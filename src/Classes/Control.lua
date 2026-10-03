-- Path of Building
--
-- Class: Control
-- UI control base class
--
local t_insert = table.insert
local m_floor = math.floor


---@enum (key) AnchorPoint
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

--[[
local rect = {
	x,
	y,
	width,
	height,
	}
	
	could possibly have
	minWidth,
	minHeight,
	for containers
--]]

---@class Control
---@field enabled        Prop<boolean>
---@field state          boolean?
---@field list           table?
---@field selValue       any
---@field selIndex       integer?
---@field offset         number?
---@field labelWidth     number?
---@field realDraw       fun(self: Control, x: number, y: number, width: number, height: number, viewPort: Viewport)?
---@field IsMouseOver?   fun(self: Control): boolean
---@field lines          table
---@field onClick?      fun(...)
---@field buf           string
---@field dropped       boolean
---@field Click?        fun(self: Control, ...)
---@field IsScrollDownKey? fun(key: string): boolean
---@field IsScrollUpKey? fun(key: string): boolean
---@field SelectIndex?  fun(self: Control, index: integer): boolean?
---@field CanDragToValue? fun(self: Control, index: integer, value: any, source: Control): boolean
---@field SetBreakdownData? fun(self: Control, displayData?: table, pinned?: boolean, forceActor?: Actor)
---@field GetColumnProperty? fun(self: Control, column: table, property: string): any
---@field anchor         AnchorState
---@field rectStart      Rect
---@field hasFocus?      boolean
---@field tabOrder?      Control[]
---@field OnFocusGained? fun()
---@field OnFocusLost?   fun()
---@field OnKeyDown?     fun(...: any): any
---@field shown          Prop<boolean>
---@field x              Prop<number>?
---@field y              Prop<number>?
---@field width          Prop<number>?
---@field height         Prop<number>?
---@field Draw?          fun(self: Control, viewPort: Viewport, noTooltip?: boolean)
---@field OnKeyUp?       fun(self: Control, key: string): Control?
---@field SetText?       fun(self: Control, text: string, notify?: boolean)
---@field SetList?       fun(self: Control, textList: table)
---@field SetSel?        fun(self: Control, newSel: integer, noCallSelFunc?: boolean)
---@field SelByValue?    fun(self: Control, value: any, key?: string): integer?
---@field Scroll?        fun(self: Control, mult: number)
---@field SetContentDimension? fun(self: Control, conDim: number, viewDim: number)
---@field collapseY      number? An additional offset which is applied when this control uses a collapsed anchor.
---@field collapseX      number? An additional offset which is applied when this control uses a collapsed anchor.
local ControlClass = newClass("Control")

---@alias Anchor [AnchorPoint, (Control|ControlHost)?, AnchorPoint, boolean|nil]
---@alias Rect [Prop<number>?, Prop<number>?, Prop<number>?, Prop<number>?]

---@class Viewport A resolved, absolute drawing region, as passed to :Draw() methods (distinct from the positional Rect tuple used for anchoring).
---@field x number
---@field y number
---@field width number
---@field height number

---@class AnchorState
---@field point? AnchorPoint
---@field other? Control|ControlHost
---@field otherPoint? AnchorPoint
---@field collapse? boolean

---@param anchor? Anchor
---@param rect? Rect
---@return Control
function ControlClass:Control(anchor, rect)
	self.rectStart = rect or {0, 0, 0, 0}
	self.x, self.y, self.width, self.height = unpack(self.rectStart)
	---@type (fun(): boolean) | boolean
	self.shown = true
	self.enabled = true
	self.anchor = { }
	if anchor then
		self:SetAnchor(anchor[1], anchor[2], anchor[3], nil, nil, anchor[4])
	end
	return self
end

---@alias Prop<T> (fun(...: any): T) | T

---@param name string
---@return unknown value
function ControlClass:GetProperty(name)
	if type(self[name]) == "function" then
		return self[name](self)
	else
		return self[name]
	end
end

---@param point AnchorPoint
---@param other Control|ControlHost
---@param otherPoint AnchorPoint
---@param x? Prop<number>
---@param y? Prop<number>
---@param collapse? boolean
function ControlClass:SetAnchor(point, other, otherPoint, x, y, collapse)
	self.anchor.point = point
	self.anchor.other = other
	self.anchor.otherPoint = otherPoint
	self.anchor.collapse = collapse
	if x and y then
		self.x = x
		self.y = y
	end
end

---@return number x
---@return number y
function ControlClass:GetPos()
	if self.anchor.collapse and self.anchor.other and not self.anchor.other:GetProperty("shown") then
		local x, y = self.anchor.other:GetPos()
		x = x + (self.collapseX or 0)
		y = y + (self.collapseY or 0)
		return x, y
	end
	local x = self:GetProperty("x")
	local y = self:GetProperty("y")
	if self.anchor.other then
		local otherX, otherY = self.anchor.other:GetPos()
		---@type number, number
		local otherW, otherH = 0, 0
		---@type number, number
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

---@return number width
---@return number height
function ControlClass:GetSize()
	return self:GetProperty("width"), self:GetProperty("height")
end

---@return boolean?
function ControlClass:IsShown()
	return (not self.anchor.other or self.anchor.collapse or self.anchor.other:IsShown()) and self:GetProperty("shown")
end

---@return boolean
function ControlClass:IsEnabled()
	return self:GetProperty("enabled")
end

---@return boolean
function ControlClass:IsMouseInBounds()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

---@param focus boolean
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

---@param master Control
function ControlClass:AddToTabGroup(master)
	if master.tabOrder then
		t_insert(master.tabOrder, self)
	else
		master.tabOrder = { master, self }
	end
	self.tabOrder = master.tabOrder
end

---@param step integer
---@return Control?
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
