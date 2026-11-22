describe("Animate Guardian gear", function()
	it("applies the equipped Guardian's allied effects while calculating a player skill", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")

		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		local guardianGroup = build.skillsTab.socketGroupList[2]
		guardianGroup.gemList[1].skillMinionItemSet = itemSet.id

		local kingmaker = new("Item"):Item([[Rarity: UNIQUE
Kingmaker
Despot Axe
Implicits: 0
Allies within 3 metres have Culling Strike
Allies within 3 metres have +50% to Critical Strike Multiplier
Allies within 3 metres have +10 Fortification]])
		local crown = new("Item"):Item([[Rarity: UNIQUE
Crown of the Tyrant
Magistrate Crown
Sockets: B
Implicits: 0
Enemies within 6 metres have -10% to all Resistances
You and Allies within 6 metres have 16 to 144 added Lightning Damage per Blue Socket]])
		build.itemsTab:EquipItemInSet(kingmaker, itemSet.id)
		build.itemsTab:EquipItemInSet(crown, itemSet.id)
		runCallback("OnFrame")

		local env = build.calcsTab.mainEnv
		assert.are.equal("Arc", env.player.mainSkill.activeEffect.grantedEffect.name)
		assert.are.equal(2, env.player.output.CritMultiplier)
		assert.are.equal(10, env.player.output.CullPercent)
		assert.are.equal(10, env.player.output.FortificationStacks)
		assert.are.equal(16, env.modDB:Sum("BASE", nil, "LightningMin"))
		assert.are.equal(-10, env.enemyDB:Sum("BASE", nil, "ElementalResist"))

		guardianGroup.enabled = false
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equal(0, build.calcsTab.mainOutput.CullPercent)
		assert.are.equal(0, build.calcsTab.mainEnv.modDB:Sum("BASE", nil, "LightningMin"))
	end)
end)
