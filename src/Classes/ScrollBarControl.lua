-- Path of Building
--
-- Class: Scroll Bar
-- Scroll bar control.
--
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil
local m_floor = math.floor

---@class ScrollBarControl: Control
local ScrollBarClass = newClass("ScrollBarControl", "Control")

function ScrollBarClass:ScrollBarControl(anchor, rect, step, dir, autoHide)
	self:Control(anchor, rect)
	self.step = step or self.width * 2
	self.dir = dir or "VERTICAL"
	self.offset = 0
	self.enabled = false
	if autoHide then
		self.shown = function()
			return self.enabled
		end
	end
	return self
end

function ScrollBarClass:SetContentDimension(conDim, viewDim)
	self.conDim = conDim
	self.viewDim = viewDim
	if conDim <= viewDim then
		self.enabled = false
		self.offsetMax = 0
		self.offset = 0
	else
		local width, height = self:GetSize()
		self.enabled = true
		if self.dir == "HORIZONTAL" then
			self.knobDim = m_max(height, (width - height * 2) * viewDim / conDim)
			self.knobTravel = (width - height * 2) - self.knobDim
		else
			self.knobDim = m_max(width, (height - width * 2) * viewDim / conDim)
			self.knobTravel = (height - width * 2) - self.knobDim
		end
		self.offsetMax = conDim - viewDim
		self.offset = m_min(self.offset, self.offsetMax)
	end
end

function ScrollBarClass:SetOffset(offset)
	self.offset = m_floor(m_max(0, m_min(self.offsetMax or 0, offset)))
end

function ScrollBarClass:Scroll(mult)
	self:SetOffset(self.offset + self.step * mult)
end

function ScrollBarClass:ScrollIntoView(minDim, size)
	if self.offset > minDim then
		self:SetOffset(minDim)
	elseif self.offset + self.viewDim < minDim + size then
		self:SetOffset(minDim + size - self.viewDim)
	end
end

function ScrollBarClass:SetOffsetFromKnobPos(knobPos)
	self:SetOffset(self.offsetMax * (knobPos / self.knobTravel))
end

function ScrollBarClass:GetKnobPosForOffset()
	return self.knobTravel * (self.offset / self.offsetMax)
end

function ScrollBarClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
	local mOverComp
	if mOver and self.enabled then
		local relDim
		local shortDim, longDim
		if self.dir == "HORIZONTAL" then
			relDim = cursorX - x
			shortDim = height
			longDim = width
		else
			relDim = cursorY - y
			shortDim = width
			longDim = height
		end
		if relDim < shortDim then
			mOverComp = "UP"
		elseif relDim >= longDim - shortDim then
			mOverComp = "DOWN"
		else
			local knobPos = self:GetKnobPosForOffset()
			if relDim < shortDim + knobPos then
				mOverComp = "SLIDEUP"
			elseif relDim >= shortDim + knobPos + self.knobDim then
				mOverComp = "SLIDEDOWN"
			else
				mOverComp = "KNOB"
			end
		end
	end
	return mOver, mOverComp
end

