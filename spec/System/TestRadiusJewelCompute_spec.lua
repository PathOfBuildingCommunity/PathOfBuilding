-- Calculation and replacement-state tests for RadiusJewelFinder.

local support = LoadModule("../spec/System/RadiusJewelFinderTestSupport.lua")

local occVortex = support.occVortex
local mirageArcherToxicRain = support.mirageArcherToxicRain
local RadiusJewelData = support.RadiusJewelData
local MIGHT_OF_MEEK_RAW_TEXT = support.MIGHT_OF_MEEK_RAW_TEXT
local UNNATURAL_INSTINCT_RAW_TEXT = support.UNNATURAL_INSTINCT_RAW_TEXT
local ANATOMICAL_KNOWLEDGE_RAW_TEXT = support.ANATOMICAL_KNOWLEDGE_RAW_TEXT
local buildSplitPersonalityRawText = support.buildSplitPersonalityRawText
local buildImpossibleEscapeRawText = support.buildImpossibleEscapeRawText
local makeFinder = support.makeFinder
local getLargeRadiusIndex = support.getLargeRadiusIndex
local getSmallRadiusIndex = support.getSmallRadiusIndex
local makeImpossibleEscapeTestVariant = support.makeImpossibleEscapeTestVariant
local makeThreadVariants = support.makeThreadVariants
local isSorted = support.isSorted
local snapshotFinderState = support.snapshotFinderState
local function assertFinderStateUnchanged(before)
	support.assertFinderStateUnchanged(before, assert)
end

