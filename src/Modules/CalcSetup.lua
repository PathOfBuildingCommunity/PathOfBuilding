-- Path of Building
--
-- Module: Calc Setup
-- Initialises the environment for calculations.
--
---@class Calcs
local calcs = require("Modules.CalcBase")
local MercenaryTools = require("Modules.MercenaryTools")
local ConfigScope = require("Modules.ConfigScope")

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local tempTable1 = { }

local mercenarySupportEffectCache = { }

local function mercenarySupportEffect(env, support, supportedEffect, errors)
	if not support then
		t_insert(errors, "Missing exported Mercenary support data")
		return
	end
	local cacheKey = supportedEffect and supportedEffect.id and (support.id .. "\0" .. supportedEffect.id)
	local cached = cacheKey and mercenarySupportEffectCache[cacheKey]
	if cached then
		return {
			grantedEffect = cached,
			level = 1,
			quality = 0,
			enabled = true,
			isSupporting = { },
		}
	end
	local errorCount = #errors
	local constantStats = { }
	local statMap = { }
	for _, stat in ipairs(support.stats or { }) do
		-- A support stat means whatever it means on the skill being supported, so that
		-- skill's own implementation wins over the shared fallback map. The fallback
		-- only holds stats whose meaning is the same everywhere.
		local implementation = supportedEffect.statMap[stat.id] or env.data.mercenarySupportStatMap[stat.id]
		if not implementation then
			t_insert(errors, "Unsupported Mercenary support stat: "..stat.id)
		else
			t_insert(constantStats, { stat.id, stat.value })
			statMap[stat.id] = copyTable(implementation, true)
			for _, modOrGroup in ipairs(statMap[stat.id]) do
				if modOrGroup.name then
					modOrGroup.source = "Mercenary Support:"..support.id
				else
					for _, mod in ipairs(modOrGroup) do mod.source = "Mercenary Support:"..support.id end
				end
			end
		end
	end
	local templateId = env.data.mercenaryStatData.supportTemplates[support.id]
	local template = templateId and env.data.skills[templateId]
	if templateId and not template then t_insert(errors, "Missing Mercenary support template: "..templateId) end
	local grantedEffect = {
		id = "MercenarySupport:"..support.id,
		name = support.name,
		modSource = "Mercenary Support:"..support.id,
		mercenarySupportId = support.id,
		support = true,
		requireSkillTypes = copyTable(template and template.requireSkillTypes or { }, true),
		excludeSkillTypes = copyTable(template and template.excludeSkillTypes or { }, true),
		addSkillTypes = copyTable(template and template.addSkillTypes or { }, true),
		addFlags = copyTable(template and template.addFlags or { }, true),
		weaponTypes = template and template.weaponTypes and copyTable(template.weaponTypes, true),
		ignoreMinionTypes = template and template.ignoreMinionTypes,
		isTrigger = template and template.isTrigger,
		baseFlags = { },
		skillTypes = { },
		constantStats = constantStats,
		stats = { },
		levels = { { levelRequirement = 1 } },
		statMap = statMap,
	}
	setmetatable(grantedEffect.statMap, env.data.skillStatMapMeta)
	grantedEffect.statMap._grantedEffect = grantedEffect
	if cacheKey and #errors == errorCount then
		mercenarySupportEffectCache[cacheKey] = grantedEffect
	end
	return {
		grantedEffect = grantedEffect,
		level = 1,
		quality = 0,
		enabled = true,
		isSupporting = { },
	}
end

local function validateMercenarySkillStats(env, grantedEffect, errors)
	local function validate(statId)
		if not grantedEffect.statMap[statId] and not env.data.knownUncalculatedSkillStats[statId] then
			t_insert(errors, "Unsupported Mercenary skill stat: "..statId.." ("..grantedEffect.id..")")
		end
	end
	for _, statId in ipairs(grantedEffect.stats or { }) do validate(statId) end
	for _, stat in ipairs(grantedEffect.constantStats or { }) do validate(stat[1]) end
	local baseEffect = grantedEffect.inheritedFrom and env.data.skills[grantedEffect.inheritedFrom]
	for _, message in ipairs(MercenaryTools.preDamageFuncErrors(grantedEffect, baseEffect, env.data.mercenaryStatData) or { }) do
		t_insert(errors, message)
	end
end

local function recordMercenaryAuxiliarySkill(env, auxiliarySkills, statId, selectedSkill)
	local auxiliarySkillId = env.data.mercenaryStatData.auxiliarySkills[statId]
	if auxiliarySkillId and not auxiliarySkills[auxiliarySkillId] then auxiliarySkills[auxiliarySkillId] = selectedSkill end
end

-- Hired Mercenaries treat Eldritch "while a Unique / Pinnacle Atlas Boss is in
-- your Presence" implicits as always active. That is a mercenary-item exception,
-- not a second encounter: shared RareOrUnique / PinnacleBoss on the enemy is
-- left alone, and "against unique enemies" mods still follow that encounter.
-- https://www.poewiki.net/wiki/Mercenary
local function mercenaryItemMod(mod, presenceImplicit)
	if mod.name == "ExtraSkill" or mod.name == "ExtraSupport" or mod.name == "SocketProperty" or mod.name == "GemProperty" or mod.name == "GroupProperty" then
		return
	end
	local copy = copyTable(mod, true)
	local index = 1
	while copy[index] do
		local tag = copy[index]
		if tag.type == "SocketedIn" then
			return
		elseif presenceImplicit and tag.type == "ActorCondition" and tag.actor == "enemy" and (tag.var == "RareOrUnique" or tag.var == "PinnacleBoss") then
			t_remove(copy, index)
		else
			index = index + 1
		end
	end
	return copy
end

local function addMercenaryItem(env, mercenary, item, slotName, slotNum)
	mercenary.itemList[slotName] = item
	local emptySockets = { R = 0, G = 0, B = 0, W = 0 }
	for _, socket in ipairs(item.sockets or { }) do
		if emptySockets[socket.color] then emptySockets[socket.color] = emptySockets[socket.color] + 1 end
	end
	mercenary.modDB.multipliers["EmptySocketIn"..slotName] = emptySockets.R + emptySockets.G + emptySockets.B + emptySockets.W
	for color, name in pairs({ R = "Red", G = "Green", B = "Blue", W = "White" }) do
		local multiplier = "Empty"..name.."SocketsInAnySlot"
		mercenary.modDB.multipliers[multiplier] = (mercenary.modDB.multipliers[multiplier] or 0) + emptySockets[color]
	end
	local presenceImplicitCounts = { }
	for _, modLine in ipairs(item.implicitModLines or { }) do
		if modLine.line and modLine.line:lower():match("^while .+ in your presence") then
			for _, implicitMod in ipairs(modLine.modList or { }) do
				local key = modLib.formatMod(implicitMod)
				presenceImplicitCounts[key] = (presenceImplicitCounts[key] or 0) + 1
			end
		end
	end
	for _, itemMod in ipairs(item.modList or item.slotModList[slotNum]) do
		local key = modLib.formatMod(itemMod)
		local presenceImplicit = (presenceImplicitCounts[key] or 0) > 0
		if presenceImplicit then presenceImplicitCounts[key] = presenceImplicitCounts[key] - 1 end
		local mod = mercenaryItemMod(itemMod, presenceImplicit)
		if mod then mercenary.modDB:AddMod(mod) end
	end
	local rarity = (item.rarity == "UNIQUE" or item.rarity == "RELIC") and "UniqueItem" or item.rarity == "RARE" and "RareItem" or item.rarity == "MAGIC" and "MagicItem" or "NormalItem"
	mercenary.modDB.multipliers[rarity] = (mercenary.modDB.multipliers[rarity] or 0) + 1
	mercenary.modDB.conditions[rarity.."In"..slotName] = true
end

local function addMercenaryMonsterStats(env, mercenary, monster, errors)
	local rawStats = { }
	for _, stat in ipairs(monster.stats or { }) do
		if not env.data.mercenaryStatData.knownMonsterStats[stat.id] then
			t_insert(errors, "Unsupported Mercenary monster stat: "..stat.id)
		end
		rawStats[stat.id] = (rawStats[stat.id] or 0) + stat.value
	end
	mercenary.modDB:NewMod("MaximumRage", "BASE", rawStats.maximum_rage or env.data.characterConstants["maximum_rage"], "Mercenary")
	mercenary.modDB:NewMod("ActiveTrapLimit", "BASE", rawStats.base_number_of_traps_allowed or env.data.characterConstants["base_number_of_traps_allowed"], "Mercenary")
	mercenary.modDB:NewMod("ActiveMineLimit", "BASE", rawStats.base_number_of_remote_mines_allowed or env.data.characterConstants["base_number_of_remote_mines_allowed"], "Mercenary")
	mercenary.modDB:NewMod("ActiveTotemLimit", "BASE", env.data.characterConstants["base_number_of_totems_allowed"] + (rawStats.number_of_additional_totems_allowed or 0), "Mercenary")
	mercenary.modDB:NewMod("LifeRegenPercent", "BASE", (rawStats["life_regeneration_per_minute_%_for_hired_mercenary_out_of_combat_window"] or 0) / 60, "Mercenary")
	mercenary.modDB:NewMod("ManaCost", "INC", -(rawStats["set_base_mana_cost_-%"] or 0), "Mercenary")
	mercenary.modDB:NewMod("ManaRegen", "BASE", (rawStats.base_mana_regeneration_rate_per_minute or 0) / 60, "Mercenary")
	mercenary.modDB:NewMod("TotemLife", "MORE", rawStats["set_totem_life_+%_final"] or 0, "Mercenary")
	mercenary.modDB:NewMod("DamageTaken", "INC", rawStats["set_minion_damage_taken_+%"] or 0, "Mercenary")
	mercenary.modDB:NewMod("DamageTaken", "MORE", env.data.mercenaryStatData.permanentMercenary.damageOverTimeTakenMore, "Mercenary", ModFlag.Dot)
	-- Rarity stats correct engine rarity bonuses; this normalized actor applies neither side.
	if monster.damageFixup then
		mercenary.modDB:NewMod("Damage", "MORE", -100 * monster.damageFixup, "Damage Fixup", ModFlag.Attack)
		mercenary.modDB:NewMod("Speed", "MORE", 100 * monster.damageFixup, "Damage Fixup", ModFlag.Attack)
	end
	if rawStats.keystone_minion_instability == 1 then
		mercenary.modDB:NewMod("Keystone", "LIST", "Minion Instability", "Mercenary")
	end
end

-- parseMod is not cheap; mercenary passives are rebuilt on every real initEnv.
local mercenaryPassiveModCache = { }

local function addMercenaryPassiveStats(mercenary, mercenaryBuild, errors)
	mercenary.passiveStats = { }
	for _, passive in ipairs(mercenaryBuild.passiveStats or { }) do
		local value = MercenaryTools.passiveStatValue(passive.values, mercenary.level)
		local scaledValue = value / (passive.divisor or 1)
		local valueText = scaledValue == m_floor(scaledValue) and tostring(m_floor(scaledValue)) or tostring(scaledValue)
		local line = passive.line or string.format(passive.format, valueText)
		if not passive.line or value ~= 0 then
			local cached = mercenaryPassiveModCache[line]
			if cached == nil then
				local parsed, extra = modLib.parseMod(line)
				if not parsed or extra then
					mercenaryPassiveModCache[line] = false
					cached = false
				else
					mercenaryPassiveModCache[line] = parsed
					cached = parsed
				end
			end
			if not cached then
				t_insert(errors, "Unsupported Mercenary passive stat "..passive.id..": "..line)
			else
				local source = "Mercenary Passive: "..passive.id
				for _, mod in ipairs(cached) do
					mercenary.modDB:AddMod(modLib.setSource(copyTable(mod, true), source))
				end
			end
		end
		t_insert(mercenary.passiveStats, { id = passive.id, statId = passive.statId, value = scaledValue })
	end
end

function calcs.attachEnemySourceDB(env, actor, sourceModList)
	if not actor then
		return
	end
	local hasSource = sourceModList and sourceModList[1] ~= nil
	local encounterList = actor == env.player and env.build.configTab.enemyModList
	local sourceDB = actor.enemySourceDB
	if sourceDB then
		wipeTable(sourceDB.mods)
		wipeTable(sourceDB.conditions)
		wipeTable(sourceDB.multipliers)
	else
		sourceDB = new("ModDB"):ModDB()
		actor.enemySourceDB = sourceDB
	end
	sourceDB.actor = actor
	sourceDB.conditions.Combat = env.mode_combat
	sourceDB.conditions.Effective = env.mode_effective
	if hasSource then
		sourceDB:AddList(sourceModList)
	end
	-- Player "by you" mods that reuse encounter names (Ignited, WitheredStack, ...)
	-- still honour the shared config checkboxes. Mercenary overlays do not copy
	-- those predicates, so they cannot claim the player's ailments as their own.
	if actor == env.player then
		for _, mod in ipairs(encounterList or { }) do
			if ConfigScope.shouldCopyEncounterOntoPlayerOverlay(mod) then
				sourceDB:AddMod(mod)
			end
		end
	end
end

local function recycleModDB(db)
	if not db then
		return nil
	end
	wipeTable(db.mods)
	wipeTable(db.conditions)
	wipeTable(db.multipliers)
	db.parent = nil
	-- The previous actor graph must not stay reachable from a parked overlay.
	db.actor = nil
	return db
end

local function dropRecycledMercenary(env)
	env.recycledMercenaryModDB = nil
	env.recycledMercenaryItemModDB = nil
	env.recycledMercenaryEnemySourceDB = nil
end

local function parkRecycledMercenary(env, modDB, itemModDB, enemySourceDB)
	env.recycledMercenaryModDB = recycleModDB(modDB)
	env.recycledMercenaryItemModDB = recycleModDB(itemModDB)
	env.recycledMercenaryEnemySourceDB = recycleModDB(enemySourceDB)
end

local function dropCachedMercenary(env)
	env.cachedMercenaryModDB = nil
	env.cachedMercenaryEnemySourceDB = nil
	env.cachedMercenaryItemModDB = nil
	env.cachedMercenaryMinionModDBs = nil
	env.cachedMercenaryMainSkill = nil
	env.mercenaryFromCache = nil
end

local function copyModDB(db)
	if not db then
		return nil
	end
	local copy = new("ModDB"):ModDB()
	copy:AddDB(db)
	copy.conditions = copyTable(db.conditions)
	copy.multipliers = copyTable(db.multipliers)
	return copy
end

local function parentModDB(db, cached, actor)
	if not db then
		return
	end
	wipeTable(db.mods)
	wipeTable(db.conditions)
	wipeTable(db.multipliers)
	db.parent = cached
	db.actor = actor
end

local preservedSkillDataKeys = {
	"manaReservationPercent", "cooldown", "storedUses", "CritChance",
	"attackTime", "attackSpeedMultiplier", "totemLevel", "damageEffectiveness", "stagesMax",
}

local function resetActiveSkillData(modDB, activeSkill)
	if not activeSkill then
		return
	end
	local skillData = activeSkill.skillData or { }
	activeSkill.skillData = { }
	if modDB and activeSkill.skillCfg then
		for _, value in ipairs(modDB:List(activeSkill.skillCfg, "SkillData")) do
			activeSkill.skillData[value.key] = value.value
		end
	end
	if activeSkill.skillModList and activeSkill.skillCfg then
		for _, value in ipairs(activeSkill.skillModList:List(activeSkill.skillCfg, "SkillData")) do
			activeSkill.skillData[value.key] = value.value
		end
	end
	for _, key in ipairs(preservedSkillDataKeys) do
		if skillData[key] ~= nil then
			activeSkill.skillData[key] = skillData[key]
		end
	end
	activeSkill.skillData.soulPreventionDuration = activeSkill.soulPreventionDuration or skillData.soulPreventionDuration
	if activeSkill.skillCfg and activeSkill.skillCfg.skillCond then
		activeSkill.skillCfg.skillCond.usedByMirage = nil
	end
end

-- Snapshot taken after initMercenary and before perform(). Full DPS reuses it
-- instead of reconstructing items/passives/skills on every player skill.
local function cacheMercenaryBaseline(env)
	dropCachedMercenary(env)
	local mercenary = env.mercenary
	if not mercenary then
		return
	end
	env.cachedMercenaryModDB = copyModDB(mercenary.modDB)
	env.cachedMercenaryEnemySourceDB = copyModDB(mercenary.enemySourceDB)
	env.cachedMercenaryItemModDB = mercenary.calcEnv and copyModDB(mercenary.calcEnv.itemModDB)
	env.cachedMercenaryMainSkill = mercenary.mainSkill
	env.cachedMercenaryMinionModDBs = { }
	for index, skill in ipairs(mercenary.activeSkillList) do
		if skill.minion and skill.minion.modDB then
			env.cachedMercenaryMinionModDBs[index] = copyModDB(skill.minion.modDB)
		end
	end
