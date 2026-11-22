-- Path of Building
--
-- Capability inventory and per-setting rule descriptions for Auto-configure.
-- Rules holds the rule text (condition/confirmation) quoted by marker tooltips
-- and the Details popup; Support assesses every Configuration input, defines the
-- scan scope and the coverage counts, and supplies marker text. No scan runs
-- here. Depends on ConfigAutoModel, ConfigAutoRulesBuild, ConfigAutoRulesCombat
-- and ConfigOptions.
local t_insert = table.insert
local t_concat = table.concat

local M = { }
local Rules, Support = { }, { }
M.Rules, M.Support = Rules, Support

local model = require("Modules.ConfigAutoModel")
local rulesBuild = require("Modules.ConfigAutoRulesBuild")
local rulesCombat = require("Modules.ConfigAutoRulesCombat")
local policy, profiles, uncertain, preferences, plainText = model.Policy, model.Profiles, model.Uncertain, model.Preferences, model.Text
local advanced, ground, minions, batch, choices, position, shrines, quests, guided = rulesBuild.Advanced, rulesBuild.Ground, rulesBuild.Minions,
	rulesBuild.Batch, rulesBuild.Choices, rulesBuild.Position, rulesBuild.Shrines, rulesBuild.Quests, rulesBuild.Guided
local events, mechanics, timeline, buildup, windows, history, stacks, resources, stuns = rulesCombat.Events, rulesCombat.Mechanics,
	rulesCombat.Timeline, rulesCombat.Buildup, rulesCombat.Windows, rulesCombat.History, rulesCombat.Stacks, rulesCombat.Resources, rulesCombat.Stuns
local options = require("Modules.ConfigOptions")
local byName, sections = model.optionsByName, model.sectionsByName

-- ============================================================================
-- Rule text
-- ============================================================================
-- One catalogue entry per setting. Settings the scanner (ConfigAutoScan)
-- implements directly, rather than a detector module with its own capability
-- inventory, carry their marker kind and inventory method here as well, so the
-- inventory entry and its rule text are declared together and cannot drift.
-- Settings a module already claims are deliberately absent: the module wins.
-- Text that quotes a sensitivity threshold is a function of the values in force.
local catalogue = { }
local core = { capabilities = { } }
local function rule(names, condition, confirmation, method, kind)
	for var in names:gmatch("%S+") do
		assert(not catalogue[var], var .. " is declared twice")
		catalogue[var] = { condition = condition, confirmation = confirmation }
		if method then core.capabilities[var] = { kind = kind or "automatic", method = method } end
	end
end
local function rate(names, event, window, method, extra)
	window = window or policy.recentWindow
	rule(names, function(values)
		return event .. ". Automatic when expected events in " .. window .. "s is at least " .. values.expectedEventThreshold .. "."
	end, "Confirm the event below that threshold." .. (extra or ""), method)
end
local function resolve(text, values) return type(text) == "function" and text(values) or text end

local STATE = "Native state with manual boxes removed."
local RATES = "Main-skill hit, crit and ailment rates."
local ENABLING = "Enabling source, then confirm its use."
-- Native states with no dedicated text: Rules.Get explains them from the
-- model's Conditions/Defaults/availability tables.
rule([[conditionLowLife conditionFullLife conditionUnbrokenWard conditionUsingFlask conditionSummonedTotemRecently conditionAttackedRecently
conditionCastSpellRecently conditionUsedMovementSkillRecently conditionUsedMinionSkillRecently conditionUsedVaalSkillRecently conditionLeeching
conditionLeechingLife conditionLeechingEnergyShield buffUnholyMight buffChaoticMight buffPhasing buffFortification buffTailwind buffAdrenaline
buffElusive conditionEnemyCursed conditionEnemyMaimed conditionEnemyHindered conditionEnemyIntimidated]], nil, nil, STATE)
rule("buffOnslaught", "A real Onslaught source; on-kill uses the kill rate.", "Confirm low-frequency on-kill sources.", STATE)
rule("minionBuffOnslaught", "A real Onslaught source for the minion.", "Confirm upkeep on all minions.")
for _, entry in ipairs({
	{ "conditionBlockedRecently", "either attack/projectile block or spell block", "blockThreshold" },
	{ "conditionBlockedAttackRecently", "attack/projectile block", "blockThreshold" },
	{ "conditionBlockedSpellRecently", "spell/projectile-spell block", "blockThreshold" },
	{ "conditionSuppressedRecently", "effective spell suppression", "suppressionThreshold" },
}) do
	rule(entry[1], function(values) return "Calculated " .. entry[2] .. " >= " .. values[entry[3]] .. "%." end,
		function(values) return "Needs " .. values.incomingEventThreshold .. " expected events in 4s; confirm below." end)
