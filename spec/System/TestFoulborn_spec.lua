describe("TestFoulborn", function()
	-- spell-checker: disable
	-- Voll's Devotion has two foulborn-convertible mods in ModFoulbornMap.jsonc:
	--   "30% reduced Power Charge Duration"     -> "Gain a Power Charge every Second..."
	--   "30% reduced Endurance Charge Duration" -> "Lose all Power Charges..."
	local powerBase = "30% reduced Power Charge Duration"
	local powerFoulborn = "Gain a Power Charge every Second if you haven't lost Power Charges Recently"
	-- the mod ids the two sides of the transformation resolve to
	local powerBaseId = "PowerChargeDurationUniqueAmulet14"
	local powerFoulbornId = "MutatedUniqueAmulet14GainPowerChargesNotLostRecently"

	local function vollsDevotion()
		return new("Item", [[
			Rarity: Unique
			Voll's Devotion
			Agate Amulet
			Implicits: 1
			+(16-24) to Strength and Intelligence
			+(20-30) to maximum Energy Shield
			+(30-40) to maximum Life
			+(15-20)% to all Elemental Resistances
			30% reduced Endurance Charge Duration
			30% reduced Power Charge Duration
			Gain an Endurance Charge when you lose a Power Charge
		]])
	end

	-- find a mod line by its exact displayed text
	local function findByLine(item, text)
		for _, modLine in ipairs(item.explicitModLines) do
			if modLine.line == text then
				return modLine
			end
		end
	end

	-- toggle foulborn on or off
	local function toggle(item, modLine)
		item:MutateMod(modLine.modId, modLine.newModId, not modLine.mutated)
	end

	it("marks convertible mods with their foulborn transformation", function()
		local item = vollsDevotion()
		local modLine = findByLine(item, powerBase)
		assert.is_not_nil(modLine)
		assert.are.equals(powerBaseId, modLine.modId)
		assert.are.equals(powerFoulbornId, modLine.newModId)
		-- offered but not applied by default, so the line is in its base form
		assert.is_falsy(modLine.mutated)
	end)

	it("offers convertible mods in the item modifier controls", function()
		local item = vollsDevotion()
		local modLine = findByLine(item, powerBase)
		local found
		for _, rangeLine in ipairs(item.rangeLineList) do
			if rangeLine == modLine then
				found = true
			end
		end
		assert.is_true(found)
	end)

	it("does not mark non-convertible mods", function()
		local item = vollsDevotion()
		local plainMod = findByLine(item, "Gain an Endurance Charge when you lose a Power Charge")
		assert.is_not_nil(plainMod)
		assert.is_nil(plainMod.modId)
		assert.is_nil(plainMod.newModId)
	end)

	it("converts the mod line to its foulborn text when activated", function()
		local item = vollsDevotion()
		toggle(item, findByLine(item, powerBase))

		-- the base line is replaced by the foulborn line, which now offers the
		-- reverse transformation
		assert.is_nil(findByLine(item, powerBase))
		local mutated = findByLine(item, powerFoulborn)
		assert.is_not_nil(mutated)
		assert.is_true(mutated.mutated)
		assert.are.equals(powerFoulbornId, mutated.modId)
		assert.are.equals(powerBaseId, mutated.newModId)
	end)

	it("flags the item as foulborn and prefixes the title once a mod is mutated", function()
		local item = vollsDevotion()
		-- an unmodified item is a plain unique
		assert.is_falsy(item.foulborn)
		assert.are.equals("Voll's Devotion", item.title)

		toggle(item, findByLine(item, powerBase))
		assert.is_true(item.foulborn)
		assert.are.equals("Foulborn Voll's Devotion", item.title)

		-- reverting the last mutated mod drops the flag and the prefix again
		toggle(item, findByLine(item, powerFoulborn))
		assert.is_falsy(item.foulborn)
		assert.are.equals("Voll's Devotion", item.title)
	end)

	it("keeps the mutated state through BuildRaw", function()
		local item = vollsDevotion()
		toggle(item, findByLine(item, powerBase))

		local raw = item:BuildRaw()
		assert.is_truthy(raw:find("{mutated}" .. powerFoulborn, 1, true))

		-- re-importing the built text preserves the foulborn conversion
		local reimported = new("Item", raw)
		local mutated = findByLine(reimported, powerFoulborn)
		assert.is_not_nil(mutated)
		assert.is_true(mutated.mutated)
		assert.is_nil(findByLine(reimported, powerBase))
		-- the foulborn flag and title prefix survive the round-trip
		assert.is_true(reimported.foulborn)
		assert.are.equals("Foulborn Voll's Devotion", reimported.title)
	end)

	it("reverts to the base mod when deactivated", function()
		local item = vollsDevotion()
		toggle(item, findByLine(item, powerBase))
		assert.is_not_nil(findByLine(item, powerFoulborn))

		toggle(item, findByLine(item, powerFoulborn))

		local base = findByLine(item, powerBase)
		assert.is_not_nil(base)
		assert.is_falsy(base.mutated)
		assert.is_nil(findByLine(item, powerFoulborn))
	end)

	it("only converts the activated mod when several are convertible", function()
		local item = vollsDevotion()
		toggle(item, findByLine(item, powerBase))

		-- the endurance charge mod stays in its base form and is still offered
		local endurance = findByLine(item, "30% reduced Endurance Charge Duration")
		assert.is_not_nil(endurance)
		assert.is_falsy(endurance.mutated)
	end)

	it("leaves items without a foulborn mapping untouched", function()
		-- same mod text, but on a rare: mutatedLines is only populated for
		-- uniques listed in the foulborn map
		local item = new("Item", "Rarity: Rare\nTest Subject\nAgate Amulet\n30% reduced Power Charge Duration")
		assert.is_nil(item.mutatedLines)
		assert.is_nil(item.explicitModLines[1].modId)
	end)

	-- Meginord's Vise maps a single mod to a two-line foulborn replacement:
	--   "+# to Strength" -> "+700 Strength Requirement\n(10-15)% chance to deal Triple Damage"
	local viseBase = "+50 to Strength"
	local viseFoulbornId = "MutatedUniqueGlovesStr2StrengthRequirementAndTripleDamageChance"

	local function meginordsVise()
		return new("Item", [[
			Rarity: Unique
			Meginord's Vise
			Steel Gauntlets
			+50 to Strength
			100% increased Knockback Distance
		]])
	end

	local function linesAllByModId(item, modId)
		local out = {}
		for _, modLine in ipairs(item.explicitModLines) do
			if modLine.modId == modId then
				table.insert(out, modLine)
			end
		end
		return out
	end

	local function hasMod(item, name)
		for _, modLine in ipairs(item.explicitModLines) do
			for _, mod in ipairs(modLine.modList or {}) do
				if mod.name == name then
					return true
				end
			end
		end
		return false
	end

	it("expands a single mod into two lines when a 1->2 foulborn mod is activated", function()
		local item = meginordsVise()

		-- one base mod carries the whole multi-line transformation
		local base = findByLine(item, viseBase)
		assert.is_not_nil(base)
		assert.are.equals(viseFoulbornId, base.newModId)
		assert.is_falsy(base.mutated)

		toggle(item, base)

		-- the base line is gone, replaced by one mod line per stat line, each
		-- offering the reverse transformation back to the single base mod
		assert.is_nil(findByLine(item, viseBase))
		local mutated = linesAllByModId(item, viseFoulbornId)
		assert.are.equals(2, #mutated)

		local seen = {}
		for _, modLine in ipairs(mutated) do
			assert.is_true(modLine.mutated)
			assert.are.equals(viseFoulbornId, modLine.modId)
			seen[modLine.line] = true
		end
		assert.is_true(seen["+700 Strength Requirement"])
		assert.is_true(seen["(10-15)% chance to deal Triple Damage"])

		-- both stat lines contribute their own parsed mod
		assert.is_true(hasMod(item, "StrRequirement"))
		assert.is_true(hasMod(item, "TripleDamageChance"))
	end)

	it("collapses the expanded lines back to the base mod when deactivated", function()
		local item = meginordsVise()
		toggle(item, findByLine(item, viseBase))
		assert.are.equals(2, #linesAllByModId(item, viseFoulbornId))

		-- deactivating from either expanded line restores the single base mod
		toggle(item, findByLine(item, "(10-15)% chance to deal Triple Damage"))

		local restored = findByLine(item, viseBase)
		assert.is_not_nil(restored)
		assert.is_falsy(restored.mutated)
		assert.is_nil(findByLine(item, "+700 Strength Requirement"))
		assert.is_false(hasMod(item, "TripleDamageChance"))
	end)

	it("keeps Kitava's Thirst transformations reversible", function()
		local item = new("Item", [[
			Rarity: Unique
			Kitava's Thirst
			Zealot Helmet
			Variant: Pre 3.11.0
			Variant: Current
			Selected Variant: 2
			50% chance to Trigger Socketed Spells when you Spend at least 100 Mana on an
			Upfront Cost to Use or Trigger a Skill, with a 0.1 second Cooldown
		]])
		local baseId = "ChanceToCastOnManaSpentUnique__1"
		local foulbornId = "MutatedUniqueHelmetStrInt6ChanceToCastOnManaSpent"
		local base = linesAllByModId(item, baseId)[1]

		toggle(item, base)

		local transformed = linesAllByModId(item, foulbornId)
		assert.are.equals(1, #transformed)
		assert.are.equals(baseId, transformed[1].newModId)

		toggle(item, transformed[1])
		assert.are.equals(1, #linesAllByModId(item, baseId))
	end)

	it("keeps Foulborn lines separate from unsupported modifiers", function()
		local item = new("Item", [[
			Rarity: Unique
			The Green Nightmare
			Viridian Jewel
			Variant: Pre 3.16.0
			Variant: Pre 3.21.0
			Variant: Current
			Selected Variant: 1
			Radius: Large
			{variant:1,2}Passives granting Cold Resistance or all Elemental Resistances in Radius
			{variant:1,2}also grant an equal chance to gain a Frenzy Charge on Kill
			{variant:1}Passives granting Cold Resistance or all Elemental Resistances in Radius
			{variant:1}also grant Chance to Suppress Spell Damage at 35% of its value
		]])
		local baseId = "ColdResistConvertedToDodgeChanceScaledJewelUnique__1"
		local foulbornId = "MutatedUniqueJewel88UniqueJewelColdResistAlsoGrantsConvertColdToChaos"
		local base = linesAllByModId(item, baseId)[1]

		toggle(item, base)

		local transformed = linesAllByModId(item, foulbornId)
		assert.are.equals(1, #transformed)
		assert.are.equals(baseId, transformed[1].newModId)

		toggle(item, transformed[1])
		assert.are.equals(1, #linesAllByModId(item, baseId))
	end)
end)
