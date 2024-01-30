-- Path of Building
--
-- Module: Calc Active Skill
-- Active skill setup.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local bor = bit.bor
local band = bit.band
local bnot = bit.bnot

-- Merge level modifier with given mod list
local mergeLevelCache = { }
local function mergeLevelMod(modList, mod, value)
	if not value then
		modList:AddMod(mod)
		return
	end
	if not mergeLevelCache[mod] then
		mergeLevelCache[mod] = { }
	end
	if mergeLevelCache[mod][value] then
		modList:AddMod(mergeLevelCache[mod][value])
	elseif value then
		local newMod = copyTable(mod, true)
		if type(newMod.value) == "table" then
			newMod.value = copyTable(newMod.value, true)
			if newMod.value.mod then
				newMod.value.mod = copyTable(newMod.value.mod, true)
				newMod.value.mod.value = value
			else
				newMod.value.value = value
			end
		else
			newMod.value = value
		end
		mergeLevelCache[mod][value] = newMod
		modList:AddMod(newMod)
	else
		modList:AddMod(mod)
	end
end

-- Merge skill modifiers with given mod list
function calcs.mergeSkillInstanceMods(env, modList, skillEffect, extraStats)
	calcLib.validateGemLevel(skillEffect)
	local grantedEffect = skillEffect.grantedEffect	
	local stats = calcLib.buildSkillInstanceStats(skillEffect, grantedEffect)
	if extraStats and extraStats[1] then
		for _, stat in pairs(extraStats) do
			stats[stat.key] = (stats[stat.key] or 0) + stat.value
		end
	end
	for stat, statValue in pairs(stats) do
		local map = grantedEffect.statMap[stat]
		if map then
			-- Some mods need different scalars for different stats, but the same value.  Putting them in a group allows this
			for _, modOrGroup in ipairs(map) do
				-- Found a mod, since all mods have names
				if modOrGroup.name then
					mergeLevelMod(modList, modOrGroup, map.value or statValue * (map.mult or 1) / (map.div or 1) + (map.base or 0))
				else
					for _, mod in ipairs(modOrGroup) do
						mergeLevelMod(modList, mod, modOrGroup.value or statValue * (modOrGroup.mult or 1) / (modOrGroup.div or 1) + (modOrGroup.base or 0))
					end
				end
			end
		end
	end
	modList:AddList(grantedEffect.baseMods)
end

-- Create an active skill using the given active gem and list of support gems
-- It will determine the base flag set, and check which of the support gems can support this skill
function calcs.createActiveSkill(activeEffect, supportList, actor, socketGroup, summonSkill)
	local activeSkill = {
		activeEffect = activeEffect,
		supportList = supportList,
		actor = actor,
		summonSkill = summonSkill,
		socketGroup = socketGroup,
		skillData = { },
		buffList = { },
	}

	local activeGrantedEffect = activeEffect.grantedEffect
	
	-- Initialise skill types
	activeSkill.skillTypes = copyTable(activeGrantedEffect.skillTypes)
	if activeGrantedEffect.minionSkillTypes then
		activeSkill.minionSkillTypes = copyTable(activeGrantedEffect.minionSkillTypes)
	end

	-- Initialise skill flag set ('attack', 'projectile', etc)
	local skillFlags = copyTable(activeGrantedEffect.baseFlags)
	activeSkill.skillFlags = skillFlags
	skillFlags.hit = skillFlags.hit or activeSkill.skillTypes[SkillType.Attack] or activeSkill.skillTypes[SkillType.Damage] or activeSkill.skillTypes[SkillType.Projectile]

	-- Process support skills
	activeSkill.effectList = { activeEffect }
	local rejectedSupportsIndices = {}

	for index, supportEffect in ipairs(supportList) do
		-- Pass 1: Add skill types from compatible supports
		if calcLib.canGrantedEffectSupportActiveSkill(supportEffect.grantedEffect, activeSkill) then
			for _, skillType in pairs(supportEffect.grantedEffect.addSkillTypes) do
				activeSkill.skillTypes[skillType] = true
			end
		else
			t_insert(rejectedSupportsIndices, index)
		end
	end

	-- loop over rejected supports until none are added.
	-- Makes sure that all skillType flags that should be added are added regardless of support gem order in group
	local notAddedNewSupport = true
	repeat
		notAddedNewSupport = true
		for index, supportEffectIndex in ipairs(rejectedSupportsIndices) do
			local supportEffect = supportList[supportEffectIndex]
			if calcLib.canGrantedEffectSupportActiveSkill(supportEffect.grantedEffect, activeSkill) then
				notAddedNewSupport = false
				rejectedSupportsIndices[index] = nil
				for _, skillType in pairs(supportEffect.grantedEffect.addSkillTypes) do
					activeSkill.skillTypes[skillType] = true
				end
			end
		end
	until (notAddedNewSupport)
	
	for _, supportEffect in ipairs(supportList) do
		-- Pass 2: Add all compatible supports
		if calcLib.canGrantedEffectSupportActiveSkill(supportEffect.grantedEffect, activeSkill) then
			t_insert(activeSkill.effectList, supportEffect)
			if supportEffect.isSupporting and activeEffect.srcInstance then
				supportEffect.isSupporting[activeEffect.srcInstance] = true
			end
			if supportEffect.grantedEffect.addFlags and not summonSkill then
				-- Support skill adds flags to supported skills (eg. Remote Mine adds 'mine')
				for k in pairs(supportEffect.grantedEffect.addFlags) do
					skillFlags[k] = true
				end
			end
		end
	end

	return activeSkill
