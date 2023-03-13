-- Path of Building
--
-- Class: Passive Spec
-- Passive tree spec class.
-- Manages node allocation and pathing for a given passive spec
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local b_lshift = bit.lshift

local PassiveSpecClass = newClass("PassiveSpec", "UndoHandler", function(self, build, treeVersion)
	self.UndoHandler()

	self.build = build

	-- Initialise and build all tables
	self:Init(treeVersion)

	self:SelectClass(0)
end)

function PassiveSpecClass:Init(treeVersion)
	self.treeVersion = treeVersion
	self.tree = main:LoadTree(treeVersion)

	-- Make a local copy of the passive tree that we can modify
	self.nodes = { }
	for _, treeNode in pairs(self.tree.nodes) do
		-- Exclude proxy or groupless nodes, as well as expansion sockets
		if treeNode.group and not treeNode.isProxy and not treeNode.group.isProxy and (not treeNode.expansionJewel or not treeNode.expansionJewel.parent) then 
			self.nodes[treeNode.id] = setmetatable({ 
				linked = { },
				power = { }
			}, treeNode)
		end
	end
	for id, node in pairs(self.nodes) do
		for _, otherId in ipairs(node.linkedId) do
			t_insert(node.linked, self.nodes[otherId])
		end
	end

	-- List of currently allocated nodes
	-- Keys are node IDs, values are nodes
	self.allocNodes = { }

	-- List of nodes allocated in subgraphs; used to maintain allocation when loading, and when rebuilding subgraphs
	self.allocSubgraphNodes = { }

	-- List of cluster nodes to allocate
	self.allocExtendedNodes = { }

	-- Table of jewels equipped in this tree
	-- Keys are node IDs, values are items
	self.jewels = { }

	-- Tree graphs dynamically generated from cluster jewels
	-- Keys are subgraph IDs, values are graphs
	self.subGraphs = { }

	-- Keys are mastery node IDs, values are mastery effect IDs
	self.masterySelections = { }
end

function PassiveSpecClass:Load(xml, dbFileName)
	self.title = xml.attrib.title
	local url
	for _, node in pairs(xml) do
		if type(node) == "table" then
			if node.elem == "URL" then
				-- Legacy format
				if type(node[1]) ~= "string" then
					launch:ShowErrMsg("^1Error parsing '%s': 'URL' element missing content", dbFileName)
					return true
				end
				url = node[1]
			elseif node.elem == "Sockets" then
				for _, child in ipairs(node) do
					if child.elem == "Socket" then
						if not child.attrib.nodeId then
							launch:ShowErrMsg("^1Error parsing '%s': 'Socket' element missing 'nodeId' attribute", dbFileName)
							return true
						end
						if not child.attrib.itemId then
							launch:ShowErrMsg("^1Error parsing '%s': 'Socket' element missing 'itemId' attribute", dbFileName)
							return true
						end
						-- there are files which have been saved poorly and have empty jewel sockets saved as sockets with itemId zero.
						-- this check filters them out to prevent dozens of invalid jewels
						jewelIdNum = tonumber(child.attrib.itemId)
						if jewelIdNum > 0 then
							self.jewels[tonumber(child.attrib.nodeId)] = jewelIdNum
						end
					end
				end
			end
		end
	end
	if xml.attrib.nodes then
		-- New format
		if not xml.attrib.classId then
			launch:ShowErrMsg("^1Error parsing '%s': 'Spec' element missing 'classId' attribute", dbFileName)
			return true
		end
		if not xml.attrib.ascendClassId then
			launch:ShowErrMsg("^1Error parsing '%s': 'Spec' element missing 'ascendClassId' attribute", dbFileName)
			return true
		end
		local hashList = { }
		for hash in xml.attrib.nodes:gmatch("%d+") do
			t_insert(hashList, tonumber(hash))
		end
		local masteryEffects = { }
		if xml.attrib.masteryEffects then
			for mastery, effect in xml.attrib.masteryEffects:gmatch("{(%d+),(%d+)}") do
				masteryEffects[tonumber(mastery)] = tonumber(effect)
			end
		end
		self:ImportFromNodeList(tonumber(xml.attrib.classId), tonumber(xml.attrib.ascendClassId), hashList, masteryEffects)
	elseif url then
		self:DecodeURL(url)
	end
	self:ResetUndo()
end

function PassiveSpecClass:Save(xml)
	local allocNodeIdList = { }
	for nodeId in pairs(self.allocNodes) do
		t_insert(allocNodeIdList, nodeId)
	end
	local masterySelections = { }
	for mastery, effect in pairs(self.masterySelections) do
		t_insert(masterySelections, "{"..mastery..","..effect.."}")
	end
	xml.attrib = { 
		title = self.title,
		treeVersion = self.treeVersion,
		-- New format
		classId = tostring(self.curClassId), 
		ascendClassId = tostring(self.curAscendClassId), 
		nodes = table.concat(allocNodeIdList, ","),
		masteryEffects = table.concat(masterySelections, ",")
	}
	t_insert(xml, {
		-- Legacy format
		elem = "URL", 
		[1] = self:EncodeURL("https://www.pathofexile.com/passive-skill-tree/")
	})

	local sockets = {
		elem = "Sockets"
	}
	for nodeId, itemId in pairs(self.jewels) do
		-- jewel socket contents should not be saved unless they contain a valid jewel
		if itemId > 0 then
			local socket = { elem = "Socket", attrib = { nodeId = tostring(nodeId), itemId = tostring(itemId) }}
			t_insert( sockets, socket )
		end
	end
	t_insert(xml, sockets)

end

function PassiveSpecClass:PostLoad()
	self:BuildClusterJewelGraphs()
end

-- Import passive spec from the provided class IDs and node hash list
function PassiveSpecClass:ImportFromNodeList(classId, ascendClassId, hashList, masteryEffects, treeVersion)
	if treeVersion and treeVersion ~= self.treeVersion then
		self:Init(treeVersion)
		self.build.treeTab.showConvert = self.treeVersion ~= latestTreeVersion
	end
	self:ResetNodes()
	self:SelectClass(classId)
	for _, id in pairs(hashList) do
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
		else
			t_insert(self.allocSubgraphNodes, id)
		end
	end
	for _, id in pairs(self.allocExtendedNodes) do
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
		end
	end
	wipeTable(self.masterySelections)
	for mastery, effect in pairs(masteryEffects) do
		-- ignore ggg codes from profile import
		if (tonumber(effect) < 65536) then
			self.masterySelections[mastery] = effect
		end
	end
	self:SelectAscendClass(ascendClassId)
end

function PassiveSpecClass:AllocateDecodedNodes(nodes, isCluster)
	for i = 1, #nodes - 1, 2 do
		local id = nodes:byte(i) * 256 + nodes:byte(i + 1)
		if isCluster then
			id = id + 65536
		end
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
		end
	end
end

function PassiveSpecClass:AllocateMasteryEffects(masteryEffects)
	for i = 1, #masteryEffects - 1, 4 do
		local effectId = masteryEffects:byte(i) * 256 + masteryEffects:byte(i + 1)
		local id  = masteryEffects:byte(i + 2) * 256 + masteryEffects:byte(i + 3)

		local effect = self.tree.masteryEffects[effectId]
		self.allocNodes[id].sd = effect.sd
		self.allocNodes[id].allMasteryOptions = false
		self.allocNodes[id].reminderText = { "Tip: Right click to select a different effect" }
		self.tree:ProcessStats(self.allocNodes[id])
		self.masterySelections[id] = effectId
		self.allocatedMasteryCount = self.allocatedMasteryCount + 1
		if not self.allocatedMasteryTypes[self.allocNodes[id].name] then
			self.allocatedMasteryTypes[self.allocNodes[id].name] = 1
			self.allocatedMasteryTypeCount = self.allocatedMasteryTypeCount + 1
		else
			local prevCount = self.allocatedMasteryTypes[self.allocNodes[id].name]
			self.allocatedMasteryTypes[self.allocNodes[id].name] = prevCount + 1
			if prevCount == 0 then
				self.allocatedMasteryTypeCount = self.allocatedMasteryTypeCount + 1
			end
		end
	end
