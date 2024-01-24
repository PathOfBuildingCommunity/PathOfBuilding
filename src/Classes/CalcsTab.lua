-- Path of Building
--
-- Module: Calcs Tab
-- Calculations breakdown tab for the current build.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_max = math.max
local m_floor = math.floor

local buffModeDropList = {
	{ label = "Unbuffed", buffMode = "UNBUFFED" },
	{ label = "Buffed", buffMode = "BUFFED" },
	{ label = "In Combat", buffMode = "COMBAT" },
	{ label = "Effective DPS", buffMode = "EFFECTIVE" } 
}

local CalcsTabClass = newClass("CalcsTab", "UndoHandler", "ControlHost", "Control", function(self, build)
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
	self:NewSection(3, "SkillSelect", 1, colorCodes.NORMAL, {{ defaultCollapsed = false, label = "View Skill Details", data = {
		{ label = "Socket Group", { controlName = "mainSocketGroup", 
			control = new("DropDownControl", nil, 0, 0, 300, 16, nil, function(index, value) 
				self.input.skill_number = index
				self:AddUndoState()
				self.build.buildFlag = true
			end) {
				tooltipFunc = function(tooltip, mode, index, value)
					local socketGroup = self.build.skillsTab.socketGroupList[index]
					if socketGroup and tooltip:CheckForUpdate(socketGroup, self.build.outputRevision) then
						self.build.skillsTab:AddSocketGroupTooltip(tooltip, socketGroup)
					end
				end
			}
		}, },
		{ label = "Active Skill", { controlName = "mainSkill", 
			control = new("DropDownControl", nil, 0, 0, 300, 16, nil, function(index, value)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				mainSocketGroup.mainActiveSkillCalcs = index
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Skill Part", playerFlag = "multiPart", { controlName = "mainSkillPart", 
			control = new("DropDownControl", nil, 0, 0, 250, 16, nil, function(index, value)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				local srcInstance = mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeEffect.srcInstance
				srcInstance.skillPartCalcs = index
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },{ label = "Skill Stages", playerFlag = "multiStage", { controlName = "mainSkillStageCount",
			control = new("EditControl", nil, 0, 0, 52, 16, nil, nil, "%D", nil, function(buf)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				local srcInstance = mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeEffect.srcInstance
				srcInstance.skillStageCountCalcs = tonumber(buf)
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Active Mines", playerFlag = "mine", { controlName = "mainSkillMineCount",
			control = new("EditControl", nil, 0, 0, 52, 16, nil, nil, "%D", nil, function(buf)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				local srcInstance = mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeEffect.srcInstance
				srcInstance.skillMineCountCalcs = tonumber(buf)
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		}, },
		{ label = "Show Minion Stats", flag = "haveMinion", { controlName = "showMinion", 
			control = new("CheckBoxControl", nil, 0, 0, 18, nil, function(state)
				self.input.showMinion = state
				self:AddUndoState()
			end, "Show stats for the minion instead of the player.")
		}, },
		{ label = "Minion", flag = "minion", { controlName = "mainSkillMinion",
			control = new("DropDownControl", nil, 0, 0, 160, 16, nil, function(index, value)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				local srcInstance = mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeEffect.srcInstance
				if value.itemSetId then
					srcInstance.skillMinionItemSetCalcs = value.itemSetId
				else
					srcInstance.skillMinionCalcs = value.minionId
				end
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		} },
		{ label = "Spectre Library", flag = "spectre", { controlName = "mainSkillMinionLibrary",
			control = new("ButtonControl", nil, 0, 0, 100, 16, "Manage Spectres...", function()
				self.build:OpenSpectreLibrary()
			end)
		} },
		{ label = "Minion Skill", flag = "haveMinion", { controlName = "mainSkillMinionSkill",
			control = new("DropDownControl", nil, 0, 0, 200, 16, nil, function(index, value)
				local mainSocketGroup = self.build.skillsTab.socketGroupList[self.input.skill_number]
				local srcInstance = mainSocketGroup.displaySkillListCalcs[mainSocketGroup.mainActiveSkillCalcs].activeEffect.srcInstance
				srcInstance.skillMinionSkillCalcs = index
				self:AddUndoState()
				self.build.buildFlag = true
			end)
		} },
		{ label = "Calculation Mode", { 
			controlName = "mode", 
			control = new("DropDownControl", nil, 0, 0, 100, 16, buffModeDropList, function(index, value) 
				self.input.misc_buffMode = value.buffMode 
				self:AddUndoState()
				self.build.buildFlag = true
			end, [[
This controls the calculation of the stats shown in this tab.
The stats in the sidebar are always shown in Effective DPS mode, regardless of this setting.

Unbuffed: No auras, buffs, or other support skills or effects will apply. This is equivalent to standing in town.
Buffed: Aura and buff skills apply. This is equivalent to standing in your hideout with auras and buffs turned on.
In Combat: Charges and combat buffs such as Onslaught will also apply. This will show your character sheet stats in combat.
Effective DPS: Curses and enemy properties (such as resistances and status conditions) will also apply. This estimates your true DPS.]]) 
		}, },
		{ label = "Aura and Buff Skills", flag = "buffs", textSize = 12, { format = "{output:BuffList}", { breakdown = "SkillBuffs" } }, },
		{ label = "Combat Buffs", flag = "combat", textSize = 12, { format = "{output:CombatList}" }, },
		{ label = "Curses and Debuffs", flag = "effective", textSize = 12, { format = "{output:CurseList}", { breakdown = "SkillDebuffs" } }, },
	}}}, function(section)
		self.build:RefreshSkillSelectControls(section.controls, self.input.skill_number, "Calcs")
		section.controls.showMinion.state = self.input.showMinion
		section.controls.mode:SelByValue(self.input.misc_buffMode, "buffMode")
	end)

	-- Add sections from the CalcSections module
	local sectionData = LoadModule("Modules/CalcSections")
	for _, section in ipairs(sectionData) do
		self:NewSection(unpack(section))
	end

	self.controls.breakdown = new("CalcBreakdownControl", self)

	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, 0, 0, 18, 0, 50, "VERTICAL", true)
	self.powerBuilderInitialized = nil
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
					if section.id == node.attrib.id and node.attrib.subsection then
						for _, subsection in ipairs(section.subSection) do
							if subsection.id == node.attrib.subsection then
								subsection.collapsed = node.attrib.collapsed == "true"
								break
							end
						end
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
		for _, subSection in ipairs(section.subSection) do
			t_insert(xml, { elem = "Section", attrib = {
				id = section.id,
				subsection = subSection.id,
				collapsed = tostring(subSection.collapsed),
			} })
		end
	end
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
	if main.portraitMode then maxCol = 3 end
	local colY = { }
	local maxY = 0
	for _, section in ipairs(self.sectionList) do
		section:UpdateSize()
		if section.enabled then
			local col
			if section.group == 1 then
				-- Group 1: Offense or 3 wide sections
				-- This group is put into the first 3 columns, with each section placed into the highest available location
				col = 1
				if section.width == self.colWidth then -- if 1 col wide
					local minY = colY[col] or baseY
					for c = 2, 3 do
						if (colY[c] or baseY) < minY then
							col = c
							minY = colY[c] or baseY
						end
					end
				else
					for c = 2, 3 do
						colY[col] = m_max(colY[col] or baseY, colY[c] or baseY)
					end
				end
			elseif section.group == 2 then
				-- Group 2: Defense (the first 4 sections)
				-- This group is put entirely into the 4th column
				if maxCol >= 4 then
					col = 4
				end
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
			if section.enabled and (main.portraitMode and section.group == 2 or section.group == 3) then
				local col = 3
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

	for _, event in ipairs(inputEvents) do
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
	for _, event in ipairs(inputEvents) do
		if event.type == "KeyUp" then
			if self.controls.scrollBar:IsScrollDownKey(event.key) then
				self.controls.scrollBar:Scroll(1)
			elseif self.controls.scrollBar:IsScrollUpKey(event.key) then
				self.controls.scrollBar:Scroll(-1)
			end
		end
	end

	main:DrawBackground(viewPort)

	if not self.displayPinned then
		self.displayData = nil
	end

	self:DrawControls(viewPort, self.selControl)

	if self.displayData then
		if self.displayPinned and not self.selControl then
			self:SelectControl(self.controls.breakdown)
		end
	else
		self.controls.breakdown:SetBreakdownData()
	end
end

function CalcsTabClass:NewSection(width, ...)
	local section = new("CalcSectionControl", self, width * self.colWidth + 8 * (width - 1), ...)
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
	if obj.playerFlag and not self.calcsEnv.player.mainSkill.skillFlags[obj.playerFlag] then
		return
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
		local ns, var = obj.haveOutput:match("^(%a+)%.(%a+)$")
		if ns then
			if not actor.output[ns] or not actor.output[ns][var] or actor.output[ns][var] == 0 then
				return
			end
		elseif not actor.output[obj.haveOutput] or actor.output[obj.haveOutput] == 0 then
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
	ConPrintf("Calc time: %d ms", GetTime() - start)
	--]]

	for _, node in pairs(self.build.spec.nodes) do
		-- Set default final mod list for all nodes; some may not be set during the main pass
		node.finalModList = node.modList
	end

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

-- Controls the coroutine that calculates node power
function CalcsTabClass:BuildPower()
	if self.powerBuildFlag then
		self.powerBuildFlag = false
		self.powerBuilder = coroutine.create(self.PowerBuilder)
	end
	if self.powerBuilder then
		local res, errMsg = coroutine.resume(self.powerBuilder, self)
		if launch.devMode and not res then
			error(errMsg)
		end
		if coroutine.status(self.powerBuilder) == "dead" then
			self.powerBuilder = nil
			if self.build.powerBuilderCallback then
				self.build.powerBuilderCallback()
			end
		end
	end
end

-- Estimate the offensive and defensive power of all unallocated nodes
function CalcsTabClass:PowerBuilder()
	--local timer_start = GetTime()
	GlobalCache.useFullDPS = self.powerStat and self.powerStat.stat == "FullDPS" or false
	local calcFunc, calcBase = self:GetMiscCalculator()
	local cache = { }
	local newPowerMax = {
		singleStat = 0,
		offence = 0,
		offencePerPoint = 0,
		defence = 0,
		defencePerPoint = 0
	}
	if not self.powerMax then
		self.powerMax = newPowerMax
	end
	if coroutine.running() then
		coroutine.yield()
	end

	local start = GetTime()
	for nodeId, node in pairs(self.build.spec.nodes) do
		wipeTable(node.power)
		if self.nodePowerMaxDepth == nil or self.nodePowerMaxDepth >= node.pathDist then
			if not node.alloc and node.modKey ~= "" and not self.mainEnv.grantedPassives[nodeId] then
				if not cache[node.modKey] then
					cache[node.modKey] = calcFunc({ addNodes = { [node] = true } }, { requirementsItems = true, requirementsGems = true, skills = true })
				end
				local output = cache[node.modKey]
				if self.powerStat and self.powerStat.stat and not self.powerStat.ignoreForNodes then
					node.power.singleStat = self:CalculatePowerStat(self.powerStat, output, calcBase)
					if node.path and not node.ascendancyName then
						newPowerMax.singleStat = m_max(newPowerMax.singleStat, node.power.singleStat)
						node.power.pathPower = node.power.singleStat
						local pathNodes = { }
						for _, node in pairs(node.path) do
							pathNodes[node] = true
						end
						if node.pathDist > 1 then
							node.power.pathPower = self:CalculatePowerStat(self.powerStat, calcFunc({ addNodes = pathNodes }, { requirementsItems = true, requirementsGems = true, skills = true }), calcBase)
						end
					end
				else
					if calcBase.Minion then
						node.power.offence = (output.Minion.CombinedDPS - calcBase.Minion.CombinedDPS) / calcBase.Minion.CombinedDPS
					else
						node.power.offence = (output.CombinedDPS - calcBase.CombinedDPS) / calcBase.CombinedDPS
					end
					node.power.defence = (output.LifeUnreserved - calcBase.LifeUnreserved) / m_max(3000, calcBase.Life) +
									(output.Armour - calcBase.Armour) / m_max(10000, calcBase.Armour) +
									((output.EnergyShieldRecoveryCap or output.EnergyShield) - (calcBase.EnergyShieldRecoveryCap or calcBase.EnergyShield)) / m_max(3000, (calcBase.EnergyShieldRecoveryCap or calcBase.EnergyShield)) +
									(output.Evasion - calcBase.Evasion) / m_max(10000, calcBase.Evasion) +
									(output.LifeRegenRecovery - calcBase.LifeRegenRecovery) / 500 +
									(output.EnergyShieldRegenRecovery - calcBase.EnergyShieldRegenRecovery) / 1000
					if node.path and not node.ascendancyName then
						newPowerMax.offence = m_max(newPowerMax.offence, node.power.offence)
						newPowerMax.defence = m_max(newPowerMax.defence, node.power.defence)
						newPowerMax.offencePerPoint = m_max(newPowerMax.offencePerPoint, node.power.offence / node.pathDist)
						newPowerMax.defencePerPoint = m_max(newPowerMax.defencePerPoint, node.power.defence / node.pathDist)

					end
				end
			elseif node.alloc and node.modKey ~= "" and not self.mainEnv.grantedPassives[nodeId] then
				local output = calcFunc({ removeNodes = { [node] = true } }, { requirementsItems = true, requirementsGems = true, skills = true })
				if self.powerStat and self.powerStat.stat and not self.powerStat.ignoreForNodes then
					node.power.singleStat = self:CalculatePowerStat(self.powerStat, output, calcBase)
					if node.depends and not node.ascendancyName then
						node.power.pathPower = node.power.singleStat
						local pathNodes = { }
						for _, node in pairs(node.depends) do
							pathNodes[node] = true
						end
						if #node.depends > 1 then
							node.power.pathPower = self:CalculatePowerStat(self.powerStat, calcFunc({ removeNodes = pathNodes }, { requirementsItems = true, requirementsGems = true, skills = true }), calcBase)
						end
					end
				end
			end
		end
		if coroutine.running() and GetTime() - start > 100 then
			coroutine.yield()
			start = GetTime()
		end
	end

	-- Calculate the impact of every cluster notable
	-- used for the power report screen
	for nodeName, node in pairs(self.build.spec.tree.clusterNodeMap) do
		if not node.power then
			node.power = {}
		end
		wipeTable(node.power)
		if not node.alloc and node.modKey ~= "" and not self.mainEnv.grantedPassives[nodeId] then
			if not cache[node.modKey] then
				cache[node.modKey] = calcFunc({ addNodes = { [node] = true } }, { requirementsItems = true, requirementsGems = true, skills = true })
			end
			local output = cache[node.modKey]
			if self.powerStat and self.powerStat.stat and not self.powerStat.ignoreForNodes then
				node.power.singleStat = self:CalculatePowerStat(self.powerStat, output, calcBase)
			end
		end
		if coroutine.running() and GetTime() - start > 100 then
			coroutine.yield()
			start = GetTime()
		end
	end
	self.powerMax = newPowerMax
	self.powerBuilderInitialized = true
	--ConPrintf("Power Build time: %d ms", GetTime() - timer_start)
end

function CalcsTabClass:CalculatePowerStat(selection, original, modified)
	if modified.Minion and not selection.stat == "FullDPS" then
		original = original.Minion
		modified = modified.Minion
	end
	local originalValue = original[selection.stat] or 0
	local modifiedValue = modified[selection.stat] or 0
	if selection.transform then
		originalValue = selection.transform(originalValue)
		modifiedValue = selection.transform(modifiedValue)
	end
	return originalValue - modifiedValue
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
