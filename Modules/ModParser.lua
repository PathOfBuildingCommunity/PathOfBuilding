-- Path of Building
--
-- Module: Mod Parser
-- Parser function for modifier names
--

local t_insert = table.insert
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot

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
	["penetrates (%d+)%% of"] = "PEN",
	["penetrates (%d+)%% of enemy"] = "PEN",
	["^([%d%.]+)%% of (.+) regenerated per second"] = "REGENPERCENT",
	["^([%d%.]+) (.+) regenerated per second"] = "REGENFLAT",
	["^regenerate ([%d%.]+) (.+) per second"] = "REGENFLAT",
	["(%d+) to (%d+) additional (%a+) damage"] = "DMG",
	["adds (%d+)%-(%d+) (%a+) damage"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) damage"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) damage to spells"] = "DMGSPELLS",
}

-- Map of modifier names
local modNameList = {
	-- Attributes
	["strength"] = "Str",
	["dexterity"] = "Dex",
	["intelligence"] = "Int",
	["strength and dexterity"] = { "Str", "Dex" },
	["strength and intelligence"] = { "Str", "Int" },
	["dexterity and intelligence"] = { "Dex", "Int" },
	["attributes"] = { "Str", "Dex", "Int" },
	["all attributes"] = { "Str", "Dex", "Int" },
	-- Life/mana
	["life"] = "Life",
	["maximum life"] = "Life",
	["mana"] = "Mana",
	["maximum mana"] = "Mana",
	["mana regeneration rate"] = "ManaRegen",
	["mana cost"] = "ManaCost",
	["mana cost of skills"] = "ManaCost",
	["mana reserved"] = "ManaReserved",
	["mana reservation"] = "ManaReserved",
	-- Primary defences
	["maximum energy shield"] = "EnergyShield",
	["energy shield recharge rate"] = "EnergyShieldRecharge",
	["energy shield recovery rate"] = "EnergyShieldRecovery",
	["start of energy shield recharge"] = "EnergyShieldRechargeFaster",
	["armour"] = "Armour",
	["evasion"] = "Evasion",
	["evasion rating"] = "Evasion",
	["energy shield"] = "EnergyShield",
	["armour and evasion"] = "ArmourAndEvasion",
	["armour and evasion rating"] = "ArmourAndEvasion",
	["evasion rating and armour"] = "ArmourAndEvasion",
	["armour and energy shield"] = "ArmourAndEnergyShield",
	["evasion and energy shield"] = "EvasionAndEnergyShield",
	["armour, evasion and energy shield"] = "Defences",
	["defences"] = "Defences",
	-- Resistances
	["fire resistance"] = "FireResist",
	["maximum fire resistance"] = "FireResistMax",
	["cold resistance"] = "ColdResist",
	["maximum cold resistance"] = "ColdResistMax",
	["lightning resistance"] = "LightningResist",
	["maximum lightning resistance"] = "LightningResistMax",
	["chaos resistance"] = "ChaosResist",
	["fire and cold resistances"] = { "FireResist", "ColdResist" },
	["fire and lightning resistances"] = { "FireResist", "LightningResist" },
	["cold and lightning resistances"] = { "ColdResist", "LightningResist" },
	["elemental resistances"] = "ElementalResist",
	["all elemental resistances"] = "ElementalResist",
	["all maximum resistances"] = { "FireResistMax", "ColdResistMax", "LightningResistMax", "ChaosResistMax" },
	-- Other defences
	["to dodge attacks"] = "AttackDodgeChance",
	["to dodge spells"] = "SpellDodgeChance",
	["to dodge spell damage"] = "SpellDodgeChance",
	["to block"] = "BlockChance",
	["block chance"] = "BlockChance",
	["to block spells"] = "SpellBlockChance",
	["chance to block attacks and spells"] = { "BlockChance", "SpellBlockChance" },
	["maximum block chance"] = "BlockChanceMax",
	["to avoid being stunned"] = "AvoidStun",
	["to avoid being shocked"] = "AvoidShock",
	["to avoid being frozen"] = "AvoidFrozen",
	["to avoid being chilled"] = "AvoidChilled",
	["to avoid being ignited"] = "AvoidIgnite",
	["to avoid elemental status ailments"] = { "AvoidShock", "AvoidFrozen", "AvoidChilled", "AvoidIgnite" },
	-- Stun modifiers
	["stun recovery"] = "StunRecovery",
	["stun and block recovery"] = "StunRecovery",
	["stun threshold"] = "StunThreshold",
	["block recovery"] = "BlockRecovery",
	["enemy stun threshold"] = "EnemyStunThreshold",
	["stun duration on enemies"] = "EnemyStunDuration",
	-- Auras/curses
	["effect of non-curse auras you cast"] = "AuraEffect",
	["effect of your curses"] = "CurseEffect",
	["curse effect"] = "CurseEffect",
	["curse duration"] = { "Duration", keywordFlags = KeywordFlag.Curse },
	["radius of auras"] = { "AreaRadius", keywordFlags = KeywordFlag.Aura },
	["radius of curses"] = { "AreaRadius", keywordFlags = KeywordFlag.Curse },
	-- Charges
	["maximum power charge"] = "PowerChargesMax",
	["maximum power charges"] = "PowerChargesMax",
	["power charge duration"] = "PowerChargesDuration",
	["maximum frenzy charge"] = "FrenzyChargesMax",
	["maximum frenzy charges"] = "FrenzyChargesMax",
	["frenzy charge duration"] = "FrenzyChargesDuration",
	["maximum endurance charge"] = "EnduranceChargesMax",
	["maximum endurance charges"] = "EnduranceChargesMax",
	["endurance charge duration"] = "EnduranceChargesDuration",
	["endurance, frenzy and power charge duration"] = { "PowerChargesDuration", "FrenzyChargesDuration", "EnduranceChargesDuration" },
	-- On hit/kill effects
	["life gained on kill"] = "LifeOnKill",
	["mana gained on kill"] = "ManaOnKill",
	["life gained for each enemy hit by attacks"] = { "LifeOnHit", flags = ModFlag.Attack },
	["life gained for each enemy hit by your attacks"] = { "LifeOnHit", flags = ModFlag.Attack },
	["life gained for each enemy hit by spells"] = { "LifeOnHit", flags = ModFlag.Spell },
	["life gained for each enemy hit by your spells"] = { "LifeOnHit", flags = ModFlag.Spell },
	["mana gained for each enemy hit by attacks"] = { "ManaOnHit", flags = ModFlag.Attack },
	["mana gained for each enemy hit by your attacks"] = { "ManaOnHit", flags = ModFlag.Attack },
	["energy shield gained for each enemy hit by attacks"] = { "EnergyShieldOnHit", flags = ModFlag.Attack },
	["energy shield gained for each enemy hit by your attacks"] = { "EnergyShieldOnHit", flags = ModFlag.Attack },
	["life and mana gained for each enemy hit"] = { "LifeOnHit", "ManaOnHit", flags = ModFlag.Attack },
	-- Projectile modifiers
	["pierce chance"] = "PierceChance",
	["of projectiles piercing"] = "PierceChance",
	["of arrows piercing"] = { "PierceChance", flags = ModFlag.Bow },
	["projectile speed"] = "ProjectileSpeed",
	["arrow speed"] = { "ProjectileSpeed", flags = ModFlag.Bow },
	-- Totem/trap/mine modifiers
	["totem placement speed"] = "TotemPlacementSpeed",
	["totem life"] = "TotemLife",
	["totem duration"] = "TotemDuration",
	["trap throwing speed"] = "TrapThrowingSpeed",
	["trap trigger radius"] = "TrapTriggerRadius",
	["trap duration"] = "TrapDuration",
	["cooldown recovery speed for throwing traps"] = "TrapCooldownRecovery",
	["mine laying speed"] = "MineLayingSpeed",
	["mine detonation radius"] = "MineDetonationRadius",
	["mine duration"] = "MineDuration",
	-- Other skill modifiers
	["radius"] = "AreaRadius",
	["radius of area skills"] = "AreaRadius",
	["area of effect radius"] = "AreaRadius",
	["area of effect"] = "AreaRadius",
	["duration"] = "Duration",
	["skill effect duration"] = "Duration",
	["chaos skill effect duration"] = { "Duration", keywordFlags = KeywordFlag.Chaos },
	-- Buffs
	["onslaught effect"] = "OnslaughtEffect",
	["fortify duration"] = "FortifyDuration",
	["effect of fortify on you"] = "FortifyEffect",
	-- Basic damage types
	["damage"] = "Damage",
	["physical damage"] = "PhysicalDamage",
	["lightning damage"] = "LightningDamage",
	["cold damage"] = "ColdDamage",
	["fire damage"] = "FireDamage",
	["chaos damage"] = "ChaosDamage",
	["elemental damage"] = "ElementalDamage",
	-- Other damage forms
	["attack damage"] = { "Damage", flags = ModFlag.Attack },
	["physical attack damage"] = { "PhysicalDamage", flags = ModFlag.Attack },
	["physical weapon damage"] = { "PhysicalDamage", flags = ModFlag.Weapon },
	["physical melee damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["melee physical damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["bow damage"] = { "Damage", flags = ModFlag.Bow },
	["wand damage"] = { "Damage", flags = ModFlag.Wand },
	["wand physical damage"] = { "PhysicalDamage", flags = ModFlag.Wand },
	["claw physical damage"] = { "PhysicalDamage", flags = ModFlag.Claw },
	["damage over time"] = { "Damage", flags = ModFlag.Dot },
	["physical damage over time"] = { "PhysicalDamage", flags = ModFlag.Dot },
	["burning damage"] = { "FireDamage", flags = ModFlag.Dot },
	["righteous fire damage"] = { "Damage", tag = { type = "SkillName", skillName = "Righteous Fire" } }, -- Parser mis-interprets this one (Righteous/Fire Damage instead of Righteous Fire/Damage)
	-- Crit/accuracy/speed modifiers
	["critical strike chance"] = "CritChance",
	["critical strike multiplier"] = "CritMultiplier",
	["accuracy rating"] = "Accuracy",
	["attack speed"] = { "Speed", flags = ModFlag.Attack },
	["cast speed"] = { "Speed", flags = ModFlag.Spell },
	["attack and cast speed"] = "Speed",
	-- Elemental status ailments
	["to shock"] = "EnemyShockChance",
	["shock chance"] = "EnemyShockChance",
	["to freeze"] = "EnemyFreezeChance",
	["freeze chance"] = "EnemyFreezeChance",
	["to ignite"] = "EnemyIgniteChance",
	["ignite chance"] = "EnemyIgniteChance",
	["to freeze, shock and ignite"] = { "EnemyFreezeChance", "EnemyShockChance", "EnemyIgniteChance" },
	["shock duration on enemies"] = "EnemyShockDuration",
	["freeze duration on enemies"] = "EnemyFreezeDuration",
	["chill duration on enemies"] = "EnemyChillDuration",
	["ignite duration on enemies"] = "EnemyIgniteDuration",
	["duration of elemental status ailments on enemies"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration" },
	-- Other debuffs
	["to poison"] = "PoisonChance",
	["to poison on hit"] = "PoisonChance",
	["poison duration"] = { "Duration", keywordFlags = KeywordFlag.Poison },
	["to cause bleeding"] = "BleedChance",
	["to cause bleeding on hit"] = "BleedChance",
	["bleed duration"] = { "Duration", keywordFlags = KeywordFlag.Bleed },
	-- Misc modifiers
	["movement speed"] = "MovementSpeed",
	["light radius"] = "LightRadius",
	["rarity of items found"] = "LootRarity",
	["quantity of items found"] = "LootQuantity",
}

-- List of modifier flags
local modFlagList = {
	-- Weapon types
	["with axes"] = { flags = ModFlag.Axe },
	["with bows"] = { flags = ModFlag.Bow },
	["with claws"] = { flags = ModFlag.Claw },
	["with daggers"] = { flags = ModFlag.Dagger },
	["with maces"] = { flags = ModFlag.Mace },
	["with staves"] = { flags = ModFlag.Staff },
	["with swords"] = { flags = ModFlag.Sword },
	["with wands"] = { flags = ModFlag.Wand },
	["unarmed"] = { flags = ModFlag.Unarmed },
	["with one handed weapons"] = { flags = ModFlag.Weapon1H },
	["with one handed melee weapons"] = { flags = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee) },
	["with two handed weapons"] = { flags = ModFlag.Weapon2H },
	["with two handed melee weapons"] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee) },
	["with ranged weapons"] = { flags = ModFlag.WeaponRanged },
	-- Skill types
	["spell"] = { flags = ModFlag.Spell },
	["for spells"] = { flags = ModFlag.Spell },
	["with attacks"] = { flags = ModFlag.Attack },
	["for attacks"] = { flags = ModFlag.Attack },
	["weapon"] = { flags = ModFlag.Weapon },
	["with weapons"] = { flags = ModFlag.Weapon },
	["melee"] = { flags = ModFlag.Melee },
	["with melee attacks"] = { flags = ModFlag.Melee },
	["on melee hit"] = { flags = ModFlag.Melee },
	["with poison"] = { keywordFlags = KeywordFlag.Poison },
	["projectile"] = { flags = ModFlag.Projectile },
	["area"] = { flags = ModFlag.Area },
	["mine"] = { keywordFlags = KeywordFlag.Mine },
	["with mines"] = { keywordFlags = KeywordFlag.Mine },
	["trap"] = { keywordFlags = KeywordFlag.Trap },
	["with traps"] = { keywordFlags = KeywordFlag.Trap },
	["totem"] = { keywordFlags = KeywordFlag.Totem },
	["with totem skills"] = { keywordFlags = KeywordFlag.Totem },
	["minion"] = { keywordFlags = KeywordFlag.Minion },
	["of aura skills"] = { keywordFlags = KeywordFlag.Aura },
	["of curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["for curses"] = { keywordFlags = KeywordFlag.Curse },
	["warcry"] = { keywordFlags = KeywordFlag.Warcry },
	["vaal"] = { keywordFlags = KeywordFlag.Vaal },
	["vaal skill"] = { keywordFlags = KeywordFlag.Vaal },
	["with movement skills"] = { keywordFlags = KeywordFlag.Movement },
	["with lightning skills"] = { keywordFlags = KeywordFlag.Lightning },
	["with cold skills"] = { keywordFlags = KeywordFlag.Cold },
	["with fire skills"] = { keywordFlags = KeywordFlag.Fire },
	["with elemental skills"] = { keywordFlags = bor(KeywordFlag.Lightning, KeywordFlag.Cold, KeywordFlag.Fire) },
	["with chaos skills"] = { keywordFlags = KeywordFlag.Chaos },
	-- Other
	["global"] = { tag = { type = "Global" } },
	["from equipped shield"] = { tag = { type = "SlotName", slotName = "Weapon 2" } },
}

