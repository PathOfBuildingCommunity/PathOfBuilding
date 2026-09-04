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

local ConfigScope = require("Modules.ConfigScope")

local ACTOR_USED_FIELD = {
	conditionsUsed = "conditions",
	multipliersUsed = "multipliers",
	modsUsed = "mods",
	perStatsUsed = "perStats",
	minionConditionsUsed = "minionConditions",
	enemyConditionsUsed = "enemyConditions",
	enemyMultipliersUsed = "enemyMultipliers",
	enemyPerStatsUsed = "enemyPerStats",
}

local function usedForVar(mainEnv, envKey, varData, viewActor)
	if not mainEnv then
		return { }
	end
	local field = ACTOR_USED_FIELD[envKey]
	if field then
		local scope = ConfigScope.forVarData(varData)
		if scope == "actor" or scope == "player" then
			local actorKey = (scope == "actor" and viewActor == "mercenary") and "mercenary" or "player"
			local usage = mainEnv.actorUsage and mainEnv.actorUsage[actorKey]
			if usage then
				return usage[field] or { }
			end
		end
	end
	return mainEnv[envKey] or { }
end

local PRIMARY_ACTOR_KEYS = { "player", "mercenary" }

local function actorKeysForVar(varData, viewActor)
	local scope = ConfigScope.forVarData(varData)
	if scope == "shared" then
		return PRIMARY_ACTOR_KEYS
	end
	if scope == "player" or viewActor ~= "mercenary" then
		return { "player" }
	end
	return { "mercenary" }
end

local function formatUsedMods(mainEnv, envKey, varData, viewActor, ifOption)
	local mods = usedForVar(mainEnv, envKey, varData, viewActor)[ifOption]
	if not mods then
		return
	end
	local out
	for _, mod in ipairs(mods) do
		out = (out and out.."\n" or "") .. modLib.formatMod(mod) .. "|" .. mod.source
	end
	return out
end

local function formatCondTrue(mainEnv, varData, viewActor, ifOption)
	local keys = actorKeysForVar(varData, viewActor)
	if #keys == 1 then
		local actor = mainEnv and mainEnv[keys[1]]
		return "Condition state: " .. ifOption .. "=" .. tostring(actor and actor.modDB and actor.modDB.conditions[ifOption])
	end
	local out
	for _, actorKey in ipairs(keys) do
		local actor = mainEnv and mainEnv[actorKey]
		local value = actor and actor.modDB and actor.modDB.conditions[ifOption]
		local line = actorKey .. " " .. ifOption .. "=" .. tostring(value)
		out = (out and out.."\n" or "") .. line
	end
	return out and ("Condition state:\n" .. out) or ("Condition state: " .. ifOption .. "=nil")
end

local function anyPrimaryActor(mainEnv, predicate, actorKeys)
	for _, actorKey in ipairs(actorKeys or PRIMARY_ACTOR_KEYS) do
		local actor = mainEnv and mainEnv[actorKey]
		if actor and predicate(actor) then return true end
	end
	return false
end

local function anyMainSkill(mainEnv, predicate, actorKeys)
	return anyPrimaryActor(mainEnv, function(actor)
		return actor.mainSkill and predicate(actor.mainSkill)
	end, actorKeys)
end

local function anyActiveSkill(mainEnv, predicate, actorKeys)
	return anyPrimaryActor(mainEnv, function(actor)
		for _, activeSkill in ipairs(actor.activeSkillList or { }) do
			if predicate(activeSkill) then return true end
		end
		return false
	end, actorKeys)
end

local function actorUsesSkill(actor, ifOption, includeTransfigured)
	if not actor then
		return false
	end
	for _, activeSkill in ipairs(actor.activeSkillList or { }) do
		for _, skillEffect in ipairs(activeSkill.effectList or { }) do
			local name = skillEffect.grantedEffect and skillEffect.grantedEffect.name
			if name then
				if includeTransfigured then
					if calcLib.getGameIdFromGemName(ifOption, true) and calcLib.isGemIdSame(name, ifOption, true) then
						return true
					end
				elseif name == ifOption then
					return true
				end
			end
		end
	end
	return false
end

