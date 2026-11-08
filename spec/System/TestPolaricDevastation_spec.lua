describe("Polaric Devastation", function()
	before_each(function()
		newBuild()
	end)

	local function rebuild()
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	for _, case in ipairs({
		{ skill = "Fireball", condition = "conditionEnemyIgnited", otherCondition = "conditionEnemyFrozen", manual = "conditionEnemyCoveredInAsh", damage = "FireDamageTaken" },
		{ skill = "Freezing Pulse", condition = "conditionEnemyFrozen", otherCondition = "conditionEnemyIgnited", manual = "conditionEnemyCoveredInFrost", damage = "ColdDamageTaken" },
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
			assert.are.equal(0, build.calcsTab.mainEnv.enemyDB:Sum("INC", nil, case.damage))

			-- The manual setting is a working control for the same final calculation.
			build.configTab.input[case.manual] = true
			rebuild()
			assert.are.equal(20, build.calcsTab.mainEnv.enemyDB:Sum("INC", nil, case.damage))
			assert.are.near(baseDPS * 1.2, build.calcsTab.mainOutput.TotalDPS, baseDPS * 1e-9)

			build.configTab.input[case.manual] = false
			build.configTab.input[case.condition] = true
			rebuild()
			assert.are.equal(20, build.calcsTab.mainEnv.enemyDB:Sum("INC", nil, case.damage))
			assert.are.near(baseDPS * 1.2, build.calcsTab.mainOutput.TotalDPS, baseDPS * 1e-9)

			build.configTab.input[case.manual] = true
			rebuild()
			assert.are.equal(20, build.calcsTab.mainEnv.enemyDB:Sum("INC", nil, case.damage))
			assert.are.near(baseDPS * 1.2, build.calcsTab.mainOutput.TotalDPS, baseDPS * 1e-9)

			build.configTab.input[case.manual] = false
			build.configTab.input[case.condition] = false
			rebuild()
			assert.are.equal(0, build.calcsTab.mainEnv.enemyDB:Sum("INC", nil, case.damage))
			assert.are.near(baseDPS, build.calcsTab.mainOutput.TotalDPS, baseDPS * 1e-9)
		end)
	end
end)
