describe("TradeQuery", function()
	local mock_tradeQuery
	local mock_queryGen

	before_each(function()
		mock_tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
		mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
	end)

	local function newRowQuery(state)
		local tq = new("TradeQuery"):TradeQuery({ itemsTab = {} })
		tq.itemsTab.activeItemSet = { }
		tq.itemsTab.slots = { }
		tq.slotTables[1] = { slotName = "Ring 1" }
		tq.controls.pbNotice = { label = "" }
		if state and state.resultTbl then tq.resultTbl = state.resultTbl end
		if state and state.sortedResultTbl then tq.sortedResultTbl = state.sortedResultTbl end
		return tq
	end

	local function listedResult(itemString, evaluation, amount)
		return { item_string = itemString, evaluation = evaluation, amount = amount or 1, currency = "chaos" }
	end

	describe("cooperative result evaluation", function()
		local function newProcessingQuery(resultCounts)
			local tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
			tradeQuery.controls.priceButton1 = { label = "Price Item" }
			tradeQuery.controls.pbNotice = { label = "" }
			for rowIdx, count in ipairs(resultCounts or { }) do
				tradeQuery.resultTbl[rowIdx] = { }
				for _ = 1, count do
					table.insert(tradeQuery.resultTbl[rowIdx], { })
				end
			end
			return tradeQuery
		end

		it("resumes fetched result work over multiple frames", function()
			local tradeQuery = newProcessingQuery({ 2 })
			local events = { }
			tradeQuery.UpdateControlsWithItems = function(_, _, yieldFunc)
				table.insert(events, "first")
				yieldFunc(1, 2)
				table.insert(events, "second")
				yieldFunc(2, 2)
				table.insert(events, "done")
			end

			tradeQuery:StartResultEvaluation(1)
			local frames = {
				{ { }, "Eval 0/2..." },
				{ { "first" }, "Eval 1/2..." },
				{ { "first", "second" }, "Eval 2/2..." },
				{ { "first", "second", "done" }, "Price Item" },
			}
			for index, frame in ipairs(frames) do
				if index > 1 then tradeQuery:ProcessResultEvaluations() end
				assert.are.same(frame[1], events, "frame " .. index)
				assert.are.equal(frame[2], tradeQuery.controls.priceButton1.label, "frame " .. index)
			end
			assert.is_nil(tradeQuery.resultProcessingByRow[1])
		end)

		it("clears the prior selection before scheduling a new evaluation", function()
			local tradeQuery = newProcessingQuery({ 1 })
			local dropdownList
			tradeQuery.controls.resultDropdown1 = {
				SetList = function(_, list)
					dropdownList = list
				end,
			}
			tradeQuery.controls.fullPrice = { label = "" }
			tradeQuery.sortedResultTbl[1] = { { index = 1 } }
			tradeQuery.itemIndexTbl[1] = 1
			tradeQuery.totalPrice[1] = { amount = 1, currency = "chaos" }
			tradeQuery.UpdateControlsWithItems = function() end

			tradeQuery:StartResultEvaluation(1)

			assert.is_nil(tradeQuery.sortedResultTbl[1])
			assert.is_nil(tradeQuery.itemIndexTbl[1])
			assert.is_nil(tradeQuery.totalPrice[1])
			assert.are.same({ }, dropdownList)
			assert.are.equal("^7Total Price: ", tradeQuery.controls.fullPrice.label)
		end)

		it("does not replace an active fetch with evaluation of old results", function()
			local tradeQuery = newProcessingQuery({ 1 })
			local evaluated = false
			tradeQuery.UpdateControlsWithItems = function()
				evaluated = true
			end

			local fetchToken = tradeQuery:StartResultFetch(1)
			tradeQuery:StartResultEvaluation(1)

			assert.is_true(tradeQuery:IsResultFetchCurrent(1, fetchToken))
			assert.is_false(evaluated)
			assert.are.equal("Searching...", tradeQuery.controls.priceButton1.label)
		end)

		it("rejects a response from a superseded fetch", function()
			local tradeQuery = newProcessingQuery()

			local firstFetch = tradeQuery:StartResultFetch(1)
			local secondFetch = tradeQuery:StartResultFetch(1)

			assert.is_false(tradeQuery:FinishResultFetch(1, firstFetch))
			assert.are.equal("Searching...", tradeQuery.controls.priceButton1.label)
			assert.is_true(tradeQuery:FinishResultFetch(1, secondFetch))
			assert.are.equal("Price Item", tradeQuery.controls.priceButton1.label)
		end)

		it("publishes only the replacement of a suspended evaluation", function()
			local tradeQuery = newProcessingQuery({ 1 })
			local run = 0
			local published
			tradeQuery.UpdateControlsWithItems = function(_, _, yieldFunc)
				run = run + 1
				local currentRun = run
				yieldFunc(1, 1)
				published = currentRun
			end

			tradeQuery:StartResultEvaluation(1)
			tradeQuery:ProcessResultEvaluations()
			tradeQuery:StartResultEvaluation(1)
			tradeQuery:ProcessResultEvaluations()
			tradeQuery:ProcessResultEvaluations()

			assert.are.equal(2, published)
			assert.is_nil(tradeQuery.resultProcessingByRow[1])
		end)

		it("does not resume replaced queued work before another result row", function()
			local tradeQuery = newProcessingQuery({ 1, 1 })
			local events = { }
			tradeQuery.UpdateControlsWithItems = function(_, rowIdx, yieldFunc)
				table.insert(events, rowIdx)
				yieldFunc(1, 1)
				table.insert(events, rowIdx)
			end

			tradeQuery:StartResultEvaluation(1)
			local fetchToken = tradeQuery:StartResultFetch(1)
			assert.is_true(tradeQuery:FinishResultFetch(1, fetchToken))
			tradeQuery:StartResultEvaluation(1)
			tradeQuery:StartResultEvaluation(2)

			tradeQuery:ProcessResultEvaluations()
			tradeQuery:ProcessResultEvaluations()

			assert.are.same({ 1, 2 }, events)
		end)
	end)
	describe("result dropdown tooltipFunc", function()
		-- Builds row 1 of the trader UI and returns the dropdown that owns the
		-- tooltipFunc we want to exercise.
		local function buildRow1Dropdown(tq)
			tq:PriceItemRowDisplay(1, nil, 0, 20)
			return tq.controls.resultDropdown1
		end

		local function swapEvaluation(itemString, swaps, lineIndexes)
			return { {
				output = { },
				weight = 1,
				estimatedResistanceSwap = { swaps = swaps, itemString = itemString, lineIndexes = lineIndexes },
			} }
		end

		local function tooltipText(tooltip)
			local text = ""
			for _, line in ipairs(tooltip.lines) do
				text = text .. (line.text or "") .. "\n"
			end
			return text
		end

		it("returns early when sortedResultTbl[row_idx] is missing", function()
			-- No sorted results at all -> first guard must short-circuit.
			local tq = newRowQuery({})
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
			local tq = newRowQuery({
				resultTbl = { [1] = { [1] = listedResult("Rarity: RARE\nBehemoth Hold\nGold Ring") } },
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
			local tq = newRowQuery({
				resultTbl = { [1] = { [1] = listedResult(itemString, swapEvaluation(
						"Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+17% to Cold Resistance",
						{ { from = "Fire", to = "Cold" } }, { 1 })) } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.AddItemTooltip = function() end
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip"):Tooltip()

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
			local text = tooltipText(tooltip)
			assert.is_truthy(text:find("Estimated swap: Fire -> Cold", 1, true))
			assert.is_truthy(text:find("(roll may change)", 1, true))
			assert.is_truthy(text:find("[Ctrl: compare]", 1, true))
			assert.is_nil(text:find("17%", 1, true))
			assert.are.equal(itemString, tq.resultTbl[1][1].item_string)
		end)

		it("highlights every swapped line and leaves other lines unchanged in the Ctrl preview", function()
			local itemString = "Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+30 to Strength\n+17% to Fire Resistance\n+24% to Cold Resistance"
			local tq = newRowQuery({
				resultTbl = { [1] = { [1] = listedResult(itemString, swapEvaluation(
						"Rarity: RARE\nBehemoth Hold\nCoral Ring\nImplicits: 0\n+30 to Strength\n+17% to Cold Resistance\n+24% to Lightning Resistance",
						{ { from = "Fire", to = "Cold" }, { from = "Cold", to = "Lightning" } }, { 2, 3 })) } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.AddItemTooltip = function(_, tooltip, item)
				for _, modLine in ipairs(item.explicitModLines) do
					tooltip:AddLine(16, colorCodes.MAGIC .. modLine.line, nil, modLine)
				end
			end
			tq.IsResistanceSwapPreviewActive = function() return true end
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip"):Tooltip()

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)

			assert.are.equal(1, #tooltip.childTooltips)
			local previewText = StripEscapes(tooltipText(tooltip.childTooltips[1]))
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

	describe("result action controls", function()
		it("ignore a stale selection while asynchronous evaluation is pending", function()
			local tradeQuery = newRowQuery({
				resultTbl = { [1] = { listedResult("Rarity: RARE\nBehemoth Hold\nGold Ring") } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tradeQuery:PriceItemRowDisplay(1, nil, 0, 20)
			tradeQuery.itemIndexTbl[1] = 2
			local tooltip = new("Tooltip"):Tooltip()

			assert.has_no.errors(function()
				tradeQuery.controls.importButton1.tooltipFunc(tooltip)
			end)
			assert.is_false(tradeQuery.controls.importButton1.enabled())
			assert.has_no.errors(function()
				tradeQuery.controls.whisperButton1.tooltipFunc(tooltip)
			end)
		end)

		it("replaces fetched candidates with the results of a pasted URL", function()
			local oldResult = listedResult("Rarity: RARE\nOld Hold\nGold Ring")
			local newResult = listedResult("Rarity: RARE\nNew Hold\nGold Ring", nil, 2)
			local tradeQuery = newRowQuery({
				resultTbl = { [1] = { oldResult } }, sortedResultTbl = { [1] = { { index = 1 } } },
			})
			local searchCallback
			tradeQuery.tradeQueryRequests.SearchWithURL = function(_, _, callback)
				searchCallback = callback
			end
			tradeQuery:PriceItemRowDisplay(1, nil, 0, 20)
			tradeQuery.controls.uri1.buf = "https://www.pathofexile.com/trade/search/pc/example"

			tradeQuery.controls.priceButton1.onClick()
			searchCallback({ newResult }, nil, "{}")

			assert.are.equal(newResult.item_string, tradeQuery.resultTbl[1][1].item_string)
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
		local function buildExact(stats, trader, weight)
			local query = require("dkjson").encode({ query = { stats = stats, filters = { } } })
			return require("dkjson").decode(mock_tradeQuery:BuildExactListingQuery(query,
				{ trader = trader, weight = weight }))
		end

		it("keeps the existing weight range narrowing for weighted queries", function()
			local exact = buildExact({ { type = "weight", value = { min = 10 }, filters = { } } },
				"WeightSeller", "172")

			assert.are.equal(171, exact.query.stats[1].value.min)
			assert.are.equal(173, exact.query.stats[1].value.max)
		end)

		it("preserves an AND-only resistance query and adds the trader account", function()
			local exact = buildExact({ { type = "and",
				filters = { { id = "pseudo.pseudo_total_fire_resistance", value = { min = 40 } } } } },
				"CapSeller", "0")

			assert.are.equal("and", exact.query.stats[1].type)
			assert.is_nil(exact.query.stats[1].value)
			assert.are.equal(40, exact.query.stats[1].filters[1].value.min)
			assert.are.equal("CapSeller", exact.query.filters.trade_filters.filters.account.input)
		end)
	end)

	describe("generated query routing", function()
		it("carries generated options and descriptors into scheduled evaluation", function()
			local originalAuthToken = main.api.authToken
			local ok, err = pcall(function()
				main.api.authToken = "test-token"
				local cases = {
					{ label = "resistance options enabled", swaps = true, caps = true, weighted = false, route = "plain" },
					{ label = "resistance options disabled", swaps = false, caps = false, weighted = true, route = "adjusted" },
				}
				for _, case in ipairs(cases) do
					local queryOptions = {
						includeResistSwaps = case.swaps,
						includeResistCaps = case.caps,
						weightAdjustedSearch = case.weighted,
					}
					local tradeQuery = newRowQuery({})
					tradeQuery.pbRealm = "pc"
					tradeQuery.pbLeague = "Standard"
					tradeQuery.tradeQueryGenerator = { }
					tradeQuery.tradeQueryGenerator.RequestQuery = function(_, _, context, _, callback)
						callback(context, case.label .. " query", nil, queryOptions)
					end

					local routedRequest
					local function search(routeName)
						return function(_, realm, league, query, callback)
							routedRequest = { routeName, realm, league, query }
							callback({ {
								item_string = "Rarity: RARE\nTest Ring\nCoral Ring\nImplicits: 0\n+17% to Fire Resistance",
								resistanceSwapDescriptors = { { lineIndex = 1, element = "Fire", domain = "explicit" } },
							} })
						end
					end
					tradeQuery.tradeQueryRequests = {
						SearchWithQuery = search("plain"),
						SearchWithQueryWeightAdjusted = search("adjusted"),
					}

					local evaluatedResult
					tradeQuery.GetResultEvaluation = function(self, rowIdx, resultIndex)
						evaluatedResult = self.resultTbl[rowIdx][resultIndex]
						return { { weight = 1 } }
					end
					tradeQuery.UpdateControlsWithItems = function(self, rowIdx)
						self:GetResultEvaluation(rowIdx, 1)
					end

					tradeQuery:PriceItemRowDisplay(1, nil, 0, 20)
					tradeQuery.controls.bestButton1.onClick()
					tradeQuery:ProcessResultEvaluations()

					local result = tradeQuery.resultTbl[1][1]
					assert.are.same({ case.route, "pc", "Standard", case.label .. " query" },
						routedRequest, case.label)
					assert.are.equal(case.swaps, result.resistanceSwapEnabled, case.label)
					assert.are.equal(case.caps, result.prioritiseResistanceCaps, case.label)
					assert.are.same({ { lineIndex = 1, element = "Fire", domain = "explicit" } },
						result.resistanceSwapDescriptors, case.label)
					assert.are.equal(result, evaluatedResult, case.label)
				end
			end)
			main.api.authToken = originalAuthToken
			assert.is_true(ok, err)
		end)
	end)

	describe("resistance swap result evaluation", function()
		local function resistance(value, element, options)
			options = options or { }
			local domain = options.domain or "explicit"
			return {
				line = (domain == "crafted" and "{crafted}" or "")
					.. string.format("+%d%% to %s Resistance", value, element),
				descriptor = options.descriptor ~= false
					and { element = options.descriptorElement or element, domain = domain } or nil,
			}
		end

		local function newEvaluationQuery(mods, options)
			options = options or { }
			local lines = { }
			local descriptors = { }
			for lineIndex, mod in ipairs(mods) do
				local line = type(mod) == "string" and mod or mod.line
				table.insert(lines, line)
				if type(mod) == "table" and mod.descriptor then
					table.insert(descriptors, { lineIndex = lineIndex,
						element = mod.descriptor.element, domain = mod.descriptor.domain })
				end
			end
			local tq = new("TradeQuery"):TradeQuery({ itemsTab = {} })
			tq.tradeQueryGenerator = mock_queryGen
			tq.slotTables[1] = { slotName = "Ring 1" }
			tq.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tq.resultTbl[1] = { {
				item_string = "Rarity: RARE\nTest Ring\nCoral Ring\nImplicits: 0\n" .. table.concat(lines, "\n"),
				resistanceSwapDescriptors = #descriptors > 0 and descriptors or nil,
				resistanceSwapEnabled = options.swaps == true,
				prioritiseResistanceCaps = options.caps == true,
			} }
			return tq
		end

		local function elementCalculator(multipliers, requirements, onEvaluation)
			return function(args)
				local totals = { Fire = 0, Cold = 0, Lightning = 0, Chaos = 0 }
				local seen = { }
				for _, modLine in ipairs(args.repItem.explicitModLines) do
					local value, element = modLine.line:match("^%+(%d+)%% to (%a+) Resistance$")
					if value and totals[element] then
						assert.is_nil(seen[element], "duplicate resistance target " .. element)
						seen[element] = true
						totals[element] = tonumber(value)
					end
				end
				local score = 0
				for element, total in pairs(totals) do
					score = score + total * ((multipliers and multipliers[element]) or 0)
				end
				if onEvaluation then onEvaluation() end
				local output = { Life = 100 + score }
				for element, total in pairs(totals) do
					output["Missing" .. element .. "Resist"] = math.max(0,
						((requirements and requirements[element]) or 0) - total)
				end
				return output
			end
		end

		local function evaluate(tq, calc, yieldFunc)
			return tq:GetResultEvaluation(1, 1, calc, { Life = 100 }, yieldFunc)
		end

		local function attachCalculator(tq, calc, baseOutput)
			tq.itemsTab.build = { calcsTab = { GetMiscCalculator = function()
				local output = type(baseOutput) == "function" and baseOutput() or baseOutput
				return calc, output or { Life = 100 }
			end } }
		end

		local function resistanceState(fireTotal)
			local output = { Life = 100 }
			for _, element in ipairs({ "Fire", "Cold", "Lightning", "Chaos" }) do
				output[element .. "Resist"] = 75
				output[element .. "ResistTotal"] = 75
				output["Missing" .. element .. "Resist"] = 0
			end
			output.FireResistTotal = fireTotal
			return output
		end

		it("uses only the listed item when it is already capped and resistance state is irrelevant", function()
			local tq = newEvaluationQuery({ resistance(10, "Fire"), resistance(20, "Cold") },
				{ swaps = true, caps = true })
			local calls = 0
			tq.ResistanceSwapMayAffectOutput = function() return false end

			local evaluation = evaluate(tq, function()
				calls = calls + 1
				return {
					Life = 100,
					MissingFireResist = 0,
					MissingColdResist = 0,
					MissingLightningResist = 0,
					MissingChaosResist = 0,
				}
			end)

			assert.are.equal(1, calls)
			assert.are.equal(1, #evaluation)
			assert.is_nil(evaluation[1].estimatedResistanceSwap)
		end)

		it("only evaluates swaps that can feed an elemental resistance deficit", function()
			local tq = newEvaluationQuery({ resistance(10, "Fire") }, { swaps = true, caps = true })
			local calls = 0
			tq.ResistanceSwapMayAffectOutput = function() return false end

			local evaluation = evaluate(tq, function(args)
				calls = calls + 1
				return elementCalculator(nil,
					{ Fire = 0, Cold = 10, Lightning = 0, Chaos = 0 })(args)
			end)

			assert.are.equal(2, calls)
			assert.are.equal(1, #evaluation)
			assert.are.equal("Cold", evaluation[1].estimatedResistanceSwap.swaps[1].to)
		end)

		it("keeps resistance swaps when the build depends on resistance state", function()
			local tq = newEvaluationQuery({ resistance(10, "Fire"), resistance(20, "Cold") },
				{ swaps = true, caps = true })
			local calls = 0
			local calc = elementCalculator({ Fire = 1, Cold = 2, Lightning = 3 },
				{ Fire = 0, Cold = 0, Lightning = 0, Chaos = 0 })
			tq.ResistanceSwapMayAffectOutput = function() return true end

			evaluate(tq, function(args)
				calls = calls + 1
				return calc(args)
			end)

			assert.are.equal(6, calls)
		end)

		it("detects direct and modifier-based resistance output dependencies", function()
			local tq = newEvaluationQuery({ resistance(10, "Fire") }, { swaps = true, caps = true })
			tq.itemsTab.build = { calcsTab = { mainEnv = { player = {
				modDB = { mods = { } },
			} } } }
			local function flag(name)
				return { name = name, type = "FLAG" }
			end

			assert.is_false(tq:ResistanceSwapMayAffectOutput())
			assert.is_true(tq:ResistanceSwapMayAffectOutput({
				modList = { flag("FirePenIncreasedByUncappedFireRes") },
			}))
			assert.is_true(tq:ResistanceSwapMayAffectOutput({
				modList = { flag("DamageIncreasedByOvercappedColdRes") },
			}))

			tq.statSortSelectionList = { { stat = "FireResistTotal", weightMult = 1 } }
			assert.is_true(tq:ResistanceSwapMayAffectOutput())

			tq.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tq.itemsTab.build.calcsTab.mainEnv.player.modDB.mods.LifeRegen = { {
				name = "LifeRegen",
				type = "BASE",
				[1] = { type = "PerStat", stat = "FireResistTotal" },
			} }
			assert.is_true(tq:ResistanceSwapMayAffectOutput())

			tq.itemsTab.build.calcsTab.mainEnv.player.modDB.mods = {
				FirePenIncreasedByUncappedFireRes = { flag("FirePenIncreasedByUncappedFireRes") },
			}
			assert.is_true(tq:ResistanceSwapMayAffectOutput())
		end)

		it("generates exactly 3, 6, and 6 distinct-target assignments for one to three candidates", function()
			local resistanceSwap = LoadModule("Classes/TradeResistanceSwap")
			local cases = {
				{ elements = { "Fire" }, expectedAssignments = 3 },
				{ elements = { "Fire", "Cold" }, expectedAssignments = 6 },
				{ elements = { "Fire", "Cold", "Lightning" }, expectedAssignments = 6 },
			}
			for _, case in ipairs(cases) do
				local descriptors = { }
				for lineIndex, element in ipairs(case.elements) do
					table.insert(descriptors, { lineIndex = lineIndex, element = element, domain = "explicit" })
				end
				assert.are.equal(case.expectedAssignments, #resistanceSwap.getAssignments(descriptors),
					table.concat(case.elements, ", "))
			end
		end)

		it("provides a cooperative yield point after each calculated assignment", function()
			local calls = 0
			local yields = 0
			local tq = newEvaluationQuery({ resistance(10, "Fire"), resistance(20, "Cold") }, { swaps = true })

			evaluate(tq,
				elementCalculator({ Fire = 1, Cold = 2, Lightning = 3 }, nil,
					function() calls = calls + 1 end),
				function() yields = yields + 1 end)

			assert.are.equal(6, calls)
			assert.are.equal(calls, yields)
		end)

		it("selects the best permutation and leaves the listed item unchanged", function()
			local tq = newEvaluationQuery({ resistance(10, "Fire"), resistance(20, "Cold") }, { swaps = true })
			local original = tq.resultTbl[1][1].item_string

			local evaluation = evaluate(tq, elementCalculator({ Fire = 1, Cold = 2, Lightning = 4 }))
			local resistanceSwap = evaluation[1].estimatedResistanceSwap
			local swaps = resistanceSwap.swaps

			assert.are.equal(2, #swaps)
			assert.are.same({ from = "Fire", to = "Cold" }, swaps[1])
			assert.are.same({ from = "Cold", to = "Lightning" }, swaps[2])
			assert.are.same({ 1, 2 }, resistanceSwap.lineIndexes)
			assert.is_truthy(resistanceSwap.itemString:find("+10%% to Cold Resistance"))
			assert.is_truthy(resistanceSwap.itemString:find("+20%% to Lightning Resistance"))
			assert.are.equal(original, tq.resultTbl[1][1].item_string)
		end)

		it("prefers fewer swaps when evaluated weights tie", function()
			local tq = newEvaluationQuery({ resistance(10, "Cold") }, { swaps = true })

			local evaluation = evaluate(tq, function()
				return { Life = 100 }
			end)

			assert.is_nil(evaluation[1].estimatedResistanceSwap)
		end)

		it("uses one baseline calculation when ranking is disabled or ineligible", function()
			local cases = {
				newEvaluationQuery({ resistance(10, "Fire") }),
				newEvaluationQuery({ resistance(10, "Fire", { descriptorElement = "Cold" }) }, { swaps = true }),
				newEvaluationQuery({ resistance(10, "Fire", { descriptor = false }) }, { swaps = true }),
			}
			for _, tq in ipairs(cases) do
				local calls = 0
				evaluate(tq, function()
					calls = calls + 1
					return { Life = 100 }
				end)
				assert.are.equal(1, calls)
			end
		end)

		it("keeps capped and partially repaired listings", function()
			local requirements = { Fire = 40, Cold = 40, Lightning = 0, Chaos = 30 }
			local cases = {
				{ label = "already capped", mods = {
					resistance(40, "Fire"), resistance(80, "Cold"), resistance(30, "Chaos", { descriptor = false }),
				}, multipliers = { Fire = 1, Cold = 1, Lightning = 100 }, shortfall = 0, expectSwap = false },
				{ label = "best partial assignment", mods = {
					resistance(80, "Fire"), resistance(30, "Chaos", { descriptor = false }),
				}, shortfall = 40 },
			}
			for _, case in ipairs(cases) do
				local tq = newEvaluationQuery(case.mods, { swaps = true, caps = true })
				local evaluation = evaluate(tq, elementCalculator(case.multipliers, requirements))
				assert.are.equal(1, #evaluation, case.label)
				assert.are.equal(case.shortfall, evaluation[1].totalResistanceCapShortfall, case.label)
				if case.expectSwap ~= nil then
					assert.are.equal(case.expectSwap, evaluation[1].estimatedResistanceSwap ~= nil, case.label)
				end
			end
		end)

		it("records elemental and Chaos shortfalls without dropping caps-only listings", function()
			local calc = elementCalculator(nil, { Fire = 40, Cold = 0, Lightning = 0, Chaos = 30 })
			local cases = {
				{ label = "capped", fire = 40, chaos = 30, shortfall = 0 },
				{ label = "elemental shortfall", fire = 39, chaos = 30, shortfall = 1 },
				{ label = "Chaos shortfall", fire = 40, chaos = 29, shortfall = 1 },
			}
			for _, case in ipairs(cases) do
				local tq = newEvaluationQuery({ resistance(case.fire, "Fire"), resistance(case.chaos, "Chaos") },
					{ caps = true })
				local evaluation = evaluate(tq, calc)
				assert.are.equal(1, #evaluation, case.label)
				assert.are.equal(case.shortfall, evaluation[1].totalResistanceCapShortfall, case.label)
			end
		end)

		it("sorts retained capped and uncapped results by requested stat value", function()
			local tq = new("TradeQuery"):TradeQuery({ itemsTab = {} })
			tq.resultTbl[1] = {
				{ id = "uncapped", prioritiseResistanceCaps = true },
				{ id = "capped", prioritiseResistanceCaps = true },
				{ id = "unrestricted" },
			}
			tq.sortModes = { StatValue = "statValue" }
			tq.itemsTab.build = { calcsTab = { GetMiscCalculator = function()
				return function() return { } end, { }
			end } }
			tq.GetResultEvaluation = function(_, _, resultIndex)
				return { { weight = 4 - resultIndex, totalResistanceCapShortfall = resultIndex == 1 and 10 or 0 } }
			end

			local sorted = tq:SortFetchResults(1, tq.sortModes.StatValue)

			assert.are.same({ "uncapped", "capped", "unrestricted" }, {
				tq.resultTbl[1][sorted[1].index].id,
				tq.resultTbl[1][sorted[2].index].id,
				tq.resultTbl[1][sorted[3].index].id,
			})
		end)

		it("recalculates cached cap shortfall when the build resistance state changes", function()
			local requiredFire = 50
			local tq = newEvaluationQuery({ resistance(40, "Fire"), resistance(30, "Chaos") }, { caps = true })
			local function calc(args)
				return elementCalculator(nil, {
					Fire = requiredFire,
					Cold = 0,
					Lightning = 0,
					Chaos = 30,
				})(args)
			end
			attachCalculator(tq, calc, function() return resistanceState(requiredFire) end)

			local first = tq:GetResultEvaluation(1, 1)
			assert.are.equal(1, #first)
			assert.are.equal(10, first[1].totalResistanceCapShortfall)

			requiredFire = 40
			local second = tq:GetResultEvaluation(1, 1)
			assert.are.equal(1, #second)
			assert.are.equal(0, second[1].totalResistanceCapShortfall)
		end)

		it("reuses the single best evaluation while the build and weights are unchanged", function()
			local calls = 0
			local tq = newEvaluationQuery({ "+5 to Strength", resistance(10, "Fire", { domain = "crafted" }) },
				{ swaps = true })
			local calc = elementCalculator({ Fire = 1, Cold = 2, Lightning = 3 }, nil,
				function() calls = calls + 1 end)
			attachCalculator(tq, calc)

			local first = tq:GetResultEvaluation(1, 1)
			local second = tq:GetResultEvaluation(1, 1)

			assert.are.equal(3, calls)
			assert.are.equal(first, second)
			assert.are.equal(1, #second)
		end)

		it("publishes evaluation inputs only after cooperative calculation completes", function()
			local tq = newEvaluationQuery({ resistance(10, "Fire") }, { swaps = true })
			local result = tq.resultTbl[1][1]
			result.evaluation = { { weight = -1 } }
			local co = coroutine.create(function()
				tq:GetResultEvaluation(1, 1,
					elementCalculator({ Fire = 1, Cold = 2, Lightning = 3 }),
					{ Life = 100 }, coroutine.yield)
			end)

			assert.is_true(coroutine.resume(co))
			assert.are.equal(-1, result.evaluation[1].weight)
			assert.is_nil(result.evaluationInputs)
			while coroutine.status(co) ~= "dead" do
				assert.is_true(coroutine.resume(co))
			end
			assert.is_truthy(result.evaluationInputs)
			assert.is_true(result.evaluation[1].weight > 0)
		end)

		it("reuses the cached evaluation when sorting supplies a shared calculator", function()
			local calls = 0
			local tq = newEvaluationQuery({ resistance(10, "Fire") }, { swaps = true })
			local calc = elementCalculator({ Fire = 1, Cold = 2, Lightning = 3 }, nil,
				function() calls = calls + 1 end)
			local baseOutput = { Life = 100 }
			attachCalculator(tq, calc, baseOutput)

			local first = tq:GetResultEvaluation(1, 1)
			local second = tq:GetResultEvaluation(1, 1, calc, baseOutput)

			assert.are.equal(3, calls)
			assert.are.equal(first, second)
		end)
	end)
end)
