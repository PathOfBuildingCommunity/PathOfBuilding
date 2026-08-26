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

local varList = require("Modules.ConfigOptions")
local configVisibility = require("Modules.ConfigVisibility")
local configModBrowser = require("Modules.ConfigModBrowser")

---@class CustomModBlockControl: ControlHost, Control
local CustomModBlockClass = newClass("CustomModBlockControl", "ControlHost", "Control")

---@param anchor Anchor?
---@param rect Rect?
---@param configTab ConfigTab
---@param blockIndex integer
---@param blockData any
function CustomModBlockClass:CustomModBlockControl(anchor, rect, configTab, blockIndex, blockData)
	self:Control(anchor, rect)
	self:ControlHost()

	self.configTab = configTab
	self.blockIndex = blockIndex
	self.blockData = blockData

	self.controls.deleteBtn = new("ButtonControl"):ButtonControl({"TOPLEFT", self, "TOPLEFT"}, {0, 0, 20, 18}, "^1X", function()
		local customModsList = configTab.configSets[configTab.activeConfigSetId].customModsList
		table.remove(customModsList, blockIndex)
		if #customModsList == 0 then
			table.insert(customModsList, { title = "Default", enabled = true, text = "" })
		end
		configTab:UpdateCustomModsControls()
		configTab:AddUndoState()
		configTab:BuildModList()
		configTab.build.buildFlag = true
	end)

	self.controls.titleEdit = new("EditControl"):EditControl({"LEFT", self.controls.deleteBtn, "RIGHT"}, {6, 0, 222, 18}, blockData.title or "", nil, nil, nil, function(buf)
		blockData.title = buf
		configTab:AddUndoState()
		configTab:BuildModList()
		configTab.build.buildFlag = true
	end)

	self.controls.addModBtn = new("ButtonControl"):ButtonControl({"LEFT", self.controls.titleEdit, "RIGHT"}, {6, 0, 58, 18}, "^7Add Mod", function()
		configModBrowser.OpenAddModPopup(self.configTab, blockData)
	end)

	self.controls.enableCheck = new("CheckBoxControl"):CheckBoxControl({"TOPRIGHT", self, "TOPRIGHT"}, {0, 0, 18}, "", function(state)
		blockData.enabled = state
		configTab:AddUndoState()
		configTab:BuildModList()
		configTab.build.buildFlag = true
	end)
	self.controls.enableCheck.state = blockData.enabled ~= false
	self.controls.enableCheck.tooltipFunc = function(tooltip)
		if tooltip:CheckForUpdate(configTab.build.outputRevision, blockData) then
			if configTab.build.calcsTab then
				local calcFunc, calcBase = configTab.build.calcsTab:GetMiscCalculator(configTab.build)
				if calcFunc then
					local curState = blockData.enabled ~= false
					blockData.enabled = not curState
					configTab:BuildModList()
					local output = calcFunc()
					blockData.enabled = curState
					configTab:BuildModList()
					configTab.build:AddStatComparesToTooltip(tooltip, calcBase, output, curState and "^7Disabling this group will give you:" or "^7Enabling this group will give you:")
				end
			end
		end
	end

	self.controls.textEdit = new("ResizableEditControl"):ResizableEditControl({"TOPLEFT", self, "TOPLEFT"}, {0, 22, 344, 80, 344, 40, 344, 600}, blockData.text or "", nil, "^%C\t\n", nil, function(buf)
		blockData.text = buf
		configTab:AddUndoState()
		configTab:BuildModList()
		configTab.build.buildFlag = true
	end, 16)

	self.controls.textEdit.inactiveText = function(val)
		local inactiveText = ""
		for line in val:gmatch("([^\n]*)\n?") do
			local strippedLine = StripEscapes(line):match("^%s*(.-)%s*$")
			local mods, extra = modLib.parseMod(strippedLine)
			inactiveText = inactiveText .. ((mods and not extra) and colorCodes.MAGIC or colorCodes.UNSUPPORTED) .. (IsKeyDown("ALT") and strippedLine or line) .. "\n"
		end
		return inactiveText
	end
	return self
end

