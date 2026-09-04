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
local ConfigScope = require("Modules.ConfigScope")
local MercenaryTools = require("Modules.MercenaryTools")
ConfigScope.index(varList)

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
		local customModsList = configTab:GetActorCustomModsList()
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
				local calcFunc, calcBase, actor = configTab:GetComparisonCalculator()
				if calcFunc then
					local curState = blockData.enabled ~= false
					blockData.enabled = not curState
					configTab:BuildModList()
					local output = configTab:RunComparisonCalc(calcFunc, actor)
					blockData.enabled = curState
					configTab:BuildModList()
					configTab.build:AddStatComparesToTooltip(tooltip, calcBase, output, curState and "^7Disabling this group will give you:" or "^7Enabling this group will give you:", nil, actor)
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
	-- ItemsTab and MercenaryTab are created after ConfigTab, so copying "live"
	-- item sets here would read the previous build's tabs during newBuild().
	self:NewConfigSet(1, nil, { copyLiveItemSets = false })
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
	self.calcActorOutputs = nil
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

	self.viewActor = "player"
	self.controls.actorLabel = new("LabelControl"):LabelControl({ "TOPLEFT", self.controls.sectionAnchor, "TOPLEFT" }, { 0, 14, 0, 16 }, "^7Actor:")
	self.controls.actorSelect = new("DropDownControl"):DropDownControl({ "LEFT", self.controls.actorLabel, "RIGHT" }, { 4, 0, 140, 20 }, {
		{ id = "player", label = "Player" },
		{ id = "mercenary", label = "Mercenary" },
	}, function(_, value)
		if value then
			self:SetViewActor(value.id)
		end
	end)
	self.controls.itemSetLabel = new("LabelControl"):LabelControl({ "LEFT", self.controls.actorSelect, "RIGHT" }, { 12, 0, 0, 16 }, "^7Equipped item set:")
	self.controls.itemSetSelect = new("DropDownControl"):DropDownControl({ "LEFT", self.controls.itemSetLabel, "RIGHT" }, { 4, 0, 210, 20 }, { }, function(_, value)
		if not value or not value.id then
			return
		end
		if self:GetViewActor() == "mercenary" and self.build.mercenaryTab then
			-- Equip without taking the Items tab's view/comparison context.
			self.build.mercenaryTab:SetItemSet(value.id, false)
		elseif self.build.itemsTab then
			self.build.itemsTab:SetActiveItemSet(value.id, false)
			self.build.itemsTab:AddUndoState()
		end
		self:AddUndoState()
	end)
	self.controls.itemSetSelect.enableDroppedWidth = true
	self.controls.itemSetManage = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.itemSetSelect, "RIGHT" }, { 4, 0, 90, 20 }, "Manage...", function()
		if self.build.itemsTab then
			self.build.itemsTab:OpenItemSetManagePopup()
		end
	end)

	self.controls.search = new("EditControl"):EditControl({ "TOPLEFT", self.controls.sectionAnchor, "TOPLEFT" }, { 8, 42, 360, 20 }, "", "Search", "%c", 100, function()
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
		return configVisibility.implyCondActive(varData, self.build, self:GetViewActor())
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
					self:SetConfigValue(varData.var, state)
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
				control = new("EditControl"):EditControl({"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 90, 18}, "", nil, ((varData.type == "integer" or varData.type == "countAllowZero") and "^%-%d") or (varData.type == "float" and "^%d.") or "%D", 10, function(buf, placeholder)
					if placeholder then
						self:SetConfigPlaceholder(varData.var, tonumber(buf))
					else
						self:SetConfigValue(varData.var, tonumber(buf))
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end)
			elseif varData.type == "list" then
				control = new("DropDownControl"):DropDownControl({"TOPLEFT",lastSection,"TOPLEFT"}, {234, 0, 118, 16}, varData.list, function(index, value)
					self:SetConfigValue(varData.var, value.val)
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			elseif varData.type == "text" and not varData.resizable then
				control = new("EditControl"):EditControl({"TOPLEFT",lastSection,"TOPLEFT"}, {8, 0, 344, 118}, "", nil, "^%C\t\n", nil, function(buf, placeholder)
					if placeholder then
						self:SetConfigPlaceholder(varData.var, tostring(buf))
					else
						self:SetConfigValue(varData.var, tostring(buf))
						self:AddUndoState()
						self:BuildModList()
					end
					self.build.buildFlag = true
				end, 16)
			elseif varData.type == "text" and varData.resizable then
				control = new("ResizableEditControl"):ResizableEditControl({"TOPLEFT",lastSection,"TOPLEFT"}, {8, 0, 344, 118, nil, nil, nil, 118 + 16 * 40}, "", nil, "^%C\t\n", nil, function(buf, placeholder)
					if placeholder then
						self:SetConfigPlaceholder(varData.var, tostring(buf))
					else
						self:SetConfigValue(varData.var, tostring(buf))
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
				if ConfigScope.forVarData(varData) == "player" and self:GetViewActor() == "mercenary" then
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
					return self:GetConfigValue(ifOption)
				end))
			end
			if varData.ifCond then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifCond, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "conditionsUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifCond, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "conditionsUsed", varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifMinionCond then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifMinionCond, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "minionConditionsUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifMinionCond, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "minionConditionsUsed", varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifEnemyCond then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifEnemyCond, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "enemyConditionsUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifEnemyCond, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "enemyConditionsUsed", varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifCondTrue then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifCondTrue, function(ifOption)
					return configVisibility.anyPrimaryActor(self.build.calcsTab.mainEnv, function(actor)
						return actor.modDB.conditions[ifOption]
					end, configVisibility.actorKeysForVar(varData, self:GetViewActor()))
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifCondTrue, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatCondTrue(self.build.calcsTab.mainEnv, varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifMult then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifMult, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "multipliersUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifMult, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "multipliersUsed", varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifEnemyMult then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifEnemyMult, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "enemyMultipliersUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifEnemyMult, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "enemyMultipliersUsed", varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifStat then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifStat, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "perStatsUsed", varData, self:GetViewActor())[ifOption] or self.build.calcsTab.mainEnv.enemyMultipliersUsed[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifStat, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					local out = configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "perStatsUsed", varData, self:GetViewActor(), ifOption)
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
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "enemyPerStatsUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifEnemyStat, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "enemyPerStatsUsed", varData, self:GetViewActor(), ifOption)
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
					return configVisibility.anyMainSkill(self.build.calcsTab.mainEnv, function(mainSkill)
						-- Check both the skill mods for flags and flags that are set via calcPerform
						return mainSkill.skillFlags[ifOption] or mainSkill.skillModList:Flag(nil, ifOption)
					end, configVisibility.actorKeysForVar(varData, self:GetViewActor()))
				end))
			end
			if varData.ifMod then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifMod, function(ifOption)
					if implyCond(varData) then
						return true
					end
					return configVisibility.usedForVar(self.build.calcsTab.mainEnv, "modsUsed", varData, self:GetViewActor())[ifOption]
				end))
				t_insert(tooltipFuncs, listOrSingleIfTooltip(varData.ifMod, function(ifOption)
					if not launch.devModeAlt then
						return
					end
					return configVisibility.formatUsedMods(self.build.calcsTab.mainEnv, "modsUsed", varData, self:GetViewActor(), ifOption)
				end))
			end
			if varData.ifSkill then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkill, function(ifOption)
					return configVisibility.anyPrimaryActor(self.build.calcsTab.mainEnv, function(actor)
						return configVisibility.actorUsesSkill(actor, ifOption, varData.includeTransfigured)
					end, configVisibility.actorKeysForVar(varData, self:GetViewActor()))
				end))
			end
			if varData.ifSkillFlag then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkillFlag, function(ifOption)
					return configVisibility.anyActiveSkill(self.build.calcsTab.mainEnv, function(activeSkill)
						return activeSkill.skillFlags[ifOption]
					end, configVisibility.actorKeysForVar(varData, self:GetViewActor()))
				end))
			end
			if varData.ifSkillData then
				t_insert(shownFuncs, listOrSingleIfOption(varData.ifSkillData, function(ifOption)
					return configVisibility.anyActiveSkill(self.build.calcsTab.mainEnv, function(activeSkill)
						return activeSkill.skillData[ifOption]
					end, configVisibility.actorKeysForVar(varData, self:GetViewActor()))
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
					local cur = self:GetConfigValue(varData.var)
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
					if ConfigScope.forVarData(varData) == "player" and self:GetViewActor() == "mercenary" then
						return false
					end
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local cur = self:GetConfigValue(varData.var)
					local def = self:GetDefaultState(varData.var, type(cur))
					return not shown and cur ~= nil and cur ~= def or shown
				end
				local innerLabel = labelControl.label
				labelControl.label = function()
					local shown = type(innerShown) == "boolean" and innerShown or innerShown()
					local cur = self:GetConfigValue(varData.var)
					local def = self:GetDefaultState(varData.var, type(cur))
					if not shown and cur ~= nil and cur ~= def then
						return colorCodes.NEGATIVE..StripEscapes(innerLabel)
					end
					return innerLabel
				end
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
					self:AddOptionStatComparison(tooltip, varData, value, self:GetViewActor(), shown)
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
			local customModsList = self:GetActorCustomModsList()
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

	local function applyNode(node, input, placeholder)
		if node.elem == "Input" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				input[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				if node.attrib.name == "enemyIsBoss" then
					input[node.attrib.name] = node.attrib.string:lower():gsub("(%l)(%w*)", function(a,b) return s_upper(a)..b end)
					:gsub("Uber Atziri", "Boss"):gsub("Shaper", "Pinnacle"):gsub("Sirus", "Pinnacle")
				elseif node.attrib.name == "presetBossSkills" then
					input[node.attrib.name] = node.attrib.string:gsub("^Uber ", "")
				else
					input[node.attrib.name] = node.attrib.string
				end
			elseif node.attrib.boolean then
				input[node.attrib.name] = node.attrib.boolean == "true"
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
				placeholder[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				input[node.attrib.name] = node.attrib.string
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Placeholder' element missing number", fileName)
				return true
			end
		end
	end

	local function setInputAndPlaceholder(node, configSetId)
		local configSet = self.configSets[configSetId]
		return applyNode(node, configSet.input, configSet.placeholder)
	end

	local function loadCustomBlock(node)
		return {
			title = node.attrib.title or "Default",
			enabled = (node.attrib.enabled == "true" or node.attrib.enabled == nil),
			text = node[1] or ""
		}
	end

	local function loadActor(actorNode, configSet)
		local actorId = actorNode.attrib.id
		if actorId ~= "player" and actorId ~= "mercenary" then
			return
		end
		self:EnsureActorConfig(configSet)
		local actor = configSet.actors[actorId]
		if actorNode.attrib.itemSetId then
			actor.itemSetId = tonumber(actorNode.attrib.itemSetId)
		end
		actor.customModsList = { }
		if actorId == "player" then
			configSet.customModsList = actor.customModsList
		end
		local input, placeholder = configSet.input, configSet.placeholder
		if actorId == "mercenary" then
			input, placeholder = actor.input, actor.placeholder
		end
		for _, child in ipairs(actorNode) do
			if child.elem == "CustomModifierBlock" then
				t_insert(actor.customModsList, loadCustomBlock(child))
			else
				applyNode(child, input, placeholder)
			end
		end
		if #actor.customModsList == 0 then
			t_insert(actor.customModsList, { title = "Default", enabled = true, text = "" })
		end
	end

	-- Catch special case of empty Config
	if xml.empty then
		self:NewConfigSet(1, "Default", { copyLiveItemSets = false })
	end
	for index, node in ipairs(xml) do
		if node.elem ~= "ConfigSet" then
			if not self.configSets[1] then
				self:NewConfigSet(1, "Default", { copyLiveItemSets = false })
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
			self:NewConfigSet(configSetId, node.attrib.title or "Default", { copyLiveItemSets = false })
			self.configSetOrderList[index] = configSetId
			self.configSets[configSetId].customModsList = { }
			for _, child in ipairs(node) do
				if child.elem == "Actor" then
					loadActor(child, self.configSets[configSetId])
				elseif child.elem == "CustomModifierBlock" then
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

	self:SetActiveConfigSet(tonumber(xml.attrib.activeConfigSet) or 1, true)
	self:ResetUndo()
end

function ConfigTabClass:PostLoad()
	local itemsTab = self.build.itemsTab
	local livePlayerId = itemsTab and itemsTab.activeItemSetId
	if livePlayerId and itemsTab and not itemsTab.itemSets[livePlayerId] then
		livePlayerId = itemsTab.itemSetOrderList[1]
	end
	for _, configSetId in ipairs(self.configSetOrderList) do
		local configSet = self.configSets[configSetId]
		self:EnsureActorConfig(configSet)
		self:SanitizeActorItemSets(configSet)
		if not configSet.actors.player.itemSetId then
			configSet.actors.player.itemSetId = livePlayerId
		end
	end
	self:ApplyActorItemSets()
	self:UpdateControls()
	self:BuildModList()
end

function ConfigTabClass:GetDefaultState(var, varType)
	local _, placeholder = self:GetVarTables(var)
	if placeholder[var] ~= nil then
		return placeholder[var]
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
	local function writeValueNode(parent, elem, name, value)
		local node = { elem = elem, attrib = { name = name } }
		if type(value) == "number" then
			node.attrib.number = tostring(value)
		elseif type(value) == "boolean" then
			node.attrib.boolean = tostring(value)
		else
			node.attrib.string = tostring(value)
		end
		t_insert(parent, node)
	end
	local function defaultFor(var, value, placeholder)
		if placeholder and placeholder[var] ~= nil then
			return placeholder[var]
		end
		if self.defaultState[var] ~= nil then
			return self.defaultState[var]
		end
		if type(value) == "number" then
			return 0
		elseif type(value) == "boolean" then
			return false
		elseif type(value) == "string" then
			return ""
		end
		return nil
	end
	local function writeInputs(parent, input, placeholder, scopePred)
		for k, v in pairs(input or { }) do
			if (not scopePred or scopePred(k)) and v ~= defaultFor(k, v, placeholder) then
				writeValueNode(parent, "Input", k, v)
			end
		end
	end
	local function writePlaceholders(parent, placeholder, scopePred)
		for k, v in pairs(placeholder or { }) do
			if v ~= nil and (not scopePred or scopePred(k)) then
				writeValueNode(parent, "Placeholder", k, v)
			end
		end
	end
	local function writeCustomMods(parent, customModsList)
		if not customModsList then
			return
		end
		for _, block in ipairs(customModsList) do
			t_insert(parent, {
				elem = "CustomModifierBlock",
				attrib = {
					title = block.title or "Default",
					enabled = tostring(block.enabled ~= false)
				},
				[1] = block.text or ""
			})
		end
	end
	local function writeActor(parent, actorId, input, placeholder, customModsList, itemSetId, scopePred)
		local actorNode = { elem = "Actor", attrib = { id = actorId } }
		if itemSetId then
			actorNode.attrib.itemSetId = tostring(itemSetId)
		end
		writeInputs(actorNode, input, placeholder, scopePred)
		writePlaceholders(actorNode, placeholder, scopePred)
		writeCustomMods(actorNode, customModsList)
		t_insert(parent, actorNode)
	end
	for _, configSetId in ipairs(self.configSetOrderList) do
		local configSet = self.configSets[configSetId]
		self:EnsureActorConfig(configSet)
		local child = { elem = "ConfigSet", attrib = { id = tostring(configSetId), title = configSet.title } }
		t_insert(xml, child)

		writeInputs(child, configSet.input, configSet.placeholder, function(var) return ConfigScope.tryForVar(var) == "shared" end)
		writePlaceholders(child, configSet.placeholder, function(var) return ConfigScope.tryForVar(var) == "shared" end)
		writeActor(child, "player", configSet.input, configSet.placeholder, configSet.customModsList, configSet.actors.player.itemSetId, function(var)
			local scope = ConfigScope.tryForVar(var)
			-- Unknown leftover keys stay on the player actor instead of being dropped or reclassified.
			return scope == "actor" or scope == "player" or scope == nil
		end)
		writeActor(child, "mercenary", configSet.actors.mercenary.input, configSet.actors.mercenary.placeholder, configSet.actors.mercenary.customModsList, configSet.actors.mercenary.itemSetId)
	end
end

function ConfigTabClass:RefreshActorSelect()
	if not MercenaryTools.tabVisible(self.build) and self:GetViewActor() == "mercenary" then
		self.viewActor = "player"
	end
	self.controls.actorSelect:SetList(MercenaryTools.configActorList(self.build))
	self.controls.actorSelect:SelByValue(self:GetViewActor(), "id")
end

function ConfigTabClass:UpdateControls()
	self:RefreshActorSelect()
	for var, control in pairs(self.varControls) do
		local input, placeholder = self:GetVarTables(var)
		if control._className == "EditControl" or control._className == "ResizableEditControl" then
			control:SetText(tostring(input[var] or ""))
			if placeholder[var] then
				control:SetPlaceholder(tostring(placeholder[var]))
			end
		elseif control._className == "CheckBoxControl" then
			control.state = input[var]
		elseif control._className == "DropDownControl" then
			control:SelByValue(input[var] or self:GetDefaultState(var), "val")
		end
	end
	self:UpdateCustomModsControls()
	self:UpdateActorItemSetSelect()
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
	self:UpdateActorItemSetSelect()

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

local function applyConfigVar(varData, input, placeholder, modList, enemyModList, build)
	if not varData.apply or not varData.var then
		return
	end
	if varData.type == "check" then
		if input[varData.var] then
			varData.apply(true, modList, enemyModList, build)
		end
	elseif varData.type == "count" or varData.type == "integer" or varData.type == "countAllowZero" or varData.type == "float" then
		if input[varData.var] and (input[varData.var] ~= 0 or varData.type == "countAllowZero") then
			varData.apply(input[varData.var], modList, enemyModList, build)
		elseif placeholder[varData.var] and (placeholder[varData.var] ~= 0 or varData.type == "countAllowZero") then
			varData.apply(placeholder[varData.var], modList, enemyModList, build)
		end
	elseif varData.type == "list" or varData.type == "text" then
		if input[varData.var] then
			varData.apply(input[varData.var], modList, enemyModList, build)
		end
	end
end

local function applyCustomMods(customModsList, modList, fallbackText)
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
								modList:AddMod(modLib.setSource(mod, source))
							end
						end
					end
				end
			end
		end
	end
	if not hasBlockText and fallbackText and #fallbackText > 0 then
		for line in fallbackText:gmatch("([^\n]*)\n?") do
			local strippedLine = StripEscapes(line):match("^%s*(.-)%s*$")
			local mods, extra = modLib.parseMod(strippedLine)
			if mods and not extra then
				for i = 1, #mods do
					local mod = mods[i]
					if mod then
						modList:AddMod(modLib.setSource(mod, "Custom"))
					end
				end
			end
		end
	end
end

function ConfigTabClass:GetViewActor()
	return self.viewActor or "player"
end

function ConfigTabClass:ComparisonActorFor(viewActor)
	return (viewActor or self:GetViewActor()) == "mercenary" and "MERCENARY" or nil
end

function ConfigTabClass:ComparisonBase(playerBase, actorOutputs, viewActor)
	local actor = self:ComparisonActorFor(viewActor)
	if actor and actorOutputs then
		return actorOutputs[actor], actor
	end
	return playerBase, actor
end

function ConfigTabClass:GetComparisonCalculator(viewActor)
	local calcFunc, playerBase, actorOutputs = self.build.calcsTab:GetMiscCalculator(self.build)
	local calcBase, actor = self:ComparisonBase(playerBase, actorOutputs, viewActor)
	return calcFunc, calcBase, actor
end

function ConfigTabClass:RunComparisonCalc(calcFunc, actor)
	return calcFunc(actor and { comparisonActor = actor } or nil)
end

-- Preview toggling a check/list option against viewActor's output.
-- optionShown is the control's eligibility; hidden-but-set values are flagged invalid.
function ConfigTabClass:AddOptionStatComparison(tooltip, varData, value, viewActor, optionShown)
	viewActor = viewActor or self:GetViewActor()
	local inputs = select(1, self:GetVarTablesForActor(varData.var, viewActor))
	local cur = inputs[varData.var]
	local def = self:GetDefaultState(varData.var, type(cur))
	if not optionShown and cur ~= nil and cur ~= def then
		tooltip:AddLine(14, colorCodes.NEGATIVE.."This config option is conditional with missing source and is invalid.")
		return
	end
	-- Number inputs apply as the user types, so a hover delta is meaningless.
	if varData.type ~= "check" and varData.type ~= "list" then
		return
	end
	local valueMapped
	if varData.type == "check" then
		valueMapped = not cur
	else
		valueMapped = type(value) == "table" and value.val or value
	end
	if valueMapped == cur then
		return
	end
	local calcFunc, playerBase, actorOutputs = self.build.calcsTab:GetMiscCalculator(self.build)
	if not calcFunc then
		return
	end
	local calcBase, actor = self:ComparisonBase(playerBase, actorOutputs, viewActor)
	if self.optionComparisonCacheRevision ~= self.build.outputRevision then
		self.optionComparisonCache = { }
		self.optionComparisonCacheRevision = self.build.outputRevision
	end
	self.optionComparisonCache = self.optionComparisonCache or { }
	local key = string.format("%s:%s:%s:%s", varData.var, tostring(valueMapped), tostring(cur), tostring(actor or "PLAYER"))
	if not self.optionComparisonCache[key] then
		local buildFlag = self.build.buildFlag
		inputs[varData.var] = valueMapped
		self:BuildModList()
		self.optionComparisonCache[key] = self:RunComparisonCalc(calcFunc, actor)
		inputs[varData.var] = cur
		self:BuildModList()
		self.build.buildFlag = buildFlag
	end
	tooltip:AddSeparator(10)
	local prefix = (varData.type == "check") and "^7Toggling this" or "^7Selecting this"
	self.build:AddStatComparesToTooltip(tooltip, calcBase, self.optionComparisonCache[key], prefix .. " option will give you:", nil, actor)
	if #tooltip.lines == 1 then
		tooltip:Clear()
	end
end

function ConfigTabClass:SetViewActor(actor)
	if actor ~= "mercenary" then
		actor = "player"
	end
	self.viewActor = actor
	if self.controls.actorSelect then
		self.controls.actorSelect:SelByValue(actor, "id")
	end
	self:UpdateControls()
	self:UpdateCustomModsControls()
	self:UpdateActorItemSetSelect()
end

function ConfigTabClass:GetVarTablesForActor(var, actor)
	local configSet = self.configSets[self.activeConfigSetId]
	self:EnsureActorConfig(configSet)
	-- Skill-option headers have a label and ifSkill but no var. Draw still
	-- asks for their current value when deciding whether to highlight them.
	if var and ConfigScope.forVar(var) == "actor" and actor == "mercenary" then
		return configSet.actors.mercenary.input, configSet.actors.mercenary.placeholder
	end
	return configSet.input, configSet.placeholder
end

function ConfigTabClass:GetVarTables(var)
	return self:GetVarTablesForActor(var, self:GetViewActor())
end

function ConfigTabClass:GetConfigValue(var)
	local input = self:GetVarTables(var)
	return input[var]
end

function ConfigTabClass:GetActorConfigInput(actor)
	local configSet = self.configSets[self.activeConfigSetId]
	self:EnsureActorConfig(configSet)
	if actor ~= "mercenary" then
		return configSet.input, configSet.placeholder
	end
	local sharedCache = self.mercenarySharedConfigCache
	if not (sharedCache and sharedCache.configSet == configSet) then
		local sharedInput, sharedPlaceholder = { }, { }
		for k, v in pairs(configSet.input) do
			if ConfigScope.tryForVar(k) == "shared" then
				sharedInput[k] = v
			end
		end
		for k, v in pairs(configSet.placeholder) do
			if ConfigScope.tryForVar(k) == "shared" then
				sharedPlaceholder[k] = v
			end
		end
		sharedCache = { configSet = configSet, input = sharedInput, placeholder = sharedPlaceholder }
		self.mercenarySharedConfigCache = sharedCache
	end
	-- Actor keys are live. Tests and the Config UI write mercenary.input
	-- without always rebuilding the shared snapshot first.
	-- Reuse the merge buffers; callers that persist the result must copy.
	local input = wipeTable(self.mercenaryMergedInput)
	local placeholder = wipeTable(self.mercenaryMergedPlaceholder)
	self.mercenaryMergedInput = input
	self.mercenaryMergedPlaceholder = placeholder
	for k, v in pairs(sharedCache.input) do
		input[k] = v
	end
	for k, v in pairs(sharedCache.placeholder) do
		placeholder[k] = v
	end
	for k, v in pairs(configSet.actors.mercenary.input) do
		input[k] = v
	end
	for k, v in pairs(configSet.actors.mercenary.placeholder) do
		placeholder[k] = v
	end
	return input, placeholder
end

function ConfigTabClass:SetConfigValue(var, value)
	local input = self:GetVarTables(var)
	input[var] = value
end

function ConfigTabClass:SetConfigPlaceholder(var, value)
	local _, placeholder = self:GetVarTables(var)
	placeholder[var] = value
end

function ConfigTabClass:GetActorCustomModsList(configSet)
	configSet = configSet or self.configSets[self.activeConfigSetId]
	self:EnsureActorConfig(configSet)
	if self:GetViewActor() == "mercenary" then
		return configSet.actors.mercenary.customModsList
	end
	return configSet.customModsList
end

function ConfigTabClass:UpdateActorItemSetSelect()
	if not self.controls.itemSetSelect or not self.build.itemsTab then
		return
	end
	local itemSetList = { }
	for _, itemSetId in ipairs(self.build.itemsTab.itemSetOrderList) do
		local itemSet = self.build.itemsTab.itemSets[itemSetId]
		if itemSet then
			t_insert(itemSetList, { id = itemSetId, label = itemSet.title or "Default" })
		end
	end
	self.controls.itemSetSelect:SetList(itemSetList)
	local selectedId
	if self:GetViewActor() == "mercenary" and self.build.mercenaryTab then
		selectedId = self.build.mercenaryTab.itemSetId
	else
		selectedId = self.build.itemsTab.activeItemSetId
	end
	self.controls.itemSetSelect:SelByValue(selectedId, "id")
	self.controls.itemSetSelect.enabled = #itemSetList > 1
end

function ConfigTabClass:EnsureActorConfig(configSet)
	if not configSet then
		return
	end
	if not configSet.actors then
		configSet.actors = { }
	end
	if not configSet.actors.player then
		configSet.actors.player = {
			itemSetId = nil,
			customModsList = configSet.customModsList,
		}
	end
	if configSet.customModsList then
		configSet.actors.player.customModsList = configSet.customModsList
	elseif not configSet.actors.player.customModsList then
		configSet.actors.player.customModsList = { { title = "Default", enabled = true, text = "" } }
		configSet.customModsList = configSet.actors.player.customModsList
	end
	if not configSet.actors.mercenary then
		local mercenaryInput, mercenaryPlaceholder = { }, { }
		for _, varData in ipairs(varList) do
			if varData.var and ConfigScope.forVarData(varData) == "actor" then
				mercenaryInput[varData.var] = varData.defaultState
				mercenaryPlaceholder[varData.var] = varData.defaultPlaceholderState
				if varData.defaultIndex then
					mercenaryInput[varData.var] = varData.list[varData.defaultIndex].val
				end
			end
		end
		configSet.actors.mercenary = {
			input = mercenaryInput,
			placeholder = mercenaryPlaceholder,
			customModsList = { { title = "Default", enabled = true, text = "" } },
			itemSetId = nil,
		}
	end
end

function ConfigTabClass:CopyLiveItemSets(configSet)
	self:EnsureActorConfig(configSet)
	if self.build.itemsTab then
		configSet.actors.player.itemSetId = self.build.itemsTab.activeItemSetId
	end
	if self.build.mercenaryTab then
		configSet.actors.mercenary.itemSetId = self.build.mercenaryTab.itemSetId
	end
end

function ConfigTabClass:SanitizeActorItemSets(configSet)
	self:EnsureActorConfig(configSet)
	local itemsTab = self.build.itemsTab
	for _, actor in pairs(configSet.actors) do
		if actor.itemSetId and itemsTab and not itemsTab.itemSets[actor.itemSetId] then
			actor.itemSetId = nil
		end
	end
end

function ConfigTabClass:RemapItemSetId(oldId, newId)
	if not oldId then
		return
	end
	for _, configSet in pairs(self.configSets) do
		self:EnsureActorConfig(configSet)
		for _, actor in pairs(configSet.actors) do
			if actor.itemSetId == oldId then
				actor.itemSetId = newId
			end
		end
	end
end

function ConfigTabClass:SyncActorItemSet(actor, itemSetId)
	local configSet = self.configSets[self.activeConfigSetId]
	if not configSet or not actor then
		return
	end
	self:EnsureActorConfig(configSet)
	if configSet.actors[actor] then
		configSet.actors[actor].itemSetId = itemSetId
	end
end

function ConfigTabClass:ApplyActorItemSets(opts)
	opts = opts or { }
	local configSet = self.configSets[self.activeConfigSetId]
	if not configSet then
		return
	end
	self:EnsureActorConfig(configSet)
	self:SanitizeActorItemSets(configSet)
	local itemsTab = self.build.itemsTab
	local playerItemSetId = configSet.actors.player and configSet.actors.player.itemSetId
	if opts.player ~= false and itemsTab and playerItemSetId and itemsTab.itemSets[playerItemSetId] then
		-- Follow the equipped player set in the Items tab only when that set is
		-- already what the user is viewing. Otherwise applying config (or undo)
		-- would yank the view off Mercenary / inactive-set inspection.
		local changeView = itemsTab.viewItemSetId == itemsTab.activeItemSetId
			and itemsTab.viewComparisonActor ~= "MERCENARY"
		itemsTab.skipConfigItemSetSync = true
		itemsTab:SetActiveItemSet(playerItemSetId, changeView)
		itemsTab.skipConfigItemSetSync = false
	end
	local mercenaryTab = self.build.mercenaryTab
	local mercenaryItemSetId = configSet.actors.mercenary and configSet.actors.mercenary.itemSetId
	if opts.mercenary ~= false and mercenaryTab and mercenaryItemSetId and itemsTab and itemsTab.itemSets[mercenaryItemSetId] then
		mercenaryTab.skipConfigItemSetSync = true
		mercenaryTab:SetItemSet(mercenaryItemSetId, false)
		mercenaryTab.skipConfigItemSetSync = false
	end
end

local function reuseModList(list)
	if list then
		local multipliers = list.multipliers
		local conditions = list.conditions
		local actor = list.actor
		wipeTable(list)
		list.parent = false
		list.actor = wipeTable(actor)
		list.multipliers = wipeTable(multipliers)
		list.conditions = wipeTable(conditions)
		return list
	end
	return new("ModList"):ModList()
end

local function idleModList(list)
	if list then
		return reuseModList(list)
	end
	return nil
end

function ConfigTabClass:BuildModList()
	local configSet = self.configSets[self.activeConfigSetId]
	self:EnsureActorConfig(configSet)
	self.mercenarySharedConfigCache = nil
	local hired = MercenaryTools.hasProfile(self.build)
	local playerModList = reuseModList(self.modList)
	local enemyModList = reuseModList(self.enemyModList)
	self.modList = playerModList
	self.enemyModList = enemyModList
	local mercenaryModList, playerEnemyModList, mercenaryEnemyModList, tempEnemy
	if hired then
		mercenaryModList = reuseModList(self.mercenaryModList)
		playerEnemyModList = reuseModList(self.playerEnemyModList)
		mercenaryEnemyModList = reuseModList(self.mercenaryEnemyModList)
		tempEnemy = reuseModList(self.tempEnemyModList)
		self.mercenaryModList = mercenaryModList
		self.playerEnemyModList = playerEnemyModList
		self.mercenaryEnemyModList = mercenaryEnemyModList
		self.tempEnemyModList = tempEnemy
	else
		self.mercenaryModList = idleModList(self.mercenaryModList)
		self.playerEnemyModList = idleModList(self.playerEnemyModList)
		self.mercenaryEnemyModList = idleModList(self.mercenaryEnemyModList)
		self.mercenaryEncounterModList = idleModList(self.mercenaryEncounterModList)
		self.tempEnemyModList = idleModList(self.tempEnemyModList)
	end
	local input = configSet.input
	local placeholder = configSet.placeholder
	self:UpdateLevel() -- enemy level handled here because it's needed to correctly set boss stats

	local function applyPartitioned(varData, srcInput, srcPlaceholder, actorMods, sourceEnemy)
		for i = #tempEnemy, 1, -1 do
			tempEnemy[i] = nil
		end
		applyConfigVar(varData, srcInput, srcPlaceholder, actorMods, tempEnemy, self.build)
		for _, mod in ipairs(tempEnemy) do
			if ConfigScope.isSourceOwnedEnemyMod(mod) then
				sourceEnemy:AddMod(mod)
			else
				enemyModList:AddMod(mod)
			end
		end
	end
	local sharedMods = reuseModList(self.sharedModsList)
	self.sharedModsList = sharedMods
	for _, varData in ipairs(varList) do
		local scope = ConfigScope.forVarData(varData)
		if scope == "shared" then
			applyConfigVar(varData, input, placeholder, sharedMods, enemyModList, self.build)
		elseif scope == "actor" or scope == "player" then
			if hired and ConfigScope.enemyStateForVarData(varData) == "source" then
				applyPartitioned(varData, input, placeholder, playerModList, playerEnemyModList)
			else
				applyConfigVar(varData, input, placeholder, playerModList, enemyModList, self.build)
			end
		end
	end
	playerModList:AddList(sharedMods)
	if hired then
		mercenaryModList:AddList(sharedMods)
	end

	local mercenary = configSet.actors.mercenary
	if hired then
		local mercenaryEnemyMods = reuseModList(self.mercenaryEncounterModList)
		self.mercenaryEncounterModList = mercenaryEnemyMods
		for _, varData in ipairs(varList) do
			if ConfigScope.forVarData(varData) == "actor" then
				if ConfigScope.enemyStateForVarData(varData) == "source" then
					applyPartitioned(varData, mercenary.input, mercenary.placeholder, mercenaryModList, mercenaryEnemyModList)
				else
					applyConfigVar(varData, mercenary.input, mercenary.placeholder, mercenaryModList, mercenaryEnemyMods, self.build)
				end
			end
		end
		enemyModList:AddList(mercenaryEnemyMods)
		applyCustomMods(mercenary.customModsList, mercenaryModList)
	end

	applyCustomMods(configSet.customModsList, playerModList, input.customMods)
	self.modListHasMercenaryProfile = hired
end

function ConfigTabClass:EnsureMercenaryProfileModList()
	if self.modListHasMercenaryProfile ~= MercenaryTools.hasProfile(self.build) then
		self:BuildModList()
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
	self:EnsureActorConfig(configSet)
	return {
		input = copyTable(configSet.input),
		placeholder = copyTable(configSet.placeholder),
		customModsList = copyTable(configSet.customModsList),
		actors = copyTable(configSet.actors),
	}
end

function ConfigTabClass:RestoreUndoState(state)
	local configSet = self.configSets[self.activeConfigSetId]
	if type(state) == "table" and state.input then
		wipeTable(configSet.input)
		for k, v in pairs(state.input) do
			configSet.input[k] = v
		end
		if state.placeholder then
			configSet.placeholder = copyTable(state.placeholder)
		end
		if state.customModsList then
			configSet.customModsList = copyTable(state.customModsList)
		end
		if state.actors then
			configSet.actors = copyTable(state.actors)
		end
	else
		wipeTable(configSet.input)
		for k, v in pairs(state) do
			configSet.input[k] = v
		end
	end
	self:ApplyActorItemSets()
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
function ConfigTabClass:NewConfigSet(configSetId, title, opts)
	opts = opts or { }
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
	self:EnsureActorConfig(configSet)
	if opts.copyLiveItemSets ~= false then
		self:CopyLiveItemSets(configSet)
	end
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
	local customModsList = self:GetActorCustomModsList(configSet)
	if not customModsList then
		customModsList = { }
		if self:GetViewActor() == "mercenary" then
			configSet.actors.mercenary.customModsList = customModsList
		else
			configSet.customModsList = customModsList
		end
	end
	if #customModsList == 0 then
		t_insert(customModsList, { title = "Default", enabled = true, text = configSet.input and configSet.input.customMods or "" })
	end

	if self.customModsBlockControls then
		for _, ctrl in ipairs(self.customModsBlockControls) do
			ctrl.shown = false
		end
	end
	self.customModsBlockControls = { }
	self.customSection.varControlList = { self.controls.customModsAddBlock }

	for index, block in ipairs(customModsList) do
		local blockControl = new("CustomModBlockControl"):CustomModBlockControl({"TOPLEFT", self.customSection, "TOPLEFT"}, {8, 0, 344, 120}, self, index, block)
		blockControl.shown = function()
			return not self:IsSectionCollapsed(self.customSection)
		end
		t_insert(self.customModsBlockControls, blockControl)
		t_insert(self.controls, blockControl)
		t_insert(self.customSection.varControlList, blockControl)
	end
end

function ConfigTabClass:SetActiveConfigSet(configSetId, init, itemSetOpts)
	-- Initialize config sets if needed
	if not self.configSetOrderList[1] then
		self.configSetOrderList[1] = 1
		self:NewConfigSet(1, nil, { copyLiveItemSets = false })
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
		self:ApplyActorItemSets(itemSetOpts)
		self:UpdateControls()
		self:BuildModList()
	end
	self.build.buildFlag = true
	self.build:SyncLoadouts()
end
