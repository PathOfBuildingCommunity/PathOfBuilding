-- Path of Building
--
-- Build-evidence rules for Auto-configure: Advanced, Guided, Quests, Ground,
-- Shrines, Choices, Minions, Position and Batch. Each family is a table on the
-- returned module; ConfigAutoScan runs their Detect passes and ConfigAutoInventory
-- reads their capabilities and rule text. Depends on ConfigAutoModel and
-- ConfigVisibility and ConfigAutoRulesCombat (Mechanics); popups live in ConfigAutoUI.
local model = require("Modules.ConfigAutoModel")
local policy = model.Policy
local visibility = require("Modules.ConfigVisibility")
local byName = model.optionsByName
local t_insert = table.insert
local mechanics = require("Modules.ConfigAutoRulesCombat").Mechanics
local M = { }

local skillEnabled = model.SkillEnabled

-- ============================================================================
-- Rule text: the long condition, confirmation and reason prose, keyed by the
-- setting var (or by the family for rules defined in a loop). Registration
-- below reads it at load, so it precedes the families.
-- ============================================================================
local text = {
	sigilOfPowerStages = {
		method = "Uses Sigil stages from your mana spent.",
	},
	resistancePenalty = {
		condition = "Uses PoB's estimated Act; confirm it.",
	},
	profaneGroundOccupant = {
		condition = "Needs a modifier explicitly making your Profane Ground affect you and allies.",
	},
	conditionEnemyChilledByYourHits = {
		condition = "Your own hits must Chill the enemy.",
	},
	shrineBuff = {
		confirmation = "Choose the buff you got; confirm it.",
	},
	bloodSandStance = {
		condition = "Needs a stance-switching skill.",
	},
	doomBlastSource = {
		condition = "Needs a Hex with Impending Doom.",
		confirmation = "Confirm what ends your curses.",
	},
	divineSentinel = {
		condition = "Needs Divine Sentinel on a Sentinel.",
		confirmation = "Confirm this aura reaches you.",
	},
	linkedSourceRate = {
		condition = "Needs Intuitive Link and a minion.",
		confirmation = "Confirm the minion you stay linked to.",
	},
	conditionEnemyBlinded = {
		condition = "Blind from a source or your hits.",
	},
	overrideBuffBlinded = {
		condition = "Needs a real Blind source.",
		confirmation = "Confirm clearing your Blind value.",
	},
	waitForMaxSeals = {
		condition = "Needs Unleash on your main skill.",
		confirmation = "Confirm how you cast with Unleash.",
	},
	repeatMode = {
		condition = "Needs a main skill that repeats.",
		confirmation = "Confirm full repeat cycles.",
	},
	ruthlessSupportMode = {
		condition = "Needs Ruthless on your main skill.",
		confirmation = "Confirm your attack rotation.",
	},
	bypassCooldown = {
		confirmation = "Confirm you can sustain the charges.",
	},
	darkPactSkeletonLife = {
		condition = "Uses your Skeleton's calculated Life.",
		confirmation = "Confirm which Skeleton you target.",
	},
	carrionGolemNearbyMinion = {
		condition = "Counts your other minions.",
	},
	raiseSpectreEnableBuffs = {
		condition = "Needs a spectre with a Buff or Aura.",
	},
	raiseSpidersSpiderCount = {
		condition = "Two Spiders per kill trigger.",
		confirmation = "Confirm your kills and corpses.",
	},
	ActiveBrands = {
		condition = "Counts your active Brands.",
	},
	conditionMoving = {
		condition = "PoB derives Moving from a real source.",
	},
	conditionStationary = {
		condition = "Main skill cast or channelled in place.",
	},
	multiplierNearbyAlly = {
		condition = "Counts your maintained minions.",
		confirmation = "Confirm these minions stay near you.",
	},
	multiplierNearbyCorpse = {
		condition = "Counts corpses your skill creates.",
		confirmation = "Confirm the corpses land nearby.",
	},
	multiplierLinkedTargets = {
		condition = "Needs a Link skill and a minion.",
		confirmation = "Confirm one linked minion.",
	},
	linkedTargetPosition = {
		condition = "Needs a Link skill and a target.",
		confirmation = "Confirm the Link and enemy position.",
	},
	conditionAtCloseRange = {
		condition = "Needs a melee Strike main skill.",
		confirmation = "Confirm you attack at close range.",
	},
	tornadoShotSecondaryHitChance = {
		condition = "Tornado Shot uses PoB's average.",
		confirmation = "Confirm PoB's average hit chance.",
	},
	incomingEvent = {
		confirmation = "Assumes regular enemy hits.",
	},
	conditionBeenSavageHitRecently = {
		condition = "A hit must take 15% of your Life.",
		confirmation = "Confirm such a hit happened recently.",
	},
	buffConflux = {
		condition = "Needs a timed Conflux source.",
	},
}

-- ============================================================================
-- Advanced: source-backed rules shared by the scanner and its UI inventory
-- ============================================================================
local Advanced = { capabilities = { }, neutralInputs = { } }
local function capability(names, kind, method)
	for name in names:gmatch("%S+") do
		Advanced.capabilities[name] = { kind = kind, method = method }
		Advanced.neutralInputs[name] = true
	end
end

local ailments = {
	{ name = "Chill", condition = "conditionEnemyChilled", magnitude = "conditionEnemyChilledEffect", recent = "conditionChilledEnemyRecently" },
	{ name = "Shock", condition = "conditionEnemyShocked", magnitude = "conditionShockEffect", recent = "conditionShockedEnemyRecently" },
	{ name = "Scorch", condition = "conditionEnemyScorched", magnitude = "conditionScorchedEffect" },
	{ name = "Brittle", condition = "conditionEnemyBrittle", magnitude = "conditionBrittleEffect" },
	{ name = "Sap", condition = "conditionEnemySapped", magnitude = "conditionSapEffect" },
}
for _, rule in ipairs(ailments) do
	capability(rule.condition .. " " .. rule.magnitude .. (rule.recent and (" " .. rule.recent) or ""), "automatic",
		"Uses PoB's ailment estimate.")
end
capability("conditionEnemyFrozen conditionFrozenEnemyRecently", "automatic",
	"Uses PoB's freeze threshold.")
capability("multiplierPoisonOnEnemy", "automatic",
	"Uses PoB's expected poison stacks.")

-- Each entry names a real active skill or an actually applied support. The
-- question describes the missing action/position instead of treating a socketed
-- gem, or a bonus conditional on a buff, as proof of activation.
local skillQuestions = {
	{ skills = { "Dread Banner", "War Banner", "Defiance Banner" }, var = "bannerPlanted", question = "Do you fight inside your banner?" },
	{ skills = { "Unbound Avatar" }, var = "Unbound", question = "Include the Unbound window?" },
	{ skills = { "Embrace Madness" }, var = "embraceMadnessActive", question = "Do you activate Embrace Madness?" },
	{ skills = { "Gluttony" }, var = "Disgorged", question = "Include Gluttony's Disgorge window?" },
	{ skills = { "Summon Greater Harbinger of Time" }, var = "greaterHarbingerOfTimeSlipstream", question = "Are you in your Slipstream?" },
	{ skills = { "Summon Harbinger of Time" }, var = "harbingerOfTimeSlipstream", question = "Are you in your Harbinger's Slipstream?" },
	{ skills = { "Fresh Meat" }, var = "freshMeatBuffs", minion = true,
		question = "Are minions in Fresh Meat's window?" },
	{ skills = { "Meat Shield" }, var = "meatShieldEnemyNearYou", minion = true, question = "Does your minion fight near you?" },
	{ skills = { "Eldritch Blasphemy" }, var = "conditionEnemyMalignantMadness", question = "Is this enemy in Malignant Madness?" },
	{ skills = { "Misty Reflection" }, var = "enemyHitMistyReflection", question = "Does Misty Reflection hit this enemy?" },
	{ skills = { "Summon Elemental Relic" }, var = "summonElementalRelicEnableAngerAura", question = "Is an Anger relic active near you?" },
	{ skills = { "Summon Elemental Relic" }, var = "summonElementalRelicEnableHatredAura", question = "Is a Hatred relic active near you?" },
	{ skills = { "Summon Elemental Relic" }, var = "summonElementalRelicEnableWrathAura", question = "Is a Wrath relic active near you?" },
	{ skills = { "Summon Holy Relic" }, var = "summonHolyRelicEnableHolyRelicBoon", question = "Is your Holy Relic's Boon on you?" },
	{ skills = { "Raise Spectre" }, var = "conditionSummonedSpectreInPast8Sec", question = "Do you resummon a spectre every 8s?" },
	{ skills = { "Raise Zombie" }, var = "conditionSummonedZombieInPast8Sec", question = "Do you resummon a zombie every 8s?" },
	{ skills = { "Summon Reaper" }, var = "summonReaperConsumeRecently", needsMinion = true,
		question = "Does your Reaper consume a minion?" },
	{ skills = { "Flame Wall" }, var = "flameWallAddedDamage", projectile = true, question = "Do projectiles pass through Flame Wall?" },
	{ skills = { "Ice Nova of Frostbolts" }, var = "iceNovaCastOnFrostbolt", other = "Frostbolt", question = "Do you cast Ice Nova on Frostbolts?" },
	{ skills = { "Vortex of Projection" }, var = "vortexCastOnFrostbolt", other = "Frostbolt", question = "Do you cast Vortex on your Frostbolts?" },
	{ skills = { "Animate Weapon", "Animate Weapon of Ranged Arms" }, var = "animateWeaponLingeringBlade", otherBlade = true,
		question = "Do you animate your Lingering Blades?" },
	{ skills = { "Pride" }, var = "prideEffect", value = "MAX", question = "Does the enemy stay in Pride for 4s?" },
	{ skills = { "Righteous Fire", "Scorching Ray" }, var = "enemyInRFOrScorchingRay",
		question = "Is the enemy in RF or Scorching Ray?" },
}
Advanced.skillQuestions = skillQuestions
for _, rule in ipairs(skillQuestions) do
	capability(rule.var, "assisted", "Verify an enabled " .. table.concat(rule.skills, " / ") .. " skill; confirm: "
		.. rule.question)
end
capability("channellingCycloneCheck", "automatic", "Detects self-used Cyclone.")
capability("useSiphoningCharges useChallengerCharges useBlitzCharges minionsUsePowerCharges minionsUseFrenzyCharges minionsUseEnduranceCharges buffHerEmbrace "
	.. "buffDivinity conditionChampionIntimidate conditionInsane changedStance linkedToMinion", "assisted",
	"Needs a source; confirm the window.")
capability("intensifyIntensity", "assisted", "Stages from your cast rate; stay still.")
capability("OverloadedIntensity", "assisted", "Confirm losing six Intensity recently.")
capability("multiplierWitheredStackCount", "assisted", "Stacks from your Wither sources.")
capability("sigilOfPowerStages", "assisted", text.sigilOfPowerStages.method)
capability("conditionSacrificeMinion conditionBleeding conditionPoisoned multiplierPoisonOnSelf", "assisted", "Needs the exact source; confirm use.")


