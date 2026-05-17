-- Path of Building
--
-- Module: Compare Trade Helpers
-- Stateless trade mod lookup/matching and item display helper functions
--
local m_floor = math.floor
local dkjson = require "dkjson"

local M = {}

-- Helper: get rarity color code for an item
function M.getRarityColor(item)
	if not item then return "^7" end
	if item.rarity == "UNIQUE" then return colorCodes.UNIQUE
	elseif item.rarity == "RARE" then return colorCodes.RARE
	elseif item.rarity == "MAGIC" then return colorCodes.MAGIC
	else return colorCodes.NORMAL end
end

-- Helper: normalize a mod line by replacing numbers with "#" for template matching
function M.modLineTemplate(line)
	-- Replace decimal numbers first (e.g. "1.5"), then integers
	return line:gsub("[%d]+%.?[%d]*", "#")
end

-- Helper: extract the first number from a mod line for value comparison
function M.modLineValue(line)
	return tonumber(line:match("[%d]+%.?[%d]*")) or 0
end

-- Helper: fetch and cache the trade API stats
local _tradeStats = nil
local _tradeStatsFetched = false
local function getTradeStatsLookup()
	if _tradeStats then return _tradeStats end
	local tradeStats = ""
	local easy = common.curl.easy()
	if not easy then return nil end
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/stats")
	easy:setopt_useragent("Path of Building/" .. (launch.versionNumber or ""))
	easy:setopt_writefunction(function(d)
		tradeStats = tradeStats .. d
		return true
	end)
	local ok = easy:perform()
	easy:close()
	if not ok or tradeStats == "" then return {} end
	local parsed = dkjson.decode(tradeStats)
	_tradeStats = parsed.result
	return _tradeStats
end

-- Map source types used in OpenBuySimilarPopup to trade API category labels
M.sourceTypeToCategory = {
	["implicit"] = "Implicit",
	["explicit"] = "Explicit",
	["enchant"] = "Enchant",
}

function M.shouldBeInverted(tradeId, modLine, modType)
	local formattedLine = M.formatDatabaseText(M.formatDatabaseText(modLine))
	for _, category in ipairs(getTradeStatsLookup()) do
		if category.id == modType then
			for _, stat in ipairs(category.entries) do
				if tradeId == stat.id then
					-- remove radius jewel extra text
					local formattedTradeSiteText = M.formatDatabaseText(stat.text)
					-- local modifiers don't seem to be inverted. same goes for
					-- the single stat that has (charm) in it
					if formattedTradeSiteText:match("(Local)") or formattedTradeSiteText:match(" %(Charm%)$") then
						return false
					end
					-- trade site sometimes has a + sign, sometimes not
					return not (formattedLine == formattedTradeSiteText or formattedLine:gsub("^%+", "") == formattedTradeSiteText)
				end
			end
		end
	end
end

-- Helper: normalise data texts to # format
function M.formatDatabaseText(text)
	-- decimal -> integer
	text = text:gsub("%d+%.%d+", "1")
	-- (123-124) -> #
	text = text:gsub("%(%d+%-%d+%)", "#")
	text = text:gsub("%d+", "#")
	-- remove radius jewel text. the same description is used for regular and
	-- radius jewels in the exports
	text = text:gsub("^Notable Passive Skills in Radius also grant ", "")
	text = text:gsub("^Small Passive Skills in Radius also grant ", "")
	return text
end

