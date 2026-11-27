describe("TestGrimFate", function()
	before_each(function()
		newBuild()
	end)

	local function enemyDamage(preset, arkhon)
		build.configTab.input.presetBossSkills = preset
		build.configTab.input.grimFateArkhon = arkhon
		build.configTab:BuildModList()
		runCallback("OnFrame")
		local output = build.calcsTab.mainOutput
		return {
			Physical = output.PhysicalEnemyDamage,
			Fire = output.FireEnemyDamage,
			Cold = output.ColdEnemyDamage,
			Lightning = output.LightningEnemyDamage,
		}
	end

	it("adds The Arkhon's 80% Physical as extra elemental damage to Shaper Slam", function()
		local base = enemyDamage("Shaper Slam", "NONE")
		assert.is_true(base.Physical > 0)
		assert.are.equal(0, base.Fire)

		local average = enemyDamage("Shaper Slam", "AVERAGE")
		assert.are.equal(base.Physical, average.Physical)
		for _, element in ipairs({ "Fire", "Cold", "Lightning" }) do
			assert.is_true(average[element] > 0, element)
		end

		local fire = enemyDamage("Shaper Slam", "FIRE")
		assert.near(average.Fire * 3, fire.Fire, 0.01)
		assert.are.equal(0, fire.Cold)
		assert.are.equal(0, fire.Lightning)
	end)

	it("doesn't change other boss skills", function()
		local base = enemyDamage("Sirus Meteor", "NONE")
		local withFate = enemyDamage("Sirus Meteor", "FIRE")
		for _, damageType in ipairs({ "Physical", "Fire", "Cold", "Lightning" }) do
			assert.are.equal(base[damageType], withFate[damageType], damageType)
		end
	end)
end)