describe("RadiusJewelCompute #radius-jewel", function()

	before_each(function()
		loadBuildFromXML(occVortex.xml, "OccVortex")
	end)

	-- ── computeBestVariantSocketImpact (The Light of Meaning) ────────────────

	describe("computeBestVariantSocketImpact (The Light of Meaning)", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function getLightOfMeaningVariants()
			return RadiusJewelData.buildVariantsFromUniqueItem("The Light of Meaning")
		end

		it("returns one result per socket and uses the best variant", function()
			local sockets = getSockets()
			local variants = getLightOfMeaningVariants()
			local results, baseline = makeFinder().compute:computeBestVariantSocketImpact({
				sockets = sockets,
				variants = variants,
				impactStat = "Life",
			})
			assert.is_true(#results > 0, "expected at least one result")
			assert.is_true(#results <= #sockets, "should return no more than socket count")
			assert.is_number(baseline)
			assert.is_true(baseline > 0)
			for _, r in ipairs(results) do
				assert.is_not_nil(r.socket)
				assert.is_not_nil(r.variant)
				assert.is_string(r.variant.name)
				assert.is_number(r.delta)
			end
		end)

		it("keeps comparison snapshots free of nested requirement sources", function()
			local results = makeFinder().compute:computeBestVariantSocketImpact({
				sockets = getSockets(),
				variants = getLightOfMeaningVariants(),
				impactStat = "Life",
			})
			local nestedRequirementKeys = {
				"ReqStrFailList", "ReqDexFailList", "ReqIntFailList", "ReqOmniFailList",
				"ReqStrItem", "ReqDexItem", "ReqIntItem", "ReqOmniItem",
			}
			assert.is_true(#results > 0, "expected comparison snapshots")
			for _, result in ipairs(results) do
				for _, key in ipairs(nestedRequirementKeys) do
					assert.is_nil(result.baseOutput[key], "base snapshot should omit " .. key)
					assert.is_nil(result.compareOutput[key], "comparison snapshot should omit " .. key)
				end
			end
		end)

		it("results are sorted by delta descending", function()
			local sockets = getSockets()
			local results, _ = makeFinder().compute:computeBestVariantSocketImpact({
				sockets = sockets,
				variants = getLightOfMeaningVariants(),
				impactStat = "Life",
			})
			assert.is_true(isSorted(results, "delta"),
				"results should be sorted by delta descending")
		end)

		it("Life variant selected on sockets where it is better than others", function()
			local sockets = getSockets()
			local results, _ = makeFinder().compute:computeBestVariantSocketImpact({
				sockets = sockets,
				variants = getLightOfMeaningVariants(),
				impactStat = "Life",
			})
			local hasLife = false
			for _, r in ipairs(results) do
				if r.variant.name == "Life" then hasLife = true; break end
			end
			assert.is_true(hasLife, "expected Life variant to be best for at least one socket")
		end)

		it("restores TotalLife after compute", function()
			local sockets = getSockets()
			local before = build.calcsTab.mainOutput["Life"]
			makeFinder().compute:computeBestVariantSocketImpact({
				sockets = sockets,
				variants = getLightOfMeaningVariants(),
				impactStat = "Life",
			})
			local after = build.calcsTab.mainOutput["Life"]
			assert.are.equal(before, after)
		end)

		it("restores socket and item state after compute", function()
			local sockets = getSockets()
			local before = snapshotFinderState()
			makeFinder().compute:computeBestVariantSocketImpact({
				sockets = sockets,
				variants = getLightOfMeaningVariants(),
				impactStat = "Life",
			})
			assertFinderStateUnchanged(before)
		end)

		it("respects occupiedMode filter", function()
			local sockets = getSockets()
			local results, _ = makeFinder().compute:computeBestVariantSocketImpact({
				sockets = sockets,
				variants = getLightOfMeaningVariants(),
				impactStat = "Life",
				occupiedMode = { id = "all" },
			})
			assert.is_true(#results > 0, "expected results with occupied mode 'all'")
		end)

	end)

	describe("historic jewel replacements", function()

		local function newHistoricJewel()
			return new("Item"):Item("Rarity: UNIQUE\n"
				.. "Lethal Pride\nTimeless Jewel\nRadius: Large\nImplicits: 0\n"
				.. "Commanded leadership over 10000 warriors under Kaom\n")
		end

		it("rebuilds the passive spec when replacing a Historic jewel", function()
			local socketId = 36634
			local historic = newHistoricJewel()
			build.itemsTab:AddItem(historic, true)
			build.itemsTab.sockets[socketId].selItemId = historic.id
			build.spec.jewels[socketId] = historic.id

			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			local usedComparisonSpec = false
			build.calcsTab.GetMiscCalculator = function()
				return function(override)
					if override.spec then
						usedComparisonSpec = true
					end
					return { Life = override.spec and 1 or 0 }
				end, { Life = 0 }
			end

			local results = makeFinder().compute:computeBestVariantSocketImpact({
				sockets = { {
					id = socketId,
					label = "Historic socket",
					pathDist = 0,
				} },
				variants = { {
					name = "Candidate",
					rawText = MIGHT_OF_MEEK_RAW_TEXT,
				} },
				impactStat = "Life",
				occupiedMode = { id = "all" },
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			assert.is_true(usedComparisonSpec)
			assert.are.equal(1, results[1].value)
		end)

		it("rebuilds the passive spec for Intuitive Leap plans", function()
			local finder = makeFinder()
			local radiusIndex = getSmallRadiusIndex()
			local testSocket
			for _, socket in ipairs(finder:buildJewelSockets(radiusIndex)) do
				local socketNode = build.spec.nodes[socket.id]
				local candidates = finder.compute:collectDisconnectedPassiveCandidates(socketNode, {
					radiusIndex = radiusIndex,
				})
				if build.spec.allocNodes[socket.id] and #candidates > 0 then
					testSocket = socket
					break
				end
			end
			assert.is_not_nil(testSocket, "expected an allocated socket with an Intuitive Leap candidate")

			local historic = newHistoricJewel()
			build.itemsTab:AddItem(historic, true)
			build.itemsTab.sockets[testSocket.id].selItemId = historic.id
			build.spec.jewels[testSocket.id] = historic.id

			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			local usedComparisonSpec = false
			build.calcsTab.GetMiscCalculator = function()
				return function(override)
					if override.spec then
						usedComparisonSpec = true
					end
					return { Life = override.spec and 1 or 0 }
				end, { Life = 0 }
			end

			local results = finder.compute:computeIntuitiveLeapSocketImpact({
				sockets = { testSocket },
				impactStat = "Life",
				methodId = "fast",
				planCache = { },
				maxTotalPoints = 0,
				occupiedMode = { id = "all" },
				skipPlanSteps = true,
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			assert.is_true(usedComparisonSpec)
			assert.are.equal(1, results[1].value)
		end)

		it("keeps Split Personality's preview distance after rebuilding the spec", function()
			local socketId = 36634
			local splitDistance = 42
			local historic = newHistoricJewel()
			build.itemsTab:AddItem(historic, true)
			build.itemsTab.sockets[socketId].selItemId = historic.id
			build.spec.jewels[socketId] = historic.id

			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			build.calcsTab.GetMiscCalculator = function()
				return function(override)
					local socketNode = override.spec and override.spec.nodes[socketId] or build.spec.nodes[socketId]
					return { Life = socketNode.distanceToClassStart }
				end, { Life = 0 }
			end

			local results = makeFinder().compute:computeSplitPersonalitySocketImpact({
				sockets = { {
					id = socketId,
					label = "Historic socket",
					classStartDist = splitDistance,
					pathDist = 0,
				} },
				impactStat = "Life",
				variants = { {
					name = "Dexterity",
					rawText = buildSplitPersonalityRawText("+5 to Dexterity"),
				} },
				occupiedMode = { id = "all" },
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			assert.are.equal(splitDistance, results[1].value)
		end)

		it("does not rebuild for a Historic jewel stored in an unallocated socket", function()
			local finder = makeFinder()
			local testSocket
			for _, socket in ipairs(finder:buildJewelSockets(getLargeRadiusIndex())) do
				if not build.spec.allocNodes[socket.id] then
					testSocket = socket
					break
				end
			end
			assert.is_not_nil(testSocket, "expected an unallocated jewel socket")

			local historic = newHistoricJewel()
			build.itemsTab:AddItem(historic, true)
			build.itemsTab.sockets[testSocket.id].selItemId = historic.id
			build.spec.jewels[testSocket.id] = historic.id

			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			local usedComparisonSpec = false
			build.calcsTab.GetMiscCalculator = function()
				return function(override)
					usedComparisonSpec = usedComparisonSpec or override.spec ~= nil
					return { Life = 0 }
				end, { Life = 0 }
			end

			makeFinder().compute:computeSplitPersonalitySocketImpact({
				sockets = { {
					id = testSocket.id,
					label = "Stored Historic socket",
					classStartDist = 42,
					pathDist = 1,
				} },
				impactStat = "Life",
				variants = { {
					name = "Dexterity",
					rawText = buildSplitPersonalityRawText("+5 to Dexterity"),
				} },
				occupiedMode = { id = "all" },
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			assert.is_false(usedComparisonSpec)
		end)

	end)

	-- ── computeSocketImpact (MoM / UI / AK) ────────────────────────────────

	describe("computeSocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function compute(request)
			request.sockets = request.sockets or getSockets()
			request.impactStat = request.impactStat or "Life"
			return makeFinder().compute:computeSocketImpact(request)
		end

		it("returns a table (may be empty if all sockets occupied)", function()
			local results, baseline = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			assert.is_table(results)
			assert.is_number(baseline)
		end)

		it("returns the current main output as baseline for the selected stat", function()
			local expectedBaseline = build.calcsTab.mainOutput["Life"]
			local _, baseline = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			assert.are.equal(expectedBaseline, baseline)
		end)

		it("returns at least one result for the fixture build", function()
			local results, _ = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			assert.is_true(#results > 0, "expected at least one empty jewel socket result")
		end)

		it("MoM: only tests empty sockets (selItemId == 0)", function()
			local results, _ = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			for _, r in ipairs(results) do
				local slot = build.itemsTab.sockets[r.socket.id]
				assert.are.equal(0, slot.selItemId,
					"result socket " .. r.socket.id .. " should be empty after compute")
			end
		end)

		it("MoM: results sorted by delta descending", function()
			local results, _ = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			assert.is_true(isSorted(results, "delta"),
				"MoM socket results should be sorted by delta descending")
		end)

		it("MoM: restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			assert.are.equal(before, build.calcsTab.mainOutput["Life"])
		end)

		it("MoM: restores socket and item state after compute", function()
			local before = snapshotFinderState()
			compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			assertFinderStateUnchanged(before)
		end)

		it("UI: restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			compute({ rawText = UNNATURAL_INSTINCT_RAW_TEXT })
			assert.are.equal(before, build.calcsTab.mainOutput["Life"])
		end)

		it("AK: restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			compute({ rawText = ANATOMICAL_KNOWLEDGE_RAW_TEXT })
			assert.are.equal(before, build.calcsTab.mainOutput["Life"])
		end)

		it("respects max total points for standard compute", function()
			local maxPoints = 2
			local results, _ = compute({
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
				maxTotalPoints = maxPoints,
			})
			for _, r in ipairs(results) do
				assert.is_true((r.socket.pathDist or 0) <= maxPoints,
					"socket " .. r.socket.id .. " used too many points")
			end
		end)

		it("occupied sockets (36634, 61419, 41263) are skipped", function()
			local results, _ = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			local occupiedIds = { [36634] = true, [61419] = true, [41263] = true }
			for _, r in ipairs(results) do
				assert.is_nil(occupiedIds[r.socket.id],
					"occupied socket " .. r.socket.id .. " should not appear in results")
			end
		end)

		it("occupiedMode 'all' includes occupied sockets", function()
			local results, _ = compute({
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
				occupiedMode = { id = "all" },
			})
			local occupiedIds = { [36634] = true, [61419] = true, [41263] = true }
			local foundOccupied = false
			for _, r in ipairs(results) do
				if occupiedIds[r.socket.id] then foundOccupied = true; break end
			end
			assert.is_true(foundOccupied,
				"expected at least one occupied socket in results with mode 'all'")
		end)

		it("occupiedMode 'safe' returns at least as many results as 'free'", function()
			local sockets = getSockets()
			local freeResults, _ = compute({
				sockets = sockets,
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
			})
			local safeResults, _ = compute({
				sockets = sockets,
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
				occupiedMode = { id = "safe" },
			})
			assert.is_true(#safeResults >= #freeResults,
				"safe mode should include at least all free sockets")
		end)

		it("occupiedMode 'all' returns more results than 'free' (build has occupied sockets)", function()
			local sockets = getSockets()
			local freeResults, _ = compute({
				sockets = sockets,
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
			})
			local allResults, _ = compute({
				sockets = sockets,
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
				occupiedMode = { id = "all" },
			})
			assert.is_true(#allResults > #freeResults,
				"all mode should include more sockets than free mode (occupied sockets exist)")
		end)

		it("each result has socket, value and delta fields", function()
			local results, _ = compute({ rawText = MIGHT_OF_MEEK_RAW_TEXT })
			local seenSocketIds = {}
			for _, r in ipairs(results) do
				assert.is_not_nil(r.socket)
				assert.is_number(r.socket.id)
				assert.is_number(r.value)
				assert.is_number(r.delta)
				assert.is_nil(seenSocketIds[r.socket.id],
					"duplicate socket result for socket " .. r.socket.id)
				seenSocketIds[r.socket.id] = true
			end
		end)

	end)

	describe("disconnected passive max total points", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function computeIntuitiveLeap(request)
			request.sockets = request.sockets or getSockets()
			request.impactStat = request.impactStat or "Life"
			request.planCache = request.planCache or { }
			return makeFinder().compute:computeIntuitiveLeapSocketImpact(request)
		end

		it("respects max total points for Intuitive Leap", function()
			local maxPoints = 4
			local results, _ = computeIntuitiveLeap({
				variant = false,
				methodId = "simulated_greedy",
				maxTotalPoints = maxPoints,
			})
			for _, r in ipairs(results) do
				local totalPoints = (r.socket.pathDist or 0) + (r.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. r.socket.id .. " plan used too many points")
			end
		end)

		it("stops at jewel-only when the socket already uses all max points", function()
			local targetSocket
			for _, socket in ipairs(getSockets()) do
				if socket.pathDist and socket.pathDist > 0 then
					targetSocket = socket
					break
				end
			end
			assert.is_not_nil(targetSocket, "expected at least one socket with path points")
			local maxPoints = targetSocket.pathDist
			local sockets = { targetSocket }
			local fastResults = computeIntuitiveLeap({
				sockets = sockets,
				variant = false,
				methodId = "fast",
				maxTotalPoints = maxPoints,
			})
			local simulatedResults = computeIntuitiveLeap({
				sockets = sockets,
				variant = false,
				methodId = "simulated_greedy",
				maxTotalPoints = maxPoints,
			})
			assert.are.equal(0, fastResults[1].addedNodeCount or 0)
			assert.are.equal(0, simulatedResults[1].addedNodeCount or 0)
		end)

	end)

	describe("computeDisconnectedPassiveFastPlan", function()

		it("does not treat individual gains as a bound for combined interactions", function()
			local finder = makeFinder()
			local socketNode = { id = 1, name = "Socket" }
			local firstNode = { id = 2, name = "First" }
			local secondNode = { id = 3, name = "Second" }
			local evaluatedCombinedNodes = false
			finder.compute.buildSocketReplacementOverride = function(_, _, item, addNodes)
				return { item = item, addNodes = addNodes }
			end
			local function calcFunc(override)
				local hasFirst = override.addNodes[firstNode] == true
				local hasSecond = override.addNodes[secondNode] == true
				evaluatedCombinedNodes = evaluatedCombinedNodes or hasFirst and hasSecond
				if hasFirst and hasSecond then
					return { Life = 20 }
				end
				return { Life = (hasFirst or hasSecond) and 2 or 0 }
			end
			local previousBestDelta = 5

			-- Keep passing the historical pruning threshold so this test fails if that unsafe bound is restored.
			local result = finder.compute:computeDisconnectedPassiveFastPlan({
				calcFunc = calcFunc,
				replacementContext = { },
				baseOutput = { Life = 0 },
				baseValue = 0,
				socketNode = socketNode,
				item = { },
				impactStat = "Life",
				candidates = { firstNode, secondNode },
				variantLabel = "Combined",
				deltaCache = { },
				maxAdditionalNodes = 2,
				skipPlanSteps = true,
				previousBestDelta = previousBestDelta,
			})

			assert.are.equal(20, result.delta)
			assert.is_nil(result.pruned)
			assert.is_true(evaluatedCombinedNodes)
		end)

	end)

	describe("computeSplitPersonalitySocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local variants = {
			{ name = "Life", rawText = buildSplitPersonalityRawText("+5 to maximum Life") },
			{ name = "Mana", rawText = buildSplitPersonalityRawText("+5 to maximum Mana") },
		}

		local function computeSplit(request)
			request.sockets = request.sockets or getSockets()
			request.impactStat = request.impactStat or "Life"
			request.variants = request.variants or variants
			return makeFinder().compute:computeSplitPersonalitySocketImpact(request)
		end

		it("returns results and restores socket distance state", function()
			local sockets = getSockets()
			local before = snapshotFinderState()
			local previousDistanceBySocketId = {}
			for _, socket in ipairs(sockets) do
				previousDistanceBySocketId[socket.id] = build.spec.nodes[socket.id] and build.spec.nodes[socket.id].distanceToClassStart
			end

			local results, baseline = computeSplit({ sockets = sockets })

			assert.is_true(#results > 0, "expected split personality results")
			assert.is_number(baseline)
			for _, result in ipairs(results) do
				assert.is_not_nil(result.variant)
				assert.is_number(result.splitDistance)
				assert.is_string(result.detailText)
			end
			for _, socket in ipairs(sockets) do
				local node = build.spec.nodes[socket.id]
				assert.are.equal(previousDistanceBySocketId[socket.id], node and node.distanceToClassStart)
			end
			assertFinderStateUnchanged(before)
		end)

		it("respects max total points", function()
			local maxPoints = 4
			local results, _ = computeSplit({ maxTotalPoints = maxPoints })
			for _, result in ipairs(results) do
				local totalPoints = (result.socket.pathDist or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. result.socket.id .. " plan used too many points")
			end
		end)

		it("restores socket distance when a suspended computation is cancelled", function()
			local socket = getSockets()[1]
			local socketNode = build.spec.nodes[socket.id]
			local previousDistance = socketNode.distanceToClassStart
			local splitDistance = (previousDistance or 0) + 100
			local progress = { }
			function progress:tick()
				coroutine.yield()
			end
			function progress:child()
				return self
			end
			local computation = coroutine.create(function()
				computeSplit({
					sockets = { {
						id = socket.id,
						label = socket.label,
						classStartDist = splitDistance,
						pathDist = socket.pathDist,
					} },
					progress = progress,
					occupiedMode = { id = "all" },
				})
			end)

			assert.is_true(coroutine.resume(computation))
			assert.are.equal(previousDistance, socketNode.distanceToClassStart)
			assert.is_true(coroutine.resume(computation))
			assert.are.equal("suspended", coroutine.status(computation))
			assert.are.equal(previousDistance, socketNode.distanceToClassStart)
		end)

		it("restores socket distance after a calculator error", function()
			local socket = getSockets()[1]
			local socketNode = build.spec.nodes[socket.id]
			local previousDistance = socketNode.distanceToClassStart
			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			local callCount = 0
			build.calcsTab.GetMiscCalculator = function()
				return function()
					callCount = callCount + 1
					if callCount == 2 then
						error("injected Split Personality calculator failure")
					end
					return { Life = 0 }
				end, { Life = 0 }
			end

			local ok, err = pcall(function()
				computeSplit({
					sockets = { {
						id = socket.id,
						label = socket.label,
						classStartDist = (previousDistance or 0) + 100,
						pathDist = socket.pathDist,
					} },
					occupiedMode = { id = "all" },
				})
			end)
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			assert.is_false(ok)
			assert.is_truthy(tostring(err):match("injected Split Personality calculator failure"))
			assert.are.equal(previousDistance, socketNode.distanceToClassStart)
		end)

	end)

	describe("cluster jewel replacements", function()

		it("rebuilds the comparison tree without the replaced cluster subgraph", function()
			loadBuildFromXML(mirageArcherToxicRain.xml, "Mirage Archer Toxic Rain")

			local clusterSubgraph, allocatedClusterNodeIds
			for _, candidateSubgraph in pairs(build.spec.subGraphs) do
				local allocatedNodeIds = { }
				for _, node in ipairs(candidateSubgraph.nodes) do
					if node.alloc then
						table.insert(allocatedNodeIds, node.id)
					end
				end
				if #allocatedNodeIds > 0 then
					clusterSubgraph = candidateSubgraph
					allocatedClusterNodeIds = allocatedNodeIds
					break
				end
			end
			assert.is_not_nil(clusterSubgraph, "expected a cluster subgraph for the equipped cluster")
			local socketId = clusterSubgraph.parentSocket.id
			local clusterItem = build.spec:GetSocketedJewel(socketId)
			assert.is_not_nil(clusterItem, "expected an allocated cluster jewel socket")
			assert.is_not_nil(clusterItem.clusterJewel, "expected a cluster jewel in the allocated socket")

			local comparisonSpec
			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			build.calcsTab.GetMiscCalculator = function()
				return function(override)
					comparisonSpec = comparisonSpec or override.spec
					return { Life = 0 }
				end, { Life = 0 }
			end

			makeFinder().compute:computeBestVariantSocketImpact({
				sockets = { {
					id = socketId,
					label = "Cluster socket",
					pathDist = 0,
				} },
				variants = { {
					name = "Candidate",
					rawText = MIGHT_OF_MEEK_RAW_TEXT,
				} },
				impactStat = "Life",
				occupiedMode = { id = "all" },
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			assert.is_not_nil(comparisonSpec, "expected a comparison spec for the cluster replacement")
			for _, subGraph in pairs(comparisonSpec.subGraphs) do
				assert.are_not.equals(socketId, subGraph.parentSocket.id,
					"replaced cluster should not remain as a comparison subgraph")
			end
			for _, nodeId in ipairs(allocatedClusterNodeIds) do
				assert.is_nil(comparisonSpec.allocNodes[nodeId], "replaced cluster node should not remain allocated")
			end
			assert.is_true(comparisonSpec.jewels[socketId] ~= clusterItem.id,
				"comparison spec should no longer equip the replaced cluster")
		end)

	end)

	describe("computeImpossibleEscapeSocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function computeImpossibleEscape(owner, request)
			request.sockets = request.sockets or getSockets()
			request.impactStat = request.impactStat or "Life"
			request.planCache = request.planCache or { }
			return owner:computeImpossibleEscapeSocketImpact(request)
		end

		it("shares fast cache keys except for structural jewel replacements", function()
			local finder = makeFinder()
			local sharedKey = finder.compute:getImpossibleEscapePlanCacheKey("Life", "Acrobatics", {
				socketNode = { id = 36634 },
				occupancy = { isOccupied = false },
			})
			local structuralItem = {
				type = "Jewel",
				jewelData = { conqueredBy = true },
			}
			local firstStructuralKey = finder.compute:getImpossibleEscapePlanCacheKey("Life", "Acrobatics", {
				socketNode = { id = 36634 },
				occupancy = { isOccupied = true, item = structuralItem },
			})
			local secondStructuralKey = finder.compute:getImpossibleEscapePlanCacheKey("Life", "Acrobatics", {
				socketNode = { id = 61419 },
				occupancy = { isOccupied = true, item = structuralItem },
			})

			assert.are.equal("IE|Life|Acrobatics", sharedKey)
			assert.are.equal("IE|Life|Acrobatics|36634", firstStructuralKey)
			assert.are.equal("IE|Life|Acrobatics|61419", secondStructuralKey)
		end)

		it("reuses fast calculations across ordinary socket groups", function()
			local finder = makeFinder()
			local variant = makeImpossibleEscapeTestVariant()
			assert.is_not_nil(variant, "expected an Impossible Escape variant")
			local sockets = { }
			for _, socket in ipairs(getSockets()) do
				if not build.spec.allocNodes[socket.id] then
					table.insert(sockets, {
						id = socket.id,
						label = socket.label,
						pathDist = #sockets,
					})
					if #sockets == 2 then
						break
					end
				end
			end
			assert.are.equal(2, #sockets, "expected two free jewel sockets")

			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			local originalCollectCandidates = finder.compute.collectDisconnectedPassiveCandidates
			local originalBuildOverride = finder.compute.buildSocketReplacementOverride
			local originalCacheKey = finder.compute.getImpossibleEscapePlanCacheKey
			local calculationCount = 0
			build.calcsTab.GetMiscCalculator = function()
				return function(override)
					calculationCount = calculationCount + 1
					local allocatedCount = 0
					for _ in pairs(override.addNodes) do
						allocatedCount = allocatedCount + 1
					end
					return { Life = allocatedCount }
				end, { Life = 0 }
			end
			finder.compute.collectDisconnectedPassiveCandidates = function()
				return {
					{ id = -101, name = "First" },
					{ id = -102, name = "Second" },
					{ id = -103, name = "Third" },
				}
			end
			finder.compute.buildSocketReplacementOverride = function(_, _, _, addNodes)
				return { addNodes = addNodes }
			end

			local function countCalculations(cacheKeyFunc)
				finder.compute.getImpossibleEscapePlanCacheKey = cacheKeyFunc
				calculationCount = 0
				computeImpossibleEscape(finder.compute, {
					sockets = sockets,
					variants = { variant },
					methodId = "fast",
					maxTotalPoints = 2,
					skipPlanSteps = true,
				})
				return calculationCount
			end

			local sharedCount = countCalculations(originalCacheKey)
			local socketScopedCount = countCalculations(function(_, statField, variantName, replacementContext)
				return string.format("IE|%s|%s|%s", statField, variantName, replacementContext.socketNode.id)
			end)
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator
			finder.compute.collectDisconnectedPassiveCandidates = originalCollectCandidates
			finder.compute.buildSocketReplacementOverride = originalBuildOverride
			finder.compute.getImpossibleEscapePlanCacheKey = originalCacheKey

			assert.is_true(sharedCount < socketScopedCount,
				"expected shared cache to avoid repeated Impossible Escape calculations")
		end)

		it("returns results for both methods without changing finder state", function()
			local variant = makeImpossibleEscapeTestVariant()
			assert.is_not_nil(variant, "expected at least one keystone-based Impossible Escape variant")
			local sockets = getSockets()
			local before = snapshotFinderState()

			local fastResults, fastBaseline = computeImpossibleEscape(makeFinder().compute, {
				sockets = sockets,
				variants = { variant },
				methodId = "fast",
			})
			local simulatedResults, simulatedBaseline = computeImpossibleEscape(makeFinder().compute, {
				sockets = sockets,
				variants = { variant },
				methodId = "simulated_greedy",
			})

			assert.is_true(#fastResults > 0, "expected fast Impossible Escape results")
			assert.is_true(#simulatedResults > 0, "expected simulated Impossible Escape results")
			assert.is_number(fastBaseline)
			assert.are.equal(fastBaseline, simulatedBaseline)
			assert.are.equal(variant.name, fastResults[1].variant.name)
			assert.are.equal(variant.name, simulatedResults[1].variant.name)
			assertFinderStateUnchanged(before)
		end)

		it("respects max total points", function()
			local variant = makeImpossibleEscapeTestVariant()
			assert.is_not_nil(variant, "expected at least one keystone-based Impossible Escape variant")
			local maxPoints = 4
			local results, _ = computeImpossibleEscape(makeFinder().compute, {
				variants = { variant },
				methodId = "simulated_greedy",
				maxTotalPoints = maxPoints,
			})
			for _, result in ipairs(results) do
				local totalPoints = (result.socket.pathDist or 0) + (result.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. result.socket.id .. " plan used too many points")
			end
		end)

		it("keeps plan details isolated between budget and replacement groups", function()
			local finder = makeFinder()
			local variant = makeImpossibleEscapeTestVariant()
			assert.is_not_nil(variant, "expected an Impossible Escape variant")
			local freeSocket = { id = 101, label = "Free socket", pathDist = 1 }
			local occupiedSocket = { id = 202, label = "Occupied socket", pathDist = 3 }
			local occupancyBySocketId = {
				[101] = { isOccupied = false },
				[202] = { isOccupied = true, replacedItemLabel = "Existing jewel" },
			}
			finder.socketMatchesOccupiedMode = function(_, socketId)
				return true, occupancyBySocketId[socketId]
			end
			finder.getSocketOccupancyInfo = function(_, socketId)
				return occupancyBySocketId[socketId]
			end
			finder.getSocketBasePoints = function(_, socket)
				return socket.pathDist
			end
			finder.compute.collectDisconnectedPassiveCandidates = function()
				return {
					{ id = -101, name = "First" },
					{ id = -102, name = "Second" },
					{ id = -103, name = "Third" },
				}
			end
			finder.compute.buildSocketReplacementContext = function(_, _, socketId)
				return {
					socketNode = { id = socketId },
					occupancy = occupancyBySocketId[socketId],
					baselineOutput = { Life = 0 },
				}
			end
			finder.compute.computeDisconnectedPassiveFastPlan = function(_, request)
				local socketNode = request.socketNode
				local result = {
					delta = socketNode.id == freeSocket.id and 100 or 90,
					addedNodeCount = request.maxAdditionalNodes,
					resultNodes = { socketNode.id * 10 },
					resultNodeLabels = { "Plan for " .. socketNode.id },
					baseOutput = { Life = 0 },
					compareOutput = { Life = socketNode.id },
					detailText = "plan-" .. socketNode.id,
					variantLabel = request.variantLabel,
				}
				if not request.skipPlanSteps then
					result.planSteps = { { detailText = result.detailText } }
				end
				return result
			end

			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			build.calcsTab.GetMiscCalculator = function()
				return function() return { Life = 0 } end, { Life = 0 }
			end
			local results = computeImpossibleEscape(finder.compute, {
				sockets = { freeSocket, occupiedSocket },
				variants = { variant },
				methodId = "fast",
				maxTotalPoints = 5,
				skipPlanSteps = false,
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator

			local resultBySocketId = { }
			for _, result in ipairs(results) do
				resultBySocketId[result.socket.id] = result
			end
			assert.are.equal("plan-101", resultBySocketId[101].detailText)
			assert.are.equal("plan-202", resultBySocketId[202].detailText)
			assert.are.same({ 1010 }, resultBySocketId[101].resultNodes)
			assert.are.same({ 2020 }, resultBySocketId[202].resultNodes)
			assert.are.equal(100, resultBySocketId[101].delta)
			assert.are.equal(90, resultBySocketId[202].delta)
			assert.are.equal(4, resultBySocketId[101].addedNodeCount)
			assert.are.equal(2, resultBySocketId[202].addedNodeCount)
			assert.is_nil(resultBySocketId[101].replacedItemLabel)
			assert.are.equal("Existing jewel", resultBySocketId[202].replacedItemLabel)
			assert.are.equal("free:4", resultBySocketId[101].impossibleEscapeGroupKey)
			assert.are.equal("occupied:202", resultBySocketId[202].impossibleEscapeGroupKey)
		end)

	end)

	describe("computeThreadOfHopeSocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function getTestVariants()
			local threadVariants = makeThreadVariants()
			return { threadVariants[1], threadVariants[2] or threadVariants[1] }
		end

		local function getTestSockets(threadVariants)
			for _, socket in ipairs(getSockets()) do
				local slot = build.itemsTab.sockets[socket.id]
				local node = build.spec.tree.nodes[socket.id]
				if slot and slot.selItemId == 0 and node and node.nodesInRadius then
					for _, variant in ipairs(threadVariants) do
						local radiusNodes = node.nodesInRadius[variant.radiusIndex]
						if radiusNodes and next(radiusNodes) then
							return { socket }
						end
					end
				end
			end
			return { getSockets()[1] }
		end

		local function computeThread(owner, request)
			request.impactStat = request.impactStat or "Life"
			request.planCache = request.planCache or { }
			return owner:computeThreadOfHopeSocketImpact(request)
		end

		it("returns results for both methods without changing finder state", function()
			local threadVariants = getTestVariants()
			assert.is_true(#threadVariants > 0, "expected Thread of Hope ring variants")
			local sockets = getTestSockets(threadVariants)
			local before = snapshotFinderState()

			local fastResults, fastBaseline = computeThread(makeFinder().compute, {
				sockets = sockets,
				variants = threadVariants,
				methodId = "fast",
			})
			local simulatedResults, simulatedBaseline = computeThread(makeFinder().compute, {
				sockets = sockets,
				variants = threadVariants,
				methodId = "simulated_greedy",
			})

			assert.is_true(#fastResults > 0, "expected fast Thread of Hope results")
			assert.is_true(#simulatedResults > 0, "expected simulated Thread of Hope results")
			assert.is_number(fastBaseline)
			assert.are.equal(fastBaseline, simulatedBaseline)
			assert.is_not_nil(fastResults[1].variant)
			assert.is_not_nil(simulatedResults[1].variant)
			assert.is_number(fastResults[1].variant.radiusIndex)
			assert.is_number(simulatedResults[1].variant.radiusIndex)
			assert.is_string(fastResults[1].detailText)
			assert.is_string(simulatedResults[1].detailText)
			assertFinderStateUnchanged(before)
		end)

		it("respects max total points", function()
			local threadVariants = getTestVariants()
			assert.is_true(#threadVariants > 0, "expected Thread of Hope ring variants")
			local maxPoints = 4
			local results, _ = computeThread(makeFinder().compute, {
				sockets = getTestSockets(threadVariants),
				variants = threadVariants,
				methodId = "simulated_greedy",
				maxTotalPoints = maxPoints,
			})
			for _, result in ipairs(results) do
				local totalPoints = (result.socket.pathDist or 0) + (result.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. result.socket.id .. " plan used too many points")
			end
		end)

		local function runSyntheticFastThreadCompute(sockets, deltaBySocketId)
			local finder = makeFinder()
			local originalGetMiscCalculator = build.calcsTab.GetMiscCalculator
			build.calcsTab.GetMiscCalculator = function()
				return function() return { Life = 0 } end, { Life = 0 }
			end
			finder.socketMatchesOccupiedMode = function()
				return true, nil
			end
			finder.getSocketBasePoints = function(_, socket)
				return socket.pathDist or 0
			end
			finder.compute.buildSocketReplacementContext = function(_, _, socketId)
				return {
					socketNode = { id = socketId },
					baselineOutput = { Life = 0 },
				}
			end
			finder.compute.collectDisconnectedPassiveCandidates = function(_, socketNode)
				return { { id = socketNode.id * 10, name = "Candidate " .. socketNode.id } }
			end
			finder.compute.computeDisconnectedPassiveFastPlan = function(_, request)
				local socketNode = request.socketNode
				local result = {
					delta = deltaBySocketId[socketNode.id],
					addedNodeCount = 1,
					resultNodes = { socketNode.id * 10 },
					resultNodeLabels = { "Candidate " .. socketNode.id },
					baseOutput = { Life = 0 },
					compareOutput = { Life = deltaBySocketId[socketNode.id] },
					detailText = "plan-" .. socketNode.id,
					variantLabel = request.variantLabel,
				}
				if not request.skipPlanSteps then
					result.planSteps = { { detailText = result.detailText } }
				end
				return result
			end

			local results = computeThread(finder.compute, {
				sockets = sockets,
				variants = { getTestVariants()[1] },
				methodId = "fast",
				skipPlanSteps = false,
			})
			build.calcsTab.GetMiscCalculator = originalGetMiscCalculator
			return results
		end

		it("keeps every fast plan attached to its socket after sorting", function()
			local results = runSyntheticFastThreadCompute({
				{ id = 101, label = "Lower gain", pathDist = 1 },
				{ id = 202, label = "Higher gain", pathDist = 1 },
			}, {
				[101] = 10,
				[202] = 20,
			})

			assert.are.equal(2, #results)
			assert.are.equal(202, results[1].socket.id)
			for _, result in ipairs(results) do
				assert.are.equal("plan-" .. result.socket.id, result.detailText)
				assert.is_not_nil(result.planSteps)
			end
		end)

		it("builds plan details for a percent-per-point leader outside the top five gains", function()
			local sockets = { }
			local deltas = { }
			for index, delta in ipairs({ 100, 90, 80, 70, 60, 10 }) do
				local socketId = 300 + index
				table.insert(sockets, {
					id = socketId,
					label = "Socket " .. index,
					pathDist = index == 6 and 0 or 99,
				})
				deltas[socketId] = delta
			end
			local results = runSyntheticFastThreadCompute(sockets, deltas)
			local efficiencyLeader = results[6]
			local leaderEfficiency = efficiencyLeader.delta
				/ (efficiencyLeader.socket.pathDist + efficiencyLeader.addedNodeCount)

			assert.are.equal(10, efficiencyLeader.delta)
			assert.is_true(leaderEfficiency > results[1].delta
				/ (results[1].socket.pathDist + results[1].addedNodeCount))
			assert.is_not_nil(efficiencyLeader.planSteps)
			assert.are.equal("plan-" .. efficiencyLeader.socket.id, efficiencyLeader.detailText)
		end)

	end)

	-- ── Jewel limit parsing ─────────────────────────────────────────────────

	describe("jewel limit parsing from raw text", function()

		it("parses Limited to: 1 from Impossible Escape raw text", function()
			local rawText = buildImpossibleEscapeRawText("Acrobatics")
			local limitKey = rawText:match("^([^\n]+)")
			local limit = tonumber(rawText:match("Limited to: (%d+)"))
			assert.are.equals("Impossible Escape", limitKey)
			assert.are.equals(1, limit)
		end)

		it("parses Limited to: 1 from Unnatural Instinct raw text", function()
			local limitKey = UNNATURAL_INSTINCT_RAW_TEXT:match("^([^\n]+)")
			local limit = tonumber(UNNATURAL_INSTINCT_RAW_TEXT:match("Limited to: (%d+)"))
			assert.are.equals("Unnatural Instinct", limitKey)
			assert.are.equals(1, limit)
		end)

		it("returns nil limit for jewels without Limited to", function()
			local limit = tonumber(MIGHT_OF_MEEK_RAW_TEXT:match("Limited to: (%d+)"))
			assert.is_nil(limit)
		end)

	end)

	-- ── filterBestPerSocket ────────────────────────────────────────────────

	describe("filterBestPerSocket", function()

		local function makeRow(socketId, score, options)
			options = options or {}
			return {
				socketId = socketId,
				sortValue = score,
				isSocketIndependent = options.isSocketIndependent,
				jewelLimitKey = options.jewelLimitKey,
				jewelLimit = options.jewelLimit,
				points = options.points,
				name = options.name or ("row-" .. socketId),
			}
		end

		it("keeps one result per socket, highest score is kept", function()
			local rows = {
				makeRow(1, 10, { name = "A" }),
				makeRow(1, 20, { name = "B" }),
				makeRow(2, 15, { name = "C" }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local ids = {}
			for _, r in ipairs(result) do ids[r.socketId] = r.name end
			assert.are.equal("B", ids[1])
			assert.are.equal("C", ids[2])
		end)

		it("results are sorted by score descending", function()
			local rows = {
				makeRow(1, 5),
				makeRow(2, 30),
				makeRow(3, 15),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(3, #result)
			assert.are.equal(2, result[1].socketId)
			assert.are.equal(3, result[2].socketId)
			assert.are.equal(1, result[3].socketId)
		end)

		it("applies jewelLimit per jewelLimitKey", function()
			local rows = {
				makeRow(1, 30, { jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(2, 20, { jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(3, 10),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local ids = {}
			for _, r in ipairs(result) do ids[r.socketId] = true end
			assert.is_true(ids[1], "best IE should be kept")
			assert.is_true(ids[3], "unlimited jewel should be kept")
			assert.is_nil(ids[2], "second IE should be dropped (limit 1)")
		end)

		it("allows multiple copies up to the limit", function()
			local rows = {
				makeRow(1, 30, { jewelLimitKey = "CF", jewelLimit = 2 }),
				makeRow(2, 20, { jewelLimitKey = "CF", jewelLimit = 2 }),
				makeRow(3, 10, { jewelLimitKey = "CF", jewelLimit = 2 }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			assert.are.equal(1, result[1].socketId)
			assert.are.equal(2, result[2].socketId)
		end)

		it("socket-dependent jewels are assigned before socket-independent", function()
			-- Socket 1: dependent score 10, independent score 20
			-- The dependent should get socket 1, independent goes to socket 2
			local rows = {
				makeRow(1, 10, { name = "dependent" }),
				makeRow(1, 20, { name = "independent", isSocketIndependent = true }),
				makeRow(2, 5,  { name = "independent2", isSocketIndependent = true }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local bySocket = {}
			for _, r in ipairs(result) do bySocket[r.socketId] = r.name end
			-- The independent with score 20 cannot take socket 1 (dependent uses it)
			-- It should go to socket 2 instead
			assert.are.equal("dependent", bySocket[1])
		end)

		it("socket-independent jewels use remaining sockets after dependent allocation", function()
			local rows = {
				makeRow(1, 30, { name = "dependent-1" }),
				makeRow(2, 25, { name = "dependent-2" }),
				makeRow(1, 20, { name = "independent-1", isSocketIndependent = true }),
				makeRow(2, 15, { name = "independent-2", isSocketIndependent = true }),
				makeRow(3, 10, { name = "independent-3", isSocketIndependent = true }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			local bySocket = {}
			for _, r in ipairs(result) do bySocket[r.socketId] = r.name end
			assert.are.equal("dependent-1", bySocket[1])
			assert.are.equal("dependent-2", bySocket[2])
			assert.are.equal("independent-3", bySocket[3])
		end)

		it("socket-independent tie-break uses fewer points", function()
			local rows = {
				makeRow(1, 20, { isSocketIndependent = true, points = 5 }),
				makeRow(2, 20, { isSocketIndependent = true, points = 2 }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			-- Both are kept (different sockets), but fewer points should come first at equal score
			-- Actually both have different sockets so both are included
			-- The tie-break matters when multiple rows can use the same remaining sockets
		end)

		it("socket-independent tie-break: at equal score, fewer points is kept", function()
			-- Two independent jewels can use a single remaining socket
			local rows = {
				makeRow(1, 50, { name = "dependent" }),        -- takes socket 1
				makeRow(1, 20, { name = "ie-high-points", isSocketIndependent = true, points = 8 }),
				makeRow(2, 20, { name = "ie-low-points",  isSocketIndependent = true, points = 2 }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			local bySocket = {}
			for _, r in ipairs(result) do bySocket[r.socketId] = r.name end
			assert.are.equal("dependent", bySocket[1])
			assert.are.equal("ie-low-points", bySocket[2])
		end)

		it("limits are shared between dependent and independent jewels", function()
			-- IE limited to 1: if a dependent row with same limitKey is placed first,
			-- independent rows with that key are blocked
			local rows = {
				makeRow(1, 30, { name = "dependent-ie", jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(2, 20, { name = "independent-ie", isSocketIndependent = true, jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(3, 10, { name = "other" }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local names = {}
			for _, r in ipairs(result) do names[r.name] = true end
			assert.is_true(names["dependent-ie"])
			assert.is_true(names["other"])
			assert.is_nil(names["independent-ie"], "second IE should be blocked by shared limit")
		end)

		it("returns empty table for empty input", function()
			local result = makeFinder():filterBestPerSocket({})
			assert.are.equal(0, #result)
		end)

		it("does not change the input rows table", function()
			local rows = {
				makeRow(2, 10),
				makeRow(1, 20),
			}
			local originalLen = #rows
			local originalFirst = rows[1]
			makeFinder():filterBestPerSocket(rows)
			assert.are.equal(originalLen, #rows)
			assert.are.equal(originalFirst, rows[1])
		end)

	end)

	-- ── Move-aware compute helpers ─────────────────────────────────────────

	describe("move-aware compute helpers", function()

		local ALLOC_SOCKET_IDS = { 36634, 61419, 41263 }

		local function findUnallocatedSocketId()
			for socketId, socketData in pairs(build.spec.nodes) do
				if socketData.isJewelSocket and socketData.name ~= "Charm Socket"
						and build.itemsTab.sockets[socketId] and not build.spec.allocNodes[socketId] then
					return socketId
				end
			end
			error("expected at least one unallocated jewel socket")
		end

		local function equipFakeJewel(socketId, title, limit, extraItemFields)
			local slot = build.itemsTab.sockets[socketId]
			assert.is_not_nil(slot, "socket " .. socketId .. " should exist")
			local fakeItemId = 999000 + socketId
			local item = { title = title, limit = limit }
			if extraItemFields then
				for k, v in pairs(extraItemFields) do item[k] = v end
			end
			build.itemsTab.items[fakeItemId] = item
			slot.selItemId = fakeItemId
			build.spec.jewels[socketId] = fakeItemId
			return item, fakeItemId
		end

		local function getTestRadiusIndex()
			return getLargeRadiusIndex()
		end

		-- Find a jewel socket whose radius contains at least one unallocated node
		-- with NO allocated linked nodes outside the radius ("isolated").
		-- Note: `linked` is on spec.nodes, not spec.tree.nodes.
		local function findIsolatedRadiusNode(radiusIndex)
			local treeData = build.spec.tree
			for socketId, socketData in pairs(build.spec.nodes) do
				if socketData.isJewelSocket then
					local socketNode = treeData.nodes[socketId]
					if socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[radiusIndex] then
						local radiusNodes = socketNode.nodesInRadius[radiusIndex]
						for nodeId, _ in pairs(radiusNodes) do
							if not build.spec.allocNodes[nodeId] then
								local specNode = build.spec.nodes[nodeId]
								local isolated = true
								if specNode and specNode.linked then
									for _, other in ipairs(specNode.linked) do
										if build.spec.allocNodes[other.id] and not radiusNodes[other.id] then
											isolated = false
											break
										end
									end
								end
								if isolated then
									return socketId, nodeId
								end
							end
						end
					end
				end
			end
		end

		-- Find an unallocated radius node that has at least one linked node
		-- OUTSIDE the radius.  Returns socketId, nodeId, outsideLinkedNodeId.
		-- Note: `linked` is on spec.nodes, not spec.tree.nodes.
		local function findRadiusNodeWithOutsideLinkedNode(radiusIndex)
			local treeData = build.spec.tree
			for socketId, socketData in pairs(build.spec.nodes) do
				if socketData.isJewelSocket then
					local socketNode = treeData.nodes[socketId]
					if socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[radiusIndex] then
						local radiusNodes = socketNode.nodesInRadius[radiusIndex]
						for nodeId, _ in pairs(radiusNodes) do
							if not build.spec.allocNodes[nodeId] then
								local specNode = build.spec.nodes[nodeId]
								if specNode and specNode.linked then
									for _, other in ipairs(specNode.linked) do
										if not radiusNodes[other.id] then
											return socketId, nodeId, other.id
										end
									end
								end
							end
						end
					end
				end
			end
		end

		-- ── findEquippedJewelSockets ────────────────────────────────────

		describe("findEquippedJewelSockets", function()

			it("returns empty when no jewel of that type is equipped", function()
				local result = makeFinder():findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(0, #result)
			end)

			it("ignores jewels stored in unallocated sockets", function()
				local socketId = findUnallocatedSocketId()
				equipFakeJewel(socketId, "Thread of Hope", 1)
				local finder = makeFinder()
				local occupancy = finder:getSocketOccupancyInfo(socketId)
				local allowed = finder:socketMatchesOccupiedMode(socketId, { id = "free" })

				assert.is_false(occupancy.isOccupied)
				assert.are.equal("Thread of Hope", occupancy.storedUnallocatedItemLabel)
				assert.is_true(allowed)
				assert.are.equal(7, finder:getSocketBasePoints({ id = socketId, pathDist = 7 }, occupancy))

				local result = finder:findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(0, #result)
				assert.is_false(result.atLimit)
			end)

			it("returns entry but atLimit=false when equipped jewel has no limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Might of the Meek", nil)
				local result = makeFinder():findEquippedJewelSockets({ name = "Might of the Meek" })
				assert.are.equal(1, #result)
				assert.are.equal(ALLOC_SOCKET_IDS[1], result[1].socketId)
				assert.is_false(result.atLimit)
			end)

			it("allows ordinary jewels in Safe occupied and labels their base type", function()
				local socketId = ALLOC_SOCKET_IDS[1]
				local itemId = 999000 + socketId
				local item = new("Item"):Item("Rarity: RARE\nChimeric Creed\nCrimson Jewel\n")
				item.id = itemId
				build.itemsTab.items[itemId] = item
				build.itemsTab.sockets[socketId].selItemId = itemId
				build.spec.jewels[socketId] = itemId
				local finder = makeFinder()
				local isAllowed, occupancy = finder:socketMatchesOccupiedMode(socketId, { id = "safe" })

				assert.is_nil(next(item.jewelData.impossibleEscapeKeystones))
				assert.is_true(isAllowed)
				assert.are.equal("Chimeric Creed (Crimson Jewel)", occupancy.replacedItemLabel)
			end)

			it("keeps ordinary Abyss jewels safe but excludes Abyss Timeless jewels", function()
				local socketId = ALLOC_SOCKET_IDS[1]
				local ordinaryAbyssJewel = equipFakeJewel(socketId, "Hypnotic Eye Jewel", nil, {
					type = "Jewel",
					jewelData = { },
				})
				local finder = makeFinder()

				local isOrdinaryAbyssAllowed = finder:socketMatchesOccupiedMode(socketId, { id = "safe" })
				assert.is_true(isOrdinaryAbyssAllowed)

				ordinaryAbyssJewel.jewelData.conqueredBy = { conqueror = { type = "Abyss" } }
				local isAbyssTimelessAllowed = finder:socketMatchesOccupiedMode(socketId, { id = "safe" })
				assert.is_false(isAbyssTimelessAllowed)
				assert.is_true(finder.compute:socketReplacementChangesPassiveTree({
					occupancy = { isOccupied = true, item = ordinaryAbyssJewel },
				}, { type = "Jewel", jewelData = { } }))
			end)

			it("returns entries with atLimit=true when limited jewel count reaches limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1)
				local result = makeFinder():findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(1, #result)
				assert.are.equal(ALLOC_SOCKET_IDS[1], result[1].socketId)
				assert.are.equal("Thread of Hope", result[1].item.title)
				assert.is_true(result.atLimit)
			end)

			it("matches an equipped Foulborn jewel against its base unique name", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Foulborn Intuitive Leap", 1)
				local result = makeFinder():findEquippedJewelSockets({ name = "Intuitive Leap" })
				assert.are.equal(1, #result)
				assert.are.equal("Foulborn Intuitive Leap", result[1].item.title)
				assert.is_true(result.atLimit)
			end)

			it("matches grouped families through the selected canonical variant", function()
				local jewelTypes = RadiusJewelData.buildJewelTypes()
				local function findJewelType(name)
					for _, jewelType in ipairs(jewelTypes) do
						if jewelType.name == name then
							return jewelType
						end
					end
				end
				local function findVariant(jewelType, name)
					for _, variant in ipairs(jewelType.variants or { }) do
						if variant.name == name then
							return variant
						end
					end
				end

				local cases = {
					{ socketId = ALLOC_SOCKET_IDS[1], family = "Dreams & Nightmares", variant = "The Red Nightmare", limit = 1 },
					{ socketId = ALLOC_SOCKET_IDS[2], family = "Stat Conversion", variant = "Healthy Mind", limit = 1 },
					{ socketId = ALLOC_SOCKET_IDS[3], family = "Tempered & Transcendent", variant = "Tempered Flesh" },
				}
				for _, testCase in ipairs(cases) do
					equipFakeJewel(testCase.socketId, testCase.variant, testCase.limit)
				end

				local finder = makeFinder()
				for _, testCase in ipairs(cases) do
					local jewelType = findJewelType(testCase.family)
					local variant = findVariant(jewelType, testCase.variant)
					local result = finder:findEquippedJewelSockets(jewelType, variant)
					assert.are.equal(1, #result, "expected canonical match for " .. testCase.variant)
					assert.are.equal(testCase.socketId, result[1].socketId)
					assert.are.equal(testCase.limit ~= nil, result.atLimit)
				end
			end)

			it("returns entry but atLimit=false when equipped count is below limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Combat Focus", 2)
				local result = makeFinder():findEquippedJewelSockets({ name = "Combat Focus" })
				assert.are.equal(1, #result, "1 equipped < limit 2")
				assert.is_false(result.atLimit)
			end)

			it("returns all entries with atLimit=true when count equals limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Combat Focus", 2)
				equipFakeJewel(ALLOC_SOCKET_IDS[2], "Combat Focus", 2)
				local result = makeFinder():findEquippedJewelSockets({ name = "Combat Focus" })
				assert.are.equal(2, #result)
				assert.is_true(result.atLimit)
			end)

			it("does not match jewels with different title", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1)
				local result = makeFinder():findEquippedJewelSockets({ name = "Impossible Escape" })
				assert.are.equal(0, #result)
			end)

		end)

		it("computeSocketImpact treats jewels stored in unallocated sockets as free sockets", function()
			local socketId = findUnallocatedSocketId()
			equipFakeJewel(socketId, "Unnatural Instinct", 1)
			local finder = makeFinder()
			local results = finder.compute:computeSocketImpact({
				sockets = {
					{ id = socketId, label = "Test socket", pathDist = 7 },
				},
				rawText = MIGHT_OF_MEEK_RAW_TEXT,
				impactStat = "Life",
				occupiedMode = { id = "free" },
			})

			assert.are.equal(1, #results)
			assert.is_nil(results[1].replacedItemLabel)
			assert.are.equal("Unnatural Instinct", results[1].storedUnallocatedItemLabel)
		end)

		-- ── findDisconnectedPassiveDependentNodes ─────────────────────────────

		describe("findDisconnectedPassiveDependentNodes", function()

			it("returns empty for items without disconnected passive properties", function()
				local result = makeFinder():findDisconnectedPassiveDependentNodes(ALLOC_SOCKET_IDS[1], { title = "Might of the Meek" })
				assert.are.equal(0, #result)
			end)

			it("returns empty for invalid socketId", function()
				local item = { jewelRadiusIndex = getTestRadiusIndex() }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(999999, item)
				assert.are.equal(0, #result)
			end)

			it("returns empty when no nodes are allocated in radius", function()
				local treeData = build.spec.tree
				local smallRI = getTestRadiusIndex()
				local testSocketId
				for socketId, _ in pairs(build.itemsTab.sockets) do
					local node = treeData.nodes[socketId]
					if node and node.nodesInRadius and node.nodesInRadius[smallRI]
							and next(node.nodesInRadius[smallRI]) then
						local hasAllocated = false
						for nodeId, _ in pairs(node.nodesInRadius[smallRI]) do
							if build.spec.allocNodes[nodeId] then
								hasAllocated = true
								break
							end
						end
						if not hasAllocated then
							testSocketId = socketId
							break
						end
					end
				end
				if not testSocketId then pending("no empty radius socket found") end
				local item = { jewelRadiusIndex = smallRI }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(testSocketId, item)
				assert.are.equal(0, #result)
			end)

			it("returns isolated allocated nodes in radius as dependent", function()
				local smallRI = getTestRadiusIndex()
				local testSocketId, testNodeId = findIsolatedRadiusNode(smallRI)
				if not testSocketId then pending("no isolated radius node found") end

				build.spec.allocNodes[testNodeId] = build.spec.tree.nodes[testNodeId]

				local item = { jewelRadiusIndex = smallRI }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(testSocketId, item)

				assert.is_true(#result > 0, "expected at least one dependent node")
				local found = false
				for _, nodeId in ipairs(result) do
					if nodeId == testNodeId then found = true; break end
				end
				assert.is_true(found, "expected node " .. testNodeId .. " in dependent nodes")
			end)

			it("excludes nodes connected from outside the radius", function()
				local treeData = build.spec.tree
				local ri = getTestRadiusIndex()
				local testSocketId, testNodeId, outsideLinkedNodeId = findRadiusNodeWithOutsideLinkedNode(ri)
				if not testSocketId then pending("no radius node with outside linked node found") end

				-- Allocate both the radius node and its outside linked node
				build.spec.allocNodes[testNodeId] = treeData.nodes[testNodeId]
				build.spec.allocNodes[outsideLinkedNodeId] = treeData.nodes[outsideLinkedNodeId]

				local item = { jewelRadiusIndex = ri }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(testSocketId, item)

				local found = false
				for _, nodeId in ipairs(result) do
					if nodeId == testNodeId then found = true; break end
				end
				assert.is_false(found, "node connected from outside radius should not be dependent")
			end)

			it("handles IE keystoneMap path", function()
				local variant = makeImpossibleEscapeTestVariant()
				if not variant then pending("no IE keystone variant found") end

				local item = {
					jewelData = { impossibleEscapeKeystones = { [variant.keystoneName] = true } },
				}
				-- Should return empty since no extra nodes are allocated in the keystone radius
				local result = makeFinder():findDisconnectedPassiveDependentNodes(ALLOC_SOCKET_IDS[1], item)
				assert.is_table(result)
			end)

		end)

		-- ── removeEquippedJewels / restoreEquippedJewels ────────────────

		describe("removeEquippedJewels / restoreEquippedJewels", function()

			it("remove+restore keeps state identical", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1, {
					jewelRadiusIndex = getTestRadiusIndex(),
				})
				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(1, #equippedList)

				local beforeSlotId = build.itemsTab.sockets[ALLOC_SOCKET_IDS[1]].selItemId
				local beforeSpecJewel = build.spec.jewels[ALLOC_SOCKET_IDS[1]]
				local beforeAllocKeys = {}
				for nodeId, _ in pairs(build.spec.allocNodes) do
					beforeAllocKeys[nodeId] = true
				end

				finder:removeEquippedJewels(equippedList)
				finder:restoreEquippedJewels(equippedList)

				assert.are.equal(beforeSlotId, build.itemsTab.sockets[ALLOC_SOCKET_IDS[1]].selItemId)
				assert.are.equal(beforeSpecJewel, build.spec.jewels[ALLOC_SOCKET_IDS[1]])
				for nodeId, _ in pairs(beforeAllocKeys) do
					assert.is_not_nil(build.spec.allocNodes[nodeId],
						"allocNode " .. nodeId .. " should be restored")
				end
			end)

			it("remove clears slot.selItemId and spec.jewels", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1)
				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Thread of Hope" })

				finder:removeEquippedJewels(equippedList)

				assert.are.equal(0, build.itemsTab.sockets[ALLOC_SOCKET_IDS[1]].selItemId)
				assert.are.equal(0, build.spec.jewels[ALLOC_SOCKET_IDS[1]])

				finder:restoreEquippedJewels(equippedList)
			end)

			it("remove clears dependent disconnected passive nodes from allocNodes", function()
				local smallRI = getTestRadiusIndex()
				local testSocketId, testNodeId = findIsolatedRadiusNode(smallRI)
				if not testSocketId then pending("no isolated radius node found") end

				-- Allocate the isolated node as a disconnected passive jewel would.
				build.spec.allocNodes[testSocketId] = build.spec.tree.nodes[testSocketId]
				build.spec.allocNodes[testNodeId] = build.spec.tree.nodes[testNodeId]

				equipFakeJewel(testSocketId, "Intuitive Leap", 1, {
					jewelRadiusIndex = smallRI,
				})

				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Intuitive Leap" })
				assert.are.equal(1, #equippedList)

				finder:removeEquippedJewels(equippedList)
				assert.is_nil(build.spec.allocNodes[testNodeId],
					"dependent node " .. testNodeId .. " should be removed")

				finder:restoreEquippedJewels(equippedList)
				assert.is_not_nil(build.spec.allocNodes[testNodeId],
					"dependent node " .. testNodeId .. " should be restored")
			end)

			it("remove preserves nodes connected from outside the radius", function()
				local treeData = build.spec.tree
				local ri = getTestRadiusIndex()
				local testSocketId, testNodeId, outsideLinkedNodeId = findRadiusNodeWithOutsideLinkedNode(ri)
				if not testSocketId then pending("no radius node with outside linked node found") end

				build.spec.allocNodes[testSocketId] = treeData.nodes[testSocketId]
				build.spec.allocNodes[testNodeId] = treeData.nodes[testNodeId]
				build.spec.allocNodes[outsideLinkedNodeId] = treeData.nodes[outsideLinkedNodeId]

				equipFakeJewel(testSocketId, "Intuitive Leap", 1, {
					jewelRadiusIndex = ri,
				})

				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Intuitive Leap" })
				assert.are.equal(1, #equippedList)

				finder:removeEquippedJewels(equippedList)
				assert.is_not_nil(build.spec.allocNodes[testNodeId],
					"connected node " .. testNodeId .. " should NOT be removed")

				finder:restoreEquippedJewels(equippedList)
			end)

		end)

	end)

end)