-- Helper: find the trade stat ID for a mod line
function M.findTradeHash(item, modLine, modType, isVeiled)
	local formattedLine = M.formatDatabaseText(modLine)
	-- the data export splits some mods into different parts, even though they
	-- are technically just one stat. we handle that here
	function findStat(dbMod, allowDefault)
		local excludeTags = (not allowDefault) and { default = true } or nil
		if #dbMod.weightKey > 0 and not (item:GetModSpawnWeight(dbMod, nil, excludeTags) > 0) then
			return nil
		end
		for tradeHash, description in pairs(dbMod.tradeHashes) do
			for _, line in ipairs(description) do
				local dbFormatted = M.formatDatabaseText(line)
				if formattedLine == dbFormatted then
					return tradeHash
				end
			end
		end
	end

	-- implicit mods
	if modType == "implicit" then
		for _, dbName in ipairs({"Implicit", "Synthesis", "Eldritch"}) do
			for _, dbMod in pairs(data.itemMods[dbName]) do
				local tradeHashMaybe = findStat(dbMod)
				if tradeHashMaybe then
					return tradeHashMaybe
				end
			end
		end
	end

	--enchantments TODO

	-- scourge mods
	if modType == "scourge" then
		for _, dbMod in pairs(data.itemMods.Scourge) do
			local tradeHashMaybe = findStat(dbMod)
			if tradeHashMaybe then
				return tradeHashMaybe
			end
		end
	end

	-- crucible mods
	-- TODO: add trade hash to these
	if modType == "crucible" then
		for _, dbMod in pairs(data.crucible) do
			local tradeHashMaybe = findStat(dbMod)
			if tradeHashMaybe then
				return tradeHashMaybe
			end
		end
	end

	-- veiled mods

	for _, dbMod in pairs(data.veiledMods) do
		local tradeHashMaybe = findStat(dbMod)
		if tradeHashMaybe then
			return tradeHashMaybe
		end
	end
	-- rest of the explicit mods
	for _, dbName in ipairs({ "Delve", "Explicit" }) do
		for _, dbMod in pairs(data.itemMods[dbName]) do
			local tradeHashMaybe = findStat(dbMod)
			if tradeHashMaybe then
				return tradeHashMaybe
			end
		end
	end

	for _, dbMod in pairs(data.itemMods.Scourge) do
		local tradeHashMaybe = findStat(dbMod)
		if tradeHashMaybe then
			return tradeHashMaybe
		end
	end

	-- implicit mods
	if modType == "explicit" then
		for _, dbMod in pairs(data.itemMods.Implicit) do
			local tradeHashMaybe = findStat(dbMod)
			if tradeHashMaybe then
				return tradeHashMaybe
			end
		end
	end

	-- TODO flask, graft, jewels
end
-- Map slot name + item type to (trade API category string, itemCategoryTags key).
-- queryStr:      e.g. "armour.shield", "weapon.onemace"
-- categoryLabel: e.g. "Shield", "1HMace", "1HWeapon" (nil for flask / generic jewel / unsupported)
function M.getTradeCategoryInfo(slotName, item)
	if not slotName then return nil, nil end
	local itemType = item and (item.type or (item.base and item.base.type))
	if slotName:find("^Weapon %d") then
		if not itemType then return "weapon.one", "1HWeapon" end
		if itemType == "Shield" then return "armour.shield", "Shield"
		elseif itemType == "Quiver" then return "armour.quiver", "Quiver"
		elseif itemType == "Bow" then return "weapon.bow", "Bow"
		elseif itemType == "Staff" then return "weapon.staff", "Staff"
		elseif itemType == "Two Handed Sword" then return "weapon.twosword", "2HSword"
		elseif itemType == "Two Handed Axe" then return "weapon.twoaxe", "2HAxe"
		elseif itemType == "Two Handed Mace" then return "weapon.twomace", "2HMace"
		elseif itemType == "Fishing Rod" then return "weapon.rod", "FishingRod"
		elseif itemType == "One Handed Sword" then return "weapon.onesword", "1HSword"
		elseif itemType == "One Handed Axe" then return "weapon.oneaxe", "1HAxe"
		elseif itemType == "One Handed Mace" or itemType == "Sceptre" then return "weapon.onemace", "1HMace"
		elseif itemType == "Wand" then return "weapon.wand", "Wand"
		elseif itemType == "Dagger" then return "weapon.dagger", "Dagger"
		elseif itemType == "Claw" then return "weapon.claw", "Claw"
		elseif itemType:find("Two Handed") then return "weapon.twomelee", "2HWeapon"
		elseif itemType:find("One Handed") then return "weapon.one", "1HWeapon"
		else return "weapon", "1HWeapon"
		end
	elseif slotName == "Body Armour" then return "armour.chest", "Chest"
	elseif slotName == "Helmet" then return "armour.helmet", "Helmet"
	elseif slotName == "Gloves" then return "armour.gloves", "Gloves"
	elseif slotName == "Boots" then return "armour.boots", "Boots"
	elseif slotName == "Amulet" then return "accessory.amulet", "Amulet"
	elseif slotName == "Ring 1" or slotName == "Ring 2" or slotName == "Ring 3" then return "accessory.ring", "Ring"
	elseif slotName == "Belt" then return "accessory.belt", "Belt"
	elseif slotName:find("Abyssal") then return "jewel.abyss", "AbyssJewel"
	elseif slotName:find("Jewel") then return "jewel", nil
	elseif slotName:find("Flask") then return "flask", "Flask"
	else return nil, nil
	end
end

