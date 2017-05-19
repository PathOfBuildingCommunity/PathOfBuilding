-- Path of Building
--
-- Class: Item list
-- Build item list control.
--
local launch, main = ...

local pairs = pairs
local t_insert = table.insert

local ItemListClass = common.NewClass("ItemList", "ListControl", function(self, anchor, x, y, width, height, itemsTab)
	self.ListControl(anchor, x, y, width, height, 16, true, itemsTab.orderList)
	self.itemsTab = itemsTab
	self.label = "^7All items:"
	self.dragTargetList = { }
	self.controls.sort = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, -64, -2, 60, 18, "Sort", function()
		itemsTab:SortItemList()
	end)
	self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
end)

function ItemListClass:GetRowValue(column, index, itemId)
	local item = self.itemsTab.list[itemId]
	if column == 1 then
		return data.colorCodes[item.rarity] .. item.name .. (not self.itemsTab:GetEquippedSlotForItem(item) and "  ^9(Unused)" or "")
	end
end

function ItemListClass:AddValueTooltip(index, itemId)
	local item = self.itemsTab.list[itemId]
	if not main.popups[1] then
		self.itemsTab:AddItemTooltip(item, nil, true)
		return data.colorCodes[item.rarity], true
	end
end

function ItemListClass:GetDragValue(index, itemId)
	return "Item", self.itemsTab.list[itemId]
end

function ItemListClass:ReceiveDrag(type, value, source)
	if type == "Item" then
		local newItem = itemLib.makeItemFromRaw(value.raw)
		itemLib.normaliseQuality(newItem)
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
	local item = self.itemsTab.list[itemId]
	if IsKeyDown("CTRL") then
		local slotName = itemLib.getPrimarySlotForItem(item)
		if slotName and self.itemsTab.slots[slotName] then
			if self.itemsTab.slots[slotName].weaponSet == 1 and self.itemsTab.useSecondWeaponSet then
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
		self.itemsTab:SetDisplayItem(copyTable(item))
	end
end

function ItemListClass:OnSelCopy(index, itemId)
	local item = self.itemsTab.list[itemId]
	Copy(itemLib.createItemRaw(item):gsub("\n","\r\n"))
end

function ItemListClass:OnSelDelete(index, itemId)
	local item = self.itemsTab.list[itemId]
	local equipSlot = self.itemsTab:GetEquippedSlotForItem(item)
	if equipSlot then
		main:OpenConfirmPopup("Delete Item", item.name.." is currently equipped in "..equipSlot.label..".\nAre you sure you want to delete it?", "Delete", function()
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
