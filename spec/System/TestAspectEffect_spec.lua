describe("TestAspectEffect", function()
	for _, case in ipairs({
		{ base = "Craicic Talisman", aspect = "Crab", effect = "Buff" },
		{ base = "Farric Talisman", aspect = "Cat", effect = "Buff" },
		{ base = "Fenumal Talisman", aspect = "Spider", effect = "Debuff" },
	}) do
		it("parses the base enchant of " .. case.base, function()
			local item = new("Item"):Item("Rarity: Normal\n" .. case.base)
			local mods, extra = modLib.parseMod(item.enchantModLines[1].line)
			assert.is_nil(extra)
			assert.are.equals(case.effect .. "Effect", mods[1].name)
			assert.are.same({ type = "SkillName", skillName = "Aspect of the " .. case.aspect }, mods[1][1])
		end)
	end

	it("scales Crab damage reduction", function()
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest\nCraicic Talisman\nImplicits: 0\nGrants Level 20 Aspect of the Crab Skill")
		build.itemsTab:AddDisplayItem()
		build.configTab.input.overrideCrabBarriers = 3
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(12, build.calcsTab.mainOutput.PhysicalDamageReduction)
	end)

	it("scales Cat critical strike chance", function()
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest\nFarric Talisman\nImplicits: 0\nGrants Level 20 Aspect of the Cat Skill")
		build.itemsTab:AddDisplayItem()
		build.configTab.input.aspectOfTheCatCatsStealth = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(200, build.calcsTab.mainEnv.player.modDB:Sum("INC", nil, "CritChance"))
	end)

	it("scales Spider damage taken", function()
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest\nFenumal Talisman\nImplicits: 0\nGrants Level 20 Aspect of the Spider Skill")
		build.itemsTab:AddDisplayItem()
		build.configTab.input.aspectOfTheSpiderWebStacks = 2
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(20, build.calcsTab.mainEnv.enemy.modDB:Sum("INC", nil, "DamageTaken"))
	end)
end)
