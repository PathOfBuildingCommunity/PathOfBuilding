-- Path of Building
--
-- Module: Compare Trade Helpers
-- Stateless trade mod lookup/matching and item display helper functions
--
local m_floor = math.floor
local statDescData = require("Data.StatDescriptions.stat_descriptions")

-- precalculate patterns used for matching stat lines
local numberPattern = "%%d%+%%.%?%%d*"
for _, statDescEntry in ipairs(statDescData) do
	for _, desc in ipairs(statDescEntry[1] or {}) do
		-- pob doesn't parse this as a part of other mods
		desc.text = desc.text:gsub("\nPassage", "")
		desc.pat = desc.text
			-- ignore uppercase letters to help custom items match
			:lower()
			-- remove minus and plus signs
			:gsub("%-{", "{")
			:gsub("%+{", "{")
			-- escape existing characters
			:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
			-- match # to # as one block since the trade site uses the midpoint. these don't seem to
			-- ever have plus or minus signs, and can't be negative as even flat damage turns into
			-- flat damage against you instead of being negative
			:gsub("{.-} to {.-}", string.format("(%s to %s)", numberPattern, numberPattern))

			-- match number variables like {}, {0}, {0:-d}, {0:+d}, or {:d}
			:gsub("{.-}",
				-- and add optional plus and number signs. this is not necessarily correct as some
				-- stats do require the plus sign to parse, but this simplifies handling reflected
				-- mods
				"%%%+%?(%%%-%?" .. numberPattern .. ")")
	end
end

local M = {}

-- Helper: get rarity color code for an item
--- @param item table
function M.getRarityColor(item)
	if not item then return "^7" end
	if item.rarity and colorCodes[item.rarity] then
		return colorCodes[item.rarity]
	else
		return "^7"
	end
end

-- Helper: normalize a mod line by replacing numbers with "#" for template matching
--- @param line string
function M.modLineTemplate(line)
	-- Replace decimal numbers first (e.g. "1.5"), then integers
	return line:gsub("%-?[%d]+%.?[%d]*", "#")
end

-- Helper: extract the first number from a mod line for value comparison, or in the case of # to #
-- mods, the midpoint of that range
--- @param line string
--- @param onlyFromTo? boolean whether we should only check for # to # matches
function M.modLineValue(line, onlyFromTo)
	local low, high = line:match("(%-?%d+%.?%d*) to (%-?%d+%.?%d*)")
	if low and high then
		return (tonumber(low) + tonumber(high)) / 2
	elseif onlyFromTo then
		return nil
	end
	return tonumber(line:match("%-?[%d]+%.?[%d]*"))
end

local _tradeStats

---@return table? tradeStats
function M.getTradeStats()
	if _tradeStats then return _tradeStats end
	_tradeStats = LoadModule("Data/TradeSiteStats")
	return _tradeStats
end

local _optionTradeStatMap

-- These option stats are still needed for legacy items, but are no longer
-- included in the trade API's 3.29 stats response.
local legacyOptionTradeStats = {
	{
		type = "explicit",
		id = "explicit.stat_2878779644",
		text = "Grants Level 20 Summon Bestial # Skill",
		options = {
			{ id = 1, text = "rhoa" },
			{ id = 2, text = "ursa" },
			{ id = 3, text = "snake" },
		},
	},
	{
		type = "explicit",
		id = "explicit.stat_3642528642",
		text = "Only affects Passives in # Ring",
		options = {
			{ id = 1, text = "small" },
			{ id = 2, text = "medium" },
			{ id = 3, text = "large" },
			{ id = 4, text = "very large" },
			{ id = 5, text = "massive" },
		},
	},
}

---@param tradeStats table table of data from https://www.pathofexile.com/api/trade2/data/stats
---@return table optionTradeStatMap table containing helper data for matching trade option filters
local function getOptionTradeStatMap(tradeStats)
	if _optionTradeStatMap then return _optionTradeStatMap end
	local optionTradeStatMap = {
		exact = {},
		patterns = {},
	}
	for _, cat in ipairs(tradeStats) do
		if cat.id == "enchant" or cat.id == "explicit" or cat.id == "implicit" then
			for _, entry in ipairs(cat.entries) do
				local tradeId, optionId = entry.id:match("^(.-)|(.+)$")
				if tradeId and optionId then
					-- The 3.29 trade API expands option stats into one entry per option,
					-- with the option value appended to the stat ID.
					local matchKey = entry.text:gsub(" Passage", ""):lower()
					optionTradeStatMap.exact[cat.id .. "\0" .. matchKey] = {
						tradeId = tradeId,
						value = tonumber(optionId) or optionId,
					}
				elseif entry.option and entry.text:match("#") then
					-- pob parses the passage part as a separate mod line, which
					-- causes trouble
					local matchKey = entry.text:gsub("#", "(.*)"):gsub(" Passage", ""):lower()
					-- make options lowercase
					for _, option in ipairs(entry.option.options) do
						option.text = option.text and option.text:lower()
					end
					optionTradeStatMap.patterns[matchKey] = { type = cat.id, options = entry.option.options, tradeId = entry.id }
				end
			end
		end
	end
	for _, entry in ipairs(legacyOptionTradeStats) do
		local matchKey = entry.text:gsub("#", "(.*)"):lower()
		optionTradeStatMap.patterns[matchKey] = optionTradeStatMap.patterns[matchKey] or {
			type = entry.type,
			options = entry.options,
			tradeId = entry.id,
		}
	end

	_optionTradeStatMap = optionTradeStatMap
	return _optionTradeStatMap
