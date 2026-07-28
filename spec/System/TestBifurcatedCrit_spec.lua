describe("Bifurcated critical strikes", function()
	local function setupBifurcate(socketGroup, bifurcate, lucky, extremeLuck, useDefaultCritMultiplier)
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw([[
				New Item
				Imbued Wand
				Quality: 0
				100% reduced lightning damage
				adds 1 to 1 physical damage to spells
				nearby enemies have 100% less armour
			]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		build.skillsTab:PasteSocketGroup(socketGroup)
		runCallback("OnFrame")

		build.configTab.input.customMods = "+44% to critical hit chance\n"
			.. (bifurcate and "spell critical strike chance bifurcates\n" or "")
			.. (lucky and "your critical strike chance is lucky\n" or "")
			.. (extremeLuck and "your lucky or unlucky effects use the best or worst from three rolls instead of two\n" or "")
			.. (useDefaultCritMultiplier and "" or "your critical strike multiplier is 1000000%\n")
		build.configTab:BuildModList()
		runCallback("OnFrame")

		return build.calcsTab.mainOutput
	end

	it("calculates bifurcated critical hit damage", function()
		local normalOutput = setupBifurcate("Spark 1/0  1")
		assert.are.equals(50, normalOutput.CritChance)
		assert.are.equals(10000, normalOutput.CritMultiplier)
		assert.are.equals(10001, normalOutput.AverageHit)

		local bifurcateOutput = setupBifurcate("Spark 1/0  1", true)
		assert.are.equals(50, bifurcateOutput.PreBifurcateCritChance)
		assert.are.equals(75, bifurcateOutput.CritChance)
		assert.are.near(1 + 1 / 3, bifurcateOutput.CritBifurcates, 10 ^ -9)
		assert.are.equals(20000, bifurcateOutput.AverageHit)
	end)

	it("accounts for guaranteed critical strikes", function()
		local normalOutput = setupBifurcate("Spark 1/0  1", nil, nil, nil, true)
		assert.are.equals(1.5, normalOutput.CritMultiplier)

		local markedOutput = setupBifurcate("Spark 1/0  1\nAssassin's Mark 1/0  1", nil, nil, nil, true)
		assert.are.equals(1.8, markedOutput.CritMultiplier)

		local bifurcateOutput = setupBifurcate("Spark 1/0  1\nAssassin's Mark 1/0  1", true, nil, nil, true)
		assert.are.equals(2.07, floor(bifurcateOutput.CritMultiplier, 2))

		local tendrilsOutput = setupBifurcate("Lightning Tendrils 1/0  1", true)
		assert.are.equals(50, tendrilsOutput.PreBifurcateCritChance)
		assert.are.near(100 / 3 + (200 / 3) * 0.75, tendrilsOutput.CritChance, 10 ^ -6)
		assert.are.equals(1.2, tendrilsOutput.CritBifurcates)

		local eccentricityOutput = setupBifurcate("Lightning Tendrils of Eccentricity 1/0  1", true)
		assert.are.equals(50, eccentricityOutput.PreBifurcateCritChance)
		assert.are.equals(80, eccentricityOutput.CritChance)
		assert.are.equals(1.25, eccentricityOutput.CritBifurcates)
	end)

	it("applies lucky rolls independently", function()
		local luckyOutput = setupBifurcate("Spark 1/0  1", false, true)
		assert.are.equals(75, luckyOutput.CritChance)
		assert.are.equals(10000, luckyOutput.CritMultiplier)
		assert.are.equals(15000.5, luckyOutput.AverageHit)

		local bifurcateOutput = setupBifurcate("Spark 1/0  1", true, true)
		assert.are.equals(75, bifurcateOutput.PreBifurcateCritChance)
		assert.are.equals(93.75, bifurcateOutput.CritChance)
		assert.are.equals(1.6, bifurcateOutput.CritBifurcates)
		assert.are.equals(29999, bifurcateOutput.AverageHit)

		local extremeLuckOutput = setupBifurcate("Spark 1/0  1", true, true, true)
		assert.are.equals(87.5, extremeLuckOutput.PreBifurcateCritChance)
		assert.are.equals(98.4375, extremeLuckOutput.CritChance)
		assert.are.equals(1 + 0.875 ^ 2 / 0.984375, extremeLuckOutput.CritBifurcates)
		assert.are.near(34998.5, extremeLuckOutput.AverageHit, 0.01)
	end)
end)
