local launch, cfg, main = ...

cfg.gridHeight = 18
cfg.defGridWidth = 50
cfg.defBorderCol = { 0.1, 0.1, 0.1 }
cfg.defCellCol = { 0, 0, 0 }

local pairs = pairs
local t_insert = table.insert
local m_max = math.max
local m_floor = math.floor

local function alignCellText(e)
	if e.align == "RIGHT" then
		return cfg.screenW - (e.grid.offX + e.x + e.grid[e.gx].width - 2)
	elseif e.align == "CENTER" then
		return - cfg.screenW / 2 + e.grid.offX + e.x + e.grid[e.gx].width / 2
	else
		return e.grid.offX + e.x + 2
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

local elem = {}

elem.input = {}
elem.input.__index = elem.input
elem.input.borderCol = { 0.9, 0.9, 0.9 }
elem.input.cellCol = { 0.1, 0.1, 0.4 }
function elem.input:Init()
	local grid = self.grid
	if self.format == "choice" then
		self.dropDown = common.newDropDown(0, 0, 0, 0, self.list, function(index, val)
			if val ~= grid.input[self.name] then
				grid.input[self.name] = val
				grid.changeFlag = true
			end
		end)
		self.dropDown.sel = 1
	end
end
function elem.input:Draw()
	local grid = self.grid
	if self.format == "check" then
		DrawString(alignCellText(self), grid.offY + self.y + 2, self.align, cfg.gridHeight - 4, "FIXED", grid.input[self.name] and "^x33FF33Yes" or "^xFF3333No")
	elseif grid.focus == self then
		if self.edit then
			self.edit:Draw()
		else
			self.dropDown:Draw()
		end
	elseif grid.input[self.name] then
		DrawString(alignCellText(self), grid.offY + self.y + 2, self.align, cfg.gridHeight - 4, "VAR", "^7"..formatCellText(self.formatFunc, grid.input[self.name]))
	end
end
function elem.input:OnKeyDown(key, doubleClick)
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
			if self.dropDown:OnKeyDown(key) then
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
function elem.input:OnKeyUp(key)
	local grid = self.grid
	if grid.focus == self then
		if self.dropDown then
			if self.dropDown:OnKeyUp(key) then
				grid:SetFocus()
			end
		else
			self.edit:OnKeyUp(key)
		end
	end
end
function elem.input:OnChar(key)
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
function elem.input:OnFocusGained()
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
function elem.input:OnFocusLost()
	self.edit = nil
	if self.dropDown then
		self.dropDown.dropped = false
	end
end

elem.output = {}
elem.output.__index = elem.output
elem.output.borderCol = { 0.7, 0.7, 0.7 }
function elem.output:Draw()
	local grid = self.grid
	if grid.output[self.name] then
		DrawString(alignCellText(self), grid.offY + self.y + 2, self.align, cfg.gridHeight - 4, self.font or "VAR", "^7"..formatCellText(self.formatFunc, grid.output[self.name]))
	end
end
function elem.output:OnKeyDown(key)
	local grid = self.grid
	if key == "c" and IsKeyDown("CTRL") and grid.output[self.name] then
		Copy(tostring(grid.output[self.name]))
	end
end

elem.label = {}
elem.label.__index = elem.label
function elem.label:Draw()
	local grid = self.grid
	DrawString(alignCellText(self), grid.offY + self.y + 2, self.align, cfg.gridHeight - 4, "VAR BOLD", "^xD0D5D0"..self.text)
end

local grid = { }
function grid:Clear()
	for gx in ipairs(self) do
		self[gx] = nil
	end
	self.width = 1
	self.height = 1
	self[1] = { width = cfg.defGridWidth, x = 0 }
	self:CalcCoords()
end
function grid:SetSize(w, h)
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
function grid:CalcCoords()
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
function grid:CheckSize()
	local mx, my = 1, 1
	for gx = 1, self.width do
		for gy = 1, self.height do
			if self[gx][gy] then
				mx = math.max(mx, gx + self[gx][gy].width - 1)
				my = math.max(my, gy)
			end
		end
	end
	grid:SetSize(mx, my)
end
function grid:SetColWidth(gx, sz)
	if self[gx] then
		self[gx].width = sz
	end
	self:CalcCoords()
end
function grid:GetElem(gx, gy)
	return self[gx] and self[gx][gy]
end
function grid:SetElem(gx, gy, e)
	if e then
		e.grid = self
		e.gx = gx
		e.gy = gy
		e.width = e.width or 1
		if gx + e.width - 1 > self.width then
			grid:SetSize(gx + e.width - 1, self.height)
		end
		if gy > self.height then
			grid:SetSize(self.width, gy)
		end
		for i = 1, e.width do
			grid[gx + i - 1][gy] = e
		end
		e.x = grid[gx].x
		e.y = (gy - 1) * cfg.gridHeight
		if elem[e.type] then
			setmetatable(e, elem[e.type])
		end
		if e.Init then
			e:Init()
		end
	elseif self:GetElem(gx, gy) then
		self[gx][gy] = nil
		self:CheckSize()
	end
