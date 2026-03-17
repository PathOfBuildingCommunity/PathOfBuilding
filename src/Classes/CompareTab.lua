-- Path of Building
--
-- Module: Compare Tab
-- Manages build comparison state and renders the comparison screen.
--
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local s_format = string.format

-- Flag matching for stat filtering (same logic as Build.lua lines 33-57)
local function matchFlags(reqFlags, notFlags, flags)
	if type(reqFlags) == "string" then
		reqFlags = { reqFlags }
	end
	if reqFlags then
		for _, flag in ipairs(reqFlags) do
			if not flags[flag] then
				return
			end
		end
	end
	if type(notFlags) == "string" then
		notFlags = { notFlags }
	end
	if notFlags then
		for _, flag in ipairs(notFlags) do
			if flags[flag] then
				return
			end
		end
	end
	return true
end

local CompareTabClass = newClass("CompareTab", "ControlHost", "Control", function(self, primaryBuild)
	self.ControlHost()
	self.Control()

	self.primaryBuild = primaryBuild

	-- Comparison entries (indexed 1..N for future 3+ build support)
	self.compareEntries = {}
	self.activeCompareIndex = 0

	-- Sub-view mode
	self.compareViewMode = "SUMMARY"

	-- Scroll offset for scrollable views
	self.scrollY = 0

	-- Tree layout cache (set in Draw, used by DrawTree)
	self.treeLayout = nil

	-- Track when tree search fields need syncing with viewer state
	self.treeSearchNeedsSync = true

	-- Tree overlay mode (false = side-by-side, true = overlay with green/red/blue nodes)
	self.treeOverlayMode = false

	-- Tooltip for item hover in Items view
	self.itemTooltip = new("Tooltip")

	-- Interactive config controls state
	self.configControls = {}        -- { var -> { control, varData } }
	self.configControlList = {}     -- ordered list for layout
	self.configNeedsRebuild = true  -- trigger initial build
	self.configCompareId = nil      -- track which compare entry controls were built for
	self.configToggle = false       -- show all / hide ineligible toggle
	self.configDisplayList = {}     -- computed display order (headers + rows)

	-- Controls for the comparison screen
	self:InitControls()
end)

