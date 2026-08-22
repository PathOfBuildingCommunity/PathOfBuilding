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

-- ─────────────────────────────────────────────────────────────────────────────
-- Color constants
-- ─────────────────────────────────────────────────────────────────────────────

local COL_UNIQUE = "^xAF6025"
local COL_MOD    = "^7"
local COL_META   = "^8"
local COL_NEG    = "^1"
M.COL_META = COL_META

M.JEWEL_STRATEGY = {
	RADIUS = "radius",
	INTUITIVE_LEAP = "intuitiveLeap",
	THREAD_OF_HOPE = "threadOfHope",
	IMPOSSIBLE_ESCAPE = "impossibleEscape",
	SPLIT_PERSONALITY = "splitPersonality",
	ALL_JEWELS = "allJewels",
}
local JEWEL_STRATEGY = M.JEWEL_STRATEGY

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

local function getJewelRadiusIndex(label)
	for index, radius in ipairs(data.jewelRadius) do
		if radius.inner == 0 and radius.label == label then
			return index
		end
	end
	return nil
end

M.getJewelRadiusIndex = getJewelRadiusIndex

local function makeVariantIdentity(family, rawText, variantGroup, radiusIndex)
	local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
	local uniqueName = (item.title or rawText:match("^([^\n]+)")):gsub("^[Ff]oulborn ", "")
	return {
		family = family,
		uniqueName = uniqueName,
		rawText = rawText,
		variantGroup = variantGroup or uniqueName,
		radiusIndex = radiusIndex or item.jewelRadiusIndex,
		limitKey = uniqueName,
		limit = item.limit,
	}
end

local function assignVariantIdentity(candidate, family, variantGroup)
	if not candidate.rawText then
		return candidate
	end
	candidate.variantIdentity = makeVariantIdentity(family, candidate.rawText, variantGroup, candidate.radiusIndex)
	candidate.radiusIndex = candidate.variantIdentity.radiusIndex
	return candidate
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

local THREAD_OF_HOPE_VARIANTS
local THREAD_OF_HOPE_RADIUS_DATA
function M.getThreadOfHopeVariants()
	if not THREAD_OF_HOPE_VARIANTS or THREAD_OF_HOPE_RADIUS_DATA ~= data.jewelRadius then
		THREAD_OF_HOPE_VARIANTS = { }
		THREAD_OF_HOPE_RADIUS_DATA = data.jewelRadius
		local rawText = mustGetUniqueRawText("Thread of Hope")
		local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
		for variantIndex, variantName in ipairs(item.variantList or { }) do
			local variantRawText = mustGetUniqueVariantRawText("Thread of Hope", variantIndex)
			local variant = {
				name = variantName:gsub(" Ring$", ""),
				ringLabel = variantName,
				rawText = variantRawText,
				radiusIndex = getRadiusIndexFromRawText(variantRawText),
			}
			t_insert(THREAD_OF_HOPE_VARIANTS, assignVariantIdentity(variant, "Thread of Hope", variant.name))
		end
	end
	return THREAD_OF_HOPE_VARIANTS
end

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
	variant.radiusIndex = getJewelRadiusIndex("Massive")
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

local function previewFinderGroup(name, note)
	local lines = previewHeader(name, "Finder group", nil)
	t_insert(lines, { height = 16, [1] = COL_META .. (note or "Select a variant to preview item data.") })
	return lines
end

local function previewThreadOfHope(ringName)
	if not ringName then
		return previewFinderGroup("Thread of Hope", "Multiple ring sizes available")
	end
	local rawText = mustGetUniqueRawText("Thread of Hope")
	local displayName
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
	return previewFromRawText(rawText, displayName)
end

local JEWEL_PREVIEW_SCHEMA = {
	["The Light of Meaning"] = { group = true, prefixVariantName = true },
	["Might of the Meek"] = { },
	["Unnatural Instinct"] = { },
	["Inspired Learning"] = { },
	["Anatomical Knowledge"] = { },
	["Tempered & Transcendent"] = { group = true },
	["Lioneye's Fall"] = { },
	["Intuitive Leap"] = { },
	["Impossible Escape"] = { group = true, prefixVariantName = true },
	["Split Personality"] = { group = true, prefixVariantName = true },
	["Stat Conversion"] = { group = true },
	["Attribute Conversion"] = { group = true },
	["Combat Focus"] = { group = true },
	["Dreams & Nightmares"] = { group = true },
	["Thread of Hope"] = { thread = true },
}

local function buildJewelPreview(name, schema, variant)
	if schema.thread then
		return previewThreadOfHope(variant)
	elseif variant and variant.rawText then
		local displayName = schema.prefixVariantName and (name .. " (" .. variant.name .. ")") or variant.name
		return previewFromRawText(variant.rawText, displayName, variant.previewMeta)
	elseif schema.group then
		return previewFinderGroup(name)
	end
	return previewUnique(name)
end

local function makeJewelPreviewFn(name, schema)
	return function(variant)
		return buildJewelPreview(name, schema, variant)
	end
end

local jewelPreviewFn = { }
for name, schema in pairs(JEWEL_PREVIEW_SCHEMA) do
	jewelPreviewFn[name] = makeJewelPreviewFn(name, schema)
end

M.jewelPreviewFn = jewelPreviewFn

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel type definitions
-- ─────────────────────────────────────────────────────────────────────────────

local function scoreAllocatedNodeType(nodeType)
	return function(nodes, allocNodes)
		local score = 0
		for nodeId, node in pairs(nodes) do
			if allocNodes[nodeId] and node.type == nodeType then
				score = score + 1
			end
		end
		return score
	end
end

local function scoreUnnaturalInstinct(nodes, allocNodes)
	local gained, lost = 0, 0
	for nodeId, node in pairs(nodes) do
		if node.type == "Normal" then
			if allocNodes[nodeId] then lost = lost + 1
			else gained = gained + 1 end
		end
	end
	return gained - lost
end

local function makeJewelType(name, scoreLabel, score, options)
	local jewelType = { }
	for key, value in pairs(options or { }) do
		jewelType[key] = value
	end
	jewelType.name = name
	jewelType.strategy = jewelType.strategy or JEWEL_STRATEGY.RADIUS
	jewelType.scoreLabel = scoreLabel
	jewelType.score = score
	jewelType.hasCompute = true
	if not jewelType.rawText and not jewelType.variants then
		jewelType.rawText = mustGetUniqueRawText(name)
	end
	if not jewelType.radiusIndex then
		jewelType.radiusIndex = jewelType.variants and jewelType.variants[1]
			and jewelType.variants[1].radiusIndex
			or jewelType.rawText and getRadiusIndexFromRawText(jewelType.rawText)
	end
	return jewelType
end

function M.buildJewelTypes()
	local scoreAllocatedNormals = scoreAllocatedNodeType("Normal")
	local scoreAllocatedNotables = scoreAllocatedNodeType("Notable")
	local mightOfTheMeek = makeJewelType("Might of the Meek", "alloc small passives", scoreAllocatedNormals)

	local inspiredLearning = makeJewelType("Inspired Learning", "alloc notables", scoreAllocatedNotables)
	appendFoulbornVariants(inspiredLearning, "Inspired Learning")

	local unnaturalInstinct = makeJewelType("Unnatural Instinct", "unalloc small - alloc small", scoreUnnaturalInstinct)
	appendFoulbornVariants(unnaturalInstinct, "Unnatural Instinct")

	local lioneyesFall = makeJewelType("Lioneye's Fall", "alloc passives", scoreAllocPassives)
	appendFoulbornVariants(lioneyesFall, "Lioneye's Fall")

	local intuitiveLeap = makeJewelType("Intuitive Leap", "unalloc passives", scoreUnallocPassives, {
		strategy = JEWEL_STRATEGY.INTUITIVE_LEAP,
		computeMethods = M.DISCONNECTED_PASSIVE_COMPUTE_METHODS,
	})
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
	local threadOfHopeRawText = mustGetUniqueRawText("Thread of Hope")

	local jewelTypes = { }
	t_insert(jewelTypes, makeJewelType("The Light of Meaning", "alloc passives", scoreAllocPassives, {
		variants = lightOfMeaningVariants,
	}))
	t_insert(jewelTypes, mightOfTheMeek)
	t_insert(jewelTypes, unnaturalInstinct)
	t_insert(jewelTypes, inspiredLearning)
	t_insert(jewelTypes, makeJewelType("Anatomical Knowledge", "alloc passives", scoreAllocPassives, {
		isLegacy = true,
	}))
	t_insert(jewelTypes, makeJewelType("Tempered & Transcendent", "attr in radius", function(nodes, allocNodes)
			return scoreRadiusAttributes(nodes, allocNodes, "Str", true, false)
		end, {
		variants = temperedTranscendentVariants,
	}))
	t_insert(jewelTypes, lioneyesFall)
	t_insert(jewelTypes, intuitiveLeap)
	t_insert(jewelTypes, makeJewelType("Impossible Escape", "unalloc notable/keystone near keystone",
		scoreUnallocNotablesAndKeystones, {
		strategy = JEWEL_STRATEGY.IMPOSSIBLE_ESCAPE,
		isImpossibleEscape = true,
		isEffectSocketIndependent = true,
		computeMethods = M.DISCONNECTED_PASSIVE_COMPUTE_METHODS,
		variants = M.getImpossibleEscapeVariants(),
	}))
	t_insert(jewelTypes, makeJewelType("Split Personality", "dist to start", function() return 0 end, {
		strategy = JEWEL_STRATEGY.SPLIT_PERSONALITY,
		isSplitPersonality = true,
		variants = M.getSplitPersonalityVariants(),
	}))
	t_insert(jewelTypes, makeJewelType("Stat Conversion", "alloc passives", scoreAllocPassives, {
		variants = statConversionVariants,
	}))
	t_insert(jewelTypes, makeJewelType("Attribute Conversion", "alloc passives", scoreAllocPassives, {
		variants = attributeConversionVariants,
	}))
	t_insert(jewelTypes, makeJewelType("Combat Focus", "alloc passives", scoreAllocPassives, {
		variants = combatFocusVariants,
	}))
	t_insert(jewelTypes, makeJewelType("Dreams & Nightmares", "alloc passives", scoreAllocPassives, {
		variants = dreamsVariants,
	}))
	t_insert(jewelTypes, makeJewelType("Thread of Hope", "unalloc notable/keystone in ring",
		scoreUnallocNotablesAndKeystones, {
		strategy = JEWEL_STRATEGY.THREAD_OF_HOPE,
		isThread = true,
		computeMethods = M.DISCONNECTED_PASSIVE_COMPUTE_METHODS,
		rawText = threadOfHopeRawText,
	}))
	for _, jewelType in ipairs(jewelTypes) do
		assignVariantIdentity(jewelType, jewelType.name, jewelType.name)
		for _, variant in ipairs(jewelType.variants or { }) do
			assignVariantIdentity(variant, jewelType.name, variant.variantGroup)
		end
	end
	return jewelTypes
end

return M