end

local function restoreCachedMercenary(env)
	local mercenary = env.mercenary
	if not mercenary or not env.cachedMercenaryModDB then
		return false
	end
	parentModDB(mercenary.modDB, env.cachedMercenaryModDB, mercenary)
	if mercenary.enemySourceDB then
		parentModDB(mercenary.enemySourceDB, env.cachedMercenaryEnemySourceDB, mercenary)
	end
	if mercenary.calcEnv and mercenary.calcEnv.itemModDB then
		parentModDB(mercenary.calcEnv.itemModDB, env.cachedMercenaryItemModDB, mercenary)
	end
	mercenary.mainSkill = env.cachedMercenaryMainSkill
	env.mercenaryMinion = nil
	if mercenary.calcEnv then
		mercenary.calcEnv.minion = false
	end
	for index, skill in ipairs(mercenary.activeSkillList) do
		resetActiveSkillData(mercenary.modDB, skill)
		local minion = skill.minion
		if minion and minion.modDB then
			parentModDB(minion.modDB, env.cachedMercenaryMinionModDBs and env.cachedMercenaryMinionModDBs[index], minion)
			for _, minionSkill in ipairs(minion.activeSkillList or { }) do
				resetActiveSkillData(minion.modDB, minionSkill)
			end
		end
	end
	env.mercenaryFromCache = true
	return true
end

local function parkCurrentMercenary(env)
	dropCachedMercenary(env)
	if env.mercenary then
		parkRecycledMercenary(env, env.mercenary.modDB, env.mercenary.calcEnv and env.mercenary.calcEnv.itemModDB, env.mercenary.enemySourceDB)
	else
		dropRecycledMercenary(env)
	end
	env.mercenary = nil
	env.mercenaryMinion = nil
	env.mercenaryCalculationErrors = nil
end

-- Mercenary calculations reuse upstream actor-aware calculation functions, some of
-- which still access env.player. Actor-local environment values therefore need
-- explicit substitution while encounter-wide state remains shared.
-- Fields that must never fall through a proxy env to another actor.
-- Add a key here when Mercenary calculation reads it and the value is actor-owned.
-- createActorCalcEnv refuses to construct a proxy that omits them, and errors if they are read unset.
calcs.ACTOR_LOCAL_ENV_KEYS = {
	"player",
	"modDB",
	"configInput",
	"configPlaceholder",
	"keystonesAdded",
	"minion",
	"itemModDB",
	"auxSkillList",
	"theIronMass",
}

-- Encounter/build state that Mercenary calculation actually reads through the proxy
-- and that is semantically shared. Unclassified root fields error on access.
calcs.ACTOR_SHARED_ENV_KEYS = {
	"build",
	"data",
	"enemy",
	"enemyLevel",
	"limitedSkills",
	"mode",
	"mode_buffs",
	"mode_combat",
	"mode_effective",
	"override",
	"partyMembers",
	"spec",
}

local actorLocalEnvKeySet = { }
for _, key in ipairs(calcs.ACTOR_LOCAL_ENV_KEYS) do
	actorLocalEnvKeySet[key] = true
end

local actorSharedEnvKeySet = { }
for _, key in ipairs(calcs.ACTOR_SHARED_ENV_KEYS) do
	if actorLocalEnvKeySet[key] then
		error("Calc env field '"..key.."' cannot be both actor-local and shared")
	end
	actorSharedEnvKeySet[key] = true
end

-- Build an actor-scoped calculation environment over `rootEnv`.
-- Inheritable encounter/build state is read from the root; actor-local
-- fields must be supplied on `actorFields` (use `false` rather than nil
-- when the actor has no value, so __index cannot leak the root actor).
function calcs.createActorCalcEnv(rootEnv, actorFields)
	if not rootEnv then
		error("createActorCalcEnv requires a root environment")
	end
	actorFields = actorFields or { }
	for _, key in ipairs(calcs.ACTOR_LOCAL_ENV_KEYS) do
		if actorFields[key] == nil then
			error("createActorCalcEnv: missing actor-local field '"..key.."'")
		end
	end
	for _, key in ipairs(calcs.ACTOR_SHARED_ENV_KEYS) do
		if actorFields[key] == nil then
			local value = rootEnv[key]
			if value ~= nil then
				actorFields[key] = value
			end
		end
	end
	return setmetatable(actorFields, {
		__index = function(_, key)
			if actorLocalEnvKeySet[key] then
				error("createActorCalcEnv: actor-local field '"..key.."' is unset")
			end
			if actorSharedEnvKeySet[key] then
				return rootEnv[key]
			end
			if rawget(rootEnv, key) ~= nil then
				error("createActorCalcEnv: unclassified env field '"..key.."'")
			end
		end,
	})
end

