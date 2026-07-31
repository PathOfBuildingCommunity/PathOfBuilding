-- Path of Building
--
-- Class: Item list
-- Build item list control.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local ItemListClass = newClass("ItemListControl", "ListControl", function(self, anchor, rect, itemsTab, forceTooltip)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, itemsTab.itemOrderList, forceTooltip)
	self.itemsTab = itemsTab
	self.defaultText = "^x7F7F7FThis is the list of items that have been added to this build.\nYou can add items to this list by dragging them from\none of the other lists, or by clicking 'Add to build' when\nviewing an item."
	self.dragTargetList = { }
	self.controls.loadoutFilter = new("DropDownControl", {"BOTTOMLEFT",self,"TOPLEFT"}, {0, -2, 110, 18}, nil, function()
		self:UpdateList()
	end)
	self.controls.loadoutFilter.enableDroppedWidth = true
	self.controls.sort = new("ButtonControl", {"LEFT",self.controls.loadoutFilter,"RIGHT"}, {4, 0, 42, 18}, "Sort", function()
		itemsTab:SortItemList()
		self:UpdateList()
	end)
	self.controls.deleteUnused = new("ButtonControl", {"LEFT",self.controls.sort,"RIGHT"}, {4, 0, 84, 18}, "Del Unused", function()
		local delList = {}
		for _, itemId in pairs(self.list) do
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
		return #self.list > 0
	end
	self.controls.deleteAll = new("ButtonControl", {"LEFT",self.controls.deleteUnused,"RIGHT"}, {4, 0, 58, 18}, "Del All", function()
		main:OpenConfirmPopup("Delete All", "Are you sure you want to delete all items in this build?", "Delete", function()
			for _, slot in pairs(itemsTab.slots) do
				slot:SetSelItemId(0)
			end
			for _, spec in pairs(itemsTab.build.treeTab.specList) do
				for nodeId, itemId in pairs(spec.jewels) do
					spec.jewels[nodeId] = 0
				end
			end
			wipeTable(self.list)
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
		return #self.list > 0
	end
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.deleteAll,"RIGHT"}, {4, 0, 50, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
end)

function ItemListClass:UpdateLoadoutList()
	local list = { "Any Loadout", "Current Loadout", "Unused Items" }
	local build = self.itemsTab.build
	if build and build.controls and build.controls.buildLoadouts then
		for _, val in ipairs(build.controls.buildLoadouts.list) do
			if val ~= "^7^7Loadouts:" and val ~= "^7^7-----" and val ~= "^7^7New Loadout" and val ~= "^7^7Sync" and val ~= "^7^7Help >>" then
				if not isValueInArray(list, val) then
					t_insert(list, val)
				end
			end
		end
	end
	if self.itemsTab.itemSetOrderList then
		for _, itemSetId in ipairs(self.itemsTab.itemSetOrderList) do
			local itemSet = self.itemsTab.itemSets[itemSetId]
			local title = itemSet and (itemSet.title or "Default")
			if title and not isValueInArray(list, title) then
				t_insert(list, title)
			end
		end
	end
	local selIndex = self.controls.loadoutFilter.selIndex or 1
	self.controls.loadoutFilter:SetList(list)
	self.controls.loadoutFilter.selIndex = math.min(selIndex, #list)
end

function ItemListClass:IsItemInLoadout(itemId, filterVal)
	local item = self.itemsTab.items[itemId]
	if not item then
		return false
	end

	-- Check item sets
	if self.itemsTab.itemSetOrderList then
		for _, itemSetId in ipairs(self.itemsTab.itemSetOrderList) do
			local itemSet = self.itemsTab.itemSets[itemSetId]
			if itemSet then
				local title = itemSet.title or "Default"
				if title == filterVal or title:find(filterVal, 1, true) or filterVal:find(title, 1, true) or #self.itemsTab.itemSetOrderList == 1 then
					local slot, equipSet = self.itemsTab:GetEquippedSlotForItem(item)
					if (slot and (not equipSet or equipSet == itemSet)) or self:FindEquippedAbyssJewel(itemId, false) == title then
						return true
					end
				end
			end
		end
	end

	-- Check passive tree specs
	local treeTab = self.itemsTab.build.treeTab
	if treeTab and treeTab.specList then
		for _, spec in ipairs(treeTab.specList) do
			local title = spec.title or "Default"
			if title == filterVal or title:find(filterVal, 1, true) or filterVal:find(title, 1, true) or #treeTab.specList == 1 then
				if self:FindSocketedJewel(itemId, false) == title then
					return true
				end
			end
		end
	end

	return false
end

function ItemListClass:UpdateList()
	self:UpdateLoadoutList()
	local selFilter = self.controls.loadoutFilter.selIndex or 1
	local filterVal = self.controls.loadoutFilter.list[selFilter] or "Any Loadout"

	if selFilter == 1 or filterVal == "Any Loadout" then
		self.list = self.itemsTab.itemOrderList
		return
	end

	local newList = {}
	for _, itemId in ipairs(self.itemsTab.itemOrderList) do
		local item = self.itemsTab.items[itemId]
		if item then
			if selFilter == 2 or filterVal == "Current Loadout" then
				if self.itemsTab:GetEquippedSlotForItem(item) or self:FindEquippedAbyssJewel(itemId, false) or self:FindSocketedJewel(itemId, false) then
					t_insert(newList, itemId)
				end
			elseif selFilter == 3 or filterVal == "Unused Items" then
				if not self.itemsTab:GetEquippedSlotForItem(item) and not self:FindEquippedAbyssJewel(itemId, false) and not self:FindSocketedJewel(itemId, false) then
					t_insert(newList, itemId)
				end
			else
				if self:IsItemInLoadout(itemId, filterVal) then
					t_insert(newList, itemId)
				end
			end
		end
	end
	self.list = newList
	if self.selIndex and self.selIndex > #self.list then
		self.selIndex = #self.list > 0 and #self.list or nil
		self.selValue = self.selIndex and self.list[self.selIndex] or nil
	end
end

function ItemListClass:Draw(viewPort)
	if self.itemsTab.build and self.itemsTab.build.outputRevision ~= self.lastOutputRevision then
		self.lastOutputRevision = self.itemsTab.build.outputRevision
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

function ItemListClass:GetRowValue(column, index, itemId)
	local item = self.itemsTab.items[itemId]
	if column == 1 then
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
	if main.popups[1] then
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
		local newItem = new("Item", value.raw)
		newItem:NormaliseQuality()
		self.itemsTab:AddItem(newItem, true, self.selDragIndex)
		self.itemsTab:PopulateSlots()
		self.itemsTab:AddUndoState()
		self:UpdateList()
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
		local newItem = new("Item", item:BuildRaw())
		newItem.id = item.id
		self.itemsTab:SetDisplayItem(newItem)
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
		if itemId then
			local item = self.itemsTab.items[itemId]
			itemLib.wiki.openItem(item)
		end
	end
end