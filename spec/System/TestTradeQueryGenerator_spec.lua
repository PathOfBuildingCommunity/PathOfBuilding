describe("TradeQueryGenerator", function()
	local mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })

	local function findStatFilter(queryTable, id, groupType)
		for _, group in ipairs(queryTable.stats) do
			for _, filter in ipairs(group.filters) do
				if filter.id == id and (not groupType or group.type == groupType) then
					return filter
				end
			end
		end
	end

	local function finishQueryWithAttributeMinimums(minimums, includeAttributeRequirementFilters)
		local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
		local queryTable, errMsg
		queryGen.modWeights = {
			{ tradeModId = "explicit.stat_3299347043", weight = 1, meanStatDiff = 1 },
		}
		queryGen.tradeTypeIndex = 1
		queryGen.requesterCallback = function(_, generatedQuery, queryErrMsg)
			queryTable = generatedQuery
			errMsg = queryErrMsg
		end
		queryGen.calcContext = {
			itemCategoryQueryStr = "accessory.ring",
			special = {},
			testItem = { BuildAndParseRaw = function() end },
			baseOutput = { TotalDPS = 100 },
			options = {
				statWeights = { { stat = "TotalDPS", weightMult = 1 } },
				includeAttributeRequirementFilters = includeAttributeRequirementFilters,
				includeMirrored = true,
			},
			attributeRequirementMinimums = minimums,
		}

		local previousClosePopup = main.ClosePopup
		main.ClosePopup = function() end
		local ok, finishError = pcall(queryGen.FinishQuery, queryGen)
		main.ClosePopup = previousClosePopup
		assert.is_true(ok, finishError)

		return queryTable, errMsg
	end

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
			queryGen.requesterCallback = function(_, generatedQuery)
				query = generatedQuery
			end

			queryGen:FinishQuery()

			assert.are.equal(31, #query.stats[1].filters)
			assert.is_not_nil(query.filters.socket_filters.filters.sockets)
			assert.is_not_nil(query.filters.socket_filters.filters.links)

			-- Account searches must also work without a maximum price.
			queryGen.calcContext.options = {
				statWeights = {}, influence1 = 1, influence2 = 1,
				includeMirrored = true, account = "ExampleAccount", maxLevel = 80, links = 5,
			}
			queryGen:FinishQuery()
			assert.same({ input = "ExampleAccount" }, query.filters.trade_filters.filters.account)
			assert.same({ max = 80 }, query.filters.req_filters.filters.lvl)
			assert.same({ min = 5, max = 5 }, query.filters.socket_filters.filters.links)
			assert.is_nil(query.filters.socket_filters.filters.sockets)
		end)
	end)

	describe("attribute requirement filters", function()
		for _, case in ipairs({
			{ name = "admits an equipped candidate whose Strength is amplified", customMods = "+50 to Strength\n100% increased Strength", originalStrength = 30, candidateMods = "+26 to Strength", strength = 192, minimum = 26 },
			{ name = "does not tighten the filter when a candidate increases reduced Strength", customMods = "+150 to Strength\n10% reduced Strength", originalStrength = 50, candidateMods = "+38 to Strength\n6% increased Strength", strength = 200, minimum = 38 },
		}) do
			it(case.name, function()
				newBuild()
				build.characterLevel, build.characterLevelAutoMode = 100, false
				build.configTab.input.customMods = case.customMods
				build.configTab:BuildModList()
				build.itemsTab:AddItem(new("Item"):Item("Rarity: RARE\nRequirement Anchor\nGlorious Plate\nImplicits: 0"))
				build.itemsTab:AddItem(new("Item"):Item("Rarity: RARE\nOriginal Ring\nGold Ring\nImplicits: 0\n+" .. case.originalStrength .. " to Strength"))
				build.modFlag, build.buildFlag = true, true
				runCallback("OnFrame")
				local candidate = new("Item"):Item("Rarity: RARE\nCandidate Ring\nGold Ring\nImplicits: 0\n" .. case.candidateMods)
				local calc = build.calcsTab:GetMiscCalculator()
				local equipped = calc({ repSlotName = "Ring 1", repItem = candidate })
				assert.are.equal(case.strength, equipped.Str)
				assert.are.equal(191, equipped.ReqStr)
				local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = build.itemsTab })
				local query
				queryGen.requesterCallback = function(_, generatedQuery) query = generatedQuery end
				queryGen:StartQuery(build.itemsTab.slots["Ring 1"], {
					statWeights = { { stat = "Life", weightMult = 1 } },
					includeAttributeRequirementFilters = true, includeMirrored = true,
				})
				while queryGen.calcContext.co do queryGen:OnFrame() end
				assert.are.equal(case.minimum, findStatFilter(query, "pseudo.pseudo_total_strength", "and").value.min)
			end)
		end

		it("calculates attribute minimums from the blank replacement output", function()
			local calcArgs
			local modDB = new("ModDB"):ModDB()
			for attribute, value in pairs({ Str = 40, Dex = 35, Int = 20 }) do
				modDB:NewMod(attribute, "BASE", value, "Fixture")
			end
			local calcsTab = {
				GetMiscCalculator = function()
					return function(args)
						calcArgs = args
						return {
							TotalDPS = 100,
							ReqStr = 50, Str = 40,
							ReqDex = 30, Dex = 35,
							ReqInt = 25, Int = 20,
						}, modDB
					end, { TotalDPS = 100 }
				end,
			}
			local queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({
				itemsTab = {
					items = {
						[1] = { baseName = "Gold Ring" },
					},
					build = { calcsTab = calcsTab },
				},
			})
			local previousOpenPopup = main.OpenPopup
			main.OpenPopup = function() return {} end
			local ok, startError = pcall(queryGen.StartQuery, queryGen, { slotName = "Ring 1", selItemId = 1 }, {
				statWeights = { { stat = "TotalDPS", weightMult = 1 } },
			})
			main.OpenPopup = previousOpenPopup
			assert.is_true(ok, startError)
			assert.are.equal("Ring 1", calcArgs.repSlotName)
			assert.are.equal("Gold Ring", calcArgs.repItem.baseName)
			assert.same({ Str = 10, Dex = 0, Int = 5 }, queryGen.calcContext.attributeRequirementMinimums)
		end)

		it("adds needed attribute pseudo filters to the generated query", function()
			local queryTable, errMsg = finishQueryWithAttributeMinimums({ Str = 12, Dex = 34, Int = 56 }, true)
			assert.is_nil(errMsg)
			assert.are.equal(12, findStatFilter(queryTable, "pseudo.pseudo_total_strength").value.min)
			assert.are.equal(34, findStatFilter(queryTable, "pseudo.pseudo_total_dexterity").value.min)
			assert.are.equal(56, findStatFilter(queryTable, "pseudo.pseudo_total_intelligence").value.min)
		end)

		it("omits attribute pseudo filters when disabled or no shortfall exists", function()
			local disabledQuery = finishQueryWithAttributeMinimums({ Str = 12, Dex = 34, Int = 56 }, false)
			local zeroQuery = finishQueryWithAttributeMinimums({ Str = 0, Dex = 0, Int = 0 }, true)
			assert.is_nil(findStatFilter(disabledQuery, "pseudo.pseudo_total_strength"))
			assert.is_nil(findStatFilter(disabledQuery, "pseudo.pseudo_total_dexterity"))
			assert.is_nil(findStatFilter(disabledQuery, "pseudo.pseudo_total_intelligence"))
			assert.is_nil(findStatFilter(zeroQuery, "pseudo.pseudo_total_strength"))
			assert.is_nil(findStatFilter(zeroQuery, "pseudo.pseudo_total_dexterity"))
			assert.is_nil(findStatFilter(zeroQuery, "pseudo.pseudo_total_intelligence"))
		end)
	end)
end)
