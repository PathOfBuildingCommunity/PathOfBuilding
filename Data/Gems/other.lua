-- Path of Building
--
-- Other active skills
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
		mod("Speed", "INC", 5, ModFlag.Cast), --"base_cast_speed_+%" = 5
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
		mod("Speed", "INC", 3, ModFlag.Cast), --"base_cast_speed_+%" = 3
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
gems["Abberath's Fury"] = {
	hidden = true,
	color = 4,
	baseFlags = {
		spell = true,
		area = true,
	},
	skillTypes = { [11] = true, [36] = true, [42] = true, [2] = true, [10] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 5), 
		skill("FireMin", 50), --"spell_minimum_base_fire_damage" = 50
		skill("FireMax", 75), --"spell_maximum_base_fire_damage" = 75
		mod("EnemyIgniteChance", "BASE", 10), --"base_chance_to_ignite_%" = 10
		--"cast_on_gain_skill" = ?
		--"cannot_knockback" = ?
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
		--"is_area_damage" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[7] = { },
	},
}
gems["Bone Nova"] = {
	hidden = true,
	color = 4,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [10] = true, [57] = true, [47] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("ProjectileCount", "BASE", 8), --"number_of_additional_projectiles" = 8
		--"attack_trigger_on_killing_bleeding_enemy_%" = 100
		--"monster_projectile_variation" = 15
		--"projectiles_nova" = ?
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
		--"base_is_projectile" = ?
		flag("CannotBleed"), --"cannot_cause_bleeding" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[20] = { },
	},
}
gems["Envy"] = {
	hidden = true,
	color = 3,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		chaos = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [50] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 50), 
		mod("ChaosMin", "BASE", 58, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_minimum_added_chaos_damage" = 58
		mod("ChaosMax", "BASE", 81, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_maximum_added_chaos_damage" = 81
		mod("AreaRadius", "INC", 0), --"base_skill_area_of_effect_+%" = 0
		mod("ChaosMin", "BASE", 52, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"spell_minimum_added_chaos_damage" = 52
		mod("ChaosMax", "BASE", 69, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"spell_maximum_added_chaos_damage" = 69
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[15] = { },
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
gems["Lightning Bolt"] = {
	hidden = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [42] = true, [35] = true, [11] = true, [10] = true, [45] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 6), 
		--"cast_on_crit_%" = 100
		--"is_area_damage" = ?
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
		[1] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[2] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 10, 29, },
		[2] = { 11, 33, },
		[3] = { 14, 41, },
		[4] = { 18, 54, },
		[5] = { 25, 75, },
		[6] = { 36, 109, },
		[7] = { 47, 141, },
		[8] = { 60, 180, },
		[9] = { 76, 227, },
		[10] = { 94, 282, },
		[11] = { 116, 348, },
		[12] = { 142, 426, },
		[13] = { 173, 518, },
		[14] = { 209, 626, },
		[15] = { 251, 754, },
		[16] = { 301, 903, },
		[17] = { 359, 1078, },
		[18] = { 428, 1283, },
		[19] = { 486, 1459, },
		[20] = { 552, 1657, },
		[21] = { 601, 1802, },
		[22] = { 653, 1959, },
		[23] = { 709, 2127, },
		[24] = { 770, 2310, },
		[25] = { 835, 2506, },
		[26] = { 906, 2718, },
		[27] = { 982, 2946, },
		[28] = { 1064, 3192, },
		[29] = { 1153, 3458, },
		[30] = { 1248, 3743, },
	},
}
gems["Molten Burst"] = {
	hidden = true,
	color = 1,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		fire = true,
	},
	skillTypes = { [3] = true, [1] = true, [11] = true, [33] = true, [57] = true, [47] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("ProjectileCount", "BASE", 2), --"number_of_additional_projectiles" = 2
		--"attack_trigger_on_melee_hit_%" = 20
		--"show_number_of_projectiles" = ?
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[16] = { },
	},
}
