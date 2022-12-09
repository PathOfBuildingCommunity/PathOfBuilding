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
end)