-- Path of Building
--
-- Class: Check Box Control
-- Basic check box control.
--
---@class CheckBoxControl: Control, TooltipHost
---@field linkStyle? boolean Draw borderless parallel bars instead of a check mark.
local CheckBoxClass = newClass("CheckBoxControl", "Control", "TooltipHost")

function CheckBoxClass:CheckBoxControl(anchor, rect, label, changeFunc, tooltipText, initialState)
	rect[4] = rect[3] or 0
	self:Control(anchor, rect)
	self:TooltipHost(tooltipText)
	self.label = label
	self.labelWidth = DrawStringWidth(self.width - 4, "VAR", label or "") + 5
	self.labelRight = false
	self.changeFunc = changeFunc
	self.state = initialState
	return self
end

function CheckBoxClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()

	-- Include the label in the clickable area.
	local label = self:GetProperty("label")
	if label then
		if not self.labelRight then
			x = x - self.labelWidth
		end
		width = width + self.labelWidth
	end
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function CheckBoxClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local size = self.width
	local enabled = self:IsEnabled()
	local mOver = self:IsMouseOver()
	if self.linkStyle then
		if mOver and enabled then
			local shade = self.clicked and 0.5 or 0.2
			SetDrawColor(shade, shade, shade)
			DrawImage(nil, x, y, size, self.height)
		end
	else
		if not enabled then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif mOver then
			SetDrawColor(1, 1, 1)
		elseif self.borderFunc then
			local r, g, b = self.borderFunc()
			SetDrawColor(r, g, b)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawImage(nil, x, y, size, size)
		if not enabled then
			SetDrawColor(0, 0, 0)
		elseif self.clicked and mOver then
			SetDrawColor(0.5, 0.5, 0.5)
		elseif mOver then
			SetDrawColor(0.33, 0.33, 0.33)
		else
			SetDrawColor(0, 0, 0)
		end
		DrawImage(nil, x + 1, y + 1, size - 2, size - 2)
	end
	if self.state or self.linkStyle then
		if self.linkStyle and not self.state and not mOver then
			SetDrawColor(0.2, 0.2, 0.2)
		elseif not enabled or not self.state then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif mOver then
			SetDrawColor(1, 1, 1)
		elseif self.linkStyle then
			SetDrawColor(0.8, 0.8, 0.8)
		else
			SetDrawColor(0.75, 0.75, 0.75)
		end
		if self.linkStyle then
			DrawImage(nil, x, y + self.height/2 - 3, size, 2)
			DrawImage(nil, x, y + self.height/2 + 1, size, 2)
		else
			main:DrawCheckMark(x + size/2, y + size/2, size * 0.8)
		end
	end
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.33, 0.33, 0.33)
	end
	local label = self:GetProperty("label")
	if label and self.labelRight then
		DrawString(x + self.width + 5, y + 2, nil, size - 4, "VAR", label)
	elseif label then
		DrawString(x - 5, y + 2, "RIGHT_X", size - 4, "VAR", label)
	end
	if mOver and not noTooltip then
		SetDrawLayer(nil, 100)
		self:DrawTooltip(x, y, size, self.height, viewPort, self.state)
		SetDrawLayer(nil, 0)
	end
end

function CheckBoxClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		self.clicked = true
	end
	return self
end

function CheckBoxClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		if self:IsMouseOver() then
			self.state = not self.state
			if self.changeFunc then
				self.changeFunc(self.state)
			end
		end
	end
	self.clicked = false
end
