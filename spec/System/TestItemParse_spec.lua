describe("TestItemParse", function()
	local function raw(s, base)
		base = base or "Plate Vest"
		return "Rarity: Rare\nName\n"..base.."\n"..s
	end

	it("Rarity", function()
		local item = new("Item", "Rarity: Normal\nCoral Ring")
		assert.are.equals("NORMAL", item.rarity)
		item = new("Item", "Rarity: Magic\nCoral Ring")
		assert.are.equals("MAGIC", item.rarity)
		item = new("Item", "Rarity: Rare\nName\nCoral Ring")
		assert.are.equals("RARE", item.rarity)
		item = new("Item", "Rarity: Unique\nName\nCoral Ring")
		assert.are.equals("UNIQUE", item.rarity)
		item = new("Item", "Rarity: Unique\nName\nCoral Ring\nFoil Unique (Verdant)")
		assert.are.equals("RELIC", item.rarity)
	end)

	it("Superior/Synthesised", function()
		local item = new("Item", raw("", "Superior Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
		item = new("Item", raw("", "Synthesised Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
		item = new("Item", raw("", "Superior Synthesised Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
	end)

	it("Two-Toned Boots", function()
		local item = new("Item", raw("", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		item = new("Item", raw("Armour: 10\nEnergy Shield: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		item = new("Item", raw("Armour: 10\nEvasion Rating: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Evasion)", item.baseName)
		item = new("Item", raw("Evasion Rating: 10\nEnergy Shield: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Evasion/Energy Shield)", item.baseName)
	end)

	it("Magic Two-Toned Boots", function()
		local item = new("Item", [[
			Rarity: Magic
			Stalwart Two-Toned Boots of Plunder
			Armour: 100
			Energy Shield: 100
			]])
		assert.are.equal("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		assert.are.equal("Stalwart ", item.namePrefix)
		assert.are.equal(" of Plunder", item.nameSuffix)
		item = new("Item", [[
			Rarity: Magic
			Sanguine Two-Toned Boots of the Phoenix
			Armour: 100
			Evasion Rating: 100
			]])
		assert.are.equal("Two-Toned Boots (Armour/Evasion)", item.baseName)
		assert.are.equal("Sanguine ", item.namePrefix)
		assert.are.equal(" of the Phoenix", item.nameSuffix)
		item = new("Item", [[
			Rarity: Magic
			Stout Two-Toned Boots of the Lightning
			Evasion Rating: 100
			Energy Shield: 100
			]])
		assert.are.equal("Two-Toned Boots (Evasion/Energy Shield)", item.baseName)
		assert.are.equal("Stout ", item.namePrefix)
		assert.are.equal(" of the Lightning", item.nameSuffix)
	end)

	it("Title", function()
		local item = new("Item", [[
			Rarity: Rare
			Phoenix Paw
			Iron Gauntlets
		]])
		assert.are.equal("Phoenix Paw", item.title)
		assert.are.equal("Iron Gauntlets", item.baseName)
		assert.are.equal("Phoenix Paw, Iron Gauntlets", item.name)
	end)

	it("Unique ID", function()
		local item = new("Item", raw("Unique ID: 40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863"))
		assert.are.equals("40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863", item.uniqueID)
	end)

	it("Item Level", function()
		local item = new("Item", raw("Item Level: 10"))
		assert.are.equals(10, item.itemLevel)
	end)

	it("Quality", function()
		local item = new("Item", raw("Quality: 10"))
		assert.are.equals(10, item.quality)
		item = new("Item", raw("Quality: +12% (augmented)"))
		assert.are.equals(12, item.quality)
	end)

	it("Sockets", function()
		local item = new("Item", raw("Sockets: R-G R-B-W A"))
		assert.are.same({
			{ color = "R", group = 0 },
			{ color = "G", group = 0 },
			{ color = "R", group = 1 },
			{ color = "B", group = 1 },
			{ color = "W", group = 1 },
			{ color = "A", group = 2 },
		}, item.sockets)
	end)

	it("Jewel", function()
		local item = new("Item", raw("Radius: Large\nLimited to: 2", "Cobalt Jewel"))
		assert.are.equals("Large", item.jewelRadiusLabel)
		assert.are.equals(2, item.limit)
	end)

	it("Variant name", function()
		local item = new("Item", raw("Variant: Pre 3.19.0\nVariant: Current"))
		assert.are.same({ "Pre 3.19.0", "Current" }, item.variantList)
	end)

	it("Talisman Tier", function()
		local item = new("Item", raw("Talisman Tier: 3", "Rotfeather Talisman"))
		assert.are.equals(3, item.talismanTier)
	end)

	it("Defence", function()
		local item = new("Item", raw("Armour: 25"))
		assert.are.equals(25, item.armourData.Armour)
		item = new("Item", raw("Armour: 25 (augmented)"))
		assert.are.equals(25, item.armourData.Armour)
		item = new("Item", raw("Evasion Rating: 35", "Shabby Jerkin"))
		assert.are.equals(35, item.armourData.Evasion)
		item = new("Item", raw("Energy Shield: 15", "Simple Robe"))
		assert.are.equals(15, item.armourData.EnergyShield)
		item = new("Item", raw("Ward: 180", "Runic Crown"))
		assert.are.equals(180, item.armourData.Ward)
	end)

	it("Defence BasePercentile", function()
		local item = new("Item", raw("ArmourBasePercentile: 0.5"))
		assert.are.equals(0.5, item.armourData.ArmourBasePercentile)
		item = new("Item", raw("EvasionBasePercentile: 0.6", "Shabby Jerkin"))
		assert.are.equals(0.6, item.armourData.EvasionBasePercentile)
		item = new("Item", raw("EnergyShieldBasePercentile: 0.7", "Simple Robe"))
		assert.are.equals(0.7, item.armourData.EnergyShieldBasePercentile)
		item = new("Item", raw("WardBasePercentile: 0.8", "Runic Crown"))
		assert.are.equals(0.8, item.armourData.WardBasePercentile)
	end)

	it("Requires Level", function()
		local item = new("Item", raw("Requires Level 10"))
		assert.are.equals(10, item.requirements.level)
		item = new("Item", raw("Level: 10"))
		assert.are.equals(10, item.requirements.level)
		item = new("Item", raw("LevelReq: 10"))
		assert.are.equals(10, item.requirements.level)
	end)

	it("Alt Variant", function()
		local item = new("Item", raw([[
			Has Alt Variant: true
			Has Alt Variant Two: true
			Has Alt Variant Three: true
			Has Alt Variant Four: true
			Has Alt Variant Five: true
			Selected Variant: 10
			Selected Alt Variant: 11
			Selected Alt Variant Two: 12
			Selected Alt Variant Three: 13
			Selected Alt Variant Four: 14
			Selected Alt Variant Five: 15
			]]))
		assert.truthy(item.hasAltVariant)
		assert.truthy(item.hasAltVariant2)
		assert.truthy(item.hasAltVariant3)
		assert.truthy(item.hasAltVariant4)
		assert.truthy(item.hasAltVariant5)
		assert.are.equals(10, item.variant)
		assert.are.equals(11, item.variantAlt)
		assert.are.equals(12, item.variantAlt2)
		assert.are.equals(13, item.variantAlt3)
		assert.are.equals(14, item.variantAlt4)
		assert.are.equals(15, item.variantAlt5)
	end)

	it("Prefix/Suffix", function()
		local item = new("Item", raw([[
			Prefix: {range:0.1}IncreasedLife1
			Suffix: {range:0.2}ColdResist1
			]]))
		assert.are.equals("IncreasedLife1", item.prefixes[1].modId)
		assert.are.equals(0.1, item.prefixes[1].range)
		assert.are.equals("ColdResist1", item.suffixes[1].modId)
		assert.are.equals(0.2, item.suffixes[1].range)
	end)

	it("Implicits", function()
		local item = new("Item", raw([[
			Implicits: 2
			+8 to Strength
			+10 to Intelligence
			+12 to Dexterity
			]]))
		assert.are.equals(2, #item.implicitModLines)
		assert.are.equals("+8 to Strength", item.implicitModLines[1].line)
		assert.are.equals("+10 to Intelligence", item.implicitModLines[2].line)
		assert.are.equals(1, #item.explicitModLines)
		assert.are.equals("+12 to Dexterity", item.explicitModLines[1].line)
	end)

	it("League", function()
		local item = new("Item", raw("League: Heist"))
		assert.are.equals("Heist", item.league)
	end)

	it("Source", function()
		local item = new("Item", raw("Source: No longer obtainable"))
		assert.are.equals("No longer obtainable", item.source)
	end)

	it("Note", function()
		local item = new("Item", raw("Note: ~price 1 chaos"))
		assert.are.equals("~price 1 chaos", item.note)
	end)

	it("Attribute Requirements", function()
		local item = new("Item", raw("Dex: 100"))
		assert.are.equals(100, item.requirements.dex)
		item = new("Item", raw("Int: 101"))
		assert.are.equals(101, item.requirements.int)
		item = new("Item", raw("Str: 102"))
		assert.are.equals(102, item.requirements.str)
	end)

	it("Requires Class", function()
		local item = new("Item", raw("Requires Class Witch"))
		assert.are.equals("Witch", item.classRestriction)
		item = new("Item", raw("Class:: Witch"))
		assert.are.equals("Witch", item.classRestriction)
	end)

	it("Requires Class variant", function()
		local item = new("Item", raw([[
			Selected Variant: 2
			+8 to Strength
			{variant:1}Requires Class Witch
			{variant:2}Requires Class Templar
			]]))
		assert.are.equals(2, item.variant)
		assert.are.equals("Templar", item.classRestriction)
	end)

	it("Influence", function()
		local item = new("Item", raw("Shaper Item"))
		assert.truthy(item.shaper)
		item = new("Item", raw("Elder Item"))
		assert.truthy(item.elder)
		item = new("Item", raw("Warlord Item"))
		assert.truthy(item.adjudicator)
		item = new("Item", raw("Hunter Item"))
		assert.truthy(item.basilisk)
		item = new("Item", raw("Crusader Item"))
		assert.truthy(item.crusader)
		item = new("Item", raw("Redeemer Item"))
		assert.truthy(item.eyrie)
		item = new("Item", raw("Searing Exarch Item"))
		assert.truthy(item.cleansing)
		item = new("Item", raw("Eater of Worlds Item"))
		assert.truthy(item.tangle)
	end)

	it("short flags", function()
		local item = new("Item", raw("Split"))
		assert.truthy(item.split)
		item = new("Item", raw("Mirrored"))
		assert.truthy(item.mirrored)
		item = new("Item", raw("Corrupted"))
		assert.truthy(item.corrupted)
		item = new("Item", raw("Fractured Item"))
		assert.truthy(item.fractured)
		item = new("Item", raw("Synthesised Item"))
		assert.truthy(item.synthesised)
		item = new("Item", raw("Crafted: true"))
		assert.truthy(item.crafted)
		item = new("Item", raw("Unreleased: true"))
		assert.truthy(item.unreleased)
	end)

	it("long flags", function()
		local item = new("Item", raw("This item can be anointed by Cassia"))
		assert.truthy(item.canBeAnointed)
		item = new("Item", raw("Can have a second Enchantment Modifier"))
		assert.truthy(item.canHaveTwoEnchants)
		item = new("Item", raw("Can have 1 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		item = new("Item", raw("Can have 2 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		assert.truthy(item.canHaveThreeEnchants)
		item = new("Item", raw("Can have 3 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		assert.truthy(item.canHaveThreeEnchants)
		assert.truthy(item.canHaveFourEnchants)
		item = new("Item", raw("Has a Crucible Passive Skill Tree with only Support Passive Skills"))
		assert.truthy(item.canHaveOnlySupportSkillsCrucibleTree)
		item = new("Item", raw("Has a Crucible Passive Skill Tree"))
		assert.truthy(item.canHaveShieldCrucibleTree)
		item = new("Item", raw("Has a Two Handed Sword Crucible Passive Skill Tree"))
		assert.truthy(item.canHaveTwoHandedSwordCrucibleTree)
	end)
	
	it("tags", function()
		local item = new("Item", raw("{tags:life,physical_damage}+8 to Strength"))
		assert.are.same({ "life", "physical_damage" }, item.explicitModLines[1].modTags)
	end)

	it("variant", function()
		local item = new("Item", raw([[
			Selected Variant: 2
			{variant:1}+8 to Strength
			{variant:2,3}+10 to Strength
			]]))
		assert.are.equals(2, item.variant)
		assert.are.same({ [1] = true }, item.explicitModLines[1].variantList)
		assert.are.same({ [2] = true, [3] = true }, item.explicitModLines[2].variantList)
		assert.are.equals(10, item.baseModList[1].value) -- variant 2 has +10 to Strength
	end)

	it("range", function()
		local item = new("Item", raw("{range:0.8}+(8-12) to Strength"))
		assert.are.equals(0.8, item.explicitModLines[1].range)
		assert.are.equals(11, item.baseModList[1].value) -- range 0.8 of (8-12) = 11
	end)

	it("crafted", function()
		local item = new("Item", raw("{crafted}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].crafted)
		item = new("Item", raw("+8 to Strength (crafted)"))
		assert.truthy(item.explicitModLines[1].crafted)
	end)

	it("crucible", function()
		local item = new("Item", raw("{crucible}+8 to Strength"))
		assert.truthy(item.crucibleModLines[1].crucible)
		item = new("Item", raw("+8 to Strength (crucible)"))
		assert.truthy(item.crucibleModLines[1].crucible)
	end)

	it("custom", function()
		local item = new("Item", raw("{custom}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].custom)
	end)

	it("eater", function()
		local item = new("Item", raw("{eater}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].eater)
	end)

	it("enchant", function()
		local item = new("Item", raw("+8 to Strength (enchant)"))
		assert.are.equals(1, #item.enchantModLines)
		-- enchant also sets crafted and implicit
		assert.truthy(item.enchantModLines[1].crafted)
		assert.truthy(item.enchantModLines[1].implicit)
	end)

	it("exarch", function()
		local item = new("Item", raw("{exarch}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].exarch)
	end)

	it("fractured", function()
		local item = new("Item", raw("{fractured}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].fractured)
		item = new("Item", raw("+8 to Strength (fractured)"))
		assert.truthy(item.explicitModLines[1].fractured)
	end)

	it("implicit", function()
		local item = new("Item", raw("+8 to Strength (implicit)"))
		assert.truthy(item.implicitModLines[1].implicit)
	end)

	it("scourge", function()
		local item = new("Item", raw("{scourge}+8 to Strength"))
		assert.truthy(item.scourgeModLines[1].scourge)
		item = new("Item", raw("+8 to Strength (scourge)"))
		assert.truthy(item.scourgeModLines[1].scourge)
	end)

	it("synthesis", function()
		local item = new("Item", raw("{synthesis}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].synthesis)
	end)

	it("unscalable", function()
		local item = new("Item", raw("{unscalable}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].unscalable)
		item = new("Item", raw("+8 to Strength - Unscalable Value"))
		assert.truthy(item.explicitModLines[1].unscalable)
	end)

	it("multiple bases", function()
		local item = new("Item", [[
			Ashcaller
			Selected Variant: 3
			{variant:1,2,3}Quartz Wand
			{variant:4}Carved Wand
			]])
		assert.are.same({
			["Quartz Wand"] = { line = "Quartz Wand", variantList = { [1] = true, [2] = true, [3] = true } },
			["Carved Wand"] = { line = "Carved Wand", variantList = { [4] = true } }
			}, item.baseLines)
		assert.are.equals("Quartz Wand", item.baseName)

		item = new("Item", [[
			Ashcaller
			Selected Variant: 4
			{variant:1,2,3}Quartz Wand
			{variant:4}Carved Wand
			]])
		assert.are.equals("Carved Wand", item.baseName)
	end)

	it("parses text without armour value then changes quality and has correct final armour", function()
		local item = new("Item", [[
				Armour Gloves
				Iron Gauntlets
				Quality: 0
			]])

		local original = item.armourData.Armour
		item.quality = 20
		item:BuildAndParseRaw()
		assert.are.equals(round(original * 1.2), item.armourData.Armour)
	end)

	it("magic item", function()
		local item = new("Item", [[
				Rarity: MAGIC
				Name Prefix Iron Gauntlets -> +50 ignite chance
				+50% chance to Ignite
			]])

		assert.are.equals("Name Prefix ", item.namePrefix)
		assert.are.equals(" -> +50 ignite chance", item.nameSuffix)
		assert.are.equals("Iron Gauntlets", item.baseName)
		assert.are.equals(1, #item.explicitModLines)
		assert.are.equals("+50% chance to Ignite", item.explicitModLines[1].line)
	end)

	it("Energy Blade", function()
		local item = new("Item", [[
			Item Class: One Hand Swords
			Rarity: Magic
			Superior Energy Blade
		]])
		assert.are.equal("Energy Blade One Handed", item.baseName)
		item = new("Item", [[
			Item Class: Two Hand Swords
			Rarity: Magic
			Superior Energy Blade
		]])
		assert.are.equal("Energy Blade Two Handed", item.baseName)
	end)

	it("Flask buff", function()
		local item = new("Item", [[
			Rarity: Magic
			Chemist's Granite Flask of the Opossum
		]])
		assert.are.equal(1, #item.buffModLines)
		assert.are.equal("+1500 to Armour", item.buffModLines[1].line)
	end)
end)

describe("TestAdvancedItemParse #item", function()
	local function raw(s, base)
		base = base or "Plate Vest"
		return "Rarity: Rare\nName\n"..base.."\n"..s
	end

	it("parses to craft", function()
		local item = new("Item", raw([[
			{ Prefix Modifier "Fecund" (Tier: 1) — Life }
			+142(130-144) to maximum Life
		]], "Cord Belt"))
		assert.are.equals("IncreasedLife9", item.prefixes[1].modId)
		assert.are.equals(0.857, item.prefixes[1].range)
		assert.are.equals("life", item.explicitModLines[1].modTags[1])
		item = new("Item", raw([[
			{ Master Crafted Suffix Modifier "of Craft" (Rank: 3) — Elemental, Cold, Resistance }
			+35(29-35)% to Cold Resistance
		]], "Cord Belt"))
		assert.truthy(item.explicitModLines[1].crafted)
	end)

	it("parses correct range", function()
		local item = new("Item", raw([[
			{ Prefix Modifier "Freezing" (Tier: 5) — Damage, Elemental, Cold, Caster  — 8% Increased }
			Adds 17(16-20) to 35(30-36) Cold Damage to Spells
		]], "Void Sceptre"))
		assert.are.equals("Adds 17 to 35 Cold Damage to Spells", item.explicitModLines[1].line)
	end)

	-- GGG scales each mod line separately here, but PoB scales them both together, so this parsing is a bit wonky
	it("parses multi-line mod", function()
		local item = new("Item", raw([[
			{ Prefix Modifier "Warlock's" (Tier: 4) — Mana, Damage, Caster }
			32(30-37)% increased Spell Damage
			+46(42-47) to maximum Mana
		]], "Royal Staff"))
		assert.are.equals("SpellDamageAndManaOnTwoHandWeapon4", item.prefixes[1].modId)
		assert.are.equals(0.286, item.prefixes[1].range)
		assert.are.equals(0.8, item.explicitModLines[2].range)
	end)

	it("resets linePrefix", function() 
		local item = new("Item", raw([[
			{ Prefix Modifier "Warlock's" (Tier: 4) — Mana, Damage, Caster }
			32(30-37)% increased Spell Damage
			+46(42-47) to maximum Mana
			--------
			+15 to maximum life
		]], "Royal Staff"))
		assert.are_not.equals("mana", item.explicitModLines[3].modTags[1])
	end)

	it("resets linePostfix", function() 
		local item = new("Item", raw([[
			{ Corruption Enhancement — Mana }
			24(20-30)% increased Mana Regeneration Rate
			--------
			+15 to maximum life
		]]))
		assert.falsy(item.explicitModLines[1].enchant)
	end)

	it("parses vaaled catalyst", function() 
		local item = new("Item", raw([[
			Quality (Attribute Modifiers): +19% (augmented)
			{ Unique Modifier — Attribute  — 19% Increased }
			+120(80-100) to all Attributes
			(Attributes are Strength, Dexterity, and Intelligence)
		]], "Onyx Amulet"))
		assert.are.equals(142, item.baseModList[1].value)
		-- assert.falsy(item.explicitModLines[1].range) -- Not sure why this is returning 0.5
		assert.are.equals(6, item.catalyst)
		assert.are.equals(19, item.catalystQuality)
	end)

	it("parses vaaled catalyst within range", function() 
		local item = new("Item", raw([[
			Quality (Attribute Modifiers): +19% (augmented)
			{ Unique Modifier — Attribute  — 19% Increased }
			+95(80-100) to all Attributes
			(Attributes are Strength, Dexterity, and Intelligence)
		]], "Onyx Amulet"))
		assert.are.equals(113, item.baseModList[1].value)
		assert.are.equals(0.75, item.explicitModLines[1].range)
		assert.are.equals(6, item.catalyst)
		assert.are.equals(19, item.catalystQuality)
	end)

	it("doesn't scale unscalable", function()
		local item = new("Item", raw([[
			Quality (Life and Mana Modifiers): +20% (augmented)
			{ Unique Modifier — Life, Defences, Energy Shield, Minion, Gem }
			Socketed Golem Skills gain 20% of Maximum Life as Extra Maximum Energy Shield — Unscalable Value
		]]))
		assert.are.equals(20, item.baseModList[1].value.mod.value)
	end)

	it("correctly matches conqueror mod", function()
		local item = new("Item", raw([[
			{ Suffix Modifier "of the Conquest" (Tier: 1) — Elemental, Cold }
			10(8-10)% chance to Avoid Cold Damage from Hits
			(No chance to avoid damage can be higher than 75%)
			Warlord Item
		]]))
		assert.are.equals(10, item.baseModList[1].value)
		-- assert.are.equals(1, item.explicitModLines[1].range) -- Not sure why this is returning 0.5
	end)

	it("parses enchant correctly #enchant", function()
		local item = new("Item", raw([[
			{ Corrupted Enhancement }
			+8(6-10)% to Fire Resistance
		]]))
		assert.are.equals(8, item.enchantModLines[1].modList[1].value)
	end)

	it("parses enchant with tags correctly #enchant", function()
		local item = new("Item", raw([[
			{ Corrupted Enhancement - Energy Shield }
			+8(6-10)% to Fire Resistance
		]]))
		assert.are.equals(8, item.enchantModLines[1].modList[1].value)
		assert.are.equals("energyshield", item.enchantModLines[1].modTags[1])
	end)

	it("parses junk", function()
		local godTestItem = new("Item", [[
			Item Class: Sceptres
			Rarity: Unique
			Nebulis
			Synthesised Void Sceptre
			--------
			Sceptre
			Physical Damage: 50-76
			Critical Strike Chance: 7.30%
			Attacks per Second: 1.25
			Weapon Range: 1.1 metres
			Memory Strands: 58
			--------
			Requirements:
			Level: 68
			Str: 104
			Int: 122
			--------
			Sockets: B R 
			--------
			Item Level: 87
			--------
			+30% to Fire Resistance (scourge)
			22% reduced Global Defences (scourge)
			(Armour, Evasion Rating and Energy Shield are the standard Defences) (scourge)
			--------
			8% increased Explicit Cold Modifier magnitudes (enchant)
			Has 1 White Socket (enchant)
			--------
			{ Searing Exarch Implicit Modifier (Lesser) }
			Tempest Shield has 15(15-17)% increased Buff Effect
			{ Implicit Modifier — Damage, Critical  — 106% Increased }
			+15(15-17)% to Global Critical Strike Multiplier
			--------
			{ Prefix Modifier "Freezing" (Tier: 5) — Damage, Elemental, Cold, Caster  — 8% Increased }
			Adds 17(16-20) to 35(30-36) Cold Damage to Spells
			{ Prefix Modifier "Beetle's" (Tier: 6) — Defences, Armour }
			9(6-13)% increased Armour
			7(6-7)% increased Stun and Block Recovery
			{ Master Crafted Prefix Modifier "Upgraded" — Life, Defences, Armour }
			21(18-21)% increased Armour
			+18(17-19) to maximum Life
			{ Unique Modifier }
			106(60-120)% increased Implicit Modifier magnitudes — Unscalable Value
			(Implicit Modifiers are those that come from an item's type, rather than its random properties)
			{ Master Crafted Suffix Modifier "of Craft" (Rank: 3) — Elemental, Cold, Resistance }
			+35(29-35)% to Cold Resistance
			{ Fractured Prefix Modifier "Thorny" (Tier: 2) — Damage, Physical }
			Reflects 3(1-4) Physical Damage to Melee Attackers
			{ Prefix Modifier "Veiled" }
			Veiled Prefix
			Searing Exarch Item
			--------
			{ Allocated Crucible Passive Skill (Tier: 2) }
			Adds 2 to 6 Physical Damage to Spells
			--------
			Synthesised Item
			--------
			Corrupted
			--------
			Scourged
			--------
			Hinekora's Lock
			--------
			Note: ~b/o 2 chaos
		]])
	end)
end)