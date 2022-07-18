-- Item data (c) Grinding Gear Games

return {
-- Amulet
[[
The Anvil
Amber Amulet
Variant: Pre 1.3.0
Variant: Pre 2.6.0
Variant: Current
Requires Level 45
Implicits: 1
StrengthImplicitAmulet1
ReducedAttackSpeedUniqueAmulet16
IncreasedCastSpeedUniqueAmulet16
IncreasedPhysicalDamageReductionRatingUniqueAmulet16
{variant:1}{tags:life}+(30-40) Life gained when you Block
{variant:2,3}GainLifeOnBlockUniqueAmulet16
{variant:1}{tags:mana}+(10-20) Mana gained when you Block
{variant:2,3}{tags:mana}+(10-24) Mana gained when you Block
{variant:1}MovementVelocityUniqueBodyStr5
{variant:2}MovementSkillCooldownReducedMoveSpeedImplicitR2_
+3% to maximum Block Chance
{variant:1}10% Chance to Block
{variant:2,3}8% Chance to Block
{tags:physical}{variant:1}Reflects 200 to 250 Physical Damage to Attackers on Block
{variant:2,3}ReflectDamageToAttackersOnBlockUniqueAmulet16
]],[[
Araku Tiki
Coral Amulet
Implicits: 1
{tags:life}(2-4) Life Regenerated per second
{tags:jewellery_defense,life}You gain 100 Evasion Rating when on Low Life
IncreasedLifeUniqueAmulet4
FireResistImplicitAmulet1
{tags:life}1% of Life Regenerated per Second while on Low Life
]],[[
Ngamahu Tiki
Coral Amulet
Source: No longer obtainable
Requires Level 36
Implicits: 1
{tags:life}(2-4) Life Regenerated per second
FireDamagePercentUnique__6
{tags:jewellery_defense,life}You gain 100 Evasion Rating when on Low Life
IncreasedLifeUniqueAmulet4
FireResistImplicitAmulet1
{tags:life}1% of Life Regenerated per Second while on Low Life
]],[[
The Ascetic
Gold Amulet
Requires Level 8
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
(80-100)% increased Rarity of Items found with a Normal Item equipped
(10-15)% increased Quantity of Items found with a Magic Item equipped
]],[[
Ashes of the Stars
Onyx Amulet
Source: Drops from unique{The Eater of Worlds}
Requires Level 60
Implicits: 1
AllAttributesImplicitAmulet1
GlobalGemExperienceGainUnique__1
ReservationEfficiencyUnique__4_
GlobalSkillGemLevelUnique__1
GlobalSkillGemQualityUnique__1
]],[[
Astramentis
Onyx Amulet
Requires Level 20
Implicits: 1
AllAttributesImplicitAmulet1
AllAttributesUniqueAmulet8
{tags:attack,physical}-4 Physical Damage taken from Attacks
]],[[
Atziri's Foible
Paua Amulet
Variant: Pre 2.6.0
Variant: Current
Requires Level 16
Implicits: 1
ManaRegenerationImplicitAmulet1
{variant:1}{tags:mana}+50 to maximum Mana
{variant:2}IncreasedManaUniqueAmulet10
{variant:1}{tags:mana}(8-12)% increased maximum Mana
{variant:2}MaximumManaUniqueAmulet10
{variant:1}ManaRegenerationUnique__11___
{variant:2}ManaRegenerationUniqueAmulet10
GlobalItemAttributeRequirementsUniqueAmulet10
]],[[
Replica Atziri's Foible
Paua Amulet
Variant: Pre 3.16.0
Variant: Current
League: Heist
Requires Level 16
Implicits: 1
{tags:life}Regenerate (1.00-2.00)% of Life per second
IncreasedLifeUniqueTwoHandAxe4
{variant:1}{tags:life}(20-25)% increased Life Recovery rate
{variant:2}LifeRecoveryRateUnique__1
GlobalItemAttributeRequirementsUniqueAmulet10
]],[[
Aul's Uprising
Onyx Amulet
League: Delve
Source: Drops from unique{Aul, the Crystal King}
Variant: Strength: Anger
Variant: Strength: Determination
Variant: Strength: Pride
Variant: Strength: Purity of Fire
Variant: Strength: Vitality
Variant: Dexterity: Grace
Variant: Dexterity: Haste
Variant: Dexterity: Hatred
Variant: Dexterity: Purity of Ice
Variant: Intelligence: Clarity
Variant: Intelligence: Discipline
Variant: Intelligence: Malevolence
Variant: Intelligence: Purity of Elements
Variant: Intelligence: Purity of Lightning
Variant: Intelligence: Wrath
Variant: Intelligence: Zealotry
Variant: Envy
Requires Level 55
Implicits: 1
AllAttributesImplicitAmulet1
{variant:1,2,3,4,5}StrengthImplicitAmulet1
{variant:6,7,8,9}DexterityImplicitAmulet1
{variant:10,11,12,13,14,15,16}IntelligenceImplicitAmulet1
{variant:17}GrantsEnvyUnique__2
{variant:1,2,3,4,5}GlobalPhysicalDamageReductionRatingPercentUnique__1
{variant:6,7,8,9}GlobalEvasionRatingPercentUnique__1
{variant:10,11,12,13,14,15,16}GlobalEnergyShieldPercentUnique__1
{variant:17}AllAttributesUnique__12
IncreasedLifeUnique__2
{variant:1,2,3,4,5}NearbyEnemiesReducedStunRecoveryUnique__1
{variant:6,7,8,9}NearbyEnemiesGrantIncreasedFlaskChargesUnique__1
{tags:critical}{variant:10,11,12,13,14,15,16}2% additional Chance to receive a Critical Strike
{variant:1,2,3,4,5}Nearby Enemies have 10% reduced Stun and Block Recovery
{variant:10,11,12,13,14,15,16}NearbyEnemiesHaveIncreasedChanceToBeCritUnique__1
{variant:17}AllDefencesUnique__4
{variant:1}AngerNoReservationUnique__1
{variant:2}DeterminationNoReservationUnique__1
{variant:3}PrideNoReservationUnique__1
{variant:4}PurityOfFireNoReservationUnique__1
{variant:5}VitalityNoReservationUnique__1
{variant:6}GraceNoReservationUnique__1
{variant:7}HasteNoReservationUnique__1
{variant:8}HatredNoReservationUnique__1_
{variant:9}PurityOfIceNoReservationUnique__1_
{variant:10}ClarityNoReservationUnique__1
{variant:11}DisciplineNoReservationUnique__1
{variant:12}MalevolenceNoReservationUnique__1
{variant:13}PurityOfElementsNoReservationUnique__1_
{variant:14}PurityOfLightningNoReservationUnique__1
{variant:15}WrathNoReservationUnique__1
{variant:16}ZealotryNoReservationUnique__1
{variant:17}EnvyNoReservationUnique__1
]],[[
The Aylardex
Agate Amulet
Variant: Pre 2.5.0
Variant: Current
Requires Level 32
Implicits: 1
HybridStrInt
IncreasedLifeUniqueAmulet4
IncreasedManaUniqueHelmetStrDex5_
IncreasedMaximumPowerChargesUnique__1
{tags:mana}10% increased Mana Regeneration Rate Per Power Charge
{variant:2}IncreasedPowerChargeDurationUnique__1
DamageTakeFromManaBeforeLifePerPowerChargeUnique__1
CriticalStrikeChancePerPowerChargeUnique__1
]],[[
Badge of the Brotherhood
Turquoise Amulet
Requires Level: 20
Implicits: 1
League: Blight
HybridDexInt
(7-10)% increased Cooldown Recovery of Travel Skills per Frenzy Charge
ElusiveBuffEffectPerPowerChargeUnique__1
LoseFrenzyChargeOnTravelSkillUnique__1
LosePowerChargeOnElusiveGainUnique__1_
MaximumFrenzyChargesEqualToMaximumPowerChargesUnique__1
]],[[
Bisco's Collar
Gold Amulet
Variant: Pre 3.0.0
Variant: Pre 3.2.0
Variant: Current
Requires Level 30
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
{variant:1}150% increased Rarity of Items Dropped by Slain Magic Enemies
{variant:2,3}MagicMonsterItemRarityUnique__1
{variant:1}100% increased Quantity of Items Dropped by Slain Normal Enemies
{variant:2}(50-100)% increased Quantity of Items Dropped by Slain Normal Enemies
{variant:3}NormalMonsterItemQuantityUnique__1
]],[[
Blightwell
Clutching Talisman
Variant: Pre 3.16.0
Variant: Current
League: Talisman Hardcore
Talisman Tier: 2
Requires Level 28
Implicits: 1
TalismanGlobalDefensesPercent
IncreasedEnergyShieldUniqueAmulet14
FireResistUnique__2
LightningResistUnique__1
{variant:1}30% slower start of Energy Shield Recharge during Flask Effect
{variant:2}50% slower start of Energy Shield Recharge during Flask Effect
{variant:1}400% increased Energy Shield Recharge Rate during Flask Effect
{variant:2}(150-200)% increased Energy Shield Recharge Rate during Flask Effect
Corrupted
]],[[
Blood of Corruption
Amber Amulet
Source: Use currency{Vaal Orb} on unique{Tear of Purity}
Requires Level 20
Implicits: 1
StrengthImplicitAmulet1
Grants level 10 Gluttony of Elements Skill
{tags:attack,chaos}Adds 19-43 Chaos Damage to Attacks
{tags:jewellery_resistance}−(10-5)% to all Elemental Resistances
ChaosResistUniqueAmulet23
Corrupted
]],[[
Bloodgrip
Coral Amulet
Variant: Pre 3.0.0
Variant: Current
Requires Level 55
Implicits: 1
{tags:life}(2.0-4.0) Life Regenerated per second
AddedPhysicalDamageUniqueAmulet25
IncreasedLifeUniqueAmulet25
{variant:1}{tags:life}Regenerate (8.0-12.0) Life per second
{variant:2}{tags:life}Regenerate (16.0-24.0) Life per second
FlaskLifeRecoveryUniqueAmulet25
NoExtraBleedDamageWhileMovingUniqueAmulet25
]],[[
Bloodgrip
Marble Amulet
Variant: Pre 3.12.0
Variant: Current
Requires Level 74
Implicits: 1
{tags:life}(1.2-1.6)% of Life Regenerated per second
AddedPhysicalDamageUniqueAmulet25
IncreasedLifeUniqueAmulet25
{variant:1}{tags:life}Regenerate (8.0-12.0) Life per second
{variant:2}{tags:life}Regenerate (16.0-24.0) Life per second
FlaskLifeRecoveryUniqueAmulet25
NoExtraBleedDamageWhileMovingUniqueAmulet25
]],[[
Carnage Heart
Onyx Amulet
Variant: Pre 2.6.0
Variant: Current
Requires Level 20
Implicits: 1
AllAttributesImplicitAmulet1
AllAttributesUniqueAmulet9
{tags:life}{variant:1}25% reduced maximum Life
{tags:jewellery_defense}{variant:1}25% reduced maximum Energy Shield
AllResistancesUniqueAmulet9
LifeLeechPermyriadUniqueAmulet9
{variant:2}IncreasedDamageWhileLeechingUnique__1
{tags:life}{variant:2}50% increased Life Leeched per second
Extra Gore
]],[[
Crystallised Omniscience
Onyx Amulet
Source: Drops from unique{The Searing Exarch}
Requires Level 61
Implicits: 1
AllAttributesImplicitAmulet1
Modifiers to Attributes instead Apply to Omniscience
+1% to All Elemental Resistances per 10 Omniscience
ElementalPenPerAscendanceUnique__1
AttributeRequirementsAscendanceUnique__1
]],[[
Daresso's Salute
Citrine Amulet
League: Anarchy
Requires Level 16
Implicits: 1
HybridStrDex
ReducedEnergyShieldPercentUniqueAmulet13
FireResistUniqueAmulet13
ColdResistUniqueAmulet13
MovementVelocityOnFullLifeUniqueAmulet13
{tags:attack}+2 to Melee Weapon and Unarmed range
MeleeDamageOnFullLifeUniqueAmulet13
]],[[
The Ephemeral Bond
Lapis Amulet
League: Heist
Requires Level 68
Implicits: 1
IntelligenceImplicitAmulet1
ManaRegenerationUnique__12
AllResistancesUnique__21
CriticalStrikeMultiplierIfGainedPowerChargeUnique__1_
GlobalAddedLightningDamagePerPowerChargeUnique__1
PowerChargeDurationFinalUnique__1__
]],[[
Extractor Mentis
Agate Amulet
Variant: Pre 3.5.0
Variant: Current
Requires Level 16
Implicits: 1
HybridStrInt
StrengthUnique__18
GrantEnemiesUnholyMightOnKillUnique__1
GrantEnemiesOnslaughtOnKillUnique__1
{variant:1}5% chance to gain Unholy Might for 10 seconds on Kill
{variant:2}UnholyMightOnKillPercentChanceUnique__1
{variant:1}{tags:caster,attack}5% chance to gain Onslaught for 10 seconds on Kill
{variant:2}OnslaugtOnKillPercentChanceUnique__1
MaximumLifeOnKillPercentUnique__4_
]],[[
Eye of Chayula
Onyx Amulet
Upgrade: Upgrades to unique{Presence of Chayula} using currency{Blessing of Chayula}
Requires Level 20
Implicits: 1
AllAttributesImplicitAmulet1
MaximumLifeUniqueAmulet6
ItemFoundRarityIncreaseUniqueAmulet6
CannotBeStunned
]],[[
Presence of Chayula
Onyx Amulet
League: Breach
Source: Upgraded from unique{Eye of Chayula} using currency{Blessing of Chayula}
Requires Level 60
Implicits: 1
AllAttributesImplicitAmulet1
ItemFoundRarityIncreaseUniqueAmulet6
ChaosResistUnique__5
CannotBeStunned
MaximumLifeConvertedToEnergyShieldUnique__1
]],[[
Eye of Innocence
Citrine Amulet
Source: Drops from unique{Guardian of the Phoenix}
Requires Level 68
Implicits: 1
HybridStrDex
ChanceToIgniteUniqueBodyInt2
DamageWhileIgnitedUnique__1
TakeFireDamageOnIgniteUnique__1
FireDamageLeechedAsLifeWhileIgnitedUnique__1
]],[[
Eyes of the Greatwolf
Greatwolf Talisman
Requires Level 52
Has Alt Variant: true
Variant: Attributes
Variant: Global Defences
Variant: Chaos Damage
Variant: Attack Damage
Variant: Cold Damage
Variant: Fire Damage
Variant: Lightning Damage
Variant: Spell Damage
Variant: Global Physical Damage
Variant: Mana
Variant: Damage
Variant: Physical Damage Reduction
Variant: Chance to Freeze, Shock and Ignite
Variant: Crit Chance
Variant: Area of Effect
Variant: Attack/Cast Speed
Variant: Item Quantity
Variant: Life
Variant: Crit Multiplier
Variant: Maximum number of Raised Zombies
Variant: Frenzy Charge on Kill
Variant: Power Charge on Kill
Variant: Endurance Charge on Kill
Variant: Life Regen
Variant: Cold taken as Fire
Variant: Cold taken as Lightning
Variant: Fire taken as Cold
Variant: Fire taken as Lightning
Variant: Lightning taken as Cold
Variant: Lightning taken as Fire
Variant: Gain Physical as random Element
Variant: Extra Pierces
Implicits: 32
{variant:1}(24-32)% increased Attributes
{variant:2}(30-50)% increased Global Defences
{variant:3}(38-62)% increased Chaos Damage
{variant:4}(40-60)% increased Attack Damage
{variant:5}(40-60)% increased Cold Damage
{variant:6}SpellDamageUniqueDagger10
{variant:7}(40-60)% increased Lightning Damage
{variant:8}SpellDamageUniqueStaff11_
{variant:9}(40-60)% increased Global Physical Damage
{variant:10}(40-60)% increased maximum Mana
{variant:11}(50-70)% increased Damage
{variant:12}(8-12)% additional Physical Damage Reduction
{variant:13}(8-12)% chance to Freeze, Shock and Ignite
{variant:14}(80-100)% increased Global Critical Strike Chance
{variant:15}(10-16)% increased Area of Effect
{variant:16}(12-20)% increased Attack and Cast Speed
{variant:17}(12-20)% increased Quantity of Items found
{variant:18}(16-24)% increased maximum Life
{variant:19}+(48-72)% to Global Critical Strike Multiplier
{variant:20}+2 to maximum number of Raised Zombies
{variant:21}20% chance to gain a Frenzy Charge on Kill
{variant:22}20% chance to gain a Power Charge on Kill
{variant:23}20% chance to gain a Endurance Charge on Kill
{variant:24}4% of Life Regenerated per second
{variant:25}100% of Cold Damage from Hits taken as Fire Damage
{variant:26}100% of Cold Damage from Hits taken as Lightning Damage
{variant:27}100% of Fire Damage from Hits taken as Cold Damage
{variant:28}100% of Fire Damage from Hits taken as Lightning Damage
{variant:29}100% of Lightning Damage from Hits taken as Cold Damage
{variant:30}100% of Lightning Damage from Hits taken as Fire Damage
{variant:31}Gain (12-24)% of Physical Damage as Extra Damage of a random Element
{variant:32}Projectiles Pierce (4-6) additional Targets
LocalDoubleImplicitMods
]],[[
The Felbog Fang
Citrine Amulet
League: Harvest
Requires Level 61
Implicits: 1
HybridStrDex
IntelligenceUnique__22_
IncreasedCastSpeedUniqueAmulet1
AreaOfEffectUnique__6
{tags:caster}Enemies Cursed by you are Hindered with 25% reduced Movement Speed if 25% of Curse Duration expired
Curse50PercentCurseEffectUnique__1
Curse75PercentEnemyDamageTakenUnique__1__
]],[[
Fury Valve
Turquoise Amulet
League: Metamorph
Requires Level 40
Implicits: 1
HybridDexInt
IncreasedEvasionRatingPercentUnique__2
AllResistancesUniqueAmulet14
AdditionalProjectilesUnique__1__
ProjectileSpeedImplicitQuiver4New
Modifiers to number of Projectiles instead apply to the number of targets Projectiles Split towards
]],[[
Gloomfang
Blue Pearl Amulet
Source: Drops from unique{The Purifier}
Variant: Pre 3.11.0
Variant: Current
Requires Level 77
Implicits: 1
ManaRegenerationImplicitAmulet2
ChaosDamageLifeLeechPermyriadUnique__2
LoseLifeOnSpellHitUnique__1
LoseLifePerTargetUnique__1
AdditionalChainUniqueOneHandMace3
{variant:2}ProjectileSpeedUnique__7
{variant:1}ProjectilesGainPercentOfNonChaosAsChaosUnique__1
{variant:2}ProjectilesGainPercentOfNonChaosAsChaosUnique__2
]],[[
The Halcyon
Jade Amulet
League: Breach
Source: Drops in Tul Breach or from unique{Tul, Creeping Avalanche}
Upgrade: Upgrades to unique{The Pandemonius} using currency{Blessing of Tul}
Requires Level 35
Implicits: 1
DexterityImplicitAmulet1
ColdDamagePercentUnique___10
ColdResistUnique__11
FreezeDurationUnique__1
ChanceToFreezeUnique__4
IncreasedDamageIfFrozenRecentlyUnique__1
]],[[
The Pandemonius
Jade Amulet
League: Breach
Source: Upgraded from unique{The Halcyon} using currency{Blessing of Tul}
Requires Level 64
Implicits: 1
DexterityImplicitAmulet1
ColdDamagePercentUniqueBelt9b
ColdResistUnique__11
Chill Enemy for 1 second when Hit
OnHitBlindChilledEnemiesUnique__1_
ColdPenetrationAgainstChilledEnemiesUnique__1
]],[[
Hinekora's Sight
Onyx Amulet
Requires Level 20
Variant: Pre 3.16.0
Variant: Current
Implicits: 1
AllAttributesImplicitAmulet1
{variant:1}{tags:attack}+1000 to Accuracy Rating
{variant:2}IncreasedAccuracyUnique__3
{variant:2}IncreasedEvasionRatingUnique__6_
{variant:1}(12-20)% chance to Suppress Spell Damage
{variant:2}SpellDamageSuppressedUnique__1
BlindImmunityUnique__1
]],[[
Hyrri's Truth
Jade Amulet
League: Synthesis
Requires Level 64
Variant: Pre 3.16.0
Variant: Current
Implicits: 1
DexterityImplicitAmulet1
GrantsAccuracyAuraSkillUnique__1
DexterityUnique__15
AddedPhysicalDamageUnique__7
AddedColdDamageUnique__8
CriticalMultiplierUnique__3__
LifeLeechPermyriadUnique__6
{variant:1}Precision has 50% less Reservation
{variant:2}PrecisionReservationEfficiencyUnique__1
]],[[
Replica Hyrri's Truth
Jade Amulet
League: Heist
Variant: Pre 3.16.0
Variant: Current
Requires Level 64
Implicits: 1
DexterityImplicitAmulet1
GrantsHatredUnique__1__
DexterityUnique__15
AddedPhysicalDamageUnique__7
AddedColdDamageUnique__8
CriticalMultiplierUnique__3__
{tags:life}(0.8-1.0)% of Cold Damage Leeched as Life
{variant:1}Hatred has 50% less Reservation
{variant:2}HatredManaReservationEfficiencyUnique__1__
]],[[
The Ignomon
Gold Amulet
Requires Level 8
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
DexterityUniqueAmulet7
AddedFireDamageUniqueAmulet7
IncreasedAccuracyUniqueAmulet7
IncreasedEvasionRatingUniqueAmulet7
FireResistUniqueAmulet7
]],[[
The Effigon
Gold Amulet
Source: No longer obtainable
Requires Level 57
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
DexterityUniqueAmulet7
AddedFireDamageUniqueAmulet7
IncreasedAccuracyUniqueAmulet7
IncreasedEvasionRatingUniqueAmulet7
FireResistUniqueAmulet7
HitsCannotBeEvadedAgainstBlindedEnemiesUnique__1
FirePenetrationAgainstBlindedEnemiesUnique__1
]],[[
Impresence
Onyx Amulet
Source: Drops from unique{The Elder} (Tier 11+)
Variant: Physical
Variant: Fire
Variant: Cold
Variant: Lightning
Variant: Chaos
Requires Level 64
Implicits: 1
AllAttributesImplicitAmulet1
{variant:1}GlobalAddedPhysicalDamageUnique__1_
{variant:2}GlobalAddedFireDamageUnique__1
{variant:3}GlobalAddedColdDamageUnique__1
{variant:4}GlobalAddedLightningDamageUnique__1_
{variant:5}GlobalAddedChaosDamageUnique__1
IncreasedLifeUnique__2
{variant:1}IncreasedPhysicalDamageReductionRatingUniqueAmulet16
{variant:2}LifeRegenerationRatePercentUnique__3
{variant:3}ManaRegenerationUnique__7
{variant:4}EnergyShieldRegenerationUnique__2
{variant:5}DegenerationDamageUnique__3
{variant:1}StunRecoveryUnique__3
{variant:2}FireResistUniqueShieldStrInt5
{variant:3}ColdResistUnique__20
{variant:4}LightningResistUnique__11
{variant:5}ChaosResistUnique__17
{variant:1}VulnerabilityReservationCostUnique__1_
{variant:2}FlammabilityReservationCostUnique__1
{variant:3}FrostbiteReservationCostUnique__1
{variant:4}ConductivityReservationCostUnique__1
{variant:5}DespairReservationCostUnique__1
GainDebilitatingPresenceUnique__1
Elder Item
]],[[
Karui Ward
Jade Amulet
Variant: Pre 2.6.0
Variant: Current
Requires Level 5
Implicits: 1
DexterityImplicitAmulet1
StrengthImplicitAmulet1
IncreasedAccuracyUniqueAmulet5
{variant:2}IncreasedProjectileDamageUnique__6
ProjectileSpeedUniqueAmulet5
MovementVelocityUniqueAmulet5
]],[[
Replica Karui Ward
Jade Amulet
League: Heist
Requires Level 5
Implicits: 1
DexterityImplicitAmulet1
IntelligenceImplicitAmulet1
IncreasedAccuracyUniqueAmulet5
MovementVelocityUniqueAmulet5
AreaOfEffectUnique__7_
AreaDamageUnique__1
]],[[
Karui Charge
Jade Amulet
Source: No longer obtainable
Variant: Pre 2.6.0
Variant: Pre 3.17.0
Requires Level 24
Implicits: 1
DexterityImplicitAmulet1
StrengthImplicitAmulet1
{variant:1}LocalIncreasedAttackSpeedUnique__25
{variant:2}LocalIncreasedAttackSpeedUniqueStaff9
IncreasedAccuracyUniqueAmulet5
{variant:2}IncreasedProjectileDamageUnique__6
ProjectileSpeedUniqueAmulet5
MovementVelocityUniqueAmulet5
]],[[
Leadership's Price
Onyx Amulet
Requires Level 68
Implicits: 1
AllAttributesImplicitAmulet1
MaximumFireResistUnique__1
MaximumColdResistUnique__1_
MaximumLightningResistUnique__1
ScorchingBrittleSappingConfluxUnique__1
CannotIgniteChillFreezeShockUnique__1
Corrupted
]],[[
Maligaro's Cruelty
Turquoise Amulet
Requires Level 20
Implicits: 1
HybridDexInt
MaximumLifeUnique__6
(25-30)% chance to gain a Frenzy Charge on Killing an Enemy affected by 5 or more Poisons
GainPowerChargeOnKillVsEnemiesWithLessThan5PoisonsUnique__1
PoisonDamagePerFrenzyChargeUnique__1
PoisonDurationPerPowerChargeUnique__1
]],[[
The Jinxed Juju
Citrine Amulet
Variant: Pre 3.16.0
Variant: Current
Requires Level 48
Implicits: 1
HybridStrDex
IntelligenceUnique__16
ChaosResistUnique__15
{variant:1}UniqueSpecialCorruptionCurseEffect___
{variant:2}CurseEffectivenessUnique__3_
{variant:1}UniqueSpecialCorruptionAuraEffect
{variant:2}AuraEffectGlobalUnique__1
DamageRemovedFromSpectresUnique__1
(The damage they take will be divided evenly between them)
]],[[
Marylene's Fallacy
Lapis Amulet
Variant: Pre 1.3.0
Variant: Pre 2.0.0
Variant: Pre 2.2.0
Variant: Pre 2.6.0
Variant: Current
Requires Level 40
Implicits: 1
IntelligenceImplicitAmulet1
IncreasedAccuracyUniqueAmulet17_
{tags:critical}{variant:1,2,3}+(140-160)% to Global Critical Strike Multiplier
{variant:4,5}CriticalMultiplierUniqueAmulet17
IncreasedEvasionRatingUniqueAmulet17
LightRadiusUniqueAmulet17
{variant:1,2}Non-critical strikes deal 25% Damage
{variant:3,4}Non-critical strikes deal 40% Damage
{tags:critical}{variant:1}60% less Critical Strike Chance
{tags:critical}{variant:2}50% less Critical Strike Chance
{tags:critical}{variant:3,4,5}40% less Critical Strike Chance
{variant:1,2,3,4}Your Critical Strikes have Culling Strike
{variant:5}CullingCriticalStrikes
]],[[
Natural Hierarchy
Rotfeather Talisman
League: Talisman Standard, Talisman Hardcore
Talisman Tier: 3
Requires Level 44
Implicits: 1
TalismanIncreasedDamage
(10-15)% increased Physical Damage
FireDamagePercentUnique__4
ColdDamagePercentUnique__6
LightningDamagePercentUnique__2
IncreasedChaosDamageUnique__1
Corrupted
]],[[
Night's Hold
Black Maw Talisman
League: Talisman Standard, Talisman Hardcore
Talisman Tier: 1
Requires Level 12
Implicits: 1
AmuletHasOneSocket
LocalIncreaseSocketedGemLevelUnique__11_
SocketedGemsHaveAddedChaosDamageUnique__1
Socketed Gems are Supported by Level 10 Blind
Socketed Gems are Supported by Level 10 Cast when Stunned
Corrupted
]],[[
Perquil's Toe
Gold Amulet
Requires Level 29
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
DexterityUnique__7
MovementVelocityUnique__36_
Lightning Damage from Enemies Hitting you is Lucky
UniqueNearbyAlliesAreLuckyDisplay
]],[[
The Primordial Chain
Coral Amulet
League: Delve
Requires Level 34
Implicits: 1
{tags:life}(2-4) Life Regenerated per second
+3 to maximum number of Golems
CannotHaveNonGolemMinionsUnique__1_
GolemSizeUnique__1
LessGolemDamageUnique__1
LessGolemLifeUnique__1
GolemMovementSpeedUnique__1
PrimordialJewelCountUnique__1
]],[[
Rashkaldor's Patience
Jade Amulet
Requires Level 61
Implicits: 1
DexterityImplicitAmulet1
IncreasedLifeUniqueAmulet19
IncreasedManaUniqueAmulet19
ElementalStatusAilmentDurationUniqueAmulet19
GlobalItemAttributeRequirementsUniqueAmulet19
ChanceToFreezeShockIgniteUniqueAmulet19
MaxPowerChargesIsZeroUniqueAmulet19
]],[[
Retaliation Charm
Citrine Amulet
Requires Level 30
Implicits: 1
HybridStrDex
IncreaseDamageOnBlindedEnemiesUnique__1
CriticalChanceAgainstBlindedEnemiesUnique__2__
ChanceToBlindOnCriticalStrikesUnique__2_
BlindDoesNotAffectLightRadiusUnique__1
BlindReflectedToSelfUnique__1
]],[[
Rigwald's Curse
Wereclaw Talisman
League: Talisman Standard
Variant: Pre 2.2.0
Variant: Current
Talisman Tier: 2
Requires Level 28
Implicits: 2
{variant:1}+(16-24)% to Global Critical Strike Multiplier
{variant:2}TalismanIncreasedCriticalStrikeMultiplier_
BaseUnarmedCriticalStrikeChanceUnique__1
ClawDamageModsAlsoAffectUnarmedUnique__1
ClawAttackSpeedModsAlsoAffectUnarmed__1
ClawCritModsAlsoAffectUnarmed__1
Corrupted
]],[[
Sacrificial Heart
Paua Amulet
Variant: Pre 3.14.0
Variant: Current
League: Incursion
Source: Drops from unique{The Vaal Omnitect}
Upgrade: Upgrades to unique{Zerphi's Heart} via currency{Vial of Sacrifice}
Requires Level 32
Implicits: 1
ManaRegenerationImplicitAmulet1
GlobalAddedFireDamageUnique__2
GlobalAddedColdDamageUnique__2_
GlobalAddedLightningDamageUnique__2_
{variant:1}GainPowerChargeOnUsingVaalSkillUnique__1
LifeGainOnHitIfVaalSkillUsedRecentlyUnique__1
MovementVelocityIfVaalSkillUsedRecentlyUnique__1_
{variant:2}GainMaximumPowerChargesOnVaalSkillUseUnique__1
]],[[
Zerphi's Heart
Paua Amulet
League: Incursion
Source: Upgraded from unique{Sacrificial Heart} via currency{Vial of Sacrifice}
Variant: Pre 3.10.0
Variant: Current
Requires Level 70
Implicits: 1
ManaRegenerationImplicitAmulet1
GlobalAddedChaosDamageUnique__4__
GlobalItemAttributeRequirementsUnique__2
ChaosDamageCanIgniteChillAndShockUnique__1
{variant:1}Gain Soul Eater for 10 seconds when you use a Vaal Skill
{variant:2}GainSoulEaterOnVaalSkillUseUnique__1
]],[[
Shaper's Seed
Agate Amulet
Variant: Pre 2.6.0
Variant: Current
Requires Level 16
Implicits: 1
HybridStrInt
ManaRegenerationUniqueAmulet21
{tags:life}2% of Life Regenerated per Second
{variant:1}{tags:life}Nearby Allies gain 1% of Life Regenerated per Second
{variant:2}{tags:life}Nearby Allies gain 2% of Life Regenerated per Second
DisplayManaRegenerationAuaUniqueAmulet21
]],[[
Sidhebreath
Paua Amulet
Variant: Pre 3.0.0
Variant: Pre 3.8.0
Variant: Current
Implicits: 1
ManaRegenerationImplicitAmulet1
ColdResistUniqueAmulet3
{variant:1,2}ManaLeechPermyriadUniqueAmulet3
MinionLifeUniqueAmulet3
MinionRunSpeedUniqueAmulet3
{tags:jewellery_elemental}{variant:3}Minions deal 6 to 13 additional Cold Damage
{variant:1,2}MinionDamageUniqueAmulet3
{variant:2,3}MinionSkillManaCostUnique__1_
]],[[
Solstice Vigil
Onyx Amulet
Source: Drops from unique{The Shaper}
Variant: Pre 3.10.0
Variant: Current
Requires Level 64
Implicits: 1
AllAttributesImplicitAmulet1
{variant:1}AllDamageUnique__2
{variant:2}AllDamageUnique__4
IncreasedLifeUnique__2
{variant:1}{tags:mana}(2-3) Mana Regenerated per second
{variant:2}{tags:mana}(8-10) Mana Regenerated per second
TemporalChainsReservationCostUnique__1
GainShapersPresenceUnique__1
]],[[
Star of Wraeclast
Ruby Amulet
Source: Vendor recipe
Variant: Pre 2.6.0
Variant: Pre 3.8.0
Variant: Current
Requires Level 28
Implicits: 1
FireResistImplicitAmulet1
{variant:3}GrantsFrostblinkSkillUnique__1
ColdDamagePercentUnique__3
AllResistancesUniqueBootsStr1
{variant:1}{tags:caster}30% increased Area of Effect of Hex Skills
{variant:2,3}CurseAreaOfEffectUnique__1
SilenceImmunityUnique__1
{variant:1,2}Grants level 20 Illusory Warp Skill
{variant:3}FrostblinkDurationUnique__1_
Corrupted
]],[[
Stone of Lazhwar
Lapis Amulet
Variant: Pre 3.4.0
Variant: Current
Requires Level 5
Implicits: 1
IntelligenceImplicitAmulet1
{variant:1}+15% chance to Block Spell Damage
{variant:2}+(12-15)% chance to Block Spell Damage
IncreasedCastSpeedUniqueAmulet1
IncreasedManaUniqueAmulet1
]],[[
Stranglegasp
Onyx Amulet
Source: Drops in Blight-ravaged Maps
Requires Level 52
Implicits: 1
AllAttributesImplicitAmulet1
MultipleEnchantmentsAllowedUnique__2
]],[[
Tavukai
Coral Amulet
League: Legion
Source: Drops from Karui Legion
Requires Level 54
Implicits: 1
{tags:life}(2.0-4.0) Life regenerated per second
IntelligenceUnique__16
{tags:chaos,jewellery_resistance}Minions have (-17-17)% to Chaos Resistance
RagingSpiritDurationUnique__1
RagingSpiritDamageUnique__2
RagingSpiritLifeUnique__1
RagingSpiritChaosDamageTakenUnique__1
]],[[
Tear of Purity
Lapis Amulet
Variant: Pre 3.16.0
Variant: Current
Requires Level 20
Implicits: 1
IntelligenceImplicitAmulet1
Grants level 10 Purity of Elements Skill
AllAttributesUniqueAmulet22
IncreasedLifeUniqueAmulet22
{variant:1}5% chance to avoid Elemental Ailments
{variant:2}ChanceToAvoidElementalStatusAilmentsUniqueAmulet22
]],[[
Ungil's Harmony
Turquoise Amulet
Variant: Pre 3.11.0
Variant: Current
Requires Level 23
Implicits: 1
HybridDexInt
{variant:1}CriticalStrikeChanceUniqueBodyInt4
{variant:2}CriticalStrikeChanceUniqueAmulet18
IncreasedLifeUniqueAmulet4
IncreasedManaUniqueAmulet1
StunRecoveryUniqueAmulet18
CriticalMultiplierUniqueAmulet18
]],[[
Uul-Netol's Vow
Unset Amulet
Source: Drops from Flawless Breachlords
Requires Level 72
Implicits: 1
AmuletHasOneSocket
SupportGemsSocketedInAmuletAlsoSupportBodySkills
FireResistUnique__28_
ColdResistUnique__35
LightningResistUnique__25
ChaosResistUnique__24
]],[[
Victario's Acuity
Turquoise Amulet
League: Onslaught
Requires Level 16
Implicits: 1
HybridDexInt
LightningResistUniqueAmulet15
ChaosResistUniqueAmulet15_
FrenzyChargeOnKillChanceUniqueAmulet15
PowerChargeOnKillChanceUniqueAmulet15
ProjectileSpeedPerFrenzyChargeUniqueAmulet15
ProjectileDamagePerPowerChargeUniqueAmulet15
]],[[
Voice of the Storm
Lapis Amulet
League: Breach
Source: Drops in Esh Breach or from unique{Esh, Forked Thought}
Upgrade: Upgrades to unique{Choir of the Storm} using currency{Blessing of Esh}
Variant: Pre 3.16.0
Variant: Current
Requires Level 40
Implicits: 1
IntelligenceImplicitAmulet1
LightningStrikesOnCritUnique__1
AllAttributesUniqueHelmetStrInt5
MaximumManaUniqueStaff4
{variant:1}Critical Strike Chance is increased by Lightning Resistance
{variant:2}CriticalChanceIncreasedByUncappedLightningResistanceUnique__1
]],[[
Choir of the Storm
Lapis Amulet
League: Breach
Source: Upgraded from unique{Voice of the Storm} using currency{Blessing of Esh}
Variant: Pre 3.0.0
Variant: Pre 3.16.0
Variant: Current
Requires Level 69
Implicits: 1
IntelligenceImplicitAmulet1
LightningStrikesOnCritUnique__2
CriticalStrikesDealIncreasedLightningDamageUnique__1
MaximumManaUniqueStaff4
{variant:1,2}Critical Strike Chance is increased by Lightning Resistance
{variant:1,3}LightningResistUnique__9
{variant:3}CriticalChanceIncreasedByUncappedLightningResistanceUnique__1
]],[[
Voll's Devotion
Agate Amulet
League: Anarchy, Onslaught
Requires Level 32
Implicits: 1
HybridStrInt
IncreasedLifeUniqueAmulet14
IncreasedEnergyShieldUniqueAmulet14
AllResistancesUniqueAmulet14
EnduranceChargeDurationUniqueAmulet14
PowerChargeDurationUniqueAmulet14
Gain an Endurance Charge when a Power Charge expires or is consumed
]],[[
Warped Timepiece
Turquoise Amulet
Variant: Pre 3.11.0
Variant: Current
Requires Level 50
Implicits: 1
HybridDexInt
{variant:1}LocalIncreasedAttackSpeedUnique__24
{variant:2}IncreasedAttackSpeedUniqueAmulet20
{variant:1}IncreasedCastSpeedUniqueClaw7
{variant:2}IncreasedCastSpeedUniqueAmulet1
{tags:speed}12% increased Movement Speed
{variant:1}(8-12)% reduced Skill Effect Duration
{variant:2}ReducedSkillEffectDurationUniqueAmulet20
IncreasedLifeLeechRateUniqueAmulet20
]],[[
Willowgift
Jade Amulet
Variant: Pre 3.16.0
Variant: Current
Requires Level 52
Implicits: 1
DexterityImplicitAmulet1
PercentageStrengthUnique__4_
PercentageDexterityUnique__5
FireResistUnique__22_
ColdResistUniqueAmulet13
AlternateFortifyUnique__1_
{variant:2}+4% chance to Suppress Spell Damage per Fortification
AttackAndCastSpeedFortifyUnique__1
]],[[
Winterheart
Gold Amulet
Requires Level 42
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
DexterityImplicitAmulet1
IncreasedLifeUnique__2
ColdResistUnique__5
CannotBeChilledUniqueBodyStrInt3
{tags:life}20% of Life Regenerated per Second while Frozen
]],[[
Replica Winterheart
Gold Amulet
League: Heist
Requires Level 42
Implicits: 1
ItemFoundRarityIncreaseImplicitAmulet1
DexterityImplicitAmulet1
IncreasedEnergyShieldUnique__9
LightningResistUnique__23_
EnergyShieldRegenerationWhileShockedUnique__1
UnaffectedByShockUnique__1
]],[[
Xoph's Heart
Amber Amulet
League: Breach
Source: Drops in Xoph Breach or from unique{Xoph, Dark Embers}
Upgrade: Upgrades to unique{Xoph's Blood} using currency{Blessing of Xoph}
Requires Level 35
Implicits: 1
StrengthImplicitAmulet1
StrengthImplicitAmulet1
FireDamagePercentUnique___7
IncreasedLifeUnique__25
FireResistUnique__23_
CoverInAshWhenHitUnique__1
]],[[
Xoph's Blood
Amber Amulet
League: Breach
Source: Upgraded from unique{Xoph's Heart} using currency{Blessing of Xoph}
Requires Level 64
Implicits: 1
StrengthImplicitAmulet1
MaximumLifeUniqueBodyInt3
FireResistUnique__23_
PercentageStrengthUnique__3
FirePenetrationUnique__1
CoverInAshWhenHitUnique__1
KeystoneAvatarOfFireUnique__1
]],[[
Yoke of Suffering
Onyx Amulet
Source: Drops from unique{The Eradicator} (Tier 11+)
Requires Level 70
Implicits: 1
AllAttributesImplicitAmulet1
FireResistUnique__15
ColdResistUniqueBelt13
LightningResistUnique__5
IncreasedAilmentDurationUnique__2
ChanceToShockUnique__3
EnemiesTakeIncreasedDamagePerAilmentTypeUnique__1
ElementalDamageCanShockUnique__1__
]],
}
