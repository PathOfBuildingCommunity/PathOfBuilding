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
	self.controls.compareBuildLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -48, 0, 16}, "^7Compare with:")
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

	self.controls.compareSetsLabel = new("LabelControl", {"TOPLEFT", self.controls.subTabAnchor, "TOPLEFT"}, {0, -22, 0, 16}, "^7Sets:")
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
	-- Tree footer controls (visible only in TREE view mode with a comparison loaded)
	-- ============================================================
	local treeFooterShown = function()
		return self.compareViewMode == "TREE" and self:GetActiveCompare() ~= nil
	end

	-- Build version dropdown list (shared between left and right)
	self.treeVersionDropdownList = {}
	for _, num in ipairs(treeVersionList) do
		t_insert(self.treeVersionDropdownList, {
			label = treeVersions[num].display,
			value = num
		})
	end

	-- Footer anchor controls (positioned dynamically in Draw)
	self.controls.leftFooterAnchor = new("Control", nil, {0, 0, 0, 20})
	self.controls.leftFooterAnchor.shown = treeFooterShown
	self.controls.rightFooterAnchor = new("Control", nil, {0, 0, 0, 20})
	self.controls.rightFooterAnchor.shown = treeFooterShown

	-- Left side (primary build) footer controls
	self.controls.leftSpecSelect = new("DropDownControl", {"LEFT", self.controls.leftFooterAnchor, "LEFT"}, {0, 0, 180, 20}, {}, function(index, value)
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

	self.controls.leftTreeSearch = new("EditControl", {"TOPLEFT", self.controls.leftFooterAnchor, "TOPLEFT"}, {0, 24, 200, 20}, "", "Search", "%c", 100, function(buf)
		if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
			self.primaryBuild.treeTab.viewer.searchStr = buf
		end
	end, nil, nil, true)
	self.controls.leftTreeSearch.shown = treeFooterShown

	-- Right side (compare build) footer controls
	self.controls.rightSpecSelect = new("DropDownControl", {"LEFT", self.controls.rightFooterAnchor, "LEFT"}, {0, 0, 180, 20}, {}, function(index, value)
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

	self.controls.rightTreeSearch = new("EditControl", {"TOPLEFT", self.controls.rightFooterAnchor, "TOPLEFT"}, {0, 24, 200, 20}, "", "Search", "%c", 100, function(buf)
		local entry = self:GetActiveCompare()
		if entry and entry.treeTab and entry.treeTab.viewer then
			entry.treeTab.viewer.searchStr = buf
		end
	end, nil, nil, true)
	self.controls.rightTreeSearch.shown = treeFooterShown
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
	controls.state = new("LabelControl", {"TOPLEFT", controls.input, "BOTTOMLEFT"}, {0, 4, 0, 16})
	controls.state.label = function()
		return stateText or ""
	end
	controls.go = new("ButtonControl", nil, {-45, 100, 80, 20}, "Import", function()
		local buf = controls.input.buf
		if not buf or buf == "" then
			return
		end

		-- Check if it's a URL
		for _, site in ipairs(buildSites.websiteList) do
			if buf:match(site.matchURL) then
				stateText = colorCodes.WARNING .. "Downloading..."
				buildSites.DownloadBuild(buf, site, function(isSuccess, codeData)
					if isSuccess then
						local xmlText = Inflate(common.base64.decode(codeData:gsub("-","+"):gsub("_","/")))
						if xmlText then
							self:ImportBuild(xmlText, "Imported from " .. site.label)
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
			self:ImportBuild(xmlText, "Imported build")
			main:ClosePopup()
		else
			stateText = colorCodes.NEGATIVE .. "Invalid build code"
		end
	end)
	controls.cancel = new("ButtonControl", nil, {45, 100, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(500, 130, "Import Comparison Build", controls, "go", "input", "cancel")
end

-- ============================================================
-- DRAW - Main render method
-- ============================================================
function CompareTabClass:Draw(viewPort, inputEvents)
	local controlBarHeight = 74

	-- Position top-bar controls
	self.controls.subTabAnchor.x = viewPort.x + 4
	self.controls.subTabAnchor.y = viewPort.y + 52

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
		local halfWidth = m_floor(contentVP.width / 2) - 2
		local footerHeight = 50
		local footerY = contentVP.y + contentVP.height - footerHeight
		local rightAbsX = contentVP.x + halfWidth + 4
		local specWidth = m_min(m_floor(halfWidth * 0.55), 200)

		-- Store layout for DrawTree
		self.treeLayout = {
			halfWidth = halfWidth,
			footerHeight = footerHeight,
			footerY = footerY,
			rightAbsX = rightAbsX,
		}

		-- Draw footer backgrounds
		SetDrawColor(0.05, 0.05, 0.05)
		DrawImage(nil, contentVP.x, footerY, halfWidth, footerHeight)
		DrawImage(nil, rightAbsX, footerY, halfWidth, footerHeight)
		SetDrawColor(0.85, 0.85, 0.85)
		DrawImage(nil, contentVP.x, footerY, halfWidth, 2)
		DrawImage(nil, rightAbsX, footerY, halfWidth, 2)

		-- Position left footer controls
		self.controls.leftFooterAnchor.x = contentVP.x + 4
		self.controls.leftFooterAnchor.y = footerY + 4
		self.controls.leftSpecSelect.width = specWidth
		self.controls.leftTreeSearch.width = halfWidth - 8

		-- Position right footer controls
		self.controls.rightFooterAnchor.x = rightAbsX + 4
		self.controls.rightFooterAnchor.y = footerY + 4
		self.controls.rightSpecSelect.width = specWidth
		self.controls.rightTreeSearch.width = halfWidth - 8

		-- Update spec dropdown lists
		if self.primaryBuild.treeTab then
			self.controls.leftSpecSelect.list = self.primaryBuild.treeTab:GetSpecList()
			self.controls.leftSpecSelect.selIndex = self.primaryBuild.treeTab.activeSpec
		end
		if compareEntry.treeTab then
			self.controls.rightSpecSelect.list = compareEntry.treeTab:GetSpecList()
			self.controls.rightSpecSelect.selIndex = compareEntry.treeTab.activeSpec
		end

		-- Update version dropdown selection to match current spec
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

		-- Sync search fields when entering tree mode or changing compare entry
		if self.treeSearchNeedsSync then
			self.treeSearchNeedsSync = false
			if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
				self.controls.leftTreeSearch:SetText(self.primaryBuild.treeTab.viewer.searchStr or "")
			end
			if compareEntry.treeTab and compareEntry.treeTab.viewer then
				self.controls.rightTreeSearch:SetText(compareEntry.treeTab.viewer.searchStr or "")
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

	-- Draw controls (footer controls render on top of pre-drawn backgrounds)
	self:DrawControls(viewPort)

	if not compareEntry then
		-- No comparison build loaded - show instructions
		SetDrawColor(1, 1, 1)
		DrawString(contentVP.x + contentVP.width / 2, contentVP.y + 40, "CENTER", 20, "VAR",
			"^7No comparison build loaded.")
		DrawString(contentVP.x + contentVP.width / 2, contentVP.y + 70, "CENTER", 16, "VAR",
			"^7Click " .. colorCodes.POSITIVE .. "Import..." .. "^7 above to import a build to compare against,")
		DrawString(contentVP.x + contentVP.width / 2, contentVP.y + 90, "CENTER", 16, "VAR",
			"^7or use the " .. colorCodes.POSITIVE .. "Import/Export Build" .. "^7 tab with \"Import as comparison\" mode.")
		return
	end

	-- Dispatch to sub-view
	if self.compareViewMode == "SUMMARY" then
		self:DrawSummary(contentVP, compareEntry)
	elseif self.compareViewMode == "TREE" then
		self:DrawTree(contentVP, inputEvents, compareEntry)
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
	local colWidth = m_floor(vp.width / 2)

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", headerHeight, "VAR", colorCodes.POSITIVE .. "Your Build: ^7" .. (self.primaryBuild.buildName or "Current"))
	DrawString(colWidth + 10, drawY, "LEFT", headerHeight, "VAR", colorCodes.WARNING .. "Compare: ^7" .. (compareEntry.label or "Comparison"))
	drawY = drawY + headerHeight + 4

	-- Separator
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 6

	-- Progress section
	drawY = self:DrawProgressSection(drawY, colWidth, vp, compareEntry)
	drawY = drawY + 4

	-- Separator
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 6

	-- Stat comparison
	local displayStats = self.primaryBuild.displayStats
	local primaryEnv = self.primaryBuild.calcsTab.mainEnv
	local compareEnv = compareEntry.calcsTab.mainEnv

	-- Section: Offence
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", headerHeight, "VAR", colorCodes.OFFENCE .. "Offence")
	drawY = drawY + headerHeight + 2

	drawY = self:DrawStatSection(drawY, colWidth, vp, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, {"attack", "spell", "dot"})

	-- Section: Defence
	drawY = drawY + 6
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 1)
	drawY = drawY + 4
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", headerHeight, "VAR", colorCodes.DEFENCE .. "Defence")
	drawY = drawY + headerHeight + 2

	drawY = self:DrawStatSection(drawY, colWidth, vp, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, nil)

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

function CompareTabClass:DrawStatSection(drawY, colWidth, vp, displayStats, primaryOutput, compareOutput, primaryEnv, compareEnv, flagFilter)
	local lineHeight = 16

	for _, statData in ipairs(displayStats) do
		if statData.stat then
			local primaryVal = primaryOutput[statData.stat] or 0
			local compareVal = compareOutput[statData.stat] or 0

			-- Skip table-type stat values (some outputs are breakdowns, not numbers)
			if type(primaryVal) == "table" or type(compareVal) == "table" then
				primaryVal = 0
				compareVal = 0
			end

			-- Skip zero-value stats
			if primaryVal ~= 0 or compareVal ~= 0 then
				-- Check if stat has a condition function that filters it
				if not statData.condFunc or statData.condFunc(primaryVal, primaryOutput) or statData.condFunc(compareVal, compareOutput) then
					-- Format values
					local fmt = statData.fmt or "d"
					local multiplier = (statData.pc or statData.mod) and 100 or 1
					local primaryStr = s_format("%"..fmt, primaryVal * multiplier)
					local compareStr = s_format("%"..fmt, compareVal * multiplier)
					primaryStr = formatNumSep(primaryStr)
					compareStr = formatNumSep(compareStr)

					-- Determine diff color
					local diff = compareVal - primaryVal
					local diffStr = ""
					local diffColor = "^7"
					if diff > 0.001 or diff < -0.001 then
						local isBetter = (statData.lowerIsBetter and diff < 0) or (not statData.lowerIsBetter and diff > 0)
						diffColor = isBetter and colorCodes.POSITIVE or colorCodes.NEGATIVE
						local diffVal = diff * multiplier
						diffStr = s_format("%+"..fmt, diffVal)
						diffStr = formatNumSep(diffStr)
					end

					-- Draw stat row
					DrawString(20, drawY, "LEFT", lineHeight, "VAR", "^7" .. (statData.label or statData.stat) .. ":")
					DrawString(colWidth - 10, drawY, "RIGHT", lineHeight, "VAR", "^7" .. primaryStr)
					DrawString(colWidth + colWidth - 10, drawY, "RIGHT", lineHeight, "VAR", diffColor .. compareStr)
					if diffStr ~= "" then
						DrawString(colWidth + colWidth + 10, drawY, "LEFT", lineHeight, "VAR", diffColor .. "(" .. diffStr .. ")")
					end
					drawY = drawY + lineHeight + 1
				end
			end
		end
	end
	return drawY
end

-- ============================================================
-- TREE VIEW (side-by-side)
-- ============================================================
function CompareTabClass:DrawTree(vp, inputEvents, compareEntry)
	local layout = self.treeLayout
	if not layout then return end

	local halfWidth = layout.halfWidth
	local footerHeight = layout.footerHeight
	local labelHeight = 20

	-- Labels (drawn in absolute screen coords before any viewport changes)
	SetDrawColor(1, 1, 1)
	DrawString(vp.x + halfWidth / 2, vp.y + 2, "CENTER", 16, "VAR", colorCodes.POSITIVE .. "Your Build" .. "^7 (" .. (self.primaryBuild.buildName or "Current") .. ")")
	DrawString(vp.x + halfWidth + 4 + halfWidth / 2, vp.y + 2, "CENTER", 16, "VAR", colorCodes.WARNING .. "Compare" .. "^7 (" .. (compareEntry.label or "Comparison") .. ")")

	-- Divider (full height including footer)
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, vp.x + halfWidth, vp.y + labelHeight, 4, vp.height - labelHeight)

	-- Route input events to the panel containing the mouse
	local origGetCursorPos = GetCursorPos
	local mouseX, mouseY = origGetCursorPos()
	local leftHasInput = mouseX < (vp.x + halfWidth + 2)

	local treeHeight = vp.height - labelHeight - footerHeight

	-- Left tree: SetViewport clips drawing; patch GetCursorPos so mouse coords
	-- are viewport-relative (matching the {x=0,y=0} viewport passed to the tree)
	local leftAbsX = vp.x
	local leftAbsY = vp.y + labelHeight
	if self.primaryBuild.treeTab and self.primaryBuild.treeTab.viewer then
		SetViewport(leftAbsX, leftAbsY, halfWidth, treeHeight)
		SetDrawLayer(nil, 0) -- Reset draw layer so background renders behind connectors
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
	local rightAbsY = vp.y + labelHeight
	if compareEntry.treeTab and compareEntry.treeTab.viewer then
		SetViewport(rightAbsX, rightAbsY, halfWidth, treeHeight)
		SetDrawLayer(nil, 0) -- Reset draw layer so background renders behind connectors
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

	-- Footer backgrounds and controls are drawn by Draw() before this method
	-- (so that controls render on top of the background rectangles)
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

	-- Headers
	SetDrawColor(1, 1, 1)
	DrawString(10, drawY, "LEFT", 18, "VAR", colorCodes.POSITIVE .. "Your Build")
	DrawString(colWidth + 10, drawY, "LEFT", 18, "VAR", colorCodes.WARNING .. "Compare Build")
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
	DrawString(10, drawY, "LEFT", 18, "VAR", colorCodes.POSITIVE .. "Your Build - Socket Groups")
	DrawString(colWidth + 10, drawY, "LEFT", 18, "VAR", colorCodes.WARNING .. "Compare Build - Socket Groups")
	drawY = drawY + 24

	-- Get socket groups from both builds
	local pGroups = self.primaryBuild.skillsTab and self.primaryBuild.skillsTab.socketGroupList or {}
	local cGroups = compareEntry.skillsTab and compareEntry.skillsTab.socketGroupList or {}

	-- Draw primary build groups
	local maxGroups = m_max(#pGroups, #cGroups)
	for i = 1, maxGroups do
		SetDrawColor(0.3, 0.3, 0.3)
		DrawImage(nil, 4, drawY, vp.width - 8, 1)
		drawY = drawY + 2

		-- Primary group
		local pGroup = pGroups[i]
		if pGroup then
			local groupLabel = pGroup.displayLabel or pGroup.label or ("Group " .. i)
			if pGroup.slot then
				groupLabel = groupLabel .. " (" .. pGroup.slot .. ")"
			end
			DrawString(10, drawY, "LEFT", 16, "VAR", "^7" .. groupLabel)
			local gemY = drawY + lineHeight
			for _, gem in ipairs(pGroup.gemList or {}) do
				local gemName = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec or "?"
				local levelStr = gem.level and (" Lv" .. gem.level) or ""
				local qualStr = gem.quality and gem.quality > 0 and ("/" .. gem.quality .. "q") or ""
				DrawString(20, gemY, "LEFT", 14, "VAR", colorCodes.GEM .. gemName .. "^7" .. levelStr .. qualStr)
				gemY = gemY + 16
			end
		end

		-- Compare group
		local cGroup = cGroups[i]
		if cGroup then
			local groupLabel = cGroup.displayLabel or cGroup.label or ("Group " .. i)
			if cGroup.slot then
				groupLabel = groupLabel .. " (" .. cGroup.slot .. ")"
			end
			DrawString(colWidth + 10, drawY, "LEFT", 16, "VAR", "^7" .. groupLabel)
			local gemY = drawY + lineHeight
			for _, gem in ipairs(cGroup.gemList or {}) do
				local gemName = gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec or "?"
				local levelStr = gem.level and (" Lv" .. gem.level) or ""
				local qualStr = gem.quality and gem.quality > 0 and ("/" .. gem.quality .. "q") or ""
				DrawString(colWidth + 20, gemY, "LEFT", 14, "VAR", colorCodes.GEM .. gemName .. "^7" .. levelStr .. qualStr)
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
-- CALCS VIEW
-- ============================================================
function CompareTabClass:DrawCalcs(vp, compareEntry)
	local primaryOutput = self.primaryBuild.calcsTab.mainOutput
	local compareOutput = compareEntry:GetOutput()
	if not primaryOutput or not compareOutput then
		return
	end

	local lineHeight = 16
	local headerHeight = 20
	local displayStats = self.primaryBuild.displayStats

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Column headers
	local col1 = 10   -- Stat name
	local col2 = 300  -- Your Build value
	local col3 = 450  -- Compare Build value
	local col4 = 600  -- Difference

	SetDrawColor(1, 1, 1)
	DrawString(col1, drawY, "LEFT", headerHeight, "VAR", "^7Stat")
	DrawString(col2, drawY, "LEFT", headerHeight, "VAR", colorCodes.POSITIVE .. "Your Build")
	DrawString(col3, drawY, "LEFT", headerHeight, "VAR", colorCodes.WARNING .. "Compare")
	DrawString(col4, drawY, "LEFT", headerHeight, "VAR", "^7Difference")
	drawY = drawY + headerHeight + 4

	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 6

	for _, statData in ipairs(displayStats) do
		if statData.stat then
			local primaryVal = primaryOutput[statData.stat] or 0
			local compareVal = compareOutput[statData.stat] or 0

			-- Skip table-type stat values (some outputs are breakdowns, not numbers)
			if type(primaryVal) == "table" or type(compareVal) == "table" then
				primaryVal = 0
				compareVal = 0
			end

			if primaryVal ~= 0 or compareVal ~= 0 then
				if not statData.condFunc or statData.condFunc(primaryVal, primaryOutput) or statData.condFunc(compareVal, compareOutput) then
					local fmt = statData.fmt or "d"
					local multiplier = (statData.pc or statData.mod) and 100 or 1

					local primaryStr = s_format("%"..fmt, primaryVal * multiplier)
					local compareStr = s_format("%"..fmt, compareVal * multiplier)
					primaryStr = formatNumSep(primaryStr)
					compareStr = formatNumSep(compareStr)

					local diff = compareVal - primaryVal
					local diffStr = ""
					local diffColor = "^7"
					if diff > 0.001 or diff < -0.001 then
						local isBetter = (statData.lowerIsBetter and diff < 0) or (not statData.lowerIsBetter and diff > 0)
						diffColor = isBetter and colorCodes.POSITIVE or colorCodes.NEGATIVE
						diffStr = s_format("%+"..fmt, diff * multiplier)
						diffStr = formatNumSep(diffStr)
						if statData.compPercent and primaryVal ~= 0 then
							local pc = compareVal / primaryVal * 100 - 100
							diffStr = diffStr .. s_format(" (%+.1f%%)", pc)
						end
					end

					DrawString(col1, drawY, "LEFT", lineHeight, "VAR", "^7" .. (statData.label or statData.stat))
					DrawString(col2, drawY, "LEFT", lineHeight, "VAR", "^7" .. primaryStr)
					DrawString(col3, drawY, "LEFT", lineHeight, "VAR", diffColor .. compareStr)
					if diffStr ~= "" then
						DrawString(col4, drawY, "LEFT", lineHeight, "VAR", diffColor .. diffStr)
					end
					drawY = drawY + lineHeight + 1
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
	local lineHeight = 18
	local headerHeight = 20

	SetViewport(vp.x, vp.y, vp.width, vp.height)
	local drawY = 4 - self.scrollY

	-- Headers
	local col1 = 10
	local col2 = 300
	local col3 = 500

	SetDrawColor(1, 1, 1)
	DrawString(col1, drawY, "LEFT", headerHeight, "VAR", "^7Configuration Option")
	DrawString(col2, drawY, "LEFT", headerHeight, "VAR", colorCodes.POSITIVE .. "Your Build")
	DrawString(col3, drawY, "LEFT", headerHeight, "VAR", colorCodes.WARNING .. "Compare Build")
	drawY = drawY + headerHeight + 4

	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(nil, 4, drawY, vp.width - 8, 2)
	drawY = drawY + 6

	-- Compare config inputs
	local pInput = self.primaryBuild.configTab.input or {}
	local cInput = compareEntry.configTab.input or {}

	-- Collect all unique keys
	local allKeys = {}
	local keySet = {}
	for k, _ in pairs(pInput) do
		if not keySet[k] then
			t_insert(allKeys, k)
			keySet[k] = true
		end
	end
	for k, _ in pairs(cInput) do
		if not keySet[k] then
			t_insert(allKeys, k)
			keySet[k] = true
		end
	end
	table.sort(allKeys)

	local diffCount = 0
	for _, key in ipairs(allKeys) do
		local pVal = pInput[key]
		local cVal = cInput[key]

		-- Only show differences
		if tostring(pVal or "") ~= tostring(cVal or "") then
			local pStr = pVal ~= nil and tostring(pVal) or "^8(not set)"
			local cStr = cVal ~= nil and tostring(cVal) or "^8(not set)"

			-- Format boolean values
			if pVal == true then pStr = colorCodes.POSITIVE .. "Yes"
			elseif pVal == false then pStr = colorCodes.NEGATIVE .. "No" end
			if cVal == true then cStr = colorCodes.POSITIVE .. "Yes"
			elseif cVal == false then cStr = colorCodes.NEGATIVE .. "No" end

			DrawString(col1, drawY, "LEFT", lineHeight, "VAR", "^7" .. key)
			DrawString(col2, drawY, "LEFT", lineHeight, "VAR", "^7" .. pStr)
			DrawString(col3, drawY, "LEFT", lineHeight, "VAR", "^7" .. cStr)
			drawY = drawY + lineHeight + 1
			diffCount = diffCount + 1
		end
	end

	if diffCount == 0 then
		DrawString(10, drawY, "LEFT", lineHeight, "VAR", colorCodes.POSITIVE .. "No configuration differences found.")
	end

	SetViewport()
end

return CompareTabClass
