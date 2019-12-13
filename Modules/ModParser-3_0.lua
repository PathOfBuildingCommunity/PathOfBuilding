-- Path of Building
--
-- Module: Mod Parser for 3.0
-- Parser function for modifier names
--
local pairs = pairs
local ipairs = ipairs
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
	["^([%+%-]?[%d%.]+)%%? of"] = "BASE",
	["^([%+%-][%d%.]+)%%? base"] = "BASE",
	["^([%+%-]?[%d%.]+)%%? additional"] = "BASE",
	["(%d+) additional hits"] = "BASE",
	["^you gain ([%d%.]+)"] = "BASE",
	["^gains? ([%d%.]+)%% of"] = "BASE",
	["^([%+%-]?%d+)%% chance"] = "CHANCE",
	["^([%+%-]?%d+)%% additional chance"] = "CHANCE",
	["penetrates? (%d+)%%"] = "PEN",
	["penetrates (%d+)%% of"] = "PEN",
	["penetrates (%d+)%% of enemy"] = "PEN",
	["^([%d%.]+) (.+) regenerated per second"] = "REGENFLAT",
	["^([%d%.]+)%% (.+) regenerated per second"] = "REGENPERCENT",
	["^([%d%.]+)%% of (.+) regenerated per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+) (.+) per second"] = "REGENFLAT",
	["^regenerate ([%d%.]+)%% (.-) per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+)%% of (.-) per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+)%% of your (.-) per second"] = "REGENPERCENT",
	["^you regenerate ([%d%.]+)%% of (.+) per second"] = "REGENPERCENT",
	["^([%d%.]+) (%a+) damage taken per second"] = "DEGEN",
	["^([%d%.]+) (%a+) damage per second"] = "DEGEN",
	["(%d+) to (%d+) added (%a+) damage"] = "DMG",
	["(%d+)%-(%d+) added (%a+) damage"] = "DMG",
	["(%d+) to (%d+) additional (%a+) damage"] = "DMG",
	["(%d+)%-(%d+) additional (%a+) damage"] = "DMG",
	["^(%d+) to (%d+) (%a+) damage"] = "DMG",
	["adds (%d+) to (%d+) (%a+) damage"] = "DMG",
	["adds (%d+)%-(%d+) (%a+) damage"] = "DMG",
	["adds (%d+) to (%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) damage to attacks"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) attack damage"] = "DMGATTACKS",
	["adds (%d+)%-(%d+) (%a+) attack damage"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+)%-(%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) spell damage"] = "DMGSPELLS",
	["adds (%d+)%-(%d+) (%a+) spell damage"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) damage to attacks and spells"] = "DMGBOTH",
	["adds (%d+)%-(%d+) (%a+) damage to attacks and spells"] = "DMGBOTH",
	["adds (%d+) to (%d+) (%a+) damage to spells and attacks"] = "DMGBOTH", -- o_O
	["adds (%d+)%-(%d+) (%a+) damage to spells and attacks"] = "DMGBOTH", -- o_O
	["adds (%d+) to (%d+) (%a+) damage to hits"] = "DMGBOTH",
	["adds (%d+)%-(%d+) (%a+) damage to hits"] = "DMGBOTH",
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
	["mana regeneration"] = "ManaRegen",
	["mana regeneration rate"] = "ManaRegen",
	["mana cost"] = "ManaCost",
	["mana cost of"] = "ManaCost",
	["mana cost of skills"] = "ManaCost",
	["total mana cost"] = "ManaCost",
	["total mana cost of skills"] = "ManaCost",
	["mana reserved"] = "ManaReserved",
	["mana reservation"] = "ManaReserved",
	["mana reservation of skills"] = "ManaReserved",
	-- Primary defences
	["maximum energy shield"] = "EnergyShield",
	["energy shield recharge rate"] = "EnergyShieldRecharge",
	["start of energy shield recharge"] = "EnergyShieldRechargeFaster",
	["armour"] = "Armour",
	["evasion"] = "Evasion",
	["evasion rating"] = "Evasion",
	["energy shield"] = "EnergyShield",
	["armour and evasion"] = "ArmourAndEvasion",
	["armour and evasion rating"] = "ArmourAndEvasion",
	["evasion rating and armour"] = "ArmourAndEvasion",
	["armour and energy shield"] = "ArmourAndEnergyShield",
	["evasion rating and energy shield"] = "EvasionAndEnergyShield",
	["evasion and energy shield"] = "EvasionAndEnergyShield",
	["armour, evasion and energy shield"] = "Defences",
	["defences"] = "Defences",
	["to evade"] = "EvadeChance",
	["chance to evade"] = "EvadeChance",
	["to evade attacks"] = "EvadeChance",
	["chance to evade attacks"] = "EvadeChance",
	["chance to evade projectile attacks"] = "ProjectileEvadeChance",
	["chance to evade melee attacks"] = "MeleeEvadeChance",
	-- Resistances
	["physical damage reduction"] = "PhysicalDamageReduction",
	["physical damage reduction from hits"] = "PhysicalDamageReductionWhenHit",
	["fire resistance"] = "FireResist",
	["maximum fire resistance"] = "FireResistMax",
	["cold resistance"] = "ColdResist",
	["maximum cold resistance"] = "ColdResistMax",
	["lightning resistance"] = "LightningResist",
	["maximum lightning resistance"] = "LightningResistMax",
	["chaos resistance"] = "ChaosResist",
	["maximum chaos resistance"] = "ChaosResistMax",
	["fire and cold resistances"] = { "FireResist", "ColdResist" },
	["fire and lightning resistances"] = { "FireResist", "LightningResist" },
	["cold and lightning resistances"] = { "ColdResist", "LightningResist" },
	["elemental resistances"] = "ElementalResist",
	["all elemental resistances"] = "ElementalResist",
	["all resistances"] = { "ElementalResist", "ChaosResist" },
	["all maximum elemental resistances"] = "ElementalResistMax",
	["all maximum resistances"] = { "ElementalResistMax", "ChaosResistMax" },
	["fire and chaos resistances"] = { "FireResist", "ChaosResist" },
	["cold and chaos resistances"] = { "ColdResist", "ChaosResist" },
	["lightning and chaos resistances"] = { "LightningResist", "ChaosResist" },
	-- Damage taken
	["damage taken"] = "DamageTaken",
	["damage taken when hit"] = "DamageTakenWhenHit",
	["damage taken from damage over time"] = "DamageTakenOverTime",
	["physical damage taken"] = "PhysicalDamageTaken",
	["physical damage from hits taken"] = "PhysicalDamageTaken",
	["physical damage taken when hit"] = "PhysicalDamageTakenWhenHit",
	["physical damage taken over time"] = "PhysicalDamageTakenOverTime",
	["physical damage over time damage taken"] = "PhysicalDamageTakenOverTime",
	["lightning damage taken"] = "LightningDamageTaken",
	["lightning damage from hits taken"] = "LightningDamageTaken",
	["lightning damage taken when hit"] = "LightningDamageTakenWhenHit",
	["lightning damage taken over time"] = "LightningDamageTakenOverTime",
	["cold damage taken"] = "ColdDamageTaken",
	["cold damage from hits taken"] = "ColdDamageTaken",
	["cold damage taken when hit"] = "ColdDamageTakenWhenHit",
	["cold damage taken over time"] = "ColdDamageTakenOverTime",
	["fire damage taken"] = "FireDamageTaken",
	["fire damage from hits taken"] = "FireDamageTaken",
	["fire damage taken when hit"] = "FireDamageTakenWhenHit",
	["fire damage taken over time"] = "FireDamageTakenOverTime",
	["chaos damage taken"] = "ChaosDamageTaken",
	["chaos damage from hits taken"] = "ChaosDamageTaken",
	["chaos damage taken when hit"] = "ChaosDamageTakenWhenHit",
	["chaos damage taken over time"] = "ChaosDamageTakenOverTime",
	["chaos damage over time taken"] = "ChaosDamageTakenOverTime",
	["elemental damage taken"] = "ElementalDamageTaken",
	["elemental damage taken when hit"] = "ElementalDamageTakenWhenHit",
	["elemental damage taken over time"] = "ElementalDamageTakenOverTime",
	-- Other defences
	["to dodge attacks"] = "AttackDodgeChance",
	["to dodge attack hits"] = "AttackDodgeChance",
	["to dodge spells"] = "SpellDodgeChance",
	["to dodge spell hits"] = "SpellDodgeChance",
	["to dodge spell damage"] = "SpellDodgeChance",
	["to dodge attacks and spells"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to dodge attacks and spell damage"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to dodge attack and spell hits"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to block"] = "BlockChance",
	["to block attacks"] = "BlockChance",
	["to block attack damage"] = "BlockChance",
	["block chance"] = "BlockChance",
	["block chance with staves"] = { "BlockChance", tag = { type = "Condition", var = "UsingStaff" } },
	["to block with staves"] = { "BlockChance", tag = { type = "Condition", var = "UsingStaff" } },
	["spell block chance"] = "SpellBlockChance",
	["to block spells"] = "SpellBlockChance",
	["to block spell damage"] = "SpellBlockChance",
	["chance to block attacks and spells"] = { "BlockChance", "SpellBlockChance" },
	["maximum block chance"] = "BlockChanceMax",
	["maximum chance to block attack damage"] = "BlockChanceMax",
	["maximum chance to block spell damage"] = "SpellBlockChanceMax",
	["to avoid being stunned"] = "AvoidStun",
	["to avoid being shocked"] = "AvoidShock",
	["to avoid being frozen"] = "AvoidFrozen",
	["to avoid being chilled"] = "AvoidChilled",
	["to avoid being ignited"] = "AvoidIgnite",
	["to avoid elemental ailments"] = { "AvoidShock", "AvoidFrozen", "AvoidChilled", "AvoidIgnite" },
	["to avoid elemental status ailments"] = { "AvoidShock", "AvoidFrozen", "AvoidChilled", "AvoidIgnite" },
	["to avoid bleeding"] = "AvoidBleed",
	["to avoid being poisoned"] = "AvoidPoison",
	["damage is taken from mana before life"] = "DamageTakenFromManaBeforeLife",
	["damage taken from mana before life"] = "DamageTakenFromManaBeforeLife",
	["effect of curses on you"] = "CurseEffectOnSelf",
	["life recovery rate"] = "LifeRecoveryRate",
	["mana recovery rate"] = "ManaRecoveryRate",
	["energy shield recovery rate"] = "EnergyShieldRecoveryRate",
	["energy shield regeneration rate"] = "EnergyShieldRegen",
	["recovery rate of life, mana and energy shield"] = { "LifeRecoveryRate", "ManaRecoveryRate", "EnergyShieldRecoveryRate" },
	["recovery rate of life and energy shield"] = { "LifeRecoveryRate", "EnergyShieldRecoveryRate" },
	["maximum life, mana and global energy shield"] = { "Life", "Mana", "EnergyShield", tag = { type = "Global" } },
	-- Stun/knockback modifiers
	["stun recovery"] = "StunRecovery",
	["stun and block recovery"] = "StunRecovery",
	["block and stun recovery"] = "StunRecovery",
	["stun threshold"] = "StunThreshold",
	["block recovery"] = "BlockRecovery",
	["enemy stun threshold"] = "EnemyStunThreshold",
	["stun duration on enemies"] = "EnemyStunDuration",
	["stun duration"] = "EnemyStunDuration",
	["to knock enemies back on hit"] = "EnemyKnockbackChance",
	["knockback distance"] = "EnemyKnockbackDistance",
	-- Auras/curses/buffs
	["aura effect"] = "AuraEffect",
	["effect of non-curse auras you cast"] = "AuraEffect",
	["effect of non-curse auras from your skills"] = "AuraEffect",
	["effect of your curses"] = "CurseEffect",
	["effect of auras on you"] = "AuraEffectOnSelf",
	["effect of auras on your minions"] = { "AuraEffectOnSelf", addToMinion = true },
	["effect of auras from mines"] = { "AuraEffect", keywordFlags = KeywordFlag.Mine },
	["curse effect"] = "CurseEffect",
	["effect of curses applied by bane"] = { "CurseEffect", tag = { type = "Condition", var = "AppliedByBane" } },
	["curse duration"] = { "Duration", keywordFlags = KeywordFlag.Curse },
	["radius of auras"] = { "AreaOfEffect", keywordFlags = KeywordFlag.Aura },
	["radius of curses"] = { "AreaOfEffect", keywordFlags = KeywordFlag.Curse },
	["buff effect"] = "BuffEffect",
	["effect of buffs on you"] = "BuffEffectOnSelf",
	["effect of buffs granted by your golems"] = { "BuffEffect", tag = { type = "SkillType", skillType = SkillType.Golem } },
	["effect of buffs granted by socketed golem skills"] = { "BuffEffect", addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["effect of the buff granted by your stone golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["effect of the buff granted by your lightning golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["effect of the buff granted by your ice golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["effect of the buff granted by your flame golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["effect of the buff granted by your chaos golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["effect of the buff granted by your carrion golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Carrion Golem" } },
	["effect of offering spells"] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } } },
	["effect of offerings"] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } } },
	["effect of heralds on you"] = { "BuffEffect", tag = { type = "SkillType", skillType = SkillType.Herald } },
	["effect of buffs granted by your active ancestor totems"] = { "BuffEffect", skillNameList = { "Ancestral Warchief", "Ancestral Protector" } },
	["warcry effect"] = { "BuffEffect", keywordFlags = KeywordFlag.Warcry },
	["aspect of the avian buff effect"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Aspect of the Avian" } },
	-- Charges
	["maximum power charge"] = "PowerChargesMax",
	["maximum power charges"] = "PowerChargesMax",
	["minimum power charge"] = "PowerChargesMin",
	["minimum power charges"] = "PowerChargesMin",
	["power charge duration"] = "PowerChargesDuration",
	["maximum frenzy charge"] = "FrenzyChargesMax",
	["maximum frenzy charges"] = "FrenzyChargesMax",
	["minimum frenzy charge"] = "FrenzyChargesMin",
	["minimum frenzy charges"] = "FrenzyChargesMin",
	["frenzy charge duration"] = "FrenzyChargesDuration",
	["maximum endurance charge"] = "EnduranceChargesMax",
	["maximum endurance charges"] = "EnduranceChargesMax",
	["minimum endurance charge"] = "EnduranceChargesMin",
	["minimum endurance charges"] = "EnduranceChargesMin",
	["endurance charge duration"] = "EnduranceChargesDuration",
	["maximum frenzy charges and maximum power charges"] = { "FrenzyChargesMax", "PowerChargesMax" },
	["endurance, frenzy and power charge duration"] = { "PowerChargesDuration", "FrenzyChargesDuration", "EnduranceChargesDuration" },
	["maximum siphoning charge"] = "SiphoningChargesMax",
	["maximum siphoning charges"] = "SiphoningChargesMax",
	["maximum challenger charges"] = "ChallengerChargesMax",
	["maximum blitz charges"] = "BlitzChargesMax",
	["maximum number of crab barriers"] = "CrabBarriersMax",
	-- On hit/kill/leech effects
	["life gained on kill"] = "LifeOnKill",
	["mana gained on kill"] = "ManaOnKill",
	["life gained for each enemy hit"] = { "LifeOnHit" },
	["life gained for each enemy hit by attacks"] = { "LifeOnHit", flags = ModFlag.Attack },
	["life gained for each enemy hit by your attacks"] = { "LifeOnHit", flags = ModFlag.Attack },
	["life gained for each enemy hit by spells"] = { "LifeOnHit", flags = ModFlag.Spell },
	["life gained for each enemy hit by your spells"] = { "LifeOnHit", flags = ModFlag.Spell },
	["mana gained for each enemy hit by attacks"] = { "ManaOnHit", flags = ModFlag.Attack },
	["mana gained for each enemy hit by your attacks"] = { "ManaOnHit", flags = ModFlag.Attack },
	["energy shield gained for each enemy hit"] = { "EnergyShieldOnHit" },
	["energy shield gained for each enemy hit by attacks"] = { "EnergyShieldOnHit", flags = ModFlag.Attack },
	["energy shield gained for each enemy hit by your attacks"] = { "EnergyShieldOnHit", flags = ModFlag.Attack },
	["life and mana gained for each enemy hit"] = { "LifeOnHit", "ManaOnHit", flags = ModFlag.Attack },
	["damage as life"] = "DamageLifeLeech",
	["life leeched per second"] = "LifeLeechRate",
	["mana leeched per second"] = "ManaLeechRate",
	["total recovery per second from life leech"] = "LifeLeechRate",
	["total recovery per second from energy shield leech"] = "EnergyShieldLeechRate",
	["total recovery per second from mana leech"] = "ManaLeechRate",
	["maximum recovery per life leech"] = "MaxLifeLeechInstance",
	["maximum recovery per energy shield leech"] = "MaxEnergyShieldLeechInstance",
	["maximum recovery per mana leech"] = "MaxManaLeechInstance",
	["maximum total recovery per second from life leech"] = "MaxLifeLeechRate",
	["maximum total recovery per second from energy shield leech"] = "MaxEnergyShieldLeechRate",
	["maximum total recovery per second from mana leech"] = "MaxManaLeechRate",
	["to impale enemies on hit"] = "ImpaleChance",
    ["impale effect"] = "ImpaleEffect",
	-- Projectile modifiers
	["projectile"] = "ProjectileCount",
	["projectiles"] = "ProjectileCount",
	["projectile speed"] = "ProjectileSpeed",
	["arrow speed"] = { "ProjectileSpeed", flags = ModFlag.Bow },
	-- Totem/trap/mine modifiers
	["totem placement speed"] = "TotemPlacementSpeed",
	["totem life"] = "TotemLife",
	["totem duration"] = "TotemDuration",
	["maximum number of summoned totems"] = "ActiveTotemLimit",
	["maximum number of summoned totems."] = "ActiveTotemLimit", -- Mark plz
	["maximum number of summoned ballista totems"] = "ActiveTotemLimit", -- Mark plz
	["trap throwing speed"] = "TrapThrowingSpeed",
	["trap trigger area of effect"] = "TrapTriggerAreaOfEffect",
	["trap duration"] = "TrapDuration",
	["cooldown recovery speed for throwing traps"] = { "CooldownRecovery", keywordFlags = KeywordFlag.Trap },
	["mine laying speed"] = "MineLayingSpeed",
	["mine throwing speed"] = "MineLayingSpeed",
	["mine detonation area of effect"] = "MineDetonationAreaOfEffect",
	["mine duration"] = "MineDuration",
	-- Minion modifiers
	["maximum number of skeletons"] = "ActiveSkeletonLimit",
	["maximum number of zombies"] = "ActiveZombieLimit",
	["maximum number of raised zombies"] = "ActiveZombieLimit",
	["number of zombies allowed"] = "ActiveZombieLimit",
	["maximum number of spectres"] = "ActiveSpectreLimit",
	["maximum number of golems"] = "ActiveGolemLimit",
	["maximum number of summoned golems"] = "ActiveGolemLimit",
	["maximum number of summoned raging spirits"] = "ActiveRagingSpiritLimit",
	["maximum number of summoned holy relics"] = "ActiveHolyRelicLimit",
	["minion duration"] = { "Duration", tag = { type = "SkillType", skillType = SkillType.CreateMinion } },
	["skeleton duration"] = { "Duration", tag = { type = "SkillName", skillName = "Summon Skeleton" } },
	["sentinel of dominance duration"] = { "Duration", tag = { type = "SkillName", skillName = "Dominating Blow" } },
	-- Other skill modifiers
	["radius"] = "AreaOfEffect",
	["radius of area skills"] = "AreaOfEffect",
	["area of effect radius"] = "AreaOfEffect",
	["area of effect"] = "AreaOfEffect",
	["area of effect of skills"] = "AreaOfEffect",
	["area of effect of area skills"] = "AreaOfEffect",
	["aspect of the spider area of effect"] = { "AreaOfEffect", tag = { type = "SkillName", skillName = "Aspect of the Spider" } },
	["firestorm explosion area of effect"] = { "AreaOfEffectSecondary", tag = { type = "SkillName", skillName = "Firestorm" } },
	["duration"] = "Duration",
	["skill effect duration"] = "Duration",
	["chaos skill effect duration"] = { "Duration", keywordFlags = KeywordFlag.Chaos },
	["aspect of the spider debuff duration"] = { "Duration", tag = { type = "SkillName", skillName = "Aspect of the Spider" } },
	["fire trap burning ground duration"] = { "Duration", tag = { type = "SkillName", skillName = "Fire Trap" } },
	["cooldown recovery"] = "CooldownRecovery",
	["cooldown recovery speed"] = "CooldownRecovery",
	["weapon range"] = "WeaponRange",
	["melee range"] = "MeleeWeaponRange",
	["melee weapon range"] = "MeleeWeaponRange",
	["melee weapon and unarmed range"] = { "MeleeWeaponRange", "UnarmedRange" },
	["melee weapon and unarmed attack range"] = { "MeleeWeaponRange", "UnarmedRange" },
	["to deal double damage"] = "DoubleDamageChance",
	["activation frequency"] = "BrandActivationFrequency",
	["brand activation frequency"] = "BrandActivationFrequency",
	-- Buffs
	["onslaught effect"] = "OnslaughtEffect",
	["fortify duration"] = "FortifyDuration",
	["effect of fortify on you"] = "FortifyEffectOnSelf",
	["effect of tailwind on you"] = "TailwindEffectOnSelf",
	["elusive effect"] = "ElusiveEffect",
	["effect of elusive on you"] = "ElusiveEffect",
	-- Basic damage types
	["damage"] = "Damage",
	["physical damage"] = "PhysicalDamage",
	["lightning damage"] = "LightningDamage",
	["cold damage"] = "ColdDamage",
	["fire damage"] = "FireDamage",
	["chaos damage"] = "ChaosDamage",
	["non-chaos damage"] = "NonChaosDamage",
	["elemental damage"] = "ElementalDamage",
	-- Other damage forms
	["attack damage"] = { "Damage", flags = ModFlag.Attack },
	["attack physical damage"] = { "PhysicalDamage", flags = ModFlag.Attack },
	["physical attack damage"] = { "PhysicalDamage", flags = ModFlag.Attack },
	["minimum physical attack damage"] = { "MinPhysicalDamage", flags = ModFlag.Attack },
	["maximum physical attack damage"] = { "MaxPhysicalDamage", flags = ModFlag.Attack },
	["physical weapon damage"] = { "PhysicalDamage", flags = ModFlag.Weapon },
	["physical damage with weapons"] = { "PhysicalDamage", flags = ModFlag.Weapon },
	["physical melee damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["melee physical damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["projectile damage"] = { "Damage", flags = ModFlag.Projectile },
	["projectile attack damage"] = { "Damage", flags = bor(ModFlag.Projectile, ModFlag.Attack) },
	["bow damage"] = { "Damage", flags = ModFlag.Bow },
	["damage with arrow hits"] = { "Damage", flags = bor(ModFlag.Bow, ModFlag.Hit) },
	["wand damage"] = { "Damage", flags = ModFlag.Wand },
	["wand physical damage"] = { "PhysicalDamage", flags = ModFlag.Wand },
	["claw physical damage"] = { "PhysicalDamage", flags = ModFlag.Claw },
	["sword physical damage"] = { "PhysicalDamage", flags = ModFlag.Sword },
	["damage over time"] = { "Damage", flags = ModFlag.Dot },
	["physical damage over time"] = { "PhysicalDamage", keywordFlags = KeywordFlag.PhysicalDot },
	["burning damage"] = { "FireDamage", keywordFlags = KeywordFlag.FireDot },
	["damage with ignite"] = { "Damage", keywordFlags = KeywordFlag.Ignite },
	["damage with ignites"] = { "Damage", keywordFlags = KeywordFlag.Ignite },
	["incinerate damage for each stage"] = { "Damage", tagList = { { type = "Multiplier", var = "IncinerateStage" }, { type = "SkillName", skillName = "Incinerate" } } },
	["physical damage over time multiplier"] = "PhysicalDotMultiplier",
	["fire damage over time multiplier"] = "FireDotMultiplier",
	["cold damage over time multiplier"] = "ColdDotMultiplier",
	["chaos damage over time multiplier"] = "ChaosDotMultiplier",
	["damage over time multiplier"] = "DotMultiplier",
	-- Crit/accuracy/speed modifiers
	["critical strike chance"] = "CritChance",
	["attack critical strike chance"] = { "CritChance", flags = ModFlag.Attack },
	["critical strike multiplier"] = "CritMultiplier",
	["accuracy"] = "Accuracy",
	["accuracy rating"] = "Accuracy",
	["minion accuracy rating"] = { "Accuracy", addToMinion = true },
	["attack speed"] = { "Speed", flags = ModFlag.Attack },
	["cast speed"] = { "Speed", flags = ModFlag.Cast },
	["attack and cast speed"] = "Speed",
	["attack and movement speed"] = { "Speed", "MovementSpeed" },
	-- Elemental ailments
	["to shock"] = "EnemyShockChance",
	["shock chance"] = "EnemyShockChance",
	["to freeze"] = "EnemyFreezeChance",
	["freeze chance"] = "EnemyFreezeChance",
	["to ignite"] = "EnemyIgniteChance",
	["ignite chance"] = "EnemyIgniteChance",
	["to freeze, shock and ignite"] = { "EnemyFreezeChance", "EnemyShockChance", "EnemyIgniteChance" },
	["effect of shock"] = "EnemyShockEffect",
	["effect of chill"] = "EnemyChillEffect",
	["effect of chill on you"] = "SelfChillEffect",
	["effect of non-damaging ailments"] = { "EnemyShockEffect", "EnemyChillEffect", "EnemyFreezeEffech" },
	["shock duration"] = "EnemyShockDuration",
	["freeze duration"] = "EnemyFreezeDuration",
	["chill duration"] = "EnemyChillDuration",
	["ignite duration"] = "EnemyIgniteDuration",
	["duration of elemental ailments"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration" },
	["duration of elemental status ailments"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration" },
	["duration of ailments"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration", "EnemyPoisonDuration", "EnemyBleedDuration" },
	["duration of ailments you inflict"] = { "EnemyShockDuration", "EnemyFreezeDuration", "EnemyChillDuration", "EnemyIgniteDuration", "EnemyPoisonDuration", "EnemyBleedDuration" },
	-- Other ailments
	["to poison"] = "PoisonChance",
	["to cause poison"] = "PoisonChance",
	["to poison on hit"] = "PoisonChance",
	["poison duration"] = { "EnemyPoisonDuration" },
	["duration of poisons you inflict"] = { "EnemyPoisonDuration" },
	["to cause bleeding"] = "BleedChance",
	["to cause bleeding on hit"] = "BleedChance",
	["to inflict bleeding"] = "BleedChance",
	["to inflict bleeding on hit"] = "BleedChance",
	["bleed duration"] = { "EnemyBleedDuration" },
	["bleeding duration"] = { "EnemyBleedDuration" },
	-- Misc modifiers
	["movement speed"] = "MovementSpeed",
	["attack, cast and movement speed"] = { "Speed", "MovementSpeed" },
	["light radius"] = "LightRadius",
	["rarity of items found"] = "LootRarity",
	["quantity of items found"] = "LootQuantity",
	["item quantity"] = "LootQuantity",
	["strength requirement"] = "StrRequirement",
	["dexterity requirement"] = "DexRequirement",
	["intelligence requirement"] = "IntRequirement",
	["strength and intelligence requirement"] = { "StrRequirement", "IntRequirement" },
	["attribute requirements"] = { "StrRequirement", "DexRequirement", "IntRequirement" },
	["effect of socketed jewels"] = "SocketedJewelEffect",
	-- Flask modifiers
	["effect"] = "FlaskEffect",
	["effect of flasks"] = "FlaskEffect",
	["effect of flasks on you"] = "FlaskEffect",
	["amount recovered"] = "FlaskRecovery",
	["life recovered"] = "FlaskRecovery",
	["life recovery from flasks used"] = "FlaskLifeRecovery",
	["mana recovered"] = "FlaskRecovery",
	["life recovery from flasks"] = "FlaskLifeRecovery",
	["mana recovery from flasks"] = "FlaskManaRecovery",
	["flask effect duration"] = "FlaskDuration",
	["recovery speed"] = "FlaskRecoveryRate",
	["recovery rate"] = "FlaskRecoveryRate",
	["flask recovery rate"] = "FlaskRecoveryRate",
	["flask recovery speed"] = "FlaskRecoveryRate",
	["flask life recovery rate"] = "FlaskLifeRecoveryRate",
	["flask mana recovery rate"] = "FlaskManaRecoveryRate",
	["extra charges"] = "FlaskCharges",
	["maximum charges"] = "FlaskCharges",
	["charges used"] = "FlaskChargesUsed",
	["flask charges used"] = "FlaskChargesUsed",
	["flask charges gained"] = "FlaskChargesGained",
	["charge recovery"] = "FlaskChargeRecovery",
	["impales you inflict last"] = "ImpaleStacksMax",
}

-- List of modifier flags
local modFlagList = {
	-- Weapon types
	["with axes"] = { flags = ModFlag.Axe },
	["to axe attacks"] = { flags = ModFlag.Axe },
	["with bows"] = { flags = ModFlag.Bow },
	["to bow attacks"] = { flags = ModFlag.Bow },
	["with claws"] = { flags = ModFlag.Claw },
	["to claw attacks"] = { flags = ModFlag.Claw },
	["dealt with claws"] = { flags = ModFlag.Claw },
	["with daggers"] = { flags = ModFlag.Dagger },
	["to dagger attacks"] = { flags = ModFlag.Dagger },
	["with maces"] = { flags = ModFlag.Mace },
	["to mace attacks"] = { flags = ModFlag.Mace },
	["with maces and sceptres"] = { flags = ModFlag.Mace },
	["to mace and sceptre attacks"] = { flags = ModFlag.Mace },
	["with staves"] = { flags = ModFlag.Staff },
	["to staff attacks"] = { flags = ModFlag.Staff },
	["with swords"] = { flags = ModFlag.Sword },
	["to sword attacks"] = { flags = ModFlag.Sword },
	["with wands"] = { flags = ModFlag.Wand },
	["to wand attacks"] = { flags = ModFlag.Wand },
	["unarmed"] = { flags = ModFlag.Unarmed },
	["with unarmed attacks"] = { flags = ModFlag.Unarmed },
	["to unarmed attacks"] = { flags = ModFlag.Unarmed },
	["with one handed weapons"] = { flags = ModFlag.Weapon1H },
	["with one handed melee weapons"] = { flags = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee) },
	["with two handed weapons"] = { flags = ModFlag.Weapon2H },
	["with two handed melee weapons"] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee) },
	["with ranged weapons"] = { flags = ModFlag.WeaponRanged },
	-- Skill types
	["spell"] = { flags = ModFlag.Spell },
	["with spells"] = { flags = ModFlag.Spell },
	["for spells"] = { flags = ModFlag.Spell },
	["with attacks"] = { keywordFlags = KeywordFlag.Attack },
	["with attack skills"] = { keywordFlags = KeywordFlag.Attack },
	["for attacks"] = { flags = ModFlag.Attack },
	["weapon"] = { flags = ModFlag.Weapon },
	["with weapons"] = { flags = ModFlag.Weapon },
	["melee"] = { flags = ModFlag.Melee },
	["with melee attacks"] = { flags = ModFlag.Melee },
	["with melee critical strikes"] = { flags = ModFlag.Melee, tag = { type = "Condition", var = "CriticalStrike" } },
	["with bow skills"] = { keywordFlags = KeywordFlag.Bow },
	["on melee hit"] = { flags = ModFlag.Melee },
	["with hits"] = { keywordFlags = KeywordFlag.Hit },
	["with hits and ailments"] = { keywordFlags = bor(KeywordFlag.Hit, KeywordFlag.Ailment) },
	["with ailments"] = { flags = ModFlag.Ailment },
	["with ailments from attack skills"] = { flags = ModFlag.Ailment, keywordFlags = KeywordFlag.Attack },
	["with poison"] = { keywordFlags = KeywordFlag.Poison },
	["with bleeding"] = { keywordFlags = KeywordFlag.Bleed },
	["for ailments"] = { flags = ModFlag.Ailment },
	["for poison"] = { keywordFlags = KeywordFlag.Poison },
	["for bleeding"] = { keywordFlags = KeywordFlag.Bleed },
	["for ignite"] = { keywordFlags = KeywordFlag.Ignite },
	["area"] = { flags = ModFlag.Area },
	["mine"] = { keywordFlags = KeywordFlag.Mine },
	["with mines"] = { keywordFlags = KeywordFlag.Mine },
	["trap"] = { keywordFlags = KeywordFlag.Trap },
	["with traps"] = { keywordFlags = KeywordFlag.Trap },
	["for traps"] = { keywordFlags = KeywordFlag.Trap },
	["that place mines or throw traps"] = { keywordFlags = bor(KeywordFlag.Mine, KeywordFlag.Trap) },
	["that throw mines"] = { keywordFlags = KeywordFlag.Mine },
	["that throw traps"] = { keywordFlags = KeywordFlag.Trap },
	["totem"] = { keywordFlags = KeywordFlag.Totem },
	["with totem skills"] = { keywordFlags = KeywordFlag.Totem },
	["for skills used by totems"] = { keywordFlags = KeywordFlag.Totem },
	["of aura skills"] = { tag = { type = "SkillType", skillType = SkillType.Aura } },
	["of curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["with curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["of herald skills"] = { tag = { type = "SkillType", skillType = SkillType.Herald } },
	["minion skills"] = { tag = { type = "SkillType", skillType = SkillType.Minion } },
	["of minion skills"] = { tag = { type = "SkillType", skillType = SkillType.Minion } },
	["for curses"] = { keywordFlags = KeywordFlag.Curse },
	["warcry"] = { keywordFlags = KeywordFlag.Warcry },
	["vaal"] = { keywordFlags = KeywordFlag.Vaal },
	["vaal skill"] = { keywordFlags = KeywordFlag.Vaal },
	["with movement skills"] = { keywordFlags = KeywordFlag.Movement },
	["of movement skills"] = { keywordFlags = KeywordFlag.Movement },
	["of travel skills"] = { keywordFlags = KeywordFlag.Travel },
	["with lightning skills"] = { keywordFlags = KeywordFlag.Lightning },
	["with cold skills"] = { keywordFlags = KeywordFlag.Cold },
	["with fire skills"] = { keywordFlags = KeywordFlag.Fire },
	["with elemental skills"] = { keywordFlags = bor(KeywordFlag.Lightning, KeywordFlag.Cold, KeywordFlag.Fire) },
	["with chaos skills"] = { keywordFlags = KeywordFlag.Chaos },
	["with channelling skills"] = { tag = { type = "SkillType", skillType = SkillType.Channelled } },
	["with brand skills"] = { tag = { type = "SkillType", skillType = SkillType.Brand } },
	["zombie"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["raised zombie"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["skeleton"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Skeleton" } },
	["spectre"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre" } },
	["raised spectre"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre" } },
	["golem"] = { addToMinion = true, addToMinionTag = { type = "SkillType", skillType = SkillType.Golem } },
	["chaos golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["flame golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["increased flame golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["ice golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["lightning golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["stone golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["animated guardian"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Guardian" } },
	-- Other
	["global"] = { tag = { type = "Global" } },
	["from equipped shield"] = { tag = { type = "SlotName", slotName = "Weapon 2" } },
	["from body armour"] = { tag = { type = "SlotName", slotName = "Body Armour" } },
}

-- List of modifier flags/tags that appear at the start of a line
local preFlagList = {
	["^hits deal "] = { keywordFlags = KeywordFlag.Hit },
	["^critical strikes deal "] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["^minions "] = { addToMinion = true },
	["^minions [hd][ae][va][el] "] = { addToMinion = true },
	["^minions leech "] = { addToMinion = true },
	["^minions' attacks deal "] = { addToMinion = true, flags = ModFlag.Attack },
	["^golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillType", skillType = SkillType.Golem } },
	["^golem skills have "] = { tag = { type = "SkillType", skillType = SkillType.Golem } },
	["^zombies [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["^raised zombies [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie" } },
	["^skeletons [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Skeleton" } },
	["^raging spirits [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Raging Spirit" } },
	["^summoned raging spirits [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Raging Spirit" } },
	["^spectres [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre" } },
	["^chaos golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["^summoned chaos golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem" } },
	["^flame golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["^summoned flame golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem" } },
	["^ice golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["^summoned ice golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem" } },
	["^lightning golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["^summoned lightning golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem" } },
	["^stone golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["^summoned stone golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem" } },
	["^summoned carrion golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Carrion Golem" } },
	["^summoned skitterbots [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Carrion Golem" } },
	["^blink arrow and blink arrow clones [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Blink Arrow" } },
	["^mirror arrow and mirror arrow clones [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Mirror Arrow" } },
	["^animated weapons [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Weapon" } },
	["^animated guardian deals "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Guardian" } },
	["^summoned holy relics [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Holy Relic" } },
	["^agony crawler deals "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Herald of Agony" } },
	["^sentinels of purity deal "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Herald of Purity" } },
	["^raised zombies' slam attack has "] = { addToMinion = true, tag = { type = "SkillId", skillId = "ZombieSlam" } },
	["^attacks used by totems have "] = { keywordFlags = KeywordFlag.Totem },
	["^spells cast by totems have "] = { keywordFlags = KeywordFlag.Totem },
	["^attacks with this weapon "] = { tag = { type = "Condition", var = "{Hand}Attack" } },
	["^attacks with this weapon [hd][ae][va][el] "] = { tag = { type = "Condition", var = "{Hand}Attack" } },
	["^hits with this weapon [hd][ae][va][el] "] = { flags = ModFlag.Hit, tag = { type = "Condition", var = "{Hand}Attack" } },
	["^attacks [hd][ae][va][el] "] = { flags = ModFlag.Attack },
	["^attack skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Attack },
	["^spells [hd][ae][va][el] "] = { flags = ModFlag.Spell },
	["^spell skills [hd][ae][va][el] "] = { flags = ModFlag.Spell },
	["^projectile attack skills [hd][ae][va][el] "] = { tagList = { { type = "SkillType", skillType = SkillType.Attack }, { type = "SkillType", skillType = SkillType.Projectile } } },
	["^projectiles from attacks [hd][ae][va][el] "] = { tagList = { { type = "SkillType", skillType = SkillType.Attack }, { type = "SkillType", skillType = SkillType.Projectile } } },
	["^arrows [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Bow },
	["^bow attacks [hdf][aei][var][el] "] = { keywordFlags = KeywordFlag.Bow },
	["^projectiles [hdf][aei][var][el] "] = { flags = ModFlag.Projectile },
	["^melee attacks have "] = { flags = ModFlag.Melee },
	["^movement attack skills have "] = { flags = ModFlag.Attack, keywordFlags = KeywordFlag.Movement },
	["^travel skills have "] = { keywordFlags = KeywordFlag.Travel },
	["^trap and mine damage "] = { keywordFlags = bor(KeywordFlag.Trap, KeywordFlag.Mine) },
	["^skills used by traps [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Trap },
	["^skills used by mines [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Mine },
	["^lightning skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Lightning },
	["^lightning spells [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Lightning, flags = ModFlag.Spell },
	["^cold skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Cold },
	["^cold spells [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Cold, flags = ModFlag.Spell },
	["^fire skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Fire },
	["^fire spells [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Fire, flags = ModFlag.Spell },
	["^chaos skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Chaos },
	["^vaal skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Vaal },
	["^brand skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Brand } },
	["^channelling skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Channelled } },
	["^curse skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Curse } },
	["^melee skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Melee } },
	["^guard skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Guard } },
	["^skills [hdfg][aei][vari][eln] "] = { },
	["^left ring slot: "] = { tag = { type = "SlotNumber", num = 1 } },
	["^right ring slot: "] = { tag = { type = "SlotNumber", num = 2 } },
	["^socketed gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}" } },
	["^socketed skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}" } },
	["^socketed attacks [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "attack" } },
	["^socketed spells [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "spell" } },
	["^socketed curse gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "curse" } },
	["^socketed melee gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "melee" } },
	["^socketed golem gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["^socketed golem skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["^your flasks grant "] = { },
	["^when hit, "] = { },
	["^you and allies [hgd][ae][via][enl] "] = { },
	["^auras from your skills grant "] = { addToAura = true },
	["^you and nearby allies [hgd][ae][via][enl] "] = { newAura = true },
	["^nearby allies [hgd][ae][via][enl] "] = { newAura = true, newAuraOnlyAllies = true },
	["^you and allies affected by auras from your skills [hgd][ae][via][enl] "] = { affectedByAura = true },
	["^take "] = { modSuffix = "Taken" },
	["^marauder: melee skills have "] = { flags = ModFlag.Melee, tag = { type = "Condition", var = "ConnectedToMarauderStart" } },
	["^duelist: "] = { tag = { type = "Condition", var = "ConnectedToDuelistStart" } },
	["^ranger: "] = { tag = { type = "Condition", var = "ConnectedToRangerStart" } },
	["^shadow: "] = { tag = { type = "Condition", var = "ConnectedToShadowStart" } },
	["^witch: "] = { tag = { type = "Condition", var = "ConnectedToWitchStart" } },
	["^templar: "] = { tag = { type = "Condition", var = "ConnectedToTemplarStart" } },
	["^scion: "] = { tag = { type = "Condition", var = "ConnectedToScionStart" } },
}

-- List of modifier tags
local modTagList = {
	["on enemies"] = { },
	["while active"] = { },
	[" on critical strike"] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["from critical strikes"] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["while affected by auras you cast"] = { affectedByAura = true },
	["for you and nearby allies"] = { newAura = true },
	-- Multipliers
	["per power charge"] = { tag = { type = "Multiplier", var = "PowerCharge" } },
	["per frenzy charge"] = { tag = { type = "Multiplier", var = "FrenzyCharge" } },
	["per endurance charge"] = { tag = { type = "Multiplier", var = "EnduranceCharge" } },
	["per siphoning charge"] = { tag = { type = "Multiplier", var = "SiphoningCharge" } },
	["per challenger charge"] = { tag = { type = "Multiplier", var = "ChallengerCharge" } },
	["per blitz charge"] = { tag = { type = "Multiplier", var = "BlitzCharge" } },
	["per ghost shroud"] = { tag = { type = "Multiplier", var = "GhostShroud" } },
	["per crab barrier"] = { tag = { type = "Multiplier", var = "CrabBarrier" } },
	["per (%d+) rage"] = function(num) return { tag = { type = "Multiplier", var = "Rage", div = num } } end,
	["per level"] = { tag = { type = "Multiplier", var = "Level" } },
	["per (%d+) player levels"] = function(num) return { tag = { type = "Multiplier", var = "Level", div = num } } end,
	["for each normal item equipped"] = { tag = { type = "Multiplier", var = "NormalItem" } },
	["for each magic item equipped"] = { tag = { type = "Multiplier", var = "MagicItem" } },
	["for each rare item equipped"] = { tag = { type = "Multiplier", var = "RareItem" } },
	["for each unique item equipped"] = { tag = { type = "Multiplier", var = "UniqueItem" } },
	["per elder item equipped"] = { tag = { type = "Multiplier", var = "ElderItem" } },
	["per shaper item equipped"] = { tag = { type = "Multiplier", var = "ShaperItem" } },
	["per elder or shaper item equipped"] = { tag = { type = "Multiplier", varList = { "ElderItem", "ShaperItem" } } },
	["for each corrupted item equipped"] = { tag = { type = "Multiplier", var = "CorruptedItem" } },
	["for each uncorrupted item equipped"] = { tag = { type = "Multiplier", var = "NonCorruptedItem" } },
	["per abyssa?l? jewel affecting you"] = { tag = { type = "Multiplier", var = "AbyssJewel" } },
	["for each type of abyssa?l? jewel affecting you"] = { tag = { type = "Multiplier", var = "AbyssJewelType" } },
	["per sextant affecting the area"] = { tag = { type = "Multiplier", var = "Sextant" } },
	["per buff on you"] = { tag = { type = "Multiplier", var = "BuffOnSelf" } },
	["per curse on enemy"] = { tag = { type = "Multiplier", var = "CurseOnEnemy" } },
	["for each curse on enemy"] = { tag = { type = "Multiplier", var = "CurseOnEnemy" } },
	["per curse on you"] = { tag = { type = "Multiplier", var = "CurseOnSelf" } },
	["per poison on you"] = { tag = { type = "Multiplier", var = "PoisonStack" } },
	["per poison on you, up to (%d+) per second"] = function(num) return { tag = { type = "Multiplier", var = "PoisonStack", limit = tonumber(num), limitTotal = true } } end,
	["for each poison you have inflicted recently"] = { tag = { type = "Multiplier", var = "PoisonAppliedRecently" } },
	["for each shocked enemy you've killed recently"] = { tag = { type = "Multiplier", var = "ShockedEnemyKilledRecently" } },
	["per enemy killed recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "EnemyKilledRecently", limit = tonumber(num), limitTotal = true } } end,
	["for each enemy you or your minions have killed recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", varList = {"EnemyKilledRecently","EnemyKilledByMinionsRecently"}, limit = tonumber(num), limitTotal = true } } end,
	["for each enemy you or your minions have killed recently, up to (%d+)%% per second"] = function(num) return { tag = { type = "Multiplier", varList = {"EnemyKilledRecently","EnemyKilledByMinionsRecently"}, limit = tonumber(num), limitTotal = true } } end,
	["per enemy killed by you or your totems recently"] = { tag = { type = "Multiplier", varList = {"EnemyKilledRecently","EnemyKilledByTotemsRecently"} } },
	["per nearby enemy, up to %+?(%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "NearbyEnemy", limit = num, limitTotal = true } } end,
	["to you and allies"] = { },
	["per red socket"] = { tag = { type = "Multiplier", var = "RedSocketIn{SlotName}" } },
	["per green socket"] = { tag = { type = "Multiplier", var = "GreenSocketIn{SlotName}" } },
	["per blue socket"] = { tag = { type = "Multiplier", var = "BlueSocketIn{SlotName}" } },
	["per white socket"] = { tag = { type = "Multiplier", var = "WhiteSocketIn{SlotName}" } },
	["for each impale on enemy"] = { tag = { type = "Multiplier", var = "ImpaleStacks", actor = "enemy" }},
	["per animated weapon"] = { tag = { type = "Multiplier", var = "AnimatedWeapon", actor = "parent" }},
	-- Per stat
	["per (%d+) strength"] = function(num) return { tag = { type = "PerStat", stat = "Str", div = num } } end,
	["per (%d+) dexterity"] = function(num) return { tag = { type = "PerStat", stat = "Dex", div = num } } end,
	["per (%d+) intelligence"] = function(num) return { tag = { type = "PerStat", stat = "Int", div = num } } end,
	["per (%d+) total attributes"] = function(num) return { tag = { type = "PerStat", statList = { "Str", "Dex", "Int" }, div = num } } end,
	["per (%d+) of your lowest attribute"] = function(num) return { tag = { type = "PerStat", stat = "LowestAttribute", div = num } } end,
	["per (%d+) unreserved maximum mana, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "ManaUnreserved", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "Evasion", div = num } } end,
	["per (%d+) evasion rating, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "Evasion", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) maximum energy shield"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShield", div = num } } end,
	["per (%d+) maximum life"] = function(num) return { tag = { type = "PerStat", stat = "Life", div = num } } end,
	["per (%d+) maximum mana, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "Mana", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) accuracy rating"] = function(num) return { tag = { type = "PerStat", stat = "Accuracy", div = num } } end,
	["per (%d+)%% block chance"] = function(num) return { tag = { type = "PerStat", stat = "BlockChance", div = num } } end,
	["per (%d+)%% chance to block attack damage"] = function(num) return { tag = { type = "PerStat", stat = "BlockChance", div = num } } end,
	["per (%d+)%% chance to block spell damage"] = function(num) return { tag = { type = "PerStat", stat = "SpellBlockChance", div = num } } end,
	["per (%d+) of the lowest of armour and evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "LowestOfArmourAndEvasion", div = num } } end,
	["per (%d+) maximum energy shield on helmet"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShieldOnHelmet", div = num } } end,
	["per (%d+) evasion rating on body armour"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnBody Armour", div = num } } end,
	["per (%d+) armour on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "ArmourOnWeapon 2", div = num } } end,
	["per (%d+) evasion rating on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnWeapon 2", div = num } } end,
	["per (%d+) maximum energy shield on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShieldOnWeapon 2", div = num } } end,
	["per (%d+)%% cold resistance above 75%%"] = function(num) return { tag  = { type = "PerStat", stat = "ColdResistOver75", div = num } } end,
	["per (%d+)%% lightning resistance above 75%%"] = function(num) return { tag  = { type = "PerStat", stat = "LightningResistOver75", div = num } } end,
	["per totem"] = { tag = { type = "PerStat", stat = "ActiveTotemLimit" } },
	["per summoned totem"] = { tag = { type = "PerStat", stat = "ActiveTotemLimit" } },
	["for each time they have chained"] = { tag = { type = "PerStat", stat = "Chain" } },
	["for each time it has chained"] = { tag = { type = "PerStat", stat = "Chain" } },
	["for each summoned golem"] = { tag = { type = "PerStat", stat = "ActiveGolemLimit" } },
	["for each golem you have summoned"] = { tag = { type = "PerStat", stat = "ActiveGolemLimit" } },
	["per summoned golem"] = { tag = { type = "PerStat", stat = "ActiveGolemLimit" } },
	-- Stat conditions
	["with (%d+) or more strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["with at least (%d+) strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["w?h?i[lf]e? you have at least (%d+) strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["w?h?i[lf]e? you have at least (%d+) dexterity"] = function(num) return { tag = { type = "StatThreshold", stat = "Dex", threshold = num } } end,
	["w?h?i[lf]e? you have at least (%d+) intelligence"] = function(num) return { tag = { type = "StatThreshold", stat = "Int", threshold = num } } end,
	["at least (%d+) intelligence"] = function(num) return { tag = { type = "StatThreshold", stat = "Int", threshold = num } } end, -- lol
	["if dexterity is higher than intelligence"] = { tag = { type = "StatThreshold", var = "DexHigherThanInt" } },
	["if strength is higher than intelligence"] = { tag = { type = "StatThreshold", var = "StrHigherThanInt" } },
	["w?h?i[lf]e? you have at least (%d+) maximum energy shield"] = function(num) return { tag = { type = "StatThreshold", stat = "EnergyShield", threshold = num } } end,
	["against targets they pierce"] = { tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	["against pierced targets"] = { tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	["to targets they pierce"] = { tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	-- Slot conditions
	["when in main hand"] = { tag = { type = "SlotNumber", num = 1 } },
	["when in off hand"] = { tag = { type = "SlotNumber", num = 2 } },
	["in main hand"] = { tag = { type = "InSlot", num = 1 } },
	["in off hand"] = { tag = { type = "InSlot", num = 2 } },
	["with main hand"] = { tag = { type = "Condition", var = "MainHandAttack" } },
	["with off hand"] = { tag = { type = "Condition", var = "OffHandAttack" } },
	["with this weapon"] = { tag = { type = "Condition", var = "{Hand}Attack" } },
	["if your other ring is a shaper item"] = { tag = { type = "Condition", var = "ShaperItemInRing {OtherSlotNum}" } },
	["if your other ring is an elder item"] = { tag = { type = "Condition", var = "ElderItemInRing {OtherSlotNum}" } },
	-- Equipment conditions
	["while holding a shield"] = { tag = { type = "Condition", var = "UsingShield" } },
	["while your off hand is empty"] = { tag = { type = "Condition", var = "OffHandIsEmpty" } },
	["with shields"] = { tag = { type = "Condition", var = "UsingShield" } },
	["while dual wielding"] = { tag = { type = "Condition", var = "DualWielding" } },
	["while dual wielding claws"] = { tag = { type = "Condition", var = "DualWieldingClaws" } },
	["while dual wielding or holding a shield"] = { tag = { type = "Condition", varList = { "DualWielding", "UsingShield" } } },
	["while wielding an axe"] = { tag = { type = "Condition", var = "UsingAxe" } },
	["while wielding a bow"] = { tag = { type = "Condition", var = "UsingBow" } },
	["while wielding a claw"] = { tag = { type = "Condition", var = "UsingClaw" } },
	["while wielding a dagger"] = { tag = { type = "Condition", var = "UsingDagger" } },
	["while wielding a mace"] = { tag = { type = "Condition", var = "UsingMace" } },
	["while wielding a mace or sceptre"] = { tag = { type = "Condition", var = "UsingMace" } },
	["while wielding a staff"] = { tag = { type = "Condition", var = "UsingStaff" } },
	["while wielding a sword"] = { tag = { type = "Condition", var = "UsingSword" } },
	["while wielding a melee weapon"] = { tag = { type = "Condition", var = "UsingMeleeWeapon" } },
	["while wielding a one handed weapon"] = { tag = { type = "Condition", var = "UsingOneHandedWeapon" } },
	["while wielding a two handed weapon"] = { tag = { type = "Condition", var = "UsingTwoHandedWeapon" } },
	["while wielding a wand"] = { tag = { type = "Condition", var = "UsingWand" } },
	["while unarmed"] = { tag = { type = "Condition", var = "Unarmed" } },
	["with a normal item equipped"] = { tag = { type = "MultiplierThreshold", var = "NormalItem", threshold = 1 } },
	["with a magic item equipped"] = { tag = { type = "MultiplierThreshold", var = "MagicItem", threshold = 1 } },
	["with a rare item equipped"] = { tag = { type = "MultiplierThreshold", var = "RareItem", threshold = 1 } },
	["with a unique item equipped"] = { tag = { type = "MultiplierThreshold", var = "UniqueItem", threshold = 1 } },
	["if you wear no corrupted items"] = { tag = { type = "MultiplierThreshold", var = "CorruptedItem", threshold = 0, upper = true } },
	["if no worn items are corrupted"] = { tag = { type = "MultiplierThreshold", var = "CorruptedItem", threshold = 0, upper = true } },
	["if no equipped items are corrupted"] = { tag = { type = "MultiplierThreshold", var = "CorruptedItem", threshold = 0, upper = true } },
	["if all worn items are corrupted"] = { tag = { type = "MultiplierThreshold", var = "NonCorruptedItem", threshold = 0, upper = true } },
	["if all equipped items are corrupted"] = { tag = { type = "MultiplierThreshold", var = "NonCorruptedItem", threshold = 0, upper = true } },
	["if equipped shield has at least (%d+)%% chance to block"] = function(num) return { tag = { type = "StatThreshold", stat = "ShieldBlockChance", threshold = num } } end,
	["if you have (%d+) primordial items socketed or equipped"] = function(num) return { tag = { type = "MultiplierThreshold", var = "PrimordialItem", threshold = num } } end,
	-- Player status conditions
	["wh[ie][ln]e? on low life"] = { tag = { type = "Condition", var = "LowLife" } },
	["wh[ie][ln]e? not on low life"] = { tag = { type = "Condition", var = "LowLife", neg = true } },
	["wh[ie][ln]e? on full life"] = { tag = { type = "Condition", var = "FullLife" } },
	["wh[ie][ln]e? not on full life"] = { tag = { type = "Condition", var = "FullLife", neg = true } },
	["wh[ie][ln]e? no life is reserved"] = { tag = { type = "StatThreshold", stat = "LifeReserved", threshold = 0, upper = true } },
	["wh[ie][ln]e? no mana is reserved"] = { tag = { type = "StatThreshold", stat = "ManaReserved", threshold = 0, upper = true } },
	["wh[ie][ln]e? on full energy shield"] = { tag = { type = "Condition", var = "FullEnergyShield" } },
	["wh[ie][ln]e? not on full energy shield"] = { tag = { type = "Condition", var = "FullEnergyShield", neg = true } },
	["wh[ie][ln]e? you have energy shield"] = { tag = { type = "Condition", var = "HaveEnergyShield" } },
	["if you have energy shield"] = { tag = { type = "Condition", var = "HaveEnergyShield" } },
	["while stationary"] = { tag = { type = "Condition", var = "Stationary" } },
	["while moving"] = { tag = { type = "Condition", var = "Moving" } },
	["while channelling"] = { tag = { type = "Condition", var = "Channelling" } },
	["while you have no power charges"] = { tag = { type = "StatThreshold", stat = "PowerCharges", threshold = 0, upper = true } },
	["while you have no frenzy charges"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", threshold = 0, upper = true } },
	["while you have no endurance charges"] = { tag = { type = "StatThreshold", stat = "EnduranceCharges", threshold = 0, upper = true } },
	["while you have a power charge"] = { tag = { type = "StatThreshold", stat = "PowerCharges", threshold = 1 } },
	["while you have a frenzy charge"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", threshold = 1 } },
	["while you have an endurance charge"] = { tag = { type = "StatThreshold", stat = "EnduranceCharges", threshold = 1 } },
	["while at maximum power charges"] = { tag = { type = "StatThreshold", stat = "PowerCharges", thresholdStat = "PowerChargesMax" } },
	["while at maximum frenzy charges"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" } },
	["while at maximum endurance charges"] = { tag = { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" } },
	["while you have at least (%d+) crab barriers"] = function(num) return { tag = { type = "StatThreshold", stat = "CrabBarriers", threshold = num } } end,
	["while you have a totem"] = { tag = { type = "Condition", var = "HaveTotem" } },
	["while you have at least one nearby ally"] = { tag = { type = "MultiplierThreshold", var = "NearbyAlly", threshold = 1 } },
	["while you have fortify"] = { tag = { type = "Condition", var = "Fortify" } },
	["during onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while you have onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while phasing"] = { tag = { type = "Condition", var = "Phasing" } },
	["while you have tailwind"] = { tag = { type = "Condition", var = "Tailwind" } },
	["while elusive"] = { tag = { type = "Condition", var = "Elusive" } },
	["gain elusive"] = { tag = { type = "Condition", varList = { "CanBeElusive", "Elusive" } } },
	["while you have arcane surge"] = { tag = { type = "Condition", var = "AffectedByArcaneSurge" } },
	["while you have cat's stealth"] = { tag = { type = "Condition", var = "AffectedByCat'sStealth" } },
	["while you have avian's might"] = { tag = { type = "Condition", var = "AffectedByAvian'sMight" } },
	["while you have avian's flight"] = { tag = { type = "Condition", var = "AffectedByAvian'sFlight" } },
	["while affected by aspect of the cat"] = { tag = { type = "Condition", varList = { "AffectedByCat'sStealth", "AffectedByCat'sAgility" } } },
	["while you have a bestial minion"] = { tag = { type = "Condition", var = "HaveBestialMinion" } },
	["while focussed"] = { tag = { type = "Condition", var = "Focused" } },
	["while leeching"] = { tag = { type = "Condition", var = "Leeching" } },
	["while leeching energy shield"] = { tag = { type = "Condition", var = "LeechingEnergyShield" } },
	["while using a flask"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during flask effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during any flask effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["while on consecrated ground"] = { tag = { type = "Condition", var = "OnConsecratedGround" } },
	["on burning ground"] = { tag = { type = "Condition", var = "OnBurningGround" } },
	["while on burning ground"] = { tag = { type = "Condition", var = "OnBurningGround" } },
	["on chilled ground"] = { tag = { type = "Condition", var = "OnChilledGround" } },
	["on shocked ground"] = { tag = { type = "Condition", var = "OnShockedGround" } },
	["while in a caustic cloud"] = { tag = { type = "Condition", var = "OnCausticCloud" } },
	["while ignited"] = { tag = { type = "Condition", var = "Ignited" } },
	["while frozen"] = { tag = { type = "Condition", var = "Frozen" } },
	["while shocked"] = { tag = { type = "Condition", var = "Shocked" } },
	["while not ignited, frozen or shocked"] = { tag = { type = "Condition", varList = { "Ignited", "Frozen", "Shocked" }, neg = true } },
	["while bleeding"] = { tag = { type = "Condition", var = "Bleeding" } },
	["while poisoned"] = { tag = { type = "Condition", var = "Poisoned" } },
	["while cursed"] = { tag = { type = "Condition", var = "Cursed" } },
	["while not cursed"] = { tag = { type = "Condition", var = "Cursed", neg = true } },
	["against damage over time"] = { tag = { type = "Condition", varList = { "AgainstDamageOverTime" } } },
	["while there is only one nearby enemy"] = { tag = { type = "Condition", var = "OnlyOneNearbyEnemy" } },
	["while t?h?e?r?e? ?i?s? ?a rare or unique enemy i?s? ?nearby"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	["if you[' ]h?a?ve hit recently"] = { tag = { type = "Condition", var = "HitRecently" } },
	["if you[' ]h?a?ve hit an enemy recently"] = { tag = { type = "Condition", var = "HitRecently" } },
	["if you[' ]h?a?ve hit a cursed enemy recently"] = { tagList = { { type = "Condition", var = "HitRecently" }, { type = "ActorCondition", actor = "enemy", var = "Cursed" } } },
	["if you[' ]h?a?ve crit recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you[' ]h?a?ve dealt a critical strike recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you[' ]h?a?ve crit in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if you[' ]h?a?ve dealt a crit in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if you[' ]h?a?ve dealt a critical strike in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if you haven't crit recently"] = { tag = { type = "Condition", var = "CritRecently", neg = true } },
	["if you haven't dealt a critical strike recently"] = { tag = { type = "Condition", var = "CritRecently", neg = true } },
	["if you[' ]h?a?ve dealt a non%-critical strike recently"] = { tag = { type = "Condition", var = "NonCritRecently" } },
	["if your skills have dealt a critical strike recently"] = { tag = { type = "Condition", var = "SkillCritRecently" } },
	["if you[' ]h?a?ve killed recently"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["if you haven't killed recently"] = { tag = { type = "Condition", var = "KilledRecently", neg = true } },
	["if you or your totems have killed recently"] = { tag = { type = "Condition", varList = {"KilledRecently","TotemsKilledRecently"} } },
	["if you[' ]h?a?ve killed a maimed enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "ActorCondition", actor = "enemy", var = "Maimed" } } },
	["if you[' ]h?a?ve killed a cursed enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "ActorCondition", actor = "enemy", var = "Cursed" } } },
	["if you[' ]h?a?ve killed a bleeding enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "ActorCondition", actor = "enemy", var = "Bleeding" } } },
	["if you[' ]h?a?ve killed an enemy affected by your damage over time recently"] = { tag = { type = "Condition", var = "KilledAffectedByDotRecently" } },
	["if you[' ]h?a?ve frozen an enemy recently"] = { tag = { type = "Condition", var = "FrozenEnemyRecently" } },
	["if you[' ]h?a?ve ignited an enemy recently"] = { tag = { type = "Condition", var = "IgnitedEnemyRecently" } },
	["if you[' ]h?a?ve shocked an enemy recently"] = { tag = { type = "Condition", var = "ShockedEnemyRecently" } },
	["if you[' ]h?a?ve been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were damaged by a hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you[' ]h?a?ve taken a critical strike recently"] = { tag = { type = "Condition", var = "BeenCritRecently" } },
	["if you[' ]h?a?ve taken a savage hit recently"] = { tag = { type = "Condition", var = "BeenSavageHitRecently" } },
	["if you have ?n[o']t been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you[' ]h?a?ve taken no damage from hits recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you[' ]h?a?ve taken fire damage from a hit recently"] = { tag = { type = "Condition", var = "HitByFireDamageRecently" } },
	["if you[' ]h?a?ve taken spell damage recently"] = { tag = { type = "Condition", var = "HitBySpellDamageRecently" } },
	["if you[' ]h?a?ve blocked recently"] = { tag = { type = "Condition", var = "BlockedRecently" } },
	["if you[' ]h?a?ve blocked an attack recently"] = { tag = { type = "Condition", var = "BlockedAttackRecently" } },
	["if you[' ]h?a?ve blocked a spell recently"] = { tag = { type = "Condition", var = "BlockedSpellRecently" } },
	["if you[' ]h?a?ve blocked damage from a unique enemy in the past 10 seconds"] = { tag = { type = "Condition", var = "BlockedHitFromUniqueEnemyInPast10Sec" } },
	["if you[' ]h?a?ve attacked recently"] = { tag = { type = "Condition", var = "AttackedRecently" } },
	["if you[' ]h?a?ve cast a spell recently"] = { tag = { type = "Condition", var = "CastSpellRecently" } },
	["if you[' ]h?a?ve consumed a corpse recently"] = { tag = { type = "Condition", var = "ConsumedCorpseRecently" } },
	["for each corpse consumed recently"] = { tag = { type = "Multiplier", var = "CorpseConsumedRecently" } },
	["if you[' ]h?a?ve taunted an enemy recently"] = { tag = { type = "Condition", var = "TauntedEnemyRecently" } },
	["if you[' ]h?a?ve used a skill recently"] = { tag = { type = "Condition", var = "UsedSkillRecently" } },
	["for each skill you've used recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "SkillUsedRecently", limit = num, limitTotal = true } } end,
	["if you[' ]h?a?ve used a warcry recently"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["if you[' ]h?a?ve warcried recently"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["for each of your mines detonated recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "MineDetonatedRecently", limit = num, limitTotal = true } } end,
	["for each mine detonated recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "MineDetonatedRecently", limit = num, limitTotal = true } } end,
	["for each mine detonated recently, up to (%d+)%% per second"] = function(num) return { tag = { type = "Multiplier", var = "MineDetonatedRecently", limit = num, limitTotal = true } } end,
	["for each of your traps triggered recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "TrapTriggeredRecently", limit = num, limitTotal = true } } end,
	["for each trap triggered recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "TrapTriggeredRecently", limit = num, limitTotal = true } } end,
	["for each trap triggered recently, up to (%d+)%% per second"] = function(num) return { tag = { type = "Multiplier", var = "TrapTriggeredRecently", limit = num, limitTotal = true } } end,
	["if you[' ]h?a?ve used a fire skill recently"] = { tag = { type = "Condition", var = "UsedFireSkillRecently" } },
	["if you[' ]h?a?ve used a cold skill recently"] = { tag = { type = "Condition", var = "UsedColdSkillRecently" } },
	["if you[' ]h?a?ve used a fire skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedFireSkillInPast10Sec" } },
	["if you[' ]h?a?ve used a cold skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedColdSkillInPast10Sec" } },
	["if you[' ]h?a?ve used a lightning skill in the past 10 seconds"] = { tag = { type = "Condition", var = "UsedLightningSkillInPast10Sec" } },
	["if you[' ]h?a?ve summoned a totem recently"] = { tag = { type = "Condition", var = "SummonedTotemRecently" } },
	["if you[' ]h?a?ve used a minion skill recently"] = { tag = { type = "Condition", var = "UsedMinionSkillRecently" } },
	["if you[' ]h?a?ve used a movement skill recently"] = { tag = { type = "Condition", var = "UsedMovementSkillRecently" } },
	["if you[' ]h?a?ve used a vaal skill recently"] = { tag = { type = "Condition", var = "UsedVaalSkillRecently" } },
	["if you've impaled an enemy recently"] = { tag = { type = "Condition", var = "ImpaledRecently" } },
	["during soul gain prevention"] = { tag = { type = "Condition", var = "SoulGainPrevention" } },
	["if you detonated mines recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["if you detonated a mine recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["if energy shield recharge has started recently"] = { tag = { type = "Condition", var = "EnergyShieldRechargeRecently" } },
	["when cast on frostbolt"] = { tag = { type = "Condition", var = "CastOnFrostbolt" } },
	["branded enemy's"] = { tag = { type = "Condition", var = "BrandAttachedToEnemy" } },
	["to enemies they're attached to"] = { tag = { type = "Condition", var = "BrandAttachedToEnemy" } },
	["for each hit you've taken recently up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "BeenHitRecently", limit = num, limitTotal = true } } end,
	["for each nearby enemy, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "NearbyEnemies", limit = num, limitTotal = true } } end,
	["while you have iron reflexes"] = { tag = { type = "Condition", var = "HaveIronReflexes" } },
	["while you do not have iron reflexes"] = { tag = { type = "Condition", var = "HaveIronReflexes", neg = true } },
	["while you have elemental overload"] = { tag = { type = "Condition", var = "HaveElementalOverload" } },
	["while you do not have elemental overload"] = { tag = { type = "Condition", var = "HaveElementalOverload", neg = true } },
	["while you have resolute technique"] = { tag = { type = "Condition", var = "HaveResoluteTechnique" } },
	["while you do not have resolute technique"] = { tag = { type = "Condition", var = "HaveResoluteTechnique", neg = true } },
	["while you have avatar of fire"] = { tag = { type = "Condition", var = "HaveAvatarOfFire" } },
	["while you do not have avatar of fire"] = { tag = { type = "Condition", var = "HaveAvatarOfFire", neg = true } },
	["if you have a summoned golem"] = { tag = { type = "Condition", varList = { "HavePhysicalGolem", "HaveLightningGolem", "HaveColdGolem", "HaveFireGolem", "HaveChaosGolem", "HaveCarrionGolem" } } },
	-- Enemy status conditions
	["at close range"] = { tag = { type = "Condition", var = "AtCloseRange" }, flags = ModFlag.Hit },
	["against rare and unique enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }, keywordFlags = KeywordFlag.Hit },
	["against unique enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }, keywordFlags = KeywordFlag.Hit },
	["against enemies on full life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "FullLife" }, keywordFlags = KeywordFlag.Hit },
	["against enemies that are on full life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "FullLife" }, keywordFlags = KeywordFlag.Hit },
	["against enemies on low life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "LowLife" }, keywordFlags = KeywordFlag.Hit },
	["against enemies that are on low life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "LowLife" }, keywordFlags = KeywordFlag.Hit },
	["against cursed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" }, keywordFlags = KeywordFlag.Hit },
	["when hitting cursed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" }, keywordFlags = KeywordFlag.Hit },
	["against taunted enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Taunted" }, keywordFlags = KeywordFlag.Hit },
	["against bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" }, keywordFlags = KeywordFlag.Hit },
	["to bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" }, keywordFlags = KeywordFlag.Hit },
	["from bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" } },
	["against poisoned enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Poisoned" }, keywordFlags = KeywordFlag.Hit },
	["to poisoned enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Poisoned" }, keywordFlags = KeywordFlag.Hit },
	["against enemies affected by (%d+) or more poisons"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "PoisonStack", threshold = num } } end,
	["against enemies affected by at least (%d+) poisons"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "PoisonStack", threshold = num } } end,
	["against hindered enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Hindered" }, keywordFlags = KeywordFlag.Hit },
	["against maimed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Maimed" }, keywordFlags = KeywordFlag.Hit },
	["against blinded enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Blinded" }, keywordFlags = KeywordFlag.Hit },
	["from blinded enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Blinded" } },
	["against burning enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Burning" }, keywordFlags = KeywordFlag.Hit },
	["against ignited enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Ignited" }, keywordFlags = KeywordFlag.Hit },
	["to ignited enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Ignited" }, keywordFlags = KeywordFlag.Hit },
	["against shocked enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" }, keywordFlags = KeywordFlag.Hit },
	["to shocked enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" }, keywordFlags = KeywordFlag.Hit },
	["against frozen enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Frozen" }, keywordFlags = KeywordFlag.Hit },
	["to frozen enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Frozen" }, keywordFlags = KeywordFlag.Hit },
	["against chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" }, keywordFlags = KeywordFlag.Hit },
	["to chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" }, keywordFlags = KeywordFlag.Hit },
	["inflicted on chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" } },
	["enemies which are chilled"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" }, keywordFlags = KeywordFlag.Hit },
	["against frozen, shocked or ignited enemies"] = { tag = { type = "ActorCondition", actor = "enemy", varList = {"Frozen","Shocked","Ignited"} }, keywordFlags = KeywordFlag.Hit },
	["against enemies affected by elemental ailments"] = { tag = { type = "ActorCondition", actor = "enemy", varList = {"Frozen","Chilled","Shocked","Ignited"} }, keywordFlags = KeywordFlag.Hit },
	["against enemies that are affected by elemental ailments"] = { tag = { type = "ActorCondition", actor = "enemy", varList = {"Frozen","Chilled","Shocked","Ignited"} }, fkeywordFlags = KeywordFlag.Hit },
	["against enemies that are affected by no elemental ailments"] = { tagList = { { type = "ActorCondition", actor = "enemy", varList = {"Frozen","Chilled","Shocked","Ignited"}, neg = true }, { type = "Condition", var = "Effective" } }, keywordFlags = KeywordFlag.Hit },
	["against enemies affected by (%d+) spider's webs"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "Spider's WebStack", threshold = num } } end,
	["against enemies on consecrated ground"] = { tag = { type = "ActorCondition", actor = "enemy", var = "OnConsecratedGround" } },
	-- Enemy multipliers
	["per freeze, shock and ignite on enemy"] = { tag = { type = "Multiplier", var = "FreezeShockIgniteOnEnemy" }, keywordFlags = KeywordFlag.Hit },
	["per poison affecting enemy"] = { tag = { type = "Multiplier", actor = "enemy", var = "PoisonStack" } },
	["per poison affecting enemy, up to %+([%d%.]+)%%"] = function(num) return { tag = { type = "Multiplier", actor = "enemy", var = "PoisonStack", limit = num, limitTotal = true } } end,
	["for each spider's web on the enemy"] = { tag = { type = "Multiplier", actor = "enemy", var = "Spider's WebStack" } },
}

local mod = modLib.createMod
local function flag(name, ...)
	return mod(name, "FLAG", true, ...)
end

local gemIdLookup = { 
	["power charge on critical strike"] = "SupportPowerChargeOnCrit",
}
for name, grantedEffect in pairs(data["3_0"].skills) do
	if not grantedEffect.hidden or grantedEffect.fromItem then
		gemIdLookup[grantedEffect.name:lower()] = grantedEffect.id
	end
end
local function extraSkill(name, level, noSupports)
	name = name:gsub(" skill","")
	if gemIdLookup[name] then
		return { 
			mod("ExtraSkill", "LIST", { skillId = gemIdLookup[name], level = level, noSupports = noSupports }) 
		}
	end
end

-- List of special modifiers
local specialModList = {
	-- Keystones
	["your hits can't be evaded"] = { flag("CannotBeEvaded") },
	["never deal critical strikes"] = { flag("NeverCrit") },
	["no critical strike multiplier"] = { flag("NoCritMultiplier") },
	["ailments never count as being from critical strikes"] = { flag("AilmentsAreNeverFromCrit") },
	["the increase to physical damage from strength applies to projectile attacks as well as melee attacks"] = { flag("IronGrip") },
	["converts all evasion rating to armour%. dexterity provides no bonus to evasion rating"] = { flag("IronReflexes") },
	["30%% chance to dodge attack hits%. 50%% less armour, 30%% less energy shield, 30%% less chance to block spell and attack damage"] = { 
		mod("AttackDodgeChance", "BASE", 30), 
		mod("Armour", "MORE", -50), 
		mod("EnergyShield", "MORE", -30), 
		mod("BlockChance", "MORE", -30),
		mod("SpellBlockChance", "MORE", -30) 
	},
	["maximum life becomes 1, immune to chaos damage"] = { flag("ChaosInoculation") },
	["life regeneration is applied to energy shield instead"] = { flag("ZealotsOath") },
	["life leeched per second is doubled"] = { mod("LifeLeechRate", "MORE", 100) },
	["maximum total recovery per second from life leech is doubled"] = { mod("MaxLifeLeechRate", "MORE", 100) },
	["maximum total recovery per second from energy shield leech is doubled"] = { mod("MaxEnergyShieldLeechRate", "MORE", 100) },
	["life regeneration has no effect"] = { flag("NoLifeRegen") },
	["deal no non%-fire damage"] = { flag("DealNoPhysical"), flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoChaos") },
	["(%d+)%% of physical, cold and lightning damage converted to fire damage"] = function(num) return {
		mod("PhysicalDamageConvertToFire", "BASE", num), 
		mod("LightningDamageConvertToFire", "BASE", num),
		mod("ColdDamageConvertToFire", "BASE", num) 
	} end,
	["removes all mana%. spend life instead of mana for skills"] = { mod("Mana", "MORE", -100), flag("BloodMagic") },
	["enemies you hit with elemental damage temporarily get (%+%d+)%% resistance to those elements and (%-%d+)%% resistance to other elements"] = function(plus, _, minus)
		minus = tonumber(minus)
		return {
			flag("ElementalEquilibrium"),
			mod("EnemyModifier", "LIST", { mod = mod("FireResist", "BASE", plus, { type = "Condition", var = "HitByFireDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("FireResist", "BASE", minus, { type = "Condition", var = "HitByFireDamage", neg = true }, { type = "Condition", varList={"HitByColdDamage","HitByLightningDamage"} }) }),
			mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", plus, { type = "Condition", var = "HitByColdDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", minus, { type = "Condition", var = "HitByColdDamage", neg = true }, { type = "Condition", varList={"HitByFireDamage","HitByLightningDamage"} }) }),
			mod("EnemyModifier", "LIST", { mod = mod("LightningResist", "BASE", plus, { type = "Condition", var = "HitByLightningDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("LightningResist", "BASE", minus, { type = "Condition", var = "HitByLightningDamage", neg = true }, { type = "Condition", varList={"HitByFireDamage","HitByColdDamage"} }) }),
		}
	end,
	["projectile attack hits deal up to 30%% more damage to targets at the start of their movement, dealing less damage to targets as the projectile travels farther"] = { flag("PointBlank") },
	["leech energy shield instead of life"] = { flag("GhostReaver") },
	["minions explode when reduced to low life, dealing 33%% of their maximum life as fire damage to surrounding enemies"] = { mod("ExtraMinionSkill", "LIST", { skillId = "MinionInstability" }) },
	["all bonuses from an equipped shield apply to your minions instead of you"] = { }, -- The node itself is detected by the code that handles it
	["spend energy shield before mana for skill costs"] = { },
	["energy shield protects mana instead of life"] = { flag("EnergyShieldProtectsMana") },
	["modifiers to critical strike multiplier also apply to damage over time multiplier for ailments from critical strikes at (%d+)%% of their value"] = function(num) return { mod("CritMultiplierAppliesToDegen", "BASE", num) } end,
	["your bleeding does not deal extra damage while the enemy is moving"] = { flag("Condition:NoExtraBleedDamageToMovingEnemy") },
	-- Ascendant
	["grants (%d+) passive skill points?"] = function(num) return { mod("ExtraPoints", "BASE", num) } end,
	["can allocate passives from the %a+'s starting point"] = { },
	["projectiles gain damage as they travel further, dealing up to (%d+)%% increased damage with hits to targets"] = function(num) return { mod("Damage", "INC", num, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "DistanceRamp", ramp = {{35,0},{70,1}} }) } end,
	["10% chance to gain Elusive on Kill"] = {
		flag("Condition:CanBeElusive"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanBeElusive" }) -- Make the Configuration option appear
	},
	-- Assassin
	["poison you inflict with critical strikes deals (%d+)%% more damage"] = function(num) return { mod("Damage", "MORE", num, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "CriticalStrike" }) } end,
	["50% chance to gain Elusive on Critical Strike"] = {
		flag("Condition:CanBeElusive"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanBeElusive" }) -- Make the Configuration option appear
	},
	-- Berserker
	["gain %d+ rage when you kill an enemy"] = {
		flag("Condition:CanGainRage"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanGainRage" }) -- Make the Configuration option appear
	},
	["gain %d+ rage when you use a warcry"] = {
		flag("Condition:CanGainRage"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanGainRage" }) -- Make the Configuration option appear
	},
	["gain %d+ rage on hit with attacks, no more than once every [%d%.]+ seconds"] = {
		flag("Condition:CanGainRage"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanGainRage" }) -- Make the Configuration option appear
	},
	["inherent effects from having rage are tripled"] = { mod("Multiplier:RageEffect", "BASE", 2) },
	["cannot be stunned while you have at least (%d+) rage"] = function(num) return { mod("AvoidStun", "BASE", 100, { type = "MultiplierThreshold", var = "Rage", threshold = 25 }) } end,
	["lose ([%d%.]+)%% of life per second per rage while you are not losing rage"] = function(num) return { mod("LifeDegen", "BASE", num / 100, { type = "PerStat", stat = "Life" }, { type = "Multiplier", var = "Rage", limit = 50 }) } end,
	["if you've warcried recently, you and nearby allies have (%d+)%% increased attack speed"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("Speed", "INC", num, nil, ModFlag.Attack) }, { type = "Condition", var = "UsedWarcryRecently" }) } end,
	-- Champion
	["you have fortify"] = { flag("Condition:Fortify") },
	["cannot be stunned while you have fortify"] = { mod("AvoidStun", "BASE", 100, { type = "Condition", var = "Fortify" }) },
	["enemies taunted by you take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "Taunted" }) }) } end,
	["enemies taunted by you cannot evade attacks"] = { mod("EnemyModifier", "LIST", { mod = flag("CannotEvade", { type = "Condition", var = "Taunted" }) }) },
	["if you've impaled an enemy recently, you and nearby allies have %+(%d+) to armour"] = function (num) return { mod("ExtraAura", "LIST", { mod = mod("Armour", "BASE", num) }, { type = "Condition", var = "ImpaledRecently" }) } end,
	-- Chieftain
	["enemies near your totems take (%d+)%% increased physical and fire damage"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("PhysicalDamageTaken", "INC", num) }), 
		mod("EnemyModifier", "LIST", { mod = mod("FireDamageTaken", "INC", num) }) 
	} end,
	-- Deadeye
	["projectiles pierce all nearby targets"] = { flag("PierceAllTargets") },
	["gain %+(%d+) life when you hit a bleeding enemy"] = function(num) return { mod("LifeOnHit", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }) } end,
	["accuracy rating is doubled"] = { mod("Accuracy", "MORE", 100) },
	["(%d+)%% increased blink arrow and mirror arrow cooldown recovery speed"] = function(num) return {
		mod("CooldownRecovery", "INC", num, { type = "SkillName", skillNameList = { "Blink Arrow", "Mirror Arrow" } }),
	} end,
	["if you've used a skill recently, you and nearby allies have tailwind"] = { mod("ExtraAura", "LIST", { mod = flag("Condition:Tailwind") }, { type = "Condition", var = "UsedSkillRecently" }) },
	["projectiles deal (%d+)%% more damage for each remaining chain"] = function(num) return { mod("Damage", "MORE", num, nil, ModFlag.Projectile, { type = "PerStat", stat = "ChainRemaining" }) } end,
	["far shot"] = { flag("FarShot") },
	-- Elementalist
	["gain (%d+)%% increased area of effect for %d+ seconds"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", var = "PendulumOfDestructionAreaOfEffect" }) } end,
	["gain (%d+)%% increased elemental damage for %d+ seconds"] = function(num) return { mod("ElementalDamage", "INC", num, { type = "Condition", var = "PendulumOfDestructionElementalDamage" }) } end,
	["for each element you've been hit by damage of recently, (%d+)%% increased damage of that element"] = function(num) return { 
		mod("FireDamage", "INC", num, { type = "Condition", var = "HitByFireDamageRecently" }),
		mod("ColdDamage", "INC", num, { type = "Condition", var = "HitByColdDamageRecently" }),
		mod("LightningDamage", "INC", num, { type = "Condition", var = "HitByLightningDamageRecently" })
	} end,
	["for each element you've been hit by damage of recently, (%d+)%% reduced damage taken of that element"] = function(num) return { 
		mod("FireDamageTaken", "INC", -num, { type = "Condition", var = "HitByFireDamageRecently" }), 
		mod("ColdDamageTaken", "INC", -num, { type = "Condition", var = "HitByColdDamageRecently" }), 
		mod("LightningDamageTaken", "INC", -num, { type = "Condition", var = "HitByLightningDamageRecently" })
	} end,
	["every %d+ seconds:"] = { },
	["gain chilling conflux for %d seconds"] = { 
		flag("PhysicalCanChill", { type = "Condition", var = "ChillingConflux" }),
		flag("LightningCanChill", { type = "Condition", var = "ChillingConflux" }),
		flag("FireCanChill", { type = "Condition", var = "ChillingConflux" }),
		flag("ChaosCanChill", { type = "Condition", var = "ChillingConflux" }),
	},
	["gain shocking conflux for %d seconds"] = {
		mod("EnemyShockChance", "BASE", 100, { type = "Condition", var = "ShockingConflux" }),
		flag("PhysicalCanShock", { type = "Condition", var = "ShockingConflux" }),
		flag("ColdCanShock", { type = "Condition", var = "ShockingConflux" }),
		flag("FireCanShock", { type = "Condition", var = "ShockingConflux" }),
		flag("ChaosCanShock", { type = "Condition", var = "ShockingConflux" }),
	},
	["gain igniting conflux for %d seconds"] = {
		mod("EnemyIgniteChance", "BASE", 100, { type = "Condition", var = "IgnitingConflux" }),
		flag("PhysicalCanIgnite", { type = "Condition", var = "IgnitingConflux" }),
		flag("LightningCanIgnite", { type = "Condition", var = "IgnitingConflux" }),
		flag("ColdCanIgnite", { type = "Condition", var = "IgnitingConflux" }),
		flag("ChaosCanIgnite", { type = "Condition", var = "IgnitingConflux" }),
	},
	["gain chilling, shocking and igniting conflux for %d seconds"] = { },
	["(%d+)%% increased golem damage per summoned golem"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "SkillType", skillType = SkillType.Golem }, { type = "PerStat", stat = "ActiveGolemLimit" }) } end,
	-- Gladiator
	["enemies maimed by you take (%d+)%% increased physical damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("PhysicalDamageTaken", "INC", num, { type = "Condition", var = "Maimed" }) }) } end,
	["chance to block spell damage is equal to chance to block attack damage"] = { flag("SpellBlockChanceIsBlockChance") },
	["maximum chance to block spell damage is equal to maximum chance to block attack damage"] = { flag("SpellBlockChanceMaxIsBlockChanceMax") },
	["Your Counterattacks deal Double Damage"] = {
		mod("DoubleDamageChance", "BASE", 100, { type = "SkillName", skillName = "Reckoning" }),
		mod("DoubleDamageChance", "BASE", 100, { type = "SkillName", skillName = "Riposte" }),
		mod("DoubleDamageChance", "BASE", 100, { type = "SkillName", skillName = "Vengeance" }),
	},
	-- Guardian
	["grants armour equal to (%d+)%% of your reserved life to you and nearby allies"] = function(num) return { mod("GrantReservedLifeAsAura", "LIST", { mod = mod("Armour", "BASE", num / 100) }) } end,
	["grants maximum energy shield equal to (%d+)%% of your reserved mana to you and nearby allies"] = function(num) return { mod("GrantReservedManaAsAura", "LIST", { mod = mod("EnergyShield", "BASE", num / 100) }) } end,
	["warcries cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Warcry) },
	["%+(%d+)%% chance to block attack damage for %d seconds? every %d seconds"] = function(num) return { mod("BlockChance", "BASE", num, { type = "Condition", var = "BastionOfHopeActive" }) } end,
	["if you've attacked recently, you and nearby allies have %+(%d+)%% chance to block attack damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("BlockChance", "BASE", num) }, { type = "Condition", var = "AttackedRecently" }) } end,
	["if you've cast a spell recently, you and nearby allies have %+(%d+)%% chance to block spell damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("SpellBlockChance", "BASE", num) }, { type = "Condition", var = "CastSpellRecently" }) } end,
	["while there is at least one nearby ally, you and nearby allies deal (%d+)%% more damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("Damage", "MORE", num) }, { type = "MultiplierThreshold", var = "NearbyAlly", threshold = 1 }) } end,
	["while there are at least five nearby allies, you and nearby allies have onslaught"] = { mod("ExtraAura", "LIST", { mod = flag("Onslaught") }, { type = "MultiplierThreshold", var = "NearbyAlly", threshold = 5 }) },
	-- Hierophant
	["you and your totems regenerate (%d+)%% of life per second per totem"] = function (num) return { 
		mod("LifeRegenPercent", "BASE", num, {type = "PerStat", stat = "ActiveTotemLimit"}),
		mod("LifeRegenPercent", "BASE", num, {type = "PerStat", stat = "ActiveTotemLimit"}, 0, KeywordFlag.Totem),
	} end,
	-- Inquisitor
	["critical strikes ignore enemy monster elemental resistances"] = { flag("IgnoreElementalResistances", { type = "Condition", var = "CriticalStrike" }) },
	["non%-critical strikes penetrate (%d+)%% of enemy elemental resistances"] = function(num) return { mod("ElementalPenetration", "BASE", num, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	["consecrated ground you create applies (%d+)%% increased damage taken to enemies"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "OnConsecratedGround" }) }) } end,
	["nearby enemies take (%d+)%% increased elemental damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("ElementalDamageTaken", "INC", num) }) } end,
	-- Juggernaut
	["armour received from body armour is doubled"] = { flag("Unbreakable") },
	["movement speed cannot be modified to below base value"] = { flag("MovementSpeedCannotBeBelowBase") },
	["you cannot be slowed to below base speed"] = { flag("ActionSpeedCannotBeBelowBase") },
	["cannot be slowed to below base speed"] = { flag("ActionSpeedCannotBeBelowBase") },
	["gain accuracy rating equal to your strength"] = { mod("Accuracy", "BASE", 1, { type = "PerStat", stat = "Str" }) },
	-- Necromancer
	["your offering skills also affect you"] = { mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "buffNotPlayer", value = false }) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } }) },
	["your offerings have (%d+)%% reduced effect on you"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("BuffEffectOnPlayer", "INC", -num) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } }) } end,
	["if you've consumed a corpse recently, you and your minions have (%d+)%% increased area of effect"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", var = "ConsumedCorpseRecently" }), mod("MinionModifier", "LIST", { mod = mod("AreaOfEffect", "INC", num) }, { type = "Condition", var = "ConsumedCorpseRecently" }) } end,
	["with at least one nearby corpse, you and nearby allies deal (%d+)%% more damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("Damage", "MORE", num) }, { type = "MultiplierThreshold", var = "NearbyCorpse", threshold = 1 }) } end,
	["for each nearby corpse, you and nearby allies regenerate ([%d%.]+)%% of energy shield per second, up to ([%d%.]+)%% per second"] = function(num, _, limit) return { mod("ExtraAura", "LIST", { mod = mod("EnergyShieldRegenPercent", "BASE", num) }, { type = "Multiplier", var = "NearbyCorpse", limit = tonumber(limit), limitTotal = true }) } end,
	["for each nearby corpse, you and nearby allies regenerate (%d+) mana per second, up to (%d+) per second"] = function(num, _, limit) return { mod("ExtraAura", "LIST", { mod = mod("ManaRegen", "BASE", num) }, { type = "Multiplier", var = "NearbyCorpse", limit = tonumber(limit), limitTotal = true }) } end,
	-- Occultist
	["enemies you curse have malediction"] = { mod("AffectedByCurseMod", "LIST", { mod = mod("DamageTaken", "INC", 10) }) },
	["nearby enemies have (%-%d+)%% to chaos resistance"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("ChaosResist", "BASE", num) }) } end,
	["nearby enemies have (%-%d+)%% to cold resistance"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", num) }) } end,
	["when you kill an enemy, for each curse on that enemy, gain (%d+)%% of non%-chaos damage as extra chaos damage for 4 seconds"] = function(num) return { 
		mod("NonChaosDamageGainAsChaos", "BASE", num, { type = "Condition", var = "KilledRecently" }, { type = "Multiplier", var = "CurseOnEnemy" }), 
	} end,
	["cannot be stunned while you have energy shield"] = { mod("AvoidStun", "BASE", 100, { type = "Condition", var = "HaveEnergyShield" }) },
	["inflict withered on nearby enemies for 15 seconds"] = {
		flag("Condition:CanWither"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanWither" }) -- Make the Configuration option appear
	},
	-- Pathfinder
	["always poison on hit while using a flask"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["poisons you inflict during any flask effect have (%d+)%% chance to deal (%d+)%% more damage"] = function(num, _, more) return { mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "UsingFlask" }) } end,
	-- Raider
	["you have phasing while at maximum frenzy charges"] = { flag("Condition:Phasing", { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["you have phasing during onslaught"] = { flag("Condition:Phasing", { type = "Condition", var = "Onslaught" }) },
	["you have onslaught while on full frenzy charges"] = { flag("Condition:Onslaught", { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["you have onslaught while at maximum endurance charges"] = { flag("Condition:Onslaught", { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }) },
	-- Sabotuer
	-- Slayer
	["deal up to 15%% more melee damage to enemies, based on proximity"] = function(num) return { mod("Damage", "MORE", num, nil, bor(ModFlag.Attack, ModFlag.Melee), { type = "MeleeProximity", ramp = {15,0} }) } end,
	-- Trickster
	["(%d+)%% chance to gain (%d+)%% of non%-chaos damage with hits as extra chaos damage"] = function(num, _, perc) return { mod("NonChaosDamageGainAsChaos", "BASE", num / 100 * tonumber(perc)) } end,
	["movement skills cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Movement) },
	-- Item local modifiers
	["has no sockets"] = { flag("NoSockets") },
	["has (%d+) sockets?"] = function(num) return { mod("SocketCount", "BASE", num) } end,
	["has (%d+) abyssal sockets?"] = function(num) return { mod("AbyssalSocketCount", "BASE", num) } end,
	["no physical damage"] = { mod("WeaponData", "LIST", { key = "PhysicalMin" }), mod("WeaponData", "LIST", { key = "PhysicalMax" }), mod("WeaponData", "LIST", { key = "PhysicalDPS" }) },
	["all attacks with this weapon are critical strikes"] = { mod("WeaponData", "LIST", { key = "CritChance", value = 100 }) },
	["counts as dual wielding"] = { mod("WeaponData", "LIST", { key = "countsAsDualWielding", value = true}) },
	["counts as all one handed melee weapon types"] = { mod("WeaponData", "LIST", { key = "countsAsAll1H", value = true }) },
	["no block chance"] = { mod("ArmourData", "LIST", { key = "BlockChance", value = 0 }) },
	["hits can't be evaded"] = { flag("CannotBeEvaded", { type = "Condition", var = "{Hand}Attack" }) },
	["causes bleeding on hit"] = { mod("BleedChance", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }) },
	["poisonous hit"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }) },
	["attacks with this weapon deal double damage"] = { mod("Damage", "MORE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }) },
	["attacks with this weapon deal double damage to chilled enemies"] = { mod("Damage", "MORE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) },
	["life leech from hits with this weapon applies instantly"] = { flag("InstantLifeLeech", { type = "Condition", var = "{Hand}Attack" }) },
	["gain life from leech instantly from hits with this weapon"] = { flag("InstantLifeLeech", { type = "Condition", var = "{Hand}Attack" }) },
	["instant recovery"] = {  mod("FlaskInstantRecovery", "BASE", 100) },
	["(%d+)%% of recovery applied instantly"] = function(num) return { mod("FlaskInstantRecovery", "BASE", num) } end,
	["has no attribute requirements"] = { flag("NoAttributeRequirements") },
	-- Socketed gem modifiers
	["%+(%d+) to level of socketed gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "all", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["%+(%d+) to level of socketed ([%a ]+) gems"] = function(num, _, type) return { mod("GemProperty", "LIST", { keyword = type, key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["%+(%d+)%% to quality of socketed ([%a ]+) gems"] = function(num, _, type) return { mod("GemProperty", "LIST", { keyword = type, key = "quality", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["%+(%d+) to level of active socketed skill gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "active_skill", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["%+(%d+) to level of socketed active skill gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "active_skill", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["%+(%d+) to level of socketed active skill gems per (%d+) player levels"] = function(num, _, div) return { mod("GemProperty", "LIST", { keyword = "active_skill", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "Multiplier", var = "Level", div = tonumber(div) }) } end,
	["socketed gems fire an additional projectile"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", 1) }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems fire (%d+) additional projectiles"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed gems reserve no mana"] = { mod("ManaReserved", "MORE", -100, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed skill gems get a (%d+)%% mana multiplier"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ManaCost", "MORE", num - 100) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed gems have blood magic"] = { flag("SkillBloodMagic", { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems gain (%d+)%% of physical damage as extra lightning damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("PhysicalDamageGainAsLightning", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed red gems get (%d+)%% physical damage as extra fire damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("PhysicalDamageGainAsFire", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "strength" }) } end,
	-- Global gem modifiers
	["%+(%d+) to level of all minion skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "minion", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all spell skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "spell", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all physical spell skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "spell", "physical", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all lightning spell skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "spell", "lightning", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all cold spell skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "spell", "cold", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all fire spell skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "spell", "fire", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all chaos spell skill gems"] = function(num) return { mod("GemProperty", "LIST", { keywordList = { "spell", "chaos", "active_skill" }, key = "level", value = num }) } end,
	["%+(%d+) to level of all (.+) gems"] = function(num, _, skill) return { mod("GemProperty", "LIST", {keyword = skill, key = "level", value = num }) } end,
	-- Extra skill/support
	["grants (%D+)"] = function(_, skill) return extraSkill(skill, 1) end,
	["grants level (%d+) (.+)"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when equipped"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num) end,
	["use level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you attack"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you deal a critical strike"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when hit"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you kill an enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you use a skill"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you use a skill while you have a spirit charge"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you hit an enemy while cursed"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you kill a frozen enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you consume a corpse"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you attack with a bow"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+) when animated guardian kills an enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to attack with level (%d+) (.+) on melee hit"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to trigger level (%d+) (.+) when animated weapon kills an enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to trigger level (%d+) (.+) on melee hit"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to trigger level (%d+) (.+) [ow][nh]e?n? ?y?o?u? kill ?a?n? ?e?n?e?m?y?"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to trigger level (%d+) (.+) when you use a socketed skill"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to trigger level (%d+) (.+) when you gain avian's might or avian's flight"] = function(num, _, skill) return extraSkill(skill, num) end,
	["%d+%% chance to [ct][ar][si][tg]g?e?r? level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num) end,
	["attack with level (%d+) (.+) when you kill a bleeding enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["triggers? level (%d+) (.+) when you kill a bleeding enemy"] = function(num, _, skill) return extraSkill(skill, num) end,
	["curse enemies with (%D+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["curse enemies with level (%d+) (%D+) on %a+, which can apply to hexproof enemies"] = function(num, _, skill) return extraSkill(skill, num, true) end,
	["curse enemies with level (%d+) (.+) on %a+"] = function(num, _, skill) return extraSkill(skill, num, true) end,
	["[ct][ar][si][tg]g?e?r?s? (.+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[at][tr][ti][ag][cg][ke]r? (.+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[at][tr][ti][ag][cg][ke]r? with (.+) on %a+"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[ct][ar][si][tg]g?e?r?s? (.+) when hit"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[at][tr][ti][ag][cg][ke]r? (.+) when hit"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[at][tr][ti][ag][cg][ke]r? with (.+) when hit"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[ct][ar][si][tg]g?e?r?s? (.+) when your skills or minions kill"] = function(_, skill) return extraSkill(skill, 1, true) end,
	["[at][tr][ti][ag][cg][ke]r? (.+) when you take a critical strike"] = function( _, skill) return extraSkill(skill, 1, true) end,
	["[at][tr][ti][ag][cg][ke]r? with (.+) when you take a critical strike"] = function( _, skill) return extraSkill(skill, 1, true) end,
	["trigger (.+) on critical strike"] = function( _, skill) return extraSkill(skill, 1, true) end,
	["triggers? (.+) when you take a critical strike"] = function( _, skill) return extraSkill(skill, 1, true) end,
	["socketed [%a+]* ?gems a?r?e? ?supported by level (%d+) (.+)"] = function(num, _, support) return { mod("ExtraSupport", "LIST", { skillId = gemIdLookup[support] or gemIdLookup[support:gsub("^increased ","")] or "Unknown", level = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["trigger level (%d+) (.+) every (%d+) seconds"] = function(num, _, skill) return extraSkill(skill, num) end,
	["trigger level (%d+) (.+), (.+) or (.+) every (%d+) seconds"] = function(num, _, skill1, skill2, skill3) return {
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill1], level = num }),
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill2], level = num }),
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill3], level = num })
	} end,
	["offering skills triggered this way also affect you"] = { mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "buffNotPlayer", value = false }) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger level (%d+) (.+) after spending a total of (%d+) mana"] = function(num, _, skill) return extraSkill(skill, num) end,
	-- Conversion
	["increases and reductions to minion damage also affects? you"] = { flag("MinionDamageAppliesToPlayer") },
	["increases and reductions to minion attack speed also affects? you"] = { flag("MinionAttackSpeedAppliesToPlayer") },
	["increases and reductions to spell damage also apply to attacks"] = { flag("SpellDamageAppliesToAttacks") },
	["modifiers to claw damage also apply to unarmed"] = { flag("ClawDamageAppliesToUnarmed") },
	["modifiers to claw damage also apply to unarmed attack damage"] = { flag("ClawDamageAppliesToUnarmed") },
	["modifiers to claw attack speed also apply to unarmed"] = { flag("ClawAttackSpeedAppliesToUnarmed") },
	["modifiers to claw attack speed also apply to unarmed attack speed"] = { flag("ClawAttackSpeedAppliesToUnarmed") },
	["modifiers to claw critical strike chance also apply to unarmed"] = { flag("ClawCritChanceAppliesToUnarmed") },
	["modifiers to claw critical strike chance also apply to unarmed attack critical strike chance"] = { flag("ClawCritChanceAppliesToUnarmed") },
	["increases and reductions to light radius also apply to accuracy"] = { flag("LightRadiusAppliesToAccuracy") },
	["increases and reductions to light radius also apply to area of effect at 50%% of their value"] = { flag("LightRadiusAppliesToAreaOfEffect") },
	["increases and reductions to light radius also apply to damage"] = { flag("LightRadiusAppliesToDamage") },
	["increases and reductions to cast speed also apply to trap throwing speed"] = { flag("CastSpeedAppliesToTrapThrowingSpeed") },
	["gain (%d+)%% of bow physical damage as extra damage of each element"] = function(num) return { 
		mod("PhysicalDamageGainAsLightning", "BASE", num, nil, ModFlag.Bow), 
		mod("PhysicalDamageGainAsCold", "BASE", num, nil, ModFlag.Bow), 
		mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Bow) 
	} end,
	["gain (%d+)%% of weapon physical damage as extra damage of each element"] = function(num) return { 
		mod("PhysicalDamageGainAsLightning", "BASE", num, nil, ModFlag.Weapon), 
		mod("PhysicalDamageGainAsCold", "BASE", num, nil, ModFlag.Weapon), 
		mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Weapon) 
	} end,
	-- Crit
	["your critical strike chance is lucky"] = { flag("CritChanceLucky") },
	["your critical strike chance is lucky while focussed"] = { flag("CritChanceLucky", { type = "Condition", var = "Focused"}) },
	["your critical strikes do not deal extra damage"] = { flag("NoCritMultiplier") },
	["critical strikes deal no damage"] = { mod("Damage", "MORE", -100, { type = "Condition", var = "CriticalStrike" }) },
	["critical strike chance is increased by uncapped lightning resistance"] = { mod("CritChance", "INC", 1, { type = "PerStat", stat = "LightningResistTotal", div = 1 }) },
	["critical strike chance is increased by lightning resistance"] = { mod("CritChance", "INC", 1, { type = "PerStat", stat = "LightningResist", div = 1 }) },
	["non%-critical strikes deal (%d+)%% damage"] = function(num) return { mod("Damage", "MORE", -100+num, nil, ModFlag.Hit, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	["critical strikes penetrate (%d+)%% of enemy elemental resistances while affected by zealotry"] = function(num) return { mod("ElementalPenetration", "BASE", num, { type = "Condition", var = "CriticalStrike"}, { type = "Condition", var = "AffectedByZealotry" }) } end,
	-- Generic Ailments
	["enemies take (%d+)%% increased damage for each type of ailment you have inflicted on them"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Frozen"}),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Chilled"}),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Ignited"}),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Shocked"}),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Bleeding"}),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Poisoned"})
	} end,
	-- Elemental Ailments
	["your elemental damage can shock"] = { flag("ColdCanShock"), flag("FireCanShock") },
	["your cold damage can ignite"] = { flag("ColdCanIgnite") },
	["your lightning damage can ignite"] = { flag("LightningCanIgnite") },
	["your fire damage can shock but not ignite"] = { flag("FireCanShock"), flag("FireCannotIgnite") },
	["your cold damage can ignite but not freeze or chill"] = { flag("ColdCanIgnite"), flag("ColdCannotFreeze"), flag("ColdCannotChill") },
	["your lightning damage can freeze but not shock"] = { flag("LightningCanFreeze"), flag("LightningCannotShock") },
	["your chaos damage can shock"] = { flag("ChaosCanShock") },
	["chaos damage can ignite, chill and shock"] = { flag("ChaosCanIgnite"), flag("ChaosCanChill"), flag("ChaosCanShock") },
	["your physical damage can chill"] = { flag("PhysicalCanChill") },
	["your physical damage can shock"] = { flag("PhysicalCanShock") },
	["you always ignite while burning"] = { mod("EnemyIgniteChance", "BASE", 100, { type = "Condition", var = "Burning" }) },
	["critical strikes do not always freeze"] = { flag("CritsDontAlwaysFreeze") },
	["you can inflict up to (%d+) ignites on an enemy"] = { flag("IgniteCanStack") },
	["enemies chilled by you take (%d+)%% increased burning damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("FireDamageTakenOverTime", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) } end,
	["ignited enemies burn (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num) } end,
	["ignited enemies burn (%d+)%% slower"] = function(num) return { mod("IgniteBurnSlower", "INC", num) } end,
	["enemies ignited by an attack burn (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num, nil, ModFlag.Attack) } end,
	["enemies ignited by you during flask effect take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Ignited" }) } end,
	["cannot inflict ignite"] = { flag("CannotIgnite") },
	["cannot inflict freeze or chill"] = { flag("CannotFreeze"), flag("CannotChill") },
	["cannot inflict shock"] = { flag("CannotShock") },
	-- Bleed
	["melee attacks cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee) },
	["attacks cause bleeding when hitting cursed enemies"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Attack, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) },
	["melee critical strikes cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) },
	["causes bleeding on melee critical strike"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) },
	["melee critical strikes have (%d+)%% chance to cause bleeding"] = function(num) return { mod("BleedChance", "BASE", num, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) } end,
	["attacks always inflict bleeding while you have cat's stealth"] = { mod("BleedChance", "BASE", 100, nil, ModFlag.Attack, { type = "Condition", var = "AffectedByCat'sStealth" }) },
	["you have crimson dance while you have cat's stealth"] = { mod("Keystone", "LIST", "Crimson Dance", { type = "Condition", var = "AffectedByCat'sStealth" }) },
	["you have crimson dance if you have dealt a critical strike recently"] = { mod("Keystone", "LIST", "Crimson Dance", { type = "Condition", var = "CritRecently" }) },
	["bleeding you inflict deals damage (%d+)%% faster"] = function(num) return { mod("BleedFaster", "INC", num) } end,
	["(%d+)%% chance for bleeding inflicted with this weapon to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 200, nil, 0, bor(KeywordFlag.Bleed, ModFlag.Attack), { type = "Condition", var = "DualWielding"}),
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, bor(KeywordFlag.Bleed, ModFlag.Attack), { type = "Condition", var = "DualWielding", neg = true })
	} end,
	-- Poison
	["y?o?u?r? ?fire damage can poison"] = { flag("FireCanPoison") },
	["y?o?u?r? ?cold damage can poison"] = { flag("ColdCanPoison") },
	["y?o?u?r? ?lightning damage can poison"] = { flag("LightningCanPoison") },
	["your chaos damage poisons enemies"] = { mod("ChaosPoisonChance", "BASE", 100) },
	["your chaos damage has (%d+)%% chance to poison enemies"] = function(num) return { mod("ChaosPoisonChance", "BASE", num) } end,
	["melee attacks poison on hit"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Melee) },
	["melee critical strikes have (%d+)%% chance to poison the enemy"] = function(num) return { mod("PoisonChance", "BASE", num, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) } end,
	["critical strikes with daggers have a (%d+)%% chance to poison the enemy"] = function(num) return { mod("PoisonChance", "BASE", num, nil, ModFlag.Dagger, { type = "Condition", var = "CriticalStrike" }) } end,
	["poison cursed enemies on hit"] = { mod("PoisonChance", "BASE", 100, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) },
	["wh[ie][ln]e? at maximum frenzy charges, attacks poison enemies"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Attack, { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["traps and mines have a (%d+)%% chance to poison on hit"] = function(num) return { mod("PoisonChance", "BASE", num, nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["poisons you inflict deal damage (%d+)%% faster"] = function(num) return { mod("PoisonFaster", "INC", num) } end,
	["(%d+)%% chance for poisons inflicted with this weapon to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 200, nil, 0, bor(KeywordFlag.Poison, ModFlag.Attack), { type = "Condition", var = "DualWielding"}),
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, bor(KeywordFlag.Poison, ModFlag.Attack), { type = "Condition", var = "DualWielding", neg = true })
	} end,
	-- Buffs/debuffs
	["phasing"] = { flag("Condition:Phasing") },
	["onslaught"] = { flag("Condition:Onslaught") },
	["you have phasing if you've killed recently"] = { flag("Condition:Phasing", { type = "Condition", var = "KilledRecently" }) },
	["you have phasing if you have blocked recently"] = { flag("Condition:Phasing", { type = "Condition", var = "BlockedRecently" }) },
	["you have phasing while affected by haste"] = { flag("Condition:Phasing", { type = "Condition", var = "AffectedByHaste" }) },
	["you have phasing while you have cat's stealth"] = { flag("Condition:Phasing", { type = "Condition", var = "AffectedByCat'sStealth" }) },
	["you have onslaught while on low life"] = { flag("Condition:Onslaught", { type = "Condition", var = "LowLife" }) },
	["you have onslaught while not on low mana"] = { flag("Condition:Onslaught", { type = "Condition", var = "LowMana", neg = true }) },
	["your aura buffs do not affect allies"] = { flag("SelfAurasCannotAffectAllies") },
	["nearby allies' damage with hits is lucky"] = { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("LuckyHits", "BASE") }) },
	["allies' aura buffs do not affect you"] = { flag("AlliesAurasCannotAffectSelf") },
	["enemies can have 1 additional curse"] = { mod("EnemyCurseLimit", "BASE", 1) },
	["you can apply an additional curse"] = { mod("EnemyCurseLimit", "BASE", 1) },
	["nearby enemies have (%d+)%% increased effect of curses on them"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("CurseEffectOnSelf", "INC", num) }) } end,
	["nearby enemies have an additional (%d+)%% chance to receive a critical strike"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("SelfExtraCritChance", "BASE", num) }) } end,
	["nearby enemies have (%-%d+)%% to all resistances"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("ElementalResist", "BASE", num) }),
		mod("EnemyModifier", "LIST", { mod = mod("ChaosResist", "BASE", num) }) 
	} end,
	["your hits inflict decay, dealing (%d+) chaos damage per second for %d+ seconds"] = function(num) return { mod("SkillData", "LIST", { key = "decay", value = num, merge = "MAX" }) } end,
	["temporal chains has (%d+)%% reduced effect on you"] = function(num) return { mod("CurseEffectOnSelf", "INC", -num, { type = "SkillName", skillName = "Temporal Chains" }) } end,
	["unaffected by temporal chains"] = { mod("CurseEffectOnSelf", "MORE", -100, { type = "SkillName", skillName = "Temporal Chains" }) },
	["([%+%-]%d+) seconds to cat's stealth duration"] = function(num) return { mod("PrimaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Cat" }) } end,
	["([%+%-]%d+) seconds to avian's might duration"] = function(num) return { mod("PrimaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Avian" }) } end,
	["([%+%-]%d+) seconds to avian's flight duration"] = function(num) return { mod("SecondaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Avian" }) } end,
	["aspect of the spider can inflict spider's web on enemies an additional time"] = { mod("ExtraSkillMod", "LIST", { mod = mod("Multiplier:SpiderWebApplyStackMax", "BASE", 1) }, { type = "SkillName", skillName = "Aspect of the Spider" }) },
	["enemies affected by your spider's webs have (%-%d+)%% to all resistances"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("ElementalResist", "BASE", num, { type = "MultiplierThreshold", var = "Spider's WebStack", threshold = 1 }) }),
		mod("EnemyModifier", "LIST", { mod = mod("ChaosResist", "BASE", num, { type = "MultiplierThreshold", var = "Spider's WebStack", threshold = 1 }) }),
	} end,
	["you are cursed with level (%d+) (%D+)"] = function(num, _, name) return { mod("ExtraCurse", "LIST", { skillId = gemIdLookup[name], level = num, applyToPlayer = true }) } end,
	["you count as on low life while you are cursed with vulnerability"] = { flag("Condition:LowLife", { type = "Condition", var = "AffectedByVulnerability" }) },
	["if you consumed a corpse recently, you and nearby allies regenerate (%d+)%% of life per second"] = function (num) return { mod("ExtraAura", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "Condition", var = "ConsumedCorpseRecently" }) } end,
	["if you have blocked recently, you and nearby allies regenerate (%d+)%% of life per second"] = function (num) return { mod("ExtraAura", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "Condition", var = "BlockedRecently" }) } end,
	["you are at maximum chance to block attack damage if you have not blocked recently"] = { flag("MaxBlockIfNotBlockedRecently", { type = "Condition", var = "BlockedRecently", neg = true }) },
	["(%d+)%% of evasion rating is regenerated as life per second while focussed"] = function(num) return { mod("LifeRegen", "BASE", num / 100, { type = "PerStat", stat = "Evasion"}, { type = "Condition", var = "Focused" }) } end,
	["nearby allies have (%d+)%% increased defences per (%d+) strength you have"] = function(num, _, div) return { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("Defences", "INC", num) }, { type = "PerStat", stat = "Str", div = tonumber(div) }) } end,
	["nearby allies have %+(%d+)%% to critical strike multiplier per (%d+) dexterity you have"] = function(num, _, div) return { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("CritMultiplier", "BASE", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["nearby allies have (%d+)%% increased cast speed per (%d+) intelligence you have"] = function(num, _, div) return { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("Speed", "INC", num, nil, ModFlag.Cast ) }, { type = "PerStat", stat = "Int", div = tonumber(div) }) } end,
	["you gain divinity for %d+ seconds on reaching maximum divine charges"] = { 
		mod("ElementalDamage", "MORE", 50, { type = "Condition", var = "Divinity" }),
		mod("ElementalDamageTaken", "MORE", -20, { type = "Condition", var = "Divinity" }),
	},
	["your maximum endurance charges is equal to your maximum frenzy charges"] = { flag("MaximumEnduranceChargesIsMaximumFrenzyCharges") },
	["your maximum frenzy charges is equal to your maximum power charges"] = { flag("MaximumFrenzyChargesIsMaximumPowerCharges") },
	["consecrated ground you create while affected by zealotry causes enemies to take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "OnConsecratedGround" }, { type = "Condition", var = "AffectedByZealotry" }) } end,
	["if you've warcried recently, you and nearby allies have (%d+)%% increased attack, cast and movement speed"] = function(num) return {
		mod("ExtraAura", "LIST", { mod = mod("Speed", "INC", num) }, { type = "Condition", var = "UsedWarcryRecently" }),
		mod("ExtraAura", "LIST", { mod = mod("MovementSpeed", "INC", num) }, { type = "Condition", var = "UsedWarcryRecently" }),
	} end,
	-- Traps, Mines and Totems
	["traps and mines deal (%d+)%-(%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["traps and mines deal (%d+) to (%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["can have up to (%d+) additional traps? placed at a time"] = function(num) return { mod("ActiveTrapLimit", "BASE", num) } end,
	["can have up to (%d+) additional remote mines? placed at a time"] = function(num) return { mod("ActiveMineLimit", "BASE", num) } end,
	["can have up to (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num) } end,
	["attack skills can have (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num, nil, 0, KeywordFlag.Attack) } end,
	["can [hs][au][vm][em]o?n? 1 additional siege ballista totem per (%d+) dexterity"] = function(num) return { mod("ActiveTotemLimit", "BASE", 1, { type = "SkillName", skillName = "Siege Ballista" }, { type = "PerStat", stat = "Dex", div = num }) } end,
	["totems fire (%d+) additional projectiles"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	["([%d%.]+)%% of damage dealt by y?o?u?r? ?totems is leeched to you as life"] = function(num) return { mod("DamageLifeLeechToPlayer", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	["([%d%.]+)%% of damage dealt by y?o?u?r? ?mines is leeched to you as life"] = function(num) return { mod("DamageLifeLeechToPlayer", "BASE", num, nil, 0, KeywordFlag.Mine) } end,
	-- Minions
	["your strength is added to your minions"] = { flag("HalfStrengthAddedToMinions") },
	["half of your strength is added to your minions"] = { flag("HalfStrengthAddedToMinions") },
	["minions poison enemies on hit"] = { mod("MinionModifier", "LIST", { mod = mod("PoisonChance", "BASE", 100) }) },
	["minions have (%d+)%% chance to poison enemies on hit"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PoisonChance", "BASE", num) }) } end,
	["(%d+)%% increased minion damage if you have hit recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "Condition", var = "HitRecently" }) } end,
	["(%d+)%% increased minion damage if you've used a minion skill recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "Condition", var = "UsedMinionSkillRecently" }) } end,
	["(%d+)%% increased minion attack speed per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", num, nil, ModFlag.Attack) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["(%d+)%% increased minion movement speed per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["minions deal (%d+)%% increased damage per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["(%d+)%% increased golem damage for each type of golem you have summoned"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HavePhysicalGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveLightningGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveColdGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveFireGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveChaosGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveCarrionGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
	} end,
	["can summon up to (%d) additional golems? at a time"] = function(num) return { mod("ActiveGolemLimit", "BASE", num) } end,
	["if you have 3 primordial jewels, can summon up to (%d) additional golems? at a time"] = function(num) return { mod("ActiveGolemLimit", "BASE", num, { type = "MultiplierThreshold", var = "PrimordialItem", threshold = 3 }) } end,
	["golems regenerate (%d)%% of their maximum life per second"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "SkillType", skillType = SkillType.Golem }) } end,
	["raging spirits' hits always ignite"] = { mod("MinionModifier", "LIST", { mod = mod("EnemyIgniteChance", "BASE", 100) }, { type = "SkillName", skillName = "Summon Raging Spirit" }) },
	["summoned skeletons have avatar of fire"] = { mod("MinionModifier", "LIST", { mod = mod("Keystone", "LIST", "Avatar of Fire") }, { type = "SkillName", skillName = "Summon Skeleton" }) },
	["summoned skeletons take ([%d%.]+)%% of their maximum life per second as fire damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("FireDegen", "BASE", num/100, { type = "PerStat", stat = "Life", div = 1 }) }, { type = "SkillName", skillName = "Summon Skeleton" }) } end,
	["minions convert (%d+)%% of physical damage to fire damage per red socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToFire", "BASE", num) }, { type = "Multiplier", var = "RedSocketIn{SlotName}" }) } end,
	["minions convert (%d+)%% of physical damage to cold damage per green socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToCold", "BASE", num) }, { type = "Multiplier", var = "GreenSocketIn{SlotName}" }) } end,
	["minions convert (%d+)%% of physical damage to lightning damage per blue socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToLightning", "BASE", num) }, { type = "Multiplier", var = "BlueSocketIn{SlotName}" }) } end,
	["minions convert (%d+)%% of physical damage to chaos damage per white socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToChaos", "BASE", num) }, { type = "Multiplier", var = "WhiteSocketIn{SlotName}" }) } end,
	-- Projectiles
	["skills chain %+(%d) times"] = function(num) return { mod("ChainCountMax", "BASE", num) } end,
	["skills chain an additional time while at maximum frenzy charges"] = { mod("ChainCountMax", "BASE", 1, { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["attacks chain an additional time when in main hand"] = { mod("ChainCountMax", "BASE", 1, nil, ModFlag.Attack, { type = "SlotNumber", num = 1 }) },
	["adds an additional arrow"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack) },
	["(%d+) additional arrows"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Attack) } end,
	["bow attacks fire an additional arrow"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Bow) },
	["bow attacks fire (%d+) additional arrows"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Bow) } end,
	["skills fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1) },
	["spells have an additional projectile"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Spell) },
	["attacks have an additional projectile when in off hand"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack, { type = "SlotNumber", num = 2 }) },
	["projectiles pierce an additional target"] = { mod("PierceCount", "BASE", 1) },
	["projectiles pierce (%d+) targets?"] = function(num) return { mod("PierceCount", "BASE", num) } end,
	["projectiles pierce (%d+) additional targets?"] = function(num) return { mod("PierceCount", "BASE", num) } end,
	["projectiles pierce (%d+) additional targets while you have phasing"] = function(num) return { mod("PierceCount", "BASE", num, { type = "Condition", var = "Phasing" }) } end,
	["arrows pierce an additional target"] = { mod("PierceCount", "BASE", 1, nil, ModFlag.Attack) },
	["arrows pierce one target"] = { mod("PierceCount", "BASE", 1, nil, ModFlag.Attack) },
	["arrows pierce (%d+) targets?"] = function(num) return { mod("PierceCount", "BASE", num, nil, ModFlag.Attack) } end,
	["always pierce with arrows"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows always pierce"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows pierce all targets"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows that pierce cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) },
	["arrows that pierce have (%d+)%% chance to cause bleeding"] = function(num) return { mod("BleedChance", "BASE", num, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	["arrows that pierce deal (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	["projectiles gain (%d+)%% of non%-chaos damage as extra chaos damage per chain"] = function(num) return { mod("NonChaosDamageGainAsChaos", "BASE", num, nil, ModFlag.Projectile, { type = "PerStat", stat = "Chain" }) } end,
	["left ring slot: projectiles from spells cannot chain"] = { flag("CannotChain", nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 1 }) },
	["right ring slot: projectiles from spells chain %+1 times"] = { mod("ChainCountMax", "BASE", 1, nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 2 }) },
	["projectiles from spells cannot pierce"] = { flag("CannotPierce", nil, ModFlag.Spell) },
	-- Leech/Gain on Hit
	["cannot leech life"] = { flag("CannotLeechLife") },
	["cannot leech mana"] = { flag("CannotLeechMana") },
	["cannot leech when on low life"] = { flag("CannotLeechLife", { type = "Condition", var = "LowLife" }), flag("CannotLeechMana", { type = "Condition", var = "LowLife" }) },
	["cannot leech life from critical strikes"] = { flag("CannotLeechLife", { type = "Condition", var = "CriticalStrike" }) },
	["leech applies instantly on critical strike"] = { flag("InstantLifeLeech", { type = "Condition", var = "CriticalStrike" }), flag("InstantManaLeech", { type = "Condition", var = "CriticalStrike" }) },
	["gain life and mana from leech instantly on critical strike"] = { flag("InstantLifeLeech", { type = "Condition", var = "CriticalStrike" }), flag("InstantManaLeech", { type = "Condition", var = "CriticalStrike" }) },
	["leech applies instantly during flask effect"] = { flag("InstantLifeLeech", { type = "Condition", var = "UsingFlask" }), flag("InstantManaLeech", { type = "Condition", var = "UsingFlask" }) },
	["gain life and mana from leech instantly during flask effect"] = { flag("InstantLifeLeech", { type = "Condition", var = "UsingFlask" }), flag("InstantManaLeech", { type = "Condition", var = "UsingFlask" }) },
	["with 5 corrupted items equipped: life leech recovers based on your chaos damage instead"] = { flag("LifeLeechBasedOnChaosDamage", { type = "MultiplierThreshold", var = "CorruptedItem", threshold = 5 }) },
	["you have vaal pact if you've dealt a critical strike recently"] = { mod("Keystone", "LIST", "Vaal Pact", { type = "Condition", var = "CritRecently" }) },
	["gain (%d+) energy shield for each enemy you hit which is affected by a spider's web"] = function(num) return { mod("EnergyShieldOnHit", "BASE", num, { type = "MultiplierThreshold", actor = "enemy", var = "Spider's WebStack", threshold = 1 }) } end,
	["(%d+) life gained for each enemy hit if you have used a vaal skill recently"] = function(num) return { mod("LifeOnHit", "BASE", num, { type = "Condition", var = "UsedVaalSkillRecently"}) } end,
	-- Defences
	["cannot evade enemy attacks"] = { flag("CannotEvade") },
	["cannot block"] = { flag("CannotBlockAttacks"), flag("CannotBlockSpells") },
	["cannot block attacks"] = { flag("CannotBlockAttacks") },
	["cannot block spells"] = { flag("CannotBlockSpells") },
	["you have no life regeneration"] = { flag("NoLifeRegen") },
	["you have no armour or energy shield"] = {
		mod("Armour", "MORE", -100),
		mod("EnergyShield", "MORE", -100),
	},
	["elemental resistances are zero"] = {
		mod("FireResist", "OVERRIDE", 0),
		mod("ColdResist", "OVERRIDE", 0),
		mod("LightningResist", "OVERRIDE", 0)
	},
	["your maximum resistances are (%d+)%%"] = function(num) return {
		mod("FireResistMax", "OVERRIDE", num),
		mod("ColdResistMax", "OVERRIDE", num),
		mod("LightningResistMax", "OVERRIDE", num),
		mod("ChaosResistMax", "OVERRIDE", num)
	} end,
	["fire resistance is (%d+)%%"] = function(num) return { mod("FireResist", "OVERRIDE", num) } end,
	["cold resistance is (%d+)%%"] = function(num) return { mod("ColdResist", "OVERRIDE", num) } end,
	["lightning resistance is (%d+)%%"] = function(num) return { mod("LightningResist", "OVERRIDE", num) } end,
	["chaos resistance is doubled"] = { mod("ChaosResist", "MORE", 100) },
	["armour is increased by uncapped fire resistance"] = { mod("Armour", "INC", 1, { type = "PerStat", stat = "FireResistTotal", div = 1 }) },
	["evasion rating is increased by uncapped cold resistance"] = { mod("Evasion", "INC", 1, { type = "PerStat", stat = "ColdResistTotal", div = 1 }) },
	["reflects (%d+) physical damage to melee attackers"] = { },
	["ignore all movement penalties from armour"] = { flag("Condition:IgnoreMovementPenalties") },
	["gain armour equal to your reserved mana"] = { mod("Armour", "BASE", 1, { type = "PerStat", stat = "ManaReserved", div = 1 }) },
	["cannot be stunned"] = { mod("AvoidStun", "BASE", 100) },
	["cannot be stunned if you haven't been hit recently"] = { mod("AvoidStun", "BASE", 100, { type = "Condition", var = "BeenHitRecently", neg = true }) },
	["cannot be stunned if you have at least (%d+) crab barriers"] = function(num) return { mod("AvoidStun", "BASE", 100, { type = "StatThreshold", stat = "CrabBarriers", threshold = num }) } end,
	["cannot be shocked"] = { mod("AvoidShock", "BASE", 100) },
	["immune to shock"] = { mod("AvoidShock", "BASE", 100) },
	["cannot be frozen"] = { mod("AvoidFreeze", "BASE", 100) },
	["immune to freeze"] = { mod("AvoidFreeze", "BASE", 100) },
	["cannot be chilled"] = { mod("AvoidChill", "BASE", 100) },
	["immune to chill"] = { mod("AvoidChill", "BASE", 100) },
	["cannot be ignited"] = { mod("AvoidIgnite", "BASE", 100) },
	["immune to ignite"] = { mod("AvoidIgnite", "BASE", 100) },
	["you cannot be shocked while at maximum endurance charges"] = { mod("AvoidShock", "BASE", 100, { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }) },
	["cannot be shocked if intelligence is higher than strength"] = { mod("AvoidShock", "BASE", 100, { type = "Condition", var = "IntHigherThanStr" }) },
	["cannot be frozen if dexterity is higher than intelligence"] = { mod("AvoidFreeze", "BASE", 100, { type = "Condition", var = "DexHigherThanInt" }) },
	["cannot be ignited if strength is higher than dexterity"] = { mod("AvoidIgnite", "BASE", 100, { type = "Condition", var = "StrHigherThanDex" }) },
	["cannot be inflicted with bleeding"] = { mod("AvoidBleed", "BASE", 100) },
	["you are immune to bleeding"] = { mod("AvoidBleed", "BASE", 100) },
	["immune to poison"] = { mod("AvoidPoison", "BASE", 100) },
	["immunity to shock during flask effect"] = { mod("AvoidShock", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immunity to freeze and chill during flask effect"] = { 
		mod("AvoidFreeze", "BASE", 100, { type = "Condition", var = "UsingFlask" }), 
		mod("AvoidChill", "BASE", 100, { type = "Condition", var = "UsingFlask" }) 
	},
	["immunity to ignite during flask effect"] = { mod("AvoidIgnite", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immunity to bleeding during flask effect"] = { mod("AvoidBleed", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immune to poison during flask effect"] = { mod("AvoidPoison", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immune to curses during flask effect"] = { mod("AvoidCurse", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["immune to freeze, chill, curses and stuns during flask effect"] = { 
		mod("AvoidFreeze", "BASE", 100, { type = "Condition", var = "UsingFlask" }), 
		mod("AvoidChill", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
		mod("AvoidCurse", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
		mod("AvoidStun", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
	},
	["unaffected by curses"] = { mod("CurseEffectOnSelf", "MORE", -100) },
	["the effect of chill on you is reversed"] = { flag("SelfChillEffectIsReversed") },
	-- Knockback
	["cannot knock enemies back"] = { flag("CannotKnockback") },
	["knocks back enemies if you get a critical strike with a staff"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Staff, { type = "Condition", var = "CriticalStrike" }) },
	["knocks back enemies if you get a critical strike with a bow"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Bow, { type = "Condition", var = "CriticalStrike" }) },
	["bow knockback at close range"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Bow, { type = "Condition", var = "AtCloseRange" }) },
	["adds knockback during flask effect"] = { mod("EnemyKnockbackChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["adds knockback to melee attacks during flask effect"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "UsingFlask" }) },
	-- Flasks
	["flasks do not apply to you"] = { flag("FlasksDoNotApplyToPlayer") },
	["flasks apply to your zombies and spectres"] = { flag("FlasksApplyToMinion", { type = "SkillName", skillNameList = { "Raise Zombie", "Raise Spectre" } }) },
	["creates a smoke cloud on use"] = { },
	["creates chilled ground on use"] = { },
	["creates consecrated ground on use"] = { },
	["gain unholy might during flask effect"] = { flag("Condition:UnholyMight", { type = "Condition", var = "UsingFlask" }) },
	["zealot's oath during flask effect"] = { mod("ZealotsOath", "FLAG", true, { type = "Condition", var = "UsingFlask" }) },
	["grants level (%d+) (.+) curse aura during flask effect"] = function(num, _, skill) return { mod("ExtraCurse", "LIST", { skillId = gemIdLookup[skill:gsub(" skill","")] or "Unknown", level = num }, { type = "Condition", var = "UsingFlask" }) } end,
	["during flask effect, (%d+)%% reduced damage taken of each element for which your uncapped elemental resistance is lowest"] = function(num) return {
		mod("LightningDamageTaken", "INC", -num, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "ColdResistTotal", upper = true }, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "FireResistTotal", upper = true }),
		mod("ColdDamageTaken", "INC", -num, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "LightningResistTotal", upper = true }, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "FireResistTotal", upper = true }),
		mod("FireDamageTaken", "INC", -num, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "LightningResistTotal", upper = true }, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "ColdResistTotal", upper = true }),
	} end,
	["during flask effect, damage penetrates (%d+)%% o?f? ?resistance of each element for which your uncapped elemental resistance is highest"] = function(num) return {
		mod("LightningPenetration", "BASE", num, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "ColdResistTotal" }, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "FireResistTotal" }),
		mod("ColdPenetration", "BASE", num, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "LightningResistTotal" }, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "FireResistTotal" }),
		mod("FirePenetration", "BASE", num, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "LightningResistTotal" }, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "ColdResistTotal" }),
	} end,
	["(%d+)%% of maximum life taken as chaos damage per second"] = function(num) return { mod("ChaosDegen", "BASE", num/100, { type = "PerStat", stat = "Life", div = 1 }) } end,
	["your critical strikes do not deal extra damage during flask effect"] = { flag("NoCritMultiplier", { type = "Condition", var = "UsingFlask" }) },
	["grants perfect agony during flask effect"] = { mod("Keystone", "LIST", "Perfect Agony", { type = "Condition", var = "UsingFlask" }) },
	["consecrated ground created during effect applies (%d+)%% increased damage taken to enemies"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "OnConsecratedGround" }) }, { type = "Condition", var = "UsingFlask" }) } end,	-- Jewels
	["passives in radius can be allocated without being connected to your tree"] = { mod("JewelData", "LIST", { key = "intuitiveLeap", value = true }) },
	["(%d+)%% increased elemental damage per grand spectrum"] = function(num) return { 
		mod("ElementalDamage", "INC", num, { type = "Multiplier", var = "GrandSpectrum" }), 
		mod("Multiplier:GrandSpectrum", "BASE", 1) 
	} end,
	["gain (%d+) armour per grand spectrum"] = function(num) return { 
		mod("Armour", "BASE", num, { type = "Multiplier", var = "GrandSpectrum" }), 
		mod("Multiplier:GrandSpectrum", "BASE", 1) 
	} end,
	["gain (%d+) mana per grand spectrum"] = function(num) return {
		mod("Mana", "BASE", num, { type = "Multiplier", var = "GrandSpectrum" }),
		mod("Multiplier:GrandSpectrum", "BASE", 1) 
	} end,
	["primordial"] = { mod("Multiplier:PrimordialItem", "BASE", 1) },
	["spectres have a base duration of (%d+) seconds"] = function(num) return { mod("SkillData", "LIST", { key = "duration", value = 6 }, { type = "SkillName", skillName = "Raise Spectre" }) } end,
	["flasks applied to you have (%d+)%% increased effect"] = function(num) return { mod("FlaskEffect", "INC", num) } end,
	-- Misc
	["iron will"] = { flag("IronWill") },
	["iron reflexes while stationary"] = { mod("Keystone", "LIST", "Iron Reflexes", { type = "Condition", var = "Stationary" }) },
	["you have zealot's oath if you haven't been hit recently"] = { mod("Keystone", "LIST", "Zealot's Oath", { type = "Condition", var = "BeenHitRecently", neg = true }) },
	["deal no physical damage"] = { flag("DealNoPhysical") },
	["deal no elemental damage"] = { flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoFire") },
	["deal no chaos damage"] = { flag("DealNoChaos") },
	["deal no non%-elemental damage"] = { flag("DealNoPhysical"), flag("DealNoChaos") },
	["attacks have blood magic"] = { flag("SkillBloodMagic", nil, ModFlag.Attack) },
	["(%d+)%% chance to cast a? ?socketed lightning spells? on hit"] = function(num) return { mod("ExtraSupport", "LIST", { name = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["cast a socketed lightning spell on hit"] = { mod("ExtraSupport", "LIST", { name = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed lightning spell on hit"] = { mod("ExtraSupport", "LIST", { name = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["cast a socketed cold s[pk][ei]ll on melee critical strike"] = { mod("ExtraSupport", "LIST", { name = "SupportUniqueCosprisMaliceColdSpellsCastOnMeleeCriticalStrike", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["your curses can apply to hexproof enemies"] = { flag("CursesIgnoreHexproof") },
	["you have onslaught while you have fortify"] = { flag("Condition:Onslaught", { type = "Condition", var = "Fortify" }) },
	["reserves (%d+)%% of life"] = function(num) return { mod("ExtraLifeReserved", "BASE", num) } end,
	["items and gems have (%d+)%% reduced attribute requirements"] = function(num) return { mod("GlobalAttributeRequirements", "INC", -num) } end,
	["items and gems have (%d+)%% increased attribute requirements"] = function(num) return { mod("GlobalAttributeRequirements", "INC", num) } end,
	["mana reservation of herald skills is always (%d+)%%"] = function(num) return { mod("SkillData", "LIST", { key = "manaCostForced", value = num }, { type = "SkillType", skillType = SkillType.Herald }) } end,
	["([%a%s]+) reserves no mana"] = function(_, name) return { mod("SkillData", "LIST", { key = "manaCostForced", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }) } end,
	["banner skills reserve no mana"] = { mod("SkillData", "LIST", { key = "manaCostForced", value = 0 }, { type = "SkillName", skillNameList = { "Dread Banner", "War Banner" } }) },
	["your spells are disabled"] = { flag("DisableSkill", { type = "SkillType", skillType = SkillType.Spell }) },
	["strength's damage bonus instead grants (%d+)%% increased melee physical damage per (%d+) strength"] = function(num, _, perStr) return { mod("StrDmgBonusRatioOverride", "BASE", num / tonumber(perStr)) } end,
	["while in her embrace, take ([%d%.]+)%% of your total maximum life and energy shield as fire damage per second per level"] = function(num) return { 
		mod("FireDegen", "BASE", 0.005, { type = "PerStat", stat = "Life" }, { type = "Multiplier", var = "Level" }, { type = "Condition", var = "HerEmbrace" }),
		mod("FireDegen", "BASE", 0.005, { type = "PerStat", stat = "EnergyShield" }, { type = "Multiplier", var = "Level" }, { type = "Condition", var = "HerEmbrace" }),
	} end,
	["gain her embrace for %d+ seconds when you ignite an enemy"] = { flag("Condition:CanGainHerEmbrace") },	
	["hits ignore enemy monster fire resistance while you are ignited"] = { flag("IgnoreFireResistance", { type = "Condition", var = "Ignited" }) },
	["your hits can't be evaded by blinded enemies"] = { flag("CannotBeEvaded", { type = "ActorCondition", actor = "enemy", var = "Blinded" }) },
	["skills which throw traps have blood magic"] = { flag("BloodMagic", { type = "SkillType", skillType = SkillType.Trap }) },
	["lose ([%d%.]+) mana per second"] = function(num) return { mod("ManaDegen", "BASE", num) } end,
	["lose ([%d%.]+)%% of maximum mana per second"] = function(num) return { mod("ManaDegen", "BASE", num/100, { type = "PerStat", stat = "Mana" }) } end,
	["strength provides no bonus to maximum life"] = { flag("NoStrBonusToLife") },
	["intelligence provides no bonus to maximum mana"] = { flag("NoIntBonusToMana") },
	["with a ghastly eye jewel socketed, minions have %+(%d+) to accuracy rating"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Accuracy", "BASE", num) }, { type = "Condition", var = "HaveGhastlyEyeJewelIn{SlotName}" }) } end,
	["hits ignore enemy monster chaos resistance if all equipped items are shaper items"] = { flag("IgnoreChaosResistance", { type = "MultiplierThreshold", var = "NonShaperItem", upper = true, threshold = 0 }) },
	["gain %d+ rage on critical hit with attacks, no more than once every [%d%.]+ seconds"] = {
		flag("Condition:CanGainRage"),
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "CanGainRage" }) -- Make the Configuration option appear
	},
	["warcry skills' cooldown time is (%d+) seconds"] = function(num) return { mod("CooldownRecovery", "OVERRIDE", 2, nil, 0, KeywordFlag.Warcry) } end,
	["your critical strike multiplier is (%d+)%%"] = function(num) return { mod("CritMultiplier", "OVERRIDE", num) } end,
	["base critical strike chance for attacks with weapons is ([%d%.]+)%%"] = function(num) return { mod("WeaponBaseCritChance", "OVERRIDE", num) } end,
	["allocates (.+)"] = function(_, passive) return { mod("GrantedPassive", "LIST", passive) } end,
	["transfiguration of body"] = { flag("TransfigurationOfBody") },
	["transfiguration of mind"] = { flag("TransfigurationOfMind") },
	["transfiguration of soul"] = { flag("TransfigurationOfSoul") },
	["offering skills have (%d+)%% reduced duration"] = function(num) return {
		mod("Duration", "INC", -num, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } }),
	} end,
	-- Skill-specific enchantment modifiers
	["(%d+)%% increased decoy totem life"] = function(num) return { mod("TotemLife", "INC", num, { type = "SkillName", skillName = "Decoy Totem" }) } end,
	["(%d+)%% increased ice spear critical strike chance in second form"] = function(num) return { mod("CritChance", "INC", num, { type = "SkillName", skillName = "Ice Spear" }, { type = "SkillPart", skillPart = 2 }) } end,
	["shock nova ring deals (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num, { type = "SkillName", skillName = "Shock Nova" }, { type = "SkillPart", skillPart = 1 }) } end,
	["lightning strike pierces (%d) additional targets?"] = function(num) return { mod("PierceCount", "BASE", num, { type = "SkillName", skillName = "Lightning Strike" }) } end,
	["lightning trap pierces (%d) additional targets?"] = function(num) return { mod("PierceCount", "BASE", num, { type = "SkillName", skillName = "Lightning Trap" }) } end,
	["enemies affected by bear trap take (%d+)%% increased damage from trap or mine hits"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("TrapMineDamageTaken", "INC", num, { type = "GlobalEffect", effectType = "Debuff" }) }, { type = "SkillName", skillName = "Bear Trap" }) } end,
	["blade vortex has %+(%d+)%% to critical strike multiplier for each blade"] = function(num) return { mod("CritMultiplier", "BASE", num, { type = "Multiplier", var = "BladeVortexBlade" }, { type = "SkillName", skillName = "Blade Vortex" }) } end,
	["double strike has a (%d+)%% chance to deal double damage to bleeding enemies"] = function(num) return { mod("DoubleDamageChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }, { type = "SkillName", skillName = "Double Strike" }) } end,
	["ethereal knives pierces an additional target"] = { mod("PierceCount", "BASE", 1, { type = "SkillName", skillName = "Ethereal Knives" }) },
	["frost bomb has (%d+)%% increased debuff duration"] = function(num) return { mod("SecondaryDuration", "INC", num, { type = "SkillName", skillName = "Frost Bomb" }) } end,
	["incinerate has %+(%d+) to maximum stages"] = function(num) return {
		mod("Multiplier:IncinerateStage", "BASE", num/2, 0, 0, { type = "SkillPart", skillPart = 2 }),
		mod("Multiplier:IncinerateStage", "BASE", num, 0, 0, { type = "SkillPart", skillPart = 3 })
	} end,
	["scourge arrow has (%d+)%% chance to poison per stage"] = function(num) return { mod("PoisonChance", "BASE", num, { type = "SkillName", skillName = "Scourge Arrow" }, { type = "Multiplier", var = "ScourgeArrowStage" }) } end,
	["winter orb has %+(%d+) maximum stages"] = function(num) return { mod("Multiplier:WinterOrbMaxStage", "BASE", num) } end,
	["winter orb has (%d+)%% increased area of effect per stage"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "SkillName", skillName = "Winter Orb"}, { type = "Multiplier", var = "WinterOrbStage" }) } end,
	["wave of conviction's exposure applies (%-%d+)%% elemental resistance"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "purge_expose_resist_%_matching_highest_element_damage", value = num }, { type = "SkillName", skillName = "Wave of Conviction" }) } end,
	-- Display-only modifiers
	["prefixes:"] = { },
	["suffixes:"] = { },
	["while your passive skill tree connects to a class' starting location, you gain:"] = { },
	["socketed lightning spells [hd][ae][va][el] (%d+)%% increased spell damage if triggered"] = { },
	["manifeste?d? dancing dervish disables both weapon slots"] = { },
	["manifeste?d? dancing dervish dies when rampage ends"] = { },
}
local keystoneList = {
	-- List of keystones that can be found on uniques
	"Acrobatics",
	"Ancestral Bond",
	"Arrow Dancing",
	"Avatar of Fire",
	"Blood Magic",
	"Conduit",
	"Crimson Dance",
	"Eldritch Battery",
	"Elemental Equilibrium",
	"Elemental Overload",
	"Ghost Reaver",
	"Iron Grip",
	"Iron Reflexes",
	"Mind Over Matter",
	"Minion Instability",
	"Pain Attunement",
	"Perfect Agony",
	"Phase Acrobatics",
	"Point Blank",
	"Resolute Technique",
	"Unwavering Stance",
	"Vaal Pact",
	"Zealot's Oath",
}
for _, name in pairs(keystoneList) do
	specialModList[name:lower()] = { mod("Keystone", "LIST", name) }
end
local oldList = specialModList
specialModList = { }
for k, v in pairs(oldList) do
	specialModList["^"..k.."$"] = v
end

-- Modifiers that are recognised but unsupported
local unsupportedModList = {
	["culling strike"] = true,
	["properties are doubled while in a breach"] = true,
}

-- Special lookups used for various modifier forms
local suffixTypes = {
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
	["converted to lightning"] = "ConvertToLightning",
	["converted to lightning damage"] = "ConvertToLightning",
	["converted to cold damage"] = "ConvertToCold",
	["converted to fire damage"] = "ConvertToFire",
	["converted to chaos damage"] = "ConvertToChaos",
	["added as energy shield"] = "GainAsEnergyShield",
	["as extra maximum energy shield"] = "GainAsEnergyShield",
	["converted to energy shield"] = "ConvertToEnergyShield",
	["as physical damage"] = "AsPhysical",
	["as lightning damage"] = "AsLightning",
	["as cold damage"] = "AsCold",
	["as fire damage"] = "AsFire",
	["as chaos damage"] = "AsChaos",
	["leeched as life and mana"] = "Leech",
	["leeched as life"] = "LifeLeech",
	["is leeched as life"] = "LifeLeech",
	["leeched as mana"] = "ManaLeech",
	["is leeched as mana"] = "ManaLeech",
	["leeched as energy shield"] = "EnergyShieldLeech",
	["is leeched as energy shield"] = "EnergyShieldLeech",
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
	["chaos resistance"] = "ChaosPenetration",
}
local regenTypes = {
	["life"] = "LifeRegen",
	["maximum life"] = "LifeRegen",
	["life and mana"] = { "LifeRegen", "ManaRegen" },
	["mana"] = "ManaRegen",
	["maximum mana"] = "ManaRegen",
	["energy shield"] = "EnergyShieldRegen",
	["maximum energy shield"] = "EnergyShieldRegen",
	["maximum mana and energy shield"] = { "ManaRegen", "EnergyShieldRegen" },
}

-- Build active skill name lookup
local skillNameList = {
	[" corpse cremation " ] = { tag = { type = "SkillName", skillName = "Cremation" } }, -- Sigh.
}
local preSkillNameList = { }
for gemId, gemData in pairs(data["3_0"].gems) do
	local grantedEffect = gemData.grantedEffect
	if not grantedEffect.hidden and not grantedEffect.support then
		local skillName = grantedEffect.name
		skillNameList[" "..skillName:lower().." "] = { tag = { type = "SkillName", skillName = skillName } }
		preSkillNameList["^"..skillName:lower().." "] = { tag = { type = "SkillName", skillName = skillName } }
		preSkillNameList["^"..skillName:lower().." has ?a? "] = { tag = { type = "SkillName", skillName = skillName } }
		preSkillNameList["^"..skillName:lower().." deals "] = { tag = { type = "SkillName", skillName = skillName } }
		preSkillNameList["^"..skillName:lower().." damage "] = { tag = { type = "SkillName", skillName = skillName } }
		if gemData.tags.totem then
			preSkillNameList["^"..skillName:lower().." totem deals "] = { tag = { type = "SkillName", skillName = skillName } }
			preSkillNameList["^"..skillName:lower().." totem grants "] = { addToSkill = { type = "SkillName", skillName = skillName }, tag = { type = "GlobalEffect", effectType = "Buff" } }
		end
		if grantedEffect.skillTypes[SkillType.Buff] or grantedEffect.baseFlags.buff then
			preSkillNameList["^"..skillName:lower().." grants "] = { addToSkill = { type = "SkillName", skillName = skillName }, tag = { type = "GlobalEffect", effectType = "Buff" } }
			preSkillNameList["^"..skillName:lower().." grants a?n? ?additional "] = { addToSkill = { type = "SkillName", skillName = skillName }, tag = { type = "GlobalEffect", effectType = "Buff" } }
		end
		if gemData.tags.aura or gemData.tags.herald then
			skillNameList["while affected by "..skillName:lower()] = { tag = { type = "Condition", var = "AffectedBy"..skillName:gsub(" ","") } }
			skillNameList["while using "..skillName:lower()] = { tag = { type = "Condition", var = "AffectedBy"..skillName:gsub(" ","") } }
		end
		if gemData.tags.mine then
			specialModList["^"..skillName:lower().." has (%d+)%% increased throwing speed"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("MineLayingSpeed", "INC", num) }, { type = "SkillName", skillName = skillName }) } end
		end
		if gemData.tags.chaining then
			specialModList["^"..skillName:lower().." chains an additional time"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", 1) }, { type = "SkillName", skillName = skillName }) }
			specialModList["^"..skillName:lower().." chains an additional (%d+) times"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = skillName }) } end
			specialModList["^"..skillName:lower().." chains (%d+) additional times"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = skillName }) } end
		end
		if gemData.tags.bow then
			specialModList["^"..skillName:lower().." fires (%d+) additional arrows?"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SkillName", skillName = skillName }) } end
		end
		if gemData.tags.bow or gemData.tags.projectile then
			specialModList["^"..skillName:lower().." fires an additional projectile"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", 1) }, { type = "SkillName", skillName = skillName }) }
			specialModList["^"..skillName:lower().." fires (%d+) additional projectiles"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SkillName", skillName = skillName }) } end
		end
	end	
end

-- Radius jewels that modify other nodes
local function getSimpleConv(srcList, dst, type, remove, factor)
	return function(node, out, data)
		if node then
			for _, src in pairs(srcList) do
				for _, mod in ipairs(node.modList) do
					if mod.name == src and mod.type == type then
						if remove then
							out:MergeNewMod(src, type, -mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
						end
						if factor then
							out:MergeNewMod(dst, type, math.floor(mod.value * factor), mod.source, mod.flags, mod.keywordFlags, unpack(mod))
						else
							out:MergeNewMod(dst, type, mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
						end
					end
				end	
			end
		end
	end
end
local jewelOtherFuncs = {
	["Strength from Passives in Radius is Transformed to Dexterity"] = getSimpleConv({"Str"}, "Dex", "BASE", true),
	["Dexterity from Passives in Radius is Transformed to Strength"] = getSimpleConv({"Dex"}, "Str", "BASE", true),
	["Strength from Passives in Radius is Transformed to Intelligence"] = getSimpleConv({"Str"}, "Int", "BASE", true),
	["Intelligence from Passives in Radius is Transformed to Strength"] = getSimpleConv({"Int"}, "Str", "BASE", true),
	["Dexterity from Passives in Radius is Transformed to Intelligence"] = getSimpleConv({"Dex"}, "Int", "BASE", true),
	["Intelligence from Passives in Radius is Transformed to Dexterity"] = getSimpleConv({"Int"}, "Dex", "BASE", true),
	["Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield"] = getSimpleConv({"Life"}, "EnergyShield", "INC", true),
	["Increases and Reductions to Energy Shield in Radius are Transformed to apply to Armour at 200% of their value"] = getSimpleConv({"EnergyShield"}, "Armour", "INC", true, 2),
	["Increases and Reductions to Life in Radius are Transformed to apply to Mana at 200% of their value"] = getSimpleConv({"Life"}, "Mana", "INC", true, 2),
	["Increases and Reductions to Physical Damage in Radius are Transformed to apply to Cold Damage"] = getSimpleConv({"PhysicalDamage"}, "ColdDamage", "INC", true),
	["Increases and Reductions to Cold Damage in Radius are Transformed to apply to Physical Damage"] = getSimpleConv({"ColdDamage"}, "PhysicalDamage", "INC", true),
	["Increases and Reductions to other Damage Types in Radius are Transformed to apply to Fire Damage"] = getSimpleConv({"PhysicalDamage","ColdDamage","LightningDamage","ChaosDamage"}, "FireDamage", "INC", true),
	["Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spells at 35% of its value"] = getSimpleConv({"LightningResist","ElementalResist"}, "SpellBlockChance", "BASE", false, 0.35),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Dodge Attacks at 35% of its value"] = getSimpleConv({"ColdResist","ElementalResist"}, "AttackDodgeChance", "BASE", false, 0.35),
	["Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block Attack Damage at 35% of its value"] = getSimpleConv({"FireResist","ElementalResist"}, "BlockChance", "BASE", false, 0.35),
	["Melee and Melee Weapon Type modifiers in Radius are Transformed to Bow Modifiers"] = function(node, out, data)
		if node then
			local mask1 = bor(ModFlag.Axe, ModFlag.Claw, ModFlag.Dagger, ModFlag.Mace, ModFlag.Staff, ModFlag.Sword, ModFlag.Melee)
			local mask2 = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee)
			local mask3 = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee)
			for _, mod in ipairs(node.modList) do
				if band(mod.flags, mask1) ~= 0 or band(mod.flags, mask2) == mask2 or band(mod.flags, mask3) == mask3 then
					out:MergeNewMod(mod.name, mod.type, -mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
					out:MergeNewMod(mod.name, mod.type, mod.value, mod.source, bor(band(mod.flags, bnot(bor(mask1, mask2, mask3))), ModFlag.Bow), mod.keywordFlags, unpack(mod))
				elseif mod[1] then
					local using = { UsingAxe = true, UsingClaw = true, UsingDagger = true, UsingMace = true, UsingStaff = true, UsingSword = true, UsingMeleeWeapon = true }
					for _, tag in ipairs(mod) do
						if tag.type == "Condition" and using[tag.var] then
							local newTagList = copyTable(mod)
							for _, tag in ipairs(newTagList) do
								if tag.type == "Condition" and using[tag.var] then
									tag.var = "UsingBow"
									break
								end
							end
							out:MergeNewMod(mod.name, mod.type, -mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
							out:MergeNewMod(mod.name, mod.type, mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(newTagList))
							break
						end
					end
				end
			end
		end
	end,
	["50% increased Effect of non-Keystone Passive Skills in Radius"] = function(node, out, data)
		if node and node.type ~= "Keystone" then
			out:NewMod("PassiveSkillEffect", "INC", 50, data.modSource)
		end
	end,
	["Notable Passive Skills in Radius grant nothing"] = function(node, out, data)
		if node and node.type == "Notable" then
			out:NewMod("PassiveSkillHasNoEffect", "FLAG", true, data.modSource)
		end
	end,
	["Allocated Small Passive Skills in Radius grant nothing"] = function(node, out, data)
		if node and node.type == "Normal" then
			out:NewMod("AllocatedPassiveSkillHasNoEffect", "FLAG", true, data.modSource)
		end
	end,
	["Passive Skills in Radius also grant: Traps and Mines deal (%d+) to (%d+) added Physical Damage"] = function(min, max)
		return function(node, out, data)
			if node and node.type ~= "Keystone" then
				out:NewMod("PhysicalMin", "BASE", min, data.modSource, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine))
				out:NewMod("PhysicalMax", "BASE", max, data.modSource, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine))
			end
		end
	end,
}

-- Radius jewels that modify the jewel itself based on nearby allocated nodes
local function getPerStat(dst, modType, flags, stat, factor)
	return function(node, out, data)
		if node then
			data[stat] = (data[stat] or 0) + out:Sum("BASE", nil, stat)
		elseif data[stat] ~= 0 then
			out:NewMod(dst, modType, math.floor((data[stat] or 0) * factor + 0.5), data.modSource, flags)
		end
	end
end
local jewelSelfFuncs = {
	["Adds 1 to maximum Life per 3 Intelligence in Radius"] = getPerStat("Life", "BASE", 0, "Int", 1 / 3),
	["Adds 1 to Maximum Life per 3 Intelligence Allocated in Radius"] = getPerStat("Life", "BASE", 0, "Int", 1 / 3),
	["1% increased Evasion Rating per 3 Dexterity Allocated in Radius"] = getPerStat("Evasion", "INC", 0, "Dex", 1 / 3),
	["1% increased Claw Physical Damage per 3 Dexterity Allocated in Radius"] = getPerStat("PhysicalDamage", "INC", ModFlag.Claw, "Dex", 1 / 3),
	["1% increased Melee Physical Damage while Unarmed per 3 Dexterity Allocated in Radius"] = getPerStat("PhysicalDamage", "INC", ModFlag.Unarmed, "Dex", 1 / 3),
	["3% increased Totem Life per 10 Strength in Radius"] = getPerStat("TotemLife", "INC", 0, "Str", 3 / 10),
	["3% increased Totem Life per 10 Strength Allocated in Radius"] = getPerStat("TotemLife", "INC", 0, "Str", 3 / 10),
	["Adds 1 maximum Lightning Damage to Attacks per 1 Dexterity Allocated in Radius"] = getPerStat("LightningMax", "BASE", ModFlag.Attack, "Dex", 1),
	["5% increased Chaos damage per 10 Intelligence from Allocated Passives in Radius"] = getPerStat("ChaosDamage", "INC", 0, "Int", 5 / 10),
	["Dexterity and Intelligence from passives in Radius count towards Strength Melee Damage bonus"] = function(node, out, data)
		if node then
			data.Dex = (data.Dex or 0) + node.modList:Sum("BASE", nil, "Dex")
			data.Int = (data.Int or 0) + node.modList:Sum("BASE", nil, "Int")
		else
			out:NewMod("DexIntToMeleeBonus", "BASE", data.Dex + data.Int, data.modSource)
		end
	end,
	["-1 Strength per 1 Strength on Allocated Passives in Radius"] = getPerStat("Str", "BASE", 0, "Str", -1),
	["1% additional Physical Damage Reduction per 10 Strength on Allocated Passives in Radius"] = getPerStat("PhysicalDamageReduction", "BASE", 0, "Str", 1 / 10),
	["-1 Intelligence per 1 Intelligence on Allocated Passives in Radius"] = getPerStat("Int", "BASE", 0, "Int", -1),
	["0.4% of Energy Shield Regenerated per Second for every 10 Intelligence on Allocated Passives in Radius"] = getPerStat("EnergyShieldRegenPercent", "BASE", 0, "Int", 0.4 / 10),
	["-1 Dexterity per 1 Dexterity on Allocated Passives in Radius"] = getPerStat("Dex", "BASE", 0, "Dex", -1),
	["2% increased Movement Speed per 10 Dexterity on Allocated Passives in Radius"] = getPerStat("MovementSpeed", "INC", 0, "Dex", 2 / 10),
}
local jewelSelfUnallocFuncs = {
	["+7% to Critical Strike Multiplier per 10 Strength on Unallocated Passives in Radius"] = getPerStat("CritMultiplier", "BASE", 0, "Str", 7 / 10),
	["+15 to maximum Mana per 10 Dexterity on Unallocated Passives in Radius"] = getPerStat("Mana", "BASE", 0, "Dex", 15 / 10),
	["+125 to Accuracy Rating per 10 Intelligence on Unallocated Passives in Radius"] = getPerStat("Accuracy", "BASE", 0, "Int", 125 / 10),
	["Grants all bonuses of Unallocated Small Passive Skills in Radius"] = function(node, out, data)
		if node then
			if node.type == "Normal" then
				data.modList = data.modList or new("ModList")
				data.modList:AddList(out)
			end
		elseif data.modList then
			out:AddList(data.modList)
		end
	end,
}

-- Radius jewels with bonuses conditional upon attributes of nearby nodes
local function getThreshold(attrib, name, modType, value, ...)
	local baseMod = mod(name, modType, value, "", ...)
	return function(node, out, data)
		if node then
			if type(attrib) == "table" then
				for _, att in ipairs(attrib) do
					local nodeVal = out:Sum("BASE", nil, att)
					data[att] = (data[att] or 0) + nodeVal
					data.total = (data.total or 0) + nodeVal
				end
			else
				local nodeVal = out:Sum("BASE", nil, attrib)
				data[attrib] = (data[attrib] or 0) + nodeVal
				data.total = (data.total or 0) + nodeVal
			end
		elseif (data.total or 0) >= 40 then
			local mod = copyTable(baseMod)
			mod.source = data.modSource
			if type(value) == "table" and value.mod then
				value.mod.source = data.modSource
			end
			out:AddMod(mod)
		end
	end
end
local jewelThresholdFuncs = {
	["With at least 40 Dexterity in Radius, Frost Blades Melee Damage Penetrates 15% Cold Resistance"] = getThreshold("Dex", "ColdPenetration", "BASE", 15, ModFlag.Melee, { type = "SkillName", skillName = "Frost Blades" }),
	["With at least 40 Dexterity in Radius, Melee Damage dealt by Frost Blades Penetrates 15% Cold Resistance"] = getThreshold("Dex", "ColdPenetration", "BASE", 15, ModFlag.Melee, { type = "SkillName", skillName = "Frost Blades" }),
	["With at least 40 Dexterity in Radius, Frost Blades has 25% increased Projectile Speed"] = getThreshold("Dex", "ProjectileSpeed", "INC", 25, { type = "SkillName", skillName = "Frost Blades" }),
	["With at least 40 Dexterity in Radius, Ice Shot has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Ice Shot" }),
	["Ice Shot Pierces 5 additional Targets with 40 Dexterity in Radius"] = getThreshold("Dex", "PierceCount", "BASE", 5, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Dexterity in Radius, Ice Shot Pierces 3 additional Targets"] = getThreshold("Dex", "PierceCount", "BASE", 3, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Dexterity in Radius, Ice Shot Pierces 5 additional Targets"] = getThreshold("Dex", "PierceCount", "BASE", 5, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Intelligence in Radius, Frostbolt fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Frostbolt" }),
	["With at least 40 Intelligence in Radius, Magma Orb fires an additional Projectile"] = getThreshold("Int", "ProjectileCount", "BASE", 1, { type = "SkillName", skillName = "Magma Orb" }),
	["With at least 40 Intelligence in Radius, Magma Orb has 10% increased Area of Effect per Chain"] = getThreshold("Int", "AreaOfEffect", "INC", 10, { type = "SkillName", skillName = "Magma Orb" }, { type = "PerStat", stat = "Chain" }),
	["With at least 40 Dexterity in Radius, Shrapnel Shot has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Shrapnel Shot" }),
	["With at least 40 Dexterity in Radius, Shrapnel Shot's cone has a 50% chance to deal Double Damage"] = getThreshold("Dex", "DoubleDamageChance", "BASE", 50, { type = "SkillName", skillName = "Shrapnel Shot" }, { type = "SkillPart", skillPart = 2 }),
	["With at least 40 Intelligence in Radius, Freezing Pulse fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Freezing Pulse" }),
	["With at least 40 Intelligence in Radius, 25% increased Freezing Pulse Damage if you've Shattered an Enemy Recently"] = getThreshold("Int", "Damage", "INC", 25, { type = "SkillName", skillName = "Freezing Pulse" }, { type = "Condition", var = "ShatteredEnemyRecently" }),
	["With at least 40 Dexterity in Radius, Ethereal Knives fires 10 additional Projectiles"] = getThreshold("Dex", "ProjectileCount", "BASE", 10, { type = "SkillName", skillName = "Ethereal Knives" }),
	["With at least 40 Dexterity in Radius, Ethereal Knives fires 5 additional Projectiles"] = getThreshold("Dex", "ProjectileCount", "BASE", 5, { type = "SkillName", skillName = "Ethereal Knives" }),
	["With at least 40 Strength in Radius, Molten Strike fires 2 additional Projectiles"] = getThreshold("Str", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Molten Strike" }),
	["With at least 40 Strength in Radius, Molten Strike has 25% increased Area of Effect"] = getThreshold("Str", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Molten Strike" }),
	["With at least 40 Strength in Radius, 25% of Glacial Hammer Physical Damage converted to Cold Damage"] = getThreshold("Str", "SkillPhysicalDamageConvertToCold", "BASE", 25, { type = "SkillName", skillName = "Glacial Hammer" }),
	["With at least 40 Strength in Radius, Heavy Strike has a 20% chance to deal Double Damage"] = getThreshold("Str", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Heavy Strike" }),
	["With at least 40 Strength in Radius, Heavy Strike has a 20% chance to deal Double Damage."] = getThreshold("Str", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Heavy Strike" }),
	["With at least 40 Dexterity in Radius, Dual Strike has a 20% chance to deal Double Damage with the Main-Hand Weapon"] = getThreshold("Dex", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Dual Strike" }, { type = "Condition", var = "MainHandAttack" }),
	["With at least 40 Intelligence in Radius, Raised Zombies' Slam Attack has 100% increased Cooldown Recovery Speed"] = getThreshold("Int", "MinionModifier", "LIST", { mod = mod("CooldownRecovery", "INC", 100, { type = "SkillId", skillId = "ZombieSlam" }) }),
	["With at least 40 Intelligence in Radius, Raised Zombies' Slam Attack deals 30% increased Damage"] = getThreshold("Int", "MinionModifier", "LIST", { mod = mod("Damage", "INC", 30, { type = "SkillId", skillId = "ZombieSlam" }) }),
	["With at least 40 Dexterity in Radius, Viper Strike deals 2% increased Attack Damage for each Poison on the Enemy"] = getThreshold("Dex", "Damage", "INC", 2, ModFlag.Attack, { type = "SkillName", skillName = "Viper Strike" }, { type = "Multiplier", actor = "enemy", var = "PoisonStack" }),
	["With at least 40 Dexterity in Radius, Viper Strike deals 2% increased Damage with Hits and Poison for each Poison on the Enemy"] = getThreshold("Dex", "Damage", "INC", 2, 0, bor(KeywordFlag.Hit, KeywordFlag.Poison), { type = "SkillName", skillName = "Viper Strike" }, { type = "Multiplier", actor = "enemy", var = "PoisonStack" }),
	["With at least 40 Intelligence in Radius, Spark fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Spark" }),
	["With at least 40 Intelligence in Radius, Blight has 50% increased Hinder Duration"] = getThreshold("Int", "SecondaryDuration", "INC", 50, { type = "SkillName", skillName = "Blight" }),
	["With at least 40 Intelligence in Radius, Enemies Hindered by Blight take 25% increased Chaos Damage"] = getThreshold("Int", "ExtraSkillMod", "LIST", { mod = mod("ChaosDamageTaken", "INC", 25, { type = "GlobalEffect", effectType = "Debuff", effectName = "Hinder" }) }, { type = "SkillName", skillName = "Blight" }, { type = "ActorCondition", actor = "enemy", var = "Hindered" }),
	["With 40 Intelligence in Radius, 20% of Glacial Cascade Physical Damage Converted to Cold Damage"] = getThreshold("Int", "SkillPhysicalDamageConvertToCold", "BASE", 20, { type = "SkillName", skillName = "Glacial Cascade" }),
	["With at least 40 Intelligence in Radius, 20% of Glacial Cascade Physical Damage Converted to Cold Damage"] = getThreshold("Int", "SkillPhysicalDamageConvertToCold", "BASE", 20, { type = "SkillName", skillName = "Glacial Cascade" }),
	["With 40 total Intelligence and Dexterity in Radius, Elemental Hit and Wild Strike deal 50% less Fire Damage"] = getThreshold({"Int","Dex"}, "FireDamage", "MORE", -50, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" } }),
	["With 40 total Strength and Intelligence in Radius, Elemental Hit and Wild Strike deal 50% less Cold Damage"] = getThreshold({"Str","Int"}, "ColdDamage", "MORE", -50, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" } }),
	["With 40 total Dexterity and Strength in Radius, Elemental Hit and Wild Strike deal 50% less Lightning Damage"] = getThreshold({"Dex","Str"}, "LightningDamage", "MORE", -50, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" } }),
	["With 40 total Dexterity and Strength in Radius, Spectral Shield Throw Chains +4 times"] = getThreshold({"Dex","Str"}, "ChainCountMax", "BASE", 4, { type = "SkillName", skillName = "Spectral Shield Throw" }),
	["With 40 total Dexterity and Strength in Radius, Spectral Shield Throw fires 75% less Shard Projectiles"] = getThreshold({"Dex","Str"}, "ProjectileCount", "MORE", -75, { type = "SkillName", skillName = "Spectral Shield Throw" }),
	--[""] = getThreshold("", "", "", , { type = "SkillName", skillName = "" }),
}

-- Unified list of jewel functions
local jewelFuncList = { }
for k, v in pairs(jewelOtherFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "Other" }
end
for k, v in pairs(jewelSelfFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "Self" }
end
for k, v in pairs(jewelSelfUnallocFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "SelfUnalloc" }
end
for k, v in pairs(jewelThresholdFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "Threshold" }
end

-- Scan a line for the earliest and longest match from the pattern list
-- If a match is found, returns the corresponding value from the pattern list, plus the remainder of the line and a table of captures
local function scan(line, patternList, plain)
	local bestIndex, bestEndIndex
	local bestPattern = ""
	local bestVal, bestStart, bestEnd, bestCaps
	local lineLower = line:lower()
	for pattern, patternVal in pairs(patternList) do
		local index, endIndex, cap1, cap2, cap3, cap4, cap5 = lineLower:find(pattern, 1, plain)
		if index and (not bestIndex or index < bestIndex or (index == bestIndex and (endIndex > bestEndIndex or (endIndex == bestEndIndex and #pattern > #bestPattern)))) then
			bestIndex = index
			bestEndIndex = endIndex
			bestPattern = pattern
			bestVal = patternVal
			bestStart = index
			bestEnd = endIndex
			bestCaps = { cap1, cap2, cap3, cap4, cap5 }
		end
	end
	if bestVal then
		return bestVal, line:sub(1, bestStart - 1) .. line:sub(bestEnd + 1, -1), bestCaps
	else
		return nil, line
	end
end

local function parseMod(line, order)
	-- Check if this is a special modifier
	local lineLower = line:lower()
	local bestVal, _, bestCaps = scan(line, jewelFuncList)
	for pattern, patternVal in pairs(jewelFuncList) do
		local _, _, cap1, cap2, cap3, cap4, cap5 = lineLower:find(pattern, 1)
		if cap1 then
			return {mod("JewelFunc", "LIST", {func = patternVal.func(cap1, cap2, cap3, cap4, cap5), type = patternVal.type}) }
		end
	end
	local jewelFunc = jewelFuncList[lineLower]
	if jewelFunc then
		return { mod("JewelFunc", "LIST", jewelFunc) }
	end
	if unsupportedModList[lineLower] then
		return { }, line
	end
	local specialMod, specialLine, cap = scan(line, specialModList)
	if specialMod and #specialLine == 0 then
		if type(specialMod) == "function" then
			return specialMod(tonumber(cap[1]), unpack(cap))
		else
			return copyTable(specialMod)
		end
	end

	line = line .. " "

	-- Check for a flag/tag specification at the start of the line
	local preFlag
	preFlag, line = scan(line, preFlagList)

	-- Check for skill name at the start of the line
	local skillTag
	skillTag, line = scan(line, preSkillNameList)

	-- Scan for modifier form
	local modForm, formCap
	modForm, line, formCap = scan(line, formList)
	if not modForm then
		return nil, line
	end
	local num = tonumber(formCap[1])

	-- Check for tags (per-charge, conditionals)
	local modTag, modTag2, tagCap
	modTag, line, tagCap = scan(line, modTagList)
	if type(modTag) == "function" then
		modTag = modTag(tonumber(tagCap[1]), unpack(tagCap))
	end
	if modTag then
		modTag2, line, tagCap = scan(line, modTagList)
		if type(modTag2) == "function" then
			modTag2 = modTag2(tonumber(tagCap[1]), unpack(tagCap))
		end
	end
	
	-- Scan for modifier name and skill name
	local modName
	if order == 2 and not skillTag then
		skillTag, line = scan(line, skillNameList, true)
	end
	if modForm == "PEN" then
		modName, line = scan(line, penTypes, true)
		if not modName then
			return { }, line
		end
		local _
		_, line = scan(line, modNameList, true)
	else
		modName, line = scan(line, modNameList, true)
	end
	if order == 1 and not skillTag then
		skillTag, line = scan(line, skillNameList, true)
	end
	
	-- Scan for flags
	local modFlag
	modFlag, line = scan(line, modFlagList, true)

	-- Find modifier value and type according to form
	local modValue = num
	local modType = "BASE"
	local modSuffix
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
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "CHANCE" then
	elseif modForm == "REGENPERCENT" then
		modName = regenTypes[formCap[2]]
		modSuffix = "Percent"
	elseif modForm == "REGENFLAT" then
		modName = regenTypes[formCap[2]]
	elseif modForm == "DEGEN" then
		local damageType = dmgTypes[formCap[2]]
		if not damageType then
			return { }, line
		end
		modName = damageType .. "Degen"
		modSuffix = ""
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
		modFlag = modFlag or { keywordFlags = KeywordFlag.Attack }
	elseif modForm == "DMGSPELLS" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { keywordFlags = KeywordFlag.Spell }
	elseif modForm == "DMGBOTH" then
		local damageType = dmgTypes[formCap[3]]
		if not damageType then
			return { }, line
		end
		modValue = { tonumber(formCap[1]), tonumber(formCap[2]) }
		modName = { damageType.."Min", damageType.."Max" }
		modFlag = modFlag or { keywordFlags = bor(KeywordFlag.Attack, KeywordFlag.Spell) }
	end
	if not modName then
		return { }, line
	end

	-- Combine flags and tags
	local flags = 0
	local keywordFlags = 0
	local tagList = { }
	local misc = { }
	for _, data in pairs({ modName, preFlag, modFlag, modTag, modTag2, skillTag }) do
		if type(data) == "table" then
			flags = bor(flags, data.flags or 0)
			keywordFlags = bor(keywordFlags, data.keywordFlags or 0)
			if data.tag then
				t_insert(tagList, copyTable(data.tag))
			elseif data.tagList then
				for _, tag in ipairs(data.tagList) do
					t_insert(tagList, copyTable(tag))
				end
			end
			for k, v in pairs(data) do
				misc[k] = v
			end
		end
	end

	-- Generate modifier list
	local nameList = modName
	local modList = { }
	for i, name in ipairs(type(nameList) == "table" and nameList or { nameList }) do
		modList[i] = {
			name = name .. (modSuffix or misc.modSuffix or ""),
			type = modType,
			value = type(modValue) == "table" and modValue[i] or modValue,
			flags = flags,
			keywordFlags = keywordFlags,
			unpack(tagList)
		}
	end
	if modList[1] then
		-- Special handling for various modifier types
		if misc.addToAura then
			-- Modifiers that add effects to your auras
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("ExtraAuraEffect", "LIST", { mod = effectMod })
			end
		elseif misc.newAura then
			-- Modifiers that add extra auras
			for i, effectMod in ipairs(modList) do
				local tagList = { }
				for i, tag in ipairs(effectMod) do
					tagList[i] = tag
					effectMod[i] = nil
				end
				modList[i] = mod("ExtraAura", "LIST", { mod = effectMod, onlyAllies = misc.newAuraOnlyAllies }, unpack(tagList))
			end
		elseif misc.affectedByAura then
			-- Modifiers that apply to actors affected by your auras
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("AffectedByAuraMod", "LIST", { mod = effectMod })
			end
		elseif misc.addToMinion then
			-- Minion modifiers
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("MinionModifier", "LIST", { mod = effectMod }, misc.addToMinionTag)
			end
		elseif misc.addToSkill then
			-- Skill enchants or socketed gem modifiers that add additional effects
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("ExtraSkillMod", "LIST", { mod = effectMod }, misc.addToSkill)
			end
		end
	end
	return modList, line:match("%S") and line
end

local cache = { }
local unsupported = { }
local count = 0
--local foo = io.open("../unsupported.txt", "w")
--foo:close()
return function(line, isComb)
	if not cache[line] then
		local modList, extra = parseMod(line, 1)
		if modList and extra then
			modList, extra = parseMod(line, 2)
		end
		cache[line] = { modList, extra }
		if foo and not isComb and not cache[line][1] then
			local form = line:gsub("[%+%-]?%d+%.?%d*","{num}")
			if not unsupported[form] then
				unsupported[form] = true
				count = count + 1
				foo = io.open("../unsupported.txt", "a+")
				foo:write(count, ': ', form, (cache[line][2] and #cache[line][2] < #line and ('    {' .. cache[line][2]).. '}') or "", '\n')
				foo:close()
			end
		end
	end
	return unpack(copyTable(cache[line]))
end, cache
