-- Path of Building
--
-- Module: Calc Offence
-- Performs offence calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local unpack = unpack
local t_insert = table.insert
local m_floor = math.floor
local m_modf = math.modf
local m_min = math.min
local m_max = math.max
local m_sqrt = math.sqrt
local m_pi = math.pi
local bor = bit.bor
local band = bit.band
local bnot = bit.bnot
local s_format = string.format

local tempTable1 = { }
local tempTable2 = { }
local tempTable3 = { }

local isElemental = { Fire = true, Cold = true, Lightning = true }

-- List of all damage types, ordered according to the conversion sequence
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}
local dmgTypeFlags = {
	Physical	= 0x01,
	Lightning	= 0x02,
	Cold		= 0x04,
	Fire		= 0x08,
	Elemental	= 0x0E,
	Chaos		= 0x10,
}

-- Magic table for caching the modifier name sets used in calcDamage()
local damageStatsForTypes = setmetatable({ }, { __index = function(t, k)
	local modNames = { "Damage" }
	for type, flag in pairs(dmgTypeFlags) do
		if band(k, flag) ~= 0 then
			t_insert(modNames, type.."Damage")
		end
	end
	t[k] = modNames
	return modNames
end })

-- Calculate min/max damage for the given damage type
local function calcDamage(activeSkill, output, cfg, breakdown, damageType, typeFlags, convDst)
	local skillModList = activeSkill.skillModList

	typeFlags = bor(typeFlags, dmgTypeFlags[damageType])

	-- Calculate conversions
	local addMin, addMax = 0, 0
	local conversionTable = activeSkill.conversionTable
	for _, otherType in ipairs(dmgTypeList) do
		if otherType == damageType then
			-- Damage can only be converted from damage types that precede this one in the conversion sequence, so stop here
			break
		end
		local convMult = conversionTable[otherType][damageType]
		if convMult > 0 then
			-- Damage is being converted/gained from the other damage type
			local min, max = calcDamage(activeSkill, output, cfg, breakdown, otherType, typeFlags, damageType)
			addMin = addMin + min * convMult
			addMax = addMax + max * convMult
		end
	end
	if addMin ~= 0 and addMax ~= 0 then
		addMin = round(addMin)
		addMax = round(addMax)
	end

	local baseMin = output[damageType.."MinBase"]
	local baseMax = output[damageType.."MaxBase"]
	if baseMin == 0 and baseMax == 0 then
		-- No base damage for this type, don't need to calculate modifiers
		if breakdown and (addMin ~= 0 or addMax ~= 0) then
			t_insert(breakdown.damageTypes, {
				source = damageType,
				convSrc = (addMin ~= 0 or addMax ~= 0) and (addMin .. " to " .. addMax),
				total = addMin .. " to " .. addMax,
				convDst = convDst and s_format("%d%% to %s", conversionTable[damageType][convDst] * 100, convDst),
			})
		end
		return addMin, addMax
	end

	-- Combine modifiers
	local modNames = damageStatsForTypes[typeFlags]
	local inc = 1 + skillModList:Sum("INC", cfg, unpack(modNames)) / 100
	local more = m_floor(skillModList:More(cfg, unpack(modNames)) * 100 + 0.50000001) / 100
	local moreMinDamage = skillModList:More(cfg, "Min"..damageType.."Damage")
	local moreMaxDamage = skillModList:More(cfg, "Max"..damageType.."Damage")

	if breakdown then
		t_insert(breakdown.damageTypes, {
			source = damageType,
			base = baseMin .. " to " .. baseMax,
			inc = (inc ~= 1 and "x "..inc),
			more = (more ~= 1 and "x "..more),
			convSrc = (addMin ~= 0 or addMax ~= 0) and (addMin .. " to " .. addMax),
			total = (round(baseMin * inc * more) + addMin) .. " to " .. (round(baseMax * inc * more) + addMax),
			convDst = convDst and conversionTable[damageType][convDst] > 0 and s_format("%d%% to %s", conversionTable[damageType][convDst] * 100, convDst),
		})
	end

	return 	round(((baseMin * inc * more) + addMin) * moreMinDamage),
			round(((baseMax * inc * more) + addMax) * moreMaxDamage)
end

local function calcAilmentSourceDamage(activeSkill, output, cfg, breakdown, damageType, typeFlags)
	local min, max = calcDamage(activeSkill, output, cfg, breakdown, damageType, typeFlags)
	local convMult = activeSkill.conversionTable[damageType].mult
	if breakdown and convMult ~= 1 then
		t_insert(breakdown, "Source damage:")
		t_insert(breakdown, s_format("%d to %d ^8(total damage)", min, max))
		t_insert(breakdown, s_format("x %g ^8(%g%% converted to other damage types)", convMult, (1-convMult)*100))
		t_insert(breakdown, s_format("= %d to %d", min * convMult, max * convMult))
	end
	return min * convMult, max * convMult
end

