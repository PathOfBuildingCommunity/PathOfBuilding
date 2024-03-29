-- Path of Building
--
-- Class: List Control
-- Basic list control.
--
-- This is an abstract base class; derived classes can supply these properties and methods to configure the list control:
-- .label  [Adds a label above the top left corner]
-- .dragTargetList  [List of controls that can receive drag events from this list control]
-- .showRowSeparators  [Shows separators between rows]
-- :GetRowValue(column, index, value)  [Required; called to retrieve the text for the given column of the given list value]
-- :GetRowIcon(column, index, value)  [Called to retrieve the icon for the given column of the given list value]
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
-- :OverrideSelectIndex(index) [Called when an index is selected, return true to prevent default action]
-- :SetHighlightColor(index, value) [Called when querying if a row is highlighted by parent element class]
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local ListClass = newClass("ListControl", "Control", "ControlHost", function(self, anchor, x, y, width, height, rowHeight, scroll, isMutable, list, forceTooltip)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.rowHeight = rowHeight
	self.scroll = scroll
	self.isMutable = isMutable
	self.list = list or { }
	self.forceTooltip = forceTooltip
	self.colList = { { } }
	self.tooltip = new("Tooltip")
	self.font = "VAR"
	if self.scroll then
		if self.scroll == "HORIZONTAL" then
			self.scrollH = true
		else
			self.scrollH = false
		end
	end
	self.controls.scrollBarH = new("ScrollBarControl", {"BOTTOM",self,"BOTTOM"}, -8, -1, 0, self.scroll and 16 or 0, rowHeight * 2, "HORIZONTAL") {
		shown = function()
			return self.scrollH
		end,
		width = function()
			local width, height = self:GetSize()
			return width - 18
		end
	}
	self.controls.scrollBarV = new("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, self.scroll and 16 or 0, 0, rowHeight * 2, "VERTICAL") {
		y = function()
			return (self.scrollH and -8 or 0)
		end,
		height = function()
			local width, height = self:GetSize()
			return height - 2 - (self.scrollH and 16 or 0)
		end
	}
	if not self.scroll then
		self.controls.scrollBarH.shown = false
		self.controls.scrollBarV.shown = false
	end
end)

