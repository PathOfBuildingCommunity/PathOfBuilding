-- Path of Building
--
-- Module: Calc Setup
-- Initialises the environment for calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local tempTable1 = { }

-- Initialise modifier database with stats and conditions common to all actors
function calcs.initModDB(env, modDB)
	modDB:NewMod("FireResistMax", "BASE", 75, "Base")
	modDB:NewMod("ColdResistMax", "BASE", 75, "Base")
	modDB:NewMod("LightningResistMax", "BASE", 75, "Base")
	modDB:NewMod("ChaosResistMax", "BASE", 75, "Base")
	modDB:NewMod("TotemFireResistMax", "BASE", 75, "Base")
	modDB:NewMod("TotemColdResistMax", "BASE", 75, "Base")
	modDB:NewMod("TotemLightningResistMax", "BASE", 75, "Base")
	modDB:NewMod("TotemChaosResistMax", "BASE", 75, "Base")
	modDB:NewMod("BlockChanceMax", "BASE", 75, "Base")
	modDB:NewMod("SpellBlockChanceMax", "BASE", 75, "Base")
	modDB:NewMod("SpellDodgeChanceMax", "BASE", 75, "Base")
	modDB:NewMod("ChargeDuration", "BASE", 10, "Base")
	modDB:NewMod("PowerChargesMax", "BASE", 3, "Base")
	modDB:NewMod("FrenzyChargesMax", "BASE", 3, "Base")
	modDB:NewMod("EnduranceChargesMax", "BASE", 3, "Base")
	modDB:NewMod("SiphoningChargesMax", "BASE", 0, "Base")
	modDB:NewMod("ChallengerChargesMax", "BASE", 0, "Base")
	modDB:NewMod("BlitzChargesMax", "BASE", 0, "Base")
	modDB:NewMod("InspirationChargesMax", "BASE", 5, "Base")
	modDB:NewMod("CrabBarriersMax", "BASE", 0, "Base")
	modDB:NewMod("BrutalChargesMax", "BASE", 0, "Base")
	modDB:NewMod("AbsorptionChargesMax", "BASE", 0, "Base")
	modDB:NewMod("AfflictionChargesMax", "BASE", 0, "Base")
	modDB:NewMod("BloodChargesMax", "BASE", 5, "Base")
	modDB:NewMod("MaxLifeLeechRate", "BASE", 20, "Base")
	modDB:NewMod("MaxManaLeechRate", "BASE", 20, "Base")
	modDB:NewMod("ImpaleStacksMax", "BASE", 5, "Base")
	modDB:NewMod("BleedStacksMax", "BASE", 1, "Base")
	modDB:NewMod("MaxEnergyShieldLeechRate", "BASE", 10, "Base")
	modDB:NewMod("MaxLifeLeechInstance", "BASE", 10, "Base")
	modDB:NewMod("MaxManaLeechInstance", "BASE", 10, "Base")
	modDB:NewMod("MaxEnergyShieldLeechInstance", "BASE", 10, "Base")
	modDB:NewMod("TrapThrowingTime", "BASE", 0.6, "Base")
	modDB:NewMod("MineLayingTime", "BASE", 0.3, "Base")
	modDB:NewMod("WarcryCastTime", "BASE", 0.8, "Base")
	modDB:NewMod("TotemPlacementTime", "BASE", 0.6, "Base")
	modDB:NewMod("BallistaPlacementTime", "BASE", 0.35, "Base")
	modDB:NewMod("ActiveTotemLimit", "BASE", 1, "Base")
	modDB:NewMod("MovementSpeed", "INC", -30, "Base", { type = "Condition", var = "Maimed" })
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Attack, { type = "Condition", var = "Intimidated"})
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Attack, { type = "Condition", var = "Intimidated", neg = true}, { type = "Condition", var = "Party:Intimidated"})
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Spell, { type = "Condition", var = "Unnerved"})
	modDB:NewMod("DamageTaken", "INC", 10, "Base", ModFlag.Spell, { type = "Condition", var = "Unnerved", neg = true}, { type = "Condition", var = "Party:Unnerved"})
	modDB:NewMod("Damage", "MORE", -10, "Base", { type = "Condition", var = "Debilitated"})
	modDB:NewMod("Condition:Burning", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "Condition", var = "Ignited" })
	modDB:NewMod("Condition:Poisoned", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "MultiplierThreshold", var = "PoisonStack", threshold = 1 })
	modDB:NewMod("Blind", "FLAG", true, "Base", { type = "Condition", var = "Blinded" })
	modDB:NewMod("Chill", "FLAG", true, "Base", { type = "Condition", var = "Chilled" })
	modDB:NewMod("Freeze", "FLAG", true, "Base", { type = "Condition", var = "Frozen" })
	modDB:NewMod("Fortify", "FLAG", true, "Base", { type = "Condition", var = "Fortify" })
	modDB:NewMod("Fortified", "FLAG", true, "Base", { type = "Condition", var = "Fortified" })
	modDB:NewMod("Fanaticism", "FLAG", true, "Base", { type = "Condition", var = "Fanaticism" })
	modDB:NewMod("Onslaught", "FLAG", true, "Base", { type = "Condition", var = "Onslaught" })
	modDB:NewMod("UnholyMight", "FLAG", true, "Base", { type = "Condition", var = "UnholyMight" })
	modDB:NewMod("Tailwind", "FLAG", true, "Base", { type = "Condition", var = "Tailwind" })
	modDB:NewMod("Adrenaline", "FLAG", true, "Base", { type = "Condition", var = "Adrenaline" })
	modDB:NewMod("LesserMassiveShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserMassiveShrine" })
	modDB:NewMod("LesserBrutalShrine", "FLAG", true, "Base", { type = "Condition", var = "LesserBrutalShrine" })
	modDB:NewMod("DiamondShrine", "FLAG", true, "Base", { type = "Condition", var = "DiamondShrine" })
	modDB:NewMod("MassiveShrine", "FLAG", true, "Base", { type = "Condition", var = "MassiveShrine" })
	modDB:NewMod("AlchemistsGenius", "FLAG", true, "Base", { type = "Condition", var = "AlchemistsGenius" })
	modDB:NewMod("LuckyHits", "FLAG", true, "Base", { type = "Condition", var = "LuckyHits" })
	modDB:NewMod("Convergence", "FLAG", true, "Base", { type = "Condition", var = "Convergence" })
	modDB:NewMod("PhysicalDamageReduction", "BASE", -15, "Base", { type = "Condition", var = "Crushed" })
	modDB:NewMod("CritChanceCap", "BASE", 100, "Base")
	modDB.conditions["Buffed"] = env.mode_buffs
	modDB.conditions["Combat"] = env.mode_combat
	modDB.conditions["Effective"] = env.mode_effective
end

function calcs.buildModListForNode(env, node)
	local modList = new("ModList")
	if node.type == "Keystone" then
		modList:AddMod(node.keystoneMod)
	else
		modList:AddList(node.modList)
	end

	-- Run first pass radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		if rad.type == "Other" and rad.nodes[node.id] and rad.nodes[node.id].type ~= "Mastery" then
			rad.func(node, modList, rad.data)
		end
	end

	if modList:Flag(nil, "PassiveSkillHasNoEffect") or (env.allocNodes[node.id] and modList:Flag(nil, "AllocatedPassiveSkillHasNoEffect")) then
		wipeTable(modList)
	end

	-- Apply effect scaling
	local scale = calcLib.mod(modList, nil, "PassiveSkillEffect")
	if scale ~= 1 then
		local scaledList = new("ModList")
		scaledList:ScaleAddList(modList, scale)
		modList = scaledList
	end

	-- Run second pass radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		if rad.nodes[node.id] and rad.nodes[node.id].type ~= "Mastery" and (rad.type == "Threshold" or (rad.type == "Self" and env.allocNodes[node.id]) or (rad.type == "SelfUnalloc" and not env.allocNodes[node.id])) then
			rad.func(node, modList, rad.data)
		end
	end

	if modList:Flag(nil, "PassiveSkillHasOtherEffect") then
		for i, mod in ipairs(modList:List(skillCfg, "NodeModifier")) do
			if i == 1 then wipeTable(modList) end
			modList:AddMod(mod.mod)
		end
	end

	node.grantedSkills = { }
	for _, skill in ipairs(modList:List(nil, "ExtraSkill")) do
		if skill.name ~= "Unknown" then
			t_insert(node.grantedSkills, {
				skillId = skill.skillId,
				level = skill.level,
				noSupports = true,
				source = "Tree:"..node.id
			})
		end
	end

	if modList:Flag(nil, "CanExplode") then
		t_insert(env.explodeSources, node)
	end

	return modList
end

-- Build list of modifiers from the listed tree nodes
function calcs.buildModListForNodeList(env, nodeList, finishJewels)
	-- Initialise radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		wipeTable(rad.data)
		rad.data.modSource = "Tree:"..rad.nodeId
	end

	-- Add node modifiers
	local modList = new("ModList")
	for _, node in pairs(nodeList) do
		local nodeModList = calcs.buildModListForNode(env, node)
		modList:AddList(nodeModList)
		if env.mode == "MAIN" then
			node.finalModList = nodeModList
		end
	end

	if finishJewels then
		-- Process extra radius nodes; these are unallocated nodes near conversion or threshold jewels that need to be processed
		for _, node in pairs(env.extraRadiusNodeList) do
			local nodeModList = calcs.buildModListForNode(env, node)
			if env.mode == "MAIN" then
				node.finalModList = nodeModList
			end
		end

		-- Finalise radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			rad.func(nil, modList, rad.data)
			if env.mode == "MAIN" then
				if not rad.item.jewelRadiusData then
					rad.item.jewelRadiusData = { }
				end
				rad.item.jewelRadiusData[rad.nodeId] = rad.data
			end
		end
	end

	return modList