function CompareTabClass:InitControls()
	-- Sub-tab buttons
	local subTabs = { "Summary", "Tree", "Skills", "Items", "Calcs", "Config" }
	local subTabModes = { "SUMMARY", "TREE", "SKILLS", "ITEMS", "CALCS", "CONFIG" }

	self.controls.subTabAnchor = new("Control", nil, {0, 0, 0, 20})
	for i, tabName in ipairs(subTabs) do
		local mode = subTabModes[i]
		local prevName = i > 1 and ("subTab" .. subTabs[i-1]) or "subTabAnchor"
		local anchor = i == 1
			and {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}
			or {"LEFT", self.controls[prevName], "RIGHT"}
		self.controls["subTab" .. tabName] = new("ButtonControl", anchor, {i == 1 and 0 or 4, 0, 72, 20}, tabName, function()
			-- Clear tree overlay compareSpec when leaving TREE mode
			if self.compareViewMode == "TREE" and self.treeOverlayMode
					and self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
				self.primaryBuild.treeTab.viewer.compareSpec = nil
			end
			self.compareViewMode = mode
			self.scrollY = 0
			if mode == "TREE" then
				self.treeSearchNeedsSync = true
			end
		end)
		self.controls["subTab" .. tabName].locked = function()
			return self.compareViewMode == mode
		end
	end

	-- Build B selector dropdown
	self.controls.compareBuildLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -70, 0, 16}, "^7Compare with:")
	self.controls.compareBuildSelect = new("DropDownControl", {"LEFT", self.controls.compareBuildLabel, "RIGHT"}, {4, 0, 250, 20}, {}, function(index, value)
		if index and index > 0 and index <= #self.compareEntries then
			self.activeCompareIndex = index
			self.treeSearchNeedsSync = true
		end
	end)
	self.controls.compareBuildSelect.enabled = function()
		return #self.compareEntries > 0
	end

	-- Import button (opens import popup)
	self.controls.importBtn = new("ButtonControl", {"LEFT", self.controls.compareBuildSelect, "RIGHT"}, {8, 0, 100, 20}, "Import...", function()
		self:OpenImportPopup()
	end)

	-- Re-import current build button
	self.controls.reimportBtn = new("ButtonControl", {"LEFT", self.controls.importBtn, "RIGHT"}, {4, 0, 120, 20}, "Re-import Current", function()
		self:ReimportPrimary()
	end)
	self.controls.reimportBtn.tooltipFunc = function(tooltip)
		tooltip:Clear()
		local importTab = self.primaryBuild.importTab
		if importTab and importTab.charImportMode == "SELECTCHAR" then
			local charSelect = importTab.controls.charSelect
			local charData = charSelect and charSelect.list and charSelect.list[charSelect.selIndex]
			if charData and charData.char then
				tooltip:AddLine(16, "Re-import character from the game server:")
				tooltip:AddLine(14, "^7" .. charData.char.name .. " (" .. charData.char.class .. ", " .. charData.char.league .. ")")
			else
				tooltip:AddLine(16, "Re-import the currently selected character.")
			end
			tooltip:AddLine(14, "^7Refreshes passive tree, jewels, items, and skills.")
		else
			tooltip:AddLine(16, "^7No character selected.")
			tooltip:AddLine(14, "^7Go to Import/Export Build tab and select a character first.")
		end
	end

	-- Remove comparison build button
	self.controls.removeBtn = new("ButtonControl", {"LEFT", self.controls.reimportBtn, "RIGHT"}, {4, 0, 70, 20}, "Remove", function()
		if self.activeCompareIndex > 0 and self.activeCompareIndex <= #self.compareEntries then
			self:RemoveBuild(self.activeCompareIndex)
		end
	end)
	self.controls.removeBtn.enabled = function()
		return #self.compareEntries > 0
	end

	-- ============================================================
	-- Comparison build set selectors (row between build selector and sub-tabs)
	-- ============================================================
	local setsEnabled = function()
		return #self.compareEntries > 0
	end

	self.controls.compareSetsLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -44, 0, 16}, "^7Sets:")
	self.controls.compareSetsLabel.shown = setsEnabled

	-- Tree spec selector for comparison build
	self.controls.compareSpecLabel = new("LabelControl", {"LEFT", self.controls.compareSetsLabel, "RIGHT"}, {4, 0, 0, 16}, "^7Tree set:")
	self.controls.compareSpecLabel.shown = setsEnabled
	self.controls.compareSpecSelect = new("DropDownControl", {"LEFT", self.controls.compareSpecLabel, "RIGHT"}, {2, 0, 150, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.treeTab and entry.treeTab.specList[index] then
			entry:SetActiveSpec(index)
			-- Restore primary build's window title (SetActiveSpec changes it)
			if self.primaryBuild.spec then
				self.primaryBuild.spec:SetWindowTitleWithBuildClass()
			end
		end
	end)
	self.controls.compareSpecSelect.enabled = setsEnabled
	self.controls.compareSpecSelect.maxDroppedWidth = 500
	self.controls.compareSpecSelect.enableDroppedWidth = true

	-- Skill set selector for comparison build
	self.controls.compareSkillSetLabel = new("LabelControl", {"LEFT", self.controls.compareSpecSelect, "RIGHT"}, {8, 0, 0, 16}, "^7Skill set:")
	self.controls.compareSkillSetLabel.shown = setsEnabled
	self.controls.compareSkillSetSelect = new("DropDownControl", {"LEFT", self.controls.compareSkillSetLabel, "RIGHT"}, {2, 0, 150, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.skillsTab and entry.skillsTab.skillSetOrderList[index] then
			entry:SetActiveSkillSet(entry.skillsTab.skillSetOrderList[index])
		end
	end)
	self.controls.compareSkillSetSelect.enabled = setsEnabled

	-- Item set selector for comparison build
	self.controls.compareItemSetLabel = new("LabelControl", {"LEFT", self.controls.compareSkillSetSelect, "RIGHT"}, {8, 0, 0, 16}, "^7Item set:")
	self.controls.compareItemSetLabel.shown = setsEnabled
	self.controls.compareItemSetSelect = new("DropDownControl", {"LEFT", self.controls.compareItemSetLabel, "RIGHT"}, {2, 0, 150, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.itemsTab and entry.itemsTab.itemSetOrderList[index] then
			entry:SetActiveItemSet(entry.itemsTab.itemSetOrderList[index])
		end
	end)
	self.controls.compareItemSetSelect.enabled = setsEnabled

	-- ============================================================
	-- Comparison build main skill selector (row between sets and sub-tabs)
	-- ============================================================
	self.controls.cmpSkillLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -22, 0, 16}, "^7Skill:")
	self.controls.cmpSkillLabel.shown = setsEnabled

	-- Socket group dropdown
	self.controls.cmpSocketGroup = new("DropDownControl", {"LEFT", self.controls.cmpSkillLabel, "RIGHT"}, {2, 0, 200, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			entry:SetMainSocketGroup(index)
		end
	end)
	self.controls.cmpSocketGroup.shown = setsEnabled
	self.controls.cmpSocketGroup.maxDroppedWidth = 500
	self.controls.cmpSocketGroup.enableDroppedWidth = true

	-- Active skill within group
	self.controls.cmpMainSkill = new("DropDownControl", {"LEFT", self.controls.cmpSocketGroup, "RIGHT"}, {2, 0, 150, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.mainSocketGroup]
			if mainSocketGroup then
				mainSocketGroup.mainActiveSkill = index
				entry.modFlag = true
				entry.buildFlag = true
			end
		end
	end)
	self.controls.cmpMainSkill.shown = false

	-- Skill part (multi-part skills)
	self.controls.cmpSkillPart = new("DropDownControl", {"LEFT", self.controls.cmpMainSkill, "RIGHT"}, {2, 0, 100, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.mainSocketGroup]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillList
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkill or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillPart = index
					entry.modFlag = true
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpSkillPart.shown = false

	-- Stage count
	self.controls.cmpStageCountLabel = new("LabelControl", {"LEFT", self.controls.cmpSkillPart, "RIGHT"}, {4, 0, 0, 16}, "^7Stages:")
	self.controls.cmpStageCountLabel.shown = function() return self.controls.cmpStageCount.shown end
	self.controls.cmpStageCount = new("EditControl", {"LEFT", self.controls.cmpStageCountLabel, "RIGHT"}, {2, 0, 52, 20}, "", nil, "%D", 5, function(buf)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.mainSocketGroup]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillList
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkill or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillStageCount = tonumber(buf)
					entry.modFlag = true
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpStageCount.shown = false

	-- Mine count
	self.controls.cmpMineCountLabel = new("LabelControl", {"LEFT", self.controls.cmpStageCount, "RIGHT"}, {4, 0, 0, 16}, "^7Mines:")
	self.controls.cmpMineCountLabel.shown = function() return self.controls.cmpMineCount.shown end
	self.controls.cmpMineCount = new("EditControl", {"LEFT", self.controls.cmpMineCountLabel, "RIGHT"}, {2, 0, 52, 20}, "", nil, "%D", 5, function(buf)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.mainSocketGroup]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillList
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkill or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillMineCount = tonumber(buf)
					entry.modFlag = true
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpMineCount.shown = false

	-- Minion selector
	self.controls.cmpMinion = new("DropDownControl", {"LEFT", self.controls.cmpMineCount, "RIGHT"}, {4, 0, 140, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.mainSocketGroup]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillList
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkill or 1]
				if activeSkill and activeSkill.activeEffect then
					local selected = self.controls.cmpMinion.list[index]
					if selected then
						if selected.itemSetId then
							activeSkill.activeEffect.srcInstance.skillMinionItemSet = selected.itemSetId
						elseif selected.minionId then
							activeSkill.activeEffect.srcInstance.skillMinion = selected.minionId
						end
						entry.modFlag = true
						entry.buildFlag = true
					end
				end
			end
		end
	end)
	self.controls.cmpMinion.shown = false

	-- Minion skill selector
	self.controls.cmpMinionSkill = new("DropDownControl", {"LEFT", self.controls.cmpMinion, "RIGHT"}, {2, 0, 140, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.mainSocketGroup]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillList
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkill or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillMinionSkill = index
					entry.modFlag = true
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpMinionSkill.shown = false

	-- ============================================================
	-- Tree footer controls (visible only in TREE view mode with a comparison loaded)
	-- ============================================================
	local treeFooterShown = function()
		return self.compareViewMode == "TREE" and self:GetActiveCompare() ~= nil
	end
	local treeSideBySideShown = function()
		return self.compareViewMode == "TREE" and self:GetActiveCompare() ~= nil and not self.treeOverlayMode
	end

	-- Build version dropdown list (shared between left and right)
	self.treeVersionDropdownList = {}
	for _, num in ipairs(treeVersionList) do
		t_insert(self.treeVersionDropdownList, {
			label = treeVersions[num].display,
			value = num
		})
	end

	-- Overlay toggle checkbox (positioned dynamically in Draw)
	self.controls.treeOverlayCheck = new("CheckBoxControl", nil, {0, 0, 20}, "Overlay comparison", function(state)
		self.treeOverlayMode = state
		self.treeSearchNeedsSync = true
		if not state and self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
			self.primaryBuild.treeTab.viewer.compareSpec = nil
		end
	end)
	self.controls.treeOverlayCheck.shown = treeFooterShown

	-- Overlay-mode search (single search for primary viewer)
	self.controls.overlayTreeSearch = new("EditControl", nil, {0, 0, 300, 20}, "", "Search", "%c", 100, function(buf)
		if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
			self.primaryBuild.treeTab.viewer.searchStr = buf
		end
	end, nil, nil, true)
	self.controls.overlayTreeSearch.shown = function()
		return self.compareViewMode == "TREE" and self:GetActiveCompare() ~= nil and self.treeOverlayMode
	end

	-- Footer anchor controls (positioned dynamically in Draw, side-by-side only)
	self.controls.leftFooterAnchor = new("Control", nil, {0, 0, 0, 20})
	self.controls.leftFooterAnchor.shown = treeSideBySideShown
	self.controls.rightFooterAnchor = new("Control", nil, {0, 0, 0, 20})
	self.controls.rightFooterAnchor.shown = treeSideBySideShown

	-- Left side (primary build) spec/version controls (header, both modes)
	self.controls.leftSpecSelect = new("DropDownControl", nil, {0, 0, 180, 20}, {}, function(index, value)
		if self.primaryBuild.treeTab and self.primaryBuild.treeTab.specList[index] then
			self.primaryBuild.modFlag = true
			self.primaryBuild.treeTab:SetActiveSpec(index)
		end
	end)
	self.controls.leftSpecSelect.shown = treeFooterShown
	self.controls.leftSpecSelect.maxDroppedWidth = 500
	self.controls.leftSpecSelect.enableDroppedWidth = true

	self.controls.leftVersionSelect = new("DropDownControl", {"LEFT", self.controls.leftSpecSelect, "RIGHT"}, {4, 0, 100, 20}, self.treeVersionDropdownList, function(index, selected)
		if selected and selected.value and self.primaryBuild.spec and selected.value ~= self.primaryBuild.spec.treeVersion then
			self.primaryBuild.treeTab:OpenVersionConvertPopup(selected.value, true)
		end
	end)
	self.controls.leftVersionSelect.shown = treeFooterShown

	-- Left search (footer, side-by-side only)
	self.controls.leftTreeSearch = new("EditControl", {"TOPLEFT", self.controls.leftFooterAnchor, "TOPLEFT"}, {0, 0, 200, 20}, "", "Search", "%c", 100, function(buf)
		if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
			self.primaryBuild.treeTab.viewer.searchStr = buf
		end
	end, nil, nil, true)
	self.controls.leftTreeSearch.shown = treeSideBySideShown

	-- Right side (compare build) spec/version controls (header, both modes)
	self.controls.rightSpecSelect = new("DropDownControl", nil, {0, 0, 180, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.treeTab and entry.treeTab.specList[index] then
			entry:SetActiveSpec(index)
			-- Restore primary build's window title (compare entry's SetActiveSpec changes it)
			if self.primaryBuild.spec then
				self.primaryBuild.spec:SetWindowTitleWithBuildClass()
			end
		end
	end)
	self.controls.rightSpecSelect.shown = treeFooterShown
	self.controls.rightSpecSelect.maxDroppedWidth = 500
	self.controls.rightSpecSelect.enableDroppedWidth = true

	self.controls.rightVersionSelect = new("DropDownControl", {"LEFT", self.controls.rightSpecSelect, "RIGHT"}, {4, 0, 100, 20}, self.treeVersionDropdownList, function(index, selected)
		local entry = self:GetActiveCompare()
		if entry and selected and selected.value and entry.spec then
			if selected.value ~= entry.spec.treeVersion then
				entry.treeTab:OpenVersionConvertPopup(selected.value, true)
			end
		end
	end)
	self.controls.rightVersionSelect.shown = treeFooterShown

	-- Right search (footer, side-by-side only)
	self.controls.rightTreeSearch = new("EditControl", {"TOPLEFT", self.controls.rightFooterAnchor, "TOPLEFT"}, {0, 0, 200, 20}, "", "Search", "%c", 100, function(buf)
		local entry = self:GetActiveCompare()
		if entry and entry.treeTab and entry.treeTab.viewer then
			entry.treeTab.viewer.searchStr = buf
		end
	end, nil, nil, true)
	self.controls.rightTreeSearch.shown = treeSideBySideShown

	-- Config view: "Copy Config from Compare Build" button
	self.controls.copyConfigBtn = new("ButtonControl", nil, {0, 0, 240, 20},
		"Copy Config from Compare Build",
		function() self:CopyCompareConfig() end)
	self.controls.copyConfigBtn.shown = function()
		return self.compareViewMode == "CONFIG" and self:GetActiveCompare() ~= nil
	end

	-- Config view: "Show All / Hide Ineligible" toggle button
	self.controls.configToggleBtn = new("ButtonControl", nil, {0, 0, 240, 20},
		function()
			return self.configToggle and "Hide Ineligible Configurations" or "Show All Configurations"
		end,
		function()
			self.configToggle = not self.configToggle
		end)
	self.controls.configToggleBtn.shown = function()
		return self.compareViewMode == "CONFIG" and self:GetActiveCompare() ~= nil
	end
end

-- Get a short display name from a build name (strips "AccountName - " prefix)
function CompareTabClass:GetShortBuildName(fullName)
	if not fullName then return "Your Build" end
	local dashPos = fullName:find(" %- ")
	if dashPos then
		return fullName:sub(dashPos + 3)
	end
	return fullName
end

-- Format a numeric value with separator and rounding
function CompareTabClass:FormatVal(val, p)
	return formatNumSep(tostring(round(val, p)))
end

-- Resolve format strings against an actor's output/modDB
-- Handles: {output:Key}, {p:output:Key}, {p:mod:indices}
function CompareTabClass:FormatStr(str, actor, colData)
	if not actor then return "" end
	str = str:gsub("{output:([%a%.:]+)}", function(c)
		local ns, var = c:match("^(%a+)%.(%a+)$")
		if ns then
			return actor.output[ns] and actor.output[ns][var] or ""
		else
			return actor.output[c] or ""
		end
	end)
	str = str:gsub("{(%d+):output:([%a%.:]+)}", function(p, c)
		local ns, var = c:match("^(%a+)%.(%a+)$")
		if ns then
			return self:FormatVal(actor.output[ns] and actor.output[ns][var] or 0, tonumber(p))
		else
			return self:FormatVal(actor.output[c] or 0, tonumber(p))
		end
	end)
	str = str:gsub("{(%d+):mod:([%d,]+)}", function(p, n)
		local numList = { }
		for num in n:gmatch("%d+") do
			t_insert(numList, tonumber(num))
		end
		if not colData[numList[1]] or not colData[numList[1]].modType then
			return "?"
		end
		local modType = colData[numList[1]].modType
		local modTotal = modType == "MORE" and 1 or 0
		for _, num in ipairs(numList) do
			local sectionData = colData[num]
			if not sectionData then break end
			local modCfg = (sectionData.cfg and actor.mainSkill and actor.mainSkill[sectionData.cfg.."Cfg"]) or { }
			if sectionData.modSource then
				modCfg.source = sectionData.modSource
			end
			if sectionData.actor then
				modCfg.actor = sectionData.actor
			end
			local modVal
			local modStore = (sectionData.enemy and actor.enemy and actor.enemy.modDB) or (sectionData.cfg and actor.mainSkill and actor.mainSkill.skillModList) or actor.modDB
			if not modStore then break end
			if type(sectionData.modName) == "table" then
				modVal = modStore:Combine(sectionData.modType, modCfg, unpack(sectionData.modName))
			else
				modVal = modStore:Combine(sectionData.modType, modCfg, sectionData.modName)
			end
			if modType == "MORE" then
				modTotal = modTotal * modVal
			else
				modTotal = modTotal + modVal
			end
		end
		if modType == "MORE" then
			modTotal = (modTotal - 1) * 100
		end
		return self:FormatVal(modTotal, tonumber(p))
	end)
	return str
end

-- Check visibility flags for a section/row against an actor
function CompareTabClass:CheckCalcFlag(obj, actor)
	if not actor or not actor.mainSkill then return true end
	local skillFlags = actor.mainSkill.skillFlags or {}
	if obj.flag and not skillFlags[obj.flag] then
		return false
	end
	if obj.flagList then
		for _, flag in ipairs(obj.flagList) do
			if not skillFlags[flag] then
				return false
			end
		end
	end
	if obj.playerFlag and not skillFlags[obj.playerFlag] then
		return false
	end
	if obj.notFlag and skillFlags[obj.notFlag] then
		return false
	end
	if obj.notFlagList then
		for _, flag in ipairs(obj.notFlagList) do
			if skillFlags[flag] then
				return false
			end
		end
	end
	if obj.haveOutput then
		local ns, var = obj.haveOutput:match("^(%a+)%.(%a+)$")
		if ns then
			if not actor.output[ns] or not actor.output[ns][var] or actor.output[ns][var] == 0 then
				return false
			end
		elseif not actor.output[obj.haveOutput] or actor.output[obj.haveOutput] == 0 then
			return false
		end
	end
	return true
end

-- Format a config value for read-only display
function CompareTabClass:FormatConfigValue(varData, val)
	if val == nil then return "^8(not set)" end
	if varData.type == "check" then
		return val and (colorCodes.POSITIVE .. "Yes") or (colorCodes.NEGATIVE .. "No")
	elseif varData.type == "list" and varData.list then
		for _, item in ipairs(varData.list) do
			if item.val == val then
				return item.label or tostring(val)
			end
		end
		return tostring(val)
	else
		return tostring(val)
	end
end

-- Rebuild interactive config controls for all config options
function CompareTabClass:RebuildConfigControls(compareEntry)
	-- Remove old config controls
	for var, _ in pairs(self.configControls) do
		self.controls["cfg_" .. var] = nil
	end
	self.configControls = {}
	self.configControlList = {}

	if not compareEntry then return end

	local configOptions = LoadModule("Modules/ConfigOptions")
	local pInput = self.primaryBuild.configTab.input or {}
	local primaryBuild = self.primaryBuild

	for _, varData in ipairs(configOptions) do
		if varData.var and varData.type ~= "text" then
			local pVal = pInput[varData.var]
			local control
			if varData.type == "check" then
				control = new("CheckBoxControl", nil, {0, 0, 18}, nil, function(state)
					primaryBuild.configTab.input[varData.var] = state
					primaryBuild.configTab:UpdateControls()
					primaryBuild.configTab:BuildModList()
					primaryBuild.buildFlag = true
				end)
				control.state = pVal or false
			elseif varData.type == "count" or varData.type == "integer"
					or varData.type == "countAllowZero" or varData.type == "float" then
				local filter = (varData.type == "integer" and "^%-%d")
					or (varData.type == "float" and "^%d.") or "%D"
				control = new("EditControl", nil, {0, 0, 90, 18},
					tostring(pVal or ""), nil, filter, 7,
					function(buf)
						primaryBuild.configTab.input[varData.var] = tonumber(buf)
						primaryBuild.configTab:UpdateControls()
						primaryBuild.configTab:BuildModList()
						primaryBuild.buildFlag = true
					end)
			elseif varData.type == "list" and varData.list then
				control = new("DropDownControl", nil, {0, 0, 150, 18},
					varData.list, function(index, value)
						primaryBuild.configTab.input[varData.var] = value.val
						primaryBuild.configTab:UpdateControls()
						primaryBuild.configTab:BuildModList()
						primaryBuild.buildFlag = true
					end)
				control:SelByValue(pVal or (varData.list[1] and varData.list[1].val), "val")
			end

			if control then
				control.shown = function() return false end -- hidden until positioned
				self.controls["cfg_" .. varData.var] = control

				-- Determine eligibility category (matches ConfigTab's isShowAllConfig logic)
				local isHardConditional = varData.ifOption or varData.ifSkill
					or varData.ifSkillData or varData.ifSkillFlag or varData.legacy
				local isKeywordExcluded = false
				if varData.label then
					local labelLower = varData.label:lower()
					for _, kw in ipairs({"recently", "in the last", "in the past", "in last", "in past", "pvp"}) do
						if labelLower:find(kw) then
							isKeywordExcluded = true
							break
						end
					end
				end
				local hasAnyCondition = varData.ifCond or varData.ifOption or varData.ifSkill
					or varData.ifSkillFlag or varData.ifSkillData or varData.ifSkillList
					or varData.ifNode or varData.ifMod or varData.ifMult
					or varData.ifEnemyStat or varData.ifEnemyCond or varData.legacy

				local ctrlInfo = {
					control = control,
					varData = varData,
					visible = false,
					-- Always shown in "All Configurations" (no conditions at all)
					alwaysShow = not hasAnyCondition and not isKeywordExcluded,
					-- Shown in "All Configurations" when toggle is ON (simple conditions only)
					showWithToggle = not isHardConditional and not isKeywordExcluded,
				}
				self.configControls[varData.var] = ctrlInfo
				t_insert(self.configControlList, ctrlInfo)
			end
		end
	end
end

-- Copy all config settings from compare build to primary build
function CompareTabClass:CopyCompareConfig()
	local compareEntry = self:GetActiveCompare()
	if not compareEntry then return end
	local cInput = compareEntry.configTab.input
	for k, v in pairs(cInput) do
		self.primaryBuild.configTab.input[k] = v
	end
	self.primaryBuild.configTab:UpdateControls()
	self.primaryBuild.configTab:BuildModList()
	self.primaryBuild.buildFlag = true
	self.configNeedsRebuild = true
end

-- Import a comparison build from XML text
function CompareTabClass:ImportBuild(xmlText, label)
	local entry = new("CompareEntry", xmlText, label)
	if entry and entry.calcsTab and entry.calcsTab.mainOutput then
		t_insert(self.compareEntries, entry)
		self.activeCompareIndex = #self.compareEntries
		self:UpdateBuildSelector()
		return true
	end
	return false
end

-- Import a comparison build from a build code (base64-encoded)
function CompareTabClass:ImportFromCode(code)
	local xmlText = Inflate(common.base64.decode(code:gsub("-","+"):gsub("_","/")))
	if not xmlText then
		return false
	end
	return self:ImportBuild(xmlText, "Imported build")
end

-- Remove a comparison build
function CompareTabClass:RemoveBuild(index)
	if index >= 1 and index <= #self.compareEntries then
		t_remove(self.compareEntries, index)
		if self.activeCompareIndex > #self.compareEntries then
			self.activeCompareIndex = #self.compareEntries
		end
		if self.activeCompareIndex == 0 and #self.compareEntries > 0 then
			self.activeCompareIndex = 1
		end
		self:UpdateBuildSelector()
	end
end

-- Re-import primary build using character import (same as Import/Export tab)
function CompareTabClass:ReimportPrimary()
	local importTab = self.primaryBuild.importTab
	if not importTab then
		main:OpenMessagePopup("Re-import", "Import tab not available.")
		return
	end
	if importTab.charImportMode ~= "SELECTCHAR" then
		main:OpenMessagePopup("Re-import", "No character selected.\nGo to the Import/Export Build tab, enter your account name,\nand select a character first.")
		return
	end
	-- Set clear checkboxes to true (delete existing jewels, skills, equipment)
	importTab.controls.charImportTreeClearJewels.state = true
	importTab.controls.charImportItemsClearSkills.state = true
	importTab.controls.charImportItemsClearItems.state = true
	-- Trigger both async imports (passive tree + items/skills)
	importTab:DownloadPassiveTree()
	importTab:DownloadItems()
end

-- Update the build selector dropdown
function CompareTabClass:UpdateBuildSelector()
	local list = {}
	for i, entry in ipairs(self.compareEntries) do
		t_insert(list, entry.label or ("Build " .. i))
	end
	self.controls.compareBuildSelect.list = list
	if self.activeCompareIndex > 0 and self.activeCompareIndex <= #list then
		self.controls.compareBuildSelect.selIndex = self.activeCompareIndex
	end
end

-- Get the active comparison entry
function CompareTabClass:GetActiveCompare()
	if self.activeCompareIndex > 0 and self.activeCompareIndex <= #self.compareEntries then
		return self.compareEntries[self.activeCompareIndex]
	end
	return nil
end

-- Open the import popup for adding a comparison build
function CompareTabClass:OpenImportPopup()
	local controls = {}
	-- Use a local variable for state text so it doesn't go into the controls table
	-- (PopupDialog iterates all controls table entries and expects them to be control objects)
	local stateText = ""
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Paste a build code or URL to import as comparison:")
	controls.input = new("EditControl", nil, {0, 50, 450, 20}, "", nil, nil, nil, nil, nil, nil, true)
	controls.input.enterFunc = function()
		if controls.input.buf and controls.input.buf ~= "" then
			controls.go.onClick()
		end
	end
	controls.nameLabel = new("LabelControl", nil, {-175, 80, 0, 16}, "^7Name:")
	controls.name = new("EditControl", nil, {40, 80, 300, 20}, "", "Name (optional)", nil, 100, nil)
	controls.state = new("LabelControl", {"TOPLEFT", controls.name, "BOTTOMLEFT"}, {0, 4, 0, 16})
	controls.state.label = function()
		return stateText or ""
	end
	controls.go = new("ButtonControl", nil, {-45, 130, 80, 20}, "Import", function()
		local buf = controls.input.buf
		if not buf or buf == "" then
			return
		end
		local customName = controls.name.buf ~= "" and controls.name.buf or nil

		-- Check if it's a URL
		for _, site in ipairs(buildSites.websiteList) do
			if buf:match(site.matchURL) then
				stateText = colorCodes.WARNING .. "Downloading..."
				buildSites.DownloadBuild(buf, site, function(isSuccess, codeData)
					if isSuccess then
						local xmlText = Inflate(common.base64.decode(codeData:gsub("-","+"):gsub("_","/")))
						if xmlText then
							self:ImportBuild(xmlText, customName or ("Imported from " .. site.label))
							main:ClosePopup()
						else
							stateText = colorCodes.NEGATIVE .. "Failed to decode build data"
						end
					else
						stateText = colorCodes.NEGATIVE .. tostring(codeData)
					end
				end)
				return
			end
		end

		-- Try as a build code
		local xmlText = Inflate(common.base64.decode(buf:gsub("-","+"):gsub("_","/")))
		if xmlText then
			self:ImportBuild(xmlText, customName or "Imported build")
			main:ClosePopup()
		else
			stateText = colorCodes.NEGATIVE .. "Invalid build code"
		end
	end)
	controls.cancel = new("ButtonControl", nil, {45, 130, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 160, "Import Comparison Build", controls, "go", "input", "cancel")
end

-- ============================================================
-- DRAW - Main render method
-- ============================================================
function CompareTabClass:Draw(viewPort, inputEvents)
	local controlBarHeight = 96

	-- Position top-bar controls
	self.controls.subTabAnchor.x = viewPort.x + 4
	self.controls.subTabAnchor.y = viewPort.y + 74

	self.controls.compareBuildLabel.x = function()
		return 0
	end

	local contentVP = {
		x = viewPort.x,
		y = viewPort.y + controlBarHeight,
		width = viewPort.width,
		height = viewPort.height - controlBarHeight,
	}

	-- Get active comparison early (needed for footer positioning before ProcessControlsInput)
	local compareEntry = self:GetActiveCompare()

	-- Rebuild compare entry if its buildFlag is set (e.g. after version convert or spec change)
	if compareEntry and compareEntry.buildFlag then
		compareEntry:Rebuild()
	end

	-- Pre-draw tree footer backgrounds and position footer controls
	-- (must happen before ProcessControlsInput so controls render on top of backgrounds)
	self.treeLayout = nil
	if self.compareViewMode == "TREE" and compareEntry then
		local headerHeight = 50   -- spec/version selectors + overlay checkbox + separator
		local footerHeight = 30   -- search field(s)
		local footerY = contentVP.y + contentVP.height - footerHeight

		if self.treeOverlayMode then
			-- ========== OVERLAY MODE LAYOUT ==========
			local specWidth = m_min(m_floor(contentVP.width * 0.25), 200)

			self.treeLayout = {
				overlay = true,
				headerHeight = headerHeight,
				footerHeight = footerHeight,
				footerY = footerY,
			}

			-- Header background + separator
			SetDrawColor(0.05, 0.05, 0.05)
			DrawImage(nil, contentVP.x, contentVP.y, contentVP.width, headerHeight)
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, contentVP.x, contentVP.y + headerHeight - 2, contentVP.width, 2)

			-- Footer background
			SetDrawColor(0.05, 0.05, 0.05)
			DrawImage(nil, contentVP.x, footerY, contentVP.width, footerHeight)
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, contentVP.x, footerY, contentVP.width, 2)

			-- Position spec/version in header row 1
			self.controls.leftSpecSelect.x = contentVP.x + 4
			self.controls.leftSpecSelect.y = contentVP.y + 4
			self.controls.leftSpecSelect.width = specWidth

			local rightSpecX = contentVP.x + m_floor(contentVP.width / 2) + 4
			self.controls.rightSpecSelect.x = rightSpecX
			self.controls.rightSpecSelect.y = contentVP.y + 4
			self.controls.rightSpecSelect.width = specWidth

			-- Overlay checkbox in header row 2 (label draws LEFT of checkbox, needs ~140px clearance)
			self.controls.treeOverlayCheck.x = contentVP.x + 155
			self.controls.treeOverlayCheck.y = contentVP.y + 28

			-- Overlay search in footer (full width)
			self.controls.overlayTreeSearch.x = contentVP.x + 4
			self.controls.overlayTreeSearch.y = footerY + 4
			self.controls.overlayTreeSearch.width = contentVP.width - 8
		else
			-- ========== SIDE-BY-SIDE MODE LAYOUT ==========
			local halfWidth = m_floor(contentVP.width / 2) - 2
			local rightAbsX = contentVP.x + halfWidth + 4
			local specWidth = m_min(m_floor(halfWidth * 0.55), 200)

			self.treeLayout = {
				overlay = false,
				halfWidth = halfWidth,
				headerHeight = headerHeight,
				footerHeight = footerHeight,
				footerY = footerY,
				rightAbsX = rightAbsX,
			}

			-- Header background + separator
			SetDrawColor(0.05, 0.05, 0.05)
			DrawImage(nil, contentVP.x, contentVP.y, contentVP.width, headerHeight)
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, contentVP.x, contentVP.y + headerHeight - 2, contentVP.width, 2)

			-- Footer backgrounds (two halves)
			SetDrawColor(0.05, 0.05, 0.05)
			DrawImage(nil, contentVP.x, footerY, halfWidth, footerHeight)
			DrawImage(nil, rightAbsX, footerY, halfWidth, footerHeight)
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, contentVP.x, footerY, halfWidth, 2)
			DrawImage(nil, rightAbsX, footerY, halfWidth, 2)

			-- Position spec/version in header row 1
			self.controls.leftSpecSelect.x = contentVP.x + 4
			self.controls.leftSpecSelect.y = contentVP.y + 4
			self.controls.leftSpecSelect.width = specWidth

			self.controls.rightSpecSelect.x = contentVP.x + m_floor(contentVP.width / 2) + 4
			self.controls.rightSpecSelect.y = contentVP.y + 4
			self.controls.rightSpecSelect.width = specWidth

			-- Overlay checkbox in header row 2 (label draws LEFT of checkbox, needs ~140px clearance)
			self.controls.treeOverlayCheck.x = contentVP.x + 155
			self.controls.treeOverlayCheck.y = contentVP.y + 28

			-- Position footer search fields
			self.controls.leftFooterAnchor.x = contentVP.x + 4
			self.controls.leftFooterAnchor.y = footerY + 4
			self.controls.leftTreeSearch.width = halfWidth - 8

			self.controls.rightFooterAnchor.x = rightAbsX + 4
			self.controls.rightFooterAnchor.y = footerY + 4
			self.controls.rightTreeSearch.width = halfWidth - 8
		end

		-- (Common) Update spec dropdown lists
		if self.primaryBuild.treeTab then
			self.controls.leftSpecSelect.list = self.primaryBuild.treeTab:GetSpecList()
			self.controls.leftSpecSelect.selIndex = self.primaryBuild.treeTab.activeSpec
		end
		if compareEntry.treeTab then
			self.controls.rightSpecSelect.list = compareEntry.treeTab:GetSpecList()
			self.controls.rightSpecSelect.selIndex = compareEntry.treeTab.activeSpec
		end

		-- (Common) Update version dropdown selection to match current spec
		if self.primaryBuild.spec then
			for i, ver in ipairs(self.treeVersionDropdownList) do
				if ver.value == self.primaryBuild.spec.treeVersion then
					self.controls.leftVersionSelect.selIndex = i
					break
				end
			end
		end
		if compareEntry.spec then
			for i, ver in ipairs(self.treeVersionDropdownList) do
				if ver.value == compareEntry.spec.treeVersion then
					self.controls.rightVersionSelect.selIndex = i
					break
				end
			end
		end

		-- (Common) Sync search fields when entering tree mode or changing compare entry
		if self.treeSearchNeedsSync then
			self.treeSearchNeedsSync = false
			if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
				self.controls.leftTreeSearch:SetText(self.primaryBuild.treeTab.viewer.searchStr or "")
				self.controls.overlayTreeSearch:SetText(self.primaryBuild.treeTab.viewer.searchStr or "")
			end
			if compareEntry.treeTab and compareEntry.treeTab.viewer then
				self.controls.rightTreeSearch:SetText(compareEntry.treeTab.viewer.searchStr or "")
			end
		end
	end

	-- Position config controls when in CONFIG view
	if self.compareViewMode == "CONFIG" and compareEntry then
		-- Rebuild controls if compare entry changed or config was modified
		if self.configCompareId ~= self.activeCompareIndex or self.configNeedsRebuild then
			self:RebuildConfigControls(compareEntry)
			self.configCompareId = self.activeCompareIndex
			self.configNeedsRebuild = false
		end

		-- Sync control values with current primary input (in case changed from normal Config tab)
		local pInput = self.primaryBuild.configTab.input or {}
		for var, ctrlInfo in pairs(self.configControls) do
			local ctrl = ctrlInfo.control
			local varData = ctrlInfo.varData
			local pVal = pInput[var]
			if varData.type == "check" then
				ctrl.state = pVal or false
			elseif varData.type == "count" or varData.type == "integer"
					or varData.type == "countAllowZero" or varData.type == "float" then
				ctrl:SetText(tostring(pVal or ""))
			elseif varData.type == "list" then
				ctrl:SelByValue(pVal or (varData.list[1] and varData.list[1].val), "val")
			end
		end

		-- Position buttons at top of config view (above column headers)
		self.controls.copyConfigBtn.x = contentVP.x + 10
		self.controls.copyConfigBtn.y = contentVP.y + 4
		self.controls.configToggleBtn.x = contentVP.x + 260
		self.controls.configToggleBtn.y = contentVP.y + 4

		-- Build display list: Differences section first, then All Configurations
		local cInput = compareEntry.configTab.input or {}
		local displayList = {}
		local rowHeight = 22
		local sectionHeaderHeight = 24

		-- Collect differences
		local diffs = {}
		for _, ctrlInfo in ipairs(self.configControlList) do
			local pVal = pInput[ctrlInfo.varData.var]
			local cVal = cInput[ctrlInfo.varData.var]
			if tostring(pVal or "") ~= tostring(cVal or "") then
				t_insert(diffs, ctrlInfo)
			end
		end

		-- Differences section
		if #diffs > 0 then
			t_insert(displayList, { type = "header", text = "Differences (" .. #diffs .. ")" })
			for _, ctrlInfo in ipairs(diffs) do
				t_insert(displayList, { type = "row", ctrlInfo = ctrlInfo })
			end
		end

		-- Collect eligible non-diff options for "All Configurations" section
		local configs = {}
		for _, ctrlInfo in ipairs(self.configControlList) do
			local pVal = pInput[ctrlInfo.varData.var]
			local cVal = cInput[ctrlInfo.varData.var]
			-- Only include non-diff options
			if tostring(pVal or "") == tostring(cVal or "") then
				if ctrlInfo.alwaysShow or (self.configToggle and ctrlInfo.showWithToggle) then
					t_insert(configs, ctrlInfo)
				end
			end
		end

		if #configs > 0 then
			t_insert(displayList, { type = "header", text = "All Configurations" })
			for _, ctrlInfo in ipairs(configs) do
				t_insert(displayList, { type = "row", ctrlInfo = ctrlInfo })
			end
		end

		self.configDisplayList = displayList

		-- First, hide ALL config controls (will selectively show visible ones)
		for _, ctrlInfo in ipairs(self.configControlList) do
			ctrlInfo.control.shown = function() return false end
		end

		-- Position visible controls at absolute coords matching DrawConfig layout
		local col2AbsX = contentVP.x + 300
		local fixedHeaderHeight = 58 -- buttons + column headers + separator (not scrollable)
		local scrollTopAbs = contentVP.y + fixedHeaderHeight -- top of scrollable area
		local startY = fixedHeaderHeight -- content starts after fixed header
		local currentY = startY
		for _, item in ipairs(displayList) do
			if item.type == "header" then
				currentY = currentY + sectionHeaderHeight
			elseif item.type == "row" then
				local absY = contentVP.y + currentY - self.scrollY
				item.ctrlInfo.control.x = col2AbsX
				item.ctrlInfo.control.y = absY
				local cy = currentY -- capture for closure
				item.ctrlInfo.control.shown = function()
					local ay = contentVP.y + cy - self.scrollY
					return ay >= scrollTopAbs - 20 and ay < contentVP.y + contentVP.height
						and self.compareViewMode == "CONFIG" and self:GetActiveCompare() ~= nil
				end
				currentY = currentY + rowHeight
			end
		end
	end

	-- Update comparison build set selectors
	if compareEntry then
		-- Tree spec list (reuse GetSpecList from TreeTab)
		if compareEntry.treeTab then
			self.controls.compareSpecSelect.list = compareEntry.treeTab:GetSpecList()
			self.controls.compareSpecSelect.selIndex = compareEntry.treeTab.activeSpec
		end
		-- Skill set list (pattern from SkillsTab:Draw lines 527-535)
		if compareEntry.skillsTab then
			local skillList = {}
			for index, skillSetId in ipairs(compareEntry.skillsTab.skillSetOrderList) do
				local skillSet = compareEntry.skillsTab.skillSets[skillSetId]
				t_insert(skillList, skillSet.title or "Default")
				if skillSetId == compareEntry.skillsTab.activeSkillSetId then
					self.controls.compareSkillSetSelect.selIndex = index
				end
			end
			self.controls.compareSkillSetSelect:SetList(skillList)
		end
		-- Item set list (pattern from ItemsTab:Draw lines 1293-1301)
		if compareEntry.itemsTab then
			local itemList = {}
			for index, itemSetId in ipairs(compareEntry.itemsTab.itemSetOrderList) do
				local itemSet = compareEntry.itemsTab.itemSets[itemSetId]
				t_insert(itemList, itemSet.title or "Default")
				if itemSetId == compareEntry.itemsTab.activeItemSetId then
					self.controls.compareItemSetSelect.selIndex = index
				end
			end
			self.controls.compareItemSetSelect:SetList(itemList)
		end

		-- Refresh comparison build skill selector controls
		local cmpControls = {
			mainSocketGroup = self.controls.cmpSocketGroup,
			mainSkill = self.controls.cmpMainSkill,
			mainSkillPart = self.controls.cmpSkillPart,
			mainSkillStageCount = self.controls.cmpStageCount,
			mainSkillMineCount = self.controls.cmpMineCount,
			mainSkillMinion = self.controls.cmpMinion,
			mainSkillMinionLibrary = { shown = false },
			mainSkillMinionSkill = self.controls.cmpMinionSkill,
		}
		compareEntry:RefreshSkillSelectControls(cmpControls, compareEntry.mainSocketGroup, "")
	end

	-- Handle scroll events for scrollable views
	local cursorX, cursorY = GetCursorPos()
	local mouseInContent = cursorX >= contentVP.x and cursorX < contentVP.x + contentVP.width
		and cursorY >= contentVP.y and cursorY < contentVP.y + contentVP.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" and mouseInContent then
			if event.key == "WHEELUP" and self.compareViewMode ~= "TREE" then
				self.scrollY = m_max(self.scrollY - 40, 0)
				inputEvents[id] = nil
			elseif event.key == "WHEELDOWN" and self.compareViewMode ~= "TREE" then
				self.scrollY = self.scrollY + 40
				inputEvents[id] = nil
			end
		end
	end

	-- Process input events for our controls (including footer controls)
	self:ProcessControlsInput(inputEvents, viewPort)

	-- Draw TREE view BEFORE controls so header dropdowns render on top of the tree
	if self.compareViewMode == "TREE" and compareEntry then
		self:DrawTree(contentVP, inputEvents, compareEntry)

		-- Elevate to main draw layer 1 (matching TreeTab pattern) so controls
		-- render above all tree sublayers (tree uses sublayers up to 100)
		SetDrawLayer(1)

		-- Redraw header + footer backgrounds at this higher layer to cover any
		-- tree artifacts that bled into those regions via high sublayers
		local layout = self.treeLayout
		if layout then
			SetDrawColor(0.05, 0.05, 0.05)
			DrawImage(nil, contentVP.x, contentVP.y, contentVP.width, layout.headerHeight)
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, contentVP.x, contentVP.y + layout.headerHeight - 2, contentVP.width, 2)
			SetDrawColor(0.05, 0.05, 0.05)
			DrawImage(nil, contentVP.x, layout.footerY, contentVP.width, layout.footerHeight)
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, contentVP.x, layout.footerY, contentVP.width, 2)
		end
	end

	-- Draw controls (at main layer 1 when in TREE mode, above all tree content)
	self:DrawControls(viewPort)

	-- Reset to default draw layer after controls
	if self.compareViewMode == "TREE" and compareEntry then
		SetDrawLayer(0)
	end

	if not compareEntry then
		-- No comparison build loaded - show instructions
		SetViewport(contentVP.x, contentVP.y, contentVP.width, contentVP.height)
		SetDrawColor(1, 1, 1)
		DrawString(0, 40, "CENTER", 20, "VAR",
			"^7No comparison build loaded.")
		DrawString(0, 70, "CENTER", 16, "VAR",
			"^7Click " .. colorCodes.POSITIVE .. "Import..." .. "^7 above to import a build to compare against,")
		DrawString(0, 90, "CENTER", 16, "VAR",
			"^7or use the " .. colorCodes.POSITIVE .. "Import/Export Build" .. "^7 tab with \"Import as comparison\" mode.")
		SetViewport()
		return
	end

	-- Dispatch to sub-view (TREE already drawn above)
	if self.compareViewMode == "SUMMARY" then
		self:DrawSummary(contentVP, compareEntry)
	elseif self.compareViewMode == "ITEMS" then
		self:DrawItems(contentVP, compareEntry)
	elseif self.compareViewMode == "SKILLS" then
		self:DrawSkills(contentVP, compareEntry)
	elseif self.compareViewMode == "CALCS" then
		self:DrawCalcs(contentVP, compareEntry)
	elseif self.compareViewMode == "CONFIG" then
		self:DrawConfig(contentVP, compareEntry)
	end
end

-- ============================================================
-- SUMMARY VIEW
-- ============================================================
function CompareTabClass:DrawSummary(vp, compareEntry)
	local primaryOutput = self.primaryBuild.calcsTab.mainOutput
	local compareOutput = compareEntry:GetOutput()
	if not primaryOutput or not compareOutput then
		return
	end

	local lineHeight = 18
	local headerHeight = 22

	-- Column positions
	local col1 = 10   -- Stat name
	local col2 = 300  -- Primary value
	local col3 = 450  -- Compare value
	local col4 = 600  -- Difference

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(col1, drawY, "LEFT", headerHeight, "VAR", "^7Stat")
	DrawString(col2, drawY, "LEFT", headerHeight, "VAR", colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(col3, drawY, "LEFT", headerHeight, "VAR", colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	DrawString(col4, drawY, "LEFT", headerHeight, "VAR", "^7Difference")
	drawY = drawY + headerHeight + 4

	-- Separator
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 6

	-- Stat comparison
	local displayStats = self.primaryBuild.displayStats
	local primaryEnv = self.primaryBuild.calcsTab.mainEnv
	local compareEnv = compareEntry.calcsTab.mainEnv

	drawY = self:DrawStatList(drawY, vp, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, col1, col2, col3, col4)

	SetViewport()
end

function CompareTabClass:DrawProgressSection(drawY, colWidth, vp, compareEntry)
	local lineHeight = 16

	-- Count matching passive nodes
	local primaryNodes = self.primaryBuild.spec and self.primaryBuild.spec.allocNodes or {}
	local compareNodes = compareEntry.spec and compareEntry.spec.allocNodes or {}
	local primaryCount = 0
	local compareCount = 0
	local matchCount = 0
	for nodeId, _ in pairs(primaryNodes) do
		if type(nodeId) == "number" and nodeId < 65536 then -- Exclude special nodes
			primaryCount = primaryCount + 1
			if compareNodes[nodeId] then
				matchCount = matchCount + 1
			end
		end
	end
	for nodeId, _ in pairs(compareNodes) do
		if type(nodeId) == "number" and nodeId < 65536 then
			compareCount = compareCount + 1
		end
	end

	-- Count matching items
	local primaryItemCount = 0
	local compareItemCount = 0
	local matchingItemCount = 0
	if self.primaryBuild.itemsTab and compareEntry.itemsTab then
		local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt" }
		for _, slotName in ipairs(baseSlots) do
			local pSlot = self.primaryBuild.itemsTab.slots[slotName]
			local cSlot = compareEntry.itemsTab.slots[slotName]
			local pItem = pSlot and self.primaryBuild.itemsTab.items[pSlot.selItemId]
			local cItem = cSlot and compareEntry.itemsTab.items[cSlot.selItemId]
			if pItem then primaryItemCount = primaryItemCount + 1 end
			if cItem then compareItemCount = compareItemCount + 1 end
			if pItem and cItem and pItem.name == cItem.name then
				matchingItemCount = matchingItemCount + 1
			end
		end
	end

	-- Count matching gems
	local primaryGemCount = 0
	local compareGemCount = 0
	local matchingGemCount = 0
	if self.primaryBuild.skillsTab and compareEntry.skillsTab then
		local pGems = {}
		for _, group in ipairs(self.primaryBuild.skillsTab.socketGroupList) do
			for _, gem in ipairs(group.gemList) do
				if gem.grantedEffect then
					pGems[gem.grantedEffect.name] = true
					primaryGemCount = primaryGemCount + 1
				end
			end
		end
		for _, group in ipairs(compareEntry.skillsTab.socketGroupList) do
			for _, gem in ipairs(group.gemList) do
				if gem.grantedEffect then
					compareGemCount = compareGemCount + 1
					if pGems[gem.grantedEffect.name] then
						matchingGemCount = matchingGemCount + 1
					end
				end
			end
		end
	end

	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", 18, "VAR", "^7Progress toward comparison build:")
	drawY = drawY + 22

	-- Nodes progress
	local nodePercent = compareCount > 0 and m_floor(matchCount / compareCount * 100) or 0
	local nodeColor = nodePercent >= 90 and colorCodes.POSITIVE or nodePercent >= 50 and colorCodes.WARNING or colorCodes.NEGATIVE
	DrawString(20, drawY, "LEFT", lineHeight, "VAR",
		s_format("^7Passive Nodes: %s%d^7/%d matched (%s%d%%^7) - You: %d, Target: %d", nodeColor, matchCount, compareCount, nodeColor, nodePercent, primaryCount, compareCount))
	drawY = drawY + lineHeight + 2

	-- Items progress
	local itemPercent = compareItemCount > 0 and m_floor(matchingItemCount / compareItemCount * 100) or 0
	local itemColor = itemPercent >= 90 and colorCodes.POSITIVE or itemPercent >= 50 and colorCodes.WARNING or colorCodes.NEGATIVE
	DrawString(20, drawY, "LEFT", lineHeight, "VAR",
		s_format("^7Items: %s%d^7/%d matching (%s%d%%^7)", itemColor, matchingItemCount, compareItemCount, itemColor, itemPercent))
	drawY = drawY + lineHeight + 2

	-- Gems progress
	local gemPercent = compareGemCount > 0 and m_floor(matchingGemCount / compareGemCount * 100) or 0
	local gemColor = gemPercent >= 90 and colorCodes.POSITIVE or gemPercent >= 50 and colorCodes.WARNING or colorCodes.NEGATIVE
	DrawString(20, drawY, "LEFT", lineHeight, "VAR",
		s_format("^7Gems: %s%d^7/%d matching (%s%d%%^7)", gemColor, matchingGemCount, compareGemCount, gemColor, gemPercent))
	drawY = drawY + lineHeight + 2

	return drawY
end

function CompareTabClass:DrawStatList(drawY, vp, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, col1, col2, col3, col4)
	local lineHeight = 16

	-- Get skill flags from both builds for stat filtering
	local primaryFlags = primaryEnv and primaryEnv.player and primaryEnv.player.mainSkill and primaryEnv.player.mainSkill.skillFlags or {}
	local compareFlags = compareEnv and compareEnv.player and compareEnv.player.mainSkill and compareEnv.player.mainSkill.skillFlags or {}

	for _, statData in ipairs(displayStats) do
		if not statData.stat and not statData.label then
			-- Empty entry = section spacer (matches sidebar behavior)
			drawY = drawY + 6
		elseif statData.stat == "SkillDPS" then
			-- Skip: multi-row SkillDPS doesn't fit compare layout
		elseif statData.hideStat then
			-- Skip: hidden stats
		elseif not matchFlags(statData.flag, statData.notFlag, primaryFlags)
		   and not matchFlags(statData.flag, statData.notFlag, compareFlags) then
			-- Skip: stat not relevant to either build's active skill
		elseif statData.stat then
			-- Normal stat with value
			local primaryVal = primaryOutput[statData.stat] or 0
			local compareVal = compareOutput[statData.stat] or 0

			-- Handle childStat (e.g. MainHand.Accuracy)
			if statData.childStat then
				primaryVal = type(primaryVal) == "table" and primaryVal[statData.childStat] or 0
				compareVal = type(compareVal) == "table" and compareVal[statData.childStat] or 0
			end

			-- Skip table-type stat values
			if type(primaryVal) == "table" or type(compareVal) == "table" then
				primaryVal = 0
				compareVal = 0
			end

			-- Skip zero-value stats, check condFunc
			if (primaryVal ~= 0 or compareVal ~= 0) and
			   (not statData.condFunc or statData.condFunc(primaryVal, primaryOutput) or statData.condFunc(compareVal, compareOutput)) then
				-- Format values
				local fmt = statData.fmt or "d"
				local multiplier = (statData.pc or statData.mod) and 100 or 1
				local primaryStr = s_format("%"..fmt, primaryVal * multiplier)
				local compareStr = s_format("%"..fmt, compareVal * multiplier)
				primaryStr = formatNumSep(primaryStr)
				compareStr = formatNumSep(compareStr)

				-- Determine diff color and string
				local diff = compareVal - primaryVal
				local diffStr = ""
				local diffColor = "^7"
				if diff > 0.001 or diff < -0.001 then
					local isBetter = (statData.lowerIsBetter and diff < 0) or (not statData.lowerIsBetter and diff > 0)
					diffColor = isBetter and colorCodes.POSITIVE or colorCodes.NEGATIVE
					local diffVal = diff * multiplier
					diffStr = s_format("%+"..fmt, diffVal)
					diffStr = formatNumSep(diffStr)
					-- Add percentage if primary value is non-zero
					if primaryVal ~= 0 then
						local pc = compareVal / primaryVal * 100 - 100
						diffStr = diffStr .. s_format(" (%+.1f%%)", pc)
					end
				end

				-- Draw stat row
				local labelColor = statData.color or "^7"
				DrawString(col1, drawY, "LEFT", lineHeight, "VAR", labelColor .. (statData.label or statData.stat))
				DrawString(col2, drawY, "LEFT", lineHeight, "VAR", "^7" .. primaryStr)
				DrawString(col3, drawY, "LEFT", lineHeight, "VAR", diffColor .. compareStr)
				if diffStr ~= "" then
					DrawString(col4, drawY, "LEFT", lineHeight, "VAR", diffColor .. diffStr)
				end
				drawY = drawY + lineHeight + 1
			end
		elseif statData.label and statData.condFunc then
			-- Label-only stat (e.g. "Chaos Resistance: Immune")
			local labelColor = statData.color or "^7"
			if statData.condFunc(primaryOutput) or statData.condFunc(compareOutput) then
				local valStr = statData.val or ""
				local primaryShown = statData.condFunc(primaryOutput)
				local compareShown = statData.condFunc(compareOutput)
				DrawString(col1, drawY, "LEFT", lineHeight, "VAR", labelColor .. statData.label)
				DrawString(col2, drawY, "LEFT", lineHeight, "VAR", "^7" .. (primaryShown and valStr or "-"))
				DrawString(col3, drawY, "LEFT", lineHeight, "VAR", "^7" .. (compareShown and valStr or "-"))
				drawY = drawY + lineHeight + 1
			end
		end
	end
	return drawY
end

-- ============================================================
-- TREE VIEW (overlay + side-by-side)
-- ============================================================
function CompareTabClass:DrawTree(vp, inputEvents, compareEntry)
	local layout = self.treeLayout
	if not layout then return end

	local headerHeight = layout.headerHeight
	local footerHeight = layout.footerHeight
	local origGetCursorPos = GetCursorPos

	if layout.overlay then
		-- ========== OVERLAY MODE ==========
		-- Uses the primary build's viewer with compareSpec set to the compare entry's spec.
		-- PassiveTreeView automatically renders green (added), red (removed), blue (mastery differs).
		local treeAbsX = vp.x
		local treeAbsY = vp.y + headerHeight
		local treeHeight = vp.height - headerHeight - footerHeight

		if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
			-- Set compareSpec to enable overlay coloring
			self.primaryBuild.treeTab.viewer.compareSpec = compareEntry.spec

			SetViewport(treeAbsX, treeAbsY, vp.width, treeHeight)
			SetDrawLayer(nil, 0)
			GetCursorPos = function()
				local x, y = origGetCursorPos()
				return x - treeAbsX, y - treeAbsY
			end
			local treeVP = { x = 0, y = 0, width = vp.width, height = treeHeight }
			self.primaryBuild.treeTab.viewer:Draw(self.primaryBuild, treeVP, inputEvents)
			SetViewport()

			-- Clear compareSpec so it doesn't affect the normal Tree tab
			self.primaryBuild.treeTab.viewer.compareSpec = nil
		end

		GetCursorPos = origGetCursorPos
		return
	end

	-- ========== SIDE-BY-SIDE MODE ==========
	local halfWidth = layout.halfWidth
	local treeHeight = vp.height - headerHeight - footerHeight

	-- Divider (from header bottom to viewport bottom)
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, vp.x + halfWidth, vp.y + headerHeight, 4, vp.height - headerHeight)

	-- Route input events to the panel containing the mouse
	local mouseX, mouseY = origGetCursorPos()
	local leftHasInput = mouseX < (vp.x + halfWidth + 2)

	-- Left tree: SetViewport clips drawing; patch GetCursorPos so mouse coords
	-- are viewport-relative (matching the {x=0,y=0} viewport passed to the tree)
	local leftAbsX = vp.x
	local leftAbsY = vp.y + headerHeight
	if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
		SetViewport(leftAbsX, leftAbsY, halfWidth, treeHeight)
		SetDrawLayer(nil, 0)
		GetCursorPos = function()
			local x, y = origGetCursorPos()
			return x - leftAbsX, y - leftAbsY
		end
		local leftTreeVP = { x = 0, y = 0, width = halfWidth, height = treeHeight }
		self.primaryBuild.treeTab.viewer:Draw(self.primaryBuild, leftTreeVP, leftHasInput and inputEvents or {})
		SetViewport()
	end

	-- Right tree: same approach - SetViewport for clipping, patched cursor
	local rightAbsX = vp.x + halfWidth + 4
	local rightAbsY = vp.y + headerHeight
	if compareEntry.treeTab and compareEntry.treeTab.viewer then
		SetViewport(rightAbsX, rightAbsY, halfWidth, treeHeight)
		SetDrawLayer(nil, 0)
		GetCursorPos = function()
			local x, y = origGetCursorPos()
			return x - rightAbsX, y - rightAbsY
		end
		local rightTreeVP = { x = 0, y = 0, width = halfWidth, height = treeHeight }
		compareEntry.treeTab.viewer:Draw(compareEntry, rightTreeVP, leftHasInput and {} or inputEvents)
		SetViewport()
	end

	-- Restore original GetCursorPos
	GetCursorPos = origGetCursorPos
end

-- ============================================================
-- ITEMS VIEW
-- ============================================================
function CompareTabClass:DrawItems(vp, compareEntry)
	local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt" }
	local lineHeight = 20
	local slotHeight = 46
	local colWidth = m_floor(vp.width / 2)

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Get cursor position relative to viewport for hover detection
	local cursorX, cursorY = GetCursorPos()
	cursorX = cursorX - vp.x
	cursorY = cursorY - vp.y
	local hoverItem = nil
	local hoverX, hoverY = 0, 0
	local hoverW, hoverH = 0, 0
	local hoverItemsTab = nil

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", 18, "VAR", colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(colWidth + 10, drawY, "LEFT", 18, "VAR", colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	drawY = drawY + 24

	for _, slotName in ipairs(baseSlots) do
		-- Separator
		SetDrawColor(0.3, 0.3, 0.3)
		DrawImage(nil, 4, drawY, vp.width - 8, 1)
		drawY = drawY + 2

		-- Slot label
		SetDrawColor(1, 1, 1)
		DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. slotName .. ":")

		-- Get items from both builds
		local pSlot = self.primaryBuild.itemsTab and self.primaryBuild.itemsTab.slots and self.primaryBuild.itemsTab.slots[slotName]
		local cSlot = compareEntry.itemsTab and compareEntry.itemsTab.slots and compareEntry.itemsTab.slots[slotName]
		local pItem = pSlot and self.primaryBuild.itemsTab.items and self.primaryBuild.itemsTab.items[pSlot.selItemId]
		local cItem = cSlot and compareEntry.itemsTab and compareEntry.itemsTab.items and compareEntry.itemsTab.items[cSlot.selItemId]

		local pName = pItem and pItem.name or "(empty)"
		local cName = cItem and cItem.name or "(empty)"

		-- Color code by rarity
		local pColor = "^7"
		if pItem then
			if pItem.rarity == "UNIQUE" then pColor = colorCodes.UNIQUE
			elseif pItem.rarity == "RARE" then pColor = colorCodes.RARE
			elseif pItem.rarity == "MAGIC" then pColor = colorCodes.MAGIC
			else pColor = colorCodes.NORMAL end
		end
		local cColor = "^7"
		if cItem then
			if cItem.rarity == "UNIQUE" then cColor = colorCodes.UNIQUE
			elseif cItem.rarity == "RARE" then cColor = colorCodes.RARE
			elseif cItem.rarity == "MAGIC" then cColor = colorCodes.MAGIC
			else cColor = colorCodes.NORMAL end
		end

		drawY = drawY + 18

		-- Draw item names
		DrawString(20, drawY, "LEFT", 16, "VAR", pColor .. pName)
		DrawString(colWidth + 20, drawY, "LEFT", 16, "VAR", cColor .. cName)

		-- Check hover on primary item (left column)
		if pItem and cursorX >= 10 and cursorX < colWidth
		   and cursorY >= drawY and cursorY < drawY + 18 then
			hoverItem = pItem
			hoverX = 20
			hoverY = drawY
			hoverW = colWidth - 30
			hoverH = 18
			hoverItemsTab = self.primaryBuild.itemsTab
		end

		-- Check hover on compare item (right column)
		if cItem and cursorX >= colWidth and cursorX < vp.width
		   and cursorY >= drawY and cursorY < drawY + 18 then
			hoverItem = cItem
			hoverX = colWidth + 20
			hoverY = drawY
			hoverW = colWidth - 30
			hoverH = 18
			hoverItemsTab = compareEntry.itemsTab
		end

		-- Show diff indicator
		local isSame = pItem and cItem and pItem.name == cItem.name
		local diffLabel = ""
		if not pItem and not cItem then
			diffLabel = "^8(both empty)"
		elseif isSame then
			diffLabel = colorCodes.POSITIVE .. "(match)"
		elseif not pItem then
			diffLabel = colorCodes.NEGATIVE .. "(missing)"
		elseif not cItem then
			diffLabel = colorCodes.TIP .. "(extra)"
		else
			diffLabel = colorCodes.WARNING .. "(different)"
		end
		DrawString(colWidth - 10, drawY, "RIGHT", 14, "VAR", diffLabel)

		drawY = drawY + 20
	end

	-- Draw item tooltip on hover (on top of everything)
	if hoverItem and hoverItemsTab then
		self.itemTooltip:Clear()
		hoverItemsTab:AddItemTooltip(self.itemTooltip, hoverItem, nil)
		SetDrawLayer(nil, 100)
		self.itemTooltip:Draw(hoverX, hoverY, hoverW, hoverH, vp)
		SetDrawLayer(nil, 0)
	end

	SetViewport()
end

-- ============================================================
-- SKILLS VIEW
-- ============================================================
function CompareTabClass:DrawSkills(vp, compareEntry)
	local lineHeight = 18
	local colWidth = m_floor(vp.width / 2)

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", 18, "VAR", colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName) .. " - Socket Groups")
	DrawString(colWidth + 10, drawY, "LEFT", 18, "VAR", colorCodes.WARNING .. (compareEntry.label or "Compare Build") .. " - Socket Groups")
	drawY = drawY + 24

	-- Get socket groups from both builds
	local pGroups = self.primaryBuild.skillsTab and self.primaryBuild.skillsTab.socketGroupList or {}
	local cGroups = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList or {}

	-- Helper: get the set of gem names in a socket group
	local function getGemNameSet(group)
		local set = {}
		for _, gem in ipairs(group.gemList or {}) do
			local name = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec
			if name then
				set[name] = true
			end
		end
		return set
	end

	-- Helper: compute Jaccard similarity between two gem name sets
	local function groupSimilarity(setA, setB)
		local intersection = 0
		local union = 0
		local allKeys = {}
		for k in pairs(setA) do allKeys[k] = true end
		for k in pairs(setB) do allKeys[k] = true end
		for k in pairs(allKeys) do
			union = union + 1
			if setA[k] and setB[k] then
				intersection = intersection + 1
			end
		end
		if union == 0 then return 0 end
		return intersection / union
	end

	-- Build gem name sets for all groups
	local pSets = {}
	for i, group in ipairs(pGroups) do
		pSets[i] = getGemNameSet(group)
	end
	local cSets = {}
	for i, group in ipairs(cGroups) do
		cSets[i] = getGemNameSet(group)
	end

	-- Compute all pairwise similarity scores
	local scorePairs = {}
	for pi = 1, #pGroups do
		for ci = 1, #cGroups do
			local score = groupSimilarity(pSets[pi], cSets[ci])
			if score > 0 then
				t_insert(scorePairs, { pIdx = pi, cIdx = ci, score = score })
			end
		end
	end

	-- Sort by similarity descending (best matches first)
	table.sort(scorePairs, function(a, b) return a.score > b.score end)

	-- Greedy matching: assign best pairs first, each group used at most once
	local pMatched = {}
	local cMatched = {}
	local renderPairs = {}
	for _, sp in ipairs(scorePairs) do
		if not pMatched[sp.pIdx] and not cMatched[sp.cIdx] then
			t_insert(renderPairs, { pIdx = sp.pIdx, cIdx = sp.cIdx })
			pMatched[sp.pIdx] = true
			cMatched[sp.cIdx] = true
		end
	end

	-- Add unmatched primary groups
	for i = 1, #pGroups do
		if not pMatched[i] then
			t_insert(renderPairs, { pIdx = i, cIdx = nil })
		end
	end
	-- Add unmatched compare groups
	for i = 1, #cGroups do
		if not cMatched[i] then
			t_insert(renderPairs, { pIdx = nil, cIdx = i })
		end
	end

	-- Draw matched pairs
	for _, pair in ipairs(renderPairs) do
		SetDrawColor(0.3, 0.3, 0.3)
		DrawImage(nil, 4, drawY, vp.width - 8, 1)
		drawY = drawY + 2

		-- Primary group (left side)
		local pGroup = pair.pIdx and pGroups[pair.pIdx]
		if pGroup then
			local groupLabel = pGroup.displayLabel or pGroup.label or ("Group " .. pair.pIdx)
			if pGroup.slot then
				groupLabel = groupLabel .. " (" .. pGroup.slot .. ")"
			end
			DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. groupLabel)
			local gemY = drawY + lineHeight
			for _, gem in ipairs(pGroup.gemList or {}) do
				local gemName = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec or "?"
				local gemColor = gem.color or colorCodes.GEM
				local levelStr = gem.level and (" Lv" .. gem.level) or ""
				local qualStr = gem.quality and gem.quality > 0 and ("/" .. gem.quality .. "q") or ""
				DrawString(20, gemY, "LEFT", 14, "VAR", gemColor .. gemName .. "^7" .. levelStr .. qualStr)
				gemY = gemY + 16
			end
		end

		-- Compare group (right side)
		local cGroup = pair.cIdx and cGroups[pair.cIdx]
		if cGroup then
			local groupLabel = cGroup.displayLabel or cGroup.label or ("Group " .. pair.cIdx)
			if cGroup.slot then
				groupLabel = groupLabel .. " (" .. cGroup.slot .. ")"
			end
			DrawString(colWidth + 10, drawY, "LEFT", 16, "VAR", "^7" .. groupLabel)
			local gemY = drawY + lineHeight
			for _, gem in ipairs(cGroup.gemList or {}) do
				local gemName = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec or "?"
				local gemColor = gem.color or colorCodes.GEM
				local levelStr = gem.level and (" Lv" .. gem.level) or ""
				local qualStr = gem.quality and gem.quality > 0 and ("/" .. gem.quality .. "q") or ""
				DrawString(colWidth + 20, gemY, "LEFT", 14, "VAR", gemColor .. gemName .. "^7" .. levelStr .. qualStr)
				gemY = gemY + 16
			end
		end

		-- Calculate height for this row
		local pGemCount = pGroup and #(pGroup.gemList or {}) or 0
		local cGemCount = cGroup and #(cGroup.gemList or {}) or 0
		local rowGems = m_max(pGemCount, cGemCount)
		drawY = drawY + lineHeight + rowGems * 16 + 6
	end

	SetViewport()
