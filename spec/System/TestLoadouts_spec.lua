describe("TestLoadouts", function()
	before_each(function()
		newBuild()

		build.itemsTab:CreateDisplayItemFromRaw([[Dialla's Malefaction
		Sage's Robe
		Energy Shield: 95
		EnergyShieldBasePercentile: 0
		Variant: Pre 3.19.0
		Variant: Current
		Selected Variant: 2
		Sage's Robe
		Quality: 20
		Sockets: R-G-B-B-B-B
		LevelReq: 37
		Implicits: 0
		Gems can be Socketed in this Item ignoring Socket Colour
		{variant:1}Gems Socketed in Red Sockets have +1 to Level
		{variant:2}Gems Socketed in Red Sockets have +2 to Level
		{variant:1}Gems Socketed in Green Sockets have +10% to Quality
		{variant:2}Gems Socketed in Green Sockets have +30% to Quality
		{variant:1}Gems Socketed in Blue Sockets gain 25% increased Experience
		{variant:2}Gems Socketed in Blue Sockets gain 100% increased Experience
		Has no Attribute Requirements]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function getSelectedLoadout(treeId, itemIndex, itemId, skillIndex, skillId, configIndex, configId)
		local selectedLoadout = {
			treeId = treeId,
			itemIndex = itemIndex,
			itemId = itemId,
			skillIndex = skillIndex,
			skillId = skillId,
			configIndex = configIndex,
			configId = configId,
		}
		return selectedLoadout
	end

	it("Test -- Default loadout exists on new build", function()
		assert.are.equals(1, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("Default", build.controls.buildLoadouts.existingLoadoutsList[1])
	end)

	it("Test New Loadout -- Default selected, fromExistingSets false", function()
		build:NewLoadout(false, "New Loadout 1", getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		assert.are.equals(2, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("Default", build.controls.buildLoadouts.existingLoadoutsList[1])
		assert.are.equals("New Loadout 1", build.controls.buildLoadouts.existingLoadoutsList[2])

		assert.are.equals(1, build.itemsTab.itemSets[1]["Body Armour"].selItemId)
		assert.are.equals(0, build.itemsTab.itemSets[2]["Body Armour"].selItemId) -- Dialla's not copied over, new empty set
	end)

	it("Test New Loadout -- Default selected, fromExistingSets true", function()
		build:NewLoadout(true, "New Loadout 1", getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		assert.are.equals(2, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("Default", build.controls.buildLoadouts.existingLoadoutsList[1])
		assert.are.equals("New Loadout 1", build.controls.buildLoadouts.existingLoadoutsList[2])

		assert.are.equals(1, build.itemsTab.itemSets[1]["Body Armour"].selItemId)
		assert.are.equals(1, build.itemsTab.itemSets[2]["Body Armour"].selItemId) -- Dialla's copied over successfully
	end)

	it("Test Copy Loadout -- Default selected", function()
		build:CopyLoadout("New Loadout 1", getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		assert.are.equals(2, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("Default", build.controls.buildLoadouts.existingLoadoutsList[1])
		assert.are.equals("New Loadout 1", build.controls.buildLoadouts.existingLoadoutsList[2])

		assert.are.equals(1, build.itemsTab.itemSets[1]["Body Armour"].selItemId)
		assert.are.equals(1, build.itemsTab.itemSets[2]["Body Armour"].selItemId) -- Dialla's copied over successfully
	end)

	it("Test Rename Loadout -- Default selected", function()
		build:RenameLoadout("New Loadout 1", getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		assert.are.equals(1, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("New Loadout 1", build.controls.buildLoadouts.existingLoadoutsList[1])
	end)

	it("Test Delete Loadout -- Default selected after creating New Loadout 1", function()
		build:NewLoadout(false, "New Loadout 1", getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		build:DeleteLoadout(getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		assert.are.equals(1, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("New Loadout 1", build.controls.buildLoadouts.existingLoadoutsList[1])
	end)

	it("Test Delete Loadout -- New Loadout 1 selected", function()
		build:NewLoadout(false, "New Loadout 1", getSelectedLoadout(1, 1, 1, 1, 1, 1, 1))
		build:SyncLoadouts()

		build:DeleteLoadout(getSelectedLoadout(2, 2, 2, 2, 2, 2, 2))
		build:SyncLoadouts()

		assert.are.equals(1, #build.controls.buildLoadouts.existingLoadoutsList)
		assert.are.equals("Default", build.controls.buildLoadouts.existingLoadoutsList[1])
		assert.are.equals(1, build.itemsTab.itemSets[1]["Body Armour"].selItemId) -- make sure items weren't somehow affected
	end)
end)