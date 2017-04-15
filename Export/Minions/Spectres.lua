-- Path of Building
--
-- Spectre Data
-- Monster data (c) Grinding Gear Games
--
local minions, mod = ...

-- Blackguard
minions["Metadata/Monsters/Axis/AxisCaster"] = {
	name = "Blackguard Mage",
	life = 0.9,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.305,
	weaponType1 = "Wand",
	weaponType2 = "Shield",
	skillList = {
		"Melee",
		"SkeletonSpark",
		"MonsterLightningThorns",
		"AxisClaimSoldierMinions",
	},
	modList = {
		-- MonsterCastsSparkText
		-- MonsterCastsLightningThornsText
	},
}
minions["Metadata/Monsters/Axis/AxisCasterArc"] = {
	name = "Blackguard Arcmage",
	life = 0.9,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.305,
	weaponType1 = "Wand",
	weaponType2 = "Shield",
	skillList = {
		"Melee",
		"MonsterLightningThorns",
		"MonsterArc",
		"AxisClaimSoldierMinions",
	},
	modList = {
		-- MonsterCastsArcText
		-- MonsterCastsLightningThornsText
	},
}
minions["Metadata/Monsters/Axis/AxisExperimenter"] = {
	name = "Mortality Experimenter",
	life = 0.96,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 75,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Wand",
	skillList = {
		"Melee",
		"SkeletonTemporalChains",
		"ExperimenterDetonateDead",
	},
	modList = {
		-- MonsterCastsTemporalChainsText
		-- MonsterDetonatesCorpsesText
	},
}
minions["Metadata/Monsters/Axis/AxisExperimenter2"] = {
	name = "Flesh Sculptor",
	life = 0.96,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 75,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Wand",
	skillList = {
		"ExperimenterDetonateDead",
		"Melee",
		"MonsterEnfeeble",
		"MonsterProjectileWeakness",
	},
	modList = {
		-- MonsterDetonatesCorpsesText
		-- MonsterCastsEnfeebleCurseText
		-- MonsterCastsProjectileWeaknessCurseText
	},
}
minions["Metadata/Monsters/Axis/AxisExperimenterRaiseZombie"] = {
	name = "Reanimator",
	life = 0.96,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 75,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Wand",
	skillList = {
		"Melee",
		"MonsterEnfeeble",
		"NecromancerRaiseZombie",
	},
	modList = {
		-- MonsterCastsEnfeebleCurseText
		-- MonsterRaisesZombiesText
	},
}
-- Bandit
minions["Metadata/Monsters/Bandits/BanditBowPoisonArrow"] = {
	name = "Alira's Deadeye",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterCausticArrow",
	},
	modList = {
		-- MonsterFiresCausticArrowsText
	},
}
minions["Metadata/Monsters/Bandits/BanditMeleeWarlordsMarkMaul"] = {
	name = "Oak's Devoted",
	life = 1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.35,
	weaponType1 = "Two Handed Mace",
	skillList = {
		"Melee",
		"MonsterWarlordsMark",
	},
	modList = {
		-- MonsterCastsWarlordsMarkCurseText
	},
}
-- Beast
minions["Metadata/Monsters/Beasts/BeastCaveDegenAura"] = {
	name = "Shaggy Monstrosity",
	life = 2.1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.605,
	skillList = {
		"Melee",
		"ChaosDegenAura",
	},
	modList = {
		mod("Damage", "MORE", -33), -- MonsterSpeedAndDamageFixupComplete
		mod("Speed", "MORE", 33), -- MonsterSpeedAndDamageFixupComplete
	},
}
minions["Metadata/Monsters/Beasts/BeastCleaveEnduringCry"] = {
	name = "Hairy Bonecruncher",
	life = 2.1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.605,
	skillList = {
		"Melee",
		"MonsterEnduringCry",
		"BeastCleave",
	},
	modList = {
		mod("Damage", "MORE", -33), -- MonsterSpeedAndDamageFixupComplete
		mod("Speed", "MORE", 33), -- MonsterSpeedAndDamageFixupComplete
		-- MonsterUsesEnduringCryText
		-- MonsterCleavesText
	},
}
-- Blood apes
minions["Metadata/Monsters/BloodChieftain/MonkeyChiefBloodEnrage"] = {
	name = "Carnage Chieftain",
	life = 1.5,
	fireResist = 75,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.395,
	weaponType1 = "One Handed Mace",
	skillList = {
		"Melee",
		"BloodChieftainSummonMonkeys",
		"MassFrenzy",
	},
	modList = {
		mod("Damage", "MORE", -22), -- MonsterSpeedAndDamageFixupLarge
		mod("Speed", "MORE", 22), -- MonsterSpeedAndDamageFixupLarge
		-- MonsterSummonsMonkeysText
		-- MonsterCastsMassFrenzyText
	},
}
-- Goatmen
minions["Metadata/Monsters/Goatman/GoatmanLeapSlam"] = {
	name = "Goatman",
	life = 1,
	fireResist = 40,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.455,
	skillList = {
		"MonsterLeapSlam",
		"Melee",
		"GoatmanWait",
		"GoatmanWait2",
	},
	modList = {
		-- MonsterLeapsOntoEnemiesText
	},
}
minions["Metadata/Monsters/Goatman/GoatmanLightningLeapSlamMaps"] = {
	name = "Bearded Devil",
	life = 1,
	fireResist = 40,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 1.8,
	damageSpread = 0.2,
	attackTime = 1.455,
	skillList = {
		"MonsterLeapSlam",
		"Melee",
		"GoatmanWait",
		"GoatmanWait2",
	},
	modList = {
		mod("PhysicalDamageGainAsLightning", "BASE", 100), -- MonsterPhysicalAddedAsLightningSkeletonMaps
		-- MonsterLeapsOntoEnemiesText
	},
}
minions["Metadata/Monsters/Goatman/GoatmanShamanFireball"] = {
	name = "Goatman Shaman",
	life = 1,
	energyShield = 0.2,
	fireResist = 75,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.5,
	weaponType1 = "Staff",
	skillList = {
		"MonsterFireball",
		"GoatmanMoltenShell",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "INC", -50, ModFlag.Cast), -- MonsterGoatmanShamanCastSpeed
		-- MonsterCastsFireballText
		-- MonsterCastsMoltenShellText
	},
}
minions["Metadata/Monsters/Goatman/GoatmanShamanLightning"] = {
	name = "Bearded Shaman",
	life = 1,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.5,
	weaponType1 = "Staff",
	skillList = {
		"Melee",
		"MonsterShockNova",
		"MonsterSpark",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "INC", -50, ModFlag.Cast), -- MonsterGoatmanShamanCastSpeed
		-- MonsterCastsShockNovaText
		-- MonsterCastsSparkText
	},
}
-- Miscreation
minions["Metadata/Monsters/DemonFemale/DemonFemale"] = {
	name = "Whipping Miscreation",
	life = 0.99,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.88,
	damageSpread = 0.2,
	attackTime = 2.445,
	skillList = {
		"Melee",
	},
	modList = {
		-- MonsterChanceToVulnerabilityOnHit2
	},
}
minions["Metadata/Monsters/DemonModular/DemonFemaleRanged"] = {
	name = "Tentacle Miscreation",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 1.84,
	damageSpread = 0.2,
	attackTime = 3,
	skillList = {
		"DemonFemaleRangedProjectile",
	},
	modList = {
		mod("PhysicalDamageConvertToFire", "BASE", 50), -- MonsterConvertToFireDamage2
	},
}
minions["Metadata/Monsters/DemonModular/DemonModularFire"] = {
	name = "Burned Miscreation",
	life = 1,
	fireResist = 40,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"MonsterRighteousFire",
		"MonsterRighteousFireWhileSpectred",
	},
	modList = {
		-- MonsterCastsUnholyFireText
	},
}
-- Maw
minions["Metadata/Monsters/Frog/Frog"] = {
	name = "Fetid Maw",
	life = 1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.455,
	skillList = {
		"MonsterLeapSlam",
		"Melee",
	},
	modList = {
		-- MonsterLeapsOntoEnemiesText
	},
}
minions["Metadata/Monsters/Frog/Frog2"] = {
	name = "Murk Fiend",
	life = 1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.455,
	skillList = {
		"MonsterLeapSlam",
		"Melee",
	},
	modList = {
		-- MonsterLeapsOntoEnemiesText
	},
}
-- Chimeral
minions["Metadata/Monsters/GemMonster/Iguana"] = {
	name = "Plumed Chimeral",
	life = 1.25,
	energyShield = 0.2,
	fireResist = 52,
	coldResist = 52,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.12,
	damageSpread = 0.2,
	attackTime = 1.005,
	skillList = {
		"IguanaProjectile",
		"Melee",
	},
	modList = {
		-- MonsterSuppressingFire
		-- DisplayMonsterSuppressingFire
	},
}
-- Ghost pirate
minions["Metadata/Monsters/GhostPirates/GhostPirateBlackBowMaps"] = {
	name = "Spectral Bowman",
	life = 0.96,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.48,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterPuncture",
	},
	modList = {
		mod("PhysicalDamageGainAsLightning", "BASE", 100), -- MonsterPhysicalAddedAsLightningSkeletonMaps
		-- MonsterCastsPunctureText
	},
}
minions["Metadata/Monsters/GhostPirates/GhostPirateBlackFlickerStrikeMaps"] = {
	name = "Cursed Mariner",
	life = 1,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.8,
	damageSpread = 0.2,
	attackTime = 1.65,
	weaponType1 = "One Handed Sword",
	weaponType2 = "Shield",
	skillList = {
		"Melee",
		"MonsterFlickerStrike",
	},
	modList = {
		mod("PhysicalDamageGainAsLightning", "BASE", 100), -- MonsterPhysicalAddedAsLightningSkeletonMaps
		-- MonsterUsesFlickerStrikeText
	},
}
-- Undying grappler
minions["Metadata/Monsters/Grappler/Grappler"] = {
	name = "Undying Grappler",
	life = 1,
	fireResist = 20,
	coldResist = 20,
	lightningResist = 20,
	chaosResist = 20,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.245,
	skillList = {
		"Melee",
		"MonsterFlickerStrike",
		"MonsterDischarge",
	},
	modList = {
		-- MonsterGainsPowerChargeOnKinDeath
		-- MonsterUsesFlickerStrikeText
		-- MonsterCastsDischargeText
	},
}
-- Ribbon
minions["Metadata/Monsters/Guardians/GuardianFire"] = {
	name = "Flame Sentinel",
	life = 1.8,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 75,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.2,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"MonsterMultiFireball",
		"MonsterSplitFireball",
		"MonsterLesserMultiFireball",
		"MonsterMultiFireballSpectre",
		"MonsterSplitFireballSpectre",
		"MonsterLesserMultiFireballSpectre",
	},
	modList = {
		-- MonsterCastsAugmentedFireballsText
	},
}
minions["Metadata/Monsters/Guardians/GuardianLightning"] = {
	name = "Galvanic Ribbon",
	life = 1.8,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 85,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.2,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"GuardianArc",
	},
	modList = {
		-- MonsterChannelsLightningText
	},
}
-- Gut flayer
minions["Metadata/Monsters/HalfSkeleton/HalfSkeleton"] = {
	name = "Gut Flayer",
	life = 1.32,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.1,
	damageSpread = 0.3,
	attackTime = 1.5,
	weaponType1 = "Dagger",
	skillList = {
		"Melee",
		"HalfSkeletonPuncture",
	},
	modList = {
		-- MonsterCastsPunctureText
	},
}
-- Construct
minions["Metadata/Monsters/incaminion/Fragment"] = {
	name = "Ancient Construct",
	life = 0.7,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 40,
	damage = 1.84,
	damageSpread = 0.2,
	attackTime = 1.995,
	skillList = {
		"IncaMinionProjectile",
	},
	modList = {
	},
}
-- Carrion queen
minions["Metadata/Monsters/InsectSpawner/InsectSpawner"] = {
	name = "Carrion Queen",
	life = 2.45,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 1.91,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"InsectSpawnerSpit",
		"InsectSpawnerSpawn",
	},
	modList = {
		mod("PhysicalDamageConvertToFire", "BASE", 50), -- MonsterConvertToFireDamage2
	},
}
-- Birdman
minions["Metadata/Monsters/Kiweth/Kiweth"] = {
	name = "Avian Retch",
	life = 1.54,
	energyShield = 0.2,
	fireResist = 0,
	coldResist = 40,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.68,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"BirdmanConsumeCorpse",
		"BirdmanBloodProjectile",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		-- MonsterLesserFarShot
	},
}
minions["Metadata/Monsters/Kiweth/KiwethSeagull"] = {
	name = "Gluttonous Gull",
	life = 1.3,
	energyShield = 0.12,
	fireResist = 0,
	coldResist = 40,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.56,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"BirdmanConsumeCorpse",
		"BirdmanBloodProjectile",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		-- MonsterLesserFarShot
	},
}
-- Helion
minions["Metadata/Monsters/Lion/LionDesertSkinPuncture"] = {
	name = "Dune Hellion",
	life = 1,
	fireResist = 40,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"MonsterPuncture",
	},
	modList = {
		-- MonsterCastsPunctureText
	},
}
-- Knitted horror
minions["Metadata/Monsters/MassSkeleton/MassSkeleton"] = {
	name = "Knitted Horror",
	life = 2.25,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"SkeletonMassBowProjectile",
	},
	modList = {
		-- MonsterCastsPunctureText
	},
}
-- Voidbearer
minions["Metadata/Monsters/Monkeys/FlameBearer"] = {
	name = "Voidbearer",
	life = 1.1,
	fireResist = 40,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.1,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"FlamebearerFlameBlue",
	},
	modList = {
	},
}
-- Stone golem
minions["Metadata/Monsters/MossMonster/FireMonster"] = {
	name = "Cinder Elemental",
	life = 2.7,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.695,
	skillList = {
		"Melee",
		"FireMonsterWhirlingBlades",
	},
	modList = {
		mod("Damage", "MORE", -33), -- MonsterSpeedAndDamageFixupComplete
		mod("Speed", "MORE", 33), -- MonsterSpeedAndDamageFixupComplete
		-- MonsterRollsOverEnemiesText
		-- ImmuneToLavaDamage
	},
}
-- Necromancer
minions["Metadata/Monsters/Necromancer/NecromancerConductivity"] = {
	name = "Sin Lord",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerConductivity",
	},
	modList = {
		-- MonsterRaisesUndeadText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
		-- MonsterCastsConductivityText
	},
}
minions["Metadata/Monsters/Necromancer/NecromancerEnfeebleCurse"] = {
	name = "Diabolist",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerEnfeeble",
	},
	modList = {
		-- MonsterRaisesUndeadText
		-- MonsterCastsEnfeebleCurseText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
	},
}
minions["Metadata/Monsters/Necromancer/NecromancerFlamability"] = {
	name = "Ash Prophet",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerFlammability",
	},
	modList = {
		-- MonsterRaisesUndeadText
		-- MonsterCastsFlammabilityText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
		-- ImmuneToLavaDamage
	},
}
minions["Metadata/Monsters/Necromancer/NecromancerFrostbite"] = {
	name = "Death Bishop",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerFrostbite",
	},
	modList = {
		-- MonsterRaisesUndeadText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
		-- MonsterCastsFrostbiteText
	},
}
minions["Metadata/Monsters/Necromancer/NecromancerElementalWeakness"] = {
	name = "Defiler",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerElementalWeakness",
	},
	modList = {
		-- MonsterRaisesUndeadText
		-- MonsterCastsElementralWeaknessCurseText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
	},
}
minions["Metadata/Monsters/Necromancer/NecromancerProjectileWeakness"] = {
	name = "Necromancer",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerProjectileWeakness",
	},
	modList = {
		-- MonsterRaisesUndeadText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
		-- MonsterCastsProjectileWeaknessCurseText
	},
}
minions["Metadata/Monsters/Necromancer/NecromancerVulnerability"] = {
	name = "Necromancer",
	life = 1.86,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 1.98,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"NecromancerReviveSkeleton",
		"NecromancerVulnerability",
	},
	modList = {
		-- MonsterRaisesUndeadText
		mod("Speed", "INC", -80, ModFlag.Cast, KeywordFlag.Curse), -- MonsterCurseCastSpeedPenalty
		-- MonsterCastsVulnerabilityCurseText
	},
}
-- Undying bomber
minions["Metadata/Monsters/Pyromaniac/PyromaniacFire"] = {
	name = "Undying Incinerator",
	life = 1,
	fireResist = 75,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"PyroFireball",
		"PyroSuicideExplosion",
		"MonsterFireBomb",
	},
	modList = {
		-- MonsterThrowsFireBombsText
		-- MonsterExplodesOnItsTargetOnLowLifeText
		-- ImmuneToLavaDamage
	},
}
minions["Metadata/Monsters/Pyromaniac/PyromaniacPoison"] = {
	name = "Undying Alchemist",
	life = 1,
	fireResist = 75,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"Melee",
		"MonsterCausticBomb",
		"PyroChaosFireball",
	},
	modList = {
		-- MonsterThrowsPoisonBombsText
	},
}
-- Stygian revenant
minions["Metadata/Monsters/Revenant/Revenant"] = {
	name = "Stygian Revenant",
	life = 1.82,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 75,
	chaosResist = 0,
	damage = 2.4,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"RevenantReviveUndead",
		"RevenantSpellProjectile",
		"Melee",
		"RevenantSpellProjectileSpectre",
	},
	modList = {
	},
}
-- Sea witch
minions["Metadata/Monsters/Seawitch/SeaWitchScreech"] = {
	name = "Singing Siren",
	life = 1.02,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 75,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.02,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"SeaWitchWave",
		"Melee",
		"SeaWitchScreech",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
	},
}
minions["Metadata/Monsters/Seawitch/SeaWitchSpawnExploding"] = {
	name = "Merveil's Attendant",
	life = 1.02,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 75,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.02,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"SeaWitchWave",
		"Melee",
		"SummonExplodingSpawn",
		"SeaWitchScreech",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		-- MonsterSummonsExplodingSpawnText
	},
}
minions["Metadata/Monsters/Seawitch/SeaWitchSpawnTemporalChains"] = {
	name = "Merveil's Chosen",
	life = 1.02,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 75,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.02,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"SeaWitchWave",
		"Melee",
		"SkeletonTemporalChains",
		"SummonSpawn",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		-- MonsterSummonsSpawnText
		-- MonsterCastsTemporalChainsText
	},
}
minions["Metadata/Monsters/Seawitch/SeaWitchVulnerabilityCurse"] = {
	name = "Merveil's Chosen",
	life = 1.02,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 75,
	lightningResist = 0,
	chaosResist = 0,
	damage = 2.02,
	damageSpread = 0.2,
	attackTime = 1.5,
	skillList = {
		"SeaWitchWave",
		"Melee",
		"SkeletonVulnerability",
	},
	modList = {
		mod("Damage", "MORE", -11), -- MonsterSpeedAndDamageFixupSmall
		mod("Speed", "MORE", 11), -- MonsterSpeedAndDamageFixupSmall
		-- MonsterCastsVulnerabilityCurseText
	},
}
-- Skeleton
minions["Metadata/Monsters/Skeletons/SkeletonBowPuncture"] = {
	name = "Brittle Bleeder",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterPuncture",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterCastsPunctureText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonBowLightning"] = {
	name = "Brittle Poacher",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterLightningArrow",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterFiresLightningArrowsText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonMeleeLarge"] = {
	name = "Colossal Bonestalker",
	life = 1.98,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 2.8,
	damageSpread = 0.2,
	attackTime = 2.25,
	weaponType1 = "One Handed Mace",
	skillList = {
		"Melee",
	},
	modList = {
		-- MonsterNecromancerRaisable
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonBowLightning3"] = {
	name = "Flayed Archer",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterLightningArrow",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterFiresLightningArrowsText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonCasterColdMultipleProjectiles"] = {
	name = "Frost Harbinger",
	life = 0.84,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 40,
	lightningResist = 0,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.605,
	skillList = {
		"SkeletonProjectileCold",
	},
	modList = {
		mod("ProjectileCount", "BASE", 2), -- MonsterMultipleProjectilesImplicit1
		-- MonsterNecromancerRaisable
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonCasterFireMultipleProjectiles2"] = {
	name = "Incinerated Mage",
	life = 0.84,
	energyShield = 0.4,
	fireResist = 40,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.605,
	skillList = {
		"SkeletonProjectileFire",
	},
	modList = {
		-- MonsterNecromancerRaisable
		mod("ProjectileCount", "BASE", 2), -- MonsterMultipleProjectilesImplicit1
		-- ImmuneToLavaDamage
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonBowPoison"] = {
	name = "Plagued Bowman",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterCausticArrow",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterFiresCausticArrowsText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonBowLightning2"] = {
	name = "Restless Archer",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterLightningArrow",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterFiresLightningArrowsText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonBowLightning4"] = {
	name = "Sin Archer",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterLightningArrow",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterFiresLightningArrowsText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonCasterLightningSpark"] = {
	name = "Sparking Mage",
	life = 0.84,
	energyShield = 0.4,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.605,
	skillList = {
		"SkeletonProjectileLightning",
		"SkeletonSpark",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterCastsSparkText
	},
}
minions["Metadata/Monsters/Skeletons/SkeletonBowProjectileWeaknessCurse"] = {
	name = "Vexing Archer",
	life = 0.96,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 1.6,
	damageSpread = 0.2,
	attackTime = 1.995,
	weaponType1 = "Bow",
	skillList = {
		"Melee",
		"MonsterProjectileWeakness",
	},
	modList = {
		-- MonsterNecromancerRaisable
		-- MonsterCastsProjectileWeaknessCurseText
	},
}
-- Snake
minions["Metadata/Monsters/Snake/SnakeScorpionMultiShot"] = {
	name = "Barb Serpent",
	life = 0.94,
	fireResist = 30,
	coldResist = 0,
	lightningResist = 0,
	chaosResist = 30,
	damage = 1.75,
	damageSpread = 0.2,
	attackTime = 1.65,
	skillList = {
		"Melee",
		"SnakeSpineProjectile",
	},
	modList = {
		mod("PhysicalDamageConvertToChaos", "BASE", 30), -- MonsterSnakeChaos
		mod("ProjectileCount", "BASE", 2), -- MonsterMultipleProjectilesImplicit1
	},
}
-- Spider
minions["Metadata/Monsters/Spiders/SpiderThornFlickerStrike"] = {
	name = "Leaping Spider",
	life = 1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.44,
	skillList = {
		"Melee",
		"MonsterFlickerStrike",
	},
	modList = {
		-- MonsterUsesFlickerStrikeText
	},
}
-- Undying
minions["Metadata/Monsters/Undying/CityStalkerMaleCasterArmour"] = {
	name = "Undying Evangelist",
	life = 1.2,
	fireResist = 37,
	coldResist = 37,
	lightningResist = 37,
	chaosResist = 0,
	damage = 2.2,
	damageSpread = 0.2,
	attackTime = 1.245,
	skillList = {
		"Melee",
		"DelayedBlast",
		"MonsterProximityShield",
		"DelayedBlastSpectre",
	},
	modList = {
	},
}
minions["Metadata/Monsters/Undying/UndyingOutcastPuncture"] = {
	name = "Undying Impaler",
	life = 1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.65,
	skillList = {
		"Melee",
		"MonsterPuncture",
	},
	modList = {
		-- MonsterCastsPunctureText
	},
}
minions["Metadata/Monsters/Undying/UndyingOutcastWhirlingBlades"] = {
	name = "Undying Outcast",
	life = 1,
	fireResist = 0,
	coldResist = 0,
	lightningResist = 40,
	chaosResist = 0,
	damage = 2,
	damageSpread = 0.2,
	attackTime = 1.65,
	skillList = {
		"Melee",
		"UndyingWhirlingBlades",
	},
	modList = {
	},
}
