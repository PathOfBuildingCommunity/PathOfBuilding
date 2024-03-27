-- Path of Building
--
-- Module: Calc Mirages
-- Handles mirages that use player skills
--

local calcs = ...
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil
local m_floor = math.floor
local m_modf = math.modf
local s_format = string.format
local m_huge = math.huge
local bor = bit.bor
local band = bit.band

local function calculateMirage(env, config)
	if not config then
		return
	end

	local mirageSkill = nil

	if config.compareFunc then
		for _, skill in ipairs(env.player.activeSkillList) do
			if not skill.skillCfg.skillCond["usedByMirage"] then
				mirageSkill = config.compareFunc(skill, env, config, mirageSkill)
			end
		end
	end

	if mirageSkill then
		local newSkill, newEnv = calcs.copyActiveSkill(env, env.mode, mirageSkill)
		newSkill.skillCfg.skillCond["usedByMirage"] = true
		newSkill.skillData.limitedProcessing = true
		newSkill.skillData.mirageUses = env.player.mainSkill.skillData.storedUses
		newSkill.skillTypes[SkillType.OtherThingUsesSkill] = true

		config.preCalcFunc(env, newSkill, newEnv)

		newEnv.player.mainSkill = newSkill
		calcs.perform(newEnv)
		config.postCalcFunc(env, newSkill, newEnv)
	else
		config.mirageSkillNotFoundFunc(env, config)
	end
	return not config.calcMainSkillOffence
end

