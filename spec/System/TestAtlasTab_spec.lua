describe("AtlasTab", function()
	local libraryPath

	local function readFile(path)
		local file = io.open(path, "r")
		if not file then
			return nil
		end
		local text = file:read("*a")
		file:close()
		return text
	end

	local function atlasSection(title, targetId, variant)
		local spec = new("AtlasSpec"):AtlasSpec("3_30", title)
		spec:AllocNode(spec.tree.nodes[targetId])
		local text = '<Spec title="' .. title .. '" treeVersion="3_30" nodes="' .. table.concat(spec:GetAllocatedIds(), ",") .. '">'
		if variant then
			text = text .. '<Variant nodeId="' .. targetId .. '" effect="' .. variant .. '"/>'
		end
		return text .. "</Spec>"
	end

	before_each(function()
		libraryPath = os.tmpname()
		os.remove(libraryPath)
		main.atlasLibrary = new("AtlasLibrary"):AtlasLibrary(libraryPath)
		wipeTable(main.popups)
		newBuild()
	end)

	after_each(function()
		os.remove(libraryPath)
	end)

	it("hooks into the build without triggering calculations", function()
		local tab = build.atlasTab
		assert.are.equal(latestAtlasTreeVersion, tab.spec.treeVersion)
		build.controls.modeAtlas.onClick()
		assert.are.equal("ATLAS", build.viewMode)
		runCallback("OnFrame")
		build.buildFlag = false
		tab:HandleNodeClick(tab.spec.tree.nodes[63753])
		assert.are.equal(12, tab.spec:CountAllocNodes())
		runCallback("OnFrame")
		assert.is_false(build.buildFlag)
		assert.is_truthy((readFile(libraryPath) or ""):find("63753", 1, true))
		tab:HandleNodeClick(tab.spec.tree.nodes[57123])
		assert.are.equal(10, tab.spec:CountAllocNodes())
		tab:HandleNodeClick(tab.spec.tree.nodes[45404])
		assert.is_not_nil(main.popups[1])
		main.popups[1].controls.variant.selFunc(2)
		assert.are.equal(5301, tab.spec.variantSelections[45404])
		main:ClosePopup()
		tab:ClearActiveSpec()
		assert.are.equal(0, tab.spec:CountAllocNodes())
		tab.spec:Undo()
		assert.is_true(tab.spec:CountAllocNodes() > 0)
	end)

	it("draws the tab and builds node tooltips", function()
		local tab = build.atlasTab
		local viewPort = { x = 0, y = 0, width = 1600, height = 900 }
		tab:Draw(viewPort, { })
		tab.spec:AllocNode(tab.spec.tree.nodes[45404])
		tab:Draw(viewPort, { })
		local mastery = tab.spec.tree.masteries[1]
		for _, node in ipairs({ tab.spec.tree.nodes[63753], tab.spec.tree.nodes[45404], tab.spec.tree.nodes[17000], tab.spec.tree.nodes[57123], mastery }) do
			assert.is_true(tab.viewer.tooltip:CheckForUpdate(node, tab.spec.revision))
			tab.viewer:AddNodeTooltip(tab.viewer.tooltip, tab.spec, node, { })
			tab.viewer.tooltip:Draw(100, 100, 20, 20, viewPort)
		end
		tab.statPanel:Draw({ x = 1280, y = 0, width = 320, height = 868 }, { })
		local view = tab.viewer
		local node = tab.spec.tree.nodes[57123]
		assert.are.equal(node, view:GetNodeAt(tab.spec, node.x, node.y))
		assert.are.equal(mastery, view:GetNodeAt(tab.spec, mastery.x, mastery.y))
		local x, y = view:ScreenToTree(view:TreeToScreen(100, -200))
		assert.is_true(math.abs(x - 100) < 0.01 and math.abs(y + 200) < 0.01)
	end)

	it("highlights nodes and clusters that share a name", function()
		local tree = build.atlasTab.spec.tree
		assert.are.equal(2, #tree:GetNodesWithSameName(tree.nodes[17000]))
		local breach = 0
		for _, mastery in ipairs(tree.masteries) do
			if mastery.dn == "Breach" then
				breach = breach + 1
			end
		end
		local breachMastery
		for _, mastery in ipairs(tree.masteries) do
			if mastery.dn == "Breach" then
				breachMastery = mastery
			end
		end
		assert.are.equal(breach, #tree:GetNodesWithSameName(breachMastery))
		assert.is_true(#tree:GetNodesWithSameName(tree.nodes[55117]) > 10)
		assert.are.equal(0, #tree:GetNodesWithSameName(tree.nodes[29045]))
	end)

	it("persists atlas trees in the library file", function()
		local tab = build.atlasTab
		tab.spec:AllocNode(tab.spec.tree.nodes[63753])
		tab.spec:AddUndoState()
		local second = tab:NewSpec("Breach farming")
		second:AllocNode(second.tree.nodes[45404])
		second:SetVariant(45404, 55878)
		second:AddUndoState()
		tab:Draw({ x = 0, y = 0, width = 1600, height = 900 }, { })
		local reloaded = new("AtlasLibrary"):AtlasLibrary(libraryPath)
		assert.are.equal(2, #reloaded.specList)
		assert.are.equal("Breach farming", reloaded.specList[2].title)
		assert.are.equal(12, reloaded.specList[1]:CountAllocNodes())
		assert.are.equal(55878, reloaded.specList[2].variantSelections[45404])
		assert.are.equal(2, reloaded.activeSpec)
		build.viewMode = "ATLAS"
		local xml = build:SaveDB("code")
		assert.is_truthy(xml:find('viewMode="TREE"', 1, true))
		assert.is_nil(xml:find("<Atlas", 1, true))
	end)

	it("imports atlas trees from older build files once", function()
		local section = '<Atlas activeSpec="1">' .. atlasSection("Old plan", 63753) .. atlasSection("Variant plan", 45404, 55878) .. '<Spec title="Lost" treeVersion="9_99" nodes="57123"/></Atlas>'
		local xml = build:SaveDB("code"):gsub("</PathOfBuilding>", section .. "</PathOfBuilding>")
		loadBuildFromXML(xml)
		local list = build.atlasTab.specList
		assert.are.equal(2, #list)
		assert.are.equal("Old plan", list[1].title)
		assert.are.equal(12, list[1]:CountAllocNodes())
		assert.are.equal(55878, list[2].variantSelections[45404])
		loadBuildFromXML(xml)
		assert.are.equal(2, #build.atlasTab.specList)
		for _, popup in ipairs(main.popups) do
			assert.are_not.equal("Unknown Passive Tree Version", popup.title)
		end
	end)

	it("round-trips share links", function()
		local spec = build.atlasTab.spec
		spec:AllocNode(spec.tree.nodes[45404])
		spec:SetVariant(45404, 5301)
		local link = spec:EncodeURL()
		assert.is_truthy(link:find("^https://www.pathofexile.com/fullscreen%-atlas%-skill%-tree/AAAABgAA"))
		local other = new("AtlasSpec"):AtlasSpec(spec.treeVersion)
		assert.is_true(other:DecodeURL(link))
		assert.are.same(spec:GetAllocatedIds(), other:GetAllocatedIds())
		assert.are.equal(5301, other.variantSelections[45404])
		local bare = new("AtlasSpec"):AtlasSpec(spec.treeVersion)
		assert.is_true(bare:DecodeURL(link:match("[^/]+$")))
		assert.is_false((other:DecodeURL("garbage")))
		assert.are.same(spec:GetAllocatedIds(), other:GetAllocatedIds())
	end)

	it("summarises stats", function()
		local spec = build.atlasTab.spec
		spec:AllocNode(spec.tree.nodes[55117])
		spec:AllocNode(spec.tree.nodes[64048])
		local found = 0
		for _, category in ipairs(spec:GetStatSummary()) do
			for _, line in ipairs(category.lines) do
				if line.text == "4% increased Maps found in your Maps" then
					found = found + 1
					assert.are.equal(2, #line.nodes)
					assert.are.equal("Misc", category.category)
				end
			end
		end
		assert.are.equal(1, found)
		spec:AllocNode(spec.tree.nodes[3204])
		local breach = false
		for _, category in ipairs(spec:GetStatSummary()) do
			for _, line in ipairs(category.lines) do
				assert.is_nil(line.text:find("[", 1, true))
				if category.category == "Breach" and line.text:find("^Unstable Breaches in your Maps are 10%% faster") then
					breach = true
				end
			end
		end
		assert.is_true(breach)
	end)
end)
