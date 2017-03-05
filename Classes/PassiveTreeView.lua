-- Path of Building
--
-- Class: Passive Tree View
-- Passive skill tree viewer.
-- Draws the passive skill tree, and also maintains the current view settings (zoom level, position, etc)
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local PassiveTreeViewClass = common.NewClass("PassiveTreeView", function(self)
	self.ring = NewImageHandle()
	self.ring:Load("Assets/ring.png")
	self.highlightRing = NewImageHandle()
	self.highlightRing:Load("Assets/small_ring.png")

	self.zoomLevel = 3
	self.zoom = 1.2 ^ self.zoomLevel
	self.zoomX = 0
	self.zoomY = 0

	self.searchStr = ""
end)

function PassiveTreeViewClass:Load(xml, fileName)
	if xml.attrib.zoomLevel then
		self.zoomLevel = tonumber(xml.attrib.zoomLevel)
		self.zoom = 1.2 ^ self.zoomLevel
	end
	if xml.attrib.zoomX and xml.attrib.zoomY then
		self.zoomX = tonumber(xml.attrib.zoomX)
		self.zoomY = tonumber(xml.attrib.zoomY)
	end
	if xml.attrib.searchStr then
		self.searchStr = xml.attrib.searchStr
	end
	if xml.attrib.showHeatMap then
		self.showHeatMap = xml.attrib.showHeatMap == "true"
	end
end

function PassiveTreeViewClass:Save(xml)
	xml.attrib = {
		zoomLevel = tostring(self.zoomLevel),
		zoomX = tostring(self.zoomX),
		zoomY = tostring(self.zoomY),
		searchStr = self.searchStr,
		showHeatMap = tostring(self.showHeatMap),
	}
end

