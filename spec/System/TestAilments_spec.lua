describe("TestAilments", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function rebuild()
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	for _, verb in ipairs({ "inflict", "apply" }) do
		it("Painseeker removes inherent ailment chance on crit with '" .. verb .. "' wording", function()
			build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nBall Lightning 20/0  1\n")
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: UNIQUE\nPainseeker\nShagreen Gloves\nImplicits: 0\nCritical Strikes do not inherently " .. verb .. " non-Damaging Ailments\nInflict non-Damaging Ailments as though dealing 150% more Damage")
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")

			assert.are.equals(0, build.calcsTab.mainOutput.ShockChanceOnCrit)
			assert.are.equals(0, build.calcsTab.mainOutput.FreezeChanceOnCrit)
			assert.are.equals(100, build.calcsTab.mainOutput.IgniteChanceOnCrit)

			build.configTab.input.customMods = "25% chance to Shock\n25% chance to Freeze"
			rebuild()

			assert.are.equals(25, build.calcsTab.mainOutput.ShockChanceOnCrit)
			assert.are.equals(25, build.calcsTab.mainOutput.FreezeChanceOnCrit)
			assert.are.equals(25, build.calcsTab.mainOutput.ShockChance)
		end)
	end

	it("maximum shock value", function()
		-- Shock Nova
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nShock Nova 4/0  1\n")
		runCallback("OnFrame")
		assert.are.equals(round(50 + 10), build.calcsTab.mainOutput.MaximumShock)

		-- Voltaxic Rift
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nAssassin Bow\n+40% to Maximum Effect of Shock")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(round(50 + 10 + 40), build.calcsTab.mainOutput.MaximumShock)
	end)

	it("bleed is buffed by bleed chance", function()
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nKarui Chopper")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHeavy Strike 1/0  1\n")
		build.configTab.input.customMods = "\z
		attacks have 10% chance to cause bleeding\n\z
		"
		rebuild()
		local badDps = build.calcsTab.mainOutput.BleedDPS

		build.configTab.input.customMods = "\z
		attacks have 100% chance to cause bleeding\n\z
		"
		rebuild()
		local goodDps = build.calcsTab.mainOutput.BleedDPS
		assert.True(goodDps > badDps)
	end)

	it("scales hit ailments with target ailment effect", function()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nShock Nova 20/0  1\n")
		build.configTab.input.customMods = "Drop Brine Ground while moving, lasting 4 seconds"
		rebuild()

		assert.are.equals(1, build.calcsTab.mainOutput.ShockEffectMod)

		build.configTab.input.conditionEnemyOnBrineGround = true
		rebuild()

		assert.are.near(1.3, build.calcsTab.mainOutput.ShockEffectMod, 10 ^ -9)
	end)

	local function setupArcInversion()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
		build.characterLevel = 90
		build.characterLevelAutoMode = false
		build.configTab.input.enemyIsBoss = "Pinnacle"
	end

	local function calcsShock(mode, chance, element, extraMods)
		build.configTab.input.ailmentMode = mode
		local mods = "Adds 50000 to 50000 Lightning Damage to Spells\n100% chance to Shock"
		if chance > 0 then
			mods = mods .. string.format("\nHits have %d%% chance to treat Enemy Monster %s Resistance values as inverted", chance, element)
		end
		build.configTab.input.customMods = mods .. (extraMods or "")
		build.buildFlag = true
		rebuild()
		return build.calcsTab.calcsEnv.player
	end

	local function pinnacleShock(player)
		for _, row in ipairs(player.breakdown.ShockDPS.rowList) do
			if row.thresh:find("(Pinnacle)", 1, true) then
				return row.effect
			end
		end
	end

	it("shows Shock from inverted hits while preserving weighted hit DPS", function()
		setupArcInversion()
		local average = calcsShock("AVERAGE", 50, "Elemental")
		local inverted = calcsShock("INVERTED", 50, "Elemental")
		local certainInversion = calcsShock("AVERAGE", 100, "Elemental")
		assert.are.equal("10%", pinnacleShock(average))
		assert.are.equal("12%", pinnacleShock(certainInversion))
		assert.are.equal(pinnacleShock(certainInversion), pinnacleShock(inverted))
		assert.are.equal(average.output.LightningHitAverage, inverted.output.LightningHitAverage)
		assert.are.equal(average.output.TotalDPS, inverted.output.TotalDPS)
		assert.matches("Inverted Hits", inverted.breakdown.ShockEffectMod[1], 1, true)

		calcsShock("INVERTED", 50, "Elemental")
		loadBuildFromXML(build:SaveDB("code"))
		assert.are.equal("INVERTED", build.configTab.input.ailmentMode)
		assert.are.equal("12%", pinnacleShock(build.calcsTab.calcsEnv.player))
	end)

	it("uses ordinary ailment damage for types without inversion and in Crits Only mode", function()
		setupArcInversion()
		local withoutInversion = calcsShock("AVERAGE", 0, "Elemental")
		local coldOnly = calcsShock("INVERTED", 50, "Cold")
		assert.are.equal(pinnacleShock(withoutInversion), pinnacleShock(coldOnly))
		assert.matches("Average Damage", coldOnly.breakdown.ShockEffectMod[1], 1, true)
		local crits = calcsShock("CRIT", 50, "Lightning")
		assert.are.equal(0, crits.output.ShockChanceOnHit)
		assert.matches("Crits Only", crits.breakdown.ShockEffectMod[1], 1, true)
	end)

	it("uses penetration after element-specific inversion and reports immunity at the hit cap", function()
		setupArcInversion()
		local penetration = "\nDamage Penetrates 20% of Enemy Lightning Resistance"
		local inverted = calcsShock("INVERTED", 50, "Lightning", penetration)
		local certainInversion = calcsShock("AVERAGE", 100, "Lightning", penetration)
		assert.are.equal(pinnacleShock(certainInversion), pinnacleShock(inverted))
		build.configTab.input.enemyLightningResist = -150
		local capped = calcsShock("INVERTED", 50, "Lightning")
		assert.is_true(capped.output.LightningHitAverage > 0)
		assert.are.equal("Inverted hits deal no damage that can inflict Shock.", capped.breakdown.ShockDPS[1])
	end)

	it("shows the Freeze threshold of an inverted hit", function()
		build.skillsTab:PasteSocketGroup("Freezing Pulse 20/0  1\n")
		build.configTab.input.enemyIsBoss = "Pinnacle"
		local function freezeThreshold(mode, chance)
			build.configTab.input.ailmentMode = mode
			build.configTab.input.customMods = string.format("100%% chance to Freeze\nHits have %d%% chance to treat Enemy Monster Cold Resistance values as inverted", chance)
			build.buildFlag = true
			rebuild()
			for _, line in ipairs(build.calcsTab.calcsEnv.player.breakdown.FreezeDPS) do
				local threshold = line:match("no more than (%d+) Ailment Threshold")
				if threshold then return tonumber(threshold) end
			end
		end
		local average = freezeThreshold("AVERAGE", 50)
		local inverted = freezeThreshold("INVERTED", 50)
		assert.is_true(inverted > average)
		assert.are.equal(freezeThreshold("AVERAGE", 100), inverted)
	end)

	it("scales minion ailment duration with Barnacles", function()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSummon Ice Golem 20/0  1\n")
		build.configTab.input.customMods = "Inflict Barnacles on nearby Enemies every second\nMinions gain 100% of Physical Damage as Extra Cold Damage"
		rebuild()
		local baseFreezeDurationMod = build.calcsTab.mainEnv.minion.output.FreezeDurationMod
		local baseChillDuration = build.calcsTab.mainEnv.minion.output.ChillDuration

		build.configTab.input.multiplierBarnacleStacks = 10
		rebuild()

		assert.are.near(baseChillDuration * 1.5, build.calcsTab.mainEnv.minion.output.ChillDuration, 10 ^ -9)
		assert.are.near(baseFreezeDurationMod * 1.5, build.calcsTab.mainEnv.minion.output.FreezeDurationMod, 10 ^ -9)
		assert.are.equals(50, build.calcsTab.mainEnv.enemyDB:Sum("BASE", nil, "PhysicalDamageConvertToCold"))
	end)

	it("scales chilling area duration with Barnacles", function()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nCold Snap 20/0  1\n")
		build.configTab.input.customMods = "Inflict Barnacles on nearby Enemies every second"
		rebuild()

		assert.are.equals(1, build.calcsTab.mainOutput.ChillDurationMod)

		build.configTab.input.multiplierBarnacleStacks = 10
		rebuild()

		assert.are.equals(1.5, build.calcsTab.mainOutput.ChillDurationMod)
	end)

	it("scales guaranteed ailments with target ailment effect", function()
		build.skillsTab:PasteSocketGroup("Summon Skitterbots 1/0  1\n")
		build.configTab.input.customMods = "Drop Brine Ground while moving, lasting 4 seconds"
		rebuild()

		assert.are.equals(15, build.calcsTab.mainOutput.CurrentShock)

		build.configTab.input.conditionEnemyOnBrineGround = true
		rebuild()

		assert.are.equals(19, build.calcsTab.mainOutput.CurrentShock)
	end)
end)
