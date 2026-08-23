local M = {}

local t_insert = table.insert

local function fuzzyScore(modText, searchStr, words)
	local modLower = modText:lower()
	if modLower:find(searchStr, 1, true) then
		return 1
	end
	if #words > 1 then
		local allFound = true
		for i = 1, #words do
			if not modLower:find(words[i], 1, true) then
				allFound = false
				break
			end
		end
		if allFound then
			return 2
		end
	end
	if #words == 1 and #searchStr >= 3 then
		local textWords = {}
		for word in modLower:gmatch("%w+") do
			t_insert(textWords, word)
		end
		for i = 1, #textWords do
			for len1 = 2, #searchStr - 1 do
				local part1 = searchStr:sub(1, len1)
				local part2 = searchStr:sub(len1 + 1)
				if textWords[i]:sub(1, #part1) == part1 and textWords[i + 1] and textWords[i + 1]:sub(1, #part2) == part2 then
					return 3
				end
			end
		end
	end
	return nil
end
local modTemplateCache = {}
---@param modText string
local function getModTemplate(modText)
	if not modTemplateCache[modText] then
		modTemplateCache[modText] = modText
			:gsub("([%+-]?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", "%1#")
			:gsub("%d+%.?%d*", "#")
			:lower()
	end
	return modTemplateCache[modText]
end
---@param set table
---@param line string
---@param source string
---@param supported boolean?
-- either adds a new entry or adds the source to an existing entry
local function addModLine(set, line, source, supported)
	local template = getModTemplate(line)
	local modEntry = set[template]
	if not modEntry then
		modEntry = { text = line, sources = { [source] = true } }
		set[template] = modEntry
	else
		modEntry.sources[source] = true
	end
	if supported ~= nil then
		if supported and not modEntry.supported then
			modEntry.text = line
		end
		modEntry.supported = modEntry.supported or supported
	end
end
---@param seenGroups table
---@param set table
---@param mod table
---@param source string
local function addItemMod(seenGroups, set, mod, source)
	if not seenGroups[mod.group] then
		seenGroups[mod.group] = true
		-- the actual trade hashes aren't relevant, but this
		-- field is separated by stat description, which
		-- means that getting rid of split lines won't
		-- result in accidentally combining two separate
		-- stats
		if mod.tradeHashes then
			for _, statDescription in pairs(mod.tradeHashes) do
				local line = table.concat(statDescription, " ")
				-- note that exactly 0.5 range is necessary as that is what the
				-- mod cache uses
				local rangedLine = itemLib.applyRange(line, 0.5)
				local modList, extra = modLib.parseMod(rangedLine)
				addModLine(set, rangedLine, source, (not not modList) and not extra)
			end
		else
			-- crafted mods have a different format
			for _, line in ipairs(mod) do
				local rangedLine = itemLib.applyRange(line, 0.5)
				local modList, extra = modLib.parseMod(rangedLine)
				addModLine(set, rangedLine, source, (not not modList) and not extra)
			end
		end
	end
end
local function sortAlphabeticallyIgnoringValues(a, b)
	if a.sortKey ~= b.sortKey then
		return a.sortKey < b.sortKey
	end
	if a.template ~= b.template then
		return a.template < b.template
	end
	return a.text < b.text
end

local NO_MATCH_TEXT = "No matching modifiers found"
local function updateDisplayList(controls, displayList, modList)
	wipeTable(displayList)
	local searchStr = controls.search.buf:lower():gsub("^[%s]+", ""):gsub("[%s]+$", "")

	if #searchStr == 0 then
		for _, mod in ipairs(modList) do
			t_insert(displayList, copyTable(mod))
		end
	else
		local words = {}
		for word in searchStr:gmatch("%S+") do
			t_insert(words, word)
		end
		for _, mod in ipairs(modList) do
			local rank = fuzzyScore(mod.text, searchStr, words)
			if rank then
				local entry = copyTable(mod)
				entry.rank = rank
				t_insert(displayList, entry)
			end
		end
		table.sort(displayList, function(a, b)
			if a.rank ~= b.rank then
				return a.rank < b.rank
			end
			return sortAlphabeticallyIgnoringValues(a, b)
		end)
	end

	if #displayList == 0 then
		t_insert(displayList, { text = NO_MATCH_TEXT })
	end
	if controls.listControl then
		controls.listControl.selIndex = 1
		controls.listControl.selValue = displayList[1]
		controls.listControl.controls.scrollBarV.offset = 0
	end
end
---@param configTab ConfigTab
---@param blockData table
function M.OpenAddModPopup(configTab, blockData)
	local bData = configTab.build.data
	local tree = configTab.build.treeTab.specList[configTab.build.treeTab.activeSpec].tree
	local modSet = {}

	for _, node in pairs(tree.nodes) do
		if node.type == "Mastery" and node.masteryEffects then
			for _, masteryEffect in ipairs(node.masteryEffects) do
				for _, statLine in ipairs(masteryEffect.stats) do
					local modList, extra = modLib.parseMod(statLine)
					addModLine(modSet, statLine, string.format("%s Node", node.type), (not not modList) and not extra)
				end
			end
		else
			local i = 1
			while node.stats[i] do
				local combinedLine = node.stats[i]
				while node.mods[i + 1] do
					local nextMod = node.mods[i + 1]
					if nextMod.combined then
						combinedLine = combinedLine .. " " .. node.stats[i + 1]
						i = i + 1
					else
						break
					end
				end
				local supported = not not node.mods[i].list and not node.mods[i].extra
				local ascendancyPrefix = node.isBloodline and "Bloodline " or
					node.ascendancyName and "Ascendancy " or ""
				addModLine(modSet, combinedLine, string.format("%s%s Node", ascendancyPrefix, node.type), supported)
				i = i + 1
			end
		end
	end
	local recordedGroups = {}
	if bData.masterMods then
		for _, mod in ipairs(bData.masterMods) do
			addItemMod(recordedGroups, modSet, mod, "Crafted mod")
		end
	end
	if bData.itemMods then
		for catName, catMods in pairs(bData.itemMods) do
			if (catName ~= "Item" and catName ~= "JewelCluster") and type(catMods) == "table" then
				for _, mod in pairs(catMods) do
					addItemMod(recordedGroups, modSet, mod, "Item mod")
				end
			end
		end
	end
	if bData.veiledMods then
		for _, mod in pairs(bData.veiledMods) do
			addItemMod(recordedGroups, modSet, mod, "Veiled mod")
		end
	end
	if bData.beastCraft then
		for _, mod in pairs(bData.beastCraft) do
			addItemMod(recordedGroups, modSet, mod, "Item mod")
		end
	end

	local supportedList = {}
	for template, mod in pairs(modSet) do
		mod.template = template
		-- a key which is based on the stripped line, but one that also tries to
		-- ignore leading special characters
		mod.sortKey = template:gsub("#", " ")
			:gsub("[^%a]+", " ")
			-- strip left and right spaces
			:match("^%s*(.-)%s*$")
		if mod.supported then
			table.insert(supportedList, mod)
		end
	end

	table.sort(supportedList, sortAlphabeticallyIgnoringValues)
	local displayList = {}
	local controls = {}


	controls.listControl = new("ListControl"):ListControl({ "TOPLEFT", nil, "TOPLEFT" }, { 10, 20, 700, 454 }, 16, "VERTICAL", false, displayList)
	controls.listControl.forceTooltip = true
	controls.listControl.font = "VAR"
	controls.listControl.GetRowValue = function(self, column, index, value)
		if value and value.text then
			return (value.text == NO_MATCH_TEXT) and value.text or (colorCodes.MAGIC .. value.text)
		else
			return ""
		end
	end

	controls.listControl.AddValueTooltip = function(self, tooltip, index, value)
		tooltip:Clear(true)
		if value and value.sources then
			for source, _ in pairs(value.sources) do
				tooltip:AddLine(14, "^7" .. source)
			end
		end
	end
	controls.listControl.OnSelClick = function(self, index, value, doubleClick)
		self:SelectIndex(index)
		if doubleClick and controls.save:IsEnabled() then
			controls.save.onClick()
		end
	end

	controls.searchLabel = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 65, 482, 0, 16 }, "^7Search:")
	controls.search = new("EditControl"):EditControl({ "TOPLEFT", nil, "TOPLEFT" }, { 70, 482, 640, 18 }, "", nil, "%c", 100, function()
		updateDisplayList(controls, displayList, supportedList)
	end, nil, nil, true)
	controls.search.controls.buttonClear.shown = function()
		return #controls.search.buf > 0
	end

	updateDisplayList(controls, displayList, supportedList)
	local helpSize = 24
	controls.whatDoesItDo = new("ButtonControl"):ButtonControl({ "BOTTOM", nil, "BOTTOM" }, { 0, -10, helpSize, helpSize }, "?", function() end)
	controls.whatDoesItDo.forceTooltip = true

	controls.whatDoesItDo.tooltipText = table.concat(
		main:WrapString(
			[[This menu currently contains supported mod lines from tree nodes and item modifiers only.

This menu is not a representation of what PoB can parse, and this is only a limited list of mods. Additionally, some mods might be local to items and might not function in custom modifiers.

A mod being supported does not necessarily mean that it will be included in calculations, and only means that the mod parser accepts it.]],
			16, 270), "\n")

	controls.save = new("ButtonControl"):ButtonControl({ "BOTTOMRIGHT", controls.whatDoesItDo, "TOP" }, { -2, -4, 80, 20 }, "Add", function()
		local selIndex = controls.listControl.selIndex or 1
		local selected = displayList[selIndex]
		if selected and selected.text ~= NO_MATCH_TEXT then
			if blockData.text and #blockData.text > 0 and not blockData.text:match("\n$") then
				blockData.text = blockData.text .. "\n"
			end
			blockData.text = (blockData.text or "") .. selected.text
			configTab:UpdateCustomModsControls()
			configTab:AddUndoState()
			configTab:BuildModList()
			configTab.build.buildFlag = true
		end
		main:ClosePopup()
	end)
	controls.save.enabled = function()
		local selIndex = controls.listControl and controls.listControl.selIndex or 1
		local selected = displayList[selIndex]
		return selected ~= nil and selected.text ~= NO_MATCH_TEXT
	end


	controls.close = new("ButtonControl"):ButtonControl({ "BOTTOMLEFT", controls.whatDoesItDo, "TOP" }, { 2, -4, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)

	local popupHeight = controls.search.y + controls.search.height + helpSize - controls.whatDoesItDo.y - controls.close.y + controls.close.height + 8

	main:OpenPopup(720, popupHeight, "Mod Browser", controls, "save", "search", "close")
end

return M
