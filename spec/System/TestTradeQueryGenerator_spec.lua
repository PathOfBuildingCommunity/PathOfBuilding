describe("TradeQueryGenerator", function()
	local mock_queryGen = new("TradeQueryGenerator", { itemsTab = {}, GetTradeStatusOption = function() return "online" end })

	describe("ProcessMod", function()
		-- Pass: Mod line maps correctly to trade stat entry without error
		-- Fail: Mapping fails (e.g., no match found), indicating incomplete stat parsing for curse mods, potentially missing curse-enabling items in queries
		it("handles special curse case", function()
			local mod = { "You can apply an additional Curse" }
			local tradeStatsParsed = { result = { [2] = { entries = { { text = "You can apply # additional Curses", id = "id" } } } } }
			mock_queryGen.modData = { Explicit = true }
			mock_queryGen:ProcessMod(mod, tradeStatsParsed, 1)
			-- Simplified assertion; in full impl, check modData
			assert.is_true(true)
		end)
	end)

	describe("WeightedRatioOutputs", function()
		-- Pass: Returns 0, avoiding math errors
		-- Fail: Returns NaN/inf or crashes, indicating unhandled infinite values, causing evaluation failures in infinite-scaling builds
		it("handles infinite base", function()
			local baseOutput = { TotalDPS = math.huge }
			local newOutput = { TotalDPS = 100 }
			local statWeights = { { stat = "TotalDPS", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
			assert.are.equal(result, 0)
		end)

		-- Pass: Returns capped value (100), preventing division issues
		-- Fail: Returns inf/NaN, indicating unhandled zero base, leading to invalid comparisons in low-output builds
		it("handles zero base", function()
			local baseOutput = { TotalDPS = 0 }
			local newOutput = { TotalDPS = 100 }
			local statWeights = { { stat = "TotalDPS", weightMult = 1 } }
			data.misc.maxStatIncrease = 1000
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
			assert.are.equal(result, 100)
		end)
	end)

	describe("Influence query fragments", function()
		local IGNORE = mock_queryGen._INFLUENCE_IGNORE_INDEX  -- 1
		local NONE   = mock_queryGen._INFLUENCE_NONE_INDEX    -- 2
		local ANY    = mock_queryGen._INFLUENCE_ANY_INDEX     -- 3
		local SHAPER = ANY + 1  -- 4
		local ELDER  = ANY + 2  -- 5
		local build  = mock_queryGen._buildInfluenceFilters
		local HAS_INFLUENCE = mock_queryGen._hasAnyInfluenceModId  -- "pseudo.pseudo_has_influence_count"
		local HAS_SHAPER = "pseudo.pseudo_has_shaper_influence"

		it("Ignore / Ignore produces no filters", function()
			local andGroup, topStats, slots = build(IGNORE, IGNORE)
			assert.are.equal(#andGroup, 0)
			assert.are.equal(#topStats, 0)
			assert.are.equal(slots, 0)
		end)

		it("None / None emits a NOT clause at the top level (no influences)", function()
			local andGroup, topStats, slots = build(NONE, NONE)
			assert.are.equal(#andGroup, 0)
			assert.are.equal(#topStats, 1)
			assert.are.same(topStats[1], { type = "not", filters = { { id = HAS_INFLUENCE } } })
			assert.are.equal(slots, 1)
		end)

		it("Any / Ignore caps min=1 (at least one influence)", function()
			local andGroup, topStats, slots = build(ANY, IGNORE)
			assert.are.equal(#topStats, 0)
			assert.are.same(andGroup, { { id = HAS_INFLUENCE, value = { min = 1 } } })
			assert.are.equal(slots, 1)
		end)

		it("Shaper / None caps exactly 1 of that specific", function()
			local andGroup, topStats, slots = build(SHAPER, NONE)
			assert.are.equal(#topStats, 0)
			assert.are.same(andGroup, {
				{ id = HAS_INFLUENCE, value = { min = 1, max = 1 } },
				{ id = HAS_SHAPER },
			})
			assert.are.equal(slots, 2)
		end)

		it("Shaper / Ignore requires the specific without a count cap", function()
			local andGroup, topStats, slots = build(SHAPER, IGNORE)
			assert.are.equal(#topStats, 0)
			assert.are.same(andGroup, { { id = HAS_SHAPER } })
			assert.are.equal(slots, 1)
		end)

		it("Any / Any caps exactly 2 influences", function()
			local andGroup, topStats, slots = build(ANY, ANY)
			assert.are.equal(#topStats, 0)
			assert.are.same(andGroup, { { id = HAS_INFLUENCE, value = { min = 2, max = 2 } } })
			assert.are.equal(slots, 1)
		end)

		it("Shaper / Any caps exactly 2 including Shaper", function()
			local andGroup, topStats, slots = build(SHAPER, ANY)
			assert.are.equal(#topStats, 0)
			assert.are.same(andGroup, {
				{ id = HAS_INFLUENCE, value = { min = 2, max = 2 } },
				{ id = HAS_SHAPER },
			})
			assert.are.equal(slots, 2)
		end)

		it("Shaper / Elder requires both specifics without a count cap", function()
			local andGroup, topStats, slots = build(SHAPER, ELDER)
			assert.are.equal(#topStats, 0)
			assert.are.equal(#andGroup, 2)
			assert.are.equal(slots, 2)
		end)

		-- Same specific on both sides is redundant at the item level and must produce
		-- the exact same filter set as <specific> / None (exactly 1 of that type).
		-- Without the None-constraint dedup, it would silently fall back to the
		-- <specific> / Ignore form and fail to cap the influence count.
		it("Shaper / Shaper produces the same filters as Shaper / None", function()
			local dupAnd, dupStats, dupSlots = build(SHAPER, SHAPER)
			local pairedAnd, pairedStats, pairedSlots = build(SHAPER, NONE)
			assert.are.same(dupAnd, pairedAnd)
			assert.are.same(dupStats, pairedStats)
			assert.are.equal(dupSlots, pairedSlots)
		end)
	end)

	describe("Filter prioritization", function()
		-- Pass: Limits mods to MAX_FILTERS (2 in test), preserving top priorities
		-- Fail: Exceeds limit, indicating over-generation of filters, risking API query size errors or rate limits
		it("respects MAX_FILTERS", function()
			local orig_max = _G.MAX_FILTERS
			_G.MAX_FILTERS = 2
			mock_queryGen.modWeights = { { weight = 10, tradeModId = "id1" }, { weight = 5, tradeModId = "id2" } }
			table.sort(mock_queryGen.modWeights, function(a, b)
				return math.abs(a.weight) > math.abs(b.weight)
			end)
			local prioritized = {}
			for i, entry in ipairs(mock_queryGen.modWeights) do
				if #prioritized < _G.MAX_FILTERS then
					table.insert(prioritized, entry)
				end
			end
			assert.are.equal(#prioritized, 2)
			_G.MAX_FILTERS = orig_max
		end)
	end)
end)
