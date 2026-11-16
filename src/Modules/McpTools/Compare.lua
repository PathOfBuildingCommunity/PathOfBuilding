-- Path of Building
--
-- Module: MCP Tools - Compare
-- The Compare tab (comparison builds, their differences, the compare power
-- report, buy similar and the copy buttons), the Party tab, and character
-- import through Path of Building's own Path of Exile login.
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat
local t_sort = table.sort
local s_format = string.format
local m_max = math.max

local tradeHelpers = require("Classes.TradeHelpers")
local buySimilar = require("Classes.CompareBuySimilar")
local configVisibility = require("Modules.ConfigVisibility")

-- The views of the Compare tab a report can include.
local REPORT_SECTIONS = { "stats", "tree", "items", "skills", "config", "calcs" }
local DEFAULT_REPORT_SECTIONS = { "stats", "tree", "items", "skills", "config" }
-- The slots of the Compare tab's Items view (CompareTab:DrawItems).
local ITEM_BASE_SLOTS = { "Weapon 1", "Weapon 2", "Weapon 1 Swap", "Weapon 2 Swap", "Helmet", "Body Armour", "Gloves",
	"Boots", "Amulet", "Ring 1", "Ring 2", "Belt", "Flask 1", "Flask 2", "Flask 3", "Flask 4", "Flask 5" }
-- Config option types the Compare tab's Config view shows (makeConfigControl in CompareTab).
local CONFIG_VIEW_TYPES = { check = true, count = true, integer = true, countAllowZero = true, float = true, list = true }
-- The power report's sortable columns (ComparePowerReportListControl:ReSort).
local POWER_SORT_COLUMNS = { category = 1, impact = 3, points = 4, per_point = 5 }
local POWER_CATEGORIES = { tree = "treeNodes", items = "items", skill_gems = "skillGems", support_gems = "supportGems", config = "config" }
-- The Buy Similar popup's realm and listed-status dropdowns (CompareBuySimilar).
local BUY_REALMS = { pc = "PC", sony = "PS4", xbox = "Xbox" }
local BUY_LISTED = { securable = 1, available = 2, online = 3, any = 4 }

-- A path below the builds folder, refusing anything that could leave it.
local function buildFolderFile(relative)
	relative = relative:gsub("\\", "/"):gsub("^/+", "")
	if relative:match("%.%.") or relative:match(":") then
		T.Fail("path must be a build file inside the builds folder, without '..' or a drive")
	end
	if not relative:lower():match("%.xml$") then
		relative = relative .. ".xml"
	end
	return relative
end

local function findLinkSite(link)
	local site = T.FindBuildSite(link)
	if not site then
		local labels = { }
		for _, entry in ipairs(buildSites.websiteList) do
			t_insert(labels, entry.label)
		end
		T.Fail("Path of Building does not recognise that link. Supported sites: %s.", t_concat(labels, ", "))
	end
	return site
end

-- PoB reads build files in text mode, so on Windows the CRLF of its own saves
-- reaches it as LF; text handed over directly gets the same conversion.
local function normaliseNewlines(text)
	return (text:gsub("\r\n", "\n"))
end

local function socketGroupLabel(group, index)
	local label = group.displayLabel or group.label
	if not label or not label:match("%S") then
		label = "Group " .. index
	end
	if group.slot then
		label = label .. " (" .. group.slot .. ")"
	end
	return T.Clean(label)
end

-- The skill the build (or comparison) is calculated for.
local function mainSkillName(calcsTab)
	local env = calcsTab and calcsTab.mainEnv
	local skill = env and env.player and env.player.mainSkill
	if not skill or not skill.activeEffect then
		return nil
	end
	return skill.activeEffect.grantedEffect.name .. (skill.skillPartName and (" (" .. skill.skillPartName .. ")") or "")
end

local function setTitles(orderList, sets, activeId)
	local list = { }
	for index, id in ipairs(orderList or { }) do
		local set = sets and sets[id]
		t_insert(list, { index = index, title = T.Clean(set and set.title or "Default"), active = id == activeId or nil })
	end
	return T.Array(list)
end

------------------------------------------------------------------------------
-- Compare tab
------------------------------------------------------------------------------

local function entryInfo(ct, entry, index)
	local spec = entry.spec
	local out = entry:GetOutput() or { }
	local treeSets = { }
	for i, title in ipairs(entry.treeTab:GetSpecList()) do
		t_insert(treeSets, { index = i, title = T.Clean(title), active = i == entry.treeTab.activeSpec or nil })
	end
	local groups = { }
	for i, group in ipairs(entry.skillsTab.socketGroupList) do
		t_insert(groups, { index = i, label = socketGroupLabel(group, i), enabled = group.enabled ~= false, main = i == entry.mainSocketGroup or nil })
	end
	local used, ascUsed = spec:CountAllocNodes()
	return {
		index = index,
		label = T.Clean(entry.label),
		active = index == ct.activeCompareIndex,
		class = spec.curClassName,
		ascendancy = spec.curAscendClassId ~= 0 and spec.curAscendClassName or nil,
		level = entry.characterLevel,
		passivePointsUsed = used,
		ascendancyPointsUsed = ascUsed,
		mainSkill = mainSkillName(entry.calcsTab),
		treeSets = T.Array(treeSets),
		itemSets = setTitles(entry.itemsTab.itemSetOrderList, entry.itemsTab.itemSets, entry.itemsTab.activeItemSetId),
		skillSets = setTitles(entry.skillsTab.skillSetOrderList, entry.skillsTab.skillSets, entry.skillsTab.activeSkillSetId),
		configSets = setTitles(entry.configTab.configSetOrderList, entry.configTab.configSets, entry.configTab.activeConfigSetId),
		socketGroups = T.Array(groups),
		stats = {
			Life = T.Round(out.Life), EnergyShield = T.Round(out.EnergyShield), Mana = T.Round(out.Mana), TotalEHP = T.Round(out.TotalEHP),
			CombinedDPS = T.Round(out.CombinedDPS), FullDPS = T.Round(out.FullDPS),
		},
	}
end

