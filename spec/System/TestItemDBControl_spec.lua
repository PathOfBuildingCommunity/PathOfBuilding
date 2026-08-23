describe("ItemDBControl", function()
	local originalGetCursorPos
	local function findPowerStat(statName)
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == statName then
				return stat
			end
		end
	end
	local function newItem(name)
		return {
			name = name,
			base = {},
			enchantModLines = {},
			implicitModLines = {},
			explicitModLines = {},
			baseModList = {},
		}
	end
	local function newRankingFixture(weights)
		local items = {
			better = newItem("Better Item"),
			worse = newItem("Worse Item"),
			invalid = newItem("Invalid Item"),
		}
		local values = {
			[items.better] = { PhysicalTakenHit = 80, FullDPS = 120 },
			[items.worse] = { PhysicalTakenHit = 120, FullDPS = 80 },
		}
		local requestedFullDPS = { }
		local itemsTab = {
			activeItemSet = { useSecondWeaponSet = false },
			slots = { ["Body Armour"] = {} },
			tradeQuery = { statSortSelectionList = weights or {} },
			IsItemValidForSlot = function(_, item)
				return item ~= items.invalid
			end,
		}
		itemsTab.build = {
			itemsTab = itemsTab,
			calcsTab = {
				GetMiscCalculator = function()
					return function(args, useFullDPS)
						requestedFullDPS[#requestedFullDPS + 1] = useFullDPS
						return values[args.repItem]
					end, { PhysicalTakenHit = 100, FullDPS = 100 }
				end,
			},
		}
		local control = new("ItemDBControl"):ItemDBControl(nil, { 0, 0, 100, 100 }, itemsTab, {
			list = { items.invalid, items.better, items.worse },
		}, "RARE")
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }
		return control, items, requestedFullDPS
	end

	before_each(function()
		originalGetCursorPos = GetCursorPos
	end)

	after_each(function()
		GetCursorPos = originalGetCursorPos
	end)

	it("sorts lower-is-better stats below zero", function()
		local control, items = newRankingFixture()
		control.sortDetail = {
			stat = "PhysicalTakenHit",
			transform = function(value) return -value end,
		}

		control:ListBuilder()

		assert.are.same({ items.better, items.worse, items.invalid }, control.list)
		assert.are.equal(-80, items.better.measuredPower)
		assert.are.equal(-120, items.worse.measuredPower)
		assert.are.equal(-math.huge, items.invalid.measuredPower)
	end)

	it("preserves negative WeightedScore results and skips unneeded FullDPS", function()
		local weights = {
			{ stat = "PhysicalTakenHit", weightMult = 1, transform = function(value) return -value end },
		}
		local control, items, requestedFullDPS = newRankingFixture(weights)
		control.sortDetail = copyTable(findPowerStat("WeightedScore"))

		control:ListBuilder()

		assert.are.same({ items.better, items.worse, items.invalid }, control.list)
		assert.is_true(items.better.measuredPower < 0)
		assert.is_true(items.worse.measuredPower < items.better.measuredPower)
		assert.are.equal(-math.huge, items.invalid.measuredPower)
		assert.are.same({ false, false }, requestedFullDPS)
	end)

	it("requests FullDPS for WeightedScore when active weights need it", function()
		local control, _, requestedFullDPS = newRankingFixture({ { stat = "FullDPS", weightMult = 1 } })
		control.sortDetail = copyTable(findPowerStat("WeightedScore"))

		control:ListBuilder()

		assert.are.same({ true, true }, requestedFullDPS)
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
