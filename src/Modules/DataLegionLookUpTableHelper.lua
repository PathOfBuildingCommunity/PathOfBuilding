-- Path of Building
--
-- Module: Data Legion Look Up Table Helper
-- Contains functions for managing the LUTs for the data module
--
local t_concat = table.concat

-- Load legion jewel data
local function loadJewelFile(jewelTypeName)
	jewelTypeName = "/Data/TimelessJewelData/" .. jewelTypeName
	local jewelData

	local scriptPath = GetScriptPath()

	local fileHandle = NewFileSearch(scriptPath .. jewelTypeName .. ".bin")
	local uncompressedFileAttr = { }
	if fileHandle then
		uncompressedFileAttr.fileName = fileHandle:GetFileName()
		uncompressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end

	fileHandle = NewFileSearch(scriptPath .. jewelTypeName .. ".zip")
	local compressedFileAttr = { }
	if fileHandle then
		compressedFileAttr.fileName = fileHandle:GetFileName()
		compressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end

	fileHandle = NewFileSearch(scriptPath .. jewelTypeName .. ".zip.part*")
	local splitFile = { }
	if fileHandle then
		compressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end
	while fileHandle do
		local fileName = fileHandle:GetFileName()
		local file = io.open(scriptPath .. "/Data/TimelessJewelData/" .. fileName, "rb")
		local part = tonumber(fileName:match("%.part(%d)")) or 0
		splitFile[part + 1] = file:read("*a")
		file:close()
		if not fileHandle:NextFile() then
			break
		end
	end
	splitFile = t_concat(splitFile, "")

	if uncompressedFileAttr.modified and uncompressedFileAttr.modified > (compressedFileAttr.modified or 0) then
		ConPrintf("Uncompressed jewel data is up-to-date, loading " .. uncompressedFileAttr.fileName)
		local uncompressedFile = io.open(scriptPath .. jewelTypeName .. ".bin", "rb")
		if uncompressedFile then
			jewelData = uncompressedFile:read("*a")
			uncompressedFile:close()
		end
		if jewelData then
			return jewelData
		end
	end

	ConPrintf("Failed to load " .. scriptPath .. jewelTypeName .. ".bin, or data is out of date, falling back to compressed file")
	local compressedFile = io.open(scriptPath .. jewelTypeName .. ".zip", "rb")
	if compressedFile then
		jewelData = Inflate(compressedFile:read("*a"))
		compressedFile:close()
	elseif splitFile ~= "" then
		jewelData = Inflate(splitFile)
	end

	if jewelData == nil then
		ConPrintf("Failed to load either file: " .. jewelTypeName .. ".zip, " .. jewelTypeName .. ".bin")
	else
		local uncompressedFile = io.open(scriptPath .. jewelTypeName .. ".bin", "wb+")
		if uncompressedFile then
			uncompressedFile:write(jewelData)
			uncompressedFile:close()
		end
	end
	return jewelData
end

