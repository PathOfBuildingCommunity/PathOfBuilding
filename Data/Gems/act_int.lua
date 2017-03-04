-- Path of Building
--
-- Active Intelligence gems
-- Skill gem data (c) Grinding Gear Games
--
local gems, mod, flag, skill = ...

gems["Arc"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	chaining = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		chaining = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [17] = true, [18] = true, [19] = true, [23] = true, [26] = true, [36] = true, [45] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.7), 
		skill("critChance", 5), 
		mod("EnemyShockChance", "BASE", 10), --"base_chance_to_shock_%" = 10
	},
	qualityMods = {
		mod("EnemyShockChance", "BASE", 0.5), --"base_chance_to_shock_%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		[4] = mod("ChainCount", "BASE", nil), --"number_of_additional_projectiles_in_chain"
	},
	levels = {
		[1] = { 9, 2, 35, 2, },
		[2] = { 10, 2, 44, 2, },
		[3] = { 11, 3, 58, 2, },
		[4] = { 12, 4, 76, 3, },
		[5] = { 13, 5, 97, 3, },
		[6] = { 14, 6, 123, 3, },
		[7] = { 16, 8, 154, 3, },
		[8] = { 16, 10, 182, 4, },
		[9] = { 17, 11, 214, 4, },
		[10] = { 18, 13, 250, 4, },
		[11] = { 19, 15, 292, 4, },
		[12] = { 20, 18, 340, 5, },
		[13] = { 21, 21, 395, 5, },
		[14] = { 22, 24, 458, 5, },
		[15] = { 23, 28, 529, 5, },
		[16] = { 24, 32, 610, 6, },
		[17] = { 24, 35, 671, 6, },
		[18] = { 25, 39, 736, 6, },
		[19] = { 25, 43, 808, 6, },
		[20] = { 26, 47, 886, 7, },
		[21] = { 26, 51, 971, 7, },
		[22] = { 26, 56, 1064, 7, },
		[23] = { 27, 61, 1164, 7, },
		[24] = { 28, 67, 1274, 8, },
		[25] = { 29, 73, 1393, 8, },
		[26] = { 30, 80, 1523, 8, },
		[27] = { 30, 88, 1663, 8, },
		[28] = { 30, 96, 1816, 9, },
		[29] = { 31, 104, 1983, 9, },
		[30] = { 32, 114, 2163, 9, },
	},
}
gems["Vaal Arc"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	chaining = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		lightning = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [17] = true, [18] = true, [19] = true, [23] = true, [26] = true, [43] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.8), 
		skill("critChance", 5), 
		mod("EnemyShockChance", "BASE", 100), --"base_chance_to_shock_%" = 100
		mod("ChainCount", "BASE", 40), --"number_of_additional_projectiles_in_chain" = 40
	},
	qualityMods = {
		mod("EnemyShockDuration", "INC", 1.5), --"shock_duration_+%" = 1.5
	},
	levelMods = {
		[1] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[2] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 2, 35, },
		[2] = { 2, 44, },
		[3] = { 3, 59, },
		[4] = { 4, 77, },
		[5] = { 5, 99, },
		[6] = { 7, 125, },
		[7] = { 8, 158, },
		[8] = { 10, 187, },
		[9] = { 12, 220, },
		[10] = { 14, 259, },
		[11] = { 16, 303, },
		[12] = { 19, 353, },
		[13] = { 22, 411, },
		[14] = { 25, 478, },
		[15] = { 29, 554, },
		[16] = { 34, 641, },
		[17] = { 37, 706, },
		[18] = { 41, 777, },
		[19] = { 45, 854, },
		[20] = { 49, 938, },
		[21] = { 54, 1030, },
		[22] = { 60, 1131, },
		[23] = { 65, 1240, },
		[24] = { 72, 1359, },
		[25] = { 78, 1489, },
		[26] = { 86, 1631, },
		[27] = { 94, 1785, },
		[28] = { 103, 1953, },
		[29] = { 112, 2136, },
		[30] = { 123, 2335, },
	},
}
gems["Arctic Breath"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	area = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		projectile = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [17] = true, [18] = true, [19] = true, [12] = true, [11] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("critChance", 5), 
		--"base_is_projectile" = 1
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		[4] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 11, 52, 78, 0.88, },
		[2] = { 11, 64, 96, 0.94, },
		[3] = { 12, 77, 116, 0.99, },
		[4] = { 13, 93, 140, 1.05, },
		[5] = { 14, 112, 168, 1.1, },
		[6] = { 14, 126, 190, 1.16, },
		[7] = { 15, 143, 214, 1.21, },
		[8] = { 15, 160, 240, 1.27, },
		[9] = { 16, 180, 270, 1.32, },
		[10] = { 16, 202, 303, 1.35, },
		[11] = { 16, 227, 340, 1.38, },
		[12] = { 17, 254, 381, 1.4, },
		[13] = { 17, 284, 426, 1.43, },
		[14] = { 18, 317, 476, 1.46, },
		[15] = { 18, 354, 532, 1.49, },
		[16] = { 19, 395, 593, 1.51, },
		[17] = { 19, 441, 661, 1.54, },
		[18] = { 20, 491, 737, 1.57, },
		[19] = { 20, 547, 820, 1.6, },
		[20] = { 21, 608, 913, 1.65, },
		[21] = { 21, 677, 1015, 1.71, },
		[22] = { 22, 752, 1128, 1.76, },
		[23] = { 22, 835, 1252, 1.82, },
		[24] = { 23, 927, 1390, 1.87, },
		[25] = { 23, 1028, 1542, 1.93, },
		[26] = { 24, 1140, 1710, 1.98, },
		[27] = { 24, 1264, 1896, 2.04, },
		[28] = { 25, 1400, 2100, 2.09, },
		[29] = { 25, 1550, 2326, 2.15, },
		[30] = { 26, 1716, 2574, 2.2, },
	},
}
gems["Assassin's Mark"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		mod("SelfCritMultiplier", "INC", 20, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_self_critical_strike_multiplier_-%" = -20
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		--"chance_to_grant_power_charge_on_death_%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("SelfExtraCritChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"additional_chance_to_take_critical_strike_%"
		[5] = mod("LifeOnKill", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"life_granted_when_killed"
		[6] = mod("ManaOnKill", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"mana_granted_when_killed"
		--[7] = "chance_to_grant_power_charge_on_death_%"
	},
	levels = {
		[1] = { 24, 6, 0, 5, 16, 16, 21, },
		[2] = { 26, 6.2, 4, 5, 16, 16, 21, },
		[3] = { 27, 6.4, 8, 5, 17, 17, 22, },
		[4] = { 29, 6.6, 12, 6, 17, 17, 22, },
		[5] = { 30, 6.8, 16, 6, 18, 18, 23, },
		[6] = { 32, 7, 20, 6, 18, 18, 23, },
		[7] = { 34, 7.2, 24, 7, 19, 19, 24, },
		[8] = { 35, 7.4, 28, 7, 19, 19, 24, },
		[9] = { 37, 7.6, 32, 7, 20, 20, 25, },
		[10] = { 38, 7.8, 36, 8, 20, 20, 25, },
		[11] = { 39, 8, 40, 8, 21, 21, 26, },
		[12] = { 40, 8.2, 44, 8, 21, 21, 26, },
		[13] = { 42, 8.4, 48, 8, 22, 22, 27, },
		[14] = { 43, 8.6, 52, 8, 22, 22, 27, },
		[15] = { 44, 8.8, 56, 9, 23, 23, 28, },
		[16] = { 45, 9, 60, 9, 23, 23, 28, },
		[17] = { 46, 9.2, 64, 9, 24, 24, 29, },
		[18] = { 47, 9.4, 68, 9, 24, 24, 29, },
		[19] = { 48, 9.6, 72, 9, 25, 25, 30, },
		[20] = { 50, 9.8, 76, 9, 25, 25, 30, },
		[21] = { 51, 10, 80, 10, 26, 26, 31, },
		[22] = { 52, 10.2, 84, 10, 26, 26, 31, },
		[23] = { 53, 10.4, 88, 10, 27, 27, 32, },
		[24] = { 54, 10.6, 92, 10, 27, 27, 32, },
		[25] = { 56, 10.8, 96, 10, 28, 28, 33, },
		[26] = { 57, 11, 100, 11, 28, 28, 33, },
		[27] = { 58, 11.2, 104, 11, 29, 29, 34, },
		[28] = { 59, 11.4, 108, 11, 29, 29, 34, },
		[29] = { 60, 11.6, 112, 11, 30, 30, 35, },
		[30] = { 61, 11.8, 116, 11, 30, 30, 35, },
	},
}
gems["Ball Lightning"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [3] = true, [11] = true, [18] = true, [17] = true, [19] = true, [26] = true, [36] = true, [45] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.2), 
		skill("critChance", 5), 
		--"active_skill_index" = 0
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("LightningDamage", "INC", 1), --"lightning_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 14, 2, 32, },
		[2] = { 15, 2, 38, },
		[3] = { 16, 2, 45, },
		[4] = { 17, 3, 53, },
		[5] = { 18, 3, 62, },
		[6] = { 19, 4, 69, },
		[7] = { 20, 4, 76, },
		[8] = { 21, 4, 84, },
		[9] = { 22, 5, 93, },
		[10] = { 23, 5, 103, },
		[11] = { 24, 6, 113, },
		[12] = { 25, 7, 124, },
		[13] = { 25, 7, 137, },
		[14] = { 25, 8, 150, },
		[15] = { 26, 9, 165, },
		[16] = { 26, 10, 181, },
		[17] = { 26, 10, 199, },
		[18] = { 26, 11, 217, },
		[19] = { 27, 13, 238, },
		[20] = { 27, 14, 260, },
		[21] = { 28, 15, 285, },
		[22] = { 28, 16, 311, },
		[23] = { 29, 18, 340, },
		[24] = { 29, 20, 371, },
		[25] = { 30, 21, 404, },
		[26] = { 30, 23, 441, },
		[27] = { 30, 25, 480, },
		[28] = { 30, 28, 523, },
		[29] = { 31, 30, 570, },
		[30] = { 31, 33, 620, },
	},
}
gems["Blight"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	chaos = true,
	area = true,
	channelling = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
		area = true,
		chaos = true,
	},
	skillTypes = { [2] = true, [50] = true, [11] = true, [18] = true, [58] = true, [12] = true, [40] = true, [59] = true, [52] = true, },
	baseMods = {
		skill("castTime", 0.3), 
		skill("duration", 2.5), --"base_skill_effect_duration" = 2500
		--"base_secondary_skill_effect_duration" = 800
		mod("MovementSpeed", "INC", -80, 0, 0, nil), --"base_movement_velocity_+%" = -80
		--"display_max_blight_stacks" = 20
		skill("dotIsSpell", true), --"spell_damage_modifiers_apply_to_damage_over_time" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
		--[3] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 2, 1.7333333333333, 0, },
		[2] = { 2, 1.9666666666667, 0, },
		[3] = { 2, 2.4666666666667, 0, },
		[4] = { 2, 3.3666666666667, 0, },
		[5] = { 2, 4.8333333333333, 1, },
		[6] = { 2, 7.2166666666667, 1, },
		[7] = { 2, 9.6833333333333, 1, },
		[8] = { 2, 12.75, 1, },
		[9] = { 2, 16.566666666667, 1, },
		[10] = { 2, 21.266666666667, 2, },
		[11] = { 2, 27.05, 2, },
		[12] = { 3, 34.133333333333, 2, },
		[13] = { 3, 42.816666666667, 2, },
		[14] = { 3, 53.4, 2, },
		[15] = { 3, 66.283333333333, 3, },
		[16] = { 3, 81.916666666667, 3, },
		[17] = { 3, 100.88333333333, 3, },
		[18] = { 4, 123.83333333333, 3, },
		[19] = { 4, 144.11666666667, 3, },
		[20] = { 4, 167.48333333333, 4, },
		[21] = { 4, 184.96666666667, 4, },
		[22] = { 4, 204.16666666667, 4, },
		[23] = { 4, 225.23333333333, 4, },
		[24] = { 5, 248.33333333333, 4, },
		[25] = { 5, 273.66666666667, 5, },
		[26] = { 5, 301.41666666667, 5, },
		[27] = { 5, 331.83333333333, 5, },
		[28] = { 5, 365.16666666667, 5, },
		[29] = { 5, 401.66666666667, 5, },
		[30] = { 5, 441.61666666667, 6, },
	},
}
gems["Bone Offering"] = {
	minion = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [36] = true, [9] = true, [49] = true, [17] = true, [19] = true, [18] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"offering_skill_effect_duration_per_corpse" = 500
		--"base_deal_no_damage" = ?
		skill("offering", true), 
	},
	qualityMods = {
		mod("Duration", "INC", 0.5), --"skill_effect_duration_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("BlockChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"monster_base_block_%"
		[3] = mod("SpellBlockChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_spell_block_%"
		--[4] = "minion_recover_X_life_on_block"
	},
	levels = {
		[1] = { 16, 25, 25, 11, },
		[2] = { 17, 26, 25, 14, },
		[3] = { 18, 26, 26, 20, },
		[4] = { 19, 27, 26, 27, },
		[5] = { 20, 27, 27, 38, },
		[6] = { 21, 28, 27, 50, },
		[7] = { 22, 28, 28, 66, },
		[8] = { 23, 29, 28, 81, },
		[9] = { 24, 29, 29, 99, },
		[10] = { 25, 30, 29, 120, },
		[11] = { 26, 30, 30, 146, },
		[12] = { 27, 31, 30, 176, },
		[13] = { 28, 31, 31, 212, },
		[14] = { 29, 32, 31, 255, },
		[15] = { 29, 32, 32, 306, },
		[16] = { 30, 33, 32, 366, },
		[17] = { 30, 33, 33, 414, },
		[18] = { 31, 34, 33, 468, },
		[19] = { 32, 34, 34, 528, },
		[20] = { 33, 35, 34, 594, },
		[21] = { 34, 35, 35, 644, },
		[22] = { 34, 36, 35, 693, },
		[23] = { 35, 36, 36, 743, },
		[24] = { 36, 37, 36, 792, },
		[25] = { 37, 37, 37, 842, },
		[26] = { 38, 38, 37, 891, },
		[27] = { 38, 38, 38, 941, },
		[28] = { 39, 39, 38, 990, },
		[29] = { 40, 39, 39, 1040, },
		[30] = { 41, 40, 39, 1089, },
	},
}
gems["Clarity"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 3,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [18] = true, [44] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("ManaRegen", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_mana_regeneration_rate_per_minute"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 34, 2.9333333333333, 0, },
		[2] = { 48, 4.0333333333333, 3, },
		[3] = { 61, 5.0833333333333, 6, },
		[4] = { 76, 6.0833333333333, 9, },
		[5] = { 89, 7.0166666666667, 12, },
		[6] = { 102, 7.9166666666667, 15, },
		[7] = { 115, 8.75, 18, },
		[8] = { 129, 9.55, 21, },
		[9] = { 141, 10.316666666667, 23, },
		[10] = { 154, 11.05, 25, },
		[11] = { 166, 11.733333333333, 27, },
		[12] = { 178, 12.4, 29, },
		[13] = { 190, 13.033333333333, 31, },
		[14] = { 203, 13.65, 33, },
		[15] = { 214, 14.25, 35, },
		[16] = { 227, 14.85, 36, },
		[17] = { 239, 15.433333333333, 37, },
		[18] = { 251, 16.016666666667, 38, },
		[19] = { 265, 16.6, 39, },
		[20] = { 279, 17.183333333333, 40, },
		[21] = { 293, 17.766666666667, 41, },
		[22] = { 303, 18.366666666667, 42, },
		[23] = { 313, 18.966666666667, 43, },
		[24] = { 323, 19.566666666667, 44, },
		[25] = { 333, 20.166666666667, 45, },
		[26] = { 343, 20.766666666667, 46, },
		[27] = { 353, 21.366666666667, 47, },
		[28] = { 363, 21.983333333333, 48, },
		[29] = { 373, 22.6, 49, },
		[30] = { 383, 23.216666666667, 50, },
	},
}
gems["Vaal Clarity"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	color = 3,
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
		mod("ManaCost", "MORE", -100, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"no_mana_cost" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[2] = skill("duration", nil), --"base_skill_effect_duration"
	},
	levels = {
		[1] = { 0, 8, },
		[2] = { 3, 8.1, },
		[3] = { 6, 8.2, },
		[4] = { 9, 8.3, },
		[5] = { 12, 8.4, },
		[6] = { 15, 8.5, },
		[7] = { 18, 8.6, },
		[8] = { 21, 8.7, },
		[9] = { 23, 8.8, },
		[10] = { 25, 8.9, },
		[11] = { 27, 9, },
		[12] = { 29, 9.1, },
		[13] = { 31, 9.2, },
		[14] = { 33, 9.3, },
		[15] = { 35, 9.4, },
		[16] = { 36, 9.5, },
		[17] = { 37, 9.6, },
		[18] = { 38, 9.7, },
		[19] = { 39, 9.8, },
		[20] = { 40, 9.9, },
		[21] = { 41, 10, },
		[22] = { 42, 10.1, },
		[23] = { 43, 10.2, },
		[24] = { 44, 10.3, },
		[25] = { 45, 10.4, },
		[26] = { 46, 10.5, },
		[27] = { 47, 10.6, },
		[28] = { 48, 10.7, },
		[29] = { 49, 10.8, },
		[30] = { 50, 10.9, },
	},
}
gems["Cold Snap"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("damageEffectiveness", 1.2), 
		skill("critChance", 5), 
		mod("EnemyFreezeChance", "BASE", 30), --"base_chance_to_freeze_%" = 30
		mod("EnemyFreezeDuration", "INC", 30), --"freeze_duration_+%" = 30
		mod("EnemyChillDuration", "INC", 110), --"chill_duration_+%" = 110
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		--[4] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 11, 9, 13, 0, },
		[2] = { 12, 11, 16, 0, },
		[3] = { 13, 14, 21, 0, },
		[4] = { 14, 18, 27, 1, },
		[5] = { 15, 25, 37, 1, },
		[6] = { 16, 32, 49, 1, },
		[7] = { 17, 42, 63, 1, },
		[8] = { 18, 54, 81, 2, },
		[9] = { 19, 68, 102, 2, },
		[10] = { 20, 85, 128, 2, },
		[11] = { 21, 106, 159, 2, },
		[12] = { 22, 131, 196, 3, },
		[13] = { 23, 160, 240, 3, },
		[14] = { 24, 196, 294, 3, },
		[15] = { 25, 227, 341, 3, },
		[16] = { 26, 263, 394, 4, },
		[17] = { 26, 303, 455, 4, },
		[18] = { 27, 350, 524, 4, },
		[19] = { 27, 402, 603, 4, },
		[20] = { 28, 462, 693, 5, },
		[21] = { 28, 506, 759, 5, },
		[22] = { 29, 554, 832, 5, },
		[23] = { 29, 607, 910, 5, },
		[24] = { 30, 664, 996, 6, },
		[25] = { 30, 726, 1089, 6, },
		[26] = { 30, 794, 1191, 6, },
		[27] = { 30, 867, 1301, 6, },
		[28] = { 31, 947, 1420, 7, },
		[29] = { 31, 1033, 1550, 7, },
		[30] = { 32, 1127, 1691, 7, },
	},
}
gems["Vaal Cold Snap"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		cold = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [12] = true, [43] = true, [34] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("damageEffectiveness", 1.4), 
		skill("critChance", 5), 
		skill("duration", 10), --"base_skill_effect_duration" = 10000
		mod("EnemyFreezeChance", "BASE", 100), --"base_chance_to_freeze_%" = 100
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[2] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 11, 17, },
		[2] = { 14, 21, },
		[3] = { 18, 28, },
		[4] = { 24, 35, },
		[5] = { 32, 48, },
		[6] = { 42, 63, },
		[7] = { 55, 82, },
		[8] = { 70, 105, },
		[9] = { 88, 132, },
		[10] = { 111, 166, },
		[11] = { 137, 206, },
		[12] = { 170, 255, },
		[13] = { 208, 313, },
		[14] = { 255, 382, },
		[15] = { 295, 443, },
		[16] = { 342, 512, },
		[17] = { 394, 591, },
		[18] = { 454, 682, },
		[19] = { 523, 784, },
		[20] = { 600, 901, },
		[21] = { 658, 987, },
		[22] = { 721, 1081, },
		[23] = { 789, 1184, },
		[24] = { 863, 1295, },
		[25] = { 944, 1416, },
		[26] = { 1032, 1548, },
		[27] = { 1127, 1691, },
		[28] = { 1231, 1846, },
		[29] = { 1343, 2015, },
		[30] = { 1466, 2199, },
	},
}
gems["Conductivity"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, [45] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("SelfShockDuration", "INC", 1, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_self_shock_duration_-%" = -1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("LightningResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_lightning_damage_resistance_%"
		[5] = mod("SelfShockChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"chance_to_be_shocked_%"
	},
	levels = {
		[1] = { 24, 9, 0, -25, 10, },
		[2] = { 26, 9.1, 4, -26, 10, },
		[3] = { 27, 9.2, 8, -27, 10, },
		[4] = { 29, 9.3, 12, -28, 10, },
		[5] = { 30, 9.4, 16, -29, 10, },
		[6] = { 32, 9.5, 20, -30, 11, },
		[7] = { 34, 9.6, 24, -31, 11, },
		[8] = { 35, 9.7, 28, -32, 11, },
		[9] = { 37, 9.8, 32, -33, 11, },
		[10] = { 38, 9.9, 36, -34, 11, },
		[11] = { 39, 10, 40, -35, 12, },
		[12] = { 40, 10.1, 44, -36, 12, },
		[13] = { 42, 10.2, 48, -37, 12, },
		[14] = { 43, 10.3, 52, -38, 12, },
		[15] = { 44, 10.4, 56, -39, 12, },
		[16] = { 45, 10.5, 60, -40, 13, },
		[17] = { 46, 10.6, 64, -41, 13, },
		[18] = { 47, 10.7, 68, -42, 13, },
		[19] = { 48, 10.8, 72, -43, 13, },
		[20] = { 50, 10.9, 76, -44, 14, },
		[21] = { 51, 11, 80, -45, 14, },
		[22] = { 52, 11.1, 84, -46, 14, },
		[23] = { 53, 11.2, 88, -47, 15, },
		[24] = { 54, 11.3, 92, -48, 15, },
		[25] = { 56, 11.4, 96, -49, 15, },
		[26] = { 57, 11.5, 100, -50, 16, },
		[27] = { 58, 11.6, 104, -51, 16, },
		[28] = { 59, 11.7, 108, -52, 16, },
		[29] = { 60, 11.8, 112, -53, 17, },
		[30] = { 61, 11.9, 116, -54, 17, },
	},
}
gems["Contagion"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	chaos = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [40] = true, [50] = true, [26] = true, [36] = true, [19] = true, [52] = true, [59] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		--"is_area_damage" = ?
		skill("dotIsSpell", true), --"spell_damage_modifiers_apply_to_damage_over_time" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
	},
	levels = {
		[1] = { 11, 3.1666666666667, },
		[2] = { 12, 3.9, },
		[3] = { 13, 5.15, },
		[4] = { 14, 6.65, },
		[5] = { 15, 9.0666666666667, },
		[6] = { 16, 12.066666666667, },
		[7] = { 17, 15.766666666667, },
		[8] = { 18, 20.3, },
		[9] = { 19, 25.866666666667, },
		[10] = { 20, 32.65, },
		[11] = { 21, 40.9, },
		[12] = { 22, 50.9, },
		[13] = { 23, 63, },
		[14] = { 24, 77.583333333333, },
		[15] = { 25, 90.466666666667, },
		[16] = { 26, 105.25, },
		[17] = { 26, 122.2, },
		[18] = { 27, 141.65, },
		[19] = { 27, 163.9, },
		[20] = { 28, 189.36666666667, },
		[21] = { 28, 208.35, },
		[22] = { 29, 229.08333333333, },
		[23] = { 29, 251.75, },
		[24] = { 30, 276.5, },
		[25] = { 30, 303.51666666667, },
		[26] = { 30, 333.03333333333, },
		[27] = { 30, 365.21666666667, },
		[28] = { 31, 400.35, },
		[29] = { 31, 438.66666666667, },
		[30] = { 32, 480.45, },
	},
}
gems["Conversion Trap"] = {
	trap = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	unsupported = true,
}
gems["Convocation"] = {
	minion = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	unsupported = true,
}
gems["Discharge"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	cold = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		lightning = true,
		cold = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [18] = true, [26] = true, [36] = true, [45] = true, [33] = true, [34] = true, [35] = true, [60] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 1.5), 
		skill("critChance", 7), 
		--"skill_override_pvp_scaling_time_ms" = 1400
		mod("Damage", "MORE", -35, ModFlag.Spell, 0, { type = "Condition", var = "SkillIsTriggered" }), --"triggered_discharge_damage_+%_final" = -35
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil, { type = "Multiplier", var = "PowerCharge" }), --"spell_minimum_base_lightning_damage_per_power_charge"
		[3] = skill("LightningMax", nil, { type = "Multiplier", var = "PowerCharge" }), --"spell_maximum_base_lightning_damage_per_power_charge"
		[4] = skill("FireMin", nil, { type = "Multiplier", var = "EnduranceCharge" }), --"spell_minimum_base_fire_damage_per_endurance_charge"
		[5] = skill("FireMax", nil, { type = "Multiplier", var = "EnduranceCharge" }), --"spell_maximum_base_fire_damage_per_endurance_charge"
		[6] = skill("ColdMin", nil, { type = "Multiplier", var = "FrenzyCharge" }), --"spell_minimum_base_cold_damage_per_frenzy_charge"
		[7] = skill("ColdMax", nil, { type = "Multiplier", var = "FrenzyCharge" }), --"spell_maximum_base_cold_damage_per_frenzy_charge"
	},
	levels = {
		[1] = { 24, 4, 77, 29, 43, 24, 36, },
		[2] = { 26, 5, 92, 34, 51, 28, 42, },
		[3] = { 27, 6, 108, 40, 60, 33, 49, },
		[4] = { 29, 7, 126, 47, 71, 39, 58, },
		[5] = { 31, 8, 147, 55, 83, 45, 68, },
		[6] = { 32, 9, 163, 61, 91, 50, 75, },
		[7] = { 33, 9, 180, 67, 101, 55, 82, },
		[8] = { 34, 10, 198, 74, 111, 61, 91, },
		[9] = { 35, 11, 218, 82, 122, 67, 100, },
		[10] = { 36, 13, 240, 90, 135, 73, 110, },
		[11] = { 37, 14, 263, 99, 148, 81, 121, },
		[12] = { 38, 15, 289, 108, 162, 88, 133, },
		[13] = { 39, 17, 317, 119, 178, 97, 146, },
		[14] = { 40, 18, 347, 130, 195, 106, 159, },
		[15] = { 41, 20, 380, 142, 213, 116, 174, },
		[16] = { 42, 22, 415, 155, 233, 127, 191, },
		[17] = { 44, 24, 454, 170, 255, 139, 208, },
		[18] = { 45, 26, 495, 185, 278, 152, 227, },
		[19] = { 46, 28, 540, 202, 303, 165, 248, },
		[20] = { 47, 31, 589, 220, 331, 180, 271, },
		[21] = { 48, 34, 642, 240, 360, 197, 295, },
		[22] = { 49, 37, 699, 262, 392, 214, 321, },
		[23] = { 50, 40, 761, 285, 427, 233, 349, },
		[24] = { 51, 44, 828, 310, 465, 253, 380, },
		[25] = { 52, 47, 900, 337, 505, 276, 413, },
		[26] = { 53, 51, 978, 366, 549, 299, 449, },
		[27] = { 54, 56, 1062, 397, 596, 325, 488, },
		[28] = { 55, 61, 1153, 431, 647, 353, 529, },
		[29] = { 57, 66, 1251, 468, 702, 383, 575, },
		[30] = { 58, 71, 1357, 508, 762, 416, 623, },
	},
}
gems["Discipline"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 3,
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
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("EnergyShield", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_energy_shield"
		[2] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 60, 0, },
		[2] = { 70, 3, },
		[3] = { 78, 6, },
		[4] = { 89, 9, },
		[5] = { 100, 12, },
		[6] = { 111, 15, },
		[7] = { 125, 18, },
		[8] = { 139, 21, },
		[9] = { 154, 23, },
		[10] = { 165, 25, },
		[11] = { 173, 27, },
		[12] = { 187, 29, },
		[13] = { 201, 31, },
		[14] = { 213, 33, },
		[15] = { 227, 35, },
		[16] = { 239, 36, },
		[17] = { 253, 37, },
		[18] = { 269, 38, },
		[19] = { 281, 39, },
		[20] = { 303, 40, },
		[21] = { 315, 41, },
		[22] = { 330, 42, },
		[23] = { 340, 43, },
		[24] = { 357, 44, },
		[25] = { 374, 45, },
		[26] = { 384, 46, },
		[27] = { 406, 47, },
		[28] = { 425, 48, },
		[29] = { 450, 49, },
		[30] = { 455, 50, },
	},
}
gems["Vaal Discipline"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	color = 3,
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
		mod("EnergyShield", "BASE", 0, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_energy_shield" = 0
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"energy_shield_recharge_not_delayed_by_damage" = ?
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 0, },
		[2] = { 3, },
		[3] = { 6, },
		[4] = { 9, },
		[5] = { 12, },
		[6] = { 15, },
		[7] = { 18, },
		[8] = { 21, },
		[9] = { 23, },
		[10] = { 25, },
		[11] = { 27, },
		[12] = { 29, },
		[13] = { 31, },
		[14] = { 33, },
		[15] = { 35, },
		[16] = { 36, },
		[17] = { 37, },
		[18] = { 38, },
		[19] = { 39, },
		[20] = { 40, },
		[21] = { 41, },
		[22] = { 42, },
		[23] = { 43, },
		[24] = { 44, },
		[25] = { 45, },
		[26] = { 46, },
		[27] = { 47, },
		[28] = { 48, },
		[29] = { 49, },
		[30] = { 50, },
	},
}
gems["Elemental Weakness"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("ElementalResist", "BASE", -0.25, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_resist_all_elements_%" = -0.25
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("ElementalResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_resist_all_elements_%"
	},
	levels = {
		[1] = { 24, 9, 0, -20, },
		[2] = { 26, 9.1, 4, -21, },
		[3] = { 27, 9.2, 8, -22, },
		[4] = { 29, 9.3, 12, -23, },
		[5] = { 30, 9.4, 16, -24, },
		[6] = { 32, 9.5, 20, -25, },
		[7] = { 34, 9.6, 24, -26, },
		[8] = { 35, 9.7, 28, -27, },
		[9] = { 37, 9.8, 32, -28, },
		[10] = { 38, 9.9, 36, -29, },
		[11] = { 39, 10, 40, -30, },
		[12] = { 40, 10.1, 44, -31, },
		[13] = { 42, 10.2, 48, -32, },
		[14] = { 43, 10.3, 52, -33, },
		[15] = { 44, 10.4, 56, -34, },
		[16] = { 45, 10.5, 60, -35, },
		[17] = { 46, 10.6, 64, -36, },
		[18] = { 47, 10.7, 68, -37, },
		[19] = { 48, 10.8, 72, -38, },
		[20] = { 50, 10.9, 76, -39, },
		[21] = { 51, 11, 80, -40, },
		[22] = { 52, 11.1, 84, -41, },
		[23] = { 53, 11.2, 88, -42, },
		[24] = { 54, 11.3, 92, -43, },
		[25] = { 56, 11.4, 96, -44, },
		[26] = { 57, 11.5, 100, -45, },
		[27] = { 58, 11.6, 104, -46, },
		[28] = { 59, 11.7, 108, -47, },
		[29] = { 60, 11.8, 112, -48, },
		[30] = { 61, 11.9, 116, -49, },
	},
}
gems["Enfeeble"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		mod("CritChance", "INC", -25, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"critical_strike_chance_+%" = -25
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("Accuracy", "INC", -0.5, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"accuracy_rating_+%" = -0.5
		mod("CritChance", "INC", -0.5, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"critical_strike_chance_+%" = -0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("Accuracy", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"accuracy_rating_+%"
		[5] = mod("Damage", "MORE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"enfeeble_damage_+%_final"
		[6] = mod("CritMultiplier", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_critical_strike_multiplier_+"
	},
	levels = {
		[1] = { 24, 9, 0, -18, -21, -21, },
		[2] = { 26, 9.1, 4, -19, -21, -21, },
		[3] = { 27, 9.2, 8, -20, -22, -22, },
		[4] = { 29, 9.3, 12, -21, -22, -22, },
		[5] = { 30, 9.4, 16, -22, -23, -23, },
		[6] = { 32, 9.5, 20, -23, -23, -23, },
		[7] = { 34, 9.6, 24, -24, -24, -24, },
		[8] = { 35, 9.7, 28, -25, -24, -24, },
		[9] = { 37, 9.8, 32, -26, -25, -25, },
		[10] = { 38, 9.9, 36, -27, -25, -25, },
		[11] = { 39, 10, 40, -28, -26, -26, },
		[12] = { 40, 10.1, 44, -29, -26, -26, },
		[13] = { 42, 10.2, 48, -30, -27, -27, },
		[14] = { 43, 10.3, 52, -31, -27, -27, },
		[15] = { 44, 10.4, 56, -32, -28, -28, },
		[16] = { 45, 10.5, 60, -33, -28, -28, },
		[17] = { 46, 10.6, 64, -34, -29, -29, },
		[18] = { 47, 10.7, 68, -35, -29, -29, },
		[19] = { 48, 10.8, 72, -36, -30, -30, },
		[20] = { 50, 10.9, 76, -37, -30, -30, },
		[21] = { 51, 11, 80, -38, -31, -31, },
		[22] = { 52, 11.1, 84, -39, -31, -31, },
		[23] = { 53, 11.2, 88, -40, -32, -32, },
		[24] = { 54, 11.3, 92, -41, -32, -32, },
		[25] = { 56, 11.4, 96, -42, -33, -33, },
		[26] = { 57, 11.5, 100, -43, -33, -33, },
		[27] = { 58, 11.6, 104, -44, -34, -34, },
		[28] = { 59, 11.7, 108, -45, -34, -34, },
		[29] = { 60, 11.8, 112, -46, -35, -35, },
		[30] = { 61, 11.9, 116, -47, -35, -35, },
	},
}
gems["Essence Drain"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	chaos = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [2] = true, [3] = true, [12] = true, [18] = true, [26] = true, [40] = true, [50] = true, [10] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.75), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 5), 
		--"siphon_life_leech_from_damage_permyriad" = 50
		skill("duration", 3.8), --"base_skill_effect_duration" = 3800
		skill("dotIsSpell", true), --"spell_damage_modifiers_apply_to_damage_over_time" = ?
		--"base_is_projectile" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("ChaosDamage", "INC", 1), --"chaos_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ChaosDot", nil), --"base_chaos_damage_to_deal_per_minute"
		[3] = skill("ChaosMin", nil), --"spell_minimum_base_chaos_damage"
		[4] = skill("ChaosMax", nil), --"spell_maximum_base_chaos_damage"
	},
	levels = {
		[1] = { 9, 21.483333333333, 6, 9, },
		[2] = { 10, 27.566666666667, 8, 12, },
		[3] = { 11, 37.6, 11, 16, },
		[4] = { 12, 50.3, 14, 22, },
		[5] = { 13, 66.266666666667, 19, 29, },
		[6] = { 14, 86.283333333333, 25, 37, },
		[7] = { 16, 111.26666666667, 32, 48, },
		[8] = { 16, 133.93333333333, 39, 58, },
		[9] = { 17, 160.58333333333, 46, 69, },
		[10] = { 18, 191.85, 55, 83, },
		[11] = { 19, 228.5, 66, 99, },
		[12] = { 20, 271.4, 78, 117, },
		[13] = { 21, 321.53333333333, 93, 139, },
		[14] = { 22, 380.05, 109, 164, },
		[15] = { 23, 448.3, 129, 194, },
		[16] = { 24, 527.78333333333, 152, 228, },
		[17] = { 24, 587.88333333333, 169, 254, },
		[18] = { 25, 654.35, 188, 283, },
		[19] = { 26, 727.81666666667, 210, 314, },
		[20] = { 27, 809, 233, 349, },
		[21] = { 28, 898.68333333333, 259, 388, },
		[22] = { 29, 997.7, 287, 431, },
		[23] = { 29, 1107, 319, 478, },
		[24] = { 30, 1227.6, 354, 530, },
		[25] = { 30, 1360.6333333333, 392, 588, },
		[26] = { 31, 1507.3333333333, 434, 651, },
		[27] = { 32, 1669.0666666667, 481, 721, },
		[28] = { 33, 1847.3, 532, 798, },
		[29] = { 33, 2043.6833333333, 589, 883, },
		[30] = { 34, 2260, 651, 976, },
	},
}
gems["Fire Nova Mine"] = {
	area = true,
	mine = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	fire = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		mine = true,
		area = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [36] = true, [11] = true, [33] = true, [26] = true, [41] = true, [12] = true, },
	baseMods = {
		skill("castTime", 0.4), 
		skill("damageEffectiveness", 0.3), 
		skill("critChance", 5), 
		--"base_mine_duration" = 16000
		skill("repeatCount", 3), --"base_spell_repeat_count" = 3
		--"base_skill_is_mined" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"is_remote_mine" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("FireDamage", "INC", 1), --"fire_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		--[4] = "fire_nova_damage_+%_per_repeat_final"
	},
	levels = {
		[1] = { 12, 6, 9, 20, },
		[2] = { 13, 7, 11, 20, },
		[3] = { 15, 10, 14, 21, },
		[4] = { 17, 12, 18, 21, },
		[5] = { 18, 16, 23, 22, },
		[6] = { 20, 20, 29, 22, },
		[7] = { 22, 24, 36, 23, },
		[8] = { 23, 28, 43, 23, },
		[9] = { 24, 33, 50, 24, },
		[10] = { 25, 39, 58, 24, },
		[11] = { 27, 45, 67, 25, },
		[12] = { 28, 52, 77, 25, },
		[13] = { 29, 60, 89, 26, },
		[14] = { 31, 68, 103, 26, },
		[15] = { 32, 79, 118, 27, },
		[16] = { 33, 90, 135, 27, },
		[17] = { 34, 98, 148, 28, },
		[18] = { 35, 107, 161, 28, },
		[19] = { 36, 117, 176, 29, },
		[20] = { 36, 128, 192, 29, },
		[21] = { 37, 140, 210, 30, },
		[22] = { 38, 152, 228, 30, },
		[23] = { 39, 166, 249, 31, },
		[24] = { 40, 181, 271, 31, },
		[25] = { 41, 197, 295, 32, },
		[26] = { 41, 214, 321, 32, },
		[27] = { 42, 232, 349, 33, },
		[28] = { 43, 253, 379, 33, },
		[29] = { 44, 274, 412, 34, },
		[30] = { 45, 298, 447, 34, },
	},
}
gems["Fireball"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	parts = {
		{
			name = "Projectile",
			area = false,
		},
		{
			name = "Explosion",
			area = true,
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		fire = true,
	},
	skillTypes = { [3] = true, [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("critChance", 6), 
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("EnemyIgniteChance", "BASE", 0.5), --"base_chance_to_ignite_%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[4] = mod("EnemyIgniteChance", "BASE", nil), --"base_chance_to_ignite_%"
		--[5] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 6, 7, 10, 20, 0, },
		[2] = { 6, 8, 11, 21, 0, },
		[3] = { 7, 10, 14, 22, 0, },
		[4] = { 8, 13, 20, 23, 0, },
		[5] = { 9, 19, 29, 24, 0, },
		[6] = { 10, 29, 43, 25, 1, },
		[7] = { 11, 39, 58, 26, 1, },
		[8] = { 12, 52, 77, 27, 1, },
		[9] = { 13, 67, 101, 28, 1, },
		[10] = { 15, 87, 131, 29, 1, },
		[11] = { 16, 112, 168, 30, 1, },
		[12] = { 17, 142, 213, 31, 2, },
		[13] = { 18, 180, 270, 32, 2, },
		[14] = { 19, 226, 339, 33, 2, },
		[15] = { 21, 283, 424, 34, 2, },
		[16] = { 22, 352, 528, 35, 2, },
		[17] = { 23, 437, 655, 36, 2, },
		[18] = { 24, 540, 810, 37, 3, },
		[19] = { 25, 632, 948, 38, 3, },
		[20] = { 26, 739, 1109, 39, 3, },
		[21] = { 27, 819, 1229, 40, 3, },
		[22] = { 27, 908, 1362, 41, 3, },
		[23] = { 28, 1005, 1508, 42, 3, },
		[24] = { 28, 1113, 1669, 43, 4, },
		[25] = { 29, 1231, 1847, 44, 4, },
		[26] = { 30, 1361, 2042, 45, 4, },
		[27] = { 30, 1504, 2257, 46, 4, },
		[28] = { 31, 1662, 2493, 47, 4, },
		[29] = { 31, 1835, 2752, 48, 4, },
		[30] = { 32, 2025, 3038, 49, 5, },
	},
}
gems["Vaal Fireball"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	fire = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		fire = true,
		vaal = true,
	},
	skillTypes = { [3] = true, [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [43] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("damageEffectiveness", 1.25), 
		skill("critChance", 6), 
		--"base_number_of_projectiles_in_spiral_nova" = 32
		--"projectile_spiral_nova_time_ms" = 2000
		--"projectile_spiral_nova_angle" = -720
		mod("AreaOfEffect", "INC", 50), --"base_skill_area_of_effect_+%" = 50
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("EnemyIgniteChance", "BASE", 1.5), --"base_chance_to_ignite_%" = 1.5
	},
	levelMods = {
		[1] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[2] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 8, 11, },
		[2] = { 9, 13, },
		[3] = { 11, 16, },
		[4] = { 14, 22, },
		[5] = { 20, 30, },
		[6] = { 30, 45, },
		[7] = { 39, 59, },
		[8] = { 51, 76, },
		[9] = { 65, 98, },
		[10] = { 82, 124, },
		[11] = { 103, 155, },
		[12] = { 128, 192, },
		[13] = { 158, 238, },
		[14] = { 195, 292, },
		[15] = { 238, 357, },
		[16] = { 289, 434, },
		[17] = { 351, 526, },
		[18] = { 424, 636, },
		[19] = { 488, 732, },
		[20] = { 560, 841, },
		[21] = { 614, 921, },
		[22] = { 673, 1009, },
		[23] = { 736, 1105, },
		[24] = { 806, 1209, },
		[25] = { 881, 1322, },
		[26] = { 963, 1445, },
		[27] = { 1052, 1578, },
		[28] = { 1149, 1723, },
		[29] = { 1254, 1881, },
		[30] = { 1368, 2052, },
	},
}
gems["Firestorm"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	fire = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.9), 
		skill("damageEffectiveness", 0.3), 
		skill("critChance", 6), 
		skill("duration", 2), --"base_skill_effect_duration" = 2000
		--"fire_storm_fireball_delay_ms" = 100
		--"is_area_damage" = 1
		--"skill_override_pvp_scaling_time_ms" = 450
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 9, 4, 10, },
		[2] = { 10, 9, 13, },
		[3] = { 11, 11, 17, },
		[4] = { 12, 15, 22, },
		[5] = { 13, 19, 28, },
		[6] = { 14, 23, 35, },
		[7] = { 15, 29, 44, },
		[8] = { 16, 35, 52, },
		[9] = { 17, 40, 61, },
		[10] = { 18, 47, 71, },
		[11] = { 19, 55, 82, },
		[12] = { 20, 64, 95, },
		[13] = { 21, 74, 110, },
		[14] = { 22, 85, 127, },
		[15] = { 23, 98, 147, },
		[16] = { 24, 112, 169, },
		[17] = { 24, 123, 185, },
		[18] = { 25, 135, 203, },
		[19] = { 25, 148, 222, },
		[20] = { 26, 162, 243, },
		[21] = { 26, 177, 265, },
		[22] = { 27, 193, 290, },
		[23] = { 27, 211, 317, },
		[24] = { 28, 231, 346, },
		[25] = { 29, 251, 377, },
		[26] = { 30, 274, 411, },
		[27] = { 30, 299, 448, },
		[28] = { 30, 326, 488, },
		[29] = { 31, 355, 532, },
		[30] = { 32, 386, 579, },
	},
}
gems["Flame Dash"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	movement = true,
	duration = true,
	fire = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		movement = true,
		fire = true,
	},
	skillTypes = { [2] = true, [38] = true, [10] = true, [40] = true, [12] = true, [18] = true, [36] = true, [33] = true, [17] = true, [19] = true, },
	baseMods = {
		skill("castTime", 0.75), 
		skill("critChance", 6), 
		skill("duration", 4), --"base_skill_effect_duration" = 4000
		--"is_area_damage" = ?
		--"firestorm_use_server_effects" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Cast), --"base_cast_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[4] = skill("FireDot", nil), --"base_fire_damage_to_deal_per_minute"
	},
	levels = {
		[1] = { 10, 6, 9, 10.9, },
		[2] = { 11, 8, 11, 14.3, },
		[3] = { 12, 11, 16, 20.016666666667, },
		[4] = { 13, 15, 22, 27.366666666667, },
		[5] = { 14, 20, 29, 36.816666666667, },
		[6] = { 15, 26, 39, 48.866666666667, },
		[7] = { 16, 34, 51, 64.15, },
		[8] = { 17, 42, 63, 78.233333333333, },
		[9] = { 18, 51, 76, 94.983333333333, },
		[10] = { 20, 61, 92, 114.9, },
		[11] = { 21, 74, 111, 138.5, },
		[12] = { 22, 89, 133, 166.48333333333, },
		[13] = { 24, 106, 160, 199.55, },
		[14] = { 25, 127, 191, 238.61666666667, },
		[15] = { 26, 152, 228, 284.7, },
		[16] = { 27, 181, 271, 339, },
		[17] = { 28, 215, 322, 402.9, },
		[18] = { 29, 255, 382, 478.05, },
		[19] = { 30, 285, 428, 535.3, },
		[20] = { 30, 319, 479, 599.01666666667, },
		[21] = { 31, 357, 536, 669.9, },
		[22] = { 32, 399, 599, 748.71666666667, },
		[23] = { 33, 446, 669, 836.35, },
		[24] = { 34, 498, 747, 933.7, },
		[25] = { 34, 556, 833, 1041.8666666667, },
		[26] = { 35, 620, 930, 1161.9666666667, },
		[27] = { 36, 691, 1036, 1295.3166666667, },
		[28] = { 37, 770, 1155, 1443.3, },
		[29] = { 38, 857, 1286, 1607.4833333333, },
		[30] = { 38, 954, 1432, 1789.6, },
	},
}
gems["Flame Surge"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [11] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("critChance", 6), 
		mod("Damage", "MORE", 50, bit.bor(ModFlag.Spell, ModFlag.Hit), 0, { type = "Condition", var = "EnemyBurning" }), --"flame_whip_damage_+%_final_vs_burning_enemies" = 50
		flag("CannotIgnite"), --"never_ignite" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 0.5, ModFlag.Cast), --"base_cast_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 5, 21, 31, },
		[2] = { 6, 26, 39, },
		[3] = { 6, 35, 52, },
		[4] = { 7, 45, 67, },
		[5] = { 7, 57, 86, },
		[6] = { 8, 73, 109, },
		[7] = { 9, 91, 137, },
		[8] = { 9, 107, 161, },
		[9] = { 10, 126, 189, },
		[10] = { 10, 147, 221, },
		[11] = { 11, 171, 257, },
		[12] = { 12, 199, 299, },
		[13] = { 12, 231, 346, },
		[14] = { 13, 267, 401, },
		[15] = { 13, 308, 462, },
		[16] = { 13, 355, 533, },
		[17] = { 13, 390, 585, },
		[18] = { 14, 428, 642, },
		[19] = { 15, 469, 703, },
		[20] = { 15, 514, 771, },
		[21] = { 15, 563, 844, },
		[22] = { 15, 616, 923, },
		[23] = { 16, 673, 1010, },
		[24] = { 16, 736, 1104, },
		[25] = { 17, 804, 1206, },
		[26] = { 18, 878, 1317, },
		[27] = { 18, 958, 1437, },
		[28] = { 18, 1045, 1567, },
		[29] = { 18, 1139, 1709, },
		[30] = { 19, 1242, 1863, },
	},
}
gems["Flameblast"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	channelling = true,
	parts = {
		{
			name = "1 Stage",
		},
		{
			name = "10 Stages",
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [18] = true, [33] = true, [58] = true, },
	baseMods = {
		skill("castTime", 0.2), 
		skill("damageEffectiveness", 0.5), 
		skill("critChance", 5), 
		--"charged_blast_spell_damage_+%_final_per_stack" = 110
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		mod("Damage", "MORE", 990, 0, 0, { type = "SkillPart", skillPart = 2 }), 
		skill("dpsMultiplier", 0.1, { type = "SkillPart", skillPart = 2 }), 
		skill("showAverage", false), 
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 6, 32, 48, },
		[2] = { 6, 38, 57, },
		[3] = { 6, 45, 67, },
		[4] = { 6, 52, 78, },
		[5] = { 7, 61, 91, },
		[6] = { 7, 67, 101, },
		[7] = { 7, 74, 111, },
		[8] = { 7, 82, 123, },
		[9] = { 7, 90, 135, },
		[10] = { 8, 99, 148, },
		[11] = { 8, 109, 163, },
		[12] = { 8, 119, 179, },
		[13] = { 8, 130, 196, },
		[14] = { 8, 143, 214, },
		[15] = { 9, 156, 234, },
		[16] = { 9, 171, 256, },
		[17] = { 9, 186, 279, },
		[18] = { 9, 203, 305, },
		[19] = { 9, 221, 332, },
		[20] = { 9, 241, 362, },
		[21] = { 10, 263, 394, },
		[22] = { 10, 286, 429, },
		[23] = { 10, 311, 466, },
		[24] = { 11, 338, 507, },
		[25] = { 11, 367, 550, },
		[26] = { 11, 398, 598, },
		[27] = { 12, 432, 649, },
		[28] = { 12, 469, 704, },
		[29] = { 12, 509, 763, },
		[30] = { 13, 551, 827, },
	},
}
gems["Vaal Flameblast"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	fire = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [18] = true, [43] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 5), 
		--"charged_blast_spell_damage_+%_final_per_stack" = 110
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		mod("Damage", "MORE", 1100, ModFlag.Spell), 
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[2] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 39, 58, },
		[2] = { 46, 68, },
		[3] = { 53, 80, },
		[4] = { 62, 93, },
		[5] = { 71, 107, },
		[6] = { 78, 117, },
		[7] = { 86, 129, },
		[8] = { 94, 141, },
		[9] = { 103, 154, },
		[10] = { 113, 169, },
		[11] = { 123, 184, },
		[12] = { 134, 201, },
		[13] = { 146, 219, },
		[14] = { 159, 238, },
		[15] = { 173, 259, },
		[16] = { 188, 282, },
		[17] = { 204, 306, },
		[18] = { 221, 332, },
		[19] = { 240, 360, },
		[20] = { 260, 390, },
		[21] = { 281, 422, },
		[22] = { 305, 457, },
		[23] = { 329, 494, },
		[24] = { 356, 534, },
		[25] = { 385, 577, },
		[26] = { 416, 623, },
		[27] = { 449, 673, },
		[28] = { 484, 726, },
		[29] = { 522, 783, },
		[30] = { 563, 844, },
	},
}
gems["Flammability"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	fire = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, [33] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("SelfIgniteDuration", "INC", 0.5, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_self_ignite_duration_-%" = -0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("FireResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_fire_damage_resistance_%"
		[5] = mod("SelfIgniteChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"chance_to_be_ignited_%"
	},
	levels = {
		[1] = { 24, 9, 0, -25, 10, },
		[2] = { 26, 9.1, 4, -26, 10, },
		[3] = { 27, 9.2, 8, -27, 10, },
		[4] = { 29, 9.3, 12, -28, 10, },
		[5] = { 30, 9.4, 16, -29, 10, },
		[6] = { 32, 9.5, 20, -30, 11, },
		[7] = { 34, 9.6, 24, -31, 11, },
		[8] = { 35, 9.7, 28, -32, 11, },
		[9] = { 37, 9.8, 32, -33, 11, },
		[10] = { 38, 9.9, 36, -34, 11, },
		[11] = { 39, 10, 40, -35, 12, },
		[12] = { 40, 10.1, 44, -36, 12, },
		[13] = { 42, 10.2, 48, -37, 12, },
		[14] = { 43, 10.3, 52, -38, 12, },
		[15] = { 44, 10.4, 56, -39, 12, },
		[16] = { 45, 10.5, 60, -40, 13, },
		[17] = { 46, 10.6, 64, -41, 13, },
		[18] = { 47, 10.7, 68, -42, 13, },
		[19] = { 48, 10.8, 72, -43, 13, },
		[20] = { 50, 10.9, 76, -44, 14, },
		[21] = { 51, 11, 80, -45, 14, },
		[22] = { 52, 11.1, 84, -46, 14, },
		[23] = { 53, 11.2, 88, -47, 15, },
		[24] = { 54, 11.3, 92, -48, 15, },
		[25] = { 56, 11.4, 96, -49, 15, },
		[26] = { 57, 11.5, 100, -50, 16, },
		[27] = { 58, 11.6, 104, -51, 16, },
		[28] = { 59, 11.7, 108, -52, 16, },
		[29] = { 60, 11.8, 112, -53, 17, },
		[30] = { 61, 11.9, 116, -54, 17, },
	},
}
gems["Flesh Offering"] = {
	minion = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [36] = true, [9] = true, [49] = true, [17] = true, [19] = true, [18] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"offering_skill_effect_duration_per_corpse" = 500
		--"base_deal_no_damage" = ?
		skill("offering", true), 
	},
	qualityMods = {
		mod("Duration", "INC", 0.5), --"skill_effect_duration_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_speed_+%"
		[3] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_movement_velocity_+%"
		[4] = mod("Speed", "INC", nil, ModFlag.Cast, 0, { type = "GlobalEffect", effectType = "Buff" }), --"cast_speed_+%_from_haste_aura"
	},
	levels = {
		[1] = { 16, 20, 20, 20, },
		[2] = { 17, 21, 20, 21, },
		[3] = { 18, 21, 21, 21, },
		[4] = { 19, 22, 21, 22, },
		[5] = { 20, 22, 22, 22, },
		[6] = { 21, 23, 22, 23, },
		[7] = { 22, 23, 23, 23, },
		[8] = { 23, 24, 23, 24, },
		[9] = { 24, 24, 24, 24, },
		[10] = { 25, 25, 24, 25, },
		[11] = { 26, 25, 25, 25, },
		[12] = { 27, 26, 25, 26, },
		[13] = { 28, 26, 26, 26, },
		[14] = { 29, 27, 26, 27, },
		[15] = { 29, 27, 27, 27, },
		[16] = { 30, 28, 27, 28, },
		[17] = { 30, 28, 28, 28, },
		[18] = { 31, 29, 28, 29, },
		[19] = { 32, 29, 29, 29, },
		[20] = { 33, 30, 29, 30, },
		[21] = { 34, 30, 30, 30, },
		[22] = { 34, 31, 30, 31, },
		[23] = { 35, 31, 31, 31, },
		[24] = { 36, 32, 31, 32, },
		[25] = { 37, 32, 32, 32, },
		[26] = { 38, 33, 32, 33, },
		[27] = { 38, 33, 33, 33, },
		[28] = { 39, 34, 33, 34, },
		[29] = { 40, 34, 34, 34, },
		[30] = { 41, 35, 34, 35, },
	},
}
gems["Freezing Pulse"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	cold = true,
	setupFunc = function(env, output)
		env.modDB:NewMod("Damage", "MORE", -100, "Skill:Freezing Pulse", ModFlag.Spell, { type = "DistanceRamp", ramp = {{0,0},{60*output.ProjectileSpeedMod,1}} })
		env.modDB:NewMod("EnemyFreezeChance", "BASE", 25, "Skill:Freezing Pulse", { type = "DistanceRamp", ramp = {{0,1},{15*output.ProjectileSpeedMod,0}} })
	end,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		cold = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.65), 
		skill("damageEffectiveness", 1.25), 
		skill("critChance", 6), 
		--"base_is_projectile" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
	},
	qualityMods = {
		mod("ProjectileSpeed", "INC", 2), --"base_projectile_speed_+%" = 2
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		[4] = mod("ProjectileSpeed", "INC", nil), --"base_projectile_speed_+%"
	},
	levels = {
		[1] = { 4, 7, 11, 0, },
		[2] = { 5, 8, 13, 1, },
		[3] = { 6, 11, 16, 2, },
		[4] = { 7, 15, 23, 3, },
		[5] = { 8, 22, 33, 4, },
		[6] = { 9, 32, 49, 5, },
		[7] = { 10, 43, 65, 6, },
		[8] = { 11, 57, 85, 7, },
		[9] = { 12, 73, 110, 8, },
		[10] = { 13, 93, 140, 9, },
		[11] = { 14, 118, 176, 10, },
		[12] = { 14, 148, 221, 11, },
		[13] = { 15, 184, 276, 12, },
		[14] = { 16, 228, 342, 13, },
		[15] = { 17, 281, 421, 14, },
		[16] = { 18, 345, 517, 15, },
		[17] = { 18, 422, 633, 16, },
		[18] = { 18, 515, 772, 17, },
		[19] = { 18, 596, 894, 18, },
		[20] = { 18, 689, 1034, 19, },
		[21] = { 18, 759, 1138, 20, },
		[22] = { 19, 835, 1252, 21, },
		[23] = { 19, 918, 1377, 22, },
		[24] = { 19, 1009, 1513, 23, },
		[25] = { 20, 1108, 1662, 24, },
		[26] = { 20, 1216, 1824, 25, },
		[27] = { 20, 1335, 2002, 26, },
		[28] = { 21, 1464, 2196, 27, },
		[29] = { 21, 1605, 2407, 28, },
		[30] = { 21, 1759, 2638, 29, },
	},
}
gems["Frost Bomb"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [34] = true, [10] = true, [26] = true, [18] = true, [17] = true, [19] = true, [36] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 1.3), 
		skill("critChance", 6), 
		skill("duration", 3.5), --"base_skill_effect_duration" = 3500
		--"base_secondary_skill_effect_duration" = 2000
		mod("ColdResist", "BASE", -20, 0, 0, { type = "GlobalEffect", effectType = "Debuff" }), --"base_cold_damage_resistance_%" = -20
		--"life_regeneration_rate_+%" = -75
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("ColdDamage", "INC", 1), --"cold_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 6, 10, 14, },
		[2] = { 7, 12, 18, },
		[3] = { 8, 15, 23, },
		[4] = { 9, 20, 30, },
		[5] = { 10, 27, 40, },
		[6] = { 11, 36, 54, },
		[7] = { 12, 46, 70, },
		[8] = { 13, 59, 89, },
		[9] = { 13, 75, 113, },
		[10] = { 14, 94, 142, },
		[11] = { 14, 118, 176, },
		[12] = { 15, 145, 218, },
		[13] = { 16, 179, 268, },
		[14] = { 16, 219, 329, },
		[15] = { 17, 254, 382, },
		[16] = { 18, 295, 442, },
		[17] = { 18, 341, 511, },
		[18] = { 19, 393, 590, },
		[19] = { 19, 453, 679, },
		[20] = { 19, 521, 781, },
		[21] = { 20, 572, 857, },
		[22] = { 21, 627, 940, },
		[23] = { 21, 687, 1030, },
		[24] = { 21, 752, 1128, },
		[25] = { 22, 823, 1235, },
		[26] = { 23, 900, 1351, },
		[27] = { 23, 985, 1477, },
		[28] = { 23, 1076, 1614, },
		[29] = { 24, 1176, 1764, },
		[30] = { 24, 1284, 1926, },
	},
}
gems["Frost Wall"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"wall_expand_delay_ms" = 150
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		--[3] = "wall_maximum_length"
		[4] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[5] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 14, 3, 28, 8, 12, },
		[2] = { 16, 3.1, 28, 9, 16, },
		[3] = { 18, 3.2, 28, 14, 23, },
		[4] = { 20, 3.3, 28, 18, 27, },
		[5] = { 21, 3.4, 35, 25, 37, },
		[6] = { 23, 3.5, 35, 32, 49, },
		[7] = { 24, 3.6, 35, 42, 63, },
		[8] = { 25, 3.7, 35, 54, 81, },
		[9] = { 26, 3.8, 42, 68, 102, },
		[10] = { 27, 3.9, 42, 85, 128, },
		[11] = { 28, 4, 42, 106, 159, },
		[12] = { 29, 4.1, 42, 131, 196, },
		[13] = { 30, 4.2, 49, 160, 240, },
		[14] = { 31, 4.3, 49, 196, 294, },
		[15] = { 32, 4.4, 49, 227, 341, },
		[16] = { 33, 4.5, 49, 263, 394, },
		[17] = { 34, 4.6, 56, 303, 455, },
		[18] = { 35, 4.7, 56, 350, 524, },
		[19] = { 36, 4.8, 56, 402, 603, },
		[20] = { 37, 4.9, 56, 462, 693, },
		[21] = { 38, 5, 63, 506, 759, },
		[22] = { 38, 5.1, 63, 554, 832, },
		[23] = { 38, 5.2, 63, 607, 910, },
		[24] = { 39, 5.3, 63, 664, 996, },
		[25] = { 40, 5.4, 70, 726, 1089, },
		[26] = { 40, 5.5, 70, 794, 1191, },
		[27] = { 41, 5.6, 70, 867, 1301, },
		[28] = { 42, 5.7, 70, 947, 1420, },
		[29] = { 42, 5.8, 77, 1033, 1550, },
		[30] = { 42, 5.9, 77, 1127, 1691, },
	},
}
gems["Frostbite"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("SelfFreezeDuration", "INC", 1, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_self_freeze_duration_-%" = -1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("ColdResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"base_cold_damage_resistance_%"
		[5] = mod("SelfFreezeChance", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"chance_to_be_frozen_%"
	},
	levels = {
		[1] = { 24, 9, 0, -25, 10, },
		[2] = { 26, 9.1, 4, -26, 10, },
		[3] = { 27, 9.2, 8, -27, 10, },
		[4] = { 29, 9.3, 12, -28, 10, },
		[5] = { 30, 9.4, 16, -29, 10, },
		[6] = { 32, 9.5, 20, -30, 11, },
		[7] = { 34, 9.6, 24, -31, 11, },
		[8] = { 35, 9.7, 28, -32, 11, },
		[9] = { 37, 9.8, 32, -33, 11, },
		[10] = { 38, 9.9, 36, -34, 11, },
		[11] = { 39, 10, 40, -35, 12, },
		[12] = { 40, 10.1, 44, -36, 12, },
		[13] = { 42, 10.2, 48, -37, 12, },
		[14] = { 43, 10.3, 52, -38, 12, },
		[15] = { 44, 10.4, 56, -39, 12, },
		[16] = { 45, 10.5, 60, -40, 13, },
		[17] = { 46, 10.6, 64, -41, 13, },
		[18] = { 47, 10.7, 68, -42, 13, },
		[19] = { 48, 10.8, 72, -43, 13, },
		[20] = { 50, 10.9, 76, -44, 14, },
		[21] = { 51, 11, 80, -45, 14, },
		[22] = { 52, 11.1, 84, -46, 14, },
		[23] = { 53, 11.2, 88, -47, 15, },
		[24] = { 54, 11.3, 92, -48, 15, },
		[25] = { 56, 11.4, 96, -49, 15, },
		[26] = { 57, 11.5, 100, -50, 16, },
		[27] = { 58, 11.6, 104, -51, 16, },
		[28] = { 59, 11.7, 108, -52, 16, },
		[29] = { 60, 11.8, 112, -53, 17, },
		[30] = { 61, 11.9, 116, -54, 17, },
	},
}
gems["Frostbolt"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		cold = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [17] = true, [18] = true, [19] = true, [26] = true, [34] = true, [36] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.75), 
		skill("critChance", 5), 
		--"base_is_projectile" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
	},
	qualityMods = {
		mod("ColdDamage", "INC", 1), --"cold_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 6, 6, 10, },
		[2] = { 6, 7, 11, },
		[3] = { 7, 9, 14, },
		[4] = { 8, 13, 19, },
		[5] = { 9, 18, 27, },
		[6] = { 10, 28, 42, },
		[7] = { 11, 38, 57, },
		[8] = { 12, 50, 75, },
		[9] = { 13, 66, 99, },
		[10] = { 14, 86, 128, },
		[11] = { 14, 110, 165, },
		[12] = { 15, 141, 211, },
		[13] = { 16, 178, 268, },
		[14] = { 16, 225, 338, },
		[15] = { 17, 283, 424, },
		[16] = { 18, 354, 530, },
		[17] = { 18, 440, 661, },
		[18] = { 19, 547, 820, },
		[19] = { 19, 642, 963, },
		[20] = { 20, 752, 1129, },
		[21] = { 20, 836, 1254, },
		[22] = { 21, 928, 1392, },
		[23] = { 21, 1030, 1544, },
		[24] = { 21, 1142, 1713, },
		[25] = { 22, 1266, 1898, },
		[26] = { 23, 1402, 2103, },
		[27] = { 23, 1552, 2329, },
		[28] = { 23, 1718, 2577, },
		[29] = { 24, 1901, 2851, },
		[30] = { 24, 2102, 3153, },
	},
}
gems["Glacial Cascade"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 5), 
		--"upheaval_number_of_spikes" = 7
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("PhysicalMin", nil), --"spell_minimum_base_physical_damage"
		[3] = skill("PhysicalMax", nil), --"spell_maximum_base_physical_damage"
		[4] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[5] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 13, 12, 19, 23, 35, },
		[2] = { 14, 15, 23, 28, 42, },
		[3] = { 15, 18, 27, 33, 50, },
		[4] = { 16, 21, 32, 39, 59, },
		[5] = { 17, 25, 38, 46, 69, },
		[6] = { 18, 27, 42, 51, 77, },
		[7] = { 18, 31, 47, 57, 85, },
		[8] = { 19, 34, 52, 63, 95, },
		[9] = { 19, 38, 58, 70, 105, },
		[10] = { 20, 42, 64, 77, 116, },
		[11] = { 21, 46, 71, 85, 129, },
		[12] = { 21, 51, 78, 94, 142, },
		[13] = { 22, 56, 86, 104, 157, },
		[14] = { 22, 62, 95, 115, 173, },
		[15] = { 23, 68, 105, 127, 191, },
		[16] = { 24, 75, 116, 139, 210, },
		[17] = { 24, 83, 127, 153, 231, },
		[18] = { 25, 91, 140, 169, 254, },
		[19] = { 25, 100, 154, 185, 280, },
		[20] = { 26, 110, 169, 203, 307, },
		[21] = { 27, 120, 185, 223, 337, },
		[22] = { 27, 132, 203, 245, 369, },
		[23] = { 28, 145, 223, 268, 405, },
		[24] = { 28, 158, 244, 294, 443, },
		[25] = { 29, 174, 267, 322, 485, },
		[26] = { 30, 190, 292, 352, 531, },
		[27] = { 30, 208, 319, 385, 581, },
		[28] = { 31, 227, 349, 421, 635, },
		[29] = { 31, 248, 382, 460, 694, },
		[30] = { 32, 271, 417, 502, 758, },
	},
}
gems["Herald of Thunder"] = {
	intelligence = true,
	active_skill = true,
	cast = true,
	area = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		cast = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [39] = true, [5] = true, [15] = true, [16] = true, [10] = true, [11] = true, [12] = true, [35] = true, [27] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("manaCost", 25), 
		skill("damageEffectiveness", 1.2), 
		skill("duration", 6), --"base_skill_effect_duration" = 6000
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		flag("CannotShock"), --"never_shock" = ?
		--"display_skill_deals_secondary_damage" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
	},
	qualityMods = {
		mod("LightningDamage", "INC", 0.75, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"herald_of_thunder_lightning_damage_+%" = 0.75
	},
	levelMods = {
		[1] = mod("LightningMin", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_minimum_added_lightning_damage"
		[2] = mod("LightningMax", "BASE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_maximum_added_lightning_damage"
		[3] = mod("LightningMin", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_minimum_added_lightning_damage"
		[4] = mod("LightningMax", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Buff" }), --"attack_maximum_added_lightning_damage"
		[5] = skill("LightningMin", nil), --"secondary_minimum_base_lightning_damage"
		[6] = skill("LightningMax", nil), --"secondary_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 2, 7, 2, 7, 1, 34, },
		[2] = { 2, 9, 2, 9, 1, 47, },
		[3] = { 3, 11, 3, 11, 1, 65, },
		[4] = { 3, 14, 3, 14, 2, 87, },
		[5] = { 4, 16, 4, 16, 2, 108, },
		[6] = { 5, 18, 5, 18, 3, 135, },
		[7] = { 5, 21, 5, 21, 3, 166, },
		[8] = { 6, 24, 6, 24, 4, 203, },
		[9] = { 7, 27, 7, 27, 5, 248, },
		[10] = { 8, 31, 8, 31, 6, 301, },
		[11] = { 9, 35, 9, 35, 8, 363, },
		[12] = { 10, 39, 10, 39, 9, 436, },
		[13] = { 11, 44, 11, 44, 11, 522, },
		[14] = { 12, 49, 12, 49, 13, 623, },
		[15] = { 13, 53, 13, 53, 15, 708, },
		[16] = { 14, 57, 14, 57, 17, 803, },
		[17] = { 15, 61, 15, 61, 19, 908, },
		[18] = { 16, 66, 16, 66, 21, 1026, },
		[19] = { 18, 71, 18, 71, 24, 1157, },
		[20] = { 19, 76, 19, 76, 27, 1303, },
		[21] = { 20, 81, 20, 81, 31, 1451, },
		[22] = { 22, 87, 22, 87, 34, 1615, },
		[23] = { 23, 94, 23, 94, 38, 1796, },
		[24] = { 25, 100, 25, 100, 43, 1995, },
		[25] = { 27, 107, 27, 107, 48, 2215, },
		[26] = { 29, 115, 29, 115, 54, 2457, },
		[27] = { 31, 123, 31, 123, 60, 2723, },
		[28] = { 33, 131, 33, 131, 67, 3016, },
		[29] = { 35, 140, 35, 140, 75, 3338, },
		[30] = { 37, 150, 37, 150, 83, 3692, },
	},
}
gems["Ice Nova"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.7), 
		skill("critChance", 6), 
		--"skill_art_variation" = 0
		--"is_area_damage" = 1
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 10, 15, 21, },
		[2] = { 11, 17, 27, },
		[3] = { 13, 24, 37, },
		[4] = { 14, 31, 49, },
		[5] = { 16, 41, 64, },
		[6] = { 17, 53, 83, },
		[7] = { 19, 68, 106, },
		[8] = { 20, 81, 127, },
		[9] = { 21, 96, 151, },
		[10] = { 22, 115, 179, },
		[11] = { 23, 136, 212, },
		[12] = { 24, 160, 250, },
		[13] = { 25, 188, 294, },
		[14] = { 26, 221, 346, },
		[15] = { 27, 259, 405, },
		[16] = { 28, 304, 474, },
		[17] = { 29, 337, 526, },
		[18] = { 30, 373, 583, },
		[19] = { 30, 413, 646, },
		[20] = { 31, 458, 715, },
		[21] = { 32, 506, 791, },
		[22] = { 33, 560, 875, },
		[23] = { 34, 619, 966, },
		[24] = { 34, 683, 1067, },
		[25] = { 34, 754, 1178, },
		[26] = { 34, 832, 1300, },
		[27] = { 35, 917, 1433, },
		[28] = { 35, 1011, 1580, },
		[29] = { 35, 1114, 1740, },
		[30] = { 35, 1227, 1917, },
	},
}
gems["Vaal Ice Nova"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	cold = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		cold = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [43] = true, [34] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.7), 
		skill("critChance", 6), 
		--"ice_nova_number_of_repeats" = 5
		--"ice_nova_radius_+%_per_repeat" = -20
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[2] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
	},
	levels = {
		[1] = { 11, 17, },
		[2] = { 14, 22, },
		[3] = { 18, 29, },
		[4] = { 24, 37, },
		[5] = { 31, 48, },
		[6] = { 39, 61, },
		[7] = { 49, 76, },
		[8] = { 57, 89, },
		[9] = { 67, 105, },
		[10] = { 78, 123, },
		[11] = { 91, 143, },
		[12] = { 106, 166, },
		[13] = { 123, 193, },
		[14] = { 143, 223, },
		[15] = { 164, 257, },
		[16] = { 189, 296, },
		[17] = { 208, 325, },
		[18] = { 228, 357, },
		[19] = { 250, 391, },
		[20] = { 274, 428, },
		[21] = { 300, 469, },
		[22] = { 328, 513, },
		[23] = { 359, 561, },
		[24] = { 393, 613, },
		[25] = { 429, 670, },
		[26] = { 468, 732, },
		[27] = { 511, 799, },
		[28] = { 558, 871, },
		[29] = { 608, 950, },
		[30] = { 663, 1035, },
	},
}
gems["Ice Spear"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	cold = true,
	parts = {
		{
			name = "First Form",
		},
		{
			name = "Second Form",
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		cold = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [34] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.85), 
		skill("damageEffectiveness", 0.8), 
		skill("critChance", 7), 
		--"base_is_projectile" = 1
		mod("CritChance", "INC", 600, 0, 0, { type = "SkillPart", skillPart = 2 }), --"ice_spear_second_form_critical_strike_chance_+%" = 600
		mod("PierceChance", "BASE", 100, 0, 0, { type = "SkillPart", skillPart = 1 }), 
	},
	qualityMods = {
		mod("ProjectileSpeed", "INC", 2), --"base_projectile_speed_+%" = 2
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		[4] = mod("EnemyChillDuration", "INC", nil), --"chill_duration_+%"
	},
	levels = {
		[1] = { 9, 17, 26, 40, },
		[2] = { 10, 21, 31, 42, },
		[3] = { 11, 28, 42, 44, },
		[4] = { 12, 36, 53, 46, },
		[5] = { 13, 47, 70, 48, },
		[6] = { 14, 61, 91, 50, },
		[7] = { 16, 78, 117, 52, },
		[8] = { 16, 94, 140, 54, },
		[9] = { 17, 112, 168, 56, },
		[10] = { 18, 133, 200, 58, },
		[11] = { 19, 158, 237, 60, },
		[12] = { 20, 187, 281, 62, },
		[13] = { 21, 221, 332, 64, },
		[14] = { 22, 261, 391, 66, },
		[15] = { 23, 307, 460, 68, },
		[16] = { 24, 360, 540, 70, },
		[17] = { 24, 400, 600, 72, },
		[18] = { 25, 445, 667, 74, },
		[19] = { 26, 494, 741, 76, },
		[20] = { 27, 548, 822, 78, },
		[21] = { 28, 607, 911, 80, },
		[22] = { 29, 673, 1009, 82, },
		[23] = { 29, 745, 1118, 84, },
		[24] = { 30, 825, 1237, 86, },
		[25] = { 30, 912, 1369, 88, },
		[26] = { 31, 1009, 1513, 90, },
		[27] = { 32, 1115, 1672, 92, },
		[28] = { 33, 1232, 1847, 94, },
		[29] = { 33, 1360, 2040, 96, },
		[30] = { 34, 1501, 2251, 98, },
	},
}
gems["Incinerate"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	fire = true,
	channelling = true,
	parts = {
		{
			name = "Base damage",
		},
		{
			name = "Fully charged",
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		fire = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [18] = true, [33] = true, [58] = true, },
	baseMods = {
		skill("castTime", 0.2), 
		skill("damageEffectiveness", 0.3), 
		--"flamethrower_damage_+%_per_stage_final" = 50
		--"base_is_projectile" = ?
		mod("PierceChance", "BASE", 100), --"always_pierce" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
		mod("Damage", "MORE", 150, ModFlag.Spell, 0, { type = "SkillPart", skillPart = 2 }), 
	},
	qualityMods = {
		mod("ProjectileSpeed", "INC", 2), --"base_projectile_speed_+%" = 2
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 6, 6, 9, },
		[2] = { 6, 7, 11, },
		[3] = { 6, 10, 15, },
		[4] = { 6, 13, 19, },
		[5] = { 6, 16, 24, },
		[6] = { 6, 20, 31, },
		[7] = { 6, 25, 38, },
		[8] = { 6, 30, 45, },
		[9] = { 7, 35, 52, },
		[10] = { 7, 41, 61, },
		[11] = { 7, 47, 71, },
		[12] = { 7, 54, 82, },
		[13] = { 7, 63, 94, },
		[14] = { 7, 72, 108, },
		[15] = { 8, 83, 125, },
		[16] = { 8, 95, 143, },
		[17] = { 8, 104, 157, },
		[18] = { 8, 114, 171, },
		[19] = { 8, 125, 187, },
		[20] = { 9, 136, 204, },
		[21] = { 9, 149, 223, },
		[22] = { 9, 162, 244, },
		[23] = { 9, 177, 266, },
		[24] = { 9, 193, 289, },
		[25] = { 9, 210, 315, },
		[26] = { 10, 229, 343, },
		[27] = { 10, 249, 374, },
		[28] = { 10, 271, 406, },
		[29] = { 10, 295, 442, },
		[30] = { 10, 320, 480, },
	},
}
gems["Kinetic Blast"] = {
	intelligence = true,
	active_skill = true,
	attack = true,
	area = true,
	projectile = true,
	parts = {
		{
			name = "Projectile",
			area = false,
		},
		{
			name = "Explosions",
			area = true,
		},
	},
	color = 3,
	baseFlags = {
		attack = true,
		projectile = true,
		area = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [6] = true, [11] = true, [17] = true, [19] = true, [22] = true, },
	weaponTypes = {
		["Wand"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"cluster_burst_spawn_amount" = 4
		mod("Damage", "MORE", -25, ModFlag.Area), --"active_skill_area_damage_+%_final" = -25
		--"base_is_projectile" = ?
		--"skill_can_fire_wand_projectiles" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 15, 20, 0, },
		[2] = { 15, 21.4, 1, },
		[3] = { 15, 22.8, 2, },
		[4] = { 15, 24.2, 3, },
		[5] = { 15, 25.6, 4, },
		[6] = { 15, 27, 5, },
		[7] = { 15, 28.4, 6, },
		[8] = { 15, 29.8, 7, },
		[9] = { 16, 31.2, 8, },
		[10] = { 16, 32.6, 9, },
		[11] = { 16, 34, 10, },
		[12] = { 16, 35.4, 11, },
		[13] = { 16, 36.8, 12, },
		[14] = { 16, 38.2, 13, },
		[15] = { 16, 39.6, 14, },
		[16] = { 16, 41, 15, },
		[17] = { 16, 42.4, 16, },
		[18] = { 16, 43.8, 17, },
		[19] = { 16, 45.2, 18, },
		[20] = { 16, 46.6, 19, },
		[21] = { 16, 48, 20, },
		[22] = { 16, 49.4, 21, },
		[23] = { 16, 50.8, 22, },
		[24] = { 16, 52.2, 23, },
		[25] = { 17, 53.6, 24, },
		[26] = { 17, 55, 25, },
		[27] = { 17, 56.4, 26, },
		[28] = { 17, 57.8, 27, },
		[29] = { 17, 59.2, 28, },
		[30] = { 17, 60.6, 29, },
	},
}
gems["Lightning Tendrils"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [18] = true, [26] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.8), 
		skill("damageEffectiveness", 0.35), 
		skill("critChance", 6), 
		--"base_skill_number_of_additional_hits" = 3
		--"is_area_damage" = ?
		skill("dpsMultiplier", 4), 
	},
	qualityMods = {
		mod("LightningDamage", "INC", 1), --"lightning_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		--[4] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 6, 1, 3, 0, },
		[2] = { 7, 1, 4, 0, },
		[3] = { 8, 1, 5, 1, },
		[4] = { 9, 1, 7, 1, },
		[5] = { 10, 1, 10, 1, },
		[6] = { 11, 1, 16, 2, },
		[7] = { 12, 1, 21, 2, },
		[8] = { 13, 1, 28, 2, },
		[9] = { 14, 2, 38, 3, },
		[10] = { 16, 3, 49, 3, },
		[11] = { 18, 3, 64, 3, },
		[12] = { 19, 4, 82, 4, },
		[13] = { 20, 6, 105, 4, },
		[14] = { 21, 7, 133, 4, },
		[15] = { 22, 9, 168, 5, },
		[16] = { 23, 11, 212, 5, },
		[17] = { 24, 14, 265, 5, },
		[18] = { 25, 17, 332, 6, },
		[19] = { 26, 21, 392, 6, },
		[20] = { 26, 24, 461, 6, },
		[21] = { 27, 27, 514, 7, },
		[22] = { 27, 30, 573, 7, },
		[23] = { 28, 34, 638, 7, },
		[24] = { 28, 37, 710, 8, },
		[25] = { 29, 42, 790, 8, },
		[26] = { 29, 46, 878, 8, },
		[27] = { 30, 51, 975, 9, },
		[28] = { 30, 57, 1083, 9, },
		[29] = { 31, 63, 1202, 9, },
		[30] = { 31, 70, 1334, 10, },
	},
}
gems["Lightning Trap"] = {
	projectile = true,
	trap = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		trap = true,
		projectile = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [3] = true, [37] = true, [19] = true, [12] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 0.9), 
		skill("critChance", 5), 
		--"base_trap_duration" = 16000
		mod("ProjectileCount", "BASE", 8), --"number_of_additional_projectiles" = 8
		--"projectiles_nova" = ?
		--"is_trap" = ?
		--"base_skill_is_trapped" = ?
		--"base_is_projectile" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		skill("trapCooldown", 2), 
	},
	qualityMods = {
		mod("TrapThrowingSpeed", "INC", 0.5), --"trap_throwing_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 8, 3, 62, },
		[2] = { 9, 4, 77, },
		[3] = { 10, 5, 98, },
		[4] = { 10, 7, 124, },
		[5] = { 11, 8, 153, },
		[6] = { 12, 10, 188, },
		[7] = { 13, 12, 228, },
		[8] = { 14, 14, 263, },
		[9] = { 14, 16, 301, },
		[10] = { 16, 18, 344, },
		[11] = { 17, 21, 391, },
		[12] = { 18, 23, 444, },
		[13] = { 19, 26, 503, },
		[14] = { 20, 30, 568, },
		[15] = { 21, 34, 640, },
		[16] = { 22, 38, 720, },
		[17] = { 22, 41, 779, },
		[18] = { 23, 44, 841, },
		[19] = { 24, 48, 907, },
		[20] = { 24, 52, 979, },
		[21] = { 25, 56, 1055, },
		[22] = { 26, 60, 1136, },
		[23] = { 26, 64, 1223, },
		[24] = { 27, 69, 1316, },
		[25] = { 27, 74, 1415, },
		[26] = { 28, 80, 1521, },
		[27] = { 29, 86, 1634, },
		[28] = { 30, 92, 1755, },
		[29] = { 30, 99, 1884, },
		[30] = { 30, 106, 2021, },
	},
}
gems["Vaal Lightning Trap"] = {
	projectile = true,
	trap = true,
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		trap = true,
		projectile = true,
		duration = true,
		lightning = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [3] = true, [37] = true, [19] = true, [12] = true, [43] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 0.9), 
		skill("critChance", 5), 
		--"base_trap_duration" = 16000
		mod("ProjectileCount", "BASE", 8), --"number_of_additional_projectiles" = 8
		skill("duration", 4), --"base_skill_effect_duration" = 4000
		mod("PierceChance", "BASE", 100), --"pierce_%" = 100
		--"projectiles_nova" = ?
		--"is_trap" = ?
		--"base_skill_is_trapped" = ?
		--"base_is_projectile" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
		--"lightning_trap_projectiles_leave_shocking_ground" = ?
	},
	qualityMods = {
		mod("TrapThrowingSpeed", "INC", 0.5), --"trap_throwing_speed_+%" = 0.5
	},
	levelMods = {
		[1] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[2] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 3, 62, },
		[2] = { 4, 77, },
		[3] = { 5, 98, },
		[4] = { 7, 124, },
		[5] = { 8, 153, },
		[6] = { 10, 188, },
		[7] = { 12, 228, },
		[8] = { 14, 263, },
		[9] = { 16, 301, },
		[10] = { 18, 344, },
		[11] = { 21, 391, },
		[12] = { 23, 444, },
		[13] = { 26, 503, },
		[14] = { 30, 568, },
		[15] = { 34, 640, },
		[16] = { 38, 720, },
		[17] = { 41, 779, },
		[18] = { 44, 841, },
		[19] = { 48, 907, },
		[20] = { 52, 979, },
		[21] = { 56, 1055, },
		[22] = { 60, 1136, },
		[23] = { 64, 1223, },
		[24] = { 69, 1316, },
		[25] = { 74, 1415, },
		[26] = { 80, 1521, },
		[27] = { 86, 1634, },
		[28] = { 92, 1755, },
		[29] = { 99, 1884, },
		[30] = { 106, 2021, },
	},
}
gems["Lightning Warp"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	movement = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		movement = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [36] = true, [38] = true, [45] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 5), 
		--"is_area_damage" = 1
		--"skill_override_pvp_scaling_time_ms" = 1000
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 1, ModFlag.Cast), --"base_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		[4] = mod("Duration", "INC", nil), --"skill_effect_duration_+%"
	},
	levels = {
		[1] = { 15, 1, 19, 0, },
		[2] = { 16, 1, 24, -2, },
		[3] = { 17, 2, 33, -4, },
		[4] = { 18, 2, 44, -6, },
		[5] = { 18, 3, 58, -8, },
		[6] = { 20, 4, 75, -10, },
		[7] = { 21, 5, 96, -12, },
		[8] = { 22, 6, 115, -14, },
		[9] = { 23, 7, 137, -16, },
		[10] = { 24, 9, 162, -18, },
		[11] = { 26, 10, 192, -20, },
		[12] = { 26, 12, 226, -22, },
		[13] = { 27, 14, 266, -24, },
		[14] = { 28, 16, 312, -26, },
		[15] = { 29, 19, 365, -28, },
		[16] = { 30, 22, 426, -30, },
		[17] = { 30, 26, 497, -32, },
		[18] = { 31, 30, 579, -34, },
		[19] = { 32, 34, 640, -36, },
		[20] = { 33, 37, 707, -38, },
		[21] = { 34, 41, 780, -40, },
		[22] = { 34, 45, 861, -42, },
		[23] = { 34, 50, 949, -44, },
		[24] = { 34, 55, 1046, -46, },
		[25] = { 35, 61, 1152, -48, },
		[26] = { 35, 67, 1269, -50, },
		[27] = { 36, 73, 1396, -52, },
		[28] = { 37, 81, 1536, -54, },
		[29] = { 37, 89, 1689, -56, },
		[30] = { 37, 98, 1856, -58, },
	},
}
gems["Vaal Lightning Warp"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		lightning = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [43] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 0.5), 
		skill("critChance", 5), 
		--"is_area_damage" = 1
		--"skill_override_pvp_scaling_time_ms" = 1000
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("Speed", "INC", 1, ModFlag.Cast), --"base_cast_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[2] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		[3] = mod("Duration", "INC", nil), --"skill_effect_duration_+%"
	},
	levels = {
		[1] = { 1, 18, 0, },
		[2] = { 1, 24, -2, },
		[3] = { 2, 32, -4, },
		[4] = { 2, 42, -6, },
		[5] = { 3, 54, -8, },
		[6] = { 4, 70, -10, },
		[7] = { 5, 88, -12, },
		[8] = { 5, 104, -14, },
		[9] = { 6, 123, -16, },
		[10] = { 8, 145, -18, },
		[11] = { 9, 170, -20, },
		[12] = { 10, 199, -22, },
		[13] = { 12, 232, -24, },
		[14] = { 14, 270, -26, },
		[15] = { 17, 314, -28, },
		[16] = { 19, 364, -30, },
		[17] = { 22, 420, -32, },
		[18] = { 26, 485, -34, },
		[19] = { 28, 534, -36, },
		[20] = { 31, 586, -38, },
		[21] = { 34, 644, -40, },
		[22] = { 37, 707, -42, },
		[23] = { 41, 775, -44, },
		[24] = { 45, 850, -46, },
		[25] = { 49, 931, -48, },
		[26] = { 54, 1019, -50, },
		[27] = { 59, 1116, -52, },
		[28] = { 64, 1221, -54, },
		[29] = { 70, 1335, -56, },
		[30] = { 77, 1459, -58, },
	},
}
gems["Magma Orb"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	chaining = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		area = true,
		chaining = true,
		fire = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [19] = true, [18] = true, [36] = true, [33] = true, [3] = true, [26] = true, [23] = true, },
	baseMods = {
		skill("castTime", 0.7), 
		skill("damageEffectiveness", 1.25), 
		skill("critChance", 5), 
		--"is_area_damage" = ?
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
		[4] = mod("ChainCount", "BASE", nil), --"number_of_additional_projectiles_in_chain"
	},
	levels = {
		[1] = { 5, 6, 9, 1, },
		[2] = { 6, 7, 10, 1, },
		[3] = { 6, 8, 12, 1, },
		[4] = { 7, 11, 17, 1, },
		[5] = { 7, 16, 24, 1, },
		[6] = { 8, 25, 37, 1, },
		[7] = { 9, 33, 50, 1, },
		[8] = { 10, 44, 66, 1, },
		[9] = { 11, 58, 87, 1, },
		[10] = { 12, 75, 112, 2, },
		[11] = { 13, 96, 144, 2, },
		[12] = { 14, 122, 183, 2, },
		[13] = { 15, 154, 232, 2, },
		[14] = { 16, 194, 291, 2, },
		[15] = { 18, 243, 365, 2, },
		[16] = { 19, 303, 454, 2, },
		[17] = { 20, 376, 564, 2, },
		[18] = { 21, 466, 698, 2, },
		[19] = { 21, 545, 818, 2, },
		[20] = { 22, 637, 956, 2, },
		[21] = { 23, 707, 1060, 3, },
		[22] = { 23, 784, 1175, 3, },
		[23] = { 24, 868, 1302, 3, },
		[24] = { 24, 961, 1442, 3, },
		[25] = { 25, 1063, 1595, 3, },
		[26] = { 26, 1176, 1764, 3, },
		[27] = { 26, 1300, 1950, 3, },
		[28] = { 27, 1437, 2155, 3, },
		[29] = { 27, 1587, 2380, 3, },
		[30] = { 28, 1752, 2628, 3, },
	},
}
gems["Orb of Storms"] = {
	lightning = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	area = true,
	chaining = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		chaining = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [35] = true, [12] = true, [11] = true, [23] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 0.2), 
		skill("critChance", 5), 
		skill("duration", 6), --"base_skill_effect_duration" = 6000
		mod("ChainCount", "BASE", 0), --"number_of_additional_projectiles_in_chain" = 0
		--"storm_cloud_charged_damage_+%_final" = 0
		--"skill_can_add_multiple_charges_per_action" = ?
	},
	qualityMods = {
		mod("LightningDamage", "INC", 1), --"lightning_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		--[4] = "projectile_number_to_split"
	},
	levels = {
		[1] = { 11, 1, 3, 2, },
		[2] = { 12, 1, 3, 2, },
		[3] = { 13, 1, 4, 2, },
		[4] = { 14, 2, 6, 2, },
		[5] = { 15, 3, 8, 2, },
		[6] = { 16, 3, 10, 2, },
		[7] = { 17, 4, 13, 2, },
		[8] = { 18, 6, 17, 2, },
		[9] = { 19, 7, 22, 3, },
		[10] = { 20, 10, 29, 3, },
		[11] = { 21, 12, 36, 3, },
		[12] = { 22, 15, 45, 3, },
		[13] = { 23, 19, 56, 3, },
		[14] = { 24, 23, 70, 3, },
		[15] = { 25, 27, 82, 3, },
		[16] = { 26, 32, 96, 3, },
		[17] = { 26, 37, 112, 4, },
		[18] = { 27, 44, 131, 4, },
		[19] = { 27, 51, 152, 4, },
		[20] = { 28, 59, 177, 4, },
		[21] = { 28, 65, 195, 4, },
		[22] = { 29, 72, 215, 4, },
		[23] = { 29, 79, 238, 4, },
		[24] = { 30, 87, 262, 4, },
		[25] = { 30, 96, 289, 5, },
		[26] = { 30, 106, 318, 5, },
		[27] = { 30, 117, 350, 5, },
		[28] = { 31, 128, 385, 5, },
		[29] = { 31, 141, 424, 5, },
		[30] = { 32, 155, 466, 5, },
	},
}
gems["Power Siphon"] = {
	intelligence = true,
	active_skill = true,
	attack = true,
	projectile = true,
	color = 3,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [6] = true, [3] = true, [22] = true, [17] = true, [19] = true, },
	weaponTypes = {
		["Wand"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"kill_enemy_on_hit_if_under_10%_life" = ?
		--"skill_can_fire_wand_projectiles" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 13, 30, },
		[2] = { 13, 31.6, },
		[3] = { 13, 33.2, },
		[4] = { 13, 34.8, },
		[5] = { 13, 36.4, },
		[6] = { 13, 38, },
		[7] = { 13, 39.6, },
		[8] = { 14, 41.2, },
		[9] = { 14, 42.8, },
		[10] = { 14, 44.4, },
		[11] = { 14, 46, },
		[12] = { 14, 47.6, },
		[13] = { 14, 49.2, },
		[14] = { 14, 50.8, },
		[15] = { 14, 52.4, },
		[16] = { 14, 54, },
		[17] = { 14, 55.6, },
		[18] = { 14, 57.2, },
		[19] = { 15, 58.8, },
		[20] = { 15, 60.4, },
		[21] = { 15, 62, },
		[22] = { 15, 63.6, },
		[23] = { 15, 65.2, },
		[24] = { 15, 66.8, },
		[25] = { 15, 68.4, },
		[26] = { 16, 70, },
		[27] = { 16, 71.6, },
		[28] = { 16, 73.2, },
		[29] = { 16, 74.8, },
		[30] = { 16, 76.4, },
	},
}
gems["Vaal Power Siphon"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	attack = true,
	projectile = true,
	color = 3,
	baseFlags = {
		attack = true,
		projectile = true,
		vaal = true,
	},
	skillTypes = { [1] = true, [48] = true, [6] = true, [3] = true, [22] = true, [17] = true, [19] = true, [43] = true, },
	weaponTypes = {
		["Wand"] = true,
	},
	baseMods = {
		skill("castTime", 1), 
		--"power_siphon_fire_at_all_targets" = ?
		--"skill_can_add_multiple_charges_per_action" = ?
		skill("cannotBeEvaded", true), --"global_always_hit" = ?
		--"kill_enemy_on_hit_if_under_10%_life" = ?
		--"skill_can_fire_wand_projectiles" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, 0, 0, nil), --"damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Attack), 
	},
	levels = {
		[1] = { 25, },
		[2] = { 26.6, },
		[3] = { 28.2, },
		[4] = { 29.8, },
		[5] = { 31.4, },
		[6] = { 33, },
		[7] = { 34.6, },
		[8] = { 36.2, },
		[9] = { 37.8, },
		[10] = { 39.4, },
		[11] = { 41, },
		[12] = { 42.6, },
		[13] = { 44.2, },
		[14] = { 45.8, },
		[15] = { 47.4, },
		[16] = { 49, },
		[17] = { 50.6, },
		[18] = { 52.2, },
		[19] = { 53.8, },
		[20] = { 55.4, },
		[21] = { 57, },
		[22] = { 58.6, },
		[23] = { 60.2, },
		[24] = { 61.8, },
		[25] = { 63.4, },
		[26] = { 65, },
		[27] = { 66.6, },
		[28] = { 68.2, },
		[29] = { 69.8, },
		[30] = { 71.4, },
	},
}
gems["Purity of Elements"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	color = 3,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 35), 
		mod("FireResistMax", "BASE", 0, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_fire_damage_resistance_%" = 0
		mod("ColdResistMax", "BASE", 0, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_cold_damage_resistance_%" = 0
		mod("LightningResistMax", "BASE", 0, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_lightning_damage_resistance_%" = 0
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("ElementalResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_resist_all_elements_%"
		[2] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 12, 0, },
		[2] = { 13, 3, },
		[3] = { 14, 6, },
		[4] = { 15, 9, },
		[5] = { 15, 12, },
		[6] = { 16, 15, },
		[7] = { 17, 18, },
		[8] = { 18, 21, },
		[9] = { 19, 23, },
		[10] = { 20, 25, },
		[11] = { 20, 27, },
		[12] = { 21, 29, },
		[13] = { 22, 31, },
		[14] = { 23, 33, },
		[15] = { 24, 35, },
		[16] = { 25, 36, },
		[17] = { 25, 37, },
		[18] = { 26, 38, },
		[19] = { 27, 39, },
		[20] = { 27, 40, },
		[21] = { 28, 41, },
		[22] = { 29, 42, },
		[23] = { 29, 43, },
		[24] = { 30, 44, },
		[25] = { 31, 45, },
		[26] = { 31, 46, },
		[27] = { 32, 47, },
		[28] = { 33, 48, },
		[29] = { 33, 49, },
		[30] = { 34, 50, },
	},
}
gems["Purity of Lightning"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 35), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("LightningResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_lightning_damage_resistance_%"
		[2] = mod("LightningResistMax", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura" }), --"base_maximum_lightning_damage_resistance_%"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
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
gems["Raise Spectre"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	minion = true,
	unsupported = true,
}
gems["Raise Zombie"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	minion = true,
	unsupported = true,
}
gems["Righteous Fire"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	fire = true,
	setupFunc = function(env, output)
		if env.mainSkill.skillFlags.totem then
			env.mainSkill.skillData.FireDot = output.TotemLife * 0.5
		else
			env.mainSkill.skillData.FireDot = (output.Life + output.EnergyShield) * 0.5
		end
	end,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [5] = true, [11] = true, [18] = true, [29] = true, [36] = true, [40] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_righteous_fire_%_of_max_life_to_deal_to_nearby_per_minute" = 3000
		--"base_nonlethal_fire_damage_%_of_maximum_life_taken_per_minute" = 5400
		--"base_righteous_fire_%_of_max_energy_shield_to_deal_to_nearby_per_minute" = 3000
		--"base_nonlethal_fire_damage_%_of_maximum_energy_shield_taken_per_minute" = 4200
	},
	qualityMods = {
		mod("Damage", "INC", 1, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"spell_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Buff" }), --"righteous_fire_spell_damage_+%_final"
		--[2] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 40, 0, },
		[2] = { 41, 0, },
		[3] = { 42, 0, },
		[4] = { 43, 1, },
		[5] = { 44, 1, },
		[6] = { 45, 1, },
		[7] = { 46, 1, },
		[8] = { 47, 2, },
		[9] = { 48, 2, },
		[10] = { 49, 2, },
		[11] = { 50, 2, },
		[12] = { 51, 3, },
		[13] = { 52, 3, },
		[14] = { 53, 3, },
		[15] = { 54, 3, },
		[16] = { 55, 4, },
		[17] = { 56, 4, },
		[18] = { 57, 4, },
		[19] = { 58, 4, },
		[20] = { 59, 5, },
		[21] = { 60, 5, },
		[22] = { 61, 5, },
		[23] = { 62, 5, },
		[24] = { 63, 6, },
		[25] = { 64, 6, },
		[26] = { 65, 6, },
		[27] = { 66, 6, },
		[28] = { 67, 7, },
		[29] = { 68, 7, },
		[30] = { 69, 7, },
	},
}
gems["Vaal Righteous Fire"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	fire = true,
	setupFunc = function(env, output)
		env.mainSkill.skillData.FireMin = output.EnergyShield + output.Life - 1
		env.mainSkill.skillData.FireMax = output.EnergyShield + output.Life - 1
	end,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [11] = true, [10] = true, [43] = true, [33] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 5), 
		--"damage_cannot_be_reflected" = ?
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("Damage", "INC", 1, ModFlag.Spell, 0, nil), --"spell_damage_+%" = 1
	},
	levelMods = {
		[1] = mod("Damage", "MORE", nil, ModFlag.Hit), --"active_skill_damage_+%_final"
	},
	levels = {
		[1] = { 20, },
		[2] = { 21, },
		[3] = { 22, },
		[4] = { 23, },
		[5] = { 24, },
		[6] = { 25, },
		[7] = { 26, },
		[8] = { 27, },
		[9] = { 28, },
		[10] = { 29, },
		[11] = { 30, },
		[12] = { 31, },
		[13] = { 32, },
		[14] = { 33, },
		[15] = { 34, },
		[16] = { 35, },
		[17] = { 36, },
		[18] = { 37, },
		[19] = { 38, },
		[20] = { 39, },
		[21] = { 40, },
		[22] = { 41, },
		[23] = { 42, },
		[24] = { 43, },
		[25] = { 44, },
		[26] = { 45, },
		[27] = { 46, },
		[28] = { 47, },
		[29] = { 48, },
		[30] = { 49, },
	},
}
gems["Scorching Ray"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	fire = true,
	duration = true,
	channelling = true,
	parts = {
		{
			name = "1 Stage",
		},
		{
			name = "4 Stages",
		},
		{
			name = "8 Stages",
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
		fire = true,
	},
	skillTypes = { [2] = true, [18] = true, [40] = true, [33] = true, [29] = true, [12] = true, [58] = true, [59] = true, [52] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		--"fire_beam_additional_stack_damage_+%_final" = -40
		--"display_max_fire_beam_stacks" = 8
		mod("FireResist", "BASE", -3, 0, 0, { type = "GlobalEffect", effectType = "Debuff" }), --"fire_beam_enemy_fire_resistance_%_per_stack" = -3
		--"fire_beam_enemy_fire_resistance_%_maximum" = -24
		skill("dotIsSpell", true), --"spell_damage_modifiers_apply_to_damage_over_time" = ?
		skill("stackCount", 4, { type = "SkillPart", skillPart = 2 }), 
		skill("stackCount", 8, { type = "SkillPart", skillPart = 3 }), 
		mod("Damage", "MORE", 180, 0, 0, { type = "SkillPart", skillPart = 2 }), 
		mod("Damage", "MORE", 420, 0, 0, { type = "SkillPart", skillPart = 3 }), 
	},
	qualityMods = {
		--"fire_beam_length_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("FireDot", nil), --"base_fire_damage_to_deal_per_minute"
	},
	levels = {
		[1] = { 4, 9.6833333333333, },
		[2] = { 4, 12.65, },
		[3] = { 4, 17.683333333333, },
		[4] = { 5, 24.233333333333, },
		[5] = { 5, 32.716666666667, },
		[6] = { 5, 43.666666666667, },
		[7] = { 6, 57.7, },
		[8] = { 6, 70.75, },
		[9] = { 6, 86.4, },
		[10] = { 7, 105.13333333333, },
		[11] = { 7, 127.55, },
		[12] = { 7, 154.3, },
		[13] = { 8, 186.2, },
		[14] = { 8, 224.16666666667, },
		[15] = { 8, 269.33333333333, },
		[16] = { 9, 322.96666666667, },
		[17] = { 9, 364.18333333333, },
		[18] = { 9, 410.36666666667, },
		[19] = { 10, 462.06666666667, },
		[20] = { 10, 519.93333333333, },
		[21] = { 10, 584.7, },
		[22] = { 11, 657.13333333333, },
		[23] = { 11, 738.1, },
		[24] = { 11, 828.61666666667, },
		[25] = { 12, 929.73333333333, },
		[26] = { 12, 1042.6833333333, },
		[27] = { 12, 1168.8, },
		[28] = { 13, 1309.5833333333, },
		[29] = { 13, 1466.6666666667, },
		[30] = { 13, 1641.9166666667, },
	},
}
gems["Shock Nova"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	lightning = true,
	parts = {
		{
			name = "Ring",
		},
		{
			name = "Nova",
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [45] = true, [35] = true, [43] = true, },
	baseMods = {
		skill("castTime", 0.75), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 6), 
		mod("Damage", "MORE", -80, 0, 0, { type = "SkillPart", skillPart = 1 }), --"newshocknova_first_ring_damage_+%_final" = -80
		mod("EnemyShockChance", "BASE", 20), --"base_chance_to_shock_%" = 20
		--"is_area_damage" = ?
	},
	qualityMods = {
		mod("EnemyShockDuration", "INC", 2), --"shock_duration_+%" = 2
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 13, 26, 79, },
		[2] = { 14, 32, 95, },
		[3] = { 15, 38, 115, },
		[4] = { 16, 46, 137, },
		[5] = { 17, 55, 164, },
		[6] = { 18, 61, 184, },
		[7] = { 18, 69, 206, },
		[8] = { 19, 77, 231, },
		[9] = { 19, 86, 258, },
		[10] = { 20, 96, 288, },
		[11] = { 20, 107, 321, },
		[12] = { 21, 119, 358, },
		[13] = { 22, 133, 399, },
		[14] = { 22, 148, 443, },
		[15] = { 23, 164, 493, },
		[16] = { 23, 182, 547, },
		[17] = { 24, 202, 607, },
		[18] = { 25, 224, 673, },
		[19] = { 25, 248, 745, },
		[20] = { 26, 275, 825, },
		[21] = { 26, 304, 913, },
		[22] = { 27, 336, 1009, },
		[23] = { 28, 372, 1115, },
		[24] = { 28, 411, 1232, },
		[25] = { 29, 453, 1360, },
		[26] = { 29, 500, 1501, },
		[27] = { 30, 552, 1655, },
		[28] = { 31, 608, 1824, },
		[29] = { 31, 670, 2010, },
		[30] = { 32, 738, 2214, },
	},
}
gems["Spark"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [45] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.65), 
		skill("damageEffectiveness", 0.7), 
		skill("critChance", 6), 
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("ProjectileSpeed", "INC", 1), --"base_projectile_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		[4] = mod("ProjectileCount", "BASE", nil), --"number_of_additional_projectiles"
	},
	levels = {
		[1] = { 5, 1, 20, 4, },
		[2] = { 6, 1, 22, 4, },
		[3] = { 7, 1, 27, 4, },
		[4] = { 8, 2, 36, 4, },
		[5] = { 9, 3, 49, 4, },
		[6] = { 10, 4, 69, 4, },
		[7] = { 11, 5, 88, 4, },
		[8] = { 12, 6, 110, 4, },
		[9] = { 14, 7, 136, 5, },
		[10] = { 16, 9, 167, 5, },
		[11] = { 17, 11, 202, 5, },
		[12] = { 18, 13, 243, 5, },
		[13] = { 19, 15, 291, 5, },
		[14] = { 20, 18, 345, 5, },
		[15] = { 21, 22, 409, 5, },
		[16] = { 22, 25, 481, 5, },
		[17] = { 22, 30, 565, 6, },
		[18] = { 22, 35, 661, 6, },
		[19] = { 22, 39, 742, 6, },
		[20] = { 23, 44, 832, 6, },
		[21] = { 23, 47, 897, 6, },
		[22] = { 24, 51, 967, 6, },
		[23] = { 24, 55, 1041, 6, },
		[24] = { 25, 59, 1120, 6, },
		[25] = { 25, 63, 1205, 7, },
		[26] = { 26, 68, 1296, 7, },
		[27] = { 26, 73, 1393, 7, },
		[28] = { 26, 79, 1496, 7, },
		[29] = { 26, 85, 1607, 7, },
		[30] = { 27, 91, 1725, 7, },
	},
}
gems["Vaal Spark"] = {
	projectile = true,
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		projectile = true,
		duration = true,
		lightning = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [3] = true, [10] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [43] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.65), 
		skill("damageEffectiveness", 0.4), 
		skill("critChance", 5), 
		skill("duration", 2), --"base_skill_effect_duration" = 2000
		--"base_number_of_projectiles_in_spiral_nova" = 100
		--"projectile_spiral_nova_time_ms" = 3000
		--"projectile_spiral_nova_angle" = 0
		--"base_is_projectile" = ?
	},
	qualityMods = {
		mod("ProjectileSpeed", "INC", 1), --"base_projectile_speed_+%" = 1
	},
	levelMods = {
		[1] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[2] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 1, 11, },
		[2] = { 1, 12, },
		[3] = { 1, 15, },
		[4] = { 1, 19, },
		[5] = { 1, 27, },
		[6] = { 2, 37, },
		[7] = { 3, 48, },
		[8] = { 3, 60, },
		[9] = { 4, 74, },
		[10] = { 5, 91, },
		[11] = { 6, 110, },
		[12] = { 7, 133, },
		[13] = { 8, 159, },
		[14] = { 10, 188, },
		[15] = { 12, 223, },
		[16] = { 14, 263, },
		[17] = { 16, 308, },
		[18] = { 19, 361, },
		[19] = { 21, 405, },
		[20] = { 24, 454, },
		[21] = { 26, 489, },
		[22] = { 28, 527, },
		[23] = { 30, 568, },
		[24] = { 32, 611, },
		[25] = { 35, 658, },
		[26] = { 37, 707, },
		[27] = { 40, 760, },
		[28] = { 43, 816, },
		[29] = { 46, 877, },
		[30] = { 50, 941, },
	},
}
gems["Spirit Offering"] = {
	minion = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [5] = true, [12] = true, [36] = true, [9] = true, [49] = true, [17] = true, [19] = true, [18] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"offering_skill_effect_duration_per_corpse" = 500
		--"spirit_offering_life_%_added_as_base_maximum_energy_shield_per_corpse_consumed" = 2
		--"base_deal_no_damage" = ?
		skill("offering", true), 
	},
	qualityMods = {
		mod("Duration", "INC", 0.5), --"skill_effect_duration_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("PhysicalDamageGainAsChaos", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"physical_damage_%_to_add_as_chaos"
		[3] = mod("ElementalResist", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"base_resist_all_elements_%"
	},
	levels = {
		[1] = { 16, 20, 20, },
		[2] = { 17, 20, 21, },
		[3] = { 18, 21, 21, },
		[4] = { 19, 21, 22, },
		[5] = { 20, 22, 22, },
		[6] = { 21, 22, 23, },
		[7] = { 22, 23, 23, },
		[8] = { 23, 23, 24, },
		[9] = { 24, 24, 24, },
		[10] = { 25, 24, 25, },
		[11] = { 26, 25, 25, },
		[12] = { 27, 25, 26, },
		[13] = { 28, 26, 26, },
		[14] = { 29, 26, 27, },
		[15] = { 29, 27, 27, },
		[16] = { 30, 27, 28, },
		[17] = { 30, 28, 28, },
		[18] = { 31, 28, 29, },
		[19] = { 32, 29, 29, },
		[20] = { 33, 29, 30, },
		[21] = { 34, 30, 30, },
		[22] = { 34, 30, 31, },
		[23] = { 35, 31, 31, },
		[24] = { 36, 31, 32, },
		[25] = { 37, 32, 32, },
		[26] = { 38, 32, 33, },
		[27] = { 38, 33, 33, },
		[28] = { 39, 33, 34, },
		[29] = { 40, 34, 34, },
		[30] = { 41, 34, 35, },
	},
}
gems["Storm Call"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [36] = true, [26] = true, [45] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 0.8), 
		skill("critChance", 6), 
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
		--[4] = "active_skill_base_radius_+"
	},
	levels = {
		[1] = { 6, 13, 24, 0, },
		[2] = { 7, 16, 30, 0, },
		[3] = { 8, 22, 40, 1, },
		[4] = { 9, 28, 53, 1, },
		[5] = { 10, 37, 68, 1, },
		[6] = { 11, 46, 86, 2, },
		[7] = { 12, 58, 108, 2, },
		[8] = { 13, 69, 128, 2, },
		[9] = { 13, 81, 151, 3, },
		[10] = { 14, 95, 177, 3, },
		[11] = { 14, 111, 206, 3, },
		[12] = { 15, 130, 241, 4, },
		[13] = { 16, 151, 280, 4, },
		[14] = { 16, 175, 325, 4, },
		[15] = { 17, 202, 376, 5, },
		[16] = { 18, 234, 434, 5, },
		[17] = { 18, 257, 478, 5, },
		[18] = { 19, 283, 525, 6, },
		[19] = { 19, 310, 577, 6, },
		[20] = { 19, 341, 633, 6, },
		[21] = { 20, 374, 694, 7, },
		[22] = { 21, 410, 761, 7, },
		[23] = { 21, 449, 834, 7, },
		[24] = { 21, 492, 914, 8, },
		[25] = { 22, 538, 1000, 8, },
		[26] = { 23, 589, 1094, 8, },
		[27] = { 23, 644, 1196, 9, },
		[28] = { 23, 704, 1308, 9, },
		[29] = { 24, 769, 1429, 9, },
		[30] = { 24, 840, 1560, 10, },
	},
}
gems["Vaal Storm Call"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	area = true,
	duration = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		lightning = true,
		vaal = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [43] = true, [35] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 0.8), 
		skill("critChance", 6), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"is_area_damage" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[2] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 13, 25, },
		[2] = { 17, 31, },
		[3] = { 22, 41, },
		[4] = { 29, 53, },
		[5] = { 36, 67, },
		[6] = { 46, 85, },
		[7] = { 57, 105, },
		[8] = { 67, 124, },
		[9] = { 78, 144, },
		[10] = { 90, 168, },
		[11] = { 105, 194, },
		[12] = { 121, 225, },
		[13] = { 140, 259, },
		[14] = { 161, 298, },
		[15] = { 184, 343, },
		[16] = { 211, 393, },
		[17] = { 231, 429, },
		[18] = { 253, 470, },
		[19] = { 276, 513, },
		[20] = { 302, 560, },
		[21] = { 329, 611, },
		[22] = { 359, 666, },
		[23] = { 391, 726, },
		[24] = { 426, 791, },
		[25] = { 464, 861, },
		[26] = { 504, 937, },
		[27] = { 549, 1019, },
		[28] = { 596, 1108, },
		[29] = { 648, 1204, },
		[30] = { 704, 1307, },
	},
}
gems["Summon Chaos Golem"] = {
	intelligence = true,
	active_skill = true,
	chaos = true,
	minion = true,
	spell = true,
	golem = true,
	color = 3,
	baseFlags = {
		spell = true,
		minion = true,
		golem = true,
		chaos = true,
	},
	skillTypes = { [36] = true, [50] = true, [19] = true, [9] = true, [21] = true, [26] = true, [2] = true, [18] = true, [17] = true, [49] = true, [62] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_number_of_golems_allowed" = 1
		--"display_minion_monster_type" = 5
		mod("Misc", "LIST", { type = "Condition", var = "HaveChaosGolem" }, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), 
	},
	qualityMods = {
		mod("MinionLife", "INC", 1), --"minion_maximum_life_+%" = 1
		mod("Damage", "INC", 1, 0, KeywordFlag.Minion), --"minion_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "base_actor_scale_+%"
		--[3] = "chaos_golem_grants_additional_physical_damage_reduction_%"
		[4] = mod("MinionLife", "INC", nil), --"minion_maximum_life_+%"
		--[5] = "display_minion_monster_level"
	},
	levels = {
		[1] = { 30, 0, 3, 30, 34, },
		[2] = { 32, 1, 3, 32, 36, },
		[3] = { 34, 1, 3, 34, 38, },
		[4] = { 36, 2, 3, 36, 40, },
		[5] = { 38, 2, 3, 38, 42, },
		[6] = { 40, 3, 3, 40, 44, },
		[7] = { 42, 3, 3, 42, 46, },
		[8] = { 44, 4, 3, 44, 48, },
		[9] = { 44, 4, 3, 46, 50, },
		[10] = { 46, 5, 3, 48, 52, },
		[11] = { 48, 5, 3, 50, 54, },
		[12] = { 48, 6, 4, 52, 56, },
		[13] = { 50, 6, 4, 54, 58, },
		[14] = { 50, 7, 4, 56, 60, },
		[15] = { 52, 7, 4, 58, 62, },
		[16] = { 52, 8, 4, 60, 64, },
		[17] = { 52, 8, 4, 62, 66, },
		[18] = { 52, 9, 4, 64, 68, },
		[19] = { 54, 9, 4, 66, 69, },
		[20] = { 54, 10, 4, 68, 70, },
		[21] = { 56, 10, 4, 70, 72, },
		[22] = { 56, 11, 5, 72, 74, },
		[23] = { 58, 11, 5, 74, 76, },
		[24] = { 58, 12, 5, 76, 78, },
		[25] = { 60, 12, 5, 78, 80, },
		[26] = { 60, 13, 5, 80, 82, },
		[27] = { 60, 13, 5, 82, 84, },
		[28] = { 60, 14, 5, 84, 86, },
		[29] = { 62, 14, 5, 86, 88, },
		[30] = { 62, 15, 5, 88, 90, },
	},
}
gems["Summon Lightning Golem"] = {
	intelligence = true,
	active_skill = true,
	lightning = true,
	minion = true,
	spell = true,
	golem = true,
	color = 3,
	baseFlags = {
		spell = true,
		minion = true,
		golem = true,
		lightning = true,
	},
	skillTypes = { [36] = true, [35] = true, [19] = true, [9] = true, [21] = true, [26] = true, [2] = true, [18] = true, [17] = true, [49] = true, [45] = true, [62] = true, },
	baseMods = {
		skill("castTime", 1), 
		--"base_number_of_golems_allowed" = 1
		--"display_minion_monster_type" = 11
		mod("Misc", "LIST", { type = "Condition", var = "HaveLightningGolem" }, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), 
	},
	qualityMods = {
		mod("MinionLife", "INC", 1), --"minion_maximum_life_+%" = 1
		mod("Damage", "INC", 1, 0, KeywordFlag.Minion), --"minion_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		--[2] = "base_actor_scale_+%"
		[3] = mod("Speed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"lightning_golem_grants_attack_and_cast_speed_+%"
		[4] = mod("MinionLife", "INC", nil), --"minion_maximum_life_+%"
		--[5] = "display_minion_monster_level"
	},
	levels = {
		[1] = { 30, 0, 6, 30, 34, },
		[2] = { 32, 1, 6, 32, 36, },
		[3] = { 34, 2, 6, 34, 38, },
		[4] = { 36, 3, 6, 36, 40, },
		[5] = { 38, 4, 6, 38, 42, },
		[6] = { 40, 5, 7, 40, 44, },
		[7] = { 42, 6, 7, 42, 46, },
		[8] = { 44, 7, 7, 44, 48, },
		[9] = { 44, 8, 7, 46, 50, },
		[10] = { 46, 9, 7, 48, 52, },
		[11] = { 48, 10, 8, 50, 54, },
		[12] = { 48, 11, 8, 52, 56, },
		[13] = { 50, 12, 8, 54, 58, },
		[14] = { 50, 13, 8, 56, 60, },
		[15] = { 52, 14, 8, 58, 62, },
		[16] = { 52, 15, 9, 60, 64, },
		[17] = { 52, 16, 9, 62, 66, },
		[18] = { 52, 17, 9, 64, 68, },
		[19] = { 54, 18, 9, 66, 69, },
		[20] = { 54, 19, 9, 68, 70, },
		[21] = { 56, 20, 10, 70, 72, },
		[22] = { 56, 21, 10, 72, 74, },
		[23] = { 58, 22, 10, 74, 76, },
		[24] = { 58, 23, 10, 76, 78, },
		[25] = { 60, 24, 10, 78, 80, },
		[26] = { 60, 25, 11, 80, 82, },
		[27] = { 60, 26, 11, 82, 84, },
		[28] = { 60, 27, 11, 84, 86, },
		[29] = { 62, 28, 11, 86, 88, },
		[30] = { 62, 29, 11, 88, 90, },
	},
}
gems["Summon Raging Spirit"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	minion = true,
	duration = true,
	fire = true,
	unsupported = true,
}
gems["Summon Skeletons"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	minion = true,
	duration = true,
	unsupported = true,
}
gems["Vaal Summon Skeletons"] = {
	intelligence = true,
	active_skill = true,
	vaal = true,
	spell = true,
	minion = true,
	duration = true,
	unsupported = true,
}
gems["Tempest Shield"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	lightning = true,
	chaining = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		duration = true,
		chaining = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [10] = true, [13] = true, [27] = true, [35] = true, [23] = true, [45] = true, [36] = true, [12] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		skill("damageEffectiveness", 0.6), 
		skill("critChance", 6), 
		mod("BlockChance", "BASE", 3, 0, 0, { type = "GlobalEffect", effectType = "Buff" }), --"shield_block_%" = 3
		--"skill_override_pvp_scaling_time_ms" = 700
		mod("ChainCount", "BASE", 1), --"number_of_additional_projectiles_in_chain" = 1
		skill("duration", 12), --"base_skill_effect_duration" = 12000
		--"skill_can_add_multiple_charges_per_action" = ?
		skill("showAverage", true), --"base_skill_show_average_damage_instead_of_dps" = ?
	},
	qualityMods = {
		mod("LightningDamage", "INC", 1), --"lightning_damage_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 17, 24, 36, },
		[2] = { 17, 31, 46, },
		[3] = { 17, 39, 58, },
		[4] = { 18, 48, 72, },
		[5] = { 18, 55, 83, },
		[6] = { 18, 64, 96, },
		[7] = { 18, 74, 111, },
		[8] = { 19, 85, 127, },
		[9] = { 19, 97, 145, },
		[10] = { 19, 110, 165, },
		[11] = { 20, 125, 187, },
		[12] = { 20, 141, 212, },
		[13] = { 20, 159, 239, },
		[14] = { 20, 180, 269, },
		[15] = { 20, 194, 291, },
		[16] = { 21, 210, 315, },
		[17] = { 21, 227, 340, },
		[18] = { 21, 245, 367, },
		[19] = { 21, 264, 396, },
		[20] = { 21, 284, 426, },
		[21] = { 22, 306, 459, },
		[22] = { 22, 330, 494, },
		[23] = { 22, 354, 532, },
		[24] = { 22, 381, 572, },
		[25] = { 22, 410, 614, },
		[26] = { 23, 440, 660, },
		[27] = { 23, 472, 708, },
		[28] = { 23, 507, 760, },
		[29] = { 23, 543, 815, },
		[30] = { 23, 583, 874, },
	},
}
gems["Vortex"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	cold = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		cold = true,
	},
	skillTypes = { [2] = true, [10] = true, [11] = true, [17] = true, [18] = true, [19] = true, [26] = true, [34] = true, [36] = true, [12] = true, [60] = true, },
	baseMods = {
		skill("castTime", 0.9), 
		skill("critChance", 5), 
		skill("duration", 3), --"base_skill_effect_duration" = 3000
		--"is_area_damage" = ?
		skill("dotIsSpell", true), --"spell_damage_modifiers_apply_to_damage_over_time" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 0.5), --"base_skill_area_of_effect_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("ColdMin", nil), --"spell_minimum_base_cold_damage"
		[3] = skill("ColdMax", nil), --"spell_maximum_base_cold_damage"
		[4] = skill("ColdDot", nil), --"base_cold_damage_to_deal_per_minute"
	},
	levels = {
		[1] = { 11, 50, 75, 41.633333333333, },
		[2] = { 11, 60, 90, 51.983333333333, },
		[3] = { 12, 71, 107, 64.466666666667, },
		[4] = { 13, 85, 127, 79.45, },
		[5] = { 14, 100, 150, 97.383333333333, },
		[6] = { 14, 112, 168, 112.51666666667, },
		[7] = { 15, 124, 187, 129.65, },
		[8] = { 15, 138, 208, 149.01666666667, },
		[9] = { 16, 154, 231, 170.88333333333, },
		[10] = { 16, 171, 256, 195.53333333333, },
		[11] = { 16, 189, 284, 223.28333333333, },
		[12] = { 17, 209, 314, 254.5, },
		[13] = { 17, 232, 347, 289.53333333333, },
		[14] = { 18, 256, 384, 328.85, },
		[15] = { 18, 283, 424, 372.9, },
		[16] = { 19, 312, 468, 422.2, },
		[17] = { 19, 344, 516, 477.35, },
		[18] = { 20, 379, 568, 538.96666666667, },
		[19] = { 20, 417, 625, 607.75, },
		[20] = { 21, 458, 688, 684.46666666667, },
		[21] = { 21, 504, 756, 769.96666666667, },
		[22] = { 22, 554, 831, 865.18333333333, },
		[23] = { 22, 608, 912, 971.15, },
		[24] = { 23, 667, 1001, 1088.9833333333, },
		[25] = { 23, 732, 1098, 1219.9166666667, },
		[26] = { 24, 802, 1204, 1365.3333333333, },
		[27] = { 24, 879, 1319, 1526.7166666667, },
		[28] = { 25, 963, 1445, 1705.7166666667, },
		[29] = { 25, 1055, 1582, 1904.1333333333, },
		[30] = { 26, 1154, 1731, 2123.9666666667, },
	},
}
gems["Vulnerability"] = {
	curse = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	color = 3,
	baseFlags = {
		spell = true,
		curse = true,
		area = true,
		duration = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [17] = true, [18] = true, [19] = true, [26] = true, [32] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.5), 
		mod("DotTaken", "INC", 33, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"degen_effect_+%" = 33
		--"base_deal_no_damage" = ?
		skill("debuff", true), 
	},
	qualityMods = {
		mod("PhysicalDamageTaken", "INC", 0.5, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"physical_damage_taken_+%" = 0.5
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = skill("duration", nil), --"base_skill_effect_duration"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("PhysicalDamageTaken", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Curse" }), --"physical_damage_taken_+%"
	},
	levels = {
		[1] = { 24, 9, 0, 20, },
		[2] = { 26, 9.1, 4, 20, },
		[3] = { 27, 9.2, 8, 21, },
		[4] = { 29, 9.3, 12, 21, },
		[5] = { 30, 9.4, 16, 22, },
		[6] = { 32, 9.5, 20, 22, },
		[7] = { 34, 9.6, 24, 23, },
		[8] = { 35, 9.7, 28, 23, },
		[9] = { 37, 9.8, 32, 24, },
		[10] = { 38, 9.9, 36, 24, },
		[11] = { 39, 10, 40, 25, },
		[12] = { 40, 10.1, 44, 25, },
		[13] = { 42, 10.2, 48, 26, },
		[14] = { 43, 10.3, 52, 26, },
		[15] = { 44, 10.4, 56, 27, },
		[16] = { 45, 10.5, 60, 27, },
		[17] = { 46, 10.6, 64, 28, },
		[18] = { 47, 10.7, 68, 28, },
		[19] = { 48, 10.8, 72, 29, },
		[20] = { 50, 10.9, 76, 29, },
		[21] = { 51, 11, 80, 30, },
		[22] = { 52, 11.1, 84, 30, },
		[23] = { 53, 11.2, 88, 31, },
		[24] = { 54, 11.3, 92, 31, },
		[25] = { 56, 11.4, 96, 32, },
		[26] = { 57, 11.5, 100, 32, },
		[27] = { 58, 11.6, 104, 33, },
		[28] = { 59, 11.7, 108, 33, },
		[29] = { 60, 11.8, 112, 34, },
		[30] = { 61, 11.9, 116, 34, },
	},
}
gems["Wither"] = {
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	duration = true,
	chaos = true,
	channelling = true,
	parts = {
		{
			name = "1 Stack",
		},
		{
			name = "5 Stacks",
		},
		{
			name = "10 Stacks",
		},
		{
			name = "20 Stacks",
		},
	},
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		chaos = true,
	},
	skillTypes = { [2] = true, [11] = true, [12] = true, [18] = true, [50] = true, [58] = true, },
	baseMods = {
		skill("castTime", 0.28), 
		mod("ChaosDamageTaken", "INC", 7, 0, 0, { type = "GlobalEffect", effectType = "Debuff" }), --"chaos_damage_taken_+%" = 7
		nil, --"base_skill_effect_duration" = 500
		skill("duration", 2), --"base_secondary_skill_effect_duration" = 2000
		skill("stackCount", 5, { type = "SkillPart", skillPart = 2 }), 
		skill("stackCount", 10, { type = "SkillPart", skillPart = 3 }), 
		skill("stackCount", 20, { type = "SkillPart", skillPart = 4 }), 
	},
	qualityMods = {
		mod("Duration", "INC", 1), --"skill_effect_duration_+%" = 1
	},
	levelMods = {
		[1] = skill("manaCost", nil), 
		[2] = mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Debuff" }), --"base_movement_velocity_+%"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
	},
	levels = {
		[1] = { 4, -30, 0, },
		[2] = { 4, -30, 1, },
		[3] = { 4, -30, 2, },
		[4] = { 5, -31, 3, },
		[5] = { 5, -31, 4, },
		[6] = { 5, -31, 5, },
		[7] = { 6, -32, 6, },
		[8] = { 6, -32, 7, },
		[9] = { 6, -32, 8, },
		[10] = { 7, -33, 9, },
		[11] = { 7, -33, 10, },
		[12] = { 7, -33, 11, },
		[13] = { 8, -34, 12, },
		[14] = { 8, -34, 13, },
		[15] = { 8, -34, 14, },
		[16] = { 9, -35, 15, },
		[17] = { 9, -35, 16, },
		[18] = { 9, -35, 17, },
		[19] = { 10, -36, 18, },
		[20] = { 10, -36, 19, },
		[21] = { 10, -36, 20, },
		[22] = { 11, -37, 21, },
		[23] = { 11, -37, 22, },
		[24] = { 11, -37, 23, },
		[25] = { 12, -38, 24, },
		[26] = { 12, -38, 25, },
		[27] = { 12, -38, 26, },
		[28] = { 13, -39, 27, },
		[29] = { 13, -39, 28, },
		[30] = { 13, -39, 29, },
	},
}
gems["Wrath"] = {
	aura = true,
	intelligence = true,
	active_skill = true,
	spell = true,
	area = true,
	lightning = true,
	color = 3,
	baseFlags = {
		spell = true,
		aura = true,
		area = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [11] = true, [5] = true, [15] = true, [27] = true, [16] = true, [18] = true, [44] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1.2), 
		skill("manaCost", 50), 
		--"base_deal_no_damage" = ?
	},
	qualityMods = {
		mod("AreaOfEffect", "INC", 1), --"base_skill_area_of_effect_+%" = 1
	},
	levelMods = {
		[1] = mod("LightningMin", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_minimum_added_lightning_damage"
		[2] = mod("LightningMax", "BASE", nil, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_maximum_added_lightning_damage"
		[3] = mod("AreaOfEffect", "INC", nil), --"base_skill_area_of_effect_+%"
		[4] = mod("LightningDamage", "MORE", nil, ModFlag.Spell, 0, { type = "GlobalEffect", effectType = "Aura" }), --"wrath_aura_spell_lightning_damage_+%_final"
	},
	levels = {
		[1] = { 2, 37, 0, 15, },
		[2] = { 3, 43, 3, 15, },
		[3] = { 3, 50, 6, 15, },
		[4] = { 4, 57, 9, 16, },
		[5] = { 4, 66, 12, 16, },
		[6] = { 5, 75, 15, 16, },
		[7] = { 5, 85, 18, 17, },
		[8] = { 6, 97, 21, 17, },
		[9] = { 7, 109, 23, 17, },
		[10] = { 7, 118, 25, 18, },
		[11] = { 8, 128, 27, 18, },
		[12] = { 9, 138, 29, 18, },
		[13] = { 9, 149, 31, 19, },
		[14] = { 10, 161, 33, 19, },
		[15] = { 11, 173, 35, 19, },
		[16] = { 12, 186, 36, 20, },
		[17] = { 13, 200, 37, 20, },
		[18] = { 13, 215, 38, 20, },
		[19] = { 14, 231, 39, 21, },
		[20] = { 16, 248, 40, 21, },
		[21] = { 17, 267, 41, 21, },
		[22] = { 18, 286, 42, 22, },
		[23] = { 19, 306, 43, 22, },
		[24] = { 20, 328, 44, 22, },
		[25] = { 22, 351, 45, 23, },
		[26] = { 23, 375, 46, 23, },
		[27] = { 25, 401, 47, 23, },
		[28] = { 27, 429, 48, 24, },
		[29] = { 29, 458, 49, 24, },
		[30] = { 31, 490, 50, 24, },
	},
}
