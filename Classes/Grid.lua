-- Path of Building
--
-- Class: Grid
-- Display grid for the calculations breakdown view
--
local launch = ...

local pairs = pairs
local m_max = math.max
local m_floor = math.floor
local t_insert = table.insert

local cfg = { }
cfg.gridHeight = 18
cfg.defGridWidth = 50
cfg.defBorderCol = { 0.1, 0.1, 0.1 }
cfg.defCellCol = { 0, 0, 0 }

local function alignCellText(elem)
	if elem.align == "RIGHT" then
		return elem.grid.offX + elem.x + elem.grid[elem.gx].width - 2, "RIGHT_X"
	elseif elem.align == "CENTER" then
		return elem.grid.offX + elem.x + elem.grid[elem.gx].width / 2, "CENTER_X"
	else
		return elem.grid.offX + elem.x + 2, "LEFT"
	end
end

local function formatCellText(fn, val)
	if fn then
		local errMsg, text = PCall(fn, val)
		if errMsg then
			launch:ShowErrMsg("Error formatting cell: %s", errMsg)
			return ""
		else
			return text
		end
	else
		return tostring(val)
	end
end

local elemTypes = {}

elemTypes.input = {}
elemTypes.input.__index = elemTypes.input
elemTypes.input.borderCol = { 0.9, 0.9, 0.9 }
elemTypes.input.cellCol = { 0.1, 0.1, 0.4 }
function elemTypes.input:Init()
	local grid = self.grid
	if self.format == "choice" then
		self.dropDown = common.New("DropDownControl", nil, 0, 0, 0, 0, self.list, function(index, val)
			if type(val) == "table" then
				val = val.val
			end
			if val ~= grid.input[self.name] then
				grid.input[self.name] = val
				grid.changeFlag = true
			end
		end)
		self.dropDown.sel = 1
		if not grid.input[self.name] then
			self.dropDown.selFunc(1, self.list[1])
		end
	end
end
function elemTypes.input:Draw()
	local grid = self.grid
	if self.format == "check" then
		local x, align = alignCellText(self)
		DrawString(x, grid.offY + self.y + 2, align, cfg.gridHeight - 4, "VAR", grid.input[self.name] and "^x33FF33Yes" or "^xFF3333No")
	elseif grid.focus == self then
		if self.edit then
			self.edit:Draw()
		else
			self.dropDown:Draw()
		end
	elseif grid.input[self.name] then
		local x, align = alignCellText(self)
		local val = grid.input[self.name]
		if self.format == "choice" and type(self.dropDown.list[self.dropDown.sel]) == "table" then
			self.dropDown:SelByValue(val)
			val = self.dropDown.list[self.dropDown.sel].label
		end
		DrawString(x, grid.offY + self.y + 2, align, cfg.gridHeight - 4, "VAR", "^7"..formatCellText(self.formatFunc, val))
	end
end
function elemTypes.input:OnKeyDown(key, doubleClick)
	local grid = self.grid
	if grid.focus == self then
		if key == "RETURN" or key == "TAB" then
			if self.edit then
				local newVal = #self.edit.buf and self.edit.buf or nil
				if self.format == "number" then
					newVal = tonumber((newVal:gsub(",",""):gsub("%*","e")))
				end
				if newVal ~= grid.input[self.name] then
					grid.input[self.name] = newVal
					grid.changeFlag = true
				end
			end
			grid:SetFocus()
			grid:MoveSel(key == "TAB" and "RIGHT" or "DOWN", true)
		elseif self.edit then
			self.edit:OnKeyDown(key)
		elseif self.dropDown then
			if not self.dropDown:OnKeyDown(key) then
				grid:SetFocus()
			end
		end
	elseif key == "RIGHTBUTTON" or (key == "LEFTBUTTON" and doubleClick) then
		if self.format == "check" then
			grid.input[self.name] = not grid.input[self.name]
			grid.changeFlag = true
		elseif self.format == "choice" then
			grid:SetFocus(self)
		else
			grid:SetFocus(self)
			self.edit:SetText(grid.input[self.name] or "")
		end
	elseif key == "WHEELUP" then
		if self.format == "number" then
			grid.input[self.name] = (grid.input[self.name] or 0) + 1
			grid.changeFlag = true
		end
	elseif key == "WHEELDOWN" then
		if self.format == "number" then
			grid.input[self.name] = (grid.input[self.name] or 0) - 1
			grid.changeFlag = true
		end
	elseif self.edit then
		if key == "c" and IsKeyDown("CTRL") then
			if grid.input[self.name] then
				Copy(tostring(grid.input[self.name]))
			end
		elseif key == "v" and IsKeyDown("CTRL") then
			local newVal = Paste()
			if newVal then
				if self.format == "number" then
					newVal = tonumber(newVal)
				end
				if newVal ~= grid.input[self.name] then
					grid.input[self.name] = newVal
					grid.changeFlag = true
				end
			end
		end
	end
