describe("NotableDBControl", function()
	local function findPowerStat(statName)
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == statName then
				return copyTable(stat)
			end
		end
	end
	local function newAnointFixture(weights, includeSecondCandidate)
		local candidates = {
			{ dn = "Candidate A", sd = {}, recipe = { "Fixture Oil" }, modKey = "CandidateA" },
			{ dn = "Candidate B", sd = {}, recipe = { "Fixture Oil" }, modKey = "CandidateB" },
		}
		local displayItem = { base = { type = "Amulet" } }
		local outputs = {
			[displayItem] = { FullDPS = 200, TotalEHP = 100 },
			[candidates[1]] = { FullDPS = 180, TotalEHP = 120 },
			[candidates[2]] = { FullDPS = 150, TotalEHP = 140 },
		}
		local requestedFullDPS = { }
		local itemsTab = {
			displayItem = displayItem,
			tradeQuery = { statSortSelectionList = weights or {} },
			anointItem = function(_, node) return node end,
		}
		itemsTab.build = {
			itemsTab = itemsTab,
			calcsTab = {
				GetMiscCalculator = function()
					return function(args, useFullDPS)
						requestedFullDPS[#requestedFullDPS + 1] = useFullDPS
						return outputs[args.repItem] or { FullDPS = 100, TotalEHP = 100 }
					end
				end,
			},
		}
		local list = includeSecondCandidate and candidates or { candidates[1] }
		local control = new("NotableDBControl"):NotableDBControl(nil, { 0, 0, 100, 100 }, itemsTab, list, "ANOINT")
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }
		return control, candidates, requestedFullDPS
	end

	it("sorts WeightedScore anoints against the displayed item", function()
		local weights = {
			{ stat = "FullDPS", weightMult = 1 },
			{ stat = "TotalEHP", weightMult = 1 },
		}
		local control, candidates, requestedFullDPS = newAnointFixture(weights, true)
		control.sortDetail = findPowerStat("WeightedScore")

		control:ListBuilder()

		assert.are.same({ true, true, true }, requestedFullDPS)
		assert.are.same({ candidates[2], candidates[1] }, control.list)
		assert.is_true(candidates[2].measuredPower > candidates[1].measuredPower)
		assert.are.equal(candidates[2].measuredPower, control.sortMaxPower)
	end)

	it("keeps scalar anoint impact relative to the item without an anoint", function()
		local control, candidates = newAnointFixture()
		control.sortDetail = findPowerStat("FullDPS")

		control:ListBuilder()

		assert.are.equal(80, candidates[1].measuredPower)
	end)
end)
