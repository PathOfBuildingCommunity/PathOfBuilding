-- Path of Building
--
-- Module: Calcs
-- Performs all the offense and defense calculations.
-- Here be dragons!
-- This file is 2400 lines long, over half of which is in one function...
--

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_abs = math.abs
local m_ceil = math.ceil
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local s_format = string.format
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot

-- List of all damage types, ordered according to the conversion sequence
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}

local resistTypeList = { "Fire", "Cold", "Lightning", "Chaos" }

local isElemental = { Fire = true, Cold = true, Lightning = true }

-- Calculate and combine INC/MORE modifiers for the given modifier names
local function calcMod(modDB, cfg, ...)
	return (1 + (modDB:Sum("INC", cfg, ...)) / 100) * modDB:Sum("MORE", cfg, ...)
end

-- Calculate value, optionally adding additional base
local function calcVal(modDB, name, cfg, base)
	local baseVal = modDB:Sum("BASE", cfg, name) + (base or 0)
	if baseVal ~= 0 then
		return baseVal * calcMod(modDB, cfg, name)
	else
		return 0
	end
end

-- Calculate hit chance
local function calcHitChance(evasion, accuracy)
	local rawChance = accuracy / (accuracy + (evasion / 4) ^ 0.8) * 100
	return m_max(m_min(m_floor(rawChance + 0.5), 95), 5)	
end

-- Merge gem modifiers with given mod list
local function mergeGemMods(modList, gem)
	modList:AddList(gem.data.baseMods)
	if gem.quality > 0 then
		for i = 1, #gem.data.qualityMods do
			local scaledMod = copyTable(gem.data.qualityMods[i])
			scaledMod.value = m_floor(scaledMod.value * gem.quality)
			modList:AddMod(scaledMod)
		end
	end
	gem.level = m_max(gem.level, 1)
	if not gem.data.levels[gem.level] then
		gem.level = m_min(gem.level, #gem.data.levels)
	end
	local levelData = gem.data.levels[gem.level]
	for col, mod in pairs(gem.data.levelMods) do
		if levelData[col] then
			local newMod = copyTable(mod)
			if type(newMod.value) == "table" then
				newMod.value.value = levelData[col]
			else
				newMod.value = levelData[col]
			end
			modList:AddMod(newMod)
		end
	end
end

-- Check if given support gem can support the given active skill
-- Global function, as GemSelectControl needs to use it too
function gemCanSupport(gem, activeSkill)
	if gem.data.unsupported then
		return false
	end
	for _, skillType in pairs(gem.data.excludeSkillTypes) do
		if activeSkill.skillTypes[skillType] then
			return false
		end
	end
	if not gem.data.requireSkillTypes[1] then
		return true
	end
	for _, skillType in pairs(gem.data.requireSkillTypes) do
		if activeSkill.skillTypes[skillType] then
			return true
		end
	end
	return false
end

-- Check if given gem is of the given type ("all", "strength", "melee", etc)
-- Global function, as ModDBClass and ModListClass need to use it too
function gemIsType(gem, type)
	return type == "all" or (type == "elemental" and (gem.data.fire or gem.data.cold or gem.data.lightning)) or gem.data[type]
end

-- Create an active skill using the given active gem and list of support gems
-- It will determine the base flag set, and check which of the support gems can support this skill
local function createActiveSkill(activeGem, supportList)
	local activeSkill = { }
	activeSkill.activeGem = {
		name = activeGem.name,
		data = activeGem.data,
		level = activeGem.level,
		quality = activeGem.quality,
		fromItem = activeGem.fromItem,
		srcGem = activeGem,
	}
	activeSkill.gemList = { activeSkill.activeGem }

	activeSkill.skillTypes = copyTable(activeGem.data.skillTypes)

	-- Initialise skill flag set ('attack', 'projectile', etc)
	local skillFlags = copyTable(activeGem.data.baseFlags)
	activeSkill.skillFlags = skillFlags
	skillFlags.hit = activeSkill.skillTypes[SkillType.Attack] or activeSkill.skillTypes[SkillType.Hit]

	for _, gem in ipairs(supportList) do
		if gemCanSupport(gem, activeSkill) then
			if gem.data.addFlags then
				-- Support gem adds flags to supported skills (eg. Remote Mine adds 'mine')
				for k in pairs(gem.data.addFlags) do
					skillFlags[k] = true
				end
			end
			for _, skillType in pairs(gem.data.addSkillTypes) do
				activeSkill.skillTypes[skillType] = true
			end
		end
	end

	-- Process support gems
	for _, gem in ipairs(supportList) do
		if gemCanSupport(gem, activeSkill) then
			t_insert(activeSkill.gemList, {
				name = gem.name,
				data = gem.data,
				level = gem.level,
				quality = gem.quality,
				fromItem = gem.fromItem,
				srcGem = gem,
			})
			if gem.isSupporting then
				gem.isSupporting[activeGem.name] = true
			end
		end
	end

	return activeSkill
end

-- Build list of modifiers for given active skill
local function buildActiveSkillModList(env, activeSkill)
	local skillFlags = activeSkill.skillFlags

	-- Handle multipart skills
	local activeGemParts = activeSkill.activeGem.data.parts
	if activeGemParts then
		if activeSkill == env.mainSkill then
			activeSkill.skillPart = m_min(#activeGemParts, env.skillPart or activeSkill.activeGem.srcGem.skillPart or 1)
		else
			activeSkill.skillPart = m_min(#activeGemParts, activeSkill.activeGem.srcGem.skillPart or 1)
		end
		local part = activeGemParts[activeSkill.skillPart]
		for k, v in pairs(part) do
			if v == true then
				skillFlags[k] = true
			elseif v == false then
				skillFlags[k] = nil
			end
		end
		activeSkill.skillPartName = part.name
		skillFlags.multiPart = #activeGemParts > 1
	end

	-- Set weapon flags
	local weapon1Type = env.itemList["Weapon 1"] and env.itemList["Weapon 1"].type or "None"
	local weapon2Type = env.itemList["Weapon 2"] and env.itemList["Weapon 2"].type or ""
	skillFlags.mainIs1H = true
	local weapon1Info = data.weaponTypeInfo[weapon1Type]
	if weapon1Info then
		if not weapon1Info.oneHand then
			skillFlags.mainIs1H = nil
		end
		if skillFlags.attack then
			skillFlags.weapon1Attack = true
			if weapon1Info.melee and skillFlags.melee then
				skillFlags.projectile = nil
			elseif not weapon1Info.melee and skillFlags.projectile then
				skillFlags.melee = nil
			end
		end
	end
	local weapon2Info = data.weaponTypeInfo[weapon2Type]
	if weapon2Info and skillFlags.mainIs1H then
		if skillFlags.attack then
			skillFlags.weapon2Attack = true
		end
	end

	-- Build skill mod flag set
	local skillModFlags = 0
	if skillFlags.hit then
		skillModFlags = bor(skillModFlags, ModFlag.Hit)
	end
	if skillFlags.spell then
		skillModFlags = bor(skillModFlags, ModFlag.Spell)
	elseif skillFlags.attack then
		skillModFlags = bor(skillModFlags, ModFlag.Attack)
	end
	if skillFlags.weapon1Attack then
		skillModFlags = bor(skillModFlags, env.weaponData1.flag or weapon1Info.flag)
		if weapon1Type ~= "None" then
			skillModFlags = bor(skillModFlags, ModFlag.Weapon)
			if skillFlags.mainIs1H then
				skillModFlags = bor(skillModFlags, ModFlag.Weapon1H)
			else
				skillModFlags = bor(skillModFlags, ModFlag.Weapon2H)
			end
			if weapon1Info.melee then
				skillModFlags = bor(skillModFlags, ModFlag.WeaponMelee)
			else
				skillModFlags = bor(skillModFlags, ModFlag.WeaponRanged)
			end
		end
	end
	if skillFlags.melee then
		skillModFlags = bor(skillModFlags, ModFlag.Melee)
	elseif skillFlags.projectile then
		skillModFlags = bor(skillModFlags, ModFlag.Projectile)
	end
	if skillFlags.area then
		skillModFlags = bor(skillModFlags, ModFlag.Area)
	end
	activeSkill.skillFlags = skillFlags

	-- Build skill keyword flag set
	local skillKeywordFlags = 0
	if skillFlags.aura then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Aura)
	end
	if skillFlags.curse then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Curse)
	end
	if skillFlags.warcry then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Warcry)
	end
	if skillFlags.movement then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Movement)
	end
	if skillFlags.lightning then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Lightning)
	end
	if skillFlags.cold then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Cold)
	end
	if skillFlags.fire then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Fire)
	end
	if skillFlags.chaos then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Chaos)
	end
	if skillFlags.minion then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Minion)
	elseif skillFlags.totem then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Totem)
	elseif skillFlags.trap then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Trap)
	elseif skillFlags.mine then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Mine)
	end
	activeSkill.skillKeywordFlags = skillKeywordFlags

	-- Get skill totem ID for totem skills
	-- This is used to calculate totem life
	if skillFlags.totem then
		activeSkill.skillTotemId = activeSkill.activeGem.data.skillTotemId
		if not activeSkill.skillTotemId then
			if activeSkill.activeGem.data.color == 2 then
				activeSkill.skillTotemId = 2
			elseif activeSkill.activeGem.data.color == 3 then
				activeSkill.skillTotemId = 3
			else
				activeSkill.skillTotemId = 1
			end
		end
	end

	-- Build config structure for modifier searches
	activeSkill.skillCfg = {
		flags = skillModFlags,
		keywordFlags = skillKeywordFlags,
		skillName = activeSkill.activeGem.name:gsub("^Vaal ",""), -- This allows modifiers that target specific skills to also apply to their Vaal counterpart
		skillGem = activeSkill.activeGem,
		skillPart = activeSkill.skillPart,
		skillTypes = activeSkill.skillTypes,
		slotName = activeSkill.slotName,
	}

	-- Apply gem property modifiers from the item this skill is socketed into
	for _, value in ipairs(env.modDB:Sum("LIST", activeSkill.skillCfg, "GemProperty")) do
		for _, gem in pairs(activeSkill.gemList) do
			if not gem.fromItem and gemIsType(gem, value.keyword) then
				gem[value.key] = (gem[value.key] or 0) + value.value
			end
		end
	end

	-- Initialise skill modifier list
	local skillModList = common.New("ModList")
	activeSkill.skillModList = skillModList

	-- Add support gem modifiers to skill mod list
	for _, gem in pairs(activeSkill.gemList) do
		if gem.data.support then
			mergeGemMods(skillModList, gem)
		end
	end

	-- Apply gem/quality modifiers from support gems
	if not activeSkill.activeGem.fromItem then
		for _, value in ipairs(skillModList:Sum("LIST", activeSkill.skillCfg, "GemProperty")) do
			if value.keyword == "active_skill" then
				activeSkill.activeGem[value.key] = activeSkill.activeGem[value.key] + value.value
			end
		end
	end

	-- Add active gem modifiers
	mergeGemMods(skillModList, activeSkill.activeGem)

	-- Extract skill data
	activeSkill.skillData = { }
	for _, value in ipairs(skillModList:Sum("LIST", activeSkill.skillCfg, "Misc")) do
		if value.type == "SkillData" then
			activeSkill.skillData[value.key] = value.value
		end
	end

	-- Separate global effect modifiers (mods that can affect defensive stats or other skills)
	local i = 1
	while skillModList[i] do
		local destList
		for _, tag in ipairs(skillModList[i].tagList) do
			if tag.type == "GlobalEffect" then
				if tag.effectType == "Buff" then
					destList = "buffModList"
				elseif tag.effectType == "Aura" then
					destList = "auraModList"
				elseif tag.effectType == "Debuff" then
					destList = "debuffModList"
				elseif tag.effectType == "Curse" then
					destList = "curseModList"
				end
				break
			end
		end
		if destList then
			if not activeSkill[destList] then
				activeSkill[destList] = { }
			end
			t_insert(activeSkill[destList],  skillModList[i])
			t_remove(skillModList, i)
		else
			i = i + 1
		end
	end

	if activeSkill.buffModList or activeSkill.auraModList or activeSkill.debuffModList or activeSkill.curseModList then
		-- Add to auxillary skill list
		t_insert(env.auxSkillList, activeSkill)
	end
end

-- Build list of modifiers from the listed tree nodes
local function buildNodeModList(env, nodeList, finishJewels)
	-- Initialise radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		wipeTable(rad.data)
	end

	-- Add node modifers
	local modList = common.New("ModList")
	for _, node in pairs(nodeList) do
		-- Merge with output list
		if node.type == "keystone" then
			modList:AddMod(node.keystoneMod)
		else
			modList:AddList(node.modList)
		end

		-- Run radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			local vX, vY = node.x - rad.x, node.y - rad.y
			if vX * vX + vY * vY <= rad.rSq then
				rad.func(node.modList, modList, rad.data)
			end
		end
	end

	if finishJewels then
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

