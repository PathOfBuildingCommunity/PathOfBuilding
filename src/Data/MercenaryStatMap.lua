-- Path of Building
--
-- Mercenary-only stat mappings and standard support templates.
-- Raw values are exported from MercenarySupports; this file only describes
-- how those values participate in PoB's existing calculation model.
--
return function(mod, flag, skill)

local allyBuff = { type = "GlobalEffect", effectType = "Buff", applyAllies = true }
local allyWarcry = { type = "GlobalEffect", effectType = "Warcry", unscalable = true }
local selfBuff = { type = "GlobalEffect", effectType = "Buff" }
local enemyDebuff = { type = "GlobalEffect", effectType = "Debuff" }

local scorchingRayTotemStages = {
	["fire_beam_additional_stack_damage_+%_final"] = {
		mod("Damage", "MORE", nil, 0, 0, { type = "Multiplier", var = "ScorchingRayTotemStageAfterFirst" }),
		base = 100,
	},
	["display_max_fire_beam_stacks"] = {
		mod("Multiplier:ScorchingRayTotemMaxStages", "BASE", nil),
	},
}

local function calculateCorruptedBlood(activeSkill, output)
	local skillData = activeSkill.skillData
	skillData.PhysicalDot = activeSkill.actor.averageDamage * (skillData.corruptedBloodDamagePercent or 0) / 6000
	local stacksPerHit = skillData.corruptedBloodStacksPerHit or 1
	local stacks = math.min(10, math.max(1, math.floor((output.DurationSecondary or 0) / skillData.hitTimeOverride + 1e-9)) * stacksPerHit)
	skillData.corruptedBloodStacks = stacks
	if stacks > 1 then
		activeSkill.skillModList:NewMod("Damage", "MORE", (stacks - 1) * 100, "Corrupted Blood stacks", 0, KeywordFlag.PhysicalDot)
	end
end

