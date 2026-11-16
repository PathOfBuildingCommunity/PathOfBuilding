describe("TestAttacks", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	it("creates an item and has the correct crit chance", function()
		assert.are.equals(build.calcsTab.mainOutput.CritChance, 0)
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nMaraketh Bow\nCrafted: true\nPrefix: None\nPrefix: None\nPrefix: None\nSuffix: None\nSuffix: None\nSuffix: None\nQuality: 20\nSockets: G-G-G-G-G-G\nLevelReq: 71\nImplicits: 1\n{tags:speed}10% increased Movement Speed")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(build.calcsTab.mainOutput.CritChance, 5.5 * build.calcsTab.mainOutput.HitChance / 100)
	end)

	it("creates an item and has the correct crit multi", function()
		assert.are.equals(1.5, build.calcsTab.mainOutput.CritMultiplier)
		build.itemsTab:CreateDisplayItemFromRaw("New Item\nAssassin Bow\nCrafted: true\nPrefix: None\nPrefix: None\nPrefix: None\nSuffix: None\nSuffix: None\nSuffix: None\nQuality: 20\nSockets: G-G-G-G-G-G\nLevelReq: 62\nImplicits: 1\n{tags:damage,critical}{range:0.5}+(15-25)% to Global Critical Strike Multiplier")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(1.5 + 0.2, build.calcsTab.mainOutput.CritMultiplier)
	end)

	it("correctly converts spell damage per stat to attack damage", function()
		assert.are.equals(0, build.calcsTab.mainEnv.player.modDB:Sum("INC", { flags = ModFlag.Attack }, "Damage"))
		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Amulet
		10% increased attack damage
		10% increased spell damage
		1% increased spell damage per 10 intelligence
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(10, build.calcsTab.mainEnv.player.modDB:Sum("INC", { flags = ModFlag.Attack }, "Damage"))
		-- Scion starts with 20 Intelligence
		assert.are.equals(12, build.calcsTab.mainEnv.player.modDB:Sum("INC", { flags = ModFlag.Spell }, "Damage"))

		build.itemsTab:CreateDisplayItemFromRaw([[
		New Item
		Coral Ring
		increases and reductions to spell damage also apply to attacks
		]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		assert.are.equals(22, build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("INC", { flags = ModFlag.Attack }, "Damage"))

	end)

	-- Hide of the Vendigo: attacking as though using a Claw while the main hand is empty.
	-- The attack stays unarmed, so it uses unarmed modifiers rather than claw modifiers.
	describe("Hide of the Vendigo", function()
		local function equipHide(extraLines)
			build.itemsTab:CreateDisplayItemFromRaw([[
				Rarity: UNIQUE
				Test Subject
				Exquisite Leather
				Can Attack as though using a Claw while main hand is empty
			]] .. (extraLines or ""))
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
		end

		-- Frost Blades requires a Claw, Dagger or One Handed Sword, so it can't be used unarmed on its own
		local function useFrostBlades()
			build.skillsTab:PasteSocketGroup("Frost Blades 20/0 1")
			build.mainSocketGroup = 1
			runCallback("OnFrame")
			build.calcsTab:BuildOutput()
			runCallback("OnFrame")
			return build.calcsTab.mainEnv.player.mainSkill
		end

		it("lets you attack as though using a Claw while the main hand is empty", function()
			equipHide()
			local weaponData1 = build.calcsTab.mainEnv.player.weaponData1
			assert.is_true(weaponData1.asThoughUsing ~= nil and weaponData1.asThoughUsing["Claw"] == true)
		end)

		it("does nothing while a main hand weapon is equipped", function()
			equipHide()
			build.itemsTab:CreateDisplayItemFromRaw([[
				New Item
				Corsair Sword
			]])
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.is_nil(build.calcsTab.mainEnv.player.weaponData1.asThoughUsing)
			local mainSkill = useFrostBlades()
			assert.is_falsy(mainSkill.skillFlags.disable)
			assert.is_true(bit.band(mainSkill.weapon1Flags, ModFlag.Sword) > 0)
		end)

		it("makes Claw skills usable unarmed", function()
			local mainSkill = useFrostBlades()
			assert.is_true(mainSkill.skillFlags.disable)

			newBuild()
			equipHide()
			mainSkill = useFrostBlades()
			assert.is_falsy(mainSkill.skillFlags.disable)
			assert.is_true(build.calcsTab.mainOutput.MainHand.AverageHit > 0)
			-- The attack is still unarmed and does not count as using a Claw
			assert.is_true(bit.band(mainSkill.weapon1Flags, ModFlag.Unarmed) > 0)
			assert.are.equals(0, bit.band(mainSkill.weapon1Flags, ModFlag.Claw))
		end)

		it("does not bypass weapon restrictions of supports", function()
			equipHide()
			-- Close Combat only allows Axes and Swords
			build.skillsTab:PasteSocketGroup("Frost Blades 20/0 1\nClose Combat 20/0 1")
			build.mainSocketGroup = 1
			runCallback("OnFrame")
			build.calcsTab:BuildOutput()
			runCallback("OnFrame")
			assert.is_true(build.calcsTab.mainEnv.player.mainSkill.skillFlags.disable)
		end)

		it("applies unarmed modifiers but not claw modifiers to Claw skills", function()
			equipHide()
			useFrostBlades()
			local baseHit = build.calcsTab.mainOutput.MainHand.AverageHit

			build.configTab.input.customMods = "100% increased Claw Damage"
			build.configTab:BuildModList()
			runCallback("OnFrame")
			build.calcsTab:BuildOutput()
			runCallback("OnFrame")
			assert.are.equals(baseHit, build.calcsTab.mainOutput.MainHand.AverageHit)

			build.configTab.input.customMods = "185 to 285 Added Cold Damage with Unarmed Attacks"
			build.configTab:BuildModList()
			runCallback("OnFrame")
			build.calcsTab:BuildOutput()
			runCallback("OnFrame")
			assert.is_true(build.calcsTab.mainOutput.MainHand.AverageHit > baseHit)
		end)

		it("only applies to the main hand with Hollow Palm Technique", function()
			equipHide()
			build.configTab.input.customMods = "Hollow Palm Technique"
			build.configTab:BuildModList()
			runCallback("OnFrame")
			local player = build.calcsTab.mainEnv.player
			-- Hollow Palm makes the off hand unarmed as well, but the Claw only applies to the main hand
			assert.are.equals("None", player.weaponData2.type)
			assert.is_true(player.weaponData1.asThoughUsing["Claw"])
			assert.is_nil(player.weaponData2.asThoughUsing)
		end)

		it("gains attack speed if you've used a movement skill recently", function()
			equipHide("20% increased Attack Speed if you've used an Attack Movement Skill Recently")
			useFrostBlades()
			local baseSpeed = build.calcsTab.mainOutput.Speed

			build.configTab.input.conditionUsedMovementSkillRecently = true
			build.configTab:BuildModList()
			runCallback("OnFrame")
			build.calcsTab:BuildOutput()
			runCallback("OnFrame")
			assert.are.near(baseSpeed * 1.2, build.calcsTab.mainOutput.Speed, 1e-9)
		end)
	end)
end)