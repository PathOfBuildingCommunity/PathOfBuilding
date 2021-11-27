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
	"fishing",
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
	{ stat="FullDPS", label="Full DPS" },
	{ stat="CombinedDPS", label="Combined DPS" },
	{ stat="TotalDPS", label="Total DPS" },
	{ stat="WithImpaleDPS", label="Impale + Total DPS" },
	{ stat="AverageDamage", label="Average Hit" },
	{ stat="Speed", label="Attack/Cast Speed" },
	{ stat="TotalDot", label="DoT DPS" },
	{ stat="BleedDPS", label="Bleed DPS" },
	{ stat="IgniteDPS", label="Ignite DPS" },
	{ stat="PoisonDPS", label="Poison DPS" },
	{ stat="Life", label="Life" },
	{ stat="LifeRegen", label="Life regen" },
	{ stat="LifeLeechRate", label="Life leech" },
	{ stat="Armour", label="Armour" },
	{ stat="Evasion", label="Evasion" },
	{ stat="EnergyShield", label="Energy Shield" },
	{ stat="EnergyShieldRecoveryCap", label="Recoverable ES" },
	{ stat="EnergyShieldRegen", label="Energy Shield regen" },
	{ stat="EnergyShieldLeechRate", label="Energy Shield leech" },
	{ stat="Mana", label="Mana" },
	{ stat="ManaRegen", label="Mana regen" },
	{ stat="ManaLeechRate", label="Mana leech" },
	{ stat="Ward", label="Ward" },
	{ stat="Str", label="Strength" },
	{ stat="Dex", label="Dexterity" },
	{ stat="Int", label="Intelligence" },
	{ stat="TotalAttr", label="Total Attributes" },
	{ stat="MeleeAvoidChance", label="Melee avoid chance" },
	{ stat="SpellAvoidChance", label="Spell avoid chance" },
	{ stat="ProjectileAvoidChance", label="Projectile avoid chance" },
	{ stat="PhysicalTotalEHP", label="eHP vs Physical hits" },
	{ stat="LightningTotalEHP", label="eHP vs Lightning hits" },
	{ stat="ColdTotalEHP", label="eHP vs Cold hits" },
	{ stat="FireTotalEHP", label="eHP vs Fire hits" },
	{ stat="ChaosTotalEHP", label="eHP vs Chaos hits" },
	{ stat="PhysicalTakenHitMult", label="Taken Phys dmg", transform=function(value) return 1-value end },
	{ stat="LightningTakenDotMult", label="Taken Lightning dmg", transform=function(value) return 1-value end },
	{ stat="ColdTakenDotMult", label="Taken Cold dmg", transform=function(value) return 1-value end },
	{ stat="FireTakenDotMult", label="Taken Fire dmg", transform=function(value) return 1-value end },
	{ stat="ChaosTakenHitMult", label="Taken Chaos dmg", transform=function(value) return 1-value end },
	{ stat="CritChance", label="Crit Chance" },
	{ stat="CritMultiplier", label="Crit Multiplier" },
	{ stat="BleedChance", label="Bleed Chance" },
	{ stat="FreezeChance", label="Freeze Chance" },
	{ stat="IgniteChance", label="Ignite Chance" },
	{ stat="ShockChance", label="Shock Chance" },
	{ stat="EffectiveMovementSpeedMod", label="Move speed" },
	{ stat="BlockChance", label="Block Chance" },
	{ stat="SpellBlockChance", label="Spell Block Chance" },
	{ stat="SpellSuppressionChance", label="Spell Suppression Chance" },
}

data.skillColorMap = { colorCodes.STRENGTH, colorCodes.DEXTERITY, colorCodes.INTELLIGENCE, colorCodes.NORMAL }

data.setJewelRadiiGlobally = function(treeVersion)
	local major, minor = treeVersion:match("(%d+)_(%d+)")
	if tonumber(major) <= 3 and tonumber(minor) <= 15 then
		data.jewelRadius = data.jewelRadii["3_15"]
	else
		data.jewelRadius = data.jewelRadii["3_16"]
	end
