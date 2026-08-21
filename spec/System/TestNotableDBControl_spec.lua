describe("NotableDBControl", function()
	local function findPowerStat(statName)
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == statName then
				return copyTable(stat)
			end
		end
	end

	it("sorts WeightedScore anoints against the displayed item", function()
		local candidateA = {
			dn = "Candidate A",
			sd = {},
			recipe = { "Amber Oil" },
			modKey = "CandidateA",
		}
		local candidateB = {
			dn = "Candidate B",
			sd = {},
			recipe = { "Azure Oil" },
			modKey = "CandidateB",
		}
		local displayItem = { base = { type = "Amulet" } }
		local requestedFullDPS = {}
		local itemsTab = {
			displayItem = displayItem,
			tradeQuery = { statSortSelectionList = {
				{ stat = "FullDPS", weightMult = 1 },
				{ stat = "TotalEHP", weightMult = 1 },
			} },
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
						if args.repItem == displayItem then
							return { FullDPS = 200, TotalEHP = 100 }
						elseif args.repItem == candidateA then
							return { FullDPS = 180, TotalEHP = 120 }
						elseif args.repItem == candidateB then
							return { FullDPS = 150, TotalEHP = 140 }
						end
						return { FullDPS = 100, TotalEHP = 100 }
					end
				end,
			},
		}
		local control = new("NotableDBControl"):NotableDBControl(nil, { 0, 0, 100, 100 }, itemsTab, { candidateA, candidateB }, "ANOINT")
		control.sortDetail = findPowerStat("WeightedScore")
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }

		control:ListBuilder()

		assert.are.same({ true, true, true }, requestedFullDPS)
		assert.are.equal(candidateB, control.list[1])
		assert.are.equal(candidateA, control.list[2])
		assert.is_true(candidateB.measuredPower > candidateA.measuredPower)
		assert.are.equal(candidateB.measuredPower, control.sortMaxPower)
		assert.are.equal("^xFF8080Candidate B", control:GetRowValue(1, 1, candidateB))
	end)

	it("keeps scalar anoint impact relative to the item without an anoint", function()
		local notable = {
			dn = "Scalar Candidate",
			sd = {},
			recipe = { "Amber Oil" },
			modKey = "ScalarCandidate",
		}
		local displayItem = { base = { type = "Amulet" } }
		local itemsTab = {
			displayItem = displayItem,
			anointItem = function(_, node)
				return node
			end,
		}
		itemsTab.build = {
			itemsTab = itemsTab,
			calcsTab = {
				GetMiscCalculator = function()
					return function(args)
						if args.repItem == displayItem then
							return { FullDPS = 200 }
						elseif args.repItem == notable then
							return { FullDPS = 180 }
						end
						return { FullDPS = 100 }
					end
				end,
			},
		}
		local control = new("NotableDBControl"):NotableDBControl(nil, { 0, 0, 100, 100 }, itemsTab, { notable }, "ANOINT")
		control.sortDetail = findPowerStat("FullDPS")
		control.sortOrder = { control.sortControl.STAT, control.sortControl.NAME }

		control:ListBuilder()

		assert.are.equal(80, notable.measuredPower)
		assert.are.equal("^xFF8080Scalar Candidate", control:GetRowValue(1, 1, notable))
	end)
end)
