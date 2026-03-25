-- Path of Building
--
-- Module: Radius Jewel Compute
-- Compute methods for the Radius Jewel Finder — calcFunc-based impact evaluation
-- across all socket × jewel combinations.
--
-- Usage:
--   local attachCompute = LoadModule("Classes/RadiusJewelCompute")
--   attachCompute(RadiusJewelFinderClass, { extractTooltipStats, normalizeImpactStat, calculateImpactPercent, mustGetUniqueRawText })
--
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local s_format = string.format

return function(Class, helpers)

local extractTooltipStats    = helpers.extractTooltipStats
local normalizeImpactStat    = helpers.normalizeImpactStat
local calculateImpactPercent = helpers.calculateImpactPercent
local mustGetUniqueRawText   = helpers.mustGetUniqueRawText

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

local function isConnectionlessCandidateNode(node, keystoneOnly)
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

local function buildNodeLabelList(nodes)
	local labels = { }
	for _, node in ipairs(nodes or { }) do
		if type(node) == "table" then
			if node.label then
				t_insert(labels, node.label)
			else
				t_insert(labels, getPassiveNodeLabel(node))
			end
		else
			t_insert(labels, tostring(node))
		end
	end
	return labels
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
	local item = new("Item", "Rarity: Normal\nCobalt Jewel")
	item:BuildModList()
	if slot and slot.selItemId == 0 then
		item.jewelSocketSource = "empty"
	end
	return item
end

local function buildConnectionlessPlanStep(baseOutput, baseValue, value, compareOutput, chosenNodes, variantLabel)
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
local function buildDisplayedConnectionlessPlans(result, socketBasePoints, baseline)
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

function Class:buildSocketReplacementContext(calcFunc, socketId)
	local socketNode = self.build.spec.nodes[socketId] or self.build.spec.tree.nodes[socketId]
	if not socketNode then
		return nil
	end
	local occupancy = self:getSocketOccupancyInfo(socketId)
	local slotName = "Jewel " .. tostring(socketId)
	local baselineItem = occupancy.item or buildReplacementItem(occupancy.slot)
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
		replacedItemLabel = occupancy.isOccupied and occupancy.itemLabel or nil,
	}
end

function Class:getSocketDistanceToClassStart(socketId)
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

function Class:collectConnectionlessCandidates(socketNode, options)
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
		if not seen[nodeId] and not allocNodes[nodeId] and isConnectionlessCandidateNode(node, options.keystoneOnly) then
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

function Class:computeConnectionlessSimulatedPlan(calcFunc, baseOutput, baseValue, socketNode, slotName, item, impactStat, candidates, variantLabel, progressLabel, progress, maxAdditionalNodes)
	impactStat = normalizeImpactStat(impactStat)
	local addNodes = { [socketNode] = true }
	local function calculate(extraNode)
		local nextNodes = copyTable(addNodes, true)
		if extraNode then
			nextNodes[extraNode] = true
		end
		local output = calcFunc({
			addNodes = nextNodes,
			repSlotName = slotName,
			repItem = item,
		})
		return output, self:getImpactValue(impactStat, output)
	end

	local currentOutput, currentValue = calculate()
	local chosenNodes = { }
	local chosenNodeIds = { }
	if maxAdditionalNodes and maxAdditionalNodes <= 0 then
		return buildConnectionlessPlanStep(baseOutput, baseValue, currentValue, currentOutput, chosenNodes, variantLabel)
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
		t_insert(planSteps, buildConnectionlessPlanStep(baseOutput, baseValue, currentValue, currentOutput, chosenNodes, variantLabel))
	end

	local result = buildConnectionlessPlanStep(baseOutput, baseValue, currentValue, currentOutput, chosenNodes, variantLabel)
	result.planSteps = planSteps
	return result
end

