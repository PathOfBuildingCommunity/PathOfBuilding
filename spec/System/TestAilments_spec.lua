describe("TestAilments", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function rebuild()
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	it("maximum shock value", function()
		-- Shock Nova
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nShock Nova 4/0  1\n")
		runCallback("OnFrame")
		assert.are.equals(round(50 + 10), build.calcsTab.mainOutput.MaximumShock)

		-- Voltaxic Rift
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nAssassin Bow\n+40% to Maximum Effect of Shock")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(round(50 + 10 + 40), build.calcsTab.mainOutput.MaximumShock)
	end)

	it("bleed is buffed by bleed chance", function()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nKarui Chopper")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHeavy Strike 1/0  1\n")
		build.configTab.input.customMods = "\z
		attacks have 10% chance to cause bleeding\n\z
		"
		rebuild()
		local badDps = build.calcsTab.mainOutput.BleedDPS

		build.configTab.input.customMods = "\z
		attacks have 100% chance to cause bleeding\n\z
		"
		rebuild()
		local goodDps = build.calcsTab.mainOutput.BleedDPS
		assert.True(goodDps > badDps)
	end)

	it("scales hit ailments with target ailment effect", function()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nShock Nova 20/0  1\n")
		build.configTab.input.customMods = "Drop Brine Ground while moving, lasting 4 seconds"
		rebuild()

		assert.are.equals(1, build.calcsTab.mainOutput.ShockEffectMod)

		build.configTab.input.conditionEnemyOnBrineGround = true
		rebuild()

		assert.are.near(1.3, build.calcsTab.mainOutput.ShockEffectMod, 10 ^ -9)
	end)

	it("scales minion ailment duration with Barnacles", function()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSummon Ice Golem 20/0  1\n")
		build.configTab.input.customMods = "Inflict Barnacles on nearby Enemies every second\nMinions gain 100% of Physical Damage as Extra Cold Damage"
		rebuild()
		local baseFreezeDurationMod = build.calcsTab.mainEnv.minion.output.FreezeDurationMod
		local baseChillDuration = build.calcsTab.mainEnv.minion.output.ChillDuration

		build.configTab.input.multiplierBarnacleStacks = 10
		rebuild()

		assert.are.near(baseChillDuration * 1.5, build.calcsTab.mainEnv.minion.output.ChillDuration, 10 ^ -9)
		assert.are.near(baseFreezeDurationMod * 1.5, build.calcsTab.mainEnv.minion.output.FreezeDurationMod, 10 ^ -9)
		assert.are.equals(50, build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "PhysicalDamageConvertToCold"))
	end)

	it("scales chilling area duration with Barnacles", function()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nCold Snap 20/0  1\n")
		build.configTab.input.customMods = "Inflict Barnacles on nearby Enemies every second"
		rebuild()

		assert.are.equals(1, build.calcsTab.mainOutput.ChillDurationMod)

		build.configTab.input.multiplierBarnacleStacks = 10
		rebuild()

		assert.are.equals(1.5, build.calcsTab.mainOutput.ChillDurationMod)
	end)

	it("scales guaranteed ailments with target ailment effect", function()
		build.skillsTab:PasteSocketGroup("Summon Skitterbots 1/0  1\n")
		build.configTab.input.customMods = "Drop Brine Ground while moving, lasting 4 seconds"
		rebuild()

		assert.are.equals(15, build.calcsTab.mainOutput.CurrentShock)

		build.configTab.input.conditionEnemyOnBrineGround = true
		rebuild()

		assert.are.equals(19, build.calcsTab.mainOutput.CurrentShock)
	end)
end)