end
function elemTypes.input:OnKeyUp(key)
	local grid = self.grid
	if grid.focus == self then
		if self.dropDown then
			if not self.dropDown:OnKeyUp(key) then
				grid:SetFocus()
			end
		else
			self.edit:OnKeyUp(key)
		end
	end
end
function elemTypes.input:OnChar(key)
	local grid = self.grid
	if self.format == "check" then
		if key == " " then
			grid.input[self.name] = not grid.input[self.name]
			grid.changeFlag = true
		end
		return
	elseif self.format == "choice" then
		return
	end
	if key == "\r" then
		return
	elseif not grid.focus and key == "\b" then
		grid.input[self.name] = nil
		grid.changeFlag = true
		return
	elseif key:match("%c") then
		return
	end
	if not grid.focus then
		if self.format == "number" and key == "+" then
			grid.input[self.name] = (grid.input[self.name] or 0) + 1
			grid.changeFlag = true
			return
		end
		grid:SetFocus(self)
	end
	self.edit:OnChar(key)
end
function elemTypes.input:OnFocusGained()
	local grid = self.grid
	if self.format == "choice" then
		self.dropDown.x = grid.offX + self.x
		self.dropDown.y = grid.offY + self.y
		self.dropDown.width = grid:GetElemWidth(self)
		self.dropDown.height = cfg.gridHeight
		self.dropDown:SelByValue(grid.input[self.name])
		self.dropDown:OnKeyDown("LEFTBUTTON")
	else
		local fmtFilter = { number = "[-%d%.e,*]", string = "." }
		self.edit = common.newEditField(nil, nil, fmtFilter[self.format])
		self.edit.x = grid.offX + self.x + 2
		self.edit.y = grid.offY + self.y + 2
		self.edit.width = grid:GetElemWidth(self)
		self.edit.height = cfg.gridHeight - 4
	end
end
function elemTypes.input:OnFocusLost()
	self.edit = nil
	if self.dropDown then
		self.dropDown.dropped = false
	end
end

elemTypes.output = {}
elemTypes.output.__index = elemTypes.output
elemTypes.output.borderCol = { 0.7, 0.7, 0.7 }
function elemTypes.output:Draw()
	local grid = self.grid
	if grid.output[self.name] then
		local x, align = alignCellText(self)
		DrawString(x, grid.offY + self.y + 2, align, cfg.gridHeight - 4, self.font or "VAR", "^7"..formatCellText(self.formatFunc, grid.output[self.name]))
	end
end
function elemTypes.output:OnKeyDown(key)
	local grid = self.grid
	if key == "c" and IsKeyDown("CTRL") and grid.output[self.name] then
		Copy(tostring(grid.output[self.name]))
	end
end

elemTypes.label = {}
elemTypes.label.__index = elemTypes.label
function elemTypes.label:Draw()
	local grid = self.grid
	local x, align = alignCellText(self)
	DrawString(x, grid.offY + self.y + 2, align, cfg.gridHeight - 4, "VAR BOLD", "^xD0D5D0"..self.text)
