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
end)

describe("WeightedScore — TradeQueryGenerator delegation", function()
	local mock_queryGen = new("TradeQueryGenerator", {
		itemsTab = {},
		GetTradeStatusOption = function() return "online" end,
	})

	-- Pass: WeightedRatioOutputs returns the same value as calling
	--       WeightedScore.computeRatioScore directly, confirming delegation
	-- Fail: divergence would indicate the wrapper has extra logic or a copy-paste
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

	-- Pass: higher-stat candidate ranks above lower-stat candidate
	-- Fail: regression in delegation would silently return 0 for all, making order random
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

	-- Pass: WeightedScore entry is registered in the shared power stat list
	-- Fail: missing registration would mean the mode never appears in the UI
	it("WeightedScore entry exists in data.powerStatList with isWeightedScore flag", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.is_true(stat.isWeightedScore)
	end)

	-- Pass: power builder runs to completion without Lua error
	-- Fail: a crash in CalculatePowerStat's isWeightedScore branch
	it("power builder completes without error using WeightedScore stat", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		drainPowerBuild(stat)
		assert.is_true(build.calcsTab.powerBuilderInitialized)
	end)

	-- Pass: powerMax is initialized and singleStat is non-negative
	-- Fail: negative singleStat would break heatmap colour scaling
	it("powerMax.singleStat is non-negative after WeightedScore build", function()
		drainPowerBuild(findStat("WeightedScore"))
		assert.is_not_nil(build.calcsTab.powerMax)
		assert.is_true(build.calcsTab.powerMax.singleStat >= 0)
	end)

	-- Pass: getValue returns a positive score when the new output is better than base
	-- Fail: reading output["WeightedScore"] (non-existent field) would return 0, giving
	--       weight1 = (0/1 - 1)*100 = -100 for every fallback node regardless of actual impact
	it("getValue on WeightedScore entry returns positive score for better output", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.is_function(stat.getValue)
		local calcFunc = build.calcsTab:GetMiscCalculator(build)
		local baseOutput = calcFunc()
		-- Synthesize a "better" output by doubling FullDPS relative to base
		local betterOutput = setmetatable({}, { __index = baseOutput })
		betterOutput.FullDPS = (baseOutput.FullDPS or 0) * 2 + 1
		local baseScore   = stat.getValue(baseOutput, build)
		local betterScore = stat.getValue(betterOutput, build)
		assert.is_true(betterScore > baseScore)
	end)

	-- Pass: getValue returns a non-zero base score (build has some meaningful output)
	-- Fail: if getValue silently returned 0 for base, generateFallbackWeights would
	--       set baseValue=1 and all weights would be computed against 1 instead of the
	--       real build score, producing incorrect -100 values for all neutral nodes
	it("getValue on WeightedScore entry returns non-zero score for current build output", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		local calcFunc = build.calcsTab:GetMiscCalculator(build)
		local baseOutput = calcFunc()
		local score = stat.getValue(baseOutput, build)
		assert.is_true(score ~= 0)
	end)
end)
