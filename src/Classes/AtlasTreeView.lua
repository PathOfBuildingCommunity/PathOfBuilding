local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local m_abs = math.abs
local m_sin = math.sin
local m_cos = math.cos
local m_sqrt = math.sqrt
local m_ceil = math.ceil

local nodeSpriteTypes = {
	Normal = "normal",
	Notable = "notable",
	Keystone = "keystone",
	Wormhole = "wormhole",
}

local frameNames = {
	Normal = { alloc = "PSSkillFrameActive", path = "PSSkillFrameHighlighted", unalloc = "PSSkillFrame" },
	Notable = { alloc = "NotableFrameAllocated", path = "NotableFrameCanAllocate", unalloc = "NotableFrameUnallocated" },
	Keystone = { alloc = "KeystoneFrameAllocated", path = "KeystoneFrameCanAllocate", unalloc = "KeystoneFrameUnallocated" },
	Wormhole = { alloc = "WormholeFrameAllocated", path = "WormholeFrameCanAllocate", unalloc = "WormholeFrameUnallocated", highlight = "WormholeFrameHighlight" },
}

local connectorColors = {
	Normal = { 0.32, 0.30, 0.27 },
	Intermediate = { 0.55, 0.85, 1.0 },
	Active = { 0.95, 0.80, 0.45 },
	Remove = { 0.9, 0.2, 0.2 },
}

local AtlasTreeViewClass = newClass("AtlasTreeView")

function AtlasTreeViewClass:AtlasTreeView()
	self.ring = NewImageHandle()
	self.ring:Load("Assets/small_ring.png", "CLAMP")
	self.tooltip = new("Tooltip"):Tooltip()
	self.zoomLevel = 0
	self.zoom = 1
	self.zoomX = 0
	self.zoomY = 0
	self.searchStr = ""
	return self
end

function AtlasTreeViewClass:UpdateTransform(tree, viewPort)
	self.scale = m_min(viewPort.width, viewPort.height) / tree.size * self.zoom
	self.offsetX = self.zoomX + viewPort.x + viewPort.width / 2
	self.offsetY = self.zoomY + viewPort.y + viewPort.height / 2
	self.centerX = tree.centerX
	self.centerY = tree.centerY
end

function AtlasTreeViewClass:TreeToScreen(x, y)
	return (x - self.centerX) * self.scale + self.offsetX, (y - self.centerY) * self.scale + self.offsetY
end

function AtlasTreeViewClass:ScreenToTree(x, y)
	return (x - self.offsetX) / self.scale + self.centerX, (y - self.offsetY) / self.scale + self.centerY
end

function AtlasTreeViewClass:GetNodeAt(spec, treeX, treeY)
	local mastery
	for _, node in pairs(spec.tree.nodes) do
		if node.x and node.id ~= 0 then
			local dx, dy = treeX - node.x, treeY - node.y
			if dx * dx + dy * dy <= node.rsq then
				if node.type ~= "Mastery" then
					return node
				end
				mastery = mastery or node
			end
		end
	end
	return mastery
end

function AtlasTreeViewClass:Zoom(level, viewPort)
	self.zoomLevel = m_max(0, m_min(14, self.zoomLevel + level))
	local oldZoom = self.zoom
	self.zoom = 1.2 ^ self.zoomLevel
	local factor = self.zoom / oldZoom
	local cursorX, cursorY = GetCursorPos()
	local relX = cursorX - viewPort.x - viewPort.width / 2
	local relY = cursorY - viewPort.y - viewPort.height / 2
	self.zoomX = relX + (self.zoomX - relX) * factor
	self.zoomY = relY + (self.zoomY - relY) * factor
end

function AtlasTreeViewClass:Focus(spec, node, viewPort)
	self.zoomLevel = 10
	self.zoom = 1.2 ^ self.zoomLevel
	local scale = m_min(viewPort.width, viewPort.height) / spec.tree.size * self.zoom
	self.zoomX = -(node.x - spec.tree.centerX) * scale
	self.zoomY = -(node.y - spec.tree.centerY) * scale
end

function AtlasTreeViewClass:DrawSprite(sprite, x, y, scale, isHalf)
	if not sprite or not sprite.handle then
		return
	end
	local width = sprite.width * scale * 1.33
	local height = sprite.height * scale * 1.33
	if isHalf then
		DrawImage(sprite.handle, x - width, y - height * 2, width * 2, height * 2, sprite[1], sprite[2], sprite[3], sprite[4])
		DrawImage(sprite.handle, x - width, y, width * 2, height * 2, sprite[1], sprite[4], sprite[3], sprite[2])
	else
		DrawImage(sprite.handle, x - width, y - height, width * 2, height * 2, sprite[1], sprite[2], sprite[3], sprite[4])
	end
