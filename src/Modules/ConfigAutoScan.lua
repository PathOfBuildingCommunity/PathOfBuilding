-- Path of Building
--
-- Source-based configuration scan for Auto-configure. Detect runs the rule
-- families over a neutral calculation (a manually enabled buff cannot prove its
-- own source), the selection state previews and applies proposals, BuildSetup
-- produces the one-click config set and the setting checks back the
-- Configuration markers. Depends on ConfigAutoModel, ConfigAutoRulesBuild,
-- ConfigAutoRulesCombat, ConfigAutoInventory, ConfigOptions and ConfigVisibility.
-- The popups live in ConfigAutoUI, which requires this module.
local t_insert = table.insert
local t_remove = table.remove
local t_concat = table.concat
local m_min = math.min
local m_max = math.max

local M = { }

local options = require("Modules.ConfigOptions")
local visibility = require("Modules.ConfigVisibility")
local support = require("Modules.ConfigAutoInventory").Support
local advanced = require("Modules.ConfigAutoRulesBuild").Advanced
local policy = require("Modules.ConfigAutoModel").Policy
local preferences = require("Modules.ConfigAutoModel").Preferences
local plainText = require("Modules.ConfigAutoModel").Text
local guided = require("Modules.ConfigAutoRulesBuild").Guided
local events = require("Modules.ConfigAutoRulesCombat").Events
local mechanics = require("Modules.ConfigAutoRulesCombat").Mechanics
local timeline = require("Modules.ConfigAutoRulesCombat").Timeline
local ground = require("Modules.ConfigAutoRulesBuild").Ground
local buildup = require("Modules.ConfigAutoRulesCombat").Buildup
local minions = require("Modules.ConfigAutoRulesBuild").Minions
local windows = require("Modules.ConfigAutoRulesCombat").Windows
local batch = require("Modules.ConfigAutoRulesBuild").Batch
local history = require("Modules.ConfigAutoRulesCombat").History
local stacks = require("Modules.ConfigAutoRulesCombat").Stacks
local resources = require("Modules.ConfigAutoRulesCombat").Resources
local choices = require("Modules.ConfigAutoRulesBuild").Choices
local position = require("Modules.ConfigAutoRulesBuild").Position
local shrines = require("Modules.ConfigAutoRulesBuild").Shrines
local model = require("Modules.ConfigAutoModel")
local profiles = require("Modules.ConfigAutoModel").Profiles
local quests = require("Modules.ConfigAutoRulesBuild").Quests
local stuns = require("Modules.ConfigAutoRulesCombat").Stuns
local uncertain = require("Modules.ConfigAutoModel").Uncertain
local optionsByName, sectionsByName = model.optionsByName, model.sectionsByName

-- Structural settings change what is calculated (skill choices, profiles,
-- quest facts) rather than describing a combat state; Preview re-runs the
-- scan with the selected structural values staged.
local structural = { }; for var in pairs(choices.structural) do structural[var] = true end
shrines.RegisterStructural(structural)
for var in pairs(profiles.structural) do structural[var] = true end
for var in pairs(quests.structural) do structural[var] = true end
for var in pairs(uncertain.limited) do structural[var] = true end
-- Sentinel proposal value: clear the input so PoB's native default applies.
local DEFAULT = { }
-- Scan state keyed by the suggestions table; setting checks keyed by config set.
local scans = setmetatable({ }, { __mode = "k" })
local settingChecks = setmetatable({ }, { __mode = "k" })

local function isValidChoice(choices, value)
	for _, choice in ipairs(choices or { }) do if choice.val == value then return true end end
	return false
end
local function enabledDependency(value)
	return value ~= nil and value ~= false and (type(value) ~= "number" or value > 0)
		and value ~= "NONE" and value ~= "None"
end

-- ============================================================================
-- Isolation helpers
-- ============================================================================
-- Scan calculations must leave the real tab untouched. ConfigOptions apply
-- functions push boss placeholders through the tab's controls (no undo), and
-- CALCULATOR results are cached globally where mirages, tree and item
-- comparisons would later reuse the neutral-config numbers.
local isolationDepth = 0
-- The stepped scan being resumed (see M.StartDetect)
local stepping
local function withIsolatedCalc(fn, ...)
	if isolationDepth > 0 then return fn(...) end
	local isolation = { cache = GlobalCache and GlobalCache.cachedData, own = { } }
	if stepping and coroutine.running() == stepping.thread then stepping.isolation = isolation end
	isolation.saved = isolation.cache and isolation.cache.CALCULATOR
	if isolation.cache then isolation.cache.CALCULATOR = isolation.own end
	isolationDepth = 1
	local results = { pcall(fn, ...) }
	isolationDepth = 0
	if isolation.cache then isolation.cache.CALCULATOR = isolation.saved end
	if not results[1] then error(results[2], 0) end
	return unpack(results, 2)
end
-- A point between two scan stages or probe calculations. A stepped scan that has
-- used its frame budget yields here, with the real CALCULATOR cache back in place
-- for the build's own calculations until it resumes. Nothing else is swapped at
-- these points: scan environments are proxies over the build, and their changes
-- stay on the proxies. A probe can be requested from inside a C callback such as
-- a sort comparator, which cannot yield, so `nested` points check first.
local function pause(nested)
	local scan = stepping
	-- A probe is one whole calculation, often longer than the budget, so it starts a
	-- new frame unless the current one has barely begun
	local budget = scan and (nested and scan.budget / 4 or scan.budget)
	if not scan or isolationDepth ~= 1 or coroutine.running() ~= scan.thread or GetTime() - scan.sliceStart < budget then return end
	if nested and not (coroutine.isyieldable and coroutine.isyieldable()) then return end
	local isolation = scan.isolation
	if isolation.cache then isolation.cache.CALCULATOR = isolation.saved end
	isolationDepth = 0
	coroutine.yield()
	isolation.cache = GlobalCache and GlobalCache.cachedData
	isolation.saved = isolation.cache and isolation.cache.CALCULATOR
	if isolation.cache then isolation.cache.CALCULATOR = isolation.own end
	isolationDepth = 1
end
local function silentControls(configTab)
	local stubs = { }
	return setmetatable({ }, { __index = function(_, var)
		if not stubs[var] then
			local control = configTab.varControls and configTab.varControls[var]
			-- Reads (placeholder, list, selIndex) see the real control; writes
			-- and placeholder/selection changes are absorbed.
			stubs[var] = setmetatable({ SetPlaceholder = function() end, SelByValue = function() end, SetSel = function() end },
				{ __index = control, __newindex = function() end })
		end
		return stubs[var]
	end })
end
-- Build a neutral CALCULATOR environment: in-scope combat checkboxes, manual
-- exposure choices and rule-owned inputs are removed; `planned` stages
-- structural values for a combined preview.
local function detectionEnv(build, planned)
	local config = setmetatable({ }, { __index = build.configTab })
	config.input = copyTable(build.configTab.input)
	config.placeholder = copyTable(build.configTab.placeholder)
	for _, option in ipairs(options) do
		-- Self-only curse selection changes where a spell is applied; it is a
		-- structural skill choice, not a combat condition to neutralise.
		if option.type == "check" and support.IsInScope(option.var) and not structural[option.var] then
			config.input[option.var] = nil
			config.placeholder[option.var] = nil
		end
	end
	-- These manual exposure choices must not become evidence for themselves.
	config.input.waveOfConvictionExposureType = nil
	config.input.elementalArmyExposureType = nil
	for var in pairs(support.defaults) do
		config.input[var], config.placeholder[var] = nil, nil
	end
	for _, rules in ipairs({ advanced, events, mechanics, timeline, ground, buildup, minions, windows }) do
		for var in pairs(rules.neutralInputs) do config.input[var], config.placeholder[var] = nil, nil end
	end
	for _, rules in ipairs({ batch, history, stacks, resources, choices, position, shrines }) do rules.Neutralize(config) end
	for var, value in pairs(planned or { }) do
		local option, valid = optionsByName[var], false
		if structural[var] and option then
			if option.type == "check" then
				valid = type(value) == "boolean"
			elseif option.type == "list" then
				valid = isValidChoice(option.list, value)
			else
				valid = value == DEFAULT and profiles.defaultVars[var]
					or type(value) == "number" and value >= 0 and value < math.huge and value == math.floor(value)
			end
			if valid then
				if value == DEFAULT then config.input[var] = nil else config.input[var] = value end
				config.placeholder[var] = nil
			end
		end
	end
	for _, color in ipairs({ "Red", "Green", "Blue", "White" }) do
		config.input["overrideEmpty" .. color .. "Sockets"] = nil
	end
	config.configSets = { [config.activeConfigSetId] = {
		input = config.input, placeholder = config.placeholder,
		customModsList = build.configTab.configSets[config.activeConfigSetId].customModsList,
	} }
	local snapshot = setmetatable({ configTab = config }, { __index = build })
	config.build = snapshot
	-- Boss presets write placeholders through the tab's controls; keep that
	-- side effect away from the real configuration set.
	config.varControls = silentControls(build.configTab)
	config:BuildModList()
	local calcs = build.calcsTab.calcs
	local env = calcs.initEnv(snapshot, "CALCULATOR")
	calcs.perform(env)
	-- Usage tables are collected by buildOutput for MAIN, not by perform for
	-- CALCULATOR. Reuse that structural metadata with the neutral actors.
	local relevanceEnv = setmetatable({ player = env.player, enemy = env.enemy }, { __index = build.calcsTab.mainEnv })
	snapshot.calcsTab = setmetatable({ mainEnv = relevanceEnv }, { __index = build.calcsTab })
	return env, snapshot
end
local function registerMainOutput(ctx, probe)
	local skill = probe.player.mainSkill
	if events.CanActivate(skill) then
		ctx.mainOutputs[probe.player.output] = (skill.minion or skill.skillFlags.totem) and "use" or "hit"
	end
end
-- Neutral environment with structural overrides staged on top of the scan's
-- plan; one probe per distinct override signature.
local function probeConfig(ctx, overrides)
	local keys = { }; for var in pairs(overrides) do t_insert(keys, var) end; table.sort(keys)
	local signature, changes = { }, false
	local projected = copyTable(ctx.planned or { })
	for _, var in ipairs(keys) do
		-- detectionEnv silently ignores non-structural overrides; a probe
		-- on such a variable would report the unchanged environment.
		assert(structural[var], "probeConfig: " .. tostring(var) .. " is not a structural setting")
		projected[var] = overrides[var]
		changes = changes or ctx.snapshot.configTab.input[var] ~= overrides[var]
		t_insert(signature, var .. "=" .. tostring(overrides[var]))
	end
	if not changes then return ctx.env end
	local key = t_concat(signature, "|")
	if not ctx.configProbes[key] then
		pause(true)
		local probe = detectionEnv(ctx.originalBuild, projected)
		registerMainOutput(ctx, probe)
		ctx.configProbes[key] = probe
	end
	return ctx.configProbes[key]
end
-- Neutral environment calculated with `skill` as the main skill; nil when the
-- skill cannot be selected. One probe per skill.
local function probeSkill(ctx, skill)
	if ctx.skillProbes[skill] ~= nil then return ctx.skillProbes[skill] or nil end
	pause(true)
	local probeBuild = setmetatable({ }, { __index = ctx.snapshot })
	for index, group in ipairs(ctx.originalBuild.skillsTab.socketGroupList) do
		if group == skill.socketGroup then probeBuild.mainSocketGroup = index break end
	end
	local calcs = ctx.originalBuild.calcsTab.calcs
	local probe = calcs.initEnv(probeBuild, "CALCULATOR")
	for _, candidate in ipairs(probe.player.activeSkillList) do
		if candidate.activeEffect.srcInstance == skill.activeEffect.srcInstance
			and candidate.activeEffect.grantedEffect.id == skill.activeEffect.grantedEffect.id then
			probe.player.mainSkill = candidate
			calcs.perform(probe)
			ctx.skillProbes[skill] = probe
			return probe
		end
	end
	ctx.skillProbes[skill] = false
end