end

-- Decode the given passive tree URL
function PassiveSpecClass:DecodeURL(url)
	local b = common.base64.decode(url:gsub("^.+/",""):gsub("-","+"):gsub("_","/"))
	if not b or #b < 6 then
		return "Invalid tree link (unrecognised format)"
	end
	local ver = b:byte(1) * 16777216 + b:byte(2) * 65536 + b:byte(3) * 256 + b:byte(4)
	if ver > 6 then
		return "Invalid tree link (unknown version number '"..ver.."')"
	end
	local classId = b:byte(5)	
	local ascendClassId = (ver >= 4) and b:byte(6) or 0
	if not self.tree.classes[classId] then
		return "Invalid tree link (bad class ID '"..classId.."')"
	end
	self:ResetNodes()
	self:SelectClass(classId)
	self:SelectAscendClass(ascendClassId)
	
	local nodesStart = ver >= 4 and 8 or 7
	local nodesEnd = ver >= 5 and 7 + (b:byte(7) * 2) or -1
	local nodes = b:sub(nodesStart, nodesEnd)
	
	self:AllocateDecodedNodes(nodes, false)

	if ver < 5 then
		return
	end

	local clusterStart = nodesEnd + 1
	local clusterEnd = clusterStart + (b:byte(clusterStart) * 2)
	local clusterNodes = b:sub(clusterStart + 1, clusterEnd)
	
	self:AllocateDecodedNodes(clusterNodes, true)
	
	if ver < 6 then
		return
	end
	
	local masteryStart = clusterEnd + 1
	local masteryEnd = masteryStart + (b:byte(masteryStart) * 4)
	local masteryEffects = b:sub(masteryStart + 1, masteryEnd)
	self:AllocateMasteryEffects(masteryEffects)
end

-- Encodes the current spec into a URL, using the official skill tree's format
-- Prepends the URL with an optional prefix
function PassiveSpecClass:EncodeURL(prefix)
	local a = { 0, 0, 0, 6, self.curClassId, self.curAscendClassId }
	
	local nodeCount = 0
	local clusterCount = 0
	local masteryCount = 0

	local clusterNodeIds = {}
	local masteryNodeIds = {}

	for id, node in pairs(self.allocNodes) do
		if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" and id < 65536 then
			t_insert(a, m_floor(id / 256))
			t_insert(a, id % 256)
			nodeCount = nodeCount + 1
			if self.masterySelections[node.id] then
				local effect_id = self.masterySelections[node.id]
				t_insert(masteryNodeIds, m_floor(effect_id / 256))
				t_insert(masteryNodeIds, effect_id % 256)
				t_insert(masteryNodeIds, m_floor(node.id / 256))
				t_insert(masteryNodeIds, node.id % 256)
				masteryCount = masteryCount + 1
			end
		elseif id >= 65536 then
			local clusterId = id - 65536
			t_insert(clusterNodeIds, m_floor(clusterId / 256))
			t_insert(clusterNodeIds, clusterId % 256)
			clusterCount = clusterCount + 1
		end
	end
	t_insert(a, 7, nodeCount)

	t_insert(a, clusterCount)
	for _, id in pairs(clusterNodeIds) do
		t_insert(a, id)
	end
	
	t_insert(a, masteryCount)
	for _, id in pairs(masteryNodeIds) do
		t_insert(a, id)
	end
	
	return (prefix or "")..common.base64.encode(string.char(unpack(a))):gsub("+","-"):gsub("/","_")
end

-- Change the current class, preserving currently allocated nodes if they connect to the new class's starting node
function PassiveSpecClass:SelectClass(classId)
	if self.curClassId then
		-- Deallocate the current class's starting node
		local oldStartNodeId = self.curClass.startNodeId
		self.nodes[oldStartNodeId].alloc = false
		self.allocNodes[oldStartNodeId] = nil
	end

	self.curClassId = classId
	local class = self.tree.classes[classId]
	self.curClass = class 
	self.curClassName = class.name

	-- Allocate the new class's starting node
	local startNode = self.nodes[class.startNodeId]
	startNode.alloc = true
	self.allocNodes[startNode.id] = startNode

	-- Reset the ascendancy class
	-- This will also rebuild the node paths and dependencies
	self:SelectAscendClass(0)
end

function PassiveSpecClass:SelectAscendClass(ascendClassId)
	self.curAscendClassId = ascendClassId
	local ascendClass = self.curClass.classes[ascendClassId] or self.curClass.classes[0]
	self.curAscendClass = ascendClass
	self.curAscendClassName = ascendClass.name

	-- Deallocate any allocated ascendancy nodes that don't belong to the new ascendancy class
	for id, node in pairs(self.allocNodes) do
		if node.ascendancyName and node.ascendancyName ~= ascendClass.name then
			node.alloc = false
			self.allocNodes[id] = nil
		end
	end

	if ascendClass.startNodeId then
		-- Allocate the new ascendancy class's start node
		local startNode = self.nodes[ascendClass.startNodeId]
		startNode.alloc = true
		self.allocNodes[startNode.id] = startNode
	end

	-- Rebuild all the node paths and dependencies
	self:BuildAllDependsAndPaths()
end

-- Determines if the given class's start node is connected to the current class's start node
-- Attempts to find a path between the nodes which doesn't pass through any ascendancy nodes (i.e. Ascendant) 
function PassiveSpecClass:IsClassConnected(classId)
	for _, other in ipairs(self.nodes[self.tree.classes[classId].startNodeId].linked) do
		-- For each of the nodes to which the given class's start node connects...
		if other.alloc then
			-- If the node is allocated, try to find a path back to the current class's starting node
			other.visited = true
			local visited = { }
			local found = self:FindStartFromNode(other, visited, true)
			for i, n in ipairs(visited) do
				n.visited = false
			end
			other.visited = false
			if found then
				-- Found a path, so the given class's start node is definitely connected to the current class's start node
				-- There might still be nodes which are connected to the current tree by an entirely different path though
				-- E.g. via Ascendant or by connecting to another "first passive node"
				return true
			end
		end
	end
	return false
end

-- Clear the allocated status of all non-class-start nodes
function PassiveSpecClass:ResetNodes()
	for id, node in pairs(self.nodes) do
		if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			node.alloc = false
			self.allocNodes[id] = nil
		end
	end
	wipeTable(self.masterySelections)
end

-- Allocate the given node, if possible, and all nodes along the path to the node
-- An alternate path to the node may be provided, otherwise the default path will be used
-- The path must always contain the given node, as will be the case for the default path
function PassiveSpecClass:AllocNode(node, altPath)
	if not node.path then
		-- Node cannot be connected to the tree as there is no possible path
		return
	end

	-- Allocate all nodes along the path
	if node.dependsOnIntuitiveLeapLike then
		node.alloc = true
		self.allocNodes[node.id] = node
	else
		for _, pathNode in ipairs(altPath or node.path) do
			pathNode.alloc = true
			self.allocNodes[pathNode.id] = pathNode
		end
	end

	if node.isMultipleChoiceOption then
		-- For multiple choice passives, make sure no other choices are allocated
		local parent = node.linked[1]
		for _, optNode in ipairs(parent.linked) do
			if optNode.isMultipleChoiceOption and optNode.alloc and optNode ~= node then
				optNode.alloc = false
				self.allocNodes[optNode.id] = nil
			end
		end
	end

	-- Rebuild all dependencies and paths for all allocated nodes
	self:BuildAllDependsAndPaths()
