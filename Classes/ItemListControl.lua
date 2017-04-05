-- Path of Building
--
-- Class: Item list
-- Build item list control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local ItemListClass = common.NewClass("ItemList", "Control", "ControlHost", function(self, anchor, x, y, width, height, itemsTab)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.itemsTab = itemsTab
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 16, 0, 32)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	self.controls.sort = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, -64, -2, 60, 18, "Sort", function()
		table.sort(itemsTab.orderList, function(a, b)
			local itemA = itemsTab.list[a]
			local itemB = itemsTab.list[b]
			local primSlotA = itemLib.getPrimarySlotForItem(itemA)
			local primSlotB = itemLib.getPrimarySlotForItem(itemB)
			if primSlotA ~= primSlotB then
				if not itemsTab.slotOrder[primSlotA] then
					return false
				elseif not itemsTab.slotOrder[primSlotB] then
					return true
				end
				return itemsTab.slotOrder[primSlotA] < itemsTab.slotOrder[primSlotB]
			end
			local equipSlotA = itemsTab:GetEquippedSlotForItem(itemA)
			local equipSlotB = itemsTab:GetEquippedSlotForItem(itemB)
			if equipSlotA and equipSlotB then
				return itemsTab.slotOrder[equipSlotA.slotName] < itemsTab.slotOrder[equipSlotB.slotName]
			elseif not equipSlotA then
				return false
			elseif not equipSlotB then
				return true
			end
			return itemA.name < itemB.name
		end)
		itemsTab:AddUndoState()
	end)
	self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnKeyUp("DELETE")
	end)
	self.controls.delete.enabled = function()
		return self.selItem ~= nil
	end
end)

function ItemListClass:SelectIndex(index)
	local selItemId = self.itemsTab.orderList[index]
	if selItemId then
		self.selItem = self.itemsTab.list[selItemId]
		self.selIndex = index
		self.controls.scrollBar:ScrollIntoView((index - 2) * 16, 48)
	end
end

function ItemListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function ItemListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.itemsTab.list
	local orderList = self.itemsTab.orderList
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#orderList * 16, height - 4)
	local cursorX, cursorY = GetCursorPos()
	self.selDragIndex = nil
	if self.selItem and self.selDragging then
		if not self.selDragActive and (cursorX-self.selCX)*(cursorX-self.selCX)+(cursorY-self.selCY)*(cursorY-self.selCY) > 100 then
			self.selDragActive = true
		end
	elseif (self.itemsTab.controls.uniqueDB:IsShown() and self.itemsTab.controls.uniqueDB.selDragActive) or (self.itemsTab.controls.rareDB:IsShown() and self.itemsTab.controls.rareDB.selDragActive) then
		self.selDragActive = true
	else
		self.selDragActive = false
	end
	if self.selDragActive then
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + scrollBar.offset) / 16 + 0.5) + 1
			if not self.selDragging or index < self.selIndex or index > self.selIndex + 1 then
				self.selDragIndex = m_min(index, #orderList + 1)
			end
		end
	end
	DrawString(x, y - 20, "LEFT", 16, "VAR", "^7All items:")
	if self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	local ttItem, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / 16 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 16 + 1), #orderList)
	for index = minIndex, maxIndex do
		local item = list[orderList[index]]
		local itemY = 16 * (index - 1) - scrollBar.offset
		local nameWidth = DrawStringWidth(16, "VAR", item.name)
		if not scrollBar.dragging and not self.selDragActive and (not self.itemsTab.selControl or self.hasFocus) and not main.popups[1] then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 17 and relY >= 0 and relY >= itemY and relY < height - 2 and relY < itemY + 16 then
				ttItem = item
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = itemY + y + 2
			end
		end
		if item == ttItem or item == self.selItem then
			if self.hasFocus then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, itemY, width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, itemY + 1, width - 20, 14)		
		end
		SetDrawColor(data.colorCodes[item.rarity])
		DrawString(0, itemY, "LEFT", 16, "VAR", item.name)
		if not self.itemsTab:GetEquippedSlotForItem(item) then
			DrawString(nameWidth + 8, itemY, "LEFT", 16, "VAR", "^9(Unused)")
		end
	end
	if self.selDragIndex then
		local itemY = 16 * (self.selDragIndex - 1) - scrollBar.offset
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, itemY - 1, width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, itemY, width - 20, 1)
	end
	SetViewport()
	if ttItem then
		self.itemsTab:AddItemTooltip(ttItem)
		SetDrawLayer(nil, 100)
		main:DrawTooltip(x + 2, ttY, ttWidth, 16, viewPort, data.colorCodes[ttItem.rarity], true)
		SetDrawLayer(nil, 0)
	end