end

function AtlasTreeViewClass:DrawLine(x1, y1, x2, y2, thickness)
	local dx, dy = x2 - x1, y2 - y1
	local length = m_sqrt(dx * dx + dy * dy)
	if length == 0 then
		return
	end
	local nx, ny = -dy / length * thickness, dx / length * thickness
	DrawImageQuad(nil, x1 + nx, y1 + ny, x2 + nx, y2 + ny, x2 - nx, y2 - ny, x1 - nx, y1 - ny)
end

function AtlasTreeViewClass:DrawConnector(connector, thickness)
	if connector.arc then
		local arc = connector.arc
		local steps = m_max(2, m_ceil(m_abs(arc.sweep) * arc.radius * self.scale / 6))
		local prevX, prevY
		for i = 0, steps do
			local angle = arc.startAngle + arc.sweep * i / steps
			local x, y = self:TreeToScreen(arc.x + m_sin(angle) * arc.radius, arc.y - m_cos(angle) * arc.radius)
			if prevX then
				self:DrawLine(prevX, prevY, x, y, thickness)
			end
			prevX, prevY = x, y
		end
	else
		local x1, y1 = self:TreeToScreen(connector.node1.x, connector.node1.y)
		local x2, y2 = self:TreeToScreen(connector.node2.x, connector.node2.y)
		self:DrawLine(x1, y1, x2, y2, thickness)
	end
end