-- List of modifier flags/tags that appear at the start of a line
local preFlagList = {
	["^hits deal "] = { flags = ModFlag.Hit },
	["^minions have "] = { keywordFlags = KeywordFlag.Minion },
	["^minions deal "] = { keywordFlags = KeywordFlag.Minion },
	["^attacks used by totems have "] = { keywordFlags = KeywordFlag.Totem },
	["^spells cast by totems have "] = { keywordFlags = KeywordFlag.Totem },
	["^attacks have "] = { flags = ModFlag.Attack },
	["^melee attacks have "] = { flags = ModFlag.Melee },
	["^left ring slot: "] = { tag = { type = "SlotNumber", num = 1 } },
	["^right ring slot: "] = { tag = { type = "SlotNumber", num = 2 } },
	["^socketed gems have "] = { tag = { type = "SocketedIn" } },
	["^socketed gems deal "] = { tag = { type = "SocketedIn" } },
	["^socketed curse gems have "] = { tag = { type = "SocketedIn", keyword = "curse" } },
	["^socketed melee gems have "] = { tag = { type = "SocketedIn", keyword = "melee" } },
	["^your flasks grant "] = { },
}

-- List of modifier tags
local modTagList = {
	-- Multipliers
	["per power charge"] = { tag = { type = "Multiplier", var = "PowerCharge" } },
	["per frenzy charge"] = { tag = { type = "Multiplier", var = "FrenzyCharge" } },
	["per endurance charge"] = { tag = { type = "Multiplier", var = "EnduranceCharge" } },
	["per level"] = { tag = { type = "Multiplier", var = "Level" } },
	["for each normal item you have equipped"] = { tag = { type = "Multiplier", var = "NormalItem" } },
	["for each magic item you have equipped"] = { tag = { type = "Multiplier", var = "MagicItem" } },
	["for each rare item you have equipped"] = { tag = { type = "Multiplier", var = "RareItem" } },
	["for each unique item you have equipped"] = { tag = { type = "Multiplier", var = "UniqueItem" } },
	-- Per stat
	["per (%d+) strength"] = function(num) return { tag = { type = "PerStat", stat = "Str", div = num } } end,
	["per (%d+) dexterity"] = function(num) return { tag = { type = "PerStat", stat = "Dex", div = num } } end,
	["per (%d+) intelligence"] = function(num) return { tag = { type = "PerStat", stat = "Int", div = num } } end,
	["per (%d+) evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "Evasion", div = num } } end,
	["per (%d+) accuracy rating"] = function(num) return { tag = { type = "PerStat", stat = "Accuracy", div = num } } end,
	["per (%d+)%% block chance"] = function(num) return { tag = { type = "PerStat", stat = "BlockChance", div = num } } end,
	-- Slot conditions
	["in main hand"] = { tag = { type = "SlotNumber", num = 1 } },
	["when in main hand"] = { tag = { type = "SlotNumber", num = 1 } },
	["in off hand"] = { tag = { type = "SlotNumber", num = 2 } },
	["when in off hand"] = { tag = { type = "SlotNumber", num = 2 } },
	-- Equipment conditions
	["while holding a shield"] = { tag = { type = "Condition", var = "UsingShield" } },
	["with shields"] = { tag = { type = "Condition", var = "UsingShield" } },
	["while dual wielding"] = { tag = { type = "Condition", var = "DualWielding" } },
	["while wielding a staff"] = { tag = { type = "Condition", var = "UsingStaff" } },
	["while unarmed"] = { tag = { type = "Condition", var = "Unarmed" } },
	["with a normal item equipped"] = { tag = { type = "Condition", var = "UsingNormalItem" } },
	["with a magic item equipped"] = { tag = { type = "Condition", var = "UsingMagicItem" } },
	["with a rare item equipped"] = { tag = { type = "Condition", var = "UsingRareItem" } },
	["with a unique item equipped"] = { tag = { type = "Condition", var = "UsingUniqueItem" } },
	["if you wear no corrupted items"] = { tag = { type = "Condition", var = "NotUsingCorruptedItem" } },
	["with main hand"] = { tag = { type = "Condition", var = "MainHandAttack" } },
	["with off hand"] = { tag = { type = "Condition", var = "OffHandAttack" } },
	-- Player status conditions
	["when on low life"] = { tag = { type = "Condition", var = "LowLife" } },
	["while on low life"] = { tag = { type = "Condition", var = "LowLife" } },
	["when not on low life"] = { tag = { type = "Condition", var = "LowLife", neg = true } },
	["while not on low life"] = { tag = { type = "Condition", var = "LowLife", neg = true } },
	["when on full life"] = { tag = { type = "Condition", var = "FullLife" } },
	["when not on full life"] = { tag = { type = "Condition", var = "FullLife", neg = true } },
	["while no mana is reserved"] = { tag = { type = "Condition", var = "NoManaReserved" } },
	["while at maximum power charges"] = { tag = { type = "Condition", var = "AtMaxPowerCharges" } },
	["while at maximum frenzy charges"] = { tag = { type = "Condition", var = "AtMaxFrenzyCharges" } },
	["while at maximum endurance charges"] = { tag = { type = "Condition", var = "AtMaxEnduranceCharges" } },
	["while you have fortify"] = { tag = { type = "Condition", var = "Fortify" } },
	["during onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while you have onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while phasing"] = { tag = { type = "Condition", var = "Phasing" } },
	["while using a flask"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during flask effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["while on consecrated ground"] = { tag = { type = "Condition", var = "OnConsecratedGround" } },
	["if you have hit recently"] = { tag = { type = "Condition", var = "HitRecently" } },
	["if you've crit recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you've dealt a critical strike recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you haven't crit recently"] = { tag = { type = "Condition", var = "NotCritRecently" } },
	["if you've killed recently"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["if you haven't killed recently"] = { tag = { type = "Condition", var = "NotKilledRecently" } },
	["if you or your totems have killed recently"] = { tag = { type = "Condition", varList = {"KilledRecently","TotemsKilledRecently"} } },
	["if you've been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were damaged by a hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you haven't been hit recently"] = { tag = { type = "Condition", var = "NotBeenHitRecently" } },
	["if you've taken no damage from hits recently"] = { tag = { type = "Condition", var = "NotBeenHitRecently" } },
	["if you've blocked a hit from a unique enemy recently"] = { tag = { type = "Condition", var = "BlockedHitFromUniqueEnemyRecently" } },
	["if you've attacked recently"] = { tag = { type = "Condition", var = "AttackedRecently" } },
	["if you've cast a spell recently"] = { tag = { type = "Condition", var = "CastSpellRecently" } },
	["if you've used a fire skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedFireSkillInPast10Sec" } },
	["if you've used a cold skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedColdSkillInPast10Sec" } },
	["if you've used a lightning skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedLightningSkillInPast10Sec" } },
	["if you've summoned a totem recently"] = { tag = { type = "Condition", var = "SummonedTotemRecently" } },
	["if you've used a movement skill recently"] = { tag = { type = "Condition", var = "UsedMovementSkillRecently" } },
	["if you detonated mines recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["if you've crit in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if energy shield recharge has started recently"] = { tag = { type = "Condition", var = "EnergyShieldRechargeRecently" } },
	-- Enemy status conditions
	["at close range"] = { tag = { type = "Condition", var = "AtCloseRange" }, flags = ModFlag.Hit },
	["against enemies on full life"] = { tag = { type = "Condition", var = "EnemyFullLife" }, flags = ModFlag.Hit },
	["against enemies that are on full life"] = { tag = { type = "Condition", var = "EnemyFullLife" }, flags = ModFlag.Hit },
	["against enemies on low life"] = { tag = { type = "Condition", var = "EnemyLowLife" }, flags = ModFlag.Hit },
	["against enemies that are on low life"] = { tag = { type = "Condition", var = "EnemyLowLife" }, flags = ModFlag.Hit },
	["against bleeding enemies"] = { tag = { type = "Condition", var = "EnemyBleeding" }, flags = ModFlag.Hit },
	["against poisoned enemies"] = { tag = { type = "Condition", var = "EnemyPoisoned" }, flags = ModFlag.Hit },
	["against burning enemies"] = { tag = { type = "Condition", var = "EnemyBurning" }, flags = ModFlag.Hit },
	["against ignited enemies"] = { tag = { type = "Condition", var = "EnemyIgnited" }, flags = ModFlag.Hit },
	["against shocked enemies"] = { tag = { type = "Condition", var = "EnemyShocked" }, flags = ModFlag.Hit },
	["against frozen enemies"] = { tag = { type = "Condition", var = "EnemyFrozen" }, flags = ModFlag.Hit },
	["against chilled enemies"] = { tag = { type = "Condition", var = "EnemyChilled" }, flags = ModFlag.Hit },
	["enemies which are chilled"] = { tag = { type = "Condition", var = "EnemyChilled" }, flags = ModFlag.Hit },
	["against frozen, shocked or ignited enemies"] = { tag = { type = "Condition", var = "EnemyFrozenShockedIgnited" }, flags = ModFlag.Hit },
	["against enemies that are affected by elemental status ailments"] = { tag = { type = "Condition", var = "EnemyElementalStatus" }, flags = ModFlag.Hit },
	["against enemies that are affected by no elemental status ailments"] = { tag = { type = "Condition", var = "NotEnemyElementalStatus" }, flags = ModFlag.Hit },
}

local mod = modLib.createMod
local function flag(name, ...)
	return mod(name, "FLAG", true, ...)
end

local gemNameLookup = { }
for name in pairs(data.gems) do
	gemNameLookup[name:lower()] = name
end

-- List of special modifiers
local specialModList = {
	-- Keystones
	["your hits can't be evaded"] = { flag("CannotBeEvaded") },
	["never deal critical strikes"] = { flag("NeverCrit") },
	["no critical strike multiplier"] = { flag("NoCritMultiplier") },
	["the increase to physical damage from strength applies to projectile attacks as well as melee attacks"] = { flag("IronGrip") },
	["converts all evasion rating to armour%. dexterity provides no bonus to evasion rating"] = { flag("IronReflexes") },
	["30%% chance to dodge attacks%. 50%% less armour and energy shield, 30%% less chance to block spells and attacks"] = { mod("AttackDodgeChance", "BASE", 30), mod("Armour", "MORE", -50), mod("EnergyShield", "MORE", -50), mod("BlockChance", "MORE", -30), mod("SpellBlockChance", "MORE", -30) },
	["maximum life becomes 1, immune to chaos damage"] = { flag("ChaosInoculation") },
	["life regeneration is applied to energy shield instead"] = { flag("ZealotsOath") },
	["life leech applies instantly%. life regeneration has no effect%."] = { flag("VaalPact"), flag("NoLifeRegen") },
	["deal no non%-fire damage"] = { flag("DealNoPhysical"), flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoChaos") },
	["(%d+)%% of physical, cold and lightning damage converted to fire damage"] = function(num) return { mod("PhysicalDamageConvertToFire", "BASE", num), mod("LightningDamageConvertToFire", "BASE", num), mod("ColdDamageConvertToFire", "BASE", num) } end,
	["removes all mana%. spend life instead of mana for skills"] = { mod("Mana", "MORE", -100), flag("BloodMagic") },
	["enemies you hit with elemental damage temporarily get (%+%d+)%% resistance to those elements and (%-%d+)%% resistance to other elements"] = function(plus, _, minus)
		minus = tonumber(minus)
		return {
			mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("FireResist", "BASE", plus, { type = "Condition", var = "HitByFireDamage" }) }),
			mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("FireResist", "BASE", minus, { type = "Condition", var = "HitByFireDamage", neg = true }, { type = "Condition", varList={"HitByColdDamage","HitByLightningDamage"} }) }),
			mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("ColdResist", "BASE", plus, { type = "Condition", var = "HitByColdDamage" }) }),
			mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("ColdResist", "BASE", minus, { type = "Condition", var = "HitByColdDamage", neg = true }, { type = "Condition", varList={"HitByFireDamage","HitByLightningDamage"} }) }),
			mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("LightningResist", "BASE", plus, { type = "Condition", var = "HitByLightningDamage" }) }),
			mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("LightningResist", "BASE", minus, { type = "Condition", var = "HitByLightningDamage", neg = true }, { type = "Condition", varList={"HitByFireDamage","HitByColdDamage"} }) }),
		}
	end,
	-- Ascendancy notables
	["movement skills cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Movement) },
	["projectiles have 100%% additional chance to pierce targets at the start of their movement, losing this chance as the projectile travels farther"] = { mod("PierceChance", "BASE", 50, { type = "Condition", var = "Effective" }) },
	["projectile critical strike chance increased by arrow pierce chance"] = { mod("CritChance", "INC", 1, nil, ModFlag.Projectile, 0, { type = "PerStat", stat = "PierceChance", div = 1 }) },
	["always poison on hit while using a flask"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["armour received from body armour is doubled"] = { flag("Unbreakable") },
	["gain (%d+)%% of maximum mana as extra maximum energy shield"] = function(num) return { mod("ManaGainAsEnergyShield", "BASE", num) } end,
	["you have fortify"] = { mod("Misc", "LIST", { type = "Condition", var = "Fortify"}) },
	["(%d+)%% increased damage of each damage type for which you have a matching golem"] = function(num) return { mod("PhysicalDamage", "INC", num, { type = "Condition", var = "HavePhysicalGolem"}), mod("LightningDamage", "INC", num, { type = "Condition", var = "HaveLightningGolem"}), mod("ColdDamage", "INC", num, { type = "Condition", var = "HaveColdGolem"}), mod("FireDamage", "INC", num, { type = "Condition", var = "HaveFireGolem"}), mod("ChaosDamage", "INC", num, { type = "Condition", var = "HaveChaosGolem"}) } end,
	["100%% increased effect of buffs granted by your elemental golems"] = { flag("LiegeOfThePrimordial") },
	["every 10 seconds, gain (%d+)%% increased elemental damage for 4 seconds"] = function(num) return { mod("ElementalDamage", "INC", num, { type = "Condition", var = "PendulumOfDestruction" }) } end,
	["every 10 seconds, gain (%d+)%% increased radius of area skills for 4 seconds"] = function(num) return { mod("AreaRadius", "INC", num, { type = "Condition", var = "PendulumOfDestruction" }) } end,
	["enemies you curse take (%d+)%% increased damage"] = function(num) return { mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("DamageTaken", "INC", num) }, { type = "Condition", var = "EnemyCursed" }) } end,
	["enemies you curse have (%-%d+)%% to chaos resistance"] = function(num) return { mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("ChaosResist", "BASE", num) }, { type = "Condition", var = "EnemyCursed" }) } end,
	["nearby enemies have (%-%d+)%% to chaos resistance"] = function(num) return { mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("ChaosResist", "BASE", num) }) } end,
	["nearby enemies take (%d+)%% increased elemental damage"] = function(num) return { mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("ElementalDamageTaken", "INC", num) }) } end,
	["enemies near your totems take (%d+)%% increased physical and fire damage"] = function(num) return { mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("PhysicalDamageTaken", "INC", num) }), mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("FireDamageTaken", "INC", num) }) } end,
	["grants armour equal to (%d+)%% of your reserved life to you and nearby allies"] = function(num) return { mod("Armour", "BASE", num/100, { type = "PerStat", stat = "LifeReserved", div = 1 }) } end,
	["grants maximum energy shield equal to (%d+)%% of your reserved mana to you and nearby allies"] = function(num) return { mod("EnergyShield", "BASE", num/100, { type = "PerStat", stat = "ManaReserved", div = 1 }) } end,
	["you and nearby allies deal (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num) } end,
	["you and nearby allies have (%d+)%% increased movement speed"] = function(num) return { mod("MovementSpeed", "INC", num) } end,
	["skills from your helmet penetrate (%d+)%% elemental resistances"] = function(num) return { mod("ElementalPenetration", "BASE", num, { type = "SocketedIn", slotName = "Helmet" }) } end,
	["skills from your gloves have (%d+)%% increased area of effect"] = function(num) return { mod("AreaRadius", "INC", num, { type = "SocketedIn", slotName = "Gloves" }) } end,
	["(%d+)%% less totem damage per totem"] = function(num) return { mod("Damage", "MORE", -num, nil, 0, KeywordFlag.Totem, { type = "PerStat", stat = "ActiveTotemLimit", div = 1 }) } end,
	["poison you inflict with critical strikes deals (%d+)%% more damage"] = function(num) return { mod("PoisonDamageOnCrit", "MORE", 100) } end,
	["bleeding you inflict on maimed enemies deals (%d+)%% more damage"] = function(num) return { mod("Damage", "MORE", num, nil, 0, KeywordFlag.Bleed, { type = "Condition", var = "EnemyMaimed"}) } end,
	-- Special node types
	["(%d+)%% of block chance applied to spells"] = function(num) return { mod("BlockChanceConv", "BASE", num) } end,
	["(%d+)%% additional block chance with staves"] = function(num) return { mod("BlockChance", "BASE", num, { type = "Condition", var = "UsingStaff" }) } end,
	["(%d+)%% additional block chance while dual wielding or holding a shield"] = function(num) return { mod("BlockChance", "BASE", num, { type = "Condition", var = "DualWielding"}), mod("BlockChance", "BASE", num, { type = "Condition", var = "UsingShield"}) } end,
	["can have up to (%d+) additional traps? placed at a time"] = function(num) return { mod("ActiveTrapLimit", "BASE", num) } end,
	["can have up to (%d+) additional remote mines? placed at a time"] = function(num) return { mod("ActiveMineLimit", "BASE", num) } end,
	["can have up to (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num) } end,
	-- Other modifiers
	["cannot be stunned"] = { mod("AvoidStun", "BASE", 100) },
	["cannot be shocked"] = { mod("AvoidShock", "BASE", 100) },
	["cannot be frozen"] = { mod("AvoidFreeze", "BASE", 100) },
	["cannot be chilled"] = { mod("AvoidChill", "BASE", 100) },
	["cannot be ignited"] = { mod("AvoidIgnite", "BASE", 100) },
	["cannot evade enemy attacks"] = { flag("CannotEvade") },
	["deal no physical damage"] = { flag("DealNoPhysical") },
	["deal no elemental damage"] = { flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoFire") },
	["your critical strikes do not deal extra damage"] = { flag("NoCritMultiplier") },
	["iron will"] = { flag("IronWill") },
	["adds an additional arrow"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack) },
	["(%d+) additional arrows"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Attack) } end,
	["skills fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1) },
	["spells have an additional projectile"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Spell) },
	["skills chain %+(%d) times"] = function(num) return { mod("ChainCount", "BASE", num) } end,
	["reflects (%d+) physical damage to melee attackers"] = { },
	-- Special item local modifiers
	["no physical damage"] = { mod("Misc", "LIST", { type = "WeaponData", key = "PhysicalMin" }), mod("Misc", "LIST", { type = "WeaponData", key = "PhysicalMax" }), mod("Misc", "LIST", { type = "WeaponData", key = "PhysicalDPS" }) },
	["all attacks with this weapon are critical strikes"] = { mod("Misc", "LIST", { type = "WeaponData", key = "critChance", value = 100 }) },
	["hits can't be evaded"] = { mod("Misc", "LIST", { type = "WeaponData", key = "CannotBeEvaded", value = true }) },
	["no block chance"] = { mod("Misc", "LIST", { type = "ArmourData", key = "BlockChance", value = 0 }) },
	["causes bleeding on hit"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Attack) },
	["poisonous hit"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Attack) },
	["has no sockets"] = { },
	["has 1 socket"] = { },
	["attacks have blood magic"] = { flag("SkillBloodMagic", nil, ModFlag.Attack) },
	["%+(%d+) to level of socketed gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "all", key = "level", value = num }, { type = "SocketedIn" }) } end,
	["%+(%d+) to level of socketed (%a+) gems"] = function(num, _, type) return { mod("GemProperty", "LIST", { keyword = type, key = "level", value = num }, { type = "SocketedIn" }) } end,
	["%+(%d+)%% to quality of socketed (%a+) gems"] = function(num, _, type) return { mod("GemProperty", "LIST", { keyword = type, key = "quality", value = num }, { type = "SocketedIn" }) } end,
	["%+(%d+) to level of active socketed skill gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "active_skill", key = "level", value = num }, { type = "SocketedIn" }) } end,
	["grants level (%d+) (.+)"] = function(num, _, skill) return { mod("ExtraSkill", "LIST", { name = gemNameLookup[skill:gsub(" skill","")] or "Unknown", level = num }, { type = "SocketedIn" }) } end,
	["curse enemies with (%D+) on %a+"] = function(_, skill) return { mod("ExtraSkill", "LIST", { name = gemNameLookup[skill] or "Unknown", level = 1, noSupports = true }, { type = "SocketedIn" }) } end,
	["curse enemies with level (%d+) (.+) on %a+"] = function(num, _, skill) return { mod("ExtraSkill", "LIST", { name = gemNameLookup[skill] or "Unknown", level = num, noSupports = true }, { type = "SocketedIn" }) } end,
	["socketed .*gems are supported by level (%d+) (.+)"] = function(num, _, support) return { mod("ExtraSupport", "LIST", { name = gemNameLookup[support] or "Unknown", level = num }, { type = "SocketedIn" }) } end,
	["socketed curse gems supported by level (%d+) (.+)"] = function(num, _, support) return { mod("ExtraSupport", "LIST", { name = gemNameLookup[support] or "Unknown", level = num }, { type = "SocketedIn" }) } end,
	["socketed gems fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1, { type = "SocketedIn" }) },
	["socketed gems fire (%d+) additional projectiles"] = function(num) return { mod("ProjectileCount", "BASE", num, { type = "SocketedIn" }) } end,
	["socketed gems reserve no mana"] = { mod("ManaReserved", "MORE", -100, { type = "SocketedIn" }) },
	["socketed gems have blood magic"] = { flag("SkillBloodMagic", { type = "SocketedIn" }) },
	["socketed gems gain (%d+)%% of physical damage as extra lightning damage"] = function(num) return { mod("PhysicalDamageGainAsLightning", "BASE", num, { type = "SocketedIn" }) } end,
	["socketed red gems get (%d+)%% physical damage as extra fire damage"] = function(num) return { mod("PhysicalDamageGainAsFire", "BASE", num, { type = "SocketedIn", keyword = "strength" }) } end,
	-- Unique item modifiers
	["your cold damage can ignite"] = { flag("ColdCanIgnite") },
	["your fire damage can shock but not ignite"] = { flag("FireCanShock"), flag("FireCannotIgnite") },
	["your cold damage can ignite but not freeze or chill"] = { flag("ColdCanIgnite"), flag("ColdCannotFreeze"), flag("ColdCannotChill") },
	["your lightning damage can freeze but not shock"] = { flag("LightningCanFreeze"), flag("LightningCannotShock") },
	["your chaos damage can shock"] = { flag("ChaosCanShock") },
	["your physical damage can chill"] = { flag("PhysicalCanChill") },
	["your physical damage can shock"] = { flag("PhysicalCanShock") },
	["your chaos damage poisons enemies"] = { mod("PoisonChance", "BASE", 100) },
	["melee attacks cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee) },
	["melee attacks poison on hit"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Melee) },
	["traps and mines deal (%d+)%-(%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["traps and mines deal (%d+) to (%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["traps and mines have a (%d+)%% chance to poison on hit"] = function(num) return { mod("PoisonChance", "BASE", num, nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["poison cursed enemies on hit"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "EnemyCursed" }) },
	["projectile damage increased by arrow pierce chance"] = { mod("Damage", "INC", 1, nil, ModFlag.Projectile, 0, { type = "PerStat", stat = "PierceChance", div = 1 }) },
	["gain (%d+) armour per grand spectrum"] = function(num) return { mod("Armour", "BASE", num, { type = "Multiplier", var = "GrandSpectrum" }), mod("Misc", "LIST", { type = "Multiplier", var = "GrandSpectrum", value = 1}) } end,
	["gain (%d+) mana per grand spectrum"] = function(num) return { mod("Mana", "BASE", num, { type = "Multiplier", var = "GrandSpectrum" }), mod("Misc", "LIST", { type = "Multiplier", var = "GrandSpectrum", value = 1}) } end,
	["(%d+)%% increased elemental damage per grand spectrum"] = function(num) return { mod("ElementalDamage", "INC", num, { type = "Multiplier", var = "GrandSpectrum" }), mod("Misc", "LIST", { type = "Multiplier", var = "GrandSpectrum", value = 1}) } end,
	["counts as dual wielding"] = { mod("Misc", "LIST", { type = "Condition", var = "DualWielding"}) },
	["counts as all one handed melee weapon types"] = { mod("Misc", "LIST", { type = "WeaponData", key = "flag", value = bor(ModFlag.Axe, ModFlag.Claw, ModFlag.Dagger, ModFlag.Mace, ModFlag.Sword)}) },
	["gain (%d+)%% of bow physical damage as extra damage of each element"] = function(num) return { mod("PhysicalDamageGainAsLightning", "BASE", num, nil, ModFlag.Bow), mod("PhysicalDamageGainAsCold", "BASE", num, nil, ModFlag.Bow), mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Bow) } end,
	["totems fire (%d+) additional projectiles"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	["when at maximum frenzy charges, attacks poison enemies"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Attack, { type = "Condition", var = "AtMaxFrenzyCharges" }) },
	["skills chain an additional time while at maximum frenzy charges"] = { mod("ChainCount", "BASE", 1, { type = "Condition", var = "AtMaxFrenzyCharges" }) },
	["you cannot be shocked while at maximum endurance charges"] = { mod("AvoidShock", "BASE", 100, { type = "Condition", var = "AtMaxEnduranceCharges" }) },
	["you have no life regeneration"] = { flag("NoLifeRegen") },
	["cannot block attacks"] = { flag("CannotBlockAttacks") },
	["projectiles pierce while phasing"] = { mod("PierceChance", "BASE", 100, { type = "Condition", var = "Phasing" }) },
	["increases and reductions to minion damage also affects you"] = { flag("MinionDamageAppliesToPlayer") },
	["increases and reductions to spell damage also apply to attacks"] = { flag("SpellDamageAppliesToAttacks") },
	["armour is increased by uncapped fire resistance"] = { mod("Armour", "INC", 1, { type = "PerStat", stat = "FireResistTotal", div = 1 }) },
	["critical strike chance is increased by uncapped lightning resistance"] = { mod("CritChance", "INC", 1, { type = "PerStat", stat = "LightningResistTotal", div = 1 }) },
	["critical strikes deal no damage"] = { flag("NoCritDamage") },
	["enemies chilled by you take (%d+)%% increased burning damage"] = function(num) return { mod("Misc", "LIST", { type = "EnemyModifier", mod = mod("BurningDamageTaken", "INC", num) }, { type = "Condition", var = "EnemyChilled" }) } end,
	["attacks with this weapon penetrate (%d+)%% elemental resistances"] = function(num) return { mod("ElementalPenetration", "BASE", num, nil, ModFlag.Weapon) } end,
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
	"Avatar of Fire",
}
for _, name in pairs(keystoneList) do
	specialModList[name:lower()] = { mod("Keystone", "LIST", name) }
end

-- Special lookups used for various modifier forms
local convTypes = {
	["as extra lightning damage"] = "GainAsLightning",
	["added as lightning damage"] = "GainAsLightning",
	["gained as extra lightning damage"] = "GainAsLightning",
	["as extra cold damage"] = "GainAsCold",
	["added as cold damage"] = "GainAsCold",
	["gained as extra cold damage"] = "GainAsCold",
	["as extra fire damage"] = "GainAsFire",
	["added as fire damage"] = "GainAsFire",
	["gained as extra fire damage"] = "GainAsFire",
	["as extra chaos damage"] = "GainAsChaos",
	["added as chaos damage"] = "GainAsChaos",
	["gained as extra chaos damage"] = "GainAsChaos",
	["converted to lightning damage"] = "ConvertToLightning",
	["converted to cold damage"] = "ConvertToCold",
	["converted to fire damage"] = "ConvertToFire",
	["converted to chaos damage"] = "ConvertToChaos",
}
local dmgTypes = {
	["physical"] = "Physical",
	["lightning"] = "Lightning",
	["cold"] = "Cold",
	["fire"] = "Fire",
	["chaos"] = "Chaos",
}
local penTypes = {
	["lightning resistance"] = "LightningPenetration",
	["cold resistance"] = "ColdPenetration",
	["fire resistance"] = "FirePenetration",
	["elemental resistance"] = "ElementalPenetration",
	["elemental resistances"] = "ElementalPenetration",
}
local regenTypes = {
	["life"] = "LifeRegen",
	["maximum life"] = "LifeRegen",
	["mana"] = "ManaRegen",
	["energy shield"] = "EnergyShieldRegen",
	["maximum mana and energy shield"] = { "ManaRegen", "EnergyShieldRegen" },
}

-- Build active skill name lookup
local skillNameList = { }
for skillName, data in pairs(data.gems) do
	if not data.support then
		skillNameList[" "..skillName:lower().." "] = { tag = { type = "SkillName", skillName = skillName } }
	end
end

local function getSimpleConv(src, dst, type, factor)
	return function(nodeMods, out, data)
		if nodeMods then
			local nodeVal = nodeMods:Sum(type, nil, src)
			if nodeVal ~= 0 then
				out:NewMod(src, type, -nodeVal, "Tree:Jewel")
				out:NewMod(dst, type, nodeVal * factor, "Tree:Jewel")
			end
		end
	end
end
local function getMatchConv(others, dst, type)
	return function(nodeMods, out, data)
		if nodeMods then
			for _, mod in ipairs(nodeMods) do
				for _, other in pairs(others) do
					if mod.name:match(other) and mod.type == type then
						out:NewMod(mod.name, type, -mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags)
						out:NewMod(mod.name:gsub(other, dst), type, mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags)
					end
				end
			end
		end
	end
end
local function getPerStat(dst, type, flags, stat, factor)
	return function(nodeMods, out, data)
		if nodeMods then
			data[stat] = (data[stat] or 0) + nodeMods:Sum("BASE", nil, stat)
		else
			out:NewMod(dst, type, math.floor(data[stat] * factor + 0.5), "Tree:Jewel", flags)
		end
	end
end
-- List of radius jewel functions
local jewelFuncs = {
	["Strength from Passives in Radius is Transformed to Dexterity"] = getSimpleConv("Str", "Dex", "BASE", 1),
	["Dexterity from Passives in Radius is Transformed to Strength"] = getSimpleConv("Dex", "Str", "BASE", 1),
	["Strength from Passives in Radius is Transformed to Intelligence"] = getSimpleConv("Str", "Int", "BASE", 1),
	["Intelligence from Passives in Radius is Transformed to Strength"] = getSimpleConv("Int", "Str", "BASE", 1),
	["Dexterity from Passives in Radius is Transformed to Intelligence"] = getSimpleConv("Dex", "Int", "BASE", 1),
	["Intelligence from Passives in Radius is Transformed to Dexterity"] = getSimpleConv("Int", "Dex", "BASE", 1),
	["Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield"] = getSimpleConv("Life", "EnergyShield", "INC", 1),
	["Increases and Reductions to Energy Shield in Radius are Transformed to apply to Armour at 200% of their value"] = getSimpleConv("EnergyShield", "Armour", "INC", 2),
	["Increases and Reductions to Life in Radius are Transformed to apply to Mana at 200% of their value"] = getSimpleConv("Life", "Mana", "INC", 2),
	["Increases and Reductions to Physical Damage in Radius are Transformed to apply to Cold Damage"] = getMatchConv({"PhysicalDamage"}, "ColdDamage", "INC"),
	["Increases and Reductions to Cold Damage in Radius are Transformed to apply to Physical Damage"] = getMatchConv({"ColdDamage"}, "PhysicalDamage", "INC"),
	["Increases and Reductions to other Damage Types in Radius are Transformed to apply to Fire Damage"] = getMatchConv({"PhysicalDamage","ColdDamage","LightningDamage","ChaosDamage"}, "FireDamage", "INC"),
	["Melee and Melee Weapon Type modifiers in Radius are Transformed to Bow Modifiers"] = function(nodeMods, out, data)
		if nodeMods then
			local mask1 = bor(ModFlag.Axe, ModFlag.Claw, ModFlag.Dagger, ModFlag.Mace, ModFlag.Staff, ModFlag.Sword, ModFlag.Melee)
			local mask2 = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee)
			local mask3 = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee)
			for _, mod in ipairs(nodeMods) do
				if band(mod.flags, mask1) ~= 0 or band(mod.flags, mask2) == mask2 or band(mod.flags, mask3) == mask3 then
					out:NewMod(mod.name, mod.type, -mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod.tagList))
					out:NewMod(mod.name, mod.type, mod.value, "Tree:Jewel", bor(band(mod.flags, bnot(bor(mask1, mask2, mask3))), ModFlag.Bow), mod.keywordFlags, unpack(mod.tagList))
				elseif mod.tagList[1] then
					for _, tag in ipairs(mod.tagList) do
						if tag.type == "Condition" and tag.var == "UsingStaff" then
							local newTagList = copyTable(mod.tagList)
							for _, tag in ipairs(newTagList) do
								if tag.type == "Condition" and tag.var == "UsingStaff" then
									tag.var = "UsingBow"
									break
								end
							end
							out:NewMod(mod.name, mod.type, -mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(mod.tagList))
							out:NewMod(mod.name, mod.type, mod.value, "Tree:Jewel", mod.flags, mod.keywordFlags, unpack(newTagList))
							break
						end
					end
				end
			end
		end
	end,
	["Adds 1 to maximum Life per 3 Intelligence in Radius"] = getPerStat("Life", "BASE", 0, "Int", 1 / 3),
	["Adds 1 to Maximum Life per 3 Intelligence Allocated in Radius"] = getPerStat("Life", "BASE", 0, "Int", 1 / 3),
	["1% increased Evasion Rating per 3 Dexterity Allocated in Radius"] = getPerStat("Evasion", "INC", 0, "Dex", 1 / 3),
	["1% increased Claw Physical Damage per 3 Dexterity Allocated in Radius"] = getPerStat("PhysicalDamage", "INC", ModFlag.Claw, "Dex", 1 / 3),
	["1% increased Melee Physical Damage while Unarmed per 3 Dexterity Allocated in Radius"] = getPerStat("PhysicalDamage", "INC", ModFlag.Unarmed, "Dex", 1 / 3),
	["3% increased Totem Life per 10 Strength in Radius"] = getPerStat("TotemLife", "INC", 0, "Str", 3 / 10),
	["3% increased Totem Life per 10 Strength Allocated in Radius"] = getPerStat("TotemLife", "INC", 0, "Str", 3 / 10),
	["Adds 1 maximum Lightning Damage to Attacks per 1 Dexterity Allocated in Radius"] = getPerStat("LightningMax", "BASE", ModFlag.Attack, "Dex", 1),
	["5% increased Chaos damage per 10 Intelligence from Allocated Passives in Radius"] = getPerStat("ChaosDamage", "INC", 0, "Int", 5 / 10),
	["Dexterity and Intelligence from passives in Radius count towards Strength Melee Damage bonus"] = function(nodeMods, out, data)
		if nodeMods then
			data.Dex = (data.Dex or 0) + nodeMods:Sum("BASE", nil, "Dex")
			data.Int = (data.Int or 0) + nodeMods:Sum("BASE", nil, "Int")
		else
			out:NewMod("DexIntToMeleeBonus", "BASE", data.Dex + data.Int, "Tree:Jewel")
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

local function parseMod(line)
	-- Check if this is a special modifier
	local specialMod, specialLine, cap = scan(line, specialModList)
	if specialMod and #specialLine == 0 then
		if type(specialMod) == "function" then
			return specialMod(tonumber(cap[1]), unpack(cap))
		else
			return copyTable(specialMod)
		end
	end
	for desc, func in pairs(jewelFuncs) do
		if desc:lower() == line:lower() then
			return { mod("Misc", "LIST", { type = "JewelFunc", func = func }) }
		end
	end

	-- Check for a flag/tag specification at the start of the line
	local modFlag
	modFlag, line = scan(line, preFlagList)

	-- Scan for modifier form
	local modForm, formCap
	modForm, line, formCap = scan(line, formList)
	if not modForm then
		return
	end
	local num = tonumber(formCap[1])

	-- Check for tags (per-charge, conditionals)
	local modTag, modTag2
	modTag, line, cap = scan(line, modTagList)
	if type(modTag) == "function" then
		modTag = modTag(tonumber(cap[1]), unpack(cap))
	end
	if modTag then
		modTag2, line, cap = scan(line, modTagList)
		if type(modTag2) == "function" then
			modTag2 = modTag2(tonumber(cap[1]), unpack(cap))
		end
	end
	
	-- Scan for modifier name
	local modName
	modName, line = scan(line, modNameList, true)

	-- Scan for skill name
	local skillTag
	skillTag, line = scan(line, skillNameList, true)

	-- Scan for flags if one hasn't been found already
	if not modFlag then
		modFlag, line = scan(line, modFlagList, true)
	end

	-- Find modifier value and type according to form
	local modValue = num
	local modType = "BASE"
	local modSuffix = ""
	if modForm == "INC" then
		modType = "INC"
	elseif modForm == "RED" then
		modValue = -num
		modType = "INC"
	elseif modForm == "MORE" then
		modType = "MORE"
	elseif modForm == "LESS" then
		modValue = -num
		modType = "MORE"
	elseif modForm == "BASE" then
	elseif modForm == "CHANCE" then
	elseif modForm == "CONV" then		
		modSuffix, line = scan(line, convTypes, true)
		if not modSuffix then
			return { }, line
		end
	elseif modForm == "PEN" then
		modName, line = scan(line, penTypes, true)
		if not modName then
			return { }, line
		end
	elseif modForm == "REGENPERCENT" then
		modName = regenTypes[formCap[2]]
		if not modName then
			return { }, line
		end
		modSuffix = "Percent"
	elseif modForm == "REGENFLAT" then
		modName = regenTypes[formCap[2]]
		if not modName then
			return { }, line
		end
	elseif modForm == "DMG" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { damageType.."Min", damageType.."Max" }
	elseif modForm == "DMGATTACKS" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { flags = ModFlag.Attack }
	elseif modForm == "DMGSPELLS" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }		
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { flags = ModFlag.Spell }
	end

	-- Combine flags and tags
	local flags = 0
	local keywordFlags = 0
	local tagList = { }
	for _, data in pairs({ modName, modFlag, modTag, modTag2, skillTag }) do
		if type(data) == "table" then
			flags = bor(flags, data.flags or 0)
			keywordFlags = bor(keywordFlags, data.keywordFlags or 0)
			if data.tag then
				t_insert(tagList, copyTable(data.tag))
			end
		end
	end

	-- Generate modifier list
	local nameList = modName or ""
	local modList = { }
	for i, name in ipairs(type(nameList) == "table" and nameList or { nameList }) do
		modList[i] = {
			name = name .. modSuffix,
			type = modType,
			value = type(modValue) == "table" and modValue[i] or modValue,
			flags = flags,
			keywordFlags = keywordFlags,
			tagList = tagList,
		}
	end
	return modList, line:match("%S") and line
end

local cache = { }
local unsupported = { }
local count = 0
return function(line)
	if not cache[line] then
		cache[line] = { parseMod(line) }
		--[[if not cache[line][1] then
			local form = line:gsub("[%+%-]?%d+%.?%d*","{num}")
			if not unsupported[form] then
				unsupported[form] = true
				count = count + 1
				ConPrintf("%d %s", count, form)
			end
		end]]
	end
	return unpack(copyTable(cache[line]))
end