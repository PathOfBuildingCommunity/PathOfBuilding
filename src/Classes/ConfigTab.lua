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
	self.defaultState = { }

	-- Initialise config sets
	self.configSets = { }
	self.configSetOrderList = { 1 }
	self:NewConfigSet(1)
	self:SetActiveConfigSet(1, true)
	
	self.enemyLevel = 1

	self.sectionList = { }
	self.varControls = { }
	
	self.toggleConfigs = false

	self.controls.sectionAnchor = new("LabelControl", { "TOPLEFT", self, "TOPLEFT" }, { 0, 20, 0, 0 }, "")

	-- Set selector
	self.controls.setSelect = new("DropDownControl", { "TOPLEFT", self.controls.sectionAnchor, "TOPLEFT" }, { 76, -12, 210, 20 }, nil, function(index, value)
		self:SetActiveConfigSet(self.configSetOrderList[index])
		self:AddUndoState()
	end)
	self.controls.setSelect.enableDroppedWidth = true
	self.controls.setSelect.enabled = function()
		return #self.configSetOrderList > 1
	end
	self.controls.setLabel = new("LabelControl", { "RIGHT", self.controls.setSelect, "LEFT" }, { -2, 0, 0, 16 }, "^7Config set:")
	self.controls.setManage = new("ButtonControl", { "LEFT", self.controls.setSelect, "RIGHT" }, { 4, 0, 90, 20 }, "Manage...", function()
		self:OpenConfigSetManagePopup()
	end)

	self.controls.search = new("EditControl", { "TOPLEFT", self.controls.sectionAnchor, "TOPLEFT" }, { 8, 15, 360, 20 }, "", "Search", "%c", 100, function()
		self:UpdateControls()
	end, nil, nil, true)
	self.controls.toggleConfigs = new("ButtonControl", { "LEFT", self.controls.search, "RIGHT" }, { 10, 0, 200, 20 }, function()
		-- dynamic text
		return self.toggleConfigs and "Hide Ineligible Configurations" or "Show All Configurations"
	end, function()
		self.toggleConfigs = not self.toggleConfigs
	end)

	local function searchMatch(varData)
		local searchStr = self.controls.search.buf:lower():gsub("[%-%.%+%[%]%$%^%%%?%*]", "%%%0")
		if searchStr and searchStr:match("%S") then
			local err, match = PCall(string.matchOrPattern, (varData.label or ""):lower(), searchStr)
			if not err and match then
				return true
			end
			return false
		end
		return true
	end

	-- blacklist for Show All Configurations
	local function isShowAllConfig(varData)
		local labelMatch = varData.label:lower()
		local excludeKeywords = { "recently", "in the last", "in the past", "in last", "in past", "pvp" }

		if not self.toggleConfigs then
			return false
		end
		if varData.ifOption or varData.ifSkill or varData.ifSkillData or varData.ifSkillFlag or varData.legacy then
			return false
		end
		for _, keyword in pairs(excludeKeywords) do
			if labelMatch:find(keyword) then
				return false
			end
		end
		return true
	end

	local function implyCond(varData)
		local mainEnv = self.build.calcsTab.mainEnv
		if self.configSets[self.activeConfigSetId].input[varData.var] then
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

		return false
	end

	local function listOrSingleIfOption(ifOption, ifFunc)
		return function()
			if type(ifOption) == "table" then
				for _, ifOpt in ipairs(ifOption) do
					if ifFunc(ifOpt) then
						return true
					end
				end
			end
			return ifFunc(ifOption)
		end
	end

	local function listOrSingleIfTooltip(ifOption, ifFunc)
		return function()
			if type(ifOption) == "table" then
				local out
				for _, ifOpt in ipairs(ifOption) do
					local curTooltipText = ifFunc(ifOpt)
					if curTooltipText then
						out = (out and out .. "\n" or "").. curTooltipText
					end
				end
				return out
			end
			return ifFunc(ifOption)
		end
	end

	local lastSection
	for _, varData in ipairs(varList) do
		if varData.section then
			lastSection = new("SectionControl", {"TOPLEFT",self.controls.search,"BOTTOMLEFT"}, {0, 0, 360, 0}, varData.section)
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
				control = new("CheckBoxControl", {"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 18}, varData.label, function(state)
					self.configSets[self.activeConfigSetId].input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
				control = new("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 90, 18}, "", nil, (varData.type == "integer" and "^%-%d") or (varData.type == "float" and "^%d.") or "%D", 7, function(buf, placeholder)
					if placeholder then
						self.configSets[self.activeConfigSetId].placeholder[varData.var] = tonumber(buf)
					else
						self.configSets[self.activeConfigSetId].input[varData.var] = tonumber(buf)
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end)
			elseif varData.type == "list" then
				control = new("DropDownControl", {"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 118, 16}, varData.list, function(index, value)
					self.configSets[self.activeConfigSetId].input[varData.var] = value.val
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "text" and not varData.resizable then
				control = new("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, {8, 0, 344, 118}, "", nil, "^%C\t\n", nil, function(buf, placeholder)
					if placeholder then
						self.configSets[self.activeConfigSetId].placeholder[varData.var] = tostring(buf)
					else
						self.configSets[self.activeConfigSetId].input[varData.var] = tostring(buf)
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end, 16)
			elseif varData.type == "text" and varData.resizable then
				control = new("ResizableEditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, {8, 0, 344, 118, nil, nil, nil, 118 + 16 * 40}, "", nil, "^%C\t\n", nil, function(buf, placeholder)
					if placeholder then
						self.configSets[self.activeConfigSetId].placeholder[varData.var] = tostring(buf)
					else
						self.configSets[self.activeConfigSetId].input[varData.var] = tostring(buf)
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end, 16)
			else
				control = new("Control", {"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 16, 16})
			end

			if varData.inactiveText then
				control.inactiveText = varData.inactiveText
			end

			local shownFuncs = {}
			control.shown = function()
				if not searchMatch(varData) then
					return false
				end

				for _, shownFunc in ipairs(shownFuncs) do
					if not shownFunc() and not isShowAllConfig(varData) then
						return false
					end
				end
				return true
			end

			local tooltipFuncs = {}
			control.tooltipText = function()
				local out
				for i, tooltipFunc in ipairs(tooltipFuncs) do
					local curTooltipText = type(tooltipFunc) == "string" and tooltipFunc or tooltipFunc(self.modList, self.build)
					if curTooltipText then
						out = (out and out .. "\n" or "") .. curTooltipText
					end
				end
				return out
			end

			if varData.tooltip then
				t_insert(tooltipFuncs, varData.tooltip)
			end

			if varData.ifNode then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifNode, function(ifOption)
					if self.build.spec.allocNodes[ifOption] then
						return true
					end
					local node = self.build.spec.nodes[ifOption]
					if node and node.type == "Keystone" then
						return self.build.calcsTab.mainEnv.keystonesAdded[node.dn]
					end
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifNode, function(ifOption)
					return "This option is specific to '"..self.build.spec.nodes[ifOption].dn.."'."
				end))
			end
			if varData.ifOption then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifOption, function(ifOption)
					return self.configSets[self.activeConfigSetId].input[ifOption]
				end))
			end
			if varData.ifCond then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifCond, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.conditionsUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifCond, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.conditionsUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifMinionCond then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifMinionCond, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.minionConditionsUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifMinionCond, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.minionConditionsUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifEnemyCond then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifEnemyCond, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.enemyConditionsUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifEnemyCond, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.enemyConditionsUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifMult then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifMult, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.multipliersUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifMult, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.multipliersUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifEnemyMult then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifEnemyMult, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.enemyMultipliersUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifEnemyMult, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.enemyMultipliersUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifStat then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifStat, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.perStatsUsed[ifOption] or self.build.calcsTab.mainEnv.enemyMultipliersUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifStat, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.perStatsUsed[ifOption]
					if mods then
						for _, mod in ipairs(mods) do
							out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
						end
					end
					local mods2 = self.build.calcsTab.mainEnv.enemyMultipliersUsed[ifOption]
					if mods2 then
						for _, mod in ipairs(mods2) do
							out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
						end
					end
					return out
				end))
			end
			if varData.ifEnemyStat then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifEnemyStat, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.enemyPerStatsUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifEnemyStat, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.enemyPerStatsUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifTagType then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifTagType, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.tagTypesUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifTagType, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.tagTypesUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifFlag then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifFlag, function(ifOption)
					local skillModList = self.build.calcsTab.mainEnv.player.mainSkill.skillModList
					local skillFlags = self.build.calcsTab.mainEnv.player.mainSkill.skillFlags
					-- Check both the skill mods for flags and flags that are set via calcPerform
					return skillFlags[ifOption] or skillModList:Flag(nil, ifOption)
				end))
			end
			if varData.ifMod then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifMod, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return self.build.calcsTab.mainEnv.modsUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifMod, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out
					local mods = self.build.calcsTab.mainEnv.modsUsed[ifOption]
					if not mods then
						return out
					end
					for _, mod in ipairs(mods) do
						out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
					end
					return out
				end))
			end
			if varData.ifSkill then
				if varData.includeTransfigured then
					t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkill, function(ifOption)
						if not calcLib.getGameIdFromGemName(ifOption, true) then
							return false
						end
						for skill,_ in pairs(self.build.calcsTab.mainEnv.skillsUsed) do
							if calcLib.isGemIdSame(skill, ifOption, true) then
								return true
							end
						end
						return false
					end))
				else
					t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkill, function(ifOption)
						return self.build.calcsTab.mainEnv.skillsUsed[ifOption]
					end))
				end
			end
			if varData.ifSkillFlag then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkillFlag, function(ifOption)
					for _, activeSkill in ipairs(self.build.calcsTab.mainEnv.player.activeSkillList) do
						if activeSkill.skillFlags[ifOption] then
							return true
						end
					end
					return false
				end))
			end
			if varData.ifSkillData then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkillData, function(ifOption)
					for _, activeSkill in ipairs(self.build.calcsTab.mainEnv.player.activeSkillList) do
						if activeSkill.skillData[ifOption] then
							return true
						end
					end
					return false
				end))
			end

			if varData.tooltipFunc then
				control.tooltipFunc = varData.tooltipFunc
			end
			local labelControl = control
			if varData.label and varData.type ~= "check" then
				labelControl = new("LabelControl", {"RIGHT",control,"LEFT"}, {-4, 0, 0, DrawStringWidth(14, "VAR", varData.label) > 228 and 12 or 14}, "^7"..varData.label)
				t_insert(self.controls, labelControl)
			end
			if varData.var then
				self.configSets[self.activeConfigSetId].input[varData.var] = varData.defaultState
				control.state = varData.defaultState
				self.varControls[varData.var] = control
				self.configSets[self.activeConfigSetId].placeholder[varData.var] = varData.defaultPlaceholderState
				control.placeholder = varData.defaultPlaceholderState
				if varData.defaultIndex then
					self.configSets[self.activeConfigSetId].input[varData.var] = varData.list[varData.defaultIndex].val
					control.selIndex = varData.defaultIndex
				end
				if varData.type == "check" then
					self.defaultState[varData.var] = varData.defaultState or false
				elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
					self.defaultState[varData.var] = varData.defaultState or 0
				elseif varData.type == "list" then
					self.defaultState[varData.var] = varData.list[varData.defaultIndex or 1].val
				elseif varData.type == "text" then
					self.defaultState[varData.var] = varData.defaultState or ""
				else
					self.defaultState[varData.var] = varData.defaultState
				end
			end

			local innerShown = control.shown
			if not varData.doNotHighlight then
				control.borderFunc = function()
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local cur = self.configSets[self.activeConfigSetId].input[varData.var]
					local def = self:GetDefaultState(varData.var, type(cur))
					if cur ~= nil and cur ~= def then
						if not shown then
							return 	0.753, 0.502, 0.502
						end
						return 	0.451, 0.576, 0.702
					end
					return 0.5, 0.5, 0.5
				end
			end

			if not varData.hideIfInvalid then
				control.shown = function()
					if not searchMatch(varData) then
						return false
					end
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local cur = self.configSets[self.activeConfigSetId].input[varData.var]
					local def = self:GetDefaultState(varData.var, type(cur))
					return not shown and cur ~= nil and cur ~= def or shown
				end
				local innerLabel = labelControl.label
				labelControl.label = function()
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local cur = self.configSets[self.activeConfigSetId].input[varData.var]
					local def = self:GetDefaultState(varData.var, type(cur))
					if not shown and cur ~= nil and cur ~= def then
						return colorCodes.NEGATIVE..StripEscapes(innerLabel)
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
						if tooltipText and tooltipText ~= '' then
							tooltip:AddLine(14, tooltipText)
						end
					end

					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local cur = self.configSets[self.activeConfigSetId].input[varData.var]
					local def = self:GetDefaultState(varData.var, type(cur))
					if not shown and cur ~= nil and cur ~= def then
						tooltip:AddLine(14, colorCodes.NEGATIVE.."This config option is conditional with missing source and is invalid.")
					end
				end
			end

			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end
	self.controls.scrollBar = new("ScrollBarControl", {"TOPRIGHT",self,"TOPRIGHT"}, {0, 0, 18, 0}, 50, "VERTICAL", true)
