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
	local match1 = (env.player.mainSkill.activeEffect.grantedEffect.fromItem or skill.activeEffect.grantedEffect.fromItem) and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot
	local match2 = (not env.player.mainSkill.activeEffect.grantedEffect.fromItem) and skill.socketGroup == env.player.mainSkill.socketGroup
	return (match1 or match2)
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

local function packageSkillDataForSimulation(skill)
	return { uuid = cacheSkillUUID(skill), cd = skill.skillData.cooldown, cdOverride = skill.skillModList:Override(skill.skillCfg, "CooldownRecovery"), addsCastTime = processAddedCastTime(skill), icdr = calcLib.mod(skill.skillModList, skill.skillCfg, "CooldownRecovery")}
end

-- Identify the trigger action skill for trigger conditions, take highest Attack Per Second
local function findTriggerSkill(env, skill, source, triggerRate, comparer)
	local comparer = comparer or function(uuid, source, triggerRate)
		local cachedSpeed = GlobalCache.cachedData["CACHE"][uuid].Speed
		return (not source and cachedSpeed) or (cachedSpeed and cachedSpeed > (triggerRate or 0))
	end
	
	local uuid = cacheSkillUUID(skill)
	if not GlobalCache.cachedData["CACHE"][uuid] or GlobalCache.noCache then
		calcs.buildActiveSkill(env, "CACHE", skill)
	end

	if GlobalCache.cachedData["CACHE"][uuid] and comparer(uuid, source, triggerRate) then
		return skill, GlobalCache.cachedData["CACHE"][uuid].Speed, uuid
	end
	return source, triggerRate, source and cacheSkillUUID(source)
end

