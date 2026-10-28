-- Reflecting Mist crafting: one magnitude roll per item, one sign per modifier.
local M = {}

-- https://www.poewiki.net/wiki/Reflecting_Mist#Mechanics
function M.GetMultipliers(legacy)
	local list = {}
	local minimum, step, count = 1300, 10, 30
	if legacy then
		minimum, step, count = 1500, 25, 24
	end
	for i = 0, count do
		local value = (minimum + i * step) / 1000
		table.insert(list, { label = string.format(legacy and "%.3fx" or "%.2fx", value), multiplier = value })
	end
	return list
end

function M.CanReflect(item)
	if not item or not item.base or item.rarity ~= "RARE"
		or (item.base.type ~= "Ring" and item.base.type ~= "Amulet")
		or item.corrupted or item.mirrored or item.synthesised or item.veiled
		or #(item.sockets or {}) > 0 or (item.base.implicit or ""):find("Has %d+ Socket") then
		return false
	end
	for _, influence in ipairs(itemLib.influenceInfo.all) do
		if item[influence.key] then
			return false
		end
	end
	return true
end

local function stripRanges(line)
	return line:gsub("%((%-?%d+%.?%d*)%-%-?%d+%.?%d*%)", "%1")
end

local function lineKey(line)
	return stripRanges(line):gsub("([%+%-]?)%d+%.?%d*", function(sign)
		return sign == "-" and "-#" or "#"
	end):lower()
end

local function inversionKey(line)
	return lineKey(line)
		:gsub("^lose ", "regenerate ")
		:gsub(" leeched by enemy as ", " leeched as ")
		:gsub("shock yourself", "shock nearby enemies")
		:gsub("chance to lose (#%% of .+ when you use a skill)", "chance to recover %1")
		:gsub("chance to lose ", "chance to gain ")
		:gsub("^hits against you gain ", "gain ")
		:gsub("^you and your minions take (#%%) increased reflected damage", "you and your minions prevent %1 of reflected damage")
		:gsub(" against you", "")
		:gsub(" to hits", "")
		:gsub("^(# to #) added (.+) damage", "adds %1 %2 damage")
end

local invertedTemplates
local function getInvertedTemplates()
	if invertedTemplates then
		return invertedTemplates
	end
	invertedTemplates = {}
	-- Use the game's exported inverted descriptions for regeneration, added damage,
	-- leech, Focus and other modifiers whose negative version changes its wording.
	for _, mods in ipairs({ data.itemMods.Explicit, data.itemMods.Delve, data.veiledMods }) do
		local originals = {}
		for id, mod in pairs(mods) do
			if type(id) == "string" then originals[id:gsub("_+$", "")] = mod end
		end
		for id, inverted in pairs(mods) do
			local original = type(id) == "string" and id:match("^(.*)Inverted$")
			original = original and originals[original]
			if original and #original == #inverted then
				for _, line in ipairs(original) do
					for _, invertedLine in ipairs(inverted) do
						-- Match descriptions rather than line positions: inverted hybrids
						-- can reorder their stats. Unchanged lines use ordinary negation.
						if lineKey(line) ~= lineKey(invertedLine) and inversionKey(line) == inversionKey(invertedLine) then
							local template = stripRanges(invertedLine):gsub("([%+%-]?)%d+%.?%d*", "%1#")
							invertedTemplates[lineKey(line)] = template
							-- Drop-restricted inverted modifiers can also be selected in
							-- the crafting editor, so support the reverse transformation.
							invertedTemplates[lineKey(invertedLine)] = stripRanges(line):gsub("([%+%-]?)%d+%.?%d*", "%1#")
						end
					end
				end
			end
		end
	end
	-- Some bench crafts (notably added Chaos Damage) have an inverted stat
	-- description but no corresponding Inverted affix in the exported mod pool.
	for line in pairs(data.modScalability) do
		if line:find(" to Attacks against you", 1, true) then
			local original = line:gsub(" against you", "")
			invertedTemplates[lineKey(original)] = line
			invertedTemplates[lineKey(line)] = original
		end
	end
	return invertedTemplates
end