-- Helper: map slot name + item type to trade API category string
function M.getTradeCategory(slotName, item)
	if not item or not item.base then return nil end
	local queryStr = M.getTradeCategoryInfo(slotName, item)
	return queryStr
end

-- Helper: get a display-friendly category name from slot name
function M.getTradeCategoryLabel(slotName, item)
	if not item or not item.base then return "Item" end
	local baseType = item.base.type or item.type
	return baseType or "Item"
end

-- Helper: build a mod comparison map from an item.
-- Returns a table keyed by template string → { line = original text, value = first number }
function M.buildModMap(item)
	local modMap = {}
	if not item then return modMap end
	for _, modList in ipairs{item.enchantModLines or {}, item.scourgeModLines or {}, item.implicitModLines or {}, item.explicitModLines or {}, item.crucibleModLines or {}} do
		for _, modLine in ipairs(modList) do
			if item:CheckModLineVariant(modLine) then
				local formatted = itemLib.formatModLine(modLine)
				if formatted then
					local template = M.modLineTemplate(modLine.line)
					modMap[template] = { line = modLine.line, value = M.modLineValue(modLine.line) }
				end
			end
		end
	end
	return modMap
end

-- Helper: get diff label string for an item slot comparison
function M.getSlotDiffLabel(pItem, cItem)
	if not pItem and not cItem then
		return "^8(both empty)"
	end
	if pItem and cItem and pItem.name == cItem.name then
		return colorCodes.POSITIVE .. "(match)"
	elseif not pItem then
		return colorCodes.NEGATIVE .. "(missing)"
	elseif not cItem then
		return colorCodes.TIP .. "(extra)"
	else
		return colorCodes.WARNING .. "(different)"
	end
end

