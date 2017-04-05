-- Path of Building
--
-- Class: Item Slot
-- Item Slot control, extends the basic dropdown control.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min

local ItemSlotClass = common.NewClass("ItemSlot", "DropDownControl", function(self, anchor, x, y, itemsTab, slotName, slotLabel, nodeId)
	self.DropDownControl(anchor, x, y, 310, 20, { }, function(sel)
		if self.items[sel] ~= self.selItemId then
			self:SetSelItemId(self.items[sel])
			itemsTab:PopulateSlots()
			itemsTab:AddUndoState()
			itemsTab.build.buildFlag = true
		end
	end)
	self.enabled = function()
		return #self.items > 1
	end
	self.shown = function()
		return not self.inactive
	end
	self.itemsTab = itemsTab
	self.items = { }
	self.slotName = slotName
	self.slotNum = tonumber(slotName:match("%d+"))
	if slotName:match("Flask") then
		self.controls.activate = common.New("CheckBoxControl", {"RIGHT",self,"LEFT"}, -2, 0, 20, nil, function(state)
			self.active = state
			itemsTab:AddUndoState()
			itemsTab.build.buildFlag = true
		end)
		self.controls.activate.enabled = function()
			return self.selItemId ~= 0
		end
		self.controls.activate.tooltip = "Activate this flask."
		self.labelOffset = -24
	else
		self.labelOffset = -2
	end
	self.label = slotLabel or slotName
	self.nodeId = nodeId
	itemsTab.slots[slotName] = self
	t_insert(itemsTab.orderedSlots, self)
end)

function ItemSlotClass:SetSelItemId(selItemId)
	self.selItemId = selItemId
	if self.nodeId and self.itemsTab.build.spec then
		self.itemsTab.build.spec.jewels[self.nodeId] = selItemId
		self.itemsTab.build.spec:BuildAllDependsAndPaths()
	end
end

function ItemSlotClass:Populate()
	wipeTable(self.items)
	wipeTable(self.list)
	self.items[1] = 0
	self.list[1] = "None"
	self.sel = 1
	for _, item in pairs(self.itemsTab.list) do
		if self.itemsTab:IsItemValidForSlot(item, self.slotName) then
			t_insert(self.items, item.id)
			t_insert(self.list, data.colorCodes[item.rarity]..item.name)
			if item.id == self.selItemId then
				self.sel = #self.list
			end
		end
	end
	if not self.selItemId or not self.itemsTab.list[self.selItemId] or not self.itemsTab:IsItemValidForSlot(self.itemsTab.list[self.selItemId], self.slotName) then
		self:SetSelItemId(0)
	end
end

function ItemSlotClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	DrawString(x + self.labelOffset, y + 2, "RIGHT_X", height - 4, "VAR", "^7"..self.label..":")
	self.DropDownControl:Draw(viewPort)
	self:DrawControls(viewPort)
	local highlight = false
	for _, control in pairs({self.itemsTab.controls.itemList, self.itemsTab.controls.uniqueDB, self.itemsTab.controls.rareDB}) do
		if control:IsShown() and control.selDragging and control.selDragActive and control.selItem and self.itemsTab:IsItemValidForSlot(control.selItem, self.slotName) then
			highlight = true
			SetDrawColor(0, 1, 0, 0.25)
			DrawImage(nil, x, y, width, height)
			break
		end
	end
	if self.nodeId and (self.dropped or (self:IsMouseOver() and (highlight or not self.itemsTab.selControl))) then
		SetDrawLayer(nil, 15)
		local viewerX = x + width + 5
		local viewerY = m_min(y, viewPort.y + viewPort.height - 304)
		SetDrawColor(1, 1, 1)
		DrawImage(nil, viewerX, viewerY, 304, 304)
		local viewer = self.itemsTab.socketViewer
		local node = self.itemsTab.build.spec.nodes[self.nodeId]
		viewer.zoom = 5
		viewer.zoomX = -node.x / 11.85
		viewer.zoomY = -node.y / 11.85
		SetViewport(viewerX + 2, viewerY + 2, 300, 300)
		viewer:Draw(self.itemsTab.build, { x = 0, y = 0, width = 300, height = 300 }, { })
		SetDrawLayer(nil, 30)
		SetDrawColor(1, 1, 1, 0.2)
		DrawImage(nil, 149, 0, 2, 300)
		DrawImage(nil, 0, 149, 300, 2)
		SetViewport()
		SetDrawLayer(nil, 0)
	end
	if self:IsMouseOver() and not main.popups[1] then
		local ttItem
		if self.dropped then
			if self.hoverSel then
				ttItem = self.itemsTab.list[self.items[self.hoverSel]]
			end
		elseif self.selItemId and (not self.itemsTab.selControl or self.itemsTab.selControl == self.controls.activate) then
			ttItem = self.itemsTab.list[self.selItemId]
		end
		if ttItem then
			self.itemsTab:AddItemTooltip(ttItem, self)
			SetDrawLayer(nil, 100)
			main:DrawTooltip(x, y, width, height, viewPort, data.colorCodes[ttItem.rarity], true)
			SetDrawLayer(nil, 0)
		end
	end
end

function ItemSlotClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl == self.controls.activate then
		return mOverControl:OnKeyDown(key)
	end
	return self.DropDownControl:OnKeyDown(key)
end