-- lazy load a specific timeless jewel type
-- valid values: "Glorious Vanity", "Lethal Pride", "Brutal Restraint", "Militant Faith", "Elegant Hubris"
-- nodeID is needed for "Glorious Vanity"
local function loadTimelessJewel(jewelType, nodeID)
	local nodeIndex = nil
	if nodeID and data.nodeIDList[nodeID] then
		nodeIndex = data.nodeIDList[nodeID].index
	end
	-- for GV, if nodeIndex is invalid, return
	if jewelType == 1 and nodeIndex == nil then
		return
	end
	-- if LUT is already loaded, and this either isn't GV, or GV has already emptied it's raw data out, return
	if data.timelessJewelLUTs[jewelType] and data.timelessJewelLUTs[jewelType].data and (jewelType ~= 1 or data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw == nil) then
		return
	end

	if jewelType == 1 then
		-- if data is already loaded but table for specific node is not created, just make table and return
		if data.timelessJewelLUTs[jewelType] and data.timelessJewelLUTs[jewelType].data[nodeIndex + 1] and data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw then
			local jewelData = data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw
			local seedSize = data.timelessJewelSeedMax[1] - data.timelessJewelSeedMin[1] + 1
			local count = 0
			for seedOffset = 1, (seedSize + 1) do
				local dataLength = data.timelessJewelLUTs[jewelType].sizes:byte(nodeIndex * seedSize + seedOffset)
				data.timelessJewelLUTs[jewelType].data[nodeIndex + 1][seedOffset] = jewelData:sub(count + 1, count + dataLength)
				count = count + dataLength
			end
			data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw = nil
			return
		end
		data.timelessJewelLUTs[jewelType] = { data = { } }
	else
		data.timelessJewelLUTs[jewelType] = { }
	end

	ConPrintf("LOADING")

	local jewelData = loadJewelFile(data.timelessJewelTypes[jewelType]:gsub("%s+", ""))

	if jewelData then
		if jewelType == 1 then -- "Glorious Vanity"
			local GV_nodecount = data.nodeIDList.size
			local seedSize = data.timelessJewelSeedMax[1] - data.timelessJewelSeedMin[1] + 1
			local sizeOffset = GV_nodecount * seedSize
			data.timelessJewelLUTs[jewelType].sizes = jewelData:sub(1, sizeOffset + 1)

			-- Loop through nodes in order as if we were reading from a file
			for i = 1, GV_nodecount do
				-- Find the node this corresponds to
				local nodeID
				for k, v in pairs(data.nodeIDList) do
					if type(v) == "table" and v.index == (i - 1) then
						nodeID = k
						break
					end
				end
				-- Preliminary initialization
				local seedDataLength = data.nodeIDList[nodeID].size
				data.timelessJewelLUTs[jewelType].data[i] = {}
				data.timelessJewelLUTs[jewelType].data[i].raw = jewelData:sub(sizeOffset + 1, sizeOffset + seedDataLength)
				sizeOffset = sizeOffset + seedDataLength
				if i == (nodeIndex + 1) then
					-- Final initialization for this seed
					local jewelData2 = data.timelessJewelLUTs[jewelType].data[nodeIndex + 1].raw
					local seedOffset = 0
					for seedKey = 1, (seedSize + 1) do
						local dataLength = data.timelessJewelLUTs[jewelType].sizes:byte(nodeIndex * seedSize + seedKey)
						data.timelessJewelLUTs[jewelType].data[nodeIndex + 1][seedKey] = jewelData2:sub(seedOffset + 1, seedOffset + dataLength)
						seedOffset = seedOffset + dataLength
					end
					data.timelessJewelLUTs[jewelType].data[i].raw = nil
				end
			end
			ConPrintf("Glorious Vanity Lookup Table Loaded! Read " .. sizeOffset .. " bytes")
			return
		else
			data.timelessJewelLUTs[jewelType].data = jewelData
		end
	end
end

--[[
-- the generation functions needs to be ported to LUA
local generateNode(jewelType, seed, nodeID)
	...
end

local function generateLUT(jewelType)
	local jewelData = {}
	for _, nodeID in ipairs(data.nodeIDList) do
		if nodeID.index then
			jewelData[nodeID.index] = {}
			for seed in data.timelessJewelSeedMin[jewelType], data.timelessJewelSeedMax[jewelType] do
				jewelData[nodeID.index][seed] = generateNode(jewelType, seed, nodeID)
			end
		end
	end
	return jewelData
end
--]]

 -- this doesn't rebuilt the list with the correct sizes, likely an issue with lua indexing from 1 instead of 0, but cbf debugging so just generated the index mapping in c#
 -- is disabled on the data side atm, needs to be setup correctly if we ever setup generation on the LUA side