end

function PassiveSpecClass:DeallocSingleNode(node)
	node.alloc = false
	self.allocNodes[node.id] = nil
	if node.type == "Mastery" then
		self:AddMasteryEffectOptionsToNode(node)
		self.masterySelections[node.id] = nil
	end
end

-- Deallocate the given node, and all nodes which depend on it (i.e. which are only connected to the tree through this node)
function PassiveSpecClass:DeallocNode(node)
	for _, depNode in ipairs(node.depends) do
		self:DeallocSingleNode(depNode)
	end

	-- Rebuild all paths and dependencies for all allocated nodes
	self:BuildAllDependsAndPaths()
end

-- Count the number of allocated nodes and allocated ascendancy nodes
function PassiveSpecClass:CountAllocNodes()
	local used, ascUsed, sockets = 0, 0, 0
	for _, node in pairs(self.allocNodes) do
		if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" then
			if node.ascendancyName then
				if not node.isMultipleChoiceOption then
					ascUsed = ascUsed + 1
				end
			else
				used = used + 1
			end
			if node.type == "Socket" then
				sockets = sockets + 1
			end
		end
	end
	return used, ascUsed, sockets
end

-- Attempt to find a class start node starting from the given node
-- Unless noAscent == true it will also look for an ascendancy class start node 
function PassiveSpecClass:FindStartFromNode(node, visited, noAscend)
	-- Mark the current node as visited so we don't go around in circles
	node.visited = true
	t_insert(visited, node)
	-- For each node which is connected to this one, check if...
	for _, other in ipairs(node.linked) do
		-- Either:
		--  - the other node is a start node, or
		--  - there is a path to a start node through the other node which didn't pass through any nodes which have already been visited
		local startIndex = #visited + 1
		if other.alloc and 
		  (other.type == "ClassStart" or other.type == "AscendClassStart" or 
		    (not other.visited and node.type ~= "Mastery" and self:FindStartFromNode(other, visited, noAscend))
		  ) then
			if node.ascendancyName and not other.ascendancyName then
				-- Pathing out of Ascendant, un-visit the outside nodes
				for i = startIndex, #visited do
					visited[i].visited = false
					visited[i] = nil
				end
			elseif not noAscend or other.type ~= "AscendClassStart" then
				return true
			end
		end
	end
end

function PassiveSpecClass:GetJewel(itemId)
	if not itemId or itemId == 0 then
		return
	end
	local item = self.build.itemsTab.items[itemId]
	if not item or not item.jewelData then
		return
	end
	return item
end

-- Perform a breadth-first search of the tree, starting from this node, and determine if it is the closest node to any other nodes
function PassiveSpecClass:BuildPathFromNode(root)
	root.pathDist = 0
	root.path = { }
	local queue = { root }
	local o, i = 1, 2 -- Out, in
	while o < i do
		-- Nodes are processed in a queue, until there are no nodes left
		-- All nodes that are 1 node away from the root will be processed first, then all nodes that are 2 nodes away, etc
		local node = queue[o]
		o = o + 1
		local curDist = node.pathDist + 1
		-- Iterate through all nodes that are connected to this one
		for _, other in ipairs(node.linked) do
			-- Paths must obey these rules:
			-- 1. They must not pass through class or ascendancy class start nodes (but they can start from such nodes)
			-- 2. They cannot pass between different ascendancy classes or between an ascendancy class and the main tree
			--    The one exception to that rule is that a path may start from an ascendancy node and pass into the main tree
			--    This permits pathing from the Ascendant 'Path of the X' nodes into the respective class start areas
			-- 3. They must not pass away from mastery nodes
			if not other.pathDist then
				ConPrintTable(other, true)
			end
			if node.type ~= "Mastery" and other.type ~= "ClassStart" and other.type ~= "AscendClassStart" and other.pathDist > curDist and (node.ascendancyName == other.ascendancyName or (curDist == 1 and not other.ascendancyName)) then
				-- The shortest path to the other node is through the current node
				other.pathDist = curDist
				other.path = wipeTable(other.path)
				other.path[1] = other
				for i, n in ipairs(node.path) do
					other.path[i+1] = n
				end
				-- Add the other node to the end of the queue
				queue[i] = other
				i = i + 1
			end
		end
	end
end

-- Determine this node's distance from the class' start
-- Only allocated nodes can be traversed
function PassiveSpecClass:SetNodeDistanceToClassStart(root)
	root.distanceToClassStart = 0
	if not root.alloc or root.dependsOnIntuitiveLeapLike then
		return
	end

	-- Stop once the current class' starting node is reached
	local targetNodeId = self.curClass.startNodeId

	local nodeDistanceToRoot = { }
	nodeDistanceToRoot[root.id] = 0

	local queue = { root }
	local o, i = 1, 2 -- Out, in
	while o < i do
		-- Nodes are processed in a queue, until there are no nodes left or the starting node is reached
		-- All nodes that are 1 node away from the root will be processed first, then all nodes that are 2 nodes away, etc
		-- Only allocated nodes are queued
		local node = queue[o]
		o = o + 1
		local curDist = nodeDistanceToRoot[node.id] + 1
		-- Iterate through all nodes that are connected to this one
		for _, other in ipairs(node.linked) do
			-- If this connected node is the correct class start node, then record the distance to the node and return
			if other.id == targetNodeId then
				root.distanceToClassStart = curDist - 1
				return
			end

			-- Otherwise, record the distance to this node if it hasn't already been visited
			if other.alloc and node.type ~= "Mastery" and other.type ~= "ClassStart" and other.type ~= "AscendClassStart" and not nodeDistanceToRoot[other.id] then
				nodeDistanceToRoot[other.id] = curDist;

				-- Add the other node to the end of the queue
				queue[i] = other
				i = i + 1
			end
		end
	end
end

function PassiveSpecClass:AddMasteryEffectOptionsToNode(node)
	node.sd = {}
	if node.masteryEffects ~= nil then
		for _, effect in ipairs(node.masteryEffects) do
			effect = self.tree.masteryEffects[effect.effect]
			if effect.sd ~= nil then
				for _, sd in ipairs(effect.sd) do
					t_insert(node.sd, sd)
				end
			end
		end
	end
	self.tree:ProcessStats(node)
	node.allMasteryOptions = true
end

