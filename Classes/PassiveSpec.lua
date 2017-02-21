-- Path of Building
--
-- Class: Passive Spec
-- Passive tree spec class.
-- Manages node allocation and pathing for a given passive spec
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local PassiveSpecClass = common.NewClass("PassiveSpec", "UndoHandler", function(self, build)
	self.UndoHandler()

	self.build = build
	self.tree = build.tree

	-- Make a local copy of the passive tree that we can modify
	self.nodes = { }
	for _, treeNode in ipairs(self.tree.nodes) do
		self.nodes[treeNode.id] = setmetatable({ 
			linked = { },
			power = { }
		}, treeNode.meta)
	end
	for id, node in pairs(self.nodes) do
		for _, otherId in ipairs(node.linkedId) do
			t_insert(node.linked, self.nodes[otherId])
		end
	end

	-- List of currently allocated nodes
	-- Keys are node IDs, values are nodes
	self.allocNodes = { }

	-- Table of jewels equipped in this tree
	-- Keys are node IDs, values are items
	self.jewels = { }

	self:SelectClass(0)
end)

function PassiveSpecClass:Load(xml, dbFileName)
	local url
	self.title = xml.attrib.title
	for _, node in pairs(xml) do
		if type(node) == "table" then
			if node.elem == "URL" then
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
	if url then
		self:DecodeURL(url)
	end
	self:ResetUndo()
end

