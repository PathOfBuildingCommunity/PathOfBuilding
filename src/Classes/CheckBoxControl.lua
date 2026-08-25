-- Path of Building
--
-- Class: Check Box Control
-- Basic check box control.
--
---@class CheckBoxControl: Control, TooltipHost
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
	local colors = ui.colors
	local radius = ui.FitRadius(ui.radiusSmall, size, size)
	local border, fill = ui.SurfaceColors(enabled, mOver, self.clicked and mOver)
	if self.borderFunc and enabled and not mOver then
		local r, g, b = self.borderFunc()
		border = ui.PackColor(r, g, b)
	end
	-- A ticked box is filled with the emphasis colour and carries a dark check mark, like the
	-- unticked box inverted
	if self.state and enabled then
		border = mOver and colors.primaryHover or colors.primary
		fill = border
	end
	ui.DrawBox(x, y, size, size, radius, border, fill)
	if self.state then
		if not enabled then
			ui.SetColor(colors.textDisabled)
		else
			ui.SetColor(colors.onPrimary)
		end
		main:DrawCheckMark(x + size/2, y + size/2, size * 0.7)
	end
	ui.SetColor(enabled and colors.text or colors.textDisabled)
	local label = self:GetProperty("label")
	if label and self.labelRight then
		DrawString(x + self.width + 5, y + 2, nil, size - 4, "VAR", label)
	elseif label then
		DrawString(x - 5, y + 2, "RIGHT_X", size - 4, "VAR", label)
	end
	if mOver and not noTooltip then
		SetDrawLayer(nil, 100)
		self:DrawTooltip(x, y, size, size, viewPort, self.state)
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