end
rule("conditionBlockedHitFromUniqueEnemyInPast10Sec", function(values) return "Boss target, block >= " .. values.blockThreshold .. "% and "
	.. values.incomingEventThreshold .. " expected blocks in 10s." end, "Confirm below either threshold.")
rule("BlockedPast10Sec", "Expected blocks over min(fight time, 10s).", "Confirm fewer than one block.")
rule("multiplierHitsSuppressedRecently", "Expected suppressed spell hits in 4s.", "Confirm fewer than one suppression.")
rate("conditionHitRecently", "The main skill hits", nil, STATE, " Or confirm a hit with another skill.")
rate("conditionHitSpellRecently", "The main spell hits", nil, STATE, " Or confirm a hit with another spell.")
rate("conditionHitRecentlyWithWeapon", "The main attack lands weapon hits")
rate("conditionCritRecently conditionSkillCritRecently", "The main skill crits", nil, RATES)
rate("conditionNonCritRecently", "The main skill hits without crits", nil, RATES)
for _, name in ipairs({ "Ignite", "Poison" }) do
	rate("condition" .. (name == "Ignite" and "Ignited" or "Poisoned") .. "EnemyRecently", "The main skill applies " .. name, nil, RATES)
end
for _, element in ipairs({ "Fire", "Cold", "Lightning" }) do
	rule("conditionEnemy" .. element .. "Exposure", "The main skill applies " .. element .. " Exposure on hit.", nil, "Exposure on hit.")
	rule("enemyConditionHitBy" .. element .. "Damage", "PoB derives a " .. element .. " damage hit.")
end
for _, color in ipairs({ "Red", "Green", "Blue", "White" }) do
	rule("overrideEmpty" .. color .. "Sockets", "Empty " .. color .. " sockets on equipped items.", nil, "Empty sockets on equipped items.")
end
for _, charge in ipairs({ "Power", "Frenzy", "Endurance" }) do
	local source = "Real " .. charge .. " Charge generation."
	local estimate = " Count = generation/s x min(fight time, charge duration), capped."
	local confirm = "Confirm infrequent generation or charge loss."
	rule("use" .. charge .. "Charges override" .. charge .. "Charges", source .. estimate, confirm)
	if charge ~= "Endurance" then rate("conditionGained" .. charge .. "ChargeRecently", "Real " .. charge .. " Charge generation") end
	rule("minionsUse" .. charge .. "Charges", "A source grants minions " .. charge .. " Charges.", "Confirm minion hits and buildup.")
end
for _, buff in ipairs({ { "buffArcaneSurge", "Arcane Surge", "mana" }, { "buffLifetap", "Lifetap", "life" } }) do
	rule(buff[1], "A " .. buff[2] .. " source, or enough " .. buff[3] .. " spent.", "Confirm auxiliary or low spending.",
		"Support applied and enough spending.")
end
rule("infusedChannellingInfusion", "A channel supported by Infused Channelling.", "Confirm auxiliary channels.", "Infused Channelling applied.")
rule("conditionHaveTotem", "A summoned or enabled totem skill.", "Confirm auxiliary totems.", STATE)
rule("conditionChannelling", "PoB derives Channelling from the main skill.", nil, STATE)
rule("conditionLowMana", "PoB classifies your mana as Low Mana.", nil, STATE)
rule("conditionLowEnergyShield", "PoB classifies your ES as Low Energy Shield.", nil, STATE)
rule("conditionLeechingMana", "PoB derives Mana Leeching.", nil, STATE)
rule("conditionUsingTincture", "An enabled tincture is equipped.", nil, STATE)
rule("conditionEnemyUnnerved", "A real Unnerve source, or main-spell Unnerve on hit.", "Confirm low application rates.", STATE)
rule("conditionEnemyBurning", "Native Burning, Righteous Fire or Scorching Ray.", "Confirm the target stays in the burn.", STATE)
for _, actor in ipairs({ { "conditionKilledRecently", "player" }, { "conditionTotemsKilledRecently", "totem" },
	{ "conditionMinionsKilledRecently", "minion" } }) do
	rule(actor[1], "Regular kills by the main " .. actor[2] .. ".", nil, actor[2] == "player" and RATES or nil)
