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
	self.input.misc_buffMode = "EFFECTIVE"

	self.colWidth = 230
	self.sectionList = { }

	-- Special section for skill/mode selection
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
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				mainSocketGroup.mainActiveSkillCalcs = index
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Skill Part", flag = "multiPart", { controlName = "mainSkillPart", 
			control = common.New("DropDownControl", nil, 0, 0, 130, 16, nil, function(index)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeGem.srcGem.skillPartCalcs = index
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Show Minion Stats", flag = "haveMinion", { controlName = "showMinion", 
			control = common.New("CheckBoxControl", nil, 0, 0, 18, nil, function(state)
				self.input.showMinion = state
				self:AddUndoState()
			end, "Show stats for the minion instead of the player.")
		}, },
		{ label = "Minion", flag = "minion", { controlName = "mainSkillMinion",
			control = common.New("DropDownControl", nil, 0, 0, 150, 16, nil, function(index, val)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeGem.srcGem.skillMinionCalcs = val.val
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		} },
		{ label = "Spectre Library", flag = "spectre", { controlName = "mainSkillMinionLibrary",
			control = common.New("ButtonControl", nil, 0, 0, 100, 16, "Manage Spectres...", function()
				self.build:OpenSpectreLibrary()
			end)
		} },
		{ label = "Minion Skill", flag = "haveMinion", { controlName = "mainSkillMinionSkill",
			control = common.New("DropDownControl", nil, 0, 0, 200, 16, nil, function(index)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeGem.srcGem.skillMinionSkillCalcs = index
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		} },
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
		{ label = "Curses and Debuffs", flag = "effective", textSize = 12, { format = "{output:CurseList}" }, },
	}, function(section)
		self.build:RefreshSkillSelectControls(section.controls, self.input.skill_number, "Calcs")
		section.controls.showMinion.state = self.input.showMinion
		section.controls.mode:SelByValue(self.input.misc_buffMode)
	end)

	-- Add sections from the CalcSections module
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

	-- Arrange the sections
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
				-- Group 1: Offense 
				-- This group is put into the first 3 columns, with each section placed into the highest available location
				col = 1
				local minY = colY[col] or baseY
				for c = 2, 3 do
					if (colY[c] or baseY) < minY then
						col = c
						minY = colY[c] or baseY
					end
				end
			elseif section.group == 2 then
				-- Group 2: Defense (the first 4 sections)
				-- This group is put entirely into the 4th column
				col = 4
			elseif section.group == 3 then
				-- Group 3: Defense (the remaining sections)
				-- This group is put into a 5th column if there's room for one, otherwise they are handled separately
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
		-- There's no room for a 5th column
		-- Each section from group 3 will instead be placed into column 4 if there's room, otherwise they'll be put in columns 1-3
		for c = 1, 3 do
			colY[c] = m_max(colY[1], colY[2], colY[3])
		end
		for _, section in ipairs(self.sectionList) do
			if section.enabled and section.group == 3 then
				local col = 4
				if colY[col] + section.height + 4 >= m_max(viewPort.y + viewPort.height, maxY) then
					-- No room in the 4th column, find the highest available location in columns 1-4
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
		-- Give sections their actual Y position and let them update
		section.y = section.y - self.controls.scrollBar.offset
		section:UpdatePos()
	end

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

function CalcsTabClass:CheckFlag(obj)
	local actor = self.input.showMinion and self.calcsEnv.minion or self.calcsEnv.player
	local skillFlags = actor.mainSkill.skillFlags
	if obj.flag and not skillFlags[obj.flag] then
		return
	end
	if obj.flagList then
		for _, flag in ipairs(obj.flagList) do
			if not skillFlags[flag] then
				return
			end
		end
	end
	if obj.notFlag and skillFlags[obj.notFlag] then
		return
	end
	if obj.notFlagList then
		for _, flag in ipairs(obj.notFlagList) do
			if skillFlags[flag] then
				return
			end
		end
	end
	if obj.haveOutput then
		if not actor.output[obj.haveOutput] or actor.output[obj.haveOutput] == 0 then
			return
		end
	end
	return true
