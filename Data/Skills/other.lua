-- Path of Building
--
-- Other active skills
-- Skill data (c) Grinding Gear Games
--
local skills, mod, flag, skill = ...

skills["Melee"] = {
	name = "Default Attack",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		attack = true,
		melee = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [6] = true, [3] = true, [25] = true, [28] = true, [24] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 1), 
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
skills["GemDetonateMines"] = {
	name = "Detonate Mines",
	gemTags = {
		low_max_level = true,
		active_skill = true,
		spell = true,
	},
	color = 4,
	baseFlags = {
		spell = true,
	},
	skillTypes = { [2] = true, [17] = true, [18] = true, [36] = true, },
	baseMods = {
		skill("castTime", 0.2), 
		skill("levelRequirement", 8), 
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
skills["Portal"] = {
	name = "Portal",
	gemTags = {
		low_max_level = true,
		active_skill = true,
		spell = true,
	},
	color = 4,
	baseFlags = {
		spell = true,
	},
	skillTypes = { [2] = true, [17] = true, [18] = true, [19] = true, [36] = true, [27] = true, },
	baseMods = {
		skill("castTime", 2.5), 
		skill("levelRequirement", 10), 
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
skills["RepeatingShockwave"] = {
	name = "Abberath's Fury",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		spell = true,
		area = true,
	},
	skillTypes = { [11] = true, [36] = true, [42] = true, [2] = true, [10] = true, [61] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 1), 
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
skills["TriggeredBoneNova"] = {
	name = "Bone Nova",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		attack = true,
		projectile = true,
	},
	skillTypes = { [1] = true, [48] = true, [3] = true, [10] = true, [57] = true, [47] = true, [61] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 1), 
		skill("cooldown", 0.5), 
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
skills["TriggeredConsecrate"] = {
	name = "Consecrate",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		spell = true,
		duration = true,
		area = true,
	},
	skillTypes = { [2] = true, [12] = true, [36] = true, [11] = true, [42] = true, [61] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 1), 
		skill("cooldown", 5), 
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		mod("LifeRegenPercent", "BASE", 4, 0, 0, nil), --"life_regeneration_rate_per_minute_%" = 240
		--"cast_on_crit_%" = 100
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[10] = { },
	},
}
skills["TriggeredSummonLesserShrine"] = {
	name = "Create Lesser Shrine",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		spell = true,
		duration = true,
	},
	skillTypes = { [2] = true, [36] = true, [42] = true, [61] = true, [12] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 1), 
		skill("cooldown", 20), 
		--"chance_to_cast_on_kill_%" = 100
		skill("duration", 10), --"base_skill_effect_duration" = 10000
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[1] = { },
	},
}
skills["Envy"] = {
	name = "Envy",
	hidden = true,
	other = true,
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
		skill("levelRequirement", 60), 
		skill("manaCost", 50), 
		skill("cooldown", 1.2), 
		mod("ChaosMin", "BASE", 58, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_minimum_added_chaos_damage" = 58
		mod("ChaosMax", "BASE", 81, ModFlag.Attack, 0, { type = "GlobalEffect", effectType = "Aura" }), --"attack_maximum_added_chaos_damage" = 81
		mod("AreaOfEffect", "INC", 0), --"base_skill_area_of_effect_+%" = 0
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
skills["FireBurstOnHit"] = {
	name = "Fire Burst",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		spell = true,
		area = true,
		fire = true,
	},
	skillTypes = { [2] = true, [11] = true, [10] = true, [33] = true, [36] = true, [42] = true, [61] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("damageEffectiveness", 0.5), 
		skill("critChance", 5), 
		skill("cooldown", 0.5), 
		--"cast_on_hit_%" = 10
		--"is_area_damage" = ?
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("FireMin", nil), --"spell_minimum_base_fire_damage"
		[3] = skill("FireMax", nil), --"spell_maximum_base_fire_damage"
	},
	levels = {
		[1] = { 1, 7, 11, },
		[2] = { 2, 8, 12, },
		[3] = { 4, 10, 16, },
		[4] = { 7, 14, 21, },
		[5] = { 11, 20, 30, },
		[6] = { 16, 30, 46, },
		[7] = { 20, 41, 61, },
		[8] = { 24, 54, 80, },
		[9] = { 28, 70, 104, },
		[10] = { 32, 89, 134, },
		[11] = { 36, 114, 170, },
		[12] = { 40, 143, 215, },
		[13] = { 44, 180, 270, },
		[14] = { 48, 224, 336, },
		[15] = { 52, 278, 418, },
		[16] = { 56, 344, 516, },
		[17] = { 60, 424, 636, },
		[18] = { 64, 520, 780, },
		[19] = { 67, 605, 908, },
		[20] = { 70, 703, 1055, },
		[21] = { 72, 777, 1165, },
		[22] = { 74, 858, 1286, },
		[23] = { 76, 946, 1419, },
		[24] = { 78, 1043, 1564, },
		[25] = { 80, 1149, 1724, },
		[26] = { 82, 1266, 1899, },
		[27] = { 84, 1394, 2091, },
		[28] = { 86, 1534, 2301, },
		[29] = { 88, 1687, 2530, },
		[30] = { 90, 1855, 2782, },
	},
}
skills["VaalAuraElementalDamageHealing"] = {
	name = "Gluttony of Elements",
	hidden = true,
	other = true,
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
		skill("levelRequirement", 1), 
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
skills["IcestormUniqueStaff12"] = {
	name = "Icestorm",
	hidden = true,
	other = true,
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
		skill("levelRequirement", 1), 
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
skills["MerveilWarp"] = {
	name = "Illusory Warp",
	hidden = true,
	other = true,
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
		skill("levelRequirement", 1), 
		skill("manaCost", 20), 
		skill("cooldown", 3), 
		skill("duration", 1.5), --"base_skill_effect_duration" = 1500
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[20] = { },
	},
}
skills["LightningSpell"] = {
	name = "Lightning Bolt",
	hidden = true,
	other = true,
	color = 3,
	baseFlags = {
		spell = true,
		area = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [42] = true, [35] = true, [11] = true, [10] = true, [45] = true, [61] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("critChance", 6), 
		skill("cooldown", 0.5), 
		--"cast_on_crit_%" = 100
		--"is_area_damage" = ?
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
		[1] = skill("levelRequirement", nil), 
		[2] = skill("LightningMin", nil), --"spell_minimum_base_lightning_damage"
		[3] = skill("LightningMax", nil), --"spell_maximum_base_lightning_damage"
	},
	levels = {
		[1] = { 1, 10, 29, },
		[2] = { 2, 11, 33, },
		[3] = { 4, 14, 41, },
		[4] = { 7, 18, 54, },
		[5] = { 11, 25, 75, },
		[6] = { 16, 36, 109, },
		[7] = { 20, 47, 141, },
		[8] = { 24, 60, 180, },
		[9] = { 28, 76, 227, },
		[10] = { 32, 94, 282, },
		[11] = { 36, 116, 348, },
		[12] = { 40, 142, 426, },
		[13] = { 44, 173, 518, },
		[14] = { 48, 209, 626, },
		[15] = { 52, 251, 754, },
		[16] = { 56, 301, 903, },
		[17] = { 60, 359, 1078, },
		[18] = { 64, 428, 1283, },
		[19] = { 67, 486, 1459, },
		[20] = { 70, 552, 1657, },
		[21] = { 72, 601, 1802, },
		[22] = { 74, 653, 1959, },
		[23] = { 76, 709, 2127, },
		[24] = { 78, 770, 2310, },
		[25] = { 80, 835, 2506, },
		[26] = { 82, 906, 2718, },
		[27] = { 84, 982, 2946, },
		[28] = { 86, 1064, 3192, },
		[29] = { 88, 1153, 3458, },
		[30] = { 90, 1248, 3743, },
	},
}
skills["TriggeredMoltenStrike"] = {
	name = "Molten Burst",
	hidden = true,
	other = true,
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
		skill("levelRequirement", 1), 
		skill("cooldown", 0.15), 
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
skills["TriggeredShockedGround"] = {
	name = "Shock Ground",
	hidden = true,
	other = true,
	color = 4,
	baseFlags = {
		spell = true,
		area = true,
		duration = true,
		lightning = true,
	},
	skillTypes = { [2] = true, [11] = true, [36] = true, [12] = true, [42] = true, [45] = true, [61] = true, [35] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 1), 
		skill("cooldown", 5), 
		--"cast_when_hit_%" = 100
		--"skill_art_variation" = 7
		skill("duration", 5), --"base_skill_effect_duration" = 5000
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[1] = { },
	},
}
skills["SummonRigwaldsPack"] = {
	name = "Summon Spectral Wolf",
	hidden = true,
	other = true,
	minionList = {
		"SummonedSpectralWolf",
	},
	color = 4,
	baseFlags = {
		spell = true,
		minion = true,
		duration = true,
	},
	skillTypes = { [2] = true, [9] = true, [12] = true, [21] = true, [17] = true, [18] = true, [19] = true, [26] = true, [36] = true, [49] = true, [42] = true, [61] = true, },
	minionSkillTypes = { [1] = true, [24] = true, [25] = true, [28] = true, },
	baseMods = {
		skill("castTime", 1), 
		skill("levelRequirement", 66), 
		skill("duration", 30), --"base_skill_effect_duration" = 30000
		mod("ActiveWolfLimit", "BASE", 20), --"number_of_wolves_allowed" = 20
		--"chance_to_cast_on_kill_%_target_self" = 10
		--"display_minion_monster_type" = 8
		skill("minionLevel", 65), --"display_minion_monster_level" = 65
		skill("triggered", true, { type = "SkillType", skillType = SkillType.TriggerableSpell }), --"spell_uncastable_if_triggerable" = ?
	},
	qualityMods = {
	},
	levelMods = {
	},
	levels = {
		[18] = { },
	},
}