local signedDescriptions
local function invertSignedDescription(line)
	if not signedDescriptions then
		signedDescriptions = {}
		for _, entry in ipairs(LoadModule("Data/StatDescriptions/stat_descriptions")) do
			if #entry.stats == 1 then
				for _, form in ipairs(entry[1] or {}) do
					local text = form.text:gsub("%%%%", "%%")
					local _, placeholders = text:gsub("%b{}", "")
					if placeholders == 1 and not text:find("\\n", 1, true) then
						local limit = form.limit[1]
						local negative = type(limit[2]) == "number" and limit[2] < 0
						local positive = type(limit[1]) == "number" and limit[1] > 0
						if negative or positive then
							local opposite
							for _, candidate in ipairs(entry[1]) do
								local bounds = candidate.limit[1]
								if (negative and type(bounds[1]) == "number" and bounds[1] > 0)
									or (positive and type(bounds[2]) == "number" and bounds[2] < 0) then
									opposite = candidate.text:gsub("%%%%", "%%")
									break
								end
							end
							local template = text:gsub("%b{}", function(value)
								return value:find("+", 1, true) and "+#" or "#"
							end)
							local key = lineKey(template:gsub("#", "1"))
							local pattern = text:gsub("%b{}", "\001"):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
								:gsub("\001", "([%%+%%-]?%%d+%%.?%%d*)")
							signedDescriptions[key] = signedDescriptions[key] or {}
							table.insert(signedDescriptions[key], { pattern = "^" .. pattern .. "$", opposite = opposite })
						end
					end
				end
			elseif entry[1] and #entry[1] == 1 then
				local form = entry[1][1]
				local positiveOnly = true
				for _, limit in ipairs(form.limit) do
					if type(limit[1]) ~= "number" or limit[1] < 0 then positiveOnly = false end
				end
				local text = form.text:gsub("%%%%", "%%")
				if positiveOnly and text:find("{", 1, true) and not text:find("\\n", 1, true) then
					local template = text:gsub("%b{}", "#")
					local key = lineKey(template:gsub("#", "1"))
					local pattern = text:gsub("%b{}", "\001"):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
						:gsub("\001", "([%%+%%-]?%%d+%%.?%%d*)")
					signedDescriptions[key] = signedDescriptions[key] or {}
					table.insert(signedDescriptions[key], { pattern = "^" .. pattern .. "$" })
				end
			end
		end
	end
	local matched = false
	for _, form in ipairs(signedDescriptions[lineKey(line)] or {}) do
		local value = line:match(form.pattern)
		if value then
			matched = true
			if form.opposite then
				return form.opposite:gsub("%b{}", function(format)
					return (format:find("+", 1, true) and "+" or "") .. tostring(math.abs(tonumber(value)))
				end)
			end
		end
	end
	-- A stat with only a positive description has no negative outcome.
	return matched and line or nil
end

function M.ReflectModLine(modLine, multiplier, negative)
	if modLine.unscalable then
		return modLine.line
	end
	local lines = {}
	for line in modLine.line:gmatch("[^\n]+") do
		local range = modLine.range or main.defaultItemAffixQuality or 1
		-- Resolve the original roll, then truncate the reflected magnitude in the
		-- stat's internal units. Catalyst and base bonuses are applied on reparse.
		local scaled = itemLib.applyRange(line, range, multiplier)
		if negative then
			local template = getInvertedTemplates()[lineKey(scaled)]
			if template then
				local values = {}
				for value in scaled:gmatch("[%+%-]?%d+%.?%d*") do
					table.insert(values, tostring(math.abs(tonumber(value))))
				end
				local i = 0
				scaled = template:gsub("#", function()
					i = i + 1
					return values[i]
				end)
			elseif itemLib.isModLineScalable(line, range, 1) then
				local described = invertSignedDescription(scaled)
				if described then
					scaled = described
				else
					scaled = itemLib.applyRange(line, range, -multiplier):gsub("%+%-", "-")
					scaled = scaled:gsub("have (%d+%.?%d*) to Total Mana Cost", "have +%1 to Total Mana Cost")
					local antonyms = { increased = "reduced", reduced = "increased", more = "less", less = "more" }
					scaled = scaled:gsub("%-(%d+%.?%d*%%) (%a+)", function(value, word)
						return antonyms[word] and value .. " " .. antonyms[word] or "-" .. value .. " " .. word
					end)
				end
			end
		end
		table.insert(lines, scaled)
	end
	return table.concat(lines, "\n")
end

function M.GetModGroups(item)
	local groups, byId = {}, {}
	for i, modLine in ipairs(item.explicitModLines) do
		if item:CheckModLineVariant(modLine) then
			local id = modLine.modGroup or modLine.modId
			local group = id and byId[id]
			if not group then
				group = { indices = {} }
				table.insert(groups, group)
				if id then byId[id] = group end
			end
			table.insert(group.indices, i)
			if M.ReflectModLine(modLine, 1.6, false) ~= M.ReflectModLine(modLine, 1.6, true) then
				group.canInvert = true
			end
			if M.ReflectModLine(modLine, 1, false) ~= M.ReflectModLine(modLine, 2.1, false) then
				group.canScale = true
			end
		end
	end
	return groups
