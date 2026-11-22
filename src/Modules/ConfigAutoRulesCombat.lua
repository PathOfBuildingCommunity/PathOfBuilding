-- Path of Building
--
-- Combat-event rules for Auto-configure. One table per rule family, all
-- derived from the neutral calculation: recent events, charge and stack
-- mechanics, cast timelines, timed buildup, skill windows, Stuns, resource
-- snapshots, source-backed history and whole-event stacks. Every value is an
-- explicit combat assumption, never a recording of live combat. Depends on
-- ConfigAutoModel.
local t_insert = table.insert

local M = { }
local model = require("Modules.ConfigAutoModel")
local policy = model.Policy
local canActivate, isDirect, useRate, personal = model.CanActivate, model.IsDirect, model.UseRate, model.Personal

local Events = { capabilities = { }, neutralInputs = { } }
local Mechanics = { capabilities = { }, neutralInputs = { } }
local Timeline = { capabilities = { }, neutralInputs = { } }
local Buildup = { capabilities = { }, neutralInputs = { } }
local Windows = { capabilities = { }, neutralInputs = { }, exclusive = { } }
local Stuns, Resources, History, Stacks = model.Registry(), model.Registry(), model.Registry(), model.Registry()
M.Events, M.Mechanics, M.Timeline, M.Buildup, M.Windows = Events, Mechanics, Timeline, Buildup, Windows
M.Stuns, M.Resources, M.History, M.Stacks = Stuns, Resources, History, Stacks

-- Rule text lives at the end of the file: capability methods, split
-- condition/confirmation rules and the static reasons.
local rules, reasons

-- Registry rules are declared next to their evaluators and registered with
-- their text at the end of the file, in declaration order.
local pending = { }
local function define(registry, var, mode, kind, evaluate)
	t_insert(pending, { registry = registry, var = var, model = mode, kind = kind, evaluate = evaluate })
end

-- Shared adapters. Rules that receive facts use facts.Active(), facts.Probe()
-- and facts.Stats() instead; these serve the Detect(context) families.
-- The scanner's probeSkill caches one probe per skill.
local function probeEnv(context, skill)
	if skill == context.mainSkill then return context.env end
	return context.probeSkill(skill) or nil
end
local function probeOutput(context, skill)
	local env = probeEnv(context, skill)
	return env and env.player.output
end
local function skillStats(skill) return calcLib.buildSkillInstanceStats(skill.activeEffect, skill.activeEffect.grantedEffect) end
local function effectStats(effect) return calcLib.buildSkillInstanceStats(effect, effect.grantedEffect) end
local function countLabel(context, var, amount) return StripEscapes(context.options[var].label):gsub(":$", "") .. ": " .. amount end
-- Activation time of a skill at the player's action speed.
local function activationTime(castTime, actionSpeedMod) return (castTime or 0) / math.min(1, math.max(0.01, actionSpeedMod or 1)) end
-- Call of Steel's native constant stats and activation time. PoB ignores the
-- 'Grants Call of Steel' line and never creates the hidden actor; its skill
-- definition still proves availability and timing.
local function callOfSteel(actionSpeedMod)
	local stats = { }
	for _, stat in ipairs(data.skills.CallOfSteel.constantStats) do stats[stat[1]] = stat[2] end
	return stats, activationTime(data.skills.CallOfSteel.castTime, actionSpeedMod)
end

-- ============================================================================
-- Events: estimates of recent combat events
-- ============================================================================
-- The activation adapters live on the shared model; keep the historical names.
Events.CanActivate, Events.IsDirect, Events.UseRate = canActivate, isDirect, useRate

local countNames = {
	multiplierSkillUsedRecently = "Main-skill activations", multiplierCritRecently = "Attack critical strikes",
	multiplierIgniteAppliedRecently = "Ignites applied", multiplierPoisonAppliedRecently = "Poisons applied",
	multiplierMineDetonatedRecently = "Mines detonated", multiplierTrapTriggeredRecently = "Traps triggered",
	multiplierWarcryUsedRecently = "Warcries used", multiplierCorpseConsumedRecently = "Corpses consumed",
	BlockedPast10Sec = "Blocks in the past ten seconds", multiplierHitsSuppressedRecently = "Spell hits suppressed recently",
}

function Events.Detect(context)
	local env, emit = context.env, context.suggest
	local main, output = context.mainSkill, context.env.player.output
	local seconds = policy.FightSeconds(context)
	local window = math.min(seconds, policy.recentWindow)
	local enabledMain = model.SkillEnabled(main)
	local mainName = main.activeEffect.grantedEffect.name
	local ownHit = enabledMain and context.selfHit
	local hits = policy.HitRate(context, output)
	local function count(var, rate, reason, review, cap, recentWindow)
		local window = math.min(seconds, recentWindow or policy.recentWindow)
		local expected = math.max(0, rate or 0) * window
		if expected <= 0 then return end
		local amount, belowOne
		amount, review, belowOne = model.Count(expected, review)
		if cap then amount = math.min(cap, amount) end
		local assumption = {
			rule = "event-count", rate = rate, window = window, expected = expected,
			description = string.format("About %.2f events in %.1f seconds.", expected, window),
		}
		if belowOne then
			assumption.description = assumption.description .. " Confirm at least one happens."
		else
			assumption.description = assumption.description .. " The expected event count is rounded down."
		end
		assumption.automatic = not review
		emit(var, reason, review, (countNames[var] or "Recent events") .. ": " .. amount, amount, nil, assumption)
	end
	local function event(var, rate, reason, label, recentWindow, review)
		if (rate or 0) <= 0 then return end
		local assumption = policy.Rate(context.settings, rate, math.min(seconds, recentWindow or 4))
		emit(var, reason, review or not assumption.automatic, label, nil, nil, assumption)
	end
	local active = model.ActiveSkills(env)
	local incoming = policy.Incoming(context.settings, output, env.configInput.enemyDamageType)
	-- The counters follow the same sensitivity decision as the recent block and
	-- suppression checkboxes.
	local function belowThreshold(chance, threshold, rate, recentWindow)
		return not policy.Chance(context.settings, chance, threshold, "", math.min(seconds, recentWindow or policy.recentWindow), rate).automatic
	end
	count("BlockedPast10Sec", incoming.blockRate,
		string.format("%g incoming hits/s (%s) give %.3f blocks/s.", context.settings.incomingHitRate, incoming.category, incoming.blockRate),
		belowThreshold(math.max(incoming.attackBlockChance, incoming.spellBlockChance), context.settings.blockThreshold, incoming.blockRate, 10), nil, 10)
	count("multiplierHitsSuppressedRecently", incoming.suppressionRate,
		string.format("%g incoming hits/s (%s) give %.3f suppressions/s.", context.settings.incomingHitRate, incoming.category, incoming.suppressionRate),
		belowThreshold(output.EffectiveSpellSuppressionChance or output.SpellSuppressionChance or 0, context.settings.suppressionThreshold,
			incoming.suppressionRate))

	if enabledMain then
		for _, resource in ipairs({ "Mana", "Life" }) do
			local netRate = math.max(0, output[resource .. "PerSecondCost"] or 0) * policy.Activity(context, output)
			local spentRate = netRate
			if resource == "Mana" and (output.ManaCost or 0) > 0
				and main.skillModList:Flag(main.skillCfg, "Every2UseManaCostRefund") then spentRate = spentRate * 2 end
			local pool = output[resource .. "Unreserved"] or output[resource] or 0
			local recovery = math.max(0, output[resource .. "RegenRecovery"] or 0)
				+ math.max(0, output[resource .. "LeechGainRate"] or 0)
			local sustainable = netRate * window <= pool + recovery * window
			local amount = math.floor(spentRate * window + 1e-8)
			-- A zero estimate is a correction of a stale manual value, never an
			-- automatic overwrite: the main skill may simply not pay this resource.
			local review = not sustainable or amount <= 0 or main.skillFlags.totem or main.skillFlags.permanentMinion or false
			local assumption = policy.Scenario("Main-skill use over a " .. window .. "-second window.")
			local reason = mainName .. ": " .. string.format("%.2f", netRate) .. " " .. resource:lower() .. "/s spent."
			if not sustainable then
				reason = reason .. "\nYour pool and recovery may not sustain this; confirm the amount."
			end
			if amount <= 0 then
				reason = reason .. "\nYour main skill spends no " .. resource:lower() .. "."
			end
			assumption.automatic = not review
			emit("multiplier" .. resource .. "SpentRecently", reason, review, "Estimated " .. resource:lower() .. " spent: " .. amount, amount, nil, assumption)
		end
	end

	local mainUses = useRate(context, main, output)
	local activity = policy.Activity(context, output)
	if activity > 0 and canActivate(main) then
		if mainUses > 0 then
			event("conditionUsedSkillRecently", mainUses,
				"Main skill: " .. mainName .. ".", "Recent use of your main skill")
		end
		if main.skillTypes[SkillType.Channel] or main.skillTypes[SkillType.Vaal] then
			local review = activity < 1 or main.skillTypes[SkillType.Vaal] or seconds > 4
			emit("multiplierSkillUsedRecently",
				"Main skill: " .. mainName .. ". Only the first activation counts.", review,
				"One recent activation of " .. mainName, 1, nil,
				policy.Scenario("The main skill was started recently."))
		else
			count("multiplierSkillUsedRecently", mainUses,
				"Main skill: " .. mainName .. ".",
				main.skillFlags.permanentMinion)
		end
	end
	local distinct, distinctNames, distinctReview = { }, { }, false
	for _, skill in ipairs(active) do
		if isDirect(skill) and skill.skillTypes[SkillType.Spell] and not skill.skillTypes[SkillType.Instant] then
			local used = skill == main and activity > 0
			if skill ~= main and skill.skillTypes[SkillType.Travel] then
				local out = probeOutput(context, skill)
				used = out and policy.SkillUse(out.Cooldown or out.Time).automatic
			end
			local id = skill.activeEffect.grantedEffect.id
			if used and not distinct[id] then
				distinct[id] = true
				t_insert(distinctNames, skill.activeEffect.grantedEffect.name)
				distinctReview = distinctReview or skill == main and activity < 1 or skill.skillFlags.permanentMinion or skill.skillTypes[SkillType.Vaal]
					or (skill.skillTypes[SkillType.Channel] and seconds > 4) or false
			end
		end
	end
	if #distinctNames > 0 then
		emit("multiplierNonInstantSpellCastRecently", "Non-instant spells you cast: " .. table.concat(distinctNames, ", ") .. ".", distinctReview,
			"Different non-instant spells recently: " .. #distinctNames, #distinctNames, nil,
			policy.Scenario("You cast these spells during combat."))
	end

	if ownHit then
		local reason = "Your hits with " .. mainName .. "."
		if main.skillFlags.attack then count("multiplierCritRecently", hits * (output.CritChance or 0) / 100, reason) end
		local elementalCount, elementalNames, elementalReview = 0, { }, false
		for _, name in ipairs({ "Ignite", "Poison", "Bleed" }) do
			local rate = model.AilmentRate(env, output, hits, name)
			if rate > 0 then
				if name == "Poison" and not main.skillModList:Flag(main.skillCfg, "CannotMultiplePoison") then
					rate = rate * (1 + math.min(1, main.skillModList:Sum("BASE", main.skillCfg, "AdditionalPoisonChance") / 100)
						+ main.skillModList:Sum("BASE", main.skillCfg, "AdditionalPoisonStacks"))
				end
				if name == "Bleed" then
					event("conditionCausedBleedingRecently", rate, reason, "Recently caused Bleeding")
				else
					local limited = name == "Poison" and main.skillModList:Min(main.skillCfg, "PoisonStackLimit") ~= nil
					count("multiplier" .. name .. "AppliedRecently", rate,
						reason .. " Counts new applications, not active stacks.", limited)
				end
				if name == "Ignite" and policy.Rate(context.settings, rate, window).automatic then
					elementalCount = elementalCount + 1
					t_insert(elementalNames, name)
				end
			end
		end
		for _, name in ipairs({ "Chill", "Shock", "Scorch", "Brittle", "Sap", "Freeze" }) do
			local rate = model.AilmentRate(env, output, hits, name)
			if rate > 0 and policy.Rate(context.settings, rate, window).automatic then
				elementalCount = elementalCount + 1; t_insert(elementalNames, name)
				elementalReview = elementalReview or (output[name .. "EstimateUsesCrit"] or 0) > 0
			end
		end
		if elementalCount > 0 then
			emit("multiplierAppliedAilmentsRecently",
				"Elemental ailments you apply often: " .. table.concat(elementalNames, ", ") .. ".", elementalReview,
				"Different elemental ailments recently: " .. elementalCount, elementalCount, nil,
				policy.Scenario("You keep hitting with your main skill."))
		end
		if main.skillFlags.impale then
			local crit = (output.CritChance or 0) / 100
			local chance = (output.ImpaleChance or 0) * (1 - crit) + (output.ImpaleChanceOnCrit or output.ImpaleChance or 0) * crit
			event("conditionImpaledRecently", hits * chance / 100, reason, "Recently Impaled an enemy")
		end
	end

	if canActivate(main) and (main.skillFlags.trap or main.skillFlags.mine) and not (main.skillFlags.trap and main.skillFlags.mine) then
		local mine = main.skillFlags.mine
		local amount = output[mine and "MineThrowCount" or "TrapThrowCount"] or 1
		local reason = "Main " .. (mine and "mine" or "trap") .. " skill: " .. mainName .. ", " .. amount .. " per throw."
		event("conditionThrownTrapOrMineRecently", mainUses, reason, "Recently threw your main traps/mines")
		count(mine and "multiplierMineDetonatedRecently" or "multiplierTrapTriggeredRecently", mainUses * amount, reason)
	end
	if enabledMain and main.skillFlags.totem and main.skillFlags.spell and main.skillFlags.hit then
		event("conditionTotemsHitSpellRecently", hits,
			"Main spell totem: " .. mainName .. ".", "Recent spell hits by your totem")
	end

	local warcryRate, warcryNames, warcryIds = 0, { }, { }
	local creators, consumers = { }, { }
	local hasOtherMinion = false
	for _, skill in ipairs(active) do
		if skill.minion and skill ~= main then hasOtherMinion = true end
		local fraction = skill == main and activity or 1
		if fraction > 0 and isDirect(skill) then
			local name, id = skill.activeEffect.grantedEffect.name, skill.activeEffect.grantedEffect.id
			if skill.skillTypes[SkillType.Warcry] and not warcryIds[id] then
				warcryIds[id] = true
				local out = probeOutput(context, skill)
				if out and (out.Cooldown or 0) > 0 then warcryRate = warcryRate + fraction / out.Cooldown; t_insert(warcryNames, name) end
			end
			if skill.skillTypes[SkillType.AppliesCurse] or skill.skillTypes[SkillType.Mark] then
				local out = probeOutput(context, skill)
				local interval = out and (out.Cooldown or out.Duration or out.Time)
				local assumption = policy.SkillUse(interval, fraction)
				if skill == main and fraction == 1 then
					assumption.automatic = true
					assumption.description = assumption.description .. " Used continuously."
				end
				local review = not assumption.automatic
				if not model.SelfOnlyCurse(context.build, skill) then
					emit("conditionCursedEnemyRecently", "Enabled self-cast curse: " .. name .. ".", review, "Recently cursed with " .. name, nil, nil,
						assumption)
				end
				if skill.skillTypes[SkillType.Mark] then
					emit("conditionCastMarkRecently", "Enabled self-cast mark: " .. name .. ".", review, "Recently cast " .. name, nil, nil, assumption)
				end
			end
			if skill.skillTypes[SkillType.CreatesCorpse] then t_insert(creators, skill) end
			if skill.skillTypes[SkillType.DestroysCorpse] or skill.skillTypes[SkillType.Offering]
				or id:match("^DetonateDead") or id:match("^VolatileDead") or id:match("^Cremation") then t_insert(consumers, skill) end
			if skill.skillTypes[SkillType.Guard] and not skill.skillTypes[SkillType.Vaal] then
				local out = probeOutput(context, skill)
				if out and (out.Duration or 0) > 0 and (out.Cooldown or 0) > 0 then
					local interval = out.Duration + out.Cooldown
					local assumption = policy.SkillUse(interval, fraction)
					emit("LostNonVaalBuffRecently", "Enabled guard: " .. name .. ". Models expiry, then cooldown.", not assumption.automatic,
						"Recently lost " .. name .. " after expiry", nil, nil, assumption)
				end
			end
		end
	end
	if warcryRate > 0 then
		local reason = "Warcries used on cooldown: " .. table.concat(warcryNames, ", ") .. "."
		local assumption = policy.SkillUse(1 / warcryRate)
		assumption.window = 8
		assumption.automatic = 1 / warcryRate <= math.min(seconds, 8) + 1 / data.misc.ServerTickRate
		assumption.description = assumption.description .. " Window: 8 seconds."
		emit("conditionUsedWarcryInPast8Seconds", reason, not assumption.automatic, "Used an enabled warcry in the past eight seconds", nil, nil, assumption)
		count("multiplierWarcryUsedRecently", warcryRate, reason, false, 100)
	end

	local bestCorpseRate, corpseReason, mainCreator = 0, nil, false
	for _, creator in ipairs(creators) do
		local createdOutput = probeOutput(context, creator)
		if createdOutput then
			local createdRate = useRate(context, creator, createdOutput)
			local perCreate = (skillStats(creator).desecrate_number_of_corpses_to_create or 1) * math.max(1, createdOutput.Repeats or 1)
			if creator == main then
				mainCreator = true
				event("conditionSpawnedCorpseRecently", createdRate, "Main corpse creator: " .. mainName .. ".",
					"Recently created corpses with your main skill")
			end
			for _, consumer in ipairs(consumers) do
				local out = probeOutput(context, consumer)
				local consumedRate = out and useRate(context, consumer, out) or 0
				if createdRate > 0 and consumedRate > 0 then
					local perConsume = (skillStats(consumer).volatile_dead_base_number_of_corpses_to_consume or 1) * math.max(1, out.Repeats or 1)
					local rate = perConsume / (1 / consumedRate + perConsume / perCreate / createdRate)
					local reason = creator.activeEffect.grantedEffect.name .. " creates " .. perCreate .. " corpses; "
						.. consumer.activeEffect.grantedEffect.name .. " consumes " .. perConsume .. "."
					local review = consumer ~= main
					event("conditionConsumedCorpseRecently", rate, reason, "Recently consumed generated corpses", 4, review)
					event("conditionConsumedCorpseInPast2Sec", rate, reason, "Consumed generated corpses in the past two seconds", 2, review)
					if not review and rate > bestCorpseRate then bestCorpseRate, corpseReason = rate, reason end
					if not mainCreator then
						emit("conditionSpawnedCorpseRecently", reason, review, "Recently generated corpses for your main skill", nil, nil,
							policy.Scenario("Your corpse skill feeds your main skill."))
					end
				end
			end
		end
	end
	if bestCorpseRate > 0 then count("multiplierCorpseConsumedRecently", bestCorpseRate, corpseReason) end

	if enabledMain and main.minion and not main.skillFlags.permanentMinion then
		event("minionsConditionCreatedRecently", mainUses,
			"Main temporary minion: " .. mainName .. ".",
			"Recently created your temporary main minions", 4, hasOtherMinion)
		if (output.Duration or 0) > 0 and seconds >= output.Duration then
			event("conditionMinionsDiedRecently", mainUses, "Main temporary minion: " .. mainName .. ". Its "
				.. string.format("%.2f", output.Duration) .. "s lifetime ends in the fight (expiry).",
				"Recent deaths from temporary minion expiry")
		end
	end
	for _, item in ipairs(model.ActiveFlasks(env)) do
		local base = item.baseName and item.baseName:match("^(%a+) Flask$")
		if base == "Amethyst" or base == "Ruby" or base == "Sapphire" or base == "Topaz" then
			emit("conditionUsed" .. base .. "FlaskRecently",
				"Active flask: " .. item.name .. " (" .. item.baseName .. ").", false,
				"Recently used your active " .. base .. " Flask", nil, nil,
				policy.Scenario("You keep this flask active."))
		end
	end
