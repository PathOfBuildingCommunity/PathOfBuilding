-- Path of Building
--
-- Active Strength skills
-- Skill gem data (c) Grinding Gear Games
--
local gems, mod, flag, skill = ...

gems["_default"] = {
	hidden = true,
	color = 4,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [6] = true, [3] = true, [25] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"skill_can_fire_arrows" = 1
		--"skill_can_fire_wand_projectiles" = 1
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[1] = { },
	},
}
gems["Detonate Mines"] = {
	low_max_level = true,
	active_skill = true,
	spell = true,
	color = 4,
	baseFlags = {
		spell = true,
	},
	skillTypes = { [2] = true, [17] = true, [18] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.2), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 5, ModFlag.Spell), --"base_cast_speed_+%" = 5
	},
	levelMods = {
	},
	levels = {
		[1] = { },
		[2] = { },
		[3] = { },
		[4] = { },
		[5] = { },
		[6] = { },
		[7] = { },
		[8] = { },
		[9] = { },
		[10] = { },
	},
}
gems["Portal"] = {
	low_max_level = true,
	active_skill = true,
	spell = true,
	color = 4,
	baseFlags = {
		spell = true,
	},
	skillTypes = { [2] = true, [17] = true, [18] = true, [19] = true, [36] = true, [27] = true, },
	baseMods = {
		skill("castTime", 2.5), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 3, ModFlag.Spell), --"base_cast_speed_+%" = 3
	},
	levelMods = {
	},
	levels = {
		[1] = { },
		[2] = { },
		[3] = { },
		[4] = { },
		[5] = { },
		[6] = { },
		[7] = { },
		[8] = { },
		[9] = { },
		[10] = { },
	},
}
gems["Gluttony of Elements"] = {
	hidden = true,
	color = 4,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [5] = true, [11] = true, [12] = true, [18] = true, [43] = true, [44] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("duration", 6), --"base_skill_effect_duration" = 6000
		--"base_elemental_damage_heals" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[20] = { },
	},
}
gems["Icestorm"] = {
	hidden = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 22), 
		skill("damageEffectiveness", 0.3), 
		skill("critChance", 5), 
		skill("ColdMin", 1, { type = "PerStat", stat = "Int", div = 10 }), --"spell_minimum_base_cold_damage_+_per_10_intelligence" = 1
		skill("ColdMax", 3, { type = "PerStat", stat = "Int", div = 10 }), --"spell_maximum_base_cold_damage_+_per_10_intelligence" = 3
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		--"fire_storm_fireball_delay_ms" = 100
		--"skill_override_pvp_scaling_time_ms" = 450
		--"firestorm_drop_ground_ice_duration_ms" = 500
		--"skill_art_variation" = 4
		--"skill_effect_duration_per_100_int" = 150
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_area_damage" = ?
		skill("duration", 0.15, { type = "PerStat", stat = "Int", div = 100, base = 1.5 }), 
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[1] = { },
	},
}
gems["Illusory Warp"] = {
	hidden = true,
	color = 4,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		movement = true,
		cold = true,
	},
	skillTypes = { [2] = true, [38] = true, [12] = true, [34] = true, [11] = true, },
	baseMods = {
		skill("castTime", 0.6), 
		skill("manaCost", 20), 
		skill("duration", 5), --"base_skill_effect_duration" = 5000
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[20] = { },
	},
}