end

-- Build the calculation output tables
function CalcsTabClass:BuildOutput()
	self.powerBuildFlag = true

	--[[
	local start = GetTime()
	SetProfiling(true)
	for i = 1, 1000  do
		self.calcs.buildOutput(self.build, "MAIN")
	end
	SetProfiling(false)
	ConPrintf("Calc time: %d msec", GetTime() - start)
	--]]

	self.mainEnv = self.calcs.buildOutput(self.build, "MAIN")
	self.mainOutput = self.mainEnv.player.output
	self.calcsEnv = self.calcs.buildOutput(self.build, "CALCS")
	self.calcsOutput = self.calcsEnv.player.output

	if self.displayData then
		self.controls.breakdown:SetBreakdownData()
		self.controls.breakdown:SetBreakdownData(self.displayData, self.displayPinned)
	end
	
	-- Retrieve calculator functions
	self.nodeCalculator = { self.calcs.getNodeCalculator(self.build) }
	self.miscCalculator = { self.calcs.getMiscCalculator(self.build) }
end

-- Controls the coroutine that calculations node power
function CalcsTabClass:BuildPower()
	if self.powerBuildFlag then
		self.powerBuildFlag = false
		self.powerBuilder = coroutine.create(self.PowerBuilder)
	end
	if self.powerBuilder then
		collectgarbage("stop")
		local res, errMsg = coroutine.resume(self.powerBuilder, self)
		if launch.devMode and not res then
			error(errMsg)
		end
		if coroutine.status(self.powerBuilder) == "dead" then
			self.powerBuilder = nil
		end
		collectgarbage("restart")
	end
end

-- Estimate the offensive and defensive power of all unallocated nodes
function CalcsTabClass:PowerBuilder()
	local calcFunc, calcBase = self:GetNodeCalculator()
	local cache = { }
	local newPowerMax = { 
		dps = 0, 
		def = 0
	}
	if not self.powerMax then
		self.powerMax = newPowerMax
	end
	if coroutine.running() then
		coroutine.yield()
	end
	local start = GetTime()
	for _, node in pairs(self.build.spec.nodes) do
		wipeTable(node.power)
		if not node.alloc and node.modKey ~= "" then
			if not cache[node.modKey] then
				cache[node.modKey] = calcFunc({node})
			end
			local output = cache[node.modKey]
			if calcBase.Minion then
				node.power.dps = (output.Minion.CombinedDPS - calcBase.Minion.CombinedDPS) / calcBase.Minion.CombinedDPS
			else
				node.power.dps = (output.CombinedDPS - calcBase.CombinedDPS) / calcBase.CombinedDPS
			end
			node.power.def = (output.LifeUnreserved - calcBase.LifeUnreserved) / m_max(3000, calcBase.Life) + 
							 (output.Armour - calcBase.Armour) / m_max(10000, calcBase.Armour) + 
							 (output.EnergyShield - calcBase.EnergyShield) / m_max(3000, calcBase.EnergyShield) + 
							 (output.Evasion - calcBase.Evasion) / m_max(10000, calcBase.Evasion) +
							 (output.LifeRegen - calcBase.LifeRegen) / 500 +
							 (output.EnergyShieldRegen - calcBase.EnergyShieldRegen) / 1000
			if node.path then
				newPowerMax.dps = m_max(newPowerMax.dps, node.power.dps)
				newPowerMax.def = m_max(newPowerMax.def, node.power.def)
			end
		end
		if coroutine.running() and GetTime() - start > 100 then
			coroutine.yield()
			start = GetTime()
		end
	end	
	self.powerMax = newPowerMax
end

function CalcsTabClass:GetNodeCalculator()
	return unpack(self.nodeCalculator)
end

function CalcsTabClass:GetMiscCalculator()
	return unpack(self.miscCalculator)
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