end

-- ============================================================================
-- Mechanics: source-specific charge, buff and stack models
-- ============================================================================
-- Shared with cooldown-bypass profiles: capacity and minimum charges are not
-- spendable generation. Keep actor, chance and loss checks in one place.
function Mechanics.ChargeGeneration(context)
	local main, out = context.mainSkill, context.env.player.output
	local rates, reasons, losses, lossesAtMaximum = { Power = 0, Frenzy = 0, Endurance = 0 }, { Power = { }, Frenzy = { }, Endurance = { } }, { }, { }
	local names = { power = "Power", frenzy = "Frenzy", endurance = "Endurance" }
	local hits = context.selfHit and model.SkillEnabled(main) and policy.HitRate(context, out) or 0
	local ownDamage = model.OwnDamage(main, out)
	local function add(charge, rate, reason)
		if rates[charge] and rate > 0 then rates[charge] = rates[charge] + rate; t_insert(reasons[charge], reason) end
	end
	for _, line in ipairs(context.lines) do
		local text = model.NormalizeLine(line.text)
		local chance, charge, trigger = text:match("^([%d%.]+)%% chance to gain an? (%a+) charge (.+)$")
		if not charge then charge, trigger = text:match("^gain an? (%a+) charge (.+)$"); chance = charge and 100 end
		local name = names[charge]
		if name and tonumber(chance) > 0 then
			local rate = trigger == "on hit" and hits or trigger == "on critical strike" and hits * (out.CritChance or 0) / 100
				or trigger == "on kill" and ownDamage and policy.KillRate(context, "player") or 0
			local probability = math.min(100, tonumber(chance)) / 100
			add(name, rate * probability, line.source .. "\n" .. line.text)
		end
		for _, name in pairs(names) do
			if text:find("lose", 1, true) and text:find(name:lower() .. " charge", 1, true) then losses[name] = true end
			if text == "lose all " .. name:lower() .. " charges on reaching maximum " .. name:lower() .. " charges" then lossesAtMaximum[name] = true end
		end
	end
	if hits > 0 then
		if main.activeEffect.grantedEffect.id == "Frenzy" then add("Frenzy", hits, "Main Frenzy grants a Frenzy Charge on a successful hit.") end
		local intrinsic = skillStats(main)
		for _, name in ipairs({ "Power", "Frenzy", "Endurance" }) do
			add(name, hits * math.min(100, intrinsic["add_" .. name:lower() .. "_charge_on_skill_hit_%"] or 0) / 100,
				"The actual main skill's native on-hit " .. name .. " Charge generation, including its quality.")
		end
		for _, effect in ipairs(main.effectList) do
			if effect.grantedEffect.id == "SupportPowerChargeOnCritical" then
				add("Power", hits * (out.CritChance or 0) / 100 * math.min(100, effectStats(effect)["add_power_charge_on_critical_strike_%"] or 0) / 100,
					"Compatible Power Charge on Critical on the main player's skill.")
			end
		end
	end
	-- Several lines can contribute to one chance stat. Never count more than
	-- one generated charge of each type per hit plus one per personal kill.
	for name, rate in pairs(rates) do rates[name] = math.min(rate, hits + (ownDamage and policy.KillRate(context, "player") or 0)) end
	-- Enduring Cry grants one Endurance Charge per X Warcry Power on each
	-- self-used activation; the native power of the selected target decides.
	local bursts = { }
	for _, skill in ipairs(model.ActiveSkills(context.env)) do
		local per = isDirect(skill) and skillStats(skill).endurance_charge_granted_per_X_monster_power_during_endurance_warcry
		local probe = per and per > 0 and probeOutput(context, skill)
		local amount = probe and math.floor((out.WarcryPower or 0) / per) or 0
		if amount > 0 and (probe.Cooldown or 0) > 0 then
			local name = skill.activeEffect.grantedEffect.name
			local fraction = skill == main and policy.Activity(context, out) or 1
			local use = policy.SkillUse(probe.Cooldown, fraction)
			if use.cooldown and (not bursts.Endurance or amount / use.cooldown > bursts.Endurance.perEvent * bursts.Endurance.rate) then
				bursts.Endurance = { rate = 1 / use.cooldown, perEvent = amount, first = probe.WarcryCastTime or skill.activeEffect.grantedEffect.castTime,
					assumption = use,
					reason = string.format("%s grants %d Endurance Charges per use (%g Warcry Power); %.2fs between uses.", name, amount,
						out.WarcryPower, use.cooldown) }
			end
		end
	end
	return rates, reasons, losses, lossesAtMaximum, bursts
end

function Mechanics.Detect(context)
	local env, main, emit = context.env, context.mainSkill, context.suggest
	local out, db = env.player.output, env.player.modDB
	local cfg, skillMods = main.skillCfg, main.skillModList
	local seconds, hits = policy.FightSeconds(context), policy.HitRate(context, env.player.output)
	local ownHit = context.selfHit and model.SkillEnabled(main)
	local function weaponFits(pattern)
		local used = false
		for index = 1, 2 do
			if main.skillFlags["weapon" .. index .. "Attack"] then
				local weapon = env.player["weaponData" .. index]
				if not weapon or not tostring(weapon.type):lower():match(pattern) then return false end
				used = true
			end
		end
		return used
	end
	local active = model.ActiveSkills(env)
	local function stacks(var, amount, reason, review, requires)
		if amount <= 0 or not context.options[var] then return end
		local belowOne
		amount, review, belowOne = model.Count(amount, review)
		if belowOne then reason = reason .. "\nLess than one stack is expected; confirm it." end
		emit(var, reason, review, countLabel(context, var, amount),
			amount, requires, policy.Scenario("The source keeps applying during the fight."))
	end
	local chargeRates, chargeReasons, losses, lossesAtMaximum, chargeBursts = Mechanics.ChargeGeneration(context)
	local rageHitAmount, rageCritAmount, rageHitInterval, corrosionChance = 0, 0, 0.5, 0
	local rageReasons = { }
	for _, line in ipairs(context.lines) do
		local text = model.NormalizeLine(line.text)
		local reason = line.source .. "\n" .. line.text
		local rage, qualifier, interval = text:match("^gain (%d+) rage on (.-), no more than once every ([%d%.]+) seconds?$")
		if not rage then rage, qualifier = text:match("^gain (%d+) rage on (.-)$") end
		if rage and ownHit and main.skillFlags.attack then
			local critical = qualifier == "critical strike with attacks"
			local valid = qualifier == "attack hit" or qualifier == "hit with attacks"
				or qualifier == "melee hit" and main.skillTypes[SkillType.Melee]
				or qualifier == "melee weapon hit" and main.skillTypes[SkillType.Melee] and not db:GetCondition("Unarmed")
				or qualifier == "hit with axes or swords" and (weaponFits("axe") or weaponFits("sword"))
				or qualifier == "hit with axes" and weaponFits("axe")
			if valid or critical then
				if critical then rageCritAmount = rageCritAmount + tonumber(rage) else rageHitAmount = rageHitAmount + tonumber(rage) end
				rageHitInterval = math.max(rageHitInterval, tonumber(interval) or 0.5); t_insert(rageReasons, reason)
			end
		end
		corrosionChance = corrosionChance + (tonumber(text:match("^([%d%.]+)%% chance to inflict corrosion on hit with attacks$")) or 0)
	end
	for _, charge in ipairs(policy.chargeTypes) do
		local cap = out[charge .. "ChargesMax"] or 0
		local minimum = math.min(cap, math.max(out[charge .. "ChargesMin"] or 0, out[charge .. "Charges"] or 0))
		local rate = chargeRates[charge]
		local duration = out[charge .. "ChargesDuration"] or 0
		local converted = charge == "Power" and db:Flag(nil, "PowerChargesConvertToAbsorptionCharges")
			or charge == "Frenzy" and db:Flag(nil, "FrenzyChargesConvertToAfflictionCharges")
			or charge == "Endurance" and db:Flag(nil, "EnduranceChargesConvertToBrutalCharges")
		local id = main.activeEffect.grantedEffect.id
		local consumedCharge = (main.activeEffect.grantedEffect.description or ""):match("bypassed by expending an? (%a+) Charge")
		local consumes = not not (losses[charge] or id:match("^Discharge") or consumedCharge == charge)
		local retainedCap = lossesAtMaximum[charge] and math.max(minimum, cap - 1) or cap
		-- Gaining a charge refreshes the duration of every charge of that type,
		-- so generation faster than the duration keeps building for the whole
		-- window; slower generation retains at most one charge at a time.
		local generated = model.StackCount(seconds, { rate = rate, duration = duration, refresh = true, cap = math.max(0, retainedCap - minimum) }) or 0
		local burst = chargeBursts[charge]
		if burst then
			generated = generated + (model.StackCount(seconds, { rate = burst.rate, perEvent = burst.perEvent, first = burst.first, duration = duration,
				refresh = true, cap = math.max(0, retainedCap - minimum) }) or 0)
		end
		local amount = math.min(retainedCap, minimum + generated)
		if retainedCap > 0 and (minimum > 0 or rate > 0 or burst) then
			local generation = policy.Rate(context.settings, rate, seconds)
			if burst and not generation.automatic then generation = burst.assumption end
			local review = amount < 1 or consumes or (minimum < amount and not generation.automatic)
			amount = math.max(1, amount)
			if burst then t_insert(chargeReasons[charge], burst.reason) end
			local reason = table.concat(chargeReasons[charge], "\n")
				.. string.format("\nMinimum/maximum: %g/%g; generation %.2f/s; duration %gs; fight time %gs.", minimum, cap, rate, duration, seconds)
			if minimum > 0 then reason = reason .. "\nYour minimum gives " .. minimum .. " charges." end
			if lossesAtMaximum[charge] then reason = reason .. "\nYou lose these charges at maximum." end
			local assumption = (amount > minimum and (rate > 0 or burst)) and generation
				or policy.Scenario("Applied together with the charge setting.")
			if assumption == generation then
				assumption.description = assumption.description .. " Applied together with the charge setting."
			end
			assumption.applyTogether = { "override" .. charge .. "Charges" }
			assumption.chargeCount = { kind = charge, value = amount }
			emit("use" .. charge .. "Charges", reason, review, "Use an estimated " .. amount .. " " .. charge .. " Charges", nil, nil, assumption)
			emit("override" .. charge .. "Charges", reason, false, charge .. " Charges: " .. amount, amount, { "use" .. charge .. "Charges" }, assumption)
		elseif cap > 0 and retainedCap == 0 and rate > 0 then
			emit("use" .. charge .. "Charges",
				"You lose all " .. charge .. " Charges on reaching the maximum of one.", false,
				"Do not retain " .. charge .. " Charges after the forced loss", false)
		end
		if not converted and cap > minimum and rate > 0 and charge ~= "Endurance" then
			local assumption = policy.Rate(context.settings, rate, math.min(4, seconds))
			emit("conditionGained" .. charge .. "ChargeRecently", table.concat(chargeReasons[charge], "\n"), not assumption.automatic,
				"Recently generated " .. charge .. " Charges", nil, nil, assumption)
		end
	end

	local rageRegen = math.max(0, db:Sum("BASE", nil, "RageRegen") * calcLib.mod(db, nil, "RageRegen"))
	if rageRegen > 0 then t_insert(rageReasons, string.format("Calculated Rage regeneration: %.2f/s.", rageRegen)) end
	local crit = math.max(0, math.min(1, (out.CritChance or 0) / 100))
	local rageHitRate = rageHitAmount > 0 and hits or hits * crit
	local ragePerHit = rageHitAmount + rageCritAmount * (rageHitAmount > 0 and crit or 1)
	local rageRate = rageRegen + ragePerHit * math.min(rageHitRate, 1 / rageHitInterval)
	local spendingRage = (out.RagePerSecondCost or 0) > 0 or main.activeEffect.grantedEffect.id:match("^RageVortex") ~= nil
	for _, skill in ipairs(active) do
		if skill.activeEffect.grantedEffect.name == "Berserk" then spendingRage = true end
	end
	local rageCap = out.MaximumRage or 0
	local rageMinimum = math.min(rageCap, db:Sum("BASE", nil, "MinimumRage"))
	if rageCap > 0 and (rageRate > 0 or rageMinimum > 0) then
		local amount = math.min(rageCap, rageMinimum + rageRate * seconds)
		local delay = out.InherentRageLossDelay or 2
		local frequent = rageRegen > 0 or ragePerHit > 0 and math.min(rageHitRate, 1 / rageHitInterval) * delay >= 1
		local review = spendingRage or (out.InherentRageLoss or 10) > 0 and rageRate > 0 and not frequent
		stacks("multiplierRage", amount,
			table.concat(rageReasons, "\n")
				.. string.format("\nGeneration %.2f Rage/s for %gs; minimum %g, maximum %g; once per %.2fs on hit.", rageRate, seconds,
					rageMinimum, rageCap, rageHitInterval), review)
	end

	if ownHit then
		if (out.BleedDPS or 0) > 0 and (out.BleedStacks or 0) > 0 and (out.BleedDuration or 0) > 0 then
			stacks("multiplierBleedsOnEnemy",
				math.min(out.BleedStacksMax or 1, out.BleedStacks * math.min(1, seconds / out.BleedDuration) * policy.Activity(context, out, "hit")),
				"Active Bleeds with Crimson Dance.")
		end
		if skillMods:Flag(cfg, "Condition:CanInflictRupture") and (out.BleedDPS or 0) > 0 then
			local bleedOnCrit = out.BleedChanceOnCrit
			if bleedOnCrit == nil then
				local total, hands = 0, 0
				for _, hand in ipairs({ "MainHand", "OffHand" }) do
					if out[hand] and out[hand].BleedChanceOnCrit then total = total + out[hand].BleedChanceOnCrit; hands = hands + 1 end
				end
				bleedOnCrit = hands > 0 and total / hands or out.BleedChance or 0
			end
			stacks("multiplierRuptureStacks", math.min(4, hits * (out.CritChance or 0) / 100 * bleedOnCrit / 100 * math.min(seconds, 3)),
				"Rupture from critical hits that cause Bleeding.")
		end
		if main.skillFlags.attack and corrosionChance > 0 then
			local rate = hits * math.min(100, corrosionChance) / 100
			local sustained = policy.Rate(context.settings, rate, math.min(seconds, 4)).automatic
			stacks("multiplierCorrosionStackCount", rate * math.min(seconds, sustained and seconds or 4),
				"Corrosion on hit: " .. corrosionChance .. "% chance.",
				not sustained)
		end
		for _, ailment in ipairs({ "Shock", "Scorch" }) do
			local rate = model.AilmentRate(env, out, hits, ailment)
			local cap = skillMods:Override(cfg, ailment .. "StacksMax") or skillMods:Sum("BASE", cfg, ailment .. "StacksMax")
			if rate > 0 and skillMods:Flag(cfg, ailment .. "CanStack") and cap > 0 then
				stacks(ailment .. "Stacks", math.min(cap, rate * math.min(seconds, out[ailment .. "Duration"] or 0)),
					"Stacking " .. ailment .. " from your hits, up to " .. cap .. ".", (out[ailment .. "EstimateUsesCrit"] or 0) > 0,
					{ "conditionEnemy" .. (ailment == "Shock" and "Shocked" or "Scorched") })
			end
		end
	end
	local conditions, count, review = { }, 0, false
	for _, var in ipairs({ "conditionEnemyFrozen", "conditionEnemyShocked", "conditionEnemyIgnited" }) do
		local proposal = context.found[var]
		if proposal and proposal.value then t_insert(conditions, var); count = count + 1; review = review or proposal.review end
	end
	if count > 0 then
		stacks("multiplierFreezeShockIgniteOnEnemy", count, "Freeze, Shock and Ignite you apply, once each.", review, conditions)
	end

	for _, skill in ipairs(active) do
		local name = skill.activeEffect.grantedEffect.name
		for _, effect in ipairs(skill.effectList) do
			if effect.grantedEffect.id == "SupportTriggerSpellFromHelmet" then
				emit("conditionFocused",
					"Helmet Focus trigger: " .. name .. ".", true,
					"Include the Focus window for your helmet trigger?", nil, nil,
					policy.Scenario("You use Focus to trigger the spell."))
			end
		end
		if skill.activeEffect.grantedEffect.id == "AspectOfTheSpider" then
			local interval = (skillStats(skill).spider_aspect_web_interval_ms or 0) / 1000
			local cap = skill.skillModList:Sum("BASE", skill.skillCfg, "Multiplier:SpiderWebApplyStackMax")
			local result = probeOutput(context, skill)
			if interval > 0 and cap > 0 and result then
				stacks("aspectOfTheSpiderWebStacks", math.min(cap, math.min(seconds, result.Duration or 0) / interval),
					"Aspect of the Spider: a web every " .. interval .. "s, up to " .. cap .. ".")
			end
		end
		if name == "Focus" then
			emit("conditionFocused", "Your Focus skill.", true,
				"Include the Focus buff window?", nil, nil, policy.Scenario("You use Focus for this window."))
		end
		if skill.skillTypes[SkillType.Vaal] and isDirect(skill) then
			local result = probeOutput(context, skill)
			local duration = result and result.SoulGainPreventionDuration or 0
			if duration > 0 then emit("conditionSoulGainPrevention",
				"Vaal skill: " .. name .. "; Soul Gain Prevention " .. string.format("%.2f", duration) .. "s.",
				skill ~= main or seconds > duration,
				"Soul Gain Prevention after using " .. name, nil, nil,
				policy.Scenario("You use the Vaal skill at the start.")) end
		end
	end
	if ownHit and isDirect(main) then
		for _, effect in ipairs(main.effectList) do
			if effect.grantedEffect.id == "SupportMomentum" then
				local maximum = skillMods:Sum("BASE", cfg, "MomentumStacksMax")
				local rate = main.skillTypes[SkillType.Channel]
					and 1000 * policy.Activity(context, out) / math.max(1, effectStats(effect).support_momentum_stack_while_channelling_base_ms or 1000)
					or useRate(context, main, out)
				stacks("MomentumSwiftnessStacks", math.min(maximum, rate * seconds), "Momentum support. Confirm you move to gain Swiftness.", true)
			end
		end
	end
	for _, ailment in ipairs({ { "Ash", "Ignite" }, { "Frost", "Freeze" } }) do
		local kind, trigger = ailment[1], ailment[2]
		local var = "conditionEnemyCoveredIn" .. kind
		-- PoB already applies an independent source and caps the effect at 20%,
		-- so the checkbox would change nothing: report it as derived instead.
		local independent = db:Sum("BASE", nil, "CoveredIn" .. kind .. "Effect") > 0
		if independent and context.derived and not context.derived[var] then
			context.derived[var] = "PoB already applies Covered in " .. kind .. " from your gear."
		end
		for _, line in ipairs(independent and { } or context.lines) do
			local text = model.NormalizeLine(line.text)
			local slot, rest = text:match("^(%a+) ring slot: (.+)$")
			local slotMatches = not slot or slot == "left" and line.source:match("^Ring 1:") or slot == "right" and line.source:match("^Ring 2:")
			text = rest or text
			local duration = tonumber(text:match("^cover enemies in " .. kind:lower() .. " for ([%d%.]+) seconds when you "
				.. (trigger == "Ignite" and "ignite" or "freeze") .. " them$"))
			local rate = ownHit and model.AilmentRate(env, out, hits, trigger) or 0
			if slotMatches and duration and rate > 0 then
				local assumption = policy.Refresh(context.settings, rate, duration, seconds)
				emit(var, line.source .. "\n" .. line.text, not assumption.automatic,
					"Cover the enemy in " .. kind .. " with your " .. trigger:lower() .. " hits", nil, nil, assumption)
			end
		end
	end
	local actor = policy.MainKillActor(env)
	local actorKills = policy.KillRate(context, actor)
	if actorKills > 0 then
		local countVar = actor == "minion" and "multiplierMinionsKilledRecently" or actor == "totem" and "multiplierTotemsKilledRecently"
			or "multiplierKilledRecently"
		local reason = string.format("Mapping: %.2f kills/s (%s).", actorKills, actor)
		stacks(countVar, actorKills * math.min(seconds, 4), reason)
		local rampage = false
		for _, line in ipairs(context.lines) do if model.NormalizeLine(line.text) == "rampage" then rampage = true end end
		if rampage and actorKills * seconds >= 15 then
			stacks("multiplierRampage", math.min(1000, actorKills * seconds),
				reason .. "\nRampage from your gear; the kill streak reaches 15.")
		end
	end