-- Calculate min/max damage of a hit for the given damage type
local function calcHitDamage(env, source, damageType, ...)
	local modDB = env.modDB
	local skillCfg = env.mainSkill.skillCfg

	local damageTypeMin = damageType.."Min"
	local damageTypeMax = damageType.."Max"

	-- Calculate base values
	local damageEffectiveness = source.damageEffectiveness or 1
	local addedMin = modDB:Sum("BASE", skillCfg, damageTypeMin)
	local addedMax = modDB:Sum("BASE", skillCfg, damageTypeMax)
	local baseMin = (source[damageTypeMin] or 0) + addedMin * damageEffectiveness
	local baseMax = (source[damageTypeMax] or 0) + addedMax * damageEffectiveness

	if env.breakdown and not (...) and baseMin ~= 0 and baseMax ~= 0 then
		t_insert(env.breakdown[damageType], "Base damage:")
		local plus = ""
		if (source[damageTypeMin] or 0) ~= 0 or (source[damageTypeMax] or 0) ~= 0 then
			t_insert(env.breakdown[damageType], s_format("%d to %d ^8(base damage from %s)", source[damageTypeMin], source[damageTypeMax], env.mode_skillType == "ATTACK" and "weapon" or "skill"))
			plus = "+ "
		end
		if addedMin ~= 0 or addedMax ~= 0 then
			if damageEffectiveness ~= 1 then
				t_insert(env.breakdown[damageType], s_format("%s(%d to %d) x %.2f ^8(added damage multiplied by damage effectiveness)", plus, addedMin, addedMax, damageEffectiveness))
			else
				t_insert(env.breakdown[damageType], s_format("%s%d to %d ^8(added damage)", plus, addedMin, addedMax))
			end
		end
		t_insert(env.breakdown[damageType], s_format("= %.1f to %.1f", baseMin, baseMax))
	end

	-- Calculate conversions
	local addMin, addMax = 0, 0
	local conversionTable = env.conversionTable
	for _, otherType in ipairs(dmgTypeList) do
		if otherType == damageType then
			-- Damage can only be converted from damage types that preceed this one in the conversion sequence, so stop here
			break
		end
		local convMult = conversionTable[otherType][damageType]
		if convMult > 0 then
			-- Damage is being converted/gained from the other damage type
			local min, max = calcHitDamage(env, source, otherType, damageType, ...)
			addMin = addMin + min * convMult
			addMax = addMax + max * convMult
		end
	end
	if addMin ~= 0 and addMax ~= 0 then
		addMin = round(addMin)
		addMax = round(addMax)
	end

	if baseMin == 0 and baseMax == 0 then
		-- No base damage for this type, don't need to calculate modifiers
		if env.breakdown and (addMin ~= 0 or addMax ~= 0) then
			local endType, convDst
			if (...) then
				endType = select(select('#', ...), ...)
				convDst = s_format("%d%% to %s", conversionTable[damageType][...] * 100, ...)
			else
				endType = damageType
			end
			t_insert(env.breakdown[endType].damageComponents, {
				source = damageType,
				convSrc = (addMin ~= 0 or addMax ~= 0) and (addMin .. " to " .. addMax),
				total = addMin .. " to " .. addMax,
				convDst = convDst,
			})
		end
		return addMin, addMax
	end

	-- Build lists of applicable modifier names
	local addElemental = isElemental[damageType]
	local modNames = { damageType.."Damage", "Damage" }
	for i = 1, select('#', ...) do
		local dstElem = select(i, ...)
		-- Add modifiers for damage types to which this damage is being converted
		addElemental = addElemental or isElemental[dstElem]
		t_insert(modNames, dstElem.."Damage")
	end
	if addElemental then
		-- Damage is elemental or is being converted to elemental damage, add global elemental modifiers
		t_insert(modNames, "ElementalDamage")
	end

	-- Combine modifiers
	local inc = 1 + modDB:Sum("INC", skillCfg, unpack(modNames)) / 100
	local more = m_floor(modDB:Sum("MORE", skillCfg, unpack(modNames)) * 100 + 0.50000001) / 100

	if env.breakdown then
		local endType, convDst
		if (...) then
			endType = select(select('#', ...), ...)
			convDst = s_format("%d%% to %s", conversionTable[damageType][...] * 100, ...)
		else
			endType = damageType
		end
		t_insert(env.breakdown[endType].damageComponents, {
			source = damageType,
			base = baseMin .. " to " .. baseMax,
			inc = (inc ~= 1 and "x "..inc),
			more = (more ~= 1 and "x "..more),
			convSrc = (addMin ~= 0 or addMax ~= 0) and (addMin .. " to " .. addMax),
			total = (round(baseMin * inc * more) + addMin) .. " to " .. (round(baseMax * inc * more) + addMax),
			convDst = convDst,
		})
	end

	return (round(baseMin * inc * more) + addMin),
		   (round(baseMax * inc * more) + addMax)
end

--
-- The following functions perform various steps in the calculations process.
-- Depending on what is being done with the output, other code may run inbetween steps, however the steps must always be performed in order:
-- 1. Initialise environment (initEnv)
-- 2. Merge main modifiers (mergeMainMods)
-- 3. Run calculations (performCalcs)
--
-- Thus a basic calculation pass would look like this:
-- 
-- local env = initEnv(build, mode)
-- mergeMainMods(env)
-- performCalcs(env)
--

local tempTable1 = { }
local tempTable2 = { }
local tempTable3 = { }

-- Initialise environment
-- This will initialise the modifier databases
local function initEnv(build, mode)
	local env = { }
	env.build = build
	env.configInput = build.configTab.input
	env.calcsInput = build.calcsTab.input
	env.mode = mode
	env.classId = build.spec.curClassId

	-- Initialise modifier database with base values
	local modDB = common.New("ModDB")
	env.modDB = modDB
	local classStats = build.tree.characterData[env.classId]
	for _, stat in pairs({"Str","Dex","Int"}) do
		modDB:NewMod(stat, "BASE", classStats["base_"..stat:lower()], "Base")
	end
	modDB.multipliers["Level"] = m_max(1, m_min(100, build.characterLevel))
	modDB:NewMod("Life", "BASE", 12, "Base", { type = "Multiplier", var = "Level", base = 38 })
	modDB:NewMod("Mana", "BASE", 6, "Base", { type = "Multiplier", var = "Level", base = 34 })
	modDB:NewMod("ManaRegen", "BASE", 0.0175, "Base", { type = "PerStat", stat = "Mana", div = 1 })
	modDB:NewMod("Evasion", "BASE", 3, "Base", { type = "Multiplier", var = "Level", base = 53 })
	modDB:NewMod("Accuracy", "BASE", 2, "Base", { type = "Multiplier", var = "Level", base = -2 })
	modDB:NewMod("FireResistMax", "BASE", 75, "Base")
	modDB:NewMod("FireResist", "BASE", -60, "Base")
	modDB:NewMod("ColdResistMax", "BASE", 75, "Base")
	modDB:NewMod("ColdResist", "BASE", -60, "Base")
	modDB:NewMod("LightningResistMax", "BASE", 75, "Base")
	modDB:NewMod("LightningResist", "BASE", -60, "Base")
	modDB:NewMod("ChaosResistMax", "BASE", 75, "Base")
	modDB:NewMod("ChaosResist", "BASE", -60, "Base")
	modDB:NewMod("BlockChanceMax", "BASE", 75, "Base")
	modDB:NewMod("PowerChargesMax", "BASE", 3, "Base")
	modDB:NewMod("CritChance", "INC", 50, "Base", { type = "Multiplier", var = "PowerCharge" })
	modDB:NewMod("FrenzyChargesMax", "BASE", 3, "Base")
	modDB:NewMod("Speed", "INC", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
	modDB:NewMod("Damage", "MORE", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
	modDB:NewMod("EnduranceChargesMax", "BASE", 3, "Base")
	modDB:NewMod("ElementalResist", "BASE", 4, "Base", { type = "Multiplier", var = "EnduranceCharge" })
	modDB:NewMod("ActiveTrapLimit", "BASE", 3, "Base")
	modDB:NewMod("ActiveMineLimit", "BASE", 5, "Base")
	modDB:NewMod("ActiveTotemLimit", "BASE", 1, "Base")
	modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
	modDB:NewMod("Speed", "MORE", 10, "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" })
	modDB:NewMod("PhysicalDamage", "MORE", 20, "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" })
	modDB:NewMod("BlockChance", "BASE", 15, "Base", { type = "Condition", var = "DualWielding" })
	modDB:NewMod("Misc", "LIST", { type = "EnemyModifier", mod = modLib.createMod("DamageTaken", "INC", 50, "Shock") }, "Base", { type = "Condition", var = "EnemyShocked" })
	
	-- Add bandit mods
	if build.banditNormal == "Alira" then
		modDB:NewMod("Mana", "BASE", 60, "Bandit")
	elseif build.banditNormal == "Kraityn" then
		modDB:NewMod("ElementalResist", "BASE", 10, "Bandit")
	elseif build.banditNormal == "Oak" then
		modDB:NewMod("Life", "BASE", 40, "Bandit")
	else
		modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
	end
	if build.banditCruel == "Alira" then
		modDB:NewMod("Speed", "INC", 5, "Bandit", ModFlag.Spell)
	elseif build.banditCruel == "Kraityn" then
		modDB:NewMod("Speed", "INC", 8, "Bandit", ModFlag.Attack)
	elseif build.banditCruel == "Oak" then
		modDB:NewMod("PhysicalDamage", "INC", 16, "Bandit")
	else
		modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
	end
	if build.banditMerciless == "Alira" then
		modDB:NewMod("PowerChargesMax", "BASE", 1, "Bandit")
	elseif build.banditMerciless == "Kraityn" then
		modDB:NewMod("FrenzyChargesMax", "BASE", 1, "Bandit")
	elseif build.banditMerciless == "Oak" then
		modDB:NewMod("EnduranceChargesMax", "BASE", 1, "Bandit")
	else
		modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
	end

	-- Initialise enemy modifier database
	local enemyDB = common.New("ModDB")
	env.enemyDB = enemyDB
	env.enemyLevel = m_max(1, m_min(100, env.configInput.enemyLevel and env.configInput.enemyLevel or m_min(env.build.characterLevel, 84)))
	enemyDB:NewMod("Accuracy", "BASE", data.monsterAccuracyTable[env.enemyLevel], "Base")
	enemyDB:NewMod("Evasion", "BASE", data.monsterEvasionTable[env.enemyLevel], "Base")

	-- Add mods from the config tab
	modDB:AddList(build.configTab.modList)
	enemyDB:AddList(build.configTab.enemyModList)

	return env
end

