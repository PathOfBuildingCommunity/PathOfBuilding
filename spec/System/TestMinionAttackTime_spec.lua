describe("TestMinionAttackTime", function()
	local replicaMaatasTeaching = [[Replica Maata's Teaching
	Karui Sceptre
	Implicits: 1
	26% increased Elemental Damage
	+(30-40) to Intelligence
	(8-16)% increased Attack Speed
	Minions have (15-30)% increased Movement Speed
	Non-Spectre Minions' Base Attack time is equal to
	the Attack time of your Main Hand Weapon]]

	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function equipReplicaMaatasTeaching()
		build.itemsTab:CreateDisplayItemFromRaw(replicaMaatasTeaching)
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
	end

	it("uses the parent main-hand attack time without changing minion base damage", function()
		build.skillsTab:PasteSocketGroup("Summon Skeletons of Archers 20/0  1")
		runCallback("OnFrame")

		local baseAverageDamage = build.calcsTab.mainOutput.Minion.AverageDamage
		assert.is_true(baseAverageDamage > 0)

		equipReplicaMaatasTeaching()

		local env = build.calcsTab.mainEnv

		assert.are.near(env.player.weaponData1.AttackRate, env.minion.weaponData1.AttackRate, 10 ^ -9)
		assert.are.equals(baseAverageDamage, build.calcsTab.mainOutput.Minion.AverageDamage)
	end)

	it("keeps damage unchanged when minion base damage ignores attack speed", function()
		local minionData = data.minions.RaisedSkeletonArcher
		local originalFlag = minionData.baseDamageIgnoresAttackSpeed
		minionData.baseDamageIgnoresAttackSpeed = true

		build.skillsTab:PasteSocketGroup("Summon Skeletons of Archers 20/0  1")
		runCallback("OnFrame")
		local baseAverageDamage = build.calcsTab.mainOutput.Minion.AverageDamage

		equipReplicaMaatasTeaching()
		local overriddenAverageDamage = build.calcsTab.mainOutput.Minion.AverageDamage
		local minionAttackRate = build.calcsTab.mainEnv.minion.weaponData1.AttackRate
		local parentAttackRate = build.calcsTab.mainEnv.player.weaponData1.AttackRate

		minionData.baseDamageIgnoresAttackSpeed = originalFlag

		assert.are.equals(baseAverageDamage, overriddenAverageDamage)
		assert.are.near(parentAttackRate, minionAttackRate, 10 ^ -9)
	end)

	it("does not change spectre base attack time", function()
		build.spectreList = { "Metadata/Monsters/BloodChieftain/MonkeyChiefBloodEnrage" }
		build.skillsTab:PasteSocketGroup("Raise Spectre 20/0  1")
		runCallback("OnFrame")

		local baseAttackRate = build.calcsTab.mainEnv.minion.weaponData1.AttackRate
		local baseAverageDamage = build.calcsTab.mainOutput.Minion.AverageDamage

		equipReplicaMaatasTeaching()

		assert.are.equals(baseAttackRate, build.calcsTab.mainEnv.minion.weaponData1.AttackRate)
		assert.are.equals(baseAverageDamage, build.calcsTab.mainOutput.Minion.AverageDamage)
	end)
end)
