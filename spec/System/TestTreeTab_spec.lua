describe("TreeTab", function()
	local originalClusterNodeMap
	local originalMasteryEffects

	before_each(function()
		newBuild()
		originalClusterNodeMap = build.spec.tree.clusterNodeMap
		originalMasteryEffects = build.spec.tree.masteryEffects
	end)

	after_each(function()
		build.spec.tree.clusterNodeMap = originalClusterNodeMap
		build.spec.tree.masteryEffects = originalMasteryEffects
	end)

	it("adds separate power report entries for mastery effects", function()
		local treeTab = build.treeTab
		local parentNode = { id = 2 }
		local masteryNode = {
			id = 1,
			type = "Mastery",
			dn = "Two Hand Mastery",
			power = {
				masteryEffects = {
					[101] = { singleStat = 10, pathPower = 10 },
					[102] = { singleStat = 20, pathPower = 20 },
				},
			},
			masteryEffects = {
				{ effect = 101 },
				{ effect = 102 },
			},
			path = { parentNode, false },
			x = 10,
			y = 20,
		}
		masteryNode.path[2] = masteryNode

		treeTab.build.displayStats = {
			{ stat = "Damage", label = "Damage", fmt = ".1f" },
		}
		treeTab.build.spec.nodes = {
			[masteryNode.id] = masteryNode,
		}
		treeTab.build.spec.masterySelections = {}
		treeTab.build.spec.tree.clusterNodeMap = {}
		treeTab.build.spec.tree.masteryEffects = {
			[101] = { id = 101, sd = { "Gain 10 Damage" }, stats = { "Gain 10 Damage" } },
			[102] = { id = 102, sd = { "Gain 20 Damage" }, stats = { "Gain 20 Damage" } },
		}
		treeTab.build.calcsTab.mainEnv = { grantedPassives = {} }

		local report = treeTab:BuildPowerReportList({ stat = "Damage", label = "Damage" })

		assert.are.same(2, #report)
		assert.are.same("Mastery", report[1].type)
		assert.are.same("Two Hand Mastery: Gain 20 Damage", report[1].name)
		assert.are.same(20, report[1].power)
		assert.are.same(2, report[1].pathDist)
		assert.are.same(10, report[2].power)
		assert.are.same("Two Hand Mastery: Gain 10 Damage", report[2].name)
	end)

	describe("CopyTree", function()
		it("Copies a tree spec with a new name", function()
			local newTitle = "Copied Tree"
			local newSpec = build.treeTab:CopyTree(1, newTitle)

			assert.is_not.same(build.treeTab.specList[1], newSpec)
			assert.are.equals(newTitle, newSpec.title)
		end)

		it("Copies tree version from source spec", function()
			local newSpec = build.treeTab:CopyTree(1, "Copy Test")

			assert.are.equals(build.treeTab.specList[1].treeVersion, newSpec.treeVersion)
		end)

		it("Copies jewels from source spec", function()
			local newSpec = build.treeTab:CopyTree(1, "Copy Test")

			assert.are.same(build.treeTab.specList[1].jewels, newSpec.jewels)
		end)

		it("Deep copies jewel allocations", function()
			local newSpec = build.treeTab:CopyTree(1, "Copy Test")

			-- Modify source jewels
			build.treeTab.specList[1].jewels["test_node"] = "test_item"

			-- Copy should have been independent
			assert.is_nil(newSpec.jewels["test_node"])
		end)

		it("Returns new spec with next ID", function()
			local newSpec = build.treeTab:CopyTree(1, "Copy Test")

			assert.are.equals(2, newSpec.id)
		end)

		it("Adds copied spec to specList", function()
			build.treeTab:CopyTree(1, "Copy Test")

			assert.are.equals(2, #build.treeTab.specList)
			assert.is_not_nil(build.treeTab.specList[2])
		end)

		it("Copies the default spec with a suffix", function()
			local newSpec = build.treeTab:CopyTree(1)

			assert.are.equals("Default (Copy)", newSpec.title)
		end)

		it("Appends suffix to source title when no name provided", function()
			build.treeTab.specList[1].title = "My Tree"
			local newSpec = build.treeTab:CopyTree(1)

			assert.are.equals("My Tree (Copy)", newSpec.title)
		end)

		it("Copies allocNodes from source spec via undo state", function()
			-- Allocate a node in the source spec
			build.treeTab.specList[1].allocNodes = { [1] = true }

			local newSpec = build.treeTab:CopyTree(1, "Copy Test")

			-- allocNodes should be copied via RestoreUndoState
			assert.is_not_nil(newSpec.allocNodes)
		end)

		it("Handles copying when source has no jewels", function()
			build.treeTab.specList[1].jewels = {}
			local newSpec = build.treeTab:CopyTree(1, "Copy Test")

			assert.are.same({}, newSpec.jewels)
		end)

		it("Handles copying when source has no allocNodes", function()
			local oldAlloc = build.treeTab.specList[1].allocNodes
			build.treeTab.specList[1].allocNodes = nil
			-- CreateUndoState needs allocNodes to exist, so we set it to empty table
			-- but the original spec may have had no allocations
			build.treeTab.specList[1].allocNodes = {}
			local newSpec = build.treeTab:CopyTree(1, "Copy Test")
			build.treeTab.specList[1].allocNodes = oldAlloc

			assert.is_not_nil(newSpec)
		end)
	end)

	describe("CopyTree integration", function()
		it("Copies multiple times with unique IDs", function()
			local copy1 = build.treeTab:CopyTree(1, "Copy 1")
			local copy2 = build.treeTab:CopyTree(1, "Copy 2")

			assert.are.equals(2, copy1.id)
			assert.are.equals(3, copy2.id)
			assert.are.not_same(copy1, copy2)
		end)

		it("Copies from copied spec", function()
			local copy1 = build.treeTab:CopyTree(1, "Copy 1")
			local copy2 = build.treeTab:CopyTree(2, "Copy 2")

			assert.are.equals(copy1.treeVersion, copy2.treeVersion)
			assert.are.equals("Copy 2", copy2.title)
		end)
	end)


	describe("SpecStateManagement", function()
		it("Preserves tree allocations across spec switches", function()
			build.treeTab:CopyTree(1, "Copy 1")

			-- Allocate a node in original
			build.treeTab.specList[1].allocNodes = { [1] = true }

			build.treeTab:SetActiveSpec(1)
			assert.is_not_nil(build.treeTab.specList[1].allocNodes[1])

			build.treeTab:SetActiveSpec(2)
			build.treeTab.specList[2].allocNodes = { [2] = true }

			build.treeTab:SetActiveSpec(1)
			assert.is_not_nil(build.treeTab.specList[1].allocNodes[1])
			assert.is_nil(build.treeTab.specList[1].allocNodes[2])
		end)
	end)
end)
