-- Path of Building
--
-- Module: Compare Trade Helpers
-- Stateless trade mod lookup/matching and item display helper functions
--
local m_floor = math.floor
local dkjson = require "dkjson"
local queryModsData = LoadModule("Data/QueryMods")

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

-- Helper: lazily build a reverse lookup from QueryMods tradeMod.text → tradeMod.id
local _tradeModLookup = nil
local function getTradeModLookup()
	if _tradeModLookup then return _tradeModLookup end
	_tradeModLookup = {}
	if not queryModsData then return _tradeModLookup end
	for _groupName, mods in pairs(queryModsData) do
		for _modKey, modData in pairs(mods) do
			if type(modData) == "table" and modData.tradeMod then
				local text = modData.tradeMod.text
				local modType = modData.tradeMod.type or "explicit"
				local id = modData.tradeMod.id
				local key = text .. "|" .. modType
				_tradeModLookup[key] = id
				if not _tradeModLookup[text] then
					_tradeModLookup[text] = id
				end
				-- Also store with template-converted text for mods with literal numbers
				-- (e.g. "1 Added Passive Skill is X" → "# Added Passive Skill is X")
				local tmpl = M.modLineTemplate(text)
				if tmpl ~= text then
					local tmplKey = tmpl .. "|" .. modType
					if not _tradeModLookup[tmplKey] then
						_tradeModLookup[tmplKey] = id
					end
					if not _tradeModLookup[tmpl] then
						_tradeModLookup[tmpl] = id
					end
				end
			end
		end
	end
	return _tradeModLookup
end

-- Helper: lazily fetch and cache the trade API stats for comprehensive mod matching
-- Covers mods not in QueryMods.lua (cluster enchants, unique-specific mods, etc.)
local _tradeStatsLookup = nil
local _tradeStatsFetched = false
local function getTradeStatsLookup()
	if _tradeStatsFetched then return _tradeStatsLookup end
	_tradeStatsFetched = true
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
	if not ok or tradeStats == "" then return nil end
	local parsed = dkjson.decode(tradeStats)
	if not parsed or not parsed.result then return nil end
	_tradeStatsLookup = {}
	for _, category in ipairs(parsed.result) do
		local catLabel = category.label
		for _, entry in ipairs(category.entries) do
			local stripped = entry.text:gsub("[#()0-9%-%+%.]", "")
			local key = stripped .. "|" .. catLabel
			if not _tradeStatsLookup[key] then
				_tradeStatsLookup[key] = entry
			end
			if not _tradeStatsLookup[stripped] then
				_tradeStatsLookup[stripped] = entry
			end
		end
	end
	return _tradeStatsLookup
end

-- Map source types used in OpenBuySimilarPopup to trade API category labels
M.sourceTypeToCategory = {
	["implicit"] = "Implicit",
	["explicit"] = "Explicit",
	["enchant"] = "Enchant",
}

-- Helper: find the trade stat ID for a mod line
function M.findTradeModId(modLine, modType)
	-- Try QueryMods-based lookup
	local lookup = getTradeModLookup()
	local tmpl = M.modLineTemplate(modLine)
	-- Try exact match with type first
	local key = tmpl .. "|" .. modType
	if lookup[key] then
		return lookup[key]
	end
	-- Try without leading +/- sign
	local stripped = tmpl:gsub("^[%+%-]", "")
	key = stripped .. "|" .. modType
	if lookup[key] then
		return lookup[key]
	end
	-- Fallback: match by template text only (any type)
	if lookup[tmpl] then
		return lookup[tmpl]
	end
	if lookup[stripped] then
		return lookup[stripped]
	end

	-- Try trade API stats (covers mods not in QueryMods)
	local tradeStats = getTradeStatsLookup()
	if tradeStats then
		local strippedLine = modLine:gsub("[#()0-9%-%+%.]", "")
		local category = M.sourceTypeToCategory[modType]
		if category then
			local catKey = strippedLine .. "|" .. category
			if tradeStats[catKey] then
				return tradeStats[catKey].id
			end
		end
		-- Fallback: any category
		if tradeStats[strippedLine] then
			return tradeStats[strippedLine].id
		end
	end

	return nil
end

