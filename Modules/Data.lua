-- Path of Building
--
-- Module: Data
-- Contains static data used by other modules.
--

LoadModule("Data/Global")

local skillTypes = {
	"act_str",
	"act_dex",
	"act_int",
	"other",
	"glove",
	"minion",
	"spectre",
	"sup_str",
	"sup_dex",
	"sup_int",
}
local itemTypes = {
	"axe",
	"bow",
	"claw",
	"dagger",
	"mace",
	"staff",
	"sword",
	"wand",
	"helmet",
	"body",
	"gloves",
	"boots",
	"shield",
	"quiver",
	"amulet",
	"ring",
	"belt",
	"jewel",
	"flask",
}

local function makeSkillMod(modName, modType, modVal, flags, keywordFlags, ...)
	return {
		name = modName,
		type = modType,
		value = modVal,
		flags = flags or 0,
		keywordFlags = keywordFlags or 0,
		...
	}
end
local function makeFlagMod(modName, ...)
	return makeSkillMod(modName, "FLAG", true, 0, 0, ...)
end
local function makeSkillDataMod(dataKey, dataValue, ...)
	return makeSkillMod("SkillData", "LIST", { key = dataKey, value = dataValue }, 0, 0, ...)
end
local function processMod(grantedEffect, mod)
	mod.source = grantedEffect.modSource
	if type(mod.value) == "table" and mod.value.mod then
		mod.value.mod.source = "Skill:"..grantedEffect.id
	end
	for _, tag in ipairs(mod) do
		if tag.type == "GlobalEffect" then
			grantedEffect.hasGlobalEffect = true
			break
		end
	end
end

-----------------
-- Common Data --
-----------------

data = { }

data.powerStatList = {
	{ stat=nil, label="Offence/Defence", combinedOffDef=true, ignoreForItems=true },
	{ stat=nil, label="Name", itemField="Name", ignoreForNodes=true, reverseSort=true, transform=function(value) return value:gsub("^The ","") end},
	{ stat="CombinedDPS", label="Combined DPS" },
	{ stat="TotalDPS", label="Total DPS" },
	{ stat="WithImpaleDPS", label="Impale + Total DPS" },
	{ stat="AverageDamage", label="Average Hit" },
	{ stat="BleedDPS", label="Bleed DPS" },
	{ stat="IgniteDPS", label="Ignite DPS" },
	{ stat="PoisonDPS", label="Poison DPS" },
	{ stat="TotalDot", label="Chaos DoT DPS" },
	{ stat="Life", label="Life" },
	{ stat="LifeRegen", label="Life regen" },
	{ stat="LifeLeechRate", label="Life leech" },
	{ stat="EnergyShield", label="Energy Shield" },
	{ stat="EnergyShieldRegen", label="Energy Shield regen" },
	{ stat="EnergyShieldLeechRate", label="Energy Shield leech" },
	{ stat="Mana", label="Mana" },
	{ stat="ManaRegen", label="Mana regen" },
	{ stat="ManaLeechRate", label="Mana leech" },
	{ stat="Str", label="Strength" },
	{ stat="Dex", label="Dexterity" },
	{ stat="Int", label="Intelligence" },
	{ stat="TotalAttr", label="Total Attributes" },
	{ stat="MeleeAvoidChance", label="Melee avoid chance" },
	{ stat="SpellAvoidChance", label="Spell avoid chance" },
	{ stat="ProjectileAvoidChance", label="Projectile avoid chance" },
	{ stat="PhysicalTakenHitMult", label="Taken Phys dmg", transform=function(value) return 1-value end },
	{ stat="FireTakenDotMult", label="Taken Fire dmg", transform=function(value) return 1-value end },
	{ stat="ColdTakenDotMult", label="Taken Cold dmg", transform=function(value) return 1-value end },
	{ stat="LightningTakenDotMult", label="Taken Lightning dmg", transform=function(value) return 1-value end },
	{ stat="ChaosTakenHitMult", label="Taken Chaos dmg", transform=function(value) return 1-value end },
	{ stat="CritChance", label="Crit Chance" },
	{ stat="BleedChance", label="Bleed Chance" },
	{ stat="FreezeChance", label="Freeze Chance" },
	{ stat="IgniteChance", label="Ignite Chance" },
	{ stat="ShockChance", label="Shock Chance" },
	{ stat="EffectiveMovementSpeedMod", label="Move speed" },
}

data.skillColorMap = { colorCodes.STRENGTH, colorCodes.DEXTERITY, colorCodes.INTELLIGENCE, colorCodes.NORMAL }

