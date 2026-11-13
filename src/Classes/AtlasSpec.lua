local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort
local t_concat = table.concat
local m_floor = math.floor
local s_char = string.char

local defaultUrlPrefix = "https://www.pathofexile.com/fullscreen-atlas-skill-tree/"

local AtlasSpecClass = newClass("AtlasSpec", "UndoHandler")

function AtlasSpecClass:AtlasSpec(key, title)
	self:UndoHandler()
	self.title = title or "Default"
	self:ApplyState(key, { }, { })
	self:ResetUndo()
	return self
end

function AtlasSpecClass:GetAllocatedIds()
	local ids = { }
	for id, node in pairs(self.allocNodes) do
		if node.type ~= "Root" then
			t_insert(ids, id)
		end
	end
	t_sort(ids)
	return ids
end

function AtlasSpecClass:ApplyState(key, ids, variants)
	self.tree = main:LoadAtlasTree(key)
	self.treeVersion = self.tree.key
	self.allocNodes = { }
	for _, node in ipairs(self.tree.startNodes) do
		self.allocNodes[node.id] = node
	end
	local dropped = 0
	for _, id in ipairs(ids) do
		local node = self.tree.nodes[id]
		if node and node.type ~= "Mastery" and node.type ~= "Root" then
			self.allocNodes[id] = node
		elseif not node then
			dropped = dropped + 1
		end
	end
	local before = #self:GetAllocatedIds()
	self:PruneDisconnected()
	dropped = dropped + before - #self:GetAllocatedIds()
	self.variantSelections = { }
	for nodeId, effect in pairs(variants) do
		self:SetVariant(nodeId, effect)
	end
	self:Invalidate()
	return dropped
end

function AtlasSpecClass:Invalidate()
	self.statSummary = nil
	self.revision = (self.revision or 0) + 1
end

function AtlasSpecClass:FindConnected(excluded)
	local reached = { }
	local queue = { }
	for _, node in ipairs(self.tree.startNodes) do
		if node ~= excluded then
			reached[node] = true
			t_insert(queue, node)
		end
	end
	local index = 1
	while queue[index] do
		local node = queue[index]
		index = index + 1
		for _, other in ipairs(node.linked) do
			if not reached[other] and other ~= excluded and self.allocNodes[other.id] then
				reached[other] = true
				t_insert(queue, other)
			end
		end
	end
	return reached
end

function AtlasSpecClass:PruneDisconnected()
	local reached = self:FindConnected()
	for id, node in pairs(self.allocNodes) do
		if not reached[node] then
			self.allocNodes[id] = nil
			self.variantSelections[id] = nil
		end
	end
end

function AtlasSpecClass:GetPathToNode(target)
	if not target or self.allocNodes[target.id] or target.type == "Mastery" or target.type == "Root" then
		return { }
	end
	local previous = { }
	local queue = { }
	for _, node in pairs(self.allocNodes) do
		previous[node] = false
		t_insert(queue, node)
	end
	local index = 1
	while queue[index] and previous[target] == nil do
		local node = queue[index]
		index = index + 1
		for _, other in ipairs(node.linked) do
			if previous[other] == nil and other.type ~= "Mastery" then
				previous[other] = node
				t_insert(queue, other)
			end
		end
	end
	if previous[target] == nil then
		return { }
	end
	local reversed = { }
	local node = target
	while node and not self.allocNodes[node.id] do
		t_insert(reversed, node)
		node = previous[node]
	end
	local path = { }
	for i = #reversed, 1, -1 do
		t_insert(path, reversed[i])
	end
	return path
end

function AtlasSpecClass:AllocNode(node)
	local path = self:GetPathToNode(node)
	for _, pathNode in ipairs(path) do
		self.allocNodes[pathNode.id] = pathNode
	end
	if #path > 0 then
		self:Invalidate()
	end
	return #path > 0
end

function AtlasSpecClass:GetDependents(node)
	if not node or not self.allocNodes[node.id] or node.type == "Root" then
		return { }
	end
	local reached = self:FindConnected(node)
	local dependents = { }
	for _, allocated in pairs(self.allocNodes) do
		if not reached[allocated] then
			t_insert(dependents, allocated)
		end
	end
	return dependents
end

function AtlasSpecClass:DeallocNode(node)
	local dependents = self:GetDependents(node)
	for _, dependent in ipairs(dependents) do
		self.allocNodes[dependent.id] = nil
		self.variantSelections[dependent.id] = nil
	end
	if #dependents > 0 then
		self:Invalidate()
	end
