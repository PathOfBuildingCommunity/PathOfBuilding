describe("TestAspectEffect", function()
	for _, case in ipairs({
		{ base = "Craicic Talisman", aspect = "Crab", effect = "Buff" },
		{ base = "Farric Talisman", aspect = "Cat", effect = "Buff" },
		{ base = "Fenumal Talisman", aspect = "Spider", effect = "Debuff" },
	}) do
		it("parses the base enchant of " .. case.base, function()
			local item = new("Item"):Item("Rarity: Normal\n" .. case.base)
			local line = item.enchantModLines[1].line
			assert.are.equals("100% increased Aspect of the " .. case.aspect .. " " .. case.effect .. " Effect", line)
			local mods, extra = modLib.parseMod(line)
			assert.is_nil(extra)
			assert.is_not_nil(mods)
		end)
	end

	it("still parses Avian buff effect", function()
		local mods, extra = modLib.parseMod("100% increased Aspect of the Avian Buff Effect")
		assert.is_nil(extra)
		assert.is_not_nil(mods)
	end)

	it("scales Crab reduction without adding barriers", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Summon Stone Golem 20/0  1\n")
		runCallback("OnFrame")
		local regen = build.calcsTab.mainOutput.LifeRegen
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest\nCraicic Talisman\nImplicits: 0\nGrants Level 20 Aspect of the Crab Skill")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(10, build.calcsTab.mainEnv.player.modDB:Sum("BASE", nil, "CrabBarriersMax"))
		assert.are.equals(40, build.calcsTab.mainOutput.PhysicalDamageReduction)
		assert.are.equals(regen, build.calcsTab.mainOutput.LifeRegen)
		build.configTab.input.overrideCrabBarriers = 3
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(12, build.calcsTab.mainOutput.PhysicalDamageReduction)
		build.calcsTab.input.misc_buffMode = "UNBUFFED"
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.calcsOutput.PhysicalDamageReduction)
		build.calcsTab.input.misc_buffMode = "BUFFED"
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(40, build.calcsTab.calcsOutput.PhysicalDamageReduction)
		build.configTab.input.overrideCrabBarriers = 0
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.mainOutput.PhysicalDamageReduction)
	end)

	it("scales both Cat buffs", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Summon Stone Golem 20/0  1\n")
		runCallback("OnFrame")
		local regen = build.calcsTab.mainOutput.LifeRegen
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest\nFarric Talisman\nImplicits: 0\nGrants Level 20 Aspect of the Cat Skill")
		build.itemsTab:AddDisplayItem()
		build.configTab.input.aspectOfTheCatCatsStealth = true
		build.configTab.input.aspectOfTheCatCatsAgility = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		local db = build.calcsTab.mainEnv.player.modDB
		assert.are.equals(200, db:Sum("INC", nil, "CritChance"))
		assert.are.equals(30, build.calcsTab.mainOutput.AvoidAllDamageFromHitsChance)
		assert.are.equals(20, db:Sum("INC", { flags = ModFlag.Attack }, "Speed"))
		assert.are.equals(20, db:Sum("INC", { flags = ModFlag.Cast }, "Speed"))
		assert.are.equals(regen, build.calcsTab.mainOutput.LifeRegen)
		build.calcsTab.input.misc_buffMode = "UNBUFFED"
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.calcsOutput.AvoidAllDamageFromHitsChance)
		build.configTab.input.aspectOfTheCatCatsAgility = false
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.mainEnv.player.modDB:Sum("INC", { flags = ModFlag.Attack }, "Speed"))
		assert.are.equals(30, build.calcsTab.mainOutput.AvoidAllDamageFromHitsChance)
		build.configTab.input.aspectOfTheCatCatsStealth = false
		build.configTab.input.aspectOfTheCatCatsAgility = true
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.mainOutput.AvoidAllDamageFromHitsChance)
		assert.are.equals(20, build.calcsTab.mainEnv.player.modDB:Sum("INC", { flags = ModFlag.Cast }, "Speed"))
	end)

	it("scales Spider damage taken without adding webs", function()
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest\nFenumal Talisman\nImplicits: 0\nGrants Level 20 Aspect of the Spider Skill")
		build.itemsTab:AddDisplayItem()
		build.configTab.input.aspectOfTheSpiderWebStacks = 2
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(20, build.calcsTab.mainEnv.enemy.modDB:Sum("INC", nil, "DamageTaken"))
		assert.are.equals(2, build.calcsTab.mainEnv.enemy.modDB:Sum("BASE", nil, "Multiplier:Spider's WebStack"))
		assert.are.equals(0, build.calcsTab.mainEnv.player.modDB:Sum("INC", nil, "DamageTaken"))
		build.configTab.input.aspectOfTheSpiderWebStacks = 3
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(30, build.calcsTab.mainEnv.enemy.modDB:Sum("INC", nil, "DamageTaken"))
		build.calcsTab.input.misc_buffMode = "COMBAT"
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.calcsEnv.enemy.modDB:Sum("INC", nil, "DamageTaken"))
		build.configTab.input.aspectOfTheSpiderWebStacks = 0
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.mainEnv.enemy.modDB:Sum("INC", nil, "DamageTaken"))
	end)

	it("does not grant an Aspect or scale Avian when only its talisman is equipped", function()
		for _, base in ipairs({ "Craicic Talisman", "Farric Talisman", "Fenumal Talisman" }) do
			newBuild()
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nControl\nIron Ring\nImplicits: 0\nGrants Level 20 Aspect of the Avian Skill")
			build.itemsTab:AddDisplayItem()
			build.configTab.input.aspectOfTheAvianAviansMight = true
			build.configTab.input.aspectOfTheAvianAviansFlight = true
			build.configTab:BuildModList()
			runCallback("OnFrame")
			local speed = build.calcsTab.mainOutput.MovementSpeedMod
			local doubleDamage = build.calcsTab.mainEnv.player.modDB:Sum("BASE", nil, "DoubleDamageChance")
			assert.is_true(doubleDamage > 0)
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: Normal\n" .. base)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(speed, build.calcsTab.mainOutput.MovementSpeedMod)
			assert.are.equals(doubleDamage, build.calcsTab.mainEnv.player.modDB:Sum("BASE", nil, "DoubleDamageChance"))
			assert.are.equals(0, build.calcsTab.mainOutput.PhysicalDamageReduction)
			assert.are.equals(0, build.calcsTab.mainOutput.AvoidAllDamageFromHitsChance)
			assert.are.equals(0, build.calcsTab.mainEnv.enemy.modDB:Sum("INC", nil, "DamageTaken"))
		end
	end)
end)
