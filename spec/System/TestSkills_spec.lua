describe("TestAttacks", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	it("adds envy, ensures +1 level keeps level 25 Envy", function()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nAssassin Bow\nGrants Level 1 Summon Raging Spirit\nGrants Level 25 Envy Skill")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(205, build.calcsTab.mainEnv.minion.modDB:Sum("BASE", build.calcsTab.mainEnv.minion.mainSkill.skillCfg, "ChaosMin"))

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAwakened Generosity 4/0  1\n")
		runCallback("OnFrame")
		assert.are.equals(round(205 * 1.43), build.calcsTab.mainEnv.minion.modDB:Sum("BASE", build.calcsTab.mainEnv.minion.mainSkill.skillCfg, "ChaosMin"))

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAwakened Generosity 5/0  1\n")
		runCallback("OnFrame")
		-- No Envy level increase, so base should still be 205
		assert.are.equals(round(205 * 1.44), build.calcsTab.mainEnv.minion.modDB:Sum("BASE", build.calcsTab.mainEnv.minion.mainSkill.skillCfg, "ChaosMin"))
	end)

	it("Test Mirage Archer using triggered skill", function()
		build.itemsTab:CreateDisplayItemFromRaw([[+3 Bow
		Thicket Bow
		Crafted: true
		Prefix: {range:0.5}LocalIncreaseSocketedGemLevel1
		Prefix: {range:0.5}LocalIncreaseSocketedBowGemLevel2
		Prefix: None
		Suffix: {range:0.5}LocalIncreasedAttackSpeed2
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: G-G-G-G-G-G
		LevelReq: 56
		Implicits: 0
		+1 to Level of Socketed Gems
		+2 to Level of Socketed Bow Gems
		9% increased Attack Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Mirage Archer 20/0  1\nRain of Arrows 20/0  1\nManaforged Arrows 20/0  1\n")
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Toxic Rain 20/0  1\n")
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.MirageDPS ~= nil)

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate == build.calcsTab.mainOutput.Speed)
	end)
	
	it("Test Sacred wisps using current skill", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Elemental Wand
			Imbued Wand
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Quality: 0
			Sockets: B-B-B
			LevelReq: 59
			Implicits: 0]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Power Siphon 20/0  1\nSacred Wisps 20/0  1\n")
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.MirageDPS ~= nil)
	end)
	
	it("Test Scorching ray applying exposure at max stages", function()
		build.skillsTab:PasteSocketGroup("Scorching Ray 20/0  1\n")
		runCallback("OnFrame")
		
		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance
		srcInstance.skillStageCount = 8
		build.modFlag = true
		build.buildFlag = true
		build.configTab.input.enemyIsBoss = "None"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		-- Manual stages
		assert.True(build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "FireResist") < 0)

		srcInstance.skillPart = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		-- Automatic maximum sustainable stages
		assert.True(build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "FireResist") < 0)
	end)

	it("Defaults Blade Blast to the skill's blade cap", function()
		build.skillsTab:PasteSocketGroup("Blade Blast 20/0  1\n")
		runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local activeSkill = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill]
		local calcsSkillSelectControls = build.calcsTab.sectionList[1].controls
		build:RefreshSkillSelectControls(calcsSkillSelectControls, build.calcsTab.input.skill_number, "Calcs")

		assert.are.equals("50", build.controls.mainSkillStageCount.buf)
		assert.are.equals("50", calcsSkillSelectControls.mainSkillStageCount.buf)
		assert.are.equals(50, activeSkill.skillData.stagesMax)
		assert.are.equals(50, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStage"))
		assert.are.equals(49, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStageAfterFirst"))

		local cappedAverageDamage = build.calcsTab.mainOutput.AverageDamage
		local cappedTotalDPS = build.calcsTab.mainOutput.TotalDPS
		local cappedCombinedDPS = build.calcsTab.mainOutput.CombinedDPS
		activeSkill.activeEffect.srcInstance.skillStageCount = 51
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		activeSkill = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill]
		assert.are.equals("51", build.controls.mainSkillStageCount.buf)
		assert.are.equals(50, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStage"))
		assert.are.equals(49, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStageAfterFirst"))
		assert.are.equals(cappedAverageDamage, build.calcsTab.mainOutput.AverageDamage)
		assert.are.equals(cappedTotalDPS, build.calcsTab.mainOutput.TotalDPS)
		assert.are.equals(cappedCombinedDPS, build.calcsTab.mainOutput.CombinedDPS)
	end)

	it("Test Adrenaline affecting blight max stage count", function()
		build.skillsTab:PasteSocketGroup("Blight 20/0  1\n")
		runCallback("OnFrame")
		
		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance
		srcInstance.skillPart = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		
		local preAdrenalineMaxStages = build.calcsTab.mainEnv.player.activeSkillList[1].skillModList:Sum("BASE", nil, "Multiplier:BlightMaxStages")
		build.configTab.input.buffAdrenaline = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.True(preAdrenalineMaxStages < build.calcsTab.mainEnv.player.activeSkillList[1].skillModList:Sum("BASE", nil, "Multiplier:BlightMaxStages"))
	end)
	local function setupBifurcate(socketGroup, bifurcate, lucky, turboLucky, noCritMulti)
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw([[
				New Item
				Imbued Wand
				Quality: 0
				100% reduced lightning damage
				adds 1 to 1 physical damage to spells
				nearby enemies have 100% less armour
			]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		build.skillsTab:PasteSocketGroup(socketGroup)
		runCallback("OnFrame")

		local customCrit = 50 - 6 -- spark 6% base crit
		build.configTab.input.customMods = string.format("+%d%% to critical hit chance\n", customCrit)
			.. (bifurcate and "spell critical strike chance bifurcates\n" or "")
			.. (lucky and "your critical strike chance is lucky\n" or "")
			.. (turboLucky and "your lucky or unlucky effects use the best or worst from three rolls instead of two\n" or "")
			.. (noCritMulti and "" or "your critical strike multiplier is 1000000%\n")
		build.configTab:BuildModList()
		runCallback("OnFrame")
		build.calcsTab:BuildOutput()
		runCallback("OnFrame")

		return build.calcsTab.mainOutput
	end
	local function closeEnough(a, b, epsilon)
		if not epsilon then epsilon = 10 ^ -9 end
		return math.abs(a - b) < epsilon
	end
	it("correctly calculates bifurcated critical hit damage", function()
		local normalOutput = setupBifurcate("Spark 1/0  1")
		assert.are.equals(50, normalOutput.CritChance)
		assert.are.equals(10000, normalOutput.CritMultiplier)
		assert.are.equals(10001, normalOutput.AverageHit)

		local garukhanOutput = setupBifurcate("Spark 1/0  1", true)
		assert.are.equals(50, garukhanOutput.PreBifurcateCritChance)
		assert.are.equals(75, garukhanOutput.CritChance)
		assert.is_true(closeEnough(1 + 1 / 3, garukhanOutput.CritBifurcates))
		assert.are.equals(20000, garukhanOutput.AverageHit)
	end)
	it("correctly calculates bifurcated for every nth crits spells", function()
		local normalOutput = setupBifurcate("Spark 1/0  1", nil, nil, nil, true)
		assert.are.equals(1.5, normalOutput.CritMultiplier)

		local garukhanOutput = setupBifurcate("Spark 1/0  1\nAssassin's Mark 1/0  1", nil, nil, nil, true)
		assert.are.equals(1.8, garukhanOutput.CritMultiplier)

		local garukhanOutput = setupBifurcate("Spark 1/0  1\nAssassin's Mark 1/0  1", true, nil, nil, true)
		assert.are.equals(2.07, floor(garukhanOutput.CritMultiplier, 2))
	end)
	it("multiplies assassin's mark ", function()
		local normalOutput = setupBifurcate("Lightning Tendrils 1/0  1")
		assert.are.equals(200 / 3, normalOutput.CritChance)
		assert.are.equals(10000, normalOutput.CritMultiplier)

		local garukhanOutput = setupBifurcate("Lightning Tendrils 1/0  1", true)
		assert.are.equals(50, garukhanOutput.PreBifurcateCritChance)
		assert.is_true(closeEnough(100 / 3 + (200 / 3) * 0.75, garukhanOutput.CritChance, 10 ^ -6))
		assert.are.equals(1.2, garukhanOutput.CritBifurcates)
		local garukhanOutput = setupBifurcate("Lightning Tendrils of Eccentricity 1/0  1", true)
		assert.are.equals(50, garukhanOutput.PreBifurcateCritChance)
		assert.are.equals(80, garukhanOutput.CritChance)
		assert.are.equals(1.25, garukhanOutput.CritBifurcates)
	end)
	it("correctly calculates lucky bifurcated critical hit damage", function()
		local normalOutput = setupBifurcate("Spark 1/0  1", false, true)
		assert.are.equals(75, normalOutput.CritChance)
		assert.are.equals(10000, normalOutput.CritMultiplier)
		assert.are.equals(15000.5, normalOutput.AverageHit)

		local garukhanOutput = setupBifurcate("Spark 1/0  1", true, true)
		assert.are.equals(75, garukhanOutput.PreBifurcateCritChance)
		assert.are.equals(93.75, garukhanOutput.CritChance)
		assert.are.equals(garukhanOutput.CritBifurcates, 16 / 10)
		assert.are.equals(29999, garukhanOutput.AverageHit)

		local garukhanOutput = setupBifurcate("Spark 1/0  1", true, true, true)
		assert.are.equals(87.5, garukhanOutput.PreBifurcateCritChance)
		assert.are.equals(98.4375, garukhanOutput.CritChance)
		assert.are.equals(1 + 0.875 * 0.875 / (0.984375), garukhanOutput.CritBifurcates)
		assert.is_true(math.abs(34998.5 - garukhanOutput.AverageHit) < 0.01)
	end)
end)