function CustomModBlockClass:GetSize()
	local textHeight = self.controls.textEdit and self.controls.textEdit.height or 80
	self.height = 22 + textHeight + 4
	return 344, self.height
end

function CustomModBlockClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function CustomModBlockClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key, doubleClick)
	end
end

function CustomModBlockClass:Draw(viewPort)
	if not self:IsShown() then
		return
	end
	self:GetSize()
	self:DrawControls(viewPort)
end

---@class ConfigTab: UndoHandler, ControlHost, Control
local ConfigTabClass = newClass("ConfigTab", "UndoHandler", "ControlHost", "Control")

---@param build Build
function ConfigTabClass:ConfigTab(build)
	self:UndoHandler()
	self:ControlHost()
	self:Control()

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

	-- A misc calculator function which is updated by the build when it is rebuilt
	---@type fun(): table
	self.calcFunc = nil
	-- A calculator base output matching the calcFunc which is updated by the build when it is rebuilt
	---@type table
	self.calcBase = nil
	self.controls.sectionAnchor = new("LabelControl"):LabelControl({ "TOPLEFT", self, "TOPLEFT" }, { 0, 20, 0, 0 }, "")

	-- Set selector
	self.controls.setSelect = new("DropDownControl"):DropDownControl({ "TOPLEFT", self.controls.sectionAnchor, "TOPLEFT" }, { 76, -12, 210, 20 }, nil, function(index, value)
		self:SetActiveConfigSet(self.configSetOrderList[index])
		self:AddUndoState()
	end)
	self.controls.setSelect.enableDroppedWidth = true
	self.controls.setSelect.enabled = function()
		return #self.configSetOrderList > 1
	end
	self.controls.setLabel = new("LabelControl"):LabelControl({ "RIGHT", self.controls.setSelect, "LEFT" }, { -2, 0, 0, 16 }, "^7Config set:")
	self.controls.setManage = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.setSelect, "RIGHT" }, { 4, 0, 90, 20 }, "Manage...", function()
		self:OpenConfigSetManagePopup()
	end)

	self.controls.search = new("EditControl"):EditControl({ "TOPLEFT", self.controls.sectionAnchor, "TOPLEFT" }, { 8, 15, 360, 20 }, "", "Search", "%c", 100, function()
		self:UpdateControls()
	end, nil, nil, true)
	self.controls.toggleConfigs = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.search, "RIGHT" }, { 10, 0, 200, 20 }, function()
		-- dynamic text
		return self.toggleConfigs and "Hide Ineligible Configurations" or "Show All Configurations"
	end, function()
		self.toggleConfigs = not self.toggleConfigs
	end)

	local function isCollapsed(section)
		return self:IsSectionCollapsed(section)
	end

	local function searchMatch(varData)
		local searchStr = self.controls.search.buf:lower():gsub("[%-%.%+%[%]%$%^%%%?%*]", "%%%0")
		if searchStr and searchStr:match("%S") then
			local label = StripEscapes(varData.label or ""):lower()
			local err, match = PCall(string.matchOrPattern, label, searchStr)
			if not err and match then
				return true
			end
			return false
		end
		return true
	end

	-- Override for Show All Configurations: when the toggle is on, show options that aren't on the shared exclusion list.
	local function isShowAllConfig(varData)
		return self.toggleConfigs and not configVisibility.isShowAllExcluded(varData)
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
			lastSection = new("SectionControl"):SectionControl({"TOPLEFT",self.controls.search,"BOTTOMLEFT"}, {0, 0, 360, 0}, varData.section)
			lastSection.varControlList = { }
			lastSection.col = varData.col
			lastSection.collapsed = false
			lastSection.height = function(section)
				if isCollapsed(section) then
					return 16
				end
				local height = 20
				for _, varControl in pairs(section.varControlList) do
					if varControl:IsShown() then
						local _, ctrlHeight = varControl:GetSize()
						height = height + m_max(ctrlHeight or varControl.height, 16) + 4
					end
				end
				return m_max(height, 32)
			end
			-- Collapse toggle, matching the Calcs tab: right aligned, '-' when expanded, '+' when collapsed.
			-- Sits on the section's top border, as the header label does, to clear the option controls below.
			local section = lastSection
			local toggle = new("ButtonControl"):ButtonControl({"TOPRIGHT",lastSection,"TOPRIGHT"}, {-6, -7, 16, 16}, function()
				return section.collapsed and "+" or "-"
			end, function()
				section.collapsed = not section.collapsed
			end)
			-- Deliberately not in varControlList: it must not count towards the section's height or visibility
			t_insert(self.sectionList, lastSection)
			t_insert(self.controls, lastSection)
			t_insert(self.controls, toggle)
			if varData.section == "Custom Modifiers" then
				self.customSection = lastSection
			end
		else
			local control
			if varData.type == "check" then
				control = new("CheckBoxControl"):CheckBoxControl({"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 18}, varData.label, function(state)
					self.configSets[self.activeConfigSetId].input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
				control = new("EditControl"):EditControl({"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 90, 18}, "", nil, ((varData.type == "integer" or varData.type == "countAllowZero") and "^%-%d") or (varData.type == "float" and "^%d.") or "%D", 10, function(buf, placeholder)
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
				control = new("DropDownControl"):DropDownControl({"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 118, 16}, varData.list, function(index, value)
					self.configSets[self.activeConfigSetId].input[varData.var] = value.val
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "text" and not varData.resizable then
				control = new("EditControl"):EditControl({"TOPLEFT",lastSection,"TOPLEFT"}, {8, 0, 344, 118}, "", nil, "^%C\t\n", nil, function(buf, placeholder)
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
				control = new("ResizableEditControl"):ResizableEditControl({"TOPLEFT",lastSection,"TOPLEFT"}, {8, 0, 344, 118, nil, nil, nil, 118 + 16 * 40}, "", nil, "^%C\t\n", nil, function(buf, placeholder)
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
				control = new("Control"):Control({"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 16, 16})
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
			if varData.ifCondTrue then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifCondTrue, function(ifOption)
					return self.build.calcsTab.mainEnv.player.modDB.conditions[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifCondTrue, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out = "Condition state: " .. ifOption .. "=" .. tostring(self.build.calcsTab.mainEnv.player.modDB.conditions[ifOption])
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
				labelControl = new("LabelControl"):LabelControl({"RIGHT",control,"LEFT"}, {-4, 0, 0, DrawStringWidth(14, "VAR", varData.label) > 228 and 12 or 14}, "^7"..varData.label)
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
				local outputCache = {}
				local outputCacheRevision = nil
				local innerTooltipFunc = control.tooltipFunc
				control.tooltipFunc = function(tooltip, mode, index, value)
					tooltip:Clear()

					if innerTooltipFunc then
						innerTooltipFunc(tooltip, mode, index, value)
					else
						local tooltipText = control:GetProperty("tooltipText")
						if tooltipText and tooltipText ~= '' then
							tooltip:AddLine(14, tooltipText)
						end
					end

					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local inputs = self.configSets[self.activeConfigSetId].input
					local cur = inputs[varData.var]
					local def = self:GetDefaultState(varData.var, type(cur))
					if not shown and cur ~= nil and cur ~= def then
						tooltip:AddLine(14, colorCodes.NEGATIVE.."This config option is conditional with missing source and is invalid.")
					else
						-- avoid adding comparisons for number inputs as the
						-- input gets applied as soon as the user types, which
						-- means comparisons don't make sense here
						if not self.calcFunc then
							self.calcFunc, self.calcBase = self.build.calcsTab:GetMiscCalculator(self.build)
						end
						if (varData.type == "check") or (varData.type == "list") then
							local valueMapped
							if varData.type == "check" then
								valueMapped = not cur
							else
								valueMapped = type(value) == "table" and value.val or value
							end
							if (valueMapped ~= cur) then
								local buildFlag = self.build.buildFlag
								tooltip:AddSeparator(10)
								-- clear cache if build has been edited
								if outputCacheRevision ~= self.build.outputRevision then
									outputCache = {}
									outputCacheRevision = self.build.outputRevision
								end
								local key = string.format("%s:%s", tostring(valueMapped), tostring(cur))
								if not outputCache[key] then
									inputs[varData.var] = valueMapped
									self:BuildModList()

									outputCache[key] = self.calcFunc()

									inputs[varData.var] = cur
									self:BuildModList()
								end
								-- building the mod lists flags the build for a
								-- rebuild, but we don't actually want that as
								-- we restore the previous state if the user
								-- hasn't actually clicked
								self.build.buildFlag = buildFlag
								local prefix = (varData.type == "check") and "^7Toggling this" or "^7Selecting this"
								self.build:AddStatComparesToTooltip(tooltip, self.calcBase, outputCache[key], prefix .. " option will give you:")
								-- clear tooltip if it only has our separator
								if #tooltip.lines == 1 then
									tooltip:Clear()
								end
							end
						end
					end
				end
			end

			local ownSection = lastSection
			local eligibleShown = control.shown
			control.shown = function()
				if isCollapsed(ownSection) then
					return false
				end
				return type(eligibleShown) == "boolean" and eligibleShown or eligibleShown()
			end

			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end
	self.controls.scrollBar = new("ScrollBarControl"):ScrollBarControl({"TOPRIGHT",self,"TOPRIGHT"}, {0, 0, 18, 0}, 50, "VERTICAL", true)
	if self.customSection then
		self.controls.customModsAddBlock = new("ButtonControl"):ButtonControl({"TOPLEFT", self.customSection, "TOPLEFT"}, {8, 0, 120, 20}, "^7Add Mod Group", function()
			local customModsList = self.configSets[self.activeConfigSetId].customModsList
			t_insert(customModsList, { title = "Group " .. (#customModsList + 1), enabled = true, text = "" })
			self:UpdateCustomModsControls()
			self:AddUndoState()
			self:BuildModList()
			self.build.buildFlag = true
		end)
		self.controls.customModsAddBlock.shown = function()
			return not isCollapsed(self.customSection)
		end
		self.customModsBlockControls = { }
		self:UpdateCustomModsControls()
	end

	return self
end

-- A collapsed section hides its contents, unless a search is active
function ConfigTabClass:IsSectionCollapsed(section)
	return section.collapsed and not self.controls.search.buf:match("%S")
end

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
			if node.elem == "CustomModifierBlock" then
				local block = {
					title = node.attrib.title or "Default",
					enabled = (node.attrib.enabled == "true" or node.attrib.enabled == nil),
					text = node[1] or ""
				}
				t_insert(self.configSets[1].customModsList, block)
			else
				setInputAndPlaceholder(node, 1)
			end
		else
			local configSetId = tonumber(node.attrib.id)
			self:NewConfigSet(configSetId, node.attrib.title or "Default")
			self.configSetOrderList[index] = configSetId
			self.configSets[configSetId].customModsList = { }
			for _, child in ipairs(node) do
				if child.elem == "CustomModifierBlock" then
					local block = {
						title = child.attrib.title or "Default",
						enabled = (child.attrib.enabled == "true" or child.attrib.enabled == nil),
						text = child[1] or ""
					}
					t_insert(self.configSets[configSetId].customModsList, block)
				else
					setInputAndPlaceholder(child, configSetId)
				end
			end
		end
	end

	-- Migration check for legacy builds
	for _, configSetId in ipairs(self.configSetOrderList) do
		local configSet = self.configSets[configSetId]
		local legacyText = configSet.input and configSet.input.customMods or ""
		if legacyText ~= "" and (not configSet.customModsList or #configSet.customModsList == 0 or (#configSet.customModsList == 1 and (configSet.customModsList[1].text or "") == "")) then
			configSet.customModsList = { { title = "Default", enabled = true, text = legacyText } }
		elseif not configSet.customModsList or #configSet.customModsList == 0 then
			configSet.customModsList = { { title = "Default", enabled = true, text = "" } }
		end
		if configSet.input then
			configSet.input.customMods = nil
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
		if configSet.customModsList then
			for _, block in ipairs(configSet.customModsList) do
				local blockNode = {
					elem = "CustomModifierBlock",
					attrib = {
						title = block.title or "Default",
						enabled = tostring(block.enabled ~= false)
					},
					[1] = block.text or ""
				}
				t_insert(child, blockNode)
			end
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
	self:UpdateCustomModsControls()
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
		-- Probe with the section expanded, so a collapsed section that still has
		-- eligible options keeps its (clickable) header on screen
		local collapsed = section.collapsed
		section.collapsed = false
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
		section.collapsed = collapsed
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
	local modList = new("ModList"):ModList()
	self.modList = modList
	local enemyModList = new("ModList"):ModList()
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

	-- Apply Custom Modifier groups
	local customModsList = self.configSets[self.activeConfigSetId].customModsList
	local hasBlockText = false
	if customModsList then
		for _, block in ipairs(customModsList) do
			if block.enabled ~= false and block.text and #block.text > 0 then
				hasBlockText = true
				for line in block.text:gmatch("([^\n]*)\n?") do
					local strippedLine = StripEscapes(line):match("^%s*(.-)%s*$")
					local mods, extra = modLib.parseMod(strippedLine)
					if mods and not extra then
						local source = "Custom:" .. (block.title or "Default")
						for i = 1, #mods do
							local mod = mods[i]
							if mod then
								mod = modLib.setSource(mod, source)
								modList:AddMod(mod)
							end
						end
					end
				end
			end
		end
	end
	-- Fallback for tests/headless
	if not hasBlockText and input.customMods and #input.customMods > 0 then
		for line in input.customMods:gmatch("([^\n]*)\n?") do
			local strippedLine = StripEscapes(line):match("^%s*(.-)%s*$")
			local mods, extra = modLib.parseMod(strippedLine)
			if mods and not extra then
				local source = "Custom"
				for i = 1, #mods do
					local mod = mods[i]
					if mod then
						mod = modLib.setSource(mod, source)
						modList:AddMod(mod)
					end
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
	local configSet = self.configSets[self.activeConfigSetId]
	return {
		input = copyTable(configSet.input),
		customModsList = copyTable(configSet.customModsList)
	}
end

function ConfigTabClass:RestoreUndoState(state)
	local configSet = self.configSets[self.activeConfigSetId]
	if type(state) == "table" and state.input then
		wipeTable(configSet.input)
		for k, v in pairs(state.input) do
			configSet.input[k] = v
		end
		if state.customModsList then
			configSet.customModsList = copyTable(state.customModsList)
		end
	else
		wipeTable(configSet.input)
		for k, v in pairs(state) do
			configSet.input[k] = v
		end
	end
	self:UpdateControls()
	self:BuildModList()
end

function ConfigTabClass:OpenConfigSetManagePopup()
	main:OpenPopup(370, 290, "Manage Config Sets", {
		new("ConfigSetListControl"):ConfigSetListControl(nil, {0, 50, 350, 200}, self),
		new("ButtonControl"):ButtonControl(nil, {0, 260, 90, 20}, "Done", function()
			main:ClosePopup()
		end),
	})
end

-- Creates a new config set
function ConfigTabClass:NewConfigSet(configSetId, title)
	local configSet = { id = configSetId, title = title, input = { }, placeholder = { }, customModsList = { { title = "Default", enabled = true, text = "" } } }
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

function ConfigTabClass:UpdateCustomModsControls()
	if not self.customSection then
		return
	end
	local configSet = self.configSets[self.activeConfigSetId]
	if not configSet then
		return
	end
	if not configSet.customModsList then
		configSet.customModsList = { }
	end
	if #configSet.customModsList == 0 then
		t_insert(configSet.customModsList, { title = "Default", enabled = true, text = configSet.input and configSet.input.customMods or "" })
	end

	if self.customModsBlockControls then
		for _, ctrl in ipairs(self.customModsBlockControls) do
			ctrl.shown = false
		end
	end
	self.customModsBlockControls = { }
	self.customSection.varControlList = { self.controls.customModsAddBlock }

	for index, block in ipairs(configSet.customModsList) do
		local blockControl = new("CustomModBlockControl"):CustomModBlockControl({"TOPLEFT", self.customSection, "TOPLEFT"}, {8, 0, 344, 120}, self, index, block)
		blockControl.shown = function()
			return not self:IsSectionCollapsed(self.customSection)
		end
		t_insert(self.customModsBlockControls, blockControl)
		t_insert(self.controls, blockControl)
		t_insert(self.customSection.varControlList, blockControl)
	end
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