end
rule("channellingCycloneCheck", "An enabled self-used Cyclone.", "Confirm auxiliary Cyclone use.")
rule("conditionUsedSkillRecently", "An enabled main skill in use.", nil, RATES)
rule("conditionUsedBrandRecently", "The main skill is a Brand.")
for _, element in ipairs({ "Fire", "Cold" }) do rule("conditionUsed" .. element .. "SkillRecently", "The main skill is a " .. element .. " skill.",
	nil, RATES) end
for _, entry in ipairs({ { "conditionUsedWarcryRecently", "Warcry" }, { "conditionUsedTravelSkillRecently", "Travel skill" },
	{ "conditionUsedDashRecently", "Dash" } }) do
	rule(entry[1], "A self-used " .. entry[2] .. " with cooldown <= 4s.", "Confirm longer intervals.")
end
rule("conditionConvergence", "A Convergence source on unique hits.", "Confirm the Convergence window.", ENABLING, "assisted")
rule("summonLightningGolemEnableWrath", "An enabled Summon Lightning Golem.", "Confirm the aura reaches you.", ENABLING, "assisted")
rule("waveOfConvictionExposureType", "Wave of Conviction's highest elemental hit.", "Confirm use and hits.", "Wave of Conviction hit and upkeep.")
rule("elementalArmyExposureType", "Elemental Army minion's highest element.", "Confirm minion hits and uptime.", "Supported minion's element.",
	"assisted")
for _, question in ipairs(advanced.skillQuestions) do
	local requirements = question.minion and " Needs a minion skill." or ""
	if question.needsMinion then requirements = requirements .. " Needs another minion." end
	if question.projectile then requirements = requirements .. " Needs projectiles." end
	if question.other then requirements = requirements .. " Needs " .. question.other .. "." end
	if question.otherBlade then requirements = requirements .. " Needs Lingering Blades." end
	rule(question.var, "Enabled: " .. t_concat(question.skills, " / ") .. "." .. requirements, question.question)
end
-- Support questions the scanner asks for a support gem it finds applied.
Support.skillQuestions = {
	["Feeding Frenzy"] = { var = "feedingFrenzyFeedingFrenzyActive", question = "Do your supported minions hit enemies to maintain Feeding Frenzy?" },
	["Predator"] = { var = "deathmarkDeathmarkActive", question = "Do you use Signal Prey to mark your target for your minions?" },
	["Close Combat"] = { var = "closeCombatCombatRush", question = "Include Combat Rush after hitting with the supported melee skill?" },
	["Innervate"] = { var = "innervateInnervation", mapping = true,
		question = "Do you kill shocked enemies with the supported skill to maintain Innervation?" },
}
for name, entry in pairs(Support.skillQuestions) do
	rule(entry.var, name .. " is applied." .. (entry.mapping and " Needs regular kills." or ""), entry.question, name .. " applied.", "assisted")
end
-- Resource/stack models.
rule("multiplierRage", "Real Rage generation over fight time, capped.", "Confirm Rage spending or loss.")
rule("multiplierBleedsOnEnemy", "Crimson Dance and expected active Bleeds.")
rule("multiplierRuptureStacks", "Rupture from critical Bleeds, max 4.", "Confirm fewer than one stack.")
rule("multiplierCorrosionStackCount", "Corrosion applications on attack hit.", "Confirm infrequent application.")
for _, ailment in ipairs({ "Shock", "Scorch" }) do rule(ailment .. "Stacks", ailment .. " applications, capped.", "Confirm crit-only or low counts.") end
rule("multiplierFreezeShockIgniteOnEnemy", "Verified Freeze, Shock and Ignite, max 3.", "Confirm if any ailment needs confirming.")
rule("aspectOfTheSpiderWebStacks", "Aspect of the Spider webs over time.")
for _, kind in ipairs({ { "Ash", "Ignite" }, { "Frost", "Freeze" } }) do rule("conditionEnemyCoveredIn" .. kind[1],
	"A Covered in " .. kind[1] .. " source on " .. kind[2] .. ".", "Confirm infrequent application.") end
