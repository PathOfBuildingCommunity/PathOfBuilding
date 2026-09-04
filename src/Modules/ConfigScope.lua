-- Path of Building
--
-- Module: Config Scope
-- Classifies Configuration options as shared (encounter), actor, or player-only.
-- Enemy/encounter state is shared. Source attribution exists only for mechanics
-- whose wording depends on the originating actor ("by you", "you have inflicted",
-- source-specific hit conditions, and equivalent actor-sensitive semantics).
--
-- Runtime bootstrap: Classes/ConfigTab.lua calls ConfigScope.index(ConfigOptions).
-- Querying before a successful index(), or looking up a name that was not indexed,
-- is an error. Legacy XML keys that are no longer in ConfigOptions should use tryForVar().
--
-- Options inherit their section's scope unless they set `scope` explicitly. Naming
-- heuristics still detect likely section overrides so a new option cannot silently
-- change actor vs encounter ownership; those cases require explicit metadata.
-- Enemy predicates (ifEnemyCond / ifEnemyMult / ifEnemyStat) and ByYou/ByYour
-- names likewise require explicit enemyState so a game update cannot silently
-- share a new source-owned condition.
--
local ConfigScope = { }

local PLAYER_VARS = {
	resistancePenalty = true,
	bandit = true,
	pantheonMajorGod = true,
	pantheonMinorGod = true,
	ignoreItemDisablers = true,
	ignoreJewelLimits = true,
}

-- Enemy conditions/multipliers whose wording establishes source ownership.
-- Each actor evaluates these against its own overlay; resulting encounter effects
-- (Shock, Exposure, increased damage taken, ...) are published to shared enemy state.
local SOURCE_OWNED_ENEMY_VARS = {
	ChilledByYou = true,
	ChilledByYourHits = true,
	FrozenByYou = true,
	ChilledByYouSeconds = true,
	FrozenByYouSeconds = true,
	BetweenYouAndLinkedTarget = true,
	NearLinkedTarget = true,
	ChampionIntimidate = true,
	HigherLifePercentThanPlayer = true,
	HitByFireDamage = true,
	HitByColdDamage = true,
	HitByLightningDamage = true,
}

-- Actor flags that only apply while that actor's hits have chilled the enemy.
-- These mods do not tag ChilledByYourHits themselves, so usage must be implied
-- for Config visibility and overlay gating.
local CHILL_BY_HITS_EFFECT_FLAGS = {
	ChillEffectIncDamageTaken = true,
	ChillEffectIncColdDamageTaken = true,
	ChillEffectLessDamageDealt = true,
}

local scopeByVar = { }
local enemyStateByVar = { }
local indexedSourceOwned = { }
local indexed = false

local SOURCE_OWNED_TAG_TYPES = {
	Condition = true,
	Multiplier = true,
	MultiplierThreshold = true,
	ActorCondition = true,
}

local sourceOwnedNameCache = { }

local function isSourceOwnedName(name)
	if not name then
		return false
	end
	local cached = sourceOwnedNameCache[name]
	if cached ~= nil then
		return cached
	end
	-- "ByYou" is also a prefix of "ByYour".
	local owned = SOURCE_OWNED_ENEMY_VARS[name] or indexedSourceOwned[name] or name:find("ByYou", 1, true) ~= nil
	sourceOwnedNameCache[name] = owned
	return owned
end

local function anySourceOwned(value)
	if type(value) == "table" then
		for _, name in ipairs(value) do
			if isSourceOwnedName(name) then
				return true
			end
		end
		return false
	end
	return isSourceOwnedName(value)
end

function ConfigScope.isSourceOwnedEnemyVar(var)
	return isSourceOwnedName(var)
end

function ConfigScope.isSourceOwnedEnemyMod(mod)
	if not mod or not mod.name then
		return false
	end
	local var = mod.name:match("^Condition:(.+)$") or mod.name:match("^Multiplier:(.+)$")
	return var and isSourceOwnedName(var)
end

