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
	self.tooltipFunc = function()
		local tooltip = self:GetProperty("tooltip")
		if tooltip then
			main:AddTooltipLine(14, tooltip)
		end
	end
end)

function ButtonClass:Click()
	if self:IsShown() and self:IsEnabled() then
		self.onClick()
	end
end

function ButtonClass:SetImage(path)
	if path then
		self.image = NewImageHandle()
		self.image:Load(path)
	else
		self.image = nil
	end
end

function ButtonClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds()
end

function ButtonClass:Draw(viewPort)
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
	if self.image then
		if enabled then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.33, 0.33, 0.33)
		end
		DrawImage(self.image, x + 2, y + 2, width - 4, height - 4)
		if self.clicked and mOver then
			SetDrawColor(1, 1, 1, 0.5)
			DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
		end
	end
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.33, 0.33, 0.33)
	end
	local label = self:GetProperty("label")
	if label == "+" then
		DrawImage(nil, x + width * 0.2, y + height * 0.45, width * 0.6, height * 0.1)
		DrawImage(nil, x + width * 0.45, y + height * 0.2, width * 0.1, height * 0.6)
	elseif label == "-" then
		DrawImage(nil, x + width * 0.2, y + height * 0.45, width * 0.6, height * 0.1)
	elseif label == "x" then
		DrawImageQuad(nil, x + width * 0.1, y + height * 0.2, x + width * 0.2, y + height * 0.1, x + width * 0.9, y + height * 0.8, x + width * 0.8, y + height * 0.9)
		DrawImageQuad(nil, x + width * 0.8, y + height * 0.1, x + width * 0.9, y + height * 0.2, x + width * 0.2, y + height * 0.9, x + width * 0.1, y + height * 0.8)
	else
		local overSize = self.overSizeText or 0
		DrawString(x + width / 2, y + 2 - overSize, "CENTER_X", height - 4 + overSize * 2, "VAR",label )
	end
	if mOver then
		SetDrawLayer(nil, 100)
		local col, center = self.tooltipFunc()
		main:DrawTooltip(x, y, width, height, viewPort, col, center)
		SetDrawLayer(nil, 0)
	end
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
