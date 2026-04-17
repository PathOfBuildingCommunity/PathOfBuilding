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
local dkjson = require "dkjson"
local tradeHelpers = LoadModule("Classes/CompareTradeHelpers")
local buySimilar = LoadModule("Classes/CompareBuySimilar")
local calcsHelpers = LoadModule("Classes/CompareCalcsHelpers")
local buildListHelpers = LoadModule("Modules/BuildListHelpers")

-- Node IDs below this value are normal passive tree nodes; IDs at or above are cluster jewel nodes
local CLUSTER_NODE_OFFSET = 65536

-- Layout constants (shared across Draw, DrawConfig, DrawItems, DrawCalcs, etc.)
local LAYOUT = {
	-- Main tab control bar
	controlBarHeight = 126,

	-- Tree view header/footer
	treeHeaderHeight = 58,
	treeFooterHeight = 30,
	treeOverlayCheckX = 155,

	-- Summary view columns
	summaryCol1 = 10,
	summaryCol2Right = 440,
	summaryCol3Right = 580,
	summaryCol4 = 600,

	-- Items view
	itemsCheckboxOffset = 60,
	itemsCopyBtnW = 60,
	itemsCopyUseBtnW = 78,
	itemsCopyBtnH = 18,
	itemsBuyBtnW = 60,

	-- Calcs view
	calcsMaxCardWidth = 400,
	calcsLabelWidth = 132,
	calcsSepW = 2,
	calcsHeaderBarHeight = 24,

	-- Power report section (inside Summary view)
	powerReportLeft = 10,

	-- Config view (shared between Draw() layout and DrawConfig())
	configRowHeight = 22,
	configColumnHeaderHeight = 20,
	configFixedHeaderHeight = 92,
	configSectionWidth = 560,
	configSectionGap = 18,
	configSectionInnerPad = 20,
	configLabelOffset = 10,
	configCol2 = 234,
	configCol3 = 400,
}

-- Flag matching for stat filtering
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
	self.treeOverlayMode = true

	-- Tooltip for item hover in Items view
	self.itemTooltip = new("Tooltip")

	-- Items expanded mode (false = compact names only, true = full item details inline)
	self.itemsExpandedMode = false

	-- Tooltip for calcs hover breakdown
	self.calcsTooltip = new("Tooltip")

	-- Interactive config controls state
	self.configControls = {}        -- { var -> { control, varData } }
	self.configControlList = {}     -- ordered list for layout
	self.configNeedsRebuild = true  -- trigger initial build
	self.configCompareId = nil      -- track which compare entry controls were built for
	self.configToggle = false       -- show all / hide ineligible toggle
	self.configSections = {}        -- section groups from ConfigOptions
	self.configSectionLayout = {}   -- computed section layout for drawing
	self.configTotalContentHeight = 0

	-- Compare power report state
	self.comparePowerStat = nil           -- selected data.powerStatList entry
	self.comparePowerCategories = { treeNodes = true, items = true, skillGems = true, supportGems = true, config = true }
	self.comparePowerResults = nil        -- sorted list of result entries
	self.comparePowerCoroutine = nil      -- active coroutine
	self.comparePowerProgress = 0         -- 0-100
	self.comparePowerDirty = false        -- flag to restart calculation
	self.comparePowerCompareId = nil      -- track which compare entry was calculated

	-- Pre-load static module data
	self.configOptions = LoadModule("Modules/ConfigOptions")
	self.calcSections = LoadModule("Modules/CalcSections")
	self.calcs = LoadModule("Modules/Calcs")

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
		self.controls["subTab" .. tabName].shown = function()
			return #self.compareEntries > 0
		end
		self.controls["subTab" .. tabName].locked = function()
			return self.compareViewMode == mode
		end
	end

	-- Build B selector dropdown
	self.controls.compareBuildLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -88, 0, 16}, "^7Compare with:")
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
	self.controls.reimportBtn = new("ButtonControl", {"LEFT", self.controls.importBtn, "RIGHT"}, {4, 0, 140, 20}, "Re-import Current", function()
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
	self.controls.reimportBtn.enabled = function()
		local importTab = self.primaryBuild.importTab
		return importTab and importTab.charImportMode == "SELECTCHAR"
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

	-- Tree spec selector for comparison build
	self.controls.compareSpecLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -54, 0, 16}, "^7Tree set:")
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
	-- Config set selector for comparison build
	self.controls.compareConfigSetLabel = new("LabelControl", {"LEFT", self.controls.compareItemSetSelect, "RIGHT"}, {8, 0, 0, 16}, "^7Config set:")
	self.controls.compareConfigSetLabel.shown = setsEnabled
	self.controls.compareConfigSetSelect = new("DropDownControl", {"LEFT", self.controls.compareConfigSetLabel, "RIGHT"}, {2, 0, 150, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.configTab then
			local setId = entry.configTab.configSetOrderList[index]
			if setId then
				entry.configTab:SetActiveConfigSet(setId)
				entry.buildFlag = true
				self.configNeedsRebuild = true
			end
		end
	end)
	self.controls.compareConfigSetSelect.enabled = setsEnabled
	self.controls.compareConfigSetSelect.enableDroppedWidth = true

	-- ============================================================
	-- Comparison build main skill selector (row between sets and sub-tabs)
	-- ============================================================
	self.controls.cmpSkillLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -32, 0, 16}, "^7Skill:")
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
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpMinionSkill.shown = false

	-- ============================================================
	-- Calcs view skill detail controls (per-build, independent of sidebar & regular Calcs tab)
	-- ============================================================
	local calcsBuffModeDropList = {
		{ label = "Unbuffed", buffMode = "UNBUFFED" },
		{ label = "Buffed", buffMode = "BUFFED" },
		{ label = "In Combat", buffMode = "COMBAT" },
		{ label = "Effective DPS", buffMode = "EFFECTIVE" },
	}
	-- Primary build calcs skill controls
	self.controls.primCalcsSocketGroup = new("DropDownControl", nil, {0, 0, 200, 18}, {}, function(index, value)
		self.primaryBuild.calcsTab.input.skill_number = index
		self.primaryBuild.buildFlag = true
	end)
	self.controls.primCalcsSocketGroup.shown = false
	self.controls.primCalcsSocketGroup.maxDroppedWidth = 400
	self.controls.primCalcsSocketGroup.enableDroppedWidth = true

	self.controls.primCalcsMainSkill = new("DropDownControl", nil, {0, 0, 200, 18}, {}, function(index, value)
		local mainSocketGroup = self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.calcsTab.input.skill_number]
		if mainSocketGroup then
			mainSocketGroup.mainActiveSkillCalcs = index
			self.primaryBuild.buildFlag = true
		end
	end)
	self.controls.primCalcsMainSkill.shown = false

	self.controls.primCalcsSkillPart = new("DropDownControl", nil, {0, 0, 150, 18}, {}, function(index, value)
		local mainSocketGroup = self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.calcsTab.input.skill_number]
		if mainSocketGroup then
			local displaySkillList = mainSocketGroup.displaySkillListCalcs
			local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
			if activeSkill and activeSkill.activeEffect then
				activeSkill.activeEffect.srcInstance.skillPartCalcs = index
				self.primaryBuild.buildFlag = true
			end
		end
	end)
	self.controls.primCalcsSkillPart.shown = false

	self.controls.primCalcsStageCount = new("EditControl", nil, {0, 0, 52, 18}, "", nil, "%D", 5, function(buf)
		local mainSocketGroup = self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.calcsTab.input.skill_number]
		if mainSocketGroup then
			local displaySkillList = mainSocketGroup.displaySkillListCalcs
			local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
			if activeSkill and activeSkill.activeEffect then
				activeSkill.activeEffect.srcInstance.skillStageCountCalcs = tonumber(buf)
				self.primaryBuild.buildFlag = true
			end
		end
	end)
	self.controls.primCalcsStageCount.shown = false

	self.controls.primCalcsMineCount = new("EditControl", nil, {0, 0, 52, 18}, "", nil, "%D", 5, function(buf)
		local mainSocketGroup = self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.calcsTab.input.skill_number]
		if mainSocketGroup then
			local displaySkillList = mainSocketGroup.displaySkillListCalcs
			local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
			if activeSkill and activeSkill.activeEffect then
				activeSkill.activeEffect.srcInstance.skillMineCountCalcs = tonumber(buf)
				self.primaryBuild.buildFlag = true
			end
		end
	end)
	self.controls.primCalcsMineCount.shown = false

	self.controls.primCalcsShowMinion = new("CheckBoxControl", nil, {0, 0, 18}, nil, function(state)
		self.primaryBuild.calcsTab.input.showMinion = state
		self.primaryBuild.buildFlag = true
	end, "Show stats for the minion instead of the player.")
	self.controls.primCalcsShowMinion.shown = false

	self.controls.primCalcsMinion = new("DropDownControl", nil, {0, 0, 140, 18}, {}, function(index, value)
		local mainSocketGroup = self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.calcsTab.input.skill_number]
		if mainSocketGroup then
			local displaySkillList = mainSocketGroup.displaySkillListCalcs
			local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
			if activeSkill and activeSkill.activeEffect then
				local selected = self.controls.primCalcsMinion.list[index]
				if selected then
					if selected.itemSetId then
						activeSkill.activeEffect.srcInstance.skillMinionItemSetCalcs = selected.itemSetId
					elseif selected.minionId then
						activeSkill.activeEffect.srcInstance.skillMinionCalcs = selected.minionId
					end
					self.primaryBuild.buildFlag = true
				end
			end
		end
	end)
	self.controls.primCalcsMinion.shown = false

	self.controls.primCalcsMinionSkill = new("DropDownControl", nil, {0, 0, 140, 18}, {}, function(index, value)
		local mainSocketGroup = self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.calcsTab.input.skill_number]
		if mainSocketGroup then
			local displaySkillList = mainSocketGroup.displaySkillListCalcs
			local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
			if activeSkill and activeSkill.activeEffect then
				activeSkill.activeEffect.srcInstance.skillMinionSkillCalcs = index
				self.primaryBuild.buildFlag = true
			end
		end
	end)
	self.controls.primCalcsMinionSkill.shown = false

	self.controls.primCalcsMode = new("DropDownControl", nil, {0, 0, 120, 18}, calcsBuffModeDropList, function(index, value)
		self.primaryBuild.calcsTab.input.misc_buffMode = value.buffMode
		self.primaryBuild.buildFlag = true
	end)
	self.controls.primCalcsMode.shown = false

	-- Compare build calcs skill controls
	self.controls.cmpCalcsSocketGroup = new("DropDownControl", nil, {0, 0, 200, 18}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			entry.calcsTab.input.skill_number = index
			entry.buildFlag = true
		end
	end)
	self.controls.cmpCalcsSocketGroup.shown = false
	self.controls.cmpCalcsSocketGroup.maxDroppedWidth = 400
	self.controls.cmpCalcsSocketGroup.enableDroppedWidth = true

	self.controls.cmpCalcsMainSkill = new("DropDownControl", nil, {0, 0, 200, 18}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.calcsTab.input.skill_number]
			if mainSocketGroup then
				mainSocketGroup.mainActiveSkillCalcs = index
				entry.buildFlag = true
			end
		end
	end)
	self.controls.cmpCalcsMainSkill.shown = false

	self.controls.cmpCalcsSkillPart = new("DropDownControl", nil, {0, 0, 150, 18}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.calcsTab.input.skill_number]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillListCalcs
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillPartCalcs = index
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpCalcsSkillPart.shown = false

	self.controls.cmpCalcsStageCount = new("EditControl", nil, {0, 0, 52, 18}, "", nil, "%D", 5, function(buf)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.calcsTab.input.skill_number]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillListCalcs
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillStageCountCalcs = tonumber(buf)
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpCalcsStageCount.shown = false

	self.controls.cmpCalcsMineCount = new("EditControl", nil, {0, 0, 52, 18}, "", nil, "%D", 5, function(buf)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.calcsTab.input.skill_number]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillListCalcs
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillMineCountCalcs = tonumber(buf)
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpCalcsMineCount.shown = false

	self.controls.cmpCalcsShowMinion = new("CheckBoxControl", nil, {0, 0, 18}, nil, function(state)
		local entry = self:GetActiveCompare()
		if entry then
			entry.calcsTab.input.showMinion = state
			entry.buildFlag = true
		end
	end, "Show stats for the minion instead of the player.")
	self.controls.cmpCalcsShowMinion.shown = false

	self.controls.cmpCalcsMinion = new("DropDownControl", nil, {0, 0, 140, 18}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.calcsTab.input.skill_number]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillListCalcs
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
				if activeSkill and activeSkill.activeEffect then
					local selected = self.controls.cmpCalcsMinion.list[index]
					if selected then
						if selected.itemSetId then
							activeSkill.activeEffect.srcInstance.skillMinionItemSetCalcs = selected.itemSetId
						elseif selected.minionId then
							activeSkill.activeEffect.srcInstance.skillMinionCalcs = selected.minionId
						end
						entry.buildFlag = true
					end
				end
			end
		end
	end)
	self.controls.cmpCalcsMinion.shown = false

	self.controls.cmpCalcsMinionSkill = new("DropDownControl", nil, {0, 0, 140, 18}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			local mainSocketGroup = entry.skillsTab.socketGroupList[entry.calcsTab.input.skill_number]
			if mainSocketGroup then
				local displaySkillList = mainSocketGroup.displaySkillListCalcs
				local activeSkill = displaySkillList and displaySkillList[mainSocketGroup.mainActiveSkillCalcs or 1]
				if activeSkill and activeSkill.activeEffect then
					activeSkill.activeEffect.srcInstance.skillMinionSkillCalcs = index
					entry.buildFlag = true
				end
			end
		end
	end)
	self.controls.cmpCalcsMinionSkill.shown = false

	self.controls.cmpCalcsMode = new("DropDownControl", nil, {0, 0, 120, 18}, calcsBuffModeDropList, function(index, value)
		local entry = self:GetActiveCompare()
		if entry then
			entry.calcsTab.input.misc_buffMode = value.buffMode
			entry.buildFlag = true
		end
	end)
	self.controls.cmpCalcsMode.shown = false

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

	-- Overlay toggle checkbox
	self.controls.treeOverlayCheck = new("CheckBoxControl", nil, {0, 0, 20}, "Overlay comparison", function(state)
		self.treeOverlayMode = state
		self.treeSearchNeedsSync = true
		if not state and self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
			self.primaryBuild.treeTab.viewer.compareSpec = nil
		end
	end, nil, true)
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

	-- Items expanded mode toggle
	self.controls.itemsExpandedCheck = new("CheckBoxControl", nil, {0, 0, 20}, "Expanded mode", function(state)
		self.itemsExpandedMode = state
		self.scrollY = 0
	end)
	self.controls.itemsExpandedCheck.shown = function()
		return self.compareViewMode == "ITEMS" and self:GetActiveCompare() ~= nil
	end

	-- Item set dropdown for primary build
	local itemsShown = function()
		return self.compareViewMode == "ITEMS" and self:GetActiveCompare() ~= nil
	end
	self.controls.primaryItemSetLabel = new("LabelControl", nil, {0, 0, 0, 16}, "^7Item set:")
	self.controls.primaryItemSetLabel.shown = itemsShown
	self.controls.primaryItemSetSelect = new("DropDownControl", nil, {0, 0, 216, 20}, {}, function(index, value)
		if self.primaryBuild.itemsTab and self.primaryBuild.itemsTab.itemSetOrderList[index] then
			self.primaryBuild.itemsTab:SetActiveItemSet(self.primaryBuild.itemsTab.itemSetOrderList[index])
			self.primaryBuild.itemsTab:AddUndoState()
		end
	end)
	self.controls.primaryItemSetSelect.enabled = itemsShown
	self.controls.primaryItemSetSelect.shown = itemsShown

	-- Item set dropdown for compare build
	self.controls.compareItemSetLabel2 = new("LabelControl", nil, {0, 0, 0, 16}, "^7Item set:")
	self.controls.compareItemSetLabel2.shown = itemsShown
	self.controls.compareItemSetSelect2 = new("DropDownControl", nil, {0, 0, 216, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.itemsTab and entry.itemsTab.itemSetOrderList[index] then
			entry:SetActiveItemSet(entry.itemsTab.itemSetOrderList[index])
		end
	end)
	self.controls.compareItemSetSelect2.enabled = itemsShown
	self.controls.compareItemSetSelect2.shown = itemsShown

	-- Tree set dropdown for primary build
	self.controls.primaryTreeSetLabel = new("LabelControl", nil, {0, 0, 0, 16}, "^7Tree set:")
	self.controls.primaryTreeSetLabel.shown = itemsShown
	self.controls.primaryTreeSetSelect = new("DropDownControl", nil, {0, 0, 216, 20}, {}, function(index, value)
		if self.primaryBuild.treeTab and self.primaryBuild.treeTab.specList[index] then
			self.primaryBuild.modFlag = true
			self.primaryBuild.treeTab:SetActiveSpec(index)
		end
	end)
	self.controls.primaryTreeSetSelect.enabled = itemsShown
	self.controls.primaryTreeSetSelect.shown = itemsShown
	self.controls.primaryTreeSetSelect.maxDroppedWidth = 500
	self.controls.primaryTreeSetSelect.enableDroppedWidth = true

	-- Tree set dropdown for compare build
	self.controls.compareTreeSetLabel = new("LabelControl", nil, {0, 0, 0, 16}, "^7Tree set:")
	self.controls.compareTreeSetLabel.shown = itemsShown
	self.controls.compareTreeSetSelect = new("DropDownControl", nil, {0, 0, 216, 20}, {}, function(index, value)
		local entry = self:GetActiveCompare()
		if entry and entry.treeTab and entry.treeTab.specList[index] then
			entry:SetActiveSpec(index)
			if self.primaryBuild.spec then
				self.primaryBuild.spec:SetWindowTitleWithBuildClass()
			end
		end
	end)
	self.controls.compareTreeSetSelect.enabled = itemsShown
	self.controls.compareTreeSetSelect.shown = itemsShown
	self.controls.compareTreeSetSelect.maxDroppedWidth = 500
	self.controls.compareTreeSetSelect.enableDroppedWidth = true

	-- Footer anchor controls (side-by-side only)
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

	-- Copy compared tree to primary build
	self.controls.copySpecBtn = new("ButtonControl", {"LEFT", self.controls.rightVersionSelect, "RIGHT"}, {4, 0, 76, 20}, "Copy tree", function()
		self:CopyCompareSpecToPrimary(false)
	end)
	self.controls.copySpecBtn.shown = treeFooterShown
	self.controls.copySpecBtn.enabled = function()
		local entry = self:GetActiveCompare()
		return entry and entry.treeTab and entry.treeTab.specList[entry.treeTab.activeSpec] ~= nil
	end

	self.controls.copySpecUseBtn = new("ButtonControl", {"LEFT", self.controls.copySpecBtn, "RIGHT"}, {2, 0, 100, 20}, "Copy and use", function()
		self:CopyCompareSpecToPrimary(true)
	end)
	self.controls.copySpecUseBtn.shown = treeFooterShown
	self.controls.copySpecUseBtn.enabled = self.controls.copySpecBtn.enabled

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

	-- Config view: search bar
	self.controls.configSearchEdit = new("EditControl", nil, {0, 0, 200, 20}, "", "Search", "%c", 100, nil, nil, nil, true)
	self.controls.configSearchEdit.shown = function()
		return self.compareViewMode == "CONFIG" and self:GetActiveCompare() ~= nil
	end

	-- Config view: primary build config set dropdown
	local configShown = function()
		return self.compareViewMode == "CONFIG" and self:GetActiveCompare() ~= nil
	end
	self.controls.configPrimarySetLabel = new("LabelControl", nil, {0, 0, 0, 16}, "^7Config set:")
	self.controls.configPrimarySetLabel.shown = configShown
	self.controls.configPrimarySetSelect = new("DropDownControl", nil, {0, 0, 150, 20}, nil, function(index, value)
		local configTab = self.primaryBuild.configTab
		local setId = configTab.configSetOrderList[index]
		if setId then
			configTab:SetActiveConfigSet(setId)
			self.configNeedsRebuild = true
		end
	end)
	self.controls.configPrimarySetSelect.shown = configShown
	self.controls.configPrimarySetSelect.enableDroppedWidth = true
	self.controls.configPrimarySetSelect.enabled = function()
		return #self.primaryBuild.configTab.configSetOrderList > 1
	end

	-- ============================================================
	-- Compare Power Report controls (Summary view)
	-- ============================================================
	local powerReportShown = function()
		return self.compareViewMode == "SUMMARY" and #self.compareEntries > 0
	end

	-- Metric dropdown
	local powerStatList = { { label = "-- Select Metric --", stat = nil } }
	for _, entry in ipairs(data.powerStatList) do
		if entry.stat and not entry.ignoreForNodes then
			t_insert(powerStatList, entry)
		end
	end
	self.controls.comparePowerStatSelect = new("DropDownControl", nil, {0, 0, 200, 20}, powerStatList, function(index, value)
		if value and value.stat and value ~= self.comparePowerStat then
			self.comparePowerStat = value
			self.comparePowerDirty = true
		elseif value and not value.stat then
			self.comparePowerStat = nil
			self.comparePowerResults = nil
			self.comparePowerCoroutine = nil
			self.comparePowerListSynced = false
		end
	end)
	self.controls.comparePowerStatSelect.shown = powerReportShown
	self.controls.comparePowerStatSelect.tooltipFunc = function(tooltip, mode, index, value)
		tooltip:Clear()
		if mode == "OUT" or self.controls.comparePowerStatSelect.dropped then
			return
		end
		tooltip:AddLine(14, "Select a metric to calculate power report")
	end

	-- Category checkboxes
	self.controls.comparePowerTreeCheck = new("CheckBoxControl", nil, {0, 0, 18}, "Tree:", function(state)
		self.comparePowerCategories.treeNodes = state
		self.comparePowerDirty = true
	end, "Include passive tree nodes from compared build")
	self.controls.comparePowerTreeCheck.shown = powerReportShown
	self.controls.comparePowerTreeCheck.state = true

	self.controls.comparePowerItemsCheck = new("CheckBoxControl", nil, {0, 0, 18}, "Items:", function(state)
		self.comparePowerCategories.items = state
		self.comparePowerDirty = true
	end, "Include items from compared build")
	self.controls.comparePowerItemsCheck.shown = powerReportShown
	self.controls.comparePowerItemsCheck.state = true

	self.controls.comparePowerGemsCheck = new("CheckBoxControl", nil, {0, 0, 18}, "Skill gems:", function(state)
		self.comparePowerCategories.skillGems = state
		self.comparePowerDirty = true
	end, "Include skill gem groups unique to compared build")
	self.controls.comparePowerGemsCheck.shown = powerReportShown
	self.controls.comparePowerGemsCheck.state = true

	self.controls.comparePowerSupportGemsCheck = new("CheckBoxControl", nil, {0, 0, 18}, "Support gems:", function(state)
		self.comparePowerCategories.supportGems = state
		self.comparePowerDirty = true
	end, "Include support gems from compared build's active skill")
	self.controls.comparePowerSupportGemsCheck.shown = powerReportShown
	self.controls.comparePowerSupportGemsCheck.state = true

	self.controls.comparePowerConfigCheck = new("CheckBoxControl", nil, {0, 0, 18}, "Config:", function(state)
		self.comparePowerCategories.config = state
		self.comparePowerDirty = true
	end, "Include config option differences from compared build")
	self.controls.comparePowerConfigCheck.shown = powerReportShown
	self.controls.comparePowerConfigCheck.state = true

	-- Power report list control (static height, own scrollbar)
	self.controls.comparePowerReportList = new("ComparePowerReportListControl", nil, {0, 0, 750, 250})
	self.controls.comparePowerReportList.compareTab = self
	self.controls.comparePowerReportList.shown = powerReportShown

	-- Scrollbar for Calcs sub-tab
	self.controls.calcsScrollBar = new("ScrollBarControl", nil, {0, 0, 18, 0}, 50, "VERTICAL", true)
	local calcsScrollBar = self.controls.calcsScrollBar
	self.controls.calcsScrollBar.shown = function()
		return self.compareViewMode == "CALCS" and self:GetActiveCompare() ~= nil and calcsScrollBar.enabled
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

-- Populate a set-selector dropdown from a tab's ordered set list.
-- tab: the tab object (e.g. itemsTab, skillsTab, configTab)
-- orderListField/setsField/activeIdField: string keys on tab
-- control: the DropDownControl to populate
function CompareTabClass:PopulateSetDropdown(tab, orderListField, setsField, activeIdField, control)
	local list = {}
	local orderList = tab[orderListField]
	local sets = tab[setsField]
	local activeId = tab[activeIdField]
	if orderList then
		for index, setId in ipairs(orderList) do
			local set = sets[setId]
			t_insert(list, (set and set.title) or "Default")
			if setId == activeId then
				control.selIndex = index
			end
		end
	end
	control:SetList(list)
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

-- Normalize config values so that functionally equivalent states compare equal
-- (nil/false for checks, nil/0 for counts/integers/floats)
function CompareTabClass:NormalizeConfigVals(varData, pVal, cVal)
	if varData.type == "check" then
		return pVal or false, cVal or false
	elseif varData.type == "count" or varData.type == "integer" or varData.type == "float" then
		return pVal or 0, cVal or 0
	end
	return pVal, cVal
end

-- Create a single config control for a given varData, writing to the specified input/configTab/build
local function makeConfigControl(varData, inputTable, configTab, buildObj)
	local control
	local pVal = inputTable[varData.var]
	if varData.type == "check" then
		control = new("CheckBoxControl", nil, {0, 0, 18}, nil, function(state)
			inputTable[varData.var] = state
			configTab:UpdateControls()
			configTab:BuildModList()
			buildObj.buildFlag = true
		end)
		control.state = pVal or false
	elseif varData.type == "count" or varData.type == "integer"
			or varData.type == "countAllowZero" or varData.type == "float" then
		local filter = (varData.type == "integer" and "^%-%d")
			or (varData.type == "float" and "^%d.") or "%D"
		control = new("EditControl", nil, {0, 0, 90, 18},
			tostring(pVal or ""), nil, filter, 7,
			function(buf)
				inputTable[varData.var] = tonumber(buf)
				configTab:UpdateControls()
				configTab:BuildModList()
				buildObj.buildFlag = true
			end)
	elseif varData.type == "list" and varData.list then
		control = new("DropDownControl", nil, {0, 0, 150, 18},
			varData.list, function(index, value)
				inputTable[varData.var] = value.val
				configTab:UpdateControls()
				configTab:BuildModList()
				buildObj.buildFlag = true
			end)
		control:SelByValue(pVal or (varData.list[1] and varData.list[1].val), "val")
	end
	if control then
		control.shown = function() return false end
	end
	return control
end

-- Rebuild interactive config controls for all config options (both primary and compare builds)
function CompareTabClass:RebuildConfigControls(compareEntry)
	-- Remove old config controls
	for var, _ in pairs(self.configControls) do
		self.controls["cfg_p_" .. var] = nil
		self.controls["cfg_c_" .. var] = nil
	end
	self.configControls = {}
	self.configControlList = {}
	self.configSections = {}

	if not compareEntry then return end

	local configOptions = self.configOptions
	local pInput = self.primaryBuild.configTab.input or {}
	local cInput = compareEntry.configTab.input or {}
	local primaryBuild = self.primaryBuild

	local currentSection = nil
	for _, varData in ipairs(configOptions) do
		if varData.section then
			-- Skip "Custom Modifiers" section
			if varData.section ~= "Custom Modifiers" then
				currentSection = { name = varData.section, col = varData.col, items = {} }
				t_insert(self.configSections, currentSection)
			else
				currentSection = nil
			end
		elseif currentSection and varData.var and varData.type ~= "text" then
			local pCtrl = makeConfigControl(varData, pInput, self.primaryBuild.configTab, primaryBuild)
			local cCtrl = makeConfigControl(varData, cInput, compareEntry.configTab, compareEntry)

			if pCtrl and cCtrl then
				self.controls["cfg_p_" .. varData.var] = pCtrl
				self.controls["cfg_c_" .. varData.var] = cCtrl

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
					primaryControl = pCtrl,
					compareControl = cCtrl,
					varData = varData,
					visible = false,
					alwaysShow = not hasAnyCondition and not isKeywordExcluded,
					showWithToggle = not isHardConditional and not isKeywordExcluded,
				}
				self.configControls[varData.var] = ctrlInfo
				t_insert(self.configControlList, ctrlInfo)
				t_insert(currentSection.items, ctrlInfo)
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
	if self:ImportBuild(xmlText, "Imported build") then
		return true
	end
	return false
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