end

function M.PrepareItem(source)
	local item = new("Item"):Item(source:BuildRaw())
	item.id = source.id
	if item.crafted then
		-- The crafting editor merges identical stats from separate affixes. Restore
		-- individual affixes so hybrid signs and per-mod rounding remain correct.
		local explicits = {}
		for _, modLine in ipairs(item.explicitModLines) do
			if modLine.crafted or modLine.custom then
				table.insert(explicits, modLine)
			end
		end
		for _, affixes in ipairs({ item.prefixes, item.suffixes }) do
			for i, affix in ipairs(affixes) do
				local mod = item.affixes[affix.modId]
				if mod then
					for _, line in ipairs(mod) do
						table.insert(explicits, {
							line = itemLib.applyRange(line, affix.range or 0.5),
							modGroup = mod.type .. i,
							modTags = mod.modTags,
							prefix = mod.type == "Prefix",
							suffix = mod.type == "Suffix",
							fractured = affix.fractured,
						})
					end
				end
			end
		end
		item.crafted = false
		item.explicitModLines = explicits
		item:BuildAndParseRaw()
	end
	return item
end

local addedAffixTypes = {}
local function restoreAddedAffixTypes(item)
	local missing = false
	for _, modLine in ipairs(item.explicitModLines) do
		if (modLine.crafted or modLine.custom) and not modLine.prefix and not modLine.suffix then missing = true end
	end
	if not missing then return end
	local types = addedAffixTypes[item.baseName]
	if not types then
		types = { crafted = {}, custom = {} }
		addedAffixTypes[item.baseName] = types
		local function register(mod, target)
			if not mod or (mod.type ~= "Prefix" and mod.type ~= "Suffix") then return end
			for _, line in ipairs(mod) do
				local key = lineKey(line)
				if target[key] == nil then
					target[key] = mod.type
				elseif target[key] ~= mod.type then
					-- Text alone cannot identify an affix when both types use it.
					target[key] = false
				end
			end
		end
		for _, craft in ipairs(data.masterMods) do
			if craft.types[item.base.type] then register(craft, types.crafted) end
		end
		for _, mods in ipairs({ item.affixes or {}, data.veiledMods }) do
			for _, mod in pairs(mods) do
				if (mod.type == "Prefix" or mod.type == "Suffix") and item:GetModSpawnWeight(mod) > 0 then
					register(mod, types.custom)
				end
			end
		end
		for _, essence in pairs(data.essences) do
			register(data.itemMods.Item[essence.mods[item.base.type]], types.custom)
		end
		for _, source in ipairs({
			{ "Data/IncursionDropOnly", data.itemMods.Explicit },
			{ "Data/DelveDropOnly", data.itemMods.Delve },
		}) do
			for id, drop in pairs(LoadModule(source[1])) do
				for _, category in ipairs(drop.categories) do
					if category == item.base.type or category == item.base.type .. ": " .. (item.base.subType or "") then
						register(source[2][id], types.custom)
						break
					end
				end
			end
		end
	end
	for _, modLine in ipairs(item.explicitModLines) do
		if (modLine.crafted or modLine.custom) and not modLine.prefix and not modLine.suffix then
			local affixType = types[modLine.crafted and "crafted" or "custom"][lineKey(modLine.line)]
			if affixType then modLine[affixType:lower()] = true end
		end
	end
end

function M.ReflectItem(source, multiplier, negatives)
	local item = new("Item"):Item(source:BuildRaw())
	item.id = source.id
	-- Older modifiers added through the editor may have no prefix/suffix marker.
	-- Recover it before the reflected values receive the base's magnitude bonus.
	restoreAddedAffixTypes(item)
	-- Keep the resolved explicit lines rather than regenerating the original affixes.
	item.crafted = false
	item.mirrored = true
	item.reflectionMultiplier = multiplier
	for i, modLine in ipairs(item.explicitModLines) do
		modLine.line = M.ReflectModLine(modLine, multiplier, negatives[i])
		if not modLine.unscalable then
			modLine.range = nil
		end
	end
	item:BuildAndParseRaw()
	return item
end

