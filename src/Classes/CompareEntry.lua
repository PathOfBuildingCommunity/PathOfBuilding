-- Path of Building
--
-- Module: Compare Entry
-- Lightweight Build wrapper for comparison. Loads XML, creates tabs, and runs calculations
-- without setting up the full UI chrome of the primary build.
--
local t_insert = table.insert
local s_format = string.format
local m_min = math.min
local m_max = math.max

local CompareEntryClass = newClass("CompareEntry", "ControlHost", function(self, xmlText, label)
	self.ControlHost()

	self.label = label or "Comparison Build"
	self.buildName = label or "Comparison Build"
	self.xmlText = xmlText

	-- Default build properties
	self.viewMode = "TREE"
	self.characterLevel = m_min(m_max(main.defaultCharLevel or 1, 1), 100)
	self.targetVersion = liveTargetVersion
	self.bandit = "None"
	self.pantheonMajorGod = "None"
	self.pantheonMinorGod = "None"
	self.characterLevelAutoMode = main.defaultCharLevel == 1 or main.defaultCharLevel == nil
	self.mainSocketGroup = 1
	self.notesText = ""

	self.spectreList = {}
	self.timelessData = {
		jewelType = {}, conquerorType = {},
		devotionVariant1 = 1, devotionVariant2 = 1,
		jewelSocket = {}, fallbackWeightMode = {},
		searchList = "", searchListFallback = "",
		searchResults = {}, sharedResults = {}
	}

	-- Shared data (read-only references)
	self.latestTree = main.tree[latestTreeVersion]
	self.data = data

	-- Flags
	self.buildFlag = false
	self.outputRevision = 1

	-- Display stats (same as primary build uses)
	self.displayStats, self.minionDisplayStats, self.extraSaveStats = LoadModule("Modules/BuildDisplayStats")

	-- Load from XML
	if xmlText then
		self:LoadFromXML(xmlText)
	end
end)

function CompareEntryClass:LoadFromXML(xmlText)
	-- Parse the XML
	local dbXML, errMsg = common.xml.ParseXML(xmlText)
	if errMsg then
		ConPrintf("CompareEntry: Error parsing XML: %s", errMsg)
		return true
	end
	if not dbXML or not dbXML[1] or dbXML[1].elem ~= "PathOfBuilding" then
		ConPrintf("CompareEntry: 'PathOfBuilding' root element missing")
		return true
	end

	-- Load Build section first
	for _, node in ipairs(dbXML[1]) do
		if type(node) == "table" and node.elem == "Build" then
			self:LoadBuildSection(node)
			break
		end
	end

	-- Check for import link
	for _, node in ipairs(dbXML[1]) do
		if type(node) == "table" and node.elem == "Import" then
			if node.attrib.importLink then
				self.importLink = node.attrib.importLink
			end
			break
		end
	end

	-- Store XML sections for tab loading
	self.xmlSectionList = {}
	for _, node in ipairs(dbXML[1]) do
		if type(node) == "table" then
			t_insert(self.xmlSectionList, node)
		end
	end

	-- Version check
	if self.targetVersion ~= liveTargetVersion then
		self.targetVersion = liveTargetVersion
	end

	-- Create tabs
	-- PartyTab is replaced with a stub providing an empty enemyModList and actor
	-- (CalcPerform.lua:1088 accesses build.partyTab.actor for party member buffs)
	local partyActor = { Aura = {}, Curse = {}, Warcry = {}, Link = {}, modDB = new("ModDB"), output = {} }
	partyActor.modDB.actor = partyActor
	self.partyTab = { enemyModList = new("ModList"), actor = partyActor }
	self.configTab = new("ConfigTab", self)
	self.itemsTab = new("ItemsTab", self)
	self.treeTab = new("TreeTab", self)
	self.skillsTab = new("SkillsTab", self)
	self.calcsTab = new("CalcsTab", self)

	-- Set up savers table
	self.savers = {
		["Config"] = self.configTab,
		["Tree"] = self.treeTab,
		["TreeView"] = self.treeTab.viewer,
		["Items"] = self.itemsTab,
		["Skills"] = self.skillsTab,
		["Calcs"] = self.calcsTab,
	}
	self.legacyLoaders = {
		["Spec"] = self.treeTab,
	}

	-- Special rebuild to properly initialise boss placeholders
	self.configTab:BuildModList()

	-- Load legacy bandit and pantheon choices from build section
	for _, control in ipairs({ "bandit", "pantheonMajorGod", "pantheonMinorGod" }) do
		self.configTab.input[control] = self[control]
	end

	-- Load XML sections into tabs
	-- Defer passive trees until after items are loaded (jewel socket issue)
	local deferredPassiveTrees = {}
	for _, node in ipairs(self.xmlSectionList) do
		local saver = self.savers[node.elem] or self.legacyLoaders[node.elem]
		if saver then
			if saver == self.treeTab then
				t_insert(deferredPassiveTrees, node)
			else
				saver:Load(node, "CompareEntry")
			end
		end
	end
	for _, node in ipairs(deferredPassiveTrees) do
		self.treeTab:Load(node, "CompareEntry")
	end
	for _, saver in pairs(self.savers) do
		if saver.PostLoad then
			saver:PostLoad()
		end
	end

	-- Extract notes from the build XML
	for _, node in ipairs(self.xmlSectionList) do
		if node.elem == "Notes" then
			for _, child in ipairs(node) do
				if type(child) == "string" then
					self.notesText = child
					break
				end
			end
			break
		end
	end

	if next(self.configTab.input) == nil then
		if self.configTab.ImportCalcSettings then
			self.configTab:ImportCalcSettings()
		end
	end

	self:SyncCalcsSkillSelection()
	self.calcsTab:BuildOutput()
	self.buildFlag = false