rule("conditionFocused", "An enabled Focus skill or trigger.", "Confirm the Focus window.")
rule("conditionSoulGainPrevention", "A self-used Vaal skill.", "Confirm Vaal use in this window.")
rule("MomentumSwiftnessStacks", "Momentum applied to the main attack.", "Confirm moving to gain Swiftness.")
for _, entry in ipairs({ { "multiplierKilledRecently", "player" }, { "multiplierTotemsKilledRecently", "totem" },
	{ "multiplierMinionsKilledRecently", "minion" } }) do rule(entry[1], "Regular kills by the main " .. entry[2] .. " in 4s.") end
rule("multiplierRampage", "A Rampage source and 15+ expected kills.")
rule("useSiphoningCharges", "A Siphoning Charge source on skill use.", "Confirm Siphoning Charge buildup.")
rule("useChallengerCharges", "A Challenger Charge source in your stance.", "Confirm stance and trigger.")
rule("useBlitzCharges", "A Blitz Charge source on crit.", "Confirm buildup.")
rule("buffHerEmbrace", "Her Embrace on Ignite, with Ignite chance.", "Confirm the Her Embrace window.")
rule("buffDivinity", "Divine Charge generation and Divinity source.", "Confirm the Divinity window.")
rule("conditionChampionIntimidate", "Intimidate on full-Life hit source.", "Confirm hitting full-Life enemies.")
rule("conditionInsane", "Enabled Unhinge.", "Confirm the Insane state.")
rule("changedStance", "Enabled Blood and Sand or Flesh and Stone.", "Confirm a stance change in 4s.")
rule("linkedToMinion", "A Link skill that can target minions.", "Confirm linking a minion.")
rule("intensifyIntensity", "The main skill gains Intensity, capped.", "Confirm stationary casting.")
rule("OverloadedIntensity", "Overloaded Intensity on the main skill.", "Confirm losing six Intensity.")
rule("multiplierWitheredStackCount", "Wither applications, max 15.", "Confirm continued application.")
rule("sigilOfPowerStages", "Sigil of Power stages from mana spent.", "Confirm spending inside the Sigil.")
rule("conditionSacrificeMinion", "A bow modifier sacrifices a minion.", "Confirm keeping minions up.")
rule("conditionBleeding", "A Bleed reflection source.", "Confirm the reflected Bleed.")
rule("conditionPoisoned multiplierPoisonOnSelf", "A Poison reflection source, max 100.", "Confirm self-poison uptime.")
-- Event counters and timing.
for _, resource in ipairs({ "Mana", "Life" }) do rule("multiplier" .. resource .. "SpentRecently", resource .. " paid in 4s.",
	"Confirm low recovery or resummoning.") end
rule("multiplierSkillUsedRecently", "Main skill activations in 4s.", "Confirm Vaal use or channel restarts.")
rule("multiplierNonInstantSpellCastRecently", "Distinct non-instant spells you cast.", "Confirm Vaal or channel casts.")
rule("multiplierCritRecently", "Attack crits in 4s.", "Confirm fewer than one crit.")
for _, name in ipairs({ "Ignite", "Poison" }) do rule("multiplier" .. name .. "AppliedRecently", name .. " applications in 4s.",
	"Confirm fewer than one application.") end
rule("multiplierAppliedAilmentsRecently", "Distinct elemental ailments applied.", "Confirm crit-only estimates.")
rate("conditionCausedBleedingRecently", "The main skill causes Bleeding")
rate("conditionImpaledRecently", "The main skill Impales")
for _, entry in ipairs({ { "multiplierMineDetonatedRecently", "Mine", "detonation" },
	{ "multiplierTrapTriggeredRecently", "Trap", "triggering" } }) do rule(entry[1], entry[2] .. " " .. entry[3] .. "s in 4s.",
	"Confirm fewer than one event.") end
