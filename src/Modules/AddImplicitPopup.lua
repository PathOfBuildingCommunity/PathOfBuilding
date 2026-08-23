local m_max = math.max
local t_insert = table.insert

local M = {}

local function buildModSortList()
	local sortList = { { label = "Default", stat = nil } }
	local sortStats = {}
	for _, entry in ipairs(data.powerStatList) do
		if entry.stat and not entry.ignoreForNodes then
			t_insert(sortList, { label = entry.label, stat = entry.stat })
			sortStats[entry.stat] = entry
		end
	end
	return sortList, sortStats
end

-- Opens the custom Implicit popup
---@param itemsTab ItemsTab
---@param displayItem Item
function M.AddImplicitToDisplayItem(itemsTab, displayItem)
	local controls = {}
	local sourceList = {}
	local modList = {}
	local modGroups = {}
	local sortList, sortStats = buildModSortList()
	if not displayItem then return end
	-- these closures should probably be refactored to be outside this function
	-- at some point
	local function setDefaultSortOrder()
		for groupIndex, group in ipairs(modGroups) do
			group.defaultSortOrder = groupIndex
			group.sortValue = nil
		end
		for _, listMods in ipairs(modList) do
			for index, listMod in ipairs(listMods) do
				listMod.defaultSortOrder = index
				listMod.sortValue = nil
				listMod.sortValues = nil
			end
		end
	end
	---Mutates modList to contain mods from the specified source
	---@param sourceId string @The crafting source id to build the list of mods for
	local function buildMods(sourceId)
		wipeTable(modList)
		wipeTable(modGroups)
		local groupIndexes = {}
		if sourceId == "EXARCH" or sourceId == "EATER" then
			for i, mod in pairs(displayItem.affixes) do
				if displayItem:GetModSpawnWeight(mod) > 0 and sourceId:lower() == mod.type:lower() then
					local modLabel = table.concat(mod, "/")
					local group = mod.group:gsub("PinnaclePresence", ""):gsub("UniquePresence", "")
					if not groupIndexes[group] then
						t_insert(modList, {})
						t_insert(modGroups, {
							label = modLabel,
							mod = mod,
							modListIndex = #modList,
							defaultOrder = i,
						})
						groupIndexes[group] = #modGroups
					end
					t_insert(modList[groupIndexes[group]], {
						label = modLabel,
						mod = mod,
						affixType = mod.type,
						type = sourceId:lower(),
						defaultOrder = i,
					})
				end
			end
			table.sort(modGroups, function(a, b)
				local modA = a.mod
				local modB = b.mod
				for i = 1, m_max(#modA, #modB) do
					if not modA[i] then
						return true
					elseif not modB[i] then
						return false
					elseif modA.statOrder[i] ~= modB.statOrder[i] then
						return modA.statOrder[i] < modB.statOrder[i]
					end
				end
				return modA.level > modB.level
			end)
			for i, _ in pairs(modList) do
				table.sort(modList[i], function(a, b)
					local modA = a.mod
					local modB = b.mod
					if modA.group ~= modB.group then
						if modA.group:match("PinnaclePresence") then
							return false
						elseif modB.group:match("PinnaclePresence") then
							return true
						elseif modA.group:match("UniquePresence") then
							return false
						else
							return true
						end
					end
					for j = 1, m_max(#modA, #modB) do
						if not modA[j] then
							return true
						elseif not modB[j] then
							return false
						elseif modA.statOrder[j] ~= modB.statOrder[j] then
							return modA.statOrder[j] < modB.statOrder[j]
						else
							local modAVal = tonumber(a.defaultOrder:match("%d+$"))
							local modBVal = tonumber(b.defaultOrder:match("%d+$"))
							return modAVal < modBVal
						end
					end
					return modA.level > modB.level
				end)
			end
			for i, _ in pairs(modGroups) do
				modGroups[i].label = modList[modGroups[i].modListIndex][1].label:gsub("%([%d%.]+%-[%d%.]+%)", "#"):gsub("[%d%.]+", "#")
			end
		elseif sourceId == "VESTIGIAL" then
			for id, uniqueTitle in pairs(data.vestigialModMappings) do
				local titleLower = uniqueTitle:lower()
				local unique = main.uniqueDB.byTitle[titleLower]
				if not unique
					-- vestigial implicits can only end up on the same item type
					or (unique.base.type ~= displayItem.type)
					-- avoid adding the item's own mods as vestigial
					or (displayItem.title:lower() == titleLower) then
					goto vestigialContinue
				end
				local mod = copyTable(data.itemMods.Vestigial[id])
				local modLabel = colorCodes.VESTIGIAL .. table.concat(mod, "/")
				t_insert(modList, { {
					label = modLabel,
					mod = mod,
					type = "vestigial",
					uniqueTitle = uniqueTitle,
					modListIndex = #modList + 1,
					id = id,
				} })
				groupIndexes[mod.group] = #modGroups
				::vestigialContinue::
			end
			table.sort(modList, function(a, b)
				a = a[1]
				b = b[1]
				if a.group == b.group then
					return a.id < b.id
				end
				return a.mod.group < b.mod.group
			end)
			for i, elem in ipairs(modList) do
				local group = elem[1]
				group.modListIndex = i
				table.insert(modGroups, elem[1])
			end
		end
		setDefaultSortOrder()
	end
	local titleLower = displayItem.title and displayItem.title:lower()
	local displayDBUnique = main.uniqueDB.byTitle[titleLower]
	if displayItem.rarity == "UNIQUE" and displayDBUnique
		and data.vestigialUniqueBaseTypes[displayItem.base.type]
		-- the source field should mean that the item comes from a specific
		-- mechanic, which usually means it is not in the core drop pool
		and (not displayDBUnique.source
			-- this is the only exception to the above, as it occasionally drops
			-- instead of other body armours in legion
			or titleLower == "stasis prison") then
		t_insert(sourceList, { label = "Vestigial", sourceId = "VESTIGIAL" })
	end
	if (displayItem.rarity ~= "UNIQUE" and displayItem.rarity ~= "RELIC") and (displayItem.type == "Helmet" or displayItem.type == "Body Armour" or displayItem.type == "Gloves" or displayItem.type == "Boots") then
		if displayItem.cleansing then
			t_insert(sourceList, { label = "Searing Exarch", sourceId = "EXARCH" })
		end
		if displayItem.tangle then
			t_insert(sourceList, { label = "Eater of Worlds", sourceId = "EATER" })
		end
	end
	t_insert(sourceList, { label = "Custom", sourceId = "CUSTOM" })
	buildMods(sourceList[1].sourceId)
	---Applies a candidate listMod to the item, mirroring the mutation addModifier()
	---performs at click-time. Eldritch (exarch/eater) sources replace an existing
	---implicit of the same type when present; other sources append.
	local function applyCandidateMod(item, listMod)
		if listMod.type == "exarch" or listMod.type == "eater" then
			local index
			for i, implicitMod in ipairs(item.implicitModLines) do
				if implicitMod[listMod.type] then
					index = i
					break
				end
			end
			if index then
				for i, line in ipairs(listMod.mod) do
					item.implicitModLines[index + i - 1] = { line = line, modTags = listMod.mod.modTags, [listMod.type] = true }
				end
				return
			end
		elseif listMod.type == "vestigial" then
			item.implicitModLines = {}
		end
		for _, line in ipairs(listMod.mod) do
			local modLine = { line = line, modTags = listMod.mod.modTags }
			if listMod.type then
				modLine[listMod.type] = true
			end
			t_insert(item.implicitModLines, modLine)
		end
	end
	local function getSortValue(listMod, stat, calcFunc, slotName, useFullDPS)
		listMod.sortValues = listMod.sortValues or {}
		if listMod.sortValues[stat] ~= nil then
			return listMod.sortValues[stat]
		end
		local item = new("Item"):Item(displayItem:BuildRaw())
		item.id = displayItem.id
		applyCandidateMod(item, listMod)
		item:BuildAndParseRaw()
		local output = calcFunc({ repSlotName = slotName, repItem = item }, useFullDPS)
		local value = data.powerStatList.GetFromOutput(output, sortStats[stat])
		listMod.sortValues[stat] = value
		return value
	end
	local function applySort(stat, selectFirst)
		if not controls.modSelect or not controls.modGroupSelect or not controls.modGroupSelect:IsShown() then
			return
		end
		local selectedGroup = not selectFirst and modGroups[controls.modGroupSelect.selIndex] or nil
		local selectedMod = not selectFirst and controls.modSelect.list and controls.modSelect.list[controls.modSelect.selIndex] or nil
		if stat then
			local slotName = displayItem:GetPrimarySlot()
			local calcFunc = itemsTab.build.calcsTab:GetMiscCalculator()
			local useFullDPS = stat == "FullDPS"
			for _, listMods in ipairs(modList) do
				for _, listMod in ipairs(listMods) do
					listMod.sortValue = getSortValue(listMod, stat, calcFunc, slotName, useFullDPS)
				end
				table.sort(listMods, function(a, b)
					if a.sortValue ~= b.sortValue then
						return a.sortValue > b.sortValue
					end
					return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
				end)
			end
			for _, group in ipairs(modGroups) do
				local best
				for _, listMod in ipairs(modList[group.modListIndex] or {}) do
					if not best or listMod.sortValue > best then
						best = listMod.sortValue
					end
				end
				group.sortValue = best or 0
			end
			table.sort(modGroups, function(a, b)
				if a.sortValue ~= b.sortValue then
					return a.sortValue > b.sortValue
				end
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		else
			for _, listMods in ipairs(modList) do
				table.sort(listMods, function(a, b)
					return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
				end)
			end
			table.sort(modGroups, function(a, b)
				return (a.defaultSortOrder or 0) < (b.defaultSortOrder or 0)
			end)
		end
		controls.modGroupSelect:UpdateSearch()
		if selectedGroup then
			for index, group in ipairs(modGroups) do
				if group == selectedGroup then
					controls.modGroupSelect.selIndex = index
					break
				end
			end
		else
			controls.modGroupSelect:SetSel(1, true)
		end
		controls.modSelect.list = modList[modGroups[controls.modGroupSelect.selIndex].modListIndex]
		controls.modSelect:UpdateSearch()
		if selectedMod then
			for index, listMod in ipairs(controls.modSelect.list) do
				if listMod == selectedMod then
					controls.modSelect.selIndex = index
					break
				end
			end
		else
			controls.modSelect:SetSel(1, true)
		end
	end
	local function addModifier()
		local item = new("Item"):Item(displayItem:BuildRaw())
		item.id = displayItem.id
		local sourceId = sourceList[controls.source.selIndex].sourceId
		if sourceId == "CUSTOM" then
			if controls.custom.buf:match("%S") then
				t_insert(item.implicitModLines, { line = controls.custom.buf, custom = true })
			end
		else
			applyCandidateMod(item, modList[modGroups[controls.modGroupSelect.selIndex].modListIndex][controls.modSelect.selIndex])
		end
		item:BuildAndParseRaw()
		return item
	end
	controls.sourceLabel = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 95, 20, 0, 16 }, "^7Source:")
	controls.source = new("DropDownControl"):DropDownControl({ "TOPLEFT", nil, "TOPLEFT" }, { 100, 20, 150, 18 }, sourceList, function(index, value)
		if value.sourceId ~= "CUSTOM" then
			controls.modSelectLabel.y = 70
			buildMods(value.sourceId)
			controls.modGroupSelect:SetSel(1)
			controls.modSelect.list = modList[modGroups[1].modListIndex]
			controls.modSelect:SetSel(1)
			if controls.sort then
				applySort(controls.sort.list[controls.sort.selIndex].stat, true)
			end
		else
			controls.modSelectLabel.y = 45
		end
	end)
	controls.source.enabled = #sourceList > 1
	controls.sortLabel = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 350, 20, 0, 16 }, "^7Sort by:")
	controls.sortLabel.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.sort = new("DropDownControl"):DropDownControl({ "TOPLEFT", nil, "TOPLEFT" }, { 355, 20, 240, 18 }, sortList, function(index, value)
		applySort(value.stat, true)
	end)
	controls.sort.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modGroupSelectLabel = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 95, 45, 0, 16 }, function()
		if controls.modSelect:IsShown() then
			return "^7Type:"
		else
			return "^7Modifier:"
		end
	end)
	controls.modGroupSelect = new("DropDownControl"):DropDownControl({ "TOPLEFT", nil, "TOPLEFT" }, { 100, 45, 600, 18 }, modGroups, function(index, value)
		controls.modSelect.list = modList[value.modListIndex]
		controls.modSelect:SetSel(1)
	end)
	controls.modGroupSelectLabel.shown = function()
		if sourceList[controls.source.selIndex].sourceId == "CUSTOM" then
			controls.modSelectLabel.y = 45
		end
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modGroupSelect.shown = function()
		return sourceList[controls.source.selIndex].sourceId ~= "CUSTOM"
	end
	controls.modGroupSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value then
			for _, line in ipairs(value.mod) do
				tooltip:AddLine(16, "^7" .. line)
			end
			if value.uniqueTitle then
				tooltip:AddLine(16, "^7Source: " .. colorCodes.UNIQUE .. value.uniqueTitle .. "^7")
			end
			itemsTab:AddModComparisonTooltip(tooltip, value.mod, value.type == "vestigial")
		end
	end
	controls.modSelectLabel = new("LabelControl"):LabelControl({ "TOPRIGHT", nil, "TOPLEFT" }, { 95, 70, 0, 16 }, "^7Modifier:")
	controls.modSelect = new("DropDownControl"):DropDownControl({ "TOPLEFT", nil, "TOPLEFT" }, { 100, 70, 600, 18 }, sourceList[controls.source.selIndex].sourceId ~= "CUSTOM" and modList[modGroups[1].modListIndex] or {})
	local modSelectHidden = {
		CUSTOM = true,
		-- vestigial implicits aren't grouped together, and the type selector
		-- will act as the mod selector
		VESTIGIAL = true
	}
	controls.modSelect.shown = function()
		return not modSelectHidden[sourceList[controls.source.selIndex].sourceId]
	end
	controls.modSelectLabel.shown = controls.modSelect.shown
	controls.modSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode ~= "OUT" and value then
			for _, line in ipairs(value.mod) do
				tooltip:AddLine(16, "^7" .. line)
			end
			if value.uniqueTitle then
				tooltip:AddLine(16, "^7Source: " .. colorCodes.UNIQUE .. value.uniqueTitle .. "^7")
			end
			itemsTab:AddModComparisonTooltip(tooltip, value.mod)
		end
	end
	controls.custom = new("EditControl"):EditControl({ "TOPLEFT", nil, "TOPLEFT" }, { 100, 45, 440, 18 })
	controls.custom.shown = function()
		return sourceList[controls.source.selIndex].sourceId == "CUSTOM"
	end
	controls.save = new("ButtonControl"):ButtonControl({ "BOTTOMRIGHT", nil, "BOTTOM" }, { -4, -8, 80, 20 }, "Add", function()
		itemsTab:SetDisplayItem(addModifier())
		main:ClosePopup()
	end)
	controls.save.tooltipFunc = function(tooltip)
		tooltip:Clear()
		itemsTab:AddItemTooltip(tooltip, addModifier())
	end
	controls.close = new("ButtonControl"):ButtonControl({ "BOTTOMLEFT", nil, "BOTTOM" }, { 4, -8, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	local popupHeight = 130
	if not controls.modSelect.shown() then
		popupHeight = popupHeight - 20
	end
	main:OpenPopup(710, popupHeight, "Add Implicit to Item", controls, "save", sourceList[controls.source.selIndex].sourceId == "CUSTOM" and "custom")
end

return M
