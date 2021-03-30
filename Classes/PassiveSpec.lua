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
	self.treeVersion = treeVersion
	self.tree = main.tree[treeVersion]

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

	-- Table of jewels equipped in this tree
	-- Keys are node IDs, values are items
	self.jewels = { }

	-- Tree graphs dynamically generated from cluster jewels
	-- Keys are subgraph IDs, values are graphs
	self.subGraphs = { }

	self:SelectClass(0)
end)

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
						self.jewels[tonumber(child.attrib.nodeId)] = tonumber(child.attrib.itemId)
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
		self:ImportFromNodeList(tonumber(xml.attrib.classId), tonumber(xml.attrib.ascendClassId), hashList)
	elseif url then
		self:DecodeURL(url)
	end
	for _, node in pairs(xml) do
		if type(node) == "table" then
			if node.elem == "EditedNodes" then
				for _, child in ipairs(node) do
					if not child.attrib.nodeId then
						launch:ShowErrMsg("^1Error parsing '%s': 'EditedNode' element missing 'nodeId' attribute", dbFileName)
						return true
					end
					if not child.attrib.editorSeed then
						launch:ShowErrMsg("^1Error parsing '%s': 'EditedNode' element missing 'editorSeed' attribute", dbFileName)
						return true
					end

					local editorSeed = tonumber(child.attrib.editorSeed)
					local nodeId = tonumber(child.attrib.nodeId)
					if not self.tree.legion.editedNodes then
						self.tree.legion.editedNodes = { }
					end
					if self.tree.legion.editedNodes[editorSeed] then
						self.tree.legion.editedNodes[editorSeed][nodeId] = copyTable(self.nodes[nodeId], true)
					else
						self.tree.legion.editedNodes[editorSeed] = { [nodeId] = copyTable(self.nodes[nodeId], true) }
					end
					self.tree.legion.editedNodes[editorSeed][nodeId].id = nodeId
					self.tree.legion.editedNodes[editorSeed][nodeId].dn = child.attrib.nodeName
					self.tree.legion.editedNodes[editorSeed][nodeId].icon = child.attrib.icon
					if self.tree.legion.nodes[child.attrib.spriteId] then
						self.tree.legion.editedNodes[editorSeed][nodeId].sprites = self.tree.legion.nodes[child.attrib.spriteId].sprites
					end
					local modCount = 0
					for _, modLine in ipairs(child) do
						for line in string.gmatch(modLine .. "\r\n", "([^\r\n\t]*)\r?\n") do
							self:NodeAdditionOrReplacementFromString(self.tree.legion.editedNodes[editorSeed][nodeId], line, modCount == 0)
							modCount = modCount + 1
						end
					end
				end
			end
		end
	end
	self:ResetUndo()
end

