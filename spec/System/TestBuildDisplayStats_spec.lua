describe("Build display stats", function()
	local originalCompactValues

	before_each(function()
		originalCompactValues = main.useCompactValues
		newBuild()
	end)

	after_each(function()
		main.useCompactValues = originalCompactValues
	end)

	local function getSidebarLine(label)
		local suffix = label .. ":"
		for _, stat in ipairs(build.controls.statBox.list) do
			if stat[1] and stat[1]:sub(-#suffix) == suffix then
				return stat
			end
		end
	end

	local function getSidebarStat(label)
		local line = getSidebarLine(label)
		return line and line[2]
	end

	it("formats compact values once and preserves normal formatting below the threshold", function()
		main.useCompactValues = true

		assert.are.equals("^712.3K", build:FormatStat({ fmt = ".1f", compactValue = true }, 12345))
		assert.are.equals("^7123", build:FormatStat({ fmt = ".1f", compactValue = true }, 123))
	end)

	it("shows Mercenary sidebar stats", function()
		local mercenaryDisplayStats = LoadModule("Modules/BuildDisplayStats").mercenaryDisplayStats
		build.controls.statBox.list = { }
		build:AddDisplayStatList(mercenaryDisplayStats, {
			mainSkill = { skillFlags = { attack = true, hit = true } },
			output = {
				Speed = 1.5,
				PreEffectiveCritChance = 12.34,
				CritChance = 10,
				CritMultiplier = 2,
				HitChance = 95,
				FireResist = 75,
				FireResistOverCap = 15,
				ColdResist = 75,
				ColdResistOverCap = 20,
				LightningResist = 75,
				LightningResistOverCap = 25,
				ChaosResist = 20,
				ChaosResistOverCap = 5,
				CrabBarriersMax = 0,
				CrabBarriers = 0,
			},
			modDB = { Flag = function() return false end },
		})

		for _, label in ipairs({ "Attack Rate", "Crit Chance", "Effective Crit Chance", "Crit Multiplier", "Hit Chance" }) do
			assert.is_truthy(getSidebarStat(label), label)
		end
		for _, stat in ipairs({
			{ label = "Fire Resistance", overCap = 15 },
			{ label = "Cold Resistance", overCap = 20 },
			{ label = "Lightning Resistance", overCap = 25 },
			{ label = "Chaos Resistance", overCap = 5 },
		}) do
			local value = getSidebarStat(stat.label)
			assert.is_truthy(value, stat.label)
			assert.is_truthy(value:find("(+" .. stat.overCap .. "%)", 1, true), stat.label)
		end
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

	it("only underlines sidebar stats with a visible breakdown", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		runCallback("OnFrame")

		for _, line in ipairs(build.controls.statBox.list) do
			if line.underline and line.underline[2] then
				build:SetDisplayStat({ line = line, x = 0, y = 0, width = 300 }, false)
				assert.is_true(build.controls.breakdown.shown, line[1])
				build:ClearDisplayStat()
			end
		end
	end)

	it("uses aggregate breakdowns for dual-wield attacks", function()
		build.skillsTab:PasteSocketGroup("Cleave 20/0  1")
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nVaal Blade\nQuality: 0\n20% increased Attack Speed")
		build.itemsTab:AddDisplayItem()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nVaal Blade\nQuality: 0")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local actor = build.calcsTab.mainEnv.player
		assert.is_true(actor.mainSkill.skillFlags.bothWeaponAttack)
		assert.matches("Both weapons", table.concat(actor.breakdown.Speed, "\n"), nil, true)
		assert.matches("Both weapons", table.concat(actor.breakdown.PreEffectiveCritChance, "\n"), nil, true)
		assert.matches("Both weapons", table.concat(actor.breakdown.CritChance, "\n"), nil, true)
		assert.not_matches("Crit confirmation roll", table.concat(actor.breakdown.PreEffectiveCritChance, "\n"), nil, true)
		assert.matches("Crit confirmation roll", table.concat(actor.breakdown.CritChance, "\n"), nil, true)
		assert.matches("Both weapons", table.concat(actor.breakdown.HitChance, "\n"), nil, true)

		local critLine = getSidebarLine("Crit Chance")
		local effectiveCritLine = getSidebarLine("Effective Crit Chance")
		assert.are.equal("PreEffectiveCritChance", critLine.breakdown)
		assert.are.equal("CritChance", effectiveCritLine.breakdown)

		local displayData = build:GetSidebarBreakdown(critLine.breakdown, critLine.modNames, critLine.ignoredSections, "player")
		local breakdownCount = 0
		local hasMainHandModifiers = false
		for _, section in ipairs(displayData) do
			breakdownCount = breakdownCount + (section.breakdown and 1 or 0)
			hasMainHandModifiers = hasMainHandModifiers or section.cfg == "weapon1"
		end
		assert.are.equal(1, breakdownCount)
		assert.is_true(hasMainHandModifiers)
	end)

	it("uses off-hand breakdowns for shield attacks", function()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nRusted Sword\nQuality: 0")
		build.itemsTab:AddDisplayItem()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nColossal Tower Shield\nQuality: 0")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Spectral Shield Throw 20/0  1")
		build.configTab.input.enemyEvasion = 10000
		build.configTab:BuildModList()
		runCallback("OnFrame")

		local actor = build.calcsTab.mainEnv.player
		assert.is_falsy(actor.mainSkill.skillFlags.weapon1Attack)
		assert.is_true(actor.mainSkill.skillFlags.weapon2Attack)
		assert.are.equal(actor.breakdown.OffHand.Speed, actor.breakdown.Speed)
		assert.are.equal(actor.breakdown.OffHand.AccuracyHitChance, actor.breakdown.HitChance)
		assert.are.equal(actor.breakdown.OffHand.PreEffectiveCritChance, actor.breakdown.PreEffectiveCritChance)
		assert.are.equal(actor.breakdown.OffHand.CritChance, actor.breakdown.CritChance)

		local critLine = getSidebarLine("Crit Chance")
		local effectiveCritLine = getSidebarLine("Effective Crit Chance")
		assert.are.equal("PreEffectiveCritChance", critLine.breakdown)
		assert.are.equal("OffHand.CritChance", actor.breakdown.PreEffectiveCritChance.breakdownSource)
		assert.are.equal("CritChance", effectiveCritLine.breakdown)

		local displayData = build:GetSidebarBreakdown(critLine.breakdown, critLine.modNames, critLine.ignoredSections, "player")
		local hasModifierSection = false
		for _, section in ipairs(displayData) do
			hasModifierSection = hasModifierSection or section.modName ~= nil
		end
		assert.is_true(hasModifierSection)

		build.configTab.input.enemyBlockChance = 25
		build.configTab:BuildModList()
		runCallback("OnFrame")
		actor = build.calcsTab.mainEnv.player
		assert.are.equal(actor.breakdown.OffHand.HitChance, actor.breakdown.HitChance)
	end)
end)
