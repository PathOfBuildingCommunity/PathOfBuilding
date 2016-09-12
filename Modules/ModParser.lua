-- Path of Building
--
-- Module: Mod Parser
-- Parser function for modifier names
--

-- List of modifier forms
local formList = {
	["^(%d+)%% increased"] = "INC",
	["^(%d+)%% faster"] = "INC",
	["^(%d+)%% reduced"] = "RED",
	["^(%d+)%% slower"] = "RED",
	["^(%d+)%% more"] = "MORE",
	["^(%d+)%% less"] = "LESS",
	["^([%+%-][%d%.]+)%%?"] = "BASE",
	["^([%+%-][%d%.]+)%%? to"] = "BASE",
	["^([%+%-][%d%.]+)%%? base"] = "BASE",
	["^([%+%-]?[%d%.]+)%% additional"] = "BASE",
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
	["adds (%d+) to (%d+) (%a+) damage"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) damage to spells"] = "DMGSPELLS",
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
	["energy shield recovery rate"] = "energyShieldRecovery{suf}",
	["start of energy shield recharge"] = "energyShieldRechargeFaster",
	["armour"] = "armour{suf}",
	["evasion rating"] = "evasion{suf}",
	["energy shield"] = "energyShield{suf}",
	["armour and evasion"] = "armourAndEvasion{suf}",
	["armour and evasion rating"] = "armourAndEvasion{suf}",
	["evasion rating and armour"] = "armourAndEvasion{suf}",
	["armour and energy shield"] = "armourAndEnergyShield{suf}",
	["evasion and energy shield"] = "evasionAndEnergyShield{suf}",
	["armour, evasion and energy shield"] = "defences{suf}",
	["defences"] = "defences{suf}",
	-- Resistances
	["fire resistance"] = "fireResist",
	["maximum fire resistance"] = "fireResistMax",
	["cold resistance"] = "coldResist",
	["maximum cold resistance"] = "coldResistMax",
	["lightning resistance"] = "lightningResist",
	["maximum lightning resistance"] = "lightningResistMax",
	["chaos resistance"] = "chaosResist",
	["fire and cold resistances"] = { "fireResist", "coldResist" },
	["fire and lightning resistances"] = { "fireResist", "lightningResist" },
	["cold and lightning resistances"] = { "coldResist", "lightningResist" },
	["elemental resistances"] = "elementalResist",
	["all elemental resistances"] = "elementalResist",
	["all maximum resistances"] = { "fireResistMax", "coldResistMax", "lightningResistMax", "chaosResistMax" },
	-- Other defences
	["to dodge attacks"] = "dodgeAttacks",
	["to dodge spells"] = "dodgeSpells",
	["to dodge spell damage"] = "dodgeSpells",
	["to block"] = "blockChance",
	["block chance"] = "blockChance",
	["to block spells"] = "spellBlockChance",
	["chance to block attacks and spells"] = { "blockChance{suf}", "spellBlockChance{suf}" },
	["maximum block chance"] = "blockChanceMax",
	["to avoid being stunned"] = "avoidStun",
	["to avoid being shocked"] = "avoidShock",
	["to avoid being frozen"] = "avoidFrozen",
	["to avoid being chilled"] = "avoidChilled",
	["to avoid being ignited"] = "avoidIgnite",
	["to avoid elemental status ailments"] = { "avoidShock", "avoidFrozen", "avoidChilled", "avoidIgnite" },
	-- Stun modifiers
	["stun recovery"] = "stunRecovery{suf}",
	["stun and block recovery"] = "stunRecovery{suf}",
	["stun threshold"] = "stunThreshold{suf}",
	["block recovery"] = "blockRecovery{suf}",
	["enemy stun threshold"] = "stunEnemyThreshold{suf}",
	["stun duration on enemies"] = "stunEnemyDuration{suf}",
	-- Auras/curses
	["effect of non-curse auras you cast"] = "auraEffect{suf}",
	["effect of your curses"] = "curseEffect{suf}",
	["curse effect"] = "curseEffect{suf}",
	["curse duration"] = "curse_duration{suf}",
	["radius of auras"] = "aura_aoeRadius{suf}",
	["radius of curses"] = "curse_aoeRadius{suf}",
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
	["of arrows piercing"] = "bow_pierceChance",
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
	["mine detonation radius"] = "mineDetonationRadius{suf}",
	["mine duration"] = "mineDuration{suf}",
	-- Other skill modifiers
	["radius"] = "aoeRadius{suf}",
	["radius of area skills"] = "aoeRadius{suf}",
	["area of effect"] = "aoeRadius{suf}",
	["duration"] = "duration{suf}",
	["skill effect duration"] = "duration{suf}",
	["chaos skill effect duration"] = "chaos_duration{suf}",
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
	["burning damage"] = "dot_fire{suf}",
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
	["to poison"] = "poisonChance",
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
	["with ranged weapons"] = "weaponRanged_",
	-- Skill types
	["spell"] = "spell_",
	["for spells"] = "spell_",
	["with attacks"] = "attack_",
	["for attacks"] = "attack_",
	["weapon"] = "weapon_",
	["with weapons"] = "weapon_",
	["melee"] = "melee_",
	["with melee attacks"] = "melee_",
	["on melee hit"] = "melee_",
	["with poison"] = "poison_",
	["projectile"] = "projectile_",
	["area"] = "aoe_",
	["mine"] = "mine_",
	["with mines"] = "mine_",
	["trap"] = "trap_",
	["with traps"] = "trap_",
	["totem"] = "totem_",
	["with totem skills"] = "totem_",
	["of aura skills"] = "aura_",
	["of curse skills"] = "curse_",
	["for curses"] = "curse_",
	["warcry"] = "warcry_",
	["vaal"] = "vaal_",
	["vaal skill"] = "vaal_",
	["with movement skills"] = "movementSkills_",
	["with lightning skills"] = "lightningSkills_",
	["with cold skills"] = "coldSkills_",
	["with fire skills"] = "fireSkills_",
	["with elemental skills"] = "elementalSkills_",
	["with chaos skills"] = "chaosSkills_",
	-- Other
	["global"] = "global_",
	["from equipped shield"] = "slot:Shield_",
}

