describe("ItemDBControl", function()
	local originalGetCursorPos
	local function findPowerStat(statName)
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == statName then
				return stat
			end
		end
	end

	before_each(function()
		originalGetCursorPos = GetCursorPos
	end)

	after_each(function()
		GetCursorPos = originalGetCursorPos
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

	it("preserves negative WeightedScore results and skips unneeded FullDPS", function()
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
		local requestedFullDPS = { }
		local itemsTab = {
			activeItemSet = { useSecondWeaponSet = false },
			slots = { ["Body Armour"] = {} },
			tradeQuery = {
				statSortSelectionList = {
					{ stat = "PhysicalTakenHit", weightMult = 1, transform = function(value) return -value end },
				},
			},
			IsItemValidForSlot = function(_, item)
				return item ~= invalidItem
			end,
		}
		itemsTab.build = {
			itemsTab = itemsTab,
			calcsTab = {
				GetMiscCalculator = function()
					return function(args, useFullDPS)
						table.insert(requestedFullDPS, useFullDPS)
						return { PhysicalTakenHit = takenDamage[args.repItem] }
					end, { PhysicalTakenHit = 100 }
				end,
			},
		}
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, itemsTab, {
			list = { invalidItem, betterItem, worseItem },
		}, "RARE")
		control.sortDetail = copyTable(findPowerStat("WeightedScore"))
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }

		control:ListBuilder()

		assert.are.equal(betterItem, control.list[1])
		assert.are.equal(worseItem, control.list[2])
		assert.are.equal(invalidItem, control.list[3])
		assert.is_true(betterItem.measuredPower < 0)
		assert.is_true(worseItem.measuredPower < betterItem.measuredPower)
		assert.are.equal(-math.huge, invalidItem.measuredPower)
		assert.are.same({ false, false }, requestedFullDPS)
	end)

	it("requests FullDPS for WeightedScore when active weights need it", function()
		local item = {
			name = "Full DPS Item",
			base = {},
			enchantModLines = {},
			implicitModLines = {},
			explicitModLines = {},
			baseModList = {},
		}
		local requestedFullDPS = { }
		local itemsTab = {
			activeItemSet = { useSecondWeaponSet = false },
			slots = { ["Body Armour"] = {} },
			tradeQuery = { statSortSelectionList = { { stat = "FullDPS", weightMult = 1 } } },
			IsItemValidForSlot = function()
				return true
			end,
		}
		itemsTab.build = {
			itemsTab = itemsTab,
			calcsTab = {
				GetMiscCalculator = function()
					return function(_, useFullDPS)
						table.insert(requestedFullDPS, useFullDPS)
						return { FullDPS = 120 }
					end, { FullDPS = 100 }
				end,
			},
		}
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, itemsTab, { list = { item } }, "RARE")
		control.sortDetail = copyTable(findPowerStat("WeightedScore"))
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }

		control:ListBuilder()

		assert.are.same({ true }, requestedFullDPS)
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
end)
