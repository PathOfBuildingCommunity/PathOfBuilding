-- Path of Building
--
-- Shared auto-configure model: user preferences, the combat policy, cached
-- build facts and rule registries, the calculation and zero-only profiles,
-- player-facing text, and the computed-default and condition inventories.
-- Depends only on ConfigOptions; every other ConfigAuto module requires this
-- one. Its popups are built by ConfigAutoUI.
local t_insert = table.insert
local t_remove = table.remove
local t_concat = table.concat
local m_min = math.min
local m_max = math.max

local M = { }

-- An enabled skill: not disabled by the engine, its socket group or its gem.
local function skillEnabled(skill)
	return not skill.skillFlags.disable and (not skill.socketGroup or skill.socketGroup.enabled ~= false)
		and (not skill.activeEffect.srcInstance or skill.activeEffect.srcInstance.enabled ~= false)
end
M.SkillEnabled = skillEnabled
function M.ActiveSkills(env)
	local active = { }
	for _, skill in ipairs(env.player.activeSkillList) do if skillEnabled(skill) then t_insert(active, skill) end end
	return active
end

-- Rule and explanation text, keyed by the setting or rule group it belongs to.
local prose = {
	eventRate = "About %.1f times in %.1fs; needs %g.",
	incomingChance = "Chance %.1f%%; needs %g%% and %g incoming hits.",
	incomingScenario = "%s enemy: %g incoming hits/s%s.",
	calculationModes = {
		condition = "Uses your Combat model profile.",
		explanation = "Uses the average for normal play.",
	},
	calculationOverrides = {
		condition = "Clears an enabled calculation override.",
		explanation = "Turns off this special override.",
	},
	bloodSacramentReservationEHP = {
		condition = "Restores PoB's reservation default.",
		explanation = "Restores PoB's normal reservation rule.",
	},
	pvp = {
		condition = "Removes a saved PvP override.",
		explanation = "Lets PoB calculate the PvP value.",
	},
	overlap = {
		condition = "Uses one overlapping %s hit.",
		explanation = "Models one overlapping hit; confirm it.",
	},
	distance = {
		condition = "Uses your %s distance profile.",
		explanation = "Uses your chosen distance; confirm it.",
	},
	hoaOverkill = {
		condition = "Needs Herald of Ash.",
		explanation = "Zero without kills, or use Hit samples.",
	},
	multiplierHallowingFlameStacksRemovedByAlly = {
		condition = "Solo with no allied attackers.",
		explanation = "Zero if no ally can hit the target.",
		zero = "Solo fight with no allied attackers.",
	},
	heraldOfAgonyVirulenceStack = {
		condition = "Zero only if nothing can Poison.",
		explanation = "Zero Virulence if you cannot Poison.",
		zero = "No enabled skill can Poison.",
	},
	heraldOfTheHivePressure = {
		condition = "Zero only if nothing applies ailments.",
		explanation = "Zero Pressure if you apply no ailments.",
		zero = "No enabled skill applies ailments.",
	},
	overrideCruelty = {
		condition = "Zero only if no Cruelty skill can hit.",
		explanation = "Zero if no Cruelty skill can hit.",
		zero = "No Cruelty skill can hit now.",
	},
	importedChoice = "Import your character for this choice.",
	stunRecently = "Use Hit samples for your Stun chance.",
	blockRecently = "PoB needs at least %g%% %s block and about %g blocks in %g seconds. Average fights use %g%% attacks.",
	suppressedRecently = "PoB needs at least %g%% spell suppression and about %g suppressed hits. Average fights use %g%% spells.",
	charges = "How many charges do you keep?",
	recentEvents = "Needs %g successful events recently.",
	effectRefresh = " Needs %g expected applications.",
}

-- User preferences for the scanner, kept separate from build calculations.
local Preferences = { }
M.Preferences = Preferences
Preferences.fields = {
	{ key = "blockThreshold", label = "Recent block: turn on at", unit = "%", default = 50, min = 0, max = 100,
		help = "Block chance needed to assume a block." },
	{ key = "suppressionThreshold", label = "Recent suppression: turn on at", unit = "%", default = 50, min = 0, max = 100,
		help = "Suppression chance needed to count it." },
	{ key = "expectedEventThreshold", label = "Recent events: number needed", unit = "events", default = 3, min = 1, max = 20,
		help = "Expected events needed to tick a box." },
	{ key = "incomingEventThreshold", label = "Recent block/suppress: events needed", unit = "events", default = 1, min = 0, max = 20,
		help = "Expected enemy hits needed as well." },
	{ key = "effectRefreshThreshold", label = "Temporary effects: applications needed", unit = "events", default = 3, min = 1, max = 20,
		help = "Applications needed per duration." },
	{ key = "incomingHitRate", group = "pace", label = "Enemy hit attempts each second", unit = "/ second", default = 1, min = 0, max = 100,
		help = "How often enemies try to hit you." },
	{ key = "incomingAttackShare", group = "pace", label = "Attacks among incoming hits (Average)", unit = "%", default = 50, min = 0, max = 100,
		help = "The rest are spell hits." },
	{ key = "incomingDamageEventRate", group = "pace", label = "Lunaris damage events each second", unit = "/ second", default = 1, min = 0,
		max = 100, help = "Damage events for Aspect of Lunaris." },
	{ key = "mainSkillActivity", group = "pace", label = "Time using your main skill", unit = "%", default = 100, min = 0, max = 100,
		help = "Share of time on your main skill." },
	{ key = "regularKillRate", group = "pace", label = "Your kills while mapping", unit = "/ second", default = 1, min = 0, max = 100,
		help = "Your kills per second while mapping." },
	{ key = "minionKillRate", group = "pace", label = "Minion kills while mapping", unit = "/ second", default = 1, inherits = "regularKillRate",
		min = 0, max = 100, help = "Minion kills per second while mapping." },
	{ key = "totemKillRate", group = "pace", label = "Totem kills while mapping", unit = "/ second", default = 1, inherits = "regularKillRate",
		min = 0, max = 100, help = "Totem kills per second while mapping." },
}
Preferences.modelFields = {
	{ key = "meleeDistanceMetres", label = "Melee distance", unit = "metres", default = 1.5, min = 0, max = 100 },
	{ key = "projectileDistanceMetres", label = "Projectile travel distance", unit = "metres", default = 4, min = 0, max = 1000 },
}
Preferences.modelChoices = {
	{ key = "calculationProfile", label = "Calculation profile", default = "AVERAGE",
		list = { { val = "KEEP", label = "Keep my calculation modes" }, { val = "AVERAGE", label = "Average gameplay" },
		{ val = "CAREFUL", label = "Careful survival estimate" } } },
	{ key = "overlapProfile", label = "Overlapping hits", default = "SINGLE",
		list = { { val = "KEEP", label = "Keep my overlap counts" }, { val = "SINGLE", label = "One hit; ask before changing" } } },
	{ key = "distanceProfile", label = "Positioning", default = "PROFILE",
		list = { { val = "KEEP", label = "Keep my distances" }, { val = "PROFILE", label = "Use distances below; ask first" } } },
}
Preferences.sampleFields = {
	{ key = "stunSampleThreshold", label = "Target's base Stun threshold", default = 0, min = 0, max = 1e12,
		help = "Target Stun Life; blank if unknown." },
	{ key = "overkillHitDamage", label = "Damage dealt by your killing hit", default = 0, min = 0, max = 1e12,
		help = "Killing hit damage after defences." },
	{ key = "overkillLifeBeforeHit", label = "Target Life just before that hit", default = 0, min = 0, max = 1e12,
		help = "Life left before your killing hit." },
}
local numericFields = { }; for _, field in ipairs(Preferences.fields) do t_insert(numericFields, field) end
for _, field in ipairs(Preferences.modelFields) do t_insert(numericFields, field) end
for _, field in ipairs(Preferences.sampleFields) do t_insert(numericFields, field) end
Preferences.defaults = { askAllAssumptions = false, showDetails = false, assumeSolo = true }
for _, field in ipairs(numericFields) do Preferences.defaults[field.key] = field.default end
for _, field in ipairs(Preferences.modelChoices) do Preferences.defaults[field.key] = field.default end
function Preferences.Normalize(values)
	values = values or { }
	local result = { }
	for _, field in ipairs(numericFields) do
		local number = tonumber(values[field.key])
		if not number or number ~= number or number == math.huge or number == -math.huge then
			number = result[field.inherits] or field.default
		end
		result[field.key] = m_max(field.min, m_min(field.max, number))
	end
	for _, key in ipairs({ "askAllAssumptions", "showDetails" }) do result[key] = values[key] == true or values[key] == "true" end
	result.assumeSolo = values.assumeSolo == nil or values.assumeSolo == true or values.assumeSolo == "true"
	for _, field in ipairs(Preferences.modelChoices) do
		result[field.key] = field.default
		for _, choice in ipairs(field.list) do if choice.val == values[field.key] then result[field.key] = choice.val end end
	end
	return result
end
function Preferences.Validate(values)
	for _, field in ipairs(numericFields) do
		local number = tonumber(values[field.key])
		if not number or number ~= number or number < field.min or number > field.max then
			return nil, field.label .. ": enter a number from " .. field.min .. " to " .. field.max .. ".", field.key
		end
	end
	return Preferences.Normalize(values)
