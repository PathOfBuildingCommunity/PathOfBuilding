-- Path of Building
--
-- Class: List Control
-- Basic list control.
--
-- This is an abstract base class; derived classes can supply these properties and methods to configure the list control:
-- .label  [Adds a label above the top left corner]
-- .dragTargetList  [List of controls that can receive drag events from this list control]
-- .showRowSeparators  [Shows separators between rows]
-- :GetColumnOffset(column)  [Called to get the offset of the given column]
-- :GetRowValue(column, index, value)  [Required; called to retrieve the text for the given column of the given list value]
-- :AddValueTooltip(index, value)  [Called to add the tooltip for the given list value]
-- :GetDragValue(index, value)  [Called to retrieve the drag type and object for the given list value]
-- :CanReceiveDrag(type, value)  [Called on drag target to determine if it can receive this value]
-- :ReceiveDrag(type, value, source)  [Called on the drag target when a drag completes]
-- :OnDragSend(index, value, target)  [Called after a drag event]
-- :OnOrderChange()  [Called after list order is changed through dragging]
-- :OnSelect(index, value)  [Called when a list value is selected]
-- :OnSelClick(index, value, doubleClick)  [Called when a list value is clicked]
-- :OnSelCopy(index, value)  [Called when Ctrl+C is pressed while a list value is selected]
-- :OnSelDelete(index, value)  [Called when backspace or delete is pressed while a list value is selected]
-- :OnSelKeyDown(index, value)  [Called when any other key is pressed while a list value is selected]
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local ListClass = common.NewClass("ListControl", "Control", "ControlHost", function(self, anchor, x, y, width, height, rowHeight, isMutable, list)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.rowHeight = rowHeight
	self.isMutable = isMutable
	self.list = list or { }
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 16, 0, rowHeight * 2)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
end)

