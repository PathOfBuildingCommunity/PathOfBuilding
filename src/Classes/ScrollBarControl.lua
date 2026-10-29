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
		local length = self.dir == "HORIZONTAL" and width or height
		self.enabled = true
		-- The knob runs the whole length of the bar; there are no stepper buttons to make room for
		self.knobDim = m_max(m_min(length, 24), length * viewDim / conDim)
		self.knobTravel = length - self.knobDim
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
		local relDim = self.dir == "HORIZONTAL" and cursorX - x or cursorY - y
		local knobPos = self:GetKnobPosForOffset()
		if relDim < knobPos then
			mOverComp = "SLIDEUP"
		elseif relDim >= knobPos + self.knobDim then
			mOverComp = "SLIDEDOWN"
		else
			mOverComp = "KNOB"
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
				if self.holdComp == "SLIDEUP" then
					self:SetOffset(self.holdBase - m_ceil(time / 50) * self.step)
				elseif self.holdComp == "SLIDEDOWN" then
					self:SetOffset(self.holdBase + m_ceil(time / 50) * self.step)
				end
			end
		elseif self.holdRepeating and not self.holdPauseTime then
			self.holdPauseTime = GetTime()
		end
	end
	-- Nothing to scroll, so nothing to show
	if not enabled then
		return
	end
	local colors = ui.colors
	local horizontal = dir == "HORIZONTAL"
	-- Thickness of the bar across its short axis; the track is a thin rail down the middle of it,
	-- while the full width stays clickable
	local shortDim = horizontal and height or width
	local active = self.dragging or mOver
	local trackDim = m_max(4, shortDim - 8)
	local trackOff = m_floor((shortDim - trackDim) / 2)
	ui.SetColor(colors.accentSubtle, active and 0.9 or 0.55)
	if horizontal then
		ui.DrawRect(x, y + trackOff, width, trackDim, trackDim / 2)
	else
		ui.DrawRect(x + trackOff, y, trackDim, height, trackDim / 2)
	end
	-- Knob, which fattens up while the bar is being used
	if self.dragging or mOverComp == "KNOB" then
		ui.SetColor(colors.borderActive)
	elseif mOver then
		ui.SetColor(colors.borderHover)
	else
		ui.SetColor(colors.border)
	end
	local knobDim = active and m_max(6, shortDim - 3) or trackDim
	local knobOff = m_floor((shortDim - knobDim) / 2)
	local knobPos = m_floor(self:GetKnobPosForOffset())
	if horizontal then
		ui.DrawRect(x + knobPos, y + knobOff, self.knobDim, knobDim, knobDim / 2)
	else
		ui.DrawRect(x + knobOff, y + knobPos, knobDim, self.knobDim, knobDim / 2)
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
		elseif mOverComp == "SLIDEUP" or mOverComp == "SLIDEDOWN" then
			-- Clicking the track pages towards the cursor, and holding keeps scrolling that way
			-- until the knob catches up
			local step = mOverComp == "SLIDEUP" and -self.knobDim or self.knobDim
			self:SetOffsetFromKnobPos(self:GetKnobPosForOffset() + step)
			self.holdComp = mOverComp
			self.holdTime = GetTime()
			self.holdBase = self.offset
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
