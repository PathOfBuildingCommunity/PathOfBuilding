-- Path of Building
--
-- Module: Radius Jewel Compute
-- Compute methods for the Radius Jewel Finder — calcFunc-based impact evaluation
-- across all socket/jewel pairs.
--
-- Usage:
--   local RadiusJewelCompute = LoadModule("Classes/RadiusJewelCompute")({
--     calculateImpactPercent, mustGetUniqueRawText, buildNodeLabelList,
--     getJewelRadiusIndex,
--   })
--   local compute = RadiusJewelCompute.new(finder)
--
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local s_format = string.format

return function(helpers)

local RadiusJewelComputeClass = { }
RadiusJewelComputeClass.__index = RadiusJewelComputeClass

local calculateImpactPercent = helpers.calculateImpactPercent
local mustGetUniqueRawText   = helpers.mustGetUniqueRawText
local buildNodeLabelList     = helpers.buildNodeLabelList
local getJewelRadiusIndex    = helpers.getJewelRadiusIndex

local function extractTooltipStats(output)
	if not output then return nil end
	local out = { }
	for key, value in pairs(output) do
		local valueType = type(value)
		if valueType == "number" or valueType == "string" or valueType == "boolean" then
			out[key] = value
		end
	end
	if output.Minion then
		out.Minion = extractTooltipStats(output.Minion)
	end
	return out
end

local function normalizeImpactStat(impactStat)
	if type(impactStat) == "string" then
		return {
			field = impactStat,
			label = impactStat,
			selection = { stat = impactStat, label = impactStat },
		}
	elseif impactStat and impactStat.stat and not impactStat.selection then
		return {
			field = impactStat.stat,
			label = impactStat.label,
			selection = impactStat,
		}
	end
	return impactStat
end

function RadiusJewelComputeClass:new(finder)
	return setmetatable({
		finder = finder,
		build = finder.build,
	}, self)
end

function RadiusJewelComputeClass:getImpactValue(impactStat, output)
	impactStat = normalizeImpactStat(impactStat)
	local selection = impactStat.selection or impactStat
	if selection.getValue then
		return selection.getValue(output, self.build)
	end
	local statOutput = output
	if statOutput and statOutput.Minion and selection.stat ~= "FullDPS" then
		statOutput = statOutput.Minion
	end
	local value = statOutput and (statOutput[selection.stat] or 0) or 0
	if selection.transform then
		value = selection.transform(value)
	end
	return value
end

function RadiusJewelComputeClass:calculateImpactDelta(impactStat, baselineOutput, compareOutput)
	impactStat = normalizeImpactStat(impactStat)
	local selection = impactStat.selection or impactStat
	return self.build.calcsTab:CalculatePowerStat(selection, compareOutput, baselineOutput)
end

function RadiusJewelComputeClass:getSocketOccupancyInfo(...)
	return self.finder:getSocketOccupancyInfo(...)
end

function RadiusJewelComputeClass:socketMatchesOccupiedMode(...)
	return self.finder:socketMatchesOccupiedMode(...)
end

function RadiusJewelComputeClass:getSocketBasePoints(...)
	return self.finder:getSocketBasePoints(...)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Local helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function progressTick(progress, done, total, label)
	if progress and progress.tick then
		progress:tick(done, total, label)
	end
end

local function progressChild(progress, startFraction, spanFraction)
	if progress and progress.child then
		return progress:child(startFraction, spanFraction)
	end
	return progress
end

local function copyRequest(request)
	local copied = { }
	for key, value in pairs(request) do
		copied[key] = value
	end
	return copied
end

local function calculateWithSocketDistance(calcFunc, override, socketNode, distance)
	local previousDistance = socketNode.distanceToClassStart
	socketNode.distanceToClassStart = distance
	local ok, output = xpcall(function()
		return calcFunc(override)
	end, debug.traceback)
	socketNode.distanceToClassStart = previousDistance
	if not ok then
		error(output, 0)
	end
	return output
end

local function isDisconnectedPassiveCandidateNode(node, keystoneOnly, notableOrKeystoneOnly)
	if not node then
		return false
	end
	if node.ascendancyName then
		return false
	end
	if node.type == "Socket" or node.type == "ClassStart" or node.type == "AscendClassStart" or node.type == "Mastery" then
		return false
	end
	if keystoneOnly then
		return node.type == "Keystone"
	end
	if notableOrKeystoneOnly then
		return node.type == "Keystone" or node.type == "Notable"
	end
	return true
end

local function getPassiveNodeLabel(node)
	return node.dn or node.name or tostring(node.id or "?")
end

