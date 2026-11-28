-- Path of Building
--
-- Stat to internal modifier mapping table for the hidden stats of mercenary builds, used before the skill stat map
-- Stat data (c) Grinding Gear Games
--
return function(mod, flag)
return {
["maximum_life_+%"] = {
	mod("Life", "INC", nil),
},
["maximum_energy_shield_+%"] = {
	mod("EnergyShield", "INC", nil),
},
["evasion_rating_+%"] = {
	mod("Evasion", "INC", nil),
},
["energy_shield_delay_-%"] = {
	mod("EnergyShieldRechargeFaster", "INC", nil),
},
["base_strength"] = {
	mod("Str", "BASE", nil),
},
["base_dexterity"] = {
	mod("Dex", "BASE", nil),
},
["base_intelligence"] = {
	mod("Int", "BASE", nil),
},
["base_spell_suppression_chance_%"] = {
	mod("SpellSuppressionChance", "BASE", nil),
},
["base_phasing_without_visual"] = {
	flag("Condition:Phasing"),
},
["resolute_technique"] = {
	flag("CannotBeEvaded"),
	flag("NeverCrit"),
	flag("Condition:NeverCrit"),
},
["keystone_minion_instability"] = {
	mod("Keystone", "LIST", nil),
	value = "Minion Instability",
},
["minion_damage_increases_and_reductions_also_affects_you"] = {
	flag("MinionDamageAppliesToPlayer"),
},
}
end