function ScrollBarClass:Draw()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver, mOverComp = self:IsMouseOver()
	local dir = self.dir
	if not IsKeyDown("LEFTBUTTON") then
		self.dragging = false
	end
	if self.dragging then
		local cursorX, cursorY = GetCursorPos()
		if self.dir == "HORIZONTAL" then
			self:SetOffsetFromKnobPos((cursorX - self.dragCX) + self.dragKnobPos)
		else
			self:SetOffsetFromKnobPos((cursorY - self.dragCY) + self.dragKnobPos)
		end
	elseif self.holdComp then
		if mOverComp == self.holdComp then
			local now = GetTime()
			if not self.holdRepeating then
				if now - self.holdTime > 500 then
					self.holdRepeating = true
					self.holdTime = now - 1
				end
			end
			if self.holdRepeating then
				if self.holdPauseTime then
					self.holdTime = self.holdTime + (now - self.holdPauseTime)
					self.holdPauseTime = nil
				end
				local time = now - self.holdTime
				if self.holdComp == "UP" then
					self:SetOffset(self.holdBase - m_ceil(time / 50) * self.step)
				elseif self.holdComp == "DOWN" then
					self:SetOffset(self.holdBase + m_ceil(time / 50) * self.step)
				end
			end
		elseif self.holdRepeating and not self.holdPauseTime then
			self.holdPauseTime = GetTime()
		end
	end
	local colors = ui.colors
	-- Draw the track behind the whole bar, including the stepper buttons
	ui.SetColor(colors.accentSubtle, 0.6)
	ui.DrawRect(x, y, width, height, ui.radiusSmall)
	-- Draw up/left arrow
	if not enabled then
		ui.SetColor(colors.textDisabled)
	elseif mOverComp == "UP" then
		ui.SetColor(colors.text)
	else
		ui.SetColor(colors.textMuted)
	end
	if dir == "HORIZONTAL" then
		main:DrawArrow(x + height/2, y + height/2, height/2 - 2, height/2 - 2, "LEFT")
	else
		main:DrawArrow(x + width/2, y + width/2, width/2 - 2, width/2 - 2, "UP")
	end
	-- Draw down/right arrow
	if not enabled then
		ui.SetColor(colors.textDisabled)
	elseif mOverComp == "DOWN" then
		ui.SetColor(colors.text)
	else
		ui.SetColor(colors.textMuted)
	end
	if dir == "HORIZONTAL" then
		main:DrawArrow(x + width - height/2, y + height/2, height/2 - 2, height/2 - 2, "RIGHT")
	else
		main:DrawArrow(x + width/2, y + height - width/2, width/2 - 2, width/2 - 2, "DOWN")
	end
	-- Draw knob
	if enabled then
		if self.dragging or mOverComp == "KNOB" then
			ui.SetColor(colors.borderActive)
		elseif mOverComp == "SLIDEUP" or mOverComp == "SLIDEDOWN" then
			ui.SetColor(colors.borderHover)
		else
			ui.SetColor(colors.border)
		end
		local knobPos = self:GetKnobPosForOffset()
		if dir == "HORIZONTAL" then
			ui.DrawRect(x + height + knobPos + 1, y + 3, self.knobDim - 2, height - 6, (height - 6) / 2)
		else
			ui.DrawRect(x + 3, y + width + knobPos + 1, width - 6, self.knobDim - 2, (width - 6) / 2)
		end
	end
end

function ScrollBarClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() or self:GetProperty("locked") then
		return
	end
	if key == "LEFTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver then
			return
		end
		if mOverComp == "KNOB" then
			if not self.dragging then
				self.dragging = true
				local cursorX, cursorY = GetCursorPos()
				self.dragCX = cursorX
				self.dragCY = cursorY
				self.dragKnobPos = self:GetKnobPosForOffset()
			end
		elseif mOverComp == "UP" then
			self:Scroll(-1)
			self.holdComp = "UP"
			self.holdTime = GetTime()
			self.holdBase = self.offset
		elseif mOverComp == "DOWN" then
			self:Scroll(1)
			self.holdComp = "DOWN"
			self.holdTime = GetTime()
			self.holdBase = self.offset
		elseif mOverComp == "SLIDEUP" then
			self:SetOffsetFromKnobPos(self:GetKnobPosForOffset() - self.knobDim)
		elseif mOverComp == "SLIDEDOWN" then
			self:SetOffsetFromKnobPos(self:GetKnobPosForOffset() + self.knobDim)
		end
	end
	return self
end

function ScrollBarClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() or self:GetProperty("locked") then
		return
	end
	if key == "LEFTBUTTON" then
		if self.dragging then
			self.dragging = false
			local cursorX, cursorY = GetCursorPos()
			if self.dir == "HORIZONTAL" then
				self:SetOffsetFromKnobPos((cursorX - self.dragCX) + self.dragKnobPos)
			else
				self:SetOffsetFromKnobPos((cursorY - self.dragCY) + self.dragKnobPos)
			end
		elseif self.holdComp then
			self.holdComp = nil
			self.holdRepeating = nil
			self.holdPauseTime = nil
		end

	elseif self:IsScrollDownKey(key) then
		self:Scroll(1)
	elseif self:IsScrollUpKey(key) then
		self:Scroll(-1)
	end
end

-- Centralize inputs allowed to keep consistent scroll behavior for all scrollBars
function ScrollBarClass:IsScrollDownKey(key)
	return isValueInTable({"WHEELDOWN", "PAGEDOWN"}, key)
end
function ScrollBarClass:IsScrollUpKey(key)
	return isValueInTable({"WHEELUP", "PAGEUP"}, key)
end