local function repairLUTs()
	ConPrintf("Error NodeIndexMapping file empty")
	local nodeIDList = {  }
	GetScriptPath()
	for _, jewelType in ipairs({2, 3, 4, 5}) do
		loadTimelessJewel(jewelType, 1)
		local jewelTypeName = data.timelessJewelTypes[jewelType]:gsub("%s+", "")
		local jewelData = loadJewelFile(jewelTypeName)
		if not jewelData then
			ConPrintf("looking for base LUT to rebuild")
			--[[
			local jewelType = 1
			while ("/Data/TimelessJewelData/" .. data.timelessJewelTypes[jewelType]:gsub("%s+", "")) ~= jewelTypeName and jewelType < 5 do
				jewelType = jewelType + 1
			end
			--]]
			local compressedFile = io.open(scriptPath .. "/Data/TimelessJewelData/" .. data.timelessJewelTypes[jewelType], "rb")
			if compressedFile then
				ConPrintf("base LUT found: " .. jewelTypeName)
				jewelData = compressedFile:read("*a")
				compressedFile:close()

				--- Code for compressing existing data if it changed
				local compressedFileData = Deflate(jewelData)
				local file = assert(io.open(scriptPath .. "Data/TimelessJewelData/" .. jewelTypeName .. ".zip", "wb+"))
				file:write(compressedFileData)
				file:close()
				if jewelType == 1 then
					ConPrintf("GV needs to be split manually")
				end
			end
		end
	end
	jewelData = loadJewelFile(data.timelessJewelTypes[1]:gsub("%s+", ""))
	if not jewelData then
		ConPrintf("missing GV file to rebuild NodeIndexMapping")
	else
		ConPrintf("attempting to rebuild NodeIndexMapping")
		local scriptPath = GetScriptPath()
		local compressedFile = io.open(scriptPath .. "/Data/TimelessJewelData/node_indices.csv", "rb")
		if compressedFile then
			ConPrintf("csv found")
			local nodeData = compressedFile:read("*a")
			compressedFile:close()
			
			tempIndList = {}
			nodeIDList["size"] = 0
			nodeIDList["sizeNotable"] = 0
			for line in nodeData:gmatch("([^\n]*)\n?") do
				nodeIDList["size"] = nodeIDList["size"] + 1
				if nodeIDList["size"] ~= 1 then
					for split in line:gmatch("([^,]*),?") do
						if tonumber(split) then
							tempIndList[nodeIDList["size"] - 1] = tonumber(split)
							if nodeIDList["size"] ~= 2 and tempIndList[nodeIDList["size"] - 1] < tempIndList[nodeIDList["size"] - 2] then
								nodeIDList["sizeNotable"] = nodeIDList["size"] - 2
							end
						end
						break
					end
				end
			end
			nodeIDList["size"] = nodeIDList["size"] - 2
			ConPrintf(nodeIDList["sizeNotable"])
			ConPrintf(nodeIDList["size"])
			
			
			local seedSize = data.timelessJewelSeedMax[1] - data.timelessJewelSeedMin[1] + 1
			local sizeOffset = nodeIDList.size * seedSize
			data.timelessJewelLUTs[1] = {}
			data.timelessJewelLUTs[1].sizes = jewelData:sub(1, sizeOffset + 1)
			for i, nodeID in ipairs(tempIndList) do
				local nodeIndex = i - 1
				local count = 0
				if i > nodeIDList["sizeNotable"] then
					count = seedSize * 2
				else
					for seedOffset = 1, (seedSize + 1) do
						local dataLength = data.timelessJewelLUTs[1].sizes:byte(nodeIndex * seedSize + seedOffset)
						count = count + dataLength
					end
				end
				nodeIDList[nodeID] = { index = nodeIndex, size = count }
			end
			
			local file = assert(io.open("Data/TimelessJewelData/NodeIndexMapping.lua", "wb+"))
			file:write("nodeIDList = { }\n")
			file:write("nodeIDList[\"size\"] = " .. tostring(nodeIDList["size"]) .. "\n")
			file:write("nodeIDList[\"sizeNotable\"] = " .. tostring(nodeIDList["sizeNotable"]) .. "\n")
			for _, nodeID in ipairs(tempIndList) do
				file:write("nodeIDList[" .. tostring(nodeID) .. "] = { index = " .. tostring(nodeIDList[nodeID].index) .. ", size = " .. tostring(nodeIDList[nodeID].size) .. " }\n")
			end
			file:write("return nodeIDList")
			file:close()
			return nodeIDList
		else
			ConPrintf("csv missing, cannot rebuild NodeIndexMapping")
		end
	end
end

local function readLUT(seed, nodeID, jewelType)
	loadTimelessJewel(jewelType, nodeID)
	if jewelType == 1 then
		assert(next(data.timelessJewelLUTs[jewelType].data), "Error occurred loading Glorious Vanity data")
	else
		assert(data.timelessJewelLUTs[jewelType].data, "Error occurred loading Timeless Jewel data")
	end
	 -- "Elegant Hubris"
	if jewelType == 5 then
		seed = seed / 20
	end
	local seedOffset = (seed - data.timelessJewelSeedMin[jewelType])
	local seedSize = (data.timelessJewelSeedMax[jewelType] - data.timelessJewelSeedMin[jewelType]) + 1
	local index = data.nodeIDList[nodeID] and data.nodeIDList[nodeID].index or nil
	if index then
		-- "Glorious Vanity"
		if jewelType == 1 then
			local result = { }

			for i = 1, data.timelessJewelLUTs[jewelType].sizes:byte(index * seedSize + seedOffset + 1) do
				result[i] = data.timelessJewelLUTs[jewelType].data[index + 1][seedOffset + 1]:byte(i)
			end
			return result
		elseif index <= data.nodeIDList["sizeNotable"] then
			return { data.timelessJewelLUTs[jewelType].data:byte(index * seedSize + seedOffset + 1) }
		end
	else
		ConPrintf("ERROR: Missing Index lookup for nodeID: "..nodeID)
	end
	return { }
end

return readLUT, repairLUTs