data.jewelRadius = {
	{ inner = 0, outer = 800, col = "^xBB6600", label = "Small" },
	{ inner = 0, outer = 1200, col = "^x66FFCC", label = "Medium" },
	{ inner = 0, outer = 1500, col = "^x2222CC", label = "Large" },

	{ inner = 850, outer = 1100, col = "^xD35400", label = "Variable" },
	{ inner = 1150, outer = 1400, col = "^x66FFCC", label = "Variable" },
	{ inner = 1450, outer = 1700, col = "^x2222CC", label = "Variable" },
	{ inner = 1750, outer = 2000, col = "^xC100FF", label = "Variable" },
}

data.labyrinths = {
	{ name = "ENDGAME", label = "Eternal" },
	{ name = "MERCILESS", label = "Merciless" },
	{ name = "CRUEL", label = "Cruel" },
	{ name = "NORMAL", label = "Normal" },
}

local maxPenaltyFreeAreaLevel = 70
local maxAreaLevel = 87 -- T16 map + side area + three watchstones that grant +1 level
local penaltyMultiplier = 0.06

---@param areaLevel number
---@return number
local function effectiveMonsterLevel(areaLevel)
	--- Areas with area level above a certain penalty-free level are considered to have
	--- a scaling lower effective monster level for experience penalty calculations.
	if areaLevel <= maxPenaltyFreeAreaLevel then
		return areaLevel
	end
	return areaLevel - triangular(areaLevel - maxPenaltyFreeAreaLevel) * penaltyMultiplier
end

---@type table<number, number>
data.monsterExperienceLevelMap = {}
for i = 1, maxAreaLevel do
	data.monsterExperienceLevelMap[i] = effectiveMonsterLevel(i)
end

data.weaponTypeInfo = {
	["None"] = { oneHand = true, melee = true, flag = "Unarmed" },
	["Bow"] = { oneHand = false, melee = false, flag = "Bow" },
	["Claw"] = { oneHand = true, melee = true, flag = "Claw" },
	["Dagger"] = { oneHand = true, melee = true, flag = "Dagger" },
	["Staff"] = { oneHand = false, melee = true, flag = "Staff" },
	["Wand"] = { oneHand = true, melee = false, flag = "Wand" },
	["One Handed Axe"] = { oneHand = true, melee = true, flag = "Axe" },
	["One Handed Mace"] = { oneHand = true, melee = true, flag = "Mace" },
	["One Handed Sword"] = { oneHand = true, melee = true, flag = "Sword" },
	["Sceptre"] = { oneHand = true, melee = true, flag = "Mace", label = "One Handed Mace" },
	["Thrusting One Handed Sword"] = { oneHand = true, melee = true, flag = "Sword", label = "One Handed Sword" },
	["Two Handed Axe"] = { oneHand = false, melee = true, flag = "Axe" },
	["Two Handed Mace"] = { oneHand = false, melee = true, flag = "Mace" },
	["Two Handed Sword"] = { oneHand = false, melee = true, flag = "Sword" },
}
data.unarmedWeaponData = {
	[0] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 6 }, -- Scion
	[1] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 8 }, -- Marauder
	[2] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 5 }, -- Ranger
	[3] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 5 }, -- Witch
	[4] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 6 }, -- Duelist
	[5] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 6 }, -- Templar
	[6] = { type = "None", AttackRate = 1.2, CritChance = 0, PhysicalMin = 2, PhysicalMax = 5 }, -- Shadow
}