function Class:computeConnectionlessFastPlan(calcFunc, baseOutput, baseValue, socketNode, slotName, item, impactStat, candidates, variantLabel, deltaCache, progressLabel, progress, maxAdditionalNodes, skipPlanSteps)
	impactStat = normalizeImpactStat(impactStat)
	local jewelOnlyOutput, jewelOnlyValue
	local function ensureJewelOnly()
		if not jewelOnlyOutput then
			jewelOnlyOutput = calcFunc({
				addNodes = { [socketNode] = true },
				repSlotName = slotName,
				repItem = item,
			})
			jewelOnlyValue = self:getImpactValue(impactStat, jewelOnlyOutput)
		end
	end
	if maxAdditionalNodes and maxAdditionalNodes <= 0 then
		ensureJewelOnly()
		local chosenNodes = { }
		return buildConnectionlessPlanStep(baseOutput, baseValue, jewelOnlyValue, jewelOnlyOutput, chosenNodes, variantLabel)
	end
	local scoredCandidates = { }
	for candidateIndex, node in ipairs(candidates) do
		progressTick(progress, candidateIndex, #candidates, progressLabel)
		local delta = deltaCache[node.id]
		if delta == nil then
			ensureJewelOnly()
			local output = calcFunc({
				addNodes = { [socketNode] = true, [node] = true },
				repSlotName = slotName,
				repItem = item,
			})
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
		local finalOutput = calcFunc({
			addNodes = addNodes,
			repSlotName = slotName,
			repItem = item,
		})
		local finalValue = self:getImpactValue(impactStat, finalOutput)
		return buildConnectionlessPlanStep(baseOutput, baseValue, finalValue, finalOutput, chosenNodes, variantLabel)
	end

	local planSteps = { }
	local prefixNodes = { }
	local prefixAddNodes = { [socketNode] = true }
	for _, node in ipairs(chosenNodes) do
		t_insert(prefixNodes, node)
		prefixAddNodes[node] = true
		local prefixOutput = calcFunc({
			addNodes = prefixAddNodes,
			repSlotName = slotName,
			repItem = item,
		})
		local prefixValue = self:getImpactValue(impactStat, prefixOutput)
		t_insert(planSteps, buildConnectionlessPlanStep(baseOutput, baseValue, prefixValue, prefixOutput, prefixNodes, variantLabel))
	end
	local finalOutput = calcFunc({
		addNodes = addNodes,
		repSlotName = slotName,
		repItem = item,
	})
	local finalValue = self:getImpactValue(impactStat, finalOutput)

	local result = buildConnectionlessPlanStep(baseOutput, baseValue, finalValue, finalOutput, chosenNodes, variantLabel)
	result.planSteps = planSteps
	return result
end

function Class:computeSocketImpact(sockets, rawText, impactStat, progress, maxTotalPoints, occupiedMode)
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local accessCost = self:getSocketAccessCost(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or accessCost <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local slotName = replacementContext.slotName
			local item = new("Item", "Rarity: Unique\n" .. rawText)
			item:BuildModList()
			local output = calcFunc({
				addNodes = { [replacementContext.socketNode] = true },
				repSlotName = slotName,
				repItem = item,
			})
			local value = self:getImpactValue(impactStat, output)
			local delta = self:calculateImpactDelta(impactStat, replacementContext.baselineOutput, output)
			t_insert(results, {
				socket = socket,
				value = value,
				delta = delta,
				replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
				baseOutput = extractTooltipStats(replacementContext.baselineOutput),
				compareOutput = extractTooltipStats(output),
			})
		end
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function Class:computeBestVariantSocketImpact(sockets, variants, impactStat, progress, maxTotalPoints, occupiedMode)
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)

	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local accessCost = self:getSocketAccessCost(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or accessCost <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local slotName = replacementContext.slotName
			local socketNode = replacementContext.socketNode
			local bestResult
			for variantIndex, variant in ipairs(variants) do
				progressTick(socketProgress, variantIndex, #variants, socket.label .. " | " .. variant.name)
				local item = new("Item", "Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				local output = calcFunc({
					addNodes = { [socketNode] = true },
					repSlotName = slotName,
					repItem = item,
				})
				local value = self:getImpactValue(impactStat, output)
				local delta = self:calculateImpactDelta(impactStat, replacementContext.baselineOutput, output)
				if not bestResult or delta > bestResult.delta then
					bestResult = {
						socket = socket,
						variant = variant,
						variantIdx = variantIndex,
						value = value,
						delta = delta,
						replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
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

function Class:computeIntuitiveLeapSocketImpact(sockets, impactStat, variant, methodId, planCache, progress, maxTotalPoints, occupiedMode, skipPlanSteps)
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local statField = impactStat.field
	local radiusLookup = { }
	for i, radius in ipairs(data.jewelRadius) do
		if radius.inner == 0 and not radiusLookup[radius.label] then
			radiusLookup[radius.label] = i
		end
	end

	local isMassiveRadius = variant and variant.isMassiveRadius
	local keystoneOnly = variant and variant.keystoneOnly or false
	local rawText = (variant and variant.rawText) or mustGetUniqueRawText("Intuitive Leap")

	local function collectMassiveNodes(socketNode)
		local nodes = { }
		if not socketNode or not socketNode.nodesInRadius then
			return nodes
		end
		for idx, radius in ipairs(data.jewelRadius) do
			if radius.outer <= 2400 and socketNode.nodesInRadius[idx] then
				for nodeId, node in pairs(socketNode.nodesInRadius[idx]) do
					nodes[nodeId] = node
				end
			end
		end
		return nodes
	end

	local candidateOptions = isMassiveRadius and {
		collectNodes = collectMassiveNodes,
		keystoneOnly = keystoneOnly,
	} or {
		radiusIndex = radiusLookup["Small"],
		keystoneOnly = false,
	}

	local variantKey = variant and variant.name or "normal"
	local results = { }
	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local accessCost = self:getSocketAccessCost(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or accessCost <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local slotName = replacementContext.slotName
			local item = new("Item", "Rarity: Unique\n" .. rawText)
			item:BuildModList()
			local candidates = self:collectConnectionlessCandidates(socketNode, candidateOptions)
			if #candidates > 0 then
				local maxAdditionalNodes = maxTotalPoints and math.max(maxTotalPoints - accessCost, 0) or nil
				local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
				local result
				if methodId == "fast" then
					local cacheKey = s_format("IL|%s|%s", statField, variantKey)
					planCache[cacheKey] = planCache[cacheKey] or { }
					result = self:computeConnectionlessFastPlan(calcFunc, replacementContext.baselineOutput, socketBaseline, socketNode, slotName, item, impactStat, candidates, nil, planCache[cacheKey], socket.label, socketProgress, maxAdditionalNodes, skipPlanSteps)
				else
					result = self:computeConnectionlessSimulatedPlan(calcFunc, replacementContext.baselineOutput, socketBaseline, socketNode, slotName, item, impactStat, candidates, nil, socket.label, socketProgress, maxAdditionalNodes)
				end
				result.socket = socket
				result.replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil
				t_insert(results, result)
			end
			progressTick(socketProgress, 1, 1, socket.label)
		end
	end

	t_sort(results, function(a, b) return a.delta > b.delta end)
	return results, realBaseline
end

function Class:computeThreadOfHopeSocketImpact(sockets, impactStat, threadVariants, methodId, planCache, progress, maxTotalPoints, occupiedMode, skipPlanSteps)
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local statField = impactStat.field
	local results = { }

	-- Pre-build items per ring variant (avoid re-creating inside the socket loop)
	local threadRawText = mustGetUniqueRawText("Thread of Hope")
	local threadItems = { }
	for variantIndex in ipairs(threadVariants) do
		local item = new("Item", "Rarity: Unique\n" .. threadRawText)
		item.variant = variantIndex
		item:BuildModList()
		threadItems[variantIndex] = item
	end

	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local accessCost = self:getSocketAccessCost(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or accessCost <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local slotName = replacementContext.slotName
			local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
			local bestResult
			for variantIndex, threadVariant in ipairs(threadVariants) do
				local variantProgress = progressChild(socketProgress, (variantIndex - 1) / #threadVariants, 1 / #threadVariants)
				local item = threadItems[variantIndex]
				local candidates = self:collectConnectionlessCandidates(socketNode, {
					radiusIndex = threadVariant.radiusIndex,
				})
				if #candidates > 0 then
					local maxAdditionalNodes = maxTotalPoints and math.max(maxTotalPoints - accessCost, 0) or nil
					local result
					if methodId == "fast" then
						local cacheKey = s_format("TOH|%s", statField)
						planCache[cacheKey] = planCache[cacheKey] or { }
						result = self:computeConnectionlessFastPlan(calcFunc, replacementContext.baselineOutput, socketBaseline, socketNode, slotName, item, impactStat, candidates, threadVariant.name .. " Ring", planCache[cacheKey], socket.label .. " | " .. threadVariant.name .. " Ring", variantProgress, maxAdditionalNodes, skipPlanSteps)
					else
						result = self:computeConnectionlessSimulatedPlan(calcFunc, replacementContext.baselineOutput, socketBaseline, socketNode, slotName, item, impactStat, candidates, threadVariant.name .. " Ring", socket.label .. " | " .. threadVariant.name .. " Ring", variantProgress, maxAdditionalNodes)
					end
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
				bestResult.replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil
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

function Class:computeSplitPersonalitySocketImpact(sockets, impactStat, variants, progress, maxTotalPoints, occupiedMode)
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local results = { }

	for socketIndex, socket in ipairs(sockets) do
		progressTick(progress, socketIndex - 1, #sockets, socket.label)
		local socketProgress = progressChild(progress, (socketIndex - 1) / #sockets, 1 / #sockets)
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local accessCost = self:getSocketAccessCost(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or accessCost <= maxTotalPoints) then
			local replacementContext = self:buildSocketReplacementContext(calcFunc, socket.id)
			local socketNode = replacementContext.socketNode
			local slotName = replacementContext.slotName
			local splitDistance = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
			local previousDistance = socketNode.distanceToClassStart

			socketNode.distanceToClassStart = splitDistance
			local baselineOutput = calcFunc({
				addNodes = { [socketNode] = true },
				repSlotName = slotName,
				repItem = replacementContext.baselineItem,
			})

			local bestResult
			for variantIdx, variant in ipairs(variants) do
				progressTick(socketProgress, variantIdx, #variants, socket.label .. " | " .. variant.name)
				local item = new("Item", "Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				local output = calcFunc({
					addNodes = { [socketNode] = true },
					repSlotName = slotName,
					repItem = item,
				})
				local value = self:getImpactValue(impactStat, output)
				local delta = self:calculateImpactDelta(impactStat, baselineOutput, output)
				if not bestResult or delta > bestResult.delta then
					bestResult = {
						socket = socket,
						variant = variant,
						variantIdx = variantIdx,
						value = value,
						delta = delta,
						replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
						baseOutput = extractTooltipStats(baselineOutput),
						compareOutput = extractTooltipStats(output),
						detailText = s_format("Dist %d | %s", splitDistance, variant.name),
					}
				end
			end

			socketNode.distanceToClassStart = previousDistance
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

function Class:computeImpossibleEscapeSocketImpact(sockets, impactStat, variants, methodId, planCache, progress, maxTotalPoints, occupiedMode, skipPlanSteps)
	impactStat = normalizeImpactStat(impactStat)
	local calcFunc, baseOutput = self.build.calcsTab:GetMiscCalculator()
	local realBaseline = self:getImpactValue(impactStat, baseOutput)
	local statField = impactStat.field
	local results = { }
	local smallRadiusIndex
	for i, radius in ipairs(data.jewelRadius) do
		if radius.label == "Small" and radius.inner == 0 then
			smallRadiusIndex = i
			break
		end
	end

	local variantContexts = { }
	for _, variant in ipairs(variants) do
		local keystoneNode = self.build.spec.tree.keystoneMap[variant.keystoneName]
		if keystoneNode and keystoneNode.nodesInRadius and keystoneNode.nodesInRadius[smallRadiusIndex] then
			local candidates = self:collectConnectionlessCandidates(nil, {
				collectNodes = function()
					return keystoneNode.nodesInRadius[smallRadiusIndex]
				end,
			})
			if #candidates > 0 then
				local item = new("Item", "Rarity: Unique\n" .. variant.rawText)
				item:BuildModList()
				variantContexts[variant.name] = {
					variant = variant,
					item = item,
					keystoneNode = keystoneNode,
					candidates = candidates,
				}
			end
		end
	end

	local groupedEntries = { }
	local groupedOrder = { }
	for _, socket in ipairs(sockets) do
		local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, occupiedMode)
		local accessCost = self:getSocketAccessCost(socket, occupancy)
		if socketAllowed and (not maxTotalPoints or accessCost <= maxTotalPoints) then
			local remainingBudget = maxTotalPoints and math.max(maxTotalPoints - accessCost, 0) or -1
			local groupKey = occupancy and occupancy.isOccupied and ("occupied:" .. socket.id) or ("free:" .. tostring(remainingBudget))
			if not groupedEntries[groupKey] then
				groupedEntries[groupKey] = {
					groupKey = groupKey,
					remainingBudget = remainingBudget,
					sockets = { },
					representativeSocket = socket,
					occupancy = occupancy,
				}
				t_insert(groupedOrder, groupedEntries[groupKey])
			end
			t_insert(groupedEntries[groupKey].sockets, socket)
		end
	end
	if #groupedOrder == 0 then
		return results, realBaseline
	end

	t_sort(groupedOrder, function(a, b)
		if a.remainingBudget ~= b.remainingBudget then
			return a.remainingBudget > b.remainingBudget
		end
		return a.representativeSocket.id < b.representativeSocket.id
	end)
	local bestResultByGroupKey = { }
	local totalPlanCount = #groupedOrder * #variants
	local currentPlanIndex = 0

	for _, groupEntry in ipairs(groupedOrder) do
		local representativeSocket = groupEntry.representativeSocket
		local replacementContext = self:buildSocketReplacementContext(calcFunc, representativeSocket.id)
		local representativeSocketNode = replacementContext.socketNode
		local representativeSlotName = replacementContext.slotName
		local socketBaseline = self:getImpactValue(impactStat, replacementContext.baselineOutput)
		local bestResult
		for _, variant in ipairs(variants) do
			currentPlanIndex = currentPlanIndex + 1
			local planProgress = progressChild(progress, (currentPlanIndex - 1) / totalPlanCount, 1 / totalPlanCount)
			local variantContext = variantContexts[variant.name]
			if variantContext then
				local maxAdditionalNodes = groupEntry.remainingBudget >= 0 and groupEntry.remainingBudget or nil
				local result
				if methodId == "fast" then
					local cacheKey = s_format("IE|%s|%s", statField, variant.name)
					planCache[cacheKey] = planCache[cacheKey] or { }
					result = self:computeConnectionlessFastPlan(
						calcFunc,
						replacementContext.baselineOutput,
						socketBaseline,
						representativeSocketNode,
						representativeSlotName,
						variantContext.item,
						impactStat,
						variantContext.candidates,
						variant.name,
						planCache[cacheKey],
						variant.name,
						planProgress,
						maxAdditionalNodes,
						skipPlanSteps
					)
				else
					result = self:computeConnectionlessSimulatedPlan(
						calcFunc,
						replacementContext.baselineOutput,
						socketBaseline,
						representativeSocketNode,
						representativeSlotName,
						variantContext.item,
						impactStat,
						variantContext.candidates,
						variant.name,
						variant.name,
						planProgress,
						maxAdditionalNodes
					)
				end
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
		bestResultByGroupKey[groupEntry.groupKey] = bestResult
	end

	for _, groupEntry in ipairs(groupedOrder) do
		local bestResult = bestResultByGroupKey[groupEntry.groupKey]
		if bestResult then
			for _, socket in ipairs(groupEntry.sockets) do
				local projectedResult = copyTableSafe(bestResult, false, true)
				projectedResult.socket = socket
				projectedResult.replacedItemLabel = groupEntry.occupancy and groupEntry.occupancy.isOccupied and groupEntry.occupancy.itemLabel or nil
				t_insert(results, projectedResult)
			end
		end
	end

	t_sort(results, function(a, b)
		if a.delta ~= b.delta then
			return a.delta > b.delta
		end
		return a.variant.name < b.variant.name
	end)
	return results, realBaseline
end

-- Return the helper function for use by the UI
return buildDisplayedConnectionlessPlans

end -- return function(Class, helpers)
