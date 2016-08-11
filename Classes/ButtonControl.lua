-- Path of Building
--
-- Class: Button Control
-- Basic button control.
--

local ButtonClass = common.NewClass("ButtonControl", function(self, x, y, width, height, label, onClick, enableFunc)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.label = label
	self.onClick = onClick
	self.enableFunc = enableFunc
end)

function ButtonClass:GetPos()
	return type(self.x) == "function" and self:x() or self.x,
		   type(self.y) == "function" and self:y() or self.y	
end

function ButtonClass:IsMouseOver()
	if self.hidden then
		return false
	end
	local x, y = self:GetPos()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + self.width and cursorY < y + self.height
end

function ButtonClass:Draw()
	if self.hidden then
		return
	end
	local x, y = self:GetPos()
	local enabled = not self.enableFunc or self.enableFunc()
	local mOver = self:IsMouseOver()
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, self.width, self.height)
	if not enabled then
		SetDrawColor(0, 0, 0)
	elseif self.clicked and mOver then
		SetDrawColor(0.5, 0.5, 0.5)
	elseif mOver then
		SetDrawColor(0.33, 0.33, 0.33)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, self.width - 2, self.height - 2)
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.33, 0.33, 0.33)
	end
	DrawString(x + self.width / 2, y + 2, "CENTER_X", self.height - 4, "VAR", self.label)
end

function ButtonClass:OnKeyDown(key)
	if self.enableFunc and not self.enableFunc() then
		return
	end
	if key == "LEFTBUTTON" then
		self.clicked = true
	end
	return self
end

function ButtonClass:OnKeyUp(key)
	if self.enableFunc and not self.enableFunc() then
		return
	end
	if key == "LEFTBUTTON" then
		if self:IsMouseOver() then
			self.onClick()
		end
	end
	self.clicked = false
end
