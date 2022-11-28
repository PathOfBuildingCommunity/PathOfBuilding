describe("TetsItemMods", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)

    it("Kalandra's Touch mod copy", function()
        local initialInt = build.calcsTab.mainOutput.Int

        build.itemsTab:CreateDisplayItemFromRaw([[New Item
        Ring
        Quality: 0
        LevelReq: 35
        Implicits: 0
        +30 to Intelligence]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        local genericRingInt = build.calcsTab.mainOutput.Int

        build.itemsTab:CreateDisplayItemFromRaw([[Kalandra's Touch
        Iron Ring
        League: Kalandra
        Implicits: 0
        Reflects your other Ring
        Mirrored]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
        
        assert.are.equals(genericRingInt - initialInt, build.calcsTab.mainOutput.Int - genericRingInt)
    end)
end)