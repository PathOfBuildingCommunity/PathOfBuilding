-- Path of Building
--
-- Module: Data
-- Contains static data used by other modules.
--
local launch = ...

data = { }

ModFlag = { }
-- Damage modes
ModFlag.Attack =	 0x00000001
ModFlag.Spell =		 0x00000002
ModFlag.Hit =		 0x00000004
ModFlag.Dot =		 0x00000008
ModFlag.Cast =		 0x00000010
-- Damage sources
ModFlag.Melee =		 0x00000100
ModFlag.Area =		 0x00000200
ModFlag.Projectile = 0x00000400
ModFlag.SourceMask = 0x00000600
-- Weapon types
ModFlag.Axe =		 0x00001000
ModFlag.Bow =		 0x00002000
ModFlag.Claw =		 0x00004000
ModFlag.Dagger =	 0x00008000
ModFlag.Mace =		 0x00010000
ModFlag.Staff =		 0x00020000
ModFlag.Sword =		 0x00040000
ModFlag.Wand =		 0x00080000
ModFlag.Unarmed =	 0x00100000
-- Weapon classes
ModFlag.WeaponMelee =0x00200000
ModFlag.WeaponRanged=0x00400000
ModFlag.Weapon =	 0x00800000
ModFlag.Weapon1H =	 0x01000000
ModFlag.Weapon2H =	 0x02000000

KeywordFlag = { }
-- Skill keywords
KeywordFlag.Aura =		0x000001
KeywordFlag.Curse =		0x000002
KeywordFlag.Warcry =	0x000004
KeywordFlag.Movement =	0x000008
KeywordFlag.Fire =		0x000010
KeywordFlag.Cold =		0x000020
KeywordFlag.Lightning =	0x000040
KeywordFlag.Chaos =		0x000080
KeywordFlag.Vaal =		0x000100
-- Skill types
KeywordFlag.Trap =		0x001000
KeywordFlag.Mine =		0x002000
KeywordFlag.Totem =		0x004000
KeywordFlag.Minion =	0x008000
-- Skill effects
KeywordFlag.Poison =	0x010000
KeywordFlag.Bleed =		0x020000

-- Active skill types, used in ActiveSkills.dat and GrantedEffects.dat
-- Had to reverse engineer this, not sure what all of the values mean
SkillType = {
	Attack = 1,
	Spell = 2,
	Projectile = 3, -- Specifically skills which fire projectiles
	DualWield = 4, -- Attack requires dual wielding, only used on Dual Strike
	Buff = 5,
	CanDualWield = 6, -- Attack can be used while dual wielding
	MainHandOnly = 7, -- Attack only uses the main hand
	Type8 = 8, -- Only used on Cleave, possibly referencing that it combines both weapons when dual wielding
	Minion = 9,
	Hit = 10, -- Skill hits (not used on attacks because all of them hit)
	Area = 11,
	Duration = 12,
	Shield = 13, -- Skill requires a shield
	ProjectileDamage = 14, -- Skill deals projectile damage but doesn't fire projectiles
	ManaCostReserved = 15, -- The skill's mana cost is a reservation
	ManaCostPercent = 16, -- The skill's mana cost is a percentage
	SkillCanTrap = 17, -- Skill can be turned into a trap
	SpellCanTotem = 18, -- Spell can be turned into a totem
	SkillCanMine = 19, -- Skill can be turned into a mine
	CauseElementalStatus = 20, -- Causes elemental status effects, but doesn't hit (used on Herald of Ash to allow Elemental Proliferation to apply)
	CreateMinion = 21, -- Creates or summons minions
	AttackCanTotem = 22, -- Attack can be turned into a totem
	Chaining = 23,
	Melee = 24,
	MeleeSingleTarget = 25,
	SpellCanRepeat = 26, -- Spell can repeat via Spell Echo
	Type27 = 27, -- No idea, used on auras and certain damage skills
	AttackCanRepeat = 28, -- Attack can repeat via Multistrike
	CausesBurning = 29, -- Deals burning damage
	Totem = 30,
	Type31 = 31, -- No idea, used on Molten Shell and the Thunder glove enchants, and added by Blasphemy
	Curse = 32,
	FireSkill = 33,
	ColdSkill = 34,
	LightningSkill = 35,
	TriggerableSpell = 36,
	Trap = 37,
	MovementSkill = 38,
	Cast = 39,
	DamageOverTime = 40,
	Mine = 41,
	TriggeredSpell = 42,
	Vaal = 43,
	Aura = 44,
	LightningSpell = 45, -- Used for Mjolner
	Type46 = 46, -- Doesn't appear to be used at all
	TriggeredAttack = 47,
	ProjectileAttack = 48,
	MinionSpell = 49, -- Used for Null's Inclination
	ChaosSkill = 50,
	Type51 = 51, -- Not used by any skill
	Type52 = 52, -- Allows Contagion, Blight and Scorching Ray to be supported by Iron Will
	Type53 = 53, -- Allows Burning Arrow and Vigilant Strike to be supported by Inc AoE and Conc Effect
	Type54 = 54, -- Not used by any skill
	Type55 = 55, -- Allows Burning Arrow to be supported by Inc/Less Duration and Rapid Decay
	Type56 = 56, -- Not used by any skill
	Type57 = 57, -- Appears to be the same as 47
	Channelled = 58,
	Type59 = 59, -- Allows Contagion, Blight and Scorching Ray to be supported by Controlled Destruction
	ColdSpell = 60, -- Used for Cospri's Malice
	TriggeredGrantedSkill = 61, -- Skill granted by item that is automatically triggered, prevents trigger gems and trap/mine/totem from applying
	Golem = 62,
}

