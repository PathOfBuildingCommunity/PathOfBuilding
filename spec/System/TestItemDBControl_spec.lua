describe("ItemDBControl", function()
	local originalGetCursorPos
	local originalIsKeyDown

	before_each(function()
		originalGetCursorPos = GetCursorPos
		originalIsKeyDown = _G.IsKeyDown
	end)

	after_each(function()
		GetCursorPos = originalGetCursorPos
		_G.IsKeyDown = originalIsKeyDown
	end)

	it("sorts lower-is-better stats below zero", function()
		local function makeItem(name)
			return {
				name = name,
				base = {},
				enchantModLines = {},
				implicitModLines = {},
				explicitModLines = {},
				baseModList = {},
			}
		end
		local betterItem = makeItem("Better Item")
		local worseItem = makeItem("Worse Item")
		local invalidItem = makeItem("Invalid Item")
		local takenDamage = {
			[betterItem] = 80,
			[worseItem] = 120,
		}
		local itemsTab = {
			activeItemSet = { useSecondWeaponSet = false },
			slots = { ["Body Armour"] = {} },
			build = {
				calcsTab = {
					GetMiscCalculator = function()
						return function(args)
							return { PhysicalTakenHit = takenDamage[args.repItem] }
						end
					end,
				},
			},
			IsItemValidForSlot = function(_, item)
				return item ~= invalidItem
			end,
		}
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, itemsTab, {
			list = { invalidItem, betterItem, worseItem },
		}, "RARE")
		control.sortDetail = {
			stat = "PhysicalTakenHit",
			transform = function(value) return -value end,
		}
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }

		control:ListBuilder()

		assert.are.equal(betterItem, control.list[1])
		assert.are.equal(worseItem, control.list[2])
		assert.are.equal(invalidItem, control.list[3])
		assert.are.equal(-80, betterItem.measuredPower)
		assert.are.equal(-120, worseItem.measuredPower)
		assert.are.equal(-math.huge, invalidItem.measuredPower)
	end)

	it("searches Foulborn modifier text without case sensitivity", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Kitava's Thirst
			Zealot Helmet
			Variant: Pre 3.11.0
			Variant: Current
			Selected Variant: 2
			50% chance to Trigger Socketed Spells when you Spend at least 100 Mana on an
			Upfront Cost to Use or Trigger a Skill, with a 0.1 second Cooldown
		]])
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, {
			build = {
				characterLevel = 100,
			},
		}, {
			list = { item },
		}, "UNIQUE")
		control.controls.search.buf = "life on an upfront cost"
		control.controls.searchMode.selIndex = 3

		assert.is_true(control:DoesItemMatchFilters(item))
	end)

	it("releases focus after opening an item with a double click", function()
		local item = {
			raw = "Rarity: Unique\nTest Item\nLeather Belt",
		}
		local itemsTab
		itemsTab = {
			CreateDisplayItemFromRaw = function(_, raw, isUnique)
				itemsTab.displayRaw = raw
				itemsTab.displayIsUnique = isUnique
			end,
		}
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, itemsTab, {
			list = { item },
		}, "UNIQUE")
		control.list = { item }
		GetCursorPos = function()
			return 3, 3
		end
		control.GetRowRegion = function()
			return { x = 0, y = 0, width = 100, height = 100 }
		end

		local selectedControl = control:OnKeyDown("LEFTBUTTON", true)

		assert.is_nil(selectedControl)
		assert.are.equal(item.raw, itemsTab.displayRaw)
		assert.is_true(itemsTab.displayIsUnique)
	end)

	it("resizes its filter controls with the item list", function()
		local width = 360
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, function() return width end, 100 }, {
			build = { outputRevision = 1 },
		}, {
			list = { },
		}, "RARE")
		local viewPort = { x = 0, y = 0, width = 1920, height = 1080 }

		control:Draw(viewPort)
		assert.equal(179, control.controls.slot.width)
		assert.equal(258, control.controls.search.width)

		width = 450
		control:Draw(viewPort)
		assert.equal(224, control.controls.slot.width)
		assert.equal(348, control.controls.search.width)
	end)

	it("selects a newly added item after equipping it", function()
		local equipped
		local counterpartAdded
		local slotsPopulated
		local selectedItemId
		local item = { raw = "Rarity: Normal\nPlate Vest" }
		local itemsTab = {
			activeItemSet = { useSecondWeaponSet = false },
			slots = {
				["Body Armour"] = {
					weaponSet = 0,
					SetSelItemId = function() equipped = true end,
				},
			},
			controls = {
				itemList = {
					SelectItem = function(_, itemId)
						assert.is_true(equipped)
						assert.is_true(counterpartAdded)
						assert.is_true(slotsPopulated)
						selectedItemId = itemId
					end,
				},
			},
			build = { },
			AddItem = function(_, newItem)
				newItem.id = 1
			end,
			AddForbiddenJewelCounterpart = function() counterpartAdded = true end,
			PopulateSlots = function() slotsPopulated = true end,
			AddUndoState = function() end,
		}
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, itemsTab, { list = { item } }, "RARE")
		_G.IsKeyDown = function(key) return key == "CTRL" end

		control:OnSelClick(1, item, false)

		assert.equal(1, selectedItemId)
	end)
end)