-- Calculate the impact other skills and source rate to trigger cooldown alignment have on the trigger rate
-- for more details regarding the implementation see comments of #4599 and #5428
function calcMultiSpellRotationImpact(env, skills, sourceRate, triggerCD, actor)
	local actor = actor or env.player
	local SIM_RESOLUTION = 2
	-- the breaking points are values in attacks per second
	local function quickSim(env, skills, sourceRate)
		local Activation = {}
		function Activation:new(skill)
			a = {skill = skill, deltaTime = 0, time = 0, count = 0}
			setmetatable(a, self)
			self.__index = self
			return a
		end
		function Activation:timeReady()
			-- returns the time when the skill is ready
			return self.time + self.skill.cd
		end
		function Activation:activate()
			-- activate the skill at the given time, update the activation
			self.deltaTime = time - self.time
			self.time = time
			self.count = self.count + 1
		end
		
		local State = {}
		function State:new(skills)
			s = {activations = {}, time = 0, currentActivation = 1}
			for _, skill in ipairs(skills) do
				t_insert(s.activations, Activation:new(skill))
			end
			setmetatable(s, self)
			self.__index = self
			return s
		end
		function State:iter()
			-- iterate over all activations in order
			local idx = self.currentActivation
			local count = #self.activations
			local i = 0
			return function()
				if i < count then
					i = i + 1
					local current = idx
					idx = (idx % count) + 1
					return self.activations[current]
				end
			end
		end
		function State:iterTimeReady()
			-- iterate over all activations and the time at which each skill is ready
			local att = 1/sourceRate
			local timePenalty = self.time + att
			local iter = self:iter()
			return function()
				local activation = iter()
				if activation then
					-- the time until the skill is ready
					local timeReady = activation:timeReady()
					-- wait for the next attack
					timeReady = att * m_ceil(timeReady / att)
					-- wait until the attack rotation is ready
					timeReady = m_max(timeReady, timePenalty)
					return timeReady, activation
				end
			end
		end
		function State:getNearestReady()
			-- Returns the next activation and the time until the skill is ready
			local nearestTime = 0
			local nearestActivation = nil
			for timeReady, activation in self:iterTimeReady() do
				if nearestActivation == nil or timeReady < nearestTime then
					nearestTime = timeReady
					nearestActivation = activation
				end
			end
			return nearestTime, nearestActivation
		end
		function State:activate()
			-- Activates the activation nearest to ready
			time, nearestActivation = self:getNearestReady()
			-- round up time to the next server tick
			time = ceil_b(time, data.misc.ServerTickTime)
			self.time = time
			if nearestActivation then
				nearestActivation:activate(time)
				for i, activation in ipairs(self.activations) do
					if nearestActivation.skill == activation.skill and nearestActivation.deltaTime == activation.deltaTime then
						self.currentActivation = i
						break
					end
				end
			end
			return nearestActivation
		end
		function State:moveNextRound()
			-- Move to the next round of activations.
			local initial_activation = self.activations[self.currentActivation]
			local is_initial = true
			local activationsCount = #self.activations
			while (self:activate() ~= nil) and (is_initial or self.activations[self.currentActivation].skill ~= initial_activation.skill and self.activations[self.currentActivation].deltaTime ~= initial_activation.deltaTime) do
				self.currentActivation = (self.currentActivation % activationsCount) + 1 -- Skips one skill in the rotation.
				is_initial = false
			end
		end
		function State:anyUntriggered()
			for activation in self:iter() do
				if activation.count == 0 then
					return true
				end
			end
			return false
		end
		
		local rates = {}
		local skillCount = #skills
		for i = 1, skillCount, 1 do
			local state = State:new(skills)
			state.currentActivation = i
			local count = SIM_RESOLUTION + 1
			repeat
				state:moveNextRound()
				count = count-1
			until(not (count > 0 or state:anyUntriggered()))
			
			for i = 1, skillCount, 1 do
				local avgRate = state.activations[i].time ~= 0 and (state.activations[i].count / state.activations[i].time) or 0
				rates[i] = (rates[i] or 0) + avgRate
			end
		end		
		for i = 1, skillCount, 1 do
			skills[i].rate = rates[i] / skillCount
		end
	end
	-- breaking point, where the trigger time is only constrained by the attack speed
	-- the region tt0 is a slope
	local tt0_br = 0
	
	-- breaking points, where the cooldown times of some skills are awaited
	local tt1_brs = {}
	local tt1_smallest_br = m_huge
	for _, skill in ipairs(skills) do
		skill.cd = m_max(skill.cdOverride or ((skill.cd or 0) / (skill.icdr or 1) + (skill.addsCastTime or 0)), triggerCD)
		if skill.cd > triggerCD then
			local br = #skills / ceil_b(skill.cd, data.misc.ServerTickTime)
			t_insert(tt1_brs, br)
			tt1_smallest_br = m_min(tt1_smallest_br, br)
		end
	end
	for _, skill in ipairs(skills) do
		-- the breaking point, where the trigger time is only constrained by the cooldown time
		-- before this its its either tt0 or tt1, depending on the skills
		-- after this the trigger time depends on resonance with the attack speed
		tt2_br = #skills / ceil_b(skill.cd, data.misc.ServerTickTime) * .8
		-- the breaking point where the the attack speed is so high, that the affect of resonance is negligible
		tt3_br = #skills / floor_b(skill.cd, data.misc.ServerTickTime) * 8
		-- classify in tt region the attack rate is in
		if sourceRate >= tt3_br then
			skill.rate = 1/ ceil_b(skill.cd, data.misc.ServerTickTime)
		elseif (sourceRate >= tt2_br) or (#tt1_brs > 0 and sourceRate >= tt1_smallest_br) then
			quickSim(env, skills, sourceRate)
			break
		elseif sourceRate >= tt0_br then
			skill.rate = sourceRate / #skills
		else
			skill.rate = 0
		end
	end
	
	local mainRate
	local trigRateTable = { simRes = SIM_RESOLUTION, rates = {}, }
	for _, sd in ipairs(skills) do
		if cacheSkillUUID(actor.mainSkill) == sd.uuid then
			mainRate = sd.rate
		end
		t_insert(trigRateTable.rates, { name = sd.uuid, rate = sd.rate })
	end
	if not mainRate then
		mainRate = trigRateTable.rates[1].rate
	end
	return mainRate, trigRateTable
end

local function mirageArcherHandler(env)
	-- Mirage Archer Support
	-- This creates and populates env.player.mainSkill.mirage table
	if not env.player.mainSkill.skillFlags.minion and not env.player.mainSkill.skillData.limitedProcessing then
		local usedSkill = nil
		local uuid = cacheSkillUUID(env.player.mainSkill)
		local calcMode = env.mode == "CALCS" and "CALCS" or "MAIN"

		-- cache a new copy of this skill that's affected by Mirage Archer
		if avoidCache then
			usedSkill = env.player.mainSkill
		else
			if not GlobalCache.cachedData[calcMode][uuid] then
				calcs.buildActiveSkill(env, calcMode, env.player.mainSkill, {[uuid] = true})
			end

			if GlobalCache.cachedData[calcMode][uuid] and not avoidCache then
				usedSkill = GlobalCache.cachedData[calcMode][uuid].ActiveSkill
			end
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
	if not env.player.mainSkill.skillFlags.minion and not env.player.mainSkill.skillFlags.disable then
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
			local triggered = skill.skillData.triggeredByUnique or skill.skillData.triggered or skill.skillTypes[SkillType.InbuiltTrigger] or skill.skillTypes[SkillType.Triggered]
			local match1 = env.player.mainSkill.activeEffect.grantedEffect.fromItem and skill.socketGroup and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot
			local match2 = (not env.player.mainSkill.activeEffect.grantedEffect.fromItem) and skill.socketGroup == env.player.mainSkill.socketGroup
			if skill.skillTypes[SkillType.Channel] and skill ~= env.player.mainSkill and (match1 or match2) and not triggered then
				source, trigRate = findTriggerSkill(env, skill, source, trigRate)
			end
			if skill.skillData.triggeredWhileChannelling and (match1 or match2) then
				t_insert(triggeredSkills, packageSkillDataForSimulation(skill))
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
						"",
						s_format("Calculated Breakdown ^8(Resolution: %.2f)", simBreakdown.simRes),
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
			env.player.mainSkill.skillData.triggered = true
			env.player.mainSkill.skillFlags.globalTrigger = true
			env.player.mainSkill.skillData.triggerSource = source
			env.player.mainSkill.skillData.triggerRate = output.SkillTriggerRate
			env.player.mainSkill.skillData.triggerSourceUUID = cacheSkillUUID(source, env.mode)
			env.player.mainSkill.infoMessage = triggerName .."'s Trigger: ".. source.activeEffect.grantedEffect.name
			env.player.infoTrigger = env.player.mainSkill.infoTrigger or triggerName
		end
	end
end

local function doomBlastHandler(env)
	if not env.player.mainSkill.skillFlags.minion then --Doom Blast
		local source = nil
		local hexCastRate = 0
		local output = env.player.output
		local breakdown = env.player.breakdown
		for _, skill in ipairs(env.player.activeSkillList) do
			local match1 = env.player.mainSkill.activeEffect.grantedEffect.fromItem and skill.socketGroup.slot == env.player.mainSkill.socketGroup.slot
			local match2 = (not env.player.mainSkill.activeEffect.grantedEffect.fromItem) and skill.socketGroup == env.player.mainSkill.socketGroup
			if skill.skillTypes[SkillType.Hex] and (match1 or match2) then
				source, hexCastRate = findTriggerSkill(env, skill, source, hexCastRate)
			end
		end
		
		if not source then
			env.player.mainSkill.skillData.triggeredWhenHexEnds = nil
			env.player.mainSkill.infoMessage = "No Triggering Hex Found"
			env.player.mainSkill.infoTrigger = ""
		else
			env.player.mainSkill.skillData.triggered = true
			-- Doom Blast stores three uses. If we assume that the spell is triggered again before all three
			-- charges have been restored, we can ignore the rate cap imposed on other skills (there are no breakpoints).
			local triggeredCD = env.player.mainSkill.skillData.cooldown
			local triggerCD = source.skillData.triggeredByCurseOnCurse and source.triggeredBy and source.triggeredBy.grantedEffect.levels[source.triggeredBy.level].cooldown
			local icdr = calcLib.mod(env.player.mainSkill.skillModList, env.player.mainSkill.skillCfg, "CooldownRecovery")
			local modActionCooldown = m_max((triggeredCD or 0) / icdr, ((triggerCD or 0) / icdr ))
			output.TriggerRateCap = 1 / modActionCooldown
			local rateCapAdjusted
			local extraICDRNeeded
			
			if source.skillData.triggeredByCurseOnCurse then
				rateCapAdjusted = m_ceil(modActionCooldown * data.misc.ServerTickRate) / data.misc.ServerTickRate
				extraICDRNeeded = m_ceil((modActionCooldown - rateCapAdjusted + data.misc.ServerTickTime) * icdr * 1000)
				
				if rateCapAdjusted ~= 0 then
					output.TriggerRateCap = 1 / rateCapAdjusted
				end
				if hexCastRate > output.TriggerRateCap then
					hexCastRate = hexCastRate - m_ceil(hexCastRate - output.TriggerRateCap)
				end
			end

			if breakdown then
				if triggerCD then
					breakdown.TriggerRateCap = {
						s_format("%.2f ^8(base cooldown of triggered skill)", triggeredCD),
						s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
						s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCD / icdr),
						"",
						s_format("%.2f ^8(base cooldown of trigger)", triggerCD),
						s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
						s_format("= %.4f ^8(final cooldown of trigger)", triggerCD / icdr),
						"",
						s_format("%.3f ^8(biggest of trigger cooldown and triggered skill cooldown)", modActionCooldown),
						"",
						s_format("%.3f ^8(adjusted for server tick rate)", rateCapAdjusted),
						"",
						"Trigger rate:",
						s_format("1 / %.3f", rateCapAdjusted),
						s_format("= %.2f ^8per second", output.TriggerRateCap),
					}
				else
					breakdown.TriggerRateCap = {
						s_format("%.2f ^8(base cooldown of Doom Blast)", triggeredCD),
						s_format("/ %.2f ^8(increased/reduced cooldown recovery)", icdr),
						s_format("= %.4f ^8(final cooldown of triggered skill)", triggeredCD / icdr),
						"",
						"Trigger rate based on Doom Blast cooldown",
						"",
						"Trigger rate:",
						s_format("1 / %.3f", modActionCooldown),
						s_format("= %.2f ^8per second", 1 / modActionCooldown),
					}
				end
				if extraICDRNeeded then
					t_insert(breakdown.TriggerRateCap, triggerCD and 10 or 8, s_format("^8(extra ICDR of %d%% would reach next breakpoint)", extraICDRNeeded))
				end
			end	
			
			-- Set trigger rate
			local hits_per_cast = env.player.mainSkill.skillPart == 2 and env.player.mainSkill.activeEffect.srcInstance.skillStageCount or 1
			output.EffectiveSourceRate = hexCastRate
			output.SkillTriggerRate = calcMultiSpellRotationImpact(env, {packageSkillDataForSimulation(env.player.mainSkill)}, hexCastRate, 0) * hits_per_cast
			if breakdown then
				breakdown.EffectiveSourceRate = {
					s_format("%.2f ^8(%s casts per second)", hexCastRate, source.activeEffect.grantedEffect.name),
				}
				breakdown.SkillTriggerRate = {
					s_format("%.2f ^8(%s casts per second)", hexCastRate, source.activeEffect.grantedEffect.name),
					s_format("* %.2f ^8(hits per cast from overlaps)", hits_per_cast),
					s_format("= %.2f ^8per second", hexCastRate * hits_per_cast),
				}
			end

			-- Account for Trigger-related INC/MORE modifiers
			addTriggerIncMoreMods(env.player.mainSkill, env.player.mainSkill)
			env.player.mainSkill.skillData.triggerRate = output.SkillTriggerRate
			env.player.mainSkill.skillData.triggerSource = source
			env.player.mainSkill.infoMessage = "Triggering Hex: " .. source.activeEffect.grantedEffect.name
			env.player.mainSkill.infoTrigger = "DoomBlast"
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
			local uuid = cacheSkillUUID(triggerSkill)
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
		local triggered = triggerSkill.skillData.triggeredByUnique or triggerSkill.skillData.triggered or triggerSkill.skillTypes[SkillType.InbuiltTrigger] or triggerSkill.skillTypes[SkillType.Triggered]
		local isDisabled = triggerSkill.skillFlags and triggerSkill.skillFlags.disable
		if triggerSkill ~= env.player.mainSkill and triggerSkill.skillTypes[SkillType.Slam] and triggerSkill.skillTypes[SkillType.Attack] and not triggerSkill.skillTypes[SkillType.Vaal] and not triggered and not isDisabled and not triggerSkill.skillTypes[SkillType.Totem] and not triggerSkill.skillTypes[SkillType.SummonsTotem] then
			-- Grab a fully-processed by calcs.perform() version of the skill that Tawhoa's Chosen will use
			local uuid = cacheSkillUUID(triggerSkill)
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
			SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, {{ uuid = cacheSkillUUID(usedSkill), cd = triggeredCD }}, EffectiveSourceRate, effectiveTriggerCD)
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

