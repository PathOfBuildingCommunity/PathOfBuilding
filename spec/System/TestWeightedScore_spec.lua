local WeightedScore = LoadModule("Modules/WeightedScore")

describe("WeightedScore module", function()
	-- Save and restore maxStatIncrease around the whole suite so we don't
	-- pollute other spec files that rely on the real game value.
	local savedMaxStatIncrease
	before_each(function()
		savedMaxStatIncrease = data.misc.maxStatIncrease
		data.misc.maxStatIncrease = 2
	end)
	after_each(function()
		data.misc.maxStatIncrease = savedMaxStatIncrease
	end)

	-- defaultWeights -----------------------------------------------------------

	it("defaultWeights returns two entries (FullDPS and TotalEHP)", function()
		local weights = WeightedScore.defaultWeights()
		assert.are.equal(2, #weights)
		assert.are.equal("FullDPS", weights[1].stat)
		assert.are.equal("TotalEHP", weights[2].stat)
	end)

	-- getWeights ---------------------------------------------------------------

	it("getWeights selects defaults or configured weights", function()
		local custom = { { stat = "TotalDPS", label = "DPS", weightMult = 2.0 } }
		local cases = {
			{ label = "nil build", expected = WeightedScore.defaultWeights() },
			{
				label = "empty selection",
				build = { itemsTab = { tradeQuery = { statSortSelectionList = {} } } },
				expected = WeightedScore.defaultWeights(),
			},
			{
				label = "configured selection",
				build = { itemsTab = { tradeQuery = { statSortSelectionList = custom } } },
				expected = custom,
			},
		}

		for _, case in ipairs(cases) do
			assert.are.same(case.expected, WeightedScore.getWeights(case.build), case.label)
		end
	end)

	-- computeRatioScore: basic ranking -----------------------------------------

	it("scores ordinary ratios and weight combinations", function()
		local unitWeight = { { stat = "TotalDPS", weightMult = 1.0 } }
		local cases = {
			{ label = "neutral", base = { TotalDPS = 1000 }, candidate = { TotalDPS = 1000 }, weights = unitWeight, expected = 1.0 },
			{ label = "better", base = { TotalDPS = 1000 }, candidate = { TotalDPS = 1500 }, weights = unitWeight, expected = 1.5 },
			{ label = "worse", base = { TotalDPS = 1000 }, candidate = { TotalDPS = 500 }, weights = unitWeight, expected = 0.5 },
			{
				label = "multiple weighted stats",
				base = { TotalDPS = 100, TotalEHP = 200 },
				candidate = { TotalDPS = 150, TotalEHP = 250 },
				weights = {
					{ stat = "TotalDPS", weightMult = 1.5 },
					{ stat = "TotalEHP", weightMult = 0.25 },
				},
				expected = 2.5625,
			},
			{ label = "empty weights", base = { TotalDPS = 1000 }, candidate = { TotalDPS = 5000 }, weights = {}, expected = 0.0 },
		}

		for _, case in ipairs(cases) do
			assert.are.equal(
				case.expected,
				WeightedScore.computeRatioScore(case.base, case.candidate, case.weights),
				case.label
			)
		end
	end)

	-- computeRatioScore: edge cases --------------------------------------------

	it("handles infinite, zero, and missing ratio inputs safely", function()
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		local cases = {
			{ label = "infinite base", base = { TotalDPS = math.huge }, candidate = { TotalDPS = 1000 }, expected = 0.0 },
			{ label = "infinite candidate", base = { TotalDPS = 1000 }, candidate = { TotalDPS = math.huge }, expected = 2.0 },
			{ label = "zero base", base = { TotalDPS = 0 }, candidate = { TotalDPS = 500 }, expected = 2.0 },
			{ label = "missing stat", base = {}, candidate = {}, expected = 0.0 },
		}

		for _, case in ipairs(cases) do
			assert.are.equal(
				case.expected,
				WeightedScore.computeRatioScore(case.base, case.candidate, weights),
				case.label
			)
		end
	end)

	-- computeRatioScore: FullDPS fallback --------------------------------------

	it("uses combined DPS fallback when FullDPS is absent from both outputs", function()
		-- baseSum = 500+200+300 = 1000, newSum = 750+300+450 = 1500 → ratio 1.5
		local base    = { TotalDPS = 500, TotalDotDPS = 200, CombinedDPS = 300 }
		local new     = { TotalDPS = 750, TotalDotDPS = 300, CombinedDPS = 450 }
		local weights = { { stat = "FullDPS", weightMult = 1.0 } }
		assert.are.equal(1.5, WeightedScore.computeRatioScore(base, new, weights))
	end)

	it("does not activate fallback when FullDPS is present (no double-counting)", function()
		-- If fallback also ran, score would be higher than 1.5 (the FullDPS ratio)
		local base    = { FullDPS = 1000, TotalDPS = 500, TotalDotDPS = 200, CombinedDPS = 300 }
		local new     = { FullDPS = 1500, TotalDPS = 750, TotalDotDPS = 300, CombinedDPS = 450 }
		local weights = { { stat = "FullDPS", weightMult = 1.0 } }
		-- Only FullDPS direct: 1500/1000 = 1.5
		assert.are.equal(1.5, WeightedScore.computeRatioScore(base, new, weights))
	end)

	-- weightsRequireFullDPS: FullDPS requirement used by PowerBuilder ----------

	it("weightsRequireFullDPS identifies active FullDPS weights", function()
		local cases = {
			{ label = "nil", expected = false },
			{ label = "empty", weights = {}, expected = false },
			{ label = "only FullDPS", weights = { { stat = "FullDPS", weightMult = 1.0 } }, expected = true },
			{
				label = "ordinary stats",
				weights = { { stat = "TotalEHP", weightMult = 0.5 }, { stat = "TotalDPS", weightMult = 1.0 } },
				expected = false,
			},
			{
				label = "FullDPS among other stats",
				weights = {
					{ stat = "TotalEHP", weightMult = 0.5 },
					{ stat = "FullDPS", weightMult = 1.0 },
					{ stat = "Life", weightMult = 0.25 },
				},
				expected = true,
			},
			{ label = "zero FullDPS weight", weights = { { stat = "FullDPS", weightMult = 0 } }, expected = false },
			{ label = "custom stat", weights = { { stat = "TotalAttr", weightMult = 1.0 } }, expected = false },
		}

		for _, case in ipairs(cases) do
			assert.are.equal(case.expected, WeightedScore.weightsRequireFullDPS(case.weights), case.label)
		end
	end)
end)

describe("WeightedScore — TradeQueryGenerator delegation", function()
	local mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({
		itemsTab = {},
		GetTradeStatusOption = function() return "online" end,
	})

	it("WeightedRatioOutputs delegates ratio calculation and preserves candidate ranking", function()
		local savedMax = data.misc.maxStatIncrease
		data.misc.maxStatIncrease = 2

		local base    = { TotalDPS = 1000, TotalEHP = 500 }
		local new     = { TotalDPS = 1200, TotalEHP = 600 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 }, { stat = "TotalEHP", weightMult = 0.5 } }

		local direct    = WeightedScore.computeRatioScore(base, new, weights)
		local delegated = mock_queryGen.WeightedRatioOutputs(base, new, weights)

		data.misc.maxStatIncrease = savedMax
		assert.are.equal(direct, delegated)

		base = { TotalDPS = 1000 }
		local high    = { TotalDPS = 1500 }
		local low     = { TotalDPS = 800 }
		weights = { { stat = "TotalDPS", weightMult = 1.0 } }

		local highScore = mock_queryGen.WeightedRatioOutputs(base, high, weights)
		local lowScore  = mock_queryGen.WeightedRatioOutputs(base, low,  weights)
		assert.is_true(highScore > lowScore)
	end)
end)

