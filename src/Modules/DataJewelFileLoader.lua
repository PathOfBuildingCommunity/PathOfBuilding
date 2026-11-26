-- Path of Building
--
-- Module: Jewel Data File Loader
-- Loads compressed jewel data from one file or a numbered set of parts.
--
local t_concat = table.concat

-- Keep temporary and backup paths beside the cache so renames stay on one
-- volume. A per-write suffix reduces collisions between concurrent writes.
local function makeSiblingPaths(cachePath)
	local allocationAddressToken = tostring({ }):match("0x(%x+)") or "unknown"
	local suffix = os.time() .. "." .. allocationAddressToken
	return cachePath .. ".tmp." .. suffix, cachePath .. ".backup." .. suffix
end

local function promoteCache(cachePath, temporaryPath, backupPath)
	local promoted, promoteError = os.rename(temporaryPath, cachePath)
	if promoted then
		return true
	end

	-- Windows cannot rename over an existing file. Move the current cache aside
	-- before retrying so a failed replacement can restore the previous data.
	local backedUp, backupError = os.rename(cachePath, backupPath)
	if not backedUp then
		os.remove(temporaryPath)
		return nil, promoteError or backupError
	end

	promoted, promoteError = os.rename(temporaryPath, cachePath)
	if promoted then
		local removed, removeError = os.remove(backupPath)
		if not removed then
			ConPrintf("Failed to remove jewel data cache backup " .. backupPath .. ": " .. tostring(removeError))
		end
		return true
	end

	local restored, restoreError = os.rename(backupPath, cachePath)
	os.remove(temporaryPath)
	if not restored then
		return nil, tostring(promoteError) .. "; cache backup remains at " .. backupPath
			.. " after restore failed: " .. tostring(restoreError)
	end
	return nil, promoteError
end

local function writeCache(cachePath, jewelData)
	local temporaryPath, backupPath = makeSiblingPaths(cachePath)
	local temporaryFile, openError = io.open(temporaryPath, "wb")
	if not temporaryFile then
		return nil, openError
	end

	local written, writeError = temporaryFile:write(jewelData)
	local closed, closeError = temporaryFile:close()
	if not written or not closed then
		os.remove(temporaryPath)
		return nil, writeError or closeError
	end

	return promoteCache(cachePath, temporaryPath, backupPath)
end

local function loadJewelFile(jewelTypeName, cacheUncompressed)
	local jewelPath = "/Data/TimelessJewelData/" .. jewelTypeName
	local scriptPath = GetScriptPath()
	if scriptPath == "" then
		-- The desktop app supplies its script folder. Headless tests may start in
		-- either the repository root or the src folder, so check both locations.
		local relativePath = "." .. jewelPath
		local file = io.open(relativePath .. ".zip", "rb") or io.open(relativePath .. ".zip.part0", "rb") or io.open(relativePath .. ".bin", "rb")
		if file then
			file:close()
			scriptPath = "."
		else
			scriptPath = "./src"
		end
	end
	cacheUncompressed = cacheUncompressed ~= false

	local uncompressedFileAttr = { }
	if cacheUncompressed then
		local fileHandle = NewFileSearch(scriptPath .. jewelPath .. ".bin")
		if fileHandle then
			uncompressedFileAttr.fileName = fileHandle:GetFileName()
			uncompressedFileAttr.modified = fileHandle:GetFileModifiedTime()
		end
	end

	local compressedFileAttr = { }
	local fileHandle = NewFileSearch(scriptPath .. jewelPath .. ".zip")
	if fileHandle then
		compressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end
	fileHandle = NewFileSearch(scriptPath .. jewelPath .. ".zip.part*")
	if fileHandle then
		compressedFileAttr.modified = fileHandle:GetFileModifiedTime()
	end

	if uncompressedFileAttr.modified and uncompressedFileAttr.modified > (compressedFileAttr.modified or 0) then
		local uncompressedFile = io.open(scriptPath .. jewelPath .. ".bin", "rb")
		if uncompressedFile then
			local jewelData = uncompressedFile:read("*a")
			uncompressedFile:close()
			if jewelData and jewelData ~= "" then
				ConPrintf("Uncompressed jewel data is up-to-date, loading " .. uncompressedFileAttr.fileName)
				return jewelData
			end
		end
	end

	if cacheUncompressed then
		ConPrintf("Failed to load " .. scriptPath .. jewelPath .. ".bin, or data is out of date, falling back to compressed file")
	end
	local compressedFile = io.open(scriptPath .. jewelPath .. ".zip", "rb")
	local compressedData
	if compressedFile then
		compressedData = compressedFile:read("*a")
		compressedFile:close()
	else
		local splitFile = { }
		local part = 0
		while true do
			local file = io.open(scriptPath .. jewelPath .. ".zip.part" .. part, "rb")
			if not file then
				break
			end
			splitFile[part + 1] = file:read("*a")
			file:close()
			part = part + 1
		end
		compressedData = t_concat(splitFile, "")
	end

	if not compressedData or compressedData == "" then
		ConPrintf("Failed to load jewel data: " .. jewelTypeName)
		return
	end

	local jewelData = Inflate(compressedData)
	if not jewelData or jewelData == "" then
		ConPrintf("Failed to inflate jewel data: " .. jewelTypeName)
		return
	end
	if cacheUncompressed then
		local cached, cacheError = writeCache(scriptPath .. jewelPath .. ".bin", jewelData)
		if not cached then
			ConPrintf("Failed to cache jewel data " .. jewelTypeName .. ": " .. tostring(cacheError))
		end
	end
	return jewelData
end

return loadJewelFile