function ListClass:SelectIndex(index)
	self.selValue = self.list[index]
	if self.selValue then
		self.selIndex = index
		local width, height = self:GetSize()
		self.controls.scrollBar:SetContentDimension(#self.list * self.rowHeight, height - 4)
		self.controls.scrollBar:ScrollIntoView((index - 2) * self.rowHeight, self.rowHeight * 3)
		if self.OnSelect then
			self:OnSelect(self.selIndex, self.selValue)
		end
	end
end

function ListClass:GetColumnOffset(column)
	if column == 1 then
		return 0
	end
end

function ListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function ListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local rowHeight = self.rowHeight
	local list = self.list
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#list * rowHeight, height - 4)
	local cursorX, cursorY = GetCursorPos()
	if self.selValue and self.selDragging and not self.selDragActive and (cursorX-self.selCX)*(cursorX-self.selCX)+(cursorY-self.selCY)*(cursorY-self.selCY) > 100 then
		self.selDragActive = true
		if self.dragTargetList then
			self.dragType, self.dragValue = self:GetDragValue(self.selIndex, self.selValue)
			for _, target in ipairs(self.dragTargetList) do
				if not target.CanReceiveDrag or target:CanReceiveDrag(self.dragType, self.dragValue) then
					target.otherDragSource = self
				end
			end
		end
	end
	self.selDragIndex = nil
	if (self.selDragActive or self.otherDragSource) and self.isMutable then
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + scrollBar.offset) / rowHeight + 0.5) + 1
			if not self.selIndex or index < self.selIndex or index > self.selIndex + 1 then
				self.selDragIndex = m_min(index, #list + 1)
			end
		end
	end
	if self.selDragActive and self.dragTargetList then 
		self.dragTarget = nil	
		for _, target in ipairs(self.dragTargetList) do
			if not self.dragTarget and target.otherDragSource == self and target:IsMouseOver() then 
				self.dragTarget = target
				target.otherDragTargeting = true
			else
				target.otherDragTargeting = false
			end
		end
	end
	local label = self:GetProperty("label") 
	if label then
		DrawString(x, y - 20, "LEFT", 16, "VAR", label)
	end
	if self.otherDragSource and not self.CanDragToValue then
		SetDrawColor(0.2, 0.6, 0.2)
	elseif self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	if self.otherDragSource and not self.CanDragToValue then
		SetDrawColor(0, 0.05, 0)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	local textOffsetY = self.showRowSeparators and 2 or 0
	local textHeight = rowHeight - textOffsetY * 2
	local ttIndex, ttValue, ttX, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / rowHeight + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / rowHeight + 1), #list)
	local column = 1
	local elipWidth = DrawStringWidth(textHeight, "VAR", "...")
	while true do
		local colOffset = self:GetColumnOffset(column)
		if not colOffset then
			break
		end
		local colWidth = (self:GetColumnOffset(column + 1) or width - 20) - colOffset
		for index = minIndex, maxIndex do
			local lineY = rowHeight * (index - 1) - scrollBar.offset
			local value = list[index]
			local text = self:GetRowValue(column, index, value)
			local textWidth = DrawStringWidth(textHeight, "VAR", text)
			if textWidth > colWidth - 2 then
				local clipIndex = DrawStringCursorIndex(textHeight, "VAR", text, colWidth - elipWidth - 2, 0)
				text = text:sub(1, clipIndex - 1) .. "..."
				textWidth = DrawStringWidth(textHeight, "VAR", text)
			end
			if not scrollBar.dragging and (not self.selDragActive or (self.CanDragToValue and self:CanDragToValue(index, value, self.otherDragSource))) then
				local cursorX, cursorY = GetCursorPos()
				local relX = cursorX - (x + 2)
				local relY = cursorY - (y + 2)
				if relX >= colOffset and relX < width - 20 and relY >= 0 and relY >= lineY and relY < height - 2 and relY < lineY + rowHeight then
					ttIndex = index
					ttValue = value
					ttX = x + 2 + colOffset
					ttY = lineY + y + 2
					ttWidth = m_max(textWidth + 8, relX - colOffset)
				end
			end
			if self.showRowSeparators then
				if self.hasFocus and value == self.selValue then
					SetDrawColor(1, 1, 1)
				elseif value == ttValue then
					SetDrawColor(0.8, 0.8, 0.8)
				else
					SetDrawColor(0.5, 0.5, 0.5)
				end
				DrawImage(nil, colOffset, lineY, colWidth, rowHeight)
				if (value == self.selValue or value == ttValue) then
					SetDrawColor(0.33, 0.33, 0.33)
				elseif self.otherDragSource and self.CanDragToValue and self:CanDragToValue(index, value, self.otherDragSource) then
					SetDrawColor(0, 0.2, 0)
				elseif index % 2 == 0 then
					SetDrawColor(0.05, 0.05, 0.05)
				else
					SetDrawColor(0, 0, 0)
				end
				DrawImage(nil, colOffset, lineY + 1, colWidth, rowHeight - 2)
			elseif value == self.selValue or value == ttValue then
				if self.hasFocus and value == self.selValue then
					SetDrawColor(1, 1, 1)
				elseif value == ttValue then
					SetDrawColor(0.8, 0.8, 0.8)
				else
					SetDrawColor(0.5, 0.5, 0.5)
				end
				DrawImage(nil, colOffset, lineY, colWidth, rowHeight)
				if self.otherDragSource and self.CanDragToValue and self:CanDragToValue(index, value, self.otherDragSource) then
					SetDrawColor(0, 0.2, 0)
				else
					SetDrawColor(0.15, 0.15, 0.15)
				end
				DrawImage(nil, colOffset, lineY + 1, colWidth, rowHeight - 2)
			end
			SetDrawColor(1, 1, 1)
			DrawString(colOffset, lineY + textOffsetY, "LEFT", textHeight, "VAR", text)
		end
		column = column + 1
	end
	if #self.list == 0 and self.defaultText then
		SetDrawColor(1, 1, 1)
		DrawString(2, 2, "LEFT", 14, "VAR", self.defaultText)
	end
	if self.selDragIndex then
		local lineY = rowHeight * (self.selDragIndex - 1) - scrollBar.offset
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, lineY - 1, width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, lineY, width - 20, 1)
	end
	SetViewport()
	if self.selDragActive and self.dragTargetList and (not self.isMutable or not self:IsMouseOver()) then
		local text = self:GetRowValue(1, self.selIndex, self.selValue)
		local strWidth = DrawStringWidth(16, "VAR", text)
		SetDrawLayer(nil, 90)
		SetDrawColor(0.15, 0.15, 0.15, 0.75)
		DrawImage(nil, cursorX, cursorY - 8, strWidth + 2, 18)
		SetDrawColor(1, 1, 1)
		DrawString(cursorX + 1, cursorY - 7, "LEFT", 16, "VAR", text)
		SetDrawLayer(nil, 0)
	end
	self.hoverIndex = ttIndex
	self.hoverValue = ttValue
	if ttIndex and self.AddValueTooltip then
		local col, center = self:AddValueTooltip(ttIndex, ttValue)
		SetDrawLayer(nil, 100)
		main:DrawTooltip(ttX, ttY, ttWidth, rowHeight, viewPort, col, center)
		SetDrawLayer(nil, 0)
	end
