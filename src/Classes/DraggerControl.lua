-- Path of Building
--
-- Class: Dragger Button Control
-- Dragger button control.
--
local DraggerClass = newClass("DraggerControl", "Control", "TooltipHost", function(self, anchor, rect, label, onKeyDown, onKeyUp, onRightClick, onHover, forceTooltip)
	self.Control(anchor, rect)
	self.TooltipHost()
	self.label = label
	self.onKeyDown = onKeyDown
	self.onKeyUp = onKeyUp
	self.onRightClick = onRightClick
	self.onHover = onHover
	self.forceTooltip = forceTooltip
	self.cursorX = 0
	self.cursorY = 0
end)

function DraggerClass:SetImage(path)
	if path then
		self.image = NewImageHandle()
		self.image:Load(path)
	else
		self.image = nil
	end
end

function DraggerClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds()
end

function DraggerClass:Draw(viewPort, noTooltip)
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
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or locked or self.dragging then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	local label = self:GetProperty("label")
	if label == "+" then
		DrawImage(nil, x + width * 0.2, y + height * 0.45, width * 0.6, height * 0.1)
		DrawImage(nil, x + width * 0.45, y + height * 0.2, width * 0.1, height * 0.6)
	elseif label == "-" then
		DrawImage(nil, x + width * 0.2, y + height * 0.45, width * 0.6, height * 0.1)
	elseif label == "x" then
		DrawImageQuad(nil, x + width * 0.2, y + height * 0.3, x + width * 0.3, y + height * 0.2, x + width * 0.8, y + height * 0.7, x + width * 0.7, y + height * 0.8)
		DrawImageQuad(nil, x + width * 0.7, y + height * 0.2, x + width * 0.8, y + height * 0.3, x + width * 0.3, y + height * 0.8, x + width * 0.2, y + height * 0.7)
	elseif label == "//" then
		DrawImageQuad(nil,  x + width * 0.75, y + height * 0.15, x + width * 0.85, y + height * 0.25, x + width * 0.25, y + height * 0.85, x + width * 0.15, y + height * 0.75)
		DrawImageQuad(nil,  x + width * 0.75, y + height * 0.5, x + width * 0.85, y + height * 0.6, x + width * 0.6, y + height * 0.85, x + width * 0.5, y + height * 0.75)
	else
		local overSize = self.overSizeText or 0
		DrawString(x + width / 2, y + 2 - overSize, "CENTER_X", height - 4 + overSize * 2, "VAR", label)
	end
	if mOver then
		if not noTooltip or self.forceTooltip then
			SetDrawLayer(nil, 100)
			self:DrawTooltip(x, y, width, height, viewPort)
			SetDrawLayer(nil, 0)
		end
		if self.onHover ~= nil then
			return self.onHover()
		end
	end
end

function DraggerClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() or self:GetProperty("locked") then
		return
	end
	if key == "LEFTBUTTON" then
		local cursorX, cursorY = GetCursorPos()

		self.clicked = true
		self.dragging = true
		if self.onKeyDown then
			self.onKeyDown({ X = cursorX, Y = cursorY })
		end
		
		self.cursorX = cursorX
		self.cursorY = cursorY
	end
	return self
end
function DraggerClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() or self:GetProperty("locked") then
		return
	end
	local cursorX, cursorY = GetCursorPos()
	if key == "LEFTBUTTON" then
		self.clicked = false
		self.dragging = false
		if self.onKeyUp then
			self.onKeyUp({ X = self.cursorX - cursorX, Y = self.cursorY - cursorY })
		end
	end
	if key == "RIGHTBUTTON" and self:IsMouseInBounds() then
		if self.onRightClick then
			self.onRightClick({ X = cursorX, Y = cursorY })
		end
	end
	return self
end