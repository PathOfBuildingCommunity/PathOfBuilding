describe("TestAttacks", function()
	before_each(function()
		newBuild()
		-- exactly 200 damage
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nVaal Greatsword\nQuality: 0\nAdds 132 to 58 physical damage\n150% chance to Impale Enemies on Hit with Attacks")
		build.itemsTab:AddDisplayItem()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nPaua Amulet\nYour hits can't be evaded\n-20 strength\n")
		build.itemsTab:AddDisplayItem()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	it("basic impale", function()
		-- 0% crit
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(100, build.calcsTab.mainOutput.MainHand.ImpaleChance)
		assert.are.equals(100, build.calcsTab.mainOutput.MainHand.ImpaleChanceOnCrit)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.equals(100*1.3, build.calcsTab.mainOutput.ImpaleDPS) -- 5 impales * 10% stored damage * 1.3 attacks per second

		-- 50% crit
		build.configTab.input.customMods = "\z
		+45% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(250, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(250, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.equals(125*1.3, build.calcsTab.mainOutput.ImpaleDPS) -- 5 impales * 10% stored damage * 1.3 attacks per second

		-- 100% crit
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(300, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.equals(150*1.3, build.calcsTab.mainOutput.ImpaleDPS) -- 5 impales * 10% stored damage * 1.3 attacks per second
	end)

	it("impale with inc damage taken", function()
		-- 0% crit
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		Nearby enemies take 100% increased physical damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(400, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.equals(200*1.3, build.calcsTab.mainOutput.ImpaleDPS) -- 5 impales * 10% stored damage * 1.3 attacks per second

		-- 50% crit
		build.configTab.input.customMods = "\z
		+45% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		Nearby enemies take 100% increased physical damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(400, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(600, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(250, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(250, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.equals(250*1.3, build.calcsTab.mainOutput.ImpaleDPS) -- 5 impales * 10% stored damage * 1.3 attacks per second

		-- 100% crit
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		Nearby enemies take 100% increased physical damage\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(400, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(600, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(300, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.equals(300*1.3, build.calcsTab.mainOutput.ImpaleDPS) -- 5 impales * 10% stored damage * 1.3 attacks per second
	end)

	it("impale with physical reduction", function()
		-- 0% crit
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		"
		build.configTab.input.enemyPhysicalReduction = 10
		build.configTab.input.enemyArmour = 1000 -- 50% dr for 200 damage, 66.6% dr for 100 dmg (impale stacks)
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- dam * (1 - (armourDR + additionalDR)
		assert.are.equals(200 * (1 - (0.5 + 0.1)), build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		-- [5 impales * 10% stored damage] * 1.3 attacks * (armour mod - phys DR)
		assert.are.near(100 * 1.3 * (1 - (2/3 + 0.1)), build.calcsTab.mainOutput.ImpaleDPS, 0.0000001) -- floating point math


		-- 100% crit
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		"
		build.configTab.input.enemyPhysicalReduction = 10
		build.configTab.input.enemyArmour = 1500 -- 50% dr for 300 damage, 66.6% dr for 150 dmg (impale stacks)
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- dam * (1 - (armourDR + additionalDR)
		assert.are.equals(300 * (1 - (0.5 + 0.1)), build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(300, build.calcsTab.mainOutput.ImpaleHit)
		-- [5 impales * 10% stored damage] * 1.3 attacks * (armour mod - phys DR)
		assert.are.near(150 * 1.3 * (1 - (2/3 + 0.1)), build.calcsTab.mainOutput.ImpaleDPS, 0.0000001) -- floating point math

	end)

	it("impale with physical reduction and inc damage taken", function()
		-- 0% crit
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		Nearby enemies take 100% increased physical damage\n\z
		"
		build.configTab.input.enemyPhysicalReduction = 10
		build.configTab.input.enemyArmour = 1000 -- 50% dr for 200 damage, 66.6% dr for 100 dmg (impale stacks) .. damage taken is after armour
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- taken * dam * (1 - (armourDR + additionalDR)
		assert.are.equals(2 * 200 * (1 - (0.5 + 0.1)), build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		-- taken * [5 impales * 10% stored damage] * 1.3 attacks * (armour mod - phys DR)
		assert.are.near(2 * 100 * 1.3 * (1 - (2/3 + 0.1)), build.calcsTab.mainOutput.ImpaleDPS, 0.0000001) -- floating point math


		-- 100% crit
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		Nearby enemies take 100% increased physical damage\n\z
		"
		build.configTab.input.enemyPhysicalReduction = 10
		build.configTab.input.enemyArmour = 1500 -- 50% dr for 300 damage, 66.6% dr for 150 dmg (impale stacks)
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- taken * dam * (1 - (armourDR + additionalDR)
		assert.are.equals(2 * 300 * (1 - (0.5 + 0.1)), build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(300, build.calcsTab.mainOutput.ImpaleHit)
		-- taken * [5 impales * 10% stored damage] * 1.3 attacks * (armour mod - phys DR)
		assert.are.near(2 * 150 * 1.3 * (1 - (2/3 + 0.1)), build.calcsTab.mainOutput.ImpaleDPS, 0.0000001) -- floating point math

	end)

	it("impale dual wield", function()
		newBuild()
		-- exactly 100
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nVaal Blade\nQuality: 0\nAdds 54 to 14 physical damage\n150% chance to Impale Enemies on Hit with Attacks")
		build.itemsTab:AddDisplayItem()
		-- exactly 200 offhand
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nVaal Blade\nQuality: 0\nAdds 54 to 14 physical damage\n100% increased Physical Damage\n150% chance to Impale Enemies on Hit with Attacks")
		build.itemsTab:AddDisplayItem()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nPaua Amulet\nYour hits can't be evaded\n-20 strength\n")
		build.itemsTab:AddDisplayItem()


		-- 0% crit
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(100, build.calcsTab.mainOutput.MainHand.ImpaleChance)
		assert.are.equals(100, build.calcsTab.mainOutput.OffHand.ImpaleChance)
		assert.are.equals(100, build.calcsTab.mainOutput.MainHand.ImpaleChanceOnCrit)
		assert.are.equals(100, build.calcsTab.mainOutput.OffHand.ImpaleChanceOnCrit)

		assert.are.equals(100, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.OffHand.PhysicalHitAverage)
		assert.are.equals(100, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.OffHand.impaleStoredHitAvg)

		assert.are.equals(150, build.calcsTab.mainOutput.ImpaleHit)
		-- 5 impales * 10% stored damage * 1.3 attacks per second * 1.1 dual wield modifier
		assert.are.near(75*1.3*1.1, build.calcsTab.mainOutput.ImpaleDPS, 0.0000001)


		-- 50% crit
		build.configTab.input.customMods = "\z
		+45% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(125, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(250, build.calcsTab.mainOutput.OffHand.impaleStoredHitAvg)

		assert.are.equals(187.5, build.calcsTab.mainOutput.ImpaleHit)
		-- 5 impales * 10% stored damage * 1.3 attacks per second * 1.1 dual wield modifier
		assert.are.near(187.5/2*1.3*1.1, build.calcsTab.mainOutput.ImpaleDPS, 0.0000001)


		-- 50% crit
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(150, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(300, build.calcsTab.mainOutput.OffHand.impaleStoredHitAvg)

		assert.are.equals(225, build.calcsTab.mainOutput.ImpaleHit)
		-- 5 impales * 10% stored damage * 1.3 attacks per second * 1.1 dual wield modifier
		assert.are.near(225/2*1.3*1.1, build.calcsTab.mainOutput.ImpaleDPS, 0.0000001)

	end)

	it("impale with extra mods", function()
		-- inc effect
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		50% increased Impale Effect\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.near(100*1.3*1.5, build.calcsTab.mainOutput.ImpaleDPS, 0.00000001) -- 5 impales * 10% stored damage * 1.3 attacks per second * 1.5 impale effect

		-- last 1 extra hit
		build.configTab.input.customMods = "\z
		never deal critical strikes\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		Impales you inflict last 1 additional Hit\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.PhysicalHitAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		assert.are.near(120*1.3, build.calcsTab.mainOutput.ImpaleDPS, 0.0000001) -- 6 impales * 10% stored damage * 1.3 attacks per second
	end)

end)
