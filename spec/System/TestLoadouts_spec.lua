local t_insert = table.insert
local t_remove = table.remove

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
				build:NewLoadout(loadoutName)
				build:SyncLoadouts()
				-- There are 5 static items in the list
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.is_true(build.modFlag)
			end)
		end)

		describe("CopyLoadout", function()
			it("Copies a loadout with a new name", function()
				local loadoutName = "Loadout Name"
				local newSpec, newItemSet, newSkillSet, newConfigSet = build:CopyLoadout("Default", loadoutName)
				build:SyncLoadouts()
				-- There are 5 static items in the list
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				-- First index is the "Loadout: " header, second index is the start of the loadouts
				assert.is_not.same(build.controls.buildLoadouts.list[2], build.controls.buildLoadouts.list[3])
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.is_not.same(newSpec, build.treeTab.specList[1])
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
				build:NewLoadout(loadoutNameToDelete)
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

				assert.is_same(1, build.treeTab.activeSpec)
				assert.is_same(1, build.itemsTab.activeItemSetId)
				assert.is_same(1, build.skillsTab.activeSkillSetId)
				assert.is_same(1, build.configTab.activeConfigSetId)
				assert.is_true(build.modFlag)
			end)

			it("Deleting the first loadout with one other loadout decrements the index for the remaining sets",
				function()
					local loadoutNameToDelete = "Default"
					local nextLoadout = "Do not delete"
					build:NewLoadout(nextLoadout)
					build:SyncLoadouts()
					-- There are 5 static items in the list
					assert.are.equals(7, #build.controls.buildLoadouts.list)

					build:DeleteLoadout(loadoutNameToDelete, nextLoadout)
					build:SyncLoadouts()

					assert.are.equals(1, #build.treeTab.specList)
					assert.are.equals(1, build.skillsTab.activeSkillSetId)
					assert.are.equals(1, build.itemsTab.activeItemSetId)
					assert.are.equals(2, build.configTab.activeConfigSetId)

					assert.are.equals(nextLoadout, build.treeTab.specList[1].title)
					assert.are.equals(nextLoadout, build.skillsTab.skillSets[build.skillsTab.activeSkillSetId].title)
					assert.are.equals(nextLoadout, build.itemsTab.itemSets[build.itemsTab.activeItemSetId].title)
					assert.are.equals(nextLoadout, build.configTab.configSets[build.configTab.activeConfigSetId].title)

					assert.are.equals(1, #build.itemsTab.itemSetOrderList)
					assert.are.equals(1, #build.skillsTab.skillSetOrderList)
					assert.are.equals(1, #build.configTab.configSetOrderList)

					assert.are.equals(1, build.itemsTab.itemSetOrderList[1])
					assert.are.equals(1, build.skillsTab.skillSetOrderList[1])
					assert.are.equals(2, build.configTab.configSetOrderList[1])

					assert.is_true(build.modFlag)
				end)

			it(
				"Deleting the first loadout with multiple other loadouts does not change the index for the remaining sets",
				function()
					local loadoutNameToDelete = "Default"
					local nextLoadout1 = "Do not delete 1"
					local nextLoadout2 = "Do not delete 2"
					build:NewLoadout(nextLoadout1)
					build:NewLoadout(nextLoadout2)
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

					assert.is_same(1, build.treeTab.activeSpec)
					assert.is_same(2, build.itemsTab.activeItemSetId)
					assert.is_same(2, build.skillsTab.activeSkillSetId)
					assert.is_same(2, build.configTab.activeConfigSetId)
					assert.is_true(build.modFlag)
				end)
		end)

		describe("RenameLoadout", function()
			it("renames a loadout and calls the callback", function()
				local oldName = "Old Loadout"
				local newName = "New Loadout"
				build:NewLoadout(oldName)
				build:SyncLoadouts()

				build:RenameLoadout(oldName, newName)
				build:SyncLoadouts()
				-- Verify the new name appears in the loadout list
				assert.is_same(newName, build.controls.buildLoadouts.list[3])
				-- Verify titles updated on spec, itemSet, skillSet, and configSet
				local loadout = build:GetLoadoutByName(newName)
				assert.is_same(newName, build.treeTab.specList[loadout.specId].title)
				assert.is_same(newName, build.itemsTab.itemSets[loadout.itemSetId].title)
				assert.is_same(newName, build.skillsTab.skillSets[loadout.skillSetId].title)
				assert.is_same(newName, build.configTab.configSets[loadout.configSetId].title)
				-- Verify mod flags set on all tabs
				assert.is_true(build.treeTab.modFlag)
				assert.is_true(build.itemsTab.modFlag)
				assert.is_true(build.skillsTab.modFlag)
				assert.is_true(build.configTab.modFlag)
				-- Old name should no longer exist
				assert.is_nil(build:GetLoadoutByName(oldName))
				assert.is_true(build.modFlag)
			end)
		end)

		describe("ReorderLoadout", function()
			local function assertActiveLoadoutByName(expectedName)
				local activeSpec = build.treeTab.specList[build.treeTab.activeSpec]
				local activeItemSet = build.itemsTab.itemSets[build.itemsTab.activeItemSetId]
				local activeSkillSet = build.skillsTab.skillSets[build.skillsTab.activeSkillSetId]
				local activeConfigSet = build.configTab.configSets[build.configTab.activeConfigSetId]
				assert.is_not_nil(activeSpec)
				assert.is_same(expectedName, activeSpec.title)
				assert.is_not_nil(activeItemSet)
				assert.is_same(expectedName, activeItemSet.title)
				assert.is_not_nil(activeSkillSet)
				assert.is_same(expectedName, activeSkillSet.title)
				assert.is_not_nil(activeConfigSet)
				assert.is_same(expectedName, activeConfigSet.title)
			end

			it("does not reorder loadouts when oldIndex is the same as newIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout A"))

				local spec = build.treeTab.specList[2]
				t_remove(build.treeTab.specList, 2)
				t_insert(build.treeTab.specList, 2, spec)
				build:ReorderLoadout(2, 2)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout A", build.treeTab.specList[2].title)
				assertActiveLoadoutByName("Loadout A")
				assert.is_false(build.modFlag)
			end)

			it("reorders loadouts when oldIndex is less than newIndex and activeSpec is at oldIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout A"))

				local spec = build.treeTab.specList[2]
				t_remove(build.treeTab.specList, 2)
				t_insert(build.treeTab.specList, 4, spec)
				build:ReorderLoadout(2, 4)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout A", build.treeTab.specList[4].title)
				assertActiveLoadoutByName("Loadout A")
				assert.is_true(build.modFlag)
			end)

			it("reorders loadouts when oldIndex is less than newIndex and activeSpec is before oldIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout C"))

				local spec = build.treeTab.specList[2]
				t_remove(build.treeTab.specList, 2)
				t_insert(build.treeTab.specList, 3, spec)
				build:ReorderLoadout(2, 3)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout A", build.treeTab.specList[3].title)
				assertActiveLoadoutByName("Loadout C")
				assert.is_true(build.modFlag)
			end)

			it("reorders loadouts when oldIndex is less than newIndex and activeSpec is after oldIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout B"))

				local spec = build.treeTab.specList[2]
				t_remove(build.treeTab.specList, 2)
				t_insert(build.treeTab.specList, 4, spec)
				build:ReorderLoadout(2, 4)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout A", build.treeTab.specList[4].title)
				assertActiveLoadoutByName("Loadout B")
				assert.is_true(build.modFlag)
			end)

			it("reorders loadouts when oldIndex is greater than newIndex and activeSpec is at oldIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout C"))

				local spec = build.treeTab.specList[4]
				t_remove(build.treeTab.specList, 4)
				t_insert(build.treeTab.specList, 2, spec)
				build:ReorderLoadout(4, 2)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout C", build.treeTab.specList[2].title)
				assertActiveLoadoutByName("Loadout C")
				assert.is_true(build.modFlag)
			end)

			it("reorders loadouts when oldIndex is greater than newIndex and activeSpec is before newIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout B"))

				local spec = build.treeTab.specList[4]
				t_remove(build.treeTab.specList, 4)
				t_insert(build.treeTab.specList, 2, spec)
				build:ReorderLoadout(4, 2)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout C", build.treeTab.specList[2].title)
				assertActiveLoadoutByName("Loadout B")
				assert.is_true(build.modFlag)
			end)

			it("reorders loadouts when oldIndex is greater than newIndex and activeSpec is after newIndex", function()
				build:NewLoadout("Loadout A")
				build:NewLoadout("Loadout B")
				build:NewLoadout("Loadout C")
				build.modFlag = false

				build:SetActiveLoadout(build:GetLoadoutByName("Loadout A"))

				local spec = build.treeTab.specList[4]
				t_remove(build.treeTab.specList, 4)
				t_insert(build.treeTab.specList, 3, spec)
				build:ReorderLoadout(4, 3)

				assert.is_same(4, #build.treeTab.specList)
				assert.is_same("Loadout C", build.treeTab.specList[3].title)
				assertActiveLoadoutByName("Loadout A")
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
				buildSetService:CopyLoadout("Default", loadoutName)
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
				assert.is_same({ itemSetId = 1, skillSetId = 1, configSetId = 2 },
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

		describe("CustomLoadout", function()
			it("creates a new loadout with default values (all -1)", function()
				local loadoutName = "Custom Loadout"
				buildSetService:CustomLoadout(-1, -1, -1, -1, loadoutName)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.is_true(build.modFlag)
			end)

			it("creates a new loadout by copying existing spec, item, skill, and config sets", function()
				local loadoutName = "Custom Loadout from Existing"
				local loadoutToCopy = build:GetLoadoutByName("Default")
				buildSetService:CustomLoadout(loadoutToCopy.specId, loadoutToCopy.itemSetId, loadoutToCopy.skillSetId,
					loadoutToCopy.configSetId, loadoutName)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				assert.are.equals(loadoutName, build.controls.buildLoadouts.list[3])
				assert.is_true(build.modFlag)
			end)

			it("creates new sets when id is -1, copies existing when id is valid", function()
				-- Create initial custom loadout with all new sets
				buildSetService:CustomLoadout(-1, -1, -1, -1, "All New Sets")
				assert.are.equals(2, #build.treeTab.specList)
				assert.are.equals(2, #build.skillsTab.skillSets)
				assert.are.equals(2, #build.itemsTab.itemSets)
				assert.are.equals(2, #build.configTab.configSets)

				-- Create second loadout mixing new and existing sets
				local existingItemSet = build.itemsTab.itemSets[1]
				local existingSkillSet = build.skillsTab.skillSets[1]
				local existingConfigSet = build.configTab.configSets[1]

				local mixedLoadoutName = "Mixed Sets"
				buildSetService:CustomLoadout(-1, existingItemSet.id, existingSkillSet.id, existingConfigSet.id,
					mixedLoadoutName)
				assert.are.equals(3, #build.treeTab.specList)
				assert.are.equals(3, #build.skillsTab.skillSets)
				assert.are.equals(3, #build.itemsTab.itemSets)
				assert.are.equals(3, #build.configTab.configSets)

				local mixedLoadout = build:GetLoadoutByName(mixedLoadoutName)
				local newSpec = build.treeTab.specList[mixedLoadout.specId]
				local newItemSet = build.itemsTab.itemSets[build.itemsTab.itemSetOrderList[mixedLoadout.itemSetId]]
				local newSkillSet = build.skillsTab.skillSets
					[build.skillsTab.skillSetOrderList[mixedLoadout.skillSetId]]
				local newConfigSet = build.configTab.configSets
					[build.configTab.configSetOrderList[mixedLoadout.configSetId]]
				assert.is_not.same(build.itemsTab.itemSetOrderList[mixedLoadout.itemSetId], existingItemSet.id)
				assert.is_not.same(build.skillsTab.skillSetOrderList[mixedLoadout.skillSetId], existingSkillSet.id)
				assert.is_not.same(build.configTab.configSetOrderList[mixedLoadout.configSetId], existingConfigSet.id)
				assert.is_same(mixedLoadoutName, newSpec.title)
				assert.is_same(mixedLoadoutName, newItemSet.title)
				assert.is_same(mixedLoadoutName, newSkillSet.title)
				assert.is_same(mixedLoadoutName, newConfigSet.title)
				assert.is_true(build.modFlag)
			end)

			it("sets the newly created loadout as selected", function()
				local loadoutName = "Should Be Selected"
				buildSetService:CustomLoadout(-1, -1, -1, -1, loadoutName)
				assert.are.equals(3, build.controls.buildLoadouts.selIndex)
				assert.are.equals(loadoutName, build.controls.buildLoadouts:GetSelValue())
				local loadout = build:GetLoadoutByName(loadoutName)
				assert.is_not_nil(build.treeTab.specList[loadout.specId])
				assert.is_not_nil(build.itemsTab.itemSets[loadout.itemSetId])
				assert.is_not_nil(build.skillsTab.skillSets[loadout.skillSetId])
				assert.is_not_nil(build.configTab.configSets[loadout.configSetId])
				assert.is_true(build.modFlag)
			end)

			it("handles copy with partial existing sets", function()
				-- Create first custom loadout
				buildSetService:CustomLoadout(-1, -1, -1, -1, "Custom 1")
				assert.are.equals(7, #build.controls.buildLoadouts.list)

				-- Get the first loadout and copy only spec and item sets
				local custom1 = build:GetLoadoutByName("Custom 1")
				local existingItemSet = build.itemsTab.itemSets[1]

				buildSetService:CustomLoadout(custom1.specId, existingItemSet.id, -1, -1, "Custom 1 Modified")
				assert.are.equals(8, #build.controls.buildLoadouts.list)

				-- Verify the loadout was created with new sets
				local modifiedCustom = build:GetLoadoutByName("Custom 1 Modified")
				assert.is_not_nil(modifiedCustom)
				assert.is_true(build.modFlag)
			end)

			it("works with copy of existing loadout combined with new sets", function()
				local copyLoadout = build:GetLoadoutByName("Default")
				buildSetService:CustomLoadout(copyLoadout.specId, -1, -1, -1, "Custom from Default")
				assert.are.equals(7, #build.controls.buildLoadouts.list)

				-- Verify new sets were created
				local customFromDefault = build:GetLoadoutByName("Custom from Default")
				assert.is_not.same(customFromDefault.itemSetId, copyLoadout.itemSetId)
				assert.is_not.same(customFromDefault.skillSetId, copyLoadout.skillSetId)
				assert.is_not.same(customFromDefault.configSetId, copyLoadout.configSetId)
				assert.is_true(build.modFlag)
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

				buildSetService:CopyLoadout(newLoadout1, copyLoadout1)

				assert.are.equals(9, #build.controls.buildLoadouts.list)
				assert.are.equals(copyLoadout1, build.controls.buildLoadouts.list[5])
				assert.are.equals(5, build.controls.buildLoadouts.selIndex)
				assert.is_true(build.modFlag)

				buildSetService:CopyLoadout(newLoadout2, copyLoadout2)

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
					buildSetService:CopyLoadout(loadoutNames[4], copyLoadoutName)
					assert.are.equals(6 + i, #build.controls.buildLoadouts.list)
					assert.are.equals(copyLoadoutName, build.controls.buildLoadouts.list[2 + i])
				end
			end)

			it("New Loadout, delete config, rename default, create custom", function()
				local newLoadoutName = "New Loadout"
				buildSetService:NewLoadout(newLoadoutName)
				assert.are.equals(7, #build.controls.buildLoadouts.list)
				local newLoadout = build:GetLoadoutByName(newLoadoutName)
				build.configTab:DeleteConfigSet(newLoadout.configSetId, 2)
				build.configTab.configSets[1].title = "Config 1"

				local customLoadoutName = "Custom Loadout"
				buildSetService:CustomLoadout(-1, -1, -1, 1, customLoadoutName)
				assert.are.equals(6, #build.controls.buildLoadouts.list)
				assert.are.equals(customLoadoutName, build.controls.buildLoadouts.list[2])
				assert.are.equals(customLoadoutName, build.controls.buildLoadouts:GetSelValue())
				local customLoadout = build:GetLoadoutByName(customLoadoutName)
				assert.are.equals(2, customLoadout.configSetId)
				assert.are.equals(3, customLoadout.itemSetId)
				assert.are.equals(3, customLoadout.skillSetId)
				assert.are.equals(3, customLoadout.specId)
				assert.is_true(build.modFlag)
			end)

			it("does not leave the config set in a broken state when deleting the last configset along with the loadout",
				function()
					local loadoutName = "Loadout To Delete"
					buildSetService:NewLoadout(loadoutName)
					assert.are.equals(7, #build.controls.buildLoadouts.list)
					build.configTab:DeleteConfigSet(build.configTab.configSetOrderList[1], 1)
					assert.are.equals(1, #build.configTab.configSetOrderList)
					local loadout = build:GetLoadoutByName(loadoutName)
					buildSetService:DeleteLoadout(2, build.treeTab.specList, build.treeTab.specList[loadout.specId])
					assert.are.equals(1, #build.configTab.configSetOrderList)
					assert.are.equals(6, #build.controls.buildLoadouts.list)
					assert.are.equals("Default", build.controls.buildLoadouts.list[2])
				end)
		end)
	end)
end)
