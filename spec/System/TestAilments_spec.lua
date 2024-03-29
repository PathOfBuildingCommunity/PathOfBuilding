describe("TestAilments", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)

    it("maximum shock value", function()
        -- Shock Nova
        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nShock Nova 4/0 Default  1\n")
        runCallback("OnFrame")
        assert.are.equals(round(50 + 10), build.calcsTab.mainOutput.MaximumShock)

        -- Voltaxic Rift
        build.itemsTab:CreateDisplayItemFromRaw("New Item\nAssassin Bow\n+40% to Maximum Effect of Shock")
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
        assert.are.equals(round(50 + 10 + 40), build.calcsTab.mainOutput.MaximumShock)
    end)
end)