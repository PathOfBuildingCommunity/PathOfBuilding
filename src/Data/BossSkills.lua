-- These are hardcoded estimates but should really be exported
-- damage mult is level 84 damage divided by 822, maximum has minimum subtracted from it and is divided by 100
-- math is included for damage mults because not exported and calculated by hand so easier to update/fix

return {
	-- poeDB AtziriFlameblastEmpowered
	["Atziri Flameblast"] = {
		DamageType = "Spell",
		DamageMultipliers = {
			Fire = { 2.945 * 10.9, (4.418 - 2.945) * 10.9 / 100 }
		},
		DamagePenetrations = {
			FirePen = ""
		},
		UberDamagePenetrations = {
			FirePen = 10
		},
		speed = 2500 * 10,
		critChance = 0,
		earlierUber = true,
		tooltip = "The Uber variant has 10 "..colourCodes.FIRE.."Fire^7 penetration (Applied on Pinnacle And Uber)"
	},
	-- poeDB AtlasBossAcceleratingProjectiles
	["Shaper Ball"] = {
		DamageType = "SpellProjectile",
		DamageMultipliers = {
			Cold = { 6.86, (10.29 - 6.86) / 100 }
		},
		DamagePenetrations = {
			ColdPen = 25
		},
		UberDamagePenetrations = {
			ColdPen = 40
		},
		speed = 1400,
		tooltip = "Allocating Cosmic Wounds increases the penetration to 40% (Applied on Uber) and adds 2 projectiles"
	},
	-- poeDB AtlasBossFlickerSlam
	["Shaper Slam"] = {
		DamageType = "Melee",
		DamageMultipliers = {
			Physical = { 3.617 * 3, (5.425 - 3.617) * 3 / 100 }
		},
		UberDamageMultiplier = 2.0,
		speed = 3510,
		critChance = 1, -- actually 0.5% but not enough precision
		tooltip = "Cannot be Evaded.  Allocating Cosmic Wounds increases Damage by a further 100% (Applied on Uber) and cannot be blocked or dodged"
	},
	-- skill missing, using shaper slam
	["Elder Slam"] = {
		DamageType = "Melee",
		DamageMultipliers = {
			Physical = { 3.617 * 3, (5.425 - 3.617) * 3 / 100 }
		},
		UberDamageMultiplier = 2.0,
		speed = 3510,
		critChance = 1, -- actually 0.5% but not enough precision
		tooltip = "SKILL CURRENTLY MISSING, USING SHAPER SLAM"
	},
	-- poeDB AtlasExileOrionCircleMazeBlast3
	["Sirus Meteor"] = {
		DamageType = "Spell",
		DamageMultipliers = {
			--base phys converted 25% each
			Physical = { 26.512 / 4, (39.768 - 26.512) / 4 / 100 },
			Lightning = { 26.512 / 4, (39.768 - 26.512) / 4 / 100 },
			Fire = { 26.512 / 4, (39.768 - 26.512) / 4 / 100 },
			Chaos = { 26.512 / 4, (39.768 - 26.512) / 4 / 100 }
		},
		UberDamageMultiplier = 1.5,
		tooltip = "Earlier ones with less walls do less damage. Allocating The Perfect Storm increases Damage by a further 50% (Applied on Uber)"
	},
	-- poeDB CleansingFireWall
	["Exarch Ball"] = {
		DamageType = "SpellProjectile",
		DamageMultipliers = {
			Fire = { 8.664, (12.996 - 8.664) / 100 }
		},
		speed = 1000,
		critChance = 0,
		tooltip = "Spawns 8-18 waves of balls depending on which fight and which ball phase"
	},
	-- poeDB GSConsumeBossDisintegrateBeam
	["Eater Beam"] = {
		DamageType = "Spell",
		DamageMultipliers = {
			Lightning = { 7.074, (21.224 - 7.074) / 100 }
		},
		speed = 1000,
		critChance = 0,
		tooltip = "Allocating Insatiable Appetite causes the beam to always shock for at least 30%"
	},
	-- poeDB MavenSuperFireProjectileImpact
	["Maven Fireball"] = {
		DamageType = "SpellProjectile",
		DamageMultipliers = {
			Fire = { 7.546, (11.319 - 7.546) / 100 }
		},
		UberDamageMultiplier = 2.0,
		DamagePenetrations = {
			FirePen = ""
		},
		UberDamagePenetrations = {
			FirePen = 30
		},
		speed = 3000,
		critChance = 0,
		tooltip = "Allocating Throw the Gauntlet increases Damage by a further 100% (Applied on Uber) and causes the fireball to have 30 "..colourCodes.FIRE.."Fire^7 penetration (Applied on Uber)"
	},
	-- poeDB MavenMemoryGame
	["Maven Memory Game"] = {
		DamageType = "Melee",
		DamageMultipliers = {
			--base phys converted 33.33% each
			Lightning = { 51.790 / 3, (77.685 - 51.790) / 3 / 100 },
			Cold = { 51.790 / 3, (77.685 - 51.790) / 3 / 100 },
			Fire = { 51.790 / 3, (77.685 - 51.790) / 3 / 100 }
		},
		tooltip = "Is three separate hits, and has a large DoT effect.  Neither is taken into account here.  \n	i.e. Hits before death should be more than 3 to survive"
	}
}