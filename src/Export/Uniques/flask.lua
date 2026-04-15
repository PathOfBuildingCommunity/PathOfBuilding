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
{variant:3}FlaskExtraLifeUnique__1[100,100]
{variant:4,5}FlaskExtraLifeUnique__1
{variant:1}FlaskIncreasedRecoverySpeedUniqueFlask3[-30,-20]
{variant:2,3,4}FlaskIncreasedRecoverySpeedUnique___1[5,20]
{variant:5}FlaskIncreasedRecoverySpeedUniqueFlask3
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
{variant:1}LocalFlaskChargesUsedUniqueFlask2[100,50]
{variant:2}LocalFlaskChargesUsedUniqueFlask2[150,120]
{variant:3}LocalFlaskChargesUsedUniqueFlask2
{variant:1,2}FlaskRemovePercentageOfEnergyShieldUniqueFlask2[20,20]
{variant:3}FlaskRemovePercentageOfEnergyShieldUniqueFlask2
{variant:1,2}FlaskTakeChaosDamagePercentageOfLifeUniqueFlask2[10,10]
{variant:3}FlaskTakeChaosDamagePercentageOfLifeUniqueFlask2
{variant:1,2}FlaskGainEnduranceChargeUniqueFlask2[1,1]
{variant:1,2}FlaskGainFrenzyChargeUniqueFlask2[1,1]
{variant:1,2}FlaskGainPowerChargeUniqueFlask2[1,1]
{variant:3}FlaskGainEnduranceChargeUniqueFlask2
{variant:3}FlaskGainFrenzyChargeUniqueFlask2
{variant:3}FlaskGainPowerChargeUniqueFlask2
]],[[
Lavianga's Spirit
Sanctified Mana Flask
League: Domination, Nemesis
FlaskIncreasedRecoveryAmountUniqueFlask4
LocalFlaskNoManaCostWhileHealingUniqueFlask4
]],[[
Replica Lavianga's Spirit
Sanctified Mana Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
FlaskIncreasedRecoveryAmountUnique__1
LocalFlaskAttackAndCastSpeedWhileHealingUnique__1
FlaskBuffReducedManaCostWhileHealingUnique__1
]],[[
Zerphi's Last Breath
Grand Mana Flask
Variant: Pre 3.2.0
Variant: Current
League: Perandus
FlaskChargesUsedUnique__3
{variant:1}FlaskLifeGainOnSkillUseUnique__1[800,800]
{variant:2}FlaskLifeGainOnSkillUseUnique__1
]],[[
Wellwater Phylactery
Colossal Mana Flask
Source: Drops from unique{Uber Incarnation of Dread} in normal{Moment of Reverence}
Requires Level 64
LocalFlaskChargesUsedUniqueFlask36
FlaskIncreasedRecoveryAmountUnique__2
FlaskLessDurationUnique2
LocalFlaskRemovePercentOfLifeOnUseUnique_7
LocalFlaskStartEnergyShieldRechargeUnique_1
LocalFlaskEnergyShieldRechargeNotDelayedByDamageDuringEffectUnique_1
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
{variant:1,2}FlaskMaximumElementalResistancesUniqueFlask1[6,6]
{variant:3}FlaskMaximumElementalResistancesUniqueFlask1
{variant:1}FlaskItemQuantityUniqueFlask1[20,25]
{variant:2,3,4}FlaskItemQuantityUniqueFlask1[12,18]
{variant:1,2,3,4}FlaskItemRarityUniqueFlask1[40,60]
{variant:5}FlaskItemRarityUniqueFlask1[20,30]
{variant:5}FlaskItemQuantityUniqueFlask1
{variant:6}FlaskItemRarityUniqueFlask1
FlaskLightRadiusUniqueFlask1
{variant:4,5}FlaskElementalResistancesUniqueFlask1_[50,50]
{variant:6}FlaskElementalResistancesUniqueFlask1_
]],[[
The Writhing Jar
Hallowed Hybrid Flask
FlaskChargesUsedUnique__11
FlaskFullInstantRecoveryUnique__1
SummonsWormsOnUse
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
{variant:1}AddedChaosDamageAsPercentOfElementalWhileUsingFlaskUniqueFlask5[13,15]
{variant:2}AddedChaosDamageAsPercentOfElementalWhileUsingFlaskUniqueFlask5[10,15]
{variant:3}AddedChaosDamageAsPercentOfElementalWhileUsingFlaskUniqueFlask5
ChaosDamageLifeLeechPermyriadWhileUsingFlaskUniqueFlask5New
{variant:1}AddedChaosDamageAsPercentOfPhysicalWhileUsingFlaskUniqueFlask5[22,25]
{variant:2}AddedChaosDamageAsPercentOfPhysicalWhileUsingFlaskUniqueFlask5[15,20]
{variant:3}AddedChaosDamageAsPercentOfPhysicalWhileUsingFlaskUniqueFlask5
]],[[
Progenesis
Amethyst Flask
LevelReq: 60
Source: Drops from unique{The Maven} (Uber)
FlaskChargesUsedUnique__11
FlaskIncreasedDurationUnique__3
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
{variant:1}FlaskConsecratedGroundDurationUnique__1[30,50]
{variant:2}FlaskConsecratedGroundDurationUnique__1[20,40]
{variant:3}FlaskConsecratedGroundDurationUnique__1
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
{variant:2}FlaskTakeChaosDamagePerSecondUnique__2
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
{variant:2}FlaskEffectDurationUnique__4[100,100]
{variant:3}FlaskEffectDurationUnique__4
ChaosDamageDoesNotBypassESDuringFlaskEffectUnique__1
RemoveLifeAndAddThatMuchEnergyShieldOnFlaskUseUnique__1
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
{variant:15}FlaskExtraChargesUnique__1[90,90]
{variant:16,17,18}FlaskExtraChargesUnique__3
{variant:13}GainChargeOnConsumingIgnitedCorpseUnique__1__
{variant:15,16,17,18}GainChargeOnConsumingIgnitedCorpseUnique__2
{variant:13}EnemiesIgnitedTakeIncreasedDamageUnique__1[10,10]
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
{variant:2}FlaskChargesUsedUnique__4
{variant:3,4}FlaskChargesUsedUnique___2
{variant:3}FlaskEffectDurationUnique__2[-60,-40]
{variant:4}FlaskLessDurationUnique1
{variant:1}FlaskIncreasedAreaOfEffectDuringEffectUnique__1_[30,30]
{variant:2}FlaskIncreasedAreaOfEffectDuringEffectUnique__1_[15,25]
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
{variant:1}LocalFlaskInstantRecoverPercentOfLifeUniqueFlask6[50,50]
{variant:2}LocalFlaskInstantRecoverPercentOfLifeUniqueFlask6[75,75]
{variant:3,4}LocalFlaskInstantRecoverPercentOfLifeUniqueFlask6
{variant:1}LocalFlaskChaosDamageOfLifeTakenPerMinuteWhileHealingUniqueFlask6[900,900]
{variant:2,3}LocalFlaskChaosDamageOfLifeTakenPerMinuteWhileHealingUniqueFlask6[480,480]
{variant:4}LocalFlaskChaosDamageOfLifeTakenPerMinuteWhileHealingUniqueFlask6
]],[[
Kiara's Determination
Silver Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
Implicits: 0
FlaskImmuneToStunFreezeCursesUnique__1
{variant:1}FlaskEffectDurationUnique__2[-50,-50]
{variant:2}FlaskEffectDurationUnique__2[-60,-60]
{variant:3}FlaskEffectDurationUnique__2
]],[[
Lion's Roar
Granite Flask
Variant: Pre 2.2.0
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
{variant:1}LocalFlaskChargesUsedUniqueFlask9
AoEKnockBackOnFlaskUseUniqueFlask9_
MonstersFleeOnFlaskUseUniqueFlask9
KnockbackOnFlaskUseUniqueFlask9
{variant:1}PhysicalDamageOnFlaskUseUniqueFlask9[30,30]
{variant:2}PhysicalDamageOnFlaskUseUniqueFlask9[30,35]
{variant:3}PhysicalDamageOnFlaskUseUniqueFlask9[20,25]
{variant:4}PhysicalDamageOnFlaskUseUniqueFlask9
]],[[
Rotgut
Quicksilver Flask
Variant: Pre 2.2.0
Variant: Pre 2.6.0
Variant: Pre 3.15.0
Variant: Current
LevelReq: 40
{variant:1,2}FlaskChanceRechargeOnCritUnique__1[15,15]
{variant:3,4}FlaskChanceRechargeOnCritUnique__1
{variant:1}FlaskChargesUsedUnique__8[150,100]
{variant:2,3}FlaskChargesUsedUnique__8[100,50]
{variant:3}FlaskEffectDurationUnique__4[50,50]
{variant:4}FlaskEffectDurationUnique__3
FlaskConsumesFrenzyChargesUnique__1
{variant:1,2}LocalFlaskOnslaughtPerFrenzyChargeUnique__1[1,1]
{variant:3}LocalFlaskOnslaughtPerFrenzyChargeUnique__1[2,2]
{variant:4}LocalFlaskOnslaughtPerFrenzyChargeUnique__1
{variant:1,2,3}(10-30)% increased Movement Speed during Effect
]],[[
Rumi's Concoction
Granite Flask
Variant: Pre 1.3.0
Variant: Pre 2.5.0
Variant: Pre 3.15.0
Variant: Current
LevelReq: 68
{variant:1}BlockIncreasedDuringFlaskEffectUniqueFlask7[30,40]
{variant:2}BlockIncreasedDuringFlaskEffectUniqueFlask7[20,30]
{variant:3}BlockIncreasedDuringFlaskEffectUniqueFlask7[14,20]
{variant:4}BlockIncreasedDuringFlaskEffectUniqueFlask7
{variant:1}SpellBlockIncreasedDuringFlaskEffectUniqueFlask7[15,20]
{variant:2}SpellBlockIncreasedDuringFlaskEffectUniqueFlask7[10,15]
{variant:3}SpellBlockIncreasedDuringFlaskEffectUniqueFlask7[6,10]
{variant:4}SpellBlockIncreasedDuringFlaskEffectUniqueFlask7
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
LocalFlaskUnholyMightUnique__1
]],[[
The Sorrow of the Divine
Sulphur Flask
Variant: Pre 3.7.0
Variant: Current
League: Legion
Implicits: 1
UtilityFlaskConsecrate
{variant:2}FlaskZealotsOathUnique__1
FlaskEffectDurationUnique__1
{variant:1}Zealot's Oath during Effect
]],[[
Replica Sorrow of the Divine
Sulphur Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
Implicits: 1
UtilityFlaskConsecrate
FlaskEldritchBatteryUnique__1
FlaskEffectDurationUnique__1
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
{variant:2}FlaskVaalSkillCriticalStrikeChanceUnique__1[80,120]
{variant:3}FlaskVaalSkillCriticalStrikeChanceUnique__1
{variant:1}FlaskVaalSkillDamageUnique__1[60,100]
{variant:2}FlaskVaalSkillDamageUnique__1[80,120]
{variant:3}FlaskVaalSkillDamageUnique__1
{variant:1}FlaskVaalSkillCostUnique__1
{variant:2}FlaskVaalSoulPreventionDurationUnique__1_[-40,-20]
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
{variant:2}FlaskExtraChargesUnique__2_
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
{variant:1}PhysicalTakenAsColdUniqueFlask8[30,30]
{variant:2,3}PhysicalTakenAsColdUniqueFlask8[20,20]
{variant:4}PhysicalTakenAsColdUniqueFlask8
{variant:5}FireLightningTakenSsColdUniquFlask8
{variant:1,2}PhysicalAddedAsColdUniqueFlask8[20,30]
{variant:3}PhysicalAddedAsColdUniqueFlask8[15,20]
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
{variant:1}FlaskChargesAddedIncreasePercentUnique_1[100,100]
{variant:2}FlaskChargesAddedIncreasePercentUnique_1
{variant:1}FlaskEffectDurationUnique__1[10,20]
{variant:1}IncreasedFlaskChargesForOtherFlasksDuringEffectUnique_1[100,100]
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
{variant:5,6,7,8,9,10,11,12,13}FlaskChargesUsedUnique__6_
{variant:14,15,16,17,18}FlaskChargesUsedUnique__5
ShockNearbyEnemiesDuringFlaskEffect___1
ShockSelfDuringFlaskEffect__1
{variant:1,5,11}LightningPenetrationDuringFlaskEffect__1[10,10]
{variant:16}LightningPenetrationDuringFlaskEffect__1
{variant:2,6,9}AddedSpellLightningDamageDuringFlaskEffect__1[15,25][70,90]
{variant:12}AddedSpellLightningDamageDuringFlaskEffect__1[25,35][110,130]
{variant:17}AddedSpellLightningDamageDuringFlaskEffect__1
{variant:3,7,13}AddedLightningDamageDuringFlaskEffect__1[25,35][110,130]
{variant:18}AddedLightningDamageDuringFlaskEffect__1
{variant:4,8,10}PhysicalToLightningDuringFlaskEffect__1[20,20]
{variant:14}PhysicalToLightningDuringFlaskEffect__1
{variant:15}ShockEffectDuringFlaskEffectUnique__1__
{variant:15}ShockProliferationDuringFlaskEffectUnique__1
{variant:1,2,3,4}LightningLifeLeechDuringFlaskEffect__1[3000,3000]
{variant:5,6,7,8,9,10,11,12,13,14,15,16,17,18}LightningLifeLeechDuringFlaskEffect__1
{variant:1,2,3,4}LightningManaLeechDuringFlaskEffect__1[3000,3000]
{variant:5,6,7,8}LightningManaLeechDuringFlaskEffect__1
{variant:1,2,3,4}LeechInstantDuringFlaskEffect__1
]],[[
The Wise Oak
Bismuth Flask
Variant: Pre 3.0.0
Variant: Pre 3.15.0
Variant: Current
{variant:1,2}FlaskElementalDamageTakenOfLowestResistUnique__1[-10,-10]
{variant:3}FlaskElementalDamageTakenOfLowestResistUnique__1
{variant:1}FlaskElementalPenetrationOfHighestResistUnique__1[20,20]
{variant:2}FlaskElementalPenetrationOfHighestResistUnique__1[10,15]
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
{variant:3}FlaskChargesUsedUnique__4
{variant:1}(50-70)% increased Damage Over Time during Effect
{variant:2}(25-40)% increased Damage Over Time during Effect
VulnerabilityAuraDuringFlaskEffectUnique__1
]],[[
Replica Witchfire Brew
Stibnite Flask
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
UtilityFlaskSmokeCloud
FlaskChargesUsedUnique__10
VulnerabilityAuraDuringFlaskEffectUnique__1Alt
]],[[
Wine of the Prophet
Gold Flask
Source: Drops from unique{Incarnation of Dread} in normal{Moment of Reverence}
Requires Level 27
FlaskExtraChargesUnique__4
FlaskChargesUsedUnique___12
GainDivinationBuffOnFlaskUsedUniqueFlask__1
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
{variant:1}FlaskEffectDurationUnique__7[20,40]
{variant:2}FlaskEffectDurationUnique__7
FlaskLoseAllEnduranceChargesGainLifePerLostChargeUnique1
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
{variant:1}FlaskMoreWardUnique1[-70,-70]
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
FlaskChargesUsedUnique__10
FlaskDebilitateNearbyEnemiesWhenEffectEndsUnique_1
FlaskRemoveEffectWhenWardBreaksUnique1
FlaskCullingStrikeUnique1
]],
}
