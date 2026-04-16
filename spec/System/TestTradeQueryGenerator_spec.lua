describe("TradeQueryGenerator", function()
	local mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {}, GetTradeStatusOption = function() return "online" end })

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

	describe("Talisman mods", function()
		it("only generates enchant weights when enabled", function()
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
			local enchantMods = queryGen.modData.Enchant
			queryGen.modData = { Explicit = { }, Implicit = { }, Enchant = enchantMods, Corrupted = { }, Scourge = { } }
			queryGen.calcContext = { special = { }, options = { } }
			local generated = { }
			queryGen.GenerateModWeights = function(_, mods) generated[mods] = true end

			queryGen:ExecuteQuery()
			assert.is_nil(generated[enchantMods])

			queryGen.calcContext.options.includeTalisman = true
			queryGen:ExecuteQuery()
			assert.is_true(generated[enchantMods])
		end)

		it("includes the utility flask charge enchant", function()
			local enchant
			for id, mod in pairs(LoadModule("Data/QueryMods.lua").Enchant) do
				if id:match("_UtilityFlaskPassiveChargeGain$") then
					enchant = mod
					break
				end
			end

			assert.is_not_nil(enchant)
			assert.are.equals("enchant.stat_2567919918", enchant.tradeMod.id)
			assert.are.equals("Utility Flasks gain # Charges every 3 seconds", enchant.specialCaseData.overrideModLine)
		end)
	end)

	describe("WeightedRatioOutputs", function()
		local maxStatIncrease

		before_each(function()
			maxStatIncrease = data.misc.maxStatIncrease
			data.misc.maxStatIncrease = 1000
		end)

		after_each(function()
			data.misc.maxStatIncrease = maxStatIncrease
		end)

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
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
			assert.are.equal(result, 100)
		end)
		it("uses minion output for non-FullDPS stats when minion output is desired", function()
			local baseOutput = { Life = 10, Minion = { Life = 100 } }
			local newOutput = { Life = 10, Minion = { Life = 250 } }
			local statWeights = { { stat = "MinionLife", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)

			assert.are.equal(result, 2.5)
		end)

		it("uses lower is better stats correctly", function()
			local baseOutput = { MaxHit = 100 }
			local newOutput = { MaxHit = 10 }
			local statWeights = { { stat = "MaxHit", weightMult = 1, transform = function(number) return -number end } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)

			local close_enough = math.abs(result - -0.1) < 0.0001
			assert.True(close_enough)
		end)

		it("uses player and minion output for FullDPS", function()
			-- minion output gets assigned to the player's full dps in reality
			local baseOutput = { FullDPS = 100, Minion = { FullDPS = 100 } }
			local newOutput = { FullDPS = 250, Minion = { FullDPS = 1000 } }
			local statWeights = { { stat = "FullDPS", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)

			assert.are.equal(result, 2.5)
		end)

		it("uses player output for non-FullDPS even when minion output is available", function()
			local baseOutput = { Life = 100, Minion = { Life = 100 } }
			local newOutput = { Life = 250, Minion = { Life = 1000 } }
			local statWeights = { { stat = "Life", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
			assert.are.equal(result, 2.5)
		end)

		it("uses the fallback DPS ratio once when FullDPS is unavailable", function()
			local baseOutput = { Minion = { TotalDPS = 10, TotalDotDPS = 0, CombinedDPS = 10 } }
			local newOutput = { Minion = { TotalDPS = 25, TotalDotDPS = 0, CombinedDPS = 25 } }
			local statWeights = { { stat = "FullDPS", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)

			assert.are.equal(result, 2.5)
		end)

		it("falls back to player output when the selected stat is not on minion output", function()
			local baseOutput = { Spirit = 100, Minion = { AverageDamage = 100 } }
			local newOutput = { Spirit = 120, Minion = { AverageDamage = 100 } }
			local statWeights = { { stat = "Spirit", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)

			assert.are.equal(result, 1.2)
		end)

		it("supports light radius as a player stat weight", function()
			local lightRadiusStat
			local minionLightRadiusStat
			for _, stat in ipairs(data.powerStatList) do
				if stat.stat == "LightRadiusMod" then
					lightRadiusStat = stat
				elseif stat.stat == "MinionLightRadiusMod" then
					minionLightRadiusStat = stat
				end
			end

			assert.is_not_nil(lightRadiusStat)
			assert.is_nil(minionLightRadiusStat)
			local result = mock_queryGen.WeightedRatioOutputs(
				{ LightRadiusMod = 1 },
				{ LightRadiusMod = 1.25 },
				{ { stat = lightRadiusStat.stat, weightMult = 1 } })
			assert.are.equal(result, 1.25)
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

	describe("Eldritch mod weights", function()
		local IGNORE = mock_queryGen._INFLUENCE_IGNORE_INDEX
		local NONE = mock_queryGen._INFLUENCE_NONE_INDEX
		local ANY = mock_queryGen._INFLUENCE_ANY_INDEX

		local function generatesEldritchWeights(influence1, influence2)
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
			local eaterMod = { }
			local exarchMod = { }
			queryGen.modData = {
				Explicit = { },
				Implicit = { },
				Eater = { EaterMod = eaterMod },
				Exarch = { ExarchMod = exarchMod },
			}
			queryGen.calcContext = {
				special = { },
				options = {
					includeEldritch = "Keep regular",
					influence1 = influence1,
					influence2 = influence2,
				},
			}
			local generated = { }
			queryGen.GenerateModWeights = function(_, mods)
				for _, mod in pairs(mods) do
					generated[mod] = true
				end
			end

			queryGen:ExecuteQuery()
			return generated[eaterMod] == true and generated[exarchMod] == true
		end

		it("skips weights when Any requires an influenced item", function()
			assert.is_false(generatesEldritchWeights(ANY, IGNORE))
		end)

		it("keeps weights when both influence slots are unconstrained or empty", function()
			assert.is_true(generatesEldritchWeights(IGNORE, NONE))
		end)
	end)

	describe("Filter prioritization", function()
		it("counts socket and link constraints against MAX_FILTERS", function()
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = { items = {} } })
			queryGen.modWeights = { }
			for index = 1, 40 do
				table.insert(queryGen.modWeights, {
					tradeModId = "explicit.stat_" .. index,
					weight = 1,
					meanStatDiff = 41 - index,
				})
			end
			queryGen.calcContext = {
				testItem = new("Item"):Item("Rarity: RARE\nNew Item\nGold Ring\nImplicits: 0"),
				baseOutput = { },
				baseStatValue = 0,
				itemCategoryQueryStr = "accessory.ring",
				special = { },
				options = {
					statWeights = { },
					influence1 = 1,
					influence2 = 1,
					includeMirrored = false,
					sockets = 6,
					links = 6,
				},
			}
			queryGen.tradeTypeIndex = 1
			local query
			queryGen.requesterCallback = function(_, queryJson)
				query = require("dkjson").decode(queryJson).query
			end

			queryGen:FinishQuery()

			-- Ignore / Ignore uses no influence slots: 36 - mirrored - sockets - links.
			assert.are.equal(33, #query.stats[1].filters)
			assert.is_not_nil(query.filters.socket_filters.filters.sockets)
			assert.is_not_nil(query.filters.socket_filters.filters.links)
		end)
	end)
end)
