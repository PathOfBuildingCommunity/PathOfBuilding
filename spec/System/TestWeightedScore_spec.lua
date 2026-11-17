local WeightedScore = LoadModule("Modules/WeightedScore")

describe("WeightedScore module", function()
	it("provides default and configured weights", function()
		local defaults = WeightedScore.defaultWeights()
		assert.are.equal(2, #defaults)
		assert.are.equal("FullDPS", defaults[1].stat)
		assert.are.equal("TotalEHP", defaults[2].stat)

		local custom = { { stat = "TotalDPS", label = "DPS", weightMult = 2.0 } }
		local cases = {
			{ label = "nil build", expected = defaults },
			{
				label = "empty selection",
				build = { itemsTab = { tradeQuery = { statSortSelectionList = {} } } },
				expected = defaults,
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

	it("weightsRequireFullDPS identifies active FullDPS weights", function()
		local cases = {
			{
				label = "ordinary stats",
				weights = { { stat = "TotalEHP", weightMult = 0.5 }, { stat = "TotalDPS", weightMult = 1.0 } },
				expected = false,
			},
			{
				label = "FullDPS among other stats",
				weights = { { stat = "TotalEHP", weightMult = 0.5 }, { stat = "FullDPS", weightMult = 1.0 } },
				expected = true,
			},
			{ label = "zero FullDPS weight", weights = { { stat = "FullDPS", weightMult = 0 } }, expected = false },
		}

		for _, case in ipairs(cases) do
			assert.are.equal(case.expected, WeightedScore.weightsRequireFullDPS(case.weights), case.label)
		end
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
		build.calcsTab.powerStat = stat
		build.calcsTab.nodePowerMaxDepth = 1
		local iterations = 0
		repeat
			build.calcsTab:BuildPower()
			iterations = iterations + 1
		until not build.calcsTab.powerBuilder or iterations >= 1000
		assert.is_nil(build.calcsTab.powerBuilder, "depth-1 Power Builder must finish within 1000 steps")
	end

	it("registers WeightedScore as the final shared non-minion power stat", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)
		assert.are.equal("WeightedScore", data.powerStatList[#data.powerStatList].stat)
		assert.is_nil(findStat("MinionWeightedScore"))
	end)

	it("power report requests FullDPS for WeightedScore when active weights use FullDPS", function()
		local stat = findStat("WeightedScore")
		assert.is_not_nil(stat)

		local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
		local calledUseFullDPS = { }
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

		drainPowerBuild(stat)
		build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

		assert.is_true(#calledUseFullDPS > 0, "fixture should exercise candidate calculations")
		for _, useFullDPS in ipairs(calledUseFullDPS) do
			assert.is_true(useFullDPS)
		end
	end)

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
		build.itemsTab.tradeQuery.statSortSelectionList = { { stat = "TotalEHP", weightMult = 1 } }
		assert.is_false(data.powerStatList.RequiresFullDPS(weightedScore, build))
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

	local function buildWithWeightEditor(openEditor)
		return { itemsTab = { tradeQuery = {
			SetStatWeights = function(_, previousSelection, onSave)
				openEditor(previousSelection, onSave)
			end,
		} } }
	end

	it("invalidates cached candidate scores after editing weights", function()
		local list = {
			{ label = "Default", stat = nil },
			{ label = "Weighted Score", stat = "WeightedScore" },
		}
		local candidates = {
			{ label = "Damage", scores = { damage = 2, defence = 1 } },
			{ label = "Defence", scores = { damage = 1, defence = 2 } },
		}
		local weight = "damage"
		local controls = {
			sort = {
				SelByValue = function() end,
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
		assert.are.equal("Defence", candidates[1].label)
	end)
end)

describe("WeightedScore — report invalidation", function()
	before_each(function()
		newBuild()
	end)

	it("invalidates the selected Compare Power report after editing weights", function()
		local compareTab = build.compareTab
		local control = compareTab.controls.comparePowerStatSelect
		local weightedIndex
		for index, entry in ipairs(control.list) do
			if entry.stat == "WeightedScore" then
				weightedIndex = index
				break
			end
		end
		build.itemsTab.tradeQuery.SetStatWeights = function(_, _, onSave)
			onSave()
		end

		control:SetSel(weightedIndex)
		compareTab.comparePowerDirty = false
		control:SetSel(weightedIndex + 1)

		assert.is_true(compareTab.comparePowerDirty)
	end)
end)

describe("WeightedScore — crafted affix sorting", function()
	local originalGetMiscCalculator

	before_each(function()
		newBuild()
		originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
	end)

	after_each(function()
		build.calcsTab.GetMiscCalculator = originalGetMiscCalculator
	end)

	it("sorts crafted affixes against the displayed item", function()
		local itemsTab = build.itemsTab
		itemsTab:CreateDisplayItemFromRaw([[
Rarity: RARE
Weighted Sort Helmet
Royal Burgonet
Item Level: 86
Crafted: true
Prefix: {range:0.5}IncreasedLife6
Prefix: None
Prefix: None
Suffix: None
Suffix: None
Suffix: None
Quality: 20
Implicits: 0
+65 to maximum Life
]])
		itemsTab.tradeQuery.statSortSelectionList = {
			{ stat = "FullDPS", label = "Full DPS", weightMult = 1 },
			{ stat = "TotalEHP", label = "Effective Hit Pool", weightMult = 1 },
		}
		itemsTab.controls.craftingSorting:SelByValue("WeightedScore", "stat")

		local calcCount = 0
		build.calcsTab.GetMiscCalculator = function()
			return function(params)
				calcCount = calcCount + 1
				local item = params and params.repItem
				local modCount = item and #item.explicitModLines or 0
				if item == itemsTab.displayItem then
					return { FullDPS = 200, TotalEHP = 100 }
				elseif modCount >= 2 then
					return { FullDPS = 180, TotalEHP = 120 }
				elseif modCount == 1 then
					return { FullDPS = 150, TotalEHP = 140 }
				end
				return { FullDPS = 100, TotalEHP = 100 }
			end
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

		assert.is_true(calcCount > 0)
		assert.is_not_nil(control.list[2].modList)
		local highestScoredMod = itemsTab.displayItem.affixes[control.list[2].modList[1]]
		assert.are.equal(1, #highestScoredMod, "the best modifier for the displayed item must sort first")
	end)
end)
