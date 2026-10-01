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

describe("Power report cluster calculations", function()
	local calcsTab, originalCalculator, originalTime, originalProgress, originalComplete
	local clusterNodes, clusterCalls, hitDPS

	before_each(function()
		newBuild()
		runCallback("OnFrame")
		calcsTab = build.calcsTab
		calcsTab.nodePowerMaxDepth = 1
		originalCalculator = calcsTab.miscCalculator[1]
		originalTime = GetTime
		originalProgress = build.powerBuilderProgressCallback
		originalComplete = build.powerBuilderCallback
		clusterNodes = { }
		clusterCalls = 0
		for _, node in pairs(build.spec.tree.clusterNodeMap) do
			clusterNodes[node] = true
		end
		for _, stat in ipairs(data.powerStatList) do
			if stat.stat == "TotalDPS" then
				hitDPS = stat
				break
			end
		end
		calcsTab.miscCalculator[1] = function(mod, ...)
			for node in pairs(mod.addNodes or { }) do
				if clusterNodes[node] then
					clusterCalls = clusterCalls + 1
					break
				end
			end
			return originalCalculator(mod, ...)
		end
	end)

	after_each(function()
		calcsTab.miscCalculator[1] = originalCalculator
		_G.GetTime = originalTime
		build.powerBuilderProgressCallback = originalProgress
		build.powerBuilderCallback = originalComplete
		calcsTab.powerBuilder = nil
		calcsTab.powerBuildFlag = false
		build.treeTab.viewer.showHeatMap = false
	end)

	it("skips cluster calculations for Offence/Defence while initializing power tables", function()
		calcsTab.powerStat = data.powerStatList[1]
		calcsTab:PowerBuilder()
		assert.are.equal(0, clusterCalls)
		assert.is_not_nil(next(clusterNodes))
		for node in pairs(clusterNodes) do
			assert.same({ }, node.power)
		end
	end)

	it("clears Hit DPS cluster values in Offence/Defence and restores them on returning", function()
		calcsTab.powerStat = hitDPS
		calcsTab:PowerBuilder()
		assert.is_true(clusterCalls > 0)
		local initialCalls = clusterCalls
		local initialPowers = { }
		for node in pairs(clusterNodes) do
			initialPowers[node] = copyTable(node.power)
			if not node.alloc and node.modKey ~= "" and not calcsTab.mainEnv.grantedPassives[node.id] then
				assert.is_number(node.power.singleStat)
			end
		end

		clusterCalls = 0
		calcsTab.powerStat = data.powerStatList[1]
		calcsTab:PowerBuilder()
		assert.are.equal(0, clusterCalls)
		for node in pairs(clusterNodes) do
			assert.same({ }, node.power)
		end

		calcsTab.powerStat = hitDPS
		calcsTab:PowerBuilder()
		assert.are.equal(initialCalls, clusterCalls)
		for node in pairs(clusterNodes) do
			assert.same(initialPowers[node], node.power)
		end
	end)

	it("reports progress and completes only the replacement after a metric switch", function()
		local clock = 0
		_G.GetTime = function()
			clock = clock + 101
			return clock
		end
		-- Exercise real traversal and coroutine scheduling without repeating the stat calculations.
		calcsTab.miscCalculator[1] = function()
			return calcsTab.miscCalculator[2]
		end
		local progress = { }
		local completions = 0
		build.powerBuilderProgressCallback = function(percent)
			assert.is_true(percent >= 0 and percent <= 100)
			assert.is_true(percent >= (progress[#progress] or 0))
			table.insert(progress, percent)
		end
		build.powerBuilderCallback = function()
			completions = completions + 1
			originalComplete()
		end

		build.treeTab:SetPowerCalc(hitDPS)
		calcsTab:BuildPower()
		local abandonedBuilder = calcsTab.powerBuilder
		calcsTab:BuildPower()
		assert.is_true(#progress > 0)
		assert.are.equal(0, completions)
		build.treeTab:SetPowerCalc(data.powerStatList[1])
		assert.same({ }, build.treeTab.controls.powerReportList.originalList)
		progress = { }
		calcsTab:BuildPower()
		assert.is_not.equal(abandonedBuilder, calcsTab.powerBuilder)
		for _ = 1, 10000 do
			if not calcsTab.powerBuilder then
				break
			end
			calcsTab:BuildPower()
		end
		assert.is_nil(calcsTab.powerBuilder)
		assert.is_true(#progress > 0)
		assert.are.equal(1, completions)
		assert.same({ }, build.treeTab.controls.powerReportList.originalList)
		assert.are.equal("suspended", coroutine.status(abandonedBuilder))
		calcsTab:BuildPower()
		assert.are.equal(1, completions)
	end)
end)