end

-- ============================================================================
-- Timeline: source-backed combat windows
-- ============================================================================
function Timeline.Detect(context)
	local env, main, emit = context.env, context.mainSkill, context.suggest
	local out, seconds = env.player.output, policy.FightSeconds(context)
	local enabled = model.SkillEnabled(main)
	local name = main.activeEffect.grantedEffect.name
	local function value(var, amount, reason, review, assumption)
		amount = math.floor(amount + 1e-8)
		if context.options[var] and amount > 0 then
			emit(var, reason, review or false, countLabel(context, var, amount), amount, nil, assumption)
		end
	end
	local activity = policy.Activity(context, out)
	if activity > 0 and isDirect(main) then
		local channel = main.skillTypes[SkillType.Channel]
		if channel then
			value("multiplierChannelling", seconds * activity, "Main channel: " .. name .. ".", activity < 1,
				policy.Scenario("You channel for " .. seconds * activity .. " seconds without stopping."))
		end
		if main.skillTypes[SkillType.Spell] then
			local rate = useRate(context, main, out)
			local oneCast = channel or main.skillTypes[SkillType.Vaal]
			local reason = "Main self-cast spell: " .. name .. "."
			if oneCast then
				local review = activity < 1 or main.skillTypes[SkillType.Vaal] or seconds > 1
				emit("conditionCastLast1Seconds", reason .. " Only the first activation counts.", review,
					"Cast " .. name .. " within the last second", nil, nil,
					policy.Scenario(seconds <= 1 and "You cast the spell at the start." or "Confirm a new cast in the last second."))
			elseif rate > 0 then
				local assumption = policy.Rate(context.settings, rate, math.min(1, seconds))
				emit("conditionCastLast1Seconds", reason, not assumption.automatic or main.skillFlags.permanentMinion,
					"Recently cast " .. name .. " within one second", nil, nil, assumption)
			end
			if not main.skillTypes[SkillType.Instant] then
				if oneCast then
					value("multiplierCastLast8Seconds", 1,
						reason .. " Counts one activation.",
						activity < 1 or main.skillTypes[SkillType.Vaal] or seconds > 8,
						policy.Scenario("One cast in the last 8 seconds."))
				elseif rate > 0 then
					local window = math.min(seconds, 8)
					local expected = rate * window
					value("multiplierCastLast8Seconds", math.max(1, expected),
						reason .. string.format("\n%.2f casts/s for %.1fs.", rate, window),
						main.skillFlags.permanentMinion or expected < 1,
						policy.Scenario("You keep casting the main spell."))
				end
			end
		end
	end
	local vaal, vaalNames = { }, { }
	for _, skill in ipairs(env.player.activeSkillList) do
		if isDirect(skill) and (skill ~= main or activity > 0) then
			local id, sourceName = skill.activeEffect.grantedEffect.id, skill.activeEffect.grantedEffect.name
			if skill.skillTypes[SkillType.Vaal] and not vaal[id] then
				vaal[id] = true; t_insert(vaalNames, sourceName)
			end
			if skill.skillTypes[SkillType.Golem] then
				for _, window in ipairs({ 8, 10 }) do
					emit("conditionSummonedGolemInPast" .. window .. "Sec",
						"Golem skill: " .. sourceName .. ".", true,
						"Resummon " .. sourceName .. " within the last " .. window .. " seconds?", nil, nil,
						policy.Scenario("You resummon this golem in this window."))
				end
			end
			if id == "ArcaneCloak" then
				local result = probeOutput(context, skill)
				local fraction = skill.skillModList:Sum("BASE", skill.skillCfg, "Multiplier:ArcaneCloakConsumedMana")
				if result and (result.ManaUnreserved or 0) > 0 and fraction > 0 then
					emit("arcaneCloakUsedRecentlyCheck", "Arcane Cloak spends " .. string.format("%.1f", fraction * 100) .. "% of current mana.", true,
						"Include a recent Arcane Cloak use at full mana?", nil, nil,
						policy.Scenario("You use Arcane Cloak at full mana in the last 4 seconds."))
				end
			end
		end
	end
	if #vaalNames > 0 then
		value("multiplierUsedVaalSkillInPast8Seconds", #vaalNames, "Vaal skills, one use each: " .. table.concat(vaalNames, ", ") .. ".", true,
			policy.Scenario("You use each Vaal skill once in the last 8 seconds."))
	end
	if enabled and ((out.TotalDPS or 0) + (out.TotalDotDPS or out.TotalDot or 0)) > 0 then
		value("enemyMultiplierEnemyPresenceSeconds", seconds,
			"Fight time with the enemy in your presence.", true,
			policy.Scenario("The enemy stays in your presence the whole fight."))
	end
	local kills = policy.KillRate(context, "player")
	if not model.OwnDamage(main, out) or kills <= 0 then return end
	local reason = "Regular kills: " .. kills .. " kill/s with " .. name .. "."
	local function killEvent(var, detail, review, window)
		local assumption = policy.Rate(context.settings, kills, math.min(seconds, window or 4))
		emit(var, reason .. "\n" .. detail, review or not assumption.automatic, StripEscapes(context.options[var].label), nil, nil, assumption)
	end
	killEvent("conditionKilledLast3Seconds", "Uses this setting's three-second window.", false, 3)
	local ownHit = context.selfHit and enabled
	local hits = ownHit and policy.HitRate(context, out) or 0
	local function applying(name) return model.AilmentRate(env, out, hits, name) end
	local poison = applying("Poison")
	if poison > 0 then
		killEvent("conditionKilledPoisonedLast2Seconds", "Your hits Poison enemies before they die.",
			not policy.Refresh(context.settings, poison, out.PoisonDuration or 0, seconds).automatic, 2)
	end
	local dotReview, hasDot = true, false
	if (out.TotalDot or 0) > 0 and not main.skillFlags.hit then hasDot, dotReview = true, false end
	for _, ailment in ipairs({ "Poison", "Ignite", "Bleed" }) do
		local rate = applying(ailment)
		if rate > 0 then
			hasDot = true
			if policy.Refresh(context.settings, rate, out[ailment .. "Duration"] or 0, seconds).automatic then dotReview = false end
		end
	end
	if hasDot then
		killEvent("conditionKilledAffectedByDoT", "Your damage over time affects enemies before they die.", dotReview)
	end
	local freeze = applying("Freeze")
	if freeze > 0 then
		killEvent("conditionShatteredEnemyRecently", "Your hits Freeze enemies before they die.",
			not policy.Rate(context.settings, freeze, math.min(seconds, 4)).automatic)
	end
	local shock = applying("Shock")
	if shock > 0 then
		local window = math.min(seconds, 4)
		local expected = math.min(kills, shock) * window
		local review = expected < 1 or not policy.Refresh(context.settings, shock, out.ShockDuration or 0, seconds).automatic
			or (out.ShockEstimateUsesCrit or 0) > 0
		local assumption = policy.Scenario(reasons.shockedEnemies)
		for _, var in ipairs({ "multiplierShockedEnemyKilledRecently", "multiplierShockedNonShockedEnemyRecently" }) do
			value(var, math.max(1, expected),
				reason .. "\nYour hits Shock; counts enemies, not hits.", review, assumption)
		end
	end
end

-- ============================================================================
-- Buildup: timed buildup from actual generators
-- ============================================================================
-- Numeric constants come from the local Gathering Winds reminder, Barkskin
-- stat description and ConfigOptions limits, not guessed uptime.
function Buildup.Detect(context)
	local env, main, emit = context.env, context.mainSkill, context.suggest
	local out, db, seconds = env.player.output, env.player.modDB, policy.FightSeconds(context)
	local active, lines = model.ActiveSkills(env), { }
	for _, line in ipairs(context.lines) do
		-- Passives may combine several modifiers into one multiline stat.
		for text in (StripEscapes(line.text) .. "\n"):gmatch("([^\n]+)\n") do
			t_insert(lines, { text = model.NormalizeLine(text), source = line.source .. "\n" .. text })
		end
	end
	local function number(var, amount, reason, review, requires, assumption)
		if not context.options[var] or amount < 0 then return end
		amount = math.floor(amount + 1e-8)
		emit(var, reason, review or false, countLabel(context, var, amount), amount, requires,
			assumption
				or policy.Scenario("Buildup from your source over the fight."))
	end
	local ownDamage = model.OwnDamage(main, out)
	local killRate = ownDamage and policy.KillRate(context, "player") or 0
	local infusionInterval, galeGain, spiritRate, spiritLoss, spiritConsumer = nil, 0, 0, false, false
	local infusionReasons, galeReasons, spiritReasons = { }, { }, { }
	local galeLoss, fragileGain, fragileDecay, fragileCap, fragileHitGain, fragileHitLoss = false, 0, 0, nil, false, false
	local fragileReasons, warcryValour, valourReasons = { }, 0, { }
	for _, line in ipairs(lines) do
		local text = line.text
		local interval = tonumber(text:match("^gain spirit infusion every ([%d%.]+) seconds? while channelling a spell$"))
		if text == "gain spirit infusion every second while channelling a spell" then interval = 1 end
		if interval and interval > 0 then infusionInterval = math.min(infusionInterval or interval, interval); t_insert(infusionReasons, line.source) end
		local gain = tonumber(text:match("^gain (%d+) gale force when you use a skill$"))
		if gain then galeGain = math.max(galeGain, gain); t_insert(galeReasons, line.source) end
		if text == "lose all gale force when hit" then galeLoss = true; t_insert(galeReasons, line.source) end
		local spiritInterval = tonumber(text:match("^gain a spirit charge every ([%d%.]+) seconds?$"))
		if text == "gain a spirit charge every second" then spiritInterval = 1 end
		if spiritInterval and spiritInterval > 0 then spiritRate = spiritRate + 1 / spiritInterval; t_insert(spiritReasons, line.source) end
		local chance = tonumber(text:match("^([%d%.]+)%% chance to gain a spirit charge on kill$"))
		if text == "gain a spirit charge on kill" then chance = 100 end
		if chance and chance > 0 and killRate > 0 then
			spiritRate = spiritRate + math.min(100, chance) / 100 * killRate
			t_insert(spiritReasons, line.source)
		end
		if text == "you lose all spirit charges when taking a savage hit" then spiritLoss = true; t_insert(spiritReasons, line.source) end
		if text:match("^trigger level %d+ spirit burst when you use a skill while you have a spirit charge$") then
			spiritConsumer = true
			t_insert(spiritReasons, line.source)
		end
		local maximum = tonumber(text:match("^maximum (%d+) fragile regrowth$"))
		if maximum then fragileCap = math.min(fragileCap or maximum, maximum, 10); t_insert(fragileReasons, line.source) end
		local gainRate = tonumber(text:match("^gain (%d+) fragile regrowth each second$"))
		if gainRate then fragileGain = fragileGain + gainRate; t_insert(fragileReasons, line.source) end
		local decayRate = tonumber(text:match("^lose (%d+) fragile regrowth each second$"))
		if decayRate then fragileDecay = fragileDecay + decayRate; t_insert(fragileReasons, line.source) end
		if text == "lose all fragile regrowth when hit" then fragileHitLoss = true; t_insert(fragileReasons, line.source) end
		if text == "gain up to maximum fragile regrowth when hit" then fragileHitGain = true; t_insert(fragileReasons, line.source) end
		local valour = tonumber(text:match("^gain (%d+) valour when you warcry, if able$")) or 0
		if valour > 0 then warcryValour = warcryValour + valour; t_insert(valourReasons, line.source) end
	end
	local activity = policy.Activity(context, out)
	if infusionInterval and activity > 0 and db:Flag(nil, "Condition:CanGainSpiritInfusion") and isDirect(main) and main.skillTypes[SkillType.Channel]
		and main.skillTypes[SkillType.Spell] then
		local maximum = out.SpiritInfusionsMax or 0
		if maximum > 0 then
			number("overrideSpiritInfusion", math.min(maximum, seconds * activity / infusionInterval),
				table.concat(infusionReasons, "\n")
					.. string.format("\nOne Infusion per %gs while channelling, %gs elapsed, maximum %g.", infusionInterval, seconds * activity, maximum),
				activity < 1)
		end
	end
	if galeGain > 0 and activity > 0 and db:Flag(nil, "Condition:CanGainGaleForce") and canActivate(main) then
		local oneUse = main.skillTypes[SkillType.Channel] or main.skillTypes[SkillType.Vaal]
		local expected = oneUse and (seconds <= 4 and 1 or 0) or useRate(context, main, out) * math.min(seconds, 4)
		local amount = math.min(10, galeGain * math.floor(expected + 1e-8))
		local review = galeLoss or main.skillFlags.permanentMinion or main.skillTypes[SkillType.Vaal] or oneUse and activity < 1 or false
		if expected > 0 and expected < 1 then amount, review = math.min(10, galeGain), true end
		number("multiplierGaleForce", amount, table.concat(galeReasons, "\n") .. "\nEach gain lasts 4 seconds; maximum 10.", review)
	end
	if spiritRate > 0 and (out.SpiritChargesMax or 0) > 0 then
		for _, skill in ipairs(active) do if skill.activeEffect.grantedEffect.id == "SpiritBurst" then spiritConsumer = true end end
		local expected = spiritRate * seconds
		local amount = math.min(out.SpiritChargesMax, math.floor(expected + 1e-8))
		local review = spiritLoss or expected < 1 or false
		local reason = table.concat(spiritReasons, "\n")
			.. string.format("\n%.2f Spirit Charges/s for %gs; maximum %g.", spiritRate, seconds, out.SpiritChargesMax)
		if expected < 1 then amount = 1; reason = reason .. "\nLess than one charge is expected; confirm it." end
		if spiritConsumer and canActivate(main) then
			amount, review = 1, true
			reason = reason .. "\nSpirit Burst spends charges, so only one is offered."
		end
		number("overrideSpiritCharges", amount, reason, review)
	end
	if fragileCap and fragileCap > 0 and not (fragileHitLoss and fragileHitGain) then
		if fragileGain > 0 and not fragileHitGain then
			number("multiplierFragileRegrowth", math.min(fragileCap, math.max(0, fragileGain - fragileDecay) * seconds),
				table.concat(fragileReasons, "\n") .. "\nBuildup from zero; confirm you are not hit.",
				true)
		elseif fragileHitGain and fragileDecay > 0 and fragileGain == 0 then
			number("multiplierFragileRegrowth", math.max(0, fragileCap - math.floor(fragileDecay * seconds + 1e-8)),
				table.concat(fragileReasons, "\n") .. "\nA hit at the start fills the stacks, then they decay.",
				true)
		end
	end
	local banners = { }
	for _, skill in ipairs(active) do
		local id = skill.activeEffect.grantedEffect.id
		local stats = skillStats(skill)
		if id == "Barkskin" then
			local maximum = stats.max_barkskin_stacks or 0
			-- "Gain 2 Bark each second if you haven't been Hit by an Enemy Attack
			-- Recently": the gain runs for the whole attack-free window. Whether
			-- the fight started attack-free is unknown, so this stays a review row.
			if maximum > 0 then number("barkskinStacks", math.min(maximum, math.floor(2 * seconds + 1e-8)), reasons.barkskinStacks, true) end
		elseif id == "AspectOfSolaris" or id == "AspectOfLunaris" then
			local result = probeOutput(context, skill)
			local duration = result and result.Duration or 0
			if duration > 0 then
				if id == "AspectOfSolaris" then
					local interval = (stats.solaris_aspect_debuff_interval_ms or 0) / 1000
					if interval > 0 then
						number("aspectOfSolarisSunscaldStacks", math.min(5, math.min(seconds, duration) / interval),
							string.format("Aspect of Solaris: one Sunscald per %gs, duration %gs, cap 5.", interval, duration),
							true)
					end
				else
					for _, entry in ipairs({ { "aspectOfLunarisLunarProtection", "Physical" }, { "aspectOfLunarisLunarResistance", "Elemental" } }) do
						number(entry[1], math.min(8, context.settings.incomingDamageEventRate * math.min(seconds, duration)),
							string.format("Aspect of Lunaris: %gs duration, cap 8; %g %s damage events/s.", duration,
								context.settings.incomingDamageEventRate, entry[2]),
							true)
					end
				end
			end
		end
		if id == "DreadBanner" or id == "WarBanner" or id == "DefianceBanner" then t_insert(banners, skill) end
	end
	if #banners > 0 then
		local baseRate = 0
		if ownDamage and isDirect(main) and main.skillTypes[SkillType.Melee] then
			local hits = context.selfHit and env.enemy.modDB:GetCondition("RareOrUnique") and policy.HitRate(context, out) or 0
			baseRate = math.min(2, math.max(hits, killRate))
		end
		local extra, extraAmount, warcryIds = 0, 0, { }
		if warcryValour > 0 then
			for _, skill in ipairs(active) do
				local id = skill.activeEffect.grantedEffect.id
				if isDirect(skill) and skill.skillTypes[SkillType.Warcry] and not warcryIds[id] then
					warcryIds[id] = true
					local result = probeOutput(context, skill)
					if result and (result.Cooldown or 0) > 0 and policy.Activity(context, result) > 0 then
						local usesPerSecond = policy.Activity(context, result) / result.Cooldown
						extra = extra + warcryValour * usesPerSecond
						local uses = math.max(1, math.floor(seconds * usesPerSecond + 1e-8))
						extraAmount = extraAmount + uses * warcryValour
						t_insert(valourReasons, skill.activeEffect.grantedEffect.name .. ": " .. uses .. " use(s), " .. warcryValour .. " Valour each.")
					end
				end
			end
		end
		local expected = baseRate * seconds + extraAmount
		local maximum = db:Sum("BASE", nil, "MaximumValour")
		if expected > 0 and maximum > 0 then
			local assumption = policy.Scenario("Build Valour, then plant the Banner and stay in its area.")
			assumption.valourGeneration = { rate = baseRate, maximum = maximum }
			number("bannerValour", math.min(maximum, math.max(1, expected)), string.format("Banner: %.2f Valour/s from melee, %.2f/s from Warcries; "
				.. "%gs buildup, maximum %g.", baseRate, extra, seconds, maximum)
				.. (extra > 0 and ("\n" .. table.concat(valourReasons, "\n")) or ""), true, { "bannerPlanted" }, assumption)
		end
	end