-- Rebuilds dependencies and paths for all nodes
function PassiveSpecClass:BuildAllDependsAndPaths()
	-- This table will keep track of which nodes have been visited during each path-finding attempt
	local visited = { }
	local attributes = { "Dexterity", "Intelligence", "Strength" }
	-- Check all nodes for other nodes which depend on them (i.e. are only connected to the tree through that node)
	for id, node in pairs(self.nodes) do
		node.depends = wipeTable(node.depends)
		node.dependsOnIntuitiveLeapLike = false
		node.conqueredBy = nil

		-- ignore cluster jewel nodes that don't have an id in the tree
		if self.tree.nodes[id] then
			self:ReplaceNode(node,self.tree.nodes[id])
		end

		if node.type ~= "ClassStart" and node.type ~= "Socket" and not node.ascendancyName then
			for nodeId, itemId in pairs(self.jewels) do
				local item = self.build.itemsTab.items[itemId]
				if item and item.jewelRadiusIndex and self.allocNodes[nodeId] and item.jewelData then
					local radiusIndex = item.jewelRadiusIndex
					if self.nodes[nodeId].nodesInRadius and self.nodes[nodeId].nodesInRadius[radiusIndex][node.id] then
						if itemId ~= 0 then
							if item.jewelData.intuitiveLeapLike then
								-- This node depends on Intuitive Leap-like behaviour
								-- This flag:
								-- 1. Prevents generation of paths from this node
								-- 2. Prevents this node from being deallocted via dependency
								-- 3. Prevents allocation of path nodes when this node is being allocated
								node.dependsOnIntuitiveLeapLike = true
							end
							if item.jewelData.conqueredBy then
								node.conqueredBy = item.jewelData.conqueredBy
							end
						end
					end

					if item.jewelData and item.jewelData.impossibleEscapeKeystone then
						for keyName, keyNode in pairs(self.tree.keystoneMap) do
							if item.jewelData.impossibleEscapeKeystones[keyName:lower()] and keyNode.nodesInRadius then
								if keyNode.nodesInRadius[radiusIndex][node.id] then
									node.dependsOnIntuitiveLeapLike = true
								end
							end
						end
					end
				end
			end
		end
		if node.alloc then
			node.depends[1] = node -- All nodes depend on themselves
		end
	end

	for id, node in pairs(self.nodes) do
		-- If node is conquered, replace it or add mods
		if node.conqueredBy and node.type ~= "Socket" then
			local conqueredBy = node.conqueredBy
			local legionNodes = self.tree.legion.nodes
			local legionAdditions = self.tree.legion.additions

			-- FIXME - continue implementing
			local jewelType = 5
			if conqueredBy.conqueror.type == "vaal" then
				jewelType = 1
			elseif conqueredBy.conqueror.type == "karui" then
				jewelType = 2
			elseif conqueredBy.conqueror.type == "maraketh" then
				jewelType = 3
			elseif conqueredBy.conqueror.type == "templar" then
				jewelType = 4
			end
			local seed = conqueredBy.id
			if jewelType == 5 then
				seed = seed / 20
			end
			
			local replaceHelperFunc = function(statToFix, statKey, statMod, value)
				if statMod.fmt == "g" then -- note the only one we actually care about is "Ritual of Flesh" life regen
					if statKey:find("per_minute") then
						value = round(value / 60, 1)
					elseif statKey:find("permyriad") then
						value = value / 100
					elseif statKey:find("_ms") then
						value = value / 1000
					end
				end
				--if statMod.fmt == "d" then -- only ever d or g, and we want both past here
				if statMod.min ~= statMod.max then
					return statToFix:gsub("%(" .. statMod.min .. "%-" .. statMod.max .. "%)", value)
				elseif statMod.min ~= value then -- only true for might/legacy of the vaal which can combine stats
					return statToFix:gsub(statMod.min, value)
				end
				return statToFix -- if it doesn't need to be changed
			end

			if node.type == "Notable" then
				local jewelDataTbl = { }
				if seed ~= m_max(m_min(seed, data.timelessJewelSeedMax[jewelType]), data.timelessJewelSeedMin[jewelType]) then
					ConPrintf("ERROR: Seed " .. seed .. " is outside of valid range [" .. data.timelessJewelSeedMin[jewelType] .. " - " .. data.timelessJewelSeedMax[jewelType] .. "] for jewel type: " .. data.timelessJewelTypes[jewelType])
				else
					jewelDataTbl = data.readLUT(conqueredBy.id, node.id, jewelType)
				end
				--print("Need to Update: " .. node.id .. " [" .. node.dn .. "]")
				if not next(jewelDataTbl) then
					ConPrintf("Missing LUT: " .. data.timelessJewelTypes[jewelType])
				else
					if jewelType == 1 then
						local headerSize = #jewelDataTbl
						-- FIXME: complete implementation of this. Need to set roll values for stats
						--        based on their `fmt` specification 
						if headerSize == 2 or headerSize == 3 then
							self:ReplaceNode(node, legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions])

							for i, repStat in ipairs(legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions].sd) do
								local statKey = legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions].sortedStats[i]
								local statMod = legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions].stats[statKey]
								repStat = replaceHelperFunc(repStat, statKey, statMod, jewelDataTbl[statMod.index + 1])
								self:NodeAdditionOrReplacementFromString(node, repStat, i == 1) -- wipe mods on first run
							end
							-- should fix the stat values here (note headerSize == 3 has 2 values)
						elseif headerSize == 6 or headerSize == 8 then
							local bias = 0
							for i,val in ipairs(jewelDataTbl) do
								if i > (headerSize / 2) then
									break
								elseif val <= 21 then
									bias = bias + 1
								else
									bias = bias - 1
								end
							end
							if bias >= 0 then
								self:ReplaceNode(node, legionNodes[77]) -- might of the vaal
							else
								self:ReplaceNode(node, legionNodes[78]) -- legacy of the vaal
							end
							local additions = {}
							for i,val in ipairs(jewelDataTbl) do
								if i <= (headerSize / 2) then
									local roll = jewelDataTbl[i + headerSize / 2]
									if not additions[val] then
										additions[val] = roll
									else
										additions[val] = additions[val] + roll
									end
								else
									break
								end
							end
							for add, val in pairs(additions) do
								local addition = legionAdditions[add + 1]
								for _, addStat in ipairs(addition.sd) do
									for k,statMod in pairs(addition.stats) do -- should only be 1 big, these didn't get changed so can't just grab index
										addStat = replaceHelperFunc(addStat, k, statMod, val)
									end
									self:NodeAdditionOrReplacementFromString(node, addStat)
								end
							end
						else
							ConPrintf("Unhandled Glorious Vanity headerSize: " .. headerSize)
						end
					else
						for _, jewelData in ipairs(jewelDataTbl) do
							if jewelData >= data.timelessJewelAdditions then -- replace
								jewelData = jewelData + 1 - data.timelessJewelAdditions
								local legionNode = legionNodes[jewelData]
								if legionNode then
									self:ReplaceNode(node, legionNode)
								else
									ConPrintf("Unhandled 'replace' ID: " .. jewelData)
								end
							elseif jewelData then -- add
								local addition = legionAdditions[jewelData + 1]
								for _, addStat in ipairs(addition.sd) do
									self:NodeAdditionOrReplacementFromString(node, " \n" .. addStat)
								end
							elseif next(jewelData) then
								ConPrintf("Unhandled OP: " .. jewelData + 1)
							end
						end
					end
				end
			elseif node.type == "Keystone" then
				local matchStr = conqueredBy.conqueror.type .. "_keystone_" .. conqueredBy.conqueror.id
				for _, legionNode in ipairs(legionNodes) do
					if legionNode.id == matchStr then
						self:ReplaceNode(node, legionNode)
						break
					end
				end					
			elseif node.type == "Normal" then
				if conqueredBy.conqueror.type == "vaal" then
					local jewelDataTbl = { }
					if seed ~= m_max(m_min(seed, data.timelessJewelSeedMax[jewelType]), data.timelessJewelSeedMin[jewelType]) then
						ConPrintf("ERROR: Seed " .. seed .. " is outside of valid range [" .. data.timelessJewelSeedMin[jewelType] .. " - " .. data.timelessJewelSeedMax[jewelType] .. "] for jewel type: " .. data.timelessJewelTypes[jewelType])
					else
						jewelDataTbl = data.readLUT(conqueredBy.id, node.id, jewelType)
					end
					--print("Need to Update: " .. node.id .. " [" .. node.dn .. "]")
					if not next(jewelDataTbl) then
						ConPrintf("Missing LUT: " .. data.timelessJewelTypes[jewelType])
					else
						self:ReplaceNode(node, legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions])
						for i, repStat in ipairs(node.sd) do
							local statKey = legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions].sortedStats[i]
							local statMod = legionNodes[jewelDataTbl[1] + 1 - data.timelessJewelAdditions].stats[statKey]
							repStat = replaceHelperFunc(repStat, statKey, statMod, jewelDataTbl[2])
							self:NodeAdditionOrReplacementFromString(node, repStat, true)
						end
					end
				elseif conqueredBy.conqueror.type == "karui" then
					local str = isValueInArray(attributes, node.dn) and "2" or "4"
					self:NodeAdditionOrReplacementFromString(node, " \n+" .. str .. " to Strength")
				elseif conqueredBy.conqueror.type == "maraketh" then
					local dex = isValueInArray(attributes, node.dn) and "2" or "4"
					self:NodeAdditionOrReplacementFromString(node, " \n+" .. dex .. " to Dexterity")
				elseif conqueredBy.conqueror.type == "templar" then
					if isValueInArray(attributes, node.dn) then
						local legionNode = legionNodes[91] -- templar_devotion_node
						self:ReplaceNode(node, legionNode)
					else
						self:NodeAdditionOrReplacementFromString(node, " \n+5 to Devotion")
					end
				elseif conqueredBy.conqueror.type == "eternal" then
					local legionNode = legionNodes[110] -- eternal_small_blank
					self:ReplaceNode(node, legionNode)
				end
			end
			self:ReconnectNodeToClassStart(node)
		end
	end

	-- Add selected mastery effect mods to mastery nodes
	self.allocatedMasteryCount = 0
	self.allocatedNotableCount = 0
	self.allocatedMasteryTypes = { }
	self.allocatedMasteryTypeCount = 0
	for id, node in pairs(self.nodes) do
		if node.type == "Mastery" and self.masterySelections[id] then
			local effect = self.tree.masteryEffects[self.masterySelections[id]]
			if effect then
				node.sd = effect.sd
				node.allMasteryOptions = false
				node.reminderText = { "Tip: Right click to select a different effect" }
				self.tree:ProcessStats(node)
				self.allocatedMasteryCount = self.allocatedMasteryCount + 1
				if not self.allocatedMasteryTypes[self.allocNodes[id].name] then
					self.allocatedMasteryTypes[self.allocNodes[id].name] = 1
					self.allocatedMasteryTypeCount = self.allocatedMasteryTypeCount + 1
				else
					local prevCount = self.allocatedMasteryTypes[self.allocNodes[id].name]
					self.allocatedMasteryTypes[self.allocNodes[id].name] = prevCount + 1
					if prevCount == 0 then
						self.allocatedMasteryTypeCount = self.allocatedMasteryTypeCount + 1
					end
				end
			else
				self.nodes[id].alloc = false
				self.allocNodes[id] = nil
			end
		elseif node.type == "Mastery" then
			self:AddMasteryEffectOptionsToNode(node)
		elseif node.type == "Notable" and node.alloc then
			self.allocatedNotableCount = self.allocatedNotableCount + 1
		end
	end

	for id, node in pairs(self.allocNodes) do
		node.visited = true
		local anyStartFound = (node.type == "ClassStart" or node.type == "AscendClassStart")
		for _, other in ipairs(node.linked) do
			if other.alloc and not isValueInArray(node.depends, other) then
				-- The other node is allocated and isn't already dependent on this node, so try and find a path to a start node through it
				if other.type == "ClassStart" or other.type == "AscendClassStart" then
					-- Well that was easy!
					anyStartFound = true
				elseif self:FindStartFromNode(other, visited) then
					-- We found a path through the other node, therefore the other node cannot be dependent on this node
					anyStartFound = true
					for i, n in ipairs(visited) do
						n.visited = false
						visited[i] = nil
					end
				else
					-- No path was found, so all the nodes visited while trying to find the path must be dependent on this node
					-- except for mastery nodes that have linked allocated nodes that weren't visited
					local depIds = { }
					for _, n in ipairs(visited) do
						if not n.dependsOnIntuitiveLeapLike then
							depIds[n.id] = true
						end
					end
					for i, n in ipairs(visited) do
						if not n.dependsOnIntuitiveLeapLike then
							if n.type == "Mastery" then
								local otherPath = false
								local allocatedLinkCount = 0
								for _, linkedNode in ipairs(n.linked) do
									if linkedNode.alloc then
										allocatedLinkCount = allocatedLinkCount + 1
									end
								end
								if allocatedLinkCount > 1 then
									for _, linkedNode in ipairs(n.linked) do
										if linkedNode.alloc and not depIds[linkedNode.id] then
											otherPath = true
										end
									end
								end
								if not otherPath then
									t_insert(node.depends, n)
								end
							else
								t_insert(node.depends, n)
							end
						end
						n.visited = false
						visited[i] = nil
					end
				end
			end
		end
		node.visited = false
		if not anyStartFound then
			-- No start nodes were found through ANY nodes
			-- Therefore this node and all nodes depending on it are orphans and should be pruned
			for _, depNode in ipairs(node.depends) do
				local prune = true
				for nodeId, itemId in pairs(self.jewels) do
					if self.allocNodes[nodeId] then
						if itemId ~= 0 and (
							 self.build.itemsTab.items[itemId] and (
								self.build.itemsTab.items[itemId].jewelData
									and self.build.itemsTab.items[itemId].jewelData.intuitiveLeapLike
									and self.build.itemsTab.items[itemId].jewelRadiusIndex
									and self.nodes[nodeId].nodesInRadius
									and self.nodes[nodeId].nodesInRadius[self.build.itemsTab.items[itemId].jewelRadiusIndex][depNode.id]
							) or (
								self.build.itemsTab.items[itemId].jewelData
									and self.build.itemsTab.items[itemId].jewelData.impossibleEscapeKeystones
									and self:NodeInKeystoneRadius(self.build.itemsTab.items[itemId].jewelData.impossibleEscapeKeystones, depNode.id, self.build.itemsTab.items[itemId].jewelRadiusIndex)
							)
						) then
							-- Hold off on the pruning; this node could be supported by Intuitive Leap-like jewel
							prune = false
							t_insert(self.nodes[nodeId].depends, depNode)
							break
						end
					end
				end
				if prune then
					self:DeallocSingleNode(depNode)
				end
			end
		end
	end

	-- Reset and rebuild all node paths
	for id, node in pairs(self.nodes) do
		node.pathDist = (node.alloc and not node.dependsOnIntuitiveLeapLike) and 0 or 1000
		node.path = nil
		if node.isJewelSocket or node.expansionJewel then
			node.distanceToClassStart = 0
		end
	end
	for id, node in pairs(self.allocNodes) do
		if not node.dependsOnIntuitiveLeapLike then
			self:BuildPathFromNode(node)
			if node.isJewelSocket or node.expansionJewel then
				self:SetNodeDistanceToClassStart(node)
			end
		end
	end
