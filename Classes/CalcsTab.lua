-- Path of Building
--
-- Module: Calcs Tab
-- Calculations breakdown tab for the current build.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local m_floor = math.floor

local CalcsTabClass = common.NewClass("CalcsTab", "UndoHandler", "ControlHost", function(self, build)
	self.UndoHandler()
	self.ControlHost()

	self.build = build

	self.input = { }
	self.gridOutput = { }
	self.mainOutput = { }

	self.grid = common.New("Grid", self.input, self.gridOutput)

	self.calcs = LoadModule("Modules/Calcs", self.grid)

	self.controls.scrollBarH = common.New("ScrollBarControl", nil, 0, 0, 0, 18, 80, "HORIZONTAL", true)
	self.controls.scrollBarV = common.New("ScrollBarControl", nil, 0, 0, 18, 0, 80, "VERTICAL", true)
end)

function CalcsTabClass:Load(xml, dbFileName)
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
	self:ResetUndo()
end

function CalcsTabClass:Save(xml)
	for k, v in pairs(self.input) do
		local child = { elem = "Input", attrib = {name = k} }
		if type(v) == "number" then
			child.attrib.number = tostring(v)
		elseif type(v) == "boolean" then
			child.attrib.boolean = tostring(v)
		else
			child.attrib.string = tostring(v)
		end
		t_insert(xml, child)
	end
	self.modFlag = false
end

function CalcsTabClass:Draw(viewPort, inputEvents)
	local gridViewPort = { x = viewPort.x, y = viewPort.y }
	if self.grid.realWidth > viewPort.width then
		gridViewPort.height = viewPort.height - 18
	else
		gridViewPort.height = viewPort.height
	end
	if self.grid.realHeight > viewPort.height then
		gridViewPort.width = viewPort.width - 18
	else
		gridViewPort.width = viewPort.width
	end
	self.controls.scrollBarH.x = gridViewPort.x
	self.controls.scrollBarH.y = gridViewPort.y + gridViewPort.height
	self.controls.scrollBarH.width = gridViewPort.width
	self.controls.scrollBarH:SetContentDimension(self.grid.realWidth, viewPort.width)
	self.controls.scrollBarV.x = gridViewPort.x + gridViewPort.width
	self.controls.scrollBarV.y = gridViewPort.y
	self.controls.scrollBarV.height = gridViewPort.height
	self.controls.scrollBarV:SetContentDimension(self.grid.realHeight, viewPort.height)

	self.grid.offX = viewPort.x - self.controls.scrollBarH.offset
	self.grid.offY = viewPort.y - self.controls.scrollBarV.offset

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			end
		end
	end
	self.grid:ProcessInput(inputEvents, gridViewPort)
	self:ProcessControlsInput(inputEvents, viewPort)

	if self.grid.changeFlag then
		self.grid.changeFlag = false
		self:AddUndoState()
		self.build.buildFlag = true
	end

	main:DrawBackground(viewPort)

	self.grid:Draw()

	self:DrawControls(viewPort)
end

-- Build the calculation output tables
function CalcsTabClass:BuildOutput()
	self.powerBuildFlag = true

	wipeTable(self.gridOutput)
	self.calcs.buildOutput(self.build, self.input, self.gridOutput, "GRID")
	wipeTable(self.mainOutput)
	self.calcs.buildOutput(self.build, self.input, self.mainOutput, "MAIN")

	-- Retrieve calculator functions
	self.nodeCalculator = { self.calcs.getNodeCalculator(self.build, self.input) }
	self.itemCalculator = { self.calcs.getItemCalculator(self.build, self.input) }
end

-- Estimate the offensive and defensive of all unallocated nodes
function CalcsTabClass:BuildPower()
	local calcFunc, calcBase = self:GetNodeCalculator()
	local cache = { }
	self.powerMax = { }
	for _, node in pairs(self.build.spec.nodes) do
		node.power = wipeTable(node.power)
		if not node.alloc and node.modKey ~= "" then
			--if not cache[node.modKey] then
				cache[node.modKey] = calcFunc({node})
			--end
			local output = cache[node.modKey]
			node.power.dps = (output.total_combinedDPS - calcBase.total_combinedDPS) / calcBase.total_combinedDPS
			node.power.def = (output.total_life - calcBase.total_life) / m_max(2000, calcBase.total_life) * 0.5 + 
							 (output.total_armour - calcBase.total_armour) / m_max(10000, calcBase.total_armour) + 
							 (output.total_energyShield - calcBase.total_energyShield) / m_max(2000, calcBase.total_energyShield) + 
							 (output.total_evasion - calcBase.total_evasion) / m_max(10000, calcBase.total_evasion) +
							 (output.total_lifeRegen - calcBase.total_lifeRegen) / 500 +
							 (output.total_energyShieldRegen - calcBase.total_energyShieldRegen) / 1000
			if node.path then
				self.powerMax.dps = m_max(self.powerMax.dps or 0, node.power.dps)
				self.powerMax.def = m_max(self.powerMax.def or 0, node.power.def)
			end
		end
	end
	self.powerBuildFlag = false
end

function CalcsTabClass:GetNodeCalculator()
	return unpack(self.nodeCalculator)
end

function CalcsTabClass:GetItemCalculator()
	return unpack(self.itemCalculator)
end

function CalcsTabClass:CreateUndoState()
	return copyTable(self.input)
end

function CalcsTabClass:RestoreUndoState(state)
	wipeTable(self.input)
	for k, v in pairs(state) do
		self.input[k] = v
	end
end
