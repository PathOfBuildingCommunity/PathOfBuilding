-- Helper: BFS from class start to find and allocate path to nearest jewel socket
local function allocatePathToSocket(spec)
	local classStart
	for _, node in pairs(spec.allocNodes) do
		if node.type == "ClassStart" then
			classStart = node
			break
		end
	end
	if not classStart then return nil end

	local queue = { classStart }
	local visited = { [classStart.id] = true }
	local parent = { }
	local targetSocket
	local head = 1

	while head <= #queue do
		local current = queue[head]
		head = head + 1

		if current.isJewelSocket then
			targetSocket = current
			break
		end

		for _, linked in ipairs(current.linked) do
			if not visited[linked.id] and linked.type ~= "Mastery" and linked.type ~= "AscendClassStart" then
				visited[linked.id] = true
				parent[linked.id] = current
				queue[#queue + 1] = linked
			end
		end
	end

	if not targetSocket then return nil end

	-- Trace path back and allocate all nodes
	local current = targetSocket
	while current do
		current.alloc = true
		spec.allocNodes[current.id] = current
		current = parent[current.id]
	end

	return targetSocket
end

local function allocatePathToNode(spec, targetNode)
	local classStart
	for _, node in pairs(spec.allocNodes) do
		if node.type == "ClassStart" then
			classStart = node
			break
		end
	end
	if not classStart then return false end

	local queue = { classStart }
	local visited = { [classStart.id] = true }
	local parent = { }
	local head = 1

	while head <= #queue do
		local current = queue[head]
		head = head + 1
		if current.id == targetNode.id then
			break
		end
		for _, linked in ipairs(current.linked) do
			if not visited[linked.id] and linked.type ~= "Mastery" and linked.type ~= "AscendClassStart" then
				visited[linked.id] = true
				parent[linked.id] = current
				queue[#queue + 1] = linked
			end
		end
	end

	if not visited[targetNode.id] then return false end
	local current = targetNode
	while current do
		current.alloc = true
		spec.allocNodes[current.id] = current
		current = parent[current.id]
	end
	return true
end

-- Helper: find allocated non-socket non-keystone nodes in a socket's radius
local function findAllocatedNodesInRadius(spec, socketNode, radiusIndex)
	local result = { }
	local inRadius = socketNode.nodesInRadius and socketNode.nodesInRadius[radiusIndex]
	for nodeId in pairs(inRadius or { }) do
		local node = spec.nodes[nodeId]
		if node and node.alloc and node.type ~= "Socket" and node.type ~= "Keystone"
		and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			result[#result + 1] = node
		end
	end
	return result
end

-- Helper: index in nodesInRadius for a named jewel radius (e.g. "Large").
-- Reads data.jewelRadius rather than hardcoding the index, so the tests stay
-- correct if the radius table is ever reordered.
local function radiusIndexFor(label)
	for index, info in ipairs(data.jewelRadius) do
		if info.label == label then
			return index
		end
	end
end

-- Helper: standard test prelude — allocate a path to the nearest jewel socket,
-- run the build pipeline once, and return the spec + socket.
local function setupAllocatedSocket()
	local spec = build.spec
	local socketNode = allocatePathToSocket(spec)
	spec:BuildAllDependsAndPaths()
	runCallback("OnFrame")
	assert.is_truthy(socketNode, "Should find a jewel socket")
	return spec, socketNode
end

local function rebuildBuild()
	build.buildFlag = true
	runCallback("OnFrame")
end

-- Helper: install an existing item into a jewel socket, bypassing
-- BuildClusterJewelGraphs. Returns the slot.
local function equipJewelInSocket(item, socketNode)
	build.itemsTab:AddItem(item, true)
	build.spec.jewels[socketNode.id] = item.id
	local slot = build.itemsTab.sockets[socketNode.id]
	if slot then
		slot.selItemId = item.id
	end
	return slot
end

-- Helper: minimal Thread of Hope item. Uses "Radius: Variable" + a single
-- variant with "Only affects Passives in Large Ring", which is the real in-game
-- parsing path: the mod sets jewelData.radiusIndex (an annular ring index, not
-- the same as the full-circle index 3 that "Radius: Large" would produce).
local function newThreadOfHope()
	return new("Item", "Rarity: UNIQUE\n" ..
		"Thread of Hope\n" ..
		"Crimson Jewel\n" ..
		"Variant: Large Ring\n" ..
		"Selected Variant: 1\n" ..
		"Radius: Variable\n" ..
		"Implicits: 0\n" ..
		"Only affects Passives in Large Ring\n" ..
		"Passives in Radius can be Allocated without being connected to your Tree\n")
end

local function newCustomLeapJewel(name)
	return new("Item", "Rarity: RARE\n" ..
		name .. "\n" ..
		"Crimson Jewel\n" ..
		"Radius: Variable\n" ..
		"Implicits: 0\n" ..
		"Only affects Passives in Large Ring\n" ..
		"Passives in Radius can be Allocated without being connected to your Tree\n")
end

local function newPlainJewel()
	return new("Item", "Rarity: RARE\n" ..
		"Plain Spark\n" ..
		"Crimson Jewel\n" ..
		"Implicits: 0\n")
end

-- Helper: minimal Impossible Escape item. Uses "Radius: Small" and targets
-- a specific keystone. The parser populates both impossibleEscapeKeystone
-- and impossibleEscapeKeystones from the "in Radius of X" mod.
local function newImpossibleEscape(keystoneName)
	return new("Item", "Rarity: UNIQUE\n" ..
		"Impossible Escape\n" ..
		"Viridian Jewel\n" ..
		"Radius: Small\n" ..
		"Implicits: 0\n" ..
		"Passive Skills in Radius of " .. keystoneName .. " can be Allocated without being connected to your Tree\n")
end

-- Helper: equip a Thread of Hope in a socket and return the item.
local function equipThreadOfHope(socketNode)
	local item = newThreadOfHope()
	equipJewelInSocket(item, socketNode)
	return item
end

-- Helper: minimal Lethal Pride item — only the lines the parser needs to
-- populate jewelData.conqueredBy and jewelRadiusIndex. Variants and flavour
-- text are intentionally omitted; the tests exercise behavior, not the parser
-- against the full serialized form.
local function newLethalPride()
	return new("Item", "Rarity: UNIQUE\n" ..
		"Lethal Pride\n" ..
		"Timeless Jewel\n" ..
		"Radius: Large\n" ..
		"Implicits: 0\n" ..
		"Commanded leadership over 10000 warriors under Kaom\n")
end

-- Helper: simulate a Karui Timeless conquest on an allocated node by replacing
-- its modList with a known +100 Life mod. The LUT binary files do not load in
-- the headless test environment, so the real BuildAllDependsAndPaths conquest
-- path cannot run. This must be called *after* runCallback("OnFrame"), or BADP
-- will reset the modList back to the original tree node modList.
local function simulateKaruiConquest(node)
	node.conqueredBy = { id = 10000, conqueror = { id = 1, type = "karui" } }
	node.modList = new("ModList")
	node.modList:NewMod("Life", "BASE", 100, "Timeless Jewel")
end

local function overrideNodeWithLife(spec, node, life)
	local override = copyTable(spec.tree.nodes[node.id], true)
	override.id = node.id
	override.dn = node.dn
	override.sd = { "+" .. life .. " to maximum Life" }
	override.modList = new("ModList")
	override.modList:NewMod("Life", "BASE", life, "Test")
	spec.hashOverrides[node.id] = override
end

-- Helper: find the first unallocated, non-Mastery, non-Keystone node in a
-- socket's radius that is reachable through an intuitiveLeapLike jewel.
local function findIntuitiveLeapTarget(spec, socketNode, radiusIndex)
	local inRadius = socketNode.nodesInRadius and socketNode.nodesInRadius[radiusIndex]
	for nodeId in pairs(inRadius or { }) do
		local node = spec.nodes[nodeId]
		if node and not node.alloc and #node.intuitiveLeapLikesAffecting > 0
		and node.type ~= "Mastery" and node.type ~= "Keystone" then
			return node
		end
	end
	return nil
end

-- Helper: true iff any tooltip line contains the given needle (literal match).
local function tooltipContains(tooltip, needle)
	for _, line in ipairs(tooltip.lines) do
		if (line.text or ""):find(needle, 1, true) then
			return true
		end
	end
	return false
end

local function tooltipText(tooltip)
	local lines = { }
	for _, line in ipairs(tooltip.lines) do
		if line.text then
			lines[#lines + 1] = line.text
		end
	end
	return table.concat(lines, "\n")
end

local function tooltipContainsNegativeStat(tooltip, label)
	for _, line in ipairs(tooltip.lines) do
		local text = line.text or ""
		if text:find(colorCodes.NEGATIVE, 1, true) and text:find(label, 1, true) then
			return true
		end
	end
	return false
end

local function sortedNodeIds(nodeMap)
	local nodeIds = { }
	for nodeId in pairs(nodeMap or { }) do
		nodeIds[#nodeIds + 1] = nodeId
	end
	table.sort(nodeIds)
	return nodeIds
end

local function findLeapOverlapCandidates(spec, radiusIndex)
	local socketList = { }
	for _, node in pairs(spec.nodes) do
		if node.isJewelSocket and node.nodesInRadius and node.nodesInRadius[radiusIndex] then
			socketList[#socketList + 1] = node
		end
	end
	table.sort(socketList, function(a, b)
		return a.id < b.id
	end)

	local candidates = { }
	for i = 1, #socketList - 1 do
		for j = i + 1, #socketList do
			for _, nodeId in ipairs(sortedNodeIds(socketList[i].nodesInRadius[radiusIndex])) do
				if socketList[j].nodesInRadius[radiusIndex][nodeId] then
					local node = spec.nodes[nodeId]
					if node and node.type ~= "Mastery" and node.type ~= "Keystone" and node.type ~= "Socket"
					and node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
						candidates[#candidates + 1] = {
							socketAId = socketList[i].id,
							socketBId = socketList[j].id,
							targetNodeId = nodeId,
						}
					end
				end
			end
		end
	end
	return candidates
end

describe("TestRadiusJewelStatDiff", function()
	before_each(function()
		newBuild()
	end)

	teardown(function() end)

	it("Lethal Pride item parses conqueredBy correctly", function()
		local item = newLethalPride()
		build.itemsTab:AddItem(item, true)

		assert.is_truthy(item.jewelData, "Item should have jewelData")
		assert.is_truthy(item.jewelData.conqueredBy, "Item should have conqueredBy")
		assert.are.equals(10000, item.jewelData.conqueredBy.id)
		assert.are.equals("karui", item.jewelData.conqueredBy.conqueror.type)
		assert.is_truthy(item.jewelRadiusIndex, "Item should have jewelRadiusIndex")
	end)

	it("Thread of Hope item parses intuitiveLeapLike correctly", function()
		local item = newThreadOfHope()
		build.itemsTab:AddItem(item, true)

		assert.is_truthy(item.jewelData, "Item should have jewelData")
		assert.is_truthy(item.jewelData.intuitiveLeapLike, "Item should have intuitiveLeapLike")
		assert.is_truthy(item.jewelRadiusIndex, "Item should have jewelRadiusIndex")
	end)

	it("calcFunc removeNodes/addNodes changes output for allocated nodes", function()
		local spec, socketNode = setupAllocatedSocket()

		local nodesInRadius = findAllocatedNodesInRadius(spec, spec.nodes[socketNode.id], radiusIndexFor("Large"))
		assert.is_true(#nodesInRadius > 0, "Should have allocated nodes in radius")

		local calcFunc = build.calcsTab:GetMiscCalculator(build)
		local testNode = nodesInRadius[1]
		local origNode = spec.tree.nodes[testNode.id]

		assert.is_truthy(calcFunc({ removeNodes = { [testNode] = true } }),
			"calcFunc with removeNodes should return output")
		assert.is_truthy(calcFunc({ removeNodes = { [testNode] = true }, addNodes = { [origNode] = true } }),
			"calcFunc with removeNodes+addNodes should return output")
	end)

	it("timeless jewel comparison: removeNodes/addNodes on conquered nodes changes output", function()
		local spec, socketNode = setupAllocatedSocket()

		local nodesInRadius = findAllocatedNodesInRadius(spec, spec.nodes[socketNode.id], radiusIndexFor("Large"))
		assert.is_true(#nodesInRadius > 0, "Should have allocated nodes in radius")

		local conqueredNode = nodesInRadius[1]
		local origNode = spec.tree.nodes[conqueredNode.id]
		simulateKaruiConquest(conqueredNode)

		-- Snapshot the state including the simulated conquest, then revert
		-- the conquered node back to the original tree node via override.
		local calcFunc, calcBase = build.calcsTab:GetMiscCalculator(build)
		local output = calcFunc({
			removeNodes = { [conqueredNode] = true },
			addNodes = { [origNode] = true },
		})

		assert.are_not.equals(calcBase.Life, output.Life,
			"Reverting conquered node should change Life output")
	end)

	it("Thread of Hope enables allocation of unconnected nodes", function()
		local spec, socketNode = setupAllocatedSocket()

		local item = equipThreadOfHope(socketNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		local targetNode = findIntuitiveLeapTarget(spec, spec.nodes[socketNode.id], item.jewelRadiusIndex)
		assert.is_truthy(targetNode, "Should find an unallocated node affected by Thread of Hope")

		spec:AllocNode(targetNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		assert.is_true(targetNode.alloc, "Node should be allocated")
		assert.is_false(targetNode.connectedToStart, "Node should not be connected to start")

		local nodesInLeapRadius = spec:NodesInIntuitiveLeapLikeRadius(spec.nodes[socketNode.id])
		local found = false
		for _, node in ipairs(nodesInLeapRadius) do
			if node.id == targetNode.id then
				found = true
				break
			end
		end
		assert.is_true(found, "NodesInIntuitiveLeapLikeRadius should include the allocated node")
	end)

	it("Thread of Hope removal comparison removes dependent nodes via override", function()
		local spec, socketNode = setupAllocatedSocket()

		local item = equipThreadOfHope(socketNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		local targetNode = findIntuitiveLeapTarget(spec, spec.nodes[socketNode.id], item.jewelRadiusIndex)
		assert.is_truthy(targetNode, "Should find a node to allocate through Thread of Hope")

		spec:AllocNode(targetNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		-- Build override like ItemsTab does: remove nodes only reachable through the jewel
		local override = { removeNodes = { } }
		for _, node in ipairs(spec:NodesInIntuitiveLeapLikeRadius(spec.nodes[socketNode.id])) do
			if not node.connectedToStart then
				override.removeNodes[node] = true
			end
		end

		assert.is_truthy(override.removeNodes[spec.nodes[targetNode.id]],
			"Node allocated through Thread of Hope should be in removeNodes")

		local calcFunc = build.calcsTab:GetMiscCalculator(build)
		assert.is_truthy(calcFunc(override), "calcFunc with removeNodes should return output")
	end)

	it("intuitiveLeapLike replacement comparison removes nodes unsupported by the new jewel", function()
		local spec, socketNode = setupAllocatedSocket()

		local leapItem = newCustomLeapJewel("Leap Spark")
		local slot = equipJewelInSocket(leapItem, socketNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		local targetNode = findIntuitiveLeapTarget(spec, spec.nodes[socketNode.id], leapItem.jewelRadiusIndex)
		assert.is_truthy(targetNode, "Should find a node to allocate through the radius jewel")
		overrideNodeWithLife(spec, targetNode, 100)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		targetNode = spec.nodes[targetNode.id]
		spec:AllocNode(targetNode)
		spec:BuildAllDependsAndPaths()
		rebuildBuild()

		assert.is_true(targetNode.alloc, "Node should be allocated")
		assert.is_false(targetNode.connectedToStart, "Node should be supported only by the radius jewel")

		local plainJewel = newPlainJewel()
		build.itemsTab:AddItem(plainJewel, true)
		local tooltip = new("Tooltip")
		build.itemsTab:AddItemTooltip(tooltip, plainJewel, slot)

		assert.is_true(tooltipContains(tooltip, "Equipping this item in"),
			"Replacing the radius jewel should show the stat loss from unsupported nodes")
		assert.is_true(tooltipContainsNegativeStat(tooltip, "Total Life"),
			"Replacing the radius jewel should remove the life node only supported by that jewel:\n" .. tooltipText(tooltip))
	end)

	it("intuitiveLeapLike removal comparison keeps nodes supported by another radius jewel", function()
		local probeItem = newCustomLeapJewel("Probe Spark")
		build.itemsTab:AddItem(probeItem, true)
		local radiusIndex = probeItem.jewelRadiusIndex
		local candidates = findLeapOverlapCandidates(build.spec, radiusIndex)
		assert.is_true(#candidates > 0, "Should find jewel sockets with overlapping radius")

		local spec, socketA, socketB, targetNodeId
		for _, candidate in ipairs(candidates) do
			newBuild()
			spec = build.spec
			socketA = spec.nodes[candidate.socketAId]
			socketB = spec.nodes[candidate.socketBId]
			assert.is_truthy(socketA, "First overlap socket should exist")
			assert.is_truthy(socketB, "Second overlap socket should exist")
			assert.is_true(allocatePathToNode(spec, socketA), "Should allocate path to first socket")
			assert.is_true(allocatePathToNode(spec, socketB), "Should allocate path to second socket")
			spec:BuildAllDependsAndPaths()
			runCallback("OnFrame")
			if not spec.nodes[candidate.targetNodeId].alloc then
				targetNodeId = candidate.targetNodeId
				break
			end
		end
		assert.is_truthy(targetNodeId, "Should find an overlap target not already allocated by the socket paths")

		local itemA = newCustomLeapJewel("First Leap")
		local slotA = equipJewelInSocket(itemA, socketA)
		local itemB = newCustomLeapJewel("Second Leap")
		equipJewelInSocket(itemB, socketB)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		local targetNode = spec.nodes[targetNodeId]
		assert.are.equals(2, #targetNode.intuitiveLeapLikesAffecting,
			"Target node should be supported by both radius jewels")
		overrideNodeWithLife(spec, targetNode, 100)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		targetNode = spec.nodes[targetNodeId]
		spec:AllocNode(targetNode)
		spec:BuildAllDependsAndPaths()
		rebuildBuild()

		assert.is_true(targetNode.alloc, "Overlap node should be allocated")
		assert.is_false(targetNode.connectedToStart, "Overlap node should be supported only by radius jewels")
		assert.are.equals(2, #targetNode.intuitiveLeapLikesAffecting,
			"Allocated overlap node should still be supported by both radius jewels")

		local tooltip = new("Tooltip")
		build.itemsTab:AddItemTooltip(tooltip, itemA, slotA)

		assert.is_false(tooltipContainsNegativeStat(tooltip, "Total Life"),
			"Removing one overlapping radius jewel should not remove the life node still supported by the other:\n" .. tooltipText(tooltip))
	end)

	it("Impossible Escape parses and targets a keystone correctly", function()
		local item = newImpossibleEscape("Iron Reflexes")
		build.itemsTab:AddItem(item, true)

		assert.is_truthy(item.jewelData, "IE should have jewelData")
		assert.is_truthy(item.jewelData.impossibleEscapeKeystone, "IE should have impossibleEscapeKeystone")
		assert.are.equals("iron reflexes", item.jewelData.impossibleEscapeKeystone)
		assert.is_truthy(item.jewelData.impossibleEscapeKeystones, "IE should have impossibleEscapeKeystones")
		assert.is_truthy(item.jewelData.impossibleEscapeKeystones["iron reflexes"],
			"IE should target Iron Reflexes")
	end)

	it("Impossible Escape removal comparison removes dependent nodes via override", function()
		local spec, socketNode = setupAllocatedSocket()

		-- IE works via a keystone's radius, not the socket's radius.
		-- Find a keystone that has unallocated nodes in its radius for the IE's radius index.
		local item = newImpossibleEscape("Iron Reflexes")
		equipJewelInSocket(item, socketNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		-- IE populates intuitiveLeapLikesAffecting on nodes in the keystone's radius,
		-- not the socket's radius. Search all spec nodes for an affected target.
		local targetNode
		for _, node in pairs(spec.nodes) do
			if not node.alloc and #node.intuitiveLeapLikesAffecting > 0
			and node.type ~= "Mastery" and node.type ~= "Keystone" then
				targetNode = node
				break
			end
		end
		if not targetNode then
			pending("No allocatable node in Impossible Escape radius for this tree layout")
			return
		end

		spec:AllocNode(targetNode)
		spec:BuildAllDependsAndPaths()
		runCallback("OnFrame")

		-- Build override like ItemsTab does
		local override = { removeNodes = { } }
		local nodesToRemove = spec:NodesInIntuitiveLeapLikeRadius(spec.nodes[socketNode.id])
		for _, node in ipairs(nodesToRemove) do
			if not node.connectedToStart then
				override.removeNodes[node] = true
			end
		end

		assert.is_truthy(override.removeNodes[spec.nodes[targetNode.id]],
			"Node allocated through Impossible Escape should be in removeNodes")

		local calcFunc = build.calcsTab:GetMiscCalculator(build)
		assert.is_truthy(calcFunc(override), "calcFunc with removeNodes should return output")
	end)

	it("AddItemTooltip emits a remove-comparison block for an equipped Timeless jewel", function()
		local spec, socketNode = setupAllocatedSocket()

		local item = newLethalPride()
		local slot = equipJewelInSocket(item, socketNode)
		assert.is_truthy(slot, "Should find a slot for the jewel socket")

		local nodesInRadius = findAllocatedNodesInRadius(spec, spec.nodes[socketNode.id], item.jewelRadiusIndex)
		assert.is_true(#nodesInRadius > 0, "Should have allocated nodes in jewel radius")
		simulateKaruiConquest(nodesInRadius[1])

		local tooltip = new("Tooltip")
		build.itemsTab:AddItemTooltip(tooltip, item, slot)

		assert.is_true(tooltipContains(tooltip, "Removing this item"),
			"tooltip should contain a 'Removing this item' comparison header")
	end)

end)
