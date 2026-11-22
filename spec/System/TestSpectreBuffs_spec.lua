describe("TestSpectreBuffs", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	it("applies buff skills from every spectre in the spectre list", function()
		build.spectreList = {
			"Metadata/Monsters/LeagueAzmeri/SpecialCorpses/DemonBossHigh", -- Perfect Blood Demon
			"Metadata/Monsters/LeagueAzmeri/SpecialCorpses/TigerHigh", -- Perfect Forest Tiger (Haste)
			"Metadata/Monsters/LeagueAzmeri/SpecialCorpses/TurtleHigh", -- Perfect Guardian Turtle (Determination)
		}
		build.skillsTab:PasteSocketGroup("Raise Spectre 20/0  1")
		build.calcsTab:BuildOutput()

		local env = build.calcsTab.mainEnv
		-- The main minion is the Blood Demon, so the Tiger's and Turtle's auras only apply if
		-- the other spectres in the list are processed as well
		assert.is_true(env.modDB.conditions["AffectedByHaste"] == true)
		assert.is_true(env.modDB.conditions["AffectedByDetermination"] == true)
		assert.is_true(env.minion.modDB.conditions["AffectedByHaste"] == true)
		assert.is_true(env.minion.modDB.conditions["AffectedByDetermination"] == true)
		-- The Tiger and Turtle are beasts, so the condition applies even with the Demon selected
		assert.is_true(env.modDB.conditions["HaveBeastSpectre"] == true)
	end)

	it("applies buff skills from the selected spectre only once", function()
		build.spectreList = {
			"Metadata/Monsters/LeagueAzmeri/SpecialCorpses/TurtleHigh", -- Perfect Guardian Turtle (Determination)
		}
		build.skillsTab:PasteSocketGroup("Raise Spectre 20/0  1")
		build.calcsTab:BuildOutput()

		local env = build.calcsTab.mainEnv
		assert.is_true(env.modDB.conditions["AffectedByDetermination"] == true)
	end)
end)
