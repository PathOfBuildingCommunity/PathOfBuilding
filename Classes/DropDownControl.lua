-- Path of Building
--
-- Class: DropDown Control
-- Basic drop down control.
--
local launch, main = ...

local ipairs = ipairs
local m_min = math.min
local m_max = math.max

local DropDownClass = common.NewClass("DropDownControl", "Control", function(self, anchor, x, y, width, height, list, selFunc)
	self.Control(anchor, x, y, width, height)
	self.list = list or { }
	self.sel = 1
	self.selFunc = selFunc
end)

function DropDownClass:SelByValue(val)
	for index, listVal in ipairs(self.list) do
		if type(listVal) == "table" then
			if listVal.val == val then
				self.sel = index
				return
			end
		else
			if listVal == val then
				self.sel = index
				return
			end
		end
	end
end

function DropDownClass:SetSel(newSel)
	newSel = m_max(1, m_min(#self.list, newSel))
	if newSel ~= self.sel then
		self.sel = newSel
		if self.selFunc then
			self.selFunc(newSel, self.list[newSel])
		end
	end
end

function DropDownClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local dropExtra = self.dropped and (height - 4) * #self.list + 2 or 0
	local mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height + dropExtra
	local mOverComp
	if mOver then
		if cursorY < y + height then
			mOverComp = "BODY"
		else
			mOverComp = "DROP"
		end
	end
	return mOver, mOverComp
end

function DropDownClass:Draw()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver, mOverComp = self:IsMouseOver()
	local dropExtra = (height - 4) * #self.list + 4
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or self.dropped then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	if self.dropped then
		SetDrawLayer(nil, 5)
		DrawImage(nil, x, y + height, width, dropExtra)
		SetDrawLayer(nil, 0)
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
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	if not enabled then
		SetDrawColor(0.33, 0.33, 0.33)
	elseif mOver or self.dropped then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	main:DrawArrow(x + width - height/2, y + height/2, height/2, "DOWN")
	if self.dropped then
		SetDrawLayer(nil, 5)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, y + height + 1, width - 2, dropExtra - 2)
		SetDrawLayer(nil, 0)
	end
	if enabled then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.66, 0.66, 0.66)
	end
	local selLabel = self.list[self.sel]
	if type(selLabel) == "table" then
		selLabel = selLabel.label
	end
	SetViewport(x + 2, y + 2, width - 16, height - 4)
	DrawString(0, 0, "LEFT", height - 4, "VAR", selLabel or "")
	SetViewport()
	if self.dropped then
		SetDrawLayer(nil, 5)
		local cursorX, cursorY = GetCursorPos()
		self.hoverSel = mOver and math.floor((cursorY - y - height) / (height - 4)) + 1
		if self.hoverSel and self.hoverSel < 1 then
			self.hoverSel = nil
		end
		SetViewport(x + 2, y + height + 2, width - 4, #self.list * (height - 4))
		for index, listVal in ipairs(self.list) do
			local y = (index - 1) * (height - 4)
			if index == self.hoverSel then
				SetDrawColor(0.5, 0.4, 0.3)
				DrawImage(nil, 0, y, width - 4, height - 4)
			end
			if index == self.hoverSel or index == self.sel then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.66, 0.66, 0.66)
			end
			local label = type(listVal) == "table" and listVal.label or listVal
			DrawString(0, y, "LEFT", height - 4, "VAR", StripEscapes(label))
		end
		SetViewport()
		SetDrawLayer(nil, 0)
	end
end

function DropDownClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver or (self.dropped and mOverComp == "BODY") then
			self.dropped = false
			return self
		end
		self.dropped = true
	elseif key == "ESCAPE" then
		self.dropped = false
	end
	return self.dropped and self
end

function DropDownClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver then
			self.dropped = false
		elseif mOverComp == "DROP" then
			local x, y = self:GetPos()
			local width, height = self:GetSize()
			local cursorX, cursorY = GetCursorPos()
			self:SetSel(math.floor((cursorY - y - height) / (height - 4)) + 1)
			self.dropped = false
		end
	elseif key == "WHEELDOWN" then
		self:SetSel(self.sel + 1)
	elseif key == "WHEELUP" then
		self:SetSel(self.sel - 1)
	end
	return self.dropped and self
end