end
function Preferences.Get(owner) return Preferences.Normalize(owner and owner.autoConfigureSettings) end
function Preferences.Key(values)
	values = Preferences.Normalize(values)
	local parts = { tostring(values.askAllAssumptions), tostring(values.showDetails) }
	t_insert(parts, tostring(values.assumeSolo))
	for _, field in ipairs(numericFields) do t_insert(parts, tostring(values[field.key])) end
	for _, field in ipairs(Preferences.modelChoices) do t_insert(parts, values[field.key]) end
	return t_concat(parts, ":")
end
function Preferences.SaveNode(values)
	local node = { elem = "AutoConfigure", attrib = { } }
	local saved = Preferences.Normalize(values)
	for _, field in ipairs(Preferences.sampleFields) do saved[field.key] = nil end
	for key, value in pairs(saved) do node.attrib[key] = tostring(value) end
	return node
end
Preferences.presets = {
	{ label = "Careful", values = { blockThreshold = 75, suppressionThreshold = 75, expectedEventThreshold = 5, incomingEventThreshold = 2,
		effectRefreshThreshold = 5 } },
	{ label = "Normal", values = { blockThreshold = 50, suppressionThreshold = 50, expectedEventThreshold = 3, incomingEventThreshold = 1,
		effectRefreshThreshold = 3 } },
	{ label = "Optimistic", values = { blockThreshold = 25, suppressionThreshold = 25, expectedEventThreshold = 1, incomingEventThreshold = 0,
		effectRefreshThreshold = 1 } },
}

-- Combat modelling policy: source evidence and expected combat events are
-- separate. These rules propose assumptions, never observations of gameplay.
-- recentWindow is the "recently" window of Configuration conditions;
-- defaultFightSeconds is the modelled fight length when the scan gives none.
local Policy = { recentWindow = 4, defaultFightSeconds = 4 }
M.Policy = Policy
-- The fight time a detector models: the scan's chosen seconds, else the default.
function Policy.FightSeconds(context) return context.seconds or Policy.defaultFightSeconds end
Policy.capabilities = { }
Policy.rateControlled = { conditionHitRecently = true, conditionHitSpellRecently = true }
local function register(names, method)
	for var in names:gmatch("%S+") do Policy.capabilities[var] = { kind = "automatic", method = method } end
end
register("conditionBlockedRecently conditionBlockedAttackRecently conditionBlockedSpellRecently",
	"Uses block chance and enemy hit rate.")
register("conditionSuppressedRecently",
	"Uses suppression and enemy hit rate.")
register("conditionBlockedHitFromUniqueEnemyInPast10Sec",
	"Uses block chance vs a Boss target.")
register("conditionHitRecentlyWithWeapon conditionUsedBrandRecently conditionTotemsKilledRecently conditionMinionsKilledRecently",
	"Uses your main skill's hit/kill rate.")
register("conditionUsedWarcryRecently conditionUsedTravelSkillRecently conditionUsedDashRecently",
	"Assumes regular use if cooldown <= 4s.")

-- Each scan registers the selected player's output and structural projections.
-- Auxiliary probes keep their full rates. Placed minions and totems scale
-- with use for placement, but their subsequent hits have their own cadence.
function Policy.Activity(context, output, kind)
	local activity = context.mainOutputs[output]
	if not activity or (kind == "hit" and activity ~= "hit") then return 1 end
	return context.settings.mainSkillActivity / 100
end

function Policy.RawHitRate(output)
	return m_max(0, output.HitSpeed or output.Speed or 0) * m_max(0, m_min(100, output.HitChance or 100)) / 100
end

function Policy.HitRate(context, output)
	return Policy.RawHitRate(output) * Policy.Activity(context, output, "hit")
end

Policy.chargeTypes = { "Power", "Frenzy", "Endurance" }
local alternativeCharges = { Power = "Absorption", Frenzy = "Affliction", Endurance = "Brutal" }
function Policy.EffectiveCharges(env, charge)
	local resolved = alternativeCharges[charge]
	if not env.player.modDB:Flag(nil, charge .. "ChargesConvertTo" .. resolved .. "Charges") then resolved = charge end
	return env.player.output[resolved .. "Charges"], resolved
end

local killFields = { player = "regularKillRate", minion = "minionKillRate", totem = "totemKillRate" }
function Policy.KillRate(context, actor)
	local field = killFields[actor]
	return context.mapping and field and context.settings[field] or 0
end

function Policy.MainKillActor(env)
	local skill = env.player.mainSkill
	if skill.skillFlags.disable then return end
	local actor, output = "player", env.player.output
	if env.minion then
		if env.minion.hostile then return end
		actor, output = "minion", env.minion.output
	elseif skill.skillFlags.totem then
		actor = "totem"
	elseif skill.skillFlags.trap or skill.skillFlags.mine or skill.minion then
		return
	end
	if (output.TotalDPS or 0) + (output.TotalDotDPS or output.TotalDot or 0) > 0 then return actor end
end

function Policy.Rate(settings, rate, window, threshold)
	window = window or Policy.recentWindow
	threshold = threshold or settings.expectedEventThreshold
	local expected = m_max(0, rate or 0) * window
	return {
		rule = "event-rate", window = window, expected = expected, threshold = threshold,
		automatic = expected >= threshold,
		description = string.format(prose.eventRate, expected, window, threshold),
	}
end

function Policy.Refresh(settings, rate, duration, seconds)
	local result = Policy.Rate(settings, rate, m_min(duration or 0, seconds or math.huge), settings.effectRefreshThreshold)
	result.effectRefresh = true
	return result
end

function Policy.Chance(settings, chance, threshold, incoming, window, eventRate)
	chance = m_max(0, m_min(100, chance or 0))
	window = window or Policy.recentWindow
	local expected = (eventRate or settings.incomingHitRate * chance / 100) * window
	return {
		rule = "incoming-chance", chance = chance, threshold = threshold, window = window,
		expected = expected, eventThreshold = settings.incomingEventThreshold,
		automatic = chance > 0 and settings.incomingHitRate > 0 and chance >= threshold and expected >= settings.incomingEventThreshold,
		description = string.format(prose.incomingChance, chance, threshold, settings.incomingEventThreshold, settings.incomingHitRate, expected,
			window, incoming),
	}
end

-- Share one total attempt rate between the configured hit types. Avoided hits
-- cannot block or suppress. Reading this scenario never edits enemy settings.
function Policy.Incoming(settings, output, category)
	category = category or "Average"
	local result = { category = category, categories = {}, blockRate = 0, attackBlockRate = 0, spellBlockRate = 0, suppressionRate = 0,
		attackBlockChance = 0, spellBlockChance = 0 }
	local types = category == "Average" and { "Melee", "Projectile", "Spell", "SpellProjectile" } or { category }
	for _, kind in ipairs(types) do
		if kind == "Untyped" then
			t_insert(result.categories, { kind = kind, rate = settings.incomingHitRate * m_max(0, 1 - (output.UntypedNotHitChance or 0) / 100),
				blockChance = 0 })
		elseif kind == "Melee" or kind == "Projectile" or kind == "Spell" or kind == "SpellProjectile" then
			local attack = kind == "Melee" or kind == "Projectile"
			local share = category == "Average" and (attack and settings.incomingAttackShare or 100 - settings.incomingAttackShare) / 200 or 1
			local rate = settings.incomingHitRate * share * m_max(0, 1 - (output[kind .. "NotHitChance"] or 0) / 100)
			local key = kind == "Melee" and "BlockChance" or kind .. "BlockChance"
			local chance = m_max(0, m_min(100, output["Effective" .. key] or output[key] or 0))
			local blocked = rate * chance / 100
			t_insert(result.categories, { kind = kind, rate = rate, blockChance = chance })
			result.blockRate = result.blockRate + blocked
			local prefix = attack and "attack" or "spell"
			result[prefix .. "BlockRate"] = result[prefix .. "BlockRate"] + blocked
			if rate > 0 then result[prefix .. "BlockChance"] = m_max(result[prefix .. "BlockChance"], chance) end
			if not attack then
				local suppression = m_max(0, m_min(100, output.EffectiveSpellSuppressionChance or output.SpellSuppressionChance or 0))
				result.suppressionRate = result.suppressionRate + rate * suppression / 100
			end
		end
	end
	return result
end

function Policy.Scenario(description)
	return { rule = "combat-scenario", automatic = true, description = "Combat assumption: " .. description }
end

function Policy.SkillUse(cooldown, activity)
	activity = activity or 1
	cooldown = type(cooldown) == "number" and activity > 0 and m_max(0, cooldown) / activity or nil
	return {
		rule = "skill-use", cooldown = cooldown, window = Policy.recentWindow,
		automatic = cooldown ~= nil and cooldown <= Policy.recentWindow,
		description = "Assumes regular use in combat. "
			.. (cooldown and string.format("Cooldown about %.2fs.", cooldown)
				or "Unknown cooldown; please confirm."),
	}
end

function Policy.IsRecent(var, label)
	return var:find("Recently", 1, true) or var:find("Past", 1, true)
		or (label or ""):lower():find("recent", 1, true)
end

-- Shared rule execution and cached build facts. The same definition supplies
-- neutralisation, detection, capability metadata, marker explanations and Details text.

-- Capability inventory shared by every detector module: one marker entry and
-- one neutralised input per listed setting.
local function inventory(module)
	module.capabilities = module.capabilities or { }
	module.neutralInputs = module.neutralInputs or { }
