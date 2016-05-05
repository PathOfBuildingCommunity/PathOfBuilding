-- Path of Building
--
-- Class: Item Slot
-- Item Slot control, wrapper for the basic dropdown control
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert

local ItemSlotClass = common.NewClass("ItemSlot", function(self, itemsMain, x, y, slotName, slotLabel)
	self.itemsMain = itemsMain
	self.items = { }
	self.list = { }
	self.x = x
	self.y = y
	self.width = 320
	self.height = 20
	self.slotName = slotName
	self.label = slotLabel or slotName
	self.dropDown = common.New("DropDownControl", x, y, self.width, self.height, self.list, function(sel)
		if self.itemsMain[sel] ~= self.selItem then
			self.selItem = self.itemsMain[sel]
			itemsMain:PopulateSlots()
			itemsMain.buildFlag = true
			itemsMain.modFlag = true
		end
	end)
	itemsMain.slots[slotName] = self
end)

function ItemSlotClass:Populate()
	wipeTable(self.items)
	wipeTable(self.list)
	self.items[1] = 0
	self.list[1] = "None"
	self.dropDown.sel = 1
	for _, item in ipairs(self.itemsMain.list) do
		if self.itemsMain:IsItemValidForSlot(item, self.slotName) then
			t_insert(self.items, item.id)
			t_insert(self.list, data.colorCodes[item.rarity]..item.name)
			if item.id == self.selItem then
				self.dropDown.sel = #self.list
			end
		end
	end
	if not self.selItem or not self.itemsMain.list[self.selItem] or not self.itemsMain:IsItemValidForSlot(self.itemsMain.list[self.selItem], self.slotName) then
		self.selItem = 0
	end
end

function ItemSlotClass:IsMouseOver()
	return self.dropDown:IsMouseOver()
end

function ItemSlotClass:Draw(viewPort)
	self.dropDown.x = viewPort.x + self.x
	self.dropDown.y = viewPort.y + self.y
	DrawString(self.dropDown.x - 2, self.dropDown.y + 2, "RIGHT_X", self.height - 4, "VAR", "^7"..self.label..":")
	self.dropDown:Draw()
	if self.dropDown:IsMouseOver() then
		local ttItem
		if self.dropDown.dropped then
			if self.dropDown.hoverSel then
				ttItem = itemsMain.list[self.items[self.dropDown.hoverSel]]
			end
		elseif self.selItem and not self.itemsMain.selControl then
			ttItem = self.itemsMain.list[self.selItem]
		end
		if ttItem then
			self.itemsMain:AddItemTooltip(ttItem)
			main:DrawTooltip(self.dropDown.x, self.dropDown.y, self.width, self.height, viewPort, data.colorCodes[ttItem.rarity], true)
		end
	end
end

function ItemSlotClass:OnKeyDown(key)
	return self.dropDown:OnKeyDown(key)
end

function ItemSlotClass:OnKeyUp(key)
	return self.dropDown:OnKeyUp(key)
end