rate("conditionThrownTrapOrMineRecently", "The main trap/mine skill is thrown")
rate("conditionTotemsHitSpellRecently", "The main spell totem hits")
rule("conditionUsedWarcryInPast8Seconds multiplierWarcryUsedRecently", "Self-used warcries on cooldown.", "Confirm long intervals.")
rule("conditionCursedEnemyRecently conditionCastMarkRecently", "A self-cast curse or Mark.", "Confirm auxiliary refresh.")
rule("conditionSpawnedCorpseRecently conditionConsumedCorpseRecently conditionConsumedCorpseInPast2Sec multiplierCorpseConsumedRecently",
	"Enabled corpse creation and consumption.", "Confirm auxiliary consumption.")
for _, flask in ipairs({ "Amethyst", "Ruby", "Sapphire", "Topaz" }) do rule("conditionUsed" .. flask .. "FlaskRecently", "An active " .. flask
	.. " Flask.") end
rule("LostNonVaalBuffRecently", "A non-Vaal Guard expiring in 4s.", "Confirm longer intervals.")
rule("minionsConditionCreatedRecently conditionMinionsDiedRecently", "The main skill summons temporary minions.", "Confirm other minion types.")
rule("multiplierChannelling", "Channel seconds = fight time.", "Use a shorter fight time for shorter channels.")
rule("conditionCastLast1Seconds", "Three or more main casts per second.", "Confirm slower casts.")
rule("multiplierCastLast8Seconds", "Main casts in 8s.", "Confirm fewer than one cast.")
rule("multiplierUsedVaalSkillInPast8Seconds", "One use of each self-used Vaal skill.", "Confirm souls and use in 8s.")
for _, window in ipairs({ 8, 10 }) do rule("conditionSummonedGolemInPast" .. window .. "Sec", "An enabled Golem skill.",
	"Confirm resummoning within " .. window .. " seconds.") end
rule("enemyMultiplierEnemyPresenceSeconds", "Presence seconds = fight time.", "Confirm the target stays in your presence.")
rule("arcaneCloakUsedRecentlyCheck", "A self-used Arcane Cloak.", "Confirm use at full mana.")
rule("conditionKilledLast3Seconds", "Regular player kills in 3s.")
rule("conditionKilledPoisonedLast2Seconds", "Regular kills with Poison.", "Confirm infrequent Poison.")
rule("conditionKilledAffectedByDoT", "Regular kills with a DoT.", "Confirm infrequent ailments.")
rule("conditionShatteredEnemyRecently", "Regular kills with Freeze.", "Confirm infrequent Freeze.")
rule("multiplierShockedEnemyKilledRecently multiplierShockedNonShockedEnemyRecently", "Shocked kills in 4s.", "Confirm infrequent Shock.")
for _, ailment in ipairs({ { "Chill", "Chilled", "conditionEnemyChilledEffect" }, { "Shock", "Shocked", "conditionShockEffect" },
	{ "Scorch", "Scorched", "conditionScorchedEffect" }, { "Brittle", "Brittle", "conditionBrittleEffect" },
	{ "Sap", "Sapped", "conditionSapEffect" } }) do
	local base = "A " .. ailment[1] .. " source or applying hit."
	rule("conditionEnemy" .. ailment[2], function(values) return base .. " Automatic at " .. values.effectRefreshThreshold .. " applications." end,
		"Confirm low or crit-only rates.")
	rule(ailment[3], base .. " Uses the stronger effect.", "Confirm crit-only effects.")
	if ailment[1] == "Chill" or ailment[1] == "Shock" then rate("condition" .. ailment[2] .. "EnemyRecently", base .. " Main-skill hits only") end
end
rule("conditionEnemyFrozen conditionFrozenEnemyRecently", "The main skill can Freeze.", "Confirm low application rates.")
local poisoned = "At least one expected active Poison."
local poisonedConfirm = "Confirm minion or burst estimates."
rule("conditionEnemyPoisoned", poisoned, poisonedConfirm, STATE)
rule("multiplierPoisonOnEnemy", poisoned, poisonedConfirm)
for _, ailment in ipairs({ { "Bleed", "Bleeding" }, { "Ignite", "Ignited" } }) do rule("conditionEnemy" .. ailment[2], "PoB derives "
	.. ailment[2] .. ", or the main skill can " .. ailment[1] .. ".", "Confirm infrequent application.", STATE) end