end

-- ============================================================
-- CALCS VIEW (card-based sections with comparison)
-- ============================================================
function CompareTabClass:DrawCalcs(vp, compareEntry)
	-- Get actors from both builds (use mainEnv, not calcsEnv, so skill dropdown is respected)
	local primaryEnv = self.primaryBuild.calcsTab.mainEnv
	local compareEnv = compareEntry.calcsTab and compareEntry.calcsTab.mainEnv
	if not primaryEnv or not compareEnv then return end
	local primaryActor = primaryEnv.player
	local compareActor = compareEnv.player
	if not primaryActor or not compareActor then return end

	-- Load section definitions (cached)
	if not self.calcSections then
		self.calcSections = LoadModule("Modules/CalcSections")
	end

	-- Card dimensions
	-- Layout: [2px border | 130px label | 2px gap | 2px sep | valW | 2px sep | valW | 2px border]
	local cardWidth = m_min(400, vp.width - 16)
	local labelWidth = 132
	local sepW = 2
	local valColWidth = m_floor((cardWidth - 140) / 2)
	local valCol1X = labelWidth + sepW * 2
	local valCol2X = valCol1X + valColWidth + sepW

	-- Layout parameters
	local maxCol = m_max(1, m_floor(vp.width / (cardWidth + 8)))
	local baseX = 4
	local headerBarHeight = 24
	local baseY = headerBarHeight

	-- Pre-compute section visibility and heights
	local sections = {}
	for _, secDef in ipairs(self.calcSections) do
		local secWidth, id, group, colour, subSections = secDef[1], secDef[2], secDef[3], secDef[4], secDef[5]
		local secData = subSections[1].data
		-- Check section-level flags against primary actor
		if self:CheckCalcFlag(secData, primaryActor) then
			local subSecInfo = {}
			local sectionHasRows = false
			for _, subSec in ipairs(subSections) do
				local rows = {}
				for _, rowData in ipairs(subSec.data) do
					-- Only include rows with a label and a first column with a format string
					if rowData.label and rowData[1] and rowData[1].format then
						if self:CheckCalcFlag(rowData, primaryActor) or self:CheckCalcFlag(rowData, compareActor) then
							t_insert(rows, rowData)
						end
					end
				end
				if #rows > 0 then
					t_insert(subSecInfo, { label = subSec.label, rows = rows, data = subSec.data })
					sectionHasRows = true
				end
			end
			if sectionHasRows then
				-- Calculate card height
				local height = 2
				for _, si in ipairs(subSecInfo) do
					height = height + 22 + #si.rows * 18
					if #si.rows > 0 then
						height = height + 2
					end
				end
				t_insert(sections, {
					id = id, group = group, colour = colour,
					subSecs = subSecInfo,
					height = height,
				})
			end
		end
	end

	-- Layout: place sections into shortest column
	local colY = {}
	local maxY = baseY
	for _, sec in ipairs(sections) do
		local col = 1
		local minY = colY[1] or baseY
		for c = 2, maxCol do
			if (colY[c] or baseY) < minY then
				col = c
				minY = colY[c] or baseY
			end
		end
		sec.drawX = baseX + (cardWidth + 8) * (col - 1)
		sec.drawY = colY[col] or baseY
		colY[col] = sec.drawY + sec.height + 8
		maxY = m_max(maxY, colY[col])
	end

	-- Set viewport for scroll clipping
	SetViewport(vp.x, vp.y, vp.width, vp.height)

	-- Draw header bar with build names
	local headerY = 4 - self.scrollY
	SetDrawColor(1, 1, 1)
	DrawString(baseX + valCol1X, headerY, "LEFT", 14, "VAR",
		colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(baseX + valCol2X, headerY, "LEFT", 14, "VAR",
		colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, headerY + 16, vp.width - 8, 1)

	-- Draw section cards
	for _, sec in ipairs(sections) do
		local x = sec.drawX
		local y = sec.drawY - self.scrollY

		-- Skip if entirely off-screen
		if y + sec.height >= 0 and y < vp.height then
			-- Draw border
			SetDrawLayer(nil, -10)
			SetDrawColor(sec.colour)
			DrawImage(nil, x, y, cardWidth, sec.height)
			-- Draw background
			SetDrawColor(0.10, 0.10, 0.10)
			DrawImage(nil, x + 2, y + 2, cardWidth - 4, sec.height - 4)
			SetDrawLayer(nil, 0)

			local lineY = y
			for _, subSec in ipairs(sec.subSecs) do
				-- Separator above header
				SetDrawColor(sec.colour)
				DrawImage(nil, x + 2, lineY, cardWidth - 4, 2)
				-- Header text
				DrawString(x + 3, lineY + 3, "LEFT", 16, "VAR BOLD", "^7" .. subSec.label .. ":")
				-- Show extra info (e.g. "4521/5000 | 3800/4200")
				if subSec.data and subSec.data.extra then
					local extraTextW = DrawStringWidth(16, "VAR BOLD", subSec.label .. ":")
					local extraX = x + 3 + extraTextW + 8
					local ok1, pExtra = pcall(self.FormatStr, self, subSec.data.extra, primaryActor)
					local ok2, cExtra = pcall(self.FormatStr, self, subSec.data.extra, compareActor)
					if ok1 and ok2 then
						DrawString(extraX, lineY + 3, "LEFT", 16, "VAR",
							colorCodes.POSITIVE .. pExtra .. "  ^8|  " .. colorCodes.WARNING .. cExtra)
					end
				end
				-- Separator below header
				SetDrawColor(sec.colour)
				DrawImage(nil, x + 2, lineY + 20, cardWidth - 4, 2)
				lineY = lineY + 22

				-- Draw rows
				for _, rowData in ipairs(subSec.rows) do
					local colData = rowData[1]
					local textSize = rowData.textSize or 14

					-- Label background and text
					SetDrawColor(rowData.bgCol or "^0")
					DrawImage(nil, x + 2, lineY, labelWidth - 2, 18)
					local textColor = rowData.color or "^7"
					DrawString(x + labelWidth, lineY + 1, "RIGHT_X", 16, "VAR", textColor .. rowData.label .. "^7:")

					-- Primary value column
					SetDrawColor(sec.colour)
					DrawImage(nil, x + valCol1X - sepW, lineY, sepW, 18)
					SetDrawColor(rowData.bgCol or "^0")
					DrawImage(nil, x + valCol1X, lineY, valColWidth, 18)
					if colData and colData.format then
						local ok, str = pcall(self.FormatStr, self, colData.format, primaryActor, colData)
						if ok and str then
							DrawString(x + valCol1X + 2, lineY + 9 - textSize / 2, "LEFT", textSize, "VAR", "^7" .. str)
						end
					end

					-- Compare value column
					SetDrawColor(sec.colour)
					DrawImage(nil, x + valCol2X - sepW, lineY, sepW, 18)
					SetDrawColor(rowData.bgCol or "^0")
					DrawImage(nil, x + valCol2X, lineY, valColWidth, 18)
					if colData and colData.format then
						local ok, str = pcall(self.FormatStr, self, colData.format, compareActor, colData)
						if ok and str then
							DrawString(x + valCol2X + 2, lineY + 9 - textSize / 2, "LEFT", textSize, "VAR", "^7" .. str)
						end
					end

					lineY = lineY + 18
				end
				if #subSec.rows > 0 then
					lineY = lineY + 2
				end
			end
		end
	end

	SetViewport()
end

-- ============================================================
-- CONFIG VIEW
-- ============================================================
function CompareTabClass:DrawConfig(vp, compareEntry)
	local rowHeight = 22
	local sectionHeaderHeight = 24
	local columnHeaderHeight = 20
	local fixedHeaderHeight = 58 -- buttons + column headers + separator (not scrollable)

	-- Column positions (viewport-relative)
	local col1 = 10
	local col2 = 300    -- primary value (interactive controls drawn by ControlHost)
	local col3 = 500    -- compare value (read-only)

	-- Fixed header area: buttons at top, then column headers + separator
	SetViewport(vp.x, vp.y, vp.width, fixedHeaderHeight)
	-- Buttons (Copy Config + Toggle) are drawn by ControlHost at y=4
	-- Column headers below buttons
	local colHeaderY = 28
	SetDrawColor(1, 1, 1)
	DrawString(col1, colHeaderY, "LEFT", columnHeaderHeight, "VAR", "^7Configuration Option")
	DrawString(col2, colHeaderY, "LEFT", columnHeaderHeight, "VAR",
		colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(col3, colHeaderY, "LEFT", columnHeaderHeight, "VAR",
		colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, colHeaderY + columnHeaderHeight + 4, vp.width - 8, 2)

	-- Scrollable content area (clipped below fixed header so content can't bleed through buttons)
	local scrollH = vp.height - fixedHeaderHeight
	if scrollH <= 0 then
		SetViewport()
		return
	end
	SetViewport(vp.x, vp.y + fixedHeaderHeight, vp.width, scrollH)

	local cInput = compareEntry.configTab.input or {}
	local currentY = 0 -- relative to scrollable viewport

	-- Draw from the computed display list (built in Draw())
	for _, item in ipairs(self.configDisplayList) do
		if item.type == "header" then
			local headerY = currentY - self.scrollY
			if headerY + sectionHeaderHeight >= 0 and headerY < scrollH then
				-- Section header text
				SetDrawColor(1, 1, 1)
				DrawString(col1, headerY + 4, "LEFT", 16, "VAR BOLD", "^7" .. item.text)
				-- Thin separator below header
				SetDrawColor(0.4, 0.4, 0.4)
				DrawImage(nil, col1, headerY + sectionHeaderHeight - 2, vp.width - col1 * 2, 1)
			end
			currentY = currentY + sectionHeaderHeight
		elseif item.type == "row" then
			local rowY = currentY - self.scrollY
			if rowY + rowHeight >= 0 and rowY < scrollH then
				local varData = item.ctrlInfo.varData
				-- Label (col1)
				SetDrawColor(1, 1, 1)
				DrawString(col1, rowY + 2, "LEFT", 16, "VAR", "^7" .. (varData.label or varData.var))
				-- Compare value (col3, read-only)
				local cVal = cInput[varData.var]
				local cStr = self:FormatConfigValue(varData, cVal)
				DrawString(col3, rowY + 2, "LEFT", 16, "VAR", "^7" .. cStr)
			end
			currentY = currentY + rowHeight
		end
	end

	if #self.configDisplayList == 0 then
		DrawString(10, -self.scrollY, "LEFT", 16, "VAR",
			colorCodes.POSITIVE .. "No configuration options to display.")
	end

	SetViewport()
end

return CompareTabClass