-- Helper: draw Copy, Equip, and Buy buttons at the given position.
-- btnStartX is the left edge where the first button (Buy) should appear.
-- copyBtnW, copyBtnH, buyBtnW are button dimensions (passed from LAYOUT by caller).
-- Returns copyHovered, equipHovered, buyHovered booleans.
function M.drawCopyButtons(cursorX, cursorY, btnStartX, btnY, slotMissing, copyBtnW, copyBtnH, buyBtnW, equipBtnW)
	local btnW     = copyBtnW
	local btnH     = copyBtnH
	local buyW     = buyBtnW
	local equipW = equipBtnW
	local btn3X = btnStartX
	local btn1X = btn3X + buyW + 4
	local btn2X = btn1X + btnW + 4

	local function drawBtn(x, w, hover, label)
		local pressed = hover and IsKeyDown("LEFTBUTTON")
		-- Outer border
		if hover then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawImage(nil, x, btnY, w, btnH)
		-- Inner fill
		if pressed then
			SetDrawColor(0.5, 0.5, 0.5)
		elseif hover then
			SetDrawColor(0.33, 0.33, 0.33)
		else
			SetDrawColor(0, 0, 0)
		end
		DrawImage(nil, x + 1, btnY + 1, w - 2, btnH - 2)
		-- Label
		SetDrawColor(1, 1, 1)
		DrawString(x + w / 2, btnY + 1, "CENTER_X", 14, "VAR", label)
	end

	-- "Buy" button
	local b3Hover = cursorX >= btn3X and cursorX < btn3X + buyW
		and cursorY >= btnY and cursorY < btnY + btnH
	drawBtn(btn3X, buyW, b3Hover, "^7Buy")

	-- "Copy" button
	local b1Hover = cursorX >= btn1X and cursorX < btn1X + btnW
		and cursorY >= btnY and cursorY < btnY + btnH
	drawBtn(btn1X, btnW, b1Hover, "^7Copy")

	local b2Hover
	if slotMissing then
		-- Show "Missing slot" label instead of Equip button
		SetDrawColor(1, 1, 1)
		DrawString(btn2X + equipW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^xBBBBBBMissing slot")
		b2Hover = false
	else
		-- "Equip" button
		b2Hover = cursorX >= btn2X and cursorX < btn2X + equipW
			and cursorY >= btnY and cursorY < btnY + btnH
		drawBtn(btn2X, equipW, b2Hover, "^7Equip")
	end

	return b1Hover, b2Hover, b3Hover, btn2X, btnY, equipW, btnH
end

-- Helper: fit a colored item name within maxW pixels, truncating with "..." if needed.
local function fitItemName(colorCode, name, maxW)
	local display = colorCode .. name
	if DrawStringWidth(16, "VAR", display) <= maxW then
		return display
	end
	local lo, hi = 0, #name
	while lo < hi do
		local mid = m_floor((lo + hi + 1) / 2)
		if DrawStringWidth(16, "VAR", colorCode .. name:sub(1, mid) .. "...") <= maxW then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return colorCode .. name:sub(1, lo) .. "..."
end

-- Helper: draw a single compact-mode item row.
-- Returns: pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H, hoverItem, hoverItemsTab
-- copyBtnW, copyBtnH, buyBtnW are button dimensions (passed from LAYOUT by caller).
local ITEM_BOX_W = 310
M.ITEM_BOX_W = ITEM_BOX_W
local ITEM_BOX_H = 20

function M.drawCompactSlotRow(drawY, slotLabel, pItem, cItem,
	colWidth, cursorX, cursorY, maxLabelW, primaryItemsTab, compareItemsTab, pWarn, cWarn, slotMissing,
	copyBtnW, copyBtnH, buyBtnW, equipBtnW, xOffset)

	xOffset = xOffset or 0
	local pName = pItem and pItem.name or "(empty)"
	local cName = cItem and cItem.name or "(empty)"
	if pWarn and pWarn ~= "" then pName = pName .. pWarn end
	if cWarn and cWarn ~= "" then cName = cName .. cWarn end
	local pColor = M.getRarityColor(pItem)
	local cColor = M.getRarityColor(cItem)
	local diffLabel = M.getSlotDiffLabel(pItem, cItem)

	-- Layout positions (fixed 310px box width matching regular Items tab)
	local labelX = 10 + xOffset
	local pBoxX = labelX + maxLabelW + 4
	local pBoxW = ITEM_BOX_W

	local cBoxX = colWidth + 10 + xOffset
	local cBoxW = ITEM_BOX_W

	-- Diff indicator position
	local diffX = pBoxX + pBoxW + 6

	-- Hover detection
	local pHover = pItem and cursorX >= pBoxX and cursorX < pBoxX + pBoxW
		and cursorY >= drawY and cursorY < drawY + ITEM_BOX_H
	local cHover = cItem and cursorX >= cBoxX and cursorX < cBoxX + cBoxW
		and cursorY >= drawY and cursorY < drawY + ITEM_BOX_H

	-- Draw slot label
	SetDrawColor(1, 1, 1)
	DrawString(labelX, drawY + 2, "LEFT", 16, "VAR", "^7" .. slotLabel .. ":")

	-- Draw primary item box
	local pBorderGray = pHover and 0.5 or 0.33
	SetDrawColor(pBorderGray, pBorderGray, pBorderGray)
	DrawImage(nil, pBoxX, drawY, pBoxW, ITEM_BOX_H)
	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, pBoxX + 1, drawY + 1, pBoxW - 2, ITEM_BOX_H - 2)
	SetDrawColor(1, 1, 1)
	DrawString(pBoxX + 4, drawY + 2, "LEFT", 16, "VAR", fitItemName(pColor, pName, pBoxW - 8))

	-- Draw diff indicator (between the two item boxes)
	DrawString(diffX, drawY + 3, "LEFT", 14, "VAR", diffLabel)

	-- Draw compare item box
	local cBorderGray = cHover and 0.5 or 0.33
	SetDrawColor(cBorderGray, cBorderGray, cBorderGray)
	DrawImage(nil, cBoxX, drawY, cBoxW, ITEM_BOX_H)
	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, cBoxX + 1, drawY + 1, cBoxW - 2, ITEM_BOX_H - 2)
	SetDrawColor(1, 1, 1)
	DrawString(cBoxX + 4, drawY + 2, "LEFT", 16, "VAR", fitItemName(cColor, cName, cBoxW - 8))

	-- Draw buttons
	local b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H
	if cItem then
		local btnStartX = cBoxX + cBoxW + 6
		b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H =
			M.drawCopyButtons(cursorX, cursorY, btnStartX, drawY + 1, slotMissing, copyBtnW, copyBtnH, buyBtnW, equipBtnW)
	end

	-- Determine hovered item and tooltip anchor position
	local hoverItem = nil
	local hoverItemsTab = nil
	local hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH = 0, 0, 0, 0
	if pHover then
		hoverItem = pItem
		hoverItemsTab = primaryItemsTab
		hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH = pBoxX, drawY, pBoxW, ITEM_BOX_H
	elseif cHover then
		hoverItem = cItem
		hoverItemsTab = compareItemsTab
		hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH = cBoxX, drawY, cBoxW, ITEM_BOX_H
	end

	return pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H,
		hoverItem, hoverItemsTab, hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH
end

return M