end

function wipeEnv(env, accelerate)
	-- Always wipe the below as we will be pushing in the modifiers,
	-- multipliers and conditions for player and enemy DBs via `parent`
	-- extensions of those DBs later which allow us to do a table-pointer
	-- link and save time on having to do a copyTable() function.
	wipeTable(env.modDB.mods)
	wipeTable(env.modDB.conditions)
	wipeTable(env.modDB.multipliers)
	wipeTable(env.enemyDB.mods)
	wipeTable(env.enemyDB.conditions)
	wipeTable(env.enemyDB.multipliers)
	if env.minion then
		wipeTable(env.minion.modDB.mods)
		wipeTable(env.minion.modDB.conditions)
		wipeTable(env.minion.modDB.multipliers)
	end

	if accelerate.everything then
		return
	end

	-- Passive tree node allocations
	-- Also in a further pass tracks Legion influenced mods
	if not accelerate.nodeAlloc then
		wipeTable(env.allocNodes)
		-- Usually states: `Allocates <NAME>` (e.g., amulet anointment)
		wipeTable(env.grantedPassives)
		wipeTable(env.grantedSkillsNodes)
	end

	if not accelerate.requirementsItems then
		-- Item-related tables
		wipeTable(env.itemModDB.mods)
		wipeTable(env.itemModDB.conditions)
		wipeTable(env.itemModDB.multipliers)
		-- 1) Jewels and Jewel-Radius related node modifications
		-- 2) Player items
		-- 3) Granted Skill from items (e.g., Curse on Hit rings)
		-- 4) Flasks
		wipeTable(env.radiusJewelList)
		wipeTable(env.extraRadiusNodeList)
		wipeTable(env.player.itemList)
		wipeTable(env.grantedSkillsItems)
		wipeTable(env.flasks)

		-- Special / Unique Items that have their own ModDB()
		if env.aegisModList then
			wipeTable(env.aegisModList)
		end
		if env.theIronMass then
			wipeTable(env.theIronMass)
		end
		if env.weaponModList1 then
			wipeTable(env.weaponModList1)
		end

		-- Requirements from Items (Str, Dex, Int)
		wipeTable(env.requirementsTableItems)
	end

	-- Requirements from Gems (Str, Dex, Int)
	if not accelerate.requirementsGems then
		wipeTable(env.requirementsTableGems)
	end

	if not accelerate.skills then
		-- Player Active Skills generation
		wipeTable(env.player.activeSkillList)

		-- Enhances Active Skills with skill ModFlags, KeywordFlags
		-- and modifiers that affect skill scaling (e.g., global buffs/effects)
		wipeTable(env.auxSkillList)
	end
end

local function getGemModList(env, groupCfg, socketColor, socketNum)
	local gemCfg = copyTable(groupCfg, true)
	gemCfg.socketColor = socketColor
	gemCfg.socketNum = socketNum
	return env.modDB:List(gemCfg, "GemProperty")
end

local function applyGemMods(effect, modList)
	for _, value in ipairs(modList) do
		local match = true
		if value.keywordList then
			for _, keyword in ipairs(value.keywordList) do
				if not calcLib.gemIsType(effect.gemData, keyword, true) then
					match = false
					break
				end
			end
		elseif not calcLib.gemIsType(effect.gemData, value.keyword, true) then
			match = false
		end
		if match then
			effect[value.key] = (effect[value.key] or 0) + value.value
		end
	end
end

local function applySocketMods(env, gem, groupCfg, socketNum, modSource)
	local socketCfg = copyTable(groupCfg, true)
	socketCfg.skillGem = gem
	socketCfg.socketNum = socketNum
	for _, value in ipairs(env.modDB:List(socketCfg, "SocketProperty")) do
		env.player.modDB:AddMod(modLib.setSource(value.value, modSource or groupCfg.slotName or ""))
	end
end

local function addBestSupport(supportEffect, appliedSupportList, mode)
	local add = true
	for index, otherSupport in ipairs(appliedSupportList) do
		-- Check if there's another better support already present
		if supportEffect.grantedEffect == otherSupport.grantedEffect then
			add = false
			if supportEffect.level > otherSupport.level or (supportEffect.level == otherSupport.level and supportEffect.quality > otherSupport.quality) then
				if mode == "MAIN" then
					otherSupport.superseded = true
				end
				appliedSupportList[index] = supportEffect
			else
				supportEffect.superseded = true
			end
			break
		elseif supportEffect.grantedEffect.plusVersionOf == otherSupport.grantedEffect.id then
			add = false
			if mode == "MAIN" then
				otherSupport.superseded = true
			end
			appliedSupportList[index] = supportEffect
		elseif otherSupport.grantedEffect.plusVersionOf == supportEffect.grantedEffect.id then
			add = false
			supportEffect.superseded = true
		end
	end
	if add then
		t_insert(appliedSupportList, supportEffect)
	end
end

