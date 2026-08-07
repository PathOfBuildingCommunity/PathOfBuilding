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

		it("shows the simulated bench craft and its Ctrl compare hint", function()
			local tq = newTradeQuery({
				resultTbl = { [1] = { [1] = {
					item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring",
					amount = 1,
					currency = "chaos",
					evaluation = { {
						benchCraft = "+25 to Strength ^8(Suffix)",
						benchCraftItemString = "Rarity: RARE\nBehemoth Hold\nGold Ring\nImplicits: 0\n{crafted}{suffix}+25 to Strength",
					} },
				} } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.AddItemTooltip = function() end
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip")

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)

			local tooltipText = ""
			for _, line in ipairs(tooltip.lines) do
				tooltipText = tooltipText .. (line.text or "") .. "\n"
			end
			assert.is_truthy(tooltipText:find("Bench craft: +25 to Strength", 1, true))
			assert.is_truthy(tooltipText:find("[Ctrl: compare]", 1, true))
		end)

		it("shows the simulated item and highlights its craft while Ctrl is held", function()
			local tq = newTradeQuery({
				resultTbl = { [1] = { [1] = {
					item_string = "Rarity: RARE\nBehemoth Hold\nGold Ring\nImplicits: 0\n{prefix}+40 to maximum Mana",
					amount = 1,
					currency = "chaos",
					evaluation = { {
						benchCraft = "+25 to Strength ^8(Suffix)",
						benchCraftItemString = "Rarity: RARE\nBehemoth Hold\nGold Ring\nImplicits: 0\n{prefix}+40 to maximum Mana\n{crafted}{suffix}+25 to Strength",
						benchCraftLineIndexes = { 2 },
					} },
				} } },
				sortedResultTbl = { [1] = { { index = 1 } } },
			})
			tq.itemsTab.AddItemTooltip = function(_, tooltip, item)
				for _, modLine in ipairs(item.explicitModLines or { }) do
					tooltip:AddLine(16, colorCodes.MAGIC .. modLine.line, nil, modLine)
				end
			end
			local previewActive = true
			tq.IsBenchCraftPreviewActive = function() return previewActive end
			local dropdown = buildRow1Dropdown(tq)
			local tooltip = new("Tooltip")

			dropdown.tooltipFunc(tooltip, "DROP", 1, nil)

			assert.are.equal(1, #tooltip.childTooltips)
			local previewText = ""
			for _, line in ipairs(tooltip.childTooltips[1].lines) do
				previewText = previewText .. (line.text or "") .. "\n"
			end
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
		local prefixCraft = {
			type = "Prefix",
			group = "IncreasedLife",
			modTags = { "life" },
			types = { Ring = true },
			"+(51-55) to maximum Life",
		}
		local suffixCraft = {
			type = "Suffix",
			group = "Strength",
			modTags = { "attribute" },
			types = { Ring = true },
			"+(21-25) to Strength",
		}

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
			for index = 1, prefixCount do
				table.insert(lines, prefixLines[index])
			end
			for index = 1, suffixCount do
				table.insert(lines, suffixLines[index])
			end
			for _, line in ipairs(extraLines or { }) do
				table.insert(lines, line)
			end
			return table.concat(lines, "\n")
		end

		local function evaluate(itemString, crafts, calcOverride)
			local tradeQuery = new("TradeQuery", { itemsTab = { } })
			tradeQuery.tradeQueryGenerator = mock_queryGen
			tradeQuery.itemsTab.build = { data = { masterMods = crafts or { prefixCraft, suffixCraft } } }
			tradeQuery.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tradeQuery.slotTables[1] = { slotName = "Ring 1", considerBenchCraft = true }
			tradeQuery.resultTbl[1] = { { item_string = itemString } }
			local function calc(args)
				local life = 100
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted and modLine.line:find("maximum Life", 1, true) then
						life = 300
					elseif modLine.crafted and modLine.line:find("to Strength", 1, true) then
						life = 150
					end
				end
				return { Life = life }
			end
			return tradeQuery:GetResultEvaluation(1, 1, calcOverride or calc, { Life = 100 })[1]
		end

		it("only evaluates suffix crafts when the prefix side is full", function()
			local evaluation = evaluate(makeRareRing(3, 2))

			assert.are.equal(1.5, evaluation.weight)
			assert.is_truthy(evaluation.benchCraft:find("to Strength", 1, true))
			assert.is_truthy(evaluation.benchCraftItemString:find("{crafted}", 1, true))
			assert.are.same({ 6 }, evaluation.benchCraftLineIndexes)
		end)

		it("only evaluates prefix crafts when the suffix side is full", function()
			local evaluation = evaluate(makeRareRing(2, 3))

			assert.is_true(evaluation.weight > 1)
			assert.is_truthy(evaluation.benchCraft:find("maximum Life", 1, true))
		end)

		it("does not evaluate crafts unavailable for the item type", function()
			local amuletCraft = {
				type = "Prefix",
				group = "IncreasedLife",
				modTags = { "life" },
				types = { Amulet = true },
				"+(51-55) to maximum Life",
			}
			local evaluation = evaluate(makeRareRing(2, 2), { amuletCraft })

			assert.are.equal(1, evaluation.weight)
			assert.is_nil(evaluation.benchCraft)
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
			local previewItem = new("Item", evaluation.benchCraftItemString)
			local previewModLine = previewItem.explicitModLines[evaluation.benchCraftLineIndexes[1]]
			local previewCraftLine = itemLib.applyRange(previewModLine.line, previewModLine.range, 1, 1)

			assert.are.equal(evaluatedCraftLine, previewCraftLine)
			assert.are.equal(main.defaultItemAffixQuality or 0.5, previewModLine.range)
		end)

		it("does not add a second bench craft", function()
			local evaluation = evaluate(makeRareRing(1, 1, { "{crafted}{suffix}+20 to Strength" }))

			assert.is_nil(evaluation.benchCraft)
		end)

		it("allows another bench craft with multiple crafted modifiers", function()
			local evaluation = evaluate(makeRareRing(1, 1, {
				"{crafted}{suffix}Can have up to 3 Crafted Modifiers",
			}), { prefixCraft })

			assert.is_truthy(evaluation.benchCraft:find("maximum Life", 1, true))
		end)

		it("does not add a fourth craft when crafted modifiers have distinct source indices", function()
			local evaluation = evaluate(makeRareRing(1, 0, {
				"{crafted}{suffix}{modGroup:trade:crafted:0}Can have up to 3 Crafted Modifiers",
				"{crafted}{suffix}{modGroup:trade:crafted:1}+20% to Fire Resistance",
				"{crafted}{suffix}{modGroup:trade:crafted:2}+20% to Cold Resistance",
			}), { prefixCraft })

			assert.are.equal(1, evaluation.weight)
			assert.is_nil(evaluation.benchCraft)
		end)

		it("does not evaluate crafts on corrupted or mirrored items", function()
			for _, marker in ipairs({ "Corrupted", "Mirrored" }) do
				local evaluation = evaluate(makeRareRing(1, 1, { marker }))
				assert.are.equal(1, evaluation.weight)
				assert.is_nil(evaluation.benchCraft)
			end
		end)

		it("does not duplicate an existing affix group", function()
			local evaluation = evaluate(makeRareRing(1, 3, { "{prefix}+50 to maximum Life" }), { prefixCraft })

			assert.are.equal(1, evaluation.weight)
			assert.is_nil(evaluation.benchCraft)
		end)

		it("does not evaluate an item when an explicit affix side is unknown", function()
			local evaluation = evaluate(makeRareRing(0, 0, { "+50 to maximum Life" }), { suffixCraft })

			assert.are.equal(1, evaluation.weight)
			assert.is_nil(evaluation.benchCraft)
		end)

		it("does not evaluate an item without explicit affix metadata", function()
			local evaluation = evaluate(makeRareRing(0, 0), { suffixCraft })

			assert.are.equal(1, evaluation.weight)
			assert.is_nil(evaluation.benchCraft)
		end)

		it("does not evaluate contradictory sides for the same trade affix", function()
			local evaluation = evaluate(makeRareRing(0, 0, {
				"{prefix}{modGroup:trade:explicit:0}+50 to maximum Life",
				"{suffix}{modGroup:trade:explicit:0}+30% to Fire Resistance",
			}), { suffixCraft })

			assert.are.equal(1, evaluation.weight)
			assert.is_nil(evaluation.benchCraft)
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
				table.insert(crafts, {
					type = "Suffix",
					group = "Candidate" .. index,
					modTags = { "attribute" },
					types = { Ring = true },
					"+" .. index .. " to Strength",
				})
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

		it("keeps lower bench tiers when a higher tier has a worse trade-off", function()
			local crafts = {
				{
					type = "Suffix", group = "FlaskEffectAndFlaskChargesGained", level = 60, types = { Ring = true },
					"20% reduced Flask Charges gained", "(8-10)% increased Effect of Flasks on you",
				},
				{
					type = "Suffix", group = "FlaskEffectAndFlaskChargesGained", level = 75, types = { Ring = true },
					"33% reduced Flask Charges gained", "(11-14)% increased Effect of Flasks on you",
				},
			}
			local evaluation = evaluate(makeRareRing(3, 2), crafts, function(args)
				local life = 100
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted and modLine.line:find("20% reduced", 1, true) then
						life = 200
					elseif modLine.crafted and modLine.line:find("33% reduced", 1, true) then
						life = 50
					end
				end
				return { Life = life }
			end)

			assert.is_truthy(evaluation.benchCraft:find("20% reduced", 1, true))
		end)

		it("renders every line of a multi-line craft in the Ctrl preview", function()
			local multiLineCraft = {
				type = "Suffix", group = "FlaskEffectAndFlaskChargesGained", types = { Ring = true },
				"20% reduced Flask Charges gained", "(8-10)% increased Effect of Flasks on you",
			}
			local originalItemString = makeRareRing(3, 2)
			local evaluation = evaluate(originalItemString, { multiLineCraft }, function(args)
				for _, modLine in ipairs(args.repItem.explicitModLines or { }) do
					if modLine.crafted then
						return { Life = 200 }
					end
				end
				return { Life = 100 }
			end)
			local tooltipQuery = new("TradeQuery", { itemsTab = { } })
			tooltipQuery.itemsTab.activeItemSet = { }
			tooltipQuery.itemsTab.slots = { }
			tooltipQuery.slotTables[1] = { slotName = "Ring 1" }
			tooltipQuery.resultTbl[1] = { {
				item_string = originalItemString,
				amount = 1,
				currency = "chaos",
				evaluation = { evaluation },
			} }
			tooltipQuery.sortedResultTbl[1] = { { index = 1 } }
			tooltipQuery.itemsTab.AddItemTooltip = function(_, tooltip, item)
				for _, modLine in ipairs(item.explicitModLines or { }) do
					local renderedLine = modLine.range
						and itemLib.applyRange(modLine.line, modLine.range, modLine.valueScalar, modLine.corruptedRange)
						or modLine.line
					tooltip:AddLine(16, colorCodes.MAGIC .. renderedLine, nil, modLine)
				end
			end
			tooltipQuery.IsBenchCraftPreviewActive = function() return true end
			tooltipQuery:PriceItemRowDisplay(1, nil, 0, 20)
			local tooltip = new("Tooltip")

			tooltipQuery.controls.resultDropdown1.tooltipFunc(tooltip, "DROP", 1, nil)

			assert.are.equal(originalItemString, tooltipQuery.resultTbl[1][1].item_string)
			assert.are.equal(1, #tooltip.childTooltips)
			local previewText = ""
			for _, line in ipairs(tooltip.childTooltips[1].lines) do
				previewText = previewText .. (line.text or "") .. "\n"
			end
			assert.is_truthy(previewText:find("[Craft] 20% reduced Flask Charges gained", 1, true))
			assert.is_truthy(previewText:find("9% increased Effect of Flasks on you", 1, true))
		end)

	end)
end)
