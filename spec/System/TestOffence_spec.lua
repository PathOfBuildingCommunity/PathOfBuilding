describe("TestOffence", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	-- Asserts actual is within a relative tolerance of expected, e.g. 0.005 = 0.5%
	local function assertNearRelative(expected, actual, tolerance, msg)
		assert.is_true(math.abs(expected - actual) / expected <= tolerance,
			string.format("%s: expected ~%.2f (within %.1f%%), got %.2f", msg, expected, tolerance * 100, actual))
	end

	it("counts only permanent minions for Communion", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nCommunion 3/0  1")
		build.skillsTab:PasteSocketGroup("Summon Reaper 20/0  1")
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1")
		runCallback("OnFrame")

		local modDB = build.calcsTab.calcsEnv.player.modDB
		assert.is_true(modDB:Sum("BASE", nil, "Multiplier:SummonedMinion") > 1)
		assert.are.equals(1, modDB:Sum("BASE", nil, "Multiplier:PermanentMinion"))
		assert.is_true(build.calcsTab.calcsOutput.PhysicalMin > 0)

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nCommunion 3/0  1")
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1")
		runCallback("OnFrame")

		assert.are.equals(0, build.calcsTab.calcsEnv.player.modDB:Sum("BASE", nil, "Multiplier:PermanentMinion"))
		assert.are.equals(0, build.calcsTab.calcsOutput.PhysicalMin or 0)
	end)

	it("does not apply arrow damage modifiers to Fireball", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		build.configTab.input.customMods = "Projectiles Pierce an additional Target"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		local damageWithoutArrowMod = build.calcsTab.mainOutput.AverageDamage

		build.configTab.input.customMods = [[
		Projectiles Pierce an additional Target
		Arrows deal 50% increased Damage with Hits and Ailments to Targets they Pierce
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(damageWithoutArrowMod, build.calcsTab.mainOutput.AverageDamage)
	end)

	it("parses more/less/increased/reduced minimum and maximum damage of every type", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		25% more Maximum Lightning Damage
		50% less Minimum Lightning Damage
		10% increased Maximum Cold Damage
		12% reduced Minimum Physical Damage
		20% more Maximum Chaos Damage
		30% more Maximum Fire Damage
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local modDB = build.calcsTab.mainEnv.player.modDB

		-- "more"/"less" -> MORE modifier (More() returns the aggregate multiplier)
		assert.are.equals(1.25, modDB:More(nil, "MaxLightningDamage"))
		assert.are.equals(0.5, modDB:More(nil, "MinLightningDamage"))
		assert.are.equals(1.2, modDB:More(nil, "MaxChaosDamage"))
		assert.are.equals(1.3, modDB:More(nil, "MaxFireDamage"))

		-- "increased"/"reduced" -> INC modifier
		assert.are.equals(10, modDB:Sum("INC", nil, "MaxColdDamage"))
		assert.are.equals(-12, modDB:Sum("INC", nil, "MinPhysicalDamage"))

		-- sanity: these must not have leaked into the wrong stat/type
		assert.are.equals(1, modDB:More(nil, "MinChaosDamage"))
		assert.are.equals(0, modDB:Sum("INC", nil, "MaxLightningDamage"))
	end)

	-- calcDamage rounds each min/max to an integer before our multipliers' effects can be
	-- observed, so scaling the rounded baseline can differ from the real value by ~1
	local function assertNear(expected, actual, msg)
		assert.is_true(math.abs(expected - actual) <= 2, string.format("%s: expected ~%.2f, got %.2f", msg, expected, actual))
	end

	it("applies min/max damage mods to an actual skill in CalcOffence", function()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nArc 20/0  1\n")
		runCallback("OnFrame")

		local baseMin = build.calcsTab.calcsOutput.LightningMin
		local baseMax = build.calcsTab.calcsOutput.LightningMax
		assert.is_true(baseMax > 0)
		assert.is_true(baseMin > 0)

		-- MORE path: "more"/"less" scale only the targeted end of the roll
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		25% more Maximum Lightning Damage
		50% less Minimum Lightning Damage
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assertNear(baseMax * 1.25, build.calcsTab.calcsOutput.LightningMax, "25%% more max")
		assertNear(baseMin * 0.5, build.calcsTab.calcsOutput.LightningMin, "50%% less min")

		-- INC path: "increased" stacks multiplicatively with the MORE factors above
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Ring
		40% increased Maximum Lightning Damage
		100% increased Minimum Lightning Damage
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assertNear(baseMax * 1.25 * 1.4, build.calcsTab.calcsOutput.LightningMax, "more + increased max")
		assertNear(baseMin * 0.5 * 2, build.calcsTab.calcsOutput.LightningMin, "less + increased min")
	end)

	it("applies minimum and maximum attack damage mods", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Rusted Sword
		]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Double Strike 20/0  1")
		runCallback("OnFrame")

		local baseMin = build.calcsTab.mainOutput.MainHand.TotalMin
		local baseMax = build.calcsTab.mainOutput.MainHand.TotalMax

		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		50% less Minimum Attack Damage
		100% more Maximum Attack Damage
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assertNear(baseMin * 0.5, build.calcsTab.mainOutput.MainHand.TotalMin, "50%% less attack min")
		assertNear(baseMax * 2, build.calcsTab.mainOutput.MainHand.TotalMax, "100%% more attack max")
	end)

	it("parses universal cannot deal/deal no non-<type> damage for player and minions", function()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nArc 20/0  1\n")
		runCallback("OnFrame")
		assert.is_true(build.calcsTab.calcsOutput.LightningMax > 0)

		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		Cannot deal non-Fire Damage
		Minions deal no non-Fire Damage
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local modDB = build.calcsTab.mainEnv.player.modDB
		assert.truthy(modDB:Flag(nil, "DealNoPhysical"))
		assert.truthy(modDB:Flag(nil, "DealNoLightning"))
		assert.truthy(modDB:Flag(nil, "DealNoCold"))
		assert.truthy(modDB:Flag(nil, "DealNoChaos"))
		assert.is_true(not (modDB:Flag(nil, "DealNoFire")))

		-- minion wording wraps the same flags in MinionModifier
		local minionDealNo = { }
		for _, value in ipairs(modDB:List(nil, "MinionModifier")) do
			if value.mod and value.mod.name:match("^DealNo") then
				minionDealNo[value.mod.name] = true
			end
		end
		assert.truthy(minionDealNo["DealNoPhysical"])
		assert.truthy(minionDealNo["DealNoLightning"])
		assert.truthy(minionDealNo["DealNoCold"])
		assert.truthy(minionDealNo["DealNoChaos"])
		assert.is_true(not (minionDealNo["DealNoFire"]))

		-- Arc is pure lightning, so the player can no longer deal damage with it
		assert.are.equals(0, build.calcsTab.calcsOutput.LightningMax)
	end)

	it("keeps deal no non-elemental damage as its own literal", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		Deal no non-Elemental Damage
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local modDB = build.calcsTab.mainEnv.player.modDB
		assert.truthy(modDB:Flag(nil, "DealNoPhysical"))
		assert.truthy(modDB:Flag(nil, "DealNoChaos"))
		assert.is_true(not (modDB:Flag(nil, "DealNoLightning")))
		assert.is_true(not (modDB:Flag(nil, "DealNoCold")))
		assert.is_true(not (modDB:Flag(nil, "DealNoFire")))
	end)

	it("enemies in your chilling areas take damage increased by the area's chill effect", function()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nVortex 20/0  1\n")
		runCallback("OnFrame")

		local baseAvg = build.calcsTab.mainOutput.AverageDamage
		assert.is_true(baseAvg > 0)
		-- the chill effect currently applied to the enemy (here, from Vortex's chilling area)
		local currentChill = build.calcsTab.mainOutput.CurrentChill
		assert.is_true(currentChill ~= nil and currentChill > 0)

		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		Enemies in your Chilling Areas have Cold Damage taken increased by Chill Effect
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		-- config checkbox not ticked -> enemy is not in the area -> no change
		assert.are.equals(baseAvg, build.calcsTab.mainOutput.AverageDamage)

		build.configTab.input.conditionEnemyInChillingArea = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		-- Vortex deals pure cold damage, so the ColdDamageTaken increase scales all of it
		local scaledAvg = baseAvg * (1 + currentChill / 100)
		assertNearRelative(scaledAvg, build.calcsTab.mainOutput.AverageDamage, 0.005,
			string.format("base %.2f scaled by %d%% current chill", baseAvg, currentChill))

		-- the paired "Chilled by your Hits" wording must not stack with the chilling area one
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Ring
		Enemies Chilled by your Hits have Cold Damage taken increased by Chill Effect
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assertNearRelative(scaledAvg, build.calcsTab.mainOutput.AverageDamage, 0.005,
			string.format("both wordings must apply only once (base %.2f, %d%% chill)", baseAvg, currentChill))
	end)

	-- "Base <ailment> Duration is X seconds" overrides the fixed base duration of the damaging ailments
	for _, case in ipairs({
		{ ailment = "Ignite", skill = "Fireball", chanceMod = "25% chance to Ignite", gameBase = 4 },
		{ ailment = "Bleeding", skill = "Double Strike", chanceMod = "25% chance to cause Bleeding on Hit", gameBase = 5, output = "BleedDuration" },
		{ ailment = "Poison", skill = "Double Strike", chanceMod = "25% chance to Poison on Hit", gameBase = 2 },
	}) do
		it("supports base " .. case.ailment .. " duration override", function()
			local outputName = case.output or (case.ailment .. "Duration")
			build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Rusted Sword
			]])
			build.itemsTab:AddDisplayItem()
			build.skillsTab:PasteSocketGroup("Slot: Body Armour\n" .. case.skill .. " 20/0  1\n")
			build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Coral Amulet
			]] .. case.chanceMod)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")

			assert.are.equals(case.gameBase, build.calcsTab.mainOutput[outputName])

			build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Coral Ring
			Base ]] .. case.ailment .. [[ Duration is 1 second]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")

			assert.are.equals(1, build.calcsTab.mainOutput[outputName])
		end)
	end
end)