-- ============================================================================
-- Source stamps: what a scan was based on, for staleness checks
-- ============================================================================
local function sourceStamp(build, baseId)
	local config, groups = build.configTab, { }
	local base = config.configSets[baseId or config.activeConfigSetId]
	for _, group in ipairs(build.skillsTab.socketGroupList) do
		local raw = { enabled = group.enabled ~= false, slot = group.slot, count = group.groupCount or 1,
			main = group.mainActiveSkill or 1, part = group.skillPart, include = group.includeInFullDPS == true, gems = { } }
		for _, gem in ipairs(group.gemList) do
			t_insert(raw.gems, { name = gem.nameSpec, id = gem.gemId, skill = gem.skillId, level = gem.level, quality = gem.quality,
				enabled = gem.enabled ~= false, count = gem.count or 1, global1 = gem.enableGlobal1 ~= false, global2 = gem.enableGlobal2 ~= false })
		end
		t_insert(groups, raw)
	end
	local refs = { specObject = build.spec }
	for _, key in ipairs({ "configTab", "skillsTab", "itemsTab", "partyTab", "spec" }) do
		local object = build[key]; refs[key] = object and object.undo and object.undo[1]
	end
	local equipment
	if baseId then
		refs.configTab = nil
		equipment = { }
		for slot, control in pairs(build.itemsTab.slots) do
			equipment[slot] = { id = control.selItemId, active = control.active }
		end
	end
	return { refs = refs, values = {
		input = copyTable(base.input), placeholder = copyTable(base.placeholder),
		custom = copyTable(base.customModsList or { }), equipment = equipment,
		groups = groups, spectres = copyTable(build.spectreList or { }), quests = copyTable(build.autoConfigureQuestEvidence or { }),
		level = build.characterLevel, main = build.mainSocketGroup, config = base.id,
		skills = build.skillsTab.activeSkillSetId, items = build.itemsTab.activeItemSetId,
	} }
end
function M.SetupSource(build, baseId, settings)
	local stamp = sourceStamp(build, baseId)
	local modelSettings = copyTable(settings)
	modelSettings.showDetails = false
	stamp.values.settings = preferences.Key(modelSettings)
	return stamp