-- Performs all offensive calculations
function calcs.offence(env, actor, activeSkill)
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local breakdown = actor.breakdown

	local skillModList = activeSkill.skillModList
	local skillData = activeSkill.skillData
	local skillFlags = activeSkill.skillFlags
	local skillCfg = activeSkill.skillCfg
	if skillData.showAverage then
		skillFlags.showAverage = true
	else
		skillFlags.notAverage = true
	end

	if skillFlags.disable then
		-- Skill is disabled
		output.CombinedDPS = 0
		return
	end

	local function runSkillFunc(name)
		local func = activeSkill.activeEffect.grantedEffect[name]
		if func then
			func(activeSkill, output)
		end
	end

	runSkillFunc("initialFunc")

	-- Update skill data
	for _, value in ipairs(skillModList:List(skillCfg, "SkillData")) do
		if value.merge == "MAX" then
			skillData[value.key] = m_max(value.value, skillData[value.key] or 0)
		else
			skillData[value.key] = value.value
		end
	end

	skillCfg.skillCond["SkillIsTriggered"] = skillData.triggered

	-- Add addition stat bonuses
	if skillModList:Flag(nil, "IronGrip") then
		skillModList:NewMod("PhysicalDamage", "INC", actor.strDmgBonus, "Strength", bor(ModFlag.Attack, ModFlag.Projectile))
	end
	if skillModList:Flag(nil, "IronWill") then
		skillModList:NewMod("Damage", "INC", actor.strDmgBonus, "Strength", ModFlag.Spell)
	end
	
	if skillModList:Flag(nil, "TransfigurationOfBody") then
		skillModList:NewMod("Damage", "INC", m_floor(skillModList:Sum("INC", nil, "Life") * 0.3), "Transfiguration of Body", ModFlag.Attack)
	end
	if skillModList:Flag(nil, "TransfigurationOfMind") then
		skillModList:NewMod("Damage", "INC", m_floor(skillModList:Sum("INC", nil, "Mana") * 0.3), "Transfiguration of Mind")
	end
	if skillModList:Flag(nil, "TransfigurationOfSoul") then
		skillModList:NewMod("Damage", "INC", m_floor(skillModList:Sum("INC", nil, "EnergyShield") * 0.3), "Transfiguration of Soul", ModFlag.Spell)
	end

	if skillModList:Flag(nil, "MinionDamageAppliesToPlayer") then
		-- Minion Damage conversion from The Scourge
		for _, value in ipairs(skillModList:List(skillCfg, "MinionModifier")) do
			if value.mod.name == "Damage" and value.mod.type == "INC" then
				skillModList:AddMod(value.mod)
			end
		end
	end
	if skillModList:Flag(nil, "MinionAttackSpeedAppliesToPlayer") then
		-- Minion Attack Speed conversion from Spiritual Command
		for _, value in ipairs(skillModList:List(skillCfg, "MinionModifier")) do
			if value.mod.name == "Speed" and value.mod.type == "INC" and (value.mod.flags == 0 or band(value.mod.flags, ModFlag.Attack) ~= 0) then
				skillModList:NewMod("Speed", "INC", value.mod.value, value.mod.source, ModFlag.Attack, value.mod.keywordFlags, unpack(value.mod))
			end
		end
	end
	if skillModList:Flag(nil, "SpellDamageAppliesToAttacks") then
		-- Spell Damage conversion from Crown of Eyes
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Spell }, "Damage")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Spell) ~= 0 then
				skillModList:NewMod("Damage", "INC", mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Spell)), ModFlag.Attack), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "ClawDamageAppliesToUnarmed") then
		-- Claw Damage conversion from Rigwald's Curse
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Claw }, "Damage")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				skillModList:NewMod("Damage", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "ClawAttackSpeedAppliesToUnarmed") then
		-- Claw Attack Speed conversion from Rigwald's Curse
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = bor(ModFlag.Claw, ModFlag.Attack) }, "Speed")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 and band(mod.flags, ModFlag.Attack) ~= 0 then
				skillModList:NewMod("Speed", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "ClawCritChanceAppliesToUnarmed") then
		-- Claw Crit Chance conversion from Rigwald's Curse
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Claw }, "CritChance")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				skillModList:NewMod("CritChance", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "LightRadiusAppliesToAccuracy") then
		-- Light Radius conversion from Corona Solaris
		for i, value in ipairs(skillModList:Tabulate("INC",  { }, "LightRadius")) do
			local mod = value.mod
			skillModList:NewMod("Accuracy", "INC", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
		end
	end
	if skillModList:Flag(nil, "LightRadiusAppliesToAreaOfEffect") then
		-- Light Radius conversion from Wreath of Phrecia
		for i, value in ipairs(skillModList:Tabulate("INC",  { }, "LightRadius")) do
			local mod = value.mod
			skillModList:NewMod("AreaOfEffect", "INC", math.floor(mod.value / 2), mod.source, mod.flags, mod.keywordFlags, unpack(mod))
		end
	end
	if skillModList:Flag(nil, "LightRadiusAppliesToDamage") then
		-- Light Radius conversion from Wreath of Phrecia
		for i, value in ipairs(skillModList:Tabulate("INC",  { }, "LightRadius")) do
			local mod = value.mod
			skillModList:NewMod("Damage", "INC", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
		end
	end
	if skillModList:Flag(nil, "CastSpeedAppliesToTrapThrowingSpeed") then
		-- Cast Speed conversion from Slavedriver's Hand
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Cast }, "Speed")) do
			local mod = value.mod
			if (mod.flags == 0 or band(mod.flags, ModFlag.Cast) ~= 0) then
				skillModList:NewMod("TrapThrowingSpeed", "INC", mod.value, mod.source, band(mod.flags, bnot(ModFlag.Cast), bnot(ModFlag.Attack)), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillData.arrowSpeedAppliesToAreaOfEffect then
		-- Arrow Speed conversion for Galvanic Arrow
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Bow }, "ProjectileSpeed")) do
			local mod = value.mod
			skillModList:NewMod("AreaOfEffect", "INC", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
		end
	end
	if skillModList:Flag(nil, "SequentialProjectiles") and not skillModList:Flag(nil, "OneShotProj") and not skillModList:Flag(nil,"NoAdditionalProjectiles") then
		-- Applies DPS multiplier based on projectile count
		skillData.dpsMultiplier = skillModList:Sum("BASE", skillCfg, "ProjectileCount")
	end

	local isAttack = skillFlags.attack

	runSkillFunc("preSkillTypeFunc")

	-- Calculate skill type stats
	if skillFlags.minion then
		if activeSkill.minion and activeSkill.minion.minionData.limit then
			output.ActiveMinionLimit = m_floor(calcLib.val(skillModList, activeSkill.minion.minionData.limit, skillCfg))
		end
	end
	if skillFlags.chaining then
		if skillModList:Flag(skillCfg, "CannotChain") then
			output.ChainMaxString = "Cannot chain"
		else
			output.ChainMax = skillModList:Sum("BASE", skillCfg, "ChainCountMax", not skillFlags.projectile and "BeamChainCountMax" or nil)
			output.ChainMaxString = output.ChainMax
			output.Chain = m_min(output.ChainMax, skillModList:Sum("BASE", skillCfg, "ChainCount"))
			output.ChainRemaining = m_max(0, output.ChainMax - output.Chain)
		end
	end
	if skillFlags.projectile then
		if skillModList:Flag(nil, "PointBlank") then
			skillModList:NewMod("Damage", "MORE", 30, "Point Blank", bor(ModFlag.Attack, ModFlag.Projectile), { type = "DistanceRamp", ramp = {{10,1},{35,0},{150,-1}} })
		end
		if skillModList:Flag(nil, "FarShot") then
			skillModList:NewMod("Damage", "MORE", 30, "Far Shot", bor(ModFlag.Attack, ModFlag.Projectile), { type = "DistanceRamp", ramp = {{35,0},{70,1}} })
		end
		if skillModList:Flag(skillCfg, "NoAdditionalProjectiles") then
			output.ProjectileCount = 1
		else
			local projBase = skillModList:Sum("BASE", skillCfg, "ProjectileCount")
			local projMore = skillModList:More(skillCfg, "ProjectileCount")
			output.ProjectileCount = round((projBase - 1) * projMore + 1)
		end
		if skillModList:Flag(skillCfg, "CannotPierce") then
			output.PierceCountString = "Cannot pierce"
		else
			if skillModList:Flag(skillCfg, "PierceAllTargets") or enemyDB:Flag(nil, "AlwaysPierceSelf") then
				output.PierceCount = 100
				output.PierceCountString = "All targets"
			else
				output.PierceCount = skillModList:Sum("BASE", skillCfg, "PierceCount")
				output.PierceCountString = output.PierceCount
			end
		end
		output.ProjectileSpeedMod = calcLib.mod(skillModList, skillCfg, "ProjectileSpeed")
		if breakdown then
			breakdown.ProjectileSpeedMod = breakdown.mod(skillCfg, "ProjectileSpeed")
		end
	end
	if skillFlags.melee then
		if skillFlags.weapon1Attack then
			actor.weaponRange1 = (actor.weaponData1.range and actor.weaponData1.range + skillModList:Sum("BASE", activeSkill.weapon1Cfg, "MeleeWeaponRange")) or (6 + skillModList:Sum("BASE", skillCfg, "UnarmedRange"))	
		end
		if skillFlags.weapon2Attack then
			actor.weaponRange2 = (actor.weaponData2.range and actor.weaponData2.range + skillModList:Sum("BASE", activeSkill.weapon2Cfg, "MeleeWeaponRange")) or (6 + skillModList:Sum("BASE", skillCfg, "UnarmedRange"))	
		end
		if activeSkill.skillTypes[SkillType.MeleeSingleTarget] then
			local range = 100
			if skillFlags.weapon1Attack then
				range = m_min(range, actor.weaponRange1)
			end
			if skillFlags.weapon2Attack then
				range = m_min(range, actor.weaponRange2)
			end
			output.WeaponRange = range + 2
			if breakdown then
				breakdown.WeaponRange = {
					radius = output.WeaponRange
				}
			end
		end
	end
	if skillFlags.area or skillData.radius or (skillFlags.mine and activeSkill.skillTypes[SkillType.Aura]) then
		output.AreaOfEffectMod = calcLib.mod(skillModList, skillCfg, "AreaOfEffect")
		if skillData.radiusIsWeaponRange then
			local range = 0
			if skillFlags.weapon1Attack then
				range = m_max(range, actor.weaponRange1)
			end
			if skillFlags.weapon2Attack then
				range = m_max(range, actor.weaponRange2)
			end
			skillData.radius = range + 2
		end
		if skillData.radius then
			skillFlags.area = true
			local baseRadius = skillData.radius + (skillData.radiusExtra or 0) + skillModList:Sum("BASE", skillCfg, "AreaOfEffect")
			output.AreaOfEffectRadius = m_floor(baseRadius * m_sqrt(output.AreaOfEffectMod))
			if breakdown then
				breakdown.AreaOfEffectRadius = breakdown.area(baseRadius, output.AreaOfEffectMod, output.AreaOfEffectRadius, skillData.radiusLabel)
			end
			if skillData.radiusSecondary then
				output.AreaOfEffectModSecondary = calcLib.mod(skillModList, skillCfg, "AreaOfEffect", "AreaOfEffectSecondary")
				baseRadius = skillData.radiusSecondary + (skillData.radiusExtra or 0)
				output.AreaOfEffectRadiusSecondary = m_floor(baseRadius * m_sqrt(output.AreaOfEffectModSecondary))
				if breakdown then
					breakdown.AreaOfEffectRadiusSecondary = breakdown.area(baseRadius, output.AreaOfEffectModSecondary, output.AreaOfEffectRadiusSecondary, skillData.radiusSecondaryLabel)
				end
			end
			if skillData.radiusTertiary then
				output.AreaOfEffectModTertiary = calcLib.mod(skillModList, skillCfg, "AreaOfEffect", "AreaOfEffectTertiary")
				baseRadius = skillData.radiusTertiary + (skillData.radiusExtra or 0)
				output.AreaOfEffectRadiusTertiary = m_floor(baseRadius * m_sqrt(output.AreaOfEffectModTertiary))
				if breakdown then
					breakdown.AreaOfEffectRadiusTertiary = breakdown.area(baseRadius, output.AreaOfEffectModTertiary, output.AreaOfEffectRadiusTertiary, skillData.radiusTertiaryLabel)
				end
			end
		end
		if breakdown then
			breakdown.AreaOfEffectMod = breakdown.mod(skillCfg, "AreaOfEffect")
		end
	end
	if activeSkill.skillTypes[SkillType.Aura] then
		output.AuraEffectMod = calcLib.mod(skillModList, skillCfg, "AuraEffect")
		if breakdown then
			breakdown.AuraEffectMod = breakdown.mod(skillCfg, "AuraEffect")
		end
	end
	if activeSkill.skillTypes[SkillType.Curse] then
		output.CurseEffectMod = calcLib.mod(skillModList, skillCfg, "CurseEffect")
		if breakdown then
			breakdown.CurseEffectMod = breakdown.mod(skillCfg, "CurseEffect")
		end
	end
	if skillFlags.trap then
		local baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "TrapThrowingTime")
		local timeMod = calcLib.mod(skillModList, skillCfg, "SkillTrapThrowingTime")
		if timeMod > 0 then
			baseSpeed = baseSpeed * (1 / timeMod)
		end
		output.TrapThrowingSpeed = baseSpeed * calcLib.mod(skillModList, skillCfg, "TrapThrowingSpeed") * output.ActionSpeedMod
		output.TrapThrowingTime = 1 / output.TrapThrowingSpeed
		if breakdown then
			breakdown.TrapThrowingSpeed = { }
			breakdown.multiChain(breakdown.TrapThrowingSpeed, {
				label = "Throwing rate:",
				base = s_format("%.2f ^8(base throwing rate)", baseSpeed),
				{ "%.2f ^8(increased/reduced throwing speed)", 1 + skillModList:Sum("INC", skillCfg, "TrapThrowingSpeed") / 100 },
				{ "%.2f ^8(more/less throwing speed)", skillModList:More(skillCfg, "TrapThrowingSpeed") },
				{ "%.2f ^8(action speed modifier)",  output.ActionSpeedMod },
				total = s_format("= %.2f ^8per second", output.TrapThrowingSpeed),
			})
		end
		if breakdown and timeMod > 0 then
			breakdown.TrapThrowingTime = { }
			breakdown.multiChain(breakdown.TrapThrowingTime, {
				label = "Throwing time:",
				base = s_format("%.2f ^8(base throwing time)", 1 / (output.TrapThrowingSpeed * timeMod)),
				{ "%.2f ^8(total modifier)", timeMod },
				total = s_format("= %.2f ^8seconds per throw", output.TrapThrowingTime),
			})
		end
		output.ActiveTrapLimit = skillModList:Sum("BASE", skillCfg, "ActiveTrapLimit")
		local baseCooldown = skillData.trapCooldown or skillData.cooldown
		if baseCooldown then
			output.TrapCooldown = baseCooldown / calcLib.mod(skillModList, skillCfg, "CooldownRecovery")
			if breakdown then
				breakdown.TrapCooldown = {
					s_format("%.2fs ^8(base)", skillData.trapCooldown or skillData.cooldown or 4),
					s_format("/ %.2f ^8(increased/reduced cooldown recovery)", 1 + skillModList:Sum("INC", skillCfg, "CooldownRecovery") / 100),
					s_format("= %.2fs", output.TrapCooldown)
				}
			end
		end
		local areaMod = calcLib.mod(skillModList, skillCfg, "TrapTriggerAreaOfEffect")
		output.TrapTriggerRadius = 10 * m_sqrt(areaMod)
		if breakdown then
			breakdown.TrapTriggerRadius = breakdown.area(10, areaMod, output.TrapTriggerRadius)
		end
	elseif skillData.cooldown then
		local cooldownOverride = skillModList:Override(skillCfg, "CooldownRecovery")
		output.Cooldown = cooldownOverride or skillData.cooldown / calcLib.mod(skillModList, skillCfg, "CooldownRecovery")
		if breakdown then
			breakdown.Cooldown = {
				s_format("%.2fs ^8(base)", skillData.cooldown),
				s_format("/ %.2f ^8(increased/reduced cooldown recovery)", 1 + skillModList:Sum("INC", skillCfg, "CooldownRecovery") / 100),
				s_format("= %.2fs", output.Cooldown)
			}
		end
	end
	if skillFlags.mine then
		local baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "MineLayingTime")
		local timeMod = calcLib.mod(skillModList, skillCfg, "SkillMineThrowingTime")
		if timeMod > 0 then
			baseSpeed = baseSpeed * (1 / timeMod)
		end
		output.MineLayingSpeed = baseSpeed * calcLib.mod(skillModList, skillCfg, "MineLayingSpeed") * output.ActionSpeedMod
		output.MineLayingTime = 1 / output.MineLayingSpeed
		if breakdown then
			breakdown.MineLayingTime = { }
			breakdown.multiChain(breakdown.MineLayingTime, {
				label = "Throwing rate:",
				base = s_format("%.2f ^8(base throwing rate)", baseSpeed),
				{ "%.2f ^8(increased/reduced throwing speed)", 1 + skillModList:Sum("INC", skillCfg, "MineLayingSpeed") / 100 },
				{ "%.2f ^8(more/less throwing speed)", skillModList:More(skillCfg, "MineLayingSpeed") },
				{ "%.2f ^8(action speed modifier)",  output.ActionSpeedMod },
				total = s_format("= %.2f ^8per second", output.MineLayingSpeed),
			})
		end
		if breakdown and timeMod > 0 then
			breakdown.MineThrowingTime = { }
			breakdown.multiChain(breakdown.MineThrowingTime, {
			label = "Throwing time:",
				base = s_format("%.2f ^8(base throwing time)", 1 / (output.MineLayingSpeed * timeMod)),
				{ "%.2f ^8(total modifier)", timeMod },
				total = s_format("= %.2f ^8seconds per throw", output.MineLayingTime),
			})
		end
		output.ActiveMineLimit = skillModList:Sum("BASE", skillCfg, "ActiveMineLimit")
		local areaMod = calcLib.mod(skillModList, skillCfg, "MineDetonationAreaOfEffect")
		output.MineDetonationRadius = 60 * m_sqrt(areaMod)
		if breakdown then
			breakdown.MineDetonationRadius = breakdown.area(60, areaMod, output.MineDetonationRadius)
		end
		if activeSkill.skillTypes[SkillType.Aura] then
			output.MineAuraRadius = 35 * m_sqrt(output.AreaOfEffectMod)
			if breakdown then
				breakdown.MineAuraRadius = breakdown.area(35, output.AreaOfEffectMod, output.MineAuraRadius)
			end
		end
	end
	if skillFlags.totem then
		local baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "TotemPlacementTime")
		output.TotemPlacementSpeed = baseSpeed * calcLib.mod(skillModList, skillCfg, "TotemPlacementSpeed") * output.ActionSpeedMod
		output.TotemPlacementTime = 1 / output.TotemPlacementSpeed
		if breakdown then
			breakdown.TotemPlacementTime = { }
			breakdown.multiChain(breakdown.TotemPlacementTime, {
				label = "Placement speed:",
				base = s_format("%.2f ^8(base placement speed)", baseSpeed),
				{ "%.2f ^8(increased/reduced placement speed)", 1 + skillModList:Sum("INC", skillCfg, "TotemPlacementSpeed") / 100 },
				{ "%.2f ^8(more/less placement speed)", skillModList:More(skillCfg, "TotemPlacementSpeed") },
				{ "%.2f ^8(action speed modifier)",  output.ActionSpeedMod },
				total = s_format("= %.2f ^8per second", output.TotemPlacementSpeed),
			})
		end
		output.TotemLifeMod = calcLib.mod(skillModList, skillCfg, "TotemLife")
		output.TotemLife = round(m_floor(env.data.monsterAllyLifeTable[skillData.totemLevel] * env.data.totemLifeMult[activeSkill.skillTotemId]) * output.TotemLifeMod)
		if breakdown then
			breakdown.TotemLifeMod = breakdown.mod(skillCfg, "TotemLife")
			breakdown.TotemLife = {
				"Totem level: "..skillData.totemLevel,
				env.data.monsterAllyLifeTable[skillData.totemLevel].." ^8(base life for a level "..skillData.totemLevel.." monster)",
				"x "..env.data.totemLifeMult[activeSkill.skillTotemId].." ^8(life multiplier for this totem type)",
				"x "..output.TotemLifeMod.." ^8(totem life modifier)",
				"= "..output.TotemLife,
			}
		end
	end

	-- Skill duration
	local debuffDurationMult
	if env.mode_effective then
		debuffDurationMult = 1 / calcLib.mod(enemyDB, skillCfg, "BuffExpireFaster")
	else
		debuffDurationMult = 1
	end
	do
		output.DurationMod = calcLib.mod(skillModList, skillCfg, "Duration", "PrimaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
		if breakdown then
			breakdown.DurationMod = breakdown.mod(skillCfg, "Duration", "PrimaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
		end
		local durationBase = (skillData.duration or 0) + skillModList:Sum("BASE", skillCfg, "Duration", "PrimaryDuration")
		if durationBase > 0 then
			output.Duration = durationBase * output.DurationMod
			if skillData.debuff then
				output.Duration = output.Duration * debuffDurationMult
			end
			if breakdown and output.Duration ~= durationBase then
				breakdown.Duration = {
					s_format("%.2fs ^8(base)", durationBase),
				}
				if output.DurationMod ~= 1 then
					t_insert(breakdown.Duration, s_format("x %.2f ^8(duration modifier)", output.DurationMod))
				end
				if skillData.debuff and debuffDurationMult ~= 1 then
					t_insert(breakdown.Duration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
				end
				t_insert(breakdown.Duration, s_format("= %.2fs", output.Duration))
			end
		end
		durationBase = (skillData.durationSecondary or 0) + skillModList:Sum("BASE", skillCfg, "Duration", "SecondaryDuration")
		if durationBase > 0 then
			local durationMod = calcLib.mod(skillModList, skillCfg, "Duration", "SecondaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
			output.DurationSecondary = durationBase * durationMod
			if skillData.debuffSecondary then
				output.DurationSecondary = output.DurationSecondary * debuffDurationMult
			end
			if breakdown and output.DurationSecondary ~= durationBase then
				breakdown.DurationSecondary = {
					s_format("%.2fs ^8(base)", durationBase),
				}
				if output.DurationMod ~= 1 then
					t_insert(breakdown.DurationSecondary, s_format("x %.2f ^8(duration modifier)", durationMod))
				end
				if skillData.debuffSecondary and debuffDurationMult ~= 1 then
					t_insert(breakdown.DurationSecondary, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
				end
				t_insert(breakdown.DurationSecondary, s_format("= %.2fs", output.DurationSecondary))
			end
		end
		durationBase = (skillData.auraDuration or 0)
		if durationBase > 0 then
			local durationMod = calcLib.mod(skillModList, skillCfg, "Duration", "SkillAndDamagingAilmentDuration")
			output.AuraDuration = durationBase * durationMod
			if breakdown and output.AuraDuration ~= durationBase then
				breakdown.AuraDuration = {
					s_format("%.2fs ^8(base)", durationBase),
					s_format("x %.2f ^8(duration modifier)", durationMod),
					s_format("= %.2fs", output.AuraDuration),
				}
			end
		end
		durationBase = (skillData.reserveDuration or 0)
		if durationBase > 0 then
			local durationMod = calcLib.mod(skillModList, skillCfg, "Duration", "SkillAndDamagingAilmentDuration")
			output.ReserveDuration = durationBase * durationMod
			if breakdown and output.ReserveDuration ~= durationBase then
				breakdown.ReserveDuration = {
					s_format("%.2fs ^8(base)", durationBase),
					s_format("x %.2f ^8(duration modifier)", durationMod),
					s_format("= %.2fs", output.ReserveDuration),
				}
			end
		end
	end

	-- Calculate mana cost (may be slightly off due to rounding differences)
	do
		local mult = m_floor(skillModList:More(skillCfg, "SupportManaMultiplier") * 100 + 0.0001) / 100
		local more = m_floor(skillModList:More(skillCfg, "ManaCost") * 100 + 0.0001) / 100
		local inc = skillModList:Sum("INC", skillCfg, "ManaCost")
		local base = skillModList:Sum("BASE", skillCfg, "ManaCost")
		local manaCost = activeSkill.activeEffect.grantedEffectLevel.manaCost or 0
		output.ManaCost = m_floor(m_max(0, manaCost * mult * more * (1 + inc / 100) + base))
		if activeSkill.skillTypes[SkillType.ManaCostPercent] and skillFlags.totem then
			output.ManaCost = m_floor(output.Mana * output.ManaCost / 100)
		end
		if breakdown and output.ManaCost ~= manaCost then
			breakdown.ManaCost = {
				s_format("%d ^8(base mana cost)", manaCost)
			}
			if mult ~= 1 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(mana cost multiplier)", mult))
			end
			if inc ~= 0 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(increased/reduced mana cost)", 1 + inc/100))
			end	
			if more ~= 0 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(more/less mana cost)", more))
			end	
			if base ~= 0 then
				t_insert(breakdown.ManaCost, s_format("- %d ^8(- mana cost)", -base))
			end
			t_insert(breakdown.ManaCost, s_format("= %d", output.ManaCost))
		end
	end

	runSkillFunc("preDamageFunc")

	-- Handle corpse explosions
	if skillData.explodeCorpse and skillData.corpseLife then
		local damageType = skillData.corpseExplosionDamageType or "Fire"
		skillData[damageType.."BonusMin"] = skillData.corpseLife * skillData.corpseExplosionLifeMultiplier
		skillData[damageType.."BonusMax"] = skillData.corpseLife * skillData.corpseExplosionLifeMultiplier
	end

	-- Cache global damage disabling flags
	local canDeal = { }
	for _, damageType in pairs(dmgTypeList) do
		canDeal[damageType] = not skillModList:Flag(skillCfg, "DealNo"..damageType)
	end

	-- Calculate damage conversion percentages
	activeSkill.conversionTable = wipeTable(activeSkill.conversionTable)
	for damageTypeIndex = 1, 4 do
		local damageType = dmgTypeList[damageTypeIndex]
		local globalConv = wipeTable(tempTable1)
		local skillConv = wipeTable(tempTable2)
		local add = wipeTable(tempTable3)
		local globalTotal, skillTotal = 0, 0
		for otherTypeIndex = damageTypeIndex + 1, 5 do
			-- For all possible destination types, check for global and skill conversions
			otherType = dmgTypeList[otherTypeIndex]
			globalConv[otherType] = skillModList:Sum("BASE", skillCfg, damageType.."DamageConvertTo"..otherType, isElemental[damageType] and "ElementalDamageConvertTo"..otherType or nil, damageType ~= "Chaos" and "NonChaosDamageConvertTo"..otherType or nil)
			globalTotal = globalTotal + globalConv[otherType]
			skillConv[otherType] = skillModList:Sum("BASE", skillCfg, "Skill"..damageType.."DamageConvertTo"..otherType)
			skillTotal = skillTotal + skillConv[otherType]
			add[otherType] = skillModList:Sum("BASE", skillCfg, damageType.."DamageGainAs"..otherType, isElemental[damageType] and "ElementalDamageGainAs"..otherType or nil, damageType ~= "Chaos" and "NonChaosDamageGainAs"..otherType or nil)
		end
		if skillTotal > 100 then
			-- Skill conversion exceeds 100%, scale it down and remove non-skill conversions
			local factor = 100 / skillTotal
			for type, val in pairs(skillConv) do
				-- Overconversion is fixed in 3.0, so I finally get to uncomment this line!
				skillConv[type] = val * factor
			end
			for type, val in pairs(globalConv) do
				globalConv[type] = 0
			end
		elseif globalTotal + skillTotal > 100 then
			-- Conversion exceeds 100%, scale down non-skill conversions
			local factor = (100 - skillTotal) / globalTotal
			for type, val in pairs(globalConv) do
				globalConv[type] = val * factor
			end
			globalTotal = globalTotal * factor
		end
		local dmgTable = { }
		for type, val in pairs(globalConv) do
			dmgTable[type] = (globalConv[type] + skillConv[type] + add[type]) / 100
		end
		dmgTable.mult = 1 - m_min((globalTotal + skillTotal) / 100, 1)
		activeSkill.conversionTable[damageType] = dmgTable
	end
	activeSkill.conversionTable["Chaos"] = { mult = 1 }

	-- Configure damage passes
	local passList = { }
	if isAttack then
		output.MainHand = { }
		output.OffHand = { }
		local critOverride = skillModList:Override(cfg, "WeaponBaseCritChance")
		if skillFlags.weapon1Attack then
			if breakdown then
				breakdown.MainHand = LoadModule(calcs.breakdownModule, skillModList, output.MainHand)
			end
			activeSkill.weapon1Cfg.skillStats = output.MainHand
			local source = copyTable(actor.weaponData1)
			if critOverride and source.type and source.type ~= "None" then
				source.CritChance = critOverride
			end
			t_insert(passList, {
				label = "Main Hand",
				source = source,
				cfg = activeSkill.weapon1Cfg,
				output = output.MainHand,
				breakdown = breakdown and breakdown.MainHand,
			})
		end
		if skillFlags.weapon2Attack then
			if breakdown then
				breakdown.OffHand = LoadModule(calcs.breakdownModule, skillModList, output.OffHand)
			end
			activeSkill.weapon2Cfg.skillStats = output.OffHand
			local source = copyTable(actor.weaponData2)
			if critOverride and source.type and source.type ~= "None" then
				source.CritChance = critOverride
			end
			if skillData.setOffHandBaseCritChance then
				source.CritChance = skillData.setOffHandBaseCritChance
			end
			if skillData.setOffHandPhysicalMin and skillData.setOffHandPhysicalMax then
				source.PhysicalMin = skillData.setOffHandPhysicalMin
				source.PhysicalMax = skillData.setOffHandPhysicalMax
			end
			if skillData.setOffHandAttackTime then
				source.AttackRate = 1000 / skillData.setOffHandAttackTime
			end
			t_insert(passList, {
				label = "Off Hand",
				source = source,
				cfg = activeSkill.weapon2Cfg,
				output = output.OffHand,
				breakdown = breakdown and breakdown.OffHand,
			})
		end
	else
		t_insert(passList, {
			label = "Skill",
			source = skillData,
			cfg = skillCfg,
			output = output,
			breakdown = breakdown,
		})
	end

	local function combineStat(stat, mode, ...)
		-- Combine stats from Main Hand and Off Hand according to the mode
		if mode == "OR" or not skillFlags.bothWeaponAttack then
			output[stat] = output.MainHand[stat] or output.OffHand[stat]
		elseif mode == "ADD" then
			output[stat] = (output.MainHand[stat] or 0) + (output.OffHand[stat] or 0)
		elseif mode == "AVERAGE" then
			output[stat] = ((output.MainHand[stat] or 0) + (output.OffHand[stat] or 0)) / 2
		elseif mode == "CHANCE" then
			if output.MainHand[stat] and output.OffHand[stat] then
				local mainChance = output.MainHand[...] * output.MainHand.HitChance
				local offChance = output.OffHand[...] * output.OffHand.HitChance
				local mainPortion = mainChance / (mainChance + offChance)
				local offPortion = offChance / (mainChance + offChance)
				output[stat] = output.MainHand[stat] * mainPortion + output.OffHand[stat] * offPortion
				if breakdown then
					if not breakdown[stat] then
						breakdown[stat] = { }
					end
					t_insert(breakdown[stat], "Contribution from Main Hand:")
					t_insert(breakdown[stat], s_format("%.1f", output.MainHand[stat]))
					t_insert(breakdown[stat], s_format("x %.3f ^8(portion of instances created by main hand)", mainPortion))
					t_insert(breakdown[stat], s_format("= %.1f", output.MainHand[stat] * mainPortion))
					t_insert(breakdown[stat], "Contribution from Off Hand:")
					t_insert(breakdown[stat], s_format("%.1f", output.OffHand[stat]))
					t_insert(breakdown[stat], s_format("x %.3f ^8(portion of instances created by off hand)", offPortion))
					t_insert(breakdown[stat], s_format("= %.1f", output.OffHand[stat] * offPortion))
					t_insert(breakdown[stat], "Total:")
					t_insert(breakdown[stat], s_format("%.1f + %.1f", output.MainHand[stat] * mainPortion, output.OffHand[stat] * offPortion))
					t_insert(breakdown[stat], s_format("= %.1f", output[stat]))
				end
			else
				output[stat] = output.MainHand[stat] or output.OffHand[stat]
			end
		elseif mode == "DPS" then
			output[stat] = (output.MainHand[stat] or 0) + (output.OffHand[stat] or 0)
			if not skillData.doubleHitsWhenDualWielding then
				output[stat] = output[stat] / 2
			end
		end
	end

	for _, pass in ipairs(passList) do
		local globalOutput, globalBreakdown = output, breakdown
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown
		
		-- Calculate hit chance 
		output.Accuracy = calcLib.val(skillModList, "Accuracy", cfg)
		if breakdown then
			breakdown.Accuracy = breakdown.simple(nil, cfg, output.Accuracy, "Accuracy")
		end
		if not isAttack or skillModList:Flag(cfg, "CannotBeEvaded") or skillData.cannotBeEvaded or (env.mode_effective and enemyDB:Flag(nil, "CannotEvade")) then
			output.HitChance = 100
		else
			local enemyEvasion = round(calcLib.val(enemyDB, "Evasion"))
			output.HitChance = calcs.hitChance(enemyEvasion, output.Accuracy)
			if breakdown then
				breakdown.HitChance = {
					"Enemy level: "..env.enemyLevel..(env.configInput.enemyLevel and " ^8(overridden from the Configuration tab" or " ^8(can be overridden in the Configuration tab)"),
					"Average enemy evasion: "..enemyEvasion,
					"Approximate hit chance: "..output.HitChance.."%",
				}
			end
		end

		-- Calculate attack/cast speed
		if activeSkill.activeEffect.grantedEffect.castTime == 0 and not skillData.castTimeOverride then
			output.Time = 0
			output.Speed = 0
		elseif skillData.timeOverride then
			output.Time = skillData.timeOverride
			output.Speed = 1 / output.Time
		elseif skillData.fixedCastTime then
			output.Time = activeSkill.activeEffect.grantedEffect.castTime
			output.Speed = 1 / output.Time
		else
			local baseTime
			if isAttack then
				if skillData.castTimeOverridesAttackTime then
					-- Skill is overriding weapon attack speed
					baseTime = activeSkill.activeEffect.grantedEffect.castTime / (1 + (source.AttackSpeedInc or 0) / 100)
				elseif calcLib.mod(skillModList, skillCfg, "SkillAttackTime") > 0 then
					baseTime = (1 / ( source.AttackRate or 1 ) + skillModList:Sum("BASE", cfg, "Speed")) * calcLib.mod(skillModList, skillCfg, "SkillAttackTime")
				else
					baseTime = 1 / ( source.AttackRate or 1 ) + skillModList:Sum("BASE", cfg, "Speed")
				end
			else
				baseTime = skillData.castTimeOverride or activeSkill.activeEffect.grantedEffect.castTime or 1
			end
			local inc = skillModList:Sum("INC", cfg, "Speed")
			local more = skillModList:More(cfg, "Speed")
			output.Speed = 1 / baseTime * round((1 + inc/100) * more, 2)
			if skillData.attackRateCap then
				output.Speed = m_min(output.Speed, skillData.attackRateCap)
			end
			if skillFlags.selfCast then
				-- Self-cast skill; apply action speed
				output.Speed = output.Speed * globalOutput.ActionSpeedMod
			end
			if output.Speed == 0 then 
				output.Time = 0
			else 
				output.Time = 1 / output.Speed
			end
			if breakdown then
				breakdown.Speed = { }
				breakdown.multiChain(breakdown.Speed, {
					base = s_format("%.2f ^8(base)", 1 / baseTime),
					{ "%.2f ^8(increased/reduced)", 1 + inc/100 },
					{ "%.2f ^8(more/less)", more },
					{ "%.2f ^8(action speed modifier)", skillFlags.selfCast and globalOutput.ActionSpeedMod or 1 },
					total = s_format("= %.2f ^8per second", output.Speed)
				})
			end
			if breakdown and calcLib.mod(skillModList, skillCfg, "SkillAttackTime") > 0 then
				breakdown.Time = { }
				breakdown.multiChain(breakdown.Time, {
					base = s_format("%.2f ^8(base)", 1 / (output.Speed * calcLib.mod(skillModList, skillCfg, "SkillAttackTime") )),
					{ "%.2f ^8(total modifier)", calcLib.mod(skillModList, skillCfg, "SkillAttackTime")  },
					total = s_format("= %.2f ^8seconds per attack", output.Time)
				})
			end 
		end
		if skillData.hitTimeOverride then
			output.HitTime = skillData.hitTimeOverride
			output.HitSpeed = 1 / output.HitTime
		end
	end

	if isAttack then
		-- Combine hit chance and attack speed
		combineStat("HitChance", "AVERAGE")
		combineStat("Speed", "AVERAGE")
		combineStat("HitSpeed", "OR")
		if output.Speed == 0 then
			output.Time = 0
		else
			output.Time = 1 / output.Speed
		end
		if skillFlags.bothWeaponAttack then
			if breakdown then
				breakdown.Speed = {
					"Both weapons:",
					s_format("(%.2f + %.2f) / 2", output.MainHand.Speed, output.OffHand.Speed),
					s_format("= %.2f", output.Speed),
				}
			end
		end
	end

	for _, pass in ipairs(passList) do
		local globalOutput, globalBreakdown = output, breakdown
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown

		-- Calculate crit chance, crit multiplier, and their combined effect
		if skillModList:Flag(nil, "NeverCrit") then
			output.PreEffectiveCritChance = 0
			output.CritChance = 0
			output.CritMultiplier = 0
			output.BonusCritDotMultiplier = 0
			output.CritEffect = 1
		else
			local baseCrit = source.CritChance or 0
			if baseCrit == 100 then
				output.PreEffectiveCritChance = 100
				output.CritChance = 100
			else
				local base = skillModList:Sum("BASE", cfg, "CritChance") + (env.mode_effective and enemyDB:Sum("BASE", nil, "SelfCritChance") or 0)
				local inc = skillModList:Sum("INC", cfg, "CritChance") + (env.mode_effective and enemyDB:Sum("INC", nil, "SelfCritChance") or 0)
				local more = skillModList:More(cfg, "CritChance")
				output.CritChance = (baseCrit + base) * (1 + inc / 100) * more
				local preCapCritChance = output.CritChance
				output.CritChance = m_min(output.CritChance, 100)
				if (baseCrit + base) > 0 then
					output.CritChance = m_max(output.CritChance, 0)
				end
				output.PreEffectiveCritChance = output.CritChance
				local preLuckyCritChance = output.CritChance
				if env.mode_effective and skillModList:Flag(cfg, "CritChanceLucky") then
					output.CritChance = (1 - (1 - output.CritChance / 100) ^ 2) * 100
				end
				local preHitCheckCritChance = output.CritChance
				if env.mode_effective then
					output.CritChance = output.CritChance * output.HitChance / 100
				end
				if breakdown and output.CritChance ~= baseCrit then
					breakdown.CritChance = { }
					if base ~= 0 then
						t_insert(breakdown.CritChance, s_format("(%g + %g) ^8(base)", baseCrit, base))
					else
						t_insert(breakdown.CritChance, s_format("%g ^8(base)", baseCrit + base))
					end
					if inc ~= 0 then
						t_insert(breakdown.CritChance, s_format("x %.2f", 1 + inc/100).." ^8(increased/reduced)")
					end
					if more ~= 1 then
						t_insert(breakdown.CritChance, s_format("x %.2f", more).." ^8(more/less)")
					end
					t_insert(breakdown.CritChance, s_format("= %.2f%% ^8(crit chance)", output.PreEffectiveCritChance))
					if preCapCritChance > 100 then
						local overCap = preCapCritChance - 100
						t_insert(breakdown.CritChance, s_format("Crit is overcapped by %.2f%% (%d%% increased Critical Strike Chance)", overCap, overCap / more / (baseCrit + base) * 100))
					end
					if env.mode_effective and skillModList:Flag(cfg, "CritChanceLucky") then
						t_insert(breakdown.CritChance, "Crit Chance is Lucky:")
						t_insert(breakdown.CritChance, s_format("1 - (1 - %.4f) x (1 - %.4f)", preLuckyCritChance / 100, preLuckyCritChance / 100))
						t_insert(breakdown.CritChance, s_format("= %.2f%%", preHitCheckCritChance))
					end
					if env.mode_effective and output.HitChance < 100 then
						t_insert(breakdown.CritChance, "Crit confirmation roll:")
						t_insert(breakdown.CritChance, s_format("%.2f%%", preHitCheckCritChance))
						t_insert(breakdown.CritChance, s_format("x %.2f ^8(chance to hit)", output.HitChance / 100))
						t_insert(breakdown.CritChance, s_format("= %.2f%%", output.CritChance))
					end
				end
			end
			if skillModList:Flag(cfg, "NoCritMultiplier") then
				output.CritMultiplier = 1
			else
				local extraDamage = skillModList:Sum("BASE", cfg, "CritMultiplier") / 100
				local multiOverride = skillModList:Override(skillCfg, "CritMultiplier")
				if multiOverride then
					extraDamage = (multiOverride - 100) / 100
				end
				if env.mode_effective then
					local enemyInc = 1 + enemyDB:Sum("INC", nil, "SelfCritMultiplier") / 100
					extraDamage = round(extraDamage * enemyInc, 2)
					if breakdown and enemyInc ~= 1 then
						breakdown.CritMultiplier = {
							s_format("%d%% ^8(additional extra damage)", skillModList:Sum("BASE", cfg, "CritMultiplier") / 100),
							s_format("x %.2f ^8(increased/reduced extra crit damage taken by enemy)", enemyInc),
							s_format("= %d%% ^8(extra crit damage)", extraDamage * 100),
						}
					end
				end
				output.CritMultiplier = 1 + m_max(0, extraDamage)
			end
			output.CritEffect = 1 - output.CritChance / 100 + output.CritChance / 100 * output.CritMultiplier
			output.BonusCritDotMultiplier = (skillModList:Sum("BASE", cfg, "CritMultiplier") - 50) * skillModList:Sum("BASE", cfg, "CritMultiplierAppliesToDegen") / 10000
			if breakdown and output.CritEffect ~= 1 then
				breakdown.CritEffect = {
					s_format("(1 - %.4f) ^8(portion of damage from non-crits)", output.CritChance/100),
					s_format("+ (%.4f x %g) ^8(portion of damage from crits)", output.CritChance/100, output.CritMultiplier),
					s_format("= %.3f", output.CritEffect),
				}
			end
		end

		-- Calculate Double Damage + Ruthless Blow chance/multipliers
		output.DoubleDamageChance = m_min(skillModList:Sum("BASE", cfg, "DoubleDamageChance") + (env.mode_effective and enemyDB:Sum("BASE", cfg, "SelfDoubleDamageChance") or 0), 100)
		output.DoubleDamageEffect = 1 + output.DoubleDamageChance / 100
		output.RuthlessBlowMaxCount = skillModList:Sum("BASE", cfg, "RuthlessBlowMaxCount")
		if output.RuthlessBlowMaxCount > 0 then
			output.RuthlessBlowChance = round(100 / output.RuthlessBlowMaxCount)
		else
			output.RuthlessBlowChance = 0
		end
		output.RuthlessBlowMultiplier = 1 + skillModList:Sum("BASE", cfg, "RuthlessBlowMultiplier") / 100
		output.RuthlessBlowEffect = 1 - output.RuthlessBlowChance / 100 + output.RuthlessBlowChance / 100 * output.RuthlessBlowMultiplier

		-- Calculate base hit damage
		for _, damageType in ipairs(dmgTypeList) do
			local damageTypeMin = damageType.."Min"
			local damageTypeMax = damageType.."Max"
			local baseMultiplier = activeSkill.activeEffect.grantedEffectLevel.baseMultiplier or 1
			local damageEffectiveness = activeSkill.activeEffect.grantedEffectLevel.damageEffectiveness or skillData.damageEffectiveness or 1
			local addedMin = skillModList:Sum("BASE", cfg, damageTypeMin) + enemyDB:Sum("BASE", cfg, "Self"..damageTypeMin)
			local addedMax = skillModList:Sum("BASE", cfg, damageTypeMax) + enemyDB:Sum("BASE", cfg, "Self"..damageTypeMax)
			local baseMin = ((source[damageTypeMin] or 0) + (source[damageType.."BonusMin"] or 0)) * baseMultiplier + addedMin * damageEffectiveness
			local baseMax = ((source[damageTypeMax] or 0) + (source[damageType.."BonusMax"] or 0)) * baseMultiplier + addedMax * damageEffectiveness
			output[damageTypeMin.."Base"] = baseMin
			output[damageTypeMax.."Base"] = baseMax
			if breakdown then
				breakdown[damageType] = { damageTypes = { } }
				if baseMin ~= 0 and baseMax ~= 0 then
					t_insert(breakdown[damageType], "Base damage:")
					local plus = ""
					if (source[damageTypeMin] or 0) ~= 0 or (source[damageTypeMax] or 0) ~= 0 then
						if baseMultiplier ~= 1 then
							t_insert(breakdown[damageType], s_format("(%d to %d) x %.2f ^8(base damage from %s multiplied by base damage multiplier)", source[damageTypeMin], source[damageTypeMax], baseMultiplier, source.type and "weapon" or "skill"))
						else
							t_insert(breakdown[damageType], s_format("%d to %d ^8(base damage from %s)", source[damageTypeMin], source[damageTypeMax], source.type and "weapon" or "skill"))
						end
						plus = "+ "
					end
					if addedMin ~= 0 or addedMax ~= 0 then
						if damageEffectiveness ~= 1 then
							t_insert(breakdown[damageType], s_format("%s(%d to %d) x %.2f ^8(added damage multiplied by damage effectiveness)", plus, addedMin, addedMax, damageEffectiveness))
						else
							t_insert(breakdown[damageType], s_format("%s%d to %d ^8(added damage)", plus, addedMin, addedMax))
						end
					end
					t_insert(breakdown[damageType], s_format("= %.1f to %.1f", baseMin, baseMax))
				end
			end
		end

		-- Calculate hit damage for each damage type
		local totalHitMin, totalHitMax, totalHitAvg = 0, 0, 0
		local totalCritMin, totalCritMax, totalCritAvg = 0, 0, 0
		local ghostReaver = skillModList:Flag(nil, "GhostReaver")
		output.LifeLeech = 0
		output.LifeLeechInstant = 0
		output.EnergyShieldLeech = 0
		output.EnergyShieldLeechInstant = 0
		output.ManaLeech = 0
		output.ManaLeechInstant = 0
		for pass = 1, 2 do
			-- Pass 1 is critical strike damage, pass 2 is non-critical strike
			cfg.skillCond["CriticalStrike"] = (pass == 1)
			local lifeLeechTotal = 0
			local energyShieldLeechTotal = 0
			local manaLeechTotal = 0
			local noLifeLeech = skillModList:Flag(cfg, "CannotLeechLife") or enemyDB:Flag(nil, "CannotLeechLifeFromSelf")
			local noEnergyShieldLeech = skillModList:Flag(cfg, "CannotLeechEnergyShield") or enemyDB:Flag(nil, "CannotLeechEnergyShieldFromSelf")
			local noManaLeech = skillModList:Flag(cfg, "CannotLeechMana") or enemyDB:Flag(nil, "CannotLeechManaFromSelf")
			for _, damageType in ipairs(dmgTypeList) do
				local damageTypeHitMin, damageTypeHitMax, damageTypeHitAvg = 0, 0, 0
				if skillFlags.hit and canDeal[damageType] then
					damageTypeHitMin, damageTypeHitMax = calcDamage(activeSkill, output, cfg, pass == 2 and breakdown and breakdown[damageType], damageType, 0)
					local convMult = activeSkill.conversionTable[damageType].mult
					if pass == 2 and breakdown then
						t_insert(breakdown[damageType], "Hit damage:")
						t_insert(breakdown[damageType], s_format("%d to %d ^8(total damage)", damageTypeHitMin, damageTypeHitMax))
						if convMult ~= 1 then
							t_insert(breakdown[damageType], s_format("x %g ^8(%g%% converted to other damage types)", convMult, (1-convMult)*100))
						end
						if output.DoubleDamageEffect ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(chance to deal double damage)", output.DoubleDamageEffect))
						end
						if output.RuthlessBlowEffect ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(ruthless blow effect modifier)", output.RuthlessBlowEffect))
						end
					end
					local allMult = convMult * output.DoubleDamageEffect * output.RuthlessBlowEffect
					if pass == 1 then
						-- Apply crit multiplier
						allMult = allMult * output.CritMultiplier
					end				
					damageTypeHitMin = damageTypeHitMin * allMult
					damageTypeHitMax = damageTypeHitMax * allMult
					if (damageTypeHitMin ~= 0 or damageTypeHitMax ~= 0) and env.mode_effective then
						-- Apply enemy resistances and damage taken modifiers
						local resist = 0
						local pen = 0
						local takenInc = enemyDB:Sum("INC", cfg, "DamageTaken", damageType.."DamageTaken")
						local takenMore = enemyDB:More(cfg, "DamageTaken", damageType.."DamageTaken")
						if damageType == "Physical" then
							resist = m_max(0, enemyDB:Sum("BASE", nil, "PhysicalDamageReduction") + skillModList:Sum("BASE", cfg, "EnemyPhysicalDamageReduction"))
						else
							resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
							if isElemental[damageType] then
								resist = resist + enemyDB:Sum("BASE", nil, "ElementalResist")
								pen = skillModList:Sum("BASE", cfg, damageType.."Penetration", "ElementalPenetration")
								takenInc = takenInc + enemyDB:Sum("INC", nil, "ElementalDamageTaken")
							elseif damageType == "Chaos" then
								pen = skillModList:Sum("BASE", cfg, "ChaosPenetration")
							end
							resist = m_min(resist, 75)
						end
						if skillFlags.projectile then
							takenInc = takenInc + enemyDB:Sum("INC", nil, "ProjectileDamageTaken")
						end
						if skillFlags.projectile and skillFlags.attack then
							takenInc = takenInc + enemyDB:Sum("INC", nil, "ProjectileAttackDamageTaken")
						end
						if skillFlags.trap or skillFlags.mine then
							takenInc = takenInc + enemyDB:Sum("INC", nil, "TrapMineDamageTaken")
						end
						local effMult = (1 + takenInc / 100) * takenMore
						if not skillModList:Flag(cfg, "Ignore"..damageType.."Resistance", isElemental[damageType] and "IgnoreElementalResistances" or nil) and not enemyDB:Flag(nil, "SelfIgnore"..damageType.."Resistance") then
							effMult = effMult * (1 - (resist - pen) / 100)
						end
						damageTypeHitMin = damageTypeHitMin * effMult
						damageTypeHitMax = damageTypeHitMax * effMult
						if env.mode == "CALCS" then
							output[damageType.."EffMult"] = effMult
						end
						if pass == 2 and breakdown and effMult ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.3f ^8(effective DPS modifier)", effMult))
							breakdown[damageType.."EffMult"] = breakdown.effMult(damageType, resist, pen, takenInc, effMult, takenMore)
						end
					end
					if pass == 2 and breakdown then
						t_insert(breakdown[damageType], s_format("= %d to %d", damageTypeHitMin, damageTypeHitMax))
					end
					if skillModList:Flag(skillCfg, "LuckyHits") then 
						damageTypeHitAvg = (damageTypeHitMin / 3 + 2 * damageTypeHitMax / 3)
					else
						damageTypeHitAvg = (damageTypeHitMin / 2 + damageTypeHitMax / 2)
					end
					
					--Beginning of Leech Calculation for this DamageType
					if skillFlags.mine or skillFlags.trap or skillFlags.totem then
						if not noLifeLeech then
							local lifeLeech = skillModList:Sum("BASE", cfg, "DamageLifeLeechToPlayer")
							if lifeLeech > 0 then
								lifeLeechTotal = lifeLeechTotal + damageTypeHitAvg * lifeLeech / 100
							end
						end
					else
						if not noLifeLeech then				
							local lifeLeech
							if skillModList:Flag(nil, "LifeLeechBasedOnChaosDamage") then
								if damageType == "Chaos" then
									lifeLeech = skillModList:Sum("BASE", cfg, "DamageLeech", "DamageLifeLeech", "PhysicalDamageLifeLeech", "LightningDamageLifeLeech", "ColdDamageLifeLeech", "FireDamageLifeLeech", "ChaosDamageLifeLeech", "ElementalDamageLifeLeech") + enemyDB:Sum("BASE", cfg, "SelfDamageLifeLeech") / 100
								else
									lifeLeech = 0
								end
							else
								lifeLeech = skillModList:Sum("BASE", cfg, "DamageLeech", "DamageLifeLeech", damageType.."DamageLifeLeech", isElemental[damageType] and "ElementalDamageLifeLeech" or nil) + enemyDB:Sum("BASE", cfg, "SelfDamageLifeLeech") / 100
							end
							if lifeLeech > 0 then
								lifeLeechTotal = lifeLeechTotal + damageTypeHitAvg * lifeLeech / 100
							end
						end
						if not noEnergyShieldLeech then
							local energyShieldLeech = skillModList:Sum("BASE", cfg, "DamageEnergyShieldLeech", damageType.."DamageEnergyShieldLeech", isElemental[damageType] and "ElementalDamageEnergyShieldLeech" or nil) + enemyDB:Sum("BASE", cfg, "SelfDamageEnergyShieldLeech") / 100
							if energyShieldLeech > 0 then
								energyShieldLeechTotal = energyShieldLeechTotal + damageTypeHitAvg * energyShieldLeech / 100
							end
						end
						if not noManaLeech then
							local manaLeech = skillModList:Sum("BASE", cfg, "DamageLeech", "DamageManaLeech", damageType.."DamageManaLeech", isElemental[damageType] and "ElementalDamageManaLeech" or nil) + enemyDB:Sum("BASE", cfg, "SelfDamageManaLeech") / 100
							if manaLeech > 0 then
								manaLeechTotal = manaLeechTotal + damageTypeHitAvg * manaLeech / 100
							end
						end
					end
				else
					if breakdown then
						breakdown[damageType] = {
							"You can't deal "..damageType.." damage"
						}
					end
				end
				if pass == 1 then
					output[damageType.."CritAverage"] = damageTypeHitAvg
					totalCritAvg = totalCritAvg + damageTypeHitAvg
					totalCritMin = totalCritMin + damageTypeHitMin
					totalCritMax = totalCritMax + damageTypeHitMax
				else
					if env.mode == "CALCS" then
						output[damageType.."Min"] = damageTypeHitMin
						output[damageType.."Max"] = damageTypeHitMax
					end
					output[damageType.."HitAverage"] = damageTypeHitAvg
					totalHitAvg = totalHitAvg + damageTypeHitAvg
					totalHitMin = totalHitMin + damageTypeHitMin
					totalHitMax = totalHitMax + damageTypeHitMax
				end
			end
			if skillData.lifeLeechPerUse then
				lifeLeechTotal = lifeLeechTotal + skillData.lifeLeechPerUse
			end
			if skillData.manaLeechPerUse then
				manaLeechTotal = manaLeechTotal + skillData.manaLeechPerUse
			end
			local portion = (pass == 1) and (output.CritChance / 100) or (1 - output.CritChance / 100)
			if skillModList:Flag(cfg, "InstantLifeLeech") and not ghostReaver then
				output.LifeLeechInstant = output.LifeLeechInstant + lifeLeechTotal * portion
			else
				output.LifeLeech = output.LifeLeech + lifeLeechTotal * portion
			end
			if skillModList:Flag(cfg, "InstantEnergyShieldLeech") then
				output.EnergyShieldLeechInstant = output.EnergyShieldLeechInstant + energyShieldLeechTotal * portion
			else
				output.EnergyShieldLeech = output.EnergyShieldLeech + energyShieldLeechTotal * portion
			end
			if skillModList:Flag(cfg, "InstantManaLeech") then
				output.ManaLeechInstant = output.ManaLeechInstant + manaLeechTotal * portion
			else
				output.ManaLeech = output.ManaLeech + manaLeechTotal * portion
			end
		end
		output.TotalMin = totalHitMin
		output.TotalMax = totalHitMax

		if skillModList:Flag(skillCfg, "ElementalEquilibrium") and not env.configInput.EEIgnoreHitDamage and (output.FireHitAverage + output.ColdHitAverage + output.LightningHitAverage > 0) then
			-- Update enemy hit-by-damage-type conditions
			enemyDB.conditions.HitByFireDamage = output.FireHitAverage > 0
			enemyDB.conditions.HitByColdDamage = output.ColdHitAverage > 0
			enemyDB.conditions.HitByLightningDamage = output.LightningHitAverage > 0
		end

		if breakdown then
			-- For each damage type, calculate percentage of total damage
			for _, damageType in ipairs(dmgTypeList) do
				if output[damageType.."HitAverage"] > 0 then
					t_insert(breakdown[damageType], s_format("Portion of total damage: %d%%", output[damageType.."HitAverage"] / (totalHitMin + totalHitMax) * 200))
				end
			end
		end

		local hitRate = output.HitChance / 100 * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)

		-- Calculate leech
		local function getLeechInstances(amount, total)
			if total == 0 then
				return 0, 0
			end
			local duration = amount / total / 0.02
			return duration, duration * hitRate
		end
		if ghostReaver then
			output.EnergyShieldLeech = output.EnergyShieldLeech + output.LifeLeech
			output.EnergyShieldLeechInstant = output.EnergyShieldLeechInstant + output.LifeLeechInstant
			output.LifeLeech = 0
			output.LifeLeechInstant = 0
		end
		output.LifeLeech = m_min(output.LifeLeech, globalOutput.MaxLifeLeechInstance)
		output.LifeLeechDuration, output.LifeLeechInstances = getLeechInstances(output.LifeLeech, globalOutput.Life)
		output.LifeLeechInstantRate = output.LifeLeechInstant * hitRate
		output.EnergyShieldLeech = m_min(output.EnergyShieldLeech, globalOutput.MaxEnergyShieldLeechInstance)
		output.EnergyShieldLeechDuration, output.EnergyShieldLeechInstances = getLeechInstances(output.EnergyShieldLeech, globalOutput.EnergyShield)
		output.EnergyShieldLeechInstantRate = output.EnergyShieldLeechInstant * hitRate
		output.ManaLeech = m_min(output.ManaLeech, globalOutput.MaxManaLeechInstance)
		output.ManaLeechDuration, output.ManaLeechInstances = getLeechInstances(output.ManaLeech, globalOutput.Mana)
		output.ManaLeechInstantRate = output.ManaLeechInstant * hitRate

		-- Calculate gain on hit
		if skillFlags.mine or skillFlags.trap or skillFlags.totem then
			output.LifeOnHit = 0
			output.EnergyShieldOnHit = 0
			output.ManaOnHit = 0
		else
			output.LifeOnHit = (skillModList:Sum("BASE", cfg, "LifeOnHit") + enemyDB:Sum("BASE", cfg, "SelfLifeOnHit")) * globalOutput.LifeRecoveryMod
			output.EnergyShieldOnHit = (skillModList:Sum("BASE", cfg, "EnergyShieldOnHit") + enemyDB:Sum("BASE", cfg, "SelfEnergyShieldOnHit")) * globalOutput.EnergyShieldRecoveryMod
			output.ManaOnHit = (skillModList:Sum("BASE", cfg, "ManaOnHit") + enemyDB:Sum("BASE", cfg, "SelfManaOnHit")) * globalOutput.ManaRecoveryMod
		end
		output.LifeOnHitRate = output.LifeOnHit * hitRate
		output.EnergyShieldOnHitRate = output.EnergyShieldOnHit * hitRate
		output.ManaOnHitRate = output.ManaOnHit * hitRate

		-- Calculate average damage and final DPS
		output.AverageHit = totalHitAvg * (1 - output.CritChance / 100) + totalCritAvg * output.CritChance / 100
		output.AverageDamage = output.AverageHit * output.HitChance / 100
		output.TotalDPS = output.AverageDamage * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)
		if breakdown then
			if output.CritEffect ~= 1 then
				breakdown.AverageHit = { }
				if skillModList:Flag(skillCfg, "LuckyHits") then 
					t_insert(breakdown.AverageHit, s_format("(1/3) x %d + (2/3) x %d = %.1f ^8(average from non-crits)", totalHitMin, totalHitMax, totalHitAvg))
					t_insert(breakdown.AverageHit, s_format("(1/3) x %d + (2/3) x %d = %.1f ^8(average from crits)", totalCritMin, totalCritMax, totalCritAvg))
					t_insert(breakdown.AverageHit, "")
				end
				t_insert(breakdown.AverageHit, s_format("%.1f x (1 - %.4f) ^8(damage from non-crits)", totalHitAvg, output.CritChance / 100))
				t_insert(breakdown.AverageHit, s_format("+ %.1f x %.4f ^8(damage from crits)", totalCritAvg, output.CritChance / 100))
				t_insert(breakdown.AverageHit, s_format("= %.1f", output.AverageHit))
			end
			if isAttack then
				breakdown.AverageDamage = { }
				t_insert(breakdown.AverageDamage, s_format("%s:", pass.label))
				t_insert(breakdown.AverageDamage, s_format("%.1f ^8(average hit)", output.AverageHit))
				t_insert(breakdown.AverageDamage, s_format("x %.2f ^8(chance to hit)", output.HitChance / 100))
				t_insert(breakdown.AverageDamage, s_format("= %.1f", output.AverageDamage))
			end
		end
	end

	if isAttack then
		-- Combine crit stats, average damage and DPS
		combineStat("PreEffectiveCritChance", "AVERAGE")
		combineStat("CritChance", "AVERAGE")
		combineStat("CritMultiplier", "AVERAGE")
		combineStat("AverageDamage", "DPS")
		combineStat("TotalDPS", "DPS")
		combineStat("LifeLeechDuration", "DPS")
		combineStat("LifeLeechInstances", "DPS")
		combineStat("LifeLeechInstant", "DPS")
		combineStat("LifeLeechInstantRate", "DPS")
		combineStat("EnergyShieldLeechDuration", "DPS")
		combineStat("EnergyShieldLeechInstances", "DPS")
		combineStat("EnergyShieldLeechInstant", "DPS")
		combineStat("EnergyShieldLeechInstantRate", "DPS")
		combineStat("ManaLeechDuration", "DPS")
		combineStat("ManaLeechInstances", "DPS")
		combineStat("ManaLeechInstant", "DPS")
		combineStat("ManaLeechInstantRate", "DPS")
		combineStat("LifeOnHit", "DPS")
		combineStat("LifeOnHitRate", "DPS")
		combineStat("EnergyShieldOnHit", "DPS")
		combineStat("EnergyShieldOnHitRate", "DPS")
		combineStat("ManaOnHit", "DPS")
		combineStat("ManaOnHitRate", "DPS")
		if skillFlags.bothWeaponAttack then
			if breakdown then
				breakdown.AverageDamage = { }
				t_insert(breakdown.AverageDamage, "Both weapons:")
				if skillData.doubleHitsWhenDualWielding then
					t_insert(breakdown.AverageDamage, s_format("%.1f + %.1f ^8(skill hits with both weapons at once)", output.MainHand.AverageDamage, output.OffHand.AverageDamage))
				else
					t_insert(breakdown.AverageDamage, s_format("(%.1f + %.1f) / 2 ^8(skill alternates weapons)", output.MainHand.AverageDamage, output.OffHand.AverageDamage))
				end
				t_insert(breakdown.AverageDamage, s_format("= %.1f", output.AverageDamage))
			end
		end
	end
	if env.mode == "CALCS" then
		if skillData.showAverage then
			output.DisplayDamage = s_format("%.1f average damage", output.AverageDamage)
		else
			output.DisplayDamage = s_format("%.1f DPS", output.TotalDPS)
		end
	end
	if breakdown then
		if isAttack then
			breakdown.TotalDPS = {
				s_format("%.1f ^8(average damage)", output.AverageDamage),
				output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(attack rate)", output.Speed),
			}
		else
			breakdown.TotalDPS = {
				s_format("%.1f ^8(average hit)", output.AverageDamage),
				output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(cast rate)", output.Speed),
			}
		end
		if skillData.dpsMultiplier then
			t_insert(breakdown.TotalDPS, s_format("x %g ^8(DPS multiplier for this skill)", skillData.dpsMultiplier))
		end
		t_insert(breakdown.TotalDPS, s_format("= %.1f", output.TotalDPS))
	end

	-- Calculate leech rates
	output.LifeLeechInstanceRate = output.Life * 0.02 * calcLib.mod(skillModList, skillCfg, "LifeLeechRate")
	output.LifeLeechRate = output.LifeLeechInstantRate * output.LifeRecoveryMod + m_min(output.LifeLeechInstances * output.LifeLeechInstanceRate, output.MaxLifeLeechRate) * output.LifeRecoveryRateMod
	output.LifeLeechPerHit = output.LifeLeechInstant * output.LifeRecoveryMod + m_min(output.LifeLeechInstanceRate, output.MaxLifeLeechRate) * output.LifeLeechDuration * output.LifeRecoveryRateMod
	output.EnergyShieldLeechInstanceRate = output.EnergyShield * 0.02 * calcLib.mod(skillModList, skillCfg, "EnergyShieldLeechRate")
	output.EnergyShieldLeechRate = output.EnergyShieldLeechInstantRate * output.EnergyShieldRecoveryMod + m_min(output.EnergyShieldLeechInstances * output.EnergyShieldLeechInstanceRate, output.MaxEnergyShieldLeechRate) * output.EnergyShieldRecoveryRateMod
	output.EnergyShieldLeechPerHit = output.EnergyShieldLeechInstant * output.EnergyShieldRecoveryMod + m_min(output.EnergyShieldLeechInstanceRate, output.MaxEnergyShieldLeechRate) * output.EnergyShieldLeechDuration * output.EnergyShieldRecoveryRateMod
	output.ManaLeechInstanceRate = output.Mana * 0.02 * calcLib.mod(skillModList, skillCfg, "ManaLeechRate")
	output.ManaLeechRate = output.ManaLeechInstantRate * output.ManaRecoveryMod + m_min(output.ManaLeechInstances * output.ManaLeechInstanceRate, output.MaxManaLeechRate) * output.ManaRecoveryRateMod
	output.ManaLeechPerHit = output.ManaLeechInstant * output.ManaRecoveryMod  + m_min(output.ManaLeechInstanceRate, output.MaxManaLeechRate) * output.ManaLeechDuration * output.ManaRecoveryRateMod
	skillFlags.leechLife = output.LifeLeechRate > 0
	skillFlags.leechES = output.EnergyShieldLeechRate > 0
	skillFlags.leechMana = output.ManaLeechRate > 0
	if skillData.showAverage then
		output.LifeLeechGainPerHit = output.LifeLeechPerHit + output.LifeOnHit
		output.EnergyShieldLeechGainPerHit = output.EnergyShieldLeechPerHit + output.EnergyShieldOnHit
		output.ManaLeechGainPerHit = output.ManaLeechPerHit + output.ManaOnHit
	else
		output.LifeLeechGainRate = output.LifeLeechRate + output.LifeOnHitRate
		output.EnergyShieldLeechGainRate = output.EnergyShieldLeechRate + output.EnergyShieldOnHitRate
		output.ManaLeechGainRate = output.ManaLeechRate + output.ManaOnHitRate
	end
	if breakdown then
		if skillFlags.leechLife then
			breakdown.LifeLeech = breakdown.leech(output.LifeLeechInstant, output.LifeLeechInstantRate, output.LifeLeechInstances, output.Life, "LifeLeechRate", output.MaxLifeLeechRate, output.LifeLeechDuration)
		end
		if skillFlags.leechES then
			breakdown.EnergyShieldLeech = breakdown.leech(output.EnergyShieldLeechInstant, output.EnergyShieldLeechInstantRate, output.EnergyShieldLeechInstances, output.EnergyShield, "EnergyShieldLeechRate", output.MaxEnergyShieldLeechRate, output.EnergyShieldLeechDuration)
		end
		if skillFlags.leechMana then
			breakdown.ManaLeech = breakdown.leech(output.ManaLeechInstant, output.ManaLeechInstantRate, output.ManaLeechInstances, output.Mana, "ManaLeechRate", output.MaxManaLeechRate, output.ManaLeechDuration)
		end
	end

	-- Calculate skill DOT components
	local dotCfg = {
		skillName = skillCfg.skillName,
		skillPart = skillCfg.skillPart,
		skillTypes = skillCfg.skillTypes,
		slotName = skillCfg.slotName,
		flags = bor(ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0, skillData.dotIsArea and ModFlag.Area or 0, skillData.dotIsProjectile and ModFlag.Projectile or 0),
		keywordFlags = band(skillCfg.keywordFlags, bnot(KeywordFlag.Hit)),
	}
	activeSkill.dotCfg = dotCfg
	output.TotalDot = 0
	for _, damageType in ipairs(dmgTypeList) do
		local dotTypeCfg = copyTable(dotCfg, true)
		dotTypeCfg.keywordFlags = bor(dotTypeCfg.keywordFlags, KeywordFlag[damageType.."Dot"])
		activeSkill["dot"..damageType.."Cfg"] = dotTypeCfg
		local baseVal 
		if canDeal[damageType] then
			baseVal = skillData[damageType.."Dot"] or 0
		else
			baseVal = 0
		end
		if baseVal > 0 then
			skillFlags.dot = true
			local effMult = 1
			if env.mode_effective then
				local resist = 0
				local takenInc = enemyDB:Sum("INC", dotTypeCfg, "DamageTaken", "DamageTakenOverTime", damageType.."DamageTaken", damageType.."DamageTakenOverTime")
				local takenMore = enemyDB:More(dotTypeCfg, "DamageTaken", "DamageTakenOverTime", damageType.."DamageTaken", damageType.."DamageTakenOverTime")
				if damageType == "Physical" then
					resist = enemyDB:Sum("BASE", nil, "PhysicalDamageReduction")
				else
					resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
					if isElemental[damageType] then
						resist = resist + enemyDB:Sum("BASE", dotTypeCfg, "ElementalResist")
						takenInc = takenInc + enemyDB:Sum("INC", dotTypeCfg, "ElementalDamageTaken")
					end
					resist = m_min(resist, 75)
				end
				effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
				output[damageType.."DotEffMult"] = effMult
				if breakdown and effMult ~= 1 then
					breakdown[damageType.."DotEffMult"] = breakdown.effMult(damageType, resist, 0, takenInc, effMult, takenMore)
				end
			end
			local inc = skillModList:Sum("INC", dotTypeCfg, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil)
			local more = round(skillModList:More(dotTypeCfg, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil), 2)
			local mult = skillModList:Sum("BASE", dotTypeCfg, "DotMultiplier", damageType.."DotMultiplier")
			local total = baseVal * (1 + inc/100) * more * (1 + mult/100) * effMult
			if activeSkill.skillTypes[SkillType.Aura] then
				total = total * calcLib.mod(skillModList, dotTypeCfg, "AuraEffect")
			end
			output[damageType.."Dot"] = total
			output.TotalDot = output.TotalDot + total
			if breakdown then
				breakdown[damageType.."Dot"] = { }
				breakdown.dot(breakdown[damageType.."Dot"], baseVal, inc, more, mult, nil, effMult, total)
			end
		end
	end

	skillFlags.bleed = false
	skillFlags.poison = false
	skillFlags.ignite = false
	skillFlags.igniteCanStack = skillModList:Flag(skillCfg, "IgniteCanStack")
	skillFlags.shock = false
	skillFlags.freeze = false
	skillFlags.impale = false
	skillFlags.chill = false
	for _, pass in ipairs(passList) do
		local globalOutput, globalBreakdown = output, breakdown
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown

		-- Calculate chance to inflict secondary dots/status effects
		cfg.skillCond["CriticalStrike"] = true
		if not skillFlags.attack or skillModList:Flag(cfg, "CannotBleed") then
			output.BleedChanceOnCrit = 0
		else
			output.BleedChanceOnCrit = m_min(100, skillModList:Sum("BASE", cfg, "BleedChance") + enemyDB:Sum("BASE", nil, "SelfBleedChance"))
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotPoison") then
			output.PoisonChanceOnCrit = 0
		else
			output.PoisonChanceOnCrit = m_min(100, skillModList:Sum("BASE", cfg, "PoisonChance") + enemyDB:Sum("BASE", nil, "SelfPoisonChance"))
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotIgnite") then
			output.IgniteChanceOnCrit = 0
		else
			output.IgniteChanceOnCrit = 100
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotShock") then
			output.ShockChanceOnCrit = 0
		else
			output.ShockChanceOnCrit = 100
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotFreeze") then
			output.FreezeChanceOnCrit = 0
		else
			output.FreezeChanceOnCrit = 100
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotChill") then
			output.ChillChanceOnCrit = 0
		else
			output.ChillChanceOnCrit = 100
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotKnockback") then
			output.KnockbackChanceOnCrit = 0
		else
			output.KnockbackChanceOnCrit = skillModList:Sum("BASE", cfg, "EnemyKnockbackChance")
		end
		cfg.skillCond["CriticalStrike"] = false
		if not skillFlags.attack or skillModList:Flag(cfg, "CannotBleed") then
			output.BleedChanceOnHit = 0
		else
			output.BleedChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "BleedChance") + enemyDB:Sum("BASE", nil, "SelfBleedChance"))
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotPoison") then
			output.PoisonChanceOnHit = 0
			output.ChaosPoisonChance = 0
		else
			output.PoisonChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "PoisonChance") + enemyDB:Sum("BASE", nil, "SelfPoisonChance"))
			output.ChaosPoisonChance = m_min(100, skillModList:Sum("BASE", cfg, "ChaosPoisonChance"))
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotIgnite") then
			output.IgniteChanceOnHit = 0
		else
			output.IgniteChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "EnemyIgniteChance") + enemyDB:Sum("BASE", nil, "SelfIgniteChance"))
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotShock") then
			output.ShockChanceOnHit = 0
		else
			output.ShockChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "EnemyShockChance") + enemyDB:Sum("BASE", nil, "SelfShockChance"))
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotFreeze") then
			output.FreezeChanceOnHit = 0
		else
			output.FreezeChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "EnemyFreezeChance") + enemyDB:Sum("BASE", nil, "SelfFreezeChance"))
			if skillModList:Flag(cfg, "CritsDontAlwaysFreeze") then
				output.FreezeChanceOnCrit = output.FreezeChanceOnHit
			end
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotChill") then
			output.ChillChanceOnHit = 0
		else
			output.ChillChanceOnHit = 100
		end
		if not skillFlags.hit or skillModList:Flag(cfg, "CannotKnockback") then
			output.KnockbackChanceOnHit = 0
		else
			output.KnockbackChanceOnHit = skillModList:Sum("BASE", cfg, "EnemyKnockbackChance")
		end
		if not skillFlags.attack then
            output.ImpaleChance = 0
        else
            output.ImpaleChance = m_min(100, skillModList:Sum("BASE", cfg, "ImpaleChance"))
        end
		if env.mode_effective then
			local bleedMult = (1 - enemyDB:Sum("BASE", nil, "AvoidBleed") / 100)
			output.BleedChanceOnHit = output.BleedChanceOnHit * bleedMult
			output.BleedChanceOnCrit = output.BleedChanceOnCrit * bleedMult
			local poisonMult = (1 - enemyDB:Sum("BASE", nil, "AvoidPoison") / 100)
			output.PoisonChanceOnHit = output.PoisonChanceOnHit * poisonMult
			output.PoisonChanceOnCrit = output.PoisonChanceOnCrit * poisonMult
			output.ChaosPoisonChance = output.ChaosPoisonChance * poisonMult
			local igniteMult = (1 - enemyDB:Sum("BASE", nil, "AvoidIgnite") / 100)
			output.IgniteChanceOnHit = output.IgniteChanceOnHit * igniteMult
			output.IgniteChanceOnCrit = output.IgniteChanceOnCrit * igniteMult
			local shockMult = (1 - enemyDB:Sum("BASE", nil, "AvoidShock") / 100)
			output.ShockChanceOnHit = output.ShockChanceOnHit * shockMult
			output.ShockChanceOnCrit = output.ShockChanceOnCrit * shockMult
			local freezeMult = (1 - enemyDB:Sum("BASE", nil, "AvoidFreeze") / 100)
			output.FreezeChanceOnHit = output.FreezeChanceOnHit * freezeMult
			output.FreezeChanceOnCrit = output.FreezeChanceOnCrit * freezeMult
			output.ChillChanceOnHit = 100
			output.ChillChanceOnCrit = 100
		end
	
		local function calcAilmentDamage(type, sourceHitDmg, sourceCritDmg)
			-- Calculate the inflict chance and base damage of a secondary effect (bleed/poison/ignite/shock/freeze)
			local chanceOnHit, chanceOnCrit = output[type.."ChanceOnHit"], output[type.."ChanceOnCrit"]
			local chanceFromHit = chanceOnHit * (1 - output.CritChance / 100)
			local chanceFromCrit = chanceOnCrit * output.CritChance / 100
			local chance = chanceFromHit + chanceFromCrit
			output[type.."Chance"] = chance
			local baseFromHit = sourceHitDmg * chanceFromHit / (chanceFromHit + chanceFromCrit)
			local baseFromCrit = sourceCritDmg * chanceFromCrit / (chanceFromHit + chanceFromCrit)
			local baseVal = baseFromHit + baseFromCrit
			if breakdown and chance ~= 0 then
				local breakdownChance = breakdown[type.."Chance"] or { }
				breakdown[type.."Chance"] = breakdownChance
				if breakdownChance[1] then
					t_insert(breakdownChance, "")
				end
				if isAttack then
					t_insert(breakdownChance, pass.label..":")
				end
				t_insert(breakdownChance, s_format("Chance on Non-crit: %d%%", chanceOnHit))
				t_insert(breakdownChance, s_format("Chance on Crit: %d%%", chanceOnCrit))
				if chanceOnHit ~= chanceOnCrit then
					t_insert(breakdownChance, "Combined chance:")
					t_insert(breakdownChance, s_format("%d x (1 - %.4f) ^8(chance from non-crits)", chanceOnHit, output.CritChance/100))
					t_insert(breakdownChance, s_format("+ %d x %.4f ^8(chance from crits)", chanceOnCrit, output.CritChance/100))
					t_insert(breakdownChance, s_format("= %.2f", chance))
				end
			end
			if breakdown and baseVal > 0 then
				local breakdownDPS = breakdown[type.."DPS"] or { }
				breakdown[type.."DPS"] = breakdownDPS
				if breakdownDPS[1] then
					t_insert(breakdownDPS, "")
				end
				if isAttack then
					t_insert(breakdownDPS, pass.label..":")
				end
				if sourceHitDmg == sourceCritDmg then
					t_insert(breakdownDPS, "Total damage:")
					t_insert(breakdownDPS, s_format("%.1f ^8(source damage)",sourceHitDmg))
				else
					if baseFromHit > 0 then
						t_insert(breakdownDPS, "Damage from Non-crits:")
						t_insert(breakdownDPS, s_format("%.1f ^8(source damage from non-crits)", sourceHitDmg))
						t_insert(breakdownDPS, s_format("x %.3f ^8(portion of instances created by non-crits)", chanceFromHit / (chanceFromHit + chanceFromCrit)))
						t_insert(breakdownDPS, s_format("= %.1f", baseFromHit))
					end
					if baseFromCrit > 0 then
						t_insert(breakdownDPS, "Damage from Crits:")
						t_insert(breakdownDPS, s_format("%.1f ^8(source damage from crits)", sourceCritDmg))
						t_insert(breakdownDPS, s_format("x %.3f ^8(portion of instances created by crits)", chanceFromCrit / (chanceFromHit + chanceFromCrit)))
						t_insert(breakdownDPS, s_format("= %.1f", baseFromCrit))
					end
					if baseFromHit > 0 and baseFromCrit > 0 then
						t_insert(breakdownDPS, "Total damage:")
						t_insert(breakdownDPS, s_format("%.1f + %.1f", baseFromHit, baseFromCrit))
						t_insert(breakdownDPS, s_format("= %.1f", baseVal))
					end
				end
			end
			return baseVal
		end

		-- Calculate bleeding chance and damage
		if canDeal.Physical and (output.BleedChanceOnHit + output.BleedChanceOnCrit) > 0 then
			if not activeSkill.bleedCfg then
				activeSkill.bleedCfg = {
					skillName = skillCfg.skillName,
					skillPart = skillCfg.skillPart,
					skillTypes = skillCfg.skillTypes,
					slotName = skillCfg.slotName,
					flags = bor(ModFlag.Dot, ModFlag.Ailment, band(skillCfg.flags, ModFlag.Melee) ~= 0 and ModFlag.MeleeHit or 0),
					keywordFlags = bor(band(skillCfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.Bleed, KeywordFlag.Ailment, KeywordFlag.PhysicalDot),
					skillCond = { },
				}
			end
			local dotCfg = activeSkill.bleedCfg
			local sourceHitDmg, sourceCritDmg
			if breakdown then
				breakdown.BleedPhysical = { damageTypes = { } }
			end
			for pass = 1, 2 do
				if not skillModList:Flag(dotCfg, "AilmentsAreNeverFromCrit") then
					dotCfg.skillCond["CriticalStrike"] = (pass == 1)
				end
				local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.BleedPhysical, "Physical", 0)
				output.BleedPhysicalMin = min
				output.BleedPhysicalMax = max
				if pass == 1 then
					sourceCritDmg = (min + max) / 2 * (1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "PhysicalDotMultiplier") / 100 + output.BonusCritDotMultiplier)
				else
					sourceHitDmg = (min + max) / 2 * (1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "PhysicalDotMultiplier") / 100)
				end
			end
			local basePercent = skillData.bleedBasePercent or 70
			local baseVal = calcAilmentDamage("Bleed", sourceHitDmg, sourceCritDmg) * basePercent / 100 * output.RuthlessBlowEffect
			if baseVal > 0 then
				skillFlags.bleed = true
				skillFlags.duration = true
				local effMult = 1
				if env.mode_effective then
					local resist = enemyDB:Sum("BASE", nil, "PhysicalDamageReduction")
					local takenInc = enemyDB:Sum("INC", dotCfg, "DamageTaken", "DamageTakenOverTime", "PhysicalDamageTaken", "PhysicalDamageTakenOverTime")
					local takenMore = enemyDB:More(dotCfg, "DamageTaken", "DamageTakenOverTime", "PhysicalDamageTaken", "PhysicalDamageTakenOverTime")
					effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
					globalOutput["BleedEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.BleedEffMult = breakdown.effMult("Physical", resist, 0, takenInc, effMult, takenMore)
					end
				end
				local mult = skillModList:Sum("BASE", dotCfg, "PhysicalDotMultiplier", "BleedMultiplier")
				local effectMod = calcLib.mod(skillModList, dotCfg, "AilmentEffect")
				local rateMod = calcLib.mod(skillModList, cfg, "BleedFaster")
				local maxStacks = skillModList:Override(cfg, "BleedStacksMax") or skillModList:Sum("BASE", cfg, "BleedStacksMax")
				local configStacks = enemyDB:Sum("BASE", nil, "Multiplier:BleedStacks")
				local bleedStacks = configStacks > 0 and m_min(configStacks, maxStacks) or maxStacks
				output.BleedDPS = (baseVal * effectMod * rateMod * effMult) * bleedStacks
				local durationBase
				if skillData.bleedDurationIsSkillDuration then
					durationBase = skillData.duration
				else
					durationBase = 5
				end
				local durationMod = calcLib.mod(skillModList, dotCfg, "EnemyBleedDuration", "SkillAndDamagingAilmentDuration", skillData.bleedIsSkillEffect and "Duration" or nil) * calcLib.mod(enemyDB, nil, "SelfBleedDuration")
				globalOutput.BleedDuration = durationBase * durationMod / rateMod * debuffDurationMult
				globalOutput.BleedStacksMax = maxStacks
				globalOutput.BleedStacks = bleedStacks
				if breakdown then
					t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(bleed deals %d%% per second)", basePercent/100, basePercent))
					if effectMod ~= 1 then
						t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(ailment effect modifier)", effectMod))
					end
					if output.RuthlessBlowEffect ~= 0 then
						t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(ruthless blow effect modifier)", output.RuthlessBlowEffect))
					end
					t_insert(breakdown.BleedDPS, s_format("= %.1f", baseVal))
					breakdown.multiChain(breakdown.BleedDPS, {
						label = "Bleed DPS:",
						base = s_format("%.1f ^8(total damage per second)", baseVal), 
						{ "%.2f ^8(ailment effect modifier)", effectMod },
						{ "%.2f ^8(damage rate modifier)", rateMod },
						{ "%.3f ^8(effective DPS modifier)", effMult },
						total = s_format("= %.1f ^8per second", output.BleedDPS),
					})
					if globalOutput.BleedDuration ~= durationBase then
						globalBreakdown.BleedDuration = {
							s_format("%.2fs ^8(base duration)", durationBase)
						}
						if durationMod ~= 1 then
							t_insert(globalBreakdown.BleedDuration, s_format("x %.2f ^8(duration modifier)", durationMod))
						end
						if rateMod ~= 1 then
							t_insert(globalBreakdown.BleedDuration, s_format("/ %.2f ^8(damage rate modifier)", rateMod))
						end
						if debuffDurationMult ~= 1 then
							t_insert(globalBreakdown.BleedDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
						end
						t_insert(globalBreakdown.BleedDuration, s_format("= %.2fs", globalOutput.BleedDuration))
					end
				end
			end
		end

		-- Calculate poison chance and damage
		if canDeal.Chaos and (output.PoisonChanceOnHit + output.PoisonChanceOnCrit + output.ChaosPoisonChance) > 0 then
			if not activeSkill.poisonCfg then
				activeSkill.poisonCfg = {
					skillName = skillCfg.skillName,
					skillPart = skillCfg.skillPart,
					skillTypes = skillCfg.skillTypes,
					slotName = skillCfg.slotName,
					flags = bor(ModFlag.Dot, ModFlag.Ailment, band(skillCfg.flags, ModFlag.Melee) ~= 0 and ModFlag.MeleeHit or 0),
					keywordFlags = bor(band(skillCfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.Poison, KeywordFlag.Ailment, KeywordFlag.ChaosDot),
					skillCond = { },
				}
			end
			local dotCfg = activeSkill.poisonCfg
			local sourceHitDmg, sourceCritDmg
			if breakdown then
				breakdown.PoisonPhysical = { damageTypes = { } }
				breakdown.PoisonLightning = { damageTypes = { } }
				breakdown.PoisonCold = { damageTypes = { } }
				breakdown.PoisonFire = { damageTypes = { } }
				breakdown.PoisonChaos = { damageTypes = { } }
			end
			for pass = 1, 2 do
				if not skillModList:Flag(dotCfg, "AilmentsAreNeverFromCrit") then
					dotCfg.skillCond["CriticalStrike"] = (pass == 1)
				end
				local totalMin, totalMax = 0, 0
				do
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.PoisonChaos, "Chaos", 0)
					output.PoisonChaosMin = min
					output.PoisonChaosMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				local nonChaosMult = 1
				if output.ChaosPoisonChance > 0 and output.PoisonChaosMax > 0 then
					-- Additional chance for chaos
					local chance = (pass == 1) and "PoisonChanceOnCrit" or "PoisonChanceOnHit"
					local chaosChance = m_min(100, output[chance] + output.ChaosPoisonChance)
					nonChaosMult = output[chance] / chaosChance
					output[chance] = chaosChance
				end
				if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanPoison") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.PoisonLightning, "Lightning", dmgTypeFlags.Chaos)
					output.PoisonLightningMin = min
					output.PoisonLightningMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if canDeal.Cold and skillModList:Flag(cfg, "ColdCanPoison") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.PoisonCold, "Cold", dmgTypeFlags.Chaos)
					output.PoisonColdMin = min
					output.PoisonColdMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if canDeal.Fire and skillModList:Flag(cfg, "FireCanPoison") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.PoisonFire, "Fire", dmgTypeFlags.Chaos)
					output.PoisonFireMin = min
					output.PoisonFireMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if canDeal.Physical then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.PoisonPhysical, "Physical", dmgTypeFlags.Chaos)
					output.PoisonPhysicalMin = min
					output.PoisonPhysicalMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if pass == 1 then
					sourceCritDmg = (totalMin + totalMax) / 2 * (1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "ChaosDotMultiplier") / 100 + output.BonusCritDotMultiplier)
				else
					sourceHitDmg = (totalMin + totalMax) / 2 * (1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "ChaosDotMultiplier") / 100)
				end
			end
			local baseVal = calcAilmentDamage("Poison", sourceHitDmg, sourceCritDmg) * 0.20
			if baseVal > 0 then
				skillFlags.poison = true
				skillFlags.duration = true
				local effMult = 1
				if env.mode_effective then
					local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist"), 75)
					local takenInc = enemyDB:Sum("INC", dotCfg, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
					local takenMore = enemyDB:More(dotCfg, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
					effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
					globalOutput["PoisonEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.PoisonEffMult = breakdown.effMult("Chaos", resist, 0, takenInc, effMult, takenMore)
					end
				end
				local effectMod = calcLib.mod(skillModList, dotCfg, "AilmentEffect")
				local rateMod = calcLib.mod(skillModList, cfg, "PoisonFaster")
				output.PoisonDPS = baseVal * effectMod * rateMod * effMult
				local durationBase
				if skillData.poisonDurationIsSkillDuration then
					durationBase = skillData.duration
				else
					durationBase = 2
				end
				local durationMod = calcLib.mod(skillModList, dotCfg, "EnemyPoisonDuration", "SkillAndDamagingAilmentDuration", skillData.poisonIsSkillEffect and "Duration" or nil) * calcLib.mod(enemyDB, nil, "SelfPoisonDuration")
				globalOutput.PoisonDuration = durationBase * durationMod / rateMod * debuffDurationMult
				output.PoisonDamage = output.PoisonDPS * globalOutput.PoisonDuration
				if skillData.showAverage then
					output.TotalPoisonAverageDamage = output.HitChance / 100 * output.PoisonChance / 100 * output.PoisonDamage
				else
					output.TotalPoisonStacks = output.HitChance / 100 * output.PoisonChance / 100 * globalOutput.PoisonDuration * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)
					output.TotalPoisonDPS = output.PoisonDPS * output.TotalPoisonStacks
				end
				if breakdown then
					t_insert(breakdown.PoisonDPS, "x 0.20 ^8(poison deals 20% per second)")
					t_insert(breakdown.PoisonDPS, s_format("= %.1f", baseVal, 1))
					breakdown.multiChain(breakdown.PoisonDPS, {
						label = "Poison DPS:",
						base = s_format("%.1f ^8(total damage per second)", baseVal), 
						{ "%.2f ^8(ailment effect modifier)", effectMod },
						{ "%.2f ^8(damage rate modifier)", rateMod },
						{ "%.3f ^8(effective DPS modifier)", effMult },
						total = s_format("= %.1f ^8per second", output.PoisonDPS),
					})
					if globalOutput.PoisonDuration ~= 2 then
						globalBreakdown.PoisonDuration = {
							s_format("%.2fs ^8(base duration)", durationBase)
						}
						if durationMod ~= 1 then
							t_insert(globalBreakdown.PoisonDuration, s_format("x %.2f ^8(duration modifier)", durationMod))
						end
						if rateMod ~= 1 then
							t_insert(globalBreakdown.PoisonDuration, s_format("/ %.2f ^8(damage rate modifier)", rateMod))
						end
						if debuffDurationMult ~= 1 then
							t_insert(globalBreakdown.PoisonDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
						end
						t_insert(globalBreakdown.PoisonDuration, s_format("= %.2fs", globalOutput.PoisonDuration))
					end
					breakdown.PoisonDamage = { }
					if isAttack then
						t_insert(breakdown.PoisonDamage, pass.label..":")
					end
					t_insert(breakdown.PoisonDamage, s_format("%.1f ^8(damage per second)", output.PoisonDPS))
					t_insert(breakdown.PoisonDamage, s_format("x %.2fs ^8(poison duration)", globalOutput.PoisonDuration))
					t_insert(breakdown.PoisonDamage, s_format("= %.1f ^8damage per poison stack", output.PoisonDamage))
					if not skillData.showAverage then
						breakdown.TotalPoisonStacks = { }
						if isAttack then
							t_insert(breakdown.TotalPoisonStacks, pass.label..":")
						end
						breakdown.multiChain(breakdown.TotalPoisonStacks, {
							base = s_format("%.2fs ^8(poison duration)", globalOutput.PoisonDuration),
							{ "%.2f ^8(poison chance)", output.PoisonChance / 100 },
							{ "%.2f ^8(hit chance)", output.HitChance / 100 },
							{ "%.2f ^8(hits per second)", globalOutput.HitSpeed or globalOutput.Speed },
							{ "%g ^8(dps multiplier for this skill)", skillData.dpsMultiplier or 1 },
							total = s_format("= %.1f", output.TotalPoisonStacks),
						})
					end
				end
			end
		end	

		-- Calculate ignite chance and damage
		if canDeal.Fire and (output.IgniteChanceOnHit + output.IgniteChanceOnCrit) > 0 then
			if not activeSkill.igniteCfg then
				activeSkill.igniteCfg = {
					skillName = skillCfg.skillName,
					skillPart = skillCfg.skillPart,
					skillTypes = skillCfg.skillTypes,
					slotName = skillCfg.slotName,
					flags = bor(ModFlag.Dot, ModFlag.Ailment, band(skillCfg.flags, ModFlag.Melee) ~= 0 and ModFlag.MeleeHit or 0),
					keywordFlags = bor(band(skillCfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.Ignite, KeywordFlag.Ailment, KeywordFlag.FireDot),
					skillCond = { },
				}
			end
			local dotCfg = activeSkill.igniteCfg
			local sourceHitDmg, sourceCritDmg
			if breakdown then
				breakdown.IgnitePhysical = { damageTypes = { } }
				breakdown.IgniteLightning = { damageTypes = { } }
				breakdown.IgniteCold = { damageTypes = { } }
				breakdown.IgniteFire = { damageTypes = { } }
				breakdown.IgniteChaos = { damageTypes = { } }
			end
			for pass = 1, 2 do
				if not skillModList:Flag(dotCfg, "AilmentsAreNeverFromCrit") then
					dotCfg.skillCond["CriticalStrike"] = (pass == 1)
				end
				local totalMin, totalMax = 0, 0
				if canDeal.Physical and skillModList:Flag(cfg, "PhysicalCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.IgnitePhysical, "Physical", dmgTypeFlags.Fire)
					output.IgnitePhysicalMin = min
					output.IgnitePhysicalMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.IgniteLightning, "Lightning", dmgTypeFlags.Fire)
					output.IgniteLightningMin = min
					output.IgniteLightningMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Cold and skillModList:Flag(cfg, "ColdCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.IgniteCold, "Cold", dmgTypeFlags.Fire)
					output.IgniteColdMin = min
					output.IgniteColdMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Fire and not skillModList:Flag(cfg, "FireCannotIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.IgniteFire, "Fire", 0)
					output.IgniteFireMin = min
					output.IgniteFireMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Chaos and skillModList:Flag(cfg, "ChaosCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, pass == 2 and breakdown and breakdown.IgniteChaos, "Chaos", dmgTypeFlags.Fire)
					output.IgniteChaosMin = min
					output.IgniteChaosMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if pass == 1 then
					sourceCritDmg = (totalMin + totalMax) / 2 * (1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "FireDotMultiplier") / 100 + output.BonusCritDotMultiplier)
				else
					sourceHitDmg = (totalMin + totalMax) / 2 * (1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "FireDotMultiplier") / 100)
				end
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.IgniteChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.IgniteDPS = {
					s_format("Ignite mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crit Damage" or "Average Damage")
				}
			end
			local baseVal = calcAilmentDamage("Ignite", sourceHitDmg, sourceCritDmg) * 0.5
			if baseVal > 0 then
				skillFlags.ignite = true
				local effMult = 1
				if env.mode_effective then
					local resist = m_min(enemyDB:Sum("BASE", nil, "FireResist", "ElementalResist"), 75)
					local takenInc = enemyDB:Sum("INC", dotCfg, "DamageTaken", "DamageTakenOverTime", "FireDamageTaken", "FireDamageTakenOverTime", "ElementalDamageTaken")
					local takenMore = enemyDB:More(dotCfg, "DamageTaken", "DamageTakenOverTime", "FireDamageTaken", "FireDamageTakenOverTime", "ElementalDamageTaken")
					effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
					globalOutput["IgniteEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.IgniteEffMult = breakdown.effMult("Fire", resist, 0, takenInc, effMult, takenMore)
					end
				end
				local effectMod = calcLib.mod(skillModList, dotCfg, "AilmentEffect")
				local rateMod = calcLib.mod(skillModList, cfg, "IgniteBurnFaster") / calcLib.mod(skillModList, cfg, "IgniteBurnSlower")
				output.IgniteDPS = baseVal * effectMod * rateMod * effMult
				local incDur = skillModList:Sum("INC", dotCfg, "EnemyIgniteDuration", "SkillAndDamagingAilmentDuration") + enemyDB:Sum("INC", nil, "SelfIgniteDuration")
				local moreDur = enemyDB:More(nil, "SelfIgniteDuration")
				globalOutput.IgniteDuration = 4 * (1 + incDur / 100) * moreDur / rateMod * debuffDurationMult
				if skillFlags.igniteCanStack then
					output.IgniteDamage = output.IgniteDPS * globalOutput.IgniteDuration
					if skillData.showAverage then
						output.TotalIgniteAverageDamage = output.HitChance / 100 * output.IgniteChance / 100 * output.IgniteDamage
					else
						output.TotalIgniteStacks = output.HitChance / 100 * output.IgniteChance / 100 * globalOutput.IgniteDuration * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)
						output.TotalIgniteDPS = output.IgniteDPS * output.TotalIgniteStacks
					end
				end
				if breakdown then
					t_insert(breakdown.IgniteDPS, "x 0.5 ^8(ignite deals 50% per second)")
					t_insert(breakdown.IgniteDPS, s_format("= %.1f", baseVal, 1))
					breakdown.multiChain(breakdown.IgniteDPS, {
						label = "Ignite DPS:",
						base = s_format("%.1f ^8(total damage per second)", baseVal), 
						{ "%.2f ^8(ailment effect modifier)", effectMod },
						{ "%.2f ^8(burn rate modifier)", rateMod },
						{ "%.3f ^8(effective DPS modifier)", effMult },
						total = s_format("= %.1f ^8per second", output.IgniteDPS),
					})
					if skillFlags.igniteCanStack then
						breakdown.IgniteDamage = { }
						if isAttack then
							t_insert(breakdown.IgniteDamage, pass.label..":")
						end
						t_insert(breakdown.IgniteDamage, s_format("%.1f ^8(damage per second)", output.IgniteDPS))
						t_insert(breakdown.IgniteDamage, s_format("x %.2fs ^8(ignite duration)", globalOutput.IgniteDuration))
						t_insert(breakdown.IgniteDamage, s_format("= %.1f ^8damage per ignite stack", output.IgniteDamage))
						if not skillData.showAverage then
							breakdown.TotalIgniteStacks = { }
							if isAttack then
								t_insert(breakdown.TotalIgniteStacks, pass.label..":")
							end
							breakdown.multiChain(breakdown.TotalIgniteStacks, {
								base = s_format("%.2fs ^8(ignite duration)", globalOutput.IgniteDuration),
								{ "%.2f ^8(ignite chance)", output.IgniteChance / 100 },
								{ "%.2f ^8(hit chance)", output.HitChance / 100 },
								{ "%.2f ^8(hits per second)", globalOutput.HitSpeed or globalOutput.Speed },
								{ "%g ^8(dps multiplier for this skill)", skillData.dpsMultiplier or 1 },
								total = s_format("= %.1f", output.TotalIgniteStacks),
							})
						end
					end
					if globalOutput.IgniteDuration ~= 4 then
						globalBreakdown.IgniteDuration = {
							s_format("4.00s ^8(base duration)", durationBase)
						}
						if incDur ~= 0 then
							t_insert(globalBreakdown.IgniteDuration, s_format("x %.2f ^8(increased/reduced duration)", 1 + incDur/100))
						end
						if moreDur ~= 1 then
							t_insert(globalBreakdown.IgniteDuration, s_format("x %.2f ^8(more/less duration)", moreDur))
						end
						if rateMod ~= 1 then
							t_insert(globalBreakdown.IgniteDuration, s_format("/ %.2f ^8(burn rate modifier)", rateMod))
						end
						if debuffDurationMult ~= 1 then
							t_insert(globalBreakdown.IgniteDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
						end
						t_insert(globalBreakdown.IgniteDuration, s_format("= %.2fs", globalOutput.IgniteDuration))
					end
				end
			end
		end

		-- Calculate shock and freeze chance + duration modifier
		-- FIXME Completely fucking wrong now
		if (output.ShockChanceOnHit + output.ShockChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if canDeal.Physical and skillModList:Flag(cfg, "PhysicalCanShock") then
				sourceHitDmg = sourceHitDmg + output.PhysicalHitAverage
				sourceCritDmg = sourceCritDmg + output.PhysicalCritAverage
			end
			if canDeal.Lightning and not skillModList:Flag(cfg, "LightningCannotShock") then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			if canDeal.Cold and skillModList:Flag(cfg, "ColdCanShock") then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
			end
			if canDeal.Fire and skillModList:Flag(cfg, "FireCanShock") then
				sourceHitDmg = sourceHitDmg + output.FireHitAverage
				sourceCritDmg = sourceCritDmg + output.FireCritAverage
			end
			if canDeal.Chaos and skillModList:Flag(cfg, "ChaosCanShock") then
				sourceHitDmg = sourceHitDmg + output.ChaosHitAverage
				sourceCritDmg = sourceCritDmg + output.ChaosCritAverage
			end
			local baseVal = calcAilmentDamage("Shock", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.shock = true
				output.ShockDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyShockDuration") / 100 + enemyDB:Sum("INC", nil, "SelfShockDuration") / 100
				output.ShockEffectMod = skillModList:Sum("INC", cfg, "EnemyShockEffect")
				if breakdown then
					t_insert(breakdown.ShockDPS, s_format("For the minimum 5%% Shock to apply for %.1f seconds, target must have no more than %d Ailment Threshold.", 2 * output.ShockDurationMod, (((100 + output.ShockEffectMod)^(2.5)) * baseVal) / (100 * m_sqrt(10))))
					t_insert(breakdown.ShockDPS, s_format("^8(Ailment Threshold is about equal to Life except on bosses where it is about half of their life)"))
				end
 			end
		end
		if (output.ChillChanceOnHit + output.ChillChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if canDeal.Cold and not skillModList:Flag(cfg, "ColdCannotChill") then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
			end
			if canDeal.Physical and skillModList:Flag(cfg, "PhysicalCanChill") then
				sourceHitDmg = sourceHitDmg + output.PhysicalHitAverage
				sourceCritDmg = sourceCritDmg + output.PhysicalCritAverage
			end
			if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanChill") then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			if canDeal.Fire and skillModList:Flag(cfg, "FireCanChill") then
				sourceHitDmg = sourceHitDmg + output.FireHitAverage
				sourceCritDmg = sourceCritDmg + output.FireCritAverage
			end
			if canDeal.Chaos and skillModList:Flag(cfg, "ChaosCanChill") then
				sourceHitDmg = sourceHitDmg + output.ChaosHitAverage
				sourceCritDmg = sourceCritDmg + output.ChaosCritAverage
			end
			local baseVal = calcAilmentDamage("Chill", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.chill = true
				output.ChillEffectMod = skillModList:Sum("INC", cfg, "EnemyChillEffect")
				output.ChillDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyChillDuration") / 100
				if breakdown then
					t_insert(breakdown.ChillDPS, s_format("For the minimum 5%% Chill to apply for %.1f seconds, target must have no more than %d Ailment Threshold.", 2 * output.ChillDurationMod, (((100 + output.ChillEffectMod)^(2.5)) * baseVal) / (100 * m_sqrt(10))))
					t_insert(breakdown.ChillDPS, s_format("^8(Ailment Threshold is about equal to Life except on bosses where it is about half of their life)"))
				end
			end
		end
		if (output.FreezeChanceOnHit + output.FreezeChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if canDeal.Cold and not skillModList:Flag(cfg, "ColdCannotFreeze") then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
			end
			if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanFreeze") then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			local baseVal = calcAilmentDamage("Freeze", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.freeze = true
				skillFlags.chill = true
				output.FreezeDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyFreezeDuration") / 100 + enemyDB:Sum("INC", nil, "SelfFreezeDuration") / 100
				if breakdown then
					t_insert(breakdown.FreezeDPS, s_format("For freeze to apply for the minimum of 0.3 seconds, target must have no more than %d Ailment Threshold.", baseVal * 20 * output.FreezeDurationMod))
					t_insert(breakdown.FreezeDPS, s_format("^8(Ailment Threshold is about equal to Life except on bosses where it is about half of their life)"))
				end
			end
		end

		-- Calculate knockback chance/distance
		output.KnockbackChance = m_min(100, output.KnockbackChanceOnHit * (1 - output.CritChance / 100) + output.KnockbackChanceOnCrit * output.CritChance / 100 + enemyDB:Sum("BASE", nil, "SelfKnockbackChance"))
		if output.KnockbackChance > 0 then
			output.KnockbackDistance = round(4 * calcLib.mod(skillModList, cfg, "EnemyKnockbackDistance"))
			if breakdown then
				breakdown.KnockbackDistance = {
					radius = output.KnockbackDistance,
				}
			end
		end

		-- Calculate enemy stun modifiers
		local enemyStunThresholdRed = -skillModList:Sum("INC", cfg, "EnemyStunThreshold")
		if enemyStunThresholdRed > 75 then
			output.EnemyStunThresholdMod = 1 - (75 + (enemyStunThresholdRed - 75) * 25 / (enemyStunThresholdRed - 50)) / 100
		else
			output.EnemyStunThresholdMod = 1 - enemyStunThresholdRed / 100
		end
		local base = skillData.baseStunDuration or 0.35
		local incDur = skillModList:Sum("INC", cfg, "EnemyStunDuration")
		local incRecov = enemyDB:Sum("INC", nil, "StunRecovery")
		output.EnemyStunDuration = base * (1 + incDur / 100) / (1 + incRecov / 100)
		if breakdown then
			if output.EnemyStunDuration ~= base then
				breakdown.EnemyStunDuration = {
					s_format("%.2fs ^8(base duration)", base),
				}
				if incDur ~= 0 then
					t_insert(breakdown.EnemyStunDuration, s_format("x %.2f ^8(increased/reduced stun duration)", 1 + incDur/100))
				end
				if incRecov ~= 0 then
					t_insert(breakdown.EnemyStunDuration, s_format("/ %.2f ^8(increased/reduced enemy stun recovery)", 1 + incRecov/100))
				end
				t_insert(breakdown.EnemyStunDuration, s_format("= %.2fs", output.EnemyStunDuration))
			end
		end
			
        -- Calculate impale chance and modifiers
		if canDeal.Physical and output.ImpaleChance > 0 then
            skillFlags.impale = true
            local impaleChance = m_min(output.ImpaleChance/100, 1)
            local maxStacks = skillModList:Sum("BASE", cfg, "ImpaleStacksMax") -- magic number: base stacks duration
            local configStacks = enemyDB:Override(nil, "ImpaleStacks") or 0
            local impaleStacks = configStacks > 0 and m_min(configStacks, maxStacks) or  maxStacks

            local baseStoredDamage = 0.1 -- magic number: base impale stored damage
            local storedDamageInc = skillModList:Sum("INC", cfg, "ImpaleEffect")/100
            local storedDamageMore = round(skillModList:More(cfg, "ImpaleEffect"), 2)
            local storedDamageModifier = (1 + storedDamageInc) * storedDamageMore
            local impaleStoredDamage = baseStoredDamage * storedDamageModifier

			local impaleDMGModifier = impaleStoredDamage * impaleStacks * impaleChance

            globalOutput.ImpaleStacksMax = maxStacks
			globalOutput.ImpaleStacks = impaleStacks
			--ImpaleStoredDamage should be named ImpaleEffect or similar
			--Using the variable name ImpaleEffect breaks the calculations sidebar (?!)
			output.ImpaleStoredDamage = impaleStoredDamage * 100
			output.ImpaleModifier = 1 + impaleDMGModifier

			if breakdown then
				breakdown.ImpaleStoredDamage = {}
				t_insert(breakdown.ImpaleStoredDamage, "10% ^8(base value)")
				t_insert(breakdown.ImpaleStoredDamage, s_format("x %.2f ^8(increased effectiveness)", storedDamageModifier))
				t_insert(breakdown.ImpaleStoredDamage, s_format("= %.1f%%", output.ImpaleStoredDamage))

				breakdown.ImpaleModifier = {}
				t_insert(breakdown.ImpaleModifier, s_format("%d ^8(number of stacks, can be overridden in the Configuration tab)", impaleStacks))
				t_insert(breakdown.ImpaleModifier, s_format("x %.3f ^8(stored damage)", impaleStoredDamage))
				t_insert(breakdown.ImpaleModifier, s_format("x %.2f ^8(impale chance)", impaleChance))
				t_insert(breakdown.ImpaleModifier, s_format("= %.3f ^8(impale damage multiplier)", impaleDMGModifier))

			end
		end
	end

	-- Combine secondary effect stats
	if isAttack then
		combineStat("BleedChance", "AVERAGE")
		combineStat("BleedDPS", "CHANCE", "BleedChance")
		combineStat("PoisonChance", "AVERAGE")
		combineStat("PoisonDPS", "CHANCE", "PoisonChance")
		combineStat("PoisonDamage", "CHANCE", "PoisonChance")
		if skillData.showAverage then
			combineStat("TotalPoisonAverageDamage", "DPS")
		else
			combineStat("TotalPoisonStacks", "DPS")
			combineStat("TotalPoisonDPS", "DPS")
		end
		combineStat("IgniteChance", "AVERAGE")
		combineStat("IgniteDPS", "CHANCE", "IgniteChance")
		if skillFlags.igniteCanStack then
			combineStat("IgniteDamage", "CHANCE", "IgniteChance")
			if skillData.showAverage then
				combineStat("TotalIgniteAverageDamage", "DPS")
			else
				combineStat("TotalIgniteStacks", "DPS")
				combineStat("TotalIgniteDPS", "DPS")
			end
		end
		combineStat("ChillEffectMod", "AVERAGE")
		combineStat("ChillDurationMod", "AVERAGE")
		combineStat("ShockChance", "AVERAGE")
		combineStat("ShockDurationMod", "AVERAGE")
		combineStat("ShockEffectMod", "AVERAGE")
		combineStat("FreezeChance", "AVERAGE")
		combineStat("FreezeDurationMod", "AVERAGE")
		combineStat("ImpaleChance", "AVERAGE")
		combineStat("ImpaleStoredDamage", "AVERAGE")
		combineStat("ImpaleModifier", "CHANCE", "ImpaleChance")
	end

	if skillFlags.hit and skillData.decay and canDeal.Chaos then
		-- Calculate DPS for Essence of Delirium's Decay effect
		skillFlags.decay = true
		activeSkill.decayCfg = {
			skillName = skillCfg.skillName,
			skillPart = skillCfg.skillPart,
			skillTypes = skillCfg.skillTypes,
			slotName = skillCfg.slotName,
			flags = ModFlag.Dot,
			keywordFlags = bor(band(skillCfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.ChaosDot),
		}
		local dotCfg = activeSkill.decayCfg
		local effMult = 1
		if env.mode_effective then
			local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist"), 75)
			local takenInc = enemyDB:Sum("INC", nil, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
			local takenMore = enemyDB:More(nil, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
			effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
			output["DecayEffMult"] = effMult
			if breakdown and effMult ~= 1 then
				breakdown.DecayEffMult = breakdown.effMult("Chaos", resist, 0, takenInc, effMult, takenMore)
			end
		end
		local inc = skillModList:Sum("INC", dotCfg, "Damage", "ChaosDamage")
		local more = round(skillModList:More(dotCfg, "Damage", "ChaosDamage"), 2)
		local mult = skillModList:Sum("BASE", dotTypeCfg, "DotMultiplier", "ChaosDotMultiplier")
		output.DecayDPS = skillData.decay * (1 + inc/100) * more * (1 + mult/100) * effMult
		local durationMod = calcLib.mod(skillModList, dotCfg, "Duration", "SkillAndDamagingAilmentDuration")
		output.DecayDuration = 10 * durationMod * debuffDurationMult
		if breakdown then
			breakdown.DecayDPS = { }
			t_insert(breakdown.DecayDPS, "Decay DPS:")
			breakdown.dot(breakdown.DecayDPS, skillData.decay, inc, more, mult, nil, effMult, output.DecayDPS)
			if output.DecayDuration ~= 2 then
				breakdown.DecayDuration = {
					s_format("%.2fs ^8(base duration)", 10)
				}
				if durationMod ~= 1 then
					t_insert(breakdown.DecayDuration, s_format("x %.2f ^8(duration modifier)", durationMod))
				end
				if debuffDurationMult ~= 1 then
					t_insert(breakdown.DecayDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
				end
				t_insert(breakdown.DecayDuration, s_format("= %.2fs", output.DecayDuration))
			end
		end
	end

	-- Calculate combined DPS estimate, including DoTs
	local baseDPS = output[(skillData.showAverage and "AverageDamage") or "TotalDPS"] + output.TotalDot
	output.CombinedDPS = baseDPS
	if skillData.showAverage then
		output.CombinedDPS = output.CombinedDPS + (output.TotalPoisonAverageDamage or 0)
		output.WithPoisonAverageDamage = baseDPS + (output.TotalPoisonAverageDamage or 0)
	else
		output.CombinedDPS = output.CombinedDPS + (output.TotalPoisonDPS or 0)
		output.WithPoisonDPS = baseDPS + (output.TotalPoisonDPS or 0)
	end
	if skillFlags.ignite then
		if skillFlags.igniteCanStack then
			if skillData.showAverage then
				output.CombinedDPS = output.CombinedDPS + output.TotalIgniteAverageDamage
				output.WithIgniteAverageDamage = baseDPS + output.TotalIgniteAverageDamage
			else
				output.CombinedDPS = output.CombinedDPS + output.TotalIgniteDPS
				output.WithIgniteDPS = baseDPS + output.TotalIgniteDPS
			end
		else
			output.CombinedDPS = output.CombinedDPS + output.IgniteDPS
		end
	end
	if skillFlags.bleed then
		output.CombinedDPS = output.CombinedDPS + output.BleedDPS
	end
	if skillFlags.decay then
		output.CombinedDPS = output.CombinedDPS + output.DecayDPS
	end
	if skillFlags.impale then
		output.ImpaleHit = ((output.MainHand.PhysicalHitAverage or output.OffHand.PhysicalHitAverage) + (output.OffHand.PhysicalHitAverage or output.MainHand.PhysicalHitAverage)) / 2 * (1-output.CritChance/100) + ((output.MainHand.PhysicalCritAverage or output.OffHand.PhysicalCritAverage) + (output.OffHand.PhysicalCritAverage or output.MainHand.PhysicalCritAverage)) / 2 * (output.CritChance/100)
		if skillData.doubleHitsWhenDualWielding and skillFlags.bothWeaponAttack then
			output.ImpaleHit = output.ImpaleHit * 2
		end
		output.ImpaleDPS = output.ImpaleHit * ((output.ImpaleModifier or 1) - 1) * output.HitChance / 100 * (skillData.dpsMultiplier or 1)
		if skillData.showAverage then
			output.WithImpaleDPS = output.AverageDamage + output.ImpaleDPS
		else
			skillFlags.notAverage = true
			output.ImpaleDPS = output.ImpaleDPS * (output.HitSpeed or output.Speed)
			output.WithImpaleDPS = output.TotalDPS + output.ImpaleDPS
		end
		output.CombinedDPS = output.CombinedDPS + output.ImpaleDPS
		if breakdown then
			breakdown.ImpaleDPS = {}
			t_insert(breakdown.ImpaleDPS, s_format("%.2f ^8(average physical hit)", output.ImpaleHit))
			t_insert(breakdown.ImpaleDPS, s_format("x %.2f ^8(chance to hit)", output.HitChance / 100))
			if skillFlags.notAverage then
				t_insert(breakdown.ImpaleDPS, output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(attack rate)", output.Speed))
			end
			t_insert(breakdown.ImpaleDPS, s_format("x %.2f ^8(impale damage multiplier)", ((output.ImpaleModifier or 1) - 1)))
			if skillData.dpsMultiplier then
				t_insert(breakdown.ImpaleDPS, s_format("x %g ^8(dps multiplier for this skill)", skillData.dpsMultiplier))
			end
			t_insert(breakdown.ImpaleDPS, s_format("= %.1f", output.ImpaleDPS))
		end
	end
end
