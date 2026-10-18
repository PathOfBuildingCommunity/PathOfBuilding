-- This file contains the matching base item types for each delve
-- drop-restricted mod. These are primarily primary types, but specifically rune
-- dagger refers to a subtype. Mods did not seem to be restricted to other subtypes.

-- spell-checker: disable
return {
	["AddedManaRegenerationDelve"] = {
		"Regenerate (3-5) Mana per second",
		["categories"] = {
			"Ring",
			"Amulet",
		},
	},
	["AddedPhysicalSpellDamageDelve___"] = {
		"Adds (11-22) to (34-46) Physical Damage to Spells",
		["categories"] = {
			"Amulet",
		},
	},
	["AdditionalCurseOnEnemiesDelve"] = {
		"You can apply an additional Curse",
		["categories"] = {
			"Shield",
			"Gloves",
		},
	},
	["AuraEffectOnEnemiesDelve_____"] = {
		"(12-18)% increased Effect of Non-Curse Auras from your Skills on Enemies",
		["categories"] = {
			"Gloves",
		},
	},
	["BleedingDamageChanceDelve__"] = {
		"(30-50)% increased Damage with Bleeding",
		"Attacks have 25% chance to cause Bleeding",
		["categories"] = {
			"Gloves",
		},
	},
	["ChaosDamageLifeLeechDelve"] = {
		"0.4% of Chaos Damage Leeched as Life",
		["categories"] = {
			"Ring",
		},
	},
	["ChaosDamageTakenDelve"] = {
		"(4-6)% reduced Chaos Damage taken",
		["categories"] = {
			"Body Armour",
		},
	},
	["ColdAilmentDurationDelve"] = {
		"(15-25)% increased Duration of Cold Ailments",
		["categories"] = {
			"Gloves",
		},
	},
	["ColdDamageLifeLeechDelve"] = {
		"0.4% of Cold Damage Leeched as Life",
		["categories"] = {
			"Ring",
		},
	},
	["ColdDamageTakenDelve"] = {
		"(4-6)% reduced Cold Damage taken",
		["categories"] = {
			"Body Armour",
		},
	},
	["CorruptedBloodImmunityDelve"] = {
		"Corrupted Blood cannot be inflicted on you",
		["categories"] = {
			"Shield",
		},
	},
	["CurseAreaOfEffectDelve"] = {
		"(25-40)% increased Area of Effect of Hex Skills",
		["categories"] = {
			"Ring",
		},
	},
	["CurseOnHitLevelConductivityDelve"] = {
		"Curse Enemies with Conductivity on Hit",
		["categories"] = {
			"Ring",
		},
	},
	["CurseOnHitLevelDespairDelve"] = {
		"Curse Enemies with Despair on Hit",
		["categories"] = {
			"Ring",
		},
	},
	["CurseOnHitLevelFlammabilityDelve"] = {
		"Curse Enemies with Flammability on Hit",
		["categories"] = {
			"Ring",
		},
	},
	["CurseOnHitLevelFrostbiteDelve"] = {
		"Curse Enemies with Frostbite on Hit",
		["categories"] = {
			"Ring",
		},
	},
	["CurseOnHitLevelVulnerabilityDelve"] = {
		"Curse Enemies with Vulnerability on Hit",
		["categories"] = {
			"Ring",
		},
	},
	["DoubleDamageChanceDelve"] = {
		"10% chance to deal Double Damage",
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
	["FasterBleedDelve"] = {
		"Bleeding you inflict deals Damage (5-10)% faster",
		["categories"] = {
			"Gloves",
		},
	},
	["FasterIgniteDelve_"] = {
		"Ignites you inflict deal Damage (5-10)% faster",
		["categories"] = {
			"Gloves",
		},
	},
	["FasterPoisonDelve_"] = {
		"Poisons you inflict deal Damage (5-10)% faster",
		["categories"] = {
			"Gloves",
		},
	},
	["FireDamageLifeLeechDelve"] = {
		"0.4% of Fire Damage Leeched as Life",
		["categories"] = {
			"Ring",
		},
	},
	["FireDamageTakenDelve"] = {
		"(4-6)% reduced Fire Damage taken",
		["categories"] = {
			"Body Armour",
		},
	},
	["ImpaleChanceDelve__"] = {
		"(5-10)% chance to Impale Enemies on Hit with Attacks",
		["categories"] = {
			"Ring",
		},
	},
	["IncreaseSocketedCurseGemLevelDelve_"] = {
		"+2 to Level of Socketed Curse Gems",
		["categories"] = {
			"Helmet",
		},
	},
	["IncreasedDamagePerCurseDelve"] = {
		"(8-10)% increased Damage with Hits and Ailments per Curse on Enemy",
		["categories"] = {
			"Amulet",
		},
	},
	["LifeReservationEfficiencyDelve"] = {
		"10% increased Life Reservation Efficiency of Skills",
		["categories"] = {
			"Ring",
		},
	},
	["LightningAilmentEffectDelve"] = {
		"(15-25)% increased Effect of Lightning Ailments",
		["categories"] = {
			"Gloves",
		},
	},
	["LightningDamageLifeLeechDelve__"] = {
		"0.4% of Lightning Damage Leeched as Life",
		["categories"] = {
			"Ring",
		},
	},
	["LightningDamageTakenDelve"] = {
		"(4-6)% reduced Lightning Damage taken",
		["categories"] = {
			"Body Armour",
		},
	},
	["LocalChaosDamageHybridDelve"] = {
		"(15-30)% increased Chaos Damage",
		"Adds (18-28) to (39-49) Chaos Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
		},
	},
	["LocalChaosDamageHybridTwoHandDelve"] = {
		"(15-30)% increased Chaos Damage",
		"Adds (32-50) to (68-86) Chaos Damage",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalColdDamageHybridDelve"] = {
		"(20-40)% increased Cold Damage",
		"Adds (15-20) to (30-35) Cold Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
		},
	},
	["LocalColdDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Cold Damage",
		"Adds (26-35) to (52-60) Cold Damage",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalFireDamageHybridDelve"] = {
		"(20-40)% increased Fire Damage",
		"Adds (18-24) to (36-42) Fire Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
		},
	},
	["LocalFireDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Fire Damage",
		"Adds (31-42) to (64-74) Fire Damage",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["LocalIncreaseSocketedAuraLevelDelve"] = {
		"+2 to Level of Socketed Aura Gems",
		["categories"] = {
			"Helmet",
			"Shield",
		},
	},
	["LocalIncreaseSocketedMinionGemLevelDelve"] = {
		"+2 to Level of Socketed Minion Gems",
		["categories"] = {
			"Boots",
		},
	},
	["LocalLightningDamageHybridDelve"] = {
		"(20-40)% increased Lightning Damage",
		"Adds (2-5) to (63-66) Lightning Damage",
		["categories"] = {
			"Claw",
			"Dagger",
			"Wand",
			"One Handed Sword",
			"One Handed Axe",
			"One Handed Mace",
		},
	},
	["LocalLightningDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Lightning Damage",
		"Adds (2-9) to (110-116) Lightning Damage",
		["categories"] = {
			"Bow",
			"Staff",
			"Two Handed Sword",
			"Two Handed Axe",
			"Two Handed Mace",
		},
	},
	["MarkEffectDelve"] = {
		"(15-25)% increased Effect of your Marks",
		["categories"] = {
			"Shield",
		},
	},
	["MaximumManaIncreasePercentDelve_"] = {
		"(10-15)% increased maximum Mana",
		["categories"] = {
			"Amulet",
		},
	},
	["MaximumMinionCountSkeletonDelve"] = {
		"+1 to maximum number of Skeletons",
		["categories"] = {
			"Body Armour",
		},
	},
	["MaximumMinionCountSpectreDelve"] = {
		"+1 to maximum number of Spectres",
		["categories"] = {
			"Body Armour",
		},
	},
	["MaximumMinionCountZombieDelve"] = {
		"+1 to maximum number of Raised Zombies",
		["categories"] = {
			"Body Armour",
		},
	},
	["MinionAreaOfEffectDelve"] = {
		"Minions have (20-30)% increased Area of Effect",
		["categories"] = {
			"Wand",
		},
	},
	["MinionCriticalStrikeMultiplierDelve"] = {
		"Minions have +(30-38)% to Critical Strike Multiplier",
		["categories"] = {
			"Wand",
		},
	},
	["MinionDamageDelve"] = {
		"Minions deal (25-35)% increased Damage",
		["categories"] = {
			"Ring",
		},
	},
	["MinionLargerAggroRadiusDelve"] = {
		"Minions are Aggressive",
		["categories"] = {
			"Wand",
		},
	},
	["MinionLeechDelve___"] = {
		"Minions Leech 1% of Damage as Life",
		["categories"] = {
			"Wand",
		},
	},
	["PercentDamageGoesToManaDelve"] = {
		"(5-8)% of Damage taken Recouped as Mana",
		["categories"] = {
			"Helmet",
			"Boots",
		},
	},
	["PhysicalDamageConvertedToColdDelve"] = {
		"10% of Physical Damage Converted to Cold Damage",
		["categories"] = {
			"Ring",
		},
	},
	["PhysicalDamageConvertedToFireDelve"] = {
		"10% of Physical Damage Converted to Fire Damage",
		["categories"] = {
			"Ring",
		},
	},
	["PhysicalDamageConvertedToLightningDelve"] = {
		"10% of Physical Damage Converted to Lightning Damage",
		["categories"] = {
			"Ring",
		},
	},
	["ReducedManaReservationsCostDelve_"] = {
		"10% increased Mana Reservation Efficiency of Skills",
		["categories"] = {
			"Helmet",
		},
	},
	["SpellAddedChaosDamageHybridDelve"] = {
		"(15-30)% increased Chaos Damage",
		"Adds (14-19) to (29-33) Chaos Damage to Spells",
		["categories"] = {
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["SpellAddedChaosDamageHybridTwoHandDelve"] = {
		"(15-30)% increased Chaos Damage",
		"Adds (23-30) to (45-53) Chaos Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["SpellAddedColdDamageHybridDelve_"] = {
		"(20-40)% increased Cold Damage",
		"Adds (15-20) to (30-35) Cold Damage to Spells",
		["categories"] = {
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["SpellAddedColdDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Cold Damage",
		"Adds (27-36) to (54-63) Cold Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["SpellAddedFireDamageHybridDelve"] = {
		"(20-40)% increased Fire Damage",
		"Adds (18-25) to (36-43) Fire Damage to Spells",
		["categories"] = {
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["SpellAddedFireDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Fire Damage",
		"Adds (30-39) to (59-69) Fire Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["SpellAddedLightningDamageHybridDelve"] = {
		"(20-40)% increased Lightning Damage",
		"Adds (1-5) to (63-66) Lightning Damage to Spells",
		["categories"] = {
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["SpellAddedLightningDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Lightning Damage",
		"Adds (3-9) to (114-120) Lightning Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["SpellAddedPhysicalDamageHybridDelve"] = {
		"(20-40)% increased Global Physical Damage",
		"Adds (14-19) to (29-33) Physical Damage to Spells",
		["categories"] = {
			"Sceptre",
			"Dagger: Rune Dagger",
		},
	},
	["SpellAddedPhysicalDamageHybridTwoHandDelve"] = {
		"(20-40)% increased Global Physical Damage",
		"Adds (23-30) to (45-53) Physical Damage to Spells",
		["categories"] = {
			"Staff",
		},
	},
	["SpiritAndPhantasmRefreshOnUniqueDelve"] = {
		"Summoned Phantasms have 5% chance to refresh their Duration when they Hit a Rare or Unique Enemy",
		"Summoned Raging Spirits have 5% chance to refresh their Duration when they Hit a Rare or Unique Enemy",
		["categories"] = {
			"Gloves",
		},
	},
	["ZeroChaosResistanceDelve"] = {
		"Chaos Resistance is Zero",
		["categories"] = {
			"Helmet",
		},
	},
}
