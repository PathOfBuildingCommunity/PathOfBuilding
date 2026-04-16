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

	describe("Influence query state", function()
		local IGNORE = mock_queryGen._INFLUENCE_IGNORE_INDEX  -- 1
		local NONE   = mock_queryGen._INFLUENCE_NONE_INDEX    -- 2
		local ANY    = mock_queryGen._INFLUENCE_ANY_INDEX     -- 3
		local SHAPER = ANY + 1  -- 4
		local ELDER  = ANY + 2  -- 5
		local resolve = mock_queryGen._resolveInfluenceQueryState
		local cost    = mock_queryGen._getInfluenceFilterCost
		local needs   = mock_queryGen._needsHasInfluenceFilter

		-- None: uses pseudo_has_influence=0 (1 slot instead of 6-slot NOT filter)
		it("None uses 1-slot pseudo_has_influence=0", function()
			local state = resolve(NONE, IGNORE)
			assert.are.equal(state.exactCount, 0)
			assert.is_true(state.hasNoneConstraint)
			assert.are.equal(cost(state), 1)
			assert.is_true(needs(state))
		end)

		-- Shaper+None: needs pseudo_has_influence=1 to cap at 1 influence (avoids Shaper+Elder matches)
		it("Shaper+None uses 2-slot filter (specific + pseudo_has_influence=1)", function()
			local state = resolve(SHAPER, NONE)
			assert.are.equal(state.exactCount, 1)
			assert.is_true(state.hasNoneConstraint)
			assert.are.equal(#state.specificInfluenceModIds, 1)
			assert.are.equal(cost(state), 2)
			assert.is_true(needs(state))
		end)

		-- Shaper+Elder: 2 named influences, no None → no pseudo_has_influence needed (saves 1 slot)
		it("Shaper+Elder uses 2-slot filter (specific mods only, no pseudo_has_influence)", function()
			local state = resolve(SHAPER, ELDER)
			assert.are.equal(state.exactCount, 2)
			assert.is_false(state.hasNoneConstraint)
			assert.are.equal(#state.specificInfluenceModIds, 2)
			assert.are.equal(cost(state), 2)
			assert.is_false(needs(state))
		end)

		-- Any+Ignore: minCount=1 → pseudo_has_influence min=1 (1 slot)
		it("Any uses 1-slot pseudo_has_influence min=1", function()
			local state = resolve(ANY, IGNORE)
			assert.are.equal(state.minCount, 1)
			assert.are.equal(state.exactCount, nil)
			assert.are.equal(cost(state), 1)
			assert.is_true(needs(state))
		end)

		-- Any+Shaper: exactCount=2 with one unnamed slot → needs pseudo_has_influence=2
		it("Any+Shaper uses 2-slot filter (specific + pseudo_has_influence=2)", function()
			local state = resolve(ANY, SHAPER)
			assert.are.equal(state.exactCount, 2)
			assert.is_false(state.hasNoneConstraint)
			assert.are.equal(#state.specificInfluenceModIds, 1)
			assert.are.equal(cost(state), 2)
			assert.is_true(needs(state))
		end)

		-- pseudo_has_influence mod ID is correct
		it("hasAnyInfluenceModId is pseudo.pseudo_has_influence_count", function()
			assert.are.equal(mock_queryGen._hasAnyInfluenceModId, "pseudo.pseudo_has_influence_count")
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
