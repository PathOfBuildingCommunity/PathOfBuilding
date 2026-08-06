describe("ItemListControl", function()
	local originalOpenConfirmPopup
	local originalGetCursorPos

	local function newItemListControl()
		local activeItemSet = {
			id = 1,
			title = "Boss",
			["Body Armour"] = { selItemId = 1 },
		}
		local otherItemSet = {
			id = 2,
			title = "Mapping",
			["Body Armour"] = { selItemId = 2 },
		}
		local treeTab = {
			activeSpec = 1,
			specList = {
				{
					title = "Boss",
					jewels = { [100] = 3 },
					nodes = { [100] = { alloc = true } },
				},
				{
					title = "Mapping",
					jewels = { [200] = 4 },
					nodes = { [200] = { alloc = true } },
				},
			},
		}
		local itemsTab = {
			itemOrderList = { 1, 2, 3, 4 },
			items = {
				[1] = { id = 1, type = "Body Armour", base = { subType = "" } },
				[2] = { id = 2, type = "Body Armour", base = { subType = "" } },
				[3] = { id = 3, type = "Jewel", base = { subType = "" } },
				[4] = { id = 4, type = "Jewel", base = { subType = "" } },
			},
			itemSetOrderList = { 1, 2 },
			itemSets = { activeItemSet, otherItemSet },
			activeItemSetId = 1,
			activeItemSet = activeItemSet,
			slots = { },
			build = {
				itemListSpecialLinks = { },
				treeListSpecialLinks = { },
				controls = {
					buildLoadouts = { list = { "Boss", "Mapping" } },
				},
				treeTab = treeTab,
			},
			PopulateSlots = function() end,
			AddUndoState = function() end,
		}
		local control = new("ItemListControl", nil, { 0, 0, 360, 308 }, itemsTab, true)
		return control, itemsTab, treeTab
	end

	before_each(function()
		originalOpenConfirmPopup = main.OpenConfirmPopup
		originalGetCursorPos = GetCursorPos
	end)

	after_each(function()
		main.OpenConfirmPopup = originalOpenConfirmPopup
		GetCursorPos = originalGetCursorPos
	end)

	it("only shows items from the active item set and passive tree", function()
		local control = newItemListControl()
		control:UpdateLoadoutList()
		control.controls.loadoutFilter.selIndex = 2

		control:UpdateList()

		assert.are.same({ 1, 3 }, control.list)
	end)

	it("uses the selected item set and passive tree for named loadouts", function()
		local control = newItemListControl()
		control:UpdateLoadoutList()
		control.controls.loadoutFilter.selIndex = isValueInArray(control.controls.loadoutFilter.list, "Mapping")

		control:UpdateList()

		assert.are.same({ 2, 4 }, control.list)
	end)

	it("matches linked sets and old passive tree display names", function()
		local control, itemsTab, treeTab = newItemListControl()
		itemsTab.itemSets[2].title = "Gear {mapping}"
		treeTab.specList[2].title = "Tree {mapping}"
		itemsTab.build.itemListSpecialLinks.mapping = { setId = 2 }
		itemsTab.build.treeListSpecialLinks.mapping = { setId = 2 }
		itemsTab.build.controls.buildLoadouts.list = { "Tree {mapping}", "[3.28] Boss" }
		control:UpdateLoadoutList()
		control.controls.loadoutFilter.selIndex = isValueInArray(control.controls.loadoutFilter.list, "Tree {mapping}")

		control:UpdateList()

		assert.are.same({ 2, 4 }, control.list)

		control.controls.loadoutFilter.selIndex = isValueInArray(control.controls.loadoutFilter.list, "[3.28] Boss")
		control:UpdateList()

		assert.are.same({ 1, 3 }, control.list)
	end)

	it("clears hidden selections and preserves visible selections by item ID", function()
		local control = newItemListControl()
		control:UpdateLoadoutList()
		control.selIndex = 2
		control.selValue = 2
		control.controls.loadoutFilter.selIndex = 2

		control:UpdateList()

		assert.is_nil(control.selIndex)
		assert.is_nil(control.selValue)

		control.selIndex = 3
		control.selValue = 3
		control:UpdateList()

		assert.are.equal(2, control.selIndex)
		assert.are.equal(3, control.selValue)
	end)

	it("only allows internal reordering in the unfiltered item list", function()
		local control = newItemListControl()
		control:UpdateLoadoutList()
		control:UpdateList()

		assert.is_true(control.isMutable)

		control.controls.loadoutFilter.selIndex = 2
		control:UpdateList()

		assert.is_false(control.isMutable)

		control.controls.loadoutFilter.selIndex = 1
		control:UpdateList()

		assert.is_true(control.isMutable)
	end)

	it("refreshes filter options when loadouts are renamed without a new output revision", function()
		local control, itemsTab, treeTab = newItemListControl()
		itemsTab.build.outputRevision = 1
		control.lastOutputRevision = 1
		control:UpdateLoadoutList()
		itemsTab.itemSets[2].title = "Renamed"
		treeTab.specList[2].title = "Renamed"
		itemsTab.build.controls.buildLoadouts.list = { "Boss", "Renamed" }
		wipeTable(itemsTab.itemOrderList)
		wipeTable(itemsTab.items)

		control:Draw({ x = 0, y = 0, width = 1920, height = 1080 })

		assert.is_nil(isValueInArray(control.controls.loadoutFilter.list, "Mapping"))
		assert.is_not_nil(isValueInArray(control.controls.loadoutFilter.list, "Renamed"))
	end)

	it("clears the canonical item order when deleting all from a filtered list", function()
		local control, itemsTab = newItemListControl()
		control:UpdateLoadoutList()
		control.controls.loadoutFilter.selIndex = isValueInArray(control.controls.loadoutFilter.list, "Mapping")
		control:UpdateList()
		main.OpenConfirmPopup = function(_, _, _, _, onConfirm)
			onConfirm()
		end

		control.controls.deleteAll.onClick()

		assert.are.same({ }, itemsTab.itemOrderList)
		assert.are.same({ }, itemsTab.items)
	end)

	it("releases focus after opening an item with a double click", function()
		local control, itemsTab = newItemListControl()
		local item = new("Item", [[
Rarity: Rare
Test Belt
Leather Belt
]])
		item.id = 1
		itemsTab.items[1] = item
		itemsTab.SetDisplayItem = function(_, displayItem)
			itemsTab.displayItem = displayItem
		end
		GetCursorPos = function()
			return 3, 3
		end
		control.GetRowRegion = function()
			return { x = 0, y = 0, width = 360, height = 308 }
		end

		local selectedControl = control:OnKeyDown("LEFTBUTTON", true)

		assert.is_nil(selectedControl)
		assert.are.equal(1, itemsTab.displayItem.id)
	end)
end)