function AtlasTreeViewClass:Draw(spec, viewPort, inputEvents, onNodeClick, highlightNodes)
	local tree = spec.tree
	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= viewPort.x and cursorX < viewPort.x + viewPort.width and cursorY >= viewPort.y and cursorY < viewPort.y + viewPort.height and not main.popups[1]

	local treeClick
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "LEFTBUTTON" and mOver then
				self.dragX, self.dragY = cursorX, cursorY
			elseif event.key == "PAGEUP" then
				self:Zoom(IsKeyDown("SHIFT") and 3 or 1, viewPort)
			elseif event.key == "PAGEDOWN" then
				self:Zoom(IsKeyDown("SHIFT") and -3 or -1, viewPort)
			end
		elseif event.type == "KeyUp" then
			if event.key == "LEFTBUTTON" then
				if self.dragX and not self.dragging then
					treeClick = true
				end
			elseif mOver then
				if event.key == "WHEELUP" then
					self:Zoom(IsKeyDown("SHIFT") and 3 or 1, viewPort)
				elseif event.key == "WHEELDOWN" then
					self:Zoom(IsKeyDown("SHIFT") and -3 or -1, viewPort)
				end
			end
		end
	end

	if not IsKeyDown("LEFTBUTTON") then
		self.dragging = false
		self.dragX, self.dragY = nil, nil
	end
	if self.dragX then
		if not self.dragging and (m_abs(cursorX - self.dragX) > 5 or m_abs(cursorY - self.dragY) > 5) then
			self.dragging = true
		end
		if self.dragging then
			self.zoomX = self.zoomX + cursorX - self.dragX
			self.zoomY = self.zoomY + cursorY - self.dragY
			self.dragX, self.dragY = cursorX, cursorY
		end
	end

	local clampFactor = self.zoom * 2 / 3
	self.zoomX = m_min(m_max(self.zoomX, -viewPort.width * clampFactor), viewPort.width * clampFactor)
	self.zoomY = m_min(m_max(self.zoomY, -viewPort.height * clampFactor), viewPort.height * clampFactor)
	self:UpdateTransform(tree, viewPort)
	local scale = self.scale

	local hoverNode
	if mOver then
		hoverNode = self:GetNodeAt(spec, self:ScreenToTree(cursorX, cursorY))
	end
	self.hoverNode = hoverNode

	if hoverNode ~= self.cachedHoverNode or spec.revision ~= self.cachedRevision or spec ~= self.cachedSpec then
		self.cachedHoverNode = hoverNode
		self.cachedRevision = spec.revision
		self.cachedSpec = spec
		self.hoverPath = { }
		self.hoverRemove = { }
		self.hoverPartners = { }
		if hoverNode then
			if spec.allocNodes[hoverNode.id] then
				for _, node in ipairs(spec:GetDependents(hoverNode)) do
					self.hoverRemove[node] = true
				end
			else
				for _, node in ipairs(spec:GetPathToNode(hoverNode)) do
					self.hoverPath[node] = true
				end
			end
			local sameName = tree:GetNodesWithSameName(hoverNode)
			if #sameName > 1 then
				for _, node in ipairs(sameName) do
					if node ~= hoverNode then
						self.hoverPartners[node] = true
					end
				end
			end
		end
	end
	local hoverPath, hoverRemove, hoverPartners = self.hoverPath, self.hoverRemove, self.hoverPartners

	if treeClick and hoverNode and onNodeClick then
		onNodeClick(hoverNode)
	end

	SetDrawLayer(nil, 0)
	SetDrawColor(1, 1, 1)
	local background = tree.assets.AtlasPassiveBackground
	if background and background.handle then
		local size = m_max(tree.max_x - tree.min_x, tree.max_y - tree.min_y) * 1.15 * scale
		local cx, cy = self:TreeToScreen(tree.centerX, tree.centerY)
		DrawImage(background.handle, cx - size / 2, cy - size / 2, size, size, background[1], background[2], background[3], background[4])
	else
		SetDrawColor(0.03, 0.04, 0.06)
		DrawImage(nil, viewPort.x, viewPort.y, viewPort.width, viewPort.height)
	end

	SetDrawColor(1, 1, 1)
	for _, group in pairs(tree.groups) do
		local scrX, scrY = self:TreeToScreen(group.x, group.y)
		if group.background then
			local sprite = tree.assets[group.background.image]
			local offsetX = (group.background.offsetX or 0) * scale
			local offsetY = (group.background.offsetY or 0) * scale
			self:DrawSprite(sprite, scrX + offsetX, scrY + offsetY, scale, group.background.isHalfImage)
		end
	end

	SetDrawLayer(nil, 10)
	local thickness = m_max(1, 5 * scale)
	for _, connector in ipairs(tree.connectors) do
		local node1, node2 = connector.node1, connector.node2
		local alloc1, alloc2 = spec.allocNodes[node1.id], spec.allocNodes[node2.id]
		local state = "Normal"
		if (hoverRemove[node1] and alloc2) or (hoverRemove[node2] and alloc1) then
			state = "Remove"
		elseif alloc1 and alloc2 then
			state = "Active"
		elseif (alloc1 or hoverPath[node1]) and (alloc2 or hoverPath[node2]) then
			state = "Intermediate"
		end
		local color = connectorColors[state]
		SetDrawColor(color[1], color[2], color[3])
		self:DrawConnector(connector, state == "Normal" and thickness or thickness * 1.4)
	end

	local searchLower = self.searchStr:lower()
	local searching = searchLower:match("%S") ~= nil

	SetDrawLayer(nil, 20)
	for _, node in pairs(tree.nodes) do
		if node.x and node.id ~= 0 then
			local scrX, scrY = self:TreeToScreen(node.x, node.y)
			if scrX > viewPort.x - 100 and scrX < viewPort.x + viewPort.width + 100 and scrY > viewPort.y - 100 and scrY < viewPort.y + viewPort.height + 100 then
				local isAlloc = spec.allocNodes[node.id] ~= nil
				local state = isAlloc and "alloc" or (hoverPath[node] and "path" or "unalloc")
				if hoverRemove[node] then
					SetDrawColor(1, 0.4, 0.4)
				else
					SetDrawColor(1, 1, 1)
				end
				if node.type == "Root" then
					self:DrawSprite(tree.assets.AtlasPassiveSkillScreenStart, scrX, scrY, scale)
				elseif node.type == "Mastery" then
					local sprites = node.sprites
					self:DrawSprite(sprites and (sprites.mastery or sprites.masteryActive), scrX, scrY, scale)
				else
					local prefix = nodeSpriteTypes[node.type]
					local sprites = node.sprites
					if sprites then
						local icon = isAlloc and (sprites[prefix .. "Active"] or sprites.normalActive) or (sprites[prefix .. "Inactive"] or sprites.normalInactive)
						self:DrawSprite(icon, scrX, scrY, scale)
					end
					local frames = frameNames[node.type]
					local frameName = frames[state]
					if hoverPartners[node] and frames.highlight then
						frameName = frames.highlight
					end
					self:DrawSprite(tree.assets[frameName], scrX, scrY, scale)
				end
				local ringSize
				if hoverPartners[node] then
					SetDrawColor(0.4, 0.9, 1)
					ringSize = node.size * scale * 0.9
				elseif highlightNodes and highlightNodes[node] then
					SetDrawColor(1, 1, 0.3)
					ringSize = node.size * scale * 0.8
				elseif searching and self:NodeMatchesSearch(node, searchLower) then
					SetDrawColor(1, 0.2, 0.2)
					ringSize = node.size * scale * 0.8
				end
				if ringSize then
					SetDrawLayer(nil, 30)
					ringSize = m_max(ringSize, 12)
					DrawImage(self.ring, scrX - ringSize, scrY - ringSize, ringSize * 2, ringSize * 2)
					SetDrawLayer(nil, 20)
				end
			end
		end
	end
	SetDrawColor(1, 1, 1)

	if hoverNode and hoverNode.type ~= "Root" and not IsKeyDown("CTRL") then
		SetDrawLayer(nil, 100)
		if self.tooltip:CheckForUpdate(hoverNode, spec.revision) then
			self:AddNodeTooltip(self.tooltip, spec, hoverNode, hoverPath)
		end
		local scrX, scrY = self:TreeToScreen(hoverNode.x, hoverNode.y)
		local size = m_floor(hoverNode.size * scale * 0.5)
		self.tooltip:Draw(m_floor(scrX - size), m_floor(scrY - size), size * 2, size * 2, viewPort)
	end
	SetDrawLayer(nil, 0)