end
function grid:GetElemWidth(e)
	local width = 0
	for gx = e.gx, e.gx + e.width - 1 do
		width = width + self[gx].width
	end
	return width
end
function grid:SetFocus(e)
	if self.focus and self.focus.OnFocusLost then
		self.focus:OnFocusLost()
	end
	self.focus = e
	if self.focus and self.focus.OnFocusGained then
		self.focus:OnFocusGained()
	end
end
function grid:MoveSel(dir, force)
	if not self.sel or not self.sel.gx then 
		return
	end
	local selX, selY = self.sel.gx, self.sel.gy
	local s, e, i
	if dir == "LEFT" or dir == "RIGHT" then
		if dir == "LEFT" then
			s, e, i = selX - 1, 1, -1
		else
			s, e, i = selX + 1, self.width, 1
		end
		for gx = s, e, i do
			if self[gx][selY] then
				self.sel = self[gx][selY]
				return
			end
		end
	else
		if dir == "UP" then
			s, e, i = selY - 1, 1, -1
		else
			s, e, i = selY + 1, self.height, 1
		end
		for gy = s, e, i do
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
function grid:Draw()
	local x = self.offX
	local h = cfg.gridHeight
	for gx = 1, self.width do
		local y = self.offY
		local w = self[gx].width
		for gy = 1, self.height do	
			local e = self[gx][gy]
			if not e or e.gx == gx then
				local ew = w
				if e and e.width and e.width > 1 then
					for i = 1, e.width - 1 do
						ew = ew + self[gx + i].width
					end
				end
				SetDrawColor(unpack(e and e.borderCol or cfg.defBorderCol))
				DrawImage(nil, x, y, ew, h)
				SetDrawColor(unpack(e and e.cellCol or cfg.defCellCol))
				DrawImage(nil, x + 1, y + 1, ew - 2, h - 2)
			end
			y = y + cfg.gridHeight
		end
		x = x + self[gx].width
	end
	for gx = 1, self.width do 
		for gy = 1, self.height do
			local e = self[gx][gy]
			if e and e.gx == gx and e.Draw and e ~= self.focus then
				e:Draw()
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
function grid:OnKeyDown(key, doubleClick)
	if self.focus then
		if self.focus.OnKeyDown then
			self.focus:OnKeyDown(key, doubleClick)
		end
	elseif key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
		self.sel = nil
		local cx, cy = GetCursorPos()
		local gcx, gcy = cx - self.offX, cy - self.offY
		local gy = math.floor(gcy / cfg.gridHeight) + 1
		if gcx >= 0 and gcy >= 0 and gcx < self.realWidth and gcy < self.realHeight then
			local x = 0
			for gx = 1, self.width do
				if gcx >= x and gcx < x + self[gx].width then
					if self[gx][gy] then
						local e = self[gx][gy]
						self.sel = e
						if e.OnKeyDown then
							e:OnKeyDown(key, doubleClick)
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
function grid:OnKeyUp(key)
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
function grid:OnChar(key)
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

local calcs = { }

function calcs:Init(build)
	self.build = build
	self.input = { }
	self.output = { }
	grid.input = self.input
	grid.output = self.output
	grid:Clear()
	self.undo = { }
	self.redo = { }
	self:LoadControl()
end
function calcs:Shutdown()
	grid:SetFocus()
	grid:Clear()
	self.redo = nil
	self.undo = nil
end

function calcs:Load(xml, dbFileName)
	for _, node in ipairs(xml) do
		if type(node) == "table" then
			if node.elem == "Input" then
				if not node.attrib.name then
					launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
					return true
				end
				if node.attrib.number then
					self.input[node.attrib.name] = tonumber(node.attrib.number)
				elseif node.attrib.string then
					self.input[node.attrib.name] = node.attrib.string
				elseif node.attrib.boolean then
					self.input[node.attrib.name] = node.attrib.boolean == "true"
				else
					launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing number, string or boolean attribute", fileName)
					return true
				end
			end
		end
	end
	self:AddUndoState()
	self.buildFlag = true
end
function calcs:Save(xml)
	self.modFlag = false
	for k, v in pairs(self.input) do
		local child = {elem = "Input", attrib = {name = k}}
		if type(v) == "number" then
			child.attrib.number = tostring(v)
		elseif type(v) == "boolean" then
			child.attrib.boolean = tostring(v)
		else
			child.attrib.string = tostring(v)
		end
		t_insert(xml, child)
	end
end

function calcs:AddUndoState()
	t_insert(self.undo, 1, copyTable(self.input))
	self.undo[102] = nil
end

