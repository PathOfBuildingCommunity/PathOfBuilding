describe("Build display stats", function()
	local originalCompactValues

	before_each(function()
		originalCompactValues = main.useCompactValues
		newBuild()
	end)

	after_each(function()
		main.useCompactValues = originalCompactValues
	end)

	local function getSidebarStat(label)
		for _, stat in ipairs(build.controls.statBox.list) do
			if stat[1] and stat[1]:find(label .. ":", 1, true) then
				return stat[2]
			end
		end
	end

	it("formats compact values once and preserves normal formatting below the threshold", function()
		main.useCompactValues = true

		assert.are.equals("^712.3K", build:FormatStat({ fmt = ".1f", compactValue = true }, 12345))
		assert.are.equals("^7123", build:FormatStat({ fmt = ".1f", compactValue = true }, 123))
	end)

	it("shows guard suffixes for EHP and max hit values", function()
		build.skillsTab:PasteSocketGroup("Steelskin 20/0  1")
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.GuardSkillActive)
		assert.matches("%(Guard%)$", getSidebarStat("Effective Hit Pool"))
		assert.matches("%(Guard%)$", getSidebarStat("Phys Max Hit"))
		assert.matches("%(Guard%)$", getSidebarStat("Elemental Max Hit"))
		assert.matches("%(Guard%)$", getSidebarStat("Chaos Max Hit"))
	end)

	it("shows immunity instead of guard for an immune max hit", function()
		build.skillsTab:PasteSocketGroup("Steelskin 20/0  1")
		build.configTab.input.customMods = "Chaos Inoculation"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(math.huge, build.calcsTab.mainOutput.ChaosMaximumHitTaken)
		assert.matches("%(Immune%)$", getSidebarStat("Chaos Resistance"))
		assert.matches("%(Immune%)$", getSidebarStat("Chaos Max Hit"))
	end)
end)
