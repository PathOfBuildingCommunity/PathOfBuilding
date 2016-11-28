-- Path of Building
--
-- Active Dexterity gems
-- Skill gem data (c) Grinding Gear Games
--
local gems, mod, flag, skill = ...

gems["Animate Weapon"] = {
	dexterity = true,
	active_skill = true,
	duration = true,
	minion = true,
	spell = true,
	unsupported = true,
}
gems["Arctic Armour"] = {
	dexterity = true,
	active_skill = true,
	spell = true,
	duration = true,
	cold = true,
	color = 2,
	baseFlags = {
		spell = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [5] = true, [18] = true, [12] = true, [15] = true, [27] = true, [34] = true, [16] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("manaCost", 25), 
		--"chill_enemy_when_hit_duration_ms" = 500
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		--[1] = "new_arctic_armour_physical_damage_taken_when_hit_+%_final"
		--[2] = "new_arctic_armour_fire_damage_taken_when_hit_+%_final"
		[3] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { -8, -8, 2.5, },
		[2] = { -8, -8, 2.6, },
		[3] = { -9, -8, 2.7, },
		[4] = { -9, -8, 2.8, },
		[5] = { -9, -9, 2.9, },
		[6] = { -9, -9, 3, },
		[7] = { -10, -9, 3.1, },
		[8] = { -10, -9, 3.2, },
		[9] = { -10, -10, 3.3, },
		[10] = { -10, -10, 3.4, },
		[11] = { -11, -10, 3.5, },
		[12] = { -11, -10, 3.6, },
		[13] = { -11, -11, 3.7, },
		[14] = { -11, -11, 3.8, },
		[15] = { -12, -11, 3.9, },
		[16] = { -12, -11, 4, },
		[17] = { -12, -12, 4.1, },
		[18] = { -12, -12, 4.2, },
		[19] = { -13, -12, 4.3, },
		[20] = { -13, -12, 4.4, },
		[21] = { -13, -13, 4.5, },
		[22] = { -13, -13, 4.6, },
		[23] = { -14, -13, 4.7, },
		[24] = { -14, -13, 4.8, },
		[25] = { -14, -14, 4.9, },
		[26] = { -14, -14, 5, },
		[27] = { -15, -14, 5.1, },
		[28] = { -15, -14, 5.2, },
		[29] = { -15, -15, 5.3, },
		[30] = { -15, -15, 5.4, },
	},
}
gems["Barrage"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [6] = true, [3] = true, [22] = true, [17] = true, [19] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("ProjectileCount", "BASE", 3), --"number_of_additional_projectiles" = 3
		--"skill_can_fire_arrows" = ?
		--"skill_can_fire_wand_projectiles" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 0.5, ModFlag.Projectile), --"projectile_damage_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 7, -50, },
		[2] = { 7, -49.4, },
		[3] = { 7, -48.8, },
		[4] = { 8, -48.2, },
		[5] = { 8, -47.6, },
		[6] = { 8, -47, },
		[7] = { 8, -46.4, },
		[8] = { 8, -45.8, },
		[9] = { 9, -45.2, },
		[10] = { 9, -44.6, },
		[11] = { 9, -44, },
		[12] = { 9, -43.4, },
		[13] = { 9, -42.8, },
		[14] = { 10, -42.2, },
		[15] = { 10, -41.6, },
		[16] = { 10, -41, },
		[17] = { 10, -40.4, },
		[18] = { 10, -39.8, },
		[19] = { 11, -39.2, },
		[20] = { 11, -38.6, },
		[21] = { 11, -38, },
		[22] = { 11, -37.4, },
		[23] = { 11, -36.8, },
		[24] = { 11, -36.2, },
		[25] = { 11, -35.6, },
		[26] = { 12, -35, },
		[27] = { 12, -34.4, },
		[28] = { 12, -33.8, },
		[29] = { 12, -33.2, },
		[30] = { 12, -32.6, },
	},
}
gems["Bear Trap"] = {
	trap = true,
	dexterity = true,
	active_skill = true,
	duration = true,
	cast = true,
	color = 2,
	baseFlags = {
		cast = true,
		trap = true,
		duration = true,
	},
	skillTypes = { [12] = true, [19] = true, [37] = true, [39] = true, [10] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 2), 
		skill("critChance", 5), 
		--"is_trap" = 1
		--"base_trap_duration" = 16000
		mod("MovementSpeed", "INC", -300, 0, 0, nil), --"base_movement_velocity_+%" = -300
		--"trap_override_pvp_scaling_time_ms" = 750
		--"base_skill_is_trapped" = ?
		--"display_skill_deals_secondary_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		skill("trapCooldown", 3), 
	},
	qualityMods = {
		mod("PhysicalDamage", "INC", 1), --"physical_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("PhysicalMin", nil), --"secondary_minimum_base_physical_damage"
		[3] = skill("PhysicalMax", nil), --"secondary_maximum_base_physical_damage"
	},
	levels = {
		[1] = { 11, 16, 22, },
		[2] = { 13, 20, 28, },
		[3] = { 15, 27, 38, },
		[4] = { 17, 35, 49, },
		[5] = { 20, 49, 69, },
		[6] = { 22, 67, 94, },
		[7] = { 24, 90, 126, },
		[8] = { 26, 119, 167, },
		[9] = { 28, 156, 218, },
		[10] = { 32, 202, 282, },
		[11] = { 35, 259, 363, },
		[12] = { 38, 331, 463, },
		[13] = { 39, 420, 587, },
		[14] = { 41, 530, 742, },
		[15] = { 42, 630, 881, },
		[16] = { 43, 746, 1045, },
		[17] = { 44, 883, 1236, },
		[18] = { 45, 1043, 1460, },
		[19] = { 46, 1230, 1721, },
		[20] = { 46, 1447, 2026, },
		[21] = { 47, 1613, 2258, },
		[22] = { 48, 1795, 2514, },
		[23] = { 49, 1998, 2797, },
		[24] = { 50, 2222, 3111, },
		[25] = { 50, 2470, 3458, },
		[26] = { 51, 2744, 3842, },
		[27] = { 52, 3047, 4266, },
		[28] = { 53, 3382, 4735, },
		[29] = { 54, 3753, 5254, },
		[30] = { 54, 4162, 5826, },
	},
}
gems["Blade Flurry"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	parts = {
		{
			name = "1 Stage",
		},
		{
			name = "6 Stages",
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [11] = true, [6] = true, [58] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 4), 
		mod("Speed", "MORE", 65, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = 65
		--"charged_attack_damage_per_stack_+%_final" = 20
		--"is_area_damage" = ?
		nil, --"base_skill_show_average_damage_instead_of_dps" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
		mod("Damage", "MORE", 20, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 1 }), 
		mod("Damage", "MORE", 120, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), 
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { -45, 0, },
		[2] = { -44.4, 1, },
		[3] = { -43.8, 2, },
		[4] = { -43.2, 3, },
		[5] = { -42.6, 4, },
		[6] = { -42, 5, },
		[7] = { -41.4, 6, },
		[8] = { -40.8, 7, },
		[9] = { -40.2, 8, },
		[10] = { -39.6, 9, },
		[11] = { -39, 10, },
		[12] = { -38.4, 11, },
		[13] = { -37.8, 12, },
		[14] = { -37.2, 13, },
		[15] = { -36.6, 14, },
		[16] = { -36, 15, },
		[17] = { -35.4, 16, },
		[18] = { -34.8, 17, },
		[19] = { -34.2, 18, },
		[20] = { -33.6, 19, },
		[21] = { -33, 20, },
		[22] = { -32.4, 21, },
		[23] = { -31.8, 22, },
		[24] = { -31.2, 23, },
		[25] = { -30.6, 24, },
		[26] = { -30, 25, },
		[27] = { -29.4, 26, },
		[28] = { -28.8, 27, },
		[29] = { -28.2, 28, },
		[30] = { -27.6, 29, },
	},
}
gems["Blade Vortex"] = {
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [18] = true, [26] = true, [36] = true, [27] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 0.3), 
		skill("critChance", 6), 
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"maximum_number_of_spinning_blades" = 20
		mod("AreaRadius", "INC", 0), --"base_skill_area_of_effect_+%" = 0
		--"extra_gore_chance_override_%" = 15
		--"is_area_damage" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
		--"action_ignores_crit_tracking" = ?
		skill("deliciouslyOverpowered", true), 
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[3] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
	},
	levels = {
		[1] = { 6, 9, 14, },
		[2] = { 7, 12, 17, },
		[3] = { 8, 15, 23, },
		[4] = { 9, 19, 29, },
		[5] = { 10, 24, 36, },
		[6] = { 11, 30, 45, },
		[7] = { 12, 37, 55, },
		[8] = { 13, 43, 64, },
		[9] = { 13, 50, 74, },
		[10] = { 14, 57, 86, },
		[11] = { 14, 66, 98, },
		[12] = { 15, 75, 113, },
		[13] = { 16, 86, 129, },
		[14] = { 16, 98, 147, },
		[15] = { 17, 111, 167, },
		[16] = { 18, 126, 190, },
		[17] = { 18, 137, 206, },
		[18] = { 19, 149, 224, },
		[19] = { 19, 162, 243, },
		[20] = { 19, 176, 264, },
		[21] = { 20, 191, 286, },
		[22] = { 21, 207, 310, },
		[23] = { 21, 224, 336, },
		[24] = { 21, 242, 363, },
		[25] = { 22, 262, 393, },
		[26] = { 23, 283, 425, },
		[27] = { 23, 306, 459, },
		[28] = { 23, 331, 496, },
		[29] = { 24, 357, 536, },
		[30] = { 24, 386, 579, },
	},
}
gems["Bladefall"] = {
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 2,
	baseFlags = {
		spell = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [17] = true, [19] = true, [18] = true, [10] = true, [36] = true, [26] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.9), 
		skill("critChance", 5), 
		--"bladefall_damage_per_stage_+%_final" = -6
		mod("AreaRadius", "INC", 0), --"base_skill_area_of_effect_+%" = 0
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[3] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
	},
	levels = {
		[1] = { 13, 44, 65, },
		[2] = { 14, 52, 78, },
		[3] = { 15, 62, 93, },
		[4] = { 16, 73, 110, },
		[5] = { 17, 86, 129, },
		[6] = { 18, 96, 144, },
		[7] = { 18, 107, 160, },
		[8] = { 19, 118, 177, },
		[9] = { 19, 131, 197, },
		[10] = { 20, 145, 218, },
		[11] = { 21, 160, 241, },
		[12] = { 21, 177, 266, },
		[13] = { 22, 195, 293, },
		[14] = { 22, 215, 323, },
		[15] = { 23, 237, 356, },
		[16] = { 24, 261, 392, },
		[17] = { 24, 287, 431, },
		[18] = { 25, 315, 473, },
		[19] = { 25, 346, 519, },
		[20] = { 26, 380, 570, },
		[21] = { 27, 417, 625, },
		[22] = { 27, 457, 685, },
		[23] = { 28, 500, 750, },
		[24] = { 28, 548, 821, },
		[25] = { 29, 599, 899, },
		[26] = { 30, 655, 983, },
		[27] = { 30, 716, 1074, },
		[28] = { 31, 782, 1174, },
		[29] = { 31, 854, 1282, },
		[30] = { 32, 933, 1399, },
	},
}
gems["Blast Rain"] = {
	fire = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		fire = true,
	},
	skillTypes = { [1] = true, [11] = true, [14] = true, [22] = true, [17] = true, [19] = true, [33] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("PhysicalDamageConvertToFire", "BASE", 50, 0, 0, nil), --"base_physical_damage_%_to_convert_to_fire" = 50
		--"blast_rain_number_of_blasts" = 4
		--"blast_rain_arrow_delay_ms" = 80
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 8, -60, 0, },
		[2] = { 8, -59.6, 1, },
		[3] = { 8, -59.2, 2, },
		[4] = { 8, -58.8, 3, },
		[5] = { 9, -58.4, 4, },
		[6] = { 9, -58, 5, },
		[7] = { 9, -57.6, 6, },
		[8] = { 9, -57.2, 7, },
		[9] = { 9, -56.8, 8, },
		[10] = { 9, -56.4, 9, },
		[11] = { 9, -56, 10, },
		[12] = { 10, -55.6, 11, },
		[13] = { 10, -55.2, 12, },
		[14] = { 10, -54.8, 13, },
		[15] = { 10, -54.4, 14, },
		[16] = { 10, -54, 15, },
		[17] = { 10, -53.6, 16, },
		[18] = { 10, -53.2, 17, },
		[19] = { 10, -52.8, 18, },
		[20] = { 10, -52.4, 19, },
		[21] = { 10, -52, 20, },
		[22] = { 10, -51.6, 21, },
		[23] = { 11, -51.2, 22, },
		[24] = { 11, -50.8, 23, },
		[25] = { 11, -50.4, 24, },
		[26] = { 11, -50, 25, },
		[27] = { 11, -49.6, 26, },
		[28] = { 12, -49.2, 27, },
		[29] = { 12, -48.8, 28, },
		[30] = { 12, -48.4, 29, },
	},
}
gems["Blink Arrow"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	minion = true,
	duration = true,
	movement = true,
	bow = true,
	unsupported = true,
}
gems["Blood Rage"] = {
	dexterity = true,
	active_skill = true,
	spell = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [18] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.25), 
		--"life_leech_from_physical_attack_damage_permyriad" = 120
		--"base_physical_damage_%_of_maximum_life_to_deal_per_minute" = 240
		--"base_physical_damage_%_of_maximum_energy_shield_to_deal_per_minute" = 240
		--"add_frenzy_charge_on_kill_%_chance" = 25
	},
	qualityMods = {
		mod("Speed", "INC", 0.25, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_speed_+%" = 0.25
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_speed_+%"
		[3] = skill("duration", nil), --"base_skill_effect_duration"
		--[4] = "skill_level"
	},
	levels = {
		[1] = { 17, 5, 7, 1, },
		[2] = { 17, 6, 7.2, 2, },
		[3] = { 17, 6, 7.4, 3, },
		[4] = { 18, 7, 7.6, 4, },
		[5] = { 18, 7, 7.8, 5, },
		[6] = { 18, 8, 8, 6, },
		[7] = { 18, 8, 8.2, 7, },
		[8] = { 19, 9, 8.4, 8, },
		[9] = { 19, 9, 8.6, 9, },
		[10] = { 19, 10, 8.8, 10, },
		[11] = { 20, 10, 9, 11, },
		[12] = { 20, 11, 9.2, 12, },
		[13] = { 20, 11, 9.4, 13, },
		[14] = { 20, 12, 9.6, 14, },
		[15] = { 20, 12, 9.8, 15, },
		[16] = { 21, 13, 10, 16, },
		[17] = { 21, 13, 10.2, 17, },
		[18] = { 21, 14, 10.4, 18, },
		[19] = { 21, 14, 10.6, 19, },
		[20] = { 21, 15, 10.8, 20, },
		[21] = { 22, 15, 11, 21, },
		[22] = { 22, 16, 11.2, 22, },
		[23] = { 22, 16, 11.4, 23, },
		[24] = { 22, 17, 11.6, 24, },
		[25] = { 22, 17, 11.8, 25, },
		[26] = { 23, 18, 12, 26, },
		[27] = { 23, 18, 12.2, 27, },
		[28] = { 23, 19, 12.4, 28, },
		[29] = { 23, 19, 12.6, 29, },
		[30] = { 23, 20, 12.8, 30, },
	},
}
gems["Burning Arrow"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	fire = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		fire = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [22] = true, [17] = true, [19] = true, [33] = true, [53] = true, [55] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("EnemyIgniteChance", "BASE", 20), --"base_chance_to_ignite_%" = 20
		mod("PhysicalDamageConvertToFire", "BASE", 50, 0, 0, nil), --"base_physical_damage_%_to_convert_to_fire" = 50
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("EnemyIgniteDuration", "INC", 3), --"ignite_duration_+%" = 3
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("FireDamage", "INC", nil, ModFlag.Dot), --"burn_damage_+%"
	},
	levels = {
		[1] = { 5, 50, 10, },
		[2] = { 5, 51.8, 11, },
		[3] = { 5, 53.6, 12, },
		[4] = { 5, 55.4, 13, },
		[5] = { 5, 57.2, 14, },
		[6] = { 6, 59, 15, },
		[7] = { 6, 60.8, 16, },
		[8] = { 6, 62.6, 17, },
		[9] = { 6, 64.4, 18, },
		[10] = { 6, 66.2, 19, },
		[11] = { 7, 68, 20, },
		[12] = { 7, 69.8, 21, },
		[13] = { 7, 71.6, 22, },
		[14] = { 7, 73.4, 23, },
		[15] = { 7, 75.2, 24, },
		[16] = { 8, 77, 25, },
		[17] = { 8, 78.8, 26, },
		[18] = { 8, 80.6, 27, },
		[19] = { 8, 82.4, 28, },
		[20] = { 8, 84.2, 29, },
		[21] = { 9, 86, 30, },
		[22] = { 9, 87.8, 31, },
		[23] = { 9, 89.6, 32, },
		[24] = { 9, 91.4, 33, },
		[25] = { 9, 93.2, 34, },
		[26] = { 10, 95, 35, },
		[27] = { 10, 96.8, 36, },
		[28] = { 10, 98.6, 37, },
		[29] = { 10, 100.4, 38, },
		[30] = { 10, 102.2, 39, },
	},
}
gems["Vaal Burning Arrow"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	area = true,
	fire = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		fire = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [22] = true, [17] = true, [19] = true, [11] = true, [43] = true, [33] = true, [55] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("EnemyIgniteChance", "BASE", 20), --"base_chance_to_ignite_%" = 20
		mod("PhysicalDamageConvertToFire", "BASE", 50, 0, 0, nil), --"base_physical_damage_%_to_convert_to_fire" = 50
		--"vaal_burning_arrow_explode_on_hit" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("EnemyIgniteDuration", "INC", 3), --"ignite_duration_+%" = 3
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("FireDamage", "INC", nil, ModFlag.Dot), --"burn_damage_+%"
	},
	levels = {
		[1] = { 60, 10, },
		[2] = { 62, 11, },
		[3] = { 64, 12, },
		[4] = { 66, 13, },
		[5] = { 68, 14, },
		[6] = { 70, 15, },
		[7] = { 72, 16, },
		[8] = { 74, 17, },
		[9] = { 76, 18, },
		[10] = { 78, 19, },
		[11] = { 80, 20, },
		[12] = { 82, 21, },
		[13] = { 84, 22, },
		[14] = { 86, 23, },
		[15] = { 88, 24, },
		[16] = { 90, 25, },
		[17] = { 92, 26, },
		[18] = { 94, 27, },
		[19] = { 96, 28, },
		[20] = { 98, 29, },
		[21] = { 100, 30, },
		[22] = { 102, 31, },
		[23] = { 104, 32, },
		[24] = { 106, 33, },
		[25] = { 108, 34, },
		[26] = { 110, 35, },
		[27] = { 112, 36, },
		[28] = { 114, 37, },
		[29] = { 116, 38, },
		[30] = { 118, 39, },
	},
}
gems["Caustic Arrow"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	duration = true,
	chaos = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [11] = true, [12] = true, [17] = true, [19] = true, [22] = true, [40] = true, [50] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"skill_can_fire_arrows" = 1
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
		[4] = mod("PhysicalDamageGainAsChaos", "BASE", nil, 0, 0, nil), --"physical_damage_%_to_add_as_chaos"
	},
	levels = {
		[1] = { 8, 2.8, 5.2, 30, },
		[2] = { 8, 2.9, 6.5166666666667, 31, },
		[3] = { 8, 3, 8.8333333333333, 32, },
		[4] = { 9, 3.1, 11.7, 33, },
		[5] = { 9, 3.2, 16.516666666667, 34, },
		[6] = { 9, 3.3, 22.75, 35, },
		[7] = { 10, 3.4, 30.766666666667, 36, },
		[8] = { 10, 3.5, 41.033333333333, 37, },
		[9] = { 10, 3.6, 54.116666666667, 38, },
		[10] = { 11, 3.7, 70.716666666667, 39, },
		[11] = { 11, 3.9, 91.683333333333, 40, },
		[12] = { 12, 4, 118.13333333333, 41, },
		[13] = { 12, 4.1, 151.35, 42, },
		[14] = { 13, 4.2, 192.96666666667, 43, },
		[15] = { 13, 4.3, 230.91666666667, 44, },
		[16] = { 14, 4.4, 275.7, 45, },
		[17] = { 14, 4.5, 328.55, 46, },
		[18] = { 15, 4.6, 390.81666666667, 47, },
		[19] = { 15, 4.7, 464.13333333333, 48, },
		[20] = { 16, 4.8, 550.33333333333, 49, },
		[21] = { 16, 5, 616.05, 50, },
		[22] = { 17, 5.1, 689.2, 51, },
		[23] = { 17, 5.2, 770.58333333333, 52, },
		[24] = { 18, 5.3, 861.11666666667, 53, },
		[25] = { 18, 5.4, 961.78333333333, 54, },
		[26] = { 19, 5.5, 1073.6833333333, 55, },
		[27] = { 19, 5.6, 1198.05, 56, },
		[28] = { 20, 5.7, 1336.2, 57, },
		[29] = { 20, 5.8, 1489.6166666667, 58, },
		[30] = { 21, 5.9, 1659.9833333333, 59, },
	},
}
gems["Cyclone"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	movement = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [24] = true, [38] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 12), 
		mod("Speed", "MORE", 50, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = 50
		mod("MovementSpeed", "MORE", -30), --"cyclone_movement_speed_+%_final" = -30
		--"base_skill_number_of_additional_hits" = 1
		--"cyclone_first_hit_damage_+%_final" = -50
		--"is_area_damage" = ?
		skill("dpsMultiplier", 2), 
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -55, },
		[2] = { -54.4, },
		[3] = { -53.8, },
		[4] = { -53.2, },
		[5] = { -52.6, },
		[6] = { -52, },
		[7] = { -51.4, },
		[8] = { -50.8, },
		[9] = { -50.2, },
		[10] = { -49.6, },
		[11] = { -49, },
		[12] = { -48.4, },
		[13] = { -47.8, },
		[14] = { -47.2, },
		[15] = { -46.6, },
		[16] = { -46, },
		[17] = { -45.4, },
		[18] = { -44.8, },
		[19] = { -44.2, },
		[20] = { -43.6, },
		[21] = { -43, },
		[22] = { -42.4, },
		[23] = { -41.8, },
		[24] = { -41.2, },
		[25] = { -40.6, },
		[26] = { -40, },
		[27] = { -39.4, },
		[28] = { -38.8, },
		[29] = { -38.2, },
		[30] = { -37.6, },
	},
}
gems["Vaal Cyclone"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	area = true,
	duration = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [24] = true, [12] = true, [43] = true, },
	baseMods = {
		skill("castTime", 1), 
		mod("Speed", "MORE", 100, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = 100
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"base_skill_number_of_additional_hits" = 1
		mod("AreaRadius", "INC", 50), --"base_skill_area_of_effect_+%" = 50
		--"is_area_damage" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -50, },
		[2] = { -49.4, },
		[3] = { -48.8, },
		[4] = { -48.2, },
		[5] = { -47.6, },
		[6] = { -47, },
		[7] = { -46.4, },
		[8] = { -45.8, },
		[9] = { -45.2, },
		[10] = { -44.6, },
		[11] = { -44, },
		[12] = { -43.4, },
		[13] = { -42.8, },
		[14] = { -42.2, },
		[15] = { -41.6, },
		[16] = { -41, },
		[17] = { -40.4, },
		[18] = { -39.8, },
		[19] = { -39.2, },
		[20] = { -38.6, },
		[21] = { -38, },
		[22] = { -37.4, },
		[23] = { -36.8, },
		[24] = { -36.2, },
		[25] = { -35.6, },
		[26] = { -35, },
		[27] = { -34.4, },
		[28] = { -33.8, },
		[29] = { -33.2, },
		[30] = { -32.6, },
	},
}
gems["Desecrate"] = {
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	chaos = true,
	color = 2,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [36] = true, [40] = true, [26] = true, [50] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"desecrate_number_of_corpses_to_create" = 3
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 1, ModFlag.Spell), --"base_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
		--[3] = "desecrate_corpse_level"
	},
	levels = {
		[1] = { 8, 8.1666666666667, 20, },
		[2] = { 8, 11.316666666667, 24, },
		[3] = { 9, 15.383333333333, 26, },
		[4] = { 9, 20.633333333333, 29, },
		[5] = { 10, 25.533333333333, 32, },
		[6] = { 11, 31.416666666667, 35, },
		[7] = { 12, 38.466666666667, 38, },
		[8] = { 12, 46.916666666667, 41, },
		[9] = { 13, 57.016666666667, 44, },
		[10] = { 14, 69.05, 47, },
		[11] = { 15, 83.4, 50, },
		[12] = { 16, 100.46666666667, 53, },
		[13] = { 17, 120.73333333333, 56, },
		[14] = { 18, 144.76666666667, 59, },
		[15] = { 18, 163.23333333333, 63, },
		[16] = { 18, 183.88333333333, 67, },
		[17] = { 19, 207, 71, },
		[18] = { 19, 232.83333333333, 75, },
		[19] = { 20, 261.71666666667, 100, },
		[20] = { 20, 294, 100, },
		[21] = { 21, 330.05, 100, },
		[22] = { 22, 370.3, 100, },
		[23] = { 22, 415.21666666667, 100, },
		[24] = { 22, 465.33333333333, 100, },
		[25] = { 23, 521.21666666667, 100, },
		[26] = { 23, 583.53333333333, 100, },
		[27] = { 24, 652.98333333333, 100, },
		[28] = { 25, 730.38333333333, 100, },
		[29] = { 25, 816.58333333333, 100, },
		[30] = { 26, 912.58333333333, 100, },
	},
}
gems["Detonate Dead"] = {
	dexterity = true,
	active_skill = true,
	cast = true,
	area = true,
	fire = true,
	unsupported = true,
}
gems["Vaal Detonate Dead"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	cast = true,
	area = true,
	fire = true,
	unsupported = true,
}
gems["Double Strike"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [25] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 5), 
		--"base_skill_number_of_additional_hits" = 1
		skill("dpsMultiplier", 2), 
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -30, },
		[2] = { -28.6, },
		[3] = { -27.2, },
		[4] = { -25.8, },
		[5] = { -24.4, },
		[6] = { -23, },
		[7] = { -21.6, },
		[8] = { -20.2, },
		[9] = { -18.8, },
		[10] = { -17.4, },
		[11] = { -16, },
		[12] = { -14.6, },
		[13] = { -13.2, },
		[14] = { -11.8, },
		[15] = { -10.4, },
		[16] = { -9, },
		[17] = { -7.6, },
		[18] = { -6.2, },
		[19] = { -4.8, },
		[20] = { -3.4, },
		[21] = { -2, },
		[22] = { -0.6, },
		[23] = { 0.8, },
		[24] = { 2.2, },
		[25] = { 3.6, },
		[26] = { 5, },
		[27] = { 6.4, },
		[28] = { 7.8, },
		[29] = { 9.2, },
		[30] = { 10.6, },
	},
}
gems["Vaal Double Strike"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	melee = true,
	duration = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [25] = true, [28] = true, [24] = true, [12] = true, [43] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_skill_number_of_additional_hits" = 1
		--"number_of_monsters_to_summon" = 1
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { -30, 3.6, },
		[2] = { -29.2, 3.7, },
		[3] = { -28.4, 3.8, },
		[4] = { -27.6, 3.9, },
		[5] = { -26.8, 4, },
		[6] = { -26, 4.1, },
		[7] = { -25.2, 4.2, },
		[8] = { -24.4, 4.3, },
		[9] = { -23.6, 4.4, },
		[10] = { -22.8, 4.5, },
		[11] = { -22, 4.6, },
		[12] = { -21.2, 4.7, },
		[13] = { -20.4, 4.8, },
		[14] = { -19.6, 4.9, },
		[15] = { -18.8, 5, },
		[16] = { -18, 5.1, },
		[17] = { -17.2, 5.2, },
		[18] = { -16.4, 5.3, },
		[19] = { -15.6, 5.4, },
		[20] = { -14.8, 5.5, },
		[21] = { -14, 5.6, },
		[22] = { -13.2, 5.7, },
		[23] = { -12.4, 5.8, },
		[24] = { -11.6, 5.9, },
		[25] = { -10.8, 6, },
		[26] = { -10, 6.1, },
		[27] = { -9.2, 6.2, },
		[28] = { -8.4, 6.3, },
		[29] = { -7.6, 6.4, },
		[30] = { -6.8, 6.5, },
	},
}
gems["Dual Strike"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	unsupported = true,
}
gems["Elemental Hit"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	fire = true,
	cold = true,
	lightning = true,
	bow = true,
	parts = {
		{
			name = "Added fire",
		},
		{
			name = "Added cold",
		},
		{
			name = "Added lightning",
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		cold = true,
		fire = true,
		lightning = true,
	},
	skillTypes = { [1] = true, [6] = true, [3] = true, [22] = true, [17] = true, [19] = true, [25] = true, [28] = true, [24] = true, [33] = true, [34] = true, [35] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"chance_to_freeze_shock_ignite_%" = 10
		--"skill_can_fire_arrows" = ?
		--"skill_can_fire_wand_projectiles" = ?
		mod("EnemyFreezeChance", "BASE", 10), 
		mod("EnemyShockChance", "BASE", 10), 
		mod("EnemyIgniteChance", "BASE", 10), 
	},
	qualityMods = {
		mod("ElementalDamage", "INC", 1), --"elemental_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("FireMin", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 1 }), --"attack_minimum_base_fire_damage_for_elemental_hit"
		[3] = mod("FireMax", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 1 }), --"attack_maximum_base_fire_damage_for_elemental_hit"
		[4] = mod("ColdMin", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"attack_minimum_base_cold_damage_for_elemental_hit"
		[5] = mod("ColdMax", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"attack_maximum_base_cold_damage_for_elemental_hit"
		[6] = mod("LightningMin", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 3 }), --"attack_minimum_base_lightning_damage_for_elemental_hit"
		[7] = mod("LightningMax", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 3 }), --"attack_maximum_base_lightning_damage_for_elemental_hit"
	},
	levels = {
		[1] = { 6, 4, 8, 3, 6, 1, 13, },
		[2] = { 6, 5, 9, 4, 7, 1, 14, },
		[3] = { 6, 6, 11, 5, 9, 1, 17, },
		[4] = { 7, 7, 14, 6, 11, 1, 23, },
		[5] = { 7, 10, 19, 8, 16, 2, 31, },
		[6] = { 7, 14, 27, 12, 22, 2, 44, },
		[7] = { 8, 18, 34, 15, 28, 3, 56, },
		[8] = { 8, 23, 43, 19, 35, 4, 70, },
		[9] = { 8, 28, 53, 23, 43, 5, 87, },
		[10] = { 9, 35, 64, 28, 53, 6, 106, },
		[11] = { 9, 42, 78, 34, 64, 7, 128, },
		[12] = { 9, 50, 93, 41, 76, 8, 153, },
		[13] = { 10, 60, 111, 49, 91, 10, 183, },
		[14] = { 10, 71, 132, 58, 108, 11, 217, },
		[15] = { 10, 84, 156, 69, 127, 13, 256, },
		[16] = { 11, 99, 183, 81, 150, 16, 301, },
		[17] = { 11, 115, 214, 94, 175, 19, 352, },
		[18] = { 11, 135, 250, 110, 205, 22, 411, },
		[19] = { 11, 151, 280, 123, 229, 24, 461, },
		[20] = { 12, 169, 314, 138, 257, 27, 516, },
		[21] = { 12, 182, 338, 149, 276, 29, 555, },
		[22] = { 12, 196, 364, 160, 297, 31, 598, },
		[23] = { 12, 211, 391, 172, 320, 34, 643, },
		[24] = { 13, 226, 420, 185, 344, 36, 691, },
		[25] = { 13, 243, 452, 199, 370, 39, 743, },
		[26] = { 13, 261, 485, 214, 397, 42, 798, },
		[27] = { 13, 281, 521, 230, 426, 45, 857, },
		[28] = { 14, 301, 559, 246, 457, 48, 919, },
		[29] = { 14, 323, 600, 264, 491, 52, 986, },
		[30] = { 14, 346, 643, 283, 526, 56, 1057, },
	},
}
gems["Ethereal Knives"] = {
	projectile = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	color = 2,
	baseFlags = {
		spell = true,
		projectile = true,
	},
	skillTypes = { [2] = true, [10] = true, [3] = true, [18] = true, [17] = true, [19] = true, [26] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.6), 
		skill("critChance", 6), 
		mod("ProjectileCount", "BASE", 9), --"number_of_additional_projectiles" = 9
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("ProjectileSpeed", "INC", 1), --"base_projectile_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[3] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
		[4] = mod("ProjectileSpeed", "INC", nil), --"base_projectile_speed_+%"
	},
	levels = {
		[1] = { 5, 4, 6, 0, },
		[2] = { 6, 5, 7, 1, },
		[3] = { 7, 6, 9, 2, },
		[4] = { 8, 8, 12, 3, },
		[5] = { 9, 12, 18, 4, },
		[6] = { 10, 18, 27, 5, },
		[7] = { 11, 24, 37, 6, },
		[8] = { 12, 32, 49, 7, },
		[9] = { 13, 42, 64, 8, },
		[10] = { 14, 55, 82, 9, },
		[11] = { 16, 70, 105, 10, },
		[12] = { 17, 89, 134, 11, },
		[13] = { 18, 112, 169, 12, },
		[14] = { 18, 141, 212, 13, },
		[15] = { 19, 176, 265, 14, },
		[16] = { 20, 219, 329, 15, },
		[17] = { 21, 272, 408, 16, },
		[18] = { 22, 336, 504, 17, },
		[19] = { 22, 393, 590, 18, },
		[20] = { 23, 459, 688, 19, },
		[21] = { 24, 509, 763, 20, },
		[22] = { 24, 563, 845, 21, },
		[23] = { 25, 623, 935, 22, },
		[24] = { 25, 690, 1034, 23, },
		[25] = { 26, 762, 1144, 24, },
		[26] = { 26, 842, 1264, 25, },
		[27] = { 27, 931, 1396, 26, },
		[28] = { 27, 1027, 1541, 27, },
		[29] = { 28, 1134, 1701, 28, },
		[30] = { 29, 1251, 1876, 29, },
	},
}
gems["Explosive Arrow"] = {
	fire = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	duration = true,
	bow = true,
	parts = {
		{
			name = "Explosion",
			attack = false,
			cast = true,
		},
		{
			name = "Arrow",
			attack = true,
			cast = false,
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [10] = true, [11] = true, [12] = true, [22] = true, [17] = true, [19] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 6), 
		skill("duration", 1), --"base_skill_effect_duration" = 1000
		--"fuse_arrow_explosion_radius_+_per_fuse_arrow_orb" = 2
		--"active_skill_attack_damage_+%_final" = 0
		--"skill_can_fire_arrows" = 1
		--"base_is_projectile" = 1
	},
	qualityMods = {
		mod("EnemyIgniteChance", "BASE", 1), --"base_chance_to_ignite_%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"minimum_fire_damage_per_fuse_arrow_orb"
		[3] = skill("FireMax", nil), --"maximum_fire_damage_per_fuse_arrow_orb"
	},
	levels = {
		[1] = { 18, 44, 66, },
		[2] = { 19, 54, 81, },
		[3] = { 20, 66, 99, },
		[4] = { 21, 80, 121, },
		[5] = { 21, 98, 146, },
		[6] = { 22, 111, 166, },
		[7] = { 22, 126, 189, },
		[8] = { 23, 142, 214, },
		[9] = { 23, 161, 242, },
		[10] = { 24, 182, 273, },
		[11] = { 24, 205, 308, },
		[12] = { 24, 232, 347, },
		[13] = { 26, 261, 391, },
		[14] = { 26, 293, 440, },
		[15] = { 26, 330, 495, },
		[16] = { 26, 371, 556, },
		[17] = { 26, 416, 624, },
		[18] = { 27, 467, 700, },
		[19] = { 27, 523, 785, },
		[20] = { 27, 586, 879, },
		[21] = { 28, 656, 984, },
		[22] = { 28, 734, 1100, },
		[23] = { 29, 820, 1230, },
		[24] = { 29, 917, 1375, },
		[25] = { 30, 1024, 1536, },
		[26] = { 30, 1143, 1714, },
		[27] = { 30, 1275, 1913, },
		[28] = { 30, 1422, 2134, },
		[29] = { 31, 1586, 2379, },
		[30] = { 31, 1767, 2651, },
	},
}
gems["Fire Trap"] = {
	trap = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	duration = true,
	area = true,
	fire = true,
	color = 2,
	baseFlags = {
		spell = true,
		trap = true,
		area = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [12] = true, [10] = true, [19] = true, [11] = true, [29] = true, [37] = true, [40] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 6), 
		--"is_trap" = 1
		--"base_trap_duration" = 16000
		skill("duration", 8), --"base_skill_effect_duration" = 8000
		--"is_area_damage" = ?
		--"base_skill_is_trapped" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		skill("trapCooldown", 3), 
	},
	qualityMods = {
		mod("FireDamage", "INC", 1.5, ModFlag.Dot), --"burn_damage_+%" = 1.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[4] = skill("FireDot", nil), --"base_fire_damage_to_deal_per_minute"
	},
	levels = {
		[1] = { 7, 2, 4, 3.6166666666667, },
		[2] = { 8, 3, 5, 4.1, },
		[3] = { 9, 4, 6, 5.2, },
		[4] = { 10, 6, 8, 7.1833333333333, },
		[5] = { 11, 8, 12, 10.6, },
		[6] = { 12, 13, 19, 16.416666666667, },
		[7] = { 13, 18, 27, 22.566666666667, },
		[8] = { 14, 25, 37, 30.466666666667, },
		[9] = { 14, 34, 50, 40.533333333333, },
		[10] = { 16, 45, 67, 53.333333333333, },
		[11] = { 17, 59, 89, 69.5, },
		[12] = { 18, 78, 117, 89.866666666667, },
		[13] = { 19, 101, 152, 115.41666666667, },
		[14] = { 20, 132, 197, 147.36666666667, },
		[15] = { 21, 170, 255, 187.21666666667, },
		[16] = { 22, 219, 328, 236.78333333333, },
		[17] = { 22, 280, 420, 298.28333333333, },
		[18] = { 23, 358, 536, 374.41666666667, },
		[19] = { 24, 429, 643, 441.11666666667, },
		[20] = { 24, 513, 770, 518.76666666667, },
		[21] = { 25, 578, 867, 573.95, },
		[22] = { 26, 651, 976, 634.4, },
		[23] = { 26, 732, 1098, 700.6, },
		[24] = { 27, 823, 1235, 772.98333333333, },
		[25] = { 27, 925, 1388, 852.1, },
		[26] = { 28, 1040, 1559, 938.5, },
		[27] = { 29, 1167, 1751, 1032.75, },
		[28] = { 30, 1310, 1965, 1135.4666666667, },
		[29] = { 30, 1470, 2205, 1247.3166666667, },
		[30] = { 30, 1648, 2472, 1368.9833333333, },
	},
}
gems["Flicker Strike"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	movement = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [24] = true, [25] = true, [28] = true, [38] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 10), 
		mod("Speed", "MORE", 20, ModFlag.Attack), --"flicker_strike_more_attack_speed_+%_final" = 20
		mod("Speed", "INC", 10, ModFlag.Attack, 0, { type = "Multiplier", var = "FrenzyCharge" }), --"base_attack_speed_+%_per_frenzy_charge" = 10
		--"ignores_proximity_shield" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 30, },
		[2] = { 31.6, },
		[3] = { 33.2, },
		[4] = { 34.8, },
		[5] = { 36.4, },
		[6] = { 38, },
		[7] = { 39.6, },
		[8] = { 41.2, },
		[9] = { 42.8, },
		[10] = { 44.4, },
		[11] = { 46, },
		[12] = { 47.6, },
		[13] = { 49.2, },
		[14] = { 50.8, },
		[15] = { 52.4, },
		[16] = { 54, },
		[17] = { 55.6, },
		[18] = { 57.2, },
		[19] = { 58.8, },
		[20] = { 60.4, },
		[21] = { 62, },
		[22] = { 63.6, },
		[23] = { 65.2, },
		[24] = { 66.8, },
		[25] = { 68.4, },
		[26] = { 70, },
		[27] = { 71.6, },
		[28] = { 73.2, },
		[29] = { 74.8, },
		[30] = { 76.4, },
	},
}
gems["Freeze Mine"] = {
	mine = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	cold = true,
	color = 2,
	baseFlags = {
		spell = true,
		mine = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [41] = true, [34] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 0.5), 
		--"freeze_mine_cold_resistance_+_while_frozen" = -15
		--"base_mine_duration" = 16000
		--"base_skill_is_mined" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_remote_mine" = ?
		--"always_freeze" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		--[4] = "freeze_as_though_dealt_damage_+%"
	},
	levels = {
		[1] = { 6, 7, 10, 200, },
		[2] = { 8, 9, 13, 210, },
		[3] = { 10, 12, 17, 220, },
		[4] = { 10, 15, 23, 230, },
		[5] = { 11, 19, 29, 240, },
		[6] = { 12, 24, 37, 250, },
		[7] = { 13, 30, 46, 260, },
		[8] = { 14, 36, 54, 270, },
		[9] = { 14, 42, 63, 280, },
		[10] = { 16, 49, 73, 290, },
		[11] = { 18, 57, 85, 300, },
		[12] = { 18, 66, 99, 310, },
		[13] = { 19, 76, 114, 320, },
		[14] = { 20, 88, 131, 330, },
		[15] = { 21, 101, 151, 340, },
		[16] = { 21, 116, 173, 350, },
		[17] = { 21, 132, 199, 360, },
		[18] = { 21, 151, 227, 370, },
		[19] = { 22, 165, 248, 380, },
		[20] = { 22, 181, 271, 390, },
		[21] = { 22, 197, 296, 400, },
		[22] = { 22, 215, 322, 410, },
		[23] = { 23, 234, 351, 420, },
		[24] = { 23, 255, 383, 430, },
		[25] = { 24, 278, 417, 440, },
		[26] = { 24, 302, 454, 450, },
		[27] = { 24, 329, 493, 460, },
		[28] = { 24, 358, 536, 470, },
		[29] = { 25, 389, 583, 480, },
		[30] = { 25, 422, 633, 490, },
	},
}
gems["Frenzy"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [22] = true, [17] = true, [19] = true, [25] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 10), 
		mod("PhysicalDamage", "INC", 5, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }), --"physical_damage_+%_per_frenzy_charge" = 5
		mod("Speed", "INC", 5, ModFlag.Attack, 0, { type = "Multiplier", var = "FrenzyCharge" }), --"base_attack_speed_+%_per_frenzy_charge" = 5
		--"skill_can_fire_arrows" = ?
		--"skill_can_fire_wand_projectiles" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 10, },
		[2] = { 11.4, },
		[3] = { 12.8, },
		[4] = { 14.2, },
		[5] = { 15.6, },
		[6] = { 17, },
		[7] = { 18.4, },
		[8] = { 19.8, },
		[9] = { 21.2, },
		[10] = { 22.6, },
		[11] = { 24, },
		[12] = { 25.4, },
		[13] = { 26.8, },
		[14] = { 28.2, },
		[15] = { 29.6, },
		[16] = { 31, },
		[17] = { 32.4, },
		[18] = { 33.8, },
		[19] = { 35.2, },
		[20] = { 36.6, },
		[21] = { 38, },
		[22] = { 39.4, },
		[23] = { 40.8, },
		[24] = { 42.2, },
		[25] = { 43.6, },
		[26] = { 45, },
		[27] = { 46.4, },
		[28] = { 47.8, },
		[29] = { 49.2, },
		[30] = { 50.6, },
	},
}
gems["Frost Blades"] = {
	projectile = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	cold = true,
	parts = {
		{
			name = "Melee hit",
			melee = true,
			projectile = false,
		},
		{
			name = "Icy blades",
			melee = false,
			projectile = true,
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		cold = true,
	},
	skillTypes = { [1] = true, [3] = true, [6] = true, [25] = true, [28] = true, [24] = true, [34] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		mod("PhysicalDamageConvertToCold", "BASE", 40, 0, 0, nil), --"base_physical_damage_%_to_convert_to_cold" = 40
		--"total_projectile_spread_angle_override" = 110
		--"show_number_of_projectiles" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, ModFlag.Projectile), --"projectile_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("ProjectileCount", "BASE", nil), --"number_of_additional_projectiles"
		--[2] = "melee_weapon_range_+"
		[3] = mod("ProjectileSpeed", "INC", nil), --"base_projectile_speed_+%"
		[4] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 4, 18, 0, nil, },
		[2] = { 4, 18, 1, 2.2, },
		[3] = { 4, 18, 2, 4.4, },
		[4] = { 4, 18, 3, 6.6, },
		[5] = { 4, 18, 4, 8.8, },
		[6] = { 5, 19, 5, 11, },
		[7] = { 5, 19, 6, 13.2, },
		[8] = { 5, 19, 7, 15.4, },
		[9] = { 5, 19, 8, 17.6, },
		[10] = { 5, 19, 9, 19.8, },
		[11] = { 6, 20, 10, 22, },
		[12] = { 6, 20, 11, 24.2, },
		[13] = { 6, 20, 12, 26.4, },
		[14] = { 6, 20, 13, 28.6, },
		[15] = { 6, 20, 14, 30.8, },
		[16] = { 7, 21, 15, 33, },
		[17] = { 7, 21, 16, 35.2, },
		[18] = { 7, 21, 17, 37.4, },
		[19] = { 7, 21, 18, 39.6, },
		[20] = { 7, 21, 19, 41.8, },
		[21] = { 8, 22, 20, 44, },
		[22] = { 8, 22, 21, 46.2, },
		[23] = { 8, 22, 22, 48.4, },
		[24] = { 8, 22, 23, 50.6, },
		[25] = { 8, 22, 24, 52.8, },
		[26] = { 9, 23, 25, 55, },
		[27] = { 9, 23, 26, 57.2, },
		[28] = { 9, 23, 27, 59.4, },
		[29] = { 9, 23, 28, 61.6, },
		[30] = { 9, 23, 29, 63.8, },
	},
}
gems["Grace"] = {
	aura = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 2,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 50), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("Evasion", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_evasion_rating"
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 227, 0, },
		[2] = { 271, 3, },
		[3] = { 322, 6, },
		[4] = { 379, 9, },
		[5] = { 444, 12, },
		[6] = { 528, 15, },
		[7] = { 621, 18, },
		[8] = { 722, 21, },
		[9] = { 845, 23, },
		[10] = { 940, 25, },
		[11] = { 1043, 27, },
		[12] = { 1155, 29, },
		[13] = { 1283, 31, },
		[14] = { 1413, 33, },
		[15] = { 1567, 35, },
		[16] = { 1732, 36, },
		[17] = { 1914, 37, },
		[18] = { 2115, 38, },
		[19] = { 2335, 39, },
		[20] = { 2575, 40, },
		[21] = { 2700, 41, },
		[22] = { 2835, 42, },
		[23] = { 2979, 43, },
		[24] = { 3124, 44, },
		[25] = { 3279, 45, },
		[26] = { 3444, 46, },
		[27] = { 3611, 47, },
		[28] = { 3795, 48, },
		[29] = { 3982, 49, },
		[30] = { 4179, 50, },
	},
}
gems["Vaal Grace"] = {
	aura = true,
	dexterity = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [5] = true, [11] = true, [18] = true, [27] = true, [12] = true, [43] = true, [44] = true, },
	baseMods = {
		skill("castTime", 0.6), 
		skill("duration", 6), --"base_skill_effect_duration" = 6000
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("AttackDodgeChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_chance_to_dodge_%"
		[2] = mod("SpellDodgeChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_chance_to_dodge_spells_%"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 24, 0, },
		[2] = { 25, 25, 3, },
		[3] = { 25, 25, 6, },
		[4] = { 26, 26, 9, },
		[5] = { 26, 26, 12, },
		[6] = { 27, 27, 15, },
		[7] = { 27, 27, 18, },
		[8] = { 28, 28, 21, },
		[9] = { 28, 28, 23, },
		[10] = { 29, 29, 25, },
		[11] = { 29, 29, 27, },
		[12] = { 30, 30, 29, },
		[13] = { 30, 30, 31, },
		[14] = { 31, 31, 33, },
		[15] = { 31, 31, 35, },
		[16] = { 32, 32, 36, },
		[17] = { 32, 32, 37, },
		[18] = { 33, 33, 38, },
		[19] = { 33, 33, 39, },
		[20] = { 34, 34, 40, },
		[21] = { 34, 34, 41, },
		[22] = { 35, 35, 42, },
		[23] = { 35, 35, 43, },
		[24] = { 36, 36, 44, },
		[25] = { 36, 36, 45, },
		[26] = { 37, 37, 46, },
		[27] = { 37, 37, 47, },
		[28] = { 38, 38, 48, },
		[29] = { 38, 38, 49, },
		[30] = { 39, 39, 50, },
	},
}
gems["Haste"] = {
	aura = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 2,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 50), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_speed_+%"
		[2] = mod("Speed", "INC", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"cast_speed_+%_from_haste_aura"
		[3] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_movement_velocity_+%"
		[4] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 9, 9, 4, 0, },
		[2] = { 10, 9, 4, 3, },
		[3] = { 10, 10, 4, 6, },
		[4] = { 10, 10, 5, 9, },
		[5] = { 11, 10, 5, 12, },
		[6] = { 11, 11, 5, 15, },
		[7] = { 11, 11, 6, 18, },
		[8] = { 12, 11, 6, 21, },
		[9] = { 12, 12, 6, 23, },
		[10] = { 12, 12, 7, 25, },
		[11] = { 13, 12, 7, 27, },
		[12] = { 13, 13, 7, 29, },
		[13] = { 13, 13, 8, 31, },
		[14] = { 14, 13, 8, 33, },
		[15] = { 14, 14, 8, 35, },
		[16] = { 15, 14, 8, 36, },
		[17] = { 15, 15, 8, 37, },
		[18] = { 16, 15, 8, 38, },
		[19] = { 16, 16, 8, 39, },
		[20] = { 16, 16, 9, 40, },
		[21] = { 17, 16, 9, 41, },
		[22] = { 17, 17, 9, 42, },
		[23] = { 17, 17, 10, 43, },
		[24] = { 18, 17, 10, 44, },
		[25] = { 18, 18, 10, 45, },
		[26] = { 18, 18, 11, 46, },
		[27] = { 19, 18, 11, 47, },
		[28] = { 19, 19, 11, 48, },
		[29] = { 19, 19, 12, 49, },
		[30] = { 20, 19, 12, 50, },
	},
}
gems["Vaal Haste"] = {
	aura = true,
	dexterity = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [5] = true, [11] = true, [18] = true, [27] = true, [12] = true, [43] = true, [44] = true, },
	baseMods = {
		skill("castTime", 0.6), 
		skill("duration", 6), --"base_skill_effect_duration" = 6000
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_speed_+%"
		[2] = mod("Speed", "INC", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"cast_speed_+%_from_haste_aura"
		[3] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_movement_velocity_+%"
		[4] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 30, 29, 14, 0, },
		[2] = { 30, 30, 14, 3, },
		[3] = { 30, 30, 15, 6, },
		[4] = { 31, 30, 15, 9, },
		[5] = { 31, 31, 15, 12, },
		[6] = { 31, 31, 16, 15, },
		[7] = { 32, 31, 16, 18, },
		[8] = { 32, 32, 16, 21, },
		[9] = { 32, 32, 17, 23, },
		[10] = { 33, 32, 17, 25, },
		[11] = { 33, 33, 17, 27, },
		[12] = { 33, 33, 18, 29, },
		[13] = { 34, 33, 18, 31, },
		[14] = { 34, 34, 18, 33, },
		[15] = { 34, 34, 19, 35, },
		[16] = { 35, 34, 19, 36, },
		[17] = { 35, 35, 19, 37, },
		[18] = { 35, 35, 20, 38, },
		[19] = { 36, 35, 20, 39, },
		[20] = { 36, 36, 20, 40, },
		[21] = { 36, 36, 21, 41, },
		[22] = { 37, 36, 21, 42, },
		[23] = { 37, 37, 21, 43, },
		[24] = { 37, 37, 22, 44, },
		[25] = { 38, 37, 22, 45, },
		[26] = { 38, 38, 22, 46, },
		[27] = { 38, 38, 23, 47, },
		[28] = { 39, 38, 23, 48, },
		[29] = { 39, 39, 23, 49, },
		[30] = { 39, 39, 24, 50, },
	},
}
gems["Hatred"] = {
	aura = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	color = 2,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 50), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("PhysicalDamageGainAsCold", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"physical_damage_%_to_add_as_cold"
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 26, 0, },
		[2] = { 26, 3, },
		[3] = { 27, 6, },
		[4] = { 27, 9, },
		[5] = { 28, 12, },
		[6] = { 28, 15, },
		[7] = { 29, 18, },
		[8] = { 29, 21, },
		[9] = { 30, 23, },
		[10] = { 30, 25, },
		[11] = { 31, 27, },
		[12] = { 31, 29, },
		[13] = { 32, 31, },
		[14] = { 32, 33, },
		[15] = { 33, 35, },
		[16] = { 34, 36, },
		[17] = { 34, 37, },
		[18] = { 35, 38, },
		[19] = { 35, 39, },
		[20] = { 36, 40, },
		[21] = { 36, 41, },
		[22] = { 37, 42, },
		[23] = { 37, 43, },
		[24] = { 38, 44, },
		[25] = { 38, 45, },
		[26] = { 39, 46, },
		[27] = { 39, 47, },
		[28] = { 40, 48, },
		[29] = { 40, 49, },
		[30] = { 41, 50, },
	},
}
gems["Herald of Ice"] = {
	dexterity = true,
	active_skill = true,
	cast = true,
	area = true,
	cold = true,
	color = 2,
	baseFlags = {
		cast = true,
		area = true,
		cold = true,
	},
	skillTypes = { [39] = true, [5] = true, [15] = true, [16] = true, [10] = true, [11] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 25), 
		skill("damageEffectiveness", 0.8), 
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"display_skill_deals_secondary_damage" = ?
		--"damage_cannot_be_reflected" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
	},
	qualityMods = {
		mod("ColdDamage", "INC", 0.75, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"herald_of_ice_cold_damage_+%" = 0.75
	},
	levelMods = {
		[1] = mod("ColdMin", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_minimum_added_cold_damage"
		[2] = mod("ColdMax", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_maximum_added_cold_damage"
		[3] = mod("ColdMin", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_minimum_added_cold_damage"
		[4] = mod("ColdMax", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_maximum_added_cold_damage"
		[5] = skill("ColdMin", nil), --"secondary_minimum_base_cold_damage"
		[6] = skill("ColdMax", nil), --"secondary_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 4, 5, 4, 5, 18, 26, },
		[2] = { 5, 7, 5, 7, 23, 35, },
		[3] = { 6, 8, 6, 8, 30, 45, },
		[4] = { 7, 10, 7, 10, 38, 57, },
		[5] = { 8, 12, 8, 12, 45, 67, },
		[6] = { 9, 14, 9, 14, 53, 80, },
		[7] = { 10, 16, 10, 16, 62, 94, },
		[8] = { 12, 18, 12, 18, 73, 110, },
		[9] = { 13, 20, 13, 20, 85, 128, },
		[10] = { 15, 23, 15, 23, 99, 149, },
		[11] = { 17, 26, 17, 26, 115, 173, },
		[12] = { 19, 29, 19, 29, 134, 200, },
		[13] = { 22, 33, 22, 33, 154, 232, },
		[14] = { 24, 37, 24, 37, 178, 267, },
		[15] = { 26, 39, 26, 39, 195, 293, },
		[16] = { 28, 42, 28, 42, 214, 321, },
		[17] = { 30, 46, 30, 46, 235, 352, },
		[18] = { 33, 49, 33, 49, 257, 386, },
		[19] = { 35, 53, 35, 53, 282, 422, },
		[20] = { 38, 56, 38, 56, 308, 462, },
		[21] = { 40, 61, 40, 61, 337, 505, },
		[22] = { 43, 65, 43, 65, 368, 552, },
		[23] = { 46, 70, 46, 70, 402, 603, },
		[24] = { 50, 75, 50, 75, 438, 658, },
		[25] = { 53, 80, 53, 80, 478, 717, },
		[26] = { 57, 85, 57, 85, 521, 782, },
		[27] = { 61, 91, 61, 91, 568, 852, },
		[28] = { 65, 98, 65, 98, 619, 928, },
		[29] = { 69, 104, 69, 104, 674, 1010, },
		[30] = { 74, 111, 74, 111, 733, 1100, },
	},
}
gems["Ice Shot"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	duration = true,
	cold = true,
	bow = true,
	parts = {
		{
			name = "Arrow",
			area = false,
		},
		{
			name = "Cone",
			area = true,
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [11] = true, [12] = true, [22] = true, [17] = true, [19] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("PhysicalDamageConvertToCold", 40), --"skill_physical_damage_%_to_convert_to_cold" = 40
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		--"skill_can_fire_arrows" = ?
		skill("PhysicalDamageConvertToCold", 100, { type = "SkillPart", skillPart = 2 }), 
	},
	qualityMods = {
		mod("ColdDamage", "INC", 1), --"cold_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 6, 20, },
		[2] = { 6, 21.4, },
		[3] = { 6, 22.8, },
		[4] = { 7, 24.2, },
		[5] = { 7, 25.6, },
		[6] = { 7, 27, },
		[7] = { 7, 28.4, },
		[8] = { 8, 29.8, },
		[9] = { 8, 31.2, },
		[10] = { 8, 32.6, },
		[11] = { 8, 34, },
		[12] = { 8, 35.4, },
		[13] = { 9, 36.8, },
		[14] = { 9, 38.2, },
		[15] = { 9, 39.6, },
		[16] = { 9, 41, },
		[17] = { 9, 42.4, },
		[18] = { 10, 43.8, },
		[19] = { 10, 45.2, },
		[20] = { 10, 46.6, },
		[21] = { 10, 48, },
		[22] = { 10, 49.4, },
		[23] = { 11, 50.8, },
		[24] = { 11, 52.2, },
		[25] = { 11, 53.6, },
		[26] = { 11, 55, },
		[27] = { 11, 56.4, },
		[28] = { 12, 57.8, },
		[29] = { 12, 59.2, },
		[30] = { 12, 60.6, },
	},
}
gems["Ice Trap"] = {
	trap = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		trap = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [19] = true, [11] = true, [37] = true, [34] = true, [12] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 1.1), 
		skill("critChance", 5), 
		--"base_trap_duration" = 16000
		--"is_area_damage" = ?
		--"base_skill_is_trapped" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_trap" = ?
		skill("trapCooldown", 2), 
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 13, 60, 90, },
		[2] = { 14, 72, 108, },
		[3] = { 15, 85, 128, },
		[4] = { 15, 101, 151, },
		[5] = { 16, 119, 178, },
		[6] = { 17, 132, 198, },
		[7] = { 17, 147, 220, },
		[8] = { 18, 163, 244, },
		[9] = { 19, 180, 270, },
		[10] = { 19, 199, 299, },
		[11] = { 20, 220, 330, },
		[12] = { 20, 243, 364, },
		[13] = { 21, 268, 402, },
		[14] = { 21, 295, 442, },
		[15] = { 22, 325, 487, },
		[16] = { 23, 357, 536, },
		[17] = { 23, 392, 589, },
		[18] = { 24, 431, 646, },
		[19] = { 24, 473, 709, },
		[20] = { 25, 519, 778, },
		[21] = { 26, 568, 853, },
		[22] = { 26, 623, 934, },
		[23] = { 27, 681, 1022, },
		[24] = { 27, 746, 1118, },
		[25] = { 28, 815, 1223, },
		[26] = { 28, 891, 1337, },
		[27] = { 29, 973, 1460, },
		[28] = { 30, 1063, 1595, },
		[29] = { 30, 1160, 1740, },
		[30] = { 31, 1266, 1899, },
	},
}
gems["Lacerate"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 8), 
		mod("Speed", "MORE", -25, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -25
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { -5, 0, },
		[2] = { -3.8, 1, },
		[3] = { -2.6, 2, },
		[4] = { -1.4, 3, },
		[5] = { -0.2, 4, },
		[6] = { 1, 5, },
		[7] = { 2.2, 6, },
		[8] = { 3.4, 7, },
		[9] = { 4.6, 8, },
		[10] = { 5.8, 9, },
		[11] = { 7, 10, },
		[12] = { 8.2, 11, },
		[13] = { 9.4, 12, },
		[14] = { 10.6, 13, },
		[15] = { 11.8, 14, },
		[16] = { 13, 15, },
		[17] = { 14.2, 16, },
		[18] = { 15.4, 17, },
		[19] = { 16.6, 18, },
		[20] = { 17.8, 19, },
		[21] = { 19, 20, },
		[22] = { 20.2, 21, },
		[23] = { 21.4, 22, },
		[24] = { 22.6, 23, },
		[25] = { 23.8, 24, },
		[26] = { 25, 25, },
		[27] = { 26.2, 26, },
		[28] = { 27.4, 27, },
		[29] = { 28.6, 28, },
		[30] = { 29.8, 29, },
	},
}
gems["Lightning Arrow"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	lightning = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		lightning = true,
	},
	skillTypes = { [1] = true, [48] = true, [11] = true, [3] = true, [22] = true, [17] = true, [19] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("PhysicalDamageConvertToLightning", 50), --"skill_physical_damage_%_to_convert_to_lightning" = 50
		--"lightning_arrow_maximum_number_of_extra_targets" = 3
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("EnemyShockChance", "BASE", 0.5), --"base_chance_to_shock_%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 7, nil, },
		[2] = { 7, 1, },
		[3] = { 7, 2, },
		[4] = { 8, 3, },
		[5] = { 8, 4, },
		[6] = { 8, 5, },
		[7] = { 8, 6, },
		[8] = { 8, 7, },
		[9] = { 9, 8, },
		[10] = { 9, 9, },
		[11] = { 9, 10, },
		[12] = { 9, 11, },
		[13] = { 9, 12, },
		[14] = { 10, 13, },
		[15] = { 10, 14, },
		[16] = { 10, 15, },
		[17] = { 10, 16, },
		[18] = { 10, 17, },
		[19] = { 11, 18, },
		[20] = { 11, 19, },
		[21] = { 11, 20, },
		[22] = { 11, 21, },
		[23] = { 11, 22, },
		[24] = { 11, 23, },
		[25] = { 11, 24, },
		[26] = { 12, 25, },
		[27] = { 12, 26, },
		[28] = { 12, 27, },
		[29] = { 12, 28, },
		[30] = { 12, 29, },
	},
}
gems["Lightning Strike"] = {
	projectile = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	lightning = true,
	parts = {
		{
			name = "Melee hit",
			melee = true,
			projectile = false,
		},
		{
			name = "Projectiles",
			melee = false,
			projectile = true,
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		lightning = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [25] = true, [28] = true, [24] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		skill("PhysicalDamageConvertToLightning", 50), --"skill_physical_damage_%_to_convert_to_lightning" = 50
		mod("Damage", "MORE", -25, ModFlag.Projectile), --"active_skill_projectile_damage_+%_final" = -25
		--"total_projectile_spread_angle_override" = 70
		--"show_number_of_projectiles" = ?
	},
	qualityMods = {
		mod("PierceChance", "BASE", 2), --"pierce_%" = 2
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("ProjectileCount", "BASE", nil), --"number_of_additional_projectiles"
	},
	levels = {
		[1] = { 30, 4, },
		[2] = { 32.4, 4, },
		[3] = { 34.8, 4, },
		[4] = { 37.2, 4, },
		[5] = { 39.6, 4, },
		[6] = { 42, 5, },
		[7] = { 44.4, 5, },
		[8] = { 46.8, 5, },
		[9] = { 49.2, 5, },
		[10] = { 51.6, 5, },
		[11] = { 54, 6, },
		[12] = { 56.4, 6, },
		[13] = { 58.8, 6, },
		[14] = { 61.2, 6, },
		[15] = { 63.6, 6, },
		[16] = { 66, 7, },
		[17] = { 68.4, 7, },
		[18] = { 70.8, 7, },
		[19] = { 73.2, 7, },
		[20] = { 75.6, 7, },
		[21] = { 78, 8, },
		[22] = { 80.4, 8, },
		[23] = { 82.8, 8, },
		[24] = { 85.2, 8, },
		[25] = { 87.6, 8, },
		[26] = { 90, 9, },
		[27] = { 92.4, 9, },
		[28] = { 94.8, 9, },
		[29] = { 97.2, 9, },
		[30] = { 99.6, 9, },
	},
}
gems["Vaal Lightning Strike"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	melee = true,
	duration = true,
	lightning = true,
	parts = {
		{
			name = "Strike",
		},
		{
			name = "Beams",
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		duration = true,
		lightning = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [25] = true, [28] = true, [24] = true, [12] = true, [43] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("PhysicalDamageConvertToLightning", 50), --"skill_physical_damage_%_to_convert_to_lightning" = 50
		mod("Damage", "MORE", -50, 0, 0, { type = "SkillPart", skillPart = 2 }), --"vaal_lightning_strike_beam_damage_+%_final" = -50
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("duration", nil), --"base_skill_effect_duration"
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 5, nil, },
		[2] = { 5.2, 1.2, },
		[3] = { 5.4, 2.4, },
		[4] = { 5.6, 3.6, },
		[5] = { 5.8, 4.8, },
		[6] = { 6, 6, },
		[7] = { 6.2, 7.2, },
		[8] = { 6.4, 8.4, },
		[9] = { 6.6, 9.6, },
		[10] = { 6.8, 10.8, },
		[11] = { 7, 12, },
		[12] = { 7.2, 13.2, },
		[13] = { 7.4, 14.4, },
		[14] = { 7.6, 15.6, },
		[15] = { 7.8, 16.8, },
		[16] = { 8, 18, },
		[17] = { 8.2, 19.2, },
		[18] = { 8.4, 20.4, },
		[19] = { 8.6, 21.6, },
		[20] = { 8.8, 22.8, },
		[21] = { 9, 24, },
		[22] = { 9.2, 25.2, },
		[23] = { 9.4, 26.4, },
		[24] = { 9.6, 27.6, },
		[25] = { 9.8, 28.8, },
		[26] = { 10, 30, },
		[27] = { 10.2, 31.2, },
		[28] = { 10.4, 32.4, },
		[29] = { 10.6, 33.6, },
		[30] = { 10.8, 34.8, },
	},
}
gems["Mirror Arrow"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	minion = true,
	duration = true,
	bow = true,
	unsupported = true,
}
gems["Phase Run"] = {
	dexterity = true,
	active_skill = true,
	spell = true,
	duration = true,
	movement = true,
	color = 2,
	baseFlags = {
		spell = true,
		duration = true,
		movement = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [36] = true, [38] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"enemy_aggro_radius_+%" = -80
		skill("duration", 1.8), --"base_skill_effect_duration" = 1800
		--"base_secondary_skill_effect_duration" = 200
		mod("Duration", "INC", 100, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }), --"skill_effect_duration_+%_per_frenzy_charge" = 100
		--"phase_through_objects" = ?
	},
	qualityMods = {
		mod("MovementSpeed", "INC", 0.5, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_movement_velocity_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_movement_velocity_+%"
		[3] = mod("PhysicalDamage", "MORE", nil, ModFlag.Melee, 0, { type = "GlobalEffect", effectType = "Buff" }), --"phase_run_melee_physical_damage_+%_final"
	},
	levels = {
		[1] = { 11, 30, 20, },
		[2] = { 11, 30, 21, },
		[3] = { 11, 31, 21, },
		[4] = { 11, 31, 22, },
		[5] = { 11, 32, 22, },
		[6] = { 12, 32, 23, },
		[7] = { 12, 33, 23, },
		[8] = { 12, 33, 24, },
		[9] = { 12, 34, 24, },
		[10] = { 12, 34, 25, },
		[11] = { 12, 35, 25, },
		[12] = { 12, 35, 26, },
		[13] = { 13, 36, 26, },
		[14] = { 13, 36, 27, },
		[15] = { 13, 37, 27, },
		[16] = { 13, 37, 28, },
		[17] = { 13, 38, 28, },
		[18] = { 13, 38, 29, },
		[19] = { 14, 39, 29, },
		[20] = { 14, 39, 30, },
		[21] = { 14, 40, 30, },
		[22] = { 14, 40, 31, },
		[23] = { 14, 41, 31, },
		[24] = { 14, 41, 32, },
		[25] = { 14, 42, 32, },
		[26] = { 14, 42, 33, },
		[27] = { 14, 43, 33, },
		[28] = { 14, 43, 34, },
		[29] = { 14, 44, 34, },
		[30] = { 14, 44, 35, },
	},
}
gems["Poacher's Mark"] = {
	curse = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"monster_slain_flask_charges_granted_+%" = 100
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		--"chance_to_grant_frenzy_charge_on_death_%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("Evasion", "MORE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse"}), --"evasion_rating_+%_final_from_poachers_mark"
		[5] = mod("LifeOnHit", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Curse" }), --"life_granted_when_hit_by_attacks"
		[6] = mod("ManaOnHit", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Curse" }), --"mana_granted_when_hit_by_attacks"
		--[7] = "chance_to_grant_frenzy_charge_on_death_%"
	},
	levels = {
		[1] = { 24, 6, 0, -30, 5, 5, 21, },
		[2] = { 26, 6.2, 2, -31, 6, 6, 21, },
		[3] = { 27, 6.4, 4, -32, 7, 6, 22, },
		[4] = { 29, 6.6, 6, -33, 8, 6, 22, },
		[5] = { 30, 6.8, 8, -34, 9, 7, 23, },
		[6] = { 32, 7, 10, -35, 10, 7, 23, },
		[7] = { 34, 7.2, 12, -36, 11, 7, 24, },
		[8] = { 35, 7.4, 14, -37, 12, 8, 24, },
		[9] = { 37, 7.6, 16, -38, 13, 8, 25, },
		[10] = { 38, 7.8, 18, -39, 14, 8, 25, },
		[11] = { 39, 8, 20, -40, 15, 9, 26, },
		[12] = { 40, 8.2, 22, -41, 16, 9, 26, },
		[13] = { 42, 8.4, 24, -42, 17, 9, 27, },
		[14] = { 43, 8.6, 26, -43, 18, 10, 27, },
		[15] = { 44, 8.8, 28, -44, 19, 10, 28, },
		[16] = { 45, 9, 30, -45, 20, 10, 28, },
		[17] = { 46, 9.2, 32, -46, 21, 11, 29, },
		[18] = { 47, 9.4, 34, -47, 22, 11, 29, },
		[19] = { 48, 9.6, 36, -48, 23, 11, 30, },
		[20] = { 50, 9.8, 38, -49, 24, 12, 30, },
		[21] = { 51, 10, 40, -50, 25, 12, 31, },
		[22] = { 52, 10.2, 42, -51, 26, 12, 31, },
		[23] = { 53, 10.4, 44, -52, 27, 13, 32, },
		[24] = { 54, 10.6, 46, -53, 28, 13, 32, },
		[25] = { 56, 10.8, 48, -54, 29, 13, 33, },
		[26] = { 57, 11, 50, -55, 30, 14, 33, },
		[27] = { 58, 11.2, 52, -56, 31, 14, 34, },
		[28] = { 59, 11.4, 54, -57, 32, 14, 34, },
		[29] = { 60, 11.6, 56, -58, 33, 15, 35, },
		[30] = { 61, 11.8, 58, -59, 34, 15, 35, },
	},
}
gems["Projectile Weakness"] = {
	curse = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		mod("SelfPierceChance", "BASE", 50, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"chance_to_be_pierced_%" = 50
		--"chance_to_be_knocked_back_%" = 25
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("ProjectileDamageTaken", "BASE", 0.5, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"projectile_damage_taken_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("ProjectileDamageTaken", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"projectile_damage_taken_+%"
	},
	levels = {
		[1] = { 24, 9, 0, 25, },
		[2] = { 26, 9.1, 2, 26, },
		[3] = { 27, 9.2, 4, 27, },
		[4] = { 29, 9.3, 6, 28, },
		[5] = { 30, 9.4, 8, 29, },
		[6] = { 32, 9.5, 10, 30, },
		[7] = { 34, 9.6, 12, 31, },
		[8] = { 35, 9.7, 14, 32, },
		[9] = { 37, 9.8, 16, 33, },
		[10] = { 38, 9.9, 18, 34, },
		[11] = { 39, 10, 20, 35, },
		[12] = { 40, 10.1, 22, 36, },
		[13] = { 42, 10.2, 24, 37, },
		[14] = { 43, 10.3, 26, 38, },
		[15] = { 44, 10.4, 28, 39, },
		[16] = { 45, 10.5, 30, 40, },
		[17] = { 46, 10.6, 32, 41, },
		[18] = { 47, 10.7, 34, 42, },
		[19] = { 48, 10.8, 36, 43, },
		[20] = { 50, 10.9, 38, 44, },
		[21] = { 51, 11, 40, 45, },
		[22] = { 52, 11.1, 42, 46, },
		[23] = { 53, 11.2, 44, 47, },
		[24] = { 54, 11.3, 46, 48, },
		[25] = { 56, 11.4, 48, 49, },
		[26] = { 57, 11.5, 50, 50, },
		[27] = { 58, 11.6, 52, 51, },
		[28] = { 59, 11.7, 54, 52, },
		[29] = { 60, 11.8, 56, 53, },
		[30] = { 61, 11.9, 58, 54, },
	},
}
gems["Puncture"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	duration = true,
	melee = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		duration = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [12] = true, [17] = true, [19] = true, [22] = true, [25] = true, [28] = true, [24] = true, [40] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		--"base_bleed_on_hit_still_%_of_physical_damage_to_deal_per_minute" = 600
		--"base_bleed_on_hit_moving_%_of_physical_damage_to_deal_per_minute" = 3000
		--"bleed_on_hit_base_duration" = 5000
		--"skill_can_fire_arrows" = ?
		mod("BleedChance", "BASE", 100), 
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { nil, },
		[2] = { 1.2, },
		[3] = { 2.4, },
		[4] = { 3.6, },
		[5] = { 4.8, },
		[6] = { 6, },
		[7] = { 7.2, },
		[8] = { 8.4, },
		[9] = { 9.6, },
		[10] = { 10.8, },
		[11] = { 12, },
		[12] = { 13.2, },
		[13] = { 14.4, },
		[14] = { 15.6, },
		[15] = { 16.8, },
		[16] = { 18, },
		[17] = { 19.2, },
		[18] = { 20.4, },
		[19] = { 21.6, },
		[20] = { 22.8, },
		[21] = { 24, },
		[22] = { 25.2, },
		[23] = { 26.4, },
		[24] = { 27.6, },
		[25] = { 28.8, },
		[26] = { 30, },
		[27] = { 31.2, },
		[28] = { 32.4, },
		[29] = { 33.6, },
		[30] = { 34.8, },
	},
}
gems["Purity of Ice"] = {
	aura = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	color = 2,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 35), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("ColdResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_cold_damage_resistance_%"
		[2] = mod("ColdResistMax", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_cold_damage_resistance_%"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 22, 0, 0, },
		[2] = { 23, 0, 3, },
		[3] = { 24, 0, 6, },
		[4] = { 25, 0, 9, },
		[5] = { 26, 1, 12, },
		[6] = { 27, 1, 15, },
		[7] = { 28, 1, 18, },
		[8] = { 29, 1, 21, },
		[9] = { 30, 1, 23, },
		[10] = { 31, 1, 25, },
		[11] = { 32, 2, 27, },
		[12] = { 33, 2, 29, },
		[13] = { 34, 2, 31, },
		[14] = { 35, 2, 33, },
		[15] = { 36, 2, 35, },
		[16] = { 37, 2, 36, },
		[17] = { 38, 3, 37, },
		[18] = { 39, 3, 38, },
		[19] = { 40, 3, 39, },
		[20] = { 41, 4, 40, },
		[21] = { 42, 4, 41, },
		[22] = { 43, 4, 42, },
		[23] = { 44, 5, 43, },
		[24] = { 45, 5, 44, },
		[25] = { 46, 5, 45, },
		[26] = { 47, 5, 46, },
		[27] = { 48, 5, 47, },
		[28] = { 49, 5, 48, },
		[29] = { 50, 5, 49, },
		[30] = { 51, 5, 50, },
	},
}
gems["Rain of Arrows"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
	},
	skillTypes = { [1] = true, [48] = true, [11] = true, [14] = true, [22] = true, [17] = true, [19] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 7, 10, 0, },
		[2] = { 7, 11, 1, },
		[3] = { 7, 12, 2, },
		[4] = { 8, 13, 3, },
		[5] = { 8, 14, 4, },
		[6] = { 8, 15, 5, },
		[7] = { 8, 16, 6, },
		[8] = { 8, 17, 7, },
		[9] = { 9, 18, 8, },
		[10] = { 9, 19, 9, },
		[11] = { 9, 20, 10, },
		[12] = { 9, 21, 11, },
		[13] = { 9, 22, 12, },
		[14] = { 10, 23, 13, },
		[15] = { 10, 24, 14, },
		[16] = { 10, 25, 15, },
		[17] = { 10, 26, 16, },
		[18] = { 10, 27, 17, },
		[19] = { 11, 28, 18, },
		[20] = { 11, 29, 19, },
		[21] = { 11, 30, 20, },
		[22] = { 11, 31, 21, },
		[23] = { 11, 32, 22, },
		[24] = { 11, 33, 23, },
		[25] = { 11, 34, 24, },
		[26] = { 12, 35, 25, },
		[27] = { 12, 36, 26, },
		[28] = { 12, 37, 27, },
		[29] = { 12, 38, 28, },
		[30] = { 12, 39, 29, },
	},
}
gems["Vaal Rain of Arrows"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	area = true,
	duration = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [11] = true, [14] = true, [22] = true, [17] = true, [19] = true, [12] = true, [43] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
		--"rain_of_arrows_pin" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 40, 3.4, 0, },
		[2] = { 41.5, 3.45, 1, },
		[3] = { 43, 3.5, 2, },
		[4] = { 44.5, 3.55, 3, },
		[5] = { 46, 3.6, 4, },
		[6] = { 47.5, 3.65, 5, },
		[7] = { 49, 3.7, 6, },
		[8] = { 50.5, 3.75, 7, },
		[9] = { 52, 3.8, 8, },
		[10] = { 53.5, 3.85, 9, },
		[11] = { 55, 3.9, 10, },
		[12] = { 56.5, 3.95, 11, },
		[13] = { 58, 4, 12, },
		[14] = { 59.5, 4.05, 13, },
		[15] = { 61, 4.1, 14, },
		[16] = { 62.5, 4.15, 15, },
		[17] = { 64, 4.2, 16, },
		[18] = { 65.5, 4.25, 17, },
		[19] = { 67, 4.3, 18, },
		[20] = { 68.5, 4.35, 19, },
		[21] = { 70, 4.4, 20, },
		[22] = { 71.5, 4.45, 21, },
		[23] = { 73, 4.5, 22, },
		[24] = { 74.5, 4.55, 23, },
		[25] = { 76, 4.6, 24, },
		[26] = { 77.5, 4.65, 25, },
		[27] = { 79, 4.7, 26, },
		[28] = { 80.5, 4.75, 27, },
		[29] = { 82, 4.8, 28, },
		[30] = { 83.5, 4.85, 29, },
	},
}
gems["Reave"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		--"reave_area_of_effect_+%_final_per_stage" = 20
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { nil, },
		[2] = { 2, },
		[3] = { 4, },
		[4] = { 6, },
		[5] = { 8, },
		[6] = { 10, },
		[7] = { 12, },
		[8] = { 14, },
		[9] = { 16, },
		[10] = { 18, },
		[11] = { 20, },
		[12] = { 22, },
		[13] = { 24, },
		[14] = { 26, },
		[15] = { 28, },
		[16] = { 30, },
		[17] = { 32, },
		[18] = { 34, },
		[19] = { 36, },
		[20] = { 38, },
		[21] = { 40, },
		[22] = { 42, },
		[23] = { 44, },
		[24] = { 46, },
		[25] = { 48, },
		[26] = { 50, },
		[27] = { 52, },
		[28] = { 54, },
		[29] = { 56, },
		[30] = { 58, },
	},
}
gems["Vaal Reave"] = {
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	area = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [28] = true, [24] = true, [43] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"reave_area_of_effect_+%_final_per_stage" = 20
		--"reave_rotation_on_repeat" = 135
		--"reave_additional_max_stacks" = 4
		--"base_attack_repeat_count" = 7
		mod("Speed", "MORE", 150, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = 150
		--"reave_additional_starting_stacks" = 4
		--"is_area_damage" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { nil, },
		[2] = { 1.2, },
		[3] = { 2.4, },
		[4] = { 3.6, },
		[5] = { 4.8, },
		[6] = { 6, },
		[7] = { 7.2, },
		[8] = { 8.4, },
		[9] = { 9.6, },
		[10] = { 10.8, },
		[11] = { 12, },
		[12] = { 13.2, },
		[13] = { 14.4, },
		[14] = { 15.6, },
		[15] = { 16.8, },
		[16] = { 18, },
		[17] = { 19.2, },
		[18] = { 20.4, },
		[19] = { 21.6, },
		[20] = { 22.8, },
		[21] = { 24, },
		[22] = { 25.2, },
		[23] = { 26.4, },
		[24] = { 27.6, },
		[25] = { 28.8, },
		[26] = { 30, },
		[27] = { 31.2, },
		[28] = { 32.4, },
		[29] = { 33.6, },
		[30] = { 34.8, },
	},
}
gems["Riposte"] = {
	trigger = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [24] = true, [25] = true, [6] = true, [47] = true, [57] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"melee_counterattack_trigger_on_block_%" = 100
		--"attack_unusable_if_triggerable" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"skill_double_hits_when_dual_wielding" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { nil, },
		[2] = { 2, },
		[3] = { 4, },
		[4] = { 6, },
		[5] = { 8, },
		[6] = { 10, },
		[7] = { 12, },
		[8] = { 14, },
		[9] = { 16, },
		[10] = { 18, },
		[11] = { 20, },
		[12] = { 22, },
		[13] = { 24, },
		[14] = { 26, },
		[15] = { 28, },
		[16] = { 30, },
		[17] = { 32, },
		[18] = { 34, },
		[19] = { 36, },
		[20] = { 38, },
		[21] = { 40, },
		[22] = { 42, },
		[23] = { 44, },
		[24] = { 46, },
		[25] = { 48, },
		[26] = { 50, },
		[27] = { 52, },
		[28] = { 54, },
		[29] = { 56, },
		[30] = { 58, },
	},
}
gems["Shrapnel Shot"] = {
	lightning = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	area = true,
	bow = true,
	parts = {
		{
			name = "Arrow",
			area = false,
		},
		{
			name = "Cone",
			area = true,
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		lightning = true,
	},
	skillTypes = { [1] = true, [3] = true, [11] = true, [22] = true, [17] = true, [19] = true, [35] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_arrow_pierce_%" = 100
		mod("Damage", "MORE", 0, ModFlag.Area), --"active_skill_area_damage_+%_final" = 0
		mod("PhysicalDamageConvertToLightning", "BASE", 40, 0, 0, nil), --"base_physical_damage_%_to_convert_to_lightning" = 40
		--"base_is_projectile" = ?
		--"skill_can_fire_arrows" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 6, -20, },
		[2] = { 6, -19, },
		[3] = { 6, -18, },
		[4] = { 7, -17, },
		[5] = { 7, -16, },
		[6] = { 7, -15, },
		[7] = { 7, -14, },
		[8] = { 8, -13, },
		[9] = { 8, -12, },
		[10] = { 8, -11, },
		[11] = { 8, -10, },
		[12] = { 8, -9, },
		[13] = { 9, -8, },
		[14] = { 9, -7, },
		[15] = { 9, -6, },
		[16] = { 9, -5, },
		[17] = { 9, -4, },
		[18] = { 10, -3, },
		[19] = { 10, -2, },
		[20] = { 10, -1, },
		[21] = { 10, nil, },
		[22] = { 10, 1, },
		[23] = { 11, 2, },
		[24] = { 11, 3, },
		[25] = { 11, 4, },
		[26] = { 11, 5, },
		[27] = { 11, 6, },
		[28] = { 12, 7, },
		[29] = { 12, 8, },
		[30] = { 12, 9, },
	},
}
gems["Siege Ballista"] = {
	totem = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	duration = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		totem = true,
		duration = true,
	},
	skillTypes = { [1] = true, [3] = true, [48] = true, [17] = true, [19] = true, [30] = true, [12] = true, },
	skillTotemId = 12,
	baseMods = {
		skill("castTime", 1), 
		mod("Speed", "MORE", -50, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -50
		--"base_arrow_pierce_%" = 100
		--"base_totem_range" = 80
		--"base_totem_duration" = 8000
		--"base_is_projectile" = ?
		--"base_skill_is_totemified" = ?
		--"is_totem" = ?
		--"skill_can_fire_arrows" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
	},
	qualityMods = {
		mod("TotemPlacementSpeed", "INC", 1), --"summon_totem_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = skill("totemLevel", nil), --"base_active_skill_totem_level"
	},
	levels = {
		[1] = { 8, 40, 4, },
		[2] = { 8, 41.6, 6, },
		[3] = { 8, 43.2, 9, },
		[4] = { 9, 44.8, 12, },
		[5] = { 9, 46.4, 16, },
		[6] = { 9, 48, 20, },
		[7] = { 9, 49.6, 24, },
		[8] = { 9, 51.2, 28, },
		[9] = { 9, 52.8, 32, },
		[10] = { 10, 54.4, 36, },
		[11] = { 10, 56, 40, },
		[12] = { 10, 57.6, 44, },
		[13] = { 10, 59.2, 48, },
		[14] = { 10, 60.8, 52, },
		[15] = { 11, 62.4, 55, },
		[16] = { 11, 64, 58, },
		[17] = { 12, 65.6, 61, },
		[18] = { 12, 67.2, 64, },
		[19] = { 12, 68.8, 67, },
		[20] = { 13, 70.4, 70, },
		[21] = { 13, 72, 72, },
		[22] = { 13, 73.6, 74, },
		[23] = { 14, 75.2, 76, },
		[24] = { 14, 76.8, 78, },
		[25] = { 14, 78.4, 80, },
		[26] = { 14, 80, 82, },
		[27] = { 14, 81.6, 84, },
		[28] = { 14, 83.2, 86, },
		[29] = { 15, 84.8, 88, },
		[30] = { 15, 86.4, 90, },
	},
}
gems["Smoke Mine"] = {
	mine = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	movement = true,
	color = 2,
	baseFlags = {
		spell = true,
		mine = true,
		area = true,
		duration = true,
		movement = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [38] = true, [41] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"base_mine_duration" = 16000
		mod("MovementSpeed", "INC", 30, 0, 0, nil), --"base_movement_velocity_+%" = 30
		--"is_remote_mine" = ?
		--"base_skill_is_mined" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 6, 4, },
		[2] = { 6, 4.1, },
		[3] = { 7, 4.2, },
		[4] = { 7, 4.3, },
		[5] = { 8, 4.4, },
		[6] = { 8, 4.5, },
		[7] = { 9, 4.6, },
		[8] = { 9, 4.7, },
		[9] = { 9, 4.8, },
		[10] = { 10, 4.9, },
		[11] = { 10, 5, },
		[12] = { 10, 5.1, },
		[13] = { 10, 5.2, },
		[14] = { 11, 5.3, },
		[15] = { 11, 5.4, },
		[16] = { 11, 5.5, },
		[17] = { 12, 5.6, },
		[18] = { 12, 5.7, },
		[19] = { 12, 5.8, },
		[20] = { 13, 5.9, },
		[21] = { 13, 6, },
		[22] = { 13, 6.1, },
		[23] = { 14, 6.2, },
		[24] = { 14, 6.3, },
		[25] = { 14, 6.4, },
		[26] = { 14, 6.5, },
		[27] = { 14, 6.6, },
		[28] = { 14, 6.7, },
		[29] = { 15, 6.8, },
		[30] = { 15, 6.9, },
	},
}
gems["Spectral Throw"] = {
	projectile = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_is_projectile" = ?
		mod("PierceChance", "BASE", 100), 
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 7, -46, },
		[2] = { 7, -44, },
		[3] = { 7, -42.1, },
		[4] = { 7, -40.2, },
		[5] = { 7, -38.3, },
		[6] = { 7, -36.4, },
		[7] = { 7, -34.4, },
		[8] = { 7, -32.5, },
		[9] = { 7, -30.6, },
		[10] = { 7, -28.7, },
		[11] = { 8, -26.8, },
		[12] = { 8, -24.8, },
		[13] = { 8, -22.9, },
		[14] = { 8, -21, },
		[15] = { 8, -19.1, },
		[16] = { 9, -17.2, },
		[17] = { 9, -15.2, },
		[18] = { 9, -13.3, },
		[19] = { 9, -11.4, },
		[20] = { 9, -9.5, },
		[21] = { 10, -7.6, },
		[22] = { 10, -5.6, },
		[23] = { 10, -3.7, },
		[24] = { 10, -1.8, },
		[25] = { 10, nil, },
		[26] = { 10, 2, },
		[27] = { 10, 3.9, },
		[28] = { 10, 5.8, },
		[29] = { 10, 7.7, },
		[30] = { 10, 9.6, },
	},
}
gems["Vaal Spectral Throw"] = {
	projectile = true,
	dexterity = true,
	active_skill = true,
	vaal = true,
	attack = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [43] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"projectiles_nova" = ?
		--"base_is_projectile" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -30, },
		[2] = { -28.2, },
		[3] = { -26.4, },
		[4] = { -24.6, },
		[5] = { -22.8, },
		[6] = { -21, },
		[7] = { -19.2, },
		[8] = { -17.4, },
		[9] = { -15.6, },
		[10] = { -13.8, },
		[11] = { -12, },
		[12] = { -10.2, },
		[13] = { -8.4, },
		[14] = { -6.6, },
		[15] = { -4.8, },
		[16] = { -3, },
		[17] = { -1.2, },
		[18] = { 0.6, },
		[19] = { 2.4, },
		[20] = { 4.2, },
		[21] = { 6, },
		[22] = { 7.8, },
		[23] = { 9.6, },
		[24] = { 11.4, },
		[25] = { 13.2, },
		[26] = { 15, },
		[27] = { 16.8, },
		[28] = { 18.6, },
		[29] = { 20.4, },
		[30] = { 22.2, },
	},
}
gems["Split Arrow"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [22] = true, [17] = true, [19] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("ProjectileCount", "BASE", nil), --"base_number_of_additional_arrows"
	},
	levels = {
		[1] = { 6, -10, 4, },
		[2] = { 6, -9, 4, },
		[3] = { 6, -8, 4, },
		[4] = { 7, -7, 4, },
		[5] = { 7, -6, 4, },
		[6] = { 7, -5, 4, },
		[7] = { 7, -4, 4, },
		[8] = { 8, -3, 5, },
		[9] = { 8, -2, 5, },
		[10] = { 8, -1, 5, },
		[11] = { 8, nil, 5, },
		[12] = { 8, 1, 5, },
		[13] = { 9, 2, 5, },
		[14] = { 9, 3, 5, },
		[15] = { 9, 4, 6, },
		[16] = { 9, 5, 6, },
		[17] = { 9, 6, 6, },
		[18] = { 10, 7, 6, },
		[19] = { 10, 8, 6, },
		[20] = { 10, 9, 6, },
		[21] = { 10, 10, 6, },
		[22] = { 10, 11, 7, },
		[23] = { 11, 12, 7, },
		[24] = { 11, 13, 7, },
		[25] = { 11, 14, 7, },
		[26] = { 11, 15, 7, },
		[27] = { 11, 16, 7, },
		[28] = { 12, 17, 7, },
		[29] = { 12, 18, 8, },
		[30] = { 12, 19, 8, },
	},
}
gems["Summon Ice Golem"] = {
	golem = true,
	dexterity = true,
	active_skill = true,
	cold = true,
	minion = true,
	spell = true,
	color = 2,
	baseFlags = {
		spell = true,
		minion = true,
		golem = true,
		cold = true,
	},
	skillTypes = { [36] = true, [34] = true, [19] = true, [9] = true, [21] = true, [26] = true, [2] = true, [18] = true, [17] = true, [49] = true, [60] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_number_of_golems_allowed" = 1
		--"display_minion_monster_type" = 6
		mod("Misc", "LIST", { type = "Condition", var = "HaveColdGolem" }, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), 
	},
	qualityMods = {
		mod("MinionLife", "INC", 1), --"minion_maximum_life_+%" = 1
		mod("Damage", "INC", 1, 0, KeywordFlag.Minion), --"minion_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "base_actor_scale_+%"
		[3] = mod("CritChance", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"ice_golem_grants_critical_strike_chance_+%"
		[4] = mod("Accuracy", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"ice_golem_grants_accuracy_+%"
		[5] = mod("MinionLife", "INC", nil), --"minion_maximum_life_+%"
		--[6] = "display_minion_monster_level"
	},
	levels = {
		[1] = { 30, 0, 20, 20, 30, 34, },
		[2] = { 32, 1, 21, 21, 32, 36, },
		[3] = { 34, 1, 21, 21, 34, 38, },
		[4] = { 36, 2, 22, 22, 36, 40, },
		[5] = { 38, 2, 22, 22, 38, 42, },
		[6] = { 40, 3, 23, 23, 40, 44, },
		[7] = { 42, 3, 23, 23, 42, 46, },
		[8] = { 44, 4, 24, 24, 44, 48, },
		[9] = { 44, 4, 24, 24, 46, 50, },
		[10] = { 46, 5, 25, 25, 48, 52, },
		[11] = { 48, 5, 25, 25, 50, 54, },
		[12] = { 48, 6, 26, 26, 52, 56, },
		[13] = { 50, 6, 26, 26, 54, 58, },
		[14] = { 50, 7, 27, 27, 56, 60, },
		[15] = { 52, 7, 27, 27, 58, 62, },
		[16] = { 52, 8, 28, 28, 60, 64, },
		[17] = { 52, 8, 28, 28, 62, 66, },
		[18] = { 52, 9, 29, 29, 64, 68, },
		[19] = { 54, 9, 29, 29, 66, 69, },
		[20] = { 54, 10, 30, 30, 68, 70, },
		[21] = { 56, 10, 30, 30, 70, 72, },
		[22] = { 56, 11, 31, 31, 72, 74, },
		[23] = { 58, 11, 31, 31, 74, 76, },
		[24] = { 58, 12, 32, 32, 76, 78, },
		[25] = { 60, 12, 32, 32, 78, 80, },
		[26] = { 60, 13, 33, 33, 80, 82, },
		[27] = { 60, 13, 33, 33, 82, 84, },
		[28] = { 60, 14, 34, 34, 84, 86, },
		[29] = { 62, 14, 34, 34, 86, 88, },
		[30] = { 62, 15, 35, 35, 88, 90, },
	},
}
gems["Temporal Chains"] = {
	curse = true,
	dexterity = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 2,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		mod("BuffExpireFaster", "MORE", -40, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"buff_time_passed_-%" = 40
		--"curse_effect_+%_vs_players" = -40
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		--"temporal_chains_action_speed_+%_final" = -0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
		--[4] = "temporal_chains_action_speed_+%_final"
	},
	levels = {
		[1] = { 24, 5, 0, -20, },
		[2] = { 26, 5.05, 2, -20, },
		[3] = { 27, 5.1, 4, -21, },
		[4] = { 29, 5.15, 6, -21, },
		[5] = { 30, 5.2, 8, -22, },
		[6] = { 32, 5.25, 10, -22, },
		[7] = { 34, 5.3, 12, -23, },
		[8] = { 35, 5.35, 14, -23, },
		[9] = { 37, 5.4, 16, -24, },
		[10] = { 38, 5.45, 18, -24, },
		[11] = { 39, 5.5, 20, -25, },
		[12] = { 40, 5.55, 22, -25, },
		[13] = { 42, 5.6, 24, -26, },
		[14] = { 43, 5.65, 26, -26, },
		[15] = { 44, 5.7, 28, -27, },
		[16] = { 45, 5.75, 30, -27, },
		[17] = { 46, 5.8, 32, -28, },
		[18] = { 47, 5.85, 34, -28, },
		[19] = { 48, 5.9, 36, -29, },
		[20] = { 50, 5.95, 38, -29, },
		[21] = { 51, 6, 40, -30, },
		[22] = { 52, 6.05, 42, -30, },
		[23] = { 53, 6.1, 44, -31, },
		[24] = { 54, 6.15, 46, -31, },
		[25] = { 56, 6.2, 48, -32, },
		[26] = { 57, 6.25, 50, -32, },
		[27] = { 58, 6.3, 52, -33, },
		[28] = { 59, 6.35, 54, -33, },
		[29] = { 60, 6.4, 56, -34, },
		[30] = { 61, 6.45, 58, -34, },
	},
}
gems["Tornado Shot"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	bow = true,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [3] = true, [17] = true, [19] = true, [22] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"tornado_shot_num_of_secondary_projectiles" = 3
		--"base_is_projectile" = ?
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, ModFlag.Projectile), --"projectile_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 8, -10, },
		[2] = { 8, -9, },
		[3] = { 8, -8, },
		[4] = { 8, -7, },
		[5] = { 9, -6, },
		[6] = { 9, -5, },
		[7] = { 9, -4, },
		[8] = { 9, -3, },
		[9] = { 9, -2, },
		[10] = { 9, -1, },
		[11] = { 9, nil, },
		[12] = { 10, 1, },
		[13] = { 10, 2, },
		[14] = { 10, 3, },
		[15] = { 10, 4, },
		[16] = { 10, 5, },
		[17] = { 10, 6, },
		[18] = { 10, 7, },
		[19] = { 10, 8, },
		[20] = { 10, 9, },
		[21] = { 10, 10, },
		[22] = { 10, 11, },
		[23] = { 11, 12, },
		[24] = { 11, 13, },
		[25] = { 11, 14, },
		[26] = { 11, 15, },
		[27] = { 11, 16, },
		[28] = { 12, 17, },
		[29] = { 12, 18, },
		[30] = { 12, 19, },
	},
}
gems["Viper Strike"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	duration = true,
	melee = true,
	chaos = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [1] = true, [6] = true, [12] = true, [28] = true, [24] = true, [25] = true, [40] = true, [50] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 5), 
		mod("PhysicalDamageConvertToChaos", "BASE", 25, 0, 0, nil), --"base_physical_damage_%_to_convert_to_chaos" = 25
		mod("PoisonChance", "BASE", 100), --"base_chance_to_poison_on_hit_%" = 100
		skill("duration", 8), --"base_skill_effect_duration" = 8000
		skill("poisonDurationIsSkillDuration", true), --"poison_duration_is_skill_duration" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 30, },
		[2] = { 32.6, },
		[3] = { 35.2, },
		[4] = { 37.8, },
		[5] = { 40.4, },
		[6] = { 43, },
		[7] = { 45.6, },
		[8] = { 48.2, },
		[9] = { 50.8, },
		[10] = { 53.4, },
		[11] = { 56, },
		[12] = { 58.6, },
		[13] = { 61.2, },
		[14] = { 63.8, },
		[15] = { 66.4, },
		[16] = { 69, },
		[17] = { 71.6, },
		[18] = { 74.2, },
		[19] = { 76.8, },
		[20] = { 79.4, },
		[21] = { 82, },
		[22] = { 84.6, },
		[23] = { 87.2, },
		[24] = { 89.8, },
		[25] = { 92.4, },
		[26] = { 95, },
		[27] = { 97.6, },
		[28] = { 100.2, },
		[29] = { 102.8, },
		[30] = { 105.4, },
	},
}
gems["Whirling Blades"] = {
	dexterity = true,
	active_skill = true,
	attack = true,
	movement = true,
	melee = true,
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [24] = true, [38] = true, },
	baseMods = {
		skill("castTime", 2.6), 
		skill("manaCost", 15), 
		--"ignores_proximity_shield" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		skill("castTimeOverridesAttackTime", true), --"cast_time_overrides_attack_duration" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -20, },
		[2] = { -19, },
		[3] = { -18, },
		[4] = { -17, },
		[5] = { -16, },
		[6] = { -15, },
		[7] = { -14, },
		[8] = { -13, },
		[9] = { -12, },
		[10] = { -11, },
		[11] = { -10, },
		[12] = { -9, },
		[13] = { -8, },
		[14] = { -7, },
		[15] = { -6, },
		[16] = { -5, },
		[17] = { -4, },
		[18] = { -3, },
		[19] = { -2, },
		[20] = { -1, },
		[21] = { nil, },
		[22] = { 1, },
		[23] = { 2, },
		[24] = { 3, },
		[25] = { 4, },
		[26] = { 5, },
		[27] = { 6, },
		[28] = { 7, },
		[29] = { 8, },
		[30] = { 9, },
	},
}
gems["Wild Strike"] = {
	projectile = true,
	dexterity = true,
	active_skill = true,
	attack = true,
	melee = true,
	lightning = true,
	cold = true,
	fire = true,
	area = true,
	chaining = true,
	parts = {
		{
			name = "Fire hit",
			melee = true,
			projectile = false,
			chaining = false,
			area = false,
		},
		{
			name = "Fire explosion",
			melee = false,
			projectile = false,
			chaining = false,
			area = true,
		},
		{
			name = "Lightning hit",
			melee = true,
			projectile = false,
			chaining = false,
			area = false,
		},
		{
			name = "Lightning bolt",
			melee = false,
			projectile = false,
			chaining = true,
			area = false,
		},
		{
			name = "Cold hit",
			melee = true,
			projectile = false,
			chaining = false,
			area = false,
		},
		{
			name = "Icy wave",
			melee = false,
			projectile = true,
			chaining = false,
			area = false,
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		chaining = true,
		area = true,
		lightning = true,
		cold = true,
		fire = true,
	},
	skillTypes = { [1] = true, [6] = true, [25] = true, [28] = true, [24] = true, [35] = true, [34] = true, [33] = true, [3] = true, [11] = true, [23] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		--"elemental_strike_physical_damage_%_to_convert" = 60
		--"fixed_projectile_spread" = 70
		mod("ProjectileCount", "BASE", 2), --"number_of_additional_projectiles" = 2
		--"show_number_of_projectiles" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
		skill("PhysicalDamageConvertToFire", 60, { type = "SkillPart", skillPart = 1 }), 
		skill("PhysicalDamageConvertToFire", 60, { type = "SkillPart", skillPart = 2 }), 
		skill("PhysicalDamageConvertToLightning", 60, { type = "SkillPart", skillPart = 3 }), 
		skill("PhysicalDamageConvertToLightning", 60, { type = "SkillPart", skillPart = 4 }), 
		skill("PhysicalDamageConvertToCold", 60, { type = "SkillPart", skillPart = 5 }), 
		skill("PhysicalDamageConvertToCold", 60, { type = "SkillPart", skillPart = 6 }), 
	},
	qualityMods = {
		mod("ElementalDamage", "INC", 1), --"elemental_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("ChainCount", "BASE", nil), --"number_of_additional_projectiles_in_chain"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 30, 4, 0, },
		[2] = { 32.4, 4, 1, },
		[3] = { 34.8, 4, 2, },
		[4] = { 37.2, 4, 3, },
		[5] = { 39.6, 4, 4, },
		[6] = { 42, 4, 5, },
		[7] = { 44.4, 5, 6, },
		[8] = { 46.8, 5, 7, },
		[9] = { 49.2, 5, 8, },
		[10] = { 51.6, 5, 9, },
		[11] = { 54, 5, 10, },
		[12] = { 56.4, 5, 11, },
		[13] = { 58.8, 6, 12, },
		[14] = { 61.2, 6, 13, },
		[15] = { 63.6, 6, 14, },
		[16] = { 66, 6, 15, },
		[17] = { 68.4, 6, 16, },
		[18] = { 70.8, 6, 17, },
		[19] = { 73.2, 7, 18, },
		[20] = { 75.6, 7, 19, },
		[21] = { 78, 7, 20, },
		[22] = { 80.4, 7, 21, },
		[23] = { 82.8, 7, 22, },
		[24] = { 85.2, 7, 23, },
		[25] = { 87.6, 8, 24, },
		[26] = { 90, 8, 25, },
		[27] = { 92.4, 8, 26, },
		[28] = { 94.8, 8, 27, },
		[29] = { 97.2, 8, 28, },
		[30] = { 99.6, 8, 29, },
	},
}
