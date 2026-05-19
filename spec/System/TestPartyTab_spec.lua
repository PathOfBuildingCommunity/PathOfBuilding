describe("PartyTab", function()
	before_each(function()
		newBuild()
	end)

	it("parses decimal tagged party member stats without treating the value as a nested key", function()
		local partyTab = build.partyTab

		local ok, err = pcall(function()
			partyTab:ParseBuffs(
				partyTab.actor["modDB"],
				"MovementSpeedMod|percent|max=129.6",
				"PartyMemberStats",
				partyTab.actor["output"]
			)
		end)

		assert.True(ok, err)
		assert.True(math.abs(1.296 - partyTab.actor["output"].MovementSpeedMod) < 0.000001)
	end)

	it("preserves existing nested party member stats when parsing another stat for the same output table", function()
		local partyTab = build.partyTab

		partyTab:ParseBuffs(
			partyTab.actor["modDB"],
			"MainHand.CritChance=4.5\nMainHand.Speed=1.2",
			"PartyMemberStats",
			partyTab.actor["output"]
		)

		assert.are.equals(4.5, partyTab.actor["output"].MainHand.CritChance)
		assert.are.equals(1.2, partyTab.actor["output"].MainHand.Speed)
	end)
end)