-- When the option has an input value and one of its implied conditions is currently used, treat gated predicates as passing.
local function optionValue(configTab, var, viewActor, input)
	if input then
		return input[var]
	end
	if viewActor and configTab and configTab.GetActorConfigInput then
		input = configTab:GetActorConfigInput(viewActor)
		return input and input[var]
	end
	if configTab and configTab.GetConfigValue then
		return configTab:GetConfigValue(var)
	end
	local activeSet = configTab and configTab.configSets and configTab.configSets[configTab.activeConfigSetId]
	return activeSet and activeSet.input and activeSet.input[var]
end

local function implyCondActive(varData, build, viewActor, input)
	local configTab = build and build.configTab
	if not configTab then return false end
	viewActor = viewActor or (configTab.GetViewActor and configTab:GetViewActor()) or "player"
	if not optionValue(configTab, varData.var, viewActor, input) then return false end
	local mainEnv = build.calcsTab and build.calcsTab.mainEnv
	if not mainEnv then return false end
	local conditionsUsed = usedForVar(mainEnv, "conditionsUsed", varData, viewActor)
	local minionConditionsUsed = usedForVar(mainEnv, "minionConditionsUsed", varData, viewActor)
	if varData.implyCondList then
		for _, implyCond in ipairs(varData.implyCondList) do
			if implyCond and conditionsUsed[implyCond] then return true end
		end
	end
	return (varData.implyCond and conditionsUsed[varData.implyCond])
		or (varData.implyMinionCond and minionConditionsUsed[varData.implyMinionCond])
		or (varData.implyEnemyCond and mainEnv.enemyConditionsUsed[varData.implyEnemyCond])
		or false
end

-- True if every `ifX` predicate on `varData` currently passes for `build`.
-- Actor-scoped options are evaluated for `viewActor`; shared options scan every primary actor.
local function isRelevantForBuild(varData, build, viewActor)
	if not build then return false end
	local mainEnv = build.calcsTab and build.calcsTab.mainEnv
	if not mainEnv then return false end
	local spec = build.spec
	local configTab = build.configTab
	viewActor = viewActor or "player"
	local actorInput
	if configTab and configTab.GetActorConfigInput then
		actorInput = configTab:GetActorConfigInput(viewActor)
	end
	local actorKeys = actorKeysForVar(varData, viewActor)

	local impliedCache
	local function implied()
		if impliedCache == nil then
			impliedCache = implyCondActive(varData, build, viewActor, actorInput) or false
		end
		return impliedCache
	end

	for _, p in ipairs(SIMPLE_PREDICATES) do
		local ifVal = varData[p.key]
		if ifVal then
			local envTable = usedForVar(mainEnv, p.env, varData, viewActor)
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
		if not anyIfValue(varData.ifOption, function(opt) return optionValue(configTab, opt, viewActor, actorInput) end) then return false end
	end
	if varData.ifCondTrue then
		if not anyIfValue(varData.ifCondTrue, function(opt)
			return anyPrimaryActor(mainEnv, function(actor) return actor.modDB.conditions[opt] end, actorKeys)
		end) then return false end
	end
	if varData.ifStat then
		if not anyIfValue(varData.ifStat, function(opt)
			return usedForVar(mainEnv, "perStatsUsed", varData, viewActor or "player")[opt] or mainEnv.enemyMultipliersUsed[opt] or implied()
		end) then return false end
	end
	if varData.ifFlag then
		if not anyIfValue(varData.ifFlag, function(opt)
			return anyMainSkill(mainEnv, function(mainSkill)
				return mainSkill.skillFlags[opt] or mainSkill.skillModList:Flag(nil, opt)
			end, actorKeys)
		end) then return false end
	end
	if varData.ifSkill then
		if not anyIfValue(varData.ifSkill, function(opt)
			return anyPrimaryActor(mainEnv, function(actor)
				return actorUsesSkill(actor, opt, varData.includeTransfigured)
			end, actorKeys)
		end) then return false end
	end
	if varData.ifSkillFlag or varData.ifSkillData then
		local function anySkillHas(field, opt)
			return anyActiveSkill(mainEnv, function(activeSkill) return activeSkill[field][opt] end, actorKeys)
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
	actorKeysForVar = actorKeysForVar,
	anyPrimaryActor = anyPrimaryActor,
	anyMainSkill = anyMainSkill,
	anyActiveSkill = anyActiveSkill,
	actorUsesSkill = actorUsesSkill,
	implyCondActive = implyCondActive,
	isRelevantForBuild = isRelevantForBuild,
	isShowAllExcluded = isShowAllExcluded,
	usedForVar = usedForVar,
	formatUsedMods = formatUsedMods,
	formatCondTrue = formatCondTrue,
}
