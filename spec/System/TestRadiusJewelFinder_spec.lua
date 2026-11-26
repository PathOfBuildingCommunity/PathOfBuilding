-- Calculation orchestration and result-state tests for RadiusJewelFinder.

local support = LoadModule("../spec/System/RadiusJewelFinderTestSupport.lua")
local occVortex = support.occVortex
local makeFinder = support.makeFinder
local getLargeRadiusIndex = support.getLargeRadiusIndex
local RadiusJewelData = support.RadiusJewelData
describe("RadiusJewelFinder #radius-jewel", function()

	before_each(function()
		loadBuildFromXML(occVortex.xml, "OccVortex")
	end)

	-- ── buildJewelSockets ───────────────────────────────────────────────────

	describe("buildJewelSockets", function()

		it("lists occupied and empty sockets in sorted order", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			assert.is_true(#sockets > 0, "expected at least one jewel socket")
			local seenIds = { }
			for index, socket in ipairs(sockets) do
				assert.is_number(socket.id)
				seenIds[socket.id] = true
				if index > 1 then
					assert.is_true(sockets[index - 1].label <= socket.label,
						"sockets not sorted at index " .. index)
				end
			end
			assert.is_true(seenIds[36634], "expected occupied socket 36634 to be present")
			assert.is_true(seenIds[61419], "expected occupied socket 61419 to be present")
			assert.is_true(seenIds[41263], "expected occupied socket 41263 to be present")
			assert.is_true(seenIds[33631], "expected empty socket 33631 to be present")
		end)
	end)

	describe("popup integration", function()
		local previousJewelRadius
		local previousMaxJewelRadius
		local syntheticAllocatedNodeIds
		local syntheticRadiusRestores

		before_each(function()
			previousJewelRadius = data.jewelRadius
			previousMaxJewelRadius = data.maxJewelRadius
			syntheticAllocatedNodeIds = { }
			syntheticRadiusRestores = { }
		end)

		after_each(function()
			while main.popups[1] do
				main:ClosePopup()
			end
			for index = #syntheticRadiusRestores, 1, -1 do
				syntheticRadiusRestores[index]()
			end
			for _, nodeId in ipairs(syntheticAllocatedNodeIds) do
				build.spec.allocNodes[nodeId] = nil
			end
			data.jewelRadius = previousJewelRadius
			data.maxJewelRadius = previousMaxJewelRadius
		end)

		local function findControlIndex(list, needle)
			for index, entry in ipairs(list) do
				local label = type(entry) == "table" and entry.label or entry
				if label == needle or (type(label) == "string" and label:find(needle, 1, true)) then
					return index
				end
			end
		end

		local function runPopupCompute(popup)
			popup.controls.computeButton:Click()
			while main.onFrameFuncs["RadiusJewelFinderCompute"] do
				runCallback("OnFrame")
			end
		end
		local function openResultContextTestPopup(yieldDuringCompute)
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local computeCompleted = false
			finder.buildJewelSockets = function()
				return { { id = 33631, label = "Synthetic socket", pathDist = 1 } }
			end
			finder.compute.computeBestIntuitiveLeapSocketImpact = function(_, request)
				request.planCache["result-context-test"] = request.methodId
				if yieldDuringCompute then
					coroutine.yield()
				end
				computeCompleted = true
				return {
					{
						socket = request.sockets[1],
						variant = request.variants[1],
						delta = 1,
						addedNodeCount = 0,
						baseOutput = { },
						compareOutput = { },
					},
				}, 100
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap"))
			return finder, popup, function() return computeCompleted end
		end

		local function findJewelType(name)
			for _, jewelType in ipairs(RadiusJewelData.buildJewelTypes()) do
				if jewelType.name == name then
					return jewelType
				end
			end
		end

		local function setSyntheticRadiusNodes(treeNode, radiusIndices, nodeType, count, allocated)
			local previousNodesInRadius = treeNode.nodesInRadius
			local previousNodesByRadius = { }
			for _, radiusIndex in ipairs(radiusIndices) do
				previousNodesByRadius[radiusIndex] = previousNodesInRadius and previousNodesInRadius[radiusIndex] or false
			end
			table.insert(syntheticRadiusRestores, function()
				if not previousNodesInRadius then
					treeNode.nodesInRadius = nil
					return
				end
				for _, radiusIndex in ipairs(radiusIndices) do
					local previousNodes = previousNodesByRadius[radiusIndex]
					previousNodesInRadius[radiusIndex] = previousNodes ~= false and previousNodes or nil
				end
			end)
			local nodes = { }
			for index = 1, count do
				local nodeId = -(treeNode.id * 10 + index)
				local node = {
					id = nodeId,
					name = "Synthetic " .. nodeType .. " " .. index,
					type = nodeType,
				}
				nodes[nodeId] = node
				if allocated then
					build.spec.allocNodes[nodeId] = node
					table.insert(syntheticAllocatedNodeIds, nodeId)
				end
			end
			treeNode.nodesInRadius = treeNode.nodesInRadius or { }
			for _, radiusIndex in ipairs(radiusIndices) do
				treeNode.nodesInRadius[radiusIndex] = nodes
			end
		end

		local function assertResultsCleared(popup, message)
			assert.are.equal(0, #popup.controls.resultsList.list, message)
		end

		local function assertResultContextRetained(popup, resultContextKey, expectedCount, message)
			assert.are.equal(expectedCount, #popup.controls.resultsList.list, message)
			assert.are.equal(resultContextKey, popup.controls.resultsList.list[1].resultContextKey, message)
		end
		it("sorts results using each mode column descriptor", function()
			build.radiusJewelFinderState = nil
			local resultsList = makeFinder():Open().controls.resultsList
			local rows = {
				{
					jewelName = "Zeta Jewel",
					socketLabel = "Zeta socket",
					points = 2,
					delta = 1,
					pct = 1,
					pctPerPoint = 0.5,
					sortValue = 0.5,
					score = 1,
					scorePerPoint = 0.5,
					variantLabel = "Large",
					action = "move",
					baseOutput = { },
					compareOutput = { },
				},
				{
					jewelName = "Alpha Jewel",
					socketLabel = "Alpha socket",
					points = 1,
					delta = 2,
					pct = 2,
					pctPerPoint = 2,
					sortValue = 2,
					score = 2,
					scorePerPoint = 2,
					variantLabel = "Small",
					action = "equip",
					baseOutput = { },
					compareOutput = { },
				},
			}
			local modeCases = {
				{ mode = "computeSocket", sortColumn = 3, expectedRow = rows[2] },
				{ mode = "computeSocketAll", sortColumn = 1, expectedRow = rows[2] },
				{ mode = "find", sortColumn = 3, expectedRow = rows[2] },
				{ mode = "findThread", sortColumn = 5, expectedRow = rows[1] },
			}

			for _, case in ipairs(modeCases) do
				local modeRows = { rows[1], rows[2] }
				resultsList:SetMode(case.mode, modeRows, "")
				resultsList:ReSort(case.sortColumn)
				assert.are.equal(case.expectedRow, modeRows[1], case.mode .. " sort should follow its column descriptor")
			end
		end)

		it("ranks Split Personality sockets by distance", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return {
					{ id = 33631, label = "Near split socket", pathDist = 1, classStartDist = 3 },
					{ id = 54127, label = "Far split socket", pathDist = 1, classStartDist = 9 },
				}
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Split Personality"))
			popup.controls.jewelVariantSelect.selFunc(2)
			popup.controls.findButton:Click()

			local row = popup.controls.resultsList.list[1]
			assert.are.equal(54127, row.socketId)
			assert.is_nil(row.topNodes)
		end)

		it("dispatches every jewel strategy to its compute owner", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local calls = { }
			local computeMethods = {
				"computeSocketImpact",
				"computeBestVariantSocketImpact",
				"computeBestIntuitiveLeapSocketImpact",
				"computeThreadOfHopeSocketImpact",
				"computeImpossibleEscapeSocketImpact",
				"computeSplitPersonalitySocketImpact",
			}
			for _, methodName in ipairs(computeMethods) do
				local capturedMethodName = methodName
				finder.compute[capturedMethodName] = function(_, request)
					table.insert(calls, { methodName = capturedMethodName, request = request })
					return { }, 100
				end
			end

			local popup = finder:Open()
			local cases = {
				{ jewelType = "Might of the Meek", methodName = "computeSocketImpact", field = "rawText" },
				{ jewelType = "The Light of Meaning", methodName = "computeBestVariantSocketImpact", field = "variants" },
				{ jewelType = "Intuitive Leap", methodName = "computeBestIntuitiveLeapSocketImpact", field = "variants" },
				{ jewelType = "Thread of Hope", methodName = "computeThreadOfHopeSocketImpact", field = "variants" },
				{ jewelType = "Impossible Escape", methodName = "computeImpossibleEscapeSocketImpact", field = "variants" },
				{ jewelType = "Split Personality", methodName = "computeSplitPersonalitySocketImpact", field = "variants" },
			}
			for _, case in ipairs(cases) do
				calls = { }
				popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, case.jewelType))
				runPopupCompute(popup)
				assert.is_true(#calls > 0, "expected a compute call for " .. case.jewelType)
				for _, call in ipairs(calls) do
					assert.are.equal(case.methodName, call.methodName, "unexpected compute owner for " .. case.jewelType)
					assert.is_not_nil(call.request[case.field], "missing " .. case.field .. " for " .. case.jewelType)
				end
			end

			calls = { }
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "All jewels"))
			runPopupCompute(popup)
			local seenMethods = { }
			local expandedPlanMethods = {
				computeBestIntuitiveLeapSocketImpact = true,
				computeThreadOfHopeSocketImpact = true,
				computeImpossibleEscapeSocketImpact = true,
			}
			for _, call in ipairs(calls) do
				seenMethods[call.methodName] = true
				if expandedPlanMethods[call.methodName] then
					assert.is_true(call.request.skipPlanSteps, "All jewels should skip expanded plan steps")
				end
			end
			for _, methodName in ipairs(computeMethods) do
				assert.is_true(seenMethods[methodName], "All jewels did not dispatch " .. methodName)
			end
		end)

		it("uses the canonical Massive radius for Foulborn Intuitive Leap Find", function()
			data.setJewelRadiiGlobally("3_29")
			local massiveRadiusIndex = RadiusJewelData.getJewelRadiusIndex("Massive")
			local syntheticSocketId = 990001
			local syntheticKeystone = { id = 990002, type = "Keystone", name = "Synthetic Keystone" }
			local treeNodes = build.spec.tree.nodes
			local previousSocket = treeNodes[syntheticSocketId]
			table.insert(syntheticRadiusRestores, function() treeNodes[syntheticSocketId] = previousSocket end)
			treeNodes[syntheticSocketId] = {
				id = syntheticSocketId,
				nodesInRadius = {
					[massiveRadiusIndex] = { [syntheticKeystone.id] = syntheticKeystone },
				},
			}
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return { { id = syntheticSocketId, label = "Synthetic socket", pathDist = 1 } }
			end
			local popup = finder:Open()
			local function findIndex(list, needle)
				for index, entry in ipairs(list) do
					local label = type(entry) == "table" and entry.label or entry
					if label == needle or (type(label) == "string" and label:find(needle, 1, true)) then
						return index
					end
				end
			end

			popup.controls.jewelTypeSelect.selFunc(findIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap"))
			popup.controls.jewelVariantSelect.selFunc(findIndex(popup.controls.jewelVariantSelect.list, "Foulborn:"))
			popup.controls.findButton:Click()

			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.are.equal(1, popup.controls.resultsList.list[1].score)
		end)

		it("attaches action plans to Thread of Hope Find and Compute results", function()
			local targetSocketId = 33631
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return { { id = targetSocketId, label = "Target socket", pathDist = 1 } }
			end
			local popup = finder:Open()
			local function findIndex(list, needle)
				for index, entry in ipairs(list) do
					local label = type(entry) == "table" and entry.label or entry
					if label == needle then
						return index
					end
				end
			end

			popup.controls.jewelTypeSelect.selFunc(findIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope"))
			popup.controls.findButton:Click()
			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.is_not_nil(popup.controls.resultsList.list[1].actionPlan,
				"Find rows should consume the shared action planner")
			assert.matches("^Thread of Hope\n", popup.controls.resultsList.list[1].actionPlan.targetRawText)

			finder.compute.computeThreadOfHopeSocketImpact = function(_, request)
				return {
					{
						socket = request.sockets[1],
						variant = request.variants[1],
						delta = 1,
						addedNodeCount = 0,
						baseOutput = { },
						compareOutput = { },
					},
				}, 100
			end
			popup.controls.computeButton:Click()
			while main.onFrameFuncs["RadiusJewelFinderCompute"] do
				runCallback("OnFrame")
			end
			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.is_not_nil(popup.controls.resultsList.list[1].actionPlan,
				"Compute rows should consume the shared action planner")
			assert.matches("^Thread of Hope\n", popup.controls.resultsList.list[1].actionPlan.targetRawText)

		end)

		it("invalidates result actions when criteria change without starting Compute", function()
			local _, popup = openResultContextTestPopup()
			local intuitiveLeapIndex = findControlIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap")
			local threadOfHopeIndex = findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope")

			local changes = {
				{
					name = "variant",
					change = function() popup.controls.jewelVariantSelect.selFunc(2) end,
					restore = function() popup.controls.jewelVariantSelect.selFunc(1) end,
				},
				{
					name = "impact stat",
					change = function() popup.controls.impactStatSelect.selFunc(2) end,
					restore = function() popup.controls.impactStatSelect.selFunc(1) end,
				},
				{
					name = "compute method",
					change = function() popup.controls.computeMethodSelect.selFunc(2) end,
					restore = function() popup.controls.computeMethodSelect.selFunc(1) end,
				},
				{
					name = "max points",
					change = function() popup.controls.maxPointsEdit:SetText("21", true) end,
					restore = function() popup.controls.maxPointsEdit:SetText("20", true) end,
				},
				{
					name = "occupied sockets",
					change = function() popup.controls.occupiedModeSelect.selFunc(2) end,
					restore = function() popup.controls.occupiedModeSelect.selFunc(1) end,
				},
				{
					name = "jewel type",
					change = function() popup.controls.jewelTypeSelect.selFunc(threadOfHopeIndex) end,
					restore = function() popup.controls.jewelTypeSelect.selFunc(intuitiveLeapIndex) end,
				},
			}
			for _, criterion in ipairs(changes) do
				runPopupCompute(popup)
				local staleRow = popup.controls.resultsList.list[1]
				assert.is_not_nil(staleRow)
				criterion.change()
				assertResultContextRetained(popup, staleRow.resultContextKey, 1,
					criterion.name .. " should retain the previous result data")
				assert.is_nil(main.onFrameFuncs["RadiusJewelFinderCompute"],
					criterion.name .. " should not start Compute automatically")
				local beforeApply = support.snapshotFinderState()
				popup.controls.resultsList.OnSelClick(popup.controls.resultsList, 1, staleRow, true)
				support.assertFinderStateUnchanged(beforeApply, assert)
				criterion.restore()
			end
		end)

		it("filters standard Find by Points and keeps Score independent", function()
			build.radiusJewelFinderState = nil
			local jewelType = findJewelType("Might of the Meek")
			assert.is_not_nil(jewelType)
			setSyntheticRadiusNodes(build.spec.tree.nodes[36634], { jewelType.radiusIndex }, "Normal", 3, true)
			setSyntheticRadiusNodes(build.spec.tree.nodes[33631], { jewelType.radiusIndex }, "Normal", 3, true)

			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return {
					{ id = 36634, label = "Occupied zero-cost socket", pathDist = 9 },
					{ id = 33631, label = "Within Max points socket", pathDist = 1 },
					{ id = 33631, label = "Above Max points socket", pathDist = 2 },
				}
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Might of the Meek"))
			popup.controls.occupiedModeSelect.selFunc(3)
			popup.controls.maxPointsEdit:SetText("1", true)
			popup.controls.findButton:Click()

			assert.are.equal(2, #popup.controls.resultsList.list)
			local maxPointsOneContextKey = popup.controls.resultsList.list[1].resultContextKey
			local sawZeroCost = false
			for _, row in ipairs(popup.controls.resultsList.list) do
				assert.is_true(row.points <= 1, "Find returned a row above Max points")
				assert.are.equal(3, row.score)
				assert.is_true(row.score > 1, "Score should not be capped by Max points")
				sawZeroCost = sawZeroCost or row.points == 0
			end
			assert.is_true(sawZeroCost, "expected the occupied zero-cost socket to remain eligible")
			popup.controls.maxPointsEdit:SetText("0", true)
			popup.controls.findButton:Click()
			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.are.equal(0, popup.controls.resultsList.list[1].points)

			popup.controls.maxPointsEdit:SetText("1", true)
			popup.controls.findButton:Click()
			assert.are.equal(2, #popup.controls.resultsList.list)
			assert.are.equal(maxPointsOneContextKey, popup.controls.resultsList.list[1].resultContextKey)
		end)

		it("applies Max points to Thread Find including zero-result searches", function()
			build.radiusJewelFinderState = nil
			local socketId = 33631
			local radiusIndices = { }
			for _, variant in ipairs(RadiusJewelData.getThreadOfHopeVariants()) do
				table.insert(radiusIndices, variant.radiusIndex)
			end
			setSyntheticRadiusNodes(build.spec.tree.nodes[socketId], radiusIndices, "Notable", 4, false)
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return { { id = socketId, label = "Thread Max points socket", pathDist = 2 } }
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope"))
			popup.controls.maxPointsEdit:SetText("1", true)
			popup.controls.findButton:Click()

			assert.are.equal(0, #popup.controls.resultsList.list)

			popup.controls.maxPointsEdit:SetText("2", true)
			popup.controls.findButton:Click()
			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.are.equal(2, popup.controls.resultsList.list[1].points)
			assert.is_true(popup.controls.resultsList.list[1].score > 0)
		end)

		it("applies Max points to Impossible Escape Find", function()
			build.radiusJewelFinderState = nil
			local jewelType = findJewelType("Impossible Escape")
			local variant = jewelType and jewelType.variants[1]
			local keystoneNode = variant and build.spec.tree.keystoneMap[variant.keystoneName]
			assert.is_not_nil(keystoneNode)
			setSyntheticRadiusNodes(keystoneNode, { RadiusJewelData.getJewelRadiusIndex("Small") }, "Notable", 4, false)
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return { { id = 33631, label = "Impossible Escape Max points socket", pathDist = 3 } }
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape"))
			popup.controls.maxPointsEdit:SetText("2", true)
			popup.controls.findButton:Click()

			assert.are.equal(0, #popup.controls.resultsList.list)

			popup.controls.maxPointsEdit:SetText("3", true)
			popup.controls.findButton:Click()
			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.are.equal(3, popup.controls.resultsList.list[1].points)
		end)


		it("tracks grouped variants and the legacy All jewels option in result identity", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return { { id = 33631, label = "Synthetic socket", pathDist = 1 } }
			end
			finder.compute.computeBestVariantSocketImpact = function(_, request)
				return {
					{
						socket = request.sockets[1],
						variant = request.variants[1],
						delta = 1,
						baseOutput = { },
						compareOutput = { },
					},
				}, 100
			end
			finder.compute.computeSocketImpact = function() return { }, 100 end
			finder.compute.computeBestIntuitiveLeapSocketImpact = function() return { }, 100 end
			finder.compute.computeThreadOfHopeSocketImpact = function() return { }, 100 end
			finder.compute.computeImpossibleEscapeSocketImpact = function() return { }, 100 end
			finder.compute.computeSplitPersonalitySocketImpact = function() return { }, 100 end

			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares"))
			runPopupCompute(popup)
			local groupedContextKey = popup.controls.resultsList.list[1].resultContextKey
			local groupedResultCount = #popup.controls.resultsList.list

			popup.controls.variantGroupSelect.selFunc(2)
			runPopupCompute(popup)
			assert.are_not.equal(groupedContextKey, popup.controls.resultsList.list[1].resultContextKey)
			popup.controls.variantGroupSelect.selFunc(1)
			runPopupCompute(popup)
			assert.are.equal(groupedResultCount, #popup.controls.resultsList.list)
			assert.are.equal(groupedContextKey, popup.controls.resultsList.list[1].resultContextKey)

			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "All jewels"))
			runPopupCompute(popup)
			local allJewelsContextKey = popup.controls.resultsList.list[1].resultContextKey
			local allJewelsResultCount = #popup.controls.resultsList.list
			popup.controls.allJewelsViewSelect.selFunc(2)
			assert.is_true(#popup.controls.resultsList.list <= allJewelsResultCount)
			popup.controls.allJewelsViewSelect.selFunc(1)
			assert.are.equal(allJewelsResultCount, #popup.controls.resultsList.list)

			popup.controls.showLegacyCheck.changeFunc(true)
			for _, viewIndex in ipairs({ 2, 1 }) do
				popup.controls.allJewelsViewSelect.selFunc(viewIndex)
				assertResultContextRetained(popup, allJewelsContextKey, allJewelsResultCount,
					"changing the All-jewels view should retain the previous result data")
			end
			runPopupCompute(popup)
			assert.are_not.equal(allJewelsContextKey, popup.controls.resultsList.list[1].resultContextKey)
			popup.controls.showLegacyCheck.changeFunc(false)
			runPopupCompute(popup)
			assert.are.equal(allJewelsResultCount, #popup.controls.resultsList.list)
			assert.are.equal(allJewelsContextKey, popup.controls.resultsList.list[1].resultContextKey)
		end)

		it("filters Thread Find and Compute by the selected ring", function()
			local threadVariants = RadiusJewelData.getThreadOfHopeVariants()
			local targetSocketId = 33631
			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return { { id = targetSocketId, label = "Target socket", pathDist = 1 } }
			end
			local computedVariants
			finder.compute.computeThreadOfHopeSocketImpact = function(_, request)
				computedVariants = request.variants
				return {
					{
						socket = request.sockets[1],
						variant = request.variants[1],
						delta = 1,
						addedNodeCount = 0,
						baseOutput = { },
						compareOutput = { },
					},
				}, 100
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope"))
			popup.controls.findButton:Click()
			local findRow = popup.controls.resultsList.list[1]
			assert.is_not_nil(findRow)
			local anyRingContextKey = findRow.resultContextKey

			popup.controls.threadVariantSelect.selFunc(2)
			popup.controls.findButton:Click()
			local explicitRingRow = popup.controls.resultsList.list[1]

			assert.are_not.equal(anyRingContextKey, explicitRingRow.resultContextKey)

			runPopupCompute(popup)
			local row = popup.controls.resultsList.list[1]
			assert.is_not_nil(row)
			assert.are.equal(1, #computedVariants)
			assert.are.equal(threadVariants[1].name, computedVariants[1].name)

			popup.controls.threadVariantSelect.selFunc(1)

			assert.is_nil(build.radiusJewelFinderState.threadVariantName)
		end)

		it("retains an explicit Thread ring in saved finder state", function()
			local finder = makeFinder()
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope"))
			popup.controls.threadVariantSelect.selFunc(2)
			popup.controls.findButton:Click()
			popup.controls.closeButton:Click()
			finder:Open()

			assert.are.equal(RadiusJewelData.getThreadOfHopeVariants()[1].name,
				build.radiusJewelFinderState.threadVariantName)
		end)

		it("cancels a suspended Compute when a result criterion changes", function()
			local _, popup, computeCompleted = openResultContextTestPopup(true)
			popup.controls.computeButton:Click()
			runCallback("OnFrame")
			assert.is_not_nil(main.onFrameFuncs["RadiusJewelFinderCompute"])
			assert.is_false(computeCompleted())

			popup.controls.impactStatSelect.selFunc(2)

			assert.is_nil(main.onFrameFuncs["RadiusJewelFinderCompute"])
			assert.is_false(computeCompleted())
			assertResultsCleared(popup)
		end)

		it("cancels a suspended Compute after a build revision", function()
			local _, popup, computeCompleted = openResultContextTestPopup(true)
			popup.controls.computeButton:Click()
			runCallback("OnFrame")
			assert.is_not_nil(main.onFrameFuncs["RadiusJewelFinderCompute"])

			build.outputRevision = build.outputRevision + 1
			runCallback("OnFrame")

			assert.is_nil(main.onFrameFuncs["RadiusJewelFinderCompute"])
			assert.is_false(computeCompleted())
			assertResultsCleared(popup)
		end)

		it("blocks stale Apply after a build revision", function()
			local finder, popup = openResultContextTestPopup()
			runPopupCompute(popup)
			local staleRow = popup.controls.resultsList.list[1]
			assert.is_not_nil(staleRow)
			popup.controls.resultsList.selIndex = 1

			popup.controls.closeButton:Click()
			build.outputRevision = build.outputRevision + 1
			local beforeApply = support.snapshotFinderState()
			popup.controls.resultsList.OnSelClick(popup.controls.resultsList, 1, staleRow, true)
			support.assertFinderStateUnchanged(beforeApply, assert)

			local reopenedPopup = finder:Open()
			assertResultsCleared(reopenedPopup)
		end)

		it("isolates grouped limit identities for All variants and All jewels Compute", function()
			local sourceSocketId = 36634
			local targetSocketId = 61419
			local sourceSlot = build.itemsTab.sockets[sourceSocketId]
			local targetSlot = build.itemsTab.sockets[targetSocketId]
			assert.is_not_nil(sourceSlot)
			assert.is_not_nil(targetSlot)
			local redNightmare
			for _, jewelType in ipairs(RadiusJewelData.buildJewelTypes()) do
				if jewelType.name == "Dreams & Nightmares" then
					for _, variant in ipairs(jewelType.variants) do
						if variant.variantIdentity.limitKey == "The Red Nightmare" and not variant.isFoulborn then
							redNightmare = variant
							break
						end
					end
				end
			end
			assert.is_not_nil(redNightmare)
			local equippedItem = new("Item"):Item("Rarity: Unique\n" .. redNightmare.rawText)
			equippedItem:BuildModList()
			build.itemsTab:AddItem(equippedItem, true)
			sourceSlot:SetSelItemId(equippedItem.id)
			targetSlot:SetSelItemId(0)
			build.itemsTab:PopulateSlots()
			local equippedItemId = equippedItem.id

			local finder = makeFinder()
			finder.buildJewelSockets = function()
				return {
					{ id = sourceSocketId, label = "Source socket", pathDist = 1 },
					{ id = targetSocketId, label = "Target socket", pathDist = 2 },
				}
			end

			local observedPartitions = { }
			finder.compute.computeBestVariantSocketImpact = function(_, request)
				local identity = request.variants[1].variantIdentity
				local limitKey = identity.limitKey
				for _, variant in ipairs(request.variants) do
					assert.are.equal(limitKey, variant.variantIdentity.limitKey,
						"each compute call should contain one canonical limit partition")
				end
				if identity.family ~= "Dreams & Nightmares" then
					return { }, 100
				end
				observedPartitions[limitKey] = sourceSlot.selItemId
				local sourceDelta = limitKey == "The Red Nightmare" and 10 or 1
				local targetDelta = limitKey == "The Red Nightmare" and 15 or 2
				return {
					{ socket = request.sockets[1], variant = request.variants[1], delta = sourceDelta, baseOutput = { }, compareOutput = { } },
					{ socket = request.sockets[2], variant = request.variants[1], delta = targetDelta, baseOutput = { }, compareOutput = { } },
				}, 100
			end
			finder.compute.computeSocketImpact = function() return { }, 100 end
			finder.compute.computeBestIntuitiveLeapSocketImpact = function() return { }, 100 end
			finder.compute.computeThreadOfHopeSocketImpact = function() return { }, 100 end
			finder.compute.computeImpossibleEscapeSocketImpact = function() return { }, 100 end
			finder.compute.computeSplitPersonalitySocketImpact = function() return { }, 100 end

			local popup = finder:Open()
			local function findIndex(list, needle)
				for index, entry in ipairs(list) do
					local label = type(entry) == "table" and entry.label or entry
					if label == needle then
						return index
					end
				end
			end
			local function runCompute()
				popup.controls.computeButton:Click()
				while main.onFrameFuncs["RadiusJewelFinderCompute"] do
					runCallback("OnFrame")
				end
			end
			local function assertCanonicalPartitioning()
				assert.are.equal(0, observedPartitions["The Red Nightmare"],
					"matching limited unique should be removed for its partition")
				assert.are.equal(equippedItemId, observedPartitions["The Green Dream"],
					"other unique partitions should retain the equipped jewel")
				assert.are.equal(equippedItemId, sourceSlot.selItemId, "equipped jewel should be restored")
				assert.are.equal(equippedItemId, build.spec.jewels[sourceSocketId])
			end

			popup.controls.jewelTypeSelect.selFunc(findIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares"))
			runCompute()
			assertCanonicalPartitioning()
			local rowsBySocket = { }
			for _, row in ipairs(popup.controls.resultsList.list) do
				rowsBySocket[row.socketId] = row
			end
			assert.are.equal("equipped", rowsBySocket[sourceSocketId].action)
			assert.are.equal("move", rowsBySocket[targetSocketId].action)
			assert.are.equal(5, rowsBySocket[targetSocketId].delta)
			assert.are.equal("The Red Nightmare", rowsBySocket[targetSocketId].jewelLimitKey)
			assert.are.equal(1, rowsBySocket[targetSocketId].jewelLimit)

			observedPartitions = { }
			popup.controls.jewelTypeSelect.selFunc(findIndex(popup.controls.jewelTypeSelect.list, "All jewels"))
			runCompute()
			assertCanonicalPartitioning()
		end)

		it("passes all or selected Impossible Escape variants and the saved method to Compute", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local capturedRequest
			finder.compute.computeImpossibleEscapeSocketImpact = function(_, request)
				capturedRequest = request
				return { }, 0
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape"))
			popup.controls.computeMethodSelect.selFunc(2)
			assert.are.equal("simulated_greedy", build.radiusJewelFinderState.computeMethodId)
			runPopupCompute(popup)
			assert.is_true(#capturedRequest.variants > 1, "All variants should compute every Impossible Escape variant")
			assert.are.equal("simulated_greedy", capturedRequest.methodId)

			local selectedEntry = popup.controls.jewelVariantSelect.list[2]
			local selectedVariantName = type(selectedEntry) == "table" and selectedEntry.label or selectedEntry
			popup.controls.jewelVariantSelect.selFunc(2)
			capturedRequest = nil
			runPopupCompute(popup)
			assert.are.equal(1, #capturedRequest.variants, "selected Impossible Escape variant should constrain compute")
			assert.are.equal(selectedVariantName, capturedRequest.variants[1].dropdownLabel or capturedRequest.variants[1].name)
		end)

	end)


end)