-- Rule text quotes the thresholds in force: the scan's settings while a scan
-- runs, otherwise the saved user preferences. Resolved once per distinct setting.
local resolved = { }
local function ruleText(var, settings)
	local entry = catalogue[var]
	if not (entry and entry.condition) then return end
	local values = settings and preferences.Normalize(settings) or preferences.Get(main)
	local key = t_concat({ values.expectedEventThreshold, values.blockThreshold, values.suppressionThreshold, values.incomingEventThreshold,
		values.effectRefreshThreshold }, ":")
	resolved[key] = resolved[key] or { }
	if not resolved[key][var] then resolved[key][var] = { condition = resolve(entry.condition, values), confirmation = resolve(entry.confirmation, values) } end
	return resolved[key][var]
end

-- Precedence contract: a setting claimed by several registries belongs to the
-- first one listed here, for its rule text (Rules.Get) and for its marker owner
-- (Support.Capability, which wraps this list with the scanner-level modules).
-- A registry's parentRules supply text for a setting it keeps but does not own.
Rules.registries = { ground, buildup, minions, windows, batch, history, stacks, resources, choices, position, profiles, quests, stuns, uncertain, shrines }
function Rules.Get(var, settings)
	for _, registry in ipairs(Rules.registries) do
		if registry.capabilities[var] then return registry.capabilities[var].rule end
		if registry.parentRules and registry.parentRules[var] then return registry.parentRules[var] end
	end
	local detail = ruleText(var, settings)
	if detail then return detail end
	local default = Support.defaults[var]
	if default then
		return { condition = "Keep PoB's live " .. default.stat .. "; clear a manual override.", confirmation = "Confirm clearing the override." }
	end
	local flag = Support.availability[var]
	if flag then
		return { condition = "A granting flag: " .. flag:gsub("^Condition:", "") .. ".", confirmation = "Confirm the activation window." }
	end
	local native = Support.conditions[var]
	if native then
		local actor = native.actor == "player" and "you" or native.actor == "minion" and "the selected minion" or "the enemy"
		return { condition = "PoB derives " .. native.flag:gsub("^Condition:", "") .. " for " .. actor .. ".",
			confirmation = native.actor == "minion" and "Confirm it applies to your other minions." or nil }
	end
end

-- ============================================================================
-- Support: inventory, scope and markers
-- ============================================================================
-- A marker means an implemented detector or a verified, dynamic fallback in
-- PoB's calculations. Eligibility is deliberately separate from evidence that
-- an effect is active.
Support.conditions = model.Conditions
Support.defaults = model.Defaults
-- These defaults use shared lookup tables rather than a literal Override(...)
-- expression; PoB still computes them when the override is empty.
for _, entry in ipairs({
	{ "multiplierSummonedMinion", "Multiplier:SummonedMinion" },
	{ "multiplierNonVaalSummonedMinion", "Multiplier:NonVaalSummonedMinion" },
	{ "multiplierPermanentMinion", "Multiplier:PermanentMinion" },
	{ "TotalMinionLife", "TotalMinionLife" }, { "TotalSpectreLife", "TotalSpectreLife" },
	{ "TotalTotemLife", "TotalTotemLife" }, { "TotalRadianceSentinelLife", "TotalRadianceSentinelLife" },
	{ "TotalVoidSpawnLife", "TotalVoidSpawnLife" }, { "TotalStoneGolemLife", "TotalStoneGolemLife" },
	{ "TotalVaalRejuvenationTotemLife", "TotalVaalRejuvenationTotemLife" },
	{ "overrideBuffElusive", "ElusiveEffect" },
	{ "minionsOverridePowerCharges", "PowerCharges" },
	{ "minionsOverrideFrenzyCharges", "FrenzyCharges" },
	{ "minionsOverrideEnduranceCharges", "EnduranceCharges" },
	{ "BrandsAttachedToEnemy", "BrandsAttachedToEnemy" },
}) do
	Support.defaults[entry[1]] = { stat = entry[2] }
