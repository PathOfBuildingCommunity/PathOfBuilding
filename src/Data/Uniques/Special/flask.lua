-- Item data (c) Grinding Gear Games

return {
-- Flask: Life
[[
Blood of the Karui
Sanctified Life Flask
League: Domination, Nemesis
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 50
(5-20)% increased Recovery Speed
{variant:1}No Life Recovery Applies during Flask effect
{variant:2}100% increased Amount Recovered
{variant:3}50% increased Amount Recovered
LocalFlaskLifeOnFlaskDurationEndUniqueFlask3
]],
-- Flask: Mana
[[
Doedre's Elixir
Greater Mana Flask
Variant: Pre 2.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 12
Implicits: 0
{variant:1,2}Removes 20% of your maximum Energy Shield on use
{variant:3}FlaskRemovePercentageOfEnergyShieldUniqueFlask2
{variant:1,2}You take 10% of your maximum Life as Chaos Damage on use
{variant:3}FlaskTakeChaosDamagePercentageOfLifeUniqueFlask2
{variant:1,2}FlaskGainPowerChargeUniqueFlask2
{variant:1,2}FlaskGainFrenzyChargeUniqueFlask2
{variant:1,2}FlaskGainEnduranceChargeUnique__1_
{variant:3}You gain (1-3) Power Charges on use
{variant:3}You gain (1-3) Frenzy Charges on use
{variant:3}You gain (1-3) Endurance Charge on use
{variant:1}(50-100)% increased Charges used
{variant:2}(120-150)% increased Charges used
{variant:3}LocalFlaskChargesUsedUniqueFlask2
]],[[
Lavianga's Spirit
Sanctified Mana Flask
League: Domination, Nemesis
Requires Level 50
FlaskIncreasedRecoveryAmountUniqueFlask4
100% increased Recovery Speed
Your Skills have no Mana Cost during Flask effect
]],[[
Replica Lavianga's Spirit
Sanctified Mana Flask
League: Heist
Requires Level 50
FlaskIncreasedRecoveryAmountUniqueFlask4
50% reduced Recovery rate
LocalFlaskAttackAndCastSpeedWhileHealingUnique__1
(5-15)% increased Cast Speed during Flask effect
FlaskBuffReducedManaCostWhileHealingUnique__1
]],[[
Zerphi's Last Breath
Grand Mana Flask
Variant: Pre 3.2.0
Variant: Current
League: Perandus
Requires Level 18
FlaskChargesUsedUnique__3
{variant:1}Grants Last Breath when you Use a Skill during Flask Effect, for 800% of Mana Cost
{variant:2}FlaskLifeGainOnSkillUseUnique__1
]],
-- Flask: Hybrid
[[
Divination Distillate
Large Hybrid Flask
Variant: Pre 1.1.0
Variant: Pre 2.2.0
Variant: Pre 3.5.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 30
{variant:1,2,3,4}(40-60)% increased Rarity of Items found during Flask effect
{variant:5}FlaskItemRarityUniqueFlask1
{variant:1}(20-25)% increased Quantity of Items found during Flask effect
{variant:2,3,4}(12-18)% increased Quantity of Items found during Flask effect
{variant:5}FlaskItemQuantityUniqueFlask1
FlaskLightRadiusUniqueFlask1
{variant:1,2}+6% to all maximum Elemental Resistances during Flask effect
{variant:3}FlaskMaximumElementalResistancesUniqueFlask1
{variant:4,5}+50% to all Elemental Resistances during Flask Effect
]],[[
The Writhing Jar
Hallowed Hybrid Flask
Requires Level 60
(75-65)% reduced Amount Recovered
Instant Recovery
SummonsWormsOnUse
(20-10)% reduced Charges used
]],
-- Flask: Utility
[[
Atziri's Promise
Amethyst Flask
Source: Drops from unique{Atziri, Queen of the Vaal} in normal{The Apex of Sacrifice}
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 68
ChaosDamageLifeLeechPermyriadWhileUsingFlaskUniqueFlask5New
{variant:1}Gain (22-25)% of Physical Damage as Extra Chaos Damage during effect
{variant:2}Gain (15-20)% of Physical Damage as Extra Chaos Damage during effect
{variant:3}AddedChaosDamageAsPercentOfPhysicalWhileUsingFlaskUniqueFlask5
{variant:1}Gain (13-15)% of Elemental Damage as Extra Chaos Damage during effect
{variant:2}Gain (10-15)% of Elemental Damage as Extra Chaos Damage during effect
{variant:3}AddedChaosDamageAsPercentOfElementalWhileUsingFlaskUniqueFlask5
]],[[
Bottled Faith
Sulphur Flask
League: Synthesis
Source: Drops from unique{Synthete Nightmare} in normal{The Cortex}
Variant: Pre 3.15.0
Variant: Current
Requires Level 35
UtilityFlaskConsecrate
{variant:1}FlaskEffectDurationUnique__3
{variant:2}FlaskEffectDurationUnique__7
FlaskConsecratedGroundAreaOfEffectUnique__1_
{variant:1}+(1.0-2.0)% to Critical Strike Chance against Enemies on Consecrated Ground during Effect
{variant:2}(100-150)% increased Critical Strike Chance against Enemies on Consecrated Ground during Effect
FlaskConsecratedGroundDamageTakenUnique__1
]],[[
Coralito's Signature
Diamond Flask
Requires Level 27
Variant: Pre 3.15.0
Variant: Current
{variant:1}FlaskTakeChaosDamagePerSecondUnique__1
{variant:2}Take (200-300) Chaos Damage per Second during Flask effect
FlaskChanceToPoisonUnique__1
FlaskHitsHaveNoCritMultiUnique__1
{variant:1}FlaskPoisonDurationUnique__1
{variant:1}FlaskGrantsPerfectAgonyUnique__1_
{variant:2}Poisons you inflict with Critical Strikes have +(20-30)% to Damage over Time Multiplier
]],[[
Coruscating Elixir
Ruby Flask
Variant: Pre 2.6.0
Variant: Current
Requires Level 18
Implicits: 0
{variant:2}FlaskEffectDurationUnique__4
ChaosDamageDoesNotBypassESDuringFlaskEffectUnique__1
RemoveLifeAndAddThatMuchEnergyShieldOnFlaskUseUnique__1
Removed life is regenerated as Energy Shield over 2 seconds
]],[[
Cinderswallow Urn
Silver Flask
League: Betrayal
Source: Drops from unique{Catarina, Master of Undeath}
Has Alt Variant: true
Variant: Crit Chance
Variant: Damage Taken is Leeched as Life
Variant: Item Rarity
Variant: Reduced Mana Cost
Variant: Movement Speed/Stun Avoidance
Variant: Life Regen
Variant: Pre 3.15.0
Variant: Current
Requires Level 22
Implicits: 0
{variant:7}GainChargeOnConsumingIgnitedCorpseUnique__1__
{variant:8}GainChargeOnConsumingIgnitedCorpseUnique__2
{variant:7}Enemies Ignited by you during Flask Effect take 10% increased Damage
{variant:8}EnemiesIgnitedTakeIncreasedDamageUnique__1
{variant:7,8}RecoverMaximumLifeOnKillFlaskEffectUnique__1
{variant:7,8}RecoverMaximumManaOnKillFlaskEffectUnique__1
{variant:7,8}RecoverMaximumEnergyShieldOnKillFlaskEffectUnique__1
{variant:8}FlaskExtraChargesUnique__3
{variant:8}LocalFlaskChargesUsedUniqueFlask2
{variant:1}{crafted}(60-80)% increased Critical Strike Chance during Flask Effect
{variant:2}{crafted}15% of Damage Taken from Hits is Leeched as Life during Flask Effect
{variant:3}FlaskItemRarityUniqueFlask1
{variant:4}{crafted}(25-20)% reduced Mana Cost of Skills during Flask Effect
{variant:5}{crafted}(8-12)% increased Movement Speed during Flask effect
{variant:5}{crafted}50% Chance to avoid being Stunned during Flask Effect
{variant:6}{crafted}3% of Life Regenerated per second during Flask Effect
]],[[
Dying Sun
Ruby Flask
Source: Drops from unique{The Shaper}
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 68
{variant:2}(-10-10)% increased Charges used
{variant:3}FlaskChargesUsedUnique__5
{variant:3}FlaskEffectDurationUnique__6
{variant:1}30% increased Area of Effect during Flask Effect
{variant:2}(15-25)% increased Area of Effect during Flask Effect
{variant:3}FlaskIncreasedAreaOfEffectDuringEffectUnique__1_
2 additional Projectiles during Flask Effect
]],[[
Forbidden Taste
Quartz Flask
Variant: Pre 1.2.3
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 27
{variant:1,2}FlaskChargesUsedUnique__3
{variant:1}Recover 50% of your maximum Life on use
{variant:2}Recover 75% of your maximum Life on use
{variant:3,4}Recover (75-100)% of your maximum Life on use
{variant:1}15% of maximum Life taken as Chaos Damage per second
{variant:2,3}8% of Maximum Life taken as Chaos Damage per second
{variant:4}LocalFlaskChaosDamageOfLifeTakenPerMinuteWhileHealingUniqueFlask6
]],[[
Kiara's Determination
Silver Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 22
Implicits: 0
FlaskImmuneToStunFreezeCursesUnique__1
{variant:1}50% reduced Duration
{variant:2}60% reduced Duration
{variant:3}FlaskEffectDurationUnique__2
]],[[
Lion's Roar
Granite Flask
Variant: Pre 2.2.0
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 27
KnockbackOnFlaskUseUniqueFlask9
MonstersFleeOnFlaskUseUniqueFlask9
{variant:1}LocalFlaskChargesUsedUniqueFlask9
{variant:1}30% more Melee Physical Damage during effect
{variant:2}(30-35)% more Melee Physical Damage during effect
{variant:3}(20-25)% more Melee Physical Damage during effect
{variant:4}PhysicalDamageOnFlaskUseUniqueFlask9
Knocks Back Enemies in an Area on Flask use
]],[[
Rotgut
Quicksilver Flask
Variant: Pre 2.2.0
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 40
{variant:1}(100-150)% increased Charges used
{variant:2,3}(50-100)% increased Charges used
{variant:3}50% increased Duration
{variant:4}FlaskEffectDurationUnique__3
{variant:1,2}15% chance to gain a Flask Charge when you deal a Critical Strike
{variant:3}FlaskChanceRechargeOnCritUnique__1
FlaskConsumesFrenzyChargesUnique__1
{variant:1,2}Gain Onslaught for 1 second per Frenzy Charge on use
{variant:3}Gain Onslaught for 2 seconds per Frenzy Charge on use
{variant:4}LocalFlaskOnslaughtPerFrenzyChargeUnique__1
]],[[
Rumi's Concoction
Granite Flask
Variant: Pre 1.3.0
Variant: Pre 2.5.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 68
{variant:1}(30-40)% Chance to Block during Flask effect
{variant:2}(20-30)% Chance to Block during Flask effect
{variant:3}(14-20)% Chance to Block during Flask effect
{variant:4}(8-12)% Chance to Block during Flask effect
{variant:1}(15-20)% Chance to Block Spells during Flask effect
{variant:2}(10-15)% Chance to Block Spells during Flask effect
{variant:3}(6-10)% Chance to Block Spells during Flask effect
{variant:4}(4-6)% Chance to Block Spells during Flask effect
]],[[
Replica Rumi's Concoction
Granite Flask
League: Heist
Requires Level 68
FlaskGainEnduranceChargeUnique__1_
BlockIncreasedDuringFlaskEffectUnique__1
SpellBlockIncreasedDuringFlaskEffectUnique__1_
LocalFlaskPetrifiedUnique__1
FlaskIncreasedDurationUnique__2
]],[[
Sin's Rebirth
Stibnite Flask
Requires Level 14
Implicits: 1
UtilityFlaskSmokeCloud
LocalFlaskUnholyMightUnique__1
Immunity to Ignite during Flask effect
Removes Burning on use
]],[[
The Sorrow of the Divine
Sulphur Flask
League: Legion
Source: Drops from Templar Legion
Requires Level 35
Implicits: 1
UtilityFlaskConsecrate
FlaskEffectDurationUnique__1
Zealot's Oath during Flask effect
FlaskZealotsOathUnique__1
]],[[
Replica Sorrow of the Divine
Sulphur Flask
League: Heist
Requires Level 35
Implicits: 1
UtilityFlaskConsecrate
FlaskEffectDurationUnique__1
Eldritch Battery during Flask effect
FlaskZealotsOathUnique__1
]],[[
Soul Catcher
Quartz Flask
League: Incursion
Source: Drops from unique{The Vaal Omnitect}
Upgrade: Upgrades to unique{Soul Ripper} via currency{Vial of the Ghost}
Variant: Pre 3.10.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 27
NoManaRecoveryDuringFlaskEffectUnique__1_
{variant:2}Vaal Skills have (80-120)% increased Critical Strike Chance during effect
{variant:3}FlaskVaalSkillCriticalStrikeChanceUnique__1
{variant:1}Vaal Skills deal (60-100)% increased Damage during effect
{variant:2}Vaal Skills deal (80-120)% increased Damage during effect
{variant:3}Vaal Skills deal (60-80)% increased Damage during effect
{variant:1}Vaal Skills have 25% reduced Soul Cost during effect
{variant:2}Vaal Skills used during effect have (20-40)% reduced Soul Gain Prevention Duration
{variant:3}FlaskVaalSoulPreventionDurationUnique__1_
]],[[
Soul Ripper
Quartz Flask
League: Incursion
Source: Upgraded from unique{Soul Catcher} via currency{Vial of the Ghost}
Variant: Pre 3.10.0
Variant: Current
Requires Level 27
{variant:1}FlaskChargesUsedUnique__7
{variant:1}FlaskVaalSkillDamageUnique__2
{variant:1}FlaskVaalNoSoulPreventionUnique__1
{variant:1}CannotGainFlaskChargesDuringEffectUnique__1
{variant:2}+(-40 to 90) maximum Charges
{variant:2}FlaskLoseChargesOnNewAreaUnique__1
{variant:2}FlaskVaalConsumeMaximumChargesUnique__1
{variant:2}FlaskVaalGainSoulsAsChargesUnique__1_
]],[[
Taste of Hate
Sapphire Flask
Variant: Pre 2.2.0
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 18
{variant:1}30% of Physical Damage from Hits taken as Cold Damage during Flask effect
{variant:2,3}20% of Physical Damage from Hits taken as Cold Damage during Flask effect
{variant:4}PhysicalTakenAsColdUniqueFlask8
{variant:1,2}Gain (20-30)% of Physical Damage as Extra Cold Damage during effect
{variant:3}Gain (15-20)% of Physical Damage as Extra Cold Damage during effect
{variant:4}PhysicalAddedAsColdUniqueFlask8
AvoidChillUniqueFlask8
AvoidFreezeUniqueFlask8
]],[[
The Overflowing Chalice
Sulphur Flask
Requires Level 35
Variant: Pre 3.15.0
Variant: Current
Implicits: 1
UtilityFlaskConsecrate
{variant:1}100% increased Charge Recovery
{variant:2}FlaskChargesAddedIncreasePercentUnique_1
{variant:1}(10-20)% increased Duration
CannotGainFlaskChargesDuringFlaskEffectUnique_1
{variant:1}100% increased Charges gained by Other Flasks during Flask Effect
{variant:2}IncreasedFlaskChargesForOtherFlasksDuringEffectUnique_1
]],[[
Vessel of Vinktar
Topaz Flask
Source: Drops from unique{Avatar of Thunder} in unique{The Vinktar Square}
Variant: Pre 2.2.0 (Penetration)
Variant: Pre 2.2.0 (Spells)
Variant: Pre 2.2.0 (Attacks)
Variant: Pre 2.2.0 (Conversion)
Variant: Pre 3.0.0 (Penetration)
Variant: Pre 3.0.0 (Spells)
Variant: Pre 3.0.0 (Attacks)
Variant: Pre 3.0.0 (Conversion)
Variant: Pre 3.14.0 (Spells)
Variant: Pre 3.14.0 (Conversion)
Variant: Pre 3.15.0 (Penetration)
Variant: Pre 3.15.0 (Spells)
Variant: Pre 3.15.0 (Attacks)
Variant: Current (Conversion)
Variant: Current (Proliferation)
Variant: Current (Penetration)
Variant: Current (Spells)
Variant: Current (Attacks)
Requires Level 68
{variant:5,6,7,8,9,10,11,12,13,14,15}FlaskChargesUsedUnique__6_
{variant:16,17,18}FlaskChargesUsedUnique__5
{variant:1,2,3,4,5,6,7,8}Shocks nearby Enemies during Flask effect
{variant:9,10,11,12,13,14,15,16,17,18}ShockNearbyEnemiesDuringFlaskEffect___1
{variant:1,2,3,4,5,6,7,8}You are Shocked during Flask effect
{variant:9,10,11,12,13,14,15,16,17,18}ShockSelfDuringFlaskEffect__1
{variant:1,2,3,4}30% of Lightning Damage Leeched as Life during Flask effect
{variant:5,6,7,8,9,10,11,12,13,14,15,16,17,18}LightningLifeLeechDuringFlaskEffect__1
{variant:1,2,3,4}30% of Lightning Damage Leeched as Mana during Flask effect
{variant:5,6,7,8}LightningManaLeechDuringFlaskEffect__1
{variant:1,2,3,4}LeechInstantDuringFlaskEffect__1
{variant:1,5,11}Damage Penetrates 10% Lightning Resistance during Flask effect
{variant:16}LightningPenetrationDuringFlaskEffect__1
{variant:2,6,9}Adds (15-25) to (70-90) Lightning Damage to Spells during Flask effect
{variant:12}Adds (25-35) to (110-130) Lightning Damage to Spells during Flask effect
{variant:17}AddedSpellLightningDamageDuringFlaskEffect__1
{variant:3,7,13}Adds (25-35) to (110-130) Lightning Damage to Attacks during Flask effect
{variant:18}AddedLightningDamageDuringFlaskEffect__1
{variant:4,8,10}20% of Physical Damage Converted to Lightning during Flask effect
{variant:14}PhysicalToLightningDuringFlaskEffect__1
{variant:15}(25-40)% increased Effect of Shock during Flask effect
{variant:15}Shocks you inflict during Flask Effect spread to other Enemies within a Radius of 20
]],[[
The Wise Oak
Bismuth Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 8
{variant:1,2}During Flask Effect, 10% reduced Damage taken of each Element for which your Uncapped Elemental Resistance is lowest
{variant:3}FlaskElementalDamageTakenOfLowestResistUnique__1
{variant:1}During Flask Effect, Damage Penetrates 20% Resistance of each Element for which your Uncapped Elemental Resistance is highest
{variant:2}During Flask Effect, Damage Penetrates (10-15)% Resistance of each Element for which your Uncapped Elemental Resistance is highest
{variant:3}FlaskElementalPenetrationOfHighestResistUnique__1
]],[[
Witchfire Brew
Stibnite Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Requires Level 48
Implicits: 1
UtilityFlaskSmokeCloud
{variant:1,2}FlaskChargesUsedUnique__3
{variant:3}(-10-10)% increased Charges used
{variant:1}(50-70)% increased Damage Over Time during Flask Effect
{variant:2}(25-40)% increased Damage Over Time during Flask Effect
VulnerabilityAuraDuringFlaskEffectUnique__1
]],
-- Flask: Ward
[[
Elixir of the Unbroken Circle
Iron Flask
League: Expedition
Requires Level 40
(20–40)% increased Duration
FlaskLoseAllEnduranceChargesGainLifePerLostChargeUnique1
Lose all Endurance Charges on use
FlaskEnduranceChargePerSecondUnique1
]],[[
Olroth's Resolve
Iron Flask
League: Expedition
Requires Level 40
(40–50)% increased Charges used
FlaskWardUnbreakableDuringEffectUnique__1
FlaskMoreWardUnique1
]],[[
Starlight Chalice
Iron Flask
League: Expedition
Requires Level 40
(20–30)% increased Charge Recovery
FlaskFireColdLightningExposureOnNearbyEnemiesUnique1
(20–30)% increased Effect of Non-Damaging Ailments you inflict during Flask Effect
]],[[
Vorana's Preparation
Iron Flask
League: Expedition
Requires Level 40
(-10–10)% reduced Charges used
FlaskDebilitateNearbyEnemiesWhenEffectEndsUnique_1
FlaskRemoveEffectWhenWardBreaksUnique1
FlaskCullingStrikeUnique1
]],
}
