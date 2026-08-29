describe("Data jewel file loader", function()
	local originalConPrintf
	local originalGetScriptPath
	local originalInflate
	local originalNewFileSearch
	local originalOpen
	local originalRemove
	local originalRename
	local files, modifiedTimeByPath
	local writePath
	local renameFile
	local renameOverride
	local loadJewelFile
	local cachePath
	local compressedFilePath

	local function setInputs(cacheData, cacheModified, inflatedData)
		files[cachePath] = cacheData
		modifiedTimeByPath[cachePath] = cacheModified
		files[compressedFilePath] = "compressed data"
		modifiedTimeByPath[compressedFilePath] = 10
		_G.Inflate = function() return inflatedData end
	end

	before_each(function()
		originalConPrintf = _G.ConPrintf
		originalGetScriptPath = _G.GetScriptPath
		originalInflate = _G.Inflate
		originalNewFileSearch = _G.NewFileSearch
		originalOpen = io.open
		originalRemove = os.remove
		originalRename = os.rename
		files = { }
		modifiedTimeByPath = { }
		writePath = nil
		cachePath = "./Data/TimelessJewelData/TestJewel.bin"
		compressedFilePath = "./Data/TimelessJewelData/TestJewel.zip"

		_G.ConPrintf = function() end
		_G.GetScriptPath = function() return "." end
		_G.NewFileSearch = function(path)
			if modifiedTimeByPath[path] == nil then
				return
			end
			return {
				GetFileName = function() return path end,
				GetFileModifiedTime = function() return modifiedTimeByPath[path] end,
			}
		end
		io.open = function(path, mode)
			if mode == "rb" then
				if files[path] == nil then
					return
				end
				return {
					read = function() return files[path] end,
					close = function() return true end,
				}
			end
			if mode == "wb" then
				writePath = path
				local pendingData
				local file = { }
				function file:write(data)
					pendingData = data
					return self
				end
				function file:close()
					files[path] = pendingData or ""
					return true
				end
				return file
			end
		end
		renameFile = function(sourcePath, destinationPath)
			if files[sourcePath] == nil then
				return nil, "source does not exist"
			end
			files[destinationPath] = files[sourcePath]
			files[sourcePath] = nil
			return true
		end
		os.rename = function(sourcePath, destinationPath)
			if renameOverride then
				local handled, renameResult, renameError = renameOverride(sourcePath, destinationPath)
				if handled then
					return renameResult, renameError
				end
			end
			return renameFile(sourcePath, destinationPath)
		end
		os.remove = function(path)
			if files[path] == nil then
				return nil, "file does not exist"
			end
			files[path] = nil
			return true
		end

		loadJewelFile = LoadModule("Modules/DataJewelFileLoader")
	end)

	after_each(function()
		_G.ConPrintf = originalConPrintf
		_G.GetScriptPath = originalGetScriptPath
		_G.Inflate = originalInflate
		_G.NewFileSearch = originalNewFileSearch
		io.open = originalOpen
		os.remove = originalRemove
		os.rename = originalRename
	end)

	it("falls back from a newer zero-byte cache", function()
		setInputs("", 20, "fresh jewel data")

		local jewelData = loadJewelFile("TestJewel")

		assert.are.equal("fresh jewel data", jewelData)
		assert.are.equal("fresh jewel data", files[cachePath])
		assert.is_truthy(writePath:find(cachePath .. ".tmp.", 1, true))
	end)

	it("rejects empty inflation without opening the cache for writing", function()
		setInputs("previous jewel data", 5, "")

		local jewelData = loadJewelFile("TestJewel")

		assert.is_nil(jewelData)
		assert.are.equal("previous jewel data", files[cachePath])
		assert.is_nil(writePath)
	end)

	it("restores the previous cache when promotion fails", function()
		setInputs("previous jewel data", 5, "fresh jewel data")
		local promotionAttempts = 0
		renameOverride = function(sourcePath, destinationPath)
			if destinationPath == cachePath and sourcePath:find(cachePath .. ".tmp.", 1, true) == 1 then
				promotionAttempts = promotionAttempts + 1
				return true, nil, "promotion failed"
			end
			return false
		end

		local jewelData = loadJewelFile("TestJewel")

		assert.are.equal("fresh jewel data", jewelData)
		assert.are.equal("previous jewel data", files[cachePath])
		assert.are.equal(2, promotionAttempts)
		for path in pairs(files) do
			assert.is_falsy(path:find(cachePath .. ".tmp.", 1, true))
			assert.is_falsy(path:find(cachePath .. ".backup.", 1, true))
		end
	end)
end)
