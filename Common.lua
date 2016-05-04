-- Path of Building
--
-- Module: Common
-- Libaries, functions and classes used by various modules.
--

common = { }

common.curl = require("lcurl")
common.xml = require("xml")
common.json = require("dkjson")
common.base64 = require("base64")

function common.controlsInput(host, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if host.selControl then
				if host.selControl:OnKeyDown(event.key, event.doubleClick) then
					host.selControl = nil
				end
				inputEvents[id] = nil
			elseif event.key == "LEFTBUTTON" then
				local cx, cy = GetCursorPos()
				for _, control in pairs(host.controls) do
					if control.IsMouseOver and control:IsMouseOver() and control.OnKeyDown then
						if not control:OnKeyDown(event.key, event.doubleClick) then
							host.selControl = control
						end
						inputEvents[id] = nil
						break
					end
				end
			end
		elseif event.type == "KeyUp" then
			if host.selControl then
				if host.selControl:OnKeyUp(event.key) then
					host.selControl = nil
				end
				inputEvents[id] = nil
			end
		elseif event.type == "Char" then
			if host.selControl then
				if host.selControl.OnChar and host.selControl:OnChar(event.key) then
					host.selControl = nil
				end
				inputEvents[id] = nil
			end
		end
	end	
end

function common.controlsDraw(host, ...)
	for _, control in pairs(host.controls) do
		if control ~= host.selControl then
			control:Draw(...)
		end
	end
	if host.selControl then
		host.selControl:Draw(...)
	end

end

common.newEditField = require("simplegraphic/editfield")

local editMeta = { }
editMeta.__index = editMeta
function editMeta:IsMouseOver()
	if self.hidden then
		return false
	end
	self.edit.x = type(self.x) == "function" and self:x() + 2 or self.x + 2
	self.edit.y = type(self.y) == "function" and self:y() + 2 or self.y + 2
	return self.edit:IsMouseOver()
end
function editMeta:OnKeyDown(key, doubleClick)
	self.edit.x = type(self.x) == "function" and self:x() + 2 or self.x + 2
	self.edit.y = type(self.y) == "function" and self:y() + 2 or self.y + 2
	self.active = not self.edit:OnKeyDown(key, doubleClick)
	return not self.active
end
function editMeta:OnKeyUp(key)
	self.edit.x = type(self.x) == "function" and self:x() + 2 or self.x + 2
	self.edit.y = type(self.y) == "function" and self:y() + 2 or self.y + 2
	self.active = not self.edit:OnKeyUp(key)
	return not self.active
end
function editMeta:OnChar(key)
	self.edit.x = type(self.x) == "function" and self:x() + 2 or self.x + 2
	self.edit.y = type(self.y) == "function" and self:y() + 2 or self.y + 2
	self.active = not self.edit:OnChar(key)
	return not self.active
end
function editMeta:Draw()
	if self.hidden then
		return
	end
	local x = type(self.x) == "function" and self:x() or self.x
	local y = type(self.y) == "function" and self:y() or self.y
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
	self.edit.x = x + 2
	self.edit.y = y + 2
	self.edit:Draw(nil, nil, nil, not self.active)
end
function editMeta:SetText(text)
	self.edit:SetText(text)
end
function common.newEditControl(x, y, width, height, ...)
	local control = { }
	control.x = x
	control.y = y
	control.width = width
	control.height = height
	control.edit = common.newEditField(...)
	control.edit.width = width - 4
	control.edit.height = height - 4
	control.edit.leader = ""
	return setmetatable(control, editMeta)
end

local buttonMeta = { }
buttonMeta.__index = buttonMeta
function buttonMeta:IsMouseOver()
	if self.hidden then
		return false
	end
	local x = type(self.x) == "function" and self:x() or self.x
	local y = type(self.y) == "function" and self:y() or self.y
	local cx, cy = GetCursorPos()
	return cx >= x and cy >= y and cx < x + self.width and cy < y + self.height
end
function buttonMeta:OnKeyDown(key)
	if self.enableFunc and not self.enableFunc() then
		return true
	end
	if key == "LEFTBUTTON" then
		self.clicked = true
	end
	return false
end
function buttonMeta:OnKeyUp(key)
	if self.enableFunc and not self.enableFunc() then
		return true
	end
	if key == "LEFTBUTTON" then
		if self:IsMouseOver() then
			self.onClick()
		end
	end
	self.clicked = false
	return true
end
function buttonMeta:Draw()
	if self.hidden then
		return
	end
	local x = type(self.x) == "function" and self:x() or self.x
	local y = type(self.y) == "function" and self:y() or self.y
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
function common.newButton(x, y, width, height, label, onClick, enableFunc)
	local control = { }
	control.x = x
	control.y = y
	control.width = width
	control.height = height
	control.label = label
	control.onClick = onClick
	control.enableFunc = enableFunc
	return setmetatable(control, buttonMeta)
end

local dropDownMeta = { }
dropDownMeta.__index = dropDownMeta
function dropDownMeta:IsMouseOver()
	if self.hidden then
		return false
	end
	local x = type(self.x) == "function" and self:x() or self.x
	local y = type(self.y) == "function" and self:y() or self.y
	local cx, cy = GetCursorPos()
	local dropExtra = self.dropped and (self.height - 4) * #self.list + 2 or 0
	return cx >= x and cy >= y and cx < x + self.width and cy < y + self.height + dropExtra, cy < y + self.height
end
function dropDownMeta:OnKeyDown(key)
	if self.enableFunc and not self.enableFunc() then
		return true
	end
	if key == "LEFTBUTTON" then
		local all, body = self:IsMouseOver()
		if not all or (self.dropped and body) then
			self.dropped = false
			return true
		end
		self.dropped = true
		return false
	elseif key == "ESCAPE" then
		self.dropped = false
		return true
	end
	return false
end
function dropDownMeta:OnKeyUp(key)
	if self.enableFunc and not self.enableFunc() then
		return true
	end
	if key == "LEFTBUTTON" then
		local all, body = self:IsMouseOver()
		if not all then
			self.dropped = false
			return true
		elseif not body then
			local y = type(self.y) == "function" and self:y() or self.y
			local sel = math.max(1, math.floor((select(2,GetCursorPos()) - y - self.height) / (self.height - 4)) + 1)
			self.sel = sel
			if self.selFunc then
				self.selFunc(sel, self.list[sel])
			end
			self.dropped = false
			return true
		end
	end
	return false
end
function dropDownMeta:Draw()
	if self.hidden then
		return false
	end
	local x = type(self.x) == "function" and self:x() or self.x
	local y = type(self.y) == "function" and self:y() or self.y
	local enabled = not self.enableFunc or self.enableFunc()
	local mOver, mOverBody = self:IsMouseOver()
	local dropExtra = (self.height - 4) * #self.list + 4
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or self.dropped then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, self.width, self.height)
	if self.dropped then
		DrawImage(nil, x, y + self.height, self.width, dropExtra)
	end
	if not enabled then
		SetDrawColor(0, 0, 0)
	elseif self.dropped then
		SetDrawColor(0.5, 0.5, 0.5)
	elseif mOver then
		SetDrawColor(0.33, 0.33, 0.33)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, self.width - 2, self.height - 2)
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or self.dropped then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	local x1 = x + self.width - self.height / 2 - self.height / 4
	local x2 = x1 + self.height / 2
	local y1 = y + self.height / 4
	local y2 = y1 + self.height / 2
	DrawImageQuad(nil, x1, y1, x2, y1, (x1+x2)/2, y2, (x1+x2)/2, y2)
	if self.dropped then
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, y + self.height + 1, self.width - 2, dropExtra - 2)
	end
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.66, 0.66, 0.66)
	end
	DrawString(x + 2, y + 2, "LEFT", self.height - 4, "VAR", self.list[self.sel] or "")
	if self.dropped then
		self.hoverSel = mOver and math.floor((select(2,GetCursorPos()) - y - self.height) / (self.height - 4)) + 1
		if self.hoverSel and self.hoverSel < 1 then
			self.hoverSel = nil
		end
		for index, val in ipairs(self.list) do
			local y = y + self.height + 2 + (index - 1) * (self.height - 4)
			if index == self.hoverSel then
				SetDrawColor(0.5, 0.4, 0.3)
				DrawImage(nil, x + 2, y, self.width - 4, self.height - 4)
			end
			if index == self.hoverSel or index == self.sel then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.66, 0.66, 0.66)
			end
			DrawString(x + 2, y, "LEFT", self.height - 4, "VAR", StripEscapes(val))
		end
	end
