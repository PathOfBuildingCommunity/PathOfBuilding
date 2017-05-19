-- Path of Building
--
-- Class: Item list
-- Shared item list control.
--
local launch, main = ...

local pairs = pairs
local t_insert = table.insert
local t_remove = table.remove

local SharedItemListClass = common.NewClass("SharedItemList", "ListControl", function(self, anchor, x, y, width, height, itemsTab)
	self.ListControl(anchor, x, y, width, height, 16, true, main.sharedItems)
	self.itemsTab = itemsTab
	self.label = "^7Shared items:"
	self.dragTargetList = { }
	self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
end)

function SharedItemListClass:GetRowValue(column, index, item)
	if column == 1 then
		return data.colorCodes[item.rarity] .. item.name
	end
end

function SharedItemListClass:AddValueTooltip(index, item)
	if not main.popups[1] then
		self.itemsTab:AddItemTooltip(item, nil, true)
		return data.colorCodes[item.rarity], true
	end
end

function SharedItemListClass:GetDragValue(index, item)
	return "Item", item
end

function SharedItemListClass:ReceiveDrag(type, value, source)
	if type == "Item" then
		local newItem = itemLib.makeItemFromRaw(value.raw)
		if not value.id then
			itemLib.normaliseQuality(newItem)
		end
		t_insert(self.list, self.selDragIndex or #self.list, newItem)
	end
end

function SharedItemListClass:OnSelClick(index, item, doubleClick)
	if doubleClick then
		self.itemsTab:CreateDisplayItemFromRaw(item.raw, true)
	end
end

function SharedItemListClass:OnSelCopy(index, item)
	Copy(itemLib.createItemRaw(item):gsub("\n","\r\n"))
end

function SharedItemListClass:OnSelDelete(index, item)
	main:OpenConfirmPopup("Delete Item", "Are you sure you want to remove '"..item.name.."' from the shared item list?", "Delete", function()
		t_remove(self.list, index)
		self.selIndex = nil
		self.selValue = nil
	end)
end