end

-- ============================================================================
-- Windows: skill windows from actual enabled sources
-- ============================================================================
-- A selectable combat window is distinct from observing the current buff
-- phase or stored resource. Aspect phases are mutually exclusive choices.
local aspects = {
	AspectOfTheAvian = { { "aspectOfTheAvianAviansMight", "Avian's Might" }, { "aspectOfTheAvianAviansFlight", "Avian's Flight" } },
	AspectOfTheCat = { { "aspectOfTheCatCatsStealth", "Cat's Stealth" }, { "aspectOfTheCatCatsAgility", "Cat's Agility" } },
}
for _, pair in pairs(aspects) do
	for index, phase in ipairs(pair) do Windows.exclusive[phase[1]] = pair[3 - index][1] end
end

function Windows.Detect(context)
	local env, main, emit = context.env, context.mainSkill, context.suggest
	local seconds, active = policy.FightSeconds(context), model.ActiveSkills(env)
	local function number(var, count, reason, review)
		count = math.floor(count + 1e-8)
		if count <= 0 then return end
		emit(var, reason, review, countLabel(context, var, count), count, nil,
			policy.Scenario("You use this skill window during the fight."))
	end
	local stanceSwitch, plague, ownPoison = false, false, false
	for _, skill in ipairs(active) do
		local id = skill.activeEffect.grantedEffect.id
		if id == "BloodAndSand" or id == "FleshAndStone" then stanceSwitch = true end
		if id == "PlagueBearer" and isDirect(skill) then plague = true end
	end
	for _, skill in ipairs(plague and active or { }) do
		if not skill.minion and not skill.skillFlags.totem and not skill.skillFlags.trap and not skill.skillFlags.mine and skill.skillFlags.hit then
			local output = probeOutput(context, skill)
			if output and (output.PoisonChance or 0) > 0 and (output.PoisonDPS or 0) > 0 then ownPoison = true end
		end
	end
	if plague and ownPoison then
		emit("plagueBearerState", reasons.plagueBearerState, true, "Model Plague Bearer's Infecting window after incubating?", "INF", nil,
			policy.Scenario("Confirm stored Plague and proximity to the target."))
	end
	local seen = { }
	for _, skill in ipairs(active) do
		local id = skill.activeEffect.grantedEffect.id
		local stats = skillStats(skill)
		if aspects[id] and not seen[id] then
			seen[id] = true
			local output = probeOutput(context, skill)
			local first, second = output and output.Duration or 0, output and output.DurationSecondary or 0
			if first > 0 and second > 0 then
				for index, phase in ipairs(aspects[id]) do
					local other = aspects[id][3 - index]
					emit(phase[1], string.format("%s phases: %gs / %gs. Model %s (%gs); this clears %s.",
						skill.activeEffect.grantedEffect.name, first, second, phase[2], index == 1 and first or second, other[2]), true,
						"Model the " .. phase[2] .. " phase (clear " .. other[2] .. ")?")
				end
			end
		elseif id == "FrostShield" and isDirect(skill) then
			local maximum = env.player.modDB:Sum("BASE", nil, "Multiplier:FrostShieldMaxStages")
			local interval = (stats.frost_globe_stage_gain_interval_ms or 0) / 1000
			local drain = (stats.energy_shield_lost_per_minute or 0) / 60
			-- Use the same scaling inputs as CalcPerform's active-skill Buff.
			local list, cfg = skill.skillModList, skill.skillCfg
			local effect = (1 + (list:Sum("INC", cfg, "BuffEffect", "BuffEffectOnSelf", "BuffEffectOnPlayer") + list:Sum("INC", cfg, "FrostShieldEffect"))
				/ 100) * list:More(cfg, "BuffEffect", "BuffEffectOnSelf")
			drain = math.max(0, math.ceil(drain * effect))
			local budget = env.player.output.EnergyShield or 0
			if maximum > 0 and interval > 0 and drain > 0 and budget > 0 then
				local window = math.min(seconds, 1, budget / drain)
				-- One stage per completed interval of the drain window, never the cap by default.
				local count = math.min(maximum, math.floor(window / interval + 1e-8))
				number("frostShieldStages", count, string.format("Frost Shield: native cap %g, stage interval %gs, ES drain %g/s; %g ES gives %gs.",
					maximum, interval, drain, budget, window), true)
			end
		elseif id == "Snipe" and isDirect(skill) then
			local result = probeEnv(context, skill)
			local output = result and result.player.output
			local maximum = result and result.player.modDB:Sum("BASE", nil, "Multiplier:SnipeStagesMax") or 0
			local interval = output and (output.Speed or 0) > 0 and 1 / output.Speed or 0
			if maximum > 0 and interval > 0 then
				local channelTime = seconds * policy.Activity(context, output)
				number("configSnipeStages", math.min(maximum, channelTime / interval + 0.5), string.format("Snipe: stage interval %gs, cap %g; %gs "
					.. "channel.", interval, maximum, channelTime), true)
			end
		elseif id == "VoltaxicBurst" and isDirect(skill) then
			local output = probeOutput(context, skill)
			local rate = output and math.min(output.CastRate or 0, output.Speed or 0) * policy.Activity(context, output) or 0
			local duration = output and output.Duration or 0
			if rate > 0 and duration > 0 then
				local expected = rate * math.min(seconds, duration)
				number("voltaxicBurstSpellsQueued", math.max(1, expected), string.format("Voltaxic Burst: %g casts/s, delay %gs.%s", rate, duration,
					expected < 1 and "\nLess than one cast is expected; confirm it." or ""), skill ~= main or expected < 1)
			end
		elseif (id == "Bladestorm" or id == "BladestormAltX") and isDirect(skill) then
			local stance = context.build.configTab.input.bloodSandStance or "BLOOD"
			for _, storm in ipairs({ { "bladestormInBloodstorm", "BLOOD", "Blood" }, { "bladestormInSandstorm", "SAND", "Sand" } }) do
				if id == "BladestormAltX" or stance == storm[2] or stanceSwitch then
					local previous = id == "Bladestorm" and stance ~= storm[2]
					emit(storm[1], skill.activeEffect.grantedEffect.name .. ": "
						.. (id == "BladestormAltX" and "the storm type is random." or previous and "your stance switch allows the other storm."
							or "your " .. storm[3] .. " stance creates this storm."), true,
						"Stand inside a living " .. storm[3] .. "storm?")
				end
			end
		end
	end
end

-- ============================================================================
-- Stuns: guaranteed or sampled outgoing Stuns
-- ============================================================================
-- A sampled hit can estimate Stun chance; a native guarantee is a separate proof.
function Stuns.CanSample(skill)
	return isDirect(skill) and not skill.minion and skill.skillFlags.hit
		and skill.skillFlags.melee and skill.skillFlags.attack and not skill.skillFlags.projectile
end

local function stunAvoidance(facts)
	local db = facts.env.enemy.modDB
	return db:Flag(nil, "StunImmune") and 100 or math.max(0, math.min(100, db:Sum("BASE", nil, "AvoidStun")))
end
local function cannotStun(facts, skill, stats)
	if (stats.cannot_stun or 0) > 0 or skill.skillModList:Flag(skill.skillCfg, "CannotStun", "HitsCannotStun") then return true end
	for _, line in ipairs(facts.Lines()) do
		if line.text == "your hits cannot stun enemies" then return true end
	end
	return false
end
local function guaranteedStun(facts, mainOnly)
	local avoid = stunAvoidance(facts)
	if mainOnly and avoid > 0 then return end
	for _, skill in ipairs(mainOnly and { facts.context.mainSkill } or facts.Active()) do
		if isDirect(skill) and not skill.minion and skill.skillFlags.hit then
			local stats = facts.Stats(skill)
			local conditional = (stats.always_stun_enemies_that_are_on_full_life or 0) > 0
			local guaranteed = (stats.always_stun or 0) > 0
			local possible = (guaranteed or conditional and facts.env.enemy.modDB:GetCondition("FullLife")) and not cannotStun(facts, skill, stats)
			local probe = possible and facts.Probe(skill)
			local out = probe and probe.player.output
			local duration, valid = math.huge, false
			if out and model.HasGeneratingHit(out) then
				valid = true
				for _, pass in ipairs(model.HitOutputs(out)) do
					if pass.AverageHit ~= nil then
						duration = math.min(duration, pass.EnemyStunDuration or 0)
						if pass.AverageHit <= 0 or (pass.HitChance or 100) <= 0 then valid = false end
					end
				end
			end
			local rate = out and policy.HitRate(facts.context, out) or 0
			if possible and rate > 0 and valid and duration >= 0.3 and duration < math.huge then
				return { rate = rate * (1 - avoid / 100), conditional = not guaranteed,
					duration = duration, reason = skill.activeEffect.grantedEffect.name .. " always stuns"
						.. (guaranteed and "." or " enemies on Full Life.") }
			end
		end
	end
end

local function meleeHitChance(pass, threshold, critical)
	local suffix = critical and "CritAverage" or "HitAverage"
	local damage = 1.25 * (pass["Physical" .. suffix] or 0)
	for _, kind in ipairs({ "Fire", "Cold", "Lightning", "Chaos" }) do damage = damage + (pass[kind .. suffix] or 0) end
	local chance = math.min(100, data.misc.StunBaseMult * damage / threshold)
	return chance > data.misc.MinStunChanceNeeded and chance or 0
end

local function sampledStun(facts)
	local base = facts.context.settings.stunSampleThreshold
	if base <= 0 then return end
	local skill, output = facts.context.mainSkill, facts.env.player.output
	if not Stuns.CanSample(skill) or policy.HitRate(facts.context, output) <= 0
		or cannotStun(facts, skill, facts.Stats(skill)) then return end
	local chance, duration = 100, math.huge
	for _, pass in ipairs(model.HitOutputs(output)) do
		if pass.AverageHit ~= nil then
			local threshold = base * (pass.EnemyStunThresholdMod or 0)
			if threshold <= 0 or not pass.EnemyStunDuration or pass.AverageHit <= 0 then return end
			local crit = math.max(0, math.min(1, (pass.CritChance or output.CritChance or 0) / 100))
			local normalChance = meleeHitChance(pass, threshold, false)
			local critChance = meleeHitChance(pass, threshold, true)
			-- Use the weaker hand when the distribution of landed hits is unknown.
			chance = math.min(chance, normalChance * (1 - crit) + critChance * crit)
			duration = math.min(duration, pass.EnemyStunDuration)
		end
	end
	chance = chance * (1 - stunAvoidance(facts) / 100)
	if chance <= 0 or duration < 0.3 or duration == math.huge then return end
	return { rate = policy.HitRate(facts.context, output) * chance / 100, duration = duration, sampleChance = chance, reason = string.format(
		"Base Stun threshold %g gives %.1f%% Stun chance per hit.", base, chance) }
end

for _, var in ipairs({ "conditionStunnedEnemyRecently", "conditionHitsAlwaysStun", "conditionEnemyStunned" }) do
	local always = var == "conditionHitsAlwaysStun"
	define(Stuns, var, "state", "automatic", function(facts)
		if stunAvoidance(facts) >= 100 then
			if facts.context.originalBuild.configTab.input[var] == true then
				return {
					value = false,
					reason = "The enemy cannot be stunned."
				}
			end
			return
		end
		local applied = guaranteedStun(facts, always)
		if not applied and not always then applied = sampledStun(facts) end
		if not applied then return end
		local window = math.min(facts.seconds, 4)
		local rate = applied.conditional and math.min(applied.rate, 1 / window) or applied.rate
		local assumption = policy.Rate(facts.context.settings, rate, window)
		assumption.stunChance = applied.sampleChance
		local review = applied.sampleChance ~= nil or applied.conditional or var == "conditionEnemyStunned" or not assumption.automatic
		assumption.automatic = not review
		return { value = true, review = review, assumption = assumption, reason = applied.reason
			.. (var == "conditionEnemyStunned"
			and (" The Stun lasts " .. applied.duration .. "s.") or "")
			.. (applied.conditional and " Confirm a hit on a full-life enemy." or "") }
	end)
end

-- ============================================================================
-- Resources: confirmed resource snapshots
-- ============================================================================
-- Recovery and capacities are separate from actual spending, damage and
-- recovery-start events. Always-full is not inferred from average
-- regeneration exceeding average spending.
local function surviving(hit) return hit and hit.after.Life >= 1 end
define(Resources, "conditionFullMana", "boolean", "assisted", function(facts)
	local out = facts.env.player.output
	if policy.Activity(facts.context, out) > 0 and not facts.env.player.modDB:Flag(nil, "EnergyShieldProtectsMana") and canActivate(facts.context.mainSkill)
		and (out.ManaCost or 0) > 0 and out.ManaCost <= (out.ManaUnreserved or 0) then
		return {
			value = false, label = "Model Mana below full after spending (clear Full Mana)", reason = string.format("Your main skill costs %g of %g "
				.. "unreserved Mana.", out.ManaCost, out.ManaUnreserved)
		}
	end
end)
for _, entry in ipairs({ { "conditionFullEnergyShield", false }, { "conditionHaveEnergyShield", true } }) do
	local var, empty = unpack(entry)
	define(Resources, var, "boolean", "assisted", function(facts)
		local hit = facts.SingleHit()
		if surviving(hit) and (hit.before.EnergyShield or 0) > 0 and hit.esLost > 0 and (not empty or hit.after.EnergyShield <= 0) then
			return {
				value = false,
				label = empty and "Model ES depletion after the hit (clear Always have ES)" or "Model ES below full after the hit (clear Full ES)",
				reason = string.format("A hit removes %g ES and leaves %g ES.", hit.esLost, hit.after.EnergyShield)
			}
		end
	end)
