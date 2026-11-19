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
