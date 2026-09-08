-- Path of Building
--
-- Class: Slider Control
-- Basic slider control.
--
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil

---@class SliderControl: Control, TooltipHost
local SliderClass = newClass("SliderControl", "Control", "TooltipHost")

function SliderClass:SliderControl(anchor, rect, changeFunc, scrollWheelSpeedTbl)
	self:Control(anchor, rect)
	self:TooltipHost()
	self.knobSize = self.height - 2
	self.val = 0
	self.changeFunc = changeFunc
	self.scrollWheelSpeedTbl = scrollWheelSpeedTbl or { ["SHIFT"] = 0.25, ["CTRL"] = 0.01, ["DEFAULT"] = 0.05 }
	return self
end

function SliderClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
	local mOverComp
	if mOver then
		local relX = cursorX - x - 2
		local knobX = self:GetKnobXForVal()
		if relX >= knobX and relX < knobX + self.knobSize then
			mOverComp = "KNOB"
		else
			mOverComp = "SLIDE"
		end
	end
	return mOver, mOverComp
end

function SliderClass:GetKnobTravel()
	local width, height = self:GetSize()
	return width - self.knobSize - 2
end

function SliderClass:SetVal(newVal)
	newVal = m_max(0, m_min(1, newVal))
	if newVal ~= self.val then
		self.val = newVal
		if self.changeFunc then
			self.changeFunc(self.val)
		end
	end
end

function SliderClass:GetDivVal(val)
	val = val or self.val
	if self.divCount and self.divCount > 1 then
		local divIndex = m_max(m_ceil(val * self.divCount), 1)
		return divIndex, val * self.divCount - divIndex + 1
	else
		return 1, val
	end
end

function SliderClass:SetValFromKnobX(knobX)
	self:SetVal(knobX / self:GetKnobTravel())
end

function SliderClass:GetKnobXForVal()
	local knobTravel = self:GetKnobTravel()
	return knobTravel * self.val
end

function SliderClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local knobTravel = self:GetKnobTravel()
	if self.dragging and not IsKeyDown("LEFTBUTTON") then
		self.dragging = false
	end
	if self.dragging then
		local cursorX, cursorY = GetCursorPos()
		self:SetValFromKnobX((cursorX - self.dragCX) + self.dragKnobX)
	end
	local mOver, mOverComp = self:IsMouseOver()
	local colors = ui.colors
	local knobX = self:GetKnobXForVal()
	-- Thin track running the length of the control, with the travelled part filled in
	local trackHeight = m_max(4, m_ceil(height / 4))
	local trackY = y + m_ceil((height - trackHeight) / 2)
	local trackRadius = trackHeight / 2
	ui.SetColor(enabled and colors.accent or colors.surfaceDisabled)
	ui.DrawRect(x, trackY, width, trackHeight, trackRadius)
	if enabled then
		if self.dragging or mOver then
			ui.SetColor(colors.primaryHover)
		else
			ui.SetColor(colors.primary)
		end
		ui.DrawRect(x, trackY, m_max(trackHeight, knobX + self.knobSize / 2), trackHeight, trackRadius)
		if self.divCount then
			ui.SetColor(colors.surface)
			for d = 0, knobTravel + 0.5, knobTravel / self.divCount do
				DrawImage(nil, x + self.knobSize/2 + d, trackY, 2, trackHeight)
			end
		end
		-- Round knob, outlined so it stays readable over the filled part of the track
		local knobSize = self.knobSize
		local knobY = y + (height - knobSize) / 2
		ui.SetColor((self.dragging or mOverComp == "KNOB") and colors.borderActive or colors.border)
		ui.DrawCircle(x + 1 + knobX, knobY, knobSize)
		ui.SetColor((self.dragging or mOverComp == "KNOB") and colors.primaryHover or colors.primary)
		ui.DrawCircle(x + 2 + knobX, knobY + 1, knobSize - 2)
	end
	if enabled and (mOver or self.dragging) then
		SetDrawLayer(nil, 100)
		if self.dragging then
			self:DrawTooltip(x, y, width, height, viewPort, self.val)
		else
			local cursorX, cursorY = GetCursorPos()
			local val = (cursorX - x - 1 - self.knobSize / 2) / knobTravel
			self:DrawTooltip(x, y, width, height, viewPort, m_max(0, m_min(1, val)))
		end
		SetDrawLayer(nil, 0)
	end
end

function SliderClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver then
			return
		end
		if not self.dragging then
			self.dragging = true
			local cursorX, cursorY = GetCursorPos()
			self.dragCX = cursorX
			if mOverComp == "SLIDE" then
				local x, y = self:GetPos()
				self:SetValFromKnobX(cursorX - x - 1 - self.knobSize / 2)
			end	
			self.dragKnobX = self:GetKnobXForVal()
		end
	end
	return self
end

function SliderClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		if self.dragging then
			self.dragging = false
			local cursorX, cursorY = GetCursorPos()
			self:SetValFromKnobX((cursorX - self.dragCX) + self.dragKnobX)
		end
	elseif (not main.invertSliderScrollDirection and key == "WHEELDOWN") or (main.invertSliderScrollDirection and  key == "WHEELUP") or key == "DOWN" or key == "LEFT" then
		if IsKeyDown("SHIFT") then
			self:SetVal(self.val - self.scrollWheelSpeedTbl["SHIFT"])
		elseif IsKeyDown("CTRL") then
			self:SetVal(self.val - self.scrollWheelSpeedTbl["CTRL"])
		else
			self:SetVal(self.val - self.scrollWheelSpeedTbl["DEFAULT"])
		end
	elseif (not main.invertSliderScrollDirection and key == "WHEELUP") or (main.invertSliderScrollDirection and key == "WHEELDOWN") or key == "UP" or key == "RIGHT" then
		if IsKeyDown("SHIFT") then
			self:SetVal(self.val + self.scrollWheelSpeedTbl["SHIFT"])
		elseif IsKeyDown("CTRL") then
			self:SetVal(self.val + self.scrollWheelSpeedTbl["CTRL"])
		else
			self:SetVal(self.val + self.scrollWheelSpeedTbl["DEFAULT"])
		end
	end
end