end
define(Resources, "minionsConditionFullEnergyShield", "boolean", "assisted", function(facts)
	for _, skill in ipairs(facts.Active()) do
		if skill.minion and not skill.minion.hostile then
			local probe = facts.Probe(skill)
			local actor = probe and probe.minion
			if actor and not actor.modDB:Flag(nil, "Condition:CannotBeDamaged") and (actor.output.EnergyShield or 0) > 0 then
				local hit = facts.SingleHit(probe, actor)
				if surviving(hit) and hit.esLost > 0 then
					return {
						value = false, label = "Model the selected minion below full ES (clear Minions on Full ES)",
						reason = string.format("A hit removes %g ES from your %s and leaves %g ES.", hit.esLost, actor.minionData.name,
							hit.after.EnergyShield)
					}
				end
			end
		end
	end
end)
define(Resources, "manabondMissingUnreservedManaPercentage", "amount", "assisted", function(facts)
	local main, cloak = facts.Find("Manabond"), facts.Find("ArcaneCloak")
	if not main or not cloak or not isDirect(main) or not isDirect(cloak) or facts.env.player.modDB:Flag(nil, "EnergyShieldProtectsMana") then return end
	local probe = facts.Probe(main)
	local out = probe and probe.player.output
	local pool = out and out.ManaUnreserved or 0
	local fraction = cloak.skillModList:Sum("BASE", cloak.skillCfg, "Multiplier:ArcaneCloakConsumedMana")
	if pool <= 0 or fraction <= 0 or fraction > 1 then return end
	local cloakCost, castCost = math.floor(pool * fraction), out.ManaCost or 0
	if castCost > pool - cloakCost then return end
	return {
		amount = 100 * (cloakCost + castCost) / pool, cap = 100, requires = { "arcaneCloakUsedRecentlyCheck" },
		reason = string.format("Unreserved Mana %g; Arcane Cloak spends %.1f%% (%g), then Manabond costs %g.", pool, fraction * 100, cloakCost,
			castCost)
	}
end)
define(Resources, "physicalAegisDepleted", "boolean", "assisted", function(facts)
	if not facts.Find("PhysicalAegis") then return end
	local hit = facts.SingleHit()
	if surviving(hit) and (hit.before.PhysicalAegis or 0) > 0 and (hit.after.Aegis.Physical or hit.before.PhysicalAegis) <= 0 then
		return {
			label = "Model Physical Aegis just after depletion", reason = "A physical hit empties your " .. hit.before.PhysicalAegis
				.. " Physical Aegis."
		}
	end
end)
for _, entry in ipairs({ { "MoltenShellDamageMitigated", "MoltenShell", false }, { "VaalMoltenShellDamageMitigated", "VaalMoltenShell", true } }) do
	local var, id, vaal = unpack(entry)
	define(Resources, var, "amount", "assisted", function(facts)
		local skill = facts.Find(id)
		if not skill then return end
		local probe = facts.WindowProbe(skill, "guard")
		local hit = probe and facts.SingleHit(probe)
		if surviving(hit) and (hit.before.sharedGuardAbsorb or 0) > 0 then
			local absorbed = math.max(0, hit.before.sharedGuardAbsorb - (hit.after.Guard.shared or 0))
			if absorbed > 0 then
				return {
					amount = absorbed, cap = hit.before.sharedGuardAbsorb, reason = string.format("%s: a hit uses %g of its %g guard pool.",
						skill.activeEffect.grantedEffect.name, absorbed, hit.before.sharedGuardAbsorb)
				}
			end
		end
	end)
end
define(Resources, "conditionWardBrokenPast2Seconds", "boolean", "assisted", function(facts)
	local hit = facts.SingleHit()
	if surviving(hit) and (hit.before.Ward or 0) > 0 and hit.after.WardActiveChance < 1 then
		return {
			label = "Confirm a real Ward break within two seconds", reason = string.format("Ward %g; after a hit it stays up %.1f%% of the time.",
				hit.before.Ward, 100 * hit.after.WardActiveChance)
		}
	end
end)
local function recharge(facts, recent)
	local hit, out = facts.SingleHit(), facts.env.player.output
	if not surviving(hit) or hit.esLost <= 0 or not out.EnergyShieldRechargeAppliesToEnergyShield or (out.EnergyShieldRecharge or 0) <= 0 then return end
	if (out.TotalBuildDegen or 0) > 0 or (out.EnergyShieldDegen or 0) > 0 then return end
	local delay = out.EnergyShieldRechargeDelay or math.huge
	local regen = math.max(0, out.EnergyShieldRegenRecovery or 0)
	if delay <= 0 or delay == math.huge or regen * delay >= hit.esLost then return end
	local age = facts.seconds - delay
	if age < 0 or age > recent then return end
	return {
		reason = string.format("A hit removes %g ES; recharge %g/s starts after %gs, %.2fs ago.", hit.esLost, out.EnergyShieldRecharge, delay, age)
	}
end
for _, entry in ipairs({ { "conditionEnergyShieldRechargeRecently", 4 }, { "conditionEnergyShieldRechargePastTwoSec", 2 } }) do
	local var, recent = unpack(entry)
	define(Resources, var, "boolean", "assisted", function(facts) return recharge(facts, recent) end)
end
define(Resources, "conditionStoppedTakingDamageOverTimeRecently", "boolean", "assisted", function(facts)
	if facts.seconds > 4 or (facts.env.player.output.TotalBuildDegen or 0) <= 0 then return end
	local burning = false
	for _, skill in ipairs(facts.Active()) do if skill.activeEffect.grantedEffect.id:match("^RighteousFire") then burning = true end end
	if not burning or facts.context.mainSkill.activeEffect.grantedEffect.id:match("^RighteousFire") then return end
	local removal
	for item in pairs(facts.env.flasks or { }) do
		for _, line in ipairs(item.explicitModLines or { }) do
			if not line.disabled and item:CheckModLineVariant(line) and StripEscapes(line.line):lower():find("removes burning on use", 1, true) then
				removal = item.name
			end
		end
	end
	if not removal then return end
	local after = facts.WindowProbe(facts.context.mainSkill, "withoutRF")
	if after and (after.player.output.TotalBuildDegen or 0) <= 0 then
		return { reason = "Your " .. removal .. " removes Righteous Fire burning." }
	end
end)

-- ============================================================================
-- History: source adapters for the shared event and elapsed-window models
-- ============================================================================
-- Application time, target coverage and player actions remain explicit
-- combat assumptions.
local function hexImmune(facts) return facts.env.enemy.modDB:Flag(nil, "HexImmune", "CurseImmune") end
local function selfOnlyCurse(facts, skill) return model.SelfOnlyCurse(facts.context.build, skill) end
-- Expected suppressed spell hits/s from the existing defensive scenario. The
-- Average category carries its configured spell share, so test that share
-- rather than the category name.
local function suppressedSpellRate(facts)
	if facts.Incoming().rate <= 0 then return 0 end
	return policy.Incoming(facts.context.settings, facts.env.player.output, facts.Incoming().category).suppressionRate
end
-- One unambiguous enabled skill matching the predicate, with its positive
-- native duration; conflicting durations or ids give nothing.
local function durationWindow(facts, predicate, field)
	local chosen
	for _, skill in ipairs(facts.Active()) do
		if predicate(skill) then
			local probe = facts.Probe(skill)
			local duration = probe and probe.player.output[field or "Duration"] or 0
			if duration <= 0 then return end
			if duration > 0 then
				if chosen and (chosen.id ~= skill.activeEffect.grantedEffect.id or math.abs(chosen.duration - duration) > 1e-6) then return end
				chosen = { skill = skill, id = skill.activeEffect.grantedEffect.id, duration = duration, probe = probe }
			end
		end
	end
	return chosen
end

define(History, "conditionChangedStanceLastSecond", "boolean", "assisted", function(facts)
	for _, skill in ipairs(facts.Active()) do
		local id = skill.activeEffect.grantedEffect.id
		if (id == "BloodAndSand" or id == "FleshAndStone") and not skill.skillData.triggered then
			local probe = facts.Probe(skill)
			if probe and (probe.player.output.Cooldown or 0) > 0 then
				return { reason = skill.activeEffect.grantedEffect.name .. ": stance-switch cooldown " .. probe.player.output.Cooldown .. "s." }
			end
		end
	end
end)
define(History, "conditionLinkedRecently", "boolean", "assisted", function(facts)
	for _, skill in ipairs(facts.Active()) do
		if personal(skill) and skill.skillTypes[SkillType.Link] then
			local probe = facts.Probe(skill)
			if probe and (probe.player.output.Duration or 0) > 0 then
				return { reason = skill.activeEffect.grantedEffect.name .. ": duration " .. probe.player.output.Duration .. "s." }
			end
		end
	end
end)
define(History, "conditionCritWithHeraldSkillRecently", "event", "assisted", function(facts)
	if not facts.PersonalKills() then return end
	for _, skill in ipairs(facts.Active()) do
		local id = skill.activeEffect.grantedEffect.id
		if (id == "HeraldOfIce" or id == "HeraldOfThunder") and not skill.minion and not skill.skillFlags.totem then
			local probe = facts.Probe(skill)
			local out = probe and probe.player.output
			local setup = facts.Ailment(id == "HeraldOfIce" and "Freeze" or "Shock")
			local rate = setup
				and (id == "HeraldOfIce" and math.min(policy.KillRate(facts.context, "player"), setup.rate) or out and policy.HitRate(facts.context, out)) or 0
			if out and (out.AverageDamage or 0) > 0 and (out.CritChance or 0) > 0 and rate > 0 then
				return {
					rate = rate * out.CritChance / 100, reason = skill.activeEffect.grantedEffect.name .. " hits with " .. out.CritChance
						.. "% critical chance."
				}
			end
		end
	end
end)
define(History, "conditionTauntedEnemyRecently", "event", "automatic", function(facts)
	return facts.Taunt()
end)
define(History, "conditionEnemyTaunted", "boolean", "assisted", function(facts)
	if facts.env.enemy.modDB:GetCondition("Taunted") then return end
	local source = facts.Taunt()
	if source then
		return { label = "Is this enemy still Taunted by you?",
			reason = source.reason .. "\nConfirm the Taunt on this enemy is still active." }
	end
end)
define(History, "conditionKilledTauntedEnemyRecently", "event", "automatic", function(facts)
	local taunt = facts.PersonalKills() and facts.Taunt()
	if taunt then
		return {
			rate = math.min(policy.KillRate(facts.context, "player"), taunt.rate), review = taunt.review,
			reason = taunt.reason .. "\nConfirm the enemy was taunted when you killed it."
		}
	end
end)
for _, entry in ipairs({ { "conditionStunnedRecently", false }, { "conditionStunnedWhileCastingRecently", true } }) do
	local var, casting = unpack(entry)
	define(History, var, "event", "assisted", function(facts)
		local out, main = facts.env.player.output, facts.context.mainSkill
		local chance = out.SelfStunChance or 0
		if chance <= 0 or (out.StunDuration or 0) <= 0 then return end
		if casting
			and (not personal(main) or not main.skillTypes[SkillType.Spell] or main.skillTypes[SkillType.Instant]
			or main.skillModList:Flag(main.skillCfg, "StunImmune")) then
			return
		end
		local hit = facts.Incoming()
		if hit.damage > 0 then
			return {
				rate = hit.damage * chance / 100,
				reason = hit.reason
					.. string.format("\nChance to be stunned %.2f%%, Stun duration %gs.", chance, out.StunDuration)
			}
		end
	end)
end

-- Reload and expenditure are serial phases: spending cancels Call of Steel's
-- continuing reload. Never add its full reload rate to simultaneous attacks.
local function steel(facts, target)
	local main = facts.context.mainSkill
	if not personal(main) or not main.skillTypes[SkillType.Attack] then return end
	local perUse = facts.Stats(main).steel_ammo_consumed_per_use or 0
	if perUse <= 0 then return end
	local reload
	for _, skill in ipairs(facts.Active()) do if skill.activeEffect.grantedEffect.id == "CallOfSteel" and personal(skill) then reload = skill break end end
	local stats, probe, useTime
	if reload then
		stats, probe = facts.Stats(reload), facts.Probe(reload)
		useTime = probe and probe.player.output.Time or 0
		if probe and useTime <= 0 then useTime = activationTime(reload.activeEffect.grantedEffect.castTime, probe.player.output.ActionSpeedMod) end
	else
		local granted = false
		for _, line in ipairs(facts.Lines()) do if line.text == "grants call of steel" then granted = true end end
		if not granted then return end
		stats, useTime = callOfSteel(facts.env.player.output.ActionSpeedMod)
	end
	local amount, interval = stats.call_of_steel_reload_amount or 0, (stats.call_of_steel_reload_time or 0) / 1000
	local rate = useRate(facts.context, main, facts.env.player.output)
	if amount <= 0 or interval <= 0 or rate <= 0 or useTime <= 0 then return end
	local loadTime = math.ceil(target / amount) * interval
	local spendTime = math.ceil(target / perUse) / rate
	if useTime + loadTime + spendTime > math.min(facts.seconds, 4) then return end
	return {
		reason = string.format("Call of Steel: %g shards per %gs; %s uses %g shards at %.3f uses/s. Call %gs + reload %gs (%g shards) + spend %gs "
			.. "fits %.1fs.", amount, interval, main.activeEffect.grantedEffect.name, perUse, rate, useTime, loadTime, target, spendTime,
			math.min(facts.seconds, 4)),
		assumption = policy.Scenario("Reload with Call of Steel, then spend the shards within 4 seconds.")
	}
end
History.SteelWindow = steel
for _, target in ipairs({ 8, 12 }) do
	define(History, "conditionConsumed" .. target .. "SteelShardsRecently", "boolean", "assisted", function(facts) return steel(facts, target) end)
end

-- window: the setting's own look-back (8s for the Past8Sec condition, the
-- recent window for the loss counter); generation must fit that window.
local function enduranceLoss(facts, window)
	window = math.min(facts.seconds, window or policy.recentWindow)
	local out, main, generation, reasons = facts.env.player.output, facts.context.mainSkill, 0, { }
	if facts.env.player.modDB:Flag(nil, "EnduranceChargesConvertToBrutalCharges") then return end
	-- An otherwise empty Discharge cannot bootstrap charges from its own hits
	-- or kills. This adapter does not assume a separate setup generator.
	if main.activeEffect.grantedEffect.id:match("^Discharge") then return end
	local minimum, cap = out.EnduranceChargesMin or 0, out.EnduranceChargesMax or 0
	if cap <= minimum then return end
	for _, line in ipairs(facts.Lines()) do
		local chance, trigger = line.text:match("^(%d+)%% chance to gain an endurance charge (.+)$")
		if not trigger then trigger = line.text:match("^gain an endurance charge (.+)$"); chance = trigger and 100 end
		local rate = trigger == "on hit" and facts.MainHit() and policy.HitRate(facts.context, out)
			or trigger == "on critical strike" and facts.MainHit() and policy.HitRate(facts.context, out) * (out.CritChance or 0) / 100
			or trigger == "on kill" and facts.PersonalKills() and policy.KillRate(facts.context, "player") or 0
		if chance and rate > 0 then generation = generation + rate * math.min(100, tonumber(chance)) / 100; t_insert(reasons, line.source) end
	end
	if generation <= 0 then return end
	local lossRate, atMaximum = 0, false
	for _, line in ipairs(facts.Lines()) do
		if line.text == "lose an endurance charge each second" then lossRate = math.max(lossRate, 1); t_insert(reasons, line.source) end
		if line.text == "you lose all endurance charges when hit" then lossRate = math.max(lossRate, facts.Incoming().rate); t_insert(reasons, line.source) end
		if line.text == "you lose all endurance charges on reaching maximum endurance charges" then atMaximum = true; t_insert(reasons, line.source) end
	end
	for _, skill in ipairs(facts.Active()) do
		if personal(skill) and skill.activeEffect.grantedEffect.id == "ImmortalCall" then
			local probe = facts.Probe(skill)
			if probe and (probe.player.output.Cooldown or 0) > 0 then
				lossRate = math.max(lossRate, 1 / probe.player.output.Cooldown)
				t_insert(reasons, "Immortal Call spends Endurance Charges.")
			end
		end
	end
	if atMaximum and generation * facts.seconds < cap - minimum then return end
	if not atMaximum and lossRate <= 0 then return end
	-- One actually generated and consumed charge is a conservative lower bound.
	-- Do not pretend a steady-state loss rate while a burst consumer is ramping.
	if generation * window < 1 then return end
	return {
		reason = table.concat(reasons, "\n")
			.. string.format("\nGeneration %.3f/s over a %gs window, minimum/maximum %g/%g.", generation, window, minimum, cap),
		rate = 1 / window
	}
end
define(History, "conditionLostEnduranceChargeInPast8Sec", "boolean", "assisted", function(facts) return enduranceLoss(facts, 8) end)
define(History, "multiplierEnduranceChargesLostRecently", "count", "assisted", function(facts) return enduranceLoss(facts, policy.recentWindow) end)

for _, ailment in ipairs({
	{ "conditionIgnited", "Ignite" }, { "conditionChilled", "Chill" }, { "conditionFrozen", "Freeze" },
	{ "conditionShocked", "Shock" }, { "conditionScorched", "Scorch" }, { "conditionBrittle", "Brittle" }, { "conditionSapped", "Sap" },
}) do
	local var, name = unpack(ailment)
	define(History, var, "boolean", "assisted", function(facts)
		local source
		for _, line in ipairs(facts.Lines()) do
			if line.text == "elemental ailments you inflict are reflected to you" or name == "Ignite"
				and line.text == "ignites you cause are reflected back to you" then
				source = line.source
				break
			end
		end
		if not source then return end
		local application, db, out = facts.Ailment(name), facts.env.player.modDB, facts.env.player.output
		if not application or db:Flag(nil, name .. "Immune", "ElementalAilmentImmune")
			or math.max(out[name .. "AvoidChance"] or 0, db:Sum("BASE", nil, "Avoid" .. name, "AvoidAilments", "AvoidElementalAilments")) >= 100 then
			return
		end
		return { reason = source .. "\n" .. application.reason .. "\nConfirm the reflected " .. name .. " affects you." }
	end)
end

define(History, "conditionEnemyDebilitated", "boolean", "assisted", function(facts)
	for _, skill in ipairs(facts.Active()) do
		if personal(skill) then
			if skill.activeEffect.grantedEffect.id == "Punishment" and not selfOnlyCurse(facts, skill)
				and not hexImmune(facts) and facts.Incoming().rate > 0 then
				local duration = (facts.Stats(skill).debilitate_self_for_x_milliseconds_on_hit or 0) / 1000
				if duration > 0 then
					return { reason = "Punishment Debilitates the enemy for " .. duration .. "s when it hits you." }
				end
			end
			for _, line in ipairs(facts.Lines()) do
				if skill.skillTypes[SkillType.Retaliation] and line.text:match("^retaliation skills debilitate enemies for %d+ seconds on hit$") then
					local probe = facts.Probe(skill)
					if probe and (probe.player.output.AverageDamage or 0) > 0 then
						return { reason = line.source .. "\n" .. skill.activeEffect.grantedEffect.name .. " can apply it on hit." }
					end
				end
				if skill.skillTypes[SkillType.Warcry] and line.text:match("^warcries debilitate enemies for %d+ seconds?$") then
					return { reason = line.source .. "\nWarcry: " .. skill.activeEffect.grantedEffect.name .. "." }
				end
			end
		end
	end
	for _, line in ipairs(facts.Lines()) do
		if line.text:match("^debilitate enemies for %d+ seconds? when you suppress their spell damage$") and suppressedSpellRate(facts) > 0 then
			return { reason = line.source
				.. string.format("\n%s scenario: %.3f suppressions/s.", facts.Incoming().category, suppressedSpellRate(facts)) }
		end
	end
end)

