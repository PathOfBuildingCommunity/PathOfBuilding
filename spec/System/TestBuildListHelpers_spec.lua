describe("BuildListHelpers", function()
	local originalBuildPath
	local originalCloudErrorPopup
	local originalFileSearch
	local originalOpen
	local buildListHelpers
	local fileHeaders
	local searches
	local fileOpenCount
	local searchCount
	local cloudErrorPath

	before_each(function()
		originalBuildPath = main.buildPath
		originalCloudErrorPopup = main.OpenCloudErrorPopup
		originalFileSearch = _G.NewFileSearch
		originalOpen = io.open
		buildListHelpers = LoadModule("Modules/BuildListHelpers")
		fileHeaders = { }
		searches = { }
		fileOpenCount = 0
		searchCount = 0
		cloudErrorPath = nil
		main.buildPath = "Builds/"
		main.OpenCloudErrorPopup = function(_, path)
			cloudErrorPath = path
		end
		_G.NewFileSearch = function(pattern, foldersOnly)
			searchCount = searchCount + 1
			local entries = searches[(foldersOnly and "folders:" or "files:")..pattern]
			if not entries or not entries[1] then return end
			local index = 1
			return {
				GetFileName = function() return entries[index].name end,
				GetFileModifiedTime = function() return entries[index].modified or 0 end,
				NextFile = function()
					index = index + 1
					return entries[index] ~= nil
				end,
			}
		end
		io.open = function(path)
			fileOpenCount = fileOpenCount + 1
			if fileHeaders[path] == nil then return end
			return {
				read = function() return fileHeaders[path] or nil end,
				close = function() end,
			}
		end
	end)

	after_each(function()
		main.buildPath = originalBuildPath
		main.OpenCloudErrorPopup = originalCloudErrorPopup
		_G.NewFileSearch = originalFileSearch
		io.open = originalOpen
	end)

	it("filters a recursive index without rescanning files", function()
		searches["files:Builds/*.xml"] = { { name = "Root.xml", modified = 1 } }
		searches["folders:Builds/*"] = { { name = "League", modified = 2 } }
		searches["files:Builds/League/*.xml"] = { { name = "Nested.xml", modified = 3 } }
		fileHeaders["Builds/Root.xml"] = '<Build level="80" className="Witch" ascendClassName="Occultist">'
		fileHeaders["Builds/League/Nested.xml"] = '<Build level="90" className="Shadow" ascendClassName="Assassin">'

		local index = buildListHelpers.ScanFolder("")
		local scansAfterIndex = searchCount
		local opensAfterIndex = fileOpenCount
		local directEntries = buildListHelpers.FilterList(index, "", "")
		local classMatches = buildListHelpers.FilterList(index, "", "CLASS:assassin")

		assert.are.same(3, #index)
		assert.are.same(2, #directEntries)
		assert.are.same("Nested.xml", classMatches[1].fileName)
		assert.are.same("League/", classMatches[1].subPath)
		assert.are.same(scansAfterIndex, searchCount)
		assert.are.same(opensAfterIndex, fileOpenCount)
	end)

	it("reports cloud read failures", function()
		searches["files:Builds/*.xml"] = { { name = "Cloud.xml" } }
		fileHeaders["Builds/Cloud.xml"] = false

		local index = buildListHelpers.ScanFolder("")

		assert.are.same(0, #index)
		assert.are.same("Builds/Cloud.xml", cloudErrorPath)
	end)

	it("blocks descendant folder targets and selects duplicate filenames by path", function()
		local rootFolder = { folderName = "Alpha", subPath = "" }
		local childFolder = { folderName = "Beta", subPath = "Alpha/" }
		local firstBuild = { fileName = "Same.xml", subPath = "Alpha/", fullFileName = "Builds/Alpha/Same.xml" }
		local secondBuild = { fileName = "Same.xml", subPath = "Other/", fullFileName = "Builds/Other/Same.xml" }
		local listMode = {
			list = { firstBuild, secondBuild },
			subPath = "",
			BuildList = function() end,
		}
		local control = new("BuildListControl"):BuildListControl(nil, { 0, 0, 500, 500 }, listMode)

		control:SelByFullFileName("Builds/Other/Same.xml")

		assert.are.same(secondBuild, control.selValue)
		assert.is_false(control:CanDragToValue(1, childFolder, { selValue = rootFolder }))
		assert.is_true(buildListHelpers.CanMoveToSubPath(rootFolder, "Other/"))
		control:SelByFullFileName("Builds/Missing.xml")
		assert.is_nil(control.selValue)
	end)
end)