end

function PassiveSpecClass:ReplaceNode(old, newNode)
	-- Edited nodes can share a name
	if old.sd == newNode.sd then
		return 1
	end
	old.dn = newNode.dn
	old.sd = newNode.sd
	old.mods = newNode.mods
	old.modKey = newNode.modKey
	old.modList = new("ModList")
	old.modList:AddList(newNode.modList)
	old.sprites = newNode.sprites
	old.keystoneMod = newNode.keystoneMod
	old.icon = newNode.icon
	old.spriteId = newNode.spriteId
	old.reminderText = newNode.reminderText or { }
end

---Reconnects altered timeless jewel to class start, for Pure Talent
---@param node table @ The node to add the Condition:ConnectedTo[Class] flag to, if applicable
function PassiveSpecClass:ReconnectNodeToClassStart(node)
	for _, linkedNodeId in ipairs(node.linkedId) do
		for classId, class in pairs(self.tree.classes) do
			if linkedNodeId == class.startNodeId and node.type == "Normal" then
				node.modList:NewMod("Condition:ConnectedTo"..class.name.."Start", "FLAG", true, "Tree:"..linkedNodeId)
			end
		end
	end
end

function PassiveSpecClass:BuildClusterJewelGraphs()
	-- Remove old subgraphs
	for id, subGraph in pairs(self.subGraphs) do
		for _, node in ipairs(subGraph.nodes) do
			if node.id then
				self.nodes[node.id] = nil
				if self.allocNodes[node.id] then
					-- Reserve the allocation in case the node is regenerated
					self.allocNodes[node.id] = nil
					t_insert(self.allocSubgraphNodes, node.id)
				end
			end
		end
		local index = isValueInArray(subGraph.parentSocket.linked, subGraph.entranceNode)
		assert(index, "Entrance for subGraph not linked to parent socket???")
		t_remove(subGraph.parentSocket.linked, index)
	end
	wipeTable(self.subGraphs)

	local importedGroups = { }
	local importedNodes = { }
	if self.jewel_data then
		for _, value in pairs(self.jewel_data) do
			if value.subgraph then
				for groupId, groupData in pairs(value.subgraph.groups) do
					importedGroups[groupId] = groupData
				end
				for nodeId, nodeValue in pairs(value.subgraph.nodes) do
					importedNodes[nodeId] = nodeValue
				end
			end
		end
	end
	for nodeId in pairs(self.tree.sockets) do
		local node = self.tree.nodes[nodeId]
		local jewel = self:GetJewel(self.jewels[nodeId])
		if node and node.expansionJewel and node.expansionJewel.size == 2 and jewel and jewel.jewelData.clusterJewelValid then
			-- This is a Large Jewel Socket, and it has a cluster jewel in it
			self:BuildSubgraph(jewel, self.nodes[nodeId], nil, nil, importedNodes, importedGroups)
		end
	end

	-- (Re-)allocate subgraph nodes
	for _, nodeId in ipairs(self.allocSubgraphNodes) do
		local node = self.nodes[nodeId]
		if node then
			node.alloc = true
			if not self.allocNodes[nodeId] then
				self.allocNodes[nodeId] = node
				t_insert(self.allocExtendedNodes, nodeId)
			end
		end
	end
	wipeTable(self.allocSubgraphNodes)

	-- Rebuild paths to account for new/removed nodes
	self:BuildAllDependsAndPaths()

	-- Rebuild node search cache because the tree might have changed
	self.build.treeTab.viewer.searchStrCached = ""