function Advanced.Detect(context)
	local env, emit = context.env, context.suggest
	local actor = env.minion or env.player
	local output, skill = actor.output, actor.mainSkill
	local ownerOutput = env.player.output
	local mainEnabled = skillEnabled(context.mainSkill)
	local rate = mainEnabled and policy.HitRate(context, output) or 0
	local name = context.mainSkill.activeEffect.grantedEffect.name .. (env.minion and " minion" or "")
	local selfHit = context.selfHit and not env.minion
	local seconds = policy.FightSeconds(context)
	-- A chilling area left by a travel skill only covers the target while that
	-- skill is reused before its ground expires. When such a skill alone accounts
	-- for the independent source, its use rate decides instead.
	local travel = { }
	for _, active in ipairs(env.player.activeSkillList) do
		if skillEnabled(active) and active.skillTypes[SkillType.Travel] then travel[active.activeEffect.grantedEffect.name] = active end
	end
	local function travelSource(ailment, guaranteed)
		local best, source = 0, nil
		for _, value in ipairs(env.player.modDB:Tabulate("BASE", nil, ailment .. "Override")) do
			local active = travel[value.mod.source]
			if active and value.value > best then best, source = value.value, active end
		end
		if source and best * calcLib.mod(env.enemy.modDB, nil, "Self" .. ailment .. "Effect") >= guaranteed then
			local probe = context.probeSkill(source)
			local out = probe and probe.player.output or { }
			local interval = out.Cooldown or out.Time or 0
			return source.activeEffect.grantedEffect.name, policy.Refresh(context.settings, interval > 0 and 1 / interval or 0, out.Duration or 0, seconds)
		end
	end
	for _, rule in ipairs(ailments) do
		local ailment = rule.name
		if not model.AilmentImmune(env, ailment) then
			local guaranteed = math.max(ownerOutput[ailment .. "IndependentSourceEffect"] or 0, output[ailment .. "IndependentSourceEffect"] or 0)
			local hitEstimate = output[ailment .. "HitEffectEstimate"] or 0
			local chance = output[ailment .. "Chance"] or (ailment == "Chill" and hitEstimate > 0 and 100 or 0)
			local critOnly = (output[ailment .. "EstimateUsesCrit"] or 0) > 0
			if critOnly then chance = math.min(chance, output.CritChance or 0) end
			local frequency = chance / 100 * rate
			-- The hit estimate only counts when the main source actually lands hits;
			-- a disabled, non-hitting or idle skill leaves the independent source alone.
			local estimate = (mainEnabled and skill.skillFlags.hit and frequency > 0) and hitEstimate or 0
			local magnitude = math.max(guaranteed, estimate)
			if magnitude > 0 then
				local usesEstimate = estimate > guaranteed
				local assumption = usesEstimate and policy.Refresh(context.settings, frequency, output[ailment .. "Duration"] or 0, seconds) or nil
				local frequent = not usesEstimate or (not critOnly and assumption.automatic)
				local reason = guaranteed > 0 and ("PoB derives an independent " .. ailment .. " source of " .. guaranteed .. "%.") or ""
				local travelName, travelUse
				if not usesEstimate then travelName, travelUse = travelSource(ailment, guaranteed) end
				if travelName then
					assumption, frequent = travelUse, travelUse.automatic
					reason = reason .. " Its source is the travel skill " .. travelName .. ", reused before its area expires."
				end
				if usesEstimate then
					reason = reason .. (guaranteed > 0 and "\n" or "") .. "Main damage source: " .. name .. ". PoB estimates " .. estimate .. "% "
						.. ailment:lower()
						.. " from your damage and its threshold."
						.. (guaranteed > 0 and " This exceeds the independent source." or "")
				end
				reason = reason .. "\nActual uptime can vary."
				if not usesEstimate and not travelName and env.enemy.modDB:GetCondition(rule.condition:match("^conditionEnemy(.+)$")) then
					-- PoB already applies the state and this effect itself (Skitterbots);
					-- the checkbox would only go stale when the source is removed.
					for _, var in ipairs({ rule.condition, rule.magnitude }) do
						if context.derived and not context.derived[var] then context.derived[var] = reason end
					end
				else
					context.propose({ var = rule.condition, reason = reason, review = not frequent, assumption = assumption,
						label = frequent and ("Enemy " .. ailment:lower() .. " from your build")
							or ("Do you keep " .. ailment .. " applied during this fight?") })
					emit(rule.magnitude, reason, not frequent, ailment .. " effect: " .. magnitude .. "%", magnitude, { rule.condition })
				end
				if rule.recent and selfHit and estimate > 0 and chance > 0 then
					local assumption = policy.Rate(context.settings, frequency, math.min(seconds, 4))
					emit(rule.recent, reason .. "\nNeeds an application within 4s.", critOnly or not assumption.automatic,
						"Recently applied " .. ailment .. " with your main skill", nil, nil, assumption)
				end
			end
		end
	end
	if rate > 0 and (output.FreezeCanApply or 0) > 0 and (output.FreezeChance or 0) > 0
		and not env.enemy.modDB:Flag(nil, "FreezeImmune", "ElementalAilmentImmune") then
		local frequency = (output.FreezeChance or 0) / 100 * rate * output.FreezeCanApply
		local reason = name .. " can freeze for at least 0.3s."
		local assumption = policy.Refresh(context.settings, frequency, 0.3, seconds)
		emit("conditionEnemyFrozen", reason, not assumption.automatic, "Enemy frozen by your main damage source", nil, nil, assumption)
		if selfHit then
			local assumption = policy.Rate(context.settings, frequency, math.min(seconds, 4))
			emit("conditionFrozenEnemyRecently", reason, not assumption.automatic, "Recently froze an enemy with your main skill", nil, nil, assumption)
		end
	end
	local function poisonCount(out)
		local duration = out.PoisonDuration or 0
		if duration <= 0 then return 0 end
		return (out.PoisonStacks or 0) * math.min(1, seconds / duration) * policy.Activity(context, out, "hit")
	end
	local poisonStacks = poisonCount(output)
	if mainEnabled and skill.skillFlags.hit and poisonStacks and poisonStacks >= 1 and (output.PoisonChance or 0) > 0
		and (output.PoisonDPS or 0) > 0 and (output.PoisonDuration or 0) > 0 then
		local amount = math.floor(poisonStacks)
		local review = env.minion ~= nil or skill.skillData.showAverage or false
		local reason = "PoB calculates " .. string.format("%.2f", poisonStacks) .. " expected poison stacks for " .. name
			.. ".\nRounded down; assumes continued use."
		local assumption = policy.Refresh(context.settings, poisonStacks / math.min(seconds, output.PoisonDuration or seconds),
			math.min(seconds, output.PoisonDuration or seconds), seconds)
		emit("conditionEnemyPoisoned", reason, review or not assumption.automatic, "Enemy poisoned by your main damage source", nil, nil, assumption)
		emit("multiplierPoisonOnEnemy", reason, review, "Poison stacks from your main source: " .. amount, amount, { "conditionEnemyPoisoned" },
			policy.Scenario("Keep using your Poison skill."))
	end

	local enabled, otherMinion = { }, false
	for _, active in ipairs(env.player.activeSkillList) do
		if skillEnabled(active) then
			local effect = active.activeEffect.grantedEffect
			enabled[effect.name] = active
			if active.minion and not effect.name:match("^Summon Reaper") then otherMinion = true end
		end
	end
	for _, active in ipairs(env.player.activeSkillList) do
		if skillEnabled(active) then
			local sourceName = active.activeEffect.grantedEffect.name
			local applied = { [sourceName] = true }
			for _, effect in ipairs(active.effectList) do applied[effect.grantedEffect.name] = true end
			for _, rule in ipairs(skillQuestions) do
				local matched = false
				for _, candidate in ipairs(rule.skills) do
					if applied[candidate] or sourceName:sub(1, #candidate + 4) == candidate .. " of " then matched = true end
				end
				if matched and (not rule.minion or active.minion)
					and (not rule.needsMinion or otherMinion)
					and (not rule.projectile or context.mainSkill.skillTypes[SkillType.Projectile])
					and (not rule.other or enabled[rule.other])
					and (not rule.otherBlade or enabled.Bladefall or enabled["Ethereal Knives"]) then
					emit(rule.var, "Enabled source: " .. sourceName .. ".\n" .. rule.question
						.. "\nConfirm when this is active.", true, rule.question, rule.value)
				end
			end
			if sourceName:match("^Cyclone") and not active.skillData.triggered and not active.skillFlags.totem and not active.skillFlags.trap
				and not active.skillFlags.mine then
				local activity = active == context.mainSkill and policy.Activity(context, ownerOutput) or 1
				if activity > 0 then
					emit("channellingCycloneCheck", "Enabled self-used skill: " .. sourceName .. ".", active ~= context.mainSkill or activity < 1,
						"Channelling your Cyclone during combat")
				end
			end
			if sourceName == "Unhinge" then
				emit("conditionInsane", "Unhinge grants the Insane window.",
					true, "Include the Insane window?")
			end
			if sourceName == "Blood and Sand" or sourceName == "Flesh and Stone" then
				emit("changedStance", "Enabled stance skill: " .. sourceName .. ".\nConfirm you change stance.", true,
					"Do you change stance every 4 seconds?")
			end
			if sourceName:match(" Link$") and env.player.modDB:Flag(nil, "Condition:CanLinkToMinions") and otherMinion then
				emit("linkedToMinion", "Enabled " .. sourceName .. " can link to an eligible minion.", true,
					"Do you keep this Link on your minion?")
			end
			if sourceName == "Wither" then
				local probe = active == context.mainSkill and env or context.probeSkill(active)
				if probe then
					local out = probe.player.output
					local rate = (out.Speed or 0) * (active.skillFlags.totem and 1 or policy.Activity(context, out))
					local count = math.min(15, math.floor(rate * math.min(seconds, out.Duration or 0)))
					if count > 0 then
						emit("multiplierWitheredStackCount", "Enabled Wither: " .. string.format("%.2f", rate) .. " applications/s, "
							.. string.format("%.2f", out.Duration or 0) .. "s duration, " .. seconds .. "s window; capped at 15.", true, "Maintain " .. count
							.. " Withered stacks using Wither?", count)
					end
				end
			end
			if sourceName == "Sigil of Power" and not env.player.modDB:Flag(nil, "EnergyShieldProtectsMana") then
				local stats = calcLib.buildSkillInstanceStats(active.activeEffect, active.activeEffect.grantedEffect)
				local threshold = stats.base_circle_of_power_mana_spend_per_upgrade or 0
				local cap = stats.circle_of_power_max_stages or 0
				local probe = context.probeSkill(active)
				local time = math.min(seconds, probe and probe.player.output.Duration or 0)
				local spending = (env.player.output.ManaPerSecondCost or 0) * policy.Activity(context, env.player.output)
				if threshold > 0 and cap > 0 and spending > 0 and time > 0 then
					local count = math.min(cap, 1 + math.floor(time * math.min(1, spending / threshold)))
					emit("sigilOfPowerStages", "Enabled Sigil of Power: " .. threshold .. " mana per new stage, maximum " .. cap .. ".\nMain skill spends "
						.. string.format("%.2f", spending) .. " mana/s over "
						.. seconds .. "s.", true, "Build " .. count
						.. " Sigil stages while fighting inside it?", count)
				end
			end
		end
	end
	local main = context.mainSkill
	local mainOutput = env.player.output
	local activity = policy.Activity(context, mainOutput)
	local selfCast = mainEnabled and activity > 0 and not main.skillData.triggered and not main.skillFlags.totem and not main.skillFlags.trap
		and not main.skillFlags.mine and not main.minion
	if selfCast and main.skillTypes[SkillType.GainsIntensity] then
		local casts = math.floor((mainOutput.Speed or 0) / math.max(1, mainOutput.Repeats or 1) * seconds * activity)
		local cap = main.skillModList:Sum("BASE", main.skillCfg, "Multiplier:IntensityLimit")
		local count = math.min(cap, casts)
		if count > 0 then
			emit("intensifyIntensity", "Your main skill gains Intensity.\n" .. seconds .. "s of casting, capped at " .. cap
				.. ". Moving removes it.", true, "Stand still and build " .. count .. " Intensity?", count)
		end
		for _, effect in ipairs(main.effectList) do
			if effect.grantedEffect.id == "SupportOverloadedIntensity" then
				local stats = calcLib.buildSkillInstanceStats(effect, effect.grantedEffect)
				local duration = (stats.gain_overloaded_intensity_for_x_ms_after_losing_6_intensity or 0) / 1000
				emit("OverloadedIntensity", "Overloaded Intensity: one stack for " .. duration
					.. " seconds.", true,
					"Include 1 Overloaded Intensity after losing six Intensity in the past " .. duration .. " seconds?", 1)
			end
		end
	end
	for _, effect in ipairs(skill.effectList) do
		if effect.grantedEffect.id == "SupportWitheringTouch" and skill.skillFlags.hit then
			local stats = calcLib.buildSkillInstanceStats(effect, effect.grantedEffect)
			local duration = (stats.support_withered_base_duration_ms or 0) / 1000 * calcLib.mod(skill.skillModList, skill.skillCfg, "Duration")
			local count = math.min(15, math.floor(rate * (stats["withered_on_hit_chance_%"] or 0) / 100 * math.min(seconds, duration)))
			if count > 0 then
				emit("multiplierWitheredStackCount", "Applied Withering Touch on " .. name
					.. ".\nUses hit rate and chance within " .. seconds
					.. "s; capped at 15.", true, "Maintain approximately " .. count
					.. " Withered stacks from Withering Touch?", count)
			end
		end
	end
	for _, line in ipairs(context.lines) do
		local text = model.NormalizeLine(line.text)
		local reason = line.source .. "\n" .. line.text .. "\nConfirm the trigger and duration."
		local siphoningChance = tonumber(text:match("^([%d%.]+)%% chance to gain a siphoning charge when you use a skill$")) or 0
		local challengerChance = tonumber(text:match("^([%d%.]+)%% chance to gain a challenger charge when you hit a rare or unique enemy while in blood "
			.. "stance$")) or 0
		if siphoningChance > 0 and selfCast then
			emit("useSiphoningCharges", reason, true, "Use Siphoning Charges from skill use?")
		elseif text == "gain a blitz charge on critical strike" and context.selfHit and (mainOutput.CritChance or 0) > 0 then
			emit("useBlitzCharges", reason, true, "Use Blitz Charges from your crits?")
		elseif challengerChance > 0 and context.selfHit then
			emit("useChallengerCharges", reason, true, "Use Challenger Charges (Blood Stance)?")
		elseif text:match("^gain a challenger charge when you kill an enemy while in sand stance$") and policy.KillRate(context, "player") > 0
			and policy.MainKillActor(env) == "player" then
			emit("useChallengerCharges", reason, true, "Use Challenger Charges (Sand Stance)?")
		elseif text:match("^gain her embrace for %d+ seconds when you ignite an enemy$") and context.selfHit and (mainOutput.IgniteChance or 0) > 0
			and (mainOutput.IgniteDPS or 0) > 0 then
			emit("buffHerEmbrace", reason, true, "Keep Her Embrace by igniting enemies?")
		elseif text:match("^you gain divinity for %d+ seconds on reaching maximum divine charges$") and context.selfHit then
			for _, generator in ipairs(context.lines) do
				if model.NormalizeLine(generator.text) == "gain a divine charge on hit" then
					emit("buffDivinity", reason .. "\n" .. generator.text, true, "Include the Divinity window?")
				end
			end
		elseif text == "your hits permanently intimidate enemies that are on full life" and context.selfHit then
			emit("conditionChampionIntimidate", reason, true, "Did you hit it while on full Life?")
		elseif text:match("^bow attacks sacrifice a random damageable minion to fire %d+ additional arrows?$") and selfCast
			and main.skillTypes[SkillType.Attack] and main.skillTypes[SkillType.Projectile] and otherMinion then
			emit("conditionSacrificeMinion", reason, true, "Do you keep minions for bow sacrifices?")
		elseif text == "bleeding you inflict is reflected to you" and context.selfHit and (mainOutput.BleedDPS or 0) > 0
			and not env.player.modDB:Flag(nil, "BleedImmune") and (mainOutput.BleedAvoidChance or 0) < 100 then
			emit("conditionBleeding", reason, true, "Are you Bleeding from reflected bleeds?")
		elseif text == "poison you inflict is reflected to you if you have fewer than 100 poisons on you"
			and context.selfHit and (mainOutput.PoisonDPS or 0) > 0
			and not env.player.modDB:Flag(nil, "PoisonImmune") and (mainOutput.PoisonAvoidChance or 0) < 100 then
			emit("conditionPoisoned", reason, true, "Are you Poisoned by reflected poisons?")
			local count = math.min(100, math.floor(poisonCount(mainOutput)))
			if count > 0 then
				emit("multiplierPoisonOnSelf", reason .. "\nUses your poisons, capped at 100.", true, "Use approximately " .. count .. " reflected Poisons on yourself?",
					count, { "conditionPoisoned" })
			end
		end
		-- Withered on hit from gear or passives. The curse-cast variant uses the
		-- same native SelfCast<Curse> condition ModParser attaches to the line.
		local witherChance, witherDuration = text:match("^([%d%.]+)%% chance to inflict withered for ([%d%.]+) seconds on hit$")
		local castDuration, castCurse = text:match("^inflict withered for ([%d%.]+) seconds on hit if you've cast (.-) in the past %d+ seconds$")
		if castCurse and env.player.modDB:GetCondition("SelfCast" .. castCurse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "")) then
			witherChance, witherDuration = 100, castDuration
		end
		witherChance, witherDuration = math.min(100, tonumber(witherChance) or 0), tonumber(witherDuration) or 0
		if selfHit and rate > 0 and witherChance > 0 and witherDuration > 0 then
			local count = math.min(15, math.floor(rate * witherChance / 100 * math.min(seconds, witherDuration)))
			if count > 0 then
				emit("multiplierWitheredStackCount", reason .. "\nUses " .. name .. "'s successful hit rate, " .. witherChance .. "% chance and the base "
					.. witherDuration .. "s duration within " .. seconds .. "s; capped at 15.", true, "Maintain approximately "
					.. count .. " Withered stacks from your hits?", count)
			end
		end
		for _, charge in ipairs({ "Power", "Frenzy", "Endurance" }) do
			local lower = charge:lower()
			local chance = text:match("^([%d%.]+)%% chance to grant an? " .. lower .. " charge to nearby allies on hit$")
			if otherMinion and context.selfHit and chance and tonumber(chance) > 0 then
				emit("minionsUse" .. charge .. "Charges", reason, true, "Do your nearby minions build " .. charge .. " Charges from your hits?")
			end
			local ownChance = tonumber(text:match("^minions have ([%d%.]+)%% chance to gain an? " .. lower .. " charge on hit$")) or 0
			if env.minion and ownChance > 0 and rate > 0 then
				emit("minionsUse" .. charge .. "Charges", reason, true, "Do your minions build " .. charge .. " Charges from their hits?")
			end
		end
	end
