-- Path of Building
--
-- Module: Weighted Score
-- Shared weighted stat score computation and weight management.
-- Used by Trade Query, Unique Item DB, Gem Upgrade Report, and Tree heatmap.
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
	local tq = build and build.itemsTab and build.itemsTab.tradeQuery
	if tq and tq.statSortSelectionList and #tq.statSortSelectionList > 0 then
		return tq.statSortSelectionList
	end
	return WeightedScore.defaultWeights()
end

-- Returns true when any active weight targets FullDPS, so callers can route
-- through the FullDPS-aware calculation path.
function WeightedScore.weightsNeedFullDPS(weights)
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
	local meanStatDiff = 0.0
	local function ratioModSums(...)
		local baseModSum = 0
		local newModSum = 0
		for _, statTable in ipairs({ ... }) do
			baseModSum = baseModSum + data.powerStatList.GetFromOutput(baseOutput, statTable, true)
			newModSum = newModSum + data.powerStatList.GetFromOutput(newOutput, statTable, true)
		end
		if baseModSum == math.huge then
			return 0
		elseif newModSum == math.huge then
			return data.misc.maxStatIncrease
		else
			return math.min(newModSum / ((baseModSum ~= 0) and baseModSum or 1), data.misc.maxStatIncrease)
		end
	end
	for _, statTable in ipairs(weights) do
		local modSumRatio
		if statTable.stat == "FullDPS" and not (baseOutput["FullDPS"] and newOutput["FullDPS"]) then
			-- FullDPS fallback: use combined DPS components when FullDPS is not directly available
			modSumRatio = ratioModSums({ stat = "TotalDPS" }, { stat = "TotalDotDPS" }, { stat = "CombinedDPS" })
		else
			modSumRatio = ratioModSums(statTable)
		end
		if statTable.transform then
			modSumRatio = statTable.transform(modSumRatio)
		end
		meanStatDiff = meanStatDiff + modSumRatio * statTable.weightMult
	end
	return meanStatDiff
end

-- Append a contextual "Edit Weights..." action after WeightedScore so the
-- score remains the final metric while its configuration stays adjacent.
function WeightedScore.appendEditWeightsAction(sortDropList, openEditor)
	for _, entry in ipairs(sortDropList) do
		if entry.isWeightedScore then
			table.insert(sortDropList, {
				label = colorCodes.TIP .. "Edit Weights...",
				isAction = true,
				action = openEditor,
			})
			return
		end
	end
end

return WeightedScore
