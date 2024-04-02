-- Path of Building
--
-- Module: Calc Triggers
-- Performs trigger rate calculations
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

-- Add trigger-based damage modifiers
local function addTriggerIncMoreMods(activeSkill, sourceSkill)
	for _, value in ipairs(activeSkill.skillModList:Tabulate("INC", sourceSkill.skillCfg, "TriggeredDamage")) do
		activeSkill.skillModList:NewMod("Damage", "INC", value.mod.value, value.mod.source, value.mod.flags, value.mod.keywordFlags, unpack(value.mod))
	end
	for _, value in ipairs(activeSkill.skillModList:Tabulate("MORE", sourceSkill.skillCfg, "TriggeredDamage")) do
		activeSkill.skillModList:NewMod("Damage", "MORE", value.mod.value, value.mod.source, value.mod.flags, value.mod.keywordFlags, unpack(value.mod))
	end
end

local function slotMatch(env, skill)
	local fromItem = (env.player.mainSkill.activeEffect.grantedEffect.fromItem or skill.activeEffect.grantedEffect.fromItem)
	fromItem = fromItem or (env.player.mainSkill.activeEffect.srcInstance and env.player.mainSkill.activeEffect.srcInstance.fromItem) or (skill.activeEffect.srcInstance and skill.activeEffect.srcInstance.fromItem)
	local match1 = fromItem and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot
	local match2 = (not env.player.mainSkill.activeEffect.grantedEffect.fromItem) and skill.socketGroup == env.player.mainSkill.socketGroup
	return (match1 or match2)
end

function isTriggered(skill)
	return skill.skillData.triggeredByUnique or skill.skillData.triggered or skill.skillTypes[SkillType.InbuiltTrigger] or skill.skillTypes[SkillType.Triggered] or skill.activeEffect.grantedEffect.triggered or (skill.activeEffect.srcInstance and skill.activeEffect.srcInstance.triggered)
end

local function processAddedCastTime(skill, breakdown)
	if skill.skillModList:Flag(skill.skillCfg, "SpellCastTimeAddedToCooldownIfTriggered") then
		local baseCastTime = skill.skillData.castTimeOverride or skill.activeEffect.grantedEffect.castTime or 1
		local inc = skill.skillModList:Sum("INC", skill.skillCfg, "Speed")
		local more = skill.skillModList:More(skill.skillCfg, "Speed")
		local csi = round((1 + inc/100) * more, 2)
		local addsCastTime = baseCastTime / csi
		skill.skillFlags.addsCastTime = true
		if breakdown then
			breakdown.AddedCastTime = {
				s_format("%.2f ^8(base cast time of %s)", baseCastTime, skill.activeEffect.grantedEffect.name),
				s_format("%.2f ^8(increased/reduced)", 1 + inc/100),
				s_format("%.2f ^8(more/less)", more),
				s_format("= %.2f ^8cast time", addsCastTime)
			}
		end
		return addsCastTime, csi
	end
end

local function packageSkillDataForSimulation(skill, env)
	return { uuid = cacheSkillUUID(skill, env), cd = skill.skillData.cooldown, cdOverride = skill.skillModList:Override(skill.skillCfg, "CooldownRecovery"), addsCastTime = processAddedCastTime(skill), icdr = calcLib.mod(skill.skillModList, skill.skillCfg, "CooldownRecovery"), addedCooldown = skill.skillModList:Sum("BASE", skill.skillCfg, "CooldownRecovery")}
end

-- Identify the trigger action skill for trigger conditions, take highest Attack Per Second
local function findTriggerSkill(env, skill, source, triggerRate, comparer)
	local comparer = comparer or function(uuid, source, triggerRate)
		local cachedSpeed = GlobalCache.cachedData[env.mode][uuid].HitSpeed or GlobalCache.cachedData[env.mode][uuid].Speed
		return (not source and cachedSpeed) or (cachedSpeed and cachedSpeed > (triggerRate or 0))
	end

	local uuid = cacheSkillUUID(skill, env)
	if not GlobalCache.cachedData[env.mode][uuid] or env.mode == "CALCULATOR" then
		calcs.buildActiveSkill(env, env.mode, skill)
	end

	if GlobalCache.cachedData[env.mode][uuid] and comparer(uuid, source, triggerRate) and (skill.skillFlags and not skill.skillFlags.disable) and (skill.skillCfg and not skill.skillCfg.skillCond["usedByMirage"]) and not skill.skillTypes[SkillType.OtherThingUsesSkill] then
		return skill, GlobalCache.cachedData[env.mode][uuid].HitSpeed or GlobalCache.cachedData[env.mode][uuid].Speed, uuid
	end
	return source, triggerRate, source and cacheSkillUUID(source, env)
end

