-- Path of Building
--
-- Active Dexterity skill gems
-- Skill data (c) Grinding Gear Games
--
local skills, mod, flag, skill = ...

skills["AnimateWeapon"] = {
	name = "Animate Weapon",
	gemTags = {
		dexterity = true,
		active_skill = true,
		duration = true,
		minion = true,
		spell = true,
	},
	unsupported = true,
	color = 2,
	baseFlags = {
	},
	skillTypes = { [36] = true, [12] = true, [9] = true, [21] = true, [2] = true, [18] = true, [49] = true, },
	minionSkillTypes = { [1] = true, [24] = true, [25] = true, [28] = true, [54] = true, [56] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		--"emerge_speed_+%" = 0
		skill("duration", 37.5), --"base_skill_effect_duration" = 37500
		--"number_of_animated_weapons_allowed" = 50
	},
	qualityMods = {
		mod("MovementSpeed", "INC", 2, 0, 0, nil), --"base_movement_velocity_+%" = 2
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		--[3] = "animate_item_maximum_level_requirement"
		[4] = mod("Damage", "MORE", nil, ModFlag.Hit), --"active_skill_damage_+%_final"
		[5] = mod("Speed", "INC", nil, ModFlag.Attack, 0, nil), --"attack_speed_+%"
		[6] = mod("PhysicalMin", "BASE", nil, ModFlag.Attack, 0, nil), --"attack_minimum_added_physical_damage"
		[7] = mod("PhysicalMax", "BASE", nil, ModFlag.Attack, 0, nil), --"attack_maximum_added_physical_damage"
	},
	levels = {
		[1] = { 4, 9, 9, 0, 0, 4, 6, },
		[2] = { 6, 10, 11, 8, 2, 5, 8, },
		[3] = { 9, 11, 14, 16, 4, 7, 10, },
		[4] = { 12, 12, 18, 24, 6, 8, 12, },
		[5] = { 16, 14, 22, 32, 8, 10, 15, },
		[6] = { 20, 15, 26, 40, 10, 12, 18, },
		[7] = { 24, 16, 31, 48, 12, 14, 21, },
		[8] = { 28, 18, 35, 56, 14, 17, 25, },
		[9] = { 32, 20, 40, 64, 16, 19, 29, },
		[10] = { 36, 22, 44, 72, 18, 22, 34, },
		[11] = { 40, 25, 49, 80, 20, 24, 37, },
		[12] = { 44, 26, 53, 88, 22, 26, 39, },
		[13] = { 48, 27, 58, 96, 24, 28, 41, },
		[14] = { 52, 29, 62, 104, 26, 29, 44, },
		[15] = { 55, 30, 66, 112, 28, 31, 46, },
		[16] = { 58, 31, 70, 120, 30, 32, 49, },
		[17] = { 61, 33, 74, 128, 32, 34, 51, },
		[18] = { 64, 34, 78, 136, 34, 36, 53, },
		[19] = { 67, 34, 82, 144, 36, 37, 55, },
		[20] = { 70, 36, 100, 152, 38, 38, 56, },
		[21] = { 72, 37, 100, 160, 40, 39, 58, },
		[22] = { 74, 38, 100, 168, 42, 40, 60, },
		[23] = { 76, 38, 100, 176, 44, 41, 61, },
		[24] = { 78, 39, 100, 184, 46, 42, 63, },
		[25] = { 80, 40, 100, 192, 48, 43, 64, },
		[26] = { 82, 41, 100, 200, 50, 44, 66, },
		[27] = { 84, 42, 100, 208, 52, 45, 67, },
		[28] = { 86, 42, 100, 216, 54, 46, 69, },
		[29] = { 88, 44, 100, 224, 56, 47, 71, },
		[30] = { 90, 45, 100, 232, 58, 48, 72, },
	},
}
skills["NewArcticArmour"] = {
	name = "Arctic Armour",
	gemTags = {
		dexterity = true,
		active_skill = true,
		spell = true,
		duration = true,
		cold = true,
	},
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
		skill("cooldown", 0.5), 
		--"chill_enemy_when_hit_duration_ms" = 500
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		--[2] = "new_arctic_armour_physical_damage_taken_when_hit_+%_final"
		--[3] = "new_arctic_armour_fire_damage_taken_when_hit_+%_final"
		[4] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 16, -8, -8, 2.5, },
		[2] = { 20, -8, -8, 2.6, },
		[3] = { 24, -9, -8, 2.7, },
		[4] = { 28, -9, -8, 2.8, },
		[5] = { 31, -9, -9, 2.9, },
		[6] = { 34, -9, -9, 3, },
		[7] = { 37, -10, -9, 3.1, },
		[8] = { 40, -10, -9, 3.2, },
		[9] = { 43, -10, -10, 3.3, },
		[10] = { 46, -10, -10, 3.4, },
		[11] = { 49, -11, -10, 3.5, },
		[12] = { 52, -11, -10, 3.6, },
		[13] = { 55, -11, -11, 3.7, },
		[14] = { 58, -11, -11, 3.8, },
		[15] = { 60, -12, -11, 3.9, },
		[16] = { 62, -12, -11, 4, },
		[17] = { 64, -12, -12, 4.1, },
		[18] = { 66, -12, -12, 4.2, },
		[19] = { 68, -13, -12, 4.3, },
		[20] = { 70, -13, -12, 4.4, },
		[21] = { 72, -13, -13, 4.5, },
		[22] = { 74, -13, -13, 4.6, },
		[23] = { 76, -14, -13, 4.7, },
		[24] = { 78, -14, -13, 4.8, },
		[25] = { 80, -14, -14, 4.9, },
		[26] = { 82, -14, -14, 5, },
		[27] = { 84, -15, -14, 5.1, },
		[28] = { 86, -15, -14, 5.2, },
		[29] = { 88, -15, -15, 5.3, },
		[30] = { 90, -15, -15, 5.4, },
	},
}
skills["Barrage"] = {
	name = "Barrage",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		bow = true,
	},
	parts = {
		{
			name = "1 Arrow",
		},
		{
			name = "All Arrows",
		},
	},
	setupFunc = function(actor, output)
		if actor.mainSkill.skillPart == 2 then
			actor.mainSkill.skillData.dpsMultiplier = output.ProjectileCount
		end
	end,
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [6] = true, [3] = true, [22] = true, [17] = true, [19] = true, },
	weaponTypes = {
		["Wand"] = true,
		["Bow"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 12, 7, -50, },
		[2] = { 15, 7, -49.4, },
		[3] = { 19, 7, -48.8, },
		[4] = { 23, 8, -48.2, },
		[5] = { 27, 8, -47.6, },
		[6] = { 31, 8, -47, },
		[7] = { 35, 8, -46.4, },
		[8] = { 38, 8, -45.8, },
		[9] = { 41, 9, -45.2, },
		[10] = { 44, 9, -44.6, },
		[11] = { 47, 9, -44, },
		[12] = { 50, 9, -43.4, },
		[13] = { 53, 9, -42.8, },
		[14] = { 56, 10, -42.2, },
		[15] = { 59, 10, -41.6, },
		[16] = { 62, 10, -41, },
		[17] = { 64, 10, -40.4, },
		[18] = { 66, 10, -39.8, },
		[19] = { 68, 11, -39.2, },
		[20] = { 70, 11, -38.6, },
		[21] = { 72, 11, -38, },
		[22] = { 74, 11, -37.4, },
		[23] = { 76, 11, -36.8, },
		[24] = { 78, 11, -36.2, },
		[25] = { 80, 11, -35.6, },
		[26] = { 82, 12, -35, },
		[27] = { 84, 12, -34.4, },
		[28] = { 86, 12, -33.8, },
		[29] = { 88, 12, -33.2, },
		[30] = { 90, 12, -32.6, },
	},
}
skills["BearTrap"] = {
	name = "Bear Trap",
	gemTags = {
		trap = true,
		dexterity = true,
		active_skill = true,
		duration = true,
		cast = true,
	},
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
		skill("cooldown", 3), 
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("PhysicalMin", nil), --"secondary_minimum_base_physical_damage"
		[4] = skill("PhysicalMax", nil), --"secondary_maximum_base_physical_damage"
	},
	levels = {
		[1] = { 4, 11, 16, 22, },
		[2] = { 6, 13, 20, 28, },
		[3] = { 9, 15, 27, 38, },
		[4] = { 12, 17, 35, 49, },
		[5] = { 16, 20, 49, 69, },
		[6] = { 20, 22, 67, 94, },
		[7] = { 24, 24, 90, 126, },
		[8] = { 28, 26, 119, 167, },
		[9] = { 32, 28, 156, 218, },
		[10] = { 36, 32, 202, 282, },
		[11] = { 40, 35, 259, 363, },
		[12] = { 44, 38, 331, 463, },
		[13] = { 48, 39, 420, 587, },
		[14] = { 52, 41, 530, 742, },
		[15] = { 55, 42, 630, 881, },
		[16] = { 58, 43, 746, 1045, },
		[17] = { 61, 44, 883, 1236, },
		[18] = { 64, 45, 1043, 1460, },
		[19] = { 67, 46, 1230, 1721, },
		[20] = { 70, 46, 1447, 2026, },
		[21] = { 72, 47, 1613, 2258, },
		[22] = { 74, 48, 1795, 2514, },
		[23] = { 76, 49, 1998, 2797, },
		[24] = { 78, 50, 2222, 3111, },
		[25] = { 80, 50, 2470, 3458, },
		[26] = { 82, 51, 2744, 3842, },
		[27] = { 84, 52, 3047, 4266, },
		[28] = { 86, 53, 3382, 4735, },
		[29] = { 88, 54, 3753, 5254, },
		[30] = { 90, 54, 4162, 5826, },
	},
}
skills["ChargedAttack"] = {
	name = "Blade Flurry",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		channelling = true,
		melee = true,
	},
	parts = {
		{
			name = "1 Stage",
		},
		{
			name = "6 Stages",
		},
		{
			name = "Release at 6 Stages",
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [11] = true, [6] = true, [58] = true, [24] = true, },
	weaponTypes = {
		["One Handed Sword"] = true,
		["Dagger"] = true,
		["Claw"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 4), 
		mod("Speed", "MORE", 60, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = 60
		--"charged_attack_damage_per_stack_+%_final" = 20
		--"is_area_damage" = ?
		nil, --"base_skill_show_average_damage_instead_of_dps" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
		mod("Damage", "MORE", 120, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), 
		skill("dpsMultiplier", 3, { type = "SkillPart", skillPart = 3 }), 
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 28, -55, },
		[2] = { 31, -54.4, },
		[3] = { 34, -53.8, },
		[4] = { 37, -53.2, },
		[5] = { 40, -52.6, },
		[6] = { 42, -52, },
		[7] = { 44, -51.4, },
		[8] = { 46, -50.8, },
		[9] = { 48, -50.2, },
		[10] = { 50, -49.6, },
		[11] = { 52, -49, },
		[12] = { 54, -48.4, },
		[13] = { 56, -47.8, },
		[14] = { 58, -47.2, },
		[15] = { 60, -46.6, },
		[16] = { 62, -46, },
		[17] = { 64, -45.4, },
		[18] = { 66, -44.8, },
		[19] = { 68, -44.2, },
		[20] = { 70, -43.6, },
		[21] = { 72, -43, },
		[22] = { 74, -42.4, },
		[23] = { 76, -41.8, },
		[24] = { 78, -41.2, },
		[25] = { 80, -40.6, },
		[26] = { 82, -40, },
		[27] = { 84, -39.4, },
		[28] = { 86, -38.8, },
		[29] = { 88, -38.2, },
		[30] = { 90, -37.6, },
	},
}
skills["BladeVortex"] = {
	name = "Blade Vortex",
	gemTags = {
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
	},
	parts = {
		{
			name = "0 Blades",
		},
		{
			name = "5 Blades",
		},
		{
			name = "10 Blades",
		},
		{
			name = "20 Blades",
		},
	},
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
		--"base_blade_vortex_hit_rate_ms" = 600
		--"blade_vortex_hit_rate_+%_per_blade" = 10
		--"blade_vortex_damage_+%_per_blade_final" = 30
		--"is_area_damage" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
		--"action_ignores_crit_tracking" = ?
		nil, --"base_skill_show_average_damage_instead_of_dps" = ?
		skill("deliciouslyOverpowered", true), 
		mod("Damage", "MORE", 150, ModFlag.Spell, 0, { type = "SkillPart", skillPart = 2 }), 
		mod("Damage", "MORE", 300, ModFlag.Spell, 0, { type = "SkillPart", skillPart = 3 }), 
		mod("Damage", "MORE", 600, ModFlag.Spell, 0, { type = "SkillPart", skillPart = 4 }), 
		skill("hitTimeOverride", 0.6, { type = "SkillPart", skillPart = 1 }), 
		skill("hitTimeOverride", 0.4, { type = "SkillPart", skillPart = 2 }), 
		skill("hitTimeOverride", 0.3, { type = "SkillPart", skillPart = 3 }), 
		skill("hitTimeOverride", 0.2, { type = "SkillPart", skillPart = 4 }), 
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[4] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
		--[5] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 12, 6, 7, 10, 0, },
		[2] = { 15, 7, 8, 12, 0, },
		[3] = { 19, 8, 11, 16, 0, },
		[4] = { 23, 9, 14, 20, 0, },
		[5] = { 27, 10, 17, 25, 1, },
		[6] = { 31, 11, 21, 32, 1, },
		[7] = { 35, 12, 26, 39, 1, },
		[8] = { 38, 13, 30, 45, 1, },
		[9] = { 41, 13, 35, 52, 1, },
		[10] = { 44, 14, 40, 60, 2, },
		[11] = { 47, 14, 46, 69, 2, },
		[12] = { 50, 15, 53, 79, 2, },
		[13] = { 53, 16, 60, 90, 2, },
		[14] = { 56, 16, 68, 103, 2, },
		[15] = { 59, 17, 78, 117, 3, },
		[16] = { 62, 18, 88, 133, 3, },
		[17] = { 64, 18, 96, 144, 3, },
		[18] = { 66, 19, 104, 157, 3, },
		[19] = { 68, 19, 113, 170, 3, },
		[20] = { 70, 19, 123, 185, 4, },
		[21] = { 72, 20, 133, 200, 4, },
		[22] = { 74, 21, 145, 217, 4, },
		[23] = { 76, 21, 157, 235, 4, },
		[24] = { 78, 21, 170, 254, 4, },
		[25] = { 80, 22, 183, 275, 5, },
		[26] = { 82, 23, 198, 298, 5, },
		[27] = { 84, 23, 214, 322, 5, },
		[28] = { 86, 23, 232, 347, 5, },
		[29] = { 88, 24, 250, 375, 5, },
		[30] = { 90, 24, 270, 405, 6, },
	},
}
skills["Bladefall"] = {
	name = "Bladefall",
	gemTags = {
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
	},
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
		mod("AreaOfEffect", "INC", 0), --"base_skill_area_of_effect_+%" = 0
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[4] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
	},
	levels = {
		[1] = { 28, 13, 44, 65, },
		[2] = { 31, 14, 52, 78, },
		[3] = { 34, 15, 62, 93, },
		[4] = { 37, 16, 73, 110, },
		[5] = { 40, 17, 86, 129, },
		[6] = { 42, 18, 96, 144, },
		[7] = { 44, 18, 107, 160, },
		[8] = { 46, 19, 118, 177, },
		[9] = { 48, 19, 131, 197, },
		[10] = { 50, 20, 145, 218, },
		[11] = { 52, 21, 160, 241, },
		[12] = { 54, 21, 177, 266, },
		[13] = { 56, 22, 195, 293, },
		[14] = { 58, 22, 215, 323, },
		[15] = { 60, 23, 237, 356, },
		[16] = { 62, 24, 261, 392, },
		[17] = { 64, 24, 287, 431, },
		[18] = { 66, 25, 315, 473, },
		[19] = { 68, 25, 346, 519, },
		[20] = { 70, 26, 380, 570, },
		[21] = { 72, 27, 417, 625, },
		[22] = { 74, 27, 457, 685, },
		[23] = { 76, 28, 500, 750, },
		[24] = { 78, 28, 548, 821, },
		[25] = { 80, 29, 599, 899, },
		[26] = { 82, 30, 655, 983, },
		[27] = { 84, 30, 716, 1074, },
		[28] = { 86, 31, 782, 1174, },
		[29] = { 88, 31, 854, 1282, },
		[30] = { 90, 32, 933, 1399, },
	},
}
skills["BlastRain"] = {
	name = "Blast Rain",
	gemTags = {
		fire = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		bow = true,
	},
	parts = {
		{
			name = "1 explosion",
		},
		{
			name = "4 explosions",
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		fire = true,
	},
	skillTypes = { [1] = true, [11] = true, [14] = true, [22] = true, [17] = true, [19] = true, [33] = true, [48] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		mod("PhysicalDamageConvertToFire", "BASE", 50, 0, 0, nil), --"base_physical_damage_%_to_convert_to_fire" = 50
		mod("AreaOfEffect", "INC", 0), --"base_skill_area_of_effect_+%" = 0
		--"blast_rain_number_of_blasts" = 4
		--"blast_rain_arrow_delay_ms" = 80
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
		skill("dpsMultiplier", 4, { type = "SkillPart", skillPart = 2 }), 
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 28, 8, -60, },
		[2] = { 31, 8, -59.6, },
		[3] = { 34, 8, -59.2, },
		[4] = { 37, 8, -58.8, },
		[5] = { 40, 9, -58.4, },
		[6] = { 42, 9, -58, },
		[7] = { 44, 9, -57.6, },
		[8] = { 46, 9, -57.2, },
		[9] = { 48, 9, -56.8, },
		[10] = { 50, 9, -56.4, },
		[11] = { 52, 9, -56, },
		[12] = { 54, 10, -55.6, },
		[13] = { 56, 10, -55.2, },
		[14] = { 58, 10, -54.8, },
		[15] = { 60, 10, -54.4, },
		[16] = { 62, 10, -54, },
		[17] = { 64, 10, -53.6, },
		[18] = { 66, 10, -53.2, },
		[19] = { 68, 10, -52.8, },
		[20] = { 70, 10, -52.4, },
		[21] = { 72, 10, -52, },
		[22] = { 74, 10, -51.6, },
		[23] = { 76, 11, -51.2, },
		[24] = { 78, 11, -50.8, },
		[25] = { 80, 11, -50.4, },
		[26] = { 82, 11, -50, },
		[27] = { 84, 11, -49.6, },
		[28] = { 86, 12, -49.2, },
		[29] = { 88, 12, -48.8, },
		[30] = { 90, 12, -48.4, },
	},
}
skills["BlinkArrow"] = {
	name = "Blink Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		minion = true,
		duration = true,
		movement = true,
		bow = true,
	},
	minionList = {
		"Clone",
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		minion = true,
		movement = true,
		duration = true,
	},
	skillTypes = { [14] = true, [1] = true, [9] = true, [48] = true, [21] = true, [12] = true, [22] = true, [17] = true, [19] = true, [38] = true, },
	minionSkillTypes = { [1] = true, [3] = true, [48] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("cooldown", 3), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"number_of_monsters_to_summon" = 1
		mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Damage", "MORE", 75) }), --"active_skill_minion_damage_+%_final" = 75
		--"display_minion_monster_type" = 4
		--"base_is_projectile" = ?
		skill("minionUseBowAndQuiver", true), 
	},
	qualityMods = {
		--"base_arrow_speed_+%" = 1.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Damage", "INC", nil) }), --"minion_damage_+%"
		[4] = mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Life", "INC", nil) }), --"minion_maximum_life_+%"
		[5] = skill("minionLevel", nil), --"display_minion_monster_level"
	},
	levels = {
		[1] = { 10, 14, 0, 0, 24, },
		[2] = { 13, 14, 6, 3, 27, },
		[3] = { 17, 15, 12, 6, 30, },
		[4] = { 21, 15, 18, 9, 33, },
		[5] = { 25, 15, 24, 12, 35, },
		[6] = { 29, 16, 30, 15, 38, },
		[7] = { 33, 16, 36, 18, 40, },
		[8] = { 36, 16, 42, 21, 43, },
		[9] = { 39, 16, 48, 24, 46, },
		[10] = { 42, 17, 54, 27, 48, },
		[11] = { 45, 17, 60, 30, 50, },
		[12] = { 48, 17, 66, 33, 52, },
		[13] = { 51, 17, 72, 36, 54, },
		[14] = { 54, 18, 78, 39, 56, },
		[15] = { 57, 18, 84, 42, 58, },
		[16] = { 60, 18, 90, 45, 60, },
		[17] = { 63, 19, 96, 48, 62, },
		[18] = { 66, 19, 102, 51, 64, },
		[19] = { 68, 20, 108, 54, 66, },
		[20] = { 70, 20, 114, 57, 68, },
		[21] = { 72, 21, 120, 60, 70, },
		[22] = { 74, 21, 126, 63, 72, },
		[23] = { 76, 22, 132, 66, 74, },
		[24] = { 78, 22, 138, 69, 76, },
		[25] = { 80, 22, 144, 72, 78, },
		[26] = { 82, 23, 150, 75, 80, },
		[27] = { 84, 23, 156, 78, 82, },
		[28] = { 86, 23, 162, 81, 84, },
		[29] = { 88, 23, 168, 84, 86, },
		[30] = { 90, 24, 174, 87, 88, },
	},
}
skills["BloodRage"] = {
	name = "Blood Rage",
	gemTags = {
		dexterity = true,
		active_skill = true,
		spell = true,
		duration = true,
	},
	color = 2,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [18] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.25), 
		skill("cooldown", 1), 
		--"life_leech_from_physical_attack_damage_permyriad" = 120
		--"base_physical_damage_%_of_maximum_life_to_deal_per_minute" = 240
		--"base_physical_damage_%_of_maximum_energy_shield_to_deal_per_minute" = 240
		--"add_frenzy_charge_on_kill_%_chance" = 25
	},
	qualityMods = {
		mod("Speed", "INC", 0.25, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_speed_+%" = 0.25
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_speed_+%"
		[4] = skill("duration", nil), --"base_skill_effect_duration"
		--[5] = "skill_level"
	},
	levels = {
		[1] = { 16, 17, 5, 7, 1, },
		[2] = { 20, 17, 6, 7.2, 2, },
		[3] = { 24, 17, 6, 7.4, 3, },
		[4] = { 28, 18, 7, 7.6, 4, },
		[5] = { 31, 18, 7, 7.8, 5, },
		[6] = { 34, 18, 8, 8, 6, },
		[7] = { 37, 18, 8, 8.2, 7, },
		[8] = { 40, 19, 9, 8.4, 8, },
		[9] = { 43, 19, 9, 8.6, 9, },
		[10] = { 46, 19, 10, 8.8, 10, },
		[11] = { 49, 20, 10, 9, 11, },
		[12] = { 52, 20, 11, 9.2, 12, },
		[13] = { 55, 20, 11, 9.4, 13, },
		[14] = { 58, 20, 12, 9.6, 14, },
		[15] = { 60, 20, 12, 9.8, 15, },
		[16] = { 62, 21, 13, 10, 16, },
		[17] = { 64, 21, 13, 10.2, 17, },
		[18] = { 66, 21, 14, 10.4, 18, },
		[19] = { 68, 21, 14, 10.6, 19, },
		[20] = { 70, 21, 15, 10.8, 20, },
		[21] = { 72, 22, 15, 11, 21, },
		[22] = { 74, 22, 16, 11.2, 22, },
		[23] = { 76, 22, 16, 11.4, 23, },
		[24] = { 78, 22, 17, 11.6, 24, },
		[25] = { 80, 22, 17, 11.8, 25, },
		[26] = { 82, 23, 18, 12, 26, },
		[27] = { 84, 23, 18, 12.2, 27, },
		[28] = { 86, 23, 19, 12.4, 28, },
		[29] = { 88, 23, 19, 12.6, 29, },
		[30] = { 90, 23, 20, 12.8, 30, },
	},
}
skills["BurningArrow"] = {
	name = "Burning Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		fire = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		fire = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [22] = true, [17] = true, [19] = true, [33] = true, [53] = true, [55] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[4] = mod("FireDamage", "INC", nil, ModFlag.Dot), --"burn_damage_+%"
	},
	levels = {
		[1] = { 1, 5, 50, 10, },
		[2] = { 2, 5, 51.8, 11, },
		[3] = { 4, 5, 53.6, 12, },
		[4] = { 7, 5, 55.4, 13, },
		[5] = { 11, 5, 57.2, 14, },
		[6] = { 16, 6, 59, 15, },
		[7] = { 20, 6, 60.8, 16, },
		[8] = { 24, 6, 62.6, 17, },
		[9] = { 28, 6, 64.4, 18, },
		[10] = { 32, 6, 66.2, 19, },
		[11] = { 36, 7, 68, 20, },
		[12] = { 40, 7, 69.8, 21, },
		[13] = { 44, 7, 71.6, 22, },
		[14] = { 48, 7, 73.4, 23, },
		[15] = { 52, 7, 75.2, 24, },
		[16] = { 56, 8, 77, 25, },
		[17] = { 60, 8, 78.8, 26, },
		[18] = { 64, 8, 80.6, 27, },
		[19] = { 67, 8, 82.4, 28, },
		[20] = { 70, 8, 84.2, 29, },
		[21] = { 72, 9, 86, 30, },
		[22] = { 74, 9, 87.8, 31, },
		[23] = { 76, 9, 89.6, 32, },
		[24] = { 78, 9, 91.4, 33, },
		[25] = { 80, 9, 93.2, 34, },
		[26] = { 82, 10, 95, 35, },
		[27] = { 84, 10, 96.8, 36, },
		[28] = { 86, 10, 98.6, 37, },
		[29] = { 88, 10, 100.4, 38, },
		[30] = { 90, 10, 102.2, 39, },
	},
}
skills["VaalBurningArrow"] = {
	name = "Vaal Burning Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
		area = true,
		fire = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		fire = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [22] = true, [17] = true, [19] = true, [11] = true, [43] = true, [33] = true, [55] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("FireDamage", "INC", nil, ModFlag.Dot), --"burn_damage_+%"
	},
	levels = {
		[1] = { 1, 60, 10, },
		[2] = { 2, 62, 11, },
		[3] = { 4, 64, 12, },
		[4] = { 7, 66, 13, },
		[5] = { 11, 68, 14, },
		[6] = { 16, 70, 15, },
		[7] = { 20, 72, 16, },
		[8] = { 24, 74, 17, },
		[9] = { 28, 76, 18, },
		[10] = { 32, 78, 19, },
		[11] = { 36, 80, 20, },
		[12] = { 40, 82, 21, },
		[13] = { 44, 84, 22, },
		[14] = { 48, 86, 23, },
		[15] = { 52, 88, 24, },
		[16] = { 56, 90, 25, },
		[17] = { 60, 92, 26, },
		[18] = { 64, 94, 27, },
		[19] = { 67, 96, 28, },
		[20] = { 70, 98, 29, },
		[21] = { 72, 100, 30, },
		[22] = { 74, 102, 31, },
		[23] = { 76, 104, 32, },
		[24] = { 78, 106, 33, },
		[25] = { 80, 108, 34, },
		[26] = { 82, 110, 35, },
		[27] = { 84, 112, 36, },
		[28] = { 86, 114, 37, },
		[29] = { 88, 116, 38, },
		[30] = { 90, 118, 39, },
	},
}
skills["PoisonArrow"] = {
	name = "Caustic Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		duration = true,
		chaos = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [11] = true, [12] = true, [17] = true, [19] = true, [22] = true, [40] = true, [50] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"skill_can_fire_arrows" = ?
		skill("dotIsArea", true), 
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
		[4] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
		[5] = mod("PhysicalDamageGainAsChaos", "BASE", nil, 0, 0, nil), --"physical_damage_%_to_add_as_chaos"
		--[6] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 4, 8, 2.8, 5.2, 30, 0, },
		[2] = { 6, 8, 2.9, 6.5166666666667, 31, 0, },
		[3] = { 9, 8, 3, 8.8333333333333, 32, 0, },
		[4] = { 12, 9, 3.1, 11.7, 33, 0, },
		[5] = { 16, 9, 3.2, 16.516666666667, 34, 1, },
		[6] = { 20, 9, 3.3, 22.75, 35, 1, },
		[7] = { 24, 10, 3.4, 30.766666666667, 36, 1, },
		[8] = { 28, 10, 3.5, 41.033333333333, 37, 1, },
		[9] = { 32, 10, 3.6, 54.116666666667, 38, 1, },
		[10] = { 36, 11, 3.7, 70.716666666667, 39, 2, },
		[11] = { 40, 11, 3.9, 91.683333333333, 40, 2, },
		[12] = { 44, 12, 4, 118.13333333333, 41, 2, },
		[13] = { 48, 12, 4.1, 151.35, 42, 2, },
		[14] = { 52, 13, 4.2, 192.96666666667, 43, 2, },
		[15] = { 55, 13, 4.3, 230.91666666667, 44, 3, },
		[16] = { 58, 14, 4.4, 275.7, 45, 3, },
		[17] = { 61, 14, 4.5, 328.55, 46, 3, },
		[18] = { 64, 15, 4.6, 390.81666666667, 47, 3, },
		[19] = { 67, 15, 4.7, 464.13333333333, 48, 3, },
		[20] = { 70, 16, 4.8, 550.33333333333, 49, 4, },
		[21] = { 72, 16, 5, 616.05, 50, 4, },
		[22] = { 74, 17, 5.1, 689.2, 51, 4, },
		[23] = { 76, 17, 5.2, 770.58333333333, 52, 4, },
		[24] = { 78, 18, 5.3, 861.11666666667, 53, 4, },
		[25] = { 80, 18, 5.4, 961.78333333333, 54, 5, },
		[26] = { 82, 19, 5.5, 1073.6833333333, 55, 5, },
		[27] = { 84, 19, 5.6, 1198.05, 56, 5, },
		[28] = { 86, 20, 5.7, 1336.2, 57, 5, },
		[29] = { 88, 20, 5.8, 1489.6166666667, 58, 5, },
		[30] = { 90, 21, 5.9, 1659.9833333333, 59, 6, },
	},
}
skills["Cyclone"] = {
	name = "Cyclone",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		movement = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [24] = true, [38] = true, },
	weaponTypes = {
		["None"] = true,
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
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
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 28, -55, },
		[2] = { 31, -54.4, },
		[3] = { 34, -53.8, },
		[4] = { 37, -53.2, },
		[5] = { 40, -52.6, },
		[6] = { 42, -52, },
		[7] = { 44, -51.4, },
		[8] = { 46, -50.8, },
		[9] = { 48, -50.2, },
		[10] = { 50, -49.6, },
		[11] = { 52, -49, },
		[12] = { 54, -48.4, },
		[13] = { 56, -47.8, },
		[14] = { 58, -47.2, },
		[15] = { 60, -46.6, },
		[16] = { 62, -46, },
		[17] = { 64, -45.4, },
		[18] = { 66, -44.8, },
		[19] = { 68, -44.2, },
		[20] = { 70, -43.6, },
		[21] = { 72, -43, },
		[22] = { 74, -42.4, },
		[23] = { 76, -41.8, },
		[24] = { 78, -41.2, },
		[25] = { 80, -40.6, },
		[26] = { 82, -40, },
		[27] = { 84, -39.4, },
		[28] = { 86, -38.8, },
		[29] = { 88, -38.2, },
		[30] = { 90, -37.6, },
	},
}
skills["VaalCyclone"] = {
	name = "Vaal Cyclone",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
		area = true,
		duration = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [24] = true, [12] = true, [43] = true, },
	weaponTypes = {
		["None"] = true,
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		mod("Speed", "MORE", 100, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = 100
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"base_skill_number_of_additional_hits" = 1
		mod("AreaOfEffect", "INC", 50), --"base_skill_area_of_effect_+%" = 50
		--"is_area_damage" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 28, -50, },
		[2] = { 31, -49.4, },
		[3] = { 34, -48.8, },
		[4] = { 37, -48.2, },
		[5] = { 40, -47.6, },
		[6] = { 42, -47, },
		[7] = { 44, -46.4, },
		[8] = { 46, -45.8, },
		[9] = { 48, -45.2, },
		[10] = { 50, -44.6, },
		[11] = { 52, -44, },
		[12] = { 54, -43.4, },
		[13] = { 56, -42.8, },
		[14] = { 58, -42.2, },
		[15] = { 60, -41.6, },
		[16] = { 62, -41, },
		[17] = { 64, -40.4, },
		[18] = { 66, -39.8, },
		[19] = { 68, -39.2, },
		[20] = { 70, -38.6, },
		[21] = { 72, -38, },
		[22] = { 74, -37.4, },
		[23] = { 76, -36.8, },
		[24] = { 78, -36.2, },
		[25] = { 80, -35.6, },
		[26] = { 82, -35, },
		[27] = { 84, -34.4, },
		[28] = { 86, -33.8, },
		[29] = { 88, -33.2, },
		[30] = { 90, -32.6, },
	},
}
skills["Desecrate"] = {
	name = "Desecrate",
	gemTags = {
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
		chaos = true,
	},
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
		skill("cooldown", 5), 
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"desecrate_number_of_corpses_to_create" = 3
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 1, ModFlag.Cast), --"base_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
		--[4] = "desecrate_corpse_level"
	},
	levels = {
		[1] = { 16, 8, 8.1666666666667, 20, },
		[2] = { 20, 8, 11.316666666667, 24, },
		[3] = { 24, 9, 15.383333333333, 26, },
		[4] = { 28, 9, 20.633333333333, 29, },
		[5] = { 31, 10, 25.533333333333, 32, },
		[6] = { 34, 11, 31.416666666667, 35, },
		[7] = { 37, 12, 38.466666666667, 38, },
		[8] = { 40, 12, 46.916666666667, 41, },
		[9] = { 43, 13, 57.016666666667, 44, },
		[10] = { 46, 14, 69.05, 47, },
		[11] = { 49, 15, 83.4, 50, },
		[12] = { 52, 16, 100.46666666667, 53, },
		[13] = { 55, 17, 120.73333333333, 56, },
		[14] = { 58, 18, 144.76666666667, 59, },
		[15] = { 60, 18, 163.23333333333, 63, },
		[16] = { 62, 18, 183.88333333333, 67, },
		[17] = { 64, 19, 207, 71, },
		[18] = { 66, 19, 232.83333333333, 75, },
		[19] = { 68, 20, 261.71666666667, 100, },
		[20] = { 70, 20, 294, 100, },
		[21] = { 72, 21, 330.05, 100, },
		[22] = { 74, 22, 370.3, 100, },
		[23] = { 76, 22, 415.21666666667, 100, },
		[24] = { 78, 22, 465.33333333333, 100, },
		[25] = { 80, 23, 521.21666666667, 100, },
		[26] = { 82, 23, 583.53333333333, 100, },
		[27] = { 84, 24, 652.98333333333, 100, },
		[28] = { 86, 25, 730.38333333333, 100, },
		[29] = { 88, 25, 816.58333333333, 100, },
		[30] = { 90, 26, 912.58333333333, 100, },
	},
}
skills["DetonateDead"] = {
	name = "Detonate Dead",
	gemTags = {
		dexterity = true,
		active_skill = true,
		cast = true,
		area = true,
		fire = true,
	},
	color = 2,
	baseFlags = {
		cast = true,
		area = true,
		fire = true,
	},
	skillTypes = { [39] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("critChance", 5), 
		--"corpse_explosion_monster_life_%" = 6
		--"is_area_damage" = 1
		--"display_skill_deals_secondary_damage" = ?
		--"damage_cannot_be_reflected" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 1, ModFlag.Cast), --"base_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("FireMin", nil), --"secondary_minimum_base_fire_damage"
		[4] = skill("FireMax", nil), --"secondary_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 4, 7, 4, 5, },
		[2] = { 6, 8, 5, 8, },
		[3] = { 9, 9, 8, 11, },
		[4] = { 12, 10, 9, 14, },
		[5] = { 16, 11, 13, 19, },
		[6] = { 20, 12, 17, 25, },
		[7] = { 24, 14, 22, 33, },
		[8] = { 28, 15, 28, 43, },
		[9] = { 32, 17, 36, 54, },
		[10] = { 36, 19, 46, 69, },
		[11] = { 40, 21, 58, 87, },
		[12] = { 44, 22, 72, 108, },
		[13] = { 48, 23, 90, 135, },
		[14] = { 52, 24, 111, 167, },
		[15] = { 55, 25, 130, 195, },
		[16] = { 58, 26, 152, 227, },
		[17] = { 61, 27, 176, 265, },
		[18] = { 64, 28, 205, 308, },
		[19] = { 67, 29, 238, 357, },
		[20] = { 70, 30, 276, 414, },
		[21] = { 72, 31, 304, 456, },
		[22] = { 74, 32, 335, 502, },
		[23] = { 76, 33, 369, 553, },
		[24] = { 78, 34, 406, 609, },
		[25] = { 80, 34, 446, 669, },
		[26] = { 82, 35, 491, 736, },
		[27] = { 84, 36, 539, 809, },
		[28] = { 86, 37, 592, 888, },
		[29] = { 88, 38, 650, 975, },
		[30] = { 90, 38, 713, 1070, },
	},
}
skills["VaalDetonateDead"] = {
	name = "Vaal Detonate Dead",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		cast = true,
		area = true,
		fire = true,
	},
	color = 2,
	baseFlags = {
		cast = true,
		area = true,
		fire = true,
	},
	skillTypes = { [39] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [43] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("critChance", 5), 
		--"corpse_explosion_monster_life_%" = 8
		--"is_area_damage" = 1
		--"display_skill_deals_secondary_damage" = ?
		--"detonate_dead_chain_explode" = ?
		--"damage_cannot_be_reflected" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 1, ModFlag.Cast), --"base_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("FireMin", nil), --"secondary_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"secondary_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 4, 3, 5, },
		[2] = { 6, 5, 7, },
		[3] = { 9, 7, 10, },
		[4] = { 12, 8, 12, },
		[5] = { 16, 11, 17, },
		[6] = { 20, 15, 23, },
		[7] = { 24, 20, 30, },
		[8] = { 28, 26, 39, },
		[9] = { 32, 33, 50, },
		[10] = { 36, 42, 63, },
		[11] = { 40, 53, 79, },
		[12] = { 44, 66, 99, },
		[13] = { 48, 82, 122, },
		[14] = { 52, 101, 151, },
		[15] = { 55, 118, 177, },
		[16] = { 58, 138, 207, },
		[17] = { 61, 160, 241, },
		[18] = { 64, 186, 280, },
		[19] = { 67, 216, 325, },
		[20] = { 70, 251, 376, },
		[21] = { 72, 276, 415, },
		[22] = { 74, 304, 457, },
		[23] = { 76, 335, 503, },
		[24] = { 78, 369, 553, },
		[25] = { 80, 406, 609, },
		[26] = { 82, 446, 669, },
		[27] = { 84, 490, 735, },
		[28] = { 86, 538, 807, },
		[29] = { 88, 591, 886, },
		[30] = { 90, 649, 973, },
	},
}
skills["DoubleStrike"] = {
	name = "Double Strike",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [25] = true, [28] = true, [24] = true, },
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, -30, },
		[2] = { 2, -28.6, },
		[3] = { 4, -27.2, },
		[4] = { 7, -25.8, },
		[5] = { 11, -24.4, },
		[6] = { 16, -23, },
		[7] = { 20, -21.6, },
		[8] = { 24, -20.2, },
		[9] = { 28, -18.8, },
		[10] = { 32, -17.4, },
		[11] = { 36, -16, },
		[12] = { 40, -14.6, },
		[13] = { 44, -13.2, },
		[14] = { 48, -11.8, },
		[15] = { 52, -10.4, },
		[16] = { 56, -9, },
		[17] = { 60, -7.6, },
		[18] = { 64, -6.2, },
		[19] = { 67, -4.8, },
		[20] = { 70, -3.4, },
		[21] = { 72, -2, },
		[22] = { 74, -0.6, },
		[23] = { 76, 0.8, },
		[24] = { 78, 2.2, },
		[25] = { 80, 3.6, },
		[26] = { 82, 5, },
		[27] = { 84, 6.4, },
		[28] = { 86, 7.8, },
		[29] = { 88, 9.2, },
		[30] = { 90, 10.6, },
	},
}
skills["VaalDoubleStrike"] = {
	name = "Vaal Double Strike",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
		melee = true,
		duration = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [7] = true, [25] = true, [28] = true, [24] = true, [12] = true, [43] = true, },
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"base_skill_number_of_additional_hits" = 1
		--"number_of_monsters_to_summon" = 1
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 1, -30, 3.6, },
		[2] = { 2, -29.2, 3.7, },
		[3] = { 4, -28.4, 3.8, },
		[4] = { 7, -27.6, 3.9, },
		[5] = { 11, -26.8, 4, },
		[6] = { 16, -26, 4.1, },
		[7] = { 20, -25.2, 4.2, },
		[8] = { 24, -24.4, 4.3, },
		[9] = { 28, -23.6, 4.4, },
		[10] = { 32, -22.8, 4.5, },
		[11] = { 36, -22, 4.6, },
		[12] = { 40, -21.2, 4.7, },
		[13] = { 44, -20.4, 4.8, },
		[14] = { 48, -19.6, 4.9, },
		[15] = { 52, -18.8, 5, },
		[16] = { 56, -18, 5.1, },
		[17] = { 60, -17.2, 5.2, },
		[18] = { 64, -16.4, 5.3, },
		[19] = { 67, -15.6, 5.4, },
		[20] = { 70, -14.8, 5.5, },
		[21] = { 72, -14, 5.6, },
		[22] = { 74, -13.2, 5.7, },
		[23] = { 76, -12.4, 5.8, },
		[24] = { 78, -11.6, 5.9, },
		[25] = { 80, -10.8, 6, },
		[26] = { 82, -10, 6.1, },
		[27] = { 84, -9.2, 6.2, },
		[28] = { 86, -8.4, 6.3, },
		[29] = { 88, -7.6, 6.4, },
		[30] = { 90, -6.8, 6.5, },
	},
}
skills["DualStrike"] = {
	name = "Dual Strike",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [4] = true, [25] = true, [28] = true, [24] = true, [53] = true, },
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Axe"] = true,
		["Dagger"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 5), 
		skill("doubleHitsWhenDualWielding", true), --"skill_double_hits_when_dual_wielding" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, -15, },
		[2] = { 2, -14, },
		[3] = { 4, -13, },
		[4] = { 7, -12, },
		[5] = { 11, -11, },
		[6] = { 16, -10, },
		[7] = { 20, -9, },
		[8] = { 24, -8, },
		[9] = { 28, -7, },
		[10] = { 32, -6, },
		[11] = { 36, -5, },
		[12] = { 40, -4, },
		[13] = { 44, -3, },
		[14] = { 48, -2, },
		[15] = { 52, -1, },
		[16] = { 56, nil, },
		[17] = { 60, 1, },
		[18] = { 64, 2, },
		[19] = { 67, 3, },
		[20] = { 70, 4, },
		[21] = { 72, 5, },
		[22] = { 74, 6, },
		[23] = { 76, 7, },
		[24] = { 78, 8, },
		[25] = { 80, 9, },
		[26] = { 82, 10, },
		[27] = { 84, 11, },
		[28] = { 86, 12, },
		[29] = { 88, 13, },
		[30] = { 90, 14, },
	},
}
skills["ElementalHit"] = {
	name = "Elemental Hit",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
		fire = true,
		cold = true,
		lightning = true,
		bow = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("FireMin", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 1 }), --"attack_minimum_base_fire_damage_for_elemental_hit"
		[4] = mod("FireMax", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 1 }), --"attack_maximum_base_fire_damage_for_elemental_hit"
		[5] = mod("ColdMin", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"attack_minimum_base_cold_damage_for_elemental_hit"
		[6] = mod("ColdMax", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 2 }), --"attack_maximum_base_cold_damage_for_elemental_hit"
		[7] = mod("LightningMin", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 3 }), --"attack_minimum_base_lightning_damage_for_elemental_hit"
		[8] = mod("LightningMax", "BASE", nil, ModFlag.Attack, 0, { type = "SkillPart", skillPart = 3 }), --"attack_maximum_base_lightning_damage_for_elemental_hit"
	},
	levels = {
		[1] = { 1, 6, 4, 8, 3, 6, 1, 13, },
		[2] = { 2, 6, 5, 9, 4, 7, 1, 14, },
		[3] = { 4, 6, 6, 11, 5, 9, 1, 17, },
		[4] = { 7, 7, 7, 14, 6, 11, 1, 23, },
		[5] = { 11, 7, 10, 19, 8, 16, 2, 31, },
		[6] = { 16, 7, 14, 27, 12, 22, 2, 44, },
		[7] = { 20, 8, 18, 34, 15, 28, 3, 56, },
		[8] = { 24, 8, 23, 43, 19, 35, 4, 70, },
		[9] = { 28, 8, 28, 53, 23, 43, 5, 87, },
		[10] = { 32, 9, 35, 64, 28, 53, 6, 106, },
		[11] = { 36, 9, 42, 78, 34, 64, 7, 128, },
		[12] = { 40, 9, 50, 93, 41, 76, 8, 153, },
		[13] = { 44, 10, 60, 111, 49, 91, 10, 183, },
		[14] = { 48, 10, 71, 132, 58, 108, 11, 217, },
		[15] = { 52, 10, 84, 156, 69, 127, 13, 256, },
		[16] = { 56, 11, 99, 183, 81, 150, 16, 301, },
		[17] = { 60, 11, 115, 214, 94, 175, 19, 352, },
		[18] = { 64, 11, 135, 250, 110, 205, 22, 411, },
		[19] = { 67, 11, 151, 280, 123, 229, 24, 461, },
		[20] = { 70, 12, 169, 314, 138, 257, 27, 516, },
		[21] = { 72, 12, 182, 338, 149, 276, 29, 555, },
		[22] = { 74, 12, 196, 364, 160, 297, 31, 598, },
		[23] = { 76, 12, 211, 391, 172, 320, 34, 643, },
		[24] = { 78, 13, 226, 420, 185, 344, 36, 691, },
		[25] = { 80, 13, 243, 452, 199, 370, 39, 743, },
		[26] = { 82, 13, 261, 485, 214, 397, 42, 798, },
		[27] = { 84, 13, 281, 521, 230, 426, 45, 857, },
		[28] = { 86, 14, 301, 559, 246, 457, 48, 919, },
		[29] = { 88, 14, 323, 600, 264, 491, 52, 986, },
		[30] = { 90, 14, 346, 643, 283, 526, 56, 1057, },
	},
}
skills["EtherealKnives"] = {
	name = "Ethereal Knives",
	gemTags = {
		projectile = true,
		dexterity = true,
		active_skill = true,
		spell = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[4] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
		[5] = mod("ProjectileSpeed", "INC", nil), --"base_projectile_speed_+%"
	},
	levels = {
		[1] = { 1, 5, 4, 6, 0, },
		[2] = { 2, 6, 5, 7, 1, },
		[3] = { 4, 7, 6, 9, 2, },
		[4] = { 7, 8, 8, 12, 3, },
		[5] = { 11, 9, 12, 18, 4, },
		[6] = { 16, 10, 18, 27, 5, },
		[7] = { 20, 11, 24, 37, 6, },
		[8] = { 24, 12, 32, 49, 7, },
		[9] = { 28, 13, 42, 64, 8, },
		[10] = { 32, 14, 55, 82, 9, },
		[11] = { 36, 16, 70, 105, 10, },
		[12] = { 40, 17, 89, 134, 11, },
		[13] = { 44, 18, 112, 169, 12, },
		[14] = { 48, 18, 141, 212, 13, },
		[15] = { 52, 19, 176, 265, 14, },
		[16] = { 56, 20, 219, 329, 15, },
		[17] = { 60, 21, 272, 408, 16, },
		[18] = { 64, 22, 336, 504, 17, },
		[19] = { 67, 22, 393, 590, 18, },
		[20] = { 70, 23, 459, 688, 19, },
		[21] = { 72, 24, 509, 763, 20, },
		[22] = { 74, 24, 563, 845, 21, },
		[23] = { 76, 25, 623, 935, 22, },
		[24] = { 78, 25, 690, 1034, 23, },
		[25] = { 80, 26, 762, 1144, 24, },
		[26] = { 82, 26, 842, 1264, 25, },
		[27] = { 84, 27, 931, 1396, 26, },
		[28] = { 86, 27, 1027, 1541, 27, },
		[29] = { 88, 28, 1134, 1701, 28, },
		[30] = { 90, 29, 1251, 1876, 29, },
	},
}
skills["ExplosiveArrow"] = {
	name = "Explosive Arrow",
	gemTags = {
		fire = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		duration = true,
		bow = true,
	},
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
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 6), 
		skill("duration", 1), --"base_skill_effect_duration" = 1000
		--"fuse_arrow_explosion_radius_+_per_fuse_arrow_orb" = 2
		--"active_skill_attack_damage_+%_final" = 0
		--"skill_can_fire_arrows" = 1
		--"base_is_projectile" = 1
		skill("showAverage", true, { type = "SkillPart", skillPart = 1 }), 
	},
	qualityMods = {
		mod("EnemyIgniteChance", "BASE", 1), --"base_chance_to_ignite_%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("FireMin", nil), --"minimum_fire_damage_per_fuse_arrow_orb"
		[4] = skill("FireMax", nil), --"maximum_fire_damage_per_fuse_arrow_orb"
	},
	levels = {
		[1] = { 28, 18, 44, 66, },
		[2] = { 31, 19, 54, 81, },
		[3] = { 34, 20, 66, 99, },
		[4] = { 37, 21, 80, 121, },
		[5] = { 40, 21, 98, 146, },
		[6] = { 42, 22, 111, 166, },
		[7] = { 44, 22, 126, 189, },
		[8] = { 46, 23, 142, 214, },
		[9] = { 48, 23, 161, 242, },
		[10] = { 50, 24, 182, 273, },
		[11] = { 52, 24, 205, 308, },
		[12] = { 54, 24, 232, 347, },
		[13] = { 56, 26, 261, 391, },
		[14] = { 58, 26, 293, 440, },
		[15] = { 60, 26, 330, 495, },
		[16] = { 62, 26, 371, 556, },
		[17] = { 64, 26, 416, 624, },
		[18] = { 66, 27, 467, 700, },
		[19] = { 68, 27, 523, 785, },
		[20] = { 70, 27, 586, 879, },
		[21] = { 72, 28, 656, 984, },
		[22] = { 74, 28, 734, 1100, },
		[23] = { 76, 29, 820, 1230, },
		[24] = { 78, 29, 917, 1375, },
		[25] = { 80, 30, 1024, 1536, },
		[26] = { 82, 30, 1143, 1714, },
		[27] = { 84, 30, 1275, 1913, },
		[28] = { 86, 30, 1422, 2134, },
		[29] = { 88, 31, 1586, 2379, },
		[30] = { 90, 31, 1767, 2651, },
	},
}
skills["FireTrap"] = {
	name = "Fire Trap",
	gemTags = {
		trap = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		duration = true,
		area = true,
		fire = true,
	},
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
		skill("cooldown", 3), 
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[4] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[5] = skill("FireDot", nil), --"base_fire_damage_to_deal_per_minute"
		--[6] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 1, 7, 2, 4, 3.6166666666667, 0, },
		[2] = { 2, 8, 3, 5, 4.1, 0, },
		[3] = { 4, 9, 4, 6, 5.2, 1, },
		[4] = { 7, 10, 6, 8, 7.1833333333333, 1, },
		[5] = { 11, 11, 8, 12, 10.6, 1, },
		[6] = { 16, 12, 13, 19, 16.416666666667, 2, },
		[7] = { 20, 13, 18, 27, 22.566666666667, 2, },
		[8] = { 24, 14, 25, 37, 30.466666666667, 2, },
		[9] = { 28, 14, 34, 50, 40.533333333333, 3, },
		[10] = { 32, 16, 45, 67, 53.333333333333, 3, },
		[11] = { 36, 17, 59, 89, 69.5, 3, },
		[12] = { 40, 18, 78, 117, 89.866666666667, 4, },
		[13] = { 44, 19, 101, 152, 115.41666666667, 4, },
		[14] = { 48, 20, 132, 197, 147.36666666667, 4, },
		[15] = { 52, 21, 170, 255, 187.21666666667, 5, },
		[16] = { 56, 22, 219, 328, 236.78333333333, 5, },
		[17] = { 60, 22, 280, 420, 298.28333333333, 5, },
		[18] = { 64, 23, 358, 536, 374.41666666667, 6, },
		[19] = { 67, 24, 429, 643, 441.11666666667, 6, },
		[20] = { 70, 24, 513, 770, 518.76666666667, 6, },
		[21] = { 72, 25, 578, 867, 573.95, 7, },
		[22] = { 74, 26, 651, 976, 634.4, 7, },
		[23] = { 76, 26, 732, 1098, 700.6, 7, },
		[24] = { 78, 27, 823, 1235, 772.98333333333, 8, },
		[25] = { 80, 27, 925, 1388, 852.1, 8, },
		[26] = { 82, 28, 1040, 1559, 938.5, 8, },
		[27] = { 84, 29, 1167, 1751, 1032.75, 9, },
		[28] = { 86, 30, 1310, 1965, 1135.4666666667, 9, },
		[29] = { 88, 30, 1470, 2205, 1247.3166666667, 9, },
		[30] = { 90, 30, 1648, 2472, 1368.9833333333, 10, },
	},
}
skills["FlickerStrike"] = {
	name = "Flicker Strike",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
		movement = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [24] = true, [25] = true, [28] = true, [38] = true, },
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 10), 
		skill("cooldown", 2), 
		mod("Speed", "MORE", 20, ModFlag.Attack), --"flicker_strike_more_attack_speed_+%_final" = 20
		mod("Speed", "INC", 10, ModFlag.Attack, 0, { type = "Multiplier", var = "FrenzyCharge" }), --"base_attack_speed_+%_per_frenzy_charge" = 10
		--"ignores_proximity_shield" = ?
		nil, --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 10, 30, },
		[2] = { 13, 31.6, },
		[3] = { 17, 33.2, },
		[4] = { 21, 34.8, },
		[5] = { 25, 36.4, },
		[6] = { 29, 38, },
		[7] = { 33, 39.6, },
		[8] = { 36, 41.2, },
		[9] = { 39, 42.8, },
		[10] = { 42, 44.4, },
		[11] = { 45, 46, },
		[12] = { 48, 47.6, },
		[13] = { 51, 49.2, },
		[14] = { 54, 50.8, },
		[15] = { 57, 52.4, },
		[16] = { 60, 54, },
		[17] = { 63, 55.6, },
		[18] = { 66, 57.2, },
		[19] = { 68, 58.8, },
		[20] = { 70, 60.4, },
		[21] = { 72, 62, },
		[22] = { 74, 63.6, },
		[23] = { 76, 65.2, },
		[24] = { 78, 66.8, },
		[25] = { 80, 68.4, },
		[26] = { 82, 70, },
		[27] = { 84, 71.6, },
		[28] = { 86, 73.2, },
		[29] = { 88, 74.8, },
		[30] = { 90, 76.4, },
	},
}
skills["FreezeMine"] = {
	name = "Freeze Mine",
	gemTags = {
		mine = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
		cold = true,
	},
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
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[4] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		--[5] = "freeze_as_though_dealt_damage_+%"
	},
	levels = {
		[1] = { 10, 6, 7, 10, 200, },
		[2] = { 13, 8, 9, 13, 210, },
		[3] = { 17, 10, 12, 17, 220, },
		[4] = { 21, 10, 15, 23, 230, },
		[5] = { 25, 11, 19, 29, 240, },
		[6] = { 29, 12, 24, 37, 250, },
		[7] = { 33, 13, 30, 46, 260, },
		[8] = { 36, 14, 36, 54, 270, },
		[9] = { 39, 14, 42, 63, 280, },
		[10] = { 42, 16, 49, 73, 290, },
		[11] = { 45, 18, 57, 85, 300, },
		[12] = { 48, 18, 66, 99, 310, },
		[13] = { 51, 19, 76, 114, 320, },
		[14] = { 54, 20, 88, 131, 330, },
		[15] = { 57, 21, 101, 151, 340, },
		[16] = { 60, 21, 116, 173, 350, },
		[17] = { 63, 21, 132, 199, 360, },
		[18] = { 66, 21, 151, 227, 370, },
		[19] = { 68, 22, 165, 248, 380, },
		[20] = { 70, 22, 181, 271, 390, },
		[21] = { 72, 22, 197, 296, 400, },
		[22] = { 74, 22, 215, 322, 410, },
		[23] = { 76, 23, 234, 351, 420, },
		[24] = { 78, 23, 255, 383, 430, },
		[25] = { 80, 24, 278, 417, 440, },
		[26] = { 82, 24, 302, 454, 450, },
		[27] = { 84, 24, 329, 493, 460, },
		[28] = { 86, 24, 358, 536, 470, },
		[29] = { 88, 25, 389, 583, 480, },
		[30] = { 90, 25, 422, 633, 490, },
	},
}
skills["Frenzy"] = {
	name = "Frenzy",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
		bow = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 16, 10, },
		[2] = { 20, 11.4, },
		[3] = { 24, 12.8, },
		[4] = { 28, 14.2, },
		[5] = { 31, 15.6, },
		[6] = { 34, 17, },
		[7] = { 37, 18.4, },
		[8] = { 40, 19.8, },
		[9] = { 43, 21.2, },
		[10] = { 46, 22.6, },
		[11] = { 49, 24, },
		[12] = { 52, 25.4, },
		[13] = { 55, 26.8, },
		[14] = { 58, 28.2, },
		[15] = { 60, 29.6, },
		[16] = { 62, 31, },
		[17] = { 64, 32.4, },
		[18] = { 66, 33.8, },
		[19] = { 68, 35.2, },
		[20] = { 70, 36.6, },
		[21] = { 72, 38, },
		[22] = { 74, 39.4, },
		[23] = { 76, 40.8, },
		[24] = { 78, 42.2, },
		[25] = { 80, 43.6, },
		[26] = { 82, 45, },
		[27] = { 84, 46.4, },
		[28] = { 86, 47.8, },
		[29] = { 88, 49.2, },
		[30] = { 90, 50.6, },
	},
}
skills["FrostBlades"] = {
	name = "Frost Blades",
	gemTags = {
		projectile = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
		cold = true,
	},
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
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		mod("PhysicalDamageConvertToCold", "BASE", 60, 0, 0, nil), --"base_physical_damage_%_to_convert_to_cold" = 60
		--"total_projectile_spread_angle_override" = 110
		--"show_number_of_projectiles" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, ModFlag.Projectile), --"projectile_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("ProjectileCount", "BASE", nil), --"number_of_additional_projectiles"
		--[3] = "melee_weapon_range_+"
		[4] = mod("ProjectileSpeed", "INC", nil), --"base_projectile_speed_+%"
		[5] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, 4, 18, 0, nil, },
		[2] = { 2, 4, 18, 1, 2.2, },
		[3] = { 4, 4, 18, 2, 4.4, },
		[4] = { 7, 4, 18, 3, 6.6, },
		[5] = { 11, 4, 18, 4, 8.8, },
		[6] = { 16, 5, 19, 5, 11, },
		[7] = { 20, 5, 19, 6, 13.2, },
		[8] = { 24, 5, 19, 7, 15.4, },
		[9] = { 28, 5, 19, 8, 17.6, },
		[10] = { 32, 5, 19, 9, 19.8, },
		[11] = { 36, 6, 20, 10, 22, },
		[12] = { 40, 6, 20, 11, 24.2, },
		[13] = { 44, 6, 20, 12, 26.4, },
		[14] = { 48, 6, 20, 13, 28.6, },
		[15] = { 52, 6, 20, 14, 30.8, },
		[16] = { 56, 7, 21, 15, 33, },
		[17] = { 60, 7, 21, 16, 35.2, },
		[18] = { 64, 7, 21, 17, 37.4, },
		[19] = { 67, 7, 21, 18, 39.6, },
		[20] = { 70, 7, 21, 19, 41.8, },
		[21] = { 72, 8, 22, 20, 44, },
		[22] = { 74, 8, 22, 21, 46.2, },
		[23] = { 76, 8, 22, 22, 48.4, },
		[24] = { 78, 8, 22, 23, 50.6, },
		[25] = { 80, 8, 22, 24, 52.8, },
		[26] = { 82, 9, 23, 25, 55, },
		[27] = { 84, 9, 23, 26, 57.2, },
		[28] = { 86, 9, 23, 27, 59.4, },
		[29] = { 88, 9, 23, 28, 61.6, },
		[30] = { 90, 9, 23, 29, 63.8, },
	},
}
skills["Grace"] = {
	name = "Grace",
	gemTags = {
		aura = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
	},
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
		skill("cooldown", 1.2), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Evasion", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_evasion_rating"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 227, 0, },
		[2] = { 27, 271, 3, },
		[3] = { 30, 322, 6, },
		[4] = { 33, 379, 9, },
		[5] = { 36, 444, 12, },
		[6] = { 39, 528, 15, },
		[7] = { 42, 621, 18, },
		[8] = { 45, 722, 21, },
		[9] = { 48, 845, 23, },
		[10] = { 50, 940, 25, },
		[11] = { 52, 1043, 27, },
		[12] = { 54, 1155, 29, },
		[13] = { 56, 1283, 31, },
		[14] = { 58, 1413, 33, },
		[15] = { 60, 1567, 35, },
		[16] = { 62, 1732, 36, },
		[17] = { 64, 1914, 37, },
		[18] = { 66, 2115, 38, },
		[19] = { 68, 2335, 39, },
		[20] = { 70, 2575, 40, },
		[21] = { 72, 2700, 41, },
		[22] = { 74, 2835, 42, },
		[23] = { 76, 2979, 43, },
		[24] = { 78, 3124, 44, },
		[25] = { 80, 3279, 45, },
		[26] = { 82, 3444, 46, },
		[27] = { 84, 3611, 47, },
		[28] = { 86, 3795, 48, },
		[29] = { 88, 3982, 49, },
		[30] = { 90, 4179, 50, },
	},
}
skills["VaalGrace"] = {
	name = "Vaal Grace",
	gemTags = {
		aura = true,
		dexterity = true,
		active_skill = true,
		vaal = true,
		spell = true,
		area = true,
		duration = true,
	},
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
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("AttackDodgeChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_chance_to_dodge_%"
		[3] = mod("SpellDodgeChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_chance_to_dodge_spells_%"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 24, 24, 0, },
		[2] = { 27, 25, 25, 3, },
		[3] = { 30, 25, 25, 6, },
		[4] = { 33, 26, 26, 9, },
		[5] = { 36, 26, 26, 12, },
		[6] = { 39, 27, 27, 15, },
		[7] = { 42, 27, 27, 18, },
		[8] = { 45, 28, 28, 21, },
		[9] = { 48, 28, 28, 23, },
		[10] = { 50, 29, 29, 25, },
		[11] = { 52, 29, 29, 27, },
		[12] = { 54, 30, 30, 29, },
		[13] = { 56, 30, 30, 31, },
		[14] = { 58, 31, 31, 33, },
		[15] = { 60, 31, 31, 35, },
		[16] = { 62, 32, 32, 36, },
		[17] = { 64, 32, 32, 37, },
		[18] = { 66, 33, 33, 38, },
		[19] = { 68, 33, 33, 39, },
		[20] = { 70, 34, 34, 40, },
		[21] = { 72, 34, 34, 41, },
		[22] = { 74, 35, 35, 42, },
		[23] = { 76, 35, 35, 43, },
		[24] = { 78, 36, 36, 44, },
		[25] = { 80, 36, 36, 45, },
		[26] = { 82, 37, 37, 46, },
		[27] = { 84, 37, 37, 47, },
		[28] = { 86, 38, 38, 48, },
		[29] = { 88, 38, 38, 49, },
		[30] = { 90, 39, 39, 50, },
	},
}
skills["Haste"] = {
	name = "Haste",
	gemTags = {
		aura = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
	},
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
		skill("cooldown", 1.2), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_speed_+%"
		[3] = mod("Speed", "INC", nil, ModFlag.Cast, 0, { type = "GlobalEffect", effectType = "Aura" }), --"cast_speed_+%_from_haste_aura"
		[4] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_movement_velocity_+%"
		[5] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 9, 9, 4, 0, },
		[2] = { 27, 10, 9, 4, 3, },
		[3] = { 30, 10, 10, 4, 6, },
		[4] = { 33, 10, 10, 5, 9, },
		[5] = { 36, 11, 10, 5, 12, },
		[6] = { 39, 11, 11, 5, 15, },
		[7] = { 42, 11, 11, 6, 18, },
		[8] = { 45, 12, 11, 6, 21, },
		[9] = { 48, 12, 12, 6, 23, },
		[10] = { 50, 12, 12, 7, 25, },
		[11] = { 52, 13, 12, 7, 27, },
		[12] = { 54, 13, 13, 7, 29, },
		[13] = { 56, 13, 13, 8, 31, },
		[14] = { 58, 14, 13, 8, 33, },
		[15] = { 60, 14, 14, 8, 35, },
		[16] = { 62, 15, 14, 8, 36, },
		[17] = { 64, 15, 15, 8, 37, },
		[18] = { 66, 16, 15, 8, 38, },
		[19] = { 68, 16, 16, 8, 39, },
		[20] = { 70, 16, 16, 9, 40, },
		[21] = { 72, 17, 16, 9, 41, },
		[22] = { 74, 17, 17, 9, 42, },
		[23] = { 76, 17, 17, 10, 43, },
		[24] = { 78, 18, 17, 10, 44, },
		[25] = { 80, 18, 18, 10, 45, },
		[26] = { 82, 18, 18, 11, 46, },
		[27] = { 84, 19, 18, 11, 47, },
		[28] = { 86, 19, 19, 11, 48, },
		[29] = { 88, 19, 19, 12, 49, },
		[30] = { 90, 20, 19, 12, 50, },
	},
}
skills["VaalHaste"] = {
	name = "Vaal Haste",
	gemTags = {
		aura = true,
		dexterity = true,
		active_skill = true,
		vaal = true,
		spell = true,
		area = true,
		duration = true,
	},
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
		skill("duration", 4), --"base_skill_effect_duration" = 4000
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_speed_+%"
		[3] = mod("Speed", "INC", nil, ModFlag.Cast, 0, { type = "GlobalEffect", effectType = "Aura" }), --"cast_speed_+%_from_haste_aura"
		[4] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_movement_velocity_+%"
		[5] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 25, 24, 10, 0, },
		[2] = { 27, 25, 25, 10, 3, },
		[3] = { 30, 25, 25, 10, 6, },
		[4] = { 33, 26, 25, 10, 9, },
		[5] = { 36, 26, 26, 10, 12, },
		[6] = { 39, 26, 26, 11, 15, },
		[7] = { 42, 27, 26, 11, 18, },
		[8] = { 45, 27, 27, 11, 21, },
		[9] = { 48, 27, 27, 11, 23, },
		[10] = { 50, 28, 27, 11, 25, },
		[11] = { 52, 28, 28, 12, 27, },
		[12] = { 54, 28, 28, 12, 29, },
		[13] = { 56, 29, 28, 12, 31, },
		[14] = { 58, 29, 29, 12, 33, },
		[15] = { 60, 29, 29, 12, 35, },
		[16] = { 62, 30, 29, 13, 36, },
		[17] = { 64, 30, 30, 13, 37, },
		[18] = { 66, 30, 30, 13, 38, },
		[19] = { 68, 31, 30, 13, 39, },
		[20] = { 70, 31, 31, 13, 40, },
		[21] = { 72, 31, 31, 14, 41, },
		[22] = { 74, 32, 31, 14, 42, },
		[23] = { 76, 32, 32, 14, 43, },
		[24] = { 78, 32, 32, 14, 44, },
		[25] = { 80, 33, 32, 14, 45, },
		[26] = { 82, 33, 33, 15, 46, },
		[27] = { 84, 33, 33, 15, 47, },
		[28] = { 86, 34, 33, 15, 48, },
		[29] = { 88, 34, 34, 15, 49, },
		[30] = { 90, 34, 34, 15, 50, },
	},
}
skills["Hatred"] = {
	name = "Hatred",
	gemTags = {
		aura = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		cold = true,
	},
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
		skill("cooldown", 1.2), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("PhysicalDamageGainAsCold", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"physical_damage_%_to_add_as_cold"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 26, 0, },
		[2] = { 27, 26, 3, },
		[3] = { 30, 27, 6, },
		[4] = { 33, 27, 9, },
		[5] = { 36, 28, 12, },
		[6] = { 39, 28, 15, },
		[7] = { 42, 29, 18, },
		[8] = { 45, 29, 21, },
		[9] = { 48, 30, 23, },
		[10] = { 50, 30, 25, },
		[11] = { 52, 31, 27, },
		[12] = { 54, 31, 29, },
		[13] = { 56, 32, 31, },
		[14] = { 58, 32, 33, },
		[15] = { 60, 33, 35, },
		[16] = { 62, 34, 36, },
		[17] = { 64, 34, 37, },
		[18] = { 66, 35, 38, },
		[19] = { 68, 35, 39, },
		[20] = { 70, 36, 40, },
		[21] = { 72, 36, 41, },
		[22] = { 74, 37, 42, },
		[23] = { 76, 37, 43, },
		[24] = { 78, 38, 44, },
		[25] = { 80, 38, 45, },
		[26] = { 82, 39, 46, },
		[27] = { 84, 39, 47, },
		[28] = { 86, 40, 48, },
		[29] = { 88, 40, 49, },
		[30] = { 90, 41, 50, },
	},
}
skills["HeraldOfIce"] = {
	name = "Herald of Ice",
	gemTags = {
		dexterity = true,
		active_skill = true,
		cast = true,
		area = true,
		cold = true,
	},
	color = 2,
	baseFlags = {
		cast = true,
		area = true,
		cold = true,
	},
	skillTypes = { [39] = true, [5] = true, [15] = true, [16] = true, [10] = true, [11] = true, [34] = true, [27] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 25), 
		skill("damageEffectiveness", 0.8), 
		skill("cooldown", 1), 
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("ColdMin", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_minimum_added_cold_damage"
		[3] = mod("ColdMax", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_maximum_added_cold_damage"
		[4] = mod("ColdMin", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_minimum_added_cold_damage"
		[5] = mod("ColdMax", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_maximum_added_cold_damage"
		[6] = skill("ColdMin", nil), --"secondary_minimum_base_cold_damage"
		[7] = skill("ColdMax", nil), --"secondary_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 16, 4, 5, 4, 5, 18, 26, },
		[2] = { 20, 5, 7, 5, 7, 23, 35, },
		[3] = { 24, 6, 8, 6, 8, 30, 45, },
		[4] = { 28, 7, 10, 7, 10, 38, 57, },
		[5] = { 31, 8, 12, 8, 12, 45, 67, },
		[6] = { 34, 9, 14, 9, 14, 53, 80, },
		[7] = { 37, 10, 16, 10, 16, 62, 94, },
		[8] = { 40, 12, 18, 12, 18, 73, 110, },
		[9] = { 43, 13, 20, 13, 20, 85, 128, },
		[10] = { 46, 15, 23, 15, 23, 99, 149, },
		[11] = { 49, 17, 26, 17, 26, 115, 173, },
		[12] = { 52, 19, 29, 19, 29, 134, 200, },
		[13] = { 55, 22, 33, 22, 33, 154, 232, },
		[14] = { 58, 24, 37, 24, 37, 178, 267, },
		[15] = { 60, 26, 39, 26, 39, 195, 293, },
		[16] = { 62, 28, 42, 28, 42, 214, 321, },
		[17] = { 64, 30, 46, 30, 46, 235, 352, },
		[18] = { 66, 33, 49, 33, 49, 257, 386, },
		[19] = { 68, 35, 53, 35, 53, 282, 422, },
		[20] = { 70, 38, 56, 38, 56, 308, 462, },
		[21] = { 72, 40, 61, 40, 61, 337, 505, },
		[22] = { 74, 43, 65, 43, 65, 368, 552, },
		[23] = { 76, 46, 70, 46, 70, 402, 603, },
		[24] = { 78, 50, 75, 50, 75, 438, 658, },
		[25] = { 80, 53, 80, 53, 80, 478, 717, },
		[26] = { 82, 57, 85, 57, 85, 521, 782, },
		[27] = { 84, 61, 91, 61, 91, 568, 852, },
		[28] = { 86, 65, 98, 65, 98, 619, 928, },
		[29] = { 88, 69, 104, 69, 104, 674, 1010, },
		[30] = { 90, 74, 111, 74, 111, 733, 1100, },
	},
}
skills["IceShot"] = {
	name = "Ice Shot",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		duration = true,
		cold = true,
		bow = true,
	},
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
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		mod("SkillPhysicalDamageConvertToCold", "BASE", 60), --"skill_physical_damage_%_to_convert_to_cold" = 60
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		--"skill_can_fire_arrows" = ?
		mod("SkillPhysicalDamageConvertToCold", "BASE", 40, 0, 0, { type = "SkillPart", skillPart = 2 }), 
	},
	qualityMods = {
		mod("ColdDamage", "INC", 1), --"cold_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, 6, 20, },
		[2] = { 2, 6, 21.4, },
		[3] = { 4, 6, 22.8, },
		[4] = { 7, 7, 24.2, },
		[5] = { 11, 7, 25.6, },
		[6] = { 16, 7, 27, },
		[7] = { 20, 7, 28.4, },
		[8] = { 24, 8, 29.8, },
		[9] = { 28, 8, 31.2, },
		[10] = { 32, 8, 32.6, },
		[11] = { 36, 8, 34, },
		[12] = { 40, 8, 35.4, },
		[13] = { 44, 9, 36.8, },
		[14] = { 48, 9, 38.2, },
		[15] = { 52, 9, 39.6, },
		[16] = { 56, 9, 41, },
		[17] = { 60, 9, 42.4, },
		[18] = { 64, 10, 43.8, },
		[19] = { 67, 10, 45.2, },
		[20] = { 70, 10, 46.6, },
		[21] = { 72, 10, 48, },
		[22] = { 74, 10, 49.4, },
		[23] = { 76, 11, 50.8, },
		[24] = { 78, 11, 52.2, },
		[25] = { 80, 11, 53.6, },
		[26] = { 82, 11, 55, },
		[27] = { 84, 11, 56.4, },
		[28] = { 86, 12, 57.8, },
		[29] = { 88, 12, 59.2, },
		[30] = { 90, 12, 60.6, },
	},
}
skills["IceTrap"] = {
	name = "Ice Trap",
	gemTags = {
		trap = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		cold = true,
		duration = true,
	},
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
		skill("cooldown", 2), 
		--"base_trap_duration" = 16000
		--"is_area_damage" = ?
		--"base_skill_is_trapped" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_trap" = ?
		skill("trapCooldown", 2), 
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[4] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 28, 13, 60, 90, },
		[2] = { 31, 14, 72, 108, },
		[3] = { 34, 15, 85, 128, },
		[4] = { 37, 15, 101, 151, },
		[5] = { 40, 16, 119, 178, },
		[6] = { 42, 17, 132, 198, },
		[7] = { 44, 17, 147, 220, },
		[8] = { 46, 18, 163, 244, },
		[9] = { 48, 19, 180, 270, },
		[10] = { 50, 19, 199, 299, },
		[11] = { 52, 20, 220, 330, },
		[12] = { 54, 20, 243, 364, },
		[13] = { 56, 21, 268, 402, },
		[14] = { 58, 21, 295, 442, },
		[15] = { 60, 22, 325, 487, },
		[16] = { 62, 23, 357, 536, },
		[17] = { 64, 23, 392, 589, },
		[18] = { 66, 24, 431, 646, },
		[19] = { 68, 24, 473, 709, },
		[20] = { 70, 25, 519, 778, },
		[21] = { 72, 26, 568, 853, },
		[22] = { 74, 26, 623, 934, },
		[23] = { 76, 27, 681, 1022, },
		[24] = { 78, 27, 746, 1118, },
		[25] = { 80, 28, 815, 1223, },
		[26] = { 82, 28, 891, 1337, },
		[27] = { 84, 29, 973, 1460, },
		[28] = { 86, 30, 1063, 1595, },
		[29] = { 88, 30, 1160, 1740, },
		[30] = { 90, 31, 1266, 1899, },
	},
}
skills["DoubleSlash"] = {
	name = "Lacerate",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		melee = true,
	},
	parts = {
		{
			name = "One slash",
		},
		{
			name = "Both slashes",
		},
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [28] = true, [24] = true, },
	weaponTypes = {
		["Two Handed Axe"] = true,
		["Two Handed Sword"] = true,
		["One Handed Axe"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 8), 
		mod("Speed", "MORE", -25, ModFlag.Attack), --"active_skill_attack_speed_+%_final" = -25
		--"is_area_damage" = ?
		skill("dpsMultiplier", 2, { type = "SkillPart", skillPart = 2 }), 
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		--[3] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 12, -5, 0, },
		[2] = { 15, -3.8, 0, },
		[3] = { 19, -2.6, 0, },
		[4] = { 23, -1.4, 1, },
		[5] = { 27, -0.2, 1, },
		[6] = { 31, 1, 1, },
		[7] = { 35, 2.2, 1, },
		[8] = { 38, 3.4, 2, },
		[9] = { 41, 4.6, 2, },
		[10] = { 44, 5.8, 2, },
		[11] = { 47, 7, 2, },
		[12] = { 50, 8.2, 3, },
		[13] = { 53, 9.4, 3, },
		[14] = { 56, 10.6, 3, },
		[15] = { 59, 11.8, 3, },
		[16] = { 62, 13, 4, },
		[17] = { 64, 14.2, 4, },
		[18] = { 66, 15.4, 4, },
		[19] = { 68, 16.6, 4, },
		[20] = { 70, 17.8, 5, },
		[21] = { 72, 19, 5, },
		[22] = { 74, 20.2, 5, },
		[23] = { 76, 21.4, 5, },
		[24] = { 78, 22.6, 6, },
		[25] = { 80, 23.8, 6, },
		[26] = { 82, 25, 6, },
		[27] = { 84, 26.2, 6, },
		[28] = { 86, 27.4, 7, },
		[29] = { 88, 28.6, 7, },
		[30] = { 90, 29.8, 7, },
	},
}
skills["LightningArrow"] = {
	name = "Lightning Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		lightning = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		lightning = true,
	},
	skillTypes = { [1] = true, [48] = true, [11] = true, [3] = true, [22] = true, [17] = true, [19] = true, [35] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		mod("SkillPhysicalDamageConvertToLightning", "BASE", 50), --"skill_physical_damage_%_to_convert_to_lightning" = 50
		--"lightning_arrow_maximum_number_of_extra_targets" = 3
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("EnemyShockChance", "BASE", 0.5), --"base_chance_to_shock_%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 12, 7, nil, },
		[2] = { 15, 7, 1, },
		[3] = { 19, 7, 2, },
		[4] = { 23, 8, 3, },
		[5] = { 27, 8, 4, },
		[6] = { 31, 8, 5, },
		[7] = { 35, 8, 6, },
		[8] = { 38, 8, 7, },
		[9] = { 41, 9, 8, },
		[10] = { 44, 9, 9, },
		[11] = { 47, 9, 10, },
		[12] = { 50, 9, 11, },
		[13] = { 53, 9, 12, },
		[14] = { 56, 10, 13, },
		[15] = { 59, 10, 14, },
		[16] = { 62, 10, 15, },
		[17] = { 64, 10, 16, },
		[18] = { 66, 10, 17, },
		[19] = { 68, 11, 18, },
		[20] = { 70, 11, 19, },
		[21] = { 72, 11, 20, },
		[22] = { 74, 11, 21, },
		[23] = { 76, 11, 22, },
		[24] = { 78, 11, 23, },
		[25] = { 80, 11, 24, },
		[26] = { 82, 12, 25, },
		[27] = { 84, 12, 26, },
		[28] = { 86, 12, 27, },
		[29] = { 88, 12, 28, },
		[30] = { 90, 12, 29, },
	},
}
skills["LightningStrike"] = {
	name = "Lightning Strike",
	gemTags = {
		projectile = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
		lightning = true,
	},
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
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		mod("SkillPhysicalDamageConvertToLightning", "BASE", 50), --"skill_physical_damage_%_to_convert_to_lightning" = 50
		mod("Damage", "MORE", -25, ModFlag.Projectile), --"active_skill_projectile_damage_+%_final" = -25
		--"total_projectile_spread_angle_override" = 70
		--"show_number_of_projectiles" = ?
	},
	qualityMods = {
		mod("PierceChance", "BASE", 2), --"pierce_%" = 2
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("ProjectileCount", "BASE", nil), --"number_of_additional_projectiles"
	},
	levels = {
		[1] = { 12, 30, 4, },
		[2] = { 15, 32.4, 4, },
		[3] = { 19, 34.8, 4, },
		[4] = { 23, 37.2, 4, },
		[5] = { 27, 39.6, 4, },
		[6] = { 31, 42, 5, },
		[7] = { 35, 44.4, 5, },
		[8] = { 38, 46.8, 5, },
		[9] = { 41, 49.2, 5, },
		[10] = { 44, 51.6, 5, },
		[11] = { 47, 54, 6, },
		[12] = { 50, 56.4, 6, },
		[13] = { 53, 58.8, 6, },
		[14] = { 56, 61.2, 6, },
		[15] = { 59, 63.6, 6, },
		[16] = { 62, 66, 7, },
		[17] = { 64, 68.4, 7, },
		[18] = { 66, 70.8, 7, },
		[19] = { 68, 73.2, 7, },
		[20] = { 70, 75.6, 7, },
		[21] = { 72, 78, 8, },
		[22] = { 74, 80.4, 8, },
		[23] = { 76, 82.8, 8, },
		[24] = { 78, 85.2, 8, },
		[25] = { 80, 87.6, 8, },
		[26] = { 82, 90, 9, },
		[27] = { 84, 92.4, 9, },
		[28] = { 86, 94.8, 9, },
		[29] = { 88, 97.2, 9, },
		[30] = { 90, 99.6, 9, },
	},
}
skills["VaalLightningStrike"] = {
	name = "Vaal Lightning Strike",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
		melee = true,
		duration = true,
		lightning = true,
	},
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
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		mod("SkillPhysicalDamageConvertToLightning", "BASE", 50), --"skill_physical_damage_%_to_convert_to_lightning" = 50
		mod("Damage", "MORE", -50, 0, 0, { type = "SkillPart", skillPart = 2 }), --"vaal_lightning_strike_beam_damage_+%_final" = -50
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 12, 5, nil, },
		[2] = { 15, 5.2, 1.2, },
		[3] = { 19, 5.4, 2.4, },
		[4] = { 23, 5.6, 3.6, },
		[5] = { 27, 5.8, 4.8, },
		[6] = { 31, 6, 6, },
		[7] = { 35, 6.2, 7.2, },
		[8] = { 38, 6.4, 8.4, },
		[9] = { 41, 6.6, 9.6, },
		[10] = { 44, 6.8, 10.8, },
		[11] = { 47, 7, 12, },
		[12] = { 50, 7.2, 13.2, },
		[13] = { 53, 7.4, 14.4, },
		[14] = { 56, 7.6, 15.6, },
		[15] = { 59, 7.8, 16.8, },
		[16] = { 62, 8, 18, },
		[17] = { 64, 8.2, 19.2, },
		[18] = { 66, 8.4, 20.4, },
		[19] = { 68, 8.6, 21.6, },
		[20] = { 70, 8.8, 22.8, },
		[21] = { 72, 9, 24, },
		[22] = { 74, 9.2, 25.2, },
		[23] = { 76, 9.4, 26.4, },
		[24] = { 78, 9.6, 27.6, },
		[25] = { 80, 9.8, 28.8, },
		[26] = { 82, 10, 30, },
		[27] = { 84, 10.2, 31.2, },
		[28] = { 86, 10.4, 32.4, },
		[29] = { 88, 10.6, 33.6, },
		[30] = { 90, 10.8, 34.8, },
	},
}
skills["MirrorArrow"] = {
	name = "Mirror Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		minion = true,
		duration = true,
		bow = true,
	},
	minionList = {
		"Clone",
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		minion = true,
		movement = true,
		duration = true,
	},
	skillTypes = { [14] = true, [1] = true, [9] = true, [48] = true, [21] = true, [12] = true, [22] = true, [17] = true, [19] = true, },
	minionSkillTypes = { [1] = true, [3] = true, [48] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("cooldown", 3), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"number_of_monsters_to_summon" = 1
		mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Damage", "MORE", 75) }), --"active_skill_minion_damage_+%_final" = 75
		--"display_minion_monster_type" = 4
		--"base_is_projectile" = ?
		skill("minionUseBowAndQuiver", true), 
	},
	qualityMods = {
		--"base_arrow_speed_+%" = 1.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Damage", "INC", nil) }), --"minion_damage_+%"
		[4] = mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Life", "INC", nil) }), --"minion_maximum_life_+%"
		[5] = skill("minionLevel", nil), --"display_minion_monster_level"
	},
	levels = {
		[1] = { 10, 14, 0, 0, 24, },
		[2] = { 13, 14, 6, 3, 27, },
		[3] = { 17, 15, 12, 6, 30, },
		[4] = { 21, 15, 18, 9, 33, },
		[5] = { 25, 15, 24, 12, 35, },
		[6] = { 29, 16, 30, 15, 38, },
		[7] = { 33, 16, 36, 18, 40, },
		[8] = { 36, 16, 42, 21, 43, },
		[9] = { 39, 16, 48, 24, 46, },
		[10] = { 42, 17, 54, 27, 48, },
		[11] = { 45, 17, 60, 30, 50, },
		[12] = { 48, 17, 66, 33, 52, },
		[13] = { 51, 17, 72, 36, 54, },
		[14] = { 54, 18, 78, 39, 56, },
		[15] = { 57, 18, 84, 42, 58, },
		[16] = { 60, 18, 90, 45, 60, },
		[17] = { 63, 19, 96, 48, 62, },
		[18] = { 66, 19, 102, 51, 64, },
		[19] = { 68, 20, 108, 54, 66, },
		[20] = { 70, 20, 114, 57, 68, },
		[21] = { 72, 21, 120, 60, 70, },
		[22] = { 74, 21, 126, 63, 72, },
		[23] = { 76, 22, 132, 66, 74, },
		[24] = { 78, 22, 138, 69, 76, },
		[25] = { 80, 22, 144, 72, 78, },
		[26] = { 82, 23, 150, 75, 80, },
		[27] = { 84, 23, 156, 78, 82, },
		[28] = { 86, 23, 162, 81, 84, },
		[29] = { 88, 23, 168, 84, 86, },
		[30] = { 90, 24, 174, 87, 88, },
	},
}
skills["NewPhaseRun"] = {
	name = "Phase Run",
	gemTags = {
		dexterity = true,
		active_skill = true,
		spell = true,
		duration = true,
		movement = true,
	},
	color = 2,
	baseFlags = {
		spell = true,
		duration = true,
		movement = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [36] = true, [38] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("cooldown", 4), 
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_movement_velocity_+%"
		[4] = mod("PhysicalDamage", "MORE", nil, ModFlag.Melee, 0, { type = "GlobalEffect", effectType = "Buff" }), --"phase_run_melee_physical_damage_+%_final"
	},
	levels = {
		[1] = { 34, 11, 30, 20, },
		[2] = { 36, 11, 30, 21, },
		[3] = { 38, 11, 31, 21, },
		[4] = { 40, 11, 31, 22, },
		[5] = { 42, 11, 32, 22, },
		[6] = { 44, 12, 32, 23, },
		[7] = { 46, 12, 33, 23, },
		[8] = { 48, 12, 33, 24, },
		[9] = { 50, 12, 34, 24, },
		[10] = { 52, 12, 34, 25, },
		[11] = { 54, 12, 35, 25, },
		[12] = { 56, 12, 35, 26, },
		[13] = { 58, 13, 36, 26, },
		[14] = { 60, 13, 36, 27, },
		[15] = { 62, 13, 37, 27, },
		[16] = { 64, 13, 37, 28, },
		[17] = { 66, 13, 38, 28, },
		[18] = { 68, 13, 38, 29, },
		[19] = { 69, 14, 39, 29, },
		[20] = { 70, 14, 39, 30, },
		[21] = { 72, 14, 40, 30, },
		[22] = { 74, 14, 40, 31, },
		[23] = { 76, 14, 41, 31, },
		[24] = { 78, 14, 41, 32, },
		[25] = { 80, 14, 42, 32, },
		[26] = { 82, 14, 42, 33, },
		[27] = { 84, 14, 43, 33, },
		[28] = { 86, 14, 43, 34, },
		[29] = { 88, 14, 44, 34, },
		[30] = { 90, 14, 44, 35, },
	},
}
skills["PoachersMark"] = {
	name = "Poacher's Mark",
	gemTags = {
		curse = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[5] = mod("Evasion", "MORE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse"}), --"evasion_rating_+%_final_from_poachers_mark"
		[6] = mod("SelfLifeOnHit", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Curse" }), --"life_granted_when_hit_by_attacks"
		[7] = mod("SelfManaOnHit", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Curse" }), --"mana_granted_when_hit_by_attacks"
		--[8] = "chance_to_grant_frenzy_charge_on_death_%"
	},
	levels = {
		[1] = { 24, 24, 6, 0, -30, 5, 5, 21, },
		[2] = { 27, 26, 6.2, 4, -31, 6, 6, 21, },
		[3] = { 30, 27, 6.4, 8, -32, 7, 6, 22, },
		[4] = { 33, 29, 6.6, 12, -33, 8, 6, 22, },
		[5] = { 36, 30, 6.8, 16, -34, 9, 7, 23, },
		[6] = { 39, 32, 7, 20, -35, 10, 7, 23, },
		[7] = { 42, 34, 7.2, 24, -36, 11, 7, 24, },
		[8] = { 45, 35, 7.4, 28, -37, 12, 8, 24, },
		[9] = { 48, 37, 7.6, 32, -38, 13, 8, 25, },
		[10] = { 50, 38, 7.8, 36, -39, 14, 8, 25, },
		[11] = { 52, 39, 8, 40, -40, 15, 9, 26, },
		[12] = { 54, 40, 8.2, 44, -41, 16, 9, 26, },
		[13] = { 56, 42, 8.4, 48, -42, 17, 9, 27, },
		[14] = { 58, 43, 8.6, 52, -43, 18, 10, 27, },
		[15] = { 60, 44, 8.8, 56, -44, 19, 10, 28, },
		[16] = { 62, 45, 9, 60, -45, 20, 10, 28, },
		[17] = { 64, 46, 9.2, 64, -46, 21, 11, 29, },
		[18] = { 66, 47, 9.4, 68, -47, 22, 11, 29, },
		[19] = { 68, 48, 9.6, 72, -48, 23, 11, 30, },
		[20] = { 70, 50, 9.8, 76, -49, 24, 12, 30, },
		[21] = { 72, 51, 10, 80, -50, 25, 12, 31, },
		[22] = { 74, 52, 10.2, 84, -51, 26, 12, 31, },
		[23] = { 76, 53, 10.4, 88, -52, 27, 13, 32, },
		[24] = { 78, 54, 10.6, 92, -53, 28, 13, 32, },
		[25] = { 80, 56, 10.8, 96, -54, 29, 13, 33, },
		[26] = { 82, 57, 11, 100, -55, 30, 14, 33, },
		[27] = { 84, 58, 11.2, 104, -56, 31, 14, 34, },
		[28] = { 86, 59, 11.4, 108, -57, 32, 14, 34, },
		[29] = { 88, 60, 11.6, 112, -58, 33, 15, 35, },
		[30] = { 90, 61, 11.8, 116, -59, 34, 15, 35, },
	},
}
skills["ProjectileWeakness"] = {
	name = "Projectile Weakness",
	gemTags = {
		curse = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
	},
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
		mod("ProjectileDamageTaken", "INC", 0.5, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"projectile_damage_taken_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[5] = mod("ProjectileDamageTaken", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"projectile_damage_taken_+%"
	},
	levels = {
		[1] = { 24, 24, 9, 0, 25, },
		[2] = { 27, 26, 9.1, 4, 26, },
		[3] = { 30, 27, 9.2, 8, 27, },
		[4] = { 33, 29, 9.3, 12, 28, },
		[5] = { 36, 30, 9.4, 16, 29, },
		[6] = { 39, 32, 9.5, 20, 30, },
		[7] = { 42, 34, 9.6, 24, 31, },
		[8] = { 45, 35, 9.7, 28, 32, },
		[9] = { 48, 37, 9.8, 32, 33, },
		[10] = { 50, 38, 9.9, 36, 34, },
		[11] = { 52, 39, 10, 40, 35, },
		[12] = { 54, 40, 10.1, 44, 36, },
		[13] = { 56, 42, 10.2, 48, 37, },
		[14] = { 58, 43, 10.3, 52, 38, },
		[15] = { 60, 44, 10.4, 56, 39, },
		[16] = { 62, 45, 10.5, 60, 40, },
		[17] = { 64, 46, 10.6, 64, 41, },
		[18] = { 66, 47, 10.7, 68, 42, },
		[19] = { 68, 48, 10.8, 72, 43, },
		[20] = { 70, 50, 10.9, 76, 44, },
		[21] = { 72, 51, 11, 80, 45, },
		[22] = { 74, 52, 11.1, 84, 46, },
		[23] = { 76, 53, 11.2, 88, 47, },
		[24] = { 78, 54, 11.3, 92, 48, },
		[25] = { 80, 56, 11.4, 96, 49, },
		[26] = { 82, 57, 11.5, 100, 50, },
		[27] = { 84, 58, 11.6, 104, 51, },
		[28] = { 86, 59, 11.7, 108, 52, },
		[29] = { 88, 60, 11.8, 112, 53, },
		[30] = { 90, 61, 11.9, 116, 54, },
	},
}
skills["Puncture"] = {
	name = "Puncture",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		duration = true,
		melee = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
		duration = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [12] = true, [17] = true, [19] = true, [22] = true, [25] = true, [28] = true, [24] = true, [40] = true, },
	weaponTypes = {
		["Bow"] = true,
		["Claw"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		skill("bleedBasePercent", 10), --"base_bleed_on_hit_still_%_of_physical_damage_to_deal_per_minute" = 600
		--"base_bleed_on_hit_moving_%_of_physical_damage_to_deal_per_minute" = 3000
		--"bleed_on_hit_base_duration" = 5000
		--"skill_can_fire_arrows" = ?
		mod("BleedChance", "BASE", 100), 
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 4, nil, },
		[2] = { 6, 1.2, },
		[3] = { 9, 2.4, },
		[4] = { 12, 3.6, },
		[5] = { 16, 4.8, },
		[6] = { 20, 6, },
		[7] = { 24, 7.2, },
		[8] = { 28, 8.4, },
		[9] = { 32, 9.6, },
		[10] = { 36, 10.8, },
		[11] = { 40, 12, },
		[12] = { 44, 13.2, },
		[13] = { 48, 14.4, },
		[14] = { 52, 15.6, },
		[15] = { 55, 16.8, },
		[16] = { 58, 18, },
		[17] = { 61, 19.2, },
		[18] = { 64, 20.4, },
		[19] = { 67, 21.6, },
		[20] = { 70, 22.8, },
		[21] = { 72, 24, },
		[22] = { 74, 25.2, },
		[23] = { 76, 26.4, },
		[24] = { 78, 27.6, },
		[25] = { 80, 28.8, },
		[26] = { 82, 30, },
		[27] = { 84, 31.2, },
		[28] = { 86, 32.4, },
		[29] = { 88, 33.6, },
		[30] = { 90, 34.8, },
	},
}
skills["ColdResistAura"] = {
	name = "Purity of Ice",
	gemTags = {
		aura = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		cold = true,
	},
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
		skill("cooldown", 1.2), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("ColdResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_cold_damage_resistance_%"
		[3] = mod("ColdResistMax", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_cold_damage_resistance_%"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 24, 22, 0, 0, },
		[2] = { 27, 23, 0, 3, },
		[3] = { 30, 24, 0, 6, },
		[4] = { 33, 25, 0, 9, },
		[5] = { 36, 26, 1, 12, },
		[6] = { 39, 27, 1, 15, },
		[7] = { 42, 28, 1, 18, },
		[8] = { 45, 29, 1, 21, },
		[9] = { 48, 30, 1, 23, },
		[10] = { 50, 31, 1, 25, },
		[11] = { 52, 32, 2, 27, },
		[12] = { 54, 33, 2, 29, },
		[13] = { 56, 34, 2, 31, },
		[14] = { 58, 35, 2, 33, },
		[15] = { 60, 36, 2, 35, },
		[16] = { 62, 37, 2, 36, },
		[17] = { 64, 38, 3, 37, },
		[18] = { 66, 39, 3, 38, },
		[19] = { 68, 40, 3, 39, },
		[20] = { 70, 41, 4, 40, },
		[21] = { 72, 42, 4, 41, },
		[22] = { 74, 43, 4, 42, },
		[23] = { 76, 44, 5, 43, },
		[24] = { 78, 45, 5, 44, },
		[25] = { 80, 46, 5, 45, },
		[26] = { 82, 47, 5, 46, },
		[27] = { 84, 48, 5, 47, },
		[28] = { 86, 49, 5, 48, },
		[29] = { 88, 50, 5, 49, },
		[30] = { 90, 51, 5, 50, },
	},
}
skills["RainOfArrows"] = {
	name = "Rain of Arrows",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
	},
	skillTypes = { [1] = true, [48] = true, [11] = true, [14] = true, [22] = true, [17] = true, [19] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		--[4] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 12, 7, 10, 0, },
		[2] = { 15, 7, 11, 0, },
		[3] = { 19, 7, 12, 0, },
		[4] = { 23, 8, 13, 0, },
		[5] = { 27, 8, 14, 1, },
		[6] = { 31, 8, 15, 1, },
		[7] = { 35, 8, 16, 1, },
		[8] = { 38, 8, 17, 1, },
		[9] = { 41, 9, 18, 1, },
		[10] = { 44, 9, 19, 2, },
		[11] = { 47, 9, 20, 2, },
		[12] = { 50, 9, 21, 2, },
		[13] = { 53, 9, 22, 2, },
		[14] = { 56, 10, 23, 2, },
		[15] = { 59, 10, 24, 3, },
		[16] = { 62, 10, 25, 3, },
		[17] = { 64, 10, 26, 3, },
		[18] = { 66, 10, 27, 3, },
		[19] = { 68, 11, 28, 3, },
		[20] = { 70, 11, 29, 4, },
		[21] = { 72, 11, 30, 4, },
		[22] = { 74, 11, 31, 4, },
		[23] = { 76, 11, 32, 4, },
		[24] = { 78, 11, 33, 4, },
		[25] = { 80, 11, 34, 5, },
		[26] = { 82, 12, 35, 5, },
		[27] = { 84, 12, 36, 5, },
		[28] = { 86, 12, 37, 5, },
		[29] = { 88, 12, 38, 5, },
		[30] = { 90, 12, 39, 6, },
	},
}
skills["VaalRainOfArrows"] = {
	name = "Vaal Rain of Arrows",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
		area = true,
		duration = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
		duration = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [11] = true, [14] = true, [22] = true, [17] = true, [19] = true, [12] = true, [43] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"base_is_projectile" = ?
		--"is_area_damage" = ?
		--"rain_of_arrows_pin" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 12, 40, 3.4, 0, },
		[2] = { 15, 41.5, 3.45, 1, },
		[3] = { 19, 43, 3.5, 2, },
		[4] = { 23, 44.5, 3.55, 3, },
		[5] = { 27, 46, 3.6, 4, },
		[6] = { 31, 47.5, 3.65, 5, },
		[7] = { 35, 49, 3.7, 6, },
		[8] = { 38, 50.5, 3.75, 7, },
		[9] = { 41, 52, 3.8, 8, },
		[10] = { 44, 53.5, 3.85, 9, },
		[11] = { 47, 55, 3.9, 10, },
		[12] = { 50, 56.5, 3.95, 11, },
		[13] = { 53, 58, 4, 12, },
		[14] = { 56, 59.5, 4.05, 13, },
		[15] = { 59, 61, 4.1, 14, },
		[16] = { 62, 62.5, 4.15, 15, },
		[17] = { 64, 64, 4.2, 16, },
		[18] = { 66, 65.5, 4.25, 17, },
		[19] = { 68, 67, 4.3, 18, },
		[20] = { 70, 68.5, 4.35, 19, },
		[21] = { 72, 70, 4.4, 20, },
		[22] = { 74, 71.5, 4.45, 21, },
		[23] = { 76, 73, 4.5, 22, },
		[24] = { 78, 74.5, 4.55, 23, },
		[25] = { 80, 76, 4.6, 24, },
		[26] = { 82, 77.5, 4.65, 25, },
		[27] = { 84, 79, 4.7, 26, },
		[28] = { 86, 80.5, 4.75, 27, },
		[29] = { 88, 82, 4.8, 28, },
		[30] = { 90, 83.5, 4.85, 29, },
	},
}
skills["Reave"] = {
	name = "Reave",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [28] = true, [24] = true, },
	weaponTypes = {
		["One Handed Sword"] = true,
		["Dagger"] = true,
		["Claw"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		--"reave_area_of_effect_+%_final_per_stage" = 50
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		--[2] = "active_skill_base_radius_+"
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 12, 0, nil, },
		[2] = { 15, 0, 2, },
		[3] = { 19, 0, 4, },
		[4] = { 23, 0, 6, },
		[5] = { 27, 1, 8, },
		[6] = { 31, 1, 10, },
		[7] = { 35, 1, 12, },
		[8] = { 38, 1, 14, },
		[9] = { 41, 1, 16, },
		[10] = { 44, 2, 18, },
		[11] = { 47, 2, 20, },
		[12] = { 50, 2, 22, },
		[13] = { 53, 2, 24, },
		[14] = { 56, 2, 26, },
		[15] = { 59, 3, 28, },
		[16] = { 62, 3, 30, },
		[17] = { 64, 3, 32, },
		[18] = { 66, 3, 34, },
		[19] = { 68, 3, 36, },
		[20] = { 70, 4, 38, },
		[21] = { 72, 4, 40, },
		[22] = { 74, 4, 42, },
		[23] = { 76, 4, 44, },
		[24] = { 78, 4, 46, },
		[25] = { 80, 5, 48, },
		[26] = { 82, 5, 50, },
		[27] = { 84, 5, 52, },
		[28] = { 86, 5, 54, },
		[29] = { 88, 5, 56, },
		[30] = { 90, 6, 58, },
	},
}
skills["VaalReave"] = {
	name = "Vaal Reave",
	gemTags = {
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
		area = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		area = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [6] = true, [11] = true, [28] = true, [24] = true, [43] = true, },
	weaponTypes = {
		["One Handed Sword"] = true,
		["Dagger"] = true,
		["Claw"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"reave_area_of_effect_+%_final_per_stage" = 50
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
		[1] = skill("levelRequirement", nil), 
		--[2] = "active_skill_base_radius_+"
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 12, 0, nil, },
		[2] = { 15, 0, 1.2, },
		[3] = { 19, 0, 2.4, },
		[4] = { 23, 0, 3.6, },
		[5] = { 27, 1, 4.8, },
		[6] = { 31, 1, 6, },
		[7] = { 35, 1, 7.2, },
		[8] = { 38, 1, 8.4, },
		[9] = { 41, 1, 9.6, },
		[10] = { 44, 2, 10.8, },
		[11] = { 47, 2, 12, },
		[12] = { 50, 2, 13.2, },
		[13] = { 53, 2, 14.4, },
		[14] = { 56, 2, 15.6, },
		[15] = { 59, 3, 16.8, },
		[16] = { 62, 3, 18, },
		[17] = { 64, 3, 19.2, },
		[18] = { 66, 3, 20.4, },
		[19] = { 68, 3, 21.6, },
		[20] = { 70, 4, 22.8, },
		[21] = { 72, 4, 24, },
		[22] = { 74, 4, 25.2, },
		[23] = { 76, 4, 26.4, },
		[24] = { 78, 4, 27.6, },
		[25] = { 80, 5, 28.8, },
		[26] = { 82, 5, 30, },
		[27] = { 84, 5, 31.2, },
		[28] = { 86, 5, 32.4, },
		[29] = { 88, 5, 33.6, },
		[30] = { 90, 6, 34.8, },
	},
}
skills["Riposte"] = {
	name = "Riposte",
	gemTags = {
		trigger = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
	},
	skillTypes = { [1] = true, [24] = true, [25] = true, [6] = true, [47] = true, [57] = true, },
	weaponTypes = {
		["None"] = true,
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("cooldown", 0.8), 
		--"melee_counterattack_trigger_on_block_%" = 100
		--"attack_unusable_if_triggerable" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		skill("doubleHitsWhenDualWielding", true), --"skill_double_hits_when_dual_wielding" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 4, nil, },
		[2] = { 6, 2, },
		[3] = { 9, 4, },
		[4] = { 12, 6, },
		[5] = { 16, 8, },
		[6] = { 20, 10, },
		[7] = { 24, 12, },
		[8] = { 28, 14, },
		[9] = { 32, 16, },
		[10] = { 36, 18, },
		[11] = { 40, 20, },
		[12] = { 44, 22, },
		[13] = { 48, 24, },
		[14] = { 52, 26, },
		[15] = { 55, 28, },
		[16] = { 58, 30, },
		[17] = { 61, 32, },
		[18] = { 64, 34, },
		[19] = { 67, 36, },
		[20] = { 70, 38, },
		[21] = { 72, 40, },
		[22] = { 74, 42, },
		[23] = { 76, 44, },
		[24] = { 78, 46, },
		[25] = { 80, 48, },
		[26] = { 82, 50, },
		[27] = { 84, 52, },
		[28] = { 86, 54, },
		[29] = { 88, 56, },
		[30] = { 90, 58, },
	},
}
skills["ShrapnelShot"] = {
	name = "Shrapnel Shot",
	gemTags = {
		lightning = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		area = true,
		bow = true,
	},
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
	weaponTypes = {
		["Bow"] = true,
	},
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
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		--[4] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 1, 6, -20, 0, },
		[2] = { 2, 6, -19, 0, },
		[3] = { 4, 6, -18, 0, },
		[4] = { 7, 7, -17, 1, },
		[5] = { 11, 7, -16, 1, },
		[6] = { 16, 7, -15, 1, },
		[7] = { 20, 7, -14, 1, },
		[8] = { 24, 8, -13, 2, },
		[9] = { 28, 8, -12, 2, },
		[10] = { 32, 8, -11, 2, },
		[11] = { 36, 8, -10, 2, },
		[12] = { 40, 8, -9, 3, },
		[13] = { 44, 9, -8, 3, },
		[14] = { 48, 9, -7, 3, },
		[15] = { 52, 9, -6, 3, },
		[16] = { 56, 9, -5, 4, },
		[17] = { 60, 9, -4, 4, },
		[18] = { 64, 10, -3, 4, },
		[19] = { 67, 10, -2, 4, },
		[20] = { 70, 10, -1, 5, },
		[21] = { 72, 10, nil, 5, },
		[22] = { 74, 10, 1, 5, },
		[23] = { 76, 11, 2, 5, },
		[24] = { 78, 11, 3, 6, },
		[25] = { 80, 11, 4, 6, },
		[26] = { 82, 11, 5, 6, },
		[27] = { 84, 11, 6, 6, },
		[28] = { 86, 12, 7, 7, },
		[29] = { 88, 12, 8, 7, },
		[30] = { 90, 12, 9, 7, },
	},
}
skills["SiegeBallista"] = {
	name = "Siege Ballista",
	gemTags = {
		totem = true,
		dexterity = true,
		active_skill = true,
		attack = true,
		duration = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		totem = true,
		duration = true,
	},
	skillTypes = { [1] = true, [3] = true, [48] = true, [17] = true, [19] = true, [30] = true, [12] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[4] = skill("totemLevel", nil), --"base_active_skill_totem_level"
	},
	levels = {
		[1] = { 4, 8, 40, 4, },
		[2] = { 6, 8, 41.6, 6, },
		[3] = { 9, 8, 43.2, 9, },
		[4] = { 12, 9, 44.8, 12, },
		[5] = { 16, 9, 46.4, 16, },
		[6] = { 20, 9, 48, 20, },
		[7] = { 24, 9, 49.6, 24, },
		[8] = { 28, 9, 51.2, 28, },
		[9] = { 32, 9, 52.8, 32, },
		[10] = { 36, 10, 54.4, 36, },
		[11] = { 40, 10, 56, 40, },
		[12] = { 44, 10, 57.6, 44, },
		[13] = { 48, 10, 59.2, 48, },
		[14] = { 52, 10, 60.8, 52, },
		[15] = { 55, 11, 62.4, 55, },
		[16] = { 58, 11, 64, 58, },
		[17] = { 61, 12, 65.6, 61, },
		[18] = { 64, 12, 67.2, 64, },
		[19] = { 67, 12, 68.8, 67, },
		[20] = { 70, 13, 70.4, 70, },
		[21] = { 72, 13, 72, 72, },
		[22] = { 74, 13, 73.6, 74, },
		[23] = { 76, 14, 75.2, 76, },
		[24] = { 78, 14, 76.8, 78, },
		[25] = { 80, 14, 78.4, 80, },
		[26] = { 82, 14, 80, 82, },
		[27] = { 84, 14, 81.6, 84, },
		[28] = { 86, 14, 83.2, 86, },
		[29] = { 88, 15, 84.8, 88, },
		[30] = { 90, 15, 86.4, 90, },
	},
}
skills["SmokeMine"] = {
	name = "Smoke Mine",
	gemTags = {
		mine = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
		movement = true,
	},
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
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 10, 6, 4, },
		[2] = { 13, 6, 4.1, },
		[3] = { 17, 7, 4.2, },
		[4] = { 21, 7, 4.3, },
		[5] = { 25, 8, 4.4, },
		[6] = { 29, 8, 4.5, },
		[7] = { 33, 9, 4.6, },
		[8] = { 36, 9, 4.7, },
		[9] = { 39, 9, 4.8, },
		[10] = { 42, 10, 4.9, },
		[11] = { 45, 10, 5, },
		[12] = { 48, 10, 5.1, },
		[13] = { 51, 10, 5.2, },
		[14] = { 54, 11, 5.3, },
		[15] = { 57, 11, 5.4, },
		[16] = { 60, 11, 5.5, },
		[17] = { 63, 12, 5.6, },
		[18] = { 66, 12, 5.7, },
		[19] = { 68, 12, 5.8, },
		[20] = { 70, 13, 5.9, },
		[21] = { 72, 13, 6, },
		[22] = { 74, 13, 6.1, },
		[23] = { 76, 14, 6.2, },
		[24] = { 78, 14, 6.3, },
		[25] = { 80, 14, 6.4, },
		[26] = { 82, 14, 6.5, },
		[27] = { 84, 14, 6.6, },
		[28] = { 86, 14, 6.7, },
		[29] = { 88, 15, 6.8, },
		[30] = { 90, 15, 6.9, },
	},
}
skills["ThrownWeapon"] = {
	name = "Spectral Throw",
	gemTags = {
		projectile = true,
		dexterity = true,
		active_skill = true,
		attack = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, },
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"base_is_projectile" = ?
		mod("PierceChance", "BASE", 100), 
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, 7, -46, },
		[2] = { 2, 7, -44, },
		[3] = { 4, 7, -42.1, },
		[4] = { 7, 7, -40.2, },
		[5] = { 11, 7, -38.3, },
		[6] = { 16, 7, -36.4, },
		[7] = { 20, 7, -34.4, },
		[8] = { 24, 7, -32.5, },
		[9] = { 28, 7, -30.6, },
		[10] = { 32, 7, -28.7, },
		[11] = { 36, 8, -26.8, },
		[12] = { 40, 8, -24.8, },
		[13] = { 44, 8, -22.9, },
		[14] = { 48, 8, -21, },
		[15] = { 52, 8, -19.1, },
		[16] = { 56, 9, -17.2, },
		[17] = { 60, 9, -15.2, },
		[18] = { 64, 9, -13.3, },
		[19] = { 67, 9, -11.4, },
		[20] = { 70, 9, -9.5, },
		[21] = { 72, 10, -7.6, },
		[22] = { 74, 10, -5.6, },
		[23] = { 76, 10, -3.7, },
		[24] = { 78, 10, -1.8, },
		[25] = { 80, 10, nil, },
		[26] = { 82, 10, 2, },
		[27] = { 84, 10, 3.9, },
		[28] = { 86, 10, 5.8, },
		[29] = { 88, 10, 7.7, },
		[30] = { 90, 10, 9.6, },
	},
}
skills["VaalThrownWeapon"] = {
	name = "Vaal Spectral Throw",
	gemTags = {
		projectile = true,
		dexterity = true,
		active_skill = true,
		vaal = true,
		attack = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [43] = true, },
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, -30, },
		[2] = { 2, -28.2, },
		[3] = { 4, -26.4, },
		[4] = { 7, -24.6, },
		[5] = { 11, -22.8, },
		[6] = { 16, -21, },
		[7] = { 20, -19.2, },
		[8] = { 24, -17.4, },
		[9] = { 28, -15.6, },
		[10] = { 32, -13.8, },
		[11] = { 36, -12, },
		[12] = { 40, -10.2, },
		[13] = { 44, -8.4, },
		[14] = { 48, -6.6, },
		[15] = { 52, -4.8, },
		[16] = { 56, -3, },
		[17] = { 60, -1.2, },
		[18] = { 64, 0.6, },
		[19] = { 67, 2.4, },
		[20] = { 70, 4.2, },
		[21] = { 72, 6, },
		[22] = { 74, 7.8, },
		[23] = { 76, 9.6, },
		[24] = { 78, 11.4, },
		[25] = { 80, 13.2, },
		[26] = { 82, 15, },
		[27] = { 84, 16.8, },
		[28] = { 86, 18.6, },
		[29] = { 88, 20.4, },
		[30] = { 90, 22.2, },
	},
}
skills["SplitArrow"] = {
	name = "Split Arrow",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [22] = true, [17] = true, [19] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"skill_can_fire_arrows" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Attack, 0, nil), --"attack_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[4] = mod("ProjectileCount", "BASE", nil), --"base_number_of_additional_arrows"
	},
	levels = {
		[1] = { 1, 6, -10, 4, },
		[2] = { 2, 6, -9, 4, },
		[3] = { 4, 6, -8, 4, },
		[4] = { 7, 7, -7, 4, },
		[5] = { 11, 7, -6, 4, },
		[6] = { 16, 7, -5, 4, },
		[7] = { 20, 7, -4, 4, },
		[8] = { 24, 8, -3, 5, },
		[9] = { 28, 8, -2, 5, },
		[10] = { 32, 8, -1, 5, },
		[11] = { 36, 8, nil, 5, },
		[12] = { 40, 8, 1, 5, },
		[13] = { 44, 9, 2, 5, },
		[14] = { 48, 9, 3, 5, },
		[15] = { 52, 9, 4, 6, },
		[16] = { 56, 9, 5, 6, },
		[17] = { 60, 9, 6, 6, },
		[18] = { 64, 10, 7, 6, },
		[19] = { 67, 10, 8, 6, },
		[20] = { 70, 10, 9, 6, },
		[21] = { 72, 10, 10, 6, },
		[22] = { 74, 10, 11, 7, },
		[23] = { 76, 11, 12, 7, },
		[24] = { 78, 11, 13, 7, },
		[25] = { 80, 11, 14, 7, },
		[26] = { 82, 11, 15, 7, },
		[27] = { 84, 11, 16, 7, },
		[28] = { 86, 12, 17, 7, },
		[29] = { 88, 12, 18, 8, },
		[30] = { 90, 12, 19, 8, },
	},
}
skills["SummonIceGolem"] = {
	name = "Summon Ice Golem",
	gemTags = {
		dexterity = true,
		active_skill = true,
		cold = true,
		minion = true,
		spell = true,
		golem = true,
	},
	minionList = {
		"SummonedIceGolem",
	},
	color = 2,
	baseFlags = {
		spell = true,
		minion = true,
		golem = true,
		cold = true,
	},
	skillTypes = { [36] = true, [34] = true, [19] = true, [9] = true, [21] = true, [26] = true, [2] = true, [18] = true, [17] = true, [49] = true, [60] = true, [62] = true, },
	minionSkillTypes = { [1] = true, [24] = true, [25] = true, [3] = true, [2] = true, [10] = true, [38] = true, [28] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("cooldown", 6), 
		mod("ActiveGolemLimit", "BASE", 1), --"base_number_of_golems_allowed" = 1
		--"display_minion_monster_type" = 6
		mod("Misc", "LIST", { type = "Condition", var = "HaveColdGolem" }, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), 
	},
	qualityMods = {
		mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Life", "INC", 1) }), --"minion_maximum_life_+%" = 1
		mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Damage", "INC", 1) }), --"minion_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		--[3] = "base_actor_scale_+%"
		[4] = mod("CritChance", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"ice_golem_grants_critical_strike_chance_+%"
		[5] = mod("Accuracy", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"ice_golem_grants_accuracy_+%"
		[6] = mod("Misc", "LIST", { type = "MinionModifier", mod = mod("Life", "INC", nil) }), --"minion_maximum_life_+%"
		[7] = skill("minionLevel", nil), --"display_minion_monster_level"
	},
	levels = {
		[1] = { 34, 30, 0, 20, 20, 30, 34, },
		[2] = { 36, 32, 1, 21, 21, 32, 36, },
		[3] = { 38, 34, 1, 21, 21, 34, 38, },
		[4] = { 40, 36, 2, 22, 22, 36, 40, },
		[5] = { 42, 38, 2, 22, 22, 38, 42, },
		[6] = { 44, 40, 3, 23, 23, 40, 44, },
		[7] = { 46, 42, 3, 23, 23, 42, 46, },
		[8] = { 48, 44, 4, 24, 24, 44, 48, },
		[9] = { 50, 44, 4, 24, 24, 46, 50, },
		[10] = { 52, 46, 5, 25, 25, 48, 52, },
		[11] = { 54, 48, 5, 25, 25, 50, 54, },
		[12] = { 56, 48, 6, 26, 26, 52, 56, },
		[13] = { 58, 50, 6, 26, 26, 54, 58, },
		[14] = { 60, 50, 7, 27, 27, 56, 60, },
		[15] = { 62, 52, 7, 27, 27, 58, 62, },
		[16] = { 64, 52, 8, 28, 28, 60, 64, },
		[17] = { 66, 52, 8, 28, 28, 62, 66, },
		[18] = { 68, 52, 9, 29, 29, 64, 68, },
		[19] = { 69, 54, 9, 29, 29, 66, 69, },
		[20] = { 70, 54, 10, 30, 30, 68, 70, },
		[21] = { 72, 56, 10, 30, 30, 70, 72, },
		[22] = { 74, 56, 11, 31, 31, 72, 74, },
		[23] = { 76, 58, 11, 31, 31, 74, 76, },
		[24] = { 78, 58, 12, 32, 32, 76, 78, },
		[25] = { 80, 60, 12, 32, 32, 78, 80, },
		[26] = { 82, 60, 13, 33, 33, 80, 82, },
		[27] = { 84, 60, 13, 33, 33, 82, 84, },
		[28] = { 86, 60, 14, 34, 34, 84, 86, },
		[29] = { 88, 62, 14, 34, 34, 86, 88, },
		[30] = { 90, 62, 15, 35, 35, 88, 90, },
	},
}
skills["TemporalChains"] = {
	name = "Temporal Chains",
	gemTags = {
		curse = true,
		dexterity = true,
		active_skill = true,
		spell = true,
		area = true,
		duration = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = skill("duration", nil), --"base_skill_effect_duration"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		--[5] = "temporal_chains_action_speed_+%_final"
	},
	levels = {
		[1] = { 24, 24, 5, 0, -20, },
		[2] = { 27, 26, 5.05, 4, -20, },
		[3] = { 30, 27, 5.1, 8, -21, },
		[4] = { 33, 29, 5.15, 12, -21, },
		[5] = { 36, 30, 5.2, 16, -22, },
		[6] = { 39, 32, 5.25, 20, -22, },
		[7] = { 42, 34, 5.3, 24, -23, },
		[8] = { 45, 35, 5.35, 28, -23, },
		[9] = { 48, 37, 5.4, 32, -24, },
		[10] = { 50, 38, 5.45, 36, -24, },
		[11] = { 52, 39, 5.5, 40, -25, },
		[12] = { 54, 40, 5.55, 44, -25, },
		[13] = { 56, 42, 5.6, 48, -26, },
		[14] = { 58, 43, 5.65, 52, -26, },
		[15] = { 60, 44, 5.7, 56, -27, },
		[16] = { 62, 45, 5.75, 60, -27, },
		[17] = { 64, 46, 5.8, 64, -28, },
		[18] = { 66, 47, 5.85, 68, -28, },
		[19] = { 68, 48, 5.9, 72, -29, },
		[20] = { 70, 50, 5.95, 76, -29, },
		[21] = { 72, 51, 6, 80, -30, },
		[22] = { 74, 52, 6.05, 84, -30, },
		[23] = { 76, 53, 6.1, 88, -31, },
		[24] = { 78, 54, 6.15, 92, -31, },
		[25] = { 80, 56, 6.2, 96, -32, },
		[26] = { 82, 57, 6.25, 100, -32, },
		[27] = { 84, 58, 6.3, 104, -33, },
		[28] = { 86, 59, 6.35, 108, -33, },
		[29] = { 88, 60, 6.4, 112, -34, },
		[30] = { 90, 61, 6.45, 116, -34, },
	},
}
skills["TornadoShot"] = {
	name = "Tornado Shot",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		bow = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [3] = true, [17] = true, [19] = true, [22] = true, [48] = true, },
	weaponTypes = {
		["Bow"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = skill("manaCost", nil), 
		[3] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 28, 8, -10, },
		[2] = { 31, 8, -9, },
		[3] = { 34, 8, -8, },
		[4] = { 37, 8, -7, },
		[5] = { 40, 9, -6, },
		[6] = { 42, 9, -5, },
		[7] = { 44, 9, -4, },
		[8] = { 46, 9, -3, },
		[9] = { 48, 9, -2, },
		[10] = { 50, 9, -1, },
		[11] = { 52, 9, nil, },
		[12] = { 54, 10, 1, },
		[13] = { 56, 10, 2, },
		[14] = { 58, 10, 3, },
		[15] = { 60, 10, 4, },
		[16] = { 62, 10, 5, },
		[17] = { 64, 10, 6, },
		[18] = { 66, 10, 7, },
		[19] = { 68, 10, 8, },
		[20] = { 70, 10, 9, },
		[21] = { 72, 10, 10, },
		[22] = { 74, 10, 11, },
		[23] = { 76, 11, 12, },
		[24] = { 78, 11, 13, },
		[25] = { 80, 11, 14, },
		[26] = { 82, 11, 15, },
		[27] = { 84, 11, 16, },
		[28] = { 86, 12, 17, },
		[29] = { 88, 12, 18, },
		[30] = { 90, 12, 19, },
	},
}
skills["ViperStrike"] = {
	name = "Viper Strike",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		duration = true,
		melee = true,
		chaos = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [1] = true, [6] = true, [12] = true, [28] = true, [24] = true, [25] = true, [40] = true, [50] = true, },
	weaponTypes = {
		["One Handed Sword"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Claw"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 1, 30, },
		[2] = { 2, 32.6, },
		[3] = { 4, 35.2, },
		[4] = { 7, 37.8, },
		[5] = { 11, 40.4, },
		[6] = { 16, 43, },
		[7] = { 20, 45.6, },
		[8] = { 24, 48.2, },
		[9] = { 28, 50.8, },
		[10] = { 32, 53.4, },
		[11] = { 36, 56, },
		[12] = { 40, 58.6, },
		[13] = { 44, 61.2, },
		[14] = { 48, 63.8, },
		[15] = { 52, 66.4, },
		[16] = { 56, 69, },
		[17] = { 60, 71.6, },
		[18] = { 64, 74.2, },
		[19] = { 67, 76.8, },
		[20] = { 70, 79.4, },
		[21] = { 72, 82, },
		[22] = { 74, 84.6, },
		[23] = { 76, 87.2, },
		[24] = { 78, 89.8, },
		[25] = { 80, 92.4, },
		[26] = { 82, 95, },
		[27] = { 84, 97.6, },
		[28] = { 86, 100.2, },
		[29] = { 88, 102.8, },
		[30] = { 90, 105.4, },
	},
}
skills["WhirlingBlades"] = {
	name = "Whirling Blades",
	gemTags = {
		dexterity = true,
		active_skill = true,
		attack = true,
		movement = true,
		melee = true,
	},
	color = 2,
	baseFlags = {
		attack = true,
		melee = true,
		movement = true,
	},
	skillTypes = { [1] = true, [6] = true, [24] = true, [38] = true, },
	weaponTypes = {
		["Claw"] = true,
		["Dagger"] = true,
		["One Handed Sword"] = true,
	},
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
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 10, -20, },
		[2] = { 13, -19, },
		[3] = { 17, -18, },
		[4] = { 21, -17, },
		[5] = { 25, -16, },
		[6] = { 29, -15, },
		[7] = { 33, -14, },
		[8] = { 36, -13, },
		[9] = { 39, -12, },
		[10] = { 42, -11, },
		[11] = { 45, -10, },
		[12] = { 48, -9, },
		[13] = { 51, -8, },
		[14] = { 54, -7, },
		[15] = { 57, -6, },
		[16] = { 60, -5, },
		[17] = { 63, -4, },
		[18] = { 66, -3, },
		[19] = { 68, -2, },
		[20] = { 70, -1, },
		[21] = { 72, nil, },
		[22] = { 74, 1, },
		[23] = { 76, 2, },
		[24] = { 78, 3, },
		[25] = { 80, 4, },
		[26] = { 82, 5, },
		[27] = { 84, 6, },
		[28] = { 86, 7, },
		[29] = { 88, 8, },
		[30] = { 90, 9, },
	},
}
skills["WildStrike"] = {
	name = "Wild Strike",
	gemTags = {
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
	},
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
	weaponTypes = {
		["One Handed Mace"] = true,
		["Two Handed Sword"] = true,
		["Dagger"] = true,
		["Staff"] = true,
		["Two Handed Axe"] = true,
		["Two Handed Mace"] = true,
		["One Handed Axe"] = true,
		["Claw"] = true,
		["One Handed Sword"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 6), 
		--"elemental_strike_physical_damage_%_to_convert" = 100
		--"fixed_projectile_spread" = 70
		mod("ProjectileCount", "BASE", 2), --"number_of_additional_projectiles" = 2
		--"show_number_of_projectiles" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
		mod("PhysicalDamageConvertToFire", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 1 }), 
		mod("PhysicalDamageConvertToFire", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 2 }), 
		mod("PhysicalDamageConvertToLightning", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 3 }), 
		mod("PhysicalDamageConvertToLightning", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 4 }), 
		mod("PhysicalDamageConvertToCold", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 5 }), 
		mod("PhysicalDamageConvertToCold", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 6 }), 
	},
	qualityMods = {
		mod("ElementalDamage", "INC", 1), --"elemental_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("ChainCount", "BASE", nil), --"number_of_additional_projectiles_in_chain"
		[4] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 28, 30, 4, 0, },
		[2] = { 31, 32.4, 4, 1, },
		[3] = { 34, 34.8, 4, 2, },
		[4] = { 37, 37.2, 4, 3, },
		[5] = { 40, 39.6, 4, 4, },
		[6] = { 42, 42, 4, 5, },
		[7] = { 44, 44.4, 5, 6, },
		[8] = { 46, 46.8, 5, 7, },
		[9] = { 48, 49.2, 5, 8, },
		[10] = { 50, 51.6, 5, 9, },
		[11] = { 52, 54, 5, 10, },
		[12] = { 54, 56.4, 5, 11, },
		[13] = { 56, 58.8, 6, 12, },
		[14] = { 58, 61.2, 6, 13, },
		[15] = { 60, 63.6, 6, 14, },
		[16] = { 62, 66, 6, 15, },
		[17] = { 64, 68.4, 6, 16, },
		[18] = { 66, 70.8, 6, 17, },
		[19] = { 68, 73.2, 7, 18, },
		[20] = { 70, 75.6, 7, 19, },
		[21] = { 72, 78, 7, 20, },
		[22] = { 74, 80.4, 7, 21, },
		[23] = { 76, 82.8, 7, 22, },
		[24] = { 78, 85.2, 7, 23, },
		[25] = { 80, 87.6, 8, 24, },
		[26] = { 82, 90, 8, 25, },
		[27] = { 84, 92.4, 8, 26, },
		[28] = { 86, 94.8, 8, 27, },
		[29] = { 88, 97.2, 8, 28, },
		[30] = { 90, 99.6, 8, 29, },
	},
}