local function buildChosenNodesSummary(nodes, variantLabel)
	local labels = { }
	for _, node in ipairs(nodes) do
		t_insert(labels, getPassiveNodeLabel(node))
	end
	t_sort(labels)
	local prefix = #labels == 1 and "1 node" or s_format("%d nodes", #labels)
	if #labels == 0 then
		return variantLabel and (variantLabel .. " | jewel only") or "jewel only"
	end
	local summary = labels[1]
	if #labels >= 2 then
		summary = summary .. ", " .. labels[2]
	end
	if #labels > 2 then
		summary = summary .. s_format(", +%d more", #labels - 2)
	end
	if variantLabel and variantLabel ~= "" then
		return s_format("%s | %s: %s", variantLabel, prefix, summary)
	end
	return s_format("%s: %s", prefix, summary)
end

local function copyNodeList(nodes)
	local out = { }
	for i, node in ipairs(nodes) do
		out[i] = node
	end
	return out
end

local function buildNodeEntries(nodes)
	local entries = { }
	for _, node in ipairs(nodes or { }) do
		if type(node) == "table" then
			t_insert(entries, {
				label = getPassiveNodeLabel(node),
				nodeId = node.id,
			})
		else
			t_insert(entries, {
				label = tostring(node),
			})
		end
	end
	t_sort(entries, function(a, b)
		return (a.label or "") < (b.label or "")
	end)
	return entries
end

local function buildReplacementItem(slot)
	local item = new("Item"):Item("Rarity: Normal\nCobalt Jewel")
	item:BuildModList()
	if slot and slot.selItemId == 0 then
		item.jewelSocketSource = "empty"
	end
	return item
end

local function itemNeedsRadiusComparisonSpec(itemsTab, item)
	return itemsTab:ItemNeedsMainTreeComparisonSpec(item)
		or not not (item and item.type == "Jewel" and item.clusterJewel)
end

local function buildDisconnectedPassivePlanStep(baseOutput, baseValue, value, compareOutput, chosenNodes, variantLabel)
	local snapshotNodes = copyNodeList(chosenNodes)
	return {
		value = value,
		delta = value - baseValue,
		baseOutput = extractTooltipStats(baseOutput),
		compareOutput = extractTooltipStats(compareOutput),
		chosenNodes = snapshotNodes,
		resultNodes = buildNodeEntries(snapshotNodes),
		resultNodeLabels = buildNodeLabelList(snapshotNodes),
		addedNodeCount = #snapshotNodes,
		detailText = buildChosenNodesSummary(snapshotNodes, variantLabel),
	}
end

-- Exported for the UI to build compute result rows
local function buildDisplayedDisconnectedPassivePlans(result, socketBasePoints, baseline)
	if not result.planSteps or #result.planSteps == 0 then
		return { result }
	end
	local displayedPlans = { }
	local bestPctPerPoint = -math.huge
	for _, step in ipairs(result.planSteps) do
		local totalPoints = socketBasePoints + (step.addedNodeCount or 0)
		local pct = calculateImpactPercent(step.delta, baseline)
		local pctPerPoint = totalPoints > 0 and (pct / totalPoints) or pct
		if pctPerPoint > bestPctPerPoint + 1e-9 then
			t_insert(displayedPlans, step)
			bestPctPerPoint = pctPerPoint
		end
	end
	local finalPlan = result
	local lastDisplayed = displayedPlans[#displayedPlans]
	if not lastDisplayed or (lastDisplayed.addedNodeCount or 0) ~= (finalPlan.addedNodeCount or 0) then
		t_insert(displayedPlans, finalPlan)
	end
	return displayedPlans
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Class methods
-- ─────────────────────────────────────────────────────────────────────────────

function RadiusJewelComputeClass:buildSocketReplacementContext(calcFunc, socketId)
	local socketNode = self.build.spec.nodes[socketId] or self.build.spec.tree.nodes[socketId]
	if not socketNode then
		return nil
	end
	local occupancy = self:getSocketOccupancyInfo(socketId)
	local slotName = "Jewel " .. tostring(socketId)
	local baselineItem = occupancy.isOccupied and occupancy.item or buildReplacementItem(occupancy.slot)
	local baselineOutput = calcFunc({
		addNodes = { [socketNode] = true },
		repSlotName = slotName,
		repItem = baselineItem,
	})
	return {
		socketNode = socketNode,
		slotName = slotName,
		occupancy = occupancy,
		baselineItem = baselineItem,
		baselineOutput = baselineOutput,
		replacedItemLabel = occupancy.replacedItemLabel,
		storedUnallocatedItemLabel = occupancy.storedUnallocatedItemLabel,
	}
end

function RadiusJewelComputeClass:socketReplacementChangesPassiveTree(replacementContext, item)
	local replacedItem = replacementContext.occupancy and replacementContext.occupancy.isOccupied and replacementContext.occupancy.item
	return itemNeedsRadiusComparisonSpec(self.build.itemsTab, replacedItem)
		or itemNeedsRadiusComparisonSpec(self.build.itemsTab, item)
end

function RadiusJewelComputeClass:getImpossibleEscapePlanCacheKey(statField, variantName, replacementContext)
	local cacheKey = s_format("IE|%s|%s", statField, variantName)
	local occupancy = replacementContext.occupancy
	if occupancy and occupancy.isOccupied and itemNeedsRadiusComparisonSpec(self.build.itemsTab, occupancy.item) then
		-- Removing a structural jewel changes the comparison spec for this socket.
		return s_format("%s|%s", cacheKey, replacementContext.socketNode.id)
	end
	return cacheKey
end

function RadiusJewelComputeClass:buildSocketReplacementOverride(replacementContext, item, addNodes)
	local override = {
		addNodes = addNodes,
		repSlotName = replacementContext.slotName,
		repItem = item,
	}
	if self:socketReplacementChangesPassiveTree(replacementContext, item) then
		-- repItem changes only the evaluated item. Structural jewels can also
		-- change node ownership and dependencies, so rebuild a comparison spec first.
		local socketNode = replacementContext.socketNode
		replacementContext.comparisonSpecs = replacementContext.comparisonSpecs or { }
		local spec = replacementContext.comparisonSpecs[item]
		if not spec then
			local replacedItem = replacementContext.occupancy and replacementContext.occupancy.item
			local rebuildClusterJewelGraphs = (replacedItem and replacedItem.clusterJewel) or item.clusterJewel
			spec = self.build.itemsTab:BuildSpecForJewelComparison({ nodeId = socketNode.id }, item, not socketNode.alloc, rebuildClusterJewelGraphs)
			replacementContext.comparisonSpecs[item] = spec
		end
		override.spec = spec
		if addNodes then
			local comparisonNodes = { }
			for node in pairs(addNodes) do
				comparisonNodes[spec.nodes[node.id] or node] = true
			end
			override.addNodes = comparisonNodes
		end
	end
	return override
end

function RadiusJewelComputeClass:getSocketDistanceToClassStart(socketId)
	local spec = self.build.spec
	local socketNode = spec.nodes[socketId]
	if not socketNode then
		return 0
	end
	if socketNode.alloc and socketNode.connectedToStart then
		return socketNode.distanceToClassStart or 0
	end

	local targetNodeId = spec.curClass.startNodeId
	local nodeDistanceToRoot = { [socketNode.id] = 0 }
	local queue = { socketNode }
	local outIndex, inIndex = 1, 2
	while outIndex < inIndex do
		local node = queue[outIndex]
		outIndex = outIndex + 1
		local curDist = nodeDistanceToRoot[node.id] + 1
		for _, other in ipairs(node.linked) do
			if other.id == targetNodeId then
				return curDist - 1
			end
			if node.type ~= "Mastery"
			and other.type ~= "ClassStart"
			and other.type ~= "AscendClassStart"
			and not nodeDistanceToRoot[other.id]
			and (node.ascendancyName == other.ascendancyName or (nodeDistanceToRoot[node.id] == 0 and not other.ascendancyName)) then
				nodeDistanceToRoot[other.id] = curDist
				queue[inIndex] = other
				inIndex = inIndex + 1
			end
		end
	end

	return 0
end

-- Candidates are unallocated passives a disconnected-passive jewel may add before scoring.
function RadiusJewelComputeClass:collectDisconnectedPassiveCandidates(socketNode, options)
	local allocNodes = self.build.spec.allocNodes
	local candidates = { }
	local seen = { }
	local sourceNodes
	if options.collectNodes then
		sourceNodes = options.collectNodes(socketNode)
	else
		sourceNodes = socketNode and socketNode.nodesInRadius and options.radiusIndex and socketNode.nodesInRadius[options.radiusIndex]
	end
	if not sourceNodes then
		return candidates
	end
	for nodeId, node in pairs(sourceNodes) do
		if not seen[nodeId] and not allocNodes[nodeId] and isDisconnectedPassiveCandidateNode(node, options.keystoneOnly, options.notableOrKeystoneOnly) then
			t_insert(candidates, node)
			seen[nodeId] = true
		end
	end
	t_sort(candidates, function(a, b)
		if a.type ~= b.type then
			if a.type == "Keystone" then
				return true
			end
			if b.type == "Keystone" then
				return false
			end
			if a.type == "Notable" then
				return true
			end
			if b.type == "Notable" then
				return false
			end
		end
		return getPassiveNodeLabel(a) < getPassiveNodeLabel(b)
	end)
	return candidates
end

function RadiusJewelComputeClass:computeDisconnectedPassiveSimulatedPlan(request)
	local calcFunc = request.calcFunc
	local replacementContext = request.replacementContext
	local baseOutput = request.baseOutput
	local baseValue = request.baseValue
	local socketNode = request.socketNode
	local item = request.item
	local impactStat = request.impactStat
	local candidates = request.candidates
	local variantLabel = request.variantLabel
	local progressLabel = request.progressLabel
	local progress = request.progress
	local maxAdditionalNodes = request.maxAdditionalNodes
	impactStat = normalizeImpactStat(impactStat)
	local addNodes = { [socketNode] = true }
	local function calculate(extraNode)
		local nextNodes = copyTable(addNodes, true)
		if extraNode then
			nextNodes[extraNode] = true
		end
		local output = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, nextNodes))
		return output, self:getImpactValue(impactStat, output)
	end

	local currentOutput, currentValue = calculate()
	local chosenNodes = { }
	local chosenNodeIds = { }
	if maxAdditionalNodes and maxAdditionalNodes <= 0 then
		return buildDisconnectedPassivePlanStep(baseOutput, baseValue, currentValue, currentOutput, chosenNodes, variantLabel)
	end
	local planSteps = { }

	while true do
		if maxAdditionalNodes and #chosenNodes >= maxAdditionalNodes then
			break
		end
		local bestCandidate
		for candidateIndex, node in ipairs(candidates) do
			progressTick(progress, candidateIndex, #candidates, progressLabel)
			if not chosenNodeIds[node.id] then
				local output, value = calculate(node)
				-- Marginal delta is this node's extra gain over the current greedy plan.
				local marginalDelta = value - currentValue
				if not bestCandidate
				or marginalDelta > bestCandidate.marginalDelta
				or (marginalDelta == bestCandidate.marginalDelta and getPassiveNodeLabel(node) < getPassiveNodeLabel(bestCandidate.node)) then
					bestCandidate = {
						node = node,
						output = output,
						value = value,
						marginalDelta = marginalDelta,
					}
				end
			end
		end
		if not bestCandidate or bestCandidate.marginalDelta <= 0 then
			break
		end
		chosenNodeIds[bestCandidate.node.id] = true
		addNodes[bestCandidate.node] = true
		t_insert(chosenNodes, bestCandidate.node)
		currentOutput = bestCandidate.output
		currentValue = bestCandidate.value
		t_insert(planSteps, buildDisconnectedPassivePlanStep(baseOutput, baseValue, currentValue, currentOutput, chosenNodes, variantLabel))
	end

	local result = buildDisconnectedPassivePlanStep(baseOutput, baseValue, currentValue, currentOutput, chosenNodes, variantLabel)
	result.planSteps = planSteps
	return result
end

function RadiusJewelComputeClass:computeDisconnectedPassiveFastPlan(request)
	local calcFunc = request.calcFunc
	local replacementContext = request.replacementContext
	local baseOutput = request.baseOutput
	local baseValue = request.baseValue
	local socketNode = request.socketNode
	local item = request.item
	local impactStat = request.impactStat
	local candidates = request.candidates
	local variantLabel = request.variantLabel
	local deltaCache = request.deltaCache
	local progressLabel = request.progressLabel
	local progress = request.progress
	local maxAdditionalNodes = request.maxAdditionalNodes
	local skipPlanSteps = request.skipPlanSteps
	impactStat = normalizeImpactStat(impactStat)
	local jewelOnlyOutput, jewelOnlyValue
	local function ensureJewelOnly()
		if not jewelOnlyOutput then
			jewelOnlyOutput = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, {
				[socketNode] = true,
			}))
			jewelOnlyValue = self:getImpactValue(impactStat, jewelOnlyOutput)
		end
	end
	if maxAdditionalNodes and maxAdditionalNodes <= 0 then
		ensureJewelOnly()
		local chosenNodes = { }
		return buildDisconnectedPassivePlanStep(baseOutput, baseValue, jewelOnlyValue, jewelOnlyOutput, chosenNodes, variantLabel)
	end
	local scoredCandidates = { }
	for candidateIndex, node in ipairs(candidates) do
		progressTick(progress, candidateIndex, #candidates, progressLabel)
		local delta = deltaCache[node.id]
		if delta == nil then
			ensureJewelOnly()
			local output = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, {
				[socketNode] = true,
				[node] = true,
			}))
			delta = self:getImpactValue(impactStat, output) - jewelOnlyValue
			deltaCache[node.id] = delta
		end
		if delta > 0 then
			t_insert(scoredCandidates, {
				node = node,
				delta = delta,
			})
		end
	end
	t_sort(scoredCandidates, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return getPassiveNodeLabel(a.node) < getPassiveNodeLabel(b.node)
	end)

	local chosenNodes = { }
	for i, entry in ipairs(scoredCandidates) do
		if maxAdditionalNodes and i > maxAdditionalNodes then
			break
		end
		t_insert(chosenNodes, entry.node)
	end

	local addNodes = { [socketNode] = true }
	for _, node in ipairs(chosenNodes) do
		addNodes[node] = true
	end

	if skipPlanSteps then
		local finalOutput = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, addNodes))
		local finalValue = self:getImpactValue(impactStat, finalOutput)
		return buildDisconnectedPassivePlanStep(baseOutput, baseValue, finalValue, finalOutput, chosenNodes, variantLabel)
	end

	local planSteps = { }
	local prefixNodes = { }
	local prefixAddNodes = { [socketNode] = true }
	local lastOutput, lastValue
	for _, node in ipairs(chosenNodes) do
		t_insert(prefixNodes, node)
		prefixAddNodes[node] = true
		lastOutput = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, prefixAddNodes))
		lastValue = self:getImpactValue(impactStat, lastOutput)
		t_insert(planSteps, buildDisconnectedPassivePlanStep(baseOutput, baseValue, lastValue, lastOutput, prefixNodes, variantLabel))
	end
	if not lastOutput then
		ensureJewelOnly()
		lastOutput = jewelOnlyOutput
		lastValue = jewelOnlyValue
	end

	local result = buildDisconnectedPassivePlanStep(baseOutput, baseValue, lastValue, lastOutput, chosenNodes, variantLabel)
	result.planSteps = planSteps
	return result
