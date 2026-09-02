-- Path of Building
--
-- Class: Item Set List
-- Item set list control.
--
local t_insert = table.insert
local t_remove = table.remove
local ipairs = ipairs
local m_max = math.max

---@class ItemSetListControl: ListControl
local ItemSetListClass = newClass("ItemSetListControl", "ListControl")

function ItemSetListClass:ItemSetListControl(anchor, rect, itemsTab)
	self:ListControl(anchor, rect, 16, "VERTICAL", true, itemsTab.itemSetOrderList)
	self.itemsTab = itemsTab
	self.controls.copy = new("ButtonControl"):ButtonControl({"BOTTOMLEFT",self,"TOP"}, {2, -4, 60, 18}, "Copy", function()
		local newSet = copyTable(itemsTab.itemSets[self.selValue])
		newSet.id = 1
		while itemsTab.itemSets[newSet.id] do
			newSet.id = newSet.id + 1
		end
		itemsTab.itemSets[newSet.id] = newSet
		self:RenameSet(newSet, true)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({"LEFT",self.controls.copy,"RIGHT"}, {4, 0, 60, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self:CanDeleteItemSet(self.selValue)
	end
	self.controls.rename = new("ButtonControl"):ButtonControl({"BOTTOMRIGHT",self,"TOP"}, {-2, -4, 60, 18}, "Rename", function()
		self:RenameSet(itemsTab.itemSets[self.selValue])
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl"):ButtonControl({"RIGHT",self.controls.rename,"LEFT"}, {-4, 0, 60, 18}, "New", function()
		local newSet = itemsTab:NewItemSet()
		self:RenameSet(newSet, true)
	end)
	return self
end

function ItemSetListClass:CanDeleteItemSet(itemSetId)
	local itemSet = self.itemsTab.itemSets[itemSetId]
	if not itemSet or self.itemsTab:IsItemSetReferenced(itemSetId) then
		return false
	end
	return #self.list > 1
end

function ItemSetListClass:RenameSet(itemSet, addOnName)
	local controls = { }
	controls.label = new("LabelControl"):LabelControl(nil, {0, 20, 0, 16}, "^7Enter name for this item set:")
	controls.edit = new("EditControl"):EditControl(nil, {0, 40, 350, 20}, itemSet.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 70, 80, 20}, "Save", function()
		itemSet.title = controls.edit.buf
		self.itemsTab.modFlag = true
		if addOnName then
			t_insert(self.list, itemSet.id)
			self.selIndex = #self.list
			self.selValue = itemSet.id
		end
		self.itemsTab:AddUndoState()
		self.itemsTab.build:SyncLoadouts()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {45, 70, 80, 20}, "Cancel", function()
		if addOnName then
			self.itemsTab.itemSets[itemSet.id] = nil
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, itemSet.title and "Rename" or "Set Name", controls, "save", "edit", "cancel")
end

function ItemSetListClass:GetRowValue(column, index, itemSetId)
	local itemSet = self.itemsTab.itemSets[itemSetId]
	if column == 1 then
		local title = itemSet.title or "Default"
		return title .. (itemSetId == self.itemsTab.viewItemSetId and "  ^9(Visible)" or "") .. (itemSetId == self.itemsTab.activeItemSetId and "  ^9(Current player)" or "")
	end
end

function ItemSetListClass:AddValueTooltip(tooltip, index, itemSetId)
	local itemSet = self.itemsTab.itemSets[itemSetId]
	tooltip:Clear()
	self.itemsTab:AddItemSetTooltip(tooltip, itemSet)
end

function ItemSetListClass:GetDragValue(index, itemSetId)
	return "ItemList", self.itemsTab.itemSets[itemSetId]
end

function ItemSetListClass:CanReceiveDrag(type, value)
	return type == "SharedItemList"
end

function ItemSetListClass:ReceiveDrag(type, value, source)
	if type == "SharedItemList" then
		local itemSet = self.itemsTab:NewItemSet()
		itemSet.title = value.title
		for _, slot in ipairs(self.itemsTab.orderedSlots) do
			local slotName = slot.slotName
			local item = value.slots[slotName]
			if item then
				local newItem = new("Item"):Item(item.raw)
				newItem:NormaliseQuality()
				self.itemsTab:AddItem(newItem, true)
				itemSet[slotName].selItemId = newItem.id
			end
		end
		t_insert(self.list, self.selDragIndex or #self.list + 1, itemSet.id)
		self.itemsTab:AddUndoState()
	end
end

function ItemSetListClass:OnOrderChange()
	self.itemsTab.modFlag = true
end

function ItemSetListClass:OnSelClick(index, itemSetId, doubleClick)
	if doubleClick and itemSetId ~= self.itemsTab.viewItemSetId then
		self.itemsTab:SetViewItemSet(itemSetId)
		self.itemsTab:AddUndoState()
	end
end

function ItemSetListClass:OnSelDelete(index, itemSetId)
	local itemSet = self.itemsTab.itemSets[itemSetId]
	if self:CanDeleteItemSet(itemSetId) then
		main:OpenConfirmPopup("Delete Item Set", "Are you sure you want to delete '"..(itemSet.title or "Default").."'?\nThis will not delete any items used by the set.", "Delete", function()
			t_remove(self.list, index)
			self.itemsTab.itemSets[itemSetId] = nil
			self.selIndex = nil
			self.selValue = nil
			local replacementItemSetId = self.list[m_max(1, index)] or self.list[index - 1]
			if itemSetId == self.itemsTab.activeItemSetId then
				self.itemsTab:SetActiveItemSet(replacementItemSetId)
			elseif itemSetId == self.itemsTab.viewItemSetId then
				self.itemsTab:SetViewItemSet(self.list[m_max(1, index - 1)])
			end
			if self.itemsTab.build.configTab then
				self.itemsTab.build.configTab:RemapItemSetId(itemSetId, replacementItemSetId)
			end
			local mercenaryTab = self.itemsTab.build.mercenaryTab
			if mercenaryTab and mercenaryTab.auxiliaryItemSetId == itemSetId then
				mercenaryTab.auxiliaryItemSetId = nil
			end
			self.itemsTab:AddUndoState()
			self.itemsTab.build:SyncLoadouts()
		end)
	end
end

function ItemSetListClass:OnSelKeyDown(index, itemSetId, key)
	local itemSet = self.itemsTab.itemSets[itemSetId]
	if key == "F2" then
		self:RenameSet(itemSet)
	end
end
