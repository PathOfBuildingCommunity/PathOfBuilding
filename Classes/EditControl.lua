-- Path of Building
--
-- Class: Edit Control
-- Basic edit control.
--
local launch, main = ...

local EditClass = common.NewClass("EditControl", "Control", function(self, anchor, x, y, width, height, init, prompt, filter, limit, changeFunc, style)
	self.Control(anchor, x, y, width, height)
	self:SetText(init or "")
	self.prompt = prompt
	self.filter = filter or "[%w%p ]"
	self.limit = limit
	self.changeFunc = changeFunc
	self.textCol = (style and style.textCol) or "^7"
	self.inactiveCol = (style and style.inactiveCol) or "^8"
	self.disableCol = (style and style.disableCol) or "^9"
	self.selCol = (style and style.selCol) or "^0"
	self.selBGCol = (style and style.selBGCol) or "^xBBBBBB"
	self.blinkStart = GetTime()
end)

function EditClass:SetText(text)
	self.buf = tostring(text)
	self.caret = #self.buf + 1
	self.sel = nil
end

function EditClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function EditClass:ReplaceSel(text)
	for i = 1, #text do
		if not text:sub(i,i):match(self.filter) then
			return
		end
	end
	local left = math.min(self.caret, self.sel)
	local right = math.max(self.caret, self.sel)
	local newBuf = self.buf:sub(1, left - 1) .. text .. self.buf:sub(right)
	if self.limit and #newBuf > self.limit then
		return
	end
	self.buf = newBuf
	self.caret = left + #text
	self.sel = nil
	self.blinkStart = GetTime()
	if self.changeFunc then
		self.changeFunc(self.buf)
	end
end

function EditClass:Insert(text)
	for i = 1, #text do
		if not text:sub(i,i):match(self.filter) then
			return
		end
	end
	local newBuf = self.buf:sub(1, self.caret - 1) .. text .. self.buf:sub(self.caret)
	if self.limit and #newBuf > self.limit then
		return
	end
	self.buf = newBuf
	self.caret = self.caret + #text
	self.sel = nil
	self.blinkStart = GetTime()
	if self.changeFunc then
		self.changeFunc(self.buf)
	end
end

function EditClass:Draw()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver = self:IsMouseOver()
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	if not enabled then
		SetDrawColor(0, 0, 0)
	elseif self.hasFocus or mOver then
		SetDrawColor(0.15, 0.15, 0.15)
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	local textX = x + 2
	local textY = y + 2
	local textHeight = height - 4
	if self.prompt then
		if not enabled then
			DrawString(textX, textY, "LEFT", textHeight, "VAR", self.disableCol..self.prompt)
		else
			DrawString(textX, textY, "LEFT", textHeight, "VAR", self.textCol..self.prompt..":")
		end
		textX = textX + DrawStringWidth(textHeight, "VAR", self.prompt) + textHeight/2
	end
	if not enabled then
		return
	end
	SetViewport(textX, textY, width - 2 - (textX - x), textHeight)
	if not self.hasFocus then
		DrawString(0, 0, "LEFT", textHeight, "VAR", self.inactiveCol..self.buf)
		SetViewport()
		return
	end
	if self.drag then
		local cursorX, cursorY = GetCursorPos()
		self.caret = DrawStringCursorIndex(textHeight, "VAR", self.buf, cursorX - textX, cursorY - textY)
	end
	textX, textY = 0, 0
	if self.sel and self.sel ~= self.caret then
		local left = math.min(self.caret, self.sel)
		local right = math.max(self.caret, self.sel)
		local pre = self.textCol .. self.buf:sub(1, left - 1)
		local sel = self.selCol .. StripEscapes(self.buf:sub(left, right - 1))
		local post = self.textCol .. self.buf:sub(right)
		DrawString(textX, textY, "LEFT", textHeight, "VAR", pre)
		textX = textX + DrawStringWidth(textHeight, "VAR", pre)
		local selWidth = DrawStringWidth(textHeight, "VAR", sel)
		SetDrawColor(self.selBGCol)
		DrawImage(nil, textX, textY, selWidth, textHeight)
		DrawString(textX, textY, "LEFT", textHeight, "VAR", sel)
		DrawString(textX + selWidth, textY, "LEFT", textHeight, "VAR", post)
		if (GetTime() - self.blinkStart) % 1000 < 500 then
			local caretX = (self.caret > self.sel) and textX + selWidth or textX
			SetDrawColor(self.textCol)
			DrawImage(nil, caretX, textY, 1, textHeight)
		end
	else
		local pre = self.textCol .. self.buf:sub(1, self.caret - 1)
		local post = self.buf:sub(self.caret)
		DrawString(textX, textY, "LEFT", textHeight, "VAR", pre)
		textX = textX + DrawStringWidth(textHeight, "VAR", pre)
		DrawString(textX, textY, "LEFT", textHeight, "VAR", post)
		if (GetTime() - self.blinkStart) % 1000 < 500 then
			SetDrawColor(self.textCol)
			DrawImage(nil, textX, textY, 1, textHeight)
		end
	end
	SetViewport()
