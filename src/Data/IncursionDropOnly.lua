-- This file contains the matching base item types for each incursion
-- drop-restricted mod. These are primarily primary types, but specifically rune
-- dagger refers to a subtype. Mods did not seem to be restricted to other subtypes.

-- spell-checker: disable
return {
	["AddedColdDamageEnhancedMod"] = {
		"25% of Physical Damage Converted to Cold Damage",
		"Adds (5-7) to (10-12) Cold Damage to Attacks",
		["categories"] = {
			"Gloves",
		},
	},
	["AddedFireDamageEnhancedLevel50Mod"] = {
		"25% of Physical Damage Converted to Fire Damage",
		"Adds (5-7) to (11-13) Fire Damage to Attacks",
		["categories"] = {
			"Gloves",
		},
	},
	["AddedLightningDamageEnhancedLevel50Mod"] = {
		"25% of Physical Damage Converted to Lightning Damage",
		"Adds (1-2) to (22-23) Lightning Damage to Attacks",
		["categories"] = {
			"Gloves",
		},
	},
	["ChanceToPoisonEnhancedLevel50Mod"] = {
		"(26-30)% increased Chaos Damage",
		"30% chance to Poison on Hit",
		["categories"] = {
			"Claw",
			"Dagger",
			"One Handed Sword",
			"Dagger: Rune Dagger",
			"Bow",
			"Two Handed Sword",
		},
	},
	["ChaosResistEnhancedLevel50Mod"] = {
		"(5-7)% reduced Chaos Damage taken over time",
		"+(31-35)% to Chaos Resistance",
		["categories"] = {
			"Body Armour",
			"Shield",
		},
	},
	["ColdDamagePrefixOnTwoHandWeaponEnhancedLevel50Mod"] = {
		"(131-138)% increased Cold Damage",
		"Adds (19-25) to (37-44) Cold Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["ColdDamagePrefixOnWeaponEnhancedLevel50Mod"] = {
		"(75-79)% increased Cold Damage",
		"Adds (12-16) to (25-29) Cold Damage to Spells",
		["categories"] = {
			"Wand",
			"Sceptre",
			"Shield",
		},
	},
	["ColdResistEnhancedLevel50ModLeechInverted"] = {
		"+(46-48)% to Cold Resistance",
		"0.4% of Cold Damage Leeched by Enemy as Life",
		["categories"] = {
			"Amulet",
		},
	},
	["ColdResistEnhancedLevel50ModPhys_"] = {
		"(3-5)% of Physical Damage from Hits taken as Cold Damage",
		"+(46-48)% to Cold Resistance",
		["categories"] = {
			"Helmet",
		},
	},
	["ColdResistEnhancedModAilments__"] = {
		"(30-50)% increased Damage with Hits against Chilled Enemies",
		"+(46-48)% to Cold Resistance",
		["categories"] = {
			"Gloves",
		},
	},
	["ColdResistEnhancedModLeech"] = {
		"+(46-48)% to Cold Resistance",
		"0.4% of Cold Damage Leeched as Life",
		["categories"] = {
			"Amulet",
		},
	},
	["FireDamagePrefixOnTwoHandWeaponEnhancedLevel50Mod__"] = {
		"(131-138)% increased Fire Damage",
		"Adds (20-27) to (41-48) Fire Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["FireDamagePrefixOnWeaponEnhancedLevel50Mod"] = {
		"(75-79)% increased Fire Damage",
		"Adds (15-20) to (30-35) Fire Damage to Spells",
		["categories"] = {
			"Wand",
			"Sceptre",
			"Shield",
		},
	},
	["FireResistEnhancedLevel50ModAilments_"] = {
		"(45-52) to (75-78) added Fire Damage against Burning Enemies",
		"+(46-48)% to Fire Resistance",
		["categories"] = {
			"Gloves",
		},
	},
	["FireResistEnhancedLevel50ModLeech"] = {
		"+(46-48)% to Fire Resistance",
		"0.4% of Fire Damage Leeched as Life",
		["categories"] = {
			"Amulet",
		},
	},
	["FireResistEnhancedLevel50ModLeechInverted"] = {
		"+(46-48)% to Fire Resistance",
		"0.4% of Fire Damage Leeched by Enemy as Life",
		["categories"] = {
			"Amulet",
		},
	},
	["FireResistEnhancedLevel50ModPhys"] = {
		"(3-5)% of Physical Damage from Hits taken as Fire Damage",
		"+(46-48)% to Fire Resistance",
		["categories"] = {
			"Helmet",
		},
	},
	["IncreasedCastSpeedEnhancedLevel50Mod"] = {
		"(29-32)% increased Cast Speed",
		"Adds (17-24) to (36-40) Chaos Damage to Spells",
		["categories"] = {
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["IncreasedCastSpeedTwoHandEnhancedLevel50Mod"] = {
		"(44-49)% increased Cast Speed",
		"Adds (24-32) to (49-57) Chaos Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["IncreasedEnergyShieldEnhancedLevel50ModES_"] = {
		"+(44-47) to maximum Energy Shield",
		"3% increased maximum Energy Shield",
		["categories"] = {
			"Amulet",
			"Ring",
			"Belt",
		},
	},
	["IncreasedEnergyShieldEnhancedModRegen_"] = {
		"+(44-47) to maximum Energy Shield",
		"Regenerate 0.4% of Energy Shield per second",
		["categories"] = {
			"Amulet",
			"Ring",
			"Belt",
		},
	},
	["IncreasedLifeEnhancedBodyMod___"] = {
		"(8-10)% increased maximum Life",
		"+(110-119) to maximum Life",
		["categories"] = {
			"Body Armour",
		},
	},
	["IncreasedLifeEnhancedLevel50Mod_"] = {
		"+(70-79) to maximum Life",
		"2% increased maximum Life",
		["categories"] = {
			"Amulet",
			"Ring",
			"Belt",
		},
	},
	["IncreasedManaEnhancedLevel50ModCostNew"] = {
		"+(74-78) to maximum Mana",
		"Non-Channelling Skills have -(8-6) to Total Mana Cost",
		["categories"] = {
			"Ring",
		},
	},
	["IncreasedManaEnhancedLevel50ModOnHit"] = {
		"+(74-78) to maximum Mana",
		"Gain (2-3) Mana per Enemy Hit with Attacks",
		["categories"] = {
			"Ring",
		},
	},
	["IncreasedManaEnhancedLevel50ModRegenInverted"] = {
		"+(74-78) to maximum Mana",
		"Lose (5-7) Mana per second",
		["categories"] = {
			"Amulet",
			"Ring",
		},
	},
	["IncreasedManaEnhancedLevel50ModReservation_"] = {
		"(6-10)% increased Mana Reservation Efficiency of Skills",
		"+(69-73) to maximum Mana",
		["categories"] = {
			"Helmet",
		},
	},
	["IncreasedManaEnhancedModPercent"] = {
		"(7-10)% increased maximum Mana",
		"+(69-73) to maximum Mana",
		["categories"] = {
			"Amulet",
			"Gloves",
			"Boots",
			"Helmet",
		},
	},
	["IncreasedManaEnhancedModRegen"] = {
		"+(74-78) to maximum Mana",
		"Regenerate (5-7) Mana per second",
		["categories"] = {
			"Amulet",
			"Ring",
		},
	},
	["LifeRegenerationEnhancedLevel50Mod"] = {
		"Regenerate (32-40) Life per second",
		"Regenerate 0.4% of Life per second",
		["categories"] = {
			"Amulet",
			"Ring",
			"Belt",
		},
	},
	["LightningDamagePrefixOnTwoHandWeaponEnhancedLevel50Mod"] = {
		"(131-138)% increased Lightning Damage",
		"Adds (2-6) to (79-84) Lightning Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["LightningDamagePrefixOnWeaponEnhancedLevel50Mod_"] = {
		"(75-79)% increased Lightning Damage",
		"Adds (1-4) to (53-56) Lightning Damage to Spells",
		["categories"] = {
			"Wand",
			"Sceptre",
			"Shield",
		},
	},
	["LightningResistEnhancedLevel50ModAilments"] = {
		"(40-60)% increased Critical Strike Chance against Shocked Enemies",
		"+(46-48)% to Lightning Resistance",
		["categories"] = {
			"Gloves",
		},
	},
	["LightningResistEnhancedLevel50ModLeech"] = {
		"+(46-48)% to Lightning Resistance",
		"0.4% of Lightning Damage Leeched as Life",
		["categories"] = {
			"Amulet",
		},
	},
	["LightningResistEnhancedLevel50ModLeechInverted"] = {
		"+(46-48)% to Lightning Resistance",
		"0.4% of Lightning Damage Leeched by Enemy as Life",
		["categories"] = {
			"Amulet",
		},
	},
	["LightningResistEnhancedLevel50ModPhys"] = {
		"(3-5)% of Physical Damage from Hits taken as Lightning Damage",
		"+(46-48)% to Lightning Resistance",
		["categories"] = {
			"Helmet",
		},
	},
	["LocalAddedColdDamageEnhancedLevel50Mod"] = {
		"Adds (37-50) to (74-87) Cold Damage",
		"Attacks with this Weapon Penetrate (5-7)% Cold Resistance",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["LocalAddedColdDamageEnhancedLevel50TwoHandMod"] = {
		"Adds (65-87) to (130-152) Cold Damage",
		"Attacks with this Weapon Penetrate (5-7)% Cold Resistance",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalAddedFireDamageEnhancedLevel50Mod"] = {
		"Adds (45-61) to (91-106) Fire Damage",
		"Attacks with this Weapon Penetrate (5-7)% Fire Resistance",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["LocalAddedFireDamageEnhancedLevel50TwoHandMod"] = {
		"Adds (79-106) to (159-186) Fire Damage",
		"Attacks with this Weapon Penetrate (5-7)% Fire Resistance",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalAddedLightningDamageEnhancedLevel50Mod"] = {
		"Adds (4-13) to (158-166) Lightning Damage",
		"Attacks with this Weapon Penetrate (5-7)% Lightning Resistance",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["LocalAddedLightningDamageEnhancedLevel50TwoHandMod"] = {
		"Adds (7-22) to (275-290) Lightning Damage",
		"Attacks with this Weapon Penetrate (5-7)% Lightning Resistance",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalIncreaseSocketedTrapGemLevelEnhancedLevel50Mod_"] = {
		"+2 to Level of Socketed Trap or Mine Gems",
		["categories"] = {
			"Staff",
		},
	},
	["LocalIncreasedAttackSpeedEnhancedLevel50Mod"] = {
		"(26-27)% increased Attack Speed",
		"Adds (23-36) to (49-61) Chaos Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
			"Sceptre",
			"Dagger: Rune Dagger",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalIncreasedAttackSpeedRangedEnhancedLevel50Mod"] = {
		"(14-16)% increased Attack Speed",
		"Adds (23-36) to (49-61) Chaos Damage",
		["categories"] = {
			"Wand",
			"Bow",
		},
	},
	["LocalIncreasedPhysicalDamageEnhancedLevel50Mod"] = {
		"(155-169)% increased Physical Damage",
		"Gain (3-5)% of Physical Damage as Extra Chaos Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
			"Sceptre",
			"Dagger: Rune Dagger",
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["MineAreaOfEffectEnhancedLevel50Mod"] = {
		"Skills used by Mines have (22-25)% increased Area of Effect",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["MineAreaOfEffectTwoHandEnhancedLevel50Mod_"] = {
		"Skills used by Mines have (33-37)% increased Area of Effect",
		["categories"] = {
			"Staff",
		},
	},
	["MineDamageOnTwoHandWeaponEnhancedLevel50Mod"] = {
		"(158-166)% increased Mine Damage",
		["categories"] = {
			"Staff",
		},
	},
	["MineDamageOnWeaponEnhancedLevel50Mod"] = {
		"(90-95)% increased Mine Damage",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["MineDetonationSpeedAndDurationEnhancedLevel50Mod_"] = {
		"(17-20)% increased Mine Duration",
		"Mines have (14-15)% increased Detonation Speed",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["MineDetonationSpeedAndDurationTwoHandEnhancedLevel50Mod"] = {
		"(26-30)% increased Mine Duration",
		"Mines have (21-22)% increased Detonation Speed",
		["categories"] = {
			"Staff",
		},
	},
	["MineThrowSpeedEnhancedLevel50Mod"] = {
		"(20-22)% increased Mine Throwing Speed",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["MineThrowSpeedTwoHandEnhancedLevel50Mod"] = {
		"(30-33)% increased Mine Throwing Speed",
		["categories"] = {
			"Staff",
		},
	},
	["MinionAttackAndCastSpeedEnhancedLevel50Mod_"] = {
		"Minions have (25-28)% increased Attack Speed",
		"Minions have (25-28)% increased Cast Speed",
		["categories"] = {
			"Wand",
			"Sceptre",
		},
	},
	["MinionAttackAndCastSpeedTwoHandEnhancedLevel50Mod_"] = {
		"Minions have (36-40)% increased Attack Speed",
		"Minions have (36-40)% increased Cast Speed",
		["categories"] = {
			"Staff",
		},
	},
	["MinionDamageOnTwoHandWeaponEnhancedLevel50ModNew"] = {
		"Minions deal (85-94)% increased Damage",
		"Minions have 5% chance to deal Double Damage",
		["categories"] = {
			"Staff",
		},
	},
	["MinionDamageOnWeaponEnhancedLevel50ModNew"] = {
		"Minions deal (50-66)% increased Damage",
		"Minions have 5% chance to deal Double Damage",
		["categories"] = {
			"Wand",
			"Sceptre",
		},
	},
	["MinionDurationEnhancedLevel50Mod_"] = {
		"(17-20)% increased Minion Duration",
		["categories"] = {
			"Wand",
			"Sceptre",
		},
	},
	["MinionDurationTwoHandedEnhancedLevel50Mod_"] = {
		"(27-30)% increased Minion Duration",
		["categories"] = {
			"Staff",
		},
	},
	["MovementVelocityEnhancedLevel50ModDodge"] = {
		"(10-15)% chance to Avoid Bleeding",
		"30% increased Movement Speed",
		["categories"] = {
			"Boots",
		},
	},
	["MovementVelocityEnhancedLevel50ModSpellDodge__"] = {
		"(10-15)% chance to Avoid being Poisoned",
		"30% increased Movement Speed",
		["categories"] = {
			"Boots",
		},
	},
	["MovementVelocityEnhancedModSpeed"] = {
		"30% increased Movement Speed",
		"5% increased Movement Speed if you haven't been Hit Recently",
		["categories"] = {
			"Boots",
		},
	},
	["PoisonDamageEnhancedLevel50AttacksMod_"] = {
		"(31-35)% increased Damage with Poison",
		"Adds (23-36) to (49-61) Chaos Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"One Handed Sword",
			"Dagger: Rune Dagger",
			"Bow",
			"Two Handed Sword",
		},
	},
	["PoisonDamageEnhancedLevel50SpellsMod"] = {
		"(31-35)% increased Damage with Poison",
		"Adds (17-24) to (36-40) Chaos Damage to Spells",
		["categories"] = {
			"Dagger",
			"Dagger: Rune Dagger",
		},
	},
	["PoisonDurationEnhancedMod"] = {
		"(13-18)% increased Poison Duration",
		"(26-30)% increased Chaos Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"One Handed Sword",
			"Dagger: Rune Dagger",
			"Bow",
			"Two Handed Sword",
		},
	},
	["SpellDamageOnTwoHandWeaponEnhancedLevel50Mod"] = {
		"(123-130)% increased Spell Damage",
		"Gain 5% of Non-Chaos Damage as extra Chaos Damage",
		["categories"] = {
			"Staff",
		},
	},
	["SpellDamageOnWeaponEnhancedMod"] = {
		"(70-74)% increased Spell Damage",
		"Gain 5% of Non-Chaos Damage as extra Chaos Damage",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["TrapAreaOfEffectEnhancedLevel50Mod"] = {
		"Skills used by Traps have (22-25)% increased Area of Effect",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["TrapAreaOfEffectTwoHandEnhancedLevel50Mod_"] = {
		"Skills used by Traps have (33-37)% increased Area of Effect",
		["categories"] = {
			"Staff",
		},
	},
	["TrapCooldownRecoveryAndDurationEnhancedLevel50Mod__"] = {
		"(14-15)% increased Cooldown Recovery Rate for throwing Traps",
		"(17-20)% increased Trap Duration",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["TrapCooldownRecoveryAndDurationTwoHandEnhancedLevel50Mod"] = {
		"(21-22)% increased Cooldown Recovery Rate for throwing Traps",
		"(26-30)% increased Trap Duration",
		["categories"] = {
			"Staff",
		},
	},
	["TrapDamageOnTwoHandWeaponEnhancedMod"] = {
		"(158-166)% increased Trap Damage",
		["categories"] = {
			"Staff",
		},
	},
	["TrapDamageOnWeaponEnhancedLevel50Mod"] = {
		"(90-95)% increased Trap Damage",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["TrapThrowSpeedEnhancedMod"] = {
		"(20-22)% increased Trap Throwing Speed",
		["categories"] = {
			"Dagger",
			"Wand",
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["TrapThrowSpeedTwoHandEnhancedLevel50Mod"] = {
		"(30-33)% increased Trap Throwing Speed",
		["categories"] = {
			"Staff",
		},
	},
	["WeaponSpellDamageTriggerSkillOnTwoHandWeaponEnhancedLevel50Mod"] = {
		"(123-130)% increased Spell Damage",
		"Spells Triggered this way have 150% more Cost",
		"Trigger a Socketed Spell on Using a Skill, with a 4 second Cooldown",
		["categories"] = {
			"Staff",
		},
	},
	["WeaponSpellDamageTriggerSkillOnWeaponEnhancedLevel50Mod"] = {
		"(70-74)% increased Spell Damage",
		"Spells Triggered this way have 150% more Cost",
		"Trigger a Socketed Spell on Using a Skill, with a 4 second Cooldown",
		["categories"] = {
			"Wand",
			"Sceptre",
		},
	},
}
