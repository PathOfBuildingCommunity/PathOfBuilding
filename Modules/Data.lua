-- Path of Building
--
-- Module: Data
-- Contains static data used by other modules
--

data = { }

data.gems = { }
local gemTypes = {
	"act_str",
	"act_dex",
	"act_int",
	"other",
	"sup_str",
	"sup_dex",
	"sup_int",
}
for _, type in pairs(gemTypes) do
	LoadModule("Data/Gems/"..type, data.gems)
end

data.colorCodes = {
	NORMAL = "^xC8C8C8",
	MAGIC = "^x8888FF",
	RARE = "^xFFFF77",
	UNIQUE = "^xAF6025",
	FIRE = "^x960000",
	COLD = "^x366492",
	LIGHTNING = "^xFFD700",
	CHAOS = "^xD02090",
	POSITIVE = "^x33FF77",
	NEGATIVE = "^xDD0022",
	SCION = "^xFFF0F0",
	MARAUDER = "^xE05030",
	RANGER = "^x70FF70",
	WITCH = "^x7070FF",
	DUELIST = "^xE0E070",
	TEMPLAR = "^xC040FF",
	SHADOW = "^x30C0D0",
}

data.jewelRadius = {
	{ rad = 800, col = "^xBB6600", label = "Small" },
	{ rad = 1200, col = "^x66FFCC", label = "Medium" },
	{ rad = 1500, col = "^x2222CC", label = "Large" }
}

data.enemyEvasionTable = {36,   42,   49,   56,   64,   72,   80,   89,   98,  108,
						 118,  128,  140,  151,  164,  177,  190,  204,  219,  235,
						 251,  268,  286,  305,  325,  345,  367,  389,  412,  437,
						 463,  489,  517,  546,  577,  609,  642,  676,  713,  750,
						 790,  831,  873,  918,  964, 1013, 1063, 1116, 1170, 1227,
						1287, 1349, 1413, 1480, 1550, 1623, 1698, 1777, 1859, 1944,
						2033, 2125, 2221, 2321, 2425, 2533, 2645, 2761, 2883, 3009,
						3140, 3276, 3418, 3565, 3717, 3876, 4041, 4213, 4391, 4574,
						4767, 4969, 5179, 5398 }
data.enemyAccuracyTable = {  18,  19,  20,  21,  23,  24,  25,  27,  28,  30,
							 31,  33,  35,  36,  38,  40,  42,  44,  46,  49,
							 51,  54,  56,  59,  62,  65,  68,  71,  74,  78,
							 81,  85,  89,  93,  97, 101, 106, 111, 116, 121,
							126, 132, 137, 143, 149, 156, 162, 169, 177, 184,
							192, 200, 208, 217, 226, 236, 245, 255, 266, 277,
							288, 300, 312, 325, 338, 352, 366, 381, 396, 412,
							428, 445, 463, 481, 500, 520, 540, 562, 584, 607,
							632, 657, 683, 711 }

data.weaponTypeInfo = {
	["None"] = { oneHand = true, melee = true, space = "unarmed" },
	["Bow"] = { oneHand = false, melee = false, space = "bow" },
	["Claw"] = { oneHand = true, melee = true, space = "claw" },
	["Dagger"] = { oneHand = true, melee = true, space = "dagger" },
	["Staff"] = { oneHand = false, melee = true, space = "staff" },
	["Wand"] = { oneHand = true, melee = false, space = "wand" },
	["One Handed Axe"] = { oneHand = true, melee = true, space = "axe" },
	["One Handed Mace"] = { oneHand = true, melee = true, space = "mace" },
	["One Handed Sword"] = { oneHand = true, melee = true, space = "sword" },
	["Two Handed Axe"] = { oneHand = false, melee = true, space = "axe" },
	["Two Handed Mace"] = { oneHand = false, melee = true, space = "mace" },
	["Two Handed Sword"] = { oneHand = false, melee = true, space = "sword" },
}

data.unarmedWeap = {
	[0] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 6 }, -- Scion
	[1] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 8 }, -- Marauder
	[2] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 5 }, -- Ranger
	[3] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 5 }, -- Witch
	[4] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 6 }, -- Duelist
	[5] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 6 }, -- Templar
	[6] = { attackRate = 1.2, critChanceBase = 0, physicalMin = 2, physicalMax = 5 }, -- Shadow
}

data.itemBases = { }
data.uniques = { }
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
}
for _, type in pairs(itemTypes) do
	LoadModule("Data/Bases/"..type, data.itemBases)
	data.uniques[type] = LoadModule("Data/Uniques/"..type)
end
