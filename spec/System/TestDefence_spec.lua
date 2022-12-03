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
        50% of physical damage taken as fire\n\z
        "
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(480, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.FireMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.ColdMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.LightningMaximumHitTaken)
        assert.are.equals(2400, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
    end)

    -- a small helper function to calculate damage taken from limited test parameters
    local function takenHitFromDamage(damage, armour, resMulti, takenMulti, overwhelmDecimal)
        local armourDR = 1 - (math.min(armour / (armour + 5 * damage * resMulti), 0.9) - overwhelmDecimal)
        return round(damage * resMulti * armourDR * takenMulti)
    end

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
        --       [res] [armour] [armour]            [res]
        -- 4000 * 0.5 * (10000 / (10000 + 5 * 4000 * 0.5) = 1000
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
        " -- max hit should be 4000
        --       [res] [armour] [armour]            [res]  [less]
        -- 6472 * 0.5 * (10000 / (10000 + 5 * 6472 * 0.5) * 0.5 = 1000
        build.configTab:BuildModList()
        runCallback("OnFrame")
        assert.are.equals(2000, build.calcsTab.calcsOutput.PhysicalMaximumHitTaken)
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.FireMaximumHitTaken, 10000, 0.5, 0.5, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.ColdMaximumHitTaken, 10000, 0.5, 0.5, 0))
        assert.are.equals(1000, takenHitFromDamage(build.calcsTab.calcsOutput.LightningMaximumHitTaken, 10000, 0.5, 0.5, 0))
        assert.are.equals(1250, build.calcsTab.calcsOutput.ChaosMaximumHitTaken)
    end)
end)