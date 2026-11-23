describe("Extensions loader", function()
	local originalFileSearch
	local originalLoadfile
	local extensions
	local files

	before_each(function()
		originalFileSearch = _G.NewFileSearch
		originalLoadfile = _G.loadfile
		extensions = LoadModule("Modules/Extensions")
		files = { }
		_G.NewFileSearch = function(pattern)
			local names = { }
			for path in pairs(files) do
				local folder, name = path:match("^(.*/)([^/]+%.lua)$")
				if folder and folder.."*.lua" == pattern then
					table.insert(names, name)
				end
			end
			if not names[1] then return end
			local index = 1
			return {
				GetFileName = function() return names[index] end,
				NextFile = function()
					index = index + 1
					return names[index] ~= nil
				end,
			}
		end
		_G.loadfile = function(path)
			local source = files[path]
			if source == nil then
				return nil, "cannot open "..path
			end
			return loadstring(source, "="..path)
		end
	end)

	after_each(function()
		_G.NewFileSearch = originalFileSearch
		_G.loadfile = originalLoadfile
	end)

	it("loads nothing when there is no folder or no extension files", function()
		extensions:Load(nil)
		assert.are.same(0, #extensions.list)

		extensions:Load("Extensions/")
		assert.are.same(0, #extensions.list)
		extensions:Call("OnFrame")
	end)

	it("loads extensions in file name order and passes callback arguments", function()
		files["Extensions/b.lua"] = "return { OnBuildFrame = function(ext, build) ext.seen = build end }"
		files["Extensions/a.lua"] = "return { name = 'First' }"

		extensions:Load("Extensions/")
		local build = { }
		extensions:Call("OnBuildFrame", build)

		assert.are.same(2, #extensions.list)
		assert.are.same("First", extensions.list[1].name)
		assert.are.same("b.lua", extensions.list[2].name)
		assert.are.equal(build, extensions.list[2].seen)
	end)

	it("skips files that fail to load or don't return a table", function()
		files["Extensions/broken.lua"] = "return {"
		files["Extensions/throws.lua"] = "error('boom')"
		files["Extensions/number.lua"] = "return 42"
		files["Extensions/good.lua"] = "return { }"

		extensions:Load("Extensions/")

		assert.are.same(1, #extensions.list)
		assert.are.same("good.lua", extensions.list[1].name)
	end)

	it("disables an extension whose callback errors and keeps calling the others", function()
		files["Extensions/a.lua"] = "return { calls = 0, OnFrame = function(ext) ext.calls = ext.calls + 1; error('boom') end }"
		files["Extensions/b.lua"] = "return { calls = 0, OnFrame = function(ext) ext.calls = ext.calls + 1 end }"

		extensions:Load("Extensions/")
		extensions:Call("OnFrame")
		extensions:Call("OnFrame")

		assert.is_true(extensions.list[1].disabled)
		assert.are.same(1, extensions.list[1].calls)
		assert.are.same(2, extensions.list[2].calls)
	end)
end)

describe("Extensions hook", function()
	it("is loaded by main and called once the build has recalculated", function()
		assert.is_not_nil(main.extensions)
		local originalList = main.extensions.list
		local seen
		main.extensions.list = { { name = "Spy", OnBuildFrame = function(_, b) seen = { b, b.buildFlag } end } }

		newBuild()
		build.buildFlag = true
		runCallback("OnFrame")
		main.extensions.list = originalList

		assert.are.equal(build, seen[1])
		assert.is_false(seen[2])
	end)
end)