end

function ListClass:OnKeyDown(key, doubleClick)
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
		self.selValue = nil
		self.selIndex = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / self.rowHeight) + 1
			self.selValue = self.list[index]
			if self.selValue then
				self.selIndex = index
				if (self.isMutable or self.dragTargetList) and self:IsShown() then
					self.selCX = cursorX
					self.selCY = cursorY
					self.selDragging = true
					self.selDragActive = false
				end
				if self.OnSelect then
					self:OnSelect(self.selIndex, self.selValue)
				end
				if self.OnSelClick then
					self:OnSelClick(self.selIndex, self.selValue, doubleClick)
				end
			end
		end
	elseif #self.list > 0 and not self.selDragActive then
		if key == "UP" then
			self:SelectIndex(((self.selIndex or 1) - 2) % #self.list + 1)
		elseif key == "DOWN" then
			self:SelectIndex((self.selIndex or #self.list) % #self.list + 1)
		elseif key == "HOME" then
			self:SelectIndex(1)
		elseif key == "END" then
			self:SelectIndex(#self.list)
		elseif self.selValue then
			if key == "c" and IsKeyDown("CTRL") then
				if self.OnSelCopy then
					self:OnSelCopy(self.selIndex, self.selValue)
				end
			elseif key == "x" and IsKeyDown("CTRL") then
				if self.OnSelCut then
					self:OnSelCut(self.selIndex, self.selValue)
				end
			elseif key == "BACK" or key == "DELETE" then
				if self.OnSelDelete then
					self:OnSelDelete(self.selIndex, self.selValue)
				end
			elseif self.OnSelKeyDown then
				self:OnSelKeyDown(self.selIndex, self.selValue, key)
			end
		end
	end
	return self
end

function ListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	elseif self.selValue then
		if key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex and self.selDragIndex ~= self.selIndex then
					t_remove(self.list, self.selIndex)
					if self.selDragIndex > self.selIndex then
						self.selDragIndex = self.selDragIndex - 1
					end
					t_insert(self.list, self.selDragIndex, self.selValue)
					if self.OnOrderChange then
						self:OnOrderChange()
					end
					self.selValue = nil
				elseif self.dragTarget then
					self.dragTarget:ReceiveDrag(self.dragType, self.dragValue, self)
					if self.OnDragSend then
						self:OnDragSend(self.selIndex, self.selValue, self.dragTarget)
					end
					self.selValue = nil
				end
				if self.dragTargetList then			
					for _, target in ipairs(self.dragTargetList) do
						target.otherDragSource = nil
						target.otherDragTargeting = false
					end
				end
				self.dragType = nil
				self.dragValue = nil
				self.dragTarget = nil
			end
		end
	end
	return self
end