local function defualtTriggerHandler(env, config)
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
			local triggered = skill.skillData.triggeredByUnique or skill.skillData.triggered or skill.skillTypes[SkillType.InbuiltTrigger] or skill.skillTypes[SkillType.Triggered]
			if config.triggerSkillCond and config.triggerSkillCond(env, skill) and (not triggered or actor.mainSkill.skillFlags.globalTrigger) and skill ~= actor.mainSkill then
				source, trigRate, uuid = findTriggerSkill(env, skill, source, trigRate, config.comparer)
			end
			if config.triggeredSkillCond and config.triggeredSkillCond(env,skill) then
				t_insert(triggeredSkills, packageSkillDataForSimulation(skill))
			end
		end
	end
	if #triggeredSkills > 0 or not config.triggeredSkillCond then
		if not source and not actor.mainSkill.skillFlags.globalTrigger then
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
			
			actor.mainSkill.skillData.ignoresTickRate = source and source.skillData.storedUses ~= nil
			
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
			if source and (source.skillTypes[SkillType.Melee] or source.skillTypes[SkillType.Attack]) and GlobalCache.cachedData["CACHE"][uuid] and not triggerOnUse then
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
				local triggeredUUID = cacheSkillUUID(actor.mainSkill)
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
			local triggerCD = (actor.mainSkill.triggeredBy and env.player.mainSkill.triggeredBy.grantedEffect.levels[env.player.mainSkill.triggeredBy.level].cooldown)
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
			
			output.TriggerRateCap = m_huge
			if rateCapAdjusted ~= 0 then
				output.TriggerRateCap = 1 / rateCapAdjusted
			end
			
			if breakdown then
				if triggeredCD == nil and triggerCD == nil then
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
			
			if trigRate ~= nil then
				output.EffectiveSourceRate = trigRate
			else
				output.EffectiveSourceRate = data.misc.ServerTickRate / m_ceil( (triggerCD or triggeredCD or 0) / icdr * data.misc.ServerTickRate)
				actor.mainSkill.skillFlags.globalTrigger = true
			end
			
			if breakdown and not actor.mainSkill.skillData.sourceRateIsFinal then
				t_insert(breakdown.EffectiveSourceRate, s_format("= %.2f ^8(Effective source rate)", output.EffectiveSourceRate))
			end
			
			local skillName = (source and source.activeEffect.grantedEffect.name) or (actor.mainSkill.triggeredBy and actor.mainSkill.triggeredBy.grantedEffect.name) or actor.mainSkill.activeEffect.grantedEffect.name
			
			--If spell count is missing the skill likely comes from a unique and /or triggers it self
			if output.EffectiveSourceRate ~= 0 then
				if actor.mainSkill.skillFlags.globalTrigger and not config.triggeredSkillCond then
					output.SkillTriggerRate = output.EffectiveSourceRate
				else
					output.SkillTriggerRate, simBreakdown = calcMultiSpellRotationImpact(env, config.triggeredSkillCond and triggeredSkills or {packageSkillDataForSimulation(actor.mainSkill)}, output.EffectiveSourceRate, (not actor.mainSkill.skillData.triggeredByBrand and ( triggerCD or triggeredCD ) or 0) / icdr, actor)
					local triggerBotsEffective = actor.modDB:Flag(nil, "HaveTriggerBots") and actor.mainSkill.skillTypes[SkillType.Spell]
					if triggerBotsEffective then
						output.SkillTriggerRate = 2 * output.SkillTriggerRate
					end
					if breakdown and (#triggeredSkills > 1 or triggerBotsEffective) then
						breakdown.SkillTriggerRate = {
							s_format("%.2f ^8(%s)", output.EffectiveSourceRate, (actor.mainSkill.skillData.triggeredByBrand and s_format("%s activations per second", source.activeEffect.grantedEffect.name)) or (not trigRate and s_format("%s triggers per second", skillName)) or "Effective source rate"),
							s_format("/ %.2f ^8(Estimated impact of skill rotation and cooldown alignment)", m_max(output.EffectiveSourceRate / output.SkillTriggerRate, 1)),
							s_format("= %.2f ^8per second", output.SkillTriggerRate),
							"",
							s_format("Calculated Breakdown ^8(Resolution: %.2f)", simBreakdown.simRes),
						}
						if triggerBotsEffective then
							t_insert(breakdown.SkillTriggerRate, 3, "x 2 ^8(Trigger bots effectively cause the skill to trigger twice)")
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
				actor.mainSkill.skillData.triggerSourceUUID = cacheSkillUUID(source, env.mode)
				actor.mainSkill.infoMessage = config.triggerName .. ( actor == env.minion and "'s attack Trigger: " or "'s Trigger: ") .. source.activeEffect.grantedEffect.name
			else
				actor.mainSkill.infoMessage = actor.mainSkill.triggeredBy.grantedEffect.name .. " Trigger"
			end
	
			actor.mainSkill.infoTrigger = config.triggerName
		end
	end
end

local configTable = {
	["Law of the Wilds"] = function()
		return {
			triggerSkillCond = function(env, skill)
				return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Claw) > 0 
			end
		}
	end,
	["The Rippling Thoughts"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name == "Storm Cascade" then
			return {
				triggerSkillCond = function(env, skill) 
					return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack])
				end
			}
		end
	end,
	["The Surging Thoughts"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name == "Storm Cascade" then
			return {
				triggerSkillCond = function(env, skill) 
					return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack])
				end
			}
		end
	end,
	["The Hidden Blade"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		if env.player.modDB:Flag(nil, "Condition:Phasing") then
			return {source = env.player.mainSkill}
		end
		env.player.mainSkill.skillFlags.disable = true
		env.player.mainSkill.disableReason = "This skill is requires you to be phasing"
	end,
	["Replica Eternity Shroud"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["Shroud of the Lightless"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["Limbsplit"] = function()
		return {triggerName = "Gore Shockwave", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["The Cauteriser"] = function()
		return {triggerName = "Gore Shockwave", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Duskblight"] = function()
		return {triggerName = "Stalking Pustule", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Lioneye's Paws"] = function(env)
		-- Due to the way the triggerExtraSkill function in mod parser works this trigger does not use the custom trigger skill (RainOfArrowsOnAttackingWithBow)
		-- the normal version is used here instead. The stats are the same but the normal version does not have cooldown.
		env.player.mainSkill.skillData.cooldown = 1
		return {triggerOnUse = true, triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["Replica Lioneye's Paws"] = function(env)
		-- Due to the way the triggerExtraSkill function in mod parser works this trigger does not use the custom trigger skill (RainOfArrowsOnAttackingWithBow)
		-- the normal version is used here instead. The stats are the same but the normal version does not have cooldown.
		env.player.mainSkill.skillData.cooldown = 1
		return {triggerOnUse = true, triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["Moonbender's Wing"] = function()
		return {triggerName = "Lightning Warp", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Ngamahu's Flame"] = function()
		return {triggerName = "Molten Burst", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Melee] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Cameria's Avarice"] = function()
		return {triggerName = "Icicle Burst", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Uul-Netol's Embrace"] = function()
		return {triggerName = "Bone Nova", triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Rigwald's Crest"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Jorrhast's Blacksteel"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Ashcaller"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Arakaali's Fang"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Sporeguard"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Mark of the Elder"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Mark of the Shaper"] = function()
		return {assumingEveryHitKills = true, triggerSkillCond = function(env, skill) return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) end}
	end,
	["Poet's Pen"] = function()
		return {triggerOnUse = true,
				triggerSkillCond = function(env, skill) 
					return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Wand) > 0 
				end,
				triggeredSkillCond = function(env, skill) 
					return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot and skill.skillTypes[SkillType.Spell] 
				end}
	end,
	["Maloney's Mechanism"] = function(env)
		local _, _, uniqueTriggerName = env.player.itemList[env.player.mainSkill.slotName].modSource:find(".*:.*:(.*),.*")
		local isReplica = uniqueTriggerName:match("Replica.")
		return {triggerOnUse = true, triggerName = uniqueTriggerName,
				triggerSkillCond = function(env, skill)
					local attack = skill.skillTypes[SkillType.Attack] and (band(skill.skillCfg.flags, ModFlag.Bow) > 0) and not isReplica
					local spell = skill.skillTypes[SkillType.Spell] and isReplica
					return (attack or spell)
				end,
				triggeredSkillCond = function(env, skill) 
					return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot and skill.skillTypes[SkillType.RangedAttack]
				end}
	end,
	["Asenath's Chant"] = function()
		return {triggerOnUse = true,
				triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, ModFlag.Bow) > 0
				end,
				triggeredSkillCond = function(env, skill) 
					return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot and skill.skillTypes[SkillType.Spell]
				end}
	end,
	["Vixen's Entrapment"] = function()
		return {useCastRate = true,
				triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Hex]
				end}
	end,
	["Flames of Judgement"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerName = env.player.mainSkill.activeEffect.grantedEffect.name,
				triggerSkillCond = function(env, skill) return skill.activeEffect.grantedEffect.name == "Queen's Demand" end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot end}
	end,
	["Storm of Judgement"] = function(env)
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerName = env.player.mainSkill.activeEffect.grantedEffect.name,
				triggerSkillCond = function(env, skill) return skill.activeEffect.grantedEffect.name == "Queen's Demand" end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByUnique and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot end}
	end,
	["Trigger Craft"] = function(env)
		local trigRate, source, uuid, useCastRate, triggeredSkills = {}
		for _, skill in ipairs(env.player.activeSkillList) do
			local triggered = skill.skillData.triggeredByUnique or skill.skillData.triggered or skill.skillTypes[SkillType.InbuiltTrigger] or  skill.skillTypes[SkillType.Triggered]
			if (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack] or skill.skillTypes[SkillType.Spell]) and skill ~= env.player.mainSkill and not skill.skillData.triggeredByCraft and not skill.activeEffect.grantedEffect.fromItem and not triggered then
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
				t_insert(triggeredSkills, packageSkillDataForSimulation(skill))
			end
		end
		return {trigRate = trigRate, source = source, uuid = uuid, useCastRate = useCastRate, triggeredSkills = triggeredSkills}
	end,
	["Kitava's Thirst"] = function(env)
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
	["Mjolner"] = function()
		return {triggerSkillCond = function(env, skill)
					return (skill.skillTypes[SkillType.Damage] or skill.skillTypes[SkillType.Attack]) and band(skill.skillCfg.flags, bor(ModFlag.Mace, ModFlag.Weapon1H)) > 0
				end,
				triggeredSkillCond = function(env, skill)
					return skill.skillData.triggeredByMjolner and  env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot
				end}
	end,
	["Cospri's Malice"] = function()
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Melee] and band(skill.skillCfg.flags, bor(ModFlag.Sword, ModFlag.Weapon1H)) > 0
				end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByCospris and env.player.mainSkill.socketGroup.slot == skill.socketGroup.slot end}
	end,
	["Cast On Critical Strike"] = function()
		return {triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and slotMatch(env, skill) end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByCoC and slotMatch(env, skill) end}
	end,
	["Cast on Melee Kill"] = function(env)
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
	["Cast On Critical Strike"] = function()
		return {triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and slotMatch(env, skill) end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByCoC and slotMatch(env, skill) end}
	end,
	["Nova"] = function(env)
		if env.minion and env.minion.mainSkill then
			return {triggerName = "Summon Holy Relic",
				   actor = env.minion,
				   triggeredSkills = {{ uuid = cacheSkillUUID(env.minion.mainSkill), cd = env.minion.mainSkill.skillData.cooldown}},
				   triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] end}
		end
	end,
	["Cast when Damage Taken"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByDamageTaken and slotMatch(env, skill) end}
	end,
	["Cast when Stunned"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {triggerChance =  env.player.mainSkill.skillData.triggeredByStunned,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByStunned and slotMatch(env, skill) end}
	end,
	["Spellslinger"] = function()
		return {triggerName = "Spellslinger",
				triggerOnUse = true,
				triggerSkillCond = function(env, skill)
					local isWandAttack = (not skill.weaponTypes or (skill.weaponTypes and skill.weaponTypes["Wand"])) and skill.skillTypes[SkillType.Attack]
					return isWandAttack and not skill.skillTypes[SkillType.Triggered] and not skill.skillData.triggeredBySpellSlinger
				end}
	end,
	["Mark On Hit"] = function()
		return {triggerSkillCond = function(env, skill) return skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Triggered] end}
	end,
	["Hextouch"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		env.player.mainSkill.skillData.sourceRateIsFinal = true
		return {triggerSkillCond = function(env, skill)
					return skill.skillTypes[SkillType.Attack] and not skill.skillTypes[SkillType.Triggered] and slotMatch(env, skill)
				end}
	end,
	["Tempest Shield"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["Riposte"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["Reckoning"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		return {source = env.player.mainSkill}
	end,
	["Battlemage's Cry"] = function()
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] end,
				triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByBattleMageCry and slotMatch(env, skill) end}
	end,
	["Arcanist Brand"] = function(env)
		if env.player.mainSkill.activeEffect.grantedEffect.name ~= "Arcanist Brand" then
			env.player.mainSkill.skillData.sourceRateIsFinal = true
			env.player.mainSkill.skillData.ignoresTickRate = true
			for _, skill in ipairs(env.player.activeSkillList) do
				if skill.activeEffect.grantedEffect.name == "Arcanist Brand" then
					env.player.mainSkill.triggeredBy.mainSkill = skill
					break
				end
			end
			
			local activationFreqInc = (100 + env.player.mainSkill.triggeredBy.mainSkill.skillModList:Sum("INC", cfg, "Speed", "BrandActivationFrequency")) / 100
			local activationFreqMore = env.player.mainSkill.triggeredBy.mainSkill.skillModList:More(cfg, "BrandActivationFrequency")
			env.player.mainSkill.triggeredBy.activationFreqInc = activationFreqInc
			env.player.mainSkill.triggeredBy.activationFreqMore = activationFreqMore
			env.player.output.EffectiveSourceRate = trigRate
			return {trigRate = env.player.mainSkill.triggeredBy.mainSkill.skillData.repeatFrequency * activationFreqInc * activationFreqMore,
					source = env.player.mainSkill.triggeredBy.mainSkill,
					triggeredSkillCond = function(env, skill) return skill.skillData.triggeredByBrand and slotMatch(env, skill) end}
		end
	end,
	["Cast on Death"] = function(env)
        env.player.mainSkill.skillFlags.globalTrigger = true
		env.player.mainSkill.skillData.triggered = true
		env.player.mainSkill.infoMessage = env.player.mainSkill.activeEffect.grantedEffect.name .. " Triggered on Death"
	end,
	["Combust"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] end}
	end,
	["Prismatic Burst"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Attack] end}
	end,
	["Shockwave"] = function(env)
		return {triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Melee] end}
	end,
	["Manaforged Arrows"] = function(env)
		return {triggerOnUse = true,
				triggerName = "Manaforged Arrows",
				triggerSkillCond = function(env, skill)	return skill.skillTypes[SkillType.Attack] and band(skill.skillCfg.flags, ModFlag.Bow) > 0 end}
	end,
	["Mirage Archer"] = function()
		return {customHandler = mirageArcherHandler}
	end,
	["Doom Blast"] = function()
		return {customHandler = doomBlastHandler}
	end,
	["Cast while Channelling"] = function()
		return {customHandler = CWCHandler}
	end,
	["Focus"] = function()
		return {customHandler = helmetFocusHandler}
	end,
	["Mirage Archer"] = function()
		return {customHandler = mirageArcherHandler}
	end,
	["Reflection"] = function()
		return {customHandler = theSaviourHandler}
	end,
	["Tawhoa's Chosen"] = function()
		return {customHandler = tawhoaChosenHandler}
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

local function logNoHandler(skillName, triggerName, uniqueName)
	local message = s_format("WARNING: no handler for: %s, %s, %s ", skillName, triggerName, uniqueName)
	return function() 
				ConPrintf(message) 
			end
end

function calcs.triggers(env)
	if not env.player.mainSkill.skillFlags.disable and not env.player.mainSkill.skillData.limitedProcessing then
		local skillName = env.minion and env.minion.mainSkill.activeEffect.grantedEffect.name or env.player.mainSkill.activeEffect.grantedEffect.name
		local triggerName = env.player.mainSkill.triggeredBy and env.player.mainSkill.triggeredBy.grantedEffect.name
		local uniqueName = getUniqueItemTriggerName(env.player.mainSkill)
		local config = (configTable[skillName] or triggerName and (configTable[triggerName] or configTable[triggerName:gsub("^Awakened ", "")]) or configTable[uniqueName] or logNoHandler(skillName, triggerName, uniqueName))(env)
        if config then
		    config.actor = config.actor or env.player
			config.triggerName = config.triggerName or triggerName or uniqueName or skillName
			local triggerHandler = config.customHandler or defualtTriggerHandler
		    triggerHandler(env, config)
		else
			env.player.mainSkill.skillData.triggered = nil
        end
	end
end