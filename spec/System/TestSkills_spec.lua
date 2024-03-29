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
end)