end

function AtlasTreeViewClass:NodeMatchesSearch(node, searchLower)
	if node.dn:lower():find(searchLower, 1, true) then
		return true
	end
	for _, line in ipairs(node.sd) do
		if line:lower():find(searchLower, 1, true) then
			return true
		end
	end
	for _, variant in ipairs(node.variants or { }) do
		for _, line in ipairs(variant.sd) do
			if line:lower():find(searchLower, 1, true) then
				return true
			end
		end
	end
	return false
end

function AtlasTreeViewClass:AddNodeTooltip(tooltip, spec, node, hoverPath)
	tooltip.center = true
	tooltip.maxWidth = 800
	local nameColor = node.type == "Keystone" and colorCodes.UNIQUE or (node.type == "Notable" and colorCodes.RARE or "^7")
	tooltip:AddLine(24, nameColor .. node.dn)
	tooltip:AddSeparator(10)
	local sameCount = #spec.tree:GetNodesWithSameName(node)
	if node.type == "Mastery" then
		tooltip:AddLine(16, "^7" .. sameCount .. " " .. node.dn .. " cluster" .. (sameCount == 1 and "" or "s") .. " on the atlas tree (highlighted)")
	elseif sameCount > 1 then
		tooltip:AddLine(14, "^8" .. (sameCount - 1) .. " other node" .. (sameCount == 2 and "" or "s") .. " with this name highlighted")
	end
	for _, line in ipairs(node.sd) do
		tooltip:AddLine(16, colorCodes.MAGIC .. line)
	end
	if node.variants then
		local selected = spec.variantSelections[node.id]
		for _, variant in ipairs(node.variants) do
			local isSelected = variant.effect == selected
			for _, line in ipairs(variant.sd) do
				tooltip:AddLine(16, (isSelected and colorCodes.MAGIC or "^8") .. line)
			end
			tooltip:AddSeparator(6)
		end
		tooltip:AddLine(14, "^7" .. (selected and "Click to change the chosen effect." or "Choose an effect after allocating."))
	end
	if node.reminderText then
		for _, line in ipairs(node.reminderText) do
			tooltip:AddLine(14, "^8" .. line)
		end
	end
	if node.flavourText then
		tooltip:AddSeparator(10)
		for _, line in ipairs(node.flavourText) do
			tooltip:AddLine(14, colorCodes.UNIQUE .. line)
		end
	end
	if node.type ~= "Mastery" then
		tooltip:AddSeparator(10)
		if spec.allocNodes[node.id] then
			local count = #spec:GetDependents(node)
			tooltip:AddLine(14, "^7Click to remove " .. count .. " point" .. (count == 1 and "" or "s") .. ".")
		else
			local count = #spec:GetPathToNode(node)
			if count > 0 then
				tooltip:AddLine(14, "^7Click to allocate " .. count .. " point" .. (count == 1 and "" or "s") .. ".")
			end
		end
	end
end
