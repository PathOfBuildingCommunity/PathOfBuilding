describe("TestDefence", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)

    -- boring part
    it("no armour max hits", function()
        assert.are.equals(60, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(38, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(38, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(38, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(38, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        200% additional Physical Damage Reduction\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(240, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(240, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(240, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(240, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        200% additional Physical Damage Reduction\n\z
        "
        build.configTab.input.enemyPhysicalOverwhelm = 15 -- should result 75% DR
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(240, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(600, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(600, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(600, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(600, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(120, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(1200, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(1200, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(1200, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(1200, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(240, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(300, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
    end)
    
    -- a small helper function to calculate damage taken from limited test parameters
    local function takenHitFromDamage(damage, armour, resMulti, takenMulti, overwhelmDecimal)
        local armourDR = 1 - (math.min(armour / (armour + 5 * damage * resMulti), 0.9) - overwhelmDecimal)
        return round(damage * resMulti * armourDR * takenMulti)
    end
    
    it("progenesis and petrified blood", function()
        -- Petrified blood
        build.skillsTab:PasteSocketGroup("\z
        Label: 50% petrified\n\z
        Petrified Blood 20/40 Alternate1  1\n\z
        Arrogance 21/200 Alternate1  1\n\z
        ")  -- 50% petrified effect, when exactly half of the life is reserved, should make the life pool be equivalent to no petrified effect and full life.
        build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(300, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        build.skillsTab.socketGroupList = {}
    
        build.skillsTab:PasteSocketGroup("\z
        Label: 50% petrified\n\z
        Petrified Blood 20/40 Alternate1  1\n\z
        Arrogance 21/200 Alternate1  1\n\z
        ")
        build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        100% less intelligence\n\z
        +60 to maximum energy shield\n\z
        "  -- petrified blood should not interact with pools other than life.
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(3000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        build.skillsTab.socketGroupList = {}
    
        build.skillsTab:PasteSocketGroup("\z
        Label: 75% petrified\n\z
        Petrified Blood 20/140 Alternate1  1\n\z
        ")  -- 75% petrified effect, starting from full life, should make the life pool be equivalent to 0.5 * life (unprotected upper half) and then 4 * 0.5 * life (protected lower half), making it 2.5* bigger in total
        build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(750, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(7500, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(7500, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(7500, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(7500, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        build.skillsTab.socketGroupList = {}
    
        -- Progenesis
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
        "   -- 50% progenesis should just simply double the life pool
        build.configTab.input.conditionUsingFlask = true
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
        100% less intelligence\n\z
        +60 to maximum energy shield\n\z
        "  -- progenesis should not interact with pools other than life.
        build.configTab.input.conditionUsingFlask = true
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(900, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
    
        -- Progenesis + petrified blood
        build.skillsTab:PasteSocketGroup("\z
        Label: 50% petrified\n\z
        Petrified Blood 20/40 Alternate1  1\n\z
        Arrogance 21/200 Alternate1  1\n\z
        ")
        build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
        "   -- With half of life reserved, both effects are active and multiplicative with each other, making the effective life pool 4 * half life = 2 * life (or same as no petrified, no reserve and 50% progenesis)
        build.configTab.input.conditionUsingFlask = true
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(600, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(6000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        build.skillsTab.socketGroupList = {}
    
        build.skillsTab:PasteSocketGroup("\z
        Label: 50% petrified\n\z
        Petrified Blood 20/40 Alternate1  1\n\z
        ")
        build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        When Hit during effect, 50% of Life loss from Damage taken occurs over 4 seconds instead\n\z
        "   -- With no life reserved, progenesis first doubles the pool of life above low, then both progenesis and petrified quadruple the pool of life below low, so effective pool is 3 * life
        build.configTab.input.conditionUsingFlask = true
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(900, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(9000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        build.skillsTab.socketGroupList = {}
    
        build.skillsTab:PasteSocketGroup("\z
        Petrified Blood 20/0 Default  1\n\z
        ")
        build.skillsTab:ProcessSocketGroup(build.skillsTab.socketGroupList[1])
        build.configTab.input.customMods = "\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        Nearby enemies deal 20% less damage\n\z
        When Hit during effect, 60% of Life loss from Damage taken occurs over 4 seconds instead\n\z
        100% less intelligence\n\z
        +60 to maximum energy shield\n\z
        "   -- wonkier numbers to test the pool reduction function
        build.configTab.input.conditionUsingFlask = true
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1300, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(13000, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(13000, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(13000, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(10000, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
        
        local poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Fire = takenHitFromDamage(build.calcsTab.calcsOutput.FireMaximumHitTaken * 0.8, 0, 0.1, 0.25, 0) })
        assert.are.equals(0, poolsRemaining.EnergyShield)
        assert.are.equals(0, poolsRemaining.Life)
        assert.are.equals(120, poolsRemaining.LifeLossLostOverTime)
        assert.are.equals(20, poolsRemaining.LifeBelowHalfLossLostOverTime)
    end)

    -- fun part
    it("armoured max hits", function()
        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +10000 to armour\n\z
        " -- hit of 2000 on 10000 armour results in 50% DR which reduces the damage to 1000 - total HP
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 10000, 1, 1, 0))
        assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +100000 to armour\n\z
        " -- hit of 5000 on 100000 armour results in 80% DR which reduces the damage to 1000 - total HP
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 100000, 1, 1, 0))
        assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +1000000000 to armour\n\z
        " -- 90% DR cap
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 1000000000, 1, 1, 0))
        assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +1000000000 to armour\n\z
        " -- 90% DR cap
        build.configTab.input.enemyPhysicalOverwhelm = 15 -- should result 75% DR
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 1000000000, 1, 1, 0.15))
        assert.are.equals(625, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +10000 to armour\n\z
        +60% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        " -- with no resistances results should be same as physical
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.FireMaximumHitTaken, 10000, 1, 1, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 10000, 1, 1, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 10000, 1, 1, 0))
        assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        " -- max hit should be 4000
        -- [max] [res]     [armour] [armour]      [max]  [res]
        -- 4000 * 0.5 * (1 - 10000 / (10000 + 5 * 4000 * 0.5)) = 1000
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(1000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.FireMaximumHitTaken, 10000, 0.5, 1, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 10000, 0.5, 1, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 10000, 0.5, 1, 0))
        assert.are.equals(625, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        50% less damage taken\n\z
        " -- max hit should be 6472
        -- [max] [res]     [armour] [armour]      [max]  [res]  [less]
        -- 6472 * 0.5 * (1 - 10000 / (10000 + 5 * 6472 * 0.5)) * 0.5 = 1000
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(2000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.FireMaximumHitTaken, 10000, 0.5, 0.5, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 10000, 0.5, 0.5, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 10000, 0.5, 0.5, 0))
        assert.are.equals(1250, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
    end)

    -- a bigger helper function to calculate damage taken from limited test parameters
    local function takenHitFromDamageWithConversion(damage, conversionMulti, armourFrom, armourTo, resMultiFrom, resMultiTo, takenMultiFrom, takenMultiTo)
        local armourDRFrom = 1 - (math.min(armourFrom / (armourFrom + 5 * damage * conversionMulti * resMultiFrom), 0.9))
        local armourDRTo = 1 - (math.min(armourTo / (armourTo + 5 * damage * (1 - conversionMulti) * resMultiTo), 0.9))
        local damage1, damage2 = damage * (1 - conversionMulti) * resMultiTo * armourDRTo * takenMultiTo, damage * conversionMulti * resMultiFrom * armourDRFrom * takenMultiFrom
        return round(damage1 + damage2), damage1, damage2
    end
    
    local function withinTenPercent(value, otherValue)
        local ratio = otherValue / value
        return 0.9 < ratio and ratio < 1.1
    end
    it("damage conversion max hits", function()
        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        50% of physical damage taken as fire\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 0.5, 0, 0, 1, 0.1, 0.25, 0.25)))

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +200 to all resistances\n\z
        +200 to all maximum resistances\n\z
        50% reduced damage taken\n\z
        50% less damage taken\n\z
        50% of physical damage taken as fire\n\z
        50% of cold damage taken as fire\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 0.5, 0, 0, 1, 0.1, 0.25, 0.25)))
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 0.5, 0, 0, 0.1, 0.1, 0.25, 0.25)))

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        50% of physical damage taken as fire\n\z
        50% of cold damage taken as fire\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 0.5, 0, 10000, 1, 0.5, 1, 1)))
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 0.5, 10000, 10000, 0.5, 0.5, 1, 1)))

        build.configTab.input.customMods = "\z
        +940 to maximum life\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        50% of physical damage taken as fire\n\z
        50% of cold damage taken as fire\n\z
        50% less fire damage taken\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.PhysicalMaximumHitTaken, 0.5, 0, 10000, 1, 0.5, 1, 0.5)))
        assert.is.not_false(withinTenPercent(1000, takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 0.5, 10000, 10000, 0.5, 0.5, 1, 0.5)))
    end)
    
    it("damage conversion to different size pools", function()
        -- conversion into a smaller pool
        build.configTab.input.customMods = "\z
        +40 to maximum life\n\z
        +950 to mana\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        100% of Lightning Damage is taken from Mana before Life\n\z
        10% of lightning damage taken as cold damage\n\z
        "   -- Small amount of conversion into a smaller pool leads to the higher pool damage type (lightning) draining it's own excess pool (mana), and then joining back on the shared pools (life)
        build.configTab:BuildModList()
        runCallback("OnFrame")
        local _, LDamage, CDamage = takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 0.1, 10000, 10000, 0.5, 0.5, 1, 1)
        local poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Lightning = LDamage, Cold = CDamage })
        assert.are.equals(0, round(poolsRemaining.Mana))
        assert.are.not_false(poolsRemaining.Life / 100 < 0.1)
        
        build.configTab.input.customMods = "\z
        +40 to maximum life\n\z
        +950 to mana\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        100% of Lightning Damage is taken from Mana before Life\n\z
        20% of lightning damage taken as cold damage\n\z
        "   -- This is a case where cold damage drains the whole life pool and lightning damage drains the entire mana pool, leaving nothing
        build.configTab:BuildModList()
        runCallback("OnFrame")
        _, LDamage, CDamage = takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 0.2, 10000, 10000, 0.5, 0.5, 1, 1)
        poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Lightning = LDamage, Cold = CDamage })
        assert.are.equals(0, round(poolsRemaining.Life))
        assert.are.equals(0, round(poolsRemaining.Mana))
    
        build.configTab.input.customMods = "\z
        +40 to maximum life\n\z
        +1950 to mana\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        100% of Lightning Damage is taken from Mana before Life\n\z
        20% of lightning damage taken as cold damage\n\z
        "   -- Any extra mana in this case will not help and be left over after death, since life hits 0 from the cold damage alone
        build.configTab:BuildModList()
        runCallback("OnFrame")
        _, LDamage, CDamage = takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 0.2, 10000, 10000, 0.5, 0.5, 1, 1)
        poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Lightning = LDamage, Cold = CDamage })
        assert.are.equals(0, round(poolsRemaining.Life))
        assert.are.equals(1000, round(poolsRemaining.Mana))
        
        -- conversion into a bigger pool
        build.configTab.input.customMods = "\z
        +40 to maximum life\n\z
        +950 to mana\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        100% of Lightning Damage is taken from Mana before Life\n\z
        90% of cold damage taken as lightning damage\n\z
        "   -- With inverted conversion amounts the behaviour of converting into a bigger pool should be exactly the same as converting into a lower one.
        build.configTab:BuildModList()
        runCallback("OnFrame")
        _, CDamage, LDamage = takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 0.9, 10000, 10000, 0.5, 0.5, 1, 1)
        poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Lightning = LDamage, Cold = CDamage })
        assert.are.equals(0, round(poolsRemaining.Mana))
        assert.are.not_false(poolsRemaining.Life / 100 < 0.1)
    
        build.configTab.input.customMods = "\z
        +40 to maximum life\n\z
        +950 to mana\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        100% of Lightning Damage is taken from Mana before Life\n\z
        80% of cold damage taken as lightning damage\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        _, CDamage, LDamage = takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 0.8, 10000, 10000, 0.5, 0.5, 1, 1)
        poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Lightning = LDamage, Cold = CDamage })
        assert.are.equals(0, round(poolsRemaining.Life))
        assert.are.equals(0, round(poolsRemaining.Mana))
    
        build.configTab.input.customMods = "\z
        +40 to maximum life\n\z
        +1950 to mana\n\z
        +10000 to armour\n\z
        +110% to all elemental resistances\n\z
        Armour applies to Fire, Cold and Lightning Damage taken from Hits instead of Physical Damage\n\z
        100% of Lightning Damage is taken from Mana before Life\n\z
        80% of cold damage taken as lightning damage\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        _, CDamage, LDamage = takenHitFromDamageWithConversion(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 0.8, 10000, 10000, 0.5, 0.5, 1, 1)
        poolsRemaining = build.calcsTab.calcsOutput.reducePoolsByDamage(nil, { Lightning = LDamage, Cold = CDamage })
        assert.are.equals(0, round(poolsRemaining.Life))
        assert.are.equals(1000, round(poolsRemaining.Mana))
    end)
end)