-- Copy the compared build's currently selected tree spec into the primary build
function CompareTabClass:CopyCompareSpecToPrimary(andUse)
	local entry = self:GetActiveCompare()
	if not entry or not entry.treeTab then return end
	local sourceSpec = entry.treeTab.specList[entry.treeTab.activeSpec]
	if not sourceSpec then return end

	local primaryTreeTab = self.primaryBuild.treeTab

	-- Create new spec from source (same pattern as PassiveSpecListControl Copy)
	-- Note: we don't copy jewels because they reference item IDs in the compared
	-- build's itemsTab which don't exist in the primary build
	local newSpec = new("PassiveSpec", self.primaryBuild, sourceSpec.treeVersion)
	newSpec.title = (sourceSpec.title or "Default") .. " (Compared)"
	newSpec:RestoreUndoState(sourceSpec:CreateUndoState())
	newSpec:BuildClusterJewelGraphs()

	-- Add to primary build's spec list
	t_insert(primaryTreeTab.specList, newSpec)

	if andUse then
		primaryTreeTab:SetActiveSpec(#primaryTreeTab.specList)
		-- Restore primary build's window title
		if self.primaryBuild.spec then
			self.primaryBuild.spec:SetWindowTitleWithBuildClass()
		end
	end

	-- Update items tab passive tree dropdown (same pattern as PassiveSpecListControl)
	local itemsSpecSelect = self.primaryBuild.itemsTab.controls.specSelect
	local newSpecList = {}
	for i = 1, #primaryTreeTab.specList do
		newSpecList[i] = primaryTreeTab.specList[i].title or "Default"
	end
	itemsSpecSelect:SetList(newSpecList)
	itemsSpecSelect.selIndex = primaryTreeTab.activeSpec

	self.primaryBuild.buildFlag = true
end

-- Build a list of jewel comparison entries between the primary and compare builds.
-- Returns a sorted list of { label, nodeId, pItem, cItem, pSlotName, cSlotName } records.
function CompareTabClass:GetJewelComparisonSlots(compareEntry)
	local pSpec = self.primaryBuild.spec
	local cSpec = compareEntry.spec
	if not pSpec or not cSpec then return {} end

	-- Collect union of all socket nodeIds that have a jewel equipped in either build
	local nodeIds = {}
	if pSpec.jewels then
		for nodeId, itemId in pairs(pSpec.jewels) do
			if itemId and itemId > 0 then
				nodeIds[nodeId] = true
			end
		end
	end
	if cSpec.jewels then
		for nodeId, itemId in pairs(cSpec.jewels) do
			if itemId and itemId > 0 then
				nodeIds[nodeId] = true
			end
		end
	end

	local result = {}
	for nodeId in pairs(nodeIds) do
		local pItemId = pSpec.jewels and pSpec.jewels[nodeId]
		local cItemId = cSpec.jewels and cSpec.jewels[nodeId]
		local pItem = pItemId and self.primaryBuild.itemsTab.items[pItemId]
		local cItem = cItemId and compareEntry.itemsTab.items[cItemId]

		-- Skip if neither build actually has a jewel here
		if pItem or cItem then
			local slotName = "Jewel "..nodeId
			-- Derive a friendly label from the primary build's socket control if available
			local label = slotName
			local pSocket = self.primaryBuild.itemsTab.sockets and self.primaryBuild.itemsTab.sockets[nodeId]
			if pSocket and pSocket.label then
				label = pSocket.label
			else
				local cSocket = compareEntry.itemsTab.sockets and compareEntry.itemsTab.sockets[nodeId]
				if cSocket and cSocket.label then
					label = cSocket.label
				end
			end

			-- Check if the socket node is allocated in each build's current tree
			local pNodeAllocated = pSpec.allocNodes and pSpec.allocNodes[nodeId] and true or false
			local cNodeAllocated = cSpec.allocNodes and cSpec.allocNodes[nodeId] and true or false

			t_insert(result, {
				label = label,
				nodeId = nodeId,
				pItem = pItem,
				cItem = cItem,
				pSlotName = slotName,
				cSlotName = slotName,
				pNodeAllocated = pNodeAllocated,
				cNodeAllocated = cNodeAllocated,
			})
		end
	end

	-- Sort by nodeId for stable ordering
	table.sort(result, function(a, b) return a.nodeId < b.nodeId end)
	return result
end

-- Copy a compared build's item into the primary build
function CompareTabClass:CopyCompareItemToPrimary(slotName, compareEntry, andUse)
	local cSlot = compareEntry.itemsTab and compareEntry.itemsTab.slots and compareEntry.itemsTab.slots[slotName]
	local cItem = cSlot and compareEntry.itemsTab.items and compareEntry.itemsTab.items[cSlot.selItemId]
	if not cItem or not cItem.raw then return end

	local newItem = new("Item", cItem.raw)
	newItem:NormaliseQuality()
	local pItemsTab = self.primaryBuild.itemsTab
	pItemsTab:AddItem(newItem, true) -- true = noAutoEquip

	if andUse then
		local pSlot = pItemsTab.slots[slotName]
		if pSlot then
			pSlot:SetSelItemId(newItem.id)
		end
	end

	pItemsTab:PopulateSlots()
	pItemsTab:AddUndoState()
	self.primaryBuild.buildFlag = true
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

	controls.name = new("EditControl", nil, {0, 80, 450, 20}, "", "Name (optional)", nil, 100, nil)
	controls.state = new("LabelControl", {"TOPLEFT", controls.name, "BOTTOMLEFT"}, {0, 4, 0, 16})
	controls.state.label = function()
		return stateText or ""
	end
	controls.go = new("ButtonControl", nil, {-118, 130, 80, 20}, "Import", function()
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
	controls.importFolder = new("ButtonControl", nil, {0, 130, 140, 20}, "Import from Folder", function()
		main:ClosePopup()
		self:OpenImportFolderPopup()
	end)
	controls.cancel = new("ButtonControl", nil, {118, 130, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 160, "Import Comparison Build", controls, "go", "input", "cancel")
end

-- Open the "Import from Folder" popup: browse the user's local builds folder and
-- import the selected build file as a comparison.
function CompareTabClass:OpenImportFolderPopup()
	local controls = {}
	local searchText = ""
	local sortMode = main.buildSortMode

	-- Minimal listMode-like host consumed by BuildListControl/PathControl.
	local listHost = {
		subPath = "",
		list = { },
		controls = { },
	}
	function listHost:BuildList()
		wipeTable(self.list)
		local scanned = buildListHelpers.ScanFolder(self.subPath, searchText)
		for _, entry in ipairs(scanned) do
			t_insert(self.list, entry)
		end
		buildListHelpers.SortList(self.list, sortMode)
	end
	function listHost:SelectControl(control)
		-- Focus is managed by the popup's ControlHost; this is a no-op for the popup list.
	end

	-- Import the given build entry (xml file on disk) as a comparison.
	local function importBuildEntry(build)
		local fileHnd = io.open(build.fullFileName, "r")
		if not fileHnd then
			main:OpenMessagePopup("Import Error", "Couldn't open '"..build.fullFileName.."'.")
			return
		end
		local xmlText = fileHnd:read("*a")
		fileHnd:close()
		if not xmlText or xmlText == "" then
			main:OpenMessagePopup("Import Error", "Build file is empty or unreadable.")
			return
		end
		if self:ImportBuild(xmlText, build.buildName) then
			main:ClosePopup()
		else
			main:OpenMessagePopup("Import Error", "Failed to import build for comparison.")
		end
	end

	-- Search box and sort dropdown sit above the build list.
	controls.searchText = new("EditControl", {"TOPLEFT", nil, "TOPLEFT"}, {15, 25, 450, 20}, "", "Search", "%c%(%)", 100, function(buf)
		searchText = buf
		listHost:BuildList()
	end, nil, nil, true)
	controls.sort = new("DropDownControl", {"TOPLEFT", nil, "TOPLEFT"}, {475, 25, 210, 20}, buildListHelpers.buildSortDropList, function(index, value)
		sortMode = value.sortMode
		main.buildSortMode = value.sortMode
		buildListHelpers.SortList(listHost.list, sortMode)
	end)
	controls.sort:SelByValue(sortMode, "sortMode")

	-- Build list itself. Reuses BuildListControl (which provides the PathControl breadcrumbs)
	controls.buildList = new("BuildListControl", {"TOPLEFT", nil, "TOPLEFT"}, {15, 75, 0, 0}, listHost)
	controls.buildList.width = function() return 670 end
	controls.buildList.height = function() return 355 end

	-- Override instance methods on the BuildListControl to tailor it for the popup:
	-- navigate folders, import builds, and suppress rename/delete/drag behaviors.
	function controls.buildList:LoadBuild(build)
		if build.folderName then
			self.controls.path:SetSubPath(self.listMode.subPath .. build.folderName .. "/")
		else
			importBuildEntry(build)
		end
	end
	function controls.buildList:OnSelKeyDown(index, build, key)
		if key == "RETURN" then
			self:LoadBuild(build)
		end
	end
	function controls.buildList:CanReceiveDrag() return false end
	function controls.buildList:OnSelCopy() end
	function controls.buildList:OnSelCut() end
	function controls.buildList:OnSelDelete() end
	function controls.buildList.controls.path:CanReceiveDrag() return false end

	-- Populate the initial list now that the control (and its path control) exist.
	listHost:BuildList()

	controls.open = new("ButtonControl", {"TOPLEFT", nil, "TOPLEFT"}, {255, 465, 80, 20}, "Open", function()
		local sel = controls.buildList.selValue
		if sel then
			controls.buildList:LoadBuild(sel)
		end
	end)
	controls.open.enabled = function() return controls.buildList.selValue ~= nil end
	controls.close = new("ButtonControl", {"TOPLEFT", nil, "TOPLEFT"}, {365, 465, 80, 20}, "Close", function()
		main:ClosePopup()
	end)

	main:OpenPopup(700, 500, "Import from Folder", controls, "open", "searchText", "close")
end

-- ============================================================
-- DRAW - Main render method
-- ============================================================
function CompareTabClass:Draw(viewPort, inputEvents)
	-- Position top-bar controls
	self.controls.subTabAnchor.x = viewPort.x + 4
	self.controls.subTabAnchor.y = viewPort.y + 96

	-- Draw dividers between top-bar sections when a comparison is loaded
	if #self.compareEntries > 0 then
		SetDrawColor(0.25, 0.25, 0.25)
		DrawImage(nil, viewPort.x + 4, viewPort.y + 32, viewPort.width - 8, 2)
		DrawImage(nil, viewPort.x + 4, viewPort.y + 88, viewPort.width - 8, 2)
		DrawImage(nil, viewPort.x + 4, viewPort.y + 122, viewPort.width - 8, 2)
	end

	self.controls.compareBuildLabel.x = function()
		return 0
	end

	local contentVP = {
		x = viewPort.x,
		y = viewPort.y + LAYOUT.controlBarHeight,
		width = viewPort.width,
		height = viewPort.height - LAYOUT.controlBarHeight,
	}

	-- Get active comparison early (needed for footer positioning before ProcessControlsInput)
	local compareEntry = self:GetActiveCompare()

	-- Rebuild compare entry if its buildFlag is set (e.g. after version convert or spec change)
	if compareEntry and compareEntry.buildFlag then
		compareEntry:Rebuild()
	end

	-- Layout: position controls and draw backgrounds for current view mode
	-- (must happen before ProcessControlsInput so controls render on top of backgrounds)
	self:LayoutTreeView(contentVP, compareEntry)
	self:LayoutConfigView(contentVP, compareEntry)
	if compareEntry then
		self:UpdateSetSelectors(compareEntry)
	end
	-- Layout and refresh calcs skill detail controls
	self.calcsSkillHeaderHeight = 0
	if self.compareViewMode == "CALCS" and compareEntry then
		self.calcsSkillHeaderHeight = self:LayoutCalcsSkillControls(contentVP, compareEntry)
	end
	self:HandleScrollInput(contentVP, inputEvents)

	-- Draw calcs skill header background
	if self.compareViewMode == "CALCS" and self.calcsSkillHeaderHeight > 0 then
		SetDrawColor(0.05, 0.05, 0.05)
		DrawImage(nil, contentVP.x, contentVP.y, contentVP.width, self.calcsSkillHeaderHeight)
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
			"^7Click " .. colorCodes.POSITIVE .. "Import..." .. "^7 above to import a build to compare against.")
		SetViewport()
		return
	end

	-- Position items expanded mode checkbox and item set dropdowns (inside content area, top-left)
	-- Label draws to the left of the checkbox, so offset x by labelWidth to keep it visible
	if self.compareViewMode == "ITEMS" then
		self.controls.itemsExpandedCheck.x = contentVP.x + 10 + self.controls.itemsExpandedCheck.labelWidth
		self.controls.itemsExpandedCheck.y = contentVP.y + 8

		local colWidth = m_floor(contentVP.width / 2)
		local itemSetLabelW = DrawStringWidth(16, "VAR", "^7Item set:") + 4

		-- Item set dropdowns
		local row1Y = contentVP.y + 34

		-- Primary build item set dropdown
		self.controls.primaryItemSetLabel.x = contentVP.x + 10
		self.controls.primaryItemSetLabel.y = row1Y + 2
		self.controls.primaryItemSetSelect.x = contentVP.x + 10 + itemSetLabelW
		self.controls.primaryItemSetSelect.y = row1Y

		-- Compare build item set dropdown
		self.controls.compareItemSetLabel2.x = contentVP.x + colWidth + 10
		self.controls.compareItemSetLabel2.y = row1Y + 2
		self.controls.compareItemSetSelect2.x = contentVP.x + colWidth + 10 + itemSetLabelW
		self.controls.compareItemSetSelect2.y = row1Y

		-- Populate primary build item set list
		if self.primaryBuild.itemsTab and self.primaryBuild.itemsTab.itemSetOrderList then
			self:PopulateSetDropdown(self.primaryBuild.itemsTab, "itemSetOrderList", "itemSets", "activeItemSetId", self.controls.primaryItemSetSelect)
		end

		-- Populate compare build item set list
		if compareEntry and compareEntry.itemsTab and compareEntry.itemsTab.itemSetOrderList then
			self:PopulateSetDropdown(compareEntry.itemsTab, "itemSetOrderList", "itemSets", "activeItemSetId", self.controls.compareItemSetSelect2)
		end

	end

	-- Dispatch to sub-view (TREE already drawn above)
	if self.compareViewMode == "SUMMARY" then
		self:DrawSummary(contentVP, compareEntry)
	elseif self.compareViewMode == "ITEMS" then
		self:DrawItems(contentVP, compareEntry, inputEvents)
	elseif self.compareViewMode == "SKILLS" then
		self:DrawSkills(contentVP, compareEntry)
	elseif self.compareViewMode == "CALCS" then
		self:DrawCalcs(contentVP, compareEntry)
	elseif self.compareViewMode == "CONFIG" then
		self:DrawConfig(contentVP, compareEntry)
	end
end

-- ============================================================
-- DRAW HELPERS
-- ============================================================

-- Pre-draw tree header/footer backgrounds and position tree controls.
-- Must run before ProcessControlsInput so controls render on top of backgrounds.
function CompareTabClass:LayoutTreeView(contentVP, compareEntry)
	self.treeLayout = nil
	if self.compareViewMode ~= "TREE" or not compareEntry then return end

	local headerHeight = LAYOUT.treeHeaderHeight
	local footerHeight = LAYOUT.treeFooterHeight
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
		self.controls.leftSpecSelect.y = contentVP.y + 8
		self.controls.leftSpecSelect.width = specWidth

		local rightSpecX = contentVP.x + m_floor(contentVP.width / 2) + 4
		self.controls.rightSpecSelect.x = rightSpecX
		self.controls.rightSpecSelect.y = contentVP.y + 8
		self.controls.rightSpecSelect.width = specWidth

		-- Overlay checkbox in header row 2
		self.controls.treeOverlayCheck.x = contentVP.x + LAYOUT.treeOverlayCheckX
		self.controls.treeOverlayCheck.y = contentVP.y + 34

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
		self.controls.leftSpecSelect.y = contentVP.y + 8
		self.controls.leftSpecSelect.width = specWidth

		self.controls.rightSpecSelect.x = contentVP.x + m_floor(contentVP.width / 2) + 4
		self.controls.rightSpecSelect.y = contentVP.y + 8
		self.controls.rightSpecSelect.width = specWidth

		-- Overlay checkbox in header row 2
		self.controls.treeOverlayCheck.x = contentVP.x + LAYOUT.treeOverlayCheckX
		self.controls.treeOverlayCheck.y = contentVP.y + 34

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

-- Sync a single control's displayed value with the actual input value
local function syncControlValue(ctrl, varData, val)
	if varData.type == "check" then
		ctrl.state = val or false
	elseif varData.type == "count" or varData.type == "integer"
			or varData.type == "countAllowZero" or varData.type == "float" then
		ctrl:SetText(tostring(val or ""))
	elseif varData.type == "list" then
		ctrl:SelByValue(val or (varData.list[1] and varData.list[1].val), "val")
	end
end

-- Position config controls and build section-grouped display when in CONFIG view.
function CompareTabClass:LayoutConfigView(contentVP, compareEntry)
	if self.compareViewMode ~= "CONFIG" or not compareEntry then return end

	-- Rebuild controls if compare entry changed or config was modified
	if self.configCompareId ~= self.activeCompareIndex or self.configNeedsRebuild then
		self:RebuildConfigControls(compareEntry)
		self.configCompareId = self.activeCompareIndex
		self.configNeedsRebuild = false
	end

	-- Sync control values with current input (in case changed from normal Config tab or externally)
	local pInput = self.primaryBuild.configTab.input or {}
	local cInput = compareEntry.configTab.input or {}
	for var, ctrlInfo in pairs(self.configControls) do
		local varData = ctrlInfo.varData
		syncControlValue(ctrlInfo.primaryControl, varData, pInput[var])
		syncControlValue(ctrlInfo.compareControl, varData, cInput[var])
	end

	-- Position header controls
	local row1Y = contentVP.y + 4
	local row2Y = contentVP.y + 28
	self.controls.copyConfigBtn.x = contentVP.x + 10
	self.controls.copyConfigBtn.y = row1Y
	self.controls.configToggleBtn.x = contentVP.x + 260
	self.controls.configToggleBtn.y = row1Y

	self.controls.configSearchEdit.x = contentVP.x + 10
	self.controls.configSearchEdit.y = row2Y

	-- Update primary config set dropdown list
	local pConfigTab = self.primaryBuild.configTab
	local pSetList = {}
	for index, setId in ipairs(pConfigTab.configSetOrderList) do
		local configSet = pConfigTab.configSets[setId]
		t_insert(pSetList, configSet and configSet.title or "Default")
		if setId == pConfigTab.activeConfigSetId then
			self.controls.configPrimarySetSelect.selIndex = index
		end
	end
	self.controls.configPrimarySetSelect:SetList(pSetList)
	self.controls.configPrimarySetLabel.x = contentVP.x + 220
	self.controls.configPrimarySetLabel.y = row2Y + 2
	self.controls.configPrimarySetSelect.x = contentVP.x + 290
	self.controls.configPrimarySetSelect.y = row2Y

	-- Build section layout: multi-column grid, mirroring regular ConfigTab
	local rowHeight = LAYOUT.configRowHeight
	local sectionInnerPad = LAYOUT.configSectionInnerPad
	local sectionGap = LAYOUT.configSectionGap
	local fixedHeaderHeight = LAYOUT.configFixedHeaderHeight
	local sectionWidth = LAYOUT.configSectionWidth
	local scrollableH = contentVP.height - fixedHeaderHeight

	-- Hide ALL config controls first (selectively shown below)
	for _, ctrlInfo in ipairs(self.configControlList) do
		ctrlInfo.primaryControl.shown = function() return false end
		ctrlInfo.compareControl.shown = function() return false end
	end

	-- Search filter: match config labels against search text
	local searchStr = self.controls.configSearchEdit.buf:lower():gsub("[%-%.%+%[%]%$%^%%%?%*]", "%%%0")
	local hasSearch = searchStr and searchStr:match("%S")
	local function searchMatch(varData)
		if not hasSearch then return true end
		local err, match = PCall(string.matchOrPattern, (varData.label or ""):lower(), searchStr)
		return not err and match
	end

	-- First pass: compute rows and height for each section
	local visibleSections = {}
	for _, section in ipairs(self.configSections) do
		local diffs = {}
		local commons = {}
		for _, ctrlInfo in ipairs(section.items) do
			if searchMatch(ctrlInfo.varData) then
				local pVal, cVal = self:NormalizeConfigVals(ctrlInfo.varData,
					pInput[ctrlInfo.varData.var], cInput[ctrlInfo.varData.var])
				local isDiff = tostring(pVal) ~= tostring(cVal)
				if isDiff then
					t_insert(diffs, ctrlInfo)
				elseif ctrlInfo.alwaysShow or (self.configToggle and ctrlInfo.showWithToggle) then
					t_insert(commons, ctrlInfo)
				end
			end
		end

		local rows = {}
		for _, ci in ipairs(diffs) do t_insert(rows, { ctrlInfo = ci, isDiff = true }) end
		for _, ci in ipairs(commons) do t_insert(rows, { ctrlInfo = ci, isDiff = false }) end

		if #rows > 0 then
			local sectionHeight = sectionInnerPad + #rows * rowHeight + 8
			t_insert(visibleSections, {
				name = section.name,
				col = section.col,
				rows = rows,
				height = sectionHeight,
				diffCount = #diffs,
			})
		end
	end

	-- Second pass: multi-column placement (same algorithm as ConfigTab)
	local maxCol = m_floor((contentVP.width - 10) / sectionWidth)
	if maxCol < 1 then maxCol = 1 end
	local colY = { 0 }
	local maxColY = 0
	local sectionLayout = {}

	for _, sec in ipairs(visibleSections) do
		local h = sec.height
		local col
		-- Try preferred column if it fits
		if sec.col and (colY[sec.col] or 0) + h + 28 <= scrollableH
				and 10 + sec.col * sectionWidth <= contentVP.width then
			col = sec.col
		else
			-- Find shortest column
			col = 1
			for c = 2, maxCol do
				colY[c] = colY[c] or 0
				if colY[c] < colY[col] then
					col = c
				end
			end
		end
		colY[col] = colY[col] or 0
		sec.x = 10 + (col - 1) * sectionWidth
		sec.y = colY[col] + sectionGap
		colY[col] = colY[col] + h + sectionGap
		maxColY = m_max(maxColY, colY[col])
		t_insert(sectionLayout, sec)
	end

	-- Third pass: position controls at absolute coords
	local scrollTopAbs = contentVP.y + fixedHeaderHeight
	for _, sec in ipairs(sectionLayout) do
		local sectionAbsX = contentVP.x + sec.x
		local rowY = sec.y + sectionInnerPad
		for _, row in ipairs(sec.rows) do
			local ci = row.ctrlInfo
			ci.primaryControl.x = sectionAbsX + LAYOUT.configCol2
			ci.primaryControl.y = contentVP.y + fixedHeaderHeight + rowY - self.scrollY
			ci.compareControl.x = sectionAbsX + LAYOUT.configCol3
			ci.compareControl.y = contentVP.y + fixedHeaderHeight + rowY - self.scrollY
			local capturedRowY = rowY
			local shownFn = function()
				local ay = contentVP.y + fixedHeaderHeight + capturedRowY - self.scrollY
				return ay >= scrollTopAbs - 20 and ay < contentVP.y + contentVP.height
					and self.compareViewMode == "CONFIG" and self:GetActiveCompare() ~= nil
			end
			ci.primaryControl.shown = shownFn
			ci.compareControl.shown = shownFn
			rowY = rowY + rowHeight
		end
	end

	self.configSectionLayout = sectionLayout
	self.configTotalContentHeight = maxColY + sectionGap
end

-- Update comparison build set selectors (spec, skill set, item set, skill controls).
function CompareTabClass:UpdateSetSelectors(compareEntry)
	-- Tree spec list (reuse GetSpecList from TreeTab)
	if compareEntry.treeTab then
		self.controls.compareSpecSelect.list = compareEntry.treeTab:GetSpecList()
		self.controls.compareSpecSelect.selIndex = compareEntry.treeTab.activeSpec
	end
	-- Skill set list
	if compareEntry.skillsTab then
		self:PopulateSetDropdown(compareEntry.skillsTab, "skillSetOrderList", "skillSets", "activeSkillSetId", self.controls.compareSkillSetSelect)
	end
	-- Item set list
	if compareEntry.itemsTab then
		self:PopulateSetDropdown(compareEntry.itemsTab, "itemSetOrderList", "itemSets", "activeItemSetId", self.controls.compareItemSetSelect)
	end
	-- Config set list
	if compareEntry.configTab then
		self:PopulateSetDropdown(compareEntry.configTab, "configSetOrderList", "configSets", "activeConfigSetId", self.controls.compareConfigSetSelect)
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

-- Refresh calcs skill detail controls for both builds.
function CompareTabClass:RefreshCalcsSkillControls(compareEntry)
	-- Build control maps for RefreshSkillSelectControls
	local primControls = {
		mainSocketGroup = self.controls.primCalcsSocketGroup,
		mainSkill = self.controls.primCalcsMainSkill,
		mainSkillPart = self.controls.primCalcsSkillPart,
		mainSkillStageCount = self.controls.primCalcsStageCount,
		mainSkillMineCount = self.controls.primCalcsMineCount,
		mainSkillMinion = self.controls.primCalcsMinion,
		mainSkillMinionLibrary = { shown = false },
		mainSkillMinionSkill = self.controls.primCalcsMinionSkill,
	}
	self.primaryBuild:RefreshSkillSelectControls(primControls, self.primaryBuild.calcsTab.input.skill_number, "Calcs")
	self.controls.primCalcsSocketGroup.shown = true
	self.controls.primCalcsMode.shown = true
	self.controls.primCalcsMode:SelByValue(self.primaryBuild.calcsTab.input.misc_buffMode, "buffMode")
	self.controls.primCalcsShowMinion.shown = self.controls.primCalcsMinion.shown == true
	self.controls.primCalcsShowMinion.state = self.primaryBuild.calcsTab.input.showMinion and true or false

	local cmpControls = {
		mainSocketGroup = self.controls.cmpCalcsSocketGroup,
		mainSkill = self.controls.cmpCalcsMainSkill,
		mainSkillPart = self.controls.cmpCalcsSkillPart,
		mainSkillStageCount = self.controls.cmpCalcsStageCount,
		mainSkillMineCount = self.controls.cmpCalcsMineCount,
		mainSkillMinion = self.controls.cmpCalcsMinion,
		mainSkillMinionLibrary = { shown = false },
		mainSkillMinionSkill = self.controls.cmpCalcsMinionSkill,
	}
	compareEntry:RefreshSkillSelectControls(cmpControls, compareEntry.calcsTab.input.skill_number, "Calcs")
	self.controls.cmpCalcsSocketGroup.shown = true
	self.controls.cmpCalcsMode.shown = true
	self.controls.cmpCalcsMode:SelByValue(compareEntry.calcsTab.input.misc_buffMode, "buffMode")
	self.controls.cmpCalcsShowMinion.shown = self.controls.cmpCalcsMinion.shown == true
	self.controls.cmpCalcsShowMinion.state = compareEntry.calcsTab.input.showMinion and true or false

	-- Wrap .shown booleans set by RefreshSkillSelectControls with a view-mode gate,
	-- so controls auto-hide when not in CALCS mode (matching configShown pattern)
	local calcsControlNames = {
		"primCalcsSocketGroup", "primCalcsMainSkill", "primCalcsSkillPart",
		"primCalcsStageCount", "primCalcsMineCount", "primCalcsShowMinion", "primCalcsMinion",
		"primCalcsMinionSkill", "primCalcsMode",
		"cmpCalcsSocketGroup", "cmpCalcsMainSkill", "cmpCalcsSkillPart",
		"cmpCalcsStageCount", "cmpCalcsMineCount", "cmpCalcsShowMinion", "cmpCalcsMinion",
		"cmpCalcsMinionSkill", "cmpCalcsMode",
	}
	for _, name in ipairs(calcsControlNames) do
		local ctrl = self.controls[name]
		local baseShown = ctrl.shown
		if baseShown then
			ctrl.shown = function()
				return self.compareViewMode == "CALCS" and self:GetActiveCompare() ~= nil
					and (type(baseShown) == "function" and baseShown() or baseShown)
			end
		end
	end
end

-- Layout calcs skill detail controls into a two-column header area
function CompareTabClass:LayoutCalcsSkillControls(vp, compareEntry)
	if self.compareViewMode ~= "CALCS" or not compareEntry then return 0 end

	self:RefreshCalcsSkillControls(compareEntry)

	local colWidth = m_floor((vp.width - 20) / 2)
	local leftX = vp.x + 4
	local rightX = leftX + colWidth + 12
	local labelW = 140
	local controlW = colWidth - labelW - 8
	local rowH = 22
	local y = vp.y + 4

	-- Helper to position a row of label + control
	local function layoutRow(control, x, currentY, width)
		if control.shown == false or (type(control.shown) == "function" and not control:IsShown()) then
			return false
		end
		control.x = x + labelW
		control.y = currentY
		if control.width then
			control.width = m_min(width or controlW, control.width)
		end
		return true
	end

	-- Track max rows for both columns
	local leftY = y
	local rightY = y

	-- Title row
	leftY = leftY + rowH
	rightY = rightY + rowH

	-- { suffix, useControlW, alwaysAdvance }
	local calcsRows = {
		{ "SocketGroup",  true,  true  },
		{ "MainSkill",    true,  false },
		{ "SkillPart",    true,  false },
		{ "StageCount",   false, false },
		{ "MineCount",    false, false },
		{ "ShowMinion",   false, false },
		{ "Minion",       true,  false },
		{ "MinionSkill",  true,  false },
		{ "Mode",         false, true  },
	}
	for _, row in ipairs(calcsRows) do
		local suffix, useControlW, alwaysAdvance = row[1], row[2], row[3]
		local width = useControlW and controlW or nil
		local primShown = layoutRow(self.controls["primCalcs" .. suffix], leftX, leftY, width)
		local cmpShown = layoutRow(self.controls["cmpCalcs" .. suffix], rightX, rightY, width)
		if primShown or alwaysAdvance then leftY = leftY + rowH end
		if cmpShown or alwaysAdvance then rightY = rightY + rowH end
	end

	-- Account for text info lines (Aura/Buffs, Combat Buffs, Curses) + separator
	local textLinesHeight = 2 -- padding before text
	local primaryEnv = self.primaryBuild.calcsTab and self.primaryBuild.calcsTab.calcsEnv
	local compareEnv = compareEntry.calcsTab and compareEntry.calcsTab.calcsEnv
	local pOutput = primaryEnv and primaryEnv.player and primaryEnv.player.output
	local cOutput = compareEnv and compareEnv.player and compareEnv.player.output
	if pOutput or cOutput then
		local infoKeys = { "BuffList", "CombatList", "CurseList" }
		for _, key in ipairs(infoKeys) do
			local pVal = pOutput and pOutput[key]
			local cVal = cOutput and cOutput[key]
			if (pVal and pVal ~= "") or (cVal and cVal ~= "") then
				textLinesHeight = textLinesHeight + 18
			end
		end
	end

	local headerHeight = m_max(leftY, rightY) - vp.y + textLinesHeight + 4 -- +4 for separator padding
	return headerHeight
end

-- Handle scroll events for scrollable views.
function CompareTabClass:HandleScrollInput(contentVP, inputEvents)
	local cursorX, cursorY = GetCursorPos()
	local mouseInContent = cursorX >= contentVP.x and cursorX < contentVP.x + contentVP.width
		and cursorY >= contentVP.y and cursorY < contentVP.y + contentVP.height

	local listControl = self.controls.comparePowerReportList
	local mouseOverList = listControl:IsShown() and listControl:IsMouseOver()

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" and mouseInContent and not mouseOverList then
			if self.compareViewMode == "CALCS" then
				if event.key == "WHEELUP" then
					self.controls.calcsScrollBar:Scroll(-1)
					inputEvents[id] = nil
				elseif event.key == "WHEELDOWN" then
					self.controls.calcsScrollBar:Scroll(1)
					inputEvents[id] = nil
				end
			elseif event.key == "WHEELUP" and self.compareViewMode ~= "TREE" then
				self.scrollY = m_max(self.scrollY - 40, 0)
				inputEvents[id] = nil
			elseif event.key == "WHEELDOWN" and self.compareViewMode ~= "TREE" then
				local maxScroll = 0
				if self.compareViewMode == "CONFIG" and self.configTotalContentHeight then
					local scrollViewH = contentVP.height - LAYOUT.configFixedHeaderHeight
					maxScroll = m_max(self.configTotalContentHeight - scrollViewH, 0)
				else
					maxScroll = 99999
				end
				self.scrollY = m_min(self.scrollY + 40, maxScroll)
				inputEvents[id] = nil
			end
		end
	end
end

-- ============================================================
-- COMPARE POWER REPORT
-- ============================================================

-- Resolve the granted effect for a gem instance
function CompareTabClass:GetGemGrantedEffect(gem)
	if gem.gemData and gem.gemData.grantedEffect then
		return gem.gemData.grantedEffect
	end
	return gem.grantedEffect
end

-- Build a signature string for a socket group (sorted gem names)
function CompareTabClass:GetSocketGroupSignature(group)
	local names = {}
	for _, gem in ipairs(group.gemList or {}) do
		local name = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec
		if name then
			t_insert(names, name)
		end
	end
	table.sort(names)
	return table.concat(names, "+")
end

-- Get a display label for a socket group (active skills only)
function CompareTabClass:GetSocketGroupLabel(group)
	local names = {}
	for _, gem in ipairs(group.gemList or {}) do
		local isSupport = gem.grantedEffect and gem.grantedEffect.support
		if not isSupport then
			local name = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec
			if name then
				t_insert(names, name)
			end
		end
	end
	if #names == 0 then
		-- Fallback: show all gem names if no active skills found
		for _, gem in ipairs(group.gemList or {}) do
			local name = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec
			if name then
				t_insert(names, name)
			end
		end
	end
	if #names == 0 then
		return "(empty group)"
	end
	return table.concat(names, " + ")
end

-- Coroutine: calculate power of compared build elements against primary build
function CompareTabClass:ComparePowerBuilder(compareEntry, powerStat, categories)
	local results = {}
	local useFullDPS = powerStat.stat == "FullDPS"

	-- Get calculator for primary build
	local calcFunc, calcBase = self.calcs.getMiscCalculator(self.primaryBuild)

	-- Find display stat for formatting
	local displayStat = nil
	for _, ds in ipairs(self.primaryBuild.displayStats) do
		if ds.stat == powerStat.stat then
			displayStat = ds
			break
		end
	end
	if not displayStat then
		displayStat = { fmt = ".1f" }
	end

	local total = 0
	local processed = 0
	local start = GetTime()

	-- Count total work items for progress
	if categories.treeNodes then
		local compareNodes = compareEntry.spec and compareEntry.spec.allocNodes or {}
		local primaryNodes = self.primaryBuild.spec and self.primaryBuild.spec.allocNodes or {}
		for nodeId, node in pairs(compareNodes) do
			if type(nodeId) == "number" and nodeId < CLUSTER_NODE_OFFSET and not primaryNodes[nodeId] then
				local pNode = self.primaryBuild.spec.nodes[nodeId]
				if pNode and (pNode.type == "Normal" or pNode.type == "Notable" or pNode.type == "Keystone") and not pNode.ascendancyName then
					total = total + 1
				end
			end
		end
	end
	if categories.items then
		local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }
		if self:ShouldShowRing3(compareEntry) then
			t_insert(baseSlots, 10, "Ring 3")
		end
		for _, slotName in ipairs(baseSlots) do
			local cSlot = compareEntry.itemsTab and compareEntry.itemsTab.slots[slotName]
			local cItem = cSlot and compareEntry.itemsTab.items[cSlot.selItemId]
			if cItem then
				total = total + 1
			end
		end
		-- Count jewels for progress tracking
		local jewelSlots = self:GetJewelComparisonSlots(compareEntry)
		for _, jEntry in ipairs(jewelSlots) do
			if jEntry.cItem then
				total = total + 1
			end
		end
	end
	if categories.skillGems then
		local cGroups = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList or {}
		total = total + #cGroups
	end
	if categories.supportGems then
		local cMainGroup = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList[compareEntry.mainSocketGroup]
		local pMainGroup = self.primaryBuild.skillsTab and self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.mainSocketGroup]
		if cMainGroup and pMainGroup then
			-- Count support gems in compared build's main group not in primary's main group
			local pSupportNames = {}
			for _, gem in ipairs(pMainGroup.gemList or {}) do
				local ge = self:GetGemGrantedEffect(gem)
				if ge and ge.support then
					local name = ge.name or gem.nameSpec
					if name then pSupportNames[name] = true end
				end
			end
			for _, gem in ipairs(cMainGroup.gemList or {}) do
				local ge = self:GetGemGrantedEffect(gem)
				if ge and ge.support then
					local name = ge.name or gem.nameSpec
					if name and not pSupportNames[name] then
						total = total + 1
					end
				end
			end
		end
	end
	if categories.config then
		local pInput = self.primaryBuild.configTab.input or {}
		local cInput = compareEntry.configTab.input or {}
		for _, varData in ipairs(self.configOptions) do
			if varData.var and varData.apply and varData.type ~= "text" then
				local pVal, cVal = self:NormalizeConfigVals(varData, pInput[varData.var], cInput[varData.var])
				if pVal ~= cVal then
					total = total + 1
				end
			end
		end
	end

	if total == 0 then
		self.comparePowerResults = results
		self.comparePowerProgress = 100
		return
	end

	-- Get baseline stat value for percentage calculation
	local baseStatValue = calcBase[powerStat.stat] or 0
	if powerStat.transform then
		baseStatValue = powerStat.transform(baseStatValue)
	end

	-- Helper to format an impact value and compute percentage
	local function formatImpact(impact)
		local displayVal = impact * ((displayStat.pc or displayStat.mod) and 100 or 1)
		local rawNumStr = s_format("%" .. displayStat.fmt, displayVal)
		local isZero = (tonumber(rawNumStr) == 0)
		local numStr = formatNumSep(rawNumStr)

		-- Determine color
		local isPositive = (displayVal > 0 and not displayStat.lowerIsBetter) or (displayVal < 0 and displayStat.lowerIsBetter)
		local isNegative = (displayVal < 0 and not displayStat.lowerIsBetter) or (displayVal > 0 and displayStat.lowerIsBetter)
		local color = isPositive and colorCodes.POSITIVE or isNegative and colorCodes.NEGATIVE or "^7"
		local sign = displayVal > 0 and "+" or ""
		local str = color .. sign .. numStr

		-- Compute percentage change
		local percent = 0
		if baseStatValue ~= 0 then
			percent = (impact / math.abs(baseStatValue)) * 100
		end

		-- Build combined string: "+1,234.5 (+4.3%)"
		local combinedStr = str
		if percent ~= 0 then
			local pctStr = s_format("%+.1f%%", percent)
			combinedStr = str .. " ^7(" .. color .. pctStr .. "^7)"
		end

		return str, displayVal, combinedStr, percent, isZero
	end

	-- ==========================================
	-- Tree Nodes
	-- ==========================================
	if categories.treeNodes then
		local compareNodes = compareEntry.spec and compareEntry.spec.allocNodes or {}
		local primaryNodes = self.primaryBuild.spec and self.primaryBuild.spec.allocNodes or {}
		local cache = {}

		for nodeId, _ in pairs(compareNodes) do
			if type(nodeId) == "number" and nodeId < CLUSTER_NODE_OFFSET and not primaryNodes[nodeId] then
				local pNode = self.primaryBuild.spec.nodes[nodeId]
				if pNode and (pNode.type == "Normal" or pNode.type == "Notable" or pNode.type == "Keystone")
						and not pNode.ascendancyName and pNode.modKey ~= "" then
					local output
					if cache[pNode.modKey] then
						output = cache[pNode.modKey]
					else
						output = calcFunc({ addNodes = { [pNode] = true } }, useFullDPS)
						cache[pNode.modKey] = output
					end
					local impact = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, output, calcBase)
					local pathDist = pNode.pathDist or 0
					if pathDist == 0 then
						pathDist = #(pNode.path or {})
						if pathDist == 0 then pathDist = 1 end
					end
					local perPoint = impact / pathDist
					local impactStr, impactVal, combinedImpactStr, impactPercent, impactIsZero = formatImpact(impact)
					local perPointStr = formatImpact(perPoint)

					if not impactIsZero then
						t_insert(results, {
							category = "Tree",
							categoryColor = "^7",
							nameColor = "^7",
							name = pNode.dn,
							nodeId = nodeId,
							impact = impactVal,
							impactStr = impactStr,
							impactPercent = impactPercent,
							combinedImpactStr = combinedImpactStr,
							pathDist = pathDist,
							perPoint = perPoint * ((displayStat.pc or displayStat.mod) and 100 or 1),
							perPointStr = perPointStr,
						})
					end

					processed = processed + 1
					if coroutine.running() and GetTime() - start > 100 then
						self.comparePowerProgress = m_floor(processed / total * 100)
						coroutine.yield()
						start = GetTime()
					end
				end
			end
		end
	end

	-- ==========================================
	-- Items
	-- ==========================================
	if categories.items then
		local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }
		if self:ShouldShowRing3(compareEntry) then
			t_insert(baseSlots, 10, "Ring 3")
		end
		for _, slotName in ipairs(baseSlots) do
			local cSlot = compareEntry.itemsTab and compareEntry.itemsTab.slots[slotName]
			local cItem = cSlot and compareEntry.itemsTab.items[cSlot.selItemId]
			local pSlot = self.primaryBuild.itemsTab and self.primaryBuild.itemsTab.slots[slotName]
			local pItem = pSlot and self.primaryBuild.itemsTab.items[pSlot.selItemId]
			if cItem and cItem.raw and not (pItem and pItem.name == cItem.name) then
				local newItem = new("Item", cItem.raw)
				newItem:NormaliseQuality()
				local output = calcFunc({ repSlotName = slotName, repItem = newItem }, useFullDPS)
				local impact = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, output, calcBase)
				local impactStr, impactVal, combinedImpactStr, impactPercent, impactIsZero = formatImpact(impact)

				if not impactIsZero then
					-- Get rarity color for item name
					local rarityColor = colorCodes[cItem.rarity] or colorCodes.NORMAL

					t_insert(results, {
						category = "Item",
						categoryColor = rarityColor,
						nameColor = rarityColor,
						name = (cItem.name or "Unknown") .. ", " .. slotName,
						itemObj = newItem,
						slotName = slotName,
						impact = impactVal,
						impactStr = impactStr,
						impactPercent = impactPercent,
						combinedImpactStr = combinedImpactStr,
						pathDist = nil,
						perPoint = nil,
						perPointStr = nil,
					})
				end
			end
			processed = processed + 1
			if coroutine.running() and GetTime() - start > 100 then
				self.comparePowerProgress = m_floor(processed / total * 100)
				coroutine.yield()
				start = GetTime()
			end
		end
	end

	-- ==========================================
	-- Jewels (included as items)
	-- ==========================================
	if categories.items then
		-- Build list of jewel socket info in the primary build for fallback testing
		-- Each entry has { slotName, nodeId, node, allocated }
		local pSpec = self.primaryBuild.spec
		local primaryJewelSockets = {}
		for _, slot in ipairs(self.primaryBuild.itemsTab.orderedSlots) do
			if slot.nodeId then
				local node = pSpec.nodes[slot.nodeId]
				local allocated = pSpec.allocNodes and pSpec.allocNodes[slot.nodeId] and true or false
				if node then
					t_insert(primaryJewelSockets, {
						slotName = slot.slotName,
						nodeId = slot.nodeId,
						node = node,
						allocated = allocated,
					})
				end
			end
		end

		local jewelSlots = self:GetJewelComparisonSlots(compareEntry)
		for _, jEntry in ipairs(jewelSlots) do
			if jEntry.cItem and jEntry.cItem.raw and not (jEntry.pItem and jEntry.pItem.name == jEntry.cItem.name) then
				local newItem = new("Item", jEntry.cItem.raw)
				newItem:NormaliseQuality()

				local bestImpactVal = nil
				local bestSlotLabel = jEntry.label

				if jEntry.pNodeAllocated then
					-- Socket is allocated in primary build, test directly in that socket
					local output = calcFunc({ repSlotName = jEntry.cSlotName, repItem = newItem }, useFullDPS)
					bestImpactVal = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, output, calcBase)
				else
					-- Socket is NOT allocated in primary build; try the jewel in every
					-- jewel socket on the primary build's tree, temporarily allocating
					-- unallocated sockets via addNodes so CalcSetup doesn't skip them
					for _, socketInfo in ipairs(primaryJewelSockets) do
						local override = { repSlotName = socketInfo.slotName, repItem = newItem }
						if not socketInfo.allocated then
							override.addNodes = { [socketInfo.node] = true }
						end
						local output = calcFunc(override, useFullDPS)
						local impact = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, output, calcBase)
						if bestImpactVal == nil or impact > bestImpactVal then
							bestImpactVal = impact
							bestSlotLabel = jEntry.label .. " (best socket)"
						end
					end
				end

				if bestImpactVal ~= nil then
					local impactStr, impactVal, combinedImpactStr, impactPercent, impactIsZero = formatImpact(bestImpactVal)
					if not impactIsZero then
					local rarityColor = colorCodes[jEntry.cItem.rarity] or colorCodes.NORMAL

					t_insert(results, {
						category = "Item",
						categoryColor = rarityColor,
						nameColor = rarityColor,
						name = (jEntry.cItem.name or "Unknown") .. ", " .. bestSlotLabel,
						itemObj = newItem,
						impact = impactVal,
						impactStr = impactStr,
						impactPercent = impactPercent,
						combinedImpactStr = combinedImpactStr,
						pathDist = nil,
						perPoint = nil,
						perPointStr = nil,
					})
					end
				end
			end
			processed = processed + 1
			if coroutine.running() and GetTime() - start > 100 then
				self.comparePowerProgress = m_floor(processed / total * 100)
				coroutine.yield()
				start = GetTime()
			end
		end
	end

	-- ==========================================
	-- Skill Gems (socket groups)
	-- ==========================================
	if categories.skillGems then
		local cGroups = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList or {}
		local pGroups = self.primaryBuild.skillsTab and self.primaryBuild.skillsTab.socketGroupList or {}

		-- Build signature set for primary groups
		local pSignatures = {}
		for _, group in ipairs(pGroups) do
			pSignatures[self:GetSocketGroupSignature(group)] = true
		end

		for _, cGroup in ipairs(cGroups) do
			local sig = self:GetSocketGroupSignature(cGroup)
			if sig ~= "" and not pSignatures[sig] then
				-- Temporarily add this socket group to primary build and recalculate
				t_insert(pGroups, cGroup)
				self.primaryBuild.buildFlag = true

				-- Get a fresh calculator with the added group (pcall to guarantee cleanup)
				local ok, gemCalcFunc, gemCalcBase = pcall(function()
					return self.calcs.getMiscCalculator(self.primaryBuild)
				end)

				-- Always remove the temporarily added group
				t_remove(pGroups)
				self.primaryBuild.buildFlag = true

				if not ok then
					-- gemCalcFunc contains the error message on failure; skip this group
					ConPrintf("Compare power (gem): %s", tostring(gemCalcFunc))
				else
					local impact = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, gemCalcBase, calcBase)
					local impactStr, impactVal, combinedImpactStr, impactPercent, impactIsZero = formatImpact(impact)
					if not impactIsZero then
						local label = self:GetSocketGroupLabel(cGroup)

						t_insert(results, {
							category = "Skill gem",
							categoryColor = colorCodes.GEM,
							nameColor = colorCodes.GEM,
							name = label,
							impact = impactVal,
							impactStr = impactStr,
							impactPercent = impactPercent,
							combinedImpactStr = combinedImpactStr,
							pathDist = nil,
							perPoint = nil,
							perPointStr = nil,
						})
					end
				end
			end
			processed = processed + 1
			if coroutine.running() and GetTime() - start > 100 then
				self.comparePowerProgress = m_floor(processed / total * 100)
				coroutine.yield()
				start = GetTime()
			end
		end
	end

	-- ==========================================
	-- Support Gems (from compared build's active skill)
	-- ==========================================
	if categories.supportGems then
		local cMainGroup = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList[compareEntry.mainSocketGroup]
		local pMainGroup = self.primaryBuild.skillsTab and self.primaryBuild.skillsTab.socketGroupList[self.primaryBuild.mainSocketGroup]

		if cMainGroup and pMainGroup then
			-- Collect support gem names already in primary build's main group
			local pSupportNames = {}
			for _, gem in ipairs(pMainGroup.gemList or {}) do
				local ge = self:GetGemGrantedEffect(gem)
				if ge and ge.support then
					local name = ge.name or gem.nameSpec
					if name then pSupportNames[name] = true end
				end
			end

			for _, cGem in ipairs(cMainGroup.gemList or {}) do
				local cGrantedEffect = self:GetGemGrantedEffect(cGem)
				if cGrantedEffect and cGrantedEffect.support then
					local name = cGrantedEffect.name or cGem.nameSpec
					if name and not pSupportNames[name] then
						-- Create a temporary copy of this support gem
						local tempGem = {
							nameSpec = cGem.nameSpec,
							level = cGem.level,
							quality = cGem.quality,
							qualityId = cGem.qualityId,
							enabled = cGem.enabled,
							grantedEffect = cGem.grantedEffect,
							gemData = cGem.gemData,
							count = cGem.count,
							enableGlobal1 = cGem.enableGlobal1,
							enableGlobal2 = cGem.enableGlobal2,
						}

						-- Temporarily add to primary build's main socket group
						t_insert(pMainGroup.gemList, tempGem)
						self.primaryBuild.buildFlag = true

						local ok, sgCalcFunc, sgCalcBase = pcall(function()
							return self.calcs.getMiscCalculator(self.primaryBuild)
						end)

						-- Always remove the temporarily added gem
						t_remove(pMainGroup.gemList)
						self.primaryBuild.buildFlag = true

						if not ok then
							ConPrintf("Compare power (support gem): %s", tostring(sgCalcFunc))
						else
							local impact = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, sgCalcBase, calcBase)
							local impactStr, impactVal, combinedImpactStr, impactPercent, impactIsZero = formatImpact(impact)

							if not impactIsZero then
								t_insert(results, {
									category = "Support gem",
									categoryColor = colorCodes.GEM,
									nameColor = colorCodes.GEM,
									name = name,
									impact = impactVal,
									impactStr = impactStr,
									impactPercent = impactPercent,
									combinedImpactStr = combinedImpactStr,
									pathDist = nil,
									perPoint = nil,
									perPointStr = nil,
								})
							end
						end
						processed = processed + 1
						if coroutine.running() and GetTime() - start > 100 then
							self.comparePowerProgress = m_floor(processed / total * 100)
							coroutine.yield()
							start = GetTime()
						end
					end
				end
			end
		end
	end

	-- ==========================================
	-- Config Options
	-- ==========================================
	if categories.config then
		local pInput = self.primaryBuild.configTab.input
		local cInput = compareEntry.configTab.input or {}

		local function stripColors(s)
			return s:gsub("%^%x", ""):gsub("%^x%x%x%x%x%x%x", "")
		end

		for _, varData in ipairs(self.configOptions) do
			if varData.var and varData.apply and varData.type ~= "text" then
				local pVal = pInput[varData.var]
				local cVal = cInput[varData.var]
				local pNorm, cNorm = self:NormalizeConfigVals(varData, pVal, cVal)

				if pNorm ~= cNorm then
					-- Save original value
					local savedVal = pInput[varData.var]

					-- Apply compare build's config value
					pInput[varData.var] = cVal

					-- Rebuild and calculate (pcall to guarantee restore on error)
					local ok, cfgCalcFunc, cfgCalcBase = pcall(function()
						self.primaryBuild.configTab:BuildModList()
						self.primaryBuild.buildFlag = true
						return self.calcs.getMiscCalculator(self.primaryBuild)
					end)

					-- Always restore original value
					pInput[varData.var] = savedVal
					self.primaryBuild.configTab:BuildModList()
					self.primaryBuild.buildFlag = true

					if not ok then
						-- cfgCalcFunc contains the error message on failure; skip this config
						ConPrintf("Compare power (config): %s", tostring(cfgCalcFunc))
					else
						local impact = self.primaryBuild.calcsTab:CalculatePowerStat(powerStat, cfgCalcBase, calcBase)
						local impactStr, impactVal, combinedImpactStr, impactPercent, impactIsZero = formatImpact(impact)

						-- Only include configs with non-zero impact
						if not impactIsZero then
							-- Build display name with value change description
							local displayName = varData.label or varData.var
							displayName = displayName:gsub(":$", "")

							local pDisplay = stripColors(self:FormatConfigValue(varData, pVal))
							local cDisplay = stripColors(self:FormatConfigValue(varData, cVal))

							t_insert(results, {
								category = "Config",
								categoryColor = colorCodes.FRACTURED,
								nameColor = "^7",
								name = displayName .. "  (" .. pDisplay .. " -> " .. cDisplay .. ")",
								impact = impactVal,
								impactStr = impactStr,
								impactPercent = impactPercent,
								combinedImpactStr = combinedImpactStr,
								pathDist = nil,
								perPoint = nil,
								perPointStr = nil,
							})
						end
					end

					processed = processed + 1
					if coroutine.running() and GetTime() - start > 100 then
						self.comparePowerProgress = m_floor(processed / total * 100)
						coroutine.yield()
						start = GetTime()
					end
				end
			end
		end
	end

	self.comparePowerResults = results
	self.comparePowerProgress = 100