end

-- Load build section attributes
function CompareEntryClass:LoadBuildSection(xml)
	self.targetVersion = xml.attrib.targetVersion or legacyTargetVersion
	if xml.attrib.viewMode then
		self.viewMode = xml.attrib.viewMode
	end
	self.characterLevel = tonumber(xml.attrib.level) or 1
	self.characterLevelAutoMode = xml.attrib.characterLevelAutoMode == "true"
	for _, diff in pairs({ "bandit", "pantheonMajorGod", "pantheonMinorGod" }) do
		self[diff] = xml.attrib[diff] or "None"
	end
	self.mainSocketGroup = tonumber(xml.attrib.mainSkillIndex) or tonumber(xml.attrib.mainSocketGroup) or 1
	wipeTable(self.spectreList)
	for _, child in ipairs(xml) do
		if child.elem == "Spectre" then
			if child.attrib.id and data.minions[child.attrib.id] then
				t_insert(self.spectreList, child.attrib.id)
			end
		elseif child.elem == "TimelessData" then
			self.timelessData.jewelType = { id = tonumber(child.attrib.jewelTypeId) }
			self.timelessData.conquerorType = { id = tonumber(child.attrib.conquerorTypeId) }
			self.timelessData.devotionVariant1 = tonumber(child.attrib.devotionVariant1) or 1
			self.timelessData.devotionVariant2 = tonumber(child.attrib.devotionVariant2) or 1
			self.timelessData.jewelSocket = { id = tonumber(child.attrib.jewelSocketId) }
			self.timelessData.fallbackWeightMode = { idx = tonumber(child.attrib.fallbackWeightModeIdx) }
			self.timelessData.socketFilter = child.attrib.socketFilter == "true"
			self.timelessData.socketFilterDistance = tonumber(child.attrib.socketFilterDistance) or 0
			self.timelessData.searchList = child.attrib.searchList
			self.timelessData.searchListFallback = child.attrib.searchListFallback
		end
	end
end

function CompareEntryClass:GetOutput()
	return self.calcsTab.mainOutput
end

function CompareEntryClass:GetSpec()
	return self.spec
end

function CompareEntryClass:SyncCalcsSkillSelection()
	self.calcsTab.input.skill_number = self.mainSocketGroup

	local mainGroup = self.skillsTab and self.skillsTab.socketGroupList[self.mainSocketGroup]
	if not mainGroup then return end

	mainGroup.mainActiveSkillCalcs = mainGroup.mainActiveSkill

	local displaySkillList = mainGroup.displaySkillList
	local activeSkill = displaySkillList and displaySkillList[mainGroup.mainActiveSkill or 1]
	if activeSkill and activeSkill.activeEffect and activeSkill.activeEffect.srcInstance then
		local src = activeSkill.activeEffect.srcInstance
		src.skillPartCalcs = src.skillPart
		src.skillStageCountCalcs = src.skillStageCount
		src.skillMineCountCalcs = src.skillMineCount
		src.skillMinionCalcs = src.skillMinion
		src.skillMinionItemSetCalcs = src.skillMinionItemSet
		src.skillMinionSkillCalcs = src.skillMinionSkill
	end
end

function CompareEntryClass:Rebuild()
	wipeGlobalCache()
	self.outputRevision = self.outputRevision + 1
	self.calcsTab:BuildOutput()
	self.buildFlag = false
