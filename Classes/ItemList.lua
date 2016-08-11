-- Path of Building
--
-- Class: Item list
-- Basic item list control
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local ItemListClass = common.NewClass("ItemList", function(self, x, y, width, height, itemsMain)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.itemsMain = itemsMain
	self.scrollBar = common.New("ScrollBarControl", 0, 0, 16, height - 2, 32)
end)

function ItemListClass:GetPos()
	return type(self.x) == "function" and self:x() or self.x,
		   type(self.y) == "function" and self:y() or self.y
end

function ItemListClass:IsMouseOver()
	local x, y = self:GetPos()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + self.width and cursorY < y + self.height
end

function ItemListClass:Draw(viewPort)
	local list = self.itemsMain.list
	local orderList = self.itemsMain.orderList
	local x, y = self:GetPos()
	self.selDragIndex = nil
	if self.selItem and self.selDragging then
		local cursorX, cursorY = GetCursorPos()
		if not self.selDragActive and (cursorX-self.selCX)*(cursorX-self.selCX)+(cursorY-self.selCY)*(cursorY-self.selCY) > 100 then
			self.selDragActive = true
		end
		if self.selDragActive then
			if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + self.width - 18 and cursorY < y + self.height - 2 then
				local index = math.floor((cursorY - y - 2 + self.scrollBar.offset) / 16 + 0.5) + 1
				if index < self.selIndex or index > self.selIndex + 1 then
					self.selDragIndex = m_min(index, #orderList + 1)
				end
			end
		end
	end
	if self.itemsMain.selControl == self then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, self.width, self.height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, self.width - 2, self.height - 2)
	self.scrollBar.x = x + self.width - 17
	self.scrollBar.y = y + 1
	self.scrollBar:SetContentHeight(#orderList * 16, self.height - 4)
	self.scrollBar:Draw()
	SetViewport(x + 2, y + 2, self.width - 18, self.height - 4)
	local ttItem, ttY, ttWidth
	for index, itemId in pairs(orderList) do
		local item = list[itemId]
		local itemY = 16 * (index - 1) - self.scrollBar.offset
		local nameWidth = DrawStringWidth(16, "VAR", item.name)
		if not self.scrollBar.dragging and not self.selDragActive and (not self.itemsMain.selControl or self.itemsMain.selControl == self) then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < self.width - 17 and relY >= 0 and relY >= itemY and relY < self.height - 2 and relY < itemY + 16 then
				ttItem = item
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = itemY + y + 2
			end
		end
		if item == ttItem or item == self.selItem then
			if self.itemsMain.selControl == self then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, itemY, self.width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, itemY + 1, self.width - 20, 14)		
		end
		SetDrawColor(data.colorCodes[item.rarity])
		DrawString(0, itemY, "LEFT", 16, "VAR", item.name)
		if not self.itemsMain:GetEquippedSlotForItem(item) then
			DrawString(nameWidth + 8, itemY, "LEFT", 16, "VAR", "^9(Unused)")
		end
	end
	if self.selDragIndex then
		local itemY = 16 * (self.selDragIndex - 1) - self.scrollBar.offset
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, itemY - 1, self.width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, itemY, self.width - 20, 1)
	end
	SetViewport()
	if ttItem then
		self.itemsMain:AddItemTooltip(ttItem)
		SetDrawLayer(nil, 100)
		main:DrawTooltip(x + 2, ttY, ttWidth, 16, viewPort, data.colorCodes[ttItem.rarity], true)
		SetDrawLayer(nil, 0)
	end
end

function ItemListClass:OnKeyDown(key, doubleClick)
	if self.scrollBar:IsMouseOver() then
		return self.scrollBar:OnKeyDown(key)
	end
	if not self:IsMouseOver() and key:match("BUTTON") then
		return
	end
	if key == "LEFTBUTTON" then
		self.selItem = nil
		local x, y = self:GetPos()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + self.width - 18 and cursorY < y + self.height - 2 then
			local index = math.floor((cursorY - y - 2 + self.scrollBar.offset) / 16) + 1
			local selItemId = self.itemsMain.orderList[index]
			if selItemId then
				self.selItem = self.itemsMain.list[selItemId]
				self.selIndex = index
				if doubleClick then
					self.itemsMain:SetDisplayItem(copyTable(self.selItem))
				end
			end
		end
		if self.selItem then
			self.selCX = cursorX
			self.selCY = cursorY
			self.selDragging = true
			self.selDragActive = false
		end
	elseif key == "c" and IsKeyDown("CTRL") then
		if self.selItem then
			Copy(self.selItem.raw)
		end
	end
	return self
end

function ItemListClass:OnKeyUp(key)
	if key == "WHEELDOWN" then
		self.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.scrollBar:Scroll(-1)
	elseif self.selItem then
		if key == "BACK" or key == "DELETE" then
			local equipSlot = self.itemsMain:GetEquippedSlotForItem(self.selItem)
			if equipSlot then
				launch:ShowPrompt(0, 0, 0, self.selItem.name.." is currently equipped in "..equipSlot.label..".\n\nAre you sure you want to delete it? Press Y to confirm.", function(key)
					if key == "y" then
						self.itemsMain:DeleteItem(self.selItem)
						self.selItem = nil
					end
					return true
				end)
			else
				self.itemsMain:DeleteItem(self.selItem)
				self.selItem = nil
			end
		elseif key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex then
					t_remove(self.itemsMain.orderList, self.selIndex)
					if self.selDragIndex > self.selIndex then
						self.selDragIndex = self.selDragIndex - 1
					end
					t_insert(self.itemsMain.orderList, self.selDragIndex, self.selItem.id)
					self.itemsMain:AddUndoState()
					self.selItem = nil
				else
					for slotName, slot in pairs(self.itemsMain.slots) do
						if not slot.inactive and slot:IsMouseOver() then
							if self.itemsMain:IsItemValidForSlot(self.selItem, slotName) and slot.selItemId ~= self.selItem.id then
								slot.selItemId = self.selItem.id
								self.itemsMain:PopulateSlots()
								self.itemsMain.buildFlag = true
								self.itemsMain:AddUndoState()
							end
							self.selItem = nil
							return
						end
					end
				end
			end
		end
	end
	return self
end