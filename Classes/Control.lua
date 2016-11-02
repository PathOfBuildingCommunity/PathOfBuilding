-- Path of Building
--
-- Class: Control
-- UI control base class
--

local t_insert = table.insert
local m_floor = math.floor

local anchorPos = {
	    ["TOPLEFT"] = { 0  , 0   },
	        ["TOP"] = { 0.5, 0   },
	   ["TOPRIGHT"] = { 1  , 0   },
	      ["RIGHT"] = { 1  , 0.5 },
	["BOTTOMRIGHT"] = { 1  , 1   },
	     ["BOTTOM"] = { 0.5, 1   },
	 ["BOTTOMLEFT"] = { 0  , 1   },
	       ["LEFT"] = { 0  , 0.5 },
	     ["CENTER"] = { 0.5, 0.5 },
}

local ControlClass = common.NewClass("Control", function(self, anchor, x, y, width, height)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.shown = true
	self.enabled = true
	self.anchor = { }
	if anchor then
		self:SetAnchor(anchor[1], anchor[2], anchor[3])
	end
end)

function ControlClass:GetProperty(name)
	if type(self[name]) == "function" then
		return self[name](self)
	else
		return self[name]
	end
end

function ControlClass:SetAnchor(point, other, otherPoint, x, y)
	self.anchor.point = point
	self.anchor.other = other
	self.anchor.otherPoint = otherPoint
	if x and y then
		self.x = x
		self.y = y
	end
end

function ControlClass:GetPos()
	local x = self:GetProperty("x")
	local y = self:GetProperty("y")
	if self.anchor.other then
		local otherX, otherY = self.anchor.other:GetPos()
		local otherW, otherH = 0, 0
		local width, height = 0, 0
		local otherPos = anchorPos[self.anchor.otherPoint]
		assert(otherPos, "invalid anchor position '"..tostring(self.anchor.otherPoint).."'")
		if self.anchor.otherPoint ~= "TOPLEFT" then
			otherW, otherH = self.anchor.other:GetSize()
		end
		local pos = anchorPos[self.anchor.point]
		assert(pos, "invalid anchor position '"..tostring(self.anchor.point).."'")
		if self.anchor.point ~= "TOPLEFT" then
			width, height = self:GetSize()
		end
		x = m_floor(otherX + otherW * otherPos[1] + x - width * pos[1])
		y = m_floor(otherY + otherH * otherPos[2] + y - height * pos[2])
	end
	return x, y
end

function ControlClass:GetSize()
	return self:GetProperty("width"), self:GetProperty("height")
end

function ControlClass:IsShown()
	return (not self.anchor.other or self.anchor.other:IsShown()) and self:GetProperty("shown")
end

function ControlClass:IsEnabled()
	return self:GetProperty("enabled")
end

function ControlClass:IsMouseInBounds()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function ControlClass:SetFocus(focus)
	if focus ~= self.hasFocus then
		if focus and self.OnFocusGained then
			self:OnFocusGained()
		elseif not focus and self.OnFocusLost then
			self:OnFocusLost()
		end
		self.hasFocus = focus
	end
end

function ControlClass:AddToTabGroup(master)
	if master.tabOrder then
		t_insert(master.tabOrder, self)
	else
		master.tabOrder = { master, self }
	end
	self.tabOrder = master.tabOrder
end

function ControlClass:TabAdvance(step)
	if self.tabOrder then
		local index = isValueInArray(self.tabOrder, self)
		if index then
			while true do
				index = index + step
				if index > #self.tabOrder then
					index = 1
				elseif index < 1 then
					index = #self.tabOrder
				end
				if self.tabOrder[index] == self or (self.tabOrder[index].OnKeyDown and self.tabOrder[index]:IsShown()) then
					return self.tabOrder[index]
				end
			end
		end
	end
	return self
end