-- Path of Building
--
-- Module: Radius Jewel Data
-- Jewel type definitions, variants, scoring functions, and preview helpers
-- for the Radius Jewel Finder.
--
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local s_format = string.format

local M = { }

-- Outer boundary for the full Massive radius used by the Foulborn Intuitive Leap effect.
M.FULL_MASSIVE_RADIUS = 2400

-- ─────────────────────────────────────────────────────────────────────────────
-- Color constants
-- ─────────────────────────────────────────────────────────────────────────────

M.COL_UNIQUE = "^xAF6025"
M.COL_MOD    = "^7"
M.COL_META   = "^8"
M.COL_NEG    = "^1"

local COL_UNIQUE = M.COL_UNIQUE
local COL_MOD    = M.COL_MOD
local COL_META   = M.COL_META
local COL_NEG    = M.COL_NEG

-- ─────────────────────────────────────────────────────────────────────────────
-- Unique raw text lookup
-- ─────────────────────────────────────────────────────────────────────────────

local uniqueRawTextByName
local uniqueRawTextByNameAndBase
local uniqueVariantRawTextCache = { }

local function buildUniqueRawTextIndex()
	local rawByName = { }
	local rawByNameAndBase = { }
	for _, uniqueList in pairs(data.uniques or { }) do
		if type(uniqueList) == "table" then
			for _, rawText in ipairs(uniqueList) do
				if type(rawText) == "string" then
					local name, baseName = rawText:match("^([^\n]+)\n([^\n]+)")
					if name and not rawByName[name] then
						rawByName[name] = rawText
					end
					if name and baseName then
						rawByNameAndBase[name] = rawByNameAndBase[name] or { }
						if not rawByNameAndBase[name][baseName] then
							rawByNameAndBase[name][baseName] = rawText
						end
					end
				end
			end
		end
	end
	return rawByName, rawByNameAndBase
end

local function getUniqueRawText(name, fallbackRawText, baseName)
	if not uniqueRawTextByName then
		uniqueRawTextByName, uniqueRawTextByNameAndBase = buildUniqueRawTextIndex()
	end
	if baseName and uniqueRawTextByNameAndBase[name] and uniqueRawTextByNameAndBase[name][baseName] then
		return uniqueRawTextByNameAndBase[name][baseName]
	end
	return uniqueRawTextByName[name] or fallbackRawText
end

local function getUniqueVariantRawText(name, variantSelector, fallbackRawText, baseName)
	if not variantSelector then
		return getUniqueRawText(name, fallbackRawText, baseName)
	end
	local cacheKey = s_format("%s|%s|%s", name, baseName or "", tostring(variantSelector))
	if uniqueVariantRawTextCache[cacheKey] then
		return uniqueVariantRawTextCache[cacheKey]
	end
	local rawText = getUniqueRawText(name, fallbackRawText, baseName)
	if not rawText then
		return nil
	end
	local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
	local selectedVariant
	if type(variantSelector) == "number" then
		selectedVariant = variantSelector
	elseif item.variantList then
		for idx, variantName in ipairs(item.variantList) do
			if variantName == variantSelector then
				selectedVariant = idx
				break
			end
		end
	end
	if not selectedVariant then
		return fallbackRawText or rawText
	end
	item.variant = selectedVariant
	local builtRaw = item:BuildRaw():gsub("^Rarity: %w+\n", "")
	uniqueVariantRawTextCache[cacheKey] = builtRaw
	return builtRaw
end

local function mustGetUniqueRawText(name, baseName)
	local rawText = getUniqueRawText(name, nil, baseName)
	assert(rawText, "Missing unique raw text: " .. name .. (baseName and (" [" .. baseName .. "]") or ""))
	return rawText
end

local function mustGetUniqueVariantRawText(name, variantSelector, baseName)
	local rawText = getUniqueVariantRawText(name, variantSelector, nil, baseName)
	assert(rawText, "Missing unique variant raw text: " .. name .. " [" .. tostring(variantSelector) .. "]" .. (baseName and (" [" .. baseName .. "]") or ""))
	return rawText
end

local function mustGetCurrentUniqueRawText(name, baseName)
	return mustGetUniqueVariantRawText(name, "Current", baseName)
end

local function getRadiusIndexFromRawText(rawText)
	if not rawText then
		return nil
	end
	local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
	return item.jewelRadiusIndex
end

