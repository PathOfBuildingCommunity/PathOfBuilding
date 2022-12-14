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

    it("adds divergent arcane cloak, ensures round to nearest percent", function()
        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nArcane Cloak 20/20 Alternate2  1\n")
        runCallback("OnFrame")

        assert.are.equals(floor(50 * floor(14 * 1.1)), build.calcsTab.mainEnv.player.modDB:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "LightningMin"))

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nArcane Cloak 25/50 Alternate2  1\n")
        runCallback("OnFrame")

        assert.are.equals(floor(50 * floor(16 * 1.25)), build.calcsTab.mainEnv.player.modDB:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "LightningMin"))

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nArcane Cloak 25/60 Alternate2  1\n")
        runCallback("OnFrame")

        assert.are.equals(floor(50 * floor(16 * 1.3)), build.calcsTab.mainEnv.player.modDB:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "LightningMin"))
    end)

    it("adds assassin's mark and ensures round to nearest percent and scales correctly", function()
        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAssassin's Mark 20/50 Alternate2  1\n")
        runCallback("OnFrame")

        assert.are.equals(floor(1.5 + 0.5, 2), build.calcsTab.mainEnv.enemy.modDB:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "SelfCritChance"))

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAssassin's Mark 20/50 Alternate2  1\nMark On Hit 20/20 Default  1\n")
        runCallback("OnFrame")

        assert.are.equals(floor((1.5 + 0.5) * 0.78, 2), build.calcsTab.mainEnv.enemy.modDB:Sum("BASE", build.calcsTab.player.mainEnv.mainSkill.skillCfg, "SelfCritChance"))

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAssassin's Mark 20/20 Alternate2  1\nMark On Hit 20/20 Default  1\n")
        runCallback("OnFrame")

        assert.are.equals(floor((1.5 + 0.2) * 0.78, 2), build.calcsTab.mainEnv.enemy.modDB:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "SelfCritChance"))
    end)
end)