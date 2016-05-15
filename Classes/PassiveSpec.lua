-- Path of Building
--
-- Class: Passive Spec
-- Passive tree spec class.
--
local launch = ...

local pairs = pairs
local ipairs = ipairs
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local t_insert = table.insert

local SpecClass = common.NewClass("PassiveSpec", function(self, tree)
	self.tree = tree

	-- Make a local copy of the passive tree that we can modify
	self.nodes = { }
	for _, treeNode in ipairs(tree.nodes) do
		self.nodes[treeNode.id] = setmetatable({ 
			rsq = treeNode.overlay and treeNode.overlay.rsq,
			size = treeNode.overlay and treeNode.overlay.size,
			linked = { }
		}, { __index = treeNode })
	end
	for id, node in pairs(self.nodes) do
		for _, otherId in ipairs(node.linkedId) do
			t_insert(node.linked, self.nodes[otherId])
		end
	end

	self.allocNodes = { }

	self.undo = { }
	self.redo = { }

	self:SelectClass(0)
end)

function SpecClass:Load(xml, dbFileName)
	for _, node in pairs(xml) do
		if type(node) == "table" then
			if node.elem == "URL" then
				if type(node[1]) ~= "string" then
					launch:ShowErrMsg("^1Error parsing '%s': 'URL' element missing content", fileName)
					return true
				end
				self:DecodeURL(node[1])
				self.undo = { node[1] }
				self.redo = { }
			end
		end
	end
	self.modFlag = false
end

function SpecClass:Save(xml)
	t_insert(xml, {
		elem = "URL", 
		[1] = self:EncodeURL("https://www.pathofexile.com/passive-skill-tree/")
	})
	self.modFlag = false
end

function SpecClass:DecodeURL(url)
	self:ResetNodes()
	local b = common.base64.decode(url:gsub("^.+/",""):gsub("-","+"):gsub("_","/"))
	local ver = b:byte(4)
	local classId = b:byte(5)
	local ascendClassId = (ver >= 4) and b:byte(6) or 0
	self:SelectClass(classId)
	for i = (ver >= 4) and 8 or 7, #b-1, 2 do
		local id = b:byte(i) * 256 + b:byte(i + 1)
		local node = self.nodes[id]
		if node then
			node.alloc = true
			self.allocNodes[id] = node
			if ascendClassId == 0 and node.ascendancyName then
				ascendClassId = self.tree.ascendNameMap[node.ascendancyName].ascendClassId
			end
		end
	end
	self:SelectAscendClass(ascendClassId)
end

function SpecClass:EncodeURL(prefix)
	local a = { 0, 0, 0, 4, self.curClassId, self.curAscendClassId, 0 }
	for id, node in pairs(self.allocNodes) do
		if node.type ~= "class" and node.type ~= "ascendClass" then
			t_insert(a, m_floor(id / 256))
			t_insert(a, id % 256)
		end
	end
	return (prefix or "")..common.base64.encode(string.char(unpack(a))):gsub("+","-"):gsub("/","_")
end

function SpecClass:SelectClass(classId)
	if self.curClassId then
		local oldStartNodeId = self.tree.classes[self.curClassId].startNodeId
		self.nodes[oldStartNodeId].alloc = false
		self.allocNodes[oldStartNodeId] = nil
	end
	self.curClassId = classId
	local class = self.tree.classes[classId]
	self.curClassName = class.name
	local startNode = self.nodes[class.startNodeId]
	startNode.alloc = true
	self.allocNodes[startNode.id] = startNode
	self:SelectAscendClass(0)
end

function SpecClass:SelectAscendClass(ascendClassId)
	self.curAscendClassId = ascendClassId
	local ascendClass = self.tree.classes[self.curClassId].classes[tostring(ascendClassId)] or { name = "" }
	self.curAscendClassName = ascendClass.name
	for id, node in pairs(self.allocNodes) do
		if node.ascendancyName and node.ascendancyName ~= ascendClass.name then
			node.alloc = false
			self.allocNodes[id] = nil
		end
	end
	if ascendClass.startNodeId then
		local startNode = self.nodes[ascendClass.startNodeId]
		startNode.alloc = true
		self.allocNodes[startNode.id] = startNode
	end
	self:BuildAllDepends()
	self:BuildAllPaths()
end

function SpecClass:IsClassConnected(classId)
	for _, other in ipairs(self.nodes[self.tree.classes[classId].startNodeId].linked) do
		if other.alloc then
			other.visited = true
			local visited = { }
			local found = findStart(other, visited, true)
			for i, n in ipairs(visited) do
				n.visited = false
			end
			other.visited = false
			if found then
				return true
			end
		end
	end
	return false