end

function RadiusJewelComputeClass:computeDisconnectedPassivePlan(request)
	if request.methodId == "fast" then
		return self:computeDisconnectedPassiveFastPlan(request)
	end
	return self:computeDisconnectedPassiveSimulatedPlan(request)
end

function RadiusJewelComputeClass:computeSocketImpact(request)
	local sockets = request.sockets
	local rawText = request.rawText
	local impactStat = request.impactStat
	local progress = request.progress
	local maxTotalPoints = request.maxTotalPoints
	local occupiedMode = request.occupiedMode
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local socketBasePoints = self:getSocketBasePoints(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or socketBasePoints <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
			item:BuildModList()
			local output = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, {
				[replacementContext.socketNode] = true,
			}))
			local value = self:getImpactValue(impactStat, output)
			local delta = self:calculateImpactDelta(impactStat, replacementContext.baselineOutput, output)
			t_insert(results, {
				socket = socket,
				value = value,
				delta = delta,
				replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
				storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
				baseOutput = extractTooltipStats(replacementContext.baselineOutput),
				compareOutput = extractTooltipStats(output),
			})
		end
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function RadiusJewelComputeClass:computeBestVariantSocketImpact(request)
	local sockets = request.sockets
	local variants = request.variants
	local impactStat = request.impactStat
	local progress = request.progress
	local maxTotalPoints = request.maxTotalPoints
	local occupiedMode = request.occupiedMode
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local socketBasePoints = self:getSocketBasePoints(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or socketBasePoints <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local bestResult
			for variantIndex, variant in ipairs(variants) do
				progressTick(socketProgress, variantIndex, #variants, socket.label .. " | " .. variant.name)
				local item = new("Item"):Item("Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				local output = calcFunc(self:buildSocketReplacementOverride(replacementContext, item, {
					[socketNode] = true,
				}))
				local value = self:getImpactValue(impactStat, output)
				local delta = self:calculateImpactDelta(impactStat, replacementContext.baselineOutput, output)
				if not bestResult or delta > bestResult.delta then
					bestResult = {
						socket = socket,
						variant = variant,
						variantIdx = variantIndex,
						value = value,
						delta = delta,
						replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
						storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
						baseOutput = extractTooltipStats(replacementContext.baselineOutput),
						compareOutput = extractTooltipStats(output),
					}
				end
			end
			if bestResult then
				t_insert(results, bestResult)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function RadiusJewelComputeClass:computeIntuitiveLeapSocketImpact(request)
	local sockets = request.sockets
	local impactStat = request.impactStat
	local variant = request.variant
	local methodId = request.methodId
	local planCache = request.planCache
	local progress = request.progress
	local maxTotalPoints = request.maxTotalPoints
	local occupiedMode = request.occupiedMode
	local skipPlanSteps = request.skipPlanSteps
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local statField = impactStat.field

	local keystoneOnly = variant and variant.keystoneOnly or false
	local rawText = (variant and variant.rawText) or mustGetUniqueRawText("Intuitive Leap")
	local candidateOptions = {
		radiusIndex = variant and variant.radiusIndex or getJewelRadiusIndex("Small"),
		keystoneOnly = keystoneOnly,
	}

	local variantKey = variant and variant.name or "normal"
	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local socketBasePoints = self:getSocketBasePoints(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or socketBasePoints <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
			item:BuildModList()
			local candidates = self:collectDisconnectedPassiveCandidates(socketNode, candidateOptions)
			if #candidates > 0 then
				local maxAdditionalNodes = maxTotalPoints and math.max(maxTotalPoints - socketBasePoints, 0) or nil
				local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
				local deltaCache
				if methodId == "fast" then
					local cacheKey = s_format("IL|%s|%s|%s", statField, variantKey, socket.id)
					planCache[cacheKey] = planCache[cacheKey] or { }
					deltaCache = planCache[cacheKey]
				end
				local result = self:computeDisconnectedPassivePlan({
					methodId = methodId,
					calcFunc = calcFunc,
					replacementContext = replacementContext,
					baseOutput = replacementContext.baselineOutput,
					baseValue = socketBaseline,
					socketNode = socketNode,
					item = item,
					impactStat = impactStat,
					candidates = candidates,
					deltaCache = deltaCache,
					progressLabel = socket.label,
					progress = socketProgress,
					maxAdditionalNodes = maxAdditionalNodes,
					skipPlanSteps = skipPlanSteps,
				})
				result.socket = socket
				result.variant = variant
				result.replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil
				result.storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil
				t_insert(results, result)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function RadiusJewelComputeClass:computeBestIntuitiveLeapSocketImpact(request)
	local variants = request.variants
	if not variants or #variants == 0 then
		return self:computeIntuitiveLeapSocketImpact(request)
	end
	local bestBySocket = { }
	local realBaseline
	local variantCount = #variants
	for variantIndex, variant in ipairs(variants) do
		local variantProgress = progressChild(request.progress, (variantIndex - 1) / variantCount, 1 / variantCount)
		local variantRequest = copyRequest(request)
		variantRequest.variant = variant
		variantRequest.progress = variantProgress
		local results, baseline = self:computeIntuitiveLeapSocketImpact(variantRequest)
		realBaseline = realBaseline or baseline
		for _, result in ipairs(results) do
			result.variant = variant
			local previous = bestBySocket[result.socket.id]
			if not previous
			or result.delta > previous.delta
			or (result.delta == previous.delta and result.addedNodeCount < previous.addedNodeCount)
			or (result.delta == previous.delta and result.addedNodeCount == previous.addedNodeCount and variant.name < previous.variant.name) then
				bestBySocket[result.socket.id] = result
			end
		end
	end
	local results = { }
	for _, result in pairs(bestBySocket) do
		t_insert(results, result)
	end
	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function RadiusJewelComputeClass:computeThreadOfHopeSocketImpact(request)
	local sockets = request.sockets
	local impactStat = request.impactStat
	local threadVariants = request.variants
	local methodId = request.methodId
	local planCache = request.planCache
	local progress = request.progress
	local maxTotalPoints = request.maxTotalPoints
	local occupiedMode = request.occupiedMode
	local skipPlanSteps = request.skipPlanSteps
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local statField = impactStat.field
	local results = { }

	-- Pre-build items per ring variant (avoid re-creating inside the socket loop)
	local threadItems = { }
	for variantIndex, threadVariant in ipairs(threadVariants) do
		local item = new("Item"):Item("Rarity: Unique\n" .. threadVariant.rawText)
		item:BuildModList()
		threadItems[variantIndex] = item
	end

	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local socketBasePoints = self:getSocketBasePoints(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or socketBasePoints <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
			local bestResult
			for variantIndex, threadVariant in ipairs(threadVariants) do
				local variantProgress = progressChild(socketProgress, (variantIndex - 1) / #threadVariants, 1 / #threadVariants)
				local item = threadItems[variantIndex]
				local ringLabel = threadVariant.ringLabel or (threadVariant.name .. " Ring")
				local candidates = self:collectDisconnectedPassiveCandidates(socketNode, {
					radiusIndex = threadVariant.radiusIndex,
					notableOrKeystoneOnly = skipPlanSteps or methodId == "fast",
				})
				if #candidates > 0 then
					local maxAdditionalNodes = maxTotalPoints and math.max(maxTotalPoints - socketBasePoints, 0) or nil
					local deltaCache
					if methodId == "fast" then
						local cacheKey = s_format("ThreadOfHope|%s|%s", statField, socket.id)
						planCache[cacheKey] = planCache[cacheKey] or { }
						deltaCache = planCache[cacheKey]
					end
					local result = self:computeDisconnectedPassivePlan({
						methodId = methodId,
						calcFunc = calcFunc,
						replacementContext = replacementContext,
						baseOutput = replacementContext.baselineOutput,
						baseValue = socketBaseline,
						socketNode = socketNode,
						item = item,
						impactStat = impactStat,
						candidates = candidates,
						variantLabel = ringLabel,
						deltaCache = deltaCache,
						progressLabel = socket.label .. " | " .. ringLabel,
						progress = variantProgress,
						maxAdditionalNodes = maxAdditionalNodes,
						skipPlanSteps = skipPlanSteps,
					})
					result.variant = threadVariant
					if not bestResult
					or result.delta > bestResult.delta
					or (result.delta == bestResult.delta and result.addedNodeCount < bestResult.addedNodeCount)
					or (result.delta == bestResult.delta and result.addedNodeCount == bestResult.addedNodeCount and threadVariant.radiusIndex < bestResult.variant.radiusIndex) then
						bestResult = result
					end
				end
			end
			if bestResult then
				bestResult.socket = socket
				bestResult.replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil
				bestResult.storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil
				t_insert(results, bestResult)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return a.variant.radiusIndex < b.variant.radiusIndex
	end)

	return results, realBaseline
end

function RadiusJewelComputeClass:computeSplitPersonalitySocketImpact(request)
	local sockets = request.sockets
	local impactStat = request.impactStat
	local variants = request.variants
	local progress = request.progress
	local maxTotalPoints = request.maxTotalPoints
	local occupiedMode = request.occupiedMode
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local results = { }

	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local socketBasePoints = self:getSocketBasePoints(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or socketBasePoints <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local slotName = replacementContext.slotName
			local splitDistance = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
			local baselineOutput = calculateWithSocketDistance(calcFunc, {
				addNodes = { [socketNode] = true },
				repSlotName = slotName,
				repItem = replacementContext.baselineItem,
			}, socketNode, splitDistance)

			local bestResult
			for variantIdx, variant in ipairs(variants) do
				progressTick(socketProgress, variantIdx, #variants, socket.label .. " | " .. variant.name)
				local item = new("Item"):Item("Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				local override = self:buildSocketReplacementOverride(replacementContext, item, {
					[socketNode] = true,
				})
				if override.spec then
					override.spec.nodes[socketNode.id].distanceToClassStart = splitDistance
				end
				local output = override.spec and calcFunc(override)
					or calculateWithSocketDistance(calcFunc, override, socketNode, splitDistance)
				local value = self:getImpactValue(impactStat, output)
				local delta = self:calculateImpactDelta(impactStat, baselineOutput, output)
				if not bestResult or delta > bestResult.delta then
					bestResult = {
						socket = socket,
						variant = variant,
						variantIdx = variantIdx,
						value = value,
						delta = delta,
						replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
						storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
						baseOutput = extractTooltipStats(baselineOutput),
						compareOutput = extractTooltipStats(output),
						detailText = s_format("Dist %d | %s", splitDistance, variant.name),
					}
				end
			end

			if bestResult then
				bestResult.splitDistance = splitDistance
				t_insert(results, bestResult)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return (a.splitDistance or 0) > (b.splitDistance or 0)
	end)
	return results, realBaseline
end

local function getSmallRadiusIndex()
	return getJewelRadiusIndex("Small")
end

local function prepareImpossibleEscapeVariants(self, variants, smallRadiusIndex, notableOrKeystoneOnly)
	local variantDataByName = { }
	for _, variant in ipairs(variants) do
		local keystoneNode = self.build.spec.tree.keystoneMap[variant.keystoneName]
		if keystoneNode and keystoneNode.nodesInRadius and keystoneNode.nodesInRadius[smallRadiusIndex] then
			local candidates = self:collectDisconnectedPassiveCandidates(nil, {
				collectNodes = function()
					return keystoneNode.nodesInRadius[smallRadiusIndex]
				end,
				notableOrKeystoneOnly = notableOrKeystoneOnly,
			})
			if #candidates > 0 then
				local item = new("Item"):Item("Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				variantDataByName[variant.name] = {
					variant = variant,
					item = item,
					keystoneNode = keystoneNode,
					candidates = candidates,
				}
			end
		end
	end
	return variantDataByName
end

-- Free sockets with the same remaining points share one representative.
-- Occupied sockets stay separate because each replacement state can differ.
local function groupImpossibleEscapeSockets(self, sockets, maxTotalPoints, occupiedMode)
	local groupedEntries = { }
	local groupedOrder = { }
	for _, socket in ipairs(sockets) do
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local socketBasePoints = self:getSocketBasePoints(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or socketBasePoints <= maxTotalPoints) then
			local remainingPoints = maxTotalPoints and math.max(maxTotalPoints - socketBasePoints, 0) or -1
			local groupKey = occupancy and occupancy.isOccupied and ("occupied:" .. socket.id) or ("free:" .. tostring(remainingPoints))
			if not groupedEntries[groupKey] then
				groupedEntries[groupKey] = {
					groupKey = groupKey,
					remainingPoints = remainingPoints,
					sockets = { },
					representativeSocket = socket,
					occupancy = occupancy,
				}
				t_insert(groupedOrder, groupedEntries[groupKey])
			end
			t_insert(groupedEntries[groupKey].sockets, socket)
		end
	end
	t_sort(groupedOrder, function(a, b)
		if a.remainingPoints ~= b.remainingPoints then
			return a.remainingPoints > b.remainingPoints
		end
		return a.representativeSocket.id < b.representativeSocket.id
	end)
	return groupedOrder
end

local function computeImpossibleEscapeRepresentativeResults(self, request)
	local groupedOrder = request.groupedOrder
	local variants = request.variants
	local variantDataByName = request.variantDataByName
	local methodId = request.methodId
	local impactStat = request.impactStat
	local statField = request.statField
	local calcFunc = request.calcFunc
	local planCache = request.planCache
	local progress = request.progress
	local bestResultByGroupKey = { }
	local totalPlanCount = #groupedOrder * #variants
	local currentPlanIndex = 0
	for _, groupEntry in ipairs(groupedOrder) do
		local representativeSocket = groupEntry.representativeSocket
		local replacementContext = self:buildSocketReplacementContext(calcFunc, representativeSocket.id)
		local representativeSocketNode = replacementContext.socketNode
		local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
		local bestResult
		for _, variant in ipairs(variants) do
			currentPlanIndex = currentPlanIndex + 1
			local planProgress = progressChild(progress, (currentPlanIndex - 1) / totalPlanCount, 1 / totalPlanCount)
			local variantData = variantDataByName[variant.name]
			if variantData then
				local maxAdditionalNodes = groupEntry.remainingPoints >= 0 and groupEntry.remainingPoints or nil
				local deltaCache
				if methodId == "fast" then
					local cacheKey = self:getImpossibleEscapePlanCacheKey(statField, variant.name, replacementContext)
					planCache[cacheKey] = planCache[cacheKey] or { }
					deltaCache = planCache[cacheKey]
				end
				local result = self:computeDisconnectedPassivePlan({
					methodId = methodId,
					calcFunc = calcFunc,
					replacementContext = replacementContext,
					baseOutput = replacementContext.baselineOutput,
					baseValue = socketBaseline,
					socketNode = representativeSocketNode,
					item = variantData.item,
					impactStat = impactStat,
					candidates = variantData.candidates,
					variantLabel = variant.name,
					deltaCache = deltaCache,
					progressLabel = variant.name,
					progress = planProgress,
					maxAdditionalNodes = maxAdditionalNodes,
					skipPlanSteps = true,
				})
				result.variant = variant
				if not bestResult
				or result.delta > bestResult.delta
				or (result.delta == bestResult.delta and result.addedNodeCount < bestResult.addedNodeCount)
				or (result.delta == bestResult.delta and result.addedNodeCount == bestResult.addedNodeCount and variant.name < bestResult.variant.name) then
					bestResult = result
				end
			end
			progressTick(planProgress, 1, 1, variant.name)
		end
		if bestResult then
			bestResult.impossibleEscapeGroupKey = groupEntry.groupKey
		end
		bestResultByGroupKey[groupEntry.groupKey] = bestResult
	end
	return bestResultByGroupKey
end

local function fanOutImpossibleEscapeResults(self, groupedOrder, bestResultByGroupKey)
	local results = { }
	for _, groupEntry in ipairs(groupedOrder) do
		local bestResult = bestResultByGroupKey[groupEntry.groupKey]
		if bestResult then
			for _, socket in ipairs(groupEntry.sockets) do
				local socketOccupancy = self:getSocketOccupancyInfo(socket.id)
				local resultForSocket = copyTableSafe(bestResult, false, true)
				resultForSocket.impossibleEscapeGroupKey = groupEntry.groupKey
				resultForSocket.socket = socket
				resultForSocket.replacedItemLabel = socketOccupancy and socketOccupancy.replacedItemLabel or nil
				resultForSocket.storedUnallocatedItemLabel = socketOccupancy and socketOccupancy.storedUnallocatedItemLabel or nil
				t_insert(results, resultForSocket)
			end
		end
	end
	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return a.variant.name < b.variant.name
	end)
	return results
end

local function addImpossibleEscapePlanDetails(self, request)
	local results = request.results
	local groupedOrder = request.groupedOrder
	local bestResultByGroupKey = request.bestResultByGroupKey
	local variantDataByName = request.variantDataByName
	local impactStat = request.impactStat
	local statField = request.statField
	local calcFunc = request.calcFunc
	local planCache = request.planCache
	for _, groupEntry in ipairs(groupedOrder) do
		local bestResult = bestResultByGroupKey[groupEntry.groupKey]
		local variantData = bestResult and variantDataByName[bestResult.variant.name]
		if variantData then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, groupEntry.representativeSocket.id)
			local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
			local maxAdditionalNodes = groupEntry.remainingPoints >= 0 and groupEntry.remainingPoints or nil
			local cacheKey = self:getImpossibleEscapePlanCacheKey(statField, bestResult.variant.name, replacementContext)
			planCache[cacheKey] = planCache[cacheKey] or { }
			local fullResult = self:computeDisconnectedPassiveFastPlan({
				calcFunc = calcFunc,
				replacementContext = replacementContext,
				baseOutput = replacementContext.baselineOutput,
				baseValue = socketBaseline,
				socketNode = replacementContext.socketNode,
				item = variantData.item,
				impactStat = impactStat,
				candidates = variantData.candidates,
				variantLabel = bestResult.variant.name,
				deltaCache = planCache[cacheKey],
				maxAdditionalNodes = maxAdditionalNodes,
				skipPlanSteps = false,
			})
			fullResult.variant = bestResult.variant
			fullResult.impossibleEscapeGroupKey = groupEntry.groupKey
			for i, result in ipairs(results) do
				if result.impossibleEscapeGroupKey == groupEntry.groupKey then
					local updated = copyTableSafe(fullResult, false, true)
					updated.socket = result.socket
					updated.replacedItemLabel = result.replacedItemLabel
					updated.storedUnallocatedItemLabel = result.storedUnallocatedItemLabel
					results[i] = updated
				end
			end
		end
	end