data.itemMods = { }
data.itemMods.Flask = LoadModule("Data/ModFlask")
data.itemMods.Jewel = LoadModule("Data/ModJewel")

data.enchantments = { }
data.enchantments.Helmet = LoadModule("Data/EnchantmentHelmet")
data.enchantments.Boots = LoadModule("Data/EnchantmentBoots")

data.labyrinths = {
	{ name = "ENDGAME", label = "Endgame" },
	{ name = "MERCILESS", label = "Merciless" },
	{ name = "CRUEL", label = "Cruel" },
	{ name = "NORMAL", label = "Normal" },
}

data.skills = { }
local function makeSkillMod(modName, modType, modVal, flags, keywordFlags, ...)
	return {
		name = modName,
		type = modType,
		value = modVal,
		flags = flags or 0,
		keywordFlags = keywordFlags or 0,
		tagList = { ... }
	}
end
local function makeFlagMod(modName)
	return makeSkillMod(modName, "FLAG", true)
end
local function makeSkillDataMod(dataKey, dataValue, ...)
	return makeSkillMod("Misc", "LIST", { type = "SkillData", key = dataKey, value = dataValue }, 0, 0, ...)
end
local skillTypes = {
	"act_str",
	"act_dex",
	"act_int",
	"other",
	"minion",
	"spectre",
	"sup_str",
	"sup_dex",
	"sup_int",
}
for _, type in pairs(skillTypes) do
	LoadModule("Data/Skills/"..type, data.skills, makeSkillMod, makeFlagMod, makeSkillDataMod)
end
for skillId, skillData in pairs(data.skills) do
	skillData.id = skillId
	-- Add sources for skill mods
	for _, list in pairs({skillData.baseMods, skillData.qualityMods, skillData.levelMods}) do
		for _, mod in pairs(list) do
			if mod[1] then
				for _, mod in ipairs(mod) do
					mod.source = "Skill:"..skillId
					if type(mod.value) == "table" and mod.value.mod then
						mod.value.mod.source = "Skill:"..skillId
					end
				end
			else
				mod.source = "Skill:"..skillId
				if type(mod.value) == "table" and mod.value.mod then
					mod.value.mod.source = "Skill:"..skillId
				end
			end
		end
	end
end

data.gems = { }
for _, skillData in pairs(data.skills) do
	if skillData.gemTags then
		data.gems[skillData.name] = skillData
	end
