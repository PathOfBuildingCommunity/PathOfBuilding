-- Path of Building
--
-- Minion Data
-- Monster data (c) Grinding Gear Games
--
local minions, mod = ...

minions["RaisedZombie"] = {
	name = "Zombie",
	life = 2.55,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.75,
	damageSpread = 0.4,
	attackTime = 1.17,
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
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 60,
	energyShield = 0.2,
	damage = 3.48,
	damageSpread = 0.2,
	attackTime = 1.5,
	limit = "ActiveGolemLimit",
	skillList = {
		"Melee",
		"ChaosElementalCascadeSummoned",
		"SandstormChaosElementalSummoned",
	},
	modList = {
		mod("Damage", "MORE", -22),
		mod("Speed", "MORE", 22),
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
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.5,
	limit = "ActiveGolemLimit",
	skillList = {
		"FireElementalFlameRedSummoned",
		"FireElementalMortarSummoned",
		"FireElementalConeSummoned",
	},
	modList = {
		mod("Damage", "MORE", -33),
		mod("Speed", "MORE", 33),
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
	damage = 4.06,
	damageSpread = 0.2,
	attackTime = 1.275,
	limit = "ActiveGolemLimit",
	skillList = {
		"Melee",
		"IceElementalIceCyclone",
		"IceElementalSpearSummoned",
	},
	modList = {
		mod("Damage", "MORE", -33),
		mod("Speed", "MORE", 33),
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
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.755,
	limit = "ActiveGolemLimit",
	skillList = {
		"LightningGolemArcSummoned",
		"MonsterProjectileSpellLightningGolemSummoned",
		"LightningGolemWrath",
	},
	modList = {
		mod("Damage", "MORE", -22),
		mod("Speed", "MORE", 22),
	},
}
minions["SummonedStoneGolem"] = {
	name = "Stone Golem",
	life = 5.25,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 4,
	damageSpread = 0.2,
	attackTime = 1.5,
	weaponType1 = "One Handed Sword",
	limit = "ActiveGolemLimit",
	skillList = {
		"Melee",
		"RockGolemSlam",
		"RockGolemWhirlingBlades",
	},
	modList = {
		mod("Damage", "MORE", -33),
		mod("Speed", "MORE", 33),
	},
}
minions["SummonedRagingSpirit"] = {
	name = "Raging Spirit",
	life = 1.8,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 0.66,
	damageSpread = 0.2,
	attackTime = 0.855,
	limit = "ActiveRagingSpiritLimit",
	skillList = {
		"PlayerRagingSpiritMeleeAttack",
	},
	modList = {
		mod("PhysicalMin", "BASE", 4),
		mod("PhysicalMax", "BASE", 5),
		mod("PhysicalDamageConvertToFire", "BASE", 50),
		mod("Speed", "MORE", 40, ModFlag.Attack),
	},
}
minions["SummonedSpectralWolf"] = {
	name = "Spectral Wolf",
	life = 4.5,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 2.5,
	damageSpread = 0.2,
	attackTime = 1.5,
	limit = "ActiveWolfLimit",
	skillList = {
		"Melee",
	},
	modList = {
	},
}
minions["RaisedSkeleton"] = {
	name = "Skeleton Warrior",
	life = 1.05,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.49,
	damageSpread = 0.4,
	attackTime = 0.87,
	weaponType1 = "One Handed Sword",
	limit = "ActiveSkeletonLimit",
	skillList = {
		"Melee",
	},
	modList = {
	},
}
minions["RaisedSkeletonCaster"] = {
	name = "Skeleton Mage",
	life = 1.05,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.98,
	damageSpread = 0.3,
	attackTime = 1.605,
	limit = "ActiveSkeletonLimit",
	skillList = {
		"SkeletonProjectileFire",
		"SkeletonProjectileCold",
		"SkeletonProjectileLightning",
	},
	modList = {
		mod("Damage", "MORE", -33),
		mod("Speed", "MORE", 33),
	},
}
minions["RaisedSkeletonArcher"] = {
	name = "Skeleton Archer",
	life = 1.05,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 1.98,
	damageSpread = 0.16,
	attackTime = 1.995,
	weaponType1 = "Bow",
	limit = "ActiveSkeletonLimit",
	skillList = {
		"Melee",
	},
	modList = {
		mod("Damage", "MORE", -33),
		mod("Speed", "MORE", 33),
	},
}
minions["Clone"] = {
	name = "Clone",
	life = 1,
	fireResist = 40,
	coldResist = 40,
	lightningResist = 40,
	chaosResist = 20,
	damage = 2,
	damageSpread = 0,
	attackTime = 1.425,
	skillList = {
		"Melee",
	},
	modList = {
		mod("EnergyShield", "BASE", 10),
	},
}