-- This function:
-- 1. Merges modifiers for all items, optionally replacing one item
-- 2. Builds a list of jewels with radius functions
-- 3. Merges modifiers for all allocated passive nodes
-- 4. Builds a list of active skills and their supports
-- 5. Builds modifier lists for all active skills
local function mergeMainMods(env, repSlotName, repItem)
	local build = env.build

	-- Build and merge item modifiers, and create list of radius jewels
	env.radiusJewelList = wipeTable(env.radiusJewelList)
	env.itemList = { }
	env.modDB.conditions["UsingAllCorruptedItems"] = true
	for slotName, slot in pairs(build.itemsTab.slots) do
		local item
		if slotName == repSlotName then
			item = repItem
		else
			item = build.itemsTab.list[slot.selItemId]
		end
		if slot.nodeId then
			-- Slot is a jewel socket, check if socket is allocated
			if not build.spec.allocNodes[slot.nodeId] then
				item = nil
			elseif item and item.jewelRadiusIndex then
				-- Jewel has a radius,  add it to the list
				local funcList = item.jewelFunc or { function(nodeMods, out, data)
					-- Default function just tallies all stats in radius
					if nodeMods then
						for _, stat in pairs({"Str","Dex","Int"}) do
							data[stat] = (data[stat] or 0) + nodeMods:Sum("BASE", nil, stat)
						end
					end
				end }
				for _, func in ipairs(funcList) do
					local radiusInfo = data.jewelRadius[item.jewelRadiusIndex]
					local node = build.spec.nodes[slot.nodeId]
					t_insert(env.radiusJewelList, {
						rSq = radiusInfo.rad * radiusInfo.rad,
						x = node.x,
						y = node.y,
						func = func,
						item = item,
						nodeId = slot.nodeId,
						data = { }
					})
				end
			end
		end
		env.itemList[slotName] = item
		if item then
			-- Merge mods for this item
			local srcList = item.modList or item.slotModList[slot.slotNum]
			env.modDB:AddList(srcList)
			if item.type ~= "Jewel" then
				-- Update item counts
				local key
				if item.rarity == "UNIQUE" then
					key = "UniqueItem"
				elseif item.rarity == "RARE" then
					key = "RareItem"
				elseif item.rarity == "MAGIC" then
					key = "MagicItem"
				else
					key = "NormalItem"
				end
				env.modDB.multipliers[key] = (env.modDB.multipliers[key] or 0) + 1
				if item.corrupted then
					env.modDB.multipliers.CorruptedItem = (env.modDB.multipliers.CorruptedItem or 0) + 1
				else
					env.modDB.conditions["UsingAllCorruptedItems"] = false
				end
			end
		end
	end
	
	if env.mode == "MAIN" then
		-- Process extra skills granted by items
		local markList = { }
		for _, mod in ipairs(env.modDB.mods["ExtraSkill"] or { }) do
			-- Extract the name of the slot containing the item this skill was granted by
			local slotName
			for _, tag in ipairs(mod.tagList) do
				if tag.type == "SocketedIn" then
					slotName = tag.slotName
					break
				end
			end

			-- Check if a matching group already exists
			local group
			for index, socketGroup in pairs(build.skillsTab.socketGroupList) do
				if socketGroup.source == mod.source and socketGroup.slot == slotName then
					if socketGroup.gemList[1] and socketGroup.gemList[1].nameSpec == mod.value.name then
						group = socketGroup
						markList[socketGroup] = true
						break
					end
				end
			end
			if not group then
				-- Create a new group for this skill
				group = { label = "", enabled = true, gemList = { }, source = mod.source, slot = slotName }
				t_insert(build.skillsTab.socketGroupList, group)
				markList[group] = true
			end

			-- Update the group
			group.sourceItem = build.itemsTab.list[tonumber(mod.source:match("Item:(%d+):"))]
			wipeTable(group.gemList)
			t_insert(group.gemList, {
				nameSpec = mod.value.name,
				level = mod.value.level,
				quality = 0,
				enabled = true,
				fromItem = true,
			})
			if mod.value.noSupports then
				group.noSupports = true
			else
				for _, socketGroup in pairs(build.skillsTab.socketGroupList) do
					-- Look for other groups that are socketed in the item
					if socketGroup.slot == slotName and not socketGroup.source then
						-- Add all support gems to the skill's group
						for _, gem in ipairs(socketGroup.gemList) do
							if gem.data and gem.data.support then
								t_insert(group.gemList, gem)
							end
						end
					end
				end
			end
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
	env.weaponData1 = env.itemList["Weapon 1"] and env.itemList["Weapon 1"].weaponData and env.itemList["Weapon 1"].weaponData[1] or copyTable(data.unarmedWeaponData[env.classId])
	env.weaponData2 = env.itemList["Weapon 2"] and env.itemList["Weapon 2"].weaponData and env.itemList["Weapon 2"].weaponData[2] or { }

	-- Build and merge modifiers for allocated passives
	env.modDB:AddList(buildNodeModList(env, build.spec.allocNodes, true))

	-- Determine main skill group
	if env.mode == "CALCS" then
		env.calcsInput.skill_number = m_min(m_max(#build.skillsTab.socketGroupList, 1), env.calcsInput.skill_number or 1)
		env.mainSocketGroup = env.calcsInput.skill_number
		env.skillPart = env.calcsInput.skill_part or 1
		env.buffMode = env.calcsInput.misc_buffMode
	else
		build.mainSocketGroup = m_min(m_max(#build.skillsTab.socketGroupList, 1), build.mainSocketGroup or 1)
		env.mainSocketGroup = build.mainSocketGroup
		env.buffMode = "EFFECTIVE"
	end

	-- Build list of active skills
	env.activeSkillList = { }
	local groupCfg = wipeTable(tempTable1)
	for index, socketGroup in pairs(build.skillsTab.socketGroupList) do
		local socketGroupSkillList = { }
		if socketGroup.enabled or index == env.mainSocketGroup then
			-- Build list of supports for this socket group
			local supportList = wipeTable(tempTable2)
			if not socketGroup.source then
				groupCfg.slotName = socketGroup.slot
				for _, value in ipairs(env.modDB:Sum("LIST", groupCfg, "ExtraSupport")) do
					-- Add extra supports from the item this group is socketed in
					local gemData = data.gems[value.name]
					if gemData then
						t_insert(supportList, { 
							name = value.name,
							data = gemData,
							level = value.level,
							quality = 0, 
							enabled = true, 
							fromItem = true
						})
					end
				end
			end
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.enabled and gem.data and gem.data.support then
					-- Add support gems from this group
					local add = true
					for _, otherGem in pairs(supportList) do
						-- Check if there's another support with the same name already present
						if gem.data == otherGem.data then
							add = false
							if gem.level > otherGem.level then
								otherGem.level = gem.level
								otherGem.quality = gem.quality
							elseif gem.level == otherGem.level then
								otherGem.quality = m_max(gem.quality, otherGem.quality)
							end
							break
						end
					end
					if add then
						gem.isSupporting = { }
						t_insert(supportList, gem)
					end
				end
			end

			-- Create active skills
			for _, gem in ipairs(socketGroup.gemList) do
				if gem.enabled and gem.data and not gem.data.support and not gem.data.unsupported then
					local activeSkill = createActiveSkill(gem, supportList)
					activeSkill.slotName = socketGroup.slot
					t_insert(socketGroupSkillList, activeSkill)
					t_insert(env.activeSkillList, activeSkill)
				end
			end

			if index == env.mainSocketGroup and #socketGroupSkillList > 0 then
				-- Select the main skill from this socket group
				local activeSkillIndex
				if env.mode == "CALCS" then
					env.calcsInput.skill_activeNumber = m_min(#socketGroupSkillList, env.calcsInput.skill_activeNumber or 1)
					activeSkillIndex = env.calcsInput.skill_activeNumber
				else
					socketGroup.mainActiveSkill = m_min(#socketGroupSkillList, socketGroup.mainActiveSkill or 1)
					activeSkillIndex = socketGroup.mainActiveSkill
				end
				env.mainSkill = socketGroupSkillList[activeSkillIndex]
			end
		end

		if env.mode == "MAIN" then
			-- Create display label for the socket group if the user didn't specify one
			if socketGroup.label and socketGroup.label:match("%S") then
				socketGroup.displayLabel = socketGroup.label
			else
				socketGroup.displayLabel = nil
				for _, gem in ipairs(socketGroup.gemList) do
					if gem.enabled and gem.data and not gem.data.support then
						socketGroup.displayLabel = (socketGroup.displayLabel and socketGroup.displayLabel..", " or "") .. gem.name
					end
				end
				socketGroup.displayLabel = socketGroup.displayLabel or "<No active skills>"
			end

			-- Save the active skill list for display in the socket group tooltip
			socketGroup.displaySkillList = socketGroupSkillList
		end
	end

	if not env.mainSkill then
		-- Add a default main skill if none are specified
		local defaultGem = {
			name = "Default Attack",
			level = 1,
			quality = 0,
			enabled = true,
			data = data.gems._default
		}
		env.mainSkill = createActiveSkill(defaultGem, { })
		t_insert(env.activeSkillList, env.mainSkill)
	end

	-- Build skill modifier lists
	env.auxSkillList = { }
	for _, activeSkill in pairs(env.activeSkillList) do
		buildActiveSkillModList(env, activeSkill)
	end
end

-- Finalise environment and perform the calculations
-- This function is 1300 lines long. Enjoy!
local function performCalcs(env)
	local modDB = env.modDB
	local enemyDB = env.enemyDB

	local output = { }
	env.output = output
	modDB.stats = output
	local breakdown
	if env.mode == "CALCS" then
		breakdown = { }
		env.breakdown = breakdown
	end

	-- Set modes
	if env.mainSkill.skillFlags.attack then
		env.mode_skillType = "ATTACK"
	else
		env.mode_skillType = "SPELL"
	end
	if env.mainSkill.skillData.showAverage then
		env.mode_average = true
	end
	if env.buffMode == "EFFECTIVE" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = true
	elseif env.buffMode == "COMBAT" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = false
	elseif env.buffMode == "BUFFED" then
		env.mode_buffs = true
		env.mode_combat = false
		env.mode_effective = false
	else
		env.mode_buffs = false
		env.mode_combat = false
		env.mode_effective = false
	end
	
	-- Merge keystone modifiers
	do
		local keystoneList = wipeTable(tempTable1)
		for _, name in ipairs(modDB:Sum("LIST", nil, "Keystone")) do
			keystoneList[name] = true
		end
		for name in pairs(keystoneList) do
			modDB:AddList(env.build.tree.keystoneMap[name].modList)
		end
	end

	-- Set conditions
	local condList = modDB.conditions
	if env.itemList["Weapon 1"] and env.itemList["Weapon 1"].type == "Staff" then
		condList["UsingStaff"] = true
	end
	if env.itemList["Weapon 1"] and env.itemList["Weapon 1"].type == "Bow" then
		condList["UsingBow"] = true
	end
	if env.itemList["Weapon 2"] and env.itemList["Weapon 2"].type == "Shield" then
		condList["UsingShield"] = true
	end
	if env.weaponData1.type and env.weaponData2.type then
		condList["DualWielding"] = true
	end
	if env.mode_skillType == "ATTACK" then
		condList["MainHandAttack"] = true
	end
	if not env.weaponData1.type then
		condList["Unarmed"] = true
	end
	if (modDB.multipliers["NormalItem"] or 0) > 0 then
		condList["UsingNormalItem"] = true
	end
	if (modDB.multipliers["MagicItem"] or 0) > 0 then
		condList["UsingMagicItem"] = true
	end
	if (modDB.multipliers["RareItem"] or 0) > 0 then
		condList["UsingRareItem"] = true
	end
	if (modDB.multipliers["UniqueItem"] or 0) > 0 then
		condList["UsingUniqueItem"] = true
	end
	if (modDB.multipliers["CorruptedItem"] or 0) > 0 then
		condList["UsingCorruptedItem"] = true
	else
		condList["NotUsingCorruptedItem"] = true
	end
	if env.mode_buffs then
		condList["Buffed"] = true
	end
	if env.mode_combat then
		condList["Combat"] = true
		if not modDB:Sum("FLAG", nil, "NeverCrit") then
			condList["CritInPast8Sec"] = true
		end
		if env.mainSkill.skillFlags.attack then
			condList["AttackedRecently"] = true
		elseif env.mainSkill.skillFlags.spell then
			condList["CastSpellRecently"] = true
		end
		if not env.mainSkill.skillFlags.trap and not env.mainSkill.skillFlags.mine and not env.mainSkill.skillFlags.totem then
			condList["HitRecently"] = true
		end
		if env.mainSkill.skillFlags.movement then
			condList["UsedMovementSkillRecently"] = true
		end
		if env.mainSkill.skillFlags.totem then
			condList["SummonedTotemRecently"] = true
		end
		if env.mainSkill.skillFlags.mine then
			condList["DetonatedMinesRecently"] = true
		end
	end
	if env.mode_effective then
		condList["Effective"] = true
	end
	
	-- Merge auxillary skill modifiers and calculate skill life and mana reservations
	env.reserved_LifeBase = 0
	env.reserved_LifePercent = 0
	env.reserved_ManaBase = 0
	env.reserved_ManaPercent = 0
	if breakdown then
		breakdown.LifeReserved = { reservations = { } }
		breakdown.ManaReserved = { reservations = { } }
	end
	for _, activeSkill in pairs(env.activeSkillList) do
		local skillModList = activeSkill.skillModList
		local skillCfg = activeSkill.skillCfg

		-- Merge auxillary modifiers
		if env.mode_buffs then
			if activeSkill.buffModList and (not activeSkill.skillFlags.totem or activeSkill.skillData.allowTotemBuff) then
				if activeSkill.activeGem.data.golem and modDB:Sum("FLAG", skillCfg, "LiegeOfThePrimordial") and (activeSkill.activeGem.data.fire or activeSkill.activeGem.data.cold or activeSkill.activeGem.data.lightning) then
					modDB:ScaleAddList(activeSkill.buffModList, 2)
				else
					modDB:AddList(activeSkill.buffModList)
				end
			end
			if activeSkill.auraModList then
				local inc = modDB:Sum("INC", skillCfg, "AuraEffect") + skillModList:Sum("INC", skillCfg, "AuraEffect")
				local more = modDB:Sum("MORE", skillCfg, "AuraEffect") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
				modDB:ScaleAddList(activeSkill.auraModList, (1 + inc / 100) * more)
				condList["HaveAuraActive"] = true
				modDB.multipliers["ActiveAura"] = (modDB.multipliers["ActiveAura"] or 0) + 1
			end
		end
		if env.mode_effective then
			if activeSkill.debuffModList then
				enemyDB:ScaleAddList(activeSkill.debuffModList, activeSkill.skillData.stackCount or 1)
			end
			if activeSkill.curseModList then
				condList["EnemyCursed"] = true
				local inc = modDB:Sum("INC", skillCfg, "CurseEffect") + enemyDB:Sum("INC", nil, "CurseEffect") + skillModList:Sum("INC", skillCfg, "CurseEffect")
				local more = modDB:Sum("MORE", skillCfg, "CurseEffect") * enemyDB:Sum("MORE", nil, "CurseEffect") * skillModList:Sum("MORE", skillCfg, "CurseEffect")
				enemyDB:ScaleAddList(activeSkill.curseModList, (1 + inc / 100) * more)
			end
		end

		-- Calculate reservations
		if activeSkill.skillTypes[SkillType.ManaCostReserved] and not activeSkill.skillFlags.totem then
			local baseVal = activeSkill.skillData.manaCostOverride or activeSkill.skillData.manaCost
			local suffix = activeSkill.skillTypes[SkillType.ManaCostPercent] and "Percent" or "Base"
			local mult = skillModList:Sum("MORE", skillCfg, "ManaCost")
			local more = modDB:Sum("MORE", skillCfg, "ManaReserved") * skillModList:Sum("MORE", skillCfg, "ManaReserved")
			local inc = modDB:Sum("INC", skillCfg, "ManaReserved") + skillModList:Sum("INC", skillCfg, "ManaReserved")
			--local cost = m_ceil(m_ceil(m_floor(baseVal * mult) * more) * (1 + inc / 100))
			local base = m_floor(baseVal * mult)
			local cost = base - m_floor(base * -m_floor((100 + inc) * more - 100) / 100)
			local pool
			if modDB:Sum("FLAG", skillCfg, "BloodMagic", "SkillBloodMagic") or skillModList:Sum("FLAG", skillCfg, "SkillBloodMagic") then
				pool = "Life"
			else
				pool = "Mana"
			end
			env["reserved_"..pool..suffix] = env["reserved_"..pool..suffix] + cost
			if breakdown then
				t_insert(breakdown[pool.."Reserved"].reservations, {
					skillName = activeSkill.activeGem.name,
					base = baseVal .. (activeSkill.skillTypes[SkillType.ManaCostPercent] and "%" or ""),
					mult = mult ~= 1 and ("x "..mult),
					more = more ~= 1 and ("x "..more),
					inc = inc ~= 0 and ("x "..(1 + inc/100)),
					total = cost .. (activeSkill.skillTypes[SkillType.ManaCostPercent] and "%" or ""),
				})
			end
		end
	end

	-- Process misc modifiers
	for _, value in ipairs(modDB:Sum("LIST", nil, "Misc")) do
		if value.type == "Condition" then
			condList[value.var] = true
		elseif value.type == "EnemyCondition" then
			enemyDB.conditions[value.var] = true
		elseif value.type == "Multiplier" then
			modDB.multipliers[value.var] = (modDB.multipliers[value.var] or 0) + value.value
		end
	end
	-- Process enemy modifiers last in case they depend on conditions that were set by misc modifiers
	for _, value in ipairs(modDB:Sum("LIST", nil, "Misc")) do
		if value.type == "EnemyModifier" then
			enemyDB:AddMod(value.mod)
		end
	end

	-- Process conditions that can depend on other conditions
	condList["NotCritRecently"] = not condList["CritRecently"]
	condList["NotKilledRecently"] = not condList["KilledRecently"]
	condList["NotBeenHitRecently"] = not condList["BeenHitRecently"]
	if env.mode_effective then
		if condList["EnemyIgnited"] then
			condList["EnemyBurning"] = true
		end
		condList["EnemyFrozenShockedIgnited"] = condList["EnemyFrozen"] or condList["EnemyShocked"] or condList["EnemyIgnited"]
		condList["EnemyElementalStatus"] = condList["EnemyChilled"] or condList["EnemyFrozen"] or condList["EnemyShocked"] or condList["EnemyIgnited"]
		condList["NotEnemyElementalStatus"] = not condList["EnemyElementalStatus"]
	end

	-- Calculate current and maximum charges
	output.PowerChargesMax = modDB:Sum("BASE", nil, "PowerChargesMax")
	output.FrenzyChargesMax = modDB:Sum("BASE", nil, "FrenzyChargesMax")
	output.EnduranceChargesMax = modDB:Sum("BASE", nil, "EnduranceChargesMax")
	if env.configInput.usePowerCharges and env.mode_combat then
		output.PowerCharges = output.PowerChargesMax
	else
		output.PowerCharges = 0
	end
	if env.configInput.useFrenzyCharges and env.mode_combat then
		output.FrenzyCharges = output.FrenzyChargesMax
	else
		output.FrenzyCharges = 0
	end
	if env.configInput.useEnduranceCharges and env.mode_combat then
		output.EnduranceCharges = output.EnduranceChargesMax
	else
		output.EnduranceCharges = 0
	end
	modDB.multipliers["PowerCharge"] = output.PowerCharges
	modDB.multipliers["FrenzyCharge"] = output.FrenzyCharges
	modDB.multipliers["EnduranceCharge"] = output.EnduranceCharges
	if output.PowerCharges == output.PowerChargesMax then
		condList["AtMaxPowerCharges"] = true
	end
	if output.FrenzyCharges == output.FrenzyChargesMax then
		condList["AtMaxFrenzyCharges"] = true
	end
	if output.EnduranceCharges == output.EnduranceChargesMax then
		condList["AtMaxEnduranceCharges"] = true
	end

	-- Add misc buffs
	if env.mode_combat then
		if condList["Onslaught"] then
			local effect = m_floor(20 * (1 + modDB:Sum("INC", nil, "OnslaughtEffect") / 100))
			modDB:NewMod("Speed", "INC", effect, "Onslaught")
			modDB:NewMod("MovementSpeed", "INC", effect, "Onslaught")
		end
		if condList["UnholyMight"] then
			modDB:NewMod("PhysicalDamageGainAsChaos", "BASE", 30, "Unholy Might")
		end
	end

	-- Helper functions for stat breakdowns
	local simpleBreakdown, modBreakdown, slotBreakdown, effMultBreakdown, dotBreakdown
	if breakdown then
		simpleBreakdown = function(extraBase, cfg, ...)
			extraBase = extraBase or 0
			local base = modDB:Sum("BASE", cfg, (...))
			if (base + extraBase) ~= 0 then
				local inc = modDB:Sum("INC", cfg, ...)
				local more = modDB:Sum("MORE", cfg, ...)
				if inc ~= 0 or more ~= 1 or (base ~= 0 and extraBase ~= 0) then
					local out = { }
					if base ~= 0 and extraBase ~= 0 then
						out[1] = s_format("(%g + %g) ^8(base)", extraBase, base)
					else
						out[1] = s_format("%g ^8(base)", base + extraBase)
					end
					if inc ~= 0 then
						t_insert(out, s_format("x %.2f", 1 + inc/100).." ^8(increased/reduced)")
					end
					if more ~= 1 then
						t_insert(out, s_format("x %.2f", more).." ^8(more/less)")
					end
					t_insert(out, s_format("= %g", output[...]))
					breakdown[...] = out
				end
			end
		end
		modBreakdown = function(cfg, ...)
			local inc = modDB:Sum("INC", cfg, ...)
			local more = modDB:Sum("MORE", cfg, ...)
			if inc ~= 0 and more ~= 1 then
				return { 
					s_format("%.2f", 1 + inc/100).." ^8(increased/reduced)",
					s_format("x %.2f", more).." ^8(more/less)",
					s_format("= %.2f", (1 + inc/100) * more),
				}
			end
		end
		slotBreakdown = function(source, sourceName, cfg, base, total, ...)
			local inc = modDB:Sum("INC", cfg, ...)
			local more = modDB:Sum("MORE", cfg, ...)
			t_insert(breakdown[...].slots, {
				base = base,
				inc = (inc ~= 0) and s_format(" x %.2f", 1 + inc/100),
				more = (more ~= 1) and s_format(" x %.2f", more),
				total = s_format("%.2f", total or (base * (1 + inc / 100) * more)),
				source = source,
				sourceName = sourceName,
				item = env.itemList[source],
			})
		end
		effMultBreakdown = function(damageType, resist, pen, taken, mult)
			local out = { }
			local resistForm = (damageType == "Physical") and "physical damage reduction" or "resistance"
			if resist ~= 0 then
				t_insert(out, s_format("Enemy %s: %d%%", resistForm, resist))
			end
			if pen ~= 0 then
				t_insert(out, "Effective resistance:")
				t_insert(out, s_format("%d%% ^8(resistance)", resist))
				t_insert(out, s_format("- %d%% ^8(penetration)", pen))
				t_insert(out, s_format("= %d%%", resist - pen))
			end
			if (resist - pen) ~= 0 and taken ~= 0 then
				t_insert(out, "Effective DPS modifier:")
				t_insert(out, s_format("%.2f ^8(%s)", 1 - (resist - pen) / 100, resistForm))
				t_insert(out, s_format("x %.2f ^8(increased/reduced damage taken)", 1 + taken / 100))
				t_insert(out, s_format("= %.3f", mult))
			end
			return out
		end
		dotBreakdown = function(out, baseVal, inc, more, effMult, total)
			t_insert(out, s_format("%.1f ^8(base damage per second)", baseVal))
			if inc ~= 0 then
				t_insert(out, s_format("x %.2f ^8(increased/reduced)", 1 + inc/100))
			end
			if more ~= 1 then
				t_insert(out, s_format("x %.2f ^8(more/less)", more))
			end
			if effMult ~= 1 then
				t_insert(out, s_format("x %.3f ^8(effective DPS modifier)", effMult))
			end
			t_insert(out, s_format("= %.1f ^8per second", total))
		end
	end

	-- Calculate attributes
	for _, stat in pairs({"Str","Dex","Int"}) do
		output[stat] = round(calcVal(modDB, stat))
		if breakdown then
			simpleBreakdown(nil, nil, stat)
		end
	end

	-- Add attribute bonuses
	modDB:NewMod("Life", "BASE", m_floor(output.Str / 2), "Strength")
	local strDmgBonus = round((output.Str + modDB:Sum("BASE", nil, "DexIntToMeleeBonus")) / 5)
	modDB:NewMod("PhysicalDamage", "INC", strDmgBonus, "Strength", ModFlag.Melee)
	modDB:NewMod("Accuracy", "BASE", output.Dex * 2, "Dexterity")
	if not modDB:Sum("FLAG", nil, "IronReflexes") then
		modDB:NewMod("Evasion", "INC", round(output.Dex / 5), "Dexterity")
	end
	modDB:NewMod("Mana", "BASE", round(output.Int / 2), "Intelligence")
	modDB:NewMod("EnergyShield", "INC", round(output.Int / 5), "Intelligence")

	-- ---------------------- --
	-- Defensive Calculations --
	-- ---------------------- --

	-- Life/mana pools
	if modDB:Sum("FLAG", nil, "ChaosInoculation") then
		output.Life = 1
		condList["FullLife"] = true
	else
		local base = modDB:Sum("BASE", cfg, "Life")
		local inc = modDB:Sum("INC", cfg, "Life")
		local more = modDB:Sum("MORE", cfg, "Life")
		local conv = modDB:Sum("BASE", nil, "LifeConvertToEnergyShield")
		output.Life = round(base * (1 + inc/100) * more * (1 - conv/100))
		if breakdown then
			if inc ~= 0 or more ~= 1 or conv ~= 0 then
				breakdown.Life = { }
				breakdown.Life[1] = s_format("%g ^8(base)", base)
				if inc ~= 0 then
					t_insert(breakdown.Life, s_format("x %.2f ^8(increased/reduced)", 1 + inc/100))
				end
				if more ~= 1 then
					t_insert(breakdown.Life, s_format("x %.2f ^8(more/less)", more))
				end
				if conv ~= 0 then
					t_insert(breakdown.Life, s_format("x %.2f ^8(converted to Energy Shield)", 1 - conv/100))
				end
				t_insert(breakdown.Life, s_format("= %g", output.Life))
			end
		end
	end
	output.Mana = round(calcVal(modDB, "Mana"))
	output.ManaRegen = round((modDB:Sum("BASE", nil, "ManaRegen") + output.Mana * modDB:Sum("BASE", nil, "ManaRegenPercent") / 100) * calcMod(modDB, nil, "ManaRegen", "ManaRecovery"), 1)
	if breakdown then
		simpleBreakdown(nil, nil, "Mana")
		simpleBreakdown(nil, nil, "ManaRegen", "ManaRecovery")
	end

	-- Life/mana reservation
	for _, pool in pairs({"Life", "Mana"}) do
		local max = output[pool]
		local reserved = env["reserved_"..pool.."Base"] + m_ceil(max * env["reserved_"..pool.."Percent"] / 100)
		output[pool.."Reserved"] = reserved
		output[pool.."ReservedPercent"] = reserved / max * 100
		output[pool.."Unreserved"] = max - reserved
		output[pool.."UnreservedPercent"] = (max - reserved) / max * 100
		if (max - reserved) / max <= 0.35 then
			condList["Low"..pool] = true
		end
		if reserved == 0 then
			condList["No"..pool.."Reserved"] = true
		end
	end

	-- Resistances
	for _, elem in ipairs(resistTypeList) do
		local max, total
		if elem == "Chaos" and modDB:Sum("FLAG", nil, "ChaosInoculation") then
			max = 100
			total = 100
		else
			max = modDB:Sum("BASE", nil, elem.."ResistMax")
			total = modDB:Sum("BASE", nil, elem.."Resist", isElemental[elem] and "ElementalResist")
		end
		output[elem.."Resist"] = m_min(total, max)
		output[elem.."ResistTotal"] = total
		output[elem.."ResistOverCap"] = m_max(0, total - max)
		if breakdown then
			breakdown[elem.."Resist"] = {
				"Max: "..max.."%",
				"Total: "..total.."%",
				"In hideout: "..(total + 60).."%",
			}
		end
	end

	-- Primary defences: Energy shield, evasion and armour
	do
		local ironReflexes = modDB:Sum("FLAG", nil, "IronReflexes")
		local energyShield = 0
		local armour = 0
		local evasion = 0
		if breakdown then
			breakdown.EnergyShield = { slots = { } }
			breakdown.Armour = { slots = { } }
			breakdown.Evasion = { slots = { } }
		end
		local energyShieldBase = modDB:Sum("BASE", nil, "EnergyShield")
		if energyShieldBase > 0 then
			energyShield = energyShield + energyShieldBase * calcMod(modDB, nil, "EnergyShield", "Defences")
			if breakdown then
				slotBreakdown("Global", nil, nil, energyShieldBase, nil, "EnergyShield", "Defences")
			end
		end
		local armourBase = modDB:Sum("BASE", nil, "Armour", "ArmourAndEvasion")
		if armourBase > 0 then
			armour = armour + armourBase * calcMod(modDB, nil, "Armour", "ArmourAndEvasion", "Defences")
			if breakdown then
				slotBreakdown("Global", nil, nil, armourBase, nil, "Armour", "ArmourAndEvasion", "Defences")
			end
		end
		local evasionBase = modDB:Sum("BASE", nil, "Evasion", "ArmourAndEvasion")
		if evasionBase > 0 then
			if ironReflexes then
				armour = armour + evasionBase * calcMod(modDB, nil, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
				if breakdown then
					slotBreakdown("Conversion", "Evasion to Armour", nil, evasionBase, nil, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
				end
			else
				evasion = evasion + evasionBase * calcMod(modDB, nil, "Evasion", "ArmourAndEvasion", "Defences")
				if breakdown then
					slotBreakdown("Global", nil, nil, evasionBase, nil, "Evasion", "ArmourAndEvasion", "Defences")
				end
			end
		end
		local gearEnergyShield = 0
		local gearArmour = 0
		local gearEvasion = 0
		local slotCfg = wipeTable(tempTable1)
		for _, slot in pairs({"Helmet","Body Armour","Gloves","Boots","Weapon 2"}) do
			local armourData = env.itemList[slot] and env.itemList[slot].armourData
			if armourData then
				slotCfg.slotName = slot
				energyShieldBase = armourData.EnergyShield or 0
				if energyShieldBase > 0 then
					energyShield = energyShield + energyShieldBase * calcMod(modDB, slotCfg, "EnergyShield", "Defences")
					gearEnergyShield = gearEnergyShield + energyShieldBase
					if breakdown then
						slotBreakdown(slot, nil, slotCfg, energyShieldBase, nil, "EnergyShield", "Defences")
					end
				end
				armourBase = armourData.Armour or 0
				if armourBase > 0 then
					if slot == "Body Armour" and modDB:Sum("FLAG", nil, "Unbreakable") then
						armourBase = armourBase * 2
					end
					armour = armour + armourBase * calcMod(modDB, slotCfg, "Armour", "ArmourAndEvasion", "Defences")
					gearArmour = gearArmour + armourBase
					if breakdown then
						slotBreakdown(slot, nil, slotCfg, armourBase, nil, "Armour", "ArmourAndEvasion", "Defences")
					end
				end
				evasionBase = armourData.Evasion or 0
				if evasionBase > 0 then
					if ironReflexes then
						armour = armour + evasionBase * calcMod(modDB, slotCfg, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
						gearArmour = gearArmour + evasionBase
						if breakdown then
							slotBreakdown(slot, nil, slotCfg, evasionBase, nil, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
						end
					else
						evasion = evasion + evasionBase * calcMod(modDB, slotCfg, "Evasion", "ArmourAndEvasion", "Defences")
						gearEvasion = gearEvasion + evasionBase
						if breakdown then
							slotBreakdown(slot, nil, slotCfg, evasionBase, nil, "Evasion", "ArmourAndEvasion", "Defences")
						end
					end
				end
			end
		end
		local convManaToES = modDB:Sum("BASE", nil, "ManaGainAsEnergyShield")
		if convManaToES > 0 then
			energyShieldBase = modDB:Sum("BASE", nil, "Mana") * convManaToES / 100
			energyShield = energyShield + energyShieldBase * calcMod(modDB, nil, "Mana", "EnergyShield", "Defences") 
			if breakdown then
				slotBreakdown("Conversion", "Mana to Energy Shield", nil, energyShieldBase, nil, "EnergyShield", "Defences", "Mana")
			end
		end
		local convLifeToES = modDB:Sum("BASE", nil, "LifeConvertToEnergyShield")
		if convLifeToES > 0 then
			energyShieldBase = modDB:Sum("BASE", nil, "Life") * convLifeToES / 100
			local total
			if modDB:Sum("FLAG", nil, "ChaosInoculation") then
				total = 1
			else
				total = energyShieldBase * calcMod(modDB, nil, "Life", "EnergyShield", "Defences")
			end
			energyShield = energyShield + total
			if breakdown then
				slotBreakdown("Conversion", "Life to Energy Shield", nil, energyShieldBase, total, "EnergyShield", "Defences", "Life")
			end
		end
		output.EnergyShield = round(energyShield)
		output.Armour = round(armour)
		output.Evasion = round(evasion)
		output.LowestOfArmourAndEvasion = m_min(output.Armour, output.Evasion)
		output["Gear:EnergyShield"] = gearEnergyShield
		output["Gear:Armour"] = gearArmour
		output["Gear:Evasion"] = gearEvasion
		output.EnergyShieldRecharge = round(output.EnergyShield * 0.2 * calcMod(modDB, nil, "EnergyShieldRecharge", "EnergyShieldRecovery"), 1)
		output.EnergyShieldRechargeDelay = 2 / (1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100)
		if breakdown then
			simpleBreakdown(output.EnergyShield * 0.2, nil, "EnergyShieldRecharge", "EnergyShieldRecovery")
			if output.EnergyShieldRechargeDelay ~= 2 then
				breakdown.EnergyShieldRechargeDelay = {
					"2.00s ^8(base)",
					s_format("/ %.2f ^8(faster start)", 1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100),
					s_format("= %.2fs", output.EnergyShieldRechargeDelay)
				}
			end
		end
		if modDB:Sum("FLAG", nil, "CannotEvade") then
			output.EvadeChance = 0
		else
			local enemyAccuracy = round(calcVal(enemyDB, "Accuracy"))
			output.EvadeChance = 100 - calcHitChance(output.Evasion, enemyAccuracy)
			if breakdown then
				breakdown.EvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
					s_format("Approximate evade chance: %d%%", output.EvadeChance),
				}
			end
		end
	end

	-- Life and energy shield regen
	do
		if modDB:Sum("FLAG", nil, "NoLifeRegen") then
			output.LifeRegen = 0
		elseif modDB:Sum("FLAG", nil, "ZealotsOath") then
			output.LifeRegen = 0
			local lifeBase = modDB:Sum("BASE", nil, "LifeRegen")
			if lifeBase > 0 then
				modDB:NewMod("EnergyShieldRegen", "BASE", lifeBase, "Zealot's Oath")
			end
			local lifePercent = modDB:Sum("BASE", nil, "LifeRegenPercent")
			if lifePercent > 0 then
				modDB:NewMod("EnergyShieldRegenPercent", "BASE", lifePercent, "Zealot's Oath")
			end
		else
			local lifeBase = modDB:Sum("BASE", nil, "LifeRegen")
			local lifePercent = modDB:Sum("BASE", nil, "LifeRegenPercent")
			if lifePercent > 0 then
				lifeBase = lifeBase + output.Life * lifePercent / 100
			end
			if lifeBase > 0 then
				output.LifeRegen = lifeBase * calcMod(modDB, nil, "LifeRecovery")
				output.LifeRegenPercent = round(lifeBase / output.Life * 100, 1)
			else
				output.LifeRegen = 0
			end
		end
		local esBase = modDB:Sum("BASE", nil, "EnergyShieldRegen")
		local esPercent = modDB:Sum("BASE", nil, "EnergyShieldRegenPercent")
		if esPercent > 0 then
			esBase = esBase + output.EnergyShield * esPercent / 100
		end
		if esBase > 0 then
			output.EnergyShieldRegen = esBase * calcMod(modDB, nil, "EnergyShieldRecovery")
			output.EnergyShieldRegenPercent = round(esBase / output.EnergyShield * 100, 1)
		else
			output.EnergyShieldRegen = 0
		end
	end

	-- Other defences: block, dodge, stun recovery/avoidance
	do
		output.BlockChanceMax = modDB:Sum("BASE", nil, "BlockChanceMax")
		local shieldData = env.itemList["Weapon 2"] and env.itemList["Weapon 2"].armourData
		output.BlockChance = m_min(((shieldData and shieldData.BlockChance or 0) + modDB:Sum("BASE", nil, "BlockChance")) * calcMod(modDB, nil, "BlockChance"), output.BlockChanceMax) 
		output.SpellBlockChance = m_min(modDB:Sum("BASE", nil, "SpellBlockChance") * calcMod(modDB, nil, "SpellBlockChance") + output.BlockChance * modDB:Sum("BASE", nil, "BlockChanceConv") / 100, output.BlockChanceMax) 
		if breakdown then
			simpleBreakdown(shieldData and shieldData.BlockChance, nil, "BlockChance")
			simpleBreakdown(output.BlockChance * modDB:Sum("BASE", nil, "BlockChanceConv") / 100, nil, "SpellBlockChance")
		end
		if modDB:Sum("FLAG", nil, "CannotBlockAttacks") then
			output.BlockChance = 0
		end
		output.AttackDodgeChance = m_min(modDB:Sum("BASE", nil, "AttackDodgeChance"), 75)
		output.SpellDodgeChance = m_min(modDB:Sum("BASE", nil, "SpellDodgeChance"), 75)
		local stunChance = 100 - modDB:Sum("BASE", nil, "AvoidStun")
		if output.EnergyShield > output.Life * 2 then
			stunChance = stunChance * 0.5
		end
		output.StunAvoidChance = 100 - stunChance
		if output.StunAvoidChance >= 100 then
			output.StunDuration = 0
			output.BlockDuration = 0
		else
			output.StunDuration = 0.35 / (1 + modDB:Sum("INC", nil, "StunRecovery") / 100)
			output.BlockDuration = 0.35 / (1 + modDB:Sum("INC", nil, "StunRecovery", "BlockRecovery") / 100)
			if breakdown then
				breakdown.StunDuration = {
					"0.35s ^8(base)",
					s_format("/ %.2f ^8(increased/reduced recovery)", 1 + modDB:Sum("INC", nil, "StunRecovery") / 100),
					s_format("= %.2fs", output.StunDuration)
				}
				breakdown.BlockDuration = {
					"0.35s ^8(base)",
					s_format("/ %.2f ^8(increased/reduced recovery)", 1 + modDB:Sum("INC", nil, "StunRecovery", "BlockRecovery") / 100),
					s_format("= %.2fs", output.BlockDuration)
				}
			end
		end
	end

	-- ---------------------- --
	-- Offensive Calculations --
	-- ---------------------- --

	-- Merge main skill mods
	modDB:AddList(env.mainSkill.skillModList)

	local skillData = env.mainSkill.skillData
	local skillFlags = env.mainSkill.skillFlags
	local skillCfg = env.mainSkill.skillCfg
	if env.mode_buffs then
		skillFlags.buffs = true
	end
	if env.mode_combat then
		skillFlags.combat = true
	end
	if env.mode_effective then
		skillFlags.effective = true
	end
	if not env.mode_average then
		skillFlags.notAverage = true
	end

	-- Update skill data
	for _, value in ipairs(modDB:Sum("LIST", skillCfg, "Misc")) do
		if value.type == "SkillData" then
			skillData[value.key] = value.value
		end
	end

	env.modDB.conditions["SkillIsTriggered"] = skillData.triggered

	-- Add addition stat bonuses
	if modDB:Sum("FLAG", nil, "IronGrip") then
		modDB:NewMod("PhysicalDamage", "INC", strDmgBonus, "Strength", bor(ModFlag.Attack, ModFlag.Projectile))
	end
	if modDB:Sum("FLAG", nil, "IronWill") then
		modDB:NewMod("Damage", "INC", strDmgBonus, "Strength", ModFlag.Spell)
	end

	if modDB:Sum("FLAG", nil, "MinionDamageAppliesToPlayer") then
		-- Minion Damage conversion from The Scourge
		for _, mod in ipairs(modDB.mods.Damage or { }) do
			if mod.type == "INC" and mod.keywordFlags == KeywordFlag.Minion then
				modDB:NewMod("Damage", "INC", mod.value, mod.source, 0, 0, unpack(mod.tagList))
			end
		end
	end
	if modDB:Sum("FLAG", nil, "SpellDamageAppliesToAttacks") then
		-- Spell Damage conversion from Crown of Eyes
		for i, mod in ipairs(modDB.mods.Damage or { }) do
			if mod.type == "INC" and band(mod.flags, ModFlag.Spell) ~= 0 then
				modDB:NewMod("Damage", "INC", mod.value, mod.source, bor(band(mod.flags, bnot(ModFlag.Spell)), ModFlag.Attack), mod.keywordFlags, unpack(mod.tagList))
			end
		end
	end

	-- Calculate skill type stats
	if skillFlags.projectile then
		output.ProjectileCount = modDB:Sum("BASE", skillCfg, "ProjectileCount")
		output.PierceChance = m_min(100, modDB:Sum("BASE", skillCfg, "PierceChance"))
		output.ProjectileSpeedMod = calcMod(modDB, skillCfg, "ProjectileSpeed")
		if breakdown then
			breakdown.ProjectileSpeedMod = modBreakdown(skillCfg, "ProjectileSpeed")
		end
	end
	if skillFlags.area then
		output.AreaRadiusMod = calcMod(modDB, skillCfg, "AreaRadius")
		if breakdown then
			breakdown.AreaRadiusMod = modBreakdown(skillCfg, "AreaRadius")
		end
	end
	if skillFlags.trap then
		output.ActiveTrapLimit = modDB:Sum("BASE", skillCfg, "ActiveTrapLimit")
		output.TrapCooldown = (skillData.trapCooldown or 4) / calcMod(modDB, skillCfg, "TrapCooldownRecovery")
		if breakdown then
			breakdown.TrapCooldown = {
				s_format("%.2fs ^8(base)", skillData.trapCooldown or 4),
				s_format("/ %.2f ^8(increased/reduced cooldown recovery)", 1 + modDB:Sum("INC", skillCfg, "TrapCooldownRecovery") / 100),
				s_format("= %.2fs", output.TrapCooldown)
			}
		end
	end
	if skillFlags.mine then
		output.ActiveMineLimit = modDB:Sum("BASE", skillCfg, "ActiveMineLimit")
	end
	if skillFlags.totem then
		output.ActiveTotemLimit = modDB:Sum("BASE", skillCfg, "ActiveTotemLimit")
		output.TotemLifeMod = calcMod(modDB, skillCfg, "TotemLife")
		output.TotemLife = round(data.monsterLifeTable[skillData.totemLevel] * data.totemLifeMult[env.mainSkill.skillTotemId] * output.TotemLifeMod)
		if breakdown then
			breakdown.TotemLifeMod = modBreakdown(skillCfg, "TotemLife")
			breakdown.TotemLife = {
				"Totem level: "..skillData.totemLevel,
				data.monsterLifeTable[skillData.totemLevel].." ^8(base life for a level "..skillData.totemLevel.." monster)",
				"x "..data.totemLifeMult[env.mainSkill.skillTotemId].." ^8(life multiplier for this totem type)",
				"x "..output.TotemLifeMod.." ^8(totem life modifier)",
				"= "..output.TotemLife,
			}
		end
	end

	-- Skill duration
	local debuffDurationMult
	if env.mode_effective then
		debuffDurationMult = 1 / calcMod(enemyDB, skillCfg, "BuffExpireFaster")
	else
		debuffDurationMult = 1
	end
	do
		output.DurationMod = calcMod(modDB, skillCfg, "Duration")
		if breakdown then
			breakdown.DurationMod = modBreakdown(skillCfg, "Duration")
		end
		local durationBase = skillData.duration or 0
		if durationBase > 0 then
			output.Duration = durationBase * output.DurationMod
			if skillData.debuff then
				output.Duration = output.Duration * debuffDurationMult
			end
			if breakdown and output.Duration ~= durationBase then
				breakdown.Duration = {
					s_format("%.2fs ^8(base)", durationBase),
				}
				if output.DurationMod ~= 1 then
					t_insert(breakdown.Duration, s_format("x %.2f ^8(duration modifier)", output.DurationMod))
				end
				if skillData.debuff and debuffDurationMult ~= 1 then
					t_insert(breakdown.Duration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
				end
				t_insert(breakdown.Duration, s_format("= %.2fs", output.Duration))
			end
		end
	end

	-- Run skill setup function
	do
		local setupFunc = env.mainSkill.activeGem.data.setupFunc
		if setupFunc then
			setupFunc(env, output)
		end
	end

	local isAttack = (env.mode_skillType == "ATTACK")

	-- Cache global damage disabling flags
	local canDeal = { }
	for _, damageType in pairs(dmgTypeList) do
		canDeal[damageType] = not modDB:Sum("FLAG", skillCfg, "DealNo"..damageType)
	end

	-- Calculate enemy resistances
	do
		local elemResist = enemyDB:Sum("BASE", nil, "ElementalResist")
		for _, damageType in pairs({"Lightning","Cold","Fire"}) do
			output["Enemy"..damageType.."Resist"] = m_min(enemyDB:Sum("BASE", nil, damageType.."Resist") + elemResist, 75)
		end
		output.EnemyChaosResist = m_min(enemyDB:Sum("BASE", nil, "ChaosResist"), 75)
	end

	-- Calculate damage conversion percentages
	env.conversionTable = wipeTable(env.conversionTable)
	for damageTypeIndex = 1, 4 do
		local damageType = dmgTypeList[damageTypeIndex]
		local globalConv = wipeTable(tempTable1)
		local skillConv = wipeTable(tempTable2)
		local add = wipeTable(tempTable3)
		local globalTotal, skillTotal = 0, 0
		for otherTypeIndex = damageTypeIndex + 1, 5 do
			-- For all possible destination types, check for global and skill conversions
			otherType = dmgTypeList[otherTypeIndex]
			globalConv[otherType] = modDB:Sum("BASE", skillCfg, damageType.."DamageConvertTo"..otherType, isElemental[damageType] and "ElementalDamageConvertTo"..otherType or nil)
			globalTotal = globalTotal + globalConv[otherType]
			skillConv[otherType] = modDB:Sum("BASE", skillCfg, "Skill"..damageType.."DamageConvertTo"..otherType)
			skillTotal = skillTotal + skillConv[otherType]
			add[otherType] = modDB:Sum("BASE", skillCfg, damageType.."DamageGainAs"..otherType, isElemental[damageType] and "ElementalDamageGainAs"..otherType or nil)
		end
		if skillTotal > 100 then
			-- Skill conversion exceeds 100%, scale it down and remove non-skill conversions
			local factor = 100 / skillTotal
			for type, val in pairs(skillConv) do
				-- The game currently doesn't scale this down even though it is supposed to
				--skillConv[type] = val * factor
			end
			for type, val in pairs(globalConv) do
				globalConv[type] = 0
			end
		elseif globalTotal + skillTotal > 100 then
			-- Conversion exceeds 100%, scale down non-skill conversions
			local factor = (100 - skillTotal) / globalTotal
			for type, val in pairs(globalConv) do
				globalConv[type] = val * factor
			end
			globalTotal = globalTotal * factor
		end
		local dmgTable = { }
		for type, val in pairs(globalConv) do
			dmgTable[type] = (globalConv[type] + skillConv[type] + add[type]) / 100
		end
		dmgTable.mult = 1 - m_min((globalTotal + skillTotal) / 100, 1)
		env.conversionTable[damageType] = dmgTable
	end
	env.conversionTable["Chaos"] = { mult = 1 }
	
	-- Calculate hit chance
	output.Accuracy = calcVal(modDB, "Accuracy", skillCfg)
	if breakdown then
		simpleBreakdown(nil, skillCfg, "Accuracy")
	end
	if not isAttack or modDB:Sum("FLAG", skillCfg, "CannotBeEvaded") or env.weaponData1.CannotBeEvaded or skillData.cannotBeEvaded then
		output.HitChance = 100
	else
		local enemyEvasion = round(calcVal(enemyDB, "Evasion"))
		output.HitChance = calcHitChance(enemyEvasion, output.Accuracy)
		if breakdown then
			breakdown.HitChance = {
				"Enemy level: "..env.enemyLevel..(env.configInput.enemyLevel and " ^8(overridden from the Configuration tab" or " ^8(can be overridden in the Configuration tab)"),
				"Average enemy evasion: "..enemyEvasion,
				"Approximate hit chance: "..output.HitChance.."%",
			}
		end
	end

	-- Calculate attack/cast speed
	do
		local baseSpeed
		if skillData.timeOverride then
			output.Time = skillData.timeOverride
			output.Speed = 1 / output.Time
		else
			if isAttack then
				if skillData.castTimeOverridesAttackTime then
					-- Skill is overriding weapon attack speed
					baseSpeed = 1 / skillData.castTime * (1 + (env.weaponData1.AttackSpeedInc or 0) / 100)
				else
					baseSpeed = env.weaponData1.attackRate or 1
				end
			else
				baseSpeed = 1 / (skillData.castTime or 1)
			end
			output.Speed = baseSpeed * calcMod(modDB, skillCfg, "Speed")
			output.Time = 1 / output.Speed
			if breakdown then
				simpleBreakdown(baseSpeed, skillCfg, "Speed")
			end
		end
		if skillData.hitTimeOverride then
			output.HitTime = skillData.hitTimeOverride
			output.HitSpeed = 1 / output.HitTime
		end
	end

	-- Calculate crit chance, crit multiplier, and their combined effect
	if modDB:Sum("FLAG", nil, "NeverCrit") then
		output.CritChance = 0
		output.CritMultiplier = 0
		output.CritEffect = 1
	else
		local baseCrit
		if isAttack then
			baseCrit = env.weaponData1.critChance or 0
		else
			baseCrit = skillData.critChance or 0
		end
		if baseCrit == 100 then
			output.CritChance = 100
		else
			local base = modDB:Sum("BASE", skillCfg, "CritChance")
			output.CritChance = (baseCrit + base) * calcMod(modDB, skillCfg, "CritChance")
			if env.mode_effective then
				output.CritChance = output.CritChance + enemyDB:Sum("BASE", nil, "SelfExtraCritChance")
			end
			output.CritChance = m_min(output.CritChance, 95)
			if (baseCrit + base) > 0 then
				output.CritChance = m_max(output.CritChance, 5)
			end
			local actualCritChance = output.CritChance
			if env.mode_effective and modDB:Sum("FLAG", skillCfg, "CritChanceLucky") then
				output.CritChance = (1 - (1 - output.CritChance / 100) ^ 2) * 100
			end
			if breakdown and output.CritChance ~= baseCrit then
				local inc = modDB:Sum("INC", skillCfg, "CritChance")
				local more = modDB:Sum("MORE", skillCfg, "CritChance")
				local enemyExtra = enemyDB:Sum("BASE", nil, "SelfExtraCritChance")
				breakdown.CritChance = { }
				if base ~= 0 then
					t_insert(breakdown.CritChance, s_format("(%g + %g) ^8(base)", baseCrit, base))
				else
					t_insert(breakdown.CritChance, s_format("%g ^8(base)", baseCrit + base))
				end
				if inc ~= 0 then
					t_insert(breakdown.CritChance, s_format("x %.2f", 1 + inc/100).." ^8(increased/reduced)")
				end
				if more ~= 1 then
					t_insert(breakdown.CritChance, s_format("x %.2f", more).." ^8(more/less)")
				end
				if env.mode_effective and enemyExtra ~= 0 then
					t_insert(breakdown.CritChance, s_format("+ %g ^8(extra chance for enemy to be crit)", enemyExtra))
				end
				t_insert(breakdown.CritChance, s_format("= %g", actualCritChance))
				if env.mode_effective and modDB:Sum("FLAG", skillCfg, "CritChanceLucky") then
					t_insert(breakdown.CritChance, "Crit Chance is Lucky:")
					t_insert(breakdown.CritChance, s_format("1 - (1 - %.4f) x (1 - %.4f)", actualCritChance / 100, actualCritChance / 100))
					t_insert(breakdown.CritChance, s_format("= %.2f", output.CritChance))
				end
			end
		end
		if modDB:Sum("FLAG", skillCfg, "NoCritDamage") then
			output.CritMultiplier = 0
		elseif modDB:Sum("FLAG", skillCfg, "NoCritMultiplier") then
			output.CritMultiplier = 1
		else
			local extraDamage = 0.5 + modDB:Sum("BASE", skillCfg, "CritMultiplier") / 100
			if env.mode_effective then
				extraDamage = round(extraDamage * (1 + enemyDB:Sum("INC", nil, "SelfCritMultiplier") / 100), 2)
			end
			output.CritMultiplier = 1 + m_max(0, extraDamage)
			if breakdown and output.CritMultiplier ~= 1.5 then
				breakdown.CritMultiplier = {
					"50% ^8(base)",
				}
				local base = modDB:Sum("BASE", skillCfg, "CritMultiplier")
				if base ~= 0 then
					t_insert(breakdown.CritMultiplier, s_format("+ %d%% ^8(additional extra damage)", base))
				end
				local enemyInc = 1 + enemyDB:Sum("INC", nil, "SelfCritMultiplier") / 100
				if env.mode_effective and enemyInc ~= 1 then
					t_insert(breakdown.CritMultiplier, s_format("x %.2f ^8(increased/reduced extra crit damage taken by enemy)", enemyInc))
				end
				t_insert(breakdown.CritMultiplier, s_format("= %d%% ^8(extra crit damage)", extraDamage * 100))
			end
		end
		output.CritEffect = 1 - output.CritChance / 100 + output.CritChance / 100 * output.CritMultiplier
		if breakdown and output.CritEffect ~= 1 then
			breakdown.CritEffect = {
				s_format("(1 - %g) ^8(portion of damage from non-crits)", output.CritChance/100),
				s_format("+ (%g x %g) ^8(portion of damage from crits)", output.CritChance/100, output.CritMultiplier),
				s_format("= %.3f", output.CritEffect),
			}
		end
	end

	-- Calculate hit damage for each damage type
	local totalMin, totalMax = 0, 0
	do
		local hitSource = (env.mode_skillType == "ATTACK") and env.weaponData1 or env.mainSkill.skillData
		for _, damageType in ipairs(dmgTypeList) do
			local min, max
			if skillFlags.hit and canDeal[damageType] then
				if breakdown then
					breakdown[damageType] = {
						damageComponents = { }
					}
				end
				min, max = calcHitDamage(env, hitSource, damageType)
				local convMult = env.conversionTable[damageType].mult
				if breakdown then
					t_insert(breakdown[damageType], "Hit damage:")
					t_insert(breakdown[damageType], s_format("%d to %d ^8(total damage)", min, max))
					if convMult ~= 1 then
						t_insert(breakdown[damageType], s_format("x %g ^8(%g%% converted to other damage types)", convMult, (1-convMult)*100))
					end
				end
				min = min * convMult
				max = max * convMult
				if (min ~= 0 or max ~= 0) and env.mode_effective then
					-- Apply enemy resistances and damage taken modifiers
					local preMult
					local resist = 0
					local pen = 0
					local taken = enemyDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken")
					if isElemental[damageType] then
						resist = output["Enemy"..damageType.."Resist"]
						pen = modDB:Sum("BASE", skillCfg, damageType.."Penetration", "ElementalPenetration")
						taken = taken + enemyDB:Sum("INC", nil, "ElementalDamageTaken")
					elseif damageType == "Chaos" then
						resist = output.EnemyChaosResist
					else
						resist = enemyDB:Sum("INC", nil, "PhysicalDamageReduction")
					end
					if skillFlags.projectile then
						taken = taken + enemyDB:Sum("INC", nil, "ProjectileDamageTaken")
					end
					local effMult = (1 - (resist - pen) / 100) * (1 + taken / 100)
					min = min * effMult
					max = max * effMult
					if env.mode == "CALCS" then
						output[damageType.."EffMult"] = effMult
					end
					if breakdown and effMult ~= 1 then
						t_insert(breakdown[damageType], s_format("x %.3f ^8(effective DPS modifier)", effMult))
						breakdown[damageType.."EffMult"] = effMultBreakdown(damageType, resist, pen, taken, effMult)
					end
				end
				if breakdown then	
					t_insert(breakdown[damageType], s_format("= %d to %d", min, max))
				end
			else
				min, max = 0, 0
				if breakdown then
					breakdown[damageType] = {
						"You can't deal "..damageType.." damage"
					}
				end
			end
			if env.mode == "CALCS" then
				output[damageType.."Min"] = min
				output[damageType.."Max"] = max
			end
			output[damageType.."Average"] = (min + max) / 2
			totalMin = totalMin + min
			totalMax = totalMax + max
		end
	end
	output.TotalMin = totalMin
	output.TotalMax = totalMax

	-- Update enemy hit-by-damage-type conditions
	enemyDB.conditions.HitByFireDamage = output.FireAverage > 0
	enemyDB.conditions.HitByColdDamage = output.ColdAverage > 0
	enemyDB.conditions.HitByLightningDamage = output.LightningAverage > 0

	-- Calculate average damage and final DPS
	output.AverageHit = (totalMin + totalMax) / 2 * output.CritEffect
	output.AverageDamage = output.AverageHit * output.HitChance / 100
	output.TotalDPS = output.AverageDamage * (output.HitSpeed or output.Speed) * (skillData.dpsMultiplier or 1)
	if env.mode == "CALCS" then
		if env.mode_average then
			output.DisplayDamage = s_format("%.1f average damage", output.AverageDamage)
		else
			output.DisplayDamage = s_format("%.1f DPS", output.TotalDPS)
		end
	end
	if breakdown then
		if output.CritEffect ~= 1 then
			breakdown.AverageHit = {
				s_format("%.1f ^8(non-crit average)", (totalMin + totalMax) / 2),
				s_format("x %.3f ^8(crit effect modifier)", output.CritEffect),
				s_format("= %.1f", output.AverageHit),
			}
		end
		if isAttack then
			breakdown.AverageDamage = {
				s_format("%.1f ^8(average hit)", output.AverageHit),
				s_format("x %.2f ^8(chance to hit)", output.HitChance / 100),
				s_format("%.1f", output.AverageDamage),
			}
			breakdown.TotalDPS = {
				s_format("%.1f ^8(average damage)", output.AverageDamage),
				output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(attack rate)", output.Speed),
			}
		else
			breakdown.TotalDPS = {
				s_format("%.1f ^8(average hit)", output.AverageDamage),
				output.HitSpeed and s_format("x %.2f ^8(hit rate)", output.HitSpeed) or s_format("x %.2f ^8(cast rate)", output.Speed),
			}
		end
		if skillData.dpsMultiplier then
			t_insert(breakdown.TotalDPS, s_format("x %d ^8(DPS multiplier for this skill)", skillData.dpsMultiplier))
		end
		t_insert(breakdown.TotalDPS, s_format("= %.1f", output.TotalDPS))
	end

	-- Calculate mana cost (may be slightly off due to rounding differences)
	do
		local more = m_floor(modDB:Sum("MORE", skillCfg, "ManaCost") * 100 + 0.0001) / 100
		local inc = modDB:Sum("INC", skillCfg, "ManaCost")
		local base = modDB:Sum("BASE", skillCfg, "ManaCost")
		output.ManaCost = m_floor(m_max(0, (skillData.manaCost or 0) * more * (1 + inc / 100) + base))
		if env.mainSkill.skillTypes[SkillType.ManaCostPercent] and skillFlags.totem then
			output.ManaCost = m_floor(output.Mana * output.ManaCost / 100)
		end
		if breakdown and output.ManaCost ~= (skillData.manaCost or 0) then
			breakdown.ManaCost = {
				s_format("%d ^8(base mana cost)", skillData.manaCost or 0)
			}
			if more ~= 1 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(mana cost multiplier)", more))
			end
			if inc ~= 0 then
				t_insert(breakdown.ManaCost, s_format("x %.2f ^8(increased/reduced mana cost)", 1 + inc/100))
			end	
			if base ~= 0 then
				t_insert(breakdown.ManaCost, s_format("- %d ^8(- mana cost)", -base))
			end
			t_insert(breakdown.ManaCost, s_format("= %d", output.ManaCost))
		end
	end

	-- Calculate skill DOT components
	local dotCfg = {
		skillName = skillCfg.skillName,
		skillPart = skillCfg.skillPart,
		slotName = skillCfg.slotName,
		flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
		keywordFlags = skillCfg.keywordFlags
	}
	env.mainSkill.dotCfg = dotCfg
	output.TotalDot = 0
	for _, damageType in ipairs(dmgTypeList) do
		local baseVal 
		if canDeal[damageType] then
			baseVal = skillData[damageType.."Dot"] or 0
		else
			baseVal = 0
		end
		if baseVal > 0 then
			skillFlags.dot = true
			local effMult = 1
			if env.mode_effective then
				local resist = 0
				local taken = enemyDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken", "DotTaken")
				if damageType == "Physical" then
					resist = enemyDB:Sum("INC", nil, "PhysicalDamageReduction")
				else
					if isElemental[damageType] then
						taken = taken + enemyDB:Sum("INC", nil, "ElementalDamageTaken")
					end
					if damageType == "Fire" then
						taken = taken + enemyDB:Sum("INC", nil, "BurningDamageTaken")
					end
					resist = output["Enemy"..damageType.."Resist"]
				end
				effMult = (1 - resist / 100) * (1 + taken / 100)
				output[damageType.."DotEffMult"] = effMult
				if breakdown and effMult ~= 1 then
					breakdown[damageType.."DotEffMult"] = effMultBreakdown(damageType, resist, 0, taken, effMult)
				end
			end
			local inc = modDB:Sum("INC", dotCfg, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil)
			local more = round(modDB:Sum("MORE", dotCfg, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil), 2)
			local total = baseVal * (1 + inc/100) * more * effMult
			output[damageType.."Dot"] = total
			output.TotalDot = output.TotalDot + total
			if breakdown then
				breakdown[damageType.."Dot"] = { }
				dotBreakdown(breakdown[damageType.."Dot"], baseVal, inc, more, effMult, total)
			end
		end
	end

	-- Calculate bleeding chance and damage
	skillFlags.bleed = false
	output.BleedChance = m_min(100, modDB:Sum("BASE", skillCfg, "BleedChance"))
	if canDeal.Physical and not modDB:Sum("FLAG", skillCfg, "CannotBleed") and output.BleedChance > 0 and output.PhysicalAverage > 0 then
		skillFlags.bleed = true
		skillFlags.duration = true
		local dotCfg = {
			slotName = skillCfg.slotName,
			flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
			keywordFlags = bor(skillCfg.keywordFlags, KeywordFlag.Bleed)
		}
		env.mainSkill.bleedCfg = dotCfg
		local baseVal = output.PhysicalAverage * output.CritEffect * 0.1
		local effMult = 1
		if env.mode_effective then
			local resist = enemyDB:Sum("INC", nil, "PhysicalDamageReduction")
			local taken = enemyDB:Sum("INC", dotCfg, "DamageTaken", "PhysicalDamageTaken", "DotTaken")
			effMult = (1 - resist / 100) * (1 + taken / 100)
			output["BleedEffMult"] = effMult
			if breakdown and effMult ~= 1 then
				breakdown.BleedEffMult = effMultBreakdown("Physical", resist, 0, taken, effMult)
			end
		end
		local inc = modDB:Sum("INC", dotCfg, "Damage", "PhysicalDamage")
		local more = round(modDB:Sum("MORE", dotCfg, "Damage", "PhysicalDamage"), 2)
		output.BleedDPS = baseVal * (1 + inc/100) * more * effMult
		output.BleedDuration = 5 * calcMod(modDB, dotCfg, "Duration") * debuffDurationMult
		if breakdown then
			breakdown.BleedDPS = {
				"Base damage:",
				s_format("%.1f ^8(average physical non-crit damage)", output.PhysicalAverage)
			}
			if output.CritEffect ~= 1 then
				t_insert(breakdown.BleedDPS, s_format("x %.3f ^8(crit effect modifier)", output.CritEffect))
			end
			t_insert(breakdown.BleedDPS, "x 0.1 ^8(bleed deals 10% per second)")
			t_insert(breakdown.BleedDPS, s_format("= %.1f", baseVal, 1))
			t_insert(breakdown.BleedDPS, "Bleed DPS:")
			dotBreakdown(breakdown.BleedDPS, baseVal, inc, more, effMult, output.BleedDPS)
			if output.BleedDuration ~= 5 then
				breakdown.BleedDuration = {
					"5.00s ^8(base duration)"
				}
				if output.DurationMod ~= 1 then
					t_insert(breakdown.BleedDuration, s_format("x %.2f ^8(duration modifier)", output.DurationMod))
				end
				if debuffDurationMult ~= 1 then
					t_insert(breakdown.BleedDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
				end
				t_insert(breakdown.BleedDuration, s_format("= %.2fs", output.BleedDuration))
			end
		end
	end	

	-- Calculate poison chance and damage
	skillFlags.poison = false
	output.PoisonChance = m_min(100, modDB:Sum("BASE", skillCfg, "PoisonChance"))
	if canDeal.Chaos and output.PoisonChance > 0 and (output.PhysicalAverage > 0 or output.ChaosAverage > 0) then
		skillFlags.poison = true
		skillFlags.duration = true
		local dotCfg = {
			slotName = skillCfg.slotName,
			flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
			keywordFlags = bor(skillCfg.keywordFlags, KeywordFlag.Poison)
		}
		env.mainSkill.poisonCfg = dotCfg
		local poisonCritEffect = 1 - output.CritChance / 100 + output.CritChance / 100 * output.CritMultiplier * modDB:Sum("MORE", skillCfg, "PoisonDamageOnCrit")
		local baseVal = (output.PhysicalAverage + output.ChaosAverage) * poisonCritEffect * 0.08
		local effMult = 1
		if env.mode_effective then
			local resist = output["EnemyChaosResist"]
			local taken = enemyDB:Sum("INC", nil, "DamageTaken", "ChaosDamageTaken", "DotTaken")
			effMult = (1 - resist / 100) * (1 + taken / 100)
			output["PoisonEffMult"] = effMult
			if breakdown then
				breakdown.PoisonEffMult = effMultBreakdown("Chaos", resist, 0, taken, effMult)
			end
		end
		local inc = modDB:Sum("INC", dotCfg, "Damage", "ChaosDamage")
		local more = round(modDB:Sum("MORE", dotCfg, "Damage", "ChaosDamage"), 2)
		output.PoisonDPS = baseVal * (1 + inc/100) * more * effMult
		local durationBase
		if skillData.poisonDurationIsSkillDuration then
			durationBase = skillData.duration
		else
			durationBase = 2
		end
		output.PoisonDuration = durationBase * calcMod(modDB, dotCfg, "Duration") * debuffDurationMult
		output.PoisonDamage = output.PoisonDPS * output.PoisonDuration
		if breakdown then
			breakdown.PoisonDPS = { }
			if poisonCritEffect ~= output.CritEffect then
				t_insert(breakdown.PoisonDPS, "Crit effect modifier for poison base damage:")
				t_insert(breakdown.PoisonDPS, s_format("(1 - %g) ^8(portion of damage from non-crits)", output.CritChance/100))
				t_insert(breakdown.PoisonDPS, s_format("+ (%g x %g x %g) ^8(portion of damage from crits)", output.CritChance/100, output.CritMultiplier, modDB:Sum("MORE", skillCfg, "PoisonDamageOnCrit")))
				t_insert(breakdown.PoisonDPS, s_format("= %.3f", poisonCritEffect))
			end
			t_insert(breakdown.PoisonDPS, "Base damage:")
			t_insert(breakdown.PoisonDPS, s_format("%.1f ^8(average physical + chaos non-crit damage)", output.PhysicalAverage + output.ChaosAverage))
			if output.CritEffect ~= 1 then
				t_insert(breakdown.PoisonDPS, s_format("x %.3f ^8(crit effect modifier)", poisonCritEffect))
			end
			t_insert(breakdown.PoisonDPS, "x 0.08 ^8(poison deals 8% per second)")
			t_insert(breakdown.PoisonDPS, s_format("= %.1f", baseVal, 1))
			t_insert(breakdown.PoisonDPS, "Poison DPS:")
			dotBreakdown(breakdown.PoisonDPS, baseVal, inc, more, effMult, output.PoisonDPS)
			if output.PoisonDuration ~= 2 then
				breakdown.PoisonDuration = {
					s_format("%.2fs ^8(base duration)", durationBase)
				}
				if output.DurationMod ~= 1 then
					t_insert(breakdown.PoisonDuration, s_format("x %.2f ^8(duration modifier)", output.DurationMod))
				end
				if debuffDurationMult ~= 1 then
					t_insert(breakdown.PoisonDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
				end
				t_insert(breakdown.PoisonDuration, s_format("= %.2fs", output.PoisonDuration))
			end
			breakdown.PoisonDamage = {
				s_format("%.1f ^8(damage per second)", output.PoisonDPS),
				s_format("x %.2fs ^8(poison duration)", output.PoisonDuration),
				s_format("= %.1f ^8damage per poison stack", output.PoisonDamage),s
			}
		end
	end	

	-- Calculate ignite chance and damage
	skillFlags.ignite = false
	if modDB:Sum("FLAG", skillCfg, "CannotIgnite") then
		output.IgniteChance = 0
	else
		local igniteMode = env.configInput.igniteMode or "AVERAGE"
		output.IgniteChance = m_min(100, modDB:Sum("BASE", skillCfg, "EnemyIgniteChance") + enemyDB:Sum("BASE", nil, "SelfIgniteChance"))
		local sourceDmg = 0
		if canDeal.Fire and not modDB:Sum("FLAG", skillCfg, "FireCannotIgnite") then
			sourceDmg = sourceDmg + output.FireAverage
		end
		if canDeal.Cold and modDB:Sum("FLAG", skillCfg, "ColdCanIgnite") then
			sourceDmg = sourceDmg + output.ColdAverage
		end
		if canDeal.Fire and (output.IgniteChance > 0 or igniteMode == "CRIT") and sourceDmg > 0 then
			skillFlags.ignite = true
			local dotCfg = {
				slotName = skillCfg.slotName,
				flags = bor(band(skillCfg.flags, ModFlag.SourceMask), ModFlag.Dot, skillData.dotIsSpell and ModFlag.Spell or 0),
				keywordFlags = skillCfg.keywordFlags,
			}
			env.mainSkill.igniteCfg = dotCfg
			local baseVal
			if igniteMode == "CRIT" then
				baseVal = sourceDmg * output.CritMultiplier * 0.2
			else
				baseVal = sourceDmg * output.CritEffect * 0.2
			end
			local effMult = 1
			if env.mode_effective then
				local resist = output["EnemyFireResist"]
				local taken = enemyDB:Sum("INC", dotCfg, "DamageTaken", "FireDamageTaken", "ElementalDamageTaken", "BurningDamageTaken", "DotTaken")
				effMult = (1 - resist / 100) * (1 + taken / 100)
				output["IgniteEffMult"] = effMult
				if breakdown then
					breakdown.IgniteEffMult = effMultBreakdown("Fire", resist, 0, taken, effMult)
				end
			end
			local inc = modDB:Sum("INC", dotCfg, "Damage", "FireDamage", "ElementalDamage")
			local more = round(modDB:Sum("MORE", dotCfg, "Damage", "FireDamage", "ElementalDamage"), 2)
			output.IgniteDPS = baseVal * (1 + inc/100) * more * effMult
			local incDur = modDB:Sum("INC", dotCfg, "EnemyIgniteDuration") + enemyDB:Sum("INC", nil, "SelfIgniteDuration")
			output.IgniteDuration = 4 * (1 + incDur / 100) * debuffDurationMult
			if breakdown then
				breakdown.IgniteDPS = {
					s_format("Ignite mode: %s ^8(can be changed in the Configuration tab)", igniteMode == "CRIT" and "Crit Damage" or "Average Damage"),
					"Base damage:",
					s_format("%.1f ^8(average non-crit damage from sources)", sourceDmg),
				}
				if igniteMode == "CRIT" then
					if output.CritMultiplier ~= 1 then
						t_insert(breakdown.IgniteDPS, s_format("x %.2f ^8(crit multiplier)", output.CritMultiplier))
					end
				else
					if output.CritEffect ~= 1 then
						t_insert(breakdown.IgniteDPS, s_format("x %.3f ^8(crit effect modifier)", output.CritEffect))
					end
				end
				t_insert(breakdown.IgniteDPS, "x 0.2 ^8(ignite deals 20% per second)")
				t_insert(breakdown.IgniteDPS, s_format("= %.1f", baseVal, 1))
				t_insert(breakdown.IgniteDPS, "Ignite DPS:")
				dotBreakdown(breakdown.IgniteDPS, baseVal, inc, more, effMult, output.IgniteDPS)
				if output.IgniteDuration ~= 4 then
					breakdown.IgniteDuration = {
						s_format("4.00s ^8(base duration)", durationBase)
					}
					if incDur ~= 0 then
						t_insert(breakdown.IgniteDuration, s_format("x %.2f ^8(increased/reduced duration)", 1 + incDur/100))
					end
					if debuffDurationMult ~= 1 then
						t_insert(breakdown.IgniteDuration, s_format("/ %.2f ^8(debuff expires slower/faster)", 1 / debuffDurationMult))
					end
					t_insert(breakdown.IgniteDuration, s_format("= %.2fs", output.IgniteDuration))
				end
			end
		end
	end

	-- Calculate shock and freeze chance + duration modifier
	skillFlags.shock = false
	if modDB:Sum("FLAG", skillCfg, "CannotShock") then
		output.ShockChance = 0
	else
		output.ShockChance = m_min(100, modDB:Sum("BASE", skillCfg, "EnemyShockChance") + enemyDB:Sum("BASE", nil, "SelfShockChance"))
		local sourceDmg = 0
		if canDeal.Lightning and not modDB:Sum("FLAG", skillCfg, "LightningCannotShock") then
			sourceDmg = sourceDmg + output.LightningAverage
		end
		if canDeal.Physical and modDB:Sum("FLAG", skillCfg, "PhysicalCanShock") then
			sourceDmg = sourceDmg + output.PhysicalAverage
		end
		if canDeal.Fire and modDB:Sum("FLAG", skillCfg, "FireCanShock") then
			sourceDmg = sourceDmg + output.FireAverage
		end
		if canDeal.Chaos and modDB:Sum("FLAG", skillCfg, "ChaosCanShock") then
			sourceDmg = sourceDmg + output.ChaosAverage
		end
		if output.ShockChance > 0 and sourceDmg > 0 then
			skillFlags.shock = true
			output.ShockDurationMod = 1 + modDB:Sum("INC", dotCfg, "EnemyShockDuration") / 100 + enemyDB:Sum("INC", nil, "SelfShockDuration") / 100
 		end
	end
	skillFlags.freeze = false
	if modDB:Sum("FLAG", skillCfg, "CannotFreeze") then
		output.FreezeChance = 0
	else
		output.FreezeChance = m_min(100, modDB:Sum("BASE", skillCfg, "EnemyFreezeChance") + enemyDB:Sum("BASE", nil, "SelfFreezeChance"))
		local sourceDmg = 0
		if canDeal.Cold and not modDB:Sum("FLAG", skillCfg, "ColdCannotFreeze") then
			sourceDmg = sourceDmg + output.ColdAverage
		end
		if canDeal.Lightning and modDB:Sum("FLAG", skillCfg, "LightningCanFreeze") then
			sourceDmg = sourceDmg + output.LightningAverage
		end
		if output.FreezeChance > 0 and sourceDmg > 0 then
			skillFlags.freeze = true
			output.FreezeDurationMod = 1 + modDB:Sum("INC", dotCfg, "EnemyFreezeDuration") / 100 + enemyDB:Sum("INC", nil, "SelfFreezeDuration") / 100
		end
	end

	-- Calculate enemy stun modifiers
	do
		local enemyStunThresholdRed = -modDB:Sum("INC", skillCfg, "EnemyStunThreshold")
		if enemyStunThresholdRed > 75 then
			output.EnemyStunThresholdMod = 1 - (75 + (enemyStunThresholdRed - 75) * 25 / (enemyStunThresholdRed - 50)) / 100
		else
			output.EnemyStunThresholdMod = 1 - enemyStunThresholdRed / 100
		end
		local incDur = modDB:Sum("INC", skillCfg, "EnemyStunDuration")
		local incRecov = enemyDB:Sum("INC", nil, "StunRecovery")
		output.EnemyStunDuration = 0.35 * (1 + incDur / 100) / (1 + incRecov / 100)
		if breakdown then
			if output.EnemyStunDuration ~= 0.35 then
				breakdown.EnemyStunDuration = {
					"0.35s ^8(base duration)"
				}
				if incDur ~= 0 then
					t_insert(breakdown.EnemyStunDuration, s_format("x %.2f ^8(increased/reduced stun duration)", 1 + incDur/100))
				end
				if incRecov ~= 0 then
					t_insert(breakdown.EnemyStunDuration, s_format("/ %.2f ^8(increased/reduced enemy stun recovery)", 1 + incRecov/100))
				end
				t_insert(breakdown.EnemyStunDuration, s_format("= %.2fs", output.EnemyStunDuration))
			end
		end
	end

	-- Calculate combined DPS estimate, including DoTs
	output.CombinedDPS = output[(env.mode_average and "AverageDamage") or "TotalDPS"] + output.TotalDot
	if skillFlags.poison then
		if env.mode_average then
			output.CombinedDPS = output.CombinedDPS + output.PoisonChance / 100 * output.PoisonDamage
			output.WithPoisonAverageHit = output.CombinedDPS
		else
			output.CombinedDPS = output.CombinedDPS + output.PoisonChance / 100 * output.PoisonDamage * (output.HitSpeed or output.Speed)
			output.WithPoisonDPS = output.CombinedDPS
		end
	end
	if skillFlags.ignite then
		output.CombinedDPS = output.CombinedDPS + output.IgniteDPS
	end
	if skillFlags.bleed then
		output.CombinedDPS = output.CombinedDPS + output.BleedDPS
	end
end

-- Print various tables to the console
local function infoDump(env, output)	
	env.modDB:Print()
	ConPrintf("=== Enemy Mod DB ===")
	env.enemyDB:Print()
	ConPrintf("=== Main Skill ===")
	for _, gem in ipairs(env.mainSkill.gemList) do
		ConPrintf("%s %d/%d", gem.name, gem.level, gem.quality)
	end
	ConPrintf("=== Main Skill Flags ===")
	ConPrintf("Mod: %s", modLib.formatFlags(env.mainSkill.skillCfg.flags, ModFlag))
	ConPrintf("Keyword: %s", modLib.formatFlags(env.mainSkill.skillCfg.keywordFlags, KeywordFlag))
	ConPrintf("=== Main Skill Mods ===")
	env.mainSkill.skillModList:Print()
	ConPrintf("== Aux Skills ==")
	for i, aux in ipairs(env.auxSkillList) do
		ConPrintf("Skill #%d:", i)
		for _, gem in ipairs(aux.gemList) do
			ConPrintf("  %s %d/%d", gem.name, gem.level, gem.quality)
		end
	end
--	ConPrintf("== Conversion Table ==")
--	ConPrintTable(env.conversionTable)
	ConPrintf("== Output Table ==")
	local outNames = { }
	for name in pairs(env.output) do
		t_insert(outNames, name)
	end
	table.sort(outNames)
	for _, name in ipairs(outNames) do
		ConPrintf("%s = %s", name, tostring(env.output[name]))
	end
end

-- Generate a function for calculating the effect of some modification to the environment
local function getCalculator(build, fullInit, modFunc)
	-- Initialise environment
	local env = initEnv(build, "CALCULATOR")

	-- Save a copy of the initial mod database
	if fullInit then
		mergeMainMods(env)
	end
	local initModDB = common.New("ModDB")
	initModDB:AddDB(env.modDB)
	initModDB.conditions = copyTable(env.modDB.conditions)
	initModDB.multipliers = copyTable(env.modDB.multipliers)
	local initEnemyDB = common.New("ModDB")
	initEnemyDB:AddDB(env.enemyDB)
	initEnemyDB.conditions = copyTable(env.enemyDB.conditions)
	initEnemyDB.multipliers = copyTable(env.enemyDB.multipliers)
	if not fullInit then
		mergeMainMods(env)
	end

	-- Run base calculation pass
	performCalcs(env)
	local baseOutput = env.output

	return function(...)
		-- Restore initial mod database
		env.modDB.mods = wipeTable(env.modDB.mods)
		env.modDB:AddDB(initModDB)
		env.modDB.conditions = copyTable(initModDB.conditions)
		env.modDB.multipliers = copyTable(initModDB.multipliers)
		env.enemyDB.mods = wipeTable(env.enemyDB.mods)
		env.enemyDB:AddDB(initEnemyDB)
		env.enemyDB.conditions = copyTable(initEnemyDB.conditions)
		env.enemyDB.multipliers = copyTable(initEnemyDB.multipliers)
		
		-- Call function to make modifications to the enviroment
		modFunc(env, ...)
		
		-- Run calculation pass
		performCalcs(env)

		return env.output
	end, baseOutput	
end

local calcs = { }

-- Get calculator for tree node modifiers
function calcs.getNodeCalculator(build)
	return getCalculator(build, true, function(env, nodeList, remove)
		-- Build and merge/unmerge modifiers for these nodes
		local nodeModList = buildNodeModList(env, nodeList)
		if remove then
			for _, mod in ipairs(nodeModList) do
				if mod.type == "LIST" or mod.type == "FLAG" then
					for i, dbMod in ipairs(env.modDB.mods[mod.name] or { }) do
						if mod == dbMod then
							t_remove(env.modDB.mods[mod.name], i)
							break
						end
					end
				elseif mod.type == "MORE" then
					env.modDB:NewMod(mod.name, mod.type, (1 / (1 + mod.value / 100) - 1) * 100, mod.source, mod.flags, mod.keywordFlags, unpack(mod.tagList))
				else
					env.modDB:NewMod(mod.name, mod.type, -mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod.tagList))
				end
			end
		else
			env.modDB:AddList(nodeModList)
		end
	end)
end

-- Get calculator for item modifiers
function calcs.getItemCalculator(build)
	return getCalculator(build, false, function(env, repSlotName, repItem)
		-- Merge main mods, replacing the item in the given slot with the given item
		mergeMainMods(env, repSlotName, repItem)
	end)
end

-- Build output for display in the side bar or calcs tab
function calcs.buildOutput(build, mode)
	-- Build output
	local env = initEnv(build, mode)
	mergeMainMods(env)
	performCalcs(env)

	local output = env.output

	if mode == "MAIN" then
		output.ExtraPoints = env.modDB:Sum("BASE", nil, "ExtraPoints")

		local specCfg = {
			source = "Tree"
		}
		for _, stat in pairs({"Life", "Mana", "Armour", "Evasion", "EnergyShield"}) do
			output["Spec:"..stat.."Inc"] = env.modDB:Sum("INC", specCfg, stat)
		end
	elseif mode == "CALCS" then
		local buffList = { }
		local combatList = { }
		local curseList = { }
		if output.PowerCharges > 0 then
			t_insert(combatList, s_format("%d Power Charges", output.PowerCharges))
		end
		if output.FrenzyCharges > 0 then
			t_insert(combatList, s_format("%d Frenzy Charges", output.FrenzyCharges))
		end
		if output.EnduranceCharges > 0 then
			t_insert(combatList, s_format("%d Endurance Charges", output.EnduranceCharges))
		end
		if env.modDB.conditions.Onslaught then
			t_insert(combatList, "Onslaught")
		end
		if env.modDB.conditions.UnholyMight then
			t_insert(combatList, "Unholy Might")
		end
		for _, activeSkill in ipairs(env.activeSkillList) do
			if activeSkill.buffModList or activeSkill.auraModList then
				if activeSkill.skillFlags.multiPart then
					t_insert(buffList, activeSkill.activeGem.name .. " (" .. activeSkill.skillPartName .. ")")
				else
					t_insert(buffList, activeSkill.activeGem.name)
				end
			end
			if activeSkill.debuffModList or activeSkill.curseModList then
				if activeSkill.skillFlags.multiPart then
					t_insert(curseList, activeSkill.activeGem.name .. " (" .. activeSkill.skillPartName .. ")")
				else
					t_insert(curseList, activeSkill.activeGem.name)
				end
			end
		end
		output.BuffList = table.concat(buffList, ", ")
		output.CombatList = table.concat(combatList, ", ")
		output.CurseList = table.concat(curseList, ", ")

		infoDump(env)
	end

	return env
end

return calcs