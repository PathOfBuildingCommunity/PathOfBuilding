-- Path of Building
--
-- Module: Data Abyss Jewel Look Up Table Helper
-- Reads Abyss jewel data grouped by socket and Zorath data grouped by passive node.
--
local s_byte = string.byte
local s_sub = string.sub
local loadJewelFile = LoadModule("Modules/DataJewelFileLoader")

local function readUInt16(jewelData, offset)
	return bytesToUShort(jewelData, offset), offset + 2
end

-- A modification starts with its number of parts. Each part then stores whether
-- it replaces or adds stats, its stat ID, its roll count, and its two-byte rolls.
local function skipModification(jewelData, offset)
	local componentCount = s_byte(jewelData, offset)
	offset = offset + 1
	for _ = 1, componentCount do
		local statCount = s_byte(jewelData, offset + 2)
		offset = offset + 3 + statCount * 2
	end
	return offset
end

local function readModification(jewelData, offset, jewelType)
	local componentCount = s_byte(jewelData, offset)
	local modification = { }
	offset = offset + 1
	for componentIndex = 1, componentCount do
		local componentType, localId, statCount = s_byte(jewelData, offset, offset + 2)
		offset = offset + 3
		local mapping = data.nodeIDList.localIdToGlobalId
		local component = {
			type = componentType,
			id = mapping and mapping[jewelType] and mapping[jewelType][localId] or localId,
			rolls = { },
		}
		for statIndex = 1, statCount do
			local roll
			roll, offset = readUInt16(jewelData, offset)
			component.rolls[statIndex] = roll >= 32768 and roll - 65536 or roll
		end
		modification[componentIndex] = component
	end
	return modification, offset
end

-- The file uses type 1 for a full node replacement and type 2 for stats added
-- to the original node. Return the matching existing Legion node data.
local function resolveAbyssJewelComponent(component, legion)
	if component.type == 1 then
		return legion.nodes[component.id + 1 - data.timelessJewelAdditions], true
	elseif component.type == 2 then
		return legion.additions[component.id + 1], false
	end
end

local function getAbyssJewelComponentRoll(component, node, statIndex)
	local statKey, statMod
	for key, mod in pairs(node.stats) do
		if mod.index == statIndex then
			statKey, statMod = key, mod
			break
		end
	end
	local roll = statMod and component.rolls[statMod.index]
	-- A negative stored value is shown as a positive number in "reduced" descriptions.
	if roll and roll < 0 and statMod.min >= 0 then
		roll = -roll
	end
	return statKey, statMod, roll
end

local function skipSocketRecord(jewelData, offset)
	local affectedNodeCount = s_byte(jewelData, offset)
	offset = offset + 1
	for _ = 1, affectedNodeCount do
		offset = skipModification(jewelData, offset + 2)
	end
	return offset
end

local function skipAscendancyRecord(jewelData, offset)
	return offset + 1 + s_byte(jewelData, offset) * 2
end

local function parseAbyssJewel(jewelType, jewelData)
	-- The header stores the four-letter format, version, jewel type, first and
	-- last seed, and the amount between seeds.
	local format = s_sub(jewelData, 1, 4)
	local formatVersion = s_byte(jewelData, 5)
	local storedJewelType = s_byte(jewelData, 6)
	local seedMinimum, offset = readUInt16(jewelData, 7)
	local seedMaximum
	seedMaximum, offset = readUInt16(jewelData, offset)
	local seedIncrement
	seedIncrement, offset = readUInt16(jewelData, offset)
	if formatVersion ~= 1 or storedJewelType ~= jewelType or seedIncrement == 0 then
		error("Invalid Abyss timeless jewel header for jewel type " .. jewelType)
	end

	local jewelLUT = {
		data = jewelData,
		format = format,
		seedMinimum = seedMinimum,
		seedMaximum = seedMaximum,
		seedIncrement = seedIncrement,
		seedCount = (seedMaximum - seedMinimum) / seedIncrement + 1,
		seedOffsets = { },
		blockOffsets = { },
	}

	if format == "ABYS" then
		-- Each socket has one entry for every seed.
		local socketCount = s_byte(jewelData, offset)
		jewelLUT.abyssSize = s_byte(jewelData, offset + 1)
		offset = offset + 2
		local socketIds = { }
		for socketIndex = 1, socketCount do
			socketIds[socketIndex], offset = readUInt16(jewelData, offset)
		end
		for _, socketId in ipairs(socketIds) do
			jewelLUT.blockOffsets[socketId] = offset
			for _ = 1, jewelLUT.seedCount do
				offset = skipSocketRecord(jewelData, offset)
			end
		end
	elseif format == "ABYN" then
		-- Zorath has one block per passive node, so only allocated path nodes are read later.
		local nodeCount
		nodeCount, offset = readUInt16(jewelData, offset)
		local nodeIds = { }
		for nodeIndex = 1, nodeCount do
			nodeIds[nodeIndex], offset = readUInt16(jewelData, offset)
		end
		for _, nodeId in ipairs(nodeIds) do
			jewelLUT.blockOffsets[nodeId] = offset
			for _ = 1, jewelLUT.seedCount do
				offset = skipModification(jewelData, offset)
			end
		end

		if s_sub(jewelData, offset, offset + 3) ~= "ASCS" then
			error("Missing Abyss ascendancy section for jewel type " .. jewelType)
		end
		offset = offset + 4
		local ascendancyCount
		ascendancyCount, offset = readUInt16(jewelData, offset)
		jewelLUT.ascendancyOffsets = { }
		for _ = 1, ascendancyCount do
			local nameLength = s_byte(jewelData, offset)
			local ascendancyName = s_sub(jewelData, offset + 1, offset + nameLength)
			offset = offset + nameLength + 1
			jewelLUT.ascendancyOffsets[ascendancyName] = offset
			for _ = 1, jewelLUT.seedCount do
				offset = skipAscendancyRecord(jewelData, offset)
			end
		end
	else
		error("Unknown Abyss timeless jewel format " .. format)
	end
	return jewelLUT
