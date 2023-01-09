describe("TetsItemMods", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)

    it("Dialla's socket mods", function()
        build.skillsTab:PasteSocketGroup("Slot: Body Armour\nArc 20/0 Default  1\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

        build.itemsTab:CreateDisplayItemFromRaw([[Dialla's Malefaction
        Sage's Robe
        Energy Shield: 95
        EnergyShieldBasePercentile: 0
        Variant: Pre 3.19.0
        Variant: Current
        Selected Variant: 2
        Sage's Robe
        Quality: 20
        Sockets: R-G-B-B-B-B
        LevelReq: 37
        Implicits: 0
        Gems can be Socketed in this Item ignoring Socket Colour
        {variant:1}Gems Socketed in Red Sockets have +1 to Level
        {variant:2}Gems Socketed in Red Sockets have +2 to Level
        {variant:1}Gems Socketed in Green Sockets have +10% to Quality
        {variant:2}Gems Socketed in Green Sockets have +30% to Quality
        {variant:1}Gems Socketed in Blue Sockets gain 25% increased Experience
        {variant:2}Gems Socketed in Blue Sockets gain 100% increased Experience
        Has no Attribute Requirements]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        assert.are.equals(build.calcsTab.mainEnv.player.activeSkillList[1].activeEffect.level, 22)
        assert.are.equals(build.calcsTab.mainEnv.player.activeSkillList[2].activeEffect.quality, 30)
    end)

    it("Malachai's Artifice socket mods", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Malachai's Artifice
        Unset Ring
        Variant: Pre 2.6.0
        Variant: Current
        Selected Variant: 2
        Unset Ring
        Sockets: W
        LevelReq: 5
        Implicits: 1
        Has 1 Socket
        {tags:jewellery_resistance}{variant:1}-25% to all Elemental Resistances
        {tags:jewellery_resistance}{variant:2}-20% to all Elemental Resistances
        {tags:jewellery_resistance}{range:0.5}+(75-100)% to Fire Resistance when Socketed with a Red Gem
        {tags:jewellery_resistance}{range:0.5}+(75-100)% to Cold Resistance when Socketed with a Green Gem
        {tags:jewellery_resistance}{range:0.5}+(75-100)% to Lightning Resistance when Socketed with a Blue Gem
        All Sockets are White
        Socketed Gems have Elemental Equilibrium]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        local lightningResBefore = build.calcsTab.mainOutput.LightningResist

        build.skillsTab:PasteSocketGroup("Slot: Ring 1\nWrath 20/0 Default  1\n")
        runCallback("OnFrame")

        assert.are_not.equals(lightningResBefore, build.calcsTab.mainOutput.LightningResist)
    end)

    it("Doomsower vaal pact and extra phys as fire", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Doomsower
        Lion Sword
        Variant: Pre 2.6.0
        Variant: Pre 3.0.0
        Variant: Pre 3.8.0
        Variant: Pre 3.11.0
        Variant: Current
        Selected Variant: 5
        Lion Sword
        Quality: 20
        Sockets: G-G-G-G-G-G
        LevelReq: 65
        Implicits: 3
        {variant:1}18% increased Global Accuracy Rating
        {variant:2,3,4}+470 to Accuracy Rating
        {variant:5}+50 to Strength and Dexterity
        Socketed Melee Gems have 15% increased Area of Effect
        {variant:1,2,3}Socketed Red Gems get 10% Physical Damage as Extra Fire Damage
        {variant:1,2,3,4}{range:0.5}(50-70)% increased Physical Damage
        {variant:5}{range:0.5}(30-50)% increased Physical Damage
        {variant:1,2}{range:0.5}Adds (50-75) to (85-110) Physical Damage
        {variant:3,4,5}{range:0.5}Adds (65-75) to (100-110) Physical Damage
        {range:0.5}(6-12)% increased Attack Speed
        {variant:5,4}Attack Skills gain 5% of Physical Damage as Extra Fire Damage per Socketed Red Gem
        {variant:5,4}You have Vaal Pact while all Socketed Gems are Red]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0 Default  1\n")
        runCallback("OnFrame")

        assert.is_true(build.calcsTab.mainEnv.keystonesAdded["Vaal Pact"])
        assert.is_true(build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "PhysicalDamageGainAsFire") > 0)
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
        Ring
        League: Kalandra
        Implicits: 0
        Reflects your other Ring
        Mirrored]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        assert.are.equals(genericRingInt - initialInt, build.calcsTab.mainOutput.Int - genericRingInt)
    end)
end)
