local t_insert = table.insert

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

	describe("Build", function()
		describe("NewLoadout", function()
			it("Creates a new loadout with the correct name", function()
				local loadoutName = "Loadout Name"
				build:NewLoadout(loadoutName, function() end)
				build:SyncLoadouts()
				-- There are 5 static items in the list
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.is_true(build.modFlag)
			end)

			it("calls the callback function", function()
				local callbackCalled = false
				build:NewLoadout("Loadout Name", function() callbackCalled = true end)
				build:SyncLoadouts()
				-- There are 5 static items in the list
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(true, callbackCalled)
				assert.is_true(build.modFlag)
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
				assert.is_true(build.modFlag)
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
				assert.is_true(build.modFlag)
			end)

			it("Deleting the first loadout with one other loadout decrements the index for the remaining sets",
				function()
					local loadoutNameToDelete = "Default"
					local nextLoadout = "Do not delete"
					build:NewLoadout(nextLoadout, function() end)
					build:SyncLoadouts()
					-- There are 5 static items in the list
					assert.are.equals(7, #build.controls.buildLoadouts.list)
					local loadoutToDelete = build:GetLoadoutByName(loadoutNameToDelete)

					build:DeleteLoadout(loadoutNameToDelete, nextLoadout)
					build:SyncLoadouts()

					assert.are.equals(1, #build.treeTab.specList)
					assert.are.equals(1, #build.skillsTab.skillSets)
					assert.are.equals(1, #build.itemsTab.itemSets)
					assert.are.equals(1, #build.configTab.configSets)

					assert.are.equals(nextLoadout, build.treeTab.specList[1].title)
					assert.are.equals(nextLoadout, build.skillsTab.skillSets[1].title)
					assert.are.equals(nextLoadout, build.itemsTab.itemSets[1].title)
					assert.are.equals(nextLoadout, build.configTab.configSets[1].title)

					assert.are.equals(1, #build.itemsTab.itemSetOrderList)
					assert.are.equals(1, #build.skillsTab.skillSetOrderList)
					assert.are.equals(1, #build.configTab.configSetOrderList)

					assert.are.equals(1, build.itemsTab.itemSetOrderList[1])
					assert.are.equals(1, build.skillsTab.skillSetOrderList[1])
					assert.are.equals(1, build.configTab.configSetOrderList[1])

					assert.is_same(nextLoadout.specId, build.treeTab.displaySpecId)
					assert.is_same(nextLoadout.itemSetId, build.itemsTab.displayItemSetId)
					assert.is_same(nextLoadout.skillSetId, build.skillsTab.displaySkillSetId)
					assert.is_same(nextLoadout.configSetId, build.configTab.displayConfigSetId)
					assert.is_true(build.modFlag)
				end)

			it(
				"Deleting the first loadout with multiple other loadouts does not change the index for the remaining sets",
				function()
					local loadoutNameToDelete = "Default"
					local nextLoadout1 = "Do not delete 1"
					local nextLoadout2 = "Do not delete 2"
					build:NewLoadout(nextLoadout1, function() end)
					build:NewLoadout(nextLoadout2, function() end)
					build:SyncLoadouts()
					-- There are 5 static items in the list
					assert.are.equals(8, #build.controls.buildLoadouts.list)
					local loadoutToDelete = build:GetLoadoutByName(loadoutNameToDelete)

					build:DeleteLoadout(loadoutNameToDelete, nextLoadout1)
					build:SyncLoadouts()

					assert.are.equals(2, #build.treeTab.specList)
					assert.are.equals(3, #build.skillsTab.skillSets)
					assert.are.equals(3, #build.itemsTab.itemSets)
					assert.are.equals(3, #build.configTab.configSets)

					assert.are.equals(nextLoadout1, build.treeTab.specList[1].title)
					assert.are.equals(nextLoadout1, build.skillsTab.skillSets[2].title)
					assert.are.equals(nextLoadout1, build.itemsTab.itemSets[2].title)
					assert.are.equals(nextLoadout1, build.configTab.configSets[2].title)

					assert.are.equals(nextLoadout2, build.treeTab.specList[2].title)
					assert.are.equals(nextLoadout2, build.skillsTab.skillSets[3].title)
					assert.are.equals(nextLoadout2, build.itemsTab.itemSets[3].title)
					assert.are.equals(nextLoadout2, build.configTab.configSets[3].title)

					assert.is_same(nextLoadout1.specId, build.treeTab.displaySpecId)
					assert.is_same(nextLoadout1.itemSetId, build.itemsTab.displayItemSetId)
					assert.is_same(nextLoadout1.skillSetId, build.skillsTab.displaySkillSetId)
					assert.is_same(nextLoadout1.configSetId, build.configTab.displayConfigSetId)
					assert.is_true(build.modFlag)
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
				assert.is_true(build.modFlag)
			end)
		end)
	end)

	describe("BuildSetService", function()
		local buildSetService
		before_each(function()
			buildSetService = new("BuildSetService", build)
		end)

		describe("NewLoadout", function()
			it("creates a new loadout", function()
				local loadoutName = "Loadout Name"
				buildSetService:NewLoadout(loadoutName)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.is_true(build.modFlag)
			end)
		end)

		describe("CopyLoadout", function()
			it("copies an existing loadout and selects it", function()
				local loadoutName = "Loadout Name"
				local loadoutToCopy = build:GetLoadoutByName("Default")
				buildSetService:CopyLoadout(loadoutToCopy.specId, loadoutToCopy.itemSetId, loadoutToCopy.skillSetId,
					loadoutToCopy.configSetId, loadoutName)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.are.equals(3, build.controls.buildLoadouts.selIndex)
				assert.is_true(build.modFlag)
			end)
		end)

		describe("RenameLoadout", function()
			it("renames an existing loadout", function()
				local oldname = "New Loadout"
				local newName = "Renamed Loadout"
				buildSetService:NewLoadout(oldname)
				buildSetService:RenameLoadout(oldname, newName)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.is_same({ "Default", newName },
					{ build.controls.buildLoadouts.list[2], build.controls.buildLoadouts.list[3] })
				assert.is_true(build.modFlag)
			end)
		end)

		describe("DeleteLoadout", function()
			it("deletes the current loadout", function()
				local loadoutNameToDelete = "Delete Me"

				buildSetService:NewLoadout(loadoutNameToDelete)
				build:SetActiveLoadout(build:GetLoadoutByName(loadoutNameToDelete))
				local specIdToDelete = build:GetLoadoutByName(loadoutNameToDelete).specId
				buildSetService:DeleteLoadout(2, build.treeTab.specList, build.treeTab.specList[specIdToDelete])
				assert.are.equals(6, #build.controls.buildLoadouts.list)
				-- Default loadout return when only one loadout remains
				assert.is_same({ itemSetId = 1, skillSetId = 1, configSetId = 1 },
					build:GetLoadoutByName(loadoutNameToDelete))
			end)

			it("deletes the loadout before the current", function()
				local loadoutNameToDelete = "Default"
				local currentLoadout = "Do not delete"

				buildSetService:NewLoadout(currentLoadout)
				build:SetActiveLoadout(build:GetLoadoutByName(currentLoadout))
				local specIdToDelete = build:GetLoadoutByName(loadoutNameToDelete).specId
				buildSetService:DeleteLoadout(1, build.treeTab.specList, build.treeTab.specList[specIdToDelete])
				assert.are.equals(6, #build.controls.buildLoadouts.list)
				-- Default loadout return when only one loadout remains
				assert.is_same({ itemSetId = 1, skillSetId = 1, configSetId = 1 },
					build:GetLoadoutByName(loadoutNameToDelete))
				assert.are.equals(2, build.controls.buildLoadouts.selIndex)
				assert.are.equals("Do not delete", build.controls.buildLoadouts:GetSelValue())
			end)

			it("deletes the loadout after the current", function()
				local loadoutNameToDelete = "Delete Me"
				local currentLoadout = "Do not delete"

				buildSetService:NewLoadout(currentLoadout)
				buildSetService:NewLoadout(loadoutNameToDelete)
				build:SetActiveLoadout(build:GetLoadoutByName(currentLoadout))
				local specIdToDelete = build:GetLoadoutByName(loadoutNameToDelete).specId
				buildSetService:DeleteLoadout(3, build.treeTab.specList, build.treeTab.specList[specIdToDelete])
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.is_nil(build:GetLoadoutByName(loadoutNameToDelete))
				assert.are.equals(3, build.controls.buildLoadouts.selIndex)
				assert.are.equals(currentLoadout, build.controls.buildLoadouts:GetSelValue())
			end)
		end)

		describe("Integration", function()
			it("completes a loadout lifecycle", function()
				-- 2 New Loadouts, Copy 2, Delete one of each
				local newLoadout1 = "New Loadout 1"
				local newLoadout2 = "New Loadout 2"
				local copyLoadout1 = "Copy Loadout 1"
				local copyLoadout2 = "Copy Loadout 2"
				local deleteLoadout1 = newLoadout1
				local deleteLoadout2 = copyLoadout2
				local currentLoadout = newLoadout2

				buildSetService:NewLoadout(newLoadout1)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(newLoadout1, build.controls.buildLoadouts.list[3])

				buildSetService:NewLoadout(newLoadout2)
				assert.are.equals(8, #build.controls.buildLoadouts.list)
				assert.are.equals(newLoadout2, build.controls.buildLoadouts.list[4])

				build:SetActiveLoadout(build:GetLoadoutByName(currentLoadout))
				assert.are.equals(4, build.controls.buildLoadouts.selIndex)

				local loadoutToCopy = build:GetLoadoutByName(newLoadout1)
				buildSetService:CopyLoadout(loadoutToCopy.specId, loadoutToCopy.itemSetId, loadoutToCopy.skillSetId,
					loadoutToCopy.configSetId, copyLoadout1)

				assert.are.equals(9, #build.controls.buildLoadouts.list)
				assert.are.equals(copyLoadout1, build.controls.buildLoadouts.list[5])
				assert.are.equals(5, build.controls.buildLoadouts.selIndex)
				assert.is_true(build.modFlag)

				local loadoutToCopy = build:GetLoadoutByName(newLoadout2)
				buildSetService:CopyLoadout(loadoutToCopy.specId, loadoutToCopy.itemSetId, loadoutToCopy.skillSetId,
					loadoutToCopy.configSetId, copyLoadout2)

				assert.are.equals(10, #build.controls.buildLoadouts.list)
				assert.are.equals(copyLoadout2, build.controls.buildLoadouts.list[6])
				assert.are.equals(6, build.controls.buildLoadouts.selIndex)
				assert.is_true(build.modFlag)

				build:SetActiveLoadout(build:GetLoadoutByName(currentLoadout))
				assert.are.equals(4, build.controls.buildLoadouts.selIndex)

				local specIdToDelete = build:GetLoadoutByName(deleteLoadout1).specId
				buildSetService:DeleteLoadout(2, build.treeTab.specList, build.treeTab.specList[specIdToDelete])

				assert.are.equals(9, #build.controls.buildLoadouts.list)
				assert.is_nil(build:GetLoadoutByName(deleteLoadout1))
				assert.are.equals(3, build.controls.buildLoadouts.selIndex)
				assert.are.equals(currentLoadout, build.controls.buildLoadouts:GetSelValue())

				local specIdToDelete = build:GetLoadoutByName(deleteLoadout2).specId
				buildSetService:DeleteLoadout(4, build.treeTab.specList, build.treeTab.specList[specIdToDelete])

				assert.are.equals(8, #build.controls.buildLoadouts.list)
				assert.is_nil(build:GetLoadoutByName(deleteLoadout2))
				assert.are.equals(3, build.controls.buildLoadouts.selIndex)
				assert.are.equals(currentLoadout, build.controls.buildLoadouts:GetSelValue())
			end)

			it("deletes all but the last loadout then copies it", function()
				local loadoutNames = { "Loadout 1", "Loadout 2", "Loadout 3", "Loadout 4" }
				for _, name in ipairs(loadoutNames) do
					buildSetService:NewLoadout(name)
				end
				assert.are.equals(10, #build.controls.buildLoadouts.list)

				build:SetActiveLoadout(build:GetLoadoutByName(loadoutNames[3]))

				for i = 1, 4 do
					local loadoutToDelete = build:GetLoadoutByName(build.controls.buildLoadouts.list[2])
					local specIdToDelete = loadoutToDelete.specId
					buildSetService:DeleteLoadout(1, build.treeTab.specList, build.treeTab.specList[specIdToDelete])
					assert.are.equals(10 - i, #build.controls.buildLoadouts.list)
				end

				assert.is_not_nil(build:GetLoadoutByName(loadoutNames[4]))
				assert.are.equals(2, build.controls.buildLoadouts.selIndex)
				assert.are.equals(loadoutNames[4], build.controls.buildLoadouts:GetSelValue())

				for i = 1, 3 do
					local copyLoadoutName = loadoutNames[i] .. " Copy"
					local loadoutToCopy = build:GetLoadoutByName(loadoutNames[4])
					buildSetService:CopyLoadout(loadoutToCopy.specId, loadoutToCopy.itemSetId, loadoutToCopy.skillSetId,
						loadoutToCopy.configSetId, copyLoadoutName)
					assert.are.equals(6 + i, #build.controls.buildLoadouts.list)
					assert.are.equals(copyLoadoutName, build.controls.buildLoadouts.list[2 + i])
				end
			end)
		end)
	end)
end)