end

-- Map source types used in OpenBuySimilarPopup to trade API category labels
M.sourceTypeToCategory = {
	["implicit"] = "Implicit",
	["explicit"] = "Explicit",
	["enchant"] = "Enchant",
}

-- inverses a mod. e.g. more x -> less x
--- @param modLine string
function M.swapInverse(modLine)
	local priorStr = modLine
	local inverseKey
	if modLine:match("increased") then
		modLine = modLine:gsub("([^ ]+) increased", "-%1 reduced")
		if modLine ~= priorStr then inverseKey = "increased" end
	elseif modLine:match("reduced") then
		modLine = modLine:gsub("([^ ]+) reduced", "-%1 increased")
		if modLine ~= priorStr then inverseKey = "reduced" end
	elseif modLine:match("more") then
		modLine = modLine:gsub("([^ ]+) more", "-%1 less")
		if modLine ~= priorStr then inverseKey = "more" end
	elseif modLine:match("less") then
		modLine = modLine:gsub("([^ ]+) less", "-%1 more")
		if modLine ~= priorStr then inverseKey = "less" end
	elseif modLine:match("expires ([^ ]+) slower") then
		modLine = modLine:gsub("([^ ]+) slower", "-%1 faster")
		if modLine ~= priorStr then inverseKey = "slower" end
	elseif modLine:match("expires ([^ ]+) faster") then
		modLine = modLine:gsub("([^ ]+) faster", "-%1 slower")
		if modLine ~= priorStr then inverseKey = "faster" end
	end
	return modLine, inverseKey
end


---@return string? tradeId
---@return number? value Only returned when applicable (primarily timeless jewels)
function M.findTradeIdOption(modLine, modType)
	-- match stringify() behaviour and ignore casing
	modLine = modLine:gsub("\n", " "):lower()
	-- exception: timeless jewels
	-- these have special pseudo trade ids and are not options in poe1
	local timelessPatterns = { "bathed in the blood of (%d+) sacrificed in the name of (.+)",
		"carved to glorify (%d+) new faithful converted by high templar (.+)",
		"commanded leadership over (%d+) warriors under (.+)",
		"commissioned (%d+) coins to commemorate (.+)",
		"denoted service of (%d+) dekhara in the akhara of (.+)",
		"remembrancing (%d+) songworthy deeds by the line of (.+)" }
	for _, pat in ipairs(timelessPatterns) do
		local value, conqueror = modLine:match(pat)
		if conqueror then
			return "explicit.pseudo_timeless_jewel_" .. conqueror, tonumber(value)
		end
	end
	local tradeStats = M.getTradeStats()
	local optionTradeStatMap = getOptionTradeStatMap(tradeStats)
	if not tradeStats or not optionTradeStatMap then return end

	-- reformat double-line cluster enchants
	modLine = modLine:gsub(".added small passive skills grant: ", " ")
	local exactEntry = optionTradeStatMap.exact[modType .. "\0" .. modLine]
	if exactEntry then
		return exactEntry.tradeId, exactEntry.value
	end
	for pat, entry in pairs(optionTradeStatMap.patterns) do
		local match = modLine:match(pat)
		if entry.type == modType and match then
			for _, option in ipairs(entry.options) do
				if option.text == match then
					return entry.tradeId, option.id
				end
			end
		end
	end
end

