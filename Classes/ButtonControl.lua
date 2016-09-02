-- Path of Building
--
-- Class: Button Control
-- Basic button control.
--
local launch, main = ...

local ButtonClass = common.NewClass("ButtonControl", "Control", function(self, anchor, x, y, width, height, label, onClick)
	self.Control(anchor, x, y, width, height)
	self.label = label
	self.onClick = onClick
end)

function ButtonClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function ButtonClass:Draw()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver = self:IsMouseOver()
	local locked = self:GetProperty("locked")
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or locked then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	if not enabled then
		SetDrawColor(0, 0, 0)
	elseif self.clicked and mOver then
		SetDrawColor(0.5, 0.5, 0.5)
	elseif mOver or locked then
		SetDrawColor(0.33, 0.33, 0.33)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.33, 0.33, 0.33)
	end
	local overSize = self.overSizeText or 0
	DrawString(x + width / 2, y + 2 - overSize, "CENTER_X", height - 4 + overSize * 2, "VAR", self:GetProperty("label"))
end

function ButtonClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		self.clicked = true
	end
	return self
end

function ButtonClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" and self.clicked then
		self.clicked = false
		if self:IsMouseOver() then
			return self.onClick()
		end
	end
	self.clicked = false
end