-- Encounter statuses that "by you" mods query by the shared ailment name.
-- ModCache stamps sourceOwned on Condition:Ignited (etc.); the player overlay
-- must still see the config checkbox. Mercenary overlays do not copy these.
local ENCOUNTER_OVERLAY_VARS = {
	Blinded = true,
	Bleeding = true,
	Burning = true,
	Brittle = true,
	Chilled = true,
	ChillEffect = true,
	Cursed = true,
	CurseDurationExpired = true,
	CurseExpired = true,
	Debilitated = true,
	Frozen = true,
	Hindered = true,
	Ignited = true,
	ImpaleStacks = true,
	Intimidated = true,
	Maimed = true,
	Marked = true,
	Poisoned = true,
	PoisonStack = true,
	Sapped = true,
	Scorched = true,
	Shocked = true,
	ShockEffect = true,
	["Spider's WebStack"] = true,
	Taunted = true,
	Unnerved = true,
	Withered = true,
	WitheredStack = true,
}

function ConfigScope.shouldCopyEncounterOntoPlayerOverlay(mod)
	if not mod or not mod.name then
		return false
	end
	local var = mod.name:match("^Condition:(.+)$") or mod.name:match("^Multiplier:(.+)$")
	if not var then
		return false
	end
	return isSourceOwnedName(var) or ENCOUNTER_OVERLAY_VARS[var]
end

function ConfigScope.isSourceOwnedEnemyTag(tag)
	if not (tag and SOURCE_OWNED_TAG_TYPES[tag.type]) then
		return false
	end
	-- Stamp the result on the tag. EvalMod hits this per Condition/Multiplier
	-- tag; the classification never changes for a given tag table.
	local cached = tag.sourceOwned
	if cached ~= nil then
		return cached
	end
	local owned = anySourceOwned(tag.var or tag.varList)
	tag.sourceOwned = owned
	return owned
end

function ConfigScope.impliesChilledByYourHits(modName)
	return modName and CHILL_BY_HITS_EFFECT_FLAGS[modName] or false
end

local VALID_ENEMY_STATE = {
	source = true,
	encounter = true,
}

local VALID_SCOPE = {
	shared = true,
	actor = true,
	player = true,
}

local function requireIndexed()
	if not indexed then
		error("ConfigScope queried before index()")
	end
end

local function hasEnemyPredicate(varData)
	return varData.ifEnemyCond or varData.ifEnemyMult or varData.ifEnemyStat
end

local function looksSourceOwned(varData)
	if anySourceOwned(varData.ifEnemyCond) or anySourceOwned(varData.ifEnemyMult) then
		return true
	end
	local var = varData.var or ""
	return var:find("ByYou", 1, true) ~= nil
end

local function registerSourceOwned(value)
	if type(value) == "table" then
		for _, name in ipairs(value) do
			if name then
				indexedSourceOwned[name] = true
			end
		end
	elseif value then
		indexedSourceOwned[value] = true
	end
end

local function inferEnemyState(varData)
	local sourceOwned = looksSourceOwned(varData)
	if varData.enemyState then
		if not VALID_ENEMY_STATE[varData.enemyState] then
			error("ConfigScope: invalid enemyState '"..tostring(varData.enemyState).."' for "..tostring(varData.var))
		end
		if sourceOwned and varData.enemyState ~= "source" then
			error("ConfigScope: '"..tostring(varData.var).."' looks source-owned and cannot have enemyState '"..varData.enemyState.."'")
		end
		return varData.enemyState
	end
	if sourceOwned or hasEnemyPredicate(varData) then
		error("ConfigScope: '"..tostring(varData.var).."' needs explicit enemyState")
	end
	return "encounter"
end

