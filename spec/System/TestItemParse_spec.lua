describe("TestItemParse", function()
	local function raw(s, base)
		base = base or "Plate Vest"
		return "Rarity: Rare\nName\n"..base.."\n"..s
	end

	it("Rarity", function()
		local item = new("Item"):Item("Rarity: Normal\nCoral Ring")
		assert.are.equals("NORMAL", item.rarity)
		item = new("Item"):Item("Rarity: Magic\nCoral Ring")
		assert.are.equals("MAGIC", item.rarity)
		item = new("Item"):Item("Rarity: Rare\nName\nCoral Ring")
		assert.are.equals("RARE", item.rarity)
		item = new("Item"):Item("Rarity: Unique\nName\nCoral Ring")
		assert.are.equals("UNIQUE", item.rarity)
		item = new("Item"):Item("Rarity: Unique\nName\nCoral Ring\nFoil Unique (Verdant)")
		assert.are.equals("RELIC", item.rarity)
	end)

	it("Superior/Synthesised", function()
		local item = new("Item"):Item(raw("", "Superior Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
		item = new("Item"):Item(raw("", "Synthesised Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
		item = new("Item"):Item(raw("", "Superior Synthesised Plate Vest"))
		assert.are.equals("Plate Vest", item.baseName)
	end)

	it("adds talisman base mods as enchants", function()
		local baseName = "Test Talisman"
		data.itemBases[baseName] = {
			type = "Amulet",
			subType = "Talisman",
			tags = { amulet = true, talisman = true },
			req = { },
			enchant = "+10 to Strength",
			enchantModTypes = { { "attribute" } },
			cannotBeAnointed = true,
		}

		local item = new("Item"):Item("Rarity: Normal\n" .. baseName)

		assert.are.equals(1, #item.enchantModLines)
		assert.are.equals("+10 to Strength", item.enchantModLines[1].line)
		assert.truthy(item.enchantModLines[1].crafted)
		assert.truthy(item.enchantModLines[1].implicit)
		assert.are.same({ "attribute" }, item.enchantModLines[1].modTags)
		assert.truthy(item.base.cannotBeAnointed)

		item:BuildAndParseRaw()
		assert.are.equals(1, #item.enchantModLines)
		assert.truthy(item.enchantModLines[1].crafted)
		assert.truthy(item.enchantModLines[1].implicit)
		data.itemBases[baseName] = nil
	end)

	it("Two-Toned Boots", function()
		local item = new("Item"):Item(raw("", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		item = new("Item"):Item(raw("Armour: 10\nEnergy Shield: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		item = new("Item"):Item(raw("Armour: 10\nEvasion Rating: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Armour/Evasion)", item.baseName)
		item = new("Item"):Item(raw("Evasion Rating: 10\nEnergy Shield: 10", "Two-Toned Boots"))
		assert.are.equals("Two-Toned Boots (Evasion/Energy Shield)", item.baseName)
	end)

	it("Magic Two-Toned Boots", function()
		local item = new("Item"):Item([[
			Rarity: Magic
			Stalwart Two-Toned Boots of Plunder
			Armour: 100
			Energy Shield: 100
			]])
		assert.are.equal("Two-Toned Boots (Armour/Energy Shield)", item.baseName)
		assert.are.equal("Stalwart ", item.namePrefix)
		assert.are.equal(" of Plunder", item.nameSuffix)
		item = new("Item"):Item([[
			Rarity: Magic
			Sanguine Two-Toned Boots of the Phoenix
			Armour: 100
			Evasion Rating: 100
			]])
		assert.are.equal("Two-Toned Boots (Armour/Evasion)", item.baseName)
		assert.are.equal("Sanguine ", item.namePrefix)
		assert.are.equal(" of the Phoenix", item.nameSuffix)
		item = new("Item"):Item([[
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
		local item = new("Item"):Item([[
			Rarity: Rare
			Phoenix Paw
			Iron Gauntlets
		]])
		assert.are.equal("Phoenix Paw", item.title)
		assert.are.equal("Iron Gauntlets", item.baseName)
		assert.are.equal("Phoenix Paw, Iron Gauntlets", item.name)
	end)

	it("Unique ID", function()
		local item = new("Item"):Item(raw("Unique ID: 40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863"))
		assert.are.equals("40f9711d5bd7ad2bcbddaf71c705607aef0eecd3dcadaafec6c0192f79b82863", item.uniqueID)
	end)

	it("Item Level", function()
		local item = new("Item"):Item(raw("Item Level: 10"))
		assert.are.equals(10, item.itemLevel)
	end)

	it("Quality", function()
		local item = new("Item"):Item(raw("Quality: 10"))
		assert.are.equals(10, item.quality)
		item = new("Item"):Item(raw("Quality: +12% (augmented)"))
		assert.are.equals(12, item.quality)
	end)

	it("Sockets", function()
		local item = new("Item"):Item(raw("Sockets: R-G R-B-W A"))
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
		local item = new("Item"):Item(raw("Radius: Large\nLimited to: 2", "Cobalt Jewel"))
		assert.are.equals("Large", item.jewelRadiusLabel)
		assert.are.equals(2, item.limit)
	end)

	it("Variant name", function()
		local item = new("Item"):Item(raw("Variant: Pre 3.19.0\nVariant: Current"))
		assert.are.same({ "Pre 3.19.0", "Current" }, item.variantList)
	end)

	it("Versioned grouped variants", function()
		local item = new("Item"):Item([[
			Rarity: UNIQUE
			Versioned Grouped Test
			Prismatic Ring
			Version: Pre 3.28.0
			Version: Current
			Variant: Life
			Variant: Energy Shield
			Variant: Mana
			Variant: Reflect Immune
			Variant: No damage from Crits
			Variant: No Monster Suppress
			Variant: No Enemy Pen
			Variant: Charges cannot be stolen
			Variant: Burning Ground Immune
			Variant: Shocked Ground Immune
			Variant: Desecrated Ground Immune
			Variant: Chilled Ground Immune
			Implicits: 0
			{version:2}{variant:2}{group:1}20% increased maximum Energy Shield
			{version:1}{variant:1}{group:1}10% increased maximum Life
			{variant:3}{group:1}20% increased maximum Mana
			{variant:4}{group:2}Damage cannot be Reflected
			{variant:5}{group:2}You take 100% reduced Extra Damage from Critical Strikes
			{variant:6}{group:2}Monsters cannot Suppress your Spells
			{variant:7}{group:2}Elemental Resistances cannot be Penetrated
			{variant:8}{group:2}Monsters cannot steal your Power, Frenzy or Endurance charges on Hit
			{variant:9}{group:3}Unaffected by Burning Ground
			{variant:10}{group:3}Unaffected by Shocked Ground
			{variant:11}{group:3}Unaffected by Desecrated Ground
			{variant:12}{group:3}Unaffected by Chilled Ground
		]])
		assert.are.same({ "Pre 3.28.0", "Current" }, item.versionList)
		assert.are.equals(2, item.selectedVersion)
		assert.are.equals(2, item.variantGroupSelections[1])
		assert.are.equals(4, item.variantGroupSelections[2])
		assert.are.equals(9, item.variantGroupSelections[3])
		assert.are.same({ 2, 3 }, item:GetVariantGroupOptions(1, false))

		item.variantGroupSelections[1] = 3
		item.selectedVersion = 1
		item:NormaliseVariantSelections()
		assert.are.equals(3, item.variantGroupSelections[1])
		assert.are.same({ 1, 3 }, item:GetVariantGroupOptions(1, false))

		item.variantGroupSelections[1] = 2
		item:NormaliseVariantSelections()
		assert.are.equals(1, item.variantGroupSelections[1])
		item:BuildAndParseRaw()
		assert.matches("Selected Version: 1", item.raw, 1, true)
		assert.matches("Selected Variant Group: 1=1", item.raw, 1, true)
		assert.matches("{version:1}{variant:1}{group:1}", item.raw, 1, true)
	end)

	it("Talisman Tier", function()
		local item = new("Item"):Item(raw("Talisman Tier: 3", "Rotfeather Talisman"))
		assert.are.equals(3, item.talismanTier)
	end)

	it("Defence", function()
		local item = new("Item"):Item(raw("Armour: 25"))
		assert.are.equals(25, item.armourData.Armour)
		item = new("Item"):Item(raw("Armour: 25 (augmented)"))
		assert.are.equals(25, item.armourData.Armour)
		item = new("Item"):Item(raw("Evasion Rating: 35", "Shabby Jerkin"))
		assert.are.equals(35, item.armourData.Evasion)
		item = new("Item"):Item(raw("Energy Shield: 15", "Simple Robe"))
		assert.are.equals(15, item.armourData.EnergyShield)
		item = new("Item"):Item(raw("Ward: 180", "Runic Crown"))
		assert.are.equals(180, item.armourData.Ward)
	end)

	it("Defence BasePercentile", function()
		local item = new("Item"):Item(raw("ArmourBasePercentile: 0.5"))
		assert.are.equals(0.5, item.armourData.ArmourBasePercentile)
		item = new("Item"):Item(raw("EvasionBasePercentile: 0.6", "Shabby Jerkin"))
		assert.are.equals(0.6, item.armourData.EvasionBasePercentile)
		item = new("Item"):Item(raw("EnergyShieldBasePercentile: 0.7", "Simple Robe"))
		assert.are.equals(0.7, item.armourData.EnergyShieldBasePercentile)
		item = new("Item"):Item(raw("WardBasePercentile: 0.8", "Runic Crown"))
		assert.are.equals(0.8, item.armourData.WardBasePercentile)
	end)

	it("Requires Level", function()
		local item = new("Item"):Item(raw("Requires Level 10"))
		assert.are.equals(10, item.requirements.level)
		item = new("Item"):Item(raw("Level: 10"))
		assert.are.equals(10, item.requirements.level)
		item = new("Item"):Item(raw("LevelReq: 10"))
		assert.are.equals(10, item.requirements.level)
	end)

	it("Alt Variant", function()
		local item = new("Item"):Item(raw([[
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
		local item = new("Item"):Item(raw([[
			Prefix: {range:0.1}IncreasedLife1
			Suffix: {range:0.2}ColdResist1
			]]))
		assert.are.equals("IncreasedLife1", item.prefixes[1].modId)
		assert.are.equals(0.1, item.prefixes[1].range)
		assert.are.equals("ColdResist1", item.suffixes[1].modId)
		assert.are.equals(0.2, item.suffixes[1].range)
	end)

	it("Implicits", function()
		local item = new("Item"):Item(raw([[
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
		local item = new("Item"):Item(raw("League: Heist"))
		assert.are.equals("Heist", item.league)
	end)

	it("Source", function()
		local item = new("Item"):Item(raw("Source: No longer obtainable"))
		assert.are.equals("No longer obtainable", item.source)
	end)

	it("Note", function()
		local item = new("Item"):Item(raw("Note: ~price 1 chaos"))
		assert.are.equals("~price 1 chaos", item.note)
	end)

	it("Attribute Requirements", function()
		local item = new("Item"):Item(raw("Dex: 100"))
		assert.are.equals(100, item.requirements.dex)
		item = new("Item"):Item(raw("Int: 101"))
		assert.are.equals(101, item.requirements.int)
		item = new("Item"):Item(raw("Str: 102"))
		assert.are.equals(102, item.requirements.str)
	end)

	it("Requires Class", function()
		local item = new("Item"):Item(raw("Requires Class Witch"))
		assert.are.equals("Witch", item.classRestriction)
		item = new("Item"):Item(raw("Class:: Witch"))
		assert.are.equals("Witch", item.classRestriction)
	end)

	it("Requires Class variant", function()
		local item = new("Item"):Item(raw([[
			Selected Variant: 2
			+8 to Strength
			{variant:1}Requires Class Witch
			{variant:2}Requires Class Templar
			]]))
		assert.are.equals(2, item.variant)
		assert.are.equals("Templar", item.classRestriction)
	end)

	it("Influence", function()
		local item = new("Item"):Item(raw("Shaper Item"))
		assert.truthy(item.shaper)
		item = new("Item"):Item(raw("Elder Item"))
		assert.truthy(item.elder)
		item = new("Item"):Item(raw("Warlord Item"))
		assert.truthy(item.adjudicator)
		item = new("Item"):Item(raw("Hunter Item"))
		assert.truthy(item.basilisk)
		item = new("Item"):Item(raw("Crusader Item"))
		assert.truthy(item.crusader)
		item = new("Item"):Item(raw("Redeemer Item"))
		assert.truthy(item.eyrie)
		item = new("Item"):Item(raw("Searing Exarch Item"))
		assert.truthy(item.cleansing)
		item = new("Item"):Item(raw("Eater of Worlds Item"))
		assert.truthy(item.tangle)
	end)

	it("short flags", function()
		local item = new("Item"):Item(raw("Split"))
		assert.truthy(item.split)
		item = new("Item"):Item(raw("Mirrored"))
		assert.truthy(item.mirrored)
		item = new("Item"):Item(raw("Corrupted"))
		assert.truthy(item.corrupted)
		item = new("Item"):Item(raw("Fractured Item"))
		assert.truthy(item.fractured)
		item = new("Item"):Item(raw("Synthesised Item"))
		assert.truthy(item.synthesised)
		item = new("Item"):Item(raw("Crafted: true"))
		assert.truthy(item.crafted)
		item = new("Item"):Item(raw("Unreleased: true"))
		assert.truthy(item.unreleased)
	end)

	it("long flags", function()
		local item = new("Item"):Item(raw("This item can be anointed by Cassia"))
		assert.truthy(item.canBeAnointed)
		item = new("Item"):Item(raw("Can have a second Enchantment Modifier"))
		assert.truthy(item.canHaveTwoEnchants)
		item = new("Item"):Item(raw("Can have 1 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		item = new("Item"):Item(raw("Can have 2 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		assert.truthy(item.canHaveThreeEnchants)
		item = new("Item"):Item(raw("Can have 3 additional Enchantment Modifiers"))
		assert.truthy(item.canHaveTwoEnchants)
		assert.truthy(item.canHaveThreeEnchants)
		assert.truthy(item.canHaveFourEnchants)
		item = new("Item"):Item(raw("Has a Crucible Passive Skill Tree with only Support Passive Skills"))
		assert.truthy(item.canHaveOnlySupportSkillsCrucibleTree)
		item = new("Item"):Item(raw("Has a Crucible Passive Skill Tree"))
		assert.truthy(item.canHaveShieldCrucibleTree)
		item = new("Item"):Item(raw("Has a Two Handed Sword Crucible Passive Skill Tree"))
		assert.truthy(item.canHaveTwoHandedSwordCrucibleTree)
	end)
	
	it("tags", function()
		local item = new("Item"):Item(raw("{tags:life,physical_damage}+8 to Strength"))
		assert.are.same({ "life", "physical_damage" }, item.explicitModLines[1].modTags)
	end)

	it("ignores disabled modifiers in item conditions", function()
		local item = new("Item"):Item(raw("{disabled}+100 to maximum Life"))
		assert.is_false(item:FindModifierSubstring("life", "body armour"))
	end)

	it("variant", function()
		local item = new("Item"):Item(raw([[
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
		local item = new("Item"):Item(raw("{range:0.8}+(8-12) to Strength"))
		assert.are.equals(0.8, item.explicitModLines[1].range)
		assert.are.equals(11, item.baseModList[1].value) -- range 0.8 of (8-12) = 11
	end)

	it("crafted", function()
		local item = new("Item"):Item(raw("{crafted}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].crafted)
		item = new("Item"):Item(raw("+8 to Strength (crafted)"))
		assert.truthy(item.explicitModLines[1].crafted)
	end)

	it("crucible", function()
		local item = new("Item"):Item(raw("{crucible}+8 to Strength"))
		assert.truthy(item.crucibleModLines[1].crucible)
		item = new("Item"):Item(raw("+8 to Strength (crucible)"))
		assert.truthy(item.crucibleModLines[1].crucible)
	end)

	it("custom", function()
		local item = new("Item"):Item(raw("{custom}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].custom)
	end)

	it("eater", function()
		local item = new("Item"):Item(raw("{eater}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].eater)
	end)

	it("enchant", function()
		local item = new("Item"):Item(raw("+8 to Strength (enchant)"))
		assert.are.equals(1, #item.enchantModLines)
		-- enchant also sets crafted and implicit
		assert.truthy(item.enchantModLines[1].crafted)
		assert.truthy(item.enchantModLines[1].implicit)
	end)

	it("exarch", function()
		local item = new("Item"):Item(raw("{exarch}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].exarch)
	end)

	it("fractured", function()
		local item = new("Item"):Item(raw("{fractured}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].fractured)
		item = new("Item"):Item(raw("+8 to Strength (fractured)"))
		assert.truthy(item.explicitModLines[1].fractured)
	end)

	it("implicit", function()
		local item = new("Item"):Item(raw("+8 to Strength (implicit)"))
		assert.truthy(item.implicitModLines[1].implicit)
	end)

	it("scourge", function()
		local item = new("Item"):Item(raw("{scourge}+8 to Strength"))
		assert.truthy(item.scourgeModLines[1].scourge)
		item = new("Item"):Item(raw("+8 to Strength (scourge)"))
		assert.truthy(item.scourgeModLines[1].scourge)
	end)

	it("synthesis", function()
		local item = new("Item"):Item(raw("{synthesis}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].synthesis)
	end)

	it("unscalable", function()
		local item = new("Item"):Item(raw("{unscalable}+8 to Strength"))
		assert.truthy(item.explicitModLines[1].unscalable)
		item = new("Item"):Item(raw("+8 to Strength - Unscalable Value"))
		assert.truthy(item.explicitModLines[1].unscalable)
	end)

	it("multiple bases", function()
		local item = new("Item"):Item([[
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

		item = new("Item"):Item([[
			Ashcaller
			Selected Variant: 4
			{variant:1,2,3}Quartz Wand
			{variant:4}Carved Wand
			]])
		assert.are.equals("Carved Wand", item.baseName)
	end)

	it("parses text without armour value then changes quality and has correct final armour", function()
		local item = new("Item"):Item([[
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
		local item = new("Item"):Item([[
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
		local item = new("Item"):Item([[
			Item Class: One Hand Swords
			Rarity: Magic
			Superior Energy Blade
		]])
		assert.are.equal("Energy Blade One Handed", item.baseName)
		item = new("Item"):Item([[
			Item Class: Two Hand Swords
			Rarity: Magic
			Superior Energy Blade
		]])
		assert.are.equal("Energy Blade Two Handed", item.baseName)
	end)

	it("Flask buff", function()
		local item = new("Item"):Item([[
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
	local function lines(modLines)
		local out = { }
		for index, modLine in ipairs(modLines) do
			out[index] = modLine.line
		end
		return out
	end

	it("parses to craft", function()
		local item = new("Item"):Item(raw([[
			{ Prefix Modifier "Fecund" (Tier: 1) — Life }
			+142(130-144) to maximum Life
		]], "Cord Belt"))
		assert.are.equals("IncreasedLife9", item.prefixes[1].modId)
		assert.are.equals(0.857, item.prefixes[1].range)
		assert.are.equals("life", item.explicitModLines[1].modTags[1])
		item = new("Item"):Item(raw([[
			{ Master Crafted Suffix Modifier "of Craft" (Rank: 3) — Elemental, Cold, Resistance }
			+35(29-35)% to Cold Resistance
		]], "Cord Belt"))
		assert.truthy(item.explicitModLines[1].crafted)
	end)

	it("parses correct range", function()
		local item = new("Item"):Item(raw([[
			{ Prefix Modifier "Freezing" (Tier: 5) — Damage, Elemental, Cold, Caster  — 8% Increased }
			Adds 17(16-20) to 35(30-36) Cold Damage to Spells
		]], "Void Sceptre"))
		assert.are.equals("Adds 17 to 35 Cold Damage to Spells", item.explicitModLines[1].line)
	end)

	-- GGG scales each mod line separately here, but PoB scales them both together, so this parsing is a bit wonky
	it("parses multi-line mod", function()
		local item = new("Item"):Item(raw([[
			{ Prefix Modifier "Warlock's" (Tier: 4) — Mana, Damage, Caster }
			32(30-37)% increased Spell Damage
			+46(42-47) to maximum Mana
		]], "Royal Staff"))
		assert.are.equals("SpellDamageAndManaOnTwoHandWeapon4", item.prefixes[1].modId)
		assert.are.equals(0.286, item.prefixes[1].range)
		assert.are.equals(0.8, item.explicitModLines[2].range)
	end)

	it("resets linePrefix", function() 
		local item = new("Item"):Item(raw([[
			{ Prefix Modifier "Warlock's" (Tier: 4) — Mana, Damage, Caster }
			32(30-37)% increased Spell Damage
			+46(42-47) to maximum Mana
			--------
			+15 to maximum life
		]], "Royal Staff"))
		assert.are_not.equals("mana", item.explicitModLines[3].modTags[1])
	end)

	it("resets linePostfix", function() 
		local item = new("Item"):Item(raw([[
			{ Corruption Enhancement — Mana }
			24(20-30)% increased Mana Regeneration Rate
			--------
			+15 to maximum life
		]]))
		assert.falsy(item.explicitModLines[1].enchant)
	end)

	it("parses vaaled catalyst", function() 
		local item = new("Item"):Item(raw([[
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
		local item = new("Item"):Item(raw([[
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
		local item = new("Item"):Item(raw([[
			Quality (Life and Mana Modifiers): +20% (augmented)
			{ Unique Modifier — Life, Defences, Energy Shield, Minion, Gem }
			Socketed Golem Skills gain 20% of Maximum Life as Extra Maximum Energy Shield — Unscalable Value
		]]))
		assert.are.equals(20, item.baseModList[1].value.mod.value)
	end)

	it("correctly matches conqueror mod", function()
		local item = new("Item"):Item(raw([[
			{ Suffix Modifier "of the Conquest" (Tier: 1) — Elemental, Cold }
			10(8-10)% chance to Avoid Cold Damage from Hits
			(No chance to avoid damage can be higher than 75%)
			Warlord Item
		]]))
		assert.are.equals(10, item.baseModList[1].value)
		-- assert.are.equals(1, item.explicitModLines[1].range) -- Not sure why this is returning 0.5
	end)

	it("parses enchant correctly #enchant", function()
		local item = new("Item"):Item(raw([[
			{ Corrupted Enhancement }
			+8(6-10)% to Fire Resistance
		]]))
		assert.are.equals(8, item.enchantModLines[1].modList[1].value)
	end)

	it("parses enchant with tags correctly #enchant", function()
		local item = new("Item"):Item(raw([[
			{ Corrupted Enhancement - Energy Shield }
			+8(6-10)% to Fire Resistance
		]]))
		assert.are.equals(8, item.enchantModLines[1].modList[1].value)
		assert.are.equals("energyshield", item.enchantModLines[1].modTags[1])
	end)

	it("parses junk", function()
		local godTestItem = new("Item"):Item([[
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

	it("parses allocated Crucible passive skills from advanced copy", function()
		local item = new("Item"):Item(raw([[
			{ Allocated Crucible Passive Skill (Tier: 1) }
			-3% to Critical Strike Chance
			+100% to Global Critical Strike Multiplier
			{ Allocated Crucible Passive Skill (Tier: 1) }
			Rampage
			(You gain Rampage bonuses for Killing multiple Enemies in quick succession)
		]], "Citadel Bow"))

		assert.are.equals(3, #item.crucibleModLines)
		assert.are.equals(0, #item.explicitModLines)
		assert.are.same({
			"-3% to Critical Strike Chance",
			"+100% to Global Critical Strike Multiplier",
			"Rampage",
		}, lines(item.crucibleModLines))
	end)

	it("ignores attribute requirements from socketed gems", function()
		local item = new("Item"):Item(raw([[
			Requirements:
			Str: 126 (unmet)
			Dex: 185 (unmet)
			Int: 129 (unmet)
			--------
			Sockets: W-W-W-W-W-W
			--------
			Item Level: 83
		]], "Citadel Bow"))

		assert.are.same({ str = 0, dex = 185, int = 0 }, {
			str = item.requirements.strMod,
			dex = item.requirements.dexMod,
			int = item.requirements.intMod,
		})
	end)

	it("orders fractured mods first and crafted mods last", function()
		local item = new("Item"):Item(raw([[
			Item Level: 83
			{ Fractured Prefix Modifier "Cheetah's" (Tier: 2) — Speed }
			30% increased Movement Speed
			{ Prefix Modifier "Athlete's" (Tier: 1) — Life }
			+128(115-129) to maximum Life
			{ Master Crafted Prefix Modifier "Upgraded" (Rank: 2) — Mana }
			+43(35-44) to maximum Mana
			{ Suffix Modifier "of the Jaguar" (Tier: 3) — Attribute }
			+41(38-42) to Dexterity
		]], "Dragonscale Boots"))
		local expectedLines = {
			"30% increased Movement Speed",
			"+41 to Dexterity",
			"+128 to maximum Life",
			"+(35-44) to maximum Mana",
		}
		assert.are.same(expectedLines, lines(item.explicitModLines))

		item:Craft()
		item:Craft()
		assert.are.same(expectedLines, lines(item.explicitModLines))
	end)

	it("matches same-name affixes using their advanced-copy ranges", function()
		local item = new("Item"):Item(raw([[
			Item Level: 85
			{ Fractured Prefix Modifier "Essences" — Damage, Elemental, Fire, Attack }
			Adds 100(80-109) to 179(162-189) Fire Damage
			{ Prefix Modifier "Essences" — Damage, Elemental, Lightning, Attack }
			Adds 14(13-19) to 285(266-310) Lightning Damage
		]], "Kinetic Wand"))

		assert.are.equals("LocalAddedFireDamageEssence7", item.prefixes[1].modId)
		assert.are.equals("LocalAddedLightningDamageEssence7_", item.prefixes[2].modId)

		item:Craft()
		item:Craft()
		assert.are.equals("Adds 100 to 179 Fire Damage", item.explicitModLines[1].line)
		assert.are.equals("Adds 14 to 285 Lightning Damage", item.explicitModLines[2].line)
	end)

	it("filters flask base properties and parses fixed-value advanced rolls", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Soul Catcher
			Quartz Flask
			--------
			Lasts 7.20 (augmented) Seconds
			Consumes 30 of 60 Charges on use
			Currently has 59 Charges
			+10% chance to Suppress Spell Damage
			(40% of Damage from Suppressed Hits and Ailments they inflict is prevented)
			Phasing
			--------
			{ Unique Modifier }
			Consumes Maximum Charges to use
			{ Unique Modifier }
			Vaal Skills used during effect have 40(10)% reduced Soul Gain Prevention Duration
		]])

		assert.are.equals(2, #item.buffModLines)
		assert.are.equals(0, #item.implicitModLines)
		assert.are.equals(2, #item.explicitModLines)
		assert.are.equals("Consumes Maximum Charges to use", item.explicitModLines[1].line)
		assert.are.equals("Vaal Skills used during effect have 40% reduced Soul Gain Prevention Duration", item.explicitModLines[2].line)
	end)

	it("preserves rolls from large advanced-copy ranges", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Elegant Hubris
			Timeless Jewel
			{ Unique Modifier }
			Commissioned 150720(2000-160000) coins to commemorate Chitus(Cadiro-Victario)
		]])

		local seedLine = itemLib.applyRange(item.explicitModLines[1].line, item.explicitModLines[1].range)
		assert.are.equals("Commissioned 150720 coins to commemorate Chitus", seedLine)

		item:BuildAndParseRaw()
		seedLine = itemLib.applyRange(item.explicitModLines[1].line, item.explicitModLines[1].range)
		assert.are.equals("Commissioned 150720 coins to commemorate Chitus", seedLine)
	end)

	it("preserves independently rolled values on the same modifier line", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Prismweave
			Rustic Sash
			{ Unique Modifier — Damage, Elemental, Fire, Attack }
			Adds 16(14-16) to 32(30-32) Fire Damage to Attacks
			{ Unique Modifier — Damage, Elemental, Cold, Attack }
			Adds 10(10-12) to 27(24-28) Cold Damage to Attacks
		]])

		assert.are.equals("Adds (14-16) to (30-32) Fire Damage to Attacks", item.explicitModLines[1].line)
		assert.are.equals("Adds 10 to 27 Cold Damage to Attacks", item.explicitModLines[2].line)
	end)

	it("orders advanced-copy unique modifiers by their database stat order", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Geofri's Sanctuary
			Elegant Ringmail
			{ Unique Modifier — Life }
			+66(60-70) to maximum Life
			{ Unique Modifier — Defences, Energy Shield }
			+31(30-40) to maximum Energy Shield
			{ Unique Modifier — Defences, Armour, Energy Shield }
			63(50-75)% increased Armour and Energy Shield
			{ Unique Modifier — Life, Defences, Energy Shield }
			Zealot's Oath
			{ Unique Modifier — Defences, Energy Shield }
			+2 maximum Energy Shield per 5 Strength
			{ Unique Modifier — Elemental, Resistance }
			+18(14-18)% to all Elemental Resistances
		]])

		assert.are.same({
			"(50-75)% increased Armour and Energy Shield",
			"+(30-40) to maximum Energy Shield",
			"+(60-70) to maximum Life",
			"+(14-18)% to all Elemental Resistances",
			"+2 maximum Energy Shield per 5 Strength",
			"Zealot's Oath",
		}, lines(item.explicitModLines))
	end)

	it("keeps the selected value from advanced-copy enum ranges", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			The Dark Monarch
			Lich's Circlet
			{ Unique Modifier }
			Maximum number of Raised Zombies (Animated Weapons-Holy Armaments) is Doubled
			Cannot have Minions other than Raised Zombies (Animated Weapons-Holy Armaments)
		]])

		assert.are.equals("Maximum number of Raised Zombies is Doubled", item.explicitModLines[1].line)
		assert.are.equals("Cannot have Minions other than Raised Zombies", item.explicitModLines[2].line)
		assert.is_true(#item.explicitModLines[1].modList > 0)
	end)

	it("parses punctuated enum and descending numeric ranges", function()
		local gemItem = new("Item"):Item([[
			Rarity: Unique
			Replica Dragonfang's Flight
			Onyx Amulet
			{ Unique Modifier }
			+3 to Level of all Lightning Tendrils(Fireball-Mana-Infused Staff) Gems
		]])
		assert.are.equals("+3 to Level of all Lightning Tendrils Gems", gemItem.explicitModLines[1].line)
		assert.is_true(#gemItem.explicitModLines[1].modList > 0)

		local requirementItem = new("Item"):Item([[
			Rarity: Unique
			Replica Dragonfang's Flight
			Onyx Amulet
			{ Unique Modifier }
			Items and Gems have 8(10-5)% reduced Attribute Requirements
		]])
		assert.are.equals("Items and Gems have (5-10)% reduced Attribute Requirements", requirementItem.explicitModLines[1].line)
		assert.are.equals("Items and Gems have 8% reduced Attribute Requirements",
			itemLib.applyRange(requirementItem.explicitModLines[1].line, requirementItem.explicitModLines[1].range))
	end)

	it("parses Memory Strands as an item property", function()
		local item = new("Item"):Item([[
			Rarity: Magic
			Imperial Maul of Revitalization
			Weapon Range: 1.3 metres
			Memory Strands: 70
			Item Level: 85
			{ Suffix Modifier "of Revitalization" (Tier: 1) — Life, Attack }
			Grants 28(27-30) Life per Enemy Hit
		]])

		assert.are.equals(70, item.memoryStrands)
		assert.are.equals(1, #item.explicitModLines)
		local _, memoryStrandsCount = item:BuildRaw():gsub("Memory Strands:", "")
		assert.are.equals(1, memoryStrandsCount)

		item:BuildAndParseRaw()
		assert.are.equals(70, item.memoryStrands)
		assert.are.equals(1, #item.explicitModLines)
	end)

	it("preserves cluster jewel enchants from advanced copy", function()
		newBuild()
		runCallback("onFrame")
		build.itemsTab:CreateDisplayItemFromRaw([[
			Item Class: Jewels
			Rarity: Rare
			Fulgent Scar
			Medium Cluster Jewel
			--------
			Intangibility: 5%
			--------
			Requirements:
			Level: 54 (unmet)
			--------
			Item Level: 74
			--------
			Adds 4 Passive Skills (enchant)
			1 Added Passive Skill is a Jewel Socket (enchant)
			Added Small Passive Skills grant: 10% increased Damage while affected by a Herald (enchant)
			--------
			{ Prefix Modifier "Notable" (Tier: 1) — Damage }
			1 Added Passive Skill is Endbringer
			{ Prefix Modifier "Notable" (Tier: 1) — Damage }
			1 Added Passive Skill is Empowered Envoy
			{ Suffix Modifier "of the Newt" (Tier: 3) — Life }
			Added Small Passive Skills also grant: Regenerate 0.1% of Life per Second
			{ Suffix Modifier "of Joy" (Tier: 2) — Mana }
			Added Small Passive Skills also grant: 5% increased Mana Regeneration Rate
		]], true)

		local item = build.itemsTab.displayItem
		assert.are.equals("affliction_damage_while_you_have_a_herald", item.clusterJewelSkill)
		assert.are.equals("affliction_damage_while_you_have_a_herald", item.jewelData.clusterJewelSkill)
		assert.are.equals(4, item.clusterJewelNodeCount)
	end)

	describe("mod magnitude scaling", function()
		before_each(function()
			newBuild()
			runCallback("onFrame")
		end)
		local function chaosDamageInc()
			return build.calcsTab.mainEnv.modDB:Sum("INC", nil, "ChaosDamage")
		end

		local function chaosResist()
			return build.calcsTab.mainEnv.modDB:Sum("BASE", nil, "ChaosResist")
		end

		local function spellCrit()
			return build.calcsTab.mainEnv.modDB:Sum("INC", { flags = ModFlag.Spell }, "CritChance")
		end

		local function spellDamage()
			return build.calcsTab.mainEnv.modDB:Sum("INC", { flags = ModFlag.Spell }, "Damage")
		end

		it("scales advanced-copy Simplex Amulet explicit mods on the first parse", function()
			local rawItem = [[
				Rarity: Rare
				Grim Collar
				Simplex Amulet
				Quality (Critical Modifiers): +20% (augmented)
				{ Implicit Modifier }
				-2 Prefix Modifiers allowed
				-1 Suffix Modifier allowed
				100% increased Explicit Modifier magnitudes
				{ Prefix Modifier "The Elder's" (Tier: 1) — Damage, Chaos  — 100% Increased }
				Gain 13(3-5)% of Non-Chaos Damage as extra Chaos Damage
				{ Suffix Modifier "of Destruction" (Tier: 1) — Damage, Critical  — 120% Increased }
				+70(35-38)% to Global Critical Strike Multiplier
				{ Suffix Modifier "of Amassment" — Drop  — 100% Increased }
				20(17-20)% increased Quantity of Items found
				Shaper Item
				Elder Item
			]]

			build.itemsTab:CreateDisplayItemFromRaw(rawItem, true)
			local firstItem = build.itemsTab.displayItem
			local function findModLine(line)
				for _, modLine in ipairs(firstItem.explicitModLines) do
					if modLine.line == line then
						return modLine
					end
				end
			end
			assert.are.equals(2, findModLine("Gain 13% of Non-Chaos Damage as extra Chaos Damage").valueScalar)
			assert.are.equals(2.2, findModLine("+70% to Global Critical Strike Multiplier").valueScalar)

			-- Changing a different affix must not normalise either legacy roll.
			firstItem.suffixes[2].range = 0
			firstItem:Craft()
			assert.are.equals(2, findModLine("Gain 13% of Non-Chaos Damage as extra Chaos Damage").valueScalar)
			assert.are.equals(2.2, findModLine("+70% to Global Critical Strike Multiplier").valueScalar)

			-- Editing the legacy affix itself deliberately returns it to the current range.
			firstItem.suffixes[1].range = 1
			firstItem:Craft()
			assert.are.equals(2, findModLine("Gain 13% of Non-Chaos Damage as extra Chaos Damage").valueScalar)
			assert.are.equals(2.2, findModLine("+38% to Global Critical Strike Multiplier").valueScalar)
		end)

		it("scales matching implicit mods by modifier magnitude", function()
			-- 130% * 1.7 = 221
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Void Sceptre
			LevelReq: 60
			Implicits: 1
			{range:0.5}(100-160)% increased Chaos Damage
			{range:0.5}70% increased implicit Modifier magnitudes
		]])
			local item = build.itemsTab.displayItem
			assert.is_true(item.advancedCopy)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(221, chaosDamageInc())
		end)

		it("does not apply disabled modifier magnitude", function()
			local item = new("Item"):Item([[
			Rarity: UNIQUE
			Magnitude Test
			Plate Vest
			Implicits: 1
			{range:0.5}+(10-20) to maximum Life
			{disabled}100% increased Implicit Modifier magnitudes
		]])
			assert.are.equals(1, item.implicitModLines[1].valueScalar)
		end)

		it("scales properly using old Eyes of the Greatwolf line", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: UNIQUE
			Eyes of the Greatwolf
			Greatwolf Talisman
			Quality (Caster Modifiers): +20% (augmented)
			LevelReq: 60
			Implicits: 1
			{tags:caster}{range:0.5}(100-160)% increased Spell Damage
			{range:0.5}Implicit Modifier magnitudes are doubled
		]])
			local item = build.itemsTab.displayItem
			assert.is_true(item.advancedCopy)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(312, spellDamage())
		end)

		it("scales properly using new Eyes of the Greatwolf line", function()
			-- 130% * 1.7 = 221
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Void Sceptre
			LevelReq: 60
			Implicits: 1
			{range:0.5}{crafted}(100-160)% increased Chaos Damage
			{range:0.5}(50-100)% increased Enchantment Modifier magnitudes
		]])
			local item = build.itemsTab.displayItem
			assert.is_true(item.advancedCopy)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(227, chaosDamageInc())
		end)
		it("does not rescale old format (baked) copies", function()
			-- magnitude already baked in, so no rescale
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Baked Subject
			Imperial Staff
			LevelReq: 60
			Implicits: 0
			{tags:chaos,damage}130% increased Chaos Damage
			70% increased Chaos Modifier magnitudes
		]])
			local item = build.itemsTab.displayItem
			assert.is_false(item.advancedCopy)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(130, chaosDamageInc())
		end)

		it("only scales mods that share the magnitude mod's tags", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Sapphire Ring
			LevelReq: 20
			Implicits: 0
			{tags:chaos,damage}{range:0.5}(100-160)% increased Chaos Damage
			{tags:resistance}{range:0.5}+(20-40)% to Chaos Resistance
			{range:0.5}100% increased resistance modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(0, chaosResist())
			assert.are.equals(130, chaosDamageInc())
			newBuild()

			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Sapphire Ring
			LevelReq: 20
			Implicits: 0
			{tags:chaos,damage}{range:0.5}(100-160)% increased Chaos Damage
			{tags:defences}{range:0.5}+(20-40)% to Chaos Resistance
			{range:0.5}100% increased defence modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(0, chaosResist())
			assert.are.equals(130, chaosDamageInc())
			newBuild()

			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Sapphire Ring
			LevelReq: 20
			Implicits: 0
			{tags:chaos,damage}{range:0.5}(100-160)% increased Chaos Damage
			{tags:physical,damage}{range:0.5}+(20-40)% to Chaos Resistance
			{tags:caster,damage}{range:0.5}(10-30)% increased spell damage
			{range:0.5}100% increased Explicit Physical and Chaos Damage Modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(0, chaosResist())
			assert.are.equals(260, chaosDamageInc())
			assert.are.equals(20, spellDamage())
		end)

		it("only scales the modifier type named by the magnitude mod", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Sapphire Ring
			LevelReq: 20
			Implicits: 1
			{range:0.5}(100-160)% increased Chaos Damage
			{range:0.5}+(20-40)% to Chaos Resistance
			{range:0.5}100% increased explicit modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(0, chaosResist())
			assert.are.equals(130, chaosDamageInc())
		end)

		it("handles explicit physical and chaos modifier magnitudes", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Void Sceptre
			LevelReq: 60
			Implicits: 1
			{tags:chaos,damage}{range:0.5}(100-160)% increased Chaos Damage
			{tags:physical,chaos,damage}{range:0.5}(100-160)% increased Chaos Damage
			{range:0.5}10% increased Explicit Physical and Chaos Damage Modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(273, chaosDamageInc())
		end)

		it("does not scale unscalable modifiers", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Void Sceptre
			LevelReq: 60
			Implicits: 0
			{tags:chaos,damage}{range:0.5}(100-160)% increased Chaos Damage — Unscalable Value
			{range:0.5}100% increased Explicit Modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(130, chaosDamageInc())
		end)

		it("reduces the modifier magnitude correctly", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Sapphire Ring
			LevelReq: 20
			Implicits: 0
			{range:0.5}(100-160)% increased Chaos Damage
			{range:0.5}+(20-40)% to Chaos Resistance
			{range:0.5}50% reduced explicit modifier magnitudes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(-45, chaosResist())
			assert.are.equals(65, chaosDamageInc())
		end)
		it("scales only prefixes for increased effect of prefixes", function()
			build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Subject
			Sapphire Ring
			LevelReq: 20
			Implicits: 0
			{prefix}{range:0.5}(100-160)% increased Chaos Damage
			{suffix}{range:0.5}+(20-40)% to Chaos Resistance
			{range:0.5}50% increased effect of prefixes
		]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(-30, chaosResist())
			assert.are.equals(195, chaosDamageInc())
		end)

		-- actually a ring so we don't have to allocate a socket
		local realJewel = [[
				Rarity: Rare
				Pandemonium Desire
				Ruby Ring
				--------
				Quality (Caster Modifiers): +20% (augmented)
				--------
				Item Level: 80
				--------
				{ Corruption Enhancement — Elemental, Cold, Resistance }
				+7(5-10)% to Cold Resistance
				{ Corruption Enhancement — Attribute }
				+6(4-6) to Intelligence
				--------
				{ Fractured Crafted Prefix Modifier "" }
				60(40-60)% increased Effect of Suffixes — Unscalable Value
				{ Prefix Modifier "Mystic" (Tier: 1) — Damage, Caster — 20% Increased }
				7(5-15)% increased Spell Damage
				{ Suffix Modifier "of Unmaking" (Tier: 1) — Damage, Caster, Critical — 80% Increased }
				20(10-20)% increased Critical Spell Damage Bonus
				{ Desecrated Suffix Modifier "of Annihilating" (Tier: 1) — Caster, Critical — 80% Increased }
				15(5-15)% increased Critical Hit Chance for Spells
				{ Suffix Modifier "of Potency" (Tier: 1) — Damage, Critical — 60% Increased }
				20(10-20)% increased Critical Strike Multiplier
				--------
				Place into an allocated Jewel Socket on the Passive Skill Tree. Right click to remove from the Socket.
				--------
				Twice Corrupted
				--------
				Fractured Item
				--------
				Note: ~b/o 1 mirror
		]]
		it("scales only prefixes for increased effect of prefixes for advanced copy format", function()
			assert.equal(0, spellCrit())
			local item = new("Item"):Item(realJewel)
			build.itemsTab:AddItem(item)
			build.itemsTab:EquipItemInSet(item, build.itemsTab.activeItemSetId)
			runCallback("OnFrame")
			assert.equal(27, spellCrit())
			assert.equal(8, spellDamage())
		end)

		it("does not apply scaling twice when saving and loading", function()
			local item = new("Item"):Item(new("Item"):Item(realJewel):BuildRaw())
			build.itemsTab:AddItem(item)
			build.itemsTab:EquipItemInSet(item, build.itemsTab.activeItemSetId)
			runCallback("OnFrame")
			assert.equal(27, spellCrit())
			assert.equal(8, spellDamage())
		end)
	end)
end)