end
local function sameValues(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in pairs(a) do if not sameValues(value, b[key]) then return false end end
	for key in pairs(b) do if a[key] == nil then return false end end
	return true
end
function M.SameSetupValues(a, b)
	return sameValues(a.input, b.input) and sameValues(a.placeholder, b.placeholder) and sameValues(a.customModsList, b.customModsList)
end
function M.SameSetupSource(a, b)
	if not a or not b or not sameValues(a.values, b.values) then return false end
	for key, value in pairs(a.refs) do if b.refs[key] ~= value then return false end end
	for key, value in pairs(b.refs) do if a.refs[key] ~= value then return false end end
	return true
end
local function scanIsCurrent(state, force)
	if not state then return true end
	local revision = state.build.outputRevision
	if not force then
		if state.outputRevision == revision then return true end
		-- The popup asks every frame; rebuild the source stamp once per output revision.
		if state.checkedRevision == revision then return state.checkedCurrent end
	end
	local current = M.SameSetupSource(state.source, sourceStamp(state.build))
	state.checkedRevision, state.checkedCurrent = revision, current
	-- Drawing/native placeholder refresh may rebuild outputs without changing
	-- the character. That is not a stale scan and must not disable Apply.
	if current then state.outputRevision = revision end
	return current
end
-- Scan state for a suggestions table and whether it still matches the build,
-- for the ConfigAutoUI popups.
function M.ScanState(suggestions) return scans[suggestions] end
function M.ScanIsCurrent(state) return scanIsCurrent(state) end

-- ============================================================================
-- Detect: staged scan over one shared context table
-- ============================================================================
-- The context (`ctx`) is shared by every stage and every rule registry. Rule
-- modules read: build (the isolated snapshot), originalBuild, env, mapping,
-- seconds, suggest, mainSkill, selfHit, probeSkill, probeConfig, lines, found,
-- options, defaultValue and facts.

-- These conditions are already derived by PoB from equipment, reservation and
-- the main skill. They are reported and marked, not written as checkboxes.
local derivedConditions = {
	conditionLowLife = "LowLife", conditionFullLife = "FullLife",
	conditionLowMana = "LowMana", conditionLowEnergyShield = "LowEnergyShield",
	conditionUnbrokenWard = "UnbrokenWard", conditionUsingFlask = "UsingFlask",
	conditionUsingTincture = "UsingTincture", conditionHaveTotem = "HaveTotem",
	conditionSummonedTotemRecently = "SummonedTotemRecently",
	conditionHitRecently = "HitRecently", conditionChannelling = "Channelling",
	conditionHitSpellRecently = "HitSpellRecently",
	conditionAttackedRecently = "AttackedRecently", conditionCastSpellRecently = "CastSpellRecently",
	conditionUsedMovementSkillRecently = "UsedMovementSkillRecently",
	conditionUsedMinionSkillRecently = "UsedMinionSkillRecently",
	conditionUsedVaalSkillRecently = "UsedVaalSkillRecently",
	conditionLeeching = "Leeching", conditionLeechingLife = "LeechingLife",
	conditionLeechingMana = "LeechingMana", conditionLeechingEnergyShield = "LeechingEnergyShield",
	buffOnslaught = "Onslaught", buffArcaneSurge = "ArcaneSurge",
	buffUnholyMight = "UnholyMight", buffChaoticMight = "ChaoticMight",
	buffPhasing = "Phasing", buffFortification = "Fortified",
	buffTailwind = "Tailwind", buffAdrenaline = "Adrenaline", buffElusive = "Elusive",
}
local enemyConditions = {
	conditionEnemyBleeding = "Bleeding", conditionEnemyPoisoned = "Poisoned",
	conditionEnemyIgnited = "Ignited", conditionEnemyChilled = "Chilled",
	conditionEnemyBlinded = "Blinded", conditionEnemyTaunted = "Taunted",
	conditionEnemyShocked = "Shocked",
}
local derivedEnemyConditions = {
	conditionEnemyCursed = "Cursed", conditionEnemyBurning = "Burning",
	conditionEnemyMaimed = "Maimed", conditionEnemyHindered = "Hindered",
	conditionEnemyIntimidated = "Intimidated", conditionEnemyCrushed = "Crushed", conditionEnemyUnnerved = "Unnerved",
}
local resourceBuffs = {
	SupportArcaneSurge = {
		var = "buffArcaneSurge", resource = "Mana", name = "Arcane Surge",
		threshold = "support_arcane_surge_gain_buff_on_mana_use_threshold",
		duration = "support_arcane_surge_base_duration_ms",
	},
	SupportLifetap = {
		var = "buffLifetap", resource = "Life", name = "Lifetap",
		threshold = "support_lifetap_spent_life_threshold",
		duration = "support_base_lifetap_buff_duration",
	},
}

local function playerUsesSkill(skill)
	return model.SkillEnabled(skill) and not skill.skillFlags.totem
		and not skill.skillFlags.trap and not skill.skillFlags.mine
		and not skill.minion
end
-- Modifier text from equipped items and allocated passives, in source order.
local function sourceLines(env)
	local lines = { }
	for slot, item in pairs(env.player.itemList) do
		-- Flask activation is an Items-tab choice; do not infer permanent uptime.
		local shieldForMinions = item.type == "Shield" and env.allocNodes[45175] and env.allocNodes[45175].dn == "Necromantic Aegis"
		if not item.flaskData and not item.tinctureData and not shieldForMinions then
			for _, field in ipairs({ "explicitModLines", "implicitModLines", "enchantModLines", "scourgeModLines", "crucibleModLines" }) do
				for _, line in ipairs(item[field] or { }) do
					if not line.disabled and item:CheckModLineVariant(line) then
						t_insert(lines, { text = itemLib.applyRange(line.line, line.range or 1, line.valueScalar, line.corruptedRange),
							source = slot .. ": " .. item.name, order = #lines + 1 })
					end
				end
			end
		end
	end
	for _, node in pairs(env.allocNodes) do
		-- Conversion ("Other") radius jewels rewrite the stats of nodes in
		-- range, so their text no longer describes the node. Attribute-tally,
		-- threshold and self jewels leave the node's own stats intact.
		local changed = node.isTattoo
		for _, radius in ipairs(env.radiusJewelList or { }) do
			if radius.type == "Other" and radius.nodes and radius.nodes[node.id] then changed = true end
		end
		if not changed and node.type ~= "Mastery" then
			for _, text in ipairs(node.sd or { }) do
				t_insert(lines, { text = text, source = "Passive: " .. node.dn, order = #lines + 1 })
			end
		end
	end
	-- Preserve native line order within a source: passive descriptions can wrap
	-- a single rule across several sd entries.
	table.sort(lines, function(a, b) return a.source == b.source and a.order < b.order or a.source < b.source end)
	return lines
end
-- Explain independently calculated conditions using their granting sources.
local function conditionReason(actor, condition, build)
	local sources = { }
	for _, entry in ipairs(actor.modDB:Tabulate("FLAG", nil, "Condition:" .. condition)) do
		local source = entry.mod.source or "Build"
		local itemId = source:match("^Item:(%d+):")
		local nodeId = source:match("^Tree:(%d+)")
		if itemId and build.itemsTab.items[tonumber(itemId)] then
			source = build.itemsTab.items[tonumber(itemId)].name
		elseif nodeId and build.spec.nodes[tonumber(nodeId)] then
			source = "Passive: " .. build.spec.nodes[tonumber(nodeId)].dn
		end
		sources[source] = true
	end
	local names = { }
	for source in pairs(sources) do t_insert(names, source) end
	table.sort(names)
	return #names > 0 and ("\nSource: " .. t_concat(names, ", ")) or ""
end
local function exposureType(actorOutput)
	local highest, damage, tied = nil, 0, false
	for _, element in ipairs({ "Fire", "Cold", "Lightning" }) do
		local key = element .. "HitAverage"
		local value = actorOutput[key]
		if value == nil then
			-- Attack actors keep damage by hand; spell actors expose it on
			-- the global output. Include both hands for the inferred average.
			value = ((actorOutput.MainHand or { })[key] or 0) + ((actorOutput.OffHand or { })[key] or 0)
		end
		if value > damage then highest, damage, tied = element, value, false
		elseif value > 0 and math.abs(value - damage) < 0.001 then tied = true end
	end
	return not tied and highest or nil
end
local function singleExposureElement(out, element)
	-- An average winner can change from hit to hit. A single element in
	-- both native damage rolls is stable even if the target's resists vary.
	for _, other in ipairs({ "Fire", "Cold", "Lightning" }) do
		if other ~= element and ((out[other .. "HitAverage"] or 0) > 0
			or (out.CritChance or 0) > 0 and (out[other .. "CritAverage"] or 0) > 0) then
			return false
		end
	end
	return true
end
-- Refresh assumption for Wave of Conviction's Exposure: direct casts of the
-- main skill, or an Arcanist Brand trigger (second result true).
local function waveApplication(ctx, skill, probe, element)
	local wave, out = probe.player.mainSkill, probe.player.output
	local duration = out.DurationSecondary or 0
	local manaCost, manaPool = out.ManaCost or 0, out.ManaUnreserved or 0
	local window = m_min(duration, ctx.seconds)
	if not singleExposureElement(out, element) or duration <= 0
		or probe.player.modDB:Flag(nil, "ElementalEquilibrium")
		or not model.HasGeneratingHit(out) or manaCost > manaPool
		or manaCost > 0 and probe.player.modDB:Flag(nil, "EnergyShieldProtectsMana")
		or (out.ManaPerSecondCost or 0) * window > manaPool + m_max(0, out.ManaRegen or 0) * window then return end
	if skill == ctx.mainSkill and events.IsDirect(skill) then
		return policy.Refresh(ctx.settings, policy.HitRate(ctx, out), duration, ctx.seconds)
	end
	local link = wave.triggeredBy
	local brand = wave.skillData.triggeredByBrand and link and link.grantedEffect and link.grantedEffect.id == "SupportBrandSupport" and link.mainSkill
	if brand and brand.activeEffect.grantedEffect.id == "BrandSupport" and events.IsDirect(brand) then
		local accuracy = m_max(0, m_min(100, out.HitChance or 100)) / 100
		local singleBrandRate = (out.SkillTriggerRate or 0) / m_max(1, link.attachedBrandCount or 1)
		local assumption = policy.Refresh(ctx.settings, singleBrandRate * accuracy, duration, ctx.seconds)
		return assumption, true
	end
end

-- Table-form proposal. Filters out-of-scope and ineligible settings, attaches
-- recent-activity assumptions and resolves dependency eligibility. Returns the
-- accepted entry, or nil when the proposal was filtered out. A later non-review
-- proposal replaces an earlier review one for the same setting. A parent PoB
-- derives itself satisfies `requires` and ifOption without a checkbox.
local function proposeEntry(ctx, spec)
	local var, reason, label, value, requires, assumption, choices, activation =
		spec.var, spec.reason, spec.label, spec.value, spec.requires, spec.assumption, spec.choices, spec.activation
	local review = not not spec.review
	local option = optionsByName[var]
	if not option or not support.IsInScope(var) then return end
	local env, found, build = ctx.env, ctx.found, ctx.originalBuild
	if var == "conditionChannelling" and ctx.activity < 1 then
		if ctx.activity == 0 then return end
		review = true
		assumption = policy.Scenario("Confirm that the selected damage window is while you are channelling.")
	end
	if not assumption and policy.IsRecent(var, option.label) then
		assumption = policy.Scenario("Estimated from your enabled skills, not measured in combat.")
	end
	if assumption then reason = reason .. "\n" .. assumption.description end
	if assumption and ctx.settings.askAllAssumptions then review = true end
	if not requires and type(option.ifOption) == "string" then requires = { option.ifOption } end
	local eligibility = option
	if activation and activation.nativeFlag and env.player.modDB:Flag(nil, activation.nativeFlag) then
		eligibility = copyTable(eligibility, true)
		eligibility.ifFlag = nil
	end
	if activation and activation.parent and activation.conditions and option.ifFlag and type(option.ifFlag) == "string" then
		local parent = found[activation.parent]
		if (parent and parent.value == true or build.configTab.input[activation.parent] == true)
			and env.player.mainSkill.skillModList:Flag({ skillCond = activation.conditions }, option.ifFlag) then
			eligibility = copyTable(eligibility, true)
			eligibility.ifFlag = nil
			requires = copyTable(requires or { })
			local present = false
			for _, parentVar in ipairs(requires) do if parentVar == activation.parent then present = true end end
			if not present then t_insert(requires, activation.parent) end
		end
	end
	if option.ifOption then
		local parents = type(option.ifOption) == "table" and option.ifOption or { option.ifOption }
		for _, parent in ipairs(parents) do
			if found[parent] and enabledDependency(found[parent].value) or enabledDependency(build.configTab.input[parent])
				or not found[parent] and ctx.derived[parent] then
				eligibility = copyTable(eligibility, true)
				eligibility.ifOption = nil
				break
			end
		end
	end
	-- A coupled correction must be able to clear an old checked condition
	-- even when its conditional benefit is no longer used by this build.
	if value == false and build.configTab.input[var] == true and assumption and assumption.applyTogether then
		eligibility = copyTable(eligibility, true)
		eligibility.ifCond = nil
	end
	local useDefault = value == DEFAULT
	-- Clearing an override can be relevant on the live build when its parent
	-- condition is off in the neutral snapshot, as with manual Fortification.
	if not visibility.isRelevantForBuild(eligibility, ctx.snapshot)
		and not (useDefault and visibility.isRelevantForBuild(eligibility, build)) then return end
	local existing = found[var]
	if existing and (not existing.review or review) then return end
	local current = build.configTab.input[var]
	if value == nil then value = true end
	if useDefault then value = nil end
	local selected = not review
	if requires then
		local kept = { }
		for _, parent in ipairs(requires) do
			if found[parent] or not ctx.derived[parent] then t_insert(kept, parent) end
		end
		requires = kept[1] and kept or nil
	end
	for _, parent in ipairs(requires or { }) do
		local proposal = found[parent]
		local parentValue = build.configTab.input[parent]
		if proposal and proposal.selected then parentValue = proposal.value end
		if not enabledDependency(parentValue) then selected = false end
	end
	found[var] = {
		var = var, label = label or StripEscapes(option.label), value = value, useDefault = useDefault,
		section = sectionsByName[var],
		reason = reason, review = review or false, current = current,
		-- A supported setting is ready to apply, including a currently off
		-- checkbox. Only gameplay questions need an answer from the user.
		selected = selected, requires = requires, assumption = assumption, choices = choices,
	}
	return found[var]
end
-- Recent-activity proposal from a per-second rate over the fight window.
local function proposeRecent(ctx, var, rate, reason, label)
	if rate <= 0 then return end
	local assumption = policy.Rate(ctx.settings, rate, m_min(ctx.seconds, policy.recentWindow))
	ctx.propose({ var = var, reason = reason, review = not assumption.automatic, label = label, assumption = assumption })
end

-- Stage 1: neutral environment, main-skill facts and the proposal helpers.
local function newScanContext(build, mapping, seconds, planned, settings)
	seconds = tonumber(seconds) or 4
	if seconds ~= seconds or seconds == math.huge or seconds == -math.huge then seconds = 4 end
	seconds = m_max(1, m_min(300, seconds))
	local env, snapshot = detectionEnv(build, planned)
	local mainSkill = env.player.mainSkill
	local ctx = {
		build = snapshot, snapshot = snapshot, originalBuild = build, env = env, mapping = mapping,
		seconds = seconds, planned = planned, settings = settings, options = optionsByName, defaultValue = DEFAULT,
		mainSkill = mainSkill, output = env.player.output,
		killActor = policy.MainKillActor(env), mainOutputs = { },
		-- found: proposals by var. derived: states PoB already derives from the
		-- build; they are reported and marked, never written, since a manual
		-- checkbox would keep forcing the condition after its source is removed.
		found = { }, derived = { },
		skillProbes = { [mainSkill] = env }, configProbes = { },
	}
	registerMainOutput(ctx, env)
	ctx.activity = policy.Activity(ctx, env.player.output)
	ctx.hitRate = policy.HitRate(ctx, env.player.output)
	ctx.selfHit = mainSkill.skillFlags.hit and playerUsesSkill(mainSkill) and ctx.activity > 0
	ctx.lines = sourceLines(env)
	function ctx.propose(spec) return proposeEntry(ctx, spec) end
	-- Rule modules keep the positional form; in-file callers use propose().
	function ctx.suggest(var, reason, review, label, value, requires, assumption, choices, activation)
		return ctx.propose({ var = var, reason = reason, review = review, label = label, value = value,
			requires = requires, assumption = assumption, choices = choices, activation = activation })
	end
	function ctx.probeSkill(skill) return probeSkill(ctx, skill) end
	function ctx.probeConfig(overrides) return probeConfig(ctx, overrides) end
	ctx.facts = model.Facts(ctx)
	return ctx
end

-- Stage 2: states PoB derives itself on the player, minion and enemy actors.
local function collectDerivedStates(ctx)
	local env, build = ctx.env, ctx.originalBuild
	local function noteDerived(var, reason)
		if optionsByName[var] and support.IsInScope(var) and not ctx.derived[var] then ctx.derived[var] = reason end
	end
	for var, condition in pairs(derivedConditions) do
		if not policy.rateControlled[var] and not shrines.controlled[var] and env.player.modDB:GetCondition(condition) then
			noteDerived(var, "PoB derives " .. condition .. " from your build."
				.. conditionReason(env.player, condition, build))
		end
	end
	for var, condition in pairs(derivedEnemyConditions) do
		-- Tombfist's Maim applies in the context of the hitting main attack.
		local skillCfg = var == "conditionEnemyMaimed" and ctx.selfHit and ctx.hitRate > 0 and ctx.mainSkill.skillCfg or nil
		if env.enemy.modDB:GetCondition(condition, skillCfg) then
			noteDerived(var, "PoB calculates " .. condition .. " on the enemy from your build."
				.. conditionReason(env.enemy, condition, build))
		end
	end
	-- A later rule can still propose the checkbox when it adds something PoB
	-- does not derive (a stronger ailment from hits, a travel skill's uptime).
	for var, condition in pairs(enemyConditions) do
		if env.enemy.modDB:GetCondition(condition) then
			noteDerived(var, "PoB derives the enemy's " .. condition .. " state from your build."
				.. conditionReason(env.enemy, condition, build))
		end
	end
	-- These two flags describe how the selected skill applies ailments.
	local skillModList = ctx.mainSkill.skillModList
	if skillModList:Flag(ctx.mainSkill.skillCfg, "Condition:SingleBleed") then
		noteDerived("conditionSingleBleed", "PoB derives this from your main skill.")
	end
	if skillModList:Flag(ctx.mainSkill.skillCfg, "Condition:NonPoisonedOnly") then
		noteDerived("conditionNonPoisonedOnly", "PoB derives this from your main skill.")
	end
	-- Generated source links cover independently provided states on all three
	-- actor types. A benefit from a condition does not make this check pass.
	for var, rule in pairs(support.conditions) do
		local actor = env[rule.actor]
		local condition = rule.flag:match("^Condition:(.+)$")
		if not derivedEnemyConditions[var] and not policy.rateControlled[var] and not shrines.controlled[var]
			and actor and condition and actor.modDB:GetCondition(condition) then
			local reason = "PoB derives " .. condition .. " for the " .. rule.actor .. "."
				.. conditionReason(actor, condition, build)
			noteDerived(var, reason .. (rule.actor == "minion" and "\nChecked for the selected minion only." or ""))
		end
	end
end

local function proposeSecondaryHits(ctx)
	local needHit = not ctx.found.conditionHitRecently and not ctx.env.player.modDB:GetCondition("HitRecently")
		and visibility.isRelevantForBuild(optionsByName.conditionHitRecently, ctx.snapshot)
	local needSpell = not ctx.found.conditionHitSpellRecently and not ctx.env.player.modDB:GetCondition("HitSpellRecently")
		and visibility.isRelevantForBuild(optionsByName.conditionHitSpellRecently, ctx.snapshot)
	if not (needHit or needSpell) then return end
	for _, skill in ipairs(ctx.env.player.activeSkillList) do
		if skill ~= ctx.mainSkill and skill.skillFlags.hit and (needHit or skill.skillFlags.spell)
			and playerUsesSkill(skill) and events.IsDirect(skill) then
			local probe = ctx.probeSkill(skill)
			if probe and model.HasGeneratingHit(probe.player.output) then
				local name = skill.activeEffect.grantedEffect.name
				local label = "Do you land a hit with " .. name .. " during this window?"
				local reason = "Enabled skill: " .. name .. ". Confirm you hit with it recently."
				if needHit then
					needHit = not ctx.propose({ var = "conditionHitRecently", label = label, reason = reason, review = true })
				end
				if needSpell and skill.skillFlags.spell then
					needSpell = not ctx.propose({ var = "conditionHitSpellRecently", label = label, reason = reason, review = true })
				end
				if not (needHit or needSpell) then return end
			end
		end
	end
end

-- Stage 3: recent hits with the main skill and frequent incoming events.
local function proposeIncomingEvents(ctx)
	local mainSkill, output, env = ctx.mainSkill, ctx.output, ctx.env
	if ctx.selfHit then
		local reason = "Main skill: " .. mainSkill.activeEffect.grantedEffect.name .. ". Calculated from its hit rate."
		proposeRecent(ctx, "conditionHitRecently", ctx.hitRate, reason, "Recent hits with your main skill")
		if mainSkill.skillFlags.spell then proposeRecent(ctx, "conditionHitSpellRecently", ctx.hitRate, reason, "Recent spell hits with your main skill") end
		if mainSkill.skillFlags.attack and (mainSkill.skillFlags.weapon1Attack or mainSkill.skillFlags.weapon2Attack)
			and not env.player.modDB:GetCondition("Unarmed") then
			proposeRecent(ctx, "conditionHitRecentlyWithWeapon", ctx.hitRate, reason, "Recent hits with your weapon")
		end
	end
	proposeSecondaryHits(ctx)
	-- Frequent incoming events are modelled under an explicit combat policy.
	-- Use calculated, neutral chances so a recent-block bonus cannot activate
	-- itself, and never substitute spell block for attack block or vice versa.
	local incomingFacts = policy.Incoming(ctx.settings, output, env.configInput.enemyDamageType)
	local attackBlock, spellBlock = incomingFacts.attackBlockChance, incomingFacts.spellBlockChance
	local blockReason = string.format("Incoming attack block: %.1f%%, spell block: %.1f%%.", attackBlock, spellBlock)
	local function incoming(var, chance, threshold, hitType, label, reason, window, eventRate)
		if chance <= 0 or ctx.settings.incomingHitRate <= 0 or eventRate <= 0 then return end
		local assumption = policy.Chance(ctx.settings, chance, threshold, hitType, m_min(ctx.seconds, window or policy.recentWindow), eventRate)
		ctx.propose({ var = var, reason = reason, review = not assumption.automatic, label = label, assumption = assumption })
	end
	incoming("conditionBlockedRecently", m_max(attackBlock, spellBlock), ctx.settings.blockThreshold,
		"blockable hits", "Recent blocks from incoming hits", blockReason, nil, incomingFacts.blockRate)
	incoming("conditionBlockedAttackRecently", attackBlock, ctx.settings.blockThreshold, "blockable attacks/projectiles", "Recent attack blocks",
		blockReason, nil, incomingFacts.attackBlockRate)
	incoming("conditionBlockedSpellRecently", spellBlock, ctx.settings.blockThreshold, "blockable spells", "Recent spell blocks", blockReason, nil,
		incomingFacts.spellBlockRate)
	incoming("conditionSuppressedRecently", output.EffectiveSpellSuppressionChance or output.SpellSuppressionChance or 0, ctx.settings.suppressionThreshold,
		"suppressible spell hits", "Recent spell suppression", "Calculated spell suppression chance.", nil,
			incomingFacts.suppressionRate)
	local target = env.configInput.enemyIsBoss
	if target == "Boss" or target == "Pinnacle" or target == "Uber" then
		incoming("conditionBlockedHitFromUniqueEnemyInPast10Sec", m_max(attackBlock, spellBlock), ctx.settings.blockThreshold,
			attackBlock >= spellBlock and "blockable attacks from the unique target" or "blockable spells from the unique target",
			"Blocked a unique target's hit in the past 10 seconds", blockReason .. "\nTarget: " .. target .. ".", 10, incomingFacts.blockRate)
	end
end

-- Stage 4: effects granted by sources, the main skill's own use and its hits.
local function proposeMainSkillEffects(ctx)
	local mainSkill, output, env, build = ctx.mainSkill, ctx.output, ctx.env, ctx.originalBuild
	local selfHit, hitRate, activity, killActor = ctx.selfHit, ctx.hitRate, ctx.activity, ctx.killActor
	for var, flag in pairs(support.availability) do
		if mainSkill.skillModList:Flag(nil, flag) or env.player.modDB:Flag(nil, flag) then
			ctx.propose({ var = var, reason = "Your build can grant this (" .. flag .. "). Include it only while active.",
				review = true, label = "Include this available effect: " .. StripEscapes(optionsByName[var].label) })
		end
	end
	-- PoB counts empty sockets itself. Only an existing manual override that
	-- disagrees with that count is worth a row: writing the computed number
	-- would freeze a value the calculation already keeps up to date.
	for _, color in ipairs({ "Red", "Green", "Blue", "White" }) do
		local var = "overrideEmpty" .. color .. "Sockets"
		local count = env.itemModDB.multipliers["Empty" .. color .. "SocketsInAnySlot"] or 0
		local override = build.configTab.input[var]
		if override ~= nil and override ~= count then
			ctx.propose({ var = var, reason = "Counted " .. count .. " empty " .. color:lower()
				.. " sockets; your override says " .. tostring(override) .. ".", review = true,
				label = "Use PoB's count of " .. count .. " empty " .. color:lower() .. " sockets instead of " .. tostring(override) .. "?", value = DEFAULT })
		end
	end
	for _, line in ipairs(ctx.lines) do
		local text = StripEscapes(line.text):lower()
		local prefix = killActor == "minion" and "minions have " or ""
		local chance, duration = text:match("^" .. prefix .. "([%d%.]+)%% chance to gain onslaught for ([%d%.]+) seconds on kill$")
		local kills = (killActor == "player" or killActor == "minion") and policy.KillRate(ctx, killActor) or 0
		if kills > 0 and chance and tonumber(chance) > 0 then
			local minion = killActor == "minion"
			local probability, lifetime = m_min(100, tonumber(chance)) / 100, tonumber(duration)
			local assumption = policy.Refresh(ctx.settings, kills * probability, lifetime, ctx.seconds)
			-- A selected minion's combined kill rate does not prove each minion can refresh it.
			ctx.propose({ var = minion and "minionBuffOnslaught" or "buffOnslaught", reason = line.source .. "\n" .. line.text,
				review = minion or not assumption.automatic, label = minion and "Do your minions maintain Onslaught from their own kills?"
					or "Onslaught from your kills", assumption = assumption })
		end
		-- Unnerve on hit is not derived natively. Unnerved enemies take increased
		-- spell damage, so only a hitting main spell benefits from it.
		local unnerve, unnerveDuration = text:match("^([%d%.]+)%% chance to unnerve enemies for ([%d%.]+) seconds on hit$")
		if unnerve and tonumber(unnerve) > 0 and mainSkill.skillFlags.spell and ctx.facts.MainHit() and not ctx.derived.conditionEnemyUnnerved then
			local assumption = policy.Refresh(ctx.settings, hitRate * m_min(100, tonumber(unnerve)) / 100, tonumber(unnerveDuration), ctx.seconds)
			ctx.propose({ var = "conditionEnemyUnnerved", reason = line.source .. "\n" .. line.text
				.. "\nUses your main spell's hit rate.",
				review = not assumption.automatic, label = "Unnerve from your main spell's hits", assumption = assumption })
		end
	end
	local name = mainSkill.activeEffect.grantedEffect.name
	if selfHit and (output.CritChance or 0) > 0 and mainSkill.skillModList:Flag(mainSkill.skillCfg, "Condition:CanBeElusive") then
		local assumption = policy.Rate(ctx.settings, hitRate * output.CritChance / 100, m_min(ctx.seconds, 4))
		ctx.propose({ var = "buffElusive", reason = "Your main skill grants Elusive on critical strikes.",
			review = not assumption.automatic, label = "Elusive from your main skill's crits", assumption = assumption })
	end
	if selfHit and (output.CritChance or 0) > 0 then
		local rate = output.CritChance / 100 * hitRate
		local reason = "Main skill: " .. name .. ". Uses its crit chance and hit rate."
		proposeRecent(ctx, "conditionCritRecently", rate, reason, "Recent crits with your main skill")
		proposeRecent(ctx, "conditionSkillCritRecently", rate, reason, "Your main skill has crit recently")
	end
	if selfHit and (output.CritChance or 0) < 100 then
		proposeRecent(ctx, "conditionNonCritRecently", (1 - (output.CritChance or 0) / 100) * hitRate,
			"Main skill: " .. name .. ". Uses its non-crit chance and hit rate.", "Recent non-crits with your main skill")
	end
	if selfHit and mainSkill.skillModList:Flag(nil, "Condition:CanGainConvergence") then
		ctx.propose({ var = "conditionConvergence", reason = "Includes the temporary Convergence damage window from hitting a unique enemy."
			.. conditionReason(env.player, "CanGainConvergence", build), review = true,
			label = "Include the Convergence damage window?" })
	end
	if activity > 0 and playerUsesSkill(mainSkill) and not mainSkill.skillData.triggered
		and (mainSkill.skillFlags.hit or mainSkill.skillTypes[SkillType.Channel]) then
		ctx.propose({ var = "conditionUsedSkillRecently", reason = "You are using " .. name
			.. " as your main skill.",
			review = activity < 1, label = "Using your main skill during combat" })
		if mainSkill.skillTypes[SkillType.Brand] then
			ctx.propose({ var = "conditionUsedBrandRecently", reason = "Main self-used brand: " .. name .. ".", review = activity < 1,
				label = "Recent use of your main brand", assumption = policy.Scenario("You cast your main brand within the last four seconds.") })
		end
		for _, element in ipairs({ "Fire", "Cold" }) do
			if mainSkill.skillTypes[SkillType[element]] then
				ctx.propose({ var = "conditionUsed" .. element .. "SkillRecently", reason = "Main skill: " .. name
					.. ", a " .. element:lower() .. " skill.", review = activity < 1,
					label = "Recently used your " .. element:lower() .. " main skill" })
			end
		end
	end
	if killActor then
		local var = killActor == "player" and "conditionKilledRecently" or killActor == "totem" and "conditionTotemsKilledRecently"
			or "conditionMinionsKilledRecently"
		proposeRecent(ctx, var, policy.KillRate(ctx, killActor), "Uses your kill rate for the " .. killActor .. ".", StripEscapes(optionsByName[var].label))
	end
	for _, element in ipairs({ "Fire", "Cold", "Lightning" }) do
		if activity > 0 and mainSkill.skillFlags.hit and mainSkill.skillFlags["apply" .. element .. "Exposure"] then
			ctx.propose({ var = "conditionEnemy" .. element .. "Exposure", reason = "Main skill: " .. name
				.. ". Applies " .. element .. " Exposure on hit.", review = false,
				label = element .. " Exposure from your main skill",
					assumption = policy.Scenario("Keep hitting to maintain Exposure.") })
		end
	end
end

-- Stage 5: enabled auxiliary skills can supply a condition even when they are
-- not selected as the main skill. Their actual use is an explicit assumption.
local function proposeAuxiliarySkills(ctx)
	local mainSkill, output, env, activity = ctx.mainSkill, ctx.output, ctx.env, ctx.activity
	local found = ctx.found
	for _, skill in ipairs(env.player.activeSkillList) do
		local name = skill.activeEffect.grantedEffect.name
		if model.SkillEnabled(skill) then
			if name:match("^Righteous Fire") and playerUsesSkill(skill) and env.player.modDB:Sum("BASE", nil, "FireDegen") > 0 then
				ctx.propose({ var = "conditionBurning", reason = "Enabled skill: " .. name
					.. ". It burns you while active." })
			end
			if skill.activeEffect.grantedEffect.id == "WaveOfConviction" then
				local probe = ctx.probeSkill(skill)
				local element = probe and exposureType(probe.player.output)
				if element then
					local assumption, branded = waveApplication(ctx, skill, probe, element)
					local automatic = assumption and assumption.automatic or false
					local reason = automatic and (name .. " deals only " .. element:lower() .. " hit damage"
						.. (branded and ", triggered by Arcanist Brand." or "."))
						or ("Enabled skill: " .. name .. ". Confirm it mostly deals " .. element:lower() .. " damage and hits regularly.")
					ctx.propose({ var = "waveOfConvictionExposureType", reason = reason, review = not automatic,
						label = element .. " Exposure from Wave of Conviction", value = element, assumption = assumption })
					if automatic and branded and found.waveOfConvictionExposureType
						and found.waveOfConvictionExposureType.assumption == assumption then
						ctx.arcanistWave = assumption
						ctx.propose({ var = "targetBrandedEnemy", reason = "Your Arcanist Brand triggers Wave of Conviction on this target.", review = false,
							label = "Arcanist Brand attached to the target", value = true, requires = { "waveOfConvictionExposureType" },
								assumption = assumption })
					end
				end
			end
			if skill.skillFlags.totem and not ctx.derived.conditionHaveTotem then
				ctx.propose({ var = "conditionHaveTotem", reason = "Enabled skill: " .. name .. ". Keep it summoned.",
					review = skill ~= mainSkill,
					label = "Do you keep " .. name .. " summoned during the fight?" })
			end
			local skillActivity = skill == mainSkill and activity or 1
			if skillActivity > 0 and skill.skillTypes[SkillType.Warcry] then
				local probe = playerUsesSkill(skill) and not skill.skillData.triggered and ctx.probeSkill(skill)
				local assumption = policy.SkillUse(probe and (probe.player.output.Cooldown or probe.player.output.Time), skillActivity)
				ctx.propose({ var = "conditionUsedWarcryRecently", reason = "Enabled warcry: " .. name .. ".", review = not assumption.automatic,
					label = "Recent use of " .. name, assumption = assumption })
			end
			if skillActivity > 0 and playerUsesSkill(skill) and not skill.skillData.triggered and skill.skillTypes[SkillType.Travel] then
				local probe = ctx.probeSkill(skill)
				local assumption = policy.SkillUse(probe and (probe.player.output.Cooldown or probe.player.output.Time), skillActivity)
				ctx.propose({ var = "conditionUsedTravelSkillRecently", reason = "Enabled travel skill: " .. name .. ".", review = not assumption.automatic,
					label = "Recent use of " .. name, assumption = assumption })
				if name == "Dash" then
					ctx.propose({ var = "conditionUsedDashRecently", reason = "Enabled self-cast Dash.", review = not assumption.automatic,
						label = "Recently cast Dash", assumption = assumption })
				end
			end
			if name:match("^Summon Lightning Golem") then
				ctx.propose({ var = "summonLightningGolemEnableWrath", reason = "Enabled skill: " .. name
					.. ". Includes its aura while nearby.", review = true,
					label = "Include your Lightning Golem's aura?" })
			end
			if playerUsesSkill(skill) then
				for _, effect in ipairs(skill.effectList) do
					if effect.grantedEffect.id == "SupportInfusedChannelling" and skill.skillTypes[SkillType.Channel]
						and (skill ~= mainSkill or activity > 0) then
						ctx.propose({ var = "infusedChannellingInfusion", reason = "Enabled skill: " .. name
							.. ", supported by Infused Channelling.",
							review = skill ~= mainSkill or activity < 1,
							label = skill == mainSkill and ("Infused Channelling while using " .. name) or ("Do you channel " .. name .. " during the fight?"),
							assumption = policy.Scenario("Keep channelling the supported skill.") })
					end
					local buff = resourceBuffs[effect.grantedEffect.id]
					if buff then
						local stats = calcLib.buildSkillInstanceStats(effect, effect.grantedEffect)
						local threshold = stats[buff.threshold] or 0
						local duration = (stats[buff.duration] or 0) / 1000
						local cost = skill == mainSkill and (output[buff.resource .. "PerSecondCost"] or 0) * activity or 0
						local window = m_min(duration, ctx.seconds)
						local paidByShield = buff.resource == "Mana" and env.player.modDB:Flag(nil, "EnergyShieldProtectsMana")
						-- With Eldritch Battery the displayed mana cost may be paid
						-- with energy shield rather than mana; ask instead.
						local sustain = threshold > 0 and cost * window >= threshold and not paidByShield
						if skill ~= mainSkill or cost > 0 then
							local assumption = policy.Scenario("Keep using the supported skill and paying its cost.")
							if skill == mainSkill then
								assumption.spending = { resource = buff.resource, amount = cost * window,
									threshold = threshold, window = window, paidByShield = paidByShield }
							end
							ctx.propose({ var = buff.var, reason = "Enabled skill: " .. name .. ", supported by " .. buff.name
								.. ".\nRequires spending " .. threshold .. " " .. buff.resource:lower() .. " on that skill."
								.. (sustain and "\nYour main skill reaches this in time." or "\nInclude only if you keep the buff up."), review = not sustain,
								label = sustain and (buff.name .. " from using " .. name)
									or ("Do you use " .. name .. " enough to maintain " .. buff.name .. "?"), assumption = assumption })
						end
					end
				end
			end
			for _, effect in ipairs(skill.effectList) do
				local question = support.skillQuestions[effect.grantedEffect.name]
				if question and (not question.mapping or ctx.mapping) then
					ctx.propose({ var = question.var, reason = "Enabled skill: " .. name .. ", supported by " .. effect.grantedEffect.name .. ".",
						review = true,
							label = question.question })
				end
				if effect.grantedEffect.name == "Elemental Army" and skill.minion then
					local probe = ctx.probeSkill(skill)
					local element = probe and probe.minion and exposureType(probe.minion.output)
					if element then
						ctx.propose({ var = "elementalArmyExposureType", reason = "Enabled minion skill: " .. name
							.. ", supported by Elemental Army. Its minion mostly deals " .. element:lower() .. " damage.", review = true,
							label = "Use " .. element .. " Exposure from your Elemental Army minion?", value = element })
					end
				end
			end
		end
	end
end

local burningSkills = {
	RighteousFire = true, RighteousFireAltX = true,
	ScorchingRay = true, ScorchingRayAltX = true,
}
local function proposeBurningTarget(ctx)
	local ignite = ctx.found.conditionEnemyIgnited
	if ctx.derived.conditionEnemyBurning or (ignite and ignite.selected)
		or not visibility.isRelevantForBuild(optionsByName.conditionEnemyBurning, ctx.snapshot) then return end
	for _, skill in ipairs(ctx.env.player.activeSkillList) do
		local effect = skill.activeEffect.grantedEffect
		if burningSkills[effect.id] and playerUsesSkill(skill) and events.IsDirect(skill)
			and (skill ~= ctx.mainSkill or ctx.activity > 0) then
			local probe = ctx.probeSkill(skill)
			if probe and (probe.player.output.FireDot or 0) > 0 then
				ctx.propose({ var = "conditionEnemyBurning", review = true,
					label = "Does " .. effect.name .. " keep this enemy burning?",
					reason = "Enabled skill: " .. effect.name .. ". Confirm it keeps the enemy burning." })
				return
			end
		end
	end
end

-- Stage 6: damaging ailments inflicted by the main skill's hits.
local function proposeMainSkillAilments(ctx)
	local mainSkill, output, hitRate = ctx.mainSkill, ctx.output, ctx.hitRate
	for _, ailment in ipairs({ { "Bleed", "Bleeding" }, { "Poison", "Poisoned" }, { "Ignite", "Ignited" } }) do
		local chance = output[ailment[1] .. "Chance"] or output[ailment[1] .. "ChancePerHit"] or 0
		if mainSkill.skillFlags.hit and chance > 0
			and (output[ailment[1] .. "DPS"] or 0) > 0 then
			local assumption = policy.Refresh(ctx.settings, chance / 100 * hitRate, output[ailment[1] .. "Duration"] or 0, ctx.seconds)
			local frequent = assumption.automatic
			ctx.propose({ var = "conditionEnemy" .. ailment[2], reason = "Main skill: " .. mainSkill.activeEffect.grantedEffect.name
				.. ". Has a " .. string.format("%.1f", chance) .. "% chance to inflict " .. ailment[1]
				.. ".", review = not frequent,
				label = frequent and ("Enemy " .. ailment[2]:lower() .. " from your main skill")
					or ("Do you keep the enemy " .. ailment[2]:lower() .. " during the fight?"), assumption = assumption })
			if ctx.selfHit and ailment[1] ~= "Bleed" then
				proposeRecent(ctx, "condition" .. ailment[2] .. "EnemyRecently", chance / 100 * hitRate,
					"Main skill: " .. mainSkill.activeEffect.grantedEffect.name .. ". Can inflict " .. ailment[1]:lower() .. ".",
					"Recently " .. ailment[2]:lower() .. " an enemy with your main skill")
			end
		end
	end
	proposeBurningTarget(ctx)
end

-- Stage 7: rule registries in precedence order, then the calculated-default
-- overrides. The Arcanist Brand counts sit between the minion and window rules
-- so that an earlier registry can claim those settings first.
local function runRuleRegistries(ctx)
	for _, rules in ipairs({ advanced, events, mechanics, timeline, ground, buildup, minions }) do pause() rules.Detect(ctx) end
	if ctx.arcanistWave then
		local source = "Your Arcanist Brand for Wave of Conviction counts as one Brand."
		local requires = { "waveOfConvictionExposureType" }
		ctx.propose({ var = "ActiveBrands", reason = source, review = false, label = "One active Arcanist Brand", value = 1, requires = requires,
			assumption = ctx.arcanistWave })
		ctx.propose({ var = "BrandsAttachedToEnemy", reason = source, review = false, label = "One Brand attached to the target", value = 1,
			requires = requires, assumption = ctx.arcanistWave })
	end
	for _, rules in ipairs({ windows, batch, history, stacks, resources, choices, position, shrines, profiles, quests, stuns, uncertain }) do
		pause()
		rules.Detect(ctx)
	end
	local input = ctx.originalBuild.configTab.input
	for var, rule in pairs(support.defaults) do
		if input[var] ~= nil and input[var] ~= rule.defaultValue then
			ctx.propose({ var = var, reason = "PoB has a live calculated default for " .. rule.stat
				.. ". Clear the override so it follows your build.", review = true,
				label = "Use PoB's calculated value for " .. StripEscapes(optionsByName[var].label):gsub(":$", "") .. "?", value = DEFAULT })
		end
	end
end

-- Stage 8: an unsupported trigger or cast policy must not approve estimates
-- calculated under it. Every non-structural proposal is held for review and
-- coupled to the policy choice; the combined preview recalculates afterwards.
local function holdForPolicy(ctx, policyVar, description, note, unresolved)
	for var, entry in pairs(ctx.found) do
		if not structural[var] then
			entry.review, entry.selected = true, false
			if unresolved then entry.unresolved, entry.status = true, "Main trigger source missing" end
			entry.assumption = copyTable(entry.assumption or { description = description }, true)
			entry.assumption.automatic = false
			entry.assumption.applyTogether = entry.assumption.applyTogether or { }
			t_insert(entry.assumption.applyTogether, policyVar)
			entry.reason = entry.reason .. note
		end
	end
end
-- Player states PoB derives from a proposed checkbox alone, such as Adrenaline
-- on kill following Killed Recently: reported as derived, never written.
local function collectFollowingStates(ctx)
	local found = ctx.found
	local function parentOf(mod)
		local parent
		for _, tag in ipairs(mod) do
			local proposal = tag.type == "Condition" and tag.var and not tag.neg and found["condition" .. tag.var]
			if not (proposal and proposal.value == true) then return end
			parent = proposal
		end
		return parent
	end
	for var, condition in pairs(derivedConditions) do
		if not found[var] and not ctx.derived[var] and support.IsInScope(var) then
			local db = ctx.env.player.modDB
			while db and not ctx.derived[var] do
				for _, mod in ipairs(db.mods and db.mods["Condition:" .. condition] or { }) do
					local parent = parentOf(mod)
					if parent then
						ctx.derived[var] = "PoB derives " .. condition .. " from the proposed \"" .. parent.label .. "\" without enabling this checkbox."
						break
					end
				end
				db = db.parent
			end
		end
	end
end
local function resolveTriggerPolicies(ctx)
	local found, env, input = ctx.found, ctx.env, ctx.originalBuild.configTab.input
	-- Resolve the actual main Doom Blast actor's source first.
	local doom = found.doomBlastSource
	if ctx.mainSkill.activeEffect.grantedEffect.name == "Doom Blast" and not isValidChoice(doom and doom.choices, env.configInput.doomBlastSource) then
		holdForPolicy(ctx, "doomBlastSource", "Choose your Doom Blast trigger source first.",
			"\nYour build has no source for the current Doom Blast trigger mode.", not doom)
	end
	-- Native bypass defaults can be true without a generator. Do not approve
	-- estimates from the neutral cooldown while leaving that old policy active.
	-- Unsupported saved repeat/seal modes likewise require an explicit profile.
	for policyVar in pairs(choices.rotationVars) do
		local proposal = found[policyVar]
		if proposal then
			local matches = ctx.planned and ctx.planned[policyVar] ~= nil or input[policyVar] == env.configInput[policyVar]
			if not isValidChoice(proposal.choices, env.configInput[policyVar]) or not matches then
				holdForPolicy(ctx, policyVar, "Confirm your main skill's cast mode first.",
					"\nThe saved cast mode is unsupported or changed: " .. policyVar .. ".")
			end
		end
	end
end

-- Stage 9: suggestions (proposals plus guided numeric fallbacks) and the full
-- report, which adds derived states and eligible settings without a source.
local function buildReport(ctx)
	local build, snapshot, settings, found, derived = ctx.originalBuild, ctx.snapshot, ctx.settings, ctx.found, ctx.derived
	local suggestions, report = { }, { }
	local numericFallbacks
	for _, option in ipairs(options) do
		local suggestion = found[option.var]
		local assessment = option.var and support.GetAssessment(option, settings)
		local function eligible() return visibility.isRelevantForBuild(option, snapshot) or visibility.isRelevantForBuild(option, build) end
		if suggestion then
			suggestion.assessment = assessment
			suggestion.settings = settings
			t_insert(suggestions, suggestion)
			t_insert(report, suggestion)
		elseif option.var and derived[option.var] and eligible() then
			-- Report only: PoB applies this state itself, so there is nothing to write.
			local current = build.configTab.input[option.var]
			t_insert(report, {
				var = option.var, label = StripEscapes(option.label), section = sectionsByName[option.var],
				unresolved = true, derived = true, selected = false, current = current, value = nil,
				status = "Calculated by PoB", assessment = assessment, settings = settings,
				reason = derived[option.var] .. (current == true
					and "\nThe checkbox is currently enabled but not needed; turn it off." or "\nNo checkbox is needed."),
			})
		elseif option.var and assessment.inScope and not option.legacy and eligible() then
			local isCheck = option.type == "check"
			local current = build.configTab.input[option.var]
			local default = support.defaults[option.var]
			if assessment.needsObservedValue and not numericFallbacks then
				numericFallbacks = { }
				for _, entry in ipairs(guided.Entries(snapshot.configTab, support.GetInventory())) do numericFallbacks[entry.var] = entry end
			end
			local numeric = numericFallbacks and numericFallbacks[option.var]
			if assessment.needsObservedValue and numeric and numeric.available then
				numeric.numeric, numeric.valueBuild, numeric.assessment = true, snapshot, assessment
				numeric.current, numeric.useDefault = current, false
				numeric.status = "Positive amount needs your input"
				numeric.reason = numeric.reason .. (uncertain.sampleDerived[option.var]
					and "\nEnter the observed amount or add a kill in Hit samples." or "\nEnter the amount you maintain.")
				t_insert(suggestions, numeric); t_insert(report, numeric)
			else
				local status = assessment.needsObservedValue and "Positive amount needs your input"
					or assessment.detectionMode == "imported-quest-record" and "Needs a character import record"
					or stuns.capabilities[option.var] and "Stun not established"
					or profiles.capabilities[option.var] and (profiles.GetStatus(option.var, settings))
					or assessment.supported and (assessment.kind == "calculated-default"
						and (current == nil or default and current == default.defaultValue) and "Calculated by PoB" or "No source detected")
					or assessment.feasibility == "possible-with-additional-rule" and "Rule not implemented"
					or "Requires your input"
				local entry = {
					var = option.var, label = StripEscapes(option.label), section = sectionsByName[option.var],
					unresolved = true, selected = false, current = current,
					status = status, assessment = assessment,
					reason = isCheck and ("No source found for this setting." .. (current == true and " It is currently enabled and left unchanged." or ""))
						or "Needs a value or choice; your current value is kept.",
				}
				if not assessment.supported or status == "Calculated by PoB" then entry.reason = assessment.method end
				t_insert(report, entry)
			end
		end
	end
	return suggestions, report
end

local function detect(build, mapping, seconds, planned, settings)
	local ctx = newScanContext(build, mapping, seconds, planned, settings)
	for _, stage in ipairs({ collectDerivedStates, proposeIncomingEvents, proposeMainSkillEffects, proposeAuxiliarySkills,
		proposeMainSkillAilments, runRuleRegistries, collectFollowingStates, resolveTriggerPolicies }) do
		pause()
		stage(ctx)
	end
	pause()
	local suggestions, report = buildReport(ctx)
	scans[suggestions] = { build = build, mapping = mapping, seconds = ctx.seconds, report = report, signature = "",
		settings = ctx.settings, outputRevision = build.outputRevision, source = sourceStamp(build) }
	return suggestions, report
end
-- Returns suggestions (proposals the user can select) and the full report.
-- `planned` stages structural values; `settings` overrides the saved
-- sensitivity preferences. Every scan and probe path runs inside detect, so
-- this single wrapper isolates the whole calculation from the real tab and
-- the global cache.
function M.Detect(build, mapping, seconds, planned, settings)
	settings = settings and preferences.Normalize(settings) or preferences.Get(main)
	return withIsolatedCalc(detect, build, mapping, seconds, planned, settings)
end
-- The same scan spread over frames, for the automatic marker check. Each
-- ResumeDetect runs it until about `budget` milliseconds have passed and the
-- next stage boundary is reached; once it has finished it returns true plus
-- pcall-style results (ok, suggestions or error, report). A scan dropped before
-- then has written nothing and holds no swapped state.
function M.StartDetect(build, mapping, seconds, planned, settings)
	settings = settings and preferences.Normalize(settings) or preferences.Get(main)
	return { thread = coroutine.create(function()
		return withIsolatedCalc(detect, build, mapping, seconds, planned, settings)
	end) }
end
function M.ResumeDetect(scan, budget)
	scan.budget, scan.sliceStart = budget, GetTime()
	stepping = scan
	local results = { coroutine.resume(scan.thread) }
	stepping = nil
	if coroutine.status(scan.thread) ~= "dead" then return false end
	return true, unpack(results)
end

-- ============================================================================
-- Selection state: Preview, Toggle, Choose, Apply and the one-click setup
-- ============================================================================
-- Entry flags. Detect sets the first group; Preview, Choose/ChooseNumber and
-- the guided editor (ConfigAutoRulesBuild.Guided) maintain the rest. Readers
-- are the selection functions below, the setting checks and the popups.
--   selected        Apply writes this entry. Toggle keeps the closure over
--                   requires, applyTogether and the alternating (exclusive) windows.
--   review          A gameplay question: starts unselected, shown on the Review page.
--   unresolved      Report-only row (no source, derived state, missing trigger
--                   source); never applied, even if a caller selects it.
--   derived         PoB applies the state itself; a manual checkbox is redundant.
--   numeric         Guided numeric entry; needs a confirmed value before it counts.
--   choices         Possible values {val, label}; the user must pick one.
--   choiceConfirmed A choice or number has been confirmed (Choose, ChooseNumber,
--                   the one-click setup) and survives a Preview when still valid.
--   useDefault      Apply clears the input (DEFAULT proposal) so PoB's native
--                   default applies; the placeholder is cleared with it.
--   restorePlaceholder / clearPlaceholder
--                   Guided editor: placeholder value to restore on apply, or
--                   clear the placeholder together with the value.
--   requires        Parent settings that must be enabled (selected or already on).
--   assumption.applyTogether
--                   Peers that must be selected and applied with this entry.
--   reviewTogether  Preview-added curse corrections: selecting the parent must
--                   not auto-select them; they stay explicit review rows.
--   proof           Reason text before Preview appends its "changed" note, so a
--                   later preview can tell an unchanged entry from a new one.
--   status          Tag shown for unresolved rows ("No source detected", ...).
--   current         The real configuration value when the scan ran.
--   valueBuild      Snapshot the guided editor validates a numeric entry against.
function M.SelectionError(configTab, suggestions)
	local selected, budgets = { }, { }
	for _, entry in ipairs(suggestions) do
		if entry.selected and not entry.unresolved then selected[entry.var] = entry end
		local budget = entry.assumption and entry.assumption.selectionBudget
		if budget then budgets[budget.group] = budget end
	end
	for _, entry in pairs(selected) do
		if entry.validate then local problem = entry.validate(entry); if problem then return problem end end
		if entry.choices and (not entry.choiceConfirmed or not isValidChoice(entry.choices, entry.value)) then
			return "Choose a valid value for " .. entry.label
		end
		for _, peer in ipairs(entry.assumption and entry.assumption.applyTogether or { }) do
			if not selected[peer] then return "Confirm the linked change before applying: " .. StripEscapes(optionsByName[peer].label) end
		end
	end
	for _, budget in pairs(budgets) do
		local count, changed = 0, false
		for _, var in ipairs(budget.vars) do
			local entry = selected[var]
			local value = configTab.input[var]
			if entry then value = entry.value; changed = changed or value == true end
			if value == true then count = count + 1 end
		end
		if changed and count > budget.maximum then
			return string.format("%g selected %s exceed %s (%g). Confirm the actual outcomes.", count, budget.label or "Sentinel auras",
				budget.limitLabel or "native Sentinel capacity", budget.maximum)
		end
	end
end

-- Recompute all structural decisions on an isolated snapshot. Preserve only
-- unchanged approvals; newly available or changed derived values need review.
function M.Preview(suggestions)
	local state = scans[suggestions]
	if not state or state.previewing then return end
	local plan, parts, previous = { }, { }, { }
	for _, entry in ipairs(suggestions) do
		previous[entry.var] = entry
		if entry.selected and structural[entry.var] and (not entry.choices or entry.choiceConfirmed) then
			if entry.choices and not isValidChoice(entry.choices, entry.value) then return state.report end
			plan[entry.var] = entry.useDefault and DEFAULT or entry.value
			t_insert(parts, entry.var .. "=" .. (entry.useDefault and "native-default" or tostring(entry.value)))
		end
	end
	table.sort(parts)
	local signature = t_concat(parts, ";")
	if signature == state.signature then return state.report end
	state.previewing = true
	local ok, fresh, report = pcall(M.Detect, state.build, state.mapping, state.seconds, plan, state.settings)
	if not ok then
		-- Leave the popup usable: keep the last report and surface the failure.
		state.previewing = false
		state.previewError = tostring(fresh)
		if launch and launch.ShowErrMsg then launch:ShowErrMsg("Auto-configure preview failed:\n%s", state.previewError) end
		return state.report
	end
	state.previewError = nil
	local byVar = { }
	for _, entry in ipairs(fresh) do
		byVar[entry.var] = entry
		local old = previous[entry.var]
		if entry.numeric and old and old.choiceConfirmed and not old.useDefault then
			local candidate = { value = old.value, choiceConfirmed = true }
			if not entry.validate(candidate) then
				entry.value, entry.choiceConfirmed, entry.label = old.value, true, old.label
			end
		end
		if entry.choices and old and old.choiceConfirmed then
			for _, choice in ipairs(entry.choices) do
				if choice.val == old.value then entry.value, entry.choiceConfirmed, entry.label = old.value, true, old.label break end
			end
		end
		entry.proof = entry.reason
		local unchanged = old and old.value == entry.value and old.useDefault == entry.useDefault and (not entry.choices or entry.choiceConfirmed)
			and (structural[entry.var] or (not entry.review or old.review) and (old.proof or old.reason) == entry.proof)
		entry.selected = unchanged and old.selected or false
		if not unchanged then
			entry.review = true
			entry.reason = entry.reason .. "\nChanged by your choices above; review it."
		end
	end
	-- Self-only curse decisions remove the enemy-curse evidence; stale claims
	-- become explicit corrections coupled to those decisions.
	local parents = { }
	for var, value in pairs(plan) do if value == true and var:match("^balanceOfTerrorSelfCast") then t_insert(parents, var) end end
	table.sort(parents)
	if #parents > 0 then
		local enemyCursed
		for _, row in ipairs(report) do
			if row.var == "conditionEnemyCursed" then enemyCursed = row.derived break end
		end
		for _, var in ipairs({ "conditionEnemyCursed", "conditionCursedEnemyRecently", "conditionEnemyDebilitated", "multiplierCurseExpiredOnEnemy",
			"multiplierCurseDurationExpiredOnEnemy" }) do
			local current = state.build.configTab.input[var]
			local placeholder = state.build.configTab.placeholder[var]
			local needsClear = current == true or type(current) == "number" and current > 0 or type(placeholder) == "number" and placeholder > 0
			local known = var == "conditionEnemyCursed" or var == "conditionCursedEnemyRecently" or previous[var]
			if not byVar[var] and not (var == "conditionEnemyCursed" and enemyCursed) and needsClear and known then
				local value = optionsByName[var].type ~= "check" and 0 or false
				local entry = { var = var, value = value, current = current, review = true, selected = false, useDefault = false,
					label = "Clear stale " .. StripEscapes(optionsByName[var].label), section = sectionsByName[var], requires = copyTable(parents),
					assessment = support.GetAssessment(var), reason = "With self-cast only, nothing curses the enemy anymore; "
						.. "clear this together with that choice." }
				local old = previous[var]
				if old and old.value == value then entry.selected = old.selected end
				byVar[var] = entry; t_insert(fresh, entry)
				for i = #report, 1, -1 do if report[i].var == var then t_remove(report, i) end end
				t_insert(report, entry)
				for _, parent in ipairs(parents) do
					local proposal = byVar[parent]
					if proposal then
						proposal.assumption = proposal.assumption
							or { automatic = false, description = "Apply together with the curse corrections." }
						proposal.assumption.applyTogether = proposal.assumption.applyTogether or { }
						t_insert(proposal.assumption.applyTogether, var)
						proposal.reviewTogether = true
					end
				end
			end
		end
	end
	-- Keep the caller's entry tables: the popup holds references to them.
	for _, entry in ipairs(fresh) do
		local old = previous[entry.var]
		if old then
			for key in pairs(old) do old[key] = nil end
			for key, value in pairs(entry) do old[key] = value end
			byVar[entry.var] = old
		end
	end
	for _, old in ipairs(suggestions) do if not byVar[old.var] then old.selected = false end end
	for i = #suggestions, 1, -1 do suggestions[i] = nil end
	for _, entry in ipairs(fresh) do t_insert(suggestions, byVar[entry.var]) end
	for i, entry in ipairs(report) do if byVar[entry.var] then report[i] = byVar[entry.var] end end
	state.report, state.signature, state.previewing = report, signature, false
	if state.onChange then state.onChange(report) end
	return M.Preview(suggestions) or report
end

-- Write the selected, applicable entries to configTab. `applied` collects the
-- entries written. Returns whether anything changed.
local function applySelected(configTab, suggestions, applied)
	local changed = false
	local selected, resolved, resolving = { }, { }, { }
	for _, suggestion in ipairs(suggestions) do
		if suggestion.selected and not suggestion.unresolved and support.IsInScope(suggestion.var) then selected[suggestion.var] = suggestion end
	end
	-- Alternating Aspect phases cannot be applied together, including callers
	-- that bypass the popup's mutually exclusive selection handling.
	for var, suggestion in pairs(selected) do
		local opposite = windows.exclusive[var]
		if suggestion.value == true and opposite and selected[opposite] and selected[opposite].value == true then
			resolved[var], resolved[opposite] = false, false
		end
	end
	local function canApply(suggestion)
		if resolved[suggestion.var] ~= nil then return resolved[suggestion.var] end
		if resolving[suggestion.var] then return false end
		if suggestion.choices and (not suggestion.choiceConfirmed or not isValidChoice(suggestion.choices, suggestion.value)) then
			resolved[suggestion.var] = false
			return false
		end
		resolving[suggestion.var] = true
		for _, parent in ipairs(suggestion.requires or { }) do
			local proposal = selected[parent]
			local value = configTab.input[parent]
			local opposite = windows.exclusive[parent]
			if opposite and selected[opposite] and selected[opposite].value == true and canApply(selected[opposite]) then value = false end
			if proposal and canApply(proposal) then value = proposal.value end
			if value == nil and configTab.GetDefaultState then value = configTab:GetDefaultState(parent) end
			if not enabledDependency(value) then resolving[suggestion.var], resolved[suggestion.var] = nil, false return false end
		end
		for _, peer in ipairs(suggestion.assumption and suggestion.assumption.applyTogether or { }) do
			if not selected[peer] then resolving[suggestion.var], resolved[suggestion.var] = nil, false return false end
		end
		resolving[suggestion.var], resolved[suggestion.var] = nil, true
		return true
	end
	for _, suggestion in ipairs(suggestions) do
		if selected[suggestion.var] and canApply(suggestion) then
			if applied then applied[suggestion.var] = suggestion end
			local opposite = suggestion.value == true and windows.exclusive[suggestion.var]
			if opposite then
				if configTab.input[opposite] ~= false then configTab.input[opposite], changed = false, true end
				if configTab.placeholder[opposite] ~= nil then configTab.placeholder[opposite], changed = nil, true end
			end
			if configTab.input[suggestion.var] ~= suggestion.value then
				configTab.input[suggestion.var] = suggestion.value
				changed = true
			end
			-- For count inputs, zero otherwise falls back to a user placeholder.
			-- Restoring a native default must also remove that old override.
			if suggestion.restorePlaceholder ~= nil and configTab.placeholder[suggestion.var] ~= suggestion.restorePlaceholder then
				configTab.placeholder[suggestion.var] = suggestion.restorePlaceholder
				changed = true
			elseif suggestion.restorePlaceholder == nil and (suggestion.value == 0 or suggestion.useDefault or suggestion.clearPlaceholder)
				and configTab.placeholder[suggestion.var] ~= nil then
				configTab.placeholder[suggestion.var] = nil
				changed = true
			end
		end
	end
	return changed
end

-- Apply the selection to the active config set as one undo step. Refuses a
-- stale scan or an invalid selection. Returns whether anything changed.
function M.Apply(configTab, suggestions)
	local state = scans[suggestions]
	if not scanIsCurrent(state, true) then return false end
	M.Preview(suggestions)
	if M.SelectionError(configTab, suggestions) then return false end
	local applied = state and { }
	local changed = applySelected(configTab, suggestions, applied)
	if changed then
		configTab:UpdateControls()
		configTab:BuildModList()
		configTab:AddUndoState()
		configTab.build.buildFlag = true
	end
	if state then
		M.RecordSettingChecks(configTab, configTab.configSets[configTab.activeConfigSetId], state.report, applied, state.settings)
	end
	return changed
end

function M.Toggle(suggestions, value)
	if value.unresolved then return end
	if value.numeric and not value.choiceConfirmed then return end
	local byVar = { }
	for _, suggestion in ipairs(suggestions) do byVar[suggestion.var] = suggestion end
	local function select(entry, seen)
		if seen[entry.var] then return end
		if entry.choices and not entry.choiceConfirmed then return end
		seen[entry.var], entry.selected = true, true
		local opposite = windows.exclusive[entry.var]
		if opposite and entry.value == true and byVar[opposite] then byVar[opposite].selected = false end
		for _, parent in ipairs(entry.requires or { }) do
			if byVar[parent] then select(byVar[parent], seen) end
		end
		for _, peer in ipairs(not entry.reviewTogether and entry.assumption and entry.assumption.applyTogether or { }) do
			if byVar[peer] then select(byVar[peer], seen) end
		end
	end
	if not value.selected then
		select(value, { })
	else
		value.selected = false
	end
	-- Deselecting cascades to dependants until the selection is closed.
	local changed = true
	while changed do
		changed = false
		for _, entry in ipairs(suggestions) do
			for _, parent in ipairs(entry.requires or { }) do
				if entry.selected and byVar[parent] and (not byVar[parent].selected or not enabledDependency(byVar[parent].value)) then
					entry.selected, changed = false, true
				end
			end
			for _, peer in ipairs(not entry.reviewTogether and entry.assumption and entry.assumption.applyTogether or { }) do
				if entry.selected and byVar[peer] and not byVar[peer].selected then entry.selected, changed = false, true end
			end
		end
	end
	M.Preview(suggestions)
end

function M.Choose(suggestions, entry, value)
	if not entry.choices then return false end
	for _, choice in ipairs(entry.choices) do
		if choice.val == value then
			entry.value, entry.choiceConfirmed = value, true
			entry.label = StripEscapes(optionsByName[entry.var].label):gsub(":$", "") .. ": " .. StripEscapes(choice.label)
			if not entry.selected then M.Toggle(suggestions, entry) else M.Preview(suggestions) end
			return true
		end
	end
	return false
end

function M.ChooseNumber(suggestions, entry, value, configTab)
	if not entry.numeric or not guided.Set(entry, value, configTab) then return false end
	M.Preview(suggestions)
	return entry.choiceConfirmed == true and entry.selected == true
end

-- One-click setup: a generated fight starts from PoB's native defaults and
-- adds the settings the scan can justify without asking.
local savedQuest = { bandit = true, pantheonMajorGod = true, pantheonMinorGod = true }
local setupOptions
local function startingSetup(base, settings)
	if not setupOptions then
		setupOptions = { }
		for _, entry in ipairs(support.GetInventory()) do
			if entry.supported then setupOptions[entry.var] = optionsByName[entry.var] end
		end
	end
	local draft = { id = base.id, input = copyTable(base.input), placeholder = copyTable(base.placeholder),
		customModsList = copyTable(base.customModsList or { }) }
	for var, option in pairs(setupOptions) do
		if not savedQuest[var] and var ~= "resistancePenalty" and not profiles.KeepsSetting(var, settings) then
			-- Start from the values a new native config set has, so the set
			-- computes the same after save and reload: an unset list stays unset
			-- (Augyre's first entry would grant Elemental Overload), and default
			-- placeholders (Shock stacks, Withered...) stay in place.
			draft.placeholder[var] = option.defaultPlaceholderState
			if option.type == "list" then
				draft.input[var] = option.defaultIndex and option.list[option.defaultIndex].val or option.defaultState
			elseif option.type == "check" then
				-- Checkboxes start at the native default, like a new config set;
				-- turning off a native default-on effect needs evidence too.
				draft.input[var] = option.defaultState
			else
				-- Zero-only adapters (Cruelty, Virulence, overkill...) start at
				-- PoB's native default too. A seeded 0 would replace Cruelty's
				-- native 40% for every Cruelty build while reading as "Left out".
				-- Their reviewed zero stays an explicit, confirmable proposal.
				draft.input[var] = option.defaultState
			end
		end
	end
	return draft
end
local function approveSetup(entries, base, plan, baseline)
	for _, entry in ipairs(entries) do
		local var = entry.var
		if not entry.unresolved and not entry.numeric then
			if entry.choices then
				local preferred = base.input[var]
				if profiles.capabilities[var] or var == "doomBlastSource" then
					preferred = entry.choices[1].val
					if var == "doomBlastSource" then preferred = base.input[var] or preferred end
				elseif var == "bloodSandStance" then
					preferred = preferred or optionsByName[var].list[1].val
				else
					-- Random outcomes and player-specific rotation choices stay optional.
					preferred = nil
				end
				for _, choice in ipairs(entry.choices) do
					if choice.val == preferred then entry.value, entry.choiceConfirmed, entry.selected = choice.val, true, true end
				end
				if var == "doomBlastSource" and not entry.choiceConfirmed then
					entry.value, entry.choiceConfirmed, entry.selected = entry.choices[1].val, true, true
				end
			elseif not entry.review or savedQuest[var] or var == "resistancePenalty" or profiles.capabilities[var] or entry.useDefault then
				entry.selected = true
			end
		end
		if plan and structural[var] then
			local projected = plan[var]
			if projected == nil then projected = baseline[var] end
			if (entry.useDefault and DEFAULT or entry.value) ~= projected then entry.selected = false end
		end
	end
end
function M.SetupValueLabel(var, input, placeholder)
	local option = optionsByName[var]
	local value = input[var]
	if value == nil and option.type == "check" then value = false end
	if value == nil then value = placeholder[var] end
	return plainText.ValueLabel(var, option, value)
end

local function markerEvidence(entry)
	if (entry.unresolved and not entry.derived) or entry.numeric then return end
	if entry.assumption and entry.assumption.rule == "incoming-chance" then return end
	if entry.derived or entry.reason:match("^PoB derives the enemy") then
		local source = entry.reason:match("\nSource: ([^\n]+)")
		return source and ("From " .. source .. ".")
			or (entry.derived and "Your build already gives you this effect." or "Your build applies this effect to the enemy.")
	end
	local first = entry.reason:match("^[^\n]*")
	local skill = first:match("^Main skill: (.-)%. Calculated")
	if skill then return "Your main skill is " .. skill .. "." end
	local damageSource, amount = entry.reason:match("Main damage source: (.-)%. PoB estimates ([%d%.]+%% %a+)")
	if damageSource then return "From " .. damageSource .. " hits: about " .. amount .. " on this enemy." end
	if entry.assumption and entry.assumption.chargeCount then
		local bonus = entry.reason:match("\n([^\n]+)")
		if bonus and bonus:lower():match("chance to gain ") then return first .. "\n" .. bonus end
	end
	return first
end

-- Returns the draft config set, a summary for the setup popup, the report and
-- the applied entries. The draft is not installed; the caller decides.
function M.BuildSetup(build, base, mapping, settings)
	settings = settings and preferences.Normalize(settings) or preferences.Get(main)
	local draft = startingSetup(base, settings)
	-- Clearing maps fights regular monsters; a boss fight keeps the base set's
	-- (or PoB's default) boss type. Enemy stat placeholders follow natively.
	if mapping and not profiles.KeepsSetting("enemyIsBoss", settings) then draft.input.enemyIsBoss = "None" end
	local config = setmetatable({ input = draft.input, placeholder = draft.placeholder, activeConfigSetId = draft.id,
		configSets = { [draft.id] = draft } }, { __index = build.configTab })
	local isolated = setmetatable({ configTab = config }, { __index = build })
	config.build = isolated
	local seconds = policy.recentWindow
	local entries, report = M.Detect(isolated, mapping, seconds, nil, settings)
	approveSetup(entries, base)
	local plan = { }
	for _, entry in ipairs(entries) do
		if structural[entry.var] and entry.selected then
			local value = entry.useDefault and DEFAULT or entry.value
			if value ~= draft.input[entry.var] or entry.useDefault then plan[entry.var] = value end
		end
	end
	if next(plan) then
		entries, report = M.Detect(isolated, mapping, seconds, plan, settings)
		approveSetup(entries, base, plan, draft.input)
	end
	local applied = { }
	applySelected(config, entries, applied)
	local summary = { }
	for _, entry in ipairs(report) do
		local var = entry.var
		local kept = profiles.KeepsSetting(var, settings) and (base.input[var] ~= nil or base.placeholder[var] ~= nil)
		if kept or applied[var] or entry.review or base.input[var] ~= draft.input[var] and base.input[var] ~= nil then
			local option = optionsByName[var]
			local estimated = not savedQuest[var] and (entry.assumption or entry.review)
			local status = kept and "Kept" or not applied[var] and "Left out" or estimated and "Estimated" or "From build"
			local explanation = kept and "Kept from your manual setup."
				or plainText.Reason(entry, entry.assessment, option, settings, applied[var] ~= nil)
			local evidence = not kept and markerEvidence(entry)
			if evidence and evidence ~= "" then explanation = evidence .. "\n" .. explanation end
			t_insert(summary, { var = var, label = StripEscapes(option.label):gsub("[?:]$", ""),
				value = M.SetupValueLabel(var, draft.input, draft.placeholder), status = status, reason = explanation })
		end
	end
	table.sort(summary, function(a, b)
		if (a.status == "Left out") ~= (b.status == "Left out") then return b.status == "Left out" end
		return a.label < b.label
	end)
	return draft, summary, report, applied
end

-- ============================================================================
-- Setting checks: per-set scan records behind the configuration markers
-- ============================================================================
local function checkSource(config, set)
	local source = M.SetupSource(config.build, set.id, preferences.Get(main))
	for _, values in ipairs({ source.values.input, source.values.placeholder }) do
		for var in pairs(values) do
			-- The values being checked can change without invalidating the scan.
			if support.IsInScope(var) and not structural[var] then values[var] = nil end
		end
	end
	return source
end

-- Requirement predicates from ConfigOptions, in the order ConfigVisibility
-- tests them, with the wording for a requirement the current build fails.
local function quoted(name)
	local words = tostring(name):gsub("^Condition:", ""):gsub("(%u)(%u%l)", "%1 %2"):gsub("([%l%d])(%u)", "%1 %2")
	return '"' .. words .. '"'
end
local requirementRules = {
	{ key = "ifCond", text = function(name) return "a skill, item or passive that uses " .. quoted(name) end },
	{ key = "ifMinionCond", text = function(name) return "a minion bonus that uses " .. quoted(name) end },
	{ key = "ifEnemyCond", text = function(name) return "a bonus that uses " .. quoted(name) .. " on the enemy" end },
	{ key = "ifMult", text = function(name) return "a bonus that scales with " .. quoted(name) end },
	{ key = "ifEnemyMult", text = function(name) return "a bonus that scales with the enemy's " .. quoted(name) end },
	{ key = "ifEnemyStat", text = function(name) return "a bonus that scales with the enemy's " .. quoted(name) end },
	{ key = "ifTagType", text = function(name) return "a bonus with " .. quoted(name) end },
	{ key = "ifMod", text = function(name) return "a source of " .. quoted(name) end },
	{ key = "ifNode", text = function(id, build)
		local node = build and build.spec and build.spec.nodes[id]
		return "the " .. quoted(node and node.dn or id) .. " passive allocated"
	end },
	{ key = "ifOption", text = function(var)
		local parent = optionsByName[var]
		return (parent and '"' .. StripEscapes(parent.label) .. '"' or quoted(var)) .. " turned on"
	end },
	{ key = "ifCondTrue", text = function(name) return quoted(name) .. " to be active" end },
	{ key = "ifStat", text = function(name) return "a bonus that uses " .. quoted(name) end },
	{ key = "ifFlag", text = function(name)
		return name == "randomPhys" and "a main skill that gains physical damage as a random element"
			or "a main skill that uses " .. quoted(name)
	end },
	{ key = "ifSkill", text = function(name) return quoted(name) .. " enabled in Skills" end },
	{ key = "ifSkillFlag", text = function(name) return "an enabled skill that uses " .. quoted(name) end },
	{ key = "ifSkillData", text = function(name) return "an enabled skill that uses " .. quoted(name) end },
}
-- Each predicate is tested on its own; the first one the build fails names
-- the requirement.
local function missingRequirement(config, option)
	local build = config.build
	for _, rule in ipairs(requirementRules) do
		local value = option[rule.key]
		if value then
			local single = { var = option.var, [rule.key] = value, includeTransfigured = option.includeTransfigured,
				implyCond = option.implyCond, implyCondList = option.implyCondList, implyMinionCond = option.implyMinionCond,
					implyEnemyCond = option.implyEnemyCond }
			if not visibility.isRelevantForBuild(single, build) then
				local names = { }
				for _, name in ipairs(type(value) == "table" and value or { value }) do t_insert(names, rule.text(name, build)) end
				return t_concat(names, " or ")
			end
		end
	end
end
-- Tooltip text for a setting whose value is set but whose ConfigOptions
-- requirements the build no longer meets.
function M.GetInvalidSettingReason(config, option)
	if type(option.ifOption) == "string" and not enabledDependency(config.input[option.ifOption]) then
		local parent = optionsByName[option.ifOption]
		if parent then return 'Turn on "' .. StripEscapes(parent.label) .. '" to use this setting.' end
	end
	local requirement = missingRequirement(config, option)
	if requirement then return "To use this, you need " .. requirement .. "." end
	return "Clear this setting. Your build doesn't use it."
end

function M.RecordSettingChecks(config, set, report, applied, settings)
	local source = checkSource(config, set)
	local rows = { }
	local scanSettings = copyTable(settings or preferences.Get(main))
	scanSettings.showDetails = false
	for _, entry in ipairs(report) do
		local var = entry.var
		local option = optionsByName[var]
		local chosen = applied and applied[var]
		local certain = not (entry.unresolved or entry.review or entry.assumption or entry.numeric or entry.choices or entry.useDefault)
		-- A value the one-click setup would apply without asking (the imported
		-- quest choice is a fact even when the advanced scan asks for permission
		-- before replacing a saved choice) is verified by the rule itself when
		-- nothing was applied: a manual set, or the automatic check. An Apply
		-- verifies exactly what it chose.
		local automatic = not entry.numeric and not entry.unresolved and not entry.choices and not entry.useDefault
			and (not entry.review or savedQuest[var])
		local verified = automatic and (chosen or not applied)
		local chargeCount = entry.assumption and entry.assumption.chargeCount
		local dependencies = { }
		for _, parent in ipairs(entry.requires or { }) do
			local value = set.input[parent]
			if value == nil then value = config:GetDefaultState(parent) end
			dependencies[parent] = value
		end
		rows[var] = {
			expected = entry.value, verified = not not verified,
			dependencies = dependencies, derived = entry.derived or nil,
			chargeCount = chargeCount and var == "use" .. chargeCount.kind .. "Charges" and chargeCount or nil,
			certain = certain, evidence = markerEvidence(entry),
			measurements = plainText.MeasuredReason(entry),
			explanation = plainText.Reason(entry, entry.assessment or support.GetAssessment(var, scanSettings), option, scanSettings, false),
		}
	end
	settingChecks[set] = { source = source, rows = rows, settings = scanSettings, revision = config.build.outputRevision, current = true }
end

-- Whether the set's scan record still matches the build: nil without a record,
-- otherwise true or false plus the source stamp it was compared with. The stamp
-- is rebuilt once per output revision; the markers ask every frame.
function M.SettingChecksState(config, set)
	local record = settingChecks[set]
	if not record then return nil end
	if record.revision ~= config.build.outputRevision then
		record.checked = checkSource(config, set)
		record.current = M.SameSetupSource(record.source, record.checked)
		record.revision = config.build.outputRevision
	end
	return record.current, record.checked or record.source
end

-- Marker status for a set value: "passed", "failed" or "review" (nil for no
-- marker), plus label and message when `details` is requested.
function M.GetSettingCheck(config, var, nativeInvalid, details)
	local set = config.configSets[config.activeConfigSetId]
	local option = optionsByName[var]
	local value = set.input[var]
	if value == nil or value == false or value == "" then return end
	local label = details and StripEscapes(option.label)
	if nativeInvalid then
		if not details then return "failed" end
		return "failed", label, M.GetInvalidSettingReason(config, option)
	end
	local opposite = windows.exclusive[var]
	if value == true and opposite and set.input[opposite] == true then
		if not details then return "failed" end
		return "failed", label, 'This buff alternates with "' .. StripEscapes(optionsByName[opposite].label)
			.. '". Leave one phase on for this setup.'
	end
	local record = settingChecks[set]
	if not record or profiles.KeepsSetting(var, record.settings) then return end
	M.SettingChecksState(config, set)
	local row = record.rows[var]
	-- Placeholders are PoB's live default for count inputs; a value equal to
	-- the effective default is not a manual claim and needs no marker.
	local isDefault = value == config:GetDefaultState(var, type(value))
	if not record.current or not row then
		if isDefault then return end
		if not details then return "review" end
		local message = record.current and support.GetPlainDescription(var)
			or "Scan again to check this value."
		return "review", label, message
	end
	for parent, expected in pairs(row.dependencies) do
		local actual = set.input[parent]
		if actual == nil then actual = config:GetDefaultState(parent) end
		if actual ~= expected then
			if isDefault then return end
			if not details then return "review" end
			return "review", label, 'Scan again after changing "' .. StripEscapes(optionsByName[parent].label) .. '".'
		end
	end
	if row.derived then
		-- PoB applies this state natively; the manual checkbox is redundant.
		if not details then return "passed" end
		return "passed", label, row.evidence .. "\nYou can leave this box off."
	end
	local countText
	if row.chargeCount and value == row.expected then
		local charge = row.chargeCount.kind
		local actual, kind = policy.EffectiveCharges(config.build.calcsTab.mainEnv, charge)
		local used = string.format("PoB uses %g %s Charge%s.", actual, kind, actual == 1 and "" or "s")
		if actual ~= row.chargeCount.value then
			if not details then return "review" end
			local action = row.verified and string.format(" Try %g for this fight.", row.chargeCount.value)
				or " Check how many you keep in this fight."
			local mismatch = used .. action
			if row.evidence then mismatch = mismatch .. "\n" .. row.evidence end
			return "review", label, mismatch .. row.measurements
		end
		countText = "\n" .. used
	end
	if row.verified and value == row.expected then
		if not details then return "passed" end
		local message = row.evidence or ""
		if type(value) == "number" and not message:find(plainText.ValueLabel(var, option, value), 1, true) then
			message = message .. "\nPoB uses " .. plainText.ValueLabel(var, option, value) .. "."
		end
		return "passed", label, ((message .. (countText or "") .. row.measurements):gsub("^\n", ""))
	end
	if isDefault then return end
	if row.certain and row.expected ~= nil and row.expected ~= value then
		if not details then return "failed" end
		local message = "Your setting is " .. plainText.ValueLabel(var, option, value)
			.. ". PoB found " .. plainText.ValueLabel(var, option, row.expected) .. "."
		if row.evidence then message = message .. "\n" .. row.evidence end
		return "failed", label, message
	end
	if not details then return "review" end
	local lines = { }
	if row.expected ~= nil and row.expected ~= value then
		t_insert(lines, "Your setting is " .. plainText.ValueLabel(var, option, value)
			.. ". Try " .. plainText.ValueLabel(var, option, row.expected) .. " for this fight.")
	end
	if row.evidence then t_insert(lines, row.evidence) end
	t_insert(lines, row.measurements == "" and row.explanation or row.measurements:sub(2))
	return "review", label, t_concat(lines, "\n")
end

return M
