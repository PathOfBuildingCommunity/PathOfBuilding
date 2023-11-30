-- Path of Building
--
-- Class: Check Box Control
-- Basic check box control.
--
local CC = UI.CC

local CheckBoxClass = newClass("CheckBoxControl", "Control", "TooltipHost", function(self, anchor, x, y, size, label, changeFunc, tooltipText, initialState)
	self.Control(anchor, x, y, size, size)
	self.TooltipHost(tooltipText)
	self.label = label
	self.labelWidth = DrawStringWidth(size - 4, "VAR", label or "") + 5
	self.changeFunc = changeFunc
	self.state = initialState
end)

function CheckBoxClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()

	-- move x left by label width, increase width by label width
	local label = self:GetProperty("label")
	if label then
		x = x - self.labelWidth
		width = width + self.labelWidth
	end
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function CheckBoxClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local size = self.width
	local enabled = self:IsEnabled()
	local mOver = self:IsMouseOver()
	if not enabled then
		SetDrawColor(CC.CONTROL_BORDER_INACTIVE)
	elseif mOver then
		SetDrawColor(CC.CONTROL_BORDER_HOVER)
	elseif self.borderFunc then
		r, g, b = self.borderFunc()
		SetDrawColor(r, g, b)
	else
		SetDrawColor(CC.CONTROL_BORDER)
	end
	DrawImage(nil, x, y, size, size)
	if not enabled then
		SetDrawColor(CC.CONTROL_BACKGROUND_INACTIVE)
	elseif mOver then
		SetDrawColor(CC.CONTROL_BACKGROUND_HOVER)
	else
		SetDrawColor(CC.CONTROL_BACKGROUND)
	end
	DrawImage(nil, x + 1, y + 1, size - 2, size - 2)
	if self.state then
		if not enabled then
			SetDrawColor(CC.CONTROL_ITEM_INACTIVE)
		elseif mOver then
			SetDrawColor(CC.CONTROL_ITEM_HOVER)
		else
			SetDrawColor(CC.CONTROL_ITEM_ACTIVE)
		end
		main:DrawCheckMark(x + size/2, y + size/2, size * 0.8)
	end
	if enabled then
		SetDrawColor(CC.CONTROL_TEXT)
	else
		SetDrawColor(CC.CONTROL_TEXT_INACTIVE)
	end
	local label = self:GetProperty("label")
	if label then
		SetDrawColor(CC.TEXT_PRIMARY)
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
