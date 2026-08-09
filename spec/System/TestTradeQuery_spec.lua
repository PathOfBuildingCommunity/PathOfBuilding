describe("TradeQuery", function()
	local mock_tradeQuery
	local mock_queryGen

	before_each(function()
		mock_tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
		mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
	end)
	describe("cooperative result evaluation", function()
		it("resumes fetched result work over multiple frames", function()
			local tradeQuery = new("TradeQuery", { itemsTab = {} })
			tradeQuery.controls.priceButton1 = { label = "Price Item" }
			tradeQuery.controls.pbNotice = { label = "" }
			tradeQuery.resultTbl[1] = { { }, { } }
			local events = { }
			tradeQuery.UpdateControlsWithItems = function(_, _, yieldFunc)
				table.insert(events, "first")
				yieldFunc(1, 2)
				table.insert(events, "second")
				yieldFunc(2, 2)
				table.insert(events, "done")
			end

			tradeQuery:StartResultEvaluation(1)

			assert.are.same({ }, events)
			assert.are.equal("Eval 0/2...", tradeQuery.controls.priceButton1.label)

			tradeQuery:ProcessResultEvaluations()
			assert.are.same({ "first" }, events)
			assert.are.equal("Eval 1/2...", tradeQuery.controls.priceButton1.label)

			tradeQuery:ProcessResultEvaluations()
			assert.are.same({ "first", "second" }, events)
			assert.are.equal("Eval 2/2...", tradeQuery.controls.priceButton1.label)

			tradeQuery:ProcessResultEvaluations()
			assert.are.same({ "first", "second", "done" }, events)
			assert.are.equal("Price Item", tradeQuery.controls.priceButton1.label)
			assert.is_nil(tradeQuery.resultEvaluationContexts[1])
		end)
	end)
	describe("result dropdown tooltipFunc", function()
		-- Builds a TradeQuery with the strict minimum needed for
		-- PriceItemRowDisplay to construct row 1 without exploding. Only the
		-- two itemsTab subtables read by the slot lookup at the top of
		-- PriceItemRowDisplay need to be created here; everything else either
		-- lives behind a callback we never trigger, or is already initialized
		-- by the TradeQuery constructor.
		local function newTradeQuery(state)
			local tq = new("TradeQuery"):TradeQuery({ itemsTab = {} })
			tq.itemsTab.activeItemSet = {}
			tq.itemsTab.slots         = {}
			tq.slotTables[1] = { slotName = "Ring 1" }
			if state.resultTbl       then tq.resultTbl       = state.resultTbl       end
			if state.sortedResultTbl then tq.sortedResultTbl = state.sortedResultTbl end
			return tq
		end

		-- Builds row 1 of the trader UI and returns the dropdown that owns the
		-- tooltipFunc we want to exercise.
		local function buildRow1Dropdown(tq)
			tq:PriceItemRowDisplay(1, nil, 0, 20)
			return tq.controls.resultDropdown1
		end

		it("returns early when sortedResultTbl[row_idx] is missing", function()
			-- No sorted results at all -> first guard must short-circuit.
			local tq = newTradeQuery({})
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip"):Tooltip()

			assert.has_no.errors(function()
				dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
			end)
			assert.are.equal(0, #tooltip.lines)
		end)

		it("returns early when the backing result entry has been cleared", function()
			-- The dropdown must be built against a valid result so that
			-- PriceItemRowDisplay's construction loop succeeds; we wipe
			-- resultTbl[1] only afterwards, to simulate a stale tooltip
			-- callback firing after the results were invalidated.
			local tq = newTradeQuery({
				resultTbl       = { [1] = { [1] = { item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring", amount = 1, currency = "chaos" } } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			local dropdown = buildRow1Dropdown(tq)
			tq.resultTbl[1] = {}
			local tooltip = new("Tooltip"):Tooltip()

			assert.has_no.errors(function()
				dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
			end)
			assert.are.equal(0, #tooltip.lines)
		end)

		it("shows a compact resistance swap without changing the listed item", function()
			local itemString = "Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+17% to Fire Resistance"
			local tq = newTradeQuery({
				resultTbl = { [1] = { [1] = {
					item_string = itemString,
					amount = 1,
					currency = "chaos",
					evaluation = { {
						output = {},
						weight = 1,
						theoreticalResistanceSwap = { { from = "Fire", to = "Cold", value = 17 } },
						theoreticalResistanceSwapItemString = "Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+17% to Cold Resistance",
						theoreticalResistanceSwapLineIndexes = { 1 },
					} },
				} } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.AddItemTooltip = function() end
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip")

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
			local text = ""
			for _, line in ipairs(tooltip.lines) do
				text = text .. (line.text or "") .. "\n"
			end
			assert.is_truthy(text:find("Estimated swap: Fire -> Cold", 1, true))
			assert.is_truthy(text:find("(roll may change)", 1, true))
			assert.is_truthy(text:find("[Ctrl: compare]", 1, true))
			assert.is_nil(text:find("17%", 1, true))
			assert.are.equal(itemString, tq.resultTbl[1][1].item_string)
		end)

		it("highlights every swapped line and leaves other lines unchanged in the Ctrl preview", function()
			local itemString = "Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+30 to Strength\n+17% to Fire Resistance\n+24% to Cold Resistance"
			local tq = newTradeQuery({
				resultTbl = { [1] = { [1] = {
					item_string = itemString,
					amount = 1,
					currency = "chaos",
					evaluation = { {
						output = {},
						weight = 1,
						theoreticalResistanceSwap = {
							{ from = "Fire", to = "Cold", value = 17 },
							{ from = "Cold", to = "Lightning", value = 24 },
						},
						theoreticalResistanceSwapItemString = "Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+30 to Strength\n+17% to Cold Resistance\n+24% to Lightning Resistance",
						theoreticalResistanceSwapLineIndexes = { 2, 3 },
					} },
				} } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.AddItemTooltip = function(_, tooltip, item)
				for _, modLine in ipairs(item.explicitModLines) do
					tooltip:AddLine(16, colorCodes.MAGIC .. modLine.line, nil, modLine)
				end
			end
			tq.IsResistanceSwapPreviewActive = function() return true end
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip")

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)

			assert.are.equal(1, #tooltip.childTooltips)
			local previewText = ""
			for _, line in ipairs(tooltip.childTooltips[1].lines) do
				previewText = previewText .. StripEscapes(line.text or "") .. "\n"
			end
			assert.is_truthy(previewText:find("[Swap] +17% to Cold Resistance", 1, true))
			assert.is_truthy(previewText:find("[Swap] +24% to Lightning Resistance", 1, true))
			assert.is_truthy(previewText:find("Estimated after swap; rolls may change.", 1, true))
			assert.is_nil(previewText:find("[Swap] +30 to Strength", 1, true))
			assert.is_nil(previewText:find("[Swap] +17% to Fire Resistance", 1, true))
			assert.are.equal(itemString, tq.resultTbl[1][1].item_string)
		end)
	end)
	describe("GetResultEvaluation", function()
		it("uses the first visible ring for a Pearl result without a selected slot", function()
			local tq = new("TradeQuery"):TradeQuery({ itemsTab = {} })
			tq.statSortSelectionList = {}
			tq.tradeQueryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
			tq.itemsTab.slots = {
				["Ring 1"] = { slotName = "Ring 1", shown = function() return false end },
				["Ring 2"] = { slotName = "Ring 2", shown = function() return true end },
			}
			tq.slotTables[1] = { slotName = "Pearl of Tsoatha", unique = true }
			tq.resultTbl[1] = {
				[1] = { item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring" },
			}
			local evaluatedSlot

			tq:GetResultEvaluation(1, 1, function(override)
				evaluatedSlot = override.repSlotName
				return {}
			end, {})

			assert.are.equal("Ring 2", evaluatedSlot)
			assert.are.equal("Ring 2", tq.slotTables[1].selectedSlotName)
		end)

		it("evaluates a socketed Megalomaniac by node combination", function()
			local slotTbl = {
				slotName = "Megalomaniac", unique = true, alreadyCorrupted = true, selectedJewelNodeId = 12345,
			}
			local tq = new("TradeQuery"):TradeQuery({ itemsTab = {} })
			tq.statSortSelectionList = {}
			tq.tradeQueryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
			tq.itemsTab.build = {
				spec = {
					tree = {
						clusterNodeMap = {
							["Node One"] = { dn = "Node One" },
							["Node Two"] = { dn = "Node Two" },
							["Node Three"] = { dn = "Node Three" },
						}
					}
				}
			}
			tq.slotTables[1] = slotTbl
			tq.resultTbl[1] = {
				[1] = {
					item_string = table.concat({
						"1 Added Passive Skill is Node One",
						"1 Added Passive Skill is Node Two",
						"1 Added Passive Skill is Node Three",
					}, "\n")
				}
			}

			local evaluation = tq:GetResultEvaluation(1, 1, function() return {} end, {})

			assert.are.equal(4, #evaluation)
			for _, entry in ipairs(evaluation) do
				assert.is_table(entry.DNs)
				assert.is_true(#entry.DNs >= 2)
			end
		end)
	end)
	describe("ReduceOutput", function()
		it("preserves lower-is-better values for weighted result comparison", function()
			local weights = {
				{ stat = "PhysicalTakenHit", weightMult = 1, transform = function(value) return -value end },
			}
			mock_tradeQuery.statSortSelectionList = weights

			local baseOutput = { PhysicalTakenHit = 100 }
			local betterOutput = mock_tradeQuery:ReduceOutput({ PhysicalTakenHit = 80 })
			local worseOutput = mock_tradeQuery:ReduceOutput({ PhysicalTakenHit = 120 })
			local betterWeight = mock_queryGen.WeightedRatioOutputs(baseOutput, betterOutput, weights)
			local worseWeight = mock_queryGen.WeightedRatioOutputs(baseOutput, worseOutput, weights)

			assert.are.equal(80, betterOutput.PhysicalTakenHit)
			assert.is_true(betterWeight > worseWeight)
		end)

		it("uses selected minion stats for weighted result comparison", function()
			mock_tradeQuery.statSortSelectionList = { { stat = "AverageDamage" } }

			local result = mock_tradeQuery:ReduceOutput({
				AverageDamage = 10,
				Life = 100,
				Minion = {
					AverageDamage = 250,
					Life = 200,
				},
			})

			assert.are.equals(260, result.AverageDamage)
			assert.is_nil(result.Life)
		end)

		it("keeps fallback DPS stats when FullDPS is selected but not present", function()
			mock_tradeQuery.statSortSelectionList = { { stat = "FullDPS", weightMult = 1 } }

			local baseOutput = {
				CombinedDPS = 100,
				TotalDPS = 100,
				TotalDotDPS = 0,
			}
			local reducedOutput = mock_tradeQuery:ReduceOutput({
				CombinedDPS = 120,
				TotalDPS = 120,
				TotalDotDPS = 0,
			})

			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, reducedOutput,
				mock_tradeQuery.statSortSelectionList)

			assert.are.equals(1.2, result)
		end)
	end)

	describe("exact listing query", function()
		it("keeps the existing weight range narrowing for weighted queries", function()
			local query = require("dkjson").encode({
				query = { stats = { { type = "weight", value = { min = 10 }, filters = {} } }, filters = {} },
			})
			local exact = require("dkjson").decode(mock_tradeQuery:BuildExactListingQuery(query, {
				trader = "WeightSeller",
				weight = "172",
			}))

			assert.are.equal(171, exact.query.stats[1].value.min)
			assert.are.equal(173, exact.query.stats[1].value.max)
		end)

		it("preserves an AND-only resistance query and adds the trader account", function()
			local query = require("dkjson").encode({
				query = {
					stats = { {
						type = "and",
						filters = { { id = "pseudo.pseudo_total_fire_resistance", value = { min = 40 } } },
					} },
					filters = {},
				},
			})
			local exact = require("dkjson").decode(mock_tradeQuery:BuildExactListingQuery(query, {
				trader = "CapSeller",
				weight = "0",
			}))

			assert.are.equal("and", exact.query.stats[1].type)
			assert.is_nil(exact.query.stats[1].value)
			assert.are.equal(40, exact.query.stats[1].filters[1].value.min)
			assert.are.equal("CapSeller", exact.query.filters.trade_filters.filters.account.input)
		end)
	end)

	describe("generated query routing", function()
		it("uses the plain search path for caps and weight adjustment otherwise", function()
			local calls = {}
			mock_tradeQuery.pbRealm = "pc"
			mock_tradeQuery.pbLeague = "Standard"
			mock_tradeQuery.tradeQueryRequests = {
				SearchWithQuery = function(_, realm, league, query)
					table.insert(calls, { "plain", realm, league, query })
				end,
				SearchWithQueryWeightAdjusted = function(_, realm, league, query)
					table.insert(calls, { "adjusted", realm, league, query })
				end,
			}

			mock_tradeQuery:SearchGeneratedQuery({ weightAdjustedSearch = false }, "caps-query", function() end, {})
			mock_tradeQuery:SearchGeneratedQuery({ weightAdjustedSearch = true }, "weighted-query", function() end, {})

			assert.are.same({
				{ "plain", "pc", "Standard", "caps-query" },
				{ "adjusted", "pc", "Standard", "weighted-query" },
			}, calls)
		end)
	end)

	describe("resistance swap result evaluation", function()
		local function itemString(lines)
			return "Rarity: RARE\nTest Ring\nCoral Ring\nImplicits: 0\n" .. table.concat(lines, "\n")
		end

		local function descriptor(lineIndex, element, domain)
			return {
				lineIndex = lineIndex,
				element = element,
				domain = domain or "explicit",
				tier = "S1",
				range = { min = 1, max = 48 },
			}
		end

		local function newEvaluationQuery(lines, descriptors, enabled, capsRequired)
			local tq = new("TradeQuery", { itemsTab = {} })
			tq.tradeQueryGenerator = mock_queryGen
			tq.slotTables[1] = { slotName = "Ring 1" }
			tq.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tq.resultTbl[1] = { {
				item_string = itemString(lines),
				resistanceSwapDescriptors = descriptors,
				resistanceSwapEnabled = enabled,
				resistanceCapsRequired = capsRequired,
			} }
			return tq
		end

		local function scoreFromElements(multipliers, onEvaluation)
			return function(args)
				local score = 0
				local seen = {}
				for _, modLine in ipairs(args.repItem.explicitModLines) do
					local value, element = modLine.line:match("^%+(%d+)%% to (%a+) Resistance$")
					if value and multipliers[element] then
						assert.is_nil(seen[element], "duplicate resistance target " .. element)
						seen[element] = true
						score = score + tonumber(value) * multipliers[element]
					end
				end
				if onEvaluation then
					onEvaluation()
				end
				return { Life = 100 + score }
			end
		end

		local function scoreAndCapsFromElements(requirements, multipliers)
			return function(args)
				local totals = { Fire = 0, Cold = 0, Lightning = 0, Chaos = 0 }
				local score = 0
				for _, modLine in ipairs(args.repItem.explicitModLines) do
					local value, element = modLine.line:match("^%+(%d+)%% to (%a+) Resistance$")
					if value and totals[element] then
						totals[element] = totals[element] + tonumber(value)
						score = score + tonumber(value) * ((multipliers and multipliers[element]) or 0)
					end
				end
				local output = { Life = 100 + score }
				for element, total in pairs(totals) do
					output["Missing" .. element .. "Resist"] = math.max(0, (requirements[element] or 0) - total)
				end
				return output
			end
		end

		it("uses only the listed item when it is already capped and resistance state is irrelevant", function()
			local tq = newEvaluationQuery(
				{ "+10% to Fire Resistance", "+20% to Cold Resistance" },
				{ descriptor(1, "Fire"), descriptor(2, "Cold") }, true, true)
			local calls = 0
			tq.HasResistanceSwapOutputDependency = function() return false end

			local evaluation = tq:GetResultEvaluation(1, 1, function()
				calls = calls + 1
				return {
					Life = 100,
					MissingFireResist = 0,
					MissingColdResist = 0,
					MissingLightningResist = 0,
					MissingChaosResist = 0,
				}
			end, { Life = 100 })

			assert.are.equal(1, calls)
			assert.are.equal(1, #evaluation)
			assert.is_nil(evaluation[1].theoreticalResistanceSwap)
		end)

		it("only evaluates swaps that can feed an elemental resistance deficit", function()
			local tq = newEvaluationQuery(
				{ "+10% to Fire Resistance" }, { descriptor(1, "Fire") }, true, true)
			local calls = 0
			tq.HasResistanceSwapOutputDependency = function() return false end

			local evaluation = tq:GetResultEvaluation(1, 1, function(args)
				calls = calls + 1
				return scoreAndCapsFromElements(
					{ Fire = 0, Cold = 10, Lightning = 0, Chaos = 0 })(args)
			end, { Life = 100 })

			assert.are.equal(2, calls)
			assert.are.equal(1, #evaluation)
			assert.are.equal("Cold", evaluation[1].theoreticalResistanceSwap[1].to)
		end)

		it("keeps resistance swaps when the build depends on resistance state", function()
			local tq = newEvaluationQuery(
				{ "+10% to Fire Resistance", "+20% to Cold Resistance" },
				{ descriptor(1, "Fire"), descriptor(2, "Cold") }, true, true)
			local calls = 0
			local calc = scoreAndCapsFromElements({ Fire = 0, Cold = 0, Lightning = 0, Chaos = 0 },
				{ Fire = 1, Cold = 2, Lightning = 3 })
			tq.HasResistanceSwapOutputDependency = function() return true end

			tq:GetResultEvaluation(1, 1, function(args)
				calls = calls + 1
				return calc(args)
			end, { Life = 100 })

			assert.are.equal(6, calls)
		end)

		it("detects direct and modifier-based resistance output dependencies", function()
			local tq = newEvaluationQuery({ "+10% to Fire Resistance" }, { descriptor(1, "Fire") }, true, true)
			tq.itemsTab.build = { calcsTab = { mainEnv = { player = {
				modDB = { mods = { } },
			} } } }

			assert.is_false(tq:HasResistanceSwapOutputDependency())
			assert.is_true(tq:HasResistanceSwapOutputDependency({ modList = { {
				name = "FirePenIncreasedByUncappedFireRes",
				type = "FLAG",
			} } }))
			assert.is_true(tq:HasResistanceSwapOutputDependency({ modList = { {
				name = "DamageIncreasedByOvercappedColdRes",
				type = "FLAG",
			} } }))

			tq.statSortSelectionList = { { stat = "FireResistTotal", weightMult = 1 } }
			assert.is_true(tq:HasResistanceSwapOutputDependency())

			tq.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tq.itemsTab.build.calcsTab.mainEnv.player.modDB.mods.LifeRegen = { {
				name = "LifeRegen",
				type = "BASE",
				[1] = { type = "PerStat", stat = "FireResistTotal" },
			} }
			assert.is_true(tq:HasResistanceSwapOutputDependency())

			tq.itemsTab.build.calcsTab.mainEnv.player.modDB.mods = {
				FirePenIncreasedByUncappedFireRes = { {
					name = "FirePenIncreasedByUncappedFireRes",
					type = "FLAG",
				} },
			}
			assert.is_true(tq:HasResistanceSwapOutputDependency())
		end)

		it("evaluates exactly 3, 6, and 6 distinct-target assignments for one to three candidates", function()
			local cases = {
				{
					lines = { "+5 to Strength", "{crafted}+10% to Fire Resistance" },
					descriptors = { descriptor(2, "Fire", "crafted") },
					expectedCalls = 3,
				},
				{
					lines = { "+10% to Fire Resistance", "+20% to Cold Resistance" },
					descriptors = { descriptor(1, "Fire"), descriptor(2, "Cold") },
					expectedCalls = 6,
				},
				{
					lines = { "+10% to Fire Resistance", "+20% to Cold Resistance", "+30% to Lightning Resistance" },
					descriptors = { descriptor(1, "Fire"), descriptor(2, "Cold"), descriptor(3, "Lightning") },
					expectedCalls = 6,
				},
			}
			for _, case in ipairs(cases) do
				local calls = 0
				local tq = newEvaluationQuery(case.lines, case.descriptors, true)
				local evaluation = tq:GetResultEvaluation(1, 1,
					scoreFromElements({ Fire = 1, Cold = 2, Lightning = 3 }, function() calls = calls + 1 end),
					{ Life = 100 })

				assert.are.equal(case.expectedCalls, calls)
				assert.are.equal(1, #evaluation)
			end
		end)

		it("provides a cooperative yield point after each calculated assignment", function()
			local calls = 0
			local yields = 0
			local tq = newEvaluationQuery(
				{ "+10% to Fire Resistance", "+20% to Cold Resistance" },
				{ descriptor(1, "Fire"), descriptor(2, "Cold") }, true)

			tq:GetResultEvaluation(1, 1,
				scoreFromElements({ Fire = 1, Cold = 2, Lightning = 3 }, function() calls = calls + 1 end),
				{ Life = 100 },
				function() yields = yields + 1 end)

			assert.are.equal(6, calls)
			assert.are.equal(calls, yields)
		end)

		it("selects the best permutation and leaves the listed item unchanged", function()
			local tq = newEvaluationQuery(
				{ "+10% to Fire Resistance", "+20% to Cold Resistance" },
				{ descriptor(1, "Fire"), descriptor(2, "Cold") }, true)
			local original = tq.resultTbl[1][1].item_string

			local evaluation = tq:GetResultEvaluation(1, 1,
				scoreFromElements({ Fire = 1, Cold = 2, Lightning = 4 }), { Life = 100 })
			local swaps = evaluation[1].theoreticalResistanceSwap

			assert.are.equal(2, #swaps)
			assert.are.same({ from = "Fire", to = "Cold", value = 10 }, swaps[1])
			assert.are.same({ from = "Cold", to = "Lightning", value = 20 }, swaps[2])
			assert.are.same({ 1, 2 }, evaluation[1].theoreticalResistanceSwapLineIndexes)
			assert.is_truthy(evaluation[1].theoreticalResistanceSwapItemString:find("+10%% to Cold Resistance"))
			assert.is_truthy(evaluation[1].theoreticalResistanceSwapItemString:find("+20%% to Lightning Resistance"))
			assert.are.equal(original, tq.resultTbl[1][1].item_string)
		end)

		it("prefers fewer swaps when theoretical weights tie", function()
			local tq = newEvaluationQuery(
				{ "+10% to Cold Resistance" }, { descriptor(1, "Cold") }, true)

			local evaluation = tq:GetResultEvaluation(1, 1, function()
				return { Life = 100 }
			end, { Life = 100 })

			assert.is_nil(evaluation[1].theoreticalResistanceSwap)
		end)

		it("uses one baseline calculation when reranking is disabled or ineligible", function()
			local cases = {
				newEvaluationQuery({ "+10% to Fire Resistance" }, { descriptor(1, "Fire") }, false),
				newEvaluationQuery({ "+10% to Fire Resistance" }, { descriptor(1, "Cold") }, true),
				newEvaluationQuery({ "+10% to Fire Resistance" }, nil, true),
			}
			for _, tq in ipairs(cases) do
				local calls = 0
				tq:GetResultEvaluation(1, 1, function()
					calls = calls + 1
					return { Life = 100 }
				end, { Life = 100 })
				assert.are.equal(1, calls)
			end
		end)

		it("keeps only swap permutations that actually reach every resistance cap", function()
			local tq = newEvaluationQuery(
				{ "+40% to Fire Resistance", "+80% to Cold Resistance", "+30% to Chaos Resistance" },
				{ descriptor(1, "Fire"), descriptor(2, "Cold") }, true, true)
			local evaluation = tq:GetResultEvaluation(1, 1, scoreAndCapsFromElements(
				{ Fire = 40, Cold = 40, Lightning = 0, Chaos = 30 },
				{ Fire = 1, Cold = 1, Lightning = 100 }), { Life = 100 })

			assert.are.equal(1, #evaluation)
			assert.is_nil(evaluation[1].theoreticalResistanceSwap)
		end)

		it("retains the best partial assignment when the elemental total cannot reach every cap", function()
			local tq = newEvaluationQuery(
				{ "+80% to Fire Resistance", "+30% to Chaos Resistance" },
				{ descriptor(1, "Fire") }, true, true)
			local evaluation = tq:GetResultEvaluation(1, 1, scoreAndCapsFromElements(
				{ Fire = 40, Cold = 40, Lightning = 0, Chaos = 30 }), { Life = 100 })

			assert.are.equal(1, #evaluation)
			assert.are.equal(40, evaluation[1].resistanceCapShortfall)
		end)

		it("records cap shortfall without dropping items when swaps are disabled", function()
			local valid = newEvaluationQuery(
				{ "+40% to Fire Resistance", "+30% to Chaos Resistance" }, nil, false, true)
			local invalid = newEvaluationQuery(
				{ "+39% to Fire Resistance", "+30% to Chaos Resistance" }, nil, false, true)
			local calc = scoreAndCapsFromElements({ Fire = 40, Cold = 0, Lightning = 0, Chaos = 30 })

			assert.are.equal(1, #valid:GetResultEvaluation(1, 1, calc, { Life = 100 }))
			local invalidEvaluation = invalid:GetResultEvaluation(1, 1, calc, { Life = 100 })
			assert.are.equal(1, #invalidEvaluation)
			assert.are.equal(1, invalidEvaluation[1].resistanceCapShortfall)
		end)

		it("retains an item that only misses the requested Chaos resistance", function()
			local tq = newEvaluationQuery(
				{ "+40% to Fire Resistance", "+29% to Chaos Resistance" }, nil, false, true)
			local evaluation = tq:GetResultEvaluation(1, 1,
				scoreAndCapsFromElements({ Fire = 40, Cold = 0, Lightning = 0, Chaos = 30 }), { Life = 100 })

			assert.are.equal(1, #evaluation)
			assert.are.equal(1, evaluation[1].resistanceCapShortfall)
		end)

		it("sorts retained capped and uncapped results by requested stat value", function()
			local tq = new("TradeQuery", { itemsTab = {} })
			tq.resultTbl[1] = {
				{ id = "uncapped", resistanceCapsRequired = true },
				{ id = "capped", resistanceCapsRequired = true },
				{ id = "unrestricted" },
			}
			tq.sortModes = { StatValue = "statValue" }
			tq.itemsTab.build = { calcsTab = { GetMiscCalculator = function()
				return function() return { } end, { }
			end } }
			tq.GetResultEvaluation = function(_, _, resultIndex)
				return { { weight = 4 - resultIndex, resistanceCapShortfall = resultIndex == 1 and 10 or 0 } }
			end

			local sorted = tq:SortFetchResults(1, tq.sortModes.StatValue)

			assert.are.same({ "uncapped", "capped", "unrestricted" }, {
				tq.resultTbl[1][sorted[1].index].id,
				tq.resultTbl[1][sorted[2].index].id,
				tq.resultTbl[1][sorted[3].index].id,
			})
		end)

		it("revalidates and restores fetched results when the build resistance state changes", function()
			local requiredFire = 50
			local tq = newEvaluationQuery(
				{ "+40% to Fire Resistance", "+30% to Chaos Resistance" }, nil, false, true)
			local itemEntry = tq.resultTbl[1][1]
			tq.unfilteredResultTbl[1] = { itemEntry }
			local function calc(args)
				return scoreAndCapsFromElements({
					Fire = requiredFire,
					Cold = 0,
					Lightning = 0,
					Chaos = 30,
				})(args)
			end
			tq.itemsTab.build = { calcsTab = {
				GetMiscCalculator = function()
					return calc, {
						Life = 100,
						FireResist = 75,
						FireResistTotal = requiredFire,
						MissingFireResist = 0,
						ColdResist = 75,
						ColdResistTotal = 75,
						MissingColdResist = 0,
						LightningResist = 75,
						LightningResistTotal = 75,
						MissingLightningResist = 0,
						ChaosResist = 75,
						ChaosResistTotal = 75,
						MissingChaosResist = 0,
					}
				end,
			} }

			local first = tq:GetResultEvaluation(1, 1)
			assert.are.equal(1, #first)
			assert.are.equal(10, first[1].resistanceCapShortfall)

			requiredFire = 40
			local second = tq:GetResultEvaluation(1, 1)
			assert.are.equal(1, #second)
			assert.are.equal(0, second[1].resistanceCapShortfall)
		end)

		it("reuses the single best evaluation while the build and weights are unchanged", function()
			local calls = 0
			local tq = newEvaluationQuery({ "+10% to Fire Resistance" }, { descriptor(1, "Fire") }, true)
			local calc = scoreFromElements({ Fire = 1, Cold = 2, Lightning = 3 }, function() calls = calls + 1 end)
			tq.itemsTab.build = { calcsTab = {
				GetMiscCalculator = function()
					return calc, { Life = 100 }
				end,
			} }

			local first = tq:GetResultEvaluation(1, 1)
			local second = tq:GetResultEvaluation(1, 1)

			assert.are.equal(3, calls)
			assert.are.equal(first, second)
			assert.are.equal(1, #second)
		end)

		it("reuses the cached evaluation when sorting supplies a shared calculator", function()
			local calls = 0
			local tq = newEvaluationQuery({ "+10% to Fire Resistance" }, { descriptor(1, "Fire") }, true)
			local calc = scoreFromElements({ Fire = 1, Cold = 2, Lightning = 3 }, function() calls = calls + 1 end)
			local baseOutput = { Life = 100 }
			tq.itemsTab.build = { calcsTab = {
				GetMiscCalculator = function()
					return calc, baseOutput
				end,
			} }

			local first = tq:GetResultEvaluation(1, 1)
			local second = tq:GetResultEvaluation(1, 1, calc, baseOutput)

			assert.are.equal(3, calls)
			assert.are.equal(first, second)
		end)
	end)
end)
