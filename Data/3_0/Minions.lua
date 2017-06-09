-- Path of Building
--
-- Minion Data
-- Monster data (c) Grinding Gear Games
--
local minions, mod = ...

minions["RaisedZombie"] = {
	name = "Raised Zombie",
	life = 2.55,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 2.19,
	damageSpread = 0.4,
	attackTime = 1.755,
	attackRange = 9,
	damageFixup = 0.33,
	limit = "ActiveZombieLimit",
	skillList = {
		"Melee",
		"ZombieSlam",
	},
	modList = {
		mod("Armour", "INC", 40),
	},
}
minions["SummonedChaosGolem"] = {
	name = "Chaos Golem",
	life = 4.8,
	energyShield = 0.2,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 60,
	damage = 2.48,
	damageSpread = 0.2,
	attackTime = 1.5,
	attackRange = 6,
	damageFixup = 0.22,
	limit = "ActiveGolemLimit",
	skillList = {
		"Melee",
		"ChaosElementalCascadeSummoned",
		"SandstormChaosElementalSummoned",
	},
	modList = {
	},
}
minions["SummonedFlameGolem"] = {
	name = "Flame Golem",
	life = 3.75,
	energyShield = 0.4,
	fireResist = 70,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.5,
	damageSpread = 0.2,
	attackTime = 1.5,
	attackRange = 4,
	damageFixup = 0.22,
	limit = "ActiveGolemLimit",
	skillList = {
		"FireElementalFlameRedSummoned",
		"FireElementalMortarSummoned",
		"FireElementalConeSummoned",
	},
	modList = {
	},
}
minions["SummonedIceGolem"] = {
	name = "Ice Golem",
	life = 4.05,
	energyShield = 0.4,
	fireResist = 40,
	coldResist = 70,
	lightningResist = 40,
	chaosResist = 20,
	damage = 3.06,
	damageSpread = 0.2,
	attackTime = 1.275,
	attackRange = 4,
	damageFixup = 0.33,
	limit = "ActiveGolemLimit",
	skillList = {
		"Melee",
		"IceElementalIceCyclone",
		"IceElementalSpearSummoned",
	},
	modList = {
	},
}
minions["SummonedLightningGolem"] = {
	name = "Lightning Golem",
	life = 3.75,
	energyShield = 0.2,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 70,
	chaosResist = 20,
	damage = 1.5,
	damageSpread = 0.2,
	attackTime = 1.755,
	attackRange = 6,
	damageFixup = 0.22,
	limit = "ActiveGolemLimit",
	skillList = {
		"LightningGolemArcSummoned",
		"MonsterProjectileSpellLightningGolemSummoned",
		"LightningGolemWrath",
	},
	modList = {
	},
}
minions["SummonedStoneGolem"] = {
	name = "Stone Golem",
	life = 5.25,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 3,
	damageSpread = 0.2,
	attackTime = 1.5,
	attackRange = 6,
	weaponType1 = "One Handed Sword",
	limit = "ActiveGolemLimit",
	skillList = {
		"Melee",
		"RockGolemSlam",
		"RockGolemWhirlingBlades",
	},
	modList = {
	},
}
minions["SummonedRagingSpirit"] = {
	name = "Raging Spirit",
	life = 1.8,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.2,
	damageSpread = 0.2,
	attackTime = 0.855,
	attackRange = 6,
	limit = "ActiveRagingSpiritLimit",
	skillList = {
		"Melee",
	},
	modList = {
		mod("PhysicalDamageConvertToFire", "BASE", 50),
		mod("PhysicalMin", "BASE", 4, ModFlag.Attack),
		mod("PhysicalMax", "BASE", 5, ModFlag.Attack),
		mod("Speed", "MORE", 40, ModFlag.Attack),
	},
}
minions["SummonedEssenceSpirit"] = {
	name = "Essence Spirit",
	life = 1.8,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 0.77,
	damageSpread = 0.2,
	attackTime = 0.855,
	attackRange = 6,
	skillList = {
		"RagingSpiritMeleeAttack",
		"SpectralSkullShieldCharge",
	},
	modList = {
		mod("Speed", "MORE", 40, ModFlag.Attack),
	},
}
minions["SummonedSpectralWolf"] = {
	name = "Spectral Wolf Companion",
	life = 4.5,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.5,
	damageSpread = 0.2,
	attackTime = 1.5,
	attackRange = 9,
	weaponType1 = "Dagger",
	limit = "ActiveWolfLimit",
	skillList = {
		"Melee",
	},
	modList = {
	},
}
minions["RaisedSkeleton"] = {
	name = "Summoned Skeleton",
	life = 1.05,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 4.05,
	damageSpread = 0.4,
	attackTime = 1.2,
	attackRange = 6,
	damageFixup = 0.33,
	weaponType1 = "One Handed Sword",
	weaponType2 = "Shield",
	limit = "ActiveSkeletonLimit",
	skillList = {
		"Melee",
	},
	modList = {
	},
}
minions["RaisedSkeletonCaster"] = {
	name = "Summoned Skeleton Caster",
	life = 1.05,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 0.98,
	damageSpread = 0.3,
	attackTime = 1.605,
	attackRange = 46,
	damageFixup = 0.33,
	limit = "ActiveSkeletonLimit",
	skillList = {
		"SkeletonProjectileFire",
		"SkeletonProjectileCold",
		"SkeletonProjectileLightning",
	},
	modList = {
	},
}
minions["RaisedSkeletonArcher"] = {
	name = "Summoned Skeleton Archer",
	life = 1.05,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 0.98,
	damageSpread = 0.16,
	attackTime = 1.995,
	attackRange = 40,
	damageFixup = 0.33,
	weaponType1 = "Bow",
	limit = "ActiveSkeletonLimit",
	skillList = {
		"Melee",
	},
	modList = {
	},
}
minions["Clone"] = {
	name = "Clone",
	life = 1,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1,
	damageSpread = 0,
	attackTime = 1.245,
	attackRange = 4,
	skillList = {
		"Melee",
	},
	modList = {
		mod("EnergyShield", "BASE", 10),
		mod("SkillData", "LIST", { key = "attackRateCap", value = 1.84 }),
	},
}
minions["SpiderMinion"] = {
	name = "Spider Minion",
	life = 1.8,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.32,
	damageSpread = 0.2,
	attackTime = 1.44,
	attackRange = 3,
	weaponType1 = "One Handed Sword",
	limit = "ActiveSpiderLimit",
	skillList = {
		"Melee",
		"SpiderMinionLeapSlam",
	},
	modList = {
	},
}