local function getUniqueRadiusIndex(name, baseName)
	return getRadiusIndexFromRawText(mustGetCurrentUniqueRawText(name, baseName))
end

local function makeUniqueVariant(name, uniqueName, baseName)
	local rawText = mustGetCurrentUniqueRawText(uniqueName or name, baseName)
	return {
		name = name,
		rawText = rawText,
		radiusIndex = getRadiusIndexFromRawText(rawText),
	}
end

-- Expose for compute module and tests
M.mustGetUniqueRawText = mustGetUniqueRawText

-- ─────────────────────────────────────────────────────────────────────────────
-- Variant helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function buildVariantsFromUniqueItem(uniqueName, baseName)
	local variants = { }
	local baseRawText = mustGetUniqueRawText(uniqueName, baseName)
	local item = new("Item"):Item("Rarity: Unique\n" .. baseRawText)
	if item.variantList then
		for idx, variantName in ipairs(item.variantList) do
			local rawText = getUniqueVariantRawText(uniqueName, idx, nil, baseName)
			if rawText then
				t_insert(variants, {
					name = variantName,
					rawText = rawText,
					radiusIndex = getRadiusIndexFromRawText(rawText),
				})
			end
		end
	end
	return variants
end

M.buildVariantsFromUniqueItem = buildVariantsFromUniqueItem

-- ─────────────────────────────────────────────────────────────────────────────
-- Scoring functions
-- ─────────────────────────────────────────────────────────────────────────────

local function scoreGainLoss(nodes, allocNodes, gainType, lossType)
	local gained, lost = 0, 0
	for nodeId, node in pairs(nodes) do
		if not node.ascendancyName and gainType and node.type == gainType and not allocNodes[nodeId] then
			gained = gained + 1
		end
		if not node.ascendancyName and lossType and node.type == lossType and allocNodes[nodeId] then
			lost = lost + 1
		end
	end
	return gained - lost
end

local function scoreAllocPassives(nodes, allocNodes)
	local s = 0
	for nodeId, node in pairs(nodes) do
		if not node.ascendancyName and allocNodes[nodeId] and node.type ~= "Socket" and node.type ~= "ClassStart"
				and node.type ~= "AscendClassStart" and node.type ~= "Mastery" then
			s = s + 1
		end
	end
	return s
end

M.scoreAllocPassives = scoreAllocPassives

local function scoreUnallocPassives(nodes, allocNodes)
	local s = 0
	for nodeId, node in pairs(nodes) do
		if not node.ascendancyName and not allocNodes[nodeId] and node.type ~= "Socket" and node.type ~= "ClassStart"
				and node.type ~= "AscendClassStart" and node.type ~= "Mastery" then
			s = s + 1
		end
	end
	return s
end

local function scoreUnallocNotablesAndKeystones(nodes, allocNodes)
	local s = 0
	for nodeId, node in pairs(nodes) do
		if not allocNodes[nodeId] and (node.type == "Notable" or node.type == "Keystone") then
			s = s + 1
		end
	end
	return s
end

local function getRadiusPassiveAttributeTotals(nodes, allocNodes, attribute)
	local allocated = 0
	local unallocated = 0
	for nodeId, node in pairs(nodes) do
		if not node.ascendancyName and node.type ~= "Socket" and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			local amount = node.modList and node.modList:Sum("BASE", nil, attribute) or 0
			if amount ~= 0 then
				if allocNodes[nodeId] then
					allocated = allocated + amount
				else
					unallocated = unallocated + amount
				end
			end
		end
	end
	return allocated, unallocated
end

local function scoreRadiusAttributes(nodes, allocNodes, attribute, includeAllocated, includeUnallocated)
	local allocated, unallocated = getRadiusPassiveAttributeTotals(nodes, allocNodes, attribute)
	local score = 0
	if includeAllocated then
		score = score + allocated
	end
	if includeUnallocated then
		score = score + unallocated
	end
	return score
end

local function makeRadiusAttributeDetail(attributeLabel, includeAllocated, includeUnallocated)
	return function(nodes, allocNodes)
		local allocated, unallocated = getRadiusPassiveAttributeTotals(nodes, allocNodes, attributeLabel)
		if includeAllocated and includeUnallocated then
			return s_format("%s alloc %d | %s unalloc %d", attributeLabel, allocated, attributeLabel, unallocated)
		elseif includeAllocated then
			return s_format("%s alloc %d", attributeLabel, allocated)
		end
		return s_format("%s unalloc %d", attributeLabel, unallocated)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Foulborn finder variants