end)

function ConfigTabClass:Load(xml, fileName)
	self.activeConfigSetId = 1
	self.configSets = { }
	self.configSetOrderList = { 1 }

	local function setInputAndPlaceholder(node, configSetId)
		if node.elem == "Input" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				self.configSets[configSetId].input[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				if node.attrib.name == "enemyIsBoss" then
					self.configSets[configSetId].input[node.attrib.name] = node.attrib.string:lower():gsub("(%l)(%w*)", function(a,b) return s_upper(a)..b end)
					:gsub("Uber Atziri", "Boss"):gsub("Shaper", "Pinnacle"):gsub("Sirus", "Pinnacle")
				-- backwards compat <=3.20, Uber Atziri Flameblast -> Atziri Flameblast
				elseif node.attrib.name == "presetBossSkills" then
					self.configSets[configSetId].input[node.attrib.name] = node.attrib.string:gsub("^Uber ", "")
				else
					self.configSets[configSetId].input[node.attrib.name] = node.attrib.string
				end
			elseif node.attrib.boolean then
				self.configSets[configSetId].input[node.attrib.name] = node.attrib.boolean == "true"
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
				self.configSets[configSetId].placeholder[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				self.configSets[configSetId].input[node.attrib.name] = node.attrib.string
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Placeholder' element missing number", fileName)
				return true
			end
		end
	end

	-- Catch special case of empty Config
	if xml.empty then
		self:NewConfigSet(1, "Default")
	end
	for index, node in ipairs(xml) do
		if node.elem ~= "ConfigSet" then
			if not self.configSets[1] then
				self:NewConfigSet(1, "Default")
			end
			setInputAndPlaceholder(node, 1)
		else
			local configSetId = tonumber(node.attrib.id)
			self:NewConfigSet(configSetId, node.attrib.title or "Default")
			self.configSetOrderList[index] = configSetId
			for _, child in ipairs(node) do
				setInputAndPlaceholder(child, configSetId)
			end
		end
	end

	self:SetActiveConfigSet(tonumber(xml.attrib.activeConfigSet) or 1)
	self:ResetUndo()
end

function ConfigTabClass:GetDefaultState(var, varType)
	if self.configSets[self.activeConfigSetId].placeholder[var] ~= nil then
		return self.configSets[self.activeConfigSetId].placeholder[var]
	end

	if self.defaultState[var] ~= nil then
		return self.defaultState[var]
	end

	if varType == "number" then
		return 0
	elseif varType == "boolean" then
		return false
	elseif varType == "string" then
		return ""
	else
		return nil
	end
end

function ConfigTabClass:Save(xml)
	xml.attrib = {
		activeConfigSet = tostring(self.activeConfigSetId)
	}
	for _, configSetId in ipairs(self.configSetOrderList) do
		local configSet = self.configSets[configSetId]
		local child = { elem = "ConfigSet", attrib = { id = tostring(configSetId), title = configSet.title } }
		t_insert(xml, child)

		for k, v in pairs(configSet.input) do
			if v ~= self:GetDefaultState(k, type(v)) then
				local node = { elem = "Input", attrib = { name = k } }
				if type(v) == "number" then
					node.attrib.number = tostring(v)
				elseif type(v) == "boolean" then
					node.attrib.boolean = tostring(v)
				else
					node.attrib.string = tostring(v)
				end
				t_insert(child, node)
			end
		end
		for k, v in pairs(configSet.placeholder) do
			local node = { elem = "Placeholder", attrib = { name = k } }
			if type(v) == "number" then
				node.attrib.number = tostring(v)
			else
				node.attrib.string = tostring(v)
			end
			t_insert(child, node)
		end
	end
end

function ConfigTabClass:UpdateControls()
	for var, control in pairs(self.varControls) do
		if control._className == "EditControl" or control._className == "ResizableEditControl" then
			control:SetText(tostring(self.configSets[self.activeConfigSetId].input[var] or ""))
			if self.configSets[self.activeConfigSetId].placeholder[var] then
				control:SetPlaceholder(tostring(self.configSets[self.activeConfigSetId].placeholder[var]))
			end
		elseif control._className == "CheckBoxControl" then
			control.state = self.configSets[self.activeConfigSetId].input[var]
		elseif control._className == "DropDownControl" then
			control:SelByValue(self.configSets[self.activeConfigSetId].input[var] or self:GetDefaultState(var), "val")
		end
	end
end

function ConfigTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for _, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			elseif event.key == "f" and IsKeyDown("CTRL") then
				self:SelectControl(self.controls.search)
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

	local maxCol = m_floor((viewPort.width - 10) / 370)
	local maxColY = 0
	local colY = { 0 }
	for _, section in ipairs(self.sectionList) do
		local y = 14
		section.shown = true
		local doShow = false
		for _, varControl in pairs(section.varControlList) do
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
	
	local newSetList = { }
	for index, configSetId in ipairs(self.configSetOrderList) do
		local configSet = self.configSets[configSetId]
		t_insert(newSetList, configSet.title or "Default")
		if configSetId == self.activeConfigSetId then
			self.controls.setSelect.selIndex = index
		end
	end
	self.controls.setSelect:SetList(newSetList)

	self.controls.scrollBar.height = viewPort.height
	self.controls.scrollBar:SetContentDimension(maxColY + 58, viewPort.height)
	self.controls.sectionAnchor.y = 20 - self.controls.scrollBar.offset

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ConfigTabClass:UpdateLevel()
	local input = self.configSets[self.activeConfigSetId].input
	local placeholder = self.configSets[self.activeConfigSetId].placeholder
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
	local input = self.configSets[self.activeConfigSetId].input
	local placeholder = self.configSets[self.activeConfigSetId].placeholder
	self:UpdateLevel() -- enemy level handled here because it's needed to correctly set boss stats
	for _, varData in ipairs(varList) do
		if varData.apply then
			if varData.type == "check" then
				if input[varData.var] then
					varData.apply(true, modList, enemyModList, self.build)
				end
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
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
	local input = self.configSets[self.activeConfigSetId].input
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
	return copyTable(self.configSets[self.activeConfigSetId].input)
end

function ConfigTabClass:RestoreUndoState(state)
	wipeTable(self.configSets[self.activeConfigSetId].input)
	for k, v in pairs(state) do
		self.configSets[self.activeConfigSetId].input[k] = v
	end
	self:UpdateControls()
	self:BuildModList()
end

function ConfigTabClass:OpenConfigSetManagePopup()
	main:OpenPopup(370, 290, "Manage Config Sets", {
		new("ConfigSetListControl", nil, {0, 50, 350, 200}, self),
		new("ButtonControl", nil, {0, 260, 90, 20}, "Done", function()
			main:ClosePopup()
		end),
	})
end

-- Creates a new config set
function ConfigTabClass:NewConfigSet(configSetId, title)
	local configSet = { id = configSetId, title = title, input = { }, placeholder = { } }
	if not configSetId then
		configSet.id = 1
		while self.configSets[configSet.id] do
			configSet.id = configSet.id + 1
		end
	end
	-- there are default values for input and placeholder that every new config set needs to have
	for _, varData in ipairs(varList) do
		if varData.var then
			configSet.input[varData.var] = varData.defaultState
			configSet.placeholder[varData.var] = varData.defaultPlaceholderState
			if varData.defaultIndex then
				configSet.input[varData.var] = varData.list[varData.defaultIndex].val
			end
		end
	end
	self.configSets[configSet.id] = configSet
	return configSet
end

-- Changes the active config set
function ConfigTabClass:SetActiveConfigSet(configSetId, init)
	-- Initialize config sets if needed
	if not self.configSetOrderList[1] then
		self.configSetOrderList[1] = 1
		self:NewConfigSet(1)
	end

	if not configSetId then
		configSetId = self.activeConfigSetId
	end

	if not self.configSets[configSetId] then
		configSetId = self.configSetOrderList[1]
	end

	self.input = self.configSets[configSetId].input
	self.placeholder = self.configSets[configSetId].placeholder
	self.activeConfigSetId = configSetId

	if not init then
		self:UpdateControls()
		self:BuildModList()
	end
	self.build.buildFlag = true
	self.build:SyncLoadouts()
end