end

function AtlasSpecClass:ResetNodes()
	self:ApplyState(self.treeVersion, { }, { })
end

function AtlasSpecClass:CountAllocNodes()
	return #self:GetAllocatedIds()
end

function AtlasSpecClass:SetVariant(nodeId, effect)
	local node = self.allocNodes[nodeId]
	if not node or not node.variants then
		return false
	end
	for _, variant in ipairs(node.variants) do
		if variant.effect == effect then
			self.variantSelections[nodeId] = effect
			self:Invalidate()
			return true
		end
	end
	return false
end

function AtlasSpecClass:GetSelectedVariant(node)
	local effect = self.variantSelections[node.id]
	for _, variant in ipairs(node.variants or { }) do
		if variant.effect == effect then
			return variant
		end
	end
end

function AtlasSpecClass:SetTreeVersion(key)
	return self:ApplyState(key, self:GetAllocatedIds(), self.variantSelections)
end

function AtlasSpecClass:CreateUndoState()
	local variants = { }
	for nodeId, effect in pairs(self.variantSelections) do
		variants[nodeId] = effect
	end
	return { treeVersion = self.treeVersion, nodes = self:GetAllocatedIds(), variants = variants, title = self.title }
end

function AtlasSpecClass:RestoreUndoState(state)
	self.title = state.title
	self:ApplyState(state.treeVersion, state.nodes, state.variants)
end

function AtlasSpecClass:Load(xml)
	self.title = xml.attrib.title or "Default"
	local ids = { }
	for id in (xml.attrib.nodes or ""):gmatch("%d+") do
		t_insert(ids, tonumber(id))
	end
	local variants = { }
	for _, child in ipairs(xml) do
		if type(child) == "table" and child.elem == "Variant" then
			local nodeId, effect = tonumber(child.attrib.nodeId), tonumber(child.attrib.effect)
			if nodeId and effect then
				variants[nodeId] = effect
			end
		end
	end
	self:ApplyState(xml.attrib.treeVersion, ids, variants)
	self:ResetUndo()
	self.modFlag = false
end

function AtlasSpecClass:Save(xml)
	local ids = { }
	for _, id in ipairs(self:GetAllocatedIds()) do
		t_insert(ids, tostring(id))
	end
	xml.attrib = {
		title = self.title,
		treeVersion = self.treeVersion,
		nodes = t_concat(ids, ","),
	}
	local variantIds = { }
	for nodeId in pairs(self.variantSelections) do
		t_insert(variantIds, nodeId)
	end
	t_sort(variantIds)
	for _, nodeId in ipairs(variantIds) do
		t_insert(xml, { elem = "Variant", attrib = { nodeId = tostring(nodeId), effect = tostring(self.variantSelections[nodeId]) } })
	end
end

function AtlasSpecClass:EncodeURL(prefix)
	local bytes = { 0, 0, 0, 6, 0, 0 }
	local ids = { }
	for _, id in ipairs(self:GetAllocatedIds()) do
		if id < 65536 and #ids < 255 then
			t_insert(ids, id)
		end
	end
	t_insert(bytes, #ids)
	for _, id in ipairs(ids) do
		t_insert(bytes, m_floor(id / 256))
		t_insert(bytes, id % 256)
	end
	t_insert(bytes, 0)
	local variantIds = { }
	for nodeId in pairs(self.variantSelections) do
		t_insert(variantIds, nodeId)
	end
	t_sort(variantIds)
	t_insert(bytes, #variantIds)
	for _, nodeId in ipairs(variantIds) do
		local effect = self.variantSelections[nodeId]
		t_insert(bytes, m_floor(effect / 256))
		t_insert(bytes, effect % 256)
		t_insert(bytes, m_floor(nodeId / 256))
		t_insert(bytes, nodeId % 256)
	end
	local chars = { }
	for i, byte in ipairs(bytes) do
		chars[i] = s_char(byte)
	end
	return (prefix or defaultUrlPrefix) .. common.base64.encode(t_concat(chars)):gsub("+", "-"):gsub("/", "_")
end

function AtlasSpecClass:DecodeURL(text)
	local payload = (text or ""):gsub("%s", ""):gsub("[?#].*$", ""):gsub("/+$", ""):match("([^/]+)$")
	if not payload then
		return false, "Invalid atlas tree link"
	end
	local ok, b = pcall(common.base64.decode, (payload:gsub("-", "+"):gsub("_", "/")))
	if not ok or not b or #b < 7 then
		return false, "Invalid atlas tree link (unrecognised format)"
	end
	local version = b:byte(1) * 16777216 + b:byte(2) * 65536 + b:byte(3) * 256 + b:byte(4)
	if version < 4 or version > 6 then
		return false, "Invalid atlas tree link (unknown version number '" .. version .. "')"
	end
	local ids = { }
	local nodeCount = b:byte(7)
	local nodesEnd = 7 + nodeCount * 2
	if #b < nodesEnd then
		return false, "Invalid atlas tree link (truncated)"
	end
	for i = 8, nodesEnd, 2 do
		t_insert(ids, b:byte(i) * 256 + b:byte(i + 1))
	end
	local variants = { }
	if version >= 6 and #b > nodesEnd then
		local clusterCount = b:byte(nodesEnd + 1) or 0
		local pairStart = nodesEnd + 2 + clusterCount * 2
		local pairCount = b:byte(pairStart) or 0
		for i = pairStart + 1, pairStart + pairCount * 4, 4 do
			if b:byte(i + 3) then
				variants[b:byte(i + 2) * 256 + b:byte(i + 3)] = b:byte(i) * 256 + b:byte(i + 1)
			end
		end
	end
	self:ApplyState(self.treeVersion, ids, variants)
	return true
end

local function statTemplate(line)
	local numbers = { }
	local template = line:gsub("%-?%d+%.?%d*", function(number)
		t_insert(numbers, tonumber(number))
		return "#"
	end)
	return template, numbers
end

local function formatNumber(value)
	if value == m_floor(value) then
		return string.format("%d", value)
	end
	return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""))