end

M.Advanced = Advanced

-- ============================================================================
-- Guided: settings whose answers are not stored in gear or gems. They are
-- editable in the workflow, with explicit confirmation, but are not detections.
-- ============================================================================
local Guided = { }
local questions = model.Text.questions
local labels = {
	overrideCruelty = "Cruelty bonus to damage over time (%)",
	meleeDistance = "Distance from the enemy (metres)", projectileDistance = "Projectile travel distance (metres)",
	hoaOverkill = "Damage left over from the killing hit",
}
function Guided.Question(var) return questions[var] end
function Guided.Bounds(entry, build)
	local option, scale, minimum, maximum = byName[entry.var], 1, 1, nil
	if option.type == "countAllowZero" or option.allowZero then minimum = 0 end
	if entry.var == "overrideCruelty" then minimum, maximum = 0, 40 end
	if entry.var == "meleeDistance" or entry.var == "projectileDistance" then scale, minimum = 10, 0 end
	local env = build.calcsTab.mainEnv
	if entry.var == "heraldOfAgonyVirulenceStack" then
		local cap = env.player.modDB:Sum("BASE", nil, "Multiplier:VirulenceStacksMax")
		if cap > 0 then maximum = cap end
	elseif entry.var == "heraldOfTheHivePressure" then
		-- The cap lives on the Herald's own skill mods, not on the main skill.
		for _, skill in ipairs(env.player.activeSkillList) do
			if skill.activeEffect.grantedEffect.name == "Herald of the Hive" and skillEnabled(skill) then
				local cap = skill.skillModList:Sum("BASE", skill.skillCfg, "Multiplier:OtherworldlyPressureMax")
				if cap > 0 then maximum = cap end
			end
		end
	elseif entry.var == "perforateSpikeOverlap" then
		local skill = env.player.mainSkill
		local name = skill.activeEffect.grantedEffect.name
		if name:match("^Perforate") then
			local cap = skill.skillModList:Sum("BASE", skill.skillCfg, "Multiplier:" .. name:gsub(" ", "") .. "MaxSpikes")
			if cap > 0 then maximum = cap end
		end
	elseif entry.var == "toxicRainPodOverlap" or entry.var == "ShrapnelBallistaProjectileOverlap" then
		local name = env.player.mainSkill.activeEffect.grantedEffect.name
		local matches = entry.var == "toxicRainPodOverlap" and name:match("^Toxic Rain") or entry.var == "ShrapnelBallistaProjectileOverlap"
			and name:match("^Shrapnel Ballista")
		if matches and (env.player.output.ProjectileCount or 0) > 0 then maximum = env.player.output.ProjectileCount end
	elseif entry.var == "skillChainCount" or entry.var == "skillForkCount" or entry.var == "skillPierceCount" then
		-- The main skill's native limit; which hit along the route to model stays the player's choice.
		local output = env.player.output
		local cap = entry.var == "skillChainCount" and output.ChainMax
			or entry.var == "skillForkCount" and output.ForkCountMax
			or entry.var == "skillPierceCount" and output.PierceCount
		if cap and math.floor(cap) >= minimum then maximum = math.floor(cap) end
	elseif entry.var == "multiplierHexDoom" then
		-- CalcPerform records the highest MaxDoom among the enabled Hexes and clamps the applied Doom to it.
		-- curseOverlaps, stormRainBeamOverlap and the distances have no native maximum, so they stay open.
		local cap = env.player.output.HexDoomLimit
		if cap and math.floor(cap) >= minimum then maximum = math.floor(cap) end
	end
	return minimum, maximum, scale
end
function Guided.Number(entry, build, input)
	local value = tonumber(input)
	if not value or value ~= value or value == math.huge or value == -math.huge then return nil, "Enter a number." end
	local minimum, maximum, scale = Guided.Bounds(entry, build)
	value = value * scale
	if value < minimum or maximum and value > maximum then
		return nil, "Enter " .. minimum / scale .. " or more" .. (maximum and (", up to " .. maximum / scale) or "") .. "."
	end
	if byName[entry.var].type ~= "float" and math.abs(value - math.floor(value + 0.5)) > 1e-7 then
		return nil, scale == 10 and "Use tenths of a metre, such as 1.5." or "Enter a whole number."
	end
	return byName[entry.var].type == "float" and value or math.floor(value + 0.5)
end
function Guided.Entries(configTab, inventory)
	local entries, retired = { }, 0
	for _, info in ipairs(inventory) do
		if info.inScope and (not info.supported or info.editableFallback) then
			if info.kind == "legacy" then retired = retired + 1
			else
				local option = byName[info.var]
				local entry = { var = info.var, baseLabel = labels[info.var] or info.label, section = info.section,
					current = configTab.input[info.var], selected = false, review = true, guided = true,
					reason = questions[info.var] or "Choose the value you actually use.",
					available = visibility.isRelevantForBuild(option, configTab.build), assessment = info }
				entry.label = entry.baseLabel
				if option.type == "list" then entry.choices = copyTable(option.list)
				elseif option.type == "check" then entry.choices = { { val = false, label = "Off" }, { val = true, label = "On" } } end
				entry.validate = function(value)
					if not entry.available or not visibility.isRelevantForBuild(option, configTab.build) then
						return "Not used by the current build: " .. entry.baseLabel
					end
					if not value.choiceConfirmed then return "Confirm a value for " .. entry.baseLabel end
					if value.useDefault or value.choices then return end
					if type(value.value) ~= "number" then return "Enter a number for " .. entry.baseLabel end
					local _, _, scale = Guided.Bounds(entry, configTab.build)
					local _, err = Guided.Number(entry, configTab.build, value.value / scale)
					return err
				end
				t_insert(entries, entry)
			end
		end
	end
	return entries, retired
end
function Guided.Set(entry, value, configTab)
	if not entry.available then return false end
	if entry.choices then
		local allowed = false; for _, choice in ipairs(entry.choices) do if choice.val == value then allowed = true end end
		if not allowed then return false end
	else
		local number = Guided.Number(entry, entry.valueBuild or configTab.build, value)
		if number == nil then return false end
		value = number
	end
	entry.value, entry.useDefault, entry.clearPlaceholder, entry.restorePlaceholder = value, false, false, nil
	entry.choiceConfirmed, entry.selected = true, true
	local shown = type(value) == "boolean" and (value and "On" or "Off") or tostring(value)
	if not entry.choices then local _, _, scale = Guided.Bounds(entry, entry.valueBuild or configTab.build); shown = string.format("%g", value / scale) end
	entry.label = entry.baseLabel .. ": " .. shown
	return true
end
function Guided.Default(entry, configTab)
	if not entry.available then return false end
	local option = byName[entry.var]
	if entry.choices then
		local value = option.type == "list" and option.list[option.defaultIndex or 1].val or option.defaultState == true
		Guided.Set(entry, value, configTab)
	else
		entry.value, entry.useDefault = nil, true
		entry.restorePlaceholder = option.defaultPlaceholderState
		entry.choiceConfirmed, entry.selected = true, true
	end
	entry.clearPlaceholder, entry.label = true, entry.baseLabel .. ": PoB default"
	return true
end
M.Guided = Guided

-- ============================================================================
-- Quests: import records retained separately from editable calculation choices
-- ============================================================================
local Quests = model.Registry()
local fields = { bandit = "bandit_choice", pantheonMajorGod = "pantheon_major", pantheonMinorGod = "pantheon_minor" }
Quests.structural = { resistancePenalty = true }
local function valid(var, value)
	for _, choice in ipairs(byName[var].list) do if choice.val == value then return true end end
	return false
end
function Quests.Capture(build, passives, characterName)
	local hash = characterName and common.sha1(characterName)
	local previous = build.autoConfigureQuestEvidence
	local records = { }
	-- Fields this import does not report keep the same character's earlier records
	if previous and previous._characterHash == hash then
		for var in pairs(fields) do records[var] = previous[var] end
	end
	for var, field in pairs(fields) do
		local mask = passives._autoConfigureQuestFields
		local reported = mask == nil or type(mask) == "table" and mask[field] == true
		if reported then
			local value = passives[field]
			if var == "bandit" and value == "Eramir" then value = "None" end
			records[var] = valid(var, value) and value or nil
		end
	end
	if hash and next(records) then records._characterHash = hash end
	build.autoConfigureQuestEvidence = records
	return records
end
function Quests.InvalidateForCharacter(build, characterName)
	if characterName and build.autoConfigureQuestEvidence and next(build.autoConfigureQuestEvidence)
		and build.autoConfigureQuestEvidence._characterHash ~= common.sha1(characterName) then build.autoConfigureQuestEvidence = { } end
end
function Quests.Save(records)
	local node = { elem = "AutoConfigureQuests", attrib = { source = "character-import" } }
	local count = 0
	for var in pairs(fields) do if records and valid(var, records[var]) then node.attrib[var], count = records[var], count + 1 end end
	if records and type(records._characterHash) == "string" and #records._characterHash == 40 and records._characterHash:match("^%x+$") then
		node.attrib.characterHash = records._characterHash
	end
	if count > 0 then return node end
end
function Quests.Load(node)
	local records = { }
	if node.attrib and node.attrib.source == "character-import" then
		for var in pairs(fields) do if valid(var, node.attrib[var]) then records[var] = node.attrib[var] end end
		if node.attrib.characterHash and #node.attrib.characterHash == 40 and node.attrib.characterHash:match("^%x+$") then
			records._characterHash = node.attrib.characterHash
		end
	end
	return records
end
for var in pairs(fields) do
	Quests.structural[var] = true
	Quests.Define({ var = var, model = "setting", kind = "automatic", keepDuringDetection = true,
		condition = "Read a native-valid " .. var .. " from your last character import.",
		confirmation = "Asks before replacing your value.",
		evaluate = function(facts)
			local build = facts.context.originalBuild
			local value = build.autoConfigureQuestEvidence and build.autoConfigureQuestEvidence[var]
			if not valid(var, value) then return end
			local current = build.configTab.input[var]
			return { value = value, review = current ~= nil and current ~= value,
				reason = "Your character import reports " .. var .. " = " .. value .. "." }
		end })
end
Quests.Define({ var = "resistancePenalty", model = "setting", kind = "assisted", keepDuringDetection = true,
	condition = text.resistancePenalty.condition,
	confirmation = "Confirm your campaign progress.",
	evaluate = function(facts)
		local act = facts.context.originalBuild.Act
		local value = act == "Endgame" and -60 or type(act) == "number" and (act > 10 and -60 or act > 5 and -30 or act >= 1 and act < 5 and 0)
		if type(value) ~= "number" then return end
		local assumption = policy.Scenario("Confirm your Kitava quest progress.")
		assumption.automatic = false
		return { value = value, assumption = assumption, reason = "PoB's native progress estimate is " .. tostring(act) .. ". It suggests a " .. value
			.. "% resistance penalty; confirm it." }
	end })