function PassiveSpecClass:Save(xml)
	xml.attrib = { 
		title = self.title,
	}
	t_insert(xml, {
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

-- Import passive spec from the provided class IDs and node hash list
function PassiveSpecClass:ImportFromNodeList(classId, ascendClassId, hashList)
	self:ResetNodes()
	self:SelectClass(classId)
	for _, id in pairs(hashList) do
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
		end
	end
	self:SelectAscendClass(ascendClassId)
end

-- Decode the given passive tree URL
-- Supports both the official skill tree links as well as PoE Planner links
function PassiveSpecClass:DecodeURL(url)
	local b = common.base64.decode(url:gsub("^.+/",""):gsub("-","+"):gsub("_","/"))
	if not b or #b < 6 then
		return "Invalid tree link (unrecognised format)"
	end
	local classId, ascendClassId, bandits, nodes
	if b:byte(1) == 0 and b:byte(2) == 2 then
		-- Hold on to your headgear, it looks like a PoE Planner link
		-- Let's grab a scalpel and start peeling back the 50 layers of base 64 encoding
		local treeLinkLen = b:byte(4) * 256 + b:byte(5)
		local treeLink = b:sub(6, 6 + treeLinkLen - 1)
		b = common.base64.decode(treeLink:gsub("^.+/",""):gsub("-","+"):gsub("_","/"))
		classId = b:byte(3)
		ascendClassId = b:byte(4)
		bandits = b:byte(5)
		nodes = b:sub(8, -1)
	elseif b:byte(1) == 0 and b:byte(2) == 4 then
		-- PoE Planner version 4
		-- Now with 50% fewer layers of base 64 encoding
		classId = b:byte(6) % 16
		ascendClassId = m_floor(b:byte(6) / 16)
		bandits = b:byte(7)
		local numNodes = b:byte(8) * 256 + b:byte(9)
		nodes = b:sub(10, 10 + numNodes * 2 - 1)
	else
		local ver = b:byte(1) * 16777216 + b:byte(2) * 65536 + b:byte(3) * 256 + b:byte(4)
		if ver > 4 then
			return "Invalid tree link (unknown version number '"..ver.."')"
		end
		classId = b:byte(5)	
		ascendClassId = 0--(ver >= 4) and b:byte(6) or 0   -- This value would be reliable if the developer of a certain online skill tree planner *cough* PoE Planner *cough* hadn't bollocked up
														   -- the generation of the official tree URL. The user would most likely import the PoE Planner URL instead but that can't be relied upon.
		nodes = b:sub(ver >= 4 and 8 or 7, -1)
	end	
	if not self.tree.classes[classId] then
		return "Invalid tree link (bad class ID '"..classId.."')"
	end
	self:ResetNodes()
	self:SelectClass(classId)
	for i = 1, #nodes - 1, 2 do
		local id = nodes:byte(i) * 256 + nodes:byte(i + 1)
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
			if ascendClassId == 0 and node.ascendancyName then
				-- Just guess the ascendancy class based on the allocated nodes
				ascendClassId = self.tree.ascendNameMap[node.ascendancyName].ascendClassId
			end
		end
	end
	self:SelectAscendClass(ascendClassId)
	if bandits then
		-- Decode bandits from PoEPlanner
		local lookup = { [0] = "None", "Alira", "Kraityn", "Oak" }
		self.build.banditNormal = lookup[bandits % 4]
		self.build.banditCruel = lookup[m_floor(bandits / 4) % 4]
		self.build.banditMerciless = lookup[m_floor(bandits / 16) % 4]
	end
end

-- Encodes the current spec into a URL, using the official skill tree's format
-- Prepends the URL with an optional prefix
function PassiveSpecClass:EncodeURL(prefix)
	local a = { 0, 0, 0, 4, self.curClassId, self.curAscendClassId, 0 }
	for id, node in pairs(self.allocNodes) do
		if node.type ~= "classStart" and node.type ~= "ascendClassStart" then
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
	-- This will also rebuild the node paths and dependancies
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

	-- Rebuild all the node paths and dependancies
	self:BuildAllDependsAndPaths()
end

-- Determines if the given class's start node is connected to the current class's start node
-- Attempts to find a path between the nodes which doesn't pass through any ascendancy nodes (i.e Ascendant)
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
				-- Found a path, so the given class's start node is definately connected to the current class's start node
				-- There might still be nodes which are connected to the current tree by an entirely different path though
				-- E.g via Ascendant or by connecting to another "first passive node"
				return true
			end
		end
	end
	return false
end

-- Clear the allocated status of all non-class-start nodes
function PassiveSpecClass:ResetNodes()
	for id, node in pairs(self.nodes) do
		if node.type ~= "classStart" and node.type ~= "ascendClassStart" then
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
	if node.dependsOnIntuitiveLeap then
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

	-- Rebuild all dependancies and paths for all allocated nodes
	self:BuildAllDependsAndPaths()
end

-- Deallocate the given node, and all nodes which depend on it (i.e which are only connected to the tree through this node)
function PassiveSpecClass:DeallocNode(node)
	for _, depNode in ipairs(node.depends) do
		depNode.alloc = false
		self.allocNodes[depNode.id] = nil
	end

	-- Rebuild all paths and dependancies for all allocated nodes
	self:BuildAllDependsAndPaths()
end

-- Count the number of allocated nodes and allocated ascendancy nodes
function PassiveSpecClass:CountAllocNodes()
	local used, ascUsed, sockets = 0, 0, 0
	for _, node in pairs(self.allocNodes) do
		if node.type ~= "classStart" and node.type ~= "ascendClassStart" then
			if node.ascendancyName then
				if not node.isMultipleChoiceOption then
					ascUsed = ascUsed + 1
				end
			else
				used = used + 1
			end
			if node.type == "socket" then
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
		if other.alloc and (other.type == "classStart" or other.type == "ascendClassStart" or (not other.visited and self:FindStartFromNode(other, visited, noAscend))) then
			if not noAscend or other.type ~= "ascendClassStart" then
				return true
			end
		end
	end
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
			if other.type ~= "classStart" and other.type ~= "ascendClassStart" and other.pathDist > curDist and (node.ascendancyName == other.ascendancyName or (curDist == 1 and not other.ascendancyName)) then
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

-- Rebuilds dependancies and paths for all nodes
function PassiveSpecClass:BuildAllDependsAndPaths()
	-- This table will keep track of which nodes have been visited during each path-finding attempt
	local visited = { }

	-- Check all nodes for other nodes which depend on them (i.e are only connected to the tree through that node)
	for id, node in pairs(self.nodes) do
		node.depends = wipeTable(node.depends)
		node.dependsOnIntuitiveLeap = false
		if node.type ~= "classStart" then
			for nodeId, itemId in pairs(self.jewels) do
				if self.allocNodes[nodeId] and self.nodes[nodeId].nodesInRadius[1][node.id] then
					if itemId ~= 0 and self.build.itemsTab.list[itemId] and self.build.itemsTab.list[itemId].jewelData and self.build.itemsTab.list[itemId].jewelData.intuitiveLeap then
						-- This node depends on Intuitive Leap
						-- This flag:
						-- 1. Prevents generation of paths from this node
						-- 2. Prevents this node from being deallocted via dependancy
						-- 3. Prevents allocation of path nodes when this node is being allocated
						node.dependsOnIntuitiveLeap = true
						break
					end
				end
			end
		end
		if node.alloc then
			node.depends[1] = node -- All nodes depend on themselves
		end
	end
	for id, node in pairs(self.allocNodes) do
		node.visited = true

		local anyStartFound = (node.type == "classStart" or node.type == "ascendClassStart")
		for _, other in ipairs(node.linked) do
			if other.alloc and not isValueInArray(node.depends, other) then
				-- The other node is allocated and isn't already dependant on this node, so try and find a path to a start node through it
				if other.type == "classStart" or other.type == "ascendClassStart" then
					-- Well that was easy!
					anyStartFound = true
				elseif self:FindStartFromNode(other, visited) then
					-- We found a path through the other node, therefore the other node cannot be dependant on this node
					anyStartFound = true
					for i, n in ipairs(visited) do
						n.visited = false
						visited[i] = nil
					end
				else
					-- No path was found, so all the nodes visited while trying to find the path must be dependant on this node
					for i, n in ipairs(visited) do
						if not n.dependsOnIntuitiveLeap then
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
					if self.allocNodes[nodeId] and self.nodes[nodeId].nodesInRadius[1][depNode.id] then
						if itemId ~= 0 and (not self.build.itemsTab.list[itemId] or (self.build.itemsTab.list[itemId].jewelData and self.build.itemsTab.list[itemId].jewelData.intuitiveLeap)) then
							-- Hold off on the pruning; this node is within the radius of a jewel that is or could be Intuitive Leap
							prune = false
							t_insert(self.nodes[nodeId].depends, depNode)
							break
						end
					end
				end
				if prune then
					depNode.alloc = false
					self.allocNodes[depNode.id] = nil
				end
			end
		end
	end

	-- Reset and rebuild all node paths
	for id, node in pairs(self.nodes) do
		node.pathDist = (node.alloc and not node.dependsOnIntuitiveLeap) and 0 or 1000
		node.path = nil
	end
	for id, node in pairs(self.allocNodes) do
		if not node.dependsOnIntuitiveLeap then
			self:BuildPathFromNode(node)
		end
	end
end

function PassiveSpecClass:CreateUndoState()
	return self:EncodeURL()
end

function PassiveSpecClass:RestoreUndoState(state)
	self:DecodeURL(state)
end