end

function AtlasSpecClass:GetMasteryCategories()
	local tree = self.tree
	if tree.masteryCategories then
		return tree.masteryCategories
	end
	local names = { }
	local seen = { }
	for _, mastery in ipairs(tree.masteries) do
		if mastery.dn ~= "" and mastery.dn ~= "Maps" and not seen[mastery.dn] then
			seen[mastery.dn] = true
			local lower = mastery.dn:lower()
			local stem = lower:match("^(.-)s$") or lower
			t_insert(names, { name = mastery.dn, pattern = stem:gsub("(%p)", "%%%1") })
		end
	end
	t_sort(names, function(a, b)
		return #a.name > #b.name
	end)
	tree.masteryCategories = names
	return names
end

function AtlasSpecClass:CategoriseLine(text)
	local lower = " " .. text:lower() .. " "
	for _, category in ipairs(self:GetMasteryCategories()) do
		if lower:find("[^%w]" .. category.pattern .. "s?[^%w]") then
			return category.name
		end
	end
	return "Misc"
end

function AtlasSpecClass:GetStatSummary()
	if self.statSummary then
		return self.statSummary
	end
	local entries = { }
	local order = { }
	local function addLine(line, node)
		local template, numbers = statTemplate(line)
		local entry = entries[template]
		if not entry then
			entry = { template = template, numbers = { }, nodes = { } }
			entries[template] = entry
			t_insert(order, entry)
		end
		for i, number in ipairs(numbers) do
			entry.numbers[i] = (entry.numbers[i] or 0) + number
		end
		t_insert(entry.nodes, node)
	end
	for _, id in ipairs(self:GetAllocatedIds()) do
		local node = self.allocNodes[id]
		local lines = node.sd
		if node.variants then
			local variant = self:GetSelectedVariant(node)
			lines = variant and variant.sd or { }
		end
		for _, line in ipairs(lines) do
			if line:match("%S") then
				addLine(line, node)
			end
		end
	end
	local categories = { }
	local categoryMap = { }
	for _, entry in ipairs(order) do
		local index = 0
		local text = entry.template:gsub("#", function()
			index = index + 1
			return formatNumber(entry.numbers[index] or 0)
		end)
		local name = self:CategoriseLine(text)
		local category = categoryMap[name]
		if not category then
			category = { category = name, lines = { } }
			categoryMap[name] = category
			t_insert(categories, category)
		end
		t_insert(category.lines, { text = text, nodes = entry.nodes })
	end
	t_sort(categories, function(a, b)
		if a.category == "Misc" or b.category == "Misc" then
			return b.category == "Misc" and a.category ~= "Misc"
		end
		return a.category < b.category
	end)
	for _, category in ipairs(categories) do
		t_sort(category.lines, function(a, b)
			return a.text < b.text
		end)
	end
	self.statSummary = categories
	return categories
end
