describe("TetsItemMods", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	it("shows versioned reusable variant groups", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Unique
			Grouped Test Item
			Plate Vest
			Version: Pre 3.28.0
			Version: Current
			Variant: Life
			Variant: Energy Shield
			Variant: Mana
			Variant: Armour
			Implicits: 0
			{version:1}{variant:1}{group:1,2}+10 to maximum Life
			{version:2}{variant:2}{group:1,2}+10 to maximum Energy Shield
			{variant:3}{group:1,2}+10 to maximum Mana
			{variant:4}{group:1,2}+10 to Armour
			]])

		local versionControl = build.itemsTab.controls.displayItemVersion
		local group1 = build.itemsTab.controls.displayItemVariant
		local group2 = build.itemsTab.controls.displayItemAltVariant
		assert.is_true(versionControl:IsShown())
		assert.are.equals(2, versionControl.selIndex)
		assert.are.equals("Energy Shield", group1.list[1].label)
		assert.are.equals("Mana", group2.list[1].label)

		group2:SetSel(2)
		group1:SetSel(2)
		assert.are.equals(3, build.itemsTab.displayItem.variantGroupSelections[1])
		versionControl:SetSel(1)
		assert.are.equals(3, build.itemsTab.displayItem.variantGroupSelections[1])
		assert.are.equals("Life", group1.list[1].label)
		assert.are.equals("Mana", group1.list[2].label)
		assert.are.equals("Life", group2.list[1].label)
		assert.are.equals("Armour", group2.list[2].label)
	end)

	it("Dialla's socket mods", function()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nArc 20/0  1\nArc 20/0  1\n")
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

		build.skillsTab:PasteSocketGroup("Slot: Ring 1\nWrath 20/0  1\n")
		runCallback("OnFrame")

		assert.are_not.equals(lightningResBefore, build.calcsTab.mainOutput.LightningResist)
	end)

	it("caps socketed gem multipliers in gem order", function()
		build.itemsTab:CreateDisplayItemFromRaw("Test Gloves\nIron Gauntlets\nSockets: R-R-R-R")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nArc 20/0  1\n")
		runCallback("OnFrame")

		local multipliers = build.calcsTab.mainEnv.itemModDB.multipliers
		assert.are.equals(4, multipliers.SocketedGemsInGloves)
		assert.are.equals(4, multipliers.SocketedRedGemsInGloves)
		assert.are.equals(0, multipliers.SocketedBlueGemsInGloves)
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

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0  1\n")
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

		build.skillsTab:PasteSocketGroup("Smite 20/0  1\nNightblade 20/0  1\n")
		runCallback("OnFrame")
		local nonElusiveCritMult = build.calcsTab.mainOutput.CritMultiplier

		build.configTab.input["buffElusive"] = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(nonElusiveCritMult, build.calcsTab.mainOutput.CritMultiplier)
	end)

	it("Runegraft of the Agile affects average Elusive effect", function()
		build.skillsTab:PasteSocketGroup("Smite 20/0  1\n")
		build.configTab.input.customMods = "Gain Elusive on Critical Strike"
		build.configTab.input.buffElusive = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(50, build.calcsTab.mainOutput.ElusiveEffectMod)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(730 / 9, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds
		Elusive on you reduces in effect 50% slower
		Elusive is removed from you at 20% Effect]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(244 / 3, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds
		100% increased Elusive Effect
		Elusive is removed from you at 100% Effect]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(1630 / 9, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.overrideBuffElusive = 220
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(220, build.calcsTab.mainOutput.ElusiveEffectMod)
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

		build.skillsTab:PasteSocketGroup("Cyclone 20/0  1\nClose Combat 20/0  1\n")
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
	
	it("Kalandra's Touch influence copy", function()

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0  1\n")
		runCallback("OnFrame")

		local dmg = build.calcsTab.mainOutput.AverageDamage

		build.configTab.input.customMods = "\z
		Gain 5% of Elemental Damage as Extra Chaos Damage per Shaper Item Equipped\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(build.calcsTab.mainOutput.AverageDamage, dmg)

		build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Cerulean Ring
		Shaper Item
		Crafted: true
		Prefix: None
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 0
		LevelReq: 80
		Implicits: 0]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.AverageDamage > dmg)

		local dmgOneRing = build.calcsTab.mainOutput.AverageDamage

		build.itemsTab:CreateDisplayItemFromRaw([[Kalandra's Touch
		Ring
		League: Kalandra
		Implicits: 0
		Reflects your other Ring
		Mirrored]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.AverageDamage > dmgOneRing)
	end)

	it("Both slots mod (evasion and es mastery)", function()

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		LevelReq: 33
		Implicits: 1
		+71 to Evasion Rating
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es changes after adding another ring with mod. Regardless of the evasion mod on the first ring being implicit.
	end)

	it("Both slots explicit mod with mixed mod rings (evasion and es mastery)", function()
	
		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		LevelReq: 33
		Implicits: 1
		+71 to Evasion Rating
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es does not change after adding another ring with mod due to the first ring having an implicit evasion mod.
	end)

	it("Both slots explicit mod (evasion and es mastery)", function()

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es changes after adding two rings with explicit mods.
	end)

	it("Both slots explicit mod no rings (evasion and es mastery)", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with no rings.

	end)

	it("mod if no mod on x slot", function()
		local baseLife = build.calcsTab.mainOutput.Life

		build.configTab.input.customMods = "\z
		15% increased maximum Life if there are no Life Modifiers on Equipped Body Armour\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(baseLife, build.calcsTab.mainOutput.Life)

		baseLife = build.calcsTab.mainOutput.Life

		build.itemsTab:CreateDisplayItemFromRaw([[Armour Chest
		Astral Plate
		Armour: 1696
		ArmourBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRating5
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRatingPercent5
		Prefix: {range:0.5}IncreasedLife9
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 62
		Implicits: 1
		{tags:elemental,resistance}{range:0.5}+(8-12)% to all Elemental Resistances
		+92 to Armour
		74% increased Armour
		+95 to maximum Life]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseLife, build.calcsTab.mainOutput.Life)
	end)

	it("globalLimit mods", function()
		build.configTab.input.customMods = [[
			-1000% to cold resistance
		]]
		build.configTab:BuildModList()
		build.itemsTab:CreateDisplayItemFromRaw([[Replica Nebulis
			Void Sceptre
			League: Heist
			Quality: 20
			Sockets: B-B-B
			LevelReq: 68
			Implicits: 1
			40% increased Elemental Damage
			{fractured}{range:1}(15-20)% increased Cast Speed
			{range:1}(15-20)% increased Cold Damage per 1% Missing Cold Resistance, up to a maximum of 300%
			{range:1}(15-20)% increased Fire Damage per 1% Missing Fire Resistance, up to a maximum of 300%]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nFireball 20/0  1\n")
		runCallback("OnFrame")

		assert.are_not.equals(340, build.calcsTab.mainEnv.modDB:Sum("INC", "FireDamage"))
		assert.are_not.equals(340, build.calcsTab.mainEnv.modDB:Sum("INC", "ColdDamage"))

		newBuild()

		build.configTab.input.customMods = [[
			Gain 25% increased Armour per 5 Power for 8 seconds when you Warcry, up to a maximum of 100%
			Warcries have infinite Power
			warcries grant arcane surge to you and allies, with 10% increased effect per 5 power, up to 100%
		]]
		build.configTab:BuildModList()
		build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Plate Vest
			Armour: 32
		]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")

		assert.are_not.equals(40, build.calcsTab.mainEnv.modDB:Sum("INC", { flags = ModFlag.Cast }, "Speed"))
		assert.are_not.equals(64, build.calcsTab.mainOutput.Armour)
		runCallback("OnFrame")
	end)
	
	it("Heralds apply exposure with Heraldry", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\nHerald of Thunder 20/0  1\n")
		runCallback("OnFrame")
		
		assert.are.equals(0.5, build.calcsTab.calcsOutput.LightningEffMult)
				
		build.configTab.input.customMods = [[
		Nearby Enemies have Cold Exposure while you are affected by Herald of Ice
		Nearby Enemies have Fire Exposure while you are affected by Herald of Ash
		Nearby Enemies have Lightning Exposure while you are affected by Herald of Thunder
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0.6, build.calcsTab.calcsOutput.LightningEffMult)
	end)
	
	it("Enemy self curse effect", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\nConductivity 14/0  1\n")
		runCallback("OnFrame")
		
		assert.are.equals(0.8, build.calcsTab.calcsOutput.LightningEffMult)
				
		build.configTab.input.customMods = [[
		Nearby Enemies have 20% increased Effect of Curses on them
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0.86, build.calcsTab.calcsOutput.LightningEffMult)
	end)
	
	it("Max charges with conditional mod", function() -- see #9442
		build.skillsTab:PasteSocketGroup("Grace 20/20  1\n")
		runCallback("OnFrame")
		
		local baseFrenzyChargesMax = build.calcsTab.calcsOutput.FrenzyChargesMax
		local baseEnduranceChargesMax = build.calcsTab.calcsOutput.EnduranceChargesMax
		
		build.configTab.input.customMods = [[
			+1 to Maximum Frenzy Charges while affected by Grace
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseFrenzyChargesMax + 1, build.calcsTab.calcsOutput.FrenzyChargesMax)
		assert.are.equals(baseEnduranceChargesMax, build.calcsTab.calcsOutput.EnduranceChargesMax)
		
		build.configTab.input.customMods = [[
			Your Maximum Endurance Charges is equal to your Maximum Frenzy Charges
			+1 to Maximum Frenzy Charges while affected by Grace
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseFrenzyChargesMax + 1, build.calcsTab.calcsOutput.FrenzyChargesMax)
		assert.are.equals(baseEnduranceChargesMax + 1, build.calcsTab.calcsOutput.EnduranceChargesMax)
	end)

	it("adds life recoup to energy shield recoup", function()
		build.configTab.input.customMods = [[
			20% of Damage taken Recouped as Life
			10% of Physical Damage taken Recouped as Life
			Damage taken Recouped as Life is also Recouped as Energy Shield
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(20, build.calcsTab.calcsOutput.LifeRecoup)
		assert.are.equals(20, build.calcsTab.calcsOutput.EnergyShieldRecoup)
		assert.are.equals(10, build.calcsTab.calcsOutput.PhysicalLifeRecoup)
		assert.are.equals(10, build.calcsTab.calcsOutput.PhysicalEnergyShieldRecoup)
	end)

	it("crafts modifiers from supported bases on rare-like uniques", function()
		local item = new("Item"):Item([[
			Item Class: Helmets
			Rarity: Unique
			Subsume the Source
			Faithful Helmet
			--------
			Item Level: 86
			--------
			{ Prefix Modifier "Hale" }
			+23 to maximum Life
			{ Unique Modifier }
			120% increased Explicit Modifier magnitudes
			{ Suffix Modifier "of Adaption" }
			+7 to all Attributes
			{ Unique Modifier }
			Cannot have non-Abyssal sockets
		]])

		assert.are.equals(4, item.affixLimit)
		assert.are.equals(4, item.prefixes.limit)
		assert.are.equals(0, item.suffixes.limit)
		assert.are.equals("AbyssJewelAddedLife1", item.prefixes[1].modId)
		assert.are.equals("AbyssAllAttributesJewel1", item.prefixes[2].modId)
		build.itemsTab.displayItem = item
		build.itemsTab:UpdateAffixControls()
		local lifeModAvailable = false
		for _, entry in ipairs(build.itemsTab.controls.displayItemAffix2.list) do
			for _, modId in ipairs(type(entry) == "table" and entry.modList or { }) do
				lifeModAvailable = lifeModAvailable or modId == "AbyssJewelAddedLife1"
			end
		end
		assert.is_true(lifeModAvailable)

		item:Craft()
		local raw = item:BuildRaw()
		assert.is_truthy(raw:find("increased Explicit Modifier magnitudes", 1, true))
		assert.is_truthy(raw:find("Cannot have non-Abyssal sockets", 1, true))
	end)

	it("uses the item base for rare-like modifier eligibility by default", function()
		local item = new("Item"):Item([[
			Item Class: Bows
			Rarity: Unique
			The Crimson Storm
			Steelwood Bow
			--------
			Item Level: 85
			--------
			{ Suffix Modifier "of the Order" }
			+24(24-28)% to Physical Damage over Time Multiplier
		]])

		assert.are.equals(1, item.affixLimit)
		assert.are.equals(0, item.prefixes.limit)
		assert.are.equals(1, item.suffixes.limit)
		assert.are.equals("JunMasterVeiledPhysicalDamageOverTimeMultiplier", item.suffixes[1].modId)
	end)

	it("keeps modifier metadata on duplicate variant tooltip lines", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Duplicate Variant Test
			Plate Vest
			Variant: First
			Variant: Second
			Selected Variant: 1
			Has Alt Variant: true
			Selected Alt Variant: 1
			Allow Duplicate Variants: true
			Implicits: 0
			{variant:1}+10 to maximum Life
		]])
		local tooltip = new("Tooltip"):Tooltip()
		build.itemsTab:AddItemTooltip(tooltip, item)

		local count = 0
		for _, line in ipairs(tooltip.lines) do
			if line.text and line.text:find("maximum Life", 1, true) then
				assert.are.equals(item.explicitModLines[1], line.modLine)
				count = count + 1
			end
		end
		assert.are.equals(2, count)
	end)

	it("does not sort cluster jewel modifiers when the sorting control is hidden", function()
		local item = new("Item"):Item([[
			Rarity: RARE
			New Item
			Large Cluster Jewel
			Crafted: true
			Prefix: {range:0.5}AfflictionNotableWickedPall_
			Prefix: {range:0.5}AfflictionNotableMiseryEverlasting
			Suffix: {range:0.5}AfflictionNotableUnholyGrace_
			Suffix: None
			Cluster Jewel Skill: affliction_chaos_damage
			Cluster Jewel Node Count: 8
			Quality: 0
			LevelReq: 40
			Implicits: 3
			{crafted}Adds 8 Passive Skills
			{crafted}2 Added Passive Skills are Jewel Sockets
			{crafted}Added Small Passive Skills grant: 12% increased Chaos Damage
			1 Added Passive Skill is Misery Everlasting
			1 Added Passive Skill is Unholy Grace
			1 Added Passive Skill is Wicked Pall
		]])
		local calcCount = 0
		build.itemsTab.displayItem = item
		build.itemsTab.controls.craftingSorting:SetSel(2, true)
		build.calcsTab.GetMiscCalculator = function()
			return function()
				calcCount = calcCount + 1
				return { }
			end
		end

		assert.is_false(build.itemsTab.controls.craftingSortingLabel.shown())
		build.itemsTab:UpdateAffixControls()
		assert.are.equals(0, calcCount)
	end)

	it("shows custom modifier controls when affix crafting is hidden", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Item
			Iron Ring
			Implicits: 1
			Adds 1 to 4 Physical Damage to Attacks
			{crafted}+8 to Strength
		]])

		local controls = build.itemsTab.controls
		assert.is_falsy(build.itemsTab.displayItem.crafted)
		assert.is_falsy(controls.displayItemSectionAffix:IsShown())
		assert.is_true(controls.displayItemSectionCustom:IsShown())
		assert.is_true(controls.displayItemAddCustom:IsShown())
		assert.is_true(controls.displayItemCustomModifierRemove1:IsShown())
	end)

	it("shows affix controls for items crafted in Path of Building", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			New Item
			Cobalt Jewel
			Crafted: true
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Quality: 0
			LevelReq: 0
			Implicits: 0
		]])

		local controls = build.itemsTab.controls
		assert.is_true(controls.displayItemSectionAffix:IsShown())
		assert.is_true(controls.displayItemAffix1:IsShown())
	end)

	it("sorts crafted modifier replacements without retaining the selected modifier", function()
		local item = new("Item"):Item([[
			Rarity: RARE
			New Item
			Cobalt Jewel
			Crafted: true
			Prefix: {range:1}PercentIncreasedLifeJewel
			Prefix: None
			Suffix: None
			Suffix: None
			Quality: 0
			LevelReq: 0
			Implicits: 0
			7% increased maximum Life
		]])
		local calcCount = 0
		local retainedCount = 0
		build.itemsTab.displayItem = item
		build.itemsTab.controls.craftingSorting:SetSel(2, true)
		build.calcsTab.GetMiscCalculator = function()
			return function(args)
				calcCount = calcCount + 1
				for _, modLine in ipairs(args.repItem.explicitModLines) do
					if modLine.line == "7% increased maximum Life" then
						retainedCount = retainedCount + 1
						break
					end
				end
				return { }
			end
		end

		build.itemsTab:UpdateAffixControl(build.itemsTab.controls.displayItemAffix1, item, "Prefix", "prefixes", 1, { })
		assert.is_true(calcCount > 1)
		assert.are.equals(0, retainedCount)
	end)
	
	it("shows a fallback tooltip when an item's base is no longer supported", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Legacy Item
			Removed Base
		]])
		local tooltip = new("Tooltip"):Tooltip()

		assert.has_no.errors(function()
			build.itemsTab:AddItemTooltip(tooltip, item)
		end)
		assert.is_truthy(tooltip.lines[#tooltip.lines].text:find("Item base is not supported", 1, true))
	end)

end)
