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

local function isTriggered(skill)
	return skill.skillData.triggeredByUnique or skill.skillData.triggered or skill.skillTypes[SkillType.InbuiltTrigger] or skill.skillTypes[SkillType.Triggered] or skill.activeEffect.grantedEffect.triggered
end

local function processAddedCastTime(skill, breakdown)
	if skill.skillModList:Flag(skill.skillCfg, "SpellCastTimeAddedToCooldownIfTriggered") then
		local baseCastTime = skill.skillData.castTimeOverride or skill.activeEffect.grantedEffect.castTime or 1
		local inc = skill.skillModList:Sum("INC", skill.skillCfg, "Speed")
		local more = skill.skillModList:More(skill.skillCfg, "Speed")
		local addsCastTime = baseCastTime / round((1 + inc/100) * more, 2)
		skill.skillFlags.addsCastTime = true
		if breakdown then
			breakdown.AddedCastTime = {
				s_format("%.2f ^8(base cast time of %s)", baseCastTime, skill.activeEffect.grantedEffect.name),
				s_format("%.2f ^8(increased/reduced)", 1 + inc/100),
				s_format("%.2f ^8(more/less)", more),
				s_format("= %.2f ^8cast time", addsCastTime)
			}
		end
		return addsCastTime
	end
end

local function packageSkillDataForSimulation(skill, env)
	return { uuid = cacheSkillUUID(skill, env), cd = skill.skillData.cooldown, cdOverride = skill.skillModList:Override(skill.skillCfg, "CooldownRecovery"), addsCastTime = processAddedCastTime(skill), icdr = calcLib.mod(skill.skillModList, skill.skillCfg, "CooldownRecovery")}
end

-- Identify the trigger action skill for trigger conditions, take highest Attack Per Second
local function findTriggerSkill(env, skill, source, triggerRate, comparer)
	local comparer = comparer or function(uuid, source, triggerRate)
		local cachedSpeed = GlobalCache.cachedData["CACHE"][uuid].Speed
		return (not source and cachedSpeed) or (cachedSpeed and cachedSpeed > (triggerRate or 0))
	end
	
	local uuid = cacheSkillUUID(skill, env)
	if not GlobalCache.cachedData["CACHE"][uuid] or GlobalCache.noCache then
		calcs.buildActiveSkill(env, "CACHE", skill)
	end

	if GlobalCache.cachedData["CACHE"][uuid] and comparer(uuid, source, triggerRate) and (skill.skillFlags and not skill.skillFlags.disable) then
		return skill, GlobalCache.cachedData["CACHE"][uuid].Speed, uuid
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
		skill.cd = m_max(skill.cdOverride or ((skill.cd or 0) / (skill.icdr or 1) + (skill.addsCastTime or 0)), triggerCD)
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

