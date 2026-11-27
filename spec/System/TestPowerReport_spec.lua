describe("PowerReportListControl", function()
	local PowerReportListControl

	before_each(function()
		LoadModule("Classes/PowerReportListControl")
		PowerReportListControl = common.classes.PowerReportListControl
	end)

	local function relist(originalList, showClusters, allocated)
		local control = {
			originalList = originalList,
			showClusters = showClusters or false,
			allocated = allocated or false,
		}
		PowerReportListControl.ReList(control)
		return control.list
	end

	it("Show Unallocated excludes allocated nodes", function()
		local list = relist({
			{ name = "allocated", power = 10, pathDist = 1, allocated = true },
			{ name = "unallocated", power = 5, pathDist = 1, allocated = false },
		}, false, false)

		assert.are.equal(1, #list)
		assert.are.equal("unallocated", list[1].name)
	end)

	it("Show Allocated includes allocated nodes", function()
		local list = relist({
			{ name = "allocated", power = -10, pathDist = 1, allocated = true },
			{ name = "unallocated", power = 5, pathDist = 1, allocated = false },
		}, false, true)

		assert.are.equal(1, #list)
		assert.are.equal("allocated", list[1].name)
	end)
end)

describe("Full DPS passive comparisons", function()
	it("matches the ordinary calculator across successive damage and no-change overrides", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		build.skillsTab.socketGroupList[1].includeInFullDPS = true
		build.buildFlag = true
		runCallback("OnFrame")

		local calcs = build.calcsTab.calcs
		local ordinary = calcs.getMiscCalculator(build)
		local report = calcs.getFullDPSPowerCalculator(build, ordinary)
		assert.are_not.equal(ordinary, report)
		local node = build.spec.nodes[build.spec.tree.notableMap["heart of flame"].id]
		local base = ordinary({ }, true).FullDPS
		local withNode = ordinary({ addNodes = { [node] = true } }, true).FullDPS
		assert.is_true(withNode > base)
		assert.are.equal(base, report({ }).FullDPS)
		assert.are.equal(withNode, report({ addNodes = { [node] = true } }).FullDPS)
		assert.are.equal(base, report({ }).FullDPS)
	end)

	it("keeps the ordinary calculator when the selected Vaal gem effect comes second", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Vaal Reap of Butchery 20/0  1")
		local group = build.skillsTab.socketGroupList[1]
		group.includeInFullDPS = true
		group.mainActiveSkill = 2
		build.buildFlag = true
		runCallback("OnFrame")

		local calcs = build.calcsTab.calcs
		local ordinary, base = calcs.getMiscCalculator(build)
		assert.is_true(base.FullDPS > 0)
		assert.are.equal(ordinary, calcs.getFullDPSPowerCalculator(build, ordinary))
	end)

	it("keeps the selected attack calculation when only Reflection contributes", function()
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: UNIQUE\nThe Saviour\nLegion Sword\nImplicits: 0\nTriggers Level 20 Reflection when Equipped")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Heavy Strike 20/0  1")
		build.mainSocketGroup = 1
		runCallback("OnFrame")
		for _, group in ipairs(build.skillsTab.socketGroupList) do
			group.includeInFullDPS = group.gemList[1].skillId == "UniqueMirageWarriors"
		end
		build.buildFlag = true
		runCallback("OnFrame")

		local calcs = build.calcsTab.calcs
		local ordinary, base = calcs.getMiscCalculator(build)
		assert.is_true(base.FullDPS > 0)
		assert.are.equal(ordinary, calcs.getFullDPSPowerCalculator(build, ordinary))
	end)
end)
