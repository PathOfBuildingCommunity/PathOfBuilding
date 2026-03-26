-- Path of Building
--
-- Module: Radius Jewel Data
-- Jewel type definitions, variants, scoring functions, and preview builders
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
	local item = new("Item", "Rarity: Unique\n" .. rawText)
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

-- Expose for compute module and tests
M.mustGetUniqueRawText = mustGetUniqueRawText

-- ─────────────────────────────────────────────────────────────────────────────
-- Variant builders
-- ─────────────────────────────────────────────────────────────────────────────

local function buildVariantsFromUniqueItem(uniqueName, baseName)
	local variants = { }
	local baseRawText = mustGetUniqueRawText(uniqueName, baseName)
	local item = new("Item", "Rarity: Unique\n" .. baseRawText)
	if item.variantList then
		for idx, variantName in ipairs(item.variantList) do
			local rawText = getUniqueVariantRawText(uniqueName, idx, nil, baseName)
			if rawText then
				t_insert(variants, {
					name = variantName,
					rawText = rawText,
				})
			end
		end
	end
	return variants
end

M.buildVariantsFromUniqueItem = buildVariantsFromUniqueItem

local function discoverFoulbornVariants(uniqueName, radiusIndexByLabel)
	local variants = { }
	local generated = data.uniques.generated
	if not generated then return variants end
	local escapedName = uniqueName:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
	for _, rawText in ipairs(generated) do
		local comboIndex = rawText:match("^Foulborn " .. escapedName .. " (%d+)\n")
		if comboIndex then
			local radiusLabel = rawText:match("\nRadius: (%a+)")
			local radiusIndex = radiusLabel and radiusIndexByLabel[radiusLabel]
			t_insert(variants, {
				name = "Foulborn " .. comboIndex,
				rawText = rawText,
				radiusIndex = radiusIndex,
				isFoulborn = true,
				comboIndex = tonumber(comboIndex),
			})
		end
	end
	t_sort(variants, function(a, b) return a.comboIndex < b.comboIndex end)
	return variants
end

M.discoverFoulbornVariants = discoverFoulbornVariants

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
-- Foulborn enrichment
-- ─────────────────────────────────────────────────────────────────────────────

local function enrichUnnaturalInstinctFoulborn(variant)
	local typeMap = { Notable = "Notable", Small = "Normal" }
	local rawText = variant.rawText
	local gainLabel = rawText:match("Unallocated (%w+) Passive Skills")
	local loseLabel = rawText:match("Allocated (%w+) Passive Skills.-grant nothing")
	local gainType = gainLabel and typeMap[gainLabel]
	local loseType = loseLabel and typeMap[loseLabel]
	if gainType and loseType then
		local gainShort = gainType == "Notable" and "notable" or "small"
		local loseShort = loseType == "Notable" and "notable" or "small"
		variant.scoreLabel = "unalloc " .. gainShort .. " - alloc " .. loseShort
		variant.score = function(nodes, allocNodes)
			return scoreGainLoss(nodes, allocNodes, gainType, loseType)
		end
	end
end

local function enrichInspiredLearningFoulborn(variant)
	local rawText = variant.rawText
	if rawText:match("If no Notables Allocated") then
		variant.scoreLabel = "no alloc notables"
		variant.score = function(nodes, allocNodes)
			for nodeId, node in pairs(nodes) do
				if allocNodes[nodeId] and node.type == "Notable" then
					return 0
				end
			end
			return 1
		end
	elseif rawText:match("Small Passives Allocated") then
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
end

local function enrichIntuitiveLeapFoulborn(variant)
	local rawText = variant.rawText
	if rawText:match("Massive Radius") then
		variant.isMassiveRadius = true
	end
	if rawText:match("Keystone Passive Skills") then
		variant.keystoneOnly = true
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
end

local function appendFoulbornVariants(jewelType, foulborn)
	if #foulborn == 0 then return end
	jewelType.variants = {
		{ name = "Normal", rawText = jewelType.rawText, radiusIndex = jewelType.radiusIndex },
	}
	for _, fb in ipairs(foulborn) do
		t_insert(jewelType.variants, fb)
	end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Lazy variant getters
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
					t_insert(variants, {
						name = name,
						dropdownLabel = name,
						keystoneName = name,
						rawText = mustGetUniqueVariantRawText("Impossible Escape", name),
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

M.CONNECTIONLESS_COMPUTE_METHODS = {
	{ id = "fast", label = "Fast" },
	{ id = "simulated_greedy", label = "Simulated" },
}

M.OCCUPIED_SOCKET_OPTIONS = {
	{ id = "free", label = "Free only" },
	{ id = "safe", label = "Safe occupied" },
	{ id = "all", label = "All occupied" },
}

function M.findConnectionlessComputeMethod(methodId)
	for _, method in ipairs(M.CONNECTIONLESS_COMPUTE_METHODS) do
		if method.id == methodId then
			return method
		end
	end
	return M.CONNECTIONLESS_COMPUTE_METHODS[1]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel preview
-- ─────────────────────────────────────────────────────────────────────────────

local function previewHeader(name, itemType, radius, extra)
	radius = radius or "?"
	local lines = {
		{ height = 20, [1] = COL_UNIQUE .. name },
		{ height = 16, [1] = COL_META   .. itemType },
		{ height = 6,  [1] = "" },
		{ height = 16, [1] = COL_META .. "Radius: " .. radius },
	}
	if extra then
		for _, e in ipairs(extra) do
			t_insert(lines, { height = 16, [1] = COL_META .. e })
		end
	end
	t_insert(lines, { height = 6, [1] = "" })
	return lines
end

local function previewFromRawText(rawText, displayName, extraPreviewMeta)
	local item = new("Item", "Rarity: Unique\n" .. rawText)
	item:BuildModList()

	local itemName = displayName or item.title or "Unknown Jewel"
	local itemType = item.baseName or "Jewel"
	local radius = item.jewelRadiusLabel or "?"
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

local jewelPreviewFn  -- forward-declare so group functions can reference it by upvalue
jewelPreviewFn = {
	["The Light of Meaning"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, "The Light of Meaning (" .. variant.name .. ")")
		end
		local lines = previewHeader("The Light of Meaning", "Prismatic Jewel", "Large",
			{ "Limited to: 1", "Source: King of The Mists" })
		for _, v in ipairs(getLightOfMeaningVariants()) do
			t_insert(lines, { height = 14, [1] = COL_META .. "  " .. v.name })
		end
		return lines
	end,

	["Might of the Meek"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText)
		end
		local lines = previewHeader("Might of the Meek", "Crimson Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "50% increased Effect of non-Keystone" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Notable Passive Skills in Radius grant nothing" })
		return lines
	end,

	["Unnatural Instinct"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText)
		end
		local lines = previewHeader("Unnatural Instinct", "Viridian Jewel", "Small",
			{ "Limited to: 1" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Allocated Small Passive Skills in" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Radius grant nothing" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Grants all bonuses of Unallocated" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Small Passive Skills in Radius" })
		return lines
	end,

	["Inspired Learning"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText)
		end
		local lines = previewHeader("Inspired Learning", "Crimson Jewel", "Small")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "With 4 Notables Allocated in Radius," })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "When you Kill a Rare monster, you gain" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "1 of its Modifiers for 20 seconds" })
		return lines
	end,

	["Anatomical Knowledge"] = function()
		local lines = previewHeader("Anatomical Knowledge", "Cobalt Jewel", "Large",
			{ "Source: No longer obtainable" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "(6-8)% increased maximum Life" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Adds 1 to Maximum Life per 3" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Intelligence Allocated in Radius" })
		return lines
	end,

	["Lioneye's Fall"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText)
		end
		local lines = previewHeader("Lioneye's Fall", "Viridian Jewel", "Medium")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Melee and Melee Weapon Type modifiers" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "in Radius are Transformed to Bow Modifiers" })
		return lines
	end,

	["Intuitive Leap"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText)
		end
		local lines = previewHeader("Intuitive Leap", "Viridian Jewel", "Small")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives in Radius can be Allocated" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "without being connected to your tree" })
		return lines
	end,

	["Tempered & Transcendent"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, variant.name)
		end
		local lines = previewHeader("Tempered & Transcendent", "Unique Jewel", "Medium")
		t_insert(lines, { height = 14, [1] = COL_META .. "Tempered Flesh / Transcendent Flesh" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Tempered Mind / Transcendent Mind" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Tempered Spirit / Transcendent Spirit" })
		return lines
	end,

	["Split Personality"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, "Split Personality (" .. variant.name .. ")")
		end
		local lines = previewHeader("Split Personality", "Crimson Jewel", "Variable",
			{ "Limited to: 2", "Source: Drops from the Simulacrum Encounter" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Socket effect scales with distance to class start" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Variants: Strength, Dexterity, Intelligence, Life" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Mana, Energy Shield, Armour, Evasion, Accuracy" })
		return lines
	end,

	["Impossible Escape"] = function(variant)
		if variant and variant.rawText then
			return previewFromRawText(variant.rawText, "Impossible Escape (" .. variant.name .. ")")
		end
		local lines = previewHeader("Impossible Escape", "Viridian Jewel", "Small",
			{ "Limited to: 1", "Source: Drops from The Maven (Uber)" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in radius of the chosen" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Keystone can be allocated without connection" })
		return lines
	end,

	["Energy From Within"] = function()
		local lines = previewHeader("Energy From Within", "Cobalt Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "3% increased maximum Energy Shield" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Life mods in Radius apply to Energy Shield" })
		return lines
	end,

	["Healthy Mind"] = function()
		local lines = previewHeader("Healthy Mind", "Cobalt Jewel", "Large",
			{ "Limited to: 1" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "15% increased maximum Mana" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Life mods in Radius apply to Mana at 200%" })
		return lines
	end,

	["Energised Armour"] = function()
		local lines = previewHeader("Energised Armour", "Crimson Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "15% increased Armour" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "ES mods in Radius apply to Armour at 200%" })
		return lines
	end,

	["Brute Force Solution"] = function()
		local lines = previewHeader("Brute Force Solution", "Cobalt Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Intelligence" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Strength from Passives -> Intelligence" })
		return lines
	end,

	["Careful Planning"] = function()
		local lines = previewHeader("Careful Planning", "Viridian Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Dexterity" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Intelligence from Passives -> Dexterity" })
		return lines
	end,

	["Efficient Training"] = function()
		local lines = previewHeader("Efficient Training", "Crimson Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Strength" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Intelligence from Passives -> Strength" })
		return lines
	end,

	["Fertile Mind"] = function()
		local lines = previewHeader("Fertile Mind", "Cobalt Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Intelligence" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Dexterity from Passives -> Intelligence" })
		return lines
	end,

	["Fluid Motion"] = function()
		local lines = previewHeader("Fluid Motion", "Viridian Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Dexterity" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Strength from Passives -> Dexterity" })
		return lines
	end,

	["Inertia"] = function()
		local lines = previewHeader("Inertia", "Crimson Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "+16 to Strength" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Dexterity from Passives -> Strength" })
		return lines
	end,

	["Combat Focus (Crimson)"] = function()
		local lines = previewHeader("Combat Focus", "Crimson Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "10% increased Elemental Damage" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Prismatic Skills lose Cold" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "with 40 total Str+Int in Radius" })
		return lines
	end,

	["Combat Focus (Cobalt)"] = function()
		local lines = previewHeader("Combat Focus", "Cobalt Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "10% increased Elemental Damage" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Prismatic Skills lose Fire" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "with 40 total Int+Dex in Radius" })
		return lines
	end,

	["Combat Focus (Viridian)"] = function()
		local lines = previewHeader("Combat Focus", "Viridian Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "10% increased Elemental Damage" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Prismatic Skills lose Lightning" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "with 40 total Dex+Str in Radius" })
		return lines
	end,

	["Attribute Conversion"] = function(variant)
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name]()
		end
		local lines = previewHeader("Attribute Conversion", "Corrupted Jewel", "Large")
		t_insert(lines, { height = 14, [1] = COL_META .. "Brute Force Solution: Str -> Int" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Careful Planning:     Int -> Dex" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Efficient Training:   Int -> Str" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Fertile Mind:         Dex -> Int" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Fluid Motion:         Str -> Dex" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Inertia:              Dex -> Str" })
		return lines
	end,

	["Stat Conversion"] = function(variant)
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name]()
		end
		local lines = previewHeader("Stat Conversion", "Corrupted Jewel", "Large")
		t_insert(lines, { height = 14, [1] = COL_META .. "Energy From Within: Life -> Energy Shield" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Healthy Mind:       Life -> Mana (200%)" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Energised Armour:   ES   -> Armour (200%)" })
		return lines
	end,

	["Combat Focus"] = function(variant)
		if variant and jewelPreviewFn[variant.name] then
			return jewelPreviewFn[variant.name]()
		end
		local lines = previewHeader("Combat Focus", "Jewel", "Medium",
			{ "Limited to: 2", "Source: Vendor Recipe" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Crimson:  lose Cold    (Str+Int >= 40)" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Cobalt:   lose Fire    (Int+Dex >= 40)" })
		t_insert(lines, { height = 14, [1] = COL_META .. "Viridian: lose Lightning (Dex+Str >= 40)" })
		return lines
	end,

	["Dreams & Nightmares"] = function(variant)
		if variant and variant.rawText then
			local extraPreviewMeta = nil
			if variant.family then
				extraPreviewMeta = { "Family: " .. variant.family:gsub("^The ", "") }
			end
			return previewFromRawText(variant.rawText, variant.name, extraPreviewMeta)
		end
		local lines = previewHeader("Dreams & Nightmares", "Unique Jewel", "Large")
		t_insert(lines, { height = 14, [1] = COL_META .. "The Red Dream:       Fire Res -> Endurance on Kill" })
		t_insert(lines, { height = 14, [1] = COL_META .. "The Red Nightmare:   Fire Res -> Block" })
		t_insert(lines, { height = 14, [1] = COL_META .. "The Green Dream:     Cold Res -> Frenzy on Kill" })
		t_insert(lines, { height = 14, [1] = COL_META .. "The Green Nightmare: Cold Res -> Suppress" })
		t_insert(lines, { height = 14, [1] = COL_META .. "The Blue Dream:      Lightning Res -> Power on Kill" })
		t_insert(lines, { height = 14, [1] = COL_META .. "The Blue Nightmare:  Lightning Res -> Spell Block" })
		return lines
	end,

	["The Red Dream"] = function()
		local lines = previewHeader("The Red Dream", "Crimson Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Fire/All Res in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Endurance Charge on Kill" })
		return lines
	end,

	["The Red Nightmare"] = function()
		local lines = previewHeader("The Red Nightmare", "Crimson Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Fire/All Res in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Chance to Block at 50%" })
		return lines
	end,

	["The Green Dream"] = function()
		local lines = previewHeader("The Green Dream", "Viridian Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Cold/All Res in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Frenzy Charge on Kill" })
		return lines
	end,

	["The Green Nightmare"] = function()
		local lines = previewHeader("The Green Nightmare", "Viridian Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Cold/All Res in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Chance to Suppress at 70%" })
		return lines
	end,

	["The Blue Dream"] = function()
		local lines = previewHeader("The Blue Dream", "Cobalt Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Lightning/All Res in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Power Charge on Kill" })
		return lines
	end,

	["The Blue Nightmare"] = function()
		local lines = previewHeader("The Blue Nightmare", "Cobalt Jewel", "Large")
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passives granting Lightning/All Res in Radius" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "also grant Spell Block at 50%" })
		return lines
	end,

	["Thread of Hope"] = function(ringName)
		local ring = ringName or "?"
		local lines = previewHeader("Thread of Hope", "Crimson Jewel", "Variable",
			{ "Source: Drops from Sirus, Awakener of Worlds" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Only affects Passives in " .. ring .. " Ring" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "Passive Skills in Radius can be Allocated" })
		t_insert(lines, { height = 16, [1] = COL_MOD .. "without being connected to your tree" })
		t_insert(lines, { height = 6,  [1] = "" })
		t_insert(lines, { height = 16, [1] = COL_NEG  .. "-(20-10)% to all Elemental Resistances" })
		return lines
	end,
}

M.jewelPreviewFn = jewelPreviewFn

-- ─────────────────────────────────────────────────────────────────────────────
-- Jewel type definitions
-- ─────────────────────────────────────────────────────────────────────────────

function M.buildJewelTypes(radiusIndexByLabel)
	local mightOfTheMeek = {
		name = "Might of the Meek",
		radiusIndex = radiusIndexByLabel["Large"],
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
	appendFoulbornVariants(mightOfTheMeek, discoverFoulbornVariants("Might of the Meek", radiusIndexByLabel))

	local inspiredLearning = {
		name = "Inspired Learning",
		hasCompute = true,
		radiusIndex = radiusIndexByLabel["Small"],
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
	do
		local fb = discoverFoulbornVariants("Inspired Learning", radiusIndexByLabel)
		for _, v in ipairs(fb) do enrichInspiredLearningFoulborn(v) end
		appendFoulbornVariants(inspiredLearning, fb)
	end

	local unnaturalInstinct = {
		name = "Unnatural Instinct",
		radiusIndex = radiusIndexByLabel["Small"],
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
	do
		local fb = discoverFoulbornVariants("Unnatural Instinct", radiusIndexByLabel)
		for _, v in ipairs(fb) do enrichUnnaturalInstinctFoulborn(v) end
		appendFoulbornVariants(unnaturalInstinct, fb)
	end

	local lioneyesFall = {
		name = "Lioneye's Fall",
		radiusIndex = radiusIndexByLabel["Medium"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		rawText = mustGetUniqueRawText("Lioneye's Fall"),
		score = scoreAllocPassives,
	}
	appendFoulbornVariants(lioneyesFall, discoverFoulbornVariants("Lioneye's Fall", radiusIndexByLabel))

	local intuitiveLeap = {
		name = "Intuitive Leap",
		radiusIndex = radiusIndexByLabel["Small"],
		scoreLabel = "unalloc passives",
		hasCompute = true,
		computeMethods = M.CONNECTIONLESS_COMPUTE_METHODS,
		rawText = mustGetUniqueRawText("Intuitive Leap"),
		score = function(nodes, allocNodes)
			return scoreUnallocPassives(nodes, allocNodes)
		end,
	}
	do
		local fb = discoverFoulbornVariants("Intuitive Leap", radiusIndexByLabel)
		for _, v in ipairs(fb) do enrichIntuitiveLeapFoulborn(v) end
		appendFoulbornVariants(intuitiveLeap, fb)
	end

	local dreamsNightmaresFamilies = {
		{ name = "The Red Dream",       baseName = "Crimson Jewel" },
		{ name = "The Red Nightmare",   baseName = "Crimson Jewel" },
		{ name = "The Green Dream",     baseName = "Viridian Jewel" },
		{ name = "The Green Nightmare", baseName = "Viridian Jewel" },
		{ name = "The Blue Dream",      baseName = "Cobalt Jewel" },
		{ name = "The Blue Nightmare",  baseName = "Cobalt Jewel" },
	}
	local dreamsVariants = { }
	for _, fam in ipairs(dreamsNightmaresFamilies) do
		t_insert(dreamsVariants, {
			name = fam.name,
			family = fam.name,
			rawText = mustGetCurrentUniqueRawText(fam.name),
		})
		local fb = discoverFoulbornVariants(fam.name, radiusIndexByLabel)
		for _, v in ipairs(fb) do
			v.family = fam.name
			v.name = fam.name .. " (" .. v.name .. ")"
			t_insert(dreamsVariants, v)
		end
	end

	local jewelTypes = { }
	t_insert(jewelTypes, {
		name = "The Light of Meaning",
		limit = 1,
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = getLightOfMeaningVariants(),
	})
	t_insert(jewelTypes, mightOfTheMeek)
	t_insert(jewelTypes, unnaturalInstinct)
	t_insert(jewelTypes, inspiredLearning)
	t_insert(jewelTypes, {
		name = "Anatomical Knowledge",
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		isLegacy = true,
		rawText = mustGetUniqueRawText("Anatomical Knowledge"),
		score = scoreAllocPassives,
	})
	t_insert(jewelTypes, {
		name = "Tempered & Transcendent",
		radiusIndex = radiusIndexByLabel["Medium"],
		scoreLabel = "attr in radius",
		hasCompute = true,
		score = function(nodes, allocNodes)
			return scoreRadiusAttributes(nodes, allocNodes, "Str", true, false)
		end,
		variants = M.getTemperedTranscendentVariants(),
	})
	t_insert(jewelTypes, lioneyesFall)
	t_insert(jewelTypes, intuitiveLeap)
	t_insert(jewelTypes, {
		name = "Impossible Escape",
		isImpossibleEscape = true,
		scoreLabel = "unalloc notable/keystone near keystone",
		hasCompute = true,
		computeMethods = M.CONNECTIONLESS_COMPUTE_METHODS,
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
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = {
			{ name = "Energy From Within", rawText = mustGetUniqueRawText("Energy From Within") },
			{ name = "Healthy Mind",       rawText = mustGetUniqueRawText("Healthy Mind") },
			{ name = "Energised Armour",   rawText = mustGetUniqueRawText("Energised Armour") },
		},
	})
	t_insert(jewelTypes, {
		name = "Attribute Conversion",
		radiusIndex = radiusIndexByLabel["Large"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = {
			{ name = "Brute Force Solution", rawText = mustGetUniqueRawText("Brute Force Solution") },
			{ name = "Careful Planning",     rawText = mustGetUniqueRawText("Careful Planning") },
			{ name = "Efficient Training",   rawText = mustGetUniqueRawText("Efficient Training") },
			{ name = "Fertile Mind",         rawText = mustGetUniqueRawText("Fertile Mind") },
			{ name = "Fluid Motion",         rawText = mustGetUniqueRawText("Fluid Motion") },
			{ name = "Inertia",              rawText = mustGetUniqueRawText("Inertia") },
		},
	})
	t_insert(jewelTypes, {
		name = "Combat Focus",
		radiusIndex = radiusIndexByLabel["Medium"],
		scoreLabel = "alloc passives",
		hasCompute = true,
		score = scoreAllocPassives,
		variants = {
			{ name = "Combat Focus (Crimson)",  rawText = mustGetUniqueRawText("Combat Focus", "Crimson Jewel") },
			{ name = "Combat Focus (Cobalt)",   rawText = mustGetUniqueRawText("Combat Focus", "Cobalt Jewel") },
			{ name = "Combat Focus (Viridian)", rawText = mustGetUniqueRawText("Combat Focus", "Viridian Jewel") },
		},
	})
	t_insert(jewelTypes, {
		name = "Dreams & Nightmares",
		radiusIndex = radiusIndexByLabel["Large"],
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
		computeMethods = M.CONNECTIONLESS_COMPUTE_METHODS,
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
