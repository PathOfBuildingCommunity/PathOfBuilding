-- Path of Building
--
-- Module: Trade Resistance Swap
-- Extracts safe resistance-swap metadata and builds theoretical item variants.
--

local M = {}

local elements = { "Fire", "Cold", "Lightning" }
local elementSet = { Fire = true, Cold = true, Lightning = true }

local function groupKey(domain, index)
	return domain .. ":" .. tostring(index)
end

local function getHashGroups(item)
	local groupsByDomain = {}
	local hashes = item.extended and item.extended.hashes or {}
	for _, domain in ipairs({ "explicit", "crafted" }) do
		local groupsByHash = {}
		for _, entry in ipairs(hashes[domain] or {}) do
			if type(entry) == "table" and type(entry[1]) == "string" and type(entry[2]) == "table" then
				if groupsByHash[entry[1]] ~= nil then
					groupsByHash[entry[1]] = false
				else
					groupsByHash[entry[1]] = entry[2]
				end
			end
		end
		groupsByDomain[domain] = groupsByHash
	end
	return groupsByDomain
end

local function getUniqueMod(modLine)
	local metadata = type(modLine.mods) == "table" and modLine.mods
	return metadata and #metadata == 1 and metadata[1]
end

local function getAffixFingerprint(modLine)
	local domain = modLine.domain
	local mod = getUniqueMod(modLine)
	if (domain ~= "explicit" and domain ~= "crafted") or not mod
		or type(mod.name) ~= "string" or mod.name == ""
		or type(mod.tier) ~= "string" or mod.tier == ""
		or type(mod.level) ~= "number" then
		return
	end
	return table.concat({ domain, mod.name, mod.tier, tostring(mod.level) }, "\0")
end

local function getLineGroups(modLine, groupsByDomain)
	local domain = modLine.domain
	local metadata = getUniqueMod(modLine)
	local magnitude = metadata and type(metadata.magnitudes) == "table" and metadata.magnitudes[1]
	local rawHash = modLine.hash or metadata and metadata.hash or magnitude and magnitude.hash
	local hash = type(rawHash) == "string" and rawHash:gsub("^stat%.", "")
	return groupsByDomain[domain] and groupsByDomain[domain][hash]
end

-- Extract only the compact, non-identifying metadata needed by local evaluation.
function M.extractDescriptors(item)
	if type(item) ~= "table" or item.corrupted or item.duplicated or item.mirrored
		or item.unmodifiable or item.unmodifiableExceptChaos then
		return {}
	end

	local explicitMods = item.explicitMods
	if type(explicitMods) ~= "table" then
		return {}
	end
	local groupsByDomain = getHashGroups(item)
	local groupLineCounts = {}
	local affixLineCounts = {}
	local metadataComplete = true
	for _, modLine in ipairs(explicitMods) do
		local groups = getLineGroups(modLine, groupsByDomain)
		if type(groups) == "table" then
			for _, index in ipairs(groups) do
				local key = groupKey(modLine.domain, index)
				groupLineCounts[key] = (groupLineCounts[key] or 0) + 1
			end
		end
		local fingerprint = getAffixFingerprint(modLine)
		if fingerprint then
			affixLineCounts[fingerprint] = (affixLineCounts[fingerprint] or 0) + 1
		end
		if (modLine.domain == "explicit" or modLine.domain == "crafted")
			and (not fingerprint or type(groups) ~= "table" or #groups ~= 1) then
			metadataComplete = false
		end
	end
	if not metadataComplete then
		return {}
	end

	local descriptors = {}
	local seenElements = {}
	local duplicateElement = false
	for lineIndex, modLine in ipairs(explicitMods) do
		local domain = modLine.domain
		local flags = modLine.flags or {}
		local value, element
		if type(modLine.description) == "string" then
			value, element = modLine.description:match("^%+(%d+%.?%d*)%% to (%a+) Resistance$")
		end
		local mod = getUniqueMod(modLine)
		local magnitudes = mod and mod.magnitudes
		local magnitude = type(magnitudes) == "table" and #magnitudes == 1 and magnitudes[1]
		local groups = getLineGroups(modLine, groupsByDomain)
		local fingerprint = getAffixFingerprint(modLine)
		local validGroup = type(groups) == "table" and #groups == 1
			and groupLineCounts[groupKey(domain, groups[1])] == 1
		if (domain == "explicit" or domain == "crafted") and value and elementSet[element]
			and not flags.fractured and not flags.unmodifiable and not flags.unmodifiableExceptChaos
			and fingerprint and affixLineCounts[fingerprint] == 1
			and magnitude and tonumber(magnitude.min) and tonumber(magnitude.max)
			and validGroup then
			if seenElements[element] then
				duplicateElement = true
			else
				table.insert(descriptors, {
					lineIndex = lineIndex,
					element = element,
					domain = domain,
					tier = mod.tier,
					range = { min = tonumber(magnitude.min), max = tonumber(magnitude.max) },
				})
				seenElements[element] = true
			end
		end
	end

	if duplicateElement or #descriptors > 3 then
		return {}
	end
	return descriptors
end

function M.getAssignments(descriptors)
	if type(descriptors) ~= "table" or #descriptors == 0 or #descriptors > 3 then
		return {}
	end
	local sourceElements = {}
	for _, descriptor in ipairs(descriptors) do
		if not elementSet[descriptor.element] or sourceElements[descriptor.element] then
			return {}
		end
		sourceElements[descriptor.element] = true
	end
	local assignments = {}
	local assignment = {}
	local used = {}
	local function visit(index, swaps)
		if index > #descriptors then
			local targets = {}
			for descriptorIndex, target in ipairs(assignment) do
				targets[descriptorIndex] = target
			end
			table.insert(assignments, { targets = targets, swaps = swaps })
			return
		end
		for _, target in ipairs(elements) do
			if not used[target] then
				used[target] = true
				assignment[index] = target
				visit(index + 1, swaps + (target == descriptors[index].element and 0 or 1))
				used[target] = nil
			end
		end
	end
	visit(1, 0)
	return assignments
end

local function readResistanceLine(modLine)
	if not modLine or type(modLine.line) ~= "string" then
		return
	end
	local value, element = modLine.line:match("^%+(%d+%.?%d*)%% to (%a+) Resistance$")
	if value and elementSet[element] then
		return value, element
	end
end

function M.validateItem(item, descriptors)
	if not item or item.corrupted or item.mirrored or item.duplicated then
		return false
	end
	for _, descriptor in ipairs(descriptors or {}) do
		local modLine = item.explicitModLines[descriptor.lineIndex]
		local _, element = readResistanceLine(modLine)
		if element ~= descriptor.element or modLine.fractured
			or (descriptor.domain == "crafted") ~= (modLine.crafted == true) then
			return false
		end
	end
	return #descriptors > 0
end

function M.buildVariant(itemString, descriptors, assignment)
	local item = new("Item"):Item(itemString)
	if not M.validateItem(item, descriptors) then
		return
	end
	local swaps = {}
	local swappedLineIndexes = {}
	for index, descriptor in ipairs(descriptors) do
		local target = assignment.targets[index]
		local modLine = item.explicitModLines[descriptor.lineIndex]
		local value, source = readResistanceLine(modLine)
		if not target or not elementSet[target] or not value or source ~= descriptor.element then
			return
		end
		if target ~= source then
			modLine.line = modLine.line:gsub(" " .. source .. " Resistance$", " " .. target .. " Resistance")
			table.insert(swaps, { from = source, to = target, value = tonumber(value) })
			table.insert(swappedLineIndexes, descriptor.lineIndex)
		end
	end
	item:BuildAndParseRaw()
	return item, swaps, swappedLineIndexes
end

return M