end

local GridClass = common.NewClass("Grid", function(self, input, output)
	self.input = input
	self.output = output
	self:Clear()
end)

function GridClass:Draw()
	local x = self.offX
	local h = cfg.gridHeight
	for gx = 1, self.width do
		local y = self.offY
		local w = self[gx].width
		for gy = 1, self.height do	
			local elem = self[gx][gy]
			if not elem or elem.gx == gx then
				local ew = w
				if elem and elem.width and elem.width > 1 then
					for i = 1, elem.width - 1 do
						ew = ew + self[gx + i].width
					end
				end
				SetDrawColor(unpack(elem and elem.borderCol or cfg.defBorderCol))
				DrawImage(nil, x, y, ew, h)
				SetDrawColor(unpack(elem and elem.cellCol or cfg.defCellCol))
				DrawImage(nil, x + 1, y + 1, ew - 2, h - 2)
			end
			y = y + cfg.gridHeight
		end
		x = x + self[gx].width
	end
	for gx = 1, self.width do 
		for gy = 1, self.height do
			local elem = self[gx][gy]
			if elem and elem.gx == gx and elem.Draw and elem ~= self.focus then
				elem:Draw()
			end
		end
	end
	if self.focus then
		self.focus:Draw()
	end
	if self.sel and self.sel.gx then
		local selX, selY = self.sel.gx, self.sel.gy
		SetDrawColor(1, 1, 1)
		local x, y = self.sel.x + self.offX, self.sel.y + self.offY
		local w, h = self:GetElemWidth(self.sel), cfg.gridHeight
		DrawImage(nil, x - 2, y - 2, w + 4, 4)
		DrawImage(nil, x - 2, y + h - 2, w + 4, 4)
		DrawImage(nil, x - 2, y - 2, 4, h + 4)
		DrawImage(nil, x + w - 2, y - 2, 4, h + 4)
	end
end

function GridClass:ProcessInput(inputEvents, viewPort)
	for id, event in pairs(inputEvents) do
		if event.type == "KeyDown" then
			self:OnKeyDown(event.key, event.doubleClick, viewPort)
		elseif event.type == "KeyUp" then
			self:OnKeyUp(event.key)
		elseif event.type == "Char" then
			self:OnChar(event.key)
		end
	end
end

function GridClass:OnKeyDown(key, doubleClick, viewPort)
	if self.focus then
		if self.focus.OnKeyDown then
			self.focus:OnKeyDown(key, doubleClick)
		end
	elseif key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		self.sel = nil
		local cursorX, cursorY = GetCursorPos()
		local relX = cursorX - self.offX
		local relY = cursorY - self.offY
		if cursorX >= viewPort.x and cursorY >= viewPort.y and cursorX < viewPort.x + viewPort.width and cursorY < viewPort.y + viewPort.height and relX < self.realWidth and relY < self.realHeight then
			local gy = math.floor(relY / cfg.gridHeight) + 1
			local x = 0
			for gx = 1, self.width do
				if relX >= x and relX < x + self[gx].width then
					if self[gx][gy] then
						local elem = self[gx][gy]
						self.sel = elem
						if elem.OnKeyDown then
							elem:OnKeyDown(key, doubleClick)
						end
					end
					return
				end
				x = x + self[gx].width
			end
		end
	elseif key == "LEFT" or key == "RIGHT" or key == "UP" or key == "DOWN" then
		self:MoveSel(key)
	elseif self.sel then
		if self.sel.OnKeyDown then
			self.sel:OnKeyDown(key)
		end
	end
end

function GridClass:OnKeyUp(key)
	if self.focus then
		if key == "ESCAPE" then
			self:SetFocus()
		elseif self.focus.OnKeyUp then
			self.focus:OnKeyUp(key)
		end
	elseif key == "ESCAPE" then
		self.sel = nil
	elseif self.sel then
		if self.sel.OnKeyUp then
			self.sel:OnKeyUp(key)
		end
	end
