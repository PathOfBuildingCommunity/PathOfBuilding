-- Path of Building
--
-- Class: Item Slot
-- Item Slot control, extends the basic dropdown control.
--
local pairs = pairs
local t_insert = table.insert
local m_min = math.min

local itemSlotHelper = require("Modules.ItemSlotHelper")
---@class ItemSlotControl
local ItemSlotClass = newClass("ItemSlotControl", "DropDownControl")

---@param anchor Anchor?
---@param x Prop<number>
---@param y Prop<number>
---@param itemsTab ItemsTab
---@param slotName string
---@param slotLabel string
---@param nodeId integer?
function ItemSlotClass:ItemSlotControl(anchor, x, y, itemsTab, slotName, slotLabel, nodeId)
	self:DropDownControl(anchor, { x, y, 310, 20 }, {}, function(index, value)
		if self.items[index] ~= self.selItemId then
			self:SetSelItemId(self.items[index], itemsTab:GetVisibleItemSet())
			itemsTab:PopulateSlots()
			itemsTab:AddUndoState()
			itemsTab.build.buildFlag = true
		end
	end)
	self.anchor.collapse = true
	self.enabled = function()
		return #self.items > 1
	end
	self.shown = function()
		return not self.inactive
	end
	self.itemsTab = itemsTab
	self.items = { }
	self.selItemId = 0
	self.slotName = slotName
	self.slotNum = tonumber(slotName:match("%d+$") or slotName:match("%d+"))
	if slotName:match("Flask") then
		self.controls.activate = new("CheckBoxControl"):CheckBoxControl({"RIGHT",self,"LEFT"}, {-2, 0, 20}, nil, function(state)
			self.active = state
			local itemSet = itemsTab:GetVisibleItemSet()
			local itemSlot = itemSet and itemSet[itemsTab:GetItemSetSlotName(self.slotName, itemSet)]
			if itemSlot then itemSlot.active = state end
			itemsTab:AddUndoState()
			itemsTab.build.buildFlag = true
		end)
		self.controls.activate.enabled = function()
			return self.selItemId ~= 0
		end
		self.controls.activate.tooltipText = "Activate this flask."
		self.labelOffset = -24
	else
		self.labelOffset = -2
	end
	self.abyssalSocketList = { }
	self.tooltipFunc = function(tooltip, mode, index, itemId)
		local item = itemsTab.items[self.items[index]]
		-- not selControl.ListControl allows hover when All Items or Unique/Rare DB Sections are in focus
		if main.popups[1] or mode == "OUT" or not item or (not self.dropped and itemsTab.selControl and itemsTab.selControl ~= self.controls.activate and not itemsTab.selControl.ListControl) then
			tooltip:Clear(true)
		elseif tooltip:CheckForUpdate(item, launch.devModeAlt, itemsTab.build.outputRevision, IsKeyDown("SHIFT")) then
			itemsTab:AddItemTooltip(tooltip, item, self)
		end
	end
	self.label = slotLabel or slotName
	self.nodeId = nodeId
	return self
end

function ItemSlotClass:SetSelItemId(selItemId, targetItemSet)
	if self.nodeId then
		if self.itemsTab.build.spec then
			self.itemsTab.build.spec.jewels[self.nodeId] = selItemId
			if selItemId ~= self.selItemId then
				self.itemsTab.build.spec:BuildClusterJewelGraphs()
			end
		end
	else
		local itemSet = targetItemSet or self.itemsTab.activeItemSet
		local itemSlot = itemSet and itemSet[self.itemsTab:GetItemSetSlotName(self.slotName, itemSet)]
		if itemSlot then itemSlot.selItemId = selItemId end
	end
	self.selItemId = selItemId
end