local function brandWindow(facts)
	for _, skill in ipairs(facts.Active()) do
		if personal(skill) and skill.skillTypes[SkillType.Brand] and (facts.Stats(skill).brand_atttached_duration_is_infinite or 0) > 0 then return end
	end
	return durationWindow(facts, function(skill) return personal(skill) and skill.skillTypes[SkillType.Brand] end)
end
for _, fraction in ipairs({ { "BrandsInLastHalf", 0.5 }, { "BrandsInLastQuarter", 0.75 } }) do
	local var, threshold = unpack(fraction)
	define(History, var, "boolean", "assisted", function(facts)
		local selected = brandWindow(facts)
		if selected and facts.seconds >= selected.duration * threshold and facts.seconds < selected.duration then
			return {
				reason = string.format("%s: duration %gs, attached %gs (%.1f%% elapsed).",
					selected.skill.activeEffect.grantedEffect.name, selected.duration, facts.seconds, 100 * facts.seconds / selected.duration)
			}
		end
	end)
end
define(History, "conditionTotemsNotSummonedInPastTwoSeconds", "boolean", "assisted", function(facts)
	if facts.seconds <= 2 then return end
	for _, skill in ipairs(facts.Active()) do
		if canActivate(skill) and skill.skillFlags.totem and not skill.skillData.triggered then
			local probe = facts.Probe(skill)
			local duration = probe and probe.player.output.TotemDuration or 0
			if duration > facts.seconds then
				return { reason = skill.activeEffect.grantedEffect.name .. ": Totem lifetime " .. duration .. "s, fight " .. facts.seconds .. "s." }
			end
		end
	end
end)

define(History, "conditionEnemyPacified", "boolean", "assisted", function(facts)
	if hexImmune(facts) then return end
	local selected = durationWindow(facts, function(skill) return personal(skill) and skill.activeEffect.grantedEffect.id == "Pacify" end)
	if selected and facts.seconds >= selected.duration * 0.6 and facts.seconds < selected.duration then
		return {
			reason = string.format("Pacify: duration %gs; Pacified from %gs (60%%); age %gs.", selected.duration, selected.duration * 0.6, facts.seconds)
		}
	end
end)

define(History, "multiplierAffectedByWarcryBuffDuration", "elapsed", "assisted", function(facts)
	local selected = durationWindow(facts, function(skill)
		if not personal(skill) or not skill.skillTypes[SkillType.Warcry] then return false end
		local probe = facts.Probe(skill)
		return probe and probe.player.mainSkill.buffSkill
	end)
	if selected then
		return {
			duration = selected.duration, reason = selected.skill.activeEffect.grantedEffect.name .. ": buff duration " .. selected.duration .. "s."
		}
	end
end)
define(History, "multiplierWoCExpiredDuration", "elapsed", "assisted", function(facts)
	local selected = durationWindow(facts, function(skill) return personal(skill) and skill.activeEffect.grantedEffect.id == "WaveOfConviction" end)
	if selected then
		return {
			duration = selected.duration, percent = true, reason = "Wave of Conviction: duration " .. selected.duration .. "s."
		}
	end
end)
for _, entry in ipairs({ { "multiplierCurseExpiredOnEnemy", true }, { "multiplierCurseDurationExpiredOnEnemy", false } }) do
	local var, percent = unpack(entry)
	define(History, var, "elapsed", "assisted", function(facts)
		if hexImmune(facts) then return end
		local selected = durationWindow(facts, function(skill)
			return personal(skill) and skill.skillTypes[SkillType.AppliesCurse] and not skill.skillTypes[SkillType.Mark]
				and not selfOnlyCurse(facts, skill)
		end)
		if selected then
			return {
				duration = selected.duration, percent = percent, reason = selected.skill.activeEffect.grantedEffect.name
					.. ": curse duration " .. selected.duration .. "s."
			}
		end
	end)
end
for _, entry in ipairs({ { "multiplierChilledByYouSeconds", "Chill", "conditionEnemyChilled" },
	{ "multiplierFrozenByYouSeconds", "Freeze", "conditionEnemyFrozen" } }) do
	local var, name, parent = unpack(entry)
	define(History, var, "elapsed", "assisted", function(facts)
		local application = facts.Ailment(name)
		if not application then return end
		local duration = 0.3
		if name == "Chill" then
			local list, cfg, enemy = facts.context.mainSkill.skillModList, facts.context.mainSkill.skillCfg, facts.env.enemy.modDB
			local inc = list:Sum("INC", cfg, "EnemyChillDuration", "EnemyAilmentDuration", "EnemyElementalAilmentDuration")
				+ enemy:Sum("INC", nil, "SelfChillDuration", "SelfAilmentDuration", "SelfElementalAilmentDuration")
			local more = list:More(cfg, "EnemyChillDuration", "EnemyAilmentDuration", "EnemyElementalAilmentDuration")
				* enemy:More(nil, "SelfChillDuration", "SelfAilmentDuration", "SelfElementalAilmentDuration")
			duration = data.nonDamagingAilment.Chill.duration * math.max(0, (1 + inc / 100) * more)
		end
		if duration > 0 and policy.Refresh(facts.context.settings, application.rate, duration, facts.seconds).automatic then
			return {
				duration = duration, upkeep = true, requires = { parent },
				reason = application.reason
					.. string.format("\n%.3f applications/s, duration %gs, fight %gs.", application.rate, duration, facts.seconds)
			}
		end
	end)
end
define(History, "inventionMineTrapPlacedDuration", "elapsed", "assisted", function(facts)
	local selected
	for _, skill in ipairs(facts.Active()) do
		if canActivate(skill) and (skill.skillFlags.trap or skill.skillFlags.mine) then
			for _, effect in ipairs(skill.effectList) do
				if effect.grantedEffect.id == "SupportInvention" then
					local probe = facts.Probe(skill)
					local base = math.huge
					for _, applied in ipairs(skill.effectList) do
						local stats = effectStats(applied)
						for _, key in ipairs(skill.skillFlags.trap and { "base_trap_duration" }
							or { "base_mine_duration", "support_remote_mine_2_base_mine_duration", "support_locus_mine_base_mine_duration" }) do
							if (stats[key] or 0) > 0 then base = math.min(base, stats[key] / 1000) end
						end
					end
					local duration = probe and base < math.huge
						and base * math.max(0, calcLib.mod(skill.skillModList, skill.skillCfg, skill.skillFlags.trap and "TrapDuration" or "MineDuration")) or 0
					if duration > 0 then
						if selected and selected.duration ~= duration then return end
						selected = {
							duration = duration, reason = skill.activeEffect.grantedEffect.name .. " with Invention: lifetime " .. duration .. "s."
						}
					end
				end
			end
		end
	end
	return selected
end)

-- ============================================================================
-- Stacks: whole-event stack models
-- ============================================================================
-- Native source/actor adapters feed one shared expiry/reset solver;
-- capacities and manually configured counts are not proof. Detection
-- neutralises these counts to nil, never 0: several apply callbacks subtract
-- one from an explicit zero and would poison the neutral environment.
local function bow(facts)
	local skill = facts.context.mainSkill
	return facts.MainHit() and skill.skillTypes[SkillType.Attack] and skill.skillTypes[SkillType.Projectile]
		and (facts.env.player.weaponData1.type == "Bow" or facts.env.player.weaponData2.type == "Bow")
end
local function nearbyDeathRate(facts)
	return policy.KillRate(facts.context, policy.MainKillActor(facts.env))
