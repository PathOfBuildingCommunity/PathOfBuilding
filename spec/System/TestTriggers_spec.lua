describe("TestTriggers", function()
    before_each(function()
        newBuild()
    end)

    teardown(function()
        -- newBuild() takes care of resetting everything in setup()
    end)
	
	it("Trigger Manaforged", function()
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

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\nManaforged Arrows 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Rain of Arrows 20/0 Default  1\n")
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

    it("Trigger Law of the Wilds", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Law of the Wilds
		Hellion's Paw
		League: Harvest
		Variant: Pre 3.14.0
		Variant: Current
		Selected Variant: 2
		Hellion's Paw
		Quality: 20
		Sockets: G-G-G
		LevelReq: 62
		Implicits: 1
		1.6% of Physical Attack Damage Leeched as Life
		{variant:1}20% chance to Trigger Level 20 Summon Spectral Wolf on Critical Strike with this Weapon
		{variant:2}20% chance to Trigger Level 25 Summon Spectral Wolf on Critical Strike with this Weapon
		{range:0.5}(15-20)% increased Attack Speed
		{range:0.5}(22-28)% increased Critical Strike Chance
		{range:0.5}+(15-25)% to Global Critical Strike Multiplier]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Reave 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger The Rippling Thoughts", function()
        build.itemsTab:CreateDisplayItemFromRaw([[The Rippling Thoughts
		Legion Sword
		League: Harbinger
		Quality: 20
		Sockets: R-R-R
		LevelReq: 62
		Implicits: 1
		40% increased Global Accuracy Rating
		Grants Summon Harbinger of the Arcane Skill
		Trigger Level 20 Storm Cascade when you Attack
		{range:0.5}(75-90)% increased Spell Damage
		{range:0.5}(140-160)% increased Physical Damage
		{range:0.5}Adds 1 to (60-70) Lightning Damage
		{range:0.5}Adds 1 to (60-70) Lightning Damage to Spells
		10% increased Area of Effect]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.mainSocketGroup = 2
		build.modFlag = true
		build.buildFlag = true
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger The Surging Thoughts", function()
        build.itemsTab:CreateDisplayItemFromRaw([[The Surging Thoughts
		Legion Sword
		League: Harvest
		Quality: 20
		Sockets: R-R-R
		LevelReq: 62
		Implicits: 1
		40% increased Global Accuracy Rating
		Grants Summon Greater Harbinger of the Arcane Skill
		Trigger Level 20 Storm Cascade when you Attack
		{range:0.5}(75-90)% increased Spell Damage
		{range:0.5}(140-160)% increased Physical Damage
		{range:0.5}Adds 1 to (60-70) Lightning Damage
		{range:0.5}Adds 1 to (60-70) Lightning Damage to Spells
		10% increased Area of Effect]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.mainSocketGroup = 2
		build.modFlag = true
		build.buildFlag = true
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger The Hidden Blade", function()
        build.itemsTab:CreateDisplayItemFromRaw([[The Hidden Blade
		Ambusher
		League: Heist
		Quality: 20
		Sockets: G-G-G
		LevelReq: 60
		Implicits: 1
		30% increased Global Critical Strike Chance
		Trigger Level 20 Unseen Strike every 0.5 seconds while Phasing
		{range:0.5}+(20-40) to Dexterity
		{range:0.5}(230-260)% increased Physical Damage
		30% reduced Attack Speed while Phasing]])
        build.itemsTab:AddDisplayItem()
		build.configTab.input["buffPhasing"] = true
		build.configTab:BuildModList()
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Replica Eternity Shroud", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Replica Eternity Shroud
		Blood Raiment
		Evasion: 1127
		EvasionBasePercentile: 0.3692
		Energy Shield: 189
		EnergyShieldBasePercentile: 0.3766
		League: Heist
		Shaper Item
		Elder Item
		Quality: 20
		Sockets: G-G-G-G-G-G
		LevelReq: 65
		Implicits: 0
		Trigger Level 20 Shade Form when Hit
		{range:0.5}(100-150)% increased Evasion and Energy Shield
		{range:0.5}+(70-100) to maximum Life
		{range:0.5}+(17-23)% to Chaos Resistance
		{range:0.5}Gain (3-5)% of Physical Damage as Extra Chaos Damage per Elder Item Equipped
		Hits ignore Enemy Monster Chaos Resistance if all Equipped Items are Elder Items]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger shroud of the Lightless", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Shroud of the Lightless
		Carnal Armour
		Evasion: 1048
		EvasionBasePercentile: 0.2394
		Energy Shield: 305
		EnergyShieldBasePercentile: 0.2172
		League: Abyss
		Variant: Two Abyssal Sockets (Pre 3.12.0)
		Variant: One Abyssal Socket (Pre 3.12.0)
		Variant: Two Abyssal Sockets (Pre 3.21.0)
		Variant: One Abyssal Socket (Pre 3.21.0)
		Variant: Three Abyssal Sockets (Current)
		Variant: Two Abyssal Sockets (Current)
		Variant: One Abyssal Socket (Current)
		Selected Variant: 7
		Quality: 20
		Sockets: B-B-B-B-B A
		LevelReq: 71
		Implicits: 1
		{range:0.5}+(20-25) to maximum Mana
		{variant:5}Has 3 Abyssal Sockets
		{variant:1,3,6}Has 2 Abyssal Sockets
		{variant:2,4,7}Has 1 Abyssal Socket
		{variant:1,2}Socketed Gems are Supported by Level 20 Elemental Penetration
		{variant:4,3}Socketed Gems are Supported by Level 25 Elemental Penetration
		20% chance to Trigger Level 20 Shade Form when you Use a Socketed Skill
		{range:0.5}(160-180)% increased Evasion and Energy Shield
		{variant:1,2,3,4}{range:0.5}(6-10)% increased maximum Life
		{variant:1,2,3,4}{range:0.5}(9-15)% increased maximum Mana
		{variant:1,2,3,4}1% increased Maximum Life per Abyss Jewel affecting you
		{variant:5,6,7}3% increased Maximum Life per Abyss Jewel affecting you
		{variant:1,2,3,4}1% increased Maximum Mana per Abyss Jewel affecting you
		{variant:5,6,7}3% increased Maximum Mana per Abyss Jewel affecting you
		{variant:5,6,7}Penetrate 4% Elemental Resistances per Abyss Jewel affecting you]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Limbsplit", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Limbsplit
		Woodsplitter
		Variant: Pre 3.11.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 13
		Implicits: 0
		+1 to Level of Socketed Strength Gems
		{variant:2}Trigger Level 1 Gore Shockwave on Melee Hit if you have at least 150 Strength
		{range:0.5}+(15-30) to Strength
		{range:0.5}(80-100)% increased Physical Damage
		Adds 5 to 10 Physical Damage
		Culling Strike]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Lioneye's Paws", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Lioneye's Paws
		Bronzescale Boots
		Armour: 66
		ArmourBasePercentile: 0
		Evasion: 66
		EvasionBasePercentile: 0
		League: Legion
		Variant: Pre 3.7.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: G-G-G-G
		LevelReq: 30
		Implicits: 0
		{variant:2}Trigger Level 5 Rain of Arrows when you Attack with a Bow
		{range:0.5}+(40-60) to Strength
		{range:0.5}+(40-60) to Dexterity
		Adds 12 to 24 Fire Damage to Attacks
		20% increased Movement Speed
		40% reduced Movement Speed when on Low Life
		{variant:1}20% increased Stun and Block Recovery
		{variant:1}Cannot be Stunned when on Low Life]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
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

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Replica Lioneye's Paws", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Replica Lioneye's Paws
		Bronzescale Boots
		Armour: 66
		ArmourBasePercentile: 0
		Evasion: 66
		EvasionBasePercentile: 0
		League: Heist
		Quality: 20
		Sockets: G-G-G-G
		LevelReq: 30
		Implicits: 0
		Trigger Level 5 Toxic Rain when you Attack with a Bow
		{range:0.5}+(40-60) to Strength
		{range:0.5}+(40-60) to Dexterity
		Adds 12 to 24 Chaos Damage to Attacks
		20% increased Movement Speed
		40% reduced Movement Speed when on Low Life]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
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

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Moonbender's Wing", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Moonbender's Wing
		Tomahawk
		Variant: Pre 3.11.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: R-R-R
		LevelReq: 39
		Implicits: 0
		{variant:1}Grants Level 1 Lightning Warp Skill
		{variant:2}Trigger Level 15 Lightning Warp on Hit with this Weapon
		{variant:1}{range:0.5}(70-90)% increased Physical Damage
		{variant:2}{range:0.5}(30-50)% increased Physical Damage
		{variant:1}{range:0.5}Adds (5-9) to (13-17) Physical Damage
		{range:0.5}(30-50)% increased Critical Strike Chance
		{variant:1}25% of Physical Damage Converted to Cold Damage
		{variant:1}25% of Physical Damage Converted to Lightning Damage
		{variant:2}{range:0.5}Hits with this Weapon gain (75-100)% of Physical Damage as Extra Cold or Lightning Damage]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Ngamahu's Flame", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Ngamahu's Flame
		Abyssal Axe
		Variant: Pre 3.11.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 55
		Implicits: 0
		20% chance to Trigger Level 16 Molten Burst on Melee Hit
		{variant:1}{range:0.5}(190-230)% increased Physical Damage
		{variant:2}{range:0.5}(170-190)% increased Physical Damage
		{range:0.5}(8-12)% increased Attack Speed
		{variant:1}50% of Physical Damage Converted to Fire Damage
		{variant:2}60% of Physical Damage Converted to Fire Damage
		Damage Penetrates 20% Fire Resistance]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cameria's Avarice", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Cameria's Avarice
		Gavel
		Quality: 20
		Sockets: R-R-R
		LevelReq: 60
		Implicits: 1
		15% reduced Enemy Stun Threshold
		{range:0.5}(140-180)% increased Physical Damage
		{range:0.5}Adds (11-14) to (17-21) Physical Damage
		{range:0.5}(15-40)% increased Critical Strike Chance
		40% increased Rarity of Items Dropped by Frozen Enemies
		{range:0.5}(30-40)% increased Cold Damage with Attack Skills
		Trigger Level 20 Icicle Burst when you Hit a Frozen Enemy]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Uul-Netol's Embrace", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Uul-Netol's Embrace
		Vaal Axe
		League: Breach
		Variant: Pre 3.11.0
		Variant: Pre 3.21.0
		Variant: Current
		Selected Variant: 3
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 64
		Implicits: 1
		{variant:2,3}25% chance to Maim on Hit
		Trigger Level 20 Bone Nova when you Hit a Bleeding Enemy
		{range:0.5}(280-320)% increased Physical Damage
		{range:0.5}(30-25)% reduced Attack Speed
		{variant:1,2}Attacks have 25% chance to inflict Bleeding when Hitting Cursed Enemies
		{variant:3}Attacks have 25% chance to inflict Bleeding]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Rigwald's Crest", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Rigwald's Crest
		Two-Stone Ring
		League: Talisman
		Variant: Pre 3.19.0
		Variant: Current
		Selected Variant: 2
		LevelReq: 49
		Implicits: 1
		{tags:jewellery_resistance}{range:0.5}+(12-16)% to Fire and Cold Resistances
		Trigger Level 10 Summon Spectral Wolf on Kill
		{tags:jewellery_elemental}{variant:1}{range:0.5}(20-30)% increased Fire Damage
		{tags:jewellery_elemental}{variant:1}{range:0.5}(20-30)% increased Cold Damage
		{tags:mana}{range:0.5}(20-30)% increased Mana Regeneration Rate]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Jorrhast's Blacksteel", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Jorrhast's Blacksteel
		Steelhead
		League: Tempest
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 44
		Implicits: 2
		{variant:1}40% increased Stun Duration on Enemies
		{variant:2}45% increased Stun Duration on Enemies
		{variant:2}25% chance to Trigger Level 20 Animate Weapon on Kill
		{range:0.5}(150-200)% increased Physical Damage
		{range:0.5}(8-12)% increased Attack Speed
		{range:0.5}(8-12)% increased Cast Speed
		30% less Animate Weapon Duration
		Weapons you Animate create an additional copy]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Ashcaller", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Ashcaller
		Carved Wand
		Variant: Pre 3.8.0
		Variant: Pre 3.19.0
		Variant: Pre 3.21.0
		Variant: Current
		Selected Variant: 4
		{variant:1,2,3}Quartz Wand
		{variant:4}Carved Wand
		Quality: 20
		Sockets: B-B-B
		LevelReq: 12
		Implicits: 2
		{variant:1,2,3}{range:0.5}(18-22)% increased Spell Damage
		{variant:4}{range:0.5}(11-15)% increased Spell Damage
		{variant:1,2}10% chance to Trigger Level 8 Summon Raging Spirit on Kill
		{variant:3,4}25% chance to Trigger Level 10 Summon Raging Spirit on Kill
		{variant:1}{range:0.5}Adds (10-14) to (18-22) Fire Damage
		{variant:3,4}{range:0.5}Adds (20-24) to (38-46) Fire Damage
		{variant:2}{range:0.5}+(15-25)% to Fire Damage over Time Multiplier
		{variant:1,2}{range:0.5}Adds (4-6) to (7-9) Fire Damage to Spells
		{variant:3,4}{range:0.5}Adds (20-24) to (36-46) Fire Damage to Spells
		{variant:1}{range:0.5}(40-50)% increased Burning Damage
		{variant:2}{range:0.5}(20-30)% increased Burning Damage
		{variant:1,2}{range:0.5}(16-22)% chance to Ignite
		{variant:3,4}10% chance to Cover Enemies in Ash on Hit]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Kinetic Blast 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Arakaali's Fang", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Arakaali's Fang
		Fiend Dagger
		Quality: 20
		Sockets: B-B-B
		LevelReq: 53
		Implicits: 1
		40% increased Global Critical Strike Chance
		100% chance to Trigger Level 1 Raise Spiders on Kill
		{range:0.5}(170-200)% increased Physical Damage
		{range:0.5}Adds (8-13) to (20-30) Physical Damage
		Adds 1 to 59 Chaos Damage
		15% chance to Poison on Hit]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Sporeguard", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Sporeguard
		Saint's Hauberk
		Armour: 1612
		ArmourBasePercentile: 0.4575
		Energy Shield: 276
		EnergyShieldBasePercentile: 0.4444
		League: Blight
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 67
		Implicits: 0
		Trigger Level 10 Contaminate when you Kill an Enemy
		{range:0.5}(200-250)% increased Armour and Energy Shield
		{range:0.5}(7-10)% increased maximum Life
		{range:0.5}+(17-23)% to Chaos Resistance
		Enemies on Fungal Ground you Kill Explode, dealing 5% of their Life as Chaos Damage
		You have Fungal Ground around you while stationary
		This item can be anointed by Cassia]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Mark of the Elder", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Mark of the Elder
		Steel Ring
		Elder Item
		LevelReq: 80
		Implicits: 1
		{tags:attack,physical_damage}{range:0.5}Adds (3-4) to (10-14) Physical Damage to Attacks
		{tags:jewellery_elemental,attack}{range:0.5}Adds (26-32) to (42-48) Cold Damage to Attacks
		{tags:jewellery_defense}{range:0.5}(6-10)% increased maximum Energy Shield
		{tags:life}{range:0.5}(6-10)% increased maximum Life
		{tags:attack}{range:0.5}(60-80)% increased Attack Damage if your other Ring is a Shaper Item
		Cannot be Stunned by Attacks if your other Ring is an Elder Item
		20% chance to Trigger Level 20 Tentacle Whip on Kill]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Mark of the Shaper", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Mark of the Shaper
		Opal Ring
		Shaper Item
		LevelReq: 80
		Implicits: 1
		{tags:jewellery_elemental}{range:0.5}(15-25)% increased Elemental Damage
		{tags:jewellery_elemental,caster}{range:0.5}Adds (13-18) to (50-56) Lightning Damage to Spells
		{tags:jewellery_defense}{range:0.5}(6-10)% increased maximum Energy Shield
		{tags:life}{range:0.5}(6-10)% increased maximum Life
		{tags:caster}{range:0.5}(60-80)% increased Spell Damage if your other Ring is an Elder Item
		Cannot be Stunned by Spells if your other Ring is a Shaper Item
		20% chance to Trigger Level 20 Summon Volatile Anomaly on Kill]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Smite 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger The Poet's Pen", function()
        build.itemsTab:CreateDisplayItemFromRaw([[The Poet's Pen
		Carved Wand
		Quality: 20
		Sockets: B-B-B
		LevelReq: 12
		Implicits: 1
		{range:0.5}(11-15)% increased Spell Damage
		+1 to Level of Socketed Active Skill Gems per 25 Player Levels
		Adds 3 to 5 Physical Damage to Attacks with this Weapon per 3 Player Levels
		{range:0.5}(8-12)% increased Attack Speed
		Trigger a Socketed Spell when you Attack with this Weapon, with a 0.25 second Cooldown]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Kinetic Blast 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Maloney's Mechanism", function()
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

        build.itemsTab:CreateDisplayItemFromRaw([[Maloney's Mechanism
		Ornate Quiver
		Sockets: G-G-G
		LevelReq: 45
		Implicits: 1
		Has 1 Socket
		Has 2 Sockets
		Trigger a Socketed Bow Skill when you Attack with a Bow, with a 1 second Cooldown
		{range:0.5}(7-12)% increased Attack Speed
		{range:0.5}+(50-70) to maximum Life
		5% chance to Blind Enemies on Hit with Attacks]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Slot: Weapon 2\nRain of Arrows 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Replica Maloney's Mechanism", function()
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

        build.itemsTab:CreateDisplayItemFromRaw([[Replica Maloney's Mechanism
		Ornate Quiver
		League: Heist
		Sockets: G-G-G
		LevelReq: 45
		Implicits: 1
		Has 1 Socket
		Has 2 Sockets
		Trigger a Socketed Bow Skill when you Cast a Spell while wielding a Bow
		{range:0.5}(7-12)% increased Cast Speed
		{range:0.5}+(50-70) to maximum Life
		5% chance to Blind Enemies on Hit with Attacks]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Slot: Weapon 2\nRain of Arrows 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Arc 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Asenath's Mark", function()
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

        build.itemsTab:CreateDisplayItemFromRaw([[Asenath's Mark
		Iron Circlet
		Energy Shield: 62
		EnergyShieldBasePercentile: 0
		Variant: Pre 2.6.0
		Variant: Pre 3.19.0
		Variant: Current
		Selected Variant: 3
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 8
		Implicits: 0
		{variant:3}Trigger a Socketed Spell when you Attack with a Bow, with a 0.3 second Cooldown
		{variant:3}{range:0.5}(30-60)% increased Spell Damage
		{range:0.5}(10-15)% increased Attack Speed
		{variant:1,2}{range:0.5}(10-15)% increased Cast Speed
		{variant:1}50% increased Energy Shield
		{variant:2,3}{range:0.5}+(30-50) to maximum Energy Shield
		30% increased Mana Regeneration Rate
		{variant:1,2}5% increased Movement Speed
		{variant:1,2}{range:0.5}(10-15)% increased Stun and Block Recovery]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Vixen's Entrapment", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Vixen's Entrapment
		Embroidered Gloves
		Energy Shield: 114
		EnergyShieldBasePercentile: 0
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 36
		Implicits: 0
		Trigger Socketed Curse Spell when you Cast a Curse Spell, with a 0.25 second Cooldown
		{range:0.5}+(50-90) to maximum Energy Shield
		0.2% of Spell Damage Leeched as Energy Shield for each Curse on Enemy
		You can apply an additional Curse
		{range:0.5}(10-20)% increased Cast Speed with Curse Skills]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nEnfeeble 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Despair 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Atziri's Rule", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Atziri's Rule
		Judgement Staff
		Quality: 20
		Sockets: B-B-B-B-B-B
		LevelReq: 68
		Implicits: 1
		+20% Chance to Block Spell Damage while wielding a Staff
		Grants Level 20 Queen's Demand Skill
		Queen's Demand can Trigger Level 20 Flames of Judgement
		Queen's Demand can Trigger Level 20 Storm of Judgement
		Cannot be Stunned
		Damage cannot be Reflected]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.mainSocketGroup = 2
		build.modFlag = true
		build.buildFlag = true
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Trigger Craft", function()
        build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Gemini Claw
		Crafted: true
		Prefix: None
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: G-G-G
		LevelReq: 72
		Implicits: 2
		{tags:resource,life,mana,attack}Grants 38 Life per Enemy Hit
		{tags:resource,life,mana,attack}Grants 14 Mana per Enemy Hit
		{tags:skill,unveiled_mod,caster,gem}{crafted}Trigger a Socketed Spell when you Use a Skill, with a 8 second Cooldown
		{crafted}Spells Triggered this way have 150% more Cost]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Kitava's Thirst", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Kitava's Thirst
		Zealot Helmet
		Armour: 240
		ArmourBasePercentile: 0.2265
		Energy Shield: 51
		EnergyShieldBasePercentile: 0.2885
		Variant: Pre 3.11.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 44
		Implicits: 0
		15% reduced Cast Speed
		{range:0.5}(70-80)% increased Armour and Energy Shield
		{range:0.5}+(30-50) to maximum Mana
		{variant:1}30% chance to Trigger Socketed Spells when you Spend at least 100 Mana on an Upfront Cost to Use or Trigger a Skill, with a 0.1 second Cooldown
		{variant:2}50% chance to Trigger Socketed Spells when you Spend at least 100 Mana on an Upfront Cost to Use or Trigger a Skill, with a 0.1 second Cooldown]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")
		
		build.itemsTab:CreateDisplayItemFromRaw([[The Blood Reaper
		Headsman Axe
		Variant: Pre 3.0.0
		Variant: Pre 3.12.0
		Variant: Current
		Selected Variant: 3
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 45
		Implicits: 0
		{variant:1}{range:0.5}(100-120)% increased Physical Damage
		{variant:2,3}{range:0.5}(180-200)% increased Physical Damage
		+100 to maximum Life
		{variant:1,2}Regenerate 10 Life per second
		{variant:3}Regenerate 20 Life per second
		1% of Physical Attack Damage Leeched as Life
		500% increased Mana Cost of Skills
		50% chance to cause Bleeding on Hit]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Slot: Helmet\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Ice Nova 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Mjolner", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Mjolner
		Gavel
		Variant: Pre 2.0.0
		Variant: Pre 2.4.0
		Variant: Pre 2.6.0
		Variant: Pre 3.15.0
		Variant: Current
		Selected Variant: 5
		Quality: 20
		Sockets: R-R-R
		LevelReq: 60
		Implicits: 2
		{variant:1,2,3}40% increased Stun Duration on Enemies
		{variant:5,4}15% reduced Enemy Stun Threshold
		{range:0.5}(80-120)% increased Physical Damage
		Skills Chain +1 times
		{variant:1,2,3,4}{range:0.5}(30-40)% increased Lightning Damage with Attack Skills
		{variant:5}{range:0.5}(80-100)% increased Lightning Damage
		+200 Strength Requirement
		+300 Intelligence Requirement
		{variant:1}50% chance to Cast a Socketed Lightning Spell on Hit
		{variant:2}30% chance to Cast a Socketed Lightning Spell on Hit
		{variant:3,4,5}Trigger a Socketed Lightning Spell on Hit, with a 0.25 second Cooldown
		{variant:1,2,3,4}Socketed Lightning Spells deal 100% increased Spell Damage if Triggered]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cospri's Malice", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Cospri's Malice
		Jewelled Foil
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: G-G-G
		LevelReq: 68
		Implicits: 2
		{variant:1}+30% to Global Critical Strike Multiplier
		{variant:2}+25% to Global Critical Strike Multiplier
		Trigger a Socketed Cold Spell on Melee Critical Strike, with a 0.25 second Cooldown
		No Physical Damage
		{range:0.5}Adds (80-100) to (160-200) Cold Damage
		{range:0.5}Adds (40-60) to (90-110) Cold Damage to Spells
		{range:0.5}(8-14)% increased Attack Speed
		+257 Intelligence Requirement
		60% increased Critical Strike Chance against Chilled Enemies]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nIce Nova 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cast On Critical", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Elemental 1H Sword
		Eternal Sword
		Crafted: true
		Prefix: {range:0.5}WeaponElementalDamageOnWeapons4
		Prefix: None
		Prefix: None
		Suffix: {range:0.5}LocalIncreasedAttackSpeed3
		Suffix: {range:0.5}LocalCriticalStrikeChance3
		Suffix: {range:0.5}LocalCriticalMultiplier4
		Quality: 20
		Sockets: G-G-G
		LevelReq: 66
		Implicits: 1
		{tags:attack}+475 to Accuracy Rating
		12% increased Attack Speed
		22% increased Critical Strike Chance
		+27% to Global Critical Strike Multiplier
		40% increased Elemental Damage with Attack Skills]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Cast On Critical Strike 20/0 Default  1\nArc 20/0 Default  1\nCyclone 20/0 Default  1\n")
        runCallback("OnFrame")
		
		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cast on Melee Kill", function()
        build.itemsTab:CreateDisplayItemFromRaw([[Elemental 1H Sword
		Eternal Sword
		Crafted: true
		Prefix: {range:0.5}WeaponElementalDamageOnWeapons4
		Prefix: None
		Prefix: None
		Suffix: {range:0.5}LocalIncreasedAttackSpeed3
		Suffix: {range:0.5}LocalCriticalStrikeChance3
		Suffix: {range:0.5}LocalCriticalMultiplier4
		Quality: 20
		Sockets: G-G-G
		LevelReq: 66
		Implicits: 1
		{tags:attack}+475 to Accuracy Rating
		12% increased Attack Speed
		22% increased Critical Strike Chance
		+27% to Global Critical Strike Multiplier
		40% increased Elemental Damage with Attack Skills]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Cast on Melee Kill 20/0 Default  1\nArc 20/0 Default  1\nCyclone 20/0 Default  1\n")
        runCallback("OnFrame")
		
		build.configTab.input["conditionKilledRecently"] = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Holy Relic", function()
		build.skillsTab:PasteSocketGroup("Summon Holy Relic 20/0 Default  1\n")
        runCallback("OnFrame")
		
		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.Minion.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cast when Damage Taken", function()
		build.skillsTab:PasteSocketGroup("Cast when Damage Taken 20/0 Default  1\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cast when Stunned", function()
		build.skillsTab:PasteSocketGroup("Cast when Stunned 20/0 Default  1\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Spellslinger", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Elemental Wand
		Imbued Wand
		Crafted: true
		Prefix: {range:0.5}WeaponElementalDamageOnWeapons4
		Prefix: None
		Prefix: None
		Suffix: {range:0.5}LocalIncreasedAttackSpeed2
		Suffix: {range:0.5}LocalCriticalStrikeChance3
		Suffix: {range:0.5}LocalCriticalMultiplier4
		Quality: 20
		Sockets: B-B-B
		LevelReq: 59
		Implicits: 1
		{tags:caster_damage,damage,caster}{range:0.5}(33-37)% increased Spell Damage
		9% increased Attack Speed
		22% increased Critical Strike Chance
		+27% to Global Critical Strike Multiplier
		40% increased Elemental Damage with Attack Skills]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Arc 20/0 Default  1\nSpellslinger 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Kinetic Blast 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Mark On Hit", function()
		build.skillsTab:PasteSocketGroup("Mark On Hit 20/0 Default  1\nAlchemist's Mark 20/0 Default  1\n")
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Hextouch", function()
		build.skillsTab:PasteSocketGroup("Despair 20/0 Default  1\nHextouch 20/0 Default  1\nFrenzy 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Oskarm", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Oskarm
		Nubuck Gloves
		Evasion: 131
		EvasionBasePercentile: 0
		Variant: Pre 3.16.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: G-G-G-G
		LevelReq: 52
		Implicits: 0
		Trigger Level 10 Assassin's Mark when you Hit a Rare or Unique Enemy
		{range:0.5}(30-40)% increased Accuracy Rating
		{range:0.5}+(40-50) to maximum Life
		{range:0.5}-(20-10)% to Chaos Resistance
		{variant:1}{range:0.5}(7-8)% chance to Suppress Spell Damage
		{variant:2}{range:0.5}(10-12)% chance to Suppress Spell Damage
		2% increased Attack Critical Strike Chance per 200 Accuracy Rating]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Oskarm", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Oskarm
		Nubuck Gloves
		Evasion: 131
		EvasionBasePercentile: 0
		Variant: Pre 3.16.0
		Variant: Current
		Selected Variant: 2
		Quality: 20
		Sockets: G-G-G-G
		LevelReq: 52
		Implicits: 0
		Trigger Level 10 Assassin's Mark when you Hit a Rare or Unique Enemy
		{range:0.5}(30-40)% increased Accuracy Rating
		{range:0.5}+(40-50) to maximum Life
		{range:0.5}-(20-10)% to Chaos Resistance
		{variant:1}{range:0.5}(7-8)% chance to Suppress Spell Damage
		{variant:2}{range:0.5}(10-12)% chance to Suppress Spell Damage
		2% increased Attack Critical Strike Chance per 200 Accuracy Rating]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Tempest Shield", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Armour Shield
		Heat-attuned Tower Shield
		Armour: 819
		ArmourBasePercentile: 0
		Crafted: true
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRating5
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRatingPercent5
		Prefix: {range:0.5}IncreasedLife8
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: R-R-R
		LevelReq: 70
		Implicits: 1
		Scorch Enemies when you Block their Damage
		+92 to Armour
		74% increased Armour
		+85 to maximum Life]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Tempest Shield 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Shattershard", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Shattershard
		Crimson Round Shield
		Armour: 418
		ArmourBasePercentile: 0.3879
		Evasion: 418
		EvasionBasePercentile: 0.3879
		League: Heist
		Quality: 20
		Sockets: G-G-G
		LevelReq: 49
		Implicits: 0
		Trigger Level 20 Shield Shatter when you Block
		{range:0.5}(120-150)% increased Armour and Evasion
		{range:0.5}+(80-100) to maximum Life
		{range:0.5}+(8-12)% Chance to Block]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Riposte", function()
		build.skillsTab:PasteSocketGroup("Riposte 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Reckoning", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Armour Shield
		Heat-attuned Tower Shield
		Armour: 819
		ArmourBasePercentile: 0
		Crafted: true
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRating5
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRatingPercent5
		Prefix: {range:0.5}IncreasedLife8
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: R-R-R
		LevelReq: 70
		Implicits: 1
		Scorch Enemies when you Block their Damage
		+92 to Armour
		74% increased Armour
		+85 to maximum Life]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Reckoning 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Vengeance", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Elemental 1H Sword
		Jewelled Foil
		Crafted: true
		Prefix: {range:0.5}WeaponElementalDamageOnWeapons4
		Prefix: None
		Prefix: None
		Suffix: {range:0.5}LocalIncreasedAttackSpeed3
		Suffix: {range:0.5}LocalCriticalStrikeChance3
		Suffix: {range:0.5}LocalCriticalMultiplier4
		Quality: 20
		Sockets: G-G-G
		LevelReq: 68
		Implicits: 1
		{tags:damage,critical}+25% to Global Critical Strike Multiplier
		12% increased Attack Speed
		22% increased Critical Strike Chance
		+27% to Global Critical Strike Multiplier
		40% increased Elemental Damage with Attack Skills]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Vengeance 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Combust", function()
		build.skillsTab:PasteSocketGroup("Infernal Cry 20/0 Default  1\n")
        runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		mainSocketGroup.mainActiveSkill = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Prismatic Burst", function()
		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\nPrismatic Burst 20/0 Default  1\n")
        runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		mainSocketGroup.mainActiveSkill = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Shockwave", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Elemental 1H Mace
		Behemoth Mace
		Crafted: true
		Prefix: {range:0.5}WeaponElementalDamageOnWeapons4
		Prefix: None
		Prefix: None
		Suffix: {range:0.5}LocalIncreasedAttackSpeed3
		Suffix: {range:0.5}LocalCriticalStrikeChance3
		Suffix: {range:0.5}LocalCriticalMultiplier4
		Quality: 20
		Sockets: R-R-R
		LevelReq: 70
		Implicits: 1
		{tags:attack,speed}6% increased Attack Speed
		12% increased Attack Speed
		22% increased Critical Strike Chance
		+27% to Global Critical Strike Multiplier
		40% increased Elemental Damage with Attack Skills]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Frenzy 20/0 Default  1\nShockwave 20/0 Default  1\n")
        runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		mainSocketGroup.mainActiveSkill = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Doom Blast", function()
		build.skillsTab:PasteSocketGroup("Impending Doom 20/0 Default  1\nDespair 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Cast while Channelling", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0 Default  1\nCast while Channelling 20/0 Default  1\nBlight 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Focus", function()
		build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Golden Wreath
		Crafted: true
		Prefix: None
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: G-G-G-G
		LevelReq: 12
		Implicits: 1
		{tags:attribute}{range:0.5}+(16-24) to all Attributes
		{tags:skill,unveiled_mod,caster,gem}{crafted}Trigger Socketed Spells when you Focus, with a 0.25 second Cooldown]])
        build.itemsTab:AddDisplayItem()
        runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Slot: Helmet\nArc 20/0 Default  1\n")
        runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)

	it("Trigger Flamewood", function()
		build.skillsTab:PasteSocketGroup("Decoy Totem 20/0 Default  1\nFlamewood 20/0 Default  1\n")
        runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		mainSocketGroup.mainActiveSkill = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate ~= nil)
    end)
end)