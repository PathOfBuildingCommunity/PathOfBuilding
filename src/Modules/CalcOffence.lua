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
local m_abs = math.abs
local m_floor = math.floor
local m_ceil = math.ceil
local m_min = math.min
local m_max = math.max
local m_sqrt = math.sqrt
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

---Calculates skill radius
---@param baseRadius number
---@param areaMod number
---@return number
local function calcRadius(baseRadius, areaMod)
	return m_floor(baseRadius * m_floor(100 * m_sqrt(areaMod)) / 100)
end

---Calculates the tertiary radius for Molten Strike, correctly handling the deadzone.
---@param baseRadius number
---@param deadzoneRadius number
---@param areaMod number
---@param speedMod number
local function calcMoltenStrikeTertiaryRadius(baseRadius, deadzoneRadius, areaMod, speedMod)
	-- For now, we assume that PoE only rounds at the end.
	local maxDistIgnoringSpeed = m_sqrt(baseRadius * baseRadius * areaMod - deadzoneRadius * deadzoneRadius * (areaMod - 1))
	local maxDist = m_floor((maxDistIgnoringSpeed - deadzoneRadius) * speedMod + deadzoneRadius)
	return maxDist
end

---Calculates modifiers needed to reach the next and previous radius breakpoints
---@param baseRadius number
---@param incArea number @Additive modifier
---@param moreArea number @Multiplicative modifier
---@return number, number, number, number @Next breakpoint: increased, more; Previous breakpoint: reduced, less
local function calcRadiusBreakpoints(baseRadius, incArea, moreArea)
	local radius = calcRadius(baseRadius, round(round(incArea * moreArea, 10), 2))
	local incAreaBreakpoint, redAreaBreakpoint, moreAreaBreakpoint, lessAreaBreakpoint
	if radius > 0 then
		incAreaBreakpoint = 0
		repeat 
			incAreaBreakpoint = incAreaBreakpoint + 1
			local newRadius = calcRadius(baseRadius, round(round((incArea + incAreaBreakpoint / 100) * moreArea, 10), 2))
		until (newRadius > radius)
		redAreaBreakpoint = 0
		repeat 
			redAreaBreakpoint = redAreaBreakpoint + 1
			local newRadius = calcRadius(baseRadius, round(round((incArea - redAreaBreakpoint / 100) * moreArea, 10), 2))
		until (newRadius < radius)
		moreAreaBreakpoint = 0
		repeat 
			moreAreaBreakpoint = moreAreaBreakpoint + 1
			local newRadius = calcRadius(baseRadius, round(round(incArea * moreArea * (1 + moreAreaBreakpoint / 100), 10), 2))
		until (newRadius > radius)
		lessAreaBreakpoint = 0
		repeat 
			lessAreaBreakpoint = lessAreaBreakpoint + 1
			local newRadius = calcRadius(baseRadius, round(round(incArea * moreArea * (1 - lessAreaBreakpoint / 100), 10), 2))
		until (newRadius < radius)
	end
	return incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint
end

---Computes and sets the breakdown for Molten Strike's tertiary radius.
---@param breakdown table
---@param deadzoneRadius number min ball landing distance (cannot be changed by any mods)
---@param baseRadius number default max landing distance with no aoe or proj. speed modifiers
---@param label string top level label to use for the breakdown
---@param incArea number current net increased area modifier
---@param moreArea number current product of all "more" and "less" area modifiers
---@param incSpd number current net increased projectile speed modifier
---@param moreSpd number current product of all "more" and "less" projectile speed modifiers
local function setMoltenStrikeTertiaryRadiusBreakdown(breakdown, deadzoneRadius, baseRadius, label, incArea, moreArea, incSpd, moreSpd)
	-- nil -> 1 (no multiplier)
	incArea = incArea or 1
	moreArea = moreArea or 1
	incSpd = incSpd or 1
	moreSpd = moreSpd or 1
	---Helper that calculates the tertiary radius with incremental modifiers to the 4 relevant pools.
	---This helps declutter the code below.
	local function calc(extraIncAoePct, extraMoreAoePct, extraIncSpdPct, extraMoreSpdPct)
		local areaMod = round(round((incArea + extraIncAoePct / 100) * moreArea * (1 + extraMoreAoePct / 100), 10), 2)
		local speedMod = round(round((incSpd + extraIncSpdPct / 100) * moreSpd * (1 + extraMoreSpdPct / 100), 10), 2)
		local dist = calcMoltenStrikeTertiaryRadius(baseRadius, deadzoneRadius, areaMod, speedMod)
		return dist, areaMod, speedMod
	end
	-- Current settings.
	local currentDist, currentAreaMod, currentSpeedMod = calc(0, 0, 0, 0)
	-- Create the detailed breakdown. This includes:
	--  * the complete formula as an algebraic expression (ignoring rounding),
	--  * the final value,
	--  * breakpoints on the 4 modifier pools (increased vs. more crossed with aoe and projectile speed), and
	--  * the input variables for the algebraic expression.
	local breakdownRadius = breakdown.AreaOfEffectRadiusTertiary or { }
	breakdown.AreaOfEffectRadiusTertiary = breakdownRadius
	t_insert(breakdownRadius, label)
	t_insert(breakdownRadius, " = (sqrt(R*R*a - r*r*(a-1)) - r) * s + r")
	t_insert(breakdownRadius, s_format(" = %d", currentDist))
	if currentDist > 0 then
		---Helper for finding one tertiary radius breakpoint value. This is a little slower than what
		---we do in the generic calcRadiusBreakpoints, but this approach requires a lot less code and
		---should be more maintainable given that we need to search for 8 different breakpoints.
		---@param sign number +1 (for increased and more breakpoints) or -1 (for reduced and less breakpoints)
		---@param argIdx number which argument to the calc function we're modifying
		local function findBreakpoint(sign, argIdx)
			local args = {0, 0, 0, 0} -- starter args for the calc function
			repeat
				args[argIdx] = args[argIdx] + sign -- increment or decrement the desired arg
				local newDist, _, _ = calc(unpack(args))
			until (newDist ~= currentDist) or (newDist == 0) -- stop once we've hit a new radius breakpoint
			return args[argIdx] * sign -- remove the sign since we want all positive numbers
		end
		t_insert(breakdownRadius, s_format("^8Next AoE breakpoint: %d%% increased or %d%% more", findBreakpoint(1, 1), findBreakpoint(1, 2)))
		t_insert(breakdownRadius, s_format("^8Next Proj. Speed breakpoint: %d%% increased or %d%% more", findBreakpoint(1, 3), findBreakpoint(1, 4)))
		t_insert(breakdownRadius, s_format("^8Previous AoE breakpoint: %d%% increased or %d%% more", findBreakpoint(-1, 1), findBreakpoint(-1, 2)))
		t_insert(breakdownRadius, s_format("^8Previous Proj. Speed breakpoint: %d%% increased or %d%% more", findBreakpoint(-1, 3), findBreakpoint(-1, 4)))
	end
	-- This is the input variable table.
	breakdownRadius.label = "Inputs"
	breakdownRadius.rowList = { }
	breakdownRadius.colList = {
		{ label = "Variable", key = "name" },
		{ label = "Value", key = "value"},
		{ label = "Description", key = "description" }
	}
	t_insert(breakdownRadius.rowList, { name = "r", value = s_format("%d", deadzoneRadius), description = "fixed deadzone radius" })
	t_insert(breakdownRadius.rowList, { name = "R", value = s_format("%d", baseRadius), description = "base outer radius" })
	t_insert(breakdownRadius.rowList, { name = "a", value = s_format("%.2f", currentAreaMod), description = "net AoE multiplier (scales area)" })
	t_insert(breakdownRadius.rowList, { name = "s", value = s_format("%.2f", currentSpeedMod), description = "net projectile speed multiplier (scales range)" })
	-- Trigger the inclusion of the radius display.
	breakdownRadius.radius = currentDist
end

function calcSkillCooldown(skillModList, skillCfg, skillData)
	local cooldownOverride = skillModList:Override(skillCfg, "CooldownRecovery")
	local cooldown = cooldownOverride or (skillData.cooldown  + skillModList:Sum("BASE", skillCfg, "CooldownRecovery")) / calcLib.mod(skillModList, skillCfg, "CooldownRecovery")
	cooldown = m_ceil(cooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
	return cooldown
end

local function calcWarcryCastTime(skillModList, skillCfg, actor)
	local baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "WarcryCastTime")
	local warcryCastTime = baseSpeed * calcLib.mod(skillModList, skillCfg, "WarcrySpeed") * calcs.actionSpeedMod(actor)
	warcryCastTime = m_min(warcryCastTime, data.misc.ServerTickRate)
	warcryCastTime = 1 / warcryCastTime
	if skillModList:Flag(skillCfg, "InstantWarcry") then
		warcryCastTime = 0
	end
	return warcryCastTime
end

