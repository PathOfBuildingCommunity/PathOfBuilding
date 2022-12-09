describe("TetsItemMods", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)


    it("Varunastra works with nightblade", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Varunastra
        Vaal Blade
        League: Perandus
        Variant: Pre 2.6.0
        Variant: Current
        Selected Variant: 2
        Vaal Blade
        Quality: 20
        Sockets: G-G-G
        LevelReq: 64
        Implicits: 2
        {variant:1}18% increased Global Accuracy Rating
        {variant:2}+460 to Accuracy Rating
        {range:0.5}(40-60)% increased Physical Damage
        {range:0.5}Adds (30-45) to (80-100) Physical Damage
        {range:0.5}+(2-3) Mana gained for each Enemy hit by Attacks
        Counts as all One Handed Melee Weapon Types]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\nNightblade 20/0 Default  1\n")
        runCallback("OnFrame")
        local nonElusiveCritMult = build.calcsTab.mainOutput.CritMultiplier

        build.configTab.input["buffElusive"] = true
        build.configTab:BuildModList()
        runCallback("OnFrame")

        assert.are_not.equals(nonElusiveCritMult, build.calcsTab.mainOutput.CritMultiplier)
    end)

    it("Varunastra works with close combat support", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Varunastra
        Vaal Blade
        League: Perandus
        Variant: Pre 2.6.0
        Variant: Current
        Selected Variant: 2
        Vaal Blade
        Quality: 20
        Sockets: G-G-G
        LevelReq: 64
        Implicits: 2
        {variant:1}18% increased Global Accuracy Rating
        {variant:2}+460 to Accuracy Rating
        {range:0.5}(40-60)% increased Physical Damage
        {range:0.5}Adds (30-45) to (80-100) Physical Damage
        {range:0.5}+(2-3) Mana gained for each Enemy hit by Attacks
        Counts as all One Handed Melee Weapon Types]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        build.configTab.input["meleeDistance"] = 99
        build.configTab:BuildModList()
        runCallback("OnFrame")

        build.skillsTab:PasteSocketGroup("Cyclone 20/0 Default  1\nClose Combat 20/0 Default  1\n")
        runCallback("OnFrame")

        local farDPS = build.calcsTab.mainOutput.TotalDPS

        build.configTab.input["meleeDistance"] = 1
        build.configTab:BuildModList()
        runCallback("OnFrame")

        assert.are_not.equals(farDPS, build.calcsTab.mainOutput.TotalDPS)

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