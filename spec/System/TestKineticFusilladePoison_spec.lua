describe("Kinetic Fusillade poison damage", function()
	local poisonMods = "Adds 1000 to 1000 Fire Damage to Attacks\n100% chance to Poison on Hit\nAll Damage from Hits can Poison"

	local function recalculate()
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
	end

	local function setupBuild(skillName)
		newBuild()
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
		build.skillsTab:PasteSocketGroup((skillName or "Kinetic Fusillade") .. " 20/20  1\nGreater Multiple Projectiles 20/0  1\n")
		build.configTab.input.customMods = poisonMods
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	it("applies sequential projectile damage to poison", function()
		setupBuild()

		local socketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = socketGroup.displaySkillList[socketGroup.mainActiveSkill].activeEffect.srcInstance
		local allProjectilesPoisonDPS = build.calcsTab.mainOutput.MainHand.PoisonDPS
		assert.are.equals(5, build.calcsTab.mainOutput.ProjectileCount)
		assert.are.equals(24, build.calcsTab.mainOutput.KineticFusilladeAvgMoreMult)

		srcInstance.skillPart = 2
		recalculate()
		local oneProjectilePoisonDPS = build.calcsTab.mainOutput.MainHand.PoisonDPS

		assert.are.near(1.24, allProjectilesPoisonDPS / oneProjectilePoisonDPS, 0.001)
	end)

	it("applies sequential projectile damage to poison with Detonation", function()
		setupBuild("Kinetic Fusillade of Detonation")

		local socketGroup = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local srcInstance = socketGroup.displaySkillList[socketGroup.mainActiveSkill].activeEffect.srcInstance
		local allProjectilesPoisonDPS = build.calcsTab.mainOutput.MainHand.PoisonDPS
		assert.are.equals(8, build.calcsTab.mainOutput.ProjectileCount)
		assert.are.equals(56, build.calcsTab.mainOutput.KineticFusilladeAvgMoreMult)

		srcInstance.skillPart = 2
		recalculate()
		local oneProjectilePoisonDPS = build.calcsTab.mainOutput.MainHand.PoisonDPS

		assert.are.near(1.56, allProjectilesPoisonDPS / oneProjectilePoisonDPS, 0.001)
	end)

	it("does not apply generic projectile damage to poison", function()
		setupBuild()
		local poisonDPS = build.calcsTab.mainOutput.MainHand.PoisonDPS
		local averageHit = build.calcsTab.mainOutput.MainHand.AverageHit

		build.configTab.input.customMods = poisonMods .. "\n100% increased Projectile Damage"
		build.configTab:BuildModList()
		recalculate()

		assert.are.equals(poisonDPS, build.calcsTab.mainOutput.MainHand.PoisonDPS)
		assert.is_true(averageHit < build.calcsTab.mainOutput.MainHand.AverageHit)
	end)
end)