end

function SpecClass:ResetNodes()
	for id, node in pairs(self.nodes) do
		if node.type ~= "class" and node.type ~= "ascendClass" then
			node.alloc = false
			self.allocNodes[id] = nil
		end
	end
end

function SpecClass:AllocNode(node, altPath)
	if not node.path then
		return
	end
	for _, pathNode in ipairs(altPath or node.path) do
		pathNode.alloc = true
		self.allocNodes[pathNode.id] = pathNode
		self:BuildPathFromNode(pathNode)
	end
	if node.isMultipleChoiceOption then
		local parent = node.linked[1]
		for _, optNode in ipairs(parent.linked) do
			if optNode.isMultipleChoiceOption and optNode.alloc and optNode ~= node then
				optNode.alloc = false
				self.allocNodes[optNode.id] = nil
				self:BuildAllPaths()
			end
		end
	end
	self:BuildAllDepends()
end

function SpecClass:DeallocNode(node)
	for _, depNode in ipairs(node.depends) do
		depNode.alloc = false
		self.allocNodes[depNode.id] = nil
	end
	self:BuildAllDepends()
	self:BuildAllPaths()
end

function SpecClass:CountAllocNodes()
	local used, ascUsed = 0, 0
	for _, node in pairs(self.allocNodes) do
		if node.type ~= "class" and node.type ~= "ascendClass" then
			if node.ascendancyName then
				if not node.isMultipleChoiceOption then
					ascUsed = ascUsed + 1
				end
			else
				used = used + 1
			end
		end
	end
	return used, ascUsed
end

function SpecClass:BuildPathFromNode(root)
	root.pathDist = 0
	root.path = { }
	local queue = { root }
	local o, i = 1, 2
	while o < i do
		local node = queue[o]
		o = o + 1
		local curDist = node.pathDist + 1
		for _, other in ipairs(node.linked) do
			if other.type ~= "class" and other.type ~= "ascendClass" and other.pathDist > curDist and (node.ascendancyName == other.ascendancyName or (curDist == 1 and not other.ascendancyName)) then
				other.pathDist = curDist
				other.path = wipeTable(other.path)
				other.path[1] = other
				for i, n in ipairs(node.path) do
					other.path[i+1] = n
				end
				queue[i] = other
				i = i + 1
			end
		end
	end
end

function SpecClass:BuildAllPaths()
	for id, node in pairs(self.nodes) do
		node.pathDist = node.alloc and 0 or 1000
		node.path = nil
	end
	for id, node in pairs(self.allocNodes) do
		self:BuildPathFromNode(node)
	end
end

function SpecClass:FindStartFromNode(node, visited, noAscend)
	node.visited = true
	t_insert(visited, node)
	for _, other in ipairs(node.linked) do
		if other.alloc and (other.type == "class" or other.type == "ascendClass" or (not other.visited and self:FindStartFromNode(other, visited, noAscend))) then
			if not noAscend or other.type ~= "ascendClass" then
				return true
			end
		end
	end
end

function SpecClass:BuildAllDepends()
	local visited = { }
	for id, node in pairs(self.nodes) do
		node.depends = wipeTable(node.depends)
		if node.alloc then
			node.depends[1] = node
			node.visited = true
			local anyStartFound = (node.type == "class" or node.type == "ascendClass")
			for _, other in ipairs(node.linked) do
				if other.alloc then
					if other.type == "class" or other.type == "ascendClass" then
						anyStartFound = true
					elseif self:FindStartFromNode(other, visited) then
						anyStartFound = true
						for i, n in ipairs(visited) do
							n.visited = false
							visited[i] = nil
						end
					else
						for i, n in ipairs(visited) do
							t_insert(node.depends, n)
							n.visited = false
							visited[i] = nil
						end
					end
				end
			end
			node.visited = false
			if not anyStartFound then
				for _, depNode in ipairs(node.depends) do
					depNode.alloc = false
					self.allocNodes[depNode.id] = nil
				end
			end
		end
	end
end

function SpecClass:AddUndoState(noClearRedo)
	t_insert(self.undo, 1, self:EncodeURL())
	self.undo[102] = nil
	self.modFlag = true
	self.buildFlag = true
	if not noClearRedo then
		self.redo = { }
	end
end

function SpecClass:Undo()
	if self.undo[2] then
		t_insert(self.redo, 1, table.remove(self.undo, 1))
		self:DecodeURL(table.remove(self.undo, 1))
		self:AddUndoState(true)
	end
end

function SpecClass:Redo()
	if self.redo[1] then
		self:DecodeURL(table.remove(self.redo, 1))
		self:AddUndoState(true)
	end
end
