-- Path of Building
--
-- Module: Compare Entry
-- Lightweight Build wrapper for comparison. Loads XML, creates tabs, and runs calculations
-- without setting up the full UI chrome of the primary build.
--
local t_insert = table.insert
local m_min = math.min
local m_max = math.max

local CompareEntryClass = newClass("CompareEntry", "ControlHost", function(self, xmlText, label)
	self.ControlHost()

	self.label = label or "Comparison Build"
	self.buildName = label or "Comparison Build"
	self.xmlText = xmlText

	-- Default build properties (mirrors Build.lua:Init lines 72-82)
	self.viewMode = "TREE"
	self.characterLevel = m_min(m_max(main.defaultCharLevel or 1, 1), 100)
	self.targetVersion = liveTargetVersion
	self.bandit = "None"
	self.pantheonMajorGod = "None"
	self.pantheonMinorGod = "None"
	self.characterLevelAutoMode = main.defaultCharLevel == 1 or main.defaultCharLevel == nil
	self.mainSocketGroup = 1

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
	self.modFlag = false
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
	-- Parse the XML (same pattern as Build.lua:LoadDB, line 1834)
	local dbXML, errMsg = common.xml.ParseXML(xmlText)
	if errMsg then
		ConPrintf("CompareEntry: Error parsing XML: %s", errMsg)
		return true
	end
	if not dbXML or not dbXML[1] or dbXML[1].elem ~= "PathOfBuilding" then
		ConPrintf("CompareEntry: 'PathOfBuilding' root element missing")
		return true
	end

	-- Load Build section first (same pattern as Build.lua:LoadDB, line 1848)
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

	-- Create tabs (same pattern as Build.lua lines 579-590)
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

	-- Set up savers table (same pattern as Build.lua lines 593-606)
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

	-- Load XML sections into tabs (same pattern as Build.lua lines 620-647)
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

	if next(self.configTab.input) == nil then
		if self.configTab.ImportCalcSettings then
			self.configTab:ImportCalcSettings()
		end
	end

	-- Build calculation output tables (same pattern as Build.lua lines 654-657)
	self.calcsTab:BuildOutput()
	self.buildFlag = false
end

-- Load build section attributes (same pattern as Build.lua:Load, line 927)
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

function CompareEntryClass:RefreshSkillSelectControls()
	-- No skill select controls in comparison entry
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

-- Stat comparison (mirrors Build.lua:CompareStatList, line 1733)
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

return CompareEntryClass