function ItemSlotClass:Populate()
	if self.nodeId and self.itemsTab.build.spec then
		self.selItemId = self.itemsTab.build.spec.jewels[self.nodeId] or 0
	elseif not self.nodeId then
		local itemSet = self.itemsTab:GetVisibleItemSet()
		local itemSlot = itemSet and itemSet[self.itemsTab:GetItemSetSlotName(self.slotName, itemSet)]
		self.selItemId = itemSlot and itemSlot.selItemId or 0
		self.active = itemSlot and itemSlot.active or false
		if self.controls.activate then self.controls.activate.state = self.active end
	end

	wipeTable(self.items)
	wipeTable(self.list)
	self.items[1] = 0
	self.list[1] = "None"
	self.selIndex = 1
	for _, item in pairs(self.itemsTab.items) do
		if self.itemsTab:IsItemValidForSlot(item, self.slotName, self.itemsTab:GetVisibleItemSet()) then
			t_insert(self.items, item.id)
			t_insert(self.list, colorCodes[item.rarity]..item.name)
			if item.id == self.selItemId then
				self.selIndex = #self.list
			end
		end
	end
	local selectedItem = self.itemsTab.items[self.selItemId]
	if not self.selItemId or not selectedItem then
		self:SetSelItemId(0, self.itemsTab:GetVisibleItemSet())
	elseif not self.itemsTab:IsItemValidForSlot(selectedItem, self.slotName, self.itemsTab:GetVisibleItemSet()) then
		local inspectingOtherSet = self.itemsTab.viewItemSetId and self.itemsTab.viewItemSetId ~= self.itemsTab.activeItemSetId
		if inspectingOtherSet then
			local alreadyListed = false
			for _, itemId in ipairs(self.items) do
				if itemId == self.selItemId then
					alreadyListed = true
					break
				end
			end
			if not alreadyListed then
				t_insert(self.items, self.selItemId)
				t_insert(self.list, colorCodes.NEGATIVE..selectedItem.name)
				self.selIndex = #self.list
			end
		else
			self:SetSelItemId(0, self.itemsTab:GetVisibleItemSet())
		end
	end

	-- Update Abyssal Sockets
	local abyssalSocketCount = 0
	if self.selItemId > 0 then
		local selItem = self.itemsTab.items[self.selItemId]
		abyssalSocketCount = selItem.abyssalSocketCount or 0
	end
	for i, abyssalSocket in ipairs(self.abyssalSocketList) do
		abyssalSocket.inactive = i > abyssalSocketCount
		if abyssalSocket.inactive then
			-- this can be inconvenient, but otherwise it is possible to double
			-- equip jewels by moving the jewel while the socket is inactive
			abyssalSocket:SetSelItemId(0, self.itemsTab:GetVisibleItemSet())
		end
	end
end

function ItemSlotClass:CanReceiveDrag(type, value)
	return type == "Item" and self.itemsTab:IsItemValidForSlot(value, self.slotName, self.itemsTab:GetVisibleItemSet())
end

function ItemSlotClass:ReceiveDrag(type, value, source)
	if value.id and self.itemsTab.items[value.id] then
		self:SetSelItemId(value.id, self.itemsTab:GetVisibleItemSet())
	else
		local newItem = new("Item"):Item(value.raw)
		newItem:NormaliseQuality()
		self.itemsTab:AddItem(newItem, true)
		self:SetSelItemId(newItem.id, self.itemsTab:GetVisibleItemSet())
		self.itemsTab:AddForbiddenJewelCounterpart(newItem)
	end
	self.itemsTab:PopulateSlots()
	self.itemsTab:AddUndoState()
	self.itemsTab.build.buildFlag = true
end

function ItemSlotClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	DrawString(x + self.labelOffset, y + 2, "RIGHT_X", height - 4, "VAR", "^7"..self.label..":")
	self.DropDownControl:Draw(viewPort)
	self:DrawControls(viewPort)
	if not main.popups[1] and self.nodeId and (self.dropped or (self:IsMouseOver() and (self.otherDragSource or not self.itemsTab.selControl))) then
		local width = 308
		local height = 280
		local viewerY
		if self.DropDownControl.dropUp and self.DropDownControl.dropped then
			viewerY = y + 20
		else
			viewerY = m_min(y - height - 4, viewPort.y + viewPort.height - height)
		end
		itemSlotHelper.DrawViewer(self.itemsTab, self.nodeId, x, viewerY, width, height)
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

function ItemSlotClass:OnHoverKeyUp(key)
	if itemLib.wiki.matchesKey(key) then
		local index = self.DropDownControl:GetHoverIndex()
		if index then
			local itemIndex = self.items[index]
			local item = self.itemsTab.items[itemIndex]

			if item then
				itemLib.wiki.openItem(item)
			end
		end
	end
end
