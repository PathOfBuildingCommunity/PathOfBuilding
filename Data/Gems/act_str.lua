-- Path of Building
--
-- Active Strength skills
-- Skill gem data (c) Grinding Gear Games
--
local gems, mod, flag, skill = ...

gems["Abyssal Cry"] = {
	warcry = true,
	strength = true,
	active_skill = true,
	area = true,
	duration = true,
	chaos = true,
	color = 1,
	baseFlags = {
	},
	skillTypes = { [11] = true, [12] = true, [50] = true, [10] = true, },
	baseMods = {
		skill("castTime", 0.25), 
		--"abyssal_cry_%_max_life_as_chaos_on_death" = 8
		skill("duration", 6), --"base_skill_effect_duration" = 6000
		--"damage_cannot_be_reflected" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"display_skill_deals_secondary_damage" = ?
		--"is_warcry" = ?
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "abyssal_cry_movement_velocity_+%_per_one_hundred_nearby_enemies"
		[3] = mod("MovementSpeed", "INC", nil, 0, 0, nil), --"base_movement_velocity_+%"
	},
	levels = {
		[1] = { 26, -60, -20, },
		[2] = { 28, -62, -20, },
		[3] = { 30, -62, -21, },
		[4] = { 32, -64, -21, },
		[5] = { 34, -66, -21, },
		[6] = { 36, -66, -22, },
		[7] = { 38, -68, -22, },
		[8] = { 40, -70, -22, },
		[9] = { 43, -70, -23, },
		[10] = { 45, -72, -23, },
		[11] = { 48, -74, -23, },
		[12] = { 49, -74, -24, },
		[13] = { 50, -76, -24, },
		[14] = { 51, -78, -24, },
		[15] = { 52, -78, -25, },
		[16] = { 53, -80, -25, },
		[17] = { 54, -82, -25, },
		[18] = { 54, -82, -26, },
		[19] = { 55, -84, -26, },
		[20] = { 56, -86, -26, },
		[21] = { 57, -86, -27, },
		[22] = { 58, -88, -27, },
		[23] = { 58, -90, -27, },
		[24] = { 59, -90, -28, },
		[25] = { 60, -92, -28, },
		[26] = { 61, -94, -28, },
		[27] = { 62, -94, -29, },
		[28] = { 62, -96, -29, },
		[29] = { 63, -98, -29, },
		[30] = { 64, -98, -30, },
	},
}
gems["Ancestral Protector"] = {
	totem = true,
	strength = true,
	active_skill = true,
	attack = true,
	duration = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		totem = true,
		duration = true,
	},
	skillTypes = { [1] = true, [30] = true, [12] = true, [6] = true, [25] = true, [24] = true, [17] = true, [19] = true, },
	skillTotemId = 13,
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 8), 
		--"base_totem_duration" = 12000
		--"base_totem_range" = 50
		--"melee_range_+" = 16
		--"ancestor_totem_parent_activiation_range" = 70
		mod("TotemPlacementSpeed", "INC", 50), --"summon_totem_cast_speed_+%" = 50
		--"base_skill_is_totemified" = ?
		--"is_totem" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, KeywordFlag.Totem), --"totem_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = skill("totemLevel", nil), --"base_active_skill_totem_level"
		[3] = mod("Speed", "MORE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"melee_ancestor_totem_grant_owner_attack_speed_+%_final"
	},
	levels = {
		[1] = { -20, 4, 10, },
		[2] = { -17.2, 6, 11, },
		[3] = { -14.4, 9, 11, },
		[4] = { -11.6, 12, 12, },
		[5] = { -8.8, 16, 12, },
		[6] = { -6, 20, 13, },
		[7] = { -3.2, 24, 13, },
		[8] = { -0.4, 28, 14, },
		[9] = { 2.4, 32, 14, },
		[10] = { 5.2, 36, 15, },
		[11] = { 8, 40, 15, },
		[12] = { 10.8, 44, 16, },
		[13] = { 13.6, 48, 16, },
		[14] = { 16.4, 52, 17, },
		[15] = { 19.2, 55, 17, },
		[16] = { 22, 58, 18, },
		[17] = { 24.8, 61, 18, },
		[18] = { 27.6, 64, 19, },
		[19] = { 30.4, 67, 19, },
		[20] = { 33.2, 70, 20, },
		[21] = { 36, 72, 20, },
		[22] = { 38.8, 74, 21, },
		[23] = { 41.6, 76, 21, },
		[24] = { 44.4, 78, 22, },
		[25] = { 47.2, 80, 22, },
		[26] = { 50, 82, 23, },
		[27] = { 52.8, 84, 23, },
		[28] = { 55.6, 86, 24, },
		[29] = { 58.4, 88, 24, },
		[30] = { 61.2, 90, 25, },
	},
}
gems["Ancestral Warchief"] = {
	totem = true,
	strength = true,
	active_skill = true,
	attack = true,
	duration = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		totem = true,
		duration = true,
	},
	skillTypes = { [1] = true, [30] = true, [12] = true, [6] = true, [24] = true, [17] = true, [19] = true, [11] = true, },
	skillTotemId = 13,
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 10), 
		--"base_totem_duration" = 12000
		--"base_totem_range" = 50
		--"ancestor_totem_parent_activiation_range" = 70
		mod("TotemPlacementSpeed", "INC", 50), --"summon_totem_cast_speed_+%" = 50
		--"totem_art_variation" = 2
		mod("Speed", "MORE", -10, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -10
		--"is_area_damage" = ?
		--"base_skill_is_totemified" = ?
		--"is_totem" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, KeywordFlag.Totem), --"totem_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = skill("totemLevel", nil), --"base_active_skill_totem_level"
		[3] = mod("Damage", "MORE", nil, ModFlag.Melee, 0, { type = "GlobalEffect", effectType = "Buff" }), --"slam_ancestor_totem_grant_owner_melee_damage_+%_final"
	},
	levels = {
		[1] = { 10, 28, 8, },
		[2] = { 11.2, 31, 8, },
		[3] = { 12.4, 34, 9, },
		[4] = { 13.6, 37, 10, },
		[5] = { 14.8, 40, 10, },
		[6] = { 16, 42, 10, },
		[7] = { 17.2, 44, 11, },
		[8] = { 18.4, 46, 12, },
		[9] = { 19.6, 48, 12, },
		[10] = { 20.8, 50, 12, },
		[11] = { 22, 52, 13, },
		[12] = { 23.2, 54, 14, },
		[13] = { 24.4, 56, 14, },
		[14] = { 25.6, 58, 14, },
		[15] = { 26.8, 60, 15, },
		[16] = { 28, 62, 16, },
		[17] = { 29.2, 64, 16, },
		[18] = { 30.4, 66, 16, },
		[19] = { 31.6, 68, 17, },
		[20] = { 32.8, 70, 18, },
		[21] = { 34, 72, 18, },
		[22] = { 35.2, 74, 18, },
		[23] = { 36.4, 76, 19, },
		[24] = { 37.6, 78, 20, },
		[25] = { 38.8, 80, 20, },
		[26] = { 40, 82, 20, },
		[27] = { 41.2, 84, 21, },
		[28] = { 42.4, 86, 22, },
		[29] = { 43.6, 88, 22, },
		[30] = { 44.8, 90, 22, },
	},
}
gems["Anger"] = {
	aura = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 50), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("FireMin", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_minimum_added_fire_damage"
		[2] = mod("FireMax", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_maximum_added_fire_damage"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("FireMin", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"spell_minimum_added_fire_damage"
		[5] = mod("FireMax", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"spell_maximum_added_fire_damage"
	},
	levels = {
		[1] = { 12, 21, 0, 10, 16, },
		[2] = { 14, 24, 3, 12, 19, },
		[3] = { 17, 28, 6, 14, 22, },
		[4] = { 19, 32, 9, 16, 26, },
		[5] = { 22, 37, 12, 18, 29, },
		[6] = { 25, 42, 15, 21, 33, },
		[7] = { 28, 47, 18, 24, 38, },
		[8] = { 32, 54, 21, 27, 43, },
		[9] = { 36, 61, 23, 30, 48, },
		[10] = { 39, 66, 25, 33, 53, },
		[11] = { 43, 71, 27, 35, 57, },
		[12] = { 46, 77, 29, 38, 61, },
		[13] = { 50, 83, 31, 41, 66, },
		[14] = { 54, 89, 33, 45, 71, },
		[15] = { 58, 96, 35, 48, 77, },
		[16] = { 62, 104, 36, 52, 83, },
		[17] = { 67, 111, 37, 56, 89, },
		[18] = { 72, 120, 38, 60, 96, },
		[19] = { 77, 129, 39, 64, 103, },
		[20] = { 83, 138, 40, 69, 110, },
		[21] = { 89, 148, 41, 74, 118, },
		[22] = { 95, 159, 42, 79, 127, },
		[23] = { 102, 170, 43, 85, 136, },
		[24] = { 109, 182, 44, 91, 146, },
		[25] = { 117, 195, 45, 97, 156, },
		[26] = { 125, 209, 46, 104, 167, },
		[27] = { 134, 223, 47, 112, 178, },
		[28] = { 143, 238, 48, 119, 191, },
		[29] = { 153, 255, 49, 127, 204, },
		[30] = { 163, 272, 50, 136, 218, },
	},
}
gems["Animate Guardian"] = {
	strength = true,
	active_skill = true,
	spell = true,
	minion = true,
	unsupported = true,
}
gems["Cleave"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [8] = true, [11] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		--"cleave_damage_+%_final_while_dual_wielding" = -40
		--"is_area_damage" = ?
		--"skill_double_hits_when_dual_wielding" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 10, 0, },
		[2] = { 12.8, 1, },
		[3] = { 15.6, 2, },
		[4] = { 18.4, 3, },
		[5] = { 21.2, 4, },
		[6] = { 24, 5, },
		[7] = { 26.8, 6, },
		[8] = { 29.6, 7, },
		[9] = { 32.4, 8, },
		[10] = { 35.2, 9, },
		[11] = { 38, 10, },
		[12] = { 40.8, 11, },
		[13] = { 43.6, 12, },
		[14] = { 46.4, 13, },
		[15] = { 49.2, 14, },
		[16] = { 52, 15, },
		[17] = { 54.8, 16, },
		[18] = { 57.6, 17, },
		[19] = { 60.4, 18, },
		[20] = { 63.2, 19, },
		[21] = { 66, 20, },
		[22] = { 68.8, 21, },
		[23] = { 71.6, 22, },
		[24] = { 74.4, 23, },
		[25] = { 77.2, 24, },
		[26] = { 80, 25, },
		[27] = { 82.8, 26, },
		[28] = { 85.6, 27, },
		[29] = { 88.4, 28, },
		[30] = { 91.2, 29, },
	},
}
gems["Decoy Totem"] = {
	totem = true,
	strength = true,
	active_skill = true,
	spell = true,
	duration = true,
	area = true,
	color = 1,
	baseFlags = {
		spell = true,
		totem = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [17] = true, [12] = true, [19] = true, [11] = true, [30] = true, [26] = true, },
	skillTotemId = 6,
	baseMods = {
		skill("castTime", 1), 
		--"is_totem" = 1
		--"base_totem_duration" = 8000
		--"base_totem_range" = 60
		--"base_skill_is_totemified" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("TotemLife", "INC", 1), --"totem_life_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("totemLevel", nil), --"base_active_skill_totem_level"
		[3] = mod("TotemLife", "INC", nil), --"totem_life_+%"
	},
	levels = {
		[1] = { 9, 4, 0, },
		[2] = { 10, 6, 2, },
		[3] = { 10, 9, 4, },
		[4] = { 12, 12, 6, },
		[5] = { 14, 15, 8, },
		[6] = { 17, 19, 10, },
		[7] = { 18, 23, 12, },
		[8] = { 19, 28, 14, },
		[9] = { 21, 33, 16, },
		[10] = { 24, 39, 18, },
		[11] = { 26, 43, 20, },
		[12] = { 28, 46, 22, },
		[13] = { 30, 49, 24, },
		[14] = { 30, 52, 26, },
		[15] = { 31, 55, 28, },
		[16] = { 33, 58, 30, },
		[17] = { 34, 61, 32, },
		[18] = { 34, 64, 34, },
		[19] = { 34, 66, 36, },
		[20] = { 35, 68, 38, },
		[21] = { 36, 70, 40, },
		[22] = { 37, 72, 42, },
		[23] = { 37, 74, 44, },
		[24] = { 38, 76, 46, },
		[25] = { 38, 78, 48, },
		[26] = { 39, 80, 50, },
		[27] = { 40, 82, 52, },
		[28] = { 40, 84, 54, },
		[29] = { 41, 86, 56, },
		[30] = { 42, 88, 58, },
	},
}
gems["Determination"] = {
	aura = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 1,
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
		[1] = mod("Armour", "MORE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"determination_aura_armour_+%_final"
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 32, 0, },
		[2] = { 33, 3, },
		[3] = { 34, 6, },
		[4] = { 35, 9, },
		[5] = { 36, 12, },
		[6] = { 37, 15, },
		[7] = { 38, 18, },
		[8] = { 39, 21, },
		[9] = { 40, 23, },
		[10] = { 41, 25, },
		[11] = { 42, 27, },
		[12] = { 43, 29, },
		[13] = { 44, 31, },
		[14] = { 45, 33, },
		[15] = { 46, 35, },
		[16] = { 47, 36, },
		[17] = { 48, 37, },
		[18] = { 49, 38, },
		[19] = { 50, 39, },
		[20] = { 51, 40, },
		[21] = { 52, 41, },
		[22] = { 53, 42, },
		[23] = { 54, 43, },
		[24] = { 55, 44, },
		[25] = { 56, 45, },
		[26] = { 57, 46, },
		[27] = { 58, 47, },
		[28] = { 59, 48, },
		[29] = { 60, 49, },
		[30] = { 61, 50, },
	},
}
gems["Devouring Totem"] = {
	totem = true,
	strength = true,
	active_skill = true,
	spell = true,
	duration = true,
	unsupported = true,
}
gems["Dominating Blow"] = {
	strength = true,
	active_skill = true,
	attack = true,
	minion = true,
	duration = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		duration = true,
	},
	skillTypes = { [1] = true, [6] = true, [9] = true, [12] = true, [21] = true, [25] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("duration", 20), --"base_skill_effect_duration" = 20000
		--"active_skill_minion_damage_+%_final" = -35
		--"is_dominated" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 0.5, 0, 0, nil), --"damage_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 12, 25, },
		[2] = { 12, 27.1, },
		[3] = { 12, 29.2, },
		[4] = { 13, 31.3, },
		[5] = { 13, 33.4, },
		[6] = { 13, 35.5, },
		[7] = { 14, 37.6, },
		[8] = { 14, 39.7, },
		[9] = { 14, 41.8, },
		[10] = { 14, 43.9, },
		[11] = { 14, 46, },
		[12] = { 15, 48.1, },
		[13] = { 15, 50.2, },
		[14] = { 15, 52.3, },
		[15] = { 15, 54.4, },
		[16] = { 15, 56.5, },
		[17] = { 15, 58.6, },
		[18] = { 15, 60.7, },
		[19] = { 15, 62.8, },
		[20] = { 16, 64.9, },
		[21] = { 16, 67, },
		[22] = { 16, 69.1, },
		[23] = { 16, 71.2, },
		[24] = { 16, 73.3, },
		[25] = { 16, 75.4, },
		[26] = { 17, 77.5, },
		[27] = { 17, 79.6, },
		[28] = { 17, 81.7, },
		[29] = { 17, 83.8, },
		[30] = { 17, 85.9, },
	},
}
gems["Earthquake"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	duration = true,
	melee = true,
	parts = {
		{
			name = "Initial impact",
		},
		{
			name = "Aftershock",
		},
	},
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		duration = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [24] = true, [7] = true, [10] = true, [28] = true, [12] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 10), 
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		mod("Damage", "MORE", 50, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"quake_slam_fully_charged_explosion_damage_+%_final" = 50
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("PhysicalDamage", "INC", 1), --"physical_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -10, },
		[2] = { -9, },
		[3] = { -8, },
		[4] = { -7, },
		[5] = { -6, },
		[6] = { -5, },
		[7] = { -4, },
		[8] = { -3, },
		[9] = { -2, },
		[10] = { -1, },
		[11] = { nil, },
		[12] = { 1, },
		[13] = { 2, },
		[14] = { 3, },
		[15] = { 4, },
		[16] = { 5, },
		[17] = { 6, },
		[18] = { 7, },
		[19] = { 8, },
		[20] = { 9, },
		[21] = { 10, },
		[22] = { 11, },
		[23] = { 12, },
		[24] = { 13, },
		[25] = { 14, },
		[26] = { 15, },
		[27] = { 16, },
		[28] = { 17, },
		[29] = { 18, },
		[30] = { 19, },
	},
}
gems["Enduring Cry"] = {
	warcry = true,
	strength = true,
	active_skill = true,
	area = true,
	duration = true,
	color = 1,
	baseFlags = {
		warcry = true,
		area = true,
		duration = true,
	},
	skillTypes = { [5] = true, [11] = true, [12] = true, },
	baseMods = {
		skill("castTime", 0.25), 
		skill("duration", 0.75), --"base_skill_effect_duration" = 750
		--"is_warcry" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 3), --"base_skill_area_of_effect_+%" = 3
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "endurance_charges_granted_per_one_hundred_nearby_enemies_during_endurance_warcry"
		[3] = mod("LifeRegen", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_life_regeneration_rate_per_minute"
	},
	levels = {
		[1] = { 17, 8, 48, },
		[2] = { 17, 10, 62, },
		[3] = { 17, 12, 76, },
		[4] = { 17, 14, 94, },
		[5] = { 18, 16, 108, },
		[6] = { 18, 18, 122, },
		[7] = { 18, 20, 140, },
		[8] = { 19, 22, 158, },
		[9] = { 19, 24, 176, },
		[10] = { 19, 26, 196, },
		[11] = { 20, 27, 216, },
		[12] = { 20, 28, 238, },
		[13] = { 20, 29, 262, },
		[14] = { 20, 30, 286, },
		[15] = { 20, 31, 302, },
		[16] = { 21, 32, 320, },
		[17] = { 21, 33, 338, },
		[18] = { 21, 34, 356, },
		[19] = { 21, 35, 374, },
		[20] = { 21, 36, 394, },
		[21] = { 22, 37, 414, },
		[22] = { 22, 38, 434, },
		[23] = { 22, 39, 454, },
		[24] = { 22, 40, 476, },
		[25] = { 22, 41, 498, },
		[26] = { 23, 42, 520, },
		[27] = { 23, 43, 544, },
		[28] = { 23, 44, 566, },
		[29] = { 23, 45, 590, },
		[30] = { 23, 46, 614, },
	},
}
gems["Flame Totem"] = {
	projectile = true,
	totem = true,
	strength = true,
	active_skill = true,
	spell = true,
	duration = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		totem = true,
		projectile = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [12] = true, [17] = true, [19] = true, [30] = true, [33] = true, },
	skillTotemId = 8,
	baseMods = {
		skill("castTime", 0.25), 
		skill("damageEffectiveness", 0.25), 
		skill("critChance", 5), 
		--"base_totem_duration" = 8000
		--"base_totem_range" = 100
		--"is_totem" = ?
		--"base_skill_is_totemified" = ?
		--"base_is_projectile" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
	},
	qualityMods = {
		mod("TotemLife", "INC", 1), --"totem_life_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("totemLevel", nil), --"base_active_skill_totem_level"
		[3] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[4] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[5] = mod("ProjectileCount", "BASE", nil), --"number_of_additional_projectiles"
	},
	levels = {
		[1] = { 12, 4, 1, 2, 0, },
		[2] = { 14, 6, 1, 3, 0, },
		[3] = { 16, 9, 2, 4, 0, },
		[4] = { 17, 12, 3, 5, 0, },
		[5] = { 19, 16, 4, 7, 1, },
		[6] = { 21, 20, 6, 10, 1, },
		[7] = { 23, 24, 9, 13, 1, },
		[8] = { 24, 28, 11, 17, 1, },
		[9] = { 26, 32, 14, 22, 2, },
		[10] = { 29, 36, 18, 28, 2, },
		[11] = { 31, 40, 24, 35, 2, },
		[12] = { 32, 44, 30, 45, 2, },
		[13] = { 33, 48, 37, 56, 2, },
		[14] = { 34, 52, 47, 70, 2, },
		[15] = { 36, 55, 55, 83, 2, },
		[16] = { 37, 58, 65, 97, 2, },
		[17] = { 39, 61, 76, 114, 2, },
		[18] = { 40, 64, 89, 134, 2, },
		[19] = { 41, 67, 105, 157, 2, },
		[20] = { 42, 70, 122, 183, 2, },
		[21] = { 43, 72, 136, 203, 2, },
		[22] = { 44, 74, 150, 225, 2, },
		[23] = { 45, 76, 166, 249, 2, },
		[24] = { 46, 78, 184, 276, 2, },
		[25] = { 47, 80, 204, 305, 2, },
		[26] = { 48, 82, 225, 338, 2, },
		[27] = { 49, 84, 249, 373, 2, },
		[28] = { 50, 86, 275, 412, 2, },
		[29] = { 51, 88, 303, 455, 2, },
		[30] = { 52, 90, 335, 502, 2, },
	},
}
gems["Glacial Hammer"] = {
	strength = true,
	active_skill = true,
	attack = true,
	melee = true,
	cold = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		cold = true,
	},
	skillTypes = { [1] = true, [6] = true, [25] = true, [28] = true, [24] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 5), 
		skill("PhysicalDamageConvertToCold", 50), --"skill_physical_damage_%_to_convert_to_cold" = 50
		mod("EnemyFreezeChance", "BASE", 25), --"base_chance_to_freeze_%" = 25
		mod("EnemyChillDuration", "INC", 35), --"chill_duration_+%" = 35
	},
	qualityMods = {
		mod("EnemyChillDuration", "INC", 2), --"chill_duration_+%" = 2
		mod("EnemyFreezeDuration", "INC", 1), --"freeze_duration_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 40, },
		[2] = { 42.2, },
		[3] = { 44.4, },
		[4] = { 46.6, },
		[5] = { 48.8, },
		[6] = { 51, },
		[7] = { 53.2, },
		[8] = { 55.4, },
		[9] = { 57.6, },
		[10] = { 59.8, },
		[11] = { 62, },
		[12] = { 64.2, },
		[13] = { 66.4, },
		[14] = { 68.6, },
		[15] = { 70.8, },
		[16] = { 73, },
		[17] = { 75.2, },
		[18] = { 77.4, },
		[19] = { 79.6, },
		[20] = { 81.8, },
		[21] = { 84, },
		[22] = { 86.2, },
		[23] = { 88.4, },
		[24] = { 90.6, },
		[25] = { 92.8, },
		[26] = { 95, },
		[27] = { 97.2, },
		[28] = { 99.4, },
		[29] = { 101.6, },
		[30] = { 103.8, },
	},
}
gems["Vaal Glacial Hammer"] = {
	strength = true,
	active_skill = true,
	vaal = true,
	attack = true,
	melee = true,
	duration = true,
	area = true,
	cold = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		duration = true,
		cold = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [25] = true, [28] = true, [24] = true, [12] = true, [11] = true, [43] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("PhysicalDamageConvertToCold", 50), --"skill_physical_damage_%_to_convert_to_cold" = 50
		mod("EnemyFreezeChance", "BASE", 25), --"base_chance_to_freeze_%" = 25
		mod("EnemyChillDuration", "INC", 35), --"chill_duration_+%" = 35
	},
	qualityMods = {
		mod("EnemyChillDuration", "INC", 2), --"chill_duration_+%" = 2
		mod("EnemyFreezeDuration", "INC", 1), --"freeze_duration_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 50, 3.4, },
		[2] = { 51.8, 3.45, },
		[3] = { 53.6, 3.5, },
		[4] = { 55.4, 3.55, },
		[5] = { 57.2, 3.6, },
		[6] = { 59, 3.65, },
		[7] = { 60.8, 3.7, },
		[8] = { 62.6, 3.75, },
		[9] = { 64.4, 3.8, },
		[10] = { 66.2, 3.85, },
		[11] = { 68, 3.9, },
		[12] = { 69.8, 3.95, },
		[13] = { 71.6, 4, },
		[14] = { 73.4, 4.05, },
		[15] = { 75.2, 4.1, },
		[16] = { 77, 4.15, },
		[17] = { 78.8, 4.2, },
		[18] = { 80.6, 4.25, },
		[19] = { 82.4, 4.3, },
		[20] = { 84.2, 4.35, },
		[21] = { 86, 4.4, },
		[22] = { 87.8, 4.45, },
		[23] = { 89.6, 4.5, },
		[24] = { 91.4, 4.55, },
		[25] = { 93.2, 4.6, },
		[26] = { 95, 4.65, },
		[27] = { 96.8, 4.7, },
		[28] = { 98.6, 4.75, },
		[29] = { 100.4, 4.8, },
		[30] = { 102.2, 4.85, },
	},
}
gems["Ground Slam"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [11] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		mod("EnemyStunThreshold", "INC", -25), --"base_stun_threshold_reduction_+%" = 25
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("EnemyStunDuration", "INC", 1.5), --"base_stun_duration_+%" = 1.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { -10, 0, },
		[2] = { -8.4, 1, },
		[3] = { -6.8, 2, },
		[4] = { -5.2, 3, },
		[5] = { -3.6, 4, },
		[6] = { -2, 5, },
		[7] = { -0.4, 6, },
		[8] = { 1.2, 7, },
		[9] = { 2.8, 8, },
		[10] = { 4.4, 9, },
		[11] = { 6, 10, },
		[12] = { 7.6, 11, },
		[13] = { 9.2, 12, },
		[14] = { 10.8, 13, },
		[15] = { 12.4, 14, },
		[16] = { 14, 15, },
		[17] = { 15.6, 16, },
		[18] = { 17.2, 17, },
		[19] = { 18.8, 18, },
		[20] = { 20.4, 19, },
		[21] = { 22, 20, },
		[22] = { 23.6, 21, },
		[23] = { 25.2, 22, },
		[24] = { 26.8, 23, },
		[25] = { 28.4, 24, },
		[26] = { 30, 25, },
		[27] = { 31.6, 26, },
		[28] = { 33.2, 27, },
		[29] = { 34.8, 28, },
		[30] = { 36.4, 29, },
	},
}
gems["Vaal Ground Slam"] = {
	strength = true,
	active_skill = true,
	vaal = true,
	attack = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [11] = true, [28] = true, [24] = true, [43] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"knockback_distance_+%" = 100
		--"animation_effect_variation" = -1
		mod("AreaRadius", "INC", 20), --"base_skill_area_of_effect_+%" = 20
		--"always_stun" = ?
		--"global_knockback" = ?
		--"is_area_damage" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("EnemyStunDuration", "INC", 1.5), --"base_stun_duration_+%" = 1.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 60, },
		[2] = { 62, },
		[3] = { 64, },
		[4] = { 66, },
		[5] = { 68, },
		[6] = { 70, },
		[7] = { 72, },
		[8] = { 74, },
		[9] = { 76, },
		[10] = { 78, },
		[11] = { 80, },
		[12] = { 82, },
		[13] = { 84, },
		[14] = { 86, },
		[15] = { 88, },
		[16] = { 90, },
		[17] = { 92, },
		[18] = { 94, },
		[19] = { 96, },
		[20] = { 98, },
		[21] = { 100, },
		[22] = { 102, },
		[23] = { 104, },
		[24] = { 106, },
		[25] = { 108, },
		[26] = { 110, },
		[27] = { 112, },
		[28] = { 114, },
		[29] = { 116, },
		[30] = { 118, },
	},
}
gems["Heavy Strike"] = {
	strength = true,
	active_skill = true,
	attack = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [6] = true, [25] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 5), 
		--"global_knockback" = 1
		mod("EnemyStunThreshold", "INC", -25), --"base_stun_threshold_reduction_+%" = 25
	},
	qualityMods = {
		mod("EnemyStunDuration", "INC", 1), --"base_stun_duration_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 50, },
		[2] = { 52.3, },
		[3] = { 54.6, },
		[4] = { 56.9, },
		[5] = { 59.2, },
		[6] = { 61.5, },
		[7] = { 63.8, },
		[8] = { 66.1, },
		[9] = { 68.4, },
		[10] = { 70.7, },
		[11] = { 73, },
		[12] = { 75.3, },
		[13] = { 77.6, },
		[14] = { 79.9, },
		[15] = { 82.2, },
		[16] = { 84.5, },
		[17] = { 86.8, },
		[18] = { 89.1, },
		[19] = { 91.4, },
		[20] = { 93.7, },
		[21] = { 96, },
		[22] = { 98.3, },
		[23] = { 100.6, },
		[24] = { 102.9, },
		[25] = { 105.2, },
		[26] = { 107.5, },
		[27] = { 109.8, },
		[28] = { 112.1, },
		[29] = { 114.4, },
		[30] = { 116.7, },
	},
}
gems["Herald of Ash"] = {
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [5] = true, [15] = true, [16] = true, [29] = true, [11] = true, [40] = true, [20] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 25), 
		mod("PhysicalDamageGainAsFire", "BASE", 15, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"physical_damage_%_to_add_as_fire" = 15
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("FireDamage", "INC", 0.75, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"herald_of_ash_fire_damage_+%" = 0.75
	},
	levelMods = {
		--[1] = "herald_of_ash_%_overkill_dealt_as_ignite"
	},
	levels = {
		[1] = { 80, },
		[2] = { 83, },
		[3] = { 86, },
		[4] = { 89, },
		[5] = { 92, },
		[6] = { 95, },
		[7] = { 98, },
		[8] = { 101, },
		[9] = { 104, },
		[10] = { 107, },
		[11] = { 110, },
		[12] = { 113, },
		[13] = { 116, },
		[14] = { 119, },
		[15] = { 122, },
		[16] = { 125, },
		[17] = { 128, },
		[18] = { 131, },
		[19] = { 134, },
		[20] = { 137, },
		[21] = { 140, },
		[22] = { 143, },
		[23] = { 146, },
		[24] = { 149, },
		[25] = { 152, },
		[26] = { 155, },
		[27] = { 158, },
		[28] = { 161, },
		[29] = { 164, },
		[30] = { 167, },
	},
}
gems["Ice Crash"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	cold = true,
	melee = true,
	parts = {
		{
			name = "First Hit",
		},
		{
			name = "Second Hit",
		},
		{
			name = "Third Hit",
		},
	},
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		cold = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [24] = true, [7] = true, [34] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 8), 
		mod("PhysicalDamageConvertToCold", "BASE", 50, 0, 0, nil), --"base_physical_damage_%_to_convert_to_cold" = 50
		mod("Speed", "MORE", -20, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -20
		mod("Damage", "MORE", -15, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"ice_crash_second_hit_damage_+%_final" = -15
		mod("Damage", "MORE", -30, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 3 }), --"ice_crash_third_hit_damage_+%_final" = -30
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("ColdDamage", "INC", 1), --"cold_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 50, },
		[2] = { 51.8, },
		[3] = { 53.6, },
		[4] = { 55.4, },
		[5] = { 57.2, },
		[6] = { 59, },
		[7] = { 60.8, },
		[8] = { 62.6, },
		[9] = { 64.4, },
		[10] = { 66.2, },
		[11] = { 68, },
		[12] = { 69.8, },
		[13] = { 71.6, },
		[14] = { 73.4, },
		[15] = { 75.2, },
		[16] = { 77, },
		[17] = { 78.8, },
		[18] = { 80.6, },
		[19] = { 82.4, },
		[20] = { 84.2, },
		[21] = { 86, },
		[22] = { 87.8, },
		[23] = { 89.6, },
		[24] = { 91.4, },
		[25] = { 93.2, },
		[26] = { 95, },
		[27] = { 96.8, },
		[28] = { 98.6, },
		[29] = { 100.4, },
		[30] = { 102.2, },
	},
}
gems["Immortal Call"] = {
	strength = true,
	active_skill = true,
	spell = true,
	duration = true,
	color = 1,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [18] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("duration", 0.4), --"base_skill_effect_duration" = 400
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 2, ModFlag.Spell), --"base_cast_speed_+%" = 2
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Duration", "INC", nil, 0, 0, { type = "Multiplier", var = "EnduranceCharge" }), --"buff_effect_duration_+%_per_endurance_charge"
	},
	levels = {
		[1] = { 21, 100, },
		[2] = { 22, 103, },
		[3] = { 23, 106, },
		[4] = { 24, 109, },
		[5] = { 25, 112, },
		[6] = { 25, 115, },
		[7] = { 26, 118, },
		[8] = { 27, 121, },
		[9] = { 28, 124, },
		[10] = { 29, 127, },
		[11] = { 30, 130, },
		[12] = { 31, 133, },
		[13] = { 31, 136, },
		[14] = { 32, 139, },
		[15] = { 33, 142, },
		[16] = { 34, 145, },
		[17] = { 35, 148, },
		[18] = { 36, 151, },
		[19] = { 36, 154, },
		[20] = { 36, 157, },
		[21] = { 37, 160, },
		[22] = { 38, 163, },
		[23] = { 39, 166, },
		[24] = { 40, 169, },
		[25] = { 41, 172, },
		[26] = { 41, 175, },
		[27] = { 42, 178, },
		[28] = { 43, 181, },
		[29] = { 44, 184, },
		[30] = { 45, 187, },
	},
}
gems["Vaal Immortal Call"] = {
	strength = true,
	active_skill = true,
	vaal = true,
	spell = true,
	duration = true,
	color = 1,
	baseFlags = {
		spell = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [18] = true, [43] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("duration", 0.4), --"base_skill_effect_duration" = 400
		--"immortal_call_prevent_all_damage" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 2, ModFlag.Spell), --"base_cast_speed_+%" = 2
	},
	levelMods = {
		[1] = mod("Duration", "INC", nil, 0, 0, { type = "Multiplier", var = "EnduranceCharge" }), --"buff_effect_duration_+%_per_endurance_charge"
	},
	levels = {
		[1] = { 100, },
		[2] = { 103, },
		[3] = { 106, },
		[4] = { 109, },
		[5] = { 112, },
		[6] = { 115, },
		[7] = { 118, },
		[8] = { 121, },
		[9] = { 124, },
		[10] = { 127, },
		[11] = { 130, },
		[12] = { 133, },
		[13] = { 136, },
		[14] = { 139, },
		[15] = { 142, },
		[16] = { 145, },
		[17] = { 148, },
		[18] = { 151, },
		[19] = { 154, },
		[20] = { 157, },
		[21] = { 160, },
		[22] = { 163, },
		[23] = { 166, },
		[24] = { 169, },
		[25] = { 172, },
		[26] = { 175, },
		[27] = { 178, },
		[28] = { 181, },
		[29] = { 184, },
		[30] = { 187, },
	},
}
gems["Infernal Blow"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	fire = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		fire = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [25] = true, [28] = true, [24] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		skill("critChance", 5), 
		skill("PhysicalDamageConvertToFire", 50), --"skill_physical_damage_%_to_convert_to_fire" = 50
		skill("duration", 0.5), --"base_skill_effect_duration" = 500
		--"corpse_explosion_monster_life_%" = 10
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
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
gems["Leap Slam"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	movement = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [11] = true, [24] = true, [38] = true, },
	baseMods = {
		skill("castTime", 1.4), 
		skill("manaCost", 15), 
		--"base_global_chance_to_knockback_%" = 20
		--"is_area_damage" = ?
		skill("castTimeOverridesAttackTime", true), --"cast_time_overrides_attack_duration" = ?
	},
	qualityMods = {
		--"base_global_chance_to_knockback_%" = 0.5
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
gems["Molten Shell"] = {
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [18] = true, [31] = true, [36] = true, [26] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 2), 
		skill("critChance", 5), 
		mod("ElementalResist", "BASE", 0, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_resist_all_elements_%" = 0
		--"is_area_damage" = 1
		skill("duration", 10), --"base_skill_effect_duration" = 10000
		--"skill_override_pvp_scaling_time_ms" = 1200
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("EnemyIgniteChance", "BASE", 1), --"base_chance_to_ignite_%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		--[4] = "fire_shield_damage_threshold"
		[5] = mod("Armour", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_physical_damage_reduction_rating"
	},
	levels = {
		[1] = { 8, 14, 20, 26, 17, },
		[2] = { 9, 17, 26, 32, 20, },
		[3] = { 9, 24, 35, 41, 26, },
		[4] = { 10, 32, 47, 52, 33, },
		[5] = { 11, 45, 68, 70, 44, },
		[6] = { 12, 64, 96, 93, 58, },
		[7] = { 13, 88, 132, 120, 75, },
		[8] = { 14, 120, 180, 155, 97, },
		[9] = { 16, 161, 241, 197, 123, },
		[10] = { 17, 214, 321, 250, 156, },
		[11] = { 19, 283, 425, 313, 196, },
		[12] = { 20, 372, 558, 391, 245, },
		[13] = { 22, 486, 729, 487, 304, },
		[14] = { 23, 631, 947, 602, 376, },
		[15] = { 25, 766, 1149, 705, 440, },
		[16] = { 25, 928, 1392, 823, 515, },
		[17] = { 26, 1122, 1683, 960, 600, },
		[18] = { 27, 1354, 2031, 1118, 698, },
		[19] = { 27, 1631, 2447, 1299, 812, },
		[20] = { 28, 1962, 2943, 1508, 943, },
		[21] = { 29, 2217, 3326, 1664, 1040, },
		[22] = { 29, 2504, 3756, 1836, 1148, },
		[23] = { 29, 2827, 4240, 2024, 1265, },
		[24] = { 30, 3189, 4784, 2231, 1394, },
		[25] = { 30, 3596, 5394, 2457, 1536, },
		[26] = { 31, 4053, 6080, 2705, 1691, },
		[27] = { 31, 4566, 6849, 2977, 1861, },
		[28] = { 31, 5141, 7712, 3275, 2047, },
		[29] = { 32, 5787, 8680, 3601, 2251, },
		[30] = { 32, 6510, 9766, 3958, 2474, },
	},
}
gems["Vaal Molten Shell"] = {
	strength = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		fire = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [18] = true, [31] = true, [26] = true, [43] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 2), 
		skill("critChance", 5), 
		mod("ElementalResist", "BASE", 0, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_resist_all_elements_%" = 0
		--"is_area_damage" = 1
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"skill_override_pvp_scaling_time_ms" = 1400
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"molten_shell_explode_each_hit" = ?
	},
	qualityMods = {
		mod("EnemyIgniteChance", "BASE", 1), --"base_chance_to_ignite_%" = 1
	},
	levelMods = {
		[1] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[2] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[3] = mod("Armour", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_physical_damage_reduction_rating"
	},
	levels = {
		[1] = { 9, 14, 17, },
		[2] = { 11, 17, 20, },
		[3] = { 15, 23, 26, },
		[4] = { 20, 30, 33, },
		[5] = { 27, 41, 44, },
		[6] = { 37, 56, 58, },
		[7] = { 49, 74, 75, },
		[8] = { 64, 96, 97, },
		[9] = { 83, 124, 123, },
		[10] = { 106, 159, 156, },
		[11] = { 135, 202, 196, },
		[12] = { 170, 256, 245, },
		[13] = { 214, 321, 304, },
		[14] = { 267, 401, 376, },
		[15] = { 315, 472, 440, },
		[16] = { 370, 556, 515, },
		[17] = { 435, 652, 600, },
		[18] = { 509, 764, 698, },
		[19] = { 596, 893, 812, },
		[20] = { 696, 1043, 943, },
		[21] = { 771, 1156, 1040, },
		[22] = { 854, 1280, 1148, },
		[23] = { 945, 1417, 1265, },
		[24] = { 1045, 1568, 1394, },
		[25] = { 1155, 1733, 1536, },
		[26] = { 1277, 1915, 1691, },
		[27] = { 1410, 2115, 1861, },
		[28] = { 1557, 2335, 2047, },
		[29] = { 1718, 2577, 2251, },
		[30] = { 1895, 2843, 2474, },
	},
}
gems["Molten Strike"] = {
	projectile = true,
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	fire = true,
	parts = {
		{
			name = "Melee Hit",
			melee = true,
			projectile = false,
			area = false,
		},
		{
			name = "Magma Balls",
			melee = false,
			projectile = true,
			area = true,
		},
	},
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		area = true,
		fire = true,
	},
	skillTypes = { [1] = true, [3] = true, [6] = true, [11] = true, [24] = true, [25] = true, [28] = true, [33] = true, [48] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		skill("PhysicalDamageConvertToFire", 60), --"skill_physical_damage_%_to_convert_to_fire" = 60
		mod("ProjectileCount", "BASE", 2), --"number_of_additional_projectiles" = 2
		mod("Damage", "MORE", -40, ModFlag.Projectile), --"active_skill_projectile_damage_+%_final" = -40
		--"show_number_of_projectiles" = ?
	},
	qualityMods = {
		mod("FireDamage", "INC", 1), --"fire_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 20, },
		[2] = { 21.4, },
		[3] = { 22.8, },
		[4] = { 24.2, },
		[5] = { 25.6, },
		[6] = { 27, },
		[7] = { 28.4, },
		[8] = { 29.8, },
		[9] = { 31.2, },
		[10] = { 32.6, },
		[11] = { 34, },
		[12] = { 35.4, },
		[13] = { 36.8, },
		[14] = { 38.2, },
		[15] = { 39.6, },
		[16] = { 41, },
		[17] = { 42.4, },
		[18] = { 43.8, },
		[19] = { 45.2, },
		[20] = { 46.6, },
		[21] = { 48, },
		[22] = { 49.4, },
		[23] = { 50.8, },
		[24] = { 52.2, },
		[25] = { 53.6, },
		[26] = { 55, },
		[27] = { 56.4, },
		[28] = { 57.8, },
		[29] = { 59.2, },
		[30] = { 60.6, },
	},
}
gems["Punishment"] = {
	curse = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	unsupported = true,
}
gems["Purity of Fire"] = {
	aura = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 35), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("FireResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_fire_damage_resistance_%"
		[2] = mod("FireResistMax", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_fire_damage_resistance_%"
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
gems["Rallying Cry"] = {
	warcry = true,
	strength = true,
	active_skill = true,
	area = true,
	duration = true,
	color = 1,
	baseFlags = {
		warcry = true,
		area = true,
		duration = true,
	},
	skillTypes = { [5] = true, [11] = true, [12] = true, },
	baseMods = {
		skill("castTime", 0.25), 
		skill("duration", 8), --"base_skill_effect_duration" = 8000
		--"base_deal_no_damage" = ?
		--"is_warcry" = ?
	},
	qualityMods = {
		mod("Duration", "INC", 1.5), --"skill_effect_duration_+%" = 1.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "inspiring_cry_damage_+%_per_one_hundred_nearby_enemies"
		[3] = mod("Damage", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"damage_+%"
		[4] = mod("ManaRegen", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_mana_regeneration_rate_per_minute"
	},
	levels = {
		[1] = { 8, 140, 10, 1.8, },
		[2] = { 10, 142, 10, 2.4, },
		[3] = { 12, 144, 11, 3.1, },
		[4] = { 13, 146, 11, 3.8, },
		[5] = { 14, 148, 11, 4.4, },
		[6] = { 15, 150, 12, 5.1, },
		[7] = { 16, 152, 12, 5.8, },
		[8] = { 17, 154, 12, 6.5, },
		[9] = { 18, 156, 13, 7.1, },
		[10] = { 20, 158, 13, 7.8, },
		[11] = { 21, 160, 13, 8.5, },
		[12] = { 22, 162, 14, 9.2, },
		[13] = { 24, 164, 14, 9.9, },
		[14] = { 25, 166, 14, 10.6, },
		[15] = { 26, 168, 15, 11.3, },
		[16] = { 26, 170, 15, 12, },
		[17] = { 26, 172, 15, 12.7, },
		[18] = { 26, 174, 16, 13.4, },
		[19] = { 27, 176, 16, 14.1, },
		[20] = { 27, 178, 16, 14.8, },
		[21] = { 28, 180, 17, 15.5, },
		[22] = { 28, 182, 17, 16.2, },
		[23] = { 29, 184, 17, 16.9, },
		[24] = { 29, 186, 18, 17.7, },
		[25] = { 30, 188, 18, 18.4, },
		[26] = { 30, 190, 18, 19.1, },
		[27] = { 30, 192, 19, 19.8, },
		[28] = { 30, 194, 19, 20.5, },
		[29] = { 31, 196, 19, 21.3, },
		[30] = { 31, 198, 20, 22, },
	},
}
gems["Reckoning"] = {
	trigger = true,
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		area = true,
		melee = true,
	},
	skillTypes = { [1] = true, [7] = true, [13] = true, [24] = true, [11] = true, [47] = true, [57] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"melee_counterattack_trigger_on_block_%" = 100
		--"shield_counterattack_aoe_range" = 35
		--"attack_unusable_if_triggerable" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -30, },
		[2] = { -28, },
		[3] = { -26, },
		[4] = { -24, },
		[5] = { -22, },
		[6] = { -20, },
		[7] = { -18, },
		[8] = { -16, },
		[9] = { -14, },
		[10] = { -12, },
		[11] = { -10, },
		[12] = { -8, },
		[13] = { -6, },
		[14] = { -4, },
		[15] = { -2, },
		[16] = { nil, },
		[17] = { 2, },
		[18] = { 4, },
		[19] = { 6, },
		[20] = { 8, },
		[21] = { 10, },
		[22] = { 12, },
		[23] = { 14, },
		[24] = { 16, },
		[25] = { 18, },
		[26] = { 20, },
		[27] = { 22, },
		[28] = { 24, },
		[29] = { 26, },
		[30] = { 28, },
	},
}
gems["Rejuvenation Totem"] = {
	totem = true,
	aura = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 1,
	baseFlags = {
		spell = true,
		aura = true,
		totem = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [11] = true, [12] = true, [15] = true, [27] = true, [17] = true, [19] = true, [30] = true, [44] = true, },
	skillTotemId = 4,
	baseMods = {
		skill("castTime", 0.6), 
		--"is_totem" = 1
		--"base_totem_duration" = 8000
		--"base_totem_range" = 10
		--"base_skill_is_totemified" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 3, 0, KeywordFlag.Aura), --"base_aura_area_of_effect_+%" = 3
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("LifeRegen", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_life_regeneration_rate_per_minute"
		[3] = skill("totemLevel", nil), --"base_active_skill_totem_level"
	},
	levels = {
		[1] = { 13, 6.35, 4, },
		[2] = { 14, 8.6833333333333, 6, },
		[3] = { 15, 12.366666666667, 9, },
		[4] = { 16, 16, 12, },
		[5] = { 17, 21.033333333333, 16, },
		[6] = { 18, 26.3, 20, },
		[7] = { 19, 32.25, 24, },
		[8] = { 20, 39.366666666667, 28, },
		[9] = { 22, 46.116666666667, 32, },
		[10] = { 24, 53.7, 36, },
		[11] = { 26, 61.816666666667, 40, },
		[12] = { 27, 72.8, 44, },
		[13] = { 28, 82.716666666667, 48, },
		[14] = { 29, 92.666666666667, 52, },
		[15] = { 30, 102.85, 55, },
		[16] = { 30, 113.98333333333, 58, },
		[17] = { 31, 122.95, 61, },
		[18] = { 31, 135.6, 64, },
		[19] = { 32, 149.03333333333, 67, },
		[20] = { 32, 162.2, 70, },
		[21] = { 33, 168.61666666667, 72, },
		[22] = { 34, 177.03333333333, 74, },
		[23] = { 34, 182.1, 76, },
		[24] = { 35, 191.2, 78, },
		[25] = { 36, 200.66666666667, 80, },
		[26] = { 37, 206.03333333333, 82, },
		[27] = { 38, 217.43333333333, 84, },
		[28] = { 38, 227.95, 86, },
		[29] = { 39, 241.21666666667, 88, },
		[30] = { 40, 243.65, 90, },
	},
}
gems["Searing Bond"] = {
	totem = true,
	strength = true,
	active_skill = true,
	spell = true,
	duration = true,
	fire = true,
	color = 1,
	baseFlags = {
		spell = true,
		totem = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [40] = true, [12] = true, [17] = true, [19] = true, [27] = true, [29] = true, [30] = true, [36] = true, [33] = true, },
	skillTotemId = 9,
	baseMods = {
		skill("castTime", 1), 
		--"base_totem_duration" = 8000
		--"base_totem_range" = 100
		mod("ActiveTotemLimit", "BASE", 1), --"number_of_additional_totems_allowed" = 1
		--"is_totem" = ?
		--"base_skill_is_totemified" = ?
	},
	qualityMods = {
		mod("TotemLife", "INC", 1), --"totem_life_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("totemLevel", nil), --"base_active_skill_totem_level"
		[3] = skill("FireDot", nil), --"base_fire_damage_to_deal_per_minute"
	},
	levels = {
		[1] = { 18, 12, 23.583333333333, },
		[2] = { 19, 15, 31.35, },
		[3] = { 20, 19, 44.816666666667, },
		[4] = { 21, 23, 62.833333333333, },
		[5] = { 23, 27, 86.783333333333, },
		[6] = { 25, 31, 118.43333333333, },
		[7] = { 27, 35, 160.06666666667, },
		[8] = { 29, 38, 199.58333333333, },
		[9] = { 31, 41, 247.88333333333, },
		[10] = { 33, 44, 306.76666666667, },
		[11] = { 35, 47, 378.48333333333, },
		[12] = { 37, 50, 465.65, },
		[13] = { 39, 53, 571.45, },
		[14] = { 40, 56, 699.7, },
		[15] = { 42, 59, 854.93333333333, },
		[16] = { 44, 62, 1042.6166666667, },
		[17] = { 46, 64, 1188.95, },
		[18] = { 48, 66, 1354.8333333333, },
		[19] = { 50, 68, 1542.7666666667, },
		[20] = { 51, 70, 1755.6333333333, },
		[21] = { 53, 72, 1996.5833333333, },
		[22] = { 53, 74, 2269.2666666667, },
		[23] = { 54, 76, 2577.7166666667, },
		[24] = { 56, 78, 2926.5, },
		[25] = { 58, 80, 3320.75, },
		[26] = { 59, 82, 3766.2333333333, },
		[27] = { 59, 84, 4269.4666666667, },
		[28] = { 61, 86, 4837.7333333333, },
		[29] = { 62, 88, 5479.2333333333, },
		[30] = { 64, 90, 6203.2333333333, },
	},
}
gems["Shield Charge"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	movement = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		movement = true,
	},
	skillTypes = { [1] = true, [7] = true, [13] = true, [24] = true, [11] = true, [38] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 8), 
		--"shield_charge_scaling_stun_threshold_reduction_+%_at_maximum_range" = 50
		mod("MovementSpeed", "INC", 75, 0, 0, nil), --"base_movement_velocity_+%" = 75
		--"shield_charge_damage_+%_maximum" = 200
		mod("Damage", "MORE", -50, ModFlag.Hit), --"active_skill_damage_+%_final" = -50
		--"ignores_proximity_shield" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
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
gems["Shockwave Totem"] = {
	totem = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 1,
	baseFlags = {
		spell = true,
		totem = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [19] = true, [30] = true, [26] = true, },
	skillTotemId = 5,
	baseMods = {
		skill("castTime", 0.6), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 5), 
		--"base_totem_duration" = 8000
		--"base_totem_range" = 100
		--"base_global_chance_to_knockback_%" = 25
		--"is_totem" = ?
		--"is_area_damage" = ?
		--"base_skill_is_totemified" = ?
	},
	qualityMods = {
		mod("TotemLife", "INC", 1), --"totem_life_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[3] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
		[4] = skill("totemLevel", nil), --"base_active_skill_totem_level"
	},
	levels = {
		[1] = { 24, 23, 46, 28, },
		[2] = { 26, 28, 51, 31, },
		[3] = { 28, 33, 62, 34, },
		[4] = { 31, 40, 74, 37, },
		[5] = { 33, 47, 88, 40, },
		[6] = { 34, 53, 98, 42, },
		[7] = { 36, 59, 110, 44, },
		[8] = { 39, 66, 123, 46, },
		[9] = { 43, 74, 137, 48, },
		[10] = { 46, 82, 153, 50, },
		[11] = { 49, 92, 170, 52, },
		[12] = { 51, 102, 189, 54, },
		[13] = { 53, 113, 210, 56, },
		[14] = { 53, 126, 233, 58, },
		[15] = { 55, 139, 259, 60, },
		[16] = { 55, 154, 287, 62, },
		[17] = { 57, 171, 318, 64, },
		[18] = { 57, 189, 351, 66, },
		[19] = { 58, 209, 389, 68, },
		[20] = { 58, 231, 429, 70, },
		[21] = { 59, 255, 474, 72, },
		[22] = { 60, 282, 524, 74, },
		[23] = { 61, 311, 578, 76, },
		[24] = { 62, 343, 637, 78, },
		[25] = { 62, 378, 702, 80, },
		[26] = { 63, 416, 773, 82, },
		[27] = { 64, 458, 851, 84, },
		[28] = { 65, 504, 936, 86, },
		[29] = { 66, 555, 1030, 88, },
		[30] = { 66, 610, 1132, 90, },
	},
}
gems["Static Strike"] = {
	strength = true,
	active_skill = true,
	attack = true,
	melee = true,
	area = true,
	duration = true,
	lightning = true,
	parts = {
		{
			name = "Melee hit",
			area = false,
		},
		{
			name = "Explosion",
			area = true,
		},
	},
	color = 1,
	baseFlags = {
		melee = true,
		area = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [1] = true, [6] = true, [25] = true, [28] = true, [24] = true, [11] = true, [12] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		skill("PhysicalDamageConvertToLightning", 60), --"skill_physical_damage_%_to_convert_to_lightning" = 60
		skill("duration", 0.75), --"base_skill_effect_duration" = 750
		mod("Damage", "MORE", -40, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"static_strike_explosion_damage_+%_final" = -40
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 10, 0, },
		[2] = { 12.6, 1, },
		[3] = { 15.2, 2, },
		[4] = { 17.8, 3, },
		[5] = { 20.4, 4, },
		[6] = { 23, 5, },
		[7] = { 25.6, 6, },
		[8] = { 28.2, 7, },
		[9] = { 30.8, 8, },
		[10] = { 33.4, 9, },
		[11] = { 36, 10, },
		[12] = { 38.6, 11, },
		[13] = { 41.2, 12, },
		[14] = { 43.8, 13, },
		[15] = { 46.4, 14, },
		[16] = { 49, 15, },
		[17] = { 51.6, 16, },
		[18] = { 54.2, 17, },
		[19] = { 56.8, 18, },
		[20] = { 59.4, 19, },
		[21] = { 62, 20, },
		[22] = { 64.6, 21, },
		[23] = { 67.2, 22, },
		[24] = { 69.8, 23, },
		[25] = { 72.4, 24, },
		[26] = { 75, 25, },
		[27] = { 77.6, 26, },
		[28] = { 80.2, 27, },
		[29] = { 82.8, 28, },
		[30] = { 85.4, 29, },
	},
}
gems["Summon Flame Golem"] = {
	golem = true,
	strength = true,
	active_skill = true,
	fire = true,
	minion = true,
	spell = true,
	color = 1,
	baseFlags = {
		spell = true,
		minion = true,
		golem = true,
		fire = true,
	},
	skillTypes = { [36] = true, [33] = true, [19] = true, [9] = true, [21] = true, [26] = true, [2] = true, [18] = true, [17] = true, [49] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_number_of_golems_allowed" = 1
		--"display_minion_monster_type" = 7
		mod("Misc", "LIST", { type = "Condition", var = "HaveFireGolem" }, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), 
	},
	qualityMods = {
		mod("MinionLife", "INC", 1), --"minion_maximum_life_+%" = 1
		mod("Damage", "INC", 1, 0, KeywordFlag.Minion), --"minion_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "base_actor_scale_+%"
		[3] = mod("Damage", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"fire_golem_grants_damage_+%"
		[4] = mod("MinionLife", "INC", nil), --"minion_maximum_life_+%"
		--[5] = "display_minion_monster_level"
	},
	levels = {
		[1] = { 30, 0, 15, 30, 34, },
		[2] = { 32, 1, 15, 32, 36, },
		[3] = { 34, 1, 16, 34, 38, },
		[4] = { 36, 2, 16, 36, 40, },
		[5] = { 38, 2, 16, 38, 42, },
		[6] = { 40, 3, 16, 40, 44, },
		[7] = { 42, 3, 17, 42, 46, },
		[8] = { 44, 4, 17, 44, 48, },
		[9] = { 44, 4, 17, 46, 50, },
		[10] = { 46, 5, 17, 48, 52, },
		[11] = { 48, 5, 18, 50, 54, },
		[12] = { 48, 6, 18, 52, 56, },
		[13] = { 50, 6, 18, 54, 58, },
		[14] = { 50, 7, 18, 56, 60, },
		[15] = { 52, 7, 19, 58, 62, },
		[16] = { 52, 8, 19, 60, 64, },
		[17] = { 52, 8, 19, 62, 66, },
		[18] = { 52, 9, 19, 64, 68, },
		[19] = { 54, 9, 20, 66, 69, },
		[20] = { 54, 10, 20, 68, 70, },
		[21] = { 56, 10, 20, 70, 72, },
		[22] = { 56, 11, 20, 72, 74, },
		[23] = { 58, 11, 21, 74, 76, },
		[24] = { 58, 12, 21, 76, 78, },
		[25] = { 60, 12, 21, 78, 80, },
		[26] = { 60, 13, 21, 80, 82, },
		[27] = { 60, 13, 22, 82, 84, },
		[28] = { 60, 14, 22, 84, 86, },
		[29] = { 62, 14, 22, 86, 88, },
		[30] = { 62, 15, 22, 88, 90, },
	},
}
gems["Summon Stone Golem"] = {
	golem = true,
	strength = true,
	active_skill = true,
	minion = true,
	spell = true,
	color = 1,
	baseFlags = {
		spell = true,
		minion = true,
		golem = true,
	},
	skillTypes = { [36] = true, [19] = true, [9] = true, [21] = true, [26] = true, [2] = true, [18] = true, [17] = true, [49] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_number_of_golems_allowed" = 1
		--"display_minion_monster_type" = 10
		mod("Misc", "LIST", { type = "Condition", var = "HavePhysicalGolem" }, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), 
	},
	qualityMods = {
		mod("MinionLife", "INC", 1), --"minion_maximum_life_+%" = 1
		mod("Damage", "INC", 1, 0, KeywordFlag.Minion), --"minion_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "base_actor_scale_+%"
		[3] = mod("MinionLife", "INC", nil), --"minion_maximum_life_+%"
		[4] = mod("LifeRegen", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"stone_golem_grants_base_life_regeneration_rate_per_minute"
		--[5] = "display_minion_monster_level"
	},
	levels = {
		[1] = { 30, 0, 30, 33, 34, },
		[2] = { 32, 1, 32, 36, 36, },
		[3] = { 34, 1, 34, 39, 38, },
		[4] = { 36, 2, 36, 42, 40, },
		[5] = { 38, 2, 38, 45, 42, },
		[6] = { 40, 3, 40, 49, 44, },
		[7] = { 42, 3, 42, 52, 46, },
		[8] = { 44, 4, 44, 56, 48, },
		[9] = { 44, 4, 46, 60, 50, },
		[10] = { 46, 5, 48, 64, 52, },
		[11] = { 48, 5, 50, 68, 54, },
		[12] = { 48, 6, 52, 72, 56, },
		[13] = { 50, 6, 54, 76, 58, },
		[14] = { 50, 7, 56, 81, 60, },
		[15] = { 52, 7, 58, 85, 62, },
		[16] = { 52, 8, 60, 90, 64, },
		[17] = { 52, 8, 62, 95, 66, },
		[18] = { 52, 9, 64, 100, 68, },
		[19] = { 54, 9, 66, 103, 69, },
		[20] = { 54, 10, 68, 105, 70, },
		[21] = { 56, 10, 70, 110, 72, },
		[22] = { 56, 11, 72, 116, 74, },
		[23] = { 58, 11, 74, 121, 76, },
		[24] = { 58, 12, 76, 127, 78, },
		[25] = { 60, 12, 78, 133, 80, },
		[26] = { 60, 13, 80, 139, 82, },
		[27] = { 60, 13, 82, 145, 84, },
		[28] = { 60, 14, 84, 151, 86, },
		[29] = { 62, 14, 86, 157, 88, },
		[30] = { 62, 15, 88, 164, 90, },
	},
}
gems["Sunder"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	parts = {
		{
			name = "Primary wave",
		},
		{
			name = "Shockwaves",
		},
	},
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [11] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 8), 
		mod("Damage", "MORE", -30, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"shockwave_slam_explosion_damage_+%_final" = -30
		mod("Speed", "MORE", -15, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -15
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { nil, },
		[2] = { 1.6, },
		[3] = { 3.2, },
		[4] = { 4.8, },
		[5] = { 6.4, },
		[6] = { 8, },
		[7] = { 9.6, },
		[8] = { 11.2, },
		[9] = { 12.8, },
		[10] = { 14.4, },
		[11] = { 16, },
		[12] = { 17.6, },
		[13] = { 19.2, },
		[14] = { 20.8, },
		[15] = { 22.4, },
		[16] = { 24, },
		[17] = { 25.6, },
		[18] = { 27.2, },
		[19] = { 28.8, },
		[20] = { 30.4, },
		[21] = { 32, },
		[22] = { 33.6, },
		[23] = { 35.2, },
		[24] = { 36.8, },
		[25] = { 38.4, },
		[26] = { 40, },
		[27] = { 41.6, },
		[28] = { 43.2, },
		[29] = { 44.8, },
		[30] = { 46.4, },
	},
}
gems["Sweep"] = {
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [11] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1.15), 
		skill("manaCost", 8), 
		mod("Speed", "MORE", -10, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -10
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		--[1] = "base_global_chance_to_knockback_%"
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 30, nil, },
		[2] = { 30, 2, },
		[3] = { 31, 4, },
		[4] = { 31, 6, },
		[5] = { 32, 8, },
		[6] = { 32, 10, },
		[7] = { 33, 12, },
		[8] = { 33, 14, },
		[9] = { 34, 16, },
		[10] = { 34, 18, },
		[11] = { 35, 20, },
		[12] = { 35, 22, },
		[13] = { 36, 24, },
		[14] = { 36, 26, },
		[15] = { 37, 28, },
		[16] = { 37, 30, },
		[17] = { 38, 32, },
		[18] = { 38, 34, },
		[19] = { 39, 36, },
		[20] = { 39, 38, },
		[21] = { 40, 40, },
		[22] = { 40, 42, },
		[23] = { 41, 44, },
		[24] = { 41, 46, },
		[25] = { 42, 48, },
		[26] = { 42, 50, },
		[27] = { 43, 52, },
		[28] = { 43, 54, },
		[29] = { 44, 56, },
		[30] = { 44, 58, },
	},
}
gems["Vengeance"] = {
	trigger = true,
	strength = true,
	active_skill = true,
	attack = true,
	area = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [11] = true, [24] = true, [47] = true, [6] = true, [57] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"melee_counterattack_trigger_on_hit_%" = 30
		--"attack_unusable_if_triggerable" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		--"melee_counterattack_trigger_on_hit_%" = 0.5
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { -25, },
		[2] = { -23, },
		[3] = { -21, },
		[4] = { -19, },
		[5] = { -17, },
		[6] = { -15, },
		[7] = { -13, },
		[8] = { -11, },
		[9] = { -9, },
		[10] = { -7, },
		[11] = { -5, },
		[12] = { -3, },
		[13] = { -1, },
		[14] = { 1, },
		[15] = { 3, },
		[16] = { 5, },
		[17] = { 7, },
		[18] = { 9, },
		[19] = { 11, },
		[20] = { 13, },
		[21] = { 15, },
		[22] = { 17, },
		[23] = { 19, },
		[24] = { 21, },
		[25] = { 23, },
		[26] = { 25, },
		[27] = { 27, },
		[28] = { 29, },
		[29] = { 31, },
		[30] = { 33, },
	},
}
gems["Vigilant Strike"] = {
	attack = true,
	strength = true,
	active_skill = true,
	melee = true,
	color = 1,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [5] = true, [24] = true, [6] = true, [28] = true, [25] = true, [53] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		mod("Misc", "LIST", { type = "Condition", var = "Fortify" }, 0, 0, { type = "Condition", var = "Combat" }), --"chance_to_fortify_on_melee_hit_+%" = 100
		mod("FortifyDuration", "INC", 50), --"fortify_duration_+%" = 50
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("FortifyDuration", "INC", 1), --"fortify_duration_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 65, },
		[2] = { 67, },
		[3] = { 69, },
		[4] = { 71, },
		[5] = { 73, },
		[6] = { 75, },
		[7] = { 77, },
		[8] = { 79, },
		[9] = { 81, },
		[10] = { 83, },
		[11] = { 85, },
		[12] = { 87, },
		[13] = { 89, },
		[14] = { 91, },
		[15] = { 93, },
		[16] = { 95, },
		[17] = { 97, },
		[18] = { 99, },
		[19] = { 101, },
		[20] = { 103, },
		[21] = { 105, },
		[22] = { 107, },
		[23] = { 109, },
		[24] = { 111, },
		[25] = { 113, },
		[26] = { 115, },
		[27] = { 117, },
		[28] = { 119, },
		[29] = { 121, },
		[30] = { 123, },
	},
}
gems["Vitality"] = {
	aura = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 1,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 35), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaRadius", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("LifeRegenPercent", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"life_regeneration_rate_per_minute_%"
		[2] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 0.7, 0, },
		[2] = { 0.75, 3, },
		[3] = { 0.8, 6, },
		[4] = { 0.85, 9, },
		[5] = { 0.9, 12, },
		[6] = { 0.95, 15, },
		[7] = { 1, 18, },
		[8] = { 1.05, 21, },
		[9] = { 1.1, 23, },
		[10] = { 1.15, 25, },
		[11] = { 1.2, 27, },
		[12] = { 1.25, 29, },
		[13] = { 1.3, 31, },
		[14] = { 1.35, 33, },
		[15] = { 1.4, 35, },
		[16] = { 1.45, 36, },
		[17] = { 1.5, 37, },
		[18] = { 1.55, 38, },
		[19] = { 1.6, 39, },
		[20] = { 1.65, 40, },
		[21] = { 1.7, 41, },
		[22] = { 1.75, 42, },
		[23] = { 1.8, 43, },
		[24] = { 1.85, 44, },
		[25] = { 1.9, 45, },
		[26] = { 1.95, 46, },
		[27] = { 2, 47, },
		[28] = { 2.05, 48, },
		[29] = { 2.1, 49, },
		[30] = { 2.15, 50, },
	},
}
gems["Warlord's Mark"] = {
	curse = true,
	strength = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 1,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"chance_to_be_stunned_%" = 10
		--"life_leech_on_any_damage_when_hit_permyriad" = 200
		--"mana_leech_on_any_damage_when_hit_permyriad" = 200
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		--"chance_to_grant_endurance_charge_on_death_%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaRadius", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("StunRecovery", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_stun_recovery_+%"
		--[5] = "chance_to_grant_endurance_charge_on_death_%"
	},
	levels = {
		[1] = { 24, 6, 0, -21, 21, },
		[2] = { 26, 6.2, 2, -21, 21, },
		[3] = { 27, 6.4, 4, -22, 22, },
		[4] = { 29, 6.6, 6, -22, 22, },
		[5] = { 30, 6.8, 8, -23, 23, },
		[6] = { 32, 7, 10, -23, 23, },
		[7] = { 34, 7.2, 12, -24, 24, },
		[8] = { 35, 7.4, 14, -24, 24, },
		[9] = { 37, 7.6, 16, -25, 25, },
		[10] = { 38, 7.8, 18, -25, 25, },
		[11] = { 39, 8, 20, -26, 26, },
		[12] = { 40, 8.2, 22, -26, 26, },
		[13] = { 42, 8.4, 24, -27, 27, },
		[14] = { 43, 8.6, 26, -27, 27, },
		[15] = { 44, 8.8, 28, -28, 28, },
		[16] = { 45, 9, 30, -28, 28, },
		[17] = { 46, 9.2, 32, -29, 29, },
		[18] = { 47, 9.4, 34, -29, 29, },
		[19] = { 48, 9.6, 36, -30, 30, },
		[20] = { 50, 9.8, 38, -30, 30, },
		[21] = { 51, 10, 40, -31, 31, },
		[22] = { 52, 10.2, 42, -31, 31, },
		[23] = { 53, 10.4, 44, -32, 32, },
		[24] = { 54, 10.6, 46, -32, 32, },
		[25] = { 56, 10.8, 48, -33, 33, },
		[26] = { 57, 11, 50, -33, 33, },
		[27] = { 58, 11.2, 52, -34, 34, },
		[28] = { 59, 11.4, 54, -34, 34, },
		[29] = { 60, 11.6, 56, -35, 35, },
		[30] = { 61, 11.8, 58, -35, 35, },
	},
}