M.Quests = Quests

-- ============================================================================
-- Ground: ground/area generation is build evidence; occupying that area is a
-- separate confirmation. An ailment never proves a particular ground source.
-- ============================================================================
local Ground = { capabilities = { }, neutralInputs = { } }
local function groundRule(var, condition, confirmation, kind)
	if var:find("ConsecratedGround", 1, true) or var:find("FungalGround", 1, true) or var:find("ProfaneGround", 1, true) then
		condition = condition .. " Conflicting replacements are skipped."
	end
	model.RegisterRule(Ground, var, condition, confirmation, kind)
end
for _, ground in ipairs({ "Shocked", "Scorched", "Brittle", "Sapped" }) do
	groundRule("conditionEnemyOn" .. ground .. "Ground", "A source drops " .. ground .. " Ground, or a skill creates it.",
		"Confirm the target stays on the ground.")
end
groundRule("conditionEnemyInChillingArea", "A skill must create a Chilling Area.", "Confirm the target stays in the area.")
groundRule("conditionEnemyInFrostGlobe", "Frost Shield must create the area.",
	"Confirm the enemy stays inside it.")
for _, entry in ipairs({ { "conditionOnConsecratedGround", "you and the affected minions" }, { "conditionEnemyOnConsecratedGround", "the enemy" } }) do
	groundRule(entry[1], "Needs a real Consecrated Ground source.", "Confirm keeping "
		.. entry[2] .. " on the ground.")
end
for _, entry in ipairs({ { "conditionOnBrineGround", "you" }, { "minionConditionOnBrineGround", "the enabled minions" },
	{ "conditionEnemyOnBrineGround", "the enemy" } }) do
	groundRule(entry[1], "Needs a Brine Ground modifier.",
		"Confirm keeping " .. entry[2] .. " on Brine Ground.")
end
for _, entry in ipairs({ { "conditionOnFungalGround", "you" }, { "conditionEnemyOnFungalGround", "the enemy" } }) do
	groundRule(entry[1], "Needs a real Fungal Ground source.", "Confirm the trigger and that " .. entry[2]
		.. " occupies the created Fungal Ground.")
end
groundRule("conditionEnemyOnProfaneGround", "Needs a Profane Ground source.", "Confirm the enemy stays on it.")
for _, var in ipairs({ "conditionOnProfaneGround", "minionConditionOnProfaneGround" }) do
	groundRule(var, text.profaneGroundOccupant.condition, "Confirm the actor stays on this ground.")
end
groundRule("conditionEnemyChilledByYourHits", text.conditionEnemyChilledByYourHits.condition, "Uses your Chill application rate.", "automatic")

function Ground.Detect(context)
	local env, main, emit = context.env, context.mainSkill, context.suggest
	local out, db = env.player.output, env.player.modDB
	local ownHit = skillEnabled(main) and context.selfHit
	local ownKills = model.OwnDamage(main, out) and policy.KillRate(context, "player") > 0
	local active, hasMinion = { }, false
	for _, skill in ipairs(env.player.activeSkillList) do
		if skillEnabled(skill) then t_insert(active, skill); hasMinion = hasMinion or skill.minion ~= nil end
	end
	local function ask(var, source, trigger)
		emit(var, source .. "\n" .. trigger .. "\nConfirm position and trigger timing.", true,
			nil, nil, nil, policy.Scenario(trigger))
	end
	local consecrated, limitedConsecrated, profane, fungal, profaneAllies = { }, { }, { }, { }, { }
	for _, skill in ipairs(active) do
		local id, name = skill.activeEffect.grantedEffect.id, skill.activeEffect.grantedEffect.name
		local source = "Enabled skill: " .. name .. "."
		if not skill.minion then
			if skill.skillTypes[SkillType.ChillingArea] or skill.skillTypes[SkillType.NonHitChill] then
				ask("conditionEnemyInChillingArea", source, "Keep the target inside this area.")
			end
			if id == "FrostShield" then ask("conditionEnemyInFrostGlobe", source, "Keep the enemy inside Frost Shield.") end
			if id:match("^PurifyingFlame") or id:match("^ConsecratedPath") or id:match("^HolyFlameTotem") then
				t_insert(consecrated, source .. " Creates Consecrated Ground.")
			end
			if id == "TriggeredShockedGround" then
				ask("conditionEnemyOnShockedGround", source, "Keep the enemy on its Shocked Ground.")
			end
			if id == "CreateFungalGroundOnKill" and ownKills then
				t_insert(fungal, source .. " Triggers on your kills.")
			end
		end
	end
	for _, line in ipairs(context.lines) do
		local text = model.NormalizeLine(line.text)
		local source = line.source .. "\n" .. line.text
		if text == "profane ground you create also affects you and your allies, granting chaotic might" then t_insert(profaneAllies, source) end
		local qualified = true
		local body = text
		-- Same gate as ModParser: ActorCondition enemy RareOrUnique / PinnacleBoss.
		if body:match("^while a unique enemy is in your presence, ") then
			qualified = env.enemy.modDB:GetCondition("RareOrUnique")
			body = body:gsub("^while a unique enemy is in your presence, ", "")
		elseif body:match("^while a pinnacle atlas boss is in your presence, ") then
			qualified = env.enemy.modDB:GetCondition("PinnacleBoss")
			body = body:gsub("^while a pinnacle atlas boss is in your presence, ", "")
		end
		for _, ground in ipairs({ "shocked", "scorched", "brittle", "sapped" }) do
			local duration = tonumber(body:match("^drops? " .. ground .. " ground while moving, lasting ([%d%.]+) seconds$"))
			if qualified and duration and duration > 0 then
				ask("conditionEnemyOn" .. ground:gsub("^%l", string.upper) .. "Ground", source,
					"Keep the target on the trail for " .. duration .. "s.")
			end
		end
		if text == "drop brine ground while moving, lasting 4 seconds" and db:Flag(nil, "CanCreateBrineGround") then
			ask("conditionOnBrineGround", source, "Stand on your own Brine Ground trail.")
			ask("conditionEnemyOnBrineGround", source, "Keep the enemy on your Brine Ground.")
			if hasMinion then ask("minionConditionOnBrineGround", source, "Keep minions on your Brine Ground.") end
		end
		if text == "you have fungal ground around you while stationary" then
			t_insert(fungal, source .. " Stay stationary to create it.")
		end
		if text == "you have consecrated ground around you while stationary" then
			t_insert(consecrated, source .. " Stay stationary to create it.")
		end
		if text:match("^creates? consecrated ground on critical strike$") and ownHit and (out.CritChance or 0) > 0 then
			t_insert(consecrated, source .. " Critically hit to create the ground.")
		end
		local blockChance = tonumber(text:match("^([%d%.]+)%% chance to create consecrated ground when you block$")) or 0
		if blockChance > 0 and math.max(out.BlockChance or 0, out.SpellBlockChance or 0) > 0 then
			t_insert(consecrated, source .. " Block a hit to create it.")
		end
		if text == "create consecrated ground when you shatter an enemy" and ownKills and ownHit and (out.FreezeCanApply or 0) > 0
			and (out.FreezeChance or 0) > 0 then
			t_insert(consecrated, source .. " Shatter an enemy to create it.")
		end
		local chance = tonumber(text:match("^([%d%.]+)%% chance to create profane ground on critical strike if intelligence is your highest attribute$"))
		if chance and chance > 0 and ownHit and (out.CritChance or 0) > 0 and db:Flag(nil, "Condition:CreateProfaneGround") then
			t_insert(profane, source .. " Crit with Intelligence highest.")
		end
		if text == "consecrated path and purifying flame create profane ground instead of consecrated ground" then
			for _, skill in ipairs(active) do
				if skill.activeEffect.grantedEffect.id:match("^PurifyingFlame") or skill.activeEffect.grantedEffect.id:match("^ConsecratedPath") then
					t_insert(limitedConsecrated, "Enabled " .. skill.activeEffect.grantedEffect.name .. ": uses its Profane Ground replacement.")
				end
			end
		end
	end
	-- Flask source text is inspected only when that actual slot is active.
	for index = 1, 5 do
		local slot = context.build.itemsTab.slots["Flask " .. index]
		local item = slot and context.build.itemsTab.items[slot.selItemId]
		if item and slot.active and item.flaskData then
			local creates = item.baseName == "Sulphur Flask"
			for _, line in ipairs(item.explicitModLines or { }) do
				if not line.disabled and item:CheckModLineVariant(line) and StripEscapes(line.line):lower() == "creates consecrated ground on use" then
					creates = true
				end
			end
			if creates then t_insert(consecrated, "Equipped and active flask: " .. item.name .. ". Use it to create Consecrated Ground.") end
		end
	end
	local replaceProfane, replaceFungal = false, false
	for _, line in ipairs(context.lines) do
		local text = model.NormalizeLine(line.text)
		if text == "create profane ground instead of consecrated ground" then replaceProfane = true end
		if text == "create fungal ground instead of consecrated ground" then replaceFungal = true end
	end
	if #consecrated > 0 then
		local source = table.concat(consecrated, "\n")
		local remaining = { }
		for _, entry in ipairs(consecrated) do
			local converted = #limitedConsecrated > 0 and (entry:match("^Enabled skill: Purifying Flame") or entry:match("^Enabled skill: Consecrated Path"))
			if not converted then t_insert(remaining, entry) end
		end
		-- Multiple competing replacements do not prove which ground wins.
		-- Independent crit/stationary generators remain in their own lists.
		if replaceProfane and not replaceFungal then
			t_insert(profane, source .. "\nA modifier makes it Profane Ground.")
		end
		if replaceFungal and not replaceProfane and #remaining > 0 then
			t_insert(fungal, table.concat(remaining, "\n") .. "\nYour modifier makes it Fungal Ground.")
		end
		if not replaceProfane and not replaceFungal then
			-- A skill-specific replacement does not convert other generators.
			if #remaining > 0 then
				ask("conditionOnConsecratedGround", table.concat(remaining, "\n"),
					"Keep you and minions on the ground.")
				ask("conditionEnemyOnConsecratedGround", table.concat(remaining, "\n"),
					"Keep the target on the ground.")
			end
		end
	end
	if not replaceFungal then for _, source in ipairs(limitedConsecrated) do t_insert(profane, source) end end
	if #profane > 0 then ask("conditionEnemyOnProfaneGround", table.concat(profane, "\n"), "Keep the enemy on your Profane Ground.") end
	if #profane > 0 and #profaneAllies > 0 then
		local source = table.concat(profane, "\n") .. "\n" .. table.concat(profaneAllies, "\n")
		ask("conditionOnProfaneGround", source, "Confirm you stand on this ground.")
		if hasMinion then
			ask("minionConditionOnProfaneGround", source, "Confirm your minions stand on it.")
			local live = context.originalBuild
			local mainEnv = live.calcsTab and live.calcsTab.mainEnv
			local actor = mainEnv and mainEnv.minion
			if live.configTab.input.minionConditionOnProfaneGround == true and actor and not actor.hostile
				and not context.derived.minionbuffChaoticMight then
				for _, entry in ipairs(actor.modDB:Tabulate("FLAG", nil, "Condition:ChaoticMight")) do
					local trigger = entry.mod[1]
					if entry.mod.source ~= "Config" and trigger and trigger.type == "Condition" and trigger.var == "OnProfaneGround" then
						context.derived.minionbuffChaoticMight = "Chaotic Might from Profane Ground.\n" .. source
						break
					end
				end
			end
		end
	end
	if #fungal > 0 then
		ask("conditionOnFungalGround", table.concat(fungal, "\n"), "Stand on its Fungal Ground.")
		ask("conditionEnemyOnFungalGround", table.concat(fungal, "\n"),
			"Keep the enemy on its Fungal Ground.")
	end
	if ownHit and (out.ChillHitEffectEstimate or 0) > 0 and not model.AilmentImmune(env, "Chill") then
		local chance = out.ChillChance or 100
		local critOnly = (out.ChillEstimateUsesCrit or 0) > 0
		if critOnly then chance = math.min(chance, out.CritChance or 0) end
		local rate = policy.HitRate(context, out) * chance / 100
		if rate > 0 then
			local assumption = policy.Refresh(context.settings, rate, out.ChillDuration or 0, policy.FightSeconds(context))
			emit("conditionEnemyChilledByYourHits", "Your own hits Chill the enemy.", critOnly or not assumption.automatic,
				"Enemy chilled by your main skill's own hits", nil, nil, assumption)
		end
	end
end

M.Ground = Ground

-- ============================================================================
-- Shrines: equipment-granted states and actual Shrine generators, never
-- arbitrary map encounters. Random outcomes require a confirmed fresh grant.
-- ============================================================================
local Shrines = model.Registry()
local families = {
	regular = { "AccelerationShrine", "BrutalShrine", "DiamondShrine", "DivineShrine", "EchoingShrine", "GloomShrine", "GreaterFreezingShrine",
		"GreaterShockingShrine", "GreaterSkeletalShrine", "ImpenetrableShrine", "MassiveShrine", "ReplenishingShrine", "ResistanceShrine", "ResonatingShrine" },
	lesser = { "LesserAccelerationShrine", "LesserBrutalShrine", "LesserImpenetrableShrine", "LesserMassiveShrine", "LesserReplenishingShrine",
		"LesserResistanceShrine" },
	blood = { "BloodShrineOfRats", "BloodShrineOfLocusts", "BloodShrineOfToads", "BloodShrineOfCrows", "BloodShrineOfBats" },
}
-- Every Shrine buff is a structural decision; ConfigAutoScan merges the set.
Shrines.controlled, Shrines.structural = { }, { }
function Shrines.RegisterStructural(target)
	for var in pairs(Shrines.structural) do target[var] = true end
	return target
