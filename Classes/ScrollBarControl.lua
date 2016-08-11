-- Path of Building
--
-- Class: Scroll Bar
-- Vertical scroll bar control
--
local launch, main = ...

local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil
local m_floor = math.floor

local ScrollBarClass = common.NewClass("ScrollBarControl", function(self, x, y, width, height, step)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.step = step or width * 2
	self.slideHeight = height - width * 2
	self.offset = 0
end)

function ScrollBarClass:GetPos()
	return type(self.x) == "function" and self:x() or self.x,
		   type(self.y) == "function" and self:y() or self.y
end

function ScrollBarClass:SetContentHeight(conHeight, viewHeight)
	if conHeight <= viewHeight then
		self.enabled = false
		self.offsetMax = 0
		self.offset = 0
	else
		self.enabled = true
		self.knobHeight = m_max(self.width, self.slideHeight * viewHeight / conHeight)
		self.knobTravel = self.slideHeight - self.knobHeight
		self.offsetMax = conHeight - viewHeight
		self.offset = m_min(self.offset, self.offsetMax)
	end
end

function ScrollBarClass:SetOffset(offset)
	self.offset = m_floor(m_max(0, m_min(self.offsetMax, offset)))
end

function ScrollBarClass:Scroll(mult)
	self:SetOffset(self.offset + self.step * mult)
end

function ScrollBarClass:SetOffsetFromKnobY(knobY)
	self:SetOffset(self.offsetMax * (knobY / self.knobTravel))
end

function ScrollBarClass:GetKnobYForOffset()
	return self.knobTravel * (self.offset / self.offsetMax)
end

function ScrollBarClass:IsMouseOver()
	local x, y = self:GetPos()
	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= x and cursorY >= y and cursorX < x + self.width and cursorY < y + self.height
	local mOverComp
	if mOver and self.enabled then
		local relY = cursorY - y
		if relY < self.width then
			mOverComp = "UP"
		elseif relY >= self.height - self.width then
			mOverComp = "DOWN"
		else
			local knobY = self:GetKnobYForOffset()
			if relY < self.width + knobY then
				mOverComp = "SLIDEUP"
			elseif relY >= self.width + knobY + self.knobHeight then
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
	local width, height = self.width, self.height
	local enabled = self.enabled
	local mOver, mOverComp = self:IsMouseOver()
	if self.dragging then
		local cursorX, cursorY = GetCursorPos()
		self:SetOffsetFromKnobY((cursorY - self.dragCY) + self.dragKnobY)
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
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOverComp == "UP" then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, width)
	if enabled and mOverComp == "UP" then
		SetDrawColor(0.33, 0.33, 0.33)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, width - 2, width - 2)
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOverComp == "UP" then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	local x1 = x + width / 2 - width / 4
	local x2 = x1 + width / 2
	local y1 = y + width / 4
	local y2 = y1 + width / 2
	DrawImageQuad(nil, x1, y2, x2, y2, (x1+x2)/2, y1, (x1+x2)/2, y1)
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif self.dragging or mOverComp == "KNOB" or mOverComp == "SLIDEUP" or mOverComp == "SLIDEDOWN" then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y + width, width, self.slideHeight)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + width, width - 2, self.slideHeight)
	if enabled then
		if self.dragging or mOverComp == "KNOB" then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		local knobY = self:GetKnobYForOffset()
		DrawImage(nil, x + 2, y + width + knobY + 1, width - 4, self.knobHeight - 2)
	end
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOverComp == "DOWN" then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y + height - width, width, width)
	if enabled and mOverComp == "DOWN" then
		SetDrawColor(0.33, 0.33, 0.33)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + height - width + 1, width - 2, width - 2)
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOverComp == "DOWN" then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	y1 = y + height - width + width / 4
	y2 = y1 + width / 2
	DrawImageQuad(nil, x1, y1, x2, y1, (x1+x2)/2, y2, (x1+x2)/2, y2)
end

function ScrollBarClass:OnKeyDown(key)
	if not self.enabled then
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
				self.dragCY = cursorY
				self.dragKnobY = self:GetKnobYForOffset()
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
			self:SetOffsetFromKnobY(self:GetKnobYForOffset() - self.knobHeight)
		elseif mOverComp == "SLIDEDOWN" then
			self:SetOffsetFromKnobY(self:GetKnobYForOffset() + self.knobHeight)
		end
	end
	return self
end

function ScrollBarClass:OnKeyUp(key)
	if not self.enabled then
		return
	end
	if key == "LEFTBUTTON" then
		if self.dragging then
			self.dragging = false
			local cursorX, cursorY = GetCursorPos()
			self:SetOffsetFromKnobY((cursorY - self.dragCY) + self.dragKnobY)
		elseif self.holdComp then
			self.holdComp = nil
			self.holdRepeating = nil
			self.holdPauseTime = nil
		end
	end
end