function PassiveSpecClass:Save(xml)
	local allocNodeIdList = { }
	for nodeId in pairs(self.allocNodes) do
		t_insert(allocNodeIdList, nodeId)
	end
	local editedNodes = {
		elem = "EditedNodes"
	}
	if self.tree.legion.editedNodes then
		for seed, nodes in pairs(self.tree.legion.editedNodes) do
			for nodeId, node in pairs(nodes) do
				local editedNode = { elem = "EditedNode", attrib = { nodeId = tostring(nodeId), editorSeed = tostring(seed), nodeName = node.dn, icon = node.icon, spriteId = node.spriteId } }
				for _, modLine in ipairs(node.sd) do
					t_insert(editedNode, modLine)
				end
				t_insert(editedNodes, editedNode)
			end
		end
	end
	t_insert(xml, editedNodes)
	xml.attrib = { 
		title = self.title,
		treeVersion = self.treeVersion,
		-- New format
		classId = tostring(self.curClassId), 
		ascendClassId = tostring(self.curAscendClassId), 
		nodes = table.concat(allocNodeIdList, ","),
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
		t_insert(sockets, { elem = "Socket", attrib = { nodeId = tostring(nodeId), itemId = tostring(itemId) } })
	end
	t_insert(xml, sockets)
	self.modFlag = false
end

function PassiveSpecClass:PostLoad()
	self:BuildClusterJewelGraphs()
end

-- Import passive spec from the provided class IDs and node hash list
function PassiveSpecClass:ImportFromNodeList(classId, ascendClassId, hashList)
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
	self:SelectAscendClass(ascendClassId)
end

-- Decode the given passive tree URL
function PassiveSpecClass:DecodeURL(url)
	local b = common.base64.decode(url:gsub("^.+/",""):gsub("-","+"):gsub("_","/"))
	if not b or #b < 6 then
		return "Invalid tree link (unrecognised format)"
	end
	local ver = b:byte(1) * 16777216 + b:byte(2) * 65536 + b:byte(3) * 256 + b:byte(4)
	if ver > 4 then
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
	local nodes = b:sub(ver >= 4 and 8 or 7, -1)
	for i = 1, #nodes - 1, 2 do
		local id = nodes:byte(i) * 256 + nodes:byte(i + 1)
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
		end
	end
end

-- Encodes the current spec into a URL, using the official skill tree's format
-- Prepends the URL with an optional prefix
function PassiveSpecClass:EncodeURL(prefix)
	local a = { 0, 0, 0, 4, self.curClassId, self.curAscendClassId, 0 }
	for id, node in pairs(self.allocNodes) do
		if node.type ~= "ClassStart" and node.type ~= "AscendClassStart" and id < 65536 then
			t_insert(a, m_floor(id / 256))
			t_insert(a, id % 256)
		end
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

-- Deallocate the given node, and all nodes which depend on it (i.e. which are only connected to the tree through this node)
function PassiveSpecClass:DeallocNode(node)
	for _, depNode in ipairs(node.depends) do
		depNode.alloc = false
		self.allocNodes[depNode.id] = nil
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
		    (not other.visited and self:FindStartFromNode(other, visited, noAscend))
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
			-- Paths must obey two rules:
			-- 1. They must not pass through class or ascendancy class start nodes (but they can start from such nodes)
			-- 2. They cannot pass between different ascendancy classes or between an ascendancy class and the main tree
			--    The one exception to that rule is that a path may start from an ascendancy node and pass into the main tree
			--    This permits pathing from the Ascendant 'Path of the X' nodes into the respective class start areas
			if not other.pathDist then
				ConPrintTable(other, true)
			end
			if other.type ~= "ClassStart" and other.type ~= "AscendClassStart" and other.pathDist > curDist and (node.ascendancyName == other.ascendancyName or (curDist == 1 and not other.ascendancyName)) then
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
			if other.alloc and not nodeDistanceToRoot[other.id] then
				nodeDistanceToRoot[other.id] = curDist;

				-- Add the other node to the end of the queue
				queue[i] = other
				i = i + 1
			end
		end
	end
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

		if node.type ~= "ClassStart" and node.type ~= "Socket" then
			for nodeId, itemId in pairs(self.jewels) do
				if self.build.itemsTab.items[itemId] and self.build.itemsTab.items[itemId].jewelRadiusIndex then
					local radiusIndex = self.build.itemsTab.items[itemId].jewelRadiusIndex
					if self.allocNodes[nodeId] and self.nodes[nodeId].nodesInRadius and self.nodes[nodeId].nodesInRadius[radiusIndex][node.id] then
						if itemId ~= 0 and self.build.itemsTab.items[itemId].jewelData then
							if self.build.itemsTab.items[itemId].jewelData.intuitiveLeapLike then
								-- This node depends on Intuitive Leap-like behaviour
								-- This flag:
								-- 1. Prevents generation of paths from this node
								-- 2. Prevents this node from being deallocted via dependancy
								-- 3. Prevents allocation of path nodes when this node is being allocated
								node.dependsOnIntuitiveLeapLike = true
							end
							if self.build.itemsTab.items[itemId].jewelData.conqueredBy then
								node.conqueredBy = self.build.itemsTab.items[itemId].jewelData.conqueredBy
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

			-- Replace with edited node if applicable
			if self.tree.legion.editedNodes and self.tree.legion.editedNodes[conqueredBy.id] and self.tree.legion.editedNodes[conqueredBy.id][node.id] then
				local editedNode = self.tree.legion.editedNodes[conqueredBy.id][node.id]
				node.dn = editedNode.dn
				node.sd = editedNode.sd
				node.sprites = editedNode.sprites
				node.mods = editedNode.mods
				node.modList = editedNode.modList
				node.modKey = editedNode.modKey
				node.icon = editedNode.icon
				node.spriteId = editedNode.spriteId
			else
				if node.type == "Keystone" then
					local legionNode = legionNodes[conqueredBy.conqueror.type.."_keystone_"..conqueredBy.conqueror.id]
					self:ReplaceNode(node, legionNode)
				elseif conqueredBy.conqueror.type == "eternal" and node.type == "Normal"  then
					local legionNode = legionNodes["eternal_small_blank"]
					self:ReplaceNode(node,legionNode)
				elseif conqueredBy.conqueror.type == "templar" then
					if isValueInArray(attributes, node.dn) then
						local legionNode =legionNodes["templar_devotion_node"]
						self:ReplaceNode(node,legionNode)
					else
						self:NodeAdditionOrReplacementFromString(node,"+5 to Devotion")
					end
				elseif conqueredBy.conqueror.type == "maraketh" and node.type == "Normal" then
					local dex = isValueInArray(attributes, node.dn) and "2" or "4"
					self:NodeAdditionOrReplacementFromString(node,"+"..dex.." to Dexterity")
				elseif conqueredBy.conqueror.type == "karui" and node.type == "Normal" then
					local str = isValueInArray(attributes, node.dn) and "2" or "4"
					self:NodeAdditionOrReplacementFromString(node,"+"..str.." to Strength")
				elseif conqueredBy.conqueror.type == "vaal" and node.type == "Normal" then
					local legionNode =legionNodes["vaal_small_fire_resistance"]
					node.dn = "Vaal small node"
					node.sd = {"Right click to set mod"}
					node.sprites = legionNode.sprites
					node.mods = {""}
					node.modList = new("ModList")
					node.modKey = ""
				elseif conqueredBy.conqueror.type == "vaal" and node.type == "Notable" then
					local legionNode =legionNodes["vaal_notable_curse_1"]
					node.dn = "Vaal notable node"
					node.sd = {"Right click to set mod"}
					node.sprites = legionNode.sprites
					node.mods = {""}
					node.modList = new("ModList")
					node.modKey = ""
				end
				self:ReconnectNodeToClassStart(node)
			end
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
					for i, n in ipairs(visited) do
						if not n.dependsOnIntuitiveLeapLike then
							t_insert(node.depends, n)
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
							not self.build.itemsTab.items[itemId] or (
								self.build.itemsTab.items[itemId].jewelData
									and self.build.itemsTab.items[itemId].jewelData.intuitiveLeapLike
									and self.build.itemsTab.items[itemId].jewelRadiusIndex
									and self.nodes[nodeId].nodesInRadius
									and self.nodes[nodeId].nodesInRadius[
										self.build.itemsTab.items[itemId].jewelRadiusIndex
								][depNode.id]
							)
						) then
							-- Hold off on the pruning; this node is Intuitive Leap-like or items are not loaded yet
							prune = false
							t_insert(self.nodes[nodeId].depends, depNode)
							break
						end
					end
				end
				if prune then
					depNode.alloc = false
					self.allocNodes[depNode.id] = nil
					ConPrintf("Pruned ID: " .. tostring(depNode.id))
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
	ConPrintf("\n")
	for _, nodeId in ipairs(self.allocSubgraphNodes) do
		local node = self.nodes[nodeId]
		if node then
			node.alloc = true
			if not self.allocNodes[nodeId] then
				self.allocNodes[nodeId] = node
				ConPrintf("Added Subgraph Node: " .. tostring(node.id))
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
		t_insert(subGraph.connectors, self.tree:BuildConnector(node1, node2))
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
			oidx = 0,
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

	-- Correct position to account for index of proxy node
	for _, node in pairs(indicies) do
		node.oidx = (node.oidx + proxyNode.oidx) % clusterJewel.totalIndicies
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
	return {
		classId = self.curClassId,
		ascendClassId = self.curAscendClassId,
		hashList = allocNodeIdList,
	}
end

function PassiveSpecClass:RestoreUndoState(state)
	self:ImportFromNodeList(state.classId, state.ascendClassId, state.hashList)
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
				mod.source = "Tree:"..node.id
				if type(mod.value) == "table" and mod.value.mod then
					mod.value.mod.source = mod.source
				end
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