end

data.jewelRadii = {
	["3_15"] = {
		{ inner = 0, outer = 800, col = "^xBB6600", label = "Small" },
		{ inner = 0, outer = 1200, col = "^x66FFCC", label = "Medium" },
		{ inner = 0, outer = 1500, col = "^x2222CC", label = "Large" },

		{ inner = 850, outer = 1100, col = "^xD35400", label = "Variable" },
		{ inner = 1150, outer = 1400, col = "^x66FFCC", label = "Variable" },
		{ inner = 1450, outer = 1700, col = "^x2222CC", label = "Variable" },
		{ inner = 1750, outer = 2000, col = "^xC100FF", label = "Variable" },
	},
	["3_16"] = {
		{ inner = 0, outer = 960, col = "^xBB6600", label = "Small" },
		{ inner = 0, outer = 1440, col = "^x66FFCC", label = "Medium" },
		{ inner = 0, outer = 1800, col = "^x2222CC", label = "Large" },

		{ inner = 960, outer = 1320, col = "^xD35400", label = "Variable" },
		{ inner = 1320, outer = 1680, col = "^x66FFCC", label = "Variable" },
		{ inner = 1680, outer = 2040, col = "^x2222CC", label = "Variable" },
		{ inner = 2040, outer = 2400, col = "^xC100FF", label = "Variable" },
	}
}

data.jewelRadius = data.setJewelRadiiGlobally(latestTreeVersion)