end

-- Drive the compare power report coroutine
function CompareTabClass:RunComparePowerReport(compareEntry)
	-- Invalidate if compare entry changed
	if self.comparePowerCompareId ~= compareEntry then
		self.comparePowerCompareId = compareEntry
		self.comparePowerDirty = true
	end

	-- Start new calculation if dirty
	if self.comparePowerDirty and self.comparePowerStat then
		self.comparePowerDirty = false
		self.comparePowerResults = nil
		self.comparePowerProgress = 0
		self.comparePowerListSynced = false
		self.comparePowerCoroutine = coroutine.create(function()
			self:ComparePowerBuilder(compareEntry, self.comparePowerStat, self.comparePowerCategories)
		end)
	end

	-- Resume coroutine
	if self.comparePowerCoroutine then
		local res, errMsg = coroutine.resume(self.comparePowerCoroutine)
		if launch and launch.devMode and not res then
			error(errMsg)
		end
		if coroutine.status(self.comparePowerCoroutine) == "dead" then
			self.comparePowerCoroutine = nil
		end
	end
end

-- ============================================================
-- SUMMARY VIEW
-- ============================================================
function CompareTabClass:DrawSummary(vp, compareEntry)
	local primaryCalcs = self.primaryBuild.calcsTab
	local compareCalcs = compareEntry.calcsTab
	local primaryEnvMain = primaryCalcs and primaryCalcs.mainEnv
	local compareEnvMain = compareCalcs and compareCalcs.mainEnv

	-- If each selected builds skill is a minion skill, use it
	local primaryMinionSkill = primaryEnvMain and primaryEnvMain.player and primaryEnvMain.player.mainSkill
		and primaryEnvMain.player.mainSkill.minion and primaryEnvMain.minion
	local compareMinionSkill = compareEnvMain and compareEnvMain.player and compareEnvMain.player.mainSkill
		and compareEnvMain.player.mainSkill.minion and compareEnvMain.minion
	local summaryUseMinion = primaryMinionSkill or compareMinionSkill

	local primaryOutput = primaryMinionSkill and primaryEnvMain.minion.output or primaryCalcs.mainOutput
	local compareOutput = compareMinionSkill and compareEnvMain.minion.output or compareEntry:GetOutput()
	if not primaryOutput or not compareOutput then
		return
	end

	local lineHeight = 18
	local headerHeight = 22

	-- Column positions (col3R and col4 shift right dynamically to avoid name overlap)
	local col1 = LAYOUT.summaryCol1
	local col2R = LAYOUT.summaryCol2Right

	local primaryName = self:GetShortBuildName(self.primaryBuild.buildName)
	local compareName = compareEntry.label or "Compare Build"
	local primaryNameW = DrawStringWidth(headerHeight, "VAR", primaryName)
	local compareNameW = DrawStringWidth(headerHeight, "VAR", compareName)

	local minCol3R = col2R + compareNameW + 16
	local maxCol3R = vp.width - 200
	local col3R = m_min(m_max(LAYOUT.summaryCol3Right, minCol3R), maxCol3R)
	local col4 = col3R + 20

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(col1, drawY, "LEFT", headerHeight, "VAR", "^7Stat")
	DrawString(col2R, drawY, "RIGHT_X", headerHeight, "VAR", colorCodes.POSITIVE .. primaryName)
	DrawString(col3R, drawY, "RIGHT_X", headerHeight, "VAR",
		colorCodes.WARNING .. compareName)
	DrawString(col4, drawY, "LEFT", headerHeight, "VAR", "^7Difference")
	drawY = drawY + headerHeight + 4

	-- Separator
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 6

	-- Stat comparison
	local displayStats = summaryUseMinion and self.primaryBuild.minionDisplayStats or self.primaryBuild.displayStats
	local primaryActor = primaryMinionSkill and primaryEnvMain.minion or primaryEnvMain.player
	local compareActor = compareMinionSkill and compareEnvMain.minion or compareEnvMain.player

	drawY = self:DrawStatList(drawY, displayStats, primaryOutput, compareOutput, primaryActor, compareActor, col1, col4, col2R, col3R)

	-- ========================================
	-- Compare Power Report section
	-- ========================================
	drawY = drawY + 16

	-- Separator
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 8

	-- Header
	SetDrawColor(1, 1, 1)
	DrawString(LAYOUT.powerReportLeft, drawY, "LEFT", 20, "VAR", "^7Compare Power Report")
	drawY = drawY + 24

	-- Run the coroutine driver (advances calculation each frame)
	self:RunComparePowerReport(compareEntry)

	-- Position controls dynamically based on drawY
	-- The controls need absolute screen positions (vp.x/vp.y offset + viewport-local drawY)
	-- drawY already includes the scroll offset (starts at 4 - self.scrollY)
	local controlY = vp.y + drawY
	local ctrlBaseX = vp.x + LAYOUT.powerReportLeft

	-- Metric dropdown
	self.controls.comparePowerStatSelect.x = ctrlBaseX + 60
	self.controls.comparePowerStatSelect.y = controlY

	-- Label for dropdown
	DrawString(LAYOUT.powerReportLeft, drawY, "LEFT", 16, "VAR", "^7Metric:")

	-- Category checkboxes (positioned to the right of dropdown)
	local checkX = ctrlBaseX + 280
	self.controls.comparePowerTreeCheck.x = checkX + self.controls.comparePowerTreeCheck.labelWidth
	self.controls.comparePowerTreeCheck.y = controlY
	checkX = checkX + self.controls.comparePowerTreeCheck.labelWidth + 26

	self.controls.comparePowerItemsCheck.x = checkX + self.controls.comparePowerItemsCheck.labelWidth
	self.controls.comparePowerItemsCheck.y = controlY
	checkX = checkX + self.controls.comparePowerItemsCheck.labelWidth + 26

	self.controls.comparePowerGemsCheck.x = checkX + self.controls.comparePowerGemsCheck.labelWidth
	self.controls.comparePowerGemsCheck.y = controlY
	checkX = checkX + self.controls.comparePowerGemsCheck.labelWidth + 26

	self.controls.comparePowerSupportGemsCheck.x = checkX + self.controls.comparePowerSupportGemsCheck.labelWidth
	self.controls.comparePowerSupportGemsCheck.y = controlY
	checkX = checkX + self.controls.comparePowerSupportGemsCheck.labelWidth + 26

	self.controls.comparePowerConfigCheck.x = checkX + self.controls.comparePowerConfigCheck.labelWidth
	self.controls.comparePowerConfigCheck.y = controlY

	drawY = drawY + 28

	-- Update the list control with current data (only when changed)
	local listControl = self.controls.comparePowerReportList
	if self.comparePowerCoroutine then
		listControl:SetProgress(self.comparePowerProgress)
		self.comparePowerListSynced = false
	elseif self.comparePowerResults and not self.comparePowerListSynced then
		listControl:SetReport(self.comparePowerStat, self.comparePowerResults)
		self.comparePowerListSynced = true
	elseif not self.comparePowerStat and not self.comparePowerListSynced then
		listControl:SetReport(nil, nil)
		self.comparePowerListSynced = true
	end

	-- Update the impact column label to match the selected stat
	if self.comparePowerStat then
		listControl.impactColumn.label = self.comparePowerStat.label or ""
	end

	-- Position the list control (absolute screen coordinates).
	-- The list has a fixed height and its own internal scrollbar for rows.
	-- Width matches the table columns (750) plus scrollbar (20px border/scroll area).
	local listHeight = 250
	local listWidth = 770
	listControl.x = vp.x + LAYOUT.powerReportLeft
	listControl.y = vp.y + drawY
	listControl.width = listWidth
	listControl.height = listHeight

	drawY = drawY + listHeight + 20 -- bottom padding

	SetViewport()
