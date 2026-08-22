describe("TradeQuery", function()
	local mock_tradeQuery
	local mock_queryGen

	before_each(function()
		mock_tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
		mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = {} })
	end)

	local function newResultQuery(evaluation, itemString)
		local tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = { }, activeItemSet = { }, slots = { } })
		tradeQuery.slotTables[1] = { slotName = "Ring 1" }
		if evaluation then
			tradeQuery.resultTbl[1] = { {
				item_string = itemString or "Rarity: RARE\nBehemoth Hold\nGold Ring", amount = 1,
				currency = "chaos", evaluation = next(evaluation) and { evaluation } or nil,
			} }
			tradeQuery.sortedResultTbl[1] = { { index = 1 } }
		end
		return tradeQuery
	end

	local function buildResultDropdown(tradeQuery)
		tradeQuery:PriceItemRowDisplay(1, nil, 0, 20)
		return tradeQuery.controls.resultDropdown1
	end

	local function tooltipText(tooltip)
		local lines = { }
		for _, line in ipairs(tooltip.lines) do
			if line.text then
				table.insert(lines, line.text)
			end
		end
		return table.concat(lines, "\n")
	end

	local function addItemTooltip(_, tooltip, item)
		for _, modLine in ipairs(item.explicitModLines or { }) do
			local line = modLine.range
				and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar, modLine.corruptedRange)
				or modLine.line
			tooltip:AddLine(16, colorCodes.MAGIC .. line, nil, modLine)
		end
	end

	local function newEvaluationQuery(results)
		local tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = { } })
		tradeQuery.controls.priceButton1, tradeQuery.controls.pbNotice = { label = "Price Item" }, { label = "" }
		tradeQuery.resultTbl[1] = results or { { } }
		return tradeQuery
	end
	describe("result sorting", function()
		it("ignores row metadata in Highest Weight order", function()
			mock_tradeQuery.resultTbl[1] = { { }, { }, { } }
			mock_tradeQuery.resultTbl[1].benchCraftEvaluationPlan = { }
			mock_tradeQuery.sortModes = { Weight = "(Highest) Weighted Sum" }

			local sortedResults = mock_tradeQuery:SortFetchResults(1, mock_tradeQuery.sortModes.Weight)

			assert.are.equal(3, #sortedResults)
			for index, result in ipairs(sortedResults) do
				assert.are.equal("number", type(result.index))
				assert.are.equal(index, result.index)
			end
		end)
	end)
	describe("cooperative result evaluation", function()
		it("resumes fetched result work over multiple frames", function()
			local tradeQuery = newEvaluationQuery({ { }, { } })
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

		it("clears the prior selection before scheduling a new evaluation", function()
			local tradeQuery = newEvaluationQuery()
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
			local tradeQuery = newEvaluationQuery()
			local evaluated = false
			tradeQuery.UpdateControlsWithItems = function()
				evaluated = true
			end

			local fetchContext = tradeQuery:StartResultFetch(1)
			tradeQuery:StartResultEvaluation(1)

			assert.is_true(tradeQuery:IsResultFetchCurrent(1, fetchContext))
			assert.is_nil(tradeQuery.resultEvaluationContexts[1])
			assert.is_false(evaluated)
			assert.are.equal("Searching...", tradeQuery.controls.priceButton1.label)
		end)

		it("rejects a response from a superseded fetch", function()
			local tradeQuery = newEvaluationQuery()

			local firstFetch = tradeQuery:StartResultFetch(1)
			local secondFetch = tradeQuery:StartResultFetch(1)

			assert.is_false(tradeQuery:FinishResultFetch(1, firstFetch))
			assert.are.equal("Searching...", tradeQuery.controls.priceButton1.label)
			assert.is_true(tradeQuery:FinishResultFetch(1, secondFetch))
			assert.are.equal("Price Item", tradeQuery.controls.priceButton1.label)
		end)

		it("publishes only the replacement of a suspended evaluation", function()
			local tradeQuery = newEvaluationQuery()
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
			assert.is_nil(tradeQuery.resultEvaluationContexts[1])
		end)
	end)
	describe("result dropdown tooltipFunc", function()
		it("returns early when result state is missing or cleared", function()
			for _, case in ipairs({
				{ name = "sort missing", tradeQuery = newResultQuery() },
				{ name = "result cleared", tradeQuery = newResultQuery({ }), clearResult = true },
			}) do
				local dropdown = buildResultDropdown(case.tradeQuery)
				if case.clearResult then case.tradeQuery.resultTbl[1] = { } end
				local tooltip = new("Tooltip"):Tooltip()

				assert.has_no.errors(function()
					dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
				end, case.name)
				assert.are.equal(0, #tooltip.lines, case.name)
			end
		end)

		it("describes added and replaced bench crafts in result tooltips", function()
			local itemString = "Rarity: RARE\nBehemoth Hold\nGold Ring\nImplicits: 0\n{crafted}{suffix}+25 to Strength"
			local cases = {
				{ name = "added", evaluation = { benchCraft = "+25 to Strength ^8(Suffix)",
					benchCraftItemString = itemString },
					expected = { "Bench craft: +25 to Strength", "[Ctrl: compare]" } },
				{ name = "replaced", evaluation = { benchCraft = "+25 to Strength ^8(Suffix)",
					benchCraftReplaced = "+20 to Dexterity ^8(Suffix)", benchCraftItemString = itemString },
					expected = { "Replace craft: +20 to Dexterity", "-> +25 to Strength" } },
			}
			for _, case in ipairs(cases) do
				local tq = newResultQuery(case.evaluation)
				tq.itemsTab.AddItemTooltip = function() end
				local tooltip = new("Tooltip"):Tooltip()
				buildResultDropdown(tq).tooltipFunc(tooltip, "DROP", 1, nil)
				local text = tooltipText(tooltip)
				for _, expected in ipairs(case.expected) do
					assert.is_truthy(text:find(expected, 1, true), case.name)
				end
			end
		end)

		it("shows the simulated item and highlights its craft while Ctrl is held", function()
			local tq = newResultQuery({
				benchCraft = "+25 to Strength ^8(Suffix)",
				benchCraftItemString = "Rarity: RARE\nBehemoth Hold\nGold Ring\nImplicits: 0\n{prefix}+40 to maximum Mana\n{crafted}{suffix}+25 to Strength",
				benchCraftLineIndexes = { 2 },
			}, "Rarity: RARE\nBehemoth Hold\nGold Ring\nImplicits: 0\n{prefix}+40 to maximum Mana")
			tq.itemsTab.AddItemTooltip = addItemTooltip
			local previewActive = true
			tq.IsBenchCraftPreviewActive = function() return previewActive end
			local dropdown = buildResultDropdown(tq)
			local tooltip = new("Tooltip"):Tooltip()

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)

			assert.are.equal(1, #tooltip.childTooltips)
			local previewText = tooltipText(tooltip.childTooltips[1])
			assert.is_truthy(previewText:find("[Craft] +25 to Strength", 1, true))
			assert.is_truthy(previewText:find("Estimated with bench craft", 1, true))

			previewActive = false
			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
			assert.is_nil(tooltip.childTooltips)

			previewActive = true
			tq.resultTbl[1][1].evaluation = { { } }
			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)
			assert.is_nil(tooltip.childTooltips)
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
			local tradeQuery = newResultQuery({ })
			buildResultDropdown(tradeQuery)
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

	describe("bench craft result evaluation", function()
		local function makeCraft(spec)
			local lines = spec.lines or { spec.line }
			spec.line, spec.lines = nil, nil
			for _, line in ipairs(lines) do table.insert(spec, line) end
			spec.types = spec.types or { Ring = true }
			return spec
		end

		local prefixCraft = makeCraft({ type = "Prefix", group = "IncreasedLife",
			modTags = { "life" }, line = "+(51-55) to maximum Life" })
		local suffixCraft = makeCraft({ type = "Suffix", group = "Strength",
			modTags = { "attribute" }, line = "+(21-25) to Strength" })
		local originalEstimator

		before_each(function()
			originalEstimator = mock_queryGen.EstimateBenchCraftWeight
		end)

		after_each(function()
			mock_queryGen.EstimateBenchCraftWeight = originalEstimator
		end)

		local function makeRareRing(prefixCount, suffixCount, extraLines)
			local lines = { "Rarity: Rare", "Test Ring", "Sapphire Ring", "Implicits: 0" }
			local prefixLines = {
				"{prefix}+40 to maximum Mana",
				"{prefix}20% increased Armour",
				"{prefix}20% increased Evasion Rating",
			}
			local suffixLines = {
				"{suffix}+30% to Fire Resistance",
				"{suffix}+30% to Cold Resistance",
				"{suffix}+30% to Lightning Resistance",
			}
			for index = 1, prefixCount do table.insert(lines, prefixLines[index]) end
			for index = 1, suffixCount do table.insert(lines, suffixLines[index]) end
			for _, line in ipairs(extraLines or { }) do table.insert(lines, line) end
			return table.concat(lines, "\n")
		end

		local function craftOutput(args, lifeByText)
			for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
				if modLine.crafted then
					for text, life in pairs(lifeByText) do
						if modLine.line:find(text, 1, true) then
							return { Life = life }
						end
					end
				end
			end
			return { Life = 100 }
		end

		local function evaluate(itemString, crafts, calcOverride, yieldFunc, evaluationPlan)
			local tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = { } })
			tradeQuery.tradeQueryGenerator = mock_queryGen
			tradeQuery.itemsTab.build = { data = { masterMods = crafts or { prefixCraft, suffixCraft } } }
			tradeQuery.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tradeQuery.slotTables[1] = { slotName = "Ring 1", considerBenchCraft = true }
			tradeQuery.resultTbl[1] = {
				{ item_string = itemString },
				benchCraftEvaluationPlan = evaluationPlan,
			}
			local calcFunc = calcOverride or function(args)
				return craftOutput(args, { ["maximum Life"] = 300, ["to Strength"] = 150 })
			end
			local baseOutput = { Life = 100 }
			local evaluation = tradeQuery:GetResultEvaluation(1, 1, calcFunc, baseOutput, yieldFunc)[1]
			return evaluation, tradeQuery, calcFunc, baseOutput
		end

		local function assertNoCraft(evaluation, caseName)
			assert.are.equal(1, evaluation.weight, caseName)
			assert.is_nil(evaluation.benchCraft, caseName)
		end

		it("evaluates crafts only on the open affix side", function()
			local cases = {
				{ name = "suffix open", prefixes = 3, suffixes = 2, weight = 1.5, craftText = "to Strength" },
				{ name = "prefix open", prefixes = 2, suffixes = 3, craftText = "maximum Life" },
			}
			for _, case in ipairs(cases) do
				local evaluation = evaluate(makeRareRing(case.prefixes, case.suffixes))

				if case.weight then assert.are.equal(case.weight, evaluation.weight, case.name)
				else assert.is_true(evaluation.weight > 1, case.name) end
				assert.is_truthy(evaluation.benchCraft:find(case.craftText, 1, true), case.name)
				assert.is_truthy(evaluation.benchCraftItemString:find("{crafted}", 1, true), case.name)
				assert.are.same({ 6 }, evaluation.benchCraftLineIndexes, case.name)
			end
		end)

		it("reuses cached craft evaluations when a shared calculator is provided", function()
			local calls = 0
			local _, tradeQuery, calcFunc, baseOutput = evaluate(makeRareRing(3, 2), { suffixCraft }, function(args)
				calls = calls + 1
				return craftOutput(args, { ["to Strength"] = 150 })
			end)

			tradeQuery:GetResultEvaluation(1, 1, calcFunc, baseOutput)

			assert.are.equal(2, calls)
		end)

		it("does not evaluate crafts unavailable for the item type", function()
			local amuletCraft = makeCraft({ type = "Prefix", group = "IncreasedLife", modTags = { "life" },
				types = { Amulet = true }, line = "+(51-55) to maximum Life" })
			local evaluation = evaluate(makeRareRing(2, 2), { amuletCraft })

			assertNoCraft(evaluation, "Ring cannot use Amulet craft")
		end)

		it("previews the same craft roll that was used for evaluation", function()
			local evaluatedCraftLine
			local evaluation = evaluate(makeRareRing(3, 2), { suffixCraft }, function(args)
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted then
						evaluatedCraftLine = itemLib.applyRange(modLine.line, modLine.range, 1, 1)
						return { Life = 200 }
					end
				end
				return { Life = 100 }
			end)
			local previewItem = new("Item"):Item(evaluation.benchCraftItemString)
			local previewModLine = previewItem.explicitModLines[evaluation.benchCraftLineIndexes[1]]
			local previewCraftLine = itemLib.applyRange(previewModLine.line, previewModLine.range, 1, 1)

			assert.are.equal(evaluatedCraftLine, previewCraftLine)
			assert.are.equal(main.defaultItemAffixQuality or 0.5, previewModLine.range)
		end)

		it("replaces an existing bench craft when the item is otherwise full", function()
			local evaluation = evaluate(makeRareRing(3, 2, { "{crafted}{suffix}+20 to Dexterity" }), { suffixCraft })

			assert.is_truthy(evaluation.benchCraft:find("to Strength", 1, true))
			assert.is_truthy(evaluation.benchCraftReplaced:find("+20 to Dexterity", 1, true))
			assert.is_nil(evaluation.benchCraftItemString:find("+20 to Dexterity", 1, true))
		end)

		it("keeps an existing bench craft when every replacement is worse", function()
			local evaluation = evaluate(makeRareRing(1, 1, { "{crafted}{prefix}+50 to maximum Life" }), { suffixCraft })

			assert.is_true(evaluation.weight > 1)
			assert.is_nil(evaluation.benchCraft)
			assert.is_nil(evaluation.benchCraftReplaced)
		end)

		it("removes every line of a replaced multi-line craft", function()
			local evaluation = evaluate(makeRareRing(1, 1, {
				"{crafted}{prefix}{modGroup:trade:crafted:0}+20 to Dexterity",
				"{crafted}{prefix}{modGroup:trade:crafted:0}10% increased Rarity of Items found",
			}), { suffixCraft })

			assert.is_truthy(evaluation.benchCraftReplaced:find("to Dexterity/10% increased Rarity", 1, true))
			assert.is_nil(evaluation.benchCraftItemString:find("+20 to Dexterity", 1, true))
			assert.is_nil(evaluation.benchCraftItemString:find("10% increased Rarity", 1, true))
		end)

		it("tracks the replacement preview line with catalyst scaling", function()
			local itemString = makeRareRing(3, 2, { "{crafted}{suffix}+20 to Dexterity" })
				:gsub("Implicits: 0", "Catalyst: Intrinsic\nCatalystQuality: 20\nImplicits: 0")
			local evaluation = evaluate(itemString, { suffixCraft })
			local previewItem = new("Item"):Item(evaluation.benchCraftItemString)
			local previewModLine = previewItem.explicitModLines[evaluation.benchCraftLineIndexes[1]]

			assert.is_true(previewModLine.crafted)
			assert.is_truthy(previewModLine.line:find("to Strength", 1, true))
			assert.is_nil(evaluation.benchCraftItemString:find("+20 to Dexterity", 1, true))
		end)

		it("allows another bench craft with multiple crafted modifiers", function()
			local evaluation = evaluate(makeRareRing(1, 1, {
				"{crafted}{suffix}Can have up to 3 Crafted Modifiers",
			}), { prefixCraft })

			assert.is_truthy(evaluation.benchCraft:find("maximum Life", 1, true))
			assert.is_nil(evaluation.benchCraftReplaced)
		end)

		it("does not add a fourth craft when crafted modifiers have distinct source indices", function()
			local evaluation = evaluate(makeRareRing(1, 0, {
				"{crafted}{suffix}{modGroup:trade:crafted:0}Can have up to 3 Crafted Modifiers",
				"{crafted}{suffix}{modGroup:trade:crafted:1}+20% to Fire Resistance",
				"{crafted}{suffix}{modGroup:trade:crafted:2}+20% to Cold Resistance",
			}), { prefixCraft })

			assertNoCraft(evaluation, "crafted modifier limit")
		end)

		it("does not evaluate crafts on corrupted or mirrored items", function()
			for _, marker in ipairs({ "Corrupted", "Mirrored" }) do
				local evaluation = evaluate(makeRareRing(1, 1, { marker }))
				assertNoCraft(evaluation, marker)
			end
		end)

		it("does not duplicate an existing affix group", function()
			local evaluation = evaluate(makeRareRing(1, 3, { "{prefix}+50 to maximum Life" }), { prefixCraft })

			assertNoCraft(evaluation, "existing affix group")
		end)

		it("blocks a craft when a differently worded explicit mod occupies its group", function()
			local minionCountCraft = makeCraft({ type = "Prefix", group = "MaximumMinionCount",
				types = { Helmet = true },
				lines = {
					"+1 to maximum number of Raised Zombies",
					"+1 to maximum number of Skeletons",
				} })
			local itemString = table.concat({
				"Rarity: Rare",
				"Test Helmet",
				"Hubris Circlet",
				"Implicits: 0",
				"{prefix}+1 to maximum number of Spectres",
			}, "\n")

			local evaluation = evaluate(itemString, { minionCountCraft })

			assertNoCraft(evaluation, "same group with different wording")
		end)

		it("rejects incomplete or contradictory explicit affix metadata", function()
			local cases = {
				{ name = "side absent", lines = { "+50 to maximum Life" } },
				{ name = "metadata absent", lines = { } },
				{ name = "sides contradictory", lines = {
					"{prefix}{modGroup:trade:explicit:0}+50 to maximum Life",
					"{suffix}{modGroup:trade:explicit:0}+30% to Fire Resistance",
				} },
			}
			for _, case in ipairs(cases) do
				local evaluation = evaluate(makeRareRing(0, 0, case.lines), { suffixCraft })
				assertNoCraft(evaluation, case.name)
			end
		end)

		it("counts multi-line trade affixes once", function()
			local independentPrefixCraft = copyTable(suffixCraft, true)
			independentPrefixCraft.type = "Prefix"
			local evaluation = evaluate(makeRareRing(1, 3, {
				"{prefix}{modGroup:trade:explicit:0}+50 to maximum Life",
				"{prefix}{modGroup:trade:explicit:0}20% increased Armour",
			}), { independentPrefixCraft })

			assert.is_true(evaluation.weight > 1)
			assert.is_truthy(evaluation.benchCraft:find("to Strength", 1, true))
		end)

		it("reuses the parsed item without leaking prior craft candidates", function()
			local crafts = { }
			for index = 1, 25 do
				table.insert(crafts, makeCraft({ type = "Suffix", group = "Candidate" .. index,
					modTags = { "attribute" }, line = "+" .. index .. " to Strength" }))
			end
			local calls = 0
			local maxCraftedLines = 0
			local evaluation = evaluate(makeRareRing(3, 2), crafts, function(args)
				calls = calls + 1
				local craftedLines = 0
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted then
						craftedLines = craftedLines + 1
					end
				end
				maxCraftedLines = math.max(maxCraftedLines, craftedLines)
				return { Life = 100 + craftedLines }
			end)

			assert.are.equal(26, calls)
			assert.are.equal(1, maxCraftedLines)
			assert.is_truthy(evaluation.benchCraft)
		end)

		it("provides a cooperative yield point after the item and every bench craft", function()
			local calls = 0
			local yields = 0

			evaluate(makeRareRing(3, 2), { suffixCraft }, function()
				calls = calls + 1
				return { Life = 100 }
			end, function()
				yields = yields + 1
			end)

			assert.are.equal(2, calls)
			assert.are.equal(calls, yields)
		end)

		it("fully evaluates only the highest estimated-weight legal bench craft", function()
			local predictedBest = makeCraft({ type = "Suffix", group = "PredictedBest",
				statOrder = { 1 }, line = "+(1-1) to Strength" })
			local actualBest = makeCraft({ type = "Suffix", group = "ActualBest",
				statOrder = { 2 }, line = "+(2-2) to Dexterity" })
			local evaluationPlan = { statWeights = { { stat = "Life", weightMult = 1 } } }
			mock_queryGen.EstimateBenchCraftWeight = function(_, craft, receivedPlan)
				assert.are.equal(evaluationPlan, receivedPlan)
				return craft == predictedBest and 2 or 1
			end
			local calls = 0
			local evaluation = evaluate(makeRareRing(3, 2), { actualBest, predictedBest }, function(args)
				calls = calls + 1
				return craftOutput(args, { Dexterity = 300, Strength = 200 })
			end, nil, evaluationPlan)
			assert.are.equal(2, calls)
			assert.is_truthy(evaluation.benchCraft:find("Strength", 1, true))
		end)

		it("evaluates the best general craft and each highest-level local group", function()
			local localStunLow = makeCraft({ type = "Prefix", group = "LocalStunDuration", level = 20,
				line = "11% increased Stun Duration on Enemies" })
			local localStunHigh = makeCraft({ type = "Prefix", group = "LocalStunDuration", level = 40,
				line = "22% increased Stun Duration on Enemies" })
			local localEnergyShield = makeCraft({ type = "Prefix", group = "LocalIncreasedEnergyShield", level = 30,
				line = "+10 to maximum Energy Shield" })
			local generalBest = makeCraft({ type = "Prefix", group = "IncreasedLife", level = 30,
				line = "+20 to maximum Life" })
			local generalWorse = makeCraft({ type = "Prefix", group = "IncreasedMana", level = 30,
				line = "+20 to maximum Mana" })
			local evaluationPlan = { statWeights = { { stat = "Life", weightMult = 1 } } }
			mock_queryGen.EstimateBenchCraftWeight = function(_, craft)
				return craft == generalBest and 2 or 1
			end
			local evaluatedLines = { }
			evaluate(makeRareRing(2, 3), {
				localStunLow, localStunHigh, localEnergyShield, generalWorse, generalBest,
			}, function(args)
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted then
						evaluatedLines[modLine.line] = true
					end
				end
				return { Life = 100 }
			end, nil, evaluationPlan)
			assert.is_nil(evaluatedLines["11% increased Stun Duration on Enemies"])
			assert.is_true(evaluatedLines["22% increased Stun Duration on Enemies"])
			assert.is_true(evaluatedLines["+10 to maximum Energy Shield"])
			assert.is_true(evaluatedLines["+20 to maximum Life"])
			assert.is_nil(evaluatedLines["+20 to maximum Mana"])
		end)

		it("uses item scaling when selecting the best general craft", function()
			local attributeCraft = makeCraft({ type = "Suffix", group = "Strength",
				modTags = { "attribute" }, line = "+20 to Strength" })
			local lifeCraft = makeCraft({ type = "Suffix", group = "LifeRegeneration",
				modTags = { "life" }, line = "Regenerate 20 Life per second" })
			local evaluationPlan = { statWeights = { { stat = "Life", weightMult = 1 } } }
			mock_queryGen.EstimateBenchCraftWeight = function(_, craft, _, valueScalar)
				return (craft == attributeCraft and 100 or 110) * valueScalar
			end
			local itemString = makeRareRing(3, 2)
				:gsub("Implicits: 0", "Catalyst: Intrinsic\nCatalystQuality: 20\nImplicits: 0")
			local evaluation = evaluate(itemString, { lifeCraft, attributeCraft }, function(args)
				return craftOutput(args, { Strength = 200 })
			end, nil, evaluationPlan)
			assert.is_truthy(evaluation.benchCraft:find("Strength", 1, true))
		end)

		it("falls back to exhaustive evaluation when stat weights changed after the query", function()
			local strengthCraft = makeCraft({ type = "Suffix", group = "Strength", line = "+1 to Strength" })
			local dexterityCraft = makeCraft({ type = "Suffix", group = "Dexterity", line = "+2 to Dexterity" })
			local stalePlan = { statWeights = { { stat = "Life", weightMult = 2 } } }
			mock_queryGen.EstimateBenchCraftWeight = function(_, _, receivedPlan)
				assert.is_nil(receivedPlan)
			end
			local calls = 0
			local evaluation = evaluate(makeRareRing(3, 2), { strengthCraft, dexterityCraft }, function(args)
				calls = calls + 1
				return craftOutput(args, { Dexterity = 190, Strength = 150 })
			end, nil, stalePlan)
			assert.are.equal(3, calls)
			assert.are.equal(190, evaluation.output.Life)
			assert.is_truthy(evaluation.benchCraft:find("Dexterity", 1, true))
		end)

		it("evaluates only the highest-level craft in a group", function()
			local crafts = {
				makeCraft({ type = "Suffix", group = "FlaskEffectAndFlaskChargesGained", level = 60,
					lines = { "20% reduced Flask Charges gained", "(8-10)% increased Effect of Flasks on you" } }),
				makeCraft({ type = "Suffix", group = "FlaskEffectAndFlaskChargesGained", level = 75,
					lines = { "33% reduced Flask Charges gained", "(11-14)% increased Effect of Flasks on you" } }),
			}
			local evaluation = evaluate(makeRareRing(3, 2), crafts, function(args)
				return craftOutput(args, { ["20% reduced"] = 200, ["33% reduced"] = 150 })
			end)

			assert.is_truthy(evaluation.benchCraft:find("33% reduced", 1, true))
		end)

		it("renders every line of a multi-line craft in the Ctrl preview", function()
			local multiLineCraft = makeCraft({ type = "Suffix", group = "FlaskEffectAndFlaskChargesGained",
				lines = { "20% reduced Flask Charges gained", "(8-10)% increased Effect of Flasks on you" } })
			local originalItemString = makeRareRing(3, 2)
			local evaluation = evaluate(originalItemString, { multiLineCraft }, function(args)
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted then
						return { Life = 200 }
					end
				end
				return { Life = 100 }
			end)
			local tooltipQuery = newResultQuery(evaluation, originalItemString)
			tooltipQuery.itemsTab.AddItemTooltip = addItemTooltip
			tooltipQuery.IsBenchCraftPreviewActive = function() return true end
			local dropdown = buildResultDropdown(tooltipQuery)
			local tooltip = new("Tooltip"):Tooltip()

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)

			assert.are.equal(originalItemString, tooltipQuery.resultTbl[1][1].item_string)
			assert.are.equal(1, #tooltip.childTooltips)
			local previewText = tooltipText(tooltip.childTooltips[1])
			assert.is_truthy(previewText:find("[Craft] 20% reduced Flask Charges gained", 1, true))
			assert.is_truthy(previewText:find("9% increased Effect of Flasks on you", 1, true))
		end)

	end)
end)
