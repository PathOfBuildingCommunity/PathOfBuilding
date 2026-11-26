describe("TestExposure", function()
	before_each(function()
		newBuild()
	end)

	local function calcsDebuffs()
		build.configTab:BuildModList()
		runCallback("OnFrame")
		build.calcsTab:BuildOutput()
		local env = build.calcsTab.calcsEnv
		local resist = { }
		for _, entry in ipairs(env.player.breakdown.SkillDebuffs.modList) do
			resist[entry.mod.name] = (resist[entry.mod.name] or 0) + entry.value
		end
		return env.player.output.CurseList, resist
	end

	it("lists exposure from the config in Curses and Debuffs", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
		build.configTab.input.customMods = "20% chance to inflict Lightning Exposure on Hit"
		build.configTab.input.conditionEnemyLightningExposure = true
		local curseList, resist = calcsDebuffs()
		assert.is_truthy(curseList:find("Lightning Exposure", 1, true))
		assert.are.equals(-10, resist.LightningResist)
	end)

	it("lists the exposure value after extra exposure", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
		build.configTab.input.customMods = "20% chance to inflict Lightning Exposure on Hit\nExposure you inflict applies an extra -5% to the affected Resistance"
		build.configTab.input.conditionEnemyLightningExposure = true
		local curseList, resist = calcsDebuffs()
		assert.is_truthy(curseList:find("Lightning Exposure", 1, true))
		assert.are.equals(-15, resist.LightningResist)
	end)

	it("does not list config exposure when it is not applied", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
		build.configTab.input.customMods = "20% chance to inflict Lightning Exposure on Hit"
		local curseList = calcsDebuffs()
		assert.is_nil(curseList:find("Exposure", 1, true))
	end)

	it("does not repeat exposure already listed under its debuff skill", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Wave of Conviction 20/0  1\n")
		build.configTab.input.waveOfConvictionExposureType = "Lightning"
		build.configTab.input.customMods = "20% chance to inflict Lightning Exposure on Hit"
		build.configTab.input.conditionEnemyLightningExposure = true
		local curseList = calcsDebuffs()
		local _, count = curseList:gsub("Lightning Exposure", "")
		assert.are.equals(1, count)
		assert.is_not_nil(build.calcsTab.calcsEnv.debuffs["Lightning Exposure"])
	end)
end)
