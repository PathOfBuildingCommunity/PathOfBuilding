describe("TradeHelpers trade hash matching", function()
	local tradeHelpers = LoadModule("Classes/TradeHelpers")

	---@param ids number[]
	---@param expected number
	---@return boolean contains whether the given array contains the expected id
	local function contains(ids, expected)
		for _, id in ipairs(ids) do
			if id == expected then return true end
		end
		return false
	end

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

	describe("findTradeHash", function()
		it("matches a simple mod", function()
			local ids, value = tradeHelpers.findTradeHash("+50 to maximum Life")
			assert.equal(50, value)
			assert.is_true(contains(ids, HashStats({ "base_maximum_life" })))
		end)

		it("matches a percentage mod", function()
			local ids, value = tradeHelpers.findTradeHash("25% reduced maximum Energy Shield")
			assert.equal(25, value)
			assert.is_true(contains(ids, HashStats({ "maximum_energy_shield_+%" })))
		end)

		it("matches a # to #  mod", function()
			local ids, value = tradeHelpers.findTradeHash("Adds 5 to 15 Fire Damage")
			assert.equal(10, value)
			assert.is_true(contains(ids,
				HashStats({ "local_minimum_added_fire_damage", "local_maximum_added_fire_damage" })))
		end)

		it("is case-insensitive", function()
			local ids = tradeHelpers.findTradeHash(
				"Each ArroW fIred is a Crescendo, Splinter, Reversing, Diamond, Covetous, or Blunt Arrow")
			assert.is_true(contains(ids, HashStats({ "each_arrow_fired_gains_random_perdandus_prefix" })))
		end)

		it("returns no results for an unmatchable line", function()
			local ids = tradeHelpers.findTradeHash("+100 to IQ")
			assert.equal(0, #ids)
		end)

		it("works thrice in a row", function()
			local a = tradeHelpers.findTradeHash("+50 to maximum Life")
			local b = tradeHelpers.findTradeHash("+50 to maximum Life")
			local c = tradeHelpers.findTradeHash("+50 to maximum Life")
			assert.same(a, b)
			assert.same(b, c)
		end)

		it("detects inverted mods correctly", function()
			-- note that this stat is a handwrap mod and doesn't actually exist on the trade site
			local ids, value, shouldNegate = tradeHelpers.findTradeHash("100% more damage taken while on low life")
			assert.equal(100, value)
			assert.is_true(shouldNegate)
			assert.equal(1, #ids)

			local ids, value, shouldNegate = tradeHelpers.findTradeHash("67% reduced maximum life")
			assert.equal(67, value)
			assert.is_true(shouldNegate)
			assert.equal(1, #ids)
		end)
		it("detects mods with lua pattern characters correctly", function()
			-- there is a form of this line which is literally 3.5% without a variable
			local ids, value = tradeHelpers.findTradeHash("Socketed Gems have +3.5% Critical Hit Chance")
			assert.is_true(contains(ids, HashStats({ "local_display_socketed_gems_additional_critical_strike_chance_%" })))
			-- for some reason the range is 3-3 on the descriptor. this behaviour is still correct
			assert.equal(3, value)

			local ids, value, shouldNegate = tradeHelpers.findTradeHash(
				"10% reduced effect of Non-Curse Auras from your Skills on your Minions")
			assert.is_true(contains(ids, HashStats({ "minions_have_non_curse_aura_effect_+%_from_parent_skills" })))
			assert.equal(10, value)
			assert.is_true(shouldNegate)
		end)

		it("matches time-lost jewel mods correctly", function()
			local ids, value = tradeHelpers.findTradeHash(
				"Small Passive Skills in Radius also grant 3% increased Damage with Bows")
			assert.equal(1, #ids)
			assert.is_true(contains(ids, HashStats({ "bow_damage_+%", "local_jewel_mod_stats_added_to_small_passives" })))
			assert.equal(3, value)

			local ids, value = tradeHelpers.findTradeHash(
				"Notable Passive Skills in Radius also grant 7% increased Critical Hit Chance for Attacks")
			assert.is_true(contains(ids,
				HashStats({ "attack_critical_strike_chance_+%", "local_jewel_mod_stats_added_to_notable_passives" })))
			assert.equal(7, value)
		end)
	end)
end)
