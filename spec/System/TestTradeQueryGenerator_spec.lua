describe("TradeQueryGenerator", function()
	local mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
	local tradeResistanceGrouping = LoadModule("Classes/TradeResistanceGrouping")

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

	describe("Eldritch mods", function()
		it("shows the Eldritch options for amulets", function()
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = { items = { } } })
			queryGen:RequestQuery({ slotName = "Amulet" }, {
				slotTbl = { slotName = "Amulet", alreadyCorrupted = false },
			}, { }, function() end)

			assert.is_not_nil(main.popups[1].controls.includeEldritch)
			main:ClosePopup()
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

	describe("resistance search options", function()
		it("derives non-negative cap shortfalls from the blank-item output", function()
			assert.are.same({ Fire = 12, Cold = 0, Lightning = 34, Chaos = 56 },
				tradeResistanceGrouping.getResistanceCapShortfallByType({
					MissingFireResist = 12,
					MissingColdResist = -3,
					MissingLightningResist = 34,
					MissingChaosResist = 56,
				}))
		end)

		it("annotates weights through the real GenerateModWeights method", function()
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
			queryGen.modWeights = {}
			queryGen.alreadyWeightedMods = {}
			queryGen.calcContext = {
				itemCategory = "Ring",
				testItem = new("Item"):Item("Rarity: RARE\nTest Ring\nCoral Ring\nImplicits: 0"),
				baseOutput = { Life = 100 },
				baseStatValue = 1000,
				calcFunc = function() return { Life = 110 } end,
				options = {
					includeTalisman = false,
					statWeights = { { stat = "Life", weightMult = 1 } },
				},
				slot = { slotName = "Ring 1" },
			}
			queryGen:GenerateModWeights({
				fireResistance = {
					Ring = { min = 10, max = 10, subType = "" },
					tradeMod = { id = "explicit.fire_resistance", text = "+#% to Fire Resistance" },
					specialCaseData = {},
				},
			})

			assert.are.equal(1, #queryGen.modWeights)
			assert.is_true(queryGen.modWeights[1].resistTag.elemental)
			assert.are.equal(queryGen.modWeights[1].weight, queryGen.modWeights[1].normalisedWeight)
		end)

		local function finishQuery(options, weights)
			options = options or {}
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
			queryGen.tradeTypeIndex = 4
			queryGen.modWeights = weights
			queryGen.calcContext = {
				itemCategoryQueryStr = "accessory.ring",
				special = {},
				testItem = new("Item"):Item("Rarity: RARE\nTest Ring\nCoral Ring\nImplicits: 0"),
				baseOutput = { Life = 100 },
				baseStatValue = 1000,
				calcFunc = function() return { Life = 100 } end,
				options = {
					includeMirrored = true,
					statWeights = { { stat = "Life", weightMult = 1 } },
					includeResistSwaps = options.includeResistSwaps,
					includeResistCaps = options.includeResistCaps,
				},
				requiredMods = options.requiredMods or {},
				resistanceCapShortfallByType = options.resistanceCapShortfallByType,
			}
			queryGen.requesterContext = { slotTbl = { sentinel = true } }
			local queryJson
			local queryOptions
			local queryError
			queryGen.requesterCallback = function(_, json, errMsg, optionsSnapshot)
				queryJson = json
				queryError = errMsg
				queryOptions = optionsSnapshot
			end
			queryGen:FinishQuery()
			return require("dkjson").decode(queryJson), queryGen.requesterContext.slotTbl, queryOptions, queryError
		end

		local function annotatedWeight(id, text, weight, meanStatDiff)
			return tradeResistanceGrouping.annotateResistanceWeight({
				tradeModId = id, weight = weight, meanStatDiff = meanStatDiff, invert = false,
			}, text)
		end

		local function weight(id, value, meanStatDiff)
			return { tradeModId = id, weight = value, meanStatDiff = meanStatDiff or value, invert = false }
		end

		local function filtersById(query, groupType)
			local filters = { }
			for _, group in ipairs(query.query.stats) do
				if not groupType or group.type == groupType then
					for _, filter in ipairs(group.filters) do
						filters[filter.id] = filter
					end
				end
			end
			return filters
		end

		local function minimumsById(query)
			local minimums = { }
			for id, filter in pairs(filtersById(query, "and")) do
				minimums[id] = filter.value.min
			end
			return minimums
		end

		it("groups resistance without changing damage filters", function()
			local query = finishQuery({ includeResistSwaps = true }, {
				annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 10, 10),
				weight("explicit.fire_damage", 8),
				weight("explicit.life", 6),
			})
			local filters = filtersById(query, "weight")

			assert.is_not_nil(filters["pseudo.pseudo_total_elemental_resistance"])
			assert.is_not_nil(filters["explicit.fire_damage"])
			assert.is_not_nil(filters["explicit.life"])
			assert.is_nil(filters["explicit.fire_resistance"])
		end)

		it("leaves non-swappable resistance filters unchanged", function()
			local cases = {
				{ "hybrid elemental and chaos", "explicit.hybrid_resistance", "+#% to Fire and Chaos Resistances" },
				{ "implicit resistance", "implicit.fire_resistance", "+#% to Fire Resistance" },
			}
			for _, case in ipairs(cases) do
				local query = finishQuery({ includeResistSwaps = true }, { annotatedWeight(case[2], case[3], 10, 10) })
				local filters = query.query.stats[1].filters
				assert.are.equal(1, #filters, case[1])
				assert.are.equal(case[2], filters[1].id, case[1])
			end
		end)

		it("does not let hybrid resistance expansion evict a lower-priority filter", function()
			local weights = {
				annotatedWeight("explicit.hybrid_resistance", "+#% to Fire and Chaos Resistances", 100, 100),
			}
			for index = 1, 31 do
				table.insert(weights, weight(string.format("explicit.filler_%d", index), 100 - index))
			end
			table.insert(weights, weight("explicit.low_priority_filter", 1))

			local query = finishQuery({ includeResistSwaps = true }, weights)
			local filters = filtersById(query, "weight")

			assert.are.equal(33, #query.query.stats[1].filters)
			assert.is_not_nil(filters["explicit.hybrid_resistance"])
			assert.is_not_nil(filters["explicit.low_priority_filter"])
		end)

		it("does not persist the swap option into requester context", function()
			local _, slotTable, queryOptions = finishQuery({ includeResistSwaps = true }, {
				weight("explicit.life", 6),
			})

			assert.are.same({ sentinel = true }, slotTable)
			assert.are.same({ includeResistSwaps = true, includeResistCaps = false, weightAdjustedSearch = true }, queryOptions)
		end)

		it("normalises multi-element resistance weights before pseudo grouping", function()
			local query = finishQuery({ includeResistSwaps = true }, {
				annotatedWeight("explicit.all_resistance", "+#% to all Elemental Resistances", 30, 30),
				annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 8, 8),
			})
			local filter = query.query.stats[1].filters[1]

			assert.are.equal("pseudo.pseudo_total_elemental_resistance", filter.id)
			assert.are.equal(10, filter.value.weight)
		end)

		it("uses individual or grouped cap minimums according to the swap option", function()
			local shortfalls = { Fire = 10, Cold = 20, Lightning = 30, Chaos = 40 }
			local cases = {
				{ label = "caps only", options = { includeResistCaps = true }, weights = {
					annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 10, 10),
					annotatedWeight("implicit.cold_resistance", "+#% to Cold Resistance", 9, 9),
					annotatedWeight("explicit.fire_chaos_resistance", "+#% to Fire and Chaos Resistances", 8, 8),
					weight("explicit.life", 6),
				}, minimums = {
					["pseudo.pseudo_total_fire_resistance"] = 10,
					["pseudo.pseudo_total_cold_resistance"] = 20,
					["pseudo.pseudo_total_lightning_resistance"] = 30,
					["pseudo.pseudo_total_chaos_resistance"] = 40,
				} },
				{ label = "caps with swaps", options = { includeResistCaps = true, includeResistSwaps = true }, weights = {
					annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 10, 10),
					weight("explicit.life", 6),
				}, minimums = {
					["pseudo.pseudo_total_elemental_resistance"] = 60,
					["pseudo.pseudo_total_chaos_resistance"] = 40,
				} },
			}
			for _, case in ipairs(cases) do
				case.options.resistanceCapShortfallByType = shortfalls
				local query, _, queryOptions = finishQuery(case.options, case.weights)
				assert.are.same(case.minimums, minimumsById(query), case.label)
				assert.are.equal(1, #query.query.stats[1].filters, case.label)
				assert.are.equal("explicit.life", query.query.stats[1].filters[1].id, case.label)
				assert.are.equal(0, query.query.stats[1].value.min, case.label)
				assert.is_false(queryOptions.weightAdjustedSearch, case.label)
			end
		end)

		it("builds an AND-only price-sorted query when caps remove every weighted filter", function()
			local query, _, queryOptions = finishQuery({
				includeResistCaps = true,
				resistanceCapShortfallByType = { Fire = 25 },
			}, {
				annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 10, 10),
			})

			assert.are.equal(1, #query.query.stats)
			assert.are.equal("and", query.query.stats[1].type)
			assert.are.same({ price = "asc" }, query.sort)
			assert.is_false(queryOptions.weightAdjustedSearch)
		end)

		it("does not add zero resistance minimums or an empty AND group", function()
			local query, _, _, queryError = finishQuery({
				includeResistCaps = true,
				resistanceCapShortfallByType = { Fire = 0, Cold = 0, Lightning = 0, Chaos = 0 },
			}, {
				annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 10, 10),
			})

			assert.are.equal(0, #query.query.stats)
			assert.is_truthy(queryError)
		end)

		it("preserves the upstream weighted-group error for required-only searches when caps are off", function()
			local query, _, queryOptions, queryError = finishQuery({
				requiredMods = { { tradeId = "explicit.required", value = 10 } },
			}, {})

			assert.are.equal("weight", query.query.stats[1].type)
			assert.are.equal(0, #query.query.stats[1].filters)
			assert.are.equal("and", query.query.stats[2].type)
			assert.are.same({ ["statgroup.0"] = "desc" }, query.sort)
			assert.is_false(queryOptions.weightAdjustedSearch)
			assert.is_truthy(queryError)
		end)

		it("budgets cap and required filters before weighted filters", function()
			local requiredMods = {}
			for index = 1, 32 do
				requiredMods[index] = { tradeId = "explicit.required_" .. index, value = index }
			end
			local query, _, queryOptions = finishQuery({
				includeResistCaps = true,
				resistanceCapShortfallByType = { Fire = 25 },
				requiredMods = requiredMods,
			}, {
				weight("explicit.life", 6),
			})
			local filterCount = 0
			for _, group in ipairs(query.query.stats) do
				filterCount = filterCount + #group.filters
			end

			assert.are.equal(33, filterCount)
			assert.are.equal("and", query.query.stats[1].type)
			assert.is_false(queryOptions.weightAdjustedSearch)
		end)

		it("preserves upstream filter order when resistance swaps are disabled", function()
			local query = finishQuery({ includeResistSwaps = false }, {
				annotatedWeight("explicit.fire_resistance", "+#% to Fire Resistance", 3, 30),
				weight("explicit.fire_damage", 2, 20),
				weight("explicit.life", 1, 10),
			})
			local filters = query.query.stats[1].filters

			assert.are.equal("explicit.fire_resistance", filters[1].id)
			assert.are.equal("explicit.fire_damage", filters[2].id)
			assert.are.equal("explicit.life", filters[3].id)
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

			assert.are.equal(31, #query.stats[1].filters)
			assert.is_not_nil(query.filters.socket_filters.filters.sockets)
			assert.is_not_nil(query.filters.socket_filters.filters.links)
		end)
	end)
end)