end
-- The capability entry for a rule whose text is split into a source condition
-- and a confirmation (the form ConfigAutoInventory.Rules.Get reads back).
local function ruleEntry(condition, confirmation, kind)
	return { kind = kind or "assisted", method = condition .. " " .. (confirmation or ""), rule = { condition = condition, confirmation = confirmation } }
end
function M.Register(module, names, method, kind)
	inventory(module)
	for var in names:gmatch("%S+") do
		module.capabilities[var] = { kind = kind or "automatic", method = method }
		module.neutralInputs[var] = true
	end
end
function M.RegisterRule(module, var, condition, confirmation, kind)
	inventory(module)
	module.capabilities[var], module.neutralInputs[var] = ruleEntry(condition, confirmation, kind), true
end

-- Configuration inputs by var, and the section each belongs to. Built once;
-- every module that needs an option by name reads these instead of rescanning.
M.optionsByName, M.sectionsByName = { }, { }
do
	local section
	for _, option in ipairs(require("Modules.ConfigOptions")) do
		section = option.section or section
		if option.var then M.optionsByName[option.var], M.sectionsByName[option.var] = option, section end
	end
end

-- One modifier-line normalisation for pattern matching: strip colour codes,
-- lower-case, collapse runs of whitespace and trim. The cached build lines and
-- the rule modules' line splitters all produce this text.
function M.NormalizeLine(text)
	return (StripEscapes(text):lower():gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

-- A personal skill: self-used by the player, not a minion's.
function M.Personal(skill) return M.IsDirect(skill) and not skill.minion end
-- The Balance of Terror self-only key for a curse name (one definition for
-- every reader), and whether the build has that curse marked self-only.
function M.BalanceOfTerrorVar(curseName) return "balanceOfTerrorSelfCast" .. curseName:gsub(" ", "") end
function M.SelfOnlyCurse(build, skill)
	return build.configTab.input[M.BalanceOfTerrorVar(skill.activeEffect.grantedEffect.name)]
end
-- Full enemy immunity or avoidance of one ailment. Poison and Bleed are not
-- elemental, so the elemental-ailment immunity and avoidance do not apply.
function M.AilmentImmune(env, name)
	local elemental = name ~= "Poison" and name ~= "Bleed"
	local db = env.enemy.modDB
	return db:Flag(nil, name .. "Immune", elemental and "ElementalAilmentImmune" or nil)
		or db:Sum("BASE", nil, "Avoid" .. name, "AvoidAilments", elemental and "AvoidElementalAilments" or nil) >= 100
end

-- Player activation adapters. Triggered, reserved and proxy skills are not
-- self-used activations; mines are the one reservation that is thrown.
function M.CanActivate(skill)
	return skillEnabled(skill) and not skill.skillData.triggered
		and not skill.skillTypes[SkillType.Triggered] and not skill.skillTypes[SkillType.InbuiltTrigger]
		and (not skill.skillTypes[SkillType.HasReservation] or skill.skillFlags.mine)
end
function M.IsDirect(skill)
	return M.CanActivate(skill) and not skill.skillFlags.trap and not skill.skillFlags.mine and not skill.skillFlags.totem
end
function M.UseRate(context, skill, output)
	if not M.CanActivate(skill) or skill.skillTypes[SkillType.Channel] or skill.skillTypes[SkillType.Vaal] then return 0 end
	local rate
	if skill.skillTypes[SkillType.Instant] then rate = output.Cooldown and output.Cooldown > 0 and 1 / output.Cooldown or 0
	elseif skill.skillFlags.mine then rate = output.MineLayingSpeed
	elseif skill.skillFlags.trap then rate = output.TrapThrowingSpeed
	elseif skill.skillFlags.totem then rate = output.TotemPlacementSpeed
	else rate = (output.Speed or 0) / m_max(1, output.Repeats or 1) end
	local cooldown = skill.skillFlags.trap and output.TrapCooldown or output.Cooldown
	if cooldown and cooldown > 0 then rate = m_min(rate or 1 / cooldown, 1 / cooldown) end
	return m_max(0, rate or 0) * Policy.Activity(context, output)
end
-- The main player's own damage: no minion, totem, trap or mine proxies.
function M.OwnDamage(main, output)
	return skillEnabled(main) and not main.minion and not main.skillFlags.totem and not main.skillFlags.trap and not main.skillFlags.mine
		and ((output.TotalDPS or 0) + (output.TotalDotDPS or output.TotalDot or 0)) > 0
end
-- Flasks activated in the Items tab, in slot order. An equipped inactive flask
-- is never activated by a scan.
function M.ActiveFlasks(env, lifeOnly)
	local result = { }
	for item in pairs(env.flasks or { }) do if item.flaskData and (not lifeOnly or (item.flaskData.lifeTotal or 0) > 0) then t_insert(result, item) end end
	local slots = env.itemSlotIndex or { }
	table.sort(result, function(a, b)
		if (slots[a] or 0) ~= (slots[b] or 0) then return (slots[a] or 0) < (slots[b] or 0) end
		return (a.id or 0) < (b.id or 0)
	end)
	return result
end
-- Expected counts are rounded down. Fewer than one expected event offers one
-- only with confirmation. Returns amount, review, belowOne.
function M.Count(expected, review)
	local amount = math.floor(m_max(0, expected or 0) + 1e-8)
	if amount < 1 then return 1, true, true end
	return amount, not not review, false
end
-- Successful applications per second of one ailment by the given hits.
-- Poison and Bleed are not elemental; immunity and full avoidance give zero.
function M.AilmentRate(env, output, hits, name)
	if (hits or 0) <= 0 then return 0 end
	local elemental = name ~= "Poison" and name ~= "Bleed"
	if M.AilmentImmune(env, name) then return 0 end
	local applies
	if name == "Ignite" or not elemental then applies = (output[name .. "DPS"] or 0) > 0
	elseif name == "Freeze" then applies = (output.FreezeCanApply or 0) > 0
	else applies = (output[name .. "HitEffectEstimate"] or 0) > 0 end
	if not applies then return 0 end
	local chance = output[name .. "Chance"] or (name == "Chill" and 100 or 0)
	if (output[name .. "EstimateUsesCrit"] or 0) > 0 then chance = m_min(chance, output.CritChance or 0) end
	return hits * m_min(100, m_max(0, chance)) / 100
end
-- Attacks keep hit damage and Stun duration on individual weapon passes.
-- A missing top-level AverageHit is not evidence of a zero-damage attack.
function M.HitOutputs(output)
	if output.MainHand or output.OffHand then
		local passes = { }
		if output.MainHand then t_insert(passes, output.MainHand) end
		if output.OffHand then t_insert(passes, output.OffHand) end
		return passes
	end
	return { output }
end
function M.HasGeneratingHit(output)
	if Policy.RawHitRate(output) <= 0 then return false end
	for _, pass in ipairs(M.HitOutputs(output)) do if (pass.AverageHit or 0) > 0 and (pass.HitChance or 100) > 0 then return true end end
	return false
end

-- Independent instances expire individually. Refreshing debuffs instead keep
-- their group alive. Resets consume the entire group at the stated threshold.
function M.StackCount(seconds, rule)
	local rate, amount, duration, cap = rule.rate or 0, rule.perEvent or 1, rule.duration or math.huge, rule.cap or math.huge
	if rate <= 0 or amount <= 0 or duration <= 0 or cap < 0 then return end
	local first, interval = rule.first or 1 / rate, 1 / rate
	local stop = m_min(seconds, rule.stop or seconds)
	if first > stop + 1e-8 then return 0 end
	local total = m_max(0, math.floor((stop - first) / interval + 1e-8) + 1)
	if not rule.resetAt and not rule.beforeEvent then
		local alive = total
		if rule.refresh then
			if seconds - (first + (total - 1) * interval) >= duration - 1e-8 then return 0 end
			if interval >= duration then alive = 1 end
		elseif duration < math.huge then
			local expired = m_max(0, math.floor((seconds - duration - first) / interval + 1e-8) + 1)
			alive = m_max(0, total - expired)
		end
		return m_min(cap, alive * amount)
	end
	if total > 100000 then return end -- never return an unfinished simulation
	local births = { }
	for index = 1, total do
		local time = first + (index - 1) * interval
		for i = #births, 1, -1 do if time - births[i] >= duration - 1e-8 then t_remove(births, i) end end
		if rule.beforeEvent and rule.beforeEvent(#births, time) == "reset" then
			births = { }
		else
			if rule.refresh then for i = 1, #births do births[i] = time end end
			for _ = 1, m_min(amount, cap - #births) do t_insert(births, time) end
			if rule.resetAt and #births >= rule.resetAt then births = { } end
		end
	end
	for i = #births, 1, -1 do if seconds - births[i] >= duration - 1e-8 then t_remove(births, i) end end
	return #births
end

function M.Facts(context)
	local facts = { context = context, env = context.env, seconds = Policy.FightSeconds(context) }
	local cached = { }
	function facts.Active()
		if not cached.active then
			cached.active = M.ActiveSkills(context.env)
		end
		return cached.active
	end
	-- The scanner's probeSkill already caches one probe per skill; no second cache here.
	function facts.Probe(skill)
		if skill == context.mainSkill then return context.env end
		return context.probeSkill(skill) or nil
	end
	function facts.Lines()
		if not cached.lines then
			cached.lines = { }
			for _, line in ipairs(context.lines or { }) do
				t_insert(cached.lines, { text = M.NormalizeLine(line.text), source = line.source .. "\n" .. line.text })
			end
		end
		return cached.lines
	end
	function facts.Paragraphs()
		if not cached.paragraphs then
			local grouped = { }; cached.paragraphs = { }
			for _, line in ipairs(context.lines or { }) do
				grouped[line.source] = grouped[line.source] or { }
				t_insert(grouped[line.source], StripEscapes(line.text))
			end
			for source, lines in pairs(grouped) do t_insert(cached.paragraphs,
				{ text = M.NormalizeLine(t_concat(lines, " ")), source = source .. "\n" .. t_concat(lines, "\n") }) end
			table.sort(cached.paragraphs, function(a, b) return a.source < b.source end)
		end
		return cached.paragraphs
	end
	function facts.Find(id)
		for _, skill in ipairs(facts.Active()) do if skill.activeEffect.grantedEffect.id == id then return skill end end
	end
	function facts.Applied(skill, id)
		for _, effect in ipairs(skill.effectList or { }) do if effect.grantedEffect.id == id then return effect end end
	end
	function facts.WindowProbe(skill, mode)
		cached.windows = cached.windows or { }
		cached.windows[skill] = cached.windows[skill] or { }
		if cached.windows[skill][mode] ~= nil then return cached.windows[skill][mode] or nil end
		local calcs = context.build.calcsTab.calcs
		local shadow = setmetatable({ }, { __index = context.env.build })
		for index, group in ipairs(context.build.skillsTab.socketGroupList) do if group == skill.socketGroup then shadow.mainSocketGroup = index break end end
		local probe = calcs.initEnv(shadow, "CALCULATOR")
		local candidate
		for i = #probe.player.activeSkillList, 1, -1 do
			local other = probe.player.activeSkillList[i]
			local match = other.activeEffect.srcInstance == skill.activeEffect.srcInstance
				and other.activeEffect.grantedEffect.id == skill.activeEffect.grantedEffect.id
			local remove = mode == "guard" and other.skillTypes[SkillType.Guard] and not match
				or mode == "withoutRF" and other.activeEffect.grantedEffect.id:match("^RighteousFire")
			if remove then t_remove(probe.player.activeSkillList, i) elseif match then candidate = other end
		end
		if not candidate then cached.windows[skill][mode] = false return end
		probe.player.mainSkill = candidate
		if calcs.perform(probe) == false then cached.windows[skill][mode] = false return end
		cached.windows[skill][mode] = probe
		return probe
	end
	function facts.SingleHit(probe, actor)
		probe = probe or context.env; actor = actor or probe.player
		local out = actor.output
		if probe.configInput.enemyDamageType == "DamageOverTime" or (out.ConfiguredNotHitChance or 0) >= 100 or (out.totalTakenHit or 0) <= 0 then return end
		local damage = { }
		for _, kind in ipairs({ "Physical", "Fire", "Cold", "Lightning", "Chaos" }) do damage[kind] = out[kind .. "TakenHit"] or 0 end
		local after = context.build.calcsTab.calcs.reducePoolsByDamage(nil, damage, actor)
		return { before = out, after = after, lifeLost = m_max(0, (out.LifeRecoverable or 0) - after.Life),
			esLost = m_max(0, (out.EnergyShieldRecoveryCap or out.EnergyShield or 0) - after.EnergyShield) }
	end
	function facts.SkillCount(skill)
		local group = skill.socketGroup
		if not group then return 1 end
		if group.groupCount then return group.groupCount end
		for _, gem in pairs(group.gemList) do
			local data = gem.gemData
			if data and (skill.activeEffect.grantedEffect == data.grantedEffect
				or skill.activeEffect.grantedEffect == data.secondaryGrantedEffect) then return gem.count or 1 end
		end
		return 1
	end
	function facts.Stats(skill)
		cached.stats = cached.stats or { }
		if not cached.stats[skill] then cached.stats[skill] = calcLib.buildSkillInstanceStats(skill.activeEffect, skill.activeEffect.grantedEffect) end
		return cached.stats[skill]
	end
	function facts.MainHit()
		local skill = context.mainSkill
		return skillEnabled(skill) and M.IsDirect(skill) and not skill.minion and skill.skillFlags.hit
			and Policy.HitRate(context, context.env.player.output) > 0
	end
	function facts.PersonalKills()
		return Policy.KillRate(context, "player") > 0 and M.IsDirect(context.mainSkill) and Policy.MainKillActor(context.env) == "player"
	end
	function facts.Taunt()
		if cached.taunt ~= nil then return cached.taunt or nil end
		local out, rate, chanceTotal, reasons, review = facts.env.player.output, 0, 0, { }, false
		if facts.MainHit() then
			for _, line in ipairs(facts.Lines()) do
				local chance = tonumber(line.text:match("^(%d+)%% chance to taunt enemies on hit$"))
				if chance then chanceTotal = chanceTotal + chance; t_insert(reasons, line.source) end
			end
			rate = Policy.HitRate(context, out) * m_min(100, chanceTotal) / 100
		end
		for _, skill in ipairs(facts.Active()) do
			if skill.skillTypes[SkillType.Warcry] and M.IsDirect(skill)
				and (skill.activeEffect.grantedEffect.description or ""):lower():find("taunt", 1, true) then
				local probe = facts.Probe(skill)
				local cooldown = probe and probe.player.output.Cooldown or 0
				if cooldown > 0 then
					if 1 / cooldown > rate then rate, review = 1 / cooldown, true end
					t_insert(reasons, "Enabled self-used " .. skill.activeEffect.grantedEffect.name .. " taunts; native cooldown " .. cooldown
						.. "s. Confirm target range and actual use.")
				end
			end
		end
		if rate > 0 and not facts.env.enemy.modDB:Flag(nil, "TauntImmune") then cached.taunt = { rate = rate, reason = t_concat(reasons, "\n"),
			review = review } else cached.taunt = false end
		return cached.taunt or nil
	end
	function facts.Ailment(name)
		if not facts.MainHit() then return end
		local out = facts.env.player.output
		local rate = M.AilmentRate(facts.env, out, Policy.HitRate(context, out), name)
		if rate > 0 then return { rate = rate, reason = "Your hits apply " .. name .. "." } end
	end
	function facts.Incoming()
		if cached.incoming then return cached.incoming end
		local env, out = context.env, context.env.player.output
		local category = env.configInput.enemyDamageType or "Average"
		local incoming = { category = category, rate = 0, attack = 0, spellDamage = 0, damage = 0, elemental = { }, critical = 0 }
		cached.incoming = incoming
		if category == "DamageOverTime" then return incoming end
		for _, source in ipairs(Policy.Incoming(context.settings, out, category).categories) do
			local kind, rate = source.kind, source.rate
			incoming.rate = incoming.rate + rate
			if kind == "Melee" or kind == "Projectile" then incoming.attack = incoming.attack + rate end
			local block = source.blockChance
			local damageRate = rate * ((out.BlockEffect or 100) >= 100 and (1 - m_min(100, block) / 100) or 1)
			if (kind == "Spell" or kind == "SpellProjectile") and (out.SpellSuppressionEffect or 0) >= 100 then
				damageRate = damageRate * (1 - m_min(100, out.EffectiveSpellSuppressionChance or 0) / 100)
			end
			incoming.damage = incoming.damage + damageRate
			if kind == "Spell" or kind == "SpellProjectile" then incoming.spellDamage = incoming.spellDamage + damageRate end
		end
		if (out.totalTakenHit or 0) <= 0 then incoming.damage, incoming.spellDamage = 0, 0 end
		for _, element in ipairs({ "Fire", "Cold", "Lightning" }) do
			incoming.elemental[element] = (out[element .. "TakenHit"] or 0) > 0 and incoming.damage or 0
		end
		incoming.critical = incoming.rate * m_max(0, m_min(100, out.EnemyCritChance or 0)) / 100
		local mix = category == "Average" and string.format(" with %g%% attacks and %g%% spells", context.settings.incomingAttackShare,
			100 - context.settings.incomingAttackShare) or ""
		incoming.reason = string.format(prose.incomingScenario, category, context.settings.incomingHitRate, mix, incoming.rate, incoming.attack,
			incoming.spellDamage)
		return incoming
	end
	return facts
end

local modelRules = {
	setting = "Native value only.",
	state = "Needs a real granting source.",
	decision = "You choose; nothing is guessed.",
	default = "Clears the override for PoB's value.",
	event = "Auto at the expected-event threshold.",
	count = "Expected count, rounded down.",
	choice = "You choose the option.",
	boolean = "Checks source and activation.",
	elapsed = "Elapsed time of one application.",
	stack = "Stacks built from zero.",
	amount = "Amount from the native budget.",
}
function M.Registry()
	local registry = { definitions = { }, capabilities = { }, neutralInputs = { } }
	function registry.Register(names, method, kind) M.Register(registry, names, method, kind) end
	function registry.Define(definition)
		assert(not registry.capabilities[definition.var], "Duplicate auto-config rule: " .. definition.var)
		assert(modelRules[definition.model] and definition.evaluate and definition.condition)
		registry.capabilities[definition.var] = ruleEntry(definition.condition .. " " .. modelRules[definition.model], definition.confirmation, definition.kind)
		t_insert(registry.definitions, definition)
	end
	function registry.Neutralize(config)
		for _, definition in ipairs(registry.definitions) do
			if not definition.keepDuringDetection then config.input[definition.var], config.placeholder[definition.var] = definition.neutralValue, nil end
		end
	end
	function registry.Detect(context)
		local facts = context.facts or M.Facts(context)
		for _, definition in ipairs(registry.definitions) do
			local result = definition.evaluate(facts)
			if result then
				local review = definition.kind ~= "automatic" or not not result.review
				local label, value, assumption = result.label or StripEscapes(context.options[definition.var].label), result.value, result.assumption
				if definition.model == "setting" then
					context.suggest(definition.var, result.reason, review, label, result.value, result.requires, assumption)
				elseif definition.model == "state" and type(result.value) == "boolean" then
					context.suggest(definition.var, result.reason, review, label, result.value, result.requires, assumption, nil, result.activation)
				elseif definition.model == "decision" or definition.model == "state" then
					local choices = result.choices or { }
					if #choices > 0 then context.suggest(definition.var, result.reason, true, "Choose " .. label:gsub(":$", ""), choices[1].val,
						result.requires, result.assumption, choices) end
				elseif definition.model == "default" then
					context.suggest(definition.var, result.reason, review, label, context.defaultValue, result.requires, assumption)
				elseif definition.model == "stack" or definition.model == "amount" then
					local amount = definition.model == "stack" and M.StackCount(facts.seconds, result) or result.amount
					if amount and amount >= 0 and amount < math.huge then
						value = math.floor(amount + 1e-8)
						if result.cap then value = m_min(value, result.cap) end
						if value > 0 or result.allowZero then
							assumption = assumption or Policy.Scenario("Starts at zero; confirm the window.")
							assumption.automatic = not review
							local before = context.found and context.found[definition.var]
							context.suggest(definition.var, result.reason, review, label:gsub(":$", "") .. ": " .. value, value, result.requires,
								assumption, nil, result.activation)
							-- A dependent proposal is retargeted only once this one is
							-- actually accepted; a filtered or superseded suggestion
							-- must not alter another rule's output.
							local dependent, accepted = result.dependent, context.found and context.found[definition.var]
							if dependent and accepted and accepted ~= before then
								local target = context.found[dependent.var]
								if target then
									target.value, target.label = dependent.value, dependent.label or target.label
									if dependent.reason then target.reason = target.reason .. "\n" .. dependent.reason end
								end
							end
						end
					end
				elseif definition.model == "event" or definition.model == "count" then
					local window = m_min(facts.seconds, definition.window or Policy.recentWindow)
					local rate = result.rate or 0
					if rate > 0 then
						assumption = Policy.Rate(facts.context.settings, rate, window)
						if definition.model == "count" then
							value, review = M.Count(assumption.expected, review)
							if result.cap then value = m_min(result.cap, value) end
							label = label:gsub(":$", "") .. ": " .. value
							assumption.description = assumption.description
								.. " Rounded down."
						else review = review or not assumption.automatic end
						assumption.automatic = not review
						context.suggest(definition.var, result.reason, review, label, value, result.requires, assumption)
					end
				elseif definition.model == "elapsed" then
					local elapsed, duration = result.elapsed or facts.seconds, result.duration or 0
					if elapsed >= 0 and duration > 0 and (elapsed < duration or result.upkeep) then
						value = math.floor((result.percent and m_min(100, 100 * elapsed / duration) or elapsed) + 1e-8)
						if result.cap then value = m_min(value, result.cap) end
						if value > 0 then
							label = label:gsub(":$", "") .. ": " .. value
							assumption = result.assumption or Policy.Scenario("Confirm one uninterrupted window of " .. duration
								.. "s.")
							context.suggest(definition.var, result.reason, review, label, value, result.requires, assumption)
						end
					end
				elseif definition.model == "choice" then
					local choices = { }
					for _, option in ipairs(context.options[definition.var].list) do
						if not result.allowed or result.allowed[option.val] then t_insert(choices, { val = option.val, label = option.label }) end
					end
					if #choices > 0 then context.suggest(definition.var, result.reason, true, "Choose " .. label:gsub(":$", ""), choices[1].val,
						result.requires, assumption, choices) end
				else
					assert(value == nil or type(value) == "boolean", "Boolean auto-config rule returned a non-boolean: " .. definition.var)
					context.suggest(definition.var, result.reason, review, label, value, result.requires, assumption)
				end
			end
		end
	end
	return registry
end
-- Profile rules (Profiles, Uncertain) keep the user's value during detection
-- and carry a plain explanation that Text reads back.
local function defineProfile(registry, var, model, condition, confirmation, explanation, evaluate)
	registry.explanations[var] = explanation
	registry.Define({ var = var, model = model, kind = "assisted", keepDuringDetection = true, condition = condition, confirmation = confirmation,
		evaluate = evaluate })
end

-- Shared modelling policies are explicit assumptions, never character facts.
local Profiles = M.Registry()
M.Profiles = Profiles
Profiles.structural, Profiles.explanations, Profiles.defaultVars = { }, { }, { }
Profiles.geometry = { }
function Profiles.KeepsSetting(var, settings)
	if not Profiles.structural[var] then return false end
	local geometry = Profiles.geometry[var]
	if geometry == "distance" then return settings.distanceProfile == "KEEP" end
	if geometry == "overlap" then return settings.overlapProfile == "KEEP" end
	return settings.calculationProfile == "KEEP"
end
function Profiles.GetStatus(var, settings)
	if Profiles.KeepsSetting(var, settings) then return "Kept by combat model" end
	if not Profiles.geometry[var] then return "Matches combat model" end
end
local function define(var, mode, condition, text, evaluate)
	Profiles.structural[var] = true
	defineProfile(Profiles, var, mode, condition, "Confirm this combat model profile.", text, evaluate)
end
local averages = { ailmentMode = "AVERAGE", physMode = "AVERAGE", lifeRegenMode = "AVERAGE", resourceGainMode = "AVERAGE",
	EHPUnluckyWorstOf = 1, armourCalculationMode = "AVERAGE", warcryMode = "AVERAGE", pactMode = "AVERAGE",
		ChanceToIgnoreEnemyPhysicalDamageReductionMode = "AVERAGE" }
for var, value in pairs(averages) do
	define(var, "choice", prose.calculationModes.condition, prose.calculationModes.explanation, function(facts)
		local profile = facts.context.settings.calculationProfile
		if profile == "KEEP" then return end
		local target = profile == "CAREFUL" and var == "EHPUnluckyWorstOf" and 4 or value
		local option = facts.context.options[var]
		local current = facts.context.originalBuild.configTab.input[var]
		if current == nil then current = option.list[option.defaultIndex or 1].val end
		if current == target then return end
		return { allowed = { [target] = true }, reason = "The " .. profile .. " model uses " .. tostring(target)
			.. " for this setting." }
	end)
end
for _, var in ipairs({ "DisableEHPGainOnBlock", "EVBypass", "ignoreItemDisablers", "ignoreJewelLimits", "EEIgnoreHitDamage" }) do
	define(var, "state", prose.calculationOverrides.condition, prose.calculationOverrides.explanation, function(facts)
		if facts.context.settings.calculationProfile == "KEEP" or facts.context.originalBuild.configTab.input[var] ~= true then return end
		return { value = false, reason = "Clears this calculation override." }
	end)
end
define("bloodSacramentReservationEHP", "state", prose.bloodSacramentReservationEHP.condition, prose.bloodSacramentReservationEHP.explanation, function(facts)
	-- Relic of the Pact grants the skill with id "BloodSacramentUnique" (Data/Skills/other.lua).
	if facts.context.settings.calculationProfile == "KEEP" or not facts.Find("BloodSacramentUnique") then return end
	local option = facts.context.options.bloodSacramentReservationEHP
	local target = option.defaultState == true
	if facts.context.originalBuild.configTab.input.bloodSacramentReservationEHP == target
		or facts.context.originalBuild.configTab.input.bloodSacramentReservationEHP == nil then return end
	return { value = target, reason = "Restores Blood Sacrament's default." }
end)
for _, var in ipairs({ "multiplierPvpTvalueOverride", "multiplierPvpDamage" }) do
	Profiles.defaultVars[var] = true
	define(var, "default", prose.pvp.condition, prose.pvp.explanation, function(facts)
		if facts.context.settings.calculationProfile == "KEEP" then return end
		local config = facts.context.originalBuild.configTab
		if config.input[var] == nil and config.placeholder[var] == nil then return end
		return { reason = "Removes the manual PvP value." }
	end)
end
local skills = { curseOverlaps = "Doom Blast", perforateSpikeOverlap = "Perforate", ShrapnelBallistaProjectileOverlap = "Shrapnel Ballista",
	stormRainBeamOverlap = "Storm Rain", toxicRainPodOverlap = "Toxic Rain" }
for var, name in pairs(skills) do
	Profiles.geometry[var] = "overlap"
	define(var, "amount", string.format(prose.overlap.condition, name), prose.overlap.explanation, function(facts)
		if facts.context.settings.overlapProfile ~= "SINGLE" then return end
		for _, skill in ipairs(facts.Active()) do
			local actual = skill.activeEffect.grantedEffect.name
			if actual == name or (var == "perforateSpikeOverlap" or var == "ShrapnelBallistaProjectileOverlap" or var == "toxicRainPodOverlap")
				and actual:sub(1, #name + 4) == name .. " of " then
				local probe = facts.Probe(skill)
				local out = probe and probe.player.output
				local blood = var ~= "perforateSpikeOverlap" or actual == "Perforate of Bloodshed" or probe and probe.player.modDB:GetCondition("BloodStance")
				if blood and out and (out.TotalDPS or out.AverageHit or 0) > 0 then
					local assumption = Policy.Scenario("Models one overlapping hit.")
					assumption.automatic = false
					return { amount = 1, assumption = assumption, reason = "Actual enabled " .. actual
						.. " deals damage; one overlap is used." }
				end
			end
		end
	end)
end
for _, entry in ipairs({ { "meleeDistance", "meleeDistanceMetres", "melee" }, { "projectileDistance", "projectileDistanceMetres", "projectile" } }) do
	local var, setting, kind = unpack(entry)
	Profiles.geometry[var] = "distance"
	define(var, "amount", string.format(prose.distance.condition, kind), prose.distance.explanation, function(facts)
		if facts.context.settings.distanceProfile ~= "PROFILE" then return end
		local skill, out = facts.context.mainSkill, facts.env.player.output
		if not skill.skillFlags[kind] or (out.TotalDPS or out.AverageHit or 0) <= 0 then return end
		local distance = facts.context.settings[setting]
		local units = distance * 10
		if math.abs(units - math.floor(units + 0.5)) > 1e-7 then return end
		return { amount = units, allowZero = true, label = StripEscapes(facts.context.options[var].label) .. " (" .. distance .. " metres)",
			reason = "The actual main " .. kind .. " skill uses " .. distance .. " metres = "
				.. units .. " units. Confirm this position.",
				assumption = { automatic = false, description = "Uses your positioning profile." } }
	end)
end

-- Absence/zero rules do not pretend to solve unknown positive quantities.
local Uncertain = M.Registry()
M.Uncertain = Uncertain
Uncertain.limited, Uncertain.explanations = { }, { }
Uncertain.sampleDerived = { hoaOverkill = true }
local function define(var, condition, explanation, evaluate)
	local sample = Uncertain.sampleDerived[var]
	Uncertain.limited[var] = true
	defineProfile(Uncertain, var, "amount", condition .. (sample and " Positive amount needs a hit sample."
		or " Zero only without generation."),
		sample and "Confirm both numbers are for one kill."
			or "Confirm a fresh window without stacks.", explanation, evaluate)
end
local function zero(reason)
	return { amount = 0, allowZero = true, reason = reason, assumption = { automatic = false,
		description = "Confirm a fresh fight window." } }
end
local function noApplyingHit(facts, test)
	for _, skill in ipairs(facts.Active()) do
		if skill.skillFlags.hit then
			local probe = facts.Probe(skill)
			local actor = probe and (skill.minion and probe.minion or probe.player)
			if not actor or not actor.output then return false end -- unknown is not zero
			if test(actor.output) then return false end
			for _, pass in ipairs(M.HitOutputs(actor.output)) do if test(pass) then return false end end
		end
	end
	return true
end
define("hoaOverkill", prose.hoaOverkill.condition, prose.hoaOverkill.explanation, function(facts)
	if not facts.Find("HeraldOfAsh") then return end
	if not facts.context.mapping then return zero("Herald of Ash with no kills: zero.") end
	local hit, life = facts.context.settings.overkillHitDamage, facts.context.settings.overkillLifeBeforeHit
	if life <= 0 or hit < life or not facts.MainHit() or not facts.PersonalKills() then return end
	return { amount = hit - life, allowZero = true, reason = string.format("Hit %g minus %g Life = %g overkill.", hit, life, hit - life),
		assumption = { automatic = false, description = "Uses your killing-hit sample." } }
end)
define("multiplierHallowingFlameStacksRemovedByAlly", prose.multiplierHallowingFlameStacksRemovedByAlly.condition,
	prose.multiplierHallowingFlameStacksRemovedByAlly.explanation, function(facts)
	if not facts.context.settings.assumeSolo then return end
	for _, skill in ipairs(facts.Active()) do
		if skill.minion or skill.skillFlags.totem or skill.skillFlags.trap or skill.skillFlags.mine then return end
	end
	return zero(prose.multiplierHallowingFlameStacksRemovedByAlly.zero)
end)
define("heraldOfAgonyVirulenceStack", prose.heraldOfAgonyVirulenceStack.condition, prose.heraldOfAgonyVirulenceStack.explanation, function(facts)
	if facts.Find("HeraldOfAgony") and noApplyingHit(facts, function(out) return (out.PoisonDPS or 0) > 0 and (out.PoisonChance or 0) > 0 end) then
		return zero(prose.heraldOfAgonyVirulenceStack.zero)
	end
end)
define("heraldOfTheHivePressure", prose.heraldOfTheHivePressure.condition, prose.heraldOfTheHivePressure.explanation, function(facts)
	if not facts.Find("HeraldOfTheBreach") then return end
	local absent = noApplyingHit(facts, function(out)
		for _, kind in ipairs({ "Poison", "Bleed", "Ignite" }) do if (out[kind .. "DPS"] or 0) > 0 and (out[kind .. "Chance"] or 0) > 0 then return true end end
		if (out.FreezeCanApply or 0) > 0 then return true end
		for _, kind in ipairs({ "Chill", "Shock", "Scorch", "Brittle", "Sap" }) do if (out[kind .. "HitEffectEstimate"] or 0) > 0 then return true end end
		return false
	end)
	if absent then return zero(prose.heraldOfTheHivePressure.zero) end
end)
define("overrideCruelty", prose.overrideCruelty.condition, prose.overrideCruelty.explanation, function(facts)
	local supported = false
	for _, skill in ipairs(facts.Active()) do
		if skill.baseSkillModList:Flag(skill.skillCfg, "Cruelty") then
			supported = true
			local probe = facts.Probe(skill)
			local out = probe and probe.player.output
			if not out or M.HasGeneratingHit(out) then return end
		end
	end
	if supported then return zero(prose.overrideCruelty.zero) end
end)

-- Short player-facing explanations. Full source rules are shown in Details and
-- are available through the optional calculation-details preference.
local Text = { }
M.Text = Text
local specific = {
	buffOnslaught = "What gives you Onslaught?",
	minionBuffOnslaught = "Do minions keep Onslaught from kills?",
	conditionFullMana = "Are you at full mana when it matters?",
	conditionFullEnergyShield = "Are you still at full Energy Shield?",
	conditionHaveEnergyShield = "Do you still have Energy Shield?",
	minionsConditionFullEnergyShield = "Is your minion at full Energy Shield?",
	conditionStationary = "How long do you stand still?",
	conditionConvergence = "Enable to see your Convergence boost.",
	summonLightningGolemEnableWrath = "Does the Golem's aura reach you?",
	conditionMoving = "Count this only while you move.",
	bloodSandStance = "Choose the stance you use.",
	doomBlastSource = "What ends your curses for Doom Blast?",
	linkedSourceRate = "Choose the minion you stay linked to.",
	waitForMaxSeals = "Keep casting or wait for all seals?",
	repeatMode = "Average the cycle or use the last hit?",
	ruthlessSupportMode = "Average or Ruthless hits only?",
	waveOfConvictionExposureType = "Which Exposure does your Wave apply?",
	elementalArmyExposureType = "Which Exposure does your minion apply?",
	buffArcaneSurge = "How do you get Arcane Surge?",
	buffLifetap = "Do you spend enough life for Lifetap?",
	conditionAtCloseRange = "Does your attack hit at close range?",
	multiplierNearbyAlly = "How many minions stay near you?",
	multiplierNearbyCorpse = "How many corpses stay near you?",
	tornadoShotSecondaryHitChance = "Clear it to use PoB's average.",
	overrideBuffBlinded = "Clear it to let PoB calculate Blind.",
}
-- Prompts for Guided settings whose answers are not stored in gear or gems.
Text.questions = {
	resistancePenalty = "How far have you finished the campaign?",
	bandit = "Who did you help in the bandit quest?",
	pantheonMajorGod = "Which major Pantheon do you use?",
	pantheonMinorGod = "Which minor Pantheon do you use?",
	ailmentMode = "Which hit should ailments use?",
	physMode = "How should random elements be modelled?",
	lifeRegenMode = "Average or peak life regeneration?",
	resourceGainMode = "Average or burst recovery?",
	EHPUnluckyWorstOf = "How cautious should survival be?",
	DisableEHPGainOnBlock = "Ignore recovery from blocks and hits?",
	armourCalculationMode = "Average or peak armour?",
	warcryMode = "Average or peak Warcry bonuses?",
	pactMode = "How should Pact bonuses be averaged?",
	EVBypass = "Disable Emperor's Vigilance bypass?",
	ignoreItemDisablers = "Ignore item disablers? Usually off.",
	ignoreJewelLimits = "Ignore jewel limits? Usually off.",
	bloodSacramentReservationEHP = "Count Blood Sacrament in survival?",
	ChanceToIgnoreEnemyPhysicalDamageReductionMode = "Average, unlucky or best case?",
	multiplierPvpTvalueOverride = "PvP timing in ms; usually the default.",
	multiplierPvpDamage = "PvP damage multiplier to test.",
	EEIgnoreHitDamage = "Leave this skill's hit damage out?",
	overrideCruelty = "Cruelty % you maintain (0-40).",
	curseOverlaps = "How many curse areas overlap?",
	heraldOfAgonyVirulenceStack = "Virulence stacks you keep in the fight.",
	heraldOfTheHivePressure = "Pressure stacks you keep in the fight.",
	hoaOverkill = "Overkill damage from a killing hit.",
	perforateSpikeOverlap = "How many spikes hit together?",
	ShrapnelBallistaProjectileOverlap = "How many projectiles hit together?",
	stormRainBeamOverlap = "How many beams hit at once?",
	toxicRainPodOverlap = "How many pods overlap the target?",
	meleeDistance = "Distance to the enemy, in metres.",
	projectileDistance = "Projectile travel distance, in metres.",
	conditionStunnedEnemyRecently = "Did your hits stun an enemy recently?",
	conditionHitsAlwaysStun = "Does every relevant hit stun?",
	conditionEnemyStunned = "Is the enemy actually stunned?",
	multiplierHallowingFlameStacksRemovedByAlly = "Flames an ally removed recently?",
	multiplierHexDoom = "Doom your Hex has built up?",
	skillForkCount = "How many forks before this hit?",
	skillChainCount = "How many chains before this hit?",
	skillPierceCount = "How many pierces before this hit?",
}
local function has(value, word) return value:lower():find(word:lower(), 1, true) ~= nil end
-- Internal helpers take settings already normalised by the public entry point.
local function describe(info, option, settings)
	local var = info.var
	if Profiles.explanations[var] then return Profiles.explanations[var] end
	if Uncertain.explanations[var] then return Uncertain.explanations[var] end
	if var == "resistancePenalty" then return "Which Kitava fights have you finished?" end
	if var == "bandit" or var == "pantheonMajorGod" or var == "pantheonMinorGod" then return prose.importedChoice end
	if var == "conditionHitsAlwaysStun" then return "Does your skill guarantee a Stun?" end
	if var == "conditionStunnedEnemyRecently" or var == "conditionEnemyStunned" then
		return prose.stunRecently
	end
	if not info.supported then
		return Text.questions[var] or (info.kind == "legacy" and "This setting is for older builds."
			or "Use the value from your fight.")
	end
	if var:find("Blocked", 1, true) and not has(var, "multiplier") and var ~= "BlockedPast10Sec" then
		local kind = var == "conditionBlockedAttackRecently" and "attack" or var == "conditionBlockedSpellRecently" and "spell" or "attack or spell"
		local window = var:find("10",1,true) and 10 or 4
		local target = window == 10 and " This needs a Boss, Pinnacle or Uber target." or ""
		return string.format(prose.blockRecently, settings.blockThreshold, kind, settings.incomingEventThreshold, window,
			settings.incomingAttackShare) .. target
	elseif var == "conditionSuppressedRecently" then
		return string.format(prose.suppressedRecently, settings.suppressionThreshold, settings.incomingEventThreshold, 100 - settings.incomingAttackShare)
	elseif specific[var] then return specific[var]
	elseif info.kind == "calculated-default" then
		return "Clear it so PoB recalculates it."
	elseif has(var,"Shrine") then
		return "Choose the Shrine buff you received."
	elseif var:match("^balanceOfTerrorSelfCast") then
		return "Do you also curse enemies with it?"
	elseif var:match("^divineSentinel") then
		return "Which aura did your Sentinel get?"
	elseif var:find("BypassCD",1,true) then
		return "Can you skip the cooldown with charges?"
	elseif has(var,"Empty") and has(var,"Sockets") then
		return "Clear it to count empty sockets."
	elseif var == "conditionLowLife" or var == "conditionFullLife" or var == "conditionLowMana" or var == "conditionLowEnergyShield" then
		return "Use the box for a state you reach."
	elseif has(var,"Ground") or has(var,"ChillingArea") or has(var,"FrostGlobe") then
		return "What creates this area?"
	elseif has(var,"NearLinked") or has(var,"BetweenYouAndLinked") or var == "multiplierLinkedTargets" then
		return "Does the target stay linked?"
	elseif has(var,"ForkCount") or has(var,"ChainCount") or has(var,"PierceCount") then
		return "Zero for the first hit."
	elseif has(var,"Charge") then
		return prose.charges
	elseif has(var,"Blinded") or has(var,"Blind") then
		return "What Blinds the enemy?"
	elseif has(var,"Effect") and (has(var,"Shock") or has(var,"Chill") or has(var,"Brittle") or has(var,"Scorch") or has(var,"Sap")) then
		return "How strong is this effect on the enemy?"
	elseif has(var,"Spectre") or has(var,"Golem") then
		return "Can your minion apply this effect?"
	elseif has(var,"Minion") and (has(var,"Life") or has(var,"EnergyShield")) then
		return "Check your minion's Life and ES."
	elseif has(var,"Killed") or has(var,"Kill") or has(var,"Rampage") or has(var,"SoulEater") then
		if var == "multiplierSoulEater" or var == "multiplierRampage" then
			return string.format("Kills/s: %g you, %g minions, %g totems.",
				settings.regularKillRate, settings.minionKillRate, settings.totemKillRate)
		end
		local source, rate = "your kills", settings.regularKillRate
		if has(var, "Minion") then source, rate = "minion kills", settings.minionKillRate end
		if has(var, "Totem") then source, rate = "totem kills", settings.totemKillRate end
		return string.format("PoB uses %g per second for %s.", rate, source)
	elseif has(var,"BeenHit") or has(var,"Taken") or has(var,"StunnedRecently") or has(var,"Suppressed") or var == "BlockedPast10Sec" then
		return string.format("From your defences and %g hits/s.", settings.incomingHitRate)
	elseif has(var,"Recently") or has(var,"Past") or has(var,"Last") then
		return string.format(prose.recentEvents, settings.expectedEventThreshold)
	elseif has(var,"Stacks") or has(var,"Stages") or has(var,"multiplier") or option
		and (option.type == "count" or option.type == "countAllowZero" or option.type == "float") then
		return "How many at the moment you calculate?"
	elseif option and option.type == "list" then
		return "Choose the option you use."
	elseif info.kind == "assisted" then
		return "When is this effect active?"
	end
	return "What gives you this effect?"
end
local refreshVars = {
	conditionEnemyChilled = true, conditionEnemyShocked = true, conditionEnemyScorched = true,
	conditionEnemyBrittle = true, conditionEnemySapped = true, conditionEnemyFrozen = true,
	conditionEnemyPoisoned = true, conditionEnemyBleeding = true, conditionEnemyIgnited = true,
	conditionEnemyChilledByYourHits = true, conditionEnemyBlinded = true,
	conditionEnemyCoveredInAsh = true, conditionEnemyCoveredInFrost = true,
	multiplierChilledByYouSeconds = true, multiplierFrozenByYouSeconds = true,
}
local function explain(info, option, settings)
	local text = describe(info, option, settings)
	if refreshVars[info.var] then
		text = text .. string.format(prose.effectRefresh, settings.effectRefreshThreshold)
	end
	if info.var == "conditionHitRecently" or info.var == "conditionCritRecently" or info.var == "conditionHitSpellRecently"
		or info.var == "multiplierSkillUsedRecently" or info.var == "multiplierChannelling" or info.var == "multiplierLifeSpentRecently"
		or info.var == "multiplierManaSpentRecently" then
		text = text .. string.format(" Main skill use: %g%% of the fight.", settings.mainSkillActivity)
	end
	return text
end
-- Public entry points normalise the settings exactly once.
function Text.Describe(info, option, settings)
	return explain(info, option, Preferences.Normalize(settings))
end
local percentValues = {
	conditionShockEffect = true, conditionEnemyChilledEffect = true, conditionScorchedEffect = true,
	conditionBrittleEffect = true, conditionSapEffect = true, overrideCruelty = true, resistancePenalty = true,
	manabondMissingUnreservedManaPercentage = true,
}
function Text.ValueLabel(var, option, value)
	if value == nil then return "PoB default" end
	if type(value) == "boolean" then return value and "On" or "Off" end
	if option and option.type == "list" then
		for _, choice in ipairs(option.list) do
			if choice.val == value then return StripEscapes(choice.label) end
		end
	end
	if type(value) == "number" then
		if var == "meleeDistance" or var == "projectileDistance" then return string.format("%g metres", value / 10) end
		if percentValues[var] then return string.format("%g%%", value) end
	end
	return tostring(value)
end
function Text.MeasuredReason(entry)
	local assumption = entry.assumption
	if not assumption then return "" end
	if assumption.rule == "incoming-chance" then
		local suppress = entry.var == "conditionSuppressedRecently"
		local chance = suppress and "Spell suppression" or "Block"
		local text = string.format("\n%s chance is %g%%.", chance, assumption.chance)
		if assumption.expected then
			text = text .. string.format(" About %.1f %s in %g seconds.", assumption.expected, suppress and "suppressed hits" or "blocks",
				assumption.window)
		end
		if not assumption.automatic then
			text = text .. string.format(" PoB needs %g%% chance and about %g %s.", assumption.threshold, assumption.eventThreshold, suppress
				and "suppressed hits" or "blocks")
		end
		return text
	elseif assumption.rule == "event-rate" then
		local text = ""
		if assumption.stunChance then text = string.format("\nEach hit has a %g%% chance to Stun.", assumption.stunChance) end
		text = text .. string.format("\nAbout %.1f times in %g seconds.", assumption.expected, assumption.window)
		if not assumption.automatic and assumption.threshold then text = text .. string.format(" PoB needs %g to assume it happens.", assumption.threshold) end
		return text
	elseif assumption.spending then
		local spending = assumption.spending
		if spending.paidByShield then
			return "\nEnergy Shield can pay for this skill."
		end
		return string.format("\nSpent: %g %s in %gs; needs %g.", spending.amount, spending.resource:lower(), spending.window,
			spending.threshold)
	end
	return ""
end

function Text.Reason(entry, info, option, settings, showProposal)
	settings = Preferences.Normalize(settings)
	local text = explain(info, option, settings)
	if showProposal ~= false then
		if entry.numeric and not entry.choiceConfirmed then text = text .. "\nEnter the amount you maintain."
		elseif entry.numeric then text = text .. "\nYour confirmed value: " .. tostring(entry.value) .. "."
		elseif entry.choices then text = text .. "\nChoose the option you use."
		elseif entry.useDefault then text = text .. "\nClear your override for PoB's value."
		elseif entry.value ~= nil and not entry.unresolved then
			text = text .. "\nSuggested value: " .. Text.ValueLabel(entry.var, option, entry.value) .. "."
		end
	end
	text = text .. Text.MeasuredReason(entry)
	if settings.showDetails then text = text .. "\n\nCalculation details:\n" .. entry.reason end
	return text
end

-- Overrides for which the calculation files explicitly supply a computed fallback.
-- Keeping the input blank retains the live calculation rather than freezing a sampled number.
M.Defaults = {
	["TotemsSummoned"] = { stat = "TotemsSummoned" },
	["conditionChilledEffect"] = { stat = "ChillVal" },
	["conditionHallowingFlameMagnitude"] = { stat = "HallowingFlameMagnitude" },
	["conditionPlayerShockEffect"] = { stat = "ShockVal" },
	["minesPerThrow"] = { stat = "MineThrowCount" },
	["missingUnreservedLifePercent"] = { stat = "MissingUnreservedLifePercent" },
	["multiplierWarcryPower"] = { stat = "WarcryPower" },
	["overrideBlitzCharges"] = { stat = "BlitzCharges" },
	["overrideBloodCharges"] = { stat = "BloodCharges" },
	["overrideChallengerCharges"] = { stat = "ChallengerCharges" },
	["overrideCrabBarriers"] = { stat = "CrabBarriers" },
	["overrideEnduranceCharges"] = { stat = "EnduranceCharges" },
	["overrideFortification"] = { stat = "FortificationStacks" },
	["overrideFrenzyCharges"] = { stat = "FrenzyCharges" },
	["overrideInspirationCharges"] = { stat = "InspirationCharges" },
	["overridePowerCharges"] = { stat = "PowerCharges" },
	["overrideSiphoningCharges"] = { stat = "SiphoningCharges" },
	["trapsPerThrow"] = { stat = "TrapThrowCount" },
}

-- Config checkbox targets with independent providers in the calculation or data files.
-- The scan still checks the neutral actor state; eligibility alone never enables a setting.
M.Conditions = {
	["DetonatedMinesRecently"] = { flag = "Condition:DetonatedMinesRecently", actor = "player" },
	["TriggeredTrapsRecently"] = { flag = "Condition:TriggeredTrapsRecently", actor = "player" },
	["buffAdrenaline"] = { flag = "Condition:Adrenaline", actor = "player" },
	["buffArcaneSurge"] = { flag = "Condition:ArcaneSurge", actor = "player" },
	["buffChaoticMight"] = { flag = "Condition:ChaoticMight", actor = "player" },
	["buffDiamondShrine"] = { flag = "Condition:DiamondShrine", actor = "player" },
	["buffElusive"] = { flag = "Condition:Elusive", actor = "player" },
	["buffFortification"] = { flag = "Condition:Fortified", actor = "player" },
	["buffMassiveShrine"] = { flag = "Condition:MassiveShrine", actor = "player" },
	["buffOnslaught"] = { flag = "Condition:Onslaught", actor = "player" },
	["buffPhasing"] = { flag = "Condition:Phasing", actor = "player" },
	["buffTailwind"] = { flag = "Condition:Tailwind", actor = "player" },
	["buffUnholyMight"] = { flag = "Condition:UnholyMight", actor = "player" },
	["conditionAttackedRecently"] = { flag = "Condition:AttackedRecently", actor = "player" },
	["conditionBlinded"] = { flag = "Condition:Blinded", actor = "player" },
	["conditionBurning"] = { flag = "Condition:Burning", actor = "player" },
	["conditionCastSpellRecently"] = { flag = "Condition:CastSpellRecently", actor = "player" },
	["conditionChannelling"] = { flag = "Condition:Channelling", actor = "player" },
	["conditionChilled"] = { flag = "Condition:Chilled", actor = "player" },
	["conditionEnemyBlinded"] = { flag = "Condition:Blinded", actor = "enemy" },
	["conditionEnemyBurning"] = { flag = "Condition:Burning", actor = "enemy" },
	["conditionEnemyChilled"] = { flag = "Condition:Chilled", actor = "enemy" },
	["conditionEnemyCrushed"] = { flag = "Condition:Crushed", actor = "enemy" },
	["conditionEnemyCursed"] = { flag = "Condition:Cursed", actor = "enemy" },
	["conditionEnemyFullLife"] = { flag = "Condition:FullLife", actor = "enemy" },
	["conditionEnemyHindered"] = { flag = "Condition:Hindered", actor = "enemy" },
	["conditionEnemyIntimidated"] = { flag = "Condition:Intimidated", actor = "enemy" },
	["conditionEnemyLowLife"] = { flag = "Condition:LowLife", actor = "enemy" },
	["conditionEnemyMaimed"] = { flag = "Condition:Maimed", actor = "enemy" },
	["conditionEnemyMoving"] = { flag = "Condition:Moving", actor = "enemy" },
	["conditionEnemyPoisoned"] = { flag = "Condition:Poisoned", actor = "enemy" },
	["conditionEnemyScorched"] = { flag = "Condition:Scorched", actor = "enemy" },
	["conditionEnemyShocked"] = { flag = "Condition:Shocked", actor = "enemy" },
	["conditionFullLife"] = { flag = "Condition:FullLife", actor = "player" },
	["conditionHaveTotem"] = { flag = "Condition:HaveTotem", actor = "player" },
	["conditionHitRecently"] = { flag = "Condition:HitRecently", actor = "player" },
	["conditionHitSpellRecently"] = { flag = "Condition:HitSpellRecently", actor = "player" },
	["conditionLeeching"] = { flag = "Condition:Leeching", actor = "player" },
	["conditionLeechingEnergyShield"] = { flag = "Condition:LeechingEnergyShield", actor = "player" },
	["conditionLeechingLife"] = { flag = "Condition:LeechingLife", actor = "player" },
	["conditionLowLife"] = { flag = "Condition:LowLife", actor = "player" },
	["conditionMoving"] = { flag = "Condition:Moving", actor = "player" },
	["conditionNonPoisonedOnly"] = { flag = "Condition:NonPoisonedOnly", actor = "player" },
	["conditionPoisoned"] = { flag = "Condition:Poisoned", actor = "player" },
	["conditionScorched"] = { flag = "Condition:Scorched", actor = "player" },
	["conditionShocked"] = { flag = "Condition:Shocked", actor = "player" },
	["conditionSingleBleed"] = { flag = "Condition:SingleBleed", actor = "player" },
	["conditionSummonedTotemRecently"] = { flag = "Condition:SummonedTotemRecently", actor = "player" },
	["conditionTotemsHitRecently"] = { flag = "Condition:TotemsHitRecently", actor = "player" },
	["conditionUnbrokenWard"] = { flag = "Condition:UnbrokenWard", actor = "player" },
	["conditionUsedMinionSkillRecently"] = { flag = "Condition:UsedMinionSkillRecently", actor = "player" },
	["conditionUsedMovementSkillRecently"] = { flag = "Condition:UsedMovementSkillRecently", actor = "player" },
	["conditionUsedVaalSkillRecently"] = { flag = "Condition:UsedVaalSkillRecently", actor = "player" },
	["conditionUsingFlask"] = { flag = "Condition:UsingFlask", actor = "player" },
	["enemyConditionHitByColdDamage"] = { flag = "Condition:HitByColdDamage", actor = "enemy" },
	["enemyConditionHitByFireDamage"] = { flag = "Condition:HitByFireDamage", actor = "enemy" },
	["enemyConditionHitByLightningDamage"] = { flag = "Condition:HitByLightningDamage", actor = "enemy" },
	["minionBuffOnslaught"] = { flag = "Condition:Onslaught", actor = "minion" },
	["minionbuffChaoticMight"] = { flag = "Condition:ChaoticMight", actor = "minion" },
	["minionbuffUnholyMight"] = { flag = "Condition:UnholyMight", actor = "minion" },
	["minionsConditionFullLife"] = { flag = "Condition:FullLife", actor = "minion" },
	["minionsConditionLeechingEnergyShield"] = { flag = "Condition:LeechingEnergyShield", actor = "minion" },
	["minionsConditionLowLife"] = { flag = "Condition:LowLife", actor = "minion" },
}

return M