end
function dropDownMeta:SelByValue(val)
	for index, listVal in ipairs(self.list) do
		if listVal == val then
			self.sel = index
			return
		end
	end
end
function common.newDropDown(x, y, width, height, list, selFunc, enableFunc)
	local control = { }
	control.x = x
	control.y = y
	control.width = width
	control.height = height
	control.list = list or { }
	control.sel = 1
	control.selFunc = selFunc
	control.enableFunc = enableFunc
	return setmetatable(control, dropDownMeta)
end

function common.drawPopup(r, g, b, fmt, ...)
	local screenW, screenH = GetScreenSize()
	SetDrawColor(0, 0, 0, 0.5)
	DrawImage(nil, 0, 0, screenW, screenH)
	local txt = string.format(fmt, ...)
	local w = DrawStringWidth(20, "VAR", txt) + 20
	local h = (#txt:gsub("[^\n]","") + 2) * 20
	local ox = (screenW - w) / 2
	local oy = (screenH - h) / 2
	SetDrawColor(1, 1, 1)
	DrawImage(nil, ox, oy, w, h)
	SetDrawColor(r, g, b)
	DrawImage(nil, ox + 2, oy + 2, w - 4, h - 4)
	SetDrawColor(1, 1, 1)
	DrawImage(nil, ox + 4, oy + 4, w - 8, h - 8)
	DrawString(0, oy + 10, "CENTER", 20, "VAR", txt)
end

function copyTable(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			out[k] = copyTable(v)
		else
			out[k] = v
		end
	end
	return out
end

function wipeTable(tbl)
	if not tbl then
		return { }
	end
	for k in pairs(tbl) do
		tbl[k] = nil
	end
	return tbl
end

function isValueInTable(tbl, val)
	for k, v in pairs(tbl) do
		if val == v then
			return k
		end
	end
end

function isValueInArray(tbl, val)
	for i, v in ipairs(tbl) do
		if val == v then
			return i
		end
	end
end
