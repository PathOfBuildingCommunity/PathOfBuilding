describe("TradeQuery", function()
	local mock_tradeQuery
	local mock_queryGen

	before_each(function()
		mock_tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
		mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
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

		it("returns early from action button tooltips when filtering clears the selected result", function()
			local tq = newTradeQuery({
				resultTbl       = { [1] = { [1] = { item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring", amount = 1, currency = "chaos" } } },
				sortedResultTbl = { [1] = {} },
			})
			buildRow1Dropdown(tq)
			local tooltip = new("Tooltip")

			assert.has_no.errors(function()
				tq.controls.importButton1.tooltipFunc(tooltip)
				tq.controls.whisperButton1.tooltipFunc(tooltip)
			end)
			assert.are.equal(0, #tooltip.lines)
		end)
	end)

	describe("attribute requirement result filtering", function()
		local function newTradeQueryWithOutput(output, slotTbl)
			local calcCalls = 0
			local tq = new("TradeQuery", { itemsTab = {} })
			tq.slotTables[1] = slotTbl or { slotName = "Ring 1" }
			tq.resultTbl = {
				[1] = {
					[1] = { item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring", amount = 1, currency = "chaos" },
				},
			}
			tq.sortModes = {
				Weight = "(Highest) Weighted Sum",
			}
			tq.itemsTab.build = {
				calcsTab = {
					GetMiscCalculator = function()
						return function()
							calcCalls = calcCalls + 1
							return output
						end, {}
					end,
				},
			}
			tq.itemsTab.slots = {
				["Ring 1"] = {},
			}
			return tq, function()
				return calcCalls
			end
		end

		it("filters fetched results that do not meet attribute requirements", function()
			local tq = newTradeQueryWithOutput({ ReqStr = 50, Str = 40, ReqDex = 0, Dex = 0, ReqInt = 0, Int = 0 })
			tq.hideResultsFailingAttributeRequirements = true
			local sortedItems = tq:SortFetchResults(1, tq.sortModes.Weight)
			assert.are.equal(0, #sortedItems)
		end)

		it("keeps fetched results that meet attribute requirements", function()
			local tq = newTradeQueryWithOutput({ ReqStr = 50, Str = 60, ReqDex = 30, Dex = 30, ReqInt = 20, Int = 25 })
			tq.hideResultsFailingAttributeRequirements = true
			local sortedItems = tq:SortFetchResults(1, tq.sortModes.Weight)
			assert.are.equal(1, #sortedItems)
			assert.are.equal(1, sortedItems[1].index)
		end)

		it("filters fetched results that do not meet Omniscience requirements", function()
			local tq = newTradeQueryWithOutput({ ReqOmni = 100, Omni = 80 })
			tq.hideResultsFailingAttributeRequirements = true
			local sortedItems = tq:SortFetchResults(1, tq.sortModes.Weight)
			assert.are.equal(0, #sortedItems)
		end)

		it("keeps fetched results without recalculating by default", function()
			local tq, calcCalls = newTradeQueryWithOutput({ ReqStr = 50, Str = 40, ReqDex = 0, Dex = 0, ReqInt = 0, Int = 0 })
			local sortedItems = tq:SortFetchResults(1, tq.sortModes.Weight)
			assert.are.equal(1, #sortedItems)
			assert.are.equal(1, sortedItems[1].index)
			assert.are.equal(0, calcCalls())
		end)

		it("does not apply equipment attribute filtering to rows without a replacement slot", function()
			local tq, calcCalls = newTradeQueryWithOutput({ ReqStr = 50, Str = 40, ReqDex = 0, Dex = 0, ReqInt = 0, Int = 0 }, { slotName = "Megalomaniac", unique = true })
			tq.hideResultsFailingAttributeRequirements = true
			local sortedItems = tq:SortFetchResults(1, tq.sortModes.Weight)
			assert.are.equal(1, #sortedItems)
			assert.are.equal(1, sortedItems[1].index)
			assert.are.equal(0, calcCalls())
		end)
	end)
	describe("trade search links", function()
		local dkjson = require "dkjson"
		local tradeHelpers = require "Classes.TradeHelpers"
		local originalEncode, originalCopy, originalOpenURL, originalToken
		local encodedQuery, copiedUrl, openedUrl
		local generatedQuery = { stats = { { type = "weight", value = { min = 10 }, filters = {} } } }

		before_each(function()
			originalEncode, originalCopy, originalOpenURL, originalToken = tradeHelpers.B64GzipEncode, _G.Copy, _G.OpenURL, main.api.authToken
			tradeHelpers.B64GzipEncode = function(json)
				encodedQuery = dkjson.decode(json)
				return "encoded"
			end
			_G.Copy = function(url) copiedUrl = url end
			_G.OpenURL = function(url) openedUrl = url end
			encodedQuery, copiedUrl, openedUrl = nil, nil, nil
			mock_tradeQuery.itemsTab.activeItemSet = {}
			mock_tradeQuery.itemsTab.slots = {}
			mock_tradeQuery.slotTables[1] = { slotName = "Ring 1" }
			mock_tradeQuery.controls.pbNotice = {}
			mock_tradeQuery:PriceItemRowDisplay(1, nil, 0, 20)
			mock_tradeQuery.pbRealm = "sony"
			mock_tradeQuery.pbLeague = "Hardcore Test"
			mock_tradeQuery.tradeQueryGenerator = {
				RequestQuery = function(_, slot, context, weights, callback)
					callback(context, copyTable(generatedQuery, true))
				end,
			}
		end)

		after_each(function()
			tradeHelpers.B64GzipEncode, _G.Copy, _G.OpenURL, main.api.authToken = originalEncode, originalCopy, originalOpenURL, originalToken
		end)

		it("creates an unauthenticated search link from the generated query", function()
			main.api.authToken = nil
			mock_tradeQuery.controls.bestButton1.onClick()
			assert.same(generatedQuery, encodedQuery)
			assert.are.equal("https://www.pathofexile.com/trade/search/sony/Hardcore%20Test/encoded", mock_tradeQuery.controls.uri1.buf)
			assert.is_true(mock_tradeQuery.controls.uri1.validURL)
			assert.are.equal(0, #mock_tradeQuery.tradeQueryRequests.requestQueue.search)
		end)

		it("posts generated queries with weighted sorting and keeps the adjusted query", function()
			main.api.authToken = "test-token"
			-- Complete two searches through the real request flow, without fetching items.
			mock_tradeQuery.tradeQueryRequests.FetchResults = function(_, ids, queryId, callback) callback({}) end
			mock_tradeQuery.UpdateControlsWithItems = function() end
			mock_tradeQuery.controls.bestButton1.onClick()
			local requests = mock_tradeQuery.tradeQueryRequests.requestQueue.search
			local firstSearch = table.remove(requests, 1)
			assert.are.equal("https://www.pathofexile.com/api/trade/search/sony/Hardcore%20Test", firstSearch.url)
			assert.same({ query = generatedQuery, sort = { ["statgroup.0"] = "desc" }, engine = "new" }, dkjson.decode(firstSearch.body))
			firstSearch.callback([[{"id":"first","total":1,"result":["item1"]}]])
			local finalSearch = table.remove(requests, 1)
			assert.are.equal(5, dkjson.decode(finalSearch.body).query.stats[1].value.min)
			finalSearch.callback([[{"id":"final","total":10,"result":["item1"]}]])
			assert.are.equal(finalSearch.body, mock_tradeQuery.lastQueries[1])
			assert.are.equal("https://www.pathofexile.com/trade/search/sony/Hardcore%20Test/final", mock_tradeQuery.controls.uri1.buf)
			assert.are.equal("Price Item", mock_tradeQuery.controls.priceButton1.label)
		end)

		for _, group in ipairs({
			{ type = "and", filters = {} },
			{ type = "count", value = { min = 1 }, filters = {} },
			{ type = "weight", value = { min = 10 }, filters = {} },
		}) do
			it("preserves " .. group.type .. " group semantics in purchase links", function()
				mock_tradeQuery.itemIndexTbl[1] = 1
				mock_tradeQuery.resultTbl[1] = { { trader = "ExampleAccount", weight = "100", priceType = "~b/o" } }
				mock_tradeQuery.lastQueries[1] = dkjson.encode({ query = { stats = { group } } })
				mock_tradeQuery.controls.whisperButton1.onClick()
				if group.type == "weight" then
					assert.same({ min = 99, max = 101 }, encodedQuery.stats[1].value)
				else
					assert.same(group, encodedQuery.stats[1])
				end
				assert.same({ input = "ExampleAccount" }, encodedQuery.filters.trade_filters.filters.account)
				assert.are.equal("https://www.pathofexile.com/trade/search/sony/Hardcore%20Test/encoded", openedUrl)
				assert.are.equal(openedUrl, copiedUrl)
			end)
		end
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
end)