-- Initialise environment:
-- 1. Initialises the player and enemy modifier databases
-- 2. Merges modifiers for all items
-- 3. Builds a list of jewels with radius functions
-- 4. Merges modifiers for all allocated passive nodes
-- 5. Builds a list of active skills and their supports (calcs.createActiveSkill)
-- 6. Builds modifier lists for all active skills (calcs.buildActiveSkillModList)
function calcs.initEnv(build, mode, override, specEnv)
	-- accelerator variables
	local cachedPlayerDB = specEnv and specEnv.cachedPlayerDB or nil
	local cachedEnemyDB = specEnv and specEnv.cachedEnemyDB or nil
	local cachedMinionDB = specEnv and specEnv.cachedMinionDB or nil
	local env = specEnv and specEnv.env or nil
	local accelerate = specEnv and specEnv.accelerate or { }

	-- environment variables
	local override = override or { }
	local modDB = nil
	local enemyDB = nil
	local classStats = nil

	if not env then
		env = { }
		env.build = build
		env.data = build.data
		env.configInput = build.configTab.input
		env.configPlaceholder = build.configTab.placeholder
		env.calcsInput = build.calcsTab.input
		env.mode = mode
		env.spec = override.spec or build.spec
		env.classId = env.spec.curClassId

		modDB = new("ModDB")
		env.modDB = modDB
		enemyDB = new("ModDB")
		env.enemyDB = enemyDB
		env.itemModDB = new("ModDB")

		env.enemyLevel = build.configTab.enemyLevel or m_min(data.misc.MaxEnemyLevel, build.characterLevel)

		-- Create player/enemy actors
		env.player = {
			modDB = env.modDB,
			level = build.characterLevel,
		}
		env.modDB.actor = env.player
		env.enemy = {
			modDB = env.enemyDB,
			level = env.enemyLevel,
		}
		enemyDB.actor = env.enemy
		env.player.enemy = env.enemy
		env.enemy.enemy = env.player
		enemyDB.actor.player = env.player
		env.modDB.actor.player = env.player

		-- Set up requirements tracking
		env.requirementsTableItems = { }
		env.requirementsTableGems = { }

		-- Prepare item, skill, flask tables
		env.radiusJewelList = wipeTable(env.radiusJewelList)
		env.extraRadiusNodeList = wipeTable(env.extraRadiusNodeList)
		env.player.itemList = { }
		env.grantedSkills = { }
		env.grantedSkillsNodes = { }
		env.grantedSkillsItems = { }
		env.explodeSources = { }
		env.itemWarnings = { }
		env.flasks = { }

		-- tree based
		env.grantedPassives = { }

		-- skill-related
		env.player.activeSkillList = { }
		env.auxSkillList = { }
	--elseif accelerate.everything then
	--	local minionDB = nil
	--	env.modDB.parent, env.enemyDB.parent, minionDB = specCopy(env)
	--	if minionDB then
	--		env.minion.modDB.parent = minionDB
	--	end
	--	wipeEnv(env, accelerate)
	else
		wipeEnv(env, accelerate)
		modDB = env.modDB
		enemyDB = env.enemyDB
	end

	-- Set buff mode
	local buffMode
	if mode == "CALCS" then
		buffMode = env.calcsInput.misc_buffMode
	else
		buffMode = "EFFECTIVE"
	end
	if buffMode == "EFFECTIVE" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = true
	elseif buffMode == "COMBAT" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = false
	elseif buffMode == "BUFFED" then
		env.mode_buffs = true
		env.mode_combat = false
		env.mode_effective = false
	else
		env.mode_buffs = false
		env.mode_combat = false
		env.mode_effective = false
	end
	classStats = env.spec.tree.characterData and env.spec.tree.characterData[env.classId] or env.spec.tree.classes[env.classId]

	if not cachedPlayerDB then
		-- Initialise modifier database with base values
		for _, stat in pairs({"Str","Dex","Int"}) do
			modDB:NewMod(stat, "BASE", classStats["base_"..stat:lower()], "Base")
		end
		modDB.multipliers["Level"] = m_max(1, m_min(100, build.characterLevel))
		calcs.initModDB(env, modDB)
		modDB:NewMod("Life", "BASE", 12, "Base", { type = "Multiplier", var = "Level", base = 38 })
		modDB:NewMod("Mana", "BASE", 6, "Base", { type = "Multiplier", var = "Level", base = 34 })
		modDB:NewMod("ManaRegen", "BASE", 0.0175, "Base", { type = "PerStat", stat = "Mana", div = 1 })
		modDB:NewMod("Devotion", "BASE", 0, "Base")
		modDB:NewMod("Evasion", "BASE", 15, "Base")
		modDB:NewMod("Accuracy", "BASE", 2, "Base", { type = "Multiplier", var = "Level", base = -2 })
		modDB:NewMod("CritMultiplier", "BASE", 50, "Base")
		modDB:NewMod("DotMultiplier", "BASE", 50, "Base", { type = "Condition", var = "CriticalStrike" })
		modDB:NewMod("FireResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("ColdResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("LightningResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("ChaosResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
		modDB:NewMod("TotemFireResist", "BASE", 40, "Base")
		modDB:NewMod("TotemColdResist", "BASE", 40, "Base")
		modDB:NewMod("TotemLightningResist", "BASE", 40, "Base")
		modDB:NewMod("TotemChaosResist", "BASE", 20, "Base")
		modDB:NewMod("CritChance", "INC", 50, "Base", { type = "Multiplier", var = "PowerCharge" })
		modDB:NewMod("Speed", "INC", 4, "Base", ModFlag.Attack, { type = "Multiplier", var = "FrenzyCharge" })
		modDB:NewMod("Speed", "INC", 4, "Base", ModFlag.Cast, { type = "Multiplier", var = "FrenzyCharge" })
		modDB:NewMod("Damage", "MORE", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		modDB:NewMod("PhysicalDamageReduction", "BASE", 4, "Base", { type = "Multiplier", var = "EnduranceCharge" })
		modDB:NewMod("ElementalResist", "BASE", 4, "Base", { type = "Multiplier", var = "EnduranceCharge" })
		modDB:NewMod("Multiplier:RageEffect", "BASE", 1, "Base")
		modDB:NewMod("Damage", "INC", 1, "Base", ModFlag.Attack, { type = "Multiplier", var = "Rage" }, { type = "Multiplier", var = "RageEffect" })
		modDB:NewMod("Speed", "INC", 1, "Base", ModFlag.Attack, { type = "Multiplier", var = "Rage", div = 2 }, { type = "Multiplier", var = "RageEffect" })
		modDB:NewMod("MovementSpeed", "INC", 1, "Base", { type = "Multiplier", var = "Rage", div = 5 }, { type = "Multiplier", var = "RageEffect" })
		modDB:NewMod("MaximumRage", "BASE", 50, "Base")
		modDB:NewMod("Multiplier:GaleForce", "BASE", 0, "Base")
		modDB:NewMod("MaximumGaleForce", "BASE", 10, "Base")
		modDB:NewMod("MaximumFortification", "BASE", 20, "Base")
		modDB:NewMod("Multiplier:IntensityLimit", "BASE", 3, "Base")
		modDB:NewMod("Damage", "INC", 2, "Base", { type = "Multiplier", var = "Rampage", limit = 50, div = 20 })
		modDB:NewMod("MovementSpeed", "INC", 1, "Base", { type = "Multiplier", var = "Rampage", limit = 50, div = 20 })
		modDB:NewMod("Speed", "INC", 5, "Base", ModFlag.Attack, { type = "Multiplier", var = "SoulEater"})
		modDB:NewMod("Speed", "INC", 5, "Base", ModFlag.Cast, { type = "Multiplier", var = "SoulEater" })
		modDB:NewMod("ActiveTrapLimit", "BASE", 15, "Base")
		modDB:NewMod("ActiveMineLimit", "BASE", 15, "Base")
		modDB:NewMod("ActiveBrandLimit", "BASE", 3, "Base")
		modDB:NewMod("EnemyCurseLimit", "BASE", 1, "Base")
		modDB:NewMod("SocketedCursesHexLimitValue", "BASE", 1, "Base")
		modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
		modDB:NewMod("Speed", "MORE", 10, "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "DoubledInherentSpeed", neg = true })
		modDB:NewMod("Speed", "MORE", 20, "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "DoubledInherentSpeed"})
		modDB:NewMod("BlockChance", "BASE", 15, "Base", { type = "Condition", var = "DualWielding" }, { type = "Condition", var = "NoInherentBlock", neg = true})
		modDB:NewMod("Damage", "MORE", 200, "Base", 0, KeywordFlag.Bleed, { type = "ActorCondition", actor = "enemy", var = "Moving" }, { type = "Condition", var = "NoExtraBleedDamageToMovingEnemy", neg = true })
		modDB:NewMod("Condition:BloodStance", "FLAG", true, "Base", { type = "Condition", var = "SandStance", neg = true })
		modDB:NewMod("Condition:PrideMinEffect", "FLAG", true, "Base", { type = "Condition", var = "PrideMaxEffect", neg = true })
		modDB:NewMod("PerBrutalTripleDamageChance", "BASE", 3, "Base")
		modDB:NewMod("PerAfflictionAilmentDamage", "BASE", 8, "Base")
		modDB:NewMod("PerAfflictionNonDamageEffect", "BASE", 8, "Base")
		modDB:NewMod("PerAbsorptionElementalEnergyShieldRecoup", "BASE", 12, "Base")

		-- Add bandit mods
		if env.configInput.bandit == "Alira" then
			modDB:NewMod("ManaRegen", "BASE", 5, "Bandit")
			modDB:NewMod("CritMultiplier", "BASE", 20, "Bandit")
			modDB:NewMod("ElementalResist", "BASE", 15, "Bandit")
		elseif env.configInput.bandit == "Kraityn" then
			modDB:NewMod("Speed", "INC", 6, "Bandit")
			for _, ailment in ipairs(env.data.elementalAilmentTypeList) do
				modDB:NewMod("Avoid"..ailment, "BASE", 10, "Bandit")
			end
			modDB:NewMod("MovementSpeed", "INC", 6, "Bandit")
		elseif env.configInput.bandit == "Oak" then
			modDB:NewMod("LifeRegenPercent", "BASE", 1, "Bandit")
			modDB:NewMod("PhysicalDamageReduction", "BASE", 2, "Bandit")
			modDB:NewMod("PhysicalDamage", "INC", 20, "Bandit")
		else
			modDB:NewMod("ExtraPoints", "BASE", 2, "Bandit")
		end

		-- Add Pantheon mods
		local parser = modLib.parseMod
		-- Major Gods
		if env.configInput.pantheonMajorGod ~= "None" then
			local majorGod = env.data.pantheons[env.configInput.pantheonMajorGod]
			pantheon.applySoulMod(modDB, parser, majorGod)
		end
		-- Minor Gods
		if env.configInput.pantheonMinorGod ~= "None" then
			local minorGod = env.data.pantheons[env.configInput.pantheonMinorGod]
			pantheon.applySoulMod(modDB, parser, minorGod)
		end

		-- Initialise enemy modifier database
		calcs.initModDB(env, enemyDB)
		enemyDB:NewMod("Accuracy", "BASE", env.data.monsterAccuracyTable[env.enemyLevel], "Base")
		enemyDB:NewMod("Condition:AgainstDamageOverTime", "FLAG", true, "Base", ModFlag.Dot, { type = "ActorCondition", actor = "player", var = "Combat" })

		-- Add mods from the config tab
		env.modDB:AddList(build.configTab.modList)
		env.enemyDB:AddList(build.configTab.enemyModList)

		-- Add mods from the party tab
		env.enemyDB:AddList(build.partyTab.enemyModList)

		cachedPlayerDB, cachedEnemyDB, cachedMinionDB = specCopy(env)
	else
		env.modDB.parent = cachedPlayerDB
		env.enemyDB.parent = cachedEnemyDB
		if cachedMinionDB and env.minion then
			env.minion.modDB.parent = cachedMinionDB
		end
	end

	if override.conditions then
		for _, flag in ipairs(override.conditions) do
			modDB.conditions[flag] = true
		end
	end

	local allocatedNotableCount = env.spec.allocatedNotableCount
	local allocatedMasteryCount = env.spec.allocatedMasteryCount
	local allocatedMasteryTypeCount = env.spec.allocatedMasteryTypeCount
	local allocatedMasteryTypes = copyTable(env.spec.allocatedMasteryTypes)



	if not accelerate.nodeAlloc then
		-- Build list of passive nodes
		local nodes
		if override.addNodes or override.removeNodes then
			nodes = { }
			if override.addNodes then
				for node in pairs(override.addNodes) do
					nodes[node.id] = node
					if node.type == "Mastery" then
						allocatedMasteryCount = allocatedMasteryCount + 1

						if not allocatedMasteryTypes[node.name] then
							allocatedMasteryTypes[node.name] = 1
							allocatedMasteryTypeCount = allocatedMasteryTypeCount + 1
						else
							local prevCount = allocatedMasteryTypes[node.name]
							allocatedMasteryTypes[node.name] = prevCount + 1
							if prevCount == 0 then
								allocatedMasteryTypeCount = allocatedMasteryTypeCount + 1
							end
						end
					elseif node.type == "Notable" then
						allocatedNotableCount = allocatedNotableCount + 1
					end
				end
			end
			for _, node in pairs(env.spec.allocNodes) do
				if not override.removeNodes or not override.removeNodes[node] then
					nodes[node.id] = node
				elseif override.removeNodes[node] then
					if node.type == "Mastery" then
						allocatedMasteryCount = allocatedMasteryCount - 1

						allocatedMasteryTypes[node.name] = allocatedMasteryTypes[node.name] - 1
						if allocatedMasteryTypes[node.name] == 0 then
							allocatedMasteryTypeCount = allocatedMasteryTypeCount - 1
						end
					elseif node.type == "Notable" then
						allocatedNotableCount = allocatedNotableCount - 1
					end
				end
			end
		else
			nodes = copyTable(env.spec.allocNodes, true)
		end
		env.allocNodes = nodes
	end

	if allocatedNotableCount and allocatedNotableCount > 0 then
		modDB:NewMod("Multiplier:AllocatedNotable", "BASE", allocatedNotableCount)
	end
	if allocatedMasteryCount and allocatedMasteryCount > 0 then
		modDB:NewMod("Multiplier:AllocatedMastery", "BASE", allocatedMasteryCount)
	end
	if allocatedMasteryTypeCount and allocatedMasteryTypeCount > 0 then
		modDB:NewMod("Multiplier:AllocatedMasteryType", "BASE", allocatedMasteryTypeCount)
	end
	if allocatedMasteryTypes["Life Mastery"] and allocatedMasteryTypes["Life Mastery"] > 0 then
		modDB:NewMod("Multiplier:AllocatedLifeMastery", "BASE", allocatedMasteryTypes["Life Mastery"])
	end

	-- Build and merge item modifiers, and create list of radius jewels
	if not accelerate.requirementsItems then
		local items = {}
		local jewelLimits = {}
		for _, slot in pairs(build.itemsTab.orderedSlots) do
			local slotName = slot.slotName
			local item
			if slotName == override.repSlotName then
				item = override.repItem
			elseif override.repItem and override.repSlotName:match("^Weapon 1") and slotName:match("^Weapon 2") and
			(override.repItem.base.type == "Staff" or override.repItem.base.type == "Two Handed Sword" or override.repItem.base.type == "Two Handed Axe" or override.repItem.base.type == "Two Handed Mace"
			or (override.repItem.base.type == "Bow" and item and item.base.type ~= "Quiver")) then
				item = nil
			elseif slot.nodeId and override.spec then
				item = build.itemsTab.items[env.spec.jewels[slot.nodeId]]
			else
				item = build.itemsTab.items[slot.selItemId]
			end
			if item and item.grantedSkills then
				-- Find skills granted by this item
				for _, skill in ipairs(item.grantedSkills) do
					local skillData = env.data.skills[skill.skillId]
					local grantedSkill = copyTable(skill)
					grantedSkill.nameSpec = skillData and skillData.name or nil
					grantedSkill.sourceItem = item
					grantedSkill.slotName = slotName
					t_insert(env.grantedSkillsItems, grantedSkill)
				end
			end
			if item and item.baseModList and item.baseModList:Flag(nil, "CanExplode") then
				t_insert(env.explodeSources, item)
			end
			if slot.weaponSet and slot.weaponSet ~= (build.itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1) then
				item = nil
			end
			if slot.weaponSet == 2 and build.itemsTab.activeItemSet.useSecondWeaponSet then
				slotName = slotName:gsub(" Swap","")
			end
			if slot.nodeId then
				-- Slot is a jewel socket, check if socket is allocated
				if not env.allocNodes[slot.nodeId] then
					item = nil
				elseif item then
					if item.jewelData then
						item.jewelData.limitDisabled = nil
					end
					if item and item.type == "Jewel" and item.name:match("The Adorned, Crimson Jewel") then
						env.modDB.multipliers["CorruptedMagicJewelEffect"] = item.jewelData.corruptedMagicJewelIncEffect / 100
					end
					if item.limit and not env.configInput.ignoreJewelLimits then
						local limitKey = item.base.subType == "Timeless" and "Historic" or item.title
						if jewelLimits[limitKey] and jewelLimits[limitKey] >= item.limit then
							if item.jewelData then
								item.jewelData.limitDisabled = true
							end
							env.itemWarnings.jewelLimitWarning = env.itemWarnings.jewelLimitWarning or { }
							t_insert(env.itemWarnings.jewelLimitWarning, limitKey)
							item = nil
						else
							jewelLimits[limitKey] = (jewelLimits[limitKey] or 0) + 1
						end
					end
					if item and ( item.jewelRadiusIndex or (override and override.extraJewelFuncs and #override.extraJewelFuncs > 0) ) then
						-- Jewel has a radius, add it to the list
						local funcList = (item.jewelData and item.jewelData.funcList) or { { type = "Self", func = function(node, out, data)
							-- Default function just tallies all stats in radius
							if node then
								for _, stat in pairs({"Str","Dex","Int"}) do
									data[stat] = (data[stat] or 0) + out:Sum("BASE", nil, stat)
								end
							end
						end } }
						for _, func in ipairs(funcList) do
							local node = env.spec.nodes[slot.nodeId]
							t_insert(env.radiusJewelList, {
								nodes = node.nodesInRadius and node.nodesInRadius[item.jewelRadiusIndex] or { },
								func = func.func,
								type = func.type,
								item = item,
								nodeId = slot.nodeId,
								attributes = node.attributesInRadius and node.attributesInRadius[item.jewelRadiusIndex] or { },
								data = { }
							})
							if func.type ~= "Self" and node.nodesInRadius then
								-- Add nearby unallocated nodes to the extra node list
								for nodeId, node in pairs(node.nodesInRadius[item.jewelRadiusIndex]) do
									if not env.allocNodes[nodeId] then
										env.extraRadiusNodeList[nodeId] = env.spec.nodes[nodeId]
									end
								end
							end
						end
						for _, funcData in ipairs(override and override.extraJewelFuncs and override.extraJewelFuncs:List({item = item}, "ExtraJewelFunc") or {}) do
							local node = env.spec.nodes[slot.nodeId]
							local radius
							for index, data in pairs(data.jewelRadius) do
								if funcData.radius == data.label then
									radius = index
									break
								end
							end
							t_insert(env.radiusJewelList, {
								nodes = node.nodesInRadius and node.nodesInRadius[radius] or { },
								func = funcData.func,
								type = funcData.type,
								item = item,
								nodeId = slot.nodeId,
								attributes = node.attributesInRadius and node.attributesInRadius[radius] or { },
								data = { }
							})
							if funcData.type ~= "Self" and node.nodesInRadius then
								-- Add nearby unallocated nodes to the extra node list
								for nodeId, node in pairs(node.nodesInRadius[radius]) do
									if not env.allocNodes[nodeId] then
										env.extraRadiusNodeList[nodeId] = env.spec.nodes[nodeId]
									end
								end
							end
						end
					end
				end
			end
			items[slotName] = item
		end

		if not env.configInput.ignoreItemDisablers then
			local itemDisabled = {}
			local itemDisablers = {}
			if modDB:Flag(nil, "CanNotUseHelm") then
				itemDisabled["Helmet"] = { disabled = true, size = 1 }
			end
			for _, slot in pairs(build.itemsTab.orderedSlots) do
				local slotName = slot.slotName
				if items[slotName] then
					local srcList = items[slotName].modList or items[slotName].slotModList[slot.slotNum]
					for _, mod in ipairs(srcList) do
						-- checks if it disables another slot
						for _, tag in ipairs(mod) do
							if tag.type == "DisablesItem" then
								-- e.g. Tincture in Flask 5 while using a Micro-Distillery Belt
								if tag.excludeItemType and items[tag.slotName] and items[tag.slotName].type == tag.excludeItemType then
									break
								end
								itemDisablers[slotName] = tag.slotName
								itemDisabled[tag.slotName] = slotName
								break
							end
						end
					end
				end
			end
			local visited = {}
			local trueDisabled = {}
			for slot in pairs(itemDisablers) do
				if not visited[slot] then
					-- find chain start
					local curChain = { slot = true }
					while itemDisabled[slot] do
						slot = itemDisabled[slot]
						if curChain[slot] then break end -- detect cycles
						curChain[slot] = true
					end

					-- step through the chain of disabled items, disabling every other one
					repeat
						visited[slot] = true
						slot = itemDisablers[slot]
						if not slot then break end
						visited[slot] = true
						trueDisabled[slot] = true
						slot = itemDisablers[slot]
					until(not slot or visited[slot])
				end
			end
			for slot in pairs(trueDisabled) do
				items[slot] = nil
			end
		end

		for _, slot in pairs(build.itemsTab.orderedSlots) do
			local slotName = slot.slotName
			local item = items[slotName]
			if item and item.type == "Flask" then
				if slot.active then
					env.flasks[item] = true
				end
				if item.base.subType == "Life" then
					local highestLifeRecovery = env.itemModDB.multipliers["LifeFlaskRecovery"] or 0
					if item.flaskData.lifeTotal > highestLifeRecovery then
						env.itemModDB.multipliers["LifeFlaskRecovery"] = item.flaskData.lifeTotal
					end
				end
				item = nil
			end
			local scale = 1
			if item and item.type == "Jewel" and item.base.subType == "Abyss" and slot.parentSlot then
				-- Check if the item in the parent slot has enough Abyssal Sockets
				local parentItem = env.player.itemList[slot.parentSlot.slotName]
				if not parentItem or parentItem.abyssalSocketCount < slot.slotNum then
					item = nil
				else
					scale = parentItem.socketedJewelEffectModifier
				end
			end
			if slot.nodeId and item and item.type == "Jewel" and item.jewelData and item.jewelData.jewelIncEffectFromClassStart then
				local node = env.spec.nodes[slot.nodeId]
				if node and node.distanceToClassStart then
					scale = scale + node.distanceToClassStart * (item.jewelData.jewelIncEffectFromClassStart / 100)
				end
			end
			if item then
				env.player.itemList[slotName] = item
				-- Merge mods for this item
				local srcList = item.modList or (item.slotModList and item.slotModList[slot.slotNum]) or {}
				if item.requirements and not accelerate.requirementsItems then
					t_insert(env.requirementsTableItems, {
						source = "Item",
						sourceItem = item,
						sourceSlot = slotName,
						Str = item.requirements.strMod,
						Dex = item.requirements.dexMod,
						Int = item.requirements.intMod,
					})
				end
				if item.type == "Jewel" and item.base.subType == "Abyss" then
					-- Update Abyss Jewel conditions/multipliers
					local cond = "Have"..item.baseName:gsub(" ","")
					if not env.itemModDB.conditions[cond] then
						env.itemModDB.conditions[cond] = true
						env.itemModDB.multipliers["AbyssJewelType"] = (env.itemModDB.multipliers["AbyssJewelType"] or 0) + 1
					end
					if slot.parentSlot then
						env.itemModDB.conditions[cond.."In"..slot.parentSlot.slotName] = true
					end
					env.itemModDB.multipliers["AbyssJewel"] = (env.itemModDB.multipliers["AbyssJewel"] or 0) + 1
					if item.rarity == "NORMAL" then env.itemModDB.multipliers["NormalAbyssJewels"] = (env.itemModDB.multipliers["NormalAbyssJewels"] or 0) + 1 end
					if item.rarity == "MAGIC" then env.itemModDB.multipliers["MagicAbyssJewels"] = (env.itemModDB.multipliers["MagicAbyssJewels"] or 0) + 1 end
					if item.rarity == "RARE" then env.itemModDB.multipliers["RareAbyssJewels"] = (env.itemModDB.multipliers["RareAbyssJewels"] or 0) + 1 end
					if item.rarity == "UNIQUE" or item.rarity == "RELIC" then env.itemModDB.multipliers["UniqueAbyssJewels"] = (env.itemModDB.multipliers["UniqueAbyssJewels"] or 0) + 1 end
					env.itemModDB.multipliers[item.baseName:gsub(" ","")] = (env.itemModDB.multipliers[item.baseName:gsub(" ","")] or 0) + 1
				end
				if item.type == "Shield" and env.allocNodes[45175] and env.allocNodes[45175].dn == "Necromantic Aegis" then
					-- Special handling for Necromantic Aegis
					env.aegisModList = new("ModList")
					for _, mod in ipairs(srcList) do
						-- Filter out mods that apply to socketed gems, or which add supports
						local add = true
						for _, tag in ipairs(mod) do
							if tag.type == "SocketedIn" then
								add = false
								break
							end
						end
						if add then
							env.aegisModList:ScaleAddMod(mod, scale)
						else
							env.itemModDB:ScaleAddMod(mod, scale)
						end
					end
				elseif (slotName == "Weapon 1" or slotName == "Weapon 2") and modDB.conditions["AffectedByEnergyBlade"] then
					local previousItem = env.player.itemList[slotName]
					local type = previousItem and previousItem.weaponData and previousItem.weaponData[1].type
					local info = env.data.weaponTypeInfo[type]
					if info and type ~= "Bow" then
						local name = info.oneHand and "Energy Blade One Handed" or "Energy Blade Two Handed"
						local item = new("Item")
						item.name = name
						item.base = data.itemBases[name]
						item.baseName = name
						item.classRequirementModLines = { }
						item.buffModLines = { }
						item.enchantModLines = { }
						item.scourgeModLines = { }
						item.implicitModLines = { }
						item.explicitModLines = { }
						item.crucibleModLines = { }
						item.quality = 0
						item.rarity = "NORMAL"
						if item.baseName.implicit then
							local implicitIndex = 1
							for line in item.baseName.implicit:gmatch("[^\n]+") do
								local modList, extra = modLib.parseMod(line)
								t_insert(item.implicitModLines, { line = line, extra = extra, modList = modList or { }, modTags = item.baseName.implicitModTypes and item.baseName.implicitModTypes[implicitIndex] or { } })
								implicitIndex = implicitIndex + 1
							end
						end
						item:NormaliseQuality()
						item:BuildAndParseRaw()
						item.sockets = previousItem.sockets
						item.abyssalSocketCount = previousItem.abyssalSocketCount
						env.player.itemList[slotName] = item
					else
						env.itemModDB:ScaleAddList(srcList, scale)
					end
				elseif slotName == "Weapon 1" and item.name == "The Iron Mass, Gladius" then
					-- Special handling for The Iron Mass
					env.theIronMass = new("ModList")
					for _, mod in ipairs(srcList) do
						-- Filter out mods that apply to socketed gems, or which add supports
						local add = true
						for _, tag in ipairs(mod) do
							if tag.type == "SocketedIn" then
								add = false
								break
							end
						end
						if add then
							env.theIronMass:ScaleAddMod(mod, scale)
						end
						-- Add all the stats to player as well
						env.itemModDB:ScaleAddMod(mod, scale)
					end
				elseif slotName == "Weapon 1" and item.grantedSkills[1] and item.grantedSkills[1].skillId == "UniqueAnimateWeapon" then
					-- Special handling for The Dancing Dervish
					env.weaponModList1 = new("ModList")
					for _, mod in ipairs(srcList) do
						-- Filter out mods that apply to socketed gems, or which add supports
						local add = true
						for _, tag in ipairs(mod) do
							if tag.type == "SocketedIn" then
								add = false
								break
							end
						end
						if add then
							env.weaponModList1:ScaleAddMod(mod, scale)
						else
							env.itemModDB:ScaleAddMod(mod, scale)
						end
					end
				elseif item.name:match("Kalandra's Touch") then
					local otherRing = (slotName == "Ring 1" and build.itemsTab.items[build.itemsTab.orderedSlots[59].selItemId]) or (slotName == "Ring 2" and build.itemsTab.items[build.itemsTab.orderedSlots[58].selItemId])
					if otherRing and not otherRing.name:match("Kalandra's Touch") then
						local otherRingList = otherRing and copyTable(otherRing.modList or otherRing.slotModList[slot.slotNum]) or {}
						for index, mod in ipairs(otherRingList) do
							modLib.setSource(mod, item.modSource)
							for _, tag in ipairs(mod) do
								if tag.type == "SocketedIn" then
									otherRingList[index] = nil
									break
								end
							end
						end
						env.itemModDB:ScaleAddList(otherRingList, scale)
						for mult, property in pairs({["CorruptedItem"] = "corrupted", ["ShaperItem"] = "shaper", ["ElderItem"] = "elder"}) do
							if otherRing[property] and not item[property] then
								env.itemModDB.multipliers[mult] = (env.itemModDB.multipliers[mult] or 0) + 1
								env.itemModDB.multipliers["Non"..mult] = (env.itemModDB.multipliers["Non"..mult] or 0) - 1
							end
						end
						if (otherRing.elder or otherRing.shaper) and not (item.elder or item.shaper) then
							env.itemModDB.multipliers.ShaperOrElderItem = (env.itemModDB.multipliers.ShaperOrElderItem or 0) + 1
						end
					end
					env.itemModDB:ScaleAddList(srcList, scale)
				elseif item.type == "Quiver" and items["Weapon 1"] and items["Weapon 1"].name:match("Widowhail") then
					scale = scale * (1 + (items["Weapon 1"].baseModList:Sum("INC", nil, "EffectOfBonusesFromQuiver") or 100) / 100)
					local combinedList = new("ModList")
					for _, mod in ipairs(srcList) do
						combinedList:MergeMod(mod)
					end
					env.itemModDB:ScaleAddList(combinedList, scale)
				elseif env.modDB.multipliers["CorruptedMagicJewelEffect"] and item.type == "Jewel" and item.rarity == "MAGIC" and item.corrupted and slot.nodeId and item.base.subType ~= "Charm" then
					scale = scale + env.modDB.multipliers["CorruptedMagicJewelEffect"]
					env.itemModDB:ScaleAddList(srcList, scale)
				else
					env.itemModDB:ScaleAddList(srcList, scale)
				end
				-- set conditions on restricted items
				if item.classRestriction then
					env.itemModDB.conditions[item.title:gsub(" ", "")] = item.classRestriction
				end
				if item.type ~= "Jewel" and item.type ~= "Flask" then
					-- Update item counts
					local key
					if item.rarity == "UNIQUE" or item.rarity == "RELIC" then
						key = "UniqueItem"
					elseif item.rarity == "RARE" then
						key = "RareItem"
					elseif item.rarity == "MAGIC" then
						key = "MagicItem"
					else
						key = "NormalItem"
					end
					env.itemModDB.multipliers[key] = (env.itemModDB.multipliers[key] or 0) + 1
					env.itemModDB.conditions[key .. "In" .. slotName] = true
					for mult, property in pairs({["CorruptedItem"] = "corrupted", ["ShaperItem"] = "shaper", ["ElderItem"] = "elder"}) do
						if item[property] then
							env.itemModDB.multipliers[mult] = (env.itemModDB.multipliers[mult] or 0) + 1
						else
							env.itemModDB.multipliers["Non"..mult] = (env.itemModDB.multipliers["Non"..mult] or 0) + 1
						end
					end
					if item.shaper or item.elder then
						env.itemModDB.multipliers.ShaperOrElderItem = (env.itemModDB.multipliers.ShaperOrElderItem or 0) + 1
					end
					env.itemModDB.multipliers[item.type:gsub(" ", ""):gsub(".+Handed", "").."Item"] = (env.itemModDB.multipliers[item.type:gsub(" ", ""):gsub(".+Handed", "").."Item"] or 0) + 1
					-- Calculate socket counts
					local slotEmptySocketsCount = { R = 0, G = 0, B = 0, W = 0}	
					local slotGemSocketsCount = 0
					local socketedGems = 0
					-- Loop through socket groups to calculate number of socketed gems
					for _, socketGroup in pairs(env.build.skillsTab.socketGroupList) do
						if (not socketGroup.source and socketGroup.enabled and socketGroup.slot and socketGroup.slot == slotName and socketGroup.gemList) then
							for _, gem in pairs(socketGroup.gemList) do
								if (gem.gemData and gem.enabled) then
									socketedGems = socketedGems + 1
								end
							end
						end
					end
					for i, socket in ipairs(item.sockets) do
						-- Check socket color to ignore abyssal sockets
						if socket.color == 'R' or socket.color == 'B' or socket.color == 'G' or socket.color == 'W' then
							slotGemSocketsCount = slotGemSocketsCount + 1
							-- loop through sockets indexes that are greater than number of socketed gems
							if i > socketedGems then
								slotEmptySocketsCount[socket.color] = slotEmptySocketsCount[socket.color] + 1
							end
						end
					end
					env.itemModDB.multipliers["SocketedGemsIn"..slotName] = (env.itemModDB.multipliers["SocketedGemsIn"..slotName] or 0) + math.min(slotGemSocketsCount, socketedGems)
					env.itemModDB.multipliers.EmptyRedSocketsInAnySlot = (env.itemModDB.multipliers.EmptyRedSocketsInAnySlot or 0) + slotEmptySocketsCount.R
					env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot = (env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot or 0) + slotEmptySocketsCount.G
					env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot = (env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot or 0) + slotEmptySocketsCount.B
					env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot = (env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot or 0) + slotEmptySocketsCount.W
					-- Warn if socketed gems over socket limit
					if socketedGems > slotGemSocketsCount then
						env.itemWarnings.socketLimitWarning = env.itemWarnings.socketLimitWarning or { }
						t_insert(env.itemWarnings.socketLimitWarning, slotName)
					end
				end
			end
		end
		-- Override empty socket calculation if set in config
		env.itemModDB.multipliers.EmptyRedSocketsInAnySlot = (env.configInput.overrideEmptyRedSockets or env.itemModDB.multipliers.EmptyRedSocketsInAnySlot)
		env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot = (env.configInput.overrideEmptyGreenSockets or env.itemModDB.multipliers.EmptyGreenSocketsInAnySlot)
		env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot = (env.configInput.overrideEmptyBlueSockets or env.itemModDB.multipliers.EmptyBlueSocketsInAnySlot)
		env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot = (env.configInput.overrideEmptyWhiteSockets or env.itemModDB.multipliers.EmptyWhiteSocketsInAnySlot)
		if override.toggleFlask then
			if env.flasks[override.toggleFlask] then
				env.flasks[override.toggleFlask] = nil
			else
				env.flasks[override.toggleFlask] = true
			end
		end
	end

	-- Merge env.itemModDB with env.ModDB
	mergeDB(env.modDB, env.itemModDB)

	-- Add granted passives (e.g., amulet anoints)
	if not accelerate.nodeAlloc then
		for _, passive in pairs(env.modDB:List(nil, "GrantedPassive")) do
			local node = env.spec.tree.notableMap[passive]
			if node and (not override.removeNodes or not override.removeNodes[node.id]) then
				env.allocNodes[node.id] = env.spec.nodes[node.id] or node -- use the conquered node data, if available
				env.grantedPassives[node.id] = true
				env.extraRadiusNodeList[node.id] = nil
			end
		end
	end

	-- Add granted ascendancy node (e.g., Forbidden Flame/Flesh combo)
	local matchedName = { }
	for _, ascTbl in pairs(env.modDB:List(nil, "GrantedAscendancyNode")) do
		local name = ascTbl.name
		if matchedName[name] and matchedName[name].side ~= ascTbl.side and matchedName[name].matched == false then
			matchedName[name].matched = true
			local node = env.spec.tree.ascendancyMap[name]
			if node and (not override.removeNodes or not override.removeNodes[node.id]) then
				if env.itemModDB.conditions["ForbiddenFlesh"] == env.spec.curClassName and env.itemModDB.conditions["ForbiddenFlame"] == env.spec.curClassName then
					env.allocNodes[node.id] = node
					env.grantedPassives[node.id] = true
				end
			end
		else
			matchedName[name] = { side = ascTbl.side, matched = false }
		end
	end

	-- Merge modifiers for allocated passives
	env.modDB:AddList(calcs.buildModListForNodeList(env, env.allocNodes, true))

	if not override or (override and not override.extraJewelFuncs) then
		override = override or {}
		override.extraJewelFuncs = new("ModList")
		override.extraJewelFuncs.actor = env.player
		for _, mod in ipairs(env.modDB:Tabulate("LIST", nil, "ExtraJewelFunc")) do
			override.extraJewelFuncs:AddMod(mod.mod)
		end
		if #override.extraJewelFuncs > 0 then
			return calcs.initEnv(build, mode, override, specEnv)
		end
	end

	-- Find skills granted by tree nodes
	if not accelerate.nodeAlloc then
		for _, node in pairs(env.allocNodes) do
			for _, skill in ipairs(node.grantedSkills) do
				local grantedSkill = copyTable(skill)
				grantedSkill.sourceNode = node
				t_insert(env.grantedSkillsNodes, grantedSkill)
			end
		end
	end

	-- Merge Granted Skills Tables
	env.grantedSkills = tableConcat(env.grantedSkillsNodes, env.grantedSkillsItems)

	if not accelerate.skills then
		if env.mode == "MAIN" then
			-- Process extra skills granted by items or tree nodes
			local markList = wipeTable(tempTable1)
			for _, grantedSkill in ipairs(env.grantedSkills) do
				-- Check if a matching group already exists
				local group
				for index, socketGroup in pairs(build.skillsTab.socketGroupList) do
					if socketGroup.source == grantedSkill.source and socketGroup.slot == grantedSkill.slotName then
						if socketGroup.gemList[1] and socketGroup.gemList[1].skillId == grantedSkill.skillId and socketGroup.gemList[1].level == grantedSkill.level then
							group = socketGroup
							markList[socketGroup] = true
							break
						end
					end
				end
				if not group then
					-- Create a new group for this skill
					group = { label = "", enabled = true, gemList = { }, source = grantedSkill.source, slot = grantedSkill.slotName }
					t_insert(build.skillsTab.socketGroupList, group)
					markList[group] = true
				end

				-- Update the group
				group.sourceItem = grantedSkill.sourceItem
				group.sourceNode = grantedSkill.sourceNode
				local activeGemInstance = group.gemList[1] or {
					skillId = grantedSkill.skillId,
					nameSpec = grantedSkill.nameSpec,
					quality = 0,
					enabled = true,
				}
				activeGemInstance.fromItem = grantedSkill.sourceItem ~= nil
				activeGemInstance.gemId = nil
				activeGemInstance.level = grantedSkill.level
				activeGemInstance.enableGlobal1 = true
				activeGemInstance.noSupports = grantedSkill.noSupports
				group.noSupports = grantedSkill.noSupports
				activeGemInstance.triggered = grantedSkill.triggered
				activeGemInstance.triggerChance = grantedSkill.triggerChance
				wipeTable(group.gemList)
				t_insert(group.gemList, activeGemInstance)
				build.skillsTab:ProcessSocketGroup(group)
			end

			if #env.explodeSources ~= 0 then
				-- Check if a matching group already exists
				local group
				for _, socketGroup in pairs(build.skillsTab.socketGroupList) do
					if socketGroup.source == "Explode" then
						group = socketGroup
						break
					end
				end
				if not group then
					-- Create a new group for this skill
					group = { label = "On Kill Monster Explosion", enabled = true, gemList = { }, source = "Explode", noSupports = true }
					t_insert(build.skillsTab.socketGroupList, group)
				end
				-- Update the group
				group.explodeSources = env.explodeSources
				local gemsBySource = { }
				for _, gem in ipairs(group.gemList) do
					if gem.explodeSource then
						gemsBySource[gem.explodeSource.modSource or gem.explodeSource.id] = gem
					end
				end
				wipeTable(group.gemList)
				for _, explodeSource in ipairs(env.explodeSources) do
					local activeGemInstance
					if gemsBySource[explodeSource.modSource or explodeSource.id] then
						activeGemInstance = gemsBySource[explodeSource.modSource or explodeSource.id]
					else
						activeGemInstance = {
							skillId = "EnemyExplode",
							quality = 0,
							enabled = true,
							level = 1,
							triggered = true,
							explodeSource = explodeSource,
						}
					end
					t_insert(group.gemList, activeGemInstance)
				end
				markList[group] = true
				build.skillsTab:ProcessSocketGroup(group)
			end

			-- Remove any socket groups that no longer have a matching item
			local i = 1
			while build.skillsTab.socketGroupList[i] do
				local socketGroup = build.skillsTab.socketGroupList[i]
				if socketGroup.source and not markList[socketGroup] then
					t_remove(build.skillsTab.socketGroupList, i)
					if build.skillsTab.displayGroup == socketGroup then
						build.skillsTab.displayGroup = nil
					end
				else
					i = i + 1
				end
			end
		end

		-- Get the weapon data tables for the equipped weapons
		env.player.weaponData1 = env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 1"].weaponData and env.player.itemList["Weapon 1"].weaponData[1] or copyTable(env.data.unarmedWeaponData[env.classId])
		if env.player.weaponData1.countsAsDualWielding then
			env.player.weaponData2 = env.player.itemList["Weapon 1"].weaponData[2]
		else
			env.player.weaponData2 = env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 2"].weaponData and env.player.itemList["Weapon 2"].weaponData[2] or { }
		end

		-- Determine main skill group
		if env.mode == "CALCS" or env.mode == "CACHE" then
			env.calcsInput.skill_number = m_min(m_max(#build.skillsTab.socketGroupList, 1), env.calcsInput.skill_number or 1)
			env.mainSocketGroup = env.calcsInput.skill_number
		else
			build.mainSocketGroup = m_min(m_max(#build.skillsTab.socketGroupList, 1), build.mainSocketGroup or 1)
			env.mainSocketGroup = build.mainSocketGroup
		end

		-- Process supports and put them into the correct buckets
		env.crossLinkedSupportGroups = {}
		for _, mod in ipairs(env.modDB:Tabulate("LIST", nil, "LinkedSupport")) do
			env.crossLinkedSupportGroups[mod.mod.sourceSlot] = env.crossLinkedSupportGroups[mod.mod.sourceSlot] or {}
			t_insert(env.crossLinkedSupportGroups[mod.mod.sourceSlot], mod.value.targetSlotName)
		end

		local supportLists = { }
		local groupCfgList = { }
		local processedSockets = {}
		-- Process support gems adding them to applicable support lists
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			local slot = group.slot and build.itemsTab.slots[group.slot]
			group.slotEnabled = not slot or not slot.weaponSet or slot.weaponSet == (build.itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1)
			-- if group is main skill or group is enabled 
			if index == env.mainSocketGroup or (group.enabled and group.slotEnabled) then
				local slotName = group.slot and group.slot:gsub(" Swap","")
				groupCfgList[slotName or "noSlot"] = groupCfgList[slotName or "noSlot"] or {}
				groupCfgList[slotName or "noSlot"][group] = groupCfgList[slotName or "noSlot"][group] or {
					slotName = slotName,
					propertyModList = env.modDB:List({slotName = slotName}, "GemProperty")
				}
				local groupCfg = groupCfgList[slotName or "noSlot"][group]
				local propertyModList = groupCfg.propertyModList
				local targetListList = {}
				if groupCfg.slotName then
					supportLists[groupCfg.slotName] = supportLists[groupCfg.slotName] or {}
					supportLists[groupCfg.slotName][group] = supportLists[groupCfg.slotName][group] or {}
					t_insert(targetListList, supportLists[groupCfg.slotName][group])
				else
					supportLists[group] = supportLists[group] or {}
					t_insert(targetListList, supportLists[group])
				end

				-- if not unique item that provides skills
				if not group.source then
					-- Add extra supports from the item this group is socketed in
					for _, value in ipairs(env.modDB:List(groupCfg, "ExtraSupport")) do
						local grantedEffect = env.data.skills[value.skillId]
						-- Some skill gems share the same name as support gems, e.g. Barrage.
						-- Since a support gem is expected here, if the first lookup returns a skill, then
						-- prepending "Support" to the skillId will find the support version of the gem.
						if grantedEffect and not grantedEffect.support then
							grantedEffect = env.data.skills["Support"..value.skillId]
						end
						if grantedEffect then
							for _, targetList in ipairs(targetListList) do
								t_insert(targetList, {
									grantedEffect = grantedEffect,
									gemData = env.data.gems[env.data.gemForBaseName[grantedEffect.name:lower()] or env.data.gemForBaseName[(grantedEffect.name .. " Support"):lower()]],
									level = value.level,
									quality = 0,
									enabled = true,
								})
							end
						end
					end
				end

				for gemIndex, gemInstance in ipairs(group.gemList) do
					-- Add support gems from this group
					if env.mode == "MAIN" then
						gemInstance.displayEffect = nil
						gemInstance.supportEffect = nil
					end
					if gemInstance.enabled then
						local function processGrantedEffect(grantedEffect)
							if not grantedEffect or not grantedEffect.support then
								return
							end
							local supportEffect = {
								grantedEffect = grantedEffect,
								level = gemInstance.level,
								quality = gemInstance.quality,
								qualityId = gemInstance.qualityId,
								srcInstance = gemInstance,
								gemData = gemInstance.gemData,
								superseded = false,
								isSupporting = { },
							}
							if env.mode == "MAIN" then
								gemInstance.displayEffect = supportEffect
								gemInstance.supportEffect = supportEffect
							end
							if gemInstance.gemData then
								local playerItems = env.player.itemList
								local socketedIn = playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].sockets and playerItems[groupCfg.slotName].sockets[gemIndex]
								applyGemMods(supportEffect, socketedIn and getGemModList(env, groupCfg, socketedIn.color, gemIndex) or propertyModList)
								if not processedSockets[gemInstance] then
									processedSockets[gemInstance] = true
									applySocketMods(env, gemInstance.gemData, groupCfg, gemIndex, playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].name)
									-- Keep track of the gem count for each color socketed in this group
									groupCfg.intelligenceGems = (groupCfg.intelligenceGems or 0) + (gemInstance.gemData.tags.intelligence and 1 or 0)
									groupCfg.dexterityGems = (groupCfg.dexterityGems or 0) + (gemInstance.gemData.tags.dexterity and 1 or 0)
									groupCfg.strengthGems = (groupCfg.strengthGems or 0) + (gemInstance.gemData.tags.strength and 1 or 0)
								end
							end
							-- Validate support gem level in case there is no active skill (and no full calculation)
							calcLib.validateGemLevel(supportEffect)

							for _, targetList in ipairs(targetListList) do
								addBestSupport(supportEffect, targetList, env.mode)
							end
						end
						if gemInstance.gemData then
							processGrantedEffect(gemInstance.gemData.grantedEffect)
							processGrantedEffect(gemInstance.gemData.secondaryGrantedEffect)
						else
							processGrantedEffect(gemInstance.grantedEffect)
						end
					end
				end
			end
		end

		-- Process active skills adding the applicable supports
		local socketGroupSkillListList = { }
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			if index == env.mainSocketGroup or (group.enabled and group.slotEnabled) then
				local slotName = group.slot and group.slot:gsub(" Swap","")
				groupCfgList[slotName or "noSlot"][group] = groupCfgList[slotName or "noSlot"][group] or {
					slotName = slotName,
					propertyModList = env.modDB:List({slotName = slotName}, "GemProperty")
				}
				local groupCfg = groupCfgList[slotName or "noSlot"][group]
				local propertyModList = groupCfg.propertyModList
				socketGroupSkillListList[slotName or "noSlot"] = socketGroupSkillListList[slotName or "noSlot"] or {}
				socketGroupSkillListList[slotName or "noSlot"][group] = socketGroupSkillListList[slotName or "noSlot"][group] or {}
				local socketGroupSkillList = socketGroupSkillListList[slotName or "noSlot"][group]
				local slotHasActiveSkill = false

				-- Create active skills
				for gemIndex, gemInstance in ipairs(group.gemList) do
					if gemInstance.enabled and (gemInstance.gemData or gemInstance.grantedEffect) then
						local grantedEffectList = gemInstance.gemData and gemInstance.gemData.grantedEffectList or { gemInstance.grantedEffect }
						for index, grantedEffect in ipairs(grantedEffectList) do
							if not grantedEffect.support and not grantedEffect.unsupported and (not grantedEffect.hasGlobalEffect or gemInstance["enableGlobal"..index]) then
								slotHasActiveSkill = true
								local activeEffect = {
									grantedEffect = grantedEffect,
									level = gemInstance.level,
									quality = gemInstance.quality,
									qualityId = gemInstance.qualityId,
									srcInstance = gemInstance,
									gemData = gemInstance.gemData,
								}
								if gemInstance.gemData then
									local playerItems = env.player.itemList
									local socketedIn = playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].sockets and playerItems[groupCfg.slotName].sockets[gemIndex]
									applyGemMods(activeEffect, socketedIn and getGemModList(env, groupCfg, socketedIn.color, gemIndex) or propertyModList)
									if not processedSockets[gemInstance] then
										processedSockets[gemInstance] = true
										applySocketMods(env, gemInstance.gemData, groupCfg, gemIndex, playerItems[groupCfg.slotName] and playerItems[groupCfg.slotName].name)
										-- Keep track of the gem count for each color socketed in this group
										groupCfg.intelligenceGems = (groupCfg.intelligenceGems or 0) + (gemInstance.gemData.tags.intelligence and 1 or 0)
										groupCfg.dexterityGems = (groupCfg.dexterityGems or 0) + (gemInstance.gemData.tags.dexterity and 1 or 0)
										groupCfg.strengthGems = (groupCfg.strengthGems or 0) + (gemInstance.gemData.tags.strength and 1 or 0)
									end
								end
								if env.mode == "MAIN" then
									gemInstance.displayEffect = activeEffect
								end
								local appliedSupportList = {}
								if not group.noSupports then
									appliedSupportList = copyTable(supportLists[group] or supportLists[slotName][group], true)
									-- add displayGemList for tooltip to display all gems linked to active skills
									group.displayGemList = copyTable(group.gemList, true)
									-- if skill granted by unique item, go through all support groups in slot
									if group.source then 
										if supportLists[slotName] then
											-- add socketed supports from other socketGroups
											for _, otherSocketGroup in ipairs(build.skillsTab.socketGroupList) do
												if otherSocketGroup.slot and otherSocketGroup.slot == group.slot then
													for _, gem in ipairs(otherSocketGroup.gemList) do
														if gem.gemData and gem.gemData.grantedEffect and gem.gemData.grantedEffect.support then
															t_insert(group.displayGemList, gem)
														end
													end
												end
											end
											for _, supportGroup in pairs(supportLists[slotName]) do
												for _, supportEffect in ipairs(supportGroup) do
													addBestSupport(supportEffect, appliedSupportList, env.mode)
												end
											end
										end
									end
									-- then add supports from crossLinked socketGroups
									for crossLinkedSupportSlot, crossLinkedSupportGroup in pairs(env.crossLinkedSupportGroups) do
										for _, crossLinkedSupportedSlot in ipairs(crossLinkedSupportGroup) do
											if crossLinkedSupportedSlot == slotName and supportLists[crossLinkedSupportSlot] then
												for _, otherSocketGroup in ipairs(build.skillsTab.socketGroupList) do 
													if otherSocketGroup.slot and otherSocketGroup.slot == crossLinkedSupportSlot then 
														for _, gem in ipairs(otherSocketGroup.gemList) do
															if gem.gemData and gem.gemData.grantedEffect and gem.gemData.grantedEffect.support then
																t_insert(group.displayGemList, gem)
															end
														end
													end
												end
												for _, supportGroup in pairs(supportLists[crossLinkedSupportSlot]) do
													for _, supportEffect in ipairs(supportGroup) do
														addBestSupport(supportEffect, appliedSupportList, env.mode)
													end
												end
											end
										end
									end
								end
								local activeSkill = calcs.createActiveSkill(activeEffect, appliedSupportList, env.player, group)
								if gemInstance.gemData then
									activeSkill.slotName = groupCfg.slotName
								end
								t_insert(socketGroupSkillList, activeSkill)
								t_insert(env.player.activeSkillList, activeSkill)
							end
						end
						if gemInstance.gemData and not accelerate.requirementsGems then
							t_insert(env.requirementsTableGems, {
								source = "Gem",
								sourceGem = gemInstance,
								Str = gemInstance.reqStr,
								Dex = gemInstance.reqDex,
								Int = gemInstance.reqInt,
							})
						end
					end
				end
				
				if not slotHasActiveSkill and group.displayGemList then
					group.displayGemList = nil
				end
			end
		end

		-- Process calculated active skill lists
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			local slotName = group.slot and group.slot:gsub(" Swap","")
			socketGroupSkillListList[slotName or "noSlot"] = socketGroupSkillListList[slotName or "noSlot"] or {}
			socketGroupSkillListList[slotName or "noSlot"][group] = socketGroupSkillListList[slotName or "noSlot"][group] or {}
			local socketGroupSkillList = socketGroupSkillListList[slotName or "noSlot"][group]
			if index == env.mainSocketGroup or (group.enabled and group.slotEnabled) then
				groupCfgList[slotName or "noSlot"][group] = groupCfgList[slotName or "noSlot"][group] or {
					slotName = slotName,
					propertyModList = env.modDB:List({slotName = slotName}, "GemProperty")
				}
				local groupCfg = groupCfgList[slotName or "noSlot"][group]
				for _, value in ipairs(env.modDB:List(groupCfg, "GroupProperty")) do
					env.player.modDB:AddMod(modLib.setSource(value.value, groupCfg.slotName or ""))
				end

				if index == env.mainSocketGroup and #socketGroupSkillList > 0 then
					-- Select the main skill from this socket group
					local activeSkillIndex
					if env.mode == "CALCS" then
						group.mainActiveSkillCalcs = m_min(#socketGroupSkillList, group.mainActiveSkillCalcs or 1)
						activeSkillIndex = group.mainActiveSkillCalcs
					else
						activeSkillIndex = m_min(#socketGroupSkillList, group.mainActiveSkill or 1)
						if env.mode == "MAIN" then
							group.mainActiveSkill = activeSkillIndex
						end
					end
					env.player.mainSkill = socketGroupSkillList[activeSkillIndex]
				end
			end

			if env.mode == "MAIN" then
				-- Create display label for the socket group if the user didn't specify one
				if group.label and group.label:match("%S") then
					group.displayLabel = group.label
				else
					group.displayLabel = nil
					for _, gemInstance in ipairs(group.gemList) do
						local grantedEffect = gemInstance.gemData and gemInstance.gemData.grantedEffect or gemInstance.grantedEffect
						if grantedEffect and not grantedEffect.support and gemInstance.enabled then
							group.displayLabel = (group.displayLabel and group.displayLabel..", " or "") .. grantedEffect.name
						end
					end
					group.displayLabel = group.displayLabel or "<No active skills>"
				end

				-- Save the active skill list for display in the socket group tooltip
				group.displaySkillList = socketGroupSkillList
			elseif env.mode == "CALCS" then
				group.displaySkillListCalcs = socketGroupSkillList
			end

			-- Check for enabled energy blade to see if we need to regenerate everything.
			if not modDB.conditions["AffectedByEnergyBlade"] and group.enabled and group.slotEnabled then
				for _, gemInstance in ipairs(group.gemList) do
					local grantedEffect = gemInstance.gemData and gemInstance.gemData.grantedEffect or gemInstance.grantedEffect
					if grantedEffect and not grantedEffect.support and gemInstance.enabled and grantedEffect.name == "Energy Blade" then
						override.conditions = override.conditions or { }
						t_insert(override.conditions, "AffectedByEnergyBlade")
						return calcs.initEnv(build, mode, override, specEnv)
					end
				end
			end
		end

		if not env.player.mainSkill then
			-- Add a default main skill if none are specified
			local defaultEffect = {
				grantedEffect = env.data.skills.Melee,
				level = 1,
				quality = 0,
				enabled = true,
			}
			env.player.mainSkill = calcs.createActiveSkill(defaultEffect, { }, env.player)
			t_insert(env.player.activeSkillList, env.player.mainSkill)
		end

		-- Build skill modifier lists
		for _, activeSkill in pairs(env.player.activeSkillList) do
			calcs.buildActiveSkillModList(env, activeSkill)
		end
	else
		-- Wipe skillData and readd required data the rest of the data will be added by the rest of code this stops iterative calculations on skillData not being reset
		for _, activeSkill in pairs(env.player.activeSkillList) do
			local skillData = copyTable(activeSkill.skillData, true)
			activeSkill.skillData = { }
			for _, value in ipairs(env.modDB:List(activeSkill.skillCfg, "SkillData")) do
				activeSkill.skillData[value.key] = value.value
			end
			for _, value in ipairs(activeSkill.skillModList:List(activeSkill.skillCfg, "SkillData")) do
				activeSkill.skillData[value.key] = value.value
			end
			-- These mods were modified with special expressions in buildActiveSkillModList() use old one to avoid more calculations
			activeSkill.skillData.manaReservationPercent = skillData.manaReservationPercent
			activeSkill.skillData.cooldown = skillData.cooldown
			activeSkill.skillData.storedUses = skillData.storedUses
			activeSkill.skillData.CritChance = skillData.CritChance
			activeSkill.skillData.attackTime = skillData.attackTime
			activeSkill.skillData.totemLevel = skillData.totemLevel
			activeSkill.skillData.damageEffectiveness = skillData.damageEffectiveness
			activeSkill.skillData.manaReservationPercent = skillData.manaReservationPercent
		end
	end

	-- Merge Requirements Tables
	env.requirementsTable = tableConcat(env.requirementsTableItems, env.requirementsTableGems)

	return env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB
end
