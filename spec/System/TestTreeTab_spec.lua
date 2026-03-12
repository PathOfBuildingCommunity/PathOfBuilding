describe("TreeTab", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() resets the shared build state for the next test.
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
		treeTab.build.spec.masterySelections = { }
		treeTab.build.spec.tree.clusterNodeMap = { }
		treeTab.build.spec.tree.masteryEffects = {
			[101] = { id = 101, sd = { "Gain 10 Damage" }, stats = { "Gain 10 Damage" } },
			[102] = { id = 102, sd = { "Gain 20 Damage" }, stats = { "Gain 20 Damage" } },
		}
		treeTab.build.calcsTab.mainEnv = { grantedPassives = { } }

		local report = treeTab:BuildPowerReportList({ stat = "Damage", label = "Damage" })

		assert.are.same(2, #report)
		assert.are.same("Mastery", report[1].type)
		assert.are.same("Two Hand Mastery: Gain 20 Damage", report[1].name)
		assert.are.same(20, report[1].power)
		assert.are.same(2, report[1].pathDist)
		assert.are.same(10, report[2].power)
		assert.are.same("Two Hand Mastery: Gain 10 Damage", report[2].name)
	end)
end)
