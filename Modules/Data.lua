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
	{ stat="PoisonDPS", label="Poison DPS" },
	{ stat="IgniteDPS", label="Ignite DPS" },
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
	{ rad = 800, col = "^xBB6600", label = "Small" },
	{ rad = 1200, col = "^x66FFCC", label = "Medium" },
	{ rad = 1500, col = "^x2222CC", label = "Large" }
}

data.labyrinths = {
	{ name = "ENDGAME", label = "Eternal" },
	{ name = "MERCILESS", label = "Merciless" },
	{ name = "CRUEL", label = "Cruel" },
	{ name = "NORMAL", label = "Normal" },
}

data.monsterExperienceLevelMap = { [71] = 70.94, [72] = 71.82, [73] = 72.64, [74] = 73.40, [75] = 74.10, [76] = 74.74, [77] = 75.32, [78] = 75.84, [79] = 76.30, [80] = 76.70, [81] = 77.04, [82] = 77.32, [83] = 77.54, [84] = 77.70, }
for i = 1, 70 do
	data.monsterExperienceLevelMap[i] = i
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
	["Amulet"] = { shaper = "amulet_shaper", elder = "amulet_elder", },
	["Ring"] = { shaper = "ring_shaper", elder = "ring_elder", },
	["Claw"] = { shaper = "claw_shaper", elder = "claw_elder", },
	["Dagger"] = { shaper = "dagger_shaper", elder = "dagger_elder", },
	["Wand"] = { shaper = "wand_shaper", elder = "wand_elder", },
	["One Handed Sword"] = { shaper = "sword_shaper", elder = "sword_elder", },
	["Thrusting One Handed Sword"] = { shaper = "sword_shaper", elder = "sword_elder", },
	["One Handed Axe"] = { shaper = "axe_shaper", elder = "axe_elder", },
	["One Handed Mace"] = { shaper = "mace_shaper", elder = "mace_elder", },
	["Bow"] = { shaper = "bow_shaper", elder = "bow_elder", },
	["Staff"] = { shaper = "staff_shaper", elder = "staff_elder", },
	["Two Handed Sword"] = { shaper = "2h_sword_shaper", elder = "2h_sword_elder", },
	["Two Handed Axe"] = { shaper = "2h_axe_shaper", elder = "2h_axe_elder", },
	["Two Handed Mace"] = { shaper = "2h_mace_shaper", elder = "2h_mace_elder", },
	["Quiver"] = { shaper = "quiver_shaper", elder = "quiver_elder", },
	["Belt"] = { shaper = "belt_shaper", elder = "belt_elder", },
	["Gloves"] = { shaper = "gloves_shaper", elder = "gloves_elder", },
	["Boots"] = { shaper = "boots_shaper", elder = "boots_elder", },
	["Body Armour"] = { shaper = "body_armour_shaper", elder = "body_armour_elder", },
	["Helmet"] = { shaper = "helmet_shaper", elder = "helmet_elder", },
	["Shield"] = { shaper = "shield_shaper", elder = "shield_elder", },
	["Sceptre"] = { shaper = "sceptre_shaper", elder = "sceptre_elder", },
}

-- Uniques
data.uniques = { }
for _, type in pairs(itemTypes) do
	data.uniques[type] = LoadModule("Data/Uniques/"..type)
end
LoadModule("Data/New")

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
	}
	verData.masterMods = dataModule("ModMaster")
	verData.enchantments = {
		Helmet = dataModule("EnchantmentHelmet"),
		Boots = dataModule("EnchantmentBoots"),
		Gloves = dataModule("EnchantmentGloves"),
	}
	verData.essences = dataModule("Essence")
	verData.pantheons = targetVersion ~= "2_6" and dataModule("Pantheons") or { }
	
	-- Load skills
	verData.skills = { }
	verData.skillStatMap = dataModule("SkillStatMap", makeSkillMod, makeFlagMod, makeSkillDataMod)
	verData.skillStatMapMeta = {
		__index = function(t, key)
			local map = verData.skillStatMap[key]
			if map then
				t[key] = copyTable(map, true)
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
	for gemId, gem in pairs(verData.gems) do
		gem.id = gemId
		gem.grantedEffect = verData.skills[gem.grantedEffectId]
		verData.gemForSkill[gem.grantedEffect] = gemId
		gem.secondaryGrantedEffect = gem.secondaryGrantedEffectId and verData.skills[gem.secondaryGrantedEffectId]
		gem.grantedEffectList = {
			gem.grantedEffect,
			gem.secondaryGrantedEffect
		}
		gem.defaultLevel = (#gem.grantedEffect.levels > 20 and #gem.grantedEffect.levels - 20) or (gem.grantedEffect.levels[3][1] and 3) or 1
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