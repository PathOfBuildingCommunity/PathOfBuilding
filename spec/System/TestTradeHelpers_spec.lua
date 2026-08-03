describe("TradeHelpers trade hash matching", function()
	local tradeHelpers = LoadModule("Classes/TradeHelpers")

	describe("modLineValue", function()
		it("returns the single number on a line", function()
			assert.equal(50, tradeHelpers.modLineValue("+50 to maximum Life"))
		end)

		it("returns the midpoint of a '# to #' range", function()
			assert.equal(15, tradeHelpers.modLineValue("Adds 10 to 20 Fire Damage"))
			assert.equal(12.5, tradeHelpers.modLineValue("Adds 10 to 15 Fire Damage"))
		end)

		it("handles negative numbers", function()
			assert.equal(-10, tradeHelpers.modLineValue("-10% to Fire Resistance"))
		end)

		it("returns nil when onlyFromTo is set and there is no range", function()
			assert.is_nil(tradeHelpers.modLineValue("+50 to maximum Life", true))
		end)
	end)

	describe("findTradeIdOption", function()
		it("matches a flattened option stat and returns its value", function()
			local tradeId, value = tradeHelpers.findTradeIdOption(
				"Passive skills in radius of Elemental Overload can be Allocated without being connected to your tree",
				"explicit")
			assert.equal("explicit.stat_2422708892", tradeId)
			assert.equal(22088, value)
		end)

		it("matches a legacy '#'-valued option and returns its value", function()
			local tradeId, value = tradeHelpers.findTradeIdOption("Grants Level 20 Summon Bestial Snake Skill",
				"explicit")
			assert.equal("explicit.stat_2878779644", tradeId)
			assert.equal(3, value)
		end)

		it("matches an exact-text option and returns no value", function()
			local tradeId, value = tradeHelpers.findTradeIdOption("Allocates Tranquility", "enchant")
			assert.equal("enchant.stat_2954116742", tradeId)
			assert.equal(16246, value)
		end)

		it("matches a timeless jewel", function()
			local tradeId, value = tradeHelpers.findTradeIdOption(
				"Bathed in the blood of 666 sacrificed in the name of Doryani", "explicit")
			assert.equal("explicit.pseudo_timeless_jewel_doryani", tradeId)
			assert.equal(666, value)
		end)

		it("returns nil for an unmatchable line", function()
			assert.is_nil(tradeHelpers.findTradeIdOption("+100 to IQ", "explicit"))
		end)
	end)
	describe("findTradeHash", function()
		it("matches a simple mod", function()
			local ids, value = tradeHelpers.findTradeHash("+50 to maximum Life")
			assert.equal(50, value)
			assert.is_truthy(isValueInArray(ids, HashStats({ "base_maximum_life" })))
		end)

		it("matches a percentage mod", function()
			local ids, value = tradeHelpers.findTradeHash("25% reduced maximum Energy Shield")
			assert.equal(25, value)
			assert.is_truthy(isValueInArray(ids, HashStats({ "maximum_energy_shield_+%" })))
		end)

		it("matches a # to # mod", function()
			local ids, value = tradeHelpers.findTradeHash("Adds 5 to 15 Fire Damage")
			assert.equal(10, value)
			assert.is_truthy(isValueInArray(ids,
				HashStats({ "local_minimum_added_fire_damage", "local_maximum_added_fire_damage" })))
		end)

		it("is case-insensitive", function()
			local ids = tradeHelpers.findTradeHash(
				"1 aDDED PASSiVe sKilL IS ONE wITh The ShiELd")
			assert.is_truthy(isValueInArray(ids, HashStats({ "local_affliction_notable_one_with_the_shield" })))
		end)

		it("returns no results for an unmatchable line", function()
			local ids = tradeHelpers.findTradeHash("+100 to IQ")
			assert.equal(0, #ids)
		end)

		it("detects inverted mods correctly", function()
			-- note that this stat is a handwrap mod and doesn't actually exist on the trade site
			local ids, value, shouldNegate = tradeHelpers.findTradeHash(
				"Debuffs on you expire 100% slower while affected by Haste")
			assert.equal(100, value)
			assert.is_true(shouldNegate)
			assert.equal(1, #ids)

			local ids, value, shouldNegate = tradeHelpers.findTradeHash("67% reduced maximum life")
			assert.equal(67, value)
			assert.is_true(shouldNegate)
			assert.equal(1, #ids)
		end)
		it("detects mods with lua pattern characters correctly", function()
			local ids, value = tradeHelpers.findTradeHash(
				"trigger Socketed Spells when you focus, with a 0.25 second cooldown")
			assert.is_truthy(isValueInArray(ids, HashStats({ "trigger_socketed_spells_when_you_focus_%" })))
			assert.equal(100, value)

			local ids, value, shouldNegate = tradeHelpers.findTradeHash(
				"10% reduced effect of Non-Curse Auras from your Skills on your Minions")
			assert.is_truthy(isValueInArray(ids, HashStats({ "minions_have_non_curse_aura_effect_+%_from_parent_skills" })))
			assert.equal(10, value)
			assert.is_true(shouldNegate)
		end)
		it("detects passage modline correctly", function()
			local ids = tradeHelpers.findTradeHash(
				"Passive Skills in Radius can be Allocated without being connected to your tree")
			assert.is_truthy(isValueInArray(ids,
				HashStats({ "local_unique_jewel_nearby_disconnected_passives_can_be_allocated",
					"unique_thread_of_hope_base_resist_all_elements_%" })))
		end)
	end)
end)