return {
	statMap = {
		["barrage_final_volley_fires_x_additional_projectiles_simultaneously"] = {
			skill("barrageFinalVolleyAdditionalProjectiles", nil),
		},
		["maximum_number_of_vaal_ice_shot_mirages"] = {
			skill("vaalIceShotMirageCount", nil),
		},
		["%_chance_to_gain_frenzy_charge_on_trap_triggered_by_an_enemy"] = {
			flag("UseFrenzyCharges"),
			skill("frenzyChargeOnTrapTriggerChance", nil),
		},
		["active_skill_has_skill_area_of_effect_+%_final_per_additional_projectile"] = {
			mod("AreaOfEffect", "MORE", nil, 0, 0, { type = "PerStat", stat = "ProjectileCount", subtract = 1 }),
		},
		["abyssal_cry_%_max_life_as_chaos_on_death"] = {
			skill("corpseExplosionLifeMultiplier", nil),
			div = 100,
		},
		["abyssal_cry_movement_velocity_+%_per_one_hundred_nearby_enemies"] = {
			skill("hinderPerNearbyEnemy", nil),
			div = 100,
		},
		["add_endurance_charge_on_skill_hit_%"] = {
			flag("UseEnduranceCharges"),
			skill("enduranceChargeOnHitChance", nil),
		},
		["add_frenzy_charge_on_skill_hit_%"] = {
			flag("UseFrenzyCharges"),
			skill("frenzyChargeOnHitChance", nil),
		},
		["add_power_charge_on_critical_strike_%"] = {
			flag("UsePowerCharges"),
			skill("powerChargeOnCritChance", nil),
		},
		["add_x_grasping_vines_on_hit"] = {
			mod("Multiplier:GraspingVinesAffectingEnemy", "BASE", nil, 0, 0, enemyDebuff),
		},
		["additional_block_%_while_on_consecrated_ground"] = {
			mod("BlockChance", "BASE", nil, 0, 0, { type = "Condition", var = "OnConsecratedGround" }),
		},
		["additional_physical_damage_reduction_%_while_affected_by_guard_skill"] = {
			mod("PhysicalDamageReduction", "BASE", nil, 0, 0, { type = "Condition", var = "AffectedByGuardSkill" }),
		},
		["attack_damage_+%_per_75_armour_or_evasion_on_shield"] = {
			mod("Damage", "INC", nil, ModFlag.Attack, 0, { type = "PerStat", statList = { "ArmourOnWeapon 2", "EvasionOnWeapon 2" }, div = 75 }),
		},
		["base_maximum_mana"] = {
			mod("Mana", "BASE", nil),
		},
		["base_spell_critical_strike_chance"] = {
			mod("CritChance", "BASE", nil, ModFlag.Spell),
			div = 100,
		},
		["beacon_placement_radius"] = {
			skill("beaconPlacementRadius", nil),
		},
		["blackhole_pulse_frequency_+%"] = {
			mod("VoidSphereFrequency", "INC", nil),
		},
		["bladestorm_maximum_number_of_storms_allowed"] = {
			skill("maximumBladestorms", nil),
		},
		["blast_rain_%_chance_for_additional_blast"] = {
			mod("Damage", "MORE", nil, ModFlag.Hit),
			skill("chanceForAdditionalBlast", nil),
		},
		["blight_secondary_skill_effect_duration_+%"] = {
			mod("SecondaryDuration", "INC", nil),
		},
		["chance_for_melee_skeletons_to_summon_as_archer_skeletons_%"] = {
			skill("summonSkeletonArchersChance", nil),
		},
		["chance_to_crush_on_hit_%"] = {
			flag("Condition:Crushed", enemyDebuff),
			skill("crushOnHitChance", nil),
		},
		["chance_to_gain_power_charge_on_rare_or_unique_enemy_hit_%"] = {
			flag("UsePowerCharges"),
			skill("powerChargeOnRareOrUniqueHitChance", nil),
		},
		["chance_to_intimidate_on_hit_%"] = {
			flag("Condition:Intimidated", enemyDebuff),
			skill("intimidateOnHitChance", nil),
		},
		["chance_to_inflict_frostburn_%"] = {
			mod("EnemyBrittleChance", "BASE", nil),
		},
		["chance_to_unnerve_on_hit_%"] = {
			flag("Condition:Unnerved", enemyDebuff),
			skill("unnerveOnHitChance", nil),
		},
		["cast_on_trigger_cascade_event_%"] = {
			skill("cascadeTriggerChance", nil),
		},
		["chaos_damage_can_chill"] = {
			flag("ChaosCanChill"),
		},
		["consume_all_impales_remaining_hits_on_hit_%_chance"] = {
			skill("consumeImpalesChance", nil),
		},
		["cover_in_ash_on_hit_%"] = {
			mod("CoveredInAshEffect", "BASE", 20, 0, 0, enemyDebuff),
			skill("coverInAshOnHitChance", nil),
		},
		["cover_in_frost_on_hit"] = {
			mod("CoveredInFrostEffect", "BASE", 20, 0, 0, enemyDebuff),
		},
		["corrupted_blood_on_hit_%_average_damage_to_deal_per_minute_per_stack"] = {
			skill("corruptedBloodDamagePercent", nil),
		},
		["corrupted_blood_on_hit_duration"] = {
			skill("durationSecondary", nil),
			div = 1000,
		},
		["corrupted_blood_on_hit_num_stacks"] = {
			skill("corruptedBloodStacksPerHit", nil),
		},
		["critical_strike_chance_increased_by_overcapped_lightning_resistance"] = {
			flag("CritChanceIncreasedByOvercappedLightningRes"),
		},
		["critical_strikes_always_knockback_shocked_enemies"] = {
			skill("criticalStrikesKnockbackShockedEnemies", true),
		},
		["decelerating_projectile_speed_variation_+%"] = {
			skill("deceleratingProjectileSpeedVariation", nil),
		},
		["curse_on_hit_%_elemental_weakness"] = {
			skill("elementalWeaknessOnHitChance", nil),
		},
		["curse_on_hit_%_vulnerability"] = {
			skill("vulnerabilityOnHitChance", nil),
		},
		["disable_skill_if_weapon_not_bow"] = {
			skill("requiresBow", true),
		},
		["divine_tempest_beam_width_+%"] = {
			skill("beamWidthMultiplier", nil),
		},
		["doubles_have_movement_speed_+%"] = {
			skill("doubleMovementSpeedMultiplier", nil),
		},
		["elemental_hit_cannot_roll_fire_damage"] = {
			flag("DealNoFire"),
		},
		["elemental_hit_cannot_roll_lightning_damage"] = {
			flag("DealNoLightning"),
		},
		["enemies_you_shock_cast_speed_+%"] = {
			mod("Speed", "INC", nil, ModFlag.Cast, 0, enemyDebuff, { type = "Condition", var = "Shocked" }),
		},
		["enemies_you_shock_movement_speed_+%"] = {
			mod("MovementSpeed", "INC", nil, 0, 0, enemyDebuff, { type = "Condition", var = "Shocked" }),
		},
		["enemies_taunted_by_your_warcies_are_intimidated"] = {
			flag("Condition:Intimidated", enemyDebuff),
		},
		["enduring_cry_grants_x_additional_endurance_charges"] = {
			flag("UseEnduranceCharges", allyWarcry),
			mod("EnduranceCharges", "OVERRIDE", nil, 0, 0, allyWarcry),
		},
		["enemy_life_regeneration_rate_+%_for_4_seconds_on_hit"] = {
			mod("LifeRegen", "INC", nil, 0, 0, enemyDebuff),
		},
		["extra_damage_rolls_with_lightning_damage_on_non_critical_hits"] = {
			flag("LightningNoCritLucky"),
		},
		["enemy_knockback_direction_is_reversed"] = {
			skill("reverseKnockback", true),
		},
		["fire_mortar_second_hit_damage_+%_final"] = {
			mod("Damage", "MORE", nil, ModFlag.Hit, 0, { type = "SkillPart", skillPart = 2 }),
		},
		["fire_beam_length_+%"] = {
			skill("beamLengthMultiplier", nil),
		},
		["firestorm_avoid_unwalkable_terrain"] = {
			skill("avoidUnwalkableTerrain", true),
		},
		["fortify_applies_to_nearby_allies_for_X_seconds"] = {
			flag("Condition:Fortified", allyBuff),
			skill("fortifyShareDuration", nil),
		},
		["fortify_on_hit"] = {
			flag("Condition:Fortified", selfBuff),
		},
		["gain_arcane_surge_when_trap_triggered_by_an_enemy"] = {
			flag("Condition:ArcaneSurge", selfBuff),
		},
		["gain_rage_when_you_use_a_warcry"] = {
			flag("Condition:CanGainRage"),
			skill("rageOnWarcry", nil),
		},
		["gain_x_rage_on_melee_hit"] = {
			flag("Condition:CanGainRage"),
			skill("rageOnMeleeHit", nil),
		},
		["global_maim_on_hit"] = {
			flag("Condition:Maimed", enemyDebuff),
		},
		["ground_slam_angle_+%"] = {
			skill("groundSlamAngleMultiplier", nil),
		},
		["ground_blood_art_variation"] = {
			skill("groundEffectArtVariation", nil),
		},
		["ground_fire_art_variation"] = {
			skill("groundEffectArtVariation", nil),
		},
		["ground_temporal_anomaly_art_variation"] = {
			skill("groundEffectArtVariation", nil),
		},
		["hallowing_flame_duration_ms"] = {
			skill("hallowingFlameDuration", nil),
			div = 1000,
		},
		["has_onslaught_if_totem_summoned_recently"] = {
			flag("Onslaught", selfBuff),
		},
		["hits_ignore_enemy_monster_physical_damage_reduction_%_chance"] = {
			mod("ChanceToIgnoreEnemyPhysicalDamageReduction", "BASE", nil, ModFlag.Hit),
		},
		["infernal_cry_%_max_life_as_fire_on_death"] = {
			skill("corpseExplosionLifeMultiplier", nil),
			div = 100,
		},
		["immune_to_auras_from_other_entities"] = {
			flag("AlliesAurasCannotAffectSelf"),
		},
		["immune_to_curses"] = {
			flag("CurseImmune"),
		},
		["lightning_arrow_maximum_number_of_extra_targets"] = {
			skill("maximumExtraTargets", nil),
		},
		["lightning_tower_trap_additional_number_of_beams"] = {
			mod("MaximumWaves", "BASE", nil),
		},
		["malediction_on_hit"] = {
			flag("HasMalediction", enemyDebuff),
		},
		["mana_degeneration_per_minute_%"] = {
			skill("manaDegenerationPercentPerSecond", nil),
			div = 60,
		},
		["mana_regeneration_rate_per_minute_%"] = {
			mod("ManaRegenPercent", "BASE", nil),
			div = 60,
		},
		["melee_splash"] = {
			skill("meleeSplash", true),
		},
		["melee_splash_area_of_effect_+%_final"] = {
			mod("AreaOfEffect", "MORE", nil),
		},
		["minion_caustic_cloud_on_death_maximum_life_per_minute_to_deal_as_chaos_damage_%"] = {
			mod("ExtraMinionSkill", "LIST", { skillId = "SiegebreakerCausticGround" }),
			mod("MinionModifier", "LIST", { mod = mod("Multiplier:SiegebreakerCausticGroundPercent", "BASE", nil) }),
			div = 60,
		},
		["mirage_archer_projectile_additional_height_offset"] = {
			skill("mirageArcherProjectileHeightOffset", nil),
		},
		["no_barrage_projectile_spread"] = {
			skill("noBarrageProjectileSpread", true),
		},
		["nova_spells_cast_at_target_location"] = {
			skill("novaCastAtTarget", true),
		},
		["number_of_beacons"] = {
			skill("beaconCount", nil),
		},
		["number_of_endurance_charges_to_gain"] = {
			flag("UseEnduranceCharges", allyBuff),
			mod("EnduranceCharges", "OVERRIDE", nil, 0, 0, allyBuff),
		},
		["number_of_frenzy_charges_to_gain"] = {
			flag("UseFrenzyCharges", allyBuff),
			mod("FrenzyCharges", "OVERRIDE", nil, 0, 0, allyBuff),
		},
		["number_of_projectiles_override"] = {
			mod("ProjectileCount", "OVERRIDE", nil),
		},
		["physical_damage_%_to_add_as_random_element"] = {
			mod("PhysicalDamageGainAsRandom", "BASE", nil),
		},
		["projectiles_nova"] = {
			skill("projectilesNova", true),
		},
		["projectiles_barrage"] = {
			flag("SequentialProjectiles"),
		},
		["projectiles_fire_at_ground"] = {
			skill("projectilesFireAtGround", true),
		},
		["projectiles_fork_after_traveling_X_units_distance"] = {
			skill("projectileForkDistance", nil),
		},
		["projectiles_rain"] = {
			skill("projectilesRain", true),
		},
		["projectiles_return"] = {
			skill("projectilesReturn", true),
		},
		["random_projectile_direction"] = {
			skill("randomProjectileDirection", true),
		},
		["reap_debuff_deals_fire_damage_instead_of_physical_damage"] = {
			flag("ReapDebuffIsFireDamage"),
		},
		["scourge_arrow_X_pods_per_projectile"] = {
			skill("scourgeArrowPodsPerProjectile", nil),
		},
		["siphon_life_leech_from_damage_permyriad"] = {
			mod("DamageLifeLeech", "BASE", nil),
			div = 100,
		},
		["skill_can_only_use_bow"] = {
			skill("requiresBow", true),
		},
		["skill_surge_type_override"] = {
			skill("surgeTypeOverride", nil),
		},
		["skill_is_rain_skill"] = {
			skill("isRainSkill", true),
		},
		["smite_chance_for_lighting_to_strike_extra_target_%"] = {
			skill("smiteExtraTargetChance", nil),
		},
		["slam_ancestor_totem_grant_owner_melee_damage_+%_final"] = {
			mod("Damage", "MORE", nil, ModFlag.Melee, 0, selfBuff),
		},
		["spell_damage_modifiers_apply_to_attack_damage"] = {
			flag("SpellDamageAppliesToAttacks"),
		},
		["storm_rain_pulse_count"] = {
			skill("stormRainPulseCount", nil),
		},
		["storm_cloud_destroy_when_caster_dies"] = {
			skill("destroyWhenCasterDies", true),
		},
		["summon_2_totems"] = {
			mod("ActiveTotemLimit", "BASE", 1),
			skill("totemsSummonedPerCast", 2),
		},
		["summoned_raging_spirits_have_diamond_and_massive_shrine_buff"] = {
			mod("MinionModifier", "LIST", { mod = flag("Condition:DiamondShrine") }),
			mod("MinionModifier", "LIST", { mod = flag("Condition:MassiveShrine") }),
		},
		["summon_specific_monsters_in_front_offset"] = {
			skill("summonFrontOffset", nil),
		},
		["summon_specific_monsters_radius_+%"] = {
			skill("summonRadiusMultiplier", nil),
		},
		["support_ancestral_slam_big_hit_max_count"] = {
			skill("fistOfWarMaxCount", nil),
		},
		["support_melee_splash_damage_+%_final_for_splash"] = {
			mod("Damage", "MORE", nil, ModFlag.Hit, 0, { type = "SkillPart", skillPart = 2 }),
		},
		["support_spell_cascade_number_of_cascades_per_side"] = {
			skill("spellCascadeCountPerSide", nil),
		},
		-- PoB's wither model is stack-based and already assumes a 2s duration.
		-- 3.29.3 exports that duration explicitly; do not treat it as skill duration.
		["support_withered_base_duration_ms"] = {
		},
		["totem_additional_physical_damage_reduction_%"] = {
			skill("totemPhysicalDamageReduction", nil),
		},
		["totem_elemental_resistance_%"] = {
			mod("TotemElementalResist", "BASE", nil),
		},
		["totem_ignores_vaal_skill_cost"] = {
			skill("totemIgnoresVaalSkillCost", true),
		},
		["unique_ryuslathas_clutches_maximum_physical_attack_damage_+%_final"] = {
			mod("MaxPhysicalDamage", "MORE", nil, ModFlag.Attack),
		},
		["upheaval_number_of_spikes"] = {
			skill("upheavalSpikeCount", nil),
		},
		["vaal_lightning_arrow_number_of_redirects"] = {
			skill("vaalLightningArrowRedirectCount", nil),
		},
		["vaal_volcanic_fissure_crack_repeat_count"] = {
			skill("vaalVolcanicFissureRepeatCount", nil),
		},
		["voll_slam_damage_+%_final_at_centre"] = {
			mod("Damage", "MORE", nil, 0, 0, { type = "SkillPart", skillPart = 2 }),
		},
		["you_and_nearby_allys_gain_onslaught_for_4_seconds_on_warcry"] = {
			flag("Onslaught", allyBuff),
		},
		["your_consecrated_ground_grants_damage_+%"] = {
			mod("Damage", "INC", nil, 0, 0, allyBuff),
		},
	},
	-- These reviewed stats are display/AI/engine metadata or mechanics that the
	-- existing PoB skill model intentionally represents without a stat-map mod.
	-- Keep this list Mercenary-specific so newly exported stats fail closed.
	knownUncalculatedStats = {
		["absolution_blast_chance_to_summon_on_hitting_rare_or_unique_%"] = true,
		["action_attack_or_cast_time_uses_animation_length"] = true,
		["action_ignores_crit_tracking"] = true,
		["active_skill_additional_projectiles_fire_parallel_x_dist"] = true,
		["active_skill_area_of_effect_description_mode"] = true,
		["active_skill_display_aegis_variation"] = true,
		["active_skill_ground_consecration_radius_+"] = true,
		["active_skill_minion_from_alternate_gem_index"] = true,
		["active_skill_projectile_speed_+%_variation_final"] = true,
		["active_skill_secondary_area_of_effect_description_mode"] = true,
		["active_skill_tertiary_area_of_effect_description_mode"] = true,
		["additional_main_hand_hits_per_combo_average"] = true,
		["aegis_recharge_delay_ms"] = true,
		["alternate_minion"] = true,
		["always_stun_enemies_that_are_on_full_life"] = true,
		["ancestor_totem_parent_activiation_range"] = true,
		["animation_effect_variation"] = true,
		["arc_additional_delay_ms"] = true,
		["arc_chain_distance"] = true,
		["arc_enhanced_behaviour"] = true,
		["arctic_armour_chill_when_hit_duration"] = true,
		["arctic_breath_maximum_number_of_skulls_allowed"] = true,
		["attack_is_melee_override"] = true,
		["attack_is_not_melee_override"] = true,
		["base_circle_of_power_mana_spend_per_upgrade"] = true,
		["base_deal_no_attack_damage"] = true,
		["base_deal_no_damage"] = true,
		["base_deal_no_secondary_damage"] = true,
		["base_deal_no_spell_damage"] = true,
		["base_display_minion_actor_level"] = true,
		["base_from_skill_shock_art_variation"] = true,
		["base_is_projectile"] = true,
		["base_max_number_of_dominated_magic_monsters"] = true,
		["base_max_number_of_dominated_normal_monsters"] = true,
		["base_max_number_of_dominated_rare_monsters"] = true,
		["base_max_number_of_vaal_absolution_sentinels"] = true,
		["base_max_number_of_vaal_dominated_monsters"] = true,
		["base_mine_duration"] = true,
		["base_skill_is_mined"] = true,
		["base_skill_is_totemified"] = true,
		["base_skill_is_trapped"] = true,
		["base_skill_number_of_additional_hits"] = true,
		["base_smite_number_of_targets"] = true,
		["base_sunder_wave_delay_ms"] = true,
		["base_totem_range"] = true,
		["base_trap_duration"] = true,
		["base_weapon_trap_total_rotation_%"] = true,
		["bear_trap_movement_speed_+%_final"] = true,
		["blackhole_hinder_%"] = true,
		["bladefall_blade_left_in_ground_for_every_X_volleys"] = true,
		["bladefall_create_X_lingering_blades_per_volley"] = true,
		["blast_rain_arrow_delay_ms"] = true,
		["blind_art_variation"] = true,
		["blood_ground_leaving_area_lasts_for_ms"] = true,
		["blood_spears_aoe_modifiers_apply_to_blood_spear_placement_range_at_%_value"] = true,
		["blood_tendrils_beam_count"] = true,
		["call_of_steel_reload_amount"] = true,
		["call_of_steel_reload_time"] = true,
		["cannot_cancel_skill_before_contact_point"] = true,
		["cannot_stun"] = true,
		["cannot_use_spectre_corpses"] = true,
		["cast_on_gain_skill"] = true,
		["chain_hook_attaches_to_X_targets"] = true,
		["chain_hook_max_attached_targets"] = true,
		["chance_to_grant_frenzy_charge_on_death_%"] = true,
		["chance_to_grant_power_charge_on_death_%"] = true,
		["charged_dash_skill_inherent_movement_speed_+%_final"] = true,
		["cluster_burst_spawn_amount"] = true,
		["consecrated_ground_immune_to_curses"] = true,
		["console_skill_dont_chase"] = true,
		["corpse_explosion_monster_life_%_lightning"] = true,
		["create_consecrated_ground_on_hit_%_vs_rare_or_unique_enemy"] = true,
		["damage_cannot_be_reflected"] = true,
		["damage_cannot_be_reflected_or_leech_if_used_by_other_object"] = true,
		["damage_originates_from_initiator_location"] = true,
		["damage_taken_from_suppressed_hits_is_unlucky"] = true,
		["debilitate_self_for_x_milliseconds_on_hit"] = true,
		["desecrate_corpse_level"] = true,
		["desecrate_maximum_number_of_corpses"] = true,
		["desecrate_number_of_corpses_to_create"] = true,
		["disable_mine_detonation_cascade"] = true,
		["disable_visual_hit_effect"] = true,
		["display_minion_monster_type"] = true,
		["display_projectiles_chain_when_impacting_ground"] = true,
		["display_skill_deals_secondary_damage"] = true,
		["divine_retribution_blasts_per_wave"] = true,
		["divine_retribution_num_waves"] = true,
		["divine_tempest_base_number_of_nearby_enemies_to_zap"] = true,
		["divine_tempest_beam_width_+"] = true,
		["dominating_blow_chance_to_summon_on_hitting_unqiue_%"] = true,
		["eye_of_winter_base_explosion_shards"] = true,
		["firestorm_drop_ground_ice_duration_ms"] = true,
		["firestorm_max_number_of_storms"] = true,
		["firewall_attached_projectile_effect_mtx"] = true,
		["fixed_projectile_spread"] = true,
		["flame_dash_repeats_target_previous_location"] = true,
		["flame_surge_burning_ground_creation_cooldown_ms"] = true,
		["frost_globe_stage_gain_interval_ms"] = true,
		["ground_ice_art_variation"] = true,
		["ground_smoke_art_variation"] = true,
		["herald_of_light_summon_champion_on_kill"] = true,
		["herald_of_light_summon_champion_on_unique_or_rare_enemy_hit_%"] = true,
		["holy_hammers_maximum_number_of_hammerslam_cascades"] = true,
		["holy_hammers_num_additional_hammerslams_if_consuming_power_charge"] = true,
		["holy_strike_animates_owners_main_hand_weapon"] = true,
		["holy_sweep_number_of_holy_bolts_to_create"] = true,
		["ignite_art_variation"] = true,
		["ignores_proximity_shield"] = true,
		["ignores_trap_and_mine_cooldown_limit"] = true,
		["is_area_damage"] = true,
		["is_dominated"] = true,
		["is_ranged_attack_totem"] = true,
		["is_remote_mine"] = true,
		["is_trap"] = true,
		["kinetic_bolt_forks_apply_to_zig_zags"] = true,
		["kinetic_wand_base_number_of_zig_zags"] = true,
		["leap_slam_always_knockback_within_range"] = true,
		["lightning_trap_projectiles_leave_shocking_ground"] = true,
		["mamba_strike_deal_%_of_all_poison_total_damage_per_minute"] = true,
		["max_number_of_lightning_warp_markers"] = true,
		["maximum_number_of_blades_left_in_ground"] = true,
		["maximum_number_of_snapping_adder_projectiles"] = true,
		["maximum_number_of_summoned_doubles"] = true,
		["melee_defer_damage_prediction"] = true,
		["mine_cannot_rearm"] = true,
		["mine_detonates_instantly"] = true,
		["minimum_rain_of_spores_movement_speed_+%_final_cap"] = true,
		["minion_actor_scale_+%"] = true,
		["minion_dies_when_parent_dies"] = true,
		["minion_life_regeneration_rate_per_minute_%_if_blocked_recently"] = true,
		["minions_cannot_taunt_enemies"] = true,
		["modifiers_to_totem_duration_also_affect_soul_prevention_duration"] = true,
		["modifiers_to_trap_throw_speed_apply_to_lightning_spire_trap_frequency"] = true,
		["molten_strike_projectiles_chain_when_impacting_ground"] = true,
		["monster_projectile_variation"] = true,
		["movement_velocity_cap"] = true,
		["napalm_arrow_maximum_number_of_unprimed_arrows_allowed"] = true,
		["no_movement_speed"] = true,
		["number_of_allowed_firewalls"] = true,
		["number_of_monsters_to_summon"] = true,
		["orb_of_storms_maximum_number_of_hits"] = true,
		["override_turn_duration_ms"] = true,
		["pact_of_ghorr_can_modify_damage_over_time_of_skill"] = true,
		["phase_through_objects"] = true,
		["projectile_angle_variance"] = true,
		["projectile_firing_forward_distance_override"] = true,
		["projectile_random_angle_based_on_distance_to_target_location_%"] = true,
		["projectile_speed_variation_+%"] = true,
		["projectile_spread_radius"] = true,
		["projectile_uses_contact_position"] = true,
		["projectiles_are_not_fired"] = true,
		["projectiles_can_shotgun"] = true,
		["projectiles_can_split_at_end_of_range"] = true,
		["projectiles_can_split_from_terrain"] = true,
		["rain_of_spores_vines_movement_speed_+%_final"] = true,
		["shield_charge_attack_time_+30%_if_no_charge"] = true,
		["shield_charge_scaling_stun_threshold_reduction_+%_at_maximum_range"] = true,
		["shock_art_variation"] = true,
		["show_number_of_projectiles"] = true,
		["single_primary_projectile"] = true,
		["skeletal_chains_no_minions_targets_self"] = true,
		["skill_angle_+%_in_sand_stance"] = true,
		["skill_can_add_multiple_charges_per_action"] = true,
		["skill_can_fire_wand_projectiles"] = true,
		["skill_cannot_be_interrupted"] = true,
		["skill_cannot_be_knocked_back"] = true,
		["skill_cannot_be_stunned"] = true,
		["skill_cannot_be_stunned_before_contact_point"] = true,
		["skill_is_ice_storm"] = true,
		["skill_is_steel_skill_reload"] = true,
		["skill_maximum_travel_distance_+%"] = true,
		["skill_override_pvp_scaling_time_ms"] = true,
		["skill_projectiles_cannot_return"] = true,
		["skill_travel_distance_+%"] = true,
		["smite_lightning_target_range"] = true,
		["snapping_adder_%_chance_to_retain_projectile_on_release"] = true,
		["snapping_adder_maximum_projectiles_released"] = true,
		["soulfeast_number_of_secondary_projectiles"] = true,
		["spectral_helix_rotations_%"] = true,
		["spectral_throw_forget_hit_list_time_override"] = true,
		["spell_maximum_action_distance_+%"] = true,
		["spider_aspect_web_interval_ms"] = true,
		["static_strike_number_of_beam_targets"] = true,
		["stationary_shield_throw_interval_acceleration_%_per_interval"] = true,
		["stationary_shield_throw_projectiles_per_interval"] = true,
		["summoned_monsters_are_minions"] = true,
		["summoned_monsters_no_drops_or_experience"] = true,
		["sunder_shockwave_limit_per_cascade"] = true,
		["sunder_wave_min_steps"] = true,
		["tectonic_slam_side_crack_additional_chance_%"] = true,
		["tectonic_slam_side_crack_additional_chance_%_per_endurance_charge"] = true,
		["tethered_movement_speed_+%_final_per_rope"] = true,
		["tethered_movement_speed_+%_final_per_rope_vs_rare"] = true,
		["tethered_movement_speed_+%_final_per_rope_vs_unique"] = true,
		["tethering_arrow_display_rope_limit"] = true,
		["throw_traps_in_circle_radius"] = true,
		["tornado_hinder"] = true,
		["tornado_movement_speed_+%"] = true,
		["total_projectile_spread_angle_override"] = true,
		["totem_formation_radius_override"] = true,
		["totem_ignores_cooldown"] = true,
		["totem_placement_range_+%"] = true,
		["totems_cannot_evade"] = true,
		["trap_override_pvp_scaling_time_ms"] = true,
		["trap_variation"] = true,
		["traps_do_not_explode_on_timeout"] = true,
		["trauma_strike_shockwave_area_of_effect_+%_per_100ms_stun_duration_up_to_400%"] = true,
		["use_intimidating_cry_buff_visual_for_intimidate"] = true,
		["vaal_burning_arrow_explode_on_hit"] = true,
		["vaal_caustic_arrow_ground_art_variation"] = true,
		["vaal_cleave_steal_mods_on_kill"] = true,
		["vaal_ice_shot_modifiers_to_projectile_count_do_not_apply_to_mirages"] = true,
		["vaal_lightning_arrow_fork_and_chain_modifiers_apply_to_number_of_redirects"] = true,
		["virulent_arrow_number_of_pod_projectiles"] = true,
		["visual_hit_effect_chaos_is_green"] = true,
		["visual_hit_effect_elemental_is_holy"] = true,
		["wall_expand_delay_ms"] = true,
		["warcry_gain_mp_from_allies"] = true,
		["weapon_trap_rotation_speed_+%_if_dual_wielding"] = true,
		["weapon_trap_total_rotation_%_if_dual_wielding"] = true,
	},
	knownMonsterStats = {
		base_mana_regeneration_rate_per_minute = true,
		base_number_of_remote_mines_allowed = true,
		base_number_of_traps_allowed = true,
		cannot_be_afflicted = true,
		cannot_be_tagged_by_sentinel = true,
		cannot_have_affliction_mods = true,
		cannot_have_azmeri_dust = true,
		cant_possess_this = true,
		cant_touch_this = true,
		keystone_minion_instability = true,
		kill_traps_mines_and_totems_on_death = true,
		["life_regeneration_per_minute_%_for_hired_mercenary_out_of_combat_window"] = true,
		["map_related_item_drop_chance_+%_final_from_league"] = true,
		max_steel_ammo = true,
		maximum_rage = true,
		mines_invulnerable_for_duration_ms = true,
		monster_no_additional_player_scaling = true,
		monster_no_drops_or_experience = true,
		["monster_rarity_attack_cast_speed_+%_and_damage_-%_final"] = true,
		["monster_rarity_damage_+%_final"] = true,
		number_of_additional_totems_allowed = true,
		rage_loss_delay_ms = true,
		["set_base_attack_speed_+%_per_frenzy_charge"] = true,
		["set_base_attack_speed_+%_per_frenzy_charge_if_not_player_minion"] = true,
		["set_base_cast_speed_+%_per_frenzy_charge"] = true,
		["set_base_cast_speed_+%_per_frenzy_charge_if_not_player_minion"] = true,
		["set_base_mana_cost_-%"] = true,
		["set_critical_strike_chance_+%_per_power_charge"] = true,
		["set_critical_strike_chance_+%_per_power_charge_if_not_player_minion"] = true,
		["set_damage_taken_from_labyrinth_traps_+%"] = true,
		["set_elemental_damage_reduction_%_per_endurance_charge"] = true,
		set_ignore_skill_weapon_restrictions = true,
		set_item_drop_slots = true,
		["set_labyrinth_trap_degen_effect_on_self_+%"] = true,
		["set_minion_damage_taken_+%"] = true,
		["set_movement_velocity_+%_per_frenzy_charge_if_not_player_minion"] = true,
		set_movement_velocity_cap = true,
		["set_physical_damage_%_to_add_as_cold_per_brine_charge"] = true,
		["set_physical_damage_%_to_add_as_lightning_per_brine_charge"] = true,
		["set_physical_damage_reduction_%_per_endurance_charge"] = true,
		["set_physical_damage_reduction_%_per_endurance_charge_if_not_player_minion"] = true,
		["set_resist_all_elements_%_per_endurance_charge"] = true,
		["set_resist_all_elements_%_per_endurance_charge_if_not_player_minion"] = true,
		["set_totem_life_+%_final"] = true,
		traps_explode_on_timeout = true,
		traps_invulnerable_for_duration_ms = true,
	},
	-- Summoned Mercenary minion stats that PoB does not calculate. Combat-relevant
	-- minion stats belong in statMap instead; this list is engine/loot/AI metadata.
	-- Overlap with knownMonsterStats is allowed by the generated-data test, so only
	-- minion-unique exemptions live here.
	knownUncalculatedMinionStats = {
		cannot_be_stunned_for_ms_after_stun_finished = true,
		cannot_be_stunned_while_stunned = true,
		is_daemon = true,
		is_hidden_monster = true,
		["monster_dropped_item_quantity_+%"] = true,
		["monster_dropped_item_rarity_+%"] = true,
		["monster_slain_experience_+%"] = true,
		set_monster_do_not_fracture = true,
		set_monster_no_drops_or_experience = true,
		set_phase_through_objects = true,
		set_use_melee_pattern_range = true,
	},
	-- MercenarySkills references one of four support counts by name, and
	-- MercenarySupportCounts holds nothing but those names — the numbers are not in
	-- GGG's data at all. These maximums are hand-authored from in-game observation.
	-- (Distribution across the 272 skill rows: High 151, Low 49, None 46, Medium 26.)
	supportCounts = {
		None = { maximum = 0 },
		Low = { maximum = 2 },
		Medium = { maximum = 3 },
		High = { maximum = 5 },
	},
	-- Builds whose weapon configuration includes a Shield. DAT does not distinguish
	-- "can hold a shield" from "needs a shield", so every shield-capable build is
	-- classified here and export fails if a new one is missing.
	shieldPolicy = {
		AurasMinionsTemplarSmite = "required",
		AurasMinionsTemplarSmiteNoble = "required",
		AurasMinionsTemplarSmiteRuckusNoble = "required",
		AurasMinionsTemplarSpectres = "optional",
		AurasMinionsTemplarSpectresNoble = "optional",
		ChaosMinionWitchInstability = "required",
		ChaosMinionWitchInstabilityNoble = "required",
		Crit1HShadowPhysSpell = "optional",
		Crit1HShadowPhysSpellNoble = "optional",
		ElementalWitchCold = "optional",
		ElementalWitchColdNoble = "optional",
		ElementalWitchFire = "optional",
		ElementalWitchLightning = "optional",
		ElementalWitchLightningNoble = "optional",
		MeleeStrikesMarauderFire = "optional",
		MiscScionWandAttacks = "required",
		MiscScionWandAttacksNoble = "required",
		PhysicalDuelistShields = "required",
		PhysicalDuelistShieldsNoble = "required",
		TrapsMinesShadowCold = "required",
	},
	-- Non-DAT behavior the Mercenary actor needs. The permanent damage penalty's
	-- maximum is exported from Noble Blood's PassiveSkills row; the 3.29.1
	-- level taper lives in `MercenaryTools.permanentDamageMore`.
	permanentMercenary = {
		-- Damage over Time the Mercenary itself takes.
		damageOverTimeTakenMore = -80,
		-- A Taunted enemy deals less Damage to anyone other than whoever Taunted it,
		-- so the character and their Minions take less Damage while the Mercenary is
		-- holding the Taunt.
		tauntedDamageTakenMore = -10,
	},
	-- A Mercenary skill reuses the `preDamageFunc` of the player skill it was
	-- derived from, and with it that function's inputs. GGG's data does not always
	-- give the Mercenary variant the stats that populate them, which would leave
	-- the function reading nil. Every base whose function is inherited therefore
	-- lists the skill-data keys it reads without its own fallback, and validation
	-- rejects both a Mercenary skill that cannot populate one and a newly
	-- inherited function that has no entry here at all.
	preDamageFuncInputs = {
		BallLightningAltX = { "duration", "strikeInterval" },
		BallLightningAltY = { "duration", "strikeInterval" },
		BladeVortex = { "hitFrequency", "hitFrequencyPerBlade" },
		BladefallAltZ = { "hitFrequency", "incVolleyFrequency" },
		BlastRain = { },
		Bodyswap = { "selfFireExplosionLifeMultiplier" },
		ChargedDash = { },
		DarkPact = { "ChaosMax", "ChaosMin", "lifeDealtAsChaos" },
		DivineIre = { },
		Earthquake = { "duration" },
		EyeOfWinter = { },
		Flameblast = { },
		ForbiddenRite = { "ChaosMax", "ChaosMin", "SelfDamageTakenES", "SelfDamageTakenLife", "energyShieldDealtAsChaos", "lifeDealtAsChaos" },
		HeraldOfAsh = { "hoaMoreBurn", "hoaOverkillPercent" },
		InfernalBlowAltX = { },
		LancingSteel = { },
		LightningSpireTrap = { "duration", "radius", "repeatInterval" },
		MoltenShell = { "moltenShellReflect" },
		-- Reads the ball, chain-minimum and chain-maximum radii through the area of
		-- effect output rather than any stat of its own.
		MoltenStrike = { "radius", "radiusSecondary", "radiusTertiary" },
		OrbOfStorms = { "hitFrequency" },
		Perforate = { },
		ShrapnelBallista = { },
		Spark = { "duration" },
		StaticStrike = { "repeatFrequency" },
		StormRain = { "hitFrequency" },
		TornadoAltY = { "damageInterval" },
		TornadoShot = { },
		ToxicRain = { },
		VaalLightningArrow = { },
		VoidSphere = { "repeatFrequency" },
		VoltaxicBurst = { "duration" },
		Vortex = { },
		WaveOfConviction = { },
		WaveOfConvictionAltY = { },
	},
	-- Mercenary skills that GGG's data gives none of the stats their base skill's
	-- `preDamageFunc` reads, because the Mercenary version does not have that
	-- damage component at all. Dropping the inherited function keeps the missing
	-- component out of the numbers instead of reporting it as zero.
	droppedPreDamageFuncs = {
		-- Explodes the targeted corpse (`corpse_explosion_monster_life_permillage_fire`,
		-- handled by `explodeCorpse`) and has no self-explosion Life multiplier.
		BodyswapMercenary = "no self-explosion Life multiplier stat",
		-- Has none of Molten Shell's
		-- `molten_shell_%_of_absorbed_damage_dealt_as_reflected_fire`, so the
		-- Mercenary version deals no reflected Fire damage.
		MoltenShellMercenary = "no reflected Fire damage stat",
	},
	supportTemplates = {
		ArrowNovaHigh = "SupportArrowNova",
		TrapChargeGenHigh = "SupportChargedTraps",
		MirageArcherHigh = "SupportMirageArcher",
		ProjectilesReturnHigh = "SupportReturningProjectiles",
		FortifyHigh = "SupportFortify",
		MaimOnHitHigh = "SupportMaim",
		MeleeSplashHigh = "SupportMeleeSplash",
		MultiTotemHigh = "SupportMultipleTotems",
		FistOfWarHigh = "SupportFistofWar",
		SpellCascadeHigh = "SupportSpellCascade",
		SpellCascadeLow = "SupportSpellCascade",
		HallowHigh = "SupportHallow",
	},
	auxiliarySkills = {
		["curse_on_hit_%_elemental_weakness"] = "ElementalWeaknessMercenary",
		["curse_on_hit_%_vulnerability"] = "Vulnerability",
		["summon_sacred_wisps_on_hit"] = "SummonSacredWisp",
	},
	defaultSkillParts = {
		ElementalHitColdOnlyMercenary = 3,
		ElementalHitColdOnlyMercenaryEncounter = 3,
	},
	skillOverrides = {
		BarrageMercenary = {
			preDamageFunc = function(activeSkill, output)
				if activeSkill.skillPart == 2 then
					activeSkill.skillData.dpsMultiplier = output.ProjectileCount + 2 * (activeSkill.skillData.barrageFinalVolleyAdditionalProjectiles or 0)
				end
			end,
		},
		BarrageAltMercenary = {
			preDamageFunc = function(activeSkill, output)
				if activeSkill.skillPart == 2 then
					activeSkill.skillData.dpsMultiplier = output.ProjectileCount + 2 * (activeSkill.skillData.barrageFinalVolleyAdditionalProjectiles or 0)
				end
			end,
		},
		ActionSpeedAuraMercenary = {
			statMap = {
				["action_speed_-%"] = {
					mod("ActionSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff", effectName = "Trarthan Agility", applyAllies = true }),
					mult = -1,
				},
			},
		},
		AbyssalCryMercenary = {
			baseMods = {
				skill("explodeCorpse", true),
				skill("corpseExplosionDamageType", "Chaos"),
			},
			statMap = {
				["base_movement_velocity_+%"] = {
					mod("MovementSpeed", "INC", nil, 0, 0, enemyDebuff),
				},
			},
		},
		DonutCircleMercenary = {
			parts = {
				{ name = "Outer Area" },
				{ name = "Centre" },
			},
		},
		EnduringCryMercenary = {
			statMap = {
				["life_regeneration_rate_per_minute_%"] = {
					mod("LifeRegenPercent", "BASE", nil, 0, 0, allyWarcry),
					div = 60,
				},
			},
		},
		EnrageMercenary = {
			statMap = {
				["attack_and_cast_speed_+%"] = {
					mod("Speed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff", effectName = "Enrage" }),
				},
				["base_movement_velocity_+%"] = {
					mod("MovementSpeed", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff", effectName = "Enrage" }),
				},
				["damage_+%"] = {
					mod("Damage", "INC", nil, 0, 0, { type = "GlobalEffect", effectType = "Buff", effectName = "Enrage" }),
				},
			},
		},
		HolyFireMortarMercenary = {
			parts = {
				{ name = "First Hit" },
				{ name = "Second Hit" },
			},
		},
		InfernalCryMercenary = {
			baseMods = {
				skill("explodeCorpse", true),
				skill("corpseExplosionDamageType", "Fire"),
				skill("showAverage", true),
			},
		},
		-- Scorching Ray's stages are implemented per skill name, and the Spectre skill
		-- this inherits from leaves them out, so the Mercenary version restates the
		-- player mapping under its own name. Unlike the player skill there is no
		-- "Maximum Stages" part to select, so the stage cap is not tied to a part: a
		-- Totem channels its target continuously and ramps to the cap on its own.
		ScorchingRayTotemMercenary = { statMap = scorchingRayTotemStages },
		ScorchingRayTotemMercenaryEncounter = { statMap = scorchingRayTotemStages },
		TemporalAnomalyMercenary = {
			statMap = {
				["action_speed_-%"] = {
					mod("ActionSpeed", "INC", nil, 0, 0, enemyDebuff),
					mult = -1,
				},
			},
		},
		-- Vaal Flameblast's 15 maximum stages are a base mod on the player skill instead
		-- of a stat, so nothing implements the stat that the Mercenary's Maximum Stages
		-- support grants. Stage counts add, the way Flameblast's own stat does.
		VaalFlameblastMercenary = {
			statMap = {
				["flameblast_maximum_stages"] = {
					mod("Multiplier:VaalFlameblastMaxStages", "BASE", nil),
				},
			},
		},
		VaalVitalityMercenary = {
			statMap = {
				["life_regeneration_rate_per_minute_%"] = {
					mod("LifeRegenPercent", "BASE", nil, 0, 0, { type = "GlobalEffect", effectType = "Aura", effectName = "Vaal Vitality", applyAllies = true }),
					div = 60,
				},
			},
		},
		-- The generated skill data exposes the extra hit but no runtime DPS
		-- multiplier, so keep the Mercenary multiplier explicit here.
		VaalDoubleStrikeMercenary = {
			baseMods = {
				skill("dpsMultiplier", 2),
			},
		},
		VaalIceShotMercenary = {
			preDamageFunc = function(activeSkill, output)
				activeSkill.skillData.dpsMultiplier = 1 + (activeSkill.skillData.vaalIceShotMirageCount or 0)
			end,
		},
		BladeVortexAltMercenary = {
			preDamageFunc = calculateCorruptedBlood,
			baseMods = {
				flag("dotIsCorruptingBlood"),
				skill("debuffSecondary", true),
			},
		},
		BladeVortexAltMercenaryEncounter = {
			preDamageFunc = calculateCorruptedBlood,
			baseMods = {
				flag("dotIsCorruptingBlood"),
				skill("debuffSecondary", true),
			},
		},
	},
}
end