end

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
		if not data.skills[skillId] and not missing[skillId] then
			ConPrintf("'%s' missing skill '%s'", minion.name, skillId)
			missing[skillId] = true
		end
	end
	for _, mod in ipairs(minion.modList) do
		mod.source = "Minion:"..minion.name
	end
end

data.colorCodes = {
	NORMAL = "^xC8C8C8",
	MAGIC = "^x8888FF",
	RARE = "^xFFFF77",
	UNIQUE = "^xAF6025",
	RELIC = "^x60C060",
	CRAFTED = "^xB8DAF1",
	UNSUPPORTED = "^xF05050",
	--FIRE = "^x960000",
	FIRE = "^xD02020",
	--COLD = "^x366492",
	COLD = "^x60A0E7",
	LIGHTNING = "^xFFD700",
	CHAOS = "^xD02090",
	POSITIVE = "^x33FF77",
	NEGATIVE = "^xDD0022",
	OFFENCE = "^xE07030",
	DEFENCE = "^x8080E0",
	SCION = "^xFFF0F0",
	MARAUDER = "^xE05030",
	RANGER = "^x70FF70",
	WITCH = "^x7070FF",
	DUELIST = "^xE0E070",
	TEMPLAR = "^xC040FF",
	SHADOW = "^x30C0D0",
	MAINHAND = "^x50FF50",
	MAINHANDBG = "^x071907",
	OFFHAND = "^xB7B7FF",
	OFFHANDBG = "^x070719",
}
data.colorCodes.STRENGTH = data.colorCodes.MARAUDER
data.colorCodes.DEXTERITY = data.colorCodes.RANGER
data.colorCodes.INTELLIGENCE = data.colorCodes.WITCH
data.skillColorMap = { data.colorCodes.STRENGTH, data.colorCodes.DEXTERITY, data.colorCodes.INTELLIGENCE, data.colorCodes.NORMAL }

data.jewelRadius = {
	{ rad = 800, col = "^xBB6600", label = "Small" },
	{ rad = 1200, col = "^x66FFCC", label = "Medium" },
	{ rad = 1500, col = "^x2222CC", label = "Large" }
}

-- Exported data tables:
-- From DefaultMonsterStats.dat
data.monsterEvasionTable = { 36, 42, 49, 56, 64, 72, 80, 89, 98, 108, 118, 128, 140, 151, 164, 177, 190, 204, 219, 235, 251, 268, 286, 305, 325, 345, 367, 389, 412, 437, 463, 489, 517, 546, 577, 609, 642, 676, 713, 750, 790, 831, 873, 918, 964, 1013, 1063, 1116, 1170, 1227, 1287, 1349, 1413, 1480, 1550, 1623, 1698, 1777, 1859, 1944, 2033, 2125, 2221, 2321, 2425, 2533, 2645, 2761, 2883, 3009, 3140, 3276, 3418, 3565, 3717, 3876, 4041, 4213, 4391, 4576, 4768, 4967, 5174, 5389, 5613, 5845, 6085, 6335, 6595, 6864, 7144, 7434, 7735, 8048, 8372, 8709, 9058, 9420, 9796, 10186, }
data.monsterAccuracyTable = { 18, 19, 20, 21, 23, 24, 25, 27, 28, 30, 31, 33, 35, 36, 38, 40, 42, 44, 46, 49, 51, 54, 56, 59, 62, 65, 68, 71, 74, 78, 81, 85, 89, 93, 97, 101, 106, 111, 116, 121, 126, 132, 137, 143, 149, 156, 162, 169, 177, 184, 192, 200, 208, 217, 226, 236, 245, 255, 266, 277, 288, 300, 312, 325, 338, 352, 366, 381, 396, 412, 428, 445, 463, 481, 500, 520, 540, 562, 584, 607, 630, 655, 680, 707, 734, 762, 792, 822, 854, 887, 921, 956, 992, 1030, 1069, 1110, 1152, 1196, 1241, 1288, }
data.monsterLifeTable = { 15, 17, 20, 23, 26, 30, 33, 37, 41, 46, 50, 55, 60, 66, 71, 77, 84, 91, 98, 105, 113, 122, 131, 140, 150, 161, 171, 183, 195, 208, 222, 236, 251, 266, 283, 300, 318, 337, 357, 379, 401, 424, 448, 474, 501, 529, 559, 590, 622, 656, 692, 730, 769, 810, 853, 899, 946, 996, 1048, 1102, 1159, 1219, 1281, 1346, 1415, 1486, 1561, 1640, 1722, 1807, 1897, 1991, 2089, 2192, 2299, 2411, 2528, 2651, 2779, 2913, 3053, 3199, 3352, 3511, 3678, 3853, 4035, 4225, 4424, 4631, 4848, 5074, 5310, 5557, 5815, 6084, 6364, 6658, 6964, 7283, }
data.monsterDamageTable = { 5, 6, 6, 7, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 23, 24, 26, 28, 30, 32, 34, 36, 39, 41, 44, 47, 50, 53, 56, 59, 63, 67, 71, 75, 80, 84, 89, 94, 100, 106, 112, 118, 125, 131, 139, 147, 155, 163, 172, 181, 191, 202, 212, 224, 236, 248, 262, 275, 290, 305, 321, 338, 355, 374, 393, 413, 434, 456, 480, 504, 530, 556, 584, 614, 645, 677, 711, 746, 783, 822, 862, 905, 949, 996, 1045, 1096, 1149, 1205, 1264, 1325, 1390, 1457, 1527, 1601, 1678, 1758, }
-- From MonsterVarieties.dat combined with SkillTotemVariations.dat
data.totemLifeMult = { [1] = 2.94, [2] = 2.94, [3] = 2.94, [4] = 2.94, [5] = 2.94, [6] = 4.2, [7] = 2.94, [8] = 2.94, [9] = 2.94, [10] = 2.94, [11] = 2.94, [12] = 2.94, [13] = 4.5, [15] = 4.5, }