function PassiveTreeViewClass:Draw(build, viewPort, inputEvents)
	local tree = build.tree
	local spec = build.spec

	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= viewPort.x and cursorX < viewPort.x + viewPort.width and cursorY >= viewPort.y and cursorY < viewPort.y + viewPort.height
	
	-- Process input events
	local treeClick
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "LEFTBUTTON" then
				if mOver then
					-- Record starting coords of mouse drag
					-- Dragging won't actually commence unless the cursor moves far enough
					self.dragX, self.dragY = cursorX, cursorY
				end
			elseif event.key == "p" then
				self.showHeatMap = not self.showHeatMap
			end
		elseif event.type == "KeyUp" then
			if event.key == "LEFTBUTTON" then
				if self.dragX and not self.dragging then
					-- Mouse button went down, but didn't move far enough to trigger drag, so register a normal click
					treeClick = "LEFT"
				end
			elseif mOver then
				if event.key == "RIGHTBUTTON" then
					treeClick = "RIGHT"
				elseif event.key == "WHEELUP" then
					self:Zoom(IsKeyDown("SHIFT") and 3 or 1, viewPort)
				elseif event.key == "WHEELDOWN" then
					self:Zoom(IsKeyDown("SHIFT") and -3 or -1, viewPort)
				end	
			end
		end
	end

	if not IsKeyDown("LEFTBUTTON") then
		-- Left mouse button isn't down, stop dragging if dragging was in progress
		self.dragging = false
		self.dragX, self.dragY = nil, nil
	end
	if self.dragX then
		-- Left mouse is down
		if not self.dragging then
			-- Check if mouse has moved more than a few pixels, and if so, initiate dragging
			if math.abs(cursorX - self.dragX) > 5 or math.abs(cursorY - self.dragY) > 5 then
				self.dragging = true
			end
		end
		if self.dragging then
			self.zoomX = self.zoomX + cursorX - self.dragX
			self.zoomY = self.zoomY + cursorY - self.dragY
			self.dragX, self.dragY = cursorX, cursorY
		end
	end
	
	-- Ctrl-click to zoom
	if treeClick and IsKeyDown("CTRL") then
		self:Zoom(treeClick == "RIGHT" and -2 or 2, viewPort)
		treeClick = nil
	end

	-- Create functions that will convert coordinates between the screen and tree coordinate spaces
	local scale = m_min(viewPort.width, viewPort.height) / tree.size * self.zoom
	local function treeToScreen(x, y)
		return x * scale + self.zoomX + viewPort.x + viewPort.width/2, 
			   y * scale + self.zoomY + viewPort.y + viewPort.height/2
	end
	local function screenToTree(x, y)
		return (x - self.zoomX - viewPort.x - viewPort.width/2) / scale, 
			   (y - self.zoomY - viewPort.y - viewPort.height/2) / scale 
	end

	if IsKeyDown("SHIFT") then
		-- Enable path tracing mode
		self.traceMode = true
		self.tracePath = self.tracePath or { }
	else
		self.traceMode = false
		self.tracePath = nil
	end

	local hoverNode
	if mOver then
		-- Cursor is over the tree, check if it is over a node
		local curTreeX, curTreeY = screenToTree(cursorX, cursorY)
		for nodeId, node in pairs(spec.nodes) do
			if node.rsq then
				-- Node has a defined size (i.e has artwork)
				local vX = curTreeX - node.x
				local vY = curTreeY - node.y
				if vX * vX + vY * vY <= node.rsq then
					hoverNode = node
					break
				end
			end
		end
	end

	-- If hovering over a node, find the path to it (if unallocated) or the list of dependant nodes (if allocated)
	local hoverPath, hoverDep
	if self.traceMode then
		-- Path tracing mode is enabled
		if hoverNode then
			if not hoverNode.path then
				-- Don't highlight the node if it can't be pathed to
				hoverNode = nil
			elseif not self.tracePath[1] then
				-- Initialise the trace path using this node's path
				for _, pathNode in ipairs(hoverNode.path) do
					t_insert(self.tracePath, 1, pathNode)
				end
			else
				local lastPathNode = self.tracePath[#self.tracePath]
				if hoverNode ~= lastPathNode then
					-- If node is directly linked to the last node in the path, add it
					if isValueInArray(hoverNode.linked, lastPathNode) then
						local index = isValueInArray(self.tracePath, hoverNode)
						if index then
							-- Node is already in the trace path, remove it first
							t_remove(self.tracePath, index)
						end
						t_insert(self.tracePath, hoverNode)	
					else
						hoverNode = nil
					end
				end
			end
		end
		-- Use the trace path as the path 
		hoverPath = { }
		for _, pathNode in pairs(self.tracePath) do
			hoverPath[pathNode] = true
		end
	elseif hoverNode and hoverNode.path then
		-- Use the node's own path and dependance list
		hoverPath = { }
		if not hoverNode.dependsOnIntuitiveLeap then
			for _, pathNode in pairs(hoverNode.path) do
				hoverPath[pathNode] = true
			end
		end
		hoverDep = { }
		for _, depNode in pairs(hoverNode.depends) do
			hoverDep[depNode] = true
		end
	end

	if treeClick == "LEFT" then
		if hoverNode then
			-- User left-clicked on a node
			if hoverNode.alloc then
				-- Node is allocated, so deallocate it
				spec:DeallocNode(hoverNode)
				spec:AddUndoState()
				build.buildFlag = true
			elseif hoverNode.path then
				-- Node is unallocated and can be allocated, so allocate it
				spec:AllocNode(hoverNode, self.tracePath and hoverNode == self.tracePath[#self.tracePath] and self.tracePath)
				spec:AddUndoState()
				build.buildFlag = true
			end
		end
	elseif treeClick == "RIGHT" then
		if hoverNode and hoverNode.alloc and hoverNode.type == "socket" then
			local slot = build.itemsTab.sockets[hoverNode.id]
			if slot:IsEnabled() then
				-- User right-clicked a jewel socket, jump to the item page and focus the corresponding item slot control
				slot.dropped = true
				build.itemsTab:SelectControl(slot)
				build.viewMode = "ITEMS"
			end
		end
	end

	-- Draw the background artwork
	local bg = tree.assets.Background1
	local bgSize = bg.width * scale * 1.33 * 2.5
	SetDrawColor(1, 1, 1)
	DrawImage(bg.handle, viewPort.x, viewPort.y, viewPort.width, viewPort.height, (self.zoomX + viewPort.width/2) / -bgSize, (self.zoomY + viewPort.height/2) / -bgSize, (viewPort.width/2 - self.zoomX) / bgSize, (viewPort.height/2 - self.zoomY) / bgSize)

	-- Hack to draw class background art, the position data doesn't seem to be in the tree JSON yet
	if build.spec.curClassId == 1 then
		local scrX, scrY = treeToScreen(-2750, 1600)
		self:DrawAsset(tree.assets.BackgroundStr, scrX, scrY, scale)
	elseif build.spec.curClassId == 2 then
		local scrX, scrY = treeToScreen(2550, 1600)
		self:DrawAsset(tree.assets.BackgroundDex, scrX, scrY, scale)
	elseif build.spec.curClassId == 3 then
		local scrX, scrY = treeToScreen(-250, -2200)
		self:DrawAsset(tree.assets.BackgroundInt, scrX, scrY, scale)
	elseif build.spec.curClassId == 4 then
		local scrX, scrY = treeToScreen(-150, 2350)
		self:DrawAsset(tree.assets.BackgroundStrDex, scrX, scrY, scale)
	elseif build.spec.curClassId == 5 then
		local scrX, scrY = treeToScreen(-2100, -1500)
		self:DrawAsset(tree.assets.BackgroundStrInt, scrX, scrY, scale)
	elseif build.spec.curClassId == 6 then
		local scrX, scrY = treeToScreen(2350, -1950)
		self:DrawAsset(tree.assets.BackgroundDexInt, scrX, scrY, scale)
	end

	-- Draw the group backgrounds
	for _, group in pairs(tree.groups) do
		local scrX, scrY = treeToScreen(group.x, group.y)
		if group.ascendancyName then
			if group.isAscendancyStart then
				if group.ascendancyName ~= spec.curAscendClassName then
					SetDrawColor(1, 1, 1, 0.25)
				end
				self:DrawAsset(tree.assets["Classes"..group.ascendancyName], scrX, scrY, scale)
				SetDrawColor(1, 1, 1)
			end
		elseif group.oo[3] then
			self:DrawAsset(tree.assets.PSGroupBackground3, scrX, scrY, scale, true)
		elseif group.oo[2] then
			self:DrawAsset(tree.assets.PSGroupBackground2, scrX, scrY, scale)
		elseif group.oo[1] then
			self:DrawAsset(tree.assets.PSGroupBackground1, scrX, scrY, scale)
		end
	end

	-- Draw the connecting lines between nodes
	SetDrawLayer(nil, 20)
	for _, connector in pairs(tree.connectors) do
		local node1, node2 = spec.nodes[connector.nodeId1], spec.nodes[connector.nodeId2]

		-- Determine the connector state
		local state = "Normal"
		if node1.alloc and node2.alloc then	
			state = "Active"
		elseif hoverPath then
			if (node1.alloc or node1 == hoverNode or hoverPath[node1]) and (node2.alloc or node2 == hoverNode or hoverPath[node2]) then
				state = "Intermediate"
			end
		end

		-- Convert vertex coordinates to screen-space and add them to the coordinate array
		local vert = connector.vert[state]
		connector.c[1], connector.c[2] = treeToScreen(vert[1], vert[2])
		connector.c[3], connector.c[4] = treeToScreen(vert[3], vert[4])
		connector.c[5], connector.c[6] = treeToScreen(vert[5], vert[6])
		connector.c[7], connector.c[8] = treeToScreen(vert[7], vert[8])

		if hoverDep and hoverDep[node1] and hoverDep[node2] then
			-- Both nodes depend on the node currently being hovered over, so color the line red
			SetDrawColor(1, 0, 0)
		elseif connector.ascendancyName and connector.ascendancyName ~= spec.curAscendClassName then
			-- Fade out lines in ascendancy classes other than the current one
			SetDrawColor(0.75, 0.75, 0.75)
		end
		DrawImageQuad(tree.assets[connector.type..state].handle, unpack(connector.c))
		SetDrawColor(1, 1, 1)
	end

	if self.showHeatMap then
		-- Build the power numbers if needed
		build.calcsTab:BuildPower()
	end

	-- Draw the nodes
	for nodeId, node in pairs(spec.nodes) do
		-- Determine the base and overlay images for this node based on type and state
		local base, overlay
		SetDrawLayer(nil, 25)
		if node.type == "classStart" then
			overlay = node.alloc and node.startArt or "PSStartNodeBackgroundInactive"
		elseif node.type == "ascendClassStart" then
			overlay = "PassiveSkillScreenAscendancyMiddle"
		elseif node.type == "mastery" then
			-- This is the icon that appears in the center of many groups
			SetDrawLayer(nil, 15)
			base = node.sprites.mastery
		else
			local state
			if self.showHeatMap or node.alloc or node == hoverNode or (self.traceMode and node == self.tracePath[#self.tracePath])then
				-- Show node as allocated if it is being hovered over
				-- Also if the heat map is turned on (makes the nodes more visible)
				state = "alloc"
			elseif hoverPath and hoverPath[node] then
				state = "path"
			else
				state = "unalloc"
			end
			if node.type == "socket" then
				-- Node is a jewel socket, retrieve the socketed jewel (if present) so we can display the correct art
				base = tree.assets[node.overlay[state]]
				local socket, jewel = build.itemsTab:GetSocketAndJewelForNodeID(nodeId)
				if node.alloc and jewel then
					if jewel.baseName == "Crimson Jewel" then
						overlay = "JewelSocketActiveRed"
					elseif jewel.baseName == "Viridian Jewel" then
						overlay = "JewelSocketActiveGreen"
					elseif jewel.baseName == "Cobalt Jewel" then
						overlay = "JewelSocketActiveBlue"
					end
				end
			else
				-- Normal node (includes keystones and notables)
				base = node.sprites[node.type..(node.alloc and "Active" or "Inactive")] 
				overlay = node.overlay[state .. (node.ascendancyName and "Ascend" or "")]
			end
		end

		-- Convert node position to screen-space
		local scrX, scrY = treeToScreen(node.x, node.y)
	
		-- Determine color for the base artwork
		if node.ascendancyName and node.ascendancyName ~= spec.curAscendClassName then
			-- By default, fade out nodes from ascendancy classes other than the current one
			SetDrawColor(0.5, 0.5, 0.5)
		end
		if self.showHeatMap then
			if not node.alloc and node.type ~= "classStart" and node.type ~= "ascendClassStart" then
				-- Calculate color based on DPS and defensive powers
				local dps = m_max(node.power.dps or 0, 0)
				local def = m_max(node.power.def or 0, 0)
				local dpsCol = (dps / build.calcsTab.powerMax.dps * 1.5) ^ 0.5
				local defCol = (def / build.calcsTab.powerMax.def * 1.5) ^ 0.5
				SetDrawColor(dpsCol, (m_max(dpsCol - 0.5, 0) + m_max(defCol - 0.5, 0)) / 2, defCol)
			else
				SetDrawColor(1, 1, 1)
			end
		elseif launch.devMode and IsKeyDown("ALT") then
			-- Debug display
			if node.extra then
				SetDrawColor(1, 0, 0)
			elseif node.unknown then
				SetDrawColor(0, 1, 1)
			else
				SetDrawColor(0, 0, 0)
			end
		else
			SetDrawColor(1, 1, 1)
		end
		
		-- Draw base artwork
		if base then
			self:DrawAsset(base, scrX, scrY, scale)
		end

		if overlay then
			-- Draw overlay
			if node.type ~= "classStart" and node.type ~= "ascendClassStart" then
				if hoverNode and hoverNode ~= node then
					-- Mouse is hovering over a different node
					if hoverDep and hoverDep[node] then
						-- This node depends on the hover node, turn it red
						SetDrawColor(1, 0, 0)
					elseif hoverNode.type == "socket" then
						-- Hover node is a socket, check if this node falls within its radius and color it accordingly
						for index, data in ipairs(data.jewelRadius) do
							if hoverNode.nodesInRadius[index][node.id] then
								SetDrawColor(data.col)
								break
							end
						end
					end
				end
			end
			self:DrawAsset(tree.assets[overlay], scrX, scrY, scale)
			SetDrawColor(1, 1, 1)
		end
		if #self.searchStr > 0 and self:DoesNodeMatchSearchStr(node) then
			-- Node matches the search string, show the highlight circle
			SetDrawLayer(nil, 30)
			SetDrawColor(1, 0, 0)
			local size = 175 * scale / self.zoom ^ 0.4
			DrawImage(self.highlightRing, scrX - size, scrY - size, size * 2, size * 2)
		end
		if node == hoverNode and (node.type ~= "socket" or not IsKeyDown("SHIFT")) then
			-- Draw tooltip
			SetDrawLayer(nil, 100)
			local size = m_floor(hoverNode.size * scale)
			self:AddNodeTooltip(hoverNode, build)
			main:DrawTooltip(m_floor(scrX - size), m_floor(scrY - size), size * 2, size * 2, viewPort)
		end
	end

	-- Draw ring overlays for jewel sockets
	SetDrawLayer(nil, 25)
	for nodeId, slot in pairs(build.itemsTab.sockets) do
		local node = spec.nodes[nodeId]
		if node == hoverNode then
			-- Mouse is over this socket, show all radius rings
			local scrX, scrY = treeToScreen(node.x, node.y)
			for _, radData in ipairs(data.jewelRadius) do
				local size = radData.rad * scale
				SetDrawColor(radData.col)
				DrawImage(self.ring, scrX - size, scrY - size, size * 2, size * 2)
			end
		elseif node.alloc then
			local socket, jewel = build.itemsTab:GetSocketAndJewelForNodeID(nodeId)
			if jewel and jewel.jewelRadiusIndex then
				-- Socket is allocated and there's a jewel socketed into it which has a radius, so show it
				local scrX, scrY = treeToScreen(node.x, node.y)
				local radData = data.jewelRadius[jewel.jewelRadiusIndex]
				local size = radData.rad * scale
				SetDrawColor(radData.col)
				DrawImage(self.ring, scrX - size, scrY - size, size * 2, size * 2)				
			end
		end
	end
end

-- Draws the given asset at the given position
function PassiveTreeViewClass:DrawAsset(data, x, y, scale, isHalf)
	local width = data.width * scale * 1.33
	local height = data.height * scale * 1.33
	if isHalf then
		DrawImage(data.handle, x - width, y - height * 2, width * 2, height * 2)
		DrawImage(data.handle, x - width, y, width * 2, height * 2, 0, 1, 1, 0)
	else
		DrawImage(data.handle, x - width, y - height, width * 2, height * 2, unpack(data))
	end
end

-- Zoom the tree in or out
function PassiveTreeViewClass:Zoom(level, viewPort)
	-- Calculate new zoom level and zoom factor
	self.zoomLevel = m_max(0, m_min(12, self.zoomLevel + level))
	local oldZoom = self.zoom
	self.zoom = 1.2 ^ self.zoomLevel

	-- Adjust zoom center position so that the point on the tree that is currently under the mouse will remain under it
	local factor = self.zoom / oldZoom
	local cursorX, cursorY = GetCursorPos()
	local relX = cursorX - viewPort.x - viewPort.width/2
	local relY = cursorY - viewPort.y - viewPort.height/2
	self.zoomX = relX + (self.zoomX - relX) * factor
	self.zoomY = relY + (self.zoomY - relY) * factor
end

function PassiveTreeViewClass:DoesNodeMatchSearchStr(node)
	if node.type == "mastery" then
		return
	end

	-- Check node name
	local errMsg, match = PCall(string.match, node.dn:lower(), self.searchStr:lower())
	if match then
		return true
	end

	-- Check node description
	for index, line in ipairs(node.sd) do
		-- Check display text first
		errMsg, match = PCall(string.match, line:lower(), self.searchStr:lower())
		if match then
			return true
		end
		if not match and node.mods[index].list then
			-- Then check modifiers
			for _, mod in ipairs(node.mods[index].list) do
				errMsg, match = PCall(string.match, mod.name, self.searchStr)
				if match then
					return true
				end
			end
		end
	end
end

function PassiveTreeViewClass:AddNodeName(node)
	main:AddTooltipLine(24, "^7"..node.dn..(launch.devMode and IsKeyDown("ALT") and " ["..node.id.."]" or ""))
	if node.type == "socket" then
		if node.attributesInRadius[2]["Str"] >= 40 then
			main:AddTooltipLine(16, "^7Can support "..data.colorCodes.STRENGTH.."Strength ^7threshold jewels")
		end
		if node.attributesInRadius[2]["Dex"] >= 40 then
			main:AddTooltipLine(16, "^7Can support "..data.colorCodes.DEXTERITY.."Dexterity ^7threshold jewels")
		end
		if node.attributesInRadius[2]["Int"] >= 40 then
			main:AddTooltipLine(16, "^7Can support "..data.colorCodes.INTELLIGENCE.."Intelligence ^7threshold jewels")
		end
	end
end

function PassiveTreeViewClass:AddNodeTooltip(node, build)
	-- Special case for sockets
	if node.type == "socket" and node.alloc then
		local socket, jewel = build.itemsTab:GetSocketAndJewelForNodeID(node.id)
		if jewel then
			build.itemsTab:AddItemTooltip(jewel, { nodeId = node.id })
		else
			self:AddNodeName(node)
		end
		main:AddTooltipSeparator(14)
		if socket:IsEnabled() then
			main:AddTooltipLine(14, "^x80A080Tip: Right click this socket to go to the items page and choose the jewel for this socket.")
		end
		main:AddTooltipLine(14, "^x80A080Tip: Hold Shift to hide this tooltip.")
		return
	end
	
	-- Node name
	self:AddNodeName(node)
	if launch.devMode and IsKeyDown("ALT") and node.power and node.power.dps then
		-- Power debugging info
		main:AddTooltipLine(16, string.format("DPS power: %g   Defence power: %g", node.power.dps, node.power.def))
	end

	-- Node description
	if node.sd[1] then
		main:AddTooltipLine(16, "")
		for i, line in ipairs(node.sd) do
			if node.mods[i].list then
				if launch.devMode and IsKeyDown("ALT") then
					-- Modifier debugging info
					local modStr
					for _, mod in pairs(node.mods[i].list) do
						modStr = (modStr and modStr..", " or "^2") .. modLib.formatMod(mod)
					end
					if node.mods[i].extra then
						modStr = (modStr and modStr.."  " or "") .. "^1" .. node.mods[i].extra
					end
					if modStr then
						line = line .. "  " .. modStr
					end
				end
			end
			main:AddTooltipLine(16, ((node.mods[i].extra or not node.mods[i].list) and data.colorCodes.UNSUPPORTED or data.colorCodes.MAGIC)..line)
		end
	end

	-- Reminder text
	if node.reminderText then
		main:AddTooltipSeparator(14)
		for _, line in ipairs(node.reminderText) do
			main:AddTooltipLine(14, "^xA0A080"..line)
		end
	end

	-- Mod differences
	local calcFunc, calcBase = build.calcsTab:GetMiscCalculator(build)
	if calcFunc then
		main:AddTooltipSeparator(14)
		local path = (node.alloc and node.depends) or self.tracePath or node.path or { }
		local pathLength = #path
		local pathNodes = { }
		for _, node in pairs(path) do
			pathNodes[node] = true
		end
		local nodeOutput, pathOutput
		if node.alloc then
			-- Calculate the differences caused by deallocating this node and its dependants
			nodeOutput = calcFunc({ removeNodes = { [node] = true } })
			if pathLength > 1 then
				pathOutput = calcFunc({ removeNodes = pathNodes })
			end
		else
			-- Calculated the differences caused by allocating this node and all nodes along the path to it
			nodeOutput = calcFunc({ addNodes = { [node] = true } })
			if pathLength > 1 then
				pathOutput = calcFunc({ addNodes = pathNodes })
			end
		end
		local count = build:AddStatComparesToTooltip(calcBase, nodeOutput, node.alloc and "^7Unallocating this node will give you:" or "^7Allocating this node will give you:")
		if pathLength > 1 then
			count = count + build:AddStatComparesToTooltip(calcBase, pathOutput, node.alloc and "^7Unallocating this node and all nodes depending on it will give you:" or "^7Allocating this node and all nodes leading to it will give you:", pathLength)
		end
		if count == 0 then
			main:AddTooltipLine(14, string.format("^7No changes from %s this node%s.", node.alloc and "unallocating" or "allocating", pathLength > 1 and " or the nodes leading to it" or ""))
		end
	end

	-- Pathing distance
	main:AddTooltipSeparator(14)
	if node.path and #node.path > 0 then
		if self.traceMode and isValueInArray(self.tracePath, node) then
			main:AddTooltipLine(14, "^7"..#self.tracePath .. " nodes in trace path")
		else
			main:AddTooltipLine(14, "^7"..#node.path .. " points to node")
			if #node.path > 1 then
				-- Handy hint!
				main:AddTooltipLine(14, "^x80A080")
				main:AddTooltipLine(14, "Tip: To reach this node by a different path, hold Shift, then trace the path and click this node")
			end
		end
	end
	if node.type == "socket" then
		main:AddTooltipLine(14, "^x80A080Tip: Hold Shift to hide this tooltip.")
	end
	if node.depends and #node.depends > 1 then
		main:AddTooltipSeparator(14)
		main:AddTooltipLine(14, "^7"..#node.depends .. " points gained from unallocating these nodes")
	end
end