end
local function independent(facts, flag)
	if not facts.env.player.modDB:Flag(nil, flag) then return false end
	for _, entry in ipairs(facts.env.player.modDB:Tabulate("FLAG", nil, flag)) do
		if entry.mod.source ~= "Config" then return true end
	end
	return false
end
local function sources(facts)
	if facts.shrineSources then return facts.shrineSources end
	local result = { regular = { }, lesser = { }, blood = { }, direct = { }, budgets = { } }
	for family, names in pairs(families) do
		result.budgets[family] = { }
		for _, name in ipairs(names) do
			local var = "buff" .. name
			result.direct[var] = independent(facts, "Condition:" .. name)
			if not result.direct[var] then t_insert(result.budgets[family], var) end
		end
	end
	local gull
	for _, line in ipairs(facts.Lines()) do
		if line.text:match("^gain a random shrine buff every %d+ seconds$") and facts.env.player.modDB:Flag(nil, "Condition:CanHaveRegularShrines") then
			t_insert(result.regular, line.source .. "\nConfirm one grant and its outcome.")
		end
		if line.text:match("^gain a random blood shrine buff every %d+ seconds$") and facts.env.player.modDB:Flag(nil, "Condition:CanHaveBloodShrines") then
			t_insert(result.blood, line.source .. "\nConfirm one Blood Shrine grant.")
		end
		if line.text:match("^trigger level %d+ create lesser shrine when you kill an enemy$") then gull = line.source end
	end
	local creator = gull and facts.Find("TriggeredSummonLesserShrine")
	if creator and facts.PersonalKills() then
		local probe, stats = facts.Probe(creator), facts.Stats(creator)
		local out = probe and probe.player.output
		if out and (out.Cooldown or 0) > 0 and (out.Duration or 0) > 0 and (stats["chance_to_cast_on_kill_%"] or 0) > 0 then
			t_insert(result.lesser, gull .. string.format("\nCooldown %gs (starts on cooldown), chance %g%%.", out.Cooldown,
				stats["chance_to_cast_on_kill_%"]) .. " Object lifetime is not buff duration.")
		end
	end
	facts.shrineSources = result
	return result
end
for family, names in pairs(families) do
	for _, name in ipairs(names) do
		local var, flag = "buff" .. name, "Condition:" .. name
		Shrines.controlled[var], Shrines.structural[var] = true, true
		local permanent = name == "LesserBrutalShrine" or name == "LesserMassiveShrine" or name == "DiamondShrine" or name == "MassiveShrine"
		Shrines.Define({ var = var, model = "state", kind = permanent and "automatic" or "assisted", neutralValue = false,
			condition = "Needs a granted flag or a periodic " .. family .. " Shrine source.",
			confirmation = text.shrineBuff.confirmation,
			evaluate = function(facts)
				local source = sources(facts)
				if source.direct[var] then
					return { value = true, activation = { nativeFlag = flag }, reason = "The neutral native player has " .. flag .. " from a real modifier." }
				end
				if #source[family] == 0 then return end
				return { choices = { { val = false, label = "This Shrine buff is absent" }, { val = true, label = "Confirm this Shrine buff was granted" } },
					reason = table.concat(source[family], "\n") .. "\nChoose the outcome of one grant.",
					assumption = { automatic = false, description = "Confirm this buff is active now.",
						selectionBudget = { group = "shrine:" .. family, label = family .. " Shrine outcomes", limitLabel = "the single fresh-grant profile",
						maximum = 1, vars = source.budgets[family] } } }
			end,
		})
	end
end
M.Shrines = Shrines

-- ============================================================================
-- Choices: source-backed decisions sharing native actor probes and one staged
-- transaction. Random Sentinel outcomes and curse targeting are explicit.
-- ============================================================================
local Choices = model.Registry()
Choices.structural = { bloodSandStance = true, doomBlastSource = true }
Choices.sentinelVars = { "divineSentinelPhysAsFire", "divineSentinelPhysAsLightning", "divineSentinelRegenLife", "divineSentinelRegenMana",
	"divineSentinelChaosResistance", "divineSentinelSelfCurseEffect" }
-- Parent explanations that are not registry definitions of this module.
Choices.parentRules = { }
local function decision(var, condition, confirmation, evaluate, keep, mode, kind)
	Choices.Define({ var = var, model = mode or "decision", kind = kind or "assisted", condition = condition, confirmation = confirmation, evaluate = evaluate,
		keepDuringDetection = keep })
end
-- ConfigAutoRulesCombat reads these through this namespace.
Choices.Personal, Choices.BalanceOfTerrorVar = model.Personal, model.BalanceOfTerrorVar
function Choices.SelfOnlyCurse(facts, skill) return model.SelfOnlyCurse(facts.context.build, skill) end
local selfOnly = Choices.SelfOnlyCurse
local function ownHex(skill) return model.Personal(skill) and skill.skillTypes[SkillType.Hex] end
for _, name in ipairs({ "Conductivity", "Despair", "Elemental Weakness", "Enfeeble", "Flammability", "Frostbite", "Punishment", "Temporal Chains",
	"Vulnerability" }) do
	local var = Choices.BalanceOfTerrorVar(name)
	Choices.structural[var] = true
	decision(var, "An actually enabled personal " .. name .. " and a matching modifier exist.", "Confirm if this curse reaches enemies.",
		function(facts)
		local enabled = false
		for _, skill in ipairs(facts.Active()) do if ownHex(skill) and skill.activeEffect.grantedEffect.name == name then enabled = true break end end
		if not enabled then return end
		for _, line in ipairs(facts.Lines()) do
			if line.text:find("if you've cast " .. name:lower() .. " in the past 10 seconds", 1, true) then
				return { choices = { { val = false, label = "Apply " .. name .. " to enemies" },
					{ val = true, label = "Cast " .. name .. " for the buff only" } }, reason = line.source .. "\nActual personal " .. name
						.. " exists. Choose how you use it." }
			end
		end
	end, true)
end
decision("bloodSandStance", text.bloodSandStance.condition, "Choose the stance you maintain.", function(facts)
	local skill = facts.Find("BloodAndSand") or facts.Find("FleshAndStone")
	if skill then
		return { choices = { { val = "BLOOD", label = "Blood Stance" }, { val = "SAND", label = "Sand Stance" } }, reason = skill.activeEffect.grantedEffect.name .. " alternates between Blood Stance and Sand Stance." }
	end
end, true)
decision("doomBlastSource", text.doomBlastSource.condition, text.doomBlastSource.confirmation, function(facts)
	local supported, curses, doomCurses, vixenCurses, expiration, hexblast = false, { }, { }, { }, false, false
	for _, skill in ipairs(facts.Active()) do
		if ownHex(skill) and not selfOnly(facts, skill) then
			curses[skill.activeEffect.grantedEffect.name] = true
			if facts.Applied(skill, "SupportImpendingDoom") then
				supported = true
				doomCurses[skill.activeEffect.grantedEffect.name] = true
				local probe = facts.Probe(skill)
				if probe and (probe.player.output.Duration or 0) > 0 then expiration = true end
			end
		end
		if skill.activeEffect.grantedEffect.id:match("^Hexblast") and model.Personal(skill) then hexblast = true end
		if skill.skillTypes[SkillType.Hex] and not selfOnly(facts, skill) and skill.socketGroup and skill.socketGroup.slot == "Gloves"
			and skill.triggeredBy and skill.triggeredBy.grantedEffect.id == "SupportUniqueCastCurseOnCurse" then
			vixenCurses[skill.activeEffect.grantedEffect.name] = true
		end
	end
	if not supported then return end
	local count = 0; for _ in pairs(curses) do count = count + 1 end
	-- CalcPerform resolves CurseLimitIsMaximumPowerCharges into output.EnemyCurseLimit.
	local limit = facts.env.player.output.EnemyCurseLimit or 0
	local choices = { }
	if expiration then t_insert(choices, { val = "expiration", label = "Curse Expiration" }) end
	if limit > 0 and count > limit then t_insert(choices, { val = "replacement", label = "Curse Replacement" }) end
	local gloves = facts.env.player.itemList.Gloves
	local vixenTotal = 0
	for name in pairs(doomCurses) do if not vixenCurses[name] then vixenTotal = vixenTotal + 1 end end
	for _ in pairs(vixenCurses) do vixenTotal = vixenTotal + 1 end
	if next(vixenCurses) and limit > 0 and vixenTotal > limit and gloves and (gloves.title or ""):find("Vixen's Entrapment", 1, true) then
		t_insert(choices, { val = "vixen", label = "Vixen's Curse" })
	end
	if hexblast then t_insert(choices, { val = "hexblast", label = "Hexblast Replacement" }) end
	local names = { }; for name in pairs(doomCurses) do t_insert(names, name) end; table.sort(names)
	if #choices > 0 then return { choices = choices, reason = "Impending Doom supports " .. table.concat(names, ", ") .. "." } end
end, true)
local function sentinelCapacity(facts)
	if facts.divineSentinelCapacity ~= nil then return facts.divineSentinelCapacity end
	local capacities = { }
	for _, skill in ipairs(facts.Active()) do
		if skill.skillTypes[SkillType.CreatesSentinelMinion] and skill.minion and not skill.minion.hostile
			and facts.Applied(skill, "SupportDivineSentinel") then
			local probe = facts.Probe(skill)
			local actor = probe and probe.minion
			local key = actor and actor.minionData.limit
			local capacity = key and probe.player.output[key] or 0
			if capacity > 0 then capacities[key] = math.max(capacities[key] or 0, capacity) end
		end
	end
	local total = 0; for _, capacity in pairs(capacities) do total = total + capacity end
	facts.divineSentinelCapacity = total
	return total
end
for _, var in ipairs(Choices.sentinelVars) do
	Choices.structural[var] = true
	decision(var, text.divineSentinel.condition, text.divineSentinel.confirmation, function(facts)
		local maximum = sentinelCapacity(facts)
		if maximum <= 0 then return end
		return { choices = { { val = false, label = "This aura is absent" }, { val = true, label = "Confirm this aura is present" } },
			assumption = { automatic = false, description = "Confirm your Sentinels' actual auras.", selectionBudget = { group = "divineSentinel",
				maximum = maximum, vars = Choices.sentinelVars } },
			reason = "Divine Sentinel capacity " .. maximum .. ". Confirm this aura covers you." }
	end, false)
end
decision("linkedSourceRate", text.linkedSourceRate.condition, text.linkedSourceRate.confirmation, function(facts)
	if not facts.Find("IntuitiveLink") or not facts.env.player.modDB:Flag(nil, "Condition:CanLinkToMinions") then return end
	local choices = { }
	for _, skill in ipairs(facts.Active()) do
		if skill.minion and not skill.minion.hostile and not skill.skillTypes[SkillType.MinionsAreUndamagable] then
			local probe = facts.Probe(skill)
			local actor = probe and probe.minion
			if actor and not actor.modDB:Flag(nil, "Condition:CannotBeDamaged") and actor.mainSkill.skillFlags.hit then
				local rate = policy.HitRate(facts.context, actor.output)
				local label = actor.minionData.name .. ": " .. actor.mainSkill.activeEffect.grantedEffect.name
				local groupIndex = 0
				for index, group in ipairs(facts.context.build.skillsTab.socketGroupList) do if group == skill.socketGroup then groupIndex = index break end end
				if rate > 0 and rate < math.huge then
					t_insert(choices, { val = rate, label = string.format("%s (%s, group %g; %.3f successful hits/s)", label,
						skill.activeEffect.grantedEffect.name, groupIndex, rate) })
				end
			end
		end
	end
	table.sort(choices, function(a, b) return a.label < b.label end)
	if #choices > 0 then return { choices = choices, requires = { "linkedToMinion" }, reason = "Intuitive Link can link to " .. #choices .. " of your minion skill" .. (#choices == 1 and "" or "s") .. "." } end
end)
-- The on-hit Blind adapter is its own rule so that the override reset below
-- never proposes its parent as a side effect. "BlindChance" is the only native
-- mod name (ModParser: "chance to blind enemies on hit"); the native enemy
-- state from CalcPerform is handled separately by ConfigAutoConditions.
decision("conditionEnemyBlinded", text.conditionEnemyBlinded.condition,
	"Confirm lower application frequency.",
		function(facts)
	-- A Blind PoB already applies (Blind Enemies on Hit) needs no checkbox.
	if not facts.MainHit() or facts.context.derived and facts.context.derived.conditionEnemyBlinded then return end
	local main = facts.context.mainSkill
	local chance = main.skillModList:Sum("BASE", main.skillCfg, "BlindChance")
	for _, line in ipairs(facts.Lines()) do
		local raw = tonumber(line.text:match("^(%d+)%% chance to blind enemies on hit$"))
		if main.skillTypes[SkillType.Attack] then raw = raw or tonumber(line.text:match("^(%d+)%% chance to blind enemies on hit with attacks$")) end
		if line.text == "blind enemies on hit" then raw = 100 end
		chance = math.max(chance, raw or 0)
	end
	if chance <= 0 or facts.env.enemy.modDB:Flag(nil, "Condition:CannotBeBlinded", "BlindImmune", "UnaffectedByBlind") then return end
	local assumption = policy.Refresh(facts.context.settings, policy.HitRate(facts.context, facts.env.player.output) * math.min(100, chance) / 100, 4,
		facts.seconds)
	return { value = true, review = not assumption.automatic, assumption = assumption, reason = "Actual personal Blind-on-hit chance " .. chance
		.. "%. Confirm Blind stays on the target." }
end, false, "boolean", "automatic")
-- Clearing a user's explicit override is a deliberate choice: always a review row.
decision("overrideBuffBlinded", text.overrideBuffBlinded.condition, text.overrideBuffBlinded.confirmation, function(facts)
	-- The parent is a Blind proposal or a Blind PoB derives itself.
	local parent = facts.context.found.conditionEnemyBlinded or facts.context.derived and facts.context.derived.conditionEnemyBlinded
	local original = (facts.context.originalBuild or facts.context.build).configTab
	if parent and (original.input.overrideBuffBlinded ~= nil or original.placeholder.overrideBuffBlinded ~= nil) then
		return { requires = { "conditionEnemyBlinded" }, reason = "Your build already Blinds the enemy; a manual Blind value replaces that." }
	end
end, false, "default")