function calcs.mirages(env)
	local config

	if env.player.mainSkill.skillCfg.skillCond["usedByMirage"] or env.player.mainSkill.skillFlags.disable then
		return
	end

	if env.player.mainSkill.skillData.triggeredByMirageArcher then
		config = {
			calcMainSkillOffence = true,
			compareFunc = function(skill, env, config, mirageSkill)
				if not env.player.mainSkill.skillCfg.skillCond["usedByMirage"] and env.player.weaponData1.type == "Bow" then
					return env.player.mainSkill
				end
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				local moreDamage =  newSkill.skillModList:Sum("BASE", newSkill.skillCfg, "MirageArcherLessDamage")
				local moreAttackSpeed = newSkill.skillModList:Sum("BASE", newSkill.skillCfg, "MirageArcherLessAttackSpeed")
				local mirageCount = newSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "MirageArcherMaxCount")

				env.player.mainSkill.mirage = { }
				env.player.mainSkill.mirage.name = newSkill.activeEffect.grantedEffect.name
				env.player.mainSkill.mirage.count = mirageCount

				if not env.player.mainSkill.infoMessage then
					env.player.mainSkill.infoMessage = tostring(mirageCount) .. " Mirage Archers using " .. newSkill.activeEffect.grantedEffect.name
				end

				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "Mirage Archer", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
				newSkill.skillModList:NewMod("Speed", "MORE", moreAttackSpeed, "Mirage Archer", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)

				-- Does not use player resources
				newSkill.skillModList:NewMod("HasNoCost", "FLAG", true, "Used by mirage")

				if newSkill.skillPartName then
					env.player.mainSkill.mirage.skillPart = newSkill.skillPart
					env.player.mainSkill.mirage.skillPartName = newSkill.skillPartName
					env.player.mainSkill.mirage.infoMessage2 = newSkill.activeEffect.grantedEffect.name
				else
					env.player.mainSkill.mirage.skillPartName = nil
				end
			end,
			postCalcFunc = function(env, newSkill, newEnv)
				env.player.mainSkill.mirage.output = newEnv.player.output
				if newSkill.minion then
					env.player.mainSkill.mirage.minion = {}
					env.player.mainSkill.mirage.minion.output = newEnv.minion.output
				end

				if newEnv.player.breakdown then
					env.player.mainSkill.mirage.breakdown = newEnv.player.breakdown
					if newSkill.minion then
						env.player.mainSkill.mirage.minion.breakdown = newEnv.minion.breakdown
					end
				end
			end,
			mirageSkillNotFoundFunc = function(env, config)
				if not env.player.mainSkill.infoMessage2 then
					env.player.mainSkill.infoMessage2 = "No Mirage Archer active skill found"
				end
			end
		}
	elseif env.player.mainSkill.skillData.triggeredBySacredWisp then 
		config = {
			calcMainSkillOffence = true,
			compareFunc = function(skill, env, config, mirageSkill)
				if not env.player.mainSkill.skillCfg.skillCond["usedByMirage"] and env.player.weaponData1.type == "Wand" then
					return env.player.mainSkill
				end
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				local moreDamage =  newSkill.skillModList:Sum("BASE", newSkill.skillCfg, "SacredWispsLessDamage")
				local wispProcChance = newSkill.skillModList:Sum("BASE", newSkill.skillCfg, "SacredWispsLessAttackSpeed")
				local wispCount = newSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SacredWispsMaxCount")
				
				env.player.mainSkill.mirage = { }
				env.player.mainSkill.mirage.name = newSkill.activeEffect.grantedEffect.name
				env.player.mainSkill.mirage.count = wispCount

				if not env.player.mainSkill.infoMessage then
					env.player.mainSkill.infoMessage = tostring(wispCount) .. " Sacred Wisps using " .. newSkill.activeEffect.grantedEffect.name
				end

				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "Sacred Wisp", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
				newSkill.skillModList:NewMod("DPS", "MORE", wispProcChance, "Sacred Wisp", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)


				-- Does not use player resources
				newSkill.skillModList:NewMod("HasNoCost", "FLAG", true, "Used by wisps")

				if newSkill.skillPartName then
					env.player.mainSkill.mirage.skillPart = newSkill.skillPart
					env.player.mainSkill.mirage.skillPartName = newSkill.skillPartName
					env.player.mainSkill.mirage.infoMessage2 = newSkill.activeEffect.grantedEffect.name
				else
					env.player.mainSkill.mirage.skillPartName = nil
				end
			end,
			postCalcFunc = function(env, newSkill, newEnv)
				env.player.mainSkill.mirage.output = newEnv.player.output
				if newSkill.minion then
					env.player.mainSkill.mirage.minion = {}
					env.player.mainSkill.mirage.minion.output = newEnv.minion.output
				end

				if newEnv.player.breakdown then
					env.player.mainSkill.mirage.breakdown = newEnv.player.breakdown
					if newSkill.minion then
						env.player.mainSkill.mirage.minion.breakdown = newEnv.minion.breakdown
					end
				end
			end,
			mirageSkillNotFoundFunc = function(env, config)
				if not env.player.mainSkill.infoMessage2 then
					env.player.mainSkill.infoMessage2 = "No sacred wisp active skill found"
				end
			end
		}
	elseif env.player.mainSkill.activeEffect.grantedEffect.name == "Reflection" then
		local usedSkillBestDps
		local maxMirageWarriors = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SaviourMirageWarriorMaxCount")
		config = {
			compareFunc = function(skill, env, config, mirageSkill)
				if skill ~= env.player.mainSkill and skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Totem] and not skill.skillTypes[SkillType.SummonsTotem] and band(skill.skillCfg.flags, bor(ModFlag.Sword, ModFlag.Weapon1H)) == bor(ModFlag.Sword, ModFlag.Weapon1H) and not skill.skillCfg.skillCond["usedByMirage"] then
					local uuid = cacheSkillUUID(skill, env)
					if not GlobalCache.cachedData[env.mode][uuid] then
						calcs.buildActiveSkill(env, env.mode, skill)
					end

					if GlobalCache.cachedData[env.mode][uuid] and GlobalCache.cachedData[env.mode][uuid].CritChance and GlobalCache.cachedData[env.mode][uuid].CritChance > 0 then
						if not mirageSkill then
							usedSkillBestDps = GlobalCache.cachedData[env.mode][uuid].TotalDPS
							return GlobalCache.cachedData[env.mode][uuid].ActiveSkill
						elseif GlobalCache.cachedData[env.mode][uuid].TotalDPS > usedSkillBestDps then
							usedSkillBestDps = GlobalCache.cachedData[env.mode][uuid].TotalDPS
							return GlobalCache.cachedData[env.mode][uuid].ActiveSkill
						end
					end
				end
				return mirageSkill
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				local moreDamage = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SaviourMirageWarriorLessDamage")
				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "The Saviour", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
				if env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 1"].name == env.player.itemList["Weapon 2"].name then
					maxMirageWarriors = maxMirageWarriors / 2
				end
				newSkill.skillModList:NewMod("QuantityMultiplier", "BASE", maxMirageWarriors, "The Saviour Mirage Warriors", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
				-- Does not use player resources
				newSkill.skillModList:NewMod("HasNoCost", "FLAG", true, "Used by mirage")
			end,
			postCalcFunc = function(env, newSkill, newEnv)
				env.player.mainSkill = newSkill
				env.player.mainSkill.infoMessage = tostring(maxMirageWarriors) .. " Mirage Warriors using " .. newSkill.activeEffect.grantedEffect.name

				-- Re-link over the output
				env.player.output = newEnv.player.output
				if newSkill.minion then
					env.minion = newEnv.player.mainSkill.minion
					env.minion.output = newEnv.minion.output
				end

				-- Re-link over the breakdown (if present)
				if newEnv.player.breakdown then
					env.player.breakdown = newEnv.player.breakdown
					if newSkill.minion then
						env.minion.breakdown = newEnv.minion.breakdown
					end
				end
			end,
			mirageSkillNotFoundFunc = function(env, config)
				env.player.mainSkill.disableReason = "No Saviour active skill found"
				env.player.mainSkill.skillFlags.disable = true
			end
		}
	elseif env.player.mainSkill.activeEffect.grantedEffect.name == "Tawhoa's Chosen" then
		local usedSkillBestDps
		local EffectiveSourceRate

		local triggerCD = env.player.mainSkill.skillData.cooldown
		local triggeredCD
		local icdrSkill
		local effectiveTriggerCD
		local modActionCooldown
		local rateCapAdjusted
		local triggerRateCap = m_huge
		local SkillTriggerRate

		config = {
			compareFunc = function(skill, env, config, mirageSkill)
				local isDisabled = skill.skillFlags and skill.skillFlags.disable
				if skill ~= env.player.mainSkill and (skill.skillTypes[SkillType.Slam] or skill.skillTypes[SkillType.Melee]) and skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Vaal] and not isTriggered(skill) and not isDisabled and not skill.skillTypes[SkillType.Totem] and not skill.skillTypes[SkillType.SummonsTotem] and not skill.skillCfg.skillCond["usedByMirage"] then
					local uuid = cacheSkillUUID(skill, env)
					if not GlobalCache.cachedData[env.mode][uuid] or env.mode == "CALCULATOR" then
						calcs.buildActiveSkill(env, env.mode, skill)
					end

					if GlobalCache.cachedData[env.mode][uuid] then
						if not mirageSkill then
							usedSkillBestDps = GlobalCache.cachedData[env.mode][uuid].TotalDPS
							EffectiveSourceRate = GlobalCache.cachedData[env.mode][uuid].Speed
							return  GlobalCache.cachedData[env.mode][uuid].ActiveSkill

						else
							if GlobalCache.cachedData[env.mode][uuid].TotalDPS > usedSkillBestDps then
								usedSkillBestDps = GlobalCache.cachedData[env.mode][uuid].TotalDPS
								EffectiveSourceRate = GlobalCache.cachedData[env.mode][uuid].Speed
								return GlobalCache.cachedData[env.mode][uuid].ActiveSkill
							end
						end
					end
				end
				return mirageSkill
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				triggeredCD = newSkill.skillData.cooldown
				icdrSkill = calcLib.mod(newSkill.skillModList, newSkill.skillCfg, "CooldownRecovery")

				effectiveTriggerCD = triggerCD / icdrSkill
				modActionCooldown = m_max( triggeredCD or 0, effectiveTriggerCD or 0 ) / icdrSkill
				rateCapAdjusted = m_ceil(modActionCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
				if modActionCooldown ~= 0 then
					triggerRateCap = 1 / modActionCooldown
				end

				SkillTriggerRate = EffectiveSourceRate ~= 0 and calcMultiSpellRotationImpact(env, {{ uuid = cacheSkillUUID(env.player.mainSkill, env), cd = triggeredCD }}, EffectiveSourceRate, effectiveTriggerCD) or 0

				-- Override attack speed with trigger rate
				newSkill.skillData.triggerRate = SkillTriggerRate

				-- Does not use player resources
				newSkill.skillModList:NewMod("HasNoCost", "FLAG", true, "Used by mirage")

				local moreDamage = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ChieftainMirageChieftainMoreDamage")
				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "Tawhoa's Chosen", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
			end,
			postCalcFunc = function(env, newSkill, newEnv)
				env.player.mainSkill = newSkill
				env.player.mainSkill.infoMessage = "Tawhoa's Chosen using " .. newSkill.activeEffect.grantedEffect.name

				env.player.output = newEnv.player.output
				env.player.output.Speed = SkillTriggerRate
				env.player.mainSkill.skillData.triggerRate = SkillTriggerRate
				env.player.mainSkill.skillData.triggered = true
				env.player.output.TriggerRateCap = triggerRateCap
				env.player.output.EffectiveSourceRate = EffectiveSourceRate
				env.player.output.SkillTriggerRate = SkillTriggerRate

				if newEnv.player.breakdown then
					if triggeredCD then
						newEnv.player.breakdown.TriggerRateCap = {
							s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD),
							s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
							s_format("= %.2f ^8(final cooldown of triggered skill)", triggeredCD / icdrSkill),
							"",
							s_format("%.2f ^8(Tawhoa's Chosen base cooldown)", triggerCD),
							s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
							s_format("= %.2f ^8(effective trigger cooldown)", effectiveTriggerCD),
							"",
							s_format("%.2f ^8(biggest of trigger cooldown and triggered skill cooldown)", modActionCooldown),
							"",
							s_format("%.2f ^8(adjusted for server tick rate)", rateCapAdjusted),
							"",
							"Trigger rate:",
							s_format("1 / %.3f", rateCapAdjusted),
							s_format("= %.2f ^8per second", triggerRateCap),
						}
					else
						newEnv.player.breakdown.TriggerRateCap = {
							"Triggered skill has no base cooldown",
							"",
							s_format("%.2f ^8(Tawhoa's Chosen base cooldown)", triggerCD),
							s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
							s_format("= %.2f ^8(effective trigger cooldown)", effectiveTriggerCD),
							"",
							s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
							"",
							"Trigger rate:",
							s_format("1 / %.2f", rateCapAdjusted),
							s_format("= %.2f ^8per second", triggerRateCap),
						}
					end

					env.player.breakdown = newEnv.player.breakdown
					env.player.mainSkill.skillData.triggered = true
				end
			end,
			mirageSkillNotFoundFunc = function(env, config)
				env.player.mainSkill.disableReason = "No Tawhoa's Chosen active skill found"
				env.player.mainSkill.skillFlags.disable = true
			end
		}
	elseif env.player.mainSkill.skillData.triggeredByGeneralsCry then
		env.player.mainSkill[SkillType.Triggered] = true
		local maxMirageWarriors = 0
		local cooldown = 1
		local generalsCryActiveSkill

		-- Find the active General's Cry gem to get active properties
		for _, skill in ipairs(env.player.activeSkillList) do
			if skill.activeEffect.grantedEffect.name == "General's Cry" and env.player.mainSkill.socketGroup.slot == env.player.mainSkill.socketGroup.slot then
				cooldown = calcSkillCooldown(skill.skillModList, skill.skillCfg, skill.skillData)
				generalsCryActiveSkill = skill
				break
			end
		end

		-- Scale dps with GC's cooldown
		env.player.mainSkill.skillData.dpsMultiplier = (env.player.mainSkill.skillData.dpsMultiplier or 1) * (1 / cooldown)

		-- Does not use player resources
		env.player.mainSkill.skillModList:NewMod("HasNoCost", "FLAG", true, "Used by mirage")

		-- Non-channelled skills only attack once, disregard attack rate
		if not env.player.mainSkill.skillTypes[SkillType.Channel] then
			env.player.mainSkill.skillData.timeOverride = 1
		end

		-- Supported Attacks Count as Exerted
		for _, value in ipairs(env.modDB:Tabulate("INC", env.player.mainSkill.skillCfg, "ExertIncrease")) do
			local mod = value.mod
			env.player.mainSkill.skillModList:NewMod("Damage", mod.type, mod.value, mod.source, mod.flags, mod.keywordFlags)
		end
		for _, value in ipairs(env.modDB:Tabulate("MORE", env.player.mainSkill.skillCfg, "ExertIncrease")) do
			local mod = value.mod
			env.player.mainSkill. skillModList:NewMod("Damage", mod.type, mod.value, mod.source, mod.flags, mod.keywordFlags)
		end
		for _, value in ipairs(env.modDB:Tabulate("MORE", env.player.mainSkill.skillCfg, "ExertAttackIncrease")) do
			local mod = value.mod
			env.player.mainSkill.skillModList:NewMod("Damage", mod.type, mod.value, mod.source, mod.flags, mod.keywordFlags)
		end
		for _, value in ipairs(env.modDB:Tabulate("BASE", env.player.mainSkill.skillCfg, "ExertDoubleDamageChance")) do
			local mod = value.mod
			env.player.mainSkill.skillModList:NewMod("DoubleDamageChance", mod.type, mod.value, mod.source, mod.flags, mod.keywordFlags)
		end

		-- Scale dps with mirage quantity
		for _, value in ipairs(generalsCryActiveSkill.skillModList:Tabulate("BASE", generalsCryActiveSkill.skillCfg, "GeneralsCryDoubleMaxCount")) do
			local mod = value.mod
			env.player.mainSkill.skillModList:NewMod("QuantityMultiplier", mod.type, mod.value, mod.source, mod.flags, mod.keywordFlags)
			maxMirageWarriors = maxMirageWarriors + mod.value
		end
		env.player.mainSkill.infoMessage = tostring(maxMirageWarriors) .. " GC Mirage Warriors using " .. env.player.mainSkill.activeEffect.grantedEffect.name
	end

	return calculateMirage(env, config)
end