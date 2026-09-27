-- Path of Building
--
-- Module: Weighted Score
-- Shared weighted stat score computation and weight management for stat-based ranking.
--

local WeightedScore = {}

-- Default stat weight configuration used when no custom weights are saved.
function WeightedScore.defaultWeights()
	return {
		{ stat = "FullDPS", label = "Full DPS", weightMult = 1.0 },
		{ stat = "TotalEHP", label = "Effective Hit Pool", weightMult = 0.5 },
	}
end

-- Returns the current stat weight list from the build's trade query settings,
-- falling back to defaults if none are configured or the build is not available.
function WeightedScore.getWeights(build)
	local tradeQuery = build and build.itemsTab and build.itemsTab.tradeQuery
	if tradeQuery and tradeQuery.statSortSelectionList and #tradeQuery.statSortSelectionList > 0 then
		return tradeQuery.statSortSelectionList
	end
	return WeightedScore.defaultWeights()
end

-- Open the shared Trade Query weight editor. onSave only runs after Save, so
-- consumers can invalidate derived scores without reacting to Cancel.
function WeightedScore.editWeights(build, onSave)
	local tradeQuery = build and build.itemsTab and build.itemsTab.tradeQuery
	if tradeQuery then
		tradeQuery:SetStatWeights(nil, onSave)
	end
end

-- Returns true when any active weight targets FullDPS, so callers can route
-- through the FullDPS-aware calculation path.
function WeightedScore.weightsRequireFullDPS(weights)
	if not weights then
		return false
	end
	for _, statTable in ipairs(weights) do
		if statTable and statTable.stat == "FullDPS" and (statTable.weightMult == nil or statTable.weightMult ~= 0) then
			return true
		end
	end
	return false
end

-- Compute a weighted ratio score comparing newOutput to baseOutput.
-- Each stat contributes: weight * (new output / base output), using the
-- shared power-stat accessor so minion and transformed stats match Trade Query.
-- A neutral candidate (same as base) scores approximately sum(weights).
-- Higher score means the candidate is better.
-- Missing or zero stats are handled safely (no crash, no infinite values).
function WeightedScore.computeRatioScore(baseOutput, newOutput, weights)
	local weightedScore = 0.0
	local function computeStatSumRatio(...)
		local baseStatSum = 0
		local candidateStatSum = 0
		for _, statTable in ipairs({ ... }) do
			baseStatSum = baseStatSum + data.powerStatList.GetFromOutput(baseOutput, statTable, true)
			candidateStatSum = candidateStatSum + data.powerStatList.GetFromOutput(newOutput, statTable, true)
		end
		if baseStatSum == math.huge then
			return 0
		elseif candidateStatSum == math.huge then
			return data.misc.maxStatIncrease
		else
			return math.min(candidateStatSum / ((baseStatSum ~= 0) and baseStatSum or 1), data.misc.maxStatIncrease)
		end
	end
	for _, statTable in ipairs(weights) do
		local statSumRatio
		if statTable.stat == "FullDPS" and not (baseOutput["FullDPS"] and newOutput["FullDPS"]) then
			-- FullDPS fallback: use combined DPS components when FullDPS is not directly available
			statSumRatio = computeStatSumRatio({ stat = "TotalDPS" }, { stat = "TotalDotDPS" }, { stat = "CombinedDPS" })
		else
			statSumRatio = computeStatSumRatio(statTable)
		end
		if statTable.transform then
			statSumRatio = statTable.transform(statSumRatio)
		end
		weightedScore = weightedScore + statSumRatio * statTable.weightMult
	end
	return weightedScore
end

-- Append "Edit Weights..." after WeightedScore so the
-- score remains the final metric while its configuration stays adjacent.
function WeightedScore.appendEditWeightsAction(sortDropList, openEditor)
	for _, entry in ipairs(sortDropList) do
		if entry.stat == "WeightedScore" then
			table.insert(sortDropList, {
				label = colorCodes.TIP .. "Edit Weights...",
				action = openEditor,
			})
			return
		end
	end
end

-- Keep the selected metric while opening the editor. Saving clears cached
-- candidate scores before reapplying that metric; cancelling leaves them intact.
function WeightedScore.createSortHandler(sortDropList, controls, build, applySort, clearSortValues)
	local activeSort = sortDropList[1]
	WeightedScore.appendEditWeightsAction(sortDropList, function()
		controls.sort:SelByValue(activeSort.stat, "stat")
		WeightedScore.editWeights(build, function()
			clearSortValues()
			applySort(activeSort.stat, true)
		end)
	end)
	return function(index, value)
		if value.action then
			value.action()
		else
			activeSort = value
			applySort(value.stat, true)
		end
	end
end

return WeightedScore
