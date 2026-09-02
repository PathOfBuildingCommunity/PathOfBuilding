-- Path of Building
--
-- Class: Item list
-- Build item list control.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

---@class ItemListControl: ListControl
local ItemListClass = newClass("ItemListControl", "ListControl")

---@param anchor Anchor?
---@param rect Rect?
---@param itemsTab ItemsTab
---@param forceTooltip boolean?
function ItemListClass:ItemListControl(anchor, rect, itemsTab, forceTooltip)
	self:ListControl(anchor, rect, 16, "VERTICAL", true, itemsTab.itemOrderList, forceTooltip)
	self.itemsTab = itemsTab
	self.defaultText = "^x7F7F7FThis is the list of items that have been added to this build.\nYou can add items to this list by dragging them from\none of the other lists, or by clicking 'Add to build' when\nviewing an item."
	self.dragTargetList = { }
	self.controls.loadoutFilter = new("DropDownControl"):DropDownControl({"BOTTOMLEFT",self,"TOPLEFT"}, {0, -2, 110, 18}, nil, function()
		self:UpdateList()
	end)
	self.controls.loadoutFilter.enableDroppedWidth = true
	self.controls.sort = new("ButtonControl"):ButtonControl({"LEFT",self.controls.loadoutFilter,"RIGHT"}, {4, 0, 42, 18}, "Sort", function()
		itemsTab:SortItemList()
		self:UpdateList()
	end)
	self.controls.deleteUnused = new("ButtonControl"):ButtonControl({"LEFT",self.controls.sort,"RIGHT"}, {4, 0, 84, 18}, "Del Unused", function()
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
		return #self.list > 0
	end
	self.controls.deleteAll = new("ButtonControl"):ButtonControl({"LEFT",self.controls.deleteUnused,"RIGHT"}, {4, 0, 58, 18}, "Del All", function()
		main:OpenConfirmPopup("Delete All", "Are you sure you want to delete all items in this build?", "Delete", function()
			for _, itemSet in pairs(itemsTab.itemSets) do
				for _, itemSlot in pairs(itemSet) do
					if type(itemSlot) == "table" and itemSlot.selItemId then itemSlot.selItemId = 0 end
				end
			end
			for _, slot in pairs(itemsTab.slots) do
				if slot.nodeId then slot:SetSelItemId(0) end
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
		return #self.list > 0
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({"LEFT",self.controls.deleteAll,"RIGHT"}, {4, 0, 50, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
	return self
end

function ItemListClass:UpdateLoadoutList()
	local list = { "Any Loadout", "Current Loadout", "Unused Items" }
	local listValues = { ["Any Loadout"] = true, ["Current Loadout"] = true, ["Unused Items"] = true }
	local build = self.itemsTab.build
	if build and build.controls and build.controls.buildLoadouts then
		for _, val in ipairs(build.controls.buildLoadouts.list) do
			if val ~= "^7^7Loadouts:" and val ~= "^7^7-----" and val ~= "^7^7New Loadout" and val ~= "^7^7Sync" and val ~= "^7^7Help >>" then
				if not listValues[val] then
					t_insert(list, val)
					listValues[val] = true
				end
			end
		end
	end
	if self.itemsTab.itemSetOrderList then
		local itemSetOrderList = self.itemsTab:GetPlayerItemSetOrderList()
		for _, itemSetId in ipairs(itemSetOrderList) do
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

function ItemListClass:UpdateList()
	self:UpdateLoadoutList()
	local selFilter = self.controls.loadoutFilter.selIndex or 1
	local filterVal = self.controls.loadoutFilter.list[selFilter] or "Any Loadout"
	local selectedItemId = self.selValue

	if selFilter == 1 or filterVal == "Any Loadout" then
		self.list = self.itemsTab.itemOrderList
		self.isMutable = true
	else
		self.isMutable = false
		local filterItemSet
		local filterSpec
		if selFilter == 2 or filterVal == "Current Loadout" then
			filterItemSet = self.itemsTab:GetVisibleItemSet()
			filterSpec = self.itemsTab.build.treeTab.specList[self.itemsTab.build.treeTab.activeSpec]
		elseif selFilter ~= 3 and filterVal ~= "Unused Items" then
			local filterTitle = filterVal:gsub("^%[[^%]]+%]%s*", "")
			local itemSetOrderList = self.itemsTab:GetPlayerItemSetOrderList()
			for _, itemSetId in ipairs(itemSetOrderList) do
				local itemSet = self.itemsTab.itemSets[itemSetId]
				if (itemSet.title or "Default") == filterTitle then
					filterItemSet = itemSet
					break
				end
			end
			local treeTab = self.itemsTab.build.treeTab
			for _, spec in ipairs(treeTab.specList) do
				if (spec.title or "Default") == filterTitle then
					filterSpec = spec
					break
				end
			end
			local linkId = filterVal:match("%{(%w+)%}")
			local itemLink = linkId and self.itemsTab.build.itemListSpecialLinks and self.itemsTab.build.itemListSpecialLinks[linkId]
			local treeLink = linkId and self.itemsTab.build.treeListSpecialLinks and self.itemsTab.build.treeListSpecialLinks[linkId]
			filterItemSet = filterItemSet or #itemSetOrderList == 1 and self.itemsTab.itemSets[itemSetOrderList[1]] or itemLink and self.itemsTab.itemSets[itemLink.setId]
			filterSpec = filterSpec or #treeTab.specList == 1 and treeTab.specList[1] or treeLink and treeTab.specList[treeLink.setId]
		end
		filterItemSet = filterItemSet or { }
		local newList = {}
		for _, itemId in ipairs(self.itemsTab.itemOrderList) do
			local item = self.itemsTab.items[itemId]
			if item then
				if selFilter == 3 or filterVal == "Unused Items" then
					if not self.itemsTab:GetEquippedSlotForItem(item) and not self:FindEquippedAbyssJewel(itemId, false) and not self:FindSocketedJewel(itemId, false) then
						t_insert(newList, itemId)
					end
				else
					local inLoadout = false
					for _, slot in pairs(filterItemSet) do
						if type(slot) == "table" and slot.selItemId == itemId then
							inLoadout = true
							break
						end
					end
					if not inLoadout and filterSpec then
						for nodeId, jewelId in pairs(filterSpec.jewels) do
							if jewelId == itemId and filterSpec.nodes[nodeId] and filterSpec.nodes[nodeId].alloc then
								inLoadout = true
								break
							end
						end
					end
					if inLoadout then
						t_insert(newList, itemId)
					end
				end
			end
		end
		self.list = newList
	end
	self.selIndex = selectedItemId and isValueInArray(self.list, selectedItemId) or nil
	self.selValue = self.selIndex and self.list[self.selIndex] or nil
end

function ItemListClass:Draw(viewPort)
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
		local newItem = new("Item"):Item(value.raw)
		newItem:NormaliseQuality()
		self.itemsTab:AddItem(newItem, true, self.selDragIndex)
		self.itemsTab:AddForbiddenJewelCounterpart(newItem)
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
		local slotName = self.itemsTab:GetVisibleSlotName(item:GetPrimarySlot())
		local visibleItemSet = self.itemsTab:GetVisibleItemSet()
		if slotName and self.itemsTab.slots[slotName] then
			if self.itemsTab.slots[slotName].weaponSet == 1 and visibleItemSet.useSecondWeaponSet then
				-- Redirect to second weapon set
				slotName = slotName .. " Swap"
			end
			if IsKeyDown("SHIFT") then
				-- Redirect to second slot if possible
				local altSlot = slotName:gsub("1","2")
				if self.itemsTab:IsItemValidForSlot(item, altSlot, visibleItemSet) then
					slotName = altSlot
				end
			end
			if self.itemsTab.slots[slotName].selItemId == item.id then
				self.itemsTab.slots[slotName]:SetSelItemId(0, visibleItemSet)
			else
				self.itemsTab.slots[slotName]:SetSelItemId(item.id, visibleItemSet)
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
		if itemId then
			local item = self.itemsTab.items[itemId]
			itemLib.wiki.openItem(item)
		end
	end
end
