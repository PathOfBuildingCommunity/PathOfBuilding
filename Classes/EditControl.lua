-- Path of Building
--
-- Class: Edit Control
-- Basic edit control.
--
local launch, main = ...

local m_max = math.max
local m_min = math.min
local m_floor = math.floor

local function lastLine(str)
	local lastLineIndex = 1
	while true do
		local nextLine = str:find("\n", lastLineIndex, true)
		if nextLine then
			lastLineIndex = nextLine + 1
		else
			break
		end
	end
	return str:sub(lastLineIndex, -1)
end

local function newlineCount(str)
	local count = 0
	local lastLineIndex = 1
	while true do
		local nextLine = str:find("\n", lastLineIndex, true)
		if nextLine then
			count = count + 1
			lastLineIndex = nextLine + 1
		else
			return count
		end
	end
end

local EditClass = common.NewClass("EditControl", "ControlHost", "Control", "UndoHandler", function(self, anchor, x, y, width, height, init, prompt, filter, limit, changeFunc, lineHeight)
	self.ControlHost()
	self.Control(anchor, x, y, width, height)
	self.UndoHandler()
	self:SetText(init or "")
	self.prompt = prompt
	self.filter = filter or "^%w%p "
	self.filterPattern = "["..self.filter.."]"
	self.limit = limit
	self.changeFunc = changeFunc
	self.lineHeight = lineHeight
	self.font = "VAR"
	self.textCol = "^7"
	self.inactiveCol = "^8"
	self.disableCol = "^9"
	self.selCol = "^0"
	self.selBGCol = "^xBBBBBB"
	self.blinkStart = GetTime()
	if self.filter == "%D" or self.filter == "^%-%d" then
		-- Add +/- buttons for integer number edits
		self.isNumeric = true
		local function buttonSize()
			local width, height = self:GetSize()
			return height - 4
		end
		self.controls.buttonDown = common.New("ButtonControl", {"RIGHT",self,"RIGHT"}, -2, 0, buttonSize, buttonSize, "-", function()
			self:OnKeyUp("DOWN")
		end)
		self.controls.buttonUp = common.New("ButtonControl", {"RIGHT",self.controls.buttonDown,"LEFT"}, -1, 0, buttonSize, buttonSize, "+", function()
			self:OnKeyUp("UP")
		end)
	end
	self.controls.scrollBarH = common.New("ScrollBarControl", {"BOTTOMLEFT",self,"BOTTOMLEFT"}, 1, -1, 0, 14, 60, "HORIZONTAL", true)
	self.controls.scrollBarH.width = function()
		local width, height = self:GetSize()
		return width - (self.controls.scrollBarV.enabled and 16 or 2)
	end
	self.controls.scrollBarV = common.New("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, -1, 1, 14, 0, (lineHeight or 0) * 3, "VERTICAL", true)
	self.controls.scrollBarV.height = function()
		local width, height = self:GetSize()
		return height - (self.controls.scrollBarH.enabled and 16 or 2)
	end
	if not lineHeight then
		self.controls.scrollBarH.shown = false
		self.controls.scrollBarV.shown = false
	end
	self.tooltipFunc = function()
		local tooltip = self:GetProperty("tooltip")
		if tooltip then
			main:AddTooltipLine(14, tooltip)
		end
	end
end)

function EditClass:SetText(text, notify)
	self.buf = tostring(text)
	self.caret = #self.buf + 1
	self.sel = nil
	if notify and self.changeFunc then
		self.changeFunc(self.buf)
	end
	self:ResetUndo()
end

function EditClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function EditClass:SelectAll()
	self.caret = #self.buf + 1
	self.sel = 1
	self:ScrollCaretIntoView()
end

function EditClass:ReplaceSel(text)
	text = text:gsub("\r","")
	if text:match(self.filterPattern) then
		return
	end
	local left = m_min(self.caret, self.sel)
	local right = m_max(self.caret, self.sel)
	local newBuf = self.buf:sub(1, left - 1) .. text .. self.buf:sub(right)
	if self.limit and #newBuf > self.limit then
		return
	end
	self.buf = newBuf
	self.caret = left + #text
	self.sel = nil
	self:ScrollCaretIntoView()
	self.blinkStart = GetTime()
	if self.changeFunc then
		self.changeFunc(self.buf)
	end
	self:AddUndoState()
end

function EditClass:Insert(text)
	text = text:gsub("\r","")
	if text:match(self.filterPattern) then
		return
	end
	local newBuf = self.buf:sub(1, self.caret - 1) .. text .. self.buf:sub(self.caret)
	if self.limit and #newBuf > self.limit then
		return
	end
	self.buf = newBuf
	self.caret = self.caret + #text
	self.sel = nil
	self:ScrollCaretIntoView()
	self.blinkStart = GetTime()
	if self.changeFunc then
		self.changeFunc(self.buf)
	end
	self:AddUndoState()
end

function EditClass:UpdateScrollBars()
	local width, height = self:GetSize()
	local textHeight = self.lineHeight or (height - 4)
	if self.lineHeight then
		self.controls.scrollBarH:SetContentDimension(DrawStringWidth(textHeight, self.font, self.buf) + 2, width - 18)
		self.controls.scrollBarV:SetContentDimension(newlineCount(self.buf.."\n") * textHeight, height - (self.controls.scrollBarH.enabled and 18 or 4))
	else
		self.controls.scrollBarH:SetContentDimension(DrawStringWidth(textHeight, self.font, self.buf) + 2, width - 4 - (self.prompt and DrawStringWidth(textHeight, self.font, self.prompt) + textHeight/2 or 0))
	end
end

function EditClass:ScrollCaretIntoView()
	local width, height = self:GetSize()
	local textHeight = self.lineHeight or (height - 4)
	local pre = self.buf:sub(1, self.caret - 1)
	local caretX = DrawStringWidth(textHeight, self.font, lastLine(pre))
	self:UpdateScrollBars()
	self.controls.scrollBarH:ScrollIntoView(caretX - textHeight, textHeight * 2)
	if self.lineHeight then
		local caretY = newlineCount(pre) * textHeight
		self.controls.scrollBarV:ScrollIntoView(caretY, textHeight)
	end
end

function EditClass:MoveCaretVertically(offset)
	local pre = self.buf:sub(1, self.caret - 1)
	local caretX = DrawStringWidth(self.lineHeight, self.font, lastLine(pre))
	local caretY = newlineCount(pre) * self.lineHeight
	self.caret = DrawStringCursorIndex(self.lineHeight, self.font, self.buf, caretX + 1, caretY + self.lineHeight/2 + offset)
	self.lastUndoState.caret = self.caret
	self:ScrollCaretIntoView()
	self.blinkStart = GetTime()
end

function EditClass:Draw(viewPort)
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
		if self.lineHeight then
			SetDrawColor(0.1, 0.1, 0.1)
		else
			SetDrawColor(0.15, 0.15, 0.15)
		end
	else
		SetDrawColor(0, 0, 0)
	end
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	local textX = x + 2
	local textY = y + 2
	local textHeight = self.lineHeight or (height - 4)
	if self.prompt then
		if not enabled then
			DrawString(textX, textY, "LEFT", textHeight, self.font, self.disableCol..self.prompt)
		else
			DrawString(textX, textY, "LEFT", textHeight, self.font, self.textCol..self.prompt..":")
		end
		textX = textX + DrawStringWidth(textHeight, self.font, self.prompt) + textHeight/2
	end
	if not enabled then
		return
	end
	if mOver then
		SetDrawLayer(nil, 100)
		local col, center = self.tooltipFunc()
		main:DrawTooltip(x, y, width, height, viewPort, col, center)
		SetDrawLayer(nil, 0)
	end
	self:UpdateScrollBars()
	local marginL = textX - x - 2
	local marginR = self.controls.scrollBarV:IsShown() and 14 or 0
	local marginB = self.controls.scrollBarH:IsShown() and 14 or 0
	SetViewport(textX, textY, width - 4 - marginL - marginR, height - 4 - marginB)
	if not self.hasFocus then
		SetDrawColor(self.inactiveCol)
		DrawString(-self.controls.scrollBarH.offset, -self.controls.scrollBarV.offset, "LEFT", textHeight, self.font, self.buf)
		SetViewport()
		self:DrawControls(viewPort)
		return
	end
	if not IsKeyDown("LEFTBUTTON") then
		self.drag = false
	end
	if self.drag then
		local cursorX, cursorY = GetCursorPos()
		self.caret = DrawStringCursorIndex(textHeight, self.font, self.buf, cursorX - textX + self.controls.scrollBarH.offset, cursorY - textY + self.controls.scrollBarV.offset)
		self.lastUndoState.caret = self.caret
		self:ScrollCaretIntoView()
	end
	textX = -self.controls.scrollBarH.offset
	textY = -self.controls.scrollBarV.offset
	if self.lineHeight then
		local left = m_min(self.caret, self.sel or self.caret)
		local right = m_max(self.caret, self.sel or self.caret)
		local caretX
		SetDrawColor(self.textCol)
		for s, line, e in (self.buf.."\n"):gmatch("()([^\n]*)\n()") do
			textX = -self.controls.scrollBarH.offset
			if left >= e or right <= s then
				DrawString(textX, textY, "LEFT", textHeight, self.font, line)
			end
			if left < e then
				if left > s then
					local pre = line:sub(1, left - s)
					DrawString(textX, textY, "LEFT", textHeight, self.font, pre)
					textX = textX + DrawStringWidth(textHeight, self.font, pre)
				end
				if left >= s and left == self.caret then
					caretX, caretY = textX, textY
				end
			end
			if left ~= right and left < e and right > s then
				local sel = self.selCol .. StripEscapes(line:sub(m_max(1, left - s + 1), m_min(#line, right - s)))
				if right >= e then
					sel = sel .. "  "
				end
				local selWidth = DrawStringWidth(textHeight, self.font, sel)
				SetDrawColor(self.selBGCol)
				DrawImage(nil, textX, textY, selWidth, textHeight)
				DrawString(textX, textY, "LEFT", textHeight, self.font, sel)
				SetDrawColor(self.textCol)
				textX = textX + selWidth
			end
			if right >= s and right < e and right == self.caret then
				caretX, caretY = textX, textY
			end
			if right > s then
				if right < e then
					local post = line:sub(right - s + 1)
					DrawString(textX, textY, "LEFT", textHeight, self.font, post)
					textX = textX + DrawStringWidth(textHeight, self.font, post)
				end
			end
			textY = textY + textHeight
		end
		if caretX then
			if (GetTime() - self.blinkStart) % 1000 < 500 then
				SetDrawColor(self.textCol)
				DrawImage(nil, caretX, caretY, 1, textHeight)
			end
		end
	elseif self.sel and self.sel ~= self.caret then
		local left = m_min(self.caret, self.sel)
		local right = m_max(self.caret, self.sel)
		local pre = self.textCol .. self.buf:sub(1, left - 1)
		local sel = self.selCol .. StripEscapes(self.buf:sub(left, right - 1))
		local post = self.textCol .. self.buf:sub(right)
		DrawString(textX, textY, "LEFT", textHeight, self.font, pre)
		textX = textX + DrawStringWidth(textHeight, self.font, pre)
		local selWidth = DrawStringWidth(textHeight, self.font, sel)
		SetDrawColor(self.selBGCol)
		DrawImage(nil, textX, textY, selWidth, textHeight)
		DrawString(textX, textY, "LEFT", textHeight, self.font, sel)
		DrawString(textX + selWidth, textY, "LEFT", textHeight, self.font, post)
		if (GetTime() - self.blinkStart) % 1000 < 500 then
			local caretX = (self.caret > self.sel) and textX + selWidth or textX
			SetDrawColor(self.textCol)
			DrawImage(nil, caretX, textY, 1, textHeight)
		end
	else
		local pre = self.textCol .. self.buf:sub(1, self.caret - 1)
		local post = self.buf:sub(self.caret)
		DrawString(textX, textY, "LEFT", textHeight, self.font, pre)
		textX = textX + DrawStringWidth(textHeight, self.font, pre)
		DrawString(textX, textY, "LEFT", textHeight, self.font, post)
		if (GetTime() - self.blinkStart) % 1000 < 500 then
			SetDrawColor(self.textCol)
			DrawImage(nil, textX, textY, 1, textHeight)
		end
	end
	SetViewport()
	self:DrawControls(viewPort)
end

function EditClass:OnFocusGained()
	self.blinkStart = GetTime()
	if not self.drag and not self.selControl and not self.lineHeight then
		self:SelectAll()
	end
end

function EditClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		self.selControl = mOverControl
		return mOverControl:OnKeyDown(key) and self
	else
		self.selControl = nil
	end
	local shift = IsKeyDown("SHIFT")
	local ctrl =  IsKeyDown("CTRL")
	if key == "LEFTBUTTON" then
		if not self.Object:IsMouseOver() then
			return
		end
		if doubleClick then
			if self.lineHeight then
				if self.buf:sub(self.caret - 1, self.caret):match("^%C\n$") then
					self.caret = self.caret - 1
				end
				while self.buf:sub(self.caret - 1, self.caret):match("[^\n][ \t]") do
					self.caret = self.caret - 1
				end
				local caretChar = self.buf:sub(self.caret, self.caret)
				if caretChar:match("%w") then
					self.sel = self.caret
					while self.buf:sub(self.sel - 1, self.sel - 1):match("%w") do
						self.sel = self.sel - 1
					end
					while self.buf:sub(self.caret, self.caret):match("%w") do
						self.caret = self.caret + 1
					end
				elseif caretChar:match("%S") then
					self.sel = self.caret
					while self.buf:sub(self.sel - 1, self.sel - 1) == caretChar do
						self.sel = self.sel - 1
					end
					while self.buf:sub(self.caret, self.caret) == caretChar do
						self.caret = self.caret + 1
					end
				end
			else
				self.sel = 1
				self.caret = #self.buf + 1
			end
			self.lastUndoState.caret = self.caret
			self:ScrollCaretIntoView()
		else
			self.drag = true
			local x, y = self:GetPos()
			local width, height = self:GetSize()
			local textX = x + 2
			local textY = y + 2
			local textHeight = self.lineHeight or (height - 4)
			if self.prompt then
				textX = textX + DrawStringWidth(textHeight, self.font, self.prompt) + textHeight/2
			end
			local cursorX, cursorY = GetCursorPos()
			self.caret = DrawStringCursorIndex(textHeight, self.font, self.buf, cursorX - textX + self.controls.scrollBarH.offset, cursorY - textY + self.controls.scrollBarV.offset)
			self.sel = self.caret
			self.lastUndoState.caret = self.caret
			self:ScrollCaretIntoView()
			self.blinkStart = GetTime()
		end
	elseif key == "ESCAPE" then
		return
	elseif key == "RETURN" then
		if self.lineHeight then
			self:Insert("\n")
		else
			return
		end
	elseif key == "a" and ctrl then
		self:SelectAll()
	elseif (key == "c" or key == "x") and ctrl then
		if self.sel and self.sel ~= self.caret then
			local left = m_min(self.caret, self.sel)
			local right = m_max(self.caret, self.sel)
			Copy(self.buf:sub(left, right - 1))
			if key == "x" then
				self:ReplaceSel("")
			end
		end
	elseif key == "v" and ctrl then
		local text = Paste()
		if text then
			if self.sel and self.sel ~= self.caret then
				self:ReplaceSel(text)
			else
				self:Insert(text)
			end
		end
	elseif key == "z" and ctrl then
		self:Undo()
	elseif key == "y" and ctrl then
		self:Redo()
	elseif key == "LEFT" then
		self.sel = shift and (self.sel or self.caret) or nil
		if self.caret > 1 then
			self.caret = self.caret - 1
			self.lastUndoState.caret = self.caret
			self:ScrollCaretIntoView()
			self.blinkStart = GetTime()
		end
	elseif key == "RIGHT" then
		self.sel = shift and (self.sel or self.caret) or nil
		if self.caret <= #self.buf then
			self.caret = self.caret + 1
			self.lastUndoState.caret = self.caret
			self:ScrollCaretIntoView()
			self.blinkStart = GetTime()
		end
	elseif key == "UP" and self.lineHeight then
		self.sel = shift and (self.sel or self.caret) or nil
		self:MoveCaretVertically(-self.lineHeight)
	elseif key == "DOWN" and self.lineHeight then
		self.sel = shift and (self.sel or self.caret) or nil
		self:MoveCaretVertically(self.lineHeight)
	elseif key == "HOME" then
		self.sel = shift and (self.sel or self.caret) or nil
		if self.lineHeight and not ctrl then
			self.caret = self.caret - #lastLine(self.buf:sub(1, self.caret - 1))
		else
			self.caret = 1
		end
		self.lastUndoState.caret = self.caret
		self:ScrollCaretIntoView()
		self.blinkStart = GetTime()
	elseif key == "END" then
		self.sel = shift and (self.sel or self.caret) or nil
		if self.lineHeight and not ctrl then
			self.caret = self.caret + #self.buf:sub(self.caret, -1):match("[^\n]*")
		else
			self.caret = #self.buf + 1			
		end
		self.lastUndoState.caret = self.caret
		self:ScrollCaretIntoView()
		self.blinkStart = GetTime()
	elseif key == "PAGEUP" and self.lineHeight then
		self.sel = shift and (self.sel or self.caret) or nil
		local width, height = self:GetSize()
		self:MoveCaretVertically(-height + 18)
	elseif key == "PAGEDOWN" and self.lineHeight then
		self.sel = shift and (self.sel or self.caret) or nil
		local width, height = self:GetSize()
		self:MoveCaretVertically(height - 18)
	elseif key == "BACK" then
		if self.sel and self.sel ~= self.caret then
			self:ReplaceSel("")
		elseif self.caret > 1 then
			local len = 1
			if IsKeyDown("CTRL") then
				while self.caret - len > 1 and self.buf:sub(self.caret - len, self.caret - len):match("%s") and not self.buf:sub(self.caret - len - 1, self.caret - len - 1):match("\n") do
					len = len + 1
				end
				if self.buf:sub(self.caret - len, self.caret - len):match("%w") then
					while self.caret - len > 1 and self.buf:sub(self.caret - len - 1, self.caret - len - 1):match("%w") do
						len = len + 1
					end
				end
			end
			self.buf = self.buf:sub(1, self.caret - 1 - len) .. self.buf:sub(self.caret)
			self.caret = self.caret - len
			self.sel = nil
			self:ScrollCaretIntoView()
			self.blinkStart = GetTime()
			if self.changeFunc then
				self.changeFunc(self.buf)
			end
			self:AddUndoState()
		end
	elseif key == "DELETE" then
		if self.sel and self.sel ~= self.caret then
			self:ReplaceSel("")
		elseif self.caret <= #self.buf then
			local len = 1
			if IsKeyDown("CTRL") then
				while self.caret + len <= #self.buf and self.buf:sub(self.caret + len - 1, self.caret + len - 1):match("%s") and not self.buf:sub(self.caret + len, self.caret + len):match("\n") do
					len = len + 1
				end
				if self.buf:sub(self.caret + len - 1, self.caret + len - 1):match("%w") then
					while self.caret + len <= #self.buf and self.buf:sub(self.caret + len, self.caret + len):match("%w") do
						len = len + 1
					end
				end
			end
			self.buf = self.buf:sub(1, self.caret - 1) .. self.buf:sub(self.caret + len)
			self.sel = nil
			self.blinkStart = GetTime()
			if self.changeFunc then
				self.changeFunc(self.buf)
			end
			self:AddUndoState()
		end
	elseif key == "TAB" then
		return self.Object:TabAdvance(shift and -1 or 1)
	end
	return self
end

function EditClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if self.selControl then
		local newSel = self.selControl:OnKeyUp(key)
		if newSel then
			return self
		else
			self.selControl = nil
		end
	end
	if key == "LEFTBUTTON" then
		if self.drag then
			self.drag = false
		end
	elseif self.isNumeric then
		local cur = tonumber(self.buf)
		if key == "WHEELUP" or key == "UP" then
			if cur then
				self:SetText(tostring(cur + 1), true)
			else
				self:SetText("1", true)
			end
		elseif key == "WHEELDOWN" or key == "DOWN" then
			if cur and (self.filter ~= "%D" or cur > 0 )then
				self:SetText(tostring(cur - 1), true)
			else
				self:SetText("0", true)
			end
		end
	elseif key == "WHEELUP" then
		if self.controls.scrollBarV.enabled then
			self.controls.scrollBarV:Scroll(-1)
		else
			self.controls.scrollBarH:Scroll(-1)
		end
	elseif key == "WHEELDOWN" then
		if self.controls.scrollBarV.enabled then
			self.controls.scrollBarV:Scroll(1)
		else
			self.controls.scrollBarH:Scroll(1)
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

function EditClass:CreateUndoState()
	local state = {
		buf = self.buf,
		caret = self.caret,
	}
	self.lastUndoState = state
	return state
end

function EditClass:RestoreUndoState(state)
	self.buf = state.buf
	self.caret = state.caret
	self.sel = nil
	self:ScrollCaretIntoView()
	if self.changeFunc then
		self.changeFunc(self.buf)
	end
	self.lastUndoState = state
end
