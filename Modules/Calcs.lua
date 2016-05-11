-- Path of Building
--
-- Module: Calcs
-- Calculations breakdown view for the active build
--
local launch, main = ...

local ipairs = ipairs
local m_max = math.max
local m_floor = math.floor
local t_insert = table.insert
local t_remove = table.remove

local calcs = { }

function calcs:Init(build)
	self.build = build

	self.input = { }
	self.output = { }
	self.grid = common.New("Grid", self.input, self.output)

	self.undo = { }
	self.redo = { }

	self:LoadControl()
end

function calcs:Shutdown()
	self.grid:Clear()
	self.grid = nil
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
	self.undo = { copyTable(self.input) }
	self.redo = { }
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

function calcs:DrawGrid(viewPort, inputEvents)
	self.grid.offX = viewPort.x + m_floor((viewPort.width - self.grid.realWidth) / 2)
	self.grid.offY = viewPort.y + 2
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "r" and IsKeyDown("CTRL") then
				self:LoadControl()
				self.buildFlag = true
			elseif event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
			else
				self.grid:OnKeyDown(event.key, event.doubleClick)
			end
		elseif event.type == "KeyUp" then
			self.grid:OnKeyUp(event.key)
		elseif event.type == "Char" then
			self.grid:OnChar(event.key)
		end
	end
	self.grid:Draw()
end

function calcs:LoadControl()
	self.grid:Clear()
	local errMsg
	errMsg, self.control = PLoadModule("Modules/CalcsControl", self.grid)
	if errMsg then
		launch:ShowErrMsg("Error loading control script: %s", errMsg)
	elseif not self.control then
		launch:ShowErrMsg("Error loading control script: no object returned")
	end
end

function calcs:RunControl()
	if self.grid.changeFlag then
		self.grid.changeFlag = false
		self:AddUndoState()
	end
	if self.buildFlag or self.build.spec.buildFlag or self.build.items.buildFlag then
		self.buildFlag = false
		self.build.spec.buildFlag = false
		self.build.items.buildFlag = false
		wipeTable(self.output)
		if self.control and self.control.buildOutput then
			local errMsg, otherMsg = PCall(self.control.buildOutput, self.input, self.output, self.build)
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
		local errMsg, calcFunc, calcBase = PCall(self.control.getNodeCalculator, self.input, self.build)
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
		local errMsg, calcFunc, calcBase = PCall(self.control.getItemCalculator, self.input, self.build)
		if errMsg then
			launch:ShowErrMsg("Error creating calculator: %s", errMsg)
		elseif otherMsg then
			launch:ShowPrompt(1, 0.5, 0, otherMsg.."\n\nEnter/Escape to Dismiss")
		end
		return calcFunc, calcBase
	end	
end

function calcs:AddUndoState(noClearRedo)
	t_insert(self.undo, 1, copyTable(self.input))
	self.undo[102] = nil
	self.modFlag = true
	self.buildFlag = true
	if not noClearRedo then
		self.redo = {}
	end
end

function calcs:Undo()
	if self.undo[2] then
		t_insert(self.redo, 1, t_remove(self.undo, 1))
		wipeTable(self.input)
		for k, v in pairs(t_remove(self.undo, 1)) do
			self.input[k] = v
		end
		self:AddUndoState(true)
	end
end

function calcs:Redo()
	if self.redo[1] then
		wipeTable(self.input)
		for k, v in pairs(t_remove(self.redo, 1)) do
			self.input[k] = v
		end
		self:AddUndoState(true)
	end
end

return calcs