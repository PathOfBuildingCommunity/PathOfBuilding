-- Path of Building
--
-- Class: Check Box Control
-- Basic check box control.
--
local launch, main = ...

local CheckBoxClass = common.NewClass("CheckBoxControl", "Control", function(self, anchor, x, y, size, label, changeFunc, tooltip)
	self.Control(anchor, x, y, size, size)
	self.label = label
	self.changeFunc = changeFunc
	self.tooltip = tooltip
	self.tooltipFunc = function(state)
		local tooltip = self:GetProperty("tooltip")
		if tooltip then
			main:AddTooltipLine(14, tooltip)
		end
	end
end)

function CheckBoxClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds()
end

function CheckBoxClass:Draw(viewPort)
	local x, y = self:GetPos()
	local size = self.width
	local enabled = self:IsEnabled()
	local mOver = self:IsMouseOver()
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver then
		SetDrawColor(1, 1, 1)
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
	if self.state then
		if not enabled then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif mOver then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.75, 0.75, 0.75)
		end
		main:DrawCheckMark(x + size/2, y + size/2, size * 0.8)
	end
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.33, 0.33, 0.33)
	end
	local label = self:GetProperty("label")
	if label then
		DrawString(x - 5, y + 2, "RIGHT_X", size - 4, "VAR", label)
	end
	if mOver then
		SetDrawLayer(nil, 100)
		local col, center = self.tooltipFunc(self.state)
		main:DrawTooltip(x, y, size, size, viewPort, col, center)
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
