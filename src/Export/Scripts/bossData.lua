local m_ceil = math.ceil
local m_min = math.min
local m_max = math.max

local rarityDamageMult = {
	Unique = (1 + dat("Mods"):GetRow("Id", "MonsterUnique5").Stat1Value[1] / 100),
	UniqueAttack = (1 + dat("Mods"):GetRow("Id", "MonsterUnique5").Stat1Value[1] / 100) * (1 - dat("Mods"):GetRow("Id", "MonsterUnique8").Stat1Value[1] / 100)
}
local monsterBaseDamage = { 4.9899997711182, 5.5599999427795, 6.1599998474121, 6.8099999427795, 7.5, 8.2299995422363, 9, 9.8199996948242, 10.699999809265, 11.619999885559, 12.60000038147, 13.640000343323, 14.739999771118, 15.909999847412, 17.139999389648, 18.450000762939, 19.829999923706, 21.290000915527, 22.840000152588, 24.469999313354, 26.190000534058, 28.010000228882, 29.940000534058, 31.959999084473, 34.110000610352, 36.360000610352, 38.75, 41.259998321533, 43.909999847412, 46.700000762939, 49.650001525879, 52.75, 56.009998321533, 59.450000762939, 63.080001831055, 66.889999389648, 70.910003662109, 75.129997253418, 79.580001831055, 84.26000213623, 89.180000305176, 94.349998474121, 99.800003051758, 105.51999664307, 111.5299987793, 117.86000061035, 124.5, 131.49000549316, 138.83000183105, 146.5299987793, 154.63000488281, 163.13999938965, 172.07000732422, 181.44999694824, 191.30000305176, 201.63000488281, 212.47999572754, 223.86999511719, 235.83000183105, 248.36999511719, 261.5299987793, 275.32998657227, 289.82000732422, 305.01000976562, 320.94000244141, 337.64999389648, 355.17999267578, 373.54998779297, 392.80999755859, 413.01000976562, 434.17999267578, 456.36999511719, 479.61999511719, 504, 529.53997802734, 556.29998779297, 584.34997558594, 613.72998046875, 644.5, 676.75, 710.52001953125, 745.89001464844, 782.94000244141, 821.72998046875, 862.35998535156, 904.90002441406, 949.44000244141, 996.07000732422, 1044.8900146484, 1096, 1149.5, 1205.5, 1264.1099853516, 1325.4499511719, 1389.6400146484, 1456.8199462891, 1527.1199951172, 1600.6800537109, 1677.6400146484, 1758.1700439453, }
local monsterMapDifficultyMult = {}
for row in dat("MonsterMapDifficulty"):Rows() do
	monsterMapDifficultyMult[row.AreaLevel] = 1 + row.DamagePercentIncrease / 100
end
local baseDamage = {
	AtziriFlameblastEmpowered = { index = 1, uberIndex = 2, mapBoss = true },
	AtlasBossAcceleratingProjectiles = { index = 1, uberIndex = 2 },
	AtlasBossFlickerSlam = { index = 1, uberIndex = 2, oldMethod = true, attack = true },
	AtlasExileOrionCircleMazeBlast3 = { index = 4, uberIndex = 5 },
	CleansingFireWall = { index = 1, oldMethod = true },
	GSConsumeBossDisintegrateBeam = { index = 1, oldMethod = true },
	MavenSuperFireProjectileImpact = { index = 1, uberIndex = 2, oldMethod = true, mapBoss = true },
	MavenMemoryGame = { index = 1, oldMethod = true, mapBoss = true },
}
local oldMethod = {
	AtziriFlameblastEmpowered = { Fire = { 1210.408, 0 } },
	AtlasBossAcceleratingProjectiles = { Cold = { 3358.0288, 0 } },
	AtlasBossFlickerSlam = { Physical = { 1769.847, 0 } },
	AtlasExileOrionCircleMazeBlast3 = { Physical = { 18154.481, 0 }, SkillUberDamageMult = 152 },
	CleansingFireWall = { Fire = { 3304.677, 20 } },
	GSConsumeBossDisintegrateBeam = { Lightning = { 3735.061, 50 } },
	MavenSuperFireProjectileImpact = { Fire = { 4955.383, 0 }, SkillUberDamageMult = 201 },
	MavenMemoryGame = { Physical = { 34505.376, 0 } },
}

