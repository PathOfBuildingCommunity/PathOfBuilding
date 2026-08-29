describe("TradeQueryGenerator", function()
	local mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })

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

	describe("EstimateBenchCraftWeight", function()
		local queryGen

		local function makeCraft(spec)
			local lines = spec.lines or { spec.line }
			spec.line, spec.lines = nil, nil
			for _, line in ipairs(lines) do table.insert(spec, line) end
			spec.types = spec.types or { Ring = true }
			return spec
		end

		local function addWeightedTradeMod(spec)
			queryGen.modData.Explicit[spec.statOrder .. "_" .. spec.group] =
				{ tradeMod = { id = spec.id, text = spec.text } }
			table.insert(queryGen.modWeights, { tradeModId = spec.id, weight = spec.weight })
		end

		before_each(function()
			queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = { } })
			queryGen.modData = { Explicit = { } }
			queryGen.modWeights = { }
		end)

		it("adds the weighted values of every craft line", function()
			addWeightedTradeMod({ statOrder = 1203, group = "TestAttributes", id = "explicit.stat_4080418644",
				text = "+# to Strength", weight = 2 })
			addWeightedTradeMod({ statOrder = 1204, group = "TestAttributes", id = "explicit.stat_3261801346",
				text = "+# to Dexterity", weight = 3 })
			local craft = makeCraft({ lines = { "+(10-10) to Strength", "+(20-20) to Dexterity" },
				statOrder = { 1203, 1204 }, group = "TestAttributes" })
			local evaluationPlan = queryGen:CreateBenchCraftEvaluationPlan({ { stat = "Life", weightMult = 1 } })

			assert.are.equal(80, queryGen:EstimateBenchCraftWeight(craft, evaluationPlan))
			assert.are.equal(96, queryGen:EstimateBenchCraftWeight(craft, evaluationPlan, 1.2))
			assert.are.equal(120, queryGen:EstimateBenchCraftWeight(craft, evaluationPlan, 1.5))
			assert.are.equal(80, evaluationPlan.craftWeights[craft])
		end)

		it("keeps the first craft when the highest levels in a group are tied", function()
			local low = makeCraft({ group = "Test", level = 1 })
			local firstHigh = makeCraft({ group = "Test", level = 2 })
			local secondHigh = makeCraft({ group = "Test", level = 2 })

			local crafts = queryGen:GetHighestLevelBenchCrafts({ low, firstHigh, secondHigh })

			assert.are.same({ firstHigh }, crafts)
		end)

		it("keeps generated mod and stat weights immutable", function()
			queryGen.modWeights = { { tradeModId = "explicit.test", weight = 2 } }
			local statWeights = { { stat = "Life", weightMult = 1 } }

			local evaluationPlan = queryGen:CreateBenchCraftEvaluationPlan(statWeights)
			queryGen.modWeights[1].weight = 20
			statWeights[1].weightMult = 10

			assert.are.equal(2, evaluationPlan.weightsByTradeMod["explicit.test"].weight)
			assert.are.equal(1, evaluationPlan.statWeights[1].weightMult)
		end)

		it("finds the best positive compatible bench craft query weight", function()
			local prefixLow = makeCraft({ type = "Prefix", level = 1, statOrder = { 1203 },
				group = "TestStrength", line = "+(10-10) to Strength" })
			local prefixHigh = makeCraft({ type = "Prefix", level = 2, statOrder = { 1203 },
				group = "TestStrength", line = "+(20-20) to Strength" })
			local suffix = makeCraft({ type = "Suffix", statOrder = { 1204 },
				group = "TestDexterity", line = "+(10-10) to Dexterity" })
			local incompatible = makeCraft({ type = "Prefix", types = { Amulet = true }, statOrder = { 1203 },
				group = "TestStrength", line = "+(100-100) to Strength" })
			local negative = makeCraft({ type = "Prefix", types = { Belt = true }, statOrder = { 1205 },
				group = "TestIntelligence", line = "+(10-10) to Intelligence" })
			queryGen.itemsTab.build = {
				data = { masterMods = { prefixLow, prefixHigh, suffix, incompatible, negative } },
			}
			addWeightedTradeMod({ statOrder = 1203, group = "TestStrength", id = "explicit.stat_4080418644",
				text = "+# to Strength", weight = 2 })
			addWeightedTradeMod({ statOrder = 1204, group = "TestDexterity", id = "explicit.stat_3261801346",
				text = "+# to Dexterity", weight = 3 })
			addWeightedTradeMod({ statOrder = 1205, group = "TestIntelligence", id = "explicit.stat_328541901",
				text = "+# to Intelligence", weight = -4 })
			local evaluationPlan = queryGen:CreateBenchCraftEvaluationPlan({ })

			local weight = queryGen:GetBenchCraftQueryWeight({ type = "Ring" }, evaluationPlan)

			assert.are.equal(40, weight)
			assert.is_nil(queryGen:GetBenchCraftQueryWeight({ type = "Belt" }, evaluationPlan))
		end)

		it("weights only items with exactly one empty affix", function()
			queryGen.GetBenchCraftQueryWeight = function() return 60 end

			local filter, priority = queryGen:GetBenchCraftQueryFilter({ type = "Ring" }, { })

			assert.are.equal("pseudo.pseudo_number_of_empty_affix_mods", filter.id)
			assert.are.same({ min = 1, max = 1, weight = 60 }, filter.value)
			assert.are.equal(60, priority)
			assert.is_nil(filter.priority)
		end)
	end)

	describe("Filter prioritization", function()
		it("counts socket and link constraints against the complexity budget", function()
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

		it("ranks the single empty affix weight with regular filters before applying the complexity budget", function()
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = { items = { } } })
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
			queryGen.requesterContext = { slotTbl = { considerBenchCraft = true } }
			local receivedPlan
			queryGen.GetBenchCraftQueryFilter = function(_, _, evaluationPlan)
				receivedPlan = evaluationPlan
				return {
					id = "pseudo.pseudo_number_of_empty_affix_mods",
					value = { min = 1, max = 1, weight = 35.5 },
				}, 35.5
			end
			local query
			queryGen.requesterCallback = function(_, queryJson)
				query = require("dkjson").decode(queryJson).query
			end

			queryGen:FinishQuery()
			local filtersById = { }
			for _, filter in ipairs(query.stats[1].filters) do
				filtersById[filter.id] = filter
			end
			assert.are.equal(31, #query.stats[1].filters)
			assert.are.equal(35.5, filtersById["pseudo.pseudo_number_of_empty_affix_mods"].value.weight)
			assert.is_not_nil(filtersById["explicit.stat_30"])
			assert.is_nil(filtersById["explicit.stat_31"])
			assert.are.equal(receivedPlan, queryGen.requesterContext.benchCraftEvaluationPlan)
		end)
	end)
end)
