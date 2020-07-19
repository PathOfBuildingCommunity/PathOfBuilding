-- Path of Building
--
-- Stat to internal modifier mapping table for skills
-- Stat data (c) Grinding Gear Games
--
local mod, flag, skill = ...

return {
--
-- Skill data modifiers
--
["base_skill_effect_duration"] = {
	skill("duration", nil),
	div = 1000,
},
["base_secondary_skill_effect_duration"] = {
	skill("durationSecondary", nil),
	div = 1000,
},
["spell_minimum_base_physical_damage"] = {
	skill("PhysicalMin", nil),
},
["secondary_minimum_base_physical_damage"] = {
	skill("PhysicalMin", nil),
},
["spell_maximum_base_physical_damage"] = {
	skill("PhysicalMax", nil),
},
["secondary_maximum_base_physical_damage"] = {
	skill("PhysicalMax", nil),
},
["spell_minimum_base_lightning_damage"] = {
	skill("LightningMin", nil),
},
["secondary_minimum_base_lightning_damage"] = {
	skill("LightningMin", nil),
},
["spell_maximum_base_lightning_damage"] = {
	skill("LightningMax", nil),
},
["secondary_maximum_base_lightning_damage"] = {
	skill("LightningMax", nil),
},
["spell_minimum_base_cold_damage"] = {
	skill("ColdMin", nil),
},
["secondary_minimum_base_cold_damage"] = {
	skill("ColdMin", nil),
},
["spell_maximum_base_cold_damage"] = {
	skill("ColdMax", nil),
},
["secondary_maximum_base_cold_damage"] = {
	skill("ColdMax", nil),
},
["spell_minimum_base_fire_damage"] = {
	skill("FireMin", nil),
},
["secondary_minimum_base_fire_damage"] = {
	skill("FireMin", nil),
},
["spell_maximum_base_fire_damage"] = {
	skill("FireMax", nil),
},
["secondary_maximum_base_fire_damage"] = {
	skill("FireMax", nil),
},
["spell_minimum_base_chaos_damage"] = {
	skill("ChaosMin", nil),
},
["secondary_minimum_base_chaos_damage"] = {
	skill("ChaosMin", nil),
},
["spell_maximum_base_chaos_damage"] = {
	skill("ChaosMax", nil),
},
["secondary_maximum_base_chaos_damage"] = {
	skill("ChaosMax", nil),
},
["spell_minimum_base_lightning_damage_per_removable_power_charge"] = {
	skill("LightningMin", nil, { type = "Multiplier", var = "RemovablePowerCharge" }),
},
["spell_maximum_base_lightning_damage_per_removable_power_charge"] = {
	skill("LightningMax", nil, { type = "Multiplier", var = "RemovablePowerCharge" }),
},
["spell_minimum_base_fire_damage_per_removable_endurance_charge"] = {
	skill("FireMin", nil, { type = "Multiplier", var = "RemovableEnduranceCharge" }),
},
["spell_maximum_base_fire_damage_per_removable_endurance_charge"] = {
	skill("FireMax", nil, { type = "Multiplier", var = "RemovableEnduranceCharge" }),
},
["spell_minimum_base_cold_damage_per_removable_frenzy_charge"] = {
	skill("ColdMin", nil, { type = "Multiplier", var = "RemovableFrenzyCharge" }),
},
["spell_maximum_base_cold_damage_per_removable_frenzy_charge"] = {
	skill("ColdMax", nil, { type = "Multiplier", var = "RemovableFrenzyCharge" }),
},
["spell_minimum_base_cold_damage_+_per_10_intelligence"] = {
	skill("ColdMin", nil, { type = "PerStat", stat = "Int", div = 10 }),
},
["spell_maximum_base_cold_damage_+_per_10_intelligence"] = {
	skill("ColdMax", nil, { type = "PerStat", stat = "Int", div = 10 }),
},
["base_cold_damage_to_deal_per_minute"] = {
	skill("ColdDot", nil),
	div = 60,
},
["base_fire_damage_to_deal_per_minute"] = {
	skill("FireDot", nil),
	div = 60,
},
["base_chaos_damage_to_deal_per_minute"] = {
	skill("ChaosDot", nil),
	div = 60,
},
["base_skill_show_average_damage_instead_of_dps"] = {
	skill("showAverage", true),
},
["cast_time_overrides_attack_duration"] = {
	skill("castTimeOverridesAttackTime", true),
},
["spell_cast_time_cannot_be_modified"] = {
	skill("fixedCastTime", true),
},
["global_always_hit"] = {
	skill("cannotBeEvaded", true),
},
["bleed_duration_is_skill_duration"] = {
	skill("bleedDurationIsSkillDuration", true),
},
["poison_duration_is_skill_duration"] = {
	skill("poisonDurationIsSkillDuration", true),
},
["spell_damage_modifiers_apply_to_skill_dot"] = {
	skill("dotIsSpell", true),
},
["projectile_damage_modifiers_apply_to_skill_dot"] = {
	skill("dotIsProjectile", true),
},
["additive_mine_duration_modifiers_apply_to_buff_effect_duration"] = {
	skill("mineDurationAppliesToSkill", true),
},
["additive_arrow_speed_modifiers_apply_to_area_of_effect"] = {
	skill("arrowSpeedAppliesToAreaOfEffect", true),
},
["base_use_life_in_place_of_mana"] = {
	flag("SkillBloodMagic"),
},
["base_active_skill_totem_level"] = {
	skill("totemLevel", nil),
},
["totem_support_gem_level"] = {
	skill("totemLevel", nil),
},
["spell_uncastable_if_triggerable"] = {
	skill("triggered", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["unique_mjolner_lightning_spells_triggered"] = {
	skill("triggered", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["unique_cospris_malice_cold_spells_triggered"] = {
	skill("triggered", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["skill_triggered_by_snipe"] = {
	skill("triggered", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["skill_double_hits_when_dual_wielding"] = {
	skill("doubleHitsWhenDualWielding", true),
},
["base_spell_repeat_count"] = {
	skill("repeatCount", nil),
},
["display_minion_monster_level"] = {
	skill("minionLevel", nil),
},
["display_skill_minions_level_is_corpse_level"] = {
	skill("minionLevelIsEnemyLevel", true),
},
["active_skill_minion_added_damage_+%_final"] = {
	skill("minionDamageEffectiveness", nil),
},
["base_bleed_on_hit_still_%_of_physical_damage_to_deal_per_minute"] = {
	skill("bleedBasePercent", nil),
	div = 60,
},
["active_skill_base_radius_+"] = {
	skill("radiusExtra", nil),
},
["corpse_explosion_monster_life_%"] = {
	skill("corpseExplosionLifeMultiplier", nil),
	div = 100,
},
["spell_base_fire_damage_%_maximum_life"] = {
	skill("selfFireExplosionLifeMultiplier", nil),
	div = 100,
},
["deal_chaos_damage_per_second_for_10_seconds_on_hit"] = {
	mod("SkillData", "LIST", { key = "decay", value = nil, merge = "MAX" }),
},
["base_spell_cast_time_ms_override"] = {
	skill("castTimeOverride", nil),
	div = 1000,
},

--
-- Defensive modifiers
--
["base_physical_damage_reduction_rating"] = {
	mod("Armour", "BASE", nil),
},
["base_evasion_rating"] = {
	mod("Evasion", "BASE", nil),
},
["base_maximum_energy_shield"] = {
	mod("EnergyShield", "BASE", nil),
},
["base_fire_damage_resistance_%"] = {
	mod("FireResist", "BASE", nil),
},
["base_cold_damage_resistance_%"] = {
	mod("ColdResist", "BASE", nil),
},
["base_lightning_damage_resistance_%"] = {
	mod("LightningResist", "BASE", nil),
},
["base_chaos_damage_resistance_%"] = {
	mod("ChaosResist", "BASE", nil),
},
["base_resist_all_elements_%"] = {
	mod("ElementalResist", "BASE", nil),
},
["base_maximum_fire_damage_resistance_%"] = {
	mod("FireResistMax", "BASE", nil),
},
["base_maximum_cold_damage_resistance_%"] = {
	mod("ColdResistMax", "BASE", nil),
},
["base_maximum_lightning_damage_resistance_%"] = {
	mod("LightningResistMax", "BASE", nil),
},
["base_stun_recovery_+%"] = {
	mod("StunRecovery", "INC", nil),
},
["base_life_gain_per_target"] = {
	mod("LifeOnHit", "BASE", nil, ModFlag.Attack),
},
["base_life_regeneration_rate_per_minute"] = {
	mod("LifeRegen", "BASE", nil),
	div = 60,
},
["life_regeneration_rate_per_minute_%"] = {
	mod("LifeRegenPercent", "BASE", nil),
	div = 60,
},
["base_mana_regeneration_rate_per_minute"] = {
	mod("ManaRegen", "BASE", nil),
	div = 60,
},
["energy_shield_recharge_rate_+%"] = {
	mod("EnergyShieldRecharge", "INC", nil),
},
["base_mana_cost_-%"] = {
	mod("ManaCost", "INC", nil),
	mult = -1,
},
["no_mana_cost"] = {
	mod("ManaCost", "MORE", nil),
	value = -100,
},
["base_chance_to_dodge_%"] = {
	mod("AttackDodgeChance", "BASE", nil),
},
["base_chance_to_dodge_spells_%"] = {
	mod("SpellDodgeChance", "BASE", nil),
},
["base_movement_velocity_+%"] = {
	mod("MovementSpeed", "INC", nil),
},
["monster_base_block_%"] = {
	mod("BlockChance", "BASE", nil),
},
["base_spell_block_%"] = {
	mod("SpellBlockChance", "BASE", nil),
},
["life_leech_from_any_damage_permyriad"] = {
	mod("DamageLifeLeech", "BASE", nil),
	div = 100,
},
["mana_leech_from_any_damage_permyriad"] = {
	mod("DamageManaLeech", "BASE", nil),
	div = 100,
},
["attack_skill_mana_leech_from_any_damage_permyriad"] = {
	mod("DamageManaLeech", "BASE", nil, ModFlag.Attack),
	div = 100,
},
["energy_shield_leech_from_any_damage_permyriad"] = {
	mod("DamageEnergyShieldLeech", "BASE", nil),
	div = 100,
},
["life_leech_from_physical_attack_damage_permyriad"] = {
	mod("PhysicalDamageLifeLeech", "BASE", nil, ModFlag.Attack),
	div = 100,
},
["base_energy_shield_leech_from_spell_damage_permyriad"] = {
	mod("DamageEnergyShieldLeech", "BASE", nil, ModFlag.Spell),
	div = 100,
},
["damage_+%_while_life_leeching"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "LeechingLife" }),
},
["damage_+%_while_mana_leeching"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "LeechingMana" }),
},
["damage_+%_while_es_leeching"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "LeechingEnergyShield" }),
},
["aura_effect_+%"] = {
	mod("AuraEffect", "INC", nil),
},
["elusive_effect_+%"] = {
	mod("ElusiveEffect", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }),
},
["cannot_be_stunned_while_leeching"] = {
	mod("AvoidStun", "BASE", 100, { type = "Condition", var = "Leeching"}),
},
["life_leech_does_not_stop_at_full_life"] = {
	flag("CanLeechLifeOnFullLife"),
},

--
-- Offensive modifiers
--
-- Speed
["attack_and_cast_speed_+%"] = {
	mod("Speed", "INC", nil),
},
["cast_speed_+%_granted_from_skill"] = {
	mod("Speed", "INC", nil, ModFlag.Cast),
},
["base_cooldown_speed_+%"] = {
	mod("CooldownRecovery", "INC", nil),
},
["support_added_cooldown_count_if_not_instant"] = {
	mod("CooldownRecovery", "INC", nil),
},
["additional_weapon_base_attack_time_ms"] = {
	mod("Speed", "BASE", nil, ModFlag.Attack),
	div = 1000,
},
["warcry_speed_+%"] = {
	mod("WarcrySpeed", "INC", nil, 0, KeywordFlag.Warcry),
},
-- AoE
["base_skill_area_of_effect_+%"] = {
	mod("AreaOfEffect", "INC", nil),
},
["base_aura_area_of_effect_+%"] = {
	mod("AreaOfEffect", "INC", nil, 0, KeywordFlag.Aura),
},
["active_skill_area_of_effect_+%_final_when_cast_on_frostbolt"] = {
	mod("AreaOfEffect", "MORE", nil, 0, 0, { type = "Condition", var = "CastOnFrostbolt" }),
},
["active_skill_area_of_effect_radius_+%_final"] = {
	mod("AreaOfEffect", "MORE", nil),
},
-- Critical strikes
["additional_base_critical_strike_chance"] = {
	mod("CritChance", "BASE", nil),
	div = 100,
},
["critical_strike_chance_+%"] = {
	mod("CritChance", "INC", nil),
},
["spell_critical_strike_chance_+%"] = {
	mod("CritChance", "INC", nil, ModFlag.Spell),
},
["attack_critical_strike_chance_+%"] = {
	mod("CritChance", "INC", nil, ModFlag.Attack),
},
["base_critical_strike_multiplier_+"] = {
	mod("CritMultiplier", "BASE", nil),
},
["critical_strike_chance_+%_vs_shocked_enemies"] = {
	mod("CritChance", "INC", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Shocked" }),
},
["critical_strike_chance_+%_per_power_charge"] = {
	mod("CritChance", "INC", nil, 0, 0, { type = "Multiplier", var = "PowerCharge" }),
},
["critical_strike_multiplier_+_per_power_charge"] = {
	mod("CritMultiplier", "BASE", nil, 0, 0, { type = "Multiplier", var = "PowerCharge" }),
},
["additional_critical_strike_chance_permyriad_while_affected_by_elusive"] = {
	mod("CritChance", "BASE", nil, 0, 0, { type = "Condition", var = "Elusive" }, { type = "Condition", varList = { "UsingClaw", "UsingDagger"} }, { type = "Condition", varList = { "UsingSword", "UsingAxe", "UsingMace" }, neg = true} ),
	div = 100,
},
["nightblade_elusive_grants_critical_strike_multiplier_+_to_supported_skills"] = {
	mod("CritMultiplier", "BASE", nil, 0, 0, { type = "Condition", var = "Elusive" }, { type = "Condition", varList = { "UsingClaw", "UsingDagger" } }, { type = "Condition", varList = { "UsingSword", "UsingAxe", "UsingMace" }, neg = true} ),
},
-- Duration
["buff_effect_duration_+%_per_removable_endurance_charge"] = {
	mod("Duration", "INC", nil, 0, 0, { type = "Multiplier", var = "RemovableEnduranceCharge" }),
},
["buff_effect_duration_+%_per_removable_endurance_charge_limited_to_5"] = {
	mod("Duration", "INC", nil, 0, 0, { type = "Multiplier", var = "RemovableEnduranceCharge", limit = 5 }),
},
["skill_effect_duration_+%_per_removable_frenzy_charge"] = {
	mod("Duration", "INC", nil, 0, 0, { type = "Multiplier", var = "RemovableFrenzyCharge" }),
},
["skill_effect_duration_+%"] = {
	mod("Duration", "INC", nil),
},
["fortify_duration_+%"] = {
	mod("FortifyDuration", "INC", nil),
},
["skill_effect_and_damaging_ailment_duration_+%"] = {
	mod("SkillAndDamagingAilmentDuration", "INC", nil),
},
-- Damage
["damage_+%"] = {
	mod("Damage", "INC", nil),
},
["physical_damage_+%"] = {
	mod("PhysicalDamage", "INC", nil),
},
["lightning_damage_+%"] = {
	mod("LightningDamage", "INC", nil),
},
["cold_damage_+%"] = {
	mod("ColdDamage", "INC", nil),
},
["fire_damage_+%"] = {
	mod("FireDamage", "INC", nil),
},
["chaos_damage_+%"] = {
	mod("ChaosDamage", "INC", nil),
},
["elemental_damage_+%"] = {
	mod("ElementalDamage", "INC", nil),
},
["damage_over_time_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Dot),
},
["burn_damage_+%"] = {
	mod("FireDamage", "INC", nil, 0, KeywordFlag.FireDot),
},
["active_skill_damage_+%_final"] = {
	mod("Damage", "MORE", nil),
},
["melee_damage_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Melee),
},
["melee_physical_damage_+%"] = {
	mod("PhysicalDamage", "INC", nil, ModFlag.Melee),
},
["area_damage_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Area),
},
["projectile_damage_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Projectile),
},
["active_skill_projectile_damage_+%_final"] = {
	mod("Damage", "MORE", nil, ModFlag.Projectile),
},
["active_skill_area_damage_+%_final"] = {
	mod("Damage", "MORE", nil, ModFlag.Area),
},
["physical_damage_+%_per_frenzy_charge"] = {
	mod("PhysicalDamage", "INC", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["melee_damage_vs_bleeding_enemies_+%"] = {
	mod("PhysicalDamage", "INC", nil, ModFlag.Melee, 0, { type = "ActorCondition", actor = "enemy", var = "Bleeding" }),
},
["damage_+%_vs_frozen_enemies"] = {
	mod("Damage", "INC", nil, ModFlag.Hit, 0, { type = "ActorCondition", actor = "enemy", var = "Frozen" }),
},
["base_reduce_enemy_fire_resistance_%"] = {
	mod("FirePenetration", "BASE", nil),
},
["base_reduce_enemy_cold_resistance_%"] = {
	mod("ColdPenetration", "BASE", nil),
},
["base_reduce_enemy_lightning_resistance_%"] = {
	mod("LightningPenetration", "BASE", nil),
},
["reduce_enemy_elemental_resistance_%"] = {
	mod("ElementalPenetration", "BASE", nil),
},
["global_minimum_added_physical_damage_vs_bleeding_enemies"] = {
	mod("PhysicalMin", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Bleeding"}),
},
["global_maximum_added_physical_damage_vs_bleeding_enemies"] = {
	mod("PhysicalMax", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Bleeding"}),
},
["global_minimum_added_fire_damage_vs_burning_enemies"] = {
	mod("FireMin", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Burning" }),
},
["global_maximum_added_fire_damage_vs_burning_enemies"] = {
	mod("FireMax", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Burning" }),
},
["minimum_added_cold_damage_per_frenzy_charge"] = {
	mod("ColdMin", "BASE", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["maximum_added_cold_damage_per_frenzy_charge"] = {
	mod("ColdMax", "BASE", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["minimum_added_cold_damage_vs_chilled_enemies"] = {
	mod("ColdMin", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Chilled" }),
},
["maximum_added_cold_damage_vs_chilled_enemies"] = {
	mod("ColdMax", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Chilled" }),
},
["global_minimum_added_cold_damage"] = {
	mod("ColdMin", "BASE", nil),
},
["global_maximum_added_cold_damage"] = {
	mod("ColdMax", "BASE", nil),
},
["global_minimum_added_lightning_damage"] = {
	mod("LightningMin", "BASE", nil),
},
["global_maximum_added_lightning_damage"] = {
	mod("LightningMax", "BASE", nil),
},
["global_minimum_added_chaos_damage"] = {
	mod("ChaosMin", "BASE", nil),
},
["global_maximum_added_chaos_damage"] = {
	mod("ChaosMax", "BASE", nil),
},
["support_slashing_damage_+%_final_from_distance"] = {
	mod("Damage", "MORE", nil, bit.bor(ModFlag.Attack, ModFlag.Melee), 0, { type = "MeleeProximity", ramp = {1,0} }, { type = "Condition", varList = { "UsingSword", "UsingAxe" }}, { type = "Condition", varList = { "UsingClaw", "UsingDagger", "UsingMace" }, neg=true} ),
},
-- Conversion
["physical_damage_%_to_add_as_lightning"] = {
	mod("PhysicalDamageGainAsLightning", "BASE", nil),
},
["physical_damage_%_to_add_as_cold"] = {
	mod("PhysicalDamageGainAsCold", "BASE", nil),
},
["physical_damage_%_to_add_as_fire"] = {
	mod("PhysicalDamageGainAsFire", "BASE", nil),
},
["physical_damage_%_to_add_as_chaos"] = {
	mod("PhysicalDamageGainAsChaos", "BASE", nil),
},
["cold_damage_%_to_add_as_fire"] = {
	mod("ColdDamageGainAsFire", "BASE", nil),
},
["base_physical_damage_%_to_convert_to_lightning"] = {
	mod("PhysicalDamageConvertToLightning", "BASE", nil),
},
["base_physical_damage_%_to_convert_to_cold"] = {
	mod("PhysicalDamageConvertToCold", "BASE", nil),
},
["base_physical_damage_%_to_convert_to_fire"] = {
	mod("PhysicalDamageConvertToFire", "BASE", nil),
},
["base_physical_damage_%_to_convert_to_chaos"] = {
	mod("PhysicalDamageConvertToChaos", "BASE", nil),
},
["skill_physical_damage_%_to_convert_to_lightning"] = {
	mod("SkillPhysicalDamageConvertToLightning", "BASE", nil),
},
["skill_physical_damage_%_to_convert_to_cold"] = {
	mod("SkillPhysicalDamageConvertToCold", "BASE", nil),
},
["skill_physical_damage_%_to_convert_to_fire"] = {
	mod("SkillPhysicalDamageConvertToFire", "BASE", nil),
},
["skill_physical_damage_%_to_convert_to_chaos"] = {
	mod("SkillPhysicalDamageConvertToChaos", "BASE", nil),
},
["skill_cold_damage_%_to_convert_to_fire"] = {
	mod("SkillColdDamageConvertToFire", "BASE", nil),
},
-- Ailments
["bleed_on_hit_with_attacks_%"] = {
	mod("BleedChance", "BASE", nil, ModFlag.Attack),
},
["global_bleed_on_hit"] = {
	mod("BleedChance", "BASE", nil),
	value = 100,
},
["bleed_on_melee_attack_chance_%"] = {
	mod("BleedChance", "BASE", nil, ModFlag.Melee),
},
["faster_bleed_%"] = {
	mod("BleedFaster", "INC", nil),
},
["base_chance_to_poison_on_hit_%"] = {
	mod("PoisonChance", "BASE", nil),
},
["global_poison_on_hit"] = {
	mod("PoisonChance", "BASE", nil),
	value = 100,
},
["base_chance_to_ignite_%"] = {
	mod("EnemyIgniteChance", "BASE", nil),
},
["base_chance_to_shock_%"] = {
	mod("EnemyShockChance", "BASE", nil),
},
["base_chance_to_freeze_%"] = {
	mod("EnemyFreezeChance", "BASE", nil),
},
["chance_to_freeze_shock_ignite_%"] = {
	mod("EnemyFreezeChance", "BASE", nil),
	mod("EnemyShockChance", "BASE", nil),
	mod("EnemyIgniteChance", "BASE", nil),
},
["additional_chance_to_freeze_chilled_enemies_%"] = {
	mod("EnemyFreezeChance", "BASE", nil, ModFlag.Hit, 0, { type = "ActorCondition", actor = "enemy", var = "Chilled" }),
},
["cannot_inflict_status_ailments"] = {
	flag("CannotShock"),
	flag("CannotChill"),
	flag("CannotFreeze"),
	flag("CannotIgnite"),
},
["chill_effect_+%"] = {
	mod("EnemyChillEffect", "INC", nil),
},
["shock_effect_+%"] = {
	mod("EnemyShockEffect", "INC", nil),
},
["non_damaging_ailment_effect_+%"] = {
	mod("EnemyChillEffect", "INC", nil),
	mod("EnemyShockEffect", "INC", nil),
	mod("EnemyFreezeEffect", "INC", nil),
	mod("EnemyScorchEffect", "INC", nil),
	mod("EnemyBrittleEffect", "INC", nil),
	mod("EnemySapEffect", "INC", nil),
},
["base_poison_duration_+%"] = {
	mod("EnemyPoisonDuration", "INC", nil),
},
["active_skill_poison_duration_+%_final"] = {
	mod("EnemyPoisonDuration", "MORE", nil),
},
["ignite_duration_+%"] = {
	mod("EnemyIgniteDuration", "INC", nil),
},
["shock_duration_+%"] = {
	mod("EnemyShockDuration", "INC", nil),
},
["chill_duration_+%"] = {
	mod("EnemyChillDuration", "INC", nil),
},
["freeze_duration_+%"] = {
	mod("EnemyFreezeDuration", "INC", nil),
},
["base_elemental_status_ailment_duration_+%"] = {
	mod("EnemyIgniteDuration", "INC", nil), 
	mod("EnemyShockDuration", "INC", nil), 
	mod("EnemyChillDuration", "INC", nil), 
	mod("EnemyFreezeDuration", "INC", nil),
	mod("EnemyScorchDuration", "INC", nil),
	mod("EnemyBrittleDuration", "INC", nil),
	mod("EnemySapDuration", "INC", nil),
},
["base_all_ailment_duration_+%"] = {
	mod("EnemyBleedDuration", "INC", nil), 
	mod("EnemyPoisonDuration", "INC", nil), 
	mod("EnemyIgniteDuration", "INC", nil), 
	mod("EnemyShockDuration", "INC", nil), 
	mod("EnemyChillDuration", "INC", nil), 
	mod("EnemyFreezeDuration", "INC", nil),
	mod("EnemyScorchDuration", "INC", nil),
	mod("EnemyBrittleDuration", "INC", nil),
	mod("EnemySapDuration", "INC", nil),
},
["bleeding_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Bleed),
},
["base_poison_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Poison),
},
["critical_poison_dot_multiplier_+"] = {
	mod("DotMultiplier", "BASE", nil, 0, KeywordFlag.Poison, { type = "Condition", var = "CriticalStrike" }),
},
["poison_dot_multiplier_+"] = {
	mod("DotMultiplier", "BASE", nil, 0, KeywordFlag.Poison),
},
["dot_multiplier_+"] = {
	mod("DotMultiplier", "BASE", nil),
},
["fire_dot_multiplier_+"] = {
	mod("FireDotMultiplier", "BASE", nil),
},
["cold_dot_multiplier_+"] = {
	mod("ColdDotMultiplier", "BASE", nil),
},
["active_skill_ignite_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, KeywordFlag.Ignite),
},
["damaging_ailments_deal_damage_+%_faster"] = {
	mod("BleedFaster", "INC", nil),
	mod("PoisonFaster", "INC", nil),
	mod("IgniteBurnFaster", "INC", nil),
},
["active_skill_shock_as_though_damage_+%_final"] = {
	mod("ShockAsThoughDealing", "MORE", nil),
},
["active_skill_chill_as_though_damage_+%_final"] = {
	mod("ChillAsThoughDealing", "MORE", nil),
},
-- Global flags
["never_ignite"] = {
	flag("CannotIgnite"),
},
["never_shock"] = {
	flag("CannotShock"),
},
["never_freeze"] = {
	flag("CannotFreeze"),
},
["cannot_cause_bleeding"] = {
	flag("CannotBleed"),
},
["keystone_strong_bowman"] = {
	flag("IronGrip"),
},
["strong_casting"] = {
	flag("IronWill"),
},
["deal_no_elemental_damage"] = {
	flag("DealNoFire"), 
	flag("DealNoCold"), 
	flag("DealNoLightning"),
},
["base_deal_no_chaos_damage"] = {
	flag("DealNoChaos"),
},
-- Other effects
["enemy_phys_reduction_%_penalty_vs_hit"] = {
	mod("EnemyPhysicalDamageReduction", "BASE", nil),
	mult = -1,
},
["base_stun_threshold_reduction_+%"] = {
	mod("EnemyStunThreshold", "INC", nil),
	mult = -1,
},
["impale_phys_reduction_%_penalty"] = {
	mod("EnemyImpalePhysicalDamageReduction", "BASE", nil),
	mult = -1,
},
["base_stun_duration_+%"] = {
	mod("EnemyStunDuration", "INC", nil),
},
["base_killed_monster_dropped_item_quantity_+%"] = {
	mod("LootQuantity", "INC", nil),
},
["base_killed_monster_dropped_item_rarity_+%"] = {
	mod("LootRarity", "INC", nil),
},
["global_knockback"] = {
	mod("EnemyKnockbackChance", "BASE", nil),
	value = 100,
},
["base_global_chance_to_knockback_%"] = {
	mod("EnemyKnockbackChance", "BASE", nil),
},
["knockback_distance_+%"] = {
	mod("EnemyKnockbackDistance", "INC", nil),
},
["chance_to_be_knocked_back_%"] = {
	mod("SelfKnockbackChance", "BASE", nil),
},
["number_of_additional_curses_allowed"] = {
	mod("EnemyCurseLimit", "BASE", nil),
},
-- Projectiles
["base_projectile_speed_+%"] = {
	mod("ProjectileSpeed", "INC", nil),
},
["projectile_base_number_of_targets_to_pierce"] = {
	mod("PierceCount", "BASE", nil),
},
["arrow_base_number_of_targets_to_pierce"] = {
	mod("PierceCount", "BASE", nil, ModFlag.Attack),
},
["pierce_%"] = {
	mod("PierceChance", "BASE", nil),
},
["always_pierce"] = {
	flag("PierceAllTargets"),
},
["cannot_pierce"] = {
	flag("CannotPierce"),
},
["base_number_of_additional_arrows"] = {
	mod("ProjectileCount", "BASE", nil),
},
["number_of_additional_projectiles"] = {
	mod("ProjectileCount", "BASE", nil),
},
["number_of_chains"] = {
	mod("ChainCountMax", "BASE", nil),
},
["additional_beam_only_chains"] = {
	mod("BeamChainCountMax", "BASE", nil),
},
["projectiles_always_pierce_you"] = {
	flag("AlwaysPierceSelf"),
},
["projectiles_fork"] = {
	flag("ForkOnce"),
	mod("ForkCountMax", "BASE", nil),
},
["number_of_additional_forks_base"] = {
	flag("ForkTwice"),
	mod("ForkCountMax", "BASE", nil),
},
["active_skill_returning_projectile_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, 0, { type = "Condition", var = "ReturningProjectile" }),
},
["returning_projectiles_always_pierce"] = {
	flag("PierceAllTargets", { type = "Condition", var = "ReturningProjectile" }),
},
["support_barrage_attack_time_+%_per_projectile_fired"] = {
	mod("SkillAttackTime", "MORE", nil, 0, 0, { type = "Condition", varList = { "UsingBow", "UsingWand" }}, { type = "PerStat", stat = "ProjectileCount" }),
},
["support_barrage_trap_and_mine_throwing_time_+%_final_per_projectile_fired"] = {
	mod("SkillMineThrowingTime", "MORE", nil, 0, 0, { type = "PerStat", stat = "ProjectileCount" }),
	mod("SkillTrapThrowingTime", "MORE", nil, 0, 0, { type = "PerStat", stat = "ProjectileCount" }),
},
-- Self modifiers
["chance_to_be_pierced_%"] = {
	mod("SelfPierceChance", "BASE", nil),
},
["projectile_damage_taken_+%"] = {
	mod("ProjectileDamageTaken", "INC", nil),
},
["physical_damage_taken_+%"] = {
	mod("PhysicalDamageTaken", "INC", nil),
},
["fire_damage_taken_+%"] = {
	mod("FireDamageTaken", "INC", nil),
},
["cold_damage_taken_+%"] = {
	mod("ColdDamageTaken", "INC", nil),
},
["lightning_damage_taken_+%"] = {
	mod("LightningDamageTaken", "INC", nil),
},
["chaos_damage_taken_+%"] = {
	mod("ChaosDamageTaken", "INC", nil),
},
["base_physical_damage_over_time_taken_+%"] = {
	mod("PhysicalDamageTakenOverTime", "INC", nil),
},
["degen_effect_+%"] = {
	mod("DamageTakenOverTime", "INC", nil),
},
["buff_time_passed_-%"] = {
	mod("BuffExpireFaster", "MORE", nil),
	mult = -1,
},
["additional_chance_to_take_critical_strike_%"] = {
	mod("SelfExtraCritChance", "BASE", nil),
},
["base_self_critical_strike_multiplier_-%"] = {
	mod("SelfCritMultiplier", "INC", nil),
	mult = -1,
},
["chance_to_be_shocked_%"] = {
	mod("SelfShockChance", "BASE", nil),
},
["chance_to_be_ignited_%"] = {
	mod("SelfIgniteChance", "BASE", nil),
},
["chance_to_be_frozen_%"] = {
	mod("SelfFreezeChance", "BASE", nil),
},
["receive_bleeding_chance_%_when_hit_by_attack"] = {
	mod("SelfBleedChance", "BASE", nil),
},
["base_self_shock_duration_-%"] = {
	mod("SelfShockDuration", "INC", nil),
	mult = -1,
},
["base_self_ignite_duration_-%"] = {
	mod("SelfIgniteDuration", "INC", nil),
	mult = -1,
},
["base_self_freeze_duration_-%"] = {
	mod("SelfFreezeDuration", "INC", nil),
	mult = -1,
},
["life_leech_on_any_damage_when_hit_permyriad"] = {
	mod("SelfDamageLifeLeech", "BASE", nil),
},
["mana_leech_on_any_damage_when_hit_permyriad"] = {
	mod("SelfDamageManaLeech", "BASE", nil),
},
["life_granted_when_hit_by_attacks"] = {
	mod("SelfLifeOnHit", "BASE", nil, ModFlag.Attack),
},
["mana_granted_when_hit_by_attacks"] = {
	mod("SelfManaOnHit", "BASE", nil, ModFlag.Attack),
},
["life_granted_when_killed"] = {
	mod("SelfLifeOnKill", "BASE", nil),
},
["mana_granted_when_killed"] = {
	mod("SelfManaOnKill", "BASE", nil),
},
-- Degen
["base_physical_damage_%_of_maximum_life_to_deal_per_minute"] = {
	mod("PhysicalDegen", "BASE", nil, 0, 0, { type = "PerStat", stat = "Life", div = 1 }),
	div = 6000,
},
["base_physical_damage_%_of_maximum_energy_shield_to_deal_per_minute"] = {
	mod("PhysicalDegen", "BASE", nil, 0, 0, { type = "PerStat", stat = "EnergyShield", div = 1 }),
	div = 6000,
},
["base_nonlethal_fire_damage_%_of_maximum_life_taken_per_minute"] = {
	mod("FireDegen", "BASE", nil, 0, 0, { type = "PerStat", stat = "Life", div = 1 }),
	div = 6000,
},
["base_nonlethal_fire_damage_%_of_maximum_energy_shield_taken_per_minute"] = {
	mod("FireDegen", "BASE", nil, 0, 0, { type = "PerStat", stat = "EnergyShield", div = 1 }),
	div = 6000,
},

--
-- Attack modifiers
--
["attack_speed_+%"] = {
	mod("Speed", "INC", nil, ModFlag.Attack),
},
["active_skill_attack_speed_+%_final"] = {
	mod("Speed", "MORE", nil, ModFlag.Attack),
},
["base_attack_speed_+%_per_frenzy_charge"] = {
	mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["accuracy_rating"] = {
	mod("Accuracy", "BASE", nil),
},
["accuracy_rating_+%"] = {
	mod("Accuracy", "INC", nil),
},
["attack_damage_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Attack),
},
["elemental_damage_with_attack_skills_+%"] = {
	mod("ElementalDamage", "INC", nil, 0, KeywordFlag.Attack),
},
["attack_minimum_added_physical_damage"] = {
	mod("PhysicalMin", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_maximum_added_physical_damage"] = {
	mod("PhysicalMax", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_minimum_added_physical_damage_with_weapons"] = {
	mod("PhysicalMin", "BASE", nil, ModFlag.Weapon, KeywordFlag.Attack),
},
["attack_maximum_added_physical_damage_with_weapons"] = {
	mod("PhysicalMax", "BASE", nil, ModFlag.Weapon, KeywordFlag.Attack),
},
["attack_minimum_added_lightning_damage"] = {
	mod("LightningMin", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_maximum_added_lightning_damage"] = {
	mod("LightningMax", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_minimum_added_cold_damage"] = {
	mod("ColdMin", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_maximum_added_cold_damage"] = {
	mod("ColdMax", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_minimum_added_fire_damage"] = {
	mod("FireMin", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_maximum_added_fire_damage"] = {
	mod("FireMax", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_minimum_added_chaos_damage"] = {
	mod("ChaosMin", "BASE", nil, 0, KeywordFlag.Attack),
},
["attack_maximum_added_chaos_damage"] = {
	mod("ChaosMax", "BASE", nil, 0, KeywordFlag.Attack),
},
["melee_weapon_range_+"] = {
	mod("MeleeWeaponRange", "BASE", nil),
},
["melee_range_+"] = {
	mod("MeleeWeaponRange", "BASE", nil),
	mod("UnarmedRange", "BASE", nil),
},
["override_off_hand_base_critical_strike_chance_to_5%"] = {
	skill("setOffHandBaseCritChance", nil),
	value = 5,
},
["off_hand_local_minimum_added_physical_damage"] = {
	skill("setOffHandPhysicalMin", nil),
},
["off_hand_local_maximum_added_physical_damage"] = {
	skill("setOffHandPhysicalMax", nil),
},
["off_hand_base_weapon_attack_duration_ms"] = {
	skill("setOffHandAttackTime", nil),
},
["off_hand_minimum_added_physical_damage_per_15_shield_armour_and_evasion_rating"] = {
	mod("PhysicalMin", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, 	div = 15, }),
},
["off_hand_maximum_added_physical_damage_per_15_shield_armour_and_evasion_rating"] = {
	mod("PhysicalMax", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, 	div = 15, }),
},
["additional_critical_strike_chance_per_10_shield_maximum_energy_shield_permyriad"] = {
	mod("CritChance", "BASE", nil, 0, 0, { type = "PerStat", stat = "EnergyShieldOnWeapon 2", 	div = 10, }),
	div = 100,
},
-- Impale
["attacks_impale_on_hit_%_chance"] = {
    mod("ImpaleChance", "BASE", nil, 0, 0)
},
["impale_debuff_effect_+%"] = {
    mod("ImpaleEffect", "INC", nil, 0, 0)
},
--
-- Spell modifiers
--
["base_cast_speed_+%"] = {
	mod("Speed", "INC", nil, ModFlag.Cast),
},
["active_skill_cast_speed_+%_final"] = {
	mod("Speed", "MORE", nil, ModFlag.Cast),
},
["spell_damage_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Spell),
},
["spell_minimum_added_physical_damage"] = {
	mod("PhysicalMin", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_maximum_added_physical_damage"] = {
	mod("PhysicalMax", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_minimum_added_lightning_damage"] = {
	mod("LightningMin", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_maximum_added_lightning_damage"] = {
	mod("LightningMax", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_minimum_added_cold_damage"] = {
	mod("ColdMin", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_maximum_added_cold_damage"] = {
	mod("ColdMax", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_minimum_added_fire_damage"] = {
	mod("FireMin", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_maximum_added_fire_damage"] = {
	mod("FireMax", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_minimum_added_chaos_damage"] = {
	mod("ChaosMin", "BASE", nil, 0, KeywordFlag.Spell),
},
["spell_maximum_added_chaos_damage"] = {
	mod("ChaosMax", "BASE", nil, 0, KeywordFlag.Spell),
},

--
-- Skill type modifier
--
-- Trap
["trap_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Trap),
},
["number_of_additional_traps_allowed"] = {
	mod("ActiveTrapLimit", "BASE", nil),
},
["trap_throwing_speed_+%"] = {
	mod("TrapThrowingSpeed", "INC", nil),
},
["trap_throwing_speed_+%_per_frenzy_charge"] = {
	mod("TrapThrowingSpeed", "INC", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["trap_critical_strike_multiplier_+_per_power_charge"] = {
	mod("CritMultiplier", "BASE", nil, 0, KeywordFlag.Trap, { type = "Multiplier", var = "PowerCharge" }),
},
["placing_traps_cooldown_recovery_+%"] = {
	mod("CooldownRecovery", "INC", nil, 0, KeywordFlag.Trap),
},
["trap_trigger_radius_+%"] = {
	mod("TrapTriggerAreaOfEffect", "INC", nil),
},
-- Mine
["number_of_additional_remote_mines_allowed"] = {
	mod("ActiveMineLimit", "BASE", nil),
},
["mine_laying_speed_+%"] = {
	mod("MineLayingSpeed", "INC", nil),
},
["mine_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Mine),
},
["mine_detonation_radius_+%"] = {
	mod("MineDetonationAreaOfEffect", "INC", nil),
},
-- Totem
["totem_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Totem),
},
["totem_life_+%"] = {
	mod("TotemLife", "INC", nil),
},
["number_of_additional_totems_allowed"] = {
	mod("ActiveTotemLimit", "BASE", nil),
},
["attack_skills_additional_ballista_totems_allowed"] = {
	mod("ActiveTotemLimit", "BASE", nil, ModFlag.Attack),
},
["base_number_of_totems_allowed"] = {
	mod("ActiveTotemLimit", "BASE", nil),
},
["summon_totem_cast_speed_+%"] = {
	mod("TotemPlacementSpeed", "INC", nil),
},
-- Minion
["minion_damage_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", nil) }),
},
["minion_maximum_life_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Life", "INC", nil) }),
},
["minion_movement_speed_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "INC", nil) }),
},
["minion_attack_speed_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", nil, ModFlag.Attack) }),
},
["minion_cast_speed_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Speed", "INC", nil, ModFlag.Cast) }),
},
["minion_elemental_resistance_%"] = {
	mod("MinionModifier", "LIST", { mod = mod("ElementalResist", "BASE", nil) }),
},
["minion_elemental_resistance_30%"] = {
	mod("MinionModifier", "LIST", { mod = mod("ElementalResist", "BASE", nil) }),
	value=30
},
["summon_fire_resistance_+"] = {
	mod("MinionModifier", "LIST", { mod = mod("FireResist", "BASE", nil) }),
},
["summon_cold_resistance_+"] = {
	mod("MinionModifier", "LIST", { mod = mod("ColdResist", "BASE", nil) }),
},
["summon_lightning_resistance_+"] = {
	mod("MinionModifier", "LIST", { mod = mod("LightningResist", "BASE", nil) }),
},
["minion_maximum_all_elemental_resistances_%"] = {
	mod("MinionModifier", "LIST", { mod = mod("ElementalResistMax", "BASE", nil) }),
},
["base_number_of_zombies_allowed"] = {
	mod("ActiveZombieLimit", "BASE", nil),
},
["base_number_of_skeletons_allowed"] = {
	mod("ActiveSkeletonLimit", "BASE", nil),
},
["base_number_of_raging_spirits_allowed"] = {
	mod("ActiveRagingSpiritLimit", "BASE", nil),
},
["base_number_of_golems_allowed"] = {
	mod("ActiveGolemLimit", "BASE", nil),
},
["base_number_of_champions_of_light_allowed"] = {
    mod("ActiveSentinelOfPurityLimit", "BASE", nil)
},
["base_number_of_spectres_allowed"] = {
	mod("ActiveSpectreLimit", "BASE", nil),
},
["number_of_wolves_allowed"] = {
	mod("ActiveWolfLimit", "BASE", nil),
},
["number_of_spider_minions_allowed"] = {
	mod("ActiveSpiderLimit", "BASE", nil),
},
["active_skill_minion_damage_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "MORE", nil) }),
},
["active_skill_minion_physical_damage_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("PhysicalDamage", "MORE", nil) }),
},
["active_skill_minion_life_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("Life", "MORE", nil) }),
},
["active_skill_minion_energy_shield_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("EnergyShield", "MORE", nil) }),
},
["active_skill_minion_movement_velocity_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "MORE", nil) }),
},
-- Curse
["curse_effect_+%"] = {
	mod("CurseEffect", "INC", nil),
},
["curse_effect_+%_vs_players"] = {
	mod("CurseEffectAgainstPlayer", "INC", nil),
},
["curse_area_of_effect_+%"] = {
	mod("AreaOfEffect", "INC", nil, 0, KeywordFlag.Curse),
},
["base_curse_duration_+%"] = {
	mod("Duration", "INC", nil, 0, KeywordFlag.Curse),
},
-- Aura
["non_curse_aura_effect_+%"] = {
	mod("AuraEffect", "INC", nil),
},
-- Brand
["sigil_attached_target_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, 0, { type = "MultiplierThreshold", var = "BrandsAttachedToEnemy", threshold = 1 }),
},
["base_number_of_sigils_allowed_per_target"] = {
	mod("BrandsAttachedLimit", "BASE", nil)
},
["base_sigil_repeat_frequency_ms"] = {
	skill("repeatFrequency", nil),
	div = 1000,
},
["sigil_repeat_frequency_+%"] = {
	mod("BrandActivationFrequency", "INC", nil)
},
-- Banner
["banner_buff_effect_+%_per_stage"] = {
	mod("AuraEffect", "INC", nil, 0, 0, { type = "Multiplier", var = "BannerStage" }, { type = "Condition", var = "BannerPlanted" }),
},
["banner_area_of_effect_+%_per_stage"] = {
	mod("AreaOfEffect", "INC", nil, 0, 0, { type = "Multiplier", var = "BannerStage" }, { type = "Condition", var = "BannerPlanted" }),
},
-- Other
["triggered_skill_damage_+%"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.Triggered }),
},
["channelled_skill_damage_+%"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.Channelled }),
},
["snipe_triggered_skill_hit_damage_+%_final_per_stage"] = {
	mod("Damage", "MORE", nil, ModFlag.Hit, 0, { type = "Multiplier", var = "SnipeStage" }),
},
["snipe_triggered_skill_ailment_damage_+%_final_per_stage"] = {
	mod("Damage", "MORE", nil, ModFlag.Ailment, 0, { type = "Multiplier", var = "SnipeStage" }),
},

}