function calcSkillDuration(skillModList, skillCfg, skillData, env, enemyDB)
	local durationMod = calcLib.mod(skillModList, skillCfg, "Duration", "PrimaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
	local durationBase = (skillData.duration or 0) + skillModList:Sum("BASE", skillCfg, "Duration", "PrimaryDuration")
	local duration = durationBase * durationMod
	local debuffDurationMult = 1
	if env.mode_effective then
		debuffDurationMult = 1 / m_max(data.misc.BuffExpirationSlowCap, calcLib.mod(enemyDB, skillCfg, "BuffExpireFaster"))
	end
	if skillData.debuff then
		duration = duration * debuffDurationMult
	end
	return duration
end

-- Performs all offensive calculations
function calcs.offence(env, actor, activeSkill)
	local modDB = actor.modDB
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

	local function calcAreaOfEffect(skillModList, skillCfg, skillData, skillFlags, output, breakdown)
		local incArea, moreArea = calcLib.mods(skillModList, skillCfg, "AreaOfEffect")
		output.AreaOfEffectMod = round(round(incArea * moreArea, 10), 2)
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
			output.AreaOfEffectRadius = calcRadius(baseRadius, output.AreaOfEffectMod)
			if breakdown then
				local incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint = calcRadiusBreakpoints(baseRadius, incArea, moreArea)
				breakdown.AreaOfEffectRadius = breakdown.area(baseRadius, output.AreaOfEffectMod, output.AreaOfEffectRadius, incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint, skillData.radiusLabel)
			end
			if skillData.radiusSecondary then
				local incAreaSecondary, moreAreaSecondary = calcLib.mods(skillModList, skillCfg, "AreaOfEffect", "AreaOfEffectSecondary")
				output.AreaOfEffectModSecondary = round(round(incAreaSecondary * moreAreaSecondary, 10), 2)
				baseRadius = skillData.radiusSecondary + (skillData.radiusExtra or 0)
				output.AreaOfEffectRadiusSecondary = calcRadius(baseRadius, output.AreaOfEffectModSecondary)
				if breakdown then
					local incAreaBreakpointSecondary, moreAreaBreakpointSecondary, redAreaBreakpointSecondary, lessAreaBreakpointSecondary
					if not skillData.projectileSpeedAppliesToMSAreaOfEffect then
						local incAreaBreakpointSecondary, moreAreaBreakpointSecondary, redAreaBreakpointSecondary, lessAreaBreakpointSecondary = calcRadiusBreakpoints(baseRadius, incAreaSecondary, moreAreaSecondary)
					end
					breakdown.AreaOfEffectRadiusSecondary = breakdown.area(baseRadius, output.AreaOfEffectModSecondary, output.AreaOfEffectRadiusSecondary, incAreaBreakpointSecondary, moreAreaBreakpointSecondary, redAreaBreakpointSecondary, lessAreaBreakpointSecondary, skillData.radiusSecondaryLabel)
				end
			end
			if skillData.radiusTertiary then
				local incAreaTertiary, moreAreaTertiary = calcLib.mods(skillModList, skillCfg, "AreaOfEffect", "AreaOfEffectTertiary")
				output.AreaOfEffectModTertiary = round(round(incAreaTertiary * moreAreaTertiary, 10), 2)
				baseRadius = skillData.radiusTertiary + (skillData.radiusExtra or 0)
				if skillData.projectileSpeedAppliesToMSAreaOfEffect then
					local incSpeedTertiary, moreSpeedTertiary = calcLib.mods(skillModList, skillCfg, "ProjectileSpeed")
					output.SpeedModTertiary = round(round(incSpeedTertiary * moreSpeedTertiary, 10), 2)
					output.AreaOfEffectRadiusTertiary = calcMoltenStrikeTertiaryRadius(baseRadius, skillData.radiusSecondary, output.AreaOfEffectModTertiary, output.SpeedModTertiary)
					if breakdown then
						setMoltenStrikeTertiaryRadiusBreakdown(
							breakdown, skillData.radiusSecondary, baseRadius, skillData.radiusTertiaryLabel,
							incAreaTertiary, moreAreaTertiary, incSpeedTertiary, moreSpeedTertiary
						)
					end
				else
					output.AreaOfEffectRadiusTertiary = calcRadius(baseRadius, output.AreaOfEffectModTertiary)
					if breakdown then
						local incAreaBreakpointTertiary, moreAreaBreakpointTertiary, redAreaBreakpointTertiary, lessAreaBreakpointTertiary = calcRadiusBreakpoints(baseRadius, incAreaTertiary, moreAreaTertiary)
						breakdown.AreaOfEffectRadiusTertiary = breakdown.area(baseRadius, output.AreaOfEffectModTertiary, output.AreaOfEffectRadiusTertiary, incAreaBreakpointTertiary, moreAreaBreakpointTertiary, redAreaBreakpointTertiary, lessAreaBreakpointTertiary, skillData.radiusTertiaryLabel)
					end
				end
			end
		end
		if breakdown then
			breakdown.AreaOfEffectMod = { }
			breakdown.multiChain(breakdown.AreaOfEffectMod, {
				{ "%.2f ^8(increased/reduced)", 1 + skillModList:Sum("INC", skillCfg, "AreaOfEffect") / 100 },
				{ "%.2f ^8(more/less)", skillModList:More(skillCfg, "AreaOfEffect") },
				total = s_format("= %.2f", output.AreaOfEffectMod),
			})
		end
	end

	local function runSkillFunc(name)
		local func = activeSkill.activeEffect.grantedEffect[name]
		if func then
			func(activeSkill, output)
		end
	end

	runSkillFunc("initialFunc")

	local isTriggered = skillData.triggeredWhileChannelling or skillData.triggeredByCoC or skillData.triggeredByMeleeKill or skillData.triggeredByCospris or skillData.triggeredByMjolner or skillData.triggeredByUnique or skillData.triggeredByFocus or skillData.triggeredByCraft or skillData.triggeredByManaSpent
	skillCfg.skillCond["SkillIsTriggered"] = skillData.triggered or isTriggered
	if skillCfg.skillCond["SkillIsTriggered"] then
		skillFlags.triggered = true
	end
	skillCfg.skillCond["SkillIsFocused"] = skillData.triggeredByFocus
	if skillCfg.skillCond["SkillIsFocused"] then
		skillFlags.focused = true
	end

	-- Update skill data
	for _, value in ipairs(skillModList:List(skillCfg, "SkillData")) do
		if value.merge == "MAX" then
			skillData[value.key] = m_max(value.value, skillData[value.key] or 0)
		else
			skillData[value.key] = value.value
		end
	end

	-- Add addition stat bonuses
	if skillModList:Flag(nil, "IronGrip") then
		skillModList:NewMod("PhysicalDamage", "INC", actor.strDmgBonus or 0, "Strength", bor(ModFlag.Attack, ModFlag.Projectile))
	end
	if skillModList:Flag(nil, "IronWill") then
		skillModList:NewMod("Damage", "INC", actor.strDmgBonus or 0, "Strength", ModFlag.Spell)
	end
	
	if skillModList:Flag(nil, "TransfigurationOfBody") then
		skillModList:NewMod("Damage", "INC", m_floor(skillModList:Sum("INC", nil, "Life") * data.misc.Transfiguration), "Transfiguration of Body", ModFlag.Attack)
	end
	if skillModList:Flag(nil, "TransfigurationOfMind") then
		skillModList:NewMod("Damage", "INC", m_floor(skillModList:Sum("INC", nil, "Mana") * data.misc.Transfiguration), "Transfiguration of Mind")
	end
	if skillModList:Flag(nil, "TransfigurationOfSoul") then
		skillModList:NewMod("Damage", "INC", m_floor(skillModList:Sum("INC", nil, "EnergyShield") * data.misc.Transfiguration), "Transfiguration of Soul", ModFlag.Spell)
	end

	if modDB:Flag(nil, "Elusive") and skillModList:Flag(nil, "SupportedByNightblade") then
		local elusiveEffect = output.ElusiveEffectMod / 100
		local nightbladeMulti = skillModList:Sum("BASE", nil, "NightbladeElusiveCritMultiplier")
		skillModList:NewMod("CritMultiplier", "BASE", m_floor(nightbladeMulti * elusiveEffect), "Nightblade")
	end

	-- modType: To look for "INC" or "BASE" for getting the percent conversion
	-- modName: Mod name to look for getting the percent conversion
	local getConversionMultiplier = function(modType, modName)
		-- Default to 100% conversion
		local multiplier = 1
		if modType and modName then
			local maxIncrease = 0
			for i, value in ipairs(skillModList:Tabulate(modType, skillCfg, modName)) do
				maxIncrease = m_max(maxIncrease, value.mod.value)
			end
			-- Convert from percent to fraction
			multiplier = maxIncrease / 100.
		end
		return multiplier
	end

	-- Correct the tags on conversion with multipliers so they carry over correctly
	local getConvertedModTags = function(mod, multiplier, minionMods)
		local modifiers = modLib.extractModTags(mod)
		for k, value in ipairs(modifiers) do
			if minionMods and value.type == "ActorCondition" and value.actor == "parent" then
				modifiers[k] = { type = "Condition", var = value.var }
			elseif value.limitTotal then
				-- LimitTotal can apply to 'per stat' or 'multiplier', so just copy the whole and update the limit
				local copy = copyTable(value)
				copy.limit = copy.limit * multiplier
				modifiers[k] = copy
			end
		end
		return modifiers
	end

	-- additional charge based modifiers
	if skillModList:Flag(nil, "UseEnduranceCharges") and skillModList:Flag(nil, "EnduranceChargesConvertToBrutalCharges") then
		local tripleDmgChancePerEndurance = modDB:Sum("BASE", nil, "PerBrutalTripleDamageChance")
		modDB:NewMod("TripleDamageChance", "BASE", tripleDmgChancePerEndurance, { type = "Multiplier", var = "BrutalCharge" } )
	end
	if skillModList:Flag(nil, "UseFrenzyCharges") and skillModList:Flag(nil, "FrenzyChargesConvertToAfflictionCharges") then
		local dmgPerAffliction = modDB:Sum("BASE", nil, "PerAfflictionAilmentDamage")
		local effectPerAffliction = modDB:Sum("BASE", nil, "PerAfflictionNonDamageEffect")
		modDB:NewMod("Damage", "MORE", dmgPerAffliction, "Affliction Charges", 0, KeywordFlag.Ailment, { type = "Multiplier", var = "AfflictionCharge" } )
		modDB:NewMod("EnemyChillEffect", "MORE", effectPerAffliction, "Affliction Charges", { type = "Multiplier", var = "AfflictionCharge" } )
		modDB:NewMod("EnemyShockEffect", "MORE", effectPerAffliction, "Affliction Charges", { type = "Multiplier", var = "AfflictionCharge" } )
		modDB:NewMod("EnemyFreezeEffect", "MORE", effectPerAffliction, "Affliction Charges", { type = "Multiplier", var = "AfflictionCharge" } )
		modDB:NewMod("EnemyScorchEffect", "MORE", effectPerAffliction, "Affliction Charges", { type = "Multiplier", var = "AfflictionCharge" } )
		modDB:NewMod("EnemyBrittleEffect", "MORE", effectPerAffliction, "Affliction Charges", { type = "Multiplier", var = "AfflictionCharge" } )
		modDB:NewMod("EnemySapEffect", "MORE", effectPerAffliction, "Affliction Charges", { type = "Multiplier", var = "AfflictionCharge" } )
	end

	-- set other limits
	output.ActiveTrapLimit = skillModList:Sum("BASE", skillCfg, "ActiveTrapLimit")
	output.ActiveMineLimit = skillModList:Sum("BASE", skillCfg, "ActiveMineLimit")

	-- set flask scaling
	output.LifeFlaskRecovery = env.itemModDB.multipliers["LifeFlaskRecovery"]

	-- account for Battlemage
	-- Note: we check conditions of Main Hand weapon using actor.itemList as actor.weaponData1 is populated with unarmed values when no weapon slotted.
	if skillModList:Flag(nil, "WeaponDamageAppliesToSpells") and actor.itemList["Weapon 1"] and actor.itemList["Weapon 1"].weaponData and actor.itemList["Weapon 1"].weaponData[1] then
		-- the multiplier below exist for future possible extension of Battlemage modifiers
		local multiplier = getConversionMultiplier("INC", "ImprovedWeaponDamageAppliesToSpells") or 1
		for _, damageType in ipairs(dmgTypeList) do
			skillModList:NewMod(damageType.."Min", "BASE", (actor.weaponData1[damageType.."Min"] or 0) * multiplier, "Battlemage", ModFlag.Spell)
			skillModList:NewMod(damageType.."Max", "BASE", (actor.weaponData1[damageType.."Max"] or 0) * multiplier, "Battlemage", ModFlag.Spell)
		end
	end
	if skillModList:Flag(nil, "MinionDamageAppliesToPlayer") then
		-- Minion Damage conversion from Spiritual Aid and The Scourge
		local multiplier = getConversionMultiplier("INC", "ImprovedMinionDamageAppliesToPlayer")
		for _, value in ipairs(skillModList:List(skillCfg, "MinionModifier")) do
			if value.mod.name == "Damage" and value.mod.type == "INC" then
				local mod = value.mod
				local modifiers = getConvertedModTags(mod, multiplier, true)
				skillModList:NewMod("Damage", "INC", mod.value * multiplier, mod.source, mod.flags, mod.keywordFlags, unpack(modifiers))
			end
		end
	end
	if skillModList:Flag(nil, "MinionAttackSpeedAppliesToPlayer") then
		-- Minion Damage conversion from Spiritual Command
		local multiplier = getConversionMultiplier("INC", "ImprovedMinionAttackSpeedAppliesToPlayer")
		-- Minion Attack Speed conversion from Spiritual Command
		for _, value in ipairs(skillModList:List(skillCfg, "MinionModifier")) do
			if value.mod.name == "Speed" and value.mod.type == "INC" and (value.mod.flags == 0 or band(value.mod.flags, ModFlag.Attack) ~= 0) then
				local modifiers = getConvertedModTags(value.mod, multiplier, true)
				skillModList:NewMod("Speed", "INC", value.mod.value * multiplier, value.mod.source, ModFlag.Attack, value.mod.keywordFlags, unpack(modifiers))
			end
		end
	end
	if skillModList:Flag(nil, "SpellDamageAppliesToAttacks") then
		-- Spell Damage conversion from Crown of Eyes, Kinetic Bolt, and the Wandslinger notable
		local multiplier = getConversionMultiplier("INC", "ImprovedSpellDamageAppliesToAttacks")
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Spell }, "Damage")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Spell) ~= 0 then
				local modifiers = getConvertedModTags(mod, multiplier)
				skillModList:NewMod("Damage", "INC", mod.value * multiplier, mod.source, bor(band(mod.flags, bnot(ModFlag.Spell)), ModFlag.Attack), mod.keywordFlags, unpack(modifiers))
				if mod.source == "Strength" then -- Prevent double-dipping from converted strength's damage bonus
					skillModList:ReplaceMod("PhysicalDamage", "INC", 0, "Strength", ModFlag.Melee)
				end
			end
		end
	end
	if skillModList:Flag(nil, "CastSpeedAppliesToAttacks") then
		-- Get all increases for this; assumption is that multiple sources would not stack, so find the max
		local multiplier = getConversionMultiplier("INC", "ImprovedCastSpeedAppliesToAttacks")
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Cast }, "Speed")) do
			local mod = value.mod
			-- Add a new mod for all mods that are cast only
			-- Replace this with a single mod for the sum?
			if band(mod.flags, ModFlag.Cast) ~= 0 then
				local modifiers = getConvertedModTags(mod, multiplier)
				skillModList:NewMod("Speed", "INC", mod.value * multiplier, mod.source, bor(band(mod.flags, bnot(ModFlag.Cast)), ModFlag.Attack), mod.keywordFlags, unpack(modifiers))
			end
		end
	end
	if skillModList:Flag(nil, "MaximumManaAppliesToShockEffect") then
		-- Maximum Mana conversion from Lightning Mastery
		local multiplier = getConversionMultiplier("INC", "ImprovedMaximumManaAppliesToShockEffect")
		for i, value in ipairs(skillModList:Tabulate("INC", nil, "Mana")) do
			local mod = value.mod
			local modifiers = getConvertedModTags(mod, multiplier)
			skillModList:NewMod("EnemyShockEffect", "INC", mod.value * multiplier, mod.source, mod.flags, mod.keywordFlags, unpack(modifiers))
		end
	end
	if skillModList:Flag(nil, "ClawDamageAppliesToUnarmed") then
		-- Claw Damage conversion from Rigwald's Curse
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = ModFlag.Claw, keywordFlags = KeywordFlag.Hit }, "Damage")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				skillModList:NewMod("Damage", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "ClawAttackSpeedAppliesToUnarmed") then
		-- Claw Attack Speed conversion from Rigwald's Curse
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = bor(ModFlag.Claw, ModFlag.Attack, ModFlag.Hit) }, "Speed")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 and band(mod.flags, ModFlag.Attack) ~= 0 then
				skillModList:NewMod("Speed", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "ClawCritChanceAppliesToUnarmed") then
		-- Claw Crit Chance conversion from Rigwald's Curse
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = bor(ModFlag.Claw, ModFlag.Hit) }, "CritChance")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				skillModList:NewMod("CritChance", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "ClawCritChanceAppliesToMinions") then
		-- Claw Crit Chance conversion from Law of the Wilds
		for i, value in ipairs(skillModList:Tabulate("INC", { flags = bor(ModFlag.Claw, ModFlag.Hit) }, "CritChance")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 then
            	env.minion.modDB:NewMod("CritChance", mod.type, mod.value, mod.source)
			end
		end
	end
   if skillModList:Flag(nil, "ClawCritMultiplierAppliesToMinions") then
		-- Claw Crit Multi conversion from Law of the Wilds
		for i, value in ipairs(skillModList:Tabulate("BASE", { flags = bor(ModFlag.Claw, ModFlag.Hit) }, "CritMultiplier")) do
			local mod = value.mod
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				env.minion.modDB:NewMod("CritMultiplier", mod.type, mod.value, mod.source)
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
	if skillModList:Flag(nil, "SequentialProjectiles") and not skillModList:Flag(nil, "OneShotProj") and not skillModList:Flag(nil,"NoAdditionalProjectiles") and not skillModList:Flag(nil, "TriggeredBySnipe") then
		-- Applies DPS multiplier based on projectile count
		skillData.dpsMultiplier = skillModList:Sum("BASE", skillCfg, "ProjectileCount")
	end
	if skillData.gainPercentBaseWandDamage then
		local mult = skillData.gainPercentBaseWandDamage / 100
		if actor.weaponData1.type == "Wand" and actor.weaponData2.type == "Wand" then
			for _, damageType in ipairs(dmgTypeList) do
				skillModList:NewMod(damageType.."Min", "BASE", ((actor.weaponData1[damageType.."Min"] or 0) + (actor.weaponData2[damageType.."Min"] or 0)) / 2 * mult, "Spellslinger")
				skillModList:NewMod(damageType.."Max", "BASE", ((actor.weaponData1[damageType.."Max"] or 0) + (actor.weaponData2[damageType.."Max"] or 0)) / 2 * mult, "Spellslinger")
			end
		elseif actor.weaponData1.type == "Wand" then
			for _, damageType in ipairs(dmgTypeList) do
				skillModList:NewMod(damageType.."Min", "BASE", (actor.weaponData1[damageType.."Min"] or 0) * mult, "Spellslinger")
				skillModList:NewMod(damageType.."Max", "BASE", (actor.weaponData1[damageType.."Max"] or 0) * mult, "Spellslinger")
			end
		elseif actor.weaponData2.type == "Wand" then
			for _, damageType in ipairs(dmgTypeList) do
				skillModList:NewMod(damageType.."Min", "BASE", (actor.weaponData2[damageType.."Min"] or 0) * mult, "Spellslinger")
				skillModList:NewMod(damageType.."Max", "BASE", (actor.weaponData2[damageType.."Max"] or 0) * mult, "Spellslinger")
			end
		end
	end
	if skillModList:Flag(nil, "TriggeredBySnipe") and activeSkill.skillTypes[SkillType.Triggerable] then
		skillModList:NewMod("Damage", "MORE", 165, "Config", ModFlag.Hit, { type = "Multiplier", var = "SnipeStage" } )
		skillModList:NewMod("Damage", "MORE", 120, "Config", ModFlag.Ailment, { type = "Multiplier", var = "SnipeStage" } )
	end
	if skillModList:Sum("BASE", nil, "CritMultiplierAppliesToDegen") > 0 then
		for i, value in ipairs(skillModList:Tabulate("BASE", skillCfg, "CritMultiplier")) do
			local mod = value.mod
			if mod.source ~= "Base" then -- The global base Crit Multi doesn't apply to ailments with Perfect Agony
				skillModList:NewMod("DotMultiplier", "BASE", m_floor(mod.value / 2), mod.source, ModFlag.Ailment, { type = "Condition", var = "CriticalStrike" }, unpack(mod))
			end
		end
	end
	if skillModList:Flag(nil, "HasSeals") and activeSkill.skillTypes[SkillType.CanRapidFire] then
		-- Applies DPS multiplier based on seals count
		output.SealCooldown = skillModList:Sum("BASE", skillCfg, "SealGainFrequency") / calcLib.mod(skillModList, skillCfg, "SealGainFrequency")
		output.SealMax = skillModList:Sum("BASE", skillCfg, "SealCount")
		output.TimeMaxSeals = output.SealCooldown * output.SealMax

		if not skillData.hitTimeOverride then
			if skillModList:Flag(nil, "UseMaxUnleash") then
				for i, value in ipairs(skillModList:Tabulate("INC",  { }, "MaxSealCrit")) do
					local mod = value.mod
					skillModList:NewMod("CritChance", "INC", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
				end
				env.player.mainSkill.skillData.dpsMultiplier = (1 + output.SealMax * calcLib.mod(skillModList, skillCfg, "SealRepeatPenalty"))
				env.player.mainSkill.skillData.hitTimeOverride = m_max(output.TimeMaxSeals, (1 / activeSkill.activeEffect.grantedEffect.castTime * 1.1 * calcLib.mod(skillModList, skillCfg, "Speed") * output.ActionSpeedMod))
			else
				env.player.mainSkill.skillData.dpsMultiplier = 1 + 1 / output.SealCooldown / (1 / activeSkill.activeEffect.grantedEffect.castTime * 1.1 * calcLib.mod(skillModList, skillCfg, "Speed") * output.ActionSpeedMod) * calcLib.mod(skillModList, skillCfg, "SealRepeatPenalty")
			end
		end
		
		if breakdown then
			breakdown.SealGainTime = { }
			breakdown.multiChain(breakdown.SealGainTime, {
				label = "Gain frequency:",
				base = s_format("%.2fs ^8(base gain frequency)", skillModList:Sum("BASE", skillCfg, "SealGainFrequency")),
				{ "%.2f ^8(increased/reduced gain frequency)", 1 + skillModList:Sum("INC", skillCfg, "SealGainFrequency") / 100 },
				{ "%.2f ^8(action speed modifier)",  output.ActionSpeedMod },
				total = s_format("= %.2fs ^8per Seal", output.SealCooldown),
			})
		end
	end
	if skillModList:Sum("BASE", skillCfg, "PhysicalDamageGainAsRandom", "PhysicalDamageConvertToRandom", "PhysicalDamageGainAsColdOrLightning") > 0 then
		skillFlags.randomPhys = true
		local physMode = env.configInput.physMode or "AVERAGE"
		for i, value in ipairs(skillModList:Tabulate("BASE", skillCfg, "PhysicalDamageGainAsRandom")) do
			local mod = value.mod
			local effVal = mod.value / 3
			if physMode == "AVERAGE" then
				skillModList:NewMod("PhysicalDamageGainAsFire", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
				skillModList:NewMod("PhysicalDamageGainAsCold", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
				skillModList:NewMod("PhysicalDamageGainAsLightning", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "FIRE" then
				skillModList:NewMod("PhysicalDamageGainAsFire", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "COLD" then
				skillModList:NewMod("PhysicalDamageGainAsCold", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "LIGHTNING" then
				skillModList:NewMod("PhysicalDamageGainAsLightning", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			end
		end
		for i, value in ipairs(skillModList:Tabulate("BASE", skillCfg, "PhysicalDamageConvertToRandom")) do
			local mod = value.mod
			local effVal = mod.value / 3
			if physMode == "AVERAGE" then
				skillModList:NewMod("PhysicalDamageConvertToFire", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
				skillModList:NewMod("PhysicalDamageConvertToCold", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
				skillModList:NewMod("PhysicalDamageConvertToLightning", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "FIRE" then
				skillModList:NewMod("PhysicalDamageConvertToFire", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "COLD" then
				skillModList:NewMod("PhysicalDamageConvertToCold", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "LIGHTNING" then
				skillModList:NewMod("PhysicalDamageConvertToLightning", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			end
		end
		for i, value in ipairs(skillModList:Tabulate("BASE", skillCfg, "PhysicalDamageGainAsColdOrLightning")) do
			local mod = value.mod
			local effVal = mod.value / 2
			if physMode == "AVERAGE" or physMode == "FIRE" then
				skillModList:NewMod("PhysicalDamageGainAsCold", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
				skillModList:NewMod("PhysicalDamageGainAsLightning", "BASE", effVal, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "COLD" then
				skillModList:NewMod("PhysicalDamageGainAsCold", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			elseif physMode == "LIGHTNING" then
				skillModList:NewMod("PhysicalDamageGainAsLightning", "BASE", mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			end
		end
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
			skillModList:NewMod("Damage", "MORE", 100, "Far Shot", bor(ModFlag.Attack, ModFlag.Projectile), { type = "DistanceRamp", ramp = {{10, -0.2}, {35, 0}, {70, 0.6}} })
		end
		if skillModList:Flag(skillCfg, "NoAdditionalProjectiles") then
			output.ProjectileCount = 1
		else
			local projBase = skillModList:Sum("BASE", skillCfg, "ProjectileCount")
			local projMore = skillModList:More(skillCfg, "ProjectileCount")
			output.ProjectileCount = m_floor(projBase * projMore)
		end
		if skillModList:Flag(skillCfg, "AdditionalProjectilesAddBouncesInstead") then
			local projBase = skillModList:Sum("BASE", skillCfg, "ProjectileCount") + skillModList:Sum("BASE", skillCfg, "BounceCount") - 1
			local projMore = skillModList:More(skillCfg, "ProjectileCount")
			output.BounceCount = m_floor(projBase * projMore) 
		end
		if skillModList:Flag(skillCfg, "CannotFork") then
			output.ForkCountString = "Cannot fork"
		elseif skillModList:Flag(skillCfg, "ForkOnce") then
			skillFlags.forking = true
			if skillModList:Flag(skillCfg, "ForkTwice") then
				output.ForkCountMax = m_min(skillModList:Sum("BASE", skillCfg, "ForkCountMax"), 2)
			else
				output.ForkCountMax = m_min(skillModList:Sum("BASE", skillCfg, "ForkCountMax"), 1)
			end
			output.ForkedCount = m_min(output.ForkCountMax, skillModList:Sum("BASE", skillCfg, "ForkedCount"))
			output.ForkCountString = output.ForkCountMax
			output.ForkRemaining = m_max(0, output.ForkCountMax - output.ForkedCount)
		else
			output.ForkCountString = "0"
		end
		if skillModList:Flag(skillCfg, "CannotPierce") then
			output.PierceCount = 0
			output.PierceCountString = "Cannot pierce"
		else
			if skillModList:Flag(skillCfg, "PierceAllTargets") or enemyDB:Flag(nil, "AlwaysPierceSelf") then
				output.PierceCount = 100
				output.PierceCountString = "All targets"
			else
				output.PierceCount = skillModList:Sum("BASE", skillCfg, "PierceCount")
				output.PierceCountString = output.PierceCount
			end
			if output.PierceCount > 0 then
				skillFlags.piercing = true
			end
			output.PiercedCount = m_min(output.PierceCount, skillModList:Sum("BASE", skillCfg, "PiercedCount"))
		end
		output.ProjectileSpeedMod = calcLib.mod(skillModList, skillCfg, "ProjectileSpeed")
		if breakdown then
			breakdown.ProjectileSpeedMod = breakdown.mod(skillModList, skillCfg, "ProjectileSpeed")
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
		calcAreaOfEffect(skillModList, skillCfg, skillData, skillFlags, output, breakdown)
	end
	if activeSkill.skillTypes[SkillType.Aura] then
		output.AuraEffectMod = calcLib.mod(skillModList, skillCfg, "AuraEffect")
		if breakdown then
			breakdown.AuraEffectMod = breakdown.mod(skillModList, skillCfg, "AuraEffect")
		end
	end
	if activeSkill.skillTypes[SkillType.HasReservation] then
		for _, pool in ipairs({"Life", "Mana"}) do
			output[pool .. "ReservedMod"] = calcLib.mod(skillModList, skillCfg, pool .. "Reserved", "Reserved") * calcLib.mod(skillModList, skillCfg, "SupportManaMultiplier") / calcLib.mod(skillModList, skillCfg, pool .. "ReservationEfficiency", "ReservationEfficiency")
			if breakdown then
				local inc = skillModList:Sum("INC", skillCfg, pool .. "Reserved", "Reserved", "SupportManaMultiplier")
				local more = skillModList:More(skillCfg, pool .. "Reserved", "Reserved", "SupportManaMultiplier")
				if inc ~= 0 and more ~= 1 then
					breakdown[pool .. "ReservedMod"] = {
						s_format("%.2f ^8(increased/reduced)", 1 + inc/100),
						s_format("x %.2f ^8(more/less)", more),
						s_format("/ %.2f ^8(reservation efficiency)", calcLib.mod(skillModList, skillCfg, pool .. "ReservationEfficiency", "ReservationEfficiency")),
						s_format("= %.2f", output[pool .. "ReservedMod"]),
					}
				end
			end
		end
	end
	if activeSkill.skillTypes[SkillType.Hex] or activeSkill.skillTypes[SkillType.Mark]then
		output.CurseEffectMod = calcLib.mod(skillModList, skillCfg, "CurseEffect")
		if breakdown then
			breakdown.CurseEffectMod = breakdown.mod(skillModList, skillCfg, "CurseEffect")
		end
	end
	if skillFlags.trap then
		local baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "TrapThrowingTime")
		local timeMod = calcLib.mod(skillModList, skillCfg, "SkillTrapThrowingTime")
		if timeMod > 0 then
			baseSpeed = baseSpeed * (1 / timeMod)
		end
		output.TrapThrowingSpeed = baseSpeed * calcLib.mod(skillModList, skillCfg, "TrapThrowingSpeed") * output.ActionSpeedMod
		output.TrapThrowingSpeed = m_min(output.TrapThrowingSpeed, data.misc.ServerTickRate)
		output.TrapThrowingTime = 1 / output.TrapThrowingSpeed
		skillData.timeOverride = output.TrapThrowingTime
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
		local incArea, moreArea = calcLib.mods(skillModList, skillCfg, "TrapTriggerAreaOfEffect")
		local areaMod = round(round(incArea * moreArea, 10), 2)
		output.TrapTriggerRadius = calcRadius(data.misc.TrapTriggerRadiusBase, areaMod)
		if breakdown then
			local incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint = calcRadiusBreakpoints(data.misc.TrapTriggerRadiusBase, incArea, moreArea)
			breakdown.TrapTriggerRadius = breakdown.area(data.misc.TrapTriggerRadiusBase, areaMod, output.TrapTriggerRadius, incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint)
		end
	elseif skillData.cooldown then
		output.Cooldown = calcSkillCooldown(skillModList, skillCfg, skillData)
		if breakdown then
			breakdown.Cooldown = {
				s_format("%.2fs ^8(base)", skillData.cooldown + skillModList:Sum("BASE", skillCfg, "CooldownRecovery")),
				s_format("/ %.2f ^8(increased/reduced cooldown recovery)", 1 + skillModList:Sum("INC", skillCfg, "CooldownRecovery") / 100),
				s_format("rounded up to nearest server tick"),
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
		output.MineLayingSpeed = m_min(output.MineLayingSpeed, data.misc.ServerTickRate)
		output.MineLayingTime = 1 / output.MineLayingSpeed
		skillData.timeOverride = output.MineLayingTime
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

		local incArea, moreArea = calcLib.mods(skillModList, skillCfg, "MineDetonationAreaOfEffect")
		local areaMod = round(round(incArea * moreArea, 10), 2)
		output.MineDetonationRadius = calcRadius(data.misc.MineDetonationRadiusBase, areaMod)
		if breakdown then
			local incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint = calcRadiusBreakpoints(data.misc.MineDetonationRadiusBase, incArea, moreArea)
			breakdown.MineDetonationRadius = breakdown.area(data.misc.MineDetonationRadiusBase, areaMod, output.MineDetonationRadius, incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint)
		end
		if activeSkill.skillTypes[SkillType.Aura] then
			output.MineAuraRadius = calcRadius(data.misc.MineAuraRadiusBase, output.AreaOfEffectMod)
			if breakdown then
				local incArea, moreArea = calcLib.mods(skillModList, skillCfg, "AreaOfEffect")
				local incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint = calcRadiusBreakpoints(data.misc.MineAuraRadiusBase, incArea, moreArea)
				breakdown.MineAuraRadius = breakdown.area(data.misc.MineAuraRadiusBase, output.AreaOfEffectMod, output.MineAuraRadius, incAreaBreakpoint, moreAreaBreakpoint, redAreaBreakpoint, lessAreaBreakpoint)
			end
		end
	end
	if skillFlags.totem then
		if skillFlags.ballista then
			baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "BallistaPlacementTime")
		else
			baseSpeed = 1 / skillModList:Sum("BASE", skillCfg, "TotemPlacementTime")
		end
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
		output.ActiveTotemLimit = skillModList:Sum("BASE", skillCfg, "ActiveTotemLimit", "ActiveBallistaLimit")
		output.TotemsSummoned = env.modDB:Override(nil, "TotemsSummoned") or output.ActiveTotemLimit
		if breakdown then
			breakdown.ActiveTotemLimit = {
				"Totems Summoned: "..output.TotemsSummoned..(env.configInput.TotemsSummoned and " ^8(overridden from the Configuration tab)" or " ^8(can be overridden in the Configuration tab)"),
			}
		end
		output.TotemLifeMod = calcLib.mod(skillModList, skillCfg, "TotemLife")
		output.TotemLife = round(m_floor(env.data.monsterAllyLifeTable[skillData.totemLevel] * env.data.totemLifeMult[activeSkill.skillTotemId]) * output.TotemLifeMod)
		if breakdown then
			breakdown.TotemLifeMod = breakdown.mod(skillModList, skillCfg, "TotemLife")
			breakdown.TotemLife = {
				"Totem level: "..skillData.totemLevel,
				env.data.monsterAllyLifeTable[skillData.totemLevel].." ^8(base life for a level "..skillData.totemLevel.." monster)",
				"x "..env.data.totemLifeMult[activeSkill.skillTotemId].." ^8(life multiplier for this totem type)",
				"x "..output.TotemLifeMod.." ^8(totem life modifier)",
				"= "..output.TotemLife,
			}
		end
	end
	if skillFlags.brand then
		output.BrandAttachmentRange = calcLib.mod(skillModList, skillCfg, "BrandAttachmentRange")
		output.ActiveBrandLimit = skillModList:Sum("BASE", skillCfg, "ActiveBrandLimit")
	end
	
	if skillFlags.warcry then
		output.WarcryCastTime = calcWarcryCastTime(skillModList, skillCfg, actor)
	end

	-- Skill duration
	local debuffDurationMult = 1
	if env.mode_effective then
		debuffDurationMult = 1 / m_max(data.misc.BuffExpirationSlowCap, calcLib.mod(enemyDB, skillCfg, "BuffExpireFaster"))
	end
	do
		output.DurationMod = calcLib.mod(skillModList, skillCfg, "Duration", "PrimaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
		if breakdown then
			breakdown.DurationMod = breakdown.mod(skillModList, skillCfg, "Duration", "PrimaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
			if breakdown.DurationMod and skillData.durationSecondary then
				t_insert(breakdown.DurationMod, 1, "Primary duration:")
			end
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
				breakdown.SecondaryDurationMod = breakdown.mod(skillModList, skillCfg, "Duration", "SecondaryDuration", "SkillAndDamagingAilmentDuration", skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
				if breakdown.SecondaryDurationMod then
					t_insert(breakdown.SecondaryDurationMod, 1, "Secondary duration:")
				end
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

	-- Calculate costs (may be slightly off due to rounding differences)
	local names = {
		["Mana"] = "mana",
		["Life"] = "life",
		["ES"] = "energy shield",
		["Rage"] = "rage",
		["ManaPercent"] = "mana",
		["LifePercent"] = "life",
	}
	-- First pass to calculate base costs.  Used for cost conversion (e.g. Petrified Blood)
	for resource, name in pairs(names) do
		local base = skillModList:Sum("BASE", skillCfg, resource.."CostBase")
		local cost = base + (activeSkill.activeEffect.grantedEffectLevel.cost[resource] or 0)
		if resource == "Mana" and skillData.baseManaCostIsAtLeastPercentUnreservedMana then
			cost = m_max(cost, m_floor((output.ManaUnreserved or 0) * skillData.baseManaCostIsAtLeastPercentUnreservedMana / 100))
		end
		output[resource.."Cost"] = cost
	end
	if skillModList:Flag(skillCfg, "CostLifeInsteadOfMana") then
		output["LifeCost"] = output["LifeCost"] + output["ManaCost"]
		output["ManaCost"] = 0
	end
	if skillModList:Sum("BASE", skillCfg, "ManaCostAsLifeCost") then
		output["LifeCost"] = output["LifeCost"] + output["ManaCost"] * skillModList:Sum("BASE", skillCfg, "ManaCostAsLifeCost") / 100
	end
	for resource, name in pairs(names) do
		local percent = resource == "ManaPercent" or resource == "LifePercent"
		do
			local mult = m_floor(skillModList:More(skillCfg, "SupportManaMultiplier") * 100 + 0.0001) / 100
			local more, inc
			if percent then
				more = m_floor(skillModList:More(skillCfg, resource.."Cost", resource:gsub("Percent", "").."Cost", "Cost") * 100 + 0.0001) / 100
				inc = skillModList:Sum("INC", skillCfg, resource.."Cost", resource:gsub("Percent", "").."Cost", "Cost")
			else
				more = m_floor(skillModList:More(skillCfg, resource.."Cost", "Cost") * 100 + 0.0001) / 100
				inc = skillModList:Sum("INC", skillCfg, resource.."Cost", "Cost")
			end
			local total = skillModList:Sum("BASE", skillCfg, resource.."Cost")
			local baseCost = output[resource.."Cost"]
			output[resource.."Cost"] = m_floor(output[resource.."Cost"] * mult)
			output[resource.."Cost"] = m_floor(m_abs(inc / 100) * output[resource.."Cost"]) * (inc >= 0 and 1 or -1) + output[resource.."Cost"]
			output[resource.."Cost"] = m_floor(m_abs(more - 1) * output[resource.."Cost"]) * (more >= 1 and 1 or -1) + output[resource.."Cost"]
			output[resource.."Cost"] = m_max(0, m_floor(output[resource.."Cost"] + total))
			if skillFlags.totem then
				local reservedFlat = activeSkill.skillData[name.."ReservationFlat"] or activeSkill.activeEffect.grantedEffectLevel[name.."ReservationFlat"] or 0
				output[resource.."Cost"] = output[resource.."Cost"] + reservedFlat
				local reservedPercent = activeSkill.skillData[name.."ReservationPercent"] or activeSkill.activeEffect.grantedEffectLevel[name.."ReservationPercent"] or 0
				if reservedPercent ~= 0 then
					skillModList:NewMod(resource.."PercentCostBase", "BASE", reservedPercent, "Totem Reservation")
				end
			end
			if breakdown and output[resource.."Cost"] ~= baseCost then
				breakdown[resource.."Cost"] = {
					s_format("%.2f"..(percent and "%%" or "").." ^8(base "..name.." cost)", baseCost)
				}
				if mult ~= 1 then
					t_insert(breakdown[resource.."Cost"], s_format("x %.2f ^8(cost multiplier)", mult))
				end
				if inc ~= 0 then
					t_insert(breakdown[resource.."Cost"], s_format("x %.2f ^8(increased/reduced "..name.." cost)", 1 + inc/100))
				end
				if more ~= 1 then
					t_insert(breakdown[resource.."Cost"], s_format("x %.2f ^8(more/less "..name.." cost)", more))
				end
				if total ~= 0 then
					t_insert(breakdown[resource.."Cost"], s_format("- %d ^8(- "..name.." cost)", -total))
				end
				t_insert(breakdown[resource.."Cost"], s_format("= %d"..(percent and "%%" or ""), output[resource.."Cost"]))
			end
		end
	end

	-- account for Sacrificial Zeal
	-- Note: Sacrificial Zeal grants Added Spell Physical Damage equal to 25% of the Skill's Mana Cost, and causes you to take Physical Damage over Time, for 4 seconds
	if skillModList:Flag(nil, "Condition:SacrificialZeal") then
		local multiplier = 0.25
		skillModList:NewMod("PhysicalMin", "BASE", m_floor(output.ManaCost * multiplier), "Sacrificial Zeal", ModFlag.Spell)
		skillModList:NewMod("PhysicalMax", "BASE", m_floor(output.ManaCost * multiplier), "Sacrificial Zeal", ModFlag.Spell)
	end

	runSkillFunc("preDamageFunc")

	-- Handle corpse explosions
	if skillData.explodeCorpse and (skillData.corpseLife or env.enemyLevel) then
		local localCorpseLife = skillData.corpseLife or data.monsterLifeTable[env.enemyLevel];
		local damageType = skillData.corpseExplosionDamageType or "Fire"
		skillData[damageType.."BonusMin"] = localCorpseLife * ( skillData.corpseExplosionLifeMultiplier or skillData.selfFireExplosionLifeMultiplier )
		skillData[damageType.."BonusMax"] = localCorpseLife * ( skillData.corpseExplosionLifeMultiplier or skillData.selfFireExplosionLifeMultiplier )
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
		local critOverride = skillModList:Override(skillCfg, "WeaponBaseCritChance")
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
			if skillData.CritChance then
				source.CritChance = skillData.CritChance
			end
			if skillData.setOffHandPhysicalMin and skillData.setOffHandPhysicalMax then
				source.PhysicalMin = skillData.setOffHandPhysicalMin
				source.PhysicalMax = skillData.setOffHandPhysicalMax
			end
			if skillData.attackTime then
				source.AttackRate = 1000 / skillData.attackTime
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

	local storedMainHandAccuracy = nil
	for _, pass in ipairs(passList) do
		local globalOutput, globalBreakdown = output, breakdown
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown
		
		-- Calculate hit chance 
		output.Accuracy = m_max(0, calcLib.val(skillModList, "Accuracy", cfg))
		if breakdown then
			breakdown.Accuracy = breakdown.simple(nil, cfg, output.Accuracy, "Accuracy")
		end
		if skillModList:Flag(nil, "Condition:OffHandAccuracyIsMainHandAccuracy") and pass.label == "Main Hand" then
			storedMainHandAccuracy = output.Accuracy
		elseif skillModList:Flag(nil, "Condition:OffHandAccuracyIsMainHandAccuracy") and pass.label == "Off Hand" and storedMainHandAccuracy then
			output.Accuracy = storedMainHandAccuracy
			if breakdown then
				breakdown.Accuracy = {
					"Using Main Hand Accuracy due to Mastery: "..output.Accuracy,
				}
			end
		end
		if not isAttack or skillModList:Flag(cfg, "CannotBeEvaded") or skillData.cannotBeEvaded or (env.mode_effective and enemyDB:Flag(nil, "CannotEvade")) then
			output.HitChance = 100
		else
			local enemyEvasion = round(calcLib.val(enemyDB, "Evasion"))
			output.HitChance = calcs.hitChance(enemyEvasion, output.Accuracy) * calcLib.mod(skillModList, cfg, "HitChance")
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
		elseif skillData.triggerTime and skillData.triggered then
			local activeSkillsLinked = skillModList:Sum("BASE", cfg, "ActiveSkillsLinkedToTrigger")
			if activeSkillsLinked > 0 then
				output.Time = skillData.triggerTime / (1 + skillModList:Sum("INC", cfg, "CooldownRecovery") / 100) * activeSkillsLinked
			else
				output.Time = skillData.triggerTime / (1 + skillModList:Sum("INC", cfg, "CooldownRecovery") / 100)
			end
			output.TriggerTime = output.Time
			output.Speed = 1 / output.Time
		elseif skillData.triggerRate and skillData.triggered then
			output.Time = 1 / skillData.triggerRate
			output.TriggerTime = output.Time
			output.Speed = skillData.triggerRate
			skillData.showAverage = false
		elseif skillData.triggeredByBrand and skillData.triggered then
			output.Time = 1 / (1 + skillModList:Sum("INC", cfg, "Speed", "BrandActivationFrequency") / 100) / skillModList:More(cfg, "BrandActivationFrequency") * (skillModList:Sum("BASE", cfg, "ArcanistSpellsLinked") or 1)
			output.TriggerTime = output.Time
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
			output.CastRate = output.Speed
			output.Repeats = 1 + (skillModList:Sum("BASE", cfg, "RepeatCount") or 0)
			if skillFlags.selfCast then
				-- Self-cast skill; apply action speed
				output.Speed = output.Speed * globalOutput.ActionSpeedMod
				output.CastRate = output.Speed
			end
			if output.Cooldown then
				output.Speed = m_min(output.Speed, 1 / output.Cooldown * output.Repeats)
			end
			if output.Cooldown and skillFlags.selfCast then
				skillFlags.notAverage = true
				skillFlags.showAverage = false
				skillData.showAverage = false
			end
			if not activeSkill.skillTypes[SkillType.Channel] then
				output.Speed = m_min(output.Speed, data.misc.ServerTickRate * output.Repeats)
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
					total = s_format("= %.2f ^8casts per second", output.CastRate)
				})
				if output.Cooldown and (1 / output.Cooldown) < output.CastRate then
					t_insert(breakdown.Speed, s_format("\n"))
					t_insert(breakdown.Speed, s_format("1 / %.2f ^8(skill cooldown)", output.Cooldown))
					if output.Repeats > 1 then
						t_insert(breakdown.Speed, s_format("x %d ^8(repeat count)", output.Repeats))
					end
					t_insert(breakdown.Speed, s_format("= %.2f ^8(casts per second)", output.Repeats / output.Cooldown))
					t_insert(breakdown.Speed, s_format("\n"))
					t_insert(breakdown.Speed, s_format("= %.2f ^8(lower of cast rates)", output.Speed))
				end
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
		if skillData.hitTimeOverride and not skillData.triggeredOnDeath then
			output.HitTime = skillData.hitTimeOverride
			output.HitSpeed = 1 / output.HitTime
			--Brands always have hitTimeOverride
			if skillFlags.brand then
				output.BrandTicks = m_floor(output.Duration * output.HitSpeed)
			end
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
		if output.Time > 1 then
			modDB:NewMod("Condition:OneSecondAttackTime", "FLAG", true)
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

	-- Grab quantity multiplier
	local quantityMultiplier = m_max(activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "QuantityMultiplier"), 1)
	if quantityMultiplier > 1 then
		output.QuantityMultiplier = quantityMultiplier
	end

	for _, pass in ipairs(passList) do
		local globalOutput, globalBreakdown = output, breakdown
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown

		-- Exerted Attack members
		local exertedDoubleDamage = env.modDB:Sum("BASE", cfg, "ExertDoubleDamageChance")
		globalOutput.OffensiveWarcryEffect = 1
		globalOutput.MaxOffensiveWarcryEffect = 1
		globalOutput.TheoreticalOffensiveWarcryEffect = 1
		globalOutput.TheoreticalMaxOffensiveWarcryEffect = 1
		globalOutput.SeismicHitEffect = 1
		globalOutput.RallyingHitEffect = 1
		globalOutput.AilmentWarcryEffect = 1

		if env.mode_buffs then
			-- Iterative over all the active skills to account for exerted attacks provided by warcries
			if (activeSkill.activeEffect.grantedEffect.name == "Vaal Ground Slam" or not activeSkill.skillTypes[SkillType.Vaal]) and not activeSkill.skillTypes[SkillType.Channel] and not activeSkill.skillModList:Flag(cfg, "SupportedByMultistrike") then
				for index, value in ipairs(actor.activeSkillList) do
					if value.activeEffect.grantedEffect.name == "Ancestral Cry" and activeSkill.skillTypes[SkillType.MeleeSingleTarget] and not globalOutput.AncestralCryCalculated then
						globalOutput.AncestralCryDuration = calcSkillDuration(value.skillModList, value.skillCfg, value.skillData, env, enemyDB)
						globalOutput.AncestralCryCooldown = calcSkillCooldown(value.skillModList, value.skillCfg, value.skillData)
						output.GlobalWarcryCooldown = env.modDB:Sum("BASE", nil, "GlobalWarcryCooldown")
						output.GlobalWarcryCount = env.modDB:Sum("BASE", nil, "GlobalWarcryCount")
						if modDB:Flag(nil, "WarcryShareCooldown") then
							globalOutput.AncestralCryCooldown = globalOutput.AncestralCryCooldown + (output.GlobalWarcryCooldown - globalOutput.AncestralCryCooldown) / output.GlobalWarcryCount
						end
						globalOutput.AncestralCryCastTime = calcWarcryCastTime(value.skillModList, value.skillCfg, actor)
						globalOutput.AncestralExertsCount = env.modDB:Sum("BASE", nil, "NumAncestralExerts") or 0
						local baseUptimeRatio = m_min((globalOutput.AncestralExertsCount / output.Speed) / (globalOutput.AncestralCryCooldown + globalOutput.AncestralCryCastTime), 1) * 100
						local additionalCooldownUses = value.skillModList:Sum("BASE", value.skillCfg, "AdditionalCooldownUses")
						globalOutput.AncestralUpTimeRatio = m_min(100, baseUptimeRatio * (additionalCooldownUses + 1))
						if globalBreakdown then
							globalBreakdown.AncestralUpTimeRatio = { }
							t_insert(globalBreakdown.AncestralUpTimeRatio, s_format("(%d ^8(number of exerts)", globalOutput.AncestralExertsCount))
							t_insert(globalBreakdown.AncestralUpTimeRatio, s_format("/ %.2f) ^8(attacks per second)", output.Speed))
							if globalOutput.AncestralCryCastTime > 0 then
								t_insert(globalBreakdown.AncestralUpTimeRatio, s_format("/ (%.2f ^8(warcry cooldown)", globalOutput.AncestralCryCooldown))
								t_insert(globalBreakdown.AncestralUpTimeRatio, s_format("+ %.2f) ^8(warcry casttime)", globalOutput.AncestralCryCastTime))
							else
								t_insert(globalBreakdown.AncestralUpTimeRatio, s_format("/ %.2f ^8(average warcry cooldown)", globalOutput.AncestralCryCooldown))
							end
							t_insert(globalBreakdown.AncestralUpTimeRatio, s_format("= %d%%", globalOutput.AncestralUpTimeRatio))
						end
						globalOutput.AncestralCryCalculated = true
					elseif value.activeEffect.grantedEffect.name == "Infernal Cry" and not globalOutput.InfernalCryCalculated then
						globalOutput.InfernalCryDuration = calcSkillDuration(value.skillModList, value.skillCfg, value.skillData, env, enemyDB)
						globalOutput.InfernalCryCooldown = calcSkillCooldown(value.skillModList, value.skillCfg, value.skillData)
						output.GlobalWarcryCooldown = env.modDB:Sum("BASE", nil, "GlobalWarcryCooldown")
						output.GlobalWarcryCount = env.modDB:Sum("BASE", nil, "GlobalWarcryCount")
						if modDB:Flag(nil, "WarcryShareCooldown") then
							globalOutput.InfernalCryCooldown = globalOutput.InfernalCryCooldown + (output.GlobalWarcryCooldown - globalOutput.InfernalCryCooldown) / output.GlobalWarcryCount
						end
						globalOutput.InfernalCryCastTime = calcWarcryCastTime(value.skillModList, value.skillCfg, actor)
						if activeSkill.skillTypes[SkillType.Melee] then
							globalOutput.InfernalExertsCount = env.modDB:Sum("BASE", nil, "NumInfernalExerts") or 0
							local baseUptimeRatio = m_min((globalOutput.InfernalExertsCount / output.Speed) / (globalOutput.InfernalCryCooldown + globalOutput.InfernalCryCastTime), 1) * 100			
							local additionalCooldownUses = value.skillModList:Sum("BASE", value.skillCfg, "AdditionalCooldownUses")
							globalOutput.InfernalUpTimeRatio = m_min(100, baseUptimeRatio * (additionalCooldownUses + 1))
							if globalBreakdown then
								globalBreakdown.InfernalUpTimeRatio = { }
								t_insert(globalBreakdown.InfernalUpTimeRatio, s_format("(%d ^8(number of exerts)", globalOutput.InfernalExertsCount))
								t_insert(globalBreakdown.InfernalUpTimeRatio, s_format("/ %.2f) ^8(attacks per second)", output.Speed))
								if globalOutput.InfernalCryCastTime > 0 then
									t_insert(globalBreakdown.InfernalUpTimeRatio, s_format("/ (%.2f ^8(warcry cooldown)", globalOutput.InfernalCryCooldown))
									t_insert(globalBreakdown.InfernalUpTimeRatio, s_format("+ %.2f) ^8(warcry casttime)", globalOutput.InfernalCryCastTime))
								else
									t_insert(globalBreakdown.InfernalUpTimeRatio, s_format("/ %.2f ^8(average warcry cooldown)", globalOutput.InfernalCryCooldown))
								end
								t_insert(globalBreakdown.InfernalUpTimeRatio, s_format("= %d%%", globalOutput.InfernalUpTimeRatio))
							end
						end
						globalOutput.InfernalCryCalculated = true
					elseif value.activeEffect.grantedEffect.name == "Intimidating Cry" and activeSkill.skillTypes[SkillType.Melee] and not globalOutput.IntimidatingCryCalculated then
						globalOutput.CreateWarcryOffensiveCalcSection = true
						globalOutput.IntimidatingCryDuration = calcSkillDuration(value.skillModList, value.skillCfg, value.skillData, env, enemyDB)
						globalOutput.IntimidatingCryCooldown = calcSkillCooldown(value.skillModList, value.skillCfg, value.skillData)
						output.GlobalWarcryCooldown = env.modDB:Sum("BASE", nil, "GlobalWarcryCooldown")
						output.GlobalWarcryCount = env.modDB:Sum("BASE", nil, "GlobalWarcryCount")
						if modDB:Flag(nil, "WarcryShareCooldown") then
							globalOutput.IntimidatingCryCooldown = globalOutput.IntimidatingCryCooldown + (output.GlobalWarcryCooldown - globalOutput.IntimidatingCryCooldown) / output.GlobalWarcryCount
						end
						globalOutput.IntimidatingCryCastTime = calcWarcryCastTime(value.skillModList, value.skillCfg, actor)
						globalOutput.IntimidatingExertsCount = env.modDB:Sum("BASE", nil, "NumIntimidatingExerts") or 0
						local baseUptime = m_min((globalOutput.IntimidatingExertsCount / output.Speed) / (globalOutput.IntimidatingCryCooldown + globalOutput.IntimidatingCryCastTime), 1) * 100
						local additionalCooldownUses = value.skillModList:Sum("BASE", value.skillCfg, "AdditionalCooldownUses")
						globalOutput.IntimidatingUpTimeRatio = m_min(100, baseUptime * (additionalCooldownUses + 1))
						if globalBreakdown then
							globalBreakdown.IntimidatingUpTimeRatio = { }
							t_insert(globalBreakdown.IntimidatingUpTimeRatio, s_format("(%d ^8(number of exerts)", globalOutput.IntimidatingExertsCount))
							t_insert(globalBreakdown.IntimidatingUpTimeRatio, s_format("/ %.2f) ^8(attacks per second)", output.Speed))
							if 	globalOutput.IntimidatingCryCastTime > 0 then
								t_insert(globalBreakdown.IntimidatingUpTimeRatio, s_format("/ (%.2f ^8(warcry cooldown)", globalOutput.IntimidatingCryCooldown))
								t_insert(globalBreakdown.IntimidatingUpTimeRatio, s_format("+ %.2f) ^8(warcry casttime)", globalOutput.IntimidatingCryCastTime))
							else
								t_insert(globalBreakdown.IntimidatingUpTimeRatio, s_format("/ %.2f ^8(average warcry cooldown)", globalOutput.IntimidatingCryCooldown))
							end
							t_insert(globalBreakdown.IntimidatingUpTimeRatio, s_format("= %d%%", globalOutput.IntimidatingUpTimeRatio))
						end
						local ddChance = m_min(skillModList:Sum("BASE", cfg, "DoubleDamageChance") + (env.mode_effective and enemyDB:Sum("BASE", cfg, "SelfDoubleDamageChance") or 0) + exertedDoubleDamage, 100)
						globalOutput.IntimidatingAvgDmg = 2 * (1 - ddChance / 100) -- 1
						if globalBreakdown then
							globalBreakdown.IntimidatingAvgDmg = {
								s_format("Average Intimidating Cry Damage:"),
								s_format("%.2f%% ^8(base double damage increase to hit 100%%)", (1 - ddChance / 100) * 100 ),
								s_format("x %d ^8(double damage multiplier)", 2),
								s_format("= %.2f", globalOutput.IntimidatingAvgDmg),
							}
						end
						globalOutput.IntimidatingHitEffect = 1 + globalOutput.IntimidatingAvgDmg * globalOutput.IntimidatingUpTimeRatio / 100
						globalOutput.IntimidatingMaxHitEffect = 1 + globalOutput.IntimidatingAvgDmg
						if globalBreakdown then
							globalBreakdown.IntimidatingHitEffect = {
								s_format("1 + (%.2f ^8(average exerted damage)", globalOutput.IntimidatingAvgDmg),
								s_format("x %.2f) ^8(uptime %%)", globalOutput.IntimidatingUpTimeRatio / 100),
								s_format("= %.2f", globalOutput.IntimidatingHitEffect),
							}
						end

						globalOutput.TheoreticalOffensiveWarcryEffect = globalOutput.TheoreticalOffensiveWarcryEffect * globalOutput.IntimidatingHitEffect
						globalOutput.TheoreticalMaxOffensiveWarcryEffect = globalOutput.TheoreticalMaxOffensiveWarcryEffect * globalOutput.IntimidatingMaxHitEffect
						globalOutput.IntimidatingCryCalculated = true
					elseif value.activeEffect.grantedEffect.name == "Rallying Cry" and activeSkill.skillTypes[SkillType.Melee] and not globalOutput.RallyingCryCalculated then
						globalOutput.CreateWarcryOffensiveCalcSection = true
						globalOutput.RallyingCryDuration = calcSkillDuration(value.skillModList, value.skillCfg, value.skillData, env, enemyDB)
						globalOutput.RallyingCryCooldown = calcSkillCooldown(value.skillModList, value.skillCfg, value.skillData)
						output.GlobalWarcryCooldown = env.modDB:Sum("BASE", nil, "GlobalWarcryCooldown")
						output.GlobalWarcryCount = env.modDB:Sum("BASE", nil, "GlobalWarcryCount")
						if modDB:Flag(nil, "WarcryShareCooldown") then
							globalOutput.RallyingCryCooldown = globalOutput.RallyingCryCooldown + (output.GlobalWarcryCooldown - globalOutput.RallyingCryCooldown) / output.GlobalWarcryCount
						end
						globalOutput.RallyingCryCastTime = calcWarcryCastTime(value.skillModList, value.skillCfg, actor)
						globalOutput.RallyingExertsCount = env.modDB:Sum("BASE", nil, "NumRallyingExerts") or 0
						local baseUptimeRatio = m_min((globalOutput.RallyingExertsCount / output.Speed) / (globalOutput.RallyingCryCooldown + globalOutput.RallyingCryCastTime), 1) * 100
						local additionalCooldownUses = value.skillModList:Sum("BASE", value.skillCfg, "AdditionalCooldownUses")
						globalOutput.RallyingUpTimeRatio = m_min(100, baseUptimeRatio * (additionalCooldownUses + 1))
						if globalBreakdown then
							globalBreakdown.RallyingUpTimeRatio = { }
							t_insert(globalBreakdown.RallyingUpTimeRatio, s_format("(%d ^8(number of exerts)", globalOutput.RallyingExertsCount))
							t_insert(globalBreakdown.RallyingUpTimeRatio, s_format("/ %.2f) ^8(attacks per second)", output.Speed))
							if 	globalOutput.RallyingCryCastTime > 0 then
								t_insert(globalBreakdown.RallyingUpTimeRatio, s_format("/ (%.2f ^8(warcry cooldown)", globalOutput.RallyingCryCooldown))
								t_insert(globalBreakdown.RallyingUpTimeRatio, s_format("+ %.2f) ^8(warcry casttime)", globalOutput.RallyingCryCastTime))
							else
								t_insert(globalBreakdown.RallyingUpTimeRatio, s_format("/ %.2f ^8(average warcry cooldown)", globalOutput.RallyingCryCooldown))
							end
							t_insert(globalBreakdown.RallyingUpTimeRatio, s_format("= %d%%", globalOutput.RallyingUpTimeRatio))
						end
						globalOutput.RallyingAvgDmg = m_min(env.modDB:Sum("BASE", cfg, "Multiplier:NearbyAlly"), 5) * (env.modDB:Sum("BASE", nil, "RallyingExertMoreDamagePerAlly") / 100)
						if globalBreakdown then
							globalBreakdown.RallyingAvgDmg = {
								s_format("Average Rallying Cry Damage:"),
								s_format("%.2f ^8(average damage multiplier per ally)", env.modDB:Sum("BASE", nil, "RallyingExertMoreDamagePerAlly") / 100),
								s_format("x %d ^8(number of nearby allies (max=5))", m_min(env.modDB:Sum("BASE", cfg, "Multiplier:NearbyAlly"), 5)),
								s_format("= %.2f", globalOutput.RallyingAvgDmg),
							}
						end
						globalOutput.RallyingHitEffect = 1 + globalOutput.RallyingAvgDmg * globalOutput.RallyingUpTimeRatio / 100
						globalOutput.RallyingMaxHitEffect = 1 + globalOutput.RallyingAvgDmg
						if globalBreakdown then
							globalBreakdown.RallyingHitEffect = {
								s_format("1 + (%.2f ^8(average exerted damage)", globalOutput.RallyingAvgDmg),
								s_format("x %.2f) ^8(uptime %%)", globalOutput.RallyingUpTimeRatio / 100),
								s_format("= %.2f", globalOutput.RallyingHitEffect),
							}
						end
						globalOutput.OffensiveWarcryEffect = globalOutput.OffensiveWarcryEffect * globalOutput.RallyingHitEffect
						globalOutput.MaxOffensiveWarcryEffect = globalOutput.MaxOffensiveWarcryEffect * globalOutput.RallyingMaxHitEffect
						globalOutput.TheoreticalOffensiveWarcryEffect = globalOutput.TheoreticalOffensiveWarcryEffect * globalOutput.RallyingHitEffect
						globalOutput.TheoreticalMaxOffensiveWarcryEffect = globalOutput.TheoreticalMaxOffensiveWarcryEffect * globalOutput.RallyingMaxHitEffect
						globalOutput.RallyingCryCalculated = true

					elseif value.activeEffect.grantedEffect.name == "Seismic Cry" and activeSkill.skillTypes[SkillType.Slam] and not globalOutput.SeismicCryCalculated then
						globalOutput.CreateWarcryOffensiveCalcSection = true
						globalOutput.SeismicCryDuration = calcSkillDuration(value.skillModList, value.skillCfg, value.skillData, env, enemyDB)
						globalOutput.SeismicCryCooldown = calcSkillCooldown(value.skillModList, value.skillCfg, value.skillData)
						output.GlobalWarcryCooldown = env.modDB:Sum("BASE", nil, "GlobalWarcryCooldown")
						output.GlobalWarcryCount = env.modDB:Sum("BASE", nil, "GlobalWarcryCount")
						if modDB:Flag(nil, "WarcryShareCooldown") then
							globalOutput.SeismicCryCooldown = globalOutput.SeismicCryCooldown + (output.GlobalWarcryCooldown - globalOutput.SeismicCryCooldown) / output.GlobalWarcryCount
						end
						globalOutput.SeismicCryCastTime = calcWarcryCastTime(value.skillModList, value.skillCfg, actor)
						globalOutput.SeismicExertsCount = env.modDB:Sum("BASE", nil, "NumSeismicExerts") or 0
						local baseUptimeRatio = m_min((globalOutput.SeismicExertsCount / output.Speed) / (globalOutput.SeismicCryCooldown + globalOutput.SeismicCryCastTime), 1) * 100
						local additionalCooldownUses = value.skillModList:Sum("BASE", value.skillCfg, "AdditionalCooldownUses")
						globalOutput.SeismicUpTimeRatio = m_min(100, baseUptimeRatio * (additionalCooldownUses + 1))
						if globalBreakdown then
							globalBreakdown.SeismicUpTimeRatio = { }
							t_insert(globalBreakdown.SeismicUpTimeRatio, s_format("(%d ^8(number of exerts)", globalOutput.SeismicExertsCount))
							t_insert(globalBreakdown.SeismicUpTimeRatio, s_format("/ %.2f) ^8(attacks per second)", output.Speed))
							if 	globalOutput.SeismicCryCastTime > 0 then
								t_insert(globalBreakdown.SeismicUpTimeRatio, s_format("/ (%.2f ^8(warcry cooldown)", globalOutput.SeismicCryCooldown))
								t_insert(globalBreakdown.SeismicUpTimeRatio, s_format("+ %.2f) ^8(warcry casttime)", globalOutput.SeismicCryCastTime))
							else
								t_insert(globalBreakdown.SeismicUpTimeRatio, s_format("/ %.2f ^8(average warcry cooldown)", globalOutput.SeismicCryCooldown))
							end
							t_insert(globalBreakdown.SeismicUpTimeRatio, s_format("= %d%%", globalOutput.SeismicUpTimeRatio))
						end
						-- calculate the stacking MORE dmg modifier of Seismic slams
						local SeismicMoreDmgAndAoEPerExert = env.modDB:Sum("BASE", cfg, "SeismicMoreDmgPerExert") / 100
						local TotalSeismicDmgImpact = 0
						local ThisSeismicDmgImpact = 0
						local LastSeismicImpact = 0
						local AoEImpact = 0
						local MaxSingleHitDmgImpact = 0
						local MaxSingleAoEImpact = 0
						for i = 1, globalOutput.SeismicExertsCount do
							ThisSeismicDmgImpact = SeismicMoreDmgAndAoEPerExert + (1 + SeismicMoreDmgAndAoEPerExert) * LastSeismicImpact
							MaxSingleHitDmgImpact = m_max(MaxSingleHitDmgImpact, ThisSeismicDmgImpact)
							LastSeismicImpact = LastSeismicImpact + SeismicMoreDmgAndAoEPerExert
							TotalSeismicDmgImpact = TotalSeismicDmgImpact + ThisSeismicDmgImpact
							AoEImpact = AoEImpact + (i * SeismicMoreDmgAndAoEPerExert)
							MaxSingleAoEImpact = MaxSingleAoEImpact + SeismicMoreDmgAndAoEPerExert
						end
						globalOutput.SeismicAvgDmg = (TotalSeismicDmgImpact / globalOutput.SeismicExertsCount)
						local AvgAoEImpact = AoEImpact / globalOutput.SeismicExertsCount
						if globalBreakdown then
							globalBreakdown.SeismicAvgDmg = {
								s_format("%.2f ^8(total seismic damage multiplier across all exerts)", TotalSeismicDmgImpact),
								s_format("Average Seismic Damage:"),
								s_format("(%.2f ^8(average damage multiplier per exert)", TotalSeismicDmgImpact / globalOutput.SeismicExertsCount),
								s_format("= %.2f", globalOutput.SeismicAvgDmg),
							}
						end
						globalOutput.SeismicHitEffect = 1 + globalOutput.SeismicAvgDmg * globalOutput.SeismicUpTimeRatio / 100
						globalOutput.SeismicMaxHitEffect = 1 + MaxSingleHitDmgImpact
						if globalBreakdown then
							globalBreakdown.SeismicHitEffect = {
								s_format("1 + (%.2f ^8(average exerted damage)", globalOutput.SeismicAvgDmg),
								s_format("x %.2f) ^8(uptime %%)", globalOutput.SeismicUpTimeRatio / 100),
								s_format("= %.2f", globalOutput.SeismicHitEffect),
							}
						end
						globalOutput.OffensiveWarcryEffect = globalOutput.OffensiveWarcryEffect * globalOutput.SeismicHitEffect
						globalOutput.MaxOffensiveWarcryEffect = globalOutput.MaxOffensiveWarcryEffect * globalOutput.SeismicMaxHitEffect
						globalOutput.TheoreticalOffensiveWarcryEffect = globalOutput.TheoreticalOffensiveWarcryEffect * globalOutput.SeismicHitEffect
						globalOutput.TheoreticalMaxOffensiveWarcryEffect = globalOutput.TheoreticalMaxOffensiveWarcryEffect * globalOutput.SeismicMaxHitEffect

						-- account for AoE increase
						if activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
							skillModList:NewMod("AreaOfEffect", "INC", MaxSingleAoEImpact * 100, "Max Seismic Exert AoE")
						else
							skillModList:NewMod("AreaOfEffect", "INC", m_floor(AvgAoEImpact * globalOutput.SeismicUpTimeRatio), "Avg Seismic Exert AoE")
						end
						calcAreaOfEffect(skillModList, skillCfg, skillData, skillFlags, globalOutput, globalBreakdown)
						globalOutput.SeismicCryCalculated = true
					end
				end

				if activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
					globalOutput.AilmentWarcryEffect = globalOutput.MaxOffensiveWarcryEffect
					skillData.showAverage = true
					skillFlags.showAverage = true
					skillFlags.notAverage = false
				else
					globalOutput.AilmentWarcryEffect = globalOutput.OffensiveWarcryEffect
				end

				-- Calculate Exerted Attack Uptime
				-- There are various strategies a player could use to maximize either warcry effect stacking or staggering
				-- 1) they don't pay attention and therefore we calculated exerted attack uptime as just the maximum uptime of any enabled warcries that exert attacks
				globalOutput.ExertedAttackUptimeRatio = m_max(m_max(m_max(globalOutput.AncestralUpTimeRatio or 0, globalOutput.InfernalUpTimeRatio or 0), m_max(globalOutput.IntimidatingUpTimeRatio or 0, globalOutput.RallyingUpTimeRatio or 0)), globalOutput.SeismicUpTimeRatio or 0)
				if globalBreakdown then
					globalBreakdown.ExertedAttackUptimeRatio = { }
					t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("Maximum of:"))
					if globalOutput.AncestralUpTimeRatio then
						t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("%d%% ^8(Ancestral Cry Uptime)", globalOutput.AncestralUpTimeRatio or 0))
					end
					if globalOutput.InfernalUpTimeRatio then
						t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("%d%% ^8(Infernal Cry Uptime)", globalOutput.InfernalUpTimeRatio or 0))
					end
					if globalOutput.IntimidatingUpTimeRatio then
						t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("%d%% ^8(Intimidating Cry Uptime)", globalOutput.IntimidatingUpTimeRatio or 0))
					end
					if globalOutput.RallyingUpTimeRatio then
						t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("%d%% ^8(Rallying Cry Uptime)", globalOutput.RallyingUpTimeRatio or 0))
					end
					if globalOutput.SeismicUpTimeRatio then
						t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("%d%% ^8(Seismic Cry Uptime)", globalOutput.SeismicUpTimeRatio or 0))
					end
					t_insert(globalBreakdown.ExertedAttackUptimeRatio, s_format("= %d%%", globalOutput.ExertedAttackUptimeRatio))
				end
				if globalOutput.ExertedAttackUptimeRatio > 0 then
					local incExertedAttacks = skillModList:Sum("INC", cfg, "ExertIncrease")
					local moreExertedAttacks = skillModList:Sum("MORE", cfg, "ExertIncrease")
					if activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
						skillModList:NewMod("Damage", "INC", incExertedAttacks, "Exerted Attacks")
						skillModList:NewMod("Damage", "MORE", moreExertedAttacks, "Exerted Attacks")
					else
						skillModList:NewMod("Damage", "INC", incExertedAttacks * globalOutput.ExertedAttackUptimeRatio / 100, "Uptime Scaled Exerted Attacks")
						skillModList:NewMod("Damage", "MORE", moreExertedAttacks * globalOutput.ExertedAttackUptimeRatio / 100, "Uptime Scaled Exerted Attacks")
					end
					globalOutput.ExertedAttackAvgDmg = calcLib.mod(skillModList, skillCfg, "ExertIncrease")
					globalOutput.ExertedAttackHitEffect = globalOutput.ExertedAttackAvgDmg * globalOutput.ExertedAttackUptimeRatio / 100
					globalOutput.ExertedAttackMaxHitEffect = globalOutput.ExertedAttackAvgDmg
					if globalBreakdown then
						globalBreakdown.ExertedAttackHitEffect = {
							s_format("(%.2f ^8(average exerted damage)", globalOutput.ExertedAttackAvgDmg),
							s_format("x %.2f) ^8(uptime %%)", globalOutput.ExertedAttackUptimeRatio / 100),
							s_format("= %.2f", globalOutput.ExertedAttackHitEffect),
						}
					end
				end
			end
		end

		output.RuthlessBlowEffect = 1
		output.FistOfWarHitEffect = 1
		output.FistOfWarAilmentEffect = 1
		if env.mode_combat then
			-- Calculate Ruthless Blow chance/multipliers + Fist of War multipliers
			output.RuthlessBlowMaxCount = skillModList:Sum("BASE", cfg, "RuthlessBlowMaxCount")
			if output.RuthlessBlowMaxCount > 0 then
				output.RuthlessBlowChance = round(100 / output.RuthlessBlowMaxCount)
			else
				output.RuthlessBlowChance = 0
			end
			output.RuthlessBlowMultiplier = 1 + skillModList:Sum("BASE", cfg, "RuthlessBlowMultiplier") / 100
			output.RuthlessBlowEffect = 1 - output.RuthlessBlowChance / 100 + output.RuthlessBlowChance / 100 * output.RuthlessBlowMultiplier

			globalOutput.FistOfWarCooldown = skillModList:Sum("BASE", cfg, "FistOfWarCooldown") or 0
			-- If Fist of War & Active Skill is a Slam Skill & NOT a Vaal Skill
			if globalOutput.FistOfWarCooldown ~= 0 and activeSkill.skillTypes[SkillType.Slam] and not activeSkill.skillTypes[SkillType.Vaal] then
				globalOutput.FistOfWarHitMultiplier = skillModList:Sum("BASE", cfg, "FistOfWarHitMultiplier") / 100
				globalOutput.FistOfWarAilmentMultiplier = skillModList:Sum("BASE", cfg, "FistOfWarAilmentMultiplier") / 100
				globalOutput.FistOfWarUptimeRatio = m_min( (1 / output.Speed) / globalOutput.FistOfWarCooldown, 1) * 100
				if globalBreakdown then
					globalBreakdown.FistOfWarUptimeRatio = {
						s_format("min( (1 / %.2f) ^8(second per attack)", output.Speed),
						s_format("/ %.2f, 1) ^8(fist of war cooldown)", globalOutput.FistOfWarCooldown),
						s_format("= %d%%", globalOutput.FistOfWarUptimeRatio),
					}
				end
				globalOutput.AvgFistOfWarHit = globalOutput.FistOfWarHitMultiplier
				globalOutput.AvgFistOfWarHitEffect = 1 + globalOutput.FistOfWarHitMultiplier * (globalOutput.FistOfWarUptimeRatio / 100)
				if globalBreakdown then
					globalBreakdown.AvgFistOfWarHitEffect = {
						s_format("1 + (%.2f ^8(fist of war hit multiplier)", globalOutput.FistOfWarHitMultiplier),
						s_format("x %.2f) ^8(fist of war uptime ratio)", globalOutput.FistOfWarUptimeRatio / 100),
						s_format("= %.2f", globalOutput.AvgFistOfWarHitEffect),
					}
				end
				globalOutput.AvgFistOfWarAilmentEffect = 1 + globalOutput.FistOfWarAilmentMultiplier * (globalOutput.FistOfWarUptimeRatio / 100)
				globalOutput.MaxFistOfWarHitEffect = 1 + globalOutput.FistOfWarHitMultiplier
				globalOutput.MaxFistOfWarAilmentEffect = 1 + globalOutput.FistOfWarAilmentMultiplier
				if activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
					output.FistOfWarHitEffect = globalOutput.MaxFistOfWarHitEffect
					output.FistOfWarAilmentEffect = globalOutput.MaxFistOfWarAilmentEffect
				else
					output.FistOfWarHitEffect = globalOutput.AvgFistOfWarHitEffect
					output.FistOfWarAilmentEffect = globalOutput.AvgFistOfWarAilmentEffect
				end
				globalOutput.TheoreticalOffensiveWarcryEffect = globalOutput.TheoreticalOffensiveWarcryEffect * globalOutput.AvgFistOfWarHitEffect
				globalOutput.TheoreticalMaxOffensiveWarcryEffect = globalOutput.TheoreticalMaxOffensiveWarcryEffect * globalOutput.MaxFistOfWarHitEffect
			else
				output.FistOfWarHitEffect = 1
				output.FistOfWarAilmentEffect = 1
			end
		end

		-- Calculate crit chance, crit multiplier, and their combined effect
		if skillModList:Flag(nil, "NeverCrit") then
			output.PreEffectiveCritChance = 0
			output.CritChance = 0
			output.CritMultiplier = 0
			output.BonusCritDotMultiplier = 0
			output.CritEffect = 1
		else
			local critOverride = skillModList:Override(cfg, "CritChance")
			local baseCrit = critOverride or source.CritChance or 0
			if baseCrit == 100 then
				output.PreEffectiveCritChance = 100
				output.CritChance = 100
			else
				local base = 0
				local inc = 0
				local more = 1
				if not critOverride then
					base = skillModList:Sum("BASE", cfg, "CritChance") + (env.mode_effective and enemyDB:Sum("BASE", nil, "SelfCritChance") or 0)
					inc = skillModList:Sum("INC", cfg, "CritChance") + (env.mode_effective and enemyDB:Sum("INC", nil, "SelfCritChance") or 0)
					more = skillModList:More(cfg, "CritChance")
				end
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
					extraDamage = extraDamage + enemyDB:Sum("BASE", nil, "SelfCritMultiplier") / 100
					extraDamage = round(extraDamage * enemyInc, 2)
					if breakdown and enemyInc ~= 1 then
						breakdown.CritMultiplier = {
							s_format("%d%% ^8(additional extra damage)", (enemyDB:Sum("BASE", nil, "SelfCritMultiplier") + skillModList:Sum("BASE", cfg, "CritMultiplier")) / 100),
							s_format("x %.2f ^8(increased/reduced extra crit damage taken by enemy)", enemyInc),
							s_format("= %d%% ^8(extra crit damage)", extraDamage * 100),
						}
					end
				end
				output.CritMultiplier = 1 + m_max(0, extraDamage)
			end
			local critChancePercentage = output.CritChance / 100
			output.CritEffect = 1 - critChancePercentage + critChancePercentage * output.CritMultiplier
			output.BonusCritDotMultiplier = (skillModList:Sum("BASE", cfg, "CritMultiplier") - 50) * skillModList:Sum("BASE", cfg, "CritMultiplierAppliesToDegen") / 10000
			if breakdown and output.CritEffect ~= 1 then
				breakdown.CritEffect = {
					s_format("(1 - %.4f) ^8(portion of damage from non-crits)", critChancePercentage),
					s_format("+ [ (%.4f x %g) ^8(portion of damage from crits)", critChancePercentage, output.CritMultiplier),
					s_format("= %.3f", output.CritEffect),
				}
			end
		end

		output.ScaledDamageEffect = 1
	
		-- Calculate chance and multiplier for dealing triple damage on Normal and Crit
		output.TripleDamageChanceOnCrit = m_min(skillModList:Sum("BASE", cfg, "TripleDamageChanceOnCrit"), 100)
		output.TripleDamageChance = m_min(skillModList:Sum("BASE", cfg, "TripleDamageChance") or 0 + (env.mode_effective and enemyDB:Sum("BASE", cfg, "SelfTripleDamageChance") or 0) + (output.TripleDamageChanceOnCrit * output.CritChance / 100), 100)
		output.TripleDamageEffect = 1 + (2 * output.TripleDamageChance / 100)
		output.ScaledDamageEffect = output.ScaledDamageEffect * output.TripleDamageEffect

		-- Calculate chance and multiplier for dealing double damage on Normal and Crit
		output.DoubleDamageChanceOnCrit = m_min(skillModList:Sum("BASE", cfg, "DoubleDamageChanceOnCrit"), 100)
		output.DoubleDamageChance = m_min(skillModList:Sum("BASE", cfg, "DoubleDamageChance") + (env.mode_effective and enemyDB:Sum("BASE", cfg, "SelfDoubleDamageChance") or 0) + (output.DoubleDamageChanceOnCrit * output.CritChance / 100), 100)
		if globalOutput.IntimidatingUpTimeRatio and activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
			output.DoubleDamageChance = 100
		elseif globalOutput.IntimidatingUpTimeRatio then
			output.DoubleDamageChance = m_min(output.DoubleDamageChance + globalOutput.IntimidatingUpTimeRatio, 100)
		end
		-- Triple Damage overrides Double Damage. If you have both, it's the same as just having Triple
		-- We need to subtract the probability of both happening in favor of Triple Damage
		if output.TripleDamageChance > 0 then
			output.DoubleDamageChance = m_max(output.DoubleDamageChance - output.TripleDamageChance * output.DoubleDamageChance / 100, 0)
		end
		output.DoubleDamageEffect = 1 + output.DoubleDamageChance / 100
		output.ScaledDamageEffect = output.ScaledDamageEffect * output.DoubleDamageEffect	
		-- Calculate culling DPS
		local criticalCull = skillModList:Max(cfg, "CriticalCullPercent") or 0
		if criticalCull > 0 then
			criticalCull = criticalCull * (output.CritChance / 100)
		end
		local regularCull = skillModList:Max(cfg, "CullPercent") or 0
		local maxCullPercent = m_max(criticalCull, regularCull)
		globalOutput.CullPercent = maxCullPercent
		globalOutput.CullMultiplier = 100 / (100 - globalOutput.CullPercent)
		-- Calculate base hit damage
		for _, damageType in ipairs(dmgTypeList) do
			local damageTypeMin = damageType.."Min"
			local damageTypeMax = damageType.."Max"
			local baseMultiplier = activeSkill.activeEffect.grantedEffectLevel.baseMultiplier or skillData.baseMultiplier or 1
			local damageEffectiveness = activeSkill.activeEffect.grantedEffectLevel.damageEffectiveness or skillData.damageEffectiveness or 1
			local addedMin = skillModList:Sum("BASE", cfg, damageTypeMin) + enemyDB:Sum("BASE", cfg, "Self"..damageTypeMin)
			local addedMax = skillModList:Sum("BASE", cfg, damageTypeMax) + enemyDB:Sum("BASE", cfg, "Self"..damageTypeMax)
			local addedMult = calcLib.mod(skillModList, cfg, "Added"..damageType.."Damage", "AddedDamage")
			local baseMin = ((source[damageTypeMin] or 0) + (source[damageType.."BonusMin"] or 0)) * baseMultiplier + addedMin * damageEffectiveness * addedMult
			local baseMax = ((source[damageTypeMax] or 0) + (source[damageType.."BonusMax"] or 0)) * baseMultiplier + addedMax * damageEffectiveness * addedMult
			output[damageTypeMin.."Base"] = baseMin
			output[damageTypeMax.."Base"] = baseMax
			if breakdown then
				breakdown[damageType] = { damageTypes = { } }
				if baseMin ~= 0 and baseMax ~= 0 then
					t_insert(breakdown[damageType], "Base damage:")
					local plus = ""
					if (source[damageTypeMin] or 0) ~= 0 or (source[damageTypeMax] or 0) ~= 0 then
						t_insert(breakdown[damageType], s_format("%d to %d ^8(base damage from %s)", source[damageTypeMin], source[damageTypeMax], source.type and "weapon" or "skill"))
						if baseMultiplier ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(base damage multiplier)", baseMultiplier))
						end
						plus = "+ "
					end
					if addedMin ~= 0 or addedMax ~= 0 then
						t_insert(breakdown[damageType], s_format("%s%d to %d ^8(added damage)", plus, addedMin, addedMax))
						if damageEffectiveness ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(damage effectiveness)", damageEffectiveness))
						end
						if addedMult ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(added damage multiplier)", addedMult))
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
        output.impaleStoredHitAvg = 0
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
				local damageTypeHitMin, damageTypeHitMax, damageTypeHitAvg, damageTypeLuckyChance, damageTypeHitAvgLucky, damageTypeHitAvgNotLucky = 0, 0, 0, 0, 0
				if skillFlags.hit and canDeal[damageType] then
					damageTypeHitMin, damageTypeHitMax = calcDamage(activeSkill, output, cfg, pass == 2 and breakdown and breakdown[damageType], damageType, 0)
					local convMult = activeSkill.conversionTable[damageType].mult
					if pass == 2 and breakdown then
						t_insert(breakdown[damageType], "Hit damage:")
						t_insert(breakdown[damageType], s_format("%d to %d ^8(total damage)", damageTypeHitMin, damageTypeHitMax))
						if convMult ~= 1 then
							t_insert(breakdown[damageType], s_format("x %g ^8(%g%% converted to other damage types)", convMult, (1-convMult)*100))
						end
						if output.TripleDamageEffect ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(multiplier from %.2f%% chance to deal triple damage)", output.TripleDamageEffect, output.TripleDamageChance))
						end
						if output.DoubleDamageEffect ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(multiplier from %.2f%% chance to deal double damage)", output.DoubleDamageEffect, output.DoubleDamageChance))
						end
						if output.RuthlessBlowEffect ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(ruthless blow effect modifier)", output.RuthlessBlowEffect))
						end
						if output.FistOfWarHitEffect ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(fist of war effect modifier)", output.FistOfWarHitEffect))
						end
						if globalOutput.OffensiveWarcryEffect ~= 1  and not activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(aggregated warcry exerted effect modifier)", globalOutput.OffensiveWarcryEffect))
						end
						if globalOutput.MaxOffensiveWarcryEffect ~= 1 and activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
							t_insert(breakdown[damageType], s_format("x %.2f ^8(aggregated max warcry exerted effect modifier)", globalOutput.MaxOffensiveWarcryEffect))
						end
					end
					if activeSkill.skillModList:Flag(nil, "Condition:WarcryMaxHit") then
						output.allMult = convMult * output.ScaledDamageEffect * output.RuthlessBlowEffect * output.FistOfWarHitEffect * globalOutput.MaxOffensiveWarcryEffect
					else
						output.allMult = convMult * output.ScaledDamageEffect * output.RuthlessBlowEffect * output.FistOfWarHitEffect * globalOutput.OffensiveWarcryEffect
					end
					local allMult = output.allMult
					if pass == 1 then
						-- Apply crit multiplier
						allMult = allMult * output.CritMultiplier
					end
					damageTypeHitMin = damageTypeHitMin * allMult
					damageTypeHitMax = damageTypeHitMax * allMult
					if skillModList:Flag(skillCfg, "LuckyHits")
					or (pass == 2 and damageType == "Lightning" and skillModList:Flag(skillCfg, "LightningNoCritLucky"))
					or (pass == 1 and skillModList:Flag(skillCfg, "CritLucky"))
					or ((damageType == "Lightning" or damageType == "Cold" or damageType == "Fire") and skillModList:Flag(skillCfg, "ElementalLuckHits")) then
						damageTypeLuckyChance = 1
					else
						damageTypeLuckyChance = m_min(skillModList:Sum("BASE", skillCfg, "LuckyHitsChance"), 100) / 100
					end
					damageTypeHitAvgNotLucky = (damageTypeHitMin / 2 + damageTypeHitMax / 2)
					damageTypeHitAvgLucky = (damageTypeHitMin / 3 + 2 * damageTypeHitMax / 3)
					damageTypeHitAvg = damageTypeHitAvgNotLucky * (1 - damageTypeLuckyChance) + damageTypeHitAvgLucky * damageTypeLuckyChance
					if (damageTypeHitMin ~= 0 or damageTypeHitMax ~= 0) and env.mode_effective then
						-- Apply enemy resistances and damage taken modifiers
						local resist = 0
						local pen = 0
						local sourceRes = 0
						local takenInc = enemyDB:Sum("INC", cfg, "DamageTaken", damageType.."DamageTaken")
						local takenMore = enemyDB:More(cfg, "DamageTaken", damageType.."DamageTaken")
						-- Check if player is supposed to ignore a damage type, or if it's ignored on enemy side
						local useThisResist = function(damageType) 
							return not skillModList:Flag(cfg, "Ignore"..damageType.."Resistance", isElemental[damageType] and "IgnoreElementalResistances" or nil) and not enemyDB:Flag(nil, "SelfIgnore"..damageType.."Resistance")
						end
						if damageType == "Physical" then
							-- store pre-armour physical damage from attacks for impale calculations
							if pass == 1 then
								output.impaleStoredHitAvg = output.impaleStoredHitAvg + damageTypeHitAvg * (output.CritChance / 100)
							else
								output.impaleStoredHitAvg = output.impaleStoredHitAvg + damageTypeHitAvg * (1 - output.CritChance / 100)
							end
							local enemyArmour = calcLib.val(enemyDB, "Armour")
							local armourReduction = calcs.armourReductionF(enemyArmour, damageTypeHitAvg)
							if skillModList:Flag(cfg, "IgnoreEnemyPhysicalDamageReduction") then
								resist = 0
							else
								resist = m_min(m_max(0, enemyDB:Sum("BASE", nil, "PhysicalDamageReduction") + skillModList:Sum("BASE", cfg, "EnemyPhysicalDamageReduction") + armourReduction), data.misc.DamageReductionCap)
							end
						else
							if (skillModList:Flag(cfg, "ChaosDamageUsesLowestResistance") and damageType == "Chaos") or 
							   (skillModList:Flag(cfg, "ElementalDamageUsesLowestResistance") and isElemental[damageType]) then
								-- Default to using the current damage type 
								local elementUsed = damageType
								if isElemental[damageType] then
									resist = m_min(enemyDB:Sum("BASE", nil, damageType.."Resist", "ElementalResist") * calcLib.mod(enemyDB, nil, damageType.."Resist", "ElementalResist"), data.misc.EnemyMaxResist)
								elseif damageType == "Chaos" then
									resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist") * calcLib.mod(enemyDB, nil, "ChaosResist"), data.misc.EnemyMaxResist)
								end
								-- Find the lowest resist of all the elements and use that if it's lower
								for _, eleDamageType in ipairs(dmgTypeList) do
									if isElemental[eleDamageType] and useThisResist(eleDamageType) and damageType ~= eleDamageType then
										local currentElementResist = m_min(enemyDB:Sum("BASE", nil, eleDamageType.."Resist", "ElementalResist") * calcLib.mod(enemyDB, nil, eleDamageType.."Resist", "ElementalResist"), data.misc.EnemyMaxResist)
										-- If it's explicitly lower, then use the resist and update which element we're using to account for penetration
										if resist > currentElementResist then
											resist = currentElementResist
											elementUsed = eleDamageType
										end
									end
								end
								-- Update the penetration based on the element used
								if isElemental[elementUsed] then
									pen = skillModList:Sum("BASE", cfg, elementUsed.."Penetration", "ElementalPenetration")
								elseif elementUsed == "Chaos" then
									pen = skillModList:Sum("BASE", cfg, "ChaosPenetration")
								end
								sourceRes = elementUsed
							elseif isElemental[damageType] then
								resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
								if env.modDB:Flag(nil, "Enemy"..damageType.."ResistEqualToYours") then
									resist = env.player.output[damageType.."Resist"]
								else
									local base = resist + enemyDB:Sum("BASE", nil, "ElementalResist")
									resist = base * calcLib.mod(enemyDB, nil, damageType.."Resist")
								end
								pen = skillModList:Sum("BASE", cfg, damageType.."Penetration", "ElementalPenetration")
								takenInc = takenInc + enemyDB:Sum("INC", cfg, "ElementalDamageTaken")
							elseif damageType == "Chaos" then
								resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
								pen = skillModList:Sum("BASE", cfg, "ChaosPenetration")
							end
							resist = m_max(m_min(resist, data.misc.EnemyMaxResist), data.misc.ResistFloor)
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
						if skillModList:Flag(cfg, isElemental[damageType] and "CannotElePenIgnore" or nil) then
							effMult = effMult * (1 - resist / 100)
						elseif useThisResist(damageType) then
							effMult = effMult * (1 - (resist - pen) / 100)
						end
						damageTypeHitMin = damageTypeHitMin * effMult
						damageTypeHitMax = damageTypeHitMax * effMult
						damageTypeHitAvg = damageTypeHitAvg * effMult
						if env.mode == "CALCS" then
							output[damageType.."EffMult"] = effMult
						end
						if pass == 2 and breakdown and (effMult ~= 1 or sourceRes ~= 0) and skillModList:Flag(cfg, isElemental[damageType] and "CannotElePenIgnore" or nil) then
							t_insert(breakdown[damageType], s_format("x %.3f ^8(effective DPS modifier)", effMult))
							breakdown[damageType.."EffMult"] = breakdown.effMult(damageType, resist, 0, takenInc, effMult, takenMore, sourceRes)
						elseif pass == 2 and breakdown and (effMult ~= 1 or sourceRes ~= 0) then
							t_insert(breakdown[damageType], s_format("x %.3f ^8(effective DPS modifier)", effMult))
							breakdown[damageType.."EffMult"] = breakdown.effMult(damageType, resist, pen, takenInc, effMult, takenMore, sourceRes)
						end
					end
					if pass == 2 and breakdown then
						t_insert(breakdown[damageType], s_format("= %d to %d", damageTypeHitMin, damageTypeHitMax))
					end
					
					-- Beginning of Leech Calculation for this DamageType
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

		local highestType = "Physical"
		
		-- For each damage type, calculate percentage of total damage. Also tracks the highest damage type and outputs a Condition:TypeIsHighestDamageType flag for whichever the highest type is
		for _, damageType in ipairs(dmgTypeList) do
			if output[damageType.."HitAverage"] > 0 then
				local portion = output[damageType.."HitAverage"] / totalHitAvg * 100
				local highestPortion = output[highestType.."HitAverage"] / totalHitAvg * 100
				if portion > highestPortion then
					highestType = damageType
					highestPortion = portion
				end
				if breakdown then
					t_insert(breakdown[damageType], s_format("Portion of total damage: %d%%", portion))
				end
			end
		end
		skillModList:NewMod("Condition:"..highestType.."IsHighestDamageType", "FLAG", true, "Config")

		local hitRate = output.HitChance / 100 * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)

		-- Calculate leech
		local function getLeechInstances(amount, total)
			if total == 0 then
				return 0, 0
			end
			local duration = amount / total / data.misc.LeechRateBase
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
			output.LifeOnHit = skillModList:Sum("BASE", cfg, "LifeOnHit") + enemyDB:Sum("BASE", cfg, "SelfLifeOnHit")
			output.EnergyShieldOnHit = skillModList:Sum("BASE", cfg, "EnergyShieldOnHit") + enemyDB:Sum("BASE", cfg, "SelfEnergyShieldOnHit")
			output.ManaOnHit = skillModList:Sum("BASE", cfg, "ManaOnHit") + enemyDB:Sum("BASE", cfg, "SelfManaOnHit")
		end
		output.LifeOnHitRate = output.LifeOnHit * hitRate
		output.EnergyShieldOnHitRate = output.EnergyShieldOnHit * hitRate
		output.ManaOnHitRate = output.ManaOnHit * hitRate

		-- Calculate average damage and final DPS
		output.AverageHit = totalHitAvg * (1 - output.CritChance / 100) + totalCritAvg * output.CritChance / 100
		output.AverageDamage = output.AverageHit * output.HitChance / 100
		output.TotalDPS = output.AverageDamage * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1) * quantityMultiplier
		if breakdown then
			if output.CritEffect ~= 1 then
				breakdown.AverageHit = { }
				if skillModList:Flag(skillCfg, "LuckyHits") then
					t_insert(breakdown.AverageHit, s_format("(1/3) x %d + (2/3) x %d = %.1f ^8(average from non-crits)", totalHitMin, totalHitMax, totalHitAvg))
				end
				if skillModList:Flag(skillCfg, "CritLucky") or skillModList:Flag(skillCfg, "LuckyHits") then
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
			output.DisplayDamage = formatNumSep(s_format("%.1f", output.AverageDamage)) .. " average damage"
		else
			output.DisplayDamage = formatNumSep(s_format("%.1f", output.TotalDPS)) .. " DPS"
		end
	end
	if breakdown then
		if isAttack then
			breakdown.TotalDPS = {
				s_format("%.1f ^8(average damage)", output.AverageDamage),
				output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(attack rate)", output.Speed),
			}
		elseif isTriggered then
			breakdown.TotalDPS = {
				s_format("%.1f ^8(average damage)", output.AverageDamage),
				output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(trigger rate)", output.Speed),
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
		if quantityMultiplier > 1 then
			t_insert(breakdown.TotalDPS, s_format("x %g ^8(quantity multiplier for this skill)", quantityMultiplier))
		end
		t_insert(breakdown.TotalDPS, s_format("= %.1f", output.TotalDPS))
	end

	-- Calculate leech rates
	output.LifeLeechInstanceRate = output.Life * data.misc.LeechRateBase * calcLib.mod(skillModList, skillCfg, "LifeLeechRate")
	output.LifeLeechRate = output.LifeLeechInstantRate + m_min(output.LifeLeechInstances * output.LifeLeechInstanceRate, output.MaxLifeLeechRate) * output.LifeRecoveryRateMod
	output.LifeLeechPerHit = output.LifeLeechInstant + m_min(output.LifeLeechInstanceRate, output.MaxLifeLeechRate) * output.LifeLeechDuration * output.LifeRecoveryRateMod
	output.EnergyShieldLeechInstanceRate = output.EnergyShield * data.misc.LeechRateBase * calcLib.mod(skillModList, skillCfg, "EnergyShieldLeechRate")
	output.EnergyShieldLeechRate = output.EnergyShieldLeechInstantRate + m_min(output.EnergyShieldLeechInstances * output.EnergyShieldLeechInstanceRate, output.MaxEnergyShieldLeechRate) * output.EnergyShieldRecoveryRateMod
	output.EnergyShieldLeechPerHit = output.EnergyShieldLeechInstant + m_min(output.EnergyShieldLeechInstanceRate, output.MaxEnergyShieldLeechRate) * output.EnergyShieldLeechDuration * output.EnergyShieldRecoveryRateMod
	output.ManaLeechInstanceRate = output.Mana * data.misc.LeechRateBase * calcLib.mod(skillModList, skillCfg, "ManaLeechRate")
	output.ManaLeechRate = output.ManaLeechInstantRate + m_min(output.ManaLeechInstances * output.ManaLeechInstanceRate, output.MaxManaLeechRate) * output.ManaRecoveryRateMod
	output.ManaLeechPerHit = output.ManaLeechInstant + m_min(output.ManaLeechInstanceRate, output.MaxManaLeechRate) * output.ManaLeechDuration * output.ManaRecoveryRateMod
	-- On full life, Immortal Ambition treats life leech as energy shield leech
	if skillModList:Flag(nil, "ImmortalAmbition") then
		output.EnergyShieldLeechRate = output.EnergyShieldLeechRate + output.LifeLeechRate
		output.EnergyShieldLeechPerHit = output.EnergyShieldLeechPerHit  + output.LifeLeechPerHit
		-- Clears output.LifeLeechRate to disable leechLife flag
		output.LifeLeechRate = 0
	end
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

	skillFlags.bleed = false
	skillFlags.poison = false
	skillFlags.ignite = false
	skillFlags.igniteCanStack = skillModList:Flag(skillCfg, "IgniteCanStack")
	skillFlags.igniteToChaos = skillModList:Flag(skillCfg, "IgniteToChaos")
	skillFlags.shock = false
	skillFlags.freeze = false
	skillFlags.impale = false
	skillFlags.chill = false
	skillFlags.scorch = false
	skillFlags.brittle = false
	skillFlags.sap = false
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
		if skillModList:Flag(cfg, "CritAlwaysAltAilments") and not skillModList:Flag(cfg, "NeverCrit") then
			skillFlags.inflictScorch = true
			skillFlags.inflictBrittle = true
			skillFlags.inflictSap = true
		end
		if skillModList:Flag(cfg, "CritAlwaysAltAilments") and not skillModList:Flag(cfg, "NeverCrit") and skillFlags.hit then
			output.ScorchChanceOnCrit = not skillModList:Flag(cfg, "CannotScorch") and 100 or 0
			output.BrittleChanceOnCrit = not skillModList:Flag(cfg, "CannotBrittle") and 100 or 0
			output.SapChanceOnCrit = not skillModList:Flag(cfg, "CannotSap") and 100 or 0
		else
			output.ScorchChanceOnCrit = 0
			output.BrittleChanceOnCrit = 0
			output.SapChanceOnCrit = 0
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
		if skillModList:Sum("BASE", cfg, "ScorchChance") > 0 then
			skillFlags.inflictScorch = true
		end
		if skillModList:Sum("BASE", cfg, "ScorchChance") > 0 and skillFlags.hit and not skillModList:Flag(cfg, "CannotScorch") then
			output.ScorchChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "ScorchChance"))
		else
			output.ScorchChanceOnHit = 0
		end
		if skillModList:Sum("BASE", cfg, "BrittleChance") > 0 then
			skillFlags.inflictBrittle = true
		end
		if skillModList:Sum("BASE", cfg, "BrittleChance") > 0 and skillFlags.hit and not skillModList:Flag(cfg, "CannotBrittle") then
			output.BrittleChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "BrittleChance"))
		else
			output.BrittleChanceOnHit = 0
		end
		if skillModList:Sum("BASE", cfg, "SapChance") > 0 then
			skillFlags.inflictSap = true
		end
		if skillModList:Sum("BASE", cfg, "SapChance") > 0 and skillFlags.hit and not skillModList:Flag(cfg, "CannotSap") then
			output.SapChanceOnHit = m_min(100, skillModList:Sum("BASE", cfg, "SapChance"))
		else
			output.SapChanceOnHit = 0
		end
		output.ImpaleChance = m_min(100, skillModList:Sum("BASE", cfg, "ImpaleChance"))
		if skillModList:Sum("BASE", cfg, "FireExposureChance") > 0 then
			skillFlags.applyFireExposure = true
		end
		if skillModList:Sum("BASE", cfg, "ColdExposureChance") > 0 then
			skillFlags.applyColdExposure = true
		end
		if skillModList:Sum("BASE", cfg, "LightningExposureChance") > 0 then
			skillFlags.applyLightningExposure = true
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
			local scorchMult = (1 - enemyDB:Sum("BASE", nil, "AvoidScorch") / 100)
			output.ScorchChanceOnHit = output.ScorchChanceOnHit * scorchMult
			output.ScorchChanceOnCrit = output.ScorchChanceOnCrit * scorchMult
			local brittleMult = (1 - enemyDB:Sum("BASE", nil, "AvoidBrittle") / 100)
			output.BrittleChanceOnHit = output.BrittleChanceOnHit * brittleMult
			output.BrittleChanceOnCrit = output.BrittleChanceOnCrit * brittleMult
			local sapMult = (1 - enemyDB:Sum("BASE", nil, "AvoidSap") / 100)
			output.SapChanceOnHit = output.SapChanceOnHit * sapMult
			output.SapChanceOnCrit = output.SapChanceOnCrit * sapMult
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
			local sourceMult = skillModList:More(nil, type.."AsThoughDealing")
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
					if sourceMult > 1 then
						t_insert(breakdownDPS, s_format("x %.2f ^8(inflicting as though dealing more damage)", sourceMult))
						t_insert(breakdownDPS, s_format("= %.1f", baseVal * sourceMult))
					end
				else
					if baseFromHit > 0 then
						t_insert(breakdownDPS, "Damage from Non-crits:")
						t_insert(breakdownDPS, s_format("%.1f ^8(source damage from non-crits)", sourceHitDmg))
						t_insert(breakdownDPS, s_format("x %.3f ^8(portion of instances created by non-crits)", chanceFromHit / (chanceFromHit + chanceFromCrit)))
						if sourceMult == 1 or baseFromCrit ~= 0 then
							t_insert(breakdownDPS, s_format("= %.1f", baseFromHit))
						end
					end
					if baseFromCrit > 0 then
						t_insert(breakdownDPS, "Damage from Crits:")
						t_insert(breakdownDPS, s_format("%.1f ^8(source damage from crits)", sourceCritDmg))
						t_insert(breakdownDPS, s_format("x %.3f ^8(portion of instances created by crits)", chanceFromCrit / (chanceFromHit + chanceFromCrit)))
						if sourceMult == 1 or baseFromHit ~= 0 then
							t_insert(breakdownDPS, s_format("= %.1f", baseFromCrit))
						end
					end
					if baseFromHit > 0 and baseFromCrit > 0 then
						t_insert(breakdownDPS, "Total damage:")
						t_insert(breakdownDPS, s_format("%.1f + %.1f", baseFromHit, baseFromCrit))
						if sourceMult == 1 then
							t_insert(breakdownDPS, s_format("= %.1f", baseVal))
						end
					end
					if sourceMult > 1 then
						t_insert(breakdownDPS, s_format("x %.2f ^8(inflicting as though dealing more damage)", sourceMult))
						t_insert(breakdownDPS, s_format("= %.1f", baseVal * sourceMult))
					end
				end
			end
			return baseVal
		end

		-- Calculate bleeding chance and damage
		if canDeal.Physical and (output.BleedChanceOnHit + output.BleedChanceOnCrit) > 0 then
			activeSkill[pass.label ~= "Off Hand" and "bleedCfg" or "OHbleedCfg"] = {
				skillName = skillCfg.skillName,
				skillPart = skillCfg.skillPart,
				skillTypes = skillCfg.skillTypes,
				slotName = skillCfg.slotName,
				flags = bor(ModFlag.Dot, ModFlag.Ailment, band(cfg.flags, ModFlag.WeaponMask), band(cfg.flags, ModFlag.Melee) ~= 0 and ModFlag.MeleeHit or 0),
				keywordFlags = bor(band(cfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.Bleed, KeywordFlag.Ailment, KeywordFlag.PhysicalDot),
				skillCond = setmetatable({["CriticalStrike"] = true }, { __index = function(table, key) return skillCfg.skillCond[key] or cfg.skillCond[key] end } ),
				skillDist = skillCfg.skillDist,
			}
			local dotCfg = pass.label ~= "Off Hand" and activeSkill.bleedCfg or activeSkill.OHbleedCfg
			local sourceHitDmg, sourceCritDmg
			if breakdown then
				breakdown.BleedPhysical = { damageTypes = { } }
			end
			for sub_pass = 1, 2 do
				if skillModList:Flag(dotCfg, "AilmentsAreNeverFromCrit") or sub_pass == 1 then
					dotCfg.skillCond["CriticalStrike"] = false
				else
					dotCfg.skillCond["CriticalStrike"] = true
				end
				local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.BleedPhysical, "Physical", 0)
				output.BleedPhysicalMin = min
				output.BleedPhysicalMax = max
				if sub_pass == 2 then
					output.CritBleedDotMulti = 1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "PhysicalDotMultiplier") / 100
					sourceCritDmg = (min + max) / 2 * output.CritBleedDotMulti
				else
					output.BleedDotMulti = 1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "PhysicalDotMultiplier") / 100
					sourceHitDmg = (min + max) / 2 * output.BleedDotMulti
				end
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.BleedChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.BleedDPS = {
					s_format("Ailment mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crits Only" or "Average Damage")
				}
			end
			local basePercent = skillData.bleedBasePercent or data.misc.BleedPercentBase
			local baseVal = calcAilmentDamage("Bleed", sourceHitDmg, sourceCritDmg) * basePercent / 100 * output.RuthlessBlowEffect * output.FistOfWarAilmentEffect * globalOutput.AilmentWarcryEffect
			if baseVal > 0 then
				skillFlags.bleed = true
				skillFlags.duration = true
				local effMult = 1
				if env.mode_effective then
					local resist = m_max(0, enemyDB:Sum("BASE", nil, "PhysicalDamageReduction"))
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
				local rateMod = calcLib.mod(skillModList, cfg, "BleedFaster") + enemyDB:Sum("INC", nil, "SelfBleedFaster")  / 100
				local maxStacks = skillModList:Override(cfg, "BleedStacksMax") or skillModList:Sum("BASE", cfg, "BleedStacksMax")
				local configStacks = enemyDB:Sum("BASE", nil, "Multiplier:BleedStacks")
				local bleedStacks = configStacks > 0 and m_min(configStacks, maxStacks) or maxStacks
				output.BaseBleedDPS = baseVal * effectMod * rateMod * effMult
				output.BleedDPS = (baseVal * effectMod * rateMod * effMult) * bleedStacks
				local durationBase
				if skillData.bleedDurationIsSkillDuration then
					durationBase = skillData.duration
				else
					durationBase = data.misc.BleedDurationBase
				end
				local durationMod = calcLib.mod(skillModList, dotCfg, "EnemyBleedDuration", "SkillAndDamagingAilmentDuration", skillData.bleedIsSkillEffect and "Duration" or nil) * calcLib.mod(enemyDB, nil, "SelfBleedDuration")
				globalOutput.BleedDuration = durationBase * durationMod / rateMod * debuffDurationMult
				globalOutput.BleedDamage = output.BaseBleedDPS * globalOutput.BleedDuration
				globalOutput.BleedStacksMax = maxStacks
				globalOutput.BleedStacks = bleedStacks
				if breakdown then
					if output.CritBleedDotMulti and (output.CritBleedDotMulti ~= output.BleedDotMulti) then
						local chanceFromHit = output.BleedChanceOnHit / 100 * (1 - globalOutput.CritChance / 100)
						local chanceFromCrit = output.BleedChanceOnCrit / 100 * output.CritChance / 100
						local totalFromHit = chanceFromHit / (chanceFromHit + chanceFromCrit)
						local totalFromCrit = chanceFromCrit / (chanceFromHit + chanceFromCrit)
						breakdown.BleedDotMulti = breakdown.critDot(output.BleedDotMulti, output.CritBleedDotMulti, totalFromHit, totalFromCrit)
						output.BleedDotMulti = (output.BleedDotMulti * totalFromHit) + (output.CritBleedDotMulti * totalFromCrit)
					end
					t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(bleed deals %d%% per second)", basePercent/100, basePercent))
					if effectMod ~= 1 then
						t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(ailment effect modifier)", effectMod))
					end
					if output.RuthlessBlowEffect ~= 1 then
						t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(ruthless blow effect modifier)", output.RuthlessBlowEffect))
					end
					if output.FistOfWarAilmentEffect ~= 1 then
						t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(fist of war effect modifier)", output.FistOfWarAilmentEffect))
					end
					if globalOutput.AilmentWarcryEffect > 1 then
						t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(combined ailment warcry effect modifier)", globalOutput.AilmentWarcryEffect))
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
			activeSkill[pass.label ~= "Off Hand" and "poisonCfg" or "OHpoisonCfg"] = {
				skillName = skillCfg.skillName,
				skillPart = skillCfg.skillPart,
				skillTypes = skillCfg.skillTypes,
				slotName = skillCfg.slotName,
				flags = bor(ModFlag.Dot, ModFlag.Ailment, band(cfg.flags, ModFlag.WeaponMask), band(cfg.flags, ModFlag.Melee) ~= 0 and ModFlag.MeleeHit or 0),
				keywordFlags = bor(band(cfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.Poison, KeywordFlag.Ailment, KeywordFlag.ChaosDot),
				skillCond = setmetatable({["CriticalStrike"] = true }, { __index = function(table, key) return skillCfg.skillCond[key] or cfg.skillCond[key] end } ),
				skillDist = skillCfg.skillDist,
			}
			local dotCfg = pass.label ~= "Off Hand" and activeSkill.poisonCfg or activeSkill.OHpoisonCfg
			local sourceHitDmg, sourceCritDmg
			if breakdown then
				breakdown.PoisonPhysical = { damageTypes = { } }
				breakdown.PoisonLightning = { damageTypes = { } }
				breakdown.PoisonCold = { damageTypes = { } }
				breakdown.PoisonFire = { damageTypes = { } }
				breakdown.PoisonChaos = { damageTypes = { } }
			end
			for sub_pass = 1, 2 do
				if skillModList:Flag(dotCfg, "AilmentsAreNeverFromCrit") or sub_pass == 1 then
					dotCfg.skillCond["CriticalStrike"] = false
				else
					dotCfg.skillCond["CriticalStrike"] = true
				end
				local totalMin, totalMax = 0, 0
				do
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.PoisonChaos, "Chaos", 0)
					output.PoisonChaosMin = min
					output.PoisonChaosMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				local nonChaosMult = 1
				if output.ChaosPoisonChance > 0 and output.PoisonChaosMax > 0 then
					-- Additional chance for chaos
					local chance = (sub_pass == 2) and "PoisonChanceOnCrit" or "PoisonChanceOnHit"
					local chaosChance = m_min(100, output[chance] + output.ChaosPoisonChance)
					nonChaosMult = output[chance] / chaosChance
					output[chance] = chaosChance
				end
				if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanPoison") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.PoisonLightning, "Lightning", dmgTypeFlags.Chaos)
					output.PoisonLightningMin = min
					output.PoisonLightningMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if canDeal.Cold and skillModList:Flag(cfg, "ColdCanPoison") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.PoisonCold, "Cold", dmgTypeFlags.Chaos)
					output.PoisonColdMin = min
					output.PoisonColdMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if canDeal.Fire and skillModList:Flag(cfg, "FireCanPoison") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.PoisonFire, "Fire", dmgTypeFlags.Chaos)
					output.PoisonFireMin = min
					output.PoisonFireMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if canDeal.Physical then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.PoisonPhysical, "Physical", dmgTypeFlags.Chaos)
					output.PoisonPhysicalMin = min
					output.PoisonPhysicalMax = max
					totalMin = totalMin + min * nonChaosMult
					totalMax = totalMax + max * nonChaosMult
				end
				if sub_pass == 2 then
					output.CritPoisonDotMulti = 1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "ChaosDotMultiplier") / 100
					sourceCritDmg = (totalMin + totalMax) / 2 * output.CritPoisonDotMulti
				else
					output.PoisonDotMulti = 1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "ChaosDotMultiplier") / 100
					sourceHitDmg = (totalMin + totalMax) / 2 * output.PoisonDotMulti
				end
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.PoisonChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.PoisonDPS = {
					s_format("Ailment mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crits Only" or "Average Damage")
				}
			end
			local baseVal = calcAilmentDamage("Poison", sourceHitDmg, sourceCritDmg) * data.misc.PoisonPercentBase * output.FistOfWarAilmentEffect * globalOutput.AilmentWarcryEffect
			if baseVal > 0 then
				skillFlags.poison = true
				skillFlags.duration = true
				local effMult = 1
				if env.mode_effective then
					local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist") * calcLib.mod(enemyDB, nil, "ChaosResist"), data.misc.EnemyMaxResist)
					local takenInc = enemyDB:Sum("INC", dotCfg, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
					local takenMore = enemyDB:More(dotCfg, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
					effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
					globalOutput["PoisonEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.PoisonEffMult = breakdown.effMult("Chaos", resist, 0, takenInc, effMult, takenMore)
					end
				end
				local effectMod = calcLib.mod(skillModList, dotCfg, "AilmentEffect")
				local rateMod = calcLib.mod(skillModList, cfg, "PoisonFaster") + enemyDB:Sum("INC", nil, "SelfPoisonFaster")  / 100
				output.PoisonDPS = baseVal * effectMod * rateMod * effMult
				local durationBase
				if skillData.poisonDurationIsSkillDuration then
					durationBase = skillData.duration
				else
					durationBase = data.misc.PoisonDurationBase
				end
				local durationMod = calcLib.mod(skillModList, dotCfg, "EnemyPoisonDuration", "SkillAndDamagingAilmentDuration", skillData.poisonIsSkillEffect and "Duration" or nil) * calcLib.mod(enemyDB, nil, "SelfPoisonDuration")
				globalOutput.PoisonDuration = durationBase * durationMod / rateMod * debuffDurationMult
				output.PoisonDamage = output.PoisonDPS * globalOutput.PoisonDuration
				if skillData.showAverage then
					output.TotalPoisonAverageDamage = output.HitChance / 100 * output.PoisonChance / 100 * output.PoisonDamage
					output.TotalPoisonDPS = output.PoisonDPS
				else
					output.TotalPoisonStacks = output.HitChance / 100 * output.PoisonChance / 100 * globalOutput.PoisonDuration * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1) * (skillData.stackMultiplier or 1) * quantityMultiplier
					output.TotalPoisonDPS = output.PoisonDPS * output.TotalPoisonStacks
				end
				if breakdown then
					if output.CritPoisonDotMulti and (output.CritPoisonDotMulti ~= output.PoisonDotMulti) then
						local chanceFromHit = output.PoisonChanceOnHit / 100 * (1 - globalOutput.CritChance / 100)
						local chanceFromCrit = output.PoisonChanceOnCrit / 100 * globalOutput.CritChance / 100
						local totalFromHit = chanceFromHit / (chanceFromHit + chanceFromCrit)
						local totalFromCrit = chanceFromCrit / (chanceFromHit + chanceFromCrit)
						breakdown.PoisonDotMulti = breakdown.critDot(output.PoisonDotMulti, output.CritPoisonDotMulti, totalFromHit, totalFromCrit)
						output.PoisonDotMulti = (output.PoisonDotMulti * totalFromHit) + (output.CritPoisonDotMulti * totalFromCrit)
					end
					t_insert(breakdown.PoisonDPS, "x 0.30 ^8(poison deals 30% per second)")
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
							{ "%g ^8(stack multiplier for this skill)", skillData.stackMultiplier or 1 },
							{ "%g ^8(quantity multiplier for this skill)", quantityMultiplier },
							total = s_format("= %.1f", output.TotalPoisonStacks),
						})
					end
				end
			end
		end	

		-- Calculate ignite chance and damage
		if canDeal.Fire and (output.IgniteChanceOnHit + output.IgniteChanceOnCrit) > 0 then
			activeSkill[pass.label ~= "Off Hand" and "igniteCfg" or "OHigniteCfg"] = {
				skillName = skillCfg.skillName,
				skillPart = skillCfg.skillPart,
				skillTypes = skillCfg.skillTypes,
				slotName = skillCfg.slotName,
				flags = bor(ModFlag.Dot, ModFlag.Ailment, band(cfg.flags, ModFlag.WeaponMask), band(cfg.flags, ModFlag.Melee) ~= 0 and ModFlag.MeleeHit or 0),
				keywordFlags = bor(band(cfg.keywordFlags, bnot(KeywordFlag.Hit)), KeywordFlag.Ignite, KeywordFlag.Ailment, KeywordFlag.FireDot),
				skillCond = setmetatable({["CriticalStrike"] = true }, { __index = function(table, key) return skillCfg.skillCond[key] or cfg.skillCond[key] end } ),
				skillDist = skillCfg.skillDist,
			}
			local dotCfg = pass.label ~= "Off Hand" and activeSkill.igniteCfg or activeSkill.OHigniteCfg
			local sourceHitDmg, sourceCritDmg
			if breakdown then
				breakdown.IgnitePhysical = { damageTypes = { } }
				breakdown.IgniteLightning = { damageTypes = { } }
				breakdown.IgniteCold = { damageTypes = { } }
				breakdown.IgniteFire = { damageTypes = { } }
				breakdown.IgniteChaos = { damageTypes = { } }
			end
			for sub_pass = 1, 2 do
				if skillModList:Flag(dotCfg, "AilmentsAreNeverFromCrit") or sub_pass == 1 then
					dotCfg.skillCond["CriticalStrike"] = false
				else
					dotCfg.skillCond["CriticalStrike"] = true
				end
				local totalMin, totalMax = 0, 0
				if canDeal.Physical and skillModList:Flag(cfg, "PhysicalCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.IgnitePhysical, "Physical", dmgTypeFlags.Fire)
					output.IgnitePhysicalMin = min
					output.IgnitePhysicalMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.IgniteLightning, "Lightning", dmgTypeFlags.Fire)
					output.IgniteLightningMin = min
					output.IgniteLightningMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Cold and skillModList:Flag(cfg, "ColdCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.IgniteCold, "Cold", dmgTypeFlags.Fire)
					output.IgniteColdMin = min
					output.IgniteColdMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Fire and not skillModList:Flag(cfg, "FireCannotIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.IgniteFire, "Fire", 0)
					output.IgniteFireMin = min
					output.IgniteFireMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if canDeal.Chaos and skillModList:Flag(cfg, "ChaosCanIgnite") then
					local min, max = calcAilmentSourceDamage(activeSkill, output, dotCfg, sub_pass == 1 and breakdown and breakdown.IgniteChaos, "Chaos", dmgTypeFlags.Fire)
					output.IgniteChaosMin = min
					output.IgniteChaosMax = max
					totalMin = totalMin + min
					totalMax = totalMax + max
				end
				if sub_pass == 2 then
					output.CritIgniteDotMulti = 1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "FireDotMultiplier") / 100
					sourceCritDmg = (totalMin + totalMax) / 2 * output.CritIgniteDotMulti
				else
					output.IgniteDotMulti = 1 + skillModList:Sum("BASE", dotCfg, "DotMultiplier", "FireDotMultiplier") / 100
					sourceHitDmg = (totalMin + totalMax) / 2 * output.IgniteDotMulti
				end
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.IgniteChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.IgniteDPS = {
					s_format("Ailment mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crits Only" or "Average Damage")
				}
			end
			local baseVal = calcAilmentDamage("Ignite", sourceHitDmg, sourceCritDmg) * data.misc.IgnitePercentBase * output.FistOfWarAilmentEffect * globalOutput.AilmentWarcryEffect
			if baseVal > 0 then
				skillFlags.ignite = true
				local effMult = 1
				if env.mode_effective then
					if skillModList:Flag(cfg, "IgniteToChaos") then
						local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist") * calcLib.mod(enemyDB, nil, "ChaosResist"), data.misc.EnemyMaxResist)
						local takenInc = enemyDB:Sum("INC", dotCfg, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
						local takenMore = enemyDB:More(dotCfg, "DamageTaken", "DamageTakenOverTime", "ChaosDamageTaken", "ChaosDamageTakenOverTime")
						effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
						globalOutput["IgniteEffMult"] = effMult
						if breakdown and effMult ~= 1 then
							globalBreakdown.IgniteEffMult = breakdown.effMult("Chaos", resist, 0, takenInc, effMult, takenMore)
						end
					else
						local resist = m_min(enemyDB:Sum("BASE", nil, "FireResist", "ElementalResist") * calcLib.mod(enemyDB, nil, "FireResist", "ElementalResist"), data.misc.EnemyMaxResist)
						local takenInc = enemyDB:Sum("INC", dotCfg, "DamageTaken", "DamageTakenOverTime", "FireDamageTaken", "FireDamageTakenOverTime", "ElementalDamageTaken")
						local takenMore = enemyDB:More(dotCfg, "DamageTaken", "DamageTakenOverTime", "FireDamageTaken", "FireDamageTakenOverTime", "ElementalDamageTaken")
						effMult = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
						globalOutput["IgniteEffMult"] = effMult
						if breakdown and effMult ~= 1 then
							breakdown.IgniteEffMult = breakdown.effMult("Fire", resist, 0, takenInc, effMult, takenMore)
						end
					end
				end
				local effectMod = calcLib.mod(skillModList, dotCfg, "AilmentEffect")
				local rateMod = (calcLib.mod(skillModList, cfg, "IgniteBurnFaster") + enemyDB:Sum("INC", nil, "SelfIgniteBurnFaster") / 100)  / calcLib.mod(skillModList, cfg, "IgniteBurnSlower")
				output.IgniteDPS = baseVal * effectMod * rateMod * effMult
				local durationBase = data.misc.IgniteDurationBase
				local durationMod = calcLib.mod(skillModList, dotCfg, "EnemyIgniteDuration", "SkillAndDamagingAilmentDuration") * calcLib.mod(enemyDB, nil, "SelfIgniteDuration")
				globalOutput.IgniteDuration = durationBase * durationMod / rateMod * debuffDurationMult
				globalOutput.IgniteDamage = output.IgniteDPS * globalOutput.IgniteDuration
				if skillFlags.igniteCanStack then
					output.IgniteDamage = output.IgniteDPS * globalOutput.IgniteDuration
					output.TotalIgniteStacks = 1 + skillModList:Sum("BASE", cfg, "IgniteStacks")
					output.TotalIgniteDPS = output.IgniteDPS * output.TotalIgniteStacks
				end
				if breakdown then
					t_insert(breakdown.IgniteDPS, "x 1.25 ^8(ignite deals 125% per second)")
					t_insert(breakdown.IgniteDPS, s_format("= %.1f", baseVal, 1))
					breakdown.multiChain(breakdown.IgniteDPS, {
						label = "Ignite DPS:",
						base = s_format("%.1f ^8(total damage per second)", baseVal), 
						{ "%.2f ^8(ailment effect modifier)", effectMod },
						{ "%.2f ^8(burn rate modifier)", rateMod },
						{ "%.3f ^8(effective DPS modifier)", effMult },
						total = s_format("= %.1f ^8per second", output.IgniteDPS),
					})
					if output.CritIgniteDotMulti and (output.CritIgniteDotMulti ~= output.IgniteDotMulti) then
						local chanceFromHit = output.IgniteChanceOnHit / 100 * (1 - globalOutput.CritChance / 100)
						local chanceFromCrit = output.IgniteChanceOnCrit / 100 * output.CritChance / 100
						local totalFromHit = chanceFromHit / (chanceFromHit + chanceFromCrit)
						local totalFromCrit = chanceFromCrit / (chanceFromHit + chanceFromCrit)
						breakdown.IgniteDotMulti = breakdown.critDot(output.IgniteDotMulti, output.CritIgniteDotMulti, totalFromHit, totalFromCrit)
						output.IgniteDotMulti = (output.IgniteDotMulti * totalFromHit) + (output.CritIgniteDotMulti * totalFromCrit)
					end
					if skillFlags.igniteCanStack then
						breakdown.IgniteDamage = { }
						if isAttack then
							t_insert(breakdown.IgniteDamage, pass.label..":")
						end
						t_insert(breakdown.IgniteDamage, s_format("%.1f ^8(damage per second)", output.IgniteDPS))
						t_insert(breakdown.IgniteDamage, s_format("x %.2fs ^8(ignite duration)", globalOutput.IgniteDuration))
						t_insert(breakdown.IgniteDamage, s_format("= %.1f ^8damage per ignite stack", output.IgniteDamage))
					end
					if globalOutput.IgniteDuration ~= data.misc.IgniteDurationBase then
						globalBreakdown.IgniteDuration = {
							s_format("%.2fs ^8(base duration)", durationBase)
						}
						if durationMod ~= 1 then
							t_insert(globalBreakdown.IgniteDuration, s_format("x %.2f ^8(duration modifier)", durationMod))
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
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.ShockChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.ShockDurationMod = {
					s_format("Ailment mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crits Only" or "Average Damage")
				}
			end
			local baseVal = calcAilmentDamage("Shock", sourceHitDmg, sourceCritDmg) * skillModList:More(cfg, "ShockAsThoughDealing")
			if baseVal > 0 then
				skillFlags.shock = true
				output.ShockDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyShockDuration") / 100 + enemyDB:Sum("INC", nil, "SelfShockDuration") / 100
				output.ShockEffectMod = calcLib.mod(skillModList, cfg, "EnemyShockEffect")
				output.ShockEffectModDisplay = 100 * (output.ShockEffectMod - 1)
				local maximum = skillModList:Override(nil, "ShockMax") or 50
				local current = m_min(globalOutput.CurrentShock or 0, maximum)
				local desired = m_min(enemyDB:Sum("BASE", nil, "DesiredShockVal"), maximum)
				local enemyThreshold = enemyDB:Sum("BASE", nil, "AilmentThreshold") * enemyDB:More(nil, "Life")
				local effList = { 5, 15, 50 }
				if enemyThreshold > 0 then
					local bossEffect = 100 * 0.5 * ((baseVal / enemyThreshold) ^ (0.4)) * (output.ShockEffectMod)
					t_insert(effList, bossEffect)
				end
				if maximum ~= 50 then
					t_insert(effList, maximum)
				end
				if current > 5 and current ~= (15 or 50 or maximum) and current < maximum then
					t_insert(effList, current)
				end
				if desired > 5 and desired ~= (15 or 50 or current or maximum) and desired < maximum and current == 0 then
					t_insert(effList, desired)
				end
				table.sort(effList)
				if breakdown then
					if current > 0 then
						breakdown.ShockDPS.label = s_format("To Shock for %.1f seconds ^8(with a ^7%s%% ^8shock on the enemy)^7", 2 * output.ShockDurationMod, current)
					else
						breakdown.ShockDPS.label = s_format("To Shock for %.1f seconds", 2 * output.ShockDurationMod)
					end
					breakdown.ShockDPS.footer = s_format("^8(ailment threshold is about equal to life, except on bosses where it is about half their life)")
					breakdown.ShockDPS.rowList = { }
					breakdown.ShockDPS.colList = {
						{ label = "Shock Effect", key = "effect" },
						{ label = "Ailment Threshold", key = "thresh" },
					}
					for _, value in ipairs(effList) do
						local thresh = (((100 + (100 * (output.ShockEffectMod - 1)))^(2.5)) * baseVal) / ((2 * value) ^ (2.5))
						local decCheck = value / m_floor(value)
						value = m_floor(value)
						local threshString = ""
						if m_floor(thresh + 0.5) == m_floor(enemyThreshold + 0.5) then
							threshString = s_format("%.0f ^8(AL%.0f %s)", thresh, skillModList:Sum("BASE", nil, "AwakeningLevel"), env.configInput.enemyIsBoss)
						else
							threshString = s_format("%.0f", thresh)
						end
						if decCheck ~= 1 then -- don't put a label on the calculated boss effect
							t_insert(breakdown.ShockDPS.rowList, {
								effect = s_format("%s%%", value),
								thresh = threshString,
							})
						elseif current > 0 and value == current then
							t_insert(breakdown.ShockDPS.rowList, {
								effect = s_format("%s%% ^8(current)", value),
								thresh = threshString,
							})
						elseif value == desired then
							t_insert(breakdown.ShockDPS.rowList, {
								effect = s_format("%s%% ^8(desired)", value),
								thresh = threshString,
							})
						elseif value == maximum then
							t_insert(breakdown.ShockDPS.rowList, {
								effect = s_format("%s%% ^8(maximum)", value),
								thresh = threshString,
							})
						elseif value == 5 then
							t_insert(breakdown.ShockDPS.rowList, {
								effect = s_format("%s%% ^8(minimum)", value),
								thresh = threshString,
							})
						else
							t_insert(breakdown.ShockDPS.rowList, {
								effect = s_format("%s%%", value),
								thresh = threshString,
							})
						end
					end
				end
 			end
		end
		if (output.ChillChanceOnHit + output.ChillChanceOnCrit) > 0 or (activeSkill.skillTypes[SkillType.ChillingArea] or activeSkill.skillTypes[SkillType.ChillNotHit]) then
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
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.ChillChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.ChillDurationMod = {
					s_format("Ailment mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crits Only" or "Average Damage")
				}
			end
			local baseVal = calcAilmentDamage("Chill", sourceHitDmg, sourceCritDmg) * skillModList:More(cfg, "ChillAsThoughDealing")
			if baseVal > 0 then
				skillFlags.chill = true
				output.ChillEffectMod = calcLib.mod(skillModList, cfg, "EnemyChillEffect")
				output.ChillEffectModDisplay = 100 * (output.ChillEffectMod - 1)
				output.ChillDurationMod = 1 + (skillModList:Sum("INC", cfg, "EnemyChillDuration") + enemyDB:Sum("INC", nil, "SelfChillDuration")) / 100
				local enemyThreshold = enemyDB:Sum("BASE", nil, "AilmentThreshold") * enemyDB:More(nil, "Life")
				effList = { 5, 10, 30 }
				local desired = skillModList:Sum("BASE", nil, "DesiredBonechillEffect") or 0
				if output.BonechillEffect then
					t_insert(effList, output.BonechillEffect)
				end
				if not output.BonechillEffect and desired ~= (0 or 5 or 10 or 30 or output.BonechillEffect) and desired > 5 and desired < 30 then
					t_insert(effList, desired)
				end
				if enemyThreshold > 0 then
					local bossEffect = 100 * 0.5 * ((baseVal / enemyThreshold) ^ (0.4)) * (output.ChillEffectMod)
					t_insert(effList, bossEffect)
				end
				table.sort(effList)
				if breakdown then
					breakdown.ChillDPS.label = s_format("To Chill for %.1f seconds", 2 * output.ChillDurationMod)
					if output.BonechillEffect then
						breakdown.ChillDPS.label = s_format("To Chill for %.1f seconds ^8(with a ^7%s%% ^8Bonechill effect on the enemy)^7", 2 * output.ChillDurationMod, output.BonechillEffect)
					else
						breakdown.ChillDPS.label = s_format("To Chill for %.1f seconds", 2 * output.ChillDurationMod)
					end
					breakdown.ChillDPS.rowList = { }
					breakdown.ChillDPS.colList = {
						{ label = "Chill Effect", key = "effect" },
						{ label = "Ailment Threshold", key = "thresh" },
					}
					breakdown.ChillDPS.footer = s_format("^8(ailment threshold is about equal to life, except on bosses where it is about half their life)")
					for _, value in ipairs(effList) do
						local thresh = (((100 + (100 * (output.ChillEffectMod - 1)))^(2.5)) * baseVal) / ((2 * value) ^ (2.5))
						local decCheck = value / m_floor(value)
						value = m_floor(value)
						if m_floor(thresh + 0.5) == m_floor(enemyThreshold + 0.5) then
							threshString = s_format("%.0f ^8(AL%.0f %s)", thresh, skillModList:Sum("BASE", nil, "AwakeningLevel"), env.configInput.enemyIsBoss)
						else
							threshString = s_format("%.0f", thresh)
						end
						if decCheck ~= 1 then -- don't put a label on the calculated boss effect
							t_insert(breakdown.ChillDPS.rowList, {
								effect = s_format("%s%%", value),
								thresh = threshString,
							})
						elseif value == output.BonechillEffect then
							t_insert(breakdown.ChillDPS.rowList, {
								effect = s_format("%s%% ^8(current)", value),
								thresh = threshString,
							})
						elseif value == desired then
							t_insert(breakdown.ChillDPS.rowList, {
								effect = s_format("%s%% ^8(desired)", value),
								thresh = threshString,
							})
						elseif value == 30 then
							t_insert(breakdown.ChillDPS.rowList, {
								effect = s_format("%s%% ^8(maximum)", value),
								thresh = threshString,
							})
						elseif value == 5 then
							t_insert(breakdown.ChillDPS.rowList, {
								effect = s_format("%s%% ^8(minimum)", value),
								thresh = threshString,
							})
						else
							t_insert(breakdown.ChillDPS.rowList, {
								effect = s_format("%s%%", value),
								thresh = threshString,
							})
						end
					end
				end
			end
		end
		if activeSkill.skillTypes[SkillType.ChillingArea] or activeSkill.skillTypes[SkillType.NonHitChill] then
			skillFlags.chill = true
			output.ChillEffectMod = skillModList:Sum("INC", cfg, "EnemyChillEffect")
			output.ChillDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyChillDuration") / 100
			output.ChillSourceEffect = m_min(30, m_floor(10 * (1 + output.ChillEffectMod / 100)))
			if breakdown then
				breakdown.DotChill = { }
				breakdown.multiChain(breakdown.DotChill, {
					label = "Effect of Chill: ^8(capped at 30%)",
					base = "10% ^8(base)",
					{ "%.2f ^8(increased effect of chill)", 1 + output.ChillEffectMod / 100},
					total = s_format("= %.0f%%", output.ChillSourceEffect)
				})
			end
		end
		if (output.FreezeChanceOnHit + output.FreezeChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if canDeal.Cold and not skillModList:Flag(cfg, "ColdCannotFreeze") then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
			end
			if canDeal.Physical and skillModList:Flag(cfg, "PhysicalCanFreeze") then
				sourceHitDmg = sourceHitDmg + output.PhysicalHitAverage
				sourceCritDmg = sourceCritDmg + output.PhysicalCritAverage
			end
			if canDeal.Lightning and skillModList:Flag(cfg, "LightningCanFreeze") then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			if canDeal.Fire and skillModList:Flag(cfg, "FireCanFreeze") then
				sourceHitDmg = sourceHitDmg + output.FireHitAverage
				sourceCritDmg = sourceCritDmg + output.FireCritAverage
			end
			if canDeal.Chaos and skillModList:Flag(cfg, "ChaosCanFreeze") then
				sourceHitDmg = sourceHitDmg + output.ChaosHitAverage
				sourceCritDmg = sourceCritDmg + output.ChaosCritAverage
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.FreezeChanceOnHit = 0
			end
			if globalBreakdown then
				globalBreakdown.FreezeDurationMod = {
					s_format("Ailment mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crits Only" or "Average Damage")
				}
			end
			local baseVal = calcAilmentDamage("Freeze", sourceHitDmg, sourceCritDmg) * skillModList:More(cfg, "FreezeAsThoughDealing")
			if baseVal > 0 then
				skillFlags.freeze = true
				skillFlags.chill = true
				output.FreezeDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyFreezeDuration") / 100 + enemyDB:Sum("INC", nil, "SelfFreezeDuration") / 100
				if breakdown then
					t_insert(breakdown.FreezeDPS, s_format("For freeze to apply for the minimum of 0.3 seconds, target must have no more than %.0f Ailment Threshold.", baseVal * 20 * output.FreezeDurationMod))
					t_insert(breakdown.FreezeDPS, s_format("^8(Ailment Threshold is about equal to Life except on bosses where it is about half of their life)"))
				end
			end
		end
		if (output.ScorchChanceOnHit + output.ScorchChanceOnCrit) > 0 or enemyDB:Flag(nil, "Condition:AlreadyScorched") then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if output.ScorchChanceOnCrit == 0 and output.ScorchChanceOnHit > 0 then
				output.ScorchChanceOnCrit = output.ScorchChanceOnHit
			end
			if canDeal.Fire then
				sourceHitDmg = sourceHitDmg + output.FireHitAverage
				sourceCritDmg = sourceCritDmg + output.FireCritAverage
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.ScorchChanceOnHit = 0
			end
			local baseVal = calcAilmentDamage("Scorch", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 or enemyDB:Flag(nil, "Condition:AlreadyScorched") then
				skillFlags.scorch = true
				output.ScorchEffectMod = skillModList:Sum("INC", cfg, "EnemyScorchEffect")
				output.ScorchDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyScorchDuration") / 100 + enemyDB:Sum("INC", nil, "SelfScorchDuration") / 100
			end
		end
		if (output.BrittleChanceOnHit + output.BrittleChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if output.BrittleChanceOnCrit == 0 and output.BrittleChanceOnHit > 0 then
				output.BrittleChanceOnCrit = output.BrittleChanceOnHit
			end
			if canDeal.Cold then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.BrittleChanceOnHit = 0
			end
			local baseVal = calcAilmentDamage("Brittle", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.brittle = true
				output.BrittleEffectMod = skillModList:Sum("INC", cfg, "EnemyBrittleEffect")
				output.BrittleDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemyBrittleDuration") / 100 + enemyDB:Sum("INC", nil, "SelfBrittleDuration") / 100
			end
		end
		if (output.SapChanceOnHit + output.SapChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if output.SapChanceOnCrit == 0 and output.SapChanceOnHit > 0 then
				output.SapChanceOnCrit = output.SapChanceOnHit
			end
			if canDeal.Lightning then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			local igniteMode = env.configInput.igniteMode or "AVERAGE"
			if igniteMode == "CRIT" then
				output.SapChanceOnHit = 0
			end
			local baseVal = calcAilmentDamage("Sap", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.sap = true
				output.SapEffectMod = skillModList:Sum("INC", cfg, "EnemySapEffect")
				output.SapDurationMod = 1 + skillModList:Sum("INC", cfg, "EnemySapDuration") / 100 + enemyDB:Sum("INC", nil, "SelfSapDuration") / 100
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
			local configStacks = enemyDB:Sum("BASE", cfg, "Multiplier:ImpaleStacks")
			local impaleStacks = m_min(maxStacks, configStacks)

            local baseStoredDamage = data.misc.ImpaleStoredDamageBase
            local storedExpectedDamageIncOnBleed = skillModList:Sum("INC", cfg, "ImpaleEffectOnBleed")*skillModList:Sum("BASE", cfg, "BleedChance")/100
            local storedExpectedDamageInc = (skillModList:Sum("INC", cfg, "ImpaleEffect") + storedExpectedDamageIncOnBleed)/100
            local storedExpectedDamageMore = round(skillModList:More(cfg, "ImpaleEffect"), 2)
            local storedExpectedDamageModifier = (1 + storedExpectedDamageInc) * storedExpectedDamageMore
            local impaleStoredDamage = baseStoredDamage * storedExpectedDamageModifier
            local impaleHitDamageMod = impaleStoredDamage * impaleStacks  -- Source: https://www.reddit.com/r/pathofexile/comments/chgqqt/impale_and_armor_interaction/

            local enemyArmour = calcLib.val(enemyDB, "Armour")
            local impaleArmourReduction = calcs.armourReductionF(enemyArmour, impaleHitDamageMod * output.impaleStoredHitAvg)
            local impaleResist = m_max(0, enemyDB:Sum("BASE", nil, "PhysicalDamageReduction") + skillModList:Sum("BASE", cfg, "EnemyImpalePhysicalDamageReduction") + impaleArmourReduction)

            local impaleDMGModifier = impaleHitDamageMod * (1 - impaleResist / 100) * impaleChance

            globalOutput.ImpaleStacksMax = maxStacks
            globalOutput.ImpaleStacks = impaleStacks
            --ImpaleStoredDamage should be named ImpaleEffect or similar
            --Using the variable name ImpaleEffect breaks the calculations sidebar (?!)
            output.ImpaleStoredDamage = impaleStoredDamage * 100
            output.ImpaleModifier = 1 + impaleDMGModifier

            if breakdown then
                breakdown.ImpaleStoredDamage = {}
                t_insert(breakdown.ImpaleStoredDamage, "10% ^8(base value)")
                t_insert(breakdown.ImpaleStoredDamage, s_format("x %.2f ^8(increased effectiveness)", storedExpectedDamageModifier))
                t_insert(breakdown.ImpaleStoredDamage, s_format("= %.1f%%", output.ImpaleStoredDamage))

                breakdown.ImpaleModifier = {}
                t_insert(breakdown.ImpaleModifier, s_format("%d ^8(number of stacks, can be overridden in the Configuration tab)", impaleStacks))
                t_insert(breakdown.ImpaleModifier, s_format("x %.3f ^8(stored damage)", impaleStoredDamage))
                t_insert(breakdown.ImpaleModifier, s_format("x %.2f ^8(impale chance)", impaleChance))
                t_insert(breakdown.ImpaleModifier, s_format("x %.2f ^8(impale enemy physical damage reduction)", (1 - impaleResist / 100)))
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
		combineStat("TotalPoisonDPS", "DPS")
		combineStat("PoisonDamage", "CHANCE", "PoisonChance")
		if skillData.showAverage then
			combineStat("TotalPoisonAverageDamage", "DPS")
		else
			combineStat("TotalPoisonStacks", "DPS")
		end
		combineStat("IgniteChance", "AVERAGE")
		combineStat("IgniteDPS", "CHANCE", "IgniteChance")
		if skillFlags.igniteCanStack then
			combineStat("IgniteDamage", "CHANCE", "IgniteChance")
			if skillData.showAverage then
				combineStat("TotalIgniteAverageDamage", "DPS")
				combineStat("TotalIgniteStacks", "DPS")
				combineStat("TotalIgniteDPS", "DPS")
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
		combineStat("ScorchChance", "AVERAGE")
		combineStat("ScorchEffectMod", "AVERAGE")
		combineStat("ScorchDurationMod", "AVERAGE")
		combineStat("BrittleChance", "AVERAGE")
		combineStat("BrittleEffectMod", "AVERAGE")
		combineStat("BrittleDurationMod", "AVERAGE")
		combineStat("SapChance", "AVERAGE")
		combineStat("SapEffectMod", "AVERAGE")
		combineStat("SapDurationMod", "AVERAGE")
		combineStat("BrittleChance", "AVERAGE")
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
			local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist") * calcLib.mod(enemyDB, nil, "ChaosResist"), data.misc.EnemyMaxResist)
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
			breakdown.dot(breakdown.DecayDPS, skillData.decay, inc, more, mult, nil, nil, effMult, output.DecayDPS)
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

	-- Calculate skill DOT components
	local dotCfg = {
		skillName = skillCfg.skillName,
		skillPart = skillCfg.skillPart,
		skillTypes = skillCfg.skillTypes,
		slotName = skillCfg.slotName,
		flags = bor(ModFlag.Dot, skillCfg.flags),
		keywordFlags = band(skillCfg.keywordFlags, bnot(KeywordFlag.Hit)),
	}
	if bor(dotCfg.flags, ModFlag.Area) == dotCfg.flags and not skillData.dotIsArea then
		dotCfg.flags = band(dotCfg.flags, bnot(ModFlag.Area))
	end
	if bor(dotCfg.flags, ModFlag.Projectile) == dotCfg.flags and not skillData.dotIsProjectile then
		dotCfg.flags = band(dotCfg.flags, bnot(ModFlag.Projectile))
	end
	if bor(dotCfg.flags, ModFlag.Spell) == dotCfg.flags and not skillData.dotIsSpell then
		dotCfg.flags = band(dotCfg.flags, bnot(ModFlag.Spell))
	end
	if bor(dotCfg.flags, ModFlag.Attack) == dotCfg.flags and not skillData.dotIsAttack then
		dotCfg.flags = band(dotCfg.flags, bnot(ModFlag.Attack))
	end
	if bor(dotCfg.flags, ModFlag.Hit) == dotCfg.flags and not skillData.dotIsHit then
		dotCfg.flags = band(dotCfg.flags, bnot(ModFlag.Hit))
	end

	-- spell_damage_modifiers_apply_to_skill_dot does not apply to enemy damage taken
	local dotTakenCfg = copyTable(dotCfg, true)
	if (skillData.dotIsSpell) then
		dotTakenCfg.flags = band(dotTakenCfg.flags, bnot(ModFlag.Spell))
	end

	activeSkill.dotCfg = dotCfg
	output.TotalDotInstance = 0
	
	runSkillFunc("preDotFunc")

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
		if baseVal > 0 or (output[damageType.."Dot"] or 0) > 0 then
			skillFlags.dot = true
			local effMult = 1
			if env.mode_effective then
				local resist = 0
				local takenInc = enemyDB:Sum("INC", dotTakenCfg, "DamageTaken", "DamageTakenOverTime", damageType.."DamageTaken", damageType.."DamageTakenOverTime")
				local takenMore = enemyDB:More(dotTakenCfg, "DamageTaken", "DamageTakenOverTime", damageType.."DamageTaken", damageType.."DamageTakenOverTime")
				if damageType == "Physical" then
					resist = enemyDB:Sum("BASE", nil, "PhysicalDamageReduction")
				else
					if env.modDB:Flag(nil, "Enemy"..damageType.."ResistEqualToYours") then
						resist = env.player.output[damageType.."Resist"]
					else
						resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
						if isElemental[damageType] then
							local base = resist + enemyDB:Sum("BASE", dotTypeCfg, "ElementalResist")
							resist = base * calcLib.mod(enemyDB, nil, damageType.."Resist")
							takenInc = takenInc + enemyDB:Sum("INC", dotTypeCfg, "ElementalDamageTaken")
						end
					end
					resist = m_min(resist, data.misc.EnemyMaxResist)
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
			local aura = activeSkill.skillTypes[SkillType.Aura] and not activeSkill.skillTypes[SkillType.RemoteMined] and calcLib.mod(skillModList, dotTypeCfg, "AuraEffect")
			local total = baseVal * (1 + inc/100) * more * (1 + mult/100) * (aura or 1) * effMult
			if output[damageType.."Dot"] == 0 or output[damageType.."Dot"] == nil then
				output[damageType.."Dot"] = total
				output.TotalDotInstance = output.TotalDotInstance + total
			else
				output.TotalDotInstance = output.TotalDotInstance + total + (output[damageType.."Dot"] or 0)
			end
			if breakdown then
				breakdown[damageType.."Dot"] = { }
				breakdown.dot(breakdown[damageType.."Dot"], baseVal, inc, more, mult, nil, aura, effMult, total)
			end
		end
	end
	if skillModList:Flag(nil, "DotCanStack") then
		skillFlags.DotCanStack = true
		local speed = output.Speed
		-- Check if skill is being triggered via Mine (e.g., Blastchain Mine Support) or Trap
		-- if "yes", you cannot use output.Speed but rather should use output.MineLayingSpeed or output.TrapThrowingSpeed
		if band(dotCfg.keywordFlags, KeywordFlag.Mine) ~= 0 then
			speed = output.MineLayingSpeed
		elseif band(dotCfg.keywordFlags, KeywordFlag.Trap) ~= 0 then
			speed = output.TrapThrowingSpeed
		end
		output.TotalDot = output.TotalDotInstance * speed * output.Duration * (skillData.dpsMultiplier or 1) * quantityMultiplier
		if breakdown then
			breakdown.TotalDot = {
				s_format("%.1f ^8(Damage per Instance)", output.TotalDotInstance),
				s_format("x %.2f ^8(hits per second)", speed),
				s_format("x %.2f ^8(skill duration)", output.Duration),
			}
			if skillData.dpsMultiplier then
				t_insert(breakdown.TotalDot, s_format("x %g ^8(DPS multiplier for this skill)", skillData.dpsMultiplier))
			end
			if quantityMultiplier > 1 then
				t_insert(breakdown.TotalDot, s_format("x %g ^8(quantity multiplier for this skill)", quantityMultiplier))
			end
			t_insert(breakdown.TotalDot, s_format("= %.1f", output.TotalDot))
		end
	else
		output.TotalDot = output.TotalDotInstance
	end

	-- The Saviour
	if activeSkill.activeEffect.grantedEffect.name == "Reflection" then
		local usedSkill = nil
		local usedSkillBestDps = 0
		local calcMode = env.mode == "CALCS" and "CALCS" or "MAIN"
		for _, triggerSkill in ipairs(actor.activeSkillList) do
			if triggerSkill ~= activeSkill and triggerSkill.skillTypes[SkillType.Attack] and band(triggerSkill.skillCfg.flags, bor(ModFlag.Sword, ModFlag.Weapon1H)) == bor(ModFlag.Sword, ModFlag.Weapon1H) then
				-- Grab a fully-processed by calcs.perform() version of the skill that Mirage Warrior(s) will use
				local uuid = cacheSkillUUID(triggerSkill)
				if not GlobalCache.cachedData[calcMode][uuid] then
					calcs.buildActiveSkill(env, calcMode, triggerSkill)
					env.dontCache = true
				end
				-- We found a skill and it can crit
				if GlobalCache.cachedData[calcMode][uuid] and GlobalCache.cachedData[calcMode][uuid].CritChance and GlobalCache.cachedData[calcMode][uuid].CritChance > 0 then
					if not usedSkill then
						usedSkill = GlobalCache.cachedData[calcMode][uuid].ActiveSkill
						usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
					else
						if GlobalCache.cachedData[calcMode][uuid].TotalDPS > usedSkillBestDps then
							usedSkill = GlobalCache.cachedData[calcMode][uuid].ActiveSkill
							usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
						end
					end
				end
			end
		end

		if usedSkill then
			local moreDamage = activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "SaviourMirageWarriorLessDamage")
			local maxMirageWarriors = activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "SaviourMirageWarriorMaxCount")
			local newSkill, newEnv = calcs.copyActiveSkill(env, calcMode, usedSkill)

			-- Add new modifiers to new skill (which already has all the old skill's modifiers)
			newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "The Saviour", activeSkill.ModFlags, activeSkill.KeywordFlags)
			if env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 1"].name == env.player.itemList["Weapon 2"].name then
				maxMirageWarriors = maxMirageWarriors / 2
			end
			newSkill.skillModList:NewMod("QuantityMultiplier", "BASE", maxMirageWarriors, "The Saviour Mirage Warriors", activeSkill.ModFlags, activeSkill.KeywordFlags)

			if usedSkill.skillPartName then
				env.player.mainSkill.skillPart = usedSkill.skillPart
				env.player.mainSkill.skillPartName = usedSkill.skillPartName
				env.player.mainSkill.infoMessage2 = usedSkill.activeEffect.grantedEffect.name
			else
				env.player.mainSkill.skillPartName = usedSkill.activeEffect.grantedEffect.name
			end

			-- Recalculate the offensive/defensive aspects of this new skill
			newEnv.player.mainSkill = newSkill
			calcs.perform(newEnv)
			env.player.mainSkill = newSkill

			env.player.mainSkill.infoMessage = tostring(maxMirageWarriors) .. " Mirage Warriors using " .. usedSkill.activeEffect.grantedEffect.name

			-- Re-link over the output
			env.player.output = newEnv.player.output
			if newSkill.minion then
				env.minion = newEnv.player.mainSkill.minion
				env.minion.output = newEnv.minion.output
			end

			-- Make any necessary corrections to output
			env.player.output.ManaCost = 0

			-- Re-link over the breakdown (if present)
			if newEnv.player.breakdown then
				env.player.breakdown = newEnv.player.breakdown

				-- Make any necessary corrections to breakdown
				env.player.breakdown.ManaCost = nil

				if newSkill.minion then
					env.minion.breakdown = newEnv.minion.breakdown
				end
			end
		else
			activeSkill.infoMessage2 = "No Saviour active skill found"
		end
	end

	-- Calculate combined DPS estimate, including DoTs
	local baseDPS = output[(skillData.showAverage and "AverageDamage") or "TotalDPS"]
	output.CombinedDPS = baseDPS
	output.CombinedAvg = baseDPS
	if skillFlags.dot then
		output.CombinedDPS = output.CombinedDPS + (output.TotalDot or 0)
		output.WithDotDPS = baseDPS + (output.TotalDot or 0)
	end
	if quantityMultiplier > 1 and output.TotalPoisonDPS then
		output.TotalPoisonDPS = output.TotalPoisonDPS * quantityMultiplier
	end
	if skillData.showAverage then
		output.CombinedDPS = output.CombinedDPS + (output.TotalPoisonDPS or 0)
		output.CombinedAvg = output.CombinedAvg + (output.PoisonDamage or 0)
		output.WithPoisonDPS = baseDPS + (output.TotalPoisonAverageDamage or 0)
	else
		output.CombinedDPS = output.CombinedDPS + (output.TotalPoisonDPS or 0)
		output.WithPoisonDPS = baseDPS + (output.TotalPoisonDPS or 0)
	end
	if skillFlags.ignite then
		if skillFlags.igniteCanStack then
			if skillData.showAverage then
				output.CombinedDPS = output.CombinedDPS + output.TotalIgniteDPS
				output.CombinedAvg = output.CombinedDPS + output.IgniteDamage
			else
				output.CombinedDPS = output.CombinedDPS + output.TotalIgniteDPS
				output.WithIgniteDPS = baseDPS + output.TotalIgniteDPS
			end
		elseif skillData.showAverage then
			output.WithIgniteDPS = baseDPS + output.IgniteDamage
			output.CombinedDPS = output.CombinedDPS + output.IgniteDPS
			output.CombinedAvg = output.CombinedAvg + output.IgniteDamage
		else
			output.WithIgniteDPS = baseDPS + output.IgniteDPS
			output.CombinedDPS = output.CombinedDPS + output.IgniteDPS
		end
	else
		output.WithIgniteDPS = baseDPS
	end
	if skillFlags.bleed then
		if skillData.showAverage then
			output.WithBleedDPS = baseDPS + output.BleedDamage
			output.CombinedDPS = output.CombinedDPS + output.BleedDPS
			output.CombinedAvg = output.CombinedAvg + output.BleedDamage
		else
			output.WithBleedDPS = baseDPS + output.BleedDPS
			output.CombinedDPS = output.CombinedDPS + output.BleedDPS
		end
	else
		output.WithBleedDPS = baseDPS
	end
	if skillFlags.decay then
		output.CombinedDPS = output.CombinedDPS + output.DecayDPS
	end
	output.TotalDotDPS = (output.TotalDot or 0) + (output.TotalPoisonDPS or 0) + (output.TotalIgniteDPS or output.IgniteDPS or 0) + (output.BleedDPS or 0) + (output.DecayDPS or 0)
	if skillFlags.impale then
		if skillFlags.attack then
			output.ImpaleHit = ((output.MainHand.PhysicalHitAverage or output.OffHand.PhysicalHitAverage) + (output.OffHand.PhysicalHitAverage or output.MainHand.PhysicalHitAverage)) / 2 * (1-output.CritChance/100) + ((output.MainHand.PhysicalCritAverage or output.OffHand.PhysicalCritAverage) + (output.OffHand.PhysicalCritAverage or output.MainHand.PhysicalCritAverage)) / 2 * (output.CritChance/100)
			if skillData.doubleHitsWhenDualWielding and skillFlags.bothWeaponAttack then
				output.ImpaleHit = output.ImpaleHit * 2
			end
		else
			output.ImpaleHit = output.PhysicalHitAverage * (1-output.CritChance/100) + output.PhysicalCritAverage * (output.CritChance/100)
		end
		output.ImpaleDPS = output.ImpaleHit * ((output.ImpaleModifier or 1) - 1) * output.HitChance / 100 * (skillData.dpsMultiplier or 1)
		if skillData.showAverage then
			output.WithImpaleDPS = output.AverageDamage + output.ImpaleDPS
			output.CombinedAvg = output.CombinedAvg + output.ImpaleDPS
		else
			skillFlags.notAverage = true
			output.ImpaleDPS = output.ImpaleDPS * (output.HitSpeed or output.Speed)
			output.WithImpaleDPS = output.TotalDPS + output.ImpaleDPS
		end
		if quantityMultiplier > 1 then
			output.ImpaleDPS = output.ImpaleDPS * quantityMultiplier
		end
		output.CombinedDPS = output.CombinedDPS + output.ImpaleDPS
		if breakdown then
			breakdown.ImpaleDPS = {}
			t_insert(breakdown.ImpaleDPS, s_format("%.2f ^8(average physical hit)", output.ImpaleHit))
			t_insert(breakdown.ImpaleDPS, s_format("x %.2f ^8(chance to hit)", output.HitChance / 100))
			if skillFlags.notAverage then
				t_insert(breakdown.ImpaleDPS, output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(%s rate)", output.Speed, skillFlags.attack and "attack" or "cast"))
			end
			t_insert(breakdown.ImpaleDPS, s_format("x %.2f ^8(impale damage multiplier)", ((output.ImpaleModifier or 1) - 1)))
			if skillData.dpsMultiplier then
				t_insert(breakdown.ImpaleDPS, s_format("x %g ^8(dps multiplier for this skill)", skillData.dpsMultiplier))
			end
			if quantityMultiplier > 1 then
				t_insert(breakdown.ImpaleDPS, s_format("x %g ^8(quantity multiplier for this skill)", quantityMultiplier))
			end
			t_insert(breakdown.ImpaleDPS, s_format("= %.1f", output.ImpaleDPS))
		end
	end
	if output.CullMultiplier > 1 then
		output.CullingDPS = output.CombinedDPS * (output.CullMultiplier - 1)
	end
	output.CombinedDPS = output.CombinedDPS * output.CullMultiplier

	if activeSkill.mirage and activeSkill.mirage.output and activeSkill.mirage.output.TotalDPS then
		local mirageCount = activeSkill.mirage.count or 1
		output.MirageDPS = activeSkill.mirage.output.TotalDPS * mirageCount
		output.CombinedDPS = output.CombinedDPS + activeSkill.mirage.output.TotalDPS * mirageCount

		if activeSkill.mirage.output.IgniteDPS and activeSkill.mirage.output.IgniteDPS > (output.IgniteDPS or 0) then
			output.MirageDPS = output.MirageDPS + activeSkill.mirage.output.IgniteDPS
			output.IgniteDPS = 0
		end
		if activeSkill.mirage.output.BleedDPS and activeSkill.mirage.output.BleedDPS > (output.BleedDPS or 0) then
			output.MirageDPS = output.MirageDPS + activeSkill.mirage.output.BleedDPS
			output.BleedDPS = 0
		end

		if activeSkill.mirage.output.PoisonDPS then
			output.MirageDPS = output.MirageDPS + activeSkill.mirage.output.PoisonDPS * mirageCount
			output.CombinedDPS = output.CombinedDPS + activeSkill.mirage.output.PoisonDPS * mirageCount
		end
		if activeSkill.mirage.output.ImpaleDPS then
			output.MirageDPS = output.MirageDPS + activeSkill.mirage.output.ImpaleDPS * mirageCount
			output.CombinedDPS = output.CombinedDPS + activeSkill.mirage.output.ImpaleDPS * mirageCount
		end
		if activeSkill.mirage.output.DecayDPS then
			output.MirageDPS = output.MirageDPS + activeSkill.mirage.output.DecayDPS
			output.CombinedDPS = output.CombinedDPS + activeSkill.mirage.output.DecayDPS
		end
		if activeSkill.mirage.output.TotalDot and (skillFlags.DotCanStack or not output.TotalDot or output.TotalDot == 0) then
			output.MirageDPS = output.MirageDPS + activeSkill.mirage.output.TotalDot * (skillFlags.DotCanStack and mirageCount or 1)
			output.CombinedDPS = output.CombinedDPS + activeSkill.mirage.output.TotalDot * (skillFlags.DotCanStack and mirageCount or 1)
		end
	end
end
