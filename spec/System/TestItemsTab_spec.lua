describe("TestItemsTab", function()
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
		build.itemsTab:AddDisplayItem(true)

		build.itemsTab:CreateDisplayItemFromRaw("New Item\nKarui Chopper")
		build.itemsTab:AddDisplayItem(true)

		runCallback("OnFrame")
	end)

	describe("ItemsTab", function()
		describe("NewItemSet", function()
			it("Creates a new item set with specified ID", function()
				local itemSetName = "New Item Set"
				local setId = 2
				build.itemsTab:NewItemSet(setId, itemSetName)

				assert.are.equals(itemSetName, build.itemsTab.itemSets[setId].title)
				assert.are.equals(setId, build.itemsTab.itemSets[setId].id)
			end)

			it("Assigns auto-incremented ID when not specified", function()
				local itemSetName = "Auto ID Item Set"
				local setId1 = build.itemsTab:NewItemSet()
				local setId2 = build.itemsTab:NewItemSet(nil, itemSetName)

				assert.are.equals(2, setId1.id)
				assert.are.equals(3, setId2.id)
				assert.are.equals(itemSetName, build.itemsTab.itemSets[setId2.id].title)
			end)

			it("Adds set to order list", function()
				local newTitle = "New Item"

				build.itemsTab:NewItemSet(nil, newTitle)

				assert.are.equals(2, #build.itemsTab.itemSetOrderList)
				assert.are.equals(2, build.itemsTab.itemSetOrderList[2])
			end)

			it("Sets mod flag when creating new item set", function()
				local newTitle = "New Item"
				build.itemsTab.modFlag = false

				build.itemsTab.modFlag = false

				build.itemsTab:NewItemSet(nil, newTitle)

				assert.is_true(build.itemsTab.modFlag)
			end)
		end)

		describe("CopyItemSet", function()
			it("Copies an item set with a new name", function()
				local newTitle = "Copied Item Set"
				local newItemSet = build.itemsTab:CopyItemSet(1, newTitle)

				assert.is_not.same(build.itemsTab.itemSets[1], newItemSet)
				assert.are.equals(newTitle, newItemSet.title)
			end)

			it("Returns copied item set with next ID", function()
				local newTitle = "Copied Item"

				local newItemSet = build.itemsTab:CopyItemSet(1, newTitle)

				assert.are.equals(2, newItemSet.id)
			end)

			it("Adds copied item set to order list", function()
				local newTitle = "Copied Item"

				build.itemsTab:CopyItemSet(1, newTitle)

				assert.are.equals(2, #build.itemsTab.itemSetOrderList)
				assert.are.equals(2, build.itemsTab.itemSetOrderList[2])
			end)

			it("Updates the mod flag", function()
				local newTitle = "Copied Item"
				build.itemsTab.modFlag = false

				build.itemsTab:CopyItemSet(1, newTitle)

				assert.is_true(build.itemsTab.modFlag)
			end)
		end)

		describe("RenameItemSet", function()
			it("Renames an item set", function()
				local newTitle = "Renamed Item Set"
				build.itemsTab:RenameItemSet(1, newTitle)

				assert.are.equals(newTitle, build.itemsTab.itemSets[1].title)
			end)

			it("Updates the mod flag", function()
				local newTitle = "Renamed Item"
				build.itemsTab.modFlag = false

				build.itemsTab:RenameItemSet(1, newTitle)

				assert.is_true(build.itemsTab.modFlag)
			end)

			it("Does not error on invalid item set ID", function()
				build.itemsTab.modFlag = false

				build.itemsTab:RenameItemSet(999, "Should Not Error")

				assert.is_false(build.itemsTab.modFlag)
			end)
		end)

		describe("DeleteItemSet", function()
			it("Deletes an item set and removes from order list", function()
				local itemSetName = "Item Set To Delete"
				build.itemsTab:NewItemSet(2, itemSetName)

				build.itemsTab:DeleteItemSet(2, 2)

				assert.is_nil(build.itemsTab.itemSets[2])
				assert.are.equals(1, #build.itemsTab.itemSetOrderList)
			end)

			it("Updates the mod flag", function()
				build.itemsTab:NewItemSet(2, "ToDelete")
				build.itemsTab.modFlag = false

				build.itemsTab:DeleteItemSet(2, 2)

				assert.is_true(build.itemsTab.modFlag)
			end)

			it("allows deletion of the last item set", function()
				local lastConfig = 1

				assert.are.equals(1, #build.itemsTab.itemSetOrderList)
				build.itemsTab:DeleteItemSet(lastConfig, 1)

				assert.are.equals(0, #build.itemsTab.itemSetOrderList)
				assert.is_nil(build.itemsTab.itemSets[lastConfig])
			end)
		end)
	end)

	describe("SetActiveItemSet", function()
		it("Switches to a valid item set", function()
			local itemSetName = "New Item Set"
			build.itemsTab:NewItemSet(2, itemSetName)

			build.itemsTab:SetActiveItemSet(2)

			assert.are.equals(2, build.itemsTab.activeItemSetId)
			assert.are.same(build.itemsTab.itemSets[2], build.itemsTab.activeItemSet)
		end)

		it("Defaults to first item set if invalid ID provided", function()
			build.itemsTab:SetActiveItemSet(999)

			assert.are.equals(1, build.itemsTab.activeItemSetId)
		end)

		it("Sets buildFlag", function()
			local itemSetName = "New Item Set"
			build.itemsTab:NewItemSet(2, itemSetName)

			build.buildFlag = false

			build.itemsTab:SetActiveItemSet(2, true)

			assert.are.equals(2, build.itemsTab.activeItemSetId)
			assert.is_true(build.buildFlag)
		end)
	end)

	describe("ItemSetService", function()
		local itemSetService
		before_each(function()
			itemSetService = new("ItemSetService", build.itemsTab)
		end)

		describe("NewItemSet", function()
			it("Creates a new item set via service", function()
				local itemSetName = "Service New Item"
				itemSetService:NewItemSet(itemSetName)

				assert.are.equals(2, #build.itemsTab.itemSetOrderList)
				assert.are.equals(itemSetName, build.itemsTab.itemSets[2].title)
			end)

			it("Sets newly created item set as active", function()
				itemSetService:NewItemSet("New From Service")

				assert.are.equals(2, build.itemsTab.activeItemSetId)
			end)

			it("Adds an undo state", function()
				local newTitle = "New Item"

				local undoCountBefore = #build.itemsTab.undo
				itemSetService:NewItemSet(newTitle)

				assert.are.equals(#build.itemsTab.undo, undoCountBefore + 1)
			end)
		end)

		describe("CopyItemSet", function()
			it("Copies a item set via service", function()
				local itemName = "Copied via Service"
				itemSetService:CopyItemSet(1, itemName)
				local setId = build.itemsTab.itemSetOrderList[2]

				assert.are.equals(itemName, build.itemsTab.itemSets[setId].title)
			end)

			it("Sets copied item set as active via service", function()
				itemSetService:NewItemSet("Item")
				itemSetService:CopyItemSet(1, "Service Copy")
				local setId = build.itemsTab.itemSetOrderList[3]

				assert.are.equals(setId, build.itemsTab.activeItemSetId)
			end)

			it("Adds an undo state when copying a item set", function()
				local undoCountBefore = #build.itemsTab.undo
				itemSetService:CopyItemSet(1, "Copied Item")

				assert.are.equals(#build.itemsTab.undo, undoCountBefore + 1)
			end)
		end)

		describe("RenameItemSet", function()
			it("Renames a item set via service", function()
				local itemName = "Original Name"
				itemSetService:NewItemSet(itemName)
				local setId = build.itemsTab.itemSetOrderList[2]

				itemSetService:RenameItemSet(setId, "New Name")

				assert.are.equals("New Name", build.itemsTab.itemSets[setId].title)
			end)

			it("Does not rename non-existent item set", function()
				itemSetService:RenameItemSet(10, "Non-existent")

				assert.is_nil(build.itemsTab.itemSets[10])
			end)

			it("Adds an undo state when renaming", function()
				local itemSetName = "Item To Rename"
				itemSetService:NewItemSet(itemSetName)
				local setId = build.itemsTab.itemSetOrderList[2]

				local undoCountBefore = #build.itemsTab.undo
				itemSetService:RenameItemSet(setId, "Renamed Item")

				assert.are.equals(#build.itemsTab.undo, undoCountBefore + 1)
			end)
		end)

		describe("DeleteItemSet", function()
			it("Deletes a item set via service", function()
				itemSetService:NewItemSet("Service Delete Me")

				itemSetService:DeleteItemSet(2, 2)

				assert.is_nil(build.itemsTab.itemSets[2])
				assert.is_nil(build.itemsTab.itemSetOrderList[2])
			end)


			it("Switches active item set when deleting current", function()
				itemSetService:NewItemSet("Service Delete Me")
				local itemToKeep = 1
				local itemToDelete = 2

				assert.are.equals(itemToDelete, build.itemsTab.activeItemSetId)

				itemSetService:DeleteItemSet(itemToDelete, 2)

				assert.are.equals(itemToKeep, build.itemsTab.activeItemSetId)
			end)

			it("Does not delete last item set via service", function()
				itemSetService:NewItemSet("Last One")

				itemSetService:DeleteItemSet(1, 1)

				assert.are.equals(1, #build.itemsTab.itemSetOrderList)
			end)

			it("Adds an undo state when deleting", function()
				local undoCountBefore = #build.itemsTab.undo
				local undoCountAfterNew = #build.itemsTab.undo
				itemSetService:NewItemSet("Undo Delete Test")

				itemSetService:DeleteItemSet(2, 2)

				assert.are.equals(#build.itemsTab.undo, undoCountBefore + 2)
			end)
		end)

		describe("Integration", function()
			it("Completes a item set lifecycle", function()
				local item1Name = "First Item"
				local item2Name = "Second Item"

				itemSetService:NewItemSet(item1Name)
				assert.are.equals("First Item", build.itemsTab.itemSets[2].title)

				itemSetService:CopyItemSet(2, item2Name)
				assert.are.equals("Second Item", build.itemsTab.itemSets[3].title)
			end)
		end)
	end)

	describe("ItemStateManagement", function()
		local itemSetService

		before_each(function()
			itemSetService = new("ItemSetService", build.itemsTab)
		end)

		describe("Item set persistence across switches", function()
			it("Preserves item assignments when switching between item sets", function()
				local itemSetName1 = "Set 1"
				local itemSetName2 = "Set 2"

				itemSetService:NewItemSet(itemSetName1)
				itemSetService:NewItemSet(itemSetName2)

				local setId1 = 2
				local setId2 = 3

				build.itemsTab:SetActiveItemSet(setId1)
				build.itemsTab:EquipItemInSet(build.itemsTab.items[1], setId1)

				build.itemsTab:SetActiveItemSet(setId2)
				build.itemsTab:EquipItemInSet(build.itemsTab.items[2], setId2)

				build.itemsTab:SetActiveItemSet(setId1)
				assert.are.equals(1, build.itemsTab.activeItemSet["Body Armour"].selItemId)

				build.itemsTab:SetActiveItemSet(setId2)
				assert.are.equals(2, build.itemsTab.activeItemSet["Weapon 1"].selItemId)
			end)

			it("Preserves weapon set flags when switching between item sets", function()
				itemSetService:NewItemSet("First Set")
				itemSetService:NewItemSet("Set with Weapon Swap")

				build.itemsTab.activeItemSet.useSecondWeaponSet = true

				build.itemsTab:SetActiveItemSet(2)
				assert.is_not.truthy(build.itemsTab.activeItemSet.useSecondWeaponSet)

				build.itemsTab:SetActiveItemSet(3)
				assert.is_true(build.itemsTab.activeItemSet.useSecondWeaponSet)
			end)

			it("Preserves active slot flags when switching between item sets", function()
				itemSetService:NewItemSet("First Set")
				itemSetService:NewItemSet("Second Set")

				build.itemsTab.slots["Weapon 1"].active = true
				build.itemsTab.activeItemSet["Weapon 1"].active = true

				build.itemsTab:SetActiveItemSet(2)
				assert.is_not.truthy(build.itemsTab.activeItemSet["Weapon 1"].active)

				build.itemsTab:SetActiveItemSet(3)
				assert.is_true(build.itemsTab.activeItemSet["Weapon 1"].active)
			end)
		end)

		describe("Default values", function()
			it("Initializes new item sets with default placeholder states", function()
				assert.is_not_nil(build.itemsTab.itemSets[1])
				assert.is.same(build.itemsTab.itemSets[1]["Weapon 1"], { selItemId = 0 })
			end)

			it("Copies placeholder states when copying item sets", function()
				build.itemsTab.itemSets[1]["Weapon 1"].selItemId = 1

				local newItemSet = build.itemsTab:CopyItemSet(1, "Copy Test")

				assert.are.equals(1, newItemSet["Weapon 1"].selItemId)
			end)
		end)
	end)
end)
