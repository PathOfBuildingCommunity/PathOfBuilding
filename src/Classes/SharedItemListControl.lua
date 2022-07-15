-- Path of Building
--
-- Class: Item list
-- Shared item list control.
--
local pairs = pairs
local t_insert = table.insert
local t_remove = table.remove

local SharedItemListClass = newClass("SharedItemListControl", "ListControl", function(self, anchor, x, y, width, height, itemsTab, forceTooltip)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", true, main.sharedItemList, forceTooltip)
	self.itemsTab = itemsTab
	self.label = "^7Shared items:"
	self.defaultText = "^x7F7F7FThis is a list of items that will be shared between all of\nyour builds.\nYou can add items to this list by dragging them from\none of the other lists."
	self.dragTargetList = { }
	self.controls.delete = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
end)

function SharedItemListClass:GetRowValue(column, index, item)
	if column == 1 then
		return colorCodes[item.rarity] .. item.name
	end
end

function SharedItemListClass:AddValueTooltip(tooltip, index, item)
	if main.popups[1] then
		tooltip:Clear()
		return
	end
	if tooltip:CheckForUpdate(item, IsKeyDown("SHIFT"), launch.devModeAlt, self.itemsTab.build.outputRevision) then
		self.itemsTab:AddItemTooltip(tooltip, item)
	end
end

function SharedItemListClass:GetDragValue(index, item)
	return "Item", item
end

function SharedItemListClass:ReceiveDrag(type, value, source)
	if type == "Item" then
		local rawItem = { raw = value:BuildRaw() }
		local newItem = new("Item", rawItem.raw)
		if not value.id then
			newItem:NormaliseQuality()
		end
		t_insert(self.list, self.selDragIndex or #self.list, newItem)
	end
end

function SharedItemListClass:OnSelClick(index, item, doubleClick)
	if doubleClick then
		self.itemsTab:CreateDisplayItemFromRaw(item.raw, true)
		self.selDragging = false
	end
end

function SharedItemListClass:OnSelCopy(index, item)
	Copy(item:BuildRaw():gsub("\n","\r\n"))
end

function SharedItemListClass:OnSelDelete(index, item)
	main:OpenConfirmPopup("Delete Item", "Are you sure you want to remove '"..item.name.."' from the shared item list?", "Delete", function()
		t_remove(self.list, index)
		self.selIndex = nil
		self.selValue = nil
	end)
end