end

-- Copy an Active Skill
function calcs.copyActiveSkill(env, mode, skill)
	local activeEffect = {
		grantedEffect = skill.activeEffect.grantedEffect,
		level = skill.activeEffect.srcInstance.level,
		quality = skill.activeEffect.srcInstance.quality,
		qualityId = skill.activeEffect.srcInstance.qualityId,
		srcInstance = skill.activeEffect.srcInstance,
		gemData = skill.activeEffect.srcInstance.gemData,
	}
	local newSkill = calcs.createActiveSkill(activeEffect, skill.supportList, skill.actor, skill.socketGroup, skill.summonSkill)
	local newEnv, _, _, _ = calcs.initEnv(env.build, mode, env.override)
	calcs.buildActiveSkillModList(newEnv, newSkill)
	newSkill.skillModList = new("ModList", newSkill.baseSkillModList)
	if newSkill.minion then
		newSkill.minion.modDB = new("ModDB")
		newSkill.minion.modDB.actor = newSkill.minion
		calcs.createMinionSkills(env, newSkill)
		newSkill.skillPartName = newSkill.minion.mainSkill.activeEffect.grantedEffect.name
	end
	return newSkill, newEnv
end

-- Get weapon flags and info for given weapon
local function getWeaponFlags(env, weaponData, weaponTypes)
	local info = env.data.weaponTypeInfo[weaponData.type]
	if not info then
		return
	end
	if weaponTypes then
		for _, types in ipairs(weaponTypes) do
			if not types[weaponData.type] and
			(not weaponData.countsAsAll1H or not (types["Claw"] or types["Dagger"] or types["One Handed Axe"] or types["One Handed Mace"] or types["One Handed Sword"])) then
				return nil, info
			end
		end
	end
	local flags = ModFlag[info.flag]
	if weaponData.countsAsAll1H then
		flags = bor(ModFlag.Axe, ModFlag.Claw, ModFlag.Dagger, ModFlag.Mace, ModFlag.Sword)
	end
	if weaponData.type ~= "None" then
		flags = bor(flags, ModFlag.Weapon)
		if info.oneHand then
			flags = bor(flags, ModFlag.Weapon1H)
		else
			flags = bor(flags, ModFlag.Weapon2H)
		end
		if info.melee then
			flags = bor(flags, ModFlag.WeaponMelee)
		else
			flags = bor(flags, ModFlag.WeaponRanged)
		end
	end
	return flags, info
end

