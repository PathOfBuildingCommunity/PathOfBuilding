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
local m_huge = math.huge
local function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

-- Radius jewels that modify other nodes
local function getSimpleConv(srcList, dst, type, remove, factor)
	return function(node, out, data)
		local attributes = {["Dex"] = true, ["Int"] = true, ["Str"] = true}
		if node then
			for _, src in pairs(srcList) do
				for _, mod in ipairs(node.modList) do
					-- do not convert stats from tattoos
					if mod.name == src and mod.type == type and not (node.isTattoo and attributes[src]) then
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

local conquerorList = {
	["xibaqua"]		=	{ id = 1, type = "vaal" },
	["zerphi"]		=	{ id = 2, type = "vaal" },
	["doryani"]		=	{ id = 3, type = "vaal" },
	["ahuana"]		=	{ id = "2_v2", type = "vaal" },
	["deshret"]		=	{ id = 1, type = "maraketh" },
	["asenath"]		=	{ id = 2, type = "maraketh" },
	["nasima"]		=	{ id = 3, type = "maraketh" },
	["balbala"]		=	{ id = "1_v2", type = "maraketh" },
	["cadiro"]		=	{ id = 1, type = "eternal" },
	["victario"]	=	{ id = 2, type = "eternal" },
	["chitus"]		=	{ id = 3, type = "eternal" },
	["caspiro"]		=	{ id = "3_v2", type = "eternal" },
	["kaom"]		=	{ id = 1, type = "karui" },
	["rakiata"]		=	{ id = 2, type = "karui" },
	["kiloava"]		=	{ id = 3, type = "karui" },
	["akoya"]		=	{ id = "3_v2", type = "karui" },
	["venarius"]	=	{ id = 1, type = "templar" },
	["dominus"]		=	{ id = 2, type = "templar" },
	["avarius"]		=	{ id = 3, type = "templar" },
	["maxarius"]	=	{ id = "1_v2", type = "templar" },
}
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
	["(%d+) additional hits?"] = "BASE",
	["^you gain ([%d%.]+)"] = "GAIN",
	["^gains? ([%d%.]+)%% of"] = "GAIN",
	["^gain ([%d%.]+)"] = "GAIN",
	["^gain %+(%d+)%% to"] = "GAIN",
	["^you lose ([%d%.]+)"] = "LOSE",
	["^loses? ([%d%.]+)%% of"] = "LOSE",
	["^lose ([%d%.]+)"] = "LOSE",
	["^lose %+(%d+)%% to"] = "LOSE",
	["^grants ([%d%.]+)"] = "GRANTS",    -- local
	["^removes? ([%d%.]+) ?o?f? ?y?o?u?r?"] = "REMOVES", -- local
	["^(%d+)"] = "BASE",
	["^([%+%-]?%d+)%% chance"] = "CHANCE",
	["^([%+%-]?%d+)%% chance to gain "] = "FLAG",
	["^([%+%-]?%d+)%% additional chance"] = "CHANCE",
	["costs? ([%+%-]?%d+)"] = "TOTALCOST",
	["skills cost ([%+%-]?%d+)"] = "BASECOST",
	["penetrates? (%d+)%%"] = "PEN",
	["penetrates (%d+)%% of"] = "PEN",
	["penetrates (%d+)%% of enemy"] = "PEN",
	["^([%d%.]+) (.+) regenerated per second"] = "REGENFLAT",
	["^([%d%.]+)%% (.+) regenerated per second"] = "REGENPERCENT",
	["^([%d%.]+)%% of (.+) regenerated per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+) (.-) per second"] = "REGENFLAT",
	["^regenerate ([%d%.]+)%% (.-) per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+)%% of (.-) per second"] = "REGENPERCENT",
	["^regenerate ([%d%.]+)%% of your (.-) per second"] = "REGENPERCENT",
	["^you regenerate ([%d%.]+)%% of (.-) per second"] = "REGENPERCENT",
	["^([%d%.]+) (.+) lost per second"] = "DEGENFLAT",
	["^([%d%.]+)%% (.+) lost per second"] = "DEGENPERCENT",
	["^([%d%.]+)%% of (.+) lost per second"] = "DEGENPERCENT",
	["^lose ([%d%.]+) (.-) per second"] = "DEGENFLAT",
	["^lose ([%d%.]+)%% (.-) per second"] = "DEGENPERCENT",
	["^lose ([%d%.]+)%% of (.-) per second"] = "DEGENPERCENT",
	["^lose ([%d%.]+)%% of your (.-) per second"] = "DEGENPERCENT",
	["^you lose ([%d%.]+)%% of (.-) per second"] = "DEGENPERCENT",
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
	["(%d+) to (%d+) added attack (%a+) damage"] = "DMGATTACKS",
	["adds (%d+) to (%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+)%-(%d+) (%a+) damage to spells"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) spell damage"] = "DMGSPELLS",
	["adds (%d+)%-(%d+) (%a+) spell damage"] = "DMGSPELLS",
	["(%d+) to (%d+) added spell (%a+) damage"] = "DMGSPELLS",
	["adds (%d+) to (%d+) (%a+) damage to attacks and spells"] = "DMGBOTH",
	["adds (%d+)%-(%d+) (%a+) damage to attacks and spells"] = "DMGBOTH",
	["adds (%d+) to (%d+) (%a+) damage to spells and attacks"] = "DMGBOTH", -- o_O
	["adds (%d+)%-(%d+) (%a+) damage to spells and attacks"] = "DMGBOTH", -- o_O
	["adds (%d+) to (%d+) (%a+) damage to hits"] = "DMGBOTH",
	["adds (%d+)%-(%d+) (%a+) damage to hits"] = "DMGBOTH",
	["^you have "] = "FLAG",
	["^have "] = "FLAG",
	["^you are "] = "FLAG",
	["^are "] = "FLAG",
	["^gain "] = "FLAG",
	["^you gain "] = "FLAG",
	["is (%-?%d+)%%? "] = "OVERRIDE",
}

-- Map of modifier names
local modNameList = {
	-- Attributes
	["strength"] = "Str",
	["dexterity"] = "Dex",
	["intelligence"] = "Int",
	["omniscience"] = "Omni",
	["strength and dexterity"] = { "Str", "Dex", "StrDex" },
	["strength and intelligence"] = { "Str", "Int", "StrInt" },
	["dexterity and intelligence"] = { "Dex", "Int", "DexInt" },
	["attributes"] = { "Str", "Dex", "Int", "All" },
	["all attributes"] = { "Str", "Dex", "Int", "All" },
	["devotion"] = "Devotion",
	-- Life/mana
	["life"] = "Life",
	["maximum life"] = "Life",
	["life regeneration rate"] = "LifeRegen",
	["mana"] = "Mana",
	["maximum mana"] = "Mana",
	["mana regeneration"] = "ManaRegen",
	["mana regeneration rate"] = "ManaRegen",
	["mana cost"] = "ManaCost",
	["mana cost of"] = "ManaCost",
	["mana cost of skills"] = "ManaCost",
	["mana cost of attacks"] = { "ManaCost", tag = { type = "SkillType", skillType = SkillType.Attack } },
	["total cost"] = "Cost",
	["total mana cost"] = "ManaCost",
	["total mana cost of skills"] = "ManaCost",
	["life cost of skills"] = "LifeCost",
	["rage cost of skills"] = "RageCost",
	["cost of"] = "Cost",
	["cost of skills"] = "Cost",
	["mana reserved"] = "ManaReserved",
	["mana reservation"] = "ManaReserved",
	["mana reservation of skills"] = { "ManaReserved", tag = { type = "SkillType", skillType = SkillType.Aura } },
	["mana reservation efficiency of skills"] = "ManaReservationEfficiency",
	["life reservation efficiency of skills"] = "LifeReservationEfficiency",
	["reservation of skills"] = "Reserved",
	["mana reservation if cast as an aura"] = { "ManaReserved", tag = { type = "SkillType", skillType = SkillType.Aura } },
	["reservation if cast as an aura"] = { "Reserved", tag = { type = "SkillType", skillType = SkillType.Aura } },
	["reservation"] = { "Reserved" },
	["reservation efficiency"] = "ReservationEfficiency",
	["reservation efficiency of skills"] = "ReservationEfficiency",
	["mana reservation efficiency"] = "ManaReservationEfficiency",
	["life reservation efficiency"] = "LifeReservationEfficiency",
	-- Primary defences
	["maximum energy shield"] = "EnergyShield",
	["energy shield recharge rate"] = "EnergyShieldRecharge",
	["start of energy shield recharge"] = "EnergyShieldRechargeFaster",
	["restoration of ward"] = "WardRechargeFaster",
	["armour"] = "Armour",
	["evasion"] = "Evasion",
	["evasion rating"] = "Evasion",
	["energy shield"] = "EnergyShield",
	["ward"] = "Ward",
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
	["to evade attack hits"] = "EvadeChance",
	["chance to evade attacks"] = "EvadeChance",
	["chance to evade attack hits"] = "EvadeChance",
	["chance to evade projectile attacks"] = "ProjectileEvadeChance",
	["chance to evade melee attacks"] = "MeleeEvadeChance",
	["evasion rating against melee attacks"] = "MeleeEvasion",
	["evasion rating against projectile attacks"] = "ProjectileEvasion",
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
	["elemental resistance"] = "ElementalResist",
	["elemental resistances"] = "ElementalResist",
	["all elemental resistances"] = "ElementalResist",
	["all resistances"] = { "ElementalResist", "ChaosResist" },
	["all maximum elemental resistances"] = "ElementalResistMax",
	["all maximum resistances"] = { "ElementalResistMax", "ChaosResistMax" },
	["all elemental resistances and maximum elemental resistances"] = { "ElementalResist", "ElementalResistMax" },
	["fire and chaos resistances"] = { "FireResist", "ChaosResist" },
	["cold and chaos resistances"] = { "ColdResist", "ChaosResist" },
	["lightning and chaos resistances"] = { "LightningResist", "ChaosResist" },
	-- Damage taken
	["damage taken"] = "DamageTaken",
	["damage taken when hit"] = "DamageTakenWhenHit",
	["damage taken from hits"] = "DamageTakenWhenHit",
	["damage over time taken"] = "DamageTakenOverTime",
	["damage taken from damage over time"] = "DamageTakenOverTime",
	["attack damage taken"] = "AttackDamageTaken",
	["spell damage taken"] = "SpellDamageTaken",
	["physical damage taken"] = "PhysicalDamageTaken",
	["physical damage from hits taken"] = "PhysicalDamageFromHitsTaken",
	["physical damage taken when hit"] = "PhysicalDamageTakenWhenHit",
	["physical damage taken from hits"] = "PhysicalDamageTakenWhenHit",
	["physical damage taken from attacks"] = "PhysicalDamageTakenFromAttacks",
	["physical damage taken from attack hits"] = "PhysicalDamageTakenFromAttacks",
	["physical damage taken over time"] = "PhysicalDamageTakenOverTime",
	["physical damage over time taken"] = "PhysicalDamageTakenOverTime",
	["physical damage over time damage taken"] = "PhysicalDamageTakenOverTime",
	["reflected physical damage taken"] = "PhysicalReflectedDamageTaken",
	["lightning damage taken"] = "LightningDamageTaken",
	["lightning damage from hits taken"] = "LightningDamageFromHitsTaken",
	["lightning damage taken when hit"] = "LightningDamageTakenWhenHit",
	["lightning damage taken from attacks"] = "LightningDamageTakenFromAttacks",
	["lightning damage taken from attack hits"] = "LightningDamageTakenFromAttacks",
	["lightning damage taken over time"] = "LightningDamageTakenOverTime",
	["cold damage taken"] = "ColdDamageTaken",
	["cold damage from hits taken"] = "ColdDamageFromHitsTaken",
	["cold damage taken when hit"] = "ColdDamageTakenWhenHit",
	["cold damage taken from hits"] = "ColdDamageTakenWhenHit",
	["cold damage taken from attacks"] = "ColdDamageTakenFromAttacks",
	["cold damage taken from attack hits"] = "ColdDamageTakenFromAttacks",
	["cold damage taken over time"] = "ColdDamageTakenOverTime",
	["fire damage taken"] = "FireDamageTaken",
	["fire damage from hits taken"] = "FireDamageFromHitsTaken",
	["fire damage taken when hit"] = "FireDamageTakenWhenHit",
	["fire damage taken from hits"] = "FireDamageTakenWhenHit",
	["fire damage taken from attacks"] = "FireDamageTakenFromAttacks",
	["fire damage taken from attack hits"] = "FireDamageTakenFromAttacks",
	["fire damage taken over time"] = "FireDamageTakenOverTime",
	["chaos damage taken"] = "ChaosDamageTaken",
	["chaos damage from hits taken"] = "ChaosDamageFromHitsTaken",
	["chaos damage taken when hit"] = "ChaosDamageTakenWhenHit",
	["chaos damage taken from hits"] = "ChaosDamageTakenWhenHit",
	["chaos damage taken from attacks"] = "ChaosDamageTakenFromAttacks",
	["chaos damage taken from attack hits"] = "ChaosDamageTakenFromAttacks",
	["chaos damage taken over time"] = "ChaosDamageTakenOverTime",
	["chaos damage over time taken"] = "ChaosDamageTakenOverTime",
	["elemental damage taken"] = "ElementalDamageTaken",
	["elemental damage from hits taken"] = "ElementalDamageFromHitsTaken",
	["elemental damage taken when hit"] = "ElementalDamageTakenWhenHit",
	["elemental damage taken from hits"] = "ElementalDamageTakenWhenHit",
	["elemental damage taken over time"] = "ElementalDamageTakenOverTime",
	["cold and lightning damage taken"] = { "ColdDamageTaken", "LightningDamageTaken" },
	["fire and lightning damage taken"] = { "FireDamageTaken", "LightningDamageTaken" },
	["fire and cold damage taken"] = { "FireDamageTaken", "ColdDamageTaken" },
	["physical and chaos damage taken"] = { "PhysicalDamageTaken", "ChaosDamageTaken" },
	["reflected elemental damage taken"] = "ElementalReflectedDamageTaken",
	-- Other defences
	["to dodge attacks"] = "AttackDodgeChance",
	["to dodge attack hits"] = "AttackDodgeChance",
	["to dodge spells"] = "SpellDodgeChance",
	["to dodge spell hits"] = "SpellDodgeChance",
	["to dodge spell damage"] = "SpellDodgeChance",
	["to dodge attacks and spells"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to dodge attacks and spell damage"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to dodge attack and spell hits"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to dodge attack or spell hits"] = { "AttackDodgeChance", "SpellDodgeChance" },
	["to suppress spell damage"] = { "SpellSuppressionChance" },
	["amount of suppressed spell damage prevented"] = { "SpellSuppressionEffect" },
	["to amount of suppressed spell damage prevented"] = { "SpellSuppressionEffect" },
	["to block"] = "BlockChance",
	["to block attacks"] = "BlockChance",
	["to block attack damage"] = "BlockChance",
	["block chance"] = "BlockChance",
	["block chance with staves"] = { "BlockChance", tag = { type = "Condition", var = "UsingStaff" } },
	["to block with staves"] = { "BlockChance", tag = { type = "Condition", var = "UsingStaff" } },
	["block chance against projectiles"] = "ProjectileBlockChance",
	["to block projectile attack damage"] = "ProjectileBlockChance",
	["to block projectile spell damage"] = "ProjectileSpellBlockChance",
	["spell block chance"] = "SpellBlockChance",
	["to block spells"] = "SpellBlockChance",
	["to block spell damage"] = "SpellBlockChance",
	["chance to block attacks and spells"] = { "BlockChance", "SpellBlockChance" },
	["chance to block attack and spell damage"] = { "BlockChance", "SpellBlockChance" },
	["to block attack and spell damage"] = { "BlockChance", "SpellBlockChance" },
	["maximum block chance"] = "BlockChanceMax",
	["maximum chance to block attack damage"] = "BlockChanceMax",
	["maximum chance to block spell damage"] = "SpellBlockChanceMax",
	["life gained when you block"] = "LifeOnBlock",
	["mana gained when you block"] = "ManaOnBlock",
	["energy shield when you block"] = "EnergyShieldOnBlock",
	["maximum chance to dodge spell hits"] = "SpellDodgeChanceMax",
	["to avoid physical damage from hits"] = "AvoidPhysicalDamageChance",
	["to avoid fire damage when hit"] = "AvoidFireDamageChance",
	["to avoid fire damage from hits"] = "AvoidFireDamageChance",
	["to avoid cold damage when hit"] = "AvoidColdDamageChance",
	["to avoid cold damage from hits"] = "AvoidColdDamageChance",
	["to avoid lightning damage when hit"] = "AvoidLightningDamageChance",
	["to avoid lightning damage from hits"] = "AvoidLightningDamageChance",
	["to avoid elemental damage when hit"] = { "AvoidFireDamageChance", "AvoidColdDamageChance", "AvoidLightningDamageChance" },
	["to avoid elemental damage from hits"] = { "AvoidFireDamageChance", "AvoidColdDamageChance", "AvoidLightningDamageChance" },
	["to avoid projectiles"] = "AvoidProjectilesChance",
	["to avoid being stunned"] = "AvoidStun",
	["to avoid interruption from stuns while casting"] = "AvoidInterruptStun",
	["to ignore stuns while casting"] = "AvoidInterruptStun",
	["to avoid being shocked"] = "AvoidShock",
	["to avoid being frozen"] = "AvoidFreeze",
	["to avoid being chilled"] = "AvoidChill",
	["to avoid being ignited"] = "AvoidIgnite",
	["to avoid non-damaging ailments on you"] = { "AvoidShock", "AvoidFreeze", "AvoidChill", "AvoidSap", "AvoidBrittle", "AvoidScorch" },
	["to avoid blind"] = "AvoidBlind",
	["to avoid elemental ailments"] = "AvoidElementalAilments",
	["to avoid elemental status ailments"] = "AvoidElementalAilments",
	["to avoid ailments"] = "AvoidAilments" ,
	["to avoid status ailments"] = "AvoidAilments",
	["to avoid bleeding"] = "AvoidBleed",
	["to avoid being poisoned"] = "AvoidPoison",
	["damage is taken from mana before life"] = "DamageTakenFromManaBeforeLife",
	["lightning damage is taken from mana before life"] = "LightningDamageTakenFromManaBeforeLife",
	["damage taken from mana before life"] = "DamageTakenFromManaBeforeLife",
	["effect of curses on you"] = "CurseEffectOnSelf",
	["effect of curses on them"] = "CurseEffectOnSelf",
	["effect of exposure on you"] = "ExposureEffectOnSelf",
	["effect of withered on you"] = "WitherEffectOnSelf",
	["life recovery rate"] = "LifeRecoveryRate",
	["mana recovery rate"] = "ManaRecoveryRate",
	["energy shield recovery rate"] = "EnergyShieldRecoveryRate",
	["energy shield regeneration rate"] = "EnergyShieldRegen",
	["recovery rate of life, mana and energy shield"] = { "LifeRecoveryRate", "ManaRecoveryRate", "EnergyShieldRecoveryRate" },
	["recovery rate of life and energy shield"] = { "LifeRecoveryRate", "EnergyShieldRecoveryRate" },
	["maximum life, mana and global energy shield"] = { "Life", "Mana", "EnergyShield", tag = { type = "Global" } },
	["non-chaos damage taken bypasses energy shield"] = { "PhysicalEnergyShieldBypass", "LightningEnergyShieldBypass", "ColdEnergyShieldBypass", "FireEnergyShieldBypass" },
	["damage taken recouped as life"] = "LifeRecoup",
	["physical damage taken recouped as life"] = "PhysicalLifeRecoup",
	["lightning damage taken recouped as life"] = "LightningLifeRecoup",
	["cold damage taken recouped as life"] = "ColdLifeRecoup",
	["fire damage taken recouped as life"] = "FireLifeRecoup",
	["chaos damage taken recouped as life"] = "ChaosLifeRecoup",
	["damage taken recouped as energy shield"] = "EnergyShieldRecoup",
	["damage taken recouped as mana"] = "ManaRecoup",
	["damage taken recouped as life, mana and energy shield"] = { "LifeRecoup", "EnergyShieldRecoup", "ManaRecoup" },
	-- Stun/knockback modifiers
	["stun recovery"] = "StunRecovery",
	["stun and block recovery"] = "StunRecovery",
	["block and stun recovery"] = "StunRecovery",
	["stun duration on you"] = "StunDuration",
	["stun threshold"] = "StunThreshold",
	["block recovery"] = "BlockRecovery",
	["enemy stun threshold"] = "EnemyStunThreshold",
	["stun duration on enemies"] = "EnemyStunDuration",
	["stun duration"] = "EnemyStunDuration",
	["to double stun duration"] = "DoubleEnemyStunDurationChance",
	["to knock enemies back on hit"] = "EnemyKnockbackChance",
	["knockback distance"] = "EnemyKnockbackDistance",
	-- Auras/curses/buffs
	["aura effect"] = "AuraEffect",
	["effect of non-curse auras you cast"] = { "AuraEffect", tagList = { { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true } } },
	["effect of non-curse auras from your skills"] = { "AuraEffect", tagList = { { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true } } },
	["effect of non-curse auras from your skills on your minions"] = { "AuraEffectOnSelf", tagList = { { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true } }, addToMinion = true },
	["effect of non-curse auras"] = { "AuraEffect", tag = { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true } },
	["effect of your curses"] = "CurseEffect",
	["effect of auras on you"] = "AuraEffectOnSelf",
	["effect of auras on your minions"] = { "AuraEffectOnSelf", addToMinion = true },
	["effect of auras from mines"] = { "AuraEffect", keywordFlags = KeywordFlag.Mine },
	["effect of consecrated ground you create"] = "ConsecratedGroundEffect",
	["curse effect"] = "CurseEffect",
	["effect of curses applied by bane"] = { "CurseEffect", tag = { type = "Condition", var = "AppliedByBane" } },
	["effect of your marks"] = { "CurseEffect", tag = { type = "SkillType", skillType = SkillType.Mark } },
	["effect of arcane surge on you"] = "ArcaneSurgeEffect",
	["curse duration"] = { "Duration", keywordFlags = KeywordFlag.Curse },
	["hex duration"] = { "Duration", tag = { type = "SkillType", skillType = SkillType.Hex } },
	["radius of auras"] = { "AreaOfEffect", keywordFlags = KeywordFlag.Aura },
	["radius of curses"] = { "AreaOfEffect", keywordFlags = KeywordFlag.Curse },
	["buff effect"] = "BuffEffect",
	["effect of buffs on you"] = "BuffEffectOnSelf",
	["effect of buffs granted by your golems"] = { "BuffEffect", tag = { type = "SkillType", skillType = SkillType.Golem } },
	["effect of buffs granted by socketed golem skills"] = { "BuffEffect", addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["effect of the buff granted by your stone golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Stone Golem", includeTransfigured = true } },
	["effect of the buff granted by your lightning golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Lightning Golem", includeTransfigured = true } },
	["effect of the buff granted by your ice golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Ice Golem", includeTransfigured = true } },
	["effect of the buff granted by your flame golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Flame Golem", includeTransfigured = true } },
	["effect of the buff granted by your chaos golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Chaos Golem", includeTransfigured = true } },
	["effect of the buff granted by your carrion golems"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Summon Carrion Golem", includeTransfigured = true } },
	["effect of offering spells"] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } } },
	["effect of offerings"] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } } },
	["effect of heralds on you"] = { "BuffEffect", tag = { type = "SkillType", skillType = SkillType.Herald } },
	["effect of herald buffs on you"] = { "BuffEffect", tag = { type = "SkillType", skillType = SkillType.Herald } },
	["effect of buffs granted by your active ancestor totems"] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Ancestral Warchief", "Ancestral Protector", "Earthbreaker" } } },
	["effect of buffs your ancestor totems grant "] = { "BuffEffect", tag = { type = "SkillName", skillNameList = { "Ancestral Warchief", "Ancestral Protector", "Earthbreaker" } } },
	["effect of shrine buffs on you"] = "ShrineBuffEffect",
	["effect of withered"] = "WitherEffect",
	["warcry effect"] = { "BuffEffect", keywordFlags = KeywordFlag.Warcry },
	["aspect of the avian buff effect"] = { "BuffEffect", tag = { type = "SkillName", skillName = "Aspect of the Avian" } },
	["maximum rage"] = "MaximumRage",
	["maximum fortification"] = "MaximumFortification",
	["fortification"] = "MinimumFortification",
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
	["minimum endurance, frenzy and power charges"] = { "PowerChargesMin", "FrenzyChargesMin", "EnduranceChargesMin" },
	["endurance charge duration"] = "EnduranceChargesDuration",
	["maximum frenzy charges and maximum power charges"] = { "FrenzyChargesMax", "PowerChargesMax" },
	["maximum power charges and maximum endurance charges"] = { "PowerChargesMax", "EnduranceChargesMax" },
	["maximum endurance, frenzy and power charges"] = { "EnduranceChargesMax", "PowerChargesMax", "FrenzyChargesMax" },
	["endurance, frenzy and power charge duration"] = { "PowerChargesDuration", "FrenzyChargesDuration", "EnduranceChargesDuration" },
	["maximum siphoning charge"] = "SiphoningChargesMax",
	["maximum siphoning charges"] = "SiphoningChargesMax",
	["maximum challenger charges"] = "ChallengerChargesMax",
	["maximum blitz charges"] = "BlitzChargesMax",
	["maximum number of crab barriers"] = "CrabBarriersMax",
	["maximum blood charges"] = "BloodChargesMax",
	["maximum spirit charges"] = "SpiritChargesMax",
	["charge duration"] = "ChargeDuration",
	-- On hit/kill/leech effects
	["life gained on kill"] = "LifeOnKill",
	["life per enemy killed"] = "LifeOnKill",
	["life on kill"] = "LifeOnKill",
	["life per enemy hit"] = { "LifeOnHit", flags = ModFlag.Hit },
	["life gained for each enemy hit"] = { "LifeOnHit", flags = ModFlag.Hit },
	["life for each enemy hit"] = { "LifeOnHit", flags = ModFlag.Hit },
	["mana gained on kill"] = "ManaOnKill",
	["mana per enemy killed"] = "ManaOnKill",
	["mana on kill"] = "ManaOnKill",
	["mana per enemy hit"] = { "ManaOnHit", flags = ModFlag.Hit },
	["mana gained for each enemy hit"] = { "ManaOnHit", flags = ModFlag.Hit },
	["mana for each enemy hit"] = { "ManaOnHit", flags = ModFlag.Hit },
	["energy shield gained on kill"] = "EnergyShieldOnKill",
	["energy shield per enemy killed"] = "EnergyShieldOnKill",
	["energy shield on kill"] = "EnergyShieldOnKill",
	["energy shield per enemy hit"] = { "EnergyShieldOnHit", flags = ModFlag.Hit },
	["energy shield gained for each enemy hit"] = { "EnergyShieldOnHit", flags = ModFlag.Hit },
	["energy shield for each enemy hit"] = { "EnergyShieldOnHit", flags = ModFlag.Hit },
	["life and mana gained for each enemy hit"] = { "LifeOnHit", "ManaOnHit", flags = ModFlag.Hit },
	["life and mana for each enemy hit"] = { "LifeOnHit", "ManaOnHit", flags = ModFlag.Hit },
	["damage as life"] = "DamageLifeLeech",
	["life leeched per second"] = "LifeLeechRate",
	["mana leeched per second"] = "ManaLeechRate",
	["total recovery per second from life leech"] = "LifeLeechRate",
	["recovery per second from life leech"] = "LifeLeechRate",
	["total recovery per second from energy shield leech"] = "EnergyShieldLeechRate",
	["recovery per second from energy shield leech"] = "EnergyShieldLeechRate",
	["total recovery per second from mana leech"] = "ManaLeechRate",
	["recovery per second from mana leech"] = "ManaLeechRate",
	["total recovery per second from life, mana, or energy shield leech"] = { "LifeLeechRate", "ManaLeechRate", "EnergyShieldLeechRate" },
	["maximum recovery per life leech"] = "MaxLifeLeechInstance",
	["maximum recovery per energy shield leech"] = "MaxEnergyShieldLeechInstance",
	["maximum recovery per mana leech"] = "MaxManaLeechInstance",
	["maximum total recovery per second from life leech"] = "MaxLifeLeechRate",
	["maximum total life recovery per second from leech"] = "MaxLifeLeechRate",
	["maximum total recovery per second from energy shield leech"] = "MaxEnergyShieldLeechRate",
	["maximum total energy shield recovery per second from leech"] = "MaxEnergyShieldLeechRate",
	["maximum total recovery per second from mana leech"] = "MaxManaLeechRate",
	["maximum total mana recovery per second from leech"] = "MaxManaLeechRate",
	["maximum total life, mana and energy shield recovery per second from leech"] = { "MaxLifeLeechRate", "MaxManaLeechRate", "MaxEnergyShieldLeechRate" },
	["life and mana leech is instant"] = { "InstantManaLeech", "InstantLifeLeech" },
	["life leech is instant"] = { "InstantLifeLeech" },
	["mana leech is instant"] = { "InstantManaLeech" },
	["energy shield leech is instant"] = { "InstantEnergyShieldLeech" },
	["leech is instant"] = { "InstantEnergyShieldLeech", "InstantManaLeech", "InstantLifeLeech" },
	["to impale enemies on hit"] = "ImpaleChance",
	["to impale on spell hit"] = { "ImpaleChance", flags = ModFlag.Spell },
	["impale effect"] = "ImpaleEffect",
	["effect of impales you inflict"] = "ImpaleEffect",
	["effects of impale inflicted"] = "ImpaleEffect", -- typo / old wording change
	["effect of impales inflicted"] = "ImpaleEffect",
	-- Projectile modifiers
	["projectile"] = "ProjectileCount",
	["projectiles"] = "ProjectileCount",
	["projectile speed"] = "ProjectileSpeed",
	["arrow speed"] = { "ProjectileSpeed", flags = ModFlag.Bow },
	-- Totem/trap/mine/brand modifiers
	["totem placement speed"] = "TotemPlacementSpeed",
	["totem life"] = "TotemLife",
	["totem duration"] = "TotemDuration",
	["maximum number of summoned totems"] = "ActiveTotemLimit",
	["maximum number of summoned totems."] = "ActiveTotemLimit", -- Mark plz
	["maximum number of summoned ballista totems"] = { "ActiveBallistaLimit", tag = { type = "SkillType", skillType = SkillType.TotemsAreBallistae } },
	["trap throwing speed"] = "TrapThrowingSpeed",
	["trap and mine throwing speed"] = { "TrapThrowingSpeed", "MineLayingSpeed" },
	["trap trigger area of effect"] = "TrapTriggerAreaOfEffect",
	["trap duration"] = "TrapDuration",
	["cooldown recovery speed for throwing traps"] = { "CooldownRecovery", keywordFlags = KeywordFlag.Trap },
	["cooldown recovery rate for throwing traps"] = { "CooldownRecovery", keywordFlags = KeywordFlag.Trap },
	["mine laying speed"] = "MineLayingSpeed",
	["mine throwing speed"] = "MineLayingSpeed",
	["mine detonation area of effect"] = "MineDetonationAreaOfEffect",
	["mine duration"] = "MineDuration",
	["activation frequency"] = "BrandActivationFrequency",
	["brand activation frequency"] = "BrandActivationFrequency",
	["brand attachment range"] = "BrandAttachmentRange",
	-- Minion modifiers
	["maximum number of skeletons"] = "ActiveSkeletonLimit",
	["maximum number of zombies"] = "ActiveZombieLimit",
	["maximum number of raised zombies"] = "ActiveZombieLimit",
	["number of zombies allowed"] = "ActiveZombieLimit",
	["maximum number of spectres"] = "ActiveSpectreLimit",
	["maximum number of golems"] = "ActiveGolemLimit",
	["maximum number of summoned golems"] = "ActiveGolemLimit",
	["maximum number of summoned raging spirits"] = "ActiveRagingSpiritLimit",
	["maximum number of raging spirits"] = "ActiveRagingSpiritLimit",
	["maximum number of summoned phantasms"] = "ActivePhantasmLimit",
	["maximum number of summoned holy relics"] = "ActiveHolyRelicLimit",
	["number of summoned arbalists"] = "ActiveArbalistLimit",
	["minion duration"] = { "Duration", tag = { type = "SkillType", skillType = SkillType.CreatesMinion } },
	["skeleton duration"] = { "Duration", tag = { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true } },
	["sentinel of dominance duration"] = { "Duration", tag = { type = "SkillName", skillName = "Dominating Blow", includeTransfigured = true } },
	-- Other skill modifiers
	["radius"] = "AreaOfEffect",
	["radius of area skills"] = "AreaOfEffect",
	["area of effect radius"] = "AreaOfEffect",
	["area of effect"] = "AreaOfEffect",
	["area of effect of skills"] = "AreaOfEffect",
	["area of effect of area skills"] = "AreaOfEffect",
	["aspect of the spider area of effect"] = { "AreaOfEffect", tag = { type = "SkillName", skillName = "Aspect of the Spider" } },
	["firestorm explosion area of effect"] = { "AreaOfEffectSecondary", tag = { type = "SkillName", skillName = "Firestorm", includeTransfigured = true } },
	["duration"] = "Duration",
	["skill effect duration"] = "Duration",
	["chaos skill effect duration"] = { "Duration", keywordFlags = KeywordFlag.Chaos },
	["soul gain prevention duration"] = "SoulGainPreventionDuration",
	["aspect of the spider debuff duration"] = { "Duration", tag = { type = "SkillName", skillName = "Aspect of the Spider" } },
	["fire trap burning ground duration"] = { "Duration", tag = { type = "SkillName", skillName = "Fire Trap" } },
	["sentinel of absolution duration"] = { "SecondaryDuration", tag = { type = "SkillName", skillName = "Absolution", includeTransfigured = true } },
	["cooldown recovery"] = "CooldownRecovery",
	["cooldown recovery speed"] = "CooldownRecovery",
	["cooldown recovery rate"] = "CooldownRecovery",
	["cooldown use"] = "AdditionalCooldownUses",
	["cooldown uses"] = "AdditionalCooldownUses",
	["weapon range"] = "WeaponRange",
	["metres to weapon range"] = "WeaponRangeMetre",
	["metre to weapon range"] = "WeaponRangeMetre",
	["melee range"] = "MeleeWeaponRange",
	["melee weapon range"] = "MeleeWeaponRange",
	["melee weapon and unarmed range"] = { "MeleeWeaponRange", "UnarmedRange" },
	["melee weapon and unarmed attack range"] = { "MeleeWeaponRange", "UnarmedRange" },
	["melee strike range"] = { "MeleeWeaponRange", "UnarmedRange" },
	["metres to melee strike range"] = { "MeleeWeaponRangeMetre", "UnarmedRangeMetre" },
	["metre to melee strike range"] = { "MeleeWeaponRangeMetre", "UnarmedRangeMetre" },
	["to deal double damage"] = "DoubleDamageChance",
	["to deal triple damage"] = "TripleDamageChance",
	-- Buffs
	["onslaught effect"] = "OnslaughtEffect",
	["effect of onslaught on you"] = "OnslaughtEffect",
	["adrenaline duration"] = "AdrenalineDuration",
	["effect of tailwind on you"] = "TailwindEffectOnSelf",
	["elusive effect"] = "ElusiveEffect",
	["effect of elusive on you"] = "ElusiveEffect",
	["effect of infusion"] = "InfusionEffect",
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
	["minimum physical attack damage"] = { "MinPhysicalDamage", tag = { type = "SkillType", skillType = SkillType.Attack } },
	["maximum physical attack damage"] = { "MaxPhysicalDamage", tag = { type = "SkillType", skillType = SkillType.Attack } },
	["physical weapon damage"] = { "PhysicalDamage", flags = ModFlag.Weapon },
	["physical damage with weapons"] = { "PhysicalDamage", flags = ModFlag.Weapon },
	["melee damage"] = { "Damage", flags = ModFlag.Melee },
	["physical melee damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["melee physical damage"] = { "PhysicalDamage", flags = ModFlag.Melee },
	["projectile damage"] = { "Damage", flags = ModFlag.Projectile },
	["projectile attack damage"] = { "Damage", flags = bor(ModFlag.Projectile, ModFlag.Attack) },
	["bow damage"] = { "Damage", flags = bor(ModFlag.Bow, ModFlag.Hit) },
	["damage with arrow hits"] = { "Damage", flags = bor(ModFlag.Bow, ModFlag.Hit) },
	["wand damage"] = { "Damage", flags = bor(ModFlag.Wand, ModFlag.Hit) },
	["wand physical damage"] = { "PhysicalDamage", flags = bor(ModFlag.Wand, ModFlag.Hit) },
	["claw physical damage"] = { "PhysicalDamage", flags = bor(ModFlag.Claw, ModFlag.Hit) },
	["sword physical damage"] = { "PhysicalDamage", flags = bor(ModFlag.Sword, ModFlag.Hit) },
	["damage over time"] = { "Damage", flags = ModFlag.Dot },
	["physical damage over time"] = { "PhysicalDamage", keywordFlags = KeywordFlag.PhysicalDot },
	["cold damage over time"] = { "ColdDamage", keywordFlags = KeywordFlag.ColdDot },
	["chaos damage over time"] = { "ChaosDamage", keywordFlags = KeywordFlag.ChaosDot },
	["burning damage"] = { "FireDamage", keywordFlags = KeywordFlag.FireDot },
	["damage with ignite"] = { "Damage", keywordFlags = KeywordFlag.Ignite },
	["damage with ignites"] = { "Damage", keywordFlags = KeywordFlag.Ignite },
	["damage with ignites inflicted"] = { "Damage", keywordFlags = KeywordFlag.Ignite },
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
	["attack critical strike multiplier"] = { "CritMultiplier", flags = ModFlag.Attack },
	["accuracy"] = "Accuracy",
	["accuracy rating"] = "Accuracy",
	["minion accuracy rating"] = { "Accuracy", addToMinion = true },
	["attack speed"] = { "Speed", flags = ModFlag.Attack },
	["cast speed"] = { "Speed", flags = ModFlag.Cast },
	["warcry speed"] = { "WarcrySpeed", keywordFlags = KeywordFlag.Warcry },
	["attack and cast speed"] = "Speed",
	["dps"] = "DPS",
	-- Elemental ailments
	["to shock"] = "EnemyShockChance",
	["shock chance"] = "EnemyShockChance",
	["to freeze"] = "EnemyFreezeChance",
	["freeze chance"] = "EnemyFreezeChance",
	["to ignite"] = "EnemyIgniteChance",
	["ignite chance"] = "EnemyIgniteChance",
	["to freeze, shock and ignite"] = { "EnemyFreezeChance", "EnemyShockChance", "EnemyIgniteChance" },
	["to scorch enemies"] = "EnemyScorchChance",
	["to inflict brittle"] = "EnemyBrittleChance",
	["to sap enemies"] = "EnemySapChance",
	["effect of scorch"] = "EnemyScorchEffect",
	["effect of sap"] = "EnemySapEffect",
	["effect of brittle"] = "EnemyBrittleEffect",
	["effect of shock"] = "EnemyShockEffect",
	["effect of shock on you"] = "SelfShockEffect",
	["effect of shock you inflict"] = "EnemyShockEffect",
	["effect of shocks you inflict"] = "EnemyShockEffect",
	["effect of lightning ailments"] = { "EnemyShockEffect" , "EnemySapEffect" },
	["effect of chill"] = "EnemyChillEffect",
	["effect of chill and shock on you"] = { "SelfChillEffect", "SelfShockEffect" },
	["chill effect"] = "EnemyChillEffect",
	["effect of chill you inflict"] = "EnemyChillEffect",
	["effect of cold ailments"] = { "EnemyChillEffect" , "EnemyBrittleEffect" },
	["effect of chill on you"] = "SelfChillEffect",
	["effect of non-damaging ailments"] = { "EnemyShockEffect", "EnemyChillEffect", "EnemyFreezeEffect", "EnemyScorchEffect", "EnemyBrittleEffect", "EnemySapEffect" },
	["effect of non-damaging ailments you inflict"] = { "EnemyShockEffect", "EnemyChillEffect", "EnemyFreezeEffect", "EnemyScorchEffect", "EnemyBrittleEffect", "EnemySapEffect" },
	["shock duration"] = "EnemyShockDuration",
	["duration of shocks you inflict"] = "EnemyShockDuration",
	["shock duration on you"] = "SelfShockDuration",
	["duration of lightning ailments"] = { "EnemyShockDuration" , "EnemySapDuration" },
	["freeze duration"] = "EnemyFreezeDuration",
	["duration of freezes you inflict"] = "EnemyFreezeDuration",
	["freeze duration on you"] = "SelfFreezeDuration",
	["chill duration"] = "EnemyChillDuration",
	["duration of chills you inflict"] = "EnemyChillDuration",
	["chill duration on you"] = "SelfChillDuration",
	["duration of cold ailments"] = { "EnemyFreezeDuration" , "EnemyChillDuration", "EnemyBrittleDuration" },
	["ignite duration"] = "EnemyIgniteDuration",
	["duration of ignites you inflict"] = "EnemyIgniteDuration",
	["ignite duration on you"] = "SelfIgniteDuration",
	["duration of ignite on you"] = "SelfIgniteDuration",
	["duration of elemental ailments"] = "EnemyElementalAilmentDuration",
	["duration of elemental ailments on you"] = "SelfElementalAilmentDuration",
	["duration of elemental status ailments"] = "EnemyElementalAilmentDuration",
	["duration of ailments"] = "EnemyAilmentDuration",
	["duration of ailments on you"] = "SelfAilmentDuration",
	["elemental ailment duration on you"] = "SelfElementalAilmentDuration",
	["duration of ailments you inflict"] = "EnemyAilmentDuration",
	["duration of ailments inflicted"] = "EnemyAilmentDuration",
	["duration of ailments inflicted on you"] = "SelfAilmentDuration",
	["duration of damaging ailments on you"] = { "SelfIgniteDuration" , "SelfBleedDuration", "SelfPoisonDuration" },
	-- Other ailments
	["to poison"] = "PoisonChance",
	["to cause poison"] = "PoisonChance",
	["to poison on hit"] = "PoisonChance",
	["poison duration"] = { "EnemyPoisonDuration" },
	["poison duration on you"] = "SelfPoisonDuration",
	["duration of poisons on you"] = "SelfPoisonDuration",
	["duration of poisons you inflict"] = { "EnemyPoisonDuration" },
	["to cause bleeding"] = "BleedChance",
	["to cause bleeding on hit"] = "BleedChance",
	["to inflict bleeding"] = "BleedChance",
	["to inflict bleeding on hit"] = "BleedChance",
	["bleed duration"] = { "EnemyBleedDuration" },
	["bleeding duration"] = { "EnemyBleedDuration" },
	["bleed duration on you"] = "SelfBleedDuration",
	-- Misc modifiers
	["movement speed"] = "MovementSpeed",
	["attack, cast and movement speed"] = { "Speed", "MovementSpeed" },
	["action speed"] = "ActionSpeed",
	["light radius"] = "LightRadius",
	["rarity of items found"] = "LootRarity",
	["rarity of items dropped"] = "LootRarity",
	["quantity of items found"] = "LootQuantity",
	["item quantity"] = "LootQuantity",
	["strength requirement"] = "StrRequirement",
	["dexterity requirement"] = "DexRequirement",
	["intelligence requirement"] = "IntRequirement",
	["omni requirement"] = "OmniRequirement",
	["strength and intelligence requirement"] = { "StrRequirement", "IntRequirement" },
	["attribute requirements"] = { "StrRequirement", "DexRequirement", "IntRequirement" },
	["effect of socketed jewels"] = "SocketedJewelEffect",
	["effect of socketed abyss jewels"] = "SocketedJewelEffect",
	["to inflict fire exposure on hit"] = "FireExposureChance",
	["to apply fire exposure on hit"] = "FireExposureChance",
	["to inflict cold exposure on hit"] = "ColdExposureChance",
	["to apply cold exposure on hit"] = "ColdExposureChance",
	["to inflict lightning exposure on hit"] = "LightningExposureChance",
	["to apply lightning exposure on hit"] = "LightningExposureChance",
	-- Flask modifiers
	["effect"] = "FlaskEffect",
	["effect of flasks"] = "FlaskEffect",
	["amount recovered"] = "FlaskRecovery",
	["life recovered"] = "FlaskRecovery",
	["life recovery from flasks used"] = "FlaskLifeRecovery",
	["mana recovered"] = "FlaskRecovery",
	["life recovery from flasks"] = "FlaskLifeRecovery",
	["mana recovery from flasks"] = "FlaskManaRecovery",
	["life and mana recovery from flasks"] = { "FlaskLifeRecovery", "FlaskManaRecovery" },
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
	["charges per use"] = "FlaskChargesUsed",
	["flask charges used"] = "FlaskChargesUsed",
	["flask charges gained"] = "FlaskChargesGained",
	["charge recovery"] = "FlaskChargeRecovery",
	["for flasks you use to not consume charges"] = "FlaskChanceNotConsumeCharges",
	["impales you inflict last"] = "ImpaleStacksMax",
	-- Buffs
	["adrenaline"] = "Condition:Adrenaline",
	["elusive"] = "Condition:CanBeElusive",
	["onslaught"] = "Condition:Onslaught",
	["rampage"] = "Condition:Rampage",
	["soul eater"] = "Condition:CanHaveSoulEater",
	["phasing"] = "Condition:Phasing",
	["arcane surge"] = "Condition:ArcaneSurge",
	["unholy might"] = { "Condition:UnholyMight", "Condition:CanWither" },
	["chaotic might"] = "Condition:ChaoticMight",
	["lesser brutal shrine buff"] = "Condition:LesserBrutalShrine",
	["lesser massive shrine buff"] = "Condition:LesserMassiveShrine",
	["diamond shrine buff"] = "Condition:DiamondShrine",
	["massive shrine buff"] = "Condition:MassiveShrine",
}

-- List of modifier flags
local modFlagList = {
	-- Weapon types
	["with axes"] = { flags = bor(ModFlag.Axe, ModFlag.Hit) },
	["to axe attacks"] = { flags = bor(ModFlag.Axe, ModFlag.Hit) },
	["with axe attacks"] = { flags = bor(ModFlag.Axe, ModFlag.Hit) },
	["with axes or swords"] = { flags = ModFlag.Hit, tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Axe, ModFlag.Sword) } },
	["with bows"] = { flags = bor(ModFlag.Bow, ModFlag.Hit) },
	["to bow attacks"] = { flags = bor(ModFlag.Bow, ModFlag.Hit) },
	["with bow attacks"] = { flags = bor(ModFlag.Bow, ModFlag.Hit) },
	["with claws"] = { flags = bor(ModFlag.Claw, ModFlag.Hit) },
	["with claws or daggers"] = { flags = ModFlag.Hit, tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Claw, ModFlag.Dagger) } },
	["to claw attacks"] = { flags = bor(ModFlag.Claw, ModFlag.Hit) },
	["with claw attacks"] = { flags = bor(ModFlag.Claw, ModFlag.Hit) },
	["claw attacks"] = { flags = bor(ModFlag.Claw, ModFlag.Hit) },
	["dealt with claws"] = { flags = bor(ModFlag.Claw, ModFlag.Hit) },
	["with daggers"] = { flags = bor(ModFlag.Dagger, ModFlag.Hit) },
	["to dagger attacks"] = { flags = bor(ModFlag.Dagger, ModFlag.Hit) },
	["with dagger attacks"] = { flags = bor(ModFlag.Dagger, ModFlag.Hit) },
	["with maces"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["to mace attacks"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["with mace attacks"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["with maces and sceptres"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["with maces or sceptres"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["with maces, sceptres or staves"] = { flags = ModFlag.Hit, tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Mace, ModFlag.Staff) } },
	["to mace and sceptre attacks"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["to mace or sceptre attacks"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["with mace or sceptre attacks"] = { flags = bor(ModFlag.Mace, ModFlag.Hit) },
	["with staves"] = { flags = bor(ModFlag.Staff, ModFlag.Hit) },
	["to staff attacks"] = { flags = bor(ModFlag.Staff, ModFlag.Hit) },
	["with staff attacks"] = { flags = bor(ModFlag.Staff, ModFlag.Hit) },
	["with swords"] = { flags = bor(ModFlag.Sword, ModFlag.Hit) },
	["to sword attacks"] = { flags = bor(ModFlag.Sword, ModFlag.Hit) },
	["with sword attacks"] = { flags = bor(ModFlag.Sword, ModFlag.Hit) },
	["with wands"] = { flags = bor(ModFlag.Wand, ModFlag.Hit) },
	["to wand attacks"] = { flags = bor(ModFlag.Wand, ModFlag.Hit) },
	["with wand attacks"] = { flags = bor(ModFlag.Wand, ModFlag.Hit) },
	["unarmed"] = { flags = bor(ModFlag.Unarmed, ModFlag.Hit) },
	["unarmed melee"] = { flags = bor(ModFlag.Unarmed, ModFlag.Melee, ModFlag.Hit) },
	["with unarmed attacks"] = { flags = bor(ModFlag.Unarmed, ModFlag.Hit) },
	["with unarmed melee attacks"] = { flags = bor(ModFlag.Unarmed, ModFlag.Melee) },
	["to unarmed attacks"] = { flags = bor(ModFlag.Unarmed, ModFlag.Hit) },
	["to unarmed melee hits"] = { flags = bor(ModFlag.Unarmed, ModFlag.Melee, ModFlag.Hit) },
	["with one handed weapons"] = { flags = bor(ModFlag.Weapon1H, ModFlag.Hit) },
	["with one handed melee weapons"] = { flags = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee, ModFlag.Hit) },
	["with two handed weapons"] = { flags = bor(ModFlag.Weapon2H, ModFlag.Hit) },
	["with two handed melee weapons"] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee, ModFlag.Hit) },
	["with ranged weapons"] = { flags = bor(ModFlag.WeaponRanged, ModFlag.Hit) },
	-- Skill types
	["spell"] = { flags = ModFlag.Spell },
	["for spells"] = { flags = ModFlag.Spell },
	["for spell damage"] = { flags = ModFlag.Spell },
	["with spell damage"] = { flags = ModFlag.Spell },
	["with spells"] = { keywordFlags = KeywordFlag.Spell },
	["with triggered spells"] = { keywordFlags = KeywordFlag.Spell, tag = { type = "SkillType", skillType = SkillType.Triggered } },
	["by spells"] = { keywordFlags = KeywordFlag.Spell },
	["by your spells"] = { keywordFlags = KeywordFlag.Spell },
	["with attacks"] = { keywordFlags = KeywordFlag.Attack },
	["by attacks"] = { keywordFlags = KeywordFlag.Attack },
	["by your attacks"] = { keywordFlags = KeywordFlag.Attack },
	["with attack skills"] = { keywordFlags = KeywordFlag.Attack },
	["for attacks"] = { flags = ModFlag.Attack },
	["for attack damage"] = { flags = ModFlag.Attack },
	["weapon"] = { flags = ModFlag.Weapon },
	["with weapons"] = { flags = ModFlag.Weapon },
	["melee"] = { flags = ModFlag.Melee },
	["with melee attacks"] = { flags = ModFlag.Melee },
	["with melee critical strikes"] = { flags = ModFlag.Melee, tag = { type = "Condition", var = "CriticalStrike" } },
	["with melee skills"] = { flags = ModFlag.Melee },
	["with bow skills"] = { keywordFlags = KeywordFlag.Bow },
	["on melee hit"] = { flags = bor(ModFlag.Melee, ModFlag.Hit) },
	["on hit"] = { flags = ModFlag.Hit },
	["with hits"] = { keywordFlags = KeywordFlag.Hit },
	["with hits against nearby enemies"] = { keywordFlags = KeywordFlag.Hit },
	["with hits and ailments"] = { keywordFlags = bor(KeywordFlag.Hit, KeywordFlag.Ailment) },
	["with ailments"] = { flags = ModFlag.Ailment },
	["with ailments from attack skills"] = { flags = ModFlag.Ailment, keywordFlags = KeywordFlag.Attack },
	["with poison"] = { keywordFlags = KeywordFlag.Poison },
	["with bleeding"] = { keywordFlags = KeywordFlag.Bleed },
	["for ailments"] = { flags = ModFlag.Ailment },
	["for poison"] = { keywordFlags = bor(KeywordFlag.Poison, KeywordFlag.MatchAll) },
	["for bleeding"] = { keywordFlags = KeywordFlag.Bleed },
	["for ignite"] = { keywordFlags = KeywordFlag.Ignite },
	["against damage over time"] = { flags = ModFlag.Dot },
	["area"] = { flags = ModFlag.Area },
	["mine"] = { keywordFlags = KeywordFlag.Mine },
	["with mines"] = { keywordFlags = KeywordFlag.Mine },
	["trap"] = { keywordFlags = KeywordFlag.Trap },
	["with traps"] = { keywordFlags = KeywordFlag.Trap },
	["for traps"] = { keywordFlags = KeywordFlag.Trap },
	["that place mines or throw traps"] = { keywordFlags = bor(KeywordFlag.Mine, KeywordFlag.Trap) },
	["that throw mines"] = { keywordFlags = KeywordFlag.Mine },
	["that throw traps"] = { keywordFlags = KeywordFlag.Trap },
	["brand"] = { tag = { type = "SkillType", skillType = SkillType.Brand } },
	["totem"] = { keywordFlags = KeywordFlag.Totem },
	["with totem skills"] = { keywordFlags = KeywordFlag.Totem },
	["for skills used by totems"] = { keywordFlags = KeywordFlag.Totem },
	["totem skills that cast an aura"] = { tag = { type = "SkillType", skillType = SkillType.Aura }, keywordFlags = KeywordFlag.Totem },
	["aura skills that summon totems"] = { tag = { type = "SkillType", skillType = SkillType.Aura }, keywordFlags = KeywordFlag.Totem },
	["of aura skills"] = { tag = { type = "SkillType", skillType = SkillType.Aura } },
	["curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["of curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["with curse skills"] = { keywordFlags = KeywordFlag.Curse },
	["of curse aura skills"] = { tag = { type = "SkillType", skillType = SkillType.Aura }, keywordFlags = KeywordFlag.Curse },
	["of curse auras"] = { keywordFlags = bor(KeywordFlag.Curse, KeywordFlag.Aura, KeywordFlag.MatchAll) },
	["of hex skills"] = { tag = { type = "SkillType", skillType = SkillType.Hex } },
	["with hex skills"] = { tag = { type = "SkillType", skillType = SkillType.Hex } },
	["of herald skills"] = { tag = { type = "SkillType", skillType = SkillType.Herald } },
	["with herald skills"] = { tag = { type = "SkillType", skillType = SkillType.Herald } },
	["with hits from herald skills"] = { tag = { type = "SkillType", skillType = SkillType.Herald }, keywordFlags = KeywordFlag.Hit },
	["minion skills"] = { tag = { type = "SkillType", skillType = SkillType.Minion } },
	["of minion skills"] = { tag = { type = "SkillType", skillType = SkillType.Minion } },
	["link skills"] = { tag = { type = "SkillType", skillType = SkillType.Link } },
	["of link skills"] = { tag = { type = "SkillType", skillType = SkillType.Link } },
	["for curses"] = { keywordFlags = KeywordFlag.Curse },
	["for hexes"] = { tag = { type = "SkillType", skillType = SkillType.Hex } },
	["warcry"] = { keywordFlags = KeywordFlag.Warcry },
	["vaal"] = { keywordFlags = KeywordFlag.Vaal },
	["vaal skill"] = { keywordFlags = KeywordFlag.Vaal },
	["with vaal skills"] = { keywordFlags = KeywordFlag.Vaal },
	["with non-vaal skills"] = { tag = { type = "SkillType", skillType = SkillType.Vaal, neg = true } },
	["with movement skills"] = { keywordFlags = KeywordFlag.Movement },
	["of movement skills"] = { keywordFlags = KeywordFlag.Movement },
	["of movement skills used"] = { keywordFlags = KeywordFlag.Movement },
	["of travel skills"] = { tag = { type = "SkillType", skillType = SkillType.Travel } },
	["of banner skills"] = { tag = { type = "SkillType", skillType = SkillType.Banner } },
	["with lightning skills"] = { keywordFlags = KeywordFlag.Lightning },
	["with cold skills"] = { keywordFlags = KeywordFlag.Cold },
	["with fire skills"] = { keywordFlags = KeywordFlag.Fire },
	["with elemental skills"] = { keywordFlags = bor(KeywordFlag.Lightning, KeywordFlag.Cold, KeywordFlag.Fire) },
	["with chaos skills"] = { keywordFlags = KeywordFlag.Chaos },
	["with physical skills"] = { keywordFlags = KeywordFlag.Physical },
	["with channelling skills"] = { tag = { type = "SkillType", skillType = SkillType.Channel } },
	["channelling"] = { tag = { type = "SkillType", skillType = SkillType.Channel } },
	["channelling skills"] = { tag = { type = "SkillType", skillType = SkillType.Channel } },
	["non-channelling"] = { tag = { type = "SkillType", skillType = SkillType.Channel, neg = true } },
	["non-channelling skills"] = { tag = { type = "SkillType", skillType = SkillType.Channel, neg = true } },
	["with brand skills"] = { tag = { type = "SkillType", skillType = SkillType.Brand } },
	["for stance skills"] = { tag = { type = "SkillType", skillType = SkillType.Stance } },
	["of stance skills"] = { tag = { type = "SkillType", skillType = SkillType.Stance } },
	["mark skills"] = { tag = { type = "SkillType", skillType = SkillType.Mark } },
	["of mark skills"] = { tag = { type = "SkillType", skillType = SkillType.Mark } },
	["with skills that cost life"] = { tag = { type = "StatThreshold", stat = "LifeCost", threshold = 1 } },
	["minion"] = { addToMinion = true },
	["zombie"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true } },
	["raised zombie"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true } },
	["skeleton"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true } },
	["spectre"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true } },
	["raised spectre"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true } },
	["golem"] = { addToMinion = true, addToMinionTag = { type = "SkillType", skillType = SkillType.Golem } },
	["chaos golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem", includeTransfigured = true } },
	["flame golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem", includeTransfigured = true } },
	["increased flame golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem", includeTransfigured = true } },
	["ice golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem", includeTransfigured = true } },
	["lightning golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem", includeTransfigured = true } },
	["stone golem"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem", includeTransfigured = true } },
	["animated guardian"] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Guardian", includeTransfigured = true } },
	-- Damage types
	["with physical damage"] = { tag = { type = "Condition", var = "PhysicalHasDamage" } },
	["with lightning damage"] = { tag = { type = "Condition", var = "LightningHasDamage" } },
	["with cold damage"] = { tag = { type = "Condition", var = "ColdHasDamage" } },
	["with fire damage"] = { tag = { type = "Condition", var = "FireHasDamage" } },
	["with chaos damage"] = { tag = { type = "Condition", var = "ChaosHasDamage" } },
	-- Other
	["global"] = { tag = { type = "Global" } },
	["from equipped shield"] = { tag = { type = "SlotName", slotName = "Weapon 2" } },
	["from equipped helmet"] = { tag = { type = "SlotName", slotName = "Helmet" } },
	["from equipped gloves and boots"] = { tag = { type = "SlotName", slotNameList = { "Gloves", "Boots" } } },
	["from equipped boots and gloves"] = { tag = { type = "SlotName", slotNameList = { "Gloves", "Boots" } } },
	["from equipped helmet and gloves"] = { tag = { type = "SlotName", slotNameList = { "Helmet", "Gloves" } } },
	["from equipped helmet and boots"] = { tag = { type = "SlotName", slotNameList = { "Helmet", "Boots" } } },
	["from your equipped body armour"] = { tag = { type = "SlotName", slotName = "Body Armour" } },
	["from equipped body armour"] = { tag = { type = "SlotName", slotName = "Body Armour" } },
	["from body armour"] = { tag = { type = "SlotName", slotName = "Body Armour" } },
	["from your body armour"] = { tag = { type = "SlotName", slotName = "Body Armour" } },
}

-- List of modifier flags/tags that appear at the start of a line
local preFlagList = {
	-- Weapon types
	["^axe attacks [hd][ae][va][el] "] = { flags = ModFlag.Axe },
	["^axe or sword attacks [hd][ae][va][el] "] = { tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Axe, ModFlag.Sword) } },
	["^bow attacks [hd][ae][va][el] "] = { flags = ModFlag.Bow },
	["^claw attacks [hd][ae][va][el] "] = { flags = ModFlag.Claw },
	["^claw or dagger attacks [hd][ae][va][el] "] = { tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Claw, ModFlag.Dagger) } },
	["^dagger attacks [hd][ae][va][el] "] = { flags = ModFlag.Dagger },
	["^mace or sceptre attacks [hd][ae][va][el] "] = { flags = ModFlag.Mace },
	["^mace, sceptre or staff attacks [hd][ae][va][el] "] = { tag = { type = "ModFlagOr", modFlags = bor(ModFlag.Mace, ModFlag.Staff) } },
	["^staff attacks [hd][ae][va][el] "] = { flags = ModFlag.Staff },
	["^sword attacks [hd][ae][va][el] "] = { flags = ModFlag.Sword },
	["^wand attacks [hd][ae][va][el] "] = { flags = ModFlag.Wand },
	["^unarmed attacks [hd][ae][va][el] "] = { flags = ModFlag.Unarmed },
	["^attacks with one handed weapons [hd][ae][va][el] "] = { flags = ModFlag.Weapon1H },
	["^attacks with two handed weapons [hd][ae][va][el] "] = { flags = ModFlag.Weapon2H },
	["^attacks with melee weapons [hd][ae][va][el] "] = { flags = ModFlag.WeaponMelee },
	["^attacks with one handed melee weapons [hd][ae][va][el] "] = { flags = bor(ModFlag.Weapon1H, ModFlag.WeaponMelee) },
	["^attacks with two handed melee weapons [hd][ae][va][el] "] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee) },
	["^attacks with ranged weapons [hd][ae][va][el] "] = { flags = ModFlag.WeaponRanged },
	-- Damage types
	["^attack damage "] = { flags = ModFlag.Attack },
	["^hits deal "] = { keywordFlags = KeywordFlag.Hit },
	["^deal "] = { },
	["^arrows deal "] = { flags = ModFlag.Bow },
	["^critical strikes deal "] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["^poisons you inflict with critical strikes have "] = { keywordFlags = bor(KeywordFlag.Poison, KeywordFlag.MatchAll), tag = { type = "Condition", var = "CriticalStrike" } },
	-- Add to minion
	["^minions "] = { addToMinion = true },
	["^minions [hd][ae][va][el] "] = { addToMinion = true },
	["^while a unique enemy is in your presence, minions [hd][ae][va][el] "] = { addToMinion = true, playerTag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	["^while a pinnacle atlas boss is in your presence, minions [hd][ae][va][el] "] = { addToMinion = true, playerTag = { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" } },
	["^minions leech "] = { addToMinion = true },
	["^minions' attacks deal "] = { addToMinion = true, flags = ModFlag.Attack },
	["^golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillType", skillType = SkillType.Golem } },
	["^summoned golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillType", skillType = SkillType.Golem } },
	["^golem skills have "] = { tag = { type = "SkillType", skillType = SkillType.Golem } },
	["^zombies [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true } },
	["^raised zombies [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true } },
	["^skeletons [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true } },
	["^raging spirits [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Raging Spirit", includeTransfigured = true } },
	["^summoned raging spirits [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Raging Spirit", includeTransfigured = true } },
	["^spectres [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true } },
	["^chaos golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem", includeTransfigured = true } },
	["^summoned chaos golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Chaos Golem", includeTransfigured = true } },
	["^flame golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem", includeTransfigured = true } },
	["^summoned flame golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Flame Golem", includeTransfigured = true } },
	["^ice golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem", includeTransfigured = true } },
	["^summoned ice golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Ice Golem", includeTransfigured = true } },
	["^lightning golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem", includeTransfigured = true } },
	["^summoned lightning golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Lightning Golem", includeTransfigured = true } },
	["^stone golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem", includeTransfigured = true } },
	["^summoned stone golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Stone Golem", includeTransfigured = true } },
	["^summoned carrion golems [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Carrion Golem", includeTransfigured = true } },
	["^summoned skitterbots [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Carrion Golem", includeTransfigured = true } },
	["^blink arrow and blink arrow clones [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Blink Arrow", includeTransfigured = true } },
	["^mirror arrow and mirror arrow clones [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Mirror Arrow", includeTransfigured = true } },
	["^animated weapons [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Weapon", includeTransfigured = true } },
	["^animated guardians? deals? "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Animate Guardian", includeTransfigured = true } },
	["^summoned holy relics [hd][ae][va][el] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Holy Relic" } },
	["^summoned reaper [dh][ea][as]l?s? "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Reaper", includeTransfigured = true } },
	["^summoned arbalists [hgdf][aei][vair][eln] "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Arbalists" } },
	["^summoned arbalists' attacks have "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Summon Arbalists" } },
	["^herald skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Herald } },
	["^agony crawler deals "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Herald of Agony" } },
	["^summoned agony crawler fires "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Herald of Agony" } },
	["^sentinels of purity deal "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Herald of Purity" } },
	["^summoned sentinels of absolution have "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillName = "Absolution", includeTransfigured = true } },
	["^summoned sentinels have "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillNameList = { "Herald of Purity", "Dominating Blow", "Absolution" }, includeTransfigured = true } },
	["^raised zombies' slam attack has "] = { addToMinion = true, tag = { type = "SkillId", skillId = "ZombieSlam" } },
	["^raised spectres, raised zombies, and summoned skeletons have "] = { addToMinion = true, addToMinionTag = { type = "SkillName", skillNameList = { "Raise Spectre", "Raise Zombie", "Summon Skeletons" }, includeTransfigured = true } },
	-- Totem/trap/mine
	["^attacks used by totems have "] = { flags = ModFlag.Attack, keywordFlags = KeywordFlag.Totem },
	["^spells cast by totems [hd][ae][va][el] "] = { flags = ModFlag.Spell, keywordFlags = KeywordFlag.Totem },
	["^trap and mine damage "] = { keywordFlags = bor(KeywordFlag.Trap, KeywordFlag.Mine) },
	["^skills used by traps [hgd][ae][via][enl] "] = { keywordFlags = KeywordFlag.Trap },
	["^skills which throw traps [hgd][ae][via][enl] "] = { keywordFlags = KeywordFlag.Trap },
	["^skills used by mines [hgd][ae][via][enl] "] = { keywordFlags = KeywordFlag.Mine },
	["^skills which throw mines [hgd][ae][via][enl] "] = { keywordFlags = KeywordFlag.Mine },
	-- Local damage
	["^attacks with this weapon "] = { tagList = { { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack } } },
	["^attacks with this weapon [hd][ae][va][el] "] = { tagList = { { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack } } },
	["^hits with this weapon [hd][ae][va][el] "] = { flags = ModFlag.Hit, tagList = { { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack } } },
	-- Skill types
	["^attacks [hd][ae][va][el] "] = { flags = ModFlag.Attack },
	["^attack skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Attack },
	["^spells [hd][ae][va][el] a? ?"] = { flags = ModFlag.Spell },
	["^spell skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Spell },
	["^projectile attack skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.RangedAttack } },
	["^projectiles from attacks [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.RangedAttack } },
	["^arrows [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Bow },
	["^bow skills [hdf][aei][var][el] "] = { keywordFlags = KeywordFlag.Bow },
	["^projectiles [hdf][aei][var][el] "] = { flags = ModFlag.Projectile },
	["^melee attacks have "] = { flags = ModFlag.Melee },
	["^movement attack skills have "] = { flags = ModFlag.Attack, keywordFlags = KeywordFlag.Movement },
	["^travel skills have "] = { tag = { type = "SkillType", skillType = SkillType.Travel } },
	["^link skills have "] = { tag = { type = "SkillType", skillType = SkillType.Link } },
	["^lightning skills [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Lightning },
	["^lightning spells [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Lightning, flags = ModFlag.Spell },
	["^cold skills [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Cold },
	["^cold spells [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Cold, flags = ModFlag.Spell },
	["^fire skills [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Fire },
	["^fire spells [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Fire, flags = ModFlag.Spell },
	["^chaos skills [hd][ae][va][el] a? ?"] = { keywordFlags = KeywordFlag.Chaos },
	["^vaal skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Vaal },
	["^brand skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Brand },
	["^channelling skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Channel } },
	["^curse skills [hd][ae][va][el] "] = { keywordFlags = KeywordFlag.Curse },
	["^hex skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Hex } },
	["^mark skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Mark } },
	["^melee skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Melee } },
	["^guard skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Guard } },
	["^nova spells [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Nova } },
	["^area skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Area } },
	["^aura skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.Aura } },
	["^prismatic skills [hd][ae][va][el] "] = { tag = { type = "SkillType", skillType = SkillType.RandomElement } },
	["^warcry skills have "] = { tag = { type = "SkillType", skillType = SkillType.Warcry } },
	["^non%-curse aura skills have "] = { tagList = { { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true } } },
	["^non%-channelling skills have "] = { tag = { type = "SkillType", skillType = SkillType.Channel, neg = true } },
	["^non%-vaal skills deal "] = { tag = { type = "SkillType", skillType = SkillType.Vaal, neg = true } },
	["^skills [hgdf][aei][vari][eln] "] = { },
	-- Slot specific
	["^left ring slot: "] = { tag = { type = "SlotNumber", num = 1 } },
	["^right ring slot: "] = { tag = { type = "SlotNumber", num = 2 } },
	["^socketed gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}" } },
	["^socketed skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}" } },
	["^socketed travel skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "travel" } },
	["^socketed warcry skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "warcry" } },
	["^socketed attacks [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "attack" } },
	["^socketed spells [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "spell" } },
	["^socketed curse gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "curse" } },
	["^socketed melee gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "melee" } },
	["^socketed golem gems [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["^socketed golem skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["^socketed golem skills have minions "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "golem" } },
	["^socketed vaal skills [hgd][ae][via][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}", keyword = "vaal" } },
	["^socketed projectile spells [hgdf][aei][viar][enl] "] = { addToSkill = { type = "SocketedIn", slotName = "{SlotName}" }, tagList = { { type = "SkillType", skillType= SkillType.Projectile }, { type = "SkillType", skillType = SkillType.Spell } } },
	-- Enemy modifiers
	["^enemies withered by you [th]a[vk]e "] = { tag = { type = "MultiplierThreshold", var = "WitheredStack", threshold = 1 }, applyToEnemy = true },
	["^enemies (%a+) by you take "] = function(cond)
		return { tag = { type = "Condition", var = cond:gsub("^%a", string.upper) }, applyToEnemy = true, modSuffix = "Taken" }
	end,
	["^enemies (%a+) by "] = function(cond)
		return { tag = { type = "Condition", var = cond:gsub("^%a", string.upper) }, applyToEnemy = true }
	end,
	["^enemies (%a+) by you have "] = function(cond)
		return { tag = { type = "Condition", var = cond:gsub("^%a", string.upper) }, applyToEnemy = true }
	end,
	["^while a pinnacle atlas boss is in your presence, enemies you've hit recently have "] = function(cond)
		return { playerTagList = { { type = "Condition", var = "HitRecently" }, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } }, applyToEnemy = true }
	end,
	["^while a unique enemy is in your presence, enemies you've hit recently have "] = function(cond)
		return { playerTagList = { { type = "Condition", var = "HitRecently" }, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" } }, applyToEnemy = true }
	end,
	["^enemies you've hit recently have "] = function(cond)
		return { playerTag = { type = "Condition", var = "HitRecently" }, applyToEnemy = true }
	end,
	["^hits against enemies (%a+) by you have "] = function(cond)
		return { tag = { type = "ActorCondition", actor = "enemy", var = cond:gsub("^%a", string.upper) } }
	end,
	["^enemies shocked or frozen by you take "] = { tag = { type = "Condition", varList = { "Shocked","Frozen" } }, applyToEnemy = true, modSuffix = "Taken" },
	["^enemies affected by your spider's webs [thd][ae][avk][el] "] = { tag = { type = "MultiplierThreshold", var = "Spider's WebStack", threshold = 1 }, applyToEnemy = true },
	["^enemies you curse take "] = { tag = { type = "Condition", var = "Cursed" }, applyToEnemy = true, modSuffix = "Taken" },
	["^enemies you curse "] = { tag = { type = "Condition", var = "Cursed" }, applyToEnemy = true },
	["^nearby enemies take "] = { modSuffix = "Taken", applyToEnemy = true },
	["^nearby enemies have "] = { applyToEnemy = true },
	["^nearby enemies deal "] = { applyToEnemy = true },
	["^nearby enemies'? "] = { applyToEnemy = true },
	["^nearby enemy monsters' "] = { applyToEnemy = true },
	["against you"] = { applyToEnemy = true, actorEnemy = true },
	["^hits against you "] = { applyToEnemy = true, flags = ModFlag.Hit },
	["^enemies near your totems deal "] = { applyToEnemy = true },
	-- Other
	["^your flasks grant "] = { },
	["^when hit, "] = { },
	["^you and allies [hgd][ae][via][enl] "] = { },
	["^auras from your skills grant "] = { addToAura = true },
	["^auras grant "] = { addToAura = true },
	["^you and nearby allies "] = { newAura = true },
	["^you and nearby allies [hgd][ae][via][enl] "] = { newAura = true },
	["^nearby allies [hgd][ae][via][enl] "] = { newAura = true, newAuraOnlyAllies = true },
	["^you and allies affected by auras from your skills [hgd][ae][via][enl] "] = { tag = { type = "Condition", var = "AffectedByAura" } },
	["^take "] = { modSuffix = "Taken" },
	["^marauder: "] = { tag = { type = "Condition", var = "ConnectedToMarauderStart" } },
	["^duelist: "] = { tag = { type = "Condition", var = "ConnectedToDuelistStart" } },
	["^ranger: "] = { tag = { type = "Condition", var = "ConnectedToRangerStart" } },
	["^shadow: "] = { tag = { type = "Condition", var = "ConnectedToShadowStart" } },
	["^witch: "] = { tag = { type = "Condition", var = "ConnectedToWitchStart" } },
	["^templar: "] = { tag = { type = "Condition", var = "ConnectedToTemplarStart" } },
	["^scion: "] = { tag = { type = "Condition", var = "ConnectedToScionStart" } },
	["^skills supported by spellslinger have "] = { tag = { type = "Condition", var = "SupportedBySpellslinger" } },
	["^skills that have dealt a critical strike in the past 8 seconds deal "] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["^blink arrow and mirror arrow have "] = { tag = { type = "SkillName", skillNameList = { "Blink Arrow", "Mirror Arrow" }, includeTransfigured = true } },
	["attacks with energy blades "] = { flags = ModFlag.Attack, tag = { type = "Condition", var = "AffectedByEnergyBlade" } },
	["^for each nearby corpse, "] = { tag = { type = "Multiplier", var = "NearbyCorpse" } },
	["^enemies in your link beams have "] = { tag = { type = "Condition", var = "BetweenYouAndLinkedTarget" }, applyToEnemy = true },
	-- While in the presence of...
	["^while a unique enemy is in your presence, "] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	["^while a pinnacle atlas boss is in your presence, "] = { tag = { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" } },
}

-- List of modifier tags
local modTagList = {
	["on enemies"] = { },
	["while active"] = { },
	["for (%d+) seconds"] = { },
	["when you hit a unique enemy"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	[" on critical strike"] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["from critical strikes"] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["with critical strikes"] = { tag = { type = "Condition", var = "CriticalStrike" } },
	["while affected by auras you cast"] = { tag = { type = "Condition", var = "AffectedByAura" } },
	["for you and nearby allies"] = { newAura = true },
	-- Multipliers
	["per power charge"] = { tag = { type = "Multiplier", var = "PowerCharge" } },
	["per frenzy charge"] = { tag = { type = "Multiplier", var = "FrenzyCharge" } },
	["per endurance charge"] = { tag = { type = "Multiplier", var = "EnduranceCharge" } },
	["per siphoning charge"] = { tag = { type = "Multiplier", var = "SiphoningCharge" } },
	["per spirit charge"] = { tag = { type = "Multiplier", var = "SpiritCharge" } },
	["per challenger charge"] = { tag = { type = "Multiplier", var = "ChallengerCharge" } },
	["per gale force"] = { tag = { type = "Multiplier", var = "GaleForce" } },
	["per intensity"] = { tag = { type = "Multiplier", var = "Intensity" } },
	["per brand"] = { tag = { type = "Multiplier", var = "ActiveBrand" } },
	["per brand, up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "ActiveBrand", limit = tonumber(num), limitTotal = true } } end,
	["per blitz charge"] = { tag = { type = "Multiplier", var = "BlitzCharge" } },
	["per ghost shroud"] = { tag = { type = "Multiplier", var = "GhostShroud" } },
	["per crab barrier"] = { tag = { type = "Multiplier", var = "CrabBarrier" } },
	["per rage"] = { tag = { type = "Multiplier", var = "Rage" } },
	["per rage while you are not losing rage"] = { tag = { type = "Multiplier", var = "Rage" } },
	["per (%d+) rage"] = function(num) return { tag = { type = "Multiplier", var = "Rage", div = num } } end,
	["per level"] = { tag = { type = "Multiplier", var = "Level" } },
	["per (%d+) player levels"] = function(num) return { tag = { type = "Multiplier", var = "Level", div = num } } end,
	["per defiance"] = { tag = { type = "Multiplier", var = "Defiance" } },
	["per (%d+)%% (%a+) effect on enemy"] = function(num, _, effectName) return { tag = { type = "Multiplier", var = firstToUpper(effectName) .. "Effect", div = num, actor = "enemy" } } end,
	["for each equipped normal item"] = { tag = { type = "Multiplier", var = "NormalItem" } },
	["for each normal item equipped"] = { tag = { type = "Multiplier", var = "NormalItem" } },
	["for each normal item you have equipped"] = { tag = { type = "Multiplier", var = "NormalItem" } },
	["for each equipped magic item"] = { tag = { type = "Multiplier", var = "MagicItem" } },
	["for each magic item equipped"] = { tag = { type = "Multiplier", var = "MagicItem" } },
	["for each magic item you have equipped"] = { tag = { type = "Multiplier", var = "MagicItem" } },
	["for each equipped rare item"] = { tag = { type = "Multiplier", var = "RareItem" } },
	["for each rare item equipped"] = { tag = { type = "Multiplier", var = "RareItem" } },
	["for each rare item you have equipped"] = { tag = { type = "Multiplier", var = "RareItem" } },
	["for each equipped unique item"] = { tag = { type = "Multiplier", var = "UniqueItem" } },
	["for each unique item equipped"] = { tag = { type = "Multiplier", var = "UniqueItem" } },
	["for each unique item you have equipped"] = { tag = { type = "Multiplier", var = "UniqueItem" } },
	["per elder item equipped"] = { tag = { type = "Multiplier", var = "ElderItem" } },
	["per shaper item equipped"] = { tag = { type = "Multiplier", var = "ShaperItem" } },
	["per elder or shaper item equipped"] = { tag = { type = "Multiplier", var = "ShaperOrElderItem" } },
	["for each corrupted item equipped"] = { tag = { type = "Multiplier", var = "CorruptedItem" } },
	["for each equipped corrupted item"] = { tag = { type = "Multiplier", var = "CorruptedItem" } },
	["for each uncorrupted item equipped"] = { tag = { type = "Multiplier", var = "NonCorruptedItem" } },
	["per equipped claw"] = { tag = { type = "Multiplier", var = "ClawItem" } },
	["per equipped dagger"] = { tag = { type = "Multiplier", var = "DaggerItem" } },
	["per equipped axe"] = { tag = { type = "Multiplier", var = "AxeItem" } },
	["per equipped ring"] = { tag = { type = "Multiplier", var = "RingItem" } },
	["per equipped flask"] = { tag = { type = "Multiplier", var = "FlaskItem" } },
	["per equipped sword"] = { tag = { type = "Multiplier", var = "SwordItem" } },
	["per equipped jewel"] = { tag = { type = "Multiplier", var = "JewelItem" } },
	["per equipped mace"] = { tag = { type = "Multiplier", var = "MaceItem" } },
	["per equipped sceptre"] = { tag = { type = "Multiplier", var = "SceptreItem" } },
	["per equipped wand"] = { tag = { type = "Multiplier", var = "WandItem" } },
	["per claw"] = { tag = { type = "Multiplier", var = "ClawItem" } },
	["per dagger"] = { tag = { type = "Multiplier", var = "DaggerItem" } },
	["per axe"] = { tag = { type = "Multiplier", var = "AxeItem" } },
	["per ring"] = { tag = { type = "Multiplier", var = "RingItem" } },
	["per flask"] = { tag = { type = "Multiplier", var = "FlaskItem" } },
	["per sword"] = { tag = { type = "Multiplier", var = "SwordItem" } },
	["per jewel"] = { tag = { type = "Multiplier", var = "JewelItem" } },
	["per mace"] = { tag = { type = "Multiplier", var = "MaceItem" } },
	["per sceptre"] = { tag = { type = "Multiplier", var = "SceptreItem" } },
	["per wand"] = { tag = { type = "Multiplier", var = "WandItem" } },
	["per abyssa?l? jewel affecting you"] = { tag = { type = "Multiplier", var = "AbyssJewel" } },
	["for each herald b?u?f?f?s?k?i?l?l? ?affecting you"] = { tag = { type = "Multiplier", var = "Herald" } },
	["for each of your aura or herald skills affecting you"] = { tag = { type = "Multiplier", varList = { "Herald", "AuraAffectingSelf" } } },
	["for each type of abyssa?l? jewel affecting you"] = { tag = { type = "Multiplier", var = "AbyssJewelType" } },
	["per (.+) eye jewel affecting you, up to a maximum of %+?(%d+)%%"] = function(type, _, num) return { tag = { type = "Multiplier", var = (type:gsub("^%l", string.upper)) .. "EyeJewel", limit = tonumber(num), limitTotal = true } } end,
	["per sextant affecting the area"] = { tag = { type = "Multiplier", var = "Sextant" } },
	["per buff on you"] = { tag = { type = "Multiplier", var = "BuffOnSelf" } },
	["per hit suppressed recently"] = { tag = { type = "Multiplier", var = "HitsSuppressedRecently" } },
	["per curse on enemy"] = { tag = { type = "Multiplier", var = "CurseOnEnemy" } },
	["for each curse on enemy"] = { tag = { type = "Multiplier", var = "CurseOnEnemy" } },
	["for each curse on the enemy"] = { tag = { type = "Multiplier", var = "CurseOnEnemy" } },
	["per curse on you"] = { tag = { type = "Multiplier", var = "CurseOnSelf" } },
	["per poison on you"] = { tag = { type = "Multiplier", var = "PoisonStack" } },
	["for each poison on you"] = { tag = { type = "Multiplier", var = "PoisonStack" } },
	["for each poison on you up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "PoisonStack", limit = tonumber(num), limitTotal = true } } end,
	["per poison on you, up to (%d+) per second"] = function(num) return { tag = { type = "Multiplier", var = "PoisonStack", limit = tonumber(num), limitTotal = true } } end,
	["for each poison you have inflicted recently"] = { tag = { type = "Multiplier", var = "PoisonAppliedRecently" } },
	["per withered debuff on enemy"] = { tag = { type = "Multiplier", var = "WitheredStack", actor = "enemy", limit = 15 } },
	["for each poison you have inflicted recently, up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "PoisonAppliedRecently", globalLimit = tonumber(num), globalLimitKey = "NoxiousStrike" } } end,
	["for each time you have shocked a non%-shocked enemy recently, up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "ShockedNonShockedEnemyRecently", limit = tonumber(num), limitTotal = true } } end,
	["for each shocked enemy you've killed recently"] = { tag = { type = "Multiplier", var = "ShockedEnemyKilledRecently" } },
	["per enemy killed recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "EnemyKilledRecently", limit = tonumber(num), limitTotal = true } } end,
	["per (%d+) rampage kills"] = function(num) return { tag = { type = "Multiplier", var = "Rampage", div = num, limit = 1000 / num, limitTotal = true } } end,
	["per minion, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "SummonedMinion", limit = tonumber(num), limitTotal = true } } end,
	["for each enemy you or your minions have killed recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", varList = { "EnemyKilledRecently","EnemyKilledByMinionsRecently" }, limit = tonumber(num), limitTotal = true } } end,
	["for each enemy you or your minions have killed recently, up to (%d+)%% per second"] = function(num) return { tag = { type = "Multiplier", varList = { "EnemyKilledRecently","EnemyKilledByMinionsRecently" }, limit = tonumber(num), limitTotal = true } } end,
	["for each (%d+) total mana y?o?u? ?h?a?v?e? ?spent recently"] = function(num) return { tag = { type = "Multiplier", var = "ManaSpentRecently", div = num } } end,
	["for each (%d+) total mana you have spent recently, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "Multiplier", var = "ManaSpentRecently", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) mana spent recently, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "Multiplier", var = "ManaSpentRecently", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["for each time you've blocked in the past 10 seconds"] = { tag = { type = "Multiplier", var =  "BlockedPast10Sec" } },
	["per enemy killed by you or your totems recently"] = { tag = { type = "Multiplier", varList = { "EnemyKilledRecently","EnemyKilledByTotemsRecently" } } },
	["per nearby enemy, up to %+?(%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "NearbyEnemies", limit = num, limitTotal = true } } end,
	["per enemy in close range"] = { tagList = { { type = "Condition", var = "AtCloseRange" }, { type = "Multiplier", var = "NearbyEnemies" } } },
	["to you and allies"] = { },
	["per red socket"] = { tag = { type = "Multiplier", var = "RedSocketIn{SlotName}" } },
	["per green socket on main hand weapon"] = { tag = { type = "Multiplier", var = "GreenSocketInWeapon 1" } },
	["per green socket on"] = { tag = { type = "Multiplier", var = "GreenSocketInWeapon 1" } },
	["per red socket on main hand weapon"] = { tag = { type = "Multiplier", var = "RedSocketInWeapon 1" } },
	["per green socket"] = { tag = { type = "Multiplier", var = "GreenSocketIn{SlotName}" } },
	["per blue socket"] = { tag = { type = "Multiplier", var = "BlueSocketIn{SlotName}" } },
	["per white socket"] = { tag = { type = "Multiplier", var = "WhiteSocketIn{SlotName}" } },
	["for each empty red socket on any equipped item"] = { tag = { type = "Multiplier", var = "EmptyRedSocketsInAnySlot" } },
	["for each empty green socket on any equipped item"] = { tag = { type = "Multiplier", var = "EmptyGreenSocketsInAnySlot" } },
	["for each empty blue socket on any equipped item"] = { tag = { type = "Multiplier", var = "EmptyBlueSocketsInAnySlot" } },
	["for each empty white socket on any equipped item"] = { tag = { type = "Multiplier", var = "EmptyWhiteSocketsInAnySlot" } },
	["per socketed gem"] = { tag = { type = "Multiplier", var = "SocketedGemsIn{SlotName}"}},
	["for each impale on enemy"] = { tag = { type = "Multiplier", var = "ImpaleStacks", actor = "enemy" } },
	["per impale on enemy"] = { tag = { type = "Multiplier", var = "ImpaleStacks", actor = "enemy" } },
	["per animated weapon"] = { tag = { type = "Multiplier", var = "AnimatedWeapon", actor = "parent" } },
	["per grasping vine"] = { tag =  { type = "Multiplier", var = "GraspingVinesCount" } },
	["per fragile regrowth"] = { tag =  { type = "Multiplier", var = "FragileRegrowthCount" } },
	["per bark"] = { tag =  { type = "Multiplier", var = "BarkskinStacks" } },
	["per bark below maximum"] = { tag =  { type = "Multiplier", var = "MissingBarkskinStacks" } },
	["per allocated mastery passive skill"] = { tag = { type = "Multiplier", var = "AllocatedMastery" } },
	["per allocated notable passive skill"] = { tag = { type = "Multiplier", var = "AllocatedNotable" } },
	["for each different type of mastery you have allocated"] = { tag = { type = "Multiplier", var = "AllocatedMasteryType" } },
	["per grand spectrum"] = { tag = { type = "Multiplier", var = "GrandSpectrum" } },
	["per second you've been stationary, up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "StationarySeconds", limit = tonumber(num), limitTotal = true } } end,
	-- Per stat
	["per (%d+)%% of maximum mana they reserve"] = function(num) return { tag = { type = "PerStat", stat = "ManaReservedPercent", div = num } } end,
	["per (%d+) strength"] = function(num) return { tag = { type = "PerStat", stat = "Str", div = num } } end,
	["per (%d+) dexterity"] = function(num) return { tag = { type = "PerStat", stat = "Dex", div = num } } end,
	["per (%d+) intelligence"] = function(num) return { tag = { type = "PerStat", stat = "Int", div = num } } end,
	["per (%d+) omniscience"] = function(num) return { tag = { type = "PerStat", stat = "Omni", div = num } } end,
	["per (%d+) total attributes"] = function(num) return { tag = { type = "PerStat", statList = { "Str", "Dex", "Int" }, div = num } } end,
	["per (%d+) of your lowest attribute"] = function(num) return { tag = { type = "PerStat", stat = "LowestAttribute", div = num } } end,
	["per (%d+) reserved life"] = function(num) return { tag = { type = "PerStat", stat = "LifeReserved", div = num } } end,
	["per (%d+) unreserved maximum mana"] = function(num) return { tag = { type = "PerStat", stat = "ManaUnreserved", div = num } } end,
	["per (%d+) unreserved maximum mana, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "ManaUnreserved", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) armour"] = function(num) return { tag = { type = "PerStat", stat = "Armour", div = num } } end,
	["per (%d+) evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "Evasion", div = num } } end,
	["per (%d+) evasion rating, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "Evasion", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) maximum energy shield"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShield", div = num } } end,
	["per (%d+) maximum life"] = function(num) return { tag = { type = "PerStat", stat = "Life", div = num } } end,
	["per (%d+) of maximum life or maximum mana, whichever is lower"] = function(num) return { tag = { type = "PerStat", stat = "LowestOfMaximumLifeAndMaximumMana", div = num } } end,
	["per (%d+) player maximum life"] = function(num) return { tag = { type = "PerStat", stat = "Life", div = num, actor = "parent" } } end,
	["per (%d+) maximum mana"] = function(num) return { tag = { type = "PerStat", stat = "Mana", div = num } } end,
	["per (%d+) maximum mana, up to (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "Mana", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) maximum mana, up to a maximum of (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "Mana", div = num, limit = tonumber(limit), limitTotal = true } } end,
	["per (%d+) accuracy rating"] = function(num) return { tag = { type = "PerStat", stat = "Accuracy", div = num } } end,
	["per (%d+)%% block chance"] = function(num) return { tag = { type = "PerStat", stat = "BlockChance", div = num } } end,
	["per (%d+)%% chance to block on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "ShieldBlockChance", div = num } } end,
	["per (%d+)%% chance to block attack damage"] = function(num) return { tag = { type = "PerStat", stat = "BlockChance", div = num } } end,
	["per (%d+)%% chance to block spell damage"] = function(num) return { tag = { type = "PerStat", stat = "SpellBlockChance", div = num } } end,
	["per (%d+) of the lowest of armour and evasion rating"] = function(num) return { tag = { type = "PerStat", stat = "LowestOfArmourAndEvasion", div = num } } end,
	["per (%d+) maximum energy shield on equipped helmet"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShieldOnHelmet", div = num } } end,
	["per (%d+) maximum energy shield on helmet"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShieldOnHelmet", div = num } } end,
	["per (%d+) evasion rating on body armour"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnBody Armour", div = num } } end,
	["per (%d+) evasion rating on equipped body armour"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnBody Armour", div = num } } end,
	["per (%d+) armour on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "ArmourOnWeapon 2", div = num } } end,
	["per (%d+) armour or evasion rating on shield"] = function(num) return { tag = { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, div = num } } end,
	["per (%d+) armour or evasion rating on equipped shield"] = function(num) return { tag = { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, div = num } } end,
	["per (%d+) evasion rating on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnWeapon 2", div = num } } end,
	["per (%d+) maximum energy shield on equipped shield"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShieldOnWeapon 2", div = num } } end,
	["per (%d+) maximum energy shield on shield"] = function(num) return { tag = { type = "PerStat", stat = "EnergyShieldOnWeapon 2", div = num } } end,
	["per (%d+) evasion on equipped boots"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnBoots", div = num } } end,
	["per (%d+) evasion on boots"] = function(num) return { tag = { type = "PerStat", stat = "EvasionOnBoots", div = num } } end,
	["per (%d+) armour on equipped gloves"] = function(num) return { tag = { type = "PerStat", stat = "ArmourOnGloves", div = num } } end,
	["per (%d+) armour on gloves"] = function(num) return { tag = { type = "PerStat", stat = "ArmourOnGloves", div = num } } end,
	["per (%d+)%% chaos resistance"] = function(num) return { tag = { type = "PerStat", stat = "ChaosResist", div = num } } end,
	["per (%d+)%% cold resistance above 75%%"] = function(num) return { tag  = { type = "PerStat", stat = "ColdResistOver75", div = num } } end,
	["per (%d+)%% lightning resistance above 75%%"] = function(num) return { tag  = { type = "PerStat", stat = "LightningResistOver75", div = num } } end,
	["per (%d+) devotion"] = function(num) return { tag = { type = "PerStat", stat = "Devotion", actor = "parent", div = num } } end,
	["per (%d+)%% missing fire resistance, up to a maximum of (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "MissingFireResist", div = num, globalLimit = tonumber(limit), globalLimitKey = "ReplicaNebulisFire" } } end,
	["per (%d+)%% missing cold resistance, up to a maximum of (%d+)%%"] = function(num, _, limit) return { tag = { type = "PerStat", stat = "MissingColdResist", div = num, globalLimit = tonumber(limit), globalLimitKey = "ReplicaNebulisCold" } } end,
	["per endurance, frenzy or power charge"] = { tag = { type = "PerStat", stat = "TotalCharges" } },
	["per fortification"] = { tag = { type = "PerStat", stat = "FortificationStacks" } },
	["per totem"] = { tag = { type = "PerStat", stat = "TotemsSummoned" } },
	["per summoned totem"] = { tag = { type = "PerStat", stat = "TotemsSummoned" } },
	["for each summoned totem"] =  { tag = { type = "PerStat", stat = "TotemsSummoned" } },
	["for each time they have chained"] = { tag = { type = "PerStat", stat = "Chain" } },
	["for each time it has chained"] = { tag = { type = "PerStat", stat = "Chain" } },
	["for each summoned golem"] = { tag = { type = "PerStat", stat = "ActiveGolemLimit" } },
	["for each golem you have summoned"] = { tag = { type = "PerStat", stat = "ActiveGolemLimit" } },
	["per summoned golem"] = { tag = { type = "PerStat", stat = "ActiveGolemLimit" } },
	["per summoned sentinel of purity"] = { tag = { type = "PerStat", stat = "ActiveSentinelOfPurityLimit" } },
	["per summoned skeleton"] = { tag = { type = "PerStat", stat = "ActiveSkeletonLimit" } },
	["per skeleton you own"] = { tag = { type = "PerStat", stat = "ActiveSkeletonLimit", actor = "parent" } },
	["per summoned raging spirit"] = { tag = { type = "PerStat", stat = "ActiveRagingSpiritLimit" } },
	["for each raised zombie"] = { tag = { type = "PerStat", stat = "ActiveZombieLimit" } },
	["per zombie you own"] = { tag = { type = "PerStat", stat = "ActiveZombieLimit", actor = "parent" } },
	["per raised zombie"] = { tag = { type = "PerStat", stat = "ActiveZombieLimit" } },
	["per raised spectre"] = { tag = { type = "PerStat", stat = "ActiveSpectreLimit" } },
	["per spectre you own"] = { tag = { type = "PerStat", stat = "ActiveSpectreLimit", actor = "parent" } },
	["for each remaining chain"] = { tag = { type = "PerStat", stat = "ChainRemaining" } },
	["for each enemy pierced"] = { tag = { type = "PerStat", stat = "PiercedCount" } },
	["for each time they've pierced"] = { tag = { type = "PerStat", stat = "PiercedCount" } },
	-- Stat conditions
	["with (%d+) or more strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["with at least (%d+) strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["w?h?i[lf]e? you have at least (%d+) strength"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num } } end,
	["w?h?i[lf]e? you have at least (%d+) dexterity"] = function(num) return { tag = { type = "StatThreshold", stat = "Dex", threshold = num } } end,
	["w?h?i[lf]e? you have at least (%d+) intelligence"] = function(num) return { tag = { type = "StatThreshold", stat = "Int", threshold = num } } end,
	["w?h?i[lf]e? strength is below (%d+)"] = function(num) return { tag = { type = "StatThreshold", stat = "Str", threshold = num - 1, upper = true } } end,
	["w?h?i[lf]e? dexterity is below (%d+)"] = function(num) return { tag = { type = "StatThreshold", stat = "Dex", threshold = num - 1, upper = true } } end,
	["w?h?i[lf]e? intelligence is below (%d+)"] = function(num) return { tag = { type = "StatThreshold", stat = "Int", threshold = num - 1, upper = true } } end,
	["at least (%d+) intelligence"] = function(num) return { tag = { type = "StatThreshold", stat = "Int", threshold = num } } end,
	["if dexterity is higher than intelligence"] = { tag = { type = "Condition", var = "DexHigherThanInt" } },
	["if strength is higher than intelligence"] = { tag = { type = "Condition", var = "StrHigherThanInt" } },
	["w?h?i[lf]e? you have at least (%d+) maximum energy shield"] = function(num) return { tag = { type = "StatThreshold", stat = "EnergyShield", threshold = num } } end,
	["against targets they pierce"] = { tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	["against pierced targets"] = { tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	["to targets they pierce"] = { tag = { type = "StatThreshold", stat = "PierceCount", threshold = 1 } },
	["w?h?i[lf]e? you have at least (%d+) devotion"] = function(num) return { tag = { type = "StatThreshold", stat = "Devotion", threshold = num } } end,
	["while you have at least (%d+) rage"] = function(num) return { tag = { type = "MultiplierThreshold", var = "Rage", threshold = num } } end,
	["while affected by a unique abyss jewel"] = { tag = { type = "MultiplierThreshold", var = "UniqueAbyssJewels", threshold = 1 } },
	["while affected by a rare abyss jewel"] = { tag = { type = "MultiplierThreshold", var = "RareAbyssJewels", threshold = 1 } },
	["while affected by a magic abyss jewel"] =  { tag = { type = "MultiplierThreshold", var = "MagicAbyssJewels", threshold = 1 } },
	["while affected by a normal abyss jewel"] = { tag = { type = "MultiplierThreshold", var = "NormalAbyssJewels", threshold = 1 } },
	-- Slot conditions
	["when in main hand"] = { tag = { type = "SlotNumber", num = 1 } },
	["when in off hand"] = { tag = { type = "SlotNumber", num = 2 } },
	["in main hand"] = { tag = { type = "InSlot", num = 1 } },
	["in off hand"] = { tag = { type = "InSlot", num = 2 } },
	["w?i?t?h? main hand"] = { tagList = { { type = "Condition", var = "MainHandAttack" }, { type = "SkillType", skillType = SkillType.Attack } } },
	["w?i?t?h? off hand"] = { tagList = { { type = "Condition", var = "OffHandAttack" }, { type = "SkillType", skillType = SkillType.Attack } } },
	["[fi]?[rn]?[of]?[ml]?[ i]?[hc]?[it]?[te]?[sd]? ? with this weapon"] = { tagList = { { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack } } },
	["if your other ring is a shaper item"] = { tag = { type = "ItemCondition", itemSlot = "Ring {OtherSlotNum}", shaperCond = true} },
	["if your other ring is an elder item"] = { tag = { type = "ItemCondition", itemSlot = "Ring {OtherSlotNum}", elderCond = true}},
	["if you have a (%a+) (%a+) in (%a+) slot"] = function(_, rarity, item, slot) return { tag = { type = "Condition", var = rarity:gsub("^%l", string.upper).."ItemIn"..item:gsub("^%l", string.upper).." "..(slot == "right" and 2 or slot == "left" and 1) } } end,
	["of skills supported by spellslinger"] = { tag = { type = "Condition", var = "SupportedBySpellslinger" } },
	-- Equipment conditions
	["while holding a (%w+)"] = function (_, gear) return {
		tag = { type = "Condition", varList = { "Using"..firstToUpper(gear) } }
	} end,
	["while holding a (%w+) or (%w+)"] = function (_, g1, g2) return {
		tag = { type = "Condition", varList = { "Using"..firstToUpper(g1), "Using"..firstToUpper(g2) } }
	} end,
	["while your off hand is empty"] = { tag = { type = "Condition", var = "OffHandIsEmpty" } },
	["with shields"] = { tag = { type = "Condition", var = "UsingShield" } },
	["while dual wielding"] = { tag = { type = "Condition", var = "DualWielding" } },
	["while dual wielding claws"] = { tag = { type = "Condition", var = "DualWieldingClaws" } },
	["while dual wielding or holding a shield"] = { tag = { type = "Condition", varList = { "DualWielding", "UsingShield" } } },
	["while wielding an axe"] = { tag = { type = "Condition", var = "UsingAxe" } },
	["while wielding an axe or sword"] = { tag = { type = "Condition", varList = { "UsingAxe", "UsingSword" } } },
	["while wielding a bow"] = { tag = { type = "Condition", var = "UsingBow" } },
	["while wielding a claw"] = { tag = { type = "Condition", var = "UsingClaw" } },
	["while wielding a dagger"] = { tag = { type = "Condition", var = "UsingDagger" } },
	["while wielding a claw or dagger"] = { tag = { type = "Condition", varList = { "UsingClaw", "UsingDagger" } } },
	["while wielding a mace"] = { tag = { type = "Condition", var = "UsingMace" } },
	["while wielding a mace or sceptre"] = { tag = { type = "Condition", var = "UsingMace" } },
	["while wielding a mace, sceptre or staff"] = { tag = { type = "Condition", varList = { "UsingMace", "UsingStaff" } } },
	["while wielding a staff"] = { tag = { type = "Condition", var = "UsingStaff" } },
	["while wielding a sword"] = { tag = { type = "Condition", var = "UsingSword" } },
	["while wielding a melee weapon"] = { tag = { type = "Condition", var = "UsingMeleeWeapon" } },
	["while wielding a one handed weapon"] = { tag = { type = "Condition", var = "UsingOneHandedWeapon" } },
	["while wielding a two handed weapon"] = { tag = { type = "Condition", var = "UsingTwoHandedWeapon" } },
	["while wielding a two handed melee weapon"] = { tagList = { { type = "Condition", var = "UsingTwoHandedWeapon" }, { type = "Condition", var = "UsingMeleeWeapon" } } },
	["while wielding a wand"] = { tag = { type = "Condition", var = "UsingWand" } },
	["while wielding two different weapon types"] = { tag = { type = "Condition", var = "WieldingDifferentWeaponTypes" } },
	["while unarmed"] = { tag = { type = "Condition", var = "Unarmed" } },
	["while you are unencumbered"] = { tag = { type = "Condition", var = "Unencumbered" } },
	["equipped bow"] = { tag = { type = "Condition", var = "UsingBow" } },
	["if equipped ([%a%s]+) has an ([%a%s]+) modifier"] = function (_, itemSlotName, conditionSubstring) return { tag = { type = "ItemCondition", searchCond = conditionSubstring, itemSlot = itemSlotName } } end,
	["if both equipped ([%a%s]+) have a?n? ?([%a%s]+) modifiers?"] = function (_, itemSlotName, conditionSubstring) return { tag = { type = "ItemCondition", searchCond = conditionSubstring, itemSlot = itemSlotName:sub(1, #itemSlotName - 1), bothSlots = true } } end,
	["if there are no ([%a%s]+) modifiers on equipped ([%a%s]+)"] = function (_, conditionSubstring, itemSlotName) return { tag = { type = "ItemCondition", searchCond = conditionSubstring, itemSlot = itemSlotName, neg = true } } end,
	["if there are no (%a+) modifiers on other equipped items"] = function(_, conditionSubstring) return {tag = { type = "ItemCondition", searchCond = conditionSubstring, itemSlot = "{SlotName}", allSlots = true, excludeSelf = true, neg = true }} end,
	["if corrupted"] = {tag = { type = "ItemCondition", itemSlot = "{SlotName}", corruptedCond = true}},
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
	["if equipped helmet, body armour, gloves, and boots all have armour"] = { tagList = {
		{ type = "StatThreshold", stat = "ArmourOnHelmet", threshold = 1},
		{ type = "StatThreshold", stat = "ArmourOnBody Armour", threshold = 1},
		{ type = "StatThreshold", stat = "ArmourOnGloves", threshold = 1},
		{ type = "StatThreshold", stat = "ArmourOnBoots", threshold = 1} } },
	["if equipped helmet, body armour, gloves, and boots all have evasion rating"] = { tagList = {
		{ type = "StatThreshold", stat = "EvasionOnHelmet", threshold = 1},
		{ type = "StatThreshold", stat = "EvasionOnBody Armour", threshold = 1},
		{ type = "StatThreshold", stat = "EvasionOnGloves", threshold = 1},
		{ type = "StatThreshold", stat = "EvasionOnBoots", threshold = 1} } },
	-- Player status conditions
	["wh[ie][ln]e? on low life"] = { tag = { type = "Condition", var = "LowLife" } },
	["on reaching low life"] = { tag = { type = "Condition", var = "LowLife" } },
	["wh[ie][ln]e? not on low life"] = { tag = { type = "Condition", var = "LowLife", neg = true } },
	["wh[ie][ln]e? on low mana"] = { tag = { type = "Condition", var = "LowMana" } },
	["wh[ie][ln]e? not on low mana"] = { tag = { type = "Condition", var = "LowMana", neg = true } },
	["wh[ie][ln]e? on full life"] = { tag = { type = "Condition", var = "FullLife" } },
	["wh[ie][ln]e? not on full life"] = { tag = { type = "Condition", var = "FullLife", neg = true } },
	["wh[ie][ln]e? no life is reserved"] = { tag = { type = "StatThreshold", stat = "LifeReserved", threshold = 0, upper = true } },
	["wh[ie][ln]e? no mana is reserved"] = { tag = { type = "StatThreshold", stat = "ManaReserved", threshold = 0, upper = true } },
	["wh[ie][ln]e? on full energy shield"] = { tag = { type = "Condition", var = "FullEnergyShield" } },
	["wh[ie][ln]e? not on full energy shield"] = { tag = { type = "Condition", var = "FullEnergyShield", neg = true } },
	["wh[ie][ln]e? you have energy shield"] = { tag = { type = "Condition", var = "HaveEnergyShield" } },
	["wh[ie][ln]e? you have no energy shield"] = { tag = { type = "Condition", var = "HaveEnergyShield", neg = true } },
	["if you have energy shield"] = { tag = { type = "Condition", var = "HaveEnergyShield" } },
	["while stationary"] = { tag = { type = "Condition", var = "Stationary" } },
	["while you are stationary"] = { tag = { type = "ActorCondition", actor = "player", var = "Stationary" }},
	["while moving"] = { tag = { type = "Condition", var = "Moving" } },
	["while channelling"] = { tag = { type = "Condition", var = "Channelling" } },
	["while channelling snipe"] = { tag = { type = "Condition", var = "Channelling" } },
	["after channelling for (%d+) seconds?"] = function(num) return { tag = { type = "MultiplierThreshold", var = "ChannellingTime", threshold = num } } end,
	["if you've been channelling for at least (%d+) seconds?"] = function(num) return { tag = { type = "MultiplierThreshold", var = "ChannellingTime", threshold = num } } end,
	["if you've inflicted exposure recently"] = { tag = { type = "Condition", var = "AppliedExposureRecently" } },
	["while you have no power charges"] = { tag = { type = "StatThreshold", stat = "PowerCharges", threshold = 0, upper = true } },
	["while you have no frenzy charges"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", threshold = 0, upper = true } },
	["while you have no endurance charges"] = { tag = { type = "StatThreshold", stat = "EnduranceCharges", threshold = 0, upper = true } },
	["while you have a power charge"] = { tag = { type = "StatThreshold", stat = "PowerCharges", threshold = 1 } },
	["while you have a frenzy charge"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", threshold = 1 } },
	["while you have an endurance charge"] = { tag = { type = "StatThreshold", stat = "EnduranceCharges", threshold = 1 } },
	["while at maximum power charges"] = { tag = { type = "StatThreshold", stat = "PowerCharges", thresholdStat = "PowerChargesMax" } },
	["while at maximum frenzy charges"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" } },
	["while on full frenzy charges"] = { tag = { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" } },
	["while at maximum endurance charges"] = { tag = { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" } },
	["while at maximum fortification"] = { tag = { type = "Condition", var = "HaveMaximumFortification" } },
	["while you have at least (%d+) crab barriers"] = function(num) return { tag = { type = "StatThreshold", stat = "CrabBarriers", threshold = num } } end,
	["while you have at least (%d+) fortification"] = function(num) return { tag = { type = "StatThreshold", stat = "FortificationStacks", threshold = num } } end,
	["while you have at least (%d+) total endurance, frenzy and power charges"] = function(num) return { tag = { type = "MultiplierThreshold", var = "TotalCharges", threshold = num } } end,
	["while you have a totem"] = { tag = { type = "Condition", var = "HaveTotem" } },
	["while you have at least one nearby ally"] = { tag = { type = "MultiplierThreshold", var = "NearbyAlly", threshold = 1 } },
	["while you have fortify"] = { tag = { type = "Condition", var = "Fortified" } },
	["while you have phasing"] = { tag = { type = "Condition", var = "Phasing" } },
	["if you[' ]h?a?ve suppressed spell damage recently"] = { tag = { type = "Condition", var = "SuppressedRecently" } },
	["while you have elusive"] = { tag = { type = "Condition", var = "Elusive" } },
	["while physical aegis is depleted"] = { tag = { type = "Condition", var = "PhysicalAegisDepleted" } },
	["during onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while you have onslaught"] = { tag = { type = "Condition", var = "Onslaught" } },
	["while phasing"] = { tag = { type = "Condition", var = "Phasing" } },
	["while you have tailwind"] = { tag = { type = "Condition", var = "Tailwind" } },
	["while elusive"] = { tag = { type = "Condition", var = "Elusive" } },
	["gain elusive"] = { tag = { type = "Condition", varList = { "CanBeElusive", "Elusive" } } },
	["while you have arcane surge"] = { tag = { type = "Condition", var = "AffectedByArcaneSurge" } },
	["while you have cat's stealth"] = { tag = { type = "Condition", var = "AffectedByCat'sStealth" } },
	["while you have cat's agility"] = { tag = { type = "Condition", var = "AffectedByCat'sAgility" } },
	["while you have avian's might"] = { tag = { type = "Condition", var = "AffectedByAvian'sMight" } },
	["while you have avian's flight"] = { tag = { type = "Condition", var = "AffectedByAvian'sFlight" } },
	["while affected by aspect of the cat"] = { tag = { type = "Condition", varList = { "AffectedByCat'sStealth", "AffectedByCat'sAgility" } } },
	["while affected by a non%-vaal guard skill"] = { tag = { type = "Condition", var =  "AffectedByNonVaalGuardSkill" } },
	["if a non%-vaal guard buff was lost recently"] = { tag = { type = "Condition", var = "LostNonVaalBuffRecently" } },
	["while affected by a guard skill buff"] = { tag = { type = "Condition", var = "AffectedByGuardSkill" } },
	["while affected by a herald"] = { tag = { type = "Condition", var = "AffectedByHerald" } },
	["while fortified"] = { tag = { type = "Condition", var = "Fortified" } },
	["while in blood stance"] = { tag = { type = "Condition", var = "BloodStance" } },
	["while in sand stance"] = { tag = { type = "Condition", var = "SandStance" } },
	["while you have a bestial minion"] = { tag = { type = "Condition", var = "HaveBestialMinion" } },
	["while you have infusion"] = { tag = { type = "Condition", var = "InfusionActive" } },
	["while focus?sed"] = { tag = { type = "Condition", var = "Focused" } },
	["while leeching"] = { tag = { type = "Condition", var = "Leeching" } },
	["while leeching energy shield"] = { tag = { type = "Condition", var = "LeechingEnergyShield" } },
	["while leeching mana"] = { tag = { type = "Condition", var = "LeechingMana" } },
	["while using a flask"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during flask effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["during any flask effect"] = { tag = { type = "Condition", var = "UsingFlask" } },
	["while under no flask effects"] = { tag = { type = "Condition", var = "UsingFlask", neg = true } },
	["during effect of any mana flask"] = { tag = { type = "Condition", var = "UsingManaFlask" } },
	["during effect of any life flask"] = { tag = { type = "Condition", var = "UsingLifeFlask" } },
	["if you've used a life flask in the past 10 seconds"] = { tag = { type = "Condition", var = "UsingLifeFlask" } },
	["if you've used a mana flask in the past 10 seconds"] = { tag = { type = "Condition", var = "UsingManaFlask" } },
	["during effect of any life or mana flask"] = { tag = { type = "Condition", varList = { "UsingManaFlask", "UsingLifeFlask" } } },
	["while on consecrated ground"] = { tag = { type = "Condition", var = "OnConsecratedGround" } },
	["while on caustic ground"] = { tag = { type = "Condition", var = "OnCausticGround" } },
	["when you create consecrated ground"] = { },
	["on burning ground"] = { tag = { type = "Condition", var = "OnBurningGround" } },
	["while on burning ground"] = { tag = { type = "Condition", var = "OnBurningGround" } },
	["on chilled ground"] = { tag = { type = "Condition", var = "OnChilledGround" } },
	["on shocked ground"] = { tag = { type = "Condition", var = "OnShockedGround" } },
	["while in a caustic cloud"] = { tag = { type = "Condition", var = "OnCausticCloud" } },
	["while blinded"] = { tagList = { { type = "Condition", var = "Blinded" }, { type = "Condition", var = "CannotBeBlinded", neg = true } } },
	["while burning"] = { tag = { type = "Condition", var = "Burning" } },
	["while ignited"] = { tag = { type = "Condition", var = "Ignited" } },
	["while you are ignited"] = { tag = { type = "Condition", var = "Ignited" } },
	["while chilled"] = { tag = { type = "Condition", var = "Chilled" } },
	["while you are chilled"] = { tag = { type = "Condition", var = "Chilled" } },
	["while frozen"] = { tag = { type = "Condition", var = "Frozen" } },
	["while shocked"] = { tag = { type = "Condition", var = "Shocked" } },
	["while you are shocked"] = { tag = { type = "Condition", var = "Shocked" } },
	["while you are bleeding"] = { tag = { type = "Condition", var = "Bleeding" } },
	["while not ignited, frozen or shocked"] = { tag = { type = "Condition", varList = { "Ignited", "Frozen", "Shocked" }, neg = true } },
	["while bleeding"] = { tag = { type = "Condition", var = "Bleeding" } },
	["while poisoned"] = { tag = { type = "Condition", var = "Poisoned" } },
	["while you are poisoned"] = { tag = { type = "Condition", var = "Poisoned" } },
	["while cursed"] = { tag = { type = "Condition", var = "Cursed" } },
	["while not cursed"] = { tag = { type = "Condition", var = "Cursed", neg = true } },
	["while there is only one nearby enemy"] = { tagList = { { type = "Multiplier", var = "NearbyEnemies", limit = 1 }, { type = "Condition", var = "OnlyOneNearbyEnemy" } } },
	["while t?h?e?r?e? ?i?s? ?a rare or unique enemy i?s? ?nearby"] = { tag = { type = "ActorCondition", actor = "enemy", varList = { "NearbyRareOrUniqueEnemy", "RareOrUnique" } } },
	["if you[' ]h?a?ve hit recently"] = { tag = { type = "Condition", var = "HitRecently" } },
	["if you[' ]h?a?ve hit an enemy recently"] = { tag = { type = "Condition", var = "HitRecently" } },
	["if you[' ]h?a?ve hit with your main hand weapon recently"] = { tag = { type = "Condition", var = "HitRecentlyWithWeapon" } },
	["if you[' ]h?a?ve hit with your off hand weapon recently"] = { tagList = { { type = "Condition", var = "HitRecentlyWithWeapon" }, { type = "Condition", var = "DualWielding" } } },
	["if you[' ]h?a?ve hit a cursed enemy recently"] = { tagList = { { type = "Condition", var = "HitRecently" }, { type = "ActorCondition", actor = "enemy", var = "Cursed" } } },
	["when you or your totems hit an enemy with a spell"] = { tag = { type = "Condition", varList = { "HitSpellRecently","TotemsHitSpellRecently" } }, },
	["on hit with spells"] = { tag = { type = "Condition", var = "HitSpellRecently" } },
	["if you[' ]h?a?ve crit recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you[' ]h?a?ve dealt a critical strike recently"] = { tag = { type = "Condition", var = "CritRecently" } },
	["when you deal a critical strike"] = { tag = { type = "Condition", var = "CritRecently" } },
	["if you[' ]h?a?ve dealt a critical strike with this weapon recently"] = { tag = { type = "Condition", var = "CritRecently" } }, -- Replica Kongor's
	["if you[' ]h?a?ve crit in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if you[' ]h?a?ve dealt a crit in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if you[' ]h?a?ve dealt a critical strike in the past 8 seconds"] = { tag = { type = "Condition", var = "CritInPast8Sec" } },
	["if you haven't crit recently"] = { tag = { type = "Condition", var = "CritRecently", neg = true } },
	["if you haven't dealt a critical strike recently"] = { tag = { type = "Condition", var = "CritRecently", neg = true } },
	["if you[' ]h?a?ve dealt a non%-critical strike recently"] = { tag = { type = "Condition", var = "NonCritRecently" } },
	["if your skills have dealt a critical strike recently"] = { tag = { type = "Condition", var = "SkillCritRecently" } },
	["if you dealt a critical strike with a herald skill recently"] = { tag = { type = "Condition", var = "CritWithHeraldSkillRecently" } },
	["if you[' ]h?a?ve dealt a critical strike with a two handed melee weapon recently"] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee), tag = { type = "Condition", var = "CritRecently" } },
	["if you[' ]h?a?ve killed recently"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["on killing taunted enemies"] = { tag = { type = "Condition", var = "KilledTauntedEnemyRecently" } },
	["on kill"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["on melee kill"] = { flags = ModFlag.WeaponMelee, tag = { type = "Condition", var = "KilledRecently" } },
	["when you kill an enemy"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["if you[' ]h?a?ve killed an enemy recently"] = { tag = { type = "Condition", var = "KilledRecently" } },
	["if you[' ]h?a?ve killed at least (%d) enemies recently"] = function(num) return { tag = { type = "MultiplierThreshold", var = "EnemyKilledRecently", threshold = num } } end,
	["if you haven't killed recently"] = { tag = { type = "Condition", var = "KilledRecently", neg = true } },
	["if you or your totems have killed recently"] = { tag = { type = "Condition", varList = { "KilledRecently","TotemsKilledRecently" } } },
	["if you[' ]h?a?ve thrown a trap or mine recently"] = { tag = { type = "Condition", var = "TrapOrMineThrownRecently" } },
	["on throwing a trap"] = { tag = { type = "Condition", var = "TrapOrMineThrownRecently" } },
	["if you[' ]h?a?ve killed a maimed enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "ActorCondition", actor = "enemy", var = "Maimed" } } },
	["if you[' ]h?a?ve killed a cursed enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "ActorCondition", actor = "enemy", var = "Cursed" } } },
	["if you[' ]h?a?ve killed a bleeding enemy recently"] = { tagList = { { type = "Condition", var = "KilledRecently" }, { type = "ActorCondition", actor = "enemy", var = "Bleeding" } } },
	["if you[' ]h?a?ve killed an enemy affected by your damage over time recently"] = { tag = { type = "Condition", var = "KilledAffectedByDotRecently" } },
	["if you[' ]h?a?ve frozen an enemy recently"] = { tag = { type = "Condition", var = "FrozenEnemyRecently" } },
	["if you[' ]h?a?ve chilled an enemy recently"] = { tag = { type = "Condition", var = "ChilledEnemyRecently" } },
	["if you[' ]h?a?ve ignited an enemy recently"] = { tag = { type = "Condition", var = "IgnitedEnemyRecently" } },
	["if you[' ]h?a?ve shocked an enemy recently"] = { tag = { type = "Condition", var = "ShockedEnemyRecently" } },
	["if you[' ]h?a?ve stunned an enemy recently"] = { tag = { type = "Condition", var = "StunnedEnemyRecently" } },
	["if you[' ]h?a?ve stunned an enemy with a two handed melee weapon recently"] = { flags = bor(ModFlag.Weapon2H, ModFlag.WeaponMelee), tag = { type = "Condition", var = "StunnedEnemyRecently" } },
	["if you[' ]h?a?ve been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you[' ]h?a?ve been hit by an attack recently"] = { tag = { type = "Condition", var = "BeenHitByAttackRecently" } },
	["if you were hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you were damaged by a hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently" } },
	["if you[' ]h?a?ve taken a critical strike recently"] = { tag = { type = "Condition", var = "BeenCritRecently" } },
	["if you[' ]h?a?ve taken a savage hit recently"] = { tag = { type = "Condition", var = "BeenSavageHitRecently" } },
	["if you have ?n[o']t been hit recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you have ?n[o']t been hit by an attack recently"] = { tag = { type = "Condition", var = "BeenHitByAttackRecently", neg = true } },
	["if you[' ]h?a?ve taken no damage from hits recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you[' ]h?a?ve taken fire damage from a hit recently"] = { tag = { type = "Condition", var = "HitByFireDamageRecently" } },
	["if you[' ]h?a?ve taken fire damage from an enemy hit recently"] = { tag = { type = "Condition", var = "TakenFireDamageFromEnemyHitRecently" } },
	["if you[' ]h?a?ve taken spell damage recently"] = { tag = { type = "Condition", var = "HitBySpellDamageRecently" } },
	["if you haven't taken damage recently"] = { tag = { type = "Condition", var = "BeenHitRecently", neg = true } },
	["if you[' ]h?a?ve blocked recently"] = { tag = { type = "Condition", var = "BlockedRecently" } },
	["if you haven't blocked recently"] = { tag = { type = "Condition", var = "BlockedRecently", neg = true } },
	["if you[' ]h?a?ve blocked an attack recently"] = { tag = { type = "Condition", var = "BlockedAttackRecently" } },
	["if you[' ]h?a?ve blocked attack damage recently"] = { tag = { type = "Condition", var = "BlockedAttackRecently" } },
	["if you[' ]h?a?ve blocked a spell recently"] = { tag = { type = "Condition", var = "BlockedSpellRecently" } },
	["if you[' ]h?a?ve blocked spell damage recently"] = { tag = { type = "Condition", var = "BlockedSpellRecently" } },
	["if you[' ]h?a?ve blocked damage from a unique enemy in the past 10 seconds"] = { tag = { type = "Condition", var = "BlockedHitFromUniqueEnemyInPast10Sec" } },
	["if you[' ]h?a?ve attacked recently"] = { tag = { type = "Condition", var = "AttackedRecently" } },
	["if you[' ]h?a?ve cast a spell recently"] = { tag = { type = "Condition", var = "CastSpellRecently" } },
	["if you[' ]h?a?ve been stunned while casting recently"] = { tag = { type = "Condition", var = "StunnedWhileCastingRecently" } },
	["if you[' ]h?a?ve consumed a corpse recently"] = { tag = { type = "Condition", var = "ConsumedCorpseRecently" } },
	["if you[' ]h?a?ve cursed an enemy recently"] = { tag = { type = "Condition", var = "CursedEnemyRecently" } },
	["if you[' ]h?a?ve cast a mark spell recently"] = { tag = { type = "Condition", var = "CastMarkRecently" } },
	["if you have ?n[o']t consumed a corpse recently"] = { tag = { type = "Condition", var = "ConsumedCorpseRecently", neg = true } },
	["for each corpse consumed recently"] = { tag = { type = "Multiplier", var = "CorpseConsumedRecently" } },
	["if you[' ]h?a?ve taunted an enemy recently"] = { tag = { type = "Condition", var = "TauntedEnemyRecently" } },
	["if you[' ]h?a?ve used a skill recently"] = { tag = { type = "Condition", var = "UsedSkillRecently" } },
	["if you[' ]h?a?ve used a travel skill recently"] = { tag = { type = "Condition", var = "UsedTravelSkillRecently" } },
	["for each skill you've used recently, up to (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "SkillUsedRecently", limit = num, limitTotal = true } } end,
	["for each different non%-instant spell you[' ]h?a?ve cast recently"] = { tag = { type = "Multiplier", var = "NonInstantSpellCastRecently" } },
	["if you[' ]h?a?ve used a warcry recently"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["when you warcry"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["if you[' ]h?a?ve warcried recently"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["for each time you[' ]h?a?ve warcried recently"] = { tag = { type = "Multiplier", var = "WarcryUsedRecently" } },
	["when you warcry"] = { tag = { type = "Condition", var = "UsedWarcryRecently" } },
	["if you[' ]h?a?ve warcried in the past 8 seconds"] = { tag = { type = "Condition", var = "UsedWarcryInPast8Seconds" } },
	["for each second you've been affected by a warcry buff, up to a maximum of (%d+)%%"] = function(num) return { tag = { type = "Multiplier", var = "AffectedByWarcryBuffDuration", limit = num, limitTotal = true } } end,
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
	["when you summon a totem"] = { tag = { type = "Condition", var = "SummonedTotemRecently" } },
	["if you summoned a golem in the past 8 seconds"] = { tag = { type = "Condition", var = "SummonedGolemInPast8Sec" } },
	["if you haven't summoned a totem in the past 2 seconds"] = { tag = { type = "Condition", var = "NoSummonedTotemsInPastTwoSeconds" }  },
	["if you[' ]h?a?ve used a minion skill recently"] = { tag = { type = "Condition", var = "UsedMinionSkillRecently" } },
	["if you[' ]h?a?ve used a movement skill recently"] = { tag = { type = "Condition", var = "UsedMovementSkillRecently" } },
	["if you haven't cast dash recently"] = { tag = { type = "Condition", var = "CastDashRecently", neg = true } },
	["if you[' ]h?a?ve cast dash recently"] = { tag = { type = "Condition", var = "CastDashRecently" } },
	["if you[' ]h?a?ve used a vaal skill recently"] = { tag = { type = "Condition", var = "UsedVaalSkillRecently" } },
	["if you[' ]h?a?ve used a socketed vaal skill recently"] = { tag = { type = "Condition", var = "UsedVaalSkillRecently" } },
	["when you use a vaal skill"] = { tag = { type = "Condition", var = "UsedVaalSkillRecently" } },
	["if you haven't used a brand skill recently"] = { tag = { type = "Condition", var = "UsedBrandRecently", neg = true } },
	["if you[' ]h?a?ve used a brand skill recently"] = { tag = { type = "Condition", var = "UsedBrandRecently" } },
	["if you[' ]h?a?ve spent (%d+) total mana recently"] = function(num) return { tag = { type = "MultiplierThreshold", var = "ManaSpentRecently", threshold = num } } end,
	["if you[' ]h?a?ve spent life recently"] = { tag = { type = "MultiplierThreshold", var = "LifeSpentRecently", threshold = 1 } },
	["for %d+ seconds after spending a total of (%d+) mana"] = function(num) return { tag = { type = "MultiplierThreshold", var = "ManaSpentRecently", threshold = num } } end,
	["if you've impaled an enemy recently"] = { tag = { type = "Condition", var = "ImpaledRecently" } },
	["if you've changed stance recently"] = { tag = { type = "Condition", var = "ChangedStanceRecently" } },
	["if you've gained a power charge recently"] = { tag = { type = "Condition", var = "GainedPowerChargeRecently" } },
	["if you haven't gained a power charge recently"] = { tag = { type = "Condition", var = "GainedPowerChargeRecently", neg = true } },
	["if you haven't gained a frenzy charge recently"] = { tag = { type = "Condition", var = "GainedFrenzyChargeRecently", neg = true } },
	["if you've stopped taking damage over time recently"] = { tag = { type = "Condition", var = "StoppedTakingDamageOverTimeRecently" } },
	["during soul gain prevention"] = { tag = { type = "Condition", var = "SoulGainPrevention" } },
	["if you detonated mines recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["if you detonated a mine recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["if you[' ]h?a?ve detonated a mine recently"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["when your mine is detonated targeting an enemy"] = { tag = { type = "Condition", var = "DetonatedMinesRecently" } },
	["when your trap is triggered by an enemy"] = { tag = { type = "Condition", var = "TriggeredTrapsRecently" } },
	["if energy shield recharge has started recently"] = { tag = { type = "Condition", var = "EnergyShieldRechargeRecently" } },
	["if energy shield recharge has started in the past 2 seconds"] = { tag = { type = "Condition", var = "EnergyShieldRechargePastTwoSec" } },
	["when cast on frostbolt"] = { tag = { type = "Condition", var = "CastOnFrostbolt" } },
	["branded enemy's"] = { tag = { type = "MultiplierThreshold", var = "BrandsAttachedToEnemy", threshold = 1 } },
	["to enemies they're attached to"] = { tag = { type = "MultiplierThreshold", var = "BrandsAttachedToEnemy", threshold = 1 } },
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
	["while you have a summoned golem"] = { tag = { type = "Condition", varList = { "HavePhysicalGolem", "HaveLightningGolem", "HaveColdGolem", "HaveFireGolem", "HaveChaosGolem", "HaveCarrionGolem" } } },
	["if a minion has died recently"] = { tag = { type = "Condition", var = "MinionsDiedRecently" } },
	["if a minion has been killed recently"] = { tag = { type = "Condition", var = "MinionsDiedRecently" } },
	["while you have sacrificial zeal"] = { tag = { type = "Condition", var = "SacrificialZeal" } },
	["while sane"] = { tag = { type = "Condition", var = "Insane", neg = true } },
	["while insane"] = { tag = { type = "Condition", var = "Insane" } },
	["while you have defiance"] = { tag = { type = "MultiplierThreshold", var = "Defiance", threshold = 1 } },
	["while affected by glorious madness"] = { tag = { type = "Condition", var = "AffectedByGloriousMadness" } },
	["if you have reserved life and mana"] = { tagList = {
		{ type = "StatThreshold", stat = "LifeReserved", threshold = 1},
		{ type = "StatThreshold", stat = "ManaReserved", threshold = 1} } },
	["if you've shattered an enemy recently"] = { tag = { type = "Condition", var = "ShatteredEnemyRecently" } },
	-- Enemy status conditions
	["at close range"] = { tag = { type = "Condition", var = "AtCloseRange" } },
	["against rare and unique enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	["by s?l?a?i?n? rare [ao][nr]d? unique enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	["against unique enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } },
	["against enemies on full life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "FullLife" } },
	["against enemies that are on full life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "FullLife" } },
	["against enemies on low life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "LowLife" } },
	["against enemies that are on low life"] = { tag = { type = "ActorCondition", actor = "enemy", var = "LowLife" } },
	["to enemies which have energy shield"] = { tag = { type = "ActorCondition", actor = "enemy", var = "HaveEnergyShield" } },
	["against cursed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" } },
	["against stunned enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Stunned" } },
	["on cursed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" } },
	["of cursed enemies'"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" } },
	["when hitting cursed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" }, keywordFlags = KeywordFlag.Hit },
	["from cursed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Cursed" } },
	["against marked enemy"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Marked" } },
	["when hitting marked enemy"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Marked" }, keywordFlags = KeywordFlag.Hit },
	["from marked enemy"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Marked" } },
	["against taunted enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Taunted" } },
	["against bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" } },
	["you inflict on bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" } },
	["to bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" } },
	["from bleeding enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Bleeding" } },
	["against poisoned enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Poisoned" } },
	["you inflict on poisoned enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Poisoned" } },
	["to poisoned enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Poisoned" } },
	["against enemies affected by (%d+) or more poisons"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "PoisonStack", threshold = num } } end,
	["against enemies affected by at least (%d+) poisons"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "PoisonStack", threshold = num } } end,
	["against hindered enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Hindered" } },
	["against maimed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Maimed" } },
	["you inflict on maimed enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Maimed" } },
	["against blinded enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Blinded" } },
	["from blinded enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Blinded" } },
	["against burning enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Burning" } },
	["against ignited enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Ignited" } },
	["to ignited enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Ignited" } },
	["against shocked enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" } },
	["you inflict on shocked enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" } },
	["to shocked enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" } },
	["inflicted on shocked enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" } },
	["enemies which are shocked"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Shocked" } },
	["against frozen enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Frozen" } },
	["to frozen enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Frozen" } },
	["against chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" } },
	["you inflict on chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" } },
	["to chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" } },
	["inflicted on chilled enemies"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" } },
	["enemies which are chilled"] = { tag = { type = "ActorCondition", actor = "enemy", var = "Chilled" } },
	["against chilled or frozen enemies"] = { tag = { type = "ActorCondition", actor = "enemy", varList = { "Chilled","Frozen" } } },
	["against frozen, shocked or ignited enemies"] = { tag = { type = "ActorCondition", actor = "enemy", varList = { "Frozen","Shocked","Ignited" } } },
	["against enemies affected by elemental ailments"] = { tag = { type = "ActorCondition", actor = "enemy", varList = { "Frozen","Chilled","Shocked","Ignited","Scorched","Brittle","Sapped" } } },
	["against enemies affected by ailments"] = { tag = { type = "ActorCondition", actor = "enemy", varList = { "Frozen","Chilled","Shocked","Ignited","Scorched","Brittle","Sapped","Poisoned","Bleeding" } } },
	["against enemies that are affected by elemental ailments"] = { tag = { type = "ActorCondition", actor = "enemy", varList = { "Frozen","Chilled","Shocked","Ignited","Scorched","Brittle","Sapped" } } },
	["against enemies that are affected by no elemental ailments"] = { tagList = { { type = "ActorCondition", actor = "enemy", varList = { "Frozen","Chilled","Shocked","Ignited","Scorched","Brittle","Sapped" }, neg = true }, { type = "Condition", var = "Effective" } } },
	["against enemies affected by (%d+) spider's webs"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "Spider's WebStack", threshold = num } } end,
	["against enemies on consecrated ground"] = { tag = { type = "ActorCondition", actor = "enemy", var = "OnConsecratedGround" } },
	["if (%d+)%% of curse duration expired"] = function(num) return { tag = { type = "MultiplierThreshold", actor = "enemy", var = "CurseExpired", threshold = num } } end,
	["against enemies with (%w+) exposure"] = function(element) return { tag = { type = "ActorCondition", actor = "enemy", var = "Has"..(firstToUpper(element).."Exposure") } } end,
	-- Enemy multipliers
	["per freeze, shock [ao][nr]d? ignite on enemy"] = { tag = { type = "Multiplier", var = "FreezeShockIgniteOnEnemy" } },
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
for name, grantedEffect in pairs(data.skills) do
	if not grantedEffect.hidden or grantedEffect.fromItem or grantedEffect.fromTree then
		gemIdLookup[grantedEffect.name:lower()] = grantedEffect.id
	end
end
local function grantedExtraSkill(name, level, noSupports)
	name = name:gsub(" skill","")
	if gemIdLookup[name] then
		return {
			mod("ExtraSkill", "LIST", { skillId = gemIdLookup[name], level = tonumber(level), noSupports = noSupports })
		}
	end
end
local function triggerExtraSkill(name, level, options)
	local options = options or {}
	name = name:gsub(" skill","")
	if options.sourceSkill then
		options.sourceSkill = options.sourceSkill:gsub(" skill","")
	end
	local mods = {}
	if gemIdLookup[name] then
		t_insert(mods, mod("ExtraSkill", "LIST", { skillId = gemIdLookup[name], level = tonumber(level), noSupports = options.noSupports, triggered = true, source = options.sourceSkill, triggerChance = tonumber(options.triggerChance) }))
	end
	if options.ignoreHexproof then
		t_insert(mods, mod("SkillData", "LIST", { key = "ignoreHexproof", value = true }, { type = "SkillId", skillId = gemIdLookup[name] }))
	end
	if options.onCrit then
		t_insert(mods, mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "triggerOnCrit", value = true })}, { type = "SkillId", skillId = gemIdLookup[name] }))
	end
	return mods
end
local function extraSupport(name, level, slot)
	local skillId = gemIdLookup[name] or gemIdLookup[name:gsub("^increased ","")] or gemIdLookup[name:gsub(" support$","")]

	if itemSlotName == "main hand" then
		slot = "Weapon 1"
	elseif itemSlotName == "off hand" then
		slot = "Weapon 2"
	elseif slot then
		slot = string.gsub(" "..slot, "%W%l", string.upper):sub(2)
	else
		slot = "{SlotName}"
	end

	level = tonumber(level)
	if skillId then
		local gemId = data.gemForBaseName[(data.skills[skillId].name .. " Support"):lower()]
		if gemId then
			local mods = {mod("ExtraSupport", "LIST", { skillId = data.gems[gemId].grantedEffectId, level = level }, { type = "SocketedIn", slotName = slot })}
			if data.gems[gemId].secondaryGrantedEffect then
				if data.gems[gemId].secondaryGrantedEffect.support then
					t_insert(mods, mod("ExtraSupport", "LIST", { skillId = data.gems[gemId].secondaryGrantedEffectId, level = level }, { type = "SocketedIn", slotName = slot }))
				else
					t_insert(mods, mod("ExtraSkill", "LIST", { skillId = data.gems[gemId].secondaryGrantedEffectId, level = level }))
				end
			end
			return mods
		else
			return {
				mod("ExtraSupport", "LIST", { skillId = skillId, level = level }, { type = "SocketedIn", slotName = slot }),
			}
		end
	end
end

local explodeFunc = function(chance, amount, type, ...)
	local amountNumber = tonumber(amount) or (amount == "tenth" and 10) or (amount == "quarter" and 25)
	if not amountNumber then
		return
	end
	local amounts = {}
	amounts[type] = amountNumber
	return {
		mod("ExplodeMod", "LIST", { type = firstToUpper(type), chance = chance / 100, amount = amountNumber, keyOfScaledMod = "chance" }, ...),
		flag("CanExplode")
	}
end

-- List of special modifiers
local specialModList = {
	-- Explode mods
	["enemies you kill have a (%d+)%% chance to explode, dealing a (.+) of their maximum life as (.+) damage"] = function(chance, _, amount, type)	-- Obliteration, Unspeakable Gifts (chaos cluster), synth implicit mod, current crusader body mod, Ngamahu Warmonger tattoo
		return explodeFunc(chance, amount, type)
	end,
	["enemies you kill have ?a? ?(%d+)%% chance to explode, dealing (%d+)%% of their maximum life as (.+) damage"] = function(chance, _, amount, type) -- Hinekora, Death's Fury 3.22
		return explodeFunc(chance, amount, type)
	end,
	["enemies you or your totems kill have (%d+)%% chance to explode, dealing (%d+)%% of their maximum life as (.+) damage"] = function(chance, _, amount, type) -- Hinekora, Death's Fury 3.23
		return explodeFunc(chance, amount, type)
	end,
	["enemies you kill while using pride have (%d+)%% chance to explode, dealing a (.+) of their maximum life as (.+) damage"] = function(chance, _, amount, type)	-- Sublime Vision
		return explodeFunc(chance, amount, type, { type = "Condition", var = "AffectedByPride" })
	end,
	["enemies you kill during effect have a (%d+)%% chance to explode, dealing a (.+) of their maximum life as damage of a random element"] = function(chance, _, amount)	-- Oriath's End
		return explodeFunc(chance, amount, "randomElement", { type = "Condition", var = "UsingFlask" })
	end,
	["enemies you kill while affected by glorious madness have a (%d+)%% chance to explode, dealing a (.+) of their life as (.+) damage"] = function(chance, _, amount, type)	-- Beacon of Madness
		return explodeFunc(chance, amount, type, { type = "Condition", var = "AffectedByGloriousMadness" })
	end,
	["enemies killed with attack hits have a (%d+)%% chance to explode, dealing a (.+) of their life as (.+) damage"] = explodeFunc,	-- Devastator (attack clusters)
	["enemies killed with wand hits have a (%d+)%% chance to explode, dealing a (.+) of their life as (.+) damage"] = function(chance, _, amount, type)	-- Explosive Force (wand clusters)
		return explodeFunc(chance, amount, type, { type = "Condition", var = "UsingWand" })
	end,
	["cursed enemies you or your minions kill have a (%d+)%% chance to explode, dealing a (.+) of their maximum life as (.+) damage"] = function(chance, _, amount, type)	-- Profane Bloom
		return explodeFunc(chance, amount, type, { type = "ActorCondition", actor = "enemy", var = "Cursed" })
	end,
	["enemies you kill explode, dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- legacy synth, legacy crusader
		return explodeFunc(100, amount, type)
	end,
	["enemies killed explode dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- Quecholli
		return explodeFunc(100, amount, type)
	end,
	["enemies on fungal ground you kill explode, dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- Sporeguard
		return explodeFunc(100, amount, type, { type = "ActorCondition", actor = "enemy", var = "OnFungalGround" })
	end,
	["enemies killed with attack or spell hits explode, dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- Shaper 2H mace mod
		return explodeFunc(100, amount, type)
	end,
	["shocked enemies you kill explode, dealing (%d+)%% of their life as (.+) damage which cannot shock"] = function(amount, _, type)	-- Inpulsa's Broken Heart
		return explodeFunc(100, amount, type, { type = "ActorCondition", actor = "enemy", var = "Shocked" })
	end,
	["bleeding enemies you kill explode, dealing (%d+)%% of their maximum life as (.+) damage"] = function(amount, _, type)	-- Haemophilia
		return explodeFunc(100, amount, type, { type = "ActorCondition", actor = "enemy", var = "Bleeding" })
	end,
	["burning enemies you kill have a (%d+)%% chance to explode, dealing a (.+) of their maximum life as (.+) damage"] = function(amount, _, type)	-- Haemophilia
		return explodeFunc(100, amount, type, { type = "ActorCondition", actor = "enemy", var = "Burning" })
	end,
	["non-aura curses you inflict are not removed from dying enemies"] = {},
	["enemies near corpses affected by your curses are blinded"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Blinded") }, { type = "MultiplierThreshold", var = "NearbyCorpse", threshold = 1 }, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) },
	["enemies killed near corpses affected by your curses explode, dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- Asenath's Gentle Touch
		return explodeFunc(100, amount, type, { type = "MultiplierThreshold", var = "NearbyCorpse", threshold = 1 }, { type = "ActorCondition", actor = "enemy", var = "Cursed" })
	end,
	["enemies taunted by your warcries explode on death, dealing (%d+)%% of their maximum life as (.+) damage"] = function(amount, _, type)	-- Al Dhih
		return explodeFunc(100, amount, type, { type = "ActorCondition", actor = "enemy", var = "Taunted" }, { type = "Condition", var = "UsedWarcryRecently" })
	end,
	["totems explode on death, dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- Crucible weapon mod
		return explodeFunc(100, amount, type)
	end,
	["nearby corpses explode when you warcry, dealing (%d+)%% of their life as (.+) damage"] = function(amount, _, type)	-- Ruthless Berserker node
		return explodeFunc(100, amount, type)
	end,
	-- Keystones
	["(%d+) rage regenerated for every (%d+) mana regeneration per second"] = function(num, _, div) return {
		mod("RageRegen", "BASE", num, {type = "PerStat", stat = "ManaRegen", div = tonumber(div) }) ,
		flag("Condition:CanGainRage"),
	} end,
	["(%w+) recovery from regeneration is not applied"] = function(_, type) return { flag("UnaffectedBy" .. firstToUpper(type) .. "Regen") } end,
	["(%d+)%% less damage taken for every (%d+)%% life recovery per second from leech"] = function(num, _, div)
		return { mod("DamageTaken", "MORE", -num, { type = "PerStat", stat = "MaxLifeLeechRatePercent", div = tonumber(div) }) }
	end,
	["(%d+)%% additional physical damage reduction for every (%d+)%% life recovery per second from leech"] = function(num, _, div)
		return { mod("PhysicalDamageReduction", "BASE", num, { type = "PerStat", stat = "MaxLifeLeechRatePercent", div = tonumber(div) }) }
	end,
	["modifiers to chance to suppress spell damage instead apply to chance to dodge spell hits at 50%% of their value"] = {
		flag("ConvertSpellSuppressionToSpellDodge"),
		mod("SpellSuppressionChance", "OVERRIDE", 0, "Acrobatics"),
	},
	["maximum chance to dodge spell hits is (%d+)%%"] = function(num) return { mod("SpellDodgeChanceMax", "OVERRIDE", num, "Acrobatics") } end,
	["dexterity provides no bonus to evasion rating"] = { flag("NoDexBonusToEvasion") },
	["dexterity provides no inherent bonus to evasion rating"] = { flag("NoDexBonusToEvasion") },
	["strength's damage bonus applies to all spell damage as well"] = { flag("IronWill") },
	["your hits can't be evaded"] = { flag("CannotBeEvaded") },
	["minion hits can't be evaded"] = { mod("MinionModifier", "LIST", { mod = flag("CannotBeEvaded") }) },
	["never deal critical strikes"] = { flag("NeverCrit"), flag("Condition:NeverCrit") },
	["minions never deal critical strikes"] = { mod("MinionModifier", "LIST", { mod = flag("NeverCrit") }), mod("MinionModifier", "LIST", { mod = flag("Condition:NeverCrit") }) },
	["never deal critical strikes with spells"] = { flag("NeverCrit", nil, ModFlag.Spell), flag("Condition:NeverCrit", nil, ModFlag.Spell) },
	["never deal critical strikes with attacks"] = { flag("NeverCrit", nil, ModFlag.Attack), flag("Condition:NeverCrit", nil, ModFlag.Attack) },
	["cannot deal critical strikes"] = { flag("NeverCrit"), flag("Condition:NeverCrit") },
	["cannot deal critical strikes with spells"] = { flag("NeverCrit", nil, ModFlag.Spell), flag("Condition:NeverCrit", nil, ModFlag.Spell) },
	["cannot deal critical strikes with attacks"] = { flag("NeverCrit", nil, ModFlag.Attack), flag("Condition:NeverCrit", nil, ModFlag.Attack) },
	["no critical strike multiplier"] = { flag("NoCritMultiplier") },
	["ailments never count as being from critical strikes"] = { flag("AilmentsAreNeverFromCrit") },
	["the increase to physical damage from strength applies to projectile attacks as well as melee attacks"] = { flag("IronGrip") },
	["strength%'s damage bonus applies to projectile attack damage as well as melee damage"] = { flag("IronGrip") },
	["converts all evasion rating to armour%. dexterity provides no bonus to evasion rating"] = { flag("NoDexBonusToEvasion"), flag("IronReflexes") },
	["30%% chance to dodge attack hits%. 50%% less armour, 30%% less energy shield, 30%% less chance to block spell and attack damage"] = {
		mod("AttackDodgeChance", "BASE", 30),
		mod("Armour", "MORE", -50),
		mod("EnergyShield", "MORE", -30),
		mod("BlockChance", "MORE", -30),
		mod("SpellBlockChance", "MORE", -30),
	},
	["(%d+)%% increased blind effect"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("BlindEffect", "INC", num) }), } end,
	["%+(%d+)%% chance to block spell damage for each (%d+)%% overcapped chance to block attack damage"] = function(num, _, div) return { mod("SpellBlockChance", "BASE", num, { type = "PerStat", stat = "BlockChanceOverCap", div = tonumber(div) }) } end,
	["maximum life becomes 1, immune to chaos damage"] = {
		flag("ChaosInoculation"),
		mod("ChaosDamageTaken", "MORE", -100)
	},
	["life regeneration is applied to energy shield instead"] = { flag("ZealotsOath") },
	["life leeched per second is doubled"] = { mod("LifeLeechRate", "MORE", 100) },
	["total recovery per second from life leech is doubled"] = { mod("LifeLeechRate", "MORE", 100) },
	["maximum total recovery per second from life leech is doubled"] = { mod("MaxLifeLeechRate", "MORE", 100) },
	["maximum total life recovery per second from leech is doubled"] = { mod("MaxLifeLeechRate", "MORE", 100) },
	["maximum total recovery per second from energy shield leech is doubled"] = { mod("MaxEnergyShieldLeechRate", "MORE", 100) },
	["maximum total energy shield recovery per second from leech is doubled"] = { mod("MaxEnergyShieldLeechRate", "MORE", 100) },
	["life regeneration has no effect"] = { flag("NoLifeRegen") },
	["energy shield recharge instead applies to life"] = { flag("EnergyShieldRechargeAppliesToLife") },
	["deal no non%-fire damage"] = { flag("DealNoPhysical"), flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoChaos") },
	["blade vortex and blade blast deal no non%-physical damage"] = {
		flag("DealNoLightning", { type = "SkillName", skillNameList = { "Blade Vortex", "Blade Blast" }, includeTransfigured = true }),
		flag("DealNoCold", { type = "SkillName", skillNameList = { "Blade Vortex", "Blade Blast" }, includeTransfigured = true }),
		flag("DealNoFire", { type = "SkillName", skillNameList = { "Blade Vortex", "Blade Blast" }, includeTransfigured = true }),
		flag("DealNoChaos", { type = "SkillName", skillNameList = { "Blade Vortex", "Blade Blast" }, includeTransfigured = true }) },
	["(%d+)%% of physical, cold and lightning damage converted to fire damage"] = function(num) return {
		mod("PhysicalDamageConvertToFire", "BASE", num),
		mod("LightningDamageConvertToFire", "BASE", num),
		mod("ColdDamageConvertToFire", "BASE", num),
	} end,
	["all elemental damage converted to chaos damage"] = {
		mod("ColdDamageConvertToChaos", "BASE", 100),
		mod("FireDamageConvertToChaos", "BASE", 100),
		mod("LightningDamageConvertToChaos", "BASE", 100),
	},
	["removes all mana%. spend life instead of mana for skills"] = { mod("Mana", "MORE", -100), flag("CostLifeInsteadOfMana") },
	["removes all mana"] = { mod("Mana", "MORE", -100) },
	["removes all energy shield"] = { mod("EnergyShield", "MORE", -100) },
	["skills cost life instead of mana"] = { flag("CostLifeInsteadOfMana") },
	["skills reserve life instead of mana"] = { flag("BloodMagicReserved") },
	["non%-aura skills cost no mana or life while focus?sed"] = {
		mod("ManaCost", "MORE", -100, { type = "Condition", var = "Focused" }, { type = "SkillType", skillType = SkillType.Aura, neg = true }),
		mod("LifeCost", "MORE", -100, { type = "Condition", var = "Focused" }, { type = "SkillType", skillType = SkillType.Aura, neg = true })
	},
	["spend life instead of mana for effects of skills"] = { },
	["skills cost %+(%d+) rage"] = function(num) return { mod("RageCostBase", "BASE", num) } end,
	["non%-aura vaal skills require (%d+)%% reduced souls per use during effect"] = function(num) return { mod("SoulCost", "INC", -num, { type = "Condition", var = "UsingFlask" }, { type = "SkillType", skillType = SkillType.Aura, neg = true }, { type = "SkillType", skillType = SkillType.Vaal }) } end,
	["non%-aura vaal skills require (%d+)%% reduced souls per use"] = function(num) return { mod("SoulCost", "INC", -num, { type = "SkillType", skillType = SkillType.Aura, neg = true }, { type = "SkillType", skillType = SkillType.Vaal }) } end,
	["vaal skills used during effect have (%d+)%% reduced soul gain prevention duration"] = function(num) return { mod("SoulGainPreventionDuration", "INC", -num, { type = "Condition", var = "UsingFlask" }, { type = "SkillType", skillType = SkillType.Vaal }) } end,
	["vaal volcanic fissure and vaal molten strike have (%d+)%% reduced soul gain prevention duration"] = function(num) return { mod("SoulGainPreventionDuration", "INC", -num, { type = "SkillName", skillNameList = { "Volcanic Fissure", "Molten Strike" }, includeTransfigured = true }, { type = "SkillType", skillType = SkillType.Vaal }) } end,
	["vaal attack skills cost rage instead of requiring souls to use"] = { flag("CostRageInsteadOfSouls", nil, ModFlag.Attack, { type = "SkillType", skillType = SkillType.Vaal }) },
	["you cannot gain rage during soul gain prevention"] = { mod("RageRegen", "MORE", -100, { type = "Condition", var = "SoulGainPrevention" }) },
	["hits that deal elemental damage remove exposure to those elements and inflict exposure to other elements exposure inflicted this way applies (%-%d+)%% to resistances"] = function(num) return {
		flag("ElementalEquilibrium"),
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", num, { type = "Condition", varList={ "HitByColdDamage","HitByLightningDamage" } }) }),
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", num, { type = "Condition", varList={ "HitByFireDamage","HitByLightningDamage" } }) }),
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", num, { type = "Condition", varList={ "HitByFireDamage","HitByColdDamage" } }) }),
	} end,
	["enemies you hit with elemental damage temporarily get (%+%d+)%% resistance to those elements and (%-%d+)%% resistance to other elements"] = function(plus, _, minus)
		minus = tonumber(minus)
		return {
			flag("ElementalEquilibrium"),
			flag("ElementalEquilibriumLegacy"),
			mod("EnemyModifier", "LIST", { mod = mod("FireResist", "BASE", plus, { type = "Condition", var = "HitByFireDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("FireResist", "BASE", minus, { type = "Condition", var = "HitByFireDamage", neg = true }, { type = "Condition", varList={ "HitByColdDamage","HitByLightningDamage" } }) }),
			mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", plus, { type = "Condition", var = "HitByColdDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "BASE", minus, { type = "Condition", var = "HitByColdDamage", neg = true }, { type = "Condition", varList={ "HitByFireDamage","HitByLightningDamage" } }) }),
			mod("EnemyModifier", "LIST", { mod = mod("LightningResist", "BASE", plus, { type = "Condition", var = "HitByLightningDamage" }) }),
			mod("EnemyModifier", "LIST", { mod = mod("LightningResist", "BASE", minus, { type = "Condition", var = "HitByLightningDamage", neg = true }, { type = "Condition", varList={ "HitByFireDamage","HitByColdDamage" } }) }),
		}
	end,
	["projectile attack hits deal up to 30%% more damage to targets at the start of their movement, dealing less damage to targets as the projectile travels farther"] = { flag("PointBlank") },
	["leech energy shield instead of life"] = { flag("GhostReaver") },
	["minions explode when reduced to low life, dealing 33%% of their maximum life as fire damage to surrounding enemies"] = { mod("ExtraMinionSkill", "LIST", { skillId = "MinionInstability" }) },
	["minions explode when reduced to low life, dealing 33%% of their life as fire damage to surrounding enemies"] = { mod("ExtraMinionSkill", "LIST", { skillId = "MinionInstability" }) },
	["all bonuses from an equipped shield apply to your minions instead of you"] = { }, -- The node itself is detected by the code that handles it
	["spend energy shield before mana for skill m?a?n?a? ?costs"] = { },
	["you have perfect agony if you've dealt a critical strike recently"] = { mod("Keystone", "LIST", "Perfect Agony", { type = "Condition", var = "CritRecently" }) },
	["energy shield protects mana instead of life"] = { flag("EnergyShieldProtectsMana") },
	["modifiers to critical strike multiplier also apply to damage over time multiplier for ailments from critical strikes at (%d+)%% of their value"] = function(num) return { mod("CritMultiplierAppliesToDegen", "BASE", num) } end,
	["your bleeding does not deal extra damage while the enemy is moving"] = { flag("Condition:NoExtraBleedDamageToMovingEnemy") },
	["you can inflict bleeding on an enemy up to (%d+) times?"] = function(num) return {
		mod("BleedStacksMax", "OVERRIDE", num),
		flag("Condition:HaveCrimsonDance"),
	} end,
	["your minions spread caustic ground on death, dealing 20%% of their maximum life as chaos damage per second"] = { mod("ExtraMinionSkill", "LIST", { skillId = "SiegebreakerCausticGround" }) },
	["your minions spread burning ground on death, dealing 20%% of their maximum life as fire damage per second"] = { mod("ExtraMinionSkill", "LIST", { skillId = "ReplicaSiegebreakerBurningGround" }) },
	["you can have an additional brand attached to an enemy"] = { mod("BrandsAttachedLimit", "BASE", 1) },
	["gain (%d+) grasping vines each second while stationary"] = function(num) return {
		mod("Multiplier:GraspingVinesCount", "BASE", num, { type = "Multiplier", var = "StationarySeconds", limit = 10, limitTotal = true }, { type = "Condition", var = "Stationary" }),
	} end,
	["all damage inflicts poison against enemies affected by at least (%d+) grasping vines"] = function(num) return {
		mod("PoisonChance", "BASE", 100, { type = "MultiplierThreshold", var = "GraspingVinesAffectingEnemy", threshold = num }),
		flag("FireCanPoison", { type = "MultiplierThreshold", var = "GraspingVinesAffectingEnemy", threshold = num }),
		flag("ColdCanPoison", { type = "MultiplierThreshold", var = "GraspingVinesAffectingEnemy", threshold = num }),
		flag("LightningCanPoison", { type = "MultiplierThreshold", var = "GraspingVinesAffectingEnemy", threshold = num }),
	} end,
	["attack projectiles always inflict bleeding and maim, and knock back enemies"] = {
		mod("BleedChance", "BASE", 100, nil, bor(ModFlag.Attack, ModFlag.Projectile)),
		mod("EnemyKnockbackChance", "BASE", 100, nil, bor(ModFlag.Attack, ModFlag.Projectile)),
	},
	["projectiles cannot pierce, fork or chain"] = {
		flag("CannotPierce", nil, ModFlag.Projectile),
		flag("CannotChain", nil, ModFlag.Projectile),
		flag("CannotFork", nil, ModFlag.Projectile),
	},
	["critical strikes inflict scorch, brittle and sapped"] = { flag("CritAlwaysAltAilments") },
	["chance to block attack damage is doubled"] = { mod("BlockChance", "MORE", 100) },
	["chance to block spell damage is doubled"] = { mod("SpellBlockChance", "MORE", 100) },
	["you take (%d+)%% of damage from blocked hits"] = function(num) return { mod("BlockEffect", "BASE", num) } end,
	["ignore attribute requirements"] = { flag("IgnoreAttributeRequirements") },
	["gain no inherent bonuses from attributes"] = { flag("NoAttributeBonuses") },
	["gain no inherent bonuses from strength"] = { flag("NoStrengthAttributeBonuses") },
	["gain no inherent bonuses from dexterity"] = { flag("NoDexterityAttributeBonuses") },
	["gain no inherent bonuses from intelligence"] = { flag("NoIntelligenceAttributeBonuses") },
	["all damage taken bypasses energy shield"] = {
		mod("PhysicalEnergyShieldBypass", "OVERRIDE", 100),
		mod("LightningEnergyShieldBypass", "OVERRIDE", 100),
		mod("ColdEnergyShieldBypass", "OVERRIDE", 100),
		mod("FireEnergyShieldBypass", "OVERRIDE", 100),
		mod("ChaosEnergyShieldBypass", "OVERRIDE", 100), -- Allows override of "chaos damage does not bypass energy shield" and similar mods
	},
	["physical damage taken bypasses energy shield"] = {
		mod("PhysicalEnergyShieldBypass", "BASE", 100),
	},
	["auras from your skills do not affect allies"] = { flag("SelfAuraSkillsCannotAffectAllies") },
	["auras from your skills have (%d+)%% more effect on you"] = function(num) return { mod("SkillAuraEffectOnSelf", "MORE", num) } end,
	["auras from your skills have (%d+)%% increased effect on you"] = function(num) return { mod("SkillAuraEffectOnSelf", "INC", num) } end,
	["increases and reductions to mana regeneration rate instead apply to rage regeneration rate"] = { flag("ManaRegenToRageRegen") },
	["increases and reductions to maximum energy shield instead apply to ward"] = { flag("EnergyShieldToWard") },
	["(%d+)%% of damage taken bypasses ward"] = function(num) return { mod("WardBypass", "BASE", num) } end,
	["maximum energy shield is (%d+)"] = function(num) return { mod("EnergyShield", "OVERRIDE", num ) } end,
	["while not on full life, sacrifice ([%d%.]+)%% of mana per second to recover that much life"] = function(num) return {
		mod("ManaDegenPercent", "BASE", num, { type = "Condition", var = "FullLife", neg = true }),
		mod("LifeRecovery", "BASE", 1, { type = "PercentStat", stat = "Mana", percent = num }, { type = "Condition", var = "FullLife", neg = true })
	} end,
	["(%d+)%% increased maximum energy shield"] = function(num) return { mod("EnergyShield", "INC", num, { type = "Global" }) } end, -- Override as increased maximum is always global
	["you are blind"] = { flag("Condition:Blinded", { type = "Condition", var = "CannotBeBlinded", neg = true }) },
	["armour applies to fire, cold and lightning damage taken from hits instead of physical damage"] = {
		mod("ArmourAppliesToFireDamageTaken", "BASE", 100),
		mod("ArmourAppliesToColdDamageTaken", "BASE", 100),
		mod("ArmourAppliesToLightningDamageTaken", "BASE", 100),
		flag("ArmourDoesNotApplyToPhysicalDamageTaken")
	},
	["(%d+)%% of armour applies to fire, cold and lightning damage taken from hits"] = function(num) return {
		mod("ArmourAppliesToFireDamageTaken", "BASE", num),
		mod("ArmourAppliesToColdDamageTaken", "BASE", num),
		mod("ArmourAppliesToLightningDamageTaken", "BASE", num),
	} end,
	["(%d+)%% of armour also applies to chaos damage taken from hits"] = function(num) return { mod("ArmourAppliesToChaosDamageTaken", "BASE", num) } end,
	["armour also applies to chaos damage taken from hits"] = function(num) return { mod("ArmourAppliesToChaosDamageTaken", "BASE", 100) } end,
	["maximum damage reduction for any damage type is (%d+)%%"] = function(num) return { mod("DamageReductionMax", "OVERRIDE", num) } end,
	["gain additional elemental damage reduction equal to half your chaos resistance"] = {
		mod("FireDamageReduction", "BASE", 1, { type = "PerStat", stat = "ChaosResist", div = 2 }),
		mod("ColdDamageReduction", "BASE", 1, { type = "PerStat", stat = "ChaosResist", div = 2 }),
		mod("LightningDamageReduction", "BASE", 1, { type = "PerStat", stat = "ChaosResist", div = 2 })
	},
	["(%d+)%% of maximum mana is converted to twice that much armour"] = function(num) return {
		mod("ManaConvertToArmour", "BASE", num),
	} end,
	["life recovery from flasks also applies to energy shield"] = { flag("LifeFlaskAppliesToEnergyShield") },
	["non%-instant mana recovery from flasks is also recovered as life"] = { flag("ManaFlaskAppliesToLife") },
	["life leech effects recover energy shield instead while on full life"] = { flag("ImmortalAmbition", { type = "Condition", var = "FullLife" }, { type = "Condition", var = "LeechingLife" }) },
	["shepherd of souls"] = { mod("Damage", "MORE", -30, { type = "SkillType", skillType = SkillType.Vaal, neg = true }) },
	["adds (%d+) to (%d+) attack physical damage to melee skills per (%d+) dexterity while you are unencumbered"] = function(_, min, max, dex) return { -- Hollow Palm 3 suffixes
		mod("PhysicalMin", "BASE", tonumber(min), nil, ModFlag.Melee, KeywordFlag.Attack, { type = "PerStat", stat = "Dex", div = tonumber(dex) }, { type = "Condition", var = "Unencumbered" }),
		mod("PhysicalMax", "BASE", tonumber(max), nil, ModFlag.Melee, KeywordFlag.Attack, { type = "PerStat", stat = "Dex", div = tonumber(dex) }, { type = "Condition", var = "Unencumbered" }),
	} end,
	["(%d+)%% more attack damage if accuracy rating is higher than maximum life"] = function(num) return {
		mod("Damage", "MORE", num, "Damage", ModFlag.Attack, { type = "Condition", var = "MainHandAccRatingHigherThanMaxLife" }, { type = "Condition", var = "MainHandAttack" }),
		mod("Damage", "MORE", num, "Damage", ModFlag.Attack, { type = "Condition", var = "OffHandAccRatingHigherThanMaxLife" }, { type = "Condition", var = "OffHandAttack" }),
	} end,
	["your hexes have infinite duration"] = { mod("Duration", "BASE", m_huge, { type = "SkillType", skillType = SkillType.AppliesCurse }) },
	-- Legacy support
	["(%d+)%% chance to defend with double armour"] = function(numChance) return {
		mod("ArmourDefense", "MAX", 100, "Armour Mastery: Max Calc", { type = "Condition", var = "ArmourMax" }),
		mod("ArmourDefense", "MAX", math.min(numChance / 100, 1.0) * 100, "Armour Mastery: Average Calc", { type = "Condition", var = "ArmourAvg" }),
		mod("ArmourDefense", "MAX", math.min(math.floor(numChance / 100), 1.0) * 100, "Armour Mastery: Min Calc", { type = "Condition", var = "ArmourMax", neg = true }, { type = "Condition", var = "ArmourAvg", neg = true }),
	} end,
	-- Masteries
	["hits have (%d+)%% chance to treat enemy monster elemental resistance values as inverted"] = function(num) return {
		mod("HitsInvertEleResChance", "CHANCE", num / 100, nil)
	} end,
	["off hand accuracy is equal to main hand accuracy while wielding a sword"] = { flag("Condition:OffHandAccuracyIsMainHandAccuracy", { type = "Condition", var = "UsingSword" }) },
	["(%d+)%% increased accuracy rating at close range"] = function(num) return { mod("AccuracyVsEnemy", "INC", num, { type = "Condition", var = "AtCloseRange" } ) } end,
	["(%d+)%% more accuracy rating at close range"] = function(num) return { mod("AccuracyVsEnemy", "MORE", num, { type = "Condition", var = "AtCloseRange" } ) } end,
	["(%d+)%% increased accuracy rating against unique enemies"] = function(num) return { mod("AccuracyVsEnemy", "INC", num, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } ) } end,
	["(%d+)%% more accuracy rating against unique enemies"] = function(num) return { mod("AccuracyVsEnemy", "MORE", num, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" } ) } end,
	["(%d+)%% chance to defend with (%d+)%% of armour"] = function(numChance, _, numArmourMultiplier) return {
		mod("ArmourDefense", "MAX", tonumber(numArmourMultiplier) - 100, "Armour Mastery: Max Calc", { type = "Condition", var = "ArmourMax" }),
		mod("ArmourDefense", "MAX", math.min(numChance / 100, 1.0) * (tonumber(numArmourMultiplier) - 100), "Armour Mastery: Average Calc", { type = "Condition", var = "ArmourAvg" }),
		mod("ArmourDefense", "MAX", math.min(math.floor(numChance / 100), 1.0) * (tonumber(numArmourMultiplier) - 100), "Armour Mastery: Min Calc", { type = "Condition", var = "ArmourMax", neg = true }, { type = "Condition", var = "ArmourAvg", neg = true }),
	} end,
	["defend with (%d+)%% of armour while not on low energy shield"] = function(num) return {
		mod("ArmourDefense", "MAX", num - 100, "Armour and Energy Shield Mastery", { type = "Condition", var = "LowEnergyShield", neg = true }),
	} end,
	["(%d+)%% increased armour and energy shield from equipped body armour if equipped helmet, gloves and boots all have armour and energy shield"] = function(num) return {
		mod("Body ArmourESAndArmour", "INC", num,
			{ type = "StatThreshold", stat = "ArmourOnGloves", threshold = 1},
			{ type = "StatThreshold", stat = "EnergyShieldOnGloves", threshold = 1},
			{ type = "StatThreshold", stat = "ArmourOnHelmet", threshold = 1},
			{ type = "StatThreshold", stat = "EnergyShieldOnHelmet", threshold = 1},
			{ type = "StatThreshold", stat = "ArmourOnBoots", threshold = 1},
			{ type = "StatThreshold", stat = "EnergyShieldOnBoots", threshold = 1}
		)
	} end,
	-- Exerted Attacks
	["exerted attacks deal (%d+)%% increased damage"] = function(num) return { mod("ExertIncrease", "INC", num, nil, ModFlag.Attack, 0) } end,
	["exerted attacks have (%d+)%% chance to deal double damage"] = function(num) return { mod("ExertDoubleDamageChance", "BASE", num, nil, ModFlag.Attack, 0) } end,
	-- Duelist (Fatal flourish)
	["final repeat of attack skills deals (%d+)%% more damage"] = function(num) return { mod("RepeatFinalDamage", "MORE", num, nil, ModFlag.Attack, 0) } end,
	["non%-travel attack skills repeat an additional time"] = { mod("RepeatCount", "BASE", 1, nil, ModFlag.Attack, 0, { type = "Condition", varList = {"averageRepeat", "alwaysFinalRepeat"} }) },
	-- Ascendant
	["grants (%d+) passive skill points?"] = function(num) return { mod("ExtraPoints", "BASE", num) } end,
	["can allocate passives from the %a+'s starting point"] = { },
	["projectiles gain damage as they travel farther, dealing up to (%d+)%% increased damage with hits to targets"] = function(num) return { mod("Damage", "INC", num, nil, bor(ModFlag.Hit, ModFlag.Projectile), { type = "DistanceRamp", ramp = { {35,0},{70,1} } }) } end,
	["(%d+)%% chance to gain elusive on kill"] = {
		flag("Condition:CanBeElusive"),
	},
	["immun[ei]t?y? to elemental ailments while on consecrated ground"] = { flag("ElementalAilmentImmune", { type = "Condition", var = "OnConsecratedGround" }), },
	-- Assassin
	["poison you inflict with critical strikes deals (%d+)%% more damage"] = function(num) return { mod("Damage", "MORE", num, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "CriticalStrike" }) } end,
	["(%d+)%% chance to gain elusive on critical strike"] = {
		flag("Condition:CanBeElusive"),
	},
	["(%d+)%% more damage while there is at most one rare or unique enemy nearby"] = function(num) return { mod("Damage", "MORE", num, nil, 0, { type = "Condition", var = "AtMostOneNearbyRareOrUniqueEnemy" }) } end,
	["(%d+)%% reduced damage taken while there are at least two rare or unique enemies nearby"] = function(num) return { mod("DamageTaken", "INC", -num, nil, 0, { type = "MultiplierThreshold", var = "NearbyRareOrUniqueEnemies", threshold = 2 }) } end,
	["you take no extra damage from critical strikes while elusive"] = { mod("ReduceCritExtraDamage", "BASE", 100, { type = "Condition", var = "Elusive" }) },
	-- Berserker
	["gain %d+ rage when you kill an enemy"] = {
		flag("Condition:CanGainRage"),
	},
	["gain %d+ rage when you use a warcry"] = {
		flag("Condition:CanGainRage"),
	},
	["you and nearby party members gain %d+ rage when you warcry"] = {
		flag("Condition:CanGainRage"),
	},
	["gain %d+ rage on hit with attacks, no more than once every [%d%.]+ seconds"] = {
		flag("Condition:CanGainRage"),
	},
	["while a unique enemy is in your presence, gain %d+ rage on hit with attacks, no more than once every [%d%.]+ seconds"] = {
		flag("Condition:CanGainRage", { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }),
	},
	["while a pinnacle atlas boss is in your presence, gain %d+ rage on hit with attacks, no more than once every [%d%.]+ seconds"] = {
		flag("Condition:CanGainRage", { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }),
	},
	["inherent effects from having rage are tripled"] = { mod("Multiplier:RageEffect", "BASE", 2) },
	["inherent effects from having rage are doubled"] = { mod("Multiplier:RageEffect", "BASE", 1) },
	["cannot be stunned while you have at least (%d+) rage"] = function(num) return { flag("StunImmune", { type = "MultiplierThreshold", var = "Rage", threshold = num }) } end,
	["lose ([%d%.]+)%% of life per second per rage while you are not losing rage"] = function(num) return { mod("LifeDegen", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "Multiplier", var = "Rage" }) } end,
	["if you've warcried recently, you and nearby allies have (%d+)%% increased attack speed"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("Speed", "INC", num, nil, ModFlag.Attack) }, { type = "Condition", var = "UsedWarcryRecently" }) } end,
	["gain (%d+)%% increased armour per (%d+) power for 8 seconds when you warcry, up to a maximum of (%d+)%%"] = function(num, _, div, limit) return {
		mod("Armour", "INC", num, { type = "Multiplier", var = "WarcryPower", div = tonumber(div), globalLimit = tonumber(limit), globalLimitKey = "WarningCall" }, { type = "Condition", var = "UsedWarcryInPast8Seconds" })
	} end,
	["warcries grant (%d+) rage per (%d+) power if you have less than (%d+) rage"] = {
		flag("Condition:CanGainRage"),
	},
	["exerted attacks deal (%d+)%% more attack damage if a warcry sacrificed rage recently"] = function(num) return { mod("ExertAttackIncrease", "MORE", num, nil, ModFlag.Attack, 0) } end,
	["deal (%d+)%% less damage"] = function(num) return { mod("Damage", "MORE", -num) } end,
	-- Champion
	["cannot be stunned while you have fortify"] = { flag("StunImmune", { type = "Condition", var = "Fortified" }) },
	["cannot be stunned while fortified"] = { flag("StunImmune", { type = "Condition", var = "Fortified" }) },
	["you cannot be stunned while at maximum endurance charges"] = { flag("StunImmune", { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }) },
	["fortify"] = { flag("Condition:Fortified") },
	["you have (%d+) fortification"] = function(num) return { mod("MinimumFortification", "BASE", num) } end,
	["enemies taunted by you cannot evade attacks"] = { mod("EnemyModifier", "LIST", { mod = flag("CannotEvade", { type = "Condition", var = "Taunted" }) }) },
	["if you've impaled an enemy recently, you and nearby allies have %+(%d+) to armour"] = function (num) return { mod("ExtraAura", "LIST", { mod = mod("Armour", "BASE", num) }, { type = "Condition", var = "ImpaledRecently" }) } end,
	["your hits permanently intimidate enemies that are on full life"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated", { type = "Condition", var = "ChampionIntimidate" }) }) },
	["you and allies affected by your placed banners regenerate ([%d%.]+)%% of life per second for each stage"] = function(num) return {
		mod("ExtraAura", "LIST", { mod = mod("LifeRegenPercent", "BASE", num, { type = "Condition", var = "AffectedByPlacedBanner" }, { type = "Multiplier", var = "BannerStage" }) })
	} end,
	-- Chieftain
	["enemies near your totems take (%d+)%% increased physical and fire damage"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("PhysicalDamageTaken", "INC", num) }),
		mod("EnemyModifier", "LIST", { mod = mod("FireDamageTaken", "INC", num) }),
	} end,
	["every (%d+) seconds, gain (%d+)%% of physical damage as extra fire damage for (%d+) seconds"] = function(frequency, _, num, duration) return {
		mod("PhysicalDamageGainAsFire", "BASE", tonumber(num), { type = "Condition", var = "NgamahuFlamesAdvance" }),
	} end,
	["(%d+)%% more damage for each endurance charge lost recently, up to (%d+)%%"] = function(num, _, limit) return {
		mod("Damage", "MORE", num, { type = "Multiplier", var = "EnduranceChargesLostRecently", limit = tonumber(limit), limitTotal = true }),
	} end,
	["(%d+)%% more damage if you've lost an endurance charge in the past 8 seconds"] = function(num) return { mod("Damage", "MORE", num, { type = "Condition", var = "LostEnduranceChargeInPast8Sec" })	} end,
	["trigger level (%d+) (.+) when you attack with a non%-vaal slam or strike skill near an enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["non%-unique jewels cause increases and reductions to other damage types in a (%a+) radius to be transformed to apply to (%a+) damage"] = function(_, radius, dmgType) return {
		mod("ExtraJewelFunc", "LIST", {radius = firstToUpper(radius), type = "Other", func = getSimpleConv({ "PhysicalDamage","FireDamage","ColdDamage","LightningDamage","ChaosDamage","ElementalDamage" }, (dmgType:gsub("^%l", string.upper)).."Damage", "INC", true)}, {type = "ItemCondition", itemSlot = "{SlotName}", rarityCond = "UNIQUE", neg = true}),
	} end,
	["non%-unique jewels cause small and notable passive skills in a (%a+) radius to also grant %+(%d+) to (%a+)"] = function(_, radius, val, attr) return {
		mod("ExtraJewelFunc", "LIST", {radius = (radius:gsub("^%l", string.upper)), type = "Other", func = function(node, out, data)
		if node and (node.type == "Notable" or node.type == "Normal") then
			out:NewMod(firstToUpper(attr):match("^%a%l%l"), "BASE", tonumber(val), data.modSource)
		end
	end}, {type = "ItemCondition", itemSlot = "{SlotName}", rarityCond = "UNIQUE", neg = true}),
	} end,
	-- Deadeye
	["projectiles pierce all nearby targets"] = { flag("PierceAllTargets") },
	["gain %+(%d+) life when you hit a bleeding enemy"] = function(num) return { mod("LifeOnHit", "BASE", num, nil, ModFlag.Hit, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }) } end,
	["accuracy rating is doubled"] = { mod("Accuracy", "MORE", 100) },
	["(%d+)%% increased blink arrow and mirror arrow cooldown recovery speed"] = function(num) return {
		mod("CooldownRecovery", "INC", num, { type = "SkillName", skillNameList = { "Blink Arrow", "Mirror Arrow" }, includeTransfigured = true }),
	} end,
	["critical strikes which inflict bleeding also inflict rupture"] = {
		flag("Condition:CanInflictRupture", { type = "Condition", neg = true, var = "NeverCrit" }),
	},
	["gain %d+ gale force when you use a skill"] = {
		flag("Condition:CanGainGaleForce"),
	},
	["if you've used a skill recently, you and nearby allies have tailwind"] = { mod("ExtraAura", "LIST", { mod = flag("Condition:Tailwind") }, { type = "Condition", var = "UsedSkillRecently" }) },
	["you and nearby allies have tailwind"] = { mod("ExtraAura", "LIST", { mod = flag("Condition:Tailwind") }) },
	["projectiles deal (%d+)%% more damage for each remaining chain"] = function(num) return { mod("Damage", "MORE", num, nil, ModFlag.Projectile, { type = "PerStat", stat = "ChainRemaining" }) } end,
	["projectiles deal (%d+)%% increased damage with hits and ailments for each remaining chain"] = function(num) return { mod("Damage", "INC", num, nil, 0, bor(KeywordFlag.Hit, KeywordFlag.Ailment), { type = "PerStat", stat = "ChainRemaining" }, { type = "SkillType", skillType = SkillType.Projectile }) } end,
	["projectiles deal (%d+)%% increased damage for each remaining chain"] = function(num) return { mod("Damage", "INC", num, nil, ModFlag.Projectile, { type = "PerStat", stat = "ChainRemaining" }) } end,
	["far shot"] = { flag("FarShot") },
	["(%d+)%% increased mirage archer duration"] = function(num) return { mod("MirageArcherDuration", "INC", num), } end,
	["([%-%+]%d+) to maximum number of summoned mirage archers"] = function(num) return { mod("MirageArcherMaxCount", "BASE", num),	} end,
	["([%-%+]%d+) to maximum number of sacred wisps"] = function(num) return { mod("SacredWispsMaxCount", "BASE", num),	} end,
	-- Elementalist
	["gain (%d+)%% increased area of effect for %d+ seconds"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", var = "PendulumOfDestructionAreaOfEffect" }) } end,
	["gain (%d+)%% increased elemental damage for %d+ seconds"] = function(num) return { mod("ElementalDamage", "INC", num, { type = "Condition", var = "PendulumOfDestructionElementalDamage" }) } end,
	["for each element you've been hit by damage of recently, (%d+)%% increased damage of that element"] = function(num) return {
		mod("FireDamage", "INC", num, { type = "Condition", var = "HitByFireDamageRecently" }),
		mod("ColdDamage", "INC", num, { type = "Condition", var = "HitByColdDamageRecently" }),
		mod("LightningDamage", "INC", num, { type = "Condition", var = "HitByLightningDamageRecently" }),
	} end,
	["for each element you've been hit by damage of recently, (%d+)%% reduced damage taken of that element"] = function(num) return {
		mod("FireDamageTaken", "INC", -num, { type = "Condition", var = "HitByFireDamageRecently" }),
		mod("ColdDamageTaken", "INC", -num, { type = "Condition", var = "HitByColdDamageRecently" }),
		mod("LightningDamageTaken", "INC", -num, { type = "Condition", var = "HitByLightningDamageRecently" }),
	} end,
	["gain convergence when you hit a unique enemy, no more than once every %d+ seconds"] = {
		flag("Condition:CanGainConvergence"),
	},
	["(%d+)%% increased area of effect while you don't have convergence"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", neg = true, var = "Convergence" }) } end,
	["exposure you inflict applies an extra (%-?%d+)%% to the affected resistance"] = function(num) return { mod("ExtraExposure", "BASE", num) } end,
	["cannot take reflected elemental damage"] = { mod("ElementalReflectedDamageTaken", "MORE", -100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
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
	["you have igniting, chilling and shocking conflux while affected by glorious madness"] = {
		flag("PhysicalCanChill", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("LightningCanChill", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("FireCanChill", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("ChaosCanChill", { type = "Condition", var = "AffectedByGloriousMadness" }),
		mod("EnemyIgniteChance", "BASE", 100, { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("PhysicalCanIgnite", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("LightningCanIgnite", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("ColdCanIgnite", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("ChaosCanIgnite", { type = "Condition", var = "AffectedByGloriousMadness" }),
		mod("EnemyShockChance", "BASE", 100, { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("PhysicalCanShock", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("ColdCanShock", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("FireCanShock", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("ChaosCanShock", { type = "Condition", var = "AffectedByGloriousMadness" }),
	},
	["immun[ei]t?y? to elemental ailments while affected by glorious madness"] = { flag("ElementalAilmentImmune", { type = "Condition", var = "AffectedByGloriousMadness" }), },
	["immun[ei]t?y? to elemental ailments while focus?sed"] = { flag("ElementalAilmentImmune", { type = "Condition", var = "Focused" }), },
	["summoned golems are immune to elemental damage"] = {
		mod("MinionModifier", "LIST", { mod = mod("FireResist", "OVERRIDE", 100) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("FireResistMax", "OVERRIDE", 100) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("ColdResist", "OVERRIDE", 100) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("ColdResistMax", "OVERRIDE", 100) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("LightningResist", "OVERRIDE", 100) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("LightningResistMax", "OVERRIDE", 100) }, { type = "SkillType", skillType = SkillType.Golem }),
	},
	["(%d+)%% increased golem damage per summoned golem"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "SkillType", skillType = SkillType.Golem }, { type = "PerStat", stat = "ActiveGolemLimit" }) } end,
	["shocks from your hits always increase damage taken by at least (%d+)%%"] = function(num) return { mod("ShockMinimum", "BASE", num) } end,
	["chills from your hits always reduce action speed by at least (%d+)%%"] = function(num) return { mod("ChillBase", "BASE", num) } end,
	["(%d+)%% more damage with ignites you inflict with hits for which the highest damage type is fire"] = function(num) return {
		mod("Damage", "MORE", num, nil, 0, KeywordFlag.Ignite, { type = "Condition", var = "FireIsHighestDamageType" }) ,
		flag("ChecksHighestDamage"),
	} end,
	["(%d+)%% more effect of cold ailments you inflict with hits for which the highest damage type is cold"] = function(num) return {
		mod("EnemyChillEffect", "MORE", num, { type = "Condition", var = "ColdIsHighestDamageType" }),
		mod("EnemyBrittleEffect", "MORE", num, { type = "Condition", var = "ColdIsHighestDamageType" }),
		flag("ChecksHighestDamage"),
	} end,
	["(%d+)%% more effect of lightning ailments you inflict with hits if the highest damage type is lightning"] = function(num) return {
		mod("EnemyShockEffect", "MORE", num, { type = "Condition", var = "LightningIsHighestDamageType" }),
		mod("EnemySapEffect", "MORE", num, { type = "Condition", var = "LightningIsHighestDamageType" }),
		flag("ChecksHighestDamage"),
	} end,
	["your chills can reduce action speed by up to a maximum of (%d+)%%"] = function(num) return { mod("ChillMax", "OVERRIDE", num) } end,
	["your hits always ignite"] = { mod("EnemyIgniteChance", "BASE", 100) },
	["hits always ignite"] = { mod("EnemyIgniteChance", "BASE", 100) },
	["your hits always shock"] = { mod("EnemyShockChance", "BASE", 100) },
	["hits always shock"] = { mod("EnemyShockChance", "BASE", 100) },
	["always freeze, shock and ignite"] = {
		mod("EnemyFreezeChance", "BASE", 100),
		mod("EnemyShockChance", "BASE", 100) ,
		mod("EnemyIgniteChance", "BASE", 100),
	},
	["all damage with hits can ignite"] = {
		flag("PhysicalCanIgnite"),
		flag("ColdCanIgnite"),
		flag("LightningCanIgnite"),
		flag("ChaosCanIgnite"),
	},
	["all damage can ignite"] = {
		flag("PhysicalCanIgnite"),
		flag("ColdCanIgnite"),
		flag("LightningCanIgnite"),
		flag("ChaosCanIgnite"),
	},
	["all damage with hits can chill"] = {
		flag("PhysicalCanChill"),
		flag("FireCanChill"),
		flag("LightningCanChill"),
		flag("ChaosCanChill"),
	},
	["all damage with hits can shock"] = {
		flag("PhysicalCanShock"),
		flag("FireCanShock"),
		flag("ColdCanShock"),
		flag("ChaosCanShock"),
	},
	["all damage can shock"] = {
		flag("PhysicalCanShock"),
		flag("FireCanShock"),
		flag("ColdCanShock"),
		flag("ChaosCanShock"),
	},
	["other aegis skills are disabled"] = {
		flag("DisableSkill", { type = "SkillType", skillType = SkillType.Aegis }),
		flag("EnableSkill", { type = "SkillName", skillId = "Primal Aegis" }),
	},
	["primal aegis can take (%d+) elemental damage per allocated notable passive skill"] = function(num) return { mod("ElementalAegisValue", "MAX", num, 0, 0, { type = "Multiplier", var = "AllocatedNotable" }, { type = "GlobalEffect", effectType = "Buff", unscalable = true }) } end,
	-- Gladiator
	["chance to block spell damage is equal to chance to block attack damage"] = { flag("SpellBlockChanceIsBlockChance") },
	["maximum chance to block spell damage is equal to maximum chance to block attack damage"] = { flag("SpellBlockChanceMaxIsBlockChanceMax") },
	["your counterattacks deal double damage"] = { mod("DoubleDamageChance", "BASE", 100, { type = "SkillName", skillNameList = { "Reckoning", "Riposte", "Vengeance" } }) },
	["attack damage is lucky if you[' ]h?a?ve blocked in the past (%d+) seconds"] = {
		flag("LuckyHits", nil, ModFlag.Attack, { type = "Condition", var = "BlockedRecently" })
	},
	["attack damage while dual wielding is lucky if you[' ]h?a?ve blocked in the past (%d+) seconds"] = {
		flag("LuckyHits", nil, ModFlag.Attack, { type = "Condition", var = "BlockedRecently" }, { type = "Condition", var = "DualWielding" })
	},
	["hits ignore enemy monster physical damage reduction if you[' ]h?a?ve blocked in the past (%d+) seconds"] = {
		flag("IgnoreEnemyPhysicalDamageReduction", { type = "Condition", var = "BlockedRecently" })
	},
	["(%d+)%% more attack and movement speed per challenger charge"] = function(num) return {
		mod("Speed", "MORE", num, nil, ModFlag.Attack, 0, { type = "Multiplier", var = "ChallengerCharge" }),
		mod("MovementSpeed", "MORE", num, { type = "Multiplier", var = "ChallengerCharge" }),
	} end,
    -- Guardian
	["grants armour equal to (%d+)%% of your reserved life to you and nearby allies"] = function(num) return { mod("GrantReservedLifeAsAura", "LIST", { mod = mod("Armour", "BASE", num / 100) }) } end,
	["grants armour equal to (%d+)%% of your reserved mana to you and nearby allies"] = function(num) return { mod("GrantReservedManaAsAura", "LIST", { mod = mod("Armour", "BASE", num / 100) }) } end,
	["grants maximum energy shield equal to (%d+)%% of your reserved mana to you and nearby allies"] = function(num) return { mod("GrantReservedManaAsAura", "LIST", { mod = mod("EnergyShield", "BASE", num / 100) }) } end,
	["warcries cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Warcry) },
	["%+(%d+)%% chance to block attack damage for %d seconds? every %d seconds"] = function(num) return { mod("BlockChance", "BASE", num, { type = "Condition", var = "BastionOfHopeActive" }) } end,
	["if you've blocked in the past %d+ seconds, you and nearby allies cannot be stunned"] = { mod("ExtraAura", "LIST", { mod = flag("StunImmune")}, { type = "Condition", var = "BlockedRecently" }, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["if you've attacked recently, you and nearby allies have %+(%d+)%% chance to block attack damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("BlockChance", "BASE", num) }, { type = "Condition", var = "AttackedRecently" }) } end,
	["if you've cast a spell recently, you and nearby allies have %+(%d+)%% chance to block spell damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("SpellBlockChance", "BASE", num) }, { type = "Condition", var = "CastSpellRecently" }) } end,
	["while there is at least one nearby ally, you and nearby allies deal (%d+)%% more damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("Damage", "MORE", num) }, { type = "MultiplierThreshold", var = "NearbyAlly", threshold = 1 }) } end,
	["while there are at least five nearby allies, you and nearby allies have onslaught"] = { mod("ExtraAura", "LIST", { mod = flag("Onslaught") }, { type = "MultiplierThreshold", var = "NearbyAlly", threshold = 5 }) },
	["linked targets and allies in your link beams have %+(%d+)%% to all maximum elemental resistances"] = function(num) return {
		mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("ElementalResistMax", "BASE", num, { type = "Condition", var = "AffectedByLink", neg = true }) }, { type = "MultiplierThreshold", var = "LinkedTargets", threshold = 1 }),
		mod("ExtraLinkEffect", "LIST", { mod = mod("ElementalResistMax", "BASE", num, { type = "GlobalEffect", effectType = "Global", unscalable = true }) }),
	} end,
	["enemies in your link beams cannot apply elemental ailments"] = { flag("ElementalAilmentImmune", { type = "ActorCondition", actor = "enemy", var = "BetweenYouAndLinkedTarget" }), },
	["(%d+)%% of damage from hits is taken from your sentinel of radiance's life before you"] = function(num) return { mod("takenFromRadianceSentinelBeforeYou", "BASE", num) } end,
	-- Hierophant
	["you and your totems regenerate ([%d%.]+)%% of life per second for each summoned totem"] = function (num) return {
		mod("LifeRegenPercent", "BASE", num, { type = "PerStat", stat = "TotemsSummoned" }),
		mod("LifeRegenPercent", "BASE", num, { type = "PerStat", stat = "TotemsSummoned" }, 0, KeywordFlag.Totem),
	} end,
	["enemies take (%d+)%% increased damage for each of your brands attached to them"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Multiplier", var = "BrandsAttached" }) }) } end,
	["non%-damaging ailments have (%d+)%% reduced effect on you while you have arcane surge"] = function(num)
		local mods = { }
		for i, ailment in ipairs(data.nonDamagingAilmentTypeList) do
			mods[i] = mod("Self"..ailment.."Effect", "INC", -num, { type = "Condition", var = "AffectedByArcaneSurge" })
		end
		return mods
	end,
	["immun[ei]t?y? to elemental ailments while you have arcane surge"] = { flag("ElementalAilmentImmune", { type = "Condition", var = "AffectedByArcaneSurge" }), },
	["brands have (%d+)%% more activation frequency if (%d+)%% of attached duration expired"] = function(num) return { mod("BrandActivationFrequency", "MORE", num, { type = "Condition", var = "BrandLastQuarter" }) } end,
	["arcane surge grants (%d+)%% more spell damage to you"] = function(num) return { mod("ArcaneSurgeDamage", "MAX", num) } end,
	-- Inquisitor
	["critical strikes ignore enemy monster elemental resistances"] = { flag("IgnoreElementalResistances", { type = "Condition", var = "CriticalStrike" }) },
	["non%-critical strikes penetrate (%d+)%% of enemy elemental resistances"] = function(num) return { mod("ElementalPenetration", "BASE", num, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	["consecrated ground you create applies (%d+)%% increased damage taken to enemies"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTakenConsecratedGround", "INC", num, { type = "Condition", var = "OnConsecratedGround" }) }) } end,
	["you have consecrated ground around you while stationary"] = { flag("Condition:OnConsecratedGround", { type = "Condition", var = "Stationary" }) },
	["consecrated ground you create grants immun[ei]t?y? to elemental ailments to you and allies"] = { mod("ExtraAura", "LIST", { mod = flag("ElementalAilmentImmune", { type = "Condition", var = "OnConsecratedGround" }) }), },
	["gain fanaticism for 4 seconds on reaching maximum fanatic charges"] = {
		flag("Condition:CanGainFanaticism"),
	},
	["(%d+)%% increased critical strike chance per point of strength or intelligence, whichever is lower"] = function(num) return {
		mod("CritChance", "INC", num, { type = "PerStat", stat = "Str" }, { type = "Condition", var = "IntHigherThanStr" }),
		mod("CritChance", "INC", num, { type = "PerStat", stat = "Int" }, { type = "Condition", neg = true, var = "IntHigherThanStr" })
	} end,
	["consecrated ground you create causes life regeneration to also recover energy shield for you and allies"] = { mod("ExtraAura", "LIST", { mod = flag("LifeRegenerationRecoversEnergyShield", { type = "Condition", var = "OnConsecratedGround" }) }), },
	["(%d+)%% more attack damage for each non%-instant spell you've cast in the past 8 seconds, up to a maximum of (%d+)%%"] = function(num, _, max) return {
		mod("Damage", "MORE", num, nil, ModFlag.Attack, { type = "Multiplier", var = "CastLast8Seconds", limit = max, limitTotal = true }),
	} end,
	-- Juggernaut
	["armour received from body armour is doubled"] = { flag("Unbreakable") },
	["armour from equipped body armour is doubled"] = { flag("Unbreakable") },
	["action speed cannot be modified to below base value"] = { mod("MinimumActionSpeed", "MAX", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["movement speed cannot be modified to below base value"] = { flag("MovementSpeedCannotBeBelowBase") },
	["you cannot be slowed to below base speed"] = { mod("MinimumActionSpeed", "MAX", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["cannot be slowed to below base speed"] = { mod("MinimumActionSpeed", "MAX", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["gain accuracy rating equal to your strength"] = { mod("Accuracy", "BASE", 1, { type = "PerStat", stat = "Str" }) },
	["gain accuracy rating equal to twice your strength"] = { mod("Accuracy", "BASE", 2, { type = "PerStat", stat = "Str" }) },
	-- Necromancer
	["your offering skills also affect you"] = { mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "buffNotPlayer", value = false }) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } }) },
	["your offerings have (%d+)%% reduced effect on you"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("BuffEffectOnPlayer", "INC", -num) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } }) } end,
	["your offerings have (%d+)%% increased effect on you"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("BuffEffectOnPlayer", "INC", num) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } }) } end,
	["if you've consumed a corpse recently, you and your minions have (%d+)%% increased area of effect"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", var = "ConsumedCorpseRecently" }), mod("MinionModifier", "LIST", { mod = mod("AreaOfEffect", "INC", num) }, { type = "Condition", var = "ConsumedCorpseRecently" }) } end,
	["with at least one nearby corpse, you and nearby allies deal (%d+)%% more damage"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("Damage", "MORE", num) }, { type = "MultiplierThreshold", var = "NearbyCorpse", threshold = 1 }) } end,
	["with at least one nearby corpse, nearby enemies deal (%d+)%% reduced damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("Damage", "INC", -num) }, { type = "MultiplierThreshold", var = "NearbyCorpse", threshold = 1 }) } end,
	["for each nearby corpse, you and nearby allies regenerate ([%d%.]+)%% of energy shield per second, up to ([%d%.]+)%% per second"] = function(num, _, limit) return { mod("ExtraAura", "LIST", { mod = mod("EnergyShieldRegenPercent", "BASE", num) }, { type = "Multiplier", var = "NearbyCorpse", limit = tonumber(limit), limitTotal = true }) } end,
	["for each nearby corpse, you and nearby allies regenerate (%d+) mana per second, up to (%d+) per second"] = function(num, _, limit) return { mod("ExtraAura", "LIST", { mod = mod("ManaRegen", "BASE", num) }, { type = "Multiplier", var = "NearbyCorpse", limit = tonumber(limit), limitTotal = true }) } end,
	["(%d+)%% increased attack and cast speed for each corpse consumed recently, up to a maximum of (%d+)%%"] = function(num, _, limit) return { mod("Speed", "INC", num, { type = "Multiplier", var = "CorpseConsumedRecently", limit = tonumber(limit / num) }) } end,
	["enemies near corpses you spawned recently are chilled and shocked"] = {
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Chilled") }, { type = "Condition", var = "SpawnedCorpseRecently" }),
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Shocked") }, { type = "Condition", var = "SpawnedCorpseRecently" }),
		mod("ChillBase", "BASE", data.nonDamagingAilment["Chill"].default, { type = "Condition", var = "SpawnedCorpseRecently" }),
		mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "Condition", var = "SpawnedCorpseRecently" }),
	},
	["regenerate (%d+)%% of energy shield over 2 seconds when you consume a corpse"] = function(num) return { mod("EnergyShieldRegenPercent", "BASE", num / 2, { type = "Condition", var = "ConsumedCorpseInPast2Sec" }) } end,
	["regenerate (%d+)%% of mana over 2 seconds when you consume a corpse"] = function(num) return { mod("ManaRegen", "BASE", 1, { type = "PercentStat", stat = "Mana", percent = num / 2 }, { type = "Condition", var = "ConsumedCorpseInPast2Sec" }) } end,
	["corpses you spawn have (%d+)%% increased maximum life"] = function(num) return { mod("CorpseLife", "INC", num) } end,
	["corpses you spawn have (%d+)%% reduced maximum life"] = function(num) return { mod("CorpseLife", "INC", -num) } end,
	["minions gain added physical damage equal to (%d+)%% of maximum energy shield on your equipped helmet"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("PhysicalMin", "BASE", 1, { type = "PercentStat", stat = "EnergyShieldOnHelmet", actor = "parent", percent = num }) }),
		mod("MinionModifier", "LIST", { mod = mod("PhysicalMax", "BASE", 1, { type = "PercentStat", stat = "EnergyShieldOnHelmet", actor = "parent", percent = num }) }),

	} end,
	-- Occultist
	["when you kill an enemy, for each curse on that enemy, gain (%d+)%% of non%-chaos damage as extra chaos damage for 4 seconds"] = function(num) return {
		mod("NonChaosDamageGainAsChaos", "BASE", num, { type = "Condition", var = "KilledRecently" }, { type = "Multiplier", var = "CurseOnEnemy" }),
	} end,
	["cannot be stunned while you have energy shield"] = { flag("StunImmune", { type = "Condition", var = "HaveEnergyShield" }) },
	["every second, inflict withered on nearby enemies for (%d+) seconds"] = { flag("Condition:CanWither") },
	["nearby hindered enemies deal (%d+)%% reduced damage over time"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageOverTime", "INC", -num) }, { type = "ActorCondition", actor = "enemy", var = "Hindered" }) } end,
	["nearby chilled enemies deal (%d+)%% reduced damage with hits"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("Damage", "INC", -num) }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) } end,
	-- Pathfinder
	["always poison on hit while using a flask"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["poisons you inflict during any flask effect have (%d+)%% chance to deal (%d+)%% more damage"] = function(num, _, more) return { mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "UsingFlask" }) } end,
	["immun[ei]t?y? to elemental ailments during any flask effect"] = { flag("ElementalAilmentImmune", { type = "Condition", var = "UsingFlask" }), },
	["grant bonuses to non%-channelling skills you use by consuming (%d+) charges from a flask of each of the following types, if possible:"] = { },
	["if diamond flask charges are consumed, (%d+)%% increased critical strike chance"] = function (num) return {
		mod("CritChance", "INC", num, { type = "SkillType", skillType = SkillType.Triggered, neg = true }, { type = "SkillType", skillType = SkillType.Channel, neg = true }, { type = "Condition", var = "UsingDiamondFlask" })
	} end,
	["if bismuth flask charges are consumed, penetrate (%d+)%% elemental resistances"] = function (num) return {
		mod("ElementalPenetration", "BASE", num, { type = "SkillType", skillType = SkillType.Triggered, neg = true }, { type = "SkillType", skillType = SkillType.Channel, neg = true }, { type = "Condition", var = "UsingBismuthFlask" })
	} end,
	["if amethyst flask charges are consumed, (%d+)%% of physical damage as extra chaos damage"] = function (num) return {
		mod("PhysicalDamageGainAsChaos", "BASE", num, { type = "SkillType", skillType = SkillType.Triggered, neg = true }, { type = "SkillType", skillType = SkillType.Channel, neg = true }, { type = "Condition", var = "UsingAmethystFlask" })
	} end,
	-- Raider
	["nearby enemies have (%d+)%% less accuracy rating while you have phasing"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("Accuracy", "MORE", -num) }, { type = "Condition", var = "Phasing" }) } end,
	["immun[ei]t?y? to elemental ailments while phasing"] = { flag("ElementalAilmentImmune", { type = "Condition", var = "Phasing" }), },
	["nearby enemies have fire, cold and lightning exposure while you have phasing, applying %-(%d+)%% to those resistances"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -num) }, { type = "Condition", var = "Phasing" }),
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -num) }, { type = "Condition", var = "Phasing" }),
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -num) }, { type = "Condition", var = "Phasing" }),
	} end,
	["nearby enemies have fire, cold and lightning exposure while you have phasing"] = {
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -10) }, { type = "Condition", var = "Phasing" }),
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -10) }, { type = "Condition", var = "Phasing" }),
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -10) }, { type = "Condition", var = "Phasing" }),
	},
	-- Saboteur
	["hits have (%d+)%% chance to deal (%d+)%% more area damage"] = function (num, _, more) return {
		mod("Damage", "MORE", (num*more/100), nil, bor(ModFlag.Area, ModFlag.Hit))
	} end,
	["immun[ei]t?y? to ignite and shock"] = {
		flag("IgniteImmune"),
		flag("ShockImmune"),
	},
	["you gain (%d+)%% increased damage for each trap"] = function(num) return { mod("Damage", "INC", num, { type = "PerStat", stat = "ActiveTrapLimit" }) } end,
	["you gain (%d+)%% increased area of effect for each mine"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "PerStat", stat = "ActiveMineLimit" }) } end,
	["triggers level (%d+) summon triggerbots when allocated"] = { flag("HaveTriggerBots") },
	-- Slayer
	["deal up to (%d+)%% more melee damage to enemies, based on proximity"] = function(num) return { mod("Damage", "MORE", num, nil, bor(ModFlag.Attack, ModFlag.Melee), { type = "MeleeProximity", ramp = {1,0} }) } end,
	["cannot be stunned while leeching"] = { flag("StunImmune", { type = "Condition", var = "Leeching" }), },
	["you are immune to bleeding while leeching"] = { flag("BleedImmune", { type = "Condition", var = "Leeching" }), },
	["life leech effects are not removed at full life"] = { flag("CanLeechLifeOnFullLife") },
	["life leech effects are not removed when unreserved life is filled"] = { flag("CanLeechLifeOnFullLife") },
	["energy shield leech effects from attacks are not removed at full energy shield"] = { flag("CanLeechEnergyShieldOnFullEnergyShield") },
	["cannot take reflected physical damage"] = { mod("PhysicalReflectedDamageTaken", "MORE", -100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["gain (%d+)%% increased movement speed for 20 seconds when you kill an enemy"] = function(num) return { mod("MovementSpeed", "INC", num, { type = "Condition", var = "KilledRecently" }) } end,
	["gain (%d+)%% increased attack speed for 20 seconds when you kill a rare or unique enemy"] = function(num) return { mod("Speed", "INC", num, nil, ModFlag.Attack, 0, { type = "Condition", var = "KilledUniqueEnemy" }) } end,
	["kill enemies that have (%d+)%% or lower life when hit by your skills"] = function(num) return { mod("CullPercent", "MAX", num) } end,
	["you are unaffected by bleeding while leeching"] = { mod("SelfBleedEffect", "MORE", -100, { type = "Condition", var = "Leeching" }) },
	-- Trickster
	["(%d+)%% chance to gain (%d+)%% of non%-chaos damage with hits as extra chaos damage"] = function(num, _, perc) return { mod("NonChaosDamageGainAsChaos", "BASE", num / 100 * tonumber(perc)) } end,
	["movement skills cost no mana"] = { mod("ManaCost", "MORE", -100, nil, 0, KeywordFlag.Movement) },
	["cannot be stunned while you have ghost shrouds"] = function(num) return { flag("StunImmune", { type = "MultiplierThreshold", var = "GhostShroud", threshold = 1 }), } end,
	["your action speed is at least (%d+)%% of base value"] = function(num) return { mod("MinimumActionSpeed", "MAX", num) } end,
	["nearby enemy monsters' action speed is at most (%d+)%% of base value"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("MaximumActionSpeedReduction", "MAX", 100 - num) }) } end,
	["prevent %+(%d+)%% of suppressed spell damage while on full energy shield"] = function(num) return { mod("SpellSuppressionEffect", "BASE", num, { type = "Condition", var = "FullEnergyShield" }) } end,
	["energy shield leech effects are not removed when energy shield is filled"] = { flag("CanLeechEnergyShieldOnFullEnergyShield") },
	["take (%d+)%% less damage from hits for (%d+) seconds"] = function(num, _, duration) return {
		mod("DamageTakenWhenHit", "MORE", -num, { type = "Condition", var = "HeartstopperHIT" }),
		mod("DamageTakenWhenHit", "MORE", -num * tonumber(duration) / 10, { type = "Condition", var = "HeartstopperAVERAGE" })
	} end,
	["take (%d+)%% less damage over time for (%d+) seconds"] = function(num, _, duration) return {
		mod("DamageTakenOverTime", "MORE", -num, { type = "Condition", var = "HeartstopperDOT" }),
		mod("DamageTakenOverTime", "MORE", -num * tonumber(duration) / 10, { type = "Condition", var = "HeartstopperAVERAGE" })
	} end,
	-- Warden
	["defences from equipped body armour are doubled if it has no socketed gems"] = { flag("DoubleBodyArmourDefence", { type = "MultiplierThreshold", var = "SocketedGemsInBody Armour", threshold = 0, upper = true }, { type = "Condition", var = "UsingBody Armour" }) },
	["([%+%-]%d+)%% to all elemental resistances if you have an equipped helmet with no socketed gems"] = function(num) return { mod("ElementalResist", "BASE", num, { type = "MultiplierThreshold", var = "SocketedGemsInHelmet", threshold = 0, upper = true}, { type = "Condition", var = "UsingHelmet" }) } end,
	["(%d+)%% increased maximum life if you have equipped gloves with no socketed gems"] = function(num) return { mod("Life", "INC", num, { type = "MultiplierThreshold", var = "SocketedGemsInGloves", threshold = 0, upper = true}, { type = "Condition", var = "UsingGloves" }) } end,
	["(%d+)%% increased movement speed if you have equipped boots with no socketed gems"] = function(num) return { mod("MovementSpeed", "INC", num, { type = "MultiplierThreshold", var = "SocketedGemsInBoots", threshold = 0, upper = true}, { type = "Condition", var = "UsingBoots" }) } end,
	-- Warlock
	["spells you cast yourself gain added physical damage equal to (%d+)%% of life cost, if life cost is not higher than the maximum you could spend"] = function(num) return {
		mod("PhysicalMin", "BASE", 1, { type = "PercentStat", stat = "LifeCost", percent = num }, { type = "StatThreshold", stat = "LifeUnreserved", thresholdStat = "LifeCost", thresholdPercent = num }),
		mod("PhysicalMax", "BASE", 1, { type = "PercentStat", stat = "LifeCost", percent = num }, { type = "StatThreshold", stat = "LifeUnreserved", thresholdStat = "LifeCost", thresholdPercent = num }),
	} end,
	["gain maximum life instead of maximum energy shield from equipped armour items"] = { flag("ConvertArmourESToLife") },
	-- Item local modifiers
	["has no sockets"] = { flag("NoSockets") },
	["reflects your other ring"] = {
		-- Display only. For Kalandra's Touch.
	},
	["has (%d+) sockets?"] = function(num) return { mod("SocketCount", "BASE", num) } end,
	["has (%d+) abyssal sockets?"] = function(num) return { mod("AbyssalSocketCount", "BASE", num) } end,
	["no physical damage"] = { mod("WeaponData", "LIST", { key = "PhysicalMin" }), mod("WeaponData", "LIST", { key = "PhysicalMax" }), mod("WeaponData", "LIST", { key = "PhysicalDPS" }) },
	["all attacks with this weapon are critical strikes"] = { mod("WeaponData", "LIST", { key = "CritChance", value = 100 }) },
	["this weapon's critical strike chance is (%d+)%%"] = function(num) return { mod("WeaponData", "LIST", { key = "CritChance", value = num }) } end,
	["counts as dual wielding"] = { mod("WeaponData", "LIST", { key = "countsAsDualWielding", value = true }) },
	["counts as all one handed melee weapon types"] = { mod("WeaponData", "LIST", { key = "countsAsAll1H", value = true }) },
	["no block chance"] = { mod("ArmourData", "LIST", { key = "BlockChance", value = 0 }) },
	["no chance to block"] = { mod("ArmourData", "LIST", { key = "BlockChance", value = 0 }) },
	["has no energy shield"] = { mod("ArmourData", "LIST", { key = "EnergyShield", value = 0 }) },
	["hits can't be evaded"] = { flag("CannotBeEvaded", { type = "Condition", var = "{Hand}Attack" }) },
	["causes bleeding on hit"] = { mod("BleedChance", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }) },
	["poisonous hit"] = { mod("PoisonChance", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }) },
	["attacks with this weapon deal double damage"] = { mod("DoubleDamageChance", "BASE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }) },
	["hits with this weapon gain (%d+)%% of physical damage as extra cold or lightning damage"] = function(num) return {
		mod("PhysicalDamageGainAsColdOrLightning", "BASE", num / 2, nil, ModFlag.Hit, { type = "Condition", var = "DualWielding" }, { type = "SkillType", skillType = SkillType.Attack }),
		mod("PhysicalDamageGainAsColdOrLightning", "BASE", num, nil, ModFlag.Hit, { type = "Condition", var = "DualWielding", neg = true}, { type = "SkillType", skillType = SkillType.Attack })
	} end,
	["hits with this weapon shock enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("ShockAsThoughDealing", "MORE", num, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }) } end,
	["hits with this weapon freeze enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("FreezeAsThoughDealing", "MORE", num, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }) } end,
	["ignites inflicted with this weapon deal (%d+)%% more damage"] = function(num) return {
		mod("Damage", "MORE", num, nil, 0, KeywordFlag.Ignite, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	} end,
	["hits with this weapon always ignite, freeze, and shock"] = {
		mod("EnemyIgniteChance", "BASE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
		mod("EnemyFreezeChance", "BASE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
		mod("EnemyShockChance", "BASE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	},
	["attacks with this weapon deal double damage to chilled enemies"] = { mod("DoubleDamageChance", "BASE", 100, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) },
	["life leech from hits with this weapon applies instantly"] = { mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }) },
	["life leech from hits with this weapon is instant"] = { mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }) },
	["gain life from leech instantly from hits with this weapon"] = { mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }) },
	["(%d+)%% of leech from hits with this weapon is instant per enemy power"] = function(num) return { mod("InstantLifeLeech", "BASE", num, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }, { type = "Multiplier", var = "EnemyPower"}) } end,
	["instant recovery"] = {  mod("FlaskInstantRecovery", "BASE", 100) },
	["life flasks used while on low life apply recovery instantly"] = { mod("LifeFlaskInstantRecovery", "BASE", 100, { type = "Condition", var = "LowMana" }) },
	["mana flasks used while on low mana apply recovery instantly"] = { mod("ManaFlaskInstantRecovery", "BASE", 100, { type = "Condition", var = "LowMana" }) },
	["(%d+)%% of recovery applied instantly"] = function(num) return { mod("FlaskInstantRecovery", "BASE", num) } end,
	["has no attribute requirements"] = { flag("NoAttributeRequirements") },
	["trigger a socketed spell when you attack with this weapon"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed spell when you attack with this weapon, with a ([%d%.]+) second cooldown"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed spell when you use a skill"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnSkillUse", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed spell when you use a skill, with a (%d+) second cooldown"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnSkillUse", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed spell when you use a skill, with a (%d+) second cooldown and (%d+)%% more cost"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnSkillUse", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger socketed spells when you focus"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellFromHelmet", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger socketed spells when you focus, with a ([%d%.]+) second cooldown"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellFromHelmet", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed spell when you attack with a bow"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnBowAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed spell when you attack with a bow, with a ([%d%.]+) second cooldown"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerSpellOnBowAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed bow skill when you attack with a bow"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerBowSkillOnBowAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed bow skill when you attack with a bow, with a ([%d%.]+) second cooldown"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerBowSkillOnBowAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed bow skill when you cast a spell while wielding a bow"] = { mod("ExtraSupport", "LIST", { skillId = "SupportTriggerBowSkillOnBowAttack", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["(%d+)%% chance to [c?t?][a?r?][s?i?][t?g?]g?e?r? socketed spells when you spend at least (%d+) mana to use a skill"] = function(num, _, amount) return {
		mod("KitavaTriggerChance", "BASE", num, "Kitava's Thirst"),
		mod("KitavaRequiredManaCost", "BASE", tonumber(amount), "Kitava's Thirst"),
		mod("ExtraSupport", "LIST", { skillId = "SupportCastOnManaSpent", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }),
	} end,
	["(%d+)%% chance to [c?t?][a?r?][s?i?][t?g?]g?e?r? socketed spells when you spend at least (%d+) mana on an upfront cost to use or trigger a skill, with a ([%d%.]+) second cooldown"] = function(num, _, amount, _) return {
		mod("KitavaTriggerChance", "BASE", num, "Kitava's Thirst"),
		mod("KitavaRequiredManaCost", "BASE", tonumber(amount), "Kitava's Thirst"),
		mod("ExtraSupport", "LIST", { skillId = "SupportCastOnManaSpent", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }),
	} end,
	-- Socketed gem modifiers
	["([%+%-]%d+) to level of socketed gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "all", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["([%+%-]%d+)%%? to (%a+) of socketed ?([%a%- ]*) gems"] = function(num, _, property, type)
		if type == "" then type = "all" end
		return { mod("GemProperty", "LIST", { keyword = type, key = property, value = num }, { type = "SocketedIn", slotName = "{SlotName}" }) }
	end,
	["([%+%-]%d+) to level of socketed skill gems per socketed gem"] = function(num) return { mod("GemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "Multiplier", var="SocketedGemsIn{SlotName}"}) } end,
	["([%+%-]%d+)%% to quality of all skill gems"] = function(num) return { mod("GemProperty", "LIST", { keyword = "grants_active_skill", key = "quality", value = num }) } end,
	["([%+%-]%d+) to level of socketed active skill gems per (%d+) player levels"] = function(num, _, div) return { mod("GemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "Multiplier", var = "Level", div = tonumber(div) }) } end,
	["([%+%-]%d+) to level of socketed skill gems per (%d+) player levels"] = function(num, _, div) return { mod("GemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "Multiplier", var = "Level", div = tonumber(div) }) } end,
	["socketed gems fire an additional projectile"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", 1) }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems fire (%d+) additional projectiles"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed gems reserve no mana"] = { mod("ManaReserved", "MORE", -100, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems have no reservation"] = { mod("Reserved", "MORE", -100, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed skill gems get a (%d+)%% mana multiplier"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("SupportManaMultiplier", "MORE", num - 100) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed skill gems get a (%d+)%% cost & reservation multiplier"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("SupportManaMultiplier", "MORE", num - 100) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed gems have blood magic"] = { mod("ExtraSupport", "LIST", { skillId = "SupportBloodMagicUniquePrismGuardian", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems cost and reserve life instead of mana"] = { mod("ExtraSupport", "LIST", { skillId = "SupportBloodMagicUniquePrismGuardian", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems have elemental equilibrium"] = { mod("Keystone", "LIST", "Elemental Equilibrium") },
	["socketed gems have secrets of suffering"] = {
		flag("CannotIgnite", { type = "SocketedIn", slotName = "{SlotName}" }),
		flag("CannotChill", { type = "SocketedIn", slotName = "{SlotName}" }),
		flag("CannotFreeze", { type = "SocketedIn", slotName = "{SlotName}" }),
		flag("CannotShock", { type = "SocketedIn", slotName = "{SlotName}" }),
		flag("CritAlwaysAltAilments", { type = "SocketedIn", slotName = "{SlotName}" })
	},
	["socketed skills deal double damage"] = { mod("ExtraSkillMod", "LIST", { mod = mod("DoubleDamageChance", "BASE", 100) }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed gems gain (%d+)%% of physical damage as extra lightning damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("PhysicalDamageGainAsLightning", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["socketed red gems get (%d+)%% physical damage as extra fire damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("PhysicalDamageGainAsFire", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "strength" }) } end,
	["socketed non%-channelling bow skills are triggered by snipe"] = {
	},
	["grants level (%d+) snipe skill"] = function(num) return {
		mod("ExtraSkill", "LIST", { skillId = "ChannelledSnipe", level = num }),
		mod("ExtraSupport", "LIST", { skillId = "ChannelledSnipeSupport", level = num }, { type = "SocketedIn", slotName = "{SlotName}" }),
	} end,
	["socketed triggered bow skills deal (%d+)%% less damage"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("Damage", "MORE", -num) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "bow" }, { type = "SkillType", skillType = SkillType.Triggerable }) } end,
	["socketed vaal skills require (%d+)%% less souls per use"]  = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("SoulCost", "MORE", -num) }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "SkillType", skillType = SkillType.Vaal }) } end,
	["hits from socketed vaal skills ignore enemy monster resistances"]  = {
		mod("ExtraSkillMod", "LIST", { mod = flag("IgnoreElementalResistances") }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "SkillType", skillType = SkillType.Vaal }),
		mod("ExtraSkillMod", "LIST", { mod = flag("IgnoreChaosResistance") }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "SkillType", skillType = SkillType.Vaal }),
	},
	["hits from socketed vaal skills ignore enemy monster physical damage reduction"]  = { mod("ExtraSkillMod", "LIST", { mod = flag("IgnoreEnemyPhysicalDamageReduction") }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "SkillType", skillType = SkillType.Vaal }) },
	["socketed vaal skills grant elusive when used"] = { flag("Condition:CanBeElusive") },
	["damage with hits from socketed vaal skills is lucky"]  = { mod("ExtraSkillMod", "LIST", { mod = flag("LuckyHits") }, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "SkillType", skillType = SkillType.Vaal }) },
	-- Global gem modifiers
	["([%+%-]%d+)%%? to (%a+) of all (.+) gems"] = function(num, _, property, skill)
		if gemIdLookup[skill] then
			return { mod("GemProperty", "LIST", {keyword = skill, key = "level", value = num }) }
		end
		local wordList = {}
		for tag in skill:gmatch("%w+") do
			table.insert(wordList, tag)
		end
		return { mod("GemProperty", "LIST", {keywordList = wordList, key = property, value = num }) }
	end,
	["gems socketed in red sockets have [%+%-](%d+) to level"] = function(num) return { mod("GemProperty", "LIST", { keyword = "all", key = "level", value = num }, { type = "SocketedIn", slotName = "{SlotName}", socketColor = "R" }) } end,
	["gems socketed in green sockets have [%+%-](%d+)%% to quality"] = function(num) return { mod("GemProperty", "LIST", { keyword = "all", key = "quality", value = num }, { type = "SocketedIn", slotName = "{SlotName}", socketColor = "G" }) } end,
	["%+(%d+)%% to fire resistance when socketed with a red gem"] = function(num) return { mod("SocketProperty", "LIST", { value = mod("FireResist", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "strength", sockets = {1} }) } end,
	["%+(%d+)%% to cold resistance when socketed with a green gem"] = function(num) return { mod("SocketProperty", "LIST", { value = mod("ColdResist", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "dexterity", sockets = {1} }) } end,
	["%+(%d+)%% to lightning resistance when socketed with a blue gem"] = function(num) return { mod("SocketProperty", "LIST", { value = mod("LightningResist", "BASE", num) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "intelligence", sockets = {1} }) } end,
	--Doomsower, Lion Sword
	["attack skills gain (%d+)%% of physical damage as extra fire damage per socketed red gem"] = function(num) return { mod("SocketProperty", "LIST", { value = mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Attack) }, { type = "SocketedIn", slotName = "{SlotName}", keyword = "strength", sockets = {1,2,3,4,5,6} }) } end,
	["you have vaal pact while all socketed gems are red"] = { mod("GroupProperty", "LIST", { value = mod("Keystone", "LIST", "Vaal Pact") }, { type = "SocketedIn", slotName = "{SlotName}", socketColor = "R", sockets = "all" }) },
	-- Mahuxotl's Machination Steel Kite Shield
	["everlasting sacrifice"] = { 
		flag("Condition:EverlastingSacrifice")
	},
	 -- Self hit dmg
	["take (%d+) (.+) damage when you ignite an enemy"] = function(dmg, _, dmgType) return {
		mod("EyeOfInnocenceSelfDamage", "LIST", {baseDamage = dmg, damageType = dmgType})
	} end,
	["(%d+) (.+) damage taken on minion death"] = function(dmg, _, dmgType) return {
		mod("HeartboundLoopSelfDamage", "LIST", {baseDamage = dmg, damageType = dmgType})
	}end,
	["your skills deal you (%d+)%% of mana cost as (.+) damage"] = function(dmgMult, _, dmgType) return {
		mod("ScoldsBridleSelfDamage", "LIST", {dmgMult = dmgMult, damageType = dmgType})
	}end,
	-- Extra skill/support
	["grants (%D+)"] = function(_, skill) return grantedExtraSkill(skill, 1) end,
	["grants level (%d+) (.+)"] = function(num, _, skill) return grantedExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when equipped"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) on %a+"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["use level (%d+) (.+) on %a+"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you attack"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you deal a critical strike"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when hit"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you kill an enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["[ct][ar][si][tg]g?e?r?s? level (%d+) (.+) when you use a skill"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["(.+) can trigger level (%d+) (.+)"] = function(_, sourceSkill, num, skill) return triggerExtraSkill(skill, tonumber(num), {sourceSkill = sourceSkill}) end,
	["trigger level (%d+) (.+) when you use a skill while you have a spirit charge"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you hit an enemy while cursed"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you hit a bleeding enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you hit a rare or unique enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you hit a rare or unique enemy and have no mark"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you hit a frozen enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you kill a frozen enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you consume a corpse"] = function(num, _, skill) return skill == "summon phantasm skill" and triggerExtraSkill("triggered summon phantasm skill", num) or triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you attack with a bow"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you block"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when animated guardian kills an enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you lose cat's stealth"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when your trap is triggered"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) on hit with this weapon"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) on melee hit while cursed"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) on melee hit with this weapon"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) every [%d%.]+ seconds while phasing"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) when you gain avian's might or avian's flight"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) on melee hit if you have at least (%d+) strength"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+) on critical strike with cleave or reave"] = function(num, _, skill) return triggerExtraSkill(skill, num, {onCrit = true}) end,
	["triggers level (%d+) (.+) when equipped"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["triggers level (%d+) (.+) when allocated"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["(%d+)%% chance to attack with level (%d+) (.+) on melee hit"] = function(chance, _, level, skill)	return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) when animated weapon kills an enemy"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) on melee hit"] = function(chance, _, level, skill)	return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) [ow][nh]e?n? ?y?o?u? kill ?a?n? ?e?n?e?m?y?"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) when you use a socketed skill"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) when you gain avian's might or avian's flight"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance = chance}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) on critical strike with this weapon"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance =  chance, onCrit = true}) end,
	["(%d+)%% chance to trigger level (%d+) (.+) when you or a nearby ally kill an enemy, or hit a rare or unique enemy"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["(%d+)%% chance to [ct][ar][si][tg]g?e?r? level (%d+) (.+) on %a+"] = function(chance, _, level, skill) return triggerExtraSkill(skill, level, {triggerChance =  chance}) end,
	["attack with level (%d+) (.+) when you kill a bleeding enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["triggers? level (%d+) (.+) when you kill a bleeding enemy"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["curse enemies with (%D+) on %a+"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["curse enemies with (%D+) on %a+, with (%d+)%% increased effect"] = function(_, skill, num) return {
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill], level = 1, noSupports = true, triggered = true }),
		mod("CurseEffect", "INC", tonumber(num), { type = "SkillName", skillName = string.gsub(" "..skill, "%W%l", string.upper):sub(2) }),
	} end,
	["curse enemies with (%D+) on %a+, with (%d+)%% reduced effect"] = function(_, skill, num) return {
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill], level = 1, noSupports = true, triggered = true }),
		mod("CurseEffect", "INC", -tonumber(num), { type = "SkillName", skillName = string.gsub(" "..skill, "%W%l", string.upper):sub(2) }),
	} end,
	["%d+%% chance to curse n?o?n?%-?c?u?r?s?e?d? ?enemies with (%D+) on %a+, with (%d+)%% increased effect"] = function(_, skill, num) return {
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill], level = 1, noSupports = true, triggered = true }),
		mod("CurseEffect", "INC", tonumber(num), { type = "SkillName", skillName = string.gsub(" "..skill, "%W%l", string.upper):sub(2) }),
	} end,
	["%d+%% chance to curse n?o?n?%-?c?u?r?s?e?d? ?enemies with (%D+) on %a+"] = function(_, skill) return {
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill], level = 1, noSupports = true, triggered = true }),
	} end,
	["curse enemies with level (%d+) (%D+) on %a+, which can apply to hexproof enemies"] = function(num, _, skill) return triggerExtraSkill(skill, num, {noSupports = true, ignoreHexproof = true}) end,
	["curse enemies with level (%d+) (.+) on %a+"] = function(num, _, skill) return triggerExtraSkill(skill, num, {noSupports = true}) end,
	["[ct][ar][si][tg]g?e?r?s? (.+) on %a+"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[at][tr][ti][ag][cg][ke]r? (.+) on %a+"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[at][tr][ti][ag][cg][ke]r? with (.+) on %a+"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[ct][ar][si][tg]g?e?r?s? (.+) when hit"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[at][tr][ti][ag][cg][ke]r? (.+) when hit"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[at][tr][ti][ag][cg][ke]r? with (.+) when hit"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[ct][ar][si][tg]g?e?r?s? (.+) when your skills or minions kill"] = function(_, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[at][tr][ti][ag][cg][ke]r? (.+) when you take a critical strike"] = function( _, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["[at][tr][ti][ag][cg][ke]r? with (.+) when you take a critical strike"] = function( _, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["trigger commandment of inferno on critical strike"] = {
		mod("ExtraSkill", "LIST", { skillId = "UniqueEnchantmentOfInfernoOnCrit", level = 1, noSupports = true, triggered = true }),
		mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "triggerOnCrit", value = true })},  { type = "SkillId", skillId = "UniqueEnchantmentOfInfernoOnCrit" }) },
	["trigger (.+) on critical strike"] = function( _, skill) return triggerExtraSkill(skill, 1, {noSupports = true, onCrit = true}) end,
	["triggers? (.+) when you take a critical strike"] = function( _, skill) return triggerExtraSkill(skill, 1, {noSupports = true}) end,
	["socketed [%a+]* ?gems a?r?e? ?supported by level (%d+) (.+)"] = function(num, _, support) return extraSupport(support, num) end,
	["skills from equipped (.+) are supported by level (%d+) (.+)"] = function(_, slot, level, support) return extraSupport(support, level, slot) end,
	["socketed support gems can also support skills from y?o?u?r? ?e?q?u?i?p?p?e?d? ?([%a%s]+)"] = function (_, itemSlotName)
		local targetItemSlotName = "Body Armour"
		if itemSlotName == "main hand" then
			targetItemSlotName = "Weapon 1"
		end
		return { mod("LinkedSupport", "LIST", { targetSlotName = targetItemSlotName }) }
	end,
	["socketed hex curse skills are triggered by doedre's effigy when summoned"] = { mod("ExtraSupport", "LIST", { skillId = "SupportCursePillarTriggerCurses", level = 20 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["socketed projectile spells have %+([%d%.]+) seconds to cooldown"] = function(num) return {
		mod("CooldownRecovery", "BASE", num, { type = "SocketedIn", slotName = "{SlotName}" }, { type = "SkillType", skillType= SkillType.Projectile }, { type = "SkillType", skillType = SkillType.Spell })
	} end,
	["trigger level (%d+) (.+) every (%d+) seconds"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["trigger level (%d+) (.+), (.+) or (.+) every (%d+) seconds"] = function(num, _, skill1, skill2, skill3) return {
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill1], level = num, triggered = true }),
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill2], level = num, triggered = true }),
		mod("ExtraSkill", "LIST", { skillId = gemIdLookup[skill3], level = num, triggered = true }),
	} end,
	["offering skills triggered this way also affect you"] = { mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "buffNotPlayer", value = false }) }, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering" } }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger level (%d+) (.+) after spending a total of (%d+) mana"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["consumes a void charge to trigger level (%d+) (.+) when you fire arrows"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["consumes a void charge to trigger level (%d+) (.+) when you fire arrows with a non%-triggered skill"] = function(num, _, skill) return triggerExtraSkill(skill, num) end,
	["your hits treat cold resistance as (%d+)%% higher than actual value"] = function(num) return {
		mod("ColdPenetration", "BASE", -num, nil, 0, KeywordFlag.Hit),
	} end,
	-- Conversion
	["increases and reductions to minion damage also affects? you"] = { flag("MinionDamageAppliesToPlayer"), mod("ImprovedMinionDamageAppliesToPlayer", "MAX", 100) },
	["increases and reductions to minion damage also affects? you at (%d+)%% of their value"] = function(num) return { flag("MinionDamageAppliesToPlayer"), mod("ImprovedMinionDamageAppliesToPlayer", "MAX", num) } end,
	["increases and reductions to minion damage also affect dominating blow and absolution at (%d+)%% of their value"] = function(num) return {
		flag("MinionDamageAppliesToPlayer", { type = "SkillName", skillNameList = { "Dominating Blow", "Absolution" }, includeTransfigured = true }),
		mod("ImprovedMinionDamageAppliesToPlayer", "MAX", num, { type = "SkillName", skillNameList = { "Dominating Blow", "Absolution" }, includeTransfigured = true })
	} end,
	["increases and reductions to minion attack speed also affects? you"] = { flag("MinionAttackSpeedAppliesToPlayer"), mod("ImprovedMinionAttackSpeedAppliesToPlayer", "MAX", 100) },
	["increases and reductions to cast speed apply to attack speed at (%d+)%% of their value"] =  function(num) return { flag("CastSpeedAppliesToAttacks"), mod("ImprovedCastSpeedAppliesToAttacks", "MAX", num) } end,
	["increases and reductions to cast speed apply to attack speed"] =  function(num) return { flag("CastSpeedAppliesToAttacks"), mod("ImprovedCastSpeedAppliesToAttacks", "MAX", 100) } end,
	["increases and reductions to spell damage also apply to attacks"] = { flag("SpellDamageAppliesToAttacks"), mod("ImprovedSpellDamageAppliesToAttacks", "MAX", 100) },
	["increases and reductions to spell damage also apply to attacks at (%d+)%% of their value"] = function(num) return { flag("SpellDamageAppliesToAttacks"), mod("ImprovedSpellDamageAppliesToAttacks", "MAX", num) } end,
	["increases and reductions to spell damage also apply to attacks while wielding a wand"] = { flag("SpellDamageAppliesToAttacks", { type = "Condition", var = "UsingWand" }), mod("ImprovedSpellDamageAppliesToAttacks", "MAX", 100, { type = "Condition", var = "UsingWand" }) },
	["increases and reductions to maximum mana also apply to shock effect at (%d+)%% of their value"] = function(num) return { flag("ManaAppliesToShockEffect"), mod("ImprovedManaAppliesToShockEffect", "MAX", num) } end,
	["modifiers to claw damage also apply to unarmed"] = { flag("ClawDamageAppliesToUnarmed") },
	["modifiers to claw damage also apply to unarmed attack damage"] = { flag("ClawDamageAppliesToUnarmed") },
	["modifiers to claw damage also apply to unarmed attack damage with melee skills"] = { flag("ClawDamageAppliesToUnarmed") },
	["modifiers to claw attack speed also apply to unarmed"] = { flag("ClawAttackSpeedAppliesToUnarmed") },
	["modifiers to claw attack speed also apply to unarmed attack speed"] = { flag("ClawAttackSpeedAppliesToUnarmed") },
	["modifiers to claw attack speed also apply to unarmed attack speed with melee skills"] = { flag("ClawAttackSpeedAppliesToUnarmed") },
	["modifiers to claw critical strike chance also apply to unarmed"] = { flag("ClawCritChanceAppliesToUnarmed") },
	["modifiers to claw critical strike chance also apply to unarmed attack critical strike chance"] = { flag("ClawCritChanceAppliesToUnarmed") },
	["modifiers to claw critical strike chance also apply to unarmed critical strike chance with melee skills"] = { flag("ClawCritChanceAppliesToUnarmed") },
	["increases and reductions to light radius also apply to accuracy"] = { flag("LightRadiusAppliesToAccuracy") },
	["increases and reductions to light radius also apply to area of effect at 50%% of their value"] = { flag("LightRadiusAppliesToAreaOfEffect") },
	["increases and reductions to light radius also apply to damage"] = { flag("LightRadiusAppliesToDamage") },
	["increases and reductions to cast speed also apply to trap throwing speed"] = { flag("CastSpeedAppliesToTrapThrowingSpeed") },
	["increases and reductions to armour also apply to energy shield recharge rate at (%d+)%% of their value"] = function(num) return { flag("ArmourAppliesToEnergyShieldRecharge"), mod("ImprovedArmourAppliesToEnergyShieldRecharge", "MAX", num) } end,
	["increases and reductions to projectile speed also apply to damage with bows"] = { flag("ProjectileSpeedAppliesToBowDamage") },
	["modifiers to maximum (%a+) resistance also apply to maximum (%a+) and (%a+) resistances"] = function(_, resFrom, resTo1, resTo2) return {
		mod((resFrom:gsub("^%l", string.upper)).."MaxResConvertTo"..(resTo1:gsub("^%l", string.upper)), "BASE", 100),
		mod((resFrom:gsub("^%l", string.upper)).."MaxResConvertTo"..(resTo2:gsub("^%l", string.upper)), "BASE", 100),
	} end,
	["modifiers to (%a+) resistance also apply to (%a+) and (%a+) resistances at (%d+)%% of their value"] = function(_, resFrom, resTo1, resTo2, rate) return {
		mod((resFrom:gsub("^%l", string.upper)).."ResConvertTo"..(resTo1:gsub("^%l", string.upper)), "BASE", tonumber(rate)),
		mod((resFrom:gsub("^%l", string.upper)).."ResConvertTo"..(resTo2:gsub("^%l", string.upper)), "BASE", tonumber(rate)),
	} end,
	["gain (%d+)%% of bow physical damage as extra damage of each element"] = function(num) return {
		mod("PhysicalDamageGainAsLightning", "BASE", num, nil, ModFlag.Bow),
		mod("PhysicalDamageGainAsCold", "BASE", num, nil, ModFlag.Bow),
		mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Bow),
	} end,
	["gain (%d+)%% of weapon physical damage as extra damage of each element"] = function(num) return {
		mod("PhysicalDamageGainAsLightning", "BASE", num, nil, ModFlag.Weapon),
		mod("PhysicalDamageGainAsCold", "BASE", num, nil, ModFlag.Weapon),
		mod("PhysicalDamageGainAsFire", "BASE", num, nil, ModFlag.Weapon),
	} end,
	["gain (%d+)%% of physical damage as extra damage of each element per spirit charge"] = function(num) return {
		mod("PhysicalDamageGainAsLightning", "BASE", num, { type = "Multiplier", var = "SpiritCharge" }),
		mod("PhysicalDamageGainAsCold", "BASE", num, { type = "Multiplier", var = "SpiritCharge" }),
		mod("PhysicalDamageGainAsFire", "BASE", num, { type = "Multiplier", var = "SpiritCharge" }),
	} end,
	["gain (%d+)%% of weapon physical damage as extra damage of an? r?a?n?d?o?m? ?element"] = function(num) return { mod("PhysicalDamageGainAsRandom", "BASE", num, nil, ModFlag.Weapon) } end,
	["gain (%d+)%% of physical damage as extra damage of a random element"] = function(num) return { mod("PhysicalDamageGainAsRandom", "BASE", num ) } end,
	["(%d+)%% chance for hits to deal (%d+)%% of physical damage as extra damage of a random element"] = function(num, _, physPercent) return { mod("PhysicalDamageGainAsRandom", "BASE", (num*physPercent/100) ) } end,
	["gain (%d+)%% of physical damage as a random element if you've cast (.-) in the past (%d+) seconds"] = function(num, _, curse) return { mod("PhysicalDamageGainAsRandom", "BASE", num, { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") }) } end,
	["gain (%d+)%% of physical damage as extra damage of a random element while you are ignited"] = function(num) return { mod("PhysicalDamageGainAsRandom", "BASE", num, { type = "Condition", var = "Ignited" }) } end,
	["(%d+)%% of physical damage from hits with this weapon is converted to a random element"] = function(num) return { mod("PhysicalDamageConvertToRandom", "BASE", num ) } end,
	["(%d+)%% of physical damage converted to a random element"] = function(num) return { mod("PhysicalDamageConvertToRandom", "BASE", num ) } end,
	["nearby enemies convert (%d+)%% of their (%a+) damage to (%a+)"] = function(num, _, damageFrom, damageTo) return { mod("EnemyModifier", "LIST", { mod = mod((damageFrom:gsub("^%l", string.upper)).."DamageConvertTo"..(damageTo:gsub("^%l", string.upper)), "BASE", num ) }), } end,
	["enemies ignited by you have (%d+)%% of (%a+) damage they deal converted to (%a+)"] = function(num, _, damageFrom, damageTo) return { mod("EnemyModifier", "LIST", { mod = mod((damageFrom:gsub("^%l", string.upper)).."DamageConvertTo"..(damageTo:gsub("^%l", string.upper)), "BASE", num, { type = "Condition", var = "Ignited" }) }), } end,
	["enemies shocked by you have (%d+)%% of (%a+) damage they deal converted to (%a+)"] = function(num, _, damageFrom, damageTo) return { mod("EnemyModifier", "LIST", { mod = mod((damageFrom:gsub("^%l", string.upper)).."DamageConvertTo"..(damageTo:gsub("^%l", string.upper)), "BASE", num, { type = "Condition", var = "Shocked" }) }), } end,
	["shield crush and spectral shield throw do not gain added physical damage based on armour or evasion on shield"] = { flag("Condition:ShieldThrowCrushNoArmourEvasion", { type = "SkillName", skillNameList = { "Spectral Shield Throw", "Shield Crush" }, includeTransfigured = true })},
	["shield crush and spectral shield throw gains (%d+) to (%d+) added lightning damage per (%d+) energy shield on shield"] = function(_, min, max, num) return {
		mod("LightningMin", "BASE", min, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", stat = "EnergyShieldOnWeapon 2", div = num }, { type = "SkillName", skillNameList = { "Spectral Shield Throw", "Shield Crush" }, includeTransfigured = true }),
		mod("LightningMax", "BASE", max, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", stat = "EnergyShieldOnWeapon 2", div = num }, { type = "SkillName", skillNameList = { "Spectral Shield Throw", "Shield Crush" }, includeTransfigured = true }),
	} end,
	["(%d+)%% of shield crush and spectral shield throw physical damage converted to lightning damage"] = function(num) return {
		mod("SkillPhysicalDamageConvertToLightning", "BASE", num, 0, 0, { type = "SkillName", skillNameList = { "Spectral Shield Throw", "Shield Crush" }, includeTransfigured = true }),
	} end,
	["(%d+)%% of exsanguinate and reap physical damage converted to fire damage"] = function(num) return {
		mod("SkillPhysicalDamageConvertToFire", "BASE", num, 0, 0, { type = "SkillName", skillNameList = { "Exsanguinate", "Reap" }, includeTransfigured = true }),
	} end,
	["%-(%d+)%% of toxic rain physical damage converted to chaos damage"] = function(num) return {
		mod("SkillPhysicalDamageConvertToChaos", "BASE", -num, 0, 0, { type = "SkillName", skillName = "Toxic Rain", includeTransfigured = true }),
	} end,
	["cobra lash and venom gyre have %-(%d+)%% of physical damage converted to chaos damage"] = function(num) return {
		mod("SkillPhysicalDamageConvertToChaos", "BASE", -num, 0, 0, { type = "SkillName", skillNameList = { "Cobra Lash", "Venom Gyre" } }),
	} end,
	["(%d+)%% of consecrated path and purifying flame fire damage converted to chaos damage"] = function(num) return {
		mod("SkillFireDamageConvertToChaos", "BASE", num, 0, 0, { type = "SkillName", skillNameList = { "Consecrated Path", "Purifying Flame" }, includeTransfigured = true }),
	} end,
	["(%d+)%% of manabond and stormbind lightning damage converted to cold damage"] = function(num) return {
		mod("SkillLightningDamageConvertToCold", "BASE", num, 0, 0, { type = "SkillName", skillNameList = { "Manabond", "Stormbind" }, includeTransfigured = true }),
	} end,
	["exsanguinate debuffs deal fire damage per second instead of physical damage per second"] = { flag("Condition:ExsanguinateDebuffIsFireDamage", { type = "SkillName", skillName = "Exsanguinate", includeTransfigured = true })},
	["reap debuffs deal fire damage per second instead of physical damage per second"] = { flag("Condition:ReapDebuffIsFireDamage", { type = "SkillName", skillName = "Reap" })},
	-- Crit
	["your critical strike chance is lucky"] = { flag("CritChanceLucky") },
	["your critical strike chance is lucky while on low life"] = { flag("CritChanceLucky", { type = "Condition", var = "LowLife" }) },
	["your critical strike chance is lucky while focus?sed"] = { flag("CritChanceLucky", { type = "Condition", var = "Focused" }) },
	["your critical strikes do not deal extra damage"] = { flag("NoCritMultiplier") },
	["minion critical strikes do not deal extra damage"] = { mod("MinionModifier", "LIST", { mod = flag("NoCritMultiplier") }) },
	["lightning damage with non%-critical strikes is lucky"] = { flag("LightningNoCritLucky") },
	["your damage with critical strikes is lucky"] = { flag("CritLucky") },
	["critical strikes deal no damage"] = { mod("Damage", "MORE", -100, { type = "Condition", var = "CriticalStrike" }) },
	["critical strike chance is increased by uncapped lightning resistance"] = { flag("CritChanceIncreasedByUncappedLightningRes") },
	["critical strike chance is increased by lightning resistance"] = { flag("CritChanceIncreasedByLightningRes") },
	["critical strike chance is increased by overcapped lightning resistance"] = { flag("CritChanceIncreasedByOvercappedLightningRes") },
	["barrage and frenzy have (%d+)%% increased critical strike chance per endurance charge"] = function(num) return { mod("CritChance", "INC", num, { type = "Multiplier", var = "EnduranceCharge" }, { type = "SkillName", skillNameList = { "Barrage", "Frenzy" }, includeTransfigured = true }) } end,
	["non%-critical strikes deal (%d+)%% damage"] = function(num) return { mod("Damage", "MORE", -100 + num, nil, ModFlag.Hit, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	["non%-critical strikes deal no damage"] = { mod("Damage", "MORE", -100, nil, ModFlag.Hit, { type = "Condition", var = "CriticalStrike", neg = true }) },
	["non%-critical strikes deal (%d+)%% less damage"] = function(num) return { mod("Damage", "MORE", -num, nil, ModFlag.Hit, { type = "Condition", var = "CriticalStrike", neg = true }) } end,
	["spell skills always deal critical strikes on final repeat"] = { flag("SpellSkillsAlwaysDealCriticalStrikesOnFinalRepeat", nil, ModFlag.Spell) },
	["spell skills cannot deal critical strikes except on final repeat"] = { flag("SpellSkillsCannotDealCriticalStrikesExceptOnFinalRepeat", nil, ModFlag.Spell), flag("", { type = "Condition", var = "alwaysFinalRepeat" }) },
	["critical strikes penetrate (%d+)%% of enemy elemental resistances while affected by zealotry"] = function(num) return { mod("ElementalPenetration", "BASE", num, { type = "Condition", var = "CriticalStrike" }, { type = "Condition", var = "AffectedByZealotry" }) } end,
	["attack critical strikes ignore enemy monster elemental resistances"] = { flag("IgnoreElementalResistances", { type = "Condition", var = "CriticalStrike" }, { type = "SkillType", skillType = SkillType.Attack }) },
	["treats enemy monster elemental resistance values as inverted"] =  { mod("HitsInvertEleResChance", "CHANCE", 100, { type = "Condition", var = "{Hand}Attack" }) } ,
	["([%+%-]%d+)%% to critical strike multiplier if you've shattered an enemy recently"] = function(num) return { mod("CritMultiplier", "BASE", num, { type = "Condition", var = "ShatteredEnemyRecently" }) } end,
	["(%d+)%% chance to gain a flask charge when you deal a critical strike"] = function(num) return{ mod("FlaskChargeOnCritChance", "BASE", num) } end,
	["gain a flask charge when you deal a critical strike"] = { mod("FlaskChargeOnCritChance", "BASE", 100) },
	["gain a flask charge when you deal a critical strike while affected by precision"] = { mod("FlaskChargeOnCritChance", "BASE", 100, { type = "Condition", var = "AffectedByPrecision" }) },
	["gain a flask charge when you deal a critical strike while at maximum frenzy charges"] = { mod("FlaskChargeOnCritChance", "BASE", 100, { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["enemies poisoned by you cannot deal critical strikes"] = { mod("EnemyModifier", "LIST", { mod = flag("NeverCrit", { type = "Condition", var = "Poisoned" }) }), mod("EnemyModifier", "LIST", { mod = flag("Condition:NeverCrit", { type = "Condition", var = "Poisoned" })}) },
	["marked enemy cannot deal critical strikes"] =  { mod("EnemyModifier", "LIST", { mod = flag("NeverCrit", { type = "Condition", var = "Marked" }) }), mod("EnemyModifier", "LIST", { mod = flag("Condition:NeverCrit", { type = "Condition", var = "Marked" })}) },
	["hits against you cannot be critical strikes if you've been stunned recently"] =  { mod("EnemyModifier", "LIST", { mod = flag("NeverCrit") }, {type = "Condition", var = "StunnedRecently" }), mod("EnemyModifier", "LIST", { mod = flag("Condition:NeverCrit")}, {type = "Condition", var = "StunnedRecently" })},
	["nearby enemies cannot deal critical strikes"] = { mod("EnemyModifier", "LIST", { mod = flag("NeverCrit")  }), mod("EnemyModifier", "LIST", { mod = flag("Condition:NeverCrit") }) },
	["hits against you are always critical strikes"] = { mod("EnemyModifier", "LIST", { mod = flag("AlwaysCrit")  }), mod("EnemyModifier", "LIST", { mod = flag("Condition:AlwaysCrit") }) },
	["your hits are always critical strikes"] =  { mod("CritChance", "OVERRIDE", 100) },
	["hits have (%d+)%% increased critical strike chance against you"] = function(num) return { mod("EnemyCritChance", "INC", num) } end,
	["stuns from critical strikes have (%d+)%% increased duration"] = function(num) return { mod("EnemyStunDurationOnCrit", "INC", num) } end,
	-- Generic Ailments
	["enemies take (%d+)%% increased damage for each type of ailment you have inflicted on them"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Frozen" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Ignited" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Shocked" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Scorched" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Brittle" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Sapped" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }),
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Poisoned" }),
	} end,
	-- Elemental Ailments
	["your shocks can increase damage taken by up to a maximum of (%d+)%%"] = function(num) return { mod("ShockMax", "OVERRIDE", num) } end,
	["%+(%d+)%% to maximum effect of shock"] = function(num) return { mod("ShockMax", "BASE", num) } end,
	["your elemental damage can shock"] = { flag("ColdCanShock"), flag("FireCanShock") },
	["your fire damage can shock"] = { flag("FireCanShock") },
	["all y?o?u?r? ?damage can freeze"] = { flag("PhysicalCanFreeze"), flag("LightningCanFreeze"), flag("FireCanFreeze"), flag("ChaosCanFreeze") },
	["all damage with maces and sceptres inflicts chill"] =  {
		flag("PhysicalCanChill", { type = "Condition", var = "UsingMace" }),
		flag("LightningCanChill", { type = "Condition", var = "UsingMace" }),
		flag("FireCanChill", { type = "Condition", var = "UsingMace" }),
		flag("ChaosCanChill", { type = "Condition", var = "UsingMace" })
	},
	["your cold damage can ignite"] = { flag("ColdCanIgnite") },
	["your lightning damage can ignite"] = { flag("LightningCanIgnite") },
	["all damage from lightning strike and frost blades hits can ignite"] = {
		flag("PhysicalCanIgnite", { type = "SkillName", skillNameList = { "Lightning Strike", "Frost Blades" }, includeTransfigured = true }),
		flag("ColdCanIgnite", { type = "SkillName", skillNameList = { "Lightning Strike", "Frost Blades" }, includeTransfigured = true }),
		flag("LightningCanIgnite", { type = "SkillName", skillNameList = { "Lightning Strike", "Frost Blades" }, includeTransfigured = true }),
		flag("ChaosCanIgnite", { type = "SkillName", skillNameList = { "Lightning Strike", "Frost Blades" }, includeTransfigured = true })
	},
	["all damage from lightning arrow and ice shot hits can ignite"] = {
		flag("PhysicalCanIgnite", { type = "SkillName", skillNameList = { "Lightning Arrow", "Ice Shot" }, includeTransfigured = true }),
		flag("ColdCanIgnite", { type = "SkillName", skillNameList = { "Lightning Arrow", "Ice Shot" }, includeTransfigured = true }),
		flag("LightningCanIgnite", { type = "SkillName", skillNameList = { "Lightning Arrow", "Ice Shot" }, includeTransfigured = true }),
		flag("ChaosCanIgnite", { type = "SkillName", skillNameList = { "Lightning Arrow", "Ice Shot" }, includeTransfigured = true })
	},
	["all damage from shock nova and storm call hits can ignite"] = {
		flag("PhysicalCanIgnite", { type = "SkillName", skillNameList = { "Shock Nova", "Storm Call" }, includeTransfigured = true }),
		flag("ColdCanIgnite", { type = "SkillName", skillNameList = { "Shock Nova", "Storm Call" }, includeTransfigured = true }),
		flag("LightningCanIgnite", { type = "SkillName", skillNameList = { "Shock Nova", "Storm Call" }, includeTransfigured = true }),
		flag("ChaosCanIgnite", { type = "SkillName", skillNameList = { "Shock Nova", "Storm Call" }, includeTransfigured = true })
	},
	["your fire damage can shock but not ignite"] = { flag("FireCanShock"), flag("FireCannotIgnite") },
	["your cold damage can ignite but not freeze or chill"] = { flag("ColdCanIgnite"), flag("ColdCannotFreeze"), flag("ColdCannotChill") },
	["your cold damage cannot freeze"] = { flag("ColdCannotFreeze") },
	["your cold damage cannot chill"] = { flag("ColdCannotChill") },
	["your lightning damage can freeze but not shock"] = { flag("LightningCanFreeze"), flag("LightningCannotShock") },
	["your chaos damage can shock"] = { flag("ChaosCanShock") },
	["your chaos damage can chill"] = { flag("ChaosCanChill") },
	["your chaos damage can ignite"] = { flag("ChaosCanIgnite") },
	["chaos damage can ignite, chill and shock"] = { flag("ChaosCanIgnite"), flag("ChaosCanChill"), flag("ChaosCanShock") },
	["your physical damage can chill"] = { flag("PhysicalCanChill") },
	["your physical damage can shock"] = { flag("PhysicalCanShock") },
	["your physical damage can freeze"] = { flag("PhysicalCanFreeze") },
	["your lightning damage can freeze"] = { flag("LightningCanFreeze") },
	["you always ignite while burning"] = { mod("EnemyIgniteChance", "BASE", 100, { type = "Condition", var = "Burning" }) },
	["critical strikes do not a?l?w?a?y?s?i?n?h?e?r?e?n?t?l?y? freeze"] = { flag("CritsDontAlwaysFreeze") },
	["cannot inflict elemental ailments"] = {
		flag("CannotIgnite"),
		flag("CannotChill"),
		flag("CannotFreeze"),
		flag("CannotShock"),
		flag("CannotScorch"),
		flag("CannotBrittle"),
		flag("CannotSap"),
	},
	["flameblast and incinerate cannot inflict elemental ailments"] = {
		flag("CannotIgnite", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate" }, includeTransfigured = true }),
		flag("CannotChill", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate" }, includeTransfigured = true }),
		flag("CannotFreeze", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate" }, includeTransfigured = true }),
		flag("CannotShock", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate" }, includeTransfigured = true }),
		flag("CannotScorch", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate"}, includeTransfigured = true }),
		flag("CannotBrittle", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate" }, includeTransfigured = true }),
		flag("CannotSap", { type = "SkillName", skillNameList = { "Flameblast", "Incinerate" }, includeTransfigured = true }),
	},
	["you can inflict up to (%d+) ignites on an enemy"] = { flag("IgniteCanStack") },
	["you can inflict an additional ignite on an enemy"] = { flag("IgniteCanStack"), mod("IgniteStacks", "BASE", 1) },
	["enemies chilled by you take (%d+)%% increased burning damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("FireDamageTakenOverTime", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) } end,
	["damaging ailments deal damage (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num), mod("BleedFaster", "INC", num), mod("PoisonFaster", "INC", num) } end,
	["damaging ailments you inflict deal damage (%d+)%% faster while affected by malevolence"] = function(num) return {
		mod("IgniteBurnFaster", "INC", num, { type = "Condition", var = "AffectedByMalevolence" }),
		mod("BleedFaster", "INC", num, { type = "Condition", var = "AffectedByMalevolence" }),
		mod("PoisonFaster", "INC", num, { type = "Condition", var = "AffectedByMalevolence" }),
	} end,
	["ignited enemies burn (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num) } end,
	["ignited enemies burn (%d+)%% slower"] = function(num) return { mod("IgniteBurnSlower", "INC", num) } end,
	["enemies ignited by an attack burn (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num, nil, ModFlag.Attack) } end,
	["ignites you inflict with attacks deal damage (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num, nil, ModFlag.Attack) } end,
	["ignites you inflict deal damage (%d+)%% faster"] = function(num) return { mod("IgniteBurnFaster", "INC", num) } end,
	["(%d+)%% chance for ignites inflicted with lightning strike or frost blades to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Ignite, { type = "SkillName", skillNameList = { "Lightning Strike", "Frost Blades" }, includeTransfigured = true }),
	} end,
	["(%d+)%% chance for ignites inflicted with lightning arrow or ice shot to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Ignite, { type = "SkillName", skillNameList = { "Lightning Arrow", "Ice Shot" }, includeTransfigured = true }),
	} end,
	["(%d+)%% chance for ignites inflicted with shock nova or storm call to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Ignite, { type = "SkillName", skillNameList = { "Shock Nova", "Storm Call" }, includeTransfigured = true}),
	} end,
	["enemies ignited by you during f?l?a?s?k? ?effect take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Ignited" }) } end,
	["enemies ignited by you take chaos damage instead of fire damage from ignite"] = { flag("IgniteToChaos") },
	["enemies chilled by your hits are shocked"] = {
		mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "ActorCondition", actor = "enemy", var = "ChilledByYourHits" }),
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Shocked", { type = "Condition", var = "ChilledByYourHits" }) })
	},
	["cannot inflict ignite"] = { flag("CannotIgnite") },
	["cannot inflict freeze or chill"] = { flag("CannotFreeze"), flag("CannotChill") },
	["cannot inflict shock"] = { flag("CannotShock") },
	["cannot ignite, chill, freeze or shock"] = { flag("CannotIgnite"), flag("CannotChill"), flag("CannotFreeze"), flag("CannotShock") },
	["shock enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("ShockAsThoughDealing", "MORE", num) } end,
	["chill enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("ChillAsThoughDealing", "MORE", num) } end,
	["inflict non%-damaging ailments as though dealing (%d+)%% more damage"] = function(num) return {
		mod("ShockAsThoughDealing", "MORE", num),
		mod("ChillAsThoughDealing", "MORE", num),
		mod("FreezeAsThoughDealing", "MORE", num),
		mod("ScorchAsThoughDealing", "MORE", num),
		mod("BrittleAsThoughDealing", "MORE", num),
		mod("SapAsThoughDealing", "MORE", num),
	} end,
	["non%-damaging elemental ailments you inflict have (%d+)%% more effect"] = function(num) return {
		mod("EnemyShockEffect", "MORE", num),
		mod("EnemyChillEffect", "MORE", num),
		mod("EnemyFreezeEffect", "MORE", num),
		mod("EnemyScorchEffect", "MORE", num),
		mod("EnemyBrittleEffect", "MORE", num),
		mod("EnemySapEffect", "MORE", num),
	} end,
	["immun[ei]t?y? to elemental ailments while on consecrated ground if you have at least (%d+) devotion"] = function(num) return { flag("ElementalAilmentImmune", { type = "Condition", var = "OnConsecratedGround" }, { type = "StatThreshold", stat = "Devotion", threshold = num }), } end,
	["freeze enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("FreezeAsThoughDealing", "MORE", num) } end,
	["freeze chilled enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("FreezeAsThoughDealing", "MORE", num, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) } end,
	["manabond and stormbind freeze enemies as though dealing (%d+)%% more damage"] = function(num) return { mod("FreezeAsThoughDealing", "MORE", num, { type = "SkillName", skillNameList = { "Manabond", "Stormbind" }, includeTransfigured = true }) } end,
	["(%d+)%% chance to inflict brittle on enemies when you block their damage"] = function(num) return { mod("EnemyBrittleChance", "BASE", num) } end,
	["(%d+)%% chance to inflict sap on enemies when you block their damage"] = function(num) return { mod("EnemySapChance", "BASE", num) } end,
	["(%d+)%% chance to inflict scorch on enemies when you block their damage"] = function(num) return { mod("EnemyScorchChance", "BASE", num) } end,
	["scorch enemies in close range when you block"] = { mod("EnemyScorchChance", "BASE", 100) },
	["(%d+)%% chance to shock attackers for (%d+) seconds on block"] = { mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default) },
	["shock attackers for (%d+) seconds on block"]  = {
		mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "Condition", var = "BlockedRecently" }),
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Shocked") }, { type = "Condition", var = "BlockedRecently" }),
	},
	["shock nearby enemies for (%d+) seconds when you focus"]  = {
		mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "Condition", var = "Focused" }),
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Shocked") }, { type = "Condition", var = "Focused" }),
	},
	["shock yourself for (%d+) seconds when you focus"] = {
		mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "Condition", var = "Focused" }),
		flag("Condition:Shocked", { type = "Condition", var = "Focused" }),
	},
	["drops shocked ground while moving, lasting (%d+) seconds"] = { mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "ActorCondition", actor = "enemy", var = "OnShockedGround" }) },
	["drops scorched ground while moving, lasting (%d+) seconds"] = { mod("ScorchBase", "BASE", data.nonDamagingAilment["Scorch"].default, { type = "ActorCondition", actor = "enemy", var = "OnScorchedGround" }) },
	["drops brittle ground while moving, lasting (%d+) seconds"] = { mod("BrittleBase", "BASE", data.nonDamagingAilment["Brittle"].default, { type = "ActorCondition", actor = "enemy", var = "OnBrittleGround" }) },
	["drops sapped ground while moving, lasting (%d+) seconds"] = { mod("SapBase", "BASE", data.nonDamagingAilment["Sap"].default, { type = "ActorCondition", actor = "enemy", var = "OnSappedGround" }) },
	["while a unique enemy is in your presence, drops shocked ground while moving, lasting (%d+) seconds"] = { mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "ActorCondition", actor = "enemy", var = "OnShockedGround" }, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }) },
	["while a unique enemy is in your presence, drops scorched ground while moving, lasting (%d+) seconds"] = { mod("ScorchBase", "BASE", data.nonDamagingAilment["Scorch"].default, { type = "ActorCondition", actor = "enemy", var = "OnScorchedGround" }, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }) },
	["while a unique enemy is in your presence, drops brittle ground while moving, lasting (%d+) seconds"] = { mod("BrittleBase", "BASE", data.nonDamagingAilment["Brittle"].default, { type = "ActorCondition", actor = "enemy", var = "OnBrittleGround" }, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }) },
	["while a unique enemy is in your presence, drops sapped ground while moving, lasting (%d+) seconds"] = { mod("SapBase", "BASE", data.nonDamagingAilment["Sap"].default, { type = "ActorCondition", actor = "enemy", var = "OnSappedGround" }, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }) },
	["while a pinnacle atlas boss is in your presence, drops shocked ground while moving, lasting (%d+) seconds"] = { mod("ShockBase", "BASE", data.nonDamagingAilment["Shock"].default, { type = "ActorCondition", actor = "enemy", var = "OnShockedGround" }, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }) },
	["while a pinnacle atlas boss is in your presence, drops scorched ground while moving, lasting (%d+) seconds"] = { mod("ScorchBase", "BASE", data.nonDamagingAilment["Scorch"].default, { type = "ActorCondition", actor = "enemy", var = "OnScorchedGround" }, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }) },
	["while a pinnacle atlas boss is in your presence, drops brittle ground while moving, lasting (%d+) seconds"] = { mod("BrittleBase", "BASE", data.nonDamagingAilment["Brittle"].default, { type = "ActorCondition", actor = "enemy", var = "OnBrittleGround" }, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }) },
	["while a pinnacle atlas boss is in your presence, drops sapped ground while moving, lasting (%d+) seconds"] = { mod("SapBase", "BASE", data.nonDamagingAilment["Sap"].default, { type = "ActorCondition", actor = "enemy", var = "OnSappedGround" }, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }) },
	["%+(%d+)%% chance to ignite, freeze, shock, and poison cursed enemies"] = function(num) return {
		mod("EnemyIgniteChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Cursed" }),
		mod("EnemyFreezeChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Cursed" }),
		mod("EnemyShockChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Cursed" }),
		mod("PoisonChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Cursed" }),
	} end,
	["you have scorching conflux, brittle conflux and sapping conflux while your two highest attributes are equal"] = {
		mod("EnemyScorchChance", "BASE", 100, { type = "Condition", var = "TwoHighestAttributesEqual" }),
		mod("EnemyBrittleChance", "BASE", 100, { type = "Condition", var = "TwoHighestAttributesEqual" }),
		mod("EnemySapChance", "BASE", 100, { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("PhysicalCanScorch", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("LightningCanScorch", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("ColdCanScorch", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("ChaosCanScorch", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("PhysicalCanBrittle", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("LightningCanBrittle", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("FireCanBrittle", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("ChaosCanBrittle", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("PhysicalCanSap", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("ColdCanSap", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("FireCanSap", { type = "Condition", var = "TwoHighestAttributesEqual" }),
		flag("ChaosCanSap", { type = "Condition", var = "TwoHighestAttributesEqual" }),
	},
	["all damage from cold snap and creeping frost can sap"] = {
		flag("PhysicalCanSap", { type = "SkillName", skillNameList = { "Cold Snap", "Creeping Frost" }, includeTransfigured = true}),
		flag("ColdCanSap", { type = "SkillName", skillNameList = { "Cold Snap", "Creeping Frost" }, includeTransfigured = true}),
		flag("FireCanSap", { type = "SkillName", skillNameList = { "Cold Snap", "Creeping Frost" }, includeTransfigured = true}),
		flag("ChaosCanSap", { type = "SkillName", skillNameList = { "Cold Snap", "Creeping Frost" }, includeTransfigured = true}),
	},
	["always inflict scorch, brittle and sapped with elemental hit and wild strike hits"] = {
		mod("EnemyScorchChance", "BASE", 100, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" }, includeTransfigured = true}),
		mod("EnemyBrittleChance", "BASE", 100, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" }, includeTransfigured = true}),
		mod("EnemySapChance", "BASE", 100, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" }, includeTransfigured = true}),
	},
	["critical strikes do not inherently apply non%-damaging ailments"] = {
		flag("CritsDontAlwaysChill"),
		flag("CritsDontAlwaysFreeze"),
		flag("CritsDontAlwaysShock"),
	},
	["critical strikes do not inherently ignite"] = {
		flag("CritsDontAlwaysIgnite")
	},
	["always scorch while affected by anger"] = { mod("EnemyScorchChance", "BASE", 100, { type = "Condition", var = "AffectedByAnger" }) },
	["always inflict brittle while affected by hatred"] = {	mod("EnemyBrittleChance", "BASE", 100, { type = "Condition", var = "AffectedByHatred" }) },
	["always sap while affected by wrath"] = { mod("EnemySapChance", "BASE", 100, { type = "Condition", var = "AffectedByWrath" }) },
	["(%d+)%% chance to sap enemies in chilling areas"] = function(num) return { mod("EnemySapChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "InChillingArea" }) } end,
	["(%d+)%% chance for cold snap and creeping frost to sap enemies in chilling areas"] = function(num) return { mod("EnemySapChance", "BASE", num, { type = "SkillName", skillNameList = { "Cold Snap", "Creeping Frost" }, includeTransfigured = true }, { type = "ActorCondition", actor = "enemy", var = "InChillingArea" })} end,
	["drops burning ground while moving, dealing (%d+) fire damage per second for %d+ seconds"] = function(num) return { mod("DropsBurningGround", "BASE", num) } end,
	["take (%d+) fire damage per second while flame%-touched"] = function(num) return { mod("FireDegen", "BASE", num, { type = "Condition", var = "AffectedByApproachingFlames" }) } end,
	["gain adrenaline when you become flame%-touched"] = { flag("Condition:Adrenaline", { type = "Condition", var = "AffectedByApproachingFlames" }) },
	["lose adrenaline when you cease to be flame%-touched"] = { },
	["modifiers to ignite duration on you apply to all elemental ailments"] = { flag("IgniteDurationAppliesToElementalAilments") },
	["chance to avoid being shocked applies to all elemental ailments"] = { flag("ShockAvoidAppliesToElementalAilments") }, -- typo / old wording change
	["modifiers to chance to avoid being shocked apply to all elemental ailments"] = { flag("ShockAvoidAppliesToElementalAilments") },
	["enemies permanently take (%d+)%% increased damage for each second they've ever been frozen by you, up to a maximum of (%d+)%%"] = function(num, _, limit) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "FrozenByYou" }, { type = "Multiplier", var = "FrozenByYouSeconds", limit = limit / num }) }) } end,
	["enemies permanently take (%d+)%% increased damage for each second they've ever been chilled by you, up to a maximum of (%d+)%%"] = function(num, _, limit) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "ChilledByYou" }, { type = "Multiplier", var = "ChilledByYouSeconds", limit = limit / num }) }) } end,
	["modifiers to chance to suppress spell damage also apply to chance to avoid elemental ailments at (%d+)%% of their value"] = function(num) return {
		mod("SpellSuppressionAppliesToAilmentAvoidancePercent", "BASE", num),
		flag("SpellSuppressionAppliesToAilmentAvoidance")
	} end,
	["enemies chilled by your hits have damage taken increased by chill effect"] = { flag("ChillEffectIncDamageTaken") },
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
	["bleeding you inflict on non%-bleeding enemies deals (%d+)%% more damage"] = function(num) return {
		mod("Damage", "MORE", num, nil, 0, KeywordFlag.Bleed, { type = "Condition", var = "SingleBleed" }),
	} end,
	["(%d+)%% chance for bleeding inflicted with this weapon to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Bleed, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	} end,
	["(%d+)%% chance for bleeding inflicted with cobra lash or venom gyre to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Bleed, { type = "SkillName", skillNameList = { "Cobra Lash", "Venom Gyre" } }),
	} end,
	["bleeding you inflict deals damage (%d+)%% faster per frenzy charge"] = function(num) return { mod("BleedFaster", "INC", num, { type = "Multiplier", var = "FrenzyCharge" }) } end,
	["rain of arrows and toxic rain deal (%d+)%% more damage with bleeding"] = function(num) return {
		mod("Damage", "MORE", num, nil, 0, KeywordFlag.Bleed, { type = "SkillName", skillNameList = { "Rain of Arrows", "Toxic Rain" }, includeTransfigured = true }),
	} end,
	-- Impale and Bleed
	["(%d+)%% increased effect of impales inflicted by hits that also inflict bleeding"] = function(num) return {
		mod("ImpaleEffectOnBleed", "INC", num, nil, 0, KeywordFlag.Hit)
	} end,
	["(%d+)%% chance for blade vortex and blade blast to impale enemies on hit"] = function(num) return {  mod("ImpaleChance", "BASE", num, { type = "SkillName", skillNameList = { "Blade Vortex", "Blade Blast" }, includeTransfigured = true }) } end,
	["critical strikes with spells inflict impale"] = { mod("ImpaleChance", "BASE", 100, nil, ModFlag.Spell, { type = "Condition", var = "CriticalStrike" }) },
	["(%d+)%% chance on hitting an enemy for all impales on that enemy to last for an additional hit"] = function(num) return {
		mod("ImpaleAdditionalDurationChance", "BASE", num)
	} end,
	-- Poison and Bleed
	["(%d+)%% increased damage with bleeding inflicted on poisoned enemies"] = function(num) return {
		mod("Damage", "INC", num, nil, 0, KeywordFlag.Bleed, { type = "ActorCondition", actor = "enemy", var = "Poisoned" })
	} end,
	-- Poison
	["y?o?u?r? ?fire damage can poison"] = { flag("FireCanPoison") },
	["y?o?u?r? ?cold damage can poison"] = { flag("ColdCanPoison") },
	["y?o?u?r? ?lightning damage can poison"] = { flag("LightningCanPoison") },
	["all damage from hits can poison"] = {
		flag("FireCanPoison"),
		flag("ColdCanPoison"),
		flag("LightningCanPoison"),
	},
	["all damage can poison"] = {
		flag("FireCanPoison"),
		flag("ColdCanPoison"),
		flag("LightningCanPoison"),
	},
	["all damage from hits with this weapon can poison"] = {
		flag("FireCanPoison", { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
		flag("ColdCanPoison", { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
		flag("LightningCanPoison", { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack })
	},
	["all damage inflicts poison while affected by glorious madness"] = {
		mod("PoisonChance", "BASE", 100, { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("FireCanPoison", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("ColdCanPoison", { type = "Condition", var = "AffectedByGloriousMadness" }),
		flag("LightningCanPoison", { type = "Condition", var = "AffectedByGloriousMadness" })
	},
	["all damage from blast rain and artillery ballista hits can poison"] = {
		flag("FireCanPoison", { type = "SkillName", skillNameList = { "Blast Rain", "Artillery Ballista" } }),
		flag("ColdCanPoison", { type = "SkillName", skillNameList = { "Blast Rain", "Artillery Ballista" } }),
		flag("LightningCanPoison", { type = "SkillName", skillNameList = { "Blast Rain", "Artillery Ballista" } })
	},
	["all damage from hits with freezing pulse and eye of winter can poison"] = {
		flag("FireCanPoison", { type = "SkillName", skillNameList = { "Freezing Pulse", "Eye of Winter" }, includeTransfigured = true }),
		flag("ColdCanPoison", { type = "SkillName", skillNameList = { "Freezing Pulse", "Eye of Winter" }, includeTransfigured = true }),
		flag("LightningCanPoison", { type = "SkillName", skillNameList = { "Freezing Pulse", "Eye of Winter" }, includeTransfigured = true })
	},
	["your chaos damage poisons enemies"] = { mod("ChaosPoisonChance", "BASE", 100) },
	["your chaos damage has (%d+)%% chance to poison enemies"] = function(num) return { mod("ChaosPoisonChance", "BASE", num) } end,
	["melee attacks poison on hit"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Melee) },
	["melee critical strikes have (%d+)%% chance to poison the enemy"] = function(num) return { mod("PoisonChance", "BASE", num, nil, ModFlag.Melee, { type = "Condition", var = "CriticalStrike" }) } end,
	["critical strikes with daggers have a (%d+)%% chance to poison the enemy"] = function(num) return { mod("PoisonChance", "BASE", num, nil, ModFlag.Dagger, { type = "Condition", var = "CriticalStrike" }) } end,
	["critical strikes with daggers poison the enemy"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Dagger, { type = "Condition", var = "CriticalStrike" }) },
	["poison cursed enemies on hit"] = { mod("PoisonChance", "BASE", 100, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) },
	["always poison on hit against cursed enemies"] = { mod("PoisonChance", "BASE", 100, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) },
	["wh[ie][ln]e? at maximum frenzy charges, attacks poison enemies"] = { mod("PoisonChance", "BASE", 100, nil, ModFlag.Attack, { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["traps and mines have a (%d+)%% chance to poison on hit"] = function(num) return { mod("PoisonChance", "BASE", num, nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["poisons you inflict deal damage (%d+)%% faster"] = function(num) return { mod("PoisonFaster", "INC", num) } end,
	["(%d+)%% chance for poisons inflicted with this weapon to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	} end,
	["(%d+)%% chance for poisons inflicted with blast rain or artillery balls?i?s?ta to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Poison, { type = "SkillName", skillNameList = { "Blast Rain", "Artillery Ballista" } }),
	} end,
	["(%d+)%% chance for poisons inflicted with freezing pulse and eye of winter to deal (%d+)%% more damage"] = function(num, _, more) return {
		mod("Damage", "MORE", tonumber(more) * num / 100, nil, 0, KeywordFlag.Poison, { type = "SkillName", skillNameList = { "Freezing Pulse", "Eye of Winter" }, includeTransfigured = true }),
	} end,

	["poisons you inflict on non%-poisoned enemies deal (%d+)%% increased damage"] = function(num) return {
		mod("Damage", "INC", num, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "SinglePoison" })
	} end,
	["poisons inflicted by sunder or ground slam on non%-poisoned enemies deal (%d+)%% increased damage"] = function(num) return {
		mod("Damage", "INC", num, nil, 0, KeywordFlag.Poison, { type = "Condition", var = "SinglePoison" }, { type = "SkillName", skillNameList = { "Sunder", "Ground Slam" }, includeTransfigured = true })
	} end,
	["poisons on you expire (%d+)%% slower"] = function(num) return { mod("SelfPoisonDebuffExpirationRate", "BASE", -num) } end,
	-- Suppression
	["y?o?u?r? ?chance to suppress spell damage is lucky"] = { flag("SpellSuppressionChanceIsLucky") },
	["y?o?u?r? ?chance to suppress spell damage is unlucky"] = { flag("SpellSuppressionChanceIsUnlucky") },
	["prevent %+(%d+)%% of suppressed spell damage"] = function(num) return { mod("SpellSuppressionEffect", "BASE", num) } end,
	["prevent %+(%d+)%% of suppressed spell damage per hit suppressed recently"] = function(num) return {
	    mod("SpellSuppressionEffect", "BASE", num, { type = "Multiplier", var = "HitsSuppressedRecently" })
	} end,
	["inflict fire, cold and lightning exposure on enemies when you suppress their spell damage"] = {
	    mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "SuppressedRecently" }),
	    mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "SuppressedRecently" }),
	    mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "SuppressedRecently" })
	},
	["critical strike chance is increased by chance to suppress spell damage"] = { flag("CritChanceIncreasedBySpellSuppressChance") },
	["you take (%d+)%% reduced extra damage from suppressed critical strikes"] = function(num) return { mod("ReduceSuppressedCritExtraDamage", "BASE", num) } end,
	["+(%d+)%% chance to suppress spell damage if your e?q?u?i?p?p?e?d? ?boots, helmet and gloves have evasion"] = function(num) return {
		mod("SpellSuppressionChance", "BASE", tonumber(num),
			{ type = "StatThreshold", stat = "EvasionOnBoots", threshold = 1},
			{ type = "StatThreshold", stat = "EvasionOnHelmet", threshold = 1},
			{ type = "StatThreshold", stat = "EvasionOnGloves", threshold = 1}
		)
	} end,
	["evasion rating is doubled against projectile attacks"] = { mod("ProjectileEvasion", "MORE", 100) },
	["evasion rating is doubled against melee attacks"] = { mod("MeleeEvasion", "MORE", 100) },
	["+(%d+)%% chance to suppress spell damage for each dagger you're wielding"] = function(num) return {
		mod("SpellSuppressionChance", "BASE", num, nil, ModFlag.Dagger ),
		mod("SpellSuppressionChance", "BASE", num, nil, ModFlag.Dagger, { type = "Condition", var = "DualWieldingDaggers" })
	} end,
	-- Buffs/debuffs
	["phasing"] = { flag("Condition:Phasing") },
	["onslaught"] = { flag("Condition:Onslaught") },
	["rampage"] = { flag("Condition:Rampage") },
	["soul eater"] = { flag("Condition:CanHaveSoulEater") },
	["unholy might"] = { flag("Condition:UnholyMight"), flag("Condition:CanWither"), },
	["chaotic might"] = { flag("Condition:ChaoticMight") },
	["elusive"] = { flag("Condition:CanBeElusive") },
	["adrenaline"] = { flag("Condition:Adrenaline") },
	["arcane surge"] = { flag("Condition:ArcaneSurge") },
	["your aura buffs do not affect allies"] = { flag("SelfAurasCannotAffectAllies") },
	["your curses have (%d+)%% increased effect if (%d+)%% of curse duration expired"] = function(num, _, limit) return {
		mod("CurseEffect", "INC", num, { type = "MultiplierThreshold", actor = "enemy", var = "CurseExpired", threshold = tonumber(limit) }, { type = "SkillType", skillType =  SkillType.Hex })
	} end,
	["non%-aura hexes expire upon reaching (%d+)%% of base effect non%-aura hexes gain (%d+)%% increased effect per second"] = function(limit, _, num) return {
		mod("CurseEffect", "INC", tonumber(num), { type = "Multiplier", actor = "enemy", var = "CurseDurationExpired", limit = tonumber(limit), limitTotal = true }, { type = "SkillType", skillType = SkillType.Aura, neg = true }, { type = "SkillType", skillType =  SkillType.Hex })
	} end,
	["enemies cursed by you have malediction if (%d+)%% of curse duration expired"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = flag("HasMalediction", { type = "MultiplierThreshold", var = "CurseExpired", threshold = tonumber(num) }, { type = "ActorCondition", var = "Cursed" }) }),
	} end,
	["auras from your skills can only affect you"] = { flag("SelfAurasOnlyAffectYou") },
	["aura buffs from skills have (%d+)%% increased effect on you for each herald affecting you"] = function(num) return { mod("SkillAuraEffectOnSelf", "INC", num, { type = "Multiplier", var = "Herald" }) } end,
	["aura buffs from skills have (%d+)%% increased effect on you for each herald affecting you, up to (%d+)%%"] = function(num, _, limit) return {
		mod("SkillAuraEffectOnSelf", "INC", num, { type = "Multiplier", var = "Herald", globalLimit = tonumber(limit), globalLimitKey = "PurposefulHarbinger" })
	} end,
	["auras from your skills have (%d+)%% increased effect on you for each herald affecting you, up to (%d+)%%"] = function(num, _, limit) return {
		mod("SkillAuraEffectOnSelf", "INC", num, { type = "Multiplier", var = "Herald", globalLimit = tonumber(limit), globalLimitKey = "PurposefulHarbinger" })
	} end,
	["(%d+)%% increased area of effect per power charge, up to a maximum of (%d+)%%"] = function(num, _, limit) return {
		mod("AreaOfEffect", "INC", num, { type = "Multiplier", var = "PowerCharge", globalLimit = tonumber(limit), globalLimitKey = "VastPower" })
	} end,
	["(%d+)%% increased chaos damage per (%d+) maximum mana, up to a maximum of (%d+)%%"] = function(num, _, div, limit) return {
		mod("ChaosDamage", "INC", num, { type = "PerStat", stat = "Mana", div = tonumber(div), globalLimit = tonumber(limit), globalLimitKey = "DarkIdeation" })
	} end,
	["minions have %+(%d+)%% to damage over time multiplier per ghastly eye jewel affecting you, up to a maximum of %+(%d+)%%"] = function(num, _, limit) return {
		mod("MinionModifier", "LIST", { mod = mod("DotMultiplier", "BASE", num, { type = "Multiplier", var = "GhastlyEyeJewel", actor = "parent", globalLimit = tonumber(limit), globalLimitKey = "AmanamuGaze" }) })
	} end,
	["(%d+)%% increased effect of arcane surge on you per hypnotic eye jewel affecting you, up to a maximum of (%d+)%%"] = function(num, _, limit) return {
		mod("ArcaneSurgeEffect", "INC", num, { type = "Multiplier", var = "HypnoticEyeJewel", globalLimit = tonumber(limit), globalLimitKey = "KurgalGaze" })
	} end,
	["(%d+)%% increased main hand critical strike chance per murderous eye jewel affecting you, up to a maximum of (%d+)%%"] = function(num, _, limit) return {
		mod("CritChance", "INC", num, { type = "Multiplier", var = "MurderousEyeJewel", globalLimit = tonumber(limit), globalLimitKey = "TecrodGazeMainHand" }, { type = "Condition", var = "MainHandAttack" })
	} end,
	["%+(%d+)%% to off hand critical strike multiplier per murderous eye jewel affecting you, up to a maximum of %+(%d+)%%"] = function(num, _, limit) return {
		mod("CritMultiplier", "BASE", num, { type = "Multiplier", var = "MurderousEyeJewel", globalLimit = tonumber(limit), globalLimitKey = "TecrodGazeOffHand" }, { type = "Condition", var = "OffHandAttack" })
	} end,
	["nearby allies' damage with hits is lucky"] = { mod("ExtraAura", "LIST", { onlyAllies = true, mod = flag("LuckyHits") }) },
	["your damage with hits is lucky"] = { flag("LuckyHits") },
	["elemental damage with hits is lucky while you are shocked"] = { flag("ElementalLuckHits", { type = "Condition", var = "Shocked" }) },
	["allies' aura buffs do not affect you"] = { flag("AlliesAurasCannotAffectSelf") },
	["(%d+)%% increased effect of non%-curse auras from your skills on enemies"] = function(num) return {
		mod("DebuffEffect", "INC", num, { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true }),
		mod("AuraEffect", "INC", num, { type = "SkillName", skillName = "Death Aura" }),
	} end,
	["enemies can have 1 additional curse"] = { mod("EnemyCurseLimit", "BASE", 1) },
	["you can apply an additional curse"] = { mod("EnemyCurseLimit", "BASE", 1) },
	["you can apply an additional curse while affected by malevolence"] = { mod("EnemyCurseLimit", "BASE", 1, { type = "Condition", var = "AffectedByMalevolence" }) },
	["you can apply an additional curse while at maximum power charges"] = { mod("EnemyCurseLimit", "BASE", 1, { type = "StatThreshold", stat = "PowerCharges", thresholdStat = "PowerChargesMax" }) },
	["you can apply one fewer curse"] = { mod("EnemyCurseLimit", "BASE", -1) },
	["curses on enemies in your chilling areas have (%d+)%% increased effect"] = function(num) return { mod("CurseEffect", "INC", num, { type = "ActorCondition", actor = "enemy", var = "InChillingArea" }) } end,
	["hexes you inflict have their effect increased by twice their doom instead"] = { mod("DoomEffect", "MORE", 100) },
	["nearby enemies have an additional (%d+)%% chance to receive a critical strike"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("SelfExtraCritChance", "BASE", num) }) } end,
	["nearby enemies have (%-%d+)%% to all resistances"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("ElementalResist", "BASE", num) }),
		mod("EnemyModifier", "LIST", { mod = mod("ChaosResist", "BASE", num) }),
	} end,
	["enemies ignited or chilled by you have (%-%d+)%% to elemental resistances"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("ElementalResist", "BASE", num )}, { type = "ActorCondition", actor = "enemy", varList = { "Ignited", "Chilled" } })
	} end,
	["reserves (%d+)%% of nearby enemy monsters' life"] = function(num) return {mod("EnemyModifier", "LIST", { mod = mod("LifeReservationPercent", "BASE", num) })} end,
	["nearby enemy monsters have at least (%d+)%% of life reserved"] = function(num) return {mod("EnemyModifier", "LIST", { mod = mod("LifeReservationPercent", "BASE", num) })} end,
	["your hits inflict decay, dealing (%d+) chaos damage per second for %d+ seconds"] = function(num) return { mod("SkillData", "LIST", { key = "decay", value = num, merge = "MAX" }) } end,
	["inflict decay on enemies you curse with hex or mark skills, dealing (%d+) chaos damage per second for %d+ seconds"] = function(num) return { -- typo never existed except in some items generated by PoB
		mod("SkillData", "LIST", { key = "decay", value = num, merge = "MAX" }, { type = "ActorCondition", actor = "enemy", var = "Cursed" })
	} end,
	["inflict decay on enemies you curse with hex skills, dealing (%d+) chaos damage per second for %d+ seconds"] = function(num) return {
		mod("SkillData", "LIST", { key = "decay", value = num, merge = "MAX" }, { type = "ActorCondition", actor = "enemy", var = "Cursed" })
	} end,
	["temporal chains has (%d+)%% reduced effect on you"] = function(num) return { mod("CurseEffectOnSelf", "INC", -num, { type = "SkillName", skillName = "Temporal Chains" }) } end,
	["unaffected by temporal chains"] = { mod("CurseEffectOnSelf", "MORE", -100, { type = "SkillName", skillName = "Temporal Chains" }, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["([%+%-][%d%.]+) seconds to cat's stealth duration"] = function(num) return { mod("PrimaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Cat" }) } end,
	["([%+%-][%d%.]+) seconds to cat's agility duration"] = function(num) return { mod("SecondaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Cat" }) } end,
	["([%+%-][%d%.]+) seconds to avian's might duration"] = function(num) return { mod("PrimaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Avian" }) } end,
	["([%+%-][%d%.]+) seconds to avian's flight duration"] = function(num) return { mod("SecondaryDuration", "BASE", num, { type = "SkillName", skillName = "Aspect of the Avian" }) } end,
	["aspect of the spider can inflict spider's web on enemies an additional time"] = { mod("ExtraSkillMod", "LIST", { mod = mod("Multiplier:SpiderWebApplyStackMax", "BASE", 1) }, { type = "SkillName", skillName = "Aspect of the Spider" }) },
	["aspect of the avian also grants avian's might and avian's flight to nearby allies"] = { mod("ExtraSkillMod", "LIST", { mod = flag("BuffAppliesToAllies") }, { type = "SkillName", skillName = "Aspect of the Avian" }) },
	["marked enemy takes (%d+)%% increased damage"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }, {type = "ActorCondition", actor = "enemy", var = "Marked" }),
	} end,
	["marked enemy has (%d+)%% reduced accuracy rating"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("Accuracy", "INC", -num) }, {type = "ActorCondition", actor = "enemy", var = "Marked" }),
	} end,
	["you are cursed with level (%d+) (%D+)"] = function(num, _, name) return { mod("ExtraCurse", "LIST", { skillId = gemIdLookup[name], level = num, applyToPlayer = true }) } end,
	["you are cursed with (%D+)"] = function(_, skill) return { mod("ExtraCurse", "LIST", { skillId = gemIdLookup[skill], level = 1, applyToPlayer = true }) } end,
	["you are cursed with (%D+), with (%d+)%% increased effect"] = function(_, skill, num) return {
		mod("ExtraCurse", "LIST", { skillId = gemIdLookup[skill], level = 1, applyToPlayer = true }),
		mod("CurseEffectOnSelf", "INC", tonumber(num), { type = "SkillName", skillName = string.gsub(" "..skill, "%W%l", string.upper):sub(2) }),
	} end,
	["you count as on low life while you are cursed with vulnerability"] = { flag("Condition:LowLife", { type = "Condition", var = "AffectedByVulnerability" }) },
	["you count as on full life while you are cursed with vulnerability"] = { flag("Condition:FullLife", { type = "Condition", var = "AffectedByVulnerability" }) },
	["if you consumed a corpse recently, you and nearby allies regenerate (%d+)%% of life per second"] = function (num) return { mod("ExtraAura", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "Condition", var = "ConsumedCorpseRecently" }) } end,
	["if you have blocked recently, you and nearby allies regenerate (%d+)%% of life per second"] = function (num) return { mod("ExtraAura", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "Condition", var = "BlockedRecently" }) } end,
	["you are at maximum chance to block attack damage if you have not blocked recently"] = { flag("MaxBlockIfNotBlockedRecently", { type = "Condition", var = "BlockedRecently", neg = true }) },
	["you are at maximum chance to block spell damage if you have not blocked recently"] = { flag("MaxSpellBlockIfNotBlockedRecently", { type = "Condition", var = "BlockedRecently", neg = true }) },
	["%+(%d+)%% chance to block attack damage if you have not blocked recently"] = function(num) return { mod("BlockChance", "BASE", num, { type = "Condition", var = "BlockedRecently", neg = true }) } end,
	["%+(%d+)%% chance to block spell damage if you have not blocked recently"] = function(num) return { mod("SpellBlockChance", "BASE", num, { type = "Condition", var = "BlockedRecently", neg = true }) } end,
	["([%d%.]+)%% of evasion rating is regenerated as life per second while focus?sed"] = function(num) return { mod("LifeRegen", "BASE", 1, { type = "PercentStat", stat = "Evasion", percent = num }, { type = "Condition", var = "Focused" }) } end,
	["nearby allies have (%d+)%% increased defences per (%d+) strength you have"] = function(num, _, div) return { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("Defences", "INC", num) }, { type = "PerStat", stat = "Str", div = tonumber(div) }) } end,
	["nearby allies have %+(%d+)%% to critical strike multiplier per (%d+) dexterity you have"] = function(num, _, div) return { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("CritMultiplier", "BASE", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["nearby allies have (%d+)%% increased cast speed per (%d+) intelligence you have"] = function(num, _, div) return { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("Speed", "INC", num, nil, ModFlag.Cast ) }, { type = "PerStat", stat = "Int", div = tonumber(div) }) } end,
	["quicksilver flasks you use also apply to nearby allies"] = { flag("QuickSilverAppliesToAllies") },
	["you gain divinity for %d+ seconds on reaching maximum divine charges"] = {
		mod("ElementalDamage", "MORE", 50, { type = "Condition", var = "Divinity" }),
		mod("ElementalDamageTaken", "MORE", -20, { type = "Condition", var = "Divinity" }),
	},
	["your nearby party members maximum endurance charges is equal to yours"] = { flag("PartyMemberMaximumEnduranceChargesEqualToYours") },
	["your maximum endurance charges is equal to your maximum frenzy charges"] = { flag("MaximumEnduranceChargesIsMaximumFrenzyCharges") },
	["your maximum frenzy charges is equal to your maximum power charges"] = { flag("MaximumFrenzyChargesIsMaximumPowerCharges") },
	["your curse limit is equal to your maximum power charges"] = { flag("CurseLimitIsMaximumPowerCharges") },
	["consecrated ground you create while affected by zealotry causes enemies to take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTakenConsecratedGround", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "OnConsecratedGround" }, { type = "Condition", var = "AffectedByZealotry" }) } end,
	["if you've warcried recently, you and nearby allies have (%d+)%% increased attack, cast and movement speed"] = function(num) return {
		mod("ExtraAura", "LIST", { mod = mod("Speed", "INC", num) }, { type = "Condition", var = "UsedWarcryRecently" }),
		mod("ExtraAura", "LIST", { mod = mod("MovementSpeed", "INC", num) }, { type = "Condition", var = "UsedWarcryRecently" }),
	} end,
	["(%d+)%% increased movement speed while on full life"] = function(num) return { mod("MovementSpeed", "INC", num, { type = "Condition", var = "FullLife" }) } end,
	["when you warcry, you and nearby allies gain onslaught for 4 seconds"] = { mod("ExtraAura", "LIST", { mod = flag("Onslaught") }, { type = "Condition", var = "UsedWarcryRecently" }) },
	["warcries grant arcane surge to you and allies, with (%d+)%% increased effect per (%d+) power, up to (%d+)%%"] = function(num, _, div, limit) return {
		mod("ExtraAura", "LIST", { mod = flag("Condition:ArcaneSurge")}, { type = "Condition", var = "UsedWarcryRecently" }),
		mod("ArcaneSurgeEffect", "INC", num, { type = "PerStat", stat = "WarcryPower", div = tonumber(div), globalLimit = tonumber(limit), globalLimitKey = "Brinerot Flag"}, { type = "Condition", var = "UsedWarcryRecently" }),
	} end,
	["gain arcane surge after spending a total of (%d+) mana"] = function(num) return {
		mod("ExtraAura", "LIST", { mod = flag("Condition:ArcaneSurge")}, { type = "MultiplierThreshold", var = "ManaSpentRecently", threshold = num }),
	} end,
	["gain onslaught for (%d+) seconds on hit while at maximum frenzy charges"] = { flag("Onslaught", { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }, { type = "Condition", var = "HitRecently" }) },
	["enemies in your chilling areas take (%d+)%% increased lightning damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("LightningDamageTaken", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "InChillingArea" }) } end,
	["warcries count as having (%d+) additional nearby enemies"] = function(num) return {
		mod("Multiplier:WarcryNearbyEnemies", "BASE", num),
	} end,
	["enemies taunted by your warcries take (%d+)%% increased damage"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Condition", var = "Taunted" }) }, { type = "Condition", var = "UsedWarcryRecently" }) } end,
	["warcries share their cooldown"] = { flag("WarcryShareCooldown") },
	["warcries have minimum of (%d+) power"] = { flag("CryWolfMinimumPower") },
	["warcries have infinite power"] = { flag("WarcryInfinitePower") },
	["(%d+)%% chance to inflict corrosion on hit with attacks"] = { flag("Condition:CanCorrode") },
	["(%d+)%% chance to inflict withered for (%d+) seconds on hit"] = { flag("Condition:CanWither") },
	["inflict withered for (%d+) seconds on hit if you've cast (.-) in the past (%d+) seconds"] = function (_, _, curse) return { flag("Condition:CanWither", { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") }) } end,
	["(%d+)%% chance to inflict withered for (%d+) seconds on hit with this weapon"] = { flag("Condition:CanWither") },
	["(%d+)%% chance to inflict withered for two seconds on hit if there are (%d+) or fewer withered debuffs on enemy"] = { flag("Condition:CanWither") },
	["inflict withered for (%d+) seconds on hit with this weapon"] = { flag("Condition:CanWither") },
	["minions have (%d+)%% chance to inflict withered on hit"] = { mod("MinionModifier", "LIST", { mod = flag("Condition:CanWither") }) },
	["enemies take (%d+)%% increased elemental damage from your hits for each withered you have inflicted on them"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("ElementalDamageTaken", "INC", num, { type = "Multiplier", var = "WitheredStack", limit = 15 }) }) } end,
	["your hits cannot penetrate or ignore elemental resistances"] = { flag("CannotElePenIgnore") },
	["nearby enemies have malediction"] = { mod("EnemyModifier", "LIST", { mod = flag("HasMalediction") }) },
	["gain shaper's presence for 10 seconds when you kill a rare or unique enemy"] = { mod("ExtraAura", "LIST", { mod = flag("HasShapersPresence") }, { type = "Condition", var = "KilledUniqueEnemy" }) },
	["gain maddening presence for 10 seconds when you kill a rare or unique enemy"] = { mod("EnemyModifier", "LIST", { mod = flag("HasMaddeningPresence") }, { type = "Condition", var = "KilledUniqueEnemy" }) },
	["elemental damage you deal with hits is resisted by lowest elemental resistance instead"] = { flag("ElementalDamageUsesLowestResistance") },
	["you take (%d+) chaos damage per second for 3 seconds on kill"] = function(num) return { mod("ChaosDegen", "BASE", num, { type = "Condition", var = "KilledLast3Seconds" }) } end,
	["regenerate (%d+) life per second for each (%d+)%% uncapped fire resistance"] = function(num, _, percent) return { mod("LifeRegen", "BASE", num, { type = "PerStat", stat = "FireResistTotal", div = 1 / percent }) } end,
	["regenerate (%d+) life over 1 second for each spell you cast"] = function(num) return { mod("LifeRegen", "BASE", num, { type = "Condition", var = "CastLast1Seconds" }) } end,
	["and nearby allies regenerate (%d+) life per second"] = function(num) return { mod("ExtraAura", "LIST", { mod = mod("LifeRegen", "BASE", num) }, { type = "Condition", var = "KilledPoisonedLast2Seconds" }) } end,
	["(%d+)%% increased life regeneration rate"] = function(num) return { mod("LifeRegen", "INC", num) } end,
	["every (%d+) seconds, regenerate life equal to (%d+)%% of armour and evasion rating over (%d+) second"] = function (interval, _, percent, duration) return {
		mod("LifeRegen", "BASE", 1, { type = "Condition", var = "LifeRegenBurstFull" }, { type = "PercentStat", stat = "Armour", percent = percent }),
		mod("LifeRegen", "BASE", 1 / interval * duration, { type = "Condition", var = "LifeRegenBurstAvg" }, { type = "PercentStat", stat = "Armour", percent = percent }),
		mod("LifeRegen", "BASE", 1, { type = "Condition", var = "LifeRegenBurstFull" }, { type = "PercentStat", stat = "Evasion", percent = percent }),
		mod("LifeRegen", "BASE", 1 / interval * duration, { type = "Condition", var = "LifeRegenBurstAvg" }, { type = "PercentStat", stat = "Evasion", percent = percent }),
	} end,
	["every (%d+) seconds, regenerate energy shield equal to (%d+)%% of evasion rating over (%d+) second"] = function (interval, _, percent, duration) return {
		mod("EnergyShieldRegen", "BASE", 1, { type = "Condition", var = "LifeRegenBurstFull" }, { type = "PercentStat", stat = "Evasion", percent = percent }),
		mod("EnergyShieldRegen", "BASE", 1 / interval * duration, { type = "Condition", var = "LifeRegenBurstAvg" }, { type = "PercentStat", stat = "Evasion", percent = percent }),
	} end,
	["regenerate (%d+)%% of life per second for each different ailment affecting you"] = function(num) return {
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Bleeding" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Ignited" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Scorched" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Chilled" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Frozen" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Brittle" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Shocked" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Sapped" }),
		mod("LifeRegenPercent", "BASE", num , { type = "Condition", var = "Poisoned" }),
	} end,
	["fire skills have a (%d+)%% chance to apply fire exposure on hit"] = function(num) return { mod("FireExposureChance", "BASE", num) } end,
	["cold skills have a (%d+)%% chance to apply cold exposure on hit"] = function(num) return { mod("ColdExposureChance", "BASE", num) } end,
	["lightning skills have a (%d+)%% chance to apply lightning exposure on hit"] = function(num) return { mod("LightningExposureChance", "BASE", num) } end,
	["(%d+)%% chance to inflict cold exposure on hit with cold damage"] = function(num) return { mod("ColdExposureChance", "BASE", num) } end,
	["socketed skills apply fire, cold and lightning exposure on hit"] = {
		mod("FireExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
		mod("ColdExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
		mod("LightningExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
	},
	["inflict fire, cold, and lightning exposure on hit"] = {
		mod("FireExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
		mod("ColdExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
		mod("LightningExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
	},
	["inflict fire exposure on hit"] = {
		mod("FireExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
	},
	["inflict cold exposure on hit"] = {
		mod("ColdExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
	},
	["inflict lightning exposure on hit"] = {
		mod("LightningExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
	},
	["nearby enemies have fire exposure"] = {
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }),
	},
	["nearby enemies have cold exposure"] = {
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }),
	},
	["nearby enemies have lightning exposure"] = {
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }),
	},
	["nearby enemies have fire exposure while you are affected by herald of ash"] = {
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "AffectedByHeraldofAsh" }),
	},
	["nearby enemies have cold exposure while you are affected by herald of ice"] = {
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "AffectedByHeraldofIce" }),
	},
	["nearby enemies have lightning exposure while you are affected by herald of thunder"] = {
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "AffectedByHeraldofThunder" }),
	},
	["i?n?f?l?i?c?t? ?(%a-) exposure on hit if you've cast (.-) in the past (%d+) seconds"] = function (_, exposureType, curse) return {
		mod("EnemyModifier", "LIST", { mod = mod(exposureType:gsub("^%l", string.upper).."Exposure", "BASE", -10) }, nil,  ModFlag.Hit, { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") }, { type = "Condition", var = "Effective" })
	} end,
	["inflict fire, cold and lightning exposure on nearby enemies when used"] = {
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "UsingFlask" }),
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "UsingFlask" }),
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -10) }, { type = "Condition", var = "Effective" }, { type = "Condition", var = "UsingFlask" }),
	},
	["enemies near your linked targets have fire, cold and lightning exposure"] = {
		mod("EnemyModifier", "LIST", { mod = mod("FireExposure", "BASE", -10, { type = "Condition", var = "NearLinkedTarget" }) }, { type = "Condition", var = "Effective" }),
		mod("EnemyModifier", "LIST", { mod = mod("ColdExposure", "BASE", -10, { type = "Condition", var = "NearLinkedTarget" }) }, { type = "Condition", var = "Effective" }),
		mod("EnemyModifier", "LIST", { mod = mod("LightningExposure", "BASE", -10, { type = "Condition", var = "NearLinkedTarget" }) }, { type = "Condition", var = "Effective" }),
	},
	["inflict (%w+) exposure on hit, applying %-(%d+)%% to (%w+) resistance"] = function(_, element1,  num, element2) return {
		mod( firstToUpper(element1).."ExposureChance", "BASE", 100, { type = "Condition", var = "Effective" }),
		mod("EnemyModifier", "LIST", { mod = mod(firstToUpper(element2).."Exposure", "BASE", -num) }, { type = "Condition", var = "Effective" }),
	} end,
	["while a unique enemy is in your presence, inflict (%w+) exposure on hit, applying %-(%d+)%% to (%w+) resistance"] = function(_, element1,  num, element2) return {
		mod( firstToUpper(element1).."ExposureChance", "BASE", 100, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }, { type = "Condition", var = "Effective" }),
		mod("EnemyModifier", "LIST", { mod = mod(firstToUpper(element2).."Exposure", "BASE", -num, { type = "Condition", var = "RareOrUnique" }) }, { type = "Condition", var = "Effective" }),
	} end,
	["while a pinnacle atlas boss is in your presence, inflict (%w+) exposure on hit, applying %-(%d+)%% to (%w+) resistance"] = function(_, element1,  num, element2) return {
		mod( firstToUpper(element1).."ExposureChance", "BASE", 100, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }, { type = "Condition", var = "Effective" }),
		mod("EnemyModifier", "LIST", { mod = mod(firstToUpper(element2).."Exposure", "BASE", -num, { type = "Condition", var = "PinnacleBoss" }) }, { type = "Condition", var = "Effective" }),
	} end,
	["fire exposure you inflict applies an extra (%-?%d+)%% to fire resistance"] = function(num) return { mod("ExtraFireExposure", "BASE", num) } end,
	["cold exposure you inflict applies an extra (%-?%d+)%% to cold resistance"] = function(num) return { mod("ExtraColdExposure", "BASE", num) } end,
	["lightning exposure you inflict applies an extra (%-?%d+)%% to lightning resistance"] = function(num) return { mod("ExtraLightningExposure", "BASE", num) } end,
	["exposure you inflict applies at least (%-%d+)%% to the affected resistance"] = function(num) return { mod("ExposureMin", "OVERRIDE", num) } end,
	["modifiers to minimum endurance charges instead apply to minimum brutal charges"] = { flag("MinimumEnduranceChargesEqualsMinimumBrutalCharges") },
	["modifiers to minimum frenzy charges instead apply to minimum affliction charges"] = { flag("MinimumFrenzyChargesEqualsMinimumAfflictionCharges") },
	["modifiers to minimum power charges instead apply to minimum absorption charges"] = { flag("MinimumPowerChargesEqualsMinimumAbsorptionCharges") },
	["maximum brutal charges is equal to maximum endurance charges"] = { flag("MaximumEnduranceChargesEqualsMaximumBrutalCharges") },
	["maximum affliction charges is equal to maximum frenzy charges"] = { flag("MaximumFrenzyChargesEqualsMaximumAfflictionCharges") },
	["maximum absorption charges is equal to maximum power charges"] = { flag("MaximumPowerChargesEqualsMaximumAbsorptionCharges") },
	["gain brutal charges instead of endurance charges"] = { flag("EnduranceChargesConvertToBrutalCharges") },
	["gain affliction charges instead of frenzy charges"] = { flag("FrenzyChargesConvertToAfflictionCharges") },
	["gain absorption charges instead of power charges"] = { flag("PowerChargesConvertToAbsorptionCharges") },
	["regenerate (%d+)%% life over one second when hit while sane"] = function(num) return {
		mod("LifeRegenPercent", "BASE", num, { type = "Condition", var = "Insane", neg = true }, { type = "Condition", var = "BeenHitRecently" }),
	} end,
	["you count as on low (%a+) while at (%d+)%% of maximum (%a+) or below"] = function(_, resourceType, numStr) return { mod("Low"..resourceType:gsub("^%l", string.upper).."Percentage", "BASE", tonumber(numStr) / 100.0) } end,
	["you count as on full (%a+) while at (%d+)%% of maximum (%a+) or above"] = function(_, resourceType, numStr) return { mod("Full"..resourceType:gsub("^%l", string.upper).."Percentage", "BASE", tonumber(numStr) / 100.0) } end,
	["(%d+)%% more maximum life if you have at least (%d+) life masteries allocated"] = function(num, _, thresh) return {
		mod("Life", "MORE", num, { type = "MultiplierThreshold", var = "AllocatedLifeMastery", threshold = tonumber(thresh) }),
	} end,
	["left ring slot: cover enemies in ash for 5 seconds when you ignite them"] = { mod("CoveredInAshEffect", "BASE", 20, { type = "SlotNumber", num = 1 }, { type = "ActorCondition", actor = "enemy", var = "Ignited" }) },
	["right ring slot: cover enemies in frost for 5 seconds when you freeze them"] = { mod("CoveredInFrostEffect", "BASE", 20, { type = "SlotNumber", num = 2 }, { type = "ActorCondition", actor = "enemy", var = "Frozen" }) },
	["nearby enemies are covered in ash"] = { mod("CoveredInAshEffect", "BASE", 20) },
	["enemies near targets you shatter have (%d+)%% chance to be covered in frost for (%d+) seconds"] = { mod("CoveredInFrostEffect", "BASE", 20, { type = "Condition", var = "ShatteredEnemyRecently" }) },
	["([%a%s]+) has (%d+)%% increased effect"] = function(_, skill, num) return { mod("BuffEffect", "INC", num, { type = "SkillId", skillId = gemIdLookup[skill]}) } end,
	["debuffs on you expire (%d+)%% faster"] = function(num) return { mod("SelfDebuffExpirationRate", "BASE", num) } end,
	["warcries debilitate enemies for (%d+) seconds?"] = { mod("DebilitateChance", "BASE", 100) },
	["debilitate enemies for (%d+) seconds? when you suppress their spell damage"] = { mod("DebilitateChance", "BASE", 100) },
	["debilitate nearby enemies for (%d+) seconds? when f?l?a?s?k? ?effect ends"] = { mod("DebilitateChance", "BASE", 100) },
	["counterattacks have a (%d+)%% chance to debilitate on hit for (%d+) seconds?"] = function (num) return { mod("DebilitateChance", "BASE", num) } end,
	["eat a soul when you hit a unique enemy, no more than once every second"] = { flag("Condition:CanHaveSoulEater") },
	["eat a soul when you hit a rare or unique enemy, no more than once every [%d%.]+ seconds"] = { flag("Condition:CanHaveSoulEater") },
	["(%d+)%% chance to gain soul eater for (%d+) seconds on killing blow against rare and unique enemies with double strike or dual strike"] = { flag("Condition:CanHaveSoulEater") },
	["maximum (%d+) eaten souls"] = function(num) return { mod("SoulEaterMax", "OVERRIDE", num) } end,
	["([%+%-]%d+) to maximum number of eaten souls"] = function(num) return { mod("SoulEaterMax", "BASE", num) } end,
	["(%d+)%% increased attack and cast speed if you've killed recently"] = function(num) return { --This boot enchant gives a buff that applies both stats individually
		mod("Speed", "INC", num, nil, ModFlag.Cast, { type = "Condition", var = "KilledRecently" }),
		mod("Speed", "INC", num, nil, ModFlag.Attack, { type = "Condition", var = "KilledRecently" }),
	} end,
	["gain adrenaline for 1 second when you change stance"] = { flag("Condition:Adrenaline", { type = "Condition", var = "StanceChangeLastSecond" }) },
	["with a searching eye jewel socketed, maim enemies for (%d) seconds on hit with attacks"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Maimed", nil, ModFlag.Attack) }, { type = "Condition", var = "HaveSearchingEyeJewelIn{SlotName}" }) },
	["with a searching eye jewel socketed, blind enemies for (%d) seconds on hit with attacks"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Blinded", nil, ModFlag.Attack) }, { type = "Condition", var = "HaveSearchingEyeJewelIn{SlotName}" }) },
	["enemies maimed by you take (%d+)%% increased damage over time"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTakenOverTime", "INC", num) }, { type = "ActorCondition", actor = "enemy", var = "Maimed" }) } end,
	["(%d+)%% increased defences while you have at least four linked targets"] = function(num) return { mod("Defences", "INC", num, { type = "MultiplierThreshold", var = "LinkedTargets", threshold = 4 }) } end,
	["your movement speed is equal to the highest movement speed among linked players"] = { flag("MovementSpeedEqualHighestLinkedPlayers", { type = "MultiplierThreshold", var = "LinkedTargets", threshold = 1 }), },
	["(%d+)%% increased movement speed while you have at least two linked targets"] = function(num) return { mod("MovementSpeed", "INC", num, { type = "MultiplierThreshold", var = "LinkedTargets", threshold = 2 }) } end,
	["link skills have (%d+)%% increased buff effect if you have linked to a target recently"] = function(num) return { mod("BuffEffect", "INC", num, { type = "SkillType", skillType = SkillType.Link }, { type = "Condition", var = "LinkedRecently" }) } end,
	["link skills can target damageable minions"] = { flag("Condition:CanLinkToMinions") },
	["curses are inflicted on you instead of linked targets"] = { mod("ExtraLinkEffect", "LIST", { mod = flag("CurseImmune"), }), },
	["elemental ailments are inflicted on you instead of linked targets"] = { mod("ExtraLinkEffect", "LIST", { mod = flag("ElementalAilmentImmune") }) },
	["non%-unique utility flasks you use apply to linked targets"] = { mod("ExtraLinkEffect", "LIST", { mod = mod("ParentNonUniqueFlasksAppliedToYou", "FLAG", true, { type = "GlobalEffect", effectType = "Global", unscalable = true } ), }) },
	-- Traps, Mines and Totems
	["traps and mines deal (%d+)%-(%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["traps and mines deal (%d+) to (%d+) additional physical damage"] = function(_, min, max) return { mod("PhysicalMin", "BASE", tonumber(min), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)), mod("PhysicalMax", "BASE", tonumber(max), nil, 0, bor(KeywordFlag.Trap, KeywordFlag.Mine)) } end,
	["each mine applies (%d+)%% increased damage taken to enemies near it, up to (%d+)%%"] = function(num, _, limit) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Multiplier", var = "ActiveMineCount", limit = limit / num }) }) } end,
	["each mine applies (%d+)%% reduced damage dealt to enemies near it, up to (%d+)%%"] = function(num, _, limit) return { mod("EnemyModifier", "LIST", { mod = mod("Damage", "INC", -num, { type = "Multiplier", var = "ActiveMineCount", limit = limit / num }) }) } end,
	["stormblast, icicle and pyroclast mine have (%d+)%% increased aura effect"] = function(num) return {
		mod("AuraEffect", "INC", num, nil, 0, KeywordFlag.Mine, { type = "SkillName", skillNameList = { "Stormblast Mine", "Icicle Mine", "Pyroclast Mine" }, includeTransfigured = true }),
	} end,
	["stormblast, icicle and pyroclast mine deal no damage"] = function(num) return {
		flag("DealNoLightning", { type = "SkillName", skillNameList = { "Stormblast Mine", "Icicle Mine", "Pyroclast Mine" }, includeTransfigured = true }),
		flag("DealNoCold", { type = "SkillName", skillNameList = { "Stormblast Mine", "Icicle Mine", "Pyroclast Mine" }, includeTransfigured = true }),
		flag("DealNoFire", { type = "SkillName", skillNameList = { "Stormblast Mine", "Icicle Mine", "Pyroclast Mine" }, includeTransfigured = true }),
		flag("DealNoChaos", { type = "SkillName", skillNameList = { "Stormblast Mine", "Icicle Mine", "Pyroclast Mine" }, includeTransfigured = true }),
		flag("DealNoPhysical", { type = "SkillName", skillNameList = { "Stormblast Mine", "Icicle Mine", "Pyroclast Mine" }, includeTransfigured = true }),
	} end,
	["can have up to (%d+) additional traps? placed at a time"] = function(num) return { mod("ActiveTrapLimit", "BASE", num) } end,
	["can have (%d+) fewer traps placed at a time"] = function(num) return { mod("ActiveTrapLimit", "BASE", -num) } end,
	["can have up to (%d+) additional remote mines? placed at a time"] = function(num) return { mod("ActiveMineLimit", "BASE", num) } end,
	["can have up to (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num) } end,
	["attack skills can have (%d+) additional totems? summoned at a time"] = function(num) return { mod("ActiveTotemLimit", "BASE", num, nil, 0, KeywordFlag.Attack) } end,
	["can [hs][au][vm][em]o?n? 1 additional siege ballista totem per (%d+) dexterity"] = function(num) return { mod("ActiveBallistaLimit", "BASE", 1, { type = "SkillName", skillName = "Siege Ballista", includeTransfigured = true }, { type = "PerStat", stat = "Dex", div = num }) } end,
	["totems fire (%d+) additional projectiles"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	["([%d%.]+)%% of damage dealt by y?o?u?r? ?totems is leeched to you as life"] = function(num) return { mod("DamageLifeLeechToPlayer", "BASE", num, nil, 0, KeywordFlag.Totem) } end,
	["([%d%.]+)%% of damage dealt by y?o?u?r? ?mines is leeched to you as life"] = function(num) return { mod("DamageLifeLeechToPlayer", "BASE", num, nil, 0, KeywordFlag.Mine) } end,
	["you can cast an additional brand"] = { mod("ActiveBrandLimit", "BASE", 1) },
	["you can cast (%d+) additional brands"] = function(num) return { mod("ActiveBrandLimit", "BASE", num) } end,
	["(%d+)%% increased damage while you are wielding a bow and have a totem"] = function(num) return { mod("Damage", "INC", num, { type = "Condition", var = "HaveTotem" }, { type = "Condition", var = "UsingBow" }) } end,
	["each totem applies (%d+)%% increased damage taken to enemies near it"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTaken", "INC", num, { type = "Multiplier", var = "TotemsSummoned" }) }) } end,
	["totems gain %+(%d+)%% to (%w+) resistance"] = function(num, _, resistance) return { mod("Totem"..firstToUpper(resistance).."Resist", "BASE", num) } end,
	["totems gain %+(%d+)%% to all elemental resistances"] = function(num) return { mod("TotemElementalResist", "BASE", num) } end,
	-- Minions
	["your strength is added to your minions"] = { flag("StrengthAddedToMinions") },
	["half of your strength is added to your minions"] = { flag("HalfStrengthAddedToMinions") },
	["minions' accuracy rating is equal to yours"] = { flag("MinionAccuracyEqualsAccuracy") },
	["minions created recently have (%d+)%% increased attack and cast speed"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", num) }, { type = "Condition", var = "MinionsCreatedRecently" }) } end,
	["minions created recently have (%d+)%% increased movement speed"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", num) }, { type = "Condition", var = "MinionsCreatedRecently" }) } end,
	["minions poison enemies on hit"] = { mod("MinionModifier", "LIST", { mod = mod("PoisonChance", "BASE", 100) }) },
	["minions have (%d+)%% chance to poison enemies on hit"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PoisonChance", "BASE", num) }) } end,
	["(%d+)%% increased minion damage if you have hit recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "Condition", var = "HitRecently" }) } end,
	["(%d+)%% increased minion damage if you've used a minion skill recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "Condition", var = "UsedMinionSkillRecently" }) } end,
	["minions deal (%d+)%% increased damage if you've used a minion skill recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "Condition", var = "UsedMinionSkillRecently" }) } end,
	["minions have (%d+)%% increased attack and cast speed if you or your minions have killed recently"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", num) }, { type = "Condition", varList = { "KilledRecently", "MinionsKilledRecently" } }) } end,
	["(%d+)%% increased minion attack speed per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", num, nil, ModFlag.Attack) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["(%d+)%% increased minion movement speed per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["minions deal (%d+)%% increased damage per (%d+) dexterity"] = function(num, _, div) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num) }, { type = "PerStat", stat = "Dex", div = tonumber(div) }) } end,
	["minions have (%d+)%% chance to deal double damage while they are on full life"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("DoubleDamageChance", "BASE", num, { type = "Condition", var = "FullLife" }) }) } end,
	["(%d+)%% increased golem damage for each type of golem you have summoned"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HavePhysicalGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveLightningGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveColdGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveFireGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveChaosGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "HaveCarrionGolem" }) }, { type = "SkillType", skillType = SkillType.Golem }),
	} end,
	["can summon up to (%d) additional golems? at a time"] = function(num) return { mod("ActiveGolemLimit", "BASE", num) } end,
	["%+(%d) to maximum number of sentinels of purity"] = function(num) return { mod("ActiveSentinelOfPurityLimit", "BASE", num) } end,
	["if you have 3 primordial jewels, can summon up to (%d) additional golems? at a time"] = function(num) return { mod("ActiveGolemLimit", "BASE", num, { type = "MultiplierThreshold", var = "PrimordialItem", threshold = 3 }) } end,
	["golems regenerate (%d)%% of their maximum life per second"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "SkillType", skillType = SkillType.Golem }) } end,
	["summoned golems regenerate (%d)%% of their life per second"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("LifeRegenPercent", "BASE", num) }, { type = "SkillType", skillType = SkillType.Golem }) } end,
	["summoned carrion golems impale on hit if you have the same number of them as summoned chaos golems"] = {
		mod("MinionModifier", "LIST", { mod = mod("ImpaleChance", "BASE", 100, { type = "ActorCondition", actor = "parent", var = "CarrionEqualChaosGolem" }, { type = "ActorCondition", actor = "parent", var = "HaveChaosGolem" }) }, { type = "SkillName", skillName = "Summon Carrion Golem", includeTransfigured = true })
	},
	["summoned chaos golems impale on hit if you have the same number of them as summoned stone golems"] = {
		mod("MinionModifier", "LIST", { mod = mod("ImpaleChance", "BASE", 100, { type = "ActorCondition", actor = "parent", var = "ChaosEqualStoneGolem" }, { type = "ActorCondition", actor = "parent", var = "HavePhysicalGolem" }) }, { type = "SkillName", skillName = "Summon Chaos Golem", includeTransfigured = true })
	},
	["summoned stone golems impale on hit if you have the same number of them as summoned carrion golems"] = {
		mod("MinionModifier", "LIST", { mod = mod("ImpaleChance", "BASE", 100, { type = "ActorCondition", actor = "parent", var = "StoneEqualCarrionGolem" }, { type = "ActorCondition", actor = "parent", var = "HaveCarrionGolem" }) }, { type = "SkillName", skillName = "Summon Stone Golem", includeTransfigured = true })
	},
	["maximum life of summoned elemental golems is doubled"] = { mod("MinionModifier", "LIST", { mod = mod("Life", "MORE", 100) }, { type = "SkillType", skillType = SkillType.Golem }, { type = "SkillType", skillTypeList = {SkillType.Lightning, SkillType.Cold, SkillType.Fire} }) },
	["golems summoned in the past 8 seconds deal (%d+)%% increased damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "SummonedGolemInPast8Sec" }) }, { type = "SkillType", skillType = SkillType.Golem }) } end,
	["raised zombies and spectres gain adrenaline for 8 seconds when raised"] = {
		mod("MinionModifier", "LIST", { mod = flag("Condition:Adrenaline") }, { type = "Condition", var = "SummonedSpectreInPast8Sec" }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true }),
		mod("MinionModifier", "LIST", { mod = flag("Condition:Adrenaline") }, { type = "Condition", var = "SummonedZombieInPast8Sec" }, { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true})
	},
	["gain onslaught for 10 seconds when you cast socketed golem skill"] = function(num) return { flag("Condition:Onslaught", { type = "Condition", var = "SummonedGolemInPast10Sec" }) } end,
	["s?u?m?m?o?n?e?d? ?raging spirits' hits always ignite"] = { mod("MinionModifier", "LIST", { mod = mod("EnemyIgniteChance", "BASE", 100) }, { type = "SkillName", skillName = "Summon Raging Spirit", includeTransfigured = true }) },
	["raised zombies have avatar of fire"] = { mod("MinionModifier", "LIST", { mod = mod("Keystone", "LIST", "Avatar of Fire") }, { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true }) },
	["raised zombies take ([%d%.]+)%% of their maximum life per second as fire damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("FireDegen", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }) }, { type = "SkillName", skillName = "Raise Zombie", includeTransfigured = true }) } end,
	["maximum number of summoned raging spirits is (%d+)"] = function(num) return { mod("ActiveRagingSpiritLimit", "OVERRIDE", num) } end,
	["maximum number of summoned phantasms is (%d+)"] = function(num) return { mod("ActivePhantasmLimit", "OVERRIDE", num) } end,
	["summoned raging spirits have diamond shrine and massive shrine buffs"] = {
		mod("MinionModifier", "LIST", { mod = flag("Condition:DiamondShrine") }, { type = "SkillName", skillName = "Summon Raging Spirit", includeTransfigured = true }),
		mod("MinionModifier", "LIST", { mod = flag("Condition:MassiveShrine") }, { type = "SkillName", skillName = "Summon Raging Spirit", includeTransfigured = true }),
	},
	["summoned phantasms have diamond shrine and massive shrine buffs"] = {
		mod("MinionModifier", "LIST", { mod = flag("Condition:DiamondShrine") }, { type = "SkillName", skillName = "Summon Phantasm" }),
		mod("MinionModifier", "LIST", { mod = flag("Condition:MassiveShrine") }, { type = "SkillName", skillName = "Summon Phantasm" }),
	},
	["minions deal no non%-physical damage"] = {
		mod("MinionModifier", "LIST", { mod = flag("DealNoLightning") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoCold") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoFire") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoChaos") }),
	},
	["minions deal no non%-lightning damage"] = {
		mod("MinionModifier", "LIST", { mod = flag("DealNoPhysical") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoLCold") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoFire") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoChaos") }),
	},
	["minions deal no non%-cold damage"] = {
		mod("MinionModifier", "LIST", { mod = flag("DealNoPhysical") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoLightning") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoFire") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoChaos") }),
	},
	["minions deal no non%-fire damage"] = {
		mod("MinionModifier", "LIST", { mod = flag("DealNoPhysical") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoLightning") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoCold") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoChaos") }),
	},
	["minions deal no non%-chaos damage"] = {
		mod("MinionModifier", "LIST", { mod = flag("DealNoPhysical") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoLightning") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoCold") }),
		mod("MinionModifier", "LIST", { mod = flag("DealNoFire") }),
	},
	["minions convert (%d+)%% of physical damage to lightning damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToLightning", "BASE", num) }) } end,
	["minions convert (%d+)%% of physical damage to cold damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToCold", "BASE", num) }) } end,
	["minions convert (%d+)%% of physical damage to fire damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToFire", "BASE", num) }) } end,
	["minions convert (%d+)%% of physical damage to chaos damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToChaos", "BASE", num) }) } end,
	["summoned skeletons have avatar of fire"] = { mod("MinionModifier", "LIST", { mod = mod("Keystone", "LIST", "Avatar of Fire") }, { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true }) },
	["summoned skeletons take ([%d%.]+)%% of their maximum life per second as fire damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("FireDegen", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }) }, { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true }) } end,
	["summoned skeletons have (%d+)%% chance to wither enemies for (%d+) seconds on hit"] = { mod("ExtraSkillMod", "LIST", { mod = flag("Condition:CanWither") }, { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true }) },
	["summoned skeletons have (%d+)%% of physical damage converted to chaos damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToChaos", "BASE", num) }, { type = "SkillName", skillName = "Summon Skeletons", includeTransfigured = true }) } end,
	["summoned skeletons gain added chaos damage equal to (%d+)%% of maximum energy shield on your equipped shield"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("ChaosMin", "BASE", 1, { type = "PercentStat", stat = "EnergyShieldOnWeapon 2", actor = "parent", percent = num }) }),
		mod("MinionModifier", "LIST", { mod = mod("ChaosMax", "BASE", 1, { type = "PercentStat", stat = "EnergyShieldOnWeapon 2", actor = "parent", percent = num }) }),
	} end,
	["skeletons gain added chaos damage equal to (%d+)%% of maximum energy shield on your equipped shield"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("ChaosMin", "BASE", 1, { type = "PercentStat", stat = "EnergyShieldOnWeapon 2", actor = "parent", percent = num }) }),
		mod("MinionModifier", "LIST", { mod = mod("ChaosMax", "BASE", 1, { type = "PercentStat", stat = "EnergyShieldOnWeapon 2", actor = "parent", percent = num }) }),
	} end,
	["minions convert (%d+)%% of physical damage to fire damage per red socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToFire", "BASE", num) }, { type = "Multiplier", var = "RedSocketIn{SlotName}" }) } end,
	["minions convert (%d+)%% of physical damage to cold damage per green socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToCold", "BASE", num) }, { type = "Multiplier", var = "GreenSocketIn{SlotName}" }) } end,
	["minions convert (%d+)%% of physical damage to lightning damage per blue socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToLightning", "BASE", num) }, { type = "Multiplier", var = "BlueSocketIn{SlotName}" }) } end,
	["minions convert (%d+)%% of physical damage to chaos damage per white socket"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToChaos", "BASE", num) }, { type = "Multiplier", var = "WhiteSocketIn{SlotName}" }) } end,
	["minions have a (%d+)%% chance to impale on hit with attacks"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("ImpaleChance", "BASE", num ) }) } end,
	["minions from herald skills deal (%d+)%% more damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "MORE", num) }, { type = "SkillType", skillType = SkillType.Herald }) } end,
	["minions have (%d+)%% increased movement speed for each herald affecting you"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", num, { type = "Multiplier", var = "Herald", actor = "parent" }) }) } end,
	["minions deal (%d+)%% increased damage while you are affected by a herald"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", num, { type = "ActorCondition", actor = "parent", var = "AffectedByHerald" }) }) } end,
	["minions have (%d+)%% increased attack and cast speed while you are affected by a herald"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", num, { type = "ActorCondition", actor = "parent", var = "AffectedByHerald" }) }) } end,
	["minions have unholy might"] = {
		mod("MinionModifier", "LIST", { mod = flag("Condition:UnholyMight") }),
		mod("MinionModifier", "LIST", { mod = flag("Condition:CanWither") }),
	},
	["summoned skeleton warriors a?n?d? ?s?o?l?d?i?e?r?s? ?deal triple damage with this weapon if you've hit with this weapon recently"] = {
		mod("Dummy", "DUMMY", 1, { type = "Condition", var = "HitRecentlyWithWeapon" }), -- Make the Configuration option appear
		mod("MinionModifier", "LIST", { mod = mod("TripleDamageChance", "BASE", 100, { type = "ActorCondition", actor = "parent", var = "HitRecentlyWithWeapon" }) }, { type = "SkillName", skillName = "Summon Skeletons" }),
	},
	["summoned skeleton warriors a?n?d? ?s?o?l?d?i?e?r?s? ?wield a? ?c?o?p?y? ?o?f? ?this weapon while in your main hand"] = { }, -- just make the mod blue, handled in CalcSetup
	["each summoned phantasm grants you phantasmal might"] = { flag("Condition:PhantasmalMight") },
	["minions have (%d+)%% increased critical strike chance per maximum power charge you have"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("CritChance", "INC", num, { type = "Multiplier", actor = "parent", var = "PowerChargeMax" }) }) } end,
	["minions' base attack critical strike chance is equal to the critical strike chance of your main hand weapon"] = { mod("MinionModifier", "LIST", { mod = flag("AttackCritIsEqualToParentMainHand", nil, ModFlag.Attack) }) },
	["minions can hear the whispers for 5 seconds after they deal a critical strike"] = {
		mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", 50, { type = "Condition", neg = true, var = "NeverCrit" }) }),
		mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", 50, nil, ModFlag.Attack, { type = "Condition", neg = true, var = "NeverCrit" }) }),
		mod("MinionModifier", "LIST", { mod = mod("ChaosDegen", "BASE", 1, { type = "PercentStat", stat = "Life", percent = 20 }, { type = "Condition", neg = true, var = "NeverCrit" }) }),
	},
	["chaos damage t?a?k?e?n? ?does not bypass minions' energy shield"] = { mod("MinionModifier", "LIST", { mod = flag("ChaosNotBypassEnergyShield") }) },
	["while minions have energy shield, their hits ignore monster elemental resistances"] = { mod("MinionModifier", "LIST", { mod = flag("IgnoreElementalResistances", { type = "StatThreshold", stat = "EnergyShield", threshold = 1 }) }) },
	["summoned arbalists' projectiles pierce (%d+) additional targets"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PierceCount", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists' projectiles fork"] = {
		mod("MinionModifier", "LIST", { mod = flag("ForkOnce") }, { type = "SkillName", skillName = "Summon Arbalists" }),
		mod("MinionModifier", "LIST", { mod = mod("ForkCountMax", "BASE", 1) }, { type = "SkillName", skillName = "Summon Arbalists" })
	},
	["summoned arbalists' projectiles chain %+(%d+) times"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists have (%d+)%% chance to inflict fire exposure on hit"] = function(num) return { mod("FireExposureChance", "BASE", num, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists have (%d+)%% chance to inflict cold exposure on hit"] = function(num) return { mod("ColdExposureChance", "BASE", num, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists have (%d+)%% chance to inflict lightning exposure on hit"] = function(num) return { mod("LightningExposureChance", "BASE", num, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists convert (%d+)%% of physical damage to fire damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToFire", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists convert (%d+)%% of physical damage to cold damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToCold", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists convert (%d+)%% of physical damage to lightning damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageConvertToLightning", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }) } end,
	["summoned arbalists have (%d+)%% chance to freeze, shock, and ignite"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("EnemyFreezeChance", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }),
		mod("MinionModifier", "LIST", { mod = mod("EnemyShockChance", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }),
		mod("MinionModifier", "LIST", { mod = mod("EnemyIgniteChance", "BASE", num) }, { type = "SkillName", skillName = "Summon Arbalists" }),
	} end,
	["skeleton warriors are permanent minions and follow you"] = { flag("RaisedSkeletonPermanentDuration", { type = "SkillName", skillName = "Summon Skeletons" }) }, -- typo never existed except in some items generated by PoB
	["summoned skeleton warriors are permanent and follow you"] = { flag("RaisedSkeletonPermanentDuration", { type = "SkillName", skillName = "Summon Skeletons" }) },
	-- Projectiles
	["skills chain %+(%d) times"] = function(num) return { mod("ChainCountMax", "BASE", num) } end,
	["arrows chain %+(%d) times"] = function(num) return { mod("ChainCountMax", "BASE", num, nil, ModFlag.Bow) } end,
	["skills chain an additional time while at maximum frenzy charges"] = { mod("ChainCountMax", "BASE", 1, { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["attacks chain an additional time when in main hand"] = { mod("ChainCountMax", "BASE", 1, nil, ModFlag.Attack, { type = "SlotNumber", num = 1 }) },
	["projectiles chain %+(%d) times while you have phasing"] = function(num) return { mod("ChainCountMax", "BASE", num, nil, ModFlag.Projectile, { type = "Condition", var = "Phasing" }) } end,
	["projectiles split towards %+(%d) targets"] = function(num) return { mod("SplitCount", "BASE", num) } end,
	["adds an additional arrow"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack) },
	["(%d+) additional arrows"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Attack) } end,
	["bow attacks fire an additional arrow"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Bow) },
	["bow attacks fire (%d+) additional arrows"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Bow) } end,
	["bow attacks fire (%d+) additional arrows if you haven't cast dash recently"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, ModFlag.Bow, { type = "Condition", var = "CastDashRecently", neg = true }) } end,
	["wand attacks fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Wand) },
	["skills fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1) },
	["spells [hf][ai][vr]e an additional projectile"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Spell) },
	["attacks fire an additional projectile"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack) },
	["attacks have an additional projectile when in off hand"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack, { type = "SlotNumber", num = 2 }) },
	["caustic arrow and scourge arrow fire (%d+)%% more projectiles"] = function(num) return { mod("ProjectileCount", "MORE", num, nil, { type = "SkillName", skillNameList = { "Caustic Arrow", "Scourge Arrow" }, includeTransfigured = true }) } end,
	["essence drain and soulrend fire (%d+) additional projectiles"] = function(num) return { mod("ProjectileCount", "BASE", num, nil, { type = "SkillName", skillNameList = { "Essence Drain", "Soulrend" }, includeTransfigured = true }) } end,
	["(%d+)%% reduced essence drain and soulrend projectile speed"] = function(num) return { mod("ProjectileSpeed", "INC", -num, nil, { type = "SkillName", skillNameList = { "Essence Drain", "Soulrend" }, includeTransfigured = true }) } end,
	["projectiles pierce an additional target"] = { mod("PierceCount", "BASE", 1) },
	["projectiles pierce (%d+) targets?"] = function(num) return { mod("PierceCount", "BASE", num) } end,
	["projectiles pierce (%d+) additional targets?"] = function(num) return { mod("PierceCount", "BASE", num) } end,
	["projectiles pierce (%d+) additional targets while you have phasing"] = function(num) return { mod("PierceCount", "BASE", num, { type = "Condition", var = "Phasing" }) } end,
	["projectiles pierce all targets while you have phasing"] = { flag("PierceAllTargets", { type = "Condition", var = "Phasing" }) },
	["projectiles pierce all burning enemies"] = { flag("PierceAllTargets", { type = "ActorCondition", actor = "enemy", var = "Burning" }) },
	["arrows pierce an additional target"] = { mod("PierceCount", "BASE", 1, nil, ModFlag.Attack) },
	["arrows pierce (%d+) additional targets"] = function(num) return { mod("PierceCount", "BASE", num, nil, ModFlag.Attack) } end,
	["arrows pierce one target"] = { mod("PierceCount", "BASE", 1, nil, ModFlag.Attack) },
	["arrows pierce (%d+) targets?"] = function(num) return { mod("PierceCount", "BASE", num, nil, ModFlag.Attack) } end,
	["always pierce with arrows"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows always pierce"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows pierce all targets"] = { flag("PierceAllTargets", nil, ModFlag.Attack) },
	["arrows that pierce cause bleeding"] = { mod("BleedChance", "BASE", 100, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) },
	["arrows that pierce have (%d+)%% chance to cause bleeding"] = function(num) return { mod("BleedChance", "BASE", num, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	["arrows that pierce deal (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num, nil, bor(ModFlag.Attack, ModFlag.Projectile), { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	["projectiles gain (%d+)%% of non%-chaos damage as extra chaos damage per chain"] = function(num) return { mod("NonChaosDamageGainAsChaos", "BASE", num, nil, ModFlag.Projectile, { type = "PerStat", stat = "Chain" }) } end,
	["projectiles that have chained gain (%d+)%% of non%-chaos damage as extra chaos damage"] = function(num) return { mod("NonChaosDamageGainAsChaos", "BASE", num, nil, ModFlag.Projectile, { type = "StatThreshold", stat = "Chain", threshold = 1 }) } end,
	["left ring slot: projectiles from spells cannot chain"] = { flag("CannotChain", nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 1 }) },
	["left ring slot: projectiles from spells fork"] = { flag("ForkOnce", nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 1 }), mod("ForkCountMax", "BASE", 1, nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 1 }) },
	["left ring slot: your chilling skitterbot's aura applies socketed h?e?x? ?curse instead"] = { flag("SkitterbotsCannotChill", { type = "SlotNumber", num = 1 }) },
	["right ring slot: projectiles from spells chain %+1 times"] = { mod("ChainCountMax", "BASE", 1, nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 2 }) },
	["right ring slot: projectiles from spells cannot fork"] = { flag("CannotFork", nil, bor(ModFlag.Spell, ModFlag.Projectile), { type = "SlotNumber", num = 2 }) },
	["right ring slot: your shocking skitterbot's aura applies socketed h?e?x? ?curse instead"] = { flag("SkitterbotsCannotShock", { type = "SlotNumber", num = 2 }) },
	["projectiles from spells cannot pierce"] = { flag("CannotPierce", nil, ModFlag.Spell) },
	["projectiles fork"] = { flag("ForkOnce", nil, ModFlag.Projectile), mod("ForkCountMax", "BASE", 1, nil, ModFlag.Projectile) },
	["projectiles from attacks fork"] = { flag("ForkOnce", nil, ModFlag.Projectile, { type = "SkillType", skillType = SkillType.RangedAttack }), mod("ForkCountMax", "BASE", 1, nil, ModFlag.Projectile, { type = "SkillType", skillType = SkillType.RangedAttack }) },
	["projectiles from attacks fork an additional time"] = { flag("ForkTwice", nil, ModFlag.Projectile, { type = "SkillType", skillType = SkillType.RangedAttack }), mod("ForkCountMax", "BASE", 1, nil, ModFlag.Projectile, { type = "SkillType", skillType = SkillType.RangedAttack }) },
	["projectiles from attacks can fork (%d+) additional times?"] = function(num) return {
		flag("ForkTwice", nil, ModFlag.Projectile, { type = "SkillType", skillType = SkillType.RangedAttack }),
		mod("ForkCountMax", "BASE", num, nil, ModFlag.Projectile, { type = "SkillType", skillType = SkillType.RangedAttack })
	} end,
	["(%d+)%% increased critical strike chance with arrows that fork"] = function(num) return {
		mod("CritChance", "INC", num, nil, ModFlag.Bow, { type = "StatThreshold", stat = "ForkRemaining", threshold = 1 }, { type = "StatThreshold", stat = "PierceCount", threshold = 0, upper = true }) }
	end,
	["arrows that pierce have %+(%d+)%% to critical strike multiplier"] = function (num) return {
		mod("CritMultiplier", "BASE", num, nil, ModFlag.Bow, { type = "StatThreshold", stat = "PierceCount", threshold = 1 }) } end,
	["arrows pierce all targets after forking"] = { flag("PierceAllTargets", nil, ModFlag.Bow, { type = "StatThreshold", stat = "ForkedCount", threshold = 1 }) },
	["modifiers to number of projectiles instead apply to the number of targets projectiles split towards"] = {
		flag("NoAdditionalProjectiles"),
		flag("AdditionalProjectilesAddSplitsInstead")
	},
	["modifiers to number of projectiles do not apply to fireball and rolling magma"] = { flag("NoAdditionalProjectiles", { type = "SkillName", skillNameList = { "Fireball", "Rolling Magma" } }) },
	["attack skills fire an additional projectile while wielding a claw or dagger"] = { mod("ProjectileCount", "BASE", 1, nil, ModFlag.Attack, { type = "ModFlagOr", modFlags = bor(ModFlag.Claw, ModFlag.Dagger) }) },
	["skills fire (%d+) additional projectiles for 4 seconds after you consume a total of 12 steel shards"] = function(num) return { mod("ProjectileCount", "BASE", num, { type = "Condition", var = "Consumed12SteelShardsRecently" }) } end,
	["non%-projectile chaining lightning skills chain %+(%d+) times"] = function (num) return { mod("ChainCountMax", "BASE", num, { type = "SkillType", skillType = SkillType.Projectile, neg = true }, { type = "SkillType", skillType = SkillType.Chains }, { type = "SkillType", skillType = SkillType.Lightning }) } end,
	["arrows gain damage as they travel farther, dealing up to (%d+)%% increased damage with hits to targets"] = function(num) return { mod("Damage", "INC", num, nil, bor(ModFlag.Bow, ModFlag.Hit), { type = "DistanceRamp", ramp = { {35,0},{70,1} } }) } end,
	["arrows gain critical strike chance as they travel farther, up to (%d+)%% increased critical strike chance"] = function(num) return { mod("CritChance", "INC", num, nil, ModFlag.Bow, { type = "DistanceRamp", ramp = { {35,0},{70,1} } }) } end,
	["projectiles deal (%d+)%% increased damage with hits to targets at the start of their movement, reducing to (%d+)%% as they travel farther"] = function(num) return { mod("Damage", "INC", num, nil, bor(ModFlag.Hit, ModFlag.Projectile), { type = "DistanceRamp", ramp = {{35,1},{70,0}} }) } end,
	["projectiles deal (%d+)%% increased damage with hits and ailments for each time they have chained"] = function(num) return { mod("Damage", "INC", num, nil, 0, bor(KeywordFlag.Hit, KeywordFlag.Ailment), { type = "PerStat", stat = "Chain" }, { type = "SkillType", skillType = SkillType.Projectile }) } end,
	["projectiles deal (%d+)%% increased damage with hits and ailments for each enemy pierced"] = function(num) return { mod("Damage", "INC", num, nil, 0, bor(KeywordFlag.Hit, KeywordFlag.Ailment), { type = "PerStat", stat = "PiercedCount" }, { type = "SkillType", skillType = SkillType.Projectile }) } end,
	["(%d+)%% increased bonuses gained from equipped quiver"] = function(num) return {mod("EffectOfBonusesFromQuiver", "INC", num)} end,
	-- Leech/Gain on Hit/Kill
	["cannot leech life"] = { flag("CannotLeechLife") },
	["cannot leech mana"] = { flag("CannotLeechMana") },
	["cannot leech when on low life"] = {
		flag("CannotLeechLife", { type = "Condition", var = "LowLife" }),
		flag("CannotLeechMana", { type = "Condition", var = "LowLife" })
	},
	["cannot leech life from critical strikes"] = {	flag("CannotLeechLife", { type = "Condition", var = "CriticalStrike" }) },
	["leech applies instantly on critical strike"] = {
		mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" }),
		mod("InstantManaLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" }),
		mod("InstantEnergyShieldLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" })
	},
	["gain life and mana from leech instantly on critical strike"] = {
		mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" }),
		mod("InstantManaLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" }),
		mod("InstantEnergyShieldLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" })
	},
	["leech applies instantly during f?l?a?s?k? ?effect"] = {
		mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
		mod("InstantManaLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
		mod("InstantEnergyShieldLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" })
	},
	["gain life and mana from leech instantly during f?l?a?s?k? ?effect"] = {
		mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
		mod("InstantManaLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" })
	},
	["life and mana leech are instant during f?l?a?s?k? ?effect"] = {
		mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" }),
		mod("InstantManaLeech", "BASE", 100, { type = "Condition", var = "UsingFlask" })
	},
	["life and mana leech from critical strikes are instant"] = {
		mod("InstantLifeLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" }),
		mod("InstantManaLeech", "BASE", 100, { type = "Condition", var = "CriticalStrike" })
	},
	["with 5 corrupted items equipped: life leech recovers based on your chaos damage instead"] = { flag("LifeLeechBasedOnChaosDamage", { type = "MultiplierThreshold", var = "CorruptedItem", threshold = 5 }) },
	["you have vaal pact if you've dealt a critical strike recently"] = { mod("Keystone", "LIST", "Vaal Pact", { type = "Condition", var = "CritRecently" }) },
	["you have vaal pact while at maximum endurance charges"] = { mod("Keystone", "LIST", "Vaal Pact", { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }) },
	["you have vaal pact while focus?sed"] = { mod("Keystone", "LIST", "Vaal Pact", { type = "Condition", var = "Focused" }) },
	["gain (%d+) energy shield for each enemy you hit which is affected by a spider's web"] = function(num) return { mod("EnergyShieldOnHit", "BASE", num, nil, ModFlag.Hit, { type = "MultiplierThreshold", actor = "enemy", var = "Spider's WebStack", threshold = 1 }) } end,
	["(%d+)%% chance to gain (%d+) life on hit with attacks"] = function (chance, _, amount) return {
		mod("LifeOnHit", "BASE", amount * chance / 100, nil, bor(ModFlag.Attack, ModFlag.Hit), { type = "Condition", var = "AverageResourceGain" }),
		mod("LifeOnHit", "BASE", tonumber(amount), nil, bor(ModFlag.Attack, ModFlag.Hit), { type = "Condition", var = "MaxResourceGain" }),
	} end,
	["(%d+) life gained for each cursed enemy hit by your attacks"] = function(num) return { mod("LifeOnHit", "BASE", num, nil, bor(ModFlag.Attack, ModFlag.Hit), { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["gain (%d+) life per cursed enemy hit with attacks"] = function(num) return { mod("LifeOnHit", "BASE", num, nil, bor(ModFlag.Attack, ModFlag.Hit), { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["(%d+) mana gained for each cursed enemy hit by your attacks"] = function(num) return { mod("ManaOnHit", "BASE", num, nil, bor(ModFlag.Attack, ModFlag.Hit), { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["gain (%d+) mana per cursed enemy hit with attacks"] = function(num) return { mod("ManaOnHit", "BASE", num, nil, bor(ModFlag.Attack, ModFlag.Hit), { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["gain (%d+) life per blinded enemy hit with this weapon"] = function(num) return { mod("LifeOnHit", "BASE", num, nil, ModFlag.Hit,{ type = "ActorCondition", actor = "enemy", var = "Blinded" }, { type = "Condition", var = "{Hand}Attack" }) } end,
	["recover (%d+)%% of life on kill"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }) } end,
	["recover (%d+)%% of life on kill for each different type of mastery you have allocated"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "Multiplier", var = "AllocatedMasteryType" }) } end,
	["recover (%d+)%% of life on killing a poisoned enemy"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "MultiplierThreshold", actor = "enemy", var = "PoisonStack", threshold = 1 }) } end,
	["recover (%d+)%% of life on killing a chilled enemy"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "ActorCondition", actor = "enemy", var = "Chilled" }) } end,
	["recover (%d+)%% of life when you kill a cursed enemy"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["recover (%d+)%% of life per withered debuff on each enemy you kill"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "Multiplier", var = "WitheredStack", actor = "enemy", limit = 15 }) } end,
	["minions recover (%d+)%% of life on killing a poisoned enemy"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "MultiplierThreshold", actor = "enemy", var = "PoisonStack", threshold = 1 }) }) } end,
	["recover (%d+)%% of mana when you kill a cursed enemy"] = function(num) return { mod("ManaOnKill", "BASE", 1, { type = "PercentStat", stat = "Mana", percent = num }, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["recover (%d+)%% of energy shield when you kill a cursed enemy"] = function(num) return { mod("EnergyShieldOnKill", "BASE", 1, { type = "PercentStat", stat = "EnergyShield", percent = num }, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["recover (%d+)%% of life on kill if you've spent life recently"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "MultiplierThreshold", var = "LifeSpentRecently", threshold = 1 }) } end,
	["(%d+)%% chance to recover all life when you kill an enemy"] = function(chance) return {
		mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = chance }, { type = "Condition", var = "AverageResourceGain" }),
		mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = 100 }, { type = "Condition", var = "MaxResourceGain" })
	} end,
	["lose (%d+)%% of life on kill"] = function(num) return { mod("LifeOnKill", "BASE", -1, { type = "PercentStat", stat = "Life", percent = num }) } end,
	["%+(%d+) life gained on killing ignited enemies"] = function(num) return { mod("LifeOnKill", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Ignited" }) } end,
	["gain (%d+) life per ignited enemy killed"] = function(num) return { mod("LifeOnKill", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Ignited" }) } end,
	["recover (%d+)%% of mana on kill"] = function(num) return { mod("ManaOnKill", "BASE", 1, { type = "PercentStat", stat = "Mana", percent = num }) } end,
	["recover (%d+)%% of mana on kill for each different type of mastery you have allocated"] = function(num) return { mod("ManaOnKill", "BASE", 1, { type = "PercentStat", stat = "Mana", percent = num }, { type = "Multiplier", var = "AllocatedMasteryType" }) } end,
	["lose (%d+)%% of mana on kill"] = function(num) return { mod("ManaOnKill", "BASE", -1, { type = "PercentStat", stat = "Mana", percent = num }) } end,
	["%+(%d+) mana gained on killing a frozen enemy"] = function(num) return { mod("ManaOnKill", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Frozen" }) } end,
	["recover (%d+)%% of energy shield on kill"] = function(num) return { mod("EnergyShieldOnKill", "BASE", 1, { type = "PercentStat", stat = "EnergyShield", percent = num }) } end,
	["recover (%d+)%% of energy shield on kill for each different type of mastery you have allocated"] = function(num) return { mod("EnergyShieldOnKill", "BASE", 1, { type = "PercentStat", stat = "EnergyShield", percent = num }, { type = "Multiplier", var = "AllocatedMasteryType" }) } end,
	["lose (%d+)%% of energy shield on kill"] = function(num) return { mod("EnergyShieldOnKill", "BASE", -1, { type = "PercentStat", stat = "EnergyShield", percent = num }) } end,
	["%+(%d+) energy shield gained on killing a shocked enemy"] = function(num) return { mod("EnergyShieldOnKill", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Shocked" }) } end,
	["%+(%d+) energy shield gained on kill per level"] = function(num) return { mod("EnergyShieldOnKill", "BASE", num, { type = "Multiplier", var = "Level" }) } end,
	-- Defences
	["chaos damage t?a?k?e?n? ?does not bypass energy shield"] = { flag("ChaosNotBypassEnergyShield") },
	["(%d+)%% of chaos damage t?a?k?e?n? ?does not bypass energy shield"] = function(num) return { mod("ChaosEnergyShieldBypass", "BASE", -num) } end,
	["chaos damage t?a?k?e?n? ?does not bypass energy shield while not on low life"] = { flag("ChaosNotBypassEnergyShield", { type = "Condition", varList = { "LowLife" }, neg = true }) },
	["chaos damage t?a?k?e?n? ?does not bypass energy shield while not on low life or low mana"] = { flag("ChaosNotBypassEnergyShield", { type = "Condition", varList = { "LowLife", "LowMana" }, neg = true }) },
	["chaos damage is taken from mana before life"] = { mod("ChaosDamageTakenFromManaBeforeLife", "BASE", 100) },
	["minions take (%d+)%% increased damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("DamageTaken", "INC", num) }) } end,
	["minions take (%d+)%% reduced damage"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("DamageTaken", "INC", -num) }) } end,
	["you and your minions take (%d+)%% reduced reflected (%w+) damage"] = function(num, _, type) return {
		mod(type:gsub("^%l", string.upper).."ReflectedDamageTaken", "INC", -tonumber(num), { type = "GlobalEffect", effectType = "Global", unscalable = true }),
		mod("MinionModifier", "LIST", { mod = mod(type:gsub("^%l", string.upper).."ReflectedDamageTaken", "INC", -tonumber(num), { type = "GlobalEffect", effectType = "Global", unscalable = true }) }),
	} end,
	["you and your minions take (%d+)%% reduced reflected damage"] = function(num) return {
		mod("ReflectedDamageTaken", "INC", -tonumber(num), { type = "GlobalEffect", effectType = "Global", unscalable = true }),
		mod("MinionModifier", "LIST", { mod = mod("ReflectedDamageTaken", "INC", -tonumber(num), { type = "GlobalEffect", effectType = "Global", unscalable = true }) }),
	} end,
	["you have mind over matter while at maximum power charges"] = { mod("Keystone", "LIST", "Mind Over Matter", { type = "StatThreshold", stat = "PowerCharges", thresholdStat = "PowerChargesMax" }) },
	["cannot evade enemy attacks"] = { flag("CannotEvade") },
	["attacks cannot hit you"] = { flag("AlwaysEvade") },
	["attacks against you always hit"] = { flag("CannotEvade") },
	["cannot block"] = { flag("CannotBlockAttacks"), flag("CannotBlockSpells") },
	["cannot block while you have no energy shield"] = { flag("CannotBlockAttacks", { type = "Condition", var = "HaveEnergyShield", neg = true }), flag("CannotBlockSpells", { type = "Condition", var = "HaveEnergyShield", neg = true }) },
	["cannot block attacks"] = { flag("CannotBlockAttacks") },
	["cannot block attack damage"] = { flag("CannotBlockAttacks") },
	["cannot block spells"] = { flag("CannotBlockSpells") },
	["cannot block spell damage"] = { flag("CannotBlockSpells") },
	["monsters cannot block your attacks"] = { mod("EnemyModifier", "LIST", { mod = flag("CannotBlockAttacks") }) },
	["damage t?a?k?e?n? from blocked hits cannot bypass energy shield"] = { flag("BlockedDamageDoesntBypassES", { type = "Condition", var = "EVBypass", neg = true }) },
	["damage t?a?k?e?n? from unblocked hits always bypasses energy shield"] = { flag("UnblockedDamageDoesBypassES", { type = "Condition", var = "EVBypass", neg = true }) },
	["recover (%d+) life when you block"] = function(num) return { mod("LifeOnBlock", "BASE", num) } end,
	["recover (%d+) energy shield when you block spell damage"] = function(num) return { mod("EnergyShieldOnSpellBlock", "BASE", num) } end,
	["recover (%d+) energy shield when you suppress spell damage"] = function(num) return { mod("EnergyShieldOnSuppress", "BASE", num) } end,
	["recover (%d+) life when you suppress spell damage"] = function(num) return { mod("LifeOnSuppress", "BASE", num) } end,
	["recover (%d+)%% of life when you block"] = function(num) return { mod("LifeOnBlock", "BASE", 1,  { type = "PercentStat", stat = "Life", percent = num }) } end,
	["recover (%d+)%% of life when you block attack damage while wielding a staff"] = function(num) return { mod("LifeOnBlock", "BASE", 1,  { type = "PercentStat", stat = "Life", percent = num }, { type = "Condition", var = "UsingStaff" }) } end,
	["recover (%d+)%% of your maximum mana when you block"] = function(num) return { mod("ManaOnBlock", "BASE", 1,  { type = "PercentStat", stat = "Mana", percent = num }) } end,
	["recover (%d+)%% of energy shield when you block"] = function(num) return { mod("EnergyShieldOnBlock", "BASE", 1,  { type = "PercentStat", stat = "EnergyShield", percent = num }) } end,
	["recover (%d+)%% of energy shield when you block spell damage while wielding a staff"] = function(num) return { mod("EnergyShieldOnSpellBlock", "BASE", 1,  { type = "PercentStat", stat = "EnergyShield", percent = num }, { type = "Condition", var = "UsingStaff" }) } end,
	["replenishes energy shield by (%d+)%% of armour when you block"] = function(num) return { mod("EnergyShieldOnBlock", "BASE", 1,  { type = "PercentStat", stat = "Armour", percent = num }) } end,
	["recover energy shield equal to (%d+)%% of armour when you block"] = function(num) return { mod("EnergyShieldOnBlock", "BASE", 1,  { type = "PercentStat", stat = "Armour", percent = num }) } end,
	["(%d+)%% of damage taken while affected by clarity recouped as mana"] = function(num) return { mod("ManaRecoup", "BASE", num, { type = "Condition", var = "AffectedByClarity" }) } end,
	["recoup effects instead occur over 3 seconds"] = { flag("3SecondRecoup") },
	["life recoup effects instead occur over 3 seconds"] = { flag("3SecondLifeRecoup") },
	["cannot leech or regenerate mana"] = { flag("NoManaRegen"), flag("CannotLeechMana") },
	["right ring slot: you cannot regenerate mana" ] = { flag("NoManaRegen", { type = "SlotNumber", num = 2 }) },
	["y?o?u? ?cannot recharge energy shield"] = { flag("NoEnergyShieldRecharge") },
	["you cannot regenerate energy shield" ] = { flag("NoEnergyShieldRegen") },
	["cannot recharge or regenerate energy shield"] = { flag("NoEnergyShieldRecharge"), flag("NoEnergyShieldRegen") },
	["left ring slot: you cannot recharge or regenerate energy shield"] = { flag("NoEnergyShieldRecharge", { type = "SlotNumber", num = 1 }), flag("NoEnergyShieldRegen", { type = "SlotNumber", num = 1 }) },
	["cannot gain energy shield"] = { flag("CannotGainEnergyShield") },
	["cannot gain life"] = { flag("CannotGainLife") },
	["cannot gain mana"] = { flag("CannotGainMana") },
	["cannot gain energy shield during f?l?a?s?k? ?effect"] = { flag("CannotGainEnergyShield", { type = "Condition", var = "UsingFlask" }) },
	["cannot gain life during f?l?a?s?k? ?effect"] = { flag("CannotGainLife", { type = "Condition", var = "UsingFlask" }) },
	["cannot gain mana during f?l?a?s?k? ?effect"] = { flag("CannotGainMana", { type = "Condition", var = "UsingFlask" }) },
	["life that would be lost by taking damage is instead reserved"] = { flag("DamageInsteadReservesLife") },
	["you have no armour or energy shield"] = {
		mod("Armour", "MORE", -100),
		mod("EnergyShield", "MORE", -100),
	},
	["you have no armour or maximum energy shield"] = {
		mod("Armour", "MORE", -100),
		mod("EnergyShield", "MORE", -100),
	},
	["defences are zero"] = {
		mod("Armour", "MORE", -100),
		mod("EnergyShield", "MORE", -100),
		mod("Evasion", "MORE", -100),
		mod("Ward", "MORE", -100),
	},
	["you have no intelligence"] = {
		mod("Int", "MORE", -100),
	},
	["elemental resistances are zero"] = {
		mod("FireResist", "OVERRIDE", 0),
		mod("ColdResist", "OVERRIDE", 0),
		mod("LightningResist", "OVERRIDE", 0),
	},
	["chaos resistance is zero"] = {
		mod("ChaosResist", "OVERRIDE", 0),
	},
	["nearby enemies' chaos resistance is (%d+)"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("ChaosResist", "OVERRIDE", num) }),
	} end,
	["your maximum resistances are (%d+)%%"] = function(num) return {
		mod("FireResistMax", "OVERRIDE", num),
		mod("ColdResistMax", "OVERRIDE", num),
		mod("LightningResistMax", "OVERRIDE", num),
		mod("ChaosResistMax", "OVERRIDE", num),
	} end,
	["fire resistance is (%d+)%%"] = function(num) return { mod("FireResist", "OVERRIDE", num) } end,
	["cold resistance is (%d+)%%"] = function(num) return { mod("ColdResist", "OVERRIDE", num) } end,
	["lightning resistance is (%d+)%%"] = function(num) return { mod("LightningResist", "OVERRIDE", num) } end,
	["elemental resistances are capped by your highest maximum elemental resistance instead"] = { flag("ElementalResistMaxIsHighestResistMax") },
	["chaos resistance is doubled"] = { mod("ChaosResist", "MORE", 100) },
	["nearby enemies have (%d+)%% increased fire and cold resistances"] = function(num) return {
		mod("EnemyModifier", "LIST", { mod = mod("FireResist", "INC", num) }),
		mod("EnemyModifier", "LIST", { mod = mod("ColdResist", "INC", num) }),
	} end,
	["nearby enemies are blinded while physical aegis is not depleted"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Blinded") }, { type = "Condition", var = "PhysicalAegisDepleted", neg = true }) },
	["armour is increased by uncapped fire resistance"] = { flag( "ArmourIncreasedByUncappedFireRes") },
	["armour is increased by overcapped fire resistance"] = { flag( "ArmourIncreasedByOvercappedFireRes") },
	["minion life is increased by t?h?e?i?r? ?overcapped fire resistance"] = { mod("MinionModifier", "LIST", { mod = mod("Life", "INC", 1, { type = "PerStat", stat = "FireResistOverCap", div = 1 }) }) },
	["evasion rating is increased by uncapped cold resistance"] = { flag( "EvasionRatingIncreasedByUncappedColdRes") },
	["evasion rating is increased by overcapped cold resistance"] = { flag( "EvasionRatingIncreasedByOvercappedColdRes") },
	["reflects (%d+) physical damage to melee attackers"] = { },
	["ignore all movement penalties from armour"] = { flag("Condition:IgnoreMovementPenalties") },
	["gain armour equal to your reserved mana"] = { mod("Armour", "BASE", 1, { type = "PerStat", stat = "ManaReserved", div = 1 }) },
	["(%d+)%% increased armour per (%d+) reserved mana"] = function(num, _, mana) return { mod("Armour", "INC", num, { type = "PerStat", stat = "ManaReserved", div = tonumber(mana) }) } end,
	["cannot be stunned"] = { flag("StunImmune"), },
	["cannot be stunned while bleeding"] = { flag("StunImmune", { type = "Condition", var = "Bleeding" }), },
	["cannot be stunned when on low life"] = { flag("StunImmune", { type = "Condition", var = "LowLife" }), },
	["cannot be stunned if you haven't been hit recently"] = { flag("StunImmune", { type = "Condition", var = "BeenHitRecently", neg = true }), },
	["cannot be stunned if you have at least (%d+) crab barriers"] = function(num) return { flag("StunImmune", { type = "StatThreshold", stat = "CrabBarriers", threshold = num }), } end,
	["cannot be blinded"] = { flag("Condition:CannotBeBlinded") },
	["cannot be shocked"] = { flag("ShockImmune") },
	["immun[ei]t?y? to shock"] = { flag("ShockImmune"), },
	["cannot be frozen"] = { flag("FreezeImmune"), },
	["immun[ei]t?y? to freeze"] = { flag("FreezeImmune"), },
	["cannot be chilled"] = { flag("ChillImmune"), },
	["immun[ei]t?y? to chill"] = { flag("ChillImmune"), },
	["cannot be ignited"] = { flag("IgniteImmune"), },
	["immun[ei]t?y? to ignite"] = { flag("IgniteImmune"), },
	["cannot be ignited while at maximum endurance charges"] = { flag("IgniteImmune", {type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }, { type = "GlobalEffect", effectType = "Global", unscalable = true }), },
	["grants immunity to ignite for (%d+) seconds if used while ignited"] = { flag("IgniteImmune", { type = "Condition", var = "UsingFlask" }), },
	["grants immunity to bleeding for (%d+) seconds if used while bleeding"] = { flag("BleedImmune", { type = "Condition", var = "UsingFlask" }) },
	["grants immunity to poison for (%d+) seconds if used while poisoned"] = { flag("PoisonImmune", { type = "Condition", var = "UsingFlask" }) },
	["grants immunity to freeze for (%d+) seconds if used while frozen"] = { flag("FreezeImmune", { type = "Condition", var = "UsingFlask" }) },
	["grants immunity to chill for (%d+) seconds if used while chilled"] = { flag("ChillImmune", { type = "Condition", var = "UsingFlask" }) },
	["grants immunity to shock for (%d+) seconds if used while shocked"] = { flag("ShockImmune", { type = "Condition", var = "UsingFlask" }) },
	["cannot be chilled while at maximum frenzy charges"] = { flag("ChillImmune", {type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["cannot be shocked while at maximum power charges"] = { flag("ShockImmune", {type = "StatThreshold", stat = "PowerCharges", thresholdStat = "PowerChargesMax" }) },
	["you cannot be shocked while at maximum endurance charges"] = { flag("ShockImmune", {type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }) },
	["you cannot be shocked while chilled"] = { flag("ShockImmune", {type = "Condition", var = "Chilled" }) },
	["cannot be shocked while chilled"] = { flag("ShockImmune", {type = "Condition", var = "Chilled" }) },
	["cannot be shocked if intelligence is higher than strength"] = { flag("ShockImmune", { type = "Condition", var = "IntHigherThanStr" }) },
	["cannot be frozen if dexterity is higher than intelligence"] = { flag("FreezeImmune", { type = "Condition", var = "DexHigherThanInt" }) },
	["cannot be frozen if energy shield recharge has started recently"] = { flag("FreezeImmune", { type = "Condition", var = "EnergyShieldRechargeRecently" }) },
	["cannot be ignited if strength is higher than dexterity"] = { flag("IgniteImmune", { type = "Condition", var = "StrHigherThanDex" }) },
	["cannot be chilled while burning"] = { flag("ChillImmune", { type = "Condition", var = "Burning" }) },
	["cannot be chilled while you have onslaught"] = { flag("ChillImmune", { type = "Condition", var = "Onslaught" }) },
	["cannot be chilled during onslaught"] = { flag("ChillImmune", { type = "Condition", var = "Onslaught" }) },
	["cannot be inflicted with bleeding"] = { flag("BleedImmune") },
	["bleeding cannot be inflicted on you"] = { flag("BleedImmune") },
	["you are immune to bleeding"] = { flag("BleedImmune") },
	["immune to bleeding if equipped helmet has higher armour than evasion rating"] = { flag("BleedImmune", { type = "Condition", var = "HelmetArmourHigherThanEvasion" }) },
	["immune to poison if equipped helmet has higher evasion rating than armour"] = { flag("PoisonImmune", { type = "Condition", var = "HelmetEvasionHigherThanArmour" }) },
	["immun[ei]t?y? to bleeding and corrupted blood during f?l?a?s?k? ?effect"] = { flag("BleedImmune", { type = "Condition", var = "UsingFlask" }) },
	["immun[ei]t?y? to poison"] = { flag("PoisonImmune") },
	["cannot be poisoned while bleeding"] = { flag("PoisonImmune", { type = "Condition", var = "Bleeding" }) },
	["immun[ei]t?y? to poison during f?l?a?s?k? ?effect"] = { flag("PoisonImmune", { type = "Condition", var = "UsingFlask" }) },
	["immun[ei]t?y? to shock during f?l?a?s?k? ?effect"] = { flag("ShockImmune", { type = "Condition", var = "UsingFlask" }) },
	["immun[ei]t?y? to freeze and chill during f?l?a?s?k? ?effect"] = {
		flag("FreezeImmune", { type = "Condition", var = "UsingFlask" }),
		flag("ChillImmune", { type = "Condition", var = "UsingFlask" }),
	},
	["immun[ei]t?y? to freeze and chill while ignited"] = {
		flag("FreezeImmune", { type = "Condition", var = "Ignited" }),
		flag("ChillImmune", { type = "Condition", var = "Ignited" }),
	},
	["immun[ei]t?y? to ignite during f?l?a?s?k? ?effect"] = { flag("IgniteImmune", { type = "Condition", var = "UsingFlask" }) },
	["immun[ei]t?y? to bleeding during f?l?a?s?k? ?effect"] = { flag("BleedImmune", { type = "Condition", var = "UsingFlask" }) },
	["immun[ei]t?y? to curses during f?l?a?s?k? ?effect"] = { flag("CurseImmune", { type = "Condition", var = "UsingFlask" }) },
	["you are unaffected by (.+) if you've cast (.-) in the past (%d+) seconds"] = function (_, ailment, curse) return {
		mod("Self"..ailment:gsub("^%l", string.upper).."Effect", "MORE", -100, { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") }, { type = "GlobalEffect", effectType = "Global", unscalable = true })
	} end,
	["immun[ei]t?y? to (%a-)s? if you've cast (.-) in the past (%d+) seconds"] = function (_, ailment, curse) return {
		flag(ailment:gsub("^%l", string.upper).."Immune", { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") })
	} end,
	["when you kill an enemy affected by a non%-aura hex, become immune to curses for remaining hex duration"] = { -- typo / old wording change
		flag("Condition:CanBeCurseImmune"),
	},
	["when you kill an enemy cursed with a non%-aura hex, become immune to curses for remaining hex duration"] = {
		flag("Condition:CanBeCurseImmune"),
	},
	["immun[ei]t?y? to freeze, chill, curses and stuns during f?l?a?s?k? ?effect"] = {
		flag("FreezeImmune", { type = "Condition", var = "UsingFlask" }),
		flag("ChillImmune", { type = "Condition", var = "UsingFlask" }),
		flag("CurseImmune", { type = "Condition", var = "UsingFlask" }),
		flag("StunImmune", { type = "Condition", var = "UsingFlask" }),
	},
	-- This mod doesn't work the way it should. It prevents self-chill among other issues.
	--Since we don't currently really do anything with enemy ailment infliction, this should probably be removed
	--["cursed enemies cannot inflict elemental ailments on you"] = {
	--	mod("AvoidElementalAilments", "BASE", 100, { type = "ActorCondition", actor = "enemy", var = "Cursed" }, { type = "GlobalEffect", effectType = "Global", unscalable = true }),
	--},
	["enemies inflict elemental ailments on you instead of nearby allies"] = { mod("ExtraAura", "LIST", { onlyAllies = true, mod = flag("ElementalAilmentImmune") }), },
	["unaffected by curses"] = { mod("CurseEffectOnSelf", "MORE", -100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["unaffected by curses while affected by zealotry"] = { mod("CurseEffectOnSelf", "MORE", -100, { type = "Condition", var = "AffectedByZealotry" }, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["immun[ei]t?y? to curses while you have at least (%d+) rage"] = function(num) return { flag("CurseImmune", { type = "MultiplierThreshold", var = "Rage", threshold = num }) } end,
	["unaffected by ignite"] = { mod("SelfIgniteEffect", "MORE", -100) },
	["unaffected by chill"] = { mod("SelfChillEffect", "MORE", -100) },
	["unaffected by chill while leeching mana"] = { mod("SelfChillEffect", "MORE", -100, { type = "Condition", var = "LeechingMana" }) },
	["unaffected by chill while channelling"] = { mod("SelfChillEffect", "MORE", -100, { type = "Condition", var = "Channelling" }) },
	["unaffected by freeze"] = { mod("SelfFreezeEffect", "MORE", -100) },
	["unaffected by shock"] = { mod("SelfShockEffect", "MORE", -100) },
	["unaffected by shock while leeching energy shield"] = { mod("SelfShockEffect", "MORE", -100, { type = "Condition", var = "LeechingEnergyShield" }) },
	["unaffected by shock while channelling"] = { mod("SelfShockEffect", "MORE", -100, { type = "Condition", var = "Channelling" }) },
	["unaffected by scorch"] = { mod("SelfScorchEffect", "MORE", -100) },
	["unaffected by brittle"] = { mod("SelfBrittleEffect", "MORE", -100) },
	["unaffected by sap"] = { mod("SelfSapEffect", "MORE", -100) },
	["unaffected by damaging ailments"] = {
		mod("SelfBleedEffect", "MORE", -100),
		mod("SelfIgniteEffect", "MORE", -100),
		mod("SelfPoisonEffect", "MORE", -100),
	},
	["the effect of chill on you is reversed"] = { flag("SelfChillEffectIsReversed") },
	["your movement speed is (%d+)%% of its base value"] = function(num) return { mod("MovementSpeed", "OVERRIDE", num / 100) } end,
	["action speed cannot be modified to below (%d+)%% base value"] = function(num) return { mod("MinimumActionSpeed", "MAX", num) } end,
	["action speed cannot be slowed below base value if you've cast (.-) in the past (%d+) seconds"] = function (_, curse) return {
		mod("MinimumActionSpeed", "MAX", 100, { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") })
	} end,
	["nearby allies' action speed cannot be modified to below base value"] = { mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("MinimumActionSpeed", "MAX", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) }) },
	["armour also applies to lightning damage taken from hits"] = { mod("ArmourAppliesToLightningDamageTaken", "BASE", 100), },
	["lightning resistance does not affect lightning damage taken"] = { flag("SelfIgnoreLightningResistance") },
	["(%d+)%% increased maximum life and reduced fire resistance"] = function(num) return {
		mod("Life", "INC", num),
		mod("FireResist", "INC", -num),
	} end,
	["(%d+)%% increased maximum mana and reduced cold resistance"] = function(num) return {
		mod("Mana", "INC", num),
		mod("ColdResist", "INC", -num),
	} end,
	["(%d+)%% increased global maximum energy shield and reduced lightning resistance"] = function(num) return {
		mod("EnergyShield", "INC", num, { type = "Global" }),
		mod("LightningResist", "INC", -num),
	} end,
	["phasing while on low life"] = { flag("Condition:Phasing", { type = "Condition", var = "LowLife" }) },
	["cannot be ignited while on low life"] = { flag("IgniteImmune", { type = "Condition", var = "LowLife" }), },
	["ward does not break during f?l?a?s?k? ?effect"] = { flag("WardNotBreak", { type = "Condition", var = "UsingFlask" }) },
	["stun threshold is based on energy shield instead of life"] = {
		flag("StunThresholdBasedOnEnergyShieldInsteadOfLife"),
		mod("StunThresholdEnergyShieldPercent", "BASE", 100),
	},
	["stun threshold is based on (%d+)%% of your energy shield instead of life"] = function(num) return {
		flag("StunThresholdBasedOnEnergyShieldInsteadOfLife"),
		mod("StunThresholdEnergyShieldPercent", "BASE", num),
	} end,
	["stun threshold is based on (%d+)%% of your mana instead of life"] = function(num) return {
		flag("StunThresholdBasedOnManaInsteadOfLife"),
		mod("StunThresholdManaPercent", "BASE", num),
	} end,
	["(%d+)%% of your energy shield is added to your stun threshold"] = function(num) return {
		flag("AddESToStunThreshold"),
		mod("ESToStunThresholdPercent", "BASE", num),
	} end,
	["(%d+)%% increased armour per second you've been stationary, up to a maximum of (%d+)%%"] = function(num, _, limit) return {
		mod("Armour", "INC", num, { type = "Multiplier", var = "StationarySeconds", limit = tonumber(limit / num) }, { type = "Condition", var = "Stationary" }),
	} end,
	["(%d+)%% of damage from hits is taken from your spectres' life before you"] = function(num) return { mod("takenFromSpectresBeforeYou", "BASE", num) } end,
	["(%d+)%% of damage from hits is taken from your nearest totem's life before you"] = function(num) return { mod("takenFromTotemsBeforeYou", "BASE", num, { type = "Condition", var = "HaveTotem" }) } end,
	-- Knockback
	["cannot knock enemies back"] = { flag("CannotKnockback") },
	["knocks back enemies if you get a critical strike with a staff"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Staff, { type = "Condition", var = "CriticalStrike" }) },
	["knocks back enemies if you get a critical strike with a bow"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Bow, { type = "Condition", var = "CriticalStrike" }) },
	["bow knockback at close range"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Bow, { type = "Condition", var = "AtCloseRange" }) },
	["adds knockback during f?l?a?s?k? ?effect"] = { mod("EnemyKnockbackChance", "BASE", 100, { type = "Condition", var = "UsingFlask" }) },
	["adds knockback to melee attacks during f?l?a?s?k? ?effect"] = { mod("EnemyKnockbackChance", "BASE", 100, nil, ModFlag.Melee, { type = "Condition", var = "UsingFlask" }) },
	["knockback direction is reversed"] = { mod("EnemyKnockbackDistance", "MORE", -200) },
	-- Culling
	["culling strike"] = { mod("CullPercent", "MAX", 10, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["culling strike during f?l?a?s?k? ?effect"] = { mod("CullPercent", "MAX", 10, { type = "Condition", var = "UsingFlask" }, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["hits with this weapon have culling strike against bleeding enemies"] = { mod("CullPercent", "MAX", 10, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }) },
	["you have culling strike against cursed enemies"] = { mod("CullPercent", "MAX", 10, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) },
	["critical strikes have culling strike"] = { mod("CriticalCullPercent", "MAX", 10) },
	["your critical strikes have culling strike"] = { mod("CriticalCullPercent", "MAX", 10) },
	["your spells have culling strike"] = { mod("CullPercent", "MAX", 10, nil, ModFlag.Spell) },
	["bow attacks have culling strike"] = { mod("CullPercent", "MAX", 10, nil, bor(ModFlag.Attack, ModFlag.Bow)) },
	["culling strike against burning enemies"] = { mod("CullPercent", "MAX", 10, { type = "ActorCondition", actor = "enemy", var = "Burning" }) },
	["culling strike against frozen enemies"] = { mod("CullPercent", "MAX", 10, { type = "ActorCondition", actor = "enemy", var = "Frozen" }) },
	["culling strike against marked enemy"] = { mod("CullPercent", "MAX", 10, { type = "ActorCondition", actor = "enemy", var = "Marked" }) },
	["nearby allies have culling strike"] = { mod("ExtraAura", "LIST", {onlyAllies = true, mod = mod("CullPercent", "MAX", 10) }) },
	-- Intimidate
	["permanently intimidate enemies on block"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated") }, { type = "Condition", var = "BlockedRecently" }) },
	["with a murderous eye jewel socketed, intimidate enemies for (%d) seconds on hit with attacks"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated") }, { type = "Condition", var = "HaveMurderousEyeJewelIn{SlotName}" }) },
	["enemies taunted by your warcries are intimidated"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated", { type = "Condition", var = "Taunted" }) }, { type = "Condition", var = "UsedWarcryRecently" }) },
	["intimidate enemies for (%d+) seconds on block while holding a shield"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated") }, { type = "Condition", var = "BlockedRecently" }, { type = "Condition", var = "UsingShield" }) },
	["intimidate enemies on hit if you've cast (.-) in the past (%d+) seconds"] = function (_, curse) return {
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated") }, nil,  ModFlag.Hit, { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") })
	} end,
	["intimidate enemies for (%d+) seconds on hit with attacks while at maximum endurance charges"] = {
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated") }, { type = "StatThreshold", stat = "EnduranceCharges", thresholdStat = "EnduranceChargesMax" }, { type = "Condition", var = "HitRecently" })
	},
	["nearby enemies are intimidated while you have rage"] = {
		-- MultiplierThreshold is on RageStacks because Rage is only set in CalcPerform if Condition:CanGainRage is true, Bear's Girdle does not flag CanGainRage
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Intimidated") }, { type = "MultiplierThreshold", var = "RageStack", threshold = 1 })
	},
	-- Flasks
	["flasks do not apply to you"] = { flag("FlasksDoNotApplyToPlayer") },
	["flasks apply to your zombies and spectres"] = { flag("FlasksApplyToMinion", { type = "SkillName", skillNameList = { "Raise Zombie", "Raise Spectre" }, includeTransfigured = true }) },
	["flasks apply to your raised zombies and spectres"] = { flag("FlasksApplyToMinion", { type = "SkillName", skillNameList = { "Raise Zombie", "Raise Spectre" }, includeTransfigured = true }) },
	["flasks you use apply to your raised zombies and spectres"] = { flag("FlasksApplyToMinion", { type = "SkillName", skillNameList = { "Raise Zombie", "Raise Spectre" }, includeTransfigured = true }) },
	["your minions use your flasks when summoned"] = { flag("FlasksApplyToMinion") },
	["recover an additional (%d+)%% of flask's life recovery amount over 10 seconds if used while not on full life"] = function(num) return {
		mod("FlaskAdditionalLifeRecovery", "BASE", num)
	} end,
	["creates a smoke cloud on use"] = { },
	["creates chilled ground on use"] = { },
	["creates consecrated ground on use"] = { },
	["removes bleeding on use"] = { },
	["removes burning on use"] = { },
	["removes all burning when used"] = { },
	["removes curses on use"] = { },
	["removes freeze and chill on use"] = { },
	["removes poison on use"] = { },
	["removes shock on use"] = { },
	["g?a?i?n? ?unholy might during f?l?a?s?k? ?effect"] = { flag("Condition:UnholyMight", { type = "Condition", var = "UsingFlask" }), flag("Condition:CanWither", { type = "Condition", var = "UsingFlask" }), },
	["zealot's oath during f?l?a?s?k? ?effect"] = { flag("ZealotsOath", { type = "Condition", var = "UsingFlask" }) },
	["grants level (%d+) (.+) curse aura during f?l?a?s?k? ?effect"] = function(num, _, skill) return { mod("ExtraCurse", "LIST", { skillId = gemIdLookup[skill:gsub(" skill","")] or "Unknown", level = num }, { type = "Condition", var = "UsingFlask" }) } end,
	["shocks nearby enemies during f?l?a?s?k? ?effect, causing (%d+)%% increased damage taken"] = function(num) return {
		mod("ShockOverride", "BASE", num, { type = "Condition", var = "UsingFlask" })
	} end,
	["during f?l?a?s?k? ?effect, (%d+)%% reduced damage taken of each element for which your uncapped elemental resistance is lowest"] = function(num) return {
		mod("LightningDamageTaken", "INC", -num, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "ColdResistTotal", upper = true }, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "FireResistTotal", upper = true }),
		mod("ColdDamageTaken", "INC", -num, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "LightningResistTotal", upper = true }, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "FireResistTotal", upper = true }),
		mod("FireDamageTaken", "INC", -num, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "LightningResistTotal", upper = true }, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "ColdResistTotal", upper = true }),
	} end,
	["during f?l?a?s?k? ?effect, damage penetrates (%d+)%% o?f? ?resistance of each element for which your uncapped elemental resistance is highest"] = function(num) return {
		mod("LightningPenetration", "BASE", num, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "ColdResistTotal" }, { type = "StatThreshold", stat = "LightningResistTotal", thresholdStat = "FireResistTotal" }),
		mod("ColdPenetration", "BASE", num, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "LightningResistTotal" }, { type = "StatThreshold", stat = "ColdResistTotal", thresholdStat = "FireResistTotal" }),
		mod("FirePenetration", "BASE", num, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "LightningResistTotal" }, { type = "StatThreshold", stat = "FireResistTotal", thresholdStat = "ColdResistTotal" }),
	} end,
	["recover (%d+)%% of life when you kill an enemy during f?l?a?s?k? ?effect"] = function(num) return { mod("LifeOnKill", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "Condition", var = "UsingFlask" }) } end,
	["recover (%d+)%% of mana when you kill an enemy during f?l?a?s?k? ?effect"] = function(num) return { mod("ManaOnKill", "BASE", 1, { type = "PercentStat", stat = "Mana", percent = num }, { type = "Condition", var = "UsingFlask" }) } end,
	["recover (%d+)%% of energy shield when you kill an enemy during f?l?a?s?k? ?effect"] = function(num) return { mod("EnergyShieldOnKill", "BASE", 1, { type = "PercentStat", stat = "EnergyShield", percent = num }, { type = "Condition", var = "UsingFlask" }) } end,
	["(%d+)%% of maximum life taken as chaos damage per second"] = function(num) return { mod("ChaosDegen", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }) } end,
	["your critical strikes do not deal extra damage during f?l?a?s?k? ?effect"] = { flag("NoCritMultiplier", { type = "Condition", var = "UsingFlask" }) },
	["grants perfect agony during f?l?a?s?k? ?effect"] = { mod("Keystone", "LIST", "Perfect Agony", { type = "Condition", var = "UsingFlask" }) },
	["grants eldritch battery during f?l?a?s?k? ?effect"] = { mod("Keystone", "LIST", "Eldritch Battery", { type = "Condition", var = "UsingFlask" }) },
	["eldritch battery during f?l?a?s?k? ?effect"] = { mod("Keystone", "LIST", "Eldritch Battery", { type = "Condition", var = "UsingFlask" }) },
	["chaos damage t?a?k?e?n? ?does not bypass energy shield during effect"] = { flag("ChaosNotBypassEnergyShield") },
	["when hit during effect, (%d+)%% of life loss from damage taken occurs over 4 seconds instead"] = function(num) return { mod("LifeLossPrevented", "BASE", num, { type = "Condition", var = "UsingFlask" }) } end,
	["y?o?u?r? ?skills [ch][oa][sv][te] no mana c?o?s?t? ?during f?l?a?s?k? ?effect"] = { mod("ManaCost", "MORE", -100, { type = "Condition", var = "UsingFlask" }) },
	["life recovery from flasks also applies to energy shield during f?l?a?s?k? ?effect"] = { flag("LifeFlaskAppliesToEnergyShield", { type = "Condition", var = "UsingFlask" }) },
	["consecrated ground created during effect applies (%d+)%% increased damage taken to enemies"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTakenConsecratedGround", "INC", num, { type = "Condition", var = "OnConsecratedGround" }) }, { type = "Condition", var = "UsingFlask" }) } end,
	["gain alchemist's genius when you use a flask"] = {
		flag("Condition:CanHaveAlchemistGenius"),
	},
	["(%d+)%% chance to gain alchemist's genius when you use a flask"] = {
		flag("Condition:CanHaveAlchemistGenius"),
	},
	["(%d+)%% less flask charges gained from kills"] = function(num) return {
		mod("FlaskChargesGained", "MORE", -num, "from Kills")
	} end,
	["flasks gain (%d+) charges? every (%d+) seconds"] = function(num, _, div) return {
		mod("FlaskChargesGenerated", "BASE", num / div)
	} end,
	["flasks gain a charge every (%d+) seconds"] = function(_, div) return {
		mod("FlaskChargesGenerated", "BASE", 1 / div)
	} end,
	["while a unique enemy is in your presence, flasks gain a charge every (%d+) seconds"] = function(_, div) return {
		mod("FlaskChargesGenerated", "BASE", 1 / div, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" })
	} end,
	["while a pinnacle atlas boss is in your presence, flasks gain a charge every (%d+) seconds"] = function(_, div) return {
		mod("FlaskChargesGenerated", "BASE", 1 / div, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" })
	} end,
	["utility flasks gain (%d+) charges? every (%d+) seconds"] = function(num, _, div) return {
		mod("UtilityFlaskChargesGenerated", "BASE", num / div)
	} end,
	["life flasks gain (%d+) charges? every (%d+) seconds"] = function(num, _, div) return {
		mod("LifeFlaskChargesGenerated", "BASE", num / div)
	} end,
	["mana flasks gain (%d+) charges? every (%d+) seconds"] = function(num, _, div) return {
		mod("ManaFlaskChargesGenerated", "BASE", num / div)
	} end,
	["flasks gain (%d+) charges? per empty flask slot every (%d+) seconds"] = function(num, _, div) return {
		mod("FlaskChargesGeneratedPerEmptyFlask", "BASE", num / div)
	} end,
	["flasks gain (%d+) charges? per second if you've hit a unique enemy recently"] = function(num) return {
		mod("FlaskChargesGenerated", "BASE", num, { type = "Condition", var = "HitRecently" }, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" })
	} end,
	["effect is not removed when unreserved mana is filled"] = {
		flag("ManaFlaskEffectNotRemoved")
	},
	["life flask effects are not removed when unreserved life is filled"] = {
		flag("LifeFlaskEffectNotRemoved")
	},
	-- Jewels
	["passives in radius of ([%a%s']+) can be allocated without being connected to your tree"] = function(_, name) return {
		mod("JewelData", "LIST", { key = "impossibleEscapeKeystone", value = name }),
		mod("ImpossibleEscapeKeystones", "LIST", { key = name, value = true }),
	} end,
	["passives in radius can be allocated without being connected to your tree"] = { mod("JewelData", "LIST", { key = "intuitiveLeapLike", value = true }) },
	["affects passives in small ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 4 }) },
	["affects passives in medium ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 5 }) },
	["affects passives in large ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 6 }) },
	["affects passives in very large ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 7 }) },
	["affects passives in massive ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 8 }) },
	["only affects passives in small ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 4 }) },
	["only affects passives in medium ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 5 }) },
	["only affects passives in large ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 6 }) },
	["only affects passives in very large ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 7 }) },
	["only affects passives in massive ring"] = { mod("JewelData", "LIST", { key = "radiusIndex", value = 8 }) },
	["primordial"] = { mod("Multiplier:PrimordialItem", "BASE", 1) },
	["spectres have a base duration of (%d+) seconds"] = { mod("SkillData", "LIST", { key = "duration", value = 6 }, { type = "SkillName", skillName = "Raise Spectre", includeTransfigured = true }) },
	["flasks applied to you have (%d+)%% increased effect"] = function(num) return { mod("FlaskEffect", "INC", num, { type = "ActorCondition", actor = "player"}) } end,
	["flasks applied to you have (%d+)%% increased effect per level"] = function(num) return { mod("FlaskEffect", "INC", num, { type = "ActorCondition", actor = "player"}, { type = "Multiplier", var = "Level" }) } end,
	["while a unique enemy is in your presence, flasks applied to you have (%d+)%% increased effect"] = function(num) return { mod("FlaskEffect", "INC", num, { type = "ActorCondition", actor = "enemy", var = "RareOrUnique" }, { type = "ActorCondition", actor = "player"}) } end,
	["while a pinnacle atlas boss is in your presence, flasks applied to you have (%d+)%% increased effect"] = function(num) return { mod("FlaskEffect", "INC", num, { type = "ActorCondition", actor = "enemy", var = "PinnacleBoss" }, { type = "ActorCondition", actor = "player"}) } end,
	["magic utility flasks applied to you have (%d+)%% increased effect"] = function(num) return { mod("MagicUtilityFlaskEffect", "INC", num, { type = "ActorCondition", actor = "player"}) } end,
	["flasks applied to you have (%d+)%% reduced effect"] = function(num) return { mod("FlaskEffect", "INC", -num, { type = "ActorCondition", actor = "player"}) } end,
	["adds (%d+) passive skills"] = function(num) return { mod("JewelData", "LIST", { key = "clusterJewelNodeCount", value = num }) } end,
	["1 added passive skill is a jewel socket"] = { mod("JewelData", "LIST", { key = "clusterJewelSocketCount", value = 1 }) },
	["(%d+) added passive skills are jewel sockets"] = function(num) return { mod("JewelData", "LIST", { key = "clusterJewelSocketCount", value = num }) } end,
	["adds (%d+) jewel socket passive skills"] = function(num) return { mod("JewelData", "LIST", { key = "clusterJewelSocketCountOverride", value = num }) } end,
	["adds (%d+) small passive skills? which grants? nothing"] = function(num) return { mod("JewelData", "LIST", { key = "clusterJewelNothingnessCount", value = num }) } end,
	["added small passive skills grant nothing"] = { mod("JewelData", "LIST", { key = "clusterJewelSmallsAreNothingness", value = true }) },
	["added small passive skills have (%d+)%% increased effect"] = function(num) return { mod("JewelData", "LIST", { key = "clusterJewelIncEffect", value = num }) } end,
	["this jewel's socket has (%d+)%% increased effect per allocated passive skill between it and your class' starting location"] = function(num) return { mod("JewelData", "LIST", { key = "jewelIncEffectFromClassStart", value = num }) } end,
	["(%d+)%% increased effect of jewel socket passive skills containing corrupted magic jewels, if not from cluster jewels"] = function(num) return { mod("JewelData", "LIST", { key = "corruptedMagicJewelIncEffect", value = num }) } end,
	["(%d+)%% increased effect of jewel socket passive skills containing corrupted magic jewels"] = function(num) return { mod("JewelData", "LIST", { key = "corruptedMagicJewelIncEffect", value = num }) } end,
	-- Misc
	["can't use chest armour"] = { mod("CanNotUseBody", "Flag", 1, { type = "DisablesItem", slotName = "Body Armour" }) },
	--["can't use helmets"] = { mod("CanNotUseHelmet", "Flag", 1, { type = "DisablesItem", slotName = "Helmet" }) }, -- this one does not work due to being on a passive?
	["can't use helmet"] = { mod("CanNotUseHelmet", "Flag", 1, { type = "DisablesItem", slotName = "Helmet" }) }, -- this is to allow for custom mod without saying the other is parsed
	["can't use other rings"] = { mod("CanNotUseRightRing", "Flag", 1, { type = "DisablesItem", slotName = "Ring 2" }, { type = "SlotNumber", num = 1 }), mod("CanNotUseLeftRing", "Flag", 1, { type = "DisablesItem", slotName = "Ring 1" }, { type = "SlotNumber", num = 2 }) },
	["uses both hand slots"] = { mod("CanNotUseRightWeapon", "Flag", 1, { type = "DisablesItem", slotName = "Weapon 2" }, { type = "SlotNumber", num = 1 }), mod("CanNotUseLeftWeapon", "Flag", 1, { type = "DisablesItem", slotName = "Weapon 1" }, { type = "SlotNumber", num = 2 }) },
	["can't use flask in fifth slot"] = { mod("CanNotUseFifthFlask", "Flag", 1, { type = "DisablesItem", slotName = "Flask 5", excludeItemType = "Tincture" }) },
	["boneshatter has (%d+)%% chance to grant %+1 trauma"] = function(num) return { mod("ExtraTrauma", "BASE", num, { type = "SkillName", skillName = "Boneshatter", includeTransfigured = true }) } end,
	["your minimum frenzy, endurance and power charges are equal to your maximum while you are stationary"] = {
		flag("MinimumFrenzyChargesIsMaximumFrenzyCharges", {type = "Condition", var = "Stationary" }),
		flag("MinimumEnduranceChargesIsMaximumEnduranceCharges", {type = "Condition", var = "Stationary" }),
		flag("MinimumPowerChargesIsMaximumPowerCharges", {type = "Condition", var = "Stationary" }),
	},
	["minimum power charges equal to maximum while stationary"] = { flag("MinimumPowerChargesIsMaximumPowerCharges", {type = "Condition", var = "Stationary" }) },
	["minimum frenzy charges equal to maximum while stationary"] = { flag("MinimumFrenzyChargesIsMaximumFrenzyCharges", {type = "Condition", var = "Stationary" }) },
	["minimum endurance charges equal to maximum while stationary"] = { flag("MinimumEnduranceChargesIsMaximumEnduranceCharges", {type = "Condition", var = "Stationary" }) },
	["count as having maximum number of power charges"] = { flag("HaveMaximumPowerCharges") },
	["count as having maximum number of frenzy charges"] = { flag("HaveMaximumFrenzyCharges") },
	["count as having maximum number of endurance charges"] = { flag("HaveMaximumEnduranceCharges") },
	["leftmost (%d+) magic utility flasks constantly apply their flask effects to you"] = function(num) return { mod("ActiveMagicUtilityFlasks", "BASE", num) } end,
	["marauder: melee skills have (%d+)%% increased area of effect"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "Condition", var = "ConnectedToMarauderStart" }, { type = "SkillType", skillType = SkillType.Melee }) } end,
	["intelligence provides no bonus to energy shield"] = { flag("NoIntBonusToES") },
	["intelligence provides no inherent bonus to energy shield"] = { flag("NoIntBonusToES") },
	["gain accuracy rating equal to your intelligence"] = { mod("Accuracy", "BASE", 1, { type = "PerStat", stat = "Int" }) },
	["intelligence is added to accuracy rating with wands"] = { mod("Accuracy", "BASE", 1, nil, ModFlag.Wand, { type = "PerStat", stat = "Int" }) },
	["dexterity's accuracy bonus instead grants %+(%d+) to accuracy rating per dexterity"] = function(num) return { mod("DexAccBonusOverride", "OVERRIDE", num ) } end,
	["(%d+)%% increased accuracy rating against marked enemy"] = function(num) return { mod("AccuracyVsEnemy", "INC", num, { type = "ActorCondition", actor = "enemy", var = "Marked" } ) } end,
	["(%d+)%% more accuracy rating against marked enemy"] = function(num) return { mod("AccuracyVsEnemy", "MORE", num, { type = "ActorCondition", actor = "enemy", var = "Marked" } ) } end,
	["%+(%d+) to accuracy against bleeding enemies"] = function(num) return { mod("AccuracyVsEnemy", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Bleeding" } ) } end,
	["cannot recover energy shield to above armour"] = { flag("ArmourESRecoveryCap") },
	["cannot recover energy shield to above evasion rating"] = { flag("EvasionESRecoveryCap") },
	["warcries exert (%d+) additional attacks?"] = function(num) return { mod("ExtraExertedAttacks", "BASE", num) } end,
	["warcries have (%d+)%% chance to exert (%d+) additional attacks?"] = function(num, _, var) return { mod("ExtraExertedAttacks", "BASE", (num*var/100)) } end,
	["iron will"] = { flag("IronWill") },
	["iron reflexes while stationary"] = { mod("Keystone", "LIST", "Iron Reflexes", { type = "Condition", var = "Stationary" }) },
	["you have iron reflexes while at maximum frenzy charges"] = { mod("Keystone", "LIST", "Iron Reflexes", { type = "StatThreshold", stat = "FrenzyCharges", thresholdStat = "FrenzyChargesMax" }) },
	["you have zealot's oath if you haven't been hit recently"] = { mod("Keystone", "LIST", "Zealot's Oath", { type = "Condition", var = "BeenHitRecently", neg = true }) },
	["deal no physical damage"] = { flag("DealNoPhysical") },
	["deal no cold damage"] = { flag("DealNoCold") },
	["deal no fire damage"] = { flag("DealNoFire") },
	["deal no lightning damage"] = { flag("DealNoLightning") },
	["deal no elemental damage"] = { flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoFire") },
	["deal no chaos damage"] = { flag("DealNoChaos") },
	["deal no damage"] = { flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoFire"), flag("DealNoChaos"), flag("DealNoPhysical") },
	["you can't deal damage with skills yourself"] = {
		flag("DealNoLightning", { type = "SkillType", skillTypeList = {SkillType.SummonsTotem, SkillType.RemoteMined, SkillType.Trapped}, neg = true }, {type = "Condition", var="usedByMirage", neg = true}),
		flag("DealNoCold", 		{ type = "SkillType", skillTypeList = {SkillType.SummonsTotem, SkillType.RemoteMined, SkillType.Trapped}, neg = true }, {type = "Condition", var="usedByMirage", neg = true}),
		flag("DealNoFire", 		{ type = "SkillType", skillTypeList = {SkillType.SummonsTotem, SkillType.RemoteMined, SkillType.Trapped}, neg = true }, {type = "Condition", var="usedByMirage", neg = true}),
		flag("DealNoChaos", 	{ type = "SkillType", skillTypeList = {SkillType.SummonsTotem, SkillType.RemoteMined, SkillType.Trapped}, neg = true }, {type = "Condition", var="usedByMirage", neg = true}),
		flag("DealNoPhysical", 	{ type = "SkillType", skillTypeList = {SkillType.SummonsTotem, SkillType.RemoteMined, SkillType.Trapped}, neg = true }, {type = "Condition", var="usedByMirage", neg = true})
	},
	["deal no non%-elemental damage"] = { flag("DealNoPhysical"), flag("DealNoChaos") },
	["deal no non%-lightning damage"] = { flag("DealNoPhysical"), flag("DealNoCold"), flag("DealNoFire"), flag("DealNoChaos") },
	["deal no non%-physical damage"] = { flag("DealNoLightning"), flag("DealNoCold"), flag("DealNoFire"), flag("DealNoChaos") },
	["cannot deal non%-chaos damage"] = { flag("DealNoPhysical"), flag("DealNoCold"), flag("DealNoFire"), flag("DealNoLightning") },
	["deal no physical or elemental damage"] = { flag("DealNoPhysical"), flag("DealNoCold"), flag("DealNoFire"), flag("DealNoLightning") },
	["deal no damage when not on low life"] = {
		flag("DealNoLightning", { type = "Condition", var = "LowLife", neg = true }),
		flag("DealNoCold", { type = "Condition", var = "LowLife", neg = true }),
		flag("DealNoFire", { type = "Condition", var = "LowLife", neg = true }),
		flag("DealNoChaos",{ type = "Condition", var = "LowLife", neg = true }),
		flag("DealNoPhysical", { type = "Condition", var = "LowLife", neg = true }),
	},
	["attacks have blood magic"] = { flag("CostLifeInsteadOfMana", nil, ModFlag.Attack) },
	["attacks cost life instead of mana"] = { flag("CostLifeInsteadOfMana", nil, ModFlag.Attack) },
	["(%d+)%% chance to cast a? ?socketed lightning spells? on hit"] = { mod("ExtraSupport", "LIST", { skillId = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["cast a socketed lightning spell on hit"] = { mod("ExtraSupport", "LIST", { skillId = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed lightning spell on hit"] = { mod("ExtraSupport", "LIST", { skillId = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["trigger a socketed lightning spell on hit, with a ([%d%.]+) second cooldown"] = { mod("ExtraSupport", "LIST", { skillId = "SupportUniqueMjolnerLightningSpellsCastOnHit", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }) },
	["[ct][ar][si][tg]g?e?r? a socketed cold s[pk][ei]ll on melee critical strike"] = {
		mod("ExtraSupport", "LIST", { skillId = "SupportUniqueCosprisMaliceColdSpellsCastOnMeleeCriticalStrike", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }),
	},
	["[ct][ar][si][tg]g?e?r? a socketed cold s[pk][ei]ll on melee critical strike, with a ([%d%.]+) second cooldown"] = {
		mod("ExtraSupport", "LIST", { skillId = "SupportUniqueCosprisMaliceColdSpellsCastOnMeleeCriticalStrike", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }),
	},
	["your curses can apply to hexproof enemies"] = { flag("CursesIgnoreHexproof") },
	["your hexes can affect hexproof enemies"] = { flag("CursesIgnoreHexproof") },
	["([%a%s]+) can affect hexproof enemies"] = function(_, name) return {
		mod("SkillData", "LIST", { key = "ignoreHexproof", value = true }, { type = "SkillId", skillId = gemIdLookup[name] }),
	} end,
	["hexes from socketed skills can apply (%d) additional curses"] = function(num) return { mod("SocketedCursesHexLimitValue", "BASE", num), flag("SocketedCursesAdditionalLimit", { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	-- This is being changed from ignoreHexLimit to SocketedCursesAdditionalLimit due to patch 3.16.0, which states that legacy versions "will be affected by this Curse Limit change,
	-- though they will only have 20% less Curse Effect of Curses triggered with Summon Doedre’s Effigy."
	-- Legacy versions will still show that "Hexes from Socketed Skills ignore Curse limit", but will instead have an internal limit of 5 to match the current functionality.
	["hexes from socketed skills ignore curse limit"] = function(num) return { mod("SocketedCursesHexLimitValue", "BASE", 5), flag("SocketedCursesAdditionalLimit", { type = "SocketedIn", slotName = "{SlotName}" }) } end,
	["reserves (%d+)%% of life"] = function(num) return { mod("ExtraLifeReserved", "BASE", num) } end,
	["(%d+)%% of cold damage taken as lightning"] = function(num) return { mod("ColdDamageTakenAsLightning", "BASE", num) } end,
	["(%d+)%% of fire damage taken as lightning"] = function(num) return { mod("FireDamageTakenAsLightning", "BASE", num) } end,
	["items and gems have (%d+)%% reduced attribute requirements"] = function(num) return { mod("GlobalAttributeRequirements", "INC", -num) } end,
	["items and gems have (%d+)%% increased attribute requirements"] = function(num) return { mod("GlobalAttributeRequirements", "INC", num) } end,
	["mana reservation of herald skills is always (%d+)%%"] = function(num) return { mod("SkillData", "LIST", { key = "ManaReservationPercentForced", value = num }, { type = "SkillType", skillType = SkillType.Herald }) } end,
	["([%a%s]+) reserves no mana"] = function(_, name) return {
		mod("SkillData", "LIST", { key = "manaReservationFlat", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationFlat", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "manaReservationPercent", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationPercent", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
	} end,
	["([%a%s]+) has no reservation"] = function(_, name) return {
		mod("SkillData", "LIST", { key = "manaReservationFlat", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationFlat", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "manaReservationPercent", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationPercent", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
	} end,
	["([%a%s]+) has no reservation if cast as an aura"] = function(_, name) return {
		mod("SkillData", "LIST", { key = "manaReservationFlat", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationFlat", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "manaReservationPercent", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationPercent", value = 0 }, { type = "SkillId", skillId = gemIdLookup[name] }, { type = "SkillType", skillType = SkillType.Aura }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
	} end,
	["banner skills reserve no mana"] = {
		mod("SkillData", "LIST", { key = "manaReservationPercent", value = 0 }, { type = "SkillType", skillType = SkillType.Banner }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationPercent", value = 0 }, { type = "SkillType", skillType = SkillType.Banner }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
	},
	["banner skills have no reservation"] = {
		mod("SkillData", "LIST", { key = "manaReservationPercent", value = 0 }, { type = "SkillType", skillType = SkillType.Banner }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
		mod("SkillData", "LIST", { key = "lifeReservationPercent", value = 0 }, { type = "SkillType", skillType = SkillType.Banner }, { type = "SkillType", skillType = SkillType.Blessing, neg = true }),
	},
	["placed banners also grant (%d+)%% increased attack damage to you and allies"] = function(num) return { mod("ExtraAuraEffect", "LIST", { mod = mod("Damage", "INC", num, nil, ModFlag.Attack) }, { type = "Condition", var = "BannerPlanted" }, { type = "SkillType", skillType = SkillType.Banner }) } end,
	["dread banner grants an additional %+(%d+) to maximum fortification when placing the banner"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("MaximumFortification", "BASE", num, { type = "GlobalEffect", effectType = "Buff" }) }, { type = "Condition", var = "BannerPlanted" }, { type = "SkillName", skillName = "Dread Banner" }) } end,
	["your aura skills are disabled"] = { flag("DisableSkill", { type = "SkillType", skillType = SkillType.Aura }) },
	["your blessing skills are disabled"] = { flag("DisableSkill", { type = "SkillType", skillType = SkillType.Blessing }) },
	["your spells are disabled"] = { flag("DisableSkill", { type = "SkillType", skillType = SkillType.Spell }) },
	["your travel skills are disabled"] = { flag("DisableSkill", { type = "SkillType", skillType = SkillType.Travel }) },
	["aura skills other than ([%a%s]+) are disabled"] = function(_, name) return {
		flag("DisableSkill", { type = "SkillType", skillType = SkillType.Aura }),
		flag("EnableSkill", { type = "SkillName", skillName = name }),
	} end,
	["travel skills other than ([%a%s]+) are disabled"] = function(_, name) return {
		flag("DisableSkill", { type = "SkillType", skillType = SkillType.Travel }),
		flag("EnableSkill", { type = "SkillId", skillId = gemIdLookup[name] }),
	} end,
	["strength's damage bonus instead grants (%d+)%% increased melee physical damage per (%d+) strength"] = function(num, _, perStr) return { mod("StrDmgBonusRatioOverride", "BASE", num / tonumber(perStr)) } end,
	["while in her embrace, take ([%d%.]+)%% of your total maximum life and energy shield as fire damage per second per level"] = function(num) return {
		mod("FireDegen", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "Multiplier", var = "Level" }, { type = "Condition", var = "HerEmbrace" }),
		mod("FireDegen", "BASE", 1, { type = "PercentStat", stat = "EnergyShield", percent = num }, { type = "Multiplier", var = "Level" }, { type = "Condition", var = "HerEmbrace" }),
	} end,
	["gain her embrace for %d+ seconds when you ignite an enemy"] = { flag("Condition:CanGainHerEmbrace") },
	["when you cast a spell, sacrifice all mana to gain added maximum lightning damage equal to (%d+)%% of sacrificed mana for 4 seconds"] = function(num) return {
		flag("Condition:HaveManaStorm"),
		mod("LightningMax", "BASE", 1, { type = "PercentStat", stat = "ManaUnreserved" , percent = num }, { type = "Condition", var = "SacrificeManaForLightning" }),
	} end,
	["attacks with this weapon have added maximum lightning damage equal to (%d+)%% of your energy shield"] = function(num) return { -- typo never existed except in some items generated by PoB
		mod("LightningMax", "BASE", 1, { type = "PercentStat", stat = "EnergyShield" , percent = num }, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	} end,
	["attacks with this weapon have added maximum lightning damage equal to (%d+)%% of your maximum energy shield"] = function(num) return {
		mod("LightningMax", "BASE", 1, { type = "PercentStat", stat = "EnergyShield" , percent = num }, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	} end,
	["attacks with this weapon have added maximum lightning damage equal to (%d+)%% of player'?s? maximum energy shield"] = function(num) return {
		mod("LightningMax", "BASE", 1, { type = "PercentStat", stat = "EnergyShield" , percent = num, actor = "parent" }, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }),
	} end,
	["gain added chaos damage equal to (%d+)%% of ward"] = function(num) return {
		mod("ChaosMin", "BASE", 1, { type = "PercentStat", stat = "Ward", percent = num }),
		mod("ChaosMax", "BASE", 1, { type = "PercentStat", stat = "Ward", percent = num }),
	} end,
	["spells deal added chaos damage equal to (%d+)%% of your maximum life"] = function(num) return {
		mod("ChaosMin", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "SkillType", skillType = SkillType.Spell }),
		mod("ChaosMax", "BASE", 1, { type = "PercentStat", stat = "Life", percent = num }, { type = "SkillType", skillType = SkillType.Spell }),
	} end,
	["every 16 seconds you gain iron reflexes for 8 seconds"] = {
		flag("Condition:HaveArborix"),
	},
	["every 16 seconds you gain elemental overload for 8 seconds"] = {
		flag("Condition:HaveAugyre"),
	},
	["every 8 seconds, gain avatar of fire for 4 seconds"] = {
		flag("Condition:HaveVulconus"),
	},
	["when hit, gain a random movement speed modifier from 40%% reduced to 100%% increased until hit again"] = {
		flag("Condition:HaveGamblesprint"),
	},
	["trigger socketed curse spell when you cast a curse spell, with a ([%d%.]+) second cooldown"] = {
		mod("ExtraSupport", "LIST", { skillId = "SupportUniqueCastCurseOnCurse", level = 1 }, { type = "SocketedIn", slotName = "{SlotName}" }),
	},
	["modifiers to attributes instead apply to omniscience"] = { flag("Omniscience") },
	["attribute requirements can be satisfied by (%d+)%% of omniscience"] = function(num) return {
		mod("OmniAttributeRequirements", "INC", num),
		flag("OmniscienceRequirements")
	} end,
	["you have far shot while you do not have iron reflexes"] = { flag("FarShot", { neg = true, type = "Condition", var = "HaveIronReflexes" }) },
	["you have resolute technique while you do not have elemental overload"] = { mod("Keystone", "LIST", "Resolute Technique", { neg = true, type = "Condition", var = "HaveElementalOverload" }) },
	["hits ignore enemy monster fire resistance while you are ignited"] = { flag("IgnoreFireResistance", { type = "Condition", var = "Ignited" }) },
	["your hits can't be evaded by blinded enemies"] = { flag("CannotBeEvaded", { type = "ActorCondition", actor = "enemy", var = "Blinded" }) },
	["blind does not affect your chance to hit"] = { flag("IgnoreBlindHitChance") },
	["enemies blinded by you while you are blinded have malediction"] = { mod("EnemyModifier", "LIST", { mod = flag("HasMalediction", { type = "Condition", var = "Blinded" }) }, { type = "Condition", var = "Blinded" }, { type = "Condition", var = "CannotBeBlinded", neg = true }) },
	["enemies blinded by you have malediction"] = { mod("EnemyModifier", "LIST", { mod = flag("HasMalediction", { type = "Condition", var = "Blinded" }) }) },
	["skills which throw traps have blood magic"] = { flag("CostLifeInsteadOfMana", { type = "SkillType", skillType = SkillType.Trapped }) },
	["skills which throw traps cost life instead of mana"] = { flag("CostLifeInsteadOfMana", { type = "SkillType", skillType = SkillType.Trapped }) },
	["strength provides no bonus to maximum life"] = { flag("NoStrBonusToLife") },
	["strength provides no inherent bonus to maximum life"] = { flag("NoStrBonusToLife") },
	["intelligence provides no bonus to maximum mana"] = { flag("NoIntBonusToMana") },
	["intelligence provides no inherent bonus to maximum mana"] = { flag("NoIntBonusToMana") },
	["with a ghastly eye jewel socketed, minions have %+(%d+) to accuracy rating"] = function(num) return { mod("MinionModifier", "LIST", { mod = mod("Accuracy", "BASE", num) }, { type = "Condition", var = "HaveGhastlyEyeJewelIn{SlotName}" }) } end,
	["with a hypnotic eye jewel socketed, gain arcane surge on hit with spells"] = function(num) return { flag("Condition:ArcaneSurge", { type = "Condition", var = "HitSpellRecently" }, { type = "Condition", var = "HaveHypnoticEyeJewelIn{SlotName}" }) } end,
	["hits ignore enemy monster chaos resistance if all equipped items are shaper items"] = { flag("IgnoreChaosResistance", { type = "MultiplierThreshold", var = "NonShaperItem", upper = true, threshold = 0 }) },
	["hits ignore enemy monster chaos resistance if all equipped items are elder items"] = { flag("IgnoreChaosResistance", { type = "MultiplierThreshold", var = "NonElderItem", upper = true, threshold = 0 }) },
	["gain %d+ rage on critical hit with attacks, no more than once every [%d%.]+ seconds"] = {
		flag("Condition:CanGainRage"),
	},
	["warcry skills' cooldown time is (%d+) seconds"] = function(num) return { mod("CooldownRecovery", "OVERRIDE", num, nil, 0, KeywordFlag.Warcry) } end,
	["warcry skills have (%+%d+) seconds to cooldown"] = function(num) return { mod("CooldownRecovery", "BASE", num, nil, 0, KeywordFlag.Warcry) } end,
	["stance skills have (%+%d+) seconds to cooldown"] = function(num) return { mod("CooldownRecovery", "BASE", num, nil, { type = "SkillType", skillType = SkillType.Stance }) } end,
	["using warcries is instant"] = { flag("InstantWarcry") },
	["attacks with axes or swords grant (%d+) rage on hit, no more than once every second"] = {
		flag("Condition:CanGainRage", { type = "Condition", varList = { "UsingAxe", "UsingSword" } }),
	},
	["regenerate (%d+) rage per second for every (%d+) life recovery per second from regeneration"] = function(num, _, div) return {
		mod("RageRegen", "BASE", num, {type = "PercentStat", stat = "LifeRegen", percent = tonumber(num/div*100) }),
		flag("Condition:CanGainRage"),
	} end,
	["when you lose temporal chains you gain maximum rage"] = { flag("Condition:CanGainRage") },
	["with a murderous eye jewel socketed, melee attacks grant (%d+) rage on hit, no more than once every second"] = { flag("Condition:CanGainRage", { type = "Condition", var = "HaveMurderousEyeJewelIn{SlotName}" }) },
	["gain %d+ rage after spending a total of %d+ mana"] = { flag("Condition:CanGainRage") },
	["rage grants cast speed instead of attack speed"] = { flag("Condition:RageCastSpeed") },
	["rage grants spell damage instead of attack damage"] = { flag("Condition:RageSpellDamage") },
	["your critical strike multiplier is (%d+)%%"] = function(num) return { mod("CritMultiplier", "OVERRIDE", num) } end,
	["base critical strike chance for attacks with weapons is ([%d%.]+)%%"] = function(num) return { mod("WeaponBaseCritChance", "OVERRIDE", num) } end,
	["base critical strike chance of spells is the critical strike chance of y?o?u?r? ?main hand weapon"] = { flag("BaseCritFromMainHand", nil, ModFlag.Spell) }, -- old wordings
	["base spell critical strike chance of spells is equal to that of main hand weapon"] = { flag("BaseCritFromMainHand", nil, ModFlag.Spell) },
	["critical strike chance is (%d+)%% for hits with this weapon"] = function(num) return { mod("CritChance", "OVERRIDE", num, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }) } end,
	["hits with this weapon have %+(%d+)%% to critical strike multiplier per enemy power"] = function(num) return { mod("CritMultiplier", "BASE", num, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack }, { type = "Multiplier", var = "EnemyPower"}) } end,
	["maximum critical strike chance is (%d+)%%"] = function(num) return {
		mod("CritChanceCap", "OVERRIDE", num),
	} end,
	["allocates (.+) if you have the matching modifiers? on forbidden (.+)"] = function(_, ascendancy, side) return { mod("GrantedAscendancyNode", "LIST", { side = side, name = ascendancy }) } end,
	["allocates (.+)"] = function(_, passive) return { mod("GrantedPassive", "LIST", passive) } end,
	["battlemage"] = { flag("Battlemage"), mod("MainHandWeaponDamageAppliesToSpells", "MAX", 100) },
	["transfiguration of body"] = { flag("TransfigurationOfBody") },
	["transfiguration of mind"] = { flag("TransfigurationOfMind") },
	["transfiguration of soul"] = { flag("TransfigurationOfSoul") },
	["offering skills have (%d+)%% increased duration"] = function(num) return {
		mod("Duration", "INC", num, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } }),
	} end,
	["offering skills have (%d+)%% reduced duration"] = function(num) return {
		mod("Duration", "INC", -num, { type = "SkillName", skillNameList = { "Bone Offering", "Flesh Offering", "Spirit Offering", "Blood Offering" } }),
	} end,
	["enemies have %-(%d+)%% to total physical damage reduction against your hits"] = function(num) return {
		mod("EnemyPhysicalDamageReduction", "BASE", -num),
	} end,
	["enemies you impale have %-(%d+)%% to total physical damage reduction against impale hits"] = function(num) return {
		mod("EnemyImpalePhysicalDamageReduction", "BASE", -num)
	} end,
	["hits with this weapon overwhelm (%d+)%% physical damage reduction"] = function(num) return {
		mod("EnemyPhysicalDamageReduction", "BASE", -num, nil, ModFlag.Hit, { type = "Condition", var = "{Hand}Attack" }, { type = "SkillType", skillType = SkillType.Attack })
	} end,
	["overwhelm (%d+)%% physical damage reduction"] = function(num) return {
		mod("EnemyPhysicalDamageReduction", "BASE", -num)
	} end,
	["hits against you overwhelm (%d+)%% of physical damage reduction"] = function(num) return {
		mod("EnemyPhysicalOverwhelm", "BASE", num)
	} end,
	["impale damage dealt to enemies impaled by you overwhelms (%d+)%% physical damage reduction"] = function(num) return {
		mod("EnemyImpalePhysicalDamageReduction", "BASE", -num)
	} end,
	["nearby enemies are crushed while you have ?a?t? least (%d+) rage"] = function(num) return {
		-- MultiplierThreshold is on RageStacks because Rage is only set in CalcPerform if Condition:CanGainRage is true, Bear's Girdle does not flag CanGainRage
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Crushed") }, { type = "MultiplierThreshold", var = "RageStack", threshold = num })
	} end,
	["you are crushed"] = { flag("Condition:Crushed") },
	["nearby enemies are crushed"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Crushed") }) },
	["crush enemies on hit with maces and sceptres"] = { mod("EnemyModifier", "LIST", { mod = flag("Condition:Crushed") }, { type = "Condition", var = "UsingMace" }) },
	["you have fungal ground around you while stationary"] = {
		mod("ExtraAura", "LIST", { mod = mod("NonChaosDamageGainAsChaos", "BASE", 10) }, { type = "Condition", varList = { "OnFungalGround", "Stationary" } }),
		mod("EnemyModifier", "LIST", { mod = mod("Damage", "MORE", -10) }, { type = "ActorCondition", actor = "enemy", varList = { "OnFungalGround", "Stationary" } }),
	},
	["create profane ground instead of consecrated ground"] = {
		flag("Condition:CreateProfaneGround"),
	},
	["(%d+)%% chance to create profane ground on critical strike if intelligence is your highest attribute"] = {
		flag("Condition:CreateProfaneGround", { type = "Condition", var = "IntHighestAttribute" }),
	},
	["consecrated path and purifying flame create profane ground instead of consecrated ground"] = {
		flag("Condition:CreateProfaneGround"),
	},
	["you have consecrated ground around you while stationary if strength is your highest attribute"] = {
		flag("Condition:OnConsecratedGround", { type = "Condition", var = "StrHighestAttribute" }, { type = "Condition", var = "Stationary" }),
	},
	["you count as dual wielding while you are unencumbered"] = { flag("Condition:DualWielding", { type = "Condition", var = "Unencumbered" }) },
	["dual wielding does not inherently grant chance to block attack damage"] = { flag("Condition:NoInherentBlock") },
	["inherent attack speed bonus from dual wielding is doubled while wielding two claws"] = {
	    flag("Condition:DoubledInherentSpeed", { type = "Condition", var = "DualWieldingClaws" })
	},
	["(%d+)%% reduced enemy chance to block sword attacks"] = function(num) return { mod("reduceEnemyBlock", "BASE", num, nil, ModFlag.Sword) } end,
	["you do not inherently take less damage for having fortification"] = { flag("Condition:NoFortificationMitigation") },
	["skills supported by intensify have %+(%d) to maximum intensity"] = function(num) return { mod("Multiplier:IntensityLimit", "BASE", num) } end,
	["spells which can gain intensity have %+(%d) to maximum intensity"] = function(num) return { mod("Multiplier:IntensityLimit", "BASE", num) } end,
	["final repeat of spells has (%d+)%% increased area of effect"] = function(num) return { mod("RepeatFinalAreaOfEffect", "INC", num, nil, ModFlag.Spell, 0, { type = "Condition", var = "CastOnFrostbolt", neg = true }, { type = "Condition", varList = {"averageRepeat", "alwaysFinalRepeat"} }) } end,
	["hexes you inflict have ([%+%-]%d+) to maximum doom"] = function(num) return { mod("MaxDoom", "BASE", num) } end,
	["while stationary, gain (%d+)%% increased area of effect every second, up to a maximum of (%d+)%%"] = function(num, _, limit) return {
		mod("AreaOfEffect", "INC", num, { type = "Multiplier", var = "StationarySeconds", globalLimit = tonumber(limit), globalLimitKey = "ExpansiveMight" }, { type = "Condition", var = "Stationary" }),
	} end,
	["fireball and rolling magma have (%d+)%% more area of effect"] = function(num) return { mod("AreaOfEffect", "MORE", num, { type = "SkillName", skillNameList = { "Fireball", "Rolling Magma" } }) } end,
	["attack skills have added lightning damage equal to (%d+)%% of maximum mana"] = function(num) return {
		mod("LightningMin", "BASE", 1, nil, ModFlag.Attack, { type = "PercentStat", stat = "Mana", percent = num }),
		mod("LightningMax", "BASE", 1, nil, ModFlag.Attack, { type = "PercentStat", stat = "Mana", percent = num }),
	} end,
	["arc and crackling lance gains added cold damage equal to (%d+)%% of mana cost, if mana cost is not higher than the maximum you could spend"] = function(num) return {
		mod("ColdMin", "BASE", 1, { type = "PercentStat", stat = "ManaCost", percent = num }, { type = "SkillName", skillNameList = { "Arc", "Crackling Lance" }, includeTransfigured = true }),
		mod("ColdMax", "BASE", 1, { type = "PercentStat", stat = "ManaCost", percent = num }, { type = "SkillName", skillNameList = { "Arc", "Crackling Lance" }, includeTransfigured = true }),
	} end,
	["forbidden rite and dark pact gains added chaos damage equal to (%d+)%% of mana cost, if mana cost is not higher than the maximum you could spend"] = function(num) return {
		mod("ChaosMin", "BASE", 1, { type = "PercentStat", stat = "ManaCost", percent = num }, { type = "SkillName", skillNameList = { "Forbidden Rite", "Dark Pact" }, includeTransfigured = true }),
		mod("ChaosMax", "BASE", 1, { type = "PercentStat", stat = "ManaCost", percent = num }, { type = "SkillName", skillNameList = { "Forbidden Rite", "Dark Pact" }, includeTransfigured = true }),
	} end,
	["herald of thunder's storms hit enemies with (%d+)%% increased frequency"] = function(num) return { mod("HeraldStormFrequency", "INC", num), } end,
	["storms hit enemies with (%d+)%% increased frequency"] = function(num) return { mod("HeraldStormFrequency", "INC", num), } end,
	["your critical strikes have a (%d+)%% chance to deal double damage"] = function(num) return { mod("DoubleDamageChanceOnCrit", "BASE", num) } end,
	["elemental skills deal triple damage"] = { mod("TripleDamageChance", "BASE", 100, { type = "SkillType", skillTypeList = { SkillType.Cold, SkillType.Fire, SkillType.Lightning } }), },
	["deal triple damage with elemental skills"] = { mod("TripleDamageChance", "BASE", 100, { type = "SkillType", skillTypeList = { SkillType.Cold, SkillType.Fire, SkillType.Lightning } }), },
	["skills supported by unleash have %+(%d) to maximum number of seals"] = function(num) return { mod("SealCount", "BASE", num) } end,
	["skills supported by unleash have (%d+)%% increased seal gain frequency"] = function(num) return { mod("SealGainFrequency", "INC", num) } end,
	["(%d+)%% increased critical strike chance with spells which remove the maximum number of seals"] = function(num) return { mod("MaxSealCrit", "INC", num) } end,
	["gain elusive on critical strike"] = {
		flag("Condition:CanBeElusive"),
	},
	["nearby enemies have (%a+) resistance equal to yours"] = function(_, res) return { flag("Enemy"..(res:gsub("^%l", string.upper)).."ResistEqualToYours") } end,
	["for each nearby corpse, regenerate ([%d%.]+)%% life per second, up to ([%d%.]+)%%"] = function(num, _, limit) return { mod("LifeRegenPercent", "BASE", num, { type = "Multiplier", var = "NearbyCorpse", limit = tonumber(limit), limitTotal = true }) } end,
	["gain sacrificial zeal when you use a skill, dealing you %d+%% of the skill's mana cost as physical damage per second"] = {
		flag("Condition:SacrificialZeal"),
	},
	["skills gain a base life cost equal to (%d+)%% of base mana cost"] = function(num) return {
		mod("ManaCostAsLifeCost", "BASE", num),
	} end,
	["skills gain a base energy shield cost equal to (%d+)%% of base mana cost"] = function(num) return {
		mod("ManaCostAsEnergyShieldCost", "BASE", num),
	} end,
    ["skills cost life instead of (%d+)%% of mana cost"] = function(num) return {
        mod("HybridManaAndLifeCost_Life", "BASE", num),
    } end,
	["(%d+)%% increased cost of arc and crackling lance"] = function(num) return {
		mod("Cost", "INC", num, { type = "SkillName", skillNameList = { "Arc", "Crackling Lance" }, includeTransfigured = true }),
	} end,
	["hits overwhelm (%d+)%% of physical damage reduction while you have sacrificial zeal"] = function(num) return {
		mod("EnemyPhysicalDamageReduction", "BASE", -num, nil, { type = "Condition", var = "SacrificialZeal" }),
	} end,
	["minions attacks overwhelm (%d+)%% physical damage reduction"] = function(num) return {
		mod("MinionModifier", "LIST", { mod = mod("EnemyPhysicalDamageReduction", "BASE", -num, { type = "SkillType", skillType = SkillType.Attack }) })
	} end,
	["focus has (%d+)%% increased cooldown recovery rate"] = function(num) return { mod("FocusCooldownRecovery", "INC", num, { type = "Condition", var = "Focused" }) } end,
	["focus has (%d+)%% reduced cooldown recovery rate"] = function(num) return { mod("FocusCooldownRecovery", "INC", -num, { type = "Condition", var = "Focused" }) } end,
	["(%d+)%% more frozen legion and general's cry cooldown recovery rate"] = function(num) return { mod("CooldownRecovery", "MORE", num, { type = "SkillName", skillNameList = { "Frozen Legion", "General's Cry" }, includeTransfigured = true }) } end,
	["flamethrower, seismic and lightning spire trap have (%d+)%% increased cooldown recovery rate"] = function(num) return { mod("CooldownRecovery", "INC", num, { type = "SkillName", skillNameList = { "Flamethrower Trap", "Seismic Trap", "Lightning Spire Trap" }, includeTransfigured = true }) } end,
	["flamethrower, seismic and lightning spire trap have %-(%d+) cooldown uses?"] = function(num) return { mod("AdditionalCooldownUses", "BASE", -num, { type = "SkillName", skillNameList = { "Flamethrower Trap", "Seismic Trap",  "Lightning Spire Trap" }, includeTransfigured = true }) } end,
	["your counterattacks have (%d+)%% reduced cooldown recovery rate"] = function(num) return { mod("CooldownRecovery", "INC", -num, { type = "SkillName", skillNameList = { "Reckoning", "Riposte", "Vengeance" } }) } end,
	["your counterattacks deal (%d+)%% more damage"] = function(num) return { mod("Damage", "MORE", num, { type = "SkillName", skillNameList = { "Reckoning", "Riposte", "Vengeance" } }) } end,
	["flameblast starts with (%d+) additional stages"] = function(num) return { mod("Multiplier:FlameblastMinimumStage", "BASE", num, 0, 0, { type = "GlobalEffect", effectType = "Buff", unscalable = true }) } end,
	["incinerate starts with (%d+) additional stages"] = function(num) return { mod("Multiplier:IncinerateMinimumStage", "BASE", num, 0, 0, { type = "GlobalEffect", effectType = "Buff", unscalable = true }) } end,
	["%+([%d%.]+) seconds to flameblast and incinerate cooldown"] = function(num) return {
		mod("ExtraSkillMod", "LIST", { mod = mod("SkillData", "LIST", { key = "cooldown", value = 0 }) }, { type = "SkillName", skillNameList = { "Incinerate", "Flameblast"}, includeTransfigured = true }),
		mod("CooldownRecovery", "BASE", num, { type = "SkillName", skillNameList = { "Incinerate", "Flameblast" }, includeTransfigured = true }) } end,
	["(%d+)%% chance to deal double damage with attacks if attack time is longer than 1 second"] = function(num) return {
		mod("DoubleDamageChance", "BASE", num, 0, 0, { type = "Condition", var = "OneSecondAttackTime" })
	} end,
	["elusive also grants %+(%d+)%% to critical strike multiplier for skills supported by nightblade"] = function(num) return { mod("NightbladeElusiveCritMultiplier", "BASE", num) } end,
	["skills supported by nightblade have (%d+)%% increased effect of elusive"] = function(num) return { mod("NightbladeSupportedElusiveEffect", "INC", num) } end,
	["nearby enemies are scorched"] = {
		mod("EnemyModifier", "LIST", { mod = flag("Condition:Scorched") }),
		mod("ScorchBase", "BASE", 10),
	},
	["hits have (%d+)%% chance to ignore enemy monster physical damage reduction"] = function (num) return {
		mod("PartialIgnoreEnemyPhysicalDamageReduction", "BASE", num),
	} end,
	["viper strike and pestilent strike deal (%d+)%% increased attack damage per frenzy charge"] = function(num) return { mod("Damage", "INC", num, nil, ModFlag.Attack, { type = "Multiplier", var = "FrenzyCharge" }, { type = "SkillName", skillNameList = { "Viper Strike", "Pestilent Strike" }, includeTransfigured = true }) } end,
	["shield charge and chain hook have (%d+)%% increased attack speed per (%d+) rampage kills"] = function(inc, _, num) return { mod("Speed", "INC", inc, nil, ModFlag.Attack, { type = "Multiplier", var = "Rampage", div = num, limit = 1000 / num, limitTotal = true }, { type = "SkillName", skillNameList = { "Shield Charge", "Chain Hook" }, includeTransfigured = true }) } end,
	["tectonic slam and infernal blow deal (%d+)%% increased attack damage per (%d+) armour"] = function(inc, _, num) return { mod("Damage", "INC", inc, nil, ModFlag.Attack, { type = "PerStat", stat = "Armour", div = num }, { type = "SkillName", skillNameList = { "Tectonic Slam", "Infernal Blow" }, includeTransfigured = true }) } end,
	["frozen sweep deals (%d+)%% less damage"] = function(num) return { mod("Damage", "MORE", -num, { type = "SkillName", skillName = "Frozen Sweep", includeTransfigured = true }) } end,
	["ice trap and lightning trap damage penetrates (%d+)%% of enemy elemental resistances"] = function(num) return {
		mod("LightningPenetration", "BASE", num, { type = "SkillName", skillNameList = { "Ice Trap", "Lightning Trap" }, includeTransfigured = true }),
		mod("ColdPenetration", "BASE", num, { type = "SkillName", skillNameList = { "Ice Trap", "Lightning Trap" }, includeTransfigured = true }),
		mod("FirePenetration", "BASE", num, { type = "SkillName", skillNameList = { "Ice Trap", "Lightning Trap" }, includeTransfigured = true }),
	} end,
	["volatile dead and cremation penetrate (%d+)%% fire resistance per (%d+) dexterity"] = function(inc, _, num) return { mod("FirePenetration", "BASE", inc, { type = "PerStat", stat = "Dex", div = num }, { type = "SkillName", skillNameList = { "Volatile Dead", "Cremation" }, includeTransfigured = true }) } end,
	["regenerate (%d+) mana per second while any enemy is in your righteous fire or scorching ray"] = function( num) return { mod("ManaRegen", "BASE", num, { type = "Condition", var = "InRFOrScorchingRay" }) } end,
	["%+(%d+)%% to wave of conviction damage over time multiplier per ([%d%.]+) seconds of duration expired"] = function(num) return { mod("WaveOfConvictionDurationDotMulti", "INC", num) } end,
	["when an enemy hit deals elemental damage to you, their resistance to those elements becomes zero for (%d+) seconds"] = { flag("Condition:HaveTrickstersSmile"), },
	-- Pantheon: Soul of Tukohama support
	["while stationary, gain ([%d%.]+)%% of life regenerated per second every second, up to a maximum of (%d+)%%"] = function(num, _, limit) return {
		mod("LifeRegenPercent", "BASE", num, { type = "Multiplier", var = "StationarySeconds", limit = tonumber(limit), limitTotal = true }, { type = "Condition", var = "Stationary" }),
	} end,
	-- Pantheon: Soul of Ryslatha support
	["life flasks gain (%d+) charges? every (%d+) seconds if you haven't used a life flask recently"] = function(num, _, div) return {
		mod("LifeFlaskChargesGenerated", "BASE", num / div, { type = "Condition", var = "UsingLifeFlask", neg = true })
	} end,
	-- Skill-specific enchantment modifiers
	["(%d+)%% increased decoy totem life"] = function(num) return { mod("TotemLife", "INC", num, { type = "SkillName", skillName = "Decoy Totem" }) } end,
	["(%d+)%% increased ice spear critical strike chance in second form"] = function(num) return { mod("CritChance", "INC", num, { type = "SkillName", skillName = "Ice Spear", includeTransfigured = true }, { type = "SkillPart", skillPartList = { 2, 4 } }) } end,
	["shock nova ring deals (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num, { type = "SkillName", skillName = "Shock Nova", includeTransfigured = true }, { type = "SkillPart", skillPart = 1 }) } end,
	["enemies affected by bear trap take (%d+)%% increased damage from trap or mine hits"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("EnemyModifier", "LIST", { mod = mod("TrapMineDamageTaken", "INC", num, { type = "GlobalEffect", effectType = "Debuff" }) }) }, { type = "SkillName", skillName = "Bear Trap", includeTransfigured = true }) } end,
	["blade vortex has %+(%d+)%% to critical strike multiplier for each blade"] = function(num) return { mod("CritMultiplier", "BASE", num, { type = "Multiplier", var = "BladeVortexBlade" }, { type = "SkillName", skillName = "Blade Vortex", includeTransfigured = true }) } end,
	["burning arrow has (%d+)%% increased debuff effect"] = function(num) return { mod("DebuffEffect", "INC", num, { type = "SkillName", skillName = "Burning Arrow" }) } end,
	["double strike has a (%d+)%% chance to deal double damage to bleeding enemies"] = function(num) return { mod("DoubleDamageChance", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }, { type = "SkillName", skillName = "Double Strike", includeTransfigured = true }) } end,
	["frost bomb has (%d+)%% increased debuff duration"] = function(num) return { mod("SecondaryDuration", "INC", num, { type = "SkillName", skillName = "Frost Bomb" }) } end,
	["incinerate has %+(%d+) to maximum stages"] = function(num) return { mod("Multiplier:IncinerateMaxStages", "BASE", num, { type = "SkillName", skillName = "Incinerate" }) } end,
	["perforate creates %+(%d+) spikes?"] = function(num) return { mod("Multiplier:PerforateMaxSpikes", "BASE", num) } end,
	["scourge arrow has (%d+)%% chance to poison per stage"] = function(num) return { mod("PoisonChance", "BASE", num, { type = "SkillName", skillName = "Scourge Arrow", includeTransfigured = true }, { type = "Multiplier", var = "ScourgeArrowStage" }) } end,
	["winter orb has %+(%d+) maximum stages"] = function(num) return { mod("Multiplier:WinterOrbMaxStages", "BASE", num) } end,
	["summoned holy relics have (%d+)%% increased buff effect"] = function(num) return { mod("BuffEffect", "INC", num, { type = "SkillName", skillName = "Summon Holy Relic" }) } end,
	["%+(%d) to maximum virulence"] = function(num) return { mod("Multiplier:VirulenceStacksMax", "BASE", num) } end,
	["winter orb has (%d+)%% increased area of effect per stage"] = function(num) return { mod("AreaOfEffect", "INC", num, { type = "SkillName", skillName = "Winter Orb" }, { type = "Multiplier", var = "WinterOrbStage" }) } end,
	["wintertide brand has %+(%d+) to maximum stages"] = function(num) return { mod("Multiplier:WintertideBrandMaxStages", "BASE", num, { type = "SkillName", skillName = "Wintertide Brand" }) } end,
	["wave of conviction's exposure applies (%-%d+)%% elemental resistance"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "purge_expose_resist_%_matching_highest_element_damage", value = num }, { type = "SkillName", skillName = "Wave of Conviction" }) } end,
	["wave of conviction's exposure applies an extra (%-%d+)%% to elemental resistance"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "purge_expose_resist_%_matching_highest_element_damage", value = num }, { type = "SkillName", skillName = "Wave of Conviction" }) } end,
	["arcane cloak spends an additional (%d+)%% of current mana"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "arcane_cloak_consume_%_of_mana", value = num }, { type = "SkillName", skillName = "Arcane Cloak" }) } end,
	["arcane cloak grants life regeneration equal to (%d+)%% of mana spent per second"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("LifeRegen", "BASE", num / 100, 0, 0, { type = "Multiplier", var = "ArcaneCloakConsumedMana" }, { type = "GlobalEffect", effectType = "Buff" }) }, { type = "SkillName", skillName = "Arcane Cloak" }) } end,
	["caustic arrow has (%d+)%% chance to inflict withered on hit for (%d+) seconds base duration"] = { mod("ExtraSkillMod", "LIST", { mod = flag("Condition:CanWither") }, { type = "SkillName", skillName = "Caustic Arrow", includeTransfigured = true }) },
	["venom gyre has a (%d+)%% chance to inflict withered for (%d+) seconds on hit"] = { mod("ExtraSkillMod", "LIST", { mod = flag("Condition:CanWither") }, { type = "SkillName", skillName = "Venom Gyre" }) },
	["sigil of power's buff also grants (%d+)%% increased critical strike chance per stage"] = function(num) return { mod("CritChance", "INC", num, 0, 0, { type = "Multiplier", var = "SigilOfPowerStage", limit = 4 }, { type = "GlobalEffect", effectType = "Buff", effectName = "Sigil of Power" }) } end,
	["cobra lash chains (%d+) additional times"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = "Cobra Lash" }) } end,
	["general's cry has ([%+%-]%d) to maximum number of mirage warriors"] = function(num) return { mod("GeneralsCryDoubleMaxCount", "BASE", num) } end,
	["([%+%-]%d) to maximum blade flurry stages"] = function(num) return { mod("Multiplier:BladeFlurryMaxStages", "BASE", num), mod("Multiplier:BladeFlurryofIncisionMaxStages", "BASE", num) } end,
	["steelskin buff can take (%d+)%% increased amount of damage"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "steelskin_damage_limit_+%", value = num }, { type = "SkillName", skillName = "Steelskin" }) } end,
	["hydrosphere has (%d+)%% increased pulse frequency"] = function(num) return { mod("HydroSphereFrequency", "INC", num) } end,
	["void sphere has (%d+)%% increased pulse frequency"] = function(num) return { mod("VoidSphereFrequency", "INC", num) } end,
	["shield crush central wave has (%d+)%% more area of effect"] = function(num) return { mod("AreaOfEffect", "MORE", num, { type = "SkillName", skillName = "Shield Crush", includeTransfigured = true }, { type = "SkillPart", skillPart = 2 }) } end,
	["storm rain has (%d+)%% increased beam frequency"] = function(num) return { mod("StormRainBeamFrequency", "INC", num) } end,
	["voltaxic burst deals (%d+)%% increased damage per ([%d%.]+) seconds of duration"] = function(num) return { mod("VoltaxicDurationIncDamage", "INC", num) } end,
	["earthquake deals (%d+)%% increased damage per ([%d%.]+) seconds duration"] = function(num) return { mod("EarthquakeDurationIncDamage", "INC", num) } end,
	["consecrated ground from holy flame totem applies (%d+)%% increased damage taken to enemies"] = function(num) return { mod("EnemyModifier", "LIST", { mod = mod("DamageTakenConsecratedGround", "INC", num, { type = "Condition", var = "OnConsecratedGround" }) }) } end,
	["consecrated ground from purifying flame applies (%d+)%% increased damage taken to enemies"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "consecrated_ground_enemy_damage_taken_+%", value = num }, { type = "SkillName", skillName = "Purifying Flame", includeTransfigured = true }) } end,
	["enemies drenched by hydrosphere have cold and lightning exposure, applying (%-%d+)%% to resistances"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "water_sphere_cold_lightning_exposure_%", value = num }, { type = "SkillName", skillName = "Hydrosphere" }) } end,
	["frost shield has %+(%d+) to maximum life per stage"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "frost_globe_health_per_stage", value = num }, { type = "SkillName", skillName = "Frost Shield" }) } end,
	["flame wall grants (%d+) to (%d+) added fire damage to projectiles"] = function(_, min, max) return { mod("ExtraSkillStat", "LIST", { key = "flame_wall_minimum_added_fire_damage", value = min }, { type = "SkillName", skillName = "Flame Wall" }), mod("ExtraSkillStat", "LIST",  { key = "flame_wall_maximum_added_fire_damage", value = max }, { type = "SkillName", skillName = "Flame Wall" }) } end,
	["plague bearer buff grants %+(%d+)%% to poison damage over time multiplier while infecting"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "corrosive_shroud_poison_dot_multiplier_+_while_aura_active", value = num }, { type = "SkillName", skillName = "Plague Bearer" }) } end,
	["(%d+)%% increased lightning trap lightning ailment effect"] = function(num) return { mod("ExtraSkillStat", "LIST", { key = "shock_effect_+%", value = num }, { type = "SkillName", skillName = "Lightning Trap", includeTransfigured = true }) } end,
	["wild strike's beam chains an additional (%d+) times"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = "Wild Strike", includeTransfigured = true }, { type = "SkillPart", skillPart = 4 }) } end,
	["energy blades have (%d+)%% increased attack speed"] = function(num) return { mod("EnergyBladeAttackSpeed", "INC", num) } end,
	["ensnaring arrow has (%d+)%% increased debuff effect"] = function(num) return { mod("DebuffEffect", "INC", num, { type = "SkillName", skillName = "Ensnaring Arrow" }) } end,
	["unearth spawns corpses with ([%+%-]%d) level"] = function(num) return { mod("CorpseLevel", "BASE", num, { type = "SkillName", skillName = "Unearth" }) } end,
	["seismic trap releases an additional wave"] = { mod("MaximumWaves", "BASE", 1, { type = "SkillName", skillName = "Seismic Trap", includeTransfigured = true }) },
	["lightning spire trap strikes an additional area"] = { mod("MaximumWaves", "BASE", 1, { type = "SkillName", skillName = "Lightning Spire Trap", includeTransfigured = true }) },
	["explosive trap causes (%d+) additional smaller explosions"] = function(num) return { mod("SmallExplosions", "BASE", num, { type = "SkillName", skillNameList = { "Explosive Trap", "Explosive Trap of Swells"} }) } end,
	["frozen sweep deals (%d+)%% increased damage"] = function(num) return { mod("Damage", "INC", num, { type = "SkillName", skillName = "Frozen Sweep", includeTransfigured = true }) } end,
	["(%d+)%% increased attack speed with snipe"] = function(num) return { mod("Speed", "INC", num, nil, ModFlag.Attack, { type = "SkillName", skillName = "Snipe" }) } end,
	["%+(%d+) to maximum snipe stages"] = function(num) return { mod("Multiplier:SnipeStagesMax", "BASE", num, 0, 0, { type = "GlobalEffect", effectType = "Buff", unscalable = true }) } end,
	["chain hook has %+([%d%.]+) metres? to radius per (%d+) rage"] = function(num, _, rage) return { mod("AreaOfEffect", "BASE", num * 10, { type = "PerStat", stat = "Rage", div = tonumber(rage) }, { type = "SkillName", skillName = "Chain Hook", includeTransfigured = true }) } end,
	["%+([%d%.]+) metres? to discharge radius"] = function(num) return { mod("AreaOfEffect", "BASE", num * 10, { type = "SkillName", skillName = "Discharge", includeTransfigured = true }) } end,
	-- Alternate Quality
	["quality does not increase physical damage"] = { mod("AlternateQualityWeapon", "BASE", 1) },
	["(%d+)%% increased critical strike chance per 4%% quality"] = function(num) return { mod("AlternateQualityLocalCritChancePer4Quality", "INC", num) } end,
	["grants (%d+)%% increased accuracy per (%d+)%% quality"] = function(num, _, div) return { mod("Accuracy", "INC", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["(%d+)%% increased attack speed per 8%% quality"] = function(num) return { mod("AlternateQualityLocalAttackSpeedPer8Quality", "INC", num) } end,
	["%+(%d+) weapon range per 10%% quality"] = function(num) return { mod("AlternateQualityLocalWeaponRangePer10Quality", "BASE", num) } end,
	["%+([%d%.]+) metres? to weapon range per 10%% quality"] = function(num) return { mod("AlternateQualityLocalWeaponRangePer10Quality", "BASE", num * 10) } end,
	["grants (%d+)%% increased elemental damage per (%d+)%% quality"] = function(num, _, div) return { mod("ElementalDamage", "INC", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants (%d+)%% increased area of effect per (%d+)%% quality"] = function(num, _, div) return { mod("AreaOfEffect", "INC", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["quality does not increase defences"] = { mod("AlternateQualityArmour", "BASE", 1) },
	["grants %+(%d+) to maximum life per (%d+)%% quality"] = function(num, _, div) return { mod("Life", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+) to maximum mana per (%d+)%% quality"] = function(num, _, div) return { mod("Mana", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+) to strength per (%d+)%% quality"] = function(num, _, div) return { mod("Str", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+) to dexterity per (%d+)%% quality"] = function(num, _, div) return { mod("Dex", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+) to intelligence per (%d+)%% quality"] = function(num, _, div) return { mod("Int", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+)%% to fire resistance per (%d+)%% quality"] = function(num, _, div) return { mod("FireResist", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+)%% to cold resistance per (%d+)%% quality"] = function(num, _, div) return { mod("ColdResist", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["grants %+(%d+)%% to lightning resistance per (%d+)%% quality"] = function(num, _, div) return { mod("LightningResist", "BASE", num, { type = "Multiplier", var = "QualityOn{SlotName}", div = tonumber(div) }) } end,
	["%+(%d+)%% to quality"] = function(num) return { mod("Quality", "BASE", num) } end,
	["infernal blow debuff deals an additional (%d+)%% of damage per charge"] = function(num) return { mod("DebuffEffect", "BASE", num, { type = "SkillName", skillName = "Infernal Blow", includeTransfigured = true }) } end,
	-- Legion modifiers
	["bathed in the blood of (%d+) sacrificed in the name of (.+)"] =  function(num, _, name)
		return { mod("JewelData", "LIST",
				{ key = "conqueredBy", value = { id = num, conqueror = conquerorList[name:lower()] } }) } end,
	["carved to glorify (%d+) new faithful converted by high templar (.+)"] =  function(num, _, name)
		return { mod("JewelData", "LIST",
				{ key = "conqueredBy", value = { id = num, conqueror = conquerorList[name:lower()] } }) } end,
	["commanded leadership over (%d+) warriors under (.+)"] =  function(num, _, name)
		return { mod("JewelData", "LIST",
				{ key = "conqueredBy", value = { id = num, conqueror = conquerorList[name:lower()] } }) } end,
	["commissioned (%d+) coins to commemorate (.+)"] =  function(num, _, name)
		return { mod("JewelData", "LIST",
				{ key = "conqueredBy", value = { id = num, conqueror = conquerorList[name:lower()] } }) } end,
	["denoted service of (%d+) dekhara in the akhara of (.+)"] =  function(num, _, name)
		return { mod("JewelData", "LIST",
				{ key = "conqueredBy", value = { id = num, conqueror = conquerorList[name:lower()] } }) } end,
	["passives in radius are conquered by the (%D+)"] = { },
	["historic"] = { },
	-- Tattoos
	["+(%d+) to maximum life per allocated journey tattoo of the body"] = function(num) return {
		mod("Life", "BASE", num, { type = "Multiplier", var = "JourneyTattooBody" }),
		mod("Multiplier:JourneyTattooBody", "BASE", 1),
	} end,
	["+(%d+) to maximum energy shield per allocated journey tattoo of the soul"] = function(num) return {
		mod("EnergyShield", "BASE", num, { type = "Multiplier", var = "JourneyTattooSoul" }),
		mod("Multiplier:JourneyTattooSoul", "BASE", 1),
	} end,
	["+(%d+) to maximum mana per allocated journey tattoo of the mind"] = function(num) return {
		mod("Mana", "BASE", num, { type = "Multiplier", var = "JourneyTattooMind" }),
		mod("Multiplier:JourneyTattooMind", "BASE", 1),
	} end,
	-- Display-only modifiers
	["extra gore"] = { },
	["prefixes:"] = { },
	["suffixes:"] = { },
	["while your passive skill tree connects to a class' starting location, you gain:"] = { },
	["socketed lightning spells [hd][ae][va][el] (%d+)%% increased spell damage if triggered"] = { },
	["manifeste?d? dancing dervishe?s? disables both weapon slots"] = { },
	["manifeste?d? dancing dervishe?s? dies? when rampage ends"] = { },
	["survival"] = { },
	["you can have two different banners at the same time"] = { },
	["can have a second enchantment modifier"] = { },
	["can have (%d+) additional enchantment modifiers"] = { },
	["this item can be anointed by cassia"] = { },
	["has a crucible passive skill tree"] = { },
	["has a two handed sword crucible passive skill tree"] = { },
	["has a crucible passive skill tree with only support passive skills"] = { },
	["crucible passive skill tree is removed if this modifier is removed"] = { },
	["all sockets are white"] = { },
	["every (%d+) seconds, regenerate (%d+)%% of life over one second"] = function (num, _, percent) return {
		mod("LifeRegenPercent", "BASE", tonumber(percent), { type = "Condition", var = "LifeRegenBurstFull" }),
		mod("LifeRegenPercent", "BASE", tonumber(percent) / num, { type = "Condition", var = "LifeRegenBurstAvg" }),
	} end,
	["take no extra damage from critical strikes"] = { mod("ReduceCritExtraDamage", "BASE", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }) },
	["take no extra damage from critical strikes if you've cast (.-) in the past (%d+) seconds"] = function (_, curse) return {
		mod("ReduceCritExtraDamage", "BASE", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }, { type = "Condition", var = "SelfCast"..curse:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", "") })
	} end,
	["take no extra damage from critical strikes if you have a magic ring in left slot"] = {
		mod("ReduceCritExtraDamage", "BASE", 100, { type = "GlobalEffect", effectType = "Global", unscalable = true }, { type = "Condition", var = "MagicItemInRing 1" })
	},
	["you take (%d+)%% reduced extra damage from critical strikes while affected by determination"] = function(num) return {
		mod("ReduceCritExtraDamage", "BASE", num, { type = "Condition", var = "AffectedByDetermination" })
	} end,
	["you take (%d+)%% reduced extra damage from critical strikes"] = function(num) return { mod("ReduceCritExtraDamage", "BASE", num) } end,
	["you take (%d+)%% increased extra damage from critical strikes"] = function(num) return { mod("ReduceCritExtraDamage", "BASE", -num) } end,
	["you take (%d+)%% reduced extra damage from critical strikes while you have no power charges"] = function(num) return { mod("ReduceCritExtraDamage", "BASE", num, { type = "StatThreshold", stat = "PowerCharges", threshold = 0, upper = true }) } end,
	["you take (%d+)%% reduced extra damage from critical strikes by poisoned enemies"] = function(num) return { mod("ReduceCritExtraDamage", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Poisoned" }) } end,
	["you take (%d+)%% reduced extra damage from critical strikes by cursed enemies"] = function(num) return { mod("ReduceCritExtraDamage", "BASE", num, { type = "ActorCondition", actor = "enemy", var = "Cursed" }) } end,
	["nearby allies have (%d+)%% chance to block attack damage per (%d+) strength you have"] = function(block, _, str) return {
		mod("ExtraAura", "LIST", { onlyAllies = true, mod = mod("BlockChance", "BASE", block) }, { type = "PerStat", stat = "Str", div = tonumber(str) }),
	} end,
}
for _, name in pairs(data.keystones) do
	specialModList[name:lower()] = { mod("Keystone", "LIST", name) }
end
local oldList = specialModList
specialModList = { }
for k, v in pairs(oldList) do
	specialModList["^"..k.."$"] = v
end

-- Modifiers that are recognised but unsupported
local unsupportedModList = {
	["properties are doubled while in a breach"] = true,
	["mirrored"] = true,
	["split"] = true,
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
	["converted to fire"] = "ConvertToFire",
	["converted to chaos damage"] = "ConvertToChaos",
	["added as energy shield"] = "GainAsEnergyShield",
	["as extra maximum energy shield"] = "GainAsEnergyShield",
	["converted to energy shield"] = "ConvertToEnergyShield",
	["as extra armour"] = "GainAsArmour",
	["as physical damage"] = "AsPhysical",
	["as lightning damage"] = "AsLightning",
	["as cold damage"] = "AsCold",
	["as fire damage"] = "AsFire",
	["as fire"] = "AsFire",
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
local resourceTypes = {
	["life"] = "Life",
	["mana"] = "Mana",
	["energy shield"] = "EnergyShield",
	["life and mana"] = { "Life", "Mana" },
	["life and energy shield"] = { "Life", "EnergyShield" },
	["life, mana and energy shield"] = { "Life", "Mana", "EnergyShield" },
	["life, energy shield and mana"] = { "Life", "Mana", "EnergyShield" },
	["mana and life"] = { "Life", "Mana" },
	["mana and energy shield"] = { "Mana", "EnergyShield" },
	["mana, life and energy shield"] = { "Life", "Mana", "EnergyShield" },
	["mana, energy shield and life"] = { "Life", "Mana", "EnergyShield" },
	["energy shield and life"] = { "Life", "EnergyShield" },
	["energy shield and mana"] = { "Mana", "EnergyShield" },
	["energy shield, life and mana"] = { "Life", "Mana", "EnergyShield" },
	["energy shield, mana and life"] = { "Life", "Mana", "EnergyShield" },
	["rage"] = "Rage",
}
do
	local maximumResourceTypes = { }
	for resource, values in pairs(resourceTypes) do
		maximumResourceTypes["maximum "..resource] = values
	end
	for resource, values in pairs(maximumResourceTypes) do
		resourceTypes[resource] = values
	end
end
local function appendMod(inputTable, string)
	local table = { }
	for subLine, mods in pairs(inputTable) do
		if type(mods) == "string" then
			table[subLine] = mods..string
		else
			table[subLine] = { }
			for _, mod in ipairs(mods) do
				t_insert(table[subLine], mod..string)
			end
		end
	end
	return table
end
local regenTypes = appendMod(resourceTypes, "Regen")
local degenTypes = appendMod(resourceTypes, "Degen")
local costTypes = appendMod(resourceTypes, "Cost")
local baseCostTypes = appendMod(resourceTypes, "CostNoMult")
local flagTypes = {
	["phasing"] = "Condition:Phasing",
	["onslaught"] = "Condition:Onslaught",
	["rampage"] = "Condition:Rampage",
	["soul eater"] = "Condition:CanHaveSoulEater",
	["adrenaline"] = "Condition:Adrenaline",
	["elusive"] = "Condition:CanBeElusive",
	["arcane surge"] = "Condition:ArcaneSurge",
	["fortify"] = "Condition:Fortified",
	["fortified"] = "Condition:Fortified",
	["unholy might"] = "Condition:UnholyMight",
	["chaotic might"] = "Condition:ChaoticMight",
	["lesser brutal shrine buff"] = "Condition:LesserBrutalShrine",
	["lesser massive shrine buff"] = "Condition:LesserMassiveShrine",
	["tailwind"] = "Condition:Tailwind",
	["intimidated"] = "Condition:Intimidated",
	["crushed"] = "Condition:Crushed",
	["chilled"] = "Condition:Chilled",
	["blinded"] = "Condition:Blinded",
	["no life regeneration"] = "NoLifeRegen",
	["hexproof"] = { name = "CurseEffectOnSelf", value = -100, type = "MORE" },
	["hindered,? with (%d+)%% reduced movement speed"] = "Condition:Hindered",
	["unnerved"] = "Condition:Unnerved",
	["malediction"] = "HasMalediction",
}

-- Build active skill name lookup
local skillNameList = {
	[" corpse cremation " ] = { tag = { type = "SkillName", skillName = "Cremation", includeTransfigured = true }}, -- Sigh.
}
local preSkillNameList = { }
for gemId, gemData in pairs(data.gems) do
	local grantedEffect = gemData.grantedEffect
	if not grantedEffect.hidden and not grantedEffect.support then
		local skillName = grantedEffect.name
		skillNameList[" "..skillName:lower().." "] = { tag = { type = "SkillName", skillName = skillName, includeTransfigured = true } }
		preSkillNameList["^"..skillName:lower().." "] = { tag = { type = "SkillName", skillName = skillName, includeTransfigured = true } }
		preSkillNameList["^"..skillName:lower().." has ?a? "] = { tag = { type = "SkillName", skillName = skillName, includeTransfigured = true } }
		preSkillNameList["^"..skillName:lower().." deals "] = { tag = { type = "SkillName", skillName = skillName, includeTransfigured = true } }
		preSkillNameList["^"..skillName:lower().." damage "] = { tag = { type = "SkillName", skillName = skillName, includeTransfigured = true } }
		if gemData.tags.totem then
			preSkillNameList["^"..skillName:lower().." totem deals "] = { tag = { type = "SkillName", skillName = skillName, includeTransfigured = true } }
			preSkillNameList["^"..skillName:lower().." totem grants "] = { addToSkill = { type = "SkillName", skillName = skillName, includeTransfigured = true }, tag = { type = "GlobalEffect", effectType = "Buff" } }
		end
		if grantedEffect.skillTypes[SkillType.Buff] or grantedEffect.baseFlags.buff then
			preSkillNameList["^"..skillName:lower().." grants "] = { addToSkill = { type = "SkillName", skillName = skillName, includeTransfigured = true }, tag = { type = "GlobalEffect", effectType = "Buff" } }
			preSkillNameList["^"..skillName:lower().." grants a?n? ?additional "] = { addToSkill = { type = "SkillName", skillName = skillName, includeTransfigured = true }, tag = { type = "GlobalEffect", effectType = "Buff" } }
		end
		if gemData.tags.aura or gemData.tags.herald then
			skillNameList["while affected by "..skillName:lower()] = { tag = { type = "Condition", var = "AffectedBy"..skillName:gsub(" ","") } }
			skillNameList["while using "..skillName:lower()] = { tag = { type = "Condition", var = "AffectedBy"..skillName:gsub(" ","") } }
		end
		if gemData.tags.curse then
			skillNameList["if you've cast "..skillName:lower().." in the past (%d+) seconds"] = { tag = { type = "Condition", var = "SelfCast"..skillName:gsub("^%l", string.upper):gsub(" %l", string.upper):gsub(" ", ""):gsub(" ","") } }
		end
		if gemData.tags.mine then
			specialModList["^"..skillName:lower().." has (%d+)%% increased throwing speed"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("MineLayingSpeed", "INC", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
		end
		if gemData.tags.trap then
			specialModList["(%d+)%% increased "..skillName:lower().." throwing speed"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("TrapThrowingSpeed", "INC", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
		end
		if gemData.tags.chaining then
			specialModList["^"..skillName:lower().." chains an additional time"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", 1) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) }
			specialModList["^"..skillName:lower().." chains an additional (%d+) times"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
			specialModList["^"..skillName:lower().." chains (%d+) additional times"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ChainCountMax", "BASE", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
		end
		if gemData.tags.bow then
			specialModList["^"..skillName:lower().." fires an additional arrow"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", 1) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
			specialModList["^"..skillName:lower().." fires (%d+) additional arrows?"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
		end
		if gemData.tags.projectile then
			specialModList["^"..skillName:lower().." pierces an additional target"] = { mod("PierceCount", "BASE", 1, { type = "SkillName", skillName = skillName, includeTransfigured = true }) }
			specialModList["^"..skillName:lower().." pierces (%d+) additional targets?"] = function(num) return { mod("PierceCount", "BASE", num, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
		end
		if gemData.tags.bow or gemData.tags.projectile then
			specialModList["^"..skillName:lower().." fires an additional projectile"] = { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", 1) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) }
			specialModList["^"..skillName:lower().." fires (%d+) additional projectiles"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
			specialModList["^"..skillName:lower().." fires (%d+) additional shard projectiles"] = function(num) return { mod("ExtraSkillMod", "LIST", { mod = mod("ProjectileCount", "BASE", num) }, { type = "SkillName", skillName = skillName, includeTransfigured = true }) } end
		end
	end
end

local jewelOtherFuncs = {
	["Strength from Passives in Radius is Transformed to Dexterity"] = getSimpleConv({ "Str" }, "Dex", "BASE", true),
	["Dexterity from Passives in Radius is Transformed to Strength"] = getSimpleConv({ "Dex" }, "Str", "BASE", true),
	["Strength from Passives in Radius is Transformed to Intelligence"] = getSimpleConv({ "Str" }, "Int", "BASE", true),
	["Intelligence from Passives in Radius is Transformed to Strength"] = getSimpleConv({ "Int" }, "Str", "BASE", true),
	["Dexterity from Passives in Radius is Transformed to Intelligence"] = getSimpleConv({ "Dex" }, "Int", "BASE", true),
	["Intelligence from Passives in Radius is Transformed to Dexterity"] = getSimpleConv({ "Int" }, "Dex", "BASE", true),
	["Increases and Reductions to Life in Radius are Transformed to apply to Energy Shield"] = getSimpleConv({ "Life" }, "EnergyShield", "INC", true),
	["Increases and Reductions to Energy Shield in Radius are Transformed to apply to Armour at 200% of their value"] = getSimpleConv({ "EnergyShield" }, "Armour", "INC", true, 2),
	["Increases and Reductions to Life in Radius are Transformed to apply to Mana at 200% of their value"] = getSimpleConv({ "Life" }, "Mana", "INC", true, 2),
	["Increases and Reductions to Physical Damage in Radius are Transformed to apply to Cold Damage"] = getSimpleConv({ "PhysicalDamage" }, "ColdDamage", "INC", true),
	["Increases and Reductions to Cold Damage in Radius are Transformed to apply to Physical Damage"] = getSimpleConv({ "ColdDamage" }, "PhysicalDamage", "INC", true),
	["Increases and Reductions to other Damage Types in Radius are Transformed to apply to Fire Damage"] = getSimpleConv({ "PhysicalDamage","ColdDamage","LightningDamage","ChaosDamage","ElementalDamage" }, "FireDamage", "INC", true),
	["Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spells at 35% of its value"] = getSimpleConv({ "LightningResist","ElementalResist" }, "SpellBlockChance", "BASE", false, 0.35),
	["Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spell Damage at 35% of its value"] = getSimpleConv({ "LightningResist","ElementalResist" }, "SpellBlockChance", "BASE", false, 0.35),
	["Passives granting Lightning Resistance or all Elemental Resistances in Radius also grant Chance to Block Spell Damage at 50% of its value"] = getSimpleConv({ "LightningResist","ElementalResist" }, "SpellBlockChance", "BASE", false, 0.5),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Dodge Attacks at 35% of its value"] = getSimpleConv({ "ColdResist","ElementalResist" }, "AttackDodgeChance", "BASE", false, 0.35),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Dodge Attack Hits at 35% of its value"] = getSimpleConv({ "ColdResist","ElementalResist" }, "AttackDodgeChance", "BASE", false, 0.35),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Suppress Spell Damage at 35% of its value"] = getSimpleConv({ "ColdResist","ElementalResist" }, "SpellSuppressionChance", "BASE", false, 0.35),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Suppress Spell Damage at 50% of its value"] = getSimpleConv({ "ColdResist","ElementalResist" }, "SpellSuppressionChance", "BASE", false, 0.5),
	["Passives granting Cold Resistance or all Elemental Resistances in Radius also grant Chance to Suppress Spell Damage at 70% of its value"] = getSimpleConv({ "ColdResist","ElementalResist" }, "SpellSuppressionChance", "BASE", false, 0.7),
	["Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block Attack Damage at 35% of its value"] = getSimpleConv({ "FireResist","ElementalResist" }, "BlockChance", "BASE", false, 0.35),
	["Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block Attack Damage at 50% of its value"] = getSimpleConv({ "FireResist","ElementalResist" }, "BlockChance", "BASE", false, 0.5),
	["Passives granting Fire Resistance or all Elemental Resistances in Radius also grant Chance to Block at 35% of its value"] = getSimpleConv({ "FireResist","ElementalResist" }, "BlockChance", "BASE", false, 0.35),
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
	["100% increased effect of Tattoos in Radius"] = function(node, out, data)
		if node and node.isTattoo then
			out:NewMod("PassiveSkillEffect", "INC", 100, data.modSource)
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
	["Passive Skills in Radius also grant: (%d+)%% increased Unarmed Attack Speed with Melee Skills"] = function(num)
		return function(node, out, data)
			if node and node.type ~= "Keystone" then
				out:NewMod("Speed", "INC", num, data.modSource, bor(ModFlag.Unarmed, ModFlag.Attack, ModFlag.Melee))
			end
		end
	end,
	["Passive Skills in Radius also grant (%d+)%% increased Global Critical Strike Chance"] = function(num)
		return function(node, out, data)
			if node and node.type ~= "Keystone" then
				out:NewMod("CritChance", "INC", num, data.modSource)
			end
		end
	end,
	["Passive Skills in Radius also grant %+(%d+) to Maximum Life"] = function(num)
		return function(node, out, data)
			if node and node.type ~= "Keystone" then
				out:NewMod("Life", "BASE", num, data.modSource)
			end
		end
	end,
	["Notable Passive Skills in Radius are Transformed to instead grant: 10% increased Mana Cost of Skills and 20% increased Spell Damage"] = function(node, out, data)
		if node and node.type == "Notable" then
			out:NewMod("PassiveSkillHasOtherEffect", "FLAG", true, data.modSource)
			out:NewMod("NodeModifier", "LIST", { mod = mod("ManaCost", "INC", 10, data.modSource) }, data.modSource)
			out:NewMod("NodeModifier", "LIST", { mod = mod("Damage", "INC", 20, data.modSource, ModFlag.Spell) }, data.modSource)
		end
	end,
	["Notable Passive Skills in Radius are Transformed to instead grant: Minions take 20% increased Damage"] = function(node, out, data)
		if node and node.type == "Notable" then
			out:NewMod("PassiveSkillHasOtherEffect", "FLAG", true, data.modSource)
			out:NewMod("NodeModifier", "LIST", { mod = mod("MinionModifier", "LIST", { mod = mod("DamageTaken", "INC", 20, data.modSource) }) }, data.modSource)
		end
	end,
	["Notable Passive Skills in Radius are Transformed to instead grant: Minions have 25% reduced Movement Speed"] = function(node, out, data)
		if node and node.type == "Notable" then
			out:NewMod("PassiveSkillHasOtherEffect", "FLAG", true, data.modSource)
			out:NewMod("NodeModifier", "LIST", { mod = mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", -25, data.modSource) }) }, data.modSource)
		end
	end,
}

-- Radius jewels that modify the jewel itself based on nearby allocated nodes
local function getPerStat(dst, modType, flags, stat, factor)
	return function(node, out, data)
		if node then
			data[stat] = (data[stat] or 0) + out:Sum("BASE", nil, stat)
		elseif data[stat] ~= 0 then
			out:NewMod(dst, modType, math.floor((data[stat] or 0) * factor), data.modSource, flags)
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
		elseif data.Dex or data.Int then
			out:NewMod("DexIntToMeleeBonus", "BASE", (data.Dex or 0) + (data.Int or 0), data.modSource)
		end
	end,
	["-1 Strength per 1 Strength on Allocated Passives in Radius"] = getPerStat("Str", "BASE", 0, "Str", -1),
	["1% additional Physical Damage Reduction per 10 Strength on Allocated Passives in Radius"] = getPerStat("PhysicalDamageReduction", "BASE", 0, "Str", 1 / 10),
	["2% increased Life Recovery Rate per 10 Strength on Allocated Passives in Radius"] = getPerStat("LifeRecoveryRate", "INC", 0, "Str", 2 / 10),
	["3% increased Life Recovery Rate per 10 Strength on Allocated Passives in Radius"] = getPerStat("LifeRecoveryRate", "INC", 0, "Str", 3 / 10),
	["-1 Intelligence per 1 Intelligence on Allocated Passives in Radius"] = getPerStat("Int", "BASE", 0, "Int", -1),
	["0.4% of Energy Shield Regenerated per Second for every 10 Intelligence on Allocated Passives in Radius"] = getPerStat("EnergyShieldRegenPercent", "BASE", 0, "Int", 0.4 / 10),
	["regenerate 0.4% of energy shield per second for every 10 Intelligence on Allocated Passives in Radius"] = getPerStat("EnergyShieldRegenPercent", "BASE", 0, "Int", 0.4 / 10),
	["2% increased Mana Recovery Rate per 10 Intelligence on Allocated Passives in Radius"] = getPerStat("ManaRecoveryRate", "INC", 0, "Int", 2 / 10),
	["3% increased Mana Recovery Rate per 10 Intelligence on Allocated Passives in Radius"] = getPerStat("ManaRecoveryRate", "INC", 0, "Int", 3 / 10),
	["-1 Dexterity per 1 Dexterity on Allocated Passives in Radius"] = getPerStat("Dex", "BASE", 0, "Dex", -1),
	["2% increased Movement Speed per 10 Dexterity on Allocated Passives in Radius"] = getPerStat("MovementSpeed", "INC", 0, "Dex", 2 / 10),
	["3% increased Movement Speed per 10 Dexterity on Allocated Passives in Radius"] = getPerStat("MovementSpeed", "INC", 0, "Dex", 3 / 10),
}
local jewelSelfUnallocFuncs = {
	["+5% to Critical Strike Multiplier per 10 Strength on Unallocated Passives in Radius"] = getPerStat("CritMultiplier", "BASE", 0, "Str", 5 / 10),
	["+7% to Critical Strike Multiplier per 10 Strength on Unallocated Passives in Radius"] = getPerStat("CritMultiplier", "BASE", 0, "Str", 7 / 10),
	["2% reduced Life Recovery Rate per 10 Strength on Unallocated Passives in Radius"] = getPerStat("LifeRecoveryRate", "INC", 0, "Str", -2 / 10),
	["+15 to maximum Mana per 10 Dexterity on Unallocated Passives in Radius"] = getPerStat("Mana", "BASE", 0, "Dex", 15 / 10),
	["+100 to Accuracy Rating per 10 Intelligence on Unallocated Passives in Radius"] = getPerStat("Accuracy", "BASE", 0, "Int", 100 / 10),
	["+125 to Accuracy Rating per 10 Intelligence on Unallocated Passives in Radius"] = getPerStat("Accuracy", "BASE", 0, "Int", 125 / 10),
	["2% reduced Mana Recovery Rate per 10 Intelligence on Unallocated Passives in Radius"] = getPerStat("ManaRecoveryRate", "INC", 0, "Int", -2 / 10),
	["+3% to Damage over Time Multiplier per 10 Intelligence on Unallocated Passives in Radius"] = getPerStat("DotMultiplier", "BASE", 0, "Int", 3 / 10),
	["2% reduced Movement Speed per 10 Dexterity on Unallocated Passives in Radius"] = getPerStat("MovementSpeed", "INC", 0, "Dex", -2 / 10),
	["+125 to Accuracy Rating per 10 Dexterity on Unallocated Passives in Radius"] = getPerStat("Accuracy", "BASE", 0, "Dex", 125 / 10),
	["Grants all bonuses of Unallocated Small Passive Skills in Radius"] = function(node, out, data)
		if node then
			if node.type == "Normal" then
				data.modList = data.modList or new("ModList")

				-- Filter out "Condition:ConnectedTo" mods as these nodes are not technically allocated by this jewel func
				for _, mod in ipairs(out) do
					if not mod.name:match("^Condition:ConnectedTo") then
						data.modList:AddMod(mod)
					end
				end
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
	["With at least 40 Dexterity in Radius, Frost Blades Melee Damage Penetrates 15% Cold Resistance"] = getThreshold("Dex", "ColdPenetration", "BASE", 15, ModFlag.Melee, { type = "SkillName", skillName = "Frost Blades", includeTransfigured = true }),
	["With at least 40 Dexterity in Radius, Melee Damage dealt by Frost Blades Penetrates 15% Cold Resistance"] = getThreshold("Dex", "ColdPenetration", "BASE", 15, ModFlag.Melee, { type = "SkillName", skillName = "Frost Blades", includeTransfigured = true }),
	["With at least 40 Dexterity in Radius, Frost Blades has 25% increased Projectile Speed"] = getThreshold("Dex", "ProjectileSpeed", "INC", 25, { type = "SkillName", skillName = "Frost Blades", includeTransfigured = true }),
	["With at least 40 Dexterity in Radius, Ice Shot has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Ice Shot" }),
	["Ice Shot Pierces 5 additional Targets with 40 Dexterity in Radius"] = getThreshold("Dex", "PierceCount", "BASE", 5, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Dexterity in Radius, Ice Shot Pierces 3 additional Targets"] = getThreshold("Dex", "PierceCount", "BASE", 3, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Dexterity in Radius, Ice Shot Pierces 5 additional Targets"] = getThreshold("Dex", "PierceCount", "BASE", 5, { type = "SkillName", skillName = "Ice Shot" }),
	["With at least 40 Intelligence in Radius, Frostbolt fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Frostbolt" }),
	["With at least 40 Intelligence in Radius, Rolling Magma fires an additional Projectile"] = getThreshold("Int", "ProjectileCount", "BASE", 1, { type = "SkillName", skillName = "Rolling Magma" }),
	["With at least 40 Intelligence in Radius, Rolling Magma has 10% increased Area of Effect per Chain"] = getThreshold("Int", "AreaOfEffect", "INC", 10, { type = "SkillName", skillName = "Rolling Magma" }, { type = "PerStat", stat = "Chain" }),
	["With at least 40 Intelligence in Radius, Rolling Magma deals 40% more damage per chain"] = getThreshold("Int", "Damage", "MORE", 40, { type = "SkillName", skillName = "Rolling Magma" }, { type = "PerStat", stat = "Chain" }),
	["With at least 40 Intelligence in Radius, Rolling Magma deals 50% less damage"] = getThreshold("Int", "Damage", "MORE", -50, { type = "SkillName", skillName = "Rolling Magma" }),
	["With at least 40 Dexterity in Radius, Shrapnel Shot has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Shrapnel Shot" }),
	["With at least 40 Dexterity in Radius, Shrapnel Shot's cone has a 50% chance to deal Double Damage"] = getThreshold("Dex", "DoubleDamageChance", "BASE", 50, { type = "SkillName", skillName = "Shrapnel Shot" }, { type = "SkillPart", skillPart = 2 }),
	["With at least 40 Dexterity in Radius, Galvanic Arrow deals 50% increased Area Damage"] = getThreshold("Dex", "Damage", "INC", 50, { type = "SkillName", skillName = "Galvanic Arrow", includeTransfigured = true }, { type = "SkillPart", skillPart = 2 }),
	["With at least 40 Dexterity in Radius, Galvanic Arrow has 25% increased Area of Effect"] = getThreshold("Dex", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Galvanic Arrow", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Freezing Pulse fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Freezing Pulse" }),
	["With at least 40 Intelligence in Radius, 25% increased Freezing Pulse Damage if you've Shattered an Enemy Recently"] = getThreshold("Int", "Damage", "INC", 25, { type = "SkillName", skillName = "Freezing Pulse" }, { type = "Condition", var = "ShatteredEnemyRecently" }),
	["With at least 40 Dexterity in Radius, Ethereal Knives fires 10 additional Projectiles"] = getThreshold("Dex", "ProjectileCount", "BASE", 10, { type = "SkillName", skillName = "Ethereal Knives", includeTransfigured = true }),
	["With at least 40 Dexterity in Radius, Ethereal Knives fires 5 additional Projectiles"] = getThreshold("Dex", "ProjectileCount", "BASE", 5, { type = "SkillName", skillName = "Ethereal Knives", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Molten Strike fires 2 additional Projectiles"] = getThreshold("Str", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Molten Strike", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Molten Strike has 25% increased Area of Effect"] = getThreshold("Str", "AreaOfEffect", "INC", 25, { type = "SkillName", skillName = "Molten Strike", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Molten Strike Projectiles Chain +1 time"] = getThreshold("Str", "ChainCountMax", "BASE", 1, { type = "SkillName", skillName = "Molten Strike", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Molten Strike fires 50% less Projectiles"] = getThreshold("Str", "ProjectileCount", "MORE", -50, { type = "SkillName", skillName = "Molten Strike", includeTransfigured = true }),
	["With at least 40 Strength in Radius, 25% of Glacial Hammer Physical Damage converted to Cold Damage"] = getThreshold("Str", "SkillPhysicalDamageConvertToCold", "BASE", 25, { type = "SkillName", skillName = "Glacial Hammer", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Heavy Strike has a 20% chance to deal Double Damage"] = getThreshold("Str", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Heavy Strike" }),
	["With at least 40 Strength in Radius, Heavy Strike has a 20% chance to deal Double Damage."] = getThreshold("Str", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Heavy Strike" }),
	["With at least 40 Strength in Radius, Cleave has +1 to Radius per Nearby Enemy, up to +10"] = getThreshold("Str", "AreaOfEffect", "BASE", 1, { type = "Multiplier", var = "NearbyEnemies", limit = 10 }, { type = "SkillName", skillName = "Cleave", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Cleave has +0.1 metres to Radius per Nearby Enemy, up to a maximum of +1 metre"] = getThreshold("Str", "AreaOfEffect", "BASE", 1, { type = "Multiplier", var = "NearbyEnemies", limit = 10 }, { type = "SkillName", skillName = "Cleave", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Cleave grants Fortify on Hit"] = getThreshold("Str", "ExtraSkillMod", "LIST", { mod = flag("Condition:Fortified") }, { type = "SkillName", skillName = "Cleave", includeTransfigured = true }),
	["With at least 40 Strength in Radius, Hits with Cleave Fortify"] = getThreshold("Str", "ExtraSkillMod", "LIST", { mod = flag("Condition:Fortified") }, { type = "SkillName", skillName = "Cleave", includeTransfigured = true }),
	["With at least 40 Dexterity in Radius, Dual Strike has a 20% chance to deal Double Damage with the Main-Hand Weapon"] = getThreshold("Dex", "DoubleDamageChance", "BASE", 20, { type = "SkillName", skillName = "Dual Strike", includeTransfigured = true }, { type = "Condition", var = "MainHandAttack" }),
	["With at least 40 Dexterity in Radius, Dual Strike has (%d+)%% increased Attack Speed while wielding a Claw"] = function(num) return getThreshold("Dex", "Speed", "INC", num, { type = "SkillName", skillName = "Dual Strike", includeTransfigured = true }, { type = "Condition", var = "UsingClaw" }) end,
	["With at least 40 Dexterity in Radius, Dual Strike has %+(%d+)%% to Critical Strike Multiplier while wielding a Dagger"] = function(num) return getThreshold("Dex", "CritMultiplier", "BASE", num, { type = "SkillName", skillName = "Dual Strike", includeTransfigured = true }, { type = "Condition", var = "UsingDagger" }) end,
	["With at least 40 Dexterity in Radius, Dual Strike has (%d+)%% increased Accuracy Rating while wielding a Sword"] = function(num) return getThreshold("Dex", "Accuracy", "INC", num, { type = "SkillName", skillName = "Dual Strike", includeTransfigured = true }, { type = "Condition", var = "UsingSword" }) end,
	["With at least 40 Dexterity in Radius, Dual Strike Hits Intimidate Enemies for 4 seconds while wielding an Axe"] = getThreshold("Dex", "EnemyModifier", "LIST", { mod = flag("Condition:Intimidated")}, { type = "Condition", var = "UsingAxe" }),
	["With at least 40 Intelligence in Radius, Raised Zombies' Slam Attack has 100% increased Cooldown Recovery Speed"] = getThreshold("Int", "MinionModifier", "LIST", { mod = mod("CooldownRecovery", "INC", 100, { type = "SkillId", skillId = "ZombieSlam" }) }),
	["With at least 40 Intelligence in Radius, Raised Zombies' Slam Attack deals 30% increased Damage"] = getThreshold("Int", "MinionModifier", "LIST", { mod = mod("Damage", "INC", 30, { type = "SkillId", skillId = "ZombieSlam" }) }),
	["With at least 40 Dexterity in Radius, Viper Strike deals 2% increased Attack Damage for each Poison on the Enemy"] = getThreshold("Dex", "Damage", "INC", 2, ModFlag.Attack, { type = "SkillName", skillName = "Viper Strike", includeTransfigured = true }, { type = "Multiplier", actor = "enemy", var = "PoisonStack" }),
	["With at least 40 Dexterity in Radius, Viper Strike deals 2% increased Damage with Hits and Poison for each Poison on the Enemy"] = getThreshold("Dex", "Damage", "INC", 2, 0, bor(KeywordFlag.Hit, KeywordFlag.Poison), { type = "SkillName", skillName = "Viper Strike", includeTransfigured = true }, { type = "Multiplier", actor = "enemy", var = "PoisonStack" }),
	["With at least 40 Intelligence in Radius, Spark fires 2 additional Projectiles"] = getThreshold("Int", "ProjectileCount", "BASE", 2, { type = "SkillName", skillName = "Spark", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Blight has 50% increased Hinder Duration"] = getThreshold("Int", "SecondaryDuration", "INC", 50, { type = "SkillName", skillName = "Blight", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Enemies Hindered by Blight take 25% increased Chaos Damage"] = getThreshold("Int", "ExtraSkillMod", "LIST", { mod = mod("ChaosDamageTaken", "INC", 25, { type = "GlobalEffect", effectType = "Debuff", effectName = "Hinder" }) }, { type = "SkillName", skillName = "Blight", includeTransfigured = true }, { type = "ActorCondition", actor = "enemy", var = "Hindered" }),
	["With 40 Intelligence in Radius, 20% of Glacial Cascade Physical Damage Converted to Cold Damage"] = getThreshold("Int", "SkillPhysicalDamageConvertToCold", "BASE", 20, { type = "SkillName", skillName = "Glacial Cascade", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, 20% of Glacial Cascade Physical Damage Converted to Cold Damage"] = getThreshold("Int", "SkillPhysicalDamageConvertToCold", "BASE", 20, { type = "SkillName", skillName = "Glacial Cascade", includeTransfigured = true }),
	["With 40 total Intelligence and Dexterity in Radius, Elemental Hit and Wild Strike deal 50% less Fire Damage"] = getThreshold({ "Int","Dex" }, "FireDamage", "MORE", -50, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" }, includeTransfigured = true }),
	["With 40 total Strength and Intelligence in Radius, Elemental Hit and Wild Strike deal 50% less Cold Damage"] = getThreshold({ "Str","Int" }, "ColdDamage", "MORE", -50, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" }, includeTransfigured = true }),
	["With 40 total Dexterity and Strength in Radius, Elemental Hit and Wild Strike deal 50% less Lightning Damage"] = getThreshold({ "Dex","Str" }, "LightningDamage", "MORE", -50, { type = "SkillName", skillNameList = { "Elemental Hit", "Wild Strike" }, includeTransfigured = true }),
	["With 40 total Intelligence and Dexterity in Radius, Prismatic Skills deal 50% less Fire Damage"] = getThreshold({ "Int","Dex" }, "FireDamage", "MORE", -50, { type = "SkillType", skillType = SkillType.RandomElement }),
	["With 40 total Strength and Intelligence in Radius, Prismatic Skills deal 50% less Cold Damage"] = getThreshold({ "Str","Int" }, "ColdDamage", "MORE", -50, { type = "SkillType", skillType = SkillType.RandomElement }),
	["With 40 total Dexterity and Strength in Radius, Prismatic Skills deal 50% less Lightning Damage"] = getThreshold({ "Dex","Str" }, "LightningDamage", "MORE", -50, { type = "SkillType", skillType = SkillType.RandomElement }),
	["With 40 total Dexterity and Strength in Radius, Spectral Shield Throw Chains +4 times"] = getThreshold({ "Dex","Str" }, "ChainCountMax", "BASE", 4, { type = "SkillName", skillName = "Spectral Shield Throw", includeTransfigured = true }),
	["With 40 total Dexterity and Strength in Radius, Spectral Shield Throw fires 75% less Shard Projectiles"] = getThreshold({ "Dex","Str" }, "ProjectileCount", "MORE", -75, { type = "SkillName", skillName = "Spectral Shield Throw", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Blight inflicts Withered for 2 seconds"] = getThreshold("Int", "ExtraSkillMod", "LIST", { mod = mod("Condition:CanWither", "FLAG", true) }, { type = "SkillName", skillName = "Blight", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Blight has 30% reduced Cast Speed"] = getThreshold("Int", "Speed", "INC", -30, { type = "SkillName", skillName = "Blight", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Fireball cannot ignite"] = getThreshold("Int", "ExtraSkillMod", "LIST", { mod = flag("CannotIgnite") }, { type = "SkillName", skillName = "Fireball" }),
	["With at least 40 Intelligence in Radius, Fireball has %+(%d+)%% chance to inflict scorch"] = function(num) return getThreshold("Int", "EnemyScorchChance", "BASE", num, { type = "SkillName", skillName = "Fireball" }) end,
	["With at least 40 Intelligence in Radius, Discharge has 60% less Area of Effect"] = getThreshold("Int", "AreaOfEffect", "MORE", -60, {type = "SkillName", skillName = "Discharge", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Discharge Cooldown is 250 ms"] = getThreshold("Int", "CooldownRecovery", "OVERRIDE", 0.25, { type = "SkillName", skillName = "Discharge", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, Discharge deals 60% less Damage"] = getThreshold("Int", "Damage", "MORE", -60, {type = "SkillName", skillName = "Discharge", includeTransfigured = true }),
	["With at least 40 Intelligence in Radius, (%d+)%% of Damage taken Recouped as Mana if you've Warcried Recently"] = function(num) return getThreshold("Int", "ManaRecoup", "BASE", num, { type = "Condition", var = "UsedWarcryRecently" }) end,
	["With at least 40 Intelligence in Radius, Fireball Projectiles gain Radius as they travel farther, up to %+(%d+) Radius"] = function(num) return getThreshold("Int", "AreaOfEffect", "BASE", num, { type = "DistanceRamp", ramp = {{0,0},{50,1}} }) end,
	["With at least 40 Intelligence in Radius, Projectiles gain radius as they travel farther, up to a maximum of %+([%d%.]+) metres? to radius"] = function(num) return getThreshold("Int", "AreaOfEffect", "BASE", num * 10, { type = "DistanceRamp", ramp = {{0,0},{50,1}} }) end,
	-- [""] = getThreshold("", "", "", , { type = "SkillName", skillName = "" }),
}

-- Unified list of jewel functions
local jewelFuncList = { }
-- Jewels that modify nodes
for k, v in pairs(jewelOtherFuncs) do
	jewelFuncList[k:lower()] = { func = function(cap1, cap2, cap3, cap4, cap5)
		-- Need to not modify any nodes already modified by timeless jewels
		-- Some functions return a function instead of simply adding mods, so if
		-- we don't see a node right away, run the outer function first
		if cap1 and type(cap1) == "table" and cap1.conqueredBy then
			return
		end
		local innerFuncOrNil = v(cap1, cap2, cap3, cap4, cap5)
		-- In all (current) cases, there is only one nested layer, so no need for recursion
		return function(node, out, other)
			if node and type(node) == "table" and node.conqueredBy then
				return
			end
			return innerFuncOrNil(node, out, other)
		end
	end, type = "Other" }
end
for k, v in pairs(jewelSelfFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "Self" }
end
for k, v in pairs(jewelSelfUnallocFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "SelfUnalloc" }
end
-- Threshold Jewels
for k, v in pairs(jewelThresholdFuncs) do
	jewelFuncList[k:lower()] = { func = v, type = "Threshold" }
end

-- Generate list of cluster jewel skills
local clusterJewelSkills = {}
for baseName, jewel in pairs(data.clusterJewels.jewels) do
	for skillId, skill in pairs(jewel.skills) do
		clusterJewelSkills[table.concat(skill.enchant, " "):lower()] = { mod("JewelData", "LIST", { key = "clusterJewelSkill", value = skillId }) }
	end
end
for notable in pairs(data.clusterJewels.notableSortOrder) do
	clusterJewelSkills["1 added passive skill is "..notable:lower()] = { mod("ClusterJewelNotable", "LIST", notable) }
end
for _, keystone in ipairs(data.clusterJewels.keystones) do
	clusterJewelSkills["adds "..keystone:lower()] = { mod("JewelData", "LIST", { key = "clusterJewelKeystone", value = keystone }) }
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
	for pattern, patternVal in pairs(jewelFuncList) do
		local _, _, cap1, cap2, cap3, cap4, cap5 = lineLower:find(pattern, 1)
		if cap1 then
			return {mod("JewelFunc", "LIST", {func = patternVal.func(cap1, cap2, cap3, cap4, cap5), type = patternVal.type }) }
		end
	end
	local jewelFunc = jewelFuncList[lineLower]
	if jewelFunc then
		return { mod("JewelFunc", "LIST", jewelFunc) }
	end
	local clusterJewelSkill = clusterJewelSkills[lineLower]
	if clusterJewelSkill then
		return clusterJewelSkill
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

	-- Check for add-to-cluster-jewel special
	local addToCluster = line:match("^Added Small Passive Skills also grant: (.+)$")
	if addToCluster then
		return { mod("AddToClusterJewelNode", "LIST", addToCluster) }
	end

	line = line .. " "

	-- Check for a flag/tag specification at the start of the line
	local preFlag, preFlagCap
	preFlag, line, preFlagCap = scan(line, preFlagList)
	if type(preFlag) == "function" then
		preFlag = preFlag(unpack(preFlagCap))
	end

	-- Check for skill name at the start of the line
	local skillTag
	skillTag, line = scan(line, preSkillNameList)

	-- Scan for modifier form
	local modForm, formCap
	modForm, line, formCap = scan(line, formList)
	if not modForm then
		return nil, line
	end

	-- Check for tags (per-charge, conditionals)
	local modTag, modTag2, tagCap
	modTag, line, tagCap = scan(line, modTagList)
	if type(modTag) == "function" then
		if tagCap[1]:match("%d+") then
			modTag = modTag(tonumber(tagCap[1]), unpack(tagCap))
		else
			modTag = modTag(tagCap[1], unpack(tagCap))
		end
	end
	if modTag then
		modTag2, line, tagCap = scan(line, modTagList)
		if type(modTag2) == "function" then
			if tagCap[1]:match("%d+") then
				modTag2 = modTag2(tonumber(tagCap[1]), unpack(tagCap))
			else
				modTag2 = modTag2(tagCap[1], unpack(tagCap))
			end
		end
	end

	-- Scan for modifier name and skill name
	local modName
	if order == 2 and not skillTag then
		skillTag, line = scan(line, skillNameList)
	end
	if modForm == "PEN" then
		modName, line = scan(line, penTypes, true)
		if not modName then
			return { }, line
		end
		local _
		_, line = scan(line, modNameList, true)
	elseif modForm == "BASECOST" then
		modName, line = scan(line, baseCostTypes, true)
		if not modName then
			return { }, line
		end
		local _
		_, line = scan(line, modNameList, true)
	elseif modForm == "TOTALCOST" then
		modName, line = scan(line, costTypes, true)
		if not modName then
			return { }, line
		end
		local _
		_, line = scan(line, modNameList, true)
	elseif modForm == "FLAG" then
		formCap[1], line = scan(line, flagTypes, false)
		if not formCap[1] then
			return nil, line
		end
		modName, line = scan(line, modNameList, true)
	else
		modName, line = scan(line, modNameList, true)
	end
	if order == 1 and not skillTag then
		skillTag, line = scan(line, skillNameList)
	end

	-- Scan for flags
	local modFlag
	modFlag, line = scan(line, modFlagList, true)

	-- Find modifier value and type according to form
	local modValue = tonumber(formCap[1]) or formCap[1]
	local modType = "BASE"
	local modSuffix
	local modExtraTags
	if modForm == "INC" then
		modType = "INC"
	elseif modForm == "RED" then
		modValue = -modValue
		modType = "INC"
	elseif modForm == "MORE" then
		modType = "MORE"
	elseif modForm == "LESS" then
		modValue = -modValue
		modType = "MORE"
	elseif modForm == "BASE" then
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "GAIN" then
		modType = "BASE"
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "LOSE" then
		modValue = -modValue
		modType = "BASE"
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "GRANTS" then -- local
		modType = "BASE"
		modFlag = modFlag
		modExtraTags = { tag = { type = "Condition", var = "{Hand}Attack" } }
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "REMOVES" then -- local
		modValue = -modValue
		modType = "BASE"
		modFlag = modFlag
		modExtraTags = { tag = { type = "Condition", var = "{Hand}Attack" } }
		modSuffix, line = scan(line, suffixTypes, true)
	elseif modForm == "CHANCE" then
	elseif modForm == "REGENPERCENT" then
		modName = regenTypes[formCap[2]]
		modSuffix = "Percent"
	elseif modForm == "REGENFLAT" then
		modName = regenTypes[formCap[2]]
	elseif modForm == "DEGENPERCENT" then
		modValue = modValue
		modName = degenTypes[formCap[2]]
		modSuffix = "Percent"
	elseif modForm == "DEGENFLAT" then
		modValue = modValue
		modName = degenTypes[formCap[2]]
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
	elseif modForm == "FLAG" then
		modName = type(modValue) == "table" and modValue.name or modValue
		modType = type(modValue) == "table" and modValue.type or "FLAG"
		modValue = type(modValue) == "table" and modValue.value or true
	elseif modForm == "OVERRIDE" then
		modType = "OVERRIDE"
	end
	if not modName then
		return { }, line
	end

	-- Combine flags and tags
	local flags = 0
	local keywordFlags = 0
	local tagList = { }
	local misc = { }
	for _, data in pairs({ modName, preFlag, modFlag, modTag, modTag2, skillTag, modExtraTags }) do
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
		elseif misc.addToMinion then
			-- Minion modifiers
			for i, effectMod in ipairs(modList) do
				local tagList = { }
				if misc.playerTag then t_insert(tagList, misc.playerTag) end
				if misc.addToMinionTag then t_insert(tagList, misc.addToMinionTag) end
				if misc.playerTagList then
					for _, tag in ipairs(misc.playerTagList) do
						t_insert(tagList, tag)
					end
				end
				modList[i] = mod("MinionModifier", "LIST", { mod = effectMod }, unpack(tagList))
			end
		elseif misc.addToSkill then
			-- Skill enchants or socketed gem modifiers that add additional effects
			for i, effectMod in ipairs(modList) do
				modList[i] = mod("ExtraSkillMod", "LIST", { mod = effectMod }, misc.addToSkill)
			end
		elseif misc.applyToEnemy then
			for i, effectMod in ipairs(modList) do
				local tagList = { }
				if misc.playerTag then t_insert(tagList, misc.playerTag) end
				if misc.playerTagList then
					for _, tag in ipairs(misc.playerTagList) do
						t_insert(tagList, tag)
					end
				end
				local newMod = effectMod
				if effectMod[1] and type(effectMod) == "table" and misc.actorEnemy then
					newMod = copyTable(effectMod)
					newMod[1]["actor"] = "enemy"
				end
				modList[i] = mod("EnemyModifier", "LIST", { mod = newMod }, unpack(tagList))
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
