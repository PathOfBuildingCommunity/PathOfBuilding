describe("TestFullDPSAutoTotems", function()
	-- Holy Flame Totem is a direct hit-damage totem skill: its FullDPS contribution
	-- comes through `usedEnv.player.output.TotalDPS * activeSkillCount`, which is the
	-- exact code path the opt-in scaling targets. A custom mod raises ActiveTotemLimit
	-- to 2 so a multiplier > 1 is observable.
	local function setupHolyFlameTotemInFullDPS()
		newBuild()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHoly Flame Totem 20/0  1\n")
		runCallback("OnFrame")
		local socketGroup = build.skillsTab.socketGroupList[1]
		socketGroup.includeInFullDPS = true
		build.configTab.input.customMods = "+1 to maximum number of Summoned Totems"
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")
		return socketGroup
	end

	teardown(function()
		-- newBuild() resets state for the next describe block
	end)

	it("does not enable the opt-in option by default", function()
		newBuild()
		assert.is_nil(build.configTab.input.fullDPSAutoMaxTotems)
	end)

	it("Full DPS for a Totem skill uses skill count 1 when the option is off", function()
		setupHolyFlameTotemInFullDPS()
		local mainSkill = build.calcsTab.mainEnv.player.mainSkill
		assert.is_true(mainSkill.skillFlags.totem)
		local baselineFullDPS = build.calcsTab.mainOutput.FullDPS
		assert.is_true(baselineFullDPS ~= nil and baselineFullDPS > 0)
		local skillDPSEntries = build.calcsTab.mainOutput.SkillDPS
		assert.are.equals(1, skillDPSEntries[1].count)
	end)

	it("Full DPS scales by ActiveTotemLimit when the option is on", function()
		setupHolyFlameTotemInFullDPS()
		local baselineFullDPS = build.calcsTab.mainOutput.FullDPS

		build.configTab.input.fullDPSAutoMaxTotems = true
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")

		local totemLimit = build.calcsTab.mainOutput.ActiveTotemLimit
		assert.is_true(totemLimit > 1, "expected ActiveTotemLimit > 1, got " .. tostring(totemLimit))
		-- SkillDPS entry uses the scaled count, which is what comparison tools observe
		assert.are.equals(totemLimit, build.calcsTab.mainOutput.SkillDPS[1].count)
		-- Combined FullDPS strictly grows; an exact ratio is not asserted because some
		-- components (ignite, burning ground) do not scale with totem count.
		assert.is_true(build.calcsTab.mainOutput.FullDPS > baselineFullDPS)
	end)

	it("manual Count > 1 wins over the auto-count option", function()
		local socketGroup = setupHolyFlameTotemInFullDPS()
		local baselineFullDPS = build.calcsTab.mainOutput.FullDPS

		socketGroup.groupCount = 5
		build.configTab.input.fullDPSAutoMaxTotems = true
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")

		local totemLimit = build.calcsTab.mainOutput.ActiveTotemLimit
		assert.is_true(totemLimit ~= 5, "test relies on ActiveTotemLimit being different from 5, got " .. tostring(totemLimit))
		assert.are.equals(5, build.calcsTab.mainOutput.SkillDPS[1].count)
		assert.is_true(build.calcsTab.mainOutput.FullDPS > baselineFullDPS)
	end)

	it("does not auto-scale when multiple Totem skills are included in Full DPS (avoids overcounting the global limit)", function()
		-- Two distinct Totem socket groups both opted into Full DPS, both at Count 1.
		-- ActiveTotemLimit is a global slot pool; applying it to each skill would
		-- multi-count the same totem slots. The implementation must keep each skill
		-- at its manual Count when more than one Totem source is included.
		--
		-- Explosive Arrow Ballista in the same scenario is handled correctly by
		-- construction in `src/Modules/Calcs.lua`: `isIncludedFullDPSTotemSource`
		-- (used by the source counter) does NOT check `explosiveArrowFunc`, so an
		-- EA Ballista source still increments the source count; only
		-- `isFullDPSAutoTotemScalable` (used by the per-skill scaling gate) excludes
		-- it. The two predicates cannot be conflated without editing the helpers
		-- themselves. A spec-level test for the EA Ballista variant would require
		-- additional weapon+support fixture wiring that the existing test harness
		-- does not currently expose.
		newBuild()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHoly Flame Totem 20/0  1\n")
		runCallback("OnFrame")
		build.skillsTab.socketGroupList[1].includeInFullDPS = true

		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nHoly Flame Totem 20/0  1\n")
		runCallback("OnFrame")
		build.skillsTab.socketGroupList[2].includeInFullDPS = true

		build.configTab.input.customMods = "+2 to maximum number of Summoned Totems"
		build.configTab.input.fullDPSAutoMaxTotems = true
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")

		local totemLimit = build.calcsTab.mainOutput.ActiveTotemLimit
		assert.is_true(totemLimit > 1, "expected ActiveTotemLimit > 1, got " .. tostring(totemLimit))

		local totemEntries = 0
		for _, entry in ipairs(build.calcsTab.mainOutput.SkillDPS) do
			if entry.name == "Holy Flame Totem" then
				assert.are.equals(1, entry.count, "Holy Flame Totem entry must stay at count 1 when multiple totem sources are included")
				totemEntries = totemEntries + 1
			end
		end
		assert.are.equals(2, totemEntries, "expected both Holy Flame Totem socket groups in the Full DPS skill list")
	end)

	it("uses the current TotemsSummoned override, not ActiveTotemLimit, when both are set", function()
		-- Raise ActiveTotemLimit to 4 via custom mod, then set the existing TotemsSummoned
		-- config to 2: getSummonedTotemCount reads output.TotemsSummoned first, so it must
		-- land on 2, not 4. This pins the "current count" half of the tooltip contract.
		newBuild()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHoly Flame Totem 20/0  1\n")
		runCallback("OnFrame")
		local socketGroup = build.skillsTab.socketGroupList[1]
		socketGroup.includeInFullDPS = true
		build.configTab.input.customMods = "+3 to maximum number of Summoned Totems"
		build.configTab.input.TotemsSummoned = 2
		build.configTab.input.fullDPSAutoMaxTotems = true
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")

		local totemLimit = build.calcsTab.mainOutput.ActiveTotemLimit
		assert.is_true(totemLimit > 2, "expected ActiveTotemLimit > TotemsSummoned override, got " .. tostring(totemLimit))
		assert.are.equals(2, build.calcsTab.mainOutput.TotemsSummoned)
		assert.are.equals(2, build.calcsTab.mainOutput.SkillDPS[1].count)
	end)
end)
