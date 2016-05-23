-- Path of Building
--
-- Module: Mod Parser
-- Parser function for modifier names
--

-- List of modifier forms
local formList = {
	["^(%d+)%% increased"] = "INC",
	["^(%d+)%% reduced"] = "RED",
	["^(%d+)%% more"] = "MORE",
	["^(%d+)%% less"] = "LESS",
	["^([%+%-][%d%.]+)%%?"] = "BASE",
	["^([%+%-][%d%.]+)%%? to"] = "BASE",
	["^([%+%-][%d%.]+)%%? base"] = "BASE",
	["^you gain ([%d%.]+)"] = "BASE",
	["^([%+%-]?%d+)%% chance"] = "CHANCE",
	["^([%+%-]?%d+)%% additional chance"] = "CHANCE",
	["^([%d%.]+)%% of"] = "CONV",
	["^gain ([%d%.]+)%% of"] = "CONV",
	["penetrates (%d+)%%"] = "PEN",
	["penetrates (%d+)%% of enemy"] = "PEN",
	["^([%d%.]+)%% of (.+) regenerated per second"] = "REGENPERCENT",
	["^([%d%.]+) (.+) regenerated per second"] = "REGENFLAT",
	["adds (%d+)%-(%d+) (%a+) damage"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to spells"] = "DMGSPELLS",
}

-- Map of modifier names
-- '{suf}' is replaced with modifier suffix ('Base', 'Inc', 'More')
local modNameList = {
	-- Attributes
	["strength"] = "str{suf}",
	["dexterity"] = "dex{suf}",
	["intelligence"] = "int{suf}",
	["strength and dexterity"] = { "str{suf}", "dex{suf}" },
	["strength and intelligence"] = { "str{suf}", "int{suf}" },
	["dexterity and intelligence"] = { "dex{suf}", "int{suf}" },
	["attributes"] = { "str{suf}", "dex{suf}", "int{suf}" },
	["all attributes"] = { "str{suf}", "dex{suf}", "int{suf}" },
	-- Life/mana
	["maximum life"] = "life{suf}",
	["maximum mana"] = "mana{suf}",
	["mana regeneration rate"] = "manaRegen{suf}",
	["mana cost"] = "manaCost{suf}",
	["mana cost of skills"] = "manaCost{suf}",
	["mana reserved"] = "manaReserved{suf}",
	["mana reservation"] = "manaReserved{suf}",
	-- Primary defences
	["maximum energy shield"] = "energyShield{suf}",
	["energy shield recharge rate"] = "energyShieldRecharge{suf}",
	["armour"] = "armour{suf}",
	["evasion rating"] = "evasion{suf}",
	["energy shield"] = "energyShield{suf}",
	["armour and evasion"] = "armourAndEvasion{suf}",
	["armour and evasion rating"] = "armourAndEvasion{suf}",
	["evasion rating and armour"] = "armourAndEvasion{suf}",
	["armour and energy shield"] = "armourAndEnergyShield{suf}",
	["evasion and energy shield"] = "evasionAndEnergyShield{suf}",
	["defences"] = "defences{suf}",
	-- Resistances
	["fire resistance"] = "fireResist",
	["maximum fire resistance"] = "fireResistMax",
	["cold resistance"] = "coldResist",
	["maximum cold resistance"] = "coldResistMax",
	["lightning resistance"] = "lightningResist",
	["maximum lightning resistance"] = "lightningResistMax",
	["fire and cold resistances"] = { "fireResist", "coldResist" },
	["fire and lightning resistances"] = { "fireResist", "lightningResist" },
	["cold and lightning resistances"] = { "coldResist", "lightningResist" },
	["elemental resistances"] = "elementalResist",
	["all elemental resistances"] = "elementalResist",
	["all maximum resistances"] = { "fireResistMax", "coldResistMax", "lightningResistMax", "chaosResistMax" },
	["chaos resistance"] = "chaosResist",
	-- Other defences
	["to dodge attacks"] = "dodgeAttacks",
	["to dodge spells"] = "dodgeSpells",
	["to dodge spell damage"] = "dodgeSpells",
	["to block"] = "blockChance",
	["to block spells"] = "spellBlockChance",
	["maximum block chance"] = "blockChanceMax",
	["to avoid being shocked"] = "avoidShock",
	["to avoid being frozen"] = "avoidFrozen",
	["to avoid being chilled"] = "avoidChilled",
	["to avoid being ignited"] = "avoidIgnite",
	["to avoid elemental status ailments"] = { "avoidShock", "avoidFrozen", "avoidChilled", "avoidIgnite" },
	-- Stun modifiers
	["stun recovery"] = "stunRecovery{suf}",
	["stun threshold"] = "stunThreshold{suf}",
	["block recovery"] = "blockRecovery{suf}",
	["enemy stun threshold"] = "stunEnemyThreshold{suf}",
	["stun duration on enemies"] = "stunEnemyDuration{suf}",
	-- Auras/curses
	["radius of aura skills"] = "auraRadius{suf}",
	["effect of non-curse auras you cast"] = "auraEffect{suf}",
	-- Charges
	["maximum power charge"] = "powerMax",
	["maximum power charges"] = "powerMax",
	["power charge duration"] = "powerDuration{suf}",
	["maximum frenzy charge"] = "frenzyMax",
	["maximum frenzy charges"] = "frenzyMax",
	["frenzy charge duration"] = "frenzyDuration{suf}",
	["maximum endurance charge"] = "enduranceMax",
	["maximum endurance charges"] = "enduranceMax",
	["endurance charge duration"] = "enduranceDuration{suf}",
	["endurance, frenzy and power charge duration"] = { "powerDuration{suf}", "frenzyDuration{suf}", "enduranceDuration{suf}" },
	-- On hit/kill effects
	["life gained on kill"] = "lifeOnKill",
	["mana gained on kill"] = "manaOnKill",
	["life gained for each enemy hit by attacks"] = "attack_lifeOnHit",
	["life gained for each enemy hit by your attacks"] = "attack_lifeOnHit",
	["life gained for each enemy hit by spells"] = "spell_lifeOnHit",
	["life gained for each enemy hit by your spells"] = "spell_lifeOnHit",
	["mana gained for each enemy hit by attacks"] = "attack_manaOnHit",
	["mana gained for each enemy hit by your attacks"] = "attack_manaOnHit",
	["energy shield gained for each enemy hit by attacks"] = "attack_energyShieldOnHit",
	["energy shield gained for each enemy hit by your attacks"] = "attack_energyShieldOnHit",
	["life and mana gained for each enemy hit"] = { "attack_lifeOnHit", "attack_manaOnHit" },
	-- Projectile modifiers
	["pierce chance"] = "pierceChance",
	["of projectiles piercing"] = "pierceChance",
	["of arrows piercing"] = "pierceChance",
	["projectile speed"] = "projectileSpeed{suf}",
	["arrow speed"] = "bow_projectileSpeed{suf}",
	-- Totem/trap/mine modifiers
	["totem placement speed"] = "totemPlacementSpeed{suf}",
	["totem life"] = "totemLife{suf}",
	["totem duration"] = "totemDuration{suf}",
	["trap throwing speed"] = "trapThrowingSpeed{suf}",
	["trap trigger radius"] = "trapTriggerRadius{suf}",
	["trap duration"] = "trapDuration{suf}",
	["cooldown recovery speed for throwing traps"] = "trapCooldownRecovery{suf}",
	["mine laying speed"] = "mineLayingSpeed{suf}",
	["mine detonation radius"] = "mineDetonationRad{suf}",
	["mine duration"] = "mineDuration{suf}",
	-- Other skill modifiers
	["radius"] = "aoeRadius{suf}",
	["radius of area skills"] = "aoeRadius{suf}",
	["duration"] = "duration{suf}",
	["skill effect duration"] = "duration{suf}",
	-- Buffs
	["onslaught effect"] = "onslaughtEffect{suf}",
	["fortify duration"] = "fortifyDuration{suf}",
	["effect of fortify on you"] = "fortifyEffect{suf}",
	-- Basic damage types
	["damage"] = "damage{suf}",
	["physical damage"] = "physical{suf}",
	["lightning damage"] = "lightning{suf}",
	["cold damage"] = "cold{suf}",
	["fire damage"] = "fire{suf}",
	["chaos damage"] = "chaos{suf}",
	["elemental damage"] = "elemental{suf}",
	-- Other damage forms
	["attack damage"] = "attack_damage{suf}",
	["physical attack damage"] = "attack_physical{suf}",
	["physical weapon damage"] = "weapon_physical{suf}",
	["physical melee damage"] = "melee_physical{suf}",
	["melee physical damage"] = "melee_physical{suf}",
	["wand damage"] = "wand_damage{suf}",
	["wand physical damage"] = "wand_physical{suf}",
	["claw physical damage"] = "claw_physical{suf}",
	["damage over time"] = "dot_damage{suf}",
	["physical damage over time"] = "dot_physical{suf}",
	["burning damage"] = "degen_fire{suf}",
	-- Crit/accuracy/speed modifiers
	["critical strike chance"] = "critChance{suf}",
	["critical strike multiplier"] = "critMultiplier",
	["accuracy rating"] = "accuracy{suf}",
	["attack speed"] = "attackSpeed{suf}",
	["cast speed"] = "castSpeed{suf}",
	["attack and cast speed"] = "speed{suf}",
	-- Elemental status ailments
	["to shock"] = "shockChance",
	["shock chance"] = "shockChance",
	["to freeze"] = "freezeChance",
	["freeze chance"] = "freezeChance",
	["to ignite"] = "igniteChance",
	["ignite chance"] = "igniteChance",
	["to freeze, shock and ignite"] = { "freezeChance", "shockChance", "igniteChance" },
	["shock duration on enemies"] = "shock_duration{suf}",
	["freeze duration on enemies"] = "freeze_duration{suf}",
	["chill duration on enemies"] = "chill_duration{suf}",
	["ignite duration on enemies"] = "ignite_duration{suf}",
	["duration of elemental status ailments on enemies"] = { "shock_duration{suf}", "freeze_duration{suf}", "chill_duration{suf}", "ignite_duration{suf}" },
	-- Other debuffs
	["to poison on hit"] = "poisonChance",
	["poison duration"] = "poison_duration{suf}",
	["to cause bleeding"] = "bleedChance",
	["to cause bleeding on hit"] = "bleedChance",
	-- Misc modifiers
	["movement speed"] = "movementSpeed{suf}",
	["light radius"] = "lightRadius{suf}",
	["rarity of items found"] = "lootRarity{suf}",
	["quantity of items found"] = "lootQuantity{suf}",
}

-- List of modifier namespaces
local namespaceList = {
	-- Weapon types
	["with axes"] = "axe_",
	["with bows"] = "bow_",
	["with claws"] = "claw_",
	["with daggers"] = "dagger_",
	["with maces"] = "mace_",
	["with staves"] = "staff_",
	["with swords"] = "sword_",
	["with wands"] = "wand_",
	["unarmed"] = "unarmed_",
	["with one handed weapons"] = "weapon1h_",
	["with one handed melee weapons"] = "weapon1hMelee_",
	["with two handed weapons"] = "weapon2h_",
	["with two handed melee weapons"] = "weapon2hMelee_",
	-- Skill types
	["spell"] = "spell_",
	["for spells"] = "spell_",
	["melee"] = "melee_",
	["with weapons"] = "weapon_",
	["weapon"] = "weapon_",
	["with poison"] = "poison_",
	["with attacks"] = "attack_",
	["projectile"] = "projectile_",
	["area"] = "aoe_",
	["mine"] = "mine_",
	["with mines"] = "mine_",
	["trap"] = "trap_",
	["with traps"] = "trap_",
	["totem"] = "totem_",
	["with totem skills"] = "totem_",
	["with movement skills"] = "movement_",
	["with lightning skills"] = "lightning_",
	["with cold skills"] = "cold_",
	["with fire skills"] = "fire_",
	["with chaos skills"] = "chaos_",
	-- Other
	["global"] = "global_",
	["from equipped shield"] = "Shield_",
}

-- List of namespaces that appear at the start of a line
local preSpaceList = {
	["^minions have "] = "minion_",
	["^minions deal "] = "minion_",
	["^attacks used by totems have "] = "totem_",
	["^spells cast by totems have "] = "totem_",
	["^melee attacks have "] = "melee_",
}

-- List of special namespaces
local specialSpaceList = {
	-- Per charge modifiers
	["per power charge"] = "power_",
	["per frenzy charge"] = "frenzy_",
	["per endurance charge"] = "endurance_",
	-- Equipment conditions
	["while holding a shield"] = "condMod_UsingShield_",
	["with shields"] = "condMod_UsingShield_",
	["while dual wielding"] = "condMod_DualWielding_",
	["while wielding a staff"] = "condMod_UsingStaff_",
	-- Player status conditions
	["when on low life"] = "condMod_LowLife_",
	["while on low life"] = "condMod_LowLife_",
	["when not on low life"] = "condMod_notLowLife_",
	["while not on low life"] = "condMod_notLowLife_",
	["when on full life"] = "condMod_FullLife_",
	["when not on full life"] = "condMod_notFullLife_",
	["while you have fortify"] = "condMod_Fortify_",
	["during onslaught"] = "condMod_Onslaught_",
	["while you have onslaught"] = "condMod_Onslaught_",
	["while phasing"] = "condMod_Phasing_",
	["while using a flask"] = "condMod_UsingFlask_",
	["while on consecrated ground"] = "condMod_OnConsecratedGround_",
	["if you've killed recently"] = "condMod_KilledRecently_",
	["if you haven't killed recently"] = "condMod_notKilledRecently_",
	["if you've attacked recently"] = "condMod_AttackedRecently_",
	["if you've cast a spell recently"] = "condMod_CastSpellRecently_",
	["if you've summoned a totem recently"] = "condMod_SummonedTotemRecently_",
	["if you've used a movement skill recently"] = "condMod_UsedMovementSkillRecently_",
	["if you detonated mines recently"] = "condMod_DetonatedMinesRecently_",
	["if you've crit in the past 8 seconds"] = "condMod_CritInPast8Sec_",
	["if energy shield recharge has started recently"] = "condMod_EnergyShieldRechargeRecently_",
	-- Enemy status conditions
	["against bleeding enemies"] = "condMod_EnemyBleeding_",
	["against poisoned enemies"] = "condMod_EnemyPoisoned_",
	["against burning enemies"] = "condMod_EnemyBurning_",
	["against ignited enemies"] = "condMod_EnemyIgnited_",
	["against shocked enemies"] = "condMod_EnemyShocked_",
	["against frozen enemies"] = "condMod_EnemyFrozen_",
	["enemies which are chilled"] = "condMod_EnemyChilled_",
	["against frozen, shocked or ignited enemies"] = "condMod_EnemyFrozenShockedIgnited_",
	["against enemies that are affected by elemental status ailments"] = "condMod_EnemyElementalStatus_",
	["against enemies that are affected by no elemental status ailments"] = "condMod_notEnemyElementalStatus_",
}

-- List of special modifiers
local specialModList = {
	-- Keystones
	["your hits can't be evaded"] = { cannotBeEvaded = true },
	["never deal critical strikes"] = { noCrit = true },
	["no critical strike multiplier"] = { noCritMult = true },
	["the increase to physical damage from strength applies to projectile attacks as well as melee attacks"] = { ironGrip = true },
	["converts all evasion rating to armour%. dexterity provides no bonus to evasion rating"] = { ironReflexes = true },
	["30%% chance to dodge attacks%. 50%% less armour and energy shield, 30%% less chance to block spells and attacks"] = { dodgeAttacks = 30, armourMore = 0.5, energyShieldMore = 0.5 },
	["maximum life becomes 1, immune to chaos damage"] = { chaosInoculation = true },
	["life regeneration is applied to energy shield instead"] = { zealotsOath = true },
	["life leech applies instantly%. life regeneration has no effect%."] = { vaalPact = true },
	["deal no non%-fire damage"] = { physicalFinalMore = 0, lightningFinalMore = 0, coldFinalMore = 0, chaosFinalMore = 0 },
	-- Ascendancy notables
	["movement skills cost no mana"] = { movement_manaCostMore = 0 },
	["projectiles have 100%% additional chance to pierce targets at the start of their movement, losing this chance as the projectile travels farther"] = { pierceChance = 100 },
	["projectile critical strike chance increased by arrow pierce chance"] = { projectile_critChanceInc = 100 },
	["always poison on hit while using a flask"] = { condMod_UsingFlask_poisonChance = 100 },
	["armour received from body armour is doubled"] = { ["Body Armour_armourMore"] = 2 },
	["gain (%d+)%% of maximum mana as extra maximum energy shield"] = function(num) return { manaGainAsES = num } end,
	["you have fortify"] = { cond_Fortify = true },
	-- Special node types
	["(%d+)%% additional block chance with staves"] = function(num) return { condMod_UsingStaff_blockChance = num } end,
	["(%d+)%% additional block chance with shields"] = function(num) return { condMod_UsingShield_blockChance = num } end,
	["(%d+)%% additional block chance while dual wielding"] = function(num) return { condMod_DualWielding_blockChance = num } end,
	["(%d+)%% faster start of energy shield recharge"] = function(num) return { energyShieldRechargeFaster = num } end,
	["(%d+)%% additional block chance while dual wielding or holding a shield"] = function(num) return { condMod_DualWielding_blockChance = num, condMod_UsingShield_blockChance = num } end,
	-- Other modifiers
	["cannot be shocked"] = { avoidShock = 100 },
	["cannot be frozen"] = { avoidFreeze = 100 },
	["cannot be chilled"] = { avoidChill = 100 },
	["cannot be ignited"] = { avoidIgnite = 100 },
	["cannot be stunned"] = { stunImmunity = true },
	["cannot evade enemy attacks"] = { cannotEvade = true },
	["deal no physical damage"] = { physicalFinalMore = 0 },
	["your critical strikes do not deal extra damage"] = { noCritMult = true },
	["iron will"] = { ironWill = true },
	["zealot's oath"] = { zealotsOath = true },
	["pain attunement"] = { condMod_LowLife_spell_damageMore = 1.3 },
	-- Special item local modifiers
	["no physical damage"] = { weaponNoPhysical = true },
	["all attacks with this weapon are critical strikes"] = { weaponAlwaysCrit = true },
	["hits can't be evaded"] = { weaponX_cannotBeEvaded = true },
	["no block chance"] = { shieldNoBlock = true },
	["causes bleeding on hit"] = { bleedChance = 100 },
	["poisonous hit"] = { poisonChance = 100 },
	["your chaos damage poisons enemies"] = { poisonChance = 100 },
	["has no sockets"] = { },
	["has 1 socket"] = { },
	["socketed gems have (.+)"] = { },
	["socketed gems are supported by (.+)"] = { },
	["+(%d) to level of socketed gems"] = { },
	["+(%d) to level of socketed (%a+) gems"] = { },
	["grants level (%d+) (.+) skill"] = { },
	-- Unique item modifiers
	["projectile damage increased by arrow pierce chance"] = { drillneck = true },
}

-- Special lookups used for various modifier forms
local convTypes = {
	["as extra lightning damage"] = "GainAslightning",
	["added as lightning damage"] = "GainAslightning",
	["as extra cold damage"] = "GainAscold",
	["added as cold damage"] = "GainAscold",
	["as extra fire damage"] = "GainAsfire",
	["added as fire damage"] = "GainAsfire",
	["as extra chaos damage"] = "GainAschaos",
	["added as chaos damage"] = "GainAschaos",
	["converted to lightning damage"] = "ConvertTolightning",
	["converted to cold damage"] = "ConvertTocold",
	["converted to fire damage"] = "ConvertTofire",
	["converted to chaos damage"] = "ConvertTochaos",
}
local penTypes = {
	["lightning resistance"] = "lightningPen",
	["cold resistance"] = "coldPen",
	["fire resistance"] = "firePen",
	["elemental resistance"] = "elementalPen",
	["elemental resistances"] = "elementalPen",
}
local regenTypes = {
	["life"] = "lifeRegen{suf}",
	["maximum life"] = "lifeRegen{suf}",
	["mana"] = "manaRegen{suf}",
	["energy shield"] = "energyShieldRegen{suf}",
}

-- Build active skill name lookup
local skillNameList = { }
for skillName, data in pairs(data.gems) do
	if not data.support then
		skillNameList[skillName:lower()] = "skill:" .. skillName .. "_"
	end
end

local function getSimpleConv(src, dst, factor)
	return function(mods, allMods, data)
		if mods and mods[src] then 
			modLib.listMerge(allMods, dst, mods[src] * factor)
			mods[src] = nil
		end
	end
end
local function getMatchConv(others, dst)
	return function(mods, allMods, data)
		if mods then
			for k, v in pairs(mods) do
				for _, other in pairs(others) do
					if k:match(other) then
						modLib.listMerge(allMods, k:gsub(other, dst), v)
						mods[k] = nil
					end
				end
			end			
		end
	end
end
local function getPerStat(dst, stat, factor)
	return function(mods, allMods, data)
		if mods then
			data[stat] = (data[stat] or 0) + (mods[stat] or 0)
		else
			modLib.listMerge(allMods, dst, math.floor(data[stat] * factor + 0.5))
		end
	end
end
-- List of radius jewel functions
local jewelFuncs = {
	["Strength from Passives in Radius is Transformed to Dexterity"] = getSimpleConv("strBase", "dexBase", 1),
	["Dexterity from Passives in Radius is Transformed to Strength"] = getSimpleConv("dexBase", "strBase", 1),
	["Strength from Passives in Radius is Transformed to Intelligence"] = getSimpleConv("strBase", "intBase", 1),
	["Intelligence from Passives in Radius is Transformed to Strength"] = getSimpleConv("intBase", "strBase", 1),
	["Dexterity from Passives in Radius is Transformed to Intelligence"] = getSimpleConv("dexBase", "intBase", 1),
	["Intelligence from Passives in Radius is Transformed to Dexterity"] = getSimpleConv("intBase", "dexBase", 1),
	["Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield"] = getSimpleConv("lifeInc", "energyShieldInc", 1),
	["Increases and Reductions to Energy Shield in Radius are Transformed to apply to Armour at 200% of their value"] = getSimpleConv("energyShieldInc", "armourInc", 2),
	["Increases and Reductions to Life in Radius are Transformted to apply to Mana at 200% of their value"] = getSimpleConv("lifeInc", "manaInc", 2),
	["Increases and Reductions to Physical Damage in Radius are transformed to apply to Cold Damage"] = getMatchConv({"physicalInc"}, "coldInc"),
	["Increases and Reductions to Cold Damage in Radius are transformed to apply to Physical Damage"] = getMatchConv({"coldInc"}, "physicalInc"),
	["Increases and Reductions to other Damage Types in Radius are Transformed to apply to Fire Damage"] = getMatchConv({"physicalInc","coldInc","lightningInc","chaosInc"}, "fireInc"),
	["Melee and Melee Weapon Type Modifiers in Radius are Transformed to Bow Modifiers"] = getMatchConv({"melee_","axe_","claw_","dagger_","mace_","staff_","sword_"}, "bow_"),
	["Adds 1 to maximum Life per 3 Intelligence in Radius"] = getPerStat("lifeBase", "intBase", 1 / 3),
	["1% increased Evasion Rating per 3 Dexterity Allocated in Radius"] = getPerStat("evasionInc", "dexBase", 1 / 3),
	["1% increased Claw Physical Damage per 3 Dexterity Allocated in Radius"] = getPerStat("claw_physicalInc", "dexBase", 1 / 3),
	["1% increased Melee Physical Damage while Unarmed per 3 Dexterity Allocated in Radius"] = getPerStat("unarmed_physicalInc", "dexBase", 1 / 3),
	["3% increased Totem Life per 10 Strength in Radius"] = getPerStat("totemLifeInc", "strBase", 3 / 10),
	["Adds 1 maximum Lightning Damage to Attacks per 1 Dexterity Allocated in Radius"] = getPerStat("attack_lightningMax", "dexBase", 1),
	["5% increased Chaos damage per 10 Intelligence from Allocated Passives in Radius"] = getPerStat("chaosInc", "intBase", 5 / 10),
	["Dexterity and Intelligence from passives in Radius count towards Strength Melee Damage bonus"] = function(mods, allMods, data)
		if mods then
			data.dexBase = (data.dexBase or 0) + (mods.dexBase or 0)
			data.intBase = (data.intBase or 0) + (mods.intBase or 0)
		else
			modLib.listMerge(allMods, "dexIntToMeleeBonus", data.dexBase + data.intBase)
		end
	end,
}

-- Scan a line for the earliest and longest match from the pattern list
-- If a match is found, returns the corresponding value from the pattern list, plus the remainder of the line and a table of captures
local function scan(line, patternList, plain)
	local bestIndex, bestEndIndex
	local bestMatch = { nil, line, nil }
	for pattern, patternVal in pairs(patternList) do
		local index, endIndex, cap1, cap2, cap3, cap4, cap5 = line:lower():find(pattern, 1, plain)
		if index and (not bestIndex or index < bestIndex or (index == bestIndex and endIndex > bestEndIndex)) then
			bestIndex = index
			bestEndIndex = endIndex
			bestMatch = { patternVal, line:sub(1, index - 1)..line:sub(endIndex + 1, -1), { cap1, cap2, cap3, cap4, cap5 } }
		end
	end
	return bestMatch[1], bestMatch[2], bestMatch[3]
end

return function(line)
	-- Check if this is a special modifier
	local specialMod, specialLine, cap = scan(line, specialModList)
	if specialMod and #specialLine == 0 then
		if type(specialMod) == "function" then
			return specialMod(tonumber(cap[1]), unpack(cap))
		else
			return copyTable(specialMod)
		end
	end
	if jewelFuncs[line] then
		return { jewelFunc = jewelFuncs[line] }
	end

	-- Check for a namespace at the start of the line
	local space
	space, line = scan(line, preSpaceList)

	-- Scan for modifier form
	local modForm, formCap
	modForm, line, formCap = scan(line, formList)
	if not modForm then
		return
	end
	local num = tonumber(formCap[1])

	-- Check for special namespaces (per-charge, conditionals)
	local specialSpace
	specialSpace, line = scan(line, specialSpaceList, true)
	
	-- Scan for modifier name
	local modName
	modName, line = scan(line, modNameList, true)

	-- Scan for skill name
	local skillSpace
	skillSpace, line = scan(line, skillNameList, true)

	-- Scan for namespace if one hasn't been found already
	if not space then
		space, line = scan(line, namespaceList, true)
	end

	-- Find modifier value and suffix according to form
	local val, suffix
	if modForm == "INC" then
		val = num
		suffix = "Inc"
	elseif modForm == "RED" then
		val = -num
		suffix = "Inc"
	elseif modForm == "MORE" then
		val = 1 + num / 100
		suffix = "More"
	elseif modForm == "LESS" then
		val = 1 - num / 100
		suffix = "More"
	elseif modForm == "BASE" then
		val = num
		suffix = "Base"
	elseif modForm == "CHANCE" then
		val = num
	elseif modForm == "CONV" then
		val = num
		suffix, line = scan(line, convTypes, true)
		if not suffix then
			return { }, line
		end
	elseif modForm == "PEN" then
		val = num
		modName, line = scan(line, penTypes, true)
		if not modName then
			return { }, line
		end
	elseif modForm == "REGENPERCENT" then
		val = num
		suffix = "Percent"
		modName = regenTypes[formCap[2]]
		if not modName then
			return { }, line
		end
	elseif modForm == "REGENFLAT" then
		val = num
		suffix = "Base"
		modName = regenTypes[formCap[2]]
		if not modName then
			return { }, line
		end
	elseif modForm == "DMGATTACKS" then
		val = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { formCap[3].."Min", formCap[3].."Max" }
		space = space or "attack_"
	elseif modForm == "DMGSPELLS" then
		val = { tonumber(formCap[1]), tonumber(formCap[2]) }		
		modName = { formCap[3].."Min", formCap[3].."Max" }
		space = "spell_"
	end

	-- Generate modifier list
	local nameList = modName or ""
	local modList = { }
	for i, name in ipairs(type(nameList) == "table" and nameList or { nameList }) do
		modList[(skillSpace or "") .. (specialSpace or "") .. (space or "") .. name:gsub("{suf}", suffix or "")] = type(val) == "table" and val[i] or val
	end
	return modList, line:match("%S") and line
end