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
			tq.itemsTab.GetVisibleItemSet = function(itemsTab) return itemsTab.activeItemSet end
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

		it("imports a result into the visible item set slot", function()
			local visibleItemSet = { Helmet = { selItemId = 0 } }
			local currentVisibleItemSet = visibleItemSet
			local helmetSlot = {
				slotName = "Helmet",
				label = "Helmet",
				selItemId = 0,
				IsShown = function() return true end,
				SetSelItemId = function(self, itemId, itemSet)
					self.selItemId = itemId
					itemSet[self.slotName].selItemId = itemId
				end,
			}
			local tq = newTradeQuery({
				resultTbl = { [1] = { [1] = { item_string = "Rarity: NORMAL\nIron Hat", amount = 1, currency = "chaos" } } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.viewItemSet = visibleItemSet
			tq.itemsTab.GetVisibleItemSet = function() return currentVisibleItemSet end
			tq.itemsTab.slots = { [helmetSlot.slotName] = helmetSlot }
			tq.itemsTab.IsItemValidForSlot = function() return true end
			tq.itemsTab.CreateDisplayItemFromRaw = function(itemsTab) itemsTab.displayItem = { id = 77 } end
			tq.itemsTab.AddDisplayItem = function() end
			tq.itemsTab.PopulateSlots = function() end
			tq.itemsTab.AddUndoState = function() end
			tq.itemsTab.build = { buildFlag = false }
			tq.slotTables[1] = { slotName = helmetSlot.slotName }
			tq.itemIndexTbl[1] = 1

			buildRow1Dropdown(tq)
			local nextVisibleItemSet = { Helmet = { selItemId = 0 } }
			currentVisibleItemSet = nextVisibleItemSet
			tq.controls.importButton1:Click()

			assert.are.equal(77, helmetSlot.selItemId)
			assert.are.equal(0, visibleItemSet.Helmet.selItemId)
			assert.are.equal(77, nextVisibleItemSet.Helmet.selItemId)
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
		it("weights Mercenary slots against Mercenary output", function()
			mock_tradeQuery.tradeQueryGenerator = mock_queryGen
			mock_tradeQuery.itemsTab.build = { calcsTab = { GetMiscCalculator = function()
				return function() return { Life = 200 } end, { Life = 10 }, {
					PLAYER = { Life = 10 },
					MERCENARY = { Life = 100 },
				}
			end } }
			mock_tradeQuery.slotTables[1] = { slotName = "Mercenary Helmet" }
			mock_tradeQuery.resultTbl[1] = { { item_string = "Rarity: NORMAL\nIron Hat" } }
			mock_tradeQuery.statSortSelectionList = { { stat = "Life", weightMult = 1 } }

			local evaluation = mock_tradeQuery:GetResultEvaluation(1, 1)
			assert.are.equal(2, evaluation[1].weight)

			mock_tradeQuery.itemsTab.build = { calcsTab = { GetMiscCalculator = function()
				return function() return { Life = 200 } end, { Life = 10 }, {
					PLAYER = { Life = 10 },
				}
			end } }
			evaluation = mock_tradeQuery:GetResultEvaluation(1, 1)
			assert.same({ }, evaluation)
		end)
	end)
	describe("PriceItem slot rows", function()
		it("only includes slots shown by the visible item set", function()
			newBuild()
			local itemsTab = build.itemsTab
			local tradeQuery = itemsTab.tradeQuery
			local originalOpenPopup = main.OpenPopup
			local originalUpdateRealms = tradeQuery.UpdateRealms
			local originalPullCXData = tradeQuery.PullCXData
			local ok, err

			itemsTab.activeItemSet.useSecondWeaponSet = false
			itemsTab.build.spec.treeVersion = "3_26"
			itemsTab.build.calcsTab.mainEnv = { modDB = { Flag = function() return false end } }
			tradeQuery.pbRealm = "pc"
			tradeQuery.UpdateRealms = function() end
			tradeQuery.PullCXData = function() end
			main.OpenPopup = function() end
			ok, err = pcall(function() tradeQuery:PriceItem() end)

			main.OpenPopup = originalOpenPopup
			tradeQuery.UpdateRealms = originalUpdateRealms
			tradeQuery.PullCXData = originalPullCXData
			assert.is_true(ok, err)

			local slotNames = { }
			for _, slotTable in ipairs(tradeQuery.slotTables) do
				if not slotTable.unique and not slotTable.nodeId then
					slotNames[slotTable.slotName] = true
				end
			end
			assert.is_true(slotNames["Weapon 1"])
			assert.is_nil(slotNames["Weapon 1 Swap"])
			assert.is_nil(slotNames["Weapon 2 Swap"])
			assert.is_nil(slotNames["Ring 3"])
			assert.is_nil(slotNames["Graft 1"])
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