function ListClass:SelectIndex(index)
	self.selValue = self.list[index]
	if not self.selValue then
		return false
	end

	if self.OverrideSelectIndex and self:OverrideSelectIndex(index) then
		return false
	end
	self.selIndex = index
	local width, height = self:GetSize()
	if self.scroll then
		self.controls.scrollBarV:SetContentDimension(#self.list * self.rowHeight, height - 4)
		self.controls.scrollBarV:ScrollIntoView((index - 2) * self.rowHeight, self.rowHeight * 3)
	end
	if self.OnSelect then
		self:OnSelect(self.selIndex, self.selValue)
	end

	return true
end

function ListClass:GetColumnProperty(column, property)
	if type(column[property]) == "function" then
		return column[property](self, column)
	else
		return column[property]
	end
end

function ListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function ListClass:GetRowRegion()
	local width, height = self:GetSize()
	return {
		x = 2,
		y = self.colLabels and 20 or 2,
		width = self.scroll and width - 20 or width,
		height = height - 4 - (self.scroll and self.scrollH and 16 or 0) - (self.colLabels and 18 or 0),
	}
end

function ListClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local rowHeight = self.rowHeight
	local list = self.list

	local colOffset = 0
	for index, column in ipairs(self.colList) do
		column._offset = colOffset
		column._width = self:GetColumnProperty(column, "width") or (index == #self.colList and self.scroll and width - 20 or width - colOffset) or 0
		colOffset = colOffset + column._width
	end

	local scrollBarV = self.controls.scrollBarV
	local rowRegion = self:GetRowRegion()
	scrollBarV:SetContentDimension(#list * rowHeight, rowRegion.height)
	local scrollOffsetV = scrollBarV.offset
	local scrollBarH = self.controls.scrollBarH
	local lastCol = self.colList[#self.colList]
	scrollBarH:SetContentDimension(lastCol._offset + lastCol._width, rowRegion.width)
	local scrollOffsetH = scrollBarH.offset

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
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 20 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + scrollOffsetV) / rowHeight + 0.5) + 1
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
		DrawString(x, y - 20, "LEFT", 16, self.font, label)
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
	self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)

	SetViewport(x + 2, y + 2,  self.scroll and width - 20 or width, height - 4 - (self.scroll and self.scrollH and 16 or 0))
	local textOffsetY = self.showRowSeparators and 2 or 0
	local textHeight = rowHeight - textOffsetY * 2
	local ttIndex, ttValue, ttX, ttY, ttWidth
	local minIndex = m_floor(scrollOffsetV / rowHeight + 1)
	local maxIndex = m_min(m_floor((scrollOffsetV + height) / rowHeight + 1), #list)
	for colIndex, column in ipairs(self.colList) do
		local colFont = self:GetColumnProperty(column, "font") or "VAR"
		local clipWidth = DrawStringWidth(textHeight, colFont, "...")
		colOffset = column._offset - scrollOffsetH
		local colWidth = column._width
		local relX = cursorX - (x + 2)
		local relY = cursorY - (y + 2)
		for index = minIndex, maxIndex do
			local lineY = rowHeight * (index - 1) - scrollOffsetV + (self.colLabels and 18 or 0)
			local value = list[index]
			local text = self:GetRowValue(colIndex, index, value)
			local icon = nil
			if self.GetRowIcon then 
				icon = self:GetRowIcon(colIndex, index, value)
			end
			local textWidth = DrawStringWidth(textHeight, colFont, text)
			if textWidth > colWidth - 2 then
				local clipIndex = DrawStringCursorIndex(textHeight, colFont, text, colWidth - clipWidth - 2, 0)
				text = text:sub(1, clipIndex - 1) .. "..."
				textWidth = DrawStringWidth(textHeight, colFont, text)
			end
			if not scrollBarV.dragging and (not self.selDragActive or (self.CanDragToValue and self:CanDragToValue(index, value, self.otherDragSource))) then
				if relX >= colOffset and relX <  (self.scroll and width - 20 or width) and relY >= 0 and relY >= lineY and relY < height - 2 - (self.scroll and self.scrollH and 18 or 0) and relY < lineY + rowHeight then
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
				DrawImage(nil, colOffset, lineY, not self.scroll and colWidth - 4 or colWidth, rowHeight)
				if (value == self.selValue or value == ttValue) then
					SetDrawColor(0.33, 0.33, 0.33)
				elseif self.otherDragSource and self.CanDragToValue and self:CanDragToValue(index, value, self.otherDragSource) then
					SetDrawColor(0, 0.2, 0)
				elseif index % 2 == 0 then
					SetDrawColor(0.05, 0.05, 0.05)
				else
					SetDrawColor(0, 0, 0)
				end
				DrawImage(nil, colOffset, lineY + 1, not self.scroll and colWidth - 4 or colWidth, rowHeight - 2)
			elseif value == self.selValue or value == ttValue then
				if self.hasFocus and value == self.selValue then
					SetDrawColor(1, 1, 1)
				elseif value == ttValue then
					SetDrawColor(0.8, 0.8, 0.8)
				else
					SetDrawColor(0.5, 0.5, 0.5)
				end
				DrawImage(nil, colOffset, lineY, not self.scroll and colWidth - 4 or colWidth, rowHeight)
				if self.otherDragSource and self.CanDragToValue and self:CanDragToValue(index, value, self.otherDragSource) then
					SetDrawColor(0, 0.2, 0)
				else
					SetDrawColor(0.15, 0.15, 0.15)
				end
				DrawImage(nil, colOffset, lineY + 1, not self.scroll and colWidth - 4 or colWidth, rowHeight - 2)
			end
			if not self.SetHighlightColor or not self:SetHighlightColor(index, value) then
				SetDrawColor(1, 1, 1)
			end
			-- TODO: handle icon size properly, for now assume they are 16x16
			if icon == nil then
				DrawString(colOffset, lineY + textOffsetY, "LEFT", textHeight, colFont, text)
			else
				DrawImage(icon, colOffset, lineY, 16, 16)
				DrawString(colOffset + 16 + 2, lineY + textOffsetY, "LEFT", textHeight, colFont, text)
			end
		end
		if self.colLabels then
			local mOver = relX >= colOffset and relX <= colOffset + colWidth and relY >= 0 and relY <= 18
			if mOver and self:GetColumnProperty(column, "sortable") then
				SetDrawColor(1, 1, 1)
				DrawImage(nil, colOffset, 1, colWidth, 18)
				SetDrawColor(0.33, 0.33, 0.33)
				DrawImage(nil, colOffset + 1, 2, colWidth - 2, 16)
			else
				SetDrawColor(0.5, 0.5, 0.5)
				DrawImage(nil, colOffset, 1, colWidth, 18)
				SetDrawColor(0.15, 0.15, 0.15)
				DrawImage(nil, colOffset + 1, 2, colWidth - 2, 16)
			end
			local label = self:GetColumnProperty(column, "label")
			if label and #label > 0 then
				SetDrawColor(1, 1, 1)
				DrawString(colOffset + colWidth/2, 4, "CENTER_X", 12, "VAR", label)
			end
		end
	end
	if #self.list == 0 and self.defaultText then
		SetDrawColor(1, 1, 1)
		DrawString(2, 2, "LEFT", 14, self.font, self.defaultText)
	end
	if self.selDragIndex then
		local lineY = rowHeight * (self.selDragIndex - 1) - scrollOffsetV
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, lineY - 1, width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, lineY, width - 20, 1)
	end
	SetViewport()

	if self.selDragActive and self.dragTargetList and (not self.isMutable or not self:IsMouseOver()) then
		main.showDragText = self:GetRowValue(1, self.selIndex, self.selValue)
	end

	self.hoverIndex = ttIndex
	self.hoverValue = ttValue
	if ttIndex and self.AddValueTooltip and (not noTooltip or self.forceTooltip) then
		SetDrawLayer(nil, 100)
		self:AddValueTooltip(self.tooltip, ttIndex, ttValue)
		self.tooltip:Draw(ttX, ttY, ttWidth, rowHeight, viewPort)
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
		local newSelect = nil
		local x, y = self:GetPos()
		local cursorX, cursorY = GetCursorPos()
		local rowRegion = self:GetRowRegion()
		if cursorX >= x + rowRegion.x and cursorY >= y + rowRegion.y and cursorX < x + rowRegion.x + rowRegion.width and cursorY < y + rowRegion.y + rowRegion.height then
			local index = math.floor((cursorY - y - rowRegion.y + self.controls.scrollBarV.offset) / self.rowHeight) + 1
			if self.list[index] then
				newSelect = index
			end
		else
			for colIndex, column in ipairs(self.colList) do
				local relX = cursorX - (x + 2)
				local relY = cursorY - (y + 2)
				local mOver = relX >= column._offset and relX <= column._offset + column._width and relY >= 0 and relY <= 18
				if self:GetColumnProperty(column, "sortable") and mOver and self.ReSort then
					self:ReSort(colIndex)
				end
			end
		end

		if self:SelectIndex(newSelect) then
			if (self.isMutable or self.dragTargetList) and self:IsShown() then
				self.selCX = cursorX
				self.selCY = cursorY
				self.selDragging = true
				self.selDragActive = false
			end
			if self.OnSelClick then
				self:OnSelClick(self.selIndex, self.selValue, doubleClick)
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
		if self.OnAnyKeyDown then
			self:OnAnyKeyDown(key)
		end
	end
	return self
end

function ListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if self.controls.scrollBarV:IsScrollDownKey(key) then
		if self.scroll and self.scrollH and IsKeyDown("SHIFT") then
			self.controls.scrollBarH:Scroll(1)
		else
			self.controls.scrollBarV:Scroll(1)
		end
	elseif self.controls.scrollBarV:IsScrollUpKey(key) then
		if self.scroll and self.scrollH and IsKeyDown("SHIFT") then
			self.controls.scrollBarH:Scroll(-1)
		else
			self.controls.scrollBarV:Scroll(-1)
		end
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
						self:OnOrderChange(self.selIndex, self.selDragIndex)
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

function ListClass:GetHoverIndex()
	local x, y = self:GetPos()
	local cursorX, cursorY = GetCursorPos()
	local rowRegion = self:GetRowRegion()
	if cursorX >= x + rowRegion.x and cursorY >= y + rowRegion.y and cursorX < x + rowRegion.x + rowRegion.width and cursorY < y + rowRegion.y + rowRegion.height then
		local index = math.floor((cursorY - y - rowRegion.y + self.controls.scrollBarV.offset) / self.rowHeight) + 1
		if self.list[index] then
			return index
		end
	end
end

function ListClass:GetHoverValue(key)
	local index = self:GetHoverIndex()
	if index then
		local value = self.list[index]
		if value then
			return value
		end
	end
end