end

function RadiusJewelComputeClass:computeImpossibleEscapeSocketImpact(request)
	local sockets = request.sockets
	local impactStat = request.impactStat
	local variants = request.variants
	local methodId = request.methodId
	local planCache = request.planCache
	local progress = request.progress
	local maxTotalPoints = request.maxTotalPoints
	local occupiedMode = request.occupiedMode
	local skipPlanSteps = request.skipPlanSteps
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local statField = impactStat.field
	local notableOrKeystoneOnly = skipPlanSteps or methodId == "fast"
	local variantDataByName = prepareImpossibleEscapeVariants(self, variants, getSmallRadiusIndex(), notableOrKeystoneOnly)
	local groupedOrder = groupImpossibleEscapeSockets(self, sockets, maxTotalPoints, occupiedMode)
	if #groupedOrder == 0 then
		return { }, realBaseline
	end
	local bestResultByGroupKey = computeImpossibleEscapeRepresentativeResults(self, {
		groupedOrder = groupedOrder,
		variants = variants,
		variantDataByName = variantDataByName,
		methodId = methodId,
		impactStat = impactStat,
		statField = statField,
		calcFunc = calcFunc,
		planCache = planCache,
		progress = progress,
	})
	local results = fanOutImpossibleEscapeResults(self, groupedOrder, bestResultByGroupKey)
	if not skipPlanSteps and methodId == "fast" and #results > 0 then
		addImpossibleEscapePlanDetails(self, {
			results = results,
			groupedOrder = groupedOrder,
			bestResultByGroupKey = bestResultByGroupKey,
			variantDataByName = variantDataByName,
			impactStat = impactStat,
			statField = statField,
			calcFunc = calcFunc,
			planCache = planCache,
		})
	end

	return results, realBaseline
end

return {
	new = function(finder)
		return RadiusJewelComputeClass:new(finder)
	end,
	buildDisplayedDisconnectedPassivePlans = buildDisplayedDisconnectedPassivePlans,
}

end -- return function(helpers)
