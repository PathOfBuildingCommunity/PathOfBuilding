-- Tests for the multi-core calculation support (Modules/ParallelRunner,
-- Modules/PowerCalcTasks, CalcWorker.lua).
--
-- Real worker threads can't run headless (LaunchSubScript is stubbed), so
-- these tests run the worker entry points (computeBatch) in-process on the
-- same build, round-trip the payloads through JSON exactly as the thread
-- boundary would, merge them, and require results identical to the
-- single-core code path.
local dkjson = require "dkjson"

local function jsonRoundTrip(payload)
	return dkjson.decode(dkjson.encode(payload))
end

local function numEq(a, b)
	if a == nil and b == nil then
		return true
	end
	if type(a) ~= "number" or type(b) ~= "number" then
		return a == b
	end
	if a ~= a and b ~= b then
		return true -- both NaN
	end
	return math.abs(a - b) <= math.max(1e-9, 1e-9 * math.max(math.abs(a), math.abs(b)))
end

describe("TestParallelTasks", function()
	before_each(function()
		newBuild()
	end)

	it("number sentinels survive the JSON boundary", function()
		local enc = PowerCalcTasks.encodeNumber
		local dec = PowerCalcTasks.decodeNumber
		assert.are.equals(5.25, dec(jsonRoundTrip({ v = enc(5.25) }).v))
		assert.are.equals(math.huge, dec(jsonRoundTrip({ v = enc(math.huge) }).v))
		assert.are.equals(-math.huge, dec(jsonRoundTrip({ v = enc(-math.huge) }).v))
		assert.are.equals(0, dec(jsonRoundTrip({ v = enc(0/0) }).v)) -- NaN guarded to 0
		assert.are.equals(nil, dec(nil))
	end)

	it("nodePower worker batches merge to the same result as single-core PowerBuilder", function()
		local calcsTab = build.calcsTab
		calcsTab.powerStat = data.powerStatList[4] -- Combined DPS
		calcsTab.nodePowerMaxDepth = 4

		-- Single-core reference (direct call; outside a coroutine it never yields)
		calcsTab:PowerBuilder()
		local refPower = { }
		for nodeId, node in pairs(build.spec.nodes) do
			refPower[nodeId] = {
				singleStat = node.power and node.power.singleStat,
				pathPower = node.power and node.power.pathPower,
			}
		end
		local refPowerMax = copyTable(calcsTab.powerMax)

		-- Parallel simulation: enumerate, batch exactly as production does
		-- (including authoritative path data), compute, JSON round trip, merge
		local cand = calcsTab:EnumeratePowerCandidates()
		assert.True(cand.total > 0)
		local batches = calcsTab:BuildPowerBatches(cand, 3)
		local common = { powerStatIndex = 4, nodePowerMaxDepth = 4 }
		local payloads = { }
		for i, batch in ipairs(batches) do
			payloads[i] = jsonRoundTrip(PowerCalcTasks.nodePower.computeBatch(build, common, batch, "", nil))
			-- Worker payloads carry a baseline for divergence detection
			assert.is_table(payloads[i].baseline)
		end
		calcsTab:MergeParallelPower(payloads, build.outputRevision)

		for nodeId, ref in pairs(refPower) do
			local node = build.spec.nodes[nodeId]
			assert.True(numEq(ref.singleStat, node.power and node.power.singleStat),
				"singleStat mismatch on node "..tostring(nodeId))
			assert.True(numEq(ref.pathPower, node.power and node.power.pathPower),
				"pathPower mismatch on node "..tostring(nodeId))
		end
		for key, value in pairs(refPowerMax) do
			assert.True(numEq(value, calcsTab.powerMax[key]), "powerMax mismatch on "..key)
		end
	end)

	it("nodePower merge discards results from a stale build revision", function()
		local calcsTab = build.calcsTab
		calcsTab.powerBuildFlag = false
		calcsTab:MergeParallelPower({ }, build.outputRevision - 1)
		assert.True(calcsTab.powerBuildFlag)
	end)

	it("notable measureOne matches the worker batch path", function()
		local itemsTab = build.itemsTab
		itemsTab.displayItem = new("Item", "Rarity: RARE\nTest Amulet\nJade Amulet\n+30 to Dexterity")
		itemsTab.anointEnchantSlot = 1

		-- Collect a handful of anointable notables
		local nodeIds = { }
		for nodeId, node in pairs(build.spec.tree.nodes) do
			if node.recipe and #node.recipe >= 1 and node.modKey ~= "" then
				table.insert(nodeIds, nodeId)
				if #nodeIds >= 15 then
					break
				end
			end
		end
		assert.True(#nodeIds > 0)

		-- Single-core reference via the shared measureOne
		local sortDetail = PowerCalcTasks.findSortDetail("CombinedDPS")
		local calcFunc = build.calcsTab:GetMiscCalculator()
		local itemType = itemsTab.displayItem.base.type
		local calcBase = calcFunc({ repSlotName = itemType, repItem = itemsTab:anointItem(nil) })
		local ref = { }
		for _, nodeId in ipairs(nodeIds) do
			ref[nodeId] = PowerCalcTasks.notable.measureOne(itemsTab, calcFunc, calcBase, sortDetail, itemType, build.spec.tree.nodes[nodeId])
		end

		-- Worker path
		local payload = jsonRoundTrip(PowerCalcTasks.notable.computeBatch(build,
			{ sortMode = "CombinedDPS", anointEnchantSlot = 1 },
			{ nodeIds = nodeIds },
			itemsTab.displayItem:BuildRaw(), nil))
		for _, nodeId in ipairs(nodeIds) do
			local workerPower = PowerCalcTasks.decodeNumber(payload.results[tostring(nodeId)])
			assert.True(numEq(ref[nodeId], workerPower), "measuredPower mismatch on node "..tostring(nodeId))
		end
	end)

	it("itemdb measureOne matches the worker batch path", function()
		-- Item DBs load over frames in the background
		local guard = 0
		while main.onFrameFuncs["LoadItems"] and guard < 1000 do
			runCallback("OnFrame")
			guard = guard + 1
		end
		local names = { }
		for name in pairs(main.uniqueDB.list) do
			table.insert(names, name)
			if #names >= 10 then
				break
			end
		end
		assert.True(#names > 0)

		local itemsTab = build.itemsTab
		local sortDetail = PowerCalcTasks.findSortDetail("Life")
		local calcFunc = build.calcsTab:GetMiscCalculator()
		local ref = { }
		for _, name in ipairs(names) do
			ref[name] = PowerCalcTasks.itemdb.measureOne(itemsTab, calcFunc, sortDetail, sortDetail.sortMode, false, main.uniqueDB.list[name])
		end

		local payload = jsonRoundTrip(PowerCalcTasks.itemdb.computeBatch(build,
			{ sortMode = "Life", dbType = "UNIQUE" },
			{ names = names }, "", nil))
		for _, name in ipairs(names) do
			local workerPower = PowerCalcTasks.decodeNumber(payload.results[name])
			assert.True(numEq(ref[name], workerPower), "measuredPower mismatch on item "..name)
		end
	end)

	it("compare descriptors compute identically through the worker entry point", function()
		local primaryFile = io.open("../spec/TestBuilds/3.13/OccVortex.xml", "r")
		local compareFile = io.open("../spec/TestBuilds/3.13/Mirage Archer Toxic Rain.xml", "r")
		assert.is_not_nil(primaryFile)
		assert.is_not_nil(compareFile)
		local primaryXml = primaryFile:read("*a")
		primaryFile:close()
		local compareXml = compareFile:read("*a")
		compareFile:close()

		loadBuildFromXML(primaryXml, "Primary")
		for i = 1, 5 do
			runCallback("OnFrame")
		end
		local compareTab = build.compareTab
		local compareEntry = new("CompareEntry", compareXml, "Comparison")
		compareEntry.xmlText = compareXml
		local powerStat = data.powerStatList[4] -- Combined DPS
		local categories = { treeNodes = true, items = true, skillGems = true, supportGems = true, config = true }

		-- Single-core reference (run the real coroutine to completion)
		local co = coroutine.create(function()
			compareTab:ComparePowerBuilder(compareEntry, powerStat, categories)
		end)
		repeat
			local res, errMsg = coroutine.resume(co)
			assert.True(res, errMsg)
		until coroutine.status(co) == "dead"
		local refResults = compareTab.comparePowerResults
		assert.True(#refResults > 0)

		-- Parallel simulation
		local descriptors = compareTab:EnumerateComparePowerCandidates(compareEntry, categories)
		for i, desc in ipairs(descriptors) do
			desc.i = i
		end
		local calcFunc, calcBase = compareTab.calcs.getMiscCalculator(build)
		local fmtCtx = compareTab:MakeComparePowerFormatContext(compareEntry, powerStat, calcBase)
		local resultByIndex = { }
		for _, slice in ipairs(ParallelRunner:PartitionList(descriptors, 3)) do
			local payload = jsonRoundTrip(PowerCalcTasks.compare.computeBatch(build,
				{ powerStatIndex = 4 }, { descriptors = slice }, compareXml, nil))
			for _, res in ipairs(payload.results) do
				resultByIndex[res.i] = res
			end
		end
		local parResults = { }
		for i, desc in ipairs(descriptors) do
			local res = resultByIndex[i]
			if res and res.ok and res.impact then
				local row = compareTab:BuildComparePowerRow(desc, PowerCalcTasks.decodeNumber(res.impact), res.extra or { }, fmtCtx)
				if row then
					table.insert(parResults, row)
				end
			end
		end

		assert.are.equals(#refResults, #parResults)
		for i = 1, #refResults do
			assert.are.equals(refResults[i].category, parResults[i].category)
			assert.are.equals(refResults[i].name, parResults[i].name)
			assert.True(numEq(refResults[i].impact, parResults[i].impact), "impact mismatch on row "..i)
			assert.are.equals(refResults[i].combinedImpactStr, parResults[i].combinedImpactStr)
		end
	end)
end)
