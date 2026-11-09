describe("Polaric Devastation", function()
	before_each(function()
		newBuild()
	end)

	local function rebuild()
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	for _, case in ipairs({
		{ skill = "Fireball", condition = "conditionEnemyIgnited", otherCondition = "conditionEnemyFrozen", manual = "conditionEnemyCoveredInAsh" },
		{ skill = "Freezing Pulse", condition = "conditionEnemyFrozen", otherCondition = "conditionEnemyIgnited", manual = "conditionEnemyCoveredInFrost" },
	}) do
		it("applies the notable to " .. case.skill .. " only with the required ailment", function()
			build.skillsTab:PasteSocketGroup(case.skill .. " 20/0  1")
			build.spec:SelectClass(build.spec.tree.classNameMap.Scion)
			build.spec:SelectAscendClass(build.spec.tree.ascendNameMap.Reliquarian.ascendClassId)
			local node = build.spec.nodes[48410]
			assert.are.equal("Polaric Devastation", node.name)
			build.spec:AllocNode(node)
			build.buildFlag = true
			build.configTab.input[case.otherCondition] = true
			rebuild()
			local baseDPS = build.calcsTab.mainOutput.TotalDPS
			assert.is_true(baseDPS > 0)

			build.configTab.input[case.condition] = true
			rebuild()
			assert.are.near(baseDPS * 1.2, build.calcsTab.mainOutput.TotalDPS, baseDPS * 1e-9)

			-- Manual coverage must not stack with the notable.
			build.configTab.input[case.manual] = true
			rebuild()
			assert.are.near(baseDPS * 1.2, build.calcsTab.mainOutput.TotalDPS, baseDPS * 1e-9)
		end)
	end
end)
