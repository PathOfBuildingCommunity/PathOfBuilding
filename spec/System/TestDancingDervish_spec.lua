describe("TestDancingDervish", function()
	local dancingDervish = [[
		Rarity: UNIQUE
		The Dancing Dervish
		Reaver Sword
		Implicits: 1
		60% increased Global Accuracy Rating
		150% increased Physical Damage
		25% increased Attack Speed
		5% increased Movement Speed
		Triggers Level 15 Manifest Dancing Dervishes on Rampage
		Manifested Dancing Dervishes disables both weapon slots
		Manifested Dancing Dervishes die when Rampage ends
		Melee Hits count as Rampage Kills
		Rampage
	]]

	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function rebuild()
		build.buildFlag = true
		runCallback("OnFrame")
		build.calcsTab:BuildOutput()
		runCallback("OnFrame")
	end

	local function equip(raw, slotName)
		build.itemsTab:CreateDisplayItemFromRaw(raw)
		local item = build.itemsTab.displayItem
		build.itemsTab:AddDisplayItem()
		if slotName then
			build.itemsTab.slots[slotName]:SetSelItemId(item.id)
			build.buildFlag = true
		end
		runCallback("OnFrame")
	end

	local function setCustomMods(mods)
		build.configTab.input.customMods = mods
		build.configTab:BuildModList()
		rebuild()
	end

	local function findManifestGroup()
		for _, group in ipairs(build.skillsTab.socketGroupList) do
			if group.source and group.gemList[1] and group.gemList[1].skillId == "ManifestDancingDervishes" then
				return group
			end
		end
	end

	-- Equips The Dancing Dervish and uses the given skill as the main skill
	-- Returns the socket group of the granted Manifest Dancing Dervishes skill
	local function setup(skill)
		build.skillsTab:PasteSocketGroup(skill)
		runCallback("OnFrame")
		equip(dancingDervish)
		build.mainSocketGroup = 1
		rebuild()
		return findManifestGroup()
	end

	local function setManifested(dervishGroup, manifested)
		dervishGroup.enabled = manifested
		rebuild()
	end

	local function player()
		return build.calcsTab.mainEnv.player
	end

	it("does not apply the weapon's modifiers while the Dancing Dervishes are manifested", function()
		local dervishGroup = setup("Cyclone 20/0 1")
		assert.is_true(player().weaponsDisabled)
		assert.are.equals(0, player().modDB:Sum("INC", nil, "Accuracy"))
		-- Only Onslaught's Movement Speed applies
		assert.are.equals(20, player().modDB:Sum("INC", nil, "MovementSpeed"))

		setManifested(dervishGroup, false)
		assert.is_false(player().weaponsDisabled)
		assert.are.equals(60, player().modDB:Sum("INC", nil, "Accuracy"))
		assert.are.equals(5, player().modDB:Sum("INC", nil, "MovementSpeed"))
	end)

	it("lets the Dancing Dervishes use the weapon while it's disabled for the player", function()
		local dervishGroup = setup("Cyclone 20/0 1")
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			if group == dervishGroup then
				build.mainSocketGroup = index
			end
		end
		rebuild()
		local env = build.calcsTab.mainEnv
		assert.is_true(player().weaponsDisabled)
		assert.are.equals("None", player().weaponData1.type)
		assert.is_nil(player().itemList["Weapon 1"])
		assert.are.equals(player().disabledItemList["Weapon 1"].weaponData[1], env.minion.weaponData1)
		assert.are.equals("Two Handed Sword", env.minion.weaponData1.type)
		assert.is_true(build.calcsTab.mainOutput.Minion.TotalDPS > 0)
	end)

	it("disables skills socketed in the weapon while the Dancing Dervishes are manifested, but not its supports", function()
		local dervishGroup = setup("Cyclone 20/0 1")
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHatred 20/0 1\nMinion Damage 20/0 1")
		-- Frost Blades can't be used unarmed, so the weapon checks would disable it as well
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nFrost Blades 20/0 1")
		rebuild()
		assert.is_true(player().mainSkill.activeEffect.grantedEffect.name == "Cyclone")
		local hatred, frostBlades, dervishes
		for _, activeSkill in ipairs(player().activeSkillList) do
			if activeSkill.activeEffect.grantedEffect.name == "Hatred" then
				hatred = activeSkill
			elseif activeSkill.activeEffect.grantedEffect.name == "Frost Blades" then
				frostBlades = activeSkill
			elseif activeSkill.activeEffect.grantedEffect.id == "ManifestDancingDervishes" then
				dervishes = activeSkill
			end
		end
		assert.is_true(hatred.skillFlags.disable)
		assert.are.equals("This skill is socketed in a disabled weapon", hatred.disableReason)
		assert.is_true(frostBlades.skillFlags.disable)
		assert.are.equals("This skill is socketed in a disabled weapon", frostBlades.disableReason)
		assert.is_nil(player().modDB.conditions["AffectedByHatred"])
		assert.is_falsy(dervishes.skillFlags.disable)
		local supportedByMinionDamage = false
		for _, effect in ipairs(dervishes.effectList) do
			if effect.grantedEffect.name == "Minion Damage" then
				supportedByMinionDamage = true
			end
		end
		assert.is_true(supportedByMinionDamage)

		setManifested(dervishGroup, false)
		assert.is_true(player().modDB.conditions["AffectedByHatred"])
	end)

	it("keeps Rampage while the Dancing Dervishes are manifested", function()
		setup("Cyclone 20/0 1")
		assert.is_true(player().weaponsDisabled)
		assert.is_true(player().modDB:Flag(nil, "Condition:Rampage"))
	end)

	it("makes attacks unarmed while the Dancing Dervishes are manifested", function()
		local dervishGroup = setup("Cyclone 20/0 1")
		local mainSkill = player().mainSkill
		local conditions = player().modDB.conditions
		assert.are.equals("None", player().weaponData1.type)
		assert.is_true(bit.band(mainSkill.weapon1Flags, ModFlag.Unarmed) > 0)
		assert.are.equals(0, bit.band(mainSkill.weapon1Flags, bit.bor(ModFlag.Sword, ModFlag.Weapon)))
		assert.is_true(conditions["Unarmed"])
		assert.is_true(conditions["Unencumbered"])
		assert.is_nil(conditions["UsingSword"])
		assert.is_nil(conditions["UsingTwoHandedWeapon"])
		assert.is_nil(conditions["UsingMeleeWeapon"])

		setManifested(dervishGroup, false)
		mainSkill = player().mainSkill
		conditions = player().modDB.conditions
		assert.are.equals("Two Handed Sword", player().weaponData1.type)
		assert.are.equals(0, bit.band(mainSkill.weapon1Flags, ModFlag.Unarmed))
		assert.is_true(bit.band(mainSkill.weapon1Flags, ModFlag.Sword) > 0)
		assert.is_nil(conditions["Unarmed"])
		assert.is_true(conditions["UsingSword"])
		assert.is_true(conditions["UsingTwoHandedWeapon"])
	end)

	it("dual wields unarmed with Hollow Palm Technique while the Dancing Dervishes are manifested", function()
		local dervishGroup = setup("Cyclone 20/0 1")
		setCustomMods("Hollow Palm Technique")
		assert.are.equals("None", player().weaponData2.type)
		assert.is_true(player().modDB.conditions["DualWielding"])
		assert.is_true(bit.band(player().mainSkill.weapon2Flags, ModFlag.Unarmed) > 0)
		assert.is_not_nil(build.calcsTab.mainOutput.OffHand)

		setManifested(dervishGroup, false)
		assert.is_nil(player().weaponData2.type)
		assert.is_nil(player().modDB.conditions["DualWielding"])
	end)

	it("only applies main hand modifiers to the main hand with Hollow Palm Technique", function()
		setup("Cyclone 20/0 1")
		setCustomMods("Hollow Palm Technique")
		local mainHandHit = build.calcsTab.mainOutput.MainHand.AverageHit
		local offHandHit = build.calcsTab.mainOutput.OffHand.AverageHit
		assert.is_true(offHandHit > 0)

		-- Ambidexterity
		setCustomMods("Hollow Palm Technique\n60% increased Attack Damage with Main Hand while Dual Wielding")
		assert.is_true(build.calcsTab.mainOutput.MainHand.AverageHit > mainHandHit)
		assert.are.equals(offHandHit, build.calcsTab.mainOutput.OffHand.AverageHit)
	end)

	it("lets Hide of the Vendigo attack as though using a Claw while the Dancing Dervishes are manifested", function()
		-- Frost Blades requires a Claw, Dagger or One Handed Sword
		local dervishGroup = setup("Frost Blades 20/0 1")
		assert.is_true(player().mainSkill.skillFlags.disable)

		equip([[
			Rarity: UNIQUE
			Test Subject
			Exquisite Leather
			Can Attack as though using a Claw while main hand is empty
		]])
		rebuild()
		assert.is_true(player().weaponData1.asThoughUsing["Claw"])
		assert.is_falsy(player().mainSkill.skillFlags.disable)
		assert.is_true(bit.band(player().mainSkill.weapon1Flags, ModFlag.Unarmed) > 0)

		-- The main hand isn't empty while the Dancing Dervishes aren't manifested
		setManifested(dervishGroup, false)
		assert.is_nil(player().weaponData1.asThoughUsing)
		assert.is_true(bit.band(player().mainSkill.weapon1Flags, ModFlag.Sword) > 0)
	end)

	it("does not let Battlemage use the disabled weapon's damage", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0 1")
		runCallback("OnFrame")
		setCustomMods("Battlemage")
		local unarmedHit = build.calcsTab.mainOutput.AverageHit

		equip(dancingDervish)
		build.mainSocketGroup = 1
		rebuild()
		assert.is_true(player().weaponsDisabled)
		assert.are.equals(unarmedHit, build.calcsTab.mainOutput.AverageHit)
	end)

	it("does not let Spellblade use the disabled weapon's damage", function()
		build.skillsTab:PasteSocketGroup("Fireball 20/0 1\nSpellblade 20/0 1")
		runCallback("OnFrame")
		rebuild()
		local unarmedHit = build.calcsTab.mainOutput.AverageHit

		equip(dancingDervish)
		build.mainSocketGroup = 1
		rebuild()
		assert.is_true(player().weaponsDisabled)
		assert.are.equals(unarmedHit, build.calcsTab.mainOutput.AverageHit)
	end)

	it("disables the weapon slots as soon as The Dancing Dervish is equipped", function()
		build.skillsTab:PasteSocketGroup("Cyclone 20/0 1")
		runCallback("OnFrame")
		-- The socket group of the granted skill doesn't exist yet when the items are processed
		equip(dancingDervish)
		assert.is_true(player().weaponsDisabled)
		assert.is_nil(player().itemList["Weapon 1"])
		assert.are.equals("None", player().weaponData1.type)
	end)

	it("does not disable a weapon that's compared against The Dancing Dervish", function()
		setup("Cyclone 20/0 1")
		local sword = new("Item"):Item("Rarity: RARE\nTest Sword\nRusted Sword\nImplicits: 0\n10% increased Fire Damage")
		local env = build.calcsTab.calcs.initEnv(build, "CALCULATOR", { repSlotName = "Weapon 1", repItem = sword })
		assert.is_false(env.player.weaponsDisabled)
		assert.are.equals(sword, env.player.itemList["Weapon 1"])
		assert.are.equals(10, env.modDB:Sum("INC", nil, "FireDamage"))
	end)

	it("keeps the requirements of the disabled weapon", function()
		setup("Cyclone 20/0 1")
		assert.is_true(player().weaponsDisabled)
		local weaponRequirement
		for _, requirement in ipairs(build.calcsTab.mainEnv.requirementsTable) do
			if requirement.sourceSlot == "Weapon 1" then
				weaponRequirement = requirement
			end
		end
		assert.are.equals(player().disabledItemList["Weapon 1"], weaponRequirement.sourceItem)
		assert.is_true(weaponRequirement.Str > 0)
	end)

	it("does not let Energy Blade replace the disabled weapons", function()
		local dervishGroup = setup("Cyclone 20/0 1")
		build.skillsTab:PasteSocketGroup("Energy Blade 20/0 1")
		rebuild()
		assert.is_true(player().weaponsDisabled)
		assert.is_nil(player().itemList["Weapon 1"])
		assert.are.equals("None", player().weaponData1.type)
		assert.is_true(bit.band(player().mainSkill.weapon1Flags, ModFlag.Unarmed) > 0)

		setManifested(dervishGroup, false)
		assert.are.equals("Energy Blade Two Handed", player().itemList["Weapon 1"].baseName)
		assert.are.equals(0, bit.band(player().mainSkill.weapon1Flags, ModFlag.Unarmed))
	end)

	it("only disables the weapon slots while The Dancing Dervish is in the active weapon set", function()
		build.skillsTab:PasteSocketGroup("Cyclone 20/0 1")
		runCallback("OnFrame")
		equip([[
			Rarity: RARE
			Test Sword
			Rusted Sword
			Implicits: 0
			10% increased Fire Damage
		]], "Weapon 1")
		equip(dancingDervish, "Weapon 1 Swap")
		build.mainSocketGroup = 1
		rebuild()
		assert.is_false(player().weaponsDisabled)
		assert.are.equals("Test Sword", player().itemList["Weapon 1"].title)
		assert.are.equals(10, player().modDB:Sum("INC", nil, "FireDamage"))
		assert.are.equals(0, player().modDB:Sum("INC", nil, "Accuracy"))

		build.itemsTab.activeItemSet.useSecondWeaponSet = true
		rebuild()
		assert.is_true(player().weaponsDisabled)
		assert.is_nil(player().itemList["Weapon 1"])
		assert.are.equals("The Dancing Dervish", player().disabledItemList["Weapon 1"].title)
		assert.are.equals(0, player().modDB:Sum("INC", nil, "FireDamage"))
		assert.are.equals(0, player().modDB:Sum("INC", nil, "Accuracy"))
	end)
end)
