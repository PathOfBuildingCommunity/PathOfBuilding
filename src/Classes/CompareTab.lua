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
local queryModsData = LoadModule("Data/QueryMods")

-- Forward declarations for trade helper functions (defined later in the file)
local findTradeModId
local getTradeCategory
local getTradeCategoryLabel
local modLineValue

-- Realm display name to API id mapping (used by Buy Similar popup and URL builder)
local REALM_API_IDS = {
	["PC"]   = "pc",
	["PS4"]  = "sony",
	["Xbox"] = "xbox",
}

-- Listed status display names and their API option values
local LISTED_STATUS_OPTIONS = {
	{ label = "Instant Buyout & In Person", apiValue = "available" },
	{ label = "Instant Buyout", apiValue = "securable" },
	{ label = "In Person (Online)", apiValue = "online" },
	{ label = "Any", apiValue = "any" },
}
local LISTED_STATUS_LABELS = { }
for i, entry in ipairs(LISTED_STATUS_OPTIONS) do
	LISTED_STATUS_LABELS[i] = entry.label
end

-- Layout constants (shared across Draw, DrawConfig, DrawItems, DrawCalcs, etc.)
local LAYOUT = {
	-- Main tab control bar
	controlBarHeight = 96,

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
	self.comparePowerCategories = { treeNodes = true, items = true, gems = true, config = true }
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
			self.modFlag = true
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
			self.modFlag = true
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
			self.modFlag = true
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
				self.modFlag = true
				self.configNeedsRebuild = true
			end
		end
	end)
	self.controls.compareConfigSetSelect.enabled = setsEnabled
	self.controls.compareConfigSetSelect.enableDroppedWidth = true

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
				self.modFlag = true
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
					self.modFlag = true
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
					self.modFlag = true
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
					self.modFlag = true
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
						self.modFlag = true
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
					self.modFlag = true
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
			self.modFlag = true
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
			self.modFlag = true
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
			self.modFlag = true
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
	self.controls.copySpecBtn = new("ButtonControl", {"LEFT", self.controls.rightVersionSelect, "RIGHT"}, {4, 0, 66, 20}, "Copy tree", function()
		self:CopyCompareSpecToPrimary(false)
	end)
	self.controls.copySpecBtn.shown = treeFooterShown
	self.controls.copySpecBtn.enabled = function()
		local entry = self:GetActiveCompare()
		return entry and entry.treeTab and entry.treeTab.specList[entry.treeTab.activeSpec] ~= nil
	end

	self.controls.copySpecUseBtn = new("ButtonControl", {"LEFT", self.controls.copySpecBtn, "RIGHT"}, {2, 0, 90, 20}, "Copy and use", function()
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
	self.controls.comparePowerStatSelect.tooltipText = "Select a metric to calculate power report"

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

	self.controls.comparePowerGemsCheck = new("CheckBoxControl", nil, {0, 0, 18}, "Gems:", function(state)
		self.comparePowerCategories.gems = state
		self.comparePowerDirty = true
	end, "Include skill gem groups from compared build")
	self.controls.comparePowerGemsCheck.shown = powerReportShown
	self.controls.comparePowerGemsCheck.state = true

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
		self.modFlag = true
		return true
	end
	return false
end

-- Save comparison builds to the build file
function CompareTabClass:Save(xml)
	xml.attrib = {
		activeCompareIndex = tostring(self.activeCompareIndex),
	}
	for _, entry in ipairs(self.compareEntries) do
		local attrib = {
			label = entry.label,
			buildCode = common.base64.encode(Deflate(entry.xmlText)):gsub("+","-"):gsub("/","_"),
		}
		if entry.treeTab then
			attrib.activeSpec = tostring(entry.treeTab.activeSpec)
		end
		if entry.skillsTab then
			attrib.activeSkillSetId = tostring(entry.skillsTab.activeSkillSetId)
		end
		if entry.itemsTab then
			attrib.activeItemSetId = tostring(entry.itemsTab.activeItemSetId)
		end
		if entry.configTab then
			attrib.activeConfigSetId = tostring(entry.configTab.activeConfigSetId)
		end
		t_insert(xml, {
			elem = "CompareEntry",
			attrib = attrib,
		})
	end
end

-- Load comparison builds from the build file
function CompareTabClass:Load(xml, dbFileName)
	local savedIndex = tonumber(xml.attrib and xml.attrib.activeCompareIndex) or 0
	for _, child in ipairs(xml) do
		if type(child) == "table" and child.elem == "CompareEntry" then
			local code = child.attrib and child.attrib.buildCode
			if code then
				local xmlText = Inflate(common.base64.decode(code:gsub("-","+"):gsub("_","/")))
				if xmlText then
					if self:ImportBuild(xmlText, child.attrib.label or "Comparison Build") then
						local entry = self.compareEntries[#self.compareEntries]
						local savedSpec = tonumber(child.attrib.activeSpec)
						if savedSpec and entry.treeTab and entry.treeTab.specList[savedSpec] then
							entry:SetActiveSpec(savedSpec)
						end
						local savedSkillSet = tonumber(child.attrib.activeSkillSetId)
						if savedSkillSet and entry.skillsTab then
							entry:SetActiveSkillSet(savedSkillSet)
						end
						local savedItemSet = tonumber(child.attrib.activeItemSetId)
						if savedItemSet and entry.itemsTab then
							entry:SetActiveItemSet(savedItemSet)
						end
						local savedConfigSet = tonumber(child.attrib.activeConfigSetId)
						if savedConfigSet and entry.configTab and entry.configTab.configSets[savedConfigSet] then
							entry.configTab:SetActiveConfigSet(savedConfigSet)
						end
					end
				end
			end
		end
	end
	if #self.compareEntries > 0 then
		self.activeCompareIndex = m_max(1, m_min(savedIndex, #self.compareEntries))
	else
		self.activeCompareIndex = 0
	end
	self:UpdateBuildSelector()
end

-- Remove a comparison build
function CompareTabClass:RemoveBuild(index)
	if index >= 1 and index <= #self.compareEntries then
		t_remove(self.compareEntries, index)
		self.modFlag = true
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

-- Helper: create a numeric EditControl without +/- spinner buttons
local function newPlainNumericEdit(anchor, rect, init, prompt, limit)
	local ctrl = new("EditControl", anchor, rect, init, prompt, "%D", limit)
	-- Remove the +/- spinner buttons that "%D" filter triggers
	ctrl.isNumeric = false
	if ctrl.controls then
		if ctrl.controls.buttonDown then ctrl.controls.buttonDown.shown = false end
		if ctrl.controls.buttonUp then ctrl.controls.buttonUp.shown = false end
	end
	return ctrl
end

-- Open the Buy Similar popup for a compared item
function CompareTabClass:OpenBuySimilarPopup(item, slotName)
	if not item then return end

	local isUnique = item.rarity == "UNIQUE" or item.rarity == "RELIC"
	local controls = {}
	local rowHeight = 24
	local popupWidth = 700
	local leftMargin = 20
	local minFieldX = popupWidth - 160
	local maxFieldX = popupWidth - 80
	local fieldW = 60
	local fieldH = 20
	local checkboxSize = 20

	-- Collect mod entries with trade IDs
	local modEntries = {}
	local modTypeSources = {
		{ list = item.implicitModLines, type = "implicit" },
		{ list = item.enchantModLines, type = "enchant" },
		{ list = item.scourgeModLines, type = "explicit" },
		{ list = item.explicitModLines, type = "explicit" },
		{ list = item.crucibleModLines, type = "explicit" },
	}
	for _, source in ipairs(modTypeSources) do
		if source.list then
			for _, modLine in ipairs(source.list) do
				if item:CheckModLineVariant(modLine) then
					local formatted = itemLib.formatModLine(modLine)
					if formatted then
						-- Use range-resolved text for matching
						local resolvedLine = (modLine.range and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar)) or modLine.line
						local tradeId = findTradeModId(resolvedLine, source.type)
						local value = modLineValue(resolvedLine)
						t_insert(modEntries, {
							line = modLine.line,
							formatted = formatted:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%x", ""), -- strip color codes
							tradeId = tradeId,
							value = value,
							modType = source.type,
						})
					end
				end
			end
		end
	end

	-- Collect defence stats for non-unique gear items
	local defenceEntries = {}
	if not isUnique and item.armourData and item.base and item.base.armour then
		local defences = {
			{ key = "Armour", label = "Armour", tradeKey = "ar" },
			{ key = "Evasion", label = "Evasion", tradeKey = "ev" },
			{ key = "EnergyShield", label = "Energy Shield", tradeKey = "es" },
			{ key = "Ward", label = "Ward", tradeKey = "ward" },
		}
		for _, def in ipairs(defences) do
			local val = item.armourData[def.key]
			if val and val > 0 then
				t_insert(defenceEntries, {
					label = def.label,
					value = val,
					tradeKey = def.tradeKey,
				})
			end
		end
	end

	-- Build controls
	local ctrlY = 25

	-- Realm and league dropdowns
	local tradeQuery = self.primaryBuild.itemsTab and self.primaryBuild.itemsTab.tradeQuery
	local tradeQueryRequests = tradeQuery and tradeQuery.tradeQueryRequests
	if not tradeQueryRequests then
		tradeQueryRequests = new("TradeQueryRequests")
	end

	-- Helper to fetch and populate leagues for a given realm API id
	local function fetchLeaguesForRealm(realmApiId)
		controls.leagueDrop:SetList({"Loading..."})
		controls.leagueDrop.selIndex = 1
		tradeQueryRequests:FetchLeagues(realmApiId, function(leagues, errMsg)
			if errMsg then
				controls.leagueDrop:SetList({"Standard"})
				return
			end
			local leagueList = {}
			for _, league in ipairs(leagues) do
				if league ~= "Standard" and league ~= "Ruthless" and league ~= "Hardcore" and league ~= "Hardcore Ruthless" then
					if not (league:find("Hardcore") or league:find("Ruthless")) then
						t_insert(leagueList, 1, league)
					else
						t_insert(leagueList, league)
					end
				end
			end
			t_insert(leagueList, "Standard")
			t_insert(leagueList, "Hardcore")
			t_insert(leagueList, "Ruthless")
			t_insert(leagueList, "Hardcore Ruthless")
			controls.leagueDrop:SetList(leagueList)
		end)
	end

	-- Realm dropdown
	controls.realmLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Realm:")
	controls.realmDrop = new("DropDownControl", {"LEFT", controls.realmLabel, "RIGHT"}, {4, 0, 80, 20}, {"PC", "PS4", "Xbox"}, function(index, value)
		local realmApiId = REALM_API_IDS[value] or "pc"
		fetchLeaguesForRealm(realmApiId)
	end)

	-- League dropdown
	controls.leagueLabel = new("LabelControl", {"LEFT", controls.realmDrop, "RIGHT"}, {12, 0, 0, 16}, "^7League:")
	controls.leagueDrop = new("DropDownControl", {"LEFT", controls.leagueLabel, "RIGHT"}, {4, 0, 160, 20}, {"Loading..."}, function(index, value)
		-- League selection stored in the dropdown itself
	end)
	controls.leagueDrop.enabled = function() return #controls.leagueDrop.list > 0 and controls.leagueDrop.list[1] ~= "Loading..." end

	-- Listed status dropdown
	controls.listedLabel = new("LabelControl", {"LEFT", controls.leagueDrop, "RIGHT"}, {12, 0, 0, 16}, "^7Listed:")
	controls.listedDrop = new("DropDownControl", {"LEFT", controls.listedLabel, "RIGHT"}, {4, 0, 180, 20}, LISTED_STATUS_LABELS, function(index, value)
		-- Listed status selection stored in the dropdown itself
	end)

	-- Fetch initial leagues for default realm
	fetchLeaguesForRealm("pc")
	ctrlY = ctrlY + rowHeight + 4

	if isUnique then
		-- Unique item name label
		controls.nameLabel = new("LabelControl", nil, {0, ctrlY, 0, 16}, "^x" .. (colorCodes[item.rarity] or "FFFFFF"):gsub("%^x","") .. item.name)
		ctrlY = ctrlY + rowHeight
	else
		-- Category label
		local categoryLabel = getTradeCategoryLabel(slotName, item)
		controls.categoryLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Category: " .. categoryLabel)
		ctrlY = ctrlY + rowHeight

		-- Base type checkbox
		controls.baseTypeCheck = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", nil, nil)
		controls.baseTypeLabel = new("LabelControl", {"LEFT", controls.baseTypeCheck, "RIGHT"}, {4, 0, 0, 16}, "^7Use specific base: " .. (item.baseName or "Unknown"))
		ctrlY = ctrlY + rowHeight

		-- Item level
		ctrlY = ctrlY + 4
		controls.ilvlLabel = new("LabelControl", {"TOPLEFT", nil, "TOPLEFT"}, {leftMargin, ctrlY, 0, 16}, "^7Item Level:")
		controls.ilvlMin = newPlainNumericEdit(nil, {minFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Min", 4)
		controls.ilvlMax = newPlainNumericEdit(nil, {maxFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Max", 4)
		ctrlY = ctrlY + rowHeight

		-- Defence stat rows
		for i, def in ipairs(defenceEntries) do
			local prefix = "def" .. i
			controls[prefix .. "Check"] = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", nil, nil)
			controls[prefix .. "Label"] = new("LabelControl", {"LEFT", controls[prefix .. "Check"], "RIGHT"}, {4, 0, 0, 16}, "^7" .. def.label)
			controls[prefix .. "Min"] = newPlainNumericEdit(nil, {minFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, tostring(m_floor(def.value)), "Min", 6)
			controls[prefix .. "Max"] = newPlainNumericEdit(nil, {maxFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Max", 6)
			ctrlY = ctrlY + rowHeight
		end

		-- Separator between defence stats and mods
		if #defenceEntries > 0 then
			ctrlY = ctrlY + 8
		end
	end

	-- Mod rows
	for i, entry in ipairs(modEntries) do
		local prefix = "mod" .. i
		local canSearch = entry.tradeId ~= nil
		controls[prefix .. "Check"] = new("CheckBoxControl", nil, {-popupWidth/2 + leftMargin + checkboxSize/2, ctrlY, checkboxSize}, "", nil, nil)
		controls[prefix .. "Check"].enabled = function() return canSearch end
		-- Truncate long mod text to fit
		local displayText = entry.formatted
		if #displayText > 45 then
			displayText = displayText:sub(1, 42) .. "..."
		end
		controls[prefix .. "Label"] = new("LabelControl", {"LEFT", controls[prefix .. "Check"], "RIGHT"}, {4, 0, 0, 16}, (canSearch and "^7" or "^8") .. displayText)
		controls[prefix .. "Min"] = newPlainNumericEdit(nil, {minFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, entry.value ~= 0 and tostring(m_floor(entry.value)) or "", "Min", 8)
		controls[prefix .. "Max"] = newPlainNumericEdit(nil, {maxFieldX - popupWidth/2, ctrlY, fieldW, fieldH}, "", "Max", 8)
		if not canSearch then
			controls[prefix .. "Min"].enabled = function() return false end
			controls[prefix .. "Max"].enabled = function() return false end
		end
		ctrlY = ctrlY + rowHeight
	end

	-- Search button
	ctrlY = ctrlY + 8
	controls.search = new("ButtonControl", nil, {0, ctrlY, 100, 20}, "Generate URL", function()
		local success, result = pcall(function()
			return self:BuildBuySimilarURL(item, slotName, controls, modEntries, defenceEntries, isUnique)
		end)
		if success and result then
			controls.uri:SetText(result, true)
		elseif not success then
			controls.uri:SetText("Error: " .. tostring(result), true)
		else
			controls.uri:SetText("Error: could not determine league", true)
		end
	end)
	ctrlY = ctrlY + rowHeight + 4

	-- URL field
	controls.uri = new("EditControl", nil, {-30, ctrlY, popupWidth - 100, fieldH}, "", nil, "^%C\t\n")
	controls.uri:SetPlaceholder("Press 'Generate URL' then Ctrl+Click to open")
	controls.uri.tooltipFunc = function(tooltip)
		tooltip:Clear()
		if controls.uri.buf and controls.uri.buf ~= "" then
			tooltip:AddLine(16, "^7Ctrl + Click to open in web browser")
		end
	end
	controls.close = new("ButtonControl", nil, {popupWidth/2 - 50, ctrlY, 60, 20}, "Close", function()
		main:ClosePopup()
	end)

	-- Calculate popup height from final control position
	local popupHeight = ctrlY + fieldH + 16
	if popupHeight > 600 then popupHeight = 600 end

	local title = "Buy Similar"
	main:OpenPopup(popupWidth, popupHeight, title, controls, "search", nil, "close")
end

-- Build the trade search URL based on popup selections
function CompareTabClass:BuildBuySimilarURL(item, slotName, controls, modEntries, defenceEntries, isUnique)
	-- Determine realm and league from the popup's dropdowns
	local realmDisplayValue = controls.realmDrop and controls.realmDrop:GetSelValue() or "PC"
	local realm = REALM_API_IDS[realmDisplayValue] or "pc"
	local league = controls.leagueDrop and controls.leagueDrop:GetSelValue()
	if not league or league == "" or league == "Loading..." then
		league = "Standard"
	end
	local hostName = "https://www.pathofexile.com/"

	-- Determine listed status from dropdown
	local listedIndex = controls.listedDrop and controls.listedDrop.selIndex or 1
	local listedApiValue = LISTED_STATUS_OPTIONS[listedIndex] and LISTED_STATUS_OPTIONS[listedIndex].apiValue or "available"

	-- Build query
	local queryTable = {
		query = {
			status = { option = listedApiValue },
			stats = {
				{
					type = "and",
					filters = {}
				}
			},
		},
		sort = { price = "asc" }
	}
	local queryFilters = {}

	if isUnique then
		-- Search by unique name
		-- Strip "Foulborn" prefix from unique name for trade search
		local tradeName = (item.title or item.name):gsub("^Foulborn%s+", "")
		queryTable.query.name = tradeName
		queryTable.query.type = item.baseName
		-- If item is Foulborn, add the foulborn_item filter
		if item.foulborn then
			queryFilters.misc_filters = queryFilters.misc_filters or { filters = {} }
			queryFilters.misc_filters.filters.foulborn_item = { option = "true" }
		end
	else
		-- Category filter
		local categoryStr = getTradeCategory(slotName, item)
		if categoryStr then
			queryFilters.type_filters = {
				filters = {
					category = { option = categoryStr }
				}
			}
		end

		-- Base type filter
		if controls.baseTypeCheck and controls.baseTypeCheck.state then
			queryTable.query.type = item.baseName
		end

		-- Item level filter
		local ilvlMin = controls.ilvlMin and tonumber(controls.ilvlMin.buf)
		local ilvlMax = controls.ilvlMax and tonumber(controls.ilvlMax.buf)
		if ilvlMin or ilvlMax then
			local ilvlFilter = {}
			if ilvlMin then ilvlFilter.min = ilvlMin end
			if ilvlMax then ilvlFilter.max = ilvlMax end
			queryFilters.misc_filters = {
				filters = {
					ilvl = ilvlFilter
				}
			}
		end

		-- Defence stat filters
		local armourFilters = {}
		for i, def in ipairs(defenceEntries) do
			local prefix = "def" .. i
			if controls[prefix .. "Check"] and controls[prefix .. "Check"].state then
				local minVal = tonumber(controls[prefix .. "Min"].buf)
				local maxVal = tonumber(controls[prefix .. "Max"].buf)
				local filter = {}
				if minVal then filter.min = minVal end
				if maxVal then filter.max = maxVal end
				if minVal or maxVal then
					armourFilters[def.tradeKey] = filter
				end
			end
		end
		if next(armourFilters) then
			queryFilters.armour_filters = {
				filters = armourFilters
			}
		end
	end

	-- Mod filters
	for i, entry in ipairs(modEntries) do
		local prefix = "mod" .. i
		if entry.tradeId and controls[prefix .. "Check"] and controls[prefix .. "Check"].state then
			local minVal = tonumber(controls[prefix .. "Min"].buf)
			local maxVal = tonumber(controls[prefix .. "Max"].buf)
			local filter = { id = entry.tradeId }
			local value = {}
			if minVal then value.min = minVal end
			if maxVal then value.max = maxVal end
			if next(value) then
				filter.value = value
			end
			t_insert(queryTable.query.stats[1].filters, filter)
		end
	end

	-- Only include filters if we have any
	if next(queryFilters) then
		queryTable.query.filters = queryFilters
	end

	-- Build URL
	local queryJson = dkjson.encode(queryTable)
	local url = hostName .. "trade/search"
	if realm and realm ~= "" and realm ~= "pc" then
		url = url .. "/" .. realm
	end
	local encodedLeague = league:gsub("[^%w%-%.%_%~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end):gsub(" ", "+")
	url = url .. "/" .. encodedLeague
	url = url .. "?q=" .. urlEncode(queryJson)

	return url
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
							self.modFlag = true
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
			self.modFlag = true
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
	-- Position top-bar controls
	self.controls.subTabAnchor.x = viewPort.x + 4
	self.controls.subTabAnchor.y = viewPort.y + 74

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
	self:HandleScrollInput(contentVP, inputEvents)

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
			local itemList = {}
			for index, itemSetId in ipairs(self.primaryBuild.itemsTab.itemSetOrderList) do
				local itemSet = self.primaryBuild.itemsTab.itemSets[itemSetId]
				t_insert(itemList, itemSet.title or "Default")
				if itemSetId == self.primaryBuild.itemsTab.activeItemSetId then
					self.controls.primaryItemSetSelect.selIndex = index
				end
			end
			self.controls.primaryItemSetSelect:SetList(itemList)
		end

		-- Populate compare build item set list
		if compareEntry and compareEntry.itemsTab and compareEntry.itemsTab.itemSetOrderList then
			local itemList = {}
			for index, itemSetId in ipairs(compareEntry.itemsTab.itemSetOrderList) do
				local itemSet = compareEntry.itemsTab.itemSets[itemSetId]
				t_insert(itemList, itemSet.title or "Default")
				if itemSetId == compareEntry.itemsTab.activeItemSetId then
					self.controls.compareItemSetSelect2.selIndex = index
				end
			end
			self.controls.compareItemSetSelect2:SetList(itemList)
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
	-- Item set list
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
	-- Config set list
	if compareEntry.configTab then
		local configList = {}
		for index, configSetId in ipairs(compareEntry.configTab.configSetOrderList) do
			local configSet = compareEntry.configTab.configSets[configSetId]
			t_insert(configList, configSet and configSet.title or "Default")
			if configSetId == compareEntry.configTab.activeConfigSetId then
				self.controls.compareConfigSetSelect.selIndex = index
			end
		end
		self.controls.compareConfigSetSelect:SetList(configList)
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

-- Handle scroll events for scrollable views.
function CompareTabClass:HandleScrollInput(contentVP, inputEvents)
	local cursorX, cursorY = GetCursorPos()
	local mouseInContent = cursorX >= contentVP.x and cursorX < contentVP.x + contentVP.width
		and cursorY >= contentVP.y and cursorY < contentVP.y + contentVP.height

	local listControl = self.controls.comparePowerReportList
	local mouseOverList = listControl:IsShown() and listControl:IsMouseOver()

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" and mouseInContent and not mouseOverList then
			if event.key == "WHEELUP" and self.compareViewMode ~= "TREE" then
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

-- Calculate the stat difference for a given power stat selection
-- output: result from calcFunc (with the change applied)
-- calcBase: baseline output (without the change)
-- Returns positive value if the change improves the stat
function CompareTabClass:CalculatePowerStat(selection, output, calcBase)
	local withChange = output
	local baseline = calcBase
	if baseline.Minion and not selection.stat == "FullDPS" then
		withChange = withChange.Minion
		baseline = baseline.Minion
	end
	local withValue = withChange[selection.stat] or 0
	local baseValue = baseline[selection.stat] or 0
	if selection.transform then
		withValue = selection.transform(withValue)
		baseValue = selection.transform(baseValue)
	end
	return withValue - baseValue
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
			if type(nodeId) == "number" and nodeId < 65536 and not primaryNodes[nodeId] then
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
	if categories.gems then
		local cGroups = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList or {}
		total = total + #cGroups
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
		local numStr = s_format("%" .. displayStat.fmt, displayVal)
		numStr = formatNumSep(numStr)

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

		return str, displayVal, combinedStr, percent
	end

	-- ==========================================
	-- Tree Nodes
	-- ==========================================
	if categories.treeNodes then
		local compareNodes = compareEntry.spec and compareEntry.spec.allocNodes or {}
		local primaryNodes = self.primaryBuild.spec and self.primaryBuild.spec.allocNodes or {}
		local cache = {}

		for nodeId, _ in pairs(compareNodes) do
			if type(nodeId) == "number" and nodeId < 65536 and not primaryNodes[nodeId] then
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
					local impact = self:CalculatePowerStat(powerStat, output, calcBase)
					local pathDist = pNode.pathDist or 0
					if pathDist == 0 then
						pathDist = #(pNode.path or {})
						if pathDist == 0 then pathDist = 1 end
					end
					local perPoint = impact / pathDist
					local impactStr, impactVal, combinedImpactStr, impactPercent = formatImpact(impact)
					local perPointStr = formatImpact(perPoint)

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
			if cItem and cItem.raw then
				local newItem = new("Item", cItem.raw)
				newItem:NormaliseQuality()
				local output = calcFunc({ repSlotName = slotName, repItem = newItem }, useFullDPS)
				local impact = self:CalculatePowerStat(powerStat, output, calcBase)
				local impactStr, impactVal, combinedImpactStr, impactPercent = formatImpact(impact)

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
			if jEntry.cItem and jEntry.cItem.raw then
				local newItem = new("Item", jEntry.cItem.raw)
				newItem:NormaliseQuality()

				local bestImpactVal = nil
				local bestSlotLabel = jEntry.label

				if jEntry.pNodeAllocated then
					-- Socket is allocated in primary build, test directly in that socket
					local output = calcFunc({ repSlotName = jEntry.cSlotName, repItem = newItem }, useFullDPS)
					bestImpactVal = self:CalculatePowerStat(powerStat, output, calcBase)
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
						local impact = self:CalculatePowerStat(powerStat, output, calcBase)
						if bestImpactVal == nil or impact > bestImpactVal then
							bestImpactVal = impact
							bestSlotLabel = jEntry.label .. " (best socket)"
						end
					end
				end

				if bestImpactVal ~= nil then
					local impactStr, impactVal, combinedImpactStr, impactPercent = formatImpact(bestImpactVal)
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
	if categories.gems then
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
				local ok, gemCalcFunc, gemCalcBase = pcall(self.calcs.getMiscCalculator, self.calcs, self.primaryBuild)

				-- Always remove the temporarily added group
				t_remove(pGroups)
				self.primaryBuild.buildFlag = true

				if not ok then
					-- gemCalcFunc contains the error message on failure; skip this group
					ConPrintf("Compare power (gem): %s", tostring(gemCalcFunc))
				else
					local impact = self:CalculatePowerStat(powerStat, gemCalcBase, calcBase)
					local impactStr, impactVal, combinedImpactStr, impactPercent = formatImpact(impact)
					local label = self:GetSocketGroupLabel(cGroup)

					t_insert(results, {
						category = "Gem",
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
			processed = processed + 1
			if coroutine.running() and GetTime() - start > 100 then
				self.comparePowerProgress = m_floor(processed / total * 100)
				coroutine.yield()
				start = GetTime()
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
						local impact = self:CalculatePowerStat(powerStat, cfgCalcBase, calcBase)
						local impactStr, impactVal, combinedImpactStr, impactPercent = formatImpact(impact)

						-- Only include configs with non-zero impact
						if impactVal ~= 0 then
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
	local primaryOutput = self.primaryBuild.calcsTab.mainOutput
	local compareOutput = compareEntry:GetOutput()
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
	local displayStats = self.primaryBuild.displayStats
	local primaryEnv = self.primaryBuild.calcsTab.mainEnv
	local compareEnv = compareEntry.calcsTab.mainEnv

	drawY = self:DrawStatList(drawY, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, col1, col4, col2R, col3R)

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


function CompareTabClass:DrawStatList(drawY, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, col1, col4, col2R, col3R)
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

-- Helper: get rarity color code for an item
local function getRarityColor(item)
	if not item then return "^7" end
	if item.rarity == "UNIQUE" then return colorCodes.UNIQUE
	elseif item.rarity == "RARE" then return colorCodes.RARE
	elseif item.rarity == "MAGIC" then return colorCodes.MAGIC
	else return colorCodes.NORMAL end
end

-- Helper: normalize a mod line by replacing numbers with "#" for template matching
local function modLineTemplate(line)
	-- Replace decimal numbers first (e.g. "1.5"), then integers
	return line:gsub("[%d]+%.?[%d]*", "#")
end

-- Helper: extract the first number from a mod line for value comparison
modLineValue = function(line)
	return tonumber(line:match("[%d]+%.?[%d]*")) or 0
end

-- Helper: lazily build a reverse lookup from QueryMods tradeMod.text → tradeMod.id
local _tradeModLookup = nil
local function getTradeModLookup()
	if _tradeModLookup then return _tradeModLookup end
	_tradeModLookup = {}
	if not queryModsData then return _tradeModLookup end
	for _groupName, mods in pairs(queryModsData) do
		for _modKey, modData in pairs(mods) do
			if type(modData) == "table" and modData.tradeMod then
				local text = modData.tradeMod.text
				local modType = modData.tradeMod.type or "explicit"
				local id = modData.tradeMod.id
				local key = text .. "|" .. modType
				_tradeModLookup[key] = id
				if not _tradeModLookup[text] then
					_tradeModLookup[text] = id
				end
				-- Also store with template-converted text for mods with literal numbers
				-- (e.g. "1 Added Passive Skill is X" → "# Added Passive Skill is X")
				local tmpl = modLineTemplate(text)
				if tmpl ~= text then
					local tmplKey = tmpl .. "|" .. modType
					if not _tradeModLookup[tmplKey] then
						_tradeModLookup[tmplKey] = id
					end
					if not _tradeModLookup[tmpl] then
						_tradeModLookup[tmpl] = id
					end
				end
			end
		end
	end
	return _tradeModLookup
end

-- Helper: lazily fetch and cache the trade API stats for comprehensive mod matching
-- Covers mods not in QueryMods.lua (cluster enchants, unique-specific mods, etc.)
local _tradeStatsLookup = nil
local _tradeStatsFetched = false
local function getTradeStatsLookup()
	if _tradeStatsFetched then return _tradeStatsLookup end
	_tradeStatsFetched = true
	local tradeStats = ""
	local easy = common.curl.easy()
	if not easy then return nil end
	easy:setopt_url("https://www.pathofexile.com/api/trade/data/stats")
	easy:setopt_useragent("Path of Building/" .. (launch.versionNumber or ""))
	easy:setopt_writefunction(function(d)
		tradeStats = tradeStats .. d
		return true
	end)
	local ok = easy:perform()
	easy:close()
	if not ok or tradeStats == "" then return nil end
	local parsed = dkjson.decode(tradeStats)
	if not parsed or not parsed.result then return nil end
	_tradeStatsLookup = {}
	for _, category in ipairs(parsed.result) do
		local catLabel = category.label
		for _, entry in ipairs(category.entries) do
			local stripped = entry.text:gsub("[#()0-9%-%+%.]", "")
			local key = stripped .. "|" .. catLabel
			if not _tradeStatsLookup[key] then
				_tradeStatsLookup[key] = entry
			end
			if not _tradeStatsLookup[stripped] then
				_tradeStatsLookup[stripped] = entry
			end
		end
	end
	return _tradeStatsLookup
end

-- Map source types used in OpenBuySimilarPopup to trade API category labels
local sourceTypeToCategory = {
	["implicit"] = "Implicit",
	["explicit"] = "Explicit",
	["enchant"] = "Enchant",
}

-- Helper: find the trade stat ID for a mod line
findTradeModId = function(modLine, modType)
	-- Try QueryMods-based lookup
	local lookup = getTradeModLookup()
	local tmpl = modLineTemplate(modLine)
	-- Try exact match with type first
	local key = tmpl .. "|" .. modType
	if lookup[key] then
		return lookup[key]
	end
	-- Try without leading +/- sign
	local stripped = tmpl:gsub("^[%+%-]", "")
	key = stripped .. "|" .. modType
	if lookup[key] then
		return lookup[key]
	end
	-- Fallback: match by template text only (any type)
	if lookup[tmpl] then
		return lookup[tmpl]
	end
	if lookup[stripped] then
		return lookup[stripped]
	end

	-- Try trade API stats (covers mods not in QueryMods)
	local tradeStats = getTradeStatsLookup()
	if tradeStats then
		local strippedLine = modLine:gsub("[#()0-9%-%+%.]", "")
		local category = sourceTypeToCategory[modType]
		if category then
			local catKey = strippedLine .. "|" .. category
			if tradeStats[catKey] then
				return tradeStats[catKey].id
			end
		end
		-- Fallback: any category
		if tradeStats[strippedLine] then
			return tradeStats[strippedLine].id
		end
	end

	return nil
end

-- Helper: map slot name + item type to trade API category string
getTradeCategory = function(slotName, item)
	if not item or not item.base then return nil end
	local itemType = item.type or (item.base and item.base.type)
	if slotName:find("^Weapon %d") then
		if itemType == "Shield" then return "armour.shield"
		elseif itemType == "Quiver" then return "armour.quiver"
		elseif itemType == "Bow" then return "weapon.bow"
		elseif itemType == "Staff" then return "weapon.staff"
		elseif itemType == "Two Handed Sword" then return "weapon.twosword"
		elseif itemType == "Two Handed Axe" then return "weapon.twoaxe"
		elseif itemType == "Two Handed Mace" then return "weapon.twomace"
		elseif itemType == "Fishing Rod" then return "weapon.rod"
		elseif itemType == "One Handed Sword" then return "weapon.onesword"
		elseif itemType == "One Handed Axe" then return "weapon.oneaxe"
		elseif itemType == "One Handed Mace" or itemType == "Sceptre" then return "weapon.onemace"
		elseif itemType == "Wand" then return "weapon.wand"
		elseif itemType == "Dagger" then return "weapon.dagger"
		elseif itemType == "Claw" then return "weapon.claw"
		elseif itemType and itemType:find("Two Handed") then return "weapon.twomelee"
		elseif itemType and itemType:find("One Handed") then return "weapon.one"
		else return "weapon"
		end
	elseif slotName == "Body Armour" then return "armour.chest"
	elseif slotName == "Helmet" then return "armour.helmet"
	elseif slotName == "Gloves" then return "armour.gloves"
	elseif slotName == "Boots" then return "armour.boots"
	elseif slotName == "Amulet" then return "accessory.amulet"
	elseif slotName == "Ring 1" or slotName == "Ring 2" or slotName == "Ring 3" then return "accessory.ring"
	elseif slotName == "Belt" then return "accessory.belt"
	elseif slotName:find("Abyssal") then return "jewel.abyss"
	elseif slotName:find("Jewel") then return "jewel"
	elseif slotName:find("Flask") then return "flask"
	else return nil
	end
end

-- Helper: get a display-friendly category name from slot name
getTradeCategoryLabel = function(slotName, item)
	if not item or not item.base then return "Item" end
	local baseType = item.base.type or item.type
	return baseType or "Item"
end

-- Helper: build a mod comparison map from an item.
-- Returns a table keyed by template string → { line = original text, value = first number }
local function buildModMap(item)
	local modMap = {}
	if not item then return modMap end
	for _, modList in ipairs{item.enchantModLines or {}, item.scourgeModLines or {}, item.implicitModLines or {}, item.explicitModLines or {}, item.crucibleModLines or {}} do
		for _, modLine in ipairs(modList) do
			if item:CheckModLineVariant(modLine) then
				local formatted = itemLib.formatModLine(modLine)
				if formatted then
					local tmpl = modLineTemplate(modLine.line)
					modMap[tmpl] = { line = modLine.line, value = modLineValue(modLine.line) }
				end
			end
		end
	end
	return modMap
end

-- Helper: get diff label string for an item slot comparison
local function getSlotDiffLabel(pItem, cItem)
	if not pItem and not cItem then
		return "^8(both empty)"
	end
	if pItem and cItem and pItem.name == cItem.name then
		return colorCodes.POSITIVE .. "(match)"
	elseif not pItem then
		return colorCodes.NEGATIVE .. "(missing)"
	elseif not cItem then
		return colorCodes.TIP .. "(extra)"
	else
		return colorCodes.WARNING .. "(different)"
	end
end

-- Helper: draw Copy, Copy+Use, and Buy buttons at the given position.
-- btnStartX is the left edge where the first button (Buy) should appear.
-- Returns copyHovered, copyUseHovered, buyHovered booleans.
local function drawCopyButtons(cursorX, cursorY, btnStartX, btnY, slotMissing)
	local btnW = LAYOUT.itemsCopyBtnW
	local btnH = LAYOUT.itemsCopyBtnH
	local buyW = LAYOUT.itemsBuyBtnW
	local btn3X = btnStartX
	local btn1X = btn3X + buyW + 4
	local btn2X = btn1X + btnW + 4

	-- "Buy" button
	local b3Hover = cursorX >= btn3X and cursorX < btn3X + buyW
		and cursorY >= btnY and cursorY < btnY + btnH
	SetDrawColor(b3Hover and 0.5 or 0.35, b3Hover and 0.5 or 0.35, b3Hover and 0.5 or 0.35)
	DrawImage(nil, btn3X, btnY, buyW, btnH)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, btn3X + 1, btnY + 1, buyW - 2, btnH - 2)
	SetDrawColor(1, 1, 1)
	DrawString(btn3X + buyW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^7Buy")

	-- "Copy" button
	local b1Hover = cursorX >= btn1X and cursorX < btn1X + btnW
		and cursorY >= btnY and cursorY < btnY + btnH
	SetDrawColor(b1Hover and 0.5 or 0.35, b1Hover and 0.5 or 0.35, b1Hover and 0.5 or 0.35)
	DrawImage(nil, btn1X, btnY, btnW, btnH)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, btn1X + 1, btnY + 1, btnW - 2, btnH - 2)
	SetDrawColor(1, 1, 1)
	DrawString(btn1X + btnW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^7Copy")

	local b2Hover
	if slotMissing then
		-- Show "Missing slot" label instead of Copy+Use button
		SetDrawColor(1, 1, 1)
		DrawString(btn2X + btnW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^xBBBBBBMissing slot")
		b2Hover = false
	else
		-- "Copy+Use" button
		b2Hover = cursorX >= btn2X and cursorX < btn2X + btnW
			and cursorY >= btnY and cursorY < btnY + btnH
		SetDrawColor(b2Hover and 0.5 or 0.35, b2Hover and 0.5 or 0.35, b2Hover and 0.5 or 0.35)
		DrawImage(nil, btn2X, btnY, btnW, btnH)
		SetDrawColor(0.1, 0.1, 0.1)
		DrawImage(nil, btn2X + 1, btnY + 1, btnW - 2, btnH - 2)
		SetDrawColor(1, 1, 1)
		DrawString(btn2X + btnW / 2, btnY + 1, "CENTER_X", 14, "VAR", "^7Copy+Use")
	end

	return b1Hover, b2Hover, b3Hover, btn2X, btnY, btnW, btnH
end

-- Helper: fit a colored item name within maxW pixels, truncating with "..." if needed.
local function fitItemName(colorCode, name, maxW)
	local display = colorCode .. name
	if DrawStringWidth(16, "VAR", display) <= maxW then
		return display
	end
	local lo, hi = 0, #name
	while lo < hi do
		local mid = m_floor((lo + hi + 1) / 2)
		if DrawStringWidth(16, "VAR", colorCode .. name:sub(1, mid) .. "...") <= maxW then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return colorCode .. name:sub(1, lo) .. "..."
end

-- Helper: draw a single compact-mode item row.
-- Returns: pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H, hoverItem, hoverItemsTab
local ITEM_BOX_W = 310
local ITEM_BOX_H = 20

local function drawCompactSlotRow(drawY, slotLabel, pItem, cItem,
	colWidth, cursorX, cursorY, maxLabelW, primaryItemsTab, compareItemsTab, pWarn, cWarn, slotMissing)

	local pName = pItem and pItem.name or "(empty)"
	local cName = cItem and cItem.name or "(empty)"
	if pWarn and pWarn ~= "" then pName = pName .. pWarn end
	if cWarn and cWarn ~= "" then cName = cName .. cWarn end
	local pColor = getRarityColor(pItem)
	local cColor = getRarityColor(cItem)
	local diffLabel = getSlotDiffLabel(pItem, cItem)

	-- Layout positions (fixed 310px box width matching regular Items tab)
	local labelX = 10
	local pBoxX = labelX + maxLabelW + 4
	local pBoxW = ITEM_BOX_W

	local cBoxX = colWidth + 10
	local cBoxW = ITEM_BOX_W

	-- Diff indicator position
	local diffX = pBoxX + pBoxW + 6

	-- Hover detection
	local pHover = pItem and cursorX >= pBoxX and cursorX < pBoxX + pBoxW
		and cursorY >= drawY and cursorY < drawY + ITEM_BOX_H
	local cHover = cItem and cursorX >= cBoxX and cursorX < cBoxX + cBoxW
		and cursorY >= drawY and cursorY < drawY + ITEM_BOX_H

	-- Draw slot label
	SetDrawColor(1, 1, 1)
	DrawString(labelX, drawY + 2, "LEFT", 16, "VAR", "^7" .. slotLabel .. ":")

	-- Draw primary item box
	local pBorderGray = pHover and 0.5 or 0.33
	SetDrawColor(pBorderGray, pBorderGray, pBorderGray)
	DrawImage(nil, pBoxX, drawY, pBoxW, ITEM_BOX_H)
	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, pBoxX + 1, drawY + 1, pBoxW - 2, ITEM_BOX_H - 2)
	SetDrawColor(1, 1, 1)
	DrawString(pBoxX + 4, drawY + 2, "LEFT", 16, "VAR", fitItemName(pColor, pName, pBoxW - 8))

	-- Draw diff indicator (between the two item boxes)
	DrawString(diffX, drawY + 3, "LEFT", 14, "VAR", diffLabel)

	-- Draw compare item box
	local cBorderGray = cHover and 0.5 or 0.33
	SetDrawColor(cBorderGray, cBorderGray, cBorderGray)
	DrawImage(nil, cBoxX, drawY, cBoxW, ITEM_BOX_H)
	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, cBoxX + 1, drawY + 1, cBoxW - 2, ITEM_BOX_H - 2)
	SetDrawColor(1, 1, 1)
	DrawString(cBoxX + 4, drawY + 2, "LEFT", 16, "VAR", fitItemName(cColor, cName, cBoxW - 8))

	-- Draw buttons
	local b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H
	if cItem then
		local btnStartX = cBoxX + cBoxW + 6
		b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H =
			drawCopyButtons(cursorX, cursorY, btnStartX, drawY + 1, slotMissing)
	end

	-- Determine hovered item and tooltip anchor position
	local hoverItem = nil
	local hoverItemsTab = nil
	local hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH = 0, 0, 0, 0
	if pHover then
		hoverItem = pItem
		hoverItemsTab = primaryItemsTab
		hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH = pBoxX, drawY, pBoxW, ITEM_BOX_H
	elseif cHover then
		hoverItem = cItem
		hoverItemsTab = compareItemsTab
		hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH = cBoxX, drawY, cBoxW, ITEM_BOX_H
	end

	return pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H,
		hoverItem, hoverItemsTab, hoverBoxX, hoverBoxY, hoverBoxW, hoverBoxH
end

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
	local rarityColor = getRarityColor(item)
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
						local tmpl = modLineTemplate(modLine.line)
						local otherEntry = otherModMap[tmpl]
						if not otherEntry then
							-- Mod exists only on this side
							formatted = colorCodes.POSITIVE .. "+ " .. formatted
						elseif otherEntry.line ~= modLine.line then
							-- Same mod template but different values
							local myVal = modLineValue(modLine.line)
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

		if self.itemsExpandedMode then
			-- === EXPANDED MODE ===
			-- Slot label + diff indicator
			SetDrawColor(1, 1, 1)
			DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. slotName .. ":")
			DrawString(colWidth - 10, drawY, "RIGHT", 14, "VAR", getSlotDiffLabel(pItem, cItem))

			-- Copy/Buy buttons for compare item
			if cItem then
				local slotMissing = slotName == "Ring 3" and not primaryHasRing3
				local b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H = drawCopyButtons(cursorX, cursorY, vp.width - 196, drawY + 1, slotMissing)
				if b2Hover then
					hoverCopyUseItem = cItem
					hoverCopyUseSlotName = slotName
					hoverCopyUseBtnX, hoverCopyUseBtnY = b2X, b2Y
					hoverCopyUseBtnW, hoverCopyUseBtnH = b2W, b2H
				end
				if inputEvents then
					for id, event in ipairs(inputEvents) do
						if event.type == "KeyUp" and event.key == "LEFTBUTTON" then
							if b1Hover then
								clickedCopySlot = slotName
								inputEvents[id] = nil
							elseif b2Hover then
								clickedCopyUseSlot = slotName
								inputEvents[id] = nil
							elseif b3Hover then
								clickedBuySlot = slotName
								clickedBuyItem = cItem
								inputEvents[id] = nil
							end
						end
					end
				end
			end

			drawY = drawY + 20

			-- Build mod maps for diff highlighting
			local pModMap = buildModMap(pItem)
			local cModMap = buildModMap(cItem)

			-- Draw both items expanded side by side
			local itemStartY = drawY
			local leftHeight = self:DrawItemExpanded(pItem, 20, drawY, colWidth - 30, cModMap)
			local rightHeight = self:DrawItemExpanded(cItem, colWidth + 20, drawY, colWidth - 30, pModMap)

			-- Vertical separator between columns
			SetDrawColor(0.25, 0.25, 0.25)
			local maxH = m_max(leftHeight, rightHeight)
			DrawImage(nil, colWidth, itemStartY, 1, maxH)

			drawY = drawY + maxH + 6
		else
			-- === COMPACT MODE (single-line with bordered boxes) ===
			local pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H,
				rowHoverItem, rowHoverItemsTab, rowHoverX, rowHoverY, rowHoverW, rowHoverH =
				drawCompactSlotRow(drawY, slotName, pItem, cItem,
					colWidth, cursorX, cursorY, maxLabelW,
					self.primaryBuild.itemsTab, compareEntry.itemsTab, nil, nil,
					slotName == "Ring 3" and not primaryHasRing3)

			if rowHoverItem then
				hoverItem = rowHoverItem
				hoverItemsTab = rowHoverItemsTab
				hoverX, hoverY = rowHoverX, rowHoverY
				hoverW, hoverH = rowHoverW, rowHoverH
			end

			if b2Hover and cItem then
				hoverCopyUseItem = cItem
				hoverCopyUseSlotName = slotName
				hoverCopyUseBtnX, hoverCopyUseBtnY = b2X, b2Y
				hoverCopyUseBtnW, hoverCopyUseBtnH = b2W, b2H
			end

			if cItem and inputEvents then
				for id, event in ipairs(inputEvents) do
					if event.type == "KeyUp" and event.key == "LEFTBUTTON" then
						if b1Hover then
							clickedCopySlot = slotName
							inputEvents[id] = nil
						elseif b2Hover then
							clickedCopyUseSlot = slotName
							inputEvents[id] = nil
						elseif b3Hover then
							clickedBuySlot = slotName
							clickedBuyItem = cItem
							inputEvents[id] = nil
						end
					end
				end
			end

			drawY = drawY + 20
		end
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
			local pItem = jEntry.pItem
			local cItem = jEntry.cItem

			-- Separator (skip before first jewel since section header already has one)
			if jIdx > 1 then
				SetDrawColor(0.3, 0.3, 0.3)
				DrawImage(nil, 4, drawY, vp.width - 8, 1)
				drawY = drawY + 2
			end

			-- Tree allocation warning text
			local pWarn = (pItem and not jEntry.pNodeAllocated) and colorCodes.WARNING .. "  (tree missing allocated node)" or ""
			local cWarn = (cItem and not jEntry.cNodeAllocated) and colorCodes.WARNING .. "  (tree missing allocated node)" or ""

			if self.itemsExpandedMode then
				-- === EXPANDED MODE ===
				SetDrawColor(1, 1, 1)
				DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. jEntry.label .. ":" .. pWarn)
				DrawString(colWidth - 10, drawY, "RIGHT", 14, "VAR", getSlotDiffLabel(pItem, cItem))

				-- Copy/Buy buttons for compare jewel
				if cItem then
					local b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H = drawCopyButtons(cursorX, cursorY, vp.width - 196, drawY + 1)
					if b2Hover then
						hoverCopyUseItem = cItem
						hoverCopyUseSlotName = jEntry.pSlotName
						hoverCopyUseBtnX, hoverCopyUseBtnY = b2X, b2Y
						hoverCopyUseBtnW, hoverCopyUseBtnH = b2W, b2H
					end
					if inputEvents then
						for id, event in ipairs(inputEvents) do
							if event.type == "KeyUp" and event.key == "LEFTBUTTON" then
								if b1Hover then
									clickedCopySlot = jEntry.cSlotName
									inputEvents[id] = nil
								elseif b2Hover then
									clickedCopyUseSlot = jEntry.pSlotName
									inputEvents[id] = nil
								elseif b3Hover then
									clickedBuySlot = jEntry.pSlotName
									clickedBuyItem = cItem
									inputEvents[id] = nil
								end
							end
						end
					end
				end

				drawY = drawY + 20

				-- Build mod maps for diff highlighting
				local pModMap = buildModMap(pItem)
				local cModMap = buildModMap(cItem)

				-- Draw both items expanded side by side
				local itemStartY = drawY
				local leftHeight = self:DrawItemExpanded(pItem, 20, drawY, colWidth - 30, cModMap)
				local rightHeight = self:DrawItemExpanded(cItem, colWidth + 20, drawY, colWidth - 30, pModMap)

				-- Vertical separator between columns
				SetDrawColor(0.25, 0.25, 0.25)
				local maxH = m_max(leftHeight, rightHeight)
				DrawImage(nil, colWidth, itemStartY, 1, maxH)

				drawY = drawY + maxH + 6
			else
				-- === COMPACT MODE (single-line with bordered boxes) ===
				local pHover, cHover, b1Hover, b2Hover, b3Hover, b2X, b2Y, b2W, b2H,
					rowHoverItem, rowHoverItemsTab, rowHoverX, rowHoverY, rowHoverW, rowHoverH =
					drawCompactSlotRow(drawY, jEntry.label, pItem, cItem,
						colWidth, cursorX, cursorY, maxJewelLabelW,
						self.primaryBuild.itemsTab, compareEntry.itemsTab, pWarn, cWarn)

				if rowHoverItem then
					hoverItem = rowHoverItem
					hoverItemsTab = rowHoverItemsTab
					hoverX, hoverY = rowHoverX, rowHoverY
					hoverW, hoverH = rowHoverW, rowHoverH
				end

				if b2Hover and cItem then
					hoverCopyUseItem = cItem
					hoverCopyUseSlotName = jEntry.pSlotName
					hoverCopyUseBtnX, hoverCopyUseBtnY = b2X, b2Y
					hoverCopyUseBtnW, hoverCopyUseBtnH = b2W, b2H
				end

				if cItem and inputEvents then
					for id, event in ipairs(inputEvents) do
						if event.type == "KeyUp" and event.key == "LEFTBUTTON" then
							if b1Hover then
								clickedCopySlot = jEntry.cSlotName
								inputEvents[id] = nil
							elseif b2Hover then
								clickedCopyUseSlot = jEntry.pSlotName
								inputEvents[id] = nil
							elseif b3Hover then
								clickedBuySlot = jEntry.pSlotName
								clickedBuyItem = cItem
								inputEvents[id] = nil
							end
						end
					end
				end

				drawY = drawY + 20
			end
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
		self:OpenBuySimilarPopup(clickedBuyItem, clickedBuySlot)
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

	-- Position pre-pass: compute gem positions without drawing to enable hover hit-testing
	local gemEntries = {} -- { gem, x, y, group }
	local preY = 4 - self.scrollY + 24 -- after headers
	for _, pair in ipairs(renderPairs) do
		preY = preY + 2 -- separator
		local pSet = pair.pIdx and pSets[pair.pIdx] or {}
		local cSet = pair.cIdx and cSets[pair.cIdx] or {}
		local pGemY = preY + lineHeight
		local cGemY = preY + lineHeight

		-- Primary group gems
		local pGroup = pair.pIdx and pGroups[pair.pIdx]
		if pGroup then
			for _, gem in ipairs(pGroup.gemList or {}) do
				t_insert(gemEntries, { gem = gem, x = 20, y = pGemY, group = pGroup })
				pGemY = pGemY + gemLineHeight
			end
			if pair.cIdx then
				for name in pairs(cSet) do
					if not pSet[name] then
						pGemY = pGemY + gemLineHeight -- missing gem placeholder
					end
				end
			end
		end

		-- Compare group gems
		local cGroup = pair.cIdx and cGroups[pair.cIdx]
		if cGroup then
			for _, gem in ipairs(cGroup.gemList or {}) do
				t_insert(gemEntries, { gem = gem, x = colWidth + 20, y = cGemY, group = cGroup })
				cGemY = cGemY + gemLineHeight
			end
			if pair.pIdx then
				for name in pairs(pSet) do
					if not cSet[name] then
						cGemY = cGemY + gemLineHeight
					end
				end
			end
		end

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
				if highlightSet[gem] then
					SetDrawColor(0.33, 1, 0.33, 0.25)
					DrawImage(nil, 20, gemY, gemTextWidth, gemLineHeight)
				end
				local gemName = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec or "?"
				local gemColor = gem.color or colorCodes.GEM
				local levelStr = gem.level and (" Lv" .. gem.level) or ""
				local qualStr = gem.quality and gem.quality > 0 and ("/" .. gem.quality .. "q") or ""
				local prefix = ""
				if pair.cIdx and not cSet[gemName] then
					prefix = colorCodes.POSITIVE .. "+ "
				end
				DrawString(20, gemY, "LEFT", gemFontSize, "VAR", prefix .. gemColor .. gemName .. "^7" .. levelStr .. qualStr)
				gemY = gemY + gemLineHeight
			end
			-- Show gems missing from primary but present in compare
			if pair.cIdx then
				local missing = {}
				for name in pairs(cSet) do
					if not pSet[name] then
						t_insert(missing, name)
					end
				end
				table.sort(missing)
				for _, name in ipairs(missing) do
					DrawString(20, gemY, "LEFT", gemFontSize, "VAR", colorCodes.NEGATIVE .. "- " .. name .. "^7")
					gemY = gemY + gemLineHeight
				end
			end
			pFinalGemY = gemY
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
				if highlightSet[gem] then
					SetDrawColor(0.33, 1, 0.33, 0.25)
					DrawImage(nil, colWidth + 20, gemY, gemTextWidth, gemLineHeight)
				end
				local gemName = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec or "?"
				local gemColor = gem.color or colorCodes.GEM
				local levelStr = gem.level and (" Lv" .. gem.level) or ""
				local qualStr = gem.quality and gem.quality > 0 and ("/" .. gem.quality .. "q") or ""
				local prefix = ""
				if pair.pIdx and not pSet[gemName] then
					prefix = colorCodes.POSITIVE .. "+ "
				end
				DrawString(colWidth + 20, gemY, "LEFT", gemFontSize, "VAR", prefix .. gemColor .. gemName .. "^7" .. levelStr .. qualStr)
				gemY = gemY + gemLineHeight
			end
			-- Show gems missing from compare but present in primary
			if pair.pIdx then
				local missing = {}
				for name in pairs(pSet) do
					if not cSet[name] then
						t_insert(missing, name)
					end
				end
				table.sort(missing)
				for _, name in ipairs(missing) do
					DrawString(colWidth + 20, gemY, "LEFT", gemFontSize, "VAR", colorCodes.NEGATIVE .. "- " .. name .. "^7")
					gemY = gemY + gemLineHeight
				end
			end
			cFinalGemY = gemY
		end

		-- Calculate height for this row
		drawY = drawY + m_max(pFinalGemY - drawY, cFinalGemY - drawY) + 6
	end

	SetViewport()
end

-- ============================================================
-- CALCS TOOLTIP HELPERS
-- ============================================================

-- Format a modifier value with its type for display
function CompareTabClass:FormatCalcModValue(value, modType)
	if modType == "BASE" then
		return s_format("%+g base", value)
	elseif modType == "INC" then
		if value >= 0 then
			return value .. "% increased"
		else
			return (-value) .. "% reduced"
		end
	elseif modType == "MORE" then
		if value >= 0 then
			return value .. "% more"
		else
			return (-value) .. "% less"
		end
	elseif modType == "OVERRIDE" then
		return "Override: " .. tostring(value)
	elseif modType == "FLAG" then
		return value and "True" or "False"
	else
		return tostring(value)
	end
end

-- Format CamelCase mod name to spaced words
function CompareTabClass:FormatCalcModName(modName)
	return modName:gsub("([%l%d]:?)(%u)", "%1 %2"):gsub("(%l)(%d)", "%1 %2")
end

-- Resolve a modifier's source to a human-readable name
function CompareTabClass:ResolveSourceName(mod, build)
	if not mod.source then return "" end
	local sourceType = mod.source:match("[^:]+") or ""
	if sourceType == "Item" then
		local itemId = mod.source:match("Item:(%d+):.+")
		local item = build.itemsTab and build.itemsTab.items[tonumber(itemId)]
		if item then
			return colorCodes[item.rarity] .. item.name
		end
	elseif sourceType == "Tree" then
		local nodeId = mod.source:match("Tree:(%d+)")
		if nodeId then
			local nodeIdNum = tonumber(nodeId)
			local node = (build.spec and build.spec.nodes[nodeIdNum])
				or (build.spec and build.spec.tree and build.spec.tree.nodes[nodeIdNum])
				or (build.latestTree and build.latestTree.nodes[nodeIdNum])
			if node then
				return node.dn or node.name or ""
			end
		end
	elseif sourceType == "Skill" then
		local skillId = mod.source:match("Skill:(.+)")
		if skillId and build.data and build.data.skills[skillId] then
			return build.data.skills[skillId].name
		end
	elseif sourceType == "Pantheon" then
		return mod.source:match("Pantheon:(.+)") or ""
	elseif sourceType == "Spectre" then
		return mod.source:match("Spectre:(.+)") or ""
	end
	return ""
end

-- Get the modDB and config for a sectionData entry and actor
function CompareTabClass:GetModStoreAndCfg(sectionData, actor)
	local cfg = {}
	if sectionData.cfg and actor.mainSkill and actor.mainSkill[sectionData.cfg .. "Cfg"] then
		cfg = copyTable(actor.mainSkill[sectionData.cfg .. "Cfg"], true)
	end
	cfg.source = sectionData.modSource
	cfg.actor = sectionData.actor

	local modStore
	if sectionData.enemy and actor.enemy then
		modStore = actor.enemy.modDB
	elseif sectionData.cfg and actor.mainSkill then
		modStore = actor.mainSkill.skillModList
	else
		modStore = actor.modDB
	end
	return modStore, cfg
end

-- Tabulate modifiers for a sectionData entry and actor
function CompareTabClass:TabulateMods(sectionData, actor)
	local modStore, cfg = self:GetModStoreAndCfg(sectionData, actor)
	if not modStore then return {} end

	local rowList
	if type(sectionData.modName) == "table" then
		rowList = modStore:Tabulate(sectionData.modType, cfg, unpack(sectionData.modName))
	else
		rowList = modStore:Tabulate(sectionData.modType, cfg, sectionData.modName)
	end
	return rowList or {}
end

-- Build a unique key for a modifier row to match between builds
function CompareTabClass:ModRowKey(row)
	local src = row.mod.source or ""
	local name = row.mod.name or ""
	local mtype = row.mod.type or ""
	-- Normalize Item sources by stripping the build-specific numeric ID
	-- "Item:5:Body Armour" -> "Item:Body Armour" so same items match across builds
	local normalizedSrc = src:gsub("^(Item):%d+:", "%1:")
	return normalizedSrc .. "|" .. name .. "|" .. mtype
end

-- Format a single modifier row as a tooltip line
function CompareTabClass:FormatModRow(row, sectionData, build)
	local displayValue
	if not sectionData.modType then
		displayValue = self:FormatCalcModValue(row.value, row.mod.type)
	else
		displayValue = formatRound(row.value, 2)
	end

	local sourceType = row.mod.source and row.mod.source:match("[^:]+") or "?"
	local sourceName = self:ResolveSourceName(row.mod, build)
	local modName = ""
	if type(sectionData.modName) == "table" then
		modName = "  " .. self:FormatCalcModName(row.mod.name)
	end

	return displayValue, sourceType, sourceName, modName
end

-- Get breakdown text lines for a build's actor
function CompareTabClass:GetBreakdownLines(sectionData, build)
	if not sectionData.breakdown then return nil end
	local calcsActor = build.calcsTab and build.calcsTab.calcsEnv and build.calcsTab.calcsEnv.player
	if not calcsActor or not calcsActor.breakdown then return nil end

	local breakdown
	local ns, name = sectionData.breakdown:match("^(%a+)%.(%a+)$")
	if ns then
		breakdown = calcsActor.breakdown[ns] and calcsActor.breakdown[ns][name]
	else
		breakdown = calcsActor.breakdown[sectionData.breakdown]
	end

	if not breakdown or #breakdown == 0 then return nil end

	local lines = {}
	for _, line in ipairs(breakdown) do
		if type(line) == "string" then
			t_insert(lines, line)
		end
	end
	return #lines > 0 and lines or nil
end

-- Draw the calcs hover tooltip showing breakdown for both builds with common/unique grouping
function CompareTabClass:DrawCalcsTooltip(colData, rowLabel, rowX, rowY, rowW, rowH, vp, compareEntry)
	local tooltip = self.calcsTooltip
	if tooltip:CheckForUpdate(colData, rowLabel) then
		-- Get calcsEnv actors (these have breakdown data populated)
		local primaryCalcsActor = self.primaryBuild.calcsTab and self.primaryBuild.calcsTab.calcsEnv
			and self.primaryBuild.calcsTab.calcsEnv.player
		local compareCalcsActor = compareEntry.calcsTab and compareEntry.calcsTab.calcsEnv
			and compareEntry.calcsTab.calcsEnv.player

		local primaryActor = primaryCalcsActor or (self.primaryBuild.calcsTab.mainEnv and self.primaryBuild.calcsTab.mainEnv.player)
		local compareActor = compareCalcsActor or (compareEntry.calcsTab.mainEnv and compareEntry.calcsTab.mainEnv.player)

		if not primaryActor and not compareActor then
			return
		end

		local primaryLabel = self:GetShortBuildName(self.primaryBuild.buildName)
		local compareLabel = compareEntry.label or "Compare Build"

		-- Tooltip header
		tooltip:AddLine(16, "^7" .. (rowLabel or ""))
		tooltip:AddSeparator(10)

		-- Process each sectionData entry in colData
		for _, sectionData in ipairs(colData) do
			-- Show breakdown formulas per build (these are always build-specific)
			if sectionData.breakdown then
				local primaryLines = self:GetBreakdownLines(sectionData, self.primaryBuild)
				local compareLines = self:GetBreakdownLines(sectionData, compareEntry)

				if primaryLines then
					tooltip:AddLine(14, colorCodes.POSITIVE .. primaryLabel .. ":")
					for _, line in ipairs(primaryLines) do
						tooltip:AddLine(14, "^7  " .. line)
					end
				end
				if compareLines then
					tooltip:AddLine(14, colorCodes.WARNING .. compareLabel .. ":")
					for _, line in ipairs(compareLines) do
						tooltip:AddLine(14, "^7  " .. line)
					end
				end
				if primaryLines or compareLines then
					tooltip:AddSeparator(10)
				end
			end

			-- Show modifier sources split into common / primary-only / compare-only
			if sectionData.modName then
				local pRows = primaryActor and self:TabulateMods(sectionData, primaryActor) or {}
				local cRows = compareActor and self:TabulateMods(sectionData, compareActor) or {}

				if #pRows > 0 or #cRows > 0 then
					-- Build lookup of compare rows by key
					local cByKey = {}
					for _, row in ipairs(cRows) do
						local key = self:ModRowKey(row)
						cByKey[key] = row
					end

					-- Classify into common, primary-only, compare-only
					local common = {}    -- { { pRow, cRow }, ... }
					local pOnly = {}
					local cMatched = {}  -- keys that were matched

					for _, pRow in ipairs(pRows) do
						local key = self:ModRowKey(pRow)
						if cByKey[key] then
							t_insert(common, { pRow, cByKey[key] })
							cMatched[key] = true
						else
							t_insert(pOnly, pRow)
						end
					end

					local cOnly = {}
					for _, cRow in ipairs(cRows) do
						local key = self:ModRowKey(cRow)
						if not cMatched[key] then
							t_insert(cOnly, cRow)
						end
					end

					-- Sub-section header (e.g., "Sources", "Increased Life Regeneration Rate")
					local sectionLabel = sectionData.label or "Player modifiers"
					tooltip:AddLine(14, "^7" .. sectionLabel .. ":")

					-- Common modifiers
					if #common > 0 then
						-- Sort by primary value descending
						table.sort(common, function(a, b)
							if type(a[1].value) == "number" and type(b[1].value) == "number" then
								return a[1].value > b[1].value
							end
							return false
						end)
						tooltip:AddLine(12, "^x808080  Common:")
						for _, pair in ipairs(common) do
							local pVal, sourceType, sourceName, modName = self:FormatModRow(pair[1], sectionData, self.primaryBuild)
							local cVal = self:FormatModRow(pair[2], sectionData, compareEntry)
							local valStr
							if pVal == cVal then
								valStr = s_format("^7%-10s", pVal)
							else
								valStr = colorCodes.POSITIVE .. s_format("%-5s", pVal) .. "^7/" .. colorCodes.WARNING .. s_format("%-5s", cVal)
							end
							local line = s_format("    %s ^7%-6s ^7%s%s", valStr, sourceType, sourceName, modName)
							tooltip:AddLine(12, line)
						end
					end

					-- Primary-only modifiers
					if #pOnly > 0 then
						table.sort(pOnly, function(a, b)
							if type(a.value) == "number" and type(b.value) == "number" then
								return a.value > b.value
							end
							return false
						end)
						tooltip:AddLine(12, colorCodes.POSITIVE .. "  " .. primaryLabel .. " only:")
						for _, row in ipairs(pOnly) do
							local displayValue, sourceType, sourceName, modName = self:FormatModRow(row, sectionData, self.primaryBuild)
							local line = s_format("    ^7%-10s ^7%-6s ^7%s%s", displayValue, sourceType, sourceName, modName)
							tooltip:AddLine(12, line)
						end
					end

					-- Compare-only modifiers
					if #cOnly > 0 then
						table.sort(cOnly, function(a, b)
							if type(a.value) == "number" and type(b.value) == "number" then
								return a.value > b.value
							end
							return false
						end)
						tooltip:AddLine(12, colorCodes.WARNING .. "  " .. compareLabel .. " only:")
						for _, row in ipairs(cOnly) do
							local displayValue, sourceType, sourceName, modName = self:FormatModRow(row, sectionData, compareEntry)
							local line = s_format("    ^7%-10s ^7%-6s ^7%s%s", displayValue, sourceType, sourceName, modName)
							tooltip:AddLine(12, line)
						end
					end

					-- Separator between sub-sections
					tooltip:AddSeparator(6)
				end
			end
		end
	end

	SetDrawLayer(nil, 100)
	tooltip:Draw(rowX, rowY, rowW, rowH, vp)
	SetDrawLayer(nil, 0)
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

	-- Card dimensions
	-- Layout: [2px border | 130px label | 2px gap | 2px sep | valW | 2px sep | valW | 2px border]
	local cardWidth = m_min(LAYOUT.calcsMaxCardWidth, vp.width - 16)
	local labelWidth = LAYOUT.calcsLabelWidth
	local sepW = LAYOUT.calcsSepW
	local valColWidth = m_floor((cardWidth - 140) / 2)
	local valCol1X = labelWidth + sepW * 2
	local valCol2X = valCol1X + valColWidth + sepW

	-- Layout parameters
	local maxCol = m_max(1, m_floor(vp.width / (cardWidth + 8)))
	local baseX = 4
	local headerBarHeight = LAYOUT.calcsHeaderBarHeight
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

	-- Cursor position relative to viewport (for hover detection)
	local cursorX, cursorY = GetCursorPos()
	local vpCursorX = cursorX - vp.x
	local vpCursorY = cursorY - vp.y
	local hoverColData = nil
	local hoverRowLabel = nil
	local hoverRowX, hoverRowY, hoverRowW, hoverRowH = 0, 0, 0, 0

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
						local ok, str = pcall(self.FormatStr, self, colData.format, primaryActor, colData)
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

	-- Draw hover tooltip for calcs breakdown (reset viewport first so tooltip can extend beyond)
	if hoverColData then
		SetViewport()
		self:DrawCalcsTooltip(hoverColData, hoverRowLabel, hoverRowX + vp.x, hoverRowY + vp.y, hoverRowW, hoverRowH, vp, compareEntry)
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
	DrawString(headerBaseX + LAYOUT.configCol2, colHeaderY, "LEFT", columnHeaderHeight, "VAR",
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