end

function PassiveSpecClass:BuildSubgraph(jewel, parentSocket, id, upSize, importedNodes, importedGroups)
	local expansionJewel = parentSocket.expansionJewel
	local clusterJewel = jewel.clusterJewel
	local jewelData = jewel.jewelData

	local subGraph = {
		nodes = { },
		group = { oo = { } },
		connectors = { },
		parentSocket = parentSocket,
	}

	-- Make id for this subgraph (and nodes)
	-- 0-3: Node index (0-11)
	-- 4-5: Group size (0-2)
	-- 6-8: Large index (0-5)
	-- 9-10: Medium index (0-2)
	-- 11-15: Unused
	-- 16: 1 (signal bit, to prevent conflict with node hashes)
	id = id or 0x10000
	if expansionJewel.size == 2 then
		id = id + b_lshift(expansionJewel.index, 6)
	elseif expansionJewel.size == 1 then
		id = id + b_lshift(expansionJewel.index, 9)
	end
	local nodeId = id + b_lshift(clusterJewel.sizeIndex, 4)

	self.subGraphs[nodeId] = subGraph

	-- Locate the proxy group
	local proxyNode = self.tree.nodes[tonumber(expansionJewel.proxy)]
	assert(proxyNode, "Proxy node not found")
	local proxyGroup = proxyNode.group

	-- Actually, let's not, since the game doesn't handle this :D
--	if upSize and upSize > 0 then
--		-- We need to move inwards to account for the parent group being downsized
--		-- So we position according to the parent's original group position
--		assert(upSize == 1) -- Only handling 1 upsize, which is the most that is possible
--		local parentGroup = self.tree.nodes[parentSocket.id].group
--		subGraph.group.x = parentGroup.x
--		subGraph.group.y = parentGroup.y
--	else
		-- Position the group using the original proxy's position
		subGraph.group.x = proxyGroup.x
		subGraph.group.y = proxyGroup.y
