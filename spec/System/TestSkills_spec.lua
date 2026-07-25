describe("TestSkills", function()
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

	it("averages inverted elemental resistance after penetration", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		build.configTab.input.enemyIsBoss = "None"
		build.configTab.input.enemyFireResist = 50
		build.configTab.input.customMods = "Hits have 50% chance to treat Enemy Monster Elemental Resistance values as inverted\nDamage Penetrates 50% of Enemy Fire Resistance"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Unlike PoE 2, PoE 1 penetration can lower resistance below zero:
		-- 50% of hits use 0% resistance and 50% use -100% resistance.
		assert.are.equals(1.5, build.calcsTab.calcsOutput.FireEffMult)
		local breakdownText = table.concat(build.calcsTab.calcsEnv.player.breakdown.FireEffMult, "\n")
		assert.is_truthy(breakdownText:match("inverted hit"))
		assert.is_truthy(breakdownText:match("weighted average"))
	end)
	it("Test cost efficiency modifiers", function()
		-- Test Mana Cost Efficiency
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		runCallback("OnFrame")

		-- Get base mana cost (Hydrosphere level 1 has 12 mana cost)
		local baseCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(12, baseCost)

		-- Add 50% mana cost efficiency (should reduce cost to 12/1.5 = 8)
		build.configTab.input.customMods = "50% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local reducedCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(8, reducedCost)

		-- Test generic cost efficiency (should also affect mana)
		newBuild()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "25% increased Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local genericEfficiencyCost = build.calcsTab.mainOutput.ManaCost
		-- Test actual behavior: 12/1.25 = 9.6 (not rounded)
		assert.True(math.abs(genericEfficiencyCost - 9.6) < 0.001)

		-- Test multiple efficiency sources stacking additively
		build.configTab.input.customMods = "25% increased Cost Efficiency\n25% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local stackedCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(8, stackedCost) -- 12/(1 + 0.25 + 0.25) = 12/1.5 = 8
	end)

	it("Test cost efficiency with cost modifiers", function()
		-- Test interaction between cost efficiency and cost multipliers
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")

		-- Add cost multiplier and efficiency
		build.configTab.input.customMods = "50% increased Mana Cost\n50% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local finalCost = build.calcsTab.mainOutput.ManaCost
		assert.True(math.abs(finalCost - 12) < 0.1) -- floor(12 * 1.5) / 1.5
	end)

	it("Test mana cost efficiency with support gems", function()
		-- Test interaction between cost efficiency and cost multipliers
		build.skillsTab:PasteSocketGroup("Contagion 6/0  1\nMagnified Area I 1/0  1")

		-- Add efficiency
		build.configTab.input.customMods = "36% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local finalCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(7, round(finalCost))
	end)

	it("evaluates BaseFlag tags using PoB 1 skill data", function()
		build.skillsTab:PasteSocketGroup("Absolution 20/0  1\n")
		runCallback("OnFrame")

		local durationSkill = build.calcsTab.mainEnv.player.mainSkill
		durationSkill.skillModList:NewMod("BaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration" })
		durationSkill.skillModList:NewMod("NegatedBaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration", neg = true })
		assert.are.equals(1, durationSkill.skillModList:Sum("BASE", durationSkill.skillCfg, "BaseFlagTest"))
		assert.are.equals(0, durationSkill.skillModList:Sum("BASE", durationSkill.skillCfg, "NegatedBaseFlagTest"))

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
		runCallback("OnFrame")

		local nonDurationSkill = build.calcsTab.mainEnv.player.mainSkill
		nonDurationSkill.skillModList:NewMod("BaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration" })
		nonDurationSkill.skillModList:NewMod("NegatedBaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration", neg = true })
		assert.are.equals(0, nonDurationSkill.skillModList:Sum("BASE", nonDurationSkill.skillCfg, "BaseFlagTest"))
		assert.are.equals(1, nonDurationSkill.skillModList:Sum("BASE", nonDurationSkill.skillCfg, "NegatedBaseFlagTest"))
	end)

	it("Test Empowered Spells - Pact of Beidat", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.calcsOutput.TotalDPS

		build.skillsTab:PasteSocketGroup("Pact of Beidat 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.BeidatUpTimeRatio > 0)
		assert.True(build.calcsTab.calcsOutput.TotalDPS > baseDPS)

		newBuild()
		build.skillsTab:PasteSocketGroup("Vaal Arc 20/0  1\nPact of Beidat 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.BeidatUpTimeRatio == nil)
	end)

	it("Test Empowered Spells - Pact of Ghorr", function()
		build.skillsTab:PasteSocketGroup("Creeping Frost 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.calcsOutput.TotalDotDPS

		build.skillsTab:PasteSocketGroup("Pact of Ghorr 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.GhorrUpTimeRatio > 0)
		assert.True(build.calcsTab.calcsOutput.TotalDotDPS > baseDPS)

		newBuild()
		build.skillsTab:PasteSocketGroup("Vaal Arc 20/0  1\n Pact of Ghorr 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.GhorrUpTimeRatio == nil)
	end)

	it("Test Empowered Spells - Pact of K'Tash", function()
		build.skillsTab:PasteSocketGroup("Vaal Arc 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.calcsOutput.TotalDPS

		build.skillsTab:PasteSocketGroup("Pact of K'Tash 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.KtashUpTimeRatio > 0)
		assert.True(build.calcsTab.calcsOutput.TotalDPS > baseDPS)

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nPact of K'Tash 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.KtashUpTimeRatio == nil)
	end)

	it("Test Empowered Spells - Pact of Lycia", function()
		build.skillsTab:PasteSocketGroup("Lightning Tendrils 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.calcsOutput.TotalDPS

		build.skillsTab:PasteSocketGroup("Pact of Lycia 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.LyciaUpTimeRatio > 0)
		assert.True(build.calcsTab.calcsOutput.TotalDPS > baseDPS)

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nPact of Lycia 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.LyciaUpTimeRatio == nil)

		newBuild()
		build.skillsTab:PasteSocketGroup("Vaal Arc 20/0  1\nPact of Lycia 1/0  1")
		runCallback("OnFrame")
		assert.True(build.calcsTab.calcsOutput.LyciaUpTimeRatio == nil)
	end)
end)