local function wrapModLine(text, size, width)
	local lines, line = {}, ""
	local function fits(value)
		return DrawStringWidth(size, "VAR", value) <= width
	end
	for word in text:gmatch("%S+") do
		local candidate = line == "" and word or line .. " " .. word
		if fits(candidate) then
			line = candidate
		else
			if line ~= "" then table.insert(lines, line) end
			line = ""
			-- Custom modifiers may contain words wider than the entire column.
			-- Split those at UTF-8 character boundaries rather than letting them overflow.
			for char in word:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
				if line ~= "" and not fits(line .. char) then
					table.insert(lines, line)
					line = ""
				end
				line = line .. char
			end
		end
	end
	if line ~= "" then table.insert(lines, line) end
	return lines
end

function M.OpenPopup(itemsTab)
	if not M.CanReflect(itemsTab.displayItem) then return end
	local source = M.PrepareItem(itemsTab.displayItem)
	local controls, negatives = {}, {}
	local groups = M.GetModGroups(source)
	local multipliers = M.GetMultipliers(false)
	local defaultRoll = math.max(0, math.min(1, main.defaultItemAffixQuality or 0.5))
	local defaultStep = round(defaultRoll * (#multipliers - 1))
	local multiplier = multipliers[defaultStep + 1].multiplier
	local preview
	local popup
	local comparisonTooltip = new("Tooltip"):Tooltip()
	local comparisonViewPort = { x = 0, y = 0, width = 685, height = main.screenH }
	local popupWidth = 705
	local function updatePreview()
		preview = M.ReflectItem(source, multiplier, negatives)
		local offset = 75
		for i, group in ipairs(groups) do
			local lines = {}
			for _, index in ipairs(group.indices) do
				local modLine = preview.explicitModLines[index]
				local line = itemLib.applyRange(modLine.line, modLine.range or 1, modLine.valueScalar)
				for _, wrapped in ipairs(wrapModLine(line, 16, 470)) do
					table.insert(lines, "^7" .. wrapped)
				end
			end
			local negative = negatives[group.indices[1]] or false
			local positiveButton, negativeButton = controls["positive" .. i], controls["negative" .. i]
			if group.canInvert then
				positiveButton.y, negativeButton.y = offset, offset
				positiveButton.locked, negativeButton.locked = not negative, negative
				positiveButton.backgroundColor = not negative and { 0.06, 0.14, 0.09 } or { 0.04, 0.04, 0.04 }
				negativeButton.backgroundColor = negative and { 0.16, 0.06, 0.08 } or { 0.04, 0.04, 0.04 }
				positiveButton.label = (not negative and colorCodes.POSITIVE or "^8") .. "+ Positive"
				negativeButton.label = (negative and "^xF05050" or "^8") .. "- Negative"
			else
				controls["state" .. i].y = offset
			end
			controls["mod" .. i].y = offset
			controls["mod" .. i].label = table.concat(lines, "\n")
			offset = offset + math.max(24, #lines * 16 + 8)
		end
		comparisonTooltip:Clear()
		controls.showComparisons.y = offset + 10
		offset = offset + 36
		popupWidth = 705
		local height = offset + 36
		if controls.showComparisons.state then
			-- Use the normal editor's comparison formatting and slot ordering. Keeping
			-- ring sections narrow lets the tooltip place them in columns if needed.
			comparisonTooltip.maxWidth = source.base.type == "Ring" and 330 or 660
			itemsTab:AddItemStatDifferences(comparisonTooltip, preview, preview.base)
			if #comparisonTooltip.lines == 0 then
				comparisonTooltip:AddLine(14, "^7No changes to displayed build stats.")
			end
			controls.comparison.y = offset
			comparisonViewPort.height = math.max(160, main.screenH - offset - 100)
			local comparisonWidth, comparisonHeight = comparisonTooltip:GetDynamicSize(comparisonViewPort)
			popupWidth = math.max(705, comparisonWidth + 20)
			height = height + comparisonHeight
		end
		if popup then popup.width, popup.height = popupWidth, height end
		return height
	end
	controls.multiplierLabel = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 25, 0, 16 }, "^7Multiplier:")
	controls.multiplier = new("SliderControl"):SliderControl({ "TOPLEFT", nil, "TOPLEFT" }, { 90, 22, 180, 20 }, function(val)
		local step = round(val * (#multipliers - 1))
		local value = multipliers[step + 1]
		controls.multiplier.val = step / (#multipliers - 1)
		if multiplier == value.multiplier then return end
		multiplier = value.multiplier
		controls.multiplierValue.label = "^7" .. value.label
		updatePreview()
	end)
	local function updateSliderSteps()
		local step = 1 / (#multipliers - 1)
		controls.multiplier.scrollWheelSpeedTbl = { DEFAULT = step, CTRL = step, SHIFT = 5 * step }
	end
	updateSliderSteps()
	controls.multiplier.val = defaultStep / (#multipliers - 1)
	controls.multiplierValue = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 280, 25, 0, 16 }, "^7" .. multipliers[defaultStep + 1].label)
	controls.legacy = new("CheckBoxControl"):CheckBoxControl({ "TOPLEFT", nil, "TOPLEFT" }, { 360, 24, 18 }, "Legacy (before 3.29)", function(state)
		multipliers = M.GetMultipliers(state)
		updateSliderSteps()
		local step = round(defaultRoll * (#multipliers - 1))
		controls.multiplier.val = step / (#multipliers - 1)
		multiplier = multipliers[step + 1].multiplier
		controls.multiplierValue.label = "^7" .. multipliers[step + 1].label
		updatePreview()
	end, "Legacy: 1.50-2.10x in 0.025 steps. Current: 1.30-1.60x in 0.01 steps.", false)
	controls.legacy.labelRight = true
	controls.hint = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 52, 0, 16 }, "^7Select Positive or Negative for each modifier:")
	for i, group in ipairs(groups) do
		local function selectSign(negative)
			if (negatives[group.indices[1]] or false) == negative then return end
			for _, modIndex in ipairs(group.indices) do
				negatives[modIndex] = negative
			end
			updatePreview()
		end
		if group.canInvert then
			controls["positive" .. i] = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 75, 95, 22 }, "+ Positive", function() selectSign(false) end)
			controls["negative" .. i] = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { 104, 75, 95, 22 }, "- Negative", function() selectSign(true) end)
		else
			local state = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 75, 189, 22 }, group.canScale and "^8No negative version" or "^8Cannot be reflected")
			controls["state" .. i] = state
			state.enabled = false
			state.tooltipText = group.canScale
				and "This modifier has no negative counterpart. Its value still scales with the reflection multiplier."
				or "Reflecting Mist leaves this modifier unchanged on both reflected items.\nIt has no negative counterpart and its values do not scale.\nThis does not mean the modifier must roll positive."
		end
		controls["mod" .. i] = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 215, 75, 0, 16 }, "")
	end
	controls.showComparisons = new("CheckBoxControl"):CheckBoxControl({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 0, 18 }, "Show stat comparisons", function()
		updatePreview()
	end, nil, false)
	controls.showComparisons.labelRight = true
	controls.comparison = new("Control"):Control({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 0 })
	controls.comparison.shown = function() return controls.showComparisons.state end
	controls.comparison.tooltip = comparisonTooltip
	function controls.comparison:Draw()
		local x, y = self:GetPos()
		comparisonViewPort.x, comparisonViewPort.y = x, y
		-- Reuse the tooltip's text and column layout without its background or border.
		local width, height = comparisonTooltip:GetSize()
		local _, _, lines = comparisonTooltip:CalculateColumns(y, x, height, width, comparisonViewPort)
		SetDrawColor(1, 1, 1)
		for _, line in ipairs(lines) do
			if #line >= 6 then DrawString(unpack(line)) end
		end
	end
	controls.createCopy = new("CheckBoxControl"):CheckBoxControl({ "TOPLEFT", nil, "TOPLEFT" }, { 520, 24, 18 }, "Create new item", nil,
		"Creates the reflected item as a new copy and saves it directly to the build's item list, leaving the original item unchanged.", true)
	controls.createCopy.labelRight = true
	controls.save = new("ButtonControl"):ButtonControl({ "BOTTOM", nil, "BOTTOM" }, { -45, -4, 80, 20 }, "Reflect", function()
		if controls.createCopy.state then
			local original = itemsTab.displayItem
			preview.id = nil
			preview.title = "Reflected " .. preview.title
			preview:BuildAndParseRaw()
			itemsTab:SetDisplayItem(preview)
			itemsTab:AddDisplayItem(true)
			itemsTab:SetDisplayItem(original)
		else
			itemsTab:SetDisplayItem(preview)
		end
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		itemsTab:AddItemTooltip(tooltip, preview, nil, false)
	end
	controls.close = new("ButtonControl"):ButtonControl({ "BOTTOM", nil, "BOTTOM" }, { 45, -4, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	local height = updatePreview()
	popup = main:OpenPopup(popupWidth, height, "Reflect Item", controls)
	popup.x = function() return math.floor((main.screenW - popup.width) / 2) end
	popup.y = function() return math.floor((main.screenH - popup.height) / 2) end
end

return M
