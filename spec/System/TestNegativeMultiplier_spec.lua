describe("TestNegativeMultiplier", function()
	local function skill(gems, mods)
		newBuild()
		build.skillsTab:PasteSocketGroup(gems)
		build.configTab.input.customMods = mods
		build.configTab:BuildModList()
		runCallback("OnFrame")
		return build.calcsTab.mainOutput
	end

	local function fireball(mods)
		return skill("Fireball 20/0  1\n", mods)
	end

	it("still deals damage below 100% less", function()
		local output = fireball("90% less Damage")
		assert.is_true(output.TotalDPS > 0)
	end)

	it("does not deal negative damage with more than 100% less damage (issue #4996)", function()
		local output = fireball("150% less Damage")
		assert.are.equals(0, output.TotalDPS)
	end)

	it("does not deal negative damage with more than 100% reduced damage", function()
		local output = fireball("150% reduced Damage")
		assert.are.equals(0, output.TotalDPS)
	end)

	it("two less multipliers above 100% do not cancel out into positive damage", function()
		local output = fireball("150% less Damage\n150% less Damage")
		assert.are.equals(0, output.TotalDPS)
	end)

	it("does not deal negative skill damage over time with more than 100% reduced damage", function()
		local output = skill("Righteous Fire 20/0  1\n", "")
		assert.is_true(output.TotalDot > 0)
		output = skill("Righteous Fire 20/0  1\n", "150% reduced Damage")
		assert.are.equals(0, output.TotalDot)
	end)

	it("does not make enemy damage negative with more than 100% less enemy damage (issue #4996)", function()
		local output = fireball("Nearby Enemies deal 150% less Damage")
		assert.is_true(output.PhysicalEnemyDamageMult >= 0)
	end)
end)
