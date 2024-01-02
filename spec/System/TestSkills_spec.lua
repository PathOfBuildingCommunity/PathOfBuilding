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


describe("TestCurses", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)

    -- Source: https://github.com/PathOfBuildingCommunity/PathOfBuilding/pull/5074#issuecomment-1264520943
	local skills = {
		{name = "Blood Rage", affected = true},
		{name = "Winter Orb", affected = true},
		{name = "Blade Vortex", affected = true},
		{name = "Corrupting Fever", affected = true},
		{name = "Intuitive Link", affected = true},
		{name = "Vampiric Link", affected = true},
		{name = "Destructive Link", affected = true},
		{name = "Soul Link", affected = true},
		{name = "Protective Link", affected = true},
		{name = "Immortal Call", affected = true},
		{name = "Steelskin", affected = true},
		{name = "Molten Shell", affected = true},
		{name = "Ancestral Cry", affected = true},
		{name = "Battlemage's Cry", affected = true},
		{name = "Enduring Cry", affected = true},
		{name = "General's Cry", affected = true},
		{name = "Infernal Cry", affected = true},
		{name = "Intimidating Cry", affected = true},
		{name = "Rallying Cry", affected = true},
		{name = "Seismic Cry", affected = true},
		{name = "Static Strike", affected = true},
		{name = "Smite", affected = true},
		{name = "Cyclone", affected = true},
		{name = "Flicker Strike", affected = true},
		--{name = "Venom Gyre", affected = true}, requires a claw
		{name = "Shattering Steel", affected = true},
        {name = "Ambush", affected = true},
		{name = "Phase Run", affected = true},
		{name = "Herald Of Thunder", affected = true},
		{name = "Herald Of Purity", affected = false},
		{name = "Bladestorm", affected = false},
		{name = "Consecrated Path", affected = false},
		{name = "Ancestral Protector", affected = false},
		{name = "Decoy Totem", affected = false},
		{name = "Defiance Banner", affected = false},
		{name = "War Banner", affected = false},
		{name = "Arctic Armour", affected = false},
		{name = "Frost Blink", affected = false},
		{name = "Flame dash", affected = false},
		{name = "Cold snap", affected = false},
		{name = "Vortex", affected = false},
		{name = "Creeping Frost", affected = false},
		{name = "Ethernal Knives", affected = false},
		{name = "Bladefall", affected = false},
		{name = "Tornado", affected = false},
		{name = "Cremation", affected = false},
		{name = "Frost Wall", affected = false},
		{name = "Blight", affected = false},
		{name = "Storm Call", affected = false},
		{name = "Bone Offering", affected = false},
		{name = "Frost shield", affected = false},
		{name = "Hydrosphere", affected = false},
	}
	
	for _, skill in ipairs(skills) do
		it("self temp chains affects " .. skill.name, function()
            build.skillsTab:PasteSocketGroup(skill.name .. " 20/20 Default  1\n")
			runCallback("OnFrame")

            build.itemsTab:CreateDisplayItemFromRaw([[
                New Item
                Gladius
                Prefix: None
                Prefix: None
                Prefix: None
                Suffix: None
                Suffix: None
                Suffix: None
                Quality: 20
                Sockets: G-G-G
                LevelReq: 60
                Implicits: 1
                {tags:attack}40% increased Global Accuracy Rating
            ]])
            build.itemsTab:AddDisplayItem()
            runCallback("OnFrame")
			
			local skillDuration = build.calcsTab.mainOutput.Duration
			
			build.configTab.input["externalCurseConfig"] = "TemporalChains"
			build.configTab:BuildModList()
			runCallback("OnFrame")
			
            if skill.affected then
                assert.are_not.equals(build.calcsTab.mainOutput.Duration, skillDuration)
            else
                assert.are.equals(build.calcsTab.mainOutput.Duration, skillDuration)
            end
		end)
	end

    it("self curse using shackles", function()
        build.skillsTab:PasteSocketGroup("Steelskin 20/20 Default  1\n")
        runCallback("OnFrame")
        
        local skillDuration = build.calcsTab.mainOutput.Duration
        
        build.itemsTab:CreateDisplayItemFromRaw([[
            Shackles of the Wretched
            Chain Gloves
            Armour: 20
            ArmourBasePercentile: 0.4444
            Energy Shield: 6
            EnergyShieldBasePercentile: 0.5
            Variant: Pre 1.2.0
            Variant: Current
            Selected Variant: 2
            Chain Gloves
            Quality: 20
            Sockets: B-B-B-B
            LevelReq: 7
            Implicits: 0
            {range:0.5}(40-60)% increased Stun Recovery
            Hexes applied by Socketed Curse Skills are Reflected back to you
            You cannot be Chilled for 3 seconds after being Chilled
            You cannot be Frozen for 3 seconds after being Frozen
            You cannot be Ignited for 3 seconds after being Ignited
            {variant:1}You cannot be Shocked for 1 second after being Shocked
            {variant:2}You cannot be Shocked for 3 seconds after being Shocked
            You grant (4-6) Frenzy Charges to allies on Death
        ]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        build.skillsTab:PasteSocketGroup("Slot: Gloves\nTemporal Chains 20/0 Default  1\n")
        runCallback("OnFrame")
        
        assert.are_not.equals(build.calcsTab.mainOutput.Duration, skillDuration)
    end)

    it("buff specific mods affect buffs", function()
        build.skillsTab:PasteSocketGroup("Steelskin 20/20 Default  1\n")
        runCallback("OnFrame")
         
        local skillDuration = build.calcsTab.mainOutput.Duration
         
        build.skillsTab:PasteSocketGroup("Haste 20/20 Alternate3  1\n")
        runCallback("OnFrame")
         
        assert.are_not.equals(build.calcsTab.mainOutput.Duration, skillDuration)
     end)

     local aspects = {
        [[Farrul's Bite
        Harlequin Mask
        Evasion: 555
        EvasionBasePercentile: 0.5871
        Energy Shield: 114
        EnergyShieldBasePercentile: 0.6042
        League: Bestiary
        Quality: 20
        Sockets: G-G-G-G
        LevelReq: 57
        Implicits: 0
        Grants Level 20 Aspect of the Cat Skill
        {range:0.5}(180-220)% increased Evasion and Energy Shield
        {range:0.5}+(25-35)% to Cold Resistance
        +1% to Critical Strike Chance while affected by Aspect of the Cat
        Critical Strikes have (10-20)% chance to Blind Enemies while you have Cat's Stealth
        {range:0.5}(40-50)% increased Damage with Hits and Ailments against Blinded Enemies]],
        [[Saqawal's Talons
        Hydrascale Boots
        Armour: 275
        ArmourBasePercentile: 0.3903
        Evasion: 275
        EvasionBasePercentile: 0.3903
        League: Bestiary
        Quality: 20
        Sockets: G-G-G-G
        LevelReq: 59
        Implicits: 0
        Grants Level 20 Aspect of the Avian Skill
        {range:0.5}(100-150)% increased Armour and Evasion
        {range:0.5}(20-30)% increased Movement Speed
        {range:0.5}+(-2-2) seconds to Avian's Flight Duration
        100 Life Regenerated per Second while you have Avian's Flight
        12 Mana Regenerated per Second while you have Avian's Flight]],
        }

     for _, skill in ipairs(aspects) do
		it("self temp chains affects " .. skill, function()
            build.itemsTab:CreateDisplayItemFromRaw(skill)
            build.itemsTab:AddDisplayItem()
            runCallback("OnFrame")
			
			local skillDuration = build.calcsTab.mainOutput.Duration
			
			build.configTab.input["externalCurseConfig"] = "TemporalChains"
			build.configTab:BuildModList()
			runCallback("OnFrame")
			
            assert.are_not.equals(build.calcsTab.mainOutput.Duration, skillDuration)
		end)
	end

    it("Debuffs on self duration mod", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Stasis Prison
        Carnal Armour
        Evasion: 970
        EvasionBasePercentile: 0.1788
        Energy Shield: 283
        EnergyShieldBasePercentile: 0.1815
        Quality: 20
        Sockets: B-B-B-B-B-B
        LevelReq: 71
        Implicits: 1
        {range:0.5}+(20-25) to maximum Mana
        {range:0.5}(140-160)% increased Evasion and Energy Shield
        {range:0.5}+(80-100) to maximum Life
        Temporal Rift has no Reservation
        {range:0.5}(80-100)% of Damage taken Recouped as Life
        {range:0.5}Debuffs on you Expire (80-100)% faster]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        build.itemsTab:CreateDisplayItemFromRaw([[
            Shackles of the Wretched
            Chain Gloves
            Armour: 20
            ArmourBasePercentile: 0.4444
            Energy Shield: 6
            EnergyShieldBasePercentile: 0.5
            Variant: Pre 1.2.0
            Variant: Current
            Selected Variant: 2
            Chain Gloves
            Quality: 20
            Sockets: B-B-B-B
            LevelReq: 7
            Implicits: 0
            {range:0.5}(40-60)% increased Stun Recovery
            Hexes applied by Socketed Curse Skills are Reflected back to you
            You cannot be Chilled for 3 seconds after being Chilled
            You cannot be Frozen for 3 seconds after being Frozen
            You cannot be Ignited for 3 seconds after being Ignited
            {variant:1}You cannot be Shocked for 1 second after being Shocked
            {variant:2}You cannot be Shocked for 3 seconds after being Shocked
            You grant (4-6) Frenzy Charges to allies on Death
        ]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        build.skillsTab:PasteSocketGroup("Slot: Gloves\nTemporal Chains 20/0 Default  1\n")
        runCallback("OnFrame")
        
        assert.are_not.equals(build.calcsTab.mainOutput.Duration, skillDuration)
    end)
    it("Rotblood self blasphemy", function()
        build.skillsTab:PasteSocketGroup("Slot: Ring 1\nTemporal Chains 20/0 Default  1\n")
        runCallback("OnFrame")

        build.itemsTab:CreateDisplayItemFromRaw([[Rotblood Promise
        Unset Ring
        League: Ritual
        Variant: Pre 3.16.0
        Variant: Current
        Selected Variant: 2
        Unset Ring
        Sockets: G
        LevelReq: 56
        Implicits: 1
        Has 1 Socket
        Socketed Gems are Supported by Level 20 Blasphemy
        Curse Auras from Socketed Skills also affect you
        {tags:caster}{variant:1}Socketed Curse Gems have 100% increased Mana Reservation Efficiency
        {tags:caster}{variant:2}Socketed Curse Gems have 80% increased Reservation Efficiency
        {tags:jewellery_attribute}{range:0.5}+(20-30) to Intelligence
        {tags:caster}20% reduced Effect of Curses on you
        {range:0.5}(15-25)% increased Damage with Hits and Ailments against Cursed Enemies]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

        assert.is_true(build.calcsTab.mainOutput.EffectiveMovementSpeedMod < 1)
	 end)
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