-- ─────────────────────────────────────────────────────────────────────────────
-- PoB now models Foulborn by toggling individual modifier lines. The finder
-- supports only radius-jewel families whose radius remains represented by Item.
local FOULBORN_EXCLUDED_UNIQUES = {
	["Might of the Meek"] = true,
}

local FOULBORN_UNNATURAL_GAIN_NOTABLE = "MutatedUniqueJewel125GrantsAllBonusesOfUnallocatedNotablesInRadius"
local FOULBORN_UNNATURAL_LOSE_NOTABLE = "MutatedUniqueJewel125AllocatedNotablePassiveSkillsInRadiusDoNothing"
local FOULBORN_INSPIRED_SMALL_PASSIVES = "MutatedUniqueJewel3GainRandomRareMonsterModOnKillWhileXSmallPassivesAllocatedInRadius"
local FOULBORN_INTUITIVE_KEYSTONES = "MutatedUniqueJewel6KeystoneCanBeAllocatedInMassiveRadiusWithoutBeingConnected"

local function hasFoulbornMutation(variant, modId)
	for _, newModId in ipairs(variant.newModIds or { }) do
		if newModId == modId then
			return true
		end
	end
	return false
end

local function addUnnaturalInstinctFoulbornFields(variant)
	local gainType = hasFoulbornMutation(variant, FOULBORN_UNNATURAL_GAIN_NOTABLE) and "Notable" or "Normal"
	local loseType = hasFoulbornMutation(variant, FOULBORN_UNNATURAL_LOSE_NOTABLE) and "Notable" or "Normal"
	local gainShort = gainType == "Notable" and "notable" or "small"
	local loseShort = loseType == "Notable" and "notable" or "small"
	variant.scoreLabel = "unalloc " .. gainShort .. " - alloc " .. loseShort
	variant.score = function(nodes, allocNodes)
		return scoreGainLoss(nodes, allocNodes, gainType, loseType)
	end
end

local function addInspiredLearningFoulbornFields(variant)
	if not hasFoulbornMutation(variant, FOULBORN_INSPIRED_SMALL_PASSIVES) then
		return
	end
	variant.scoreLabel = "alloc small passives"
	variant.score = function(nodes, allocNodes)
		local s = 0
		for nodeId, node in pairs(nodes) do
			if allocNodes[nodeId] and node.type == "Normal" then
				s = s + 1
			end
		end
		return s
	end
end

local function addIntuitiveLeapFoulbornFields(variant)
	if not hasFoulbornMutation(variant, FOULBORN_INTUITIVE_KEYSTONES) then
		return
	end
	-- Massive radius is part of the Foulborn effect, not a parsed item mod line.
	variant.isMassiveRadius = true
	variant.keystoneOnly = true
	variant.previewMeta = { "Massive Radius", "Keystone Passive Skills only" }
	variant.scoreLabel = "unalloc keystones"
	variant.score = function(nodes, allocNodes)
		local s = 0
		for nodeId, node in pairs(nodes) do
			if not allocNodes[nodeId] and node.type == "Keystone" then
				s = s + 1
			end
		end
		return s
	end
end

local function addFoulbornFields(uniqueName, variant)
	if uniqueName == "Unnatural Instinct" then
		addUnnaturalInstinctFoulbornFields(variant)
	elseif uniqueName == "Inspired Learning" then
		addInspiredLearningFoulbornFields(variant)
	elseif uniqueName == "Intuitive Leap" then
		addIntuitiveLeapFoulbornFields(variant)
	end
end

local function getFoulbornMutationPairs(uniqueName, foulbornMap)
	local mutationMap = foulbornMap[uniqueName]
	local mutationPairs = { }
	if not mutationMap then
		return mutationPairs
	end
	for originalModId, newModId in pairs(mutationMap) do
		t_insert(mutationPairs, { originalModId = originalModId, newModId = newModId })
	end
	t_sort(mutationPairs, function(a, b) return a.newModId < b.newModId end)
	return mutationPairs
end

local function getFoulbornVariantLabel(newModIds)
	local labels = { }
	for _, newModId in ipairs(newModIds) do
		local mod = data.itemMods.Foulborn[newModId]
		t_insert(labels, mod and mod[1] or newModId)
	end
	return "Foulborn: " .. table.concat(labels, " + ")
end