end

function ItemListClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	if not self:IsMouseOver() and key:match("BUTTON") then
		return
	end
	if key == "LEFTBUTTON" then
		self.selItem = nil
		self.selIndex = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 16) + 1
			local selItemId = self.itemsTab.orderList[index]
			if selItemId then
				self.selItem = self.itemsTab.list[selItemId]
				self.selIndex = index
				if IsKeyDown("CTRL") then
					-- Equip it
					local slotName = itemLib.getPrimarySlotForItem(self.selItem)
					if slotName and self.itemsTab.slots[slotName] then
						if IsKeyDown("SHIFT") then
							local altSlot = slotName:gsub("1","2")
							if self.itemsTab:IsItemValidForSlot(self.selItem, altSlot) then
								slotName = altSlot
							end
						end
						if self.itemsTab.slots[slotName].selItemId == selItemId then
							self.itemsTab.slots[slotName]:SetSelItemId(0)
						else
							self.itemsTab.slots[slotName]:SetSelItemId(selItemId)
						end
						self.itemsTab:PopulateSlots()
						self.itemsTab:AddUndoState()
						self.itemsTab.build.buildFlag = true
					end
				elseif doubleClick then
					self.itemsTab:SetDisplayItem(copyTable(self.selItem))
				end
			end
		end
		if self.selItem then
			self.selCX = cursorX
			self.selCY = cursorY
			self.selDragging = true
			self.selDragActive = false
		end
	elseif key == "UP" then
		self:SelectIndex(((self.selIndex or 1) - 2) % #self.itemsTab.orderList + 1)
	elseif key == "DOWN" then
		self:SelectIndex((self.selIndex or #self.itemsTab.orderList) % #self.itemsTab.orderList + 1)
	elseif key == "HOME" then
		self:SelectIndex(1)
	elseif key == "END" then
		self:SelectIndex(#self.itemsTab.orderList)
	elseif key == "c" and IsKeyDown("CTRL") then
		if self.selItem then
			Copy(itemLib.createItemRaw(self.selItem):gsub("\n","\r\n"))
		end
	end
	return self
end

function ItemListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	elseif self.selItem then
		if key == "BACK" or key == "DELETE" then
			local equipSlot = self.itemsTab:GetEquippedSlotForItem(self.selItem)
			if equipSlot then
				main:OpenConfirmPopup("Delete Item", self.selItem.name.." is currently equipped in "..equipSlot.label..".\nAre you sure you want to delete it?", "Delete", function()
					self.itemsTab:DeleteItem(self.selItem)
					self.selItem = nil
					self.selIndex = nil
				end)
			else
				self.itemsTab:DeleteItem(self.selItem)
				self.selItem = nil
				self.selIndex = nil
			end
		elseif key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex then
					if self.selDragIndex ~= self.selIndex then
						t_remove(self.itemsTab.orderList, self.selIndex)
						if self.selDragIndex > self.selIndex then
							self.selDragIndex = self.selDragIndex - 1
						end
						t_insert(self.itemsTab.orderList, self.selDragIndex, self.selItem.id)
						self.itemsTab:AddUndoState()
						self.selItem = nil
						self.selIndex = nil
					end
				else
					for slotName, slot in pairs(self.itemsTab.slots) do
						if not slot.inactive and slot:IsMouseOver() then
							if self.itemsTab:IsItemValidForSlot(self.selItem, slotName) and slot.selItemId ~= self.selItem.id then
								slot:SetSelItemId(self.selItem.id)
								self.itemsTab:PopulateSlots()
								self.itemsTab:AddUndoState()
								self.itemsTab.build.buildFlag = true
							end
							self.selItem = nil
							self.selIndex = nil
							return
						end
					end
				end
			end
		end
	end
	return self
end