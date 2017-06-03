-- Path of Building
--
-- Class: DropDown Control
-- Basic drop down control.
--
local launch, main = ...

local ipairs = ipairs
local m_min = math.min
local m_max = math.max

local DropDownClass = common.NewClass("DropDownControl", "Control", "ControlHost", function(self, anchor, x, y, width, height, list, selFunc, tooltip)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.controls.scrollBar = common.New("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, -1, 0, 18, 0, (height - 4) * 4)
	self.controls.scrollBar.y = function()
		local width, height = self:GetSize()
		return height + 1
	end
	self.controls.scrollBar.height = function()
		return (height - 4) * m_min(#self.list, 30) + 2
	end
	self.controls.scrollBar.shown = function()
		return self.dropped and self.controls.scrollBar.enabled
	end
	self.list = list or { }
	self.selIndex = 1
	self.selFunc = selFunc
	self.tooltip = tooltip
	self.tooltipFunc = function(mode, index, value)
		local tooltip = self:GetProperty("tooltip")
		if tooltip then
			main:AddTooltipLine(14, self.tooltip)
		end
	end
end)

function DropDownClass:SelByValue(value, key)
	for index, listVal in ipairs(self.list) do
		if type(listVal) == "table" then
			if listVal[key] == value then
				self.selIndex = index
				return
			end
		else
			if listVal == val then
				self.selIndex = index
				return
			end
		end
	end
end

function DropDownClass:SetSel(newSel)
	newSel = m_max(1, m_min(#self.list, newSel))
	if newSel ~= self.selIndex then
		self.selIndex = newSel
		if self.selFunc then
			self.selFunc(newSel, self.list[newSel])
		end
	end
end

function DropDownClass:ScrollSelIntoView()
	local width, height = self:GetSize()
	local scrollBar = self.controls.scrollBar
	local dropHeight = (height - 4) * m_min(#self.list, 30)
	scrollBar:SetContentDimension((height - 4) * #self.list, dropHeight)
	scrollBar:ScrollIntoView((self.selIndex - 2) * (height - 4), 3 * (height - 4))
end

function DropDownClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	if self:GetMouseOverControl() then
		return true
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local dropExtra = self.dropped and (height - 4) * m_min(#self.list, 30) + 2 or 0
	local mOver
	if self.dropUp then
		mOver = cursorX >= x and cursorY >= y - dropExtra and cursorX < x + width and cursorY < y + height
	else
		mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height + dropExtra
	end
	local mOverComp
	if mOver then
		if cursorY >= y and cursorY < y + height then
			mOverComp = "BODY"
		else
			mOverComp = "DROP"
		end
	end
	return mOver, mOverComp
end

function DropDownClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver, mOverComp = self:IsMouseOver()
	local dropHeight = (height - 4) * m_min(#self.list, 30)
	local dropExtra = dropHeight + 4
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension((height - 4) * #self.list, dropHeight)
	self.dropUp = y + height + dropExtra > viewPort.height
	local dropY = self.dropUp and y - dropExtra or y + height
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
		DrawImage(nil, x, dropY, width, dropExtra)
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
		DrawImage(nil, x + 1, dropY + 1, width - 2, dropExtra - 2)
		SetDrawLayer(nil, 0)
	end
	if enabled then
		if (mOver or self.dropped) and mOverComp ~= "DROP" then
			local col, center = self.tooltipFunc(mOver and "BODY" or "OUT", self.selIndex, self.list[self.selIndex])
			SetDrawLayer(nil, 10)
			main:DrawTooltip(x, y - (self.dropped and self.dropUp and dropExtra or 0), width, height + (self.dropped and dropExtra or 0), viewPort, col, center)
			SetDrawLayer(nil, 0)
		end
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.66, 0.66, 0.66)
	end
	local selLabel = self.list[self.selIndex]
	if type(selLabel) == "table" then
		selLabel = selLabel.label
	end
	SetViewport(x + 2, y + 2, width - height, height - 4)
	DrawString(0, 0, "LEFT", height - 4, "VAR", selLabel or "")
	SetViewport()
	if self.dropped then
		SetDrawLayer(nil, 5)
		self:DrawControls(viewPort)
		local cursorX, cursorY = GetCursorPos()
		self.hoverSel = mOver and not scrollBar:IsMouseOver() and math.floor((cursorY - dropY + scrollBar.offset) / (height - 4)) + 1
		if self.hoverSel and not self.list[self.hoverSel] then
			self.hoverSel = nil
		end
		if self.hoverSel then
			local col, center = self.tooltipFunc("HOVER", self.hoverSel, self.list[self.hoverSel])
			main:DrawTooltip(x, dropY + 2 + (self.hoverSel - 1) * (height - 4) - scrollBar.offset, width, height - 4, viewPort, col, center)
		end
		SetViewport(x + 2, dropY + 2, scrollBar.enabled and width - 22 or width - 4, dropHeight)
		for index, listVal in ipairs(self.list) do
			local y = (index - 1) * (height - 4) - scrollBar.offset
			if index == self.hoverSel then
				SetDrawColor(0.5, 0.4, 0.3)
				DrawImage(nil, 0, y, width - 4, height - 4)
			end
			if index == self.hoverSel or index == self.selIndex then
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
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		self.selControl = mOverControl
		return mOverControl:OnKeyDown(key) and self
	else
		self.selControl = nil
	end
	if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver or (self.dropped and mOverComp == "BODY") then
			self.dropped = false
			return self
		end
		if not self.dropped then
			self.dropped = true
			self:ScrollSelIntoView()
		end
	elseif key == "ESCAPE" then
		self.dropped = false
	end
	return self.dropped and self
end

function DropDownClass:OnKeyUp(key)
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
		return self
	end
	if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver then
			self.dropped = false
		elseif mOverComp == "DROP" then
			local x, y = self:GetPos()
			local width, height = self:GetSize()
			local cursorX, cursorY = GetCursorPos()
			local dropExtra = (height - 4) * m_min(#self.list, 30) + 4
			local dropY = self.dropUp and y - dropExtra or y + height
			self:SetSel(math.floor((cursorY - dropY + self.controls.scrollBar.offset) / (height - 4)) + 1)
			self.dropped = false
		end
	elseif key == "WHEELDOWN" then
		if self.dropped and self.controls.scrollBar.enabled then
			self.controls.scrollBar:Scroll(1)
		else
			self:SetSel(self.selIndex + 1)
		end
		return self
	elseif key == "DOWN" then
		self:SetSel(self.selIndex + 1)
		self:ScrollSelIntoView()
		return self
	elseif key == "WHEELUP" then
		if self.dropped and self.controls.scrollBar.enabled then
			self.controls.scrollBar:Scroll(-1)
		else
			self:SetSel(self.selIndex - 1)
		end
		return self
	elseif key == "UP" then
		self:SetSel(self.selIndex - 1)
		self:ScrollSelIntoView()
		return self
	end
	return self.dropped and self
end
