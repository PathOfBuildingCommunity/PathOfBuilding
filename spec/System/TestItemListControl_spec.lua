describe("ItemListControl", function()
	local originalOpenConfirmPopup
	local originalGetCursorPos
	local originalPortraitMode

	local function newItemListControl()
		local function newItem(id, name, type, primarySlot, rarity)
			return {
				id = id,
				name = name,
				type = type,
				rarity = rarity or "NORMAL",
				base = { subType = "" },
				GetPrimarySlot = function()
					return primarySlot
				end,
			}
		end
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
			slotOrder = { ["Body Armour"] = 1, Jewel = 2 },
			items = {
				[1] = newItem(1, "Armour One", "Body Armour", "Body Armour"),
				[2] = newItem(2, "Armour Two", "Body Armour", "Body Armour"),
				[3] = newItem(3, "Jewel One", "Jewel", "Jewel"),
				[4] = newItem(4, "Jewel Two", "Jewel", "Jewel"),
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
			GetEquippedSlotForItem = function(_, item)
				if item.id == 1 then
					return { slotName = "Body Armour" }
				elseif item.id == 2 then
					return { slotName = "Body Armour" }, otherItemSet
				end
			end,
		}
		local control = new("ItemListControl"):ItemListControl(nil, { 0, 0, 360, 308 }, itemsTab, true)
		return control, itemsTab, treeTab
	end

	before_each(function()
		originalOpenConfirmPopup = main.OpenConfirmPopup
		originalGetCursorPos = GetCursorPos
		originalPortraitMode = main.portraitMode
	end)

	after_each(function()
		main.OpenConfirmPopup = originalOpenConfirmPopup
		GetCursorPos = originalGetCursorPos
		main.portraitMode = originalPortraitMode
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

	it("uses the mutable custom order by default", function()
		local control = newItemListControl()
		control:UpdateLoadoutList()
		control:UpdateList()

		assert.equal("Custom Order", control.controls.sortMode:GetSelValue())
		assert.is_true(control.isMutable)
		assert.is_true(rawequal(control.list, control.itemsTab.itemOrderList))
		assert.are.same({ 1, 2, 3, 4 }, control.itemsTab.itemOrderList)

		control.controls.loadoutFilter.selIndex = 2
		control:UpdateList()

		assert.is_false(control.isMutable)

		control.controls.loadoutFilter.selIndex = 1
		control:UpdateList()

		assert.is_true(control.isMutable)
		assert.is_true(rawequal(control.list, control.itemsTab.itemOrderList))
		assert.are.same({ 1, 2, 3, 4 }, control.itemsTab.itemOrderList)
	end)

	it("keeps sorted views separate from the custom order", function()
		local control, itemsTab = newItemListControl()
		itemsTab.items[1].name = "D Item"
		itemsTab.items[2].name = "A Item"
		itemsTab.items[3].name = "B Item"
		itemsTab.items[4].name = "C Item"
		control.controls.sortMode:SelByValue("Sort by Name")

		control:UpdateList()

		assert.is_false(control.isMutable)
		assert.are.same({ 2, 3, 4, 1 }, control.list)
		assert.are.same({ 1, 2, 3, 4 }, control.itemsTab.itemOrderList)
	end)

	it("appends drops from sorted views to the custom order", function()
		local control, itemsTab = newItemListControl()
		local insertionIndex
		itemsTab.AddItem = function(self, item, _, index)
			insertionIndex = index
			item.id = 5
			self.items[item.id] = item
			table.insert(self.itemOrderList, index or #self.itemOrderList + 1, item.id)
		end
		itemsTab.AddForbiddenJewelCounterpart = function() end
		control.controls.sortMode:SelByValue("Sort by Name")
		control:UpdateList()
		control.selDragIndex = 2

		control:ReceiveDrag("Item", { raw = "Rarity: Normal\nPlate Vest" })

		assert.is_nil(insertionIndex)
		assert.are.same({ 1, 2, 3, 4, 5 }, itemsTab.itemOrderList)
	end)

	it("filters by primary item slot and item name", function()
		local control, itemsTab = newItemListControl()
		itemsTab.items[1].name = "Matching Body Armour"
		itemsTab.items[2].name = "Other Body Armour"
		itemsTab.items[3].name = "Matching Jewel"
		control.controls.slotFilter.selIndex = isValueInArray(control.controls.slotFilter.list, "Body Armour")
		control.controls.search.buf = "matching"

		control:UpdateList()

		assert.are.same({ 1 }, control.list)
	end)

	it("sorts by item-slot order and then by name", function()
		local control, itemsTab = newItemListControl()
		itemsTab.items[1].name = "Later Body Armour"
		itemsTab.items[2].name = "Earlier Body Armour"
		itemsTab.items[3].name = "Later Jewel"
		itemsTab.items[4].name = "Earlier Jewel"
		control.controls.sortMode:SelByValue("Sort by Item Slot")

		control:UpdateList()

		assert.are.same({ 2, 1, 4, 3 }, control.list)
	end)

	it("sorts unique, rare, magic, and normal items in rarity order", function()
		local control, itemsTab = newItemListControl()
		itemsTab.items[1].rarity = "MAGIC"
		itemsTab.items[2].rarity = "NORMAL"
		itemsTab.items[3].rarity = "UNIQUE"
		itemsTab.items[4].rarity = "RARE"
		control.controls.sortMode:SelByValue("Sort by Rarity")

		control:UpdateList()

		assert.are.same({ 3, 4, 1, 2 }, control.list)
	end)

	it("sorts loadout groups in menu order while preferring the current loadout", function()
		local control, itemsTab = newItemListControl()
		itemsTab.items[1].name = "Later Boss Armour"
		itemsTab.items[2].name = "Mapping Armour"
		itemsTab.items[3].name = "Boss Jewel"
		itemsTab.items[4].name = "Mapping Jewel"
		itemsTab.itemSets[2].Gloves = { selItemId = 1 }
		itemsTab.build.controls.buildLoadouts.list = { "Mapping", "Boss" }
		control.controls.sortMode:SelByValue("Sort by Loadout")

		control:UpdateList()

		assert.are.same({
			{ groupHeader = "Mapping" }, 2, 4,
			{ groupHeader = "Boss" }, 3, 1,
		}, control.list)
	end)

	it("does not label items used outside complete loadouts as unused", function()
		local control, itemsTab, treeTab = newItemListControl()
		itemsTab.items[5] = {
			id = 5,
			name = "Experimental Jewel",
			type = "Jewel",
			rarity = "RARE",
			base = { subType = "" },
			GetPrimarySlot = function() return "Jewel" end,
		}
		itemsTab.items[6] = {
			id = 6,
			name = "Unused Jewel",
			type = "Jewel",
			rarity = "RARE",
			base = { subType = "" },
			GetPrimarySlot = function() return "Jewel" end,
		}
		table.insert(itemsTab.itemOrderList, 5)
		table.insert(itemsTab.itemOrderList, 6)
		table.insert(treeTab.specList, {
			title = "Experimental",
			jewels = { [300] = 5 },
			nodes = { [300] = { alloc = true } },
		})
		control.controls.sortMode:SelByValue("Sort by Loadout")

		control:UpdateList()

		assert.are.same({
			{ groupHeader = "Boss" }, 1, 3,
			{ groupHeader = "Mapping" }, 2, 4,
			{ groupHeader = "Other Used Items" }, 5,
			{ groupHeader = "Unused Items" }, 6,
		}, control.list)
	end)

	it("does not allow group headers to become selected", function()
		local control = newItemListControl()
		control.controls.sortMode:SelByValue("Sort by Loadout")
		control:UpdateList()

		assert.is_false(control:SelectIndex(1))
		assert.is_nil(control.selIndex)
		assert.is_nil(control.selValue)
	end)

	it("shows slot icons for items but not loadout group headers", function()
		local control = newItemListControl()

		assert.is_not_nil(control:GetRowIcon(1, 1, 1))
		assert.is_nil(control:GetRowIcon(1, 1, { groupHeader = "Boss" }))
	end)

	it("clears filters that hide a selected item", function()
		local control = newItemListControl()
		control.controls.slotFilter.selIndex = 4
		control.controls.loadoutFilter.selIndex = 2
		control.controls.search.buf = "missing"
		control.controls.sortMode:SelByValue("Sort by Item Slot")

		control:SelectItem(4)

		assert.equal(1, control.controls.slotFilter.selIndex)
		assert.equal(1, control.controls.loadoutFilter.selIndex)
		assert.equal("", control.controls.search.buf)
		assert.equal(4, control.selValue)
		assert.equal(4, control.selIndex)
	end)

	it("skips group headers during keyboard navigation", function()
		local control = newItemListControl()
		control.controls.sortMode:SelByValue("Sort by Loadout")
		control:UpdateList()

		control:OnKeyDown("HOME")
		assert.equal(1, control.selValue)
		control:OnKeyDown("DOWN")
		assert.equal(3, control.selValue)
		control:OnKeyDown("DOWN")
		assert.equal(2, control.selValue)
		control:OnKeyDown("UP")
		assert.equal(3, control.selValue)
		control:OnKeyDown("END")
		assert.equal(4, control.selValue)
	end)

	it("resizes list controls when the orientation changes", function()
		local control = newItemListControl()
		control.width = function() return main.portraitMode and 360 or 450 end
		local viewPort = { x = 0, y = 0, width = 1920, height = 1080 }

		main.portraitMode = false
		control:Draw(viewPort)
		assert.equal((450 - 8) / 3, control.controls.slotFilter.width)
		assert.equal(450, control.controls.search.width)

		main.portraitMode = true
		control:Draw(viewPort)
		assert.equal((360 - 8) / 3, control.controls.slotFilter.width)
		assert.equal(360, control.controls.search.width)
		assert.equal(-44, control.controls.deleteUnused.y)
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
		local item = new("Item"):Item([[
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
