-- Path of Building
--
-- Module: Config Visibility
-- Shared helpers that decide which entries in ConfigOptions should be visible for a given build.
-- Used by both the main Config tab and the Compare tab's Config view so their "Show All
-- Configurations" toggles stay in sync when the predicate list in ConfigOptions grows.
--

-- Labels containing any of these keywords stay hidden even when "Show All Configurations" is on.
local EXCLUDE_KEYWORDS = { "recently", "in the last", "in the past", "in last", "in past", "pvp" }

-- Simple predicates of the form `varData.ifX` → `mainEnv.YUsed[opt]`, with imply-cond fallback when `canImply` is true.
local SIMPLE_PREDICATES = {
	{ key = "ifCond",       env = "conditionsUsed",       canImply = true },
	{ key = "ifMinionCond", env = "minionConditionsUsed", canImply = true },
	{ key = "ifEnemyCond",  env = "enemyConditionsUsed",  canImply = true },
	{ key = "ifMult",       env = "multipliersUsed",      canImply = true },
	{ key = "ifEnemyMult",  env = "enemyMultipliersUsed", canImply = true },
	{ key = "ifEnemyStat",  env = "enemyPerStatsUsed",    canImply = true },
	{ key = "ifTagType",    env = "tagTypesUsed",         canImply = true },
	{ key = "ifMod",        env = "modsUsed",             canImply = true },
}

-- Run `predicate` against either a single value or a list of values.
local function anyIfValue(ifOption, predicate)
	if type(ifOption) == "table" then
		for _, opt in ipairs(ifOption) do
			if predicate(opt) then return true end
		end
		return false
	end
	return predicate(ifOption) and true or false
end

-- When the option has an input value and one of its implied conditions is currently used, treat gated predicates as passing.
local function implyCondActive(varData, build)
	local configTab = build and build.configTab
	if not configTab then return false end
	local activeSet = configTab.configSets and configTab.configSets[configTab.activeConfigSetId]
	if not activeSet or not activeSet.input[varData.var] then return false end
	local mainEnv = build.calcsTab and build.calcsTab.mainEnv
	if not mainEnv then return false end
	if varData.implyCondList then
		for _, implyCond in ipairs(varData.implyCondList) do
			if implyCond and mainEnv.conditionsUsed[implyCond] then return true end
		end
	end
	return (varData.implyCond and mainEnv.conditionsUsed[varData.implyCond])
		or (varData.implyMinionCond and mainEnv.minionConditionsUsed[varData.implyMinionCond])
		or (varData.implyEnemyCond and mainEnv.enemyConditionsUsed[varData.implyEnemyCond])
		or false
end

-- True if every `ifX` predicate on `varData` currently passes for `build`
local function isRelevantForBuild(varData, build)
	if not build then return false end
	local mainEnv = build.calcsTab and build.calcsTab.mainEnv
	if not mainEnv then return false end
	local player = mainEnv.player
	local mainSkill = player and player.mainSkill
	local spec = build.spec
	local configTab = build.configTab
	local activeInput = configTab and configTab.configSets
			and configTab.configSets[configTab.activeConfigSetId]
			and configTab.configSets[configTab.activeConfigSetId].input
			or {}

	local impliedCache
	local function implied()
		if impliedCache == nil then
			impliedCache = implyCondActive(varData, build) or false
		end
		return impliedCache
	end

	for _, p in ipairs(SIMPLE_PREDICATES) do
		local ifVal = varData[p.key]
		if ifVal then
			local envTable = mainEnv[p.env] or {}
			if not anyIfValue(ifVal, function(opt)
				return envTable[opt] or (p.canImply and implied())
			end) then return false end
		end
	end

	if varData.ifNode and spec then
		if not anyIfValue(varData.ifNode, function(opt)
			if spec.allocNodes[opt] then return true end
			local node = spec.nodes[opt]
			if node and node.type == "Keystone" then
				return mainEnv.keystonesAdded and mainEnv.keystonesAdded[node.dn]
			end
			return false
		end) then return false end
	end
	if varData.ifOption then
		if not anyIfValue(varData.ifOption, function(opt) return activeInput[opt] end) then return false end
	end
	if varData.ifCondTrue then
		if not anyIfValue(varData.ifCondTrue, function(opt) return player and player.modDB.conditions[opt] end) then return false end
	end
	if varData.ifStat then
		if not anyIfValue(varData.ifStat, function(opt)
			return mainEnv.perStatsUsed[opt] or mainEnv.enemyMultipliersUsed[opt] or implied()
		end) then return false end
	end
	if varData.ifFlag then
		if not mainSkill then return false end
		local skillFlags = mainSkill.skillFlags or {}
		local skillModList = mainSkill.skillModList
		if not anyIfValue(varData.ifFlag, function(opt)
			return skillFlags[opt] or (skillModList and skillModList:Flag(nil, opt))
		end) then return false end
	end
	if varData.ifSkill then
		local skillsUsed = mainEnv.skillsUsed or {}
		if varData.includeTransfigured then
			if not anyIfValue(varData.ifSkill, function(opt)
				if not calcLib.getGameIdFromGemName(opt, true) then return false end
				for skill, _ in pairs(skillsUsed) do
					if calcLib.isGemIdSame(skill, opt, true) then return true end
				end
				return false
			end) then return false end
		else
			if not anyIfValue(varData.ifSkill, function(opt) return skillsUsed[opt] end) then return false end
		end
	end
	if varData.ifSkillFlag or varData.ifSkillData then
		local skillList = (player and player.activeSkillList) or {}
		local function anySkillHas(field, opt)
			for _, s in ipairs(skillList) do
				if s[field][opt] then return true end
			end
			return false
		end
		if varData.ifSkillFlag and not anyIfValue(varData.ifSkillFlag, function(opt) return anySkillHas("skillFlags", opt) end) then return false end
		if varData.ifSkillData and not anyIfValue(varData.ifSkillData, function(opt) return anySkillHas("skillData", opt) end) then return false end
	end
	return true
end

-- Options with these properties or label keywords stay hidden even when "Show All Configurations" is on.
local function isShowAllExcluded(varData)
	if varData.ifOption or varData.ifSkill or varData.ifSkillData or varData.ifSkillFlag or varData.legacy then
		return true
	end
	if varData.label then
		local labelLower = varData.label:lower()
		for _, kw in ipairs(EXCLUDE_KEYWORDS) do
			if labelLower:find(kw) then return true end
		end
	end
	return false
end

return {
	isRelevantForBuild = isRelevantForBuild,
	isShowAllExcluded = isShowAllExcluded,
}