describe("WeightedScore — tree integration", function()
	before_each(function()
		newBuild()
	end)

	local function findStat(statName)
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == statName then return stat end
		end
	end

	local function drainPowerBuild(stat)
		build.calcsTab.powerBuildFlag = true
		build.calcsTab.powerStat = stat or findStat("Life")
		local maxIterations = 100000
		local iterations = 0
		repeat
			build.calcsTab:BuildPower()
			iterations = iterations + 1
		until not build.calcsTab.powerBuilder or iterations >= maxIterations
	end

	it("registers WeightedScore as the final shared non-minion power stat", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.are.equal("WeightedScore", data.powerStatList[#data.powerStatList].stat)
		assert.is_nil(findStat("MinionWeightedScore"))
	end)

	it("power builder completes with an initialized non-negative WeightedScore result", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		drainPowerBuild(stat)
		assert.is_true(build.calcsTab.powerBuilderInitialized)
		assert.is_not_nil(build.calcsTab.powerMax)
		assert.is_true(build.calcsTab.powerMax.singleStat >= 0)
	end)

	it("power report requests FullDPS for WeightedScore when active weights use FullDPS", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)

		local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
		local originalNodePowerMaxDepth = build.calcsTab.nodePowerMaxDepth
		local calledUseFullDPS = { }
		build.calcsTab.nodePowerMaxDepth = 1
		build.calcsTab.GetMiscCalculator = function()
			local function calcFunc(_, useFullDPS)
				calledUseFullDPS[#calledUseFullDPS + 1] = useFullDPS
				return {
					FullDPS = 110,
					TotalEHP = 100,
					CombinedDPS = 0,
					TotalDPS = 0,
					TotalDotDPS = 0,
				}
			end
			return calcFunc, {
				FullDPS = 100,
				TotalEHP = 100,
				CombinedDPS = 0,
				TotalDPS = 0,
				TotalDotDPS = 0,
			}
		end

		local ok, errMsg = pcall(function()
			drainPowerBuild(stat)
		end)
		build.calcsTab.GetMiscCalculator = originalGetMiscCalculator
		build.calcsTab.nodePowerMaxDepth = originalNodePowerMaxDepth

		assert.is_true(ok, errMsg)
		assert.is_true(#calledUseFullDPS > 0, "fixture should exercise candidate calculations")
		for _, useFullDPS in ipairs(calledUseFullDPS) do
			assert.is_true(useFullDPS)
		end
	end)

	-- Fallback weights must evaluate the configured stats rather than a synthetic output key.
	it("power stat helpers keep positive WeightedScore deltas and baselines on the same scale", function()
		local weightedScore = findStat("WeightedScore")
		local fullDPS = findStat("FullDPS")
		local life = findStat("Life")
		local baseOutput = { FullDPS = 100, TotalEHP = 100, TotalDPS = 0, TotalDotDPS = 0, CombinedDPS = 0 }
		local betterOutput = { FullDPS = 120, TotalEHP = 100, TotalDPS = 0, TotalDotDPS = 0, CombinedDPS = 0 }

		assert.is_true(data.powerStatList.RequiresFullDPS(weightedScore, build))
		assert.is_true(data.powerStatList.RequiresFullDPS(fullDPS, build))
		assert.is_false(data.powerStatList.RequiresFullDPS(life, build))
		local baseValue = data.powerStatList.GetValue(baseOutput, weightedScore, build, baseOutput)
		local betterValue = data.powerStatList.GetValue(betterOutput, weightedScore, build, baseOutput)
		local delta = build.calcsTab:CalculatePowerStat(weightedScore, betterOutput, baseOutput)
		assert.is_true(math.abs(baseValue - 1500) < 0.0001)
		assert.is_true(math.abs(betterValue - 1700) < 0.0001)
		assert.is_true(betterValue > baseValue)
		assert.is_true(math.abs(delta - 200) < 0.0001)
		assert.is_true(math.abs(delta / baseValue - 2 / 15) < 0.0001)
		assert.are.equal(123, data.powerStatList.GetValue({ Life = 123 }, life, build, baseOutput))
	end)

	it("getValue on WeightedScore entry reuses provided calcBase", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.is_function(stat.getValue)

		local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
		local getMiscCalculatorCalls = 0
		build.calcsTab.GetMiscCalculator = function()
			getMiscCalculatorCalls = getMiscCalculatorCalls + 1
			return function()
				return { FullDPS = 1, TotalEHP = 1 }
			end, { FullDPS = 1, TotalEHP = 1 }
		end

		local score = stat.getValue(
			{ FullDPS = 120, TotalEHP = 100, TotalDPS = 0, TotalDotDPS = 0, CombinedDPS = 0 },
			build,
			{ FullDPS = 100, TotalEHP = 100, TotalDPS = 0, TotalDotDPS = 0, CombinedDPS = 0 }
		)
		build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

		assert.are.equal(0, getMiscCalculatorCalls)
		assert.is_true(score > 0)
	end)

	it("getValue on WeightedScore entry returns non-zero score for current build output", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		local calcFunc = build.calcsTab:GetMiscCalculator(build)
		local baseOutput = calcFunc()
		local score = stat.getValue(baseOutput, build)
		assert.is_true(score ~= 0)
	end)

	-- appendEditWeightsAction -----------------------------------------------
	local function buildWithWeightEditor(openEditor)
		return { itemsTab = { tradeQuery = {
			SetStatWeights = function(_, previousSelection, onSave)
				openEditor(previousSelection, onSave)
			end,
		} } }
	end

	it("appendEditWeightsAction handles lists with and without WeightedScore", function()
		local ordinaryList = {
			{ label = "Sort by Name", sortMode = "name" },
			{ label = "Sort by Life", sortMode = "Life" },
		}
		local called = false
		WeightedScore.appendEditWeightsAction(ordinaryList, function() called = true end)
		assert.are.equal(2, #ordinaryList)
		assert.is_false(called)

		local list = {
			{ label = "Sort by Name", sortMode = "name" },
			{ label = "Sort by Weighted Score", sortMode = "WeightedScore", stat = "WeightedScore" },
		}
		local opened = false
		WeightedScore.appendEditWeightsAction(list, function() opened = true end)
		assert.are.equal(3, #list)
		local entry = list[3]
		assert.is_function(entry.action)
		assert.is_string(entry.label)
		assert.are.equal("WeightedScore", list[2].stat)
		entry.action()
		assert.is_true(opened, "calling entry.action must invoke the openEditor callback")
	end)

	it("createSortHandler restores the metric and invalidates cached candidate scores after editing weights", function()
		local list = {
			{ label = "Default", stat = nil },
			{ label = "Weighted Score", stat = "WeightedScore" },
		}
		local candidates = {
			{ label = "Damage", scores = { damage = 2, defence = 1 } },
			{ label = "Defence", scores = { damage = 1, defence = 2 } },
		}
		local weight = "damage"
		local selectedStat
		local controls = {
			sort = {
				SelByValue = function(_, value)
					selectedStat = value
				end,
			},
		}
		local function applySort(stat)
			for _, candidate in ipairs(candidates) do
				candidate.sortValues = candidate.sortValues or { }
				candidate.sortValue = candidate.sortValues[stat] or candidate.scores[weight]
				candidate.sortValues[stat] = candidate.sortValue
			end
			table.sort(candidates, function(a, b) return a.sortValue > b.sortValue end)
		end
		local function clearSortValues()
			for _, candidate in ipairs(candidates) do
				candidate.sortValues = nil
			end
		end
		local build = buildWithWeightEditor(function(_, onSave)
			weight = "defence"
			onSave()
		end)
		local handler = WeightedScore.createSortHandler(list, controls, build, applySort, clearSortValues)

		handler(2, list[2])
		assert.are.equal("Damage", candidates[1].label)
		handler(3, list[3])
		assert.are.equal("WeightedScore", selectedStat)
		assert.are.equal("Defence", candidates[1].label)
	end)
end)

describe("WeightedScore — selector contracts", function()
	local function findWeightedScore(list)
		local weightedIndex
		local weightedCount = 0
		for index, entry in ipairs(list) do
			if entry.stat == "WeightedScore" then
				weightedIndex = index
				weightedCount = weightedCount + 1
			end
		end
		assert.are.equal(1, weightedCount)
		assert.is_truthy(weightedIndex)
		assert.is_truthy(list[weightedIndex + 1])
		assert.is_function(list[weightedIndex + 1].action)
		return weightedIndex
	end

	before_each(function()
		newBuild()
	end)

	it("opens weight editing from crafted modifier sorting and restores Weighted Score", function()
		local itemsTab = build.itemsTab
		itemsTab:CreateDisplayItemFromRaw([[
Rarity: RARE
Weighted Selector Helmet
Royal Burgonet
Item Level: 86
Crafted: true
Prefix: None
Prefix: None
Prefix: None
Suffix: None
Suffix: None
Suffix: None
Quality: 20
Implicits: 0
]])
		local control = itemsTab.controls.craftingSorting
		local weightedIndex = findWeightedScore(control.list)
		local opened = false
		itemsTab.tradeQuery.SetStatWeights = function(_, _, onSave)
			opened = true
			onSave()
		end

		control:SetSel(weightedIndex)
		control:SetSel(weightedIndex + 1)

		assert.is_true(opened)
		assert.are.equal("WeightedScore", control:GetSelValue().stat)
	end)

	it("opens weight editing from Compare Power and invalidates the selected report", function()
		local compareTab = build.compareTab
		local control = compareTab.controls.comparePowerStatSelect
		local weightedIndex = findWeightedScore(control.list)
		local opened = false
		build.itemsTab.tradeQuery.SetStatWeights = function(_, _, onSave)
			opened = true
			onSave()
		end

		control:SetSel(weightedIndex)
		compareTab.comparePowerDirty = false
		control:SetSel(weightedIndex + 1)

		assert.is_true(opened)
		assert.are.equal("WeightedScore", control:GetSelValue().stat)
		assert.is_true(compareTab.comparePowerDirty)
	end)
end)

describe("WeightedScore — crafted affix sorting", function()
	local originalGetMiscCalculator
	local originalGetValue

	before_each(function()
		newBuild()
		originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
		originalGetValue = data.powerStatList.GetValue
	end)

	after_each(function()
		build.calcsTab.GetMiscCalculator = originalGetMiscCalculator
		data.powerStatList.GetValue = originalGetValue
	end)

	it("evaluates baseline-dependent scores with their reference output and Full DPS requirement", function()
		local itemsTab = build.itemsTab
		itemsTab:CreateDisplayItemFromRaw([[
Rarity: RARE
Weighted Sort Helmet
Royal Burgonet
Item Level: 86
Crafted: true
Prefix: None
Prefix: None
Prefix: None
Suffix: None
Suffix: None
Suffix: None
Quality: 20
Implicits: 0
]])
		itemsTab.tradeQuery.statSortSelectionList = {
			{ stat = "FullDPS", label = "Full DPS", weightMult = 1 },
		}
		itemsTab.controls.craftingSorting:SelByValue("WeightedScore", "stat")

		local useFullDPSCalls = { }
		build.calcsTab.GetMiscCalculator = function()
			return function(params, useFullDPS)
				useFullDPSCalls[#useFullDPSCalls + 1] = useFullDPS
				return {
					modCount = params and params.repItem and #params.repItem.explicitModLines or 0,
				}
			end
		end

		local getValueCalls = 0
		local sawBaseline = false
		data.powerStatList.GetValue = function(output, statTable, ownerBuild, calcBase)
			getValueCalls = getValueCalls + 1
			sawBaseline = sawBaseline or (calcBase and calcBase.modCount == 0)
			assert.are.equal("WeightedScore", statTable.stat)
			assert.are.equal(build, ownerBuild)
			return output.modCount
		end

		local control = itemsTab.controls.displayItemAffix1
		itemsTab:UpdateAffixControl(
			control,
			itemsTab.displayItem,
			"Prefix",
			"prefixes",
			1,
			{ }
		)

		assert.is_true(getValueCalls > 0, "crafted affix sorting must evaluate baseline-dependent stats through GetValue")
		assert.is_true(sawBaseline, "baseline-dependent scoring must receive the item without the candidate affix")
		assert.is_true(#useFullDPSCalls > 0)
		for _, useFullDPS in ipairs(useFullDPSCalls) do
			assert.is_true(useFullDPS)
		end
		assert.is_not_nil(control.list[2].modList)
		local highestScoredMod = itemsTab.displayItem.affixes[control.list[2].modList[1]]
		assert.are.equal(2, #highestScoredMod, "the highest baseline-dependent score must sort first")
	end)
end)
