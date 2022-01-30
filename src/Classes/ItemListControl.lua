-- Path of Building
--
-- Class: Item list
-- Build item list control.
--
local pairs = pairs
local t_insert = table.insert

local ItemListClass = newClass("ItemListControl", "ListControl", function(self, anchor, x, y, width, height, itemsTab)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", true, itemsTab.itemOrderList)
	self.itemsTab = itemsTab
	self.label = "^7All items:"
	self.defaultText = "^x7F7F7FThis is the list of items that have been added to this build.\nYou can add items to this list by dragging them from\none of the other lists, or by clicking 'Add to build' when\nviewing an item."
	self.dragTargetList = { }
	self.controls.delete = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.deleteAll = new("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 70, 18, "Delete All", function()
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
		end)
	end)
	self.controls.deleteAll.enabled = function()
		return #self.list > 0
	end
	self.controls.sort = new("ButtonControl", {"RIGHT",self.controls.deleteAll,"LEFT"}, -4, 0, 60, 18, "Sort", function()
		itemsTab:SortItemList()
	end)
end)

function ItemListClass:FindSocketedJewel(jewelId, excludeActiveSpec)
	local treeTab = self.itemsTab.build.treeTab
	local matchActive = false
	local outputString = ""
	for specId = #treeTab.specList, 1, -1 do
		local spec = treeTab.specList[specId]
		for nodeId, itemId in pairs(spec.jewels) do
			if itemId == jewelId and spec.nodes[nodeId] and spec.nodes[nodeId].alloc then
				if excludeActiveSpec and (specId == treeTab.activeSpec or matchActive) then
					matchActive = true
					outputString = ""
				else
					outputString = spec.title or "Default"
				end
			end
		end
	end
	return outputString
end

function ItemListClass:GetRowValue(column, index, itemId)
	local item = self.itemsTab.items[itemId]
	if column == 1 then
		local used = self:FindSocketedJewel(itemId, true)
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
		self.itemsTab.build.buildFlag = true
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
	Copy(item:BuildRaw():gsub("\n","\r\n"))
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
		end)
	else
		local equipTree = self:FindSocketedJewel(itemId, true)
		if equipTree ~= "" then
			main:OpenConfirmPopup("Delete Item", item.name.." is currently equipped in passive tree '"..equipTree.."'.\nAre you sure you want to delete it?", "Delete", function()
				self.itemsTab:DeleteItem(item)
				self.selIndex = nil
				self.selValue = nil
			end)
		else
			self.itemsTab:DeleteItem(item)
			self.selIndex = nil
			self.selValue = nil
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