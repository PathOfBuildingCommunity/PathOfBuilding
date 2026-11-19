describe("TestAttackSpeedFloor", function()
	local function cyclone(mods, skill)
		newBuild()
		if skill then
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: NORMAL\nCorroded Blade")
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
		end
		build.skillsTab:PasteSocketGroup((skill or "Cyclone").." 20/0  1\n")
		build.configTab.input.customMods = mods
		build.configTab:BuildModList()
		runCallback("OnFrame")
		return build.calcsTab.mainOutput
	end

	local ailments = "100% chance to cause Bleeding on Hit\n100% chance to Poison on Hit\n100% chance to Ignite\nAdds 10 to 20 Fire Damage to Attacks\n"

	it("still scales ailments with attack speed above 100% reduced", function()
		local output = cyclone(ailments.."99% reduced Attack Speed")
		assert.is_true(output.Speed > 0)
		assert.is_true(output.BleedDPS > 0)
		assert.is_true(output.TotalPoisonDPS > 0)
		assert.is_true(output.IgniteDPS > 0)
	end)

	for _, reduced in ipairs({ 100, 104, 150 }) do
		it("does not hit or inflict ailments with "..reduced.."% reduced attack speed", function()
			local output = cyclone(ailments..reduced.."% reduced Attack Speed")
			assert.are.equals(0, output.Speed)
			assert.are.equals(0, output.TotalDPS)
			assert.are.equals(0, output.BleedDPS)
			assert.are.equals(0, output.TotalPoisonDPS)
			assert.are.equals(0, output.IgniteDPS)
			assert.are.equals(0, output.CombinedDPS)
		end)
	end

	it("does not ignite with a cooldown attack at 100% reduced attack speed", function()
		local output = cyclone(ailments.."99% reduced Attack Speed", "Vigilant Strike")
		assert.is_not_nil(output.Cooldown)
		assert.is_true(output.BleedDPS > 0)
		assert.is_true(output.IgniteDPS > 0)
		output = cyclone(ailments.."100% reduced Attack Speed", "Vigilant Strike")
		assert.are.equals(0, output.Speed)
		assert.are.equals(0, output.BleedDPS)
		assert.are.equals(0, output.IgniteDPS)
		assert.are.equals(0, output.CombinedDPS)
	end)
end)