-- Helper: map slot name + item type to trade API category string
function M.getTradeCategory(slotName, item)
	if not item or not item.base then return nil end
	local itemType = item.type or (item.base and item.base.type)
	if slotName:find("^Weapon %d") then
		if itemType == "Shield" then return "armour.shield"
		elseif itemType == "Quiver" then return "armour.quiver"
		elseif itemType == "Bow" then return "weapon.bow"
		elseif itemType == "Staff" then return "weapon.staff"
		elseif itemType == "Two Handed Sword" then return "weapon.twosword"
		elseif itemType == "Two Handed Axe" then return "weapon.twoaxe"
		elseif itemType == "Two Handed Mace" then return "weapon.twomace"
		elseif itemType == "Fishing Rod" then return "weapon.rod"
		elseif itemType == "One Handed Sword" then return "weapon.onesword"
		elseif itemType == "One Handed Axe" then return "weapon.oneaxe"
		elseif itemType == "One Handed Mace" or itemType == "Sceptre" then return "weapon.onemace"
		elseif itemType == "Wand" then return "weapon.wand"
		elseif itemType == "Dagger" then return "weapon.dagger"
		elseif itemType == "Claw" then return "weapon.claw"
		elseif itemType and itemType:find("Two Handed") then return "weapon.twomelee"
		elseif itemType and itemType:find("One Handed") then return "weapon.one"
		else return "weapon"
		end
	elseif slotName == "Body Armour" then return "armour.chest"
	elseif slotName == "Helmet" then return "armour.helmet"
	elseif slotName == "Gloves" then return "armour.gloves"
	elseif slotName == "Boots" then return "armour.boots"
	elseif slotName == "Amulet" then return "accessory.amulet"
	elseif slotName == "Ring 1" or slotName == "Ring 2" or slotName == "Ring 3" then return "accessory.ring"
	elseif slotName == "Belt" then return "accessory.belt"
	elseif slotName:find("Abyssal") then return "jewel.abyss"
	elseif slotName:find("Jewel") then return "jewel"
	elseif slotName:find("Flask") then return "flask"
	else return nil
	end
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
					local tmpl = M.modLineTemplate(modLine.line)
					modMap[tmpl] = { line = modLine.line, value = M.modLineValue(modLine.line) }
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

-- Helper: draw Copy, Copy+Use, and Buy buttons at the given position.
-- btnStartX is the left edge where the first button (Buy) should appear.
-- copyBtnW, copyBtnH, buyBtnW are button dimensions (passed from LAYOUT by caller).
-- Returns copyHovered, copyUseHovered, buyHovered booleans.
function M.drawCopyButtons(cursorX, cursorY, btnStartX, btnY, slotMissing, copyBtnW, copyBtnH, buyBtnW)
	local btnW = copyBtnW
	local btnH = copyBtnH
	local buyW = buyBtnW
	local btn3X = btnStartX
	local btn1X = btn3X + buyW + 4
	local btn2X = btn1X + btnW + 4

	-- "Buy" button
	local b3Hover = cursorX >= btn3X and cursorX < btn3X + buyW
		and cursorY >= btnY and cursorY < btnY + btnH
	SetDrawColor(b3Hover and 0.5 or 0.35, b3Hover and 0.5 or 0.35, b3Hover and 0.5 or 0.35)
	DrawImage(nil, btn3X, btnY, buyW, btnH)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, btn3X + 1, btnY + 1, buyW - 2, btnH - 2)
	SetDrawColor(1, 1, 1)
	DrawString(btn3X + buyW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^7Buy")

	-- "Copy" button
	local b1Hover = cursorX >= btn1X and cursorX < btn1X + btnW
		and cursorY >= btnY and cursorY < btnY + btnH
	SetDrawColor(b1Hover and 0.5 or 0.35, b1Hover and 0.5 or 0.35, b1Hover and 0.5 or 0.35)
	DrawImage(nil, btn1X, btnY, btnW, btnH)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, btn1X + 1, btnY + 1, btnW - 2, btnH - 2)
	SetDrawColor(1, 1, 1)
	DrawString(btn1X + btnW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^7Copy")

	local b2Hover
	if slotMissing then
		-- Show "Missing slot" label instead of Copy+Use button
		SetDrawColor(1, 1, 1)
		DrawString(btn2X + btnW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^xBBBBBBMissing slot")
		b2Hover = false
	else
		-- "Copy+Use" button
		b2Hover = cursorX >= btn2X and cursorX < btn2X + btnW
			and cursorY >= btnY and cursorY < btnY + btnH
		SetDrawColor(b2Hover and 0.5 or 0.35, b2Hover and 0.5 or 0.35, b2Hover and 0.5 or 0.35)
		DrawImage(nil, btn2X, btnY, btnW, btnH)
		SetDrawColor(0.1, 0.1, 0.1)
		DrawImage(nil, btn2X + 1, btnY + 1, btnW - 2, btnH - 2)
		SetDrawColor(1, 1, 1)
		DrawString(btn2X + btnW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^7Copy+Use")
	end

	return b1Hover, b2Hover, b3Hover, btn2X, btnY, btnW, btnH
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
local ITEM_BOX_H = 20

function M.drawCompactSlotRow(drawY, slotLabel, pItem, cItem,
	colWidth, cursorX, cursorY, maxLabelW, primaryItemsTab, compareItemsTab, pWarn, cWarn, slotMissing,
	copyBtnW, copyBtnH, buyBtnW)

	local pName = pItem and pItem.name or "(empty)"
	local cName = cItem and cItem.name or "(empty)"
	if pWarn and pWarn ~= "" then pName = pName .. pWarn end
	if cWarn and cWarn ~= "" then cName = cName .. cWarn end
	local pColor = M.getRarityColor(pItem)
	local cColor = M.getRarityColor(cItem)
	local diffLabel = M.getSlotDiffLabel(pItem, cItem)

	-- Layout positions (fixed 310px box width matching regular Items tab)
	local labelX = 10
	local pBoxX = labelX + maxLabelW + 4
	local pBoxW = ITEM_BOX_W

	local cBoxX = colWidth + 10
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
			M.drawCopyButtons(cursorX, cursorY, btnStartX, drawY + 1, slotMissing, copyBtnW, copyBtnH, buyBtnW)
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
