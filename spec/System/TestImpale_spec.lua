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
	
    it("basic impale stats", function()
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
		assert.are.equals(0, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
		assert.are.equals(200, build.calcsTab.mainOutput.MainHand.impaleStoredHitAvg)
		assert.are.equals(200, build.calcsTab.mainOutput.ImpaleHit)
		
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
        runCallback("OnFrame")
		
		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
    end)
	
	it("basic impale stats", function()
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
		assert.are.equals(400, build.calcsTab.mainOutput.ImpaleHit)
		
		build.configTab.input.customMods = "\z
		+100% critical strike chance\n\z
		Impale Damage dealt to Enemies Impaled by you Overwhelms 100% Physical Damage Reduction\n\z
		Overwhelm 100% physical damage reduction\n\z
		"
		build.configTab:BuildModList()
        runCallback("OnFrame")
		
		assert.are.equals(300, build.calcsTab.mainOutput.MainHand.PhysicalCritAverage)
    end)
end)