end
define(Stacks, "multiplierWitheredStackCountSelf", "stack", "assisted", function(facts)
	if not facts.Find("AspectOfArakaali") or not facts.env.player.modDB:Flag(nil, "Condition:CanBeWithered") then return end
	for _, skill in ipairs(facts.Active()) do
		if personal(skill) and skill.activeEffect.grantedEffect.name == "Wither" then
			local probe = facts.Probe(skill)
			local out = probe and probe.player.output
			local rate = out and (out.Speed or 0) * policy.Activity(facts.context, out) or 0
			if rate > 0 and (out.Duration or 0) > 0 then
				return {
					rate = rate, duration = out.Duration, cap = 15, allowZero = true, reason = string.format("Aspect of Arakaali reflects your Wither: "
						.. "%.3f/s, duration %gs.", rate, out.Duration)
				}
			end
		end
	end
end)
define(Stacks, "multiplierManaBurnStacks", "amount", "assisted", function(facts)
	local db, out, main = facts.env.player.modDB, facts.env.player.output, facts.context.mainSkill
	if not db:GetCondition("UsingTincture") or db:Flag(nil, "Condition:WeepingWoundsInsteadOfManaBurn")
		or (out.LifeCost or 0) > 0 or main.skillModList:Flag(main.skillCfg, "Every2UseManaCostRefund") then return end
	local pool = out.ManaUnreserved or 0
	if pool <= 0 then return end
	local items = { }
	for item in pairs(facts.env.tinctures or { }) do if item.tinctureData then t_insert(items, item) end end
	table.sort(items, function(a, b)
		local ia, ib = (facts.env.itemSlotIndex or { })[a] or 0, (facts.env.itemSlotIndex or { })[b] or 0
		if ia ~= ib then return ia < ib end
		return (a.id or 0) < (b.id or 0)
	end)
	local clocks, limit = { }, db:Sum("BASE", nil, "TinctureLimit")
	if #items == 0 or limit <= 0 then return end
	for i, item in ipairs(items) do
		if i > limit then break end
		local timed = true
		for _, line in ipairs(item.explicitModLines or { }) do
			if not line.disabled and item:CheckModLineVariant(line) and StripEscapes(line.line):lower() == "does not inflict mana burn over time" then
				timed = false
			end
		end
		if timed and (item.tinctureData.manaBurn or 0) > 0 then t_insert(clocks, { base = item.tinctureData.manaBurn, next = 0 }) end
	end
	local deactivateAt = db:Sum("BASE", nil, "MaxManaBurnStacks")
	local cap = deactivateAt > 0 and deactivateAt or 9999
	local function withCount(count, fn)
		local oldBurn, oldEffective = db.multipliers.ManaBurnStacks, db.multipliers.EffectiveManaBurnStacks
		db.multipliers.ManaBurnStacks, db.multipliers.EffectiveManaBurnStacks = count, count
		local a, b = fn()
		db.multipliers.ManaBurnStacks, db.multipliers.EffectiveManaBurnStacks = oldBurn, oldEffective
		return a, b
	end
	local function interval(clock, count)
		return withCount(count, function()
			local cfg = { actor = "player" }
			local chance = math.min(100, math.max(0, db:Sum("BASE", cfg, "TincturesNotInflictManaBurn")))
			local rate = (1 + db:Sum("INC", cfg, "TinctureManaBurnRate") / 100) * (1 + db:Sum("MORE", cfg, "TinctureManaBurnRate") / 100) * (1 - chance / 100)
			return rate > 0 and clock.base / rate or math.huge
		end)
	end
	for _, clock in ipairs(clocks) do clock.next = interval(clock, 0) end
	local rate = useRate(facts.context, main, out)
	if main.skillTypes[SkillType.Channel] and isDirect(main) then rate = (out.Speed or 0) * policy.Activity(facts.context, out) end
	local cost = out.ManaCost or 0
	local nextCast = rate > 0 and cost > 0 and canActivate(main) and 0 or math.huge
	local mana, count, time, steps = pool, 0, 0, 0
	while time < facts.seconds - 1e-8 do
		steps = steps + 1; if steps > 100000 then return end
		local nextEvent = math.min(facts.seconds, nextCast)
		for _, clock in ipairs(clocks) do nextEvent = math.min(nextEvent, clock.next) end
		local extra, degenMod = withCount(count,
			function() return db:Sum("BASE", { actor = "player" }, "EffectiveManaBurnStacks"), calcLib.mod(db, nil, "ManaDegen") end)
		local net = (out.ManaRegenRecovery or 0) - math.max(1, (out.Mana or 0) / 100) * math.max(0, count + extra) * degenMod
		local delta = math.max(0, nextEvent - time)
		if net < 0 and mana + net * delta <= 0 then return end
		mana = math.min(pool, mana + net * delta); time = nextEvent
		if nextCast <= time + 1e-8 then
			if mana >= cost then mana = mana - cost end
			nextCast = nextCast + 1 / rate
			if mana <= 0 then return end
		end
		for _, clock in ipairs(clocks) do if clock.next <= time + 1e-8 then count = math.min(cap, count + 1); clock.next = time + interval(clock, count) end end
		if deactivateAt > 0 and count >= deactivateAt then return end
	end
	return {
		amount = count, cap = cap, allowZero = true, reason = string.format("%g active Tinctures, %g Mana Burn clocks. From %g Mana, after %gs about %.1f "
			.. "Mana and %g stacks remain (cap %g).", math.min(#items, limit), #clocks, pool, facts.seconds, mana, count, cap)
	}
end)

define(Stacks, "touchedDebuffsCount", "amount", "assisted", function(facts)
	local skill = facts.Find("EmbraceMadness")
	if not skill then return end
	local interval = (facts.Stats(skill).glorious_madness_timer_ms or 0) / 1000
	if interval <= 0 then return end
	local grants = math.floor(facts.seconds / interval + 1e-8)
	if grants % 4 ~= 0 then return end
	return {
		amount = math.min(10, grants / 4), cap = 10, allowZero = true, requires = { "embraceMadnessActive" },
		reason = string.format("Embrace Madness: one random Touched debuff every %gs, %g in %gs; %g per type.", interval, grants, facts.seconds,
			math.min(10, grants / 4))
	}
end)
define(Stacks, "maniaDebuffsCount", "stack", "assisted", function(facts)
	if not facts.Find("EmbraceMadness") then return end
	for _, line in ipairs(facts.Paragraphs()) do
		if line.text:find("while affected by glorious madness", 1, true) and line.text:match("inflict mania on.-enemies.-every second") then
			return {
				rate = 1, duration = 15, cap = 15, requires = { "embraceMadnessActive" },
				activation = { parent = "embraceMadnessActive", conditions = { AffectedByGloriousMadness = true } },
				reason = line.source .. "\nOne Mania per second, lasting 15s, cap 15."
			}
		end
	end
end)

define(Stacks, "multiplierDefiance", "stack", "assisted", function(facts)
	local hit = facts.SingleHit()
	if not hit or hit.after.Life < 1 or hit.lifeLost <= 0 then return end
	for _, line in ipairs(facts.Paragraphs()) do
		local duration, interval = line.text:match("gain defiance for (%d+) seconds on losing life to an enemy hit, no more than once every ([%d%.]+) seconds")
		if duration and line.text:find("lose all defiance when you reach 10 defiance", 1, true) then
			return {
				rate = math.min(facts.Incoming().damage, 1 / tonumber(interval)), duration = tonumber(duration), cap = 10, resetAt = 10, allowZero = true,
				reason = line.source .. "\nA hit removes " .. hit.lifeLost .. " Life and you survive."
			}
		end
	end
end)
define(Stacks, "multiplierEnemyAffectedByGraspingVines", "stack", "assisted", function(facts)
	if not facts.MainHit() or #model.ActiveFlasks(facts.env, true) == 0 then return end
	for _, line in ipairs(facts.Paragraphs()) do
		if line.text:match("inflict a grasping vine on hit against enemies with fewer than 8 grasping vines during effect of any life flask") then
			return {
				rate = policy.HitRate(facts.context, facts.env.player.output), cap = 8, reason = line.source .. "\nYour hits during an active Life Flask."
			}
		end
	end
end)

for _, entry in ipairs({ { "cinderflameStacks", "ResentmentUniqueSkill", 10, false }, { "weepingBlackStacks", "AnimosityUniqueSkill", 5, true } }) do
	local var, id, cap, impaled = unpack(entry)
	define(Stacks, var, "stack", "assisted", function(facts)
		local skill = facts.Find(id)
		if not skill or not bow(facts) then return end
		local probe = facts.Probe(skill)
		local duration = probe and probe.player.output.Duration or 0
		local rate = policy.HitRate(facts.context, facts.env.player.output)
		if impaled then
			local chance = facts.env.player.output.ImpaleChance or 0
			if chance <= 0 then return end
			rate = rate * math.min(100, chance) / 100
		end
		if duration > 0 and rate > 0 then
			return {
				rate = rate, first = impaled and 2 / rate or nil, duration = duration, cap = cap, allowZero = true,
				reason = skill.activeEffect.grantedEffect.name .. ": duration " .. duration .. "s, cap " .. cap .. ", " .. rate .. " bow hits/s."
					.. (impaled and " The first hit must Impale." or "")
			}
		end
	end)
end
define(Stacks, "conditionCorruptingCryStages", "stack", "assisted", function(facts)
	local best
	for _, skill in ipairs(facts.Active()) do
		local support = facts.Applied(skill, "SupportCorruptingCry")
		if personal(skill) and skill.skillTypes[SkillType.Warcry] and support then
			local probe = facts.Probe(skill)
			local out, stats = probe and probe.player.output, effectStats(support)
			local cooldown = out and out.Cooldown or 0
			local duration = out and out.DurationSecondary or 0
			local stacks = stats.support_corrupting_cry_warcry_applies_X_stacks_of_corrupted_blood or 0
			if cooldown > 0 and duration > 0 and stacks > 0 then
				if best then return end -- distinct overlapping sources need their own ownership rule
				best = {
					rate = 1 / cooldown, first = out.WarcryCastTime or skill.activeEffect.grantedEffect.castTime, perEvent = stacks, duration = duration,
					cap = 10, allowZero = true, reason = string.format("Corrupting Cry on %s: %g stacks per use, cooldown %gs, lasting %gs.",
						skill.activeEffect.grantedEffect.name, stacks, cooldown, duration)
				}
			end
		end
	end
	return best
end)
define(Stacks, "bloodsoakedBannerStages", "stack", "assisted", function(facts)
	local valour = facts.context.found.bannerValour
	local generator = valour and valour.assumption and valour.assumption.valourGeneration
	if not generator or generator.rate <= 0 then return end
	local buildTime = facts.seconds / 2
	local amount = math.min(generator.maximum, math.floor(generator.rate * buildTime + 1e-8))
	if amount < 8 then return end
	for _, skill in ipairs(facts.Active()) do
		local support = facts.Applied(skill, "SupportBloodsoakedBanner")
		if skill.skillTypes[SkillType.Banner] and support then
			local stats, probe = effectStats(support), facts.Probe(skill)
			local interval = (stats.support_bloodstained_banner_apply_corrupted_blood_every_x_ms or 0) / 1000
			local duration = probe and probe.player.output.DurationSecondary or 0
			if interval > 0 and duration > 0 then
				-- The Valour proposal is retargeted by the registry only once this
				-- Banner suggestion is actually accepted, so a filtered Banner row
				-- never halves another rule's Valour on its own.
				local dependent = { var = "bannerValour", value = amount, label = "Valour before planting: " .. amount,
					reason = string.format("Bloodsoaked Banner: %gs of %gs build Valour (%g/s), giving %g.", buildTime, facts.seconds, generator.rate,
						amount) }
				return {
					rate = 1 / interval, first = buildTime + interval, duration = duration, cap = math.min(10, math.floor(amount / 8)), allowZero = true,
					requires = { "bannerPlanted", "bannerValour" }, dependent = dependent, reason = string.format("Bloodsoaked Banner: %gs buildup "
						.. "gives %g Valour; then %gs planted, a stage every %gs (lasting %gs).", buildTime, amount, facts.seconds - buildTime, interval,
						duration)
				}
			end
		end
	end
end)
define(Stacks, "goreblossomBlooms", "stack", "assisted", function(facts)
	local skill, main, out = facts.Find("BloodFlower"), facts.context.mainSkill, facts.env.player.output
	if not skill or not personal(main) or not main.skillTypes[SkillType.Spell] or (out.LifePerSecondCost or 0) <= 0 then return end
	for _, line in ipairs(facts.Paragraphs()) do
		local percent = tonumber(line.text:match("trigger level %d+ goreblossom after spending ([%d%.]+)%% of your maximum life on spells"))
		if percent and percent > 0 then
			local probe = facts.Probe(skill)
			local duration, cooldown = probe and probe.player.output.Duration or 0, probe and probe.player.output.Cooldown or 0
			local threshold = (out.Life or 0) * percent / 100
			local cap = facts.env.player.modDB:Sum("BASE", nil, "Multiplier:GoreblossomMaxBlooms")
			if threshold > 0 and duration > 0 and cooldown > 0 and cap > 0 then
				local spending, recovery = out.LifePerSecondCost * policy.Activity(facts.context, out), math.max(0, out.LifeRegenRecovery or 0)
				local affordable = spending > recovery and math.max(0, (out.LifeUnreserved - 1) / (spending - recovery)) or facts.seconds
				-- No allowZero: the native option treats 0 as "maximum", so an empty
				-- Bloom window must emit no row rather than a zero.
				return {
					rate = math.min(spending / threshold, 1 / cooldown), first = threshold / spending, stop = affordable, duration = duration, cap = cap,
					reason = line.source
						.. string.format("\nLife spent %g/s, %g per Bloom, cooldown %gs, lasting %gs, cap %g; %.2fs affordable.", spending, threshold,
							cooldown, duration, cap, affordable)
				}
			end
		end
	end
end)

define(Stacks, "shardsConsumed", "amount", "assisted", function(facts)
	local amount = facts.Stats(facts.context.mainSkill).steel_ammo_consumed_per_use or 0
	if amount <= 0 then return end
	local proof = steel(facts, amount)
	if proof then return { amount = amount, reason = proof.reason .. "\nShards per use." } end
end)
define(Stacks, "steelWards", "amount", "assisted", function(facts)
	local main, out = facts.context.mainSkill, facts.env.player.output
	local perUse = facts.Stats(main).steel_ammo_consumed_per_use or 0
	if not personal(main) or not main.activeEffect.grantedEffect.name:match("^Shattering Steel") or perUse < 2 or not steel(facts, perUse) then return end
	local duration = out.Duration or 0
	local rate = useRate(facts.context, main, out)
	local reloadStats, castTime = callOfSteel(out.ActionSpeedMod)
	local packet = reloadStats.call_of_steel_reload_amount or 0
	local reloadTime = castTime + (reloadStats.call_of_steel_reload_time or 0) / 1000
	if duration <= 0 or rate <= 0 or packet < perUse then return end
	local clock, stock, births, steps = 0, 0, { }, 0
	while clock <= facts.seconds do
		steps = steps + 1; if steps > 100000 then return end
		if stock < perUse then clock, stock = clock + reloadTime, packet end
		clock = clock + 1 / rate
		if clock > facts.seconds then break end
		stock = stock - perUse
		t_insert(births, clock)
	end
	local count = 0
	for _, birth in ipairs(births) do if facts.seconds - birth < duration then count = count + 1 end end
	return {
		amount = math.min(6, count), cap = 6, allowZero = true, reason = string.format("Shattering Steel: %g shards/use, one Ward per use; reload %gs, "
			.. "attack %.3fs, Ward lasts %gs.", perUse, reloadTime, 1 / rate, duration)
	}
end)
define(Stacks, "stormRainActiveArrows", "stack", "assisted", function(facts)
	local skill = facts.Find("StormRainAltX")
	if not skill or not personal(skill) then return end
	local probe = facts.Probe(skill)
	local out, stats = probe and probe.player.output, facts.Stats(skill)
	local frequency = (stats.prismatic_rain_beam_base_frequency_ms or 0) / 1000
	local rate = out and (out.Speed or 0) * policy.Activity(facts.context, out) or 0 -- Speed remains attack rate; HitSpeed can be beams
	local duration = (stats.storm_rain_pulse_count or 0) * frequency / math.max(0.01, calcLib.mod(skill.skillModList, skill.skillCfg, "StormRainBeamFrequency"))
	local cap = skill.skillModList:Sum("BASE", skill.skillCfg, "StormRainAllowedStormArrows")
	if rate > 0 and duration > 0 and cap > 0 and (out.ProjectileCount or 0) > 0 then
		return {
			rate = rate, perEvent = out.ProjectileCount, duration = duration, cap = cap, allowZero = true,
			reason = string.format("Conduit: %.3f attacks/s, %g arrows each, lifetime %.3fs, cap %g.", rate, out.ProjectileCount, duration, cap)
		}
	end
end)
define(Stacks, "multiplierEnsnaredStackCount", "stack", "assisted", function(facts)
	local skill = facts.Find("EnsnaringArrow")
	if not skill or not personal(skill) then return end
	local probe = facts.Probe(skill)
	local out, cap = probe and probe.player.output, facts.Stats(skill).tethering_arrow_display_rope_limit or 0
	if out and cap > 0 and policy.HitRate(facts.context, out) > 0 then
		return {
			rate = policy.HitRate(facts.context, out), cap = cap, allowZero = true, reason = "Ensnaring Arrow: cap " .. cap .. "."
		}
	end
end)
define(Stacks, "multiplierBarnacleStacks", "stack", "assisted", function(facts)
	if not facts.env.player.modDB:Flag(nil, "CanInflictBarnacles") then return end
	for _, line in ipairs(facts.Lines()) do
		if line.text:match("^inflict barnacles on .- every second$") then
			return {
				rate = 1, duration = 30, cap = 10, allowZero = true, reason = line.source .. "\nOne per second, lasting 30s, cap 10."
			}
		end
	end
end)
define(Stacks, "HoarfrostStacks", "stack", "assisted", function(facts)
	local main, out, enemy = facts.context.mainSkill, facts.env.player.output, facts.env.enemy.modDB
	if not facts.MainHit() or not main.skillModList:Flag(main.skillCfg, "HitsCanInflictHoarfrost")
		or enemy:Flag(nil, "FreezeImmune", "ElementalAilmentImmune") then
		return
	end
	local ratio, durationMod = out.FreezeHitThresholdRatio or 0, out.FreezeDurationMod or 0
	local avoid = math.min(100, enemy:Sum("BASE", nil, "AvoidFreeze", "AvoidAilments", "AvoidElementalAilments"))
	local rate = policy.HitRate(facts.context, out) * (out.FreezeChance or 0) / 100 * (1 - avoid / 100)
	if facts.env.configInput.ailmentMode == "CRIT" or main.skillModList:Flag(main.skillCfg, "AilmentsOnlyFromCrit") then
		rate = math.min(rate, policy.HitRate(facts.context, out) * (out.CritChance or 0) / 100 * (out.FreezeChanceOnCrit or 0) / 100 * (1 - avoid / 100))
	end
	if ratio <= 0 or durationMod <= 0 or rate <= 0 then return end
	return {
		rate = rate, duration = 10, refresh = true,
		beforeEvent = function(count) if ratio * (durationMod + count * 0.2) / durationMod >= 1 then return "reset" end end, allowZero = true,
		reason = string.format("Hoarfrost: %.3f Freeze attempts/s; each failed Freeze adds one, a Freeze removes all.", rate)
	}
end)

local function soulCap(actor)
	return actor.modDB:Override(nil, "SoulEaterMax") or actor.modDB:Sum("BASE", nil, "SoulEaterMax")
end
define(Stacks, "multiplierSoulEater", "stack", "assisted", function(facts)
	local deathRate = nearbyDeathRate(facts)
	if deathRate <= 0 then return end
	local cap = soulCap(facts.env.player)
	if cap <= 0 then return end
	for _, line in ipairs(facts.Paragraphs()) do
		if line.text:find("gain soul eater during any flask effect", 1, true) and facts.env.player.modDB:Flag(nil, "Condition:CanHaveSoulEater") then
			local duration
			for _, item in ipairs(model.ActiveFlasks(facts.env)) do
				local length = (item.flaskData.duration or 0) * calcLib.mod(facts.env.player.modDB, nil, "FlaskDuration")
				if length > 0 then duration = duration and math.min(duration, length) or length end
			end
			if duration and facts.seconds < duration then
				return {
					rate = deathRate, cap = cap, allowZero = true, reason = line.source .. "\nActive flask for " .. duration .. "s; one Soul per nearby "
						.. "death, cap " .. cap .. "."
				}
			end
		end
		local duration = tonumber(line.text:match("gain soul eater for (%d+) seconds when you use a vaal skill"))
		if duration then
			for _, skill in ipairs(facts.Active()) do
				if personal(skill) and skill.skillTypes[SkillType.Vaal] then
					local probe = facts.Probe(skill)
					local start = probe and probe.player.output.Time or skill.activeEffect.grantedEffect.castTime or 0
					local lifetime = duration / math.max(1, calcLib.mod(facts.env.player.modDB, nil, "BuffExpireFaster"))
					if facts.seconds >= start and facts.seconds - start < lifetime then
						return {
							rate = deathRate, first = start + 1 / deathRate, cap = cap, allowZero = true,
							requires = { "multiplierUsedVaalSkillInPast8Seconds" }, reason = line.source .. "\nVaal skill "
								.. skill.activeEffect.grantedEffect.name .. "; one Soul per nearby death, cap " .. cap .. "."
						}
					end
				end
			end
		end
	end
end)
define(Stacks, "multiplierMinionSoulEater", "stack", "assisted", function(facts)
	local deathRate = policy.KillRate(facts.context, "minion")
	if deathRate <= 0 then return end
	local actor, skill = facts.env.minion, facts.context.mainSkill
	if not actor or actor.hostile or (actor.output.TotalDPS or 0) <= 0 or not actor.modDB:Flag(nil, "Condition:CanHaveSoulEater") then return end
	local cap = soulCap(actor)
	if cap <= 0 then cap = data.characterConstants.soul_eater_maximum_stacks end
	if skill.activeEffect.grantedEffect.id:match("^RaiseSpectre") and facts.env.player.modDB:Flag(nil, "Condition:MinionCanHaveSoulEater")
		and facts.seconds >= 1 / deathRate and facts.seconds < 20 + 1 / deathRate then
		return { rate = deathRate, first = 2 / deathRate, cap = cap, allowZero = true, reason = reasons.multiplierMinionSoulEater }
	end
end)

for _, entry in ipairs({ { "raiseSpectreBladeVortexBladeCount", { DemonModularBladeVortexSpectre = true, GhostPirateBladeVortexSpectre = true }, false },
	{ "raiseSpectreKaomFireBeamTotemStage", { KaomFireBeamTotemSpectre = true }, true } }) do
	local var, ids, ray = unpack(entry)
	define(Stacks, var, "stack", "assisted", function(facts)
		local actor = facts.env.minion
		if not actor or actor.hostile then return end
		local skill, out = actor.mainSkill, actor.output
		if not ids[skill.activeEffect.grantedEffect.id] then return end
		local stats = facts.Stats(skill)
		local rate = out.CastRate or out.Speed or 0
		local duration = out.Duration or 0
		local cap = ray and 8 or stats.maximum_number_of_spinning_blades or 0
		if rate > 0 and duration > 0 and cap > 0 then
			return {
				rate = rate, duration = duration, cap = cap, allowZero = true, reason = string.format("Your %s uses %s: %.3f/s, lasting %gs, cap %g.",
					actor.minionData.name, skill.activeEffect.grantedEffect.name, rate, duration, cap)
			}
		end
	end)
end

local function hitType(out, name)
	return (out[name .. "HitAverage"] or 0) + ((out.MainHand or { })[name .. "HitAverage"] or 0) + ((out.OffHand or { })[name .. "HitAverage"] or 0)
end
for _, entry in ipairs({ { "configResonanceCount", "SupportTrinity", { Fire = true, Cold = true, Lightning = true } },
	{ "configUnholyResonanceCount", "SupportUnholyTrinity", { Physical = true, Lightning = true, Chaos = true } } }) do
	local var, id, allowed = unpack(entry)
	define(Stacks, var, "amount", "automatic", function(facts)
		local pure, instances, uncertain = { }, { }, false
		for _, skill in ipairs(facts.Active()) do
			if personal(skill) and facts.Applied(skill, id) then
				local probe = facts.Probe(skill)
				local out = probe and probe.player.output
				if out and policy.HitRate(facts.context, out) > 0 then
					local highest, count = nil, 0
					for _, kind in ipairs({ "Physical", "Fire", "Cold", "Lightning", "Chaos" }) do
						if hitType(out, kind) > 0 then highest, count = kind, count + 1 end
					end
					if count == 1 and allowed[highest] then
						local rate = useRate(facts.context, skill, out)
						local info = { type = highest, skill = skill, out = out, time = rate > 0 and 1 / rate or math.huge }
						pure[highest] = pure[highest] or info; t_insert(instances, info)
					else uncertain = true end
				end
			end
		end
		local types = { }; for kind in pairs(pure) do t_insert(types, kind) end; table.sort(types)
		if #types == 1 and not uncertain and #instances > 0 then
			return {
				amount = 0, allowZero = true, reason = "Your supported hits deal only " .. types[1] .. " damage, so the lowest count is zero."
			}
		end
		for i = 1, #types do for j = i + 1, #types do
			local a, b = pure[types[i]], pure[types[j]]
			local cycle = a.time + b.time
			if cycle > 0 and cycle <= 2 and facts.seconds >= cycle then
				local cycles = math.ceil(facts.seconds / cycle)
				local out = facts.env.player.output
				local manaCost, lifeCost = (a.out.ManaCost or 0) + (b.out.ManaCost or 0), (a.out.LifeCost or 0) + (b.out.LifeCost or 0)
				local manaBudget = (out.ManaUnreserved or 0) + math.max(0, out.ManaRegenRecovery or 0) * facts.seconds
				local lifeBudget = (out.LifeUnreserved or 0) - 1 + math.max(0, out.LifeRegenRecovery or 0) * facts.seconds
				local initialAffordable = manaCost <= (out.ManaUnreserved or 0) and lifeCost < (out.LifeUnreserved or 0)
				if initialAffordable and not facts.env.player.modDB:Flag(nil, "EnergyShieldProtectsMana") and manaCost * cycles <= manaBudget
					and lifeCost * cycles <= lifeBudget then
					return {
						amount = math.min(50, 25 * (facts.seconds - cycle)), cap = 50, allowZero = true, review = true,
						reason = string.format("Alternate %s %s and %s %s: %.3fs rotation, %g affordable; 25/s, cap 50.", a.type,
							a.skill.activeEffect.grantedEffect.name, b.type, b.skill.activeEffect.grantedEffect.name, cycle, cycles)
					}
				end
			end
		end end
	end)
end

define(Stacks, "witchhuntersPyreBurningDebuffs", "amount", "assisted", function(facts)
	local pyre = false
	for _, skill in ipairs(facts.Active()) do if skill.activeEffect.grantedEffect.name == "Witchhunter's Pyre" then pyre = true end end
	if not pyre then return end
	local seen, sources = { }, { }
	if facts.Ailment("Ignite") then seen.Ignite = true; t_insert(sources, "one verified personal Ignite") end
	local families = {
		RighteousFire = "Righteous Fire", VaalRighteousFire = "Vaal Righteous Fire", FireTrap = "Fire Trap burning ground", ScorchingRay = "Scorching Ray",
		SearingBond = "Searing Bond", FireWall = "Fire Wall"
	}
	for _, skill in ipairs(facts.Active()) do
		local base = skill.activeEffect.grantedEffect.id:gsub("Alt.*$", "")
		local family = families[base]
		if family and not seen[family] then
			local probe = facts.Probe(skill)
			if probe and (probe.player.output.FireDot or 0) > 0 then seen[family] = true; t_insert(sources, family) end
		end
	end
	if #sources > 0 then
		return {
			amount = #sources, reason = "Witchhunter's Pyre burns: " .. table.concat(sources, ", ") .. "."
		}
	end
end)
define(Stacks, "multiplierEnemyHallowingFlame", "stack", "assisted", function(facts)
	local main, db = facts.context.mainSkill, facts.env.player.modDB
	if not facts.MainHit() or not db:Flag(nil, "Condition:CanInflictHallowingFlame") then return end
	-- The native counter starts with one Flame; sources can add to that limit.
	local cap = 1 + db:Sum("BASE", nil, "Multiplier:HallowingFlameMax")
	if facts.Applied(main, "SupportHallow") and main.skillTypes[SkillType.Melee] then
		local duration = (effectStats(facts.Applied(main, "SupportHallow")).hallowing_flame_duration_ms or 0) / 1000
		if duration > 0 then
			return {
				rate = policy.HitRate(facts.context, facts.env.player.output), duration = duration, cap = cap, requires = { "conditionEnemyHallowingFlame" },
				reason = "Hallow on your melee attack: Flames last " .. duration .. "s, limit " .. cap .. "."
			}
		end
	end
	for _, line in ipairs(facts.Lines()) do
		local melee = line.text == "inflict hallowing flame on melee hit" and main.skillTypes[SkillType.Melee]
		local weapon = line.text == "attacks with this weapon inflict hallowing flame on hit" and main.skillTypes[SkillType.Attack]
		if weapon then
			local slot = line.source:match("^(.-):")
			weapon = slot == "Weapon 1" and main.skillFlags.weapon1Attack or slot == "Weapon 2" and main.skillFlags.weapon2Attack
		end
		if melee or weapon then
			return {
				rate = policy.HitRate(facts.context, facts.env.player.output), duration = 6, cap = cap, requires = { "conditionEnemyHallowingFlame" },
				reason = line.source .. "\nFlames last 6s, limit " .. cap .. "."
			}
		end
	end
end)

-- ============================================================================
-- Rule text
-- ============================================================================
-- Static reasons used by the detectors above.
reasons = {
	shockedEnemies = "Each new enemy is shocked once before it dies, at the lower of the Shock and kill rates.",
	barkskinStacks = "Barkskin gains Bark while you avoid attack hits. The pre-fight hit state is unknown; confirm the attack-free window.",
	plagueBearerState = "Your Poison skill feeds Plague Bearer. Confirm incubating Plague Value before switching to Infecting.",
	multiplierMinionSoulEater = "Your Raised Spectre has Unending Hunger. Confirm its first kill grants Soul Eater.",
}

-- Capability methods: { module, setting names, method, kind }.
for _, entry in ipairs({
	{ Events, "multiplierLifeSpentRecently multiplierManaSpentRecently", "Resource spent by your main skill." },
	{ Events, "multiplierSkillUsedRecently multiplierNonInstantSpellCastRecently", "Main-skill and spell casts." },
	{ Events, "multiplierCritRecently multiplierIgniteAppliedRecently multiplierPoisonAppliedRecently multiplierAppliedAilmentsRecently "
		.. "conditionCausedBleedingRecently conditionImpaledRecently", "Hits, crits and ailments you apply." },
	{ Events, "multiplierMineDetonatedRecently multiplierTrapTriggeredRecently conditionThrownTrapOrMineRecently conditionTotemsHitSpellRecently",
		"Your trap, mine and totem use." },
	{ Events, "conditionUsedWarcryInPast8Seconds multiplierWarcryUsedRecently", "Warcries you use yourself." },
	{ Events, "conditionCursedEnemyRecently conditionCastMarkRecently", "Curses and marks you cast." },
	{ Events, "conditionSpawnedCorpseRecently conditionConsumedCorpseRecently conditionConsumedCorpseInPast2Sec multiplierCorpseConsumedRecently",
		"Your corpse creation and use." },
	{ Events, "conditionUsedAmethystFlaskRecently conditionUsedRubyFlaskRecently conditionUsedSapphireFlaskRecently conditionUsedTopazFlaskRecently",
		"Your active flasks." },
	{ Events, "LostNonVaalBuffRecently minionsConditionCreatedRecently conditionMinionsDiedRecently", "Guard skills and temporary minions." },
	{ Events, "BlockedPast10Sec multiplierHitsSuppressedRecently", "Your block and suppression chance." },
	{ Mechanics, "usePowerCharges useFrenzyCharges useEnduranceCharges overridePowerCharges overrideFrenzyCharges overrideEnduranceCharges "
		.. "conditionGainedPowerChargeRecently conditionGainedFrenzyChargeRecently", "Your charge generation." },
	{ Mechanics, "multiplierRage", "Your Rage generation." },
	{ Mechanics, "multiplierBleedsOnEnemy multiplierRuptureStacks multiplierCorrosionStackCount ShockStacks ScorchStacks multiplierFreezeShockIgniteOnEnemy",
		"Ailment stacks you apply." },
	{ Mechanics, "aspectOfTheSpiderWebStacks", "Your Aspect of the Spider." },
	{ Mechanics, "conditionEnemyCoveredInAsh conditionEnemyCoveredInFrost", "Your Ash or Frost source." },
	{ Mechanics, "conditionFocused conditionSoulGainPrevention MomentumSwiftnessStacks", "Your Focus, Vaal or Momentum window.", "assisted" },
	{ Mechanics, "multiplierKilledRecently multiplierTotemsKilledRecently multiplierMinionsKilledRecently multiplierRampage", "Your kill rate." },
	{ Timeline, "conditionCastLast1Seconds multiplierCastLast8Seconds multiplierChannelling", "Your main skill's casts." },
	{ Timeline, "multiplierUsedVaalSkillInPast8Seconds", "Vaal skills you use.", "assisted" },
	{ Timeline, "conditionSummonedGolemInPast8Sec conditionSummonedGolemInPast10Sec", "Golems you resummon.", "assisted" },
	{ Timeline, "conditionKilledLast3Seconds conditionKilledPoisonedLast2Seconds conditionKilledAffectedByDoT conditionShatteredEnemyRecently "
		.. "multiplierShockedEnemyKilledRecently multiplierShockedNonShockedEnemyRecently", "Your kills and the ailments on them." },
	{ Timeline, "enemyMultiplierEnemyPresenceSeconds", "Time the enemy stays near you.", "assisted" },
	{ Timeline, "arcaneCloakUsedRecentlyCheck", "Your Arcane Cloak use.", "assisted" },
}) do model.Register(entry[1], entry[2], entry[3], entry[4]) end

-- Split rules keyed by setting: { condition, confirmation, kind = ... }.
-- Buildup and Windows register directly; registry rules take the text of
-- their pending definitions.
rules = {
	overrideSpiritInfusion = { "Spirit Infusions from channelling a Spell.", "Confirm you keep channelling.", kind = "automatic" },
	overrideSpiritCharges = { "Spirit Charges you generate.", "Confirm nothing spends the charges.", kind = "automatic" },
	multiplierGaleForce = { "Gale Force from your skill use.", "Confirm you are not hit while building it.", kind = "automatic" },
	multiplierFragileRegrowth = { "Fragile Regrowth over time.", "Confirm the hit-free window.", kind = "assisted" },
	barkskinStacks = { "Bark gained while not hit by attacks.", "Confirm the attack-free window.", kind = "assisted" },
	aspectOfSolarisSunscaldStacks = { "Sunscald from Aspect of Solaris.", "Confirm the enemy stays in the area.", kind = "assisted" },
	bannerValour = { "Valour gained before planting.", "Confirm you plant the Banner after building Valour.", kind = "assisted" },
	frostShieldStages = { "Frost Shield stages paid with Energy Shield.", "Confirm you drain ES inside the shield." },
	configSnipeStages = { "Snipe stages from channelling.", "Confirm you release after this channel." },
	voltaxicBurstSpellsQueued = { "Voltaxic Burst casts queued.", "Confirm you keep casting.", kind = "automatic" },
	plagueBearerState = { "Plague Bearer with your Poison skill.", "Confirm you switch to Infecting." },
	conditionFullMana = { "Your main skill costs Mana.", "Confirm you are below full Mana." },
	minionsConditionFullEnergyShield = { "A hit removes your minion's ES.", "Confirm the minion is below full ES." },
	manabondMissingUnreservedManaPercentage = { "Mana spent on Arcane Cloak and Manabond.", "Confirm this cast order." },
	physicalAegisDepleted = { "A physical hit empties Physical Aegis.", "Confirm the hit and that Aegis is empty." },
	conditionWardBrokenPast2Seconds = { "A hit breaks your Ward.", "Confirm Ward broke in the last 2 seconds." },
	conditionStoppedTakingDamageOverTimeRecently = { "A flask removes Righteous Fire burning.", "Confirm the flask stops all DoT." },
	conditionChangedStanceLastSecond = { "Your stance-switch skill.", "Confirm you switched stance in the last second." },
	conditionLinkedRecently = { "Your Link skill.", "Confirm you linked in the last 4 seconds." },
	conditionCritWithHeraldSkillRecently = { "Crits from your Herald's own hits.", "Confirm the Herald crits in the last 4 seconds." },
	conditionTauntedEnemyRecently = { "Your Taunt from hits or Warcries.", "Confirm the Taunt reaches enemies." },
	conditionEnemyTaunted = { "A Warcry or hit that can Taunt.", "Confirm the Taunt is still active." },
	conditionKilledTauntedEnemyRecently = { "Your kills and Taunt source.", "Confirm the enemy was taunted when it died." },
	conditionLostEnduranceChargeInPast8Sec = { "Endurance Charges you gain and lose.", "Confirm a charge was lost in 8 seconds." },
	multiplierEnduranceChargesLostRecently = { "Endurance Charges you gain and lose.", "Confirm a charge was lost in 4 seconds." },
	conditionEnemyDebilitated = { "Your Debilitate source.", "Confirm the enemy is debilitated." },
	conditionTotemsNotSummonedInPastTwoSeconds = { "A totem placed at the start.", "Confirm no totem was placed in 2 seconds." },
	conditionEnemyPacified = { "Your Pacify curse.", "Confirm the curse reached 60% of its duration." },
	multiplierAffectedByWarcryBuffDuration = { "Your Warcry buff duration.", "Confirm the buff has not expired." },
	multiplierWoCExpiredDuration = { "Your Wave of Conviction duration.", "Confirm the wave was cast at the start." },
	inventionMineTrapPlacedDuration = { "Your trap or mine with Invention.", "Confirm you hold it until this age." },
	multiplierWitheredStackCountSelf = { "Wither reflected by Aspect of Arakaali.", "Confirm you keep channelling Wither." },
	multiplierManaBurnStacks = { "Mana Burn from your Tinctures.", "Confirm one activation from full Mana." },
	touchedDebuffsCount = { "Touched debuffs from Embrace Madness.", "Confirm all four Touched counts match." },
	maniaDebuffsCount = { "Mania while affected by Glorious Madness.", "Confirm Madness is active." },
	multiplierDefiance = { "Defiance from losing Life to hits.", "Confirm you take these hits and survive." },
	multiplierEnemyAffectedByGraspingVines = { "Grasping Vines during a Life Flask.", "Confirm the Life Flask is active." },
	conditionCorruptingCryStages = { "Corrupting Cry on your Warcry.", "Confirm the Warcry use and range." },
	bloodsoakedBannerStages = { "Bloodsoaked Banner after building Valour.", "Confirm you build Valour, then plant." },
	goreblossomBlooms = { "Blooms from spending Life on Spells.", "Confirm you stay near the Blooms." },
	shardsConsumed = { "Steel Shards your attack consumes.", "Confirm you reload before each use." },
	steelWards = { "Steel Wards from Shattering Steel.", "Confirm you keep reloading shards." },
	stormRainActiveArrows = { "Arrows from Storm Rain of the Conduit.", "Confirm you keep attacking." },
	multiplierEnsnaredStackCount = { "Your Ensnaring Arrow hits.", "Confirm the target stays ensnared." },
	multiplierBarnacleStacks = { "Your Barnacle source.", "Confirm the enemy stays nearby." },
	HoarfrostStacks = { "Hoarfrost from your Freeze attempts.", "Confirm your hits reach the target." },
	multiplierSoulEater = { "Your Soul Eater source and nearby deaths.", "Confirm the Soul Eater grant is active." },
	multiplierMinionSoulEater = { "Your minion's Soul Eater.", "Confirm the minion's kills and buff." },
	witchhuntersPyreBurningDebuffs = { "Distinct burning effects you apply.", "Confirm they all cover the target." },
	multiplierEnemyHallowingFlame = { "Hallowing Flame from your hits.", "Confirm no ally removes the Flames." },
}
-- Parametrised rule families, written out once per setting.
for _, entry in ipairs({ { "aspectOfLunarisLunarProtection", "Physical Damage" }, { "aspectOfLunarisLunarResistance", "Elemental Damage" } }) do
	rules[entry[1]] = { "Aspect of Lunaris stacks from taking " .. entry[2] .. ".", "Confirm you take this damage.", kind = "assisted" }
end
for id, pair in pairs(aspects) do
	for index, phase in ipairs(pair) do
		local other = pair[3 - index]
		rules[phase[1]] = { (id == "AspectOfTheCat" and "Aspect of the Cat" or "Aspect of the Avian") .. " grants " .. phase[2] .. ".",
			"Confirm the " .. phase[2] .. " window; this clears " .. other[2] .. "." }
	end
end
for _, storm in ipairs({ { "bladestormInBloodstorm", "Blood" }, { "bladestormInSandstorm", "Sand" } }) do
	rules[storm[1]] = { "Your Bladestorm creates a " .. storm[2] .. "storm.", "Confirm you stand in the " .. storm[2] .. "storm." }
end
for _, var in ipairs({ "conditionStunnedEnemyRecently", "conditionHitsAlwaysStun", "conditionEnemyStunned" }) do
	rules[var] = { "Your skill's Stun chance.", "Confirm the Stun." }
end
for _, entry in ipairs({ { "conditionFullEnergyShield", false }, { "conditionHaveEnergyShield", true } }) do
	local var, empty = unpack(entry)
	rules[var] = { empty and "A hit empties your Energy Shield." or "A hit removes some Energy Shield.", "Confirm this hit." }
end
for _, entry in ipairs({ { "MoltenShellDamageMitigated", false }, { "VaalMoltenShellDamageMitigated", true } }) do
	local var, vaal = unpack(entry)
	rules[var] = { "Damage absorbed by " .. (vaal and "Vaal Molten Shell" or "Molten Shell") .. ".", "Confirm a hit while the shield is active." }
end
for _, entry in ipairs({ { "conditionEnergyShieldRechargeRecently", 4 }, { "conditionEnergyShieldRechargePastTwoSec", 2 } }) do
	local var, recent = unpack(entry)
	rules[var] = { "A hit removes ES and recharge starts.", "Confirm recharge started in the last " .. recent .. " seconds." }
end
for _, entry in ipairs({ { "conditionStunnedRecently", false }, { "conditionStunnedWhileCastingRecently", true } }) do
	local var, casting = unpack(entry)
	rules[var] = { "Your chance to be stunned.", "Confirm you were stunned" .. (casting and " while casting" or "") .. " in 4 seconds." }
end
for _, target in ipairs({ 8, 12 }) do
	rules["conditionConsumed" .. target .. "SteelShardsRecently"] = { "Call of Steel and your shard-using attack.",
		"Confirm you used " .. target .. " shards in 4 seconds." }
end
for _, ailment in ipairs({
	{ "conditionIgnited", "Ignite" }, { "conditionChilled", "Chill" }, { "conditionFrozen", "Freeze" },
	{ "conditionShocked", "Shock" }, { "conditionScorched", "Scorch" }, { "conditionBrittle", "Brittle" }, { "conditionSapped", "Sap" },
}) do
	local var, name = unpack(ailment)
	rules[var] = { "Your ailment reflection and " .. name .. ".", "Confirm the " .. name .. " affects you." }
end
for _, fraction in ipairs({ { "BrandsInLastHalf", 0.5 }, { "BrandsInLastQuarter", 0.75 } }) do
	local var, threshold = unpack(fraction)
	rules[var] = { "Your Brand's duration.", "Confirm " .. threshold * 100 .. "% of it has elapsed." }
end
for _, var in ipairs({ "multiplierCurseExpiredOnEnemy", "multiplierCurseDurationExpiredOnEnemy" }) do
	rules[var] = { "Your curse's duration.", "Confirm the curse was not refreshed." }
end
for _, entry in ipairs({ { "multiplierChilledByYouSeconds", "Chill" }, { "multiplierFrozenByYouSeconds", "Freeze" } }) do
	local var, name = unpack(entry)
	rules[var] = { "Your own " .. name .. " hits.", "Confirm you keep applying " .. name .. "." }
end
for _, entry in ipairs({ { "cinderflameStacks", 10, false }, { "weepingBlackStacks", 5, true } }) do
	local var, cap, impaled = unpack(entry)
	rules[var] = { (impaled and "Tears of Rot" or "Cinders") .. " from your bow hits, up to " .. cap .. ".", "Confirm your hits reach the target." }
end
for _, var in ipairs({ "raiseSpectreBladeVortexBladeCount", "raiseSpectreKaomFireBeamTotemStage" }) do
	rules[var] = { "Your selected spectre's skill.", "Confirm the spectre keeps using it." }
end
for _, var in ipairs({ "configResonanceCount", "configUnholyResonanceCount" }) do
	rules[var] = { "Damage types of your supported skills.", "Confirm you alternate skills." }
end

-- Registration. Buildup and Windows publish split rules directly; the
-- registries define their pending evaluators with the matching text.
for _, var in ipairs({ "overrideSpiritInfusion", "overrideSpiritCharges", "multiplierGaleForce", "multiplierFragileRegrowth", "barkskinStacks",
	"aspectOfSolarisSunscaldStacks", "aspectOfLunarisLunarProtection", "aspectOfLunarisLunarResistance", "bannerValour" }) do
	model.RegisterRule(Buildup, var, rules[var][1], rules[var][2], rules[var].kind)
end
for _, var in ipairs({ "aspectOfTheAvianAviansMight", "aspectOfTheAvianAviansFlight", "aspectOfTheCatCatsStealth", "aspectOfTheCatCatsAgility",
	"frostShieldStages", "configSnipeStages", "voltaxicBurstSpellsQueued", "plagueBearerState", "bladestormInBloodstorm", "bladestormInSandstorm" }) do
	model.RegisterRule(Windows, var, rules[var][1], rules[var][2], rules[var].kind)
end
for _, entry in ipairs(pending) do
	local text = assert(rules[entry.var], "Missing rule text: " .. entry.var)
	entry.registry.Define({ var = entry.var, model = entry.model, kind = entry.kind, condition = text[1], confirmation = text[2], evaluate = entry.evaluate })
end

return M