data.enchantmentSource = {
	{ name = "ENKINDLING", label = "Enkindling Orb" },
	{ name = "INSTILLING", label = "Instilling Orb" },
	{ name = "HEIST", label = "Heist" },
	{ name = "HARVEST", label = "Harvest" },
	{ name = "DEDICATION", label = "Dedication to the Goddess" },
	{ name = "ENDGAME", label = "Eternal Labyrinth" },
	{ name = "MERCILESS", label = "Merciless Labyrinth" },
	{ name = "CRUEL", label = "Cruel Labyrinth" },
	{ name = "NORMAL", label = "Normal Labyrinth" },
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
	["Fishing Rod"] = { oneHand = false, melee = true, flag = "Fishing" },
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

---@type string[] @List of all keystones not exclusive to timeless jewels.
data.keystones = {
	"Acrobatics",
	"Ancestral Bond",
	"Arrow Dancing",
	"Avatar of Fire",
	"Blood Magic",
	"Call to Arms",
	"Chaos Inoculation",
	"Conduit",
	"Corrupted Soul",
	"Crimson Dance",
	"Divine Flesh",
	"Divine Shield",
	"Doomsday",
	"Eldritch Battery",
	"Elemental Equilibrium",
	"Elemental Overload",
	"Eternal Youth",
	"Ghost Dance",
	"Ghost Reaver",
	"Glancing Blows",
	"Hollow Palm Technique",
	"Imbalanced Guard",
	"Immortal Ambition",
	"Iron Grip",
	"Iron Reflexes",
	"Iron Will",
	"Lethe Shade",
	"Magebane",
	"Mind Over Matter",
	"Minion Instability",
	"Mortal Conviction",
	"Necromantic Aegis",
	"Pain Attunement",
	"Perfect Agony",
	"Phase Acrobatics",
	"Point Blank",
	"Resolute Technique",
	"Runebinder",
	"Secrets of Suffering",
	"Solipsism",
	"Supreme Ego",
	"The Agnostic",
	"The Impaler",
	"Unwavering Stance",
	"Vaal Pact",
	"Versatile Combatant",
	"Wicked Ward",
	"Wind Dancer",
	"Zealot's Oath",
}

data.misc = { -- magic numbers
	ServerTickTime = 0.033,
	ServerTickRate = 1 / 0.033,
	TemporalChainsEffectCap = 75,
	DamageReductionCap = 90,
	ResistFloor = -200,
	MaxResistCap = 90,
	EvadeChanceCap = 95,
	DodgeChanceCap = 75,
	SuppressionChanceCap = 100,
	SuppressionEffect = 50,
	AvoidChanceCap = 75,
	EnergyShieldRechargeBase = 0.33,
	EnergyShieldRechargeDelay = 2,
	WardRechargeDelay = 5,
	Transfiguration = 0.3,
	EnemyMaxResist = 75,
	LeechRateBase = 0.02,
	BleedPercentBase = 70,
	BleedDurationBase = 5,
	PoisonPercentBase = 0.30,
	PoisonDurationBase = 2,
	IgnitePercentBase = 1.25,
	IgniteDurationBase = 4,
	ImpaleStoredDamageBase = 0.1,
	BuffExpirationSlowCap = 0.25,
	TrapTriggerRadiusBase = 10,
	MineDetonationRadiusBase = 60,
	MineAuraRadiusBase = 35,
	PurposefulHarbingerMaxBuffPercent = 40,
	VastPowerMaxAoEPercent = 50,
	MaxEnemyLevel = 84,
	LowPoolThreshold = 0.5,
	AccuracyPerDexBase = 2,
}

-- Misc data tables
LoadModule("Data/Misc", data)

-- Stat descriptions
data.describeStats = LoadModule("Modules/StatDescriber")

-- Load item modifiers
data.itemMods = {
	Item = LoadModule("Data/ModItem"),
	Flask = LoadModule("Data/ModFlask"),
	Jewel = LoadModule("Data/ModJewel"),
	JewelAbyss = LoadModule("Data/ModJewelAbyss"),
	JewelCluster = LoadModule("Data/ModJewelCluster"),
}
data.masterMods = LoadModule("Data/ModMaster")
data.enchantments = {
	["Helmet"] = LoadModule("Data/EnchantmentHelmet"),
	["Boots"] = LoadModule("Data/EnchantmentBoots"),
	["Gloves"] = LoadModule("Data/EnchantmentGloves"),
	["Belt"] = LoadModule("Data/EnchantmentBelt"),
	["Body Armour"] = LoadModule("Data/EnchantmentBody"),
	["Weapon"] = LoadModule("Data/EnchantmentWeapon"),
	["Flask"] = LoadModule("Data/EnchantmentFlask"),
}
data.essences = LoadModule("Data/Essence")
data.veiledMods = LoadModule("Data/ModVeiled")
data.pantheons = LoadModule("Data/Pantheons")

-- Cluster jewel data
data.clusterJewels = LoadModule("Data/ClusterJewels")

-- Create a quick lookup cache from cluster jewel skill to the notables which use that skill
---@type table<string, table<string>>
local clusterSkillToNotables = { }
for notableKey, notableInfo in pairs(data.itemMods.JewelCluster) do
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
data.clusterJewelInfoForNotable = { }
for size, jewel in pairs(data.clusterJewels.jewels) do
	for skill, skillInfo in pairs(jewel.skills) do
		local notables = clusterSkillToNotables[skill]
		if notables then
			for _, notableKey in ipairs(notables) do
				if not data.clusterJewelInfoForNotable[notableKey] then
					data.clusterJewelInfoForNotable[notableKey] = { }
					data.clusterJewelInfoForNotable[notableKey].jewelTypes = { }
					data.clusterJewelInfoForNotable[notableKey].size = { }
				end
				local curJewelInfo = data.clusterJewelInfoForNotable[notableKey]
				curJewelInfo.size[size] = true
				table.insert(curJewelInfo.jewelTypes, skill)
			end
		end
	end
end

-- Load skills
data.skills = { }
data.skillStatMap = LoadModule("Data/SkillStatMap", makeSkillMod, makeFlagMod, makeSkillDataMod)
data.skillStatMapMeta = {
	__index = function(t, key)
		local map = data.skillStatMap[key]
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
	LoadModule("Data/Skills/"..type, data.skills, makeSkillMod, makeFlagMod, makeSkillDataMod)
end
for skillId, grantedEffect in pairs(data.skills) do
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
	setmetatable(grantedEffect.statMap, data.skillStatMapMeta)
	grantedEffect.statMap._grantedEffect = grantedEffect
	for _, map in pairs(grantedEffect.statMap) do
		for _, mod in ipairs(map) do
			processMod(grantedEffect, mod)
		end
	end
end

-- Load gems
data.gems = LoadModule("Data/Gems")
data.gemForSkill = { }
data.gemForBaseName = { }
for gemId, gem in pairs(data.gems) do
	gem.id = gemId
	gem.grantedEffect = data.skills[gem.grantedEffectId]
	data.gemForSkill[gem.grantedEffect] = gemId
	data.gemForBaseName[gem.name .. (gem.grantedEffect.support and " Support" or "")] = gemId
	gem.secondaryGrantedEffect = gem.secondaryGrantedEffectId and data.skills[gem.secondaryGrantedEffectId]
	gem.grantedEffectList = {
		gem.grantedEffect,
		gem.secondaryGrantedEffect
	}
	gem.defaultLevel = gem.defaultLevel or (#gem.grantedEffect.levels > 20 and #gem.grantedEffect.levels - 20) or (gem.grantedEffect.levels[3][1] and 3) or 1
end

-- Load minions
data.minions = { }
LoadModule("Data/Minions", data.minions, makeSkillMod)
data.spectres = { }
LoadModule("Data/Spectres", data.spectres, makeSkillMod)
for name, spectre in pairs(data.spectres) do
	spectre.limit = "ActiveSpectreLimit"
	data.minions[name] = spectre
end
local missing = { }
for _, minion in pairs(data.minions) do
	for _, skillId in ipairs(minion.skillList) do
		if launch.devMode and not data.skills[skillId] and not missing[skillId] then
			ConPrintf("'%s' missing skill '%s'", minion.name, skillId)
			missing[skillId] = true
		end
	end
	for _, mod in ipairs(minion.modList) do
		mod.source = "Minion:"..minion.name
	end
end

-- Item bases
data.itemBases = { }
for _, type in pairs(itemTypes) do
	LoadModule("Data/Bases/"..type, data.itemBases)
end

-- Build lists of item bases, separated by type
data.itemBaseLists = { }
for name, base in pairs(data.itemBases) do
	if not base.hidden then
		local type = base.type
		if base.subType then
			type = type .. ": " .. base.subType
		end
		data.itemBaseLists[type] = data.itemBaseLists[type] or { }
		table.insert(data.itemBaseLists[type], { label = name:gsub(" %(.+%)",""), name = name, base = base })
	end
end
data.itemBaseTypeList = { }
for type, list in pairs(data.itemBaseLists) do
	table.insert(data.itemBaseTypeList, type)
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
table.sort(data.itemBaseTypeList)

-- Rare templates
data.rares = LoadModule("Data/Rares")

-- Uniques (loaded after version-specific data because reasons)
data.uniques = { }
for _, type in pairs(itemTypes) do
	data.uniques[type] = LoadModule("Data/Uniques/"..type)
end
data.uniqueMods = { }
data.uniqueMods["Watcher's Eye"] = { }
local unsortedMods = LoadModule("Data/Uniques/Special/WatchersEye")
local sortedMods = { }
for modId in pairs(unsortedMods) do
	table.insert(sortedMods, modId)
end
table.sort(sortedMods)
for _, modId in ipairs(sortedMods) do
	table.insert(data.uniqueMods["Watcher's Eye"], {
		Id = modId,
		mod = unsortedMods[modId],
	})
end
LoadModule("Data/Uniques/Special/Generated")
LoadModule("Data/Uniques/Special/New")