local function buildFoulbornVariants(uniqueName, baseName, foulbornMap)
	if FOULBORN_EXCLUDED_UNIQUES[uniqueName] then
		return { }
	end
	foulbornMap = foulbornMap or data.foulbornMap or { }
	local mutationPairs = getFoulbornMutationPairs(uniqueName, foulbornMap)
	local variants = { }
	if #mutationPairs == 0 then
		return variants
	end
	local combinationCount = 2 ^ #mutationPairs - 1
	local baseRawText = mustGetCurrentUniqueRawText(uniqueName, baseName)
	for combination = 1, combinationCount do
		local item = new("Item"):Item("Rarity: Unique\n" .. baseRawText)
		local newModIds = { }
		for index, mutationPair in ipairs(mutationPairs) do
			if math.floor(combination / 2 ^ (index - 1)) % 2 == 1 then
				item:MutateMod(mutationPair.originalModId, mutationPair.newModId, true)
				t_insert(newModIds, mutationPair.newModId)
			end
		end
		local rawText = item:BuildRaw():gsub("^Rarity: %w+\n", "")
		local variant = {
			name = getFoulbornVariantLabel(newModIds),
			rawText = rawText,
			radiusIndex = item.jewelRadiusIndex,
			isFoulborn = true,
			newModIds = newModIds,
		}
		addFoulbornFields(uniqueName, variant)
		t_insert(variants, variant)
	end
	return variants
end

M.buildFoulbornVariants = buildFoulbornVariants

local function appendFoulbornVariants(jewelType, uniqueName)
	local foulbornVariants = buildFoulbornVariants(uniqueName)
	if #foulbornVariants == 0 then return end
	jewelType.variants = {
		{ name = "Normal", rawText = jewelType.rawText, radiusIndex = jewelType.radiusIndex },
	}
	for _, foulbornVariant in ipairs(foulbornVariants) do
		t_insert(jewelType.variants, foulbornVariant)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Lazy variant lists
-- ─────────────────────────────────────────────────────────────────────────────

local LIGHT_OF_MEANING_VARIANTS
local function getLightOfMeaningVariants()
	if not LIGHT_OF_MEANING_VARIANTS then
		LIGHT_OF_MEANING_VARIANTS = buildVariantsFromUniqueItem("The Light of Meaning")
	end
	return LIGHT_OF_MEANING_VARIANTS
end

local function buildImpossibleEscapeVariants()
	local variants = { }
	for _, rawText in ipairs(data.uniques.generated or { }) do
		if type(rawText) == "string" and rawText:match("^Impossible Escape\n") then
			for line in rawText:gmatch("[^\n]+") do
				local name = line:match("^Variant: (.+)$")
				if name and name ~= "Everything (QoL Test Variant)" then
					local variantRawText = mustGetUniqueVariantRawText("Impossible Escape", name)
					t_insert(variants, {
						name = name,
						dropdownLabel = name,
						keystoneName = name,
						rawText = variantRawText,
						radiusIndex = getRadiusIndexFromRawText(variantRawText),
						scoreLabel = "unalloc notable/keystone near keystone",
					})
				end
			end
			break
		end
	end
	return variants
end

local function makeTemperedVariant(name, rawText, attribute, includeAllocated, includeUnallocated)
	local detailBuilder = makeRadiusAttributeDetail(attribute, includeAllocated, includeUnallocated)
	return {
		name = name,
		rawText = rawText,
		radiusIndex = getRadiusIndexFromRawText(rawText),
		scoreLabel = includeAllocated and includeUnallocated and (attribute:lower() .. " alloc+unalloc")
			or includeAllocated and (attribute:lower() .. " alloc")
			or (attribute:lower() .. " unalloc"),
		score = function(nodes, allocNodes)
			return scoreRadiusAttributes(nodes, allocNodes, attribute, includeAllocated, includeUnallocated)
		end,
		detailBuilder = detailBuilder,
	}
end

local TEMPERED_TRANSCENDENT_VARIANTS
function M.getTemperedTranscendentVariants()
	if not TEMPERED_TRANSCENDENT_VARIANTS then
		TEMPERED_TRANSCENDENT_VARIANTS = {
			makeTemperedVariant("Tempered Flesh", mustGetCurrentUniqueRawText("Tempered Flesh"), "Str", true, false),
			makeTemperedVariant("Transcendent Flesh", mustGetCurrentUniqueRawText("Transcendent Flesh"), "Str", true, true),
			makeTemperedVariant("Tempered Mind", mustGetCurrentUniqueRawText("Tempered Mind"), "Int", true, false),
			makeTemperedVariant("Transcendent Mind", mustGetCurrentUniqueRawText("Transcendent Mind"), "Int", true, true),
			makeTemperedVariant("Tempered Spirit", mustGetCurrentUniqueRawText("Tempered Spirit"), "Dex", true, false),
			makeTemperedVariant("Transcendent Spirit", mustGetCurrentUniqueRawText("Transcendent Spirit"), "Dex", true, true),
		}
	end
	return TEMPERED_TRANSCENDENT_VARIANTS
end

local SPLIT_PERSONALITY_VARIANTS
function M.getSplitPersonalityVariants()
	if not SPLIT_PERSONALITY_VARIANTS then
		SPLIT_PERSONALITY_VARIANTS = buildVariantsFromUniqueItem("Split Personality")
	end
	return SPLIT_PERSONALITY_VARIANTS
end

local IMPOSSIBLE_ESCAPE_VARIANTS
function M.getImpossibleEscapeVariants()
	if not IMPOSSIBLE_ESCAPE_VARIANTS then
		IMPOSSIBLE_ESCAPE_VARIANTS = buildImpossibleEscapeVariants()
	end
	return IMPOSSIBLE_ESCAPE_VARIANTS
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dropdown / impact helpers
-- ─────────────────────────────────────────────────────────────────────────────

function M.makeVariantDropdownEntry(variant)
	local label = variant.dropdownLabel or variant.name
	if label == variant.name then
		return label
	end
	return {
		label = label,
		searchFilter = variant.name,
	}
end

function M.buildImpactStats()
	local stats = { }
	for _, stat in ipairs(data.powerStatList or { }) do
		if stat.stat and not stat.combinedOffDef and not stat.itemField and stat.label ~= "Name" then
			t_insert(stats, {
				field = stat.stat,
				label = stat.label,
				selection = stat,
			})
		end
	end
	return stats
end

M.DISCONNECTED_PASSIVE_COMPUTE_METHODS = {
	{ id = "fast", label = "Fast" },
	{ id = "simulated_greedy", label = "Simulated" },
}

M.OCCUPIED_SOCKET_OPTIONS = {
	{ id = "free", label = "Free only" },
	{ id = "safe", label = "Safe occupied" },
	{ id = "all", label = "All occupied" },
}

function M.findDisconnectedPassiveComputeMethod(methodId)
	for _, method in ipairs(M.DISCONNECTED_PASSIVE_COMPUTE_METHODS) do
		if method.id == methodId then
			return method
		end
	end
	return M.DISCONNECTED_PASSIVE_COMPUTE_METHODS[1]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel preview
-- ─────────────────────────────────────────────────────────────────────────────

local function previewHeader(name, itemType, radius, extra)
	local lines = {
		{ height = 20, [1] = COL_UNIQUE .. name },
		{ height = 16, [1] = COL_META   .. itemType },
		{ height = 6,  [1] = "" },
	}
	if radius then
		t_insert(lines, { height = 16, [1] = COL_META .. "Radius: " .. radius })
	end
	if extra then
		for _, e in ipairs(extra) do
			t_insert(lines, { height = 16, [1] = COL_META .. e })
		end
	end
	t_insert(lines, { height = 6, [1] = "" })
	return lines
end

local function previewFromRawText(rawText, displayName, extraPreviewMeta)
	local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
	item:BuildModList()

	local itemName = displayName or item.title or "Unknown Jewel"
	local itemType = item.baseName or "Jewel"
	local radius = item.jewelRadiusLabel
	local extra = { }
	local mods = { }

	if item.limit then
		t_insert(extra, "Limited to: " .. item.limit)
	end
	if item.source then
		t_insert(extra, "Source: " .. item.source)
	end
	if item.league then
		t_insert(extra, "League: " .. item.league)
	end
	for _, upgradePath in ipairs(item.upgradePaths or { }) do
		t_insert(extra, "Upgrade: " .. upgradePath)
	end
	if rawText:match("(^|\n)Corrupted(\n|$)") then
		t_insert(extra, "Corrupted")
	end

	local function addActiveModLines(modLineList)
		for _, modLine in ipairs(modLineList or { }) do
			if item:CheckModLineVariant(modLine) then
				for line in modLine.line:gmatch("[^\n]+") do
					t_insert(mods, line)
				end
			end
		end
	end

	addActiveModLines(item.implicitModLines)
	addActiveModLines(item.explicitModLines)

	local lines = previewHeader(itemName, itemType, radius, extra)
	if extraPreviewMeta then
		for _, meta in ipairs(extraPreviewMeta) do
			t_insert(lines, { height = 16, [1] = COL_META .. meta })
		end
		t_insert(lines, { height = 6, [1] = "" })
	end
	for _, mod in ipairs(mods) do
		local col = mod:match("^%-") and COL_NEG or COL_MOD
		t_insert(lines, { height = 16, [1] = col .. mod })
	end
	return lines
end

local function previewUnique(uniqueName, displayName, baseName)
	return previewFromRawText(mustGetCurrentUniqueRawText(uniqueName, baseName), displayName)
end

local function previewVariant(variant, displayName)
	if variant and variant.rawText then
		return previewFromRawText(variant.rawText, displayName or variant.name, variant.previewMeta)
	end
	return nil
end

local function previewFinderGroup(name, note)
	local lines = previewHeader(name, "Finder group", nil)
	t_insert(lines, { height = 16, [1] = COL_META .. (note or "Select a variant to preview item data.") })
	return lines
end

local function previewVariantOrGroup(groupName, variant)
	return previewVariant(variant) or previewFinderGroup(groupName)
end

local function previewThreadOfHope(ringName)
	local rawText = mustGetUniqueRawText("Thread of Hope")
	local displayName
	if ringName then
		local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
		local variantName
		for _, candidate in ipairs(item.variantList or { }) do
			if candidate == ringName or candidate:gsub(" Ring$", "") == ringName then
				variantName = candidate
				break
			end
		end
		if variantName then
			rawText = mustGetUniqueVariantRawText("Thread of Hope", variantName)
			displayName = "Thread of Hope (" .. variantName .. ")"
		end
	end
	return previewFromRawText(rawText, displayName)
end

local jewelPreviewFn = {
	["The Light of Meaning"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, "The Light of Meaning (" .. variant.name .. ")")
		end
		return previewFinderGroup("The Light of Meaning")
	end,

	["Might of the Meek"] = function(variant)
		return previewVariant(variant) or previewUnique("Might of the Meek")
	end,

	["Unnatural Instinct"] = function(variant)
		return previewVariant(variant) or previewUnique("Unnatural Instinct")
	end,

	["Inspired Learning"] = function(variant)
		return previewVariant(variant) or previewUnique("Inspired Learning")
	end,

	["Anatomical Knowledge"] = function()
		return previewUnique("Anatomical Knowledge")
	end,

	["Lioneye's Fall"] = function(variant)
		return previewVariant(variant) or previewUnique("Lioneye's Fall")
	end,

	["Intuitive Leap"] = function(variant)
		return previewVariant(variant) or previewUnique("Intuitive Leap")
	end,

	["Tempered & Transcendent"] = function(variant)
		return previewVariantOrGroup("Tempered & Transcendent", variant)
	end,

	["Split Personality"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, "Split Personality (" .. variant.name .. ")")
		end
		return previewFinderGroup("Split Personality")
	end,

	["Impossible Escape"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, "Impossible Escape (" .. variant.name .. ")")
		end
		return previewFinderGroup("Impossible Escape")
	end,

	["Attribute Conversion"] = function(variant)
		return previewVariantOrGroup("Attribute Conversion", variant)
	end,

	["Stat Conversion"] = function(variant)
		return previewVariantOrGroup("Stat Conversion", variant)
	end,

	["Combat Focus"] = function(variant)
		return previewVariantOrGroup("Combat Focus", variant)
	end,

	["Dreams & Nightmares"] = function(variant)
		return previewVariantOrGroup("Dreams & Nightmares", variant)
	end,

	["Thread of Hope"] = function(ringName)
		return previewThreadOfHope(ringName)
	end,
}

M.jewelPreviewFn = jewelPreviewFn

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel type definitions
-- ─────────────────────────────────────────────────────────────────────────────

function M.buildJewelTypes()
	local mightOfTheMeek = {
		name = "Might of the Meek",
		radiusIndex = getUniqueRadiusIndex("Might of the Meek"),
		scoreLabel = "alloc small passives",
		hasCompute = true,
		rawText = mustGetUniqueRawText("Might of the Meek"),
		score = function(nodes, allocNodes)
			local s = 0
			for nodeId, node in pairs(nodes) do
				if allocNodes[nodeId] and node.type == "Normal" then
					s = s + 1
				end
			end
			return s
		end,
	}

	local inspiredLearning = {
		name = "Inspired Learning",
		hasCompute = true,
		radiusIndex = getUniqueRadiusIndex("Inspired Learning"),
		scoreLabel = "alloc notables",
		rawText = mustGetUniqueRawText("Inspired Learning"),
		score = function(nodes, allocNodes)
			local s = 0
			for nodeId, node in pairs(nodes) do
				if allocNodes[nodeId] and node.type == "Notable" then
					s = s + 1
				end
			end
			return s
		end,
	}
	appendFoulbornVariants(inspiredLearning, "Inspired Learning")

	local unnaturalInstinct = {
		name = "Unnatural Instinct",
		radiusIndex = getUniqueRadiusIndex("Unnatural Instinct"),
		scoreLabel = "unalloc small - alloc small",
		hasCompute = true,
		rawText = mustGetUniqueRawText("Unnatural Instinct"),
		score = function(nodes, allocNodes)
			local gained, lost = 0, 0
			for nodeId, node in pairs(nodes) do
				if node.type == "Normal" then
					if allocNodes[nodeId] then lost = lost + 1
					else gained = gained + 1 end
				end
			end
			return gained - lost
		end,
	}
	appendFoulbornVariants(unnaturalInstinct, "Unnatural Instinct")

	local lioneyesFall = {
		name = "Lioneye's Fall",
		radiusIndex = getUniqueRadiusIndex("Lioneye's Fall"),
		scoreLabel = "alloc passives",
		hasCompute = true,
		rawText = mustGetUniqueRawText("Lioneye's Fall"),
		score = scoreAllocPassives,
	}
	appendFoulbornVariants(lioneyesFall, "Lioneye's Fall")

	local intuitiveLeap = {
		name = "Intuitive Leap",
		radiusIndex = getUniqueRadiusIndex("Intuitive Leap"),
		scoreLabel = "unalloc passives",
		hasCompute = true,
		computeMethods = M.DISCONNECTED_PASSIVE_COMPUTE_METHODS,
		rawText = mustGetUniqueRawText("Intuitive Leap"),
		score = function(nodes, allocNodes)
			return scoreUnallocPassives(nodes, allocNodes)
		end,
	}
	appendFoulbornVariants(intuitiveLeap, "Intuitive Leap")

	local dreamsNightmaresJewels = {
		{ name = "The Red Dream" },
		{ name = "The Red Nightmare" },
		{ name = "The Green Dream" },
		{ name = "The Green Nightmare" },
		{ name = "The Blue Dream" },
		{ name = "The Blue Nightmare" },
	}
	local dreamsVariants = { }
	for _, jewelInfo in ipairs(dreamsNightmaresJewels) do
		local rawText = mustGetCurrentUniqueRawText(jewelInfo.name)
		t_insert(dreamsVariants, {
			name = jewelInfo.name,
			variantGroup = jewelInfo.name,
			rawText = rawText,
			radiusIndex = getRadiusIndexFromRawText(rawText),
		})
		local foulbornVariants = buildFoulbornVariants(jewelInfo.name)
		for _, variant in ipairs(foulbornVariants) do
			variant.variantGroup = jewelInfo.name
			variant.name = jewelInfo.name .. " (" .. variant.name .. ")"
			t_insert(dreamsVariants, variant)
		end
	end

	local lightOfMeaningVariants = getLightOfMeaningVariants()
	local temperedTranscendentVariants = M.getTemperedTranscendentVariants()
	local statConversionVariants = {
		makeUniqueVariant("Energy From Within"),
		makeUniqueVariant("Healthy Mind"),
		makeUniqueVariant("Energised Armour"),
	}
	local attributeConversionVariants = {
		makeUniqueVariant("Brute Force Solution"),
		makeUniqueVariant("Careful Planning"),
		makeUniqueVariant("Efficient Training"),
		makeUniqueVariant("Fertile Mind"),
		makeUniqueVariant("Fluid Motion"),
		makeUniqueVariant("Inertia"),
	}
	local combatFocusVariants = {
		makeUniqueVariant("Combat Focus (Crimson)", "Combat Focus", "Crimson Jewel"),
		makeUniqueVariant("Combat Focus (Cobalt)", "Combat Focus", "Cobalt Jewel"),
		makeUniqueVariant("Combat Focus (Viridian)", "Combat Focus", "Viridian Jewel"),
	}

	local jewelTypes = { }
	t_insert(jewelTypes, {
		name = "The Light of Meaning",
		radiusIndex = lightOfMeaningVariants[1] and lightOfMeaningVariants[1].radiusIndex,
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = lightOfMeaningVariants,
	})
	t_insert(jewelTypes, mightOfTheMeek)
	t_insert(jewelTypes, unnaturalInstinct)
	t_insert(jewelTypes, inspiredLearning)
	t_insert(jewelTypes, {
		name = "Anatomical Knowledge",
		radiusIndex = getUniqueRadiusIndex("Anatomical Knowledge"),
		scoreLabel = "alloc passives",
		hasCompute = true,
		isLegacy = true,
		rawText = mustGetUniqueRawText("Anatomical Knowledge"),
		score = scoreAllocPassives,
	})
	t_insert(jewelTypes, {
		name = "Tempered & Transcendent",
		radiusIndex = temperedTranscendentVariants[1] and temperedTranscendentVariants[1].radiusIndex,
		scoreLabel = "attr in radius",
		hasCompute = true,
		score = function(nodes, allocNodes)
			return scoreRadiusAttributes(nodes, allocNodes, "Str", true, false)
		end,
		variants = temperedTranscendentVariants,
	})
	t_insert(jewelTypes, lioneyesFall)
	t_insert(jewelTypes, intuitiveLeap)
	t_insert(jewelTypes, {
		name = "Impossible Escape",
		isImpossibleEscape = true,
		isSocketIndependent = true,
		scoreLabel = "unalloc notable/keystone near keystone",
		hasCompute = true,
		computeMethods = M.DISCONNECTED_PASSIVE_COMPUTE_METHODS,
		score = scoreUnallocNotablesAndKeystones,
		variants = M.getImpossibleEscapeVariants(),
	})
	t_insert(jewelTypes, {
		name = "Split Personality",
		isSplitPersonality = true,
		scoreLabel = "dist to start",
		hasCompute = true,
		score = function()
			return 0
		end,
		variants = M.getSplitPersonalityVariants(),
	})
	t_insert(jewelTypes, {
		name = "Stat Conversion",
		radiusIndex = statConversionVariants[1] and statConversionVariants[1].radiusIndex,
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = statConversionVariants,
	})
	t_insert(jewelTypes, {
		name = "Attribute Conversion",
		radiusIndex = attributeConversionVariants[1] and attributeConversionVariants[1].radiusIndex,
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = attributeConversionVariants,
	})
	t_insert(jewelTypes, {
		name = "Combat Focus",
		radiusIndex = combatFocusVariants[1] and combatFocusVariants[1].radiusIndex,
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = combatFocusVariants,
	})
	t_insert(jewelTypes, {
		name = "Dreams & Nightmares",
		radiusIndex = dreamsVariants[1] and dreamsVariants[1].radiusIndex,
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = dreamsVariants,
	})
	t_insert(jewelTypes, {
		name = "Thread of Hope",
		isThread = true,
		scoreLabel = "unalloc notable/keystone in ring",
		hasCompute = true,
		computeMethods = M.DISCONNECTED_PASSIVE_COMPUTE_METHODS,
		rawText = nil,
		score = scoreUnallocNotablesAndKeystones,
	})
	return jewelTypes
end

function M.jewelTypeSortOrder(jt)
	if jt.name == "The Light of Meaning" then return 10 end
	if jt.name == "Might of the Meek" then return 20 end
	if jt.name == "Unnatural Instinct" then return 30 end
	if jt.name == "Inspired Learning" then return 40 end
	if jt.name == "Anatomical Knowledge" then return 50 end
	if jt.name == "Tempered & Transcendent" then return 55 end
	if jt.name == "Lioneye's Fall" then return 60 end
	if jt.name == "Intuitive Leap" then return 70 end
	if jt.isImpossibleEscape then return 75 end
	if jt.isSplitPersonality then return 80 end
	if jt.name == "Stat Conversion" then return 90 end
	if jt.name == "Attribute Conversion" then return 100 end
	if jt.name == "Combat Focus" then return 110 end
	if jt.name == "Dreams & Nightmares" then return 120 end
	if jt.isThread then return 130 end
	return 1000
end

return M
