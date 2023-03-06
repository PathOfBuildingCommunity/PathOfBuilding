-- Path of Building
--
-- Module: Config Tab
-- Configuration tab for the current build.
--
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local s_upper = string.upper

local varList = LoadModule("Modules/ConfigOptions")

local ConfigTabClass = newClass("ConfigTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.input = { }
	self.placeholder = { }
	
	self.enemyLevel = 1

	self.sectionList = { }
	self.varControls = { }
	
	self:BuildModList()

	local lastSection
	for _, varData in ipairs(varList) do
		if varData.section then
			lastSection = new("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 0, 0, 360, 0, varData.section)
			lastSection.varControlList = { }
			lastSection.col = varData.col
			lastSection.height = function(self)
				local height = 20
				for _, varControl in pairs(self.varControlList) do
					if varControl:IsShown() then
						height = height + m_max(varControl.height, 16) + 4
					end
				end
				return m_max(height, 32)
			end
			t_insert(self.sectionList, lastSection)
			t_insert(self.controls, lastSection)
		else
			local control
			if varData.type == "check" then
				control = new("CheckBoxControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 18, varData.label, function(state)
					self.input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" then
				control = new("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 90, 18, "", nil, varData.type == "integer" and "^%-%d" or "%D", 7, function(buf, placeholder)
					if placeholder then
						self.placeholder[varData.var] = tonumber(buf)
					else
						self.input[varData.var] = tonumber(buf)
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end)
			elseif varData.type == "list" then
				control = new("DropDownControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 118, 16, varData.list, function(index, value)
					self.input[varData.var] = value.val
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "text" then
				control = new("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 8, 0, 344, 118, "", nil, "^%C\t\n", nil, function(buf, placeholder)
					if placeholder then
						self.placeholder[varData.var] = tostring(buf)
					else
						self.input[varData.var] = tostring(buf)
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end, 16)
			else 
				control = new("Control", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 16, 16)
			end
			if varData.ifNode then
				control.shown = function()
					if self.build.spec.allocNodes[varData.ifNode] then
						return true
					end
					local node = self.build.spec.nodes[varData.ifNode]
					if node and node.type == "Keystone" then
						return self.build.calcsTab.mainEnv.keystonesAdded[node.dn]
					end
				end
				control.tooltipText = function()
					return "This option is specific to '"..self.build.spec.nodes[varData.ifNode].dn.."'."..(varData.tooltip and "\n"..varData.tooltip or "")
				end
			elseif varData.ifOption then
				control.shown = function()
					return self.input[varData.ifOption]
				end
				control.tooltipText = varData.tooltip
			elseif varData.ifCond or varData.ifMinionCond or varData.ifEnemyCond then
				control.shown = function()
					local mainEnv = self.build.calcsTab.mainEnv
					if self.input[varData.var] then
						if varData.implyCondList then
							for _, implyCond in ipairs(varData.implyCondList) do
								if (implyCond and mainEnv.conditionsUsed[implyCond]) then
									return true
								end
							end
						end
						if (varData.implyCond and mainEnv.conditionsUsed[varData.implyCond]) or
						   (varData.implyMinionCond and mainEnv.minionConditionsUsed[varData.implyMinionCond]) or
						   (varData.implyEnemyCond and mainEnv.enemyConditionsUsed[varData.implyEnemyCond]) then
							return true
						end
					end
					if varData.ifCond then
						return mainEnv.conditionsUsed[varData.ifCond]
					elseif varData.ifMinionCond then
						return mainEnv.minionConditionsUsed[varData.ifMinionCond]
					else
						return mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
					end
				end
				control.tooltipText = function()
					if launch.devModeAlt then
						local out = varData.tooltip or ""
						local list
						if varData.ifCond then
							list = self.build.calcsTab.mainEnv.conditionsUsed[varData.ifCond]
						elseif varData.ifMinionCond then
							list = self.build.calcsTab.mainEnv.minionConditionsUsed[varData.ifMinionCond]
						else
							list = self.build.calcsTab.mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
						end
						for _, mod in ipairs(list) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifMult or varData.ifEnemyMult then
				control.shown = function()
					local mainEnv = self.build.calcsTab.mainEnv
					if self.input[varData.var] then
						if varData.implyCondList then
							for _, implyCond in ipairs(varData.implyCondList) do
								if (implyCond and mainEnv.conditionsUsed[implyCond]) then
									return true
								end
							end
						end
						if (varData.implyCond and mainEnv.conditionsUsed[varData.implyCond]) or
						   (varData.implyMinionCond and mainEnv.minionConditionsUsed[varData.implyMinionCond]) or
						   (varData.implyEnemyCond and mainEnv.enemyConditionsUsed[varData.implyEnemyCond]) then
							return true
						end
					end
					if varData.ifMult then
						return mainEnv.multipliersUsed[varData.ifMult]
					else
						return mainEnv.enemyMultipliersUsed[varData.ifEnemyMult]
					end
				end
				control.tooltipText = function()
					if launch.devModeAlt then
						local out = varData.tooltip or ""
						for _, mod in ipairs(self.build.calcsTab.mainEnv.multipliersUsed[varData.ifMult]) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifFlag then
				control.shown = function()
					local skillModList = self.build.calcsTab.mainEnv.player.mainSkill.skillModList
					local skillFlags = self.build.calcsTab.mainEnv.player.mainSkill.skillFlags
					-- Check both the skill mods for flags and flags that are set via calcPerform
					return skillFlags[varData.ifFlag] or skillModList:Flag(nil, varData.ifFlag)
				end
				control.tooltipText = varData.tooltip
			elseif varData.ifMod then
				control.shown = function()
					local skillModList = self.build.calcsTab.mainEnv.player.mainSkill.skillModList
					return skillModList:Sum(varData.ifModType or "BASE", nil, varData.ifMod) > 0
				end
				control.tooltipText = varData.tooltip
			elseif varData.ifSkill or varData.ifSkillList then
				control.shown = function()
					if varData.ifSkillList then
						for _, skillName in ipairs(varData.ifSkillList) do
							if self.build.calcsTab.mainEnv.skillsUsed[skillName] then
								return true
							end
						end
					else
						return self.build.calcsTab.mainEnv.skillsUsed[varData.ifSkill]
					end
				end
				control.tooltipText = varData.tooltip
			elseif varData.ifSkillFlag or varData.ifSkillFlagList then
				control.shown = function()
					if varData.ifSkillFlagList then
						for _, skillFlag in ipairs(varData.ifSkillFlagList) do
							for _, activeSkill in ipairs(self.build.calcsTab.mainEnv.player.activeSkillList) do
								if activeSkill.skillFlags[skillFlag] then
									return true
								end
							end
						end
					else
						-- print(ipairs(self.build.calcsTab.mainEnv.skillsUsed))
						for _, activeSkill in ipairs(self.build.calcsTab.mainEnv.player.activeSkillList) do
							if activeSkill.skillFlags[varData.ifSkillFlag] then
								return true
							end
						end
					end
					return false
				end
				control.tooltipText = varData.tooltip
			else
				control.tooltipText = varData.tooltip
			end
			if varData.tooltipFunc then
				control.tooltipFunc = varData.tooltipFunc
			end
			if varData.label and varData.type ~= "check" then
				t_insert(self.controls, new("LabelControl", {"RIGHT",control,"LEFT"}, -4, 0, 0, DrawStringWidth(14, "VAR", varData.label) > 228 and 12 or 14, "^7"..varData.label))
			end
			if varData.var then
				self.input[varData.var] = varData.defaultState
				control.state = varData.defaultState
				self.varControls[varData.var] = control
				self.placeholder[varData.var] = varData.defaultPlaceholderState
				control.placeholder = varData.defaultPlaceholderState
				if varData.defaultIndex then
					self.input[varData.var] = varData.list[varData.defaultIndex].val
					control.selIndex = varData.defaultIndex
				end
			end

			if not varData.hideIfInvalid then
				local innerShown = control.shown
				control.shown = function()
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					return not shown and control.state ~= self:GetDefaultState(varData.var, type(control.state)) or shown
				end
				local innerLabel = control.label
				control.label = function()
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					if not shown and control.state ~= self:GetDefaultState(varData.var, type(control.state)) then
						return "^1"..innerLabel
					end
					return innerLabel
				end
				local innerTooltipFunc = control.tooltipFunc
				control.tooltipFunc = function (tooltip, ...)
					tooltip:Clear()

					if innerTooltipFunc then
						innerTooltipFunc(tooltip, ...)
					else
						local tooltipText = control:GetProperty("tooltipText")
						if tooltipText then
							tooltip:AddLine(14, tooltipText)
						end
					end

					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					if not shown and control.state ~= self:GetDefaultState(varData.var, type(control.state)) then
						tooltip:AddLine(14, "^1This config option is conditional with missing source and is invalid.")
					end
				end
			end

			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end
	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, 0, 0, 18, 0, 50, "VERTICAL", true)
end)

function ConfigTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "Input" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				self.input[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				if node.attrib.name == "enemyIsBoss" then
					self.input[node.attrib.name] = node.attrib.string:lower():gsub("(%l)(%w*)", function(a,b) return s_upper(a)..b end)
					:gsub("Uber Atziri", "Boss"):gsub("Shaper", "Pinnacle"):gsub("Sirus", "Pinnacle")
				else
					self.input[node.attrib.name] = node.attrib.string
				end
			elseif node.attrib.boolean then
				self.input[node.attrib.name] = node.attrib.boolean == "true"
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing number, string or boolean attribute", fileName)
				return true
			end
		elseif node.elem == "Placeholder" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Placeholder' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				self.placeholder[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				self.input[node.attrib.name] = node.attrib.string
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Placeholder' element missing number", fileName)
				return true
			end
		end
	end
	self:BuildModList()
	self:UpdateControls()
	self:ResetUndo()
end

function ConfigTabClass:GetDefaultState(var, varType)
	if self.placeholder[var] ~= nil then
		return self.placeholder[var]
	end

	for i = 1, #varList do
		if varList[i].var == var then
			if varType == "number" then
				return varList[i].defaultState or 0
			elseif varType == "boolean" then
				return varList[i].defaultState == true
			else
				return varList[i].defaultState
			end
		end
	end
	if varType == "number" then
		return 0
	elseif varType == "boolean" then
		return false
	else
		return nil
	end
end

function ConfigTabClass:Save(xml)
	for k, v in pairs(self.input) do
		if v ~= self:GetDefaultState(k, type(v)) then
			local child = { elem = "Input", attrib = { name = k } }
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
	for k, v in pairs(self.placeholder) do
		local child = { elem = "Placeholder", attrib = { name = k } }
		if type(v) == "number" then
			child.attrib.number = tostring(v)
		else
			child.attrib.string = tostring(v)
		end
		t_insert(xml, child)
	end
end

function ConfigTabClass:UpdateControls()
	for var, control in pairs(self.varControls) do
		if control._className == "EditControl" then
			control:SetText(tostring(self.input[var] or ""))
			if self.placeholder[var] then
				control:SetPlaceholder(tostring(self.placeholder[var]))
			end
		elseif control._className == "CheckBoxControl" then
			control.state = self.input[var]
		elseif control._className == "DropDownControl" then
			control:SelByValue(self.input[var], "val")
		end
	end
end

function ConfigTabClass:Draw(viewPort, inputEvents)
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

	local maxCol = m_floor((viewPort.width - 10) / 370)
	local maxColY = 0
	local colY = { }
	for _, section in ipairs(self.sectionList) do
		local y = 14
		section.shown = true
		local doShow = false
		for _, varControl in ipairs(section.varControlList) do
			if varControl:IsShown() then
				doShow = true
				local width, height = varControl:GetSize()
				height = m_max(height, 16)
				varControl.y = y + 2
				y = y + height + 4
			end
		end
		section.shown = doShow
		if doShow then
			local width, height = section:GetSize()
			local col
			if section.col and (colY[section.col] or 0) + height + 28 <= viewPort.height and 10 + section.col * 370 <= viewPort.width then
				col = section.col
			else
				col = 1
				for c = 2, maxCol do
					colY[c] = colY[c] or 0
					if colY[c] < colY[col] then
						col = c
					end
				end
			end
			colY[col] = colY[col] or 0
			section.x = 10 + (col - 1) * 370
			section.y = colY[col] + 18
			colY[col] = colY[col] + height + 18
			maxColY = m_max(maxColY, colY[col])
		end
	end

	self.controls.scrollBar.height = viewPort.height
	self.controls.scrollBar:SetContentDimension(maxColY + 10, viewPort.height)
	for _, section in ipairs(self.sectionList) do
		section.y = section.y - self.controls.scrollBar.offset
	end

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ConfigTabClass:UpdateLevel()
	local input = self.input
	local placeholder = self.placeholder
	if input.enemyLevel and input.enemyLevel > 0 then
		self.enemyLevel = m_min(data.misc.MaxEnemyLevel, input.enemyLevel)
	elseif placeholder.enemyLevel and placeholder.enemyLevel > 0 then
		self.enemyLevel = m_min(data.misc.MaxEnemyLevel, placeholder.enemyLevel)
	else
		self.enemyLevel = m_min(data.misc.MaxEnemyLevel, self.build.characterLevel)
	end
end

function ConfigTabClass:BuildModList()
	local modList = new("ModList")
	self.modList = modList
	local enemyModList = new("ModList")
	self.enemyModList = enemyModList
	local input = self.input
	local placeholder = self.placeholder
	self:UpdateLevel() -- enemy level handled here because it's needed to correctly set boss stats
	for _, varData in ipairs(varList) do
		if varData.apply then
			if varData.type == "check" then
				if input[varData.var] then
					varData.apply(true, modList, enemyModList, self.build)
				end
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" then
				if input[varData.var] and (input[varData.var] ~= 0 or varData.type == "countAllowZero") then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				elseif placeholder[varData.var] and (placeholder[varData.var] ~= 0 or varData.type == "countAllowZero") then
					varData.apply(placeholder[varData.var], modList, enemyModList, self.build)
				end
			elseif varData.type == "list" then
				if input[varData.var] then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				end
			elseif varData.type == "text" then
				if input[varData.var] then
					varData.apply(input[varData.var], modList, enemyModList, self.build)
				end
			end
		end
	end
end

function ConfigTabClass:ImportCalcSettings()
	local input = self.input
	local calcsInput = self.build.calcsTab.input
	local function import(old, new)
		input[new] = calcsInput[old]
		calcsInput[old] = nil
	end
	import("Cond_LowLife", "conditionLowLife")
	import("Cond_FullLife", "conditionFullLife")
	import("Cond_LowMana", "conditionLowMana")
	import("Cond_FullMana", "conditionFullMana")
	import("buff_power", "usePowerCharges")
	import("buff_frenzy", "useFrenzyCharges")
	import("buff_endurance", "useEnduranceCharges")
	import("CondBuff_Onslaught", "buffOnslaught")
	import("CondBuff_Phasing", "buffPhasing")
	import("CondBuff_Fortify", "buffFortify")
	import("CondBuff_UsingFlask", "conditionUsingFlask")
	import("buff_pendulum", "usePendulum")
	import("CondEff_EnemyCursed", "conditionEnemyCursed")
	import("CondEff_EnemyBleeding", "conditionEnemyBleeding")
	import("CondEff_EnemyPoisoned", "conditionEnemyPoisoned")
	import("CondEff_EnemyBurning", "conditionEnemyBurning")
	import("CondEff_EnemyIgnited", "conditionEnemyIgnited")
	import("CondEff_EnemyChilled", "conditionEnemyChilled")
	import("CondEff_EnemyFrozen", "conditionEnemyFrozen")
	import("CondEff_EnemyShocked", "conditionEnemyShocked")
	import("effective_physicalRed", "enemyPhysicalReduction")
	import("effective_fireResist", "enemyFireResist")
	import("effective_coldResist", "enemyColdResist")
	import("effective_lightningResist", "enemyLightningResist")
	import("effective_chaosResist", "enemyChaosResist")
	import("effective_enemyIsBoss", "enemyIsBoss")
	self:BuildModList()
	self:UpdateControls()
end

function ConfigTabClass:CreateUndoState()
	return copyTable(self.input)
end

function ConfigTabClass:RestoreUndoState(state)
	wipeTable(self.input)
	for k, v in pairs(state) do
		self.input[k] = v
	end
	self:UpdateControls()
	self:BuildModList()
end
