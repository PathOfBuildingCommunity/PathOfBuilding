-- Path of Building
--
-- Class: Item Slot
-- Item Slot control, extends the basic dropdown control
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min

local ItemSlotClass = common.NewClass("ItemSlot", "DropDownControl", function(self, itemsMain, x, y, slotName, slotLabel, nodeId)
	self.DropDownControl(x, y, 320, 20, { }, function(sel)
		if self.items[sel] ~= self.selItemId then
			self.selItemId = self.items[sel]
			itemsMain:PopulateSlots()
			itemsMain.buildFlag = true
			itemsMain:AddUndoState()
		end
	end, function() return #self.items > 1 end)
	self.itemsMain = itemsMain
	self.items = { }
	self.baseX = x
	self.baseY = y
	self.slotName = slotName
	self.label = slotLabel or slotName
	self.nodeId = nodeId
	itemsMain.slots[slotName] = self
end)

function ItemSlotClass:Populate()
	wipeTable(self.items)
	wipeTable(self.list)
	self.items[1] = 0
	self.list[1] = "None"
	self.sel = 1
	for _, item in pairs(self.itemsMain.list) do
		if self.itemsMain:IsItemValidForSlot(item, self.slotName) then
			t_insert(self.items, item.id)
			t_insert(self.list, data.colorCodes[item.rarity]..item.name)
			if item.id == self.selItemId then
				self.sel = #self.list
			end
		end
	end
	if not self.selItemId or not self.itemsMain.list[self.selItemId] or not self.itemsMain:IsItemValidForSlot(self.itemsMain.list[self.selItemId], self.slotName) then
		self.selItemId = 0
	end
end

function ItemSlotClass:Draw(viewPort)
	self.x = viewPort.x + self.baseX
	self.y = viewPort.y + self.baseY
	DrawString(self.x - 2, self.y + 2, "RIGHT_X", self.height - 4, "VAR", "^7"..self.label..":")
	self.DropDownControl:Draw()
	if self.itemsMain.controls.itemList.selDragActive and self.itemsMain:IsItemValidForSlot(self.itemsMain.controls.itemList.selItem, self.slotName) then
		SetDrawColor(0, 1, 0, 0.25)
		DrawImage(nil, self.x, self.y, self.width, self.height)
	end
	if self.nodeId and (self.dropped or (self:IsMouseOver() and not self.itemsMain.selControl)) then
		SetDrawLayer(nil, 10)
		local viewerX = self.x + self.width + 5
		local viewerY = m_min(self.y, viewPort.y + viewPort.height - 300)
		SetDrawColor(1, 1, 1)
		DrawImage(nil, viewerX, viewerY, 304, 304)
		local viewer = self.itemsMain.socketViewer
		local node = self.itemsMain.build.spec.nodes[self.nodeId]
		viewer.zoom = 5
		viewer.zoomX = -node.x / 11.85
		viewer.zoomY = -node.y / 11.85
		SetViewport(viewerX + 2, viewerY + 2, 300, 300)
		viewer:DrawTree(self.itemsMain.build, { x = 0, y = 0, width = 300, height = 300}, { }, true)
		SetDrawColor(1, 1, 1, 0.1)
		DrawImage(nil, 149, 0, 2, 300)
		DrawImage(nil, 0, 149, 300, 2)
		SetViewport()
		SetDrawLayer(nil, 0)
	end
	if self:IsMouseOver() then
		local ttItem
		if self.dropped then
			if self.hoverSel then
				ttItem = self.itemsMain.list[self.items[self.hoverSel]]
			end
		elseif self.selItemId and not self.itemsMain.selControl then
			ttItem = self.itemsMain.list[self.selItemId]
		end
		if ttItem then
			self.itemsMain:AddItemTooltip(ttItem)
			SetDrawLayer(nil, 100)
			main:DrawTooltip(self.x, self.y, self.width, self.height, viewPort, data.colorCodes[ttItem.rarity], true)
			SetDrawLayer(nil, 0)
		end
	end
end
