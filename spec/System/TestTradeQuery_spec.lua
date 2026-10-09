describe("TradeQuery", function()
	local mock_tradeQuery
	local mock_queryGen

	local function newTradeQuery(state)
		local tq = new("TradeQuery"):TradeQuery({ activeItemSet = {}, slots = {}, sockets = {} })
		tq.slotTables[1] = { slotName = "Ring 1" }
		tq.resultTbl = state.resultTbl or {}
		tq.sortedResultTbl = state.sortedResultTbl or {}
		return tq
	end

	local function buildRow1Dropdown(tq)
		tq:PriceItemRowDisplay(1, nil, 0, 20)
		return tq.controls.resultDropdown1
	end

	before_each(function()
		mock_tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
		mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
	end)
	describe("result dropdown tooltipFunc", function()
		it("constructs the Watcher's Eye row without an active jewel socket", function()
			local tq = newTradeQuery({})
			tq.slotTables[1] = { slotName = "Watcher's Eye", unique = true }

			assert.has_no.errors(function()
				buildRow1Dropdown(tq)
			end)
		end)

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
	end)
	describe("replacement slot resolution", function()
		it("resolves normal, Abyssal, and selected jewel slots without stored row state", function()
			local tq = newTradeQuery({})
			tq.itemsTab.slots = {
				["Ring 1"] = {},
				["Body Armour Abyssal Socket 1"] = {},
			}
			tq.itemsTab.sockets = { [123] = {} }
			tq.slotTables = {
				{ slotName = "Ring 1" },
				{ slotName = "Abyssal Socket 1", fullName = "Body Armour Abyssal Socket 1" },
				{ slotName = "Jewel Socket", selectedJewelNodeId = 123 },
				{ slotName = "Watcher's Eye", unique = true },
			}

			assert.are.equal("Ring 1", tq:GetReplacementSlotName(1))
			assert.are.equal("Body Armour Abyssal Socket 1", tq:GetReplacementSlotName(2))
			assert.are.equal("Jewel 123", tq:GetReplacementSlotName(3))
			assert.is_nil(tq:GetReplacementSlotName(4))
		end)
	end)

	describe("attribute requirement result filtering", function()
		local function newTradeQueryWithOutput(output, slotTbl)
			local calcCalls = 0
			local tq = newTradeQuery({})
			tq.slotTables[1] = slotTbl or { slotName = "Ring 1" }
			tq.resultTbl = {
				[1] = {
					[1] = { item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring", amount = 1, currency = "chaos" },
				},
			}
			tq.sortModes = {
				Weight = "Weight", StatValue = "StatValue", StatValuePrice = "StatValuePrice", Price = "Price",
			}
			tq.itemSortSelectionList = { tq.sortModes.Weight }
			tq.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tq.tradeQueryGenerator = mock_queryGen
			tq.pbLeague = "Test League"
			tq.pbCurrencyConversion = { [tq.pbRealm] = { [tq.pbLeague] = { chaos = 1 } } }
			tq.itemsTab.build = {
				calcsTab = {
					GetMiscCalculator = function()
						return function(calcArgs)
							calcCalls = calcCalls + 1
							return type(output) == "function" and output(calcArgs) or output
						end, { Life = 100 }
					end,
				},
			}
			tq.itemsTab.slots = {
				["Ring 1"] = {},
			}
			return tq, function() return calcCalls end
		end

		for _, mode in ipairs({ "Weight", "StatValue", "StatValuePrice", "Price" }) do
			it("postfilters mixed fetched results in " .. mode .. " mode", function()
				local tq = newTradeQueryWithOutput(function(calcArgs)
					assert.are.equal("Ring 1", calcArgs.repSlotName)
					if calcArgs.repItem.name == "Behemoth Hold, Gold Ring" then
						return { ReqStr = 50, Str = 40, Life = 400 }
					end
					assert.are.equal("Survivor Hold, Gold Ring", calcArgs.repItem.name)
					return { ReqStr = 50, Str = 60, ReqDex = 30, Dex = 30, ReqInt = 20, Int = 25, Life = 120 }
				end)
				-- The rejected result arrives first, costs less, and has more Life.
				local survivor = { item_string = "Rarity: RARE\nSurvivor Hold\nGold Ring", amount = 7, currency = "chaos" }
				tq.resultTbl[1][2] = survivor
				tq.hideResultsFailingAttributeRequirements = true
				local sortedItems, err = tq:SortFetchResults(1, tq.sortModes[mode])
				assert.is_nil(err)
				assert.are.equal(1, #sortedItems)
				assert.are.equal(2, sortedItems[1].index)
				assert.are.equal(survivor, tq.resultTbl[1][sortedItems[1].index])
			end)
		end

		it("clears the visible selection and price when postfiltering removes every result", function()
			local tq = newTradeQueryWithOutput({ ReqStr = 50, Str = 40 })
			local dropdown = buildRow1Dropdown(tq)
			tq.controls.fullPrice = new("LabelControl"):LabelControl(nil, { 0, 0, 100, 20 }, "")
			tq.controls.pbNotice = new("LabelControl"):LabelControl(nil, { 0, 0, 100, 20 }, "")
			-- Populate the row through the same path first, so stale state can be detected.
			tq:UpdateControlsWithItems(1)
			assert.is_not_nil(dropdown:GetSelValue())
			assert.are.equal(1, tq.itemIndexTbl[1])
			assert.are.equal("1 chaos", tq:GetTotalPriceString())
			assert.is_true(tq.controls.importButton1:IsEnabled())
			local populatedPriceLabel = tq.controls.fullPrice.label

			tq.hideResultsFailingAttributeRequirements = true
			tq:UpdateControlsWithItems(1)
			assert.are.equal(0, dropdown:GetDropCount())
			assert.is_nil(dropdown:GetSelValue())
			assert.are.equal(0, #tq.sortedResultTbl[1])
			assert.is_nil(tq.itemIndexTbl[1])
			assert.is_nil(tq.totalPrice[1])
			assert.are.equal("", tq:GetTotalPriceString())
			assert.are_not.equal(populatedPriceLabel, tq.controls.fullPrice.label)
			assert.not_matches("chaos", tq.controls.fullPrice.label, 1, true)
			assert.matches("attribute requirements", tq.controls.pbNotice.label, 1, true)
			assert.is_falsy(tq.controls.importButton1:IsEnabled())
			assert.are.equal("", tq.controls.whisperButton1:GetProperty("label"))
			local tooltip = new("Tooltip"):Tooltip()
			for _, control in ipairs({ dropdown, tq.controls.importButton1, tq.controls.whisperButton1 }) do
				control.tooltipFunc(tooltip, "DROP", 1, nil)
				assert.are.equal(0, #tooltip.lines)
			end
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
			tq.itemsTab.sockets = { [12345] = {} }
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
