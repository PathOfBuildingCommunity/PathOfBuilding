-- Path of Building
--
-- Class: Item Slot
-- Item Slot control, extends the basic dropdown control
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert

local ItemSlotClass = common.NewClass("ItemSlot", "DropDownControl", function(self, itemsMain, x, y, slotName, slotLabel)
	self.DropDownControl(x, y, 320, 20, { }, function(sel)
		if self.items[sel] ~= self.selItem then
			self.selItem = self.items[sel]
			itemsMain:PopulateSlots()
			itemsMain.buildFlag = true
			itemsMain.modFlag = true
		end
	end)
	self.itemsMain = itemsMain
	self.items = { }
	self.baseX = x
	self.baseY = y
	self.slotName = slotName
	self.label = slotLabel or slotName
	itemsMain.slots[slotName] = self
end)

function ItemSlotClass:Populate()
	wipeTable(self.items)
	wipeTable(self.list)
	self.items[1] = 0
	self.list[1] = "None"
	self.sel = 1
	for _, item in ipairs(self.itemsMain.list) do
		if self.itemsMain:IsItemValidForSlot(item, self.slotName) then
			t_insert(self.items, item.id)
			t_insert(self.list, data.colorCodes[item.rarity]..item.name)
			if item.id == self.selItem then
				self.sel = #self.list
			end
		end
	end
	if not self.selItem or not self.itemsMain.list[self.selItem] or not self.itemsMain:IsItemValidForSlot(self.itemsMain.list[self.selItem], self.slotName) then
		self.selItem = 0
	end
end

function ItemSlotClass:Draw(viewPort)
	self.x = viewPort.x + self.baseX
	self.y = viewPort.y + self.baseY
	DrawString(self.x - 2, self.y + 2, "RIGHT_X", self.height - 4, "VAR", "^7"..self.label..":")
	self.DropDownControl:Draw()
	if self:IsMouseOver() then
		local ttItem
		if self.dropped then
			if self.hoverSel then
				ttItem = self.itemsMain.list[self.items[self.hoverSel]]
			end
		elseif self.selItem and not self.itemsMain.selControl then
			ttItem = self.itemsMain.list[self.selItem]
		end
		if ttItem then
			self.itemsMain:AddItemTooltip(ttItem)
			main:DrawTooltip(self.x, self.y, self.width, self.height, viewPort, data.colorCodes[ttItem.rarity], true)
		end
	end
end