function calcs:LoadControl()
	grid:Clear()
	local errMsg
	errMsg, self.control = PLoadModule("Modules/CalcsControl", grid)
	if errMsg then
		launch:ShowErrMsg("Error loading control script: %s", errMsg)
	elseif not self.control then
		launch:ShowErrMsg("Error loading control script: no object returned")
	end
end

function calcs:RunControl()
	if grid.changeFlag then
		grid.changeFlag = false
		self.modFlag = true
		self.buildFlag = true
		self:AddUndoState()
		if not self.noClearRedo then
			self.redo = {}
		end
		self.noClearRedo = false
	end
	if self.buildFlag or self.build.spec.buildFlag or self.build.items.buildFlag then
		self.buildFlag = false
		self.build.spec.buildFlag = false
		self.build.items.buildFlag = false
		wipeTable(self.output)
		if self.control and self.control.buildOutput then
			local errMsg, otherMsg = PCall(self.control.buildOutput, grid.input, grid.output, self.build)
			if errMsg then
				launch:ShowErrMsg("Error building output: %s", errMsg)
			elseif otherMsg then
				launch:ShowPrompt(1, 0.5, 0, otherMsg.."\n\nEnter/Escape to Dismiss", function(key)
					if key == "RETURN" or key == "ESCAPE" then
						return true
					end
				end)
			end
		end
		self.powerBuildFlag = true
	end
end

function calcs:BuildPower()
	local calcFunc, base = self:GetNodeCalculator()
	if not calcFunc then
		return
	end
	local cache = { }
	self.powerMax = { }
	for _, node in pairs(self.build.spec.nodes) do
		node.power = wipeTable(node.power)
		if not node.alloc and node.modKey ~= "" then
			if not cache[node.modKey] then
				cache[node.modKey] = calcFunc({node})
			end
			local output = cache[node.modKey]
			local dpsKey = base.mode_average and "total_avg" or "total_dps"
			node.power.dps = (output[dpsKey] - base[dpsKey]) / base[dpsKey]
			node.power.def = (output.total_life - base.total_life) / m_max(2000, base.total_life) * 0.5 + 
							 (output.total_armour - base.total_armour) / m_max(10000, base.total_armour) + 
							 (output.total_energyShield - base.total_energyShield) / m_max(2000, base.total_energyShield) + 
							 (output.total_evasion - base.total_evasion) / m_max(10000, base.total_evasion) +
							 (output.total_lifeRegen - base.total_lifeRegen) / 500
			if node.path then
				self.powerMax.dps = m_max(self.powerMax.dps or 0, node.power.dps)
				self.powerMax.def = m_max(self.powerMax.def or 0, node.power.def)
			end
		end
	end
	self.powerBuildFlag = false
end

function calcs:GetNodeCalculator()
	if self.control and self.control.getNodeCalculator then
		local errMsg, calcFunc, calcBase = PCall(self.control.getNodeCalculator, grid.input, self.build)
		if errMsg then
			launch:ShowErrMsg("Error creating calculator: %s", errMsg)
		elseif otherMsg then
			launch:ShowPrompt(1, 0.5, 0, otherMsg.."\n\nEnter/Escape to Dismiss")
		end
		return calcFunc, calcBase
	end	
end

function calcs:GetItemCalculator()
	if self.control and self.control.getItemCalculator then
		local errMsg, calcFunc, calcBase = PCall(self.control.getItemCalculator, grid.input, self.build)
		if errMsg then
			launch:ShowErrMsg("Error creating calculator: %s", errMsg)
		elseif otherMsg then
			launch:ShowPrompt(1, 0.5, 0, otherMsg.."\n\nEnter/Escape to Dismiss")
		end
		return calcFunc, calcBase
	end	
end

function calcs:DrawGrid(viewPort, inputEvents)
	grid.offX = viewPort.x + m_floor((viewPort.width - grid.realWidth) / 2)
	grid.offY = viewPort.y + 2
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "r" and IsKeyDown("CTRL") then
				self:LoadControl()
				self.buildFlag = true
			elseif event.key == "z" and IsKeyDown("CTRL") then
				if self.undo[2] then
					t_insert(self.redo, 1, table.remove(self.undo, 1))
					wipeTable(self.input)
					for k, v in pairs(table.remove(self.undo, 1)) do
						self.input[k] = v
					end
					grid.changeFlag = true
					self.noClearRedo = true
				end
			elseif event.key == "y" and IsKeyDown("CTRL") then
				if self.redo[1] then
					wipeTable(self.input)
					for k, v in pairs(table.remove(self.redo, 1)) do
						self.input[k] = v
					end
					grid.changeFlag = true
					self.noClearRedo = true
				end
			else
				grid:OnKeyDown(event.key, event.doubleClick)
			end
		elseif event.type == "KeyUp" then
			grid:OnKeyUp(event.key)
		elseif event.type == "Char" then
			grid:OnChar(event.key)
		end
	end
	grid:Draw()
end

return calcs