end


function CompareTabClass:DrawStatList(drawY, displayStats, primaryOutput, compareOutput, primaryActor, compareActor, col1, col4, col2R, col3R)
	local lineHeight = 16

	-- Get skill flags from each build's selected actor (player, or minion when the
	-- top-section "Skill:" is a minion skill) for stat filtering
	local primaryFlags = primaryActor and primaryActor.mainSkill and primaryActor.mainSkill.skillFlags or {}
	local compareFlags = compareActor and compareActor.mainSkill and compareActor.mainSkill.skillFlags or {}

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
				DrawString(col2R, drawY, "RIGHT_X", lineHeight, "VAR", "^7" .. primaryStr)
				DrawString(col3R, drawY, "RIGHT_X", lineHeight, "VAR", colorCodes.SPLITPERSONALITY .. compareStr)
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
				DrawString(col2R, drawY, "RIGHT_X", lineHeight, "VAR", "^7" .. (primaryShown and valStr or "-"))
				DrawString(col3R, drawY, "RIGHT_X", lineHeight, "VAR", colorCodes.WARNING .. (compareShown and valStr or "-"))
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

-- Draw a single item's full details at (x, startY) within colWidth.
-- otherModMap: optional table from buildModMap() of the other item for diff highlighting.
-- Returns the total height consumed.
function CompareTabClass:DrawItemExpanded(item, x, startY, colWidth, otherModMap)
	local lineHeight = 16
	local fontSize = 14
	local drawY = startY

	if not item then
		DrawString(x, drawY, "LEFT", fontSize, "VAR", "^8(empty)")
		return lineHeight
	end

	-- Item name
	local rarityColor = tradeHelpers.getRarityColor(item)
	DrawString(x, drawY, "LEFT", 16, "VAR", rarityColor .. item.name)
	drawY = drawY + 18

	-- Base type label
	local base = item.base
	if base then
		if base.weapon then
			local weaponData = item.weaponData and item.weaponData[1]
			if weaponData then
				if weaponData.PhysicalDPS then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FPhys DPS: " .. colorCodes.MAGIC .. "%.1f", weaponData.PhysicalDPS))
					drawY = drawY + lineHeight
				end
				if weaponData.ElementalDPS then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FEle DPS: " .. colorCodes.MAGIC .. "%.1f", weaponData.ElementalDPS))
					drawY = drawY + lineHeight
				end
				if weaponData.ChaosDPS then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FChaos DPS: " .. colorCodes.MAGIC .. "%.1f", weaponData.ChaosDPS))
					drawY = drawY + lineHeight
				end
				if weaponData.TotalDPS then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FTotal DPS: " .. colorCodes.MAGIC .. "%.1f", weaponData.TotalDPS))
					drawY = drawY + lineHeight
				end
				DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FCrit: " .. colorCodes.MAGIC .. "%.2f%%", weaponData.CritChance))
				drawY = drawY + lineHeight
				DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FAPS: " .. colorCodes.MAGIC .. "%.2f", weaponData.AttackRate))
				drawY = drawY + lineHeight
			end
		elseif base.armour then
			local armourData = item.armourData
			if armourData then
				if armourData.Armour and armourData.Armour > 0 then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FArmour: " .. colorCodes.MAGIC .. "%d", armourData.Armour))
					drawY = drawY + lineHeight
				end
				if armourData.Evasion and armourData.Evasion > 0 then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FEvasion: " .. colorCodes.MAGIC .. "%d", armourData.Evasion))
					drawY = drawY + lineHeight
				end
				if armourData.EnergyShield and armourData.EnergyShield > 0 then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FES: " .. colorCodes.MAGIC .. "%d", armourData.EnergyShield))
					drawY = drawY + lineHeight
				end
				if armourData.Ward and armourData.Ward > 0 then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FWard: " .. colorCodes.MAGIC .. "%d", armourData.Ward))
					drawY = drawY + lineHeight
				end
				if armourData.BlockChance and armourData.BlockChance > 0 then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FBlock: " .. colorCodes.MAGIC .. "%d%%", armourData.BlockChance))
					drawY = drawY + lineHeight
				end
			end
		elseif base.flask then
			local flaskData = item.flaskData
			if flaskData then
				if flaskData.lifeTotal then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FLife: " .. colorCodes.MAGIC .. "%d ^x7F7F7F(%.1fs)", flaskData.lifeTotal, flaskData.duration or 0))
					drawY = drawY + lineHeight
				end
				if flaskData.manaTotal then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FMana: " .. colorCodes.MAGIC .. "%d ^x7F7F7F(%.1fs)", flaskData.manaTotal, flaskData.duration or 0))
					drawY = drawY + lineHeight
				end
				if not flaskData.lifeTotal and not flaskData.manaTotal and flaskData.duration then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FDuration: " .. colorCodes.MAGIC .. "%.2fs", flaskData.duration))
					drawY = drawY + lineHeight
				end
				if flaskData.chargesUsed and flaskData.chargesMax then
					DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FCharges: " .. colorCodes.MAGIC .. "%d/%d", flaskData.chargesUsed, flaskData.chargesMax))
					drawY = drawY + lineHeight
				end
				-- Flask buff mods
				if item.buffModLines then
					for _, modLine in pairs(item.buffModLines) do
						local color = modLine.extra and colorCodes.UNSUPPORTED or colorCodes.MAGIC
						DrawString(x, drawY, "LEFT", fontSize, "VAR", color .. modLine.line)
						drawY = drawY + lineHeight
					end
				end
			end
		end

		-- Quality (if not shown in type-specific section)
		if item.quality and item.quality > 0 and not base.weapon and not base.armour and not base.flask then
			DrawString(x, drawY, "LEFT", fontSize, "VAR", s_format("^x7F7F7FQuality: " .. colorCodes.MAGIC .. "+%d%%", item.quality))
			drawY = drawY + lineHeight
		end
	end

	-- Separator before mods
	if drawY > startY + 18 then
		drawY = drawY + 2
	end

	-- Mod lines with diff highlighting
	for _, modListData in ipairs{item.enchantModLines or {}, item.scourgeModLines or {}, item.implicitModLines or {}, item.explicitModLines or {}, item.crucibleModLines or {}} do
		local drewAny = false
		for _, modLine in ipairs(modListData) do
			if item:CheckModLineVariant(modLine) then
				local formatted = itemLib.formatModLine(modLine)
				if formatted then
					if otherModMap then
						local template = tradeHelpers.modLineTemplate(modLine.line)
						local otherEntry = otherModMap[template]
						if not otherEntry then
							-- Mod exists only on this side
							formatted = colorCodes.POSITIVE .. "+ " .. formatted
						elseif otherEntry.line ~= modLine.line then
							-- Same mod template but different values
							local myVal = tradeHelpers.modLineValue(modLine.line)
							local otherVal = otherEntry.value
							if myVal > otherVal then
								formatted = colorCodes.POSITIVE .. "> " .. formatted
							elseif myVal < otherVal then
								formatted = colorCodes.NEGATIVE .. "< " .. formatted
							end
							-- If equal after rounding, no indicator needed
						end
						-- If exact match (same line text), no indicator — it's identical
					end
					DrawString(x, drawY, "LEFT", fontSize, "VAR", formatted)
					drawY = drawY + lineHeight
					drewAny = true
				end
			end
		end
		if drewAny then
			drawY = drawY + 2 -- small gap between mod sections
		end
	end

	-- Corrupted/Split/Mirrored
	if item.corrupted then
		DrawString(x, drawY, "LEFT", fontSize, "VAR", colorCodes.NEGATIVE .. "Corrupted")
		drawY = drawY + lineHeight
	end
	if item.split then
		DrawString(x, drawY, "LEFT", fontSize, "VAR", colorCodes.NEGATIVE .. "Split")
		drawY = drawY + lineHeight
	end
	if item.mirrored then
		DrawString(x, drawY, "LEFT", fontSize, "VAR", colorCodes.NEGATIVE .. "Mirrored")
		drawY = drawY + lineHeight
	end

	return drawY - startY
