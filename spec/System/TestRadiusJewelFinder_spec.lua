-- Popup and interaction tests for RadiusJewelFinder.

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

		it("returns a non-empty list", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			assert.is_true(#sockets > 0, "expected at least one jewel socket")
		end)

		it("each entry has id (number) and label (string)", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			for _, s in ipairs(sockets) do
				assert.is_number(s.id)
				assert.is_string(s.label)
			end
		end)

		it("uses the standard zone labels for sockets without nearby Keystones", function()
			local socketsById = { }
			for _, socket in ipairs(makeFinder():buildJewelSockets(getLargeRadiusIndex())) do
				socketsById[socket.id] = socket
			end
			for socketId, expectedLabel in pairs({ [26725] = "Marauder", [54127] = "Duelist", [7960] = "Templar/Witch" }) do
				assert.matches("^" .. expectedLabel .. " %(" .. socketId .. "%)", socketsById[socketId].label)
			end
		end)

		it("marks the 3 allocated sockets with # prefix", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			local allocIds = { [36634] = true, [61419] = true, [41263] = true }
			for _, s in ipairs(sockets) do
				if allocIds[s.id] then
					assert.is_true(s.label:sub(1, 2) == "# ",
						"socket " .. s.id .. " should start with '# ', was: " .. s.label)
				end
			end
		end)

		it("unallocated sockets without # prefix", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			local allocIds = { [36634] = true, [61419] = true, [41263] = true }
			for _, s in ipairs(sockets) do
				if not allocIds[s.id] then
					assert.is_false(s.label:sub(1, 2) == "# ",
						"socket " .. s.id .. " should NOT start with '# '")
				end
			end
		end)

		it("list is sorted alphabetically by label", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			for i = 2, #sockets do
				assert.is_true(sockets[i - 1].label <= sockets[i].label,
					"sockets not sorted at index " .. i)
			end
		end)

		it("includes known occupied and empty sockets from the fixture build", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			local seenIds = {}
			for _, socket in ipairs(sockets) do
				seenIds[socket.id] = true
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
		local previousGetCursorPos
		local syntheticAllocatedNodeIds
		local syntheticRadiusRestores

		before_each(function()
			previousJewelRadius = data.jewelRadius
			previousMaxJewelRadius = data.maxJewelRadius
			previousGetCursorPos = GetCursorPos
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
			GetCursorPos = previousGetCursorPos
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

		local function getDropdownTooltipText(control, index)
			local tooltip = new("Tooltip"):Tooltip()
			control.tooltipFunc(tooltip, "DROP", index, control.list[index])
			local lines = { }
			for _, line in ipairs(tooltip.lines) do
				table.insert(lines, line.text or "")
			end
			return table.concat(lines, "\n")
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
			assert.are.equal("message", popup.controls.resultsList.mode, message)
			assert.are.equal(0, #popup.controls.resultsList.list, message)
			assert.is_nil(popup.controls.resultsList.selIndex, message)
			assert.is_false(popup.controls.applyButton.enabled(), message)
		end

		local function assertStaleResultsRemainVisible(popup, resultContextKey, expectedCount, expectedMode, message)
			assert.are.equal(expectedMode, popup.controls.resultsList.mode, message)
			assert.are.equal(expectedCount, #popup.controls.resultsList.list, message)
			assert.are.equal(resultContextKey, popup.controls.resultsList.list[1].resultContextKey, message)
			assert.is_not_nil(popup.controls.resultsList.selIndex, message)
			assert.is_false(popup.controls.applyButton.enabled(), message)
		end

		local function detailText(popup)
			local lines = { }
			for _, line in ipairs(popup.controls.resultDetailList.list) do
				table.insert(lines, line[1] or "")
			end
			return table.concat(lines, "\n")
		end

		local function countPlainText(text, needle)
			local count = 0
			local offset = 1
			while true do
				local startPos = text:find(needle, offset, true)
				if not startPos then
					return count
				end
				count = count + 1
				offset = startPos + #needle
			end
		end

		local function countDetailNodeLines(popup)
			local count = 0
			for _, line in ipairs(popup.controls.resultDetailList.list) do
				if line.nodeId then
					count = count + 1
				end
			end
			return count
		end

		local function makeDetailRow(overrides)
			local row = {
				socketId = 36634,
				socketLabel = "Worst-case occupied socket label",
				variantLabel = "Long selected jewel variant label",
				points = 2,
				delta = 10,
				pct = 10,
				pctPerPoint = 5,
				sortValue = 10,
				detailText = "Worst-case dynamic detail summary",
				resultNodes = {
					{ label = "Passive Alpha", nodeId = 36634 },
					{ label = "Passive Beta", nodeId = 61419 },
				},
				actionPlan = {
					kind = "replace",
					targetSocketAllocated = true,
					sourceItemId = 999001,
					sourceItemLabel = "Source jewel",
					targetIdentity = { uniqueName = "Test jewel" },
					replacedTargetId = build.itemsTab.sockets[36634].selItemId,
					replacedTargetLabel = "Existing jewel with a long label",
				},
			}
			for key, value in pairs(overrides or { }) do
				row[key] = value
			end
			return row
		end

		it("drives rendering, sorting, and hover roles from each result mode schema", function()
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
					detailText = "Zeta detail",
					action = "move",
					baseOutput = { },
					compareOutput = { },
					itemTooltipLines = { { height = 16, [1] = "Zeta preview" } },
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
					detailText = "Alpha detail",
					action = "equip",
					baseOutput = { },
					compareOutput = { },
					itemTooltipLines = { { height = 16, [1] = "Alpha preview" } },
				},
			}
			local modeCases = {
				{ mode = "computeSocket", sortColumn = 3, expectedRow = rows[2], valueColumn = 3,
					expectedValue = "^2+2.0", socketColumn = 1, statColumn = 3, detailColumn = 6 },
				{ mode = "computeSocketAll", sortColumn = 1, expectedRow = rows[2], valueColumn = 1,
					expectedValue = "Alpha Jewel", socketColumn = 2, statColumn = 4, detailColumn = 7 },
				{ mode = "find", sortColumn = 3, expectedRow = rows[2], valueColumn = 3,
					expectedValue = "^72", socketColumn = 1, detailColumn = 5 },
				{ mode = "findThread", sortColumn = 5, expectedRow = rows[1], valueColumn = 5,
					expectedValue = "Large", socketColumn = 1, detailColumn = 6 },
			}

			for _, case in ipairs(modeCases) do
				local modeRows = { rows[1], rows[2] }
				resultsList:SetMode(case.mode, modeRows, "")
				resultsList:ReSort(case.sortColumn)
				assert.are.equal(case.expectedRow, modeRows[1], case.mode .. " sort should follow its column descriptor")
				assert.are.equal(case.expectedValue, resultsList:GetRowValue(case.valueColumn, 1, modeRows[1]),
					case.mode .. " rendering should follow its column descriptor")
				assert.is_true(resultsList:GetHoverInfo(case.socketColumn, modeRows[1]).showViewer,
					case.mode .. " socket column should show the passive viewer")
				assert.is_true(resultsList:GetHoverInfo(case.detailColumn, modeRows[1]).showItemTooltip,
					case.mode .. " detail column should show the item preview")
				if case.statColumn then
					assert.is_true(resultsList:GetHoverInfo(case.statColumn, modeRows[1]).showStatTooltip,
						case.mode .. " stat column should show the stat comparison")
				end
			end
		end)

		it("uses full-height Details without changing Results", function()
			build.radiusJewelFinderState = nil
			local popup = makeFinder():Open()
			local popupWidth, popupHeight = popup:GetSize()
			assert.are.equal(1020, popupWidth)
			assert.are.equal(474, popupHeight)
			assert.is_nil(popup.controls.previewList)
			assert.is_nil(popup.controls.resultPassivesButton)

			local resultsWidth, resultsHeight = popup.controls.resultsList:GetSize()
			assert.are.equal(580, resultsWidth)
			assert.are.equal(352, resultsHeight)
			local _, detailsHeight = popup.controls.resultDetailList:GetSize()
			assert.are.equal(334, detailsHeight)
			assert.are.equal("", popup.controls.resultsList.defaultText,
				"the status line should not be repeated inside empty Results")
		end)

		it("keeps a long Search error once in Results with a short status", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Might of the Meek"))
			local searchError = "synthetic search failure with diagnostic context beyond the status width"
			finder.socketMatchesOccupiedMode = function()
				error(searchError)
			end

			popup.controls.findButton:Click()

			assert.are.equal("^1Search failed", popup.controls.statusLabel.label)
			assert.are.equal("message", popup.controls.resultsList.mode)
			assert.are.equal("", popup.controls.resultsList.defaultText)
			assert.are.equal(1, #popup.controls.resultsList.list)
			local resultError = popup.controls.resultsList.list[1].text
			assert.are.equal(1, countPlainText(resultError, searchError))
			assert.are.equal(1, countPlainText(popup.controls.statusLabel.label .. resultError, searchError),
				"the detailed Search error should appear exactly once across status and Results")
		end)

		it("keeps a long Compute error once in Results with a short status", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Might of the Meek"))
			local computeError = "synthetic compute failure with diagnostic context beyond the status width"
			finder.compute.computeSocketImpact = function()
				error(computeError)
			end

			runPopupCompute(popup)

			assert.are.equal("^1Compute failed", popup.controls.statusLabel.label)
			assert.are.equal("message", popup.controls.resultsList.mode)
			assert.are.equal("", popup.controls.resultsList.defaultText)
			assert.are.equal(1, #popup.controls.resultsList.list)
			local resultError = popup.controls.resultsList.list[1].text
			assert.are.equal(1, countPlainText(resultError, computeError))
			assert.are.equal(1, countPlainText(popup.controls.statusLabel.label .. resultError, computeError),
				"the detailed Compute error should appear exactly once across status and Results")
		end)

		it("shows a computed variant once under Variant in Details", function()
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
						delta = 10,
						addedNodeCount = 0,
						baseOutput = { },
						compareOutput = { },
					},
				}, 100
			end
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "The Light of Meaning"))
			popup.controls.jewelVariantSelect.selFunc(findControlIndex(popup.controls.jewelVariantSelect.list, "Armour"))

			runPopupCompute(popup)

			local row = popup.controls.resultsList.list[1]
			assert.are.equal("Armour", row.detailText,
				"Results Detail should keep the general summary")
			assert.are.equal("Armour", row.variantLabel,
				"the computed variant should remain available to Details")
			local text = detailText(popup)
			assert.is_true(text:find("Variant: Armour", 1, true) ~= nil)
			assert.are.equal(1, countPlainText(text, "Armour"),
				"Details should not repeat the variant as a generic detail line")
		end)

		it("builds stable Details hover tooltips only once", function()
			build.radiusJewelFinderState = nil
			local popup = makeFinder():Open()
			local control = popup.controls.resultDetailList
			local viewPort = { x = 0, y = 0, width = 1024, height = 768 }
			GetCursorPos = function() return 620, 150 end
			local secondPopup = main.popups[2]
			main.popups[2] = nil

			local item = build.itemsTab.items[build.itemsTab.sockets[36634].selItemId]
			assert.is_not_nil(item)
			local itemLine = { height = 16, [1] = "Replacement", item = item }
			control.GetHoverLine = function() return itemLine end
			local itemTooltipBuilds = 0
			local originalAddItemTooltip = build.itemsTab.AddItemTooltip
			build.itemsTab.AddItemTooltip = function(_, tooltip)
				itemTooltipBuilds = itemTooltipBuilds + 1
				tooltip:AddLine(16, "Item tooltip")
			end
			control:Draw(viewPort)
			control:Draw(viewPort)
			build.itemsTab.AddItemTooltip = originalAddItemTooltip

			local node = build.spec.nodes[33631] or build.spec.tree.nodes[33631]
			assert.is_not_nil(node)
			local nodeLine = { height = 16, [1] = "Passive", nodeId = node.id }
			control.GetHoverLine = function() return nodeLine end
			local nodeTooltipBuilds = 0
			local originalViewerDraw = control.socketViewer.Draw
			local originalAddNodeTooltip = control.socketViewer.AddNodeTooltip
			control.socketViewer.Draw = function() end
			control.socketViewer.AddNodeTooltip = function(_, tooltip)
				nodeTooltipBuilds = nodeTooltipBuilds + 1
				tooltip:AddLine(16, "Node tooltip")
			end
			control:Draw(viewPort)
			control:Draw(viewPort)
			control.socketViewer.Draw = originalViewerDraw
			control.socketViewer.AddNodeTooltip = originalAddNodeTooltip
			main.popups[2] = secondPopup
			assert.are.equal(1, itemTooltipBuilds,
				"an unchanged item hover should reuse its tooltip between frames")
			assert.are.equal(1, nodeTooltipBuilds,
				"an unchanged passive hover should reuse its tooltip between frames")
		end)

		it("shows fact-only Details and passive rows immediately", function()
			build.radiusJewelFinderState = nil
			local popup = makeFinder():Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap"))
			local firstRow = makeDetailRow()
			local secondRow = makeDetailRow({
				socketId = 33631,
				socketLabel = "Second socket",
				resultNodes = { { label = "Passive Gamma", nodeId = 33631 } },
			})
			popup.controls.resultsList:SetMode("computeSocket", { firstRow, secondRow }, "")

			local text = detailText(popup)
			for _, expected in ipairs({
				"Jewel:",
				"Test jewel",
				"Variant: Long selected jewel variant label",
				"Socket: Worst-case occupied socket label",
				"Current location:",
				"Items",
				"Will replace:",
				"Existing jewel with a long label",
				"Worst-case dynamic detail summary",
				"Recommended passives (2):",
				"Passive Alpha",
				"Passive Beta",
			}) do
				assert.is_true(text:find(expected, 1, true) ~= nil, "expected detail: " .. expected)
			end
			for _, redundant in ipairs({
				"Use occupied socket",
				"Use free socket",
				"Move equipped jewel",
				"Already equipped",
				"This socket is unallocated",
				"Passive allocations are not applied automatically",
				"Source:",
				"New Test jewel",
			}) do
				assert.is_nil(text:find(redundant, 1, true), "unexpected Details text: " .. redundant)
			end
			local jewelPos = assert(text:find("Jewel:", 1, true))
			local variantPos = assert(text:find("Variant: Long selected jewel variant label", 1, true))
			local socketPos = assert(text:find("Socket: Worst-case occupied socket label", 1, true))
			local locationPos = assert(text:find("Current location:", 1, true))
			assert.is_true(jewelPos < variantPos and variantPos < socketPos and socketPos < locationPos,
				"Details should read Jewel, Variant, Socket, then Current location")
			assert.are.equal(2, countDetailNodeLines(popup))

			local replacementLine
			for _, line in ipairs(popup.controls.resultDetailList.list) do
				if line[1] and line[1]:find("Will replace", 1, true) then
					replacementLine = line
					break
				end
			end
			assert.is_not_nil(replacementLine)
			assert.is_not_nil(replacementLine.item, "replacement item tooltip should remain available")

			popup.controls.resultDetailList.controls.scrollBar.offset = 80
			popup.controls.resultsList:SelectIndex(2)
			assert.are.equal(0, popup.controls.resultDetailList.controls.scrollBar.offset)
			assert.are.equal(1, countDetailNodeLines(popup))
			assert.is_true(detailText(popup):find("Passive Gamma", 1, true) ~= nil)
			for _, line in ipairs(popup.controls.resultDetailList.list) do
				if line.nodeId then
					assert.is_not_nil(build.spec.nodes[line.nodeId] or build.spec.tree.nodes[line.nodeId],
						"passive lines should resolve to nodes for their tooltips")
				end
			end
		end)

		it("uses precise zero-passive labels", function()
			build.radiusJewelFinderState = nil
			local popup = makeFinder():Open()
			popup.controls.resultsList:SetMode("computeSocket", { makeDetailRow({ resultNodes = { } }) }, "")
			assert.is_true(detailText(popup):find("No recommended passives", 1, true) ~= nil)

			local findRow = makeDetailRow({ topNodes = { } })
			findRow.resultNodes = nil
			popup.controls.resultsList:SetMode("find", { findRow }, "")
			assert.is_true(detailText(popup):find("No notables or keystones in range", 1, true) ~= nil)
		end)

		it("omits a Detail summary already shown by Variant and recommended passives", function()
			build.radiusJewelFinderState = nil
			local popup = makeFinder():Open()
			popup.controls.resultsList:SetMode("computeSocket", { makeDetailRow({
				variantLabel = "Normal",
				detailText = "Normal | 2 nodes",
			}) }, "")

			local text = detailText(popup)
			assert.is_true(text:find("Variant: Normal", 1, true) ~= nil)
			assert.is_true(text:find("Recommended passives (2):", 1, true) ~= nil)
			assert.is_nil(text:find("Normal | 2 nodes", 1, true),
				"Details should not repeat the Results summary")
		end)

		it("keeps Split Personality distance ranking without a passive block", function()
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
			assert.are.equal("Far split socket", row.socketLabel)
			assert.are.equal("dist to start 9", row.detailText)
			assert.is_nil(row.topNodes)
			local text = detailText(popup)
			assert.is_true(text:find("dist to start 9", 1, true) ~= nil)
			assert.is_nil(text:find("passive", 1, true))
			assert.is_nil(text:find("in range", 1, true))
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
			build.spec.tree.nodes[syntheticSocketId] = {
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

		it("enables Apply for Thread of Hope Find and Compute results", function()
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
			popup.controls.resultsList.selIndex = 1
			assert.is_true(popup.controls.applyButton.enabled())

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
			popup.controls.resultsList.selIndex = 1
			assert.is_true(popup.controls.applyButton.enabled())

		end)

		it("keeps stale results visible and blocks Apply when criteria change", function()
			local _, popup = openResultContextTestPopup()
			local criteriaChangedMessage = "^xFFAA33Criteria changed. ^8Run Find or Compute again."
			local computeOnlyCriteriaChangedMessage = "^xFFAA33Criteria changed. ^8Run Compute again."
			local intuitiveLeapIndex = findControlIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap")
			local threadOfHopeIndex = findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope")

			local changes = {
				{
					name = "variant",
					change = function() popup.controls.jewelVariantSelect.selFunc(2) end,
					restore = function() popup.controls.jewelVariantSelect.selFunc(1) end,
					message = criteriaChangedMessage,
				},
				{
					name = "impact stat",
					change = function() popup.controls.impactStatSelect.selFunc(2) end,
					restore = function() popup.controls.impactStatSelect.selFunc(1) end,
					message = computeOnlyCriteriaChangedMessage,
				},
				{
					name = "compute method",
					change = function() popup.controls.computeMethodSelect.selFunc(2) end,
					restore = function() popup.controls.computeMethodSelect.selFunc(1) end,
					message = computeOnlyCriteriaChangedMessage,
				},
				{
					name = "max points",
					change = function() popup.controls.maxPointsEdit:SetText("21", true) end,
					restore = function() popup.controls.maxPointsEdit:SetText("20", true) end,
					message = computeOnlyCriteriaChangedMessage,
				},
				{
					name = "occupied sockets",
					change = function() popup.controls.occupiedModeSelect.selFunc(2) end,
					restore = function() popup.controls.occupiedModeSelect.selFunc(1) end,
					message = computeOnlyCriteriaChangedMessage,
				},
				{
					name = "jewel type",
					change = function() popup.controls.jewelTypeSelect.selFunc(threadOfHopeIndex) end,
					restore = function() popup.controls.jewelTypeSelect.selFunc(intuitiveLeapIndex) end,
					message = criteriaChangedMessage,
				},
			}
			for _, criterion in ipairs(changes) do
				runPopupCompute(popup)
				local staleRow = popup.controls.resultsList.list[1]
				local resultMode = popup.controls.resultsList.mode
				assert.is_not_nil(staleRow)
				criterion.change()
				assertStaleResultsRemainVisible(popup, staleRow.resultContextKey, 1, resultMode,
					criterion.name .. " should keep the previous results visible but stale")
				assert.are.equal(criterion.message, popup.controls.statusLabel.label,
					criterion.name .. " should explain how to refresh results")
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
			assert.matches("2 results", popup.controls.statusLabel.label, 1, true)

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

			assert.are.equal("findThread", popup.controls.resultsList.mode)
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

			assert.are.equal("find", popup.controls.resultsList.mode)
			assert.are.equal(0, #popup.controls.resultsList.list)

			popup.controls.maxPointsEdit:SetText("3", true)
			popup.controls.findButton:Click()
			assert.are.equal(1, #popup.controls.resultsList.list)
			assert.are.equal(3, popup.controls.resultsList.list[1].points)
		end)

		it("keeps Find discoverable when an exact variant is required", function()
			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local popup = finder:Open()
			local computeOnlyCriteriaChangedMessage = "^xFFAA33Criteria changed. ^8Run Compute again."

			local function tooltipText(control, mode, index)
				local tooltip = new("Tooltip"):Tooltip()
				control.tooltipFunc(tooltip, mode, index, index and control.list and control.list[index])
				local texts = { }
				for _, line in ipairs(tooltip.lines) do
					if line.text and line.text ~= "" then
						texts[#texts + 1] = line.text
					end
				end
				return table.concat(texts, "\n")
			end

			for _, jewelTypeName in ipairs({
				"Intuitive Leap",
				"Dreams & Nightmares",
				"Tempered & Transcendent",
				"Split Personality",
			}) do
				popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, jewelTypeName))
				assert.is_true(popup.controls.findButton:IsShown(), jewelTypeName .. " should keep Find visible")
				assert.is_false(popup.controls.findButton:IsEnabled(), jewelTypeName .. " should require an exact variant")
				assert.are.equal(computeOnlyCriteriaChangedMessage, popup.controls.statusLabel.label)
				local statusBeforeClick = popup.controls.statusLabel.label
				popup.controls.findButton:Click()
				assert.are.equal(statusBeforeClick, popup.controls.statusLabel.label,
					"disabled Find should not start a search")
			end

			local allVariantsTooltip = tooltipText(popup.controls.jewelVariantSelect, "DROP", 1)
			assert.matches("Find ranks sockets for one exact variant.", allVariantsTooltip, 1, true)
			assert.matches("Compute to compare the displayed variants by the selected stat.", allVariantsTooltip, 1, true)

			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares"))
			popup.controls.variantGroupSelect.selFunc(2)
			assert.is_false(popup.controls.findButton:IsEnabled(), "a filtered All variants selection should still require one variant")
			popup.controls.jewelVariantSelect.selFunc(2)
			assert.is_true(popup.controls.findButton:IsEnabled(), "an exact grouped variant should enable Find")

			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape"))
			assert.is_true(popup.controls.findButton:IsShown())
			assert.is_true(popup.controls.findButton:IsEnabled(), "Impossible Escape should keep its All variants Find contract")
			assert.matches("every displayed Keystone variant", tooltipText(popup.controls.jewelVariantSelect, "DROP", 1), 1, true)

			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope"))
			assert.is_true(popup.controls.findButton:IsShown())
			assert.is_true(popup.controls.findButton:IsEnabled(), "Thread should keep its Any ring Find contract")
			assert.matches("every ring", tooltipText(popup.controls.findButton), 1, true)

			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "All jewels"))
			assert.is_false(popup.controls.findButton:IsShown(), "All jewels should remain Compute-only")

			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Tempered & Transcendent"))
			popup.controls.closeButton:Click()
			local reopenedPopup = finder:Open()
			assert.is_true(reopenedPopup.controls.findButton:IsShown())
			assert.is_false(reopenedPopup.controls.findButton:IsEnabled())
			assert.are.equal("^8Select a variant for Find, or click Compute", reopenedPopup.controls.statusLabel.label)
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
			assert.is_true(#popup.controls.variantGroupSelect.list > 1)

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
			assert.are.equal("^xFFAA33Criteria changed. ^8Run Compute again.",
				popup.controls.statusLabel.label)
			local staleAllJewelsMode = popup.controls.resultsList.mode
			for _, viewIndex in ipairs({ 2, 1 }) do
				popup.controls.allJewelsViewSelect.selFunc(viewIndex)
				assertStaleResultsRemainVisible(popup, allJewelsContextKey, allJewelsResultCount,
					staleAllJewelsMode, "changing the All-jewels view should keep stale results visible")
				assert.are.equal("^xFFAA33Criteria changed. ^8Run Compute again.",
					popup.controls.statusLabel.label)
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
			assert.are.equal("^7Ring:", popup.controls.threadVariantLabel.label)
			assert.are.equal("Any ring", popup.controls.threadVariantSelect.list[1])
			for index, variant in ipairs(threadVariants) do
				assert.are.equal(variant.ringLabel, popup.controls.threadVariantSelect.list[index + 1])
			end
			local anyRingTooltip = getDropdownTooltipText(popup.controls.threadVariantSelect, 1)
			assert.matches("Multiple ring sizes available", anyRingTooltip, 1, true)
			for _, variant in ipairs(threadVariants) do
				assert.is_nil(anyRingTooltip:find(variant.ringLabel, 1, true))
			end
			popup.controls.findButton:Click()
			local findRow = popup.controls.resultsList.list[1]
			assert.is_not_nil(findRow)
			local anyRingContextKey = findRow.resultContextKey

			popup.controls.threadVariantSelect.selFunc(2)
			local explicitRingTooltip = getDropdownTooltipText(popup.controls.threadVariantSelect, 2)
			assert.matches(threadVariants[1].ringLabel, explicitRingTooltip, 1, true)
			assert.is_nil(explicitRingTooltip:find("Multiple ring sizes available", 1, true))
			popup.controls.findButton:Click()
			local explicitRingRow = popup.controls.resultsList.list[1]

			assert.are.equal("findThread", popup.controls.resultsList.mode)
			assert.are.equal(threadVariants[1].ringLabel, explicitRingRow.variantLabel)
			assert.are_not.equal(anyRingContextKey, explicitRingRow.resultContextKey)

			runPopupCompute(popup)
			local row = popup.controls.resultsList.list[1]
			assert.is_not_nil(row)
			assert.are.equal(1, #computedVariants)
			assert.are.equal(threadVariants[1].name, computedVariants[1].name)
			assert.matches(threadVariants[1].ringLabel, row.detailText, 1, true)
			assert.matches(threadVariants[1].ringLabel, popup.controls.statusLabel.label, 1, true)

			popup.controls.threadVariantSelect.selFunc(1)

			assert.is_nil(build.radiusJewelFinderState.threadVariantName)
		end)

		it("restores an explicit Thread ring selection", function()
			local finder = makeFinder()
			local popup = finder:Open()
			popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope"))
			popup.controls.threadVariantSelect.selFunc(2)
			popup.controls.findButton:Click()
			popup.controls.closeButton:Click()
			local reopenedPopup = finder:Open()

			assert.are.equal(2, reopenedPopup.controls.threadVariantSelect.selIndex)
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
			assert.is_false(popup.controls.applyButton.enabled())
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

			it("opens the popup with expected jewel types and controls", function()
			local function listLabels(list)
				local labels = {}
				for i, entry in ipairs(list) do
					labels[i] = type(entry) == "table" and entry.label or entry
				end
				return labels
			end

			local function tooltipTexts(control, index)
				local tooltip = new("Tooltip"):Tooltip()
				control.tooltipFunc(tooltip, "DROP", index, control.list[index])
				local texts = {}
				for _, line in ipairs(tooltip.lines) do
					if line.text and line.text ~= "" then
						texts[#texts + 1] = line.text
					end
				end
				return texts
			end
			local function buttonTooltipTexts(control, ...)
				local tooltip = new("Tooltip"):Tooltip()
				control.tooltipFunc(tooltip, ...)
				local texts = {}
				for _, line in ipairs(tooltip.lines) do
					if line.text and line.text ~= "" then
						texts[#texts + 1] = line.text
					end
				end
				return texts
			end

			local function findIndex(list, needle)
				for i, label in ipairs(listLabels(list)) do
					if label == needle then
						return i
					end
				end
			end
			local function assertAlphabetical(labels, message)
				for i = 2, #labels do
					assert.is_true(labels[i - 1] <= labels[i], message or ("labels not sorted at index " .. i))
				end
			end

			while main.popups[1] do
				main:ClosePopup()
			end

			build.radiusJewelFinderState = nil
			local finder = makeFinder()
			local popup = finder:Open()
			assert.is_not_nil(popup)
			assert.are.equal("Find Radius Jewel", popup.title)
			local popupWidth, popupHeight = popup:GetSize()
			assert.is_true(popupWidth <= 1020, "popup should fit within a 1024px-wide screen")
			local popupX, popupY = popup:GetPos()
			local function assertControlInsidePopup(controlName)
				local control = popup.controls[controlName]
				assert.is_not_nil(control, "expected control: " .. controlName)
				local x, y = control:GetPos()
				local width, height = control:GetSize()
				assert.is_true(x >= popupX, controlName .. " should not extend past the popup left edge")
				assert.is_true(y >= popupY, controlName .. " should not extend past the popup top edge")
				assert.is_true(x + width <= popupX + popupWidth, controlName .. " should not extend past the popup right edge")
				assert.is_true(y + height <= popupY + popupHeight, controlName .. " should not extend past the popup bottom edge")
			end
			for _, controlName in ipairs({
				"computeButton",
				"impactStatSelect",
				"resultDetailList",
				"findButton",
				"addToBuildButton",
				"applyButton",
				"closeButton",
			}) do
				assertControlInsidePopup(controlName)
			end
			for _, controlName in ipairs({ "findButton", "addToBuildButton", "applyButton", "closeButton" }) do
				local control = popup.controls[controlName]
				local _, y = control:GetPos()
				local _, height = control:GetSize()
				assert.are.equal(10, popupY + popupHeight - (y + height), controlName .. " should keep the bottom action margin")
			end
			local occupiedX = popup.controls.occupiedModeSelect:GetPos()
			local occupiedWidth = popup.controls.occupiedModeSelect:GetSize()
			local addToBuildX = popup.controls.addToBuildButton:GetPos()
			local addToBuildWidth = popup.controls.addToBuildButton:GetSize()
			local applyX = popup.controls.applyButton:GetPos()
			assert.is_true(occupiedX + occupiedWidth <= addToBuildX,
				"Add to build should not overlap the Sockets selector")
			assert.is_true(addToBuildX + addToBuildWidth <= applyX,
				"placement action should not overlap Add to build")
			local computeX = popup.controls.computeButton:GetPos()
			local computeWidth = popup.controls.computeButton:GetSize()
			assert.are.equal(20, popupX + popupWidth - (computeX + computeWidth), "computeButton should keep the header right margin")
			local closeX = popup.controls.closeButton:GetPos()
			local closeWidth = popup.controls.closeButton:GetSize()
			assert.are.equal(10, popupX + popupWidth - (closeX + closeWidth), "closeButton should keep the bottom right margin")
			local computeTooltipTexts = buttonTooltipTexts(popup.controls.computeButton)
			assert.is_true(#computeTooltipTexts > 0, "expected Compute tooltip content")
			assert.is_true(computeTooltipTexts[1]:find("selected stat", 1, true) ~= nil,
				"expected Compute tooltip to explain stat ranking")
			assert.is_true(computeTooltipTexts[2]:find("Max points", 1, true) ~= nil,
				"expected Compute tooltip to name the Max points filter")
			assert.is_false(popup.controls.findButton:IsShown(), "Find should be hidden for All jewels")
			local addToBuildTooltipTexts = buttonTooltipTexts(popup.controls.addToBuildButton)
			assert.is_true(#addToBuildTooltipTexts > 0, "expected Add to build tooltip content")
			assert.is_true(addToBuildTooltipTexts[1]:find("Select a result", 1, true) ~= nil,
				"expected Add to build tooltip to explain missing selection")
			local applyTooltipTexts = buttonTooltipTexts(popup.controls.applyButton)
			assert.is_true(#applyTooltipTexts > 0, "expected Apply tooltip content")
			assert.is_true(applyTooltipTexts[1]:find("Select a result", 1, true) ~= nil,
				"expected Apply tooltip to explain missing selection")
			assert.is_nil(popup.controls.closeButton.tooltipFunc, "Close is self-explanatory and should not need a tooltip")
			assert.are.equal("^7Max points:", popup.controls.maxPointsLabel.label)
			local maxPointsTooltipTexts = buttonTooltipTexts(popup.controls.maxPointsEdit)
			assert.is_true(#maxPointsTooltipTexts > 0, "expected Max points tooltip content")
			assert.is_true(maxPointsTooltipTexts[1]:find("Maximum Points per result.", 1, true) ~= nil,
				"expected Max points tooltip to explain the result limit")
			assert.is_true(table.concat(maxPointsTooltipTexts, "\n"):find("For Compute, this includes pathing and passives to allocate.", 1, true) ~= nil,
				"expected Max points tooltip to explain Compute point cost")
			assert.is_true(table.concat(maxPointsTooltipTexts, "\n"):find("Leave blank for no limit.", 1, true) ~= nil,
				"expected Max points tooltip to explain the unlimited state")
			for mode, pointColumnIndex in pairs({ computeSocket = 2, computeSocketAll = 3, find = 2, findThread = 2 }) do
				local pointColumn = popup.controls.resultsList.columnsByMode[mode][pointColumnIndex]
				assert.are.equal("Points", pointColumn.label, mode .. " should spell out Points")
				assert.are.equal(50, pointColumn.width, mode .. " should leave room for the Points label")
			end
			local occupiedTooltipTexts = buttonTooltipTexts(popup.controls.occupiedModeSelect, "DROP", 2, popup.controls.occupiedModeSelect.list[2])
			assert.is_true(#occupiedTooltipTexts > 0, "expected Sockets tooltip content")
			assert.is_true(occupiedTooltipTexts[2]:find("socket%-specific") ~= nil,
				"expected Safe occupied tooltip to explain socket-specific behavior")
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected Method selector for All jewels")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			local fastMethodTooltipTexts = buttonTooltipTexts(popup.controls.computeMethodSelect, "DROP", 1, popup.controls.computeMethodSelect.list[1])
			assert.is_true(fastMethodTooltipTexts[1]:find("Intuitive Leap", 1, true) ~= nil,
				"expected All jewels Method tooltip to name affected jewel types")
			assert.is_true(fastMethodTooltipTexts[2]:find("independently", 1, true) ~= nil,
				"expected Fast method tooltip to explain independent scoring")
			local simulatedMethodTooltipTexts = buttonTooltipTexts(popup.controls.computeMethodSelect, "DROP", 2, popup.controls.computeMethodSelect.list[2])
			assert.is_true(simulatedMethodTooltipTexts[2]:find("recalculates", 1, true) ~= nil,
				"expected Simulated method tooltip to explain recalculation")
			popup.controls.computeMethodSelect.selFunc(2)
			assert.are.equal("simulated_greedy", build.radiusJewelFinderState.computeMethodId)
			popup.controls.computeMethodSelect.selFunc(1)
			local allResultsViewTooltipTexts = buttonTooltipTexts(popup.controls.allJewelsViewSelect, "DROP", 1, popup.controls.allJewelsViewSelect.list[1])
			assert.is_true(allResultsViewTooltipTexts[1]:find("every compatible result", 1, true) ~= nil,
				"expected All results view tooltip to explain unfiltered results")
			local bestPerSocketTooltipTexts = buttonTooltipTexts(popup.controls.allJewelsViewSelect, "DROP", 2, popup.controls.allJewelsViewSelect.list[2])
			assert.is_true(bestPerSocketTooltipTexts[1]:find("one best result per socket", 1, true) ~= nil,
				"expected Best per socket tooltip to explain per-socket filtering")
			assert.is_true(bestPerSocketTooltipTexts[2]:find("Jewel limits", 1, true) ~= nil,
				"expected Best per socket tooltip to mention jewel limits")
			assert.is_true(findIndex(popup.controls.impactStatSelect.list, "Full DPS") ~= nil)
			assert.is_true(findIndex(popup.controls.impactStatSelect.list, "Hit DPS") ~= nil)
			assert.is_true(findIndex(popup.controls.impactStatSelect.list, "Block Chance") ~= nil)

			local hasIntuitiveLeap = false
			local hasThreadOfHope = false
			local hasTemperedAndTranscendent = false
			local hasSplitPersonality = false
			local hasImpossibleEscape = false
			local hasDreamsAndNightmares = false
			local jewelTypeLabels = listLabels(popup.controls.jewelTypeSelect.list)
			for _, label in ipairs(popup.controls.jewelTypeSelect.list) do
				if label == "Intuitive Leap" then
					hasIntuitiveLeap = true
				elseif label == "Thread of Hope" then
					hasThreadOfHope = true
				elseif label == "Tempered & Transcendent" then
					hasTemperedAndTranscendent = true
				elseif label == "Split Personality" then
					hasSplitPersonality = true
				elseif label == "Impossible Escape" then
					hasImpossibleEscape = true
				elseif label == "Dreams & Nightmares" then
					hasDreamsAndNightmares = true
				end
			end

			assert.is_true(hasIntuitiveLeap, "expected Intuitive Leap in jewel type list")
			assert.is_true(hasThreadOfHope, "expected Thread of Hope in jewel type list")
			assert.is_true(hasTemperedAndTranscendent, "expected Tempered & Transcendent in jewel type list")
			assert.is_true(hasSplitPersonality, "expected Split Personality in jewel type list")
			assert.is_true(hasImpossibleEscape, "expected Impossible Escape in jewel type list")
			assert.is_true(hasDreamsAndNightmares, "expected Dreams & Nightmares in jewel type list")
			assertAlphabetical(jewelTypeLabels, "expected jewel types to be sorted alphabetically")

			local allJewelsIdx = findIndex(popup.controls.jewelTypeSelect.list, "All jewels")
			assert.is_not_nil(allJewelsIdx, "expected All jewels in jewel type list")
			local allJewelsTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, allJewelsIdx)
			assert.is_true(allJewelsTooltipTexts[2]:find("%/Pt.", 1, true) ~= nil,
				"expected All jewels tooltip to show %/Pt")
			local doubledPercent = allJewelsTooltipTexts[2]:find("%%/Pt.", 1, true)
			assert.is_nil(doubledPercent, "All jewels tooltip should not show escaped %%/Pt")
			popup.controls.jewelTypeSelect.selFunc(allJewelsIdx)
			local selectedResultPreview = {
				{ height = 16, [1] = "^7Selected Jewel" },
				{ height = 16, [1] = "^8Selected result preview line" },
			}
			assert.is_false(popup.controls.findButton:IsShown(), "Find should stay hidden for All jewels")
			popup.controls.resultsList:SetMode("computeSocketAll", {
				{
					jewelName = "Selected Jewel",
					socketLabel = "Socket #1",
					socketId = 33631,
					points = 1,
					delta = 10,
					pct = 10,
					pctPerPoint = 10,
					sortValue = 10,
					detailText = "Test detail",
					itemTooltipLines = selectedResultPreview,
					action = "equip",
				},
			}, "(no compatible sockets)")
			assert.is_nil(popup.controls.previewList)
			assert.are.equal("^7Selected Jewel", popup.controls.resultsList.selValue.itemTooltipLines[1][1])
			local allJewelsDetailHover = popup.controls.resultsList:GetHoverInfo(7, popup.controls.resultsList.selValue)
			assert.is_true(allJewelsDetailHover.showItemTooltip,
				"All jewels Compute detail column should show jewel preview tooltip")
			local allJewelsSocketHover = popup.controls.resultsList:GetHoverInfo(2, popup.controls.resultsList.selValue)
			assert.is_true(allJewelsSocketHover.showViewer,
				"All jewels Compute socket column should show socket preview")
			popup.controls.resultsList:SetMode("message", { }, "Click Compute")

			-- Intuitive Leap: tooltip, compute method, occupied mode
			local intuitiveIdx = findIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap")
			assert.is_not_nil(intuitiveIdx, "expected Intuitive Leap in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(intuitiveIdx)
			local typeTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, intuitiveIdx)
			assert.is_true(#typeTooltipTexts > 0, "expected jewel type tooltip content")
			assert.is_true(typeTooltipTexts[1]:find("Intuitive Leap", 1, true) ~= nil,
				"expected type tooltip to describe Intuitive Leap")
			assert.is_true(popup.controls.jewelVariantSelect.shown, "expected Foulborn variant selector for Intuitive Leap")
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should stay visible while all Intuitive Leap variants are selected")
			assert.is_false(popup.controls.findButton:IsEnabled(),
				"Find should require one Intuitive Leap variant")
			local intuitiveVariantLabels = listLabels(popup.controls.jewelVariantSelect.list)
			local foulbornIntuitiveIdx
			for i, label in ipairs(intuitiveVariantLabels) do
				if label:find("Foulborn:", 1, true) then
					foulbornIntuitiveIdx = i
					break
				end
			end
			assert.is_not_nil(foulbornIntuitiveIdx, "expected Foulborn Intuitive Leap variant")
			popup.controls.jewelVariantSelect.selFunc(foulbornIntuitiveIdx)
			assert.is_true(popup.controls.findButton:IsShown(), "Find should be shown for the selected Intuitive Leap variant")
			local findTooltipTexts = buttonTooltipTexts(popup.controls.findButton)
			assert.is_true(#findTooltipTexts > 0, "expected Find tooltip content")
			assert.is_true(findTooltipTexts[1]:find("matching passives", 1, true) ~= nil,
				"expected Find tooltip to explain passive matching")
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Intuitive Leap")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			assert.are.same({ "Free only", "Safe occupied", "All occupied" }, listLabels(popup.controls.occupiedModeSelect.list))
			assert.are.equal("Fast", popup.controls.computeMethodSelect.list[popup.controls.computeMethodSelect.selIndex])

			-- Dreams & Nightmares: variant tooltips
			local normalDreamsIdx = findIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares")
			assert.is_not_nil(normalDreamsIdx, "expected Dreams & Nightmares in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(normalDreamsIdx)
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			assert.are.equal(1, popup.controls.jewelVariantSelect.selIndex)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should stay visible while all variants are selected")
			assert.is_false(popup.controls.findButton:IsEnabled(),
				"Find should require one Dreams & Nightmares variant")
			assert.is_true(popup.controls.jewelVariantLabel.y >= 18,
				"expected header labels to sit below the popup title")
			if popup.controls.variantGroupSelect.shown then
				assert.is_true(popup.controls.variantGroupSelect.x < popup.controls.jewelVariantSelect.x,
					"expected Jewel to filter Variant from left to right")
				local redNightmareGroupIdx = findIndex(popup.controls.variantGroupSelect.list, "Red Nightmare")
				assert.is_not_nil(redNightmareGroupIdx, "expected Red Nightmare in jewel filter")
				popup.controls.variantGroupSelect.selFunc(redNightmareGroupIdx)
				local redNightmareGroupLabels = listLabels(popup.controls.jewelVariantSelect.list)
				assert.are.equal("All variants", redNightmareGroupLabels[1])
				for i = 2, #redNightmareGroupLabels do
					assert.is_true(redNightmareGroupLabels[i]:find("Red Nightmare", 1, true) ~= nil,
						"jewel filter should only show Red Nightmare variants: " .. redNightmareGroupLabels[i])
				end
				popup.controls.variantGroupSelect.selFunc(1)
			end
			local redNightmareIdx = findIndex(popup.controls.jewelVariantSelect.list, "The Red Nightmare")
			assert.is_not_nil(redNightmareIdx, "expected The Red Nightmare in variant list")
			local redNightmareTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, redNightmareIdx)
			assert.is_true(#redNightmareTooltipTexts > 0, "expected Red Nightmare tooltip content")
			for _, text in ipairs(redNightmareTooltipTexts) do
				assert.is_nil(text:find("{variant:", 1, true), "variant tooltip should not expose raw variant tags")
				assert.is_nil(text:find("Selected Variant:", 1, true), "variant tooltip should not expose saved-state metadata")
			end
			popup.controls.jewelVariantSelect.selFunc(redNightmareIdx)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should be shown after selecting a specific variant")
			local foulbornRedNightmareIdx
			for i, label in ipairs(listLabels(popup.controls.jewelVariantSelect.list)) do
				if label:find("The Red Nightmare (Foulborn:", 1, true) then
					foulbornRedNightmareIdx = i
					break
				end
			end
			assert.is_not_nil(foulbornRedNightmareIdx, "expected Foulborn Red Nightmare variant")
			popup.controls.jewelVariantSelect.selFunc(foulbornRedNightmareIdx)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should stay shown for the selected Foulborn variant")
			popup.controls.findButton:Click()
			local hasFoulbornResultLabel = false
			for _, row in ipairs(popup.controls.resultsList.list) do
				if row.variantLabel and row.variantLabel:find("Foulborn:", 1, true) then
					hasFoulbornResultLabel = true
					break
				end
			end
			assert.is_true(hasFoulbornResultLabel, "expected Find results to name the selected Foulborn variant")

			-- Tempered & Transcendent: type tooltip generic, variant tooltip specific
			local temperedIdx = findIndex(popup.controls.jewelTypeSelect.list, "Tempered & Transcendent")
			assert.is_not_nil(temperedIdx, "expected Tempered & Transcendent in jewel type list")
			local temperedTypeTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, temperedIdx)
			assert.is_true(#temperedTypeTooltipTexts > 0, "expected generic type tooltip content")
			for _, text in ipairs(temperedTypeTooltipTexts) do
				assert.is_nil(text:find("Tempered Flesh", 1, true),
					"type tooltip should not include a specific variant")
			end
			popup.controls.jewelTypeSelect.selFunc(temperedIdx)
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			local temperedFleshIdx = findIndex(popup.controls.jewelVariantSelect.list, "Tempered Flesh")
			assert.is_not_nil(temperedFleshIdx, "expected Tempered Flesh in variant list")
			local variantTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, temperedFleshIdx)
			assert.is_true(#variantTooltipTexts > 0, "expected jewel variant tooltip content")
			assert.is_true(variantTooltipTexts[1]:find("Tempered Flesh", 1, true) ~= nil,
				"expected variant tooltip to describe the hovered variant")
			local temperedLabels = listLabels(popup.controls.jewelVariantSelect.list)
			assert.is_true(#temperedLabels > 0, "expected Tempered & Transcendent variants")
			for i, label in ipairs(temperedLabels) do
				if i == 1 then
					assert.are.equal("All variants", label)
				else
					assert.is_truthy(label:find("Tempered") or label:find("Transcendent"),
						"variant should be Tempered or Transcendent: " .. label)
				end
			end

			-- Split Personality: unique variant labels
			local splitIdx = findIndex(popup.controls.jewelTypeSelect.list, "Split Personality")
			assert.is_not_nil(splitIdx, "expected Split Personality in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(splitIdx)
			assert.is_true(popup.controls.computeButton.shown, "expected Compute for Split Personality")
			local splitTypeTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, splitIdx)
			for _, text in ipairs(splitTypeTooltipTexts) do
				assert.is_nil(text:find("Radius:", 1, true),
					"Split Personality type tooltip should not show a radius line")
			end
			local splitLabels = listLabels(popup.controls.jewelVariantSelect.list)
			assert.is_true(#splitLabels > 0, "expected Split Personality variants")
			assert.are.equal("All variants", splitLabels[1])
			local splitVariantTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, 2)
			for _, text in ipairs(splitVariantTooltipTexts) do
				assert.is_nil(text:find("Radius:", 1, true),
					"Split Personality variant tooltip should not show a radius line")
			end
			local seenLabels = {}
			for i, label in ipairs(splitLabels) do
				assert.is_string(label)
				assert.is_true(#label > 0, "variant label should not be empty")
				if i > 1 then
					assert.is_nil(seenLabels[label], "duplicate Split Personality variant: " .. label)
					seenLabels[label] = true
				end
			end

			-- Impossible Escape: compute method + keystone variants
			local impossibleIdx = findIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape")
			assert.is_not_nil(impossibleIdx, "expected Impossible Escape in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(impossibleIdx)
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Impossible Escape")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			assert.is_true(#popup.controls.jewelVariantSelect.list > 0, "expected Impossible Escape keystone variants")
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			assert.are.equal(1, popup.controls.jewelVariantSelect.selIndex)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should stay shown for Impossible Escape all-variant searches")
			assert.is_true(#popup.controls.jewelVariantSelect.list > 1, "expected at least one selectable keystone variant")

			local capturedVariants
			finder.compute.computeImpossibleEscapeSocketImpact = function(_, request)
				capturedVariants = request.variants
				return { }, 0
			end
			popup.controls.computeButton:Click()
			while main.onFrameFuncs["RadiusJewelFinderCompute"] do
				runCallback("OnFrame")
			end
			assert.is_table(capturedVariants)
			assert.is_true(#capturedVariants > 1, "All variants should compute every Impossible Escape variant")

			local selectedImpossibleEscapeLabel = listLabels(popup.controls.jewelVariantSelect.list)[2]
			popup.controls.jewelVariantSelect.selFunc(2)
			capturedVariants = nil
			popup.controls.computeButton:Click()
			while main.onFrameFuncs["RadiusJewelFinderCompute"] do
				runCallback("OnFrame")
			end
			assert.is_table(capturedVariants)
			assert.are.equal(1, #capturedVariants, "selected Impossible Escape variant should constrain compute")
			assert.are.equal(selectedImpossibleEscapeLabel, capturedVariants[1].dropdownLabel or capturedVariants[1].name)

			-- Thread of Hope: compute method
			local threadIdx = findIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope")
			assert.is_not_nil(threadIdx, "expected Thread of Hope in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(threadIdx)
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Thread of Hope")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))

			while main.popups[1] do
				main:ClosePopup()
			end
			assert.is_nil(main.popups[1])
		end)

	end)

	describe("replacement item tooltip", function()

		it("attaches the replaced jewel to its detail line", function()
			while main.popups[1] do
				main:ClosePopup()
			end
			local popup = makeFinder():Open()
			local socketId = 36634
			local replacedItem = build.itemsTab.items[build.itemsTab.sockets[socketId].selItemId]
			popup.controls.resultsList:SetMode("computeSocket", {
				{
					socketId = socketId,
					socketLabel = "Test socket",
					points = 0,
					delta = 0,
					pct = 0,
					pctPerPoint = 0,
					sortValue = 0,
					detailText = "",
					action = "replace",
					replacedItemLabel = "Existing jewel",
				},
			}, "")

			local replacementLine
			for _, line in ipairs(popup.controls.resultDetailList.list) do
				if line[1] and line[1]:find("Will replace", 1, true) then
					replacementLine = line
					break
				end
			end

			assert.is_not_nil(replacementLine, "expected a replacement detail line")
			assert.are.equal(replacedItem, replacementLine.item)
		end)

	end)

end)
