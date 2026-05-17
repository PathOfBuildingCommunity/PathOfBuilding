describe("TradeQuery", function()
	describe("result dropdown tooltipFunc", function()
		-- Builds a TradeQuery with the strict minimum needed for
		-- PriceItemRowDisplay to construct row 1 without exploding. Only the
		-- two itemsTab subtables read by the slot lookup at the top of
		-- PriceItemRowDisplay need to be created here; everything else either
		-- lives behind a callback we never trigger, or is already initialized
		-- by the TradeQuery constructor.
		local function newTradeQuery(state)
			local tq = new("TradeQuery", { itemsTab = {} })
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
			local tooltip = new("Tooltip")

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
			local tooltip = new("Tooltip")

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
			local sortedItems = tq:SortFetchResults(1, tq.sortModes.Weight)
			assert.are.equal(1, #sortedItems)
			assert.are.equal(1, sortedItems[1].index)
			assert.are.equal(0, calcCalls())
		end)
	end)
end)