end

function CompareTabClass:ShouldShowRing3(compareEntry)
	local primaryEnv = self.primaryBuild.calcsTab and self.primaryBuild.calcsTab.mainEnv
	local compareEnv = compareEntry.calcsTab and compareEntry.calcsTab.mainEnv
	local primaryHas = primaryEnv and primaryEnv.modDB:Flag(nil, "AdditionalRingSlot")
	local compareHas = compareEnv and compareEnv.modDB:Flag(nil, "AdditionalRingSlot")
	return primaryHas or compareHas
end

function CompareTabClass:DrawItems(vp, compareEntry, inputEvents)
	local baseSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }
	if self:ShouldShowRing3(compareEntry) then
		t_insert(baseSlots, 10, "Ring 3")
	end
	local primaryEnv = self.primaryBuild.calcsTab and self.primaryBuild.calcsTab.mainEnv
	local primaryHasRing3 = primaryEnv and primaryEnv.modDB:Flag(nil, "AdditionalRingSlot")
	local lineHeight = 20
	local colWidth = m_floor(vp.width / 2)

	local checkboxOffset = LAYOUT.itemsCheckboxOffset
	SetViewport(vp.x, vp.y + checkboxOffset, vp.width, vp.height - checkboxOffset)
	local drawY = 4 - self.scrollY

	-- Get cursor position relative to viewport for hover detection
	local cursorX, cursorY = GetCursorPos()
	cursorX = cursorX - vp.x
	cursorY = cursorY - (vp.y + checkboxOffset)
	local hoverItem = nil
	local hoverX, hoverY = 0, 0
	local hoverW, hoverH = 0, 0
	local hoverItemsTab = nil

	-- Track item copy button clicks
	local clickedCopySlot = nil
	local clickedCopyUseSlot = nil
	local clickedBuySlot = nil
	local clickedBuyItem = nil

	-- Track Copy+Use button hover for stat comparison tooltip
	local hoverCopyUseItem = nil
	local hoverCopyUseSlotName = nil
	local hoverCopyUseBtnX, hoverCopyUseBtnY = 0, 0
	local hoverCopyUseBtnW, hoverCopyUseBtnH = 0, 0

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", 18, "VAR", colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(colWidth + 10, drawY, "LEFT", 18, "VAR", colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	drawY = drawY + 24

	-- Pre-compute max slot label width for alignment
	local maxLabelW = 0
	for _, sn in ipairs(baseSlots) do
		local w = DrawStringWidth(16, "VAR", "^7" .. sn .. ":")
		if w > maxLabelW then maxLabelW = w end
	end
	maxLabelW = maxLabelW + 2

	-- Helper: process copy/buy button hover state and click events for a slot.
	-- Closes over hoverCopyUse*/clicked* locals above.
	local function processSlotButtons(b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H, cItem, copySlotName, copyUseSlotName)
		if b2Hover and cItem then
			hoverCopyUseItem = cItem
			hoverCopyUseSlotName = copyUseSlotName
			hoverCopyUseBtnX, hoverCopyUseBtnY = b2X, b2Y
			hoverCopyUseBtnW, hoverCopyUseBtnH = b2W, b2H
		end
		if cItem and inputEvents then
			for id, event in ipairs(inputEvents) do
				if event.type == "KeyUp" and event.key == "LEFTBUTTON" then
					if b1Hover then
						clickedCopySlot = copySlotName
						inputEvents[id] = nil
					elseif b2Hover then
						clickedCopyUseSlot = copyUseSlotName
						inputEvents[id] = nil
					elseif b3Hover then
						clickedBuySlot = copyUseSlotName
						clickedBuyItem = cItem
						inputEvents[id] = nil
					end
				end
			end
		end
	end

	-- Helper: draw a single slot entry (expanded or compact mode).
	-- Closes over drawY, colWidth, cursorX/Y, vp, self, compareEntry, hoverItem/hoverX/Y/W/H/hoverItemsTab.
	local function drawSlotEntry(label, pItem, cItem, copySlotName, copyUseSlotName, labelW, pWarn, cWarn, slotMissing)
		if self.itemsExpandedMode then
			-- === EXPANDED MODE ===
			SetDrawColor(1, 1, 1)
			DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. label .. ":" .. (pWarn or ""))
			DrawString(colWidth - 10, drawY, "RIGHT", 14, "VAR", tradeHelpers.getSlotDiffLabel(pItem, cItem))

			if cItem then
				local b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H = tradeHelpers.drawCopyButtons(cursorX, cursorY, vp.width - 214, drawY + 1, slotMissing, LAYOUT.itemsCopyBtnW, LAYOUT.itemsCopyBtnH, LAYOUT.itemsBuyBtnW, LAYOUT.itemsCopyUseBtnW)
				processSlotButtons(b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H, cItem, copySlotName, copyUseSlotName)
			end

			drawY = drawY + 20

			local pModMap = tradeHelpers.buildModMap(pItem)
			local cModMap = tradeHelpers.buildModMap(cItem)
			local itemStartY = drawY
			local leftHeight = self:DrawItemExpanded(pItem, 20, drawY, colWidth - 30, cModMap)
			local rightHeight = self:DrawItemExpanded(cItem, colWidth + 20, drawY, colWidth - 30, pModMap)

			SetDrawColor(0.25, 0.25, 0.25)
			local maxH = m_max(leftHeight, rightHeight)
			DrawImage(nil, colWidth, itemStartY, 1, maxH)

			drawY = drawY + maxH + 6
		else
			-- === COMPACT MODE ===
			local pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H,
				rowHoverItem, rowHoverItemsTab, rowHoverX, rowHoverY, rowHoverW, rowHoverH =
				tradeHelpers.drawCompactSlotRow(drawY, label, pItem, cItem,
					colWidth, cursorX, cursorY, labelW,
					self.primaryBuild.itemsTab, compareEntry.itemsTab, pWarn, cWarn, slotMissing,
					LAYOUT.itemsCopyBtnW, LAYOUT.itemsCopyBtnH, LAYOUT.itemsBuyBtnW, LAYOUT.itemsCopyUseBtnW)

			if rowHoverItem then
				hoverItem = rowHoverItem
				hoverItemsTab = rowHoverItemsTab
				hoverX, hoverY = rowHoverX, rowHoverY
				hoverW, hoverH = rowHoverW, rowHoverH
			end

			processSlotButtons(b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H, cItem, copySlotName, copyUseSlotName)

			drawY = drawY + 20
		end
	end

	for _, slotName in ipairs(baseSlots) do
		-- Separator
		SetDrawColor(0.3, 0.3, 0.3)
		DrawImage(nil, 4, drawY, vp.width - 8, 1)
		drawY = drawY + 2

		-- Get items from both builds
		local pSlot = self.primaryBuild.itemsTab and self.primaryBuild.itemsTab.slots and self.primaryBuild.itemsTab.slots[slotName]
		local cSlot = compareEntry.itemsTab and compareEntry.itemsTab.slots and compareEntry.itemsTab.slots[slotName]
		local pItem = pSlot and self.primaryBuild.itemsTab.items and self.primaryBuild.itemsTab.items[pSlot.selItemId]
		local cItem = cSlot and compareEntry.itemsTab and compareEntry.itemsTab.items and compareEntry.itemsTab.items[cSlot.selItemId]

		local slotMissing = slotName == "Ring 3" and not primaryHasRing3
		drawSlotEntry(slotName, pItem, cItem, slotName, slotName, maxLabelW, nil, nil, slotMissing)
	end

	-- === TREE SET DROPDOWNS ===
	drawY = drawY + 12
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 1)
	drawY = drawY + 10

	-- Convert drawY to absolute screen coords for control positioning
	local absY = vp.y + checkboxOffset + drawY
	local treeSetLabelW = DrawStringWidth(16, "VAR", "^7Tree set:") + 4

	self.controls.primaryTreeSetLabel.x = vp.x + 10
	self.controls.primaryTreeSetLabel.y = absY + 2
	self.controls.primaryTreeSetSelect.x = vp.x + 10 + treeSetLabelW
	self.controls.primaryTreeSetSelect.y = absY

	self.controls.compareTreeSetLabel.x = vp.x + colWidth + 10
	self.controls.compareTreeSetLabel.y = absY + 2
	self.controls.compareTreeSetSelect.x = vp.x + colWidth + 10 + treeSetLabelW
	self.controls.compareTreeSetSelect.y = absY

	-- Populate tree set lists
	if self.primaryBuild.treeTab then
		self.controls.primaryTreeSetSelect.list = self.primaryBuild.treeTab:GetSpecList()
		self.controls.primaryTreeSetSelect.selIndex = self.primaryBuild.treeTab.activeSpec
	end
	if compareEntry.treeTab then
		self.controls.compareTreeSetSelect.list = compareEntry.treeTab:GetSpecList()
		self.controls.compareTreeSetSelect.selIndex = compareEntry.treeTab.activeSpec
	end

	drawY = drawY + 24

	-- === JEWELS SECTION ===
	local jewelSlots = self:GetJewelComparisonSlots(compareEntry)
	if #jewelSlots > 0 then
		-- Section header
		SetDrawColor(1, 1, 1)
		DrawString(10, drawY, "LEFT", 16, "VAR", "^7-- Jewels --")
		drawY = drawY + 20

		-- Pre-compute max jewel label width for alignment
		local maxJewelLabelW = maxLabelW
		for _, jE in ipairs(jewelSlots) do
			local w = DrawStringWidth(16, "VAR", "^7" .. jE.label .. ":") + 2
			if w > maxJewelLabelW then maxJewelLabelW = w end
		end

		for jIdx, jEntry in ipairs(jewelSlots) do
			-- Separator (skip before first jewel since section header already has one)
			if jIdx > 1 then
				SetDrawColor(0.3, 0.3, 0.3)
				DrawImage(nil, 4, drawY, vp.width - 8, 1)
				drawY = drawY + 2
			end

			-- Tree allocation warning text
			local pWarn = (jEntry.pItem and not jEntry.pNodeAllocated) and colorCodes.WARNING .. "  (tree missing allocated node)" or ""
			local cWarn = (jEntry.cItem and not jEntry.cNodeAllocated) and colorCodes.WARNING .. "  (tree missing allocated node)" or ""

			drawSlotEntry(jEntry.label, jEntry.pItem, jEntry.cItem, jEntry.cSlotName, jEntry.pSlotName, maxJewelLabelW, pWarn, cWarn, nil)
		end
	end

	-- Process item copy button clicks
	if clickedCopySlot then
		self:CopyCompareItemToPrimary(clickedCopySlot, compareEntry, false)
	elseif clickedCopyUseSlot then
		self:CopyCompareItemToPrimary(clickedCopyUseSlot, compareEntry, true)
	end

	-- Process buy button click
	if clickedBuySlot and clickedBuyItem then
		buySimilar.openPopup(clickedBuyItem, clickedBuySlot, self.primaryBuild)
	end

	-- Draw item tooltip on hover (compact mode only, on top of everything)
	if hoverItem and hoverItemsTab then
		self.itemTooltip:Clear()
		hoverItemsTab:AddItemTooltip(self.itemTooltip, hoverItem, nil)
		SetDrawLayer(nil, 100)
		self.itemTooltip:Draw(hoverX, hoverY, hoverW, hoverH, vp)
		SetDrawLayer(nil, 0)
	end

	-- Draw stat comparison tooltip when hovering Copy+Use button
	if hoverCopyUseItem and hoverCopyUseSlotName and not hoverItem then
		self.itemTooltip:Clear()
		local calcFunc, calcBase = self.calcs.getMiscCalculator(self.primaryBuild)
		if calcFunc then
			-- Create a fresh item to evaluate
			local newItem = new("Item", hoverCopyUseItem.raw)
			newItem:NormaliseQuality()

			-- Determine what's currently in the target slot
			local pSlot = self.primaryBuild.itemsTab.slots[hoverCopyUseSlotName]
			local selItem = pSlot and self.primaryBuild.itemsTab.items[pSlot.selItemId]

			-- For jewel sockets that aren't allocated, temporarily allocate the node
			local override = { repSlotName = hoverCopyUseSlotName, repItem = newItem }
			if pSlot and pSlot.nodeId then
				local pSpec = self.primaryBuild.spec
				if pSpec and pSpec.allocNodes and not pSpec.allocNodes[pSlot.nodeId] then
					local node = pSpec.nodes[pSlot.nodeId]
					if node then
						override.addNodes = { [node] = true }
					end
				end
			end

			local output = calcFunc(override)
			local slotLabel = pSlot and pSlot.label or hoverCopyUseSlotName
			local header
			if selItem then
				header = string.format("^7Equipping this item in %s will give you:\n(replacing %s%s^7)", slotLabel, colorCodes[selItem.rarity] or "^7", selItem.name)
			else
				header = string.format("^7Equipping this item in %s will give you:", slotLabel)
			end
			local count = self.primaryBuild:AddStatComparesToTooltip(self.itemTooltip, calcBase, output, header)
			if count == 0 then
				self.itemTooltip:AddLine(14, header)
				self.itemTooltip:AddLine(14, "^7No changes.")
			end
		end
		SetDrawLayer(nil, 100)
		-- Force tooltip to the left of the button by passing a large width
		-- so the right-side placement overflows and the Draw logic flips to left
		self.itemTooltip:Draw(hoverCopyUseBtnX, hoverCopyUseBtnY, vp.width, hoverCopyUseBtnH, vp)
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
	DrawString(10, drawY, "LEFT", 18, "VAR", colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(colWidth + 10, drawY, "LEFT", 18, "VAR", colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
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

	-- Helper: check if gemA supports gemB (mirrors GemSelectControl:CheckSupporting)
	local function checkSupporting(gemA, gemB)
		if not gemA.gemData or not gemB.gemData then return false end
		return (gemA.gemData.grantedEffect and gemA.gemData.grantedEffect.support
			and gemB.gemData.grantedEffect and not gemB.gemData.grantedEffect.support
			and gemA.supportEffect and gemA.supportEffect.isSupporting
			and gemA.supportEffect.isSupporting[gemB])
		or (gemA.gemData.secondaryGrantedEffect
			and gemA.gemData.secondaryGrantedEffect.support
			and gemB.gemData.grantedEffect and not gemB.gemData.grantedEffect.support
			and gemA.supportEffect and gemA.supportEffect.isSupporting
			and gemA.supportEffect.isSupporting[gemB])
	end

	local gemFontSize = 16
	local gemLineHeight = 18
	local gemTextWidth = colWidth - 30

	-- Helper: build aligned display lists for a matched pair of groups
	-- Common gems appear first, then additional, then missing
	local function getGemName(gem)
		return gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec
	end

	local function buildAlignedGemLists(pGroup, cGroup, pSet, cSet)
		local pDisplay = {}
		local cDisplay = {}

		-- Build name->gem lookup for compare side (common gems only)
		local cGemByName = {}
		if cGroup then
			for _, gem in ipairs(cGroup.gemList or {}) do
				local name = getGemName(gem)
				if name and pSet[name] and not cGemByName[name] then
					cGemByName[name] = gem
				end
			end
		end

		-- Common gems in primary build's order
		local emittedCommon = {}
		if pGroup then
			for _, gem in ipairs(pGroup.gemList or {}) do
				local name = getGemName(gem)
				if name and cSet[name] and not emittedCommon[name] then
					emittedCommon[name] = true
					t_insert(pDisplay, { gem = gem, name = name, status = "common" })
					t_insert(cDisplay, { gem = cGemByName[name], name = name, status = "common" })
				end
			end
		end

		-- Additional gems (unique to each side), preserving original order
		if pGroup then
			for _, gem in ipairs(pGroup.gemList or {}) do
				local name = getGemName(gem)
				if name and not cSet[name] then
					t_insert(pDisplay, { gem = gem, name = name, status = "additional" })
				end
			end
		end
		if cGroup then
			for _, gem in ipairs(cGroup.gemList or {}) do
				local name = getGemName(gem)
				if name and not pSet[name] then
					t_insert(cDisplay, { gem = gem, name = name, status = "additional" })
				end
			end
		end

		-- Missing gems (sorted alphabetically)
		if pGroup and cGroup then
			local pMissing = {}
			local cMissing = {}
			for name in pairs(cSet) do
				if not pSet[name] then t_insert(pMissing, name) end
			end
			for name in pairs(pSet) do
				if not cSet[name] then t_insert(cMissing, name) end
			end
			table.sort(pMissing)
			table.sort(cMissing)
			for _, name in ipairs(pMissing) do
				t_insert(pDisplay, { gem = nil, name = name, status = "missing" })
			end
			for _, name in ipairs(cMissing) do
				t_insert(cDisplay, { gem = nil, name = name, status = "missing" })
			end
		end

		return pDisplay, cDisplay
	end

	-- Helper: collect gem positions from a display list into gemEntries for hit-testing
	local function collectGemEntries(gemEntries, displayList, xOffset, startY, group)
		local y = startY
		for _, entry in ipairs(displayList) do
			if entry.gem then
				t_insert(gemEntries, { gem = entry.gem, x = xOffset, y = y, group = group })
			end
			y = y + gemLineHeight
		end
		return y
	end

	-- Helper: draw a list of gems (common, additional, missing) at a given x offset
	local function drawGemList(displayList, xOffset, startY, highlightSet)
		local y = startY
		for _, entry in ipairs(displayList) do
			if entry.status == "missing" then
				DrawString(xOffset, y, "LEFT", gemFontSize, "VAR", colorCodes.NEGATIVE .. "- " .. entry.name .. "^7")
			elseif entry.gem then
				if highlightSet[entry.gem] then
					SetDrawColor(0.33, 1, 0.33, 0.25)
					DrawImage(nil, xOffset, y, gemTextWidth, gemLineHeight)
				end
				local gemName = entry.gem.grantedEffect and entry.gem.grantedEffect.name or entry.gem.nameSpec or "?"
				local gemColor = entry.gem.color or colorCodes.GEM
				local levelStr = entry.gem.level and (" Lv" .. entry.gem.level) or ""
				local qualStr = entry.gem.quality and entry.gem.quality > 0 and ("/" .. entry.gem.quality .. "q") or ""
				local prefix = ""
				if entry.status == "additional" then
					prefix = colorCodes.POSITIVE .. "+ "
				end
				DrawString(xOffset, y, "LEFT", gemFontSize, "VAR", prefix .. gemColor .. gemName .. "^7" .. levelStr .. qualStr)
			end
			y = y + gemLineHeight
		end
		return y
	end

	-- Position pre-pass: compute gem positions without drawing to enable hover hit-testing
	local gemEntries = {} -- { gem, x, y, group }
	local preY = 4 - self.scrollY + 24 -- after headers
	for _, pair in ipairs(renderPairs) do
		preY = preY + 2 -- separator
		local pSet = pair.pIdx and pSets[pair.pIdx] or {}
		local cSet = pair.cIdx and cSets[pair.cIdx] or {}

		local pGroup = pair.pIdx and pGroups[pair.pIdx]
		local cGroup = pair.cIdx and cGroups[pair.cIdx]
		local pDisplayList, cDisplayList = buildAlignedGemLists(pGroup, cGroup, pSet, cSet)

		local pGemY = collectGemEntries(gemEntries, pDisplayList, 20, preY + lineHeight, pGroup)
		local cGemY = collectGemEntries(gemEntries, cDisplayList, colWidth + 20, preY + lineHeight, cGroup)

		preY = preY + m_max(pGemY - preY, cGemY - preY) + 6
	end

	-- Hit-test: find hovered gem
	local cursorX, cursorY = GetCursorPos()
	local localCursorX = cursorX - vp.x
	local localCursorY = cursorY - vp.y
	local hoveredEntry = nil
	if localCursorX >= 0 and localCursorX < vp.width and localCursorY >= 0 and localCursorY < vp.height then
		for _, entry in ipairs(gemEntries) do
			if localCursorX >= entry.x and localCursorX < entry.x + gemTextWidth
				and localCursorY >= entry.y and localCursorY < entry.y + gemLineHeight then
				hoveredEntry = entry
				break
			end
		end
	end

	-- Build set of highlighted gems based on hover
	local highlightSet = {}
	if hoveredEntry then
		highlightSet[hoveredEntry.gem] = true
		for _, entry in ipairs(gemEntries) do
			if entry.group == hoveredEntry.group and entry.gem ~= hoveredEntry.gem then
				if checkSupporting(hoveredEntry.gem, entry.gem) or checkSupporting(entry.gem, hoveredEntry.gem) then
					highlightSet[entry.gem] = true
				end
			end
		end
		-- Only keep highlights if there's at least one linked gem (not just the hovered one)
		local count = 0
		for _ in pairs(highlightSet) do count = count + 1 end
		if count <= 1 then
			highlightSet = {}
		end
	end

	-- Draw pass
	for _, pair in ipairs(renderPairs) do
		SetDrawColor(0.3, 0.3, 0.3)
		DrawImage(nil, 4, drawY, vp.width - 8, 1)
		drawY = drawY + 2

		local pSet = pair.pIdx and pSets[pair.pIdx] or {}
		local cSet = pair.cIdx and cSets[pair.cIdx] or {}
		local pFinalGemY = drawY + lineHeight
		local cFinalGemY = drawY + lineHeight

		-- Build aligned display lists
		local pGroup = pair.pIdx and pGroups[pair.pIdx]
		local cGroup = pair.cIdx and cGroups[pair.cIdx]
		local pDisplayList, cDisplayList = buildAlignedGemLists(pGroup, cGroup, pSet, cSet)

		-- Primary group label (left side)
		if pGroup then
			local groupLabel = pGroup.displayLabel or pGroup.label or ("Group " .. pair.pIdx)
			if pGroup.slot then
				groupLabel = groupLabel .. " (" .. pGroup.slot .. ")"
			end
			DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. groupLabel)
		end

		-- Compare group label (right side)
		if cGroup then
			local groupLabel = cGroup.displayLabel or cGroup.label or ("Group " .. pair.cIdx)
			if cGroup.slot then
				groupLabel = groupLabel .. " (" .. cGroup.slot .. ")"
			end
			DrawString(colWidth + 10, drawY, "LEFT", 16, "VAR", "^7" .. groupLabel)
		end

		pFinalGemY = drawGemList(pDisplayList, 20, drawY + lineHeight, highlightSet)
		cFinalGemY = drawGemList(cDisplayList, colWidth + 20, drawY + lineHeight, highlightSet)

		-- Calculate height for this row
		drawY = drawY + m_max(pFinalGemY - drawY, cFinalGemY - drawY) + 6
	end

	SetViewport()
end

-- ============================================================
-- CALCS TOOLTIP HELPERS (delegated to CompareCalcsHelpers)
-- ============================================================
function CompareTabClass:DrawCalcsTooltip(colData, rowLabel, rowX, rowY, rowW, rowH, vp, compareEntry)
	local primaryLabel = self:GetShortBuildName(self.primaryBuild.buildName)
	calcsHelpers.DrawCalcsTooltip(
		self.calcsTooltip, self.primaryBuild, primaryLabel,
		colData, rowLabel, rowX, rowY, rowW, rowH, vp, compareEntry
	)
end

-- ============================================================
-- CALCS VIEW (card-based sections with comparison)
-- ============================================================

-- Draw the skill detail header area with labels for controls and text info lines
function CompareTabClass:DrawCalcsSkillHeader(vp, compareEntry, headerHeight, primaryEnv, compareEnv)
	local colWidth = m_floor((vp.width - 20) / 2)
	local leftX = vp.x + 4
	local rightX = leftX + colWidth + 12
	local labelW = 100
	local rowH = 22
	local y = vp.y + 4

	-- Build name headers
	SetDrawColor(1, 1, 1)
	DrawString(leftX, y + 2, "LEFT", 18, "VAR",
		colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(rightX, y + 2, "LEFT", 18, "VAR",
		colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	y = y + rowH

	-- Draw labels next to each control row
	local function drawLabel(label, x, cy, control)
		if control.shown == false or (type(control.shown) == "function" and not control:IsShown()) then
			return false
		end
		DrawString(x, cy + 2, "LEFT", 14, "VAR", "^7" .. label .. ":")
		return true
	end

	local leftY = y
	local rightY = y

	-- Socket Group
	drawLabel("Socket Group", leftX, leftY, self.controls.primCalcsSocketGroup)
	drawLabel("Socket Group", rightX, rightY, self.controls.cmpCalcsSocketGroup)
	leftY = leftY + rowH
	rightY = rightY + rowH

	-- Active Skill
	if drawLabel("Active Skill", leftX, leftY, self.controls.primCalcsMainSkill) then leftY = leftY + rowH end
	if drawLabel("Active Skill", rightX, rightY, self.controls.cmpCalcsMainSkill) then rightY = rightY + rowH end

	-- Skill Part
	if drawLabel("Skill Part", leftX, leftY, self.controls.primCalcsSkillPart) then leftY = leftY + rowH end
	if drawLabel("Skill Part", rightX, rightY, self.controls.cmpCalcsSkillPart) then rightY = rightY + rowH end

	-- Stage Count
	if drawLabel("Stages", leftX, leftY, self.controls.primCalcsStageCount) then leftY = leftY + rowH end
	if drawLabel("Stages", rightX, rightY, self.controls.cmpCalcsStageCount) then rightY = rightY + rowH end

	-- Mine Count
	if drawLabel("Mines", leftX, leftY, self.controls.primCalcsMineCount) then leftY = leftY + rowH end
	if drawLabel("Mines", rightX, rightY, self.controls.cmpCalcsMineCount) then rightY = rightY + rowH end

	-- Show Minion Stats
	if drawLabel("Show Minion Stats", leftX, leftY, self.controls.primCalcsShowMinion) then leftY = leftY + rowH end
	if drawLabel("Show Minion Stats", rightX, rightY, self.controls.cmpCalcsShowMinion) then rightY = rightY + rowH end

	-- Minion
	if drawLabel("Minion", leftX, leftY, self.controls.primCalcsMinion) then leftY = leftY + rowH end
	if drawLabel("Minion", rightX, rightY, self.controls.cmpCalcsMinion) then rightY = rightY + rowH end

	-- Minion Skill
	if drawLabel("Minion Skill", leftX, leftY, self.controls.primCalcsMinionSkill) then leftY = leftY + rowH end
	if drawLabel("Minion Skill", rightX, rightY, self.controls.cmpCalcsMinionSkill) then rightY = rightY + rowH end

	-- Calc Mode
	drawLabel("Calc Mode", leftX, leftY, self.controls.primCalcsMode)
	drawLabel("Calc Mode", rightX, rightY, self.controls.cmpCalcsMode)
	leftY = leftY + rowH
	rightY = rightY + rowH

	-- Text info lines (Aura/Buffs, Combat Buffs, Curses)
	local textY = m_max(leftY, rightY) + 2
	local pOutput = primaryEnv.player and primaryEnv.player.output
	local cOutput = compareEnv.player and compareEnv.player.output
	self.calcsSkillHeaderHover = nil  -- Reset hover state
	if pOutput or cOutput then
		local cursorX, cursorY = GetCursorPos()
		local infoLines = {
			{ label = "Aura/Buff Skills", key = "BuffList", breakdown = "SkillBuffs" },
			{ label = "Combat Buffs", key = "CombatList" },
			{ label = "Curses/Debuffs", key = "CurseList", breakdown = "SkillDebuffs" },
		}
		for _, info in ipairs(infoLines) do
			local pVal = pOutput and pOutput[info.key]
			local cVal = cOutput and cOutput[info.key]
			if (pVal and pVal ~= "") or (cVal and cVal ~= "") then
				-- Check hover per-side for lines that have breakdown data
				if info.breakdown and cursorY >= textY and cursorY < textY + 18 then
					local onLeft = cursorX >= leftX and cursorX < rightX
					local onRight = cursorX >= rightX and cursorX < vp.x + vp.width
					if onLeft then
						SetDrawColor(0.15, 0.25, 0.15)
						DrawImage(nil, leftX, textY, colWidth, 18)
						self.calcsSkillHeaderHover = {
							breakdown = info.breakdown,
							label = info.label,
							build = self.primaryBuild,
							x = leftX, y = textY, w = colWidth, h = 18,
						}
					elseif onRight then
						SetDrawColor(0.15, 0.25, 0.15)
						DrawImage(nil, rightX, textY, colWidth, 18)
						self.calcsSkillHeaderHover = {
							breakdown = info.breakdown,
							label = info.label,
							build = compareEntry,
							x = rightX, y = textY, w = colWidth, h = 18,
						}
					end
				end
				DrawString(leftX, textY + 1, "LEFT", 14, "VAR", "^7" .. info.label .. ": " .. (pVal or ""))
				DrawString(rightX, textY + 1, "LEFT", 14, "VAR", "^7" .. info.label .. ": " .. (cVal or ""))
				textY = textY + 18
			end
		end
	end

	-- Separator line
	SetDrawColor(0.4, 0.4, 0.4)
	DrawImage(nil, vp.x + 2, vp.y + headerHeight - 2, vp.width - 4, 1)
end

function CompareTabClass:DrawCalcs(vp, compareEntry)
	-- Use calcsEnv for both values and tooltips (has breakdown data + respects Calcs skill selection)
	local primaryEnv = self.primaryBuild.calcsTab.calcsEnv
	local compareEnv = compareEntry.calcsTab and compareEntry.calcsTab.calcsEnv
	if not primaryEnv or not compareEnv then return end
	local primaryActor = (self.primaryBuild.calcsTab.input.showMinion and primaryEnv.minion) or primaryEnv.player
	local compareActor = (compareEntry.calcsTab.input.showMinion and compareEnv.minion) or compareEnv.player
	if not primaryActor or not compareActor then return end

	-- Skill detail header height
	local skillHeaderHeight = self.calcsSkillHeaderHeight or 0

	-- Draw skill detail header background and labels
	if skillHeaderHeight > 0 then
		self:DrawCalcsSkillHeader(vp, compareEntry, skillHeaderHeight, primaryEnv, compareEnv)
	end

	-- Reserve space on the right for the scrollbar
	local scrollBarWidth = 20
	local gridWidth = vp.width - scrollBarWidth

	-- Card dimensions
	-- Layout: [2px border | 130px label | 2px gap | 2px sep | valW | 2px sep | valW | 2px border]
	local cardWidth = m_min(LAYOUT.calcsMaxCardWidth, gridWidth - 16)
	local labelWidth = LAYOUT.calcsLabelWidth
	local sepW = LAYOUT.calcsSepW
	local valColWidth = m_floor((cardWidth - 140) / 2)
	local valCol1X = labelWidth + sepW * 2
	local valCol2X = valCol1X + valColWidth + sepW

	-- Layout parameters
	local maxCol = m_max(1, m_floor(gridWidth / (cardWidth + 8)))
	local baseX = 4
	local headerBarHeight = LAYOUT.calcsHeaderBarHeight
	local baseY = headerBarHeight

	-- Pre-compute section visibility and heights
	local sections = {}
	for _, secDef in ipairs(self.calcSections) do
		local secWidth, id, group, colour, subSections = secDef[1], secDef[2], secDef[3], secDef[4], secDef[5]
		local secData = subSections[1].data
		-- Check section-level flags against primary actor
		if self.primaryBuild.calcsTab:CheckFlag(secData, primaryActor) then
			local subSecInfo = {}
			local sectionHasRows = false
			for _, subSec in ipairs(subSections) do
				local rows = {}
				for _, rowData in ipairs(subSec.data) do
					-- Only include rows with a label and a first column with a format string
					if rowData.label and rowData[1] and rowData[1].format then
						if self.primaryBuild.calcsTab:CheckFlag(rowData, primaryActor) or self.primaryBuild.calcsTab:CheckFlag(rowData, compareActor) then
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

	-- Position scrollbar and set content dimensions based on laid-out content
	local scrollBar = self.controls.calcsScrollBar
	scrollBar.x = vp.x + vp.width - 18
	scrollBar.y = vp.y + skillHeaderHeight
	scrollBar.height = vp.height - skillHeaderHeight
	scrollBar:SetContentDimension(maxY + 26, vp.height - skillHeaderHeight)

	-- Set viewport for scroll clipping, offset below skill header so cards can't bleed into it
	SetViewport(vp.x, vp.y + skillHeaderHeight, gridWidth, vp.height - skillHeaderHeight)

	-- Cursor position relative to viewport (for hover detection)
	local cursorX, cursorY = GetCursorPos()
	local vpCursorX = cursorX - vp.x
	local vpCursorY = cursorY - (vp.y + skillHeaderHeight)
	local hoverColData = nil
	local hoverRowLabel = nil
	local hoverRowX, hoverRowY, hoverRowW, hoverRowH = 0, 0, 0, 0

	-- Draw section cards
	for _, sec in ipairs(sections) do
		local x = sec.drawX
		local y = sec.drawY - scrollBar.offset

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
					local ok1, pExtra = pcall(formatCalcStr, subSec.data.extra, primaryActor)
					local ok2, cExtra = pcall(formatCalcStr, subSec.data.extra, compareActor)
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

					-- Hover highlight
					local isHovered = vpCursorX >= x and vpCursorX < x + cardWidth
						and vpCursorY >= lineY and vpCursorY < lineY + 18
						and vpCursorY >= 0 and vpCursorY < vp.height
					local rowHovered = isHovered and colData
					if rowHovered then
						-- Draw green border around hovered row (matching normal CalcsTab style)
						SetDrawColor(0.25, 1, 0.25)
						DrawImage(nil, x + 2, lineY, cardWidth - 4, 18)
						SetDrawColor(rowData.bgCol or "^0")
						DrawImage(nil, x + 3, lineY + 1, cardWidth - 6, 16)
						hoverColData = colData
						hoverRowLabel = rowData.label
						hoverRowX = x
						hoverRowY = lineY
						hoverRowW = cardWidth
						hoverRowH = 18
					end

					-- Label background and text
					local bgCol = rowData.bgCol or "^0"
					if not rowHovered then
						SetDrawColor(bgCol)
						DrawImage(nil, x + 2, lineY, labelWidth - 2, 18)
					end
					local textColor = rowData.color or "^7"
					DrawString(x + labelWidth, lineY + 1, "RIGHT_X", 16, "VAR", textColor .. rowData.label .. "^7:")

					-- Primary value column
					if not rowHovered then
						SetDrawColor(sec.colour)
						DrawImage(nil, x + valCol1X - sepW, lineY, sepW, 18)
						SetDrawColor(bgCol)
						DrawImage(nil, x + valCol1X, lineY, valColWidth, 18)
					end
					if colData and colData.format then
						local ok, str = pcall(formatCalcStr, colData.format, primaryActor, colData)
						if ok and str then
							DrawString(x + valCol1X + 2, lineY + 9 - textSize / 2, "LEFT", textSize, "VAR", "^7" .. str)
						end
					end

					-- Compare value column
					if not rowHovered then
						SetDrawColor(sec.colour)
						DrawImage(nil, x + valCol2X - sepW, lineY, sepW, 18)
						SetDrawColor(bgCol)
						DrawImage(nil, x + valCol2X, lineY, valColWidth, 18)
					end
					if colData and colData.format then
						local ok, str = pcall(formatCalcStr, colData.format, compareActor, colData)
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

	-- Draw hover tooltip for calcs breakdown (reset viewport first so tooltip can extend beyond)
	if hoverColData then
		SetViewport()
		self:DrawCalcsTooltip(hoverColData, hoverRowLabel, hoverRowX + vp.x, hoverRowY + vp.y + skillHeaderHeight, hoverRowW, hoverRowH, vp, compareEntry)
	elseif self.calcsSkillHeaderHover then
		SetViewport()
		local hover = self.calcsSkillHeaderHover
		calcsHelpers.DrawSkillBreakdownPanel(
			hover.build, hover.breakdown, hover.label,
			hover.x, hover.y, hover.w, hover.h, vp
		)
	else
		SetViewport()
	end
end

-- ============================================================
-- CONFIG VIEW
-- ============================================================
function CompareTabClass:DrawConfig(vp, compareEntry)
	local rowHeight = LAYOUT.configRowHeight
	local columnHeaderHeight = LAYOUT.configColumnHeaderHeight
	local fixedHeaderHeight = LAYOUT.configFixedHeaderHeight
	local sectionInnerPad = LAYOUT.configSectionInnerPad
	local sectionWidth = LAYOUT.configSectionWidth
	local labelOffset = LAYOUT.configLabelOffset

	-- Fixed header area: row 1 = buttons, row 2 = search/dropdowns, then column headers + separator
	SetViewport(vp.x, vp.y, vp.width, fixedHeaderHeight)
	-- Controls are drawn by ControlHost (positioned in LayoutConfigView)
	local colHeaderY = 54
	SetDrawColor(1, 1, 1)
	-- Column headers aligned with first column's control offsets
	local headerBaseX = 10
	DrawString(headerBaseX + LAYOUT.configCol3 - 8, colHeaderY, "RIGHT_X", columnHeaderHeight, "VAR",
		colorCodes.POSITIVE .. self:GetShortBuildName(self.primaryBuild.buildName))
	DrawString(headerBaseX + LAYOUT.configCol3, colHeaderY, "LEFT", columnHeaderHeight, "VAR",
		colorCodes.WARNING .. (compareEntry.label or "Compare Build"))
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, colHeaderY + columnHeaderHeight + 4, vp.width - 8, 2)

	-- Scrollable content area (clipped below fixed header)
	local scrollH = vp.height - fixedHeaderHeight
	if scrollH <= 0 then
		SetViewport()
		return
	end
	SetViewport(vp.x, vp.y + fixedHeaderHeight, vp.width, scrollH)

	-- Draw section boxes
	for _, sec in ipairs(self.configSectionLayout) do
		local boxX = sec.x
		local boxY = sec.y - self.scrollY
		local boxH = sec.height

		-- Skip entirely off-screen sections
		if boxY + boxH >= 0 and boxY < scrollH then
			-- Draw section box
			SetDrawLayer(nil, -10)
			SetDrawColor(0.66, 0.66, 0.66)
			DrawImage(nil, boxX, boxY, sectionWidth, boxH)
			SetDrawColor(0.1, 0.1, 0.1)
			DrawImage(nil, boxX + 2, boxY + 2, sectionWidth - 4, boxH - 4)
			SetDrawLayer(nil, 0)

			-- Draw section label badge
			local labelText = sec.name
			if sec.diffCount > 0 then
				labelText = labelText .. "  (" .. sec.diffCount .. " diff)"
			end
			local labelWidth = DrawStringWidth(14, "VAR", labelText)
			SetDrawColor(0.66, 0.66, 0.66)
			DrawImage(nil, boxX + 6, boxY - 8, labelWidth + 6, 18)
			SetDrawColor(0, 0, 0)
			DrawImage(nil, boxX + 7, boxY - 7, labelWidth + 4, 16)
			SetDrawColor(1, 1, 1)
			DrawString(boxX + 9, boxY - 6, "LEFT", 14, "VAR", labelText)

			-- Draw rows inside section
			local rowY = boxY + sectionInnerPad
			for _, row in ipairs(sec.rows) do
				if rowY + rowHeight >= 0 and rowY < scrollH then
					local varData = row.ctrlInfo.varData
					-- Subtle highlight for diff rows
					if row.isDiff then
						SetDrawLayer(nil, -5)
						SetDrawColor(0.18, 0.14, 0.08)
						DrawImage(nil, boxX + 3, rowY, sectionWidth - 6, rowHeight)
						SetDrawLayer(nil, 0)
					end
					-- Label (reduce font size for long labels, matching ConfigTab behavior)
					local labelStr = varData.label or varData.var
					local labelSize = DrawStringWidth(14, "VAR", labelStr) > 228 and 12 or 14
					SetDrawColor(1, 1, 1)
					DrawString(boxX + labelOffset, rowY + 2, "LEFT", labelSize, "VAR",
						"^7" .. labelStr)
					-- Controls are drawn by ControlHost (positioned in LayoutConfigView)
				end
				rowY = rowY + rowHeight
			end
		end
	end

	if #self.configSectionLayout == 0 then
		DrawString(10, -self.scrollY, "LEFT", 16, "VAR",
			colorCodes.POSITIVE .. "No configuration options to display.")
	end

	SetViewport()
end



return CompareTabClass