-- These are actual source-backed rotation profiles, never inferred intentions.
-- Keep existing cast policies where they do not prove their own source. Bypass
-- defaults are neutralised explicitly: their native default can be true even
-- when no spendable generator exists. The core holds mismatched approvals.
Choices.rotationVars = { }
local function rotation(var, neutral, condition, confirmation, evaluate, keep)
	Choices.structural[var] = true
	Choices.rotationVars[var] = true
	Choices.Define({ var = var, model = "decision", kind = "assisted", neutralValue = neutral,
		condition = condition, confirmation = confirmation, evaluate = evaluate, keepDuringDetection = keep })
end
local function personalMain(facts)
	local skill = facts.context.mainSkill
	return model.Personal(skill) and not skill.skillTypes[SkillType.Channel] and skill or nil
end
rotation("waitForMaxSeals", false,
	text.waitForMaxSeals.condition,
	text.waitForMaxSeals.confirmation, function(facts)
	local skill, out = personalMain(facts), facts.env.player.output
	if not skill or not (facts.Applied(skill, "SupportUnleash") or facts.Applied(skill, "SupportGreaterUnleash"))
		or not skill.skillTypes[SkillType.CanRapidFire] or not skill.skillModList:Flag(nil, "HasSeals")
		or skill.skillModList:Flag(nil, "NoRepeatBonuses") or (out.SealCooldown or 0) <= 0 or (out.SealMax or 0) <= 0 then return end
	local allowed = { { val = false, label = "Cast continuously without waiting for full seals" } }
	if (out.TimeMaxSeals or math.huge) <= facts.seconds then t_insert(allowed, { val = true, label = "Wait for full Unleash seals between casts" }) end
	return { choices = allowed, reason = string.format("%g seals, %.3fs each, %.3fs to fill.", out.SealMax,
		out.SealCooldown, out.TimeMaxSeals, facts.seconds) }
end, true)
rotation("repeatMode", "AVERAGE",
	text.repeatMode.condition,
	text.repeatMode.confirmation, function(facts)
	local skill, out = personalMain(facts), facts.env.player.output
	if not skill or (out.Repeats or 1) <= 1 then return end
	local rate = model.UseRate(facts.context, skill, out)
	if rate <= 0 or 1 / rate > facts.seconds then return end
	return { choices = { { val = "AVERAGE", label = "Complete cycles: average of all repeated hits" },
		{ val = "FINAL", label = "Complete cycles: count only each final hit" } },
		reason = string.format("%g hits per cycle at %.3f/s.", out.Repeats, rate,
			1 / rate, facts.seconds) }
end, true)
rotation("ruthlessSupportMode", "AVERAGE",
	text.ruthlessSupportMode.condition,
	text.ruthlessSupportMode.confirmation, function(facts)
	local skill, out = personalMain(facts), facts.env.player.output
	if not skill or not facts.Applied(skill, "SupportRuthless") then return end
	local count = skill.skillModList:Sum("BASE", skill.skillCfg, "RuthlessBlowMaxCount")
	local rate = model.UseRate(facts.context, skill, out)
	if count <= 0 or rate <= 0 or math.floor(rate * facts.seconds + 1e-8) < count then return end
	return { choices = { { val = "AVERAGE", label = "Average over the whole Ruthless cycle" },
		{ val = "MAX", label = "Count only Ruthless hits at their native reduced frequency" } },
		reason = string.format("One Ruthless hit every %g attacks.", count, rate, facts.seconds, count) }
end, true)
for var, skillName in pairs({ ColdSnapBypassCD = "Cold Snap", ConcPathBypassCD = "Consecrated Path of Endurance", FlickerStrikeBypassCD = "Flicker Strike",
	VigilantStrikeBypassCD = "Vigilant Strike" }) do
	rotation(var, false,
		"The actual personal main " .. skillName .. " uses charges to skip its cooldown.",
		text.bypassCooldown.confirmation, function(facts)
		local skill = personalMain(facts)
		if not skill then return end
		local name = skill.activeEffect.grantedEffect.name
		if name ~= skillName and not (skillName == "Cold Snap" or skillName == "Flicker Strike") then return end
		if name ~= skillName and not name:find(skillName .. " of ", 1, true) then return end
		local charge = (skill.activeEffect.grantedEffect.description or ""):match("bypassed by expending an? (%a+) Charge")
		if not charge then return end
		local natural = facts.context.probeConfig({ [var] = false })
		local out = natural and natural.player.output
		if not out or (out.Cooldown or 0) <= 0 then return end
		local allowed = { { val = false, label = "Use the natural cooldown without spending charges" } }
		local reason = string.format("%s spends %s Charges to skip %.3fs.", name, charge, out.Cooldown)
		local bypass = facts.context.probeConfig({ [var] = true })
		if bypass then
			local actor, bypassSkill = bypass.player, bypass.player.mainSkill
			local rates, reasons, losses = mechanics.ChargeGeneration({
				env = bypass, mainSkill = bypassSkill,
				selfHit = bypassSkill.skillFlags.hit and not bypassSkill.minion and not bypassSkill.skillFlags.totem
					and not bypassSkill.skillFlags.trap and not bypassSkill.skillFlags.mine,
				mapping = facts.context.mapping, lines = facts.context.lines,
				settings = facts.context.settings, mainOutputs = facts.context.mainOutputs,
			})
			local rate, demand = rates[charge], model.UseRate(facts.context, bypassSkill, actor.output)
			local maximum, minimum, duration = actor.output[charge .. "ChargesMax"] or 0, actor.output[charge .. "ChargesMin"] or 0,
				actor.output[charge .. "ChargesDuration"] or 0
			local converted = actor.modDB:Flag(nil, charge .. "ChargesConvertTo"
				.. ({ Power = "Absorption", Frenzy = "Affliction", Endurance = "Brutal" })[charge] .. "Charges")
			reason = reason .. string.format("\n%.3f %s Charges/s vs %.3f uses/s.\n", rate, charge, demand, math.max(0, maximum - minimum), duration)
				.. table.concat(reasons[charge], "\n")
			if maximum > minimum and not converted and not losses[charge] and demand > 0 and rate + 1e-8 >= demand
				and rate * math.min(duration, facts.seconds) >= 1 then
				t_insert(allowed, { val = true, label = "Confirm continuous charge generation covers cooldown bypass" })
				reason = reason .. "\nGeneration covers one charge per use."
			else
				reason = reason .. "\nOnly the natural cooldown is offered."
			end
		end
		return { choices = allowed, reason = reason }
	end)
end
M.Choices = Choices

-- ============================================================================
-- Minions: minion sources, calculated life and summon/brand buildup. Selected
-- spectres supply abilities; a generic summon gem or a maximum is not proof.
-- ============================================================================
local Minions = { capabilities = { }, neutralInputs = { } }
local function minionRule(var, condition, confirmation, kind) model.RegisterRule(Minions, var, condition, confirmation, kind) end
minionRule("minionsConditionFullLife", "Uses your minion's defences vs a hit.",
	"Confirm your minion is below full Life.")
minionRule("darkPactSkeletonLife", text.darkPactSkeletonLife.condition, text.darkPactSkeletonLife.confirmation, "automatic")
minionRule("carrionGolemNearbyMinion", text.carrionGolemNearbyMinion.condition, "Confirm these minions stay near it.")
local golemPairs = { { "carrionGolemEqualsChaosGolem", "Carrion", "Chaos" }, { "chaosGolemEqualsStoneGolem", "Chaos", "Stone" },
	{ "stoneGolemEqualsCarrionGolem", "Stone", "Carrion" } }
for _, entry in ipairs(golemPairs) do
	minionRule(entry[1], "Enabled " .. entry[2] .. " and " .. entry[3] .. " Golems fit the global limit.", "Confirm equal counts of both Golems.")
end
minionRule("raiseSpectreEnableBuffs", text.raiseSpectreEnableBuffs.condition, "Confirm using that spectre's buffs.")
minionRule("raiseSpectreEnableCurses", "Needs a spectre with a curse.", "Confirm the spectre curses your target.")
minionRule("raiseSpectreEnableSummonedUrsaRallyingCry", "Needs Summoned Ursa's Rallying Cry.", "Confirm using its Rallying Cry.")
minionRule("raiseSpectreEnableSlashingHorrorEnrage", "Needs Slashing Horror's Enrage.", "Confirm allowing its Enrage.")
minionRule("raiseSpectreEnableSanguimancerDemonLowLife", "Needs the Sanguimancer Demon's buff.",
	"Confirm it stays above Low Life.")
for _, entry in ipairs({ { "configSpectralTigerCount", "Tiger" }, { "configSpectralWolfCount", "Wolf" } }) do
	minionRule(entry[1], "An enabled Summon Spectral " .. entry[2] .. " has a kill or crit trigger.", "Confirm the trigger actually happens.", "automatic")
end
minionRule("raiseSpidersSpiderCount", text.raiseSpidersSpiderCount.condition, text.raiseSpidersSpiderCount.confirmation)
minionRule("ActiveBrands", text.ActiveBrands.condition, "Confirm your other Brand casting.", "automatic")
minionRule("targetBrandedEnemy", "Needs a Brand on the target.", "Confirm you target the branded enemy.")

local baseBrands = { ArmageddonBrand = true, StormBrand = true, BrandSupport = true, PenanceBrand = true, WintertideBrand = true }
local specificSpectre = {
	DropBearSummonedRallyingCry = { var = "raiseSpectreEnableSummonedUrsaRallyingCry", value = true, question = "Use the selected Ursa's Rallying Cry?",
		buffs = true },
	AzmeriDualStrikeDemonFireEnrage = { var = "raiseSpectreEnableSlashingHorrorEnrage", value = false,
		question = "Allow Slashing Horror's Enrage?", buffs = true },
	ABTTAzmeriShepherdSpellDamage = { var = "raiseSpectreEnableSanguimancerDemonLowLife", value = true,
		question = "Is the Sanguimancer above Low Life?" },
}

local function proposeMinionPoolStates(context)
	local env, input = context.env, context.originalBuild.configTab.input
	local actor = env.minion
	if not context.mainSkill.minion or not actor or actor.hostile or actor.modDB:Flag(nil, "Condition:CannotBeDamaged") then return end
	local hit = context.facts.SingleHit(env, actor)
	if not hit or hit.after.Life < 1 then return end
	local out = actor.output
	local belowLowLife = hit.after.Life <= out.Life * (out.LowLifePercentage or data.misc.LowPoolThreshold * 100) / 100
	if belowLowLife then
		for _, skill in ipairs(env.player.modDB:List(nil, "ExtraMinionSkill")) do
			if skill.skillId == "MinionInstability" then return end
		end
	end
	-- Low Life and Leeching are derived by PoB; only an old Full Life claim is cleared here.
	if hit.lifeLost > 0 and input.minionsConditionFullLife == true and not actor.modDB:GetCondition("FullLife") then
		local reason = string.format("Hit leaves your %s at %g/%g Life.", actor.minionData.name, hit.after.Life, out.Life)
		local confirmation = "Confirm your minion takes this hit."
		context.suggest("minionsConditionFullLife", reason, true, "Clear Full Life for your minion?", false, nil,
			policy.Scenario(confirmation))
	end
end

