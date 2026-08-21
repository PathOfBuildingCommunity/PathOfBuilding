describe("NotableDBControl", function()
	it("requests FullDPS when sorting by WeightedScore with FullDPS weights", function()
		local notable = {
			dn = "Full DPS Notable",
			sd = {},
			recipe = { "Amber Oil" },
			modKey = "NotableFullDPS",
		}
		local requestedFullDPS = {}
		local itemsTab = {
			displayItem = { base = { type = "Amulet" } },
			tradeQuery = { statSortSelectionList = { { stat = "FullDPS", weightMult = 1 } } },
			anointItem = function(_, node)
				return node
			end,
		}
		itemsTab.build = {
			itemsTab = itemsTab,
			calcsTab = {
				GetMiscCalculator = function()
					return function(args, useFullDPS)
						table.insert(requestedFullDPS, useFullDPS)
						return { FullDPS = args.repItem and 120 or 100 }
					end
				end,
			},
		}
		local control = new("NotableDBControl"):NotableDBControl(nil, { 0, 0, 100, 100 }, itemsTab, { [1] = notable }, "ANOINT")
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == "WeightedScore" then
				control.sortDetail = copyTable(stat)
				break
			end
		end
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }

		control:ListBuilder()

		assert.are.same({ true, true }, requestedFullDPS)
		assert.are.equal(notable, control.list[1])
		assert.is_true(notable.measuredPower > 0)
		assert.are.equal(notable.measuredPower, control.sortMaxPower)
		assert.are.equal("^xFF8080Full DPS Notable", control:GetRowValue(1, 1, notable))
	end)
end)
