-- Path of Building
--
-- Module: Data
-- Contains static data used by other modules.
--

LoadModule("Data/Global")

local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local t_insert = table.insert
local t_concat = table.concat

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
	{ stat="TotalDPS", label="Hit DPS" },
	{ stat="WithImpaleDPS", label="Impale + Hit DPS" },
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
	{ stat="TotalEHP", label="Effective Hit Pool" },
	{ stat="SecondMinimalMaximumHitTaken", label="Eff. Maximum Hit Taken" },
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
		{ inner = 2400, outer = 2880, col = "^x0B9300", label = "Variable" },
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

data.cursePriority = {
	["Temporal Chains"] = 1, -- Despair and Elemental Weakness override Temporal Chains.
	["Enfeeble"] = 2, -- Elemental Weakness and Vulnerability override Enfeeble.
	["Vulnerability"] = 3, -- Despair and Elemental Weakness override Vulnerability. Vulnerability was reworked in 3.1.0.
	["Elemental Weakness"] = 4, -- Despair and Flammability override Elemental Weakness.
	["Flammability"] = 5, -- Frostbite overrides Flammability.
	["Frostbite"] = 6, -- Conductivity overrides Frostbite.
	["Conductivity"] = 7,
	["Despair"] = 8, -- Despair was created in 3.1.0.
	["Punishment"] = 9, -- Punishment was reworked in 3.12.0.
	["Warlord's Mark"] = 10,
	["Assassin's Mark"] = 11,
	["Sniper's Mark"] = 12,
	["Poacher's Mark"] = 13,
	["SocketPriorityBase"] = 100,
	["Weapon 1"] = 1000,
	["Amulet"] = 2000,
	["Helmet"] = 3000,
	["Weapon 2"] = 4000,
	["Body Armour"] = 5000,
	["Gloves"] = 6000,
	["Boots"] = 7000,
	["Ring 1"] = 8000,
	["Ring 2"] = 9000,
	["CurseFromEquipment"] = 10000,
	["CurseFromAura"] = 20000,
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
	"Hex Master",
	"Hollow Palm Technique",
	"Imbalanced Guard",
	"Immortal Ambition",
	"Inner Conviction",
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
	"Precise Technique",
	"Resolute Technique",
	"Runebinder",
	"Secrets of Suffering",
	"Solipsism",
	"Supreme Decadence",
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

data.ailmentTypeList = { "Bleed", "Poison", "Ignite", "Chill", "Freeze", "Shock", "Scorch", "Brittle", "Sap" }
data.elementalAilmentTypeList = { "Ignite", "Chill", "Freeze", "Shock", "Scorch", "Brittle", "Sap" }
data.nonElementalAilmentTypeList = { "Bleed", "Poison" }

data.nonDamagingAilment = {
	["Chill"] = { associatedType = "Cold", alt = false, default = 10, min = 5, max = 30, precision = 0, duration = 2 },
	["Freeze"] = { associatedType = "Cold", alt = false, default = nil, min = 0.3, max = 3, precision = 2, duration = nil },
	["Shock"] = { associatedType = "Lightning", alt = false, default = 15, min = 5, max = 50, precision = 0, duration = 2 },
	["Scorch"] = { associatedType = "Fire", alt = true, default = 10, min = 0, max = 30, precision = 0, duration = 4 },
	["Brittle"] = { associatedType = "Cold", alt = true, default = 2, min = 0, max = 6, precision = 2, duration = 4 },
	["Sap"] = { associatedType = "Lightning", alt = true, default = 6, min = 0, max = 20, precision = 0, duration = 4 },
}

-- Used in ModStoreClass:ScaleAddMod(...) to identify high precision modifiers
data.defaultHighPrecision = 1
data.highPrecisionMods = {
	["CritChance"] = {
		["BASE"] = 2,
	},
	["SelfCritChance"] = {
		["BASE"] = 2,
	},
	["LifeRegenPercent"] = {
		["BASE"] = 2,
	},
	["ManaRegenPercent"] = {
		["BASE"] = 2,
	},
	["EnergyShieldRegenPercent"] = {
		["BASE"] = 2,
	},
	["LifeRegen"] = {
		["BASE"] = 1,
	},
	["ManaRegen"] = {
		["BASE"] = 1,
	},
	["EnergyShieldRegen"] = {
		["BASE"] = 1,
	},
	["LifeDegenPercent"] = {
		["BASE"] = 2,
	},
	["ManaDegenPercent"] = {
		["BASE"] = 2,
	},
	["EnergyShieldDegenPercent"] = {
		["BASE"] = 2,
	},
	["LifeDegen"] = {
		["BASE"] = 1,
	},
	["ManaDegen"] = {
		["BASE"] = 1,
	},
	["EnergyShieldDegen"] = {
		["BASE"] = 1,
	},
	["DamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["PhysicalDamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["ElementalDamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["FireDamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["ColdDamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["LightningDamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["ChaosDamageLifeLeech"] = {
		["BASE"] = 2,
	},
	["DamageManaLeech"] = {
		["BASE"] = 2,
	},
	["PhysicalDamageManaLeech"] = {
		["BASE"] = 2,
	},
	["ElementalDamageManaLeech"] = {
		["BASE"] = 2,
	},
	["FireDamageManaLeech"] = {
		["BASE"] = 2,
	},
	["ColdDamageManaLeech"] = {
		["BASE"] = 2,
	},
	["LightningDamageManaLeech"] = {
		["BASE"] = 2,
	},
	["ChaosDamageManaLeech"] = {
		["BASE"] = 2,
	},
	["DamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["PhysicalDamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["ElementalDamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["FireDamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["ColdDamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["LightningDamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["ChaosDamageEnergyShieldLeech"] = {
		["BASE"] = 2,
	},
	["SupportManaMultiplier"] = {
		["MORE"] = 4,
	}
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
	WardRechargeDelay = 4,
	Transfiguration = 0.3,
	EnemyMaxResist = 75,
	LeechRateBase = 0.02,
	DotDpsCap = 35791394, -- (2 ^ 31 - 1) / 60 (int max / 60 seconds)
	BleedPercentBase = 70,
	BleedDurationBase = 5,
	PoisonPercentBase = 0.30,
	PoisonDurationBase = 2,
	IgnitePercentBase = 0.9,
	IgniteDurationBase = 4,
	IgniteMinDuration = 0.3,
	ImpaleStoredDamageBase = 0.1,
	BuffExpirationSlowCap = 0.25,
	TrapTriggerRadiusBase = 10,
	MineDetonationRadiusBase = 60,
	MineAuraRadiusBase = 35,
	MaxEnemyLevel = 85,
	LowPoolThreshold = 0.5,
	MinStunChanceNeeded = 20,
	StunBaseMult = 200,
	StunBaseDuration = 0.35,
	StunNotMeleeDamageMult = 0.75,
	AccuracyPerDexBase = 2,
	BrandAttachmentRangeBase = 30,
	ProjectileDistanceCap = 150,
	-- Expected values to calculate EHP
	stdBossDPSMult = 4 / 4.40,
	pinnacleBossDPSMult = 8 / 4.40,
	pinnacleBossPen = 15 / 5,
	uberBossDPSMult = 10 / 4.25,
	uberBossPen = 40 / 5,
	-- ehp helper function magic numbers
	ehpCalcSpeedUp = 8,
	-- max damage can be increased for more accuracy
	ehpCalcMaxDamage = 100000000,
	-- max iterations can be increased for more accuracy this should be perfectly accurate unless it runs out of iterations and so high eHP values will be underestimated.
	ehpCalcMaxIterationsToCalc = 50,
	-- PvP scaling used for hogm
	PvpElemental1 = 0.55,
	PvpElemental2 = 150,
	PvpNonElemental1 = 0.57,
	PvpNonElemental2 = 90,
}

-- Load bosses
do 
	data.bosses = { }
	LoadModule("Data/Bosses", data.bosses)
	
	local count, uberCount = 0, 0
	local armourTotal, evasionTotal = 0, 0
	local uberArmourTotal, uberEvasionTotal = 0, 0

	for _, boss in pairs(data.bosses) do
		if boss.isUber then
			uberCount = uberCount + 1
			uberArmourTotal = uberArmourTotal + boss.armourMult
			uberEvasionTotal = uberEvasionTotal + boss.evasionMult
		end
		count = count + 1
		armourTotal = armourTotal + boss.armourMult
		evasionTotal = evasionTotal + boss.evasionMult
	end

	data.bossStats = {
		PinnacleArmourMean = 100 + armourTotal / count,
		PinnacleEvasionMean = 100 + evasionTotal / count,
		UberArmourMean = 100 + uberArmourTotal / uberCount,
		UberEvasionMean = 100 + uberEvasionTotal / uberCount
	}

	data.bossSkills, data.bossSkillsList = LoadModule("Data/BossSkills")

	data.enemyIsBossTooltip = [[Bosses' damage is monster damage scaled to an average damage of their attacks
This is divided by 4.40 to represent 4 damage types + some (40% as much) ^xD02090chaos
^7Fill in the exact damage numbers if more precision is needed

Bosses' armour and evasion multiplier are calculated using the average of the boss type

Standard Boss adds the following modifiers:
	+40% to enemy Elemental Resistances
	+25% to enemy ^xD02090Chaos Resistance
	^7]]..tostring(m_floor(data.misc.stdBossDPSMult * 100))..[[% of monster Damage of each type
	]]..tostring(m_floor(data.misc.stdBossDPSMult * 4.4 * 100))..[[% of monster Damage total

Guardian / Pinnacle Boss adds the following modifiers:
	+50% to enemy Elemental Resistances
	+30% to enemy ^xD02090Chaos Resistance
	^7]]..tostring(m_floor(data.bossStats.PinnacleArmourMean))..[[% of monster Armour
	]]..tostring(m_floor(data.bossStats.PinnacleEvasionMean))..[[% of monster ^x33FF77Evasion
	^7]]..tostring(m_floor(data.misc.pinnacleBossDPSMult * 100))..[[% of monster Damage of each type
	]]..tostring(m_floor(data.misc.pinnacleBossDPSMult * 4.4 * 100))..[[% of monster Damage total
	]]..tostring(data.misc.pinnacleBossPen)..[[% penetration

Uber Pinnacle Boss adds the following modifiers:
	+50% to enemy Elemental Resistances
	+30% to enemy ^xD02090Chaos Resistance
	^7]]..tostring(m_floor(data.bossStats.UberArmourMean))..[[% of monster Armour
	]]..tostring(m_floor(data.bossStats.UberEvasionMean))..[[% of monster ^x33FF77Evasion
	^770% less to enemy Damage taken
	]]..tostring(m_floor(data.misc.uberBossDPSMult * 100))..[[% of monster Damage of each type
	]]..tostring(m_floor(data.misc.uberBossDPSMult * 4.25 * 100))..[[% of monster Damage total
	]]..tostring(data.misc.uberBossPen)..[[% penetration]]
end

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
data.costs = LoadModule("Data/Costs")
do
	local map = { }
	for i, value in ipairs(data.costs) do
		map[value.Resource] = i
	end
	setmetatable(data.costs, { __index = function(t, k) return t[map[k]] end })
end

-- Manually seeded modifier tag against item slot table for Mastery Item Condition based modifiers
-- Data is informed by getTagBasedModifiers() located in Item.lua
data.itemTagSpecial = {
	["life"] = {
		["body armour"] = {
			-- Keystone
			"Blood Magic",
			"Eternal Youth",
			"Ghost Reaver",
			"Mind Over Matter",
			"The Agnostic",
			"Vaal Pact",
			"Zealot's Oath",
			-- Special Cases
			"Cannot Leech",
			"Damage taken Recouped as",
		},
	},
	["evasion"] = {
		["ring"] = {
			-- Delve
			"chance to Evade",
			-- Unique
			"Cannot Evade",
		},
	},
}

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

-- Load legion jewel data
local function loadJewelFile(jewelTypeName)
	jewelTypeName = "/Data/TimelessJewelData/" .. jewelTypeName
	local jewelData

	local scriptPath = GetScriptPath()

	local fileHandle = NewFileSearch(scriptPath .. jewelTypeName .. ".bin")
	local uncompressedFileAttr = { }
	if fileHandle then
		uncompressedFileAttr.fileName = fileHandle:GetFileName()
		uncompressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end

	fileHandle = NewFileSearch(scriptPath .. jewelTypeName .. ".zip")
	local compressedFileAttr = { }
	if fileHandle then
		compressedFileAttr.fileName = fileHandle:GetFileName()
		compressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end

	fileHandle = NewFileSearch(scriptPath .. jewelTypeName .. ".zip.part*")
	local splitFile = { }
	if fileHandle then
		compressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end
	while fileHandle do
		local fileName = fileHandle:GetFileName()
		local file = io.open(scriptPath .. "/Data/TimelessJewelData/" .. fileName, "rb")
		local part = tonumber(fileName:match("%.part(%d)")) or 0
		splitFile[part + 1] = file:read("*a")
		file:close()
		if not fileHandle:NextFile() then
			break
		end
	end
	splitFile = t_concat(splitFile, "")

	if uncompressedFileAttr.modified and uncompressedFileAttr.modified > (compressedFileAttr.modified or 0) then
		ConPrintf("Uncompressed jewel data is up-to-date, loading " .. uncompressedFileAttr.fileName)
		local uncompressedFile = io.open(scriptPath .. jewelTypeName .. ".bin", "rb")
		if uncompressedFile then
			jewelData = uncompressedFile:read("*a")
			uncompressedFile:close()
		end
		if jewelData then
			return jewelData
		end
	end

	ConPrintf("Failed to load " .. scriptPath .. jewelTypeName .. ".bin, or data is out of date, falling back to compressed file")
	local compressedFile = io.open(scriptPath .. jewelTypeName .. ".zip", "rb")
	if compressedFile then
		jewelData = Inflate(compressedFile:read("*a"))
		compressedFile:close()
	elseif splitFile ~= "" then
		jewelData = Inflate(splitFile)
	end

	if jewelData == nil then
		ConPrintf("Failed to load either file: " .. jewelTypeName .. ".zip, " .. jewelTypeName .. ".bin")
		if (data.nodeIDList[1] and (data.nodeIDList[1].rebuildLUT or 0) or 0) == 1 then
			ConPrintf("looking for base LUT to rebuild")
			local jewelType = 1
			while ("/Data/TimelessJewelData/" .. data.timelessJewelTypes[jewelType]:gsub("%s+", "")) ~= jewelTypeName and jewelType < 5 do
				jewelType = jewelType + 1
			end
			local compressedFile = io.open(scriptPath .. "/Data/TimelessJewelData/" .. data.timelessJewelTypes[jewelType], "rb")
			if compressedFile then
				ConPrintf("base LUT found: " .. jewelTypeName)
				jewelData = compressedFile:read("*a")
				compressedFile:close()

				--- Code for compressing existing data if it changed
				if jewelType == 1 then
					ConPrintf("GV needs to be split manually")
				else
					local compressedFileData = Deflate(jewelData)
					local file = assert(io.open(scriptPath .. "Data/TimelessJewelData/" .. jewelTypeName .. ".zip", "wb+"))
					file:write(compressedFileData)
					file:close()
				end
			end
		end
	else
		local uncompressedFile = io.open(scriptPath .. jewelTypeName .. ".bin", "wb+")
		if uncompressedFile then
			uncompressedFile:write(jewelData)
			uncompressedFile:close()
		end
	end
	return jewelData
end

-- lazy load a specific timeless jewel type
-- valid values: "Glorious Vanity", "Lethal Pride", "Brutal Restraint", "Militant Faith", "Elegant Hubris"
local function loadTimelessJewel(jewelType, nodeID)
	local nodeIndex = nil
	if nodeID and data.nodeIDList[nodeID] then
		nodeIndex = data.nodeIDList[nodeID].index
	end
	-- for GV, if nodeIndex is invalid, return
	if jewelType == 1 and nodeIndex == nil then
		return
	end
	-- if LUT is already loaded, and this either isn't GV, or GV has already emptied it's raw data out, return
	if data.timelessJewelLUTs[jewelType] and data.timelessJewelLUTs[jewelType].data and (jewelType ~= 1 or data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw == nil) then
		return
	end

	if jewelType == 1 then
		-- if data is already loaded but table for specific node is not created, just make table and return
		if data.timelessJewelLUTs[jewelType] and data.timelessJewelLUTs[jewelType].data[nodeIndex + 1] and data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw then
			local jewelData = data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw
			local seedSize = data.timelessJewelSeedMax[1] - data.timelessJewelSeedMin[1] + 1
			local count = 0
			for seedOffset = 1, (seedSize + 1) do
				local dataLength = data.timelessJewelLUTs[jewelType].sizes:byte(nodeIndex * seedSize + seedOffset)
				data.timelessJewelLUTs[jewelType].data[nodeIndex + 1][seedOffset] = jewelData:sub(count + 1, count + dataLength)
				count = count + dataLength
			end
			data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw = nil
			return
		end
		data.timelessJewelLUTs[jewelType] = { data = { } }
	else
		data.timelessJewelLUTs[jewelType] = { }
	end

	ConPrintf("LOADING")

	local jewelData = loadJewelFile(data.timelessJewelTypes[jewelType]:gsub("%s+", ""))

	if jewelData then
		if jewelType == 1 then -- "Glorious Vanity"
			local GV_nodecount = data.nodeIDList.size
			local seedSize = data.timelessJewelSeedMax[1] - data.timelessJewelSeedMin[1] + 1
			local sizeOffset = GV_nodecount * seedSize
			data.timelessJewelLUTs[jewelType].sizes = jewelData:sub(1, sizeOffset + 1)

			-- Loop through nodes in order as if we were reading from a file
			for i = 1, GV_nodecount do
				-- Find the node this corresponds to
				local nodeID
				for k, v in pairs(data.nodeIDList) do
					if type(v) == "table" and v.index == (i - 1) then
						nodeID = k
						break
					end
				end
				-- Preliminary initialization
				local seedDataLength = data.nodeIDList[nodeID].size
				data.timelessJewelLUTs[jewelType].data[i] = {}
				data.timelessJewelLUTs[jewelType].data[i].raw = jewelData:sub(sizeOffset + 1, sizeOffset + seedDataLength)
				sizeOffset = sizeOffset + seedDataLength
				if i == (nodeIndex + 1) then
					-- Final initialization for this seed
					local jewelData2 = data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw
					local seedOffset = 0
					for seedKey = 1, (seedSize + 1) do
						local dataLength = data.timelessJewelLUTs[jewelType].sizes:byte(nodeIndex * seedSize + seedKey)
						data.timelessJewelLUTs[jewelType].data[nodeIndex + 1][seedKey] = jewelData2:sub(seedOffset + 1, seedOffset + dataLength)
						seedOffset = seedOffset + dataLength
					end
					data.timelessJewelLUTs[jewelType].data[i].raw = nil
				end
			end
			ConPrintf("Glorious Vanity Lookup Table Loaded! Read " .. sizeOffset .. " bytes")
			return
		else
			data.timelessJewelLUTs[jewelType].data = jewelData
		end
	end
end

data.timelessJewelTypes = {
	[1] = "Glorious Vanity",
	[2] = "Lethal Pride",
	[3] = "Brutal Restraint",
	[4] = "Militant Faith",
	[5] = "Elegant Hubris",
}
data.timelessJewelSeedMin = {
	[1] = 100,
	[2] = 10000,
	[3] = 500,
	[4] = 2000,
	[5] = 2000 / 20,
}
data.timelessJewelSeedMax = {
	[1] = 8000,
	[2] = 18000,
	[3] = 8000,
	[4] = 10000,
	[5] = 160000 / 20,
}
data.timelessJewelTradeIDs = LoadModule("Data/LegionTradeIds")
data.timelessJewelAdditions = 94 -- #legionAdditions
data.nodeIDList = LoadModule("Data/TimelessJewelData/NodeIndexMapping")
data.timelessJewelLUTs = { }
-- this runs if the "size" key is missing from nodeIDList and attempts to rebuild all jewel LUTs and the nodeIDList
-- note this should only run in dev mode
if not data.nodeIDList.size and launch.devMode then -- this doesn't rebuilt the list with the correct sizes, likely an issue with lua indexing from 1 instead of 0, but cbf debugging so just generated the index mapping in c#
	ConPrintf("Error NodeIndexMapping file empty")
	data.nodeIDList = { { index = 0, rebuildLUT = 1 } }
	for _, jewelType in ipairs({2, 3, 4, 5}) do
		loadTimelessJewel(jewelType, 1)
		data.nodeIDList[1].rebuildLUT = 1
	end
	jewelData = loadJewelFile(data.timelessJewelTypes[1]:gsub("%s+", ""))
	if not jewelData then
		ConPrintf("missing GV file to rebuild NodeIndexMapping")
	else
		ConPrintf("attempting to rebuild NodeIndexMapping")
		local scriptPath = GetScriptPath()
		local compressedFile = io.open(scriptPath .. "/Data/TimelessJewelData/node_indices.csv", "rb")
		if compressedFile then
			ConPrintf("csv found")
			local nodeData = compressedFile:read("*a")
			compressedFile:close()
			
			tempIndList = {}
			nodeIDList["size"] = 0
			nodeIDList["sizeNotable"] = 0
			for line in nodeData:gmatch("([^\n]*)\n?") do
				nodeIDList["size"] = nodeIDList["size"] + 1
				if nodeIDList["size"] ~= 1 then
					for split in line:gmatch("([^,]*),?") do
						if tonumber(split) then
							tempIndList[nodeIDList["size"] - 1] = tonumber(split)
							if nodeIDList["size"] ~= 2 and tempIndList[nodeIDList["size"] - 1] < tempIndList[nodeIDList["size"] - 2] then
								nodeIDList["sizeNotable"] = nodeIDList["size"] - 2
							end
						end
						break
					end
				end
			end
			nodeIDList["size"] = nodeIDList["size"] - 2
			ConPrintf(nodeIDList["sizeNotable"])
			ConPrintf(nodeIDList["size"])
			
			
			local seedSize = data.timelessJewelSeedMax[1] - data.timelessJewelSeedMin[1] + 1
			local sizeOffset = nodeIDList.size * seedSize
			data.timelessJewelLUTs[1] = {}
			data.timelessJewelLUTs[1].sizes = jewelData:sub(1, sizeOffset + 1)
			for i, nodeID in ipairs(tempIndList) do
				local nodeIndex = i - 1
				local count = 0
				if i > nodeIDList["sizeNotable"] then
					count = seedSize * 2
				else
					for seedOffset = 1, (seedSize + 1) do
						local dataLength = data.timelessJewelLUTs[1].sizes:byte(nodeIndex * seedSize + seedOffset)
						count = count + dataLength
					end
				end
				nodeIDList[nodeID] = { index = nodeIndex, size = count }
			end
			
			local file = assert(io.open("Data/TimelessJewelData/NodeIndexMapping.lua", "wb+"))
			file:write("nodeIDList = { }\n")
			file:write("nodeIDList[\"size\"] = " .. tostring(nodeIDList["size"]) .. "\n")
			file:write("nodeIDList[\"sizeNotable\"] = " .. tostring(nodeIDList["sizeNotable"]) .. "\n")
			for _, nodeID in ipairs(tempIndList) do
				file:write("nodeIDList[" .. tostring(nodeID) .. "] = { index = " .. tostring(nodeIDList[nodeID].index) .. ", size = " .. tostring(nodeIDList[nodeID].size) .. " }\n")
			end
			file:write("return nodeIDList")
			file:close()
		else
			ConPrintf("csv missing, cannot rebuild NodeIndexMapping")
		end
	end
end
data.readLUT = function(seed, nodeID, jewelType)
	loadTimelessJewel(jewelType, nodeID)
	if jewelType == 1 then
		assert(next(data.timelessJewelLUTs[jewelType].data), "Error occurred loading Glorious Vanity data")
	else
		assert(data.timelessJewelLUTs[jewelType].data, "Error occurred loading Timeless Jewel data")
	end
	if jewelType == 5 then -- "Elegant Hubris"
		seed = seed / 20
	end
	local seedOffset = (seed - data.timelessJewelSeedMin[jewelType])
	local seedSize = (data.timelessJewelSeedMax[jewelType] - data.timelessJewelSeedMin[jewelType]) + 1
	local index = data.nodeIDList[nodeID] and data.nodeIDList[nodeID].index or nil
	if index then
		if jewelType == 1 then  -- "Glorious Vanity"
			local result = { }

			for i = 1, data.timelessJewelLUTs[jewelType].sizes:byte(index * seedSize + seedOffset + 1) do
				result[i] = data.timelessJewelLUTs[jewelType].data[index + 1][seedOffset + 1]:byte(i)
			end
			return result
		elseif index <= data.nodeIDList["sizeNotable"] then
			return { data.timelessJewelLUTs[jewelType].data:byte(index * seedSize + seedOffset + 1) }
		end
	else
		ConPrintf("ERROR: Missing Index lookup for nodeID: "..nodeID)
	end
	return { }
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
	local baseName = gem.name
	if gem.grantedEffect.support and gem.grantedEffectId ~= "SupportBarrage" then
		baseName = baseName .. " Support"
	end
	data.gemForBaseName[baseName] = gemId
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
data.uniques['race'] = LoadModule("Data/Uniques/Special/race")
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