end

function GridClass:OnChar(key)
	if self.focus then
		if self.focus.OnChar then
			self.focus:OnChar(key)
		end
	elseif self.sel then
		if self.sel.OnChar then
			self.sel:OnChar(key)
		end		
	end
end

function GridClass:Clear()
	for gx in ipairs(self) do
		self[gx] = nil
	end
	self.width = 1
	self.height = 1
	self[1] = { width = cfg.defGridWidth, x = 0 }
	self:CalcCoords()
end

function GridClass:SetSize(w, h)
	if w < self.width then
		for gx = w + 1, self.width do
			self[gx] = nil
		end
	end
	self.width = w
	self.height = h
	for gx = 1, w do	
		self[gx] = self[gx] or { width = cfg.defGridWidth }
	end
	self:CalcCoords()
end

function GridClass:CheckSize()
	local mx, my = 1, 1
	for gx = 1, self.width do
		for gy = 1, self.height do
			if self[gx][gy] then
				mx = math.max(mx, gx + self[gx][gy].width - 1)
				my = math.max(my, gy)
			end
		end
	end
	self:SetSize(mx, my)
end

function GridClass:CalcCoords()
	local x = 0
	for gx = 1, self.width do
		self[gx].x = x
		for gy = 1, self.height do
			if self[gx][gy] and self[gx][gy].gx == gx then
				self[gx][gy].x = x
			end
		end
		x = x + self[gx].width
	end
	self.realWidth = x
	self.realHeight = self.height * cfg.gridHeight
end

function GridClass:SetColWidth(gx, sz)
	if self[gx] then
		self[gx].width = sz
	end
	self:CalcCoords()
end

function GridClass:GetElem(gx, gy)
	return self[gx] and self[gx][gy]
end

function GridClass:SetElem(gx, gy, elem)
	if elem then
		elem.grid = self
		elem.gx = gx
		elem.gy = gy
		elem.width = elem.width or 1
		if gx + elem.width - 1 > self.width then
			self:SetSize(gx + elem.width - 1, self.height)
		end
		if gy > self.height then
			self:SetSize(self.width, gy)
		end
		for i = 1, elem.width do
			self[gx + i - 1][gy] = elem
		end
		elem.x = self[gx].x
		elem.y = (gy - 1) * cfg.gridHeight
		if elemTypes[elem.type] then
			setmetatable(elem, elemTypes[elem.type])
		end
		if elem.Init then
			elem:Init()
		end
	elseif self:GetElem(gx, gy) then
		self[gx][gy] = nil
		self:CheckSize()
	end
end

function GridClass:GetElemWidth(elem)
	local width = 0
	for gx = elem.gx, elem.gx + elem.width - 1 do
		width = width + self[gx].width
	end
	return width
end

function GridClass:SetFocus(elem)
	if self.focus and self.focus.OnFocusLost then
		self.focus:OnFocusLost()
	end
	self.focus = elem
	if self.focus and self.focus.OnFocusGained then
		self.focus:OnFocusGained()
	end
end

function GridClass:MoveSel(dir, force)
	if not self.sel or not self.sel.gx then 
		return
	end
	local selX, selY = self.sel.gx, self.sel.gy
	local s, elem, i
	if dir == "LEFT" or dir == "RIGHT" then
		if dir == "LEFT" then
			s, elem, i = selX - 1, 1, -1
		else
			s, elem, i = selX + 1, self.width, 1
		end
		for gx = s, elem, i do
			if self[gx][selY] then
				self.sel = self[gx][selY]
				return
			end
		end
	else
		if dir == "UP" then
			s, elem, i = selY - 1, 1, -1
		else
			s, elem, i = selY + 1, self.height, 1
		end
		for gy = s, elem, i do
			if self[selX][gy] then
				self.sel = self[selX][gy]
				return
			end
		end
	end
	if force then
		self.sel = nil
	end
end