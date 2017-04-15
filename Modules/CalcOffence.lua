-- Path of Building
--
-- Module: Calc Offence
-- Performs offence calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
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

-- Calculate min/max damage of a hit for the given damage type
local function calcHitDamage(actor, source, cfg, breakdown, damageType, ...)
	local modDB = actor.modDB

	local damageTypeMin = damageType.."Min"
	local damageTypeMax = damageType.."Max"

	-- Calculate base values
	local damageEffectiveness = actor.mainSkill.skillData.damageEffectiveness or 1
	local addedMin = modDB:Sum("BASE", cfg, damageTypeMin)
	local addedMax = modDB:Sum("BASE", cfg, damageTypeMax)
	local baseMin = (source[damageTypeMin] or 0) + addedMin * damageEffectiveness
	local baseMax = (source[damageTypeMax] or 0) + addedMax * damageEffectiveness

	if breakdown and not (...) and baseMin ~= 0 and baseMax ~= 0 then
		t_insert(breakdown, "Base damage:")
		local plus = ""
		if (source[damageTypeMin] or 0) ~= 0 or (source[damageTypeMax] or 0) ~= 0 then
			t_insert(breakdown, s_format("%d to %d ^8(base damage from %s)", source[damageTypeMin], source[damageTypeMax], source.type and "weapon" or "skill"))
			plus = "+ "
		end
		if addedMin ~= 0 or addedMax ~= 0 then
			if damageEffectiveness ~= 1 then
				t_insert(breakdown, s_format("%s(%d to %d) x %.2f ^8(added damage multiplied by damage effectiveness)", plus, addedMin, addedMax, damageEffectiveness))
			else
				t_insert(breakdown, s_format("%s%d to %d ^8(added damage)", plus, addedMin, addedMax))
			end
		end
		t_insert(breakdown, s_format("= %.1f to %.1f", baseMin, baseMax))
	end

	-- Calculate conversions
	local addMin, addMax = 0, 0
	local conversionTable = actor.conversionTable
	for _, otherType in ipairs(dmgTypeList) do
		if otherType == damageType then
			-- Damage can only be converted from damage types that preceed this one in the conversion sequence, so stop here
			break
		end
		local convMult = conversionTable[otherType][damageType]
		if convMult > 0 then
			-- Damage is being converted/gained from the other damage type
			local min, max = calcHitDamage(actor, source, cfg, breakdown, otherType, damageType, ...)
			addMin = addMin + min * convMult
			addMax = addMax + max * convMult
		end
	end
	if addMin ~= 0 and addMax ~= 0 then
		addMin = round(addMin)
		addMax = round(addMax)
	end

	if baseMin == 0 and baseMax == 0 then
		-- No base damage for this type, don't need to calculate modifiers
		if breakdown and (addMin ~= 0 or addMax ~= 0) then
			t_insert(breakdown.damageComponents, {
				source = damageType,
				convSrc = (addMin ~= 0 or addMax ~= 0) and (addMin .. " to " .. addMax),
				total = addMin .. " to " .. addMax,
				convDst = (...) and s_format("%d%% to %s", conversionTable[damageType][...] * 100, ...),
			})
		end
		return addMin, addMax
	end

	-- Build lists of applicable modifier names
	local addElemental = isElemental[damageType]
	local modNames = { damageType.."Damage", "Damage" }
	for i = 1, select('#', ...) do
		local dstElem = select(i, ...)
		-- Add modifiers for damage types to which this damage is being converted
		addElemental = addElemental or isElemental[dstElem]
		t_insert(modNames, dstElem.."Damage")
	end
	if addElemental then
		-- Damage is elemental or is being converted to elemental damage, add global elemental modifiers
		t_insert(modNames, "ElementalDamage")
	end

	-- Combine modifiers
	local inc = 1 + modDB:Sum("INC", cfg, unpack(modNames)) / 100
	local more = m_floor(modDB:Sum("MORE", cfg, unpack(modNames)) * 100 + 0.50000001) / 100

	if breakdown then
		t_insert(breakdown.damageComponents, {
			source = damageType,
			base = baseMin .. " to " .. baseMax,
			inc = (inc ~= 1 and "x "..inc),
			more = (more ~= 1 and "x "..more),
			convSrc = (addMin ~= 0 or addMax ~= 0) and (addMin .. " to " .. addMax),
			total = (round(baseMin * inc * more) + addMin) .. " to " .. (round(baseMax * inc * more) + addMax),
			convDst = (...) and s_format("%d%% to %s", conversionTable[damageType][...] * 100, ...),
		})
	end

	return (round(baseMin * inc * more) + addMin),
		   (round(baseMax * inc * more) + addMax)
end