-- Name/predicate hints that would pull an option off its section default.
-- Returning nil means "use the section scope".
local function heuristicScope(varData)
	local var = varData.var or ""
	if var:match("^playerCursed") then
		return "actor"
	end
	if PLAYER_VARS[var] or var:match("^overrideEmpty") then
		return "player"
	end
	if varData.ifEnemyCond or varData.ifEnemyMult or varData.ifEnemyStat
		or var:match("^enemy") or var:match("^conditionEnemy")
		or var:match("^MapPrefix") or var:match("^MapSuffix")
		or var:match("^multiplierMap") or var == "multiplierSextant" or var == "PvpScaling"
		or var:match("OnEnemy") or var == "ShockStacks" or var == "ScorchStacks"
	then
		return "shared"
	end
	return nil
end

local function inferScope(varData, sectionScope)
	if varData.scope and not VALID_SCOPE[varData.scope] then
		error("ConfigScope: invalid scope '"..tostring(varData.scope).."' for "..tostring(varData.var))
	end
	-- Source-owned enemy predicates are per-actor even if a section default is shared.
	if inferEnemyState(varData) == "source" then
		if varData.scope and varData.scope ~= "actor" then
			error("ConfigScope: '"..tostring(varData.var).."' is source-owned and cannot have scope '"..varData.scope.."'")
		end
		return "actor"
	end
	if varData.scope then
		return varData.scope
	end
	local guessed = heuristicScope(varData)
	if guessed and guessed ~= sectionScope then
		error("ConfigScope: '"..tostring(varData.var).."' needs explicit scope (heuristic '"..guessed.."' vs section '"..tostring(sectionScope).."')")
	end
	return sectionScope or "actor"
end

function ConfigScope.index(varList)
	indexed = false
	scopeByVar = { }
	enemyStateByVar = { }
	indexedSourceOwned = { }
	sourceOwnedNameCache = { }
	if varList == nil then
		error("ConfigScope.index requires a config option list")
	end
	local sectionScope = "actor"
	for _, varData in ipairs(varList) do
		if varData.section then
			if not varData.scope then
				error("ConfigScope: section '"..tostring(varData.section).."' needs explicit scope")
			elseif not VALID_SCOPE[varData.scope] then
				error("ConfigScope: invalid scope '"..tostring(varData.scope).."' for section "..tostring(varData.section))
			end
			sectionScope = varData.scope
		end
		if varData.var then
			local enemyState = inferEnemyState(varData)
			local scope = inferScope(varData, sectionScope)
			scopeByVar[varData.var] = scope
			enemyStateByVar[varData.var] = enemyState
			varData.resolvedScope = scope
			varData.resolvedEnemyState = enemyState
			if enemyState == "source" then
				registerSourceOwned(varData.ifEnemyCond)
				registerSourceOwned(varData.ifEnemyMult)
			end
		end
	end
	indexed = true
	-- Names registered as source-owned during this pass must not keep
	-- a false negative from an earlier option's lookup.
	sourceOwnedNameCache = { }
end

function ConfigScope.tryForVar(var)
	requireIndexed()
	if not var then
		return nil
	end
	return scopeByVar[var]
end

function ConfigScope.tryEnemyStateForVar(var)
	requireIndexed()
	if not var then
		return nil
	end
	return enemyStateByVar[var]
end

function ConfigScope.forVar(var)
	local scope = ConfigScope.tryForVar(var)
	if not scope then
		error("ConfigScope: unknown config var '"..tostring(var).."'")
	end
	return scope
end

function ConfigScope.forVarData(varData)
	if varData and varData.resolvedScope then
		return varData.resolvedScope
	end
	if varData and varData.var then
		return ConfigScope.forVar(varData.var)
	end
	return nil
end

function ConfigScope.enemyStateForVar(var)
	local enemyState = ConfigScope.tryEnemyStateForVar(var)
	if not enemyState then
		error("ConfigScope: unknown config var '"..tostring(var).."'")
	end
	return enemyState
end

function ConfigScope.enemyStateForVarData(varData)
	if varData and varData.resolvedEnemyState then
		return varData.resolvedEnemyState
	end
	if varData and varData.var then
		return ConfigScope.enemyStateForVar(varData.var)
	end
	return nil
end

function ConfigScope.isIndexed()
	return indexed
end

return ConfigScope