local function mirageArcherHandler(env)
	-- Mirage Archer Support
	-- This creates and populates env.player.mainSkill.mirage table
	if not env.player.mainSkill.skillFlags.minion and not env.player.mainSkill.skillData.limitedProcessing then
		local usedSkill = nil
		local uuid = cacheSkillUUID(env.player.mainSkill, env)
		local calcMode = env.mode == "CALCS" and "CALCS" or "MAIN"

		if not GlobalCache.cachedData[calcMode][uuid] then
			calcs.buildActiveSkill(env, calcMode, env.player.mainSkill, {[uuid] = true})
		end

		if GlobalCache.cachedData[calcMode][uuid] then
			usedSkill = GlobalCache.cachedData[calcMode][uuid].ActiveSkill
		end

		if usedSkill then
			local moreDamage =  usedSkill.skillModList:Sum("BASE", usedSkill.skillCfg, "MirageArcherLessDamage")
			local moreAttackSpeed = usedSkill.skillModList:Sum("BASE", usedSkill.skillCfg, "MirageArcherLessAttackSpeed")
			local mirageCount =  usedSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "MirageArcherMaxCount")

			-- Make a copy of this skill so we can add new modifiers to the copy affected by Mirage Archers
			local newSkill, newEnv = calcs.copyActiveSkill(env, calcMode, usedSkill)

			-- Add new modifiers to new skill (which already has all the old skill's modifiers)
			newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "Mirage Archer", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
			newSkill.skillModList:NewMod("Speed", "MORE", moreAttackSpeed, "Mirage Archer", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
			newSkill.skillCfg.skillCond["usedByMirage"] = true

			env.player.mainSkill.mirage = { }
			env.player.mainSkill.mirage.count = mirageCount
			env.player.mainSkill.mirage.name = usedSkill.activeEffect.grantedEffect.name

			if usedSkill.skillPartName then
				env.player.mainSkill.mirage.skillPart = usedSkill.skillPart
				env.player.mainSkill.mirage.skillPartName = usedSkill.skillPartName
				env.player.mainSkill.mirage.infoMessage2 = usedSkill.activeEffect.grantedEffect.name
			else
				env.player.mainSkill.mirage.skillPartName = nil
			end
			env.player.mainSkill.mirage.infoTrigger = "MA"

			-- Recalculate the offensive/defensive aspects of the Mirage Archer influence on skill
			newEnv.player.mainSkill = newSkill
			-- mark it so we don't recurse infinitely
			
			newSkill.skillData.limitedProcessing = true
			calcs.perform(newEnv)

			env.player.mainSkill.infoMessage = tostring(mirageCount) .. " Mirage Archers using " .. usedSkill.activeEffect.grantedEffect.name

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
		else
			env.player.mainSkill.infoMessage2 = "No Mirage Archer active skill found"
		end
	end
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
		env.player.mainSkill.skillData.triggerSource = source
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
			if skill.skillTypes[SkillType.Channel] and skill ~= env.player.mainSkill and (match1 or match2) and not isTriggered(skill) then
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
			
			local triggeredTotalCooldown = cooldownOverride or (((triggeredCD or 0.0) / icdr) + (output.addsCastTime or 0))
			local effCDTriggeredSkill = m_ceil(triggeredTotalCooldown * triggerRateOfTrigger) / triggerRateOfTrigger
			
			local simBreakdown = nil
			output.TriggerRateCap = m_min(1 / effCDTriggeredSkill, triggerRateOfTrigger)
			output.SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, triggeredSkills, triggerRateOfTrigger, 0)
			
			if breakdown then
				if triggeredCD or cooldownOverride then
					breakdown.TriggerRateCap = {
						s_format("Cast While Channeling triggers %s every %.2fs while channeling %s ", triggeredName, source.skillData.triggerTime, source.activeEffect.grantedEffect.name),
						s_format("%.3f ^8(adjusted for server tick rate)", adjTriggerInterval),
						"",
						s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD or 0),
						s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
						s_format("= %.4f ^8(final cooldown of triggered skill)", ((triggeredCD or 0) / icdr) +  (output.addsCastTime or 0)),
						"",
					}
					if cooldownOverride ~= nil then
						breakdown.TriggerRateCap[4] = s_format("%.2f ^8(hard override of cooldown of %s)", cooldownOverride, triggeredName)
						t_remove(breakdown.TriggerRateCap, 5)
						t_remove(breakdown.TriggerRateCap, 5)
					end
					if output.addsCastTime then
						t_insert(breakdown.TriggerRateCap, 5, s_format("+ %.2f ^8(this skill adds cast time to cooldown when triggered)", output.addsCastTime))
					end
				else
					breakdown.TriggerRateCap = {
						s_format("Cast While Channeling triggers %s every %.2fs while channeling %s ", triggeredName, source.skillData.triggerTime, source.activeEffect.grantedEffect.name),
						s_format("%.3f ^8(adjusted for server tick rate)", adjTriggerInterval),
						"",
						triggeredName .. " has no base cooldown or cooldown override",
						"",
					}
					if output.addsCastTime then
						t_insert(breakdown.TriggerRateCap, 5, s_format("+ %.2f ^8(this skill adds cast time to cooldown when triggered)", output.addsCastTime))
						t_insert(breakdown.TriggerRateCap, 6,s_format("= %.4f ^8(final cooldown of triggered skill)", output.addsCastTime))
					end
				end
				
				local timeAboveLastBreakPoint = triggeredTotalCooldown + adjTriggerInterval - effCDTriggeredSkill
				
				if triggeredCD and triggeredTotalCooldown > adjTriggerInterval and timeAboveLastBreakPoint < (triggeredCD / icdr) then
					t_insert(breakdown.TriggerRateCap, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", ((((triggeredCD / icdr) / ((triggeredCD / icdr) - timeAboveLastBreakPoint)) - 1) * 100)))
					t_insert(breakdown.TriggerRateCap,"")
				end
				
				if output.addsCastTime and triggeredTotalCooldown > adjTriggerInterval and timeAboveLastBreakPoint < output.addsCastTime then
					t_insert(breakdown.TriggerRateCap, s_format("^8(extra Cast Rate Increase of %d%% would reach next breakpoint)", (((output.addsCastTime / (output.addsCastTime - timeAboveLastBreakPoint )) - 1) * 100)))
					t_insert(breakdown.TriggerRateCap,"")
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
			env.player.mainSkill.skillData.triggerSource = source
			env.player.mainSkill.skillData.triggerRate = output.SkillTriggerRate
			env.player.mainSkill.skillData.triggerSourceUUID = cacheSkillUUID(source, env)
			env.player.mainSkill.infoMessage = triggerName .."'s Trigger: ".. source.activeEffect.grantedEffect.name
			env.player.infoTrigger = env.player.mainSkill.infoTrigger or triggerName
		end
	end
end

local function theSaviourHandler(env)
	local usedSkill = nil
	local usedSkillBestDps = 0
	local calcMode = env.mode == "CALCS" and "CALCS" or "MAIN"
	for _, triggerSkill in ipairs(env.player.activeSkillList) do
		if triggerSkill ~= env.player.mainSkill and triggerSkill.skillTypes[SkillType.Attack] and not triggerSkill.skillTypes[SkillType.Totem] and not triggerSkill.skillTypes[SkillType.SummonsTotem] and band(triggerSkill.skillCfg.flags, bor(ModFlag.Sword, ModFlag.Weapon1H)) == bor(ModFlag.Sword, ModFlag.Weapon1H) then
			-- Grab a fully-processed by calcs.perform() version of the skill that Mirage Warrior(s) will use
			local uuid = cacheSkillUUID(triggerSkill, env)
			if not GlobalCache.cachedData[calcMode][uuid] then
				calcs.buildActiveSkill(env, calcMode, triggerSkill)
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
		local moreDamage = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SaviourMirageWarriorLessDamage")
		local maxMirageWarriors = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SaviourMirageWarriorMaxCount")
		local newSkill, newEnv = calcs.copyActiveSkill(env, calcMode, usedSkill)

		-- Add new modifiers to new skill (which already has all the old skill's modifiers)
		newSkill.skillModList:NewMod("Damage", "MORE", moreDamage, "The Saviour", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)
		if env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 1"].name == env.player.itemList["Weapon 2"].name then
			maxMirageWarriors = maxMirageWarriors / 2
		end
		newSkill.skillModList:NewMod("QuantityMultiplier", "BASE", maxMirageWarriors, "The Saviour Mirage Warriors", env.player.mainSkill.ModFlags, env.player.mainSkill.KeywordFlags)

		if usedSkill.skillPartName then
			env.player.mainSkill.skillPart = usedSkill.skillPart
			env.player.mainSkill.skillPartName = usedSkill.skillPartName
			env.player.mainSkill.infoMessage2 = usedSkill.activeEffect.grantedEffect.name
		else
			env.player.mainSkill.skillPartName = usedSkill.activeEffect.grantedEffect.name
		end
		
		newSkill.skillCfg.skillCond["usedByMirage"] = true
		
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
		env.player.mainSkill.infoMessage2 = "No Saviour active skill found"
	end
end

local function tawhoaChosenHandler(env)
	local usedSkill = nil
	local usedSkillBestDps = 0
	local sourceAPS = 0
	local calcMode = env.mode == "CALCS" and "CALCS" or "MAIN"
	
	for _, triggerSkill in ipairs(env.player.activeSkillList) do
		local isDisabled = triggerSkill.skillFlags and triggerSkill.skillFlags.disable
		if triggerSkill ~= env.player.mainSkill and (triggerSkill.skillTypes[SkillType.Slam] or triggerSkill.skillTypes[SkillType.Melee]) and triggerSkill.skillTypes[SkillType.Attack] and not triggerSkill.skillTypes[SkillType.Vaal] and not isTriggered(triggerSkill) and not isDisabled and not triggerSkill.skillTypes[SkillType.Totem] and not triggerSkill.skillTypes[SkillType.SummonsTotem] then
			-- Grab a fully-processed by calcs.perform() version of the skill that Tawhoa's Chosen will use
			local uuid = cacheSkillUUID(triggerSkill, env)
			if not GlobalCache.cachedData[calcMode][uuid] then
				calcs.buildActiveSkill(env, calcMode, triggerSkill)
			end
			
			if GlobalCache.cachedData[calcMode][uuid] and GlobalCache.cachedData[calcMode][uuid].Speed then
				if not usedSkill then
					usedSkill = GlobalCache.cachedData[calcMode][uuid].ActiveSkill
					usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
					sourceAPS = GlobalCache.cachedData[calcMode][uuid].Speed
				else
					if GlobalCache.cachedData[calcMode][uuid].TotalDPS > usedSkillBestDps then
						usedSkill = GlobalCache.cachedData[calcMode][uuid].ActiveSkill
						usedSkillBestDps = GlobalCache.cachedData[calcMode][uuid].TotalDPS
						sourceAPS = GlobalCache.cachedData[calcMode][uuid].Speed
					end
				end
			end
		end
	end
	
	if usedSkill then
		local moreDamage = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ChieftainMirageChieftainMoreDamage")
		local newSkill, newEnv = calcs.copyActiveSkill(env, calcMode, usedSkill)
		newSkill.skillData.triggered = true
		newSkill.skillTypes[SkillType.OtherThingUsesSkill] = true
		
		-- Calculate trigger rate
		local triggerCD = env.player.mainSkill.skillData.cooldown
		local triggeredCD = newSkill.skillData.cooldown
		local triggerDuration = calcSkillDuration(env.player.mainSkill.skillModList, env.player.mainSkill.skillCfg, env.player.mainSkill.skillData, env, env.player.enemy.modDB)
		local icdrSkill = calcLib.mod(newSkill.skillModList, newSkill.skillCfg, "CooldownRecovery")
		local effectiveTriggerCD = (triggerCD / icdrSkill) + triggerDuration
		
		local modActionCooldown = m_max( triggeredCD or 0, effectiveTriggerCD or 0 ) / icdrSkill
		local rateCapAdjusted = m_ceil(modActionCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
		local triggerRateCap = m_huge
		if modActionCooldown ~= 0 then
			triggerRateCap = 1 / modActionCooldown
		end
		
		local BreakdownEffectiveSourceRate = {}
		local EffectiveSourceRate = sourceAPS
		local BreakdownSkillTriggerRate = {}
		local SkillTriggerRate
		local BreakdownSimData
		local simBreakdown
		
		if EffectiveSourceRate ~= 0 then
			SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, {{ uuid = cacheSkillUUID(usedSkill, env), cd = triggeredCD }}, EffectiveSourceRate, effectiveTriggerCD)
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

		env.player.mainSkill.infoMessage = "Tawhoa's Chosen using " .. usedSkill.activeEffect.grantedEffect.name

		-- Re-link over the output
		env.player.output = newEnv.player.output

		-- Make any necessary corrections to output
		env.player.output.ManaCost = 0
		env.player.output.Speed = SkillTriggerRate
		env.player.output.TriggerRateCap = triggerRateCap
		env.player.output.EffectiveSourceRate = EffectiveSourceRate
		env.player.output.SkillTriggerRate = SkillTriggerRate
		
		-- Re-link over the breakdown (if present)
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

			-- Make any necessary corrections to breakdown
			env.player.breakdown.ManaCost = nil
		end
	else
		env.player.mainSkill.disableReason = "No Tawhoa's Chosen active skill found"
		env.player.mainSkill.skillFlags.disable = true
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
					t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(%s %s)", trigRate, source.activeEffect.grantedEffect.name, config.useCastRate and "cast rate" or "attack rate"))
				end
			end
			
			--Dual wield
			if trigRate and source and (source.skillTypes[SkillType.Melee] or source.skillTypes[SkillType.Damage] or source.skillTypes[SkillType.Attack]) and not actor.mainSkill.skillFlags.globalTrigger then
				local dualWield = env.player.weaponData1.type and env.player.weaponData2.type
				trigRate = dualWield and source.skillData.doubleHitsWhenDualWielding and trigRate * 2 or dualWield and trigRate / 2 or trigRate
				if dualWield and breakdown then
					t_insert(breakdown.EffectiveSourceRate, 2, s_format("%s 2 ^8(due to dual wielding)", source.skillData.doubleHitsWhenDualWielding and "*" or "/"))
				end
			end
			
			actor.mainSkill.skillData.ignoresTickRate = actor.mainSkill.skillData.ignoresTickRate or source and source.skillData.storedUses and source.skillData.storedUses > 1
			actor.mainSkill.skillData.ignoresTickRate = actor.mainSkill.skillData.ignoresTickRate and not source.skillData.triggeredByCurseOnCurse

			--Account for source unleash
			if source and GlobalCache.cachedData["CACHE"][uuid] and source.skillModList:Flag(nil, "HasSeals") and source.skillTypes[SkillType.CanRapidFire] then
				local unleashDpsMult = GlobalCache.cachedData["CACHE"][uuid].ActiveSkill.skillData.dpsMultiplier or 1
				trigRate = trigRate * unleashDpsMult
				actor.mainSkill.skillFlags.HasSeals = true
				actor.mainSkill.skillData.ignoresTickRate = true
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.2f ^8(multiplier from Unleash)", unleashDpsMult))
				end
			end
			
			-- Battlemage's Cry uptime
			if actor.mainSkill.skillData.triggeredByBattleMageCry and GlobalCache.cachedData["CACHE"][uuid] and source and source.skillTypes[SkillType.Melee] then
				local battleMageUptime = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.BattlemageUpTimeRatio or 100
				trigRate = trigRate * battleMageUptime / 100
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %d%% ^8(Battlemage's Cry uptime)", battleMageUptime))
				end
			end
			
			-- Infernal Cry uptime
			if actor.mainSkill.activeEffect.grantedEffect.name == "Combust" and GlobalCache.cachedData["CACHE"][uuid] and source and source.skillTypes[SkillType.Melee] then
				local InfernalUpTime = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.InfernalUpTimeRatio or 100
				trigRate = trigRate * InfernalUpTime / 100
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %d%% ^8(Infernal Cry uptime)", InfernalUpTime))
				end
			end
			
			--Account for skills that can hit multiple times per use
			if source and GlobalCache.cachedData["CACHE"][uuid] and source.skillPartName and source.skillPartName:match("(.*)All(.*)Projectiles(.*)") and source.skillFlags.projectile then
				local multiHitDpsMult = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.ProjectileCount or 1
				trigRate = trigRate * multiHitDpsMult
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.2f ^8(%d projectiles hit)", multiHitDpsMult, multiHitDpsMult))
				end
			end
			
			--Accuracy and crit chance
			if source and (source.skillTypes[SkillType.Melee] or source.skillTypes[SkillType.Attack]) and GlobalCache.cachedData["CACHE"][uuid] and not config.triggerOnUse then
				local sourceHitChance = GlobalCache.cachedData["CACHE"][uuid].HitChance					
				trigRate = trigRate * (sourceHitChance or 0) / 100
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("x %.0f%% ^8(%s hit chance)", sourceHitChance, source.activeEffect.grantedEffect.name))
				end
				if (actor.mainSkill.skillData.triggeredByCospris or actor.mainSkill.skillData.triggeredByCoC or config.triggerName == "Law of the Wilds") and GlobalCache.cachedData["CACHE"][uuid] then
					local sourceCritChance = GlobalCache.cachedData["CACHE"][uuid].CritChance
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
				if not GlobalCache.cachedData["CACHE"][triggeredUUID] then
					calcs.buildActiveSkill(env, "CACHE", actor.mainSkill, {[triggeredUUID] = true})
				end
				local triggeredManaCost = GlobalCache.cachedData["CACHE"][triggeredUUID].Env.player.output.ManaCost or 0
				if triggeredManaCost > 0 then 
					local manaSpentThreshold = triggeredManaCost * actor.mainSkill.skillData.ManaForgedArrowsPercentThreshold
					local sourceManaCost = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.ManaCost or 0
					if sourceManaCost > 0 then
						trigRate = (trigRate * sourceManaCost) / manaSpentThreshold
						if breakdown then
							t_insert(breakdown.EffectiveSourceRate, s_format("* %.2f ^8(Mana cost of trigger source)", sourceManaCost))
							t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Mana spent per second)", (GlobalCache.cachedData["CACHE"][uuid].Env.player.output.Speed * sourceManaCost)))
							t_insert(breakdown.EffectiveSourceRate, s_format(""))
							t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Mana Cost of triggered)", triggeredManaCost))
							t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Manaforged threshold multiplier)", actor.mainSkill.skillData.ManaForgedArrowsPercentThreshold))
							t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Manaforged trigger threshold)", manaSpentThreshold))
							t_insert(breakdown.EffectiveSourceRate, s_format(""))
							t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Mana spent per second)", (GlobalCache.cachedData["CACHE"][uuid].Env.player.output.Speed * sourceManaCost)))
							t_insert(breakdown.EffectiveSourceRate, s_format("/ %.2f ^8(Manaforged trigger threshold)", manaSpentThreshold))
						end
					else
						trigRate = 0
					end
				end
			end
			
			--Trigger chance
			if config.triggerChance and trigRate then
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
			local cooldownOverride = actor.mainSkill.skillModList:Override(actor.mainSkill.skillCfg, "CooldownRecovery")
			local triggerCD = actor.mainSkill.triggeredBy and env.player.mainSkill.triggeredBy.grantedEffect.levels[env.player.mainSkill.triggeredBy.level].cooldown
			triggerCD = triggerCD or source.triggeredBy and source.triggeredBy.grantedEffect.levels[source.triggeredBy.level].cooldown
			local triggeredCD = actor.mainSkill.skillData.cooldown
			
			if actor.mainSkill.skillData.triggeredByBrand then
				triggerCD = actor.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency / actor.mainSkill.triggeredBy.activationFreqMore / actor.mainSkill.triggeredBy.activationFreqInc
				triggerCD = triggerCD * icdr -- cancels out division by icdr lower, brand activation rate is not affected by icdr
			end
			
			local triggeredName = (actor.mainSkill.activeEffect.grantedEffect and actor ~= env.minion and actor.mainSkill.activeEffect.grantedEffect.name) or "Triggered skill"
			output.addsCastTime = processAddedCastTime(env.player.mainSkill, breakdown)
			
			local modActionCooldown = cooldownOverride or m_max((triggeredCD or 0) / icdr + (output.addsCastTime or 0), ((triggerCD or 0) / icdr ))
			
			local rateCapAdjusted = actor.mainSkill.skillData.ignoresTickRate and modActionCooldown or m_ceil(modActionCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
			local extraICDRNeeded = m_ceil((modActionCooldown - rateCapAdjusted + data.misc.ServerTickTime) * icdr * 1000)
			
			if actor.mainSkill.skillData.triggeredByBrand then
				extraICDRNeeded = m_ceil(((triggeredCD or 0) / icdr - rateCapAdjusted + data.misc.ServerTickTime) * icdr * 1000)
			end
			
			local extraCSIncNeeded = nil
			
			if output.addsCastTime then
				local timeAboveLastBreakPoint = modActionCooldown + data.misc.ServerTickTime - rateCapAdjusted
				if rateCapAdjusted > data.misc.ServerTickTime and timeAboveLastBreakPoint < output.addsCastTime then
					extraCSIncNeeded = ((output.addsCastTime / (output.addsCastTime - timeAboveLastBreakPoint)) - 1)*100
				end
				if triggeredCD and rateCapAdjusted > data.misc.ServerTickTime and timeAboveLastBreakPoint < (triggeredCD / icdr) then
					extraICDRNeeded = (((triggeredCD / icdr) / ((triggeredCD / icdr) - timeAboveLastBreakPoint)) - 1)*100
				else
					extraICDRNeeded = nil
				end
			end

			output.TriggerRateCap = source == actor.mainSkill and actor.mainSkill.skillData.triggerRateCapOverride or m_huge
			if rateCapAdjusted ~= 0 then
				output.TriggerRateCap = 1 / rateCapAdjusted
			end
			
			if config.triggerName == "Doom Blast" and env.build.configTab.input["doomBlastSource"] == "expiration" then
				trigRate = 1 / GlobalCache.cachedData["CACHE"][uuid].Env.player.output.Duration
				if breakdown and breakdown.EffectiveSourceRate then
						breakdown.EffectiveSourceRate[1] = s_format("1 / %.2f ^8(source curse duration)", GlobalCache.cachedData["CACHE"][uuid].Env.player.output.Duration)
				end
			end
			
			if breakdown then
				if triggeredCD == nil and triggerCD == nil then
					if source == actor.mainSkill and actor.mainSkill.skillData.triggerRateCapOverride then
						breakdown.TriggerRateCap = {
							s_format("%.2f ^8(Trigger rate cap override of skill)", actor.mainSkill.skillData.triggerRateCapOverride),
							s_format("= %.2f", output.TriggerRateCap),
						}
					else
						breakdown.TriggerRateCap = {
							triggeredName .. " has no base cooldown or cooldown override",
							"",
							config.triggerName .. " has no base cooldown",
							"",
							"Assuming cast on every kill/attack/hit",
						}
						if output.addsCastTime then
							breakdown.TriggerRateCap = {
								triggeredName .. " has no base cooldown",
								s_format("+ %.2f ^8(this skill adds cast time to cooldown when triggered)", output.addsCastTime),
								s_format("= %.4f ^8(final cooldown of %s)", ((triggeredCD or 0) / icdr) + output.addsCastTime or 0, triggeredName),
								"",
								config.triggerName .. " has no base cooldown",
								"",
								s_format("%.3f ^8(biggest of trigger cooldown and triggered skill cooldown)", modActionCooldown),
								"",
								"Trigger rate:",
								s_format("1 / %.3f", rateCapAdjusted),
								s_format("= %.2f ^8per second", output.TriggerRateCap),
							}
						end
						if cooldownOverride ~= nil then
							breakdown.TriggerRateCap[1] = s_format("%.2f ^8(hard override of cooldown of %s)", cooldownOverride, triggeredName)
						end
					end
				elseif cooldownOverride then
					breakdown.TriggerRateCap = {
						s_format("%.2f ^8(hard override of cooldown of %s)", cooldownOverride, triggeredName),
						"",
						(actor.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
						"",
						"Trigger rate:",
						s_format("1 / %.3f", rateCapAdjusted),
						s_format("= %.2f ^8per second", output.TriggerRateCap),
					}
					actor.mainSkill.skillFlags.hasOverride = true
					if actor.mainSkill.skillData.triggeredByBrand then
						breakdown.TriggerRateCap[3] = s_format("%.2f ^8(base activation cooldown of %s)", actor.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency, config.triggerName)
						breakdown.TriggerRateCap[4] = s_format("/ %.2f ^8(more activation frequency)", actor.mainSkill.triggeredBy.activationFreqMore)
						t_insert(breakdown.TriggerRateCap, 4 , s_format("/ %.2f ^8(increased activation frequency)", actor.mainSkill.triggeredBy.activationFreqInc))
					end
				else
					if triggeredCD ~= nil then
						-- minion skills should always have some kind of cooldown
						if actor == env.minion then
							breakdown.TriggerRateCap = {
								s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD),
								s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
								s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCD / icdr),
								"",
								(actor.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
								"",
								"Trigger rate:",
								s_format("1 / %.3f", rateCapAdjusted),
								s_format("= %.2f ^8per second", output.TriggerRateCap),
							}
							if extraICDRNeeded then
								t_insert(breakdown.TriggerRateCap, 6, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
							end
							if extraCSIncNeeded then
								t_insert(breakdown.TriggerRateCap, 6, s_format("^8(extra Cast Rate Increase of %d%% would reach next breakpoint)", extraCSIncNeeded))
							end
						elseif triggerCD then
							breakdown.TriggerRateCap = {
								s_format("%.2f ^8(base cooldown of %s)", triggeredCD, triggeredName),
								s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
								s_format("= %.4f ^8(final cooldown of %s)", ((triggeredCD or 0) / icdr) + (output.addsCastTime or 0), triggeredName),
								"",
								s_format("%.2f ^8(base cooldown of %s)", triggerCD, config.triggerName),
								s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
								s_format("= %.4f ^8(final cooldown of trigger)", triggerCD / icdr),
								"",
								s_format("%.3f ^8(biggest of trigger cooldown and triggered skill cooldown)", modActionCooldown),
								"",
								(actor.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
								"",
								"Trigger rate:",
								s_format("1 / %.3f", rateCapAdjusted),
								s_format("= %.2f ^8per second", output.TriggerRateCap),
							}
							if extraICDRNeeded then
								t_insert(breakdown.TriggerRateCap, 12, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
							end
							if extraCSIncNeeded then
								t_insert(breakdown.TriggerRateCap, 12, s_format("^8(extra Cast Rate Increase of %d%% would reach next breakpoint)", extraCSIncNeeded))
							end
							if actor.mainSkill.skillData.triggeredByBrand then
								breakdown.TriggerRateCap[5] = s_format("%.2f ^8(base activation cooldown of %s)", actor.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency, config.triggerName)
								breakdown.TriggerRateCap[6] = s_format("/ %.2f ^8(more activation frequency)", actor.mainSkill.triggeredBy.activationFreqMore)
								t_insert(breakdown.TriggerRateCap, 6 , s_format("/ %.2f ^8(increased activation frequency)", actor.mainSkill.triggeredBy.activationFreqInc))
							end
							if output.addsCastTime then
								t_insert(breakdown.TriggerRateCap, 3, s_format("+ %.2f ^8(this skill adds cast time to cooldown when triggered)", output.addsCastTime))
							end
						else
							--Self trigger; likely from unique.
							breakdown.TriggerRateCap = {
								s_format("%.2f ^8(base cooldown of %s)", triggeredCD, triggeredName),
								s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
								s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCD / icdr),
								"",
								s_format("Trigger rate based on %s cooldown", triggeredName),
								"",
								(actor.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
								"",
								"Trigger rate:",
								s_format("1 / %.3f", rateCapAdjusted),
								s_format("= %.2f ^8per second", output.TriggerRateCap),
							}
							if extraICDRNeeded then
								t_insert(breakdown.TriggerRateCap, 8, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
							end
							if extraCSIncNeeded then
								t_insert(breakdown.TriggerRateCap, 8, s_format("^8(extra Cast Rate Increase of %d%% would reach next breakpoint)", extraCSIncNeeded))
							end
						end
					else
						breakdown.TriggerRateCap = {
							triggeredName .. " has no base cooldown",
							"",
							s_format("%.2f ^8(base cooldown of %s)", triggerCD, config.triggerName),
							s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
							s_format("= %.4f ^8(final cooldown of trigger)", triggerCD / icdr),
							"",
							s_format("%.3f ^8(biggest of trigger cooldown and triggered skill cooldown)", modActionCooldown),
							"",
							(actor.mainSkill.skillData.ignoresTickRate and "") or s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
							"",
							"Trigger rate:",
							s_format("1 / %.3f", rateCapAdjusted),
							s_format("= %.2f ^8per second", output.TriggerRateCap),
						}
						if extraICDRNeeded and not actor.mainSkill.skillData.triggeredByBrand then
							t_insert(breakdown.TriggerRateCap, 10, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
						end
						if extraCSIncNeeded then
							t_insert(breakdown.TriggerRateCap, 10, s_format("^8(extra Cast Rate Increase of %d%% would reach next breakpoint)", extraCSIncNeeded))
						end
						if actor.mainSkill.skillData.triggeredByBrand then
							breakdown.TriggerRateCap[3] = s_format("%.2f ^8(base activation cooldown of %s)", actor.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency, config.triggerName)
							breakdown.TriggerRateCap[4] = s_format("/ %.2f ^8(more activation frequency)", actor.mainSkill.triggeredBy.activationFreqMore)
							t_insert(breakdown.TriggerRateCap, 4 , s_format("/ %.2f ^8(increased activation frequency)", actor.mainSkill.triggeredBy.activationFreqInc))
						end
						if output.addsCastTime then
							t_insert(breakdown.TriggerRateCap, 2, s_format("+ %.2f ^8(this skill adds cast time to cooldown when triggered)", output.addsCastTime))
							t_insert(breakdown.TriggerRateCap, 3, s_format("= %.4f ^8(final cooldown of %s)", ((triggeredCD or 0) / icdr) + output.addsCastTime or 0, triggeredName))
						end
					end	
				end
			end
<<<<<<< Updated upstream
			
			if trigRate ~= nil and not actor.mainSkill.skillFlags.globalTrigger and not config.ignoreSourceRate then
=======

			if config.triggerName == "Doom Blast" and env.build.configTab.input["doomBlastSource"] == "vixen" then
				local vixens = env.data.skills["SupportUniqueCastCurseOnCurse"]
				local vixensCD = vixens and vixens.levels[1].cooldown / icdr
				output.EffectiveSourceRate = calcMultiSpellRotationImpact(env, {{ uuid = cacheSkillUUID(env.player.mainSkill, env), icdr = icdr}}, trigRate, vixensCD)
				output.VixensTooMuchCastSpeedWarn = vixensCD > (1 / trigRate)
				if breakdown then
					t_insert(breakdown.EffectiveSourceRate, s_format("%.2f / %.2f = %.2f ^8(Vixen's trigger cooldown)", vixensCD * icdr, icdr, vixensCD))
					t_insert(breakdown.EffectiveSourceRate, s_format("%.2f ^8(Simulated trigger rate of a curse socketed in Vixen's given ^7%.2f ^8CD and ^7%.2f ^8source rate)", output.EffectiveSourceRate, vixensCD, trigRate))
				end
			elseif trigRate ~= nil and not actor.mainSkill.skillFlags.globalTrigger and not config.ignoreSourceRate then
>>>>>>> Stashed changes
				output.EffectiveSourceRate = trigRate
			else
				output.EffectiveSourceRate = output.TriggerRateCap
				actor.mainSkill.skillFlags.globalTrigger = true
			end
			
			if breakdown and not actor.mainSkill.skillData.sourceRateIsFinal then
				t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Effective source rate)", output.EffectiveSourceRate))
			end
			
			local skillName = (source and source.activeEffect.grantedEffect.name) or (actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.grantedEffect.name) or actor.mainSkill.activeEffect.grantedEffect.name
			
			--If spell count is missing the skill likely comes from a unique and /or triggers it self
			if output.EffectiveSourceRate ~= 0 then
				if config.triggerName == "Doom Blast" and env.build.configTab.input["doomBlastSource"] == "vixen" then
					local overlaps = m_max(env.player.modDB:Sum("BASE", nil, "Multiplier:CurseOverlaps") or 1, 1)
					output.SkillTriggerRate = m_min(output.TriggerRateCap, output.EffectiveSourceRate * overlaps)
					if breakdown then
						breakdown.SkillTriggerRate = {
							s_format("min(%.2f, %.2f *  %d)", output.TriggerRateCap, output.EffectiveSourceRate, overlaps)
						}
					end
				elseif actor.mainSkill.skillFlags.globalTrigger and not config.triggeredSkillCond then
					output.SkillTriggerRate = output.EffectiveSourceRate
				else
					output.SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, config.triggeredSkillCond and triggeredSkills or {packageSkillDataForSimulation(actor.mainSkill, env)}, output.EffectiveSourceRate, (not actor.mainSkill.skillData.triggeredByBrand and ( triggerCD or triggeredCD ) or 0) / icdr, actor)
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
				actor.mainSkill.skillData.triggerSource = source
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
				return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Claw) > 0 
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
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and not skill.skillTypes[SkillType.Triggered] end}
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
					local cachedSpeed = GlobalCache.cachedData["CACHE"][uuid].Speed
					local cachedManaCost = GlobalCache.cachedData["CACHE"][uuid].ManaCost
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
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByCoC and slotMatch(env, skill) end}
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
		return {triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByDamageTaken and slotMatch(env, skill) end}
	end,
	["cast when stunned"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {triggerChance =  env.player.mainSkill.skillData.triggeredByStunned,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByStunned and slotMatch(env, skill) end}
	end,
	["spellslinger"] = function()
		return {triggerName = "Spellslinger",
				triggerOnUse = true,
				triggerSkillCond = function(env, skill)
					local isWandAttack = (not skill.weaponTypes or (skill.weaponTypes and skill.weaponTypes["Wand"])) and skill.skillTypes[SkillType.Attack]
					return isWandAttack and not skill.skillTypes[SkillType.Triggered] and not skill.skillData.triggeredBySpellSlinger
				end}
	end,
	["mark on hit"] = function()
		return {triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Triggered] end}
	end,
	["hextouch"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Triggered] and slotMatch(env, skill)
				end}
	end,
	["oskarm"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Triggered]
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
			env.player.mainSkill.skillData.ignoresTickRate = true
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
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Attack] end}
	end,
	["shockwave"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] end}
	end,
	["manaforged arrows"] = function(env)
		return {triggerOnUse = true,
				triggerName = "Manaforged Arrows",
				triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["mirage archer"] = function()
		return {customHandler = mirageArcherHandler}
	end,		
	["doom blast"] = function(env)
		env.player.mainSkill.skillData.ignoresTickRate = true
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {useCastRate = true,
				customTriggerName = "Doom Blast triggering Hex: ",
				triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Hex] and slotMatch(env, skill) end}
	end,
	["cast while channelling"] = function()
		return {customHandler = CWCHandler}
	end,
	["focus"] = function()
		return {customHandler = helmetFocusHandler}
	end,
	["reflection"] = function()
		return {customHandler = theSaviourHandler}
	end,
	["tawhoa's chosen"] = function()
		return {customHandler = tawhoaChosenHandler}
	end,
	["snipe"] = function(env)
		local snipeStages = m_min(env.player.modDB:Sum("BASE", nil, "Multiplier:SnipeStage"), env.player.modDB:Sum("BASE", nil, "Multiplier:SnipeStagesMax"))
		local snipeHitMulti = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "snipeHitMulti")
		local snipeAilmentMulti = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "snipeAilmentMulti")
		local triggeredSkills = {}
		local source
		local trigRate
		local uuid
		local currentSkillSnipeIndex
		
		for _, skill in ipairs(env.player.activeSkillList) do
			if skill.skillData.triggeredBySnipe and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot then
				t_insert(triggeredSkills, skill)
			end
		end
	
		for index, skill in ipairs(triggeredSkills) do
			if skill == env.player.mainSkill then 
				currentSkillSnipeIndex = index 
				break
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
				env.player.mainSkill.skillData.baseMultiplier = 0
			end
		else			
			-- Does snipe have enough stages to trigger this skill?
			if currentSkillSnipeIndex and currentSkillSnipeIndex <= snipeStages then
				env.player.mainSkill.skillModList:NewMod("Damage", "MORE", snipeHitMulti * snipeStages , "Snipe", ModFlag.Hit, 0)
				env.player.mainSkill.skillModList:NewMod("Damage", "MORE", snipeAilmentMulti * snipeStages , "Snipe", ModFlag.Ailment, 0)
				for _, skill in ipairs(env.player.activeSkillList) do
					if skill.activeEffect.grantedEffect.name == "Snipe" and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot then
						skill.skillData.hitTimeMultiplier = snipeStages - 0.5
						source, _, uuid = findTriggerSkill(env, skill, source)
						trigRate = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.HitSpeed
						env.player.output.ChannelTimeToTrigger = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.HitTime
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
					local totemLife = GlobalCache.cachedData["CACHE"][uuid].Env.player.output.TotemLife
					return (not source and totemLife) or (totemLife and totemLife > (currentTotemLife or 0))
				end,
				ignoreSourceRate = true}
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