data.specialBaseTags = {
	["Amulet"] = { shaper = "amulet_shaper", elder = "amulet_elder", adjudicator = "amulet_adjudicator", basilisk = "amulet_basilisk", crusader = "amulet_crusader", eyrie = "amulet_eyrie", },
	["Ring"] = { shaper = "ring_shaper", elder = "ring_elder", adjudicator = "ring_adjudicator", basilisk = "ring_basilisk", crusader = "ring_crusader", eyrie = "ring_eyrie", },
	["Claw"] = { shaper = "claw_shaper", elder = "claw_elder", adjudicator = "claw_adjudicator", basilisk = "claw_basilisk", crusader = "claw_crusader", eyrie = "claw_eyrie", },
	["Dagger"] = { shaper = "dagger_shaper", elder = "dagger_elder", adjudicator = "dagger_adjudicator", basilisk = "dagger_basilisk", crusader = "dagger_crusader", eyrie = "dagger_eyrie", },
	["Wand"] = { shaper = "wand_shaper", elder = "wand_elder", adjudicator = "wand_adjudicator", basilisk = "wand_basilisk", crusader = "wand_crusader", eyrie = "wand_eyrie", },
	["One Handed Sword"] = { shaper = "sword_shaper", elder = "sword_elder", adjudicator = "sword_adjudicator", basilisk = "sword_basilisk", crusader = "sword_crusader", eyrie = "sword_eyrie", },
	["Thrusting One Handed Sword"] = { shaper = "sword_shaper", elder = "sword_elder", adjudicator = "sword_adjudicator", basilisk = "sword_basilisk", crusader = "sword_crusader", eyrie = "sword_eyrie", },
	["One Handed Axe"] = { shaper = "axe_shaper", elder = "axe_elder", adjudicator = "axe_adjudicator", basilisk = "axe_basilisk", crusader = "axe_crusader", eyrie = "axe_eyrie", },
	["One Handed Mace"] = { shaper = "mace_shaper", elder = "mace_elder", adjudicator = "mace_adjudicator", basilisk = "mace_basilisk", crusader = "mace_crusader", eyrie = "mace_eyrie", },
	["Bow"] = { shaper = "bow_shaper", elder = "bow_elder", adjudicator = "bow_adjudicator", basilisk = "bow_basilisk", crusader = "bow_crusader", eyrie = "bow_eyrie", },
	["Staff"] = { shaper = "staff_shaper", elder = "staff_elder", adjudicator = "staff_adjudicator", basilisk = "staff_basilisk", crusader = "staff_crusader", eyrie = "staff_eyrie", },
	["Two Handed Sword"] = { shaper = "2h_sword_shaper", elder = "2h_sword_elder", adjudicator = "2h_sword_adjudicator", basilisk = "2h_sword_basilisk", crusader = "2h_sword_crusader", eyrie = "2h_sword_eyrie", },
	["Two Handed Axe"] = { shaper = "2h_axe_shaper", elder = "2h_axe_elder", adjudicator = "2h_axe_adjudicator", basilisk = "2h_axe_basilisk", crusader = "2h_axe_crusader", eyrie = "2h_axe_eyrie", },
	["Two Handed Mace"] = { shaper = "2h_mace_shaper", elder = "2h_mace_elder", adjudicator = "2h_mace_adjudicator", basilisk = "2h_mace_basilisk", crusader = "2h_mace_crusader", eyrie = "2h_mace_eyrie", },
	["Quiver"] = { shaper = "quiver_shaper", elder = "quiver_elder", adjudicator = "quiver_adjudicator", basilisk = "quiver_basilisk", crusader = "quiver_crusader", eyrie = "quiver_eyrie", },
	["Belt"] = { shaper = "belt_shaper", elder = "belt_elder", adjudicator = "belt_adjudicator", basilisk = "belt_basilisk", crusader = "belt_crusader", eyrie = "belt_eyrie", },
	["Gloves"] = { shaper = "gloves_shaper", elder = "gloves_elder", adjudicator = "gloves_adjudicator", basilisk = "gloves_basilisk", crusader = "gloves_crusader", eyrie = "gloves_eyrie", },
	["Boots"] = { shaper = "boots_shaper", elder = "boots_elder", adjudicator = "boots_adjudicator", basilisk = "boots_basilisk", crusader = "boots_crusader", eyrie = "boots_eyrie", },
	["Body Armour"] = { shaper = "body_armour_shaper", elder = "body_armour_elder", adjudicator = "body_armour_adjudicator", basilisk = "body_armour_basilisk", crusader = "body_armour_crusader", eyrie = "body_armour_eyrie", },
	["Helmet"] = { shaper = "helmet_shaper", elder = "helmet_elder", adjudicator = "helmet_adjudicator", basilisk = "helmet_basilisk", crusader = "helmet_crusader", eyrie = "helmet_eyrie", },
	["Shield"] = { shaper = "shield_shaper", elder = "shield_elder", adjudicator = "shield_adjudicator", basilisk = "shield_basilisk", crusader = "shield_crusader", eyrie = "shield_eyrie", },
	["Sceptre"] = { shaper = "sceptre_shaper", elder = "sceptre_elder", adjudicator = "sceptre_adjudicator", basilisk = "sceptre_basilisk", crusader = "sceptre_crusader", eyrie = "sceptre_eyrie", },
}