function calcs.initMercenary(env)
	local tab = env.build.mercenaryTab
	if not tab or not tab.profile or not tab.profile.buildId then
		env.mercenary = nil
		env.mercenaryMinion = nil
		env.mercenaryCalculationErrors = nil
		dropRecycledMercenary(env)
		dropCachedMercenary(env)
		return
	end
	env.data.ensureMercenaries()
	local recycledModDB = env.recycledMercenaryModDB
	local recycledItemModDB = env.recycledMercenaryItemModDB
	local recycledEnemySourceDB = env.recycledMercenaryEnemySourceDB
	dropRecycledMercenary(env)
	dropCachedMercenary(env)
	env.mercenary = nil
	env.mercenaryMinion = nil
	env.mercenaryCalculationErrors = nil

	local function abortInit(errors)
		env.mercenaryCalculationErrors = errors
		dropCachedMercenary(env)
		parkRecycledMercenary(env, recycledModDB, recycledItemModDB, recycledEnemySourceDB)
	end

	local profile = tab.profile
	local profileErrors = MercenaryTools.validateProfile(profile, env.data.mercenaries)
	if #profileErrors > 0 then
		abortInit(profileErrors)
		return
	end
	local mercenaryBuild = env.data.mercenaries.builds[profile.buildId]
	local mercenaryClass = mercenaryBuild and env.data.mercenaries.classes[mercenaryBuild.classId]
	local monster = mercenaryClass and mercenaryClass.monster
	local calculationErrors = { }
	if not monster then
		abortInit({ "Selected Mercenary has no allied MonsterVariety data" })
		return
	end
	local itemsTab = env.build.itemsTab
	local itemSet = tab:GetItemSet(false)
	local selectedItemSet = env.override.itemSetId and itemsTab.itemSets[env.override.itemSetId]
	if selectedItemSet and tab.itemSetId == selectedItemSet.id then
		itemSet = selectedItemSet
	end
	if not itemSet then
		abortInit({ "No Mercenary item set is available" })
		return
	end
	local equipmentErrors = MercenaryTools.equipmentErrors({
		profile = profile,
		mercenaryData = env.data.mercenaries,
		itemSet = itemSet,
		playerItemSet = itemsTab.activeItemSet,
		items = itemsTab.items,
		playerHasFlag = function(flagName) return env.modDB:Flag(nil, flagName) end,
		isItemValidForSlot = function(item, slotName, set)
			return itemsTab:IsItemValidForSlot(item, slotName, set)
		end,
	})
	if #equipmentErrors > 0 then
		abortInit(equipmentErrors)
		return
	end
	-- Permanent hiring is a Luminary/Noble Blood capability. Keep the
	-- configured profile for editing, but do not construct an actor that
	-- would enter the player calculation graph.
	if not env.modDB:Flag(nil, "CanHirePermanentMercenary") then
		parkRecycledMercenary(env, recycledModDB, recycledItemModDB, recycledEnemySourceDB)
		return
	end
	local mercenary = {
		type = "Mercenary",
		isMercenary = true,
		player = env.player,
		parent = env.player,
		enemy = env.enemy,
		level = MercenaryTools.effectiveLevel(profile.foundAreaLevel, env.enemyLevel),
		foundAreaLevel = profile.foundAreaLevel,
		itemList = { },
		activeSkillList = { },
		profile = profile,
		monster = monster,
	}
	mercenary.modDB = recycledModDB or new("ModDB"):ModDB()
	mercenary.modDB.actor = mercenary
	mercenary.modDB.multipliers.Level = mercenary.level
	calcs.initModDB(env, mercenary.modDB)
	if env.build.configTab.mercenaryModList then
		mercenary.modDB:AddList(env.build.configTab.mercenaryModList)
	end
	mercenary.enemySourceDB = recycledEnemySourceDB
	calcs.attachEnemySourceDB(env, mercenary, env.build.configTab.mercenaryEnemyModList)
	local baseStats = env.data.mercenaries.baseStats
	mercenary.modDB:NewMod("Life", "BASE", baseStats.lifePerLevel * mercenary.level, "Base")
	mercenary.modDB:NewMod("Mana", "BASE", env.data.monsterConstants.base_maximum_mana + baseStats.manaPerLevel * mercenary.level, "Base")
	mercenary.modDB:NewMod("Accuracy", "BASE", baseStats.accuracyPerLevel * mercenary.level, "Base")
	if not baseStats.disableDefaultMonsterStats then
		mercenary.modDB:NewMod("Armour", "BASE", round(env.data.monsterArmourTable[mercenary.level] * monster.armour), "Base")
		mercenary.modDB:NewMod("Evasion", "BASE", round(env.data.monsterEvasionTable[mercenary.level] * monster.evasion), "Base")
	end
	mercenary.modDB:NewMod("CritMultiplier", "BASE", env.data.monsterConstants["base_critical_strike_multiplier"] - 100, "Base")
	mercenary.modDB:NewMod("DotMultiplier", "BASE", env.data.monsterConstants["critical_ailment_dot_multiplier_+"], "Base", { type = "Condition", var = "CriticalStrike" })
	mercenary.modDB:NewMod("FireResist", "BASE", monster.fireResist, "Base")
	mercenary.modDB:NewMod("ColdResist", "BASE", monster.coldResist, "Base")
	mercenary.modDB:NewMod("LightningResist", "BASE", monster.lightningResist, "Base")
	mercenary.modDB:NewMod("ChaosResist", "BASE", monster.chaosResist, "Base")
	mercenary.modDB:NewMod("CritChance", "INC", env.data.characterConstants["critical_strike_chance_+%_per_power_charge"], "Base", { type = "Multiplier", var = "PowerCharge" })
	mercenary.modDB:NewMod("Speed", "INC", env.data.characterConstants["base_attack_speed_+%_per_frenzy_charge"], "Base", ModFlag.Attack, { type = "Multiplier", var = "FrenzyCharge" })
	mercenary.modDB:NewMod("Speed", "INC", env.data.characterConstants["base_cast_speed_+%_per_frenzy_charge"], "Base", ModFlag.Cast, { type = "Multiplier", var = "FrenzyCharge" })
	mercenary.modDB:NewMod("Damage", "MORE", env.data.characterConstants["object_inherent_damage_+%_final_per_frenzy_charge"], "Base", { type = "Multiplier", var = "FrenzyCharge" })
	mercenary.modDB:NewMod("PhysicalDamageReduction", "BASE", env.data.characterConstants["physical_damage_reduction_%_per_endurance_charge"], "Base", { type = "Multiplier", var = "EnduranceCharge" })
	mercenary.modDB:NewMod("ElementalDamageReduction", "BASE", env.data.characterConstants["elemental_damage_reduction_%_per_endurance_charge"], "Base", { type = "Multiplier", var = "EnduranceCharge" })
	mercenary.modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
	mercenary.modDB:NewMod("MineThrowCount", "BASE", 1, "Base")
	mercenary.modDB:NewMod("TrapThrowCount", "BASE", 1, "Base")
	mercenary.modDB:NewMod("MaximumFortification", "BASE", env.data.characterConstants["base_max_fortification"], "Base")
	mercenary.modDB:NewMod("Damage", "MORE", MercenaryTools.permanentDamageMore(mercenary.level, env.data.mercenaries.permanentMercenaryDamageMore), "Permanent Mercenary")
	addMercenaryMonsterStats(env, mercenary, monster, calculationErrors)
	addMercenaryPassiveStats(mercenary, mercenaryBuild, calculationErrors)
	for _, value in ipairs(env.modDB:List(nil, "MercenaryModifier")) do
		mercenary.modDB:AddMod(value.mod)
	end

	for _, slotName in ipairs(MercenaryTools.equipmentSlots) do
		local slot = env.build.itemsTab.slots[slotName]
		local item
		if MercenaryTools.overrideReplacesMercenarySlot(env.override, slotName, tab.itemSetId) then
			item = env.override.repItem
		else
			item = itemSet and itemSet[slotName] and env.build.itemsTab.items[itemSet[slotName].selItemId]
		end
		if item then addMercenaryItem(env, mercenary, item, slotName, slot and slot.slotNum or 1) end
		for abyssalSocketIndex = 1, 6 do
			local abyssalSlotName = slotName.." Abyssal Socket "..abyssalSocketIndex
			local abyssalJewel
			if MercenaryTools.overrideReplacesMercenarySlot(env.override, abyssalSlotName, tab.itemSetId) then
				abyssalJewel = env.override.repItem
			else
				local abyssalSetSlot = itemSet and itemSet[abyssalSlotName]
				abyssalJewel = abyssalSetSlot and env.build.itemsTab.items[abyssalSetSlot.selItemId]
			end
			if abyssalJewel then addMercenaryItem(env, mercenary, abyssalJewel, abyssalSlotName, abyssalSocketIndex) end
		end
	end
	for _, passiveName in ipairs(mercenary.modDB:List(nil, "GrantedPassive")) do
		local node = env.spec.tree.notableMap[passiveName] or env.spec.tree.ascendancyMap[passiveName]
			or env.build.latestTree.notableMap[passiveName] or env.build.latestTree.ascendancyMap[passiveName]
		if node then
			mercenary.modDB:AddList((env.spec.nodes[node.id] or node).modList)
		else
			t_insert(calculationErrors, "Unsupported Mercenary anoint: "..tostring(passiveName))
		end
	end
	for _, keystoneName in ipairs(mercenary.modDB:List(nil, "Keystone")) do
		if not env.spec.tree.keystoneMap[keystoneName] and not env.build.latestTree.keystoneMap[keystoneName] then
			t_insert(calculationErrors, "Unsupported Mercenary keystone: "..tostring(keystoneName))
		end
	end

	local attackTime = monster.attackTime
	-- Only reached while a weapon slot is empty. `disable_default_monster_stats` has
	-- no per-level replacement for damage, so an unarmed Mercenary keeps the same
	-- allied-monster damage model PoB uses for minions.
	mercenary.averageDamage = env.data.monsterAllyDamageTable[mercenary.level] * monster.damage
	local damage = mercenary.averageDamage
	if not monster.baseDamageIgnoresAttackSpeed then damage = damage * attackTime end
	mercenary.weaponData1 = mercenary.itemList["Weapon 1"] and mercenary.itemList["Weapon 1"].weaponData and mercenary.itemList["Weapon 1"].weaponData[1] or {
		type = "None",
		AttackRate = 1 / attackTime,
		CritChance = 5,
		PhysicalMin = round(damage * (1 - monster.damageSpread)),
		PhysicalMax = round(damage * (1 + monster.damageSpread)),
		range = monster.attackRange,
	}
	mercenary.weaponData2 = mercenary.itemList["Weapon 2"] and mercenary.itemList["Weapon 2"].weaponData and mercenary.itemList["Weapon 2"].weaponData[2] or { }

	-- Skill building reads `env.player` and `env.modDB` for the actor that owns the
	-- skill. This proxy environment presents the Mercenary as that actor while
	-- inheritable encounter/build state still falls through to the real environment.
	-- Invariant: `mercenaryEnv.player` is the Mercenary; `env.player` is always
	-- the character. `mercenaryEnv.minion` is the Mercenary minion or false.
	-- false (not nil) prevents __index from returning the player's minion.
	local mercInput, mercPlaceholder = { }, { }
	if env.build.configTab.GetActorConfigInput then
		-- GetActorConfigInput reuses its merge buffers; snapshot before the next call.
		mercInput, mercPlaceholder = env.build.configTab:GetActorConfigInput("mercenary")
		mercInput = copyTable(mercInput)
		mercPlaceholder = copyTable(mercPlaceholder)
	end
	local mercenaryEnv = calcs.createActorCalcEnv(env, {
		modDB = mercenary.modDB,
		player = mercenary,
		keystonesAdded = { },
		minion = false,
		configInput = mercInput,
		configPlaceholder = mercPlaceholder,
		itemModDB = recycledItemModDB or new("ModDB"):ModDB(),
		auxSkillList = { },
		theIronMass = false,
	})
	mercenary.calcEnv = mercenaryEnv
	local function addActiveSkill(selectedSkill, grantedEffect, supports, isPrimary, sourceItem)
		local skillPart = isPrimary and selectedSkill.skillPart or env.data.mercenaryStatData.defaultSkillParts[grantedEffect.id] or 1
		if grantedEffect.parts and (skillPart < 1 or skillPart > #grantedEffect.parts) then
			t_insert(calculationErrors, "Invalid Mercenary skill part for "..grantedEffect.id..": "..tostring(skillPart))
			return
		end
		local instance = {
			skillId = grantedEffect.id,
			level = sourceItem and (sourceItem.level or mercenary.level) or MercenaryTools.skillLevel(grantedEffect, mercenary.level),
			quality = 0,
			enabled = true,
			mercenarySkill = selectedSkill,
			fromItem = sourceItem ~= nil,
			sourceItem = sourceItem,
			skillPart = skillPart,
			skillStageCount = isPrimary and selectedSkill.skillStageCount or nil,
			skillMineCount = isPrimary and selectedSkill.skillMineCount or nil,
			skillMinionSkill = isPrimary and selectedSkill.skillMinionSkill or nil,
			skillMinionSkillCalcs = isPrimary and (selectedSkill.skillMinionSkillCalcs or selectedSkill.skillMinionSkill) or nil,
			mercenaryPossibleSupportIds = env.data.mercenaries.skills[grantedEffect.id] and env.data.mercenaries.skills[grantedEffect.id].possibleSupportIds,
		}
		local activeSkill = calcs.createActiveSkill({ grantedEffect = grantedEffect, level = instance.level, quality = 0, srcInstance = instance }, supports or { }, mercenary, selectedSkill)
		activeSkill.mercenarySkill = selectedSkill
		activeSkill.isMercenaryPrimary = isPrimary
		activeSkill.sourceItem = sourceItem
		activeSkill.isMercenaryAuxiliary = not isPrimary
		calcs.buildActiveSkillModList(mercenaryEnv, activeSkill)
		if activeSkill.unsupportedReason then
			t_insert(calculationErrors, activeSkill.unsupportedReason)
		else
			t_insert(mercenary.activeSkillList, activeSkill)
		end
		return activeSkill
	end
	local auxiliarySkills = { }
	for _, selectedSkill in ipairs(profile.skills) do
		if selectedSkill.enabled ~= false then
			local grantedEffect = env.data.skills[selectedSkill.id]
			if not grantedEffect then
				t_insert(calculationErrors, "Missing generated Mercenary skill: "..tostring(selectedSkill.id))
			else
				validateMercenarySkillStats(env, grantedEffect, calculationErrors)
				for _, statId in ipairs(grantedEffect.stats or { }) do
					recordMercenaryAuxiliarySkill(env, auxiliarySkills, statId, selectedSkill)
				end
				for _, stat in ipairs(grantedEffect.constantStats or { }) do
					recordMercenaryAuxiliarySkill(env, auxiliarySkills, stat[1], selectedSkill)
				end
				local supports = { }
				for _, selectedSupport in ipairs(selectedSkill.supports or { }) do
					local support = env.data.mercenaries.supports[selectedSupport.id]
					local supportEffect = mercenarySupportEffect(env, support, grantedEffect, calculationErrors)
					if supportEffect then t_insert(supports, supportEffect) end
					for _, stat in ipairs(support and support.stats or { }) do
						recordMercenaryAuxiliarySkill(env, auxiliarySkills, stat.id, selectedSkill)
					end
				end
				local activeSkill = addActiveSkill(selectedSkill, grantedEffect, supports, true)
				if selectedSkill.id == profile.mainSkillId then mercenary.mainSkill = activeSkill end
			end
		end
	end
	local auxiliarySkillIds = { }
	for auxiliarySkillId in pairs(auxiliarySkills) do t_insert(auxiliarySkillIds, auxiliarySkillId) end
	t_sort(auxiliarySkillIds)
	for _, auxiliarySkillId in ipairs(auxiliarySkillIds) do
		local auxiliaryEffect = env.data.skills[auxiliarySkillId]
		if auxiliaryEffect then
			validateMercenarySkillStats(env, auxiliaryEffect, calculationErrors)
			addActiveSkill(auxiliarySkills[auxiliarySkillId], auxiliaryEffect, nil, false)
		else
			t_insert(calculationErrors, "Missing Mercenary auxiliary skill: "..auxiliarySkillId)
		end
	end
	if not mercenary.mainSkill then
		t_insert(calculationErrors, "Configured Mercenary main skill could not be constructed: "..tostring(profile.mainSkillId))
	end
	if #calculationErrors > 0 then
		env.mercenaryCalculationErrors = calculationErrors
		return
	end
	env.mercenary = mercenary
end

-- Initialise modifier database with stats and conditions common to all actors
function calcs.initModDB(env, modDB)
	modDB:NewMod("FireResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("ColdResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("LightningResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("ChaosResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("TotemFireResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("TotemColdResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("TotemLightningResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("TotemChaosResistMax", "BASE", data.characterConstants["base_maximum_all_resistances_%"], "Base")
	modDB:NewMod("BlockChanceMax", "BASE", data.characterConstants["maximum_block_%"], "Base")
	modDB:NewMod("SpellBlockChanceMax", "BASE", data.characterConstants["base_maximum_spell_block_%"], "Base")
	modDB:NewMod("SpellDodgeChanceMax", "BASE", 75, "Base")
	modDB:NewMod("ChargeDuration", "BASE", 10, "Base")
	modDB:NewMod("PowerChargesMax", "BASE", data.characterConstants["max_power_charges"], "Base")
	modDB:NewMod("FrenzyChargesMax", "BASE", data.characterConstants["max_frenzy_charges"], "Base")
	modDB:NewMod("EnduranceChargesMax", "BASE", data.characterConstants["max_endurance_charges"], "Base")
	modDB:NewMod("SiphoningChargesMax", "BASE", 0, "Base")
	modDB:NewMod("ChallengerChargesMax", "BASE", 0, "Base")
	modDB:NewMod("BlitzChargesMax", "BASE", 0, "Base")
	modDB:NewMod("InspirationChargesMax", "BASE", data.characterConstants["maximum_righteous_charges"], "Base")
	modDB:NewMod("CrabBarriersMax", "BASE", 0, "Base")
	modDB:NewMod("BrutalChargesMax", "BASE", 0, "Base")
	modDB:NewMod("BrineChargesMax", "BASE", 0, "Base")
	modDB:NewMod("PhysicalDamageGainAsCold", "BASE", data.characterConstants["physical_damage_%_to_add_as_cold_per_brine_charge"], "Base", { type = "Multiplier", var = "BrineCharge" })
	modDB:NewMod("PhysicalDamageGainAsLightning", "BASE", data.characterConstants["physical_damage_%_to_add_as_lightning_per_brine_charge"], "Base", { type = "Multiplier", var = "BrineCharge" })
	modDB:NewMod("AbsorptionChargesMax", "BASE", 0, "Base")
	modDB:NewMod("AfflictionChargesMax", "BASE", 0, "Base")
	modDB:NewMod("BloodChargesMax", "BASE", data.characterConstants["maximum_blood_scythe_charges"], "Base")
	modDB:NewMod("MaxLifeLeechRate", "BASE", data.characterConstants["maximum_life_leech_rate_%_per_minute"] / 60, "Base")
	modDB:NewMod("MaxManaLeechRate", "BASE", data.characterConstants["maximum_mana_leech_rate_%_per_minute"] / 60, "Base")
	modDB:NewMod("ImpaleStacksMax", "BASE", data.characterConstants["impaled_debuff_number_of_reflected_hits"], "Base")
	modDB:NewMod("SoulEaterMax", "BASE", data.characterConstants["soul_eater_maximum_stacks"], "Base")
	modDB:NewMod("BleedStacksMax", "BASE", 1, "Base")
	modDB:NewMod("MaxEnergyShieldLeechRate", "BASE", 10, "Base")
	modDB:NewMod("MaxLifeLeechInstance", "BASE", data.characterConstants["maximum_life_leech_amount_per_leech_%_max_life"] , "Base")
	modDB:NewMod("MaxManaLeechInstance", "BASE", data.characterConstants["maximum_mana_leech_amount_per_leech_%_max_mana"], "Base")
	modDB:NewMod("MaxEnergyShieldLeechInstance", "BASE", data.characterConstants["maximum_energy_shield_leech_amount_per_leech_%_max_energy_shield"], "Base")
	modDB:NewMod("TrapThrowingTime", "BASE", 0.6, "Base")
	modDB:NewMod("MineLayingTime", "BASE", 0.3, "Base")
	modDB:NewMod("WarcryCastTime", "BASE", 0.8, "Base")
	modDB:NewMod("TotemPlacementTime", "BASE", 0.6, "Base")
	modDB:NewMod("BallistaPlacementTime", "BASE", 0.5, "Base")
	modDB:NewMod("ActiveTotemLimit", "BASE", data.characterConstants["base_number_of_totems_allowed"], "Base")
	modDB:NewMod("ShockStacksMax", "BASE", 1, "Base")
	modDB:NewMod("ScorchStacksMax", "BASE", 1, "Base")
	modDB:NewMod("MovementSpeed", "INC", -30, "Base", { type = "Condition", var = "Maimed" })
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Attack, { type = "Condition", var = "Intimidated"})
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Attack, { type = "Condition", var = "Intimidated", neg = true}, { type = "Condition", var = "Party:Intimidated"})
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Spell, { type = "Condition", var = "Unnerved"})
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Spell, { type = "Condition", var = "Unnerved", neg = true}, { type = "Condition", var = "Party:Unnerved"})
	modDB:NewMod("Damage", "MORE", -10, "Base", { type = "Condition", var = "Debilitated"}, { type = "GlobalEffect", effectName = "Debilitated", effectType = "Debuff"})
	modDB:NewMod("MovementSpeed", "MORE", -20, "Base", { type = "Condition", var = "Debilitated"}, { type = "GlobalEffect", effectName = "Debilitated", effectType = "Debuff"})
	modDB:NewMod("Damage", "MORE", -10, "Base", { type = "Condition", var = "MalignantMadness"}, { type = "GlobalEffect", effectName = "Malignant Madness", effectType = "Debuff"})
	modDB:NewMod("ActionSpeed", "MORE", -10, "Base", { type = "Condition", var = "MalignantMadness"}, { type = "GlobalEffect", effectName = "Malignant Madness", effectType = "Debuff"})
	modDB:NewMod("Condition:Burning", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "Condition", var = "Ignited" })
	modDB:NewMod("Condition:Poisoned", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "MultiplierThreshold", var = "PoisonStack", threshold = 1 })
	modDB:NewMod("Blind", "FLAG", true, "Base", { type = "Condition", var = "Blinded" })
	modDB:NewMod("Chill", "FLAG", true, "Base", { type = "Condition", var = "Chilled" })
	modDB:NewMod("Freeze", "FLAG", true, "Base", { type = "Condition", var = "Frozen" })
	modDB:NewMod("Fortify", "FLAG", true, "Base", { type = "Condition", var = "Fortify" })
	modDB:NewMod("Fortified", "FLAG", true, "Base", { type = "Condition", var = "Fortified" })
	modDB:NewMod("Excommunicated", "FLAG", true, "Base", { type = "Condition", var = "Excommunicated" })
	modDB:NewMod("Fanaticism", "FLAG", true, "Base", { type = "Condition", var = "Fanaticism" })
	modDB:NewMod("Onslaught", "FLAG", true, "Base", { type = "Condition", var = "Onslaught" })
	modDB:NewMod("UnholyMight", "FLAG", true, "Base", { type = "Condition", var = "UnholyMight" })
	modDB:NewMod("ChaoticMight", "FLAG", true, "Base", { type = "Condition", var = "ChaoticMight" })
	modDB:NewMod("Tailwind", "FLAG", true, "Base", { type = "Condition", var = "Tailwind" })
	modDB:NewMod("Adrenaline", "FLAG", true, "Base", { type = "Condition", var = "Adrenaline" })
	modDB:NewMod("AccelerationShrine", "FLAG", true, "Base", { type = "Condition", var = "AccelerationShrine" })
	modDB:NewMod("BrutalShrine", "FLAG", true, "Base", { type = "Condition", var = "BrutalShrine" })
	modDB:NewMod("DiamondShrine", "FLAG", true, "Base", { type = "Condition", var = "DiamondShrine" })
	modDB:NewMod("DivineShrine", "FLAG", true, "Base", { type = "Condition", var = "DivineShrine" })
	modDB:NewMod("EchoingShrine", "FLAG", true, "Base", { type = "Condition", var = "EchoingShrine" })
	modDB:NewMod("GloomShrine", "FLAG", true, "Base", { type = "Condition", var = "GloomShrine" })
	modDB:NewMod("GreaterFreezingShrine", "FLAG", true, "Base", { type = "Condition", var = "GreaterFreezingShrine" })
	modDB:NewMod("GreaterShockingShrine", "FLAG", true, "Base", { type = "Condition", var = "GreaterShockingShrine" })
	modDB:NewMod("GreaterSkeletalShrine", "FLAG", true, "Base", { type = "Condition", var = "GreaterSkeletalShrine" })
	modDB:NewMod("ImpenetrableShrine", "FLAG", true, "Base", { type = "Condition", var = "ImpenetrableShrine" })
	modDB:NewMod("MassiveShrine", "FLAG", true, "Base", { type = "Condition", var = "MassiveShrine" })
	modDB:NewMod("ReplenishingShrine", "FLAG", true, "Base", { type = "Condition", var = "ReplenishingShrine" })
	modDB:NewMod("ResistanceShrine", "FLAG", true, "Base", { type = "Condition", var = "ResistanceShrine" })
	modDB:NewMod("ResonatingShrine", "FLAG", true, "Base", { type = "Condition", var = "ResonatingShrine" })
	modDB:NewMod("LesserAccelerationShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserAccelerationShrine" }, { type = "Condition", var = "AccelerationShrine", neg = true })
	modDB:NewMod("LesserBrutalShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserBrutalShrine" }, { type = "Condition", var = "BrutalShrine", neg = true })
	modDB:NewMod("LesserImpenetrableShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserImpenetrableShrine" }, { type = "Condition", var = "ImpenetrableShrine", neg = true })
	modDB:NewMod("LesserMassiveShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserMassiveShrine" }, { type = "Condition", var = "MassiveShrine", neg = true })
	modDB:NewMod("LesserReplenishingShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserReplenishingShrine" }, { type = "Condition", var = "ReplenishingShrine", neg = true })
	modDB:NewMod("LesserResistanceShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserResistanceShrine" }, { type = "Condition", var = "ResistanceShrine", neg = true })
	modDB:NewMod("BloodShrineOfRats", "FLAG", true, "Base", { type = "Condition", var = "BloodShrineOfRats" })
	modDB:NewMod("BloodShrineOfLocusts", "FLAG", true, "Base", { type = "Condition", var = "BloodShrineOfLocusts" })
	modDB:NewMod("BloodShrineOfToads", "FLAG", true, "Base", { type = "Condition", var = "BloodShrineOfToads" })
	modDB:NewMod("BloodShrineOfCrows", "FLAG", true, "Base", { type = "Condition", var = "BloodShrineOfCrows" })
	modDB:NewMod("BloodShrineOfBats", "FLAG", true, "Base", { type = "Condition", var = "BloodShrineOfBats" })
	modDB:NewMod("AlchemistsGenius", "FLAG", true, "Base", { type = "Condition", var = "AlchemistsGenius" })
	modDB:NewMod("LuckyHits", "FLAG", true, "Base", { type = "Condition", var = "LuckyHits" })
	modDB:NewMod("Convergence", "FLAG", true, "Base", { type = "Condition", var = "Convergence" })
	modDB:NewMod("PhysicalDamageReduction", "BASE", -15, "Base", { type = "Condition", var = "Crushed" })
	modDB:NewMod("CritChanceCap", "BASE", 100, "Base")
	modDB.conditions["Buffed"] = env.mode_buffs
	modDB.conditions["Combat"] = env.mode_combat
	modDB.conditions["Effective"] = env.mode_effective
end