-- Build list of modifiers for given active skill
function calcs.buildActiveSkillModList(env, activeSkill)
	local skillTypes = activeSkill.skillTypes
	local skillFlags = activeSkill.skillFlags
	local activeEffect = activeSkill.activeEffect
	local activeGrantedEffect = activeEffect.grantedEffect
	local effectiveRange = 0

	-- Set mode flags
	if env.mode_buffs then
		skillFlags.buffs = true
	end
	if env.mode_combat then
		skillFlags.combat = true
	end
	if env.mode_effective then
		skillFlags.effective = true
	end

	-- Handle multipart skills
	local activeGemParts = activeGrantedEffect.parts
	if activeGemParts and #activeGemParts > 1 then
		if env.mode == "CALCS" and activeSkill == env.player.mainSkill then
			activeEffect.srcInstance.skillPartCalcs = m_min(#activeGemParts, activeEffect.srcInstance.skillPartCalcs or 1)
			activeSkill.skillPart = activeEffect.srcInstance.skillPartCalcs
		else
			activeEffect.srcInstance.skillPart = m_min(#activeGemParts, activeEffect.srcInstance.skillPart or 1)
			activeSkill.skillPart = activeEffect.srcInstance.skillPart
		end
		local part = activeGemParts[activeSkill.skillPart]
		for k, v in pairs(part) do
			if v == true then
				skillFlags[k] = true
			elseif v == false then
				skillFlags[k] = nil
			end
		end
		activeSkill.skillPartName = part.name
		skillFlags.multiPart = #activeGemParts > 1
	elseif activeEffect.srcInstance and not (activeEffect.gemData and activeEffect.gemData.secondaryGrantedEffect) then
		activeEffect.srcInstance.skillPart = nil
		activeEffect.srcInstance.skillPartCalcs = nil
	end

	if (skillTypes[SkillType.RequiresShield] or skillFlags.shieldAttack) and not activeSkill.summonSkill and (not activeSkill.actor.itemList["Weapon 2"] or activeSkill.actor.itemList["Weapon 2"].type ~= "Shield") then
		-- Skill requires a shield to be equipped
		skillFlags.disable = true
		activeSkill.disableReason = "This skill requires a Shield"
	end

	if skillFlags.shieldAttack then
		-- Special handling for Spectral Shield Throw
		skillFlags.weapon2Attack = true
		activeSkill.weapon2Flags = 0
	else
		-- Set weapon flags
		local weaponTypes = { activeGrantedEffect.weaponTypes }
		for _, skillEffect in pairs(activeSkill.effectList) do
			if skillEffect.grantedEffect.support and skillEffect.grantedEffect.weaponTypes then
				t_insert(weaponTypes, skillEffect.grantedEffect.weaponTypes)
			end
		end
		local weapon1Flags, weapon1Info = getWeaponFlags(env, activeSkill.actor.weaponData1, weaponTypes)
		if not weapon1Flags and activeSkill.summonSkill then
			-- Minion skills seem to ignore weapon types
			weapon1Flags, weapon1Info = ModFlag[env.data.weaponTypeInfo["None"].flag], env.data.weaponTypeInfo["None"]
		end
		if weapon1Flags then
			if skillFlags.attack then
				activeSkill.weapon1Flags = weapon1Flags
				skillFlags.weapon1Attack = true
				if weapon1Info.melee and skillFlags.melee then
					skillFlags.projectile = nil
				elseif not weapon1Info.melee and skillFlags.projectile then
					skillFlags.melee = nil
				end
			end
		elseif (skillTypes[SkillType.DualWieldOnly] or skillTypes[SkillType.MainHandOnly] or skillFlags.forceMainHand or weapon1Info) and not activeSkill.summonSkill then
			-- Skill requires a compatible main hand weapon
			skillFlags.disable = true
			activeSkill.disableReason = "Main Hand weapon is not usable with this skill"
		end
		if not skillTypes[SkillType.MainHandOnly] and not skillFlags.forceMainHand then
			local weapon2Flags, weapon2Info = getWeaponFlags(env, activeSkill.actor.weaponData2, weaponTypes)
			if weapon2Flags then
				if skillFlags.attack then
					activeSkill.weapon2Flags = weapon2Flags
					skillFlags.weapon2Attack = true
				end
			elseif (skillTypes[SkillType.DualWieldOnly] or weapon2Info) and not activeSkill.summonSkill then
				-- Skill requires a compatible off hand weapon
				skillFlags.disable = true
				activeSkill.disableReason = activeSkill.disableReason or "Off Hand weapon is not usable with this skill"
			elseif skillFlags.disable then
				-- Neither weapon is compatible
				activeSkill.disableReason = "No usable weapon equipped"
			end
		end
		if skillFlags.attack then
			skillFlags.bothWeaponAttack = skillFlags.weapon1Attack and skillFlags.weapon2Attack
		end
	end

	-- Build skill mod flag set
	local skillModFlags = 0
	if skillFlags.hit then
		skillModFlags = bor(skillModFlags, ModFlag.Hit)
	end
	if skillFlags.attack then
		skillModFlags = bor(skillModFlags, ModFlag.Attack)
	else
		skillModFlags = bor(skillModFlags, ModFlag.Cast)
		if skillFlags.spell then
			skillModFlags = bor(skillModFlags, ModFlag.Spell)
		end
	end
	if skillFlags.melee then
		skillModFlags = bor(skillModFlags, ModFlag.Melee)
	elseif skillFlags.projectile then
		skillModFlags = bor(skillModFlags, ModFlag.Projectile)
		skillFlags.chaining = true
	end
	if skillFlags.area then
		skillModFlags = bor(skillModFlags, ModFlag.Area)
	end

	-- Build skill keyword flag set
	local skillKeywordFlags = 0
	if skillFlags.hit then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Hit)
	end
	if skillTypes[SkillType.Aura] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Aura)
	end
	if skillTypes[SkillType.AppliesCurse] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Curse)
	end
	if skillTypes[SkillType.Warcry] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Warcry)
	end
	if skillTypes[SkillType.Movement] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Movement)
	end
	if skillTypes[SkillType.Vaal] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Vaal)
	end
	if skillTypes[SkillType.Lightning] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Lightning)
	end
	if skillTypes[SkillType.Cold] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Cold)
	end
	if skillTypes[SkillType.Fire] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Fire)
	end
	if skillTypes[SkillType.Chaos] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Chaos)
	end
	if skillTypes[SkillType.Physical] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Physical)
	end
	if skillFlags.weapon1Attack and band(activeSkill.weapon1Flags, ModFlag.Bow) ~= 0 then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Bow)
	end
	if skillFlags.brand then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Brand)
	end
	if skillFlags.totem then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Totem)
	elseif skillFlags.trap then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Trap)
	elseif skillFlags.mine then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Mine)
	elseif not skillTypes[SkillType.Triggered] then
		skillFlags.selfCast = true
	end
	if skillTypes[SkillType.Attack] then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Attack)
	end
	if skillTypes[SkillType.Spell] and not skillFlags.cast then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Spell)
	end

	-- Get skill totem ID for totem skills
	-- This is used to calculate totem life
	if skillFlags.totem then
		activeSkill.skillTotemId = activeGrantedEffect.skillTotemId
		if not activeSkill.skillTotemId then
			if activeGrantedEffect.color == 2 then
				activeSkill.skillTotemId = 2
			elseif activeGrantedEffect.color == 3 then
				activeSkill.skillTotemId = 3
			else
				activeSkill.skillTotemId = 1
			end
		end
	end

	-- Calculate Distance for meleeDistance or projectileDistance (for melee proximity, e.g. Impact)
	if skillFlags.melee then
		effectiveRange = env.configInput.meleeDistance
	else
		effectiveRange = env.configInput.projectileDistance
	end
	
	-- Build config structure for modifier searches
	activeSkill.skillCfg = {
		flags = bor(skillModFlags, activeSkill.weapon1Flags or activeSkill.weapon2Flags or 0),
		keywordFlags = skillKeywordFlags,
		skillName = activeGrantedEffect.name:gsub("^Vaal ",""):gsub("Summon Skeletons","Summon Skeleton"), -- This allows modifiers that target specific skills to also apply to their Vaal counterpart
		summonSkillName = activeSkill.summonSkill and activeSkill.summonSkill.activeEffect.grantedEffect.name,
		skillGem = activeEffect.gemData,
		skillGrantedEffect = activeGrantedEffect,
		skillPart = activeSkill.skillPart,
		skillTypes = activeSkill.skillTypes,
		skillCond = { },
		skillDist = env.mode_effective and effectiveRange,
		slotName = activeSkill.slotName,
	}
	if skillFlags.weapon1Attack then
		activeSkill.weapon1Cfg = copyTable(activeSkill.skillCfg, true)
		activeSkill.weapon1Cfg.skillCond = setmetatable({ ["MainHandAttack"] = true }, { __index = activeSkill.skillCfg.skillCond })
		activeSkill.weapon1Cfg.flags = bor(skillModFlags, activeSkill.weapon1Flags)
	end
	if skillFlags.weapon2Attack then
		activeSkill.weapon2Cfg = copyTable(activeSkill.skillCfg, true)
		activeSkill.weapon2Cfg.skillCond = setmetatable({ ["OffHandAttack"] = true }, { __index = activeSkill.skillCfg.skillCond })
		activeSkill.weapon2Cfg.flags = bor(skillModFlags, activeSkill.weapon2Flags)
	end

	-- Initialise skill modifier list
	local skillModList = new("ModList", activeSkill.actor.modDB)
	activeSkill.skillModList = skillModList
	activeSkill.baseSkillModList = skillModList
	
	-- The damage fixup stat applies x% less base Attack Damage and x% more base Attack Speed as confirmed by Openarl Jan 4th 2024
	-- Implemented in this manner as the stat exists on the minion not the skills 
	if activeSkill.actor and activeSkill.actor.minionData and activeSkill.actor.minionData.damageFixup then
		skillModList:NewMod("Damage", "MORE", -100 * activeSkill.actor.minionData.damageFixup, "Damage Fixup", ModFlag.Attack)
		skillModList:NewMod("Speed", "MORE", 100 * activeSkill.actor.minionData.damageFixup, "Damage Fixup", ModFlag.Attack)
	end

	if skillModList:Flag(activeSkill.skillCfg, "DisableSkill") and not skillModList:Flag(activeSkill.skillCfg, "EnableSkill") then
		skillFlags.disable = true
		activeSkill.disableReason = "Skills of this type are disabled"
	end

	if skillFlags.disable then
		wipeTable(skillFlags)
		skillFlags.disable = true
		calcLib.validateGemLevel(activeEffect)
		activeEffect.grantedEffectLevel = activeGrantedEffect.levels[activeEffect.level]
		return
	end

	-- Add support gem modifiers to skill mod list
	for _, skillEffect in pairs(activeSkill.effectList) do
		if skillEffect.grantedEffect.support then
			calcs.mergeSkillInstanceMods(env, skillModList, skillEffect)
			local level = skillEffect.grantedEffect.levels[skillEffect.level]
			if level.manaMultiplier then
				skillModList:NewMod("SupportManaMultiplier", "MORE", level.manaMultiplier, skillEffect.grantedEffect.modSource)
			end
			if level.manaReservationPercent then
				activeSkill.skillData.manaReservationPercent = level.manaReservationPercent
			end	
			-- Handle multiple triggers situation and if triggered by a trigger skill save a reference to the trigger.
			local match = skillEffect.grantedEffect.addSkillTypes and (not skillFlags.disable)
			if match and skillEffect.grantedEffect.isTrigger then
				if activeSkill.triggeredBy then
					skillFlags.disable = true
					activeSkill.disableReason = "This skill is supported by more than one trigger"
				else
					activeSkill.triggeredBy = skillEffect
				end
			end
			if level.PvPDamageMultiplier then
				skillModList:NewMod("PvpDamageMultiplier", "MORE", level.PvPDamageMultiplier, skillEffect.grantedEffect.modSource)
			end
			if level.storedUses then
				activeSkill.skillData.storedUses = level.storedUses
			end
		end
	end

	-- Apply gem/quality modifiers from support gems
	for _, value in ipairs(skillModList:List(activeSkill.skillCfg, "SupportedGemProperty")) do
		if value.keyword == "grants_active_skill" and activeSkill.activeEffect.gemData and not activeSkill.activeEffect.gemData.tags.support  then
			activeEffect[value.key] = activeEffect[value.key] + value.value
		end
	end

	-- Add active gem modifiers
	activeEffect.actorLevel = activeSkill.actor.minionData and activeSkill.actor.level
	calcs.mergeSkillInstanceMods(env, skillModList, activeEffect, skillModList:List(activeSkill.skillCfg, "ExtraSkillStat"))
	activeEffect.grantedEffectLevel = activeGrantedEffect.levels[activeEffect.level]

	-- Add extra modifiers from granted effect level
	local level = activeEffect.grantedEffectLevel
	activeSkill.skillData.CritChance = level.critChance
	if level.damageMultiplier then
		skillModList:NewMod("Damage", "MORE", level.damageMultiplier, activeEffect.grantedEffect.modSource, ModFlag.Attack)
	end
	if level.attackTime then
		activeSkill.skillData.attackTime = level.attackTime
	end
	if level.attackSpeedMultiplier then
		skillModList:NewMod("Speed", "MORE", level.attackSpeedMultiplier, activeEffect.grantedEffect.modSource, ModFlag.Attack)
	end
	if level.cooldown then
		activeSkill.skillData.cooldown = level.cooldown
	end
	if level.storedUses then
		activeSkill.skillData.storedUses = level.storedUses
	end
	if level.soulPreventionDuration then
		activeSkill.skillData.soulPreventionDuration = level.soulPreventionDuration
	end
	if level.PvPDamageMultiplier then
		skillModList:NewMod("PvpDamageMultiplier", "MORE", level.PvPDamageMultiplier, activeEffect.grantedEffect.modSource)
	end
	
	-- Add extra modifiers from other sources
	activeSkill.extraSkillModList = { }
	for _, value in ipairs(skillModList:List(activeSkill.skillCfg, "ExtraSkillMod")) do
		skillModList:AddMod(value.mod)
		t_insert(activeSkill.extraSkillModList, value.mod)
	end

	-- Find totem level
	if skillFlags.totem then
		activeSkill.skillData.totemLevel = activeEffect.grantedEffectLevel.levelRequirement
	end

	-- Add active mine multiplier
	if skillFlags.mine then
		activeSkill.activeMineCount = (env.mode == "CALCS" and activeEffect.srcInstance.skillMineCountCalcs) or (env.mode ~= "CALCS" and activeEffect.srcInstance.skillMineCount)
		if activeSkill.activeMineCount and activeSkill.activeMineCount > 0 then
			skillModList:NewMod("Multiplier:ActiveMineCount", "BASE", activeSkill.activeMineCount, "Base")
			env.enemy.modDB.multipliers["ActiveMineCount"] = m_max(activeSkill.activeMineCount or 0, env.enemy.modDB.multipliers["ActiveMineCount"] or 0)
		end
	elseif activeEffect.srcInstance and not (activeEffect.gemData and activeEffect.gemData.secondaryGrantedEffect) then
		activeEffect.srcInstance.skillMineCountCalcs = nil
		activeEffect.srcInstance.skillMineCount = nil
	end
	

	-- Determine if it possible to have a stage on this skill based upon skill parts.
	local noPotentialStage = true
	if activeEffect.grantedEffect.parts then
		for _, part in ipairs(activeEffect.grantedEffect.parts) do
			if part.stages then 
				noPotentialStage = false
				break
			end
		end
	end

	if skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:"..activeGrantedEffect.name:gsub("%s+", "").."MaxStages") > 0 then
		skillFlags.multiStage = true
		activeSkill.activeStageCount = m_max((env.mode == "CALCS" and activeEffect.srcInstance.skillStageCountCalcs) or (env.mode ~= "CALCS" and activeEffect.srcInstance.skillStageCount) or 1, 1 + skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:"..activeGrantedEffect.name:gsub("%s+", "").."MinimumStage"))
		local limit = skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:"..activeGrantedEffect.name:gsub("%s+", "").."MaxStages")
		if limit > 0 then
			if activeSkill.activeStageCount and activeSkill.activeStageCount > 0 then
				skillModList:NewMod("Multiplier:"..activeGrantedEffect.name:gsub("%s+", "").."Stage", "BASE", m_min(limit, activeSkill.activeStageCount), "Base")
				activeSkill.activeStageCount = (activeSkill.activeStageCount or 0) - 1
				skillModList:NewMod("Multiplier:"..activeGrantedEffect.name:gsub("%s+", "").."StageAfterFirst", "BASE", m_min(limit - 1, activeSkill.activeStageCount), "Base")
			end
		end
	elseif noPotentialStage and activeEffect.srcInstance and not (activeEffect.gemData and activeEffect.gemData.secondaryGrantedEffect) then
		activeEffect.srcInstance.skillStageCountCalcs = nil
		activeEffect.srcInstance.skillStageCount = nil
	end

	-- Extract skill data
	for _, value in ipairs(env.modDB:List(activeSkill.skillCfg, "SkillData")) do
		activeSkill.skillData[value.key] = value.value
	end
	for _, value in ipairs(skillModList:List(activeSkill.skillCfg, "SkillData")) do
		activeSkill.skillData[value.key] = value.value
	end

	-- Create minion
	local minionList, isSpectre
	if activeGrantedEffect.minionList then
		if activeGrantedEffect.minionList[1] then
			minionList = copyTable(activeGrantedEffect.minionList)
		else
			minionList = copyTable(env.build.spectreList)
			isSpectre = true
		end
	else
		minionList = { }
	end
	for _, skillEffect in ipairs(activeSkill.effectList) do
		if skillEffect.grantedEffect.support and skillEffect.grantedEffect.addMinionList then
			for _, minionType in ipairs(skillEffect.grantedEffect.addMinionList) do
				t_insert(minionList, minionType)
			end
		end
	end
	activeSkill.minionList = minionList
	if minionList[1] and not activeSkill.actor.minionData then
		local minionType
		if env.mode == "CALCS" and activeSkill == env.player.mainSkill then
			local index = isValueInArray(minionList, activeEffect.srcInstance.skillMinionCalcs) or 1
			minionType = minionList[index]
			activeEffect.srcInstance.skillMinionCalcs = minionType
		else
			local index = isValueInArray(minionList, activeEffect.srcInstance.skillMinion) or 1
			minionType = minionList[index]
			activeEffect.srcInstance.skillMinion = minionType
		end
		if minionType then
			local minion = { }
			activeSkill.minion = minion
			skillFlags.haveMinion = true
			minion.parent = env.player
			minion.enemy = env.enemy
			minion.type = minionType
			minion.minionData = env.data.minions[minionType]
			minion.level = activeSkill.skillData.minionLevelIsEnemyLevel and env.enemyLevel or 
								activeSkill.skillData.minionLevelIsPlayerLevel and (m_min(env.build and env.build.characterLevel or activeSkill.skillData.minionLevel or activeEffect.grantedEffectLevel.levelRequirement, activeSkill.skillData.minionLevelIsPlayerLevel)) or 
								activeSkill.skillData.minionLevel or activeEffect.grantedEffectLevel.levelRequirement
			-- fix minion level between 1 and 100
			minion.level = m_min(m_max(minion.level,1),100) 
			minion.itemList = { }
			minion.uses = activeGrantedEffect.minionUses
			minion.lifeTable = (minion.minionData.lifeScaling == "AltLife1" and env.data.monsterLifeTable2) or (minion.minionData.lifeScaling == "AltLife2" and env.data.monsterLifeTable3) or (isSpectre and env.data.monsterLifeTable) or env.data.monsterAllyLifeTable
			local attackTime = minion.minionData.attackTime
			local damage = (isSpectre and env.data.monsterDamageTable[minion.level] or env.data.monsterAllyDamageTable[minion.level]) * minion.minionData.damage
			if not minion.minionData.baseDamageIgnoresAttackSpeed then -- minions with this flag do not factor attack time into their base damage
				 damage = damage * attackTime
			end
			if activeGrantedEffect.minionHasItemSet then
				if env.mode == "CALCS" and activeSkill == env.player.mainSkill then
					if not env.build.itemsTab.itemSets[activeEffect.srcInstance.skillMinionItemSetCalcs] then
						activeEffect.srcInstance.skillMinionItemSetCalcs = env.build.itemsTab.itemSetOrderList[1]
					end
					minion.itemSet = env.build.itemsTab.itemSets[activeEffect.srcInstance.skillMinionItemSetCalcs]
				else
					if not env.build.itemsTab.itemSets[activeEffect.srcInstance.skillMinionItemSet] then
						activeEffect.srcInstance.skillMinionItemSet = env.build.itemsTab.itemSetOrderList[1]
					end
					minion.itemSet = env.build.itemsTab.itemSets[activeEffect.srcInstance.skillMinionItemSet]
				end
			elseif activeEffect.srcInstance and not (activeEffect.gemData and activeEffect.gemData.secondaryGrantedEffect) then
				activeEffect.srcInstance.skillMinionItemSetCalcs = nil
				activeEffect.srcInstance.skillMinionItemSet = nil
			end
			if activeSkill.skillData.minionUseBowAndQuiver and env.player.weaponData1.type == "Bow" then
				minion.weaponData1 = env.player.weaponData1
			elseif env.theIronMass and minionType == "RaisedSkeleton" then
				minion.weaponData1 = env.player.weaponData1
			else
				minion.weaponData1 = {
					type = minion.minionData.weaponType1 or "None",
					AttackRate = 1 / attackTime,
					CritChance = 5,
					PhysicalMin = round(damage * (1 - minion.minionData.damageSpread)),
					PhysicalMax = round(damage * (1 + minion.minionData.damageSpread)),
					range = minion.minionData.attackRange,
				}
			end
			minion.weaponData2 = { }
			if minion.uses then
				if minion.uses["Weapon 1"] then
					if minion.itemSet then
						local item = env.build.itemsTab.items[minion.itemSet[minion.itemSet.useSecondWeaponSet and "Weapon 1 Swap" or "Weapon 1"].selItemId]
						if item and item.weaponData then
							minion.weaponData1 = item.weaponData[1]
						end
					else
						minion.weaponData1 = env.player.weaponData1
					end
				end
				if minion.uses["Weapon 2"] then	
					if minion.itemSet then
						local item = env.build.itemsTab.items[minion.itemSet[minion.itemSet.useSecondWeaponSet and "Weapon 2 Swap" or "Weapon 2"].selItemId]
						if item and item.weaponData then
							minion.weaponData2 = item.weaponData[2]
						end
					else
						minion.weaponData2 = env.player.weaponData2
					end
				end
			end
		end
	elseif activeEffect.srcInstance and not (activeEffect.gemData and activeEffect.gemData.secondaryGrantedEffect) then
		activeEffect.srcInstance.skillMinionCalcs = nil
		activeEffect.srcInstance.skillMinion = nil
		activeEffect.srcInstance.skillMinionItemSetCalcs = nil
		activeEffect.srcInstance.skillMinionItemSet = nil
		activeEffect.srcInstance.skillMinionSkill = nil
		activeEffect.srcInstance.skillMinionSkillCalcs = nil
	end

	-- Separate global effect modifiers (mods that can affect defensive stats or other skills)
	local i = 1
	while skillModList[i] do
		local effectType, effectName, effectTag
		for _, tag in ipairs(skillModList[i]) do
			if tag.type == "GlobalEffect" then
				effectType = tag.effectType
				effectName = tag.effectName or activeGrantedEffect.name
				effectTag = tag
				break
			end
		end
		if effectTag and effectTag.modCond and not skillModList:GetCondition(effectTag.modCond, activeSkill.skillCfg) then
			t_remove(skillModList, i)
		elseif effectType then
			local buff
			for _, skillBuff in ipairs(activeSkill.buffList) do
				if skillBuff.type == effectType and skillBuff.name == effectName then
					buff = skillBuff
					break
				end
			end
			if not buff then
				buff = {
					type = effectType,
					name = effectName,
					allowTotemBuff = effectTag.allowTotemBuff,
					cond = effectTag.effectCond,
					enemyCond = effectTag.effectEnemyCond,
					stackVar = effectTag.effectStackVar,
					stackLimit = effectTag.effectStackLimit,
					stackLimitVar = effectTag.effectStackLimitVar,
					applyNotPlayer = effectTag.applyNotPlayer,
					applyMinions = effectTag.applyMinions,
					modList = { },
				}
				if skillModList[i].source == activeGrantedEffect.modSource then
					-- Inherit buff configuration from the active skill
					buff.activeSkillBuff = true
					buff.applyNotPlayer = buff.applyNotPlayer or activeSkill.skillData.buffNotPlayer
					buff.applyMinions = buff.applyMinions or activeSkill.skillData.buffMinions
					buff.applyAllies = activeSkill.skillData.buffAllies
					buff.allowTotemBuff = activeSkill.skillData.allowTotemBuff
				end
				t_insert(activeSkill.buffList, buff)
			end
			local match = false
			local modList = buff.modList
			for d = 1, #modList do
				local destMod = modList[d]
				if modLib.compareModParams(skillModList[i], destMod) and (destMod.type == "BASE" or destMod.type == "INC") then
					destMod = copyTable(destMod)
					destMod.value = destMod.value + skillModList[i].value
					modList[d] = destMod
					match = true
					break
				end
			end
			if not match then
				t_insert(modList, skillModList[i])
			end
			t_remove(skillModList, i)
		else
			i = i + 1
		end
	end

	if activeSkill.buffList[1] then
		-- Add to auxiliary skill list
		t_insert(env.auxSkillList, activeSkill)
	end
end

-- Initialise the active skill's minion skills
function calcs.createMinionSkills(env, activeSkill)
	local activeEffect = activeSkill.activeEffect
	local minion = activeSkill.minion
	local minionData = minion.minionData

	minion.activeSkillList = { }
	local skillIdList = { }
	for _, skillId in ipairs(minionData.skillList) do
		if env.data.skills[skillId] then
			t_insert(skillIdList, skillId)
		end
	end
	for _, skill in ipairs(activeSkill.skillModList:List(activeSkill.skillCfg, "ExtraMinionSkill")) do
		if not skill.minionList or isValueInArray(skill.minionList, minion.type) then
			t_insert(skillIdList, skill.skillId)
		end
	end
	if #skillIdList == 0 then
		-- Not ideal, but let's avoid horrible crashes if a spectre has no skills for some reason
		t_insert(skillIdList, "Melee")
	end
	for _, skillId in ipairs(skillIdList) do
		local activeEffect = {
			grantedEffect = env.data.skills[skillId],
			level = 1,
			quality = 0,
		}
		if #activeEffect.grantedEffect.levels > 1 then
			for level, levelData in ipairs(activeEffect.grantedEffect.levels) do
				if levelData.levelRequirement > minion.level then
					break
				else
					activeEffect.level = level
				end
			end
		end
		local minionSkill = calcs.createActiveSkill(activeEffect, activeSkill.supportList, minion, nil, activeSkill)
		calcs.buildActiveSkillModList(env, minionSkill)
		minionSkill.skillFlags.minion = true
		minionSkill.skillFlags.minionSkill = true
		minionSkill.skillFlags.haveMinion = true
		minionSkill.skillFlags.spectre = activeSkill.skillFlags.spectre
		minionSkill.skillData.damageEffectiveness = 1 + (activeSkill.skillData.minionDamageEffectiveness or 0) / 100
		t_insert(minion.activeSkillList, minionSkill)
	end
	local skillIndex 
	if env.mode == "CALCS" then
		skillIndex = m_max(m_min(activeEffect.srcInstance.skillMinionSkillCalcs or 1, #minion.activeSkillList), 1)
		activeEffect.srcInstance.skillMinionSkillCalcs = skillIndex
	else
		skillIndex = m_max(m_min(activeEffect.srcInstance.skillMinionSkill or 1, #minion.activeSkillList), 1)
		if env.mode == "MAIN" then
			activeEffect.srcInstance.skillMinionSkill = skillIndex
		end
	end
	minion.mainSkill = minion.activeSkillList[skillIndex]
end
