-- Path of Building
--
-- Module: Data
-- Contains static data used by other modules.
--
local launch = ...

LoadModule("Data/Global")

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
		tagList = { ... }
	}
end
local function makeFlagMod(modName, ...)
	return makeSkillMod(modName, "FLAG", true, 0, 0, ...)
end
local function makeSkillDataMod(dataKey, dataValue, ...)
	return makeSkillMod("SkillData", "LIST", { key = dataKey, value = dataValue }, 0, 0, ...)
end

-----------------
-- Common Data --
-----------------

data = { }

data.skillColorMap = { colorCodes.STRENGTH, colorCodes.DEXTERITY, colorCodes.INTELLIGENCE, colorCodes.NORMAL }

data.jewelRadius = {
	{ rad = 800, col = "^xBB6600", label = "Small" },
	{ rad = 1200, col = "^x66FFCC", label = "Medium" },
	{ rad = 1500, col = "^x2222CC", label = "Large" }
}

data.labyrinths = {
	{ name = "ENDGAME", label = "Endgame" },
	{ name = "MERCILESS", label = "Merciless" },
	{ name = "CRUEL", label = "Cruel" },
	{ name = "NORMAL", label = "Normal" },
}

data.monsterExperienceLevelMap = { [71] = 70.94, [72] = 71.82, [73] = 72.64, [74] = 73.40, [75] = 74.10, [76] = 74.74, [77] = 75.32, [78] = 75.84, [79] = 76.30, [80] = 76.70, [81] = 77.04, [82] = 77.32, [83] = 77.54, [84] = 77.70, }
for i = 1, 70 do
	data.monsterExperienceLevelMap[i] = i
end

data.weaponTypeInfo = {
	["None"] = { oneHand = true, melee = true, flag = ModFlag.Unarmed, range = 4 },
	["Bow"] = { oneHand = false, melee = false, flag = ModFlag.Bow },
	["Claw"] = { oneHand = true, melee = true, flag = ModFlag.Claw, range = 9 },
	["Dagger"] = { oneHand = true, melee = true, flag = ModFlag.Dagger, range = 8 },
	["Staff"] = { oneHand = false, melee = true, flag = ModFlag.Staff, range = 11 },
	["Wand"] = { oneHand = true, melee = false, flag = ModFlag.Wand },
	["One Handed Axe"] = { oneHand = true, melee = true, flag = ModFlag.Axe, range = 9 },
	["One Handed Mace"] = { oneHand = true, melee = true, flag = ModFlag.Mace, range = 9 },
	["One Handed Sword"] = { oneHand = true, melee = true, flag = ModFlag.Sword, range = 9 },
	["Sceptre"] = { oneHand = true, melee = true, flag = ModFlag.Mace, range = 9, label = "One Handed Mace" },
	["Thrusting One Handed Sword"] = { oneHand = true, melee = true, flag = ModFlag.Sword, range = 12, label = "One Handed Sword" },
	["Two Handed Axe"] = { oneHand = false, melee = true, flag = ModFlag.Axe, range = 11 },
	["Two Handed Mace"] = { oneHand = false, melee = true, flag = ModFlag.Mace, range = 11 },
	["Two Handed Sword"] = { oneHand = false, melee = true, flag = ModFlag.Sword, range = 11 },
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

-- Uniques
data.uniques = { }
for _, type in pairs(itemTypes) do
	data.uniques[type] = LoadModule("Data/Uniques/"..type)
end
LoadModule("Data/New")

-- Misc. exported data tables
LoadModule("Data/Misc")

---------------------------
-- Version-specific Data --
---------------------------

for _, targetVersion in ipairs(targetVersionList) do
	data[targetVersion] = setmetatable({ }, { __index = data })
	local function dataModule(mod, ...)
		return LoadModule("Data/"..targetVersion.."/"..mod, ...)
	end

	-- Load item modifiers
	data[targetVersion].itemMods = {
		Item = dataModule("ModItem"),
		Flask = dataModule("ModFlask"),
		Jewel = dataModule("ModJewel"),
	}
	data[targetVersion].corruptedMods = dataModule("ModCorrupted")
	data[targetVersion].masterMods = dataModule("ModMaster")
	data[targetVersion].enchantments = {
		Helmet = dataModule("EnchantmentHelmet"),
		Boots = dataModule("EnchantmentBoots"),
	}
	data[targetVersion].essences = dataModule("Essence")

	-- Load skills
	data[targetVersion].skills = { }
	for _, type in pairs(skillTypes) do
		dataModule("Skills/"..type, data[targetVersion].skills, makeSkillMod, makeFlagMod, makeSkillDataMod)
	end
	for skillId, grantedEffect in pairs(data[targetVersion].skills) do
		grantedEffect.id = skillId
		-- Add sources for skill mods
		for _, list in pairs({grantedEffect.baseMods, grantedEffect.qualityMods, grantedEffect.levelMods}) do
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

	-- Build gem list
	data[targetVersion].gems = { }
	for _, grantedEffect in pairs(data[targetVersion].skills) do
		if grantedEffect.gemTags then
			data[targetVersion].gems[grantedEffect.name] = grantedEffect
			grantedEffect.defaultLevel = (grantedEffect.levels[20] and 20) or (grantedEffect.levels[3][2] and 3) or 1
		end
	end

	-- Load minions
	data[targetVersion].minions = { }
	dataModule("Minions", data[targetVersion].minions, makeSkillMod)
	data[targetVersion].spectres = { }
	dataModule("Spectres", data[targetVersion].spectres, makeSkillMod)
	for name, spectre in pairs(data[targetVersion].spectres) do
		spectre.limit = "ActiveSpectreLimit"
		data[targetVersion].minions[name] = spectre
	end
	local missing = { }
	for _, minion in pairs(data[targetVersion].minions) do
		for _, skillId in ipairs(minion.skillList) do
			if launch.devMode and not data[targetVersion].skills[skillId] and not missing[skillId] then
				ConPrintf("'%s' missing skill '%s'", minion.name, skillId)
				missing[skillId] = true
			end
		end
		for _, mod in ipairs(minion.modList) do
			mod.source = "Minion:"..minion.name
		end
	end

	-- Item bases
	data[targetVersion].itemBases = { }
	for _, type in pairs(itemTypes) do
		dataModule("Bases/"..type, data[targetVersion].itemBases)
	end

	-- Rare templates
	data[targetVersion].rares = dataModule("Rares")
end