---@param reuse table|nil A ModList to recycle instead of allocating. Only safe when the caller discards the result.
function calcs.buildModListForNode(env, node, reuse)
	local modList
	if reuse then
		-- Reset the scratch list so non-MAIN calculations can reuse it for each node
		modList = reuse
		for i = #modList, 1, -1 do
			modList[i] = nil
		end
		modList.multipliers = wipeTable(modList.multipliers)
		modList.conditions = wipeTable(modList.conditions)
		modList.actor = wipeTable(modList.actor)
		modList.parent = false
	else
		modList = new("ModList"):ModList()
	end
	if node.type == "Keystone" then
		modList:AddMod(node.keystoneMod)
	else
		modList:AddList(node.modList)
	end

	-- Run first pass radius jewels
	for i = 1, #env.radiusJewelList do
		local rad = env.radiusJewelList[i]
		if rad.type == "Other" then
			local radNode = rad.nodes[node.id]
			if radNode and radNode.type ~= "Mastery" then
				rad.func(node, modList, rad.data)
			end
		end
	end

	-- prefilter the modlist so that every :Flag() call does not have to go through the entire mod list
	local hasNoEffect, hasAllocNoEffect, hasScale, hasOtherEffect, hasExtraSkill, hasExplode
	for i = 1, #modList do
		local name = modList[i].name
		if name == "PassiveSkillHasNoEffect" then
			hasNoEffect = true
		elseif name == "AllocatedPassiveSkillHasNoEffect" then
			hasAllocNoEffect = true
		elseif name == "PassiveSkillEffect" then
			hasScale = true
		elseif name == "PassiveSkillHasOtherEffect" then
			hasOtherEffect = true
		elseif name == "ExtraSkill" then
			hasExtraSkill = true
		elseif name == "CanExplode" then
			hasExplode = true
		end
	end

	if (hasNoEffect and modList:Flag(nil, "PassiveSkillHasNoEffect")) or (env.allocNodes[node.id] and (hasAllocNoEffect and modList:Flag(nil, "AllocatedPassiveSkillHasNoEffect"))) then
		wipeTable(modList)
		hasScale = false
		hasOtherEffect = nil
		hasExtraSkill = nil
		hasExplode = nil
	end

	-- Apply effect scaling
	if hasScale then
		local scale = calcLib.mod(modList, nil, "PassiveSkillEffect")
		if scale ~= 1 then
			local scaledList = new("ModList"):ModList()
			scaledList:ScaleAddList(modList, scale)
			modList = scaledList
		end
	end

	-- Run second pass radius jewels
	local rescan = false
	for i = 1, #env.radiusJewelList do
		local rad = env.radiusJewelList[i]
		if rad.nodes[node.id] and rad.nodes[node.id].type ~= "Mastery" and (rad.type == "Threshold" or (rad.type == "Self" and env.allocNodes[node.id]) or (rad.type == "SelfUnalloc" and not env.allocNodes[node.id])) then
			rad.func(node, modList, rad.data)
			rescan = true
			hasOtherEffect = nil
			hasExtraSkill = nil
			hasExplode = nil
		end
	end

	if rescan then
		for i = 1, #modList do
			local name = modList[i].name
			if name == "PassiveSkillHasOtherEffect" then
				hasOtherEffect = true
			elseif name == "ExtraSkill" then
				hasExtraSkill = true
			elseif name == "CanExplode" then
				hasExplode = true
			end
		end
	end

	if hasOtherEffect and modList:Flag(nil, "PassiveSkillHasOtherEffect") then
		local newMods = modList:List(nil, "NodeModifier")
		for i = 1, #newMods do
			local mod = newMods[i].mod
			if i == 1 then
				wipeTable(modList)
				hasExtraSkill = nil
				hasExplode = nil
			end
			if mod.name == "ExtraSkill" then
				hasExtraSkill = true
			elseif mod.name == "CanExplode" then
				hasExplode = true
			end
			modList:AddMod(mod)
		end
	end

	node.grantedSkills = wipeTable(node.grantedSkills)
	if hasExtraSkill then
		local list = modList:List(nil, "ExtraSkill")
		for i = 1, #list do
			local skill = list[i]
			if skill.name ~= "Unknown" then
				t_insert(node.grantedSkills, {
					skillId = skill.skillId,
					level = skill.level,
					source = "Tree:" .. node.id
				})
			end
		end
	end

	if hasExplode then
		return modList, modList:Flag(nil, "CanExplode") and node
	else
		return modList
	end
end

-- Build list of modifiers from the listed tree nodes
function calcs.buildModListForNodeList(env, nodeList, finishJewels)
	-- Initialise radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		wipeTable(rad.data)
		rad.data.modSource = "Tree:"..rad.nodeId
	end

	-- Add node modifiers
	local modList = new("ModList"):ModList()
	local explodeSources = {}
	-- Outside MAIN mode the per-node list is merged into modList and then
	-- dropped, so a single list can be recycled for every node instead of
	-- allocating one each time.
	local scratch = env.mode ~= "MAIN" and new("ModList"):ModList() or nil
	for _, node in pairs(nodeList) do
		local nodeModList, explode = calcs.buildModListForNode(env, node, scratch)
		t_insert(explodeSources, explode)
		modList:AddList(nodeModList)
		if env.mode == "MAIN" then
			node.finalModList = nodeModList
		end
	end

	if finishJewels then
		-- Process extra radius nodes; these are unallocated nodes near conversion or threshold jewels that need to be processed
		for _, node in pairs(env.extraRadiusNodeList) do
			local nodeModList = calcs.buildModListForNode(env, node, scratch)
			if env.mode == "MAIN" then
				node.finalModList = nodeModList
			end
		end

		-- Finalise radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			rad.func(nil, modList, rad.data)
			if env.mode == "MAIN" then
				if not rad.item.jewelRadiusData then
					rad.item.jewelRadiusData = { }
				end
				rad.item.jewelRadiusData[rad.nodeId] = rad.data
			end
		end
	end

	return modList, explodeSources
end

function wipeEnv(env, accelerate)
	-- Always wipe the below as we will be pushing in the modifiers,
	-- multipliers and conditions for player and enemy DBs via `parent`
	-- extensions of those DBs later which allow us to do a table-pointer
	-- link and save time on having to do a copyTable() function.
	wipeTable(env.modDB.mods)
	wipeTable(env.modDB.conditions)
	wipeTable(env.modDB.multipliers)
	wipeTable(env.enemyDB.mods)
	wipeTable(env.enemyDB.conditions)
	wipeTable(env.enemyDB.multipliers)
	if env.minion then
		wipeTable(env.minion.modDB.mods)
		wipeTable(env.minion.modDB.conditions)
		wipeTable(env.minion.modDB.multipliers)
	end

	if accelerate.everything then
		-- perform() appends combat mods onto mercenary.modDB. Restore the
		-- pre-combat snapshot when we have one; otherwise park and rebuild.
		if not restoreCachedMercenary(env) then
			parkCurrentMercenary(env)
		end
		return
	end

	-- Passive tree node allocations
	-- Also in a further pass tracks Legion influenced mods
	if not accelerate.nodeAlloc then
		wipeTable(env.allocNodes)
		-- Usually states: `Allocates <NAME>` (e.g., amulet anointment)
		wipeTable(env.grantedPassives)
		wipeTable(env.grantedSkillsNodes)
	end

	if not accelerate.requirementsItems then
		-- Item-related tables
		wipeTable(env.itemModDB.mods)
		wipeTable(env.itemModDB.conditions)
		wipeTable(env.itemModDB.multipliers)
		-- 1) Jewels and Jewel-Radius related node modifications
		-- 2) Player items
		-- 3) Granted Skill from items (e.g., Curse on Hit rings)
		-- 4) Flasks and Tinctures
		wipeTable(env.radiusJewelList)
		wipeTable(env.extraRadiusNodeList)
		wipeTable(env.player.itemList)
		wipeTable(env.grantedSkillsItems)
		wipeTable(env.flasks)
		wipeTable(env.tinctures)

		-- Special / Unique Items that have their own ModDB()
		if env.aegisModList then
			wipeTable(env.aegisModList)
		end
		if env.theIronMass then
			wipeTable(env.theIronMass)
		end
		if env.weaponModList1 then
			wipeTable(env.weaponModList1)
		end

		-- Requirements from Items (Str, Dex, Int)
		wipeTable(env.requirementsTableItems)
	end

	-- Requirements from Gems (Str, Dex, Int)
	if not accelerate.requirementsGems then
		wipeTable(env.requirementsTableGems)
	end

	if not accelerate.skills then
		-- Player Active Skills generation
		wipeTable(env.player.activeSkillList)

		-- Enhances Active Skills with skill ModFlags, KeywordFlags
		-- and modifiers that affect skill scaling (e.g., global buffs/effects)
		wipeTable(env.auxSkillList)
	end
	parkCurrentMercenary(env)
end

local function applyGemMods(effect, modList)
	for _, mod in ipairs(modList) do
		local match = true
		local value = mod.value
		if value.keywordList then
			for _, keyword in ipairs(value.keywordList) do
				if not calcLib.gemIsType(effect.gemData, keyword, true) then
					match = false
					break
				end
			end
		elseif not calcLib.gemIsType(effect.gemData, value.keyword, true) then
			match = false
		end
		if match then
			-- save quality increases for use in tooltips
			if value.key == "quality" then
				local isSocketed = false
				for _, tag in ipairs(mod.mod) do
					if tag.type == "SocketedIn" then
						isSocketed = true
						break
					end
				end
				if isSocketed then
					effect.itemQuality = (effect.itemQuality or 0) + value.value
				else
					effect.globalQuality = (effect.globalQuality or 0) + value.value
				end
			end
			effect[value.key] = (effect[value.key] or 0) + value.value
			effect.gemPropertyInfo = effect.gemPropertyInfo or {}
			t_insert(effect.gemPropertyInfo, mod)
		end
	end
end

local function applySocketMods(env, gem, groupCfg, socketNum, modSource)
	local socketCfg = copyTable(groupCfg, true)
	socketCfg.skillGem = gem
	socketCfg.socketNum = socketNum
	for _, value in ipairs(env.modDB:List(socketCfg, "SocketProperty")) do
		env.player.modDB:AddMod(modLib.setSource(value.value, modSource or groupCfg.slotName or ""))
	end
end

local function addBestSupport(supportEffect, appliedSupportList, mode)
	local add = true
	for index, otherSupport in ipairs(appliedSupportList) do
		-- Check if there's another better support already present
		if supportEffect.grantedEffect == otherSupport.grantedEffect then
			add = false
			if supportEffect.level > otherSupport.level or (supportEffect.level == otherSupport.level and supportEffect.quality > otherSupport.quality) then
				if mode == "MAIN" then
					otherSupport.superseded = true
				end
				appliedSupportList[index] = supportEffect
			else
				supportEffect.superseded = true
			end
			break
		elseif supportEffect.grantedEffect.plusVersionOf == otherSupport.grantedEffect.id then
			add = false
			if mode == "MAIN" then
				otherSupport.superseded = true
			end
			appliedSupportList[index] = supportEffect
		elseif otherSupport.grantedEffect.plusVersionOf == supportEffect.grantedEffect.id then
			add = false
			supportEffect.superseded = true
		end
	end
	if add then
		t_insert(appliedSupportList, supportEffect)
	end
end