end

function CompareEntryClass:SetActiveSpec(index)
	if self.treeTab and self.treeTab.SetActiveSpec then
		self.treeTab:SetActiveSpec(index)
		self:Rebuild()
	end
end

function CompareEntryClass:SetActiveItemSet(id)
	if self.itemsTab and self.itemsTab.SetActiveItemSet then
		self.itemsTab:SetActiveItemSet(id)
		self:Rebuild()
	end
end

function CompareEntryClass:SetActiveSkillSet(id)
	if self.skillsTab and self.skillsTab.SetActiveSkillSet then
		self.skillsTab:SetActiveSkillSet(id)
		self:Rebuild()
	end
end

-- Stub methods that the build interface may call
function CompareEntryClass:RefreshStatList()
	-- No sidebar to refresh in comparison entry
end

function CompareEntryClass:SetMainSocketGroup(index)
	self.mainSocketGroup = index
	self.buildFlag = true
end

function CompareEntryClass:RefreshSkillSelectControls(controls, mainGroup, suffix)
	-- Populate skill select controls
	if not controls or not controls.mainSocketGroup then return end
	controls.mainSocketGroup.selIndex = mainGroup
	wipeTable(controls.mainSocketGroup.list)
	for i, socketGroup in pairs(self.skillsTab.socketGroupList) do
		controls.mainSocketGroup.list[i] = { val = i, label = socketGroup.displayLabel }
	end
	controls.mainSocketGroup:CheckDroppedWidth(true)

	-- Helper: hide all skill detail controls
	local function hideAllSkillControls()
		controls.mainSkill.shown = false
		controls.mainSkillPart.shown = false
		controls.mainSkillMineCount.shown = false
		controls.mainSkillStageCount.shown = false
		controls.mainSkillMinion.shown = false
		controls.mainSkillMinionSkill.shown = false
	end

	if #controls.mainSocketGroup.list == 0 then
		controls.mainSocketGroup.list[1] = { val = 1, label = "<No skills added yet>" }
		hideAllSkillControls()
		return
	end

	local mainSocketGroup = self.skillsTab.socketGroupList[mainGroup]
	if not mainSocketGroup then
		mainSocketGroup = self.skillsTab.socketGroupList[1]
		mainGroup = 1
	end
	local displaySkillList = mainSocketGroup["displaySkillList"..suffix]
	if not displaySkillList then
		hideAllSkillControls()
		return
	end

	-- Populate main skill dropdown
	local mainActiveSkill = mainSocketGroup["mainActiveSkill"..suffix] or 1
	wipeTable(controls.mainSkill.list)
	for i, activeSkill in ipairs(displaySkillList) do
		local explodeSource = activeSkill.activeEffect.srcInstance.explodeSource
		local explodeSourceName = explodeSource and (explodeSource.name or explodeSource.dn)
		local colourCoded = explodeSourceName and ("From "..colorCodes[explodeSource.rarity or "NORMAL"]..explodeSourceName)
		t_insert(controls.mainSkill.list, { val = i, label = colourCoded or activeSkill.activeEffect.grantedEffect.name })
	end
	controls.mainSkill.enabled = #displaySkillList > 1
	controls.mainSkill.selIndex = mainActiveSkill
	controls.mainSkill.shown = true
	hideAllSkillControls()
	controls.mainSkill.shown = true -- restore after hideAll

	local activeSkill = displaySkillList[mainActiveSkill] or displaySkillList[1]
	if not activeSkill then return end
	local activeEffect = activeSkill.activeEffect
	if not activeEffect then return end

	-- Skill parts
	if activeEffect.grantedEffect.parts and #activeEffect.grantedEffect.parts > 1 then
		controls.mainSkillPart.shown = true
		wipeTable(controls.mainSkillPart.list)
		for i, part in ipairs(activeEffect.grantedEffect.parts) do
			t_insert(controls.mainSkillPart.list, { val = i, label = part.name })
		end
		controls.mainSkillPart.selIndex = activeEffect.srcInstance["skillPart"..suffix] or 1
		local selectedPart = activeEffect.grantedEffect.parts[controls.mainSkillPart.selIndex]
		if selectedPart and selectedPart.stages then
			controls.mainSkillStageCount.shown = true
			controls.mainSkillStageCount.buf = tostring(activeEffect.srcInstance["skillStageCount"..suffix] or selectedPart.stagesMin or 1)
		end
	end

	-- Mine count
	if activeSkill.skillFlags and activeSkill.skillFlags.mine then
		controls.mainSkillMineCount.shown = true
		controls.mainSkillMineCount.buf = tostring(activeEffect.srcInstance["skillMineCount"..suffix] or "")
	end

	-- Stage count (for multi-stage skills without parts)
	if activeSkill.skillFlags and activeSkill.skillFlags.multiStage and not (activeEffect.grantedEffect.parts and #activeEffect.grantedEffect.parts > 1) then
		controls.mainSkillStageCount.shown = true
		controls.mainSkillStageCount.buf = tostring(activeEffect.srcInstance["skillStageCount"..suffix] or activeSkill.skillData.stagesMin or 1)
	end

	-- Minion controls
	if activeSkill.skillFlags and not activeSkill.skillFlags.disable and (activeEffect.grantedEffect.minionList or (activeSkill.minionList and activeSkill.minionList[1])) then
		self:RefreshMinionControls(controls, activeSkill, activeEffect, suffix)
	end
end

function CompareEntryClass:RefreshMinionControls(controls, activeSkill, activeEffect, suffix)
	wipeTable(controls.mainSkillMinion.list)
	if activeEffect.grantedEffect.minionHasItemSet then
		for _, itemSetId in ipairs(self.itemsTab.itemSetOrderList) do
			local itemSet = self.itemsTab.itemSets[itemSetId]
			t_insert(controls.mainSkillMinion.list, {
				label = itemSet.title or "Default Item Set",
				itemSetId = itemSetId,
			})
		end
		controls.mainSkillMinion:SelByValue(activeEffect.srcInstance["skillMinionItemSet"..suffix] or 1, "itemSetId")
	else
		for _, minionId in ipairs(activeSkill.minionList) do
			t_insert(controls.mainSkillMinion.list, {
				label = self.data.minions[minionId] and self.data.minions[minionId].name or minionId,
				minionId = minionId,
			})
		end
		controls.mainSkillMinion:SelByValue(activeEffect.srcInstance["skillMinion"..suffix] or (controls.mainSkillMinion.list[1] and controls.mainSkillMinion.list[1].minionId), "minionId")
	end
	controls.mainSkillMinion.enabled = #controls.mainSkillMinion.list > 1
	controls.mainSkillMinion.shown = true

	wipeTable(controls.mainSkillMinionSkill.list)
	if activeSkill.minion then
		for _, minionSkill in ipairs(activeSkill.minion.activeSkillList) do
			t_insert(controls.mainSkillMinionSkill.list, minionSkill.activeEffect.grantedEffect.name)
		end
		controls.mainSkillMinionSkill.selIndex = activeEffect.srcInstance["skillMinionSkill"..suffix] or 1
		controls.mainSkillMinionSkill.shown = true
		controls.mainSkillMinionSkill.enabled = #controls.mainSkillMinionSkill.list > 1
	else
		t_insert(controls.mainSkillMinion.list, "<No spectres in build>")
	end
end

function CompareEntryClass:UpdateClassDropdowns()
	-- No class dropdowns in comparison entry
end

function CompareEntryClass:SyncLoadouts()
	-- No loadout syncing in comparison entry
end

function CompareEntryClass:OpenSpectreLibrary()
	-- No spectre library in comparison entry
end

function CompareEntryClass:AddStatComparesToTooltip(tooltip, baseOutput, compareOutput, header, nodeCount)
	-- Reuse the stat comparison logic
	local count = 0
	if self.calcsTab and self.calcsTab.mainEnv and self.calcsTab.mainEnv.player and self.calcsTab.mainEnv.player.mainSkill then
		if self.calcsTab.mainEnv.player.mainSkill.minion and baseOutput.Minion and compareOutput.Minion then
			count = count + self:CompareStatList(tooltip, self.minionDisplayStats, self.calcsTab.mainEnv.minion, baseOutput.Minion, compareOutput.Minion, header.."\n^7Minion:", nodeCount)
			if count > 0 then
				header = "^7Player:"
			else
				header = header.."\n^7Player:"
			end
		end
		count = count + self:CompareStatList(tooltip, self.displayStats, self.calcsTab.mainEnv.player, baseOutput, compareOutput, header, nodeCount)
	end
	return count
end

-- Stat comparison
function CompareEntryClass:CompareStatList(tooltip, statList, actor, baseOutput, compareOutput, header, nodeCount)
	local s_format = string.format
	local count = 0
	if not actor or not actor.mainSkill then
		return 0
	end
	for _, statData in ipairs(statList) do
		if statData.stat and not statData.childStat and statData.stat ~= "SkillDPS" then
			local flagMatch = true
			if statData.flag then
				if type(statData.flag) == "string" then
					flagMatch = actor.mainSkill.skillFlags[statData.flag]
				elseif type(statData.flag) == "table" then
					for _, flag in ipairs(statData.flag) do
						if not actor.mainSkill.skillFlags[flag] then
							flagMatch = false
							break
						end
					end
				end
			end
			if statData.notFlag then
				if type(statData.notFlag) == "string" then
					if actor.mainSkill.skillFlags[statData.notFlag] then
						flagMatch = false
					end
				elseif type(statData.notFlag) == "table" then
					for _, flag in ipairs(statData.notFlag) do
						if actor.mainSkill.skillFlags[flag] then
							flagMatch = false
							break
						end
					end
				end
			end
			if flagMatch then
				local statVal1 = compareOutput[statData.stat] or 0
				local statVal2 = baseOutput[statData.stat] or 0
				local diff = statVal1 - statVal2
				if statData.stat == "FullDPS" and not compareOutput[statData.stat] then
					diff = 0
				end
				if (diff > 0.001 or diff < -0.001) and (not statData.condFunc or statData.condFunc(statVal1, compareOutput) or statData.condFunc(statVal2, baseOutput)) then
					if count == 0 then
						tooltip:AddLine(14, header)
					end
					local color = ((statData.lowerIsBetter and diff < 0) or (not statData.lowerIsBetter and diff > 0)) and colorCodes.POSITIVE or colorCodes.NEGATIVE
					local val = diff * ((statData.pc or statData.mod) and 100 or 1)
					local valStr = s_format("%+"..statData.fmt, val)
					local number, suffix = valStr:match("^([%+%-]?%d+%.%d+)(%D*)$")
					if number then
						valStr = number:gsub("0+$", ""):gsub("%.$", "") .. suffix
					end
					valStr = formatNumSep(valStr)
					local line = s_format("%s%s %s", color, valStr, statData.label)
					if statData.compPercent and statVal1 ~= 0 and statVal2 ~= 0 then
						local pc = statVal1 / statVal2 * 100 - 100
						line = line .. s_format(" (%+.1f%%)", pc)
					end
					tooltip:AddLine(14, line)
					count = count + 1
				end
			end
		end
	end
	return count
end

-- Add requirements to tooltip
do
	local req = { }
	function CompareEntryClass:AddRequirementsToTooltip(tooltip, level, str, dex, int, strBase, dexBase, intBase)
		if level and level > 0 then
			t_insert(req, s_format("^x7F7F7FLevel %s%d", main:StatColor(level, nil, self.characterLevel), level))
		end
		if self.calcsTab.mainEnv.modDB:Flag(nil, "OmniscienceRequirements") then
			local omniSatisfy = self.calcsTab.mainEnv.modDB:Sum("INC", nil, "OmniAttributeRequirements")
			local highestAttribute = 0
			for i, stat in ipairs({str, dex, int}) do
				if((stat or 0) > highestAttribute) then
					highestAttribute = stat
				end
			end
			local omni = math.floor(highestAttribute * (100/omniSatisfy))
			if omni and (omni > 0 or omni > self.calcsTab.mainOutput.Omni) then
				t_insert(req, s_format("%s%d ^x7F7F7FOmni", main:StatColor(omni, 0, self.calcsTab.mainOutput.Omni), omni))
			end
		else
			if str and (str > 14 or str > self.calcsTab.mainOutput.Str) then
				t_insert(req, s_format("%s%d ^x7F7F7FStr", main:StatColor(str, strBase, self.calcsTab.mainOutput.Str), str))
			end
			if dex and (dex > 14 or dex > self.calcsTab.mainOutput.Dex) then
				t_insert(req, s_format("%s%d ^x7F7F7FDex", main:StatColor(dex, dexBase, self.calcsTab.mainOutput.Dex), dex))
			end
			if int and (int > 14 or int > self.calcsTab.mainOutput.Int) then
				t_insert(req, s_format("%s%d ^x7F7F7FInt", main:StatColor(int, intBase, self.calcsTab.mainOutput.Int), int))
			end
		end
		if req[1] then
			local fontSizeBig = main.showFlavourText and 18 or 16
			tooltip:AddLine(fontSizeBig, "^x7F7F7FRequires "..table.concat(req, "^x7F7F7F, "), "FONTIN SC")
			tooltip:AddSeparator(10)
		end
		wipeTable(req)
	end
end

return CompareEntryClass