-- A comparison by its number (default: the one the tab shows), recalculated if flagged.
local function compareEntryAt(build, index)
	local ct = build.compareTab
	if not ct.compareEntries[1] then
		T.Fail("No comparison build is loaded; add one with compare_builds action 'add'.")
	end
	index = index or ct.activeCompareIndex
	local entry = ct.compareEntries[index]
	if not entry then
		T.Fail("There is no comparison %d; they are numbered 1 to %d (see action 'list').", index, #ct.compareEntries)
	end
	-- CompareTab:Draw rebuilds a flagged comparison before using it.
	if entry.buildFlag then
		entry:Rebuild()
	end
	return entry, index
end

-- CompareTab:ImportBuild, as its Import and Import from Folder popups call it.
local function addComparison(build, xml, label)
	local ct = build.compareTab
	local before = #ct.compareEntries
	local ok, imported = pcall(ct.ImportBuild, ct, normaliseNewlines(xml), (T.Sanitise(label)))
	if not ok then
		T.Fail("Path of Building could not load that build for comparison: %s", tostring(imported))
	end
	if not imported or #ct.compareEntries == before then
		T.Fail("Path of Building could not load that build for comparison; check that it is a valid Path of Building build.")
	end
	return { added = entryInfo(ct, ct.compareEntries[#ct.compareEntries], #ct.compareEntries), count = #ct.compareEntries }
end

-- Summary view: CompareTab:DrawSummary and DrawStatList.
local function compareStats(build, entry, onlyDifferences)
	local ct = build.compareTab
	local matchFlags = ct.matchFlags
	local primaryCalcs, compareCalcs = build.calcsTab, entry.calcsTab
	local pEnv, cEnv = primaryCalcs.mainEnv, compareCalcs.mainEnv
	local pMinion = pEnv and pEnv.player and pEnv.player.mainSkill and pEnv.player.mainSkill.minion and pEnv.minion
	local cMinion = cEnv and cEnv.player and cEnv.player.mainSkill and cEnv.player.mainSkill.minion and cEnv.minion
	local pOut = pMinion and pEnv.minion.output or primaryCalcs.mainOutput
	local cOut = cMinion and cEnv.minion.output or entry:GetOutput()
	if not pOut or not cOut then
		T.Fail("One of the builds has no calculated output.")
	end
	local displayStats = (pMinion or cMinion) and build.minionDisplayStats or build.displayStats
	local pActor = pMinion and pEnv.minion or pEnv.player
	local cActor = cMinion and cEnv.minion or cEnv.player
	local pFlags = pActor and pActor.mainSkill and pActor.mainSkill.skillFlags or { }
	local cFlags = cActor and cActor.mainSkill and cActor.mainSkill.skillFlags or { }
	local rows = { }
	for _, statData in ipairs(displayStats) do
		if (not statData.stat and not statData.label) or statData.stat == "SkillDPS" or statData.hideStat then
			-- Spacers, the multi-row SkillDPS and hidden stats are not listed.
		elseif not matchFlags(statData.flag, statData.notFlag, pFlags) and not matchFlags(statData.flag, statData.notFlag, cFlags) then
			-- Not relevant to either build's skill.
		elseif statData.stat then
			local pVal = pOut[statData.stat] or 0
			local cVal = cOut[statData.stat] or 0
			if statData.childStat then
				pVal = type(pVal) == "table" and pVal[statData.childStat] or 0
				cVal = type(cVal) == "table" and cVal[statData.childStat] or 0
			end
			if type(pVal) == "table" or type(cVal) == "table" then
				pVal, cVal = 0, 0
			end
			if (pVal ~= 0 or cVal ~= 0) and (not statData.condFunc or statData.condFunc(pVal, pOut) or statData.condFunc(cVal, cOut)) then
				local fmt = statData.fmt or "d"
				local multiplier = (statData.pc or statData.mod) and 100 or 1
				local diff = cVal - pVal
				local differs = diff > 0.001 or diff < -0.001
				if differs or not onlyDifferences then
					local row = {
						label = T.Clean(statData.label or statData.stat),
						stat = statData.stat,
						primary = formatNumSep(s_format("%" .. fmt, pVal * multiplier)),
						compare = formatNumSep(s_format("%" .. fmt, cVal * multiplier)),
					}
					if differs then
						row.difference = formatNumSep(s_format("%+" .. fmt, diff * multiplier))
						if pVal ~= 0 then
							row.difference = row.difference .. s_format(" (%+.1f%%)", cVal / pVal * 100 - 100)
						end
						row.compareIsBetter = (statData.lowerIsBetter and diff < 0) or (not statData.lowerIsBetter and diff > 0)
					end
					t_insert(rows, row)
				end
			end
		elseif statData.label and statData.condFunc then
			local pShown = statData.condFunc(pOut) and true or false
			local cShown = statData.condFunc(cOut) and true or false
			if (pShown or cShown) and (pShown ~= cShown or not onlyDifferences) then
				t_insert(rows, {
					label = T.Clean(statData.label),
					primary = pShown and (statData.val or "") or "-",
					compare = cShown and (statData.val or "") or "-",
				})
			end
		end
	end
	return { minionStats = (pMinion or cMinion) and true or false, rows = T.Array(rows) }
end

local function capped(list, limit, sortFunc)
	if sortFunc then
		t_sort(list, sortFunc)
	end
	local out = { }
	for i = 1, math.min(#list, limit) do
		out[i] = list[i]
	end
	return T.Array(out), #list
end

-- Tree view, overlay mode: the tab hands the comparison's spec to the open
-- build's tree view as compareSpec; PassiveTreeView:GetCompareNodeColor colours
-- nodes green (compared build only), red (open build only) or blue (both, but
-- a different mastery choice or jewel).
local function compareTree(build, entry, limit)
	local spec, cSpec = build.spec, entry.spec
	local viewer = build.treeTab.viewer
	local function jewelName(jewel)
		return jewel and T.Clean(jewel.title or jewel.name) or nil
	end
	local function nodeInfo(node, cNode)
		local info = { id = node.id, name = node.dn, type = node.type, ascendancy = node.ascendancyName }
		if node.type == "Mastery" then
			info.primaryEffect = node.alloc and T.Clean(t_concat(node.sd or { }, " / ")) or nil
			info.compareEffect = cNode and cNode.alloc and T.Clean(t_concat(cNode.sd or { }, " / ")) or nil
		elseif node.type == "Socket" then
			local pJewelId = spec.jewels[node.id]
			info.primaryJewel = jewelName(pJewelId and build.itemsTab.items[pJewelId])
			info.compareJewel = jewelName(viewer:GetCompareJewel(node.id))
		end
		return info
	end
	local compareOnly, primaryOnly, differs = { }, { }, { }
	local shared = 0
	local savedCompareSpec = viewer.compareSpec
	viewer.compareSpec = cSpec
	local ok, err = pcall(function()
		for nodeId, node in pairs(spec.nodes) do
			local cNode = cSpec.nodes[nodeId]
			local r, g, b = viewer:GetCompareNodeColor(node, cNode, spec, build, "same")
			if r == 0 and g == 1 and b == 0 then
				t_insert(compareOnly, nodeInfo(node, cNode))
			elseif r == 1 and g == 0 and b == 0 then
				t_insert(primaryOnly, nodeInfo(node, cNode))
			elseif r == 0 and g == 0 and b == 1 then
				t_insert(differs, nodeInfo(node, cNode))
			elseif node.alloc then
				shared = shared + 1
			end
		end
		-- Nodes only the compared build has (its cluster jewel subgraphs), drawn green by the tree view.
		for nodeId, cNode in pairs(cSpec.nodes) do
			if not spec.nodes[nodeId] and cNode.alloc and cNode.type ~= "ClassStart" and cNode.type ~= "AscendClassStart" then
				t_insert(compareOnly, { id = nodeId, name = cNode.dn, type = cNode.type, clusterJewelNode = true })
			end
		end
	end)
	viewer.compareSpec = savedCompareSpec
	if not ok then
		error(err, 0)
	end
	local byName = function(a, b)
		return tostring(a.name) < tostring(b.name)
	end
	local result = { sharedAllocated = shared }
	result.compareOnly, result.compareOnlyCount = capped(compareOnly, limit, byName)
	result.primaryOnly, result.primaryOnlyCount = capped(primaryOnly, limit, byName)
	result.differs, result.differsCount = capped(differs, limit, byName)
	for key, s in pairs({ primary = spec, compare = cSpec }) do
		local used, ascUsed = s:CountAllocNodes()
		result[key] = {
			treeSet = T.Clean(s.title or "Default"), class = s.curClassName,
			ascendancy = s.curAscendClassId ~= 0 and s.curAscendClassName or nil,
			passivePointsUsed = used, ascendancyPointsUsed = ascUsed,
		}
	end
	return result
end

local function itemSummary(item)
	if not item then
		return nil
	end
	return { name = T.Clean(item.name), rarity = item.rarity }
end

-- Mod lines with the Items view's expanded-mode markers (CompareTab:DrawItemExpanded):
-- '+' only on this side, '>' / '<' the same mod with a higher / lower value.
local function itemModLines(item, otherModMap)
	local lines = { }
	if not item then
		return lines
	end
	for _, modList in ipairs({ item.enchantModLines or { }, item.scourgeModLines or { }, item.implicitModLines or { }, item.explicitModLines or { }, item.crucibleModLines or { } }) do
		for _, modLine in ipairs(modList) do
			if item:CheckModLineVariant(modLine) then
				local formatted = itemLib.formatModLine(modLine)
				if formatted then
					local marker
					local other = otherModMap[tradeHelpers.modLineTemplate(modLine.line)]
					if not other then
						marker = "+"
					elseif other.line ~= modLine.line then
						local mine = tradeHelpers.modLineValue(modLine.line)
						if mine and other.value and mine > other.value then
							marker = ">"
						elseif mine and other.value and mine < other.value then
							marker = "<"
						end
					end
					t_insert(lines, (marker and (marker .. " ") or "") .. T.Clean(formatted))
				end
			end
		end
	end
	return T.Array(lines)
end

-- The Equip button's hover tooltip in the Items view: the open build's stat
-- changes with the compared item in that slot.
local function equipStatChanges(build, slotName, item)
	local calcFunc, calcBase = build.compareTab.calcs.getMiscCalculator(build)
	local newItem = new("Item"):Item(item.raw)
	newItem:NormaliseQuality()
	local override = { repSlotName = slotName, repItem = newItem }
	local pSlot = build.itemsTab.slots[slotName]
	if pSlot and pSlot.nodeId and not build.spec.allocNodes[pSlot.nodeId] then
		local node = build.spec.nodes[pSlot.nodeId]
		if node then
			override.addNodes = { [node] = true }
		end
	end
	local collector = T.LineCollector()
	build:AddStatComparesToTooltip(collector, calcBase, calcFunc(override), "")
	return T.Array(collector.lines)
end

-- Items view: CompareTab:DrawItems (gear slots, then jewel sockets).
local function compareItems(build, entry, onlyDifferences, expanded, statChanges)
	local ct = build.compareTab
	local baseSlots = { }
	for _, slotName in ipairs(ITEM_BASE_SLOTS) do
		t_insert(baseSlots, slotName)
	end
	if ct:ShouldShowRing3(entry) then
		t_insert(baseSlots, 10, "Ring 3")
	end
	ct:AddAbyssSockets(entry, baseSlots, false)
	local pEnv = build.calcsTab.mainEnv
	local primaryHasRing3 = pEnv and pEnv.modDB:Flag(nil, "AdditionalRingSlot")
	local pTab, cTab = build.itemsTab, entry.itemsTab
	local function row(label, slotName, pItem, cItem, extra)
		-- PoB's label calls items with the same name a match; whether they are
		-- identical is decided on the full item text, as the tree view compares jewels.
		local identical = (not pItem and not cItem) or (pItem and cItem and pItem:BuildRaw() == cItem:BuildRaw()) or false
		if onlyDifferences and identical then
			return
		end
		local r = {
			slot = label,
			status = T.Clean(tradeHelpers.getSlotDiffLabel(pItem, cItem)):gsub("^%((.*)%)$", "%1"),
			identical = identical,
			primary = itemSummary(pItem),
			compare = itemSummary(cItem),
		}
		for k, v in pairs(extra or { }) do
			r[k] = v
		end
		if expanded then
			r.primaryMods = itemModLines(pItem, tradeHelpers.buildModMap(cItem))
			r.compareMods = itemModLines(cItem, tradeHelpers.buildModMap(pItem))
		end
		-- No Equip button (and so no tooltip) where the open build lacks the slot.
		if statChanges and cItem and cItem.raw and not identical and not r.missingSlotInPrimary then
			r.equipStatChanges = equipStatChanges(build, slotName, cItem)
		end
		return r
	end
	local slots = { }
	for _, slotName in ipairs(baseSlots) do
		local pSlot, cSlot = pTab.slots[slotName], cTab.slots[slotName]
		local pItem = pSlot and pTab.items[pSlot.selItemId]
		local cItem = cSlot and cTab.items[cSlot.selItemId]
		local r = row(slotName, slotName, pItem, cItem, { missingSlotInPrimary = (slotName == "Ring 3" and not primaryHasRing3) or nil })
		if r then
			t_insert(slots, r)
		end
	end
	local jewels = { }
	for _, jEntry in ipairs(ct:GetJewelComparisonSlots(entry)) do
		local r = row(T.Clean(jEntry.label), jEntry.pSlotName, jEntry.pItem, jEntry.cItem, {
			socketNodeId = jEntry.nodeId,
			primarySocketAllocated = jEntry.pNodeAllocated,
			compareSocketAllocated = jEntry.cNodeAllocated,
		})
		if r then
			t_insert(jewels, r)
		end
	end
	local function activeSet(tab)
		local set = tab.itemSets[tab.activeItemSetId]
		return T.Clean(set and set.title or "Default")
	end
	return { primaryItemSet = activeSet(pTab), compareItemSet = activeSet(cTab), slots = T.Array(slots), jewels = T.Array(jewels) }
end

-- Skills view: CompareTab:DrawSkills. Socket groups are paired greedily by
-- the similarity of their gem names; within a pair common gems come first,
-- then gems only on that side ("additional"), then gems only on the other side
-- ("missing"). Imbued supports count as gems of their group.
local function compareSkills(build, entry, onlyDifferences)
	local pSkillsTab, cSkillsTab = build.skillsTab, entry.skillsTab
	local pGroups, cGroups = pSkillsTab.socketGroupList, cSkillsTab.socketGroupList
	local imbuedCache = { }
	local function imbuedGem(group, skillsTab)
		if not group or not group.imbuedSupport then
			return nil
		end
		if not imbuedCache[group] then
			local grantedEffect = skillsTab.imbuedSupportBySlot and group.slot and skillsTab.imbuedSupportBySlot[group.slot]
			if not grantedEffect then
				local gemId = data.gemForBaseName and data.gemForBaseName[group.imbuedSupport:lower() .. " support"]
				grantedEffect = gemId and data.gems[gemId] and data.gems[gemId].grantedEffect or nil
			end
			imbuedCache[group] = { grantedEffect = grantedEffect, nameSpec = group.imbuedSupport, level = 1, quality = 0, isImbuedSupport = true }
		end
		return imbuedCache[group]
	end
	local function gemName(gem)
		return gem.grantedEffect and gem.grantedEffect.name or gem.nameSpec
	end
	local function gemsOf(group, skillsTab)
		local gems = { }
		if group then
			for _, gem in ipairs(group.gemList or { }) do
				t_insert(gems, gem)
			end
			t_insert(gems, imbuedGem(group, skillsTab))
		end
		return gems
	end
	local function nameSet(group, skillsTab)
		local set = { }
		for _, gem in ipairs(gemsOf(group, skillsTab)) do
			if gemName(gem) then
				set[gemName(gem)] = true
			end
		end
		return set
	end
	local pSets, cSets = { }, { }
	for i, group in ipairs(pGroups) do
		pSets[i] = nameSet(group, pSkillsTab)
	end
	for i, group in ipairs(cGroups) do
		cSets[i] = nameSet(group, cSkillsTab)
	end
	local scored = { }
	for pi = 1, #pGroups do
		for ci = 1, #cGroups do
			local inter, union, keys = 0, 0, { }
			for k in pairs(pSets[pi]) do keys[k] = true end
			for k in pairs(cSets[ci]) do keys[k] = true end
			for k in pairs(keys) do
				union = union + 1
				if pSets[pi][k] and cSets[ci][k] then
					inter = inter + 1
				end
			end
			if union > 0 and inter > 0 then
				t_insert(scored, { pIdx = pi, cIdx = ci, score = inter / union })
			end
		end
	end
	t_sort(scored, function(a, b) return a.score > b.score end)
	local pMatched, cMatched, pairList = { }, { }, { }
	for _, pair in ipairs(scored) do
		if not pMatched[pair.pIdx] and not cMatched[pair.cIdx] then
			t_insert(pairList, pair)
			pMatched[pair.pIdx], cMatched[pair.cIdx] = true, true
		end
	end
	for i = 1, #pGroups do
		if not pMatched[i] then t_insert(pairList, { pIdx = i }) end
	end
	for i = 1, #cGroups do
		if not cMatched[i] then t_insert(pairList, { cIdx = i }) end
	end

	local function gemEntry(gem, name, status)
		local e = { name = name, status = status }
		if gem then
			e.level, e.quality = gem.level, gem.quality
			e.enabled = gem.enabled ~= false
			e.imbued = gem.isImbuedSupport or nil
		end
		return e
	end
	local out = { }
	for _, pair in ipairs(pairList) do
		local pGroup, cGroup = pair.pIdx and pGroups[pair.pIdx], pair.cIdx and cGroups[pair.cIdx]
		local pSet, cSet = pair.pIdx and pSets[pair.pIdx] or { }, pair.cIdx and cSets[pair.cIdx] or { }
		local pGems, cGems = gemsOf(pGroup, pSkillsTab), gemsOf(cGroup, cSkillsTab)
		local pList, cList = { }, { }
		local cByName, emitted = { }, { }
		for _, gem in ipairs(cGems) do
			local name = gemName(gem)
			if name and pSet[name] and not cByName[name] then
				cByName[name] = gem
			end
		end
		for _, gem in ipairs(pGems) do
			local name = gemName(gem)
			if name and cSet[name] and not emitted[name] then
				emitted[name] = true
				t_insert(pList, gemEntry(gem, name, "common"))
				t_insert(cList, gemEntry(cByName[name], name, "common"))
			end
		end
		for _, gem in ipairs(pGems) do
			if gemName(gem) and not cSet[gemName(gem)] then t_insert(pList, gemEntry(gem, gemName(gem), "additional")) end
		end
		for _, gem in ipairs(cGems) do
			if gemName(gem) and not pSet[gemName(gem)] then t_insert(cList, gemEntry(gem, gemName(gem), "additional")) end
		end
		if pGroup and cGroup then
			local pMissing, cMissing = { }, { }
			for name in pairs(cSet) do if not pSet[name] then t_insert(pMissing, name) end end
			for name in pairs(pSet) do if not cSet[name] then t_insert(cMissing, name) end end
			t_sort(pMissing)
			t_sort(cMissing)
			for _, name in ipairs(pMissing) do t_insert(pList, gemEntry(nil, name, "missing")) end
			for _, name in ipairs(cMissing) do t_insert(cList, gemEntry(nil, name, "missing")) end
		end
		-- A pair differs when the view would show something different in its columns.
		local differs = not pGroup or not cGroup
		for i, e in ipairs(pList) do
			local c = cList[i]
			if e.status ~= "common" or not c or c.level ~= e.level or c.quality ~= e.quality then
				differs = true
			end
		end
		for _, e in ipairs(cList) do
			if e.status ~= "common" then differs = true end
		end
		if differs or not onlyDifferences then
			t_insert(out, {
				primaryGroup = pGroup and { index = pair.pIdx, label = socketGroupLabel(pGroup, pair.pIdx), enabled = pGroup.enabled ~= false, main = pair.pIdx == build.mainSocketGroup or nil } or nil,
				compareGroup = cGroup and { index = pair.cIdx, label = socketGroupLabel(cGroup, pair.cIdx), enabled = cGroup.enabled ~= false, main = pair.cIdx == entry.mainSocketGroup or nil } or nil,
				primaryGems = T.Array(pList),
				compareGems = T.Array(cList),
				differs = differs,
			})
		end
	end
	local function activeSet(tab)
		local set = tab.skillSets[tab.activeSkillSetId]
		return T.Clean(set and set.title or "Default")
	end
	return { primarySkillSet = activeSet(pSkillsTab), compareSkillSet = activeSet(cSkillsTab), groups = T.Array(out) }
end

-- Config view: the sections of CompareTab:RebuildConfigControls and the rows
-- LayoutConfigView lists (differences first; equal options only when relevant
-- to either build, or all but the excluded ones with show_all).
local function compareConfig(build, entry, onlyDifferences, showAll)
	local ct = build.compareTab
	local pInput, cInput = build.configTab.input, entry.configTab.input
	local sections, current = { }, nil
	local total = 0
	for _, varData in ipairs(ct.configOptions) do
		if varData.section then
			if varData.section ~= "Custom Modifiers" and varData.section ~= "Map Modifiers and Player Debuffs" then
				current = { name = varData.section, diffs = { }, commons = { } }
				t_insert(sections, current)
			else
				current = nil
			end
		elseif current and varData.var and CONFIG_VIEW_TYPES[varData.type] and (varData.type ~= "list" or varData.list) then
			local pVal, cVal = ct:NormalizeConfigVals(varData, pInput[varData.var], cInput[varData.var])
			local row = {
				option = varData.var,
				label = T.Clean((varData.label or varData.var):gsub(":$", "")),
				primary = T.Clean(ct:FormatConfigValue(varData, pInput[varData.var])),
				compare = T.Clean(ct:FormatConfigValue(varData, cInput[varData.var])),
			}
			if tostring(pVal) ~= tostring(cVal) then
				t_insert(current.diffs, row)
			elseif not onlyDifferences then
				local relevant = configVisibility.isRelevantForBuild(varData, build) or configVisibility.isRelevantForBuild(varData, entry)
				if relevant or (showAll and not configVisibility.isShowAllExcluded(varData)) then
					row.same = true
					t_insert(current.commons, row)
				end
			end
		end
	end
	local out = { }
	for _, section in ipairs(sections) do
		local rows = { }
		for _, r in ipairs(section.diffs) do t_insert(rows, r) end
		for _, r in ipairs(section.commons) do t_insert(rows, r) end
		if rows[1] then
			total = total + #section.diffs
			t_insert(out, { section = section.name, differences = #section.diffs, rows = rows })
		end
	end
	local function activeSet(tab)
		local set = tab.configSets[tab.activeConfigSetId]
		return T.Clean(set and set.title or "Default")
	end
	return { primaryConfigSet = activeSet(build.configTab), compareConfigSet = activeSet(entry.configTab), differences = total, sections = T.Array(out) }
end

-- Calcs view: CompareTab:DrawCalcs over Modules/CalcSections, with the tab's
-- own row and sub-section comparisons for "Show only differences".
local function compareCalcs(build, entry, onlyDifferences, filter, limit)
	local ct = build.compareTab
	local rowMatches = ct.calcRowMatchesBetweenBuilds
	local extraMatches = ct.subSectionExtraMatches
	local pEnv, cEnv = build.calcsTab.calcsEnv, entry.calcsTab.calcsEnv
	if not pEnv or not cEnv then
		T.Fail("The Calcs view has no calculation for one of the builds yet.")
	end
	local pActor = (build.calcsTab.input.showMinion and pEnv.minion) or pEnv.player
	local cActor = (entry.calcsTab.input.showMinion and cEnv.minion) or cEnv.player
	local needle = filter and filter:match("%S") and filter:lower() or nil
	local function fmt(colData, actor)
		local ok, str = pcall(formatCalcStr, colData.format, actor, colData)
		return ok and str and T.Clean(tostring(str)) or nil
	end
	local sections, rowCount = { }, 0
	for _, secDef in ipairs(ct.calcSections) do
		local id, subSections = secDef[2], secDef[5]
		if build.calcsTab:CheckFlag(subSections[1].data, pActor) then
			local subs = { }
			for _, subSec in ipairs(subSections) do
				local subMatches = not needle or tostring(id):lower():find(needle, 1, true) or tostring(subSec.label or ""):lower():find(needle, 1, true)
				local rows = { }
				for _, rowData in ipairs(subSec.data) do
					if rowData.label and rowData[1] and rowData[1].format and rowCount < limit then
						local pVisible = build.calcsTab:CheckFlag(rowData, pActor)
						local cVisible = build.calcsTab:CheckFlag(rowData, cActor)
						if pVisible or cVisible then
							local keep = true
							if onlyDifferences and pVisible and cVisible then
								keep = not rowMatches(ct, rowData[1], pActor, cActor, entry)
							end
							local label = T.Clean(rowData.label)
							if keep and (subMatches or label:lower():find(needle, 1, true)) then
								t_insert(rows, { label = label, primary = fmt(rowData[1], pActor), compare = fmt(rowData[1], cActor) })
								rowCount = rowCount + 1
							end
						end
					end
				end
				if rows[1] or (onlyDifferences and subMatches and not extraMatches(subSec.data, pActor, cActor)) then
					local sub = { label = T.Clean(subSec.label), rows = T.Array(rows) }
					if subSec.data.extra then
						local okP, pExtra = pcall(formatCalcStr, subSec.data.extra, pActor)
						local okC, cExtra = pcall(formatCalcStr, subSec.data.extra, cActor)
						if okP and okC then
							sub.primaryExtra, sub.compareExtra = T.Clean(pExtra), T.Clean(cExtra)
						end
					end
					t_insert(subs, sub)
				end
			end
			if subs[1] then
				t_insert(sections, { section = id, subSections = subs })
			end
		end
	end
	return { rows = rowCount, truncated = rowCount >= limit or nil, sections = T.Array(sections) }
end

-- Pick a set by its position (1-based) or its title.
local function pickSet(titles, value, what)
	if type(value) == "number" then
		if not titles[value] then
			T.Fail("There is no %s %d; there are %d.", what, value, #titles)
		end
		return value
	end
	local list = { }
	for i, title in ipairs(titles) do
		t_insert(list, { index = i, title = title })
	end
	return T.Find(list, value, function(e) return e.title end, what).index
end

local function setTitleList(orderList, sets)
	local titles = { }
	for i, id in ipairs(orderList) do
		titles[i] = T.Clean(sets[id] and sets[id].title or "Default")
	end
	return titles
end

-- The comparison's selectors (CompareTab:InitControls): compareSpecSelect,
-- compareSkillSetSelect, compareItemSetSelect, compareConfigSetSelect, cmpSocketGroup.
local function selectComparison(build, args)
	local ct = build.compareTab
	local entry, index = compareEntryAt(build, args.index)
	-- Validate every choice before changing anything.
	local sel = { }
	if args.tree_set ~= nil then
		local titles = { }
		for i, spec in ipairs(entry.treeTab.specList) do
			titles[i] = T.Clean(spec.title or "Default")
		end
		sel.tree = pickSet(titles, args.tree_set, "tree set")
	end
	if args.skill_set ~= nil then
		sel.skill = pickSet(setTitleList(entry.skillsTab.skillSetOrderList, entry.skillsTab.skillSets), args.skill_set, "skill set")
	end
	if args.item_set ~= nil then
		sel.item = pickSet(setTitleList(entry.itemsTab.itemSetOrderList, entry.itemsTab.itemSets), args.item_set, "item set")
	end
	if args.config_set ~= nil then
		sel.config = pickSet(setTitleList(entry.configTab.configSetOrderList, entry.configTab.configSets), args.config_set, "config set")
	end
	if args.main_socket_group ~= nil then
		-- Socket groups belong to the skill set that will be active.
		local groups = entry.skillsTab.socketGroupList
		if sel.skill then
			local skillSet = entry.skillsTab.skillSets[entry.skillsTab.skillSetOrderList[sel.skill]]
			groups = skillSet and skillSet.socketGroupList or groups
		end
		if not groups[args.main_socket_group] then
			T.Fail("The compared build has no socket group %d; it has %d (see action 'list').", args.main_socket_group, #groups)
		end
	end
	-- The "Compare with" dropdown.
	ct.activeCompareIndex = index
	ct.treeSearchNeedsSync = true
	ct:UpdateBuildSelector()
	if sel.tree then
		entry:SetActiveSpec(sel.tree)
		-- SetActiveSpec changes the window title; the tab puts the open build's back.
		build.spec:SetWindowTitleWithBuildClass()
	end
	if sel.skill then
		entry:SetActiveSkillSet(entry.skillsTab.skillSetOrderList[sel.skill])
	end
	if sel.item then
		entry:SetActiveItemSet(entry.itemsTab.itemSetOrderList[sel.item])
	end
	if sel.config then
		entry.configTab:SetActiveConfigSet(entry.configTab.configSetOrderList[sel.config])
		entry.buildFlag = true
		ct.configNeedsRebuild = true
	end
	if args.main_socket_group then
		entry:SetMainSocketGroup(args.main_socket_group)
	end
	if entry.buildFlag then
		entry:Rebuild()
	end
	return { selected = entryInfo(ct, entry, index) }
end

local function powerMetrics()
	local list = { }
	for _, e in ipairs(data.powerStatList) do
		if e.stat and not e.ignoreForNodes then
			t_insert(list, e)
		end
	end
	return list
end

-- CompareTab:ComparePowerBuilder run to the end the way RunComparePowerReport
-- resumes it each frame; the rows are sorted and worded by the tab's own
-- ComparePowerReportListControl, which then shows the same report.
local function powerReport(build, args)
	local ct = build.compareTab
	local entry, index = compareEntryAt(build, args.index)
	local metrics = powerMetrics()
	local wanted = (args.metric or "Full DPS"):lower()
	local powerStat
	for _, e in ipairs(metrics) do
		if e.stat:lower() == wanted or e.label:lower() == wanted then
			powerStat = e
		end
	end
	if not powerStat then
		local names = { }
		for _, e in ipairs(metrics) do
			t_insert(names, e.label .. " (" .. e.stat .. ")")
		end
		T.Fail("Unknown metric '%s'. Metrics: %s", args.metric, t_concat(names, ", "))
	end
	local categories = { }
	if args.categories and args.categories[1] then
		for _, key in pairs(POWER_CATEGORIES) do
			categories[key] = false
		end
		for _, name in ipairs(args.categories) do
			categories[POWER_CATEGORIES[name]] = true
		end
	else
		for _, key in pairs(POWER_CATEGORIES) do
			categories[key] = true
		end
	end
	build:ProcessBuildFlag()
	-- The builder adds and removes skills, config values and abyssal jewels on
	-- the open build while it measures them; none of that is a change to keep.
	local flags = { build.modFlag, build.itemsTab.modFlag, build.skillsTab.modFlag, build.configTab.modFlag }
	local co = coroutine.create(function()
		ct:ComparePowerBuilder(entry, powerStat, categories)
	end)
	local ok, err = true, nil
	while ok and coroutine.status(co) ~= "dead" do
		ok, err = coroutine.resume(co)
	end
	build.buildFlag = true
	T.Recalculate(build)
	build.modFlag, build.itemsTab.modFlag, build.skillsTab.modFlag, build.configTab.modFlag = flags[1], flags[2], flags[3], flags[4]
	if not ok then
		T.Fail("The power report failed: %s", tostring(err))
	end
	-- Show the report in the tab, as choosing the metric there would.
	ct.comparePowerStat = powerStat
	ct.comparePowerCategories = categories
	ct.comparePowerCompareId = entry
	ct.comparePowerDirty = false
	ct.comparePowerCoroutine = nil
	ct.comparePowerProgress = 100
	ct.comparePowerListSynced = false
	ct.controls.comparePowerStatSelect:SelByValue(powerStat.stat, "stat")
	ct.controls.comparePowerTreeCheck.state = categories.treeNodes
	ct.controls.comparePowerItemsCheck.state = categories.items
	ct.controls.comparePowerGemsCheck.state = categories.skillGems
	ct.controls.comparePowerSupportGemsCheck.state = categories.supportGems
	ct.controls.comparePowerConfigCheck.state = categories.config
	local listControl = ct.controls.comparePowerReportList
	listControl:SetReport(powerStat, ct.comparePowerResults or { })
	local sortCol = POWER_SORT_COLUMNS[args.sort_by or "impact"]
	if sortCol ~= 3 then
		listControl:ReSort(sortCol)
	end
	local rows = { }
	for i, r in ipairs(listControl.list) do
		t_insert(rows, {
			category = r.category,
			name = T.Clean(r.name),
			impact = T.Round(r.impact),
			impactText = T.Clean(listControl:GetRowValue(3, i, r)),
			percent = T.Round(r.impactPercent, 2),
			points = r.pathDist,
			perPoint = T.Round(r.perPoint),
			nodeId = r.nodeId,
			slot = r.slotName,
		})
	end
	local page, paging = T.Page(rows, args, 25)
	local used = { }
	for name, key in pairs(POWER_CATEGORIES) do
		if categories[key] then
			t_insert(used, name)
		end
	end
	t_sort(used)
	return {
		comparison = index,
		compareName = T.Clean(entry.label),
		metric = { stat = powerStat.stat, label = powerStat.label },
		categories = used,
		status = listControl.statusText,
		rows = page,
		page = paging,
	}
end

-- A compared item for the Items view's Copy / Equip / Buy buttons: a gear
-- slot name, or a jewel socket ("Jewel <nodeId>", its label, or the node id).
-- Returns the item and the slot name both builds use for it.
local function comparedItem(build, entry, slot)
	if not slot then
		T.Fail("slot is required: a gear slot such as 'Helmet' or 'Ring 1', or a jewel socket from the report's jewels list.")
	end
	local cSlot = entry.itemsTab.slots[slot]
	if cSlot and not cSlot.nodeId then
		local item = entry.itemsTab.items[cSlot.selItemId]
		if not item then
			T.Fail("The compared build has nothing in %s.", slot)
		end
		return item, slot
	end
	local wanted = slot:lower()
	for _, jEntry in ipairs(build.compareTab:GetJewelComparisonSlots(entry)) do
		if jEntry.pSlotName:lower() == wanted or T.Clean(jEntry.label):lower() == wanted or tostring(jEntry.nodeId) == slot then
			if not jEntry.cItem then
				T.Fail("The compared build has no jewel in %s.", slot)
			end
			return jEntry.cItem, jEntry.pSlotName
		end
	end
	T.Fail("Unknown slot '%s'. Use a gear slot (%s) or a jewel socket from the report's jewels list.", slot, t_concat(ITEM_BASE_SLOTS, ", "))
end

-- The Items view's "Buy" button opens CompareBuySimilar's popup, whose URL
-- builder turns the popup's choices into a trade search URL. Here stand-ins
-- for the popup's controls hold the requested choices (the popup's defaults
-- otherwise: nothing ticked, minimums prefilled with the item's values), so
-- the URL is composed without opening the popup or fetching the league list.
local function buySimilarUrl(build, args)
	local entry, index = compareEntryAt(build, args.index)
	local buildURL = buySimilar.buildURL
	local item, slotName = comparedItem(build, entry, args.slot)
	local isUnique = item.rarity == "UNIQUE" or item.rarity == "RELIC"
	local modEntries = buySimilar.addModEntries(item, {
		{ list = item.enchantModLines, type = "enchant" },
		{ list = item.implicitModLines, type = "implicit" },
		{ list = item.explicitModLines, type = "explicit" },
		{ list = item.scourgeModLines, type = "scourge" },
	})
	local defenceEntries = { }
	if not isUnique and item.armourData and item.base and item.base.armour then
		for _, def in ipairs({ { key = "Armour", label = "Armour", tradeKey = "ar" }, { key = "Evasion", label = "Evasion", tradeKey = "ev" },
			{ key = "EnergyShield", label = "Energy Shield", tradeKey = "es" }, { key = "Ward", label = "Ward", tradeKey = "ward" } }) do
			local val = item.armourData[def.key]
			if val and val > 0 then
				t_insert(defenceEntries, { label = def.label, value = val, tradeKey = def.tradeKey })
			end
		end
	end
	local realm = BUY_REALMS[args.realm or "pc"]
	local league = args.league and args.league:match("%S") and args.league or "Standard"
	local function edit(value)
		return { buf = value ~= nil and tostring(value) or "" }
	end
	local controls = {
		realmDrop = { GetSelValue = function() return realm end },
		leagueDrop = { GetSelValue = function() return league end },
		listedDrop = { selIndex = BUY_LISTED[args.listed or "securable"] },
	}
	if not isUnique then
		controls.baseTypeCheck = { state = args.use_base_type == true }
		controls.ilvlMin = edit(args.item_level_min)
		controls.ilvlMax = edit(args.item_level_max)
	end
	local wantAll = args.mods == "all"
	local wantedMods = { }
	if type(args.mods) == "table" then
		for _, i in ipairs(args.mods) do
			if not modEntries[i] then
				T.Fail("The item has no mod %d; its mods are numbered 1 to %d (call without mods to see them).", i, #modEntries)
			end
			wantedMods[i] = true
		end
	end
	local modValues = args.mod_values or { }
	local mods = { }
	for i, e in ipairs(modEntries) do
		local searchable = #e.tradeIds > 0
		local selected = searchable and (wantAll or wantedMods[i]) or false
		local hasRange = not (e.isOption or e.needsExactValue) and e.value ~= nil
		local minVal = (hasRange and e.value ~= 0) and e.value or nil
		local maxVal
		local override = modValues[tostring(i)]
		if override then
			minVal = override.min ~= nil and override.min or minVal
			maxVal = override.max
		end
		controls["mod" .. i .. "Check"] = { state = selected }
		controls["mod" .. i .. "Min"] = edit(minVal)
		controls["mod" .. i .. "Max"] = edit(maxVal)
		local lines = { }
		for _, line in ipairs(e.formattedLines) do
			t_insert(lines, T.Clean(line))
		end
		t_insert(mods, {
			index = i, type = e.type, text = t_concat(lines, " + "), searchable = searchable, selected = selected,
			min = hasRange and minVal or nil, max = hasRange and maxVal or nil,
		})
	end
	local wantAllDef = args.defences == "all"
	local wantedDef = { }
	if type(args.defences) == "table" then
		for _, name in ipairs(args.defences) do
			wantedDef[name:lower()] = true
		end
	end
	local defences = { }
	for i, def in ipairs(defenceEntries) do
		local selected = wantAllDef or wantedDef[def.label:lower()] or wantedDef[def.tradeKey] or false
		controls["def" .. i .. "Check"] = { state = selected }
		controls["def" .. i .. "Min"] = edit(math.floor(def.value))
		controls["def" .. i .. "Max"] = edit(nil)
		t_insert(defences, { name = def.label, value = def.value, selected = selected })
	end
	local ok, url = pcall(buildURL, item, slotName, controls, modEntries, defenceEntries, isUnique)
	if not ok then
		T.Fail("Path of Building could not compose the trade URL: %s", tostring(url))
	end
	return {
		comparison = index,
		item = itemSummary(item),
		slot = slotName,
		url = url,
		realm = args.realm or "pc",
		league = league,
		mods = T.Array(mods),
		defences = T.Array(defences),
		note = "Nothing was opened or searched; give the URL to the user to open in a browser.",
	}
end

T.Tool {
	name = "compare_builds",
	title = "Compare builds",
	description = "Path of Building's Compare tab: load other builds next to the open one and see how they differ. Actions: 'add' loads "
		.. "a comparison build from exactly one of path (a saved build, as builds_list returns), code (a build code or build XML), "
		.. "link (a build link; PoB downloads it) or current (a copy of the open build, to try changes against); 'list' shows the "
		.. "loaded comparisons with their tree/item/skill/config sets and socket groups; 'select' makes one active and picks its "
		.. "sets or main socket group; 'remove' drops one; 'report' returns what the tab shows as different (side-bar stats, "
		.. "passive tree nodes, items per slot, socket groups, config options, optionally calcs rows; only differences unless "
		.. "only_differences is false); 'power_report' measures, for one metric, how much each thing the compared build has and the "
		.. "open one lacks (passives, items, gem groups, supports, config values) would change the open build, and shows it in the tab; "
		.. "'buy_similar' composes the trade search URL of the Buy button for a compared item (nothing is opened or fetched). "
		.. "Comparisons are not saved with the build and do not mark it unsaved; to copy something across use compare_copy.",
	destructive = true,
	openWorld = true,
	input = {
		action = { type = "string", enum = { "add", "list", "select", "remove", "report", "power_report", "buy_similar" }, description = "What to do." },
		index = { type = "integer", minimum = 1, description = "Comparison number (from 'list'). Default: the one the tab shows." },
		path = { type = "string", description = "add: a build file in the builds folder, for example 'Guides/Witch.xml'." },
		code = { type = "string", description = "add: a build code or build XML." },
		link = { type = "string", description = "add: a build link (pobb.in, pob.codes, poe.ninja, Maxroll, pastebin, ...)." },
		current = { type = "boolean", description = "add: a copy of the open build as it is now, unsaved changes included." },
		name = { type = "string", maxLength = 100, description = "add: the name the tab shows for it." },
		tree_set = { type = { "integer", "string" }, description = "select: tree set of the comparison, by position or title." },
		item_set = { type = { "integer", "string" }, description = "select: item set, by position or title." },
		skill_set = { type = { "integer", "string" }, description = "select: skill set, by position or title." },
		config_set = { type = { "integer", "string" }, description = "select: config set, by position or title." },
		main_socket_group = { type = "integer", minimum = 1, description = "select: the comparison's main socket group (its number in 'list')." },
		sections = { type = "array", items = { type = "string", enum = REPORT_SECTIONS }, maxItems = 6, description = "report: sections to include (default stats, tree, items, skills, config; calcs is long)." },
		only_differences = { type = "boolean", description = "report: list only what differs (default true)." },
		item_mods = { type = "boolean", description = "report: list each item's mod lines, marked '+' (only this side), '>' or '<' (higher or lower value)." },
		item_stat_changes = { type = "boolean", description = "report: for each differing item, the open build's stat changes if it equipped the compared one (slower)." },
		config_show_all = { type = "boolean", description = "report with only_differences false: also list equal options not relevant to either build." },
		calcs_filter = { type = "string", description = "report: only calcs rows whose section or label contains this text." },
		limit = { type = "integer", minimum = 1, maximum = 500, description = "report: most nodes per tree list and calcs rows (default 100); power_report: rows per page (default 25)." },
		offset = T.PageArgs(25).offset,
		metric = { type = "string", description = "power_report: the stat to measure, by name or label, for example 'Full DPS', 'Life', 'TotalEHP' (default Full DPS)." },
		categories = { type = "array", items = { type = "string", enum = { "tree", "items", "skill_gems", "support_gems", "config" } }, maxItems = 5, description = "power_report: what to measure (default all)." },
		sort_by = { type = "string", enum = { "impact", "category", "points", "per_point" }, description = "power_report: row order (default impact)." },
		slot = { type = "string", description = "buy_similar: the compared item's slot, for example 'Helmet', 'Ring 2', or a jewel socket." },
		league = { type = "string", description = "buy_similar: trade league (default Standard)." },
		realm = { type = "string", enum = { "pc", "xbox", "sony" }, description = "buy_similar: realm (default pc)." },
		listed = { type = "string", enum = { "securable", "available", "online", "any" }, description = "buy_similar: listing status (default securable = instant buyout)." },
		use_base_type = { type = "boolean", description = "buy_similar: search the item's base type only." },
		item_level_min = { type = "integer", minimum = 1, maximum = 100, description = "buy_similar: minimum item level." },
		item_level_max = { type = "integer", minimum = 1, maximum = 100, description = "buy_similar: maximum item level." },
		mods = { anyOf = { { type = "string", enum = { "all" } }, { type = "array", items = { type = "integer", minimum = 1 }, maxItems = 50 } }, description = "buy_similar: mods to search for, by their number in the result, or 'all'. Default none (category only)." },
		mod_values = { type = "object", additionalProperties = { type = "object", properties = { min = { type = "number" }, max = { type = "number" } }, additionalProperties = false }, description = "buy_similar: per mod number (as a string key) its min/max, replacing the item's own value as minimum." },
		defences = { anyOf = { { type = "string", enum = { "all" } }, { type = "array", items = { type = "string" }, maxItems = 4 } }, description = "buy_similar: defences to require at least the item's value of (Armour, Evasion, Energy Shield, Ward), or 'all'." },
	},
	required = { "action" },
	run = function(args)
		local build = T.Build()
		local ct = build.compareTab
		local action = args.action
		if action == "add" then
			local sources = 0
			for _, key in ipairs({ "path", "code", "link" }) do
				if args[key] ~= nil then
					sources = sources + 1
				end
			end
			if args.current then
				sources = sources + 1
			end
			if sources ~= 1 then
				T.Fail("Give exactly one of path, code, link or current.")
			end
			if args.path then
				local relative = buildFolderFile(args.path)
				local file = io.open(main.buildPath .. relative, "r")
				if not file then
					T.Fail("No build file '%s' in the builds folder; use builds_list to find it.", relative)
				end
				local xml = file:read("*a")
				file:close()
				return addComparison(build, xml, args.name or relative:match("([^/]+)%.[xX][mM][lL]$"))
			elseif args.code then
				return addComparison(build, T.DecodeBuildCode(args.code), args.name or "Imported build")
			elseif args.current then
				build:ProcessBuildFlag()
				return addComparison(build, build:SaveDB("code"), args.name or ("Copy of " .. (build.buildName or "build")))
			end
			local link = args.link:gsub("^%s+", ""):gsub("%s+$", "")
			local site = findLinkSite(link)
			return T.Defer(function(resolve)
				buildSites.DownloadBuild(link, site, function(isSuccess, data)
					if not isSuccess then
						return resolve(nil, s_format("Could not download the build from %s: %s", site.label, tostring(data)))
					end
					T.Settle(resolve, function()
						local result = addComparison(T.Build(), T.DecodeBuildCode(data), args.name or ("Imported from " .. site.label))
						result.source = site.label
						return result
					end)
				end)
			end, 60)
		elseif action == "list" then
			local entries = { }
			for i, entry in ipairs(ct.compareEntries) do
				if entry.buildFlag then
					entry:Rebuild()
				end
				t_insert(entries, entryInfo(ct, entry, i))
			end
			return {
				primary = { name = build.buildName, class = build.spec.curClassName, level = build.characterLevel, mainSkill = mainSkillName(build.calcsTab) },
				active = ct.activeCompareIndex > 0 and ct.activeCompareIndex or nil,
				comparisons = T.Array(entries),
			}
		elseif action == "select" then
			return selectComparison(build, args)
		elseif action == "remove" then
			local entry, index = compareEntryAt(build, args.index)
			ct:RemoveBuild(index)
			return { removed = T.Clean(entry.label), remaining = #ct.compareEntries, active = ct.activeCompareIndex > 0 and ct.activeCompareIndex or nil }
		elseif action == "report" then
			local entry, index = compareEntryAt(build, args.index)
			build:ProcessBuildFlag()
			local onlyDifferences = args.only_differences ~= false
			local limit = args.limit or 100
			local wanted = { }
			for _, name in ipairs(args.sections and args.sections[1] and args.sections or DEFAULT_REPORT_SECTIONS) do
				wanted[name] = true
			end
			local result = {
				comparison = index,
				primaryName = T.Clean(ct:GetShortBuildName(build.buildName)),
				compareName = T.Clean(entry.label),
				primaryLevel = build.characterLevel,
				compareLevel = entry.characterLevel,
				primaryMainSkill = mainSkillName(build.calcsTab),
				compareMainSkill = mainSkillName(entry.calcsTab),
				onlyDifferences = onlyDifferences,
			}
			if wanted.stats then result.stats = compareStats(build, entry, onlyDifferences) end
			if wanted.tree then result.tree = compareTree(build, entry, limit) end
			if wanted.items then result.items = compareItems(build, entry, onlyDifferences, args.item_mods, args.item_stat_changes) end
			if wanted.skills then result.skills = compareSkills(build, entry, onlyDifferences) end
			if wanted.config then result.config = compareConfig(build, entry, onlyDifferences, args.config_show_all) end
			if wanted.calcs then result.calcs = compareCalcs(build, entry, onlyDifferences, args.calcs_filter, limit) end
			return result
		elseif action == "power_report" then
			return powerReport(build, args)
		else
			return buySimilarUrl(build, args)
		end
	end,
}

-- Copy socket groups as the Skills tab's Copy and Paste buttons do
-- (SkillsTab:CopySocketGroup, SkillsTab:PasteSocketGroup), without the clipboard.
local function copySocketGroup(skillsTab, group)
	-- CopySocketGroup writes the group's text to the clipboard; capture it instead.
	local copy = Copy
	local text
	local ok, err = pcall(function()
		Copy = function(value)
			text = value
		end
		skillsTab:CopySocketGroup(group)
	end)
	Copy = copy
	if not ok then
		error(err, 0)
	end
	skillsTab:PasteSocketGroup(text)
end

T.Tool {
	name = "compare_copy",
	title = "Copy from a compared build",
	description = "Copies something from a comparison build (compare_builds) into the open build, as the Compare tab's buttons do. "
		.. "what='tree' adds the compared build's active passive tree as a new tree set named '<title> (Compared)' (\"Copy tree\"; "
		.. "with use=true it also becomes the active tree, \"Copy and use\"; jewels are not copied). what='item' adds the compared item "
		.. "in 'slot' to the open build's items (\"Copy\"; with use=true it is also equipped in that slot, \"Equip\"). what='config' "
		.. "copies every Config tab option of the compared build (\"Copy Config from Compare Build\"). what='skills' adds the compared "
		.. "build's socket groups listed in socket_groups as new groups, as the Skills tab's copy and paste do (gem name, level, quality, "
		.. "enabled, count, label and slot; groups granted by items come with the item and are skipped). The build is marked unsaved and "
		.. "statChanges lists what changed.",
	destructive = true,
	modifies = true,
	input = {
		what = { type = "string", enum = { "tree", "item", "config", "skills" }, description = "What to copy." },
		index = { type = "integer", minimum = 1, description = "Comparison number (default: the one the tab shows)." },
		slot = { type = "string", description = "item: the compared item's slot, for example 'Helmet', 'Ring 1', or a jewel socket from the report's jewels list." },
		use = { type = "boolean", description = "tree: make the copy the active tree; item: equip it in that slot." },
		socket_groups = { type = "array", items = { type = "integer", minimum = 1 }, maxItems = 50, description = "skills: numbers of the compared build's socket groups to copy (from compare_builds list)." },
	},
	required = { "what" },
	run = function(args, ctx)
		local build = T.Build()
		local ct = build.compareTab
		local entry, index = compareEntryAt(build, args.index)
		local result = { comparison = index, compareName = T.Clean(entry.label), copied = args.what }
		if args.what == "tree" then
			if not entry.treeTab.specList[entry.treeTab.activeSpec] then
				T.Fail("The compared build has no active tree.")
			end
			local before = #build.treeTab.specList
			ct:CopyCompareSpecToPrimary(args.use == true)
			if #build.treeTab.specList == before then
				T.Fail("Path of Building did not copy the tree.")
			end
			local spec = build.treeTab.specList[#build.treeTab.specList]
			result.treeSet = { index = #build.treeTab.specList, title = T.Clean(spec.title), active = build.treeTab.activeSpec == #build.treeTab.specList }
		elseif args.what == "item" then
			local item, slotName = comparedItem(build, entry, args.slot)
			local pEnv = build.calcsTab.mainEnv
			if args.use and slotName == "Ring 3" and not (pEnv and pEnv.modDB:Flag(nil, "AdditionalRingSlot")) then
				T.Fail("The open build has no third ring slot (the tab shows 'Missing slot' there); copy it without use to add it unequipped.")
			end
			-- ItemsTab:AddItem takes the lowest free id: find the item that was not there before.
			local idsBefore = { }
			for id in pairs(build.itemsTab.items) do
				idsBefore[id] = true
			end
			ct:CopyCompareItemToPrimary(slotName, entry, args.use == true)
			local newItem
			for id, it in pairs(build.itemsTab.items) do
				if not idsBefore[id] then
					newItem = it
				end
			end
			if not newItem then
				T.Fail("Path of Building did not copy the item.")
			end
			local pSlot = build.itemsTab.slots[slotName]
			result.item = itemSummary(newItem)
			result.slot = slotName
			result.equipped = pSlot and pSlot.selItemId == newItem.id or false
		elseif args.what == "config" then
			ct:CopyCompareConfig()
		else
			if not args.socket_groups or not args.socket_groups[1] then
				T.Fail("socket_groups is required for skills: the numbers of the compared build's socket groups (compare_builds list).")
			end
			local groups = entry.skillsTab.socketGroupList
			local copied, skipped = { }, { }
			for _, i in ipairs(args.socket_groups) do
				if not groups[i] then
					T.Fail("The compared build has no socket group %d; it has %d.", i, #groups)
				end
			end
			for _, i in ipairs(args.socket_groups) do
				local group = groups[i]
				if group.source then
					t_insert(skipped, socketGroupLabel(group, i))
				else
					local before = #build.skillsTab.socketGroupList
					copySocketGroup(build.skillsTab, group)
					if #build.skillsTab.socketGroupList > before then
						t_insert(copied, socketGroupLabel(group, i))
					else
						t_insert(skipped, socketGroupLabel(group, i))
					end
				end
			end
			if not copied[1] then
				T.Fail("Nothing was copied: %s come from items or have no gems.", t_concat(skipped, ", "))
			end
			result.socketGroups = copied
			result.skipped = skipped[1] and skipped or nil
		end
		ctx:Changed()
		return result
	end,
}

------------------------------------------------------------------------------
-- Party tab
------------------------------------------------------------------------------

-- partyDestinations in PartyTab.
local PARTY_DESTINATIONS = { "All", "Party Member Stats", "Aura", "Curse", "Warcry Skills", "Link Skills", "EnemyConditions", "EnemyMods" }
-- PartyTab:Save's export sections, keyed by the buffExports entry each one reads.
local PARTY_EXPORTS = { { "PlayerMods", "PartyMemberStats" }, { "Aura", "Aura" }, { "Curse", "Curse" }, { "Warcry", "Warcry Skills" },
	{ "Link", "Link Skills" }, { "EnemyConditions", "EnemyConditions" }, { "EnemyMods", "EnemyMods" } }

-- The effects of one of the party actor's buff lists (PartyTab:ParseBuffs keys
-- them by name, Vaal skills in a nested "Vaal" list).
local function partyEffects(list)
	local out = { }
	for name, entry in pairs(list or { }) do
		if name == "Vaal" and type(entry) == "table" and entry.effectMult == nil then
			for vaalName, vaalEntry in pairs(entry) do
				t_insert(out, { name = vaalName, effect = vaalEntry.effectMult })
			end
		elseif type(entry) == "table" and entry.effectMult then
			t_insert(out, { name = name, effect = entry.effectMult, mark = entry.isMark or nil })
		end
	end
	t_sort(out, function(a, b) return tostring(a.name) < tostring(b.name) end)
	return T.Array(out)
end

local function partySummary(build, includeText)
	local partyTab = build.partyTab
	local c = partyTab.controls
	local actor = partyTab.actor
	local aura, curse = actor.Aura or { }, actor.Curse or { }
	local memberStats = { }
	for k, v in pairs(actor.output or { }) do
		if type(v) == "number" then
			memberStats[k] = T.Round(v)
		elseif type(v) == "table" then
			for k2, v2 in pairs(v) do
				if type(v2) == "number" then
					memberStats[k .. "." .. k2] = T.Round(v2)
				end
			end
		end
	end
	local memberFlags = { }
	for name in pairs(actor.modDB and actor.modDB.mods or { }) do
		t_insert(memberFlags, name)
	end
	t_sort(memberFlags)
	local otherEffects = { }
	for name in pairs(aura.otherEffects or { }) do
		t_insert(otherEffects, name)
	end
	t_sort(otherEffects)
	local extraAura = aura.extraAura and aura.extraAura.extraAura
	local summary = {
		exportSupport = partyTab.enableExportBuffs == true,
		auras = partyEffects(aura.Aura),
		auraDebuffs = partyEffects(aura.AuraDebuff),
		extraAuraMods = extraAura and #extraAura.modList or 0,
		otherEffects = T.Array(otherEffects),
		curses = partyEffects(curse.Curse),
		curseLimit = curse.limit,
		warcries = partyEffects((actor.Warcry or { }).Warcry),
		links = partyEffects((actor.Link or { }).Link),
		partyMemberStats = T.Object(memberStats),
		partyMemberFlags = T.Array(memberFlags),
		enemyMods = #partyTab.enemyModList,
	}
	local texts = {
		partyMemberStats = c.editPartyMemberStats.buf, auras = c.editAuras.buf, curses = c.editCurses.buf, warcries = c.editWarcries.buf,
		links = c.editLinks.buf, enemyConditions = c.enemyCond.buf, enemyMods = c.enemyMods.buf,
	}
	local imported = { }
	for key, text in pairs(texts) do
		if text ~= "" then
			imported[key] = includeText and text or select(2, text:gsub("\n", "\n")) + 1
		end
	end
	summary.importedText = T.Object(imported)
	return summary
end

-- Run fn with the Party tab's destination and Append controls set, as the
-- user would set them before pressing Import or Clear; put them back after.
local function withPartyControls(partyTab, destination, append, fn)
	local c = partyTab.controls
	local saved = { c.importCodeDestination.selIndex, c.appendNotReplace.state }
	local wanted = destination or "All"
	local found
	for _, name in ipairs(c.importCodeDestination.list) do
		if name == wanted then
			found = true
		end
	end
	if not found then
		T.Fail("Unknown destination '%s'. Destinations: %s", wanted, t_concat(c.importCodeDestination.list, ", "))
	end
	c.importCodeDestination:SelByValue(wanted)
	c.appendNotReplace.state = append == true
	local ok, err = pcall(fn)
	c.importCodeDestination.selIndex, c.appendNotReplace.state = saved[1], saved[2]
	if not ok then
		error(err, 0)
	end
end

-- The Party tab's Import button, once its code box holds a valid code: the
-- state importCodeHandle leaves for it, then the button, then the code box
-- state put back as it was.
local function partyImport(build, xml, args)
	xml = normaliseNewlines(xml)
	-- finishImport reports bad XML through an error popup; check what it needs first.
	local dbXML, parseErr = common.xml.ParseXML(xml)
	if not dbXML or not dbXML[1] or dbXML[1].elem ~= "PathOfBuilding" then
		T.Fail("That is not a Path of Building build (%s).", tostring(parseErr or "no PathOfBuilding element"))
	end
	local sections = { }
	for _, tabNode in ipairs(dbXML[1]) do
		if type(tabNode) == "table" and tabNode.elem == "Party" then
			for _, node in ipairs(tabNode) do
				if type(node) == "table" and node.elem == "ExportedBuffs" and node.attrib.name then
					t_insert(sections, node.attrib.name)
				end
			end
		end
	end
	if not sections[1] then
		T.Fail("That build carries nothing for the Party tab: it must be exported with 'Export Support' enabled "
			.. "(Import/Export tab, or party action export_support on that build).")
	end
	local partyTab = build.partyTab
	local fields = { "importCodeSite", "importCodeXML", "importCodeValid", "importCodeDetail", "importCodeFetching" }
	local saved = { }
	for _, field in ipairs(fields) do
		saved[field] = partyTab[field]
	end
	partyTab.importCodeSite = nil
	partyTab.importCodeFetching = nil
	partyTab.importCodeXML = xml
	partyTab.importCodeValid = true
	local ok, err = pcall(withPartyControls, partyTab, args.destination, args.append, partyTab.controls.importCodeGo.onClick)
	for _, field in ipairs(fields) do
		partyTab[field] = saved[field]
	end
	if not ok then
		error(err, 0)
	end
	return sections
end

T.Tool {
	name = "party",
	title = "Party tab",
	description = "Path of Building's Party tab, which adds the auras, curses, warcries, link skills, party member stats and enemy "
		.. "modifiers of other party members to the open build's calculations. Actions: 'get' summarises what is imported and active "
		.. "(include_text adds the tab's text boxes); 'import' adds a party member from a build that was exported with 'Export Support' "
		.. "enabled, given as code (build code or build XML) or link, into a destination (default All; append keeps what is there, "
		.. "except curses); 'clear' empties a destination; 'disable_effects' stops the effects but keeps the text ('Disable Party "
		.. "Effects'); 'rebuild' parses all the text again ('Rebuild All'); 'export_support' turns the Import/Export tab's 'Export "
		.. "Support' on or off for the open build, so its own export can be imported into another build's Party tab (the result "
		.. "lists the sections it exports). Changes mark the build unsaved and statChanges shows their effect.",
	destructive = true,
	modifies = true,
	openWorld = true,
	input = {
		action = { type = "string", enum = { "get", "import", "clear", "disable_effects", "rebuild", "export_support" }, description = "What to do." },
		code = { type = "string", description = "import: build code or build XML of the party member." },
		link = { type = "string", description = "import: build link of the party member (PoB downloads it)." },
		destination = { type = "string", enum = PARTY_DESTINATIONS, description = "import/clear: which part (default All)." },
		append = { type = "boolean", description = "import: add to what is there instead of replacing it (curses still replace)." },
		enabled = { type = "boolean", description = "export_support: on or off." },
		include_text = { type = "boolean", description = "Include the Party tab's text boxes (or, for export_support, the exported text)." },
	},
	required = { "action" },
	run = function(args, ctx)
		local build = T.Build()
		local partyTab = build.partyTab
		local action = args.action
		if action == "get" then
			return partySummary(build, args.include_text)
		elseif action == "import" then
			if (args.code == nil) == (args.link == nil) then
				T.Fail("Give exactly one of code or link.")
			end
			if args.code then
				local sections = partyImport(build, T.DecodeBuildCode(args.code), args)
				ctx:Changed()
				T.Recalculate(build)
				local result = partySummary(build, args.include_text)
				result.importedSections = sections
				return result
			end
			local link = args.link:gsub("^%s+", ""):gsub("%s+$", "")
			local site = findLinkSite(link)
			-- main.modes.BUILD is reused for every build; its tabs are recreated whenever another build opens.
			local openedTree = build.treeTab
			return T.Defer(function(resolve)
				buildSites.DownloadBuild(link, site, function(isSuccess, data)
					if not isSuccess then
						return resolve(nil, s_format("Could not download the build from %s: %s", site.label, tostring(data)))
					end
					T.Settle(resolve, function()
						local current = T.Build()
						if current.treeTab ~= openedTree then
							T.Fail("The open build changed while the download ran; nothing was imported.")
						end
						local sections = partyImport(build, T.DecodeBuildCode(data), args)
						ctx:Changed()
						T.Recalculate(build)
						local result = partySummary(build, args.include_text)
						result.importedSections = sections
						return result
					end)
				end)
			end, 60)
		elseif action == "clear" then
			withPartyControls(partyTab, args.destination, nil, partyTab.controls.clear.onClick)
		elseif action == "disable_effects" then
			partyTab.controls.removeEffects.onClick()
		elseif action == "rebuild" then
			partyTab.controls.rebuild.onClick()
		else
			if args.enabled == nil then
				T.Fail("enabled is required for export_support.")
			end
			local checkbox = build.importTab.controls.enablePartyExportBuffs
			checkbox.state = args.enabled
			checkbox.changeFunc(args.enabled)
			ctx:Changed()
			T.Recalculate(build)
			local exports = { }
			for _, pair in ipairs(PARTY_EXPORTS) do
				local text = partyTab:exportBuffs(pair[1])
				if text ~= "" then
					exports[pair[2]] = args.include_text and text or (select(2, text:gsub("\n", "\n")) + 1)
				end
			end
			return { exportSupport = partyTab.enableExportBuffs == true, exports = T.Object(exports) }
		end
		ctx:Changed()
		T.Recalculate(build)
		return partySummary(build, args.include_text)
	end,
}

------------------------------------------------------------------------------
-- Character import (Import/Export tab, "Import From Your Account")
------------------------------------------------------------------------------

-- realmList in ImportTab.
local REALMS = { pc = "PC", xbox = "XBOX", sony = "SONY" }
-- The inventory ids ImportTab:ImportItem puts into a slot.
local IMPORTED_INVENTORIES = { Weapon = true, Offhand = true, Weapon2 = true, Offhand2 = true, Helm = true, BodyArmour = true,
	Gloves = true, Boots = true, Amulet = true, Ring = true, Ring2 = true, Ring3 = true, Belt = true, BrequelGrafts = true,
	BrequelGrafts2 = true, Flask = true, PassiveJewels = true }
local NOT_LOGGED_IN = "Path of Building is not logged in to Path of Exile. Ask the user to log in from the Import/Export tab "
	.. "('Authorize with Path of Exile'), then try again."

local function poeApi()
	-- As ImportTab creates it, from the login PoB remembers.
	if not main.api then
		main.api = new("PoEAPI"):PoEAPI(main.lastToken, main.lastRefreshToken, main.tokenExpiry)
	end
	return main.api
end

-- What an answer from PoEAPI's download functions means (as the Import tab reads them).
local function apiFailure(api, err, timeNext, name)
	err = tostring(err or "no answer")
	if err == "Response code: 429" then
		local wait = timeNext and m_max(0, timeNext - os.time())
		return "pathofexile.com is rate limiting these requests" .. (wait and s_format("; try again in %d seconds.", wait) or "; try again later.")
	elseif not api.authToken or err:match("401") then
		-- PoEAPI drops the login when the token cannot be refreshed.
		return "The Path of Exile login in Path of Building has expired. Ask the user to log in again from the Import/Export tab ('Authorize with Path of Exile')."
	elseif name and err:match("404") then
		return s_format("pathofexile.com has no character '%s' on the account Path of Building is logged in to. The name must match exactly "
			.. "(use action 'list'); other accounts' characters cannot be imported this way.", name)
	end
	return "pathofexile.com answered: " .. err
end

-- What the import left out: items in slots PoB imports that did not arrive,
-- and mod lines PoB does not understand (shown in red, counting for nothing).
local function auditImport(build, char, withItems, withTree)
	local present = { }
	for _, item in pairs(build.itemsTab.items) do
		if item.uniqueID then
			present[item.uniqueID] = true
		end
	end
	local missing = { }
	local function check(list)
		for _, itemData in ipairs(list or { }) do
			if IMPORTED_INVENTORIES[itemData.inventoryId] and itemData.id and not present[itemData.id] then
				t_insert(missing, { inventory = itemData.inventoryId, name = T.Clean((itemData.name ~= "" and (itemData.name .. ", ") or "") .. tostring(itemData.typeLine)) })
			end
		end
	end
	if withItems then
		check(char.equipment)
	end
	if withTree then
		check(char.jewels)
	end
	local unsupported = { }
	for slotName, slot in pairs(build.itemsTab.slots) do
		local item = build.itemsTab.items[slot.selItemId]
		if item then
			for _, listName in ipairs({ "enchantModLines", "scourgeModLines", "implicitModLines", "explicitModLines", "crucibleModLines" }) do
				for _, modLine in ipairs(item[listName] or { }) do
					if modLine.extra then
						t_insert(unsupported, { slot = slotName, line = T.Clean(modLine.line) })
					end
				end
			end
		end
	end
	t_sort(unsupported, function(a, b) return a.slot < b.slot end)
	return { itemsNotImported = T.Array(missing), unsupportedModLines = T.Array(unsupported) }
end

-- The Import tab's "Items and Skills" and "Passive Tree and Jewels" buttons
-- with the character PoB downloaded (the order of its JSON import).
local function importCharacterInto(build, char, realmCode, args, withItems, withTree)
	local importTab = build.importTab
	-- saveDetails in ImportTab: the realm, league and character the tab remembers.
	main.lastRealm, importTab.lastRealm = REALMS[realmCode], REALMS[realmCode]
	main.lastLeague, importTab.lastLeague = char.league, char.league
	main.lastCharacterHash = common.sha1(char.name)
	importTab.lastCharacterHash = main.lastCharacterHash
	if withItems then
		importTab:ImportItemsAndSkills(char, args.delete_equipment ~= false, args.delete_skills ~= false, args.ignore_weapon_swap == true)
	end
	if withTree then
		importTab:ImportPassiveTreeAndJewels(char, args.delete_jewels ~= false)
	end
	T.Recalculate(build)
	local equipped = 0
	for _, slot in pairs(build.itemsTab.slots) do
		if build.itemsTab.items[slot.selItemId] then
			equipped = equipped + 1
		end
	end
	local input = build.configTab.input
	return {
		character = { name = char.name, class = char.class, league = char.league, level = char.level },
		imported = withItems and withTree and "tree, jewels, items and skills" or withTree and "tree and jewels" or "items and skills",
		build = T.BuildSummary(build),
		equippedItems = equipped,
		socketGroups = #build.skillsTab.socketGroupList,
		questChoices = { bandit = input.bandit, pantheonMajor = input.pantheonMajorGod, pantheonMinor = input.pantheonMinorGod },
		audit = auditImport(build, char, withItems, withTree),
	}
end

T.Tool {
	name = "import_character",
	title = "Import a Path of Exile character",
	description = "Imports a character from the Path of Exile account Path of Building is logged in to, exactly as the Import/Export "
		.. "tab's 'Import From Your Account' does (PoB's own login, token refresh and rate limiting; the login never leaves PoB). "
		.. "action 'list' lists the account's characters (optionally of one league). action 'import' downloads one character by "
		.. "name: mode 'new_build' (default) opens a new build and imports everything into it (refused while the open build has "
		.. "unsaved changes unless discard_unsaved); mode 'update' imports into the open build: parts 'tree' (passive tree and jewels, "
		.. "replacing the tree), 'items_skills' (items and skills) or 'both'; by default equipped jewels, equipment and skills are "
		.. "deleted first, as the tab's checkboxes are. The result includes an audit of items PoB could not import and mod lines it "
		.. "does not support. It fails when PoB is not logged in: only the user can log in, from the Import/Export tab "
		.. "('Authorize with Path of Exile'). Builds from other people's accounts are imported with build_open link instead.",
	destructive = true,
	openWorld = true,
	modifies = true,
	replacesBuild = true,
	needsBuild = false,
	input = {
		action = { type = "string", enum = { "list", "import" }, description = "List the account's characters, or import one." },
		realm = { type = "string", enum = { "pc", "xbox", "sony" }, description = "Realm (default: the one last used, else pc)." },
		league = { type = "string", description = "list: only characters in this league, for example 'Standard'." },
		name = { type = "string", maxLength = 50, description = "import: the character name, exactly as in the game." },
		mode = { type = "string", enum = { "new_build", "update" }, description = "import: into a new build (default) or the open one." },
		parts = { type = "string", enum = { "both", "tree", "items_skills" }, description = "import with mode update: what to import (default both)." },
		delete_jewels = { type = "boolean", description = "Delete the equipped jewels before importing the tree (default true)." },
		delete_equipment = { type = "boolean", description = "Delete the equipped items before importing items (default true)." },
		delete_skills = { type = "boolean", description = "Delete the existing skills before importing skills (default true)." },
		ignore_weapon_swap = { type = "boolean", description = "Skip weapon swap items and their skills (default false)." },
		build_name = { type = "string", maxLength = 100, description = "mode new_build: name of the new build (default the character name)." },
		discard_unsaved = T.discardUnsavedArg,
		limit = T.PageArgs(50).limit,
		offset = T.PageArgs(50).offset,
	},
	required = { "action" },
	run = function(args, ctx)
		local realmCode = args.realm or (main.lastRealm and main.lastRealm:lower()) or "pc"
		if not REALMS[realmCode] then
			realmCode = "pc"
		end
		local api = poeApi()
		if args.action == "list" then
			if not api.authToken then
				T.Fail(NOT_LOGGED_IN)
			end
			return T.Defer(function(resolve)
				api:DownloadCharacterList(realmCode, function(body, err, timeNext)
					T.Settle(resolve, function()
						if err or type(body) ~= "table" or type(body.characters) ~= "table" then
							T.Fail(apiFailure(api, err, timeNext))
						end
						local list, leagues = { }, { }
						for _, char in ipairs(body.characters) do
							-- ImportTab:BuildCharacterList
							if char.realm == realmCode and (not args.league or char.league == args.league) then
								t_insert(list, { name = char.name, class = char.class, league = char.league, level = char.level })
							end
							if char.league then
								leagues[char.league] = true
							end
						end
						t_sort(list, function(a, b) return tostring(a.name):lower() < tostring(b.name):lower() end)
						local leagueList = { }
						for league in pairs(leagues) do
							t_insert(leagueList, league)
						end
						t_sort(leagueList)
						local page, paging = T.Page(list, args, 50)
						return { realm = realmCode, leagues = T.Array(leagueList), characters = page, page = paging }
					end)
				end)
			end, 60)
		end
		-- PoB puts the name into the URL path as it is: allow only what character names contain.
		if type(args.name) ~= "string" or not args.name:match("^[%w_]+$") then
			T.Fail("name must be a character name (letters, digits and underscores), exactly as in the game.")
		end
		local mode = args.mode or "new_build"
		local withItems = mode == "new_build" or args.parts ~= "tree"
		local withTree = mode == "new_build" or args.parts ~= "items_skills"
		-- main.modes.BUILD is reused for every build; its tabs are recreated whenever another build opens.
		local targetTree
		if mode == "update" then
			targetTree = T.Build().treeTab
		else
			T.CheckCanReplaceBuild(args)
		end
		if not api.authToken then
			T.Fail(NOT_LOGGED_IN)
		end
		return T.Defer(function(resolve)
			api:DownloadCharacter(realmCode, args.name, function(body, err, timeNext)
				T.Settle(resolve, function()
					if err or type(body) ~= "table" or type(body.character) ~= "table" then
						T.Fail(apiFailure(api, err, timeNext, args.name))
					end
					local char = body.character
					local build
					if mode == "update" then
						build = T.Build()
						if build.treeTab ~= targetTree then
							T.Fail("The open build changed while the download ran; nothing was imported.")
						end
						local result = importCharacterInto(build, char, realmCode, args, withItems, withTree)
						ctx:Changed()
						return result
					end
					-- The user may have changed something while the download ran.
					T.CheckCanReplaceBuild(args)
					build = T.SwitchToBuild(false, (T.Sanitise(args.build_name or char.name)))
					return importCharacterInto(build, char, realmCode, args, true, true)
				end)
			end)
		end, 60)
	end,
}
