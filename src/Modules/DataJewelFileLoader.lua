-- Path of Building
--
-- Module: Jewel Data File Loader
-- Loads compressed jewel data from one file or a numbered set of parts.
--
local t_concat = table.concat

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
		ConPrintf("Uncompressed jewel data is up-to-date, loading " .. uncompressedFileAttr.fileName)
		local uncompressedFile = io.open(scriptPath .. jewelPath .. ".bin", "rb")
		if uncompressedFile then
			local jewelData = uncompressedFile:read("*a")
			uncompressedFile:close()
			if jewelData then
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
	if cacheUncompressed then
		local uncompressedFile = io.open(scriptPath .. jewelPath .. ".bin", "wb+")
		if uncompressedFile then
			uncompressedFile:write(jewelData)
			uncompressedFile:close()
		end
	end
	return jewelData
end

return loadJewelFile
