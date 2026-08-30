describe("PowerReportListControl", function()
	local PowerReportListControl

	before_each(function()
		LoadModule("Classes/PowerReportListControl")
		PowerReportListControl = common.classes.PowerReportListControl
	end)

	local function relist(originalList, showClusters, allocated)
		local control = {
			originalList = originalList,
			showClusters = showClusters or false,
			allocated = allocated or false,
		}
		PowerReportListControl.ReList(control)
		return control.list
	end

	it("Show Unallocated excludes allocated nodes", function()
		local list = relist({
			{ name = "allocated", power = 10, pathDist = 1, allocated = true },
			{ name = "unallocated", power = 5, pathDist = 1, allocated = false },
		}, false, false)

		assert.are.equal(1, #list)
		assert.are.equal("unallocated", list[1].name)
	end)

	it("Show Allocated includes allocated nodes", function()
		local list = relist({
			{ name = "allocated", power = -10, pathDist = 1, allocated = true },
			{ name = "unallocated", power = 5, pathDist = 1, allocated = false },
		}, false, true)

		assert.are.equal(1, #list)
		assert.are.equal("allocated", list[1].name)
	end)
end)

local function findPowerStat(stat)
	for _, powerStat in ipairs(data.powerStatList) do
		if powerStat.stat == stat then
			return powerStat
		end
	end
end

describe("Power report calculation requirements", function()
	before_each(function()
		newBuild()
	end)

	it("marks only the metrics that require eHP or Full DPS", function()
		local expectedEHPStats = {
			TotalEHP = true,
			SecondMinimalMaximumHitTaken = true,
			PhysicalTakenHit = true,
			LightningTakenHit = true,
			ColdTakenHit = true,
			FireTakenHit = true,
			ChaosTakenHit = true,
		}
		local eHPStatCount = 0
		local fullDPSStatCount = 0
		for _, powerStat in ipairs(data.powerStatList) do
			if powerStat.requiresEHP then
				eHPStatCount = eHPStatCount + 1
				assert.is_true(expectedEHPStats[powerStat.stat:gsub("^Minion", "")])
			end
			if powerStat.requiresFullDPS then
				fullDPSStatCount = fullDPSStatCount + 1
				assert.are.equal("FullDPS", powerStat.stat)
			end
		end

		assert.are.equal(14, eHPStatCount)
		assert.are.equal(1, fullDPSStatCount)
		assert.is_true(findPowerStat("MinionTotalEHP").requiresEHP)
		assert.is_nil(findPowerStat("MeleeAvoidChance").requiresEHP)
		assert.is_nil(findPowerStat("SpellAvoidChance").requiresEHP)
		assert.is_nil(findPowerStat("ProjectileAvoidChance").requiresEHP)
	end)
end)

describe("Power report calculator options", function()
	local calcs
	local originalCalcFullDPS
	local originalPerform

	before_each(function()
		newBuild()
		calcs = build.calcsTab.calcs
		originalCalcFullDPS = calcs.calcFullDPS
		originalPerform = calcs.perform
	end)

	after_each(function()
		calcs.calcFullDPS = originalCalcFullDPS
		calcs.perform = originalPerform
	end)

	local function makeCalculator()
		local state = {
			fullDPSCalls = 0,
			performSkipEHP = { },
		}
		calcs.calcFullDPS = function()
			state.fullDPSCalls = state.fullDPSCalls + 1
			return { skills = { { } }, combinedDPS = 1, TotalDotDPS = 0 }
		end
		calcs.perform = function(env, skipEHP)
			table.insert(state.performSkipEHP, skipEHP == nil and "nil" or skipEHP)
			return originalPerform(env, skipEHP)
		end

		local calcFunc = calcs.getMiscCalculator(build)
		state.fullDPSCalls = 0
		state.performSkipEHP = { }
		return calcFunc, state
	end

	it("honors explicit stage skips for each report type", function()
		build.viewMode = "TREE"
		local calcFunc, state = makeCalculator()

		calcFunc({ }, nil, { skipEHP = true, skipFullDPS = true })
		assert.are.same({ true }, state.performSkipEHP)
		assert.are.equal(0, state.fullDPSCalls)

		state.performSkipEHP = { }
		calcFunc({ }, true, { skipEHP = true, skipFullDPS = false })
		assert.are.same({ true }, state.performSkipEHP)
		assert.are.equal(1, state.fullDPSCalls)

		state.performSkipEHP = { }
		calcFunc({ }, false, { skipEHP = false, skipFullDPS = true })
		assert.are.same({ false }, state.performSkipEHP)
		assert.are.equal(1, state.fullDPSCalls)
	end)

	it("preserves legacy Tree calculations when options are omitted", function()
		build.viewMode = "TREE"
		local calcFunc, state = makeCalculator()

		calcFunc({ }, false)
		assert.are.same({ "nil" }, state.performSkipEHP)
		assert.are.equal(1, state.fullDPSCalls)
	end)

	it("preserves representative report values", function()
		build.viewMode = "TREE"
		local calcFunc, calcBase = calcs.getMiscCalculator(build)
		local testNode
		for nodeId, node in pairs(build.spec.nodes) do
			if not node.alloc and node.type ~= "Mastery" and node.modKey ~= "" and not build.calcsTab.mainEnv.grantedPassives[nodeId] then
				testNode = node
				break
			end
		end
		assert(testNode)
		local override = { addNodes = { [testNode] = true } }

		for _, stat in ipairs({ "Life", "TotalDPS", "FullDPS", "TotalEHP" }) do
			local powerStat = findPowerStat(stat)
			local useFullDPS = powerStat.requiresFullDPS or false
			local legacyOutput = calcFunc(override, useFullDPS)
			local optimizedOutput = calcFunc(override, useFullDPS, {
				skipEHP = not powerStat.requiresEHP,
				skipFullDPS = not useFullDPS,
			})
			assert.are.near(
				data.powerStatList.GetFromOutput(legacyOutput, powerStat),
				data.powerStatList.GetFromOutput(optimizedOutput, powerStat),
				10 ^ -9
			)
		end

		local legacyOutput = calcFunc(override, false)
		local optimizedOutput = calcFunc(override, false, { skipEHP = true, skipFullDPS = true })
		local legacyOffence, legacyDefence = build.calcsTab:CalculateCombinedOffDefStat(legacyOutput, calcBase)
		local optimizedOffence, optimizedDefence = build.calcsTab:CalculateCombinedOffDefStat(optimizedOutput, calcBase)
		assert.are.near(legacyOffence, optimizedOffence, 10 ^ -9)
		assert.are.near(legacyDefence, optimizedDefence, 10 ^ -9)
	end)
end)

describe("PowerBuilder calculation options", function()
	before_each(function()
		newBuild()
	end)

	it("uses one selected-metric option set for all candidate calculations", function()
		local output = {
			Life = 101,
			TotalEHP = 101,
			FullDPS = 101,
			CombinedDPS = 101,
			LifeUnreserved = 101,
			Armour = 101,
			EnergyShield = 101,
			Evasion = 101,
			LifeRegenRecovery = 101,
			EnergyShieldRegenRecovery = 101,
			Minion = { TotalEHP = 101, CombinedDPS = 101 },
		}
		local baseOutput = output

		local function runPowerBuilder(powerStat, expectedOptions)
			local callCount = 0
			build.calcsTab.powerStat = powerStat
			build.calcsTab.powerMax = nil
			build.calcsTab.nodePowerMaxDepth = 1
			build.calcsTab.miscCalculator = { function(override, useFullDPS, options)
				callCount = callCount + 1
				assert.are.same(expectedOptions, options)
				assert.are.equal(not expectedOptions.skipFullDPS, useFullDPS)
				return output
			end, baseOutput }

			build.calcsTab:PowerBuilder()
			assert.is_true(callCount > 0)
		end

		runPowerBuilder(findPowerStat("Life"), { skipEHP = true, skipFullDPS = true })
		runPowerBuilder(findPowerStat("FullDPS"), { skipEHP = true, skipFullDPS = false })
		runPowerBuilder(findPowerStat("TotalEHP"), { skipEHP = false, skipFullDPS = true })
		runPowerBuilder(findPowerStat("MinionTotalEHP"), { skipEHP = false, skipFullDPS = true })
		runPowerBuilder(findPowerStat("MeleeAvoidChance"), { skipEHP = true, skipFullDPS = true })
		runPowerBuilder(data.powerStatList[1], { skipEHP = true, skipFullDPS = true })
	end)
end)