-- Calculate the impact other skills and source rate to trigger cooldown alignment have on the trigger rate
-- for more details regarding the implementation see comments of #4599 and #5428
function calcMultiSpellRotationImpact(env, skillRotation, sourceRate, triggerCD, actor)
	local SIM_TIME = 100.0
	local TIME_STEP = 0.0001
	local index = 1
	local time = 0
	local tick = 0
	local currTick = 0
	local next_trigger = 0
	local trigger_increment = 1 / sourceRate
	local wasted = 0
	local actor = actor or env.player

	for _, skill in ipairs(skillRotation) do
		skill.cd = m_max(skill.cdOverride or ( ((skill.cd or 0) + (skill.addedCooldown or 0)) / (skill.icdr or 1)), ( (triggerCD or 0) + (skill.addsCastTime or 0) ) / (skill.icdr or 1))
		skill.next_trig = 0
		skill.count = 0
	end

	while time < SIM_TIME do
		local currIndex = index

		if time >= next_trigger then
			while skillRotation[index].next_trig > time do
				index = (index % #skillRotation) + 1
				if index == currIndex then
					wasted = wasted + 1
					-- Triggers are free from the server tick so cooldown starts at current time
					next_trigger = time + trigger_increment
					break
				end
			end

			if skillRotation[index].next_trig <= time then
				skillRotation[index].count = skillRotation[index].count + 1
				-- Cooldown starts at the beginning of current tick
				skillRotation[index].next_trig = currTick + skillRotation[index].cd
				local tempTick = tick

				while skillRotation[index].next_trig > tempTick do
					tempTick = tempTick + (1/data.misc.ServerTickRate)
				end
				-- Cooldown ends at the start of the next tick. Price is right rules.
				skillRotation[index].next_trig = tempTick
				index = (index % #skillRotation) + 1
				next_trigger = time + trigger_increment
			end
		end
		-- Increment time by smallest reasonable amount to attempt to hit every trigger event and every server tick. Frees attacks from the server tick.
		time = time + TIME_STEP
		-- Keep track of the server tick as the trigger cooldown is still bound by it
		if tick < time then
			currTick = tick
			tick = tick + (1/data.misc.ServerTickRate)
		end
	end

	local mainRate = 0
	local trigRateTable = { simTime = SIM_TIME, rates = {}, }
	for _, sd in ipairs(skillRotation) do
		if cacheSkillUUID(actor.mainSkill, env) == sd.uuid then
			mainRate = sd.count / SIM_TIME
		end
		t_insert(trigRateTable.rates, { name = sd.uuid, rate = sd.count / SIM_TIME })
	end

	return mainRate, trigRateTable
end

local function helmetFocusHandler(env)
	if not env.player.mainSkill.skillFlags.minion and not env.player.mainSkill.skillFlags.disable and env.player.mainSkill.triggeredBy then
		local triggerName = "Focus"
		env.player.mainSkill.skillData.triggered = true
		local output = env.player.output
		local breakdown = env.player.breakdown
		local triggerCD = env.player.mainSkill.triggeredBy.grantedEffect.levels[env.player.mainSkill.triggeredBy.level].cooldown
		local triggeredCD = env.player.mainSkill.skillData.cooldown

		local icdrFocus = calcLib.mod(env.player.mainSkill.skillModList, env.player.mainSkill.skillCfg, "FocusCooldownRecovery")
		local icdrSkill = calcLib.mod(env.player.mainSkill.skillModList, env.player.mainSkill.skillCfg, "CooldownRecovery")

		-- Skills trigger only on activation
		-- Next possible activation will be duration + cooldown
		-- cooldown is in milliseconds
		local skillFocus = env.data.skills["Focus"]
		local focusDuration = (skillFocus.constantStats[1][2] / 1000)
		local focusCD = (skillFocus.levels[1].cooldown / icdrFocus)
		local focusTotalCD = focusDuration + focusCD

		-- skill cooldown should still apply to focus triggers
		local modActionCooldown = m_max( triggeredCD or 0, (triggerCD or 0) / icdrSkill )
		local rateCapAdjusted = m_ceil(modActionCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
		local triggerRate = m_huge
		if rateCapAdjusted ~= 0 then
			triggerRate = 1 / rateCapAdjusted
		end

		output.TriggerRateCap = triggerRate
		output.SkillTriggerRate = 1 / focusTotalCD

		if breakdown then
			if triggeredCD then
				breakdown.TriggerRateCap = {
					s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD),
					s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
					s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCD / icdrSkill),
					"",
					s_format("%.2f ^8(base cooldown of trigger)", triggerCD),
					s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
					s_format("= %.4f ^8(final cooldown of trigger)", triggerCD / icdrSkill),
					"",
					s_format("%.3f ^8(biggest of trigger cooldown and triggered skill cooldown)", modActionCooldown),
					"",
					(env.player.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
					"",
					"Trigger rate:",
					s_format("1 / %.3f", rateCapAdjusted),
					s_format("= %.2f ^8per second", triggerRate),
				}
			else
				breakdown.TriggerRateCap = {
					"Triggered skill has no base cooldown",
					"",
					s_format("%.2f ^8(base cooldown of trigger)", triggerCD),
					s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrSkill),
					s_format("= %.4f ^8(final cooldown of trigger)", triggerCD / icdrSkill),
					"",
					(env.player.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
					"",
					"Trigger rate:",
					s_format("1 / %.3f", rateCapAdjusted),
					s_format("= %.3f ^8per second", triggerRate),
				}
			end
			breakdown.SkillTriggerRate = {
				s_format("%.2f ^8(focus base cooldown)", skillFocus.levels[1].cooldown),
				s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdrFocus),
				s_format("+ %.2f ^8(skills are only triggered on activation thus we add focus duration)", focusDuration),
				s_format("= %.2f ^8(effective skill cooldown for trigger purposes)", focusTotalCD),
				"",
				s_format("%.3f casts per second ^8(Assuming player uses focus exactly when its cooldown of %.2fs expires)", 1 / focusTotalCD, focusTotalCD)
			}
		end

		-- Account for Trigger-related INC/MORE modifiers
		addTriggerIncMoreMods(env.player.mainSkill, env.player.mainSkill)
		env.player.mainSkill.infoMessage = "Assuming perfect focus Re-Use"
		env.player.mainSkill.infoTrigger = triggerName
		env.player.mainSkill.skillData.triggerRate = output.SkillTriggerRate
		env.player.mainSkill.skillFlags.globalTrigger = true
	end
end

local function CWCHandler(env)
	if not env.player.mainSkill.skillFlags.minion and not env.player.mainSkill.skillFlags.disable then
		local triggeredSkills = {}
		local trigRate = 0
		local source = nil
		local triggerName = "Cast While Channeling"
		local output = env.player.output
		local breakdown = env.player.breakdown
		for _, skill in ipairs(env.player.activeSkillList) do
			local match1 = env.player.mainSkill.activeEffect.grantedEffect.fromItem and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot
			local match2 = (not env.player.mainSkill.activeEffect.grantedEffect.fromItem) and skill.socketGroup == env.player.mainSkill.socketGroup
			if env.player.mainSkill.triggeredBy.gemData and calcLib.canGrantedEffectSupportActiveSkill(env.player.mainSkill.triggeredBy.gemData.grantedEffect, skill) and skill ~= env.player.mainSkill and (match1 or match2) and not isTriggered(skill) then
				source, trigRate = findTriggerSkill(env, skill, source, trigRate)
			end
			if skill.skillData.triggeredWhileChannelling and (match1 or match2) then
				t_insert(triggeredSkills, packageSkillDataForSimulation(skill, env))
			end
		end
		if not source or #triggeredSkills < 1 then
			env.player.mainSkill.skillData.triggered = nil
			env.player.mainSkill.infoMessage2 = "DPS reported assuming Self-Cast"
			env.player.mainSkill.infoMessage = s_format("No %s Triggering Skill Found", triggerName)
			env.player.mainSkill.infoTrigger = ""
		else
			local triggeredName = env.player.mainSkill.activeEffect.grantedEffect.name or "Triggered"

			output.addsCastTime = processAddedCastTime(env.player.mainSkill, breakdown)

			local icdr = calcLib.mod(env.player.mainSkill.skillModList, env.player.mainSkill.skillCfg, "CooldownRecovery") or 1
			local adjTriggerInterval = m_ceil(source.skillData.triggerTime * data.misc.ServerTickRate) / data.misc.ServerTickRate
			local triggerRateOfTrigger = 1/adjTriggerInterval
			local triggeredCD = env.player.mainSkill.skillData.cooldown
			local cooldownOverride = env.player.mainSkill.skillModList:Override(env.player.mainSkill.skillCfg, "CooldownRecovery")

			if cooldownOverride then
				env.player.mainSkill.skillFlags.hasOverride = true
			end

			local triggeredTotalCooldown = cooldownOverride or m_max(triggeredCD or 0, output.addsCastTime or 0) / icdr
			local triggeredCDAdjusted = m_ceil(triggeredTotalCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
			local effCDTriggeredSkill = m_ceil(triggeredCDAdjusted * triggerRateOfTrigger) / triggerRateOfTrigger

			local simBreakdown = nil
			output.TriggerRateCap = m_min(1 / effCDTriggeredSkill, triggerRateOfTrigger)
			output.SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, triggeredSkills, triggerRateOfTrigger, 0)

			if breakdown then
				if triggeredCD or cooldownOverride then
					breakdown.TriggerRateCap = {
						s_format("Cast While Channeling triggers %s every %.2fs while channeling %s ", triggeredName, source.skillData.triggerTime, source.activeEffect.grantedEffect.name),
						s_format("%.3f ^8(adjusted for server tick rate)", adjTriggerInterval),
						"",
						s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD),
						s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
						s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCD / icdr),
						"",
					}
					if cooldownOverride ~= nil then
						breakdown.TriggerRateCap[4] = s_format("%.2f ^8(hard override of cooldown of %s)", cooldownOverride, triggeredName)
						t_remove(breakdown.TriggerRateCap, 5)
						t_remove(breakdown.TriggerRateCap, 5)
					end
				else
					breakdown.TriggerRateCap = {
						s_format("Cast While Channeling triggers %s every %.2fs while channeling %s ", triggeredName, source.skillData.triggerTime, source.activeEffect.grantedEffect.name),
						s_format("%.3f ^8(adjusted for server tick rate)", adjTriggerInterval),
						"",
						triggeredName .. " has no base cooldown or cooldown override",
						"",
					}
				end

				local function extraIncreaseNeeded(affectedCD)
					if not cooldownOverride then
						local nextBreakpoint = effCDTriggeredSkill - adjTriggerInterval
						local timeOverBreakpoint = triggeredTotalCooldown - nextBreakpoint
						local alreadyReducedTime = triggeredTotalCooldown * icdr - triggeredTotalCooldown
						if timeOverBreakpoint < affectedCD then
							local divNeeded = affectedCD / (affectedCD - timeOverBreakpoint - alreadyReducedTime)
							local incTotal = m_ceil(( divNeeded - 1 ) * 100)
							return incTotal - (icdr - 1) * 100
						end
					end
				end

				if output.addsCastTime then
					t_insert(breakdown.TriggerRateCap, "Cast While Channeling had no base cooldown")
					t_insert(breakdown.TriggerRateCap, s_format("+ %.2f ^8(%s adds cast time as cooldown to trigger)", output.addsCastTime, triggeredName))
					t_insert(breakdown.TriggerRateCap, s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr))
					t_insert(breakdown.TriggerRateCap, s_format("= %.4f ^8(final cooldown of triggered skill)", output.addsCastTime / icdr))
					t_insert(breakdown.TriggerRateCap, "")
					t_insert(breakdown.TriggerRateCap, s_format("%.3f ^8(adjusted for server tick rate)", triggeredCDAdjusted))
					t_insert(breakdown.TriggerRateCap, "")

					local extraCSINeeded = extraIncreaseNeeded(output.addsCastTime)
					local extraICDRNeeded = extraIncreaseNeeded(triggeredTotalCooldown*icdr)
					if extraICDRNeeded then
						t_insert(breakdown.TriggerRateCap, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
					end
					if extraCSINeeded then
						t_insert(breakdown.TriggerRateCap, s_format("^8(extra Cast Rate Increase of %d%% would reach next breakpoint)", extraCSINeeded))
						t_insert(breakdown.TriggerRateCap,"")
					end
				else
					local extraICDRNeeded = extraIncreaseNeeded(triggeredTotalCooldown*icdr)
					if extraICDRNeeded then
						t_insert(breakdown.TriggerRateCap, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
						t_insert(breakdown.TriggerRateCap,"")
					end
				end

				t_insert(breakdown.TriggerRateCap, "Trigger rate:")
				t_insert(breakdown.TriggerRateCap, s_format("1 / %.3f ^8(trigger rate adjusted for triggering interval)", 1 / output.TriggerRateCap))
				t_insert(breakdown.TriggerRateCap, s_format("= %.2f ^8 %s casts per second", output.TriggerRateCap, triggeredName))

				if #triggeredSkills > 1 then
					breakdown.SkillTriggerRate = {
						s_format("%.2f ^8(%s triggers per second)", triggerRateOfTrigger, triggerName),
						s_format("/ %.2f ^8(Estimated impact of linked spells)", (triggerRateOfTrigger / output.SkillTriggerRate) or 1),
						s_format("= %.2f ^8%s casts per second", output.SkillTriggerRate, triggeredName),
					}

					if simBreakdown.extraSimInfo then
						t_insert(breakdown.SkillTriggerRate, "")
						t_insert(breakdown.SkillTriggerRate, simBreakdown.extraSimInfo)
					end
					breakdown.SimData = {
						rowList = { },
						colList = {
							{ label = "Rate", key = "rate" },
							{ label = "Skill Name", key = "skillName" },
							{ label = "Slot Name", key = "slotName" },
							{ label = "Gem Index", key = "gemIndex" },
						},
					}
					for _, rateData in ipairs(simBreakdown.rates) do
						local t = { }
						for str in string.gmatch(rateData.name, "([^_]+)") do
							t_insert(t, str)
						end

						local row = {
							rate = round(rateData.rate,2),
							skillName = t[1],
							slotName = t[2],
							gemIndex = t[3],
						}
						t_insert(breakdown.SimData.rowList, row)
					end
				end
			end

			-- Account for Trigger-related INC/MORE modifiers
			addTriggerIncMoreMods(env.player.mainSkill, env.player.mainSkill)
			env.player.output.ChannelTimeToTrigger = source.skillData.triggerTime
			env.player.mainSkill.skillData.triggered = true
			env.player.mainSkill.skillFlags.globalTrigger = true
			env.player.mainSkill.skillData.triggerRate = output.SkillTriggerRate
			env.player.mainSkill.skillData.triggerSourceUUID = cacheSkillUUID(source, env)
			env.player.mainSkill.infoMessage = triggerName .."'s Trigger: ".. source.activeEffect.grantedEffect.name
			env.player.infoTrigger = env.player.mainSkill.infoTrigger or triggerName
		end
	end
end

local function defaultTriggerHandler(env, config)
	local actor = config.actor
	local output = config.actor.output
	local breakdown = config.actor.breakdown
	local source = config.source
	local triggeredSkills = config.triggeredSkills or {}
	local trigRate = config.trigRate
	local uuid

	-- Find trigger skill and triggered skills
	if config.triggeredSkillCond or config.triggerSkillCond then
		for _, skill in ipairs(env.player.activeSkillList) do
			if config.triggerSkillCond and config.triggerSkillCond(env, skill) and (not isTriggered(skill) or actor.mainSkill.skillFlags.globalTrigger or config.allowTriggered) and skill ~= actor.mainSkill then
				source, trigRate, uuid = findTriggerSkill(env, skill, source, trigRate, config.comparer)
			end
			if config.triggeredSkillCond and config.triggeredSkillCond(env,skill) then
				t_insert(triggeredSkills, packageSkillDataForSimulation(skill, env))
			end
		end
	end
	if #triggeredSkills > 0 or not config.triggeredSkillCond then
		if not source and not (actor.mainSkill.skillFlags.globalTrigger and config.triggeredSkillCond) then
			actor.mainSkill.skillData.triggered = nil
			actor.mainSkill.infoMessage2 = "DPS reported assuming Self-Cast"
			actor.mainSkill.infoMessage = s_format("No %s Triggering Skill Found", config.triggerName)
			actor.mainSkill.infoTrigger = ""
		else
			actor.mainSkill.skillData.triggered = true

			-- Account for Arcanist Brand using activation frequency
			if breakdown and actor.mainSkill.skillData.triggeredByBrand then
				breakdown.EffectiveSourceRate = {
					s_format("%.2f ^8(base activation cooldown of %s)", actor.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency, config.triggerName),
					s_format("* %.2f ^8(more activation frequency)", actor.mainSkill.triggeredBy.activationFreqMore),
					s_format("* %.2f ^8(increased activation frequency)", actor.mainSkill.triggeredBy.activationFreqInc),
					s_format("= %.2f ^8(activation rate of %s)", trigRate, actor.mainSkill.triggeredBy.mainSkill.activeEffect.grantedEffect.name)
				}
			elseif breakdown then
				breakdown.EffectiveSourceRate = {}
				if trigRate and source then
					if config.assumingEveryHitKills then
						t_insert(breakdown.EffectiveSourceRate, "Assuming every attack kills")
					end
					t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(%s %s)", trigRate, config.sourceName or source.activeEffect.grantedEffect.name, config.useCastRate and "cast rate" or "attack rate"))
				end
			end
			
			-- Dual wield triggers
			if trigRate and source and env.player.weaponData1.type and env.player.weaponData2.type and not source.skillData.doubleHitsWhenDualWielding and (source.skillTypes[SkillType.Melee] or source.skillTypes[SkillType.Attack]) and actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.grantedEffect.support and actor.mainSkill.triggeredBy.grantedEffect.fromItem then
				trigRate = trigRate / 2
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, 2, s_format("/ 2 ^8(due to dual wielding)"))
				end
			end

			actor.mainSkill.skillData.ignoresTickRate = actor.mainSkill.skillData.ignoresTickRate or (actor.mainSkill.skillData.storedUses and actor.mainSkill.skillData.storedUses > 1)

			--Account for source unleash
			if source and GlobalCache.cachedData[env.mode][uuid] and source.skillModList:Flag(nil, "HasSeals") and source.skillTypes[SkillType.CanRapidFire] then
				local unleashDpsMult = GlobalCache.cachedData[env.mode][uuid].ActiveSkill.skillData.dpsMultiplier or 1
				trigRate = trigRate * unleashDpsMult
				actor.mainSkill.skillFlags.HasSeals = true
				actor.mainSkill.skillData.ignoresTickRate = true
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.2f ^8(multiplier from Unleash)", unleashDpsMult))
				end
			end

			-- Battlemage's Cry uptime
			if actor.mainSkill.skillData.triggeredByBattleMageCry and GlobalCache.cachedData[env.mode][uuid] and source and source.skillTypes[SkillType.Melee] then
				local battleMageUptime = GlobalCache.cachedData[env.mode][uuid].Env.player.output.BattlemageUpTimeRatio or 100
				trigRate = trigRate * battleMageUptime / 100
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %d%% ^8(Battlemage's Cry uptime)", battleMageUptime))
				end
			end

			-- Infernal Cry uptime
			if actor.mainSkill.activeEffect.grantedEffect.name == "Combust" and GlobalCache.cachedData[env.mode][uuid] and source and source.skillTypes[SkillType.Melee] then
				local InfernalUpTime = GlobalCache.cachedData[env.mode][uuid].Env.player.output.InfernalUpTimeRatio or 100
				trigRate = trigRate * InfernalUpTime / 100
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %d%% ^8(Infernal Cry uptime)", InfernalUpTime))
				end
			end

			--Account for skills that can hit multiple times per use
			if source and GlobalCache.cachedData[env.mode][uuid] and source.skillPartName and source.skillPartName:match("(.*)All(.*)Projectiles(.*)") and source.skillFlags.projectile then
				local multiHitDpsMult = GlobalCache.cachedData[env.mode][uuid].Env.player.output.ProjectileCount or 1
				trigRate = trigRate * multiHitDpsMult
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.2f ^8(%d projectiles hit)", multiHitDpsMult, multiHitDpsMult))
				end
			end

			--Accuracy and crit chance
			if source and (source.skillTypes[SkillType.Melee] or source.skillTypes[SkillType.Attack]) and GlobalCache.cachedData[env.mode][uuid] and not config.triggerOnUse then
				local sourceHitChance = GlobalCache.cachedData[env.mode][uuid].HitChance
				trigRate = trigRate * (sourceHitChance or 0) / 100
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.0f%% ^8(%s hit chance)", sourceHitChance, source.activeEffect.grantedEffect.name))
				end
				if actor.mainSkill.skillData.triggerOnCrit then
					local onCritChance = actor.mainSkill.skillData.chanceToTriggerOnCrit or (GlobalCache.cachedData[env.mode][uuid] and GlobalCache.cachedData[env.mode][uuid].Env.player.mainSkill.skillData.chanceToTriggerOnCrit)
					config.triggerChance = config.triggerChance or actor.mainSkill.skillData.chanceToTriggerOnCrit or onCritChance

					local sourceCritChance = GlobalCache.cachedData[env.mode][uuid].CritChance
					trigRate = trigRate * (sourceCritChance or 0) / 100
					if breakdown then
						t_insert(breakdown.EffectiveSourceRate, s_format("x %.2f%% ^8(%s effective crit chance)", sourceCritChance, source.activeEffect.grantedEffect.name))
					end
				end
			end

			--Special handling for Kitava's Thirst
			-- Repeated hits do not consume mana and do not trigger Kitava's thirst
			if actor.mainSkill.skillData.triggeredByManaSpent then
				local repeats = 1 + source.skillModList:Sum("BASE", nil, "RepeatCount")
				trigRate = trigRate / repeats
				if breakdown and repeats > 1 then
					t_insert(breakdown.EffectiveSourceRate, s_format("/%d ^8(repeated attacks/casts do not count as they don't use mana)", repeats))
				end
			end

			-- Handling for mana spending rate for Manaforged Arrows Support
			if actor.mainSkill.skillData.triggeredByManaforged and trigRate > 0 then
				local triggeredUUID = cacheSkillUUID(actor.mainSkill, env)
				if not GlobalCache.cachedData[env.mode][triggeredUUID] then
					calcs.buildActiveSkill(env, env.mode, actor.mainSkill, {[triggeredUUID] = true})
				end
				local triggeredManaCost = GlobalCache.cachedData[env.mode][triggeredUUID].Env.player.output.ManaCost or 0
				if triggeredManaCost > 0 then
					local manaSpentThreshold = triggeredManaCost * actor.mainSkill.skillData.ManaForgedArrowsPercentThreshold
					local sourceManaCost = GlobalCache.cachedData[env.mode][uuid].Env.player.output.ManaCost or 0
					if sourceManaCost > 0 then
						if breakdown then
							t_insert(breakdown.EffectiveSourceRate, s_format("* %.2f ^8(Mana cost of trigger source)", sourceManaCost))
							t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Mana spent per second)", (trigRate * sourceManaCost)))
							t_insert(breakdown.EffectiveSourceRate, s_format(""))
							t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Mana Cost of triggered)", triggeredManaCost))
							t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Manaforged threshold multiplier)", actor.mainSkill.skillData.ManaForgedArrowsPercentThreshold))
							t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Manaforged trigger threshold)", manaSpentThreshold))
							t_insert(breakdown.EffectiveSourceRate, s_format(""))
							t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Mana spent per second)", (trigRate * sourceManaCost)))
							t_insert(breakdown.EffectiveSourceRate, s_format("/ %.2f ^8(Manaforged trigger threshold)", manaSpentThreshold))
						end
						trigRate = (trigRate * sourceManaCost) / manaSpentThreshold
					else
						trigRate = 0
					end
				end
			end

			--Trigger chance
			if config.triggerChance and config.triggerChance ~= 100 and trigRate then
				trigRate = trigRate * config.triggerChance / 100
				if breakdown and breakdown.EffectiveSourceRate then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.2f%% ^8(chance to trigger)", config.triggerChance))
				elseif breakdown then
					breakdown.EffectiveSourceRate = {
						s_format("%.2f ^8(adjusted trigger rate)", trigRate),
						s_format("x %.2f%% ^8(chance to trigger)", config.triggerChance),
					}
				end
			end

			local icdr = calcLib.mod(actor.mainSkill.skillModList, actor.mainSkill.skillCfg, "CooldownRecovery") or 1
			local addedCooldown = actor.mainSkill.skillModList:Sum("BASE", actor.mainSkill.skillCfg, "CooldownRecovery")
			addedCooldown = addedCooldown ~= 0 and addedCooldown
			local cooldownOverride = actor.mainSkill.skillModList:Override(actor.mainSkill.skillCfg, "CooldownRecovery")
			local triggerCD = actor.mainSkill.triggeredBy and env.player.mainSkill.triggeredBy.grantedEffect.levels[env.player.mainSkill.triggeredBy.level].cooldown
			triggerCD = triggerCD or source.triggeredBy and source.triggeredBy.grantedEffect.levels[source.triggeredBy.level].cooldown
			local triggeredCD = actor.mainSkill.skillData.cooldown
			
			if actor.mainSkill.skillData.triggeredByBrand then
				triggerCD = actor.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency / actor.mainSkill.triggeredBy.activationFreqMore / actor.mainSkill.triggeredBy.activationFreqInc
				triggerCD = triggerCD * icdr -- cancels out division by icdr lower, brand activation rate is not affected by icdr
			end

			local triggeredName = (actor.mainSkill.activeEffect.grantedEffect and actor ~= env.minion and actor.mainSkill.activeEffect.grantedEffect.name) or "Triggered skill"
			local csi
			output.addsCastTime, csi = processAddedCastTime(env.player.mainSkill, breakdown)

			local triggeredCDAdjusted = ( (triggeredCD or 0) + (addedCooldown or 0) ) / icdr
			local triggerCDAdjusted = ( (triggerCD or 0) + (output.addsCastTime or 0) ) / icdr
			local triggeredCDTickRounded = actor.mainSkill.skillData and actor.mainSkill.skillData.ignoresTickRate and triggeredCDAdjusted or m_ceil(triggeredCDAdjusted * data.misc.ServerTickRate) / data.misc.ServerTickRate
			local triggerCDTickRounded = actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.ignoresTickRate and triggerCDAdjusted or m_ceil(triggerCDAdjusted * data.misc.ServerTickRate) / data.misc.ServerTickRate
			local actionCooldown = cooldownOverride or m_max((triggerCD or 0) + (output.addsCastTime or 0), (triggeredCD or 0) + (addedCooldown or 0))
			local actionCooldownAdjusted = cooldownOverride or m_max(triggerCDAdjusted, triggeredCDAdjusted)
			local actionCooldownTickRounded = cooldownOverride and (m_ceil(cooldownOverride * data.misc.ServerTickRate) / data.misc.ServerTickRate) or m_max(triggerCDTickRounded, triggeredCDTickRounded)

			output.TriggerRateCap = source == actor.mainSkill and actor.mainSkill.skillData.triggerRateCapOverride or m_huge
			if actionCooldownTickRounded ~= 0 then
				output.TriggerRateCap = 1 / actionCooldownTickRounded
			end
			if config.triggerName == "Doom Blast" and env.build.configTab.input["doomBlastSource"] == "expiration" then
				local expirationRate = 1 / GlobalCache.cachedData[env.mode][uuid].Env.player.output.Duration
				if breakdown and breakdown.EffectiveSourceRate then
						breakdown.EffectiveSourceRate[1] = s_format("1 / %.2f ^8(source curse duration)", GlobalCache.cachedData[env.mode][uuid].Env.player.output.Duration)
				end
				if expirationRate > trigRate then
					env.player.modDB:NewMod("UsesCurseOverlaps", "FLAG", true, "Config")
					if breakdown and breakdown.EffectiveSourceRate then
						t_insert(breakdown.EffectiveSourceRate, 2, s_format("max(%.2f, %.2f) ^8(If a curse expires instantly curse expiration is equivalent to curse replacement)", expirationRate, trigRate))
						t_insert(breakdown.EffectiveSourceRate, 2, s_format("%.2f ^8(%s cast rate)", trigRate, source.activeEffect.grantedEffect.name))
					end
				else
					trigRate = expirationRate
				end
			elseif config.triggerName == "Doom Blast" and env.build.configTab.input["doomBlastSource"] == "hexblast" then
				local hexBlast, rate
				for _, skill in ipairs(env.player.activeSkillList) do
					if skill.activeEffect.grantedEffect.name == "Hexblast" and not isTriggered(skill) and skill ~= actor.mainSkill then
						hexBlast, rate, uuid = findTriggerSkill(env, skill, hexBlast, rate)
					end
				end
				if hexBlast then
					if breakdown then
						breakdown.EffectiveSourceRate[1] = s_format("1 / (%.2f + %.2f) ^8(sum of triggered curse and hexblast cast time)", 1/trigRate, 1/rate)
					end
					trigRate = 1/ (1/trigRate + 1/rate)
				end
			end

			if breakdown and not breakdown.TriggerRateCap then
				breakdown.TriggerRateCap = {}

				if cooldownOverride then
					t_insert(breakdown.TriggerRateCap, s_format("%.2f ^8(hard override of cooldown of %s)", cooldownOverride, triggeredName))
				elseif triggeredCDAdjusted == 0 then
					t_insert(breakdown.TriggerRateCap, triggeredName .. " has no base cooldown or cooldown override")
				else -- triggeredCDAdjusted ~= 0 triggered skill has some kind of cooldown
					if triggeredCD then
						t_insert(breakdown.TriggerRateCap, s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD))
					else
						t_insert(breakdown.TriggerRateCap, triggeredName .. " has no base cooldown or cooldown override")
					end
					if addedCooldown then
						t_insert(breakdown.TriggerRateCap, s_format("+ %.2f ^8(flat added cooldown)", addedCooldown))
					end
					t_insert(breakdown.TriggerRateCap, s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr))
					t_insert(breakdown.TriggerRateCap, s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCDAdjusted))
				end

				t_insert(breakdown.TriggerRateCap, "")

				if actor ~= env.minion then -- Minion triggers have internal triggers
					if triggerCDAdjusted == 0 then
						t_insert(breakdown.TriggerRateCap, s_format("Trigger rate based on %s cooldown", triggeredName))
					else -- triggerCDAdjusted ~= 0 trigger has some kind of cooldown
						if triggerCD then
							t_insert(breakdown.TriggerRateCap, s_format("%.2f ^8(base cooldown of %s)", triggerCD, config.triggerName))
						else
							t_insert(breakdown.TriggerRateCap, config.triggerName .. " has no base cooldown")
						end
						if output.addsCastTime then
							t_insert(breakdown.TriggerRateCap, s_format("+ %.2f ^8(this skill adds cast time to cooldown when triggered)", output.addsCastTime))
						end
						t_insert(breakdown.TriggerRateCap, s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr))
						t_insert(breakdown.TriggerRateCap, s_format("= %.4f ^8(final cooldown of trigger)", triggerCDAdjusted))
					end
				end

				t_insert(breakdown.TriggerRateCap, "")

				if triggeredCDAdjusted ~= 0 and triggerCDAdjusted ~= 0 then
					t_insert(breakdown.TriggerRateCap, s_format("%.3f ^8(biggest of trigger cooldown and triggered skill cooldown)", actionCooldownAdjusted))
				end

				local displayCooldownRounding = (actor.mainSkill.skillData and not actor.mainSkill.skillData.ignoresTickRate and triggeredCDAdjusted ~= 0) or (actor.mainSkill.triggeredBy and not actor.mainSkill.triggeredBy.ignoresTickRate and triggerCDAdjusted ~= 0)
				if displayCooldownRounding then
					t_insert(breakdown.TriggerRateCap, s_format("%.3f ^8(adjusted for server tick rate)", actionCooldownTickRounded))
				end

				local function extraIncreaseNeeded(affectedCD)
					if not cooldownOverride then
						local nextBreakpoint = actionCooldownTickRounded - data.misc.ServerTickTime
						local timeOverBreakpoint = actionCooldownAdjusted - nextBreakpoint
						local alreadyReducedTime = actionCooldown - actionCooldownAdjusted
						if timeOverBreakpoint < affectedCD then
							local divNeeded = affectedCD / (affectedCD - timeOverBreakpoint - alreadyReducedTime)
							local incTotal = m_ceil(( divNeeded - 1 ) * 100)
							return incTotal - (icdr - 1) * 100
						end
					end
				end

				local extraICDRNeeded = extraIncreaseNeeded(actionCooldown)
				if extraICDRNeeded then
					t_insert(breakdown.TriggerRateCap, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
				end

				local extraCSIncNeeded = output.addsCastTime and extraIncreaseNeeded(output.addsCastTime)
				if extraCSIncNeeded then
					t_insert(breakdown.TriggerRateCap, s_format("^8(extra ICS  of %d%% would reach next breakpoint)", extraCSIncNeeded))
				end

				t_insert(breakdown.TriggerRateCap, "")

				if not (triggeredCD or triggerCD or cooldownOverride) then
					t_insert(breakdown.TriggerRateCap, "Assuming cast on every kill/attack/hit")
				else
					t_insert(breakdown.TriggerRateCap, "Trigger rate:")
					t_insert(breakdown.TriggerRateCap, s_format("1 / %.3f", actionCooldownTickRounded))
					t_insert(breakdown.TriggerRateCap, s_format("= %.2f ^8per second", output.TriggerRateCap))
				end
			end

			if env.player.mainSkill.activeEffect.grantedEffect.name == "Doom Blast" and env.build.configTab.input["doomBlastSource"] == "vixen" then
				if not env.player.itemList["Gloves"] or env.player.itemList["Gloves"].title ~= "Vixen's Entrapment" then
					output.VixenModeNoVixenGlovesWarn = true
				end

				env.player.modDB:NewMod("UsesCurseOverlaps", "FLAG", true, "Config")
				local vixens = env.data.skills["SupportUniqueCastCurseOnCurse"]
				local vixensCD = vixens and vixens.levels[1].cooldown / icdr
				output.EffectiveSourceRate = calcMultiSpellRotationImpact(env, {{ uuid = cacheSkillUUID(env.player.mainSkill, env), icdr = icdr}}, trigRate, vixensCD)
				output.VixensTooMuchCastSpeedWarn = vixensCD > (1 / trigRate)
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("%.2f / %.2f = %.2f ^8(Vixen's trigger cooldown)", vixensCD * icdr, icdr, vixensCD))
					t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Simulated trigger rate of a curse socketed in Vixen's given ^7%.2f ^8CD and ^7%.2f ^8source rate)", output.EffectiveSourceRate, vixensCD, trigRate))
				end
			elseif trigRate ~= nil and not actor.mainSkill.skillFlags.globalTrigger and not config.ignoreSourceRate then
				output.EffectiveSourceRate = trigRate
			else
				output.EffectiveSourceRate = output.TriggerRateCap
				actor.mainSkill.skillFlags.globalTrigger = true
			end

			if breakdown and not actor.mainSkill.skillData.sourceRateIsFinal then
				t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Effective source rate)", output.EffectiveSourceRate))
			end

			local skillName = (source and source.activeEffect.grantedEffect.name) or (actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.grantedEffect.name) or actor.mainSkill.activeEffect.grantedEffect.name

			if output.EffectiveSourceRate ~= 0 then
				-- If the current triggered skill ignores tick rate and is the only triggered skill by this trigger use charge based calcs
				if actor.mainSkill.skillData.ignoresTickRate and ( not config.triggeredSkillCond or (triggeredSkills and #triggeredSkills == 1 and triggeredSkills[1] == packageSkillDataForSimulation(actor.mainSkill, env)) ) then
					local overlaps = config.stagesAreOverlaps and env.player.mainSkill.skillPart == config.stagesAreOverlaps and env.player.mainSkill.activeEffect.srcInstance.skillStageCount or config.overlaps
					output.SkillTriggerRate = m_min(output.TriggerRateCap, output.EffectiveSourceRate * (overlaps or 1))
					if breakdown then
						if overlaps then
							breakdown.SkillTriggerRate = {
								s_format("min(%.2f, %.2f *  %d) ^8(%d overlaps)", output.TriggerRateCap, output.EffectiveSourceRate, overlaps, overlaps)
							}
						else
							breakdown.SkillTriggerRate = {
								s_format("min(%.2f, %.2f)", output.TriggerRateCap, output.EffectiveSourceRate)
							}
						end
					end
				elseif actor.mainSkill.skillFlags.globalTrigger and not config.triggeredSkillCond then -- Trigger does not use source rate breakpoints for one reason or another
					output.SkillTriggerRate = output.EffectiveSourceRate
				else -- Triggers like Cast on Crit go through simulation to calculate the trigger rate of each skill in the trigger group
					output.SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, config.triggeredSkillCond and triggeredSkills or {packageSkillDataForSimulation(actor.mainSkill, env)}, output.EffectiveSourceRate, (not actor.mainSkill.skillData.triggeredByBrand and ( triggerCD or triggeredCD ) or 0), actor)
					local triggerBotsEffective = actor.modDB:Flag(nil, "HaveTriggerBots") and actor.mainSkill.skillTypes[SkillType.Spell]
					if triggerBotsEffective then
						output.SkillTriggerRate = 2 * output.SkillTriggerRate
					end

					-- stagesAreOverlaps is the skill part which makes the stages behave as overlaps
					local hits_per_cast = config.stagesAreOverlaps and env.player.mainSkill.skillPart == config.stagesAreOverlaps and env.player.mainSkill.activeEffect.srcInstance.skillStageCount or 1
					output.SkillTriggerRate = hits_per_cast * output.SkillTriggerRate
					if breakdown and (#triggeredSkills > 1 or triggerBotsEffective or hits_per_cast > 1) then
						breakdown.SkillTriggerRate = {
							s_format("%.2f ^8(%s)", output.EffectiveSourceRate, (actor.mainSkill.skillData.triggeredByBrand and s_format("%s activations per second", source.activeEffect.grantedEffect.name)) or (not trigRate and s_format("%s triggers per second", skillName)) or "Effective source rate"),
							s_format("/ %.2f ^8(Estimated impact of skill rotation and cooldown alignment)", m_max(output.EffectiveSourceRate / output.SkillTriggerRate, 1)),
							s_format("= %.2f ^8per second", output.SkillTriggerRate),
						}
						if triggerBotsEffective then
							t_insert(breakdown.SkillTriggerRate, 3, "x 2 ^8(Trigger bots effectively cause the skill to trigger twice)")
						end
						if hits_per_cast > 1 then
							t_insert(breakdown.SkillTriggerRate, 3, s_format("x %.2f ^8(hits per triggered skill cast)", hits_per_cast))
						end
						if simBreakdown.extraSimInfo then
							t_insert(breakdown.SkillTriggerRate, "")
							t_insert(breakdown.SkillTriggerRate, simBreakdown.extraSimInfo)
						end
						breakdown.SimData = {
							rowList = { },
							colList = {
								{ label = "Rate", key = "rate" },
								{ label = "Skill Name", key = "skillName" },
								{ label = "Slot Name", key = "slotName" },
								{ label = "Gem Index", key = "gemIndex" },
							},
						}
						for _, rateData in ipairs(simBreakdown.rates) do
							local t = { }
							for str in string.gmatch(rateData.name, "([^_]+)") do
								t_insert(t, str)
							end

							local row = {
								rate = round(rateData.rate, 2),
								skillName = t[1],
								slotName = t[2],
								gemIndex = t[3],
							}
							t_insert(breakdown.SimData.rowList, row)
						end
					end
				end
			else
				if breakdown then
					breakdown.SkillTriggerRate = {
						s_format("The trigger needs to be triggered for any skill to be triggered."),
					}
				end
				output.SkillTriggerRate = 0
			end
			actor.mainSkill.skillData.triggerRate = output.SkillTriggerRate

			-- Account for Trigger-related INC/MORE modifiers
			output.Speed = actor.mainSkill.skillData.triggerRate
			addTriggerIncMoreMods(actor.mainSkill, source or actor.mainSkill)
			if source and source ~= actor.mainSkill then
				actor.mainSkill.skillData.triggerSourceUUID = cacheSkillUUID(source, env)
				actor.mainSkill.infoMessage = (config.customTriggerName or ((config.triggerName ~= source.activeEffect.grantedEffect.name and config.triggerName or triggeredName) .. ( actor == env.minion and "'s attack Trigger: " or "'s Trigger: "))) .. source.activeEffect.grantedEffect.name
			else
				actor.mainSkill.infoMessage = actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.grantedEffect.name or config.triggerName .. " Trigger"
			end

			actor.mainSkill.infoTrigger = config.triggerName
		end
	end
end

local configTable = {
	["law of the wilds"] = function()
		return {
			triggerSkillCond = function(env, skill)
				return not skill.skillTypes[SkillType.SummonsTotem] and (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Claw) > 0
			end
		}
	end,
	["the rippling thoughts"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name == "Storm Cascade" then
			return {
				triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack])
				end
			}
		end
	end,
	["the surging thoughts"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name == "Storm Cascade" then
			return {
				triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack])
				end
			}
		end
	end,
	["the hidden blade"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		env.player.mainSkill.skillData.triggerRateCapOverride = 2
		if env.player.modDB:Flag(nil, "Condition:Phasing") then
			if env.player.breakdown then
				env.player.breakdown.TriggerRateCap = {
					s_format("%.2f ^8(Unseen Strike from The Hidden Blade has no cooldown but is still triggered)", env.player.mainSkill.skillData.triggerRateCapOverride),
					s_format("= %.2f", env.player.mainSkill.skillData.triggerRateCapOverride),
				}
			end
			return {source = env.player.mainSkill}
		end
		env.player.mainSkill.skillFlags.disable = true
		env.player.mainSkill.disableReason = "This skill is requires you to be phasing"
	end,
	["replica eternity shroud"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["shroud of the lightless"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["limbsplit"] = function()
		return {triggerName = "Gore Shockwave", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["the cauteriser"] = function()
		return {triggerName = "Gore Shockwave", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["duskblight"] = function()
		return {triggerName = "Stalking Pustule", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["lioneye's paws"] = function(env)
		-- Due to the way the triggerExtraSkill function in mod parser works this trigger does not use the custom trigger skill (RainOfArrowsOnAttackingWithBow)
		-- the normal version is used here instead. The stats are the same but the normal version does not have cooldown.
		env.player.mainSkill.skillData.cooldown = 1
		return {triggerOnUse = true, triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["replica lioneye's paws"] = function(env)
		-- Due to the way the triggerExtraSkill function in mod parser works this trigger does not use the custom trigger skill (RainOfArrowsOnAttackingWithBow)
		-- the normal version is used here instead. The stats are the same but the normal version does not have cooldown.
		env.player.mainSkill.skillData.cooldown = 1
		return {triggerOnUse = true, triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["moonbender's wing"] = function(env)
		--Similar situation to "Replica Lioneye's Paws"
		env.player.mainSkill.skillData.cooldown = 1
		return {triggerName = "Lightning Warp", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["ngamahu's flame"] = function()
		return {triggerName = "Molten Burst", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["cameria's avarice"] = function()
		return {triggerName = "Icicle Burst", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["uul-netol's embrace"] = function()
		return {triggerName = "Bone Nova", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["rigwald's crest"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["jorrhast's blacksteel"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["ashcaller"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["arakaali's fang"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["sporeguard"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["mark of the elder"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["mark of the shaper"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["poet's pen"] = function()
		return {triggerOnUse = true,
				triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Wand) > 0
				end,
				triggeredSkillCond = function(env, skill)
					return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot and skill.skillTypes[SkillType.Spell]
				end}
	end,
	["maloney's mechanism"] = function(env)
		local _, _, uniqueTriggerName = env.player.itemList[env.player.mainSkill.slotName].modSource:find(".*:.*:(.*),.*")
		local isReplica = uniqueTriggerName:match("Replica.")
		return {triggerOnUse = true, triggerName = uniqueTriggerName, useCastRate = isReplica,
				triggerSkillCond = function(env, skill)
					local attack = skill.skillTypes[SkillType.Attack] and (band(skill.skillCfg.flags, ModFlag.Bow) > 0) and not isReplica
					local spell = skill.skillTypes[SkillType.Spell] and isReplica
					return (attack or spell)
				end,
				triggeredSkillCond = function(env, skill)
					return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot and skill.skillTypes[SkillType.RangedAttack]
				end}
	end,
	["asenath's chant"] = function()
		return {triggerOnUse = true,
				triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Bow) > 0
				end,
				triggeredSkillCond = function(env, skill)
					return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot and skill.skillTypes[SkillType.Spell]
				end}
	end,
	["vixen's entrapment"] = function()
		return {useCastRate = true,
				triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Hex]
				end}
	end,
	["flames of judgement"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerName = env.player.mainSkill.activeEffect.grantedEffect.name,
				triggerSkillCond = function(env, skill) return skill.activeEffect.grantedEffect.name == "Queen's Demand" end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot end}
	end,
	["storm of judgement"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerName = env.player.mainSkill.activeEffect.grantedEffect.name,
				triggerSkillCond = function(env, skill) return skill.activeEffect.grantedEffect.name == "Queen's Demand" end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot end}
	end,
	["trigger craft"] = function(env)
		if env.player.mainSkill.skillData.triggeredByCraft then
			local trigRate, source, uuid, useCastRate, triggeredSkills
			triggeredSkills = {}
			for _, skill in ipairs(env.player.activeSkillList) do
				if (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack] or skill.skillTypes[SkillType.Spell]) and not skill.skillFlags.aura and skill ~= env.player.mainSkill and not skill.skillData.triggeredByCraft and not skill.activeEffect.grantedEffect.fromItem and not isTriggered(skill) then
					source, trigRate, uuid = findTriggerSkill(env, skill, source, trigRate)
					if skill.skillFlags and (skill.skillFlags.totem or skill.skillFlags.golem or skill.skillFlags.banner or skill.skillFlags.ballista) and skill.activeEffect.grantedEffect.castTime then
						if skill.activeEffect.grantedEffect.levels ~= nil then
							trigRate = 1 / (skill.activeEffect.grantedEffect.castTime + (skill.activeEffect.grantedEffect.levels[skill.activeEffect.level].cooldown or 0))
						else
							trigRate = 1 / skill.activeEffect.grantedEffect.castTime
						end
						useCastRate = true
					end
				end
				if skill.skillData.triggeredByCraft and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot then
					t_insert(triggeredSkills, packageSkillDataForSimulation(skill, env))
				end
			end
			return {trigRate = trigRate, source = source, uuid = uuid, useCastRate = useCastRate, triggeredSkills = triggeredSkills}
		end
	end,
	["kitava's thirst"] = function(env)
		local requiredManaCost = env.player.modDB:Sum("BASE", nil, "KitavaRequiredManaCost")
		return {triggerChance = env.player.modDB:Sum("BASE", nil, "KitavaTriggerChance"),
				triggerName = "Kitava's Thirst",
				comparer = function(uuid, source, triggerRate)
					local cachedSpeed = GlobalCache.cachedData[env.mode][uuid].HitSpeed or GlobalCache.cachedData[env.mode][uuid].Speed
					local cachedManaCost = GlobalCache.cachedData[env.mode][uuid].ManaCost
					return ( (not source and cachedSpeed) or (cachedSpeed and cachedSpeed > (triggerRate or 0)) ) and ( (cachedManaCost or 0) > requiredManaCost )
				end,
				triggerSkillCond = function(env, skill)
					return true
					-- Filtering done by skill() in SkillStatMap, comparer and default excludes
				end}
	end,
	["mjolner"] = function()
		return {triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, bor(ModFlag.Mace, ModFlag.Weapon1H)) > 0 and not slotMatch(env, skill)
				end,
				triggeredSkillCond = function(env, skill)
					return skill.skillData.triggeredByMjolner and slotMatch(env, skill)
				end}
	end,
	["cospri's malice"] = function()
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Melee] and band(skill.skillCfg.flags, bor(ModFlag.Sword, ModFlag.Weapon1H)) > 0
				end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByCospris and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot end}
	end,
	["cast on critical strike"] = function()
		return {triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and slotMatch(env, skill) end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByCoc and slotMatch(env, skill) end}
	end,
	["cast on melee kill"] = function(env)
		if env.player.modDB:Flag(nil, "Condition:KilledRecently") then
			return {assumingEveryHitKills = true,
					triggerSkillCond = function(env, skill)
						return skill.skillTypes[SkillType.Attack] and skill.skillTypes[SkillType.Melee] and slotMatch(env, skill)
					end,
					triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByMeleeKill and slotMatch(env, skill) end}
		else
			env.player.mainSkill.infoMessage2 = "DPS reported assuming Self-Cast"
			env.player.mainSkill.infoMessage = "Cast on Melee Kill requires recent kills"
		end
	end,
	["nova"] = function(env)
		if env.minion and env.minion.mainSkill then
			return {triggerName = "Summon Holy Relic",
				   actor = env.minion,
				   triggeredSkills = {{ uuid = cacheSkillUUID(env.minion.mainSkill, env), cd = env.minion.mainSkill.skillData.cooldown}},
				   triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] end}
		end
	end,
	["cast when damage taken"] = function(env)
		local thresholdMod = calcLib.mod(env.player.mainSkill.skillModList, nil, "CWDTThreshold")
		env.player.output.CWDTThreshold = env.player.mainSkill.skillData.triggeredByDamageTaken * thresholdMod
		if env.player.breakdown and env.player.output.CWDTThreshold ~= env.player.mainSkill.skillData.triggeredByDamageTaken then
			env.player.breakdown.CWDTThreshold = {
				s_format("%.2f ^8(base threshold)", env.player.mainSkill.skillData.triggeredByDamageTaken),
				s_format("x %.2f ^8(threshold modifier)", thresholdMod),
				s_format("= %.2f", env.player.output.CWDTThreshold),
			}
		end
        env.player.mainSkill.skillFlags.globalTrigger = true
		return  {source = env.player.mainSkill}
	end,
	["cast when stunned"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {triggerChance =  env.player.mainSkill.skillData.chanceToTriggerOnStun,
				source = env.player.mainSkill}
	end,
	["spellslinger"] = function()
		return {triggerName = "Spellslinger",
				triggerOnUse = true,
				triggerSkillCond = function(env, skill)
					local isWandAttack = (not skill.weaponTypes or (skill.weaponTypes and skill.weaponTypes["Wand"])) and skill.skillTypes[SkillType.Attack]
					return isWandAttack and not skill.skillData.triggeredBySpellSlinger
				end}
	end,
	["mark on hit"] = function()
		return {triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] end}
	end,
	["hextouch"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Attack] and slotMatch(env, skill)
				end}
	end,
	["oskarm"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Attack]
				end}
	end,
	["tempest shield"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["shattershard"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["riposte"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["reckoning"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["vengeance"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["battlemage's cry"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name ~= "Battlemage's Cry" then
			return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] end,
					triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByBattleMageCry and slotMatch(env, skill) end}
		end
	end,
	["arcanist brand"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name ~= "Arcanist Brand" then
			env.player.mainSkill.skillData.sourceRateIsFinal = true
			for _, skill in ipairs(env.player.activeSkillList) do
				if skill.activeEffect.grantedEffect.name == "Arcanist Brand" then
					env.player.mainSkill.triggeredBy.mainSkill = skill
					break
				end
			end

			local activationFreqInc = (100 + env.player.mainSkill.triggeredBy.mainSkill.skillModList:Sum("INC", env.player.mainSkill.skillCfg, "Speed", "BrandActivationFrequency")) / 100
			local activationFreqMore = env.player.mainSkill.triggeredBy.mainSkill.skillModList:More(env.player.mainSkill.skillCfg, "BrandActivationFrequency")
			env.player.mainSkill.triggeredBy.activationFreqInc = activationFreqInc
			env.player.mainSkill.triggeredBy.activationFreqMore = activationFreqMore
			env.player.mainSkill.triggeredBy.ignoresTickRate = true
			env.player.output.EffectiveSourceRate = trigRate
			return {trigRate = env.player.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency * activationFreqInc * activationFreqMore,
					source = env.player.mainSkill.triggeredBy.mainSkill,
					triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByBrand and slotMatch(env, skill) end}
		end
	end,
	["cast on death"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		env.player.mainSkill.skillData.triggered = true
		env.player.mainSkill.infoMessage = env.player.mainSkill.activeEffect.grantedEffect.name .. " Triggered on Death"
	end,
	["combust"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] end}
	end,
	["prismatic burst"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Attack] and slotMatch(env, skill) end}
	end,
	["shockwave"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] and slotMatch(env, skill) end}
	end,
	["manaforged arrows"] = function(env)
		return {triggerOnUse = true,
				triggerName = "Manaforged Arrows",
				triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["doom blast"] = function(env)
		if env.build.configTab.input["doomBlastSource"] == "replacement" then
			env.player.modDB:NewMod("UsesCurseOverlaps", "FLAG", true, "Config")
		end
		env.player.mainSkill.skillData.ignoresTickRate = true
		return {useCastRate = true,
				overlaps = #env.player.modDB:Tabulate("BASE", nil, "Multiplier:CurseOverlaps") > 0 and m_max(env.player.modDB:Sum("BASE", nil, "Multiplier:CurseOverlaps"), 1),
				customTriggerName = "Doom Blast triggering Hex: ",
				triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Hex] and slotMatch(env, skill) end}
	end,
	["cast while channelling"] = function()
		return {customHandler = CWCHandler}
	end,
	["focus"] = function()
		return {customHandler = helmetFocusHandler}
	end,
	["snipe"] = function(env)
		local snipeStages = m_min(env.player.modDB:Sum("BASE", nil, "Multiplier:SnipeStage"), env.player.modDB:Sum("BASE", nil, "Multiplier:SnipeStagesMax"))
		local snipeHitMulti = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "snipeHitMulti")
		local snipeAilmentMulti = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "snipeAilmentMulti")
		local triggeredSkills = {}

		for _, skill in ipairs(env.player.activeSkillList) do
			if skill.skillData.triggeredBySnipe and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot then
				t_insert(triggeredSkills, skill)
			end
		end

		if env.player.mainSkill.activeEffect.grantedEffect.name == "Snipe" then
			if env.player.mainSkill.skillData.limitedProcessing then
				-- Snipe is being used by some other skill. In this case snipe does not get more damage mods
				snipeStages = 0
			else
				-- max(1, snipeStages) makes it behave consistently with other channeled ranged skills (scourge arrow)
				env.player.mainSkill.skillData.hitTimeMultiplier = m_max(1, snipeStages) - 0.5 --First stage takes 0.5x time to channel compared to subsequent stages
			end
			if #triggeredSkills < 1 then
				-- Snipe is being used as a standalone skill
				if snipeStages then
					env.player.mainSkill.skillModList:NewMod("Damage", "MORE", snipeHitMulti * snipeStages, "Snipe", ModFlag.Hit, 0)
					env.player.mainSkill.skillModList:NewMod("Damage", "MORE", snipeAilmentMulti * snipeStages, "Snipe", ModFlag.Ailment, 0)
				end
			else
				-- Snipe is being used as a trigger source, it triggers other skills but does no damage it self
				env.player.mainSkill.skillModList:NewMod("DealNoLightning", "FLAG", true, { type = "SkillName", skillName = "Snipe", includeTransfigured = true })
				env.player.mainSkill.skillModList:NewMod("DealNoCold", "FLAG", true, { type = "SkillName", skillName = "Snipe", includeTransfigured = true })
				env.player.mainSkill.skillModList:NewMod("DealNoFire", "FLAG", true, { type = "SkillName", skillName = "Snipe", includeTransfigured = true })
				env.player.mainSkill.skillModList:NewMod("DealNoChaos", "FLAG", true, { type = "SkillName", skillName = "Snipe", includeTransfigured = true })
				env.player.mainSkill.skillModList:NewMod("DealNoPhysical", "FLAG", true, { type = "SkillName", skillName = "Snipe", includeTransfigured = true })
			end
		else
			local currentSkillSnipeIndex
			for index, skill in ipairs(triggeredSkills) do
				if skill == env.player.mainSkill then
					currentSkillSnipeIndex = index
					break
				end
			end

			-- Does snipe have enough stages to trigger this skill?
			if currentSkillSnipeIndex and currentSkillSnipeIndex <= snipeStages then
				local source
				local trigRate
				env.player.mainSkill.skillModList:NewMod("Damage", "MORE", snipeHitMulti * snipeStages , "Snipe", ModFlag.Hit, 0)
				env.player.mainSkill.skillModList:NewMod("Damage", "MORE", snipeAilmentMulti * snipeStages , "Snipe", ModFlag.Ailment, 0)
				for _, skill in ipairs(env.player.activeSkillList) do
					if skill.activeEffect.grantedEffect.name == "Snipe" and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot then
						skill.skillData.hitTimeMultiplier = snipeStages - 0.5
						local uuid = cacheSkillUUID(skill, env)
						if not GlobalCache.cachedData[env.mode][uuid] or env.mode == "CALCULATOR" then
							calcs.buildActiveSkill(env, env.mode, skill)
						end
						local cachedSpeed = GlobalCache.cachedData[env.mode][uuid].Env.player.output.HitSpeed
						if (skill.skillFlags and not skill.skillFlags.disable) and (skill.skillCfg and not skill.skillCfg.skillCond["usedByMirage"]) and not skill.skillTypes[SkillType.OtherThingUsesSkill] and ((not source and cachedSpeed) or (cachedSpeed and cachedSpeed > (trigRate or 0))) then
							trigRate = cachedSpeed
							env.player.output.ChannelTimeToTrigger = GlobalCache.cachedData[env.mode][uuid].Env.player.output.HitTime
							source = skill
						end
					end
				end

				return {trigRate = trigRate, source = source}
			else
				env.player.mainSkill.skillData.triggered = nil
				env.player.mainSkill.infoMessage2 = "DPS reported assuming Self-Cast"
				env.player.mainSkill.infoMessage = "Not enough Snipe stages to trigger this skill"
				env.player.mainSkill.infoTrigger = ""
			end
		end
	end,
	["avenging flame"]  = function(env)
		return {triggerSkillCond = function(env, skill) return skill.skillFlags.totem and slotMatch(env, skill) end,
				comparer = function(uuid, source, currentTotemLife)
					local totemLife = GlobalCache.cachedData[env.mode][uuid].Env.player.output.TotemLife
					return (not source and totemLife) or (totemLife and totemLife > (currentTotemLife or 0))
				end,
				ignoreSourceRate = true}
	end,
	["intuitive link"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name ~= "Intuitive Link" then
			for _, skill in ipairs(env.player.activeSkillList) do
				if skill.activeEffect.grantedEffect.name == "Intuitive Link" then
					env.player.mainSkill.triggeredBy.mainSkill = skill
					break
				end
			end
			return {triggeredSkillCond = function(env, skill) return skill.skillTypes[SkillType.Spell] and slotMatch(env, skill) and skill ~= env.player.mainSkill.triggeredBy.mainSkill end,
					trigRate = env.modDB:Sum("BASE", nil, "IntuitiveLinkSourceRate"),
					source = env.player.mainSkill.triggeredBy.mainSkill,
					sourceName = "Custom source",
					useCastRate = true}
		end
	end,
}

-- Find unique item trigger name
local function getUniqueItemTriggerName(skill)
	if skill.skillData.triggerSource then
		return skill.skillData.triggerSource
	elseif skill.supportList and #skill.supportList >= 1 then
		for _, gemInstance in ipairs(skill.supportList) do
			if gemInstance.grantedEffect and gemInstance.grantedEffect.fromItem then
				return gemInstance.grantedEffect.name
			end
		end
	end

	if skill.socketGroup and skill.socketGroup.source then
		local _, _, uniqueTriggerName = skill.socketGroup.source:find(".*:.*:(.*),.*")
		return uniqueTriggerName
	end
end

function calcs.triggers(env, actor)
	if actor and not actor.mainSkill.skillFlags.disable and not actor.mainSkill.skillData.limitedProcessing then
		local skillName = actor.mainSkill.activeEffect.grantedEffect.name
		local triggerName = actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.grantedEffect.name
		local uniqueName = isTriggered(actor.mainSkill) and getUniqueItemTriggerName(actor.mainSkill)
		local skillNameLower = skillName and skillName:lower()
		local triggerNameLower = triggerName and triggerName:lower()
		local awakenedTriggerNameLower = triggerNameLower and triggerNameLower:gsub("^awakened ", "")
		local uniqueNameLower = uniqueName and uniqueName:lower()
		local config = skillNameLower and configTable[skillNameLower] and configTable[skillNameLower](env)
        config = config or triggerNameLower and configTable[triggerNameLower] and configTable[triggerNameLower](env)
        config = config or awakenedTriggerNameLower and configTable[awakenedTriggerNameLower] and configTable[awakenedTriggerNameLower](env)
        config = config or uniqueNameLower and configTable[uniqueNameLower] and configTable[uniqueNameLower](env)
		if config then
		    config.actor = config.actor or actor
			config.triggerName = config.triggerName or triggerName or uniqueName or skillName
			config.triggerChance = config.triggerChance or (actor.mainSkill.activeEffect.srcInstance and actor.mainSkill.activeEffect.srcInstance.triggerChance)
			local triggerHandler = config.customHandler or defaultTriggerHandler
		    triggerHandler(env, config)
		else
			actor.mainSkill.skillData.triggered = nil
        end
	end
end