---@alias CalcEnvMode "MAIN"|"CALCS"|"EFFECTIVE"|"COMBAT"|"BUFFED"|"CALCULATOR"
-- Initialise environment:
-- 1. Initialises the player and enemy modifier databases
-- 2. Merges modifiers for all items
-- 3. Builds a list of jewels with radius functions
-- 4. Merges modifiers for all allocated passive nodes
-- 5. Builds a list of active skills and their supports (calcs.createActiveSkill)
-- 6. Builds modifier lists for all active skills (calcs.buildActiveSkillModList)
---@param build Build
---@param mode CalcEnvMode
---@param override CalcOverride?
---@param specEnv any?
---@return Env
---@return ModDB? cachedPlayerDB
---@return ModDB? cachedEnemyDB
---@return ModDB? cachedMinionDB
function calcs.initEnv(build, mode, override, specEnv)
	ClearMatchKeywordFlagsCache()
	-- accelerator variables
	local cachedPlayerDB = specEnv and specEnv.cachedPlayerDB or nil
	local cachedEnemyDB = specEnv and specEnv.cachedEnemyDB or nil
	local cachedMinionDB = specEnv and specEnv.cachedMinionDB or nil
	local env = specEnv and specEnv.env or nil
	local accelerate = specEnv and specEnv.accelerate or { }

	-- environment variables
	local override = override or { }
	if override.itemSetId ~= nil and not build.itemsTab.itemSets[override.itemSetId] then
		error("Unknown item set id: "..tostring(override.itemSetId))
	end
	local replacesPlayerItem = MercenaryTools.overrideReplacesPlayerItem(override, build.itemsTab.activeItemSetId)
	local modDB = nil
	local enemyDB = nil
	local classStats = nil

	if not env then
		---@class Env
		---@field minion Actor?
		env = { }
		env.build = build
		env.data = build.data
		env.configInput = build.configTab.input
		env.configPlaceholder = build.configTab.placeholder
		env.calcsInput = build.calcsTab.input
		env.mode = mode
		env.buildBreakdown = mode == "MAIN" or mode == "CALCS"
		env.spec = override.spec or build.spec
		env.override = override
		env.classId = env.spec.curClassId

		modDB = new("ModDB"):ModDB()
		env.modDB = modDB
		enemyDB = new("ModDB"):ModDB()
		env.enemyDB = enemyDB
		env.itemModDB = new("ModDB"):ModDB()

		env.enemyLevel = build.configTab.enemyLevel or m_min(data.misc.MaxEnemyLevel, build.characterLevel)

		-- Create player/enemy actors
		env.player = {
			modDB = env.modDB,
			level = build.characterLevel,
		}
		env.modDB.actor = env.player
		env.enemy = {
			modDB = env.enemyDB,
			level = env.enemyLevel,
		}
		enemyDB.actor = env.enemy
		env.player.enemy = env.enemy
		env.enemy.enemy = env.player
		enemyDB.actor.player = env.player
		env.modDB.actor.player = env.player

		-- Set up requirements tracking
		env.requirementsTableItems = { }
		env.requirementsTableGems = { }

		-- Prepare item, skill, flask tables
		env.radiusJewelList = wipeTable(env.radiusJewelList)
		env.extraRadiusNodeList = wipeTable(env.extraRadiusNodeList)
		env.player.itemList = { }
		env.grantedSkills = { }
		env.grantedSkillsNodes = { }
		env.grantedSkillsItems = { }
		env.explodeSources = { }
		env.itemWarnings = { }
		env.flasks = { }
		env.tinctures = { }

		-- tree based
		env.grantedPassives = { }

		-- skill-related
		env.player.activeSkillList = { }
		env.auxSkillList = { }
	--elseif accelerate.everything then
	--	local minionDB = nil
	--	env.modDB.parent, env.enemyDB.parent, minionDB = specCopy(env)
	--	if minionDB then
	--		env.minion.modDB.parent = minionDB
	--	end
	--	wipeEnv(env, accelerate)
	else
		wipeEnv(env, accelerate)
		modDB = env.modDB
		enemyDB = env.enemyDB
	end

	-- Set buff mode
	local buffMode
	if mode == "CALCS" then
		buffMode = env.calcsInput.misc_buffMode
	else
		buffMode = "EFFECTIVE"
	end
	if buffMode == "EFFECTIVE" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = true
	elseif buffMode == "COMBAT" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = false
	elseif buffMode == "BUFFED" then
		env.mode_buffs = true
		env.mode_combat = false
		env.mode_effective = false
	else
		env.mode_buffs = false
		env.mode_combat = false
		env.mode_effective = false
	end
	classStats = env.spec.tree.characterData and env.spec.tree.characterData[env.classId] or env.spec.tree.classes[env.classId]

	if not cachedPlayerDB then
		-- Initialise modifier database with base values
		for _, stat in pairs({"Str","Dex","Int"}) do
			modDB:NewMod(stat, "BASE", classStats["base_"..stat:lower()], "Base")
		end
		modDB.multipliers["Level"] = m_max(1, m_min(100, build.characterLevel))
		calcs.initModDB(env, modDB)
		modDB:NewMod("Life", "BASE", data.characterConstants["life_per_level"], "Base", { type = "Multiplier", var = "Level", base = 38 })
		modDB:NewMod("Mana", "BASE", data.characterConstants["mana_per_level"], "Base", { type = "Multiplier", var = "Level", base = 34 })
		modDB:NewMod("ManaRegen", "BASE", env.data.misc.ManaRegenBase, "Base", { type = "PerStat", stat = "Mana", div = 1 })
		modDB:NewMod("Devotion", "BASE", 0, "Base")
		modDB:NewMod("Evasion", "BASE", data.characterConstants["base_evasion_rating"], "Base")
		modDB:NewMod("Accuracy", "BASE", data.characterConstants["accuracy_rating_per_level"], "Base", { type = "Multiplier", var = "Level", base = -data.characterConstants["accuracy_rating_per_level"] })
		modDB:NewMod("CritMultiplier", "BASE", data.characterConstants["base_critical_strike_multiplier"] - 100, "Base")
		modDB:NewMod("DotMultiplier", "BASE", data.characterConstants["critical_ailment_dot_multiplier_+"], "Base", { type = "Condition", var = "CriticalStrike" })
		modDB:NewMod("FireResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("ColdResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("LightningResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("ChaosResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("TotemFireResist", "BASE", 40, "Base")
		modDB:NewMod("TotemColdResist", "BASE", 40, "Base")
		modDB:NewMod("TotemLightningResist", "BASE", 40, "Base")
		modDB:NewMod("TotemChaosResist", "BASE", 20, "Base")
		modDB:NewMod("CritChance", "INC", data.characterConstants["critical_strike_chance_+%_per_power_charge"], "Base", { type = "Multiplier", var = "PowerCharge" })
		modDB:NewMod("Speed", "INC", data.characterConstants["base_attack_speed_+%_per_frenzy_charge"], "Base", ModFlag.Attack, { type = "Multiplier", var = "FrenzyCharge" })
		modDB:NewMod("Speed", "INC", data.characterConstants["base_cast_speed_+%_per_frenzy_charge"], "Base", ModFlag.Cast, { type = "Multiplier", var = "FrenzyCharge" })
		modDB:NewMod("Damage", "MORE", data.characterConstants["object_inherent_damage_+%_final_per_frenzy_charge"], "Base", { type = "Multiplier", var = "FrenzyCharge" })
		modDB:NewMod("PhysicalDamageReduction", "BASE", data.characterConstants["physical_damage_reduction_%_per_endurance_charge"], "Base", { type = "Multiplier", var = "EnduranceCharge" })
		modDB:NewMod("ElementalDamageReduction", "BASE", data.characterConstants["elemental_damage_reduction_%_per_endurance_charge"], "Base", { type = "Multiplier", var = "EnduranceCharge" })
		modDB:NewMod("MaximumRage", "BASE", data.characterConstants["maximum_rage"], "Base")
		modDB:NewMod("Multiplier:GaleForce", "BASE", 0, "Base")
		modDB:NewMod("MaximumGaleForce", "BASE", 10, "Base")
		modDB:NewMod("MaximumFortification", "BASE", data.characterConstants["base_max_fortification"], "Base")
		modDB:NewMod("MaximumValour", "BASE", 50, "Base")
		modDB:NewMod("Multiplier:IntensityLimit", "BASE", 3, "Base")
		modDB:NewMod("Damage", "INC", data.characterConstants["damage_+%_per_10_rampage_stacks"], "Base", { type = "Multiplier", var = "Rampage", limit = data.characterConstants["max_rampage_stacks"] / 20, div = 20 })
		modDB:NewMod("MovementSpeed", "INC", data.characterConstants["movement_velocity_+%_per_10_rampage_stacks"], "Base", { type = "Multiplier", var = "Rampage", limit = data.characterConstants["max_rampage_stacks"] / 20, div = 20 })
		modDB:NewMod("ActiveTrapLimit", "BASE", data.characterConstants["base_number_of_traps_allowed"], "Base")
		modDB:NewMod("ActiveMineLimit", "BASE", data.characterConstants["base_number_of_remote_mines_allowed"], "Base")
		modDB:NewMod("MineThrowCount", "BASE", 1, "Base")
		modDB:NewMod("TrapThrowCount", "BASE", 1, "Base")
		modDB:NewMod("ActiveBrandLimit", "BASE", 3, "Base")
		modDB:NewMod("EnemyCurseLimit", "BASE", 1, "Base")
		modDB:NewMod("SocketedCursesHexLimitValue", "BASE", 1, "Base")
		modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
		modDB:NewMod("Speed", "MORE", data.characterConstants["dual_wield_inherent_attack_speed_+%_final"], "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "DoubledInherentDualWieldingSpeed", neg = true })
		modDB:NewMod("Speed", "MORE", 2 * data.characterConstants["dual_wield_inherent_attack_speed_+%_final"], "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "DoubledInherentDualWieldingSpeed"})
		modDB:NewMod("BlockChance", "BASE", data.characterConstants["inherent_block_while_dual_wielding_%"], "Base", { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "NoInherentBlock", neg = true}, { type = "Condition", var = "DoubledInherentDualWieldingBlock", neg = true})
		modDB:NewMod("BlockChance", "BASE", 2 * data.characterConstants["inherent_block_while_dual_wielding_%"], "Base", { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "NoInherentBlock", neg = true}, { type = "Condition", var = "DoubledInherentDualWieldingBlock"})
		modDB:NewMod("Damage", "MORE", 200, "Base", 0, KeywordFlag.Bleed, { type = "ActorCondition", actor = "enemy", var = "Moving" }, { type = "Condition", var = "NoExtraBleedDamageToMovingEnemy", neg = true })
		modDB:NewMod("Condition:BloodStance", "FLAG", true, "Base", { type = "Condition", var = "SandStance", neg = true })
		modDB:NewMod("Condition:PrideMinEffect", "FLAG", true, "Base", { type = "Condition", var = "PrideMaxEffect", neg = true })
		modDB:NewMod("PerBrutalTripleDamageChance", "BASE", data.characterConstants["chance_to_deal_triple_damage_%_per_brutal_charge"], "Base")
		modDB:NewMod("PerAfflictionAilmentDamage", "BASE", data.characterConstants["ailment_damage_+%_final_per_affliction_charge"], "Base")
		modDB:NewMod("PerAfflictionNonDamageEffect", "BASE", data.characterConstants["non_damaging_ailment_effect_+%_final_per_affliction_charge"], "Base")
		modDB:NewMod("PerAbsorptionElementalEnergyShieldRecoup", "BASE", data.characterConstants["elemental_damage_taken_goes_to_energy_shield_over_4_seconds_%_per_absorption_charge"], "Base")
		modDB:NewMod("TinctureLimit", "BASE", 1, "Base")
		modDB:NewMod("ManaDegenPercentTincture", "BASE", 1, "Base", { type = "Multiplier", var = "EffectiveManaBurnStacks" })
		modDB:NewMod("LifeDegenPercentTincture", "BASE", 1, "Base", { type = "Multiplier", var = "WeepingWoundsStacks" })
		modDB:NewMod("PresenceRadius", "BASE", data.characterConstants["base_presence_radius"], "Base")

		-- Add bandit mods
		if env.configInput.bandit == "Alira" then
			modDB:NewMod("ElementalResist", "BASE", 15, "Bandit")
		elseif env.configInput.bandit == "Kraityn" then
			modDB:NewMod("MovementSpeed", "INC", 8, "Bandit")
		elseif env.configInput.bandit == "Oak" then
			modDB:NewMod("Life", "BASE", 40, "Bandit")
		else
			modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
		end

		-- Add Pantheon mods
		local parser = modLib.parseMod
		-- Major Gods
		if env.configInput.pantheonMajorGod ~= "None" then
			local majorGod = env.data.pantheons[env.configInput.pantheonMajorGod]
			pantheon.applySoulMod(modDB, parser, majorGod)
		end
		-- Minor Gods
		if env.configInput.pantheonMinorGod ~= "None" then
			local minorGod = env.data.pantheons[env.configInput.pantheonMinorGod]
			pantheon.applySoulMod(modDB, parser, minorGod)
		end

		-- Initialise enemy modifier database
		calcs.initModDB(env, enemyDB)
		enemyDB:NewMod("Accuracy", "BASE", env.data.monsterAccuracyTable[env.enemyLevel], "Base")
		enemyDB:NewMod("Condition:AgainstDamageOverTime", "FLAG", true, "Base", ModFlag.Dot, { type = "ActorCondition", actor = "player", var = "Combat" })

		-- Add mods from the config tab
		env.modDB:AddList(build.configTab.modList)
		env.enemyDB:AddList(build.configTab.enemyModList)

		-- Add mods from the party tab
		env.enemyDB:AddList(build.partyTab.enemyModList)

		cachedPlayerDB, cachedEnemyDB, cachedMinionDB = specCopy(env)
	else
		env.modDB.parent = cachedPlayerDB
		env.enemyDB.parent = cachedEnemyDB
		if cachedMinionDB and env.minion then
			env.minion.modDB.parent = cachedMinionDB
		end
	end

	if MercenaryTools.hasProfile(env.build) then
		calcs.attachEnemySourceDB(env, env.player, env.build.configTab.playerEnemyModList)
	elseif env.player then
		env.player.enemySourceDB = nil
	end

	if override.conditions then
		for _, flag in ipairs(override.conditions) do
			modDB.conditions[flag] = true
		end
	end

	local allocatedNotableCount = env.spec.allocatedNotableCount
	local allocatedKeystoneCount = env.spec.allocatedKeystoneCount
	local allocatedMasteryCount = env.spec.allocatedMasteryCount
	local allocatedMasteryTypeCount = env.spec.allocatedMasteryTypeCount
	local allocatedMasteryTypes = copyTable(env.spec.allocatedMasteryTypes)
	local allocatedTattooTypes = copyTable(env.spec.allocatedTattooTypes)



	if not accelerate.nodeAlloc then
		-- Build list of passive nodes
		local nodes
		if override.addNodes or override.removeNodes then
			nodes = { }
			if override.addNodes then
				for node in pairs(override.addNodes) do
					nodes[node.id] = node
					if node.type == "Mastery" then
						allocatedMasteryCount = allocatedMasteryCount + 1

						if not allocatedMasteryTypes[node.name] then
							allocatedMasteryTypes[node.name] = 1
							allocatedMasteryTypeCount = allocatedMasteryTypeCount + 1
						else
							local prevCount = allocatedMasteryTypes[node.name]
							allocatedMasteryTypes[node.name] = prevCount + 1
							if prevCount == 0 then
								allocatedMasteryTypeCount = allocatedMasteryTypeCount + 1
							end
						end
					elseif node.type == "Notable" then
						allocatedNotableCount = allocatedNotableCount + 1
					elseif node.type == "Keystone" then
						allocatedKeystoneCount = allocatedKeystoneCount + 1	
					end
					if node.isTattoo and node.overrideType then
						if not allocatedTattooTypes[node.overrideType] then
							allocatedTattooTypes[node.overrideType] = 1
						else
							local prevCount = allocatedTattooTypes[node.overrideType]
							allocatedTattooTypes[node.overrideType] = prevCount + 1
						end
					end
				end
			end
			for _, node in pairs(env.spec.allocNodes) do
				if not override.removeNodes or not override.removeNodes[node] then
					nodes[node.id] = node
				elseif override.removeNodes[node] then
					if node.type == "Mastery" then
						allocatedMasteryCount = allocatedMasteryCount - 1

						allocatedMasteryTypes[node.name] = allocatedMasteryTypes[node.name] - 1
						if allocatedMasteryTypes[node.name] == 0 then
							allocatedMasteryTypeCount = allocatedMasteryTypeCount - 1
						end
					elseif node.type == "Notable" then
						allocatedNotableCount = allocatedNotableCount - 1
					elseif node.type == "Keystone" then
						allocatedKeystoneCount = allocatedKeystoneCount - 1	
					end
					if node.isTattoo and node.overrideType then
						if allocatedTattooTypes[node.overrideType] then
							allocatedTattooTypes[node.overrideType] = allocatedTattooTypes[node.overrideType] - 1
						end
					end
				end
			end
		else
			nodes = copyTable(env.spec.allocNodes, true)
		end
		env.allocNodes = nodes
		env.initialNodeModDB = calcs.buildModListForNodeList(env, env.allocNodes, true)
		modLib.mergeKeystones(env, env.initialNodeModDB)
	end

	if allocatedNotableCount and allocatedNotableCount > 0 then
		modDB:NewMod("Multiplier:AllocatedNotable", "BASE", allocatedNotableCount)
	end
	if allocatedKeystoneCount and allocatedKeystoneCount > 0 then
		modDB:NewMod("Multiplier:AllocatedKeystone", "BASE", allocatedKeystoneCount)
	end
	if allocatedMasteryCount and allocatedMasteryCount > 0 then
		modDB:NewMod("Multiplier:AllocatedMastery", "BASE", allocatedMasteryCount)
	end
	if allocatedMasteryTypeCount and allocatedMasteryTypeCount > 0 then
		modDB:NewMod("Multiplier:AllocatedMasteryType", "BASE", allocatedMasteryTypeCount)
	end
	if allocatedMasteryTypes["Life Mastery"] and allocatedMasteryTypes["Life Mastery"] > 0 then
		modDB:NewMod("Multiplier:AllocatedLifeMastery", "BASE", allocatedMasteryTypes["Life Mastery"])
	end
	if allocatedTattooTypes then
		for type, count in pairs(allocatedTattooTypes) do
			env.modDB.multipliers[type] = count
		end
	end

	-- Build and merge item modifiers, and create list of radius jewels
	if not accelerate.requirementsItems then
		local items = {}
		local jewelLimits = {}
		for _, slot in ipairs(build.itemsTab.orderedSlots) do
			local slotName = slot.slotName
			if slotName == "Graft 1" or slotName == "Graft 2" then
				if not build.spec.treeVersion:find("3_27") then
					goto continue
				end
			end
			-- ignore item in Ring 3 if The Unseen Hand is not allocated
			if slotName == "Ring 3" and not env.initialNodeModDB:Flag(nil, "AdditionalRingSlot") then
				goto continue
			end
			local item
			if replacesPlayerItem and slotName == override.repSlotName then
				item = override.repItem
			elseif replacesPlayerItem and override.repItem and override.repSlotName:match("^Weapon 1") and slotName:match("^Weapon 2") and
			(override.repItem.base.type == "Staff" or override.repItem.base.type == "Two Handed Sword" or override.repItem.base.type == "Two Handed Axe" or override.repItem.base.type == "Two Handed Mace"
			or (override.repItem.base.type == "Bow" and item and item.base.type ~= "Quiver")) then
				goto continue
			elseif slot.nodeId then
				item = build.itemsTab.items[env.spec.jewels[slot.nodeId]]
			else
				local itemSlot = build.itemsTab.activeItemSet[slotName]
				item = build.itemsTab.items[itemSlot and itemSlot.selItemId]
			end
			if item and item.grantedSkills then
				-- Find skills granted by this item
				for _, skill in ipairs(item.grantedSkills) do
					local skillData = env.data.skills[skill.skillId]
					local grantedSkill = copyTable(skill)
					grantedSkill.nameSpec = skillData and skillData.name or nil
					grantedSkill.sourceItem = item
					grantedSkill.slotName = slotName
					t_insert(env.grantedSkillsItems, grantedSkill)
				end
			end
			if item and item.baseModList and item.baseModList:Flag(nil, "CanExplode") then
				t_insert(env.explodeSources, item)
			end
			if slot.weaponSet and slot.weaponSet ~= (build.itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1) then
				goto continue
			end
			if slot.weaponSet == 2 and build.itemsTab.activeItemSet.useSecondWeaponSet then
				slotName = slotName:gsub(" Swap","")
			end
			if slot.nodeId then
				-- Slot is a jewel socket, check if socket is allocated
				if not env.allocNodes[slot.nodeId] then
					goto continue
				elseif item then
					if item.jewelData then
						item.jewelData.limitDisabled = nil
					end
					if item and item.type == "Jewel" and item.name:match("The Adorned, Crimson Jewel") then
						if item.jewelData.corruptedMagicJewelIncEffect then
							env.modDB.multipliers["CorruptedMagicJewelEffect"] = item.jewelData.corruptedMagicJewelIncEffect / 100
						end
						if item.jewelData.corruptedRareJewelIncEffect then
							env.modDB.multipliers["CorruptedRareJewelEffect"] = item.jewelData.corruptedRareJewelIncEffect / 100
						end
					end
					if item.limit and not env.configInput.ignoreJewelLimits then
						local limitKey = item.base.subType == "Timeless" and "Historic" or item.title
						if jewelLimits[limitKey] and jewelLimits[limitKey] >= item.limit then
							if item.jewelData then
								item.jewelData.limitDisabled = true
							end
							env.itemWarnings.jewelLimitWarning = env.itemWarnings.jewelLimitWarning or { }
							t_insert(env.itemWarnings.jewelLimitWarning, limitKey)
							goto continue
						else
							jewelLimits[limitKey] = (jewelLimits[limitKey] or 0) + 1
						end
					end
					if item and ( item.jewelRadiusIndex or (override and override.extraJewelFuncs and #override.extraJewelFuncs > 0) ) then
						-- Jewel has a radius, add it to the list
						local funcList = (item.jewelData and item.jewelData.funcList) or { { type = "Self", func = function(node, out, data)
							-- Default function just tallies all stats in radius
							if node then
								for _, stat in pairs({"Str","Dex","Int"}) do
									data[stat] = (data[stat] or 0) + out:Sum("BASE", nil, stat)
								end
							end
						end } }
						for _, func in ipairs(funcList) do
							local node = env.spec.nodes[slot.nodeId]
							t_insert(env.radiusJewelList, {
								nodes = node.nodesInRadius and node.nodesInRadius[item.jewelRadiusIndex] or { },
								func = func.func,
								type = func.type,
								item = item,
								nodeId = slot.nodeId,
								attributes = node.attributesInRadius and node.attributesInRadius[item.jewelRadiusIndex] or { },
								data = { }
							})
							if func.type ~= "Self" and node.nodesInRadius then
								-- Add nearby unallocated nodes to the extra node list
								for nodeId, node in pairs(node.nodesInRadius[item.jewelRadiusIndex]) do
									if not env.allocNodes[nodeId] then
										env.extraRadiusNodeList[nodeId] = env.spec.nodes[nodeId]
									end
								end
							end
						end
						for _, funcData in ipairs(override and override.extraJewelFuncs and override.extraJewelFuncs:List({item = item}, "ExtraJewelFunc") or {}) do
							local node = env.spec.nodes[slot.nodeId]
							local radius
							for index, data in pairs(data.jewelRadius) do
								if funcData.radius == data.label then
									radius = index
									break
								end
							end
							t_insert(env.radiusJewelList, {
								nodes = node.nodesInRadius and node.nodesInRadius[radius] or { },
								func = funcData.func,
								type = funcData.type,
								item = item,
								nodeId = slot.nodeId,
								attributes = node.attributesInRadius and node.attributesInRadius[radius] or { },
								data = { }
							})
							if funcData.type ~= "Self" and node.nodesInRadius then
								-- Add nearby unallocated nodes to the extra node list
								for nodeId, node in pairs(node.nodesInRadius[radius]) do
									if not env.allocNodes[nodeId] then
										env.extraRadiusNodeList[nodeId] = env.spec.nodes[nodeId]
									end
								end
							end
						end
					end
				end
			end
			if item and item.type == "Flask" and item.base.subType == "Life" and item.flaskData then
				-- Keep highest life flask recovery even if this slot is later disabled (e.g. Poisonous Concoction).
				env.itemModDB.multipliers["LifeFlaskRecovery"] = m_max(env.itemModDB.multipliers["LifeFlaskRecovery"] or 0, item.flaskData.lifeTotal or 0)
			end
			items[slotName] = item
			::continue::
		end

		if not env.configInput.ignoreItemDisablers then
			local itemDisabled = {}
			local itemDisablers = {}
			-- First check tree nodes for disabled items.  This will break if there's ever an anointable node that disables items
			for _, mod in ipairs(env.initialNodeModDB:Tabulate("Flag", { source = "Tree" }, "CanNotUseItem")) do
				mod = mod.mod
				-- checks if it disables another slot
				for _, tag in ipairs(mod) do
					if tag.type == "DisablesItem" then
						if tag.excludeItemType and items[tag.slotName] and items[tag.slotName].type == tag.excludeItemType then
							break
						end
						itemDisablers[mod.source] = tag.slotName
						itemDisabled[tag.slotName] = mod.source
						break
					end
				end
			end
			for _, slot in ipairs(build.itemsTab.orderedSlots) do
				local slotName = slot.slotName
				if items[slotName] then
					local srcList = items[slotName].modList or items[slotName].slotModList[slot.slotNum]
					for _, mod in ipairs(srcList) do
						-- checks if it disables another slot
						for _, tag in ipairs(mod) do
							if tag.type == "DisablesItem" then
								-- e.g. Tincture in Flask 5 while using a Micro-Distillery Belt
								if tag.excludeItemType and items[tag.slotName] and items[tag.slotName].type == tag.excludeItemType then
									break
								end
								itemDisablers[slotName] = tag.slotName
								itemDisabled[tag.slotName] = slotName
								break
							end
						end
					end
				end
			end
			local visited = {}
			local trueDisabled = {}
			for slot in pairs(itemDisablers) do
				if not visited[slot] then
					-- find chain start
					local curChain = { slot = true }
					while itemDisabled[slot] do
						slot = itemDisabled[slot]
						if curChain[slot] then break end -- detect cycles
						curChain[slot] = true
					end

					-- step through the chain of disabled items, disabling every other one
					repeat
						visited[slot] = true
						slot = itemDisablers[slot]
						if not slot then break end
						visited[slot] = true
						trueDisabled[slot] = true
						slot = itemDisablers[slot]
					until(not slot or visited[slot])
				end
			end
			for slot in pairs(trueDisabled) do
				items[slot] = nil
			end
		end

		for _, slot in ipairs(build.itemsTab.orderedSlots) do
			local item = items[slot.slotName]
			local missingAnoints = build.itemsTab:getMissingAnointCount(item)
			if missingAnoints > 0 then
				local slotLabel = slot.label
				if missingAnoints > 1 then
					slotLabel = slotLabel .. " (" .. missingAnoints .. " missing)"
				end
				env.itemWarnings.missingAnointWarning = env.itemWarnings.missingAnointWarning or { }
				t_insert(env.itemWarnings.missingAnointWarning, slotLabel)
			end
		end

		-- Track which flask slot (1-5) each flask is in, for adjacency checks
		env.flaskSlotMap = { }
		env.flaskSlotOccupied = { }
		for _, slot in ipairs(build.itemsTab.orderedSlots) do
			local slotName = slot.slotName
			local item = items[slotName]
			if item and item.type == "Flask" then
				env.itemModDB.conditions["Have"..item.baseName:gsub("%s+", "")] = true
				if slot.active then
					env.flasks[item] = true
				end
				local flaskNum = tonumber(slotName:match("Flask (%d+)"))
				if flaskNum then
					env.flaskSlotMap[item] = flaskNum
					env.flaskSlotOccupied[flaskNum] = true
				end
				if item.base.subType == "Life" then
					local highestCharges = env.itemModDB.multipliers["LifeFlaskCharges"] or 0
					if item.flaskData.chargesMax > highestCharges then
						env.itemModDB.multipliers["LifeFlaskCharges"] = item.flaskData.chargesMax
					end
				end
				item = nil
			elseif item and item.type == "Tincture" then
				if slot.active then
					env.tinctures[item] = true
				end
				item = nil
			end
			local scale = 1
			if item and item.type == "Jewel" and item.base.subType == "Abyss" and slot.parentSlot then
				-- Check if the item in the parent slot has enough Abyssal Sockets
				local parentItem = env.player.itemList[slot.parentSlot.slotName]
				if not parentItem or parentItem.abyssalSocketCount < slot.slotNum then
					item = nil
				else
					scale = parentItem.socketedJewelEffectModifier
				end
			end
			if slot.nodeId and item and item.type == "Jewel" and item.jewelData and item.jewelData.jewelIncEffectFromClassStart then
				local node = env.spec.nodes[slot.nodeId]
				if node and node.distanceToClassStart then
					scale = scale + node.distanceToClassStart * (item.jewelData.jewelIncEffectFromClassStart / 100)
				end
			end
			if item then
				env.player.itemList[slotName] = item
				-- Merge mods for this item
				local srcList = item.modList or (item.slotModList and item.slotModList[slot.slotNum]) or {}
				if item.requirements and not accelerate.requirementsItems then
					t_insert(env.requirementsTableItems, {
						source = "Item",
						sourceItem = item,
						sourceSlot = slotName,
						Str = item.requirements.strMod,
						Dex = item.requirements.dexMod,
						Int = item.requirements.intMod,
					})
				end
				if item.type == "Jewel" and item.base.subType == "Abyss" then
					-- Update Abyss Jewel conditions/multipliers
					local cond = "Have"..item.baseName:gsub(" ","")
					local mult = item.baseName:gsub(" ","")
					if not env.itemModDB.conditions[cond] then
						env.itemModDB.conditions[cond] = true
						env.itemModDB.multipliers["AbyssJewelType"] = (env.itemModDB.multipliers["AbyssJewelType"] or 0) + 1
					end
					if slot.parentSlot then
						env.itemModDB.conditions[cond.."In"..slot.parentSlot.slotName] = true
						env.itemModDB.multipliers[mult.."In"..slot.parentSlot.slotName] = (env.itemModDB.multipliers[mult.."In"..slot.parentSlot.slotName] or 0) + 1
					end
					env.itemModDB.multipliers["AbyssJewel"] = (env.itemModDB.multipliers["AbyssJewel"] or 0) + 1
					if item.rarity == "NORMAL" then env.itemModDB.multipliers["NormalAbyssJewels"] = (env.itemModDB.multipliers["NormalAbyssJewels"] or 0) + 1 end
					if item.rarity == "MAGIC" then env.itemModDB.multipliers["MagicAbyssJewels"] = (env.itemModDB.multipliers["MagicAbyssJewels"] or 0) + 1 end
					if item.rarity == "RARE" then env.itemModDB.multipliers["RareAbyssJewels"] = (env.itemModDB.multipliers["RareAbyssJewels"] or 0) + 1 end
					if item.rarity == "UNIQUE" or item.rarity == "RELIC" then env.itemModDB.multipliers["UniqueAbyssJewels"] = (env.itemModDB.multipliers["UniqueAbyssJewels"] or 0) + 1 end
					env.itemModDB.multipliers[item.baseName:gsub(" ","")] = (env.itemModDB.multipliers[item.baseName:gsub(" ","")] or 0) + 1
				end
				if item.type == "Shield" and env.allocNodes[45175] and env.allocNodes[45175].dn == "Necromantic Aegis" then
					-- Special handling for Necromantic Aegis
					env.aegisModList = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						-- Filter out mods that apply to socketed gems, or which add supports
						local add = true
						for _, tag in ipairs(mod) do
							if tag.type == "SocketedIn" then
								add = false
								break
							end
						end
						if add then
							env.aegisModList:ScaleAddMod(mod, scale)
						else
							env.itemModDB:ScaleAddMod(mod, scale)
						end
					end
				elseif (slotName == "Weapon 1" or slotName == "Weapon 2") and modDB.conditions["AffectedByEnergyBlade"] then
					local previousItem = env.player.itemList[slotName]
					local type = previousItem and previousItem.weaponData and previousItem.weaponData[1].type
					local info = env.data.weaponTypeInfo[type]
					if info and type ~= "Bow" then
						local name = info.oneHand and "Energy Blade One Handed" or "Energy Blade Two Handed"
						local item = new("Item"):Item()
						item.name = name
						item.base = data.itemBases[name]
						item.baseName = name
						item.classRequirementModLines = { }
						item.buffModLines = { }
						item.enchantModLines = { }
						item.scourgeModLines = { }
						item.implicitModLines = { }
						item.explicitModLines = { }
						item.crucibleModLines = { }
						item.quality = 0
						item.rarity = "NORMAL"
						if item.baseName.implicit then
							local implicitIndex = 1
							for line in item.baseName.implicit:gmatch("[^\n]+") do
								local modList, extra = modLib.parseMod(line)
								t_insert(item.implicitModLines, { line = line, extra = extra, modList = modList or { }, modTags = item.baseName.implicitModTypes and item.baseName.implicitModTypes[implicitIndex] or { } })
								implicitIndex = implicitIndex + 1
							end
						end
						item:NormaliseQuality()
						item:BuildAndParseRaw()
						item.sockets = previousItem.sockets
						item.abyssalSocketCount = previousItem.abyssalSocketCount
						env.player.itemList[slotName] = item
					else
						env.itemModDB:ScaleAddList(srcList, scale)
					end
				elseif slotName == "Weapon 1" and item.name == "The Iron Mass, Gladius" then
					-- Special handling for The Iron Mass
					env.theIronMass = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						-- Filter out mods that apply to socketed gems, or which add supports
						local add = true
						for _, tag in ipairs(mod) do
							if tag.type == "SocketedIn" then
								add = false
								break
							end
						end
						if add then
							env.theIronMass:ScaleAddMod(mod, scale)
						end
						-- Add all the stats to player as well
						env.itemModDB:ScaleAddMod(mod, scale)
					end
				elseif slotName == "Weapon 1" and item.grantedSkills[1] and item.grantedSkills[1].skillId == "UniqueAnimateWeapon" then
					-- Special handling for The Dancing Dervish
					env.weaponModList1 = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						-- Filter out mods that apply to socketed gems, or which add supports
						local add = true
						for _, tag in ipairs(mod) do
							if tag.type == "SocketedIn" then
								add = false
								break
							end
						end
						if add then
							env.weaponModList1:ScaleAddMod(mod, scale)
						else
							env.itemModDB:ScaleAddMod(mod, scale)
						end
					end
				elseif item.name:match("Kalandra's Touch") then
					local otherRing = items[(slotName == "Ring 1" and "Ring 2") or (slotName == "Ring 2" and "Ring 1")]
					if otherRing and not otherRing.name:match("Kalandra's Touch") then
						for _, mod in ipairs(otherRing.modList or otherRing.slotModList[slot.slotNum] or {}) do
							-- Filter out SocketedIn type mods
							for _, tag in ipairs(mod) do
								if tag.type == "SocketedIn" then
									goto skip_mod
								end
							end

							local modCopy = copyTable(mod)
							modLib.setSource(modCopy, item.modSource)
							env.itemModDB:ScaleAddMod(modCopy, scale)

							::skip_mod::
						end
						-- Adjust multipliers based on other ring
						for mult, property in pairs({["CorruptedItem"] = "corrupted", ["ShaperItem"] = "shaper", ["ElderItem"] = "elder", ["WarlordItem"] = "adjudicator", ["HunterItem"] = "basilisk", ["CrusaderItem"] = "crusader", ["RedeemerItem"] = "eyrie"}) do
							if otherRing[property] then
								env.itemModDB.multipliers[mult] = (env.itemModDB.multipliers[mult] or 0) + 1
								env.itemModDB.multipliers["Non"..mult] = (env.itemModDB.multipliers["Non"..mult] or 0) - 1
							end
						end
						if otherRing.elder or otherRing.shaper then
							env.itemModDB.multipliers.ShaperOrElderItem = (env.itemModDB.multipliers.ShaperOrElderItem or 0) + 1
						end
						-- Esh of the Storm, Tul of the Blizzard
						local otherRingKey = otherRing.baseName:gsub(" ", "").."Equipped"
						if otherRingKey then
							env.itemModDB.multipliers[otherRingKey] = (env.itemModDB.multipliers[otherRingKey] or 0) + 1
						end
					end
					-- Only ExtraSkill implicit mods work (none should but this is likely an in game bug)
					for _, mod in ipairs(srcList) do
						if mod.name == "ExtraSkill" then
							env.itemModDB:ScaleAddMod(mod, scale)
						end
					end
				elseif item.type == "Quiver" and (items["Weapon 1"] and items["Weapon 1"].name:match("Widowhail") or env.initialNodeModDB:Sum("INC", nil, "EffectOfBonusesFromQuiver") > 0) then
					local widowHailMod= (1 + (items["Weapon 1"] and items["Weapon 1"].baseModList:Sum("INC", nil, "EffectOfBonusesFromQuiver") + env.initialNodeModDB:Sum("INC", nil, "EffectOfBonusesFromQuiver") or 100) / 100)
					scale = scale * widowHailMod
					env.modDB:NewMod("WidowHailMultiplier", "BASE", widowHailMod, "Widowhail")
					local combinedList = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						combinedList:MergeMod(mod)
					end
					env.itemModDB:ScaleAddList(combinedList, scale)
				elseif env.modDB.multipliers["Corrupted" .. item.rarity:gsub("(%a)(%u*)", function(a, b) return a..string.lower(b) end) .. "JewelEffect"] and item.type == "Jewel" and item.corrupted and slot.nodeId and item.base.subType ~= "Charm" and not env.spec.nodes[slot.nodeId].containJewelSocket then
					scale = scale + env.modDB.multipliers["Corrupted" .. item.rarity:gsub("(%a)(%u*)", function(a, b) return a..string.lower(b) end) .. "JewelEffect"]
					local combinedList = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						combinedList:MergeMod(mod)
					end	
					env.itemModDB:ScaleAddList(combinedList, scale)
				elseif item.type == "Gloves" and calcLib.mod(env.initialNodeModDB, nil, "EffectOfBonusesFromGloves") ~=1 then
					scale = calcLib.mod(env.initialNodeModDB, nil, "EffectOfBonusesFromGloves") - 1
					local combinedList = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						combinedList:MergeMod(mod)
					end
					local scaledList = new("ModList"):ModList()
					scaledList:ScaleAddList(combinedList, scale)
					for _, mod in ipairs(scaledList) do
						combinedList:MergeMod(mod, true)
					end
					env.itemModDB:AddList(combinedList)
				elseif item.type == "Boots" and calcLib.mod(env.initialNodeModDB, nil, "EffectOfBonusesFromBoots") ~= 1 then
					scale = calcLib.mod(env.initialNodeModDB, nil, "EffectOfBonusesFromBoots") - 1
					local combinedList = new("ModList"):ModList()
					for _, mod in ipairs(srcList) do
						combinedList:MergeMod(mod)
					end
					local scaledList = new("ModList"):ModList()
					scaledList:ScaleAddList(combinedList, scale)
					for _, mod in ipairs(scaledList) do
						combinedList:MergeMod(mod, true)
					end
					env.itemModDB:AddList(combinedList)
				else
					env.itemModDB:ScaleAddList(srcList, scale)
				end
				-- set conditions on restricted items
				if item.classRestriction then
					env.itemModDB.conditions[item.title:gsub(" ", "")] = item.classRestriction
				end
				if item.type ~= "Jewel" and item.type ~= "Flask" and item.type ~= "Tincture" and item.type ~= "Graft" then
					-- Update item counts
					local key
					if item.rarity == "UNIQUE" or item.rarity == "RELIC" then
						if item.foulborn then
							env.itemModDB.multipliers["FoulbornUniqueItem"] = (env.itemModDB.multipliers["FoulbornUniqueItem"] or 0) + 1
						end
						key = "UniqueItem"
					elseif item.rarity == "RARE" then
						key = "RareItem"
					elseif item.rarity == "MAGIC" then
						key = "MagicItem"
					else
						key = "NormalItem"
					end
					env.itemModDB.multipliers[key] = (env.itemModDB.multipliers[key] or 0) + 1
					env.itemModDB.conditions[key .. "In" .. slotName] = true
					for mult, property in pairs({["CorruptedItem"] = "corrupted", ["ShaperItem"] = "shaper", ["ElderItem"] = "elder", ["WarlordItem"] = "adjudicator", ["HunterItem"] = "basilisk", ["CrusaderItem"] = "crusader", ["RedeemerItem"] = "eyrie"}) do
						if item[property] then
							env.itemModDB.multipliers[mult] = (env.itemModDB.multipliers[mult] or 0) + 1
						else
							env.itemModDB.multipliers["Non"..mult] = (env.itemModDB.multipliers["Non"..mult] or 0) + 1
						end
					end
					if item.shaper or item.elder then
						env.itemModDB.multipliers.ShaperOrElderItem = (env.itemModDB.multipliers.ShaperOrElderItem or 0) + 1
					end
					env.itemModDB.multipliers[item.type:gsub(" ", ""):gsub(".+Handed", "").."Item"] = (env.itemModDB.multipliers[item.type:gsub(" ", ""):gsub(".+Handed", "").."Item"] or 0) + 1
					-- base ring count, e.g. Cryonic, Synaptic for Breachlord Esh of the Storm, Tul of the Blizzard
					if item.type == "Ring" then
						local key = item.baseName:gsub(" ", "").."Equipped"
						env.itemModDB.multipliers[key] = (env.itemModDB.multipliers[key] or 0) + 1
					end
					-- Calculate socket counts
					local slotEmptySocketsCount = { R = 0, G = 0, B = 0, W = 0}	
					local slotGemSocketsCount = 0
					local socketedGems = { }
					-- Loop through socket groups to calculate number of socketed gems
					for _, socketGroup in ipairs(env.build.skillsTab.socketGroupList) do
						if (not socketGroup.source and socketGroup.enabled and socketGroup.slot and socketGroup.slot == slotName and socketGroup.gemList) then
							for _, gem in ipairs(socketGroup.gemList) do
								if (gem.gemData and gem.enabled) then
									t_insert(socketedGems, gem)
								end
							end
						end
					end
					for i, socket in ipairs(item.sockets) do
						-- Check socket color to ignore abyssal sockets
						if socket.color == 'R' or socket.color == 'B' or socket.color == 'G' or socket.color == 'W' then
							slotGemSocketsCount = slotGemSocketsCount + 1
							-- loop through sockets indexes that are greater than number of socketed gems
							if i > #socketedGems then
								slotEmptySocketsCount[socket.color] = slotEmptySocketsCount[socket.color] + 1
							end
						end
					end
					local socketedColours = { R = 0, G = 0, B = 0 }
					-- Only gems that fit in the item's sockets contribute to multipliers
					for i = 1, math.min(slotGemSocketsCount, #socketedGems) do
						local tags = socketedGems[i].gemData.tags
						if tags and tags.strength then
							socketedColours.R = socketedColours.R + 1
						end
						if tags and tags.dexterity then
							socketedColours.G = socketedColours.G + 1
						end
						if tags and tags.intelligence then
							socketedColours.B = socketedColours.B + 1
						end
					end
					env.itemModDB.multipliers["SocketedGemsIn" .. slotName] = math.min(slotGemSocketsCount, #socketedGems)
					env.itemModDB.multipliers["SocketedRedGemsIn" .. slotName] = socketedColours.R
					env.itemModDB.multipliers["SocketedGreenGemsIn" .. slotName] = socketedColours.G
					env.itemModDB.multipliers["SocketedBlueGemsIn" .. slotName] = socketedColours.B
					env.itemModDB.multipliers["EmptySocketIn" .. slotName] = math.min(slotGemSocketsCount, slotEmptySocketsCount.R + slotEmptySocketsCount.G + slotEmptySocketsCount.B + slotEmptySocketsCount.W)
					env.itemModDB.multipliers.EmptyRedSocketsInAnySlot = (env.itemModDB.multipliers.EmptyRedSocketsInAnySlot or 0) + slotEmptySocketsCount.R
					env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot = (env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot or 0) + slotEmptySocketsCount.G
					env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot = (env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot or 0) + slotEmptySocketsCount.B
					env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot = (env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot or 0) + slotEmptySocketsCount.W
					-- Warn if socketed gems over socket limit
					if #socketedGems > slotGemSocketsCount then
						env.itemWarnings.socketLimitWarning = env.itemWarnings.socketLimitWarning or { }
						t_insert(env.itemWarnings.socketLimitWarning, slotName)
					end
				end
			end
		end
		-- Override empty socket calculation if set in config
		env.itemModDB.multipliers.EmptyRedSocketsInAnySlot = (env.configInput.overrideEmptyRedSockets or env.itemModDB.multipliers.EmptyRedSocketsInAnySlot)
		env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot = (env.configInput.overrideEmptyGreenSockets or env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot)
		env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot = (env.configInput.overrideEmptyBlueSockets or env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot)
		env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot = (env.configInput.overrideEmptyWhiteSockets or env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot)
		if override.toggleFlask then
			if env.flasks[override.toggleFlask] then
				env.flasks[override.toggleFlask] = nil
			else
				env.flasks[override.toggleFlask] = true
			end
		end
		if override.toggleTincture then
			if env.tinctures[override.toggleTincture] then
				env.tinctures[override.toggleTincture] = nil
			else
				env.tinctures[override.toggleTincture] = true
			end
		end
	end

	-- Merge env.itemModDB with env.ModDB
	mergeDB(env.modDB, env.itemModDB)

	-- Add granted passives (e.g., amulet anoints)
	if not accelerate.nodeAlloc then
		for _, passive in pairs(env.modDB:List(nil, "GrantedPassive")) do
			local node = env.spec.tree.notableMap[passive] or env.spec.tree.ascendancyMap[passive]
			local specNode = node and env.spec.nodes[node.id] -- use the conquered node data, if available
			node = node or build.latestTree.ascendancyMap[passive]
			if node and (not override.removeNodes or not override.removeNodes[node.id]) then
				env.allocNodes[node.id] = specNode or node
				env.grantedPassives[node.id] = true
				env.extraRadiusNodeList[node.id] = nil
			end
		end
	end

	-- Add granted ascendancy node (e.g., Forbidden Flame/Flesh combo)
	local matchedName = { }
	for _, ascTbl in pairs(env.modDB:List(nil, "GrantedAscendancyNode")) do
		local name = ascTbl.name
		if matchedName[name] and matchedName[name].side ~= ascTbl.side and matchedName[name].matched == false then
			matchedName[name].matched = true
			local node = env.spec.tree.ascendancyMap[name] or build.latestTree.ascendancyMap[name]
			if node and (not override.removeNodes or not override.removeNodes[node.id]) then
				if env.itemModDB.conditions["ForbiddenFlesh"] == env.spec.curClassName and env.itemModDB.conditions["ForbiddenFlame"] == env.spec.curClassName then
					env.allocNodes[node.id] = node
					env.grantedPassives[node.id] = true
				end
			end
		else
			matchedName[name] = { side = ascTbl.side, matched = false }
		end
	end

	-- Merge modifiers for allocated passives
	do
		local modList, explodeSources = calcs.buildModListForNodeList(env, env.allocNodes, true)
		env.modDB:AddList(modList)
		env.explodeSources = tableConcat(explodeSources, env.explodeSources)
	end
	if not override or (override and not override.extraJewelFuncs) then
		override = override or {}
		override.extraJewelFuncs = new("ModList"):ModList()
		override.extraJewelFuncs.actor = env.player
		for _, mod in ipairs(env.modDB:Tabulate("LIST", nil, "ExtraJewelFunc")) do
			override.extraJewelFuncs:AddMod(mod.mod)
		end
		if #override.extraJewelFuncs > 0 then
			return calcs.initEnv(build, mode, override, specEnv)
		end
	end

	-- Find skills granted by tree nodes
	if not accelerate.nodeAlloc then
		for _, node in pairs(env.allocNodes) do
			for _, skill in ipairs(node.grantedSkills) do
				local grantedSkill = copyTable(skill)
				grantedSkill.sourceNode = node
				t_insert(env.grantedSkillsNodes, grantedSkill)
			end
		end
	end

	-- Merge Granted Skills Tables
	env.grantedSkills = tableConcat(env.grantedSkillsNodes, env.grantedSkillsItems)

	if not accelerate.skills then
		if env.mode == "MAIN" then
			local function getNormalizedSkillLevel(grantedSkill)
				-- Levels in socketGroup.gemList[1].level are normalized
				-- grantedSkill.level is not causing group match miss which causes all things that rely on group order to fail
				local normalizedGrantedSkill = {
					grantedEffect = data.skills[grantedSkill.skillId],
					level = grantedSkill.level
				}
				calcLib.validateGemLevel(normalizedGrantedSkill)
				return normalizedGrantedSkill.level
			end

			-- Process extra skills granted by items or tree nodes
			local markList = wipeTable(tempTable1)
			for _, grantedSkill in ipairs(env.grantedSkills) do
				-- Check if a matching group already exists
				local group
				for index, socketGroup in pairs(build.skillsTab.socketGroupList) do
					if socketGroup.source == grantedSkill.source and socketGroup.slot == grantedSkill.slotName then
						if socketGroup.gemList[1] and socketGroup.gemList[1].skillId == grantedSkill.skillId and (socketGroup.gemList[1].level == grantedSkill.level or socketGroup.gemList[1].level == getNormalizedSkillLevel(grantedSkill)) then
							group = socketGroup
							markList[socketGroup] = true
							break
						end
					end
				end
				if not group then
					-- Create a new group for this skill
					group = { label = "", enabled = true, gemList = { }, source = grantedSkill.source, slot = grantedSkill.slotName }
					t_insert(build.skillsTab.socketGroupList, group)
					markList[group] = true
				end

				-- Update the group
				group.sourceItem = grantedSkill.sourceItem
				group.sourceNode = grantedSkill.sourceNode
				local activeGemInstance = group.gemList[1] or {
					skillId = grantedSkill.skillId,
					nameSpec = grantedSkill.nameSpec,
					quality = 0,
					enabled = true,
				}
				activeGemInstance.fromItem = grantedSkill.sourceItem ~= nil
				activeGemInstance.gemId = nil
				activeGemInstance.level = grantedSkill.level
				activeGemInstance.enableGlobal1 = true
				activeGemInstance.noSupports = grantedSkill.noSupports
				group.noSupports = grantedSkill.noSupports
				activeGemInstance.triggered = grantedSkill.triggered
				activeGemInstance.triggerChance = grantedSkill.triggerChance
				wipeTable(group.gemList)
				t_insert(group.gemList, activeGemInstance)
				build.skillsTab:ProcessSocketGroup(group)
			end

			if #env.explodeSources ~= 0 then
				-- Check if a matching group already exists
				local group
				for _, socketGroup in pairs(build.skillsTab.socketGroupList) do
					if socketGroup.source == "Explode" then
						group = socketGroup
						break
					end
				end
				if not group then
					-- Create a new group for this skill
					group = { label = "On Kill Monster Explosion", enabled = true, gemList = { }, source = "Explode", noSupports = true }
					t_insert(build.skillsTab.socketGroupList, group)
				end
				-- Update the group
				group.explodeSources = env.explodeSources
				local gemsBySource = { }
				for _, gem in ipairs(group.gemList) do
					if gem.explodeSource then
						gemsBySource[gem.explodeSource.modSource or gem.explodeSource.id] = gem
					end
				end
				wipeTable(group.gemList)
				for _, explodeSource in ipairs(env.explodeSources) do
					local activeGemInstance
					if gemsBySource[explodeSource.modSource or explodeSource.id] then
						activeGemInstance = gemsBySource[explodeSource.modSource or explodeSource.id]
					else
						activeGemInstance = {
							skillId = "EnemyExplode",
							quality = 0,
							enabled = true,
							level = 1,
							triggered = true,
							explodeSource = explodeSource,
						}
					end
					t_insert(group.gemList, activeGemInstance)
				end
				markList[group] = true
				build.skillsTab:ProcessSocketGroup(group)
			end

			-- Remove any socket groups that no longer have a matching item
			local i = 1
			while build.skillsTab.socketGroupList[i] do
				local socketGroup = build.skillsTab.socketGroupList[i]
				if socketGroup.source and not markList[socketGroup] then
					t_remove(build.skillsTab.socketGroupList, i)
					if build.skillsTab.displayGroup == socketGroup then
						build.skillsTab.displayGroup = nil
					end
				else
					i = i + 1
				end
			end
		end

		-- Get the weapon data tables for the equipped weapons
		env.player.weaponData1 = env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 1"].weaponData and env.player.itemList["Weapon 1"].weaponData[1] or copyTable(env.data.unarmedWeaponData[env.classId])
		if env.player.weaponData1.countsAsDualWielding then
			env.player.weaponData2 = env.player.itemList["Weapon 1"].weaponData[2]
		elseif not env.player.itemList["Weapon 2"] then
			-- Hollow Palm Technique
			if (not env.player.itemList["Weapon 1"]) and (not env.player.itemList["Gloves"]) and env.modDB.mods.Keystone then
				for _, keystone in ipairs(env.modDB.mods.Keystone) do
					if keystone.value == "Hollow Palm Technique" then
						env.player.weaponData2 = copyTable(env.data.unarmedWeaponData[env.classId])
						break
					end
				end
			end
			env.player.weaponData2 = env.player.weaponData2 or { }
		else
			env.player.weaponData2 = env.player.itemList["Weapon 2"].weaponData and env.player.itemList["Weapon 2"].weaponData[2] or { }
		end

		-- Determine main skill group
		if env.mode == "CALCS" then
			env.calcsInput.skill_number = m_min(m_max(#build.skillsTab.socketGroupList, 1), env.calcsInput.skill_number or 1)
			env.mainSocketGroup = env.calcsInput.skill_number
		else
			build.mainSocketGroup = m_min(m_max(#build.skillsTab.socketGroupList, 1), build.mainSocketGroup or 1)
			env.mainSocketGroup = build.mainSocketGroup
		end

		-- Process supports and put them into the correct buckets
		env.crossLinkedSupportGroups = {}
		for _, mod in ipairs(env.modDB:Tabulate("LIST", nil, "LinkedSupport")) do
			env.crossLinkedSupportGroups[mod.mod.sourceSlot] = env.crossLinkedSupportGroups[mod.mod.sourceSlot] or {}
			t_insert(env.crossLinkedSupportGroups[mod.mod.sourceSlot], mod.value.targetSlotName)
		end

		local supportLists = { }
		local groupCfgList = { }
		local processedSockets = {}
		-- Process support gems adding them to applicable support lists
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			local slot = group.slot and build.itemsTab.slots[group.slot]
			group.slotEnabled = not slot or not slot.weaponSet or slot.weaponSet == (build.itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1)
			-- if group is main skill or group is enabled 
			if index == env.mainSocketGroup or (group.enabled and group.slotEnabled) then
				local isTreeSkill = not group.slot and group.source and group.source:lower():find("tree")
				local slotName = group.slot and group.slot:gsub(" Swap", "") or (isTreeSkill and "Passive Tree") or nil
				groupCfgList[slotName or "noSlot"] = groupCfgList[slotName or "noSlot"] or {}
				groupCfgList[slotName or "noSlot"][group] = groupCfgList[slotName or "noSlot"][group] or {
					slotName = slotName,
					propertyModList = env.modDB:Tabulate("LIST", {slotName = slotName}, "GemProperty")
				}
				local groupCfg = groupCfgList[slotName or "noSlot"][group]
				local propertyModList = groupCfg.propertyModList
				local targetListList = {}
				if groupCfg.slotName then
					supportLists[groupCfg.slotName] = supportLists[groupCfg.slotName] or {}
					supportLists[groupCfg.slotName][group] = supportLists[groupCfg.slotName][group] or {}
					t_insert(targetListList, supportLists[groupCfg.slotName][group])
				else
					supportLists[group] = supportLists[group] or {}
					t_insert(targetListList, supportLists[group])
				end

				local function addExtraSupports(value, grantedEffect, level)
					local grantedEffect = grantedEffect or env.data.skills[value.skillId]
					-- Some skill gems share the same name as support gems, e.g. Barrage.
					-- Since a support gem is expected here, if the first lookup returns a skill, then
					-- prepending "Support" to the skillId will find the support version of the gem.
					if value and grantedEffect and not grantedEffect.support then
						grantedEffect = env.data.skills["Support"..value.skillId]
					end
					if value and grantedEffect then -- Only item ExtraSupport gems should be flagged as fromItem. Imbued gems do not pass this check
						grantedEffect.fromItem = true
					end
					if grantedEffect then
						for _, targetList in ipairs(targetListList) do
							addBestSupport({
								grantedEffect = grantedEffect,
								gemData = env.data.gems[env.data.gemForBaseName[grantedEffect.name:lower()] or env.data.gemForBaseName[(grantedEffect.name .. " Support"):lower()]],
								level = level or value.level,
								appliesToGrantedSkills = value and value.appliesToGrantedSkills,
								quality = 0,
								enabled = true,
							}, targetList, env.mode)
						end
					end
				end

				-- Add extra supports from the item this group is socketed in
				for _, value in ipairs(env.modDB:List(groupCfg, "ExtraSupport")) do
					if not group.source or value.appliesToGrantedSkills then
						addExtraSupports(value)
					end
				end
				-- if the slot has an imbued support, add it as an ExtraSupport
				if build.skillsTab.imbuedSupportBySlot and build.skillsTab.imbuedSupportBySlot[slotName] and group.imbuedSupport then
					local imbuedSupport = build.skillsTab.imbuedSupportBySlot[slotName]
					addExtraSupports(nil, imbuedSupport, 1)
					local imbuedGemData = env.data.gems[env.data.gemForSkill[imbuedSupport]]
					if imbuedGemData and imbuedGemData.secondaryGrantedEffect and imbuedGemData.secondaryGrantedEffect.support then
						addExtraSupports(nil, imbuedGemData.secondaryGrantedEffect, 1)
					end
				end

				for gemIndex, gemInstance in ipairs(group.gemList) do
					-- Add support gems from this group
					if env.mode == "MAIN" then
						gemInstance.displayEffect = nil
						gemInstance.supportEffect = nil
					end
					if gemInstance.enabled then
						local function processGrantedEffect(grantedEffect)
							if not grantedEffect or not grantedEffect.support then
								return
							end
							local actualQuality = gemInstance.quality + (gemInstance.matchesSocket and data.misc.MatchingSocketQualityBonus or 0)
							local supportEffect = {
								grantedEffect = grantedEffect,
								level = gemInstance.level,
								quality = actualQuality,
								globalQuality = 0,
								itemQuality = 0,
								supportQuality = 0,
								socketQuality = gemInstance.matchesSocket and data.misc.MatchingSocketQualityBonus or 0,
								srcInstance = gemInstance,
								gemData = gemInstance.gemData,
								superseded = false,
								isSupporting = { },
							}
							if env.mode == "MAIN" then
								gemInstance.displayEffect = supportEffect
								gemInstance.supportEffect = supportEffect
							end
							if gemInstance.gemData then
								local playerItems = env.player.itemList
								local socketedIn = playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].sockets and playerItems[groupCfg.slotName].sockets[gemIndex]
								supportEffect.gemCfg = copyTable(groupCfg, true)
								supportEffect.gemCfg.socketColor = socketedIn and socketedIn.color
								supportEffect.gemCfg.socketNum = gemIndex
								applyGemMods(supportEffect, socketedIn and env.modDB:Tabulate("LIST", supportEffect.gemCfg, "GemProperty") or propertyModList)
								gemInstance.reqOverride = supportEffect.req
								if not processedSockets[gemInstance] then
									processedSockets[gemInstance] = true
									applySocketMods(env, gemInstance.gemData, groupCfg, gemIndex, playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].name)
									-- Keep track of the gem count for each color socketed in this group
									groupCfg.intelligenceGems = (groupCfg.intelligenceGems or 0) + (gemInstance.gemData.tags.intelligence and 1 or 0)
									groupCfg.dexterityGems = (groupCfg.dexterityGems or 0) + (gemInstance.gemData.tags.dexterity and 1 or 0)
									groupCfg.strengthGems = (groupCfg.strengthGems or 0) + (gemInstance.gemData.tags.strength and 1 or 0)
								end
							end
							-- Validate support gem level in case there is no active skill (and no full calculation)
							calcLib.validateGemLevel(supportEffect)

							for _, targetList in ipairs(targetListList) do
								addBestSupport(supportEffect, targetList, env.mode)
							end
						end
						if gemInstance.gemData then
							processGrantedEffect(gemInstance.gemData.grantedEffect)
							processGrantedEffect(gemInstance.gemData.secondaryGrantedEffect)
						else
							processGrantedEffect(gemInstance.grantedEffect)
						end
					end
				end
			end
		end

		-- Process active skills adding the applicable supports
		local socketGroupSkillListList = { }
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			if index == env.mainSocketGroup or (group.enabled and group.slotEnabled) then
				local isTreeSkill = not group.slot and group.source and group.source:lower():find("tree")
				local slotName = group.slot and group.slot:gsub(" Swap", "") or (isTreeSkill and "Passive Tree") or nil
				groupCfgList[slotName or "noSlot"][group] = groupCfgList[slotName or "noSlot"][group] or {
					slotName = slotName,
					propertyModList = env.modDB:Tabulate("LIST", {slotName = slotName}, "GemProperty")
				}
				local groupCfg = groupCfgList[slotName or "noSlot"][group]
				local propertyModList = groupCfg.propertyModList
				socketGroupSkillListList[slotName or "noSlot"] = socketGroupSkillListList[slotName or "noSlot"] or {}
				socketGroupSkillListList[slotName or "noSlot"][group] = socketGroupSkillListList[slotName or "noSlot"][group] or {}
				local socketGroupSkillList = socketGroupSkillListList[slotName or "noSlot"][group]
				local slotHasActiveSkill = false

				-- Create active skills
				for gemIndex, gemInstance in ipairs(group.gemList) do
					if gemInstance.enabled and (gemInstance.gemData or gemInstance.grantedEffect) then
						local grantedEffectList = gemInstance.gemData and gemInstance.gemData.grantedEffectList or { gemInstance.grantedEffect }
						for index, grantedEffect in ipairs(grantedEffectList) do
							if not grantedEffect.support and not grantedEffect.unsupported and (not grantedEffect.hasGlobalEffect or gemInstance["enableGlobal"..index]) then
								slotHasActiveSkill = true
								local actualQuality = gemInstance.quality + (gemInstance.matchesSocket and data.misc.MatchingSocketQualityBonus or 0)
								local activeEffect = {
									grantedEffect = grantedEffect,
									level = gemInstance.level,
									quality = actualQuality,
									globalQuality = 0,
									itemQuality = 0,
									supportQuality = 0,
									socketQuality = gemInstance.matchesSocket and data.misc.MatchingSocketQualityBonus or 0,
									srcInstance = gemInstance,
									gemData = gemInstance.gemData,
								}
								if gemInstance.gemData then
									local playerItems = env.player.itemList
									local socketedIn = playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].sockets and playerItems[groupCfg.slotName].sockets[gemIndex]
									activeEffect.gemCfg = copyTable(groupCfg, true)
									activeEffect.gemCfg.socketColor = socketedIn and socketedIn.color
									activeEffect.gemCfg.socketNum = gemIndex
									applyGemMods(activeEffect, socketedIn and env.modDB:Tabulate("LIST", activeEffect.gemCfg, "GemProperty") or propertyModList)
									gemInstance.reqOverride = activeEffect.req
									if not processedSockets[gemInstance] then
										processedSockets[gemInstance] = true
										applySocketMods(env, gemInstance.gemData, groupCfg, gemIndex, playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].name)
										-- Keep track of the gem count for each color socketed in this group
										groupCfg.intelligenceGems = (groupCfg.intelligenceGems or 0) + (gemInstance.gemData.tags.intelligence and 1 or 0)
										groupCfg.dexterityGems = (groupCfg.dexterityGems or 0) + (gemInstance.gemData.tags.dexterity and 1 or 0)
										groupCfg.strengthGems = (groupCfg.strengthGems or 0) + (gemInstance.gemData.tags.strength and 1 or 0)
									end
								end
								if env.mode == "MAIN" then
									gemInstance.displayEffect = activeEffect
								end
								local appliedSupportList = {}
								if not group.noSupports then
									appliedSupportList = copyTable(supportLists[group] or supportLists[slotName][group], true)
									-- add displayGemList for tooltip to display all gems linked to active skills
									group.displayGemList = copyTable(group.gemList, true)
									-- if skill granted by unique item, go through all support groups in slot
									if group.source then 
										if supportLists[slotName] then
											-- add socketed supports from other socketGroups
											for _, otherSocketGroup in ipairs(build.skillsTab.socketGroupList) do
												if otherSocketGroup.slot and otherSocketGroup.slot == group.slot and not (otherSocketGroup.source and otherSocketGroup.source == group.source) then
													for _, gem in ipairs(otherSocketGroup.gemList) do
														if gem.gemData and gem.gemData.grantedEffect and gem.gemData.grantedEffect.support then
															t_insert(group.displayGemList, gem)
														end
													end
												end
											end
											for _, supportGroup in pairs(supportLists[slotName]) do
												for _, supportEffect in ipairs(supportGroup) do
													addBestSupport(supportEffect, appliedSupportList, env.mode)
												end
											end
										end
									end
									-- then add supports from crossLinked socketGroups
									for crossLinkedSupportSlot, crossLinkedSupportGroup in pairs(env.crossLinkedSupportGroups) do
										for _, crossLinkedSupportedSlot in ipairs(crossLinkedSupportGroup) do
											if crossLinkedSupportedSlot == slotName and supportLists[crossLinkedSupportSlot] then
												for _, otherSocketGroup in ipairs(build.skillsTab.socketGroupList) do 
													if otherSocketGroup.slot and otherSocketGroup.slot == crossLinkedSupportSlot then 
														for _, gem in ipairs(otherSocketGroup.gemList) do
															if gem.gemData and gem.gemData.grantedEffect and gem.gemData.grantedEffect.support then
																t_insert(group.displayGemList, gem)
															end
														end
													end
												end
												for _, supportGroup in pairs(supportLists[crossLinkedSupportSlot]) do
													for _, supportEffect in ipairs(supportGroup) do
														addBestSupport(supportEffect, appliedSupportList, env.mode)
													end
												end
											end
										end
									end
								end
								local activeSkill = calcs.createActiveSkill(activeEffect, appliedSupportList, env.player, group)
								if gemInstance.gemData then
									activeSkill.slotName = groupCfg.slotName
								end
								t_insert(socketGroupSkillList, activeSkill)
								t_insert(env.player.activeSkillList, activeSkill)
							end
						end
						if gemInstance.gemData and not accelerate.requirementsGems then
							t_insert(env.requirementsTableGems, {
								source = "Gem",
								sourceGem = gemInstance,
								Str = gemInstance.reqOverride or gemInstance.reqStr,
								Dex = gemInstance.reqOverride or gemInstance.reqDex,
								Int = gemInstance.reqOverride or gemInstance.reqInt,
							})
						end
					end
				end
				
				if not slotHasActiveSkill and group.displayGemList then
					group.displayGemList = nil
				end
			end
		end

		-- Process calculated active skill lists
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			local isTreeSkill = not group.slot and group.source and group.source:lower():find("tree")
			local slotName = group.slot and group.slot:gsub(" Swap", "") or (isTreeSkill and "Passive Tree") or nil
			socketGroupSkillListList[slotName or "noSlot"] = socketGroupSkillListList[slotName or "noSlot"] or {}
			socketGroupSkillListList[slotName or "noSlot"][group] = socketGroupSkillListList[slotName or "noSlot"][group] or {}
			local socketGroupSkillList = socketGroupSkillListList[slotName or "noSlot"][group]
			if index == env.mainSocketGroup or (group.enabled and group.slotEnabled) then
				groupCfgList[slotName or "noSlot"][group] = groupCfgList[slotName or "noSlot"][group] or {
					slotName = slotName,
					propertyModList = env.modDB:Tabulate("LIST", {slotName = slotName}, "GemProperty")
				}
				local groupCfg = groupCfgList[slotName or "noSlot"][group]
				for _, value in ipairs(env.modDB:List(groupCfg, "GroupProperty")) do
					env.player.modDB:AddMod(modLib.setSource(value.value, groupCfg.slotName or ""))
				end

				if index == env.mainSocketGroup and #socketGroupSkillList > 0 then
					-- Select the main skill from this socket group
					local activeSkillIndex
					if env.mode == "CALCS" then
						group.mainActiveSkillCalcs = m_min(#socketGroupSkillList, group.mainActiveSkillCalcs or 1)
						activeSkillIndex = group.mainActiveSkillCalcs
					else
						activeSkillIndex = m_min(#socketGroupSkillList, group.mainActiveSkill or 1)
						if env.mode == "MAIN" then
							group.mainActiveSkill = activeSkillIndex
						end
					end
					env.player.mainSkill = socketGroupSkillList[activeSkillIndex]
				end
			end

			if env.mode == "MAIN" then
				-- Create display label for the socket group if the user didn't specify one
				if group.label and group.label:match("%S") then
					group.displayLabel = group.label
				else
					group.displayLabel = nil
					for _, gemInstance in ipairs(group.gemList) do
						local grantedEffect = gemInstance.gemData and gemInstance.gemData.grantedEffect or gemInstance.grantedEffect
						if grantedEffect and not grantedEffect.support and gemInstance.enabled then
							group.displayLabel = (group.displayLabel and group.displayLabel..", " or "") .. grantedEffect.name
						end
					end
					group.displayLabel = group.displayLabel or "<No active skills>"
				end

				-- Save the active skill list for display in the socket group tooltip
				group.displaySkillList = socketGroupSkillList
			elseif env.mode == "CALCS" then
				group.displaySkillListCalcs = socketGroupSkillList
			end

			-- Check for enabled energy blade to see if we need to regenerate everything.
			if not modDB.conditions["AffectedByEnergyBlade"] and group.enabled and group.slotEnabled then
				for _, gemInstance in ipairs(group.gemList) do
					local grantedEffect = gemInstance.gemData and gemInstance.gemData.grantedEffect or gemInstance.grantedEffect
					if grantedEffect and not grantedEffect.support and gemInstance.enabled and grantedEffect.name == "Energy Blade" then
						override.conditions = override.conditions or { }
						t_insert(override.conditions, "AffectedByEnergyBlade")
						return calcs.initEnv(build, mode, override, specEnv)
					end
				end
			end
		end

		if not env.player.mainSkill then
			-- Add a default main skill if none are specified
			local defaultEffect = {
				grantedEffect = env.data.skills.Melee,
				level = 1,
				quality = 0,
				enabled = true,
			}
			env.player.mainSkill = calcs.createActiveSkill(defaultEffect, { }, env.player)
			t_insert(env.player.activeSkillList, env.player.mainSkill)
		end

		-- Build skill modifier lists
		for _, activeSkill in pairs(env.player.activeSkillList) do
			calcs.buildActiveSkillModList(env, activeSkill)
		end
	else
		-- Wipe skillData and readd required data the rest of the data will be added by the rest of code this stops iterative calculations on skillData not being reset
		for _, activeSkill in pairs(env.player.activeSkillList) do
			local skillData = copyTable(activeSkill.skillData, true)
			activeSkill.skillData = { }
			for _, value in ipairs(env.modDB:List(activeSkill.skillCfg, "SkillData")) do
				activeSkill.skillData[value.key] = value.value
			end
			for _, value in ipairs(activeSkill.skillModList:List(activeSkill.skillCfg, "SkillData")) do
				activeSkill.skillData[value.key] = value.value
			end
			-- These mods were modified with special expressions in buildActiveSkillModList() use old one to avoid more calculations
			activeSkill.skillData.manaReservationPercent = skillData.manaReservationPercent
			activeSkill.skillData.cooldown = skillData.cooldown
			activeSkill.skillData.storedUses = skillData.storedUses
			activeSkill.skillData.CritChance = skillData.CritChance
			activeSkill.skillData.attackTime = skillData.attackTime
			activeSkill.skillData.attackSpeedMultiplier = skillData.attackSpeedMultiplier
			activeSkill.skillData.soulPreventionDuration = activeSkill.soulPreventionDuration
			activeSkill.skillData.totemLevel = skillData.totemLevel
			activeSkill.skillData.damageEffectiveness = skillData.damageEffectiveness
			activeSkill.skillData.stagesMax = skillData.stagesMax
			activeSkill.skillData.manaReservationPercent = skillData.manaReservationPercent
		end
	end

	-- Merge Requirements Tables
	env.requirementsTable = tableConcat(env.requirementsTableItems, env.requirementsTableGems)
	if env.mercenaryFromCache then
		env.mercenaryFromCache = nil
	else
		calcs.initMercenary(env)
		cacheMercenaryBaseline(env)
	end

	return env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB
end