-- exports and calculates the damage multipliers of the skill
-- min and max damage equal to damage dealt divided by base monster damage at that level
-- also provides the UberDamageMultiplier if the skill does more in uber form
local function calcSkillDamage(state)
	local monsterLevel = 84
	local skill = state.skill
	local boss = state.boss
	local physConversions = { 1, 0, 0, 0, 0 }
	for i, constStat in ipairs(skill.GrantedEffectStatSets.ConstantStats) do
		if constStat.Id == "skill_physical_damage_%_to_convert_to_lightning" then
			physConversions[2] = skill.GrantedEffectStatSets.ConstantStatsValues[i]
		elseif constStat.Id == "skill_physical_damage_%_to_convert_to_cold" then
			physConversions[3] = skill.GrantedEffectStatSets.ConstantStatsValues[i]
		elseif constStat.Id == "skill_physical_damage_%_to_convert_to_fire" then
			physConversions[4] = skill.GrantedEffectStatSets.ConstantStatsValues[i]
		elseif constStat.Id == "skill_physical_damage_%_to_convert_to_chaos" then
			physConversions[5] = skill.GrantedEffectStatSets.ConstantStatsValues[i]
		end
	end
	local grantedId = skill.grantedId
	if not baseDamage[grantedId] and baseDamage[skill.grantedId2] then
		grantedId = skill.grantedId2
	end
	local rarityType = baseDamage[grantedId].attack and (boss.rarity.."Attack") or boss.rarity
	local ExtraDamageMult = { 1, 1 }
	for i, levelIndex  in ipairs({baseDamage[grantedId].index, baseDamage[grantedId].uberIndex}) do
		local statsPerLevel = skill.statsPerLevel[levelIndex]
		for j, additionalStat in ipairs(statsPerLevel.AdditionalStats) do
			if additionalStat.Id == "active_skill_damage_+%_final" then
				ExtraDamageMult[i] = 1 + statsPerLevel.AdditionalStatsValues[j] / 100
				break
			end
		end
	end
	if skill.stages then
		local stageMulti = 1
		for i, constStat in ipairs(skill.GrantedEffectStatSets.ConstantStats) do
		if constStat.Id == "charged_blast_spell_damage_+%_final_per_stack" then
			stageMulti = skill.GrantedEffectStatSets.ConstantStatsValues[i] / 100
			break
		end
	end
		ExtraDamageMult = { ExtraDamageMult[1] * (1 + stageMulti * skill.stages), ExtraDamageMult[2] * (1 + stageMulti * skill.stages) }
	end
	-- old method with hardcoded values (Still used for Shaper Slam)
	if baseDamage[grantedId].oldMethod then
		if oldMethod[grantedId].Physical then
			local totalConversions = physConversions[2] + physConversions[3] + physConversions[4] + physConversions[5]
			local conversionDivisor = m_max(totalConversions, 100)
			physConversions = { m_max(1 - totalConversions / 100, 0), physConversions[2] / conversionDivisor, physConversions[3] / conversionDivisor, physConversions[4] / conversionDivisor, physConversions[5] / conversionDivisor }
		end
		local baseDamageMult = state.SkillExtraDamageMult * ExtraDamageMult[1] * boss.damageMult / 100 * (rarityDamageMult[rarityType] or 1) * (baseDamage[grantedId].mapBoss and monsterMapDifficultyMult[monsterLevel] or 1) / (monsterBaseDamage[monsterLevel - 1] or 1)
		if oldMethod[grantedId].Physical and physConversions[1] ~= 0 then
			local damageRange = (oldMethod[grantedId].Physical[2] == 0) and (boss.damageRange / 100) or oldMethod[grantedId].Physical[2] / 100
			local damageMult = oldMethod[grantedId].Physical[1] * physConversions[1] * baseDamageMult
			state.DamageData["PhysicalDamageMultMin"], state.DamageData["PhysicalDamageMultMax"] = damageMult * ( 1 - damageRange ), damageMult * ( 1 + damageRange )
		end
		for i, damageType in ipairs({"Lightning", "Cold", "Fire", "Chaos"}) do
			if oldMethod[grantedId][damageType] or (oldMethod[grantedId].Physical and physConversions[i + 1] ~= 0) then
				state.DamageData[damageType.."DamageMultMin"], state.DamageData[damageType.."DamageMultMax"] = 0, 0
				if oldMethod[grantedId][damageType] then
					local damageRange = (oldMethod[grantedId][damageType][2] == 0) and (boss.damageRange / 100) or oldMethod[grantedId][damageType][2] / 100
					local damageMult = oldMethod[grantedId][damageType][1] * baseDamageMult
					state.DamageData[damageType.."DamageMultMin"], state.DamageData[damageType.."DamageMultMax"] = damageMult * ( 1 - damageRange ), damageMult * ( 1 + damageRange )
				end
				if oldMethod[grantedId].Physical and physConversions[i + 1] ~= 0 then
					local damageRange = (oldMethod[grantedId].Physical[2] == 0) and (boss.damageRange / 100) or oldMethod[grantedId].Physical[2] / 100
					local damageMult = (oldMethod[grantedId].Physical[1] * physConversions[i + 1]) * baseDamageMult
					state.DamageData[damageType.."DamageMultMin"] = state.DamageData[damageType.."DamageMultMin"] + damageMult * ( 1 - damageRange )
					state.DamageData[damageType.."DamageMultMax"] = state.DamageData[damageType.."DamageMultMax"] + damageMult * ( 1 + damageRange )
				end
			end
		end
		if ExtraDamageMult[1] ~= ExtraDamageMult[2] then
			state.DamageData.SkillUberDamageMult = 100 * ExtraDamageMult[2] / ExtraDamageMult[1] * (baseDamage[grantedId].mapBoss and (monsterMapDifficultyMult[monsterLevel + 1] / monsterMapDifficultyMult[monsterLevel]) or 1)
		elseif oldMethod[grantedId].SkillUberDamageMult then
			state.DamageData.SkillUberDamageMult = oldMethod[grantedId].SkillUberDamageMult * (baseDamage[grantedId].mapBoss and (monsterMapDifficultyMult[monsterLevel + 1] / monsterMapDifficultyMult[monsterLevel]) or 1)
		elseif baseDamage[grantedId].mapBoss then
			state.DamageData.SkillUberDamageMult = 100 * (monsterMapDifficultyMult[baseDamage[grantedId].uberMapBoss or (monsterLevel + 1)] / monsterMapDifficultyMult[monsterLevel])
		end
		
	else
		-- new method
		local baseDamages = {}
		for i, levelIndex  in ipairs({baseDamage[grantedId].index, baseDamage[grantedId].uberIndex}) do
			local statsPerLevel = (grantedId == skill.grantedId2) and skill.statsPerLevel2[levelIndex] or skill.statsPerLevel[levelIndex]
			for j, floatStat in ipairs(statsPerLevel.FloatStats) do
				if floatStat.Id == "spell_minimum_base_physical_damage" then
					baseDamages["minPhysical"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_maximum_base_physical_damage" then
					baseDamages["maxPhysical"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_minimum_base_lightning_damage" then
					baseDamages["minLightning"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_maximum_base_lightning_damage" then
					baseDamages["maxLightning"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_minimum_base_cold_damage" then
					baseDamages["minCold"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_maximum_base_cold_damage" then
					baseDamages["maxCold"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_minimum_base_fire_damage" then
					baseDamages["minFire"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_maximum_base_fire_damage" then
					baseDamages["maxFire"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_minimum_base_chaos_damage" then
					baseDamages["minChaos"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				elseif floatStat.Id == "spell_maximum_base_chaos_damage" then
					baseDamages["maxChaos"..i] = 1 + statsPerLevel.BaseResolvedValues[j]
				end
			end
		end
		monsterLevel = skill.statsPerLevel[baseDamage[grantedId].index].PlayerLevelReq
		if baseDamages["minPhysical1"] or baseDamages["maxPhysical1"] then
			local totalConversions = physConversions[2] + physConversions[3] + physConversions[4] + physConversions[5]
			local conversionDivisor = m_max(totalConversions, 100)
			physConversions = { m_max(1 - totalConversions / 100, 0), physConversions[2] / conversionDivisor, physConversions[3] / conversionDivisor, physConversions[4] / conversionDivisor, physConversions[5] / conversionDivisor }
		end
		local baseDamageMult = state.SkillExtraDamageMult * ExtraDamageMult[1] * (rarityDamageMult[rarityType] or 1) * (baseDamage[grantedId].mapBoss and monsterMapDifficultyMult[monsterLevel] or 1) / (monsterBaseDamage[monsterLevel] or 1) --  * boss.damageMult / 100
		if (baseDamages["minPhysical1"] or baseDamages["maxPhysical1"]) and physConversions[1] ~= 0 then
			local damageMult = physConversions[1] * baseDamageMult
			state.DamageData["PhysicalDamageMultMin"], state.DamageData["PhysicalDamageMultMax"] = damageMult * (baseDamages["minPhysical1"] or 0), damageMult * (baseDamages["maxPhysical1"] or 0)
		end
		for i, damageType in ipairs({"Lightning", "Cold", "Fire", "Chaos"}) do
			if (baseDamages["min"..damageType.."1"] or baseDamages["max"..damageType.."1"]) or ((baseDamages["minPhysical1"] or baseDamages["maxPhysical1"]) and physConversions[i + 1] ~= 0) then
				local damageMult = baseDamageMult
				state.DamageData[damageType.."DamageMultMin"], state.DamageData[damageType.."DamageMultMax"] = 0, 0
				if (baseDamages["min"..damageType.."1"] or baseDamages["max"..damageType.."1"]) then
					state.DamageData[damageType.."DamageMultMin"], state.DamageData[damageType.."DamageMultMax"] = damageMult * (baseDamages["min"..damageType.."1"] or 0), damageMult * (baseDamages["max"..damageType.."1"] or 0)
				end
				if (baseDamages["minPhysical1"] or baseDamages["maxPhysical1"]) and physConversions[i + 1] ~= 0 then
					damageMult = damageMult * physConversions[i + 1]
					state.DamageData[damageType.."DamageMultMin"] = state.DamageData[damageType.."DamageMultMin"] + damageMult * (baseDamages["minPhysical1"] or 0)
					state.DamageData[damageType.."DamageMultMax"] = state.DamageData[damageType.."DamageMultMax"] + damageMult * (baseDamages["maxPhysical1"] or 0)
				end
			end
		end
		if baseDamage[grantedId].uberIndex then
			local SkillUberDamageMult = 0
			local SkillDamageMult = 0
			local uberMonsterLevel = skill.statsPerLevel[baseDamage[grantedId].uberIndex].PlayerLevelReq
			for _, damageType in ipairs({"Physical", "Lightning", "Cold", "Fire", "Chaos"}) do
				if (baseDamages["min"..damageType.."1"] or baseDamages["max"..damageType.."1"]) then
					SkillDamageMult = SkillDamageMult + baseDamages["min"..damageType.."1"] or baseDamages["max"..damageType.."1"]
					SkillUberDamageMult = SkillUberDamageMult + baseDamages["min"..damageType.."2"] or baseDamages["max"..damageType.."2"]
				end
			end
			SkillUberDamageMult = (SkillUberDamageMult / (monsterBaseDamage[uberMonsterLevel] or 1)) / (SkillDamageMult / (monsterBaseDamage[monsterLevel] or 1)) * (baseDamage[grantedId].mapBoss and (monsterMapDifficultyMult[uberMonsterLevel] / monsterMapDifficultyMult[monsterLevel]) or 1)
			if SkillUberDamageMult > 1.15 or SkillUberDamageMult < 0.85 then
				state.DamageData.SkillUberDamageMult = m_ceil(SkillUberDamageMult * 100)
			end
		end
	end
end

-- exports non-damage stats
-- possible stats: DamageType, Penetration, Speed
local function getStat(state, stat)
	local DamageData = state.DamageData
	local skill = state.skill
	local boss = state.boss
	if stat == "DamageType" then
		local DamageType = "Melee"
		for _, skillType in ipairs(skill.skillData.ActiveSkill.SkillTypes) do
			if skillType.Id == "Spell" then
				if DamageType == "Projectile" then
					DamageType = "SpellProjectile"
				else
					DamageType = "Spell"
				end
			elseif skillType.Id  == "Projectile" then
				if DamageType == "Spell" then
					DamageType = "SpellProjectile"
				else
					DamageType = "Projectile"
				end
			end
		end
		if DamageType == "Melee" then
			for _, implicitStat in ipairs(skill.GrantedEffectStatSets.ImplicitStats) do
				if implicitStat.Id  == "base_is_projectile" then
					DamageType = "Projectile"
					break
				end
			end
		end
		return DamageType
	elseif stat == "Penetration" then
		DamageData["PhysOverwhelm"], DamageData["PhysUberOverwhelm"], DamageData["LightningPen"], DamageData["LightningUberPen"], DamageData["ColdPen"], DamageData["ColdUberPen"], DamageData["FirePen"], DamageData["FireUberPen"], DamageData["ChaosPen"], DamageData["ChaosUberPen"] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		for level, statsPerLevel in ipairs(skill.statsPerLevel) do
			for i, additionalStat in ipairs(statsPerLevel.AdditionalStats) do
				if additionalStat.Id == "base_reduce_enemy_lightning_resistance_%" then
					DamageData["Lightning"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
				elseif additionalStat.Id == "base_reduce_enemy_cold_resistance_%" then
					DamageData["Cold"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
				elseif additionalStat.Id == "base_reduce_enemy_fire_resistance_%" then
					DamageData["Fire"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
				elseif additionalStat.Id == "base_reduce_enemy_chaos_resistance_%" then
					DamageData["Chaos"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
				end
			end
		end
		if skill.statsPerLevel2 then 
			for level, statsPerLevel in ipairs(skill.statsPerLevel2) do
				for i, additionalStat in ipairs(statsPerLevel.AdditionalStats) do
					if additionalStat.Id == "base_reduce_enemy_lightning_resistance_%" then
						DamageData["Lightning"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
					elseif additionalStat.Id == "base_reduce_enemy_cold_resistance_%" then
						DamageData["Cold"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
					elseif additionalStat.Id == "base_reduce_enemy_fire_resistance_%" then
						DamageData["Fire"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
					elseif additionalStat.Id == "base_reduce_enemy_chaos_resistance_%" then
						DamageData["Chaos"..(level > 1 and "Uber" or "").."Pen"] = statsPerLevel.AdditionalStatsValues[i]
					end
				end
			end
		end
		DamageData["PhysOverwhelm"] = (DamageData["PhysOverwhelm"] == 0) and (DamageData["PhysUberOverwhelm"] ~= 0 and "" or DamageData["PhysOverwhelm"]) or DamageData["PhysOverwhelm"]
		for _, damageType in ipairs({"Lightning", "Cold", "Fire"}) do
			DamageData[damageType.."Pen"] = (DamageData[damageType.."Pen"] == 0) and (DamageData[damageType.."UberPen"] ~= 0 and "" or DamageData[damageType.."Pen"]) or DamageData[damageType.."Pen"]
		end
		return (DamageData["PhysOverwhelm"] ~= 0 or DamageData["LightningPen"] ~= 0 or DamageData["ColdPen"] ~= 0 or DamageData["FirePen"] ~= 0)
	elseif stat == "Speed" then
		local speed = skill.skillData.CastTime
		local uberSpeed
		if skill.skillDataUber then
			uberSpeed = skill.skillDataUber.CastTime
		end
		local speedMult = { 0, 0 }
		for level, statsPerLevel in ipairs(skill.statsPerLevel) do
			if level > 2 then
				break
			end
			for i, additionalStat in ipairs(statsPerLevel.AdditionalStats) do
				if additionalStat.Id == "active_skill_attack_speed_+%_final" then
					speedMult[level] = 100 + statsPerLevel.AdditionalStatsValues[i]
					break
				elseif additionalStat.Id == "active_skill_cast_speed_+%_final" then
					speedMult[level] = 100 + statsPerLevel.AdditionalStatsValues[i]
					break
				end
			end
		end
		if skill.speedMult then
			speed = speed * skill.speedMult / 10000
			if uberSpeed then
				uberSpeed = uberSpeed * skill.speedMult / 10000
			end
		end
		if skill.stages then
			speed = speed * skill.stages
			if uberSpeed then
				uberSpeed = uberSpeed * skill.stages
			end
		end
		if speedMult[1] ~= 0 then
			if speedMult[1] ~= speedMult[2] then
				return tonumber(m_ceil(speed / speedMult[1] * 100)), tonumber(m_ceil(speed / speedMult[2] * 100))
			end
			speed = speed / speedMult[1] * 100
			uberSpeed = uberSpeed / speedMult[1] * 100
		end
		if uberSpeed then
			return tonumber(m_ceil(speed)), tonumber(m_ceil(uberSpeed))
		end
		return tonumber(m_ceil(speed))
	end
end

local directiveTable = { monsters = {}, skills = {} }

-- #boss [<Display name>] [<MonsterId>] <isUber>
directiveTable.monsters.boss = function(state, args, out)
	local displayName, monsterId, isUber = args:match("(%w+) (.+) {(%w+)}")
	if not displayName then
		displayName, monsterId = args:match("(%w+) (.+)")
	end

    local monsterType = dat("MonsterTypes"):GetRow("Id", monsterId)
    if not monsterType then
		print("Invalid Type: "..monsterId)
		return
	end

    out:write('bosses["', displayName, '"] = {\n')
    out:write('\tarmourMult = ', monsterType.Armour, ',\n')
    out:write('\tevasionMult = ', monsterType.Evasion, ',\n')
    out:write('\tisUber = ', isUber and "true" or "false", ',\n')
	out:write('}\n')
end

-- #boss [<Display name>] [<MonsterId>] <earlierUber>
-- Initialises the boss
directiveTable.skills.boss = function(state, args, out)
	local displayName, monsterId, earlierUber = args:match("(%w+) (.+) (%w+)")
	local bossData = dat("MonsterVarieties"):GetRow("Id", monsterId)
	state.boss = { displayName = displayName, damageRange = bossData.Type.DamageSpread, damageMult = bossData.DamageMultiplier, critChance = m_ceil(bossData.CriticalStrikeChance / 100) }
	if earlierUber == "true" then
		state.boss.earlierUber = true
	end
	for _, mod in ipairs(bossData.Mods) do
		if mod.Id == "MonsterMapBoss" then
			state.boss.rarity = "Unique"
			break
		end
	end
end

-- #skill [<Display name>] [<GrantedEffectId>]
-- optional#  <GrantedEffectId2> <GrantedEffectIdUber> <SkillExtraDamageMult> <speedMult>
-- Initialises and emits the skill data
directiveTable.skills.skill = function(state, args, out)
	local displayName, grantedId = args:match("(%w+) (%w+)")
	if not grantedId then
		displayName, grantedId = args
	end
	if displayName == "MemoryGame" then
		displayName = "Memory Game"
	end
	local boss = state.boss
	state.skillList = state.skillList or {}
	table.insert(state.skillList, boss.displayName.." "..displayName)
	local skill = {}
	local skillData = dat("GrantedEffects"):GetRow("Id", grantedId)
	local GrantedEffectStatSets = dat("GrantedEffectStatSets"):GetRow("Id", grantedId)
	local statsPerLevel = dat("GrantedEffectStatSetsPerLevel"):GetRowList("GrantedEffect", skillData)
	skill = { skillData = skillData, displayName = displayName, GrantedEffectStatSets = GrantedEffectStatSets, statsPerLevel = statsPerLevel, grantedId = grantedId }
	state.skill = skill
	local grantedId2 = args:match("GrantedEffectId2 = (%w+),")
	if grantedId2 then
		skill.skillData2 = dat("GrantedEffects"):GetRow("Id", grantedId2)
		skill.statsPerLevel2 = dat("GrantedEffectStatSetsPerLevel"):GetRowList("GrantedEffect", skill.skillData2)
		skill.grantedId2 = grantedId2
	end
	local grantedIdUber = args:match("GrantedEffectIdUber = (%w+),")
	if grantedIdUber then
		skill.skillDataUber = dat("GrantedEffects"):GetRow("Id", grantedIdUber)
		skill.statsPerLevelUber = dat("GrantedEffectStatSetsPerLevel"):GetRowList("GrantedEffect", skill.skillDataUber)
		skill.grantedIdUber = grantedIdUber
	end
	state.SkillExtraDamageMult = args:match("ExtraDamageMult = (%d+),")
	state.SkillExtraDamageMult = state.SkillExtraDamageMult and (state.SkillExtraDamageMult / 100) or 1
	skill.stages = args:match("stages = (%w+),")
	local DamageData = {}
	state.DamageData = DamageData
	calcSkillDamage(state)
	-- output
	out:write('	["', boss.displayName, " ", displayName, '"] = {\n')
	out:write('		DamageType = "', getStat(state, "DamageType"),'",\n')
	out:write('		DamageMultipliers = {\n')
	local dCount = 0
	for i, damageType in ipairs({"Physical", "Lightning", "Cold", "Fire", "Chaos"}) do
		if DamageData[damageType.."DamageMultMin"] then
			dCount = dCount + 1
			out:write(dCount > 1 and ',\n' or '', '			', damageType, ' = { ', DamageData[damageType.."DamageMultMin"], ', ', (DamageData[damageType.."DamageMultMax"] - DamageData[damageType.."DamageMultMin"]) / 100, ' }')
		end
	end
	if dCount == 0 then
		print("error skill: "..skill.displayName.." has no damage")
	end
	out:write('\n		}')
	if DamageData.SkillUberDamageMult then
		out:write(',\n		UberDamageMultiplier = ', (DamageData.SkillUberDamageMult / 100))
	end
	if getStat(state, "Penetration") then
		out:write(',\n		DamagePenetrations = {\n')
		dCount = 0
		for _, penType in ipairs({"PhysOverwhelm", "LightningPen", "ColdPen", "FirePen"}) do
			if DamageData[penType] ~= 0 then
				dCount = dCount + 1
				out:write(dCount > 1 and ',\n' or '', '			', penType, ' = ', (DamageData[penType] == "" and '""' or DamageData[penType]))
			end
		end
		out:write('\n		}')
		if DamageData["PhysUberOverwhelm"] ~= 0 or DamageData["LightningUberPen"] ~= 0 or DamageData["ColdUberPen"] ~= 0 or DamageData["FireUberPen"] ~= 0 then
			out:write(',\n		UberDamagePenetrations = {\n')
			dCount = 0
			for _, penType in ipairs({"PhysUberOverwhelm", "LightningUberPen", "ColdUberPen", "FireUberPen"}) do
				if DamageData[penType] ~= 0 then
					dCount = dCount + 1
					out:write(dCount > 1 and ',\n' or '', '			', penType:gsub("Uber", ""), ' = ', DamageData[penType])
				end
			end
			out:write('\n		}')
		end
	end
	skill.speedMult = args:match("speedMult = (%d+),")
	local speed, uberSpeed = getStat(state, "Speed")
	if speed and speed ~= 700 then
		out:write(',\n		speed = ', speed)
	end
	if uberSpeed and uberSpeed ~= 700 then
		out:write(',\n		UberSpeed = ', uberSpeed)
	end
	local critChance = statsPerLevel[1].AttackCritChance
	if critChance or boss.critChance then
		critChance = critChance and (m_ceil(critChance / 100)) or boss.critChance
		if critChance ~= 5 then
			out:write(',\n		critChance = ', critChance)
		end
	end
	if boss.earlierUber then
		out:write(',\n		earlierUber = true')
	end
end

 -- #tooltip
 directiveTable.skills.tooltip = function(state, args, out)
	if args then
		out:write(',\n		tooltip = ', args,'\n')
	end
	out:write('	},\n')
	state.skill = nil
end

 -- #skillList
 directiveTable.skills.skillList = function(state, args, out)
	out:write('},{\n')
	out:write('    { val = "None", label = "None" }')
	for _, skillName in pairs(state.skillList) do
		out:write(',\n    { val = "', skillName, '", label = "', skillName, '" }')
	end
	out:write('\n}')
	state.boss = nil
	state.skillList = nil
end

processTemplateFile("BossSkills", "Enemies/", "../Data/", directiveTable.skills)
print("Boss skill data exported.")
processTemplateFile("Bosses", "Enemies/", "../Data/", directiveTable.monsters)
print("Boss data exported.")

