local applyRangeTests = {
	-- Number without range
	[{ "+10 to maximum Life", 1.0, 1.0 }] = "+10 to maximum Life",
	[{ "+10 to maximum Life", 1.0, 1.5 }] = "+15 to maximum Life",
	[{ "+10 to maximum Life", 0.5, 1.0 }] = "+10 to maximum Life",
	[{ "+10 to maximum Life", 0.5, 1.5 }] = "+15 to maximum Life",
	-- One range
	[{ "+(10-20) to maximum Life", 1.0, 1.0 }] = "+20 to maximum Life",
	[{ "+(10-20) to maximum Life", 1.0, 1.5 }] = "+30 to maximum Life",
	[{ "+(10-20) to maximum Life", 0.5, 1.0 }] = "+15 to maximum Life",
	[{ "+(10-20) to maximum Life", 0.5, 1.5 }] = "+22 to maximum Life",
	-- Two ranges
	[{ "Adds (60-80) to (270-300) Physical Damage", 1.0, 1.0 }] = "Adds 80 to 300 Physical Damage",
	[{ "Adds (60-80) to (270-300) Physical Damage", 1.0, 1.5 }] = "Adds 120 to 450 Physical Damage",
	[{ "Adds (60-80) to (270-300) Physical Damage", 0.5, 1.0 }] = "Adds 70 to 285 Physical Damage",
	[{ "Adds (60-80) to (270-300) Physical Damage", 0.5, 1.5 }] = "Adds 105 to 427 Physical Damage",
	-- Range with increased/reduced
	[{ "(10--10)% increased Charges per use", 1.0, 1.0 }] = "10% reduced Charges per use",
	[{ "(10--10)% increased Charges per use", 1.0, 1.5 }] = "15% reduced Charges per use",
	[{ "(10--10)% increased Charges per use", 0.5, 1.0 }] = "0% increased Charges per use",
	[{ "(10--10)% increased Charges per use", 0.5, 1.5 }] = "0% increased Charges per use",
	[{ "(10--10)% increased Charges per use", 0.0, 1.0 }] = "10% increased Charges per use",
	[{ "(10--10)% increased Charges per use", 0.0, 1.5 }] = "15% increased Charges per use",
	-- Range with constant numbers after
	[{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 1.0, 1.0 }] = "20% increased Cold Damage per 1% Cold Resistance above 75%",
	[{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 1.0, 1.5 }] = "30% increased Cold Damage per 1% Cold Resistance above 75%",
	[{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 0.5, 1.0 }] = "18% increased Cold Damage per 1% Cold Resistance above 75%",
	[{ "(15-20)% increased Cold Damage per 1% Cold Resistance above 75%", 0.5, 1.5 }] = "27% increased Cold Damage per 1% Cold Resistance above 75%",
	-- High precision range
	[{ "Regenerate (66.7-75) Life per second", 1.0, 1.0 }] = "Regenerate 75 Life per second",
	[{ "Regenerate (66.7-75) Life per second", 1.0, 1.5 }] = "Regenerate 112.5 Life per second",
	[{ "Regenerate (66.7-75) Life per second", 0.5, 1.0 }] = "Regenerate 70.9 Life per second",
	[{ "Regenerate (66.7-75) Life per second", 0.5, 1.5 }] = "Regenerate 106.3 Life per second",
	-- Range with plus sign that is removed when negative
	[{ "+(-25-50)% to Fire Resistance", 1.0, 1.0 }] = "+50% to Fire Resistance",
	[{ "+(-25-50)% to Fire Resistance", 1.0, 1.5 }] = "+75% to Fire Resistance",
	[{ "+(-25-50)% to Fire Resistance", 0.0, 1.0 }] = "-25% to Fire Resistance",
	[{ "+(-25-50)% to Fire Resistance", 0.0, 1.5 }] = "-37% to Fire Resistance",
	-- Fallback scaling
	[{ "+(10-20) to unsupported value", 1.0, 1.0, 1.22 }] = "+24 to unsupported value",
	[{ "+(10-20) to unsupported value", 1.0, 1.5, 1.22 }] = "+36 to unsupported value",
}

describe("TestItemTools", function()
	for args, expected in pairs(applyRangeTests) do
		it(string.format("tests applyRange('%s', %.2f, %.2f)", unpack(args)), function()
			local result = itemLib.applyRange(unpack(args))
			assert.are.equals(expected, result)
		end)
	end

	it("detects scalability after resolving ranges", function()
		assert.is_true(itemLib.isModLineScalable("+(10-20) to maximum Life", 1, 1))
		assert.is_false(itemLib.isModLineScalable("Your Maximum Resistances are (76-80)%", 1, 1))
	end)

	it("formats corrupted fixed-value modifiers", function()
		local modLine = { line = "Adds 1 to 59 Chaos Damage", corruptedRange = 1.22 }
		assert.are.equals(colorCodes.MAGIC .. "Adds 1 to 72 Chaos Damage", itemLib.formatModLine(modLine))
	end)

	it("uses the displayed item slot for anoint comparison tooltips", function()
		if not common.classes.ItemsTab then
			LoadModule("Classes/ItemsTab")
		end
		local item = new("Item", [[
Rarity: Rare
Dire Thread
Cord Belt
Can be Anointed
]])
		local overrides = { }
		local fakeItemsTab = setmetatable({
			displayItem = item,
			build = {
				spec = { allocNodes = { } },
				calcsTab = {
					GetMiscCalculator = function()
						return function(override)
							table.insert(overrides, override)
							return { }
						end
					end,
				},
				AddStatComparesToTooltip = function()
					return 1
				end,
			},
		}, common.classes.ItemsTab)
		local tooltip = {
			AddLine = function() end,
		}

		fakeItemsTab:AppendAnointTooltip(tooltip, { id = 1, dn = "Acrimony" })

		assert.are.equals("Belt", overrides[1].repSlotName)
		assert.are.equals("Belt", overrides[2].repSlotName)
	end)

	it("does not report missing anoints for non-anointable talisman bases", function()
		if not common.classes.ItemsTab then
			LoadModule("Classes/ItemsTab")
		end
		local fakeItemsTab = setmetatable({ }, common.classes.ItemsTab)
		local item = {
			base = {
				type = "Amulet",
				cannotBeAnointed = true,
			},
			enchantModLines = { },
			scourgeModLines = { },
			implicitModLines = { },
			explicitModLines = { },
			crucibleModLines = { },
		}

		assert.are.equals(0, fakeItemsTab:getMissingAnointCount(item))
	end)
end)