function Minions.Detect(context)
	local env, main, emit = context.env, context.mainSkill, context.suggest
	proposeMinionPoolStates(context)
	local seconds, out = policy.FightSeconds(context), env.player.output
	local active, lines = { }, { }
	for _, skill in ipairs(env.player.activeSkillList) do if skillEnabled(skill) then t_insert(active, skill) end end
	for _, line in ipairs(context.lines) do
		for text in (StripEscapes(line.text) .. "\n"):gmatch("([^\n]+)\n") do
			t_insert(lines, { text = model.NormalizeLine(text), source = line.source .. "\n" .. text, slot = line.source:match("^(.-):") })
		end
	end
	-- The scanner's probeSkill caches one probe per skill.
	local function probe(skill)
		if skill == main then return env end
		return context.probeSkill(skill)
	end
	local function number(var, amount, reason, review, requires)
		if not context.options[var] or amount <= 0 then return end
		local expected = amount
		amount = math.floor(amount + 1e-8)
		if amount < 1 then amount, review = 1, true; reason = reason .. "\nConfirm the event actually happens." end
		emit(var, reason, review or false, StripEscapes(context.options[var].label):gsub(":$", "") .. ": " .. amount, amount, requires,
			policy.Scenario(string.format("Over %gs: about %.2f.", seconds, expected)))
	end
	local ownHit = skillEnabled(main) and context.selfHit
	local killRate = model.OwnDamage(main, out) and policy.KillRate(context, "player") or 0
	local golems, golemFamilies = { }, { }
	local skeletonLives, skeletonUnknown, skeletonAmbiguous, nearby, nearbyReasons = { }, false, false, { }, { }
	local darkPact, bestBrands = false, nil
	for _, skill in ipairs(active) do
		local id, name = skill.activeEffect.grantedEffect.id, skill.activeEffect.grantedEffect.name
		if id == "DarkPact" and skill.skillPart == 2 then darkPact = true end
		if skill.skillTypes[SkillType.Golem] then
			local family = name:gsub(" of .*$", "")
			golemFamilies[family] = true
			for _, pair in ipairs(golemPairs) do if name:match("^Summon " .. pair[2] .. " Golem") then golems[pair[2]] = true end end
		end
		if skill.minion and not skill.minion.hostile then
			local result = probe(skill)
			local actualSpectre = id:match("^RaiseSpectre") and isValueInArray(context.build.spectreList, skill.minion.type)
			local intrinsic = actualSpectre or isValueInArray(skill.activeEffect.grantedEffect.minionList or { }, skill.minion.type)
			local limit = skill.minion.minionData.limit
			local capacity = result and result.player.output[limit or ""] or 1
			capacity = math.max(0, capacity or 0)
			if not skill.skillTypes[SkillType.Golem] then
				local count = intrinsic and capacity or 0
				if not skill.skillFlags.permanentMinion then
					local duration = result and result.player.output.Duration or 0
					local rate = result and model.UseRate(context, skill, result.player.output) or 0
					-- One minion per activation is conservative for multi-summons.
					count = intrinsic and math.min(capacity, rate * math.min(seconds, duration)) or 0
				end
				local key = limit or id .. ":" .. skill.minion.type
				nearby[key] = math.max(nearby[key] or 0, math.floor(count + 1e-8))
				if count > 0 then
					t_insert(nearbyReasons, name .. ": at most " .. math.floor(count + 1e-8) .. " (summon window).")
				end
			end
			if id:match("^SummonSkeleton") then
				local types = 0
				for _, kind in ipairs(skill.minionList or { }) do if kind:lower():find("skeleton", 1, true) then types = types + 1 end end
				local life = result and result.minion and result.minion.output.Life
				if not skill.minion.type:lower():find("skeleton", 1, true) or not life or life <= 0 then skeletonUnknown = true else
					skeletonLives[math.floor(life + 0.5)] = true
					skeletonAmbiguous = skeletonAmbiguous or types ~= 1
				end
			end
			do
				local isSpectre = not not actualSpectre
				local data = skill.minion.minionData
				local buff, curse = false, false
				local definitions = { }
				for _, skillId in ipairs(data.skillList or { }) do definitions[skillId] = env.data.skills[skillId] end
				for _, extra in ipairs(skill.skillModList:List(skill.skillCfg, "ExtraMinionSkill")) do
					if not extra.minionList or isValueInArray(extra.minionList, skill.minion.type) then
						definitions[extra.skillId] = env.data.skills[extra.skillId]
					end
				end
				for _, definition in pairs(definitions) do
					buff = buff or definition.skillTypes[SkillType.Buff] or definition.skillTypes[SkillType.Aura]
					curse = curse or definition.skillTypes[SkillType.Hex] or definition.skillTypes[SkillType.Mark]
						or definition.skillTypes[SkillType.AppliesCurse]
				end
				local source = "Selected friendly " .. (isSpectre and "spectre: " or "minion: ") .. (data.name or skill.minion.type)
					.. "."
				if isSpectre and buff then emit("raiseSpectreEnableBuffs", source, true, "Use buffs from your selected spectre?", true) end
				if isSpectre and curse then emit("raiseSpectreEnableCurses", source, true, "Use curses from your selected spectre?", true) end
				for skillId, choice in pairs(specificSpectre) do
					if definitions[skillId] then
						emit(choice.var, source .. "\nActual ability: " .. definitions[skillId].name .. ".\n" .. choice.question, true, choice.question,
							choice.value,
							isSpectre and choice.buffs and { "raiseSpectreEnableBuffs" } or nil)
					end
				end
			end
		end
		if skill.skillTypes[SkillType.Brand] then
			emit("targetBrandedEnemy", "Enabled Brand: " .. name .. ". Confirm it brands your target.", true,
				"Target the enemy branded by " .. name .. "?", true, nil,
					policy.Scenario("Attack the enemy your Brand marks."))
			if baseBrands[id] and model.IsDirect(skill) then
				local result = probe(skill)
				local calculated = result and result.player.output
				if calculated then
					local duration = math.min(calculated.Duration or 0, calculated.DurationSecondary or calculated.Duration or 0)
					local cap = calculated.ActiveBrandLimit or 0
					local rate = (calculated.CastRate or calculated.Speed or 0) / math.max(1, calculated.Repeats or 1) * policy.Activity(context, calculated)
					if (calculated.Cooldown or 0) > 0 then rate = math.min(rate, 1 / calculated.Cooldown) end
					local count = math.min(cap, rate * math.min(seconds, duration))
					if count > 0 and (not bestBrands or count > bestBrands.count) then
						bestBrands = { count = count, name = name, review = skill ~= main, duration = duration, rate = rate, cap = cap }
					end
				end
			end
		end
		if id == "RaiseSpiders" or id == "SummonSpectralTiger" or id == "SummonSpectralWolf" then
			local result = probe(skill)
			local calculated = result and result.player.output
			local kind = id == "SummonSpectralTiger" and "tiger" or "wolf"
			local rate, reasons, perTrigger = 0, { }, 1
			if id == "RaiseSpiders" then
				local stats = calcLib.buildSkillInstanceStats(skill.activeEffect, skill.activeEffect.grantedEffect)
				rate = killRate * (stats["chance_to_cast_on_kill_%_target_self"] or 0) / 100
				perTrigger = 2
				t_insert(reasons, "Raise Spiders: two Spiders per kill.")
			else
				for _, line in ipairs(lines) do
					local chance, suffix = line.text:match("^([%d%.]+)%% chance to trigger level %d+ summon spectral " .. kind .. " on critical strike(.*)$")
					if not chance then
						suffix = line.text:match("^trigger level %d+ summon spectral " .. kind .. " on critical strike(.*)$"); chance = suffix and 100
					end
					if chance and ownHit then
						local hits, crit = policy.HitRate(context, out), (out.CritChance or 0) / 100
						local valid = suffix == ""
						if suffix == " with this weapon" then
							local hand = line.slot == "Weapon 1" and 1 or line.slot == "Weapon 2" and 2
							valid = hand and main.skillFlags.attack and main.skillFlags["weapon" .. hand .. "Attack"]
							if valid then
								local hands = (main.skillFlags.weapon1Attack and 1 or 0) + (main.skillFlags.weapon2Attack and 1 or 0)
								hits = hits / math.max(1, hands)
								crit = ((out[hand == 1 and "MainHand" or "OffHand"] or { }).CritChance or out.CritChance or 0) / 100
							end
						end
						if valid then rate = rate + hits * crit * math.min(100, tonumber(chance)) / 100; t_insert(reasons, line.source) end
					elseif line.text:match("^trigger level %d+ summon spectral " .. kind .. " on kill$") and killRate > 0 then
						rate = rate + killRate; t_insert(reasons, line.source)
					end
				end
			end
			if calculated and rate > 0 and skill.minion then
				local cap = calculated[skill.minion.minionData.limit or ""] or 0
				local cooldown, duration = calculated.Cooldown or 0, calculated.Duration or 0
				if cooldown > 0 then rate = math.min(rate, 1 / cooldown) end
				if cap > 0 and duration > 0 then
					local var = id == "RaiseSpiders" and "raiseSpidersSpiderCount" or id == "SummonSpectralTiger" and "configSpectralTigerCount"
						or "configSpectralWolfCount"
					local expected = rate * math.min(seconds, duration)
					local triggers = math.max(1, math.floor(expected + 1e-8))
					number(var, math.min(cap, triggers * perTrigger), table.concat(reasons, "\n") .. string.format("\n%.2f/s, %g each, %gs life, cap %g.", rate,
						perTrigger, duration, cap)
						.. (expected < 1 and "\nConfirm a trigger actually happens." or ""),
						id == "RaiseSpiders" or expected < 1)
				end
			end
		end
	end
	if darkPact and not skeletonUnknown then
		local life, count = nil, 0
		for value in pairs(skeletonLives) do life, count = value, count + 1 end
		if count == 1 then
			emit("darkPactSkeletonLife", "Dark Bargain casts on your Skeleton."
				.. (skeletonAmbiguous and "\nConfirm which Skeleton you target." or "\nOnly one Skeleton type applies."), skeletonAmbiguous,
				"Calculated Skeleton maximum Life: " .. life, life)
		end
	end
	if golems.Carrion then
		local count = 0
		for _, value in pairs(nearby) do count = count + value end
		if count > 0 then
			number("carrionGolemNearbyMinion", count, table.concat(nearbyReasons, "\n") .. "\nConfirm these minions stay nearby.", true)
		end
	end
	local familyCount = 0
	for _ in pairs(golemFamilies) do familyCount = familyCount + 1 end
	-- Each Golem gem supplies its own base count (one for ordinary Golems).
	-- Do not mistake a Hordes gem's larger local base for shared extra slots.
	local globalLimit = math.max(0, math.floor(env.player.modDB:Override(nil, "ActiveGolemLimit")
		or ((1 + env.player.modDB:Sum("BASE", nil, "ActiveGolemLimit")) * calcLib.mod(env.player.modDB, nil, "ActiveGolemLimit"))))
	if familyCount > 1 and globalLimit >= familyCount then
		for _, pair in ipairs(golemPairs) do
			if golems[pair[2]] and golems[pair[3]] then
				emit(pair[1], "Golem limit " .. globalLimit .. " fits one of each of "
					.. familyCount .. " families.\nConfirm equal counts.", true, "Maintain equal positive "
					.. pair[2] .. " and " .. pair[3] .. " Golem counts?")
			end
		end
	end
	if bestBrands then
		number("ActiveBrands", bestBrands.count, string.format("%s: %.2f casts/s, %gs, limit %g.", bestBrands.name, bestBrands.rate,
			bestBrands.duration, bestBrands.cap), bestBrands.review)
	end
end

M.Minions = Minions

-- ============================================================================
-- Position: build-created actors and effects provide sources. Occupancy and a
-- first-hit profile are explicit assumptions; geometry is not invented.
-- ============================================================================
local Position = model.Registry()
Position.parentRules = { conditionMoving = {
	condition = text.conditionMoving.condition,
	confirmation = "Select it with the stationary timer.",
} }
local function placement(var, mode, condition, confirmation, evaluate, kind)
	Position.Define({ var = var, model = mode, kind = kind or "assisted", condition = condition, confirmation = confirmation, evaluate = evaluate })
end
local function friendly(facts)
	if facts.friendlyPopulation then return facts.friendlyPopulation end
	local groups, damageable, sources = { }, { }, { }
	for _, skill in ipairs(facts.Active()) do
		local actor = skill.minion
		if actor and not actor.hostile then
			local id = skill.activeEffect.grantedEffect.id
			local intrinsic = isValueInArray(skill.activeEffect.grantedEffect.minionList or { }, actor.type)
				or id:match("^RaiseSpectre") and isValueInArray(facts.context.build.spectreList, actor.type)
			local probe = intrinsic and facts.Probe(skill)
			actor = probe and probe.minion
			local key = actor and actor.minionData.limit
			local capacity = key and probe.player.output[key] or 0
			local count = math.max(0, capacity or 0)
			if not skill.skillFlags.permanentMinion then
				local out = probe and probe.player.output
				local rate = out and model.UseRate(facts.context, skill, out) or 0
				count = math.min(count, math.floor(rate * math.min(facts.seconds, out and out.Duration or 0) + 1e-8))
			end
			if count > 0 then
				groups[key] = math.max(groups[key] or 0, count)
				if not skill.skillTypes[SkillType.MinionsAreUndamagable] and not actor.modDB:Flag(nil, "Condition:CannotBeDamaged") then
					damageable[key] = math.max(damageable[key] or 0, count)
				end
				t_insert(sources, skill.activeEffect.grantedEffect.name .. ": " .. count .. " (summon window)")
			end
		end
	end
	local result = { count = 0, damageable = 0, reason = table.concat(sources, "\n") }
	for _, count in pairs(groups) do result.count = result.count + count end
	for _, count in pairs(damageable) do result.damageable = result.damageable + count end
	facts.friendlyPopulation = result
	return result
