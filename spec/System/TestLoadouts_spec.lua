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

	describe("NewLoadout", function()
		it("Creates a new loadout with the correct name", function()
			build:NewLoadout("Loadout Name", function() end)
			build:SyncLoadouts()
			-- There are 5 static items in the list
			assert.are.equals(7, #build.controls.buildLoadouts.list)
		end)

		it("calls the callback function", function()
			local callbackCalled = false
			build:NewLoadout("Loadout Name", function() callbackCalled = true end)
			build:SyncLoadouts()
			-- There are 5 static items in the list
			assert.are.equals(7, #build.controls.buildLoadouts.list)
			assert.are.equals(true, callbackCalled)
		end)
	end)

	describe("CopyLoadout", function()
		it("Copies a loadout with a new name", function()
			local loadoutName = "Loadout Name"
			local newSpec, newItemSet, newSkillSet, newConfigSet = build:CopyLoadout(1, 1, 1, 1, loadoutName)
			build:SyncLoadouts()
			-- There are 5 static items in the list
			assert.are.equals(7, #build.controls.buildLoadouts.list)
			-- First index is the "Loadout: " header, second index is the start of the loadouts
			assert.is_not.same(build.controls.buildLoadouts.list[2], build.controls.buildLoadouts.list[3])
			assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
			assert.is_not.same(newSpec, build.spec)
			assert.is_not.same(newItemSet, build.itemsTab.itemSets[1])
			assert.is_not.same(newSkillSet, build.skillsTab.skillSets[1])
			assert.is_not.same(newConfigSet, build.configTab.configSets[1])
			assert.is_same(loadoutName, newSpec.title)
			assert.is_same(loadoutName, newItemSet.title)
			assert.is_same(loadoutName, newSkillSet.title)
			assert.is_same(loadoutName, newConfigSet.title)
		end)
	end)

	describe("DeleteLoadout", function()
		it("Deletes a loadout and sets the next to the requested loadout by name", function()
			local loadoutNameToDelete = "Delete Me"
			build:NewLoadout(loadoutNameToDelete, function() end)
			build:SyncLoadouts()
			-- There are 5 static items in the list
			assert.are.equals(7, #build.controls.buildLoadouts.list)
			local loadoutToDelete = build:GetLoadoutByName(loadoutNameToDelete)
			local nextLoadout = build.controls.buildLoadouts.list[2] -- Default loadout

			build:DeleteLoadout(loadoutNameToDelete, nextLoadout)
			build:SyncLoadouts()

			assert.is_nil(build.treeTab.specList[loadoutToDelete.specId])
			assert.is_nil(build.skillsTab.skillSets[loadoutToDelete.skillSetId])
			assert.is_nil(build.itemsTab.itemSets[loadoutToDelete.itemSetId])
			assert.is_nil(build.configTab.configSets[loadoutToDelete.configSetId])

			assert.is_nil(build.itemsTab.itemSetOrderList[loadoutToDelete.itemSetId])
			assert.is_nil(build.skillsTab.skillSetOrderList[loadoutToDelete.skillSetId])
			assert.is_nil(build.configTab.configSetOrderList[loadoutToDelete.configSetId])

			assert.is_same(nextLoadout.specId, build.treeTab.displaySpecId)
			assert.is_same(nextLoadout.itemSetId, build.itemsTab.displayItemSetId)
			assert.is_same(nextLoadout.skillSetId, build.skillsTab.displaySkillSetId)
			assert.is_same(nextLoadout.configSetId, build.configTab.displayConfigSetId)
		end)
	end)

	describe("RenameLoadout", function()
		it("renames a loadout and calls the callback", function()
			local oldName = "Old Loadout"
			local newName = "New Loadout"
			local callbackCalled = false
			build:NewLoadout(oldName, function() end)
			build:SyncLoadouts()

			build:RenameLoadout(oldName, newName, function() callbackCalled = true end)
			build:SyncLoadouts()
			-- Verify the new name appears in the loadout list
			assert.is_same(newName, build.controls.buildLoadouts.list[3])
			-- Verify titles updated on spec, itemSet, skillSet, and configSet
			local loadout = build:GetLoadoutByName(newName)
			assert.is_same(newName, build.treeTab.specList[loadout.specId].title)
			assert.is_same(newName, build.itemsTab.itemSets[loadout.itemSetId].title)
			assert.is_same(newName, build.skillsTab.skillSets[loadout.skillSetId].title)
			assert.is_same(newName, build.configTab.configSets[loadout.configSetId].title)
			-- Ensure callback was called
			assert.is_true(callbackCalled)
			-- Old name should no longer exist
			assert.is_nil(build:GetLoadoutByName(oldName))
		end)
	end)
end)
