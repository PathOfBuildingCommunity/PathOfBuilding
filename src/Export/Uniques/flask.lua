-- Item data (c) Grinding Gear Games

return {
-- Flask: Life
[[
Blood of the Karui
Sanctified Life Flask
League: Domination, Nemesis
Variant: Pre 1.3.0
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Pre 3.16.0
Variant: Current
{variant:3}100% increased Life Recovered
{variant:4,5}FlaskExtraLifeUnique__1
{variant:1}(30-20)% reduced Recovery rate
{variant:2,3,4}(5-20)% increased Recovery rate
{variant:5}(50-35)% reduced Recovery rate
LocalFlaskLifeOnFlaskDurationEndUniqueFlask3
{variant:1,2}Cannot gain Life during effect
]],
-- Flask: Mana
[[
Doedre's Elixir
Greater Mana Flask
Variant: Pre 2.0.0
Variant: Pre 3.15.0
Variant: Current
Implicits: 0
{variant:1}(100-50)% increased Charges per use
{variant:2}(150-120)% increased Charges per use
{variant:3}(300-250)% increased Charges per use
{variant:1,2}Removes 20% of your maximum Energy Shield on use
{variant:3}FlaskRemovePercentageOfEnergyShieldUniqueFlask2
{variant:1,2}You take 10% of your maximum Life as Chaos Damage on use
{variant:3}FlaskTakeChaosDamagePercentageOfLifeUniqueFlask2
{variant:1,2}FlaskGainEnduranceChargeUnique__1_
{variant:1,2}Gain 1 Frenzy Charge on use
{variant:1,2}Gain 1 Power Charge on use
{variant:3}FlaskGainEnduranceChargeUniqueFlask2
{variant:3}FlaskGainFrenzyChargeUniqueFlask2
{variant:3}FlaskGainPowerChargeUniqueFlask2
]],[[
Lavianga's Spirit
Sanctified Mana Flask
League: Domination, Nemesis
FlaskIncreasedRecoveryAmountUnique__1
100% increased Recovery rate
LocalFlaskNoManaCostWhileHealingUniqueFlask4
]],[[
Replica Lavianga's Spirit
Sanctified Mana Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
FlaskIncreasedRecoveryAmountUnique__1
50% reduced Recovery rate
LocalFlaskAttackAndCastSpeedWhileHealingUnique__1
(5-15)% increased Cast Speed during Effect
FlaskBuffReducedManaCostWhileHealingUnique__1
]],[[
Zerphi's Last Breath
Grand Mana Flask
Variant: Pre 3.2.0
Variant: Current
League: Perandus
FlaskChargesUsedUnique__3
{variant:1}Grants Last Breath when you Use a Skill during Effect, for 800% of Mana Cost
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
Variant: Pre 3.25.0
Variant: Current
{variant:1,2}+6% to all maximum Elemental Resistances during Effect
{variant:3}FlaskMaximumElementalResistancesUniqueFlask1
{variant:1}(20-25)% increased Quantity of Items found during Effect
{variant:2,3,4}(12-18)% increased Quantity of Items found during Effect
{variant:1,2,3,4}(40-60)% increased Rarity of Items found during Effect
{variant:5}(20-30)% increased Rarity of Items found during Effect
{variant:5}FlaskItemQuantityUniqueFlask1
{variant:6}FlaskItemRarityUniqueFlask1
FlaskLightRadiusUniqueFlask1
{variant:4,5}+50% to Elemental Resistances during Effect
{variant:6}FlaskElementalResistancesUniqueFlask1_
]],[[
The Writhing Jar
Hallowed Hybrid Flask
(-10--20)% increased Charges per use
(75-65)% reduced Amount Recovered
Instant Recovery
SummonsWormsOnUse
Writhing Worms are destroyed when Hit
]],
-- Flask: Utility
[[
Atziri's Promise
Amethyst Flask
Source: Drops from unique{Atziri, Queen of the Vaal} in normal{The Apex of Sacrifice}
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
LevelReq: 68
{variant:1}Gain (13-15)% of Elemental Damage as Extra Chaos Damage during effect
{variant:2}Gain (10-15)% of Elemental Damage as Extra Chaos Damage during effect
{variant:3}AddedChaosDamageAsPercentOfElementalWhileUsingFlaskUniqueFlask5
ChaosDamageLifeLeechPermyriadWhileUsingFlaskUniqueFlask5New
{variant:1}Gain (22-25)% of Physical Damage as Extra Chaos Damage during effect
{variant:2}Gain (15-20)% of Physical Damage as Extra Chaos Damage during effect
{variant:3}AddedChaosDamageAsPercentOfPhysicalWhileUsingFlaskUniqueFlask5
]],[[
Progenesis
Amethyst Flask
LevelReq: 60
Source: Drops from unique{The Maven} (Uber)
FlaskChargesUsedUnique__11
(-35-35)% increased Duration
LifeLossToPreventDuringFlaskEffectToLoseOverTimeUnique__1
]],[[
Bottled Faith
Sulphur Flask
League: Synthesis
Source: Drops from unique{Synthete Nightmare} in normal{The Cortex}
Variant: Pre 3.15.0
Variant: Pre 3.16.0
Variant: Current
Implicits: 1
UtilityFlaskConsecrate
{variant:1}FlaskEffectDurationUnique__3
{variant:2}(20-40)% increased Duration
{variant:3}(30-15)% reduced Duration
FlaskConsecratedGroundAreaOfEffectUnique__1_
{variant:1}FlaskConsecratedGroundEffectUnique__1_
FlaskConsecratedGroundDamageTakenUnique__1
{variant:2,3}FlaskConsecratedGroundEffectCriticalStrikeUnique__1
]],[[
Coralito's Signature
Diamond Flask
Variant: Pre 3.15.0
Variant: Current
{variant:1}FlaskTakeChaosDamagePerSecondUnique__1
{variant:2}Take (200-300) Chaos Damage per Second during Effect
FlaskChanceToPoisonUnique__1
FlaskHitsHaveNoCritMultiUnique__1
{variant:1}FlaskPoisonDurationUnique__1
{variant:1}FlaskGrantsPerfectAgonyUnique__1_
{variant:2}FlaskCriticalStrikeDoTMultiplierUnique__1
]],[[
Coruscating Elixir
Ruby Flask
Variant: Pre 2.6.0
Variant: Pre 3.16.0
Variant: Current
Implicits: 0
{variant:2}100% increased Duration
{variant:3}FlaskEffectDurationUnique__4
ChaosDamageDoesNotBypassESDuringFlaskEffectUnique__1
RemoveLifeAndAddThatMuchEnergyShieldOnFlaskUseUnique__1
Removed life is Regenerated as Energy Shield over 2 seconds
]],[[
Cinderswallow Urn
Silver Flask
League: Betrayal
Source: Drops from unique{Catarina, Master of Undeath}
Has Alt Variant: true
Selected Variant: 16
Selected Alt Variant: 6
Variant: Pre 3.26 Crit Chance
Variant: Damage Taken is Leeched as Life
Variant: Item Rarity
Variant: Pre 3.26 Movement Speed/Stun Avoidance
Variant: Stun Avoidance
Variant: Life Regen
Variant: Reduced Reflected Damage Taken
Variant: Physical Damage can Ignite
Variant: Ignited enemies have Malediction
Variant: Additional Curse
Variant: Ignite Spread
Variant: Ignite Leech
Variant: Pre 3.15.0
Variant: Pre 3.16.0 Crit Chance
Variant: Pre 3.26
Variant: Life on Kill
Variant: Mana on Kill
Variant: ES on Kill
LevelReq: 48
Implicits: 0
{variant:15}+90 to maximum Charges
{variant:16,17,18}+(10-20) to maximum Charges
{variant:13}GainChargeOnConsumingIgnitedCorpseUnique__1__
{variant:15,16,17,18}GainChargeOnConsumingIgnitedCorpseUnique__2
{variant:13}Enemies Ignited by you during Effect take 10% increased Damage
{variant:14,15,16,17,18}EnemiesIgnitedTakeIncreasedDamageUnique__1
{variant:13,15,16}RecoverMaximumLifeOnKillFlaskEffectUnique__1
{variant:13,15,17}RecoverMaximumManaOnKillFlaskEffectUnique__1
{variant:13,15,18}RecoverMaximumEnergyShieldOnKillFlaskEffectUnique__1
{variant:14}FlaskChargesUsedUnique__8
{variant:14}{crafted}(60-80)% increased Critical Strike Chance during Effect
{variant:1}{crafted}(45-55)% increased Critical Strike Chance during Effect
{variant:2}{crafted}15% of Damage Taken from Hits is Leeched as Life during Effect
{variant:3}{crafted}(20-30)% increased Rarity of Items found during Effect
{variant:4}{crafted}(8-12)% increased Movement Speed during Effect
{variant:4,5}{crafted}50% Chance to avoid being Stunned during Effect
{variant:6}{crafted}Regenerate 3% of Life per second during Effect
{variant:7}{crafted}(60-80)% reduced Reflected Damage taken during Effect
{variant:8}{crafted}Your Physical Damage can Ignite during Effect
{variant:9}{crafted}Enemies Ignited by you during Effect have Malediction
{variant:10}{crafted}You can apply an additional Curse during Effect
{variant:11}{crafted}Ignites you inflict during Effect spread to other Enemies within 1.5 metres
{variant:12}{crafted}Leech 1.5% of Expected Ignite Damage as Life when you Ignite an Enemy during Effect
]],[[
Dying Sun
Ruby Flask
Source: Drops from unique{The Shaper}
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Pre 3.16.0
Variant: Current
LevelReq: 68
{variant:2}(10--10)% increased Charges per use
{variant:3,4}(150-125)% increased Charges per use
{variant:3}(60-40)% reduced duration
{variant:4}(60-40)% less duration
{variant:1}30% increased Area of Effect during Effect
{variant:2}(15-25)% increased Area of Effect during Effect
{variant:3,4}FlaskIncreasedAreaOfEffectDuringEffectUnique__1_
FlaskAdditionalProjectilesDuringEffectUnique__1
]],[[
Forbidden Taste
Quartz Flask
Variant: Pre 1.2.3
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Current
{variant:1,2}FlaskChargesUsedUnique__3
{variant:1}Recover 50% of Life on use
{variant:2}Recover 75% of Life on use
{variant:3,4}LocalFlaskInstantRecoverPercentOfLifeUniqueFlask6
{variant:1}15% of maximum Life taken as Chaos Damage per second
{variant:2,3}8% of Maximum Life taken as Chaos Damage per second
{variant:4}LocalFlaskChaosDamageOfLifeTakenPerMinuteWhileHealingUniqueFlask6
]],[[
Kiara's Determination
Silver Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Implicits: 0
FlaskImmuneToStunFreezeCursesUnique__1
{variant:1}50% reduced Duration
{variant:2}60% reduced Duration
{variant:3}(80-60)% reduced Duration
]],[[
Lion's Roar
Granite Flask
Variant: Pre 2.2.0
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
{variant:1}(100-70)% increased Charges per use
AoEKnockBackOnFlaskUseUniqueFlask9_
MonstersFleeOnFlaskUseUniqueFlask9
KnockbackOnFlaskUseUniqueFlask9
{variant:1}30% more Melee Physical Damage during effect
{variant:2}(30-35)% more Melee Physical Damage during effect
{variant:3}(20-25)% more Melee Physical Damage during effect
{variant:4}PhysicalDamageOnFlaskUseUniqueFlask9
]],[[
Rotgut
Quicksilver Flask
Variant: Pre 2.2.0
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Current
LevelReq: 40
{variant:1,2}15% chance to gain a Flask Charge when you deal a Critical Strike
{variant:3,4}FlaskChanceRechargeOnCritUnique__1
{variant:1}(150-100)% increased Charges per use
{variant:2,3}(100-50)% increased Charges per use
{variant:3}50% increased Duration
{variant:4}FlaskEffectDurationUnique__3
FlaskConsumesFrenzyChargesUnique__1
{variant:1,2}Gain Onslaught for 1 second per Frenzy Charge on use
{variant:3}Gain Onslaught for 2 seconds per Frenzy Charge on use
{variant:4}Gain Onslaught for 3 seconds per Frenzy Charge on use
{variant:1,2,3}(10-30)% increased Movement Speed during Effect
]],[[
Rumi's Concoction
Granite Flask
Variant: Pre 1.3.0
Variant: Pre 2.5.0
Variant: Pre 3.15.0
Variant: Current
LevelReq: 68
{variant:1}(30-40)% Chance to Block Attack Damage during Effect
{variant:2}(20-30)% Chance to Block Attack Damage during Effect
{variant:3}(14-20)% Chance to Block Attack Damage during Effect
{variant:4}(8-12)% Chance to Block Attack Damage during Effect
{variant:1}(15-20)% Chance to Block Spell Damage during Effect
{variant:2}(10-15)% Chance to Block Spell Damage during Effect
{variant:3}(6-10)% Chance to Block Spell Damage during Effect
{variant:4}(4-6)% Chance to Block Spell Damage during Effect
]],[[
Replica Rumi's Concoction
Granite Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
LevelReq: 68
FlaskIncreasedDurationUnique__2
FlaskGainEnduranceChargeUnique__1_
LocalFlaskPetrifiedUnique__1
BlockIncreasedDuringFlaskEffectUnique__1
SpellBlockIncreasedDuringFlaskEffectUnique__1_
]],[[
Sin's Rebirth
Stibnite Flask
Implicits: 1
UtilityFlaskSmokeCloud
FlaskDispellsBurningUnique__1
Removes all Burning when used
LocalFlaskUnholyMightUnique__1
]],[[
The Sorrow of the Divine
Sulphur Flask
Variant: Pre 3.7.0
Variant: Current
League: Legion
Implicits: 1
UtilityFlaskConsecrate
{variant:2}FlaskEldritchBatteryUnique__1
FlaskEffectDurationUnique__1
Zealot's Oath during Effect
]],[[
Replica Sorrow of the Divine
Sulphur Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
Implicits: 1
UtilityFlaskConsecrate
FlaskEldritchBatteryUnique__1
FlaskEffectDurationUnique__1
Eldritch Battery during Effect
]],[[
Soul Catcher
Quartz Flask
League: Incursion
Source: Drops from unique{The Vaal Omnitect}
Upgrade: Upgrades to unique{Soul Ripper} via currency{Vial of the Ghost}
Variant: Pre 3.10.0
Variant: Pre 3.15.0
Variant: Current
NoManaRecoveryDuringFlaskEffectUnique__1_
{variant:2}(80-120)% increased Critical Strike Chance with Vaal Skills during effect
{variant:3}FlaskVaalSkillCriticalStrikeChanceUnique__1
{variant:1}(60-100)% increased Damage with Vaal Skills during effect
{variant:2}(80-120)% increased Damage with Vaal Skills during effect
{variant:3}FlaskVaalSkillDamageUnique__1
{variant:1}FlaskVaalSkillCostUnique__1
{variant:2}Vaal Skills used during effect have (20-40)% reduced Soul Gain Prevention Duration
{variant:3}FlaskVaalSoulPreventionDurationUnique__1_
]],[[
Soul Ripper
Quartz Flask
League: Incursion
Source: Upgraded from unique{Soul Catcher} via currency{Vial of the Ghost}
Variant: Pre 3.10.0
Variant: Current
{variant:1}FlaskChargesUsedUnique__7
{variant:1}FlaskVaalSkillDamageUnique__2
{variant:1}FlaskVaalNoSoulPreventionUnique__1
{variant:1}CannotGainFlaskChargesDuringEffectUnique__1
{variant:2}+(-40-90) maximum Charges
{variant:2}FlaskLoseChargesOnNewAreaUnique__1
{variant:2}FlaskVaalConsumeMaximumChargesUnique__1
{variant:2}FlaskVaalGainSoulsAsChargesUnique__1_
]],[[
Taste of Hate
Sapphire Flask
Variant: Pre 2.2.0
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Pre 3.25.0
Variant: Current
{variant:1}30% of Physical Damage from Hits taken as Cold Damage during Effect
{variant:2,3}20% of Physical Damage from Hits taken as Cold Damage during Effect
{variant:4}PhysicalTakenAsColdUniqueFlask8
{variant:5}FireLightningTakenSsColdUniquFlask8
{variant:1,2}Gain (20-30)% of Physical Damage as Extra Cold Damage during effect
{variant:3}Gain (15-20)% of Physical Damage as Extra Cold Damage during effect
{variant:4,5}PhysicalAddedAsColdUniqueFlask8
AvoidChillUniqueFlask8
AvoidFreezeUniqueFlask8
]],[[
The Overflowing Chalice
Sulphur Flask
Variant: Pre 3.15.0
Variant: Current
Implicits: 1
UtilityFlaskConsecrate
{variant:1}100% increased Charge Recovery
{variant:2}FlaskChargesAddedIncreasePercentUnique_1
{variant:1}(10-20)% increased Duration
{variant:1}100% increased Charges gained by Other Flasks during Effect
{variant:2}IncreasedFlaskChargesForOtherFlasksDuringEffectUnique_1
CannotGainFlaskChargesDuringFlaskEffectUnique_1
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
LevelReq: 68
{variant:5,6,7,8,9,10,11,12,13}(100-80)% increased Charges per use
{variant:14,15,16,17,18}(150-125)% increased Charges per use
ShockNearbyEnemiesDuringFlaskEffect___1
ShockSelfDuringFlaskEffect__1
{variant:1,5,11}Damage Penetrates 10% Lightning Resistance during Effect
{variant:16}LightningPenetrationDuringFlaskEffect__1
{variant:2,6,9}Adds (15-25) to (70-90) Lightning Damage to Spells during Effect
{variant:12}Adds (25-35) to (110-130) Lightning Damage to Spells during Effect
{variant:17}AddedSpellLightningDamageDuringFlaskEffect__1
{variant:3,7,13}Adds (25-35) to (110-130) Lightning Damage to Attacks during Effect
{variant:18}AddedLightningDamageDuringFlaskEffect__1
{variant:4,8,10}20% of Physical Damage Converted to Lightning during Effect
{variant:14}PhysicalToLightningDuringFlaskEffect__1
{variant:15}ShockEffectDuringFlaskEffectUnique__1__
{variant:15}ShockProliferationDuringFlaskEffectUnique__1
{variant:1,2,3,4}30% of Lightning Damage Leeched as Life during Effect
{variant:5,6,7,8,9,10,11,12,13,14,15,16,17,18}LightningLifeLeechDuringFlaskEffect__1
{variant:1,2,3,4}30% of Lightning Damage Leeched as Mana during Effect
{variant:5,6,7,8}LightningManaLeechDuringFlaskEffect__1
{variant:1,2,3,4}LeechInstantDuringFlaskEffect__1
]],[[
The Wise Oak
Bismuth Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
{variant:1,2}During Effect, 10% reduced Damage taken of each Element for which your Uncapped Elemental Resistance is lowest
{variant:3}FlaskElementalDamageTakenOfLowestResistUnique__1
{variant:1}During Effect, Damage Penetrates 20% Resistance of each Element for which your Uncapped Elemental Resistance is highest
{variant:2}During Effect, Damage Penetrates (10-15)% Resistance of each Element for which your Uncapped Elemental Resistance is highest
{variant:3}FlaskElementalPenetrationOfHighestResistUnique__1
]],[[
Oriath's End
Bismuth Flask
LevelReq: 56
Source: Drops from unique{Sirus, Awakener of Worlds} (Uber)
FlaskChargesAddedIncreasePercentUnique__3
EnemyExplosionRandomElementFlaskEffectUnique__1
]],[[
Witchfire Brew
Stibnite Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
LevelReq: 48
Implicits: 1
UtilityFlaskSmokeCloud
{variant:1,2}FlaskChargesUsedUnique__3
{variant:3}(10--10)% increased Charges per use
{variant:1}(50-70)% increased Damage Over Time during Effect
{variant:2}(25-40)% increased Damage Over Time during Effect
VulnerabilityAuraDuringFlaskEffectUnique__1
]],[[
Replica Witchfire Brew
Stibnite Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
UtilityFlaskSmokeCloud
FlaskChargesUsedUnique__4
VulnerabilityAuraDuringFlaskEffectUnique__1Alt
]],[[
Wine of the Prophet
Gold Flask
Source: Drops from unique{Incarnation of Dread} in normal{Moment of Reverence}
Requires Level 27
FlaskExtraChargesUnique__4
(20-100)% increased Charges per Use
Grants a random Divination buff for 20 seconds when used
]],
-- Flask: Ward
[[
Elixir of the Unbroken Circle
Iron Flask
Variant: Pre 3.25.0
Variant: Current
League: Expedition
Source: Drops from unique{Medved, Feller of Heroes} in normal{Expedition Logbook}
Implicits: 1
UtilityFlaskWard
{variant:1}(20-40)% increased Duration
{variant:2}FlaskEffectDurationUnique__7
FlaskLoseAllEnduranceChargesGainLifePerLostChargeUnique1
Lose all Endurance Charges on use
FlaskEnduranceChargePerSecondUnique1
]],[[
Olroth's Resolve
Iron Flask
Variant: Pre 3.25.0
Variant: Current
League: Expedition
Source: Drops from unique{Olroth, Origin of the Fall} in normal{Expedition Logbook}
Implicits: 1
UtilityFlaskWard
(50-40)% increased Charges per use
FlaskWardUnbreakableDuringEffectUnique__1
{variant:1}70% less Ward during Effect
{variant:2}FlaskMoreWardUnique1
]],[[
Starlight Chalice
Iron Flask
League: Expedition
Source: Drops from unique{Uhtred, Covetous Traitor} in normal{Expedition Logbook}
Implicits: 1
UtilityFlaskWard
FlaskChargesAddedIncreasePercentUnique__2
FlaskFireColdLightningExposureOnNearbyEnemiesUnique1
FlaskNonDamagingAilmentIncreasedEffectUnique__1
]],[[
Vorana's Preparation
Iron Flask
League: Expedition
Source: Drops from unique{Vorana, Last to Fall} in normal{Expedition Logbook}
Implicits: 1
UtilityFlaskWard
(10--10)% increased Charges per use
FlaskDebilitateNearbyEnemiesWhenEffectEndsUnique_1
FlaskRemoveEffectWhenWardBreaksUnique1
FlaskCullingStrikeUnique1
]],
}