-- Helper: find the trade stat ID for a mod line
---@param modLine  string
---@return table[] results Can include more than one result if the results are ambiguous
---@return number? value Might be nil if the line has no sensible number value
---@return boolean shouldNegate whether the mod needs to be negated when given to the trade site
function M.findTradeHash(modLine)
	modLine = modLine:lower()
	local resultIds = {}
	local value
	local shouldNegate
	local extraStat
	-- time-lost jewels don't have proper stat descriptors and need to be handled separately
	local timeLostJewelLines = {
		["^notable passive skills in radius also grant "] = "local_jewel_mod_stats_added_to_notable_passives",
		["^small passive skills in radius also grant "] = "local_jewel_mod_stats_added_to_small_passives",
	}
	for pat, stat in pairs(timeLostJewelLines) do
		if modLine:match(pat) then
			modLine = modLine:lower():gsub(pat, "")
			extraStat = stat
			break
		end
	end
	for _, statDescEntry in ipairs(statDescData) do
		local statDescriptions = statDescEntry[1]
		if not statDescriptions then
			goto continue
		end
		-- by default, the trade site uses the first form listed in the stat descriptions, but there
		-- can be a flag that says otherwise
		-- local canonical_line = 1
		-- the stat descriptions default to using the first stat for the trade site, but this
		-- flag can define it to be another one
		local canonical_stat = 1
		local canonical_negated = false
		for statFormIdx, statForm in ipairs(statDescriptions) do
			local negate = false
			for _, flag in ipairs(statForm) do
				if (flag.k == "negate" or flag.k == "negate_and_double") and flag.v == 1 then
					negate = true
				end
				if flag.k == "canonical_stat" then
					canonical_stat = flag.v
				end
				if statFormIdx == 1 or (flag.k == "canonical_line" and flag.v) then
					-- canonical_line = desc_idx
					canonical_negated = negate
				end
			end
		end
		for _, statForm in ipairs(statDescriptions) do
			local negate = false
			for _, flag in ipairs(statForm) do
				if (flag.k == "negate" or flag.k == "negate_and_double") and flag.v == 1 then
					negate = true
				end
			end
			-- stat has no variables
			if modLine == statForm.text:lower() then
				local tradeHash = HashStats(statDescEntry.stats, extraStat)
				table.insert(resultIds, tradeHash)
				shouldNegate = false
				-- it's hard to know the correct value, but many stats have a form with no variables when the chance to do something is 100%. this should assign a value for those
				value = tonumber(statForm.limit and statForm.limit[1] and statForm.limit[1][1])
				goto continue
			end
			-- ensure no false positives by requiring a full line match. this is not possible in gmatch as it doesn't support ^
			if modLine:match("^" .. statForm.pat .. "$") then
				local idx = 1
				for match in modLine:gmatch(statForm.pat) do
					-- note that if the desired value isn't the first match and this is a # to #,
					-- this will break as it contains two values. however, there is only a single
					-- example where # to # are not the first two values currently
					local number = tonumber(match) or M.modLineValue(match)
					if number and idx == canonical_stat then
						shouldNegate = negate ~= canonical_negated
						local tradeHash = HashStats(statDescEntry.stats, extraStat)
						table.insert(resultIds, tradeHash)
						value = number
					end
					idx = idx + 1
				end
			end
		end
		::continue::
	end
	return resultIds, value, shouldNegate
end

-- Map slot name + item type to (trade API category string, itemCategoryTags key).
-- queryStr:      e.g. "armour.shield", "weapon.onemace"
-- categoryLabel: e.g. "Shield", "1HMace", "1HWeapon" (nil for flask / generic jewel / unsupported)
--- @param slotName string
--- @param item table
function M.getTradeCategory(slotName, item)
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
	elseif slotName:find("Jewel") then return "jewel", "Jewel"
	elseif slotName:find("Flask") then return "flask", "Flask"
	else return nil, nil
	end
end


-- Helper: get a display-friendly category name from slot name
--- @param item table
function M.getTradeCategoryLabel(slotName, item)
	if not item or not item.base then return "Item" end
	local baseType = item.base.type or item.type
	return baseType or "Item"
end

-- Helper: build a mod comparison map from an item.
-- Returns a table keyed by template string → { line = original text, value = first number }
--- @param item table
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
--- @param pItem table
--- @param cItem table
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
	copyBtnW, copyBtnH, buyBtnW, equipBtnW, xOffset, shouldUnderlineLabel)

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
	local labelText = "^7" .. slotLabel .. ":"
	DrawString(labelX, drawY + 2, "LEFT", 16, "VAR", labelText)

	if shouldUnderlineLabel then
		local labelW = DrawStringWidth(16, "VAR", labelText)
		DrawImage(nil, labelX, drawY + 2 + 16, labelW, 1)
	end

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

-- Helper: create a numeric EditControl without +/- spinner buttons, and
-- with a preset changeFunc intended for mod values
function M.newPlainNumericEdit(anchor, rect, init, prompt, limit, integer, changeFunc)
	local format = integer and "%D" or "^%d."
	local ctrl = new("EditControl", anchor, rect, init, prompt, format, limit, changeFunc)
	-- Remove the +/- spinner buttons that "%D" filter triggers
	ctrl.isNumeric = false
	if ctrl.controls then
		if ctrl.controls.buttonDown then ctrl.controls.buttonDown.shown = false end
		if ctrl.controls.buttonUp then ctrl.controls.buttonUp.shown = false end
	end
	return ctrl
end
return M
