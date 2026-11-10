-- Path of Building
--
-- Module: Trade Resistance Grouping
-- Stateless classification and grouping helpers for resistance trade query weights.
--

local M = {}

local resistanceTypes = { "Fire", "Cold", "Lightning", "Chaos" }
local elementSet = {
	Fire = true,
	Cold = true,
	Lightning = true,
}

function M.getResistanceCapShortfallByType(output)
	local shortfall = {}
	for _, resistanceType in ipairs(resistanceTypes) do
		shortfall[resistanceType] = math.max(0, output["Missing" .. resistanceType .. "Resist"] or 0)
	end
	-- Chaos Inoculation makes the build immune to chaos damage, so its Chaos cap is not a search target.
	if output.ChaosInoculation then
		shortfall.Chaos = 0
	end
	return shortfall
end

local function isElement(element)
	return elementSet[element] == true
end

local function maxField(current, entry, field)
	local value = entry[field] or 0
	return value > current and value or current
end

function M.classifyResistanceMod(modText)
	local resistanceElement = modText:match("^%+#%% to (%a+) Resistance$")
	if isElement(resistanceElement) then
		return { resistTag = { elemental = true }, normalisationFactor = 1, group = "elemental", resistanceTypes = { resistanceElement } }
	elseif resistanceElement == "Chaos" then
		return { resistTag = { chaos = true }, normalisationFactor = 1, group = "chaos", resistanceTypes = { "Chaos" } }
	end

	if modText == "+#% to all Elemental Resistances" then
		return { resistTag = { elemental = true }, normalisationFactor = 3, group = "elemental", resistanceTypes = { "Fire", "Cold", "Lightning" } }
	end
	local firstElement, secondElement = modText:match("^%+#%% to (%a+) and (%a+) Resistances$")
	if isElement(firstElement) and isElement(secondElement) then
		return { resistTag = { elemental = true }, normalisationFactor = 2, group = "elemental", resistanceTypes = { firstElement, secondElement } }
	elseif isElement(firstElement) and secondElement == "Chaos" then
		return { resistTag = { elemental = true, chaos = true }, resistanceTypes = { firstElement, "Chaos" } }
	end
end

-- Returns the resistance types that at least one mod of the item category can roll.
-- Every mod source counts, independently of the sources selected for weights,
-- because a listing can carry any of them.
function M.getRollableResistanceTypes(modData, itemCategory)
	local rollable = {}
	for _, mods in pairs(modData) do
		for _, entry in pairs(mods) do
			local classification = entry[itemCategory] and M.classifyResistanceMod(entry.tradeMod.text)
			for _, resistanceType in ipairs(classification and classification.resistanceTypes or {}) do
				rollable[resistanceType] = true
			end
		end
	end
	return rollable
end

function M.annotateResistanceWeight(weightEntry, modText)
	if type(weightEntry.tradeModId) ~= "string" then
		return weightEntry
	end
	local classification = M.classifyResistanceMod(modText)
	if classification then
		weightEntry.resistTag = classification.resistTag
		if weightEntry.tradeModId:match("^explicit%.") and classification.group then
			weightEntry.resistanceGroup = classification.group
			weightEntry.normalisedWeight = weightEntry.weight / classification.normalisationFactor
		end
	end
	return weightEntry
end

local function makePseudoWeight(id, aggregate)
	return {
		tradeModId = id,
		weight = aggregate.weight,
		meanStatDiff = aggregate.meanStatDiff,
		invert = false,
	}
end

-- Swap searches fold interchangeable elemental weights into one pseudo filter.
-- Cap searches take precedence and remove resistance weights because their
-- minimum filters are emitted separately from the current cap shortfall.
function M.applyResistanceWeightOptions(modWeights, includeResistSwaps, includeResistCaps)
	if not includeResistSwaps and not includeResistCaps then
		return modWeights
	end

	local kept = {}
	local elementalResistance = { weight = 0, meanStatDiff = 0 }
	local chaosResistance = { weight = 0, meanStatDiff = 0 }
	for _, entry in ipairs(modWeights) do
		if entry.resistTag then
			local normalisedWeight = entry.normalisedWeight or entry.weight
			if not includeResistCaps and entry.resistanceGroup == "elemental" then
				elementalResistance.weight = math.max(elementalResistance.weight, normalisedWeight)
				elementalResistance.meanStatDiff = maxField(elementalResistance.meanStatDiff, entry, "meanStatDiff")
			end
			if not includeResistCaps and entry.resistanceGroup == "chaos" then
				chaosResistance.weight = math.max(chaosResistance.weight, normalisedWeight)
				chaosResistance.meanStatDiff = maxField(chaosResistance.meanStatDiff, entry, "meanStatDiff")
			end
			if not includeResistCaps and not entry.resistanceGroup then
				table.insert(kept, entry)
			end
		else
			table.insert(kept, entry)
		end
	end

	if elementalResistance.weight > 0 then
		table.insert(kept, makePseudoWeight("pseudo.pseudo_total_elemental_resistance", elementalResistance))
	end
	if chaosResistance.weight > 0 then
		table.insert(kept, makePseudoWeight("pseudo.pseudo_total_chaos_resistance", chaosResistance))
	end
	return kept
end

return M
