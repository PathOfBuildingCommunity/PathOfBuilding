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
local m_min = math.min
local m_floor = math.floor
local band = bit.band

local sectionData = LoadModule("Modules/CalcSections")

local CalcsTabClass = common.NewClass("CalcsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.calcs = LoadModule("Modules/Calcs")

	self.input = { }
	self.input.skill_number = 1
	self.input.skill_activeNumber = 1
	self.input.skill_part = 1
	self.input.misc_buffMode = "EFFECTIVE"

	self.colWidth = 230
	self.sectionList = { }

	self:NewSection(3, "SkillSelect", 1, "View Skill Details", data.colorCodes.NORMAL, {
		{ label = "Socket Group", { controlName = "mainSocketGroup", 
			control = common.New("DropDownControl", nil, 0, 0, 300, 16, nil, function(index) 
				self.input.skill_number = index 
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Active Skill", { controlName = "mainSkill", 
			control = common.New("DropDownControl", nil, 0, 0, 300, 16, nil, function(index)
				self.input.skill_activeNumber = index
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Skill Part", flag = "multiPart", { controlName = "mainSkillPart", 
			control = common.New("DropDownControl", nil, 0, 0, 100, 16, nil, function(index)
				self.input.skill_part = index
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Calculation Mode", { 
			controlName = "mode", 
			control = common.New("DropDownControl", nil, 0, 0, 100, 16, {
				{label="Unbuffed",val="UNBUFFED"},
				{label="Buffed",val="BUFFED"},
				{label="In Combat",val="COMBAT"},
				{label="Effective DPS",val="EFFECTIVE"} 
			}, function(_, sel) 
				self.input.misc_buffMode = sel.val 
				self:AddUndoState()
				self.build.buildFlag = true
			end, [[
This controls the calculation of the stats shown in this tab.
The stats in the sidebar are always shown in Effective DPS mode, regardless of this setting.

Unbuffed: No auras, buffs, or other support skills or effects will apply. This is equivelant to standing in town.
Buffed: Aura and buff skills apply. This is equivelant to standing in your hideout with auras and buffs turned on.
In Combat: Charges and combat buffs such as Onslaught will also apply. This will show your character sheet stats in combat.
Effective DPS: Curses and enemy properties (such as resistances and status conditions) will also apply. This estimates your true DPS.]]) 
		}, },
		{ label = "Aura and Buff Skills", flag = "buffs", textSize = 12, { format = "{output:BuffList}" }, },
		{ label = "Combat Buffs", flag = "combat", textSize = 12, { format = "{output:CombatList}" }, },
		{ label = "Curse Skills", flag = "effective", textSize = 12, { format = "{output:CurseList}" }, },
	}, function(section)
		wipeTable(section.controls.mainSocketGroup.list)
		for i, socketGroup in pairs(self.build.skillsTab.socketGroupList) do
			section.controls.mainSocketGroup.list[i] = { val = i, label = socketGroup.displayLabel }
		end
		if #section.controls.mainSocketGroup.list == 0 then
			section.controls.mainSocketGroup.list[1] = { val = 1, label = "<No skills added yet>" }
		else
			local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
			wipeTable(section.controls.mainSkill.list)
			for i, activeSkill in ipairs(mainSocketGroup.displaySkillList) do
				t_insert(section.controls.mainSkill.list, { val = i, label = activeSkill.activeGem.name })
			end
			section.controls.mainSkill.enabled = #mainSocketGroup.displaySkillList > 1
			if mainSocketGroup.displaySkillList[1] then
				local activeGem = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeGem
				if activeGem and activeGem.data.parts and #activeGem.data.parts > 1 then
					section.controls.mainSkillPart.shown = true
					wipeTable(section.controls.mainSkillPart.list)
					for i, part in ipairs(activeGem.data.parts) do
						t_insert(section.controls.mainSkillPart.list, { val = i, label = part.name })
					end
					section.controls.mainSkillPart.sel = self.input.skill_part
				end
			end
		end
		section.controls.mainSocketGroup.sel = self.input.skill_number
		section.controls.mode:SelByValue(self.input.misc_buffMode)
	end)

	for _, section in ipairs(sectionData) do
		self:NewSection(unpack(section))
	end

	self.controls.breakdown = common.New("CalcBreakdown", self)

	self.controls.scrollBar = common.New("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, 0, 0, 18, 0, 50, "VERTICAL", true)
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
			elseif node.elem == "Section" then
				if not node.attrib.id then
					launch:ShowErrMsg("^1Error parsing '%s': 'Section' element missing id attribute", fileName)
					return true
				end
				for _, section in ipairs(self.sectionList) do
					if section.id == node.attrib.id then
						section.collapsed = (node.attrib.collapsed == "true")
						break
					end
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
	for _, section in ipairs(self.sectionList) do
		t_insert(xml, { elem = "Section", attrib = {
			id = section.id,
			collapsed = tostring(section.collapsed),
		} })
	end
	self.modFlag = false
end

function CalcsTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

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
	self:ProcessControlsInput(inputEvents, viewPort)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if event.key == "WHEELDOWN" then
				self.controls.scrollBar:Scroll(1)
			elseif event.key == "WHEELUP" then
				self.controls.scrollBar:Scroll(-1)
			end
		end
	end

	main:DrawBackground(viewPort)

	local baseX = viewPort.x + 4
	local baseY = viewPort.y + 4
	local maxCol = m_floor(viewPort.width / (self.colWidth + 8))
	local colY = { }
	local maxY = 0
	for _, section in ipairs(self.sectionList) do
		section:UpdateSize()
		if section.enabled then
			local col
			if section.group == 1 then
				col = 1
				local minY = colY[col] or baseY
				for c = 2, 3 do
					if (colY[c] or baseY) < minY then
						col = c
						minY = colY[c] or baseY
					end
				end
			elseif section.group == 2 then
				col = 4
			elseif section.group == 3 then
				if maxCol >= 5 then
					col = 5
				end
			end
			if col then
				section.x = baseX + (self.colWidth + 8) * (col - 1)
				section.y = colY[col] or baseY
				for c = col, col + section.widthCols - 1 do
					colY[c] = section.y + section.height + 8
				end
				maxY = m_max(maxY, colY[col])
			end
		end
	end
	if maxCol < 5 then
		for c = 1, 3 do
			colY[c] = m_max(colY[1], colY[2], colY[3])--maxY
		end
		for _, section in ipairs(self.sectionList) do
			if section.enabled and section.group == 3 then
				local col = 4
				if colY[col] + section.height + 4 >= m_max(viewPort.y + viewPort.height, maxY) then
					local minY = colY[col]
					for c = 3, 1, -1 do
						if colY[c] < minY then
							col = c
							minY = colY[c]
						end
					end
				end
				section.x = baseX + (self.colWidth + 8) * (col - 1)
				section.y = colY[col]
				colY[col] = section.y + section.height + 8
				maxY = m_max(maxY, colY[col])
			end
		end
	end
	self.controls.scrollBar.height = viewPort.height
	self.controls.scrollBar:SetContentDimension(maxY - baseY, viewPort.height)
	for _, section in ipairs(self.sectionList) do
		section.y = section.y - self.controls.scrollBar.offset
		section:UpdatePos()
	end

	if not self.displayPinned then
		self.displayData = nil
	end

	self:DrawControls(viewPort)

	if self.displayData then
		if self.displayPinned and not self.selControl then
			self:SelectControl(self.controls.breakdown)
		end
	else
		self.controls.breakdown:SetBreakdownData()
	end
end

function CalcsTabClass:NewSection(width, ...)
	local section = common.New("CalcSection", self, width * self.colWidth + 8 * (width - 1), ...)
	section.widthCols = width
	t_insert(self.controls, section)
	t_insert(self.sectionList, section)
end

function CalcsTabClass:ClearDisplayStat()
	self.displayData = nil
	self.displayPinned = nil
	self.controls.breakdown:SetBreakdownData()
end

function CalcsTabClass:SetDisplayStat(displayData, pin)
	if not displayData or (not pin and self.displayPinned) then
		return
	end
	self.displayData = displayData
	self.displayPinned = pin
	self.controls.breakdown:SetBreakdownData(displayData, pin)
end

-- Build the calculation output tables
function CalcsTabClass:BuildOutput()
	self.powerBuildFlag = true

	--[[
	local start = GetTime()
	SetProfiling(true)
	for i = 1, 1000  do
		wipeTable(self.mainOutput)
		self.calcs.buildOutput(self.build, self.mainOutput, "MAIN")
	end
	SetProfiling(false)
	ConPrintf("Calc time: %d msec", GetTime() - start)
	--]]

	self.mainEnv = self.calcs.buildOutput(self.build, "MAIN")
	self.mainOutput = self.mainEnv.output
	self.calcsEnv = self.calcs.buildOutput(self.build, "CALCS")
	self.calcsOutput = self.calcsEnv.output
	self.calcsBreakdown = self.calcsEnv.breakdown

	if self.displayData then
		self.controls.breakdown:SetBreakdownData()
		self.controls.breakdown:SetBreakdownData(self.displayData, self.displayPinned)
	end
	
	-- Retrieve calculator functions
	self.nodeCalculator = { self.calcs.getNodeCalculator(self.build) }
	self.itemCalculator = { self.calcs.getItemCalculator(self.build) }
end

-- Estimate the offensive and defensive power of all unallocated nodes
function CalcsTabClass:BuildPower()
	local calcFunc, calcBase = self:GetNodeCalculator()
	local cache = { }
	self.powerMax = { }
	for _, node in pairs(self.build.spec.nodes) do
		node.power = wipeTable(node.power)
		if not node.alloc and node.modKey ~= "" then
			if not cache[node.modKey] then
				cache[node.modKey] = calcFunc({node})
			end
			local output = cache[node.modKey]
			node.power.dps = (output.CombinedDPS - calcBase.CombinedDPS) / calcBase.CombinedDPS
			node.power.def = (output.LifeUnreserved - calcBase.LifeUnreserved) / m_max(3000, calcBase.Life) + 
							 (output.Armour - calcBase.Armour) / m_max(10000, calcBase.Armour) + 
							 (output.EnergyShield - calcBase.EnergyShield) / m_max(3000, calcBase.EnergyShield) + 
							 (output.Evasion - calcBase.Evasion) / m_max(10000, calcBase.Evasion) +
							 (output.LifeRegen - calcBase.LifeRegen) / 500 +
							 (output.EnergyShieldRegen - calcBase.EnergyShieldRegen) / 1000
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
