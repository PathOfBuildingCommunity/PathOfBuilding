describe("Vaal Caress Onslaught", function()
	for _, duration in ipairs({ 5, 10, 20 }) do
		it("activates the " .. duration .. "-second modifier after recent Vaal skill use", function()
			newBuild()
			build.skillsTab:PasteSocketGroup("Fireball 1/0  1\n")
			build.mainSocketGroup = 1
			runCallback("OnFrame")
			assert.are.equal("Fireball", build.calcsTab.mainEnv.player.mainSkill.activeEffect.grantedEffect.name)
			local inactiveSpeed = build.calcsTab.mainOutput.Speed
			local inactiveMovement = build.calcsTab.mainOutput.MovementSpeedMod
			build.configTab.input.customMods = "You gain Onslaught for " .. duration .. " seconds on using a Vaal Skill"

			local function check(input, multiplier)
				build.configTab.input.conditionUsedVaalSkillRecently = input.conditionUsedVaalSkillRecently
				build.configTab.input.buffOnslaught = input.buffOnslaught
				build.configTab:BuildModList()
				runCallback("OnFrame")
				assert.are.near(inactiveSpeed * multiplier, build.calcsTab.mainOutput.Speed, 1e-9)
				assert.are.near(inactiveMovement + multiplier - 1, build.calcsTab.mainOutput.MovementSpeedMod, 1e-9)
			end

			check({}, 1)
			check({ conditionUsedVaalSkillRecently = true }, 1.2)
			check({ conditionUsedVaalSkillRecently = true, buffOnslaught = true }, 1.2)
			check({ buffOnslaught = true }, 1.2)
			check({}, 1)
		end)
	end
end)
