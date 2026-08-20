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

	it("getWeights returns defaults when build is nil", function()
		local weights = WeightedScore.getWeights(nil)
		assert.are.same(WeightedScore.defaultWeights(), weights)
	end)

	it("getWeights returns defaults when statSortSelectionList is empty", function()
		local mockBuild = {
			itemsTab = {
				tradeQuery = { statSortSelectionList = {} }
			}
		}
		local weights = WeightedScore.getWeights(mockBuild)
		assert.are.same(WeightedScore.defaultWeights(), weights)
	end)

	it("getWeights returns custom weights when statSortSelectionList is populated", function()
		local custom = { { stat = "TotalDPS", label = "DPS", weightMult = 2.0 } }
		local mockBuild = {
			itemsTab = {
				tradeQuery = { statSortSelectionList = custom }
			}
		}
		local weights = WeightedScore.getWeights(mockBuild)
		assert.are.equal(1, #weights)
		assert.are.equal("TotalDPS", weights[1].stat)
		assert.are.equal(2.0, weights[1].weightMult)
	end)

	-- computeRatioScore: basic ranking -----------------------------------------

	it("neutral candidate (identical outputs) scores 1.0 with single unit weight", function()
		local base = { TotalDPS = 1000 }
		local new  = { TotalDPS = 1000 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		assert.are.equal(1.0, WeightedScore.computeRatioScore(base, new, weights))
	end)

	it("better candidate scores higher than neutral", function()
		local base    = { TotalDPS = 1000 }
		local better  = { TotalDPS = 1500 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		local score   = WeightedScore.computeRatioScore(base, better, weights)
		assert.is_true(score > 1.0)
		assert.are.equal(1.5, score)
	end)

	it("worse candidate scores lower than neutral", function()
		local base    = { TotalDPS = 1000 }
		local worse   = { TotalDPS = 500 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		local score   = WeightedScore.computeRatioScore(base, worse, weights)
		assert.is_true(score < 1.0)
		assert.are.equal(0.5, score)
	end)

	it("combines multiple stats with their individual weight multipliers", function()
		local base = { TotalDPS = 100, TotalEHP = 200 }
		local candidate = { TotalDPS = 150, TotalEHP = 250 }
		local weights = {
			{ stat = "TotalDPS", weightMult = 1.5 },
			{ stat = "TotalEHP", weightMult = 0.25 },
		}

		-- (150 / 100) * 1.5 + (250 / 200) * 0.25 = 2.5625
		assert.are.equal(2.5625, WeightedScore.computeRatioScore(base, candidate, weights))
	end)

	it("empty weights always scores 0", function()
		local base = { TotalDPS = 1000 }
		local new  = { TotalDPS = 5000 }
		assert.are.equal(0.0, WeightedScore.computeRatioScore(base, new, {}))
	end)

	-- computeRatioScore: edge cases --------------------------------------------

	it("infinite base stat contributes 0 (no crash)", function()
		local base    = { TotalDPS = math.huge }
		local new     = { TotalDPS = 1000 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		assert.are.equal(0.0, WeightedScore.computeRatioScore(base, new, weights))
	end)

	it("infinite new stat is capped at maxStatIncrease", function()
		local base    = { TotalDPS = 1000 }
		local new     = { TotalDPS = math.huge }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		-- maxStatIncrease == 2 (set in before_each)
		assert.are.equal(2.0, WeightedScore.computeRatioScore(base, new, weights))
	end)

	it("zero base stat treats denominator as 1 and caps at maxStatIncrease (no div-by-zero crash)", function()
		local base    = { TotalDPS = 0 }
		local new     = { TotalDPS = 500 }  -- 500/1 = 500, capped at 2
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		assert.are.equal(2.0, WeightedScore.computeRatioScore(base, new, weights))
	end)

	it("missing stat in both base and new scores 0 (no crash)", function()
		local base    = {}
		local new     = {}
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }
		-- 0/1 = 0
		assert.are.equal(0.0, WeightedScore.computeRatioScore(base, new, weights))
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

	-- weightsNeedFullDPS: routing helper used by PowerBuilder ------------------

	it("weightsNeedFullDPS returns false for nil weights", function()
		assert.is_false(WeightedScore.weightsNeedFullDPS(nil))
	end)

	it("weightsNeedFullDPS returns false for empty weights", function()
		assert.is_false(WeightedScore.weightsNeedFullDPS({}))
	end)

	it("weightsNeedFullDPS returns true when FullDPS is the only weight", function()
		local weights = { { stat = "FullDPS", weightMult = 1.0 } }
		assert.is_true(WeightedScore.weightsNeedFullDPS(weights))
	end)

	it("weightsNeedFullDPS returns false when only non-FullDPS weights are present", function()
		local weights = {
			{ stat = "TotalEHP", weightMult = 0.5 },
			{ stat = "TotalDPS", weightMult = 1.0 },
		}
		assert.is_false(WeightedScore.weightsNeedFullDPS(weights))
	end)

	it("weightsNeedFullDPS returns true when FullDPS appears alongside other weights", function()
		local weights = {
			{ stat = "TotalEHP", weightMult = 0.5 },
			{ stat = "FullDPS", weightMult = 1.0 },
			{ stat = "Life", weightMult = 0.25 },
		}
		assert.is_true(WeightedScore.weightsNeedFullDPS(weights))
	end)

	it("weightsNeedFullDPS returns false when FullDPS weight is zero", function()
		local weights = { { stat = "FullDPS", weightMult = 0 } }
		assert.is_false(WeightedScore.weightsNeedFullDPS(weights))
	end)

	it("weightsNeedFullDPS returns false for custom-stat-only weights", function()
		local weights = { { stat = "TotalAttr", weightMult = 1.0 } }
		assert.is_false(WeightedScore.weightsNeedFullDPS(weights))
	end)
end)

describe("WeightedScore — TradeQueryGenerator delegation", function()
	local mock_queryGen = new("TradeQueryGenerator"):TradeQueryGenerator({
		itemsTab = {},
		GetTradeStatusOption = function() return "online" end,
	})

	it("WeightedRatioOutputs delegates to WeightedScore.computeRatioScore", function()
		local savedMax = data.misc.maxStatIncrease
		data.misc.maxStatIncrease = 2

		local base    = { TotalDPS = 1000, TotalEHP = 500 }
		local new     = { TotalDPS = 1200, TotalEHP = 600 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 }, { stat = "TotalEHP", weightMult = 0.5 } }

		local direct    = WeightedScore.computeRatioScore(base, new, weights)
		local delegated = mock_queryGen.WeightedRatioOutputs(base, new, weights)

		data.misc.maxStatIncrease = savedMax
		assert.are.equal(direct, delegated)
	end)

	it("higher-stat candidate ranks above lower-stat candidate", function()
		local base    = { TotalDPS = 1000 }
		local high    = { TotalDPS = 1500 }
		local low     = { TotalDPS = 800 }
		local weights = { { stat = "TotalDPS", weightMult = 1.0 } }

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
		local maxIter = 100000
		local iter = 0
		repeat
			build.calcsTab:BuildPower()
			iter = iter + 1
		until not build.calcsTab.powerBuilder or iter >= maxIter
	end

	it("registers WeightedScore as the final shared power stat", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.are.equal("WeightedScore", data.powerStatList[#data.powerStatList].stat)
	end)

	it("does not create a Minion WeightedScore entry", function()
		assert.is_nil(findStat("MinionWeightedScore"))
	end)

	it("power builder completes without error using WeightedScore stat", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		drainPowerBuild(stat)
		assert.is_true(build.calcsTab.powerBuilderInitialized)
	end)

	it("powerMax.singleStat is non-negative after WeightedScore build", function()
		drainPowerBuild(findStat("WeightedScore"))
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
	it("getValue on WeightedScore entry returns positive score for better output", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.is_function(stat.getValue)
		local baseOutput = { FullDPS = 100, TotalEHP = 100 }
		local betterOutput = { FullDPS = 201, TotalEHP = 100 }
		local baseScore = stat.getValue(baseOutput, build, baseOutput)
		local betterScore = stat.getValue(betterOutput, build, baseOutput)
		assert.is_true(betterScore > baseScore)
	end)

	it("power stat helpers keep WeightedScore deltas and baselines on the same scale", function()
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

	it("appendEditWeightsAction is a no-op when the list has no WeightedScore entry", function()
		local list = {
			{ label = "Sort by Name", sortMode = "name" },
			{ label = "Sort by Life", sortMode = "Life" },
		}
		local called = false
		WeightedScore.appendEditWeightsAction(list, function() called = true end)
		assert.are.equal(2, #list)
		assert.is_false(called)
	end)

	it("appendEditWeightsAction appends an action after WeightedScore", function()
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
		local handler = WeightedScore.createSortHandler(list, controls, function(onSave)
			weight = "defence"
			onSave()
		end, applySort, clearSortValues)

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

	it("evaluates contextual scores with their baseline and Full DPS requirement", function()
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

		assert.is_true(getValueCalls > 0, "crafted affix sorting must evaluate contextual stats through GetValue")
		assert.is_true(sawBaseline, "contextual scoring must receive the item without the candidate affix")
		assert.is_true(#useFullDPSCalls > 0)
		for _, useFullDPS in ipairs(useFullDPSCalls) do
			assert.is_true(useFullDPS)
		end
		assert.is_not_nil(control.list[2].modList)
		local highestScoredMod = itemsTab.displayItem.affixes[control.list[2].modList[1]]
		assert.are.equal(2, #highestScoredMod, "the highest contextual score must sort first")
	end)
end)