end
Support.defaults.highestDamageType = { stat = "highest damage type", defaultValue = "NONE" }
Support.defaults.traumaStacks = { stat = "SustainableTraumaStacks" }
Support.defaults.multiplierImpalesOnEnemy = { stat = "ImpaleStacksMax" }
Support.defaults.overrideBleedStackPotential = { stat = "BleedStackPotential" }
Support.defaults.overrideIgniteStackPotential = { stat = "IgniteStackPotential" }
Support.defaults.MomentumStacks = { stat = "average Momentum stacks" }
Support.defaults.sacrificedRageCount = { stat = "maximum sacrificed Rage" }
Support.availability = {
	buffSacrificialZeal = "SacrificialZeal", buffAlchemistsGenius = "Condition:CanHaveAlchemistGenius",
	buffVaalArcLuckyHits = "Condition:CanBeLucky", buffWildSavagery = "WildSavagery",
	conditionCanBeCurseImmune = "Condition:CanBeCurseImmune", conditionHaveArborix = "Condition:HaveArborix",
	conditionHaveVulconus = "Condition:HaveVulconus", conditionHaveManaStorm = "Condition:HaveManaStorm",
	buffFanaticism = "Condition:CanGainFanaticism", EverlastingSacrifice = "Condition:EverlastingSacrifice",
	conditionEnemyExcommunicated = "Condition:CanExcommunicate", conditionEnemyHallowingFlame = "Condition:CanInflictHallowingFlame",
}

-- Keep the complete file inventory, but remove map and mob scenario inputs
-- from scan coverage, suggestions, reports and markers. Existing values remain
-- available to PoB's calculations and are never edited by auto-configure.
local excludedMobInputs = { }
for var in ("conditionOnCausticGround conditionOnBurningGround conditionOnChilledGround conditionOnShockedGround multiplierNearbyEnemies "
	.. "multiplierNearbyRareOrUniqueEnemies siphoningTrapAffectedEnemies nearbyBleedingEnemies"):gmatch("%S+") do excludedMobInputs[var] = true end
for var in ("enemySizePreset enemyRadius detonateDeadCorpseLife conditionEnemyMoving conditionEnemyFullLife conditionEnemyLowLife "
	.. "conditionEnemyHaveEnergyShield conditionEnemyLifeHigherThanPlayer conditionEnemyFireResZero conditionEnemyColdResZero "
	.. "conditionEnemyLightningResZero conditionKilledUniqueEnemy conditionRavenousCorpseConsumed"):gmatch("%S+") do excludedMobInputs[var] = true end
function Support.IsInScope(var)
	return byName[var] ~= nil and sections[var] ~= "Enemy Stats"
		and sections[var] ~= "Map Modifiers and Player Debuffs" and not excludedMobInputs[var]
end

-- Detector modules in capability precedence: the scanner-level modules, the
-- registries in Rules.registries order (see the contract there), then the
-- remaining scanner modules and the core rules declared above.
local modules = { policy, mechanics, timeline }
for _, registry in ipairs(Rules.registries) do t_insert(modules, registry) end
for _, module in ipairs({ events, advanced, core }) do t_insert(modules, module) end
Support.modules = modules
function Support.Capability(var)
	for _, module in ipairs(modules) do
		local capability = module.capabilities[var]
		if capability then return capability, module end
	end
end

