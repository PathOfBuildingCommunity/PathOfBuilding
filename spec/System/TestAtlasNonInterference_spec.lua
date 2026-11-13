describe("Atlas non-interference", function()
	local libraryPath

	local function snapshot()
		local values = { }
		for key, value in pairs(build.calcsTab.mainOutput) do
			if type(value) == "number" then
				values[key] = value
			end
		end
		return values
	end

	local function atlasSection()
		local parts = { '<Atlas activeSpec="1">' }
		for index, target in ipairs({ 63753, 45404, 3204 }) do
			local spec = new("AtlasSpec"):AtlasSpec("3_30")
			spec:AllocNode(spec.tree.nodes[target])
			table.insert(parts, '<Spec title="Plan ' .. index .. '" treeVersion="3_30" nodes="' .. table.concat(spec:GetAllocatedIds(), ",") .. '"/>')
		end
		table.insert(parts, "</Atlas>")
		return table.concat(parts)
	end

	before_each(function()
		libraryPath = os.tmpname()
		os.remove(libraryPath)
		main.atlasLibrary = new("AtlasLibrary"):AtlasLibrary(libraryPath)
	end)

	after_each(function()
		os.remove(libraryPath)
	end)

	local buildFiles = { }
	for file in lfs.dir("../spec/TestBuilds/3.13") do
		if file:match("%.lua$") then
			table.insert(buildFiles, file)
		end
	end
	table.sort(buildFiles)

	for _, file in ipairs(buildFiles) do
		local name = file:gsub("%.lua$", "")
		it("keeps calc output identical for " .. name, function()
			local testBuild = LoadModule("../spec/TestBuilds/3.13/" .. file)
			loadBuildFromXML(testBuild.xml, name)
			local before = snapshot()
			loadBuildFromXML(testBuild.xml:gsub("</PathOfBuilding>", atlasSection() .. "</PathOfBuilding>"), name)
			assert.are.equal(3, #build.atlasTab.specList)
			assert.is_true(build.atlasTab.specList[3]:CountAllocNodes() > 0)
			assert.are.same(before, snapshot())
			build.buildFlag = false
			build.controls.modeAtlas.onClick()
			build.atlasTab:HandleNodeClick(build.atlasTab.spec.tree.nodes[17000])
			runCallback("OnFrame")
			assert.is_false(build.buildFlag)
			assert.are.same(before, snapshot())
		end)
	end
end)