data.misc = { -- magic numbers
	ServerTickRate = 30,
	TemporalChainsEffectCap = 75,
	DamageReductionCap = 90,
	MaxResistCap = 90,
	EvadeChanceCap = 95,
	DodgeChanceCap = 75,
	AvoidChanceCap = 75,
	EnergyShieldRechargeBase = 0.2,
	Transfiguration = 0.3,
	EnemyMaxResist = 75,
	LeechRateBase = 0.02,
	BleedPercentBase = 70,
	BleedDurationBase = 5,
	PoisonPercentBase = 0.20,
	PoisonDurationBase = 2,
	IgnitePercentBase = 0.50,
	IgniteDurationBase = 4,
	ImpaleStoredDamageBase = 0.1,
	BuffExpirationSlowCap = 0.25,
	TrapTriggerRadiusBase = 10,
	MineDetonationRadiusBase = 60,
	MineAuraRadiusBase = 35,
	PurposefulHarbingerMaxBuffPercent = 40,
}

---------------------------
-- Version-specific Data --
---------------------------

for _, targetVersion in ipairs(targetVersionList) do
	local verData = setmetatable({ }, { __index = data })
	data[targetVersion] = verData
	local function dataModule(mod, ...)
		return LoadModule("Data/"..targetVersion.."/"..mod, ...)
	end

	-- Misc data tables
	dataModule("Misc", verData)

	-- Stat descriptions
	if targetVersion ~= "2_6" then
		verData.describeStats = LoadModule("Modules/StatDescriber", targetVersion)
	end

	-- Load item modifiers
	verData.itemMods = {
		Item = dataModule("ModItem"),
		Flask = dataModule("ModFlask"),
		Jewel = dataModule("ModJewel"),
		JewelAbyss = targetVersion ~= "2_6" and dataModule("ModJewelAbyss") or { },
		JewelCluster = targetVersion ~= "2_6" and dataModule("ModJewelCluster") or { },
	}
	verData.masterMods = dataModule("ModMaster")
	verData.enchantments = {
		Helmet = dataModule("EnchantmentHelmet"),
		Boots = dataModule("EnchantmentBoots"),
		Gloves = dataModule("EnchantmentGloves"),
	}
	verData.essences = dataModule("Essence")
	verData.pantheons = targetVersion ~= "2_6" and dataModule("Pantheons") or { }
	

	-- Cluster jewel data
	if targetVersion ~= "2_6" then	
		verData.clusterJewels = dataModule("ClusterJewels")

		-- Create a quick lookup cache from cluster jewel skill to the notables which use that skill
		---@type table<string, table<string>>
		local clusterSkillToNotables = { }
		for notableKey, notableInfo in pairs(verData.itemMods.JewelCluster) do
			-- Translate the notable key to its name
			local notableName = notableInfo[1] and notableInfo[1]:match("1 Added Passive Skill is (.*)")
			if notableName then
				for weightIndex, clusterSkill in pairs(notableInfo.weightKey) do
					if notableInfo.weightVal[weightIndex] > 0 then
						if not clusterSkillToNotables[clusterSkill] then
							clusterSkillToNotables[clusterSkill] = { }
						end
						table.insert(clusterSkillToNotables[clusterSkill], notableName)
					end
				end
			end
		end

		-- Create easy lookup from cluster node name -> cluster jewel size and types
		verData.clusterJewelInfoForNotable = { }
		for size, jewel in pairs(verData.clusterJewels.jewels) do
			for skill, skillInfo in pairs(jewel.skills) do
				local notables = clusterSkillToNotables[skill]
				if notables then
					for _, notableKey in ipairs(notables) do
						if not verData.clusterJewelInfoForNotable[notableKey] then
							verData.clusterJewelInfoForNotable[notableKey] = { }
							verData.clusterJewelInfoForNotable[notableKey].jewelTypes = { }
							verData.clusterJewelInfoForNotable[notableKey].size = { }
						end
						local curJewelInfo = verData.clusterJewelInfoForNotable[notableKey]
						curJewelInfo.size[size] = true
						table.insert(curJewelInfo.jewelTypes, skill)
					end
				end
			end
		end
	end

	-- Load skills
	verData.skills = { }
	verData.skillStatMap = dataModule("SkillStatMap", makeSkillMod, makeFlagMod, makeSkillDataMod)
	verData.skillStatMapMeta = {
		__index = function(t, key)
			local map = verData.skillStatMap[key]
			if map then
				map = copyTable(map)
				t[key] = map
				for _, mod in ipairs(map) do
					processMod(t._grantedEffect, mod)
				end
				return map
			end
		end
	}
	for _, type in pairs(skillTypes) do
		dataModule("Skills/"..type, verData.skills, makeSkillMod, makeFlagMod, makeSkillDataMod)
	end
	for skillId, grantedEffect in pairs(verData.skills) do
		grantedEffect.id = skillId
		grantedEffect.modSource = "Skill:"..skillId
		-- Add sources for skill mods, and check for global effects
		for _, list in pairs({grantedEffect.baseMods, grantedEffect.qualityMods, grantedEffect.levelMods}) do
			for _, mod in pairs(list) do
				if mod.name then
					processMod(grantedEffect, mod)
				else
					for _, mod in ipairs(mod) do
						processMod(grantedEffect, mod)
					end
				end
			end
		end
		-- Install stat map metatable
		grantedEffect.statMap = grantedEffect.statMap or { }
		setmetatable(grantedEffect.statMap, verData.skillStatMapMeta)
		grantedEffect.statMap._grantedEffect = grantedEffect
		for _, map in pairs(grantedEffect.statMap) do
			for _, mod in ipairs(map) do
				processMod(grantedEffect, mod)
			end
		end
	end

	-- Load gems
	verData.gems = dataModule("Gems")
	verData.gemForSkill = { }
	verData.gemForBaseName = { }
	for gemId, gem in pairs(verData.gems) do
		gem.id = gemId
		gem.grantedEffect = verData.skills[gem.grantedEffectId]
		verData.gemForSkill[gem.grantedEffect] = gemId
		verData.gemForBaseName[gem.name .. (gem.grantedEffect.support and " Support" or "")] = gemId
		gem.secondaryGrantedEffect = gem.secondaryGrantedEffectId and verData.skills[gem.secondaryGrantedEffectId]
		gem.grantedEffectList = {
			gem.grantedEffect,
			gem.secondaryGrantedEffect
		}
		gem.defaultLevel = gem.defaultLevel or (#gem.grantedEffect.levels > 20 and #gem.grantedEffect.levels - 20) or (gem.grantedEffect.levels[3][1] and 3) or 1
	end

	-- Load minions
	verData.minions = { }
	dataModule("Minions", verData.minions, makeSkillMod)
	verData.spectres = { }
	dataModule("Spectres", verData.spectres, makeSkillMod)
	for name, spectre in pairs(verData.spectres) do
		spectre.limit = "ActiveSpectreLimit"
		verData.minions[name] = spectre
	end
	local missing = { }
	for _, minion in pairs(verData.minions) do
		for _, skillId in ipairs(minion.skillList) do
			if launch.devMode and not verData.skills[skillId] and not missing[skillId] then
				ConPrintf("'%s' missing skill '%s'", minion.name, skillId)
				missing[skillId] = true
			end
		end
		for _, mod in ipairs(minion.modList) do
			mod.source = "Minion:"..minion.name
		end
	end

	-- Item bases
	verData.itemBases = { }
	for _, type in pairs(itemTypes) do
		dataModule("Bases/"..type, verData.itemBases)
	end

	-- Build lists of item bases, separated by type
	verData.itemBaseLists = { }
	for name, base in pairs(verData.itemBases) do
		if not base.hidden then
			local type = base.type
			if base.subType then
				type = type .. ": " .. base.subType
			end
			verData.itemBaseLists[type] = verData.itemBaseLists[type] or { }
			table.insert(verData.itemBaseLists[type], { label = name:gsub(" %(.+%)",""), name = name, base = base })
		end
	end
	verData.itemBaseTypeList = { }
	for type, list in pairs(verData.itemBaseLists) do
		table.insert(verData.itemBaseTypeList, type)
		table.sort(list, function(a, b) 
			if a.base.req and b.base.req then
				if a.base.req.level == b.base.req.level then
					return a.name < b.name
				else
					return (a.base.req.level or 1) > (b.base.req.level or 1)
				end
			elseif a.base.req and not b.base.req then
				return true
			elseif b.base.req and not a.base.req then
				return false
			else
				return a.name < b.name
			end
		end)
	end
	table.sort(verData.itemBaseTypeList)

	-- Rare templates
	verData.rares = dataModule("Rares")
end

-- Uniques (loaded after version-specific data because reasons)
data.uniques = { }
for _, type in pairs(itemTypes) do
	data.uniques[type] = LoadModule("Data/Uniques/"..type)
end
LoadModule("Data/Generated")
LoadModule("Data/New")