local assessments = { }
local function baseAssessment(var)
	local option = type(var) == "table" and var or byName[var]
	if not option then return end
	var = option.var
	if assessments[var] then return assessments[var] end
	local assessment = { var = var, section = sections[var], label = StripEscapes and StripEscapes(option.label or "") or option.label, type = option.type }
	assessments[var] = assessment
	assessment.inScope = Support.IsInScope(var)
	local capability, module = Support.Capability(var)
	if not assessment.inScope then
		assessment.kind, assessment.method = "excluded", "Map and enemy settings are not auto-configured."
	elseif option.legacy or var == "minionPactLife" or option.ifOption == "useGhostShrouds" then
		assessment.kind, assessment.method = "legacy", "Legacy setting for older builds."
	elseif capability then
		assessment.kind, assessment.method, assessment.supported = capability.kind, capability.method, true
		if module == uncertain then
			assessment.needsObservedValue = true
			assessment.valueCoverage = uncertain.sampleDerived[var] and "sample-or-observed" or "zero-only"
		end
	elseif Support.availability[var] then
		assessment.kind, assessment.supported = "assisted", true
		assessment.method = "Granting flag found; confirm the buff window."
	elseif Support.conditions[var] then
		assessment.kind, assessment.supported = Support.conditions[var].actor == "minion" and "assisted" or "automatic", true
		assessment.method = "Native " .. Support.conditions[var].actor .. " state " .. Support.conditions[var].flag .. "."
	elseif Support.defaults[var] then
		assessment.kind, assessment.supported = "calculated-default", true
		assessment.method = "PoB calculates " .. Support.defaults[var].stat .. " when this is empty."
	elseif sections[var] == "Map Modifiers and Player Debuffs" or sections[var] == "Enemy Stats" or var:find("Shrine") then
		assessment.kind, assessment.method = "encounter", "Depends on the map or encounter."
	elseif option.type == "text" or var == "bandit" or var == "resistancePenalty" or var:find("pantheon") or var:find("Mode") or var:find("Bypass")
		or var:find("^ignore") or var:find("^Disable") or var:find("Pvp") or var == "bloodSacramentReservationEHP" then
		assessment.kind, assessment.method = "choice", "This is your choice."
	elseif option.ifSkill or option.ifSkillFlag or option.ifSkillData then
		assessment.kind = "possible-with-usage"
		local source = option.ifSkill or option.ifSkillFlag or option.ifSkillData
		if type(source) == "table" then source = t_concat(source, ", ") end
		assessment.method = "Needs " .. source .. "; usage is not detected."
	elseif var:find("Distance") or var:find("Nearby") or var:find("Overlap") or var:find("Fork") or var:find("Chain") or var:find("Pierce")
		or var == "conditionMoving" or var == "conditionStationary" or var:find("Ground") or var:find("CloseRange") then
		assessment.kind, assessment.method = "position", "Depends on positioning during play."
	elseif var:find("Recently") or var:find("Past") or var:find("Last") or var:find("Seconds") or var:find("Channelling") then
		assessment.kind, assessment.method = "combat-history", "Depends on combat events."
	elseif option.type == "check" then
		assessment.kind, assessment.method = "source-rule-needed", "No source detector yet."
	else
		assessment.kind, assessment.method = "value-rule-needed", "No value rule yet."
	end
	if assessment.supported then assessment.rule = Rules.Get(var, preferences.defaults)
	elseif assessment.inScope and guided.Question(var) then
		assessment.guided, assessment.guidance = true, guided.Question(var)
	end
	-- Registries whose proposal the player can edit before applying it.
	if profiles.capabilities[var] then assessment.detectionMode = "confirmed-profile"
	elseif quests.capabilities[var] then assessment.detectionMode = var == "resistancePenalty" and "reviewed-progress-estimate" or "imported-quest-record"
	elseif stuns.capabilities[var] then assessment.detectionMode = var == "conditionHitsAlwaysStun" and "guaranteed-stun-or-immunity"
		or "guaranteed-or-sampled-stun"
	elseif uncertain.capabilities[var] then assessment.detectionMode = assessment.valueCoverage end
	if assessment.detectionMode then assessment.editableFallback = true end
	assessment.feasibility = assessment.valueCoverage == "sample-or-observed" and "implemented-with-sample" or assessment.needsObservedValue
		and "implemented-zero-only" or assessment.supported and "implemented"
		or not assessment.inScope and "excluded-by-scope"
		or assessment.kind == "choice" and "user-choice"
		or assessment.kind == "legacy" and "legacy"
		or (assessment.kind == "encounter" or assessment.kind == "position" or assessment.kind == "combat-history") and "scenario-or-runtime-data"
		or "possible-with-additional-rule"
	return assessment
end

-- Keep the inventory at default sensitivity. A scan or tooltip can attach the
-- rule text for its own settings without mutating the shared assessment.
function Support.GetAssessment(var, settings)
	local assessment = baseAssessment(var)
	if not assessment or not assessment.supported or not catalogue[assessment.var] then return assessment end
	local rule = Rules.Get(assessment.var, settings)
	if rule == assessment.rule then return assessment end
	local result = copyTable(assessment, true)
	result.rule = rule
	return result
end

local inventory
function Support.GetInventory()
	if not inventory then
		inventory = { }
		for _, option in ipairs(options) do
			if option.var then t_insert(inventory, baseAssessment(option)) end
		end
	end
	return inventory
end

function Support.GetPlainDescription(var, settings)
	local info = Support.GetAssessment(var)
	return info and plainText.Describe(info, byName[var], settings or preferences.Get(main))
end

return M
