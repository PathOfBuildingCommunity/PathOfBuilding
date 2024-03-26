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
["base_tertiary_skill_effect_duration"] = {
	skill("durationTertiary", nil),
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
["base_physical_damage_to_deal_per_minute"] = {
	skill("PhysicalDot", nil),
	div = 60,
},
["critical_ailment_dot_multiplier_+"] = {
	mod("DotMultiplier", "BASE", nil, 0, 0, {type = "Condition", var = "CriticalStrike"})
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
["cannot_poison_poisoned_enemies"] = {
	flag("Condition:SinglePoison"),
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
["skill_buff_effect_+%"] = {
	mod("BuffEffect", "INC", nil)
},
["base_skill_reserve_life_instead_of_mana"] = {
	flag("BloodMagicReserved"),
},
["base_skill_cost_life_instead_of_mana"] = {
	flag("CostLifeInsteadOfMana"),
},
["base_skill_cost_life_instead_of_mana_%"] = {
	mod("HybridManaAndLifeCost_Life", "BASE", nil),
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
	skill("triggeredByMjolner", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Lightning }),
},
["unique_cospris_malice_cold_spells_triggered"] = {
	skill("triggeredByCospris", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }, { type = "SkillType", skillType = SkillType.Cold }),
	skill("triggerOnCrit", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }, { type = "SkillType", skillType = SkillType.Cold }),
},
["skill_has_trigger_from_unique_item"] = {
	skill("triggeredByUnique", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["skill_triggered_when_you_focus_chance_%"] = {
	skill("chanceToTriggerOnFocus", nil, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
	div = 100,
},
["spell_has_trigger_from_crafted_item_mod"] = {
	skill("triggeredByCraft", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
["support_cast_on_mana_spent"] = {
	skill("triggeredByKitavaThirst", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
["cast_when_cast_curse_%"] = {
	skill("chanceToTriggerCurseOnCurse", nil, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Hex }),
},
["display_mirage_warriors_no_spirit_strikes"] = {
	skill("triggeredBySaviour", true, { type = "SkillType", skillType = SkillType.Attack } ),
},
["cast_spell_on_linked_attack_crit"] = {
	skill("triggeredByCoc", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
	skill("triggerOnCrit", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
["cast_linked_spells_on_attack_crit_%"] = {
	skill("chanceToTriggerOnCrit", nil, { type = "SkillType", skillType = SkillType.Attack }),
},
["cast_spell_on_linked_melee_kill"] = {
	skill("triggeredByMeleeKill", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }, { type = "Condition", var = "KilledRecently" }),
},
["cast_linked_spells_on_melee_kill_%"] = {
	skill("chanceToTriggerOnMeleeKill", nil , { type = "SkillType", skillType = SkillType.Attack }, { type = "SkillType", skillType = SkillType.Melee })
},
["cast_spell_while_linked_skill_channelling"] = {
	skill("triggeredWhileChannelling", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
["skill_triggered_by_snipe"] = {
	skill("triggeredBySnipe", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["triggered_by_spiritual_cry"] = {
	skill("triggeredByGeneralsCry", true, { type = "SkillType", skillType = SkillType.Melee }, { type = "SkillType", skillType = SkillType.Attack }),
},
["cast_on_damage_taken_threshold"] = {
	skill("triggeredByDamageTaken", nil, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
["cast_on_stunned_%"] = {
	skill("chanceToTriggerOnStun", nil, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
["trigger_on_attack_hit_against_rare_or_unique"] = {
	skill("triggerMarkOnRareOrUnique", true, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Mark }),
},
["melee_counterattack_trigger_on_block_%"] = {
	skill("chanceToTriggerCounterattackOnBlock", nil, { type = "SkillType", skillType = SkillType.Attack }, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["melee_counterattack_trigger_on_hit_%"] = {
	skill("chanceToTriggerCounterAttackOnHit", nil, { type = "SkillType", skillType = SkillType.Attack }, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["holy_relic_trigger_on_parent_attack_%"] = {
	skill("chanceToTriggerOnParentAttack", true, { type = "SkillType", skillType = SkillType.Triggerable }),
},
["skill_can_own_mirage_archers"] = {
	skill("triggeredByMirageArcher", true, { type = "SkillType", skillType = SkillType.MirageArcherCanUse }),
},
["skill_can_own_sacred_wisps"] = {
	skill("triggeredBySacredWisp", true, { type = "SkillType", skillType = SkillType.SacredWispsCanUse }),
},
["skill_double_hits_when_dual_wielding"] = {
	skill("doubleHitsWhenDualWielding", true),
},
["base_spell_repeat_count"] = {
	mod("RepeatCount", "BASE", nil, 0, 0, {type = "SkillType", skillType = SkillType.Multicastable }),
},
["base_melee_attack_repeat_count"] = {
	mod("RepeatCount", "BASE", nil, 0, 0, { type = "SkillType", skillType = SkillType.Multistrikeable }),
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
["corpse_explosion_monster_life_%"] = {
	skill("corpseExplosionLifeMultiplier", nil),
	div = 100,
},
["corpse_explosion_monster_life_permillage_fire"] = {
	skill("corpseExplosionLifeMultiplier", nil),
	div = 1000,
},
["spell_base_fire_damage_%_maximum_life"] = {
	skill("selfFireExplosionLifeMultiplier", nil),
	div = 100,
},
-- for some reason DeathWish adds another stat with same effect as above
["skill_minion_explosion_life_%"] = {
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
["skill_cannot_gain_repeat_bonuses"] = {
	flag("NoRepeatBonuses"),
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
["base_mana_cost_+"] = {
	mod("ManaCostNoMult", "BASE", nil),
},
["no_mana_cost"] = {
	mod("ManaCost", "MORE", nil),
	value = -100,
},
["base_life_cost_+%"] = {
	mod("LifeCost", "INC", nil),
},
["flask_mana_to_recover_+%"] = {
	mod("FlaskManaRecovery", "INC", nil),
},
["flask_effect_+%"] = {
	mod("FlaskEffect", "INC", nil),
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
["base_block_%_damage_taken"] = {
	mod("BlockEffect", "BASE", nil)
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
["base_mana_leech_from_elemental_damage_permyriad"] = {
	mod("ElementalDamageManaLeech", "BASE", nil),
	div = 100,
},
["base_life_leech_from_attack_damage_permyriad"] = {
	mod("DamageLifeLeech", "BASE", nil, ModFlag.Attack),
	div = 100,
},
["base_life_leech_from_chaos_damage_permyriad"] = {
	mod("ChaosDamageLifeLeech", "BASE", nil),
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
["maximum_life_leech_amount_per_leech_+%"] = {
	mod("MaxLifeLeechRate", "INC", nil)
},
["maximum_energy_shield_leech_amount_per_leech_+%"] = {
	mod("MaxEnergyShieldLeechRate", "INC", nil)
},
["mana_gain_per_target"] = {
	mod("ManaOnHit", "BASE", nil)
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
	mod("ElusiveEffect", "MAX", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }),
},
["blind_effect_+%"] = {
	mod("BlindEffect", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Debuff", effectName = "Vaal Blade Flurry" }),
},
["cannot_be_stunned_while_leeching"] = {
	mod("AvoidStun", "BASE", 100, { type = "Condition", var = "Leeching"}),
},
["base_avoid_stun_%"] = {
	mod("AvoidStun", "BASE", nil),
},
["avoid_interruption_while_using_this_skill_%"] = {
	mod("AvoidInterruptStun", "BASE", nil)
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
["attack_speed_+%_with_atleast_20_rage"] = {
	mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "MultiplierThreshold", var = "Rage", threshold = 20 })
},
["base_cooldown_speed_+%"] = {
	mod("CooldownRecovery", "INC", nil),
},
["base_spell_cooldown_speed_+%"] = {
	mod("CooldownRecovery", "INC", nil),
},
["base_cooldown_modifier_ms"] = {
	mod("CooldownRecovery", "BASE", nil),
	div = 1000,
},
["additional_weapon_base_attack_time_ms"] = {
	mod("Speed", "BASE", nil, ModFlag.Attack),
	div = 1000,
},
["warcry_speed_+%"] = {
	mod("WarcrySpeed", "INC", nil, 0, KeywordFlag.Warcry),
},
["display_this_skill_cooldown_does_not_recover_during_buff"] = {
	flag("NoCooldownRecoveryInDuration"),
},
-- AoE
["active_skill_base_area_of_effect_radius"] = {
	skill("radius", nil),
},
["active_skill_base_secondary_area_of_effect_radius"] = {
	skill("radiusSecondary", nil),
},
["active_skill_base_tertiary_area_of_effect_radius"] = {
	skill("radiusTertiary", nil),
},
["active_skill_base_radius_+"] = {
	skill("radiusExtra", nil),
},
["base_skill_area_of_effect_+%"] = {
	mod("AreaOfEffect", "INC", nil),
},
["base_aura_area_of_effect_+%"] = {
	mod("AreaOfEffect", "INC", nil, 0, KeywordFlag.Aura),
},
["area_of_effect_+%_while_not_dual_wielding"] = {
	mod("AreaOfEffect", "INC", nil, 0, 0, { type = "Condition", var = "DualWielding", neg = true })
},
["active_skill_area_of_effect_+%_final_when_cast_on_frostbolt"] = {
	mod("AreaOfEffect", "MORE", nil, 0, 0, { type = "Condition", var = "CastOnFrostbolt" }),
},
["active_skill_area_of_effect_radius_+%_final"] = {
	mod("AreaOfEffect", "MORE", nil),
},
["active_skill_area_of_effect_+%_final"] = {
	mod("AreaOfEffect", "MORE", nil),
},
["area_of_effect_+%_per_50_strength"] = {
	skill("AreaOfEffect", nil, { type = "PerStat", stat = "Str", div = 50 }),
},
["active_skill_area_of_effect_+%_final_per_endurance_charge"] = {
	mod("AreaOfEffect", "MORE", nil, 0, 0, { type = "Multiplier", var = "EnduranceCharge" }),
},
["skill_area_of_effect_+%_final_in_sand_stance"] = {
	mod("AreaOfEffect", "MORE", nil, 0, 0, { type = "Condition", var = "SandStance" }),
},
["area_of_effect_+%_final_per_removable_power_frenzy_or_endurance_charge"] = {
	mod("AreaOfEffect", "MORE", nil, ModFlag.Spell, 0, { type = "Multiplier", var = "RemovableTotalCharges" }),
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
["critical_multiplier_+%_per_100_max_es_on_shield"] = {
	mod("CritMultiplier", "BASE", nil, 0, 0, { type = "PerStat", div = 100, stat = "EnergyShieldOnWeapon 2" }),
},
["critical_strike_multiplier_+_if_dexterity_higher_than_intelligence"] = {
	skill("CritMultiplier", nil, { type = "Condition", var = "DexHigherThanInt" }),
},
["damage_+%_per_endurance_charge"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Multiplier", var = "EnduranceCharge" }),
},
["active_skill_attack_damage_+%_final_per_endurance_charge"] = {
	mod("Damage", "MORE", nil, ModFlag.Attack, 0, { type = "Multiplier", var = "EnduranceCharge" }),
},
["attack_damage_+%_per_450_physical_damage_reduction_rating"] = {
	mod("Damage", "INC", nil, ModFlag.Attack, 0, { type = "PerStat", stat = "Armour", div = 450 }),
},
["attack_damage_+%_per_450_evasion"] = {
	mod("Damage", "INC", nil, ModFlag.Attack, 0, { type = "PerStat", stat = "Evasion", div = 450 }),
},
["damage_+%_per_frenzy_charge"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["additional_critical_strike_chance_permyriad_while_affected_by_elusive"] = {
	mod("CritChance", "BASE", nil, 0, 0, { type = "Condition", var = "Elusive" }, { type = "Condition", varList = { "UsingClaw", "UsingDagger"} }, { type = "Condition", varList = { "UsingSword", "UsingAxe", "UsingMace" }, neg = true} ),
	div = 100,
},
["nightblade_elusive_grants_critical_strike_multiplier_+_to_supported_skills"] = {
	mod("NightbladeElusiveCritMultiplier", "BASE", nil, 0, 0, { type = "Condition", varList = { "UsingClaw", "UsingDagger" } }, { type = "Condition", varList = { "UsingSword", "UsingAxe", "UsingMace" }, neg = true} ),
},
["critical_strike_chance_against_enemies_on_full_life_+%"] = {
	mod("CritChance", "INC", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "FullLife" })
},
["critical_strike_chance_+%_vs_blinded_enemies"] = {
	mod("CritChance", "INC", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Blinded"})
},
["no_critical_strike_multiplier"] = {
	flag("NoCritMultiplier"),
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
["secondary_skill_effect_duration_+%"] = {
	mod("SecondaryDuration", "INC", nil),
},
["offering_skill_effect_duration_per_corpse"] = {
	mod("PrimaryDuration", "BASE", nil, 0, 0, { type = "Multiplier", var = "CorpseConsumedRecently", limit = 4 }),
	div = 1000,
},
["modifiers_to_skill_effect_duration_also_affect_soul_prevention_duration"] = {
	skill("skillEffectAppliesToSoulGainPrevention", true),
},
["modifiers_to_buff_effect_duration_also_affect_soul_prevention_duration"] = {
	skill("skillEffectAppliesToSoulGainPrevention", true),
},
["active_skill_quality_duration_+%_final"] = {
	mod("Duration", "MORE", nil),
},
["fortify_duration_+%"] = {
	mod("FortifyDuration", "INC", nil),
},
["support_swift_affliction_skill_effect_and_damaging_ailment_duration_+%_final"] = {
	mod("SkillAndDamagingAilmentDuration", "MORE", nil),
},
["base_bleed_duration_+%"] = {
	mod("EnemyBleedDuration", "INC", nil),
},
-- Damage
["damage_+%"] = {
	mod("Damage", "INC", nil),
},
["chance_for_extra_damage_roll_%"] = {
	mod("LuckyHitsChance", "BASE", nil)
},
["chance_to_deal_double_damage_%"] = {
	mod("DoubleDamageChance", "BASE", nil)
},
["chance_to_deal_double_damage_%_vs_bleeding_enemies"] = {
	mod("DoubleDamageChance", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Bleeding"}),
},
["base_chance_to_deal_triple_damage_%"] = {
	mod("TripleDamageChance", "BASE", nil)
},
["damage_+%_with_hits_and_ailments"] = {
	mod("Damage", "INC", nil, 0, bit.bor(KeywordFlag.Hit, KeywordFlag.Ailment)),
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
["faster_burn_%"] = {
	mod("IgniteBurnFaster", "INC", nil)
},
["faster_poison_%"] = {
	mod("PoisonFaster", "INC", nil)
},
["active_skill_damage_+%_final"] = {
	mod("Damage", "MORE", nil),
},
["sigil_attached_target_hit_damage_+%_final"] = {
	mod("Damage", "MORE", nil, ModFlag.Hit, 0, { type = "Condition", var = "TargetingBrandedEnemy"}),
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
["reduce_enemy_chaos_resistance_%"] = {
	mod("ChaosPenetration", "BASE", nil),
},
["reduce_enemy_elemental_resistance_%"] = {
	mod("ElementalPenetration", "BASE", nil),
},
["base_penetrate_elemental_resistances_%"] = {
	mod("ElementalPenetration", "BASE", nil),
},
["treat_enemy_resistances_as_negated_on_elemental_damage_hit_%_chance"] = {
	mod("HitsInvertEleResChance", "CHANCE", nil),
	div = 100,
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
["minimum_added_fire_damage_vs_ignited_enemies"] = {
	mod("FireMin", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Ignited" }),
},
["maximum_added_fire_damage_vs_ignited_enemies"] = {
	mod("FireMax", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Ignited" }),
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
["added_damage_+%_final"] = {
	mod("AddedDamage", "MORE", nil),
},
["active_skill_added_damage_+%_final"] = {
	mod("AddedDamage", "MORE", nil),
},
["shield_charge_damage_+%_maximum"] = {
	mod("Damage", "MORE", nil, ModFlag.Hit, 0, { type = "DistanceRamp", ramp = {{0,0},{60,1}} }),
},
["damage_+%_on_full_energy_shield"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "FullEnergyShield"})
},
["damage_+%_when_on_low_life"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "LowLife"})
},
["damage_vs_enemies_on_low_life_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Hit, 0, { type = "ActorCondition", actor = "enemy", var = "LowLife"})
},
["damage_+%_when_on_full_life"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "FullLife"})
},
["damage_+%_vs_enemies_on_full_life"] = {
	mod("Damage", "INC", nil, 0, bit.bor(KeywordFlag.Hit, KeywordFlag.Ailment), {type = "ActorCondition", actor = "enemy", var = "FullLife"})
},
["hit_damage_+%"] = {
	mod("Damage", "INC", nil, ModFlag.Hit)
},
["active_skill_damage_+%_final_when_cast_on_frostbolt"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "CastOnFrostbolt" }),
},
["active_skill_merged_damage_+%_final_while_dual_wielding"] = {
	mod("Damage", "MORE", nil, 0, 0, { type = "Condition", var = "DualWielding" }),
},
["active_skill_additive_minion_damage_modifiers_apply_to_all_damage_at_%_value"] = {
	flag("MinionDamageAppliesToPlayer"),
	mod("ImprovedMinionDamageAppliesToPlayer", "MAX", nil)
},
["active_skill_main_hand_weapon_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, 0, { type = "Condition", var = "MainHandAttack" }),
},
["physical_weapon_damage_+%_per_10_str"] = {
	mod("PhysicalDamage", "INC", nil, ModFlag.Weapon, 0, { type = "PerStat", stat = "Str", div = 10 }),
},
-- PvP Damage
["support_makes_skill_mine_pvp_damage_+%_final"] = {
	mod("PvpDamageMultiplier", "MORE", nil),
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
["fire_damage_%_to_add_as_chaos"] = {
	mod("FireDamageGainAsChaos", "BASE", nil),
},
["lightning_damage_%_to_add_as_chaos"] = {
	mod("LightningDamageGainAsChaos", "BASE", nil),
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
-- Skill Physical
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
-- Skill Lightning Conversion
["skill_lightning_damage_%_to_convert_to_chaos"] = {
	mod("SkillLightningDamageConvertToChaos", "BASE", nil),
},
["skill_lightning_damage_%_to_convert_to_fire"] = {
	mod("SkillLightningDamageConvertToFire", "BASE", nil),
},
["skill_lightning_damage_%_to_convert_to_cold"] = {
	mod("SkillLightningDamageConvertToCold", "BASE", nil),
},
-- Skill Cold Conversion
["skill_cold_damage_%_to_convert_to_fire"] = {
	mod("SkillColdDamageConvertToFire", "BASE", nil),
},
["skill_cold_damage_%_to_convert_to_chaos"] = {
	mod("SkillColdDamageConvertToChaos", "BASE", nil),
},
["skill_fire_damage_%_to_convert_to_chaos"] = {
	mod("SkillFireDamageConvertToChaos", "BASE", nil),
},
["skill_convert_%_physical_damage_to_random_element"] = {
	mod("PhysicalDamageConvertToRandom", "BASE", nil)
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
["chance_to_bleed_on_hit_%_chance_in_blood_stance"] = {
	mod("BleedChance", "BASE", nil, ModFlag.Attack, 0, { type = "Condition", var = "BloodStance" }),
},
["chance_to_bleed_on_hit_%_vs_maimed"] = {
	mod("BleedChance", "BASE", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "Maimed" })
},
["faster_bleed_%"] = {
	mod("BleedFaster", "INC", nil),
},
["bleeding_stacks_up_to_x_times"] = {
	mod("BleedStacksMax", "OVERRIDE", nil)
},
["base_ailment_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Ailment)
},
["active_skill_ailment_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, KeywordFlag.Ailment),
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
["always_ignite"] = {
	mod("EnemyIgniteChance", "BASE", nil),
	value = 100,
},
["base_chance_to_shock_%"] = {
	mod("EnemyShockChance", "BASE", nil),
},
["always_shock"] = {
	mod("EnemyShockChance", "BASE", nil),
	value = 100,
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
["chance_to_scorch_%"] = {
	mod("EnemyScorchChance", "BASE", nil)
},
["cannot_inflict_status_ailments"] = {
	flag("CannotShock"),
	flag("CannotChill"),
	flag("CannotFreeze"),
	flag("CannotIgnite"),
	flag("CannotScorch"),
	flag("CannotBrittle"),
	flag("CannotSap"),
},
["lightning_damage_cannot_shock"] = {
	flag("LightningCannotShock"),
},
["chill_effect_+%"] = {
	mod("EnemyChillEffect", "INC", nil),
},
["chill_effect_+%_final"] = {
	mod("EnemyChillEffect", "MORE", nil),
},
["shock_effect_+%"] = {
	mod("EnemyShockEffect", "INC", nil),
},
["active_skill_shock_effect_+%_final"] = {
	mod("EnemyShockEffect", "MORE", nil),
},
["non_damaging_ailment_effect_+%"] = {
	mod("EnemyChillEffect", "INC", nil),
	mod("EnemyShockEffect", "INC", nil),
	mod("EnemyFreezeEffect", "INC", nil),
	mod("EnemyScorchEffect", "INC", nil),
	mod("EnemyBrittleEffect", "INC", nil),
	mod("EnemySapEffect", "INC", nil),
},
["lightning_ailment_effect_+%"] = {
	mod("EnemyShockEffect", "INC", nil),
	mod("EnemySapEffect", "INC", nil),
},
["cold_ailment_duration_+%"] = {
	mod("EnemyChillDuration", "INC", nil),
	mod("EnemyFreezeDuration", "INC", nil),
	mod("EnemyBrittleDuration", "INC", nil),
},
["chill_and_freeze_duration_+%"] = {
	mod("EnemyChillDuration", "INC", nil),
	mod("EnemyFreezeDuration", "INC", nil),
},
["cold_ailment_effect_+%"] = {
	mod("EnemyChillEffect", "INC", nil),
	mod("EnemyFreezeEffect", "INC", nil),
	mod("EnemyBrittleEffect", "INC", nil),
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
["lightning_ailment_duration_+%"] = {
	mod("EnemyShockDuration", "INC", nil),
	mod("EnemySapDuration", "INC", nil),
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
["active_skill_freeze_duration_+%_final"] = {
	mod("EnemyFreezeDuration", "MORE", nil),
},
["base_elemental_status_ailment_duration_+%"] = {
	mod("EnemyElementalAilmentDuration", "INC", nil),
},
["base_all_ailment_duration_+%"] = {
	mod("EnemyAilmentDuration", "INC", nil),
},
["bleeding_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Bleed),
},
["active_skill_bleeding_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, KeywordFlag.Bleed),
},
["active_skill_bleeding_damage_+%_final_in_blood_stance"] = {
	mod("Damage", "MORE", nil, 0, KeywordFlag.Bleed, { type = "Condition", var = "BloodStance" }),
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
["chaos_dot_multiplier_+"] = {
	mod("ChaosDotMultiplier", "BASE", nil),
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
["ailment_damage_+%_per_frenzy_charge"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Ailment, { type = "Multiplier", var = "FrenzyCharge"})
},
["freeze_as_though_dealt_damage_+%"] = {
	mod("FreezeAsThoughDealing", "MORE", nil),
},
["shock_maximum_magnitude_+"] = {
	mod("ShockMax", "BASE", nil),
},
["shock_minimum_damage_taken_increase_%+"] = {
	mod("ShockMinimum", "BASE", nil),
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
["never_chill"] = {
	flag("CannotChill"),
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
["all_damage_can_ignite"] = {
	flag("PhysicalCanIgnite"),
	flag("LightningCanIgnite"),
	flag("ColdCanIgnite"),
	flag("ChaosCanIgnite"),
},
["all_damage_can_freeze"] = {
	flag("PhysicalCanFreeze"),
	flag("LightningCanFreeze"),
	flag("FireCanFreeze"),
	flag("ChaosCanFreeze"),
},
["all_damage_can_shock"] = {
	flag("PhysicalCanShock"),
	flag("ColdCanShock"),
	flag("FireCanShock"),
	flag("ChaosCanShock"),
},
["all_damage_can_ignite_freeze_shock"] = {
	flag("PhysicalCanIgnite"),
	flag("LightningCanIgnite"),
	flag("ColdCanIgnite"),
	flag("ChaosCanIgnite"),
	flag("PhysicalCanFreeze"),
	flag("LightningCanFreeze"),
	flag("FireCanFreeze"),
	flag("ChaosCanFreeze"),
	flag("PhysicalCanShock"),
	flag("ColdCanShock"),
	flag("FireCanShock"),
	flag("ChaosCanShock"),
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
["stun_duration_+%_vs_enemies_that_are_on_full_life"] = {
	mod("EnemyStunDuration", "INC", nil, 0, 0, { type = "ActorCondition", actor = "enemy", var = "FullLife" }),
},
["chance_to_double_stun_duration_%"] = {
	mod("DoubleEnemyStunDurationChance", "BASE", nil),
},
["stun_threshold_+%"] = {
	mod("StunThreshold", "INC", nil),
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
["consecrated_ground_enemy_damage_taken_+%"] = {
	mod("DamageTakenConsecratedGround", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "OnConsecratedGround" }),
},
["consecrated_ground_effect_+%"] = {
	mod("ConsecratedGroundEffect", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff" }),
},
["base_inflict_cold_exposure_on_hit_%_chance"] = {
	mod("ColdExposureChance", "BASE", nil),
},
["base_inflict_lightning_exposure_on_hit_%_chance"] = {
	mod("LightningExposureChance", "BASE", nil),
},
["base_inflict_fire_exposure_on_hit_%_chance"] = {
	mod("FireExposureChance", "BASE", nil),
},
["offering_spells_effect_+%"] = {
	mod("BuffEffect", "INC", nil),
},
["link_buff_effect_on_self_+%"] = {
	mod("LinkEffectOnSelf", "INC", nil),
},
-- Projectiles
["base_projectile_speed_+%"] = {
	mod("ProjectileSpeed", "INC", nil),
},
["base_arrow_speed_+%"] = {
	mod("ProjectileSpeed", "INC", nil),
},
["active_skill_projectile_speed_+%_final"] = {
	mod("ProjectileSpeed", "MORE", nil),
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
["projectile_damage_+%_if_pierced_enemy"] = {
	mod("Damage", "INC", nil, ModFlag.Projectile, 0, { type = "StatThreshold", stat = "PiercedCount", threshold = 1 }),
},
["projectile_damage_+%_final_if_pierced_enemy"] = {
	mod("Damage", "MORE", nil, ModFlag.Projectile, 0, { type = "StatThreshold", stat = "PiercedCount", threshold = 1 }),
},
["projectile_behaviour_only_explode"] = {
	flag("CannotSplit"),
},
["projectile_number_to_split"] = {
	mod("SplitCount", "BASE")
},
["modifiers_to_number_of_projectiles_instead_apply_to_splitting"] = {
	flag("NoAdditionalProjectiles"),
	flag("AdditionalProjectilesAddSplitsInstead")
},
["active_skill_beam_splits_instead_of_chaining"] = {
	flag("NoAdditionalChains"),
	flag("AdditionalChainsAddSplitsInstead")
},
["modifiers_to_projectile_count_do_not_apply"] = {
	flag("NoAdditionalProjectiles"),
},
["base_number_of_arrows"] = {
	mod("ProjectileCount", "BASE", nil),
	base = -1,
},
["number_of_additional_arrows"] = {
	mod("ProjectileCount", "BASE", nil),
},
["base_number_of_projectiles"] = {
	mod("ProjectileCount", "BASE", nil),
	base = -1,
},
["number_of_additional_projectiles"] = {
	mod("ProjectileCount", "BASE", nil),
},
["projectile_damage_+%_per_remaining_chain"] = {
	mod("Damage", "INC", nil, ModFlag.Projectile, 0, { type = "PerStat", stat = "ChainRemaining" }),
	mod("Damage", "INC", nil, ModFlag.Ailment, 0, { type = "PerStat", stat = "ChainRemaining" }),
},
["number_of_chains"] = {
	mod("ChainCountMax", "BASE", nil),
},
["additional_beam_only_chains"] = {
	mod("BeamChainCountMax", "BASE", nil),
},
["damage_+%_per_chain"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "PerStat", stat = "Chain" }),
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
["enemies_you_shock_take_%_increased_physical_damage"] = {
	mod("PhysicalDamageTaken", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Debuff" }, { type = "Condition", var = "Shocked" }),
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
["trauma_strike_self_damage_per_trauma"] = {
	mod("TraumaSelfDamageTakenLife", "BASE", nil),
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
["attack_speed_+%_when_on_low_life"] = {
	mod("Speed", "INC", nil, ModFlag.Attack, 0, { type = "Condition", var = "LowLife"})
},
["damage_+%_per_power_charge"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Multiplier", var = "PowerCharge" })
},
["accuracy_rating"] = {
	mod("Accuracy", "BASE", nil),
},
["accuracy_rating_+%"] = {
	mod("Accuracy", "INC", nil),
},
["accuracy_rating_+%_when_on_low_life"] = {
	mod("Accuracy", "INC", nil, 0, 0, { type = "Condition", var = "LowLife"})
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
["attack_skills_have_added_lightning_damage_equal_to_%_of_maximum_mana"] = {
	mod("LightningMin", "BASE", nil, ModFlag.Attack, 0, { type = "PercentStat", stat = "Mana", percent = 1 }),
	mod("LightningMax", "BASE", nil, ModFlag.Attack, 0, { type = "PercentStat", stat = "Mana", percent = 1 }),
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
["off_hand_local_minimum_added_cold_damage"] = {
	skill("setOffHandColdMin", nil),
},
["off_hand_local_maximum_added_cold_damage"] = {
	skill("setOffHandColdMax", nil),
},
["off_hand_local_minimum_added_fire_damage"] = {
	skill("setOffHandFireMin", nil),
},
["off_hand_local_maximum_added_fire_damage"] = {
	skill("setOffHandFireMax", nil),
},
["off_hand_base_weapon_attack_duration_ms"] = {
	skill("setOffHandAttackTime", nil),
},
["off_hand_minimum_added_physical_damage_per_15_shield_armour_and_evasion_rating"] = {
	mod("PhysicalMin", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "Condition", var = "ShieldThrowCrushNoArmourEvasion", neg = true }, { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, div = 15, }),
},
["off_hand_maximum_added_physical_damage_per_15_shield_armour_and_evasion_rating"] = {
	mod("PhysicalMax", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "Condition", var = "ShieldThrowCrushNoArmourEvasion", neg = true }, { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, div = 15, }),
},
["off_hand_minimum_added_cold_damage_per_15_shield_evasion"] = {
	mod("ColdMin", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", stat = "EvasionOnWeapon 2", div = 15 }),
},
["off_hand_maximum_added_cold_damage_per_15_shield_evasion"] = {
	mod("ColdMax", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", stat = "EvasionOnWeapon 2", div = 15 }),
},
["off_hand_minimum_added_fire_damage_per_15_shield_armour"] = {
	mod("FireMin", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", stat = "ArmourOnWeapon 2", div = 15 }),
},
["off_hand_maximum_added_fire_damage_per_15_shield_armour"] = {
	mod("FireMax", "BASE", nil, 0, 0, { type = "Condition", var = "OffHandAttack" }, { type = "PerStat", stat = "ArmourOnWeapon 2", div = 15 }),
},
["additional_critical_strike_chance_per_10_shield_maximum_energy_shield_permyriad"] = {
	mod("CritChance", "BASE", nil, 0, 0, { type = "PerStat", stat = "EnergyShieldOnWeapon 2", div = 10, }),
	div = 100,
},
-- Impale
["attacks_impale_on_hit_%_chance"] = {
    mod("ImpaleChance", "BASE", nil, 0, KeywordFlag.Attack)
},
["impale_on_hit_%_chance"] = {
    mod("ImpaleChance", "BASE", nil, 0, 0)
},
["spells_impale_on_hit_%_chance"] = {
    mod("ImpaleChance", "BASE", nil, 0, KeywordFlag.Spell)
},
["impale_debuff_effect_+%"] = {
	mod("ImpaleEffect", "INC", nil)
},
["spell_impale_on_crit_%_chance"] = {
	mod("ImpaleChance", "BASE", nil, ModFlag.Spell, 0, { type = "Condition", var = "CriticalStrike" })
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
["spell_damage_+%_per_10_int"] = {
	skill("Damage", nil, ModFlag.Spell, 0, { type = "PerStat", stat = "Int", div = 10 }),
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
["support_trap_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, KeywordFlag.Trap),
},
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
["active_skill_trap_throwing_speed_+%_final"] = {
	mod("TrapThrowingSpeed", "MORE", nil),
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
["mine_throwing_speed_+%_per_frenzy_charge"] = {
	mod("MineLayingSpeed", "INC", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["mine_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Mine),
},
["mine_detonation_radius_+%"] = {
	mod("MineDetonationAreaOfEffect", "INC", nil),
},
["mine_throwing_speed_+%_per_frenzy_charge"] = {
	mod("MineLayingSpeed", "INC", nil, 0, 0, { type = "Multiplier", var = "FrenzyCharge" }),
},
["remote_mined_by_support"] = {
	flag("ManaCostGainAsReservation"),
	flag("LifeCostGainAsReservation"),
},
["mine_critical_strike_chance_+%_per_power_charge"] = {
	mod("CritChance", "INC", nil, 0, KeywordFlag.Mine, { type = "Multiplier", var = "PowerCharge" }),
},
["mine_projectile_speed_+%_per_frenzy_charge"] = {
	mod("ProjectileSpeed", "INC", nil, 0, KeywordFlag.Mine, { type = "Multiplier", var = "FrenzyCharge" })
},
-- Totem
["totem_damage_+%"] = {
	mod("Damage", "INC", nil, 0, KeywordFlag.Totem),
},
["totem_life_+%"] = {
	mod("TotemLife", "INC", nil),
},
["totem_life_+%_final"] = {
	mod("TotemLife", "MORE", nil),
},
["number_of_additional_totems_allowed"] = {
	mod("ActiveTotemLimit", "BASE", nil),
},
["attack_skills_additional_ballista_totems_allowed"] = {
	mod("ActiveTotemLimit", "BASE", nil, 0, 0, { type = "SkillType", skillType = SkillType.TotemsAreBallistae }),
},
["base_number_of_totems_allowed"] = {
	mod("ActiveTotemLimit", "BASE", nil),
},
["summon_totem_cast_speed_+%"] = {
	mod("TotemPlacementSpeed", "INC", nil),
},
["totems_regenerate_%_life_per_minute"] = {
    mod("LifeRegenPercent", "BASE", nil, 0, KeywordFlag.Totem),
    div = 60,
},
["totem_duration_+%"] = {
	mod("TotemDuration", "INC", nil),
},
["base_totem_duration"] = {
	mod("TotemDuration", "BASE", nil),
	div = 1000
},
-- Minion
["minion_damage_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", nil) }),
},
["minion_melee_damage_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", nil, ModFlag.Melee) }),
},
["minion_damage_+%_on_full_life"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", nil, 0, 0, {type = "Condition", var = "FullLife"}) }),
},
["active_skill_minion_bleeding_damage_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "MORE", nil, 0, KeywordFlag.Bleed) }),
},
["minion_critical_strike_chance_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("CritChance", "INC", nil) }),
},
["minion_critical_strike_multiplier_+"] = {
	mod("MinionModifier", "LIST", { mod = mod("CritMultiplier", "BASE", nil) }),
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
["base_minion_duration_+%"] = {
	mod("Duration", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.CreatesMinion }),
},
["minion_skill_area_of_effect_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("AreaOfEffect", "INC", nil) }),
},
["minion_additional_physical_damage_reduction_%"] = {
	mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageReduction", "BASE", nil) }),
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
["minion_cooldown_recovery_+%"] = {
	mod("MinionModifier", "LIST", {mod = mod("CooldownRecovery", "INC", nil)}),
},
["minion_life_regeneration_rate_per_minute_%"] = {
	mod("MinionModifier", "LIST", { mod = mod("LifeRegenPercent", "BASE", nil) }),
	div = 60,
},
["minion_chance_to_deal_double_damage_%"] = {
	mod("MinionModifier", "LIST", { mod = mod("DoubleDamageChance", "BASE", nil) }),
},
["minion_ailment_damage_+%"] = {
	mod("MinionModifier", "LIST", { mod = mod("Damage", "INC", nil, 0, KeywordFlag.Ailment) }),
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
["base_number_of_arbalists"] = {
	mod("ActiveArbalistLimit", "BASE", nil),
},
["base_number_of_champions_of_light_allowed"] = {
	mod("ActiveSentinelOfPurityLimit", "BASE", nil),
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
["active_skill_minion_attack_speed_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("Speed", "MORE", nil, ModFlag.Attack) }),
},
["active_skill_minion_physical_damage_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("PhysicalDamage", "MORE", nil) }),
},
["active_skill_minion_life_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("Life", "MORE", nil) }),
},
["support_minion_damage_minion_life_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("Life", "MORE", nil) }),
},
["minion_life_leech_from_elemental_damage_permyriad"] = {
	mod("MinionModifier", "LIST", { mod = mod("FireDamageLeech", "BASE", nil) }),
	mod("MinionModifier", "LIST", { mod = mod("LightningDamageLeech", "BASE", nil) }),
	mod("MinionModifier", "LIST", { mod = mod("ColdDamageLeech", "BASE", nil) }),
	div = 100
},
["active_skill_minion_energy_shield_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("EnergyShield", "MORE", nil) }),
},
["active_skill_minion_movement_velocity_+%_final"] = {
	mod("MinionModifier", "LIST", { mod = mod("MovementSpeed", "MORE", nil) }),
},
["minions_deal_%_of_physical_damage_as_additional_chaos_damage"] = {
	mod("MinionModifier", "LIST", { mod = mod("PhysicalDamageGainAsChaos", "BASE", nil) }),
},
["maximum_life_+%_for_corpses_you_create"] = {
	mod("CorpseLife", "INC", nil),
},
["number_of_melee_skeletons_to_summon"] = {
	mod("MinionPerCastCount", "BASE", nil)
},
["number_of_archer_skeletons_to_summon"] = {
	mod("MinionPerCastCount", "BASE", nil)
},
["number_of_mage_skeletons_to_summon"] = {
	mod("MinionPerCastCount", "BASE", nil)
},
["minion_always_crit"] = {
	mod("MinionModifier", "LIST", { mod = mod("CritChance", "OVERRIDE", nil) }),
	value = 100,
},
--Golem
["golem_buff_effect_+%"] = {
	mod("BuffEffect", "INC", nil, 0, 0)
},
["golem_cooldown_recovery_+%"] = {
	mod("MinionModifier", "LIST", {mod = mod("CooldownRecovery", "INC", nil)})
},
-- Slam
["warcry_grant_damage_+%_to_exerted_attacks"] = {
	mod("ExertIncrease", "INC", nil, ModFlag.Attack, 0)
},
-- Curse
["curse_effect_+%"] = {
	mod("CurseEffect", "INC", nil),
},
["curse_effect_+%_vs_players"] = {
	mod("CurseEffectAgainstPlayer", "INC", nil),
},
["mark_skills_curse_effect_+%"] = {
	mod("CurseEffect", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.Mark }),
},
["curse_area_of_effect_+%"] = {
	mod("AreaOfEffect", "INC", nil, 0, KeywordFlag.Curse),
},
["base_curse_duration_+%"] = {
	mod("Duration", "INC", nil, 0, KeywordFlag.Curse),
},
["curse_skill_effect_duration_+%"] = {
	mod("Duration", "INC", nil, 0, KeywordFlag.Curse),
},
["curse_cast_speed_+%"] = {
	mod("Speed", "INC", nil, ModFlag.Cast),
},
-- Hex
["curse_maximum_doom"] = {
	mod("MaxDoom", "BASE", nil),
},
["triggered_vicious_hex_explosion"] = {
	skill("triggeredWhenHexEnds", nil, { type = "SkillType", skillType = SkillType.Triggerable }, { type = "SkillType", skillType = SkillType.Spell }),
},
-- Aura
["non_curse_aura_effect_+%"] = {
	mod("AuraEffect", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.AppliesCurse, neg = true }),
},
["base_mana_reservation_+%"] = {
	mod("ManaReserved", "INC", nil)
},
["base_life_reservation_+%"] = {
	mod("LifeReserved", "INC", nil)
},
["base_reservation_+%"] = {
	mod("Reserved", "INC", nil)
},
["base_mana_reservation_efficiency_+%"] = {
	mod("ManaReservationEfficiency", "INC", nil)
},
["base_life_reservation_efficiency_+%"] = {
	mod("LifeReservationEfficiency", "INC", nil)
},
["base_reservation_efficiency_+%"] = {
	mod("ReservationEfficiency", "INC", nil)
},
-- Brand
["sigil_attached_target_damage_+%_final"] = {
	mod("Damage", "MORE", nil, 0, 0, { type = "MultiplierThreshold", var = "BrandsAttachedToEnemy", threshold = 1 }),
},
["base_number_of_sigils_allowed_per_target"] = {
	mod("BrandsAttachedLimit", "BASE", nil)
},
["active_skill_brands_allowed_on_enemy_+"] = {
	mod("BrandsAttachedLimit", "BASE", nil)
},
["base_sigil_repeat_frequency_ms"] = {
	skill("repeatFrequency", nil),
	div = 1000,
},
["sigil_repeat_frequency_+%"] = {
	mod("BrandActivationFrequency", "INC", nil)
},
["additive_cast_speed_modifiers_apply_to_sigil_repeat_frequency"] = {
},
["brand_atttached_duration_is_infinite"] = {
	flag("UnlimitedBrandDuration"),
},
["brand_cannot_be_recalled"] = {
	flag("Condition:CannotRecallBrand"),
},
-- Banner
["banner_buff_effect_+%_per_stage"] = {
	mod("AuraEffect", "INC", nil, 0, 0, { type = "Multiplier", var = "BannerStage" }, { type = "Condition", var = "BannerPlanted" }),
},
["banner_area_of_effect_+%_per_stage"] = {
	mod("AreaOfEffect", "INC", nil, 0, 0, { type = "Multiplier", var = "BannerStage" }, { type = "Condition", var = "BannerPlanted" }),
},
["banner_additional_base_duration_per_stage_ms"] = {
	mod("PrimaryDuration", "BASE", nil, 0, 0, { type = "Multiplier", var = "BannerStage" }, { type = "Condition", var = "BannerPlanted" }),
	div = 1000,
},
-- Other
["triggered_skill_damage_+%"] = {
	mod("TriggeredDamage", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.Triggered }),
},
["channelled_skill_damage_+%"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "SkillType", skillType = SkillType.Channel }),
},
["snipe_triggered_skill_ailment_damage_+%_final_per_stage"] = {
	mod("snipeAilmentMulti", "BASE", nil),
},
["snipe_triggered_skill_hit_damage_+%_final_per_stage"] = {
	mod("snipeHitMulti", "BASE", nil),
},
["snipe_triggered_skill_damage_+%_final"] = {
	mod("Damage", "MORE", nil),
},
["damage_+%_if_you_have_consumed_a_corpse_recently"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Condition", var = "ConsumedCorpseRecently" }),
},
["withered_on_hit_chance_%"] = {
	flag("Condition:CanWither"),
},
["minions_have_%_chance_to_inflict_wither_on_hit"] = {
	mod("MinionModifier", "LIST", { mod = flag("Condition:CanWither") }),
},
["withered_on_hit_for_2_seconds_%_chance"] = {
	flag("Condition:CanWither"),
},
["discharge_damage_+%_if_3_charge_types_removed"] = {
	mod("Damage", "INC", nil, 0, 0, { type = "Multiplier", var = "RemovableEnduranceCharge", limit = 1 }, { type = "Multiplier", var = "RemovableFrenzyCharge", limit = 1 }, { type = "Multiplier", var = "RemovablePowerCharge", limit = 1 }),
},
["support_added_cooldown_count_if_not_instant"] = {
	mod("AdditionalCooldownUses", "BASE", nil, 0, 0, { type = "SkillType", skillType = SkillType.Instant, neg = true })
},
["base_added_cooldown_count"] = {
	mod("AdditionalCooldownUses", "BASE", nil)
},
["kill_enemy_on_hit_if_under_10%_life"] = {
	mod("CullPercent", "MAX", nil), 
	value = 10
},
["spell_cast_time_added_to_cooldown_if_triggered"] = {
	flag("SpellCastTimeAddedToCooldownIfTriggered"),
},
--
-- Spectre or Minion-specific stats
--
["physical_damage_reduction_rating_+%"] = {
	mod("Armour", "INC", nil),
},
["base_cannot_be_damaged"] = {
	mod("Condition:CannotBeDamaged", "FLAG", nil)
},
--
-- Gem Levels
--
--Fire
["supported_fire_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Fire }),
},
--Cold
["supported_cold_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Cold }),
},
--Lightning
["supported_lightning_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Lightning }),
},
--Chaos
["supported_chaos_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Chaos }),
},
--Physical
["supported_physical_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Physical }),
},
--Active
["supported_active_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }),
},
--Aura
["supported_aura_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Aura }),
},
--Curse
["supported_curse_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, KeywordFlag.Curse),
},
--Strike
["supported_strike_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.MeleeSingleTarget }),
},
--Elemental
["supported_elemental_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, bit.bor(KeywordFlag.Lightning, KeywordFlag.Cold, KeywordFlag.Fire)),
},
--Minion
["supported_minion_skill_gem_level_+"] = {
	mod("SupportedGemProperty", "LIST", { keyword = "grants_active_skill", key = "level", value = nil }, 0, 0, { type = "SkillType", skillType = SkillType.Minion }),
},

-- Gem quality display only
["quality_display_base_additional_arrows_is_gem"] = {
	-- Display only
},
["quality_display_base_duration_is_quality"] = {
	-- Display only
},
["quality_display_base_number_of_projectiles_is_gem"] = {
	-- Display only
},
["quality_display_animate_weapon_is_gem"] = {
	-- Display only
},
["quality_display_sigil_attached_target_damage_is_gem"] = {
	-- Display only
},
["quality_display_shock_chance_from_skill_is_gem"] = {
	-- Display only
},
["quality_display_trap_duration_is_gem"] = {
	-- Display only
},
["quality_display_active_skill_area_damage_is_gem"] = {
	-- Display only
},
["quality_display_active_skill_bleed_damage_final_is_gem"] = {
	-- Display only
},
}
