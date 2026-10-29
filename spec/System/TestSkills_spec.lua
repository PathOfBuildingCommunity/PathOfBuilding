describe("TestSkills", function()
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

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAwakened Generosity 4/0  1\n")
		runCallback("OnFrame")
		assert.are.equals(round(205 * 1.43), build.calcsTab.mainEnv.minion.modDB:Sum("BASE", build.calcsTab.mainEnv.minion.mainSkill.skillCfg, "ChaosMin"))

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nAwakened Generosity 5/0  1\n")
		runCallback("OnFrame")
		-- No Envy level increase, so base should still be 205
		assert.are.equals(round(205 * 1.44), build.calcsTab.mainEnv.minion.modDB:Sum("BASE", build.calcsTab.mainEnv.minion.mainSkill.skillCfg, "ChaosMin"))
	end)

	it("applies Aspect of the Brine King's chilling aura", function()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nCoral Amulet\nGrants Level 20 Aspect of the Brine King Skill")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Freezing Pulse 20/0  1\n")
		runCallback("OnFrame")

		local env = build.calcsTab.mainEnv
		assert.is_true(env.enemy.modDB:Flag(nil, "Condition:Chilled"))
		assert.are.equals(15, build.calcsTab.mainOutput.CurrentChill)
		assert.are.equals(50, env.player.mainSkill.skillModList:Sum("INC", env.player.mainSkill.skillCfg, "EnemyChillEffect"))
		assert.are.equals(10, env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ColdPenetration"))
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

		build.skillsTab:PasteSocketGroup("Mirage Archer 20/0  1\nRain of Arrows 20/0  1\nManaforged Arrows 20/0  1\n")
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Toxic Rain 20/0  1\n")
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.MirageDPS ~= nil)

		assert.True(build.calcsTab.mainOutput.SkillTriggerRate == build.calcsTab.mainOutput.Speed)
		assert.is_true(not build.calcsTab.mainEnv.player.mainSkill.skillCfg.skillCond.usedByMirage)
	end)

	it("calculates The Saviour Reflection mirages for a player sword attack", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Rarity: Unique
The Saviour
Legion Sword
Implicits: 1
40% increased Global Accuracy Rating
Triggers Level 20 Reflection when Equipped
(130-150)% increased Physical Damage
Adds (16-22) to (40-45) Physical Damage
(8-12)% increased Attack Speed
(8-12)% increased Critical Strike Chance]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Double Strike 20/0  1\n")
		runCallback("OnFrame")
		local player = build.calcsTab.mainEnv.player
		assert.is_true(not player.mainSkill.skillCfg.skillCond.usedByMirage)
	end)
	
	it("Test Sacred wisps using current skill", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Elemental Wand
			Imbued Wand
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Quality: 0
			Sockets: B-B-B
			LevelReq: 59
			Implicits: 0]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Power Siphon 20/0  1\nSacred Wisps 20/0  1\n")
		runCallback("OnFrame")

		assert.True(build.calcsTab.mainOutput.MirageDPS ~= nil)
	end)

	it("checks equipped weapon types for support-granted attacks", function()
		build.itemsTab:CreateDisplayItemFromRaw("Test Claw\nImperial Claw")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Cobra Lash 20/0  1\nWindburst 20/0  1\nNightblade 20/0  1\nSacred Wisps 20/0  1\n")
		runCallback("OnFrame")

		local windburst
		for _, activeSkill in ipairs(build.calcsTab.mainEnv.player.activeSkillList) do
			if activeSkill.activeEffect.grantedEffect.id == "TriggeredSupportWindburst" then
				windburst = activeSkill
				break
			end
		end
		assert.is_not_nil(windburst)

		local supports = { }
		for _, effect in ipairs(windburst.effectList) do
			supports[effect.grantedEffect.id] = true
		end
		assert.is_true(supports.SupportNightblade)
		assert.is_nil(supports.SupportSacredWisps)
	end)

	it("keeps forced mana reservations on mana", function()
		build.itemsTab:CreateDisplayItemFromRaw("Test Staff\nJudgement Staff")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Mana-Infused Staff 20/0  1\nArrogance 20/0  1\n")
		runCallback("OnFrame")

		local activeSkill = build.calcsTab.mainEnv.player.mainSkill
		assert.are.equals("SupportArrogance", activeSkill.effectList[2].grantedEffect.id)
		assert.is_nil(activeSkill.skillFlags.disable)
		assert.are.equals(30, build.calcsTab.mainEnv.player.output.ManaReservedPercent)
		assert.are.equals(0, build.calcsTab.mainEnv.player.output.LifeReserved)

		build.configTab.input.customMods = "Removes all mana\nSkills Reserve Life instead of Mana"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		activeSkill = build.calcsTab.mainEnv.player.mainSkill
		assert.is_true(activeSkill.skillFlags.disable)
		assert.are.equals("This skill requires reserving Mana", activeSkill.disableReason)
		assert.are.equals(0, activeSkill.skillData.ManaReservedBase)
		assert.is_nil(activeSkill.skillData.LifeReservedBase)
	end)
	
	it("Test Scorching ray applying exposure at max stages", function()
		build.skillsTab:PasteSocketGroup("Scorching Ray 20/0  1\n")
		runCallback("OnFrame")
		
		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance
		srcInstance.skillStageCount = 8
		build.modFlag = true
		build.buildFlag = true
		build.configTab.input.enemyIsBoss = "None"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		-- Manual stages
		assert.True(build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "FireResist") < 0)

		srcInstance.skillPart = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		-- Automatic maximum sustainable stages
		assert.True(build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "FireResist") < 0)
	end)

	it("Defaults Blade Blast to the skill's blade cap", function()
		build.skillsTab:PasteSocketGroup("Blade Blast 20/0  1\n")
		runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local activeSkill = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill]
		local calcsSkillSelectControls = build.calcsTab.sectionList[1].controls
		build:RefreshSkillSelectControls(calcsSkillSelectControls, build.calcsTab.input.skill_number, "Calcs")

		assert.are.equals("50", build.controls.mainSkillStageCount.buf)
		assert.are.equals("50", calcsSkillSelectControls.mainSkillStageCount.buf)
		assert.are.equals(50, activeSkill.skillData.stagesMax)
		assert.are.equals(50, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStage"))
		assert.are.equals(49, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStageAfterFirst"))

		local cappedAverageDamage = build.calcsTab.mainOutput.AverageDamage
		local cappedTotalDPS = build.calcsTab.mainOutput.TotalDPS
		local cappedCombinedDPS = build.calcsTab.mainOutput.CombinedDPS
		activeSkill.activeEffect.srcInstance.skillStageCount = 51
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		activeSkill = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill]
		assert.are.equals("51", build.controls.mainSkillStageCount.buf)
		assert.are.equals(50, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStage"))
		assert.are.equals(49, activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "Multiplier:BladeBlastStageAfterFirst"))
		assert.are.equals(cappedAverageDamage, build.calcsTab.mainOutput.AverageDamage)
		assert.are.equals(cappedTotalDPS, build.calcsTab.mainOutput.TotalDPS)
		assert.are.equals(cappedCombinedDPS, build.calcsTab.mainOutput.CombinedDPS)
	end)

	it("uses enemy radius when calculating Ball Lightning hits", function()
		build.skillsTab:PasteSocketGroup("Ball Lightning 20/0  1\n")
		runCallback("OnFrame")

		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance.skillPart = 2
		build.configTab.input.projectileDistance = 40
		build.configTab.input.enemyRadius = 1
		build.configTab:BuildModList()
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		local smallEnemyHits = build.calcsTab.mainOutput.SkillDPSMultiplier

		build.configTab.input.enemyRadius = 11
		build.configTab:BuildModList()
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.SkillDPSMultiplier > smallEnemyHits)
	end)

	it("Test Adrenaline affecting blight max stage count", function()
		build.skillsTab:PasteSocketGroup("Blight 20/0  1\n")
		runCallback("OnFrame")
		
		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance
		srcInstance.skillPart = 2
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		
		local preAdrenalineMaxStages = build.calcsTab.mainEnv.player.activeSkillList[1].skillModList:Sum("BASE", nil, "Multiplier:BlightMaxStages")
		build.configTab.input.buffAdrenaline = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.True(preAdrenalineMaxStages < build.calcsTab.mainEnv.player.activeSkillList[1].skillModList:Sum("BASE", nil, "Multiplier:BlightMaxStages"))
	end)

	it("calculates added resistance from heralds even when using scornful herald", function()
		build.skillsTab:PasteSocketGroup("Cyclone 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Herald of Thunder 20/0  1\nScornful Herald 20/0  1\n")
		build.itemsTab:CreateDisplayItemFromRaw([[Circle of Regret
		Topaz Ring
		{tags:resistance}+(50-60)% to Lightning Resistance while affected by Herald of Thunder
		]])
		build.itemsTab:AddDisplayItem()
		
		runCallback("OnFrame")

		assert.are.equals(0, build.calcsTab.mainEnv.player.modDB:Sum("BASE", nil, "LightningMin"))
		assert.are.equals(-5, build.calcsTab.mainEnv.player.modDB:Sum("BASE", nil, "LightningResist"))
	end)

	it("calculates Wintertide Brand average damage for attached brands and Wintertide's End", function()
		local function getAverageDamageMultiplier()
			for _, mod in ipairs(build.calcsTab.mainEnv.player.mainSkill.skillModList) do
				if mod.source == "Wintertide Brand Average Multiplier" then
					return mod.value
				end
			end
		end

		build.skillsTab:PasteSocketGroup("Wintertide Brand 20/0  1\n")
		runCallback("OnFrame")
		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance
		srcInstance.skillPart = 1
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		assert.is_true(build.configTab.varControls.BrandsAttachedToEnemy.shown())
		assert.are.equals(8, build.calcsTab.mainOutput.BrandTicks)
		assert.are.near(2, build.calcsTab.mainOutput.DurationTertiary, 0.02)
		assert.are.equals(20, build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "Multiplier:WintertideBrandMaxStages"))
		assert.are.equals("Average Damage for 2 attached Brands", build.calcsTab.mainEnv.player.mainSkill.infoMessage)
		assert.are.near(500, getAverageDamageMultiplier(), 10 ^ -9)

		build.configTab.input.BrandsAttachedToEnemy = 1
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals("Average Damage for 1 attached Brand", build.calcsTab.mainEnv.player.mainSkill.infoMessage)
		assert.are.near(330, getAverageDamageMultiplier(), 10 ^ -9)

		build.configTab.input.BrandsAttachedToEnemy = nil
		build.configTab.input.customMods = "You can have an additional Brand Attached to an Enemy"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals("Average Damage for 3 attached Brands", build.calcsTab.mainEnv.player.mainSkill.infoMessage)
		assert.are.near(670, getAverageDamageMultiplier(), 10 ^ -9)

		build.configTab.input.customMods = "400% increased Skill Effect Duration"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(40, build.calcsTab.mainOutput.BrandTicks)
		assert.are.near(1190, getAverageDamageMultiplier(), 10 ^ -9)
	end)

	it("multiplies Brand DPS by the attached Brand count", function()
		build.skillsTab:PasteSocketGroup("Armageddon Brand 20/0  1\n")
		runCallback("OnFrame")

		local singleBrandDPS = build.calcsTab.mainOutput.TotalDPS
		build.configTab.input.customMods = "You can have an additional Brand Attached to an Enemy"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(singleBrandDPS * 2, build.calcsTab.mainOutput.TotalDPS, 10 ^ -9)
		assert.are.equals("DPS for 2 attached Brands", build.calcsTab.mainEnv.player.mainSkill.infoMessage)
	end)

	it("multiplies manually staged Brand damage over time by the attached Brand count", function()
		build.skillsTab:PasteSocketGroup("Wintertide Brand 20/0  1\n")
		runCallback("OnFrame")
		local mainSocketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		mainSocketGroup.displaySkillList[mainSocketGroup.mainActiveSkill].activeEffect.srcInstance.skillPart = 2
		build.configTab.input.BrandsAttachedToEnemy = 1
		build.configTab:BuildModList()
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		local singleBrandDPS = build.calcsTab.mainOutput.TotalDot
		build.configTab.input.BrandsAttachedToEnemy = nil
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(singleBrandDPS * 2, build.calcsTab.mainOutput.TotalDot, 10 ^ -9)
	end)

	it("caps total Brand Recall Cooldown Recovery from multiple Chip Away notables at 40%", function()
		build.skillsTab:PasteSocketGroup("Storm Brand 20/0  1\n")
		build.configTab.input.ActiveBrands = 10
		build.configTab.input.customMods = [[
			You can cast 7 additional brands
			Brand Recall has 4% increased Cooldown Recovery Rate per Brand, up to a maximum of 40%
			Brand Recall has 4% increased Cooldown Recovery Rate per Brand, up to a maximum of 40%
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(40, build.calcsTab.mainEnv.modDB:Sum("INC", { skillName = "Brand Recall" }, "CooldownRecovery"))
	end)

	it("applies a single Chip Away notable per active Brand", function()
		build.skillsTab:PasteSocketGroup("Storm Brand 20/0  1\n")
		build.configTab.input.ActiveBrands = 3
		build.configTab.input.customMods = "Brand Recall has 4% increased Cooldown Recovery Rate per Brand, up to a maximum of 40%"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(12, build.calcsTab.mainEnv.modDB:Sum("INC", { skillName = "Brand Recall" }, "CooldownRecovery"))
	end)

	it("counts support gem brand limit increases in the active Brand count", function()
		build.skillsTab:PasteSocketGroup("Storm Brand 20/0  1\nFoul Grasp 1/0  1\n")
		build.configTab.input.ActiveBrands = 5
		build.configTab.input.customMods = "Brand Recall has 4% increased Cooldown Recovery Rate per Brand, up to a maximum of 40%"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(20, build.calcsTab.mainEnv.modDB:Sum("INC", { skillName = "Brand Recall" }, "CooldownRecovery"))
	end)

	it("uses the highest brand limit across multiple brand skills for the active Brand count", function()
		build.skillsTab:PasteSocketGroup("Storm Brand 20/0  1\nFoul Grasp 1/0  1\n")
		build.skillsTab:PasteSocketGroup("Armageddon Brand 20/0  1\n")
		build.configTab.input.ActiveBrands = 5
		build.configTab.input.customMods = "Brand Recall has 4% increased Cooldown Recovery Rate per Brand, up to a maximum of 40%"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(20, build.calcsTab.mainEnv.modDB:Sum("INC", { skillName = "Brand Recall" }, "CooldownRecovery"))
	end)

	it("averages inverted elemental resistance after penetration", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		build.configTab.input.enemyIsBoss = "None"
		build.configTab.input.enemyFireResist = 50
		build.configTab.input.customMods = "Hits have 50% chance to treat Enemy Monster Elemental Resistance values as inverted\nDamage Penetrates 50% of Enemy Fire Resistance"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Unlike PoE 2, PoE 1 penetration can lower resistance below zero:
		-- 50% of hits use 0% resistance and 50% use -100% resistance.
		assert.are.equals(1.5, build.calcsTab.calcsOutput.FireEffMult)
		local breakdownText = table.concat(build.calcsTab.calcsEnv.player.breakdown.FireEffMult, "\n")
		assert.is_truthy(breakdownText:match("inverted hit"))
		assert.is_truthy(breakdownText:match("weighted average"))
	end)
	it("Test cost efficiency modifiers", function()
		-- Test Mana Cost Efficiency
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		runCallback("OnFrame")

		-- Get base mana cost (Hydrosphere level 1 has 12 mana cost)
		local baseCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(12, baseCost)

		-- Add 50% mana cost efficiency (should reduce cost to 12/1.5 = 8)
		build.configTab.input.customMods = "50% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local reducedCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(8, reducedCost)

		-- Test generic cost efficiency (should also affect mana)
		newBuild()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "25% increased Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local genericEfficiencyCost = build.calcsTab.mainOutput.ManaCost
		-- The game rounds 12 / 1.25 = 9.6 after applying efficiency.
		assert.are.equals(10, genericEfficiencyCost)

		-- Test multiple efficiency sources stacking additively
		build.configTab.input.customMods = "25% increased Cost Efficiency\n25% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local stackedCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(8, stackedCost) -- 12/(1 + 0.25 + 0.25) = 12/1.5 = 8
	end)

	it("Test cost efficiency with cost modifiers", function()
		-- Test interaction between cost efficiency and cost multipliers
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")

		-- Add cost multiplier and efficiency
		build.configTab.input.customMods = "50% increased Mana Cost\n50% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local finalCost = build.calcsTab.mainOutput.ManaCost
		assert.True(math.abs(finalCost - 12) < 0.1) -- floor(12 * 1.5) / 1.5
	end)

	it("Test flat cost is added after cost efficiency", function()
		-- In-game order is ((base cost * multipliers) + flat cost) / (1 + cost efficiency)
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")

		-- Hydrosphere 12 base mana cost
		build.configTab.input.customMods = "+10 to Total Mana Cost\n50% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local finalCost = build.calcsTab.mainOutput.ManaCost
		-- 12 / 1.5 + 10 = 18
		assert.equals(18, finalCost)
	end)
	it("Test flat cost is added after cost efficiency for life costs", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")

		-- Convert Hydrosphere's 12 base cost to life, then add +10 flat and 50% efficiency
		build.configTab.input.customMods = "Skills Cost Life instead of Mana\n+10 to Total Cost\n50% increased Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- 12 / 1.5 + 10 = 18
		assert.equals(18, build.calcsTab.mainOutput.LifeCost)
	end)

	it("converts and rounds flat mana cost separately from base cost", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Life instead of 15% of Mana Cost\n+4 to Total Mana Cost"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.equals(3, build.calcsTab.mainOutput.LifeCost)
		assert.equals(13, build.calcsTab.mainOutput.ManaCost)
	end)

	it("moves flat mana cost when all costs are converted", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Life instead of Mana\n+4 to Total Mana Cost"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.equals(16, build.calcsTab.mainOutput.LifeCost)
		assert.equals(0, build.calcsTab.mainOutput.ManaCost)
	end)

	it("does not move reduced flat mana cost to life", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Life instead of Mana\nNon-Channelling Skills have -7 to Total Mana Cost"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.equals(12, build.calcsTab.mainOutput.LifeCost)
		assert.equals(0, build.calcsTab.mainOutput.ManaCost)
	end)

	it("does not partially convert reduced flat mana cost to life", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Life instead of 15% of Mana Cost\nNon-Channelling Skills have -7 to Total Mana Cost"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.equals(2, build.calcsTab.mainOutput.LifeCost)
		assert.equals(4, build.calcsTab.mainOutput.ManaCost)
	end)

	it("Test flat cost is added after cost efficiency for energy shield costs", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")

		-- Convert Hydrosphere's 12 base cost to ES, then add +10 flat and 50% efficiency
		build.configTab.input.customMods = "Skills Cost Energy Shield instead of Mana or Life\n+10 to Total Cost\n50% increased Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- 12 / 1.5 + 10 = 18
		assert.equals(18, build.calcsTab.mainOutput.ESCost)
	end)

	it("moves flat mana cost to energy shield with the base cost", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Energy Shield instead of Mana or Life\n+4 to Total Mana Cost"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.equals(16, build.calcsTab.mainOutput.ESCost)
		assert.equals(0, build.calcsTab.mainOutput.ManaCost)
	end)

	it("does not move reduced flat mana cost to energy shield", function()
		build.skillsTab:PasteSocketGroup("Hydrosphere 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Energy Shield instead of Mana or Life\nNon-Channelling Skills have -7 to Total Mana Cost"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.equals(12, build.calcsTab.mainOutput.ESCost)
		assert.equals(0, build.calcsTab.mainOutput.ManaCost)
	end)

	it("only grants payable cost damage when the full cost can be paid", function()
		build.skillsTab:PasteSocketGroup("Fireball 1/0  1\n")
		build.configTab.input.customMods = "Skills gain Added Chaos Damage equal to 25% of Mana Cost, if Mana Cost is not higher than the maximum you could spend"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(5, build.calcsTab.mainOutput.ManaCost)
		assert.are.equals(1, build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "ChaosMin"))

		build.configTab.input.customMods = build.configTab.input.customMods .. "\n-10000 to maximum Mana"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0, build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "ChaosMin"))

		build.configTab.input.customMods = build.configTab.input.customMods .. "\nEnergy Shield protects Mana instead of Life\n+100 to maximum Energy Shield"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(1, build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "ChaosMin"))
	end)

	it("checks life-cost damage against the full life cost", function()
		build.skillsTab:PasteSocketGroup("Fireball 1/0  1\n")
		build.configTab.input.customMods = "Skills Cost Life instead of Mana\nSkills gain Added Chaos Damage equal to 25% of Life Cost, if Life Cost is not higher than the maximum you could spend\n-10000 to maximum Life"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(5, build.calcsTab.mainOutput.LifeCost)
		assert.are.equals(0, build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "ChaosMin"))
	end)
	it("Test mana cost efficiency with support gems", function()
		-- Test interaction between cost efficiency and cost multipliers
		build.skillsTab:PasteSocketGroup("Contagion 6/0  1\nMagnified Area I 1/0  1")

		-- Add efficiency
		build.configTab.input.customMods = "36% increased Mana Cost Efficiency"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local finalCost = build.calcsTab.mainOutput.ManaCost
		assert.are.equals(7, round(finalCost))
	end)

	it("rounds Supreme Ego mana reservation down", function()
		build.skillsTab:PasteSocketGroup("Precision 1/0  1\n")
		local supremeEgo = build.spec.tree.keystoneMap["Supreme Ego"]
		build.spec:AllocNode(build.spec.nodes[supremeEgo.id])
		build.spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		-- 22 base + floor(40% of 22) = 30, rather than round(22 * 1.4) = 31.
		assert.are.equals(30, build.calcsTab.mainEnv.player.mainSkill.skillData.ManaReservedBase)
	end)

	it("evaluates BaseFlag tags using PoB 1 skill data", function()
		build.skillsTab:PasteSocketGroup("Absolution 20/0  1\n")
		runCallback("OnFrame")

		local durationSkill = build.calcsTab.mainEnv.player.mainSkill
		durationSkill.skillModList:NewMod("BaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration" })
		durationSkill.skillModList:NewMod("NegatedBaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration", neg = true })
		assert.are.equals(1, durationSkill.skillModList:Sum("BASE", durationSkill.skillCfg, "BaseFlagTest"))
		assert.are.equals(0, durationSkill.skillModList:Sum("BASE", durationSkill.skillCfg, "NegatedBaseFlagTest"))

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
		runCallback("OnFrame")

		local nonDurationSkill = build.calcsTab.mainEnv.player.mainSkill
		nonDurationSkill.skillModList:NewMod("BaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration" })
		nonDurationSkill.skillModList:NewMod("NegatedBaseFlagTest", "BASE", 1, "Test", { type = "BaseFlag", baseFlag = "duration", neg = true })
		assert.are.equals(0, nonDurationSkill.skillModList:Sum("BASE", nonDurationSkill.skillCfg, "BaseFlagTest"))
		assert.are.equals(1, nonDurationSkill.skillModList:Sum("BASE", nonDurationSkill.skillCfg, "NegatedBaseFlagTest"))
	end)

	it("applies Pact of Beidat coverage based on uptime", function()
		for _, test in ipairs({
			{ skill = "Fireball", output = "ProjectileCount", bonus = "BeidatAdditionalProjectiles", amount = 4 },
			{ skill = "Arc", output = "ChainMax", bonus = "BeidatAdditionalBeamChains", amount = 4 },
			{ skill = "Firestorm", bonus = "BeidatAdditionalCascades", amount = 5 },
		}) do
			newBuild()
			build.skillsTab:PasteSocketGroup(test.skill.." 20/0  1")
			runCallback("OnFrame")
			local baseOutput = test.output and build.calcsTab.mainOutput[test.output]
			local baseDPS = build.calcsTab.mainOutput.TotalDPS

			build.skillsTab:PasteSocketGroup("Pact of Beidat 1/0  1")
			runCallback("OnFrame")
			local output = build.calcsTab.mainOutput
			local expectedBonus = test.amount * output.BeidatUpTimeRatio / 100
			assert.are.near(expectedBonus, output[test.bonus], 10 ^ -9)
			if test.output then
				assert.are.near(baseOutput + expectedBonus, output[test.output], 10 ^ -9)
			end
			assert.is_true(output.TotalDPS > baseDPS)
		end

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nPact of Beidat 1/0  1")
		build.configTab.input.pactMode = "MAX"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equals(4, build.calcsTab.mainOutput.BeidatAdditionalProjectiles)
	end)

	it("applies Pact damage to eligible spells", function()
		for _, test in ipairs({
			{ skill = "Creeping Frost", pact = "Pact of Ghorr", uptime = "GhorrUpTimeRatio", dps = "TotalDotDPS" },
			{ skill = "Lightning Tendrils", pact = "Pact of Lycia", uptime = "LyciaUpTimeRatio", dps = "TotalDPS" },
		}) do
			newBuild()
			build.skillsTab:PasteSocketGroup(test.skill.." 20/0  1")
			runCallback("OnFrame")
			local baseDPS = build.calcsTab.mainOutput[test.dps]
			build.skillsTab:PasteSocketGroup(test.pact.." 1/0  1")
			runCallback("OnFrame")
			local output = build.calcsTab.mainOutput
			assert.is_true(output[test.uptime] > 0)
			assert.is_true(output[test.dps] > baseDPS)
		end

		newBuild()
		build.skillsTab:PasteSocketGroup("Lightning Tendrils 20/0  1\nSpell Totem 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.mainOutput.TotalDPS
		build.skillsTab:PasteSocketGroup("Pact of Lycia 1/0  1")
		runCallback("OnFrame")
		assert.is_nil(build.calcsTab.mainOutput.LyciaUpTimeRatio)
		assert.are.equals(baseDPS, build.calcsTab.mainOutput.TotalDPS)
	end)

	it("applies Pact of K'Tash to instant damaging Vaal spells", function()
		build.skillsTab:PasteSocketGroup("Vaal Righteous Fire 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.mainOutput.TotalDotDPS
		local basePrevention = build.calcsTab.mainOutput.SoulGainPreventionDuration

		build.skillsTab:PasteSocketGroup("Pact of K'Tash 1/0  1")
		runCallback("OnFrame")
		local output = build.calcsTab.mainOutput
		assert.are.equals(100, output.KtashUpTimeRatio)
		assert.are.near(baseDPS * 1.1, output.TotalDotDPS, 10 ^ -6)
		assert.are.equals(100, output.KtashSoulRefundChance)
		assert.are.equals(math.max(math.ceil(basePrevention * 0.5 * data.misc.ServerTickRate), 1) / data.misc.ServerTickRate, output.SoulGainPreventionDuration)
	end)

	it("does not apply Pacts to ineligible spells", function()
		for _, test in ipairs({
			{ "Vaal Arc", "Pact of Beidat", "BeidatUpTimeRatio" },
			{ "Vaal Arc", "Pact of Ghorr", "GhorrUpTimeRatio" },
			{ "Fireball", "Pact of K'Tash", "KtashUpTimeRatio" },
			{ "Fireball", "Pact of Lycia", "LyciaUpTimeRatio" },
		}) do
			newBuild()
			build.skillsTab:PasteSocketGroup(test[1].." 20/0  1\n"..test[2].." 1/0  1")
			runCallback("OnFrame")
			assert.is_nil(build.calcsTab.mainOutput[test[3]])
		end
	end)

	it("ignores invalid extra supports while allowing support name collisions", function()
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nFireball 20/0  1")
		runCallback("OnFrame")
		build.configTab.input.customMods = "Skills socketed in your gloves are supported by level 20 Arc"
		build.configTab:BuildModList()
		build.modFlag = true
		build.buildFlag = true
		assert.has_no.errors(function()
			main:OnFrame()
		end)
		assert.are.equals(0, #build.calcsTab.mainEnv.player.mainSkill.supportList)

		newBuild()
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nFireball 20/0  1")
		build.configTab.input.customMods = "Skills socketed in your gloves are supported by level 20 Arcane Surge"
		build.configTab:BuildModList()
		main:OnFrame()
		local arcaneSurge = build.calcsTab.mainEnv.player.mainSkill.supportList[1]
		assert.are.equals("SupportArcaneSurge", arcaneSurge.grantedEffect.id)
		assert.are.equals(20, arcaneSurge.level)

		newBuild()
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nRain of Arrows 20/0  1")
		build.configTab.input.customMods = "Skills socketed in your gloves are supported by level 20 Barrage"
		build.configTab:BuildModList()
		main:OnFrame()
		local barrage = build.calcsTab.mainEnv.player.mainSkill.supportList[1]
		assert.are.equals("SupportBarrage", barrage.grantedEffect.id)
		assert.are.equals(20, barrage.level)
	end)
end)