--	end

	local function linkNodes(node1, node2)
		t_insert(node1.linked, node2)
		t_insert(node2.linked, node1)
		-- BuildConnector returns a table of objects, not a single object now
		local connectors = self.tree:BuildConnector(node1, node2)
		t_insert(subGraph.connectors, connectors[1])
		if connectors[2] then
			t_insert(subGraph.connectors, connectors[2])
		end
	end

	local function matchGroup(proxyId)
		for groupId, groupData in pairs(importedGroups) do
			if groupData.proxy == proxyId then
				return groupId
			end
		end
	end

	local function inExtendedHashes(nodeId)
		for _, exID in ipairs(self.extended_hashes) do
			if nodeId == exID then
				return true
			end
		end
		return false
	end

	local function addToAllocatedSubgraphNodes(node)
		local proxyGroup = matchGroup(expansionJewel.proxy)
		if proxyGroup then
			for id, data in pairs(importedNodes) do
				if proxyGroup == data.group then
					if node.oidx == data.orbitIndex and node.type ~= "Mastery" then
						for _, extendedId in ipairs(importedGroups[proxyGroup].nodes) do
							if id == tonumber(extendedId) and inExtendedHashes(id) then
								return true
							end
						end
						return false
					end
				end
			end
		end
		return false
	end

	if jewelData.clusterJewelKeystone then
		-- Special handling for keystones
		local keystoneNode = self.tree.clusterNodeMap[jewelData.clusterJewelKeystone]
		assert(keystoneNode, "Keystone node not found: "..jewelData.clusterJewelKeystone)

		-- Construct the new node
		local node = {
			type = "Keystone",
			id = nodeId,
			dn = keystoneNode.dn,
			sd = keystoneNode.sd,
			icon = keystoneNode.icon,
			expansionSkill = true,
			group = subGraph.group,
			o = 0,
			oidx = 1,
			linked = { },
			power = { },
		}
		t_insert(subGraph.nodes, node)

		-- Process and add it
		self.tree:ProcessNode(node)
		linkNodes(node, parentSocket)
		subGraph.entranceNode = node
		self.nodes[node.id] = node
		if addToAllocatedSubgraphNodes(node) then
			t_insert(self.allocSubgraphNodes, node.id)
			t_insert(self.allocExtendedNodes, node.id)
		end
		return
	end

	local function findSocket(group, index)
		-- Find the given socket index in the group
		for _, nodeId in ipairs(group.n) do
			local node = self.tree.nodes[tonumber(nodeId)]
			if node.expansionJewel and node.expansionJewel.index == index then
				return node
			end
		end
	end

	-- Check if we need to downsize the group
	local groupSize = expansionJewel.size
	upSize = upSize or 0
	while clusterJewel.sizeIndex < groupSize do
		-- Look for the socket with index 1 first (middle socket of large groups), then index 0
		local socket = findSocket(proxyGroup, 1) or findSocket(proxyGroup, 0)
		assert(socket, "Downsizing socket not found")

		-- Grab the proxy node/group from the socket
		proxyNode = self.tree.nodes[tonumber(socket.expansionJewel.proxy)]
		proxyGroup = proxyNode.group
		groupSize = socket.expansionJewel.size
		upSize = upSize + 1
	end

	-- Initialise orbit flags
	local nodeOrbit = clusterJewel.sizeIndex + 1
	subGraph.group.oo[nodeOrbit] = true

	-- Process list of notables
	local notableList = { }
	local sortOrder = self.build.data.clusterJewels.notableSortOrder
	for _, name in ipairs(jewelData.clusterJewelNotables) do
		local baseNode = self.tree.clusterNodeMap[name]
		-- Ignore subgraphs when loading old trees where certain notables don't exist
		if not baseNode then
			self.subGraphs[nodeId] = nil
			return
		end
		assert(baseNode, "Cluster notable not found:  "..name)
		assert(sortOrder[baseNode.dn], "Cluster notable has no sort order: "..name)
		t_insert(notableList, baseNode)
	end
	table.sort(notableList, function(a, b) return sortOrder[a.dn] < sortOrder[b.dn] end)

	local skill = clusterJewel.skills[jewelData.clusterJewelSkill] or {
		name = "Nothingness",
		icon = "Art/2DArt/SkillIcons/passives/MasteryBlank.png",
		stats = { },
	}
	local socketCount = jewelData.clusterJewelSocketCountOverride or jewelData.clusterJewelSocketCount or 0
	local notableCount = #notableList
	local nodeCount = jewelData.clusterJewelNodeCount or (socketCount + notableCount + (jewelData.clusterJewelNothingnessCount or 0))
	local smallCount = nodeCount - socketCount - notableCount

	if skill.masteryIcon then
		-- Add mastery node
		subGraph.group.oo[0] = true
		t_insert(subGraph.nodes, {
			dn = "Nothingness",
			sd = { },
			type = "Mastery",
			id = nodeId + 12,
			icon = skill.masteryIcon,
			group = subGraph.group,
			o = 0,
			oidx = 0,
		})
	end

	local indicies = { }

	local function makeJewel(nodeIndex, jewelIndex)
		-- Look for the socket
		local socket = findSocket(proxyGroup, jewelIndex)
		assert(socket, "Socket not found (ran out of sockets nani?)")

		-- Construct the new node
		local node = {
			type = "Socket",
			id = socket.id,
			dn = socket.dn,
			sd = { },
			icon = socket.icon,
			expansionJewel = socket.expansionJewel,
			group = subGraph.group,
			o = nodeOrbit,
			oidx = nodeIndex,
		}
		t_insert(subGraph.nodes, node)
		indicies[nodeIndex] = node
	end

	-- First pass: sockets
	if clusterJewel.size == "Large" and socketCount == 1 then
		-- Large clusters always have the single jewel at index 6
		makeJewel(6, 1)
	else
		assert(socketCount <= #clusterJewel.socketIndicies, "Too many sockets!")
		local getJewels = { 0, 2, 1 }
		for i = 1, socketCount do
			makeJewel(clusterJewel.socketIndicies[i], getJewels[i])
		end
	end

	-- Second pass: notables

	-- Gather notable indicies
	local notableIndexList = { }
	for _, nodeIndex in ipairs(clusterJewel.notableIndicies) do
		if #notableIndexList == notableCount then
			break
		end
		if clusterJewel.size == "Medium" then
			if socketCount == 0 and notableCount == 2 then
				-- Special rule for two notables in a Medium cluster
				if nodeIndex == 6 then
					nodeIndex = 4
				elseif nodeIndex == 10 then
					nodeIndex = 8
				end
			elseif nodeCount == 4 then
				-- Special rule for notables in a 4-node Medium cluster
				if nodeIndex == 10 then
					nodeIndex = 9
				elseif nodeIndex == 2 then
					nodeIndex = 3
				end
			end
		end
		if not indicies[nodeIndex] then
			t_insert(notableIndexList, nodeIndex)
		end
	end
	table.sort(notableIndexList)

	-- Create the notables
	for index, baseNode in ipairs(notableList) do
		-- Get the index
		local nodeIndex = notableIndexList[index]
		if not nodeIndex then
			-- Silently fail to handle cases of jewels with more notables than should be allowed
			break
		end

		-- Construct the new node
		local node = {
			type = "Notable",
			id = nodeId + nodeIndex,
			dn = baseNode.dn,
			sd = baseNode.sd,
			icon = baseNode.icon,
			expansionSkill = true,
			group = subGraph.group,
			o = nodeOrbit,
			oidx = nodeIndex,
		}
		t_insert(subGraph.nodes, node)
		indicies[nodeIndex] = node
	end

	-- Third pass: small fill

	-- Gather small indicies
	local smallIndexList = { }
	for _, nodeIndex in ipairs(clusterJewel.smallIndicies) do
		if #smallIndexList == smallCount then
			break
		end
		if clusterJewel.size == "Medium" then
			-- Special rules for small nodes in Medium clusters
			if nodeCount == 5 and nodeIndex == 4 then
				nodeIndex = 3
			elseif nodeCount == 4 then
				if nodeIndex == 8 then
					nodeIndex = 9
				elseif nodeIndex == 4 then
					nodeIndex = 3
				end
			end
		end
		if not indicies[nodeIndex] then
			t_insert(smallIndexList, nodeIndex)
		end
	end

	-- Create the small nodes
	for index = 1, smallCount do
		-- Get the index
		local nodeIndex = smallIndexList[index]
		if not nodeIndex then
			break
		end

		-- Construct the new node
		local node = {
			type = "Normal",
			id = nodeId + nodeIndex,
			dn = skill.name,
			sd = copyTable(skill.stats),
			icon = skill.icon,
			expansionSkill = true,
			group = subGraph.group,
			o = nodeOrbit,
			oidx = nodeIndex,
		}
		for _, line in ipairs(jewelData.clusterJewelAddedMods) do
			t_insert(node.sd, line)
		end
		t_insert(subGraph.nodes, node)
		indicies[nodeIndex] = node
	end

	assert(indicies[0], "No entrance to subgraph")
	subGraph.entranceNode = indicies[0]

	-- The nodes' oidx values we just calculated are all relative to the totalIndicies properties of Data/ClusterJewels,
	-- but the PassiveTree rendering logic treats node.oidx as relative to the tree.skillsPerOrbit constants. Those used
	-- to be the same, but as of 3.17 they can differ, so we need to translate the ClusterJewels-relative indices into
	-- tree.skillsPerOrbit-relative indices before we invoke tree:ProcessNode or do math against proxyNode.oidx.
	--
	-- The specific 12<->16 mappings are derived from https://github.com/grindinggear/skilltree-export/blob/3.17.0/README.md
	local function translateOidx(srcOidx, srcNodesPerOrbit, destNodesPerOrbit)
		if srcNodesPerOrbit == destNodesPerOrbit then
			return srcOidx
		elseif srcNodesPerOrbit == 12 and destNodesPerOrbit == 16 then
			return ({[0] = 0, 1,    3, 4, 5,    7, 8, 9,    11, 12, 13,     15})[srcOidx]
		elseif srcNodesPerOrbit == 16 and destNodesPerOrbit == 12 then
			return ({[0] = 0, 1, 1, 2, 3, 4, 4, 5, 6, 7, 7,  8,  9, 10, 10, 11})[srcOidx]
		else
			-- there is no known case where this should happen...
			launch:ShowErrMsg("^1Error: unexpected cluster jewel node counts %d -> %d", srcNodesPerOrbit, destNodesPerOrbit)
			-- ...but if a future patch adds one, this should end up only a little krangled, close enough for initial skill data imports:
			return m_floor(srcOidx * destNodesPerOrbit / srcNodesPerOrbit)
		end
	end
	local proxyNodeSkillsPerOrbit = self.tree.skillsPerOrbit[proxyNode.o+1]

	-- Translate oidx positioning to TreeData-relative values
	for _, node in pairs(indicies) do
		local proxyNodeOidxRelativeToClusterIndicies = translateOidx(proxyNode.oidx, proxyNodeSkillsPerOrbit, clusterJewel.totalIndicies)
		local correctedNodeOidxRelativeToClusterIndicies = (node.oidx + proxyNodeOidxRelativeToClusterIndicies) % clusterJewel.totalIndicies
		local correctedNodeOidxRelativeToTreeSkillsPerOrbit = translateOidx(correctedNodeOidxRelativeToClusterIndicies, clusterJewel.totalIndicies, proxyNodeSkillsPerOrbit)
		node.oidx = correctedNodeOidxRelativeToTreeSkillsPerOrbit
	end

	-- Perform processing on nodes to calculate positions, parse mods, and other goodies
	for _, node in ipairs(subGraph.nodes) do
		node.linked = { }
		node.power = { }
		self.tree:ProcessNode(node)
		if node.modList and jewelData.clusterJewelIncEffect and node.type == "Normal" then
			node.modList:NewMod("PassiveSkillEffect", "INC", jewelData.clusterJewelIncEffect)
		end
	end

	-- Generate connectors
	local firstNode, lastNode
	for i = 0, clusterJewel.totalIndicies - 1 do
		local thisNode = indicies[i]
		if thisNode then
			if not firstNode then
				firstNode = thisNode
			end
			if lastNode then
				linkNodes(thisNode, lastNode)
			end
			lastNode = thisNode
		end
	end
	if firstNode ~= lastNode and clusterJewel.size ~= "Small" then
		-- Close the loop on non-small clusters
		linkNodes(firstNode, lastNode)
	end
	linkNodes(subGraph.entranceNode, parentSocket)

	-- Add synthetic nodes to the main node list
	for _, node in ipairs(subGraph.nodes) do
		self.nodes[node.id] = node
		if addToAllocatedSubgraphNodes(node) then
			t_insert(self.allocSubgraphNodes, node.id)
		end
		if node.type == "Socket" then
			-- Recurse to smaller jewels
			local jewel = self:GetJewel(self.jewels[node.id])
			if jewel and jewel.jewelData.clusterJewelValid then
				self:BuildSubgraph(jewel, node, id, upSize, importedNodes, importedGroups)
			end
		end
	end

	--ConPrintTable(subGraph)
end

function PassiveSpecClass:CreateUndoState()
	local allocNodeIdList = { }
	for nodeId in pairs(self.allocNodes) do
		t_insert(allocNodeIdList, nodeId)
	end
	local selections = { }
	for mastery, effect in pairs(self.masterySelections) do
		selections[mastery] = effect
	end
	return {
		classId = self.curClassId,
		ascendClassId = self.curAscendClassId,
		hashList = allocNodeIdList,
		masteryEffects = selections,
		treeVersion = self.treeVersion
	}
end

function PassiveSpecClass:RestoreUndoState(state)
	self:ImportFromNodeList(state.classId, state.ascendClassId, state.hashList, state.masteryEffects, state.treeVersion)
	self:SetWindowTitleWithBuildClass()
end

function PassiveSpecClass:SetWindowTitleWithBuildClass()
	main:SetWindowTitleSubtext(string.format("%s (%s)", self.build.buildName, self.curAscendClassId == 0 and self.curClassName or self.curAscendClassName))
end

--- Adds a line to or replaces a node given a line to add/replace with
--- @param node table The node to replace/add to
--- @param sd string The line being parsed and added
--- @param replacement boolean true to replace the node with the new mod, false to simply add it
function PassiveSpecClass:NodeAdditionOrReplacementFromString(node,sd,replacement)
	local addition = {}
	addition.sd = {sd}
	addition.mods = { }
	addition.modList = new("ModList")
	addition.modKey = ""
	local i = 1
	while addition.sd[i] do
		if addition.sd[i]:match("\n") then
			local line = addition.sd[i]
			local lineIdx = i
			t_remove(addition.sd, i)
			for line in line:gmatch("[^\n]+") do
				t_insert(addition.sd, lineIdx, line)
				lineIdx = lineIdx + 1
			end
		end
		local line = addition.sd[i]
		local parsedMod, unrecognizedMod = modLib.parseMod(line)
		if not parsedMod or unrecognizedMod then
			-- Try to combine it with one or more of the lines that follow this one
			local endI = i + 1
			while addition.sd[endI] do
				local comb = line
				for ci = i + 1, endI do
					comb = comb .. " " .. addition.sd[ci]
				end
				parsedMod, unrecognizedMod = modLib.parseMod(comb, true)
				if parsedMod and not unrecognizedMod then
					-- Success, add dummy mod lists to the other lines that were combined with this one
					for ci = i + 1, endI do
						addition.mods[ci] = { list = { } }
					end
					break
				end
				endI = endI + 1
			end
		end
		if not parsedMod then
			-- Parser had no idea how to read this modifier
			addition.unknown = true
		elseif unrecognizedMod then
			-- Parser recognised this as a modifier but couldn't understand all of it
			addition.extra = true
		else
			for _, mod in ipairs(parsedMod) do
				addition.modKey = addition.modKey.."["..modLib.formatMod(mod).."]"
			end
		end
		addition.mods[i] = { list = parsedMod, extra = unrecognizedMod }
		i = i + 1
		while addition.mods[i] do
			-- Skip any lines with dummy lists added by the line combining code
			i = i + 1
		end
	end

	-- Build unified list of modifiers from all recognised modifier lines
	for _, mod in pairs(addition.mods) do
		if mod.list and not mod.extra then
			for i, mod in ipairs(mod.list) do
				mod = modLib.setSource(mod, "Tree:"..node.id)
				addition.modList:AddMod(mod)
			end
		end
	end
	if replacement then
		node.sd = addition.sd
		node.mods = addition.mods
		node.modKey = addition.modKey
	else
		node.sd = tableConcat(node.sd, addition.sd)
		node.mods = tableConcat(node.mods, addition.mods)
		node.modKey = node.modKey .. addition.modKey
	end
	local modList = new("ModList")
	modList:AddList(addition.modList)
	if not replacement then
		modList:AddList(node.modList)
	end
	node.modList = modList
end

function PassiveSpecClass:NodeInKeystoneRadius(keystoneNames, nodeId, radiusIndex)
	for _, node in pairs(self.nodes) do
		if node.name and node.type == "Keystone" and keystoneNames[node.name:lower()] then
			if (node.nodesInRadius[radiusIndex][nodeId]) then
				return true
			end
		end
	end

	return false
end