function calcs.triggers(env)
	if not env.player.mainSkill.skillFlags.disable and not env.player.mainSkill.skillData.limitedProcessing then
		local skillName = env.minion and env.minion.mainSkill.activeEffect.grantedEffect.name or env.player.mainSkill.activeEffect.grantedEffect.name
		local triggerName = env.player.mainSkill.triggeredBy and env.player.mainSkill.triggeredBy.grantedEffect.name
		local uniqueName = isTriggered(env.player.mainSkill) and getUniqueItemTriggerName(env.player.mainSkill)
		local skillNameLower = skillName and skillName:lower()
		local triggerNameLower = triggerName and triggerName:lower()
		local awakenedTriggerNameLower = triggerNameLower and triggerNameLower:gsub("^awakened ", "")
		local uniqueNameLower = uniqueName and uniqueName:lower()
		local config = skillNameLower and configTable[skillNameLower] and configTable[skillNameLower](env)
        config = config or triggerNameLower and configTable[triggerNameLower] and configTable[triggerNameLower](env)
        config = config or awakenedTriggerNameLower and configTable[awakenedTriggerNameLower] and configTable[awakenedTriggerNameLower](env)
        config = config or uniqueNameLower and configTable[uniqueNameLower] and configTable[uniqueNameLower](env)
		if config then
		    config.actor = config.actor or env.player
			config.triggerName = config.triggerName or triggerName or uniqueName or skillName
			local triggerHandler = config.customHandler or defaultTriggerHandler
		    triggerHandler(env, config)
		else
			env.player.mainSkill.skillData.triggered = nil
        end
	end
end