-- List of namespaces that appear at the start of a line
local preSpaceList = {
	["^minions have "] = "minion_",
	["^minions deal "] = "minion_",
	["^attacks used by totems have "] = "totem_",
	["^spells cast by totems have "] = "totem_",
	["^attacks have "] = "attack_",
	["^melee attacks have "] = "melee_",
	["^left ring slot: "] = "IfSlot:1_",
	["^right ring slot: "] = "IfSlot:2_",
	["^socketed gems have "] = "SocketedIn:X_",
	["^socketed curse gems have "] = "SocketedIn:X_curse_",
}

-- List of special namespaces
local specialSpaceList = {
	-- Per charge modifiers
	["per power charge"] = "PerPower_",
	["per frenzy charge"] = "PerFrenzy_",
	["per endurance charge"] = "PerEndurance_",
	-- Slot conditions
	["in main hand"] = "IfSlot:1_",
	["when in main hand"] = "IfSlot:1_",
	["in off hand"] = "IfSlot:2_",
	["when in off hand"] = "IfSlot:2_",
	-- Equipment conditions
	["while holding a shield"] = "CondMod_UsingShield_",
	["with shields"] = "CondMod_UsingShield_",
	["while dual wielding"] = "CondMod_DualWielding_",
	["while wielding a staff"] = "CondMod_UsingStaff_",
	["while unarmed"] = "CondMod_Unarmed_",
	["with a normal item equipped"] = "CondMod_UsingNormalItem_",
	["with a magic item equipped"] = "CondMod_UsingMagicItem_",
	["with a rare item equipped"] = "CondMod_UsingRareItem_",
	["with a unique item equipped"] = "CondMod_UsingUniqueItem_",
	["for each normal item you have equipped"] = "PerNormal_",
	["for each magic item you have equipped"] = "PerMagic_",
	["for each rare item you have equipped"] = "PerRare_",
	["for each unique item you have equipped"] = "PerUnique_",
	-- Player status conditions
	["when on low life"] = "CondMod_LowLife_",
	["while on low life"] = "CondMod_LowLife_",
	["when not on low life"] = "CondMod_notLowLife_",
	["while not on low life"] = "CondMod_notLowLife_",
	["when on full life"] = "CondMod_FullLife_",
	["when not on full life"] = "CondMod_notFullLife_",
	["while no mana is reserved"] = "CondMod_NoManaReserved_",
	["while you have fortify"] = "CondMod_Fortify_",
	["during onslaught"] = "CondMod_Onslaught_",
	["while you have onslaught"] = "CondMod_Onslaught_",
	["while phasing"] = "CondMod_Phasing_",
	["while using a flask"] = "CondMod_UsingFlask_",
	["during flask effect"] = "CondMod_UsingFlask_",
	["while on consecrated ground"] = "CondMod_OnConsecratedGround_",
	["if you've killed recently"] = "CondMod_KilledRecently_",
	["if you haven't killed recently"] = "CondMod_notKilledRecently_",
	["if you've attacked recently"] = "CondMod_AttackedRecently_",
	["if you've cast a spell recently"] = "CondMod_CastSpellRecently_",
	["if you've summoned a totem recently"] = "CondMod_SummonedTotemRecently_",
	["if you've used a movement skill recently"] = "CondMod_UsedMovementSkillRecently_",
	["if you detonated mines recently"] = "CondMod_DetonatedMinesRecently_",
	["if you've crit in the past 8 seconds"] = "CondMod_CritInPast8Sec_",
	["if energy shield recharge has started recently"] = "CondMod_EnergyShieldRechargeRecently_",
	-- Enemy status conditions
	["against bleeding enemies"] = "CondMod_EnemyBleeding_",
	["against poisoned enemies"] = "CondMod_EnemyPoisoned_",
	["against burning enemies"] = "CondMod_EnemyBurning_",
	["against ignited enemies"] = "CondMod_EnemyIgnited_",
	["against shocked enemies"] = "CondMod_EnemyShocked_",
	["against frozen enemies"] = "CondMod_EnemyFrozen_",
	["against chilled enemies"] = "CondMod_EnemyChilled_",
	["enemies which are chilled"] = "CondMod_EnemyChilled_",
	["against frozen, shocked or ignited enemies"] = "CondMod_EnemyFrozenShockedIgnited_",
	["against enemies that are affected by elemental status ailments"] = "CondMod_EnemyElementalStatus_",
	["against enemies that are affected by no elemental status ailments"] = "CondMod_notEnemyElementalStatus_",
}

-- List of special modifiers
local specialModList = {
	-- Keystones
	["your hits can't be evaded"] = { cannotBeEvaded = true },
	["never deal critical strikes"] = { neverCrit = true },
	["no critical strike multiplier"] = { noCritMult = true },
	["the increase to physical damage from strength applies to projectile attacks as well as melee attacks"] = { ironGrip = true },
	["converts all evasion rating to armour%. dexterity provides no bonus to evasion rating"] = { ironReflexes = true },
	["30%% chance to dodge attacks%. 50%% less armour and energy shield, 30%% less chance to block spells and attacks"] = { dodgeAttacks = 30, armourMore = 0.5, energyShieldMore = 0.5, blockChanceMore = 0.7, spellBlockChanceMore = 0.7 },
	["maximum life becomes 1, immune to chaos damage"] = { chaosInoculation = true },
	["life regeneration is applied to energy shield instead"] = { zealotsOath = true },
	["life leech applies instantly%. life regeneration has no effect%."] = { vaalPact = true, noLifeRegen = true },
	["deal no non%-fire damage"] = { dealNophysical = true, dealNolightning = true, dealNocold = true, dealNochaos = true },
	["removes all mana%. spend life instead of mana for skills"] = { manaMore = 0, bloodMagic = true },
	-- Ascendancy notables
	["movement skills cost no mana"] = { movementSkills_manaCostMore = 0 },
	["projectiles have 100%% additional chance to pierce targets at the start of their movement, losing this chance as the projectile travels farther"] = { pierceChance = 100 },
	["projectile critical strike chance increased by arrow pierce chance"] = { projectile_critChanceInc = 100 },
	["always poison on hit while using a flask"] = { CondMod_UsingFlask_poisonChance = 100 },
	["armour received from body armour is doubled"] = { unbreakable = true },
	["gain (%d+)%% of maximum mana as extra maximum energy shield"] = function(num) return { manaGainAsEnergyShield = num } end,
	["you have fortify"] = { Cond_Fortify = true },
	["nearby enemies have (%-%d+)%% to chaos resistance"] = function(num) return { effective_chaosResist = num } end,
	["(%d+)%% increased damage of each damage type for which you have a matching golem"] = function(num) return { CondMod_HavePhysicalGolem_physicalInc = num, CondMod_HaveLightningGolem_lightningInc = num, CondMod_HaveColdGolem_coldInc = num, CondMod_HaveFireGolem_fireInc = num, CondMod_HaveChaosGolem_chaosInc = num } end,
	["100%% increased effect of buffs granted by your elemental golems"] = { Cond_LiegeOfThePrimordial = true },
	["enemies you curse take (%d+)%% increased damage"] = function(num) return { CondMod_EnemyCursed_effective_damageTakenInc = num } end,
	["grants armour equal to (%d+)%% of your reserved life to you and nearby allies"] = function(num) return { armourFromReservedLife = num } end,
	["grants maximum energy shield equal to (%d+)%% of your reserved mana to you and nearby allies"] = function(num) return { energyShieldFromReservedMana = num } end,
	["you and nearby allies deal (%d+)%% increased damage"] = function(num) return { damageInc = num } end,
	["you and nearby allies have (%d+)%% increased movement speed"] = function(num) return {  movementSpeedInc = num } end,
	["skills from your helmet penetrate (%d+)%% elemental resistances"] = function(num) return { ["SocketedIn:Helmet_elementalPen"] = num } end,
	["skills from your gloves have (%d+)%% increased area of effect"] = function(num) return { ["SocketedIn:Gloves_aoeRadiusInc"] = num } end,
	-- Special node types
	["(%d+)%% of block chance applied to spells"] = function(num) return { blockChanceConv = num } end,
	["(%d+)%% additional block chance with staves"] = function(num) return { CondMod_UsingStaff_blockChance = num } end,
	["(%d+)%% additional block chance while dual wielding or holding a shield"] = function(num) return { CondMod_DualWielding_blockChance = num, CondMod_UsingShield_blockChance = num } end,
	["can have up to (%d+) additional trap placed at a time"] = function(num) return { activeTrapLimit = num } end,
	["can have up to (%d+) additional remote mine placed at a time"] = function(num) return { activeMineLimit = num } end,
	-- Other modifiers
	["cannot be stunned"] = { avoidStun = 100 },
	["cannot be shocked"] = { avoidShock = 100 },
	["cannot be frozen"] = { avoidFreeze = 100 },
	["cannot be chilled"] = { avoidChill = 100 },
	["cannot be ignited"] = { avoidIgnite = 100 },
	["cannot evade enemy attacks"] = { cannotEvade = true },
	["deal no physical damage"] = { dealNophysical = true },
	["deal no elemental damage"] = { dealNolightning = true, dealNocold = true, dealNofire = true },
	["your critical strikes do not deal extra damage"] = { noCritMult = true },
	["iron will"] = { ironWill = true },
	["adds an additional arrow"] = { attack_projectileCount = 1 },
	["(%d+) additional arrows"] = function(num) return { attack_projectileCount = num } end,
	["skills fire an additional projectile"] = { projectileCount = 1 },
	["spells have an additional projectile"] = { spell_projectileCount = 1 },
	["skills chain %+(%d) times"] = function(num) return { chainCount = num } end,
	["reflects (%d+) physical damage to melee attackers"] = { },
	-- Special item local modifiers
	["no physical damage"] = { weaponLocal_noPhysical = true },
	["all attacks with this weapon are critical strikes"] = { weaponLocal_alwaysCrit = true },
	["hits can't be evaded"] = { weaponX_cannotBeEvaded = true },
	["no block chance"] = { shieldLocal_noBlock = true },
	["causes bleeding on hit"] = { bleedChance = 100 },
	["poisonous hit"] = { poisonChance = 100 },
	["has no sockets"] = { },
	["has 1 socket"] = { },
	["%+(%d+) to level of socketed gems"] = function(num) return { ["SocketedIn:X_gemLevel_all"] = num } end,
	["%+(%d+) to level of socketed (%a+) gems"] = function(num, _, type) return { ["SocketedIn:X_gemLevel_"..type] = num } end,
	["%+(%d+)%% to quality of socketed (%a+) gems"] = function(num, _, type) return { ["SocketedIn:X_gemQuality_"..type] = num } end,
	["%+(%d+) to level of active socketed skill gems"] = function(num) return { ["SocketedIn:X_gemLevel_active"] = num } end,
	["socketed gems fire an additional projectile"] = { ["SocketedIn:X_projectileCount"] = 1 },
	["socketed gems fire (%d+) additional projectiles"] = function(num) return { ["SocketedIn:X_projectileCount"] = num } end,
	["socketed gems reserve no mana"] = { ["SocketedIn:X_manaReservedMore"] = 0 },
	["socketed gems have blood magic"]  = { ["SocketedIn:X_bloodMagic"] = true },
	-- Unique item modifiers
	["your cold damage can ignite"] = { coldCanIgnite = true },
	["your fire damage can shock but not ignite"] = { fireCanShock = true, fireCannotIgnite = true },
	["your cold damage can ignite but not freeze or chill"] = { coldCanIgnite = true, coldCannotFreeze = true, coldCannotChill = true },
	["your lightning damage can freeze but not shock"] = { lightningCanFreeze = true, lightningCannotShock = true },
	["your chaos damage can shock"] = { chaosCanShock = true },
	["your physical damage can chill"] = { physicalCanChill = true },
	["your physical damage can shock"] = { physicalCanShock = true },
	["your chaos damage poisons enemies"] = { poisonChance = 100 },
	["melee attacks cause bleeding"] = { melee_bleedChance = 100 },
	["melee attacks poison on hit"] = { melee_poisonChance = 100 },	
	["traps and mines deal (%d+)%-(%d+) additional physical damage"] = function(_, min, max) return { trap_physicalMin = tonumber(min), trap_physicalMax = tonumber(max), mine_physicalMin = tonumber(min), mine_physicalMax = tonumber(max) } end,
	["traps and mines deal (%d+) to (%d+) additional physical damage"] = function(_, min, max) return { trap_physicalMin = tonumber(min), trap_physicalMax = tonumber(max), mine_physicalMin = tonumber(min), mine_physicalMax = tonumber(max) } end,
	["traps and mines have a (%d+)%% chance to poison on hit"] = function(num) return { trap_poisonChance = num, mine_poisonChance = num } end,
	["poison cursed enemies on hit"] = { CondMod_EnemyCursed_poisonChance = 100 },
	["projectile damage increased by arrow pierce chance"] = { drillneck = true },
	["gain (%d+) armour per grand spectrum"] = function(num) return { PerGrandSpectrum_armourBase = num, gear_GrandSpectrumCount = 1 } end,
	["gain (%d+) mana per grand spectrum"] = function(num) return { PerGrandSpectrum_manaBase = num, gear_GrandSpectrumCount = 1 } end,
	["(%d+)%% increased elemental damage per grand spectrum"] = function(num) return { PerGrandSpectrum_elementalInc = num, gear_GrandSpectrumCount = 1 } end,
	["counts as dual wielding"] = { Cond_DualWielding = true },
	["counts as all one handed melee weapon types"] = { weaponX_varunastra = true },
	["gain (%d+)%% of bow physical damage as extra damage of each element"] = function(num) return { bow_physicalGainAslightning = num, bow_physicalGainAscold = num, bow_physicalGainAsfire = num } end,
	["totems fire (%d+) additional projectiles"] = function(num) return { totem_projectileCount = num } end,
	["you have no life regeneration"] = { noLifeRegen = true },
	["cannot block attacks"] = { cannotBlockAttacks = true },
	["projectiles pierce while phasing"] = { CondMod_Phasing_pierceChance = 100 },
	["reserves (%d+)%% of life"] = function(num) return { reserved_lifePercent = num } end,
}
local keystoneList = {
	-- List of keystones that can be found on uniques
	"Zealot's Oath",
	"Pain Attunement",
	"Blood Magic",
	"Unwavering Stance",
	"Ghost Reaver",
	"Conduit",
	"Mind Over Matter",
	"Acrobatics",
}
for _, name in pairs(keystoneList) do
	specialModList[name:lower()] = { ["gear_keystone:"..name] = true }
end

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
		skillNameList[" "..skillName:lower().." "] = "Skill:" .. skillName .. "_"
	end
end

local function getSimpleConv(src, dst, factor)
	return function(nodeMods, out, data)
		if nodeMods and nodeMods[src] then 
			modLib.listMerge(out, dst, nodeMods[src] * factor)
			modLib.listUnmerge(out, src, nodeMods[src])
		end
	end
end
local function getMatchConv(others, dst)
	return function(nodeMods, out, data)
		if nodeMods then
			for k, v in pairs(nodeMods) do
				for _, other in pairs(others) do
					if k:match(other) then
						modLib.listMerge(out, k:gsub(other, dst), v)
						modLib.listUnmerge(out, k, v)
					end
				end
			end
		end
	end
end
local function getPerStat(dst, stat, factor)
	return function(nodeMods, out, data)
		if nodeMods then
			data[stat] = (data[stat] or 0) + (nodeMods[stat] or 0)
		else
			modLib.listMerge(out, dst, math.floor(data[stat] * factor + 0.5))
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
	["Increases and Reductions to Life in Radius are Transformed to apply to Mana at 200% of their value"] = getSimpleConv("lifeInc", "manaInc", 2),
	["Increases and Reductions to Physical Damage in Radius are Transformed to apply to Cold Damage"] = getMatchConv({"physicalInc"}, "coldInc"),
	["Increases and Reductions to Cold Damage in Radius are Transformed to apply to Physical Damage"] = getMatchConv({"coldInc"}, "physicalInc"),
	["Increases and Reductions to other Damage Types in Radius are Transformed to apply to Fire Damage"] = getMatchConv({"physicalInc","coldInc","lightningInc","chaosInc"}, "fireInc"),
	["Melee and Melee Weapon Type Modifiers in Radius are Transformed to Bow Modifiers"] = getMatchConv({"melee_","weapon1hMelee_","weapon2hMelee_","axe_","claw_","dagger_","mace_","staff_","sword_"}, "bow_"),
	["Adds 1 to maximum Life per 3 Intelligence in Radius"] = getPerStat("lifeBase", "intBase", 1 / 3),
	["1% increased Evasion Rating per 3 Dexterity Allocated in Radius"] = getPerStat("evasionInc", "dexBase", 1 / 3),
	["1% increased Claw Physical Damage per 3 Dexterity Allocated in Radius"] = getPerStat("claw_physicalInc", "dexBase", 1 / 3),
	["1% increased Melee Physical Damage while Unarmed per 3 Dexterity Allocated in Radius"] = getPerStat("unarmed_physicalInc", "dexBase", 1 / 3),
	["3% increased Totem Life per 10 Strength in Radius"] = getPerStat("totemLifeInc", "strBase", 3 / 10),
	["Adds 1 maximum Lightning Damage to Attacks per 1 Dexterity Allocated in Radius"] = getPerStat("attack_lightningMax", "dexBase", 1),
	["5% increased Chaos damage per 10 Intelligence from Allocated Passives in Radius"] = getPerStat("chaosInc", "intBase", 5 / 10),
	["Dexterity and Intelligence from passives in Radius count towards Strength Melee Damage bonus"] = function(nodeMods, out, data)
		if nodeMods then
			data.dexBase = (data.dexBase or 0) + (nodeMods.dexBase or 0)
			data.intBase = (data.intBase or 0) + (nodeMods.intBase or 0)
		else
			modLib.listMerge(out, "dexIntToMeleeBonus", data.dexBase + data.intBase)
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