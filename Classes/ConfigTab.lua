-- Path of Building
--
-- Module: Config Tab
-- Configuration tab for the current build.
--
local launch, main = ...

local t_insert = table.insert
local m_max = math.max

local varList = {
	{ section = "General" },
	{ var = "enemyLevel", type = "number", label = "Enemy Level:", tooltip = "This overrides the default enemy level used to estimate your hit and evade chances.\nThe default level is your character level, capped at 84, which is the same value\nused in-game to calculate the stats on the character sheet." },
	{ var = "conditionLowLife", type = "check", label = "Are you always on Low Life?", ifCond = "LowLife", tooltip = "You will automatically be considered to be on Low Life if you have at least 65% life reserved,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "LowLife" }, "Config")
	end },
	{ var = "conditionFullLife", type = "check", label = "Are you always on Full Life?", ifCond = "FullLife", tooltip = "You will automatically be considered to be on Full Life if you have Chaos Innoculation,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "FullLife" }, "Config")
	end },
	{ var = "conditionFullEnergyShield", type = "check", label = "Are you always on Full Energy Shield?", ifCond = "FullES", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "FullEnergyShield" }, "Config")
	end },
	{ var = "igniteMode", type = "list", label = "Ignite calculation mode:", tooltip = "Controls how the base damage for ignite is calculated:\nAverage Damage: Ignite is based on the average damage dealt, factoring in crits and non-crits.\nCrit Damage: Ignite is based on crit damage only.", list = {{val="AVERAGE",label="Average Damage"},{val="CRIT",label="Crit Damage"}} },
	{ section = "When In Combat" },
	{ var = "usePowerCharges", type = "check", label = "Do you use Power Charges?" },
	{ var = "useFrenzyCharges", type = "check", label = "Do you use Frenzy Charges?" },
	{ var = "useEnduranceCharges", type = "check", label = "Do you use Endurance Charges?" },
	{ var = "buffOnslaught", type = "check", label = "Do you have Onslaught?", tooltip = "In addition to allowing any 'while you have Onslaught' modifiers to apply,\nthis will enable the Onslaught buff itself. (20% increased Attack/Cast/Movement Speed)", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Onslaught" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffUnholyMight", type = "check", label = "Do you have Unholy Might?", tooltip = "This will enable the Unholy Might buff. (Gain 30% of Physical Damage as Extra Chaos Damage)", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UnholyMight" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPhasing", type = "check", label = "Do you have Phasing?", ifCond = "Phasing", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Phasing" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffFortify", type = "check", label = "Do you have Fortify?", ifCond = "Fortify", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Fortify" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionLeeching", type = "check", label = "Are you Leeching?", ifCond = "Leeching", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Leeching" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsingFlask", type = "check", label = "Do you have a Flask active?", ifCond = "UsingFlask", tooltip = "This is automatically enabled if you have a flask active,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UsingFlask" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHaveTotem", type = "check", label = "Do you have a Totem summoned?", ifCond = "HaveTotem", tooltip = "You will automatically be considered to have a Totem if your main skill is a Totem,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "HaveTotem" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnConsecratedGround", type = "check", label = "Are you on Consecrated Ground?", tooltip = "In addition to allowing any 'while on Consecrated Ground' modifiers to apply,\nthis will apply the 4% life regen modifier granted by Consecrated Ground.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "OnConsecratedGround" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnBurningGround", type = "check", label = "Are you on Burning Ground?", ifCond = "OnBurningGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "OnBurningGround" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnChilledGround", type = "check", label = "Are you on Chilled Ground?", ifCond = "OnChilledGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "OnChilledGround" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionOnShockedGround", type = "check", label = "Are you on Shocked Ground?", ifCond = "OnShockedGround", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "OnShockedGround" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnited", type = "check", label = "Are you Ignited?", ifCond = "Ignited", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Ignited" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozen", type = "check", label = "Are you Frozen?", ifCond = "Frozen", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Frozen" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionShocked", type = "check", label = "Are you Shocked?", ifCond = "Shocked", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "Shocked" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitRecently", type = "check", label = "Have you Hit Recently?", ifCond = "HitRecently", tooltip = "You will automatically be considered to have Hit Recently if your main skill is self-cast,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "HitRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCritRecently", type = "check", label = "Have you Crit Recently?", ifCond = "CritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "CritRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionNonCritRecently", type = "check", label = "Have you dealt a Non-Crit Recently?", ifCond = "NonCritRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "NonCritRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionKilledRecently", type = "check", label = "Have you Killed Recently?", ifCond = "KilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "KilledRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTotemsKilledRecently", type = "check", label = "Have your Totems Killed Recently?", ifCond = "TotemsKilledRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "TotemsKilledRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionFrozenEnemyRecently", type = "check", label = "Have you Frozen an Enemy Recently?", ifCond = "FrozenEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "FrozenEnemyRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionIgnitedEnemyRecently", type = "check", label = "Have you Ignited an Enemy Recently?", ifCond = "IgnitedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "IgnitedEnemyRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenHitRecently", type = "check", label = "Have you been Hit Recently?", ifCond = "BeenHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "BeenHitRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBeenSavageHitRecently", type = "check", label = "Have you been Savage Hit Recently?", ifCond = "BeenSavageHitRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "BeenSavageHitRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByFireDamageRecently", type = "check", label = "Have you been hit by Fire Recently?", ifCond = "HitByFireDamageRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "HitByFireDamageRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByColdDamageRecently", type = "check", label = "Have you been hit by Cold Recently?", ifCond = "HitByColdDamageRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "HitByColdDamageRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionHitByLightningDamageRecently", type = "check", label = "Have you been hit by Light. Recently?", ifCond = "HitByLightningDamageRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "HitByLightningDamageRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedAttackRecently", type = "check", label = "Have you Blocked an Attack Recently?", ifCond = "BlockedAttackRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "BlockedAttackRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedSpellRecently", type = "check", label = "Have you Blocked a Spell Recently?", ifCond = "BlockedSpellRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "BlockedSpellRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "buffPendulum", type = "check", label = "Is Pendulum of Destruction active?", ifNode = 57197, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "PendulumOfDestruction" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionAttackedRecently", type = "check", label = "Have you Attacked Recently?", ifNode = 3154, tooltip = "You will automatically be considered to have Attacked Recently if your main skill is an attack,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "AttackedRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionCastSpellRecently", type = "check", label = "Have you Cast a Spell Recently?", ifNode = 3154, tooltip = "You will automatically be considered to have Cast a Spell Recently if your main skill is a spell,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "CastSpellRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedWarcryRecently", type = "check", label = "Have you used a Warcry Recently?", ifCond = "UsedWarcryRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UsedWarcryRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionConsumedCorpseRecently", type = "check", label = "Consumed a corpse Recently?", ifCond = "ConsumedCorpseRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "ConsumedCorpseRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionTauntedEnemyRecently", type = "check", label = "Taunted an Enemy Recently?", ifCond = "TauntedEnemyRecently", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "TauntedEnemyRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedFireSkillInPast10Sec", type = "check", label = "Used a Fire Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UsedFireSkillInPast10Sec" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedColdSkillInPast10Sec", type = "check", label = "Used a Cold Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UsedColdSkillInPast10Sec" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionUsedLightningSkillInPast10Sec", type = "check", label = "Used a Light. Skill in the past 10s?", ifNode = 61259, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "UsedLightningSkillInPast10Sec" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ var = "conditionBlockedHitFromUniqueEnemyRecently", type = "check", label = "Blocked hit from a Unique Recently?", ifNode = 63490, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "BlockedHitFromUniqueEnemyRecently" }, "Config", { type = "Condition", var = "Combat" })
	end },
	{ section = "For Effective DPS" },
	{ var = "critChanceLucky", type = "check", label = "Is your Crit Chance Lucky?", apply = function(val, modList, enemyModList)
		modList:NewMod("CritChanceLucky", "FLAG", true, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "projectileDistance", type = "number", label = "Projectile travel distance:", ifFlag = "projectile" },
	{ var = "conditionEnemyMoving", type = "check", label = "Is the enemy Moving?", ifFlag = "bleed", apply = function(val, modList, enemyModList)
		modList:NewMod("Damage", "MORE", 500, "Movement", 0, KeywordFlag.Bleed)
	end },
	{ var = "conditionEnemyFullLife", type = "check", label = "Is the enemy on Full Life?", ifEnemyCond = "FullLife", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "FullLife" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyLowLife", type = "check", label = "Is the enemy on Low Life?", ifEnemyCond = "LowLife", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "LowLife" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionAtCloseRange", type = "check", label = "Is the enemy at Close Range?", ifCond = "AtCloseRange", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "AtCloseRange" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyCursed", type = "check", label = "Is the enemy Cursed?", ifEnemyCond = "Cursed", tooltip = "Your enemy will automatically be considered to be Cursed if you have at least one curse enabled,\nbut you can use this option to force it if necessary.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Cursed" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBleeding", type = "check", label = "Is the enemy Bleeding?", ifEnemyCond = "Bleeding", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Bleeding" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyPoisoned", type = "check", label = "Is the enemy Poisoned?", ifEnemyCond = "Poisoned", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Poisoned" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyMaimed", type = "check", label = "Is the enemy Maimed?", ifEnemyCond = "Maimed", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Maimed" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyHindered", type = "check", label = "Is the enemy Hindered?", ifEnemyCond = "Hindered", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Hindered" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyBlinded", type = "check", label = "Is the enemy Blinded?", tooltip = "In addition to allowing 'against Blinded Enemies' modifiers to apply,\nthis will lessen the enemy's chance to hit, and thereby increase your evade chance.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Blinded" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyTaunted", type = "check", label = "Is the enemy Taunted?", ifEnemyCond = "Taunted", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Taunted" }, "Config", { type = "Condition", var = "Effective" })
	end }, 
	{ var = "conditionEnemyBurning", type = "check", label = "Is the enemy Burning?", ifEnemyCond = "Burning", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Burning" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIgnited", type = "check", label = "Is the enemy Ignited?", ifEnemyCond = "Ignited", tooltip = "This also implies that the enemy is Burning.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Ignited" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyChilled", type = "check", label = "Is the enemy Chilled?", ifEnemyCond = "Chilled", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Chilled" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyFrozen", type = "check", label = "Is the enemy Frozen?", ifEnemyCond = "Frozen", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Frozen" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyShocked", type = "check", label = "Is the enemy Shocked?", tooltip = "In addition to allowing any 'against Shocked Enemies' modifiers to apply,\nthis will apply Shock's Damage Taken modifier to the enemy.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "Shocked" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "conditionEnemyIntimidated", type = "check", label = "Is the enemy Intimidated?", tooltip = "This adds the following modifiers:\n10% increased Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("DamageTaken", "INC", 10, "Intimidate")
	end },
	{ var = "conditionEnemyCoveredInAsh", type = "check", label = "Is the enemy covered in Ash?", tooltip = "This adds the following modifiers:\n20% less enemy Movement Speed\n20% increased Fire Damage Taken by enemy", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireDamageTaken", "INC", 20, "Ash")
	end },
	{ var = "conditionEnemyRareOrUnique", type = "check", label = "is the enemy Rare or Unique?", ifCond = "EnemyRareOrUnique", tooltip = "Your enemy will automatically be considered to be Unique if one of the Boss options is selected.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyRareOrUnique" }, "Config", { type = "Condition", var = "Effective" })
	end },
	{ var = "enemyIsBoss", type = "list", label = "Is the enemy a Boss?", tooltip = "Standard Boss adds the following modifiers:\n60% less Effect of your Curses\n+30% to enemy Elemental Resistances\n+15% to enemy Chaos Resistance\n\nShaper/Guardian adds the following modifiers:\n80% less Effect of your Curses\n+40% to enemy Elemental Resistances\n+25% to enemy Chaos Resistance\n50% less Duration of Bleed\n50% less Duration of Poison\n50% less Duration of Ignite", list = {{val="NONE",label="No"},{val=true,label="Standard Boss"},{val="SHAPER",label="Shaper/Guardian"}}, apply = function(val, modList, enemyModList)
		if val == true then
			modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyRareOrUnique" }, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -60, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 30, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 15, "Boss")
		elseif val == "SHAPER" then
			modList:NewMod("Misc", "LIST", { type = "Condition", var = "EnemyRareOrUnique" }, "Config", { type = "Condition", var = "Effective" })
			enemyModList:NewMod("CurseEffectOnSelf", "MORE", -80, "Boss")
			enemyModList:NewMod("ElementalResist", "BASE", 40, "Boss")
			enemyModList:NewMod("ChaosResist", "BASE", 25, "Boss")
			enemyModList:NewMod("SelfBleedDuration", "MORE", -50, "Boss")
			enemyModList:NewMod("SelfPoisonDuration", "MORE", -50, "Boss")
			enemyModList:NewMod("SelfIgniteDuration", "MORE", -50, "Boss")
		end
	end },
	{ var = "enemyPhysicalReduction", type = "number", label = "Enemy Phys. Damage Reduction:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("PhysicalDamageReduction", "INC", val, "Config")
	end },
	{ var = "enemyFireResist", type = "number", label = "Enemy Fire Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("FireResist", "BASE", val, "Config")
	end },
	{ var = "enemyColdResist", type = "number", label = "Enemy Cold Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ColdResist", "BASE", val, "Config")
	end },
	{ var = "enemyLightningResist", type = "number", label = "Enemy Lightning Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("LightningResist", "BASE", val, "Config")
	end },
	{ var = "enemyChaosResist", type = "number", label = "Enemy Chaos Resistance:", apply = function(val, modList, enemyModList)
		enemyModList:NewMod("ChaosResist", "BASE", val, "Config")
	end },
	{ var = "enemyConditionHitByFireDamage", type = "check", label = "Enemy was Hit by Fire Damage?", ifNode = 39085, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "HitByFireDamage" }, "Config")
	end },
	{ var = "enemyConditionHitByColdDamage", type = "check", label = "Enemy was Hit by Cold Damage?", ifNode = 39085, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "HitByColdDamage" }, "Config")
	end },
	{ var = "enemyConditionHitByLightningDamage", type = "check", label = "Enemy was Hit by Light. Damage?", ifNode = 39085, apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "EnemyCondition", var = "HitByLightningDamage" }, "Config")
	end },
	{ var = "EEIgnoreHitDamage", type = "check", label = "Ignore Skill Hit Damage?", ifNode = 39085, tooltip = "This option prevents EE from being reset by the hit damage of your main skill." },
	{ section = "Skill Options" },
	{ label = "Raise Spectre:", ifSkill = "Raise Spectre" },
	{ var = "raiseSpectreSpectreLevel", type = "number", label = "Spectre Level:", ifSkill = "Raise Spectre", tooltip = "Sets the level of the raised spectre.\nThe default level is the level requirement of the Raise Spectre skill.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "SkillData", key = "minionLevel", value = val }, "Config", { type = "SkillName", skillName = "Raise Spectre" })
	end },
	{ var = "raiseSpectreEnableCurses", type = "check", label = "Enable curses:", ifSkill = "Raise Spectre", tooltip = "Enable any curse skills that your spectres have.", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "SkillData", key = "enable", value = true }, "Config", { type = "SkillType", skillType = SkillType.Curse }, { type = "SkillName", skillName = "Raise Spectre", summonSkill = true })
	end },
	{ label = "Summon Lightning Golem:", ifSkill = "Summon Lightning Golem" },
	{ var = "summonLightningGolemEnableWrath", type = "check", label = "Enable Wrath Aura:", ifSkill = "Summon Lightning Golem", apply = function(val, modList, enemyModList)
		modList:NewMod("Misc", "LIST", { type = "SkillData", key = "enable", value = true }, "Config", { type = "SkillId", skillId = "LightningGolemWrath" })
	end },
}

local ConfigTabClass = common.NewClass("ConfigTab", "UndoHandler", "ControlHost", "Control", function(self, build)
	self.UndoHandler()
	self.ControlHost()
	self.Control()

	self.build = build

	self.input = { }

	self.sectionList = { }
	self.varControls = { }

	self:BuildModList()

	local lastSection
	for _, varData in ipairs(varList) do
		if varData.section then
			lastSection = common.New("SectionControl", {"TOPLEFT",self,"TOPLEFT"}, 0, 0, 360, 0, varData.section)
			lastSection.varControlList = { }
			lastSection.height = function(self)
				local height = 20
				for _, varControl in pairs(self.varControlList) do
					if varControl:IsShown() then
						height = height + 20
					end
				end
				return m_max(height, 32)
			end
			t_insert(self.sectionList, lastSection)
			t_insert(self.controls, lastSection)
		else
			local control
			if varData.type == "check" then
				control = common.New("CheckBoxControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 18, nil, function(state)
					self.input[varData.var] = state
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "number" then
				control = common.New("EditControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 70, 18, "", nil, "^%-%d", 4, function(buf)
					self.input[varData.var] = tonumber(buf)
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end) 
			elseif varData.type == "list" then
				control = common.New("DropDownControl", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 118, 16, varData.list, function(sel, selVal)
					self.input[varData.var] = selVal.val
					self:AddUndoState()
					self:BuildModList()
					self.build.buildFlag = true
				end)
			else 
				control = common.New("Control", {"TOPLEFT",lastSection,"TOPLEFT"}, 234, 0, 16, 16)
			end
			if varData.ifNode then
				control.shown = function()
					return self.build.spec.allocNodes[varData.ifNode]
				end
				control.tooltip = function()
					return "This option is specific to '"..self.build.spec.nodes[varData.ifNode].dn.."'."..(varData.tooltip and "\n"..varData.tooltip or "")
				end
			elseif varData.ifCond or varData.ifEnemyCond then
				control.shown = function()
					if varData.ifCond then
						return self.build.calcsTab.mainEnv.conditionsUsed[varData.ifCond]
					else
						return self.build.calcsTab.mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
					end
				end
				control.tooltip = function()
					if launch.devMode and IsKeyDown("ALT") then
						local out = varData.tooltip or ""
						local list
						if varData.ifCond then
							list = self.build.calcsTab.mainEnv.conditionsUsed[varData.ifCond]
						else
							list = self.build.calcsTab.mainEnv.enemyConditionsUsed[varData.ifEnemyCond]
						end
						for _, mod in ipairs(list) do
							out = (#out > 0 and out.."\n" or out) .. modLib.formatMod(mod) .. "|" .. mod.source
						end
						return out
					else
						return varData.tooltip
					end
				end
			elseif varData.ifFlag then
				control.shown = function()
					return self.build.calcsTab.mainEnv.player.mainSkill.skillFlags[varData.ifFlag] -- O_O
				end
				control.tooltip = varData.tooltip
			elseif varData.ifSkill then
				control.shown = function()
					return self.build.calcsTab.mainEnv.skillsUsed[varData.ifSkill]
				end
				control.tooltip = varData.tooltip
			else
				control.tooltip = varData.tooltip
			end
			t_insert(self.controls, common.New("LabelControl", {"RIGHT",control,"LEFT"}, -4, 0, 0, 14, "^7"..varData.label))
			if varData.var then
				self.varControls[varData.var] = control
			end
			t_insert(self.controls, control)
			t_insert(lastSection.varControlList, control)
		end
	end
end)

function ConfigTabClass:Load(xml, fileName)
	for _, node in ipairs(xml) do
		if node.elem == "Input" then
			if not node.attrib.name then
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing name attribute", fileName)
				return true
			end
			if node.attrib.number then
				self.input[node.attrib.name] = tonumber(node.attrib.number)
			elseif node.attrib.string then
				self.input[node.attrib.name] = node.attrib.string
			elseif node.attrib.boolean then
				self.input[node.attrib.name] = node.attrib.boolean == "true"
			else
				launch:ShowErrMsg("^1Error parsing '%s': 'Input' element missing number, string or boolean attribute", fileName)
				return true
			end
		end
	end
	self:BuildModList()
	self:UpdateControls()
	self:ResetUndo()
end

function ConfigTabClass:Save(xml)
	for k, v in pairs(self.input) do
		local child = { elem = "Input", attrib = {name = k} }
		if type(v) == "number" then
			child.attrib.number = tostring(v)
		elseif type(v) == "boolean" then
			child.attrib.boolean = tostring(v)
		else
			child.attrib.string = tostring(v)
		end
		t_insert(xml, child)
	end
	self.modFlag = false
end

function ConfigTabClass:UpdateControls()
	for var, control in pairs(self.varControls) do
		if control._className == "EditControl" then
			control:SetText(tostring(self.input[var] or ""))
		elseif control._className == "CheckBoxControl" then
			control.state = self.input[var]
		elseif control._className == "DropDownControl" then
			control:SelByValue(self.input[var])
		end
	end
end

function ConfigTabClass:Draw(viewPort, inputEvents)
	self.x = viewPort.x
	self.y = viewPort.y
	self.width = viewPort.width
	self.height = viewPort.height

	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "z" and IsKeyDown("CTRL") then
				self:Undo()
				self.build.buildFlag = true
			elseif event.key == "y" and IsKeyDown("CTRL") then
				self:Redo()
				self.build.buildFlag = true
			end
		end
	end

	self:ProcessControlsInput(inputEvents, viewPort)

	local colY = { }
	for _, section in ipairs(self.sectionList) do
		local y = 14
		section.shown = true
		local doShow = false
		for _, varControl in ipairs(section.varControlList) do
			if varControl:IsShown() then
				doShow = true
				local width, height = varControl:GetSize()
				varControl.y = y + (18 - height) / 2
				y = y + 20
			end
		end
		section.shown = doShow
		if doShow then
			local width, height = section:GetSize()
			local col = 1
			while true do
				colY[col] = colY[col] or 18
				if colY[col] + height + 10 <= viewPort.height then
					break
				end
				col = col + 1
			end
			section.x = 10 + (col - 1) * 360
			section.y = colY[col]
			colY[col] = colY[col] + height + 18
		end
	end

	main:DrawBackground(viewPort)

	self:DrawControls(viewPort)
end

function ConfigTabClass:BuildModList()
	local modList = common.New("ModList")
	self.modList = modList
	local enemyModList = common.New("ModList")
	self.enemyModList = enemyModList
	local input = self.input
	for _, varData in ipairs(varList) do
		if varData.apply then
			if varData.type == "check" then
				if input[varData.var] then
					varData.apply(true, modList, enemyModList)
				end
			elseif varData.type == "number" then
				if input[varData.var] and input[varData.var] ~= 0 then
					varData.apply(input[varData.var], modList, enemyModList)
				end
			elseif varData.type == "list" then
				if input[varData.var] then
					varData.apply(input[varData.var], modList, enemyModList)
				end
			end
		end
	end
end

function ConfigTabClass:ImportCalcSettings()
	local input = self.input
	local calcsInput = self.build.calcsTab.input
	local function import(old, new)
		input[new] = calcsInput[old]
		calcsInput[old] = nil
	end
	import("Cond_LowLife", "conditionLowLife")
	import("Cond_FullLife", "conditionFullLife")
	import("buff_power", "usePowerCharges")
	import("buff_frenzy", "useFrenzyCharges")
	import("buff_endurance", "useEnduranceCharges")
	import("CondBuff_Onslaught", "buffOnslaught")
	import("CondBuff_Phasing", "buffPhasing")
	import("CondBuff_Fortify", "buffFortify")
	import("CondBuff_UsingFlask", "conditionUsingFlask")
	import("buff_pendulum", "usePendulum")
	import("CondEff_EnemyCursed", "conditionEnemyCursed")
	import("CondEff_EnemyBleeding", "conditionEnemyBleeding")
	import("CondEff_EnemyPoisoned", "conditionEnemyPoisoned")
	import("CondEff_EnemyBurning", "conditionEnemyBurning")
	import("CondEff_EnemyIgnited", "conditionEnemyIgnited")
	import("CondEff_EnemyChilled", "conditionEnemyChilled")
	import("CondEff_EnemyFrozen", "conditionEnemyFrozen")
	import("CondEff_EnemyShocked", "conditionEnemyShocked")
	import("effective_physicalRed", "enemyPhysicalReduction")
	import("effective_fireResist", "enemyFireResist")
	import("effective_coldResist", "enemyColdResist")
	import("effective_lightningResist", "enemyLightningResist")
	import("effective_chaosResist", "enemyChaosResist")
	import("effective_enemyIsBoss", "enemyIsBoss")
	self:BuildModList()
	self:UpdateControls()
end

function ConfigTabClass:CreateUndoState()
	return copyTable(self.input)
end

function ConfigTabClass:RestoreUndoState(state)
	wipeTable(self.input)
	for k, v in pairs(state) do
		self.input[k] = v
	end
	self:UpdateControls()
	self:BuildModList()
end