end
placement("conditionStationary", "amount", text.conditionStationary.condition, "Confirm gaps and clear Always Moving.", function(facts)
	local main, out = facts.context.mainSkill, facts.env.player.output
	if not model.IsDirect(main) or main.minion or main.skillTypes[SkillType.Movement] or main.skillTypes[SkillType.Travel] or main.skillTypes[SkillType.Instant]
		or facts.env.player.modDB:GetCondition("Moving") or (out.Time or 0) <= 0 then return end
	local assumption = policy.Scenario("Stay still from the start.")
	local original = facts.context.originalBuild.configTab
	local moving = original.input.conditionMoving == true
	-- Clearing maps means moving between packs, so only a boss window can be continuous.
	local continuous = not facts.context.mapping and main.skillTypes[SkillType.Channel] and policy.Activity(facts.context, out) == 1 and not moving
	if moving then
		assumption.applyTogether = { "conditionMoving" }
		facts.context.suggest("conditionMoving", "Clears Always Moving for this window.", true, "Clear Always Moving for the stationary window", false, nil,
			{ automatic = false, description = "Confirm the stationary window.",
				applyTogether = { "conditionStationary" } })
	end
	return { amount = facts.seconds, assumption = assumption, review = not continuous,
		reason = continuous and ("Your main skill " .. main.activeEffect.grantedEffect.name .. " channels in place for " .. facts.seconds
			.. "s main-skill window.")
			or ("Your main skill " .. main.activeEffect.grantedEffect.name .. " casts in place. Stay still for " .. facts.seconds
				.. "s, including between casts.") }
end, "automatic")
placement("multiplierNearbyAlly", "amount", text.multiplierNearbyAlly.condition, text.multiplierNearbyAlly.confirmation, function(facts)
	local population = friendly(facts)
	if population.count > 0 then
		return { amount = population.count, reason = population.reason .. "\nConfirm these minions stay nearby." }
	end
end)
placement("multiplierNearbyCorpse", "amount", text.multiplierNearbyCorpse.condition, text.multiplierNearbyCorpse.confirmation, function(facts)
	local best
	for _, skill in ipairs(facts.Active()) do
		if model.IsDirect(skill) and not skill.minion and skill.skillTypes[SkillType.CreatesCorpse] then
			local stats, probe = facts.Stats(skill), facts.Probe(skill)
			local out = probe and probe.player.output
			local cap = stats.desecrate_maximum_number_of_corpses or 0
			local perUse = stats.desecrate_number_of_corpses_to_create or (out and out.ProjectileCount or 0)
			local rate = out and model.UseRate(facts.context, skill, out) or 0
			local uses = math.floor(rate * facts.seconds + 1e-8)
			if out and cap > 0 and perUse > 0 and uses > 0 then
				-- A conservative initial budget avoids counting recovery that
				-- arrives after a scheduled cast, while full-pool regen is lost.
				local mana = out.ManaUnreserved or 0
				local life = (out.LifeUnreserved or 0) - 1
				local cost, lifeCost = out.ManaCost or 0, out.LifeCost or 0
				if cost > 0 then uses = math.min(uses, math.floor(mana / cost)) end
				if lifeCost > 0 then uses = math.min(uses, math.floor(life / lifeCost)) end
				if cost > (out.ManaUnreserved or 0) or lifeCost >= (out.LifeUnreserved or 0) then uses = 0 end
				local count = math.min(cap, uses * perUse)
				if count > 0 and (not best or count > best.amount) then
					best = { amount = count, reason = string.format("%s: %g uses in %gs, %g corpses each.", skill.activeEffect.grantedEffect.name, uses,
						facts.seconds, perUse, cap) }
				end
			end
		end
	end
	return best
end)
local function link(facts)
	local skill
	for _, active in ipairs(facts.Active()) do if active.skillTypes[SkillType.Link] and model.IsDirect(active) then skill = active break end end
	if not skill or not facts.env.player.modDB:Flag(nil, "Condition:CanLinkToMinions") or friendly(facts).damageable <= 0 then return end
	local probe = facts.Probe(skill)
	if not probe or (probe.player.output.Duration or 0) < facts.seconds then return end
	return skill
end
placement("multiplierLinkedTargets", "amount", text.multiplierLinkedTargets.condition, text.multiplierLinkedTargets.confirmation, function(facts)
	local skill = link(facts)
	if skill then
		return { amount = 1, requires = { "linkedToMinion" }, reason = "Actual " .. skill.activeEffect.grantedEffect.name .. " can link a minion. Confirm the Link." }
	end
end)
for _, var in ipairs({ "conditionNearLinkedTarget", "conditionBetweenYouAndLinkedTarget" }) do
	placement(var, "boolean", text.linkedTargetPosition.condition, text.linkedTargetPosition.confirmation, function(facts)
		local skill = link(facts)
		if skill then
			return { requires = { "linkedToMinion" }, reason = "Actual " .. skill.activeEffect.grantedEffect.name .. " links a target; confirm its position." }
		end
	end)
end
placement("conditionAtCloseRange", "boolean", text.conditionAtCloseRange.condition, text.conditionAtCloseRange.confirmation, function(facts)
	if facts.MainHit() and facts.context.mainSkill.skillTypes[SkillType.Melee] and facts.context.mainSkill.skillTypes[SkillType.MeleeSingleTarget] then
		return { reason = "Your main Melee Strike hits up close." }
	end
end)
placement("tornadoShotSecondaryHitChance", "default", text.tornadoShotSecondaryHitChance.condition, text.tornadoShotSecondaryHitChance.confirmation,
	function(facts)
	local original = facts.context.originalBuild.configTab
	if original.input.tornadoShotSecondaryHitChance == nil and original.placeholder.tornadoShotSecondaryHitChance == nil then return end
	for _, skill in ipairs(facts.Active()) do
		if skill.activeEffect.grantedEffect.id == "TornadoShot" and skill.skillPart == 2 then
			local probe = facts.Probe(skill)
			if probe and (probe.player.output.ReturnChance or 0) == 0 then return { reason = "PoB calculates the secondary hit chance for this Tornado Shot." } end
		end
	end
end, "calculated-default")
M.Position = Position

-- ============================================================================
-- Batch: declarative event/time rules. Source adapters supply facts; shared
-- models handle estimation, review policy, native choices and documentation.
-- ============================================================================
local Batch = model.Registry()
local incoming = {
	{ "conditionBeenHitRecently", "rate", "hit",
		"Enemies can hit you." },
	{ "multiplierBeenHitRecently", "rate", "hit count", "Uses the Been Hit Recently rate.", "count" },
	{ "conditionBeenHitByAttackRecently", "attack", "attack hit", "Only incoming attack hits count." },
	{ "conditionHitBySpellDamageRecently", "spellDamage", "spell damage", "Only damaging spell hits count." },
	{ "conditionBeenCritRecently", "critical", "critical hit", "Enemies can land critical hits.", nil, true },
}
for _, element in ipairs({ "Fire", "Cold", "Lightning" }) do
	t_insert(incoming, { "conditionHitBy" .. element .. "DamageRecently", element, element .. " damage",
		"Enemy hits deal positive " .. element
		.. " hit damage to you." })
end
t_insert(incoming, { "conditionTakenFireDamageFromEnemyHitRecently", "Fire", "enemy Fire damage", "Enemy hits deal Fire damage to you." })
for _, entry in ipairs(incoming) do
	local var, key, label, condition, model, review = unpack(entry)
	Batch.Define({ var = var, model = model or "event", kind = review and "assisted" or "automatic", window = 4,
		condition = "Uses your enemy hit rate. " .. condition,
		confirmation = text.incomingEvent.confirmation,
		evaluate = function(facts)
			local hit = facts.Incoming()
			local rate = hit[key] or hit.elemental[key] or 0
			if rate > 0 then return { rate = rate, label = "Recent incoming " .. label, reason = hit.reason .. "\n" .. condition, review = review } end
		end,
	})
end
Batch.Define({ var = "conditionBeenSavageHitRecently", model = "event", kind = "assisted", window = 4,
	condition = text.conditionBeenSavageHitRecently.condition,
	confirmation = text.conditionBeenSavageHitRecently.confirmation,
	evaluate = function(facts)
		local hit, out = facts.Incoming(), facts.env.player.output
		if hit.damage <= 0 or (out.Life or 0) <= 0 then return end
		local damage = { }
		for _, kind in ipairs({ "Physical", "Fire", "Cold", "Lightning", "Chaos" }) do damage[kind] = out[kind .. "TakenHit"] or 0 end
		local remaining = facts.context.build.calcsTab.calcs.reducePoolsByDamage(nil, damage, facts.env.player)
		local lost = math.max(0, (out.LifeRecoverable or 0) - remaining.Life)
		if lost / out.Life < 0.15 then return end
		return { rate = hit.damage, reason = hit.reason .. string.format("\nLoses %g Life through the simulated starting pools (%.1f%%).", lost, 100 * lost / out.Life, out.Life) }
	end,
})

-- neutral: the option's own "none" value during detection. Pass `nil` for lists
-- without a neutral entry (the input is cleared instead of set to a stray value).
local function phase(var, condition, evaluate, neutral)
	Batch.Define({ var = var, model = "choice", kind = "assisted", neutralValue = neutral,
		condition = condition, confirmation = "Choose the window to model.", evaluate = evaluate })
end
-- A timed cycle: the allowed set starts from the native None (0); collect adds
-- each proven phase and its source line, and returns the closing note.
local function cycle(var, condition, collect)
	phase(var, condition, function(facts)
		local allowed, reasons = { [0] = true }, { }
		local note = collect(facts, allowed, reasons)
		if #reasons > 0 then return { allowed = allowed, reason = table.concat(reasons, "\n") .. "\n" .. note } end
	end, 0)
end
cycle("buffPendulum", "Needs a timed Pendulum grant.", function(facts, allowed, reasons)
	for _, line in ipairs(facts.Lines()) do
		if line.text:match("gain %d+%% increased area of effect for %d+ seconds") then allowed.AREA = true; t_insert(reasons, line.source) end
		if line.text:match("gain %d+%% increased elemental damage for %d+ seconds") then allowed.DAMAGE = true; t_insert(reasons, line.source) end
	end
	return "Choose a Pendulum window."
end)
cycle("buffConflux", text.buffConflux.condition, function(facts, allowed, reasons)
	for _, line in ipairs(facts.Lines()) do
		for _, kind in ipairs({ "chilling", "shocking", "igniting" }) do
			if line.text:match("gain " .. kind .. " conflux for %d+ seconds") then allowed[kind:upper()] = true; t_insert(reasons, line.source) end
		end
		local chance = tonumber(line.text:match("(%d+)%% chance to gain elemental conflux for %d+ seconds when you kill an enemy"))
		if chance and chance > 0 and facts.PersonalKills() then
			allowed.ALL = true; t_insert(reasons, line.source .. "\nAssumes regular kills.")
		end
	end
	return "Choose a phase from these sources."
end)
cycle("buffHeartstopper", "Needs a timed Heartstopper grant.", function(facts, allowed, reasons)
	for _, line in ipairs(facts.Lines()) do
		if line.text:match("take %d+%% less damage from hits for %d+ seconds") then
			allowed.HIT, allowed.AVERAGE = true, true; t_insert(reasons, line.source)
		end
		if line.text:match("take %d+%% less damage over time for %d+ seconds") then
			allowed.DOT, allowed.AVERAGE = true, true; t_insert(reasons, line.source)
		end
	end
	return "Choose a window or Average."
end)
for _, buff in ipairs({
	{ "buffBastionOfHope", "a real periodic attack-block grant", "%+%d+%% chance to block attack damage for %d+ seconds? every %d+ seconds" },
	{ "buffNgamahuFlamesAdvance", "a periodic extra-Fire grant",
		"every %d+ seconds, gain %d+%% of physical damage as extra fire damage for %d+ seconds" },
}) do
	local var, source, pattern = unpack(buff)
	Batch.Define({ var = var, model = "boolean", kind = "assisted", condition = "Find " .. source .. " on your gear or passives.",
		confirmation = "Confirm the active window.",
		evaluate = function(facts)
			for _, line in ipairs(facts.Lines()) do
				if line.text:match(pattern) then
					return { reason = line.source .. "\nConfirm the active window." }
				end
			end
		end,
	})
end
phase("conditionHaveAugyre", "Choose an Augyre keystone window.", function(facts)
	if facts.env.player.modDB:Flag(nil, "Condition:HaveAugyre") then return { reason = "Your Augyre grants a keystone that changes over time." } end
end)
phase("GamblesprintMovementSpeed", "Needs Gamblesprint.", function(facts)
	if facts.env.player.modDB:Flag(nil, "Condition:HaveGamblesprint") then
		return { reason = "Gamblesprint gives a random Movement Speed roll." }
	end
end, 0)

for _, family in ipairs({ { "Absolution", "absolutionSkillDamageCountedOnce" }, { "Dominating Blow", "dominatingBlowSkillDamageCountedOnce" },
	{ "Holy Strike", "holyStrikeSkillDamageCountedOnce" } }) do
	local name, var = unpack(family)
	Batch.Define({ var = var, model = "boolean", kind = "automatic", condition = "An enabled self-used " .. name .. " with a minion uses Count > 1.",
		confirmation = "Counts your damage once.",
		evaluate = function(facts)
			local needed, safe, reasons = false, true, { }
			for _, skill in ipairs(facts.Active()) do
				if skill.activeEffect.grantedEffect.name:match("^" .. name) and skill.socketGroup and skill.socketGroup.includeInFullDPS then
					local count = facts.SkillCount(skill)
					if count > 1 then
						local compatible = model.IsDirect(skill) and skill.minion and not skill.minion.hostile and not skill.mirage
						for _, effect in ipairs(skill.effectList) do
							if effect.grantedEffect.support and effect.grantedEffect.name:find("Spell Cascade", 1, true) then
								compatible = false
							end
						end
						if not compatible then safe = false end
						needed = true; t_insert(reasons, skill.activeEffect.grantedEffect.name .. ": in Full DPS with Count " .. count)
					end
				end
			end
			if needed and safe then
				return { reason = table.concat(reasons, "\n") .. "\nCounts your damage once." }
			end
		end,
	})
end

M.Batch = Batch

return M
