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
	local mirageSkill = nil

	if config.compareFunc then
		for _, skill in ipairs(env.player.activeSkillList) do
			if not skill.skillCfg.skillCond["usedByMirage"] then
				mirageSkill = config.compareFunc(skill, env, config, mirageSkill)
			end
		end
	end

	if mirageSkill then
		local newSkill, newEnv = calcs.copyActiveSkill(env, env.mode == "CALCS" and "CALCS" or "MAIN", mirageSkill)
		newSkill.skillCfg.skillCond["usedByMirage"] = true
		newSkill.skillData.limitedProcessing = true
		newSkill.skillTypes[SkillType.OtherThingUsesSkill] = true
		env.player.mainSkill.mirage = { }
		env.player.mainSkill.mirage.name = newSkill.activeEffect.grantedEffect.name
		_ = config.preCalcFunc and config.preCalcFunc(env, newSkill, newEnv)

		newEnv.player.mainSkill = newSkill
		calcs.perform(newEnv)

		_ = config.postCalcFunc and config.postCalcFunc(env, newSkill, newEnv)
	else
		_ = config.mirageSkillNotFoundFunc and config.mirageSkillNotFoundFunc(env, config)
	end
end

function calcs.mirages(env)
	local config
	local calcMode = env.mode == "CALCS" and "CALCS" or "MAIN"

	if env.player.mainSkill.skillData.triggeredByMirageArcher then
		config = {
			compareFunc = function(skill, env, config, mirageSkill)
				if not env.player.mainSkill.skillCfg.skillCond["usedByMirage"] then
					return env.player.mainSkill
				end
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				local moreDamage =  newSkill.skillModList:Sum("BASE", newSkill.skillCfg, "MirageArcherLessDamage")
				local moreAttackSpeed = newSkill.skillModList:Sum("BASE", newSkill.skillCfg, "MirageArcherLessAttackSpeed")
				local mirageCount = newSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "MirageArcherMaxCount")
				env.player.mainSkill.mirage.count = mirageCount
				if not env.player.mainSkill.infoMessage then
					env.player.mainSkill.infoMessage = tostring(mirageCount) .. " Mirage Archers using " .. newSkill.activeEffect.grantedEffect.name
				end

				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "Mirage Archer", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
				newSkill.skillModList:NewMod("Speed", "MORE", moreAttackSpeed, "Mirage Archer", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)

				if newSkill.skillPartName then
					env.player.mainSkill.mirage.skillPart = newSkill.skillPart
					env.player.mainSkill.mirage.skillPartName = newSkill.skillPartName
					env.player.mainSkill.mirage.infoMessage2 = newSkill.activeEffect.grantedEffect.name
				else
					env.player.mainSkill.mirage.skillPartName = nil
				end
			end,
			postCalcFunc = function(env, newSkill, newEnv)
				-- Re-link over the output
				env.player.mainSkill.mirage.output = newEnv.player.output

				if newSkill.minion then
					env.player.mainSkill.mirage.minion = {}
					env.player.mainSkill.mirage.minion.output = newEnv.minion.output
				end

				-- Make any necessary corrections to output
				env.player.mainSkill.mirage.output.ManaCost = 0

				if newEnv.player.breakdown then
					env.player.mainSkill.mirage.breakdown = newEnv.player.breakdown
					-- Make any necessary corrections to breakdown
					env.player.mainSkill.mirage.breakdown.ManaCost = nil
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
	elseif env.player.mainSkill.activeEffect.grantedEffect.name == "Reflection" then
		local usedSkillBestDps
		local moreDamage = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SaviourMirageWarriorLessDamage")
		local maxMirageWarriors = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SaviourMirageWarriorMaxCount")
		config = {
			compareFunc = function(skill, env, config, mirageSkill)
				if skill ~= env.player.mainSkill and skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Totem] and not skill.skillTypes[SkillType.SummonsTotem] and band(skill.skillCfg.flags, bor(ModFlag.Sword, ModFlag.Weapon1H)) == bor(ModFlag.Sword, ModFlag.Weapon1H) and not skill.skillCfg.skillCond["usedByMirage"] then
					local uuid = cacheSkillUUID(skill, env)
					if not GlobalCache.cachedData[calcMode][uuid] then
						calcs.buildActiveSkill(env, calcMode, skill)
					end

					if GlobalCache.cachedData[calcMode][uuid] and GlobalCache.cachedData[calcMode][uuid].CritChance and GlobalCache.cachedData[calcMode][uuid].CritChance > 0 then
						if not mirageSkill then
							usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
							return GlobalCache.cachedData[calcMode][uuid].ActiveSkill
						elseif GlobalCache.cachedData[calcMode][uuid].TotalDPS > usedSkillBestDps then
							usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
							return GlobalCache.cachedData[calcMode][uuid].ActiveSkill
						end
					end
				end
				return mirageSkill
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "The Saviour", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
				if env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 1"].name == env.player.itemList["Weapon 2"].name then
					maxMirageWarriors = maxMirageWarriors / 2
				end
				newSkill.skillModList:NewMod("QuantityMultiplier", "BASE", maxMirageWarriors, "The Saviour Mirage Warriors", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
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
			end,
			mirageSkillNotFoundFunc = function(env, config)
				env.player.mainSkill.infoMessage2 = "No Saviour active skill found"
				env.player.mainSkill.skillFlags.disable = true
			end
		}
	elseif env.player.mainSkill.activeEffect.grantedEffect.name == "Tawhoa's Chosen" then
		local usedSkillBestDps

		local triggerCD = env.player.mainSkill.skillData.cooldown
		local triggeredCD
		local triggerDuration = calcSkillDuration(env.player.mainSkill.skillModList, env.player.mainSkill.skillCfg, env.player.mainSkill.skillData, env, env.player.enemy.modDB)
		local icdrSkill
		local effectiveTriggerCD
		local modActionCooldown
		local rateCapAdjusted
		local triggerRateCap = m_huge
		local SkillTriggerRate
		local EffectiveSourceRate
		local moreDamage = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ChieftainMirageChieftainMoreDamage")
		config = {
			compareFunc = function(skill, env, config, mirageSkill)
				local isDisabled = skill.skillFlags and skill.skillFlags.disable
				if skill ~= env.player.mainSkill and (skill.skillTypes[SkillType.Slam] or skill.skillTypes[SkillType.Melee]) and skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Vaal] and not isTriggered(skill) and not isDisabled and not skill.skillTypes[SkillType.Totem] and not skill.skillTypes[SkillType.SummonsTotem] and not skill.skillCfg.skillCond["usedByMirage"] then
					local uuid = cacheSkillUUID(skill, env)
					if not GlobalCache.cachedData[calcMode][uuid] then
						calcs.buildActiveSkill(env, calcMode, skill)
					end

					if GlobalCache.cachedData[calcMode][uuid] then
						if not mirageSkill then
							usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
							return  GlobalCache.cachedData[calcMode][uuid].ActiveSkill

						else
							if GlobalCache.cachedData[calcMode][uuid].TotalDPS > usedSkillBestDps then
								usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
								return GlobalCache.cachedData[calcMode][uuid].ActiveSkill
							end
						end
					end
				end
				return mirageSkill
			end,
			preCalcFunc = function(env, newSkill, newEnv)
				triggeredCD = newSkill.skillData.cooldown
				icdrSkill = calcLib.mod(newSkill.skillModList, newSkill.skillCfg, "CooldownRecovery")

				effectiveTriggerCD = (triggerCD / icdrSkill) + triggerDuration
				modActionCooldown = m_max( triggeredCD or 0, effectiveTriggerCD or 0 ) / icdrSkill
				rateCapAdjusted = m_ceil(modActionCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
				if modActionCooldown ~= 0 then
					triggerRateCap = 1 / modActionCooldown
				end

				local BreakdownEffectiveSourceRate = {}
				EffectiveSourceRate = GlobalCache.cachedData[calcMode][cacheSkillUUID(newSkill, env)].Speed
				local BreakdownSkillTriggerRate = {}
				local BreakdownSimData
				local simBreakdown

				if EffectiveSourceRate ~= 0 then
					--cacheSkillUUID(env.player.mainSkill, env) main skill is used to get rate of newSkill as mainSkill and not the actual mainSkill in calcMultiSpellRotationImpact
					SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, {{ uuid = cacheSkillUUID(env.player.mainSkill, env), cd = triggeredCD }}, EffectiveSourceRate, effectiveTriggerCD)

					if breakdown then
						BreakdownSkillTriggerRate = {
							s_format("%.2f ^8(effective trigger rate of trigger)", EffectiveSourceRate),
							s_format("/ %.2f ^8(simulated impact of linked spells)", m_max(EffectiveSourceRate / SkillTriggerRate, 1)),
							s_format("= %.2f ^8per second", SkillTriggerRate),
							"",
							s_format("^8(Calculation Resolution: %.2f)", simBreakdown.simRes),
						}

						local skillName = "Tawhoa's Chosen"

						BreakdownSkillTriggerRate[1] = s_format("%.2f ^8(%s triggers per second)", EffectiveSourceRate, skillName)

						if simBreakdown.extraSimInfo then
							t_insert(BreakdownSkillTriggerRate, "")
							t_insert(BreakdownSkillTriggerRate, simBreakdown.extraSimInfo)
						end
					end
				else
					if breakdown then
						BreakdownSkillTriggerRate = {
							s_format("The trigger needs to be triggered for any skill to be triggered."),
						}
					end
					SkillTriggerRate = 0
				end

				-- Override attack speed with trigger rate
				newSkill.skillData.triggerRate = SkillTriggerRate

				-- Add new modifiers to new skill (which already has all the old skill's modifiers)
				newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "Tawhoa's Chosen", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
			end,
			postCalcFunc = function(env, newSkill, newEnv)
				env.player.mainSkill = newSkill
				env.player.mainSkill.infoMessage = "Tawhoa's Chosen using " .. newSkill.activeEffect.grantedEffect.name

				env.player.output = newEnv.player.output
				env.player.output.ManaCost = 0
				env.player.output.Speed = SkillTriggerRate
				env.player.mainSkill.skillData.triggerRate = SkillTriggerRate
				env.player.mainSkill.skillData.triggered = true
				env.player.output.TriggerRateCap = triggerRateCap
				env.player.output.EffectiveSourceRate = EffectiveSourceRate
				env.player.output.SkillTriggerRate = SkillTriggerRate

				if newEnv.player.breakdown then
					newEnv.player.breakdown.SkillTriggerRate = BreakdownSkillTriggerRate
					newEnv.player.breakdown.EffectiveSourceRate = BreakdownEffectiveSourceRate
					if triggeredCD then
						newEnv.player.breakdown.TriggerRateCap = {
							s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD),
							s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
							s_format("= %.2f ^8(final cooldown of triggered skill)", triggeredCD / icdrSkill),
							"",
							s_format("%.2f ^8(Tawhoa's Chosen base cooldown)", triggerCD),
							s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
							s_format("+ %.2f ^8(only one Tawhoa's Chosen can be active at a time thus we add duration)", triggerDuration),
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
							s_format("+ %.2f ^8(only one Tawhoa's Chosen can be active at a time thus we add duration)", triggerDuration),
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
					env.player.breakdown.ManaCost = nil
					env.player.mainSkill.skillData.triggered = true
				end
			end,
			mirageSkillNotFoundFunc = function(env, config)
				env.player.mainSkill.disableReason = "No Tawhoa's Chosen active skill found"
				env.player.mainSkill.skillFlags.disable = true
			end
		}
	end

	if config then
		calculateMirage(env, config)
	end
end