end

local function loadAbyssJewel(jewelType)
	if data.timelessJewelLUTs[jewelType] and data.timelessJewelLUTs[jewelType].data then
		return data.timelessJewelLUTs[jewelType]
	end

	local jewelTypeName = data.timelessJewelTypes[jewelType]:gsub("%s+", "")
	local jewelData = loadJewelFile(jewelTypeName, false)
	if not jewelData then
		return
	end
	data.timelessJewelLUTs[jewelType] = parseAbyssJewel(jewelType, jewelData)
	return data.timelessJewelLUTs[jewelType]
end

local function getSeedIndex(jewelLUT, seed)
	local seedOffset = seed - jewelLUT.seedMinimum
	if seedOffset < 0 or seed > jewelLUT.seedMaximum or seedOffset % jewelLUT.seedIncrement ~= 0 then
		return
	end
	return seedOffset / jewelLUT.seedIncrement + 1
end

local function getRecordOffsets(jewelLUT, blockKey, blockOffset, skipRecord)
	if not blockOffset then
		return
	end
	if not jewelLUT.seedOffsets[blockKey] then
		-- Entry sizes vary, so remember where each seed starts after the first scan.
		local offsets = { }
		local offset = blockOffset
		for seedIndex = 1, jewelLUT.seedCount do
			offsets[seedIndex] = offset
			offset = skipRecord(jewelLUT.data, offset)
		end
		jewelLUT.seedOffsets[blockKey] = offsets
	end
	return jewelLUT.seedOffsets[blockKey]
end

local function readNode(seed, nodeId, jewelType)
	local jewelLUT = loadAbyssJewel(jewelType)
	local seedIndex = jewelLUT and getSeedIndex(jewelLUT, seed)
	if not seedIndex or jewelLUT.format ~= "ABYN" then
		return { }
	end
	local offsets = getRecordOffsets(jewelLUT, nodeId, jewelLUT.blockOffsets[nodeId], skipModification)
	return offsets and readModification(jewelLUT.data, offsets[seedIndex], jewelType) or { }
end

local function readAbyssJewelLUT(seed, socketId, jewelType, path, ascendancyName)
	if jewelType >= 7 and jewelType <= 10 then
		local jewelLUT = loadAbyssJewel(jewelType)
		local seedIndex = jewelLUT and getSeedIndex(jewelLUT, seed)
		if not seedIndex or jewelLUT.format ~= "ABYS" then
			return { }
		end
		local offsets = getRecordOffsets(jewelLUT, socketId, jewelLUT.blockOffsets[socketId], skipSocketRecord)
		if not offsets then
			return { }
		end

		local offset = offsets[seedIndex]
		local affectedNodeCount = s_byte(jewelLUT.data, offset)
		local affectedNodes = { }
		offset = offset + 1
		for _ = 1, affectedNodeCount do
			local nodeId
			nodeId, offset = readUInt16(jewelLUT.data, offset)
			affectedNodes[nodeId], offset = readModification(jewelLUT.data, offset, jewelType)
		end
		return affectedNodes
	elseif jewelType ~= 11 or not path then
		return { }
	end

	local affectedNodes = { }
	for nodeId in pairs(path) do
		local modification = readNode(seed, nodeId, jewelType)
		if next(modification) then
			affectedNodes[nodeId] = modification
		end
	end
	local jewelLUT = loadAbyssJewel(jewelType)
	local seedIndex = jewelLUT and getSeedIndex(jewelLUT, seed)
	if seedIndex and jewelLUT.format == "ABYN" then
		-- A Zorath seed selects one node in every ascendancy. A name limits the
		-- result to one ascendancy when a caller only needs that section.
		local ascendancyOffsets = jewelLUT.ascendancyOffsets
		if ascendancyName then
			ascendancyOffsets = { [ascendancyName] = ascendancyOffsets[ascendancyName] }
		end
		for name, blockOffset in pairs(ascendancyOffsets) do
			local blockKey = "ascendancy:" .. name
			local offsets = getRecordOffsets(jewelLUT, blockKey, blockOffset, skipAscendancyRecord)
			if offsets then
				local offset = offsets[seedIndex]
				local selectedCount = s_byte(jewelLUT.data, offset)
				offset = offset + 1
				for _ = 1, selectedCount do
					local nodeId
					nodeId, offset = readUInt16(jewelLUT.data, offset)
					affectedNodes[nodeId] = readNode(seed, nodeId, jewelType)
				end
			end
		end
	end
	return affectedNodes
end

return readAbyssJewelLUT, resolveAbyssJewelComponent, getAbyssJewelComponentRoll, parseAbyssJewel