end

function EditClass:OnFocusGained()
	self.blinkStart = GetTime()
end

function EditClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local shift = IsKeyDown("SHIFT")
	if key == "LEFTBUTTON" then
		if not self:IsMouseOver() then
			return
		end
		if doubleClick then
			self.sel = 1
			self.caret = #self.buf + 1
		else
			self.drag = true
			local x, y = self:GetPos()
			local width, height = self:GetSize()
			local textX = x + 2
			local textY = y + 2
			local textHeight = height - 4
			if self.prompt then
				textX = textX + DrawStringWidth(textHeight, "VAR", self.prompt) + textHeight/2
			end
			local cursorX, cursorY = GetCursorPos()
			self.caret = DrawStringCursorIndex(textHeight, "VAR", self.buf, cursorX - textX, cursorY - textY)
			self.sel = self.caret
			self.blinkStart = GetTime()
		end
	elseif key == "ESCAPE" or key == "RETURN" then
		return
	elseif IsKeyDown("CTRL") then
		if key == "a" then
			self.caret = 1
			self.sel = #self.buf + 1
		elseif key == "c" or key == "x" then
			if self.sel and self.sel ~= self.caret then
				local left = math.min(self.caret, self.sel)
				local right = math.max(self.caret, self.sel)
				Copy(self.buf:sub(left, right - 1))
				if key == "x" then
					self:ReplaceSel("")
				end
			end
		elseif key == "v" then
			local text = Paste()
			if text then
				if self.sel and self.sel ~= self.caret then
					self:ReplaceSel(text)
				else
					self:Insert(text)
				end
			end
		end
	elseif key == "LEFT" then
		self.sel = shift and (self.sel or self.caret) or nil
		if self.caret > 1 then
			self.caret = self.caret - 1
			self.blinkStart = GetTime()
		end
	elseif key == "RIGHT" then
		self.sel = shift and (self.sel or self.caret) or nil
		if self.caret <= #self.buf then
			self.caret = self.caret + 1
			self.blinkStart = GetTime()
		end
	elseif key == "HOME" then
		self.sel = shift and (self.sel or self.caret) or nil
		self.caret = 1
		self.blinkStart = GetTime()
	elseif key == "END" then
		self.sel = shift and (self.sel or self.caret) or nil
		self.caret = #self.buf + 1			
		self.blinkStart = GetTime()
	elseif key == "BACK" then
		if self.sel and self.sel ~= self.caret then
			self:ReplaceSel("")
		elseif self.caret > 1 then
			self.buf = self.buf:sub(1, self.caret - 2) .. self.buf:sub(self.caret)
			self.caret = self.caret - 1
			self.sel = nil
			self.blinkStart = GetTime()
			if self.changeFunc then
				self.changeFunc(self.buf)
			end
		end
	elseif key == "DELETE" then
		if self.sel and self.sel ~= self.caret then
			self:ReplaceSel("")
		elseif self.caret <= #self.buf then
			self.buf = self.buf:sub(1, self.caret - 1) .. self.buf:sub(self.caret + 1)
			self.sel = nil
			self.blinkStart = GetTime()
			if self.changeFunc then
				self.changeFunc(self.buf)
			end
		end
	elseif key == "TAB" then
		return self:TabAdvance(shift and -1 or 1)
	end
	return self
end

function EditClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		if self.drag then
			self.drag = false
		end
	end		
	return self.hasFocus and self
end

function EditClass:OnChar(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key ~= '\b' then
		if self.sel and self.sel ~= self.caret then
			self:ReplaceSel(key)
		else
			self:Insert(key)
		end
	end
	return self
end
