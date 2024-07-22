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

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAwakened Generosity 4/0 Default  1\n")
        runCallback("OnFrame")
        assert.are.equals(round(205 * 1.43), build.calcsTab.mainEnv.minion.modDB:Sum("BASE", build.calcsTab.mainEnv.minion.mainSkill.skillCfg, "ChaosMin"))

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAwakened Generosity 5/0 Default  1\n")
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

        build.skillsTab:PasteSocketGroup("Mirage Archer 20/0 Default  1\nRain of Arrows 20/0 Default  1\nManaforged Arrows 20/0 Default  1\n")
        runCallback("OnFrame")

        build.skillsTab:PasteSocketGroup("Toxic Rain 20/0 Default  1\n")
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

        build.skillsTab:PasteSocketGroup("Power Siphon 20/0 Default  1\nSacred Wisps 20/0 Default  1\n")
        runCallback("OnFrame")

        assert.True(build.calcsTab.mainOutput.MirageDPS ~= nil)
    end)
	
	it("Test Scorching ray applying exposure at max stages", function()
        build.skillsTab:PasteSocketGroup("Scorching Ray 20/0 Default  1\n")
        runCallback("OnFrame")
        
        local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
        local srcInstance = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance
        srcInstance.skillStageCount = 8
        build.modFlag = true
        build.buildFlag = true
        runCallback("OnFrame")
        
        assert.True(build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "FireResist") < 0)
    end)

    it("Test Adrenaline affecting blight max stage count", function()
        build.skillsTab:PasteSocketGroup("Blight 20/0 Default  1\n")
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
end)