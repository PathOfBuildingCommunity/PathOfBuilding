-- Path of Building
--
-- Class: Edit Control
-- Wrapper for the basic edit field.
--

local EditClass = common.NewClass("EditControl", function(self, x, y, width, height, ...)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.edit = common.newEditField(...)
	self.edit.width = width - 4
	self.edit.height = height - 4
	self.edit.leader = ""
end)

function EditClass:SetText(text)
	self.edit:SetText(text)
end

function EditClass:UpdatePosition()
	local x = type(self.x) == "function" and self:x() or self.x
	local y = type(self.y) == "function" and self:y() or self.y
	self.edit.x = x + 2
	self.edit.y = y + 2
	return x, y
end

function EditClass:IsMouseOver()
	if self.hidden then
		return false
	end
	self:UpdatePosition()
	return self.edit:IsMouseOver()
end

function EditClass:Draw()
	if self.hidden then
		return
	end
	local x, y = self:UpdatePosition()
	local enabled = not self.edit.enableFunc or self.edit.enableFunc()
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
	elseif self.active or mOver then
		SetDrawColor(0.15, 0.15, 0.15)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, self.width - 2, self.height - 2)
	self.edit:Draw(nil, nil, nil, not self.active)
end

function EditClass:OnKeyDown(key, doubleClick)
	self:UpdatePosition()
	self.active = not self.edit:OnKeyDown(key, doubleClick)
	return self.active and self
end

function EditClass:OnKeyUp(key)
	self:UpdatePosition()
	self.active = not self.edit:OnKeyUp(key)
	return self.active and self
end

function EditClass:OnChar(key)
	self:UpdatePosition()
	self.active = not self.edit:OnChar(key)
	return self.active and self
end