-- Performs all offensive calculations
function calcs.offence(env, actor)
	local modDB = actor.modDB
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local breakdown = actor.breakdown

	local mainSkill = actor.mainSkill
	local skillData = mainSkill.skillData
	local skillFlags = mainSkill.skillFlags
	local skillCfg = mainSkill.skillCfg
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

	-- Merge main skill mods
	modDB:AddList(mainSkill.skillModList)

	-- Update skill data
	for _, value in ipairs(modDB:Sum("LIST", skillCfg, "Misc")) do
		if value.type == "SkillData" then
			if value.merge == "MAX" then
				skillData[value.key] = m_max(value.value, skillData[value.key] or 0)
			else
				skillData[value.key] = value.value
			end
		end
	end

	skillCfg.skillCond["SkillIsTriggered"] = skillData.triggered

	-- Add addition stat bonuses
	if modDB:Sum("FLAG", nil, "IronGrip") then
		modDB:NewMod("PhysicalDamage", "INC", actor.strDmgBonus, "Strength", bor(ModFlag.Attack, ModFlag.Projectile))
	end
	if modDB:Sum("FLAG", nil, "IronWill") then
		modDB:NewMod("Damage", "INC", actor.strDmgBonus, "Strength", ModFlag.Spell)
	end

	if modDB:Sum("FLAG", nil, "MinionDamageAppliesToPlayer") then
		-- Minion Damage conversion from The Scourge
		for _, value in ipairs(modDB:Sum("LIST", env.player.mainSkill.skillCfg, "Misc")) do
			if value.type == "MinionModifier" and value.mod.name == "Damage "then
				modDB:AddMod(value.mod)
			end
		end
	end
	if modDB:Sum("FLAG", nil, "SpellDamageAppliesToAttacks") then
		-- Spell Damage conversion from Crown of Eyes
		for i, mod in ipairs(modDB.mods.Damage or { }) do
			if mod.type == "INC" and band(mod.flags, ModFlag.Spell) ~= 0 then
				modDB:NewMod("Damage", "INC", mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Spell)), ModFlag.Attack), mod.keywordFlags, unpack(mod.tagList))
			end
		end
	end
	if modDB:Sum("FLAG", nil, "ClawDamageAppliesToUnarmed") then
		-- Claw Damage conversion from Rigwald's Curse
		for i, mod in ipairs(modDB.mods.PhysicalDamage or { }) do
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				modDB:NewMod("PhysicalDamage", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod.tagList))
			end
		end
	end
	if modDB:Sum("FLAG", nil, "ClawAttackSpeedAppliesToUnarmed") then
		-- Claw Attack Speed conversion from Rigwald's Curse
		for i, mod in ipairs(modDB.mods.Speed or { }) do
			if band(mod.flags, ModFlag.Claw) ~= 0 and band(mod.flags, ModFlag.Attack) ~= 0 then
				modDB:NewMod("Speed", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod.tagList))
			end
		end
	end
	if modDB:Sum("FLAG", nil, "ClawCritChanceAppliesToUnarmed") then
		-- Claw Crit Chance conversion from Rigwald's Curse
		for i, mod in ipairs(modDB.mods.CritChance or { }) do
			if band(mod.flags, ModFlag.Claw) ~= 0 then
				modDB:NewMod("CritChance", mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Claw)), ModFlag.Unarmed), mod.keywordFlags, unpack(mod.tagList))
			end
		end
	end

	local isAttack = skillFlags.attack

	-- Calculate skill type stats
	if skillFlags.minion then
		if mainSkill.minion and mainSkill.minion.minionData.limit then
			output.ActiveMinionLimit = m_floor(calcLib.val(modDB, mainSkill.minion.minionData.limit, skillCfg))
		end
	end
	if skillFlags.projectile then
		if modDB:Sum("FLAG", nil, "PointBlank") then
			modDB:NewMod("Damage", "MORE", 50, "Point Blank", bor(ModFlag.Attack, ModFlag.Projectile), { type = "DistanceRamp", ramp = {{10,1},{35,0},{150,-1}} })
		end
		output.ProjectileCount = modDB:Sum("BASE", skillCfg, "ProjectileCount")
		output.PierceChance = m_min(100, modDB:Sum("BASE", skillCfg, "PierceChance"))
		output.ProjectileSpeedMod = calcLib.mod(modDB, skillCfg, "ProjectileSpeed")
		if breakdown then
			breakdown.ProjectileSpeedMod = breakdown.mod(skillCfg, "ProjectileSpeed")
		end
	end
	if skillFlags.area then
		output.AreaOfEffectMod = calcLib.mod(modDB, skillCfg, "AreaOfEffect")
		if breakdown then
			breakdown.AreaOfEffectMod = breakdown.mod(skillCfg, "AreaOfEffect")
		end
	end
	if skillFlags.trap then
		output.ActiveTrapLimit = modDB:Sum("BASE", skillCfg, "ActiveTrapLimit")
		output.TrapCooldown = (skillData.trapCooldown or 4) / calcLib.mod(modDB, skillCfg, "CooldownRecovery")
		if breakdown then
			breakdown.TrapCooldown = {
				s_format("%.2fs ^8(base)", skillData.trapCooldown or 4),
				s_format("/ %.2f ^8(increased/reduced cooldown recovery)", 1 + modDB:Sum("INC", skillCfg, "CooldownRecovery") / 100),
				s_format("= %.2fs", output.TrapCooldown)
			}
		end
	elseif skillData.cooldown then
		output.Cooldown = skillData.cooldown / calcLib.mod(modDB, skillCfg, "CooldownRecovery")
		if breakdown then
			breakdown.Cooldown = {
				s_format("%.2fs ^8(base)", skillData.cooldown),
				s_format("/ %.2f ^8(increased/reduced cooldown recovery)", 1 + modDB:Sum("INC", skillCfg, "CooldownRecovery") / 100),
				s_format("= %.2fs", output.Cooldown)
			}
		end
	end
	if skillFlags.mine then
		output.ActiveMineLimit = modDB:Sum("BASE", skillCfg, "ActiveMineLimit")
	end
	if skillFlags.totem then
		output.ActiveTotemLimit = modDB:Sum("BASE", skillCfg, "ActiveTotemLimit")
		output.TotemLifeMod = calcLib.mod(modDB, skillCfg, "TotemLife")
		output.TotemLife = round(m_floor(data.monsterLifeTable[skillData.totemLevel] * data.totemLifeMult[mainSkill.skillTotemId]) * output.TotemLifeMod)
		if breakdown then
			breakdown.TotemLifeMod = breakdown.mod(skillCfg, "TotemLife")
			breakdown.TotemLife = {
				"Totem level: "..skillData.totemLevel,
				data.monsterLifeTable[skillData.totemLevel].." ^8(base life for a level "..skillData.totemLevel.." monster)",
				"x "..data.totemLifeMult[mainSkill.skillTotemId].." ^8(life multiplier for this totem type)",
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
		output.DurationMod = calcLib.mod(modDB, skillCfg, "Duration")
		if breakdown then
			breakdown.DurationMod = breakdown.mod(skillCfg, "Duration")
		end
		local durationBase = skillData.duration or 0
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
	end

	-- Run skill setup function
	do
		local setupFunc = mainSkill.activeGem.data.setupFunc
		if setupFunc then
			setupFunc(actor, output)
		end
	end

	-- Cache global damage disabling flags
	local canDeal = { }
	for _, damageType in pairs(dmgTypeList) do
		canDeal[damageType] = not modDB:Sum("FLAG", skillCfg, "DealNo"..damageType)
	end

	-- Calculate damage conversion percentages
	actor.conversionTable = wipeTable(actor.conversionTable)
	for damageTypeIndex = 1, 4 do
		local damageType = dmgTypeList[damageTypeIndex]
		local globalConv = wipeTable(tempTable1)
		local skillConv = wipeTable(tempTable2)
		local add = wipeTable(tempTable3)
		local globalTotal, skillTotal = 0, 0
		for otherTypeIndex = damageTypeIndex + 1, 5 do
			-- For all possible destination types, check for global and skill conversions
			otherType = dmgTypeList[otherTypeIndex]
			globalConv[otherType] = modDB:Sum("BASE", skillCfg, damageType.."DamageConvertTo"..otherType, isElemental[damageType] and "ElementalDamageConvertTo"..otherType or nil)
			globalTotal = globalTotal + globalConv[otherType]
			skillConv[otherType] = modDB:Sum("BASE", skillCfg, "Skill"..damageType.."DamageConvertTo"..otherType)
			skillTotal = skillTotal + skillConv[otherType]
			add[otherType] = modDB:Sum("BASE", skillCfg, damageType.."DamageGainAs"..otherType, isElemental[damageType] and "ElementalDamageGainAs"..otherType or nil)
		end
		if skillTotal > 100 then
			-- Skill conversion exceeds 100%, scale it down and remove non-skill conversions
			local factor = 100 / skillTotal
			for type, val in pairs(skillConv) do
				-- The game currently doesn't scale this down even though it is supposed to
				--skillConv[type] = val * factor
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
		actor.conversionTable[damageType] = dmgTable
	end
	actor.conversionTable["Chaos"] = { mult = 1 }

	-- Calculate mana cost (may be slightly off due to rounding differences)
	do
		local more = m_floor(modDB:Sum("MORE", skillCfg, "ManaCost") * 100 + 0.0001) / 100
		local inc = modDB:Sum("INC", skillCfg, "ManaCost")
		local base = modDB:Sum("BASE", skillCfg, "ManaCost")
		output.ManaCost = m_floor(m_max(0, (skillData.manaCost or 0) * more * (1 + inc / 100) + base))
		if mainSkill.skillTypes[SkillType.ManaCostPercent] and skillFlags.totem then
			output.ManaCost = m_floor(output.Mana * output.ManaCost / 100)
		end
		if breakdown and output.ManaCost ~= (skillData.manaCost or 0) then
			breakdown.ManaCost = {
				s_format("%d ^8(base mana cost)", skillData.manaCost or 0)
			}
			if more ~= 1 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(mana cost multiplier)", more))
			end
			if inc ~= 0 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(increased/reduced mana cost)", 1 + inc/100))
			end	
			if base ~= 0 then
				t_insert(breakdown.ManaCost, s_format("- %d ^8(- mana cost)", -base))
			end
			t_insert(breakdown.ManaCost, s_format("= %d", output.ManaCost))
		end
	end

	-- Configure damage passes
	local passList = { }
	if isAttack then
		output.MainHand = { }
		output.OffHand = { }
		if skillFlags.weapon1Attack then
			if breakdown then
				breakdown.MainHand = LoadModule("Modules/CalcBreakdown", modDB, output.MainHand)
			end
			mainSkill.weapon1Cfg.skillStats = output.MainHand
			t_insert(passList, {
				label = "Main Hand",
				source = actor.weaponData1,
				cfg = mainSkill.weapon1Cfg,
				output = output.MainHand,
				breakdown = breakdown and breakdown.MainHand,
			})
		end
		if skillFlags.weapon2Attack then
			if breakdown then
				breakdown.OffHand = LoadModule("Modules/CalcBreakdown", modDB, output.OffHand)
			end
			mainSkill.weapon2Cfg.skillStats = output.OffHand
			t_insert(passList, {
				label = "Off Hand",
				source = actor.weaponData2,
				cfg = mainSkill.weapon2Cfg,
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
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown
		
		-- Calculate hit chance
		output.Accuracy = calcLib.val(modDB, "Accuracy", cfg)
		if breakdown then
			breakdown.Accuracy = breakdown.simple(nil, cfg, output.Accuracy, "Accuracy")
		end
		if not isAttack or modDB:Sum("FLAG", cfg, "CannotBeEvaded") or skillData.cannotBeEvaded then
			output.HitChance = 100
		else
			local enemyEvasion = round(calcLib.val(enemyDB, "Evasion"))
			output.HitChance = calcLib.hitChance(enemyEvasion, output.Accuracy)
			if breakdown then
				breakdown.HitChance = {
					"Enemy level: "..env.enemyLevel..(env.configInput.enemyLevel and " ^8(overridden from the Configuration tab" or " ^8(can be overridden in the Configuration tab)"),
					"Average enemy evasion: "..enemyEvasion,
					"Approximate hit chance: "..output.HitChance.."%",
				}
			end
		end

		-- Calculate attack/cast speed
		if skillData.timeOverride then
			output.Time = skillData.timeOverride
			output.Speed = 1 / output.Time
		else
			local baseSpeed
			if isAttack then
				if skillData.castTimeOverridesAttackTime then
					-- Skill is overriding weapon attack speed
					baseSpeed = 1 / skillData.castTime * (1 + (source.AttackSpeedInc or 0) / 100)
				else
					baseSpeed = source.attackRate or 1
				end
			else
				baseSpeed = 1 / (skillData.castTime or 1)
			end
			output.Speed = baseSpeed * round(calcLib.mod(modDB, cfg, "Speed"), 2)
			output.Time = 1 / output.Speed
			if breakdown then
				breakdown.Speed = breakdown.simple(baseSpeed, cfg, output.Speed, "Speed")
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
		output.Time = 1 / output.Speed
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
		if modDB:Sum("FLAG", nil, "NeverCrit") then
			output.PreEffectiveCritChance = 0
			output.CritChance = 0
			output.CritMultiplier = 0
			output.CritEffect = 1
		else
			local baseCrit = source.critChance or 0
			if baseCrit == 100 then
				output.PreEffectiveCritChance = 100
				output.CritChance = 100
			else
				local base = modDB:Sum("BASE", cfg, "CritChance")
				local inc = modDB:Sum("INC", cfg, "CritChance")
				local more = modDB:Sum("MORE", cfg, "CritChance")
				output.CritChance = (baseCrit + base) * (1 + inc / 100) * more
				if env.mode_effective then
					output.CritChance = output.CritChance + enemyDB:Sum("BASE", nil, "SelfExtraCritChance")
				end
				local preCapCritChance = output.CritChance
				output.CritChance = m_min(output.CritChance, 95)
				if (baseCrit + base) > 0 then
					output.CritChance = m_max(output.CritChance, 5)
				end
				output.PreEffectiveCritChance = output.CritChance
				local preLuckyCritChance = output.CritChance
				if env.mode_effective and modDB:Sum("FLAG", cfg, "CritChanceLucky") then
					output.CritChance = (1 - (1 - output.CritChance / 100) ^ 2) * 100
				end
				local preHitCheckCritChance = output.CritChance
				if env.mode_effective then
					output.CritChance = output.CritChance * output.HitChance / 100
				end
				if breakdown and output.CritChance ~= baseCrit then
					local enemyExtra = enemyDB:Sum("BASE", nil, "SelfExtraCritChance")
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
					if env.mode_effective and enemyExtra ~= 0 then
						t_insert(breakdown.CritChance, s_format("+ %g ^8(extra chance for enemy to be crit)", enemyExtra))
					end
					t_insert(breakdown.CritChance, s_format("= %g", preLuckyCritChance))
					if preCapCritChance > 95 then
						local overCap = preCapCritChance - 95
						t_insert(breakdown.CritChance, s_format("Crit is overcapped by %.2f%% (%d%% increased Critical Strike Chance)", overCap, overCap / more / (baseCrit + base) * 100))
					end
					if env.mode_effective and modDB:Sum("FLAG", cfg, "CritChanceLucky") then
						t_insert(breakdown.CritChance, "Crit Chance is Lucky:")
						t_insert(breakdown.CritChance, s_format("1 - (1 - %.4f) x (1 - %.4f)", preLuckyCritChance / 100, preLuckyCritChance / 100))
						t_insert(breakdown.CritChance, s_format("= %.2f", preHitCheckCritChance))
					end
					if env.mode_effective and output.HitChance < 100 then
						t_insert(breakdown.CritChance, "Crit confirmation roll:")
						t_insert(breakdown.CritChance, s_format("%.2f", preHitCheckCritChance))
						t_insert(breakdown.CritChance, s_format("x %.2f ^8(chance to hit)", output.HitChance / 100))
						t_insert(breakdown.CritChance, s_format("= %.2f", output.CritChance))
					end
				end
			end
			if modDB:Sum("FLAG", cfg, "NoCritMultiplier") then
				output.CritMultiplier = 1
			else
				local extraDamage = modDB:Sum("BASE", cfg, "CritMultiplier") / 100
				if env.mode_effective then
					local enemyInc = 1 + enemyDB:Sum("INC", nil, "SelfCritMultiplier") / 100
					extraDamage = round(extraDamage * enemyInc, 2)
					if breakdown and enemyInc ~= 1 then
						breakdown.CritMultiplier = {
							s_format("%d%% ^8(additional extra damage)", modDB:Sum("BASE", cfg, "CritMultiplier") / 100),
							s_format("x %.2f ^8(increased/reduced extra crit damage taken by enemy)", enemyInc),
							s_format("= %d%% ^8(extra crit damage)", extraDamage * 100),
						}
					end
				end
				output.CritMultiplier = 1 + m_max(0, extraDamage)
			end
			output.CritEffect = 1 - output.CritChance / 100 + output.CritChance / 100 * output.CritMultiplier
			if breakdown and output.CritEffect ~= 1 then
				breakdown.CritEffect = {
					s_format("(1 - %.4f) ^8(portion of damage from non-crits)", output.CritChance/100),
					s_format("+ (%.4f x %g) ^8(portion of damage from crits)", output.CritChance/100, output.CritMultiplier),
					s_format("= %.3f", output.CritEffect),
				}
			end
		end

		-- Calculate hit damage for each damage type
		local totalHitMin, totalHitMax = 0, 0
		local totalCritMin, totalCritMax = 0, 0
		output.LifeLeech = 0
		output.LifeLeechInstant = 0
		output.ManaLeech = 0
		output.ManaLeechInstant = 0
		for pass = 1, 2 do
			-- Pass 1 is critical strike damage, pass 2 is non-critical strike
			cfg.skillCond["CriticalStrike"] = (pass == 1)
			local lifeLeechTotal = 0
			local manaLeechTotal = 0
			for _, damageType in ipairs(dmgTypeList) do
				local min, max
				if skillFlags.hit and canDeal[damageType] then
					if breakdown then
						breakdown[damageType] = {
							damageComponents = { }
						}
					end
					min, max = calcHitDamage(actor, source, cfg, breakdown and breakdown[damageType], damageType)
					local convMult = actor.conversionTable[damageType].mult
					if breakdown then
						t_insert(breakdown[damageType], "Hit damage:")
						t_insert(breakdown[damageType], s_format("%d to %d ^8(total damage)", min, max))
						if convMult ~= 1 then
							t_insert(breakdown[damageType], s_format("x %g ^8(%g%% converted to other damage types)", convMult, (1-convMult)*100))
						end
					end
					min = min * convMult
					max = max * convMult
					if pass == 1 then
						-- Apply crit multiplier
						min = min * output.CritMultiplier
						max = max * output.CritMultiplier
					end
					if (min ~= 0 or max ~= 0) and env.mode_effective then
						-- Apply enemy resistances and damage taken modifiers
						local preMult
						local resist = 0
						local pen = 0
						local taken = enemyDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken")
						if damageType == "Physical" then
							resist = enemyDB:Sum("INC", nil, "PhysicalDamageReduction")
						else
							resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
							if isElemental[damageType] then
								resist = resist + enemyDB:Sum("BASE", nil, "ElementalResist")
								pen = modDB:Sum("BASE", cfg, damageType.."Penetration", "ElementalPenetration")
								taken = taken + enemyDB:Sum("INC", nil, "ElementalDamageTaken")
							end
							resist = m_min(resist, 75)
						end
						if skillFlags.projectile then
							taken = taken + enemyDB:Sum("INC", nil, "ProjectileDamageTaken")
						end
						local effMult = (1 + taken / 100)
						if not isElemental[damageType] or not modDB:Sum("FLAG", cfg, "IgnoreElementalResistances") then
							effMult = effMult * (1 - (resist - pen) / 100)
						end
						min = min * effMult
						max = max * effMult
						if env.mode == "CALCS" then
							output[damageType.."EffMult"] = effMult
						end
						if breakdown and effMult ~= 1 then
							t_insert(breakdown[damageType], s_format("x %.3f ^8(effective DPS modifier)", effMult))
							breakdown[damageType.."EffMult"] = breakdown.effMult(damageType, resist, pen, taken, effMult)
						end
					end
					if breakdown then
						t_insert(breakdown[damageType], s_format("= %d to %d", min, max))
					end
					if skillFlags.mine or skillFlags.trap or skillFlags.totem then
						if not modDB:Sum("FLAG", cfg, "CannotLeechLife") then
							local lifeLeech = modDB:Sum("BASE", cfg, "DamageLifeLeechToPlayer")
							if lifeLeech > 0 then
								lifeLeechTotal = lifeLeechTotal + (min + max) / 2 * lifeLeech / 100
							end
						end
					else
						if not modDB:Sum("FLAG", cfg, "CannotLeechLife") then				
							local lifeLeech = modDB:Sum("BASE", cfg, "DamageLifeLeech", damageType.."DamageLifeLeech", isElemental[damageType] and "ElementalDamageLifeLeech" or nil) + enemyDB:Sum("BASE", nil, "SelfDamageLifeLeech") / 100
							if lifeLeech > 0 then
								lifeLeechTotal = lifeLeechTotal + (min + max) / 2 * lifeLeech / 100
							end
						end
						if not modDB:Sum("FLAG", cfg, "CannotLeechMana") then
							local manaLeech = modDB:Sum("BASE", cfg, "DamageManaLeech", damageType.."DamageManaLeech", isElemental[damageType] and "ElementalDamageManaLeech" or nil) + enemyDB:Sum("BASE", nil, "SelfDamageManaLeech") / 100
							if manaLeech > 0 then
								manaLeechTotal = manaLeechTotal + (min + max) / 2 * manaLeech / 100
							end
						end
					end
				else
					min, max = 0, 0
					if breakdown then
						breakdown[damageType] = {
							"You can't deal "..damageType.." damage"
						}
					end
				end
				if pass == 1 then
					output[damageType.."CritAverage"] = (min + max) / 2
					totalCritMin = totalCritMin + min
					totalCritMax = totalCritMax + max
				else
					if env.mode == "CALCS" then
						output[damageType.."Min"] = min
						output[damageType.."Max"] = max
					end
					output[damageType.."HitAverage"] = (min + max) / 2
					totalHitMin = totalHitMin + min
					totalHitMax = totalHitMax + max
				end
			end
			local portion = (pass == 1) and (output.CritChance / 100) or (1 - output.CritChance / 100)
			if modDB:Sum("FLAG", cfg, "InstantLifeLeech") then
				output.LifeLeechInstant = output.LifeLeechInstant + lifeLeechTotal * portion
			else
				output.LifeLeech = output.LifeLeech + lifeLeechTotal * portion
			end
			if modDB:Sum("FLAG", cfg, "InstantManaLeech") then
				output.ManaLeechInstant = output.ManaLeechInstant + manaLeechTotal * portion
			else
				output.ManaLeech = output.ManaLeech + manaLeechTotal * portion
			end
		end
		output.TotalMin = totalHitMin
		output.TotalMax = totalHitMax

		if not env.configInput.EEIgnoreHitDamage and (output.FireHitAverage + output.ColdHitAverage + output.LightningHitAverage > 0) then
			-- Update enemy hit-by-damage-type conditions
			enemyDB.conditions.HitByFireDamage = output.FireHitAverage > 0
			enemyDB.conditions.HitByColdDamage = output.ColdHitAverage > 0
			enemyDB.conditions.HitByLightningDamage = output.LightningHitAverage > 0
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
		output.LifeLeechDuration, output.LifeLeechInstances = getLeechInstances(output.LifeLeech, modDB:Sum("FLAG", nil, "GhostReaver") and globalOutput.EnergyShield or globalOutput.Life)
		output.LifeLeechInstantRate = output.LifeLeechInstant * hitRate
		output.ManaLeechDuration, output.ManaLeechInstances = getLeechInstances(output.ManaLeech, globalOutput.Mana)
		output.ManaLeechInstantRate = output.ManaLeechInstant * hitRate

		-- Calculate gain on hit
		if skillFlags.mine or skillFlags.trap or skillFlags.totem then
			output.LifeOnHit = 0
			output.EnergyShieldOnHit = 0
			output.ManaOnHit = 0
		else
			output.LifeOnHit = modDB:Sum("BASE", skillCfg, "LifeOnHit") + enemyDB:Sum("BASE", skillCfg, "SelfLifeOnHit")
			output.EnergyShieldOnHit = modDB:Sum("BASE", skillCfg, "EnergyShieldOnHit") + enemyDB:Sum("BASE", skillCfg, "SelfEnergyShieldOnHit")
			output.ManaOnHit = modDB:Sum("BASE", skillCfg, "ManaOnHit") + enemyDB:Sum("BASE", skillCfg, "SelfManaOnHit")
		end
		output.LifeOnHitRate = output.LifeOnHit * hitRate
		output.EnergyShieldOnHitRate = output.EnergyShieldOnHit * hitRate
		output.ManaOnHitRate = output.ManaOnHit * hitRate

		-- Calculate average damage and final DPS
		output.AverageHit = (totalHitMin + totalHitMax) / 2 * (1 - output.CritChance / 100) + (totalCritMin + totalCritMax) / 2 * output.CritChance / 100
		output.AverageDamage = output.AverageHit * output.HitChance / 100
		output.TotalDPS = output.AverageDamage * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)
		if breakdown then
			if output.CritEffect ~= 1 then
				breakdown.AverageHit = {
					s_format("%.1f x (1 - %.4f) ^8(damage from non-crits)", (totalHitMin + totalHitMax) / 2, output.CritChance / 100),
					s_format("+ %.1f x %.4f ^8(damage from crits)", (totalCritMin + totalCritMax) / 2, output.CritChance / 100),
					s_format("= %.1f", output.AverageHit),
				}
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
	if modDB:Sum("FLAG", nil, "GhostReaver") then
		output.LifeLeechRate = 0
		output.LifeLeechPerHit = 0
		output.EnergyShieldLeechInstanceRate = output.EnergyShield * 0.02 * calcLib.mod(modDB, skillCfg, "LifeLeechRate")
		output.EnergyShieldLeechRate = output.LifeLeechInstantRate + m_min(output.LifeLeechInstances * output.EnergyShieldLeechInstanceRate, output.MaxEnergyShieldLeechRate)
		output.EnergyShieldLeechPerHit = m_min(output.EnergyShieldLeechInstanceRate,  output.MaxEnergyShieldLeechRate) * output.LifeLeechDuration + output.LifeLeechInstant
	else
		output.LifeLeechInstanceRate = output.Life * 0.02 * calcLib.mod(modDB, skillCfg, "LifeLeechRate")
		output.LifeLeechRate = output.LifeLeechInstantRate + m_min(output.LifeLeechInstances * output.LifeLeechInstanceRate, output.MaxLifeLeechRate)
		output.LifeLeechPerHit = m_min(output.LifeLeechInstanceRate, output.MaxLifeLeechRate) * output.LifeLeechDuration + output.LifeLeechInstant
		output.EnergyShieldLeechRate = 0
		output.EnergyShieldLeechPerHit = 0
	end
	output.ManaLeechInstanceRate = output.Mana * 0.02 * calcLib.mod(modDB, skillCfg, "ManaLeechRate")
	output.ManaLeechRate = output.ManaLeechInstantRate + m_min(output.ManaLeechInstances * output.ManaLeechInstanceRate, output.MaxManaLeechRate)
	output.ManaLeechPerHit = m_min(output.ManaLeechInstanceRate, output.MaxManaLeechRate) * output.ManaLeechDuration + output.ManaLeechInstant
	skillFlags.leechES = output.EnergyShieldLeechRate > 0
	skillFlags.leechLife = output.LifeLeechRate > 0
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
			breakdown.EnergyShieldLeech = breakdown.leech(output.LifeLeechInstant, output.LifeLeechInstantRate, output.LifeLeechInstances, output.EnergyShield, "LifeLeechRate", output.MaxEnergyShieldLeechRate, output.LifeLeechDuration)
		end
		if skillFlags.leechMana then
			breakdown.ManaLeech = breakdown.leech(output.ManaLeechInstant, output.ManaLeechInstantRate, output.ManaLeechInstances, output.Mana, "ManaLeechRate", output.MaxManaLeechRate, output.ManaLeechDuration)
		end
	end

	-- Calculate skill DOT components
	local dotCfg = {
		skillName = skillCfg.skillName,
		skillPart = skillCfg.skillPart,
		slotName = skillCfg.slotName,
		flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0, skillData.dotIsArea and ModFlag.Area or 0),
		keywordFlags = skillCfg.keywordFlags
	}
	mainSkill.dotCfg = dotCfg
	output.TotalDot = 0
	for _, damageType in ipairs(dmgTypeList) do
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
				local taken = enemyDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken", "DotTaken")
				if damageType == "Physical" then
					resist = enemyDB:Sum("INC", nil, "PhysicalDamageReduction")
				else
					resist = enemyDB:Sum("BASE", nil, damageType.."Resist")
					if isElemental[damageType] then
						resist = resist + enemyDB:Sum("BASE", nil, "ElementalResist")
						taken = taken + enemyDB:Sum("INC", nil, "ElementalDamageTaken")
					end
					if damageType == "Fire" then
						taken = taken + enemyDB:Sum("INC", nil, "BurningDamageTaken")
					end
					resist = m_min(resist, 75)
				end
				effMult = (1 - resist / 100) * (1 + taken / 100)
				output[damageType.."DotEffMult"] = effMult
				if breakdown and effMult ~= 1 then
					breakdown[damageType.."DotEffMult"] = breakdown.effMult(damageType, resist, 0, taken, effMult)
				end
			end
			local inc = modDB:Sum("INC", dotCfg, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil)
			local more = round(modDB:Sum("MORE", dotCfg, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil), 2)
			local total = baseVal * (1 + inc/100) * more * effMult
			output[damageType.."Dot"] = total
			output.TotalDot = output.TotalDot + total
			if breakdown then
				breakdown[damageType.."Dot"] = { }
				breakdown.dot(breakdown[damageType.."Dot"], baseVal, inc, more, nil, effMult, total)
			end
		end
	end

	skillFlags.bleed = false
	skillFlags.poison = false
	skillFlags.ignite = false
	skillFlags.igniteCanStack = modDB:Sum("FLAG", skillCfg, "IgniteCanStack")
	skillFlags.shock = false
	skillFlags.freeze = false
	for _, pass in ipairs(passList) do
		local globalOutput, globalBreakdown = output, breakdown
		local source, output, cfg, breakdown = pass.source, pass.output, pass.cfg, pass.breakdown

		-- Calculate chance to inflict secondary dots/status effects
		cfg.skillCond["CriticalStrike"] = true
		if modDB:Sum("FLAG", cfg, "CannotBleed") then
			output.BleedChanceOnCrit = 0
		else
			output.BleedChanceOnCrit = m_min(100, modDB:Sum("BASE", cfg, "BleedChance"))
		end
		output.PoisonChanceOnCrit = m_min(100, modDB:Sum("BASE", cfg, "PoisonChance"))
		if modDB:Sum("FLAG", cfg, "CannotIgnite") then
			output.IgniteChanceOnCrit = 0
		else
			output.IgniteChanceOnCrit = 100
		end
		if modDB:Sum("FLAG", cfg, "CannotShock") then
			output.ShockChanceOnCrit = 0
		else
			output.ShockChanceOnCrit = 100
		end
		if modDB:Sum("FLAG", cfg, "CannotFreeze") then
			output.FreezeChanceOnCrit = 0
		else
			output.FreezeChanceOnCrit = 100
		end
		cfg.skillCond["CriticalStrike"] = false
		if modDB:Sum("FLAG", cfg, "CannotBleed") then
			output.BleedChanceOnHit = 0
		else
			output.BleedChanceOnHit = m_min(100, modDB:Sum("BASE", cfg, "BleedChance"))
		end
		output.PoisonChanceOnHit = m_min(100, modDB:Sum("BASE", cfg, "PoisonChance"))
		if modDB:Sum("FLAG", cfg, "CannotIgnite") then
			output.IgniteChanceOnHit = 0
		else
			output.IgniteChanceOnHit = m_min(100, modDB:Sum("BASE", cfg, "EnemyIgniteChance") + enemyDB:Sum("BASE", nil, "SelfIgniteChance"))
		end
		if modDB:Sum("FLAG", cfg, "CannotShock") then
			output.ShockChanceOnHit = 0
		else
			output.ShockChanceOnHit = m_min(100, modDB:Sum("BASE", cfg, "EnemyShockChance") + enemyDB:Sum("BASE", nil, "SelfShockChance"))
		end
		if modDB:Sum("FLAG", cfg, "CannotFreeze") then
			output.FreezeChanceOnHit = 0
		else
			output.FreezeChanceOnHit = m_min(100, modDB:Sum("BASE", cfg, "EnemyFreezeChance") + enemyDB:Sum("BASE", nil, "SelfFreezeChance"))
			if modDB:Sum("FLAG", cfg, "CritsDontAlwaysFreeze") then
				output.FreezeChanceOnCrit = output.FreezeChanceOnHit
			end
		end
		if skillFlags.attack and skillFlags.projectile and modDB:Sum("FLAG", cfg, "ArrowsThatPierceCauseBleeding") then
			output.BleedChanceOnHit = 100 - (1 - output.BleedChanceOnHit / 100) * (1 - globalOutput.PierceChance / 100) * 100
			output.BleedChanceOnCrit = 100 - (1 - output.BleedChanceOnCrit / 100) * (1 - globalOutput.PierceChance / 100) * 100
		end

		local function calcSecondaryEffectBase(type, sourceHitDmg, sourceCritDmg)
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
					t_insert(breakdownDPS, "Base damage:")
					t_insert(breakdownDPS, s_format("%.1f ^8(source damage)",sourceHitDmg))
				else
					if baseFromHit > 0 then
						t_insert(breakdownDPS, "Base from Non-crits:")
						t_insert(breakdownDPS, s_format("%.1f ^8(source damage from non-crits)", sourceHitDmg))
						t_insert(breakdownDPS, s_format("x %.3f ^8(portion of instances created by non-crits)", chanceFromHit / (chanceFromHit + chanceFromCrit)))
						t_insert(breakdownDPS, s_format("= %.1f", baseFromHit))
					end
					if baseFromCrit > 0 then
						t_insert(breakdownDPS, "Base from Crits:")
						t_insert(breakdownDPS, s_format("%.1f ^8(source damage from crits)", sourceCritDmg))
						t_insert(breakdownDPS, s_format("x %.3f ^8(portion of instances created by crits)", chanceFromCrit / (chanceFromHit + chanceFromCrit)))
						t_insert(breakdownDPS, s_format("= %.1f", baseFromCrit))
					end
					if baseFromHit > 0 and baseFromCrit > 0 then
						t_insert(breakdownDPS, "Total base damage:")
						t_insert(breakdownDPS, s_format("%.1f + %.1f", baseFromHit, baseFromCrit))
						t_insert(breakdownDPS, s_format("= %.1f", baseVal))
					end
				end
			end
			return baseVal
		end

		-- Calculate bleeding chance and damage
		if canDeal.Physical and (output.BleedChanceOnHit + output.BleedChanceOnCrit) > 0 then
			local sourceHitDmg = output.PhysicalHitAverage
			local sourceCritDmg = output.PhysicalCritAverage
			local basePercent = skillData.bleedBasePercent or 10
			local baseVal = calcSecondaryEffectBase("Bleed", sourceHitDmg, sourceCritDmg) * basePercent / 100
			if baseVal > 0 then
				skillFlags.bleed = true
				skillFlags.duration = true
				if not mainSkill.bleedCfg then
					mainSkill.bleedCfg = {
						skillName = skillCfg.skillName,
						slotName = skillCfg.slotName,
						flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
						keywordFlags = bor(skillCfg.keywordFlags, KeywordFlag.Bleed)
					}
				end
				local dotCfg = mainSkill.bleedCfg
				local effMult = 1
				if env.mode_effective then
					local resist = enemyDB:Sum("INC", nil, "PhysicalDamageReduction")
					local taken = enemyDB:Sum("INC", dotCfg, "DamageTaken", "PhysicalDamageTaken", "DotTaken")
					effMult = (1 - resist / 100) * (1 + taken / 100)
					globalOutput["BleedEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.BleedEffMult = breakdown.effMult("Physical", resist, 0, taken, effMult)
					end
				end
				local inc = modDB:Sum("INC", dotCfg, "Damage", "PhysicalDamage")
				local more = round(modDB:Sum("MORE", dotCfg, "Damage", "PhysicalDamage"), 2)
				output.BleedDPS = baseVal * (1 + inc/100) * more * effMult
				local durationMod = calcLib.mod(modDB, dotCfg, "Duration") * calcLib.mod(enemyDB, nil, "SelfBleedDuration")
				globalOutput.BleedDuration = 5 * durationMod * debuffDurationMult
				if breakdown then
					t_insert(breakdown.BleedDPS, s_format("x %.2f ^8(bleed deals %d%% per second)", basePercent/100, basePercent))
					t_insert(breakdown.BleedDPS, s_format("= %.1f", baseVal))
					t_insert(breakdown.BleedDPS, "Bleed DPS:")
					breakdown.dot(breakdown.BleedDPS, baseVal, inc, more, nil, effMult, output.BleedDPS)
					if globalOutput.BleedDuration ~= 5 then
						globalBreakdown.BleedDuration = {
							"5.00s ^8(base duration)"
						}
						if durationMod ~= 1 then
							t_insert(globalBreakdown.BleedDuration, s_format("x %.2f ^8(duration modifier)", durationMod))
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
		if canDeal.Chaos and (output.PoisonChanceOnHit + output.PoisonChanceOnCrit) > 0 then
			local sourceHitDmg = output.PhysicalHitAverage + output.ChaosHitAverage
			local sourceCritDmg = output.PhysicalCritAverage + output.ChaosCritAverage
			local baseVal = calcSecondaryEffectBase("Poison", sourceHitDmg, sourceCritDmg * modDB:Sum("MORE", cfg, "PoisonDamageOnCrit")) * 0.08
			if baseVal > 0 then
				skillFlags.poison = true
				skillFlags.duration = true
				if not mainSkill.poisonCfg then
					mainSkill.poisonCfg = {
						skillName = skillCfg.skillName,
						slotName = skillCfg.slotName,
						flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
						keywordFlags = bor(skillCfg.keywordFlags, KeywordFlag.Poison)
					}
				end
				local dotCfg = mainSkill.poisonCfg
				local effMult = 1
				if env.mode_effective then
					local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist"), 75)
					local taken = enemyDB:Sum("INC", nil, "DamageTaken", "ChaosDamageTaken", "DotTaken")
					effMult = (1 - resist / 100) * (1 + taken / 100)
					globalOutput["PoisonEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.PoisonEffMult = breakdown.effMult("Chaos", resist, 0, taken, effMult)
					end
				end
				local inc = modDB:Sum("INC", dotCfg, "Damage", "ChaosDamage")
				local more = round(modDB:Sum("MORE", dotCfg, "Damage", "ChaosDamage"), 2)
				output.PoisonDPS = baseVal * (1 + inc/100) * more * effMult
				local durationBase
				if skillData.poisonDurationIsSkillDuration then
					durationBase = skillData.duration
				else
					durationBase = 2
				end
				local durationMod = calcLib.mod(modDB, dotCfg, "Duration") * calcLib.mod(enemyDB, nil, "SelfPoisonDuration")
				globalOutput.PoisonDuration = durationBase * durationMod * debuffDurationMult
				output.PoisonDamage = output.PoisonDPS * globalOutput.PoisonDuration
				if skillData.showAverage then
					output.TotalPoisonAverageDamage = output.HitChance / 100 * output.PoisonChance / 100 * output.PoisonDamage
				else
					output.TotalPoisonDPS = output.HitChance / 100 * output.PoisonChance / 100 * output.PoisonDamage * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)
				end
				if breakdown then
					t_insert(breakdown.PoisonDPS, "x 0.08 ^8(poison deals 8% per second)")
					t_insert(breakdown.PoisonDPS, s_format("= %.1f", baseVal, 1))
					t_insert(breakdown.PoisonDPS, "Poison DPS:")
					breakdown.dot(breakdown.PoisonDPS, baseVal, inc, more, nil, effMult, output.PoisonDPS)
					if globalOutput.PoisonDuration ~= 2 then
						globalBreakdown.PoisonDuration = {
							s_format("%.2fs ^8(base duration)", durationBase)
						}
						if durationMod ~= 1 then
							t_insert(globalBreakdown.PoisonDuration, s_format("x %.2f ^8(duration modifier)", durationMod))
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
				end
			end
		end	

		-- Calculate ignite chance and damage
		if canDeal.Fire and (output.IgniteChanceOnHit + output.IgniteChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if canDeal.Fire and not modDB:Sum("FLAG", cfg, "FireCannotIgnite") then
				sourceHitDmg = sourceHitDmg + output.FireHitAverage
				sourceCritDmg = sourceCritDmg + output.FireCritAverage
			end
			if canDeal.Cold and modDB:Sum("FLAG", cfg, "ColdCanIgnite") then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
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
			local baseVal = calcSecondaryEffectBase("Ignite", sourceHitDmg, sourceCritDmg) * 0.2
			if baseVal > 0 then
				skillFlags.ignite = true
				if not mainSkill.igniteCfg then
					mainSkill.igniteCfg = {
						skillName = skillCfg.skillName,
						slotName = skillCfg.slotName,
						flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
						keywordFlags = skillCfg.keywordFlags,
					}
				end
				local dotCfg = mainSkill.igniteCfg
				local effMult = 1
				if env.mode_effective then
					local resist = m_min(enemyDB:Sum("BASE", nil, "FireResist", "ElementalResist"), 75)
					local taken = enemyDB:Sum("INC", dotCfg, "DamageTaken", "FireDamageTaken", "ElementalDamageTaken", "BurningDamageTaken", "DotTaken")
					effMult = (1 - resist / 100) * (1 + taken / 100)
					globalOutput["IgniteEffMult"] = effMult
					if breakdown and effMult ~= 1 then
						globalBreakdown.IgniteEffMult = breakdown.effMult("Fire", resist, 0, taken, effMult)
					end
				end
				local inc = modDB:Sum("INC", dotCfg, "Damage", "FireDamage", "ElementalDamage")
				local more = round(modDB:Sum("MORE", dotCfg, "Damage", "FireDamage", "ElementalDamage"), 2)
				local burnRateMod = calcLib.mod(modDB, cfg, "IgniteBurnRate")
				output.IgniteDPS = baseVal * (1 + inc/100) * more * burnRateMod * effMult
				local incDur = modDB:Sum("INC", dotCfg, "EnemyIgniteDuration") + enemyDB:Sum("INC", nil, "SelfIgniteDuration")
				local moreDur = enemyDB:Sum("MORE", nil, "SelfIgniteDuration")
				globalOutput.IgniteDuration = 4 * (1 + incDur / 100) * moreDur / burnRateMod * debuffDurationMult
				if skillFlags.igniteCanStack then
					output.IgniteDamage = output.IgniteDPS * globalOutput.IgniteDuration
					if skillData.showAverage then
						output.TotalIgniteAverageDamage = output.HitChance / 100 * output.IgniteChance / 100 * output.IgniteDamage
					else
						output.TotalIgniteDPS = output.HitChance / 100 * output.IgniteChance / 100 * output.IgniteDamage * (globalOutput.HitSpeed or globalOutput.Speed) * (skillData.dpsMultiplier or 1)
					end
				end
				if breakdown then
					t_insert(breakdown.IgniteDPS, "x 0.2 ^8(ignite deals 20% per second)")
					t_insert(breakdown.IgniteDPS, s_format("= %.1f", baseVal, 1))
					t_insert(breakdown.IgniteDPS, "Ignite DPS:")
					breakdown.dot(breakdown.IgniteDPS, baseVal, inc, more, burnRateMod, effMult, output.IgniteDPS)
					if skillFlags.igniteCanStack then
						breakdown.IgniteDamage = { }
						if isAttack then
							t_insert(breakdown.IgniteDamage, pass.label..":")
						end
						t_insert(breakdown.IgniteDamage, s_format("%.1f ^8(damage per second)", output.IgniteDPS))
						t_insert(breakdown.IgniteDamage, s_format("x %.2fs ^8(ignite duration)", globalOutput.IgniteDuration))
						t_insert(breakdown.IgniteDamage, s_format("= %.1f ^8damage per ignite stack", output.IgniteDamage))
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
						if burnRateMod ~= 1 then
							t_insert(globalBreakdown.IgniteDuration, s_format("/ %.2f ^8(rate modifier)", burnRateMod))
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
			if canDeal.Lightning and not modDB:Sum("FLAG", cfg, "LightningCannotShock") then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			if canDeal.Physical and modDB:Sum("FLAG", cfg, "PhysicalCanShock") then
				sourceHitDmg = sourceHitDmg + output.PhysicalHitAverage
				sourceCritDmg = sourceCritDmg + output.PhysicalCritAverage
			end
			if canDeal.Fire and modDB:Sum("FLAG", cfg, "FireCanShock") then
				sourceHitDmg = sourceHitDmg + output.FireHitAverage
				sourceCritDmg = sourceCritDmg + output.FireCritAverage
			end
			if canDeal.Chaos and modDB:Sum("FLAG", cfg, "ChaosCanShock") then
				sourceHitDmg = sourceHitDmg + output.ChaosHitAverage
				sourceCritDmg = sourceCritDmg + output.ChaosCritAverage
			end
			local baseVal = calcSecondaryEffectBase("Shock", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.shock = true
				output.ShockDurationMod = 1 + modDB:Sum("INC", cfg, "EnemyShockDuration") / 100 + enemyDB:Sum("INC", nil, "SelfShockDuration") / 100
				if breakdown then
					t_insert(breakdown.ShockDPS, s_format("For shock to apply, target must have no more than %d life.", baseVal * 20 * output.ShockDurationMod))
				end
 			end
		end
		if (output.FreezeChanceOnHit + output.FreezeChanceOnCrit) > 0 then
			local sourceHitDmg = 0
			local sourceCritDmg = 0
			if canDeal.Cold and not modDB:Sum("FLAG", cfg, "ColdCannotFreeze") then
				sourceHitDmg = sourceHitDmg + output.ColdHitAverage
				sourceCritDmg = sourceCritDmg + output.ColdCritAverage
			end
			if canDeal.Lightning and modDB:Sum("FLAG", cfg, "LightningCanFreeze") then
				sourceHitDmg = sourceHitDmg + output.LightningHitAverage
				sourceCritDmg = sourceCritDmg + output.LightningCritAverage
			end
			local baseVal = calcSecondaryEffectBase("Freeze", sourceHitDmg, sourceCritDmg)
			if baseVal > 0 then
				skillFlags.freeze = true
				output.FreezeDurationMod = 1 + modDB:Sum("INC", cfg, "EnemyFreezeDuration") / 100 + enemyDB:Sum("INC", nil, "SelfFreezeDuration") / 100
				if breakdown then
					t_insert(breakdown.FreezeDPS, s_format("For freeze to apply, target must have no more than %d life.", baseVal * 20 * output.FreezeDurationMod))
				end
			end
		end

		-- Calculate enemy stun modifiers
		local enemyStunThresholdRed = -modDB:Sum("INC", cfg, "EnemyStunThreshold")
		if enemyStunThresholdRed > 75 then
			output.EnemyStunThresholdMod = 1 - (75 + (enemyStunThresholdRed - 75) * 25 / (enemyStunThresholdRed - 50)) / 100
		else
			output.EnemyStunThresholdMod = 1 - enemyStunThresholdRed / 100
		end
		local incDur = modDB:Sum("INC", cfg, "EnemyStunDuration")
		local incRecov = enemyDB:Sum("INC", nil, "StunRecovery")
		output.EnemyStunDuration = 0.35 * (1 + incDur / 100) / (1 + incRecov / 100)
		if breakdown then
			if output.EnemyStunDuration ~= 0.35 then
				breakdown.EnemyStunDuration = {
					"0.35s ^8(base duration)"
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
			combineStat("TotalPoisonDPS", "DPS")
		end
		combineStat("IgniteChance", "AVERAGE")
		combineStat("IgniteDPS", "CHANCE", "IgniteChance")
		if skillFlags.igniteCanStack then
			combineStat("IgniteDamage", "CHANCE", "IgniteChance")
			if skillData.showAverage then
				combineStat("TotalIgniteAverageDamage", "DPS")
			else
				combineStat("TotalIgniteDPS", "DPS")
			end
		end
		combineStat("ShockChance", "AVERAGE")
		combineStat("ShockDurationMod", "AVERAGE")
		combineStat("FreezeChance", "AVERAGE")
		combineStat("FreezeDurationMod", "AVERAGE")
	end

	if skillFlags.hit and skillData.decay then
		-- Calculate DPS for Essence of Delirium's Decay effect
		skillFlags.decay = true
		mainSkill.decayCfg = {
			slotName = skillCfg.slotName,
			flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
			keywordFlags = skillCfg.keywordFlags,
		}
		local dotCfg = mainSkill.decayCfg
		local effMult = 1
		if env.mode_effective then
			local resist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist"), 75)
			local taken = enemyDB:Sum("INC", nil, "DamageTaken", "ChaosDamageTaken", "DotTaken")
			effMult = (1 - resist / 100) * (1 + taken / 100)
			output["DecayEffMult"] = effMult
			if breakdown and effMult ~= 1 then
				breakdown.DecayEffMult = breakdown.effMult("Chaos", resist, 0, taken, effMult)
			end
		end
		local inc = modDB:Sum("INC", dotCfg, "Damage", "ChaosDamage")
		local more = round(modDB:Sum("MORE", dotCfg, "Damage", "ChaosDamage"), 2)
		output.DecayDPS = skillData.decay * (1 + inc/100) * more * effMult
		local durationMod = calcLib.mod(modDB, dotCfg, "Duration")
		output.DecayDuration = 10 * durationMod * debuffDurationMult
		if breakdown then
			breakdown.DecayDPS = { }
			t_insert(breakdown.DecayDPS, "Decay DPS:")
			breakdown.dot(breakdown.DecayDPS, skillData.decay, inc, more, nil, effMult, output.DecayDPS)
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
	if skillFlags.poison then
		if skillData.showAverage then
			output.CombinedDPS = output.CombinedDPS + output.TotalPoisonAverageDamage
			output.WithPoisonAverageDamage = baseDPS + output.TotalPoisonAverageDamage
		else
			output.CombinedDPS = output.CombinedDPS + output.TotalPoisonDPS
			output.WithPoisonDPS = baseDPS + output.TotalPoisonDPS
		end
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
end