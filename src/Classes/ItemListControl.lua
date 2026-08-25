-- Path of Building
--
-- Class: Item list
-- Build item list control.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort

local slotFilterList = { "Any Slot", "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring", "Belt", "Graft", "Flask", "Jewel" }
local raritySortOrder = { UNIQUE = 1, RELIC = 1, RARE = 2, MAGIC = 3, NORMAL = 4 }

local function isGroupHeader(value)
	return type(value) == "table" and value.groupHeader
end

local function getItemName(item)
	return (item.name or item.title or ""):lower()
end

---@class ItemListControl: ListControl
local ItemListClass = newClass("ItemListControl", "ListControl")

function ItemListClass:ItemListControl(anchor, rect, itemsTab, forceTooltip)
	self:ListControl(anchor, rect, 16, "VERTICAL", true, itemsTab.itemOrderList, forceTooltip)
	self.itemsTab = itemsTab
	self.defaultText = "^x7F7F7FThis is the list of items that have been added to this build.\nYou can add items to this list by dragging them from\none of the other lists, or by clicking 'Add to build' when\nviewing an item."
	self.dragTargetList = { }
	local width = self:GetProperty("width")
	local rowControlWidth = (width - 8) / 3
	self.controls.slotFilter = new("DropDownControl"):DropDownControl({"BOTTOMLEFT",self,"TOPLEFT"}, {0, -22, rowControlWidth, 18}, slotFilterList, function()
		self:UpdateList()
	end)
	self.controls.sortMode = new("DropDownControl"):DropDownControl({"LEFT",self.controls.slotFilter,"RIGHT"}, {4, 0, rowControlWidth, 18}, { "Custom Order", "Sort by Item Slot", "Sort by Name", "Sort by Rarity", "Sort by Loadout" }, function()
		self:UpdateList()
	end)
	self.controls.loadoutFilter = new("DropDownControl"):DropDownControl({"LEFT",self.controls.sortMode,"RIGHT"}, {4, 0, rowControlWidth, 18}, nil, function()
		self:UpdateList()
	end)
	self.controls.loadoutFilter.enableDroppedWidth = true
	self.controls.search = new("EditControl"):EditControl({"BOTTOMLEFT",self,"TOPLEFT"}, {0, -2, width, 18}, "", "Search", "%c", 100, function()
		self:UpdateList()
	end, nil, nil, true)
	self.controls.deleteUnused = new("ButtonControl"):ButtonControl({"BOTTOMLEFT",self,"TOPLEFT"}, {0, -50, rowControlWidth, 20}, "Delete Unused", function()
		local delList = {}
		for _, itemId in pairs(itemsTab.itemOrderList) do
			if not itemsTab:GetEquippedSlotForItem(itemsTab.items[itemId]) and not self:FindEquippedAbyssJewel(itemId, false) and not self:FindSocketedJewel(itemId, false) then
				t_insert(delList, itemId)
			end
		end
		-- Delete in reverse order so as to not delete the wrong item whilst deleting
		for i = #delList, 1, -1 do
			itemsTab:DeleteItem(itemsTab.items[delList[i]], true)
		end
		-- Rebuild cluster jewel graphs, populate slots, and create an undo state, as we deferred doing this during itemsTab:DeleteItem(...)
		for _, spec in pairs(itemsTab.build.treeTab.specList) do
			spec:BuildClusterJewelGraphs()
		end
		itemsTab:PopulateSlots()
		itemsTab:AddUndoState()
		itemsTab.build.buildFlag = true
		self:UpdateList()
	end)
	self.controls.deleteUnused.enabled = function()
		return #itemsTab.itemOrderList > 0
	end
	self.controls.deleteAll = new("ButtonControl"):ButtonControl({"LEFT",self.controls.deleteUnused,"RIGHT"}, {4, 0, rowControlWidth, 20}, "Delete All", function()
		main:OpenConfirmPopup("Delete All", "Are you sure you want to delete all items in this build?", "Delete", function()
			for _, slot in pairs(itemsTab.slots) do
				slot:SetSelItemId(0)
			end
			for _, spec in pairs(itemsTab.build.treeTab.specList) do
				for nodeId, itemId in pairs(spec.jewels) do
					spec.jewels[nodeId] = 0
				end
			end
			wipeTable(itemsTab.itemOrderList)
			wipeTable(self.itemsTab.items)
			itemsTab:PopulateSlots()
			itemsTab:AddUndoState()
			itemsTab.build.buildFlag = true
			self.selIndex = nil
			self.selValue = nil
			self:UpdateList()
		end)
	end)
	self.controls.deleteAll.enabled = function()
		return #itemsTab.itemOrderList > 0
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({"LEFT",self.controls.deleteAll,"RIGHT"}, {4, 0, rowControlWidth, 20}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return type(self.selValue) == "number"
	end
	return self
end

function ItemListClass:UpdateLoadoutList()
	local list = { "Any Loadout", "Current Loadout", "Unused Items" }
	local listValues = { ["Any Loadout"] = true, ["Current Loadout"] = true, ["Unused Items"] = true }
	local build = self.itemsTab.build
	if build and build.controls and build.controls.buildLoadouts then
		for _, val in ipairs(build.controls.buildLoadouts.list) do
			if val ~= "No Loadouts" and val ~= "^7^7Loadouts:" and val ~= "^7^7-----" and val ~= "^7^7New Loadout" and val ~= "^7^7Sync" and val ~= "^7^7Help >>" then
				if not listValues[val] then
					t_insert(list, val)
					listValues[val] = true
				end
			end
		end
	end
	if self.itemsTab.itemSetOrderList then
		for _, itemSetId in ipairs(self.itemsTab.itemSetOrderList) do
			local itemSet = self.itemsTab.itemSets[itemSetId]
			local title = itemSet and (itemSet.title or "Default")
			if title and not listValues[title] then
				t_insert(list, title)
				listValues[title] = true
			end
		end
	end
	local listKey = table.concat(list, "\0")
	if self.loadoutListKey == listKey then
		return false
	end
	self.loadoutListKey = listKey
	local selIndex = self.controls.loadoutFilter.selIndex or 1
	local selValue = self.controls.loadoutFilter.list and self.controls.loadoutFilter.list[selIndex] or "Any Loadout"
	self.controls.loadoutFilter:SetList(list)
	self.controls.loadoutFilter.selIndex = isValueInArray(list, selValue) or 1
	return true
end

function ItemListClass:GetLoadoutSetAndSpec(loadoutName)
	local itemSet
	local spec
	local filterTitle = loadoutName:gsub("^%[[^%]]+%]%s*", "")
	for _, itemSetId in ipairs(self.itemsTab.itemSetOrderList) do
		local candidate = self.itemsTab.itemSets[itemSetId]
		if (candidate.title or "Default") == filterTitle then
			itemSet = candidate
			break
		end
	end
	local treeTab = self.itemsTab.build.treeTab
	for _, candidate in ipairs(treeTab.specList) do
		if (candidate.title or "Default") == filterTitle then
			spec = candidate
			break
		end
	end
	local linkId = loadoutName:match("%{(%w+)%}")
	local itemLink = linkId and self.itemsTab.build.itemListSpecialLinks and self.itemsTab.build.itemListSpecialLinks[linkId]
	local treeLink = linkId and self.itemsTab.build.treeListSpecialLinks and self.itemsTab.build.treeListSpecialLinks[linkId]
	itemSet = itemSet or #self.itemsTab.itemSetOrderList == 1 and self.itemsTab.itemSets[self.itemsTab.itemSetOrderList[1]] or itemLink and self.itemsTab.itemSets[itemLink.setId]
	spec = spec or #treeTab.specList == 1 and treeTab.specList[1] or treeLink and treeTab.specList[treeLink.setId]
	return itemSet or { }, spec
end

function ItemListClass:IsItemInLoadout(itemId, itemSet, spec)
	for _, slot in pairs(itemSet) do
		if type(slot) == "table" and slot.selItemId == itemId then
			return true
		end
	end
	if spec and spec.jewels then
		for nodeId, jewelId in pairs(spec.jewels) do
			if jewelId == itemId and spec.nodes[nodeId] and spec.nodes[nodeId].alloc then
				return true
			end
		end
	end
	return false
end

function ItemListClass:SortItems(itemList, canonicalOrder, sortMode)
	t_sort(itemList, function(a, b)
		local itemA = self.itemsTab.items[a]
		local itemB = self.itemsTab.items[b]
		if sortMode == "Sort by Item Slot" then
			local orderA = self.itemsTab.slotOrder[itemA:GetPrimarySlot()] or math.huge
			local orderB = self.itemsTab.slotOrder[itemB:GetPrimarySlot()] or math.huge
			if orderA ~= orderB then
				return orderA < orderB
			end
		elseif sortMode == "Sort by Rarity" then
			local orderA = raritySortOrder[itemA.rarity] or math.huge
			local orderB = raritySortOrder[itemB.rarity] or math.huge
			if orderA ~= orderB then
				return orderA < orderB
			end
		end
		local nameA = getItemName(itemA)
		local nameB = getItemName(itemB)
		return nameA == nameB and canonicalOrder[a] < canonicalOrder[b] or nameA < nameB
	end)
end

function ItemListClass:BuildLoadoutSort(itemList, canonicalOrder)
	local groups = { }
	local currentGroup
	local currentSpec = self.itemsTab.build.treeTab.specList[self.itemsTab.build.treeTab.activeSpec]
	for index = 4, #self.controls.loadoutFilter.list do
		local loadoutName = self.controls.loadoutFilter.list[index]
		local itemSet, spec = self:GetLoadoutSetAndSpec(loadoutName)
		local group = { label = loadoutName, itemSet = itemSet, spec = spec, items = { } }
		t_insert(groups, group)
		if itemSet == self.itemsTab.activeItemSet and spec == currentSpec then
			currentGroup = group
		end
	end
	local otherUsed = { }
	local unused = { }
	for _, itemId in ipairs(itemList) do
		local assigned
		if currentGroup and self:IsItemInLoadout(itemId, currentGroup.itemSet, currentGroup.spec) then
			t_insert(currentGroup.items, itemId)
			assigned = true
		else
			for _, group in ipairs(groups) do
				if self:IsItemInLoadout(itemId, group.itemSet, group.spec) then
					t_insert(group.items, itemId)
					assigned = true
					break
				end
			end
		end
		if not assigned then
			local item = self.itemsTab.items[itemId]
			if not self.itemsTab:GetEquippedSlotForItem(item) and not self:FindEquippedAbyssJewel(itemId, false) and not self:FindSocketedJewel(itemId, false) then
				t_insert(unused, itemId)
			else
				t_insert(otherUsed, itemId)
			end
		end
	end
	local list = { }
	local function addGroup(label, items)
		if #items > 0 then
			self:SortItems(items, canonicalOrder, "Sort by Name")
			t_insert(list, { groupHeader = label })
			for _, itemId in ipairs(items) do
				t_insert(list, itemId)
			end
		end
	end
	for _, group in ipairs(groups) do
		addGroup(group.label, group.items)
	end
	addGroup("Other Used Items", otherUsed)
	addGroup("Unused Items", unused)
	return list
end

function ItemListClass:UpdateList()
	self:UpdateLoadoutList()
	local loadoutFilterIndex = self.controls.loadoutFilter.selIndex or 1
	local loadoutFilter = self.controls.loadoutFilter.list[loadoutFilterIndex] or "Any Loadout"
	local slotFilter = self.controls.slotFilter.list[self.controls.slotFilter.selIndex or 1] or "Any Slot"
	local searchText = self.controls.search.buf:lower()
	local selectedItemId = type(self.selValue) == "number" and self.selValue
	local filterItemSet
	local filterSpec
	if loadoutFilterIndex == 2 then
		filterItemSet = self.itemsTab.activeItemSet
		filterSpec = self.itemsTab.build.treeTab.specList[self.itemsTab.build.treeTab.activeSpec]
	elseif loadoutFilterIndex > 3 then
		filterItemSet, filterSpec = self:GetLoadoutSetAndSpec(loadoutFilter)
	end
	local itemList = { }
	local canonicalOrder = { }
	for index, itemId in ipairs(self.itemsTab.itemOrderList) do
		canonicalOrder[itemId] = index
		local item = self.itemsTab.items[itemId]
		if item then
			local matchesLoadout = loadoutFilterIndex == 1
				or loadoutFilterIndex == 3 and not self.itemsTab:GetEquippedSlotForItem(item) and not self:FindEquippedAbyssJewel(itemId, false) and not self:FindSocketedJewel(itemId, false)
				or filterItemSet and self:IsItemInLoadout(itemId, filterItemSet, filterSpec)
			local primarySlot = item:GetPrimarySlot()
			local matchesSlot = slotFilter == "Any Slot" or primarySlot == slotFilter or primarySlot:gsub(" %d$", "") == slotFilter
			local matchesSearch = searchText == "" or getItemName(item):find(searchText, 1, true)
			if matchesLoadout and matchesSlot and matchesSearch then
				t_insert(itemList, itemId)
			end
		end
	end
	local sortMode = self.controls.sortMode.list[self.controls.sortMode.selIndex or 1] or "Custom Order"
	if sortMode == "Custom Order" then
		local unfiltered = loadoutFilterIndex == 1 and slotFilter == "Any Slot" and searchText == ""
		self.list = unfiltered and self.itemsTab.itemOrderList or itemList
		self.isMutable = unfiltered
	elseif sortMode == "Sort by Loadout" then
		self.list = self:BuildLoadoutSort(itemList, canonicalOrder)
		self.isMutable = false
	else
		self:SortItems(itemList, canonicalOrder, sortMode)
		self.list = itemList
		self.isMutable = false
	end
	self.selIndex = selectedItemId and isValueInArray(self.list, selectedItemId) or nil
	self.selValue = self.selIndex and self.list[self.selIndex] or nil
end

function ItemListClass:SelectItem(itemId)
	self:UpdateList()
	local index = isValueInArray(self.list, itemId)
	if not index then
		self.controls.slotFilter.selIndex = 1
		self.controls.loadoutFilter.selIndex = 1
		self.controls.search.buf = ""
		self:UpdateList()
		index = isValueInArray(self.list, itemId)
	end
	if index then
		self:SelectIndex(index)
	end
end

function ItemListClass:Draw(viewPort)
	local width = self:GetProperty("width")
	local rowControlWidth = (width - 8) / 3
	local widthChanged = self.controls.slotFilter.width ~= rowControlWidth
	self.controls.slotFilter.width = rowControlWidth
	self.controls.sortMode.width = rowControlWidth
	self.controls.loadoutFilter.width = rowControlWidth
	self.controls.search.width = width
	self.controls.deleteUnused.y = main.portraitMode and -44 or -50
	self.controls.deleteUnused.width = rowControlWidth
	self.controls.deleteAll.width = rowControlWidth
	self.controls.delete.width = rowControlWidth
	if widthChanged then
		self.controls.slotFilter:CheckDroppedWidth(false)
		self.controls.sortMode:CheckDroppedWidth(false)
		self.controls.loadoutFilter:CheckDroppedWidth(true)
	end
	local loadoutListChanged = self:UpdateLoadoutList()
	local outputRevision = self.itemsTab.build and self.itemsTab.build.outputRevision
	if loadoutListChanged or outputRevision ~= self.lastOutputRevision then
		self.lastOutputRevision = outputRevision
		self:UpdateList()
	end
	self.ListControl.Draw(self, viewPort)
end

function ItemListClass:FindSocketedJewel(jewelId, excludeActiveSpec)
	if not self.itemsTab.items[jewelId] or self.itemsTab.items[jewelId].type ~= "Jewel" then
		return nil
	end
	local treeTab = self.itemsTab.build.treeTab
	local equipTree = nil
	local matchActive = false
	for specId = #treeTab.specList, 1, -1 do
		local spec = treeTab.specList[specId]
		for nodeId, itemId in pairs(spec.jewels) do
			if itemId == jewelId and spec.nodes[nodeId] and spec.nodes[nodeId].alloc then
				if excludeActiveSpec and (specId == treeTab.activeSpec or matchActive) then
					equipTree = nil
					matchActive = true
				else
					equipTree = spec.title or "Default"
				end
			end
		end
	end
	return equipTree
end

function ItemListClass:FindEquippedAbyssJewel(jewelId, excludeActiveSet)
	if not self.itemsTab.items[jewelId] or self.itemsTab.items[jewelId].base.subType ~= "Abyss" then
		return nil
	end
	local equipSet = nil
	local matchActive = false
	for _, itemSet in pairs(self.itemsTab.itemSets) do
		for slotName, slot in pairs(itemSet) do
			if type(slot) == "table" and slot.selItemId == jewelId then
				if excludeActiveSet and (itemSet == self.itemsTab.activeItemSet or matchActive) then
					equipSet = nil
					matchActive = true
				else
					equipSet = itemSet.title or "Default"
				end
			end
		end
	end
	return equipSet
end

function ItemListClass:OverrideSelectIndex(index)
	if isGroupHeader(self.list[index]) then
		self.selIndex = nil
		self.selValue = nil
		return true
	end
	return false
end

function ItemListClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mouseOverControl = self:GetMouseOverControl()
	if mouseOverControl and mouseOverControl.OnKeyDown then
		return mouseOverControl:OnKeyDown(key)
	end
	if not self.selDragActive and #self.list > 0 and (key == "UP" or key == "DOWN" or key == "HOME" or key == "END") then
		local step = (key == "UP" or key == "END") and -1 or 1
		local index
		if key == "HOME" then
			index = 1
		elseif key == "END" then
			index = #self.list
		elseif key == "UP" then
			index = (self.selIndex or #self.list + 1) - 1
		else
			index = (self.selIndex or 0) + 1
		end
		for _ = 1, #self.list do
			if index < 1 then
				index = #self.list
			elseif index > #self.list then
				index = 1
			end
			if not isGroupHeader(self.list[index]) then
				self:SelectIndex(index)
				return self
			end
			index = index + step
		end
	end
	return self.ListControl.OnKeyDown(self, key, doubleClick)
end

function ItemListClass:GetRowValue(column, index, itemId)
	if column == 1 then
		if isGroupHeader(itemId) then
			return "^7" .. itemId.groupHeader
		end
		local item = self.itemsTab.items[itemId]
		local used = self:FindEquippedAbyssJewel(itemId, true) or self:FindSocketedJewel(itemId, true) or ""
		if used == "" then
			local slot, itemSet = self.itemsTab:GetEquippedSlotForItem(item)
			if not slot then
				used = "  ^9(Unused)"
			elseif itemSet then
				used = "  ^9(Used in '" .. (itemSet.title or "Default") .. "')"
			end
		else
			used = "  ^9(Used in '" .. used .. "')"
		end
		return colorCodes[item.rarity] .. item.name .. used
	end
end

function ItemListClass:AddValueTooltip(tooltip, index, itemId)
	if main.popups[1] or isGroupHeader(itemId) then
		tooltip:Clear()
		return
	end
	local item = self.itemsTab.items[itemId]
	if tooltip:CheckForUpdate(item, IsKeyDown("SHIFT"), launch.devModeAlt, self.itemsTab.build.outputRevision) then
		self.itemsTab:AddItemTooltip(tooltip, item)
	end
end

function ItemListClass:GetDragValue(index, itemId)
	return "Item", self.itemsTab.items[itemId]
end

function ItemListClass:ReceiveDrag(type, value, source)
	if type == "Item" then
		local newItem = new("Item"):Item(value.raw)
		newItem:NormaliseQuality()
		self.itemsTab:AddItem(newItem, true, self.isMutable and self.selDragIndex or nil)
		self.itemsTab:AddForbiddenJewelCounterpart(newItem)
		self.itemsTab:PopulateSlots()
		self.itemsTab:AddUndoState()
		self:SelectItem(newItem.id)
	end
end

function ItemListClass:OnOrderChange()
	self.itemsTab:AddUndoState()
end

function ItemListClass:OnSelClick(index, itemId, doubleClick)
	local item = self.itemsTab.items[itemId]
	if IsKeyDown("CTRL") then
		local slotName = item:GetPrimarySlot()
		if slotName and self.itemsTab.slots[slotName] then
			if self.itemsTab.slots[slotName].weaponSet == 1 and self.itemsTab.activeItemSet.useSecondWeaponSet then
				-- Redirect to second weapon set
				slotName = slotName .. " Swap"
			end
			if IsKeyDown("SHIFT") then
				-- Redirect to second slot if possible
				local altSlot = slotName:gsub("1","2")
				if self.itemsTab:IsItemValidForSlot(item, altSlot) then
					slotName = altSlot
				end
			end
			if self.itemsTab.slots[slotName].selItemId == item.id then
				self.itemsTab.slots[slotName]:SetSelItemId(0)
			else
				self.itemsTab.slots[slotName]:SetSelItemId(item.id)
			end
			self.itemsTab:PopulateSlots()
			self.itemsTab:AddUndoState()
			self.itemsTab.build.buildFlag = true
		end
	elseif doubleClick then
		-- disallow dragging since if the cursor is outside the selection after
		-- the second click, the item will be stuck onto the cursor
		self.selDragging = false
		local newItem = new("Item"):Item(item:BuildRaw())
		newItem.id = item.id
		self.itemsTab:SetDisplayItem(newItem)
		return false
	end
end

function ItemListClass:OnSelCopy(index, itemId)
	local item = self.itemsTab.items[itemId]
	Copy(item:BuildRaw():gsub("\n", "\r\n"))
end

function ItemListClass:OnSelDelete(index, itemId)
	local item = self.itemsTab.items[itemId]
	local equipSlot, equipSet = self.itemsTab:GetEquippedSlotForItem(item)
	if equipSlot then
		local inSet = equipSet and (" in set '"..(equipSet.title or "Default").."'") or ""
		main:OpenConfirmPopup("Delete Item", item.name.." is currently equipped in "..equipSlot.label..inSet..".\nAre you sure you want to delete it?", "Delete", function()
			self.itemsTab:DeleteItem(item)
			self.selIndex = nil
			self.selValue = nil
			self:UpdateList()
		end)
	else
		local equipSet = self:FindEquippedAbyssJewel(itemId, true)
		if equipSet then
			local inSet = equipSet and (" in set '"..(equipSet.title or "Default").."'") or ""
			main:OpenConfirmPopup("Delete Item", item.name.." is currently equipped in an Abyssal Socket"..inSet..".\nAre you sure you want to delete it?", "Delete", function()
				self.itemsTab:DeleteItem(item)
				self.selIndex = nil
				self.selValue = nil
				self:UpdateList()
			end)
		else
			local equipTree = self:FindSocketedJewel(itemId, true)
			if equipTree then
				main:OpenConfirmPopup("Delete Item", item.name.." is currently equipped in passive tree '"..equipTree.."'.\nAre you sure you want to delete it?", "Delete", function()
					self.itemsTab:DeleteItem(item)
					self.selIndex = nil
					self.selValue = nil
					self:UpdateList()
				end)
			else
				self.itemsTab:DeleteItem(item)
				self.selIndex = nil
				self.selValue = nil
				self:UpdateList()
			end
		end
	end
end

function ItemListClass:OnHoverKeyUp(key)
	if itemLib.wiki.matchesKey(key) then
		local itemId = self.ListControl:GetHoverValue()
		if itemId and not isGroupHeader(itemId) then
			local item = self.itemsTab.items[itemId]
			itemLib.wiki.openItem(item)
		end
	end
end