data.monsterExperienceLevelMap = { [71] = 70.94, [72] = 71.82, [73] = 72.64, [74] = 73.40, [75] = 74.10, [76] = 74.74, [77] = 75.32, [78] = 75.84, [79] = 76.30, [80] = 76.70, [81] = 77.04, [82] = 77.32, [83] = 77.54, [84] = 77.70, }
for i = 1, 70 do
	data.monsterExperienceLevelMap[i] = i
end

data.weaponTypeInfo = {
	["None"] = { oneHand = true, melee = true, flag = ModFlag.Unarmed },
	["Bow"] = { oneHand = false, melee = false, flag = ModFlag.Bow },
	["Claw"] = { oneHand = true, melee = true, flag = ModFlag.Claw },
	["Dagger"] = { oneHand = true, melee = true, flag = ModFlag.Dagger },
	["Staff"] = { oneHand = false, melee = true, flag = ModFlag.Staff },
	["Wand"] = { oneHand = true, melee = false, flag = ModFlag.Wand },
	["One Handed Axe"] = { oneHand = true, melee = true, flag = ModFlag.Axe },
	["One Handed Mace"] = { oneHand = true, melee = true, flag = ModFlag.Mace },
	["One Handed Sword"] = { oneHand = true, melee = true, flag = ModFlag.Sword },
	["Two Handed Axe"] = { oneHand = false, melee = true, flag = ModFlag.Axe },
	["Two Handed Mace"] = { oneHand = false, melee = true, flag = ModFlag.Mace },
	["Two Handed Sword"] = { oneHand = false, melee = true, flag = ModFlag.Sword },
}

data.unarmedWeaponData = {
	[0] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 6 }, -- Scion
	[1] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 8 }, -- Marauder
	[2] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 5 }, -- Ranger
	[3] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 5 }, -- Witch
	[4] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 6 }, -- Duelist
	[5] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 6 }, -- Templar
	[6] = { type = "None", attackRate = 1.2, critChance = 0, PhysicalMin = 2, PhysicalMax = 5 }, -- Shadow
}

data.itemBases = { }
data.uniques = { }
data.rares = LoadModule("Data/Rares")
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
for _, type in pairs(itemTypes) do
	LoadModule("Data/Bases/"..type, data.itemBases)
	data.uniques[type] = LoadModule("Data/Uniques/"..type)
end

LoadModule("Data/New")