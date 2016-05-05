-- Path of Building
--
-- Class: Passive Tree View
-- Passive skill tree viewer.
--
local launch = ...

local pairs = pairs
local ipairs = ipairs
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local t_insert = table.insert

local TreeViewClass = common.NewClass("PassiveTreeView", function(self, main)
	self.main = main

	self.ring = NewImageHandle()
	self.ring:Load("Art/ring.png")

	self.zoomLevel = 3
	self.zoom = 1.2 ^ self.zoomLevel
	self.zoomX = 0
	self.zoomY = 0

	self.searchStr = ""

	self.controls = { }
	t_insert(self.controls, common.New("ButtonControl", function() return self.viewPort.x + 4 end, function() return self.viewPort.y + self.viewPort.height + 8 end, 60, 20, "Reset", function()
		launch:ShowPrompt(1, 0, 0, "Are you sure to want to reset your tree?\nPress Y to continue.", function(key)
			if key == "y" then
				self.build.spec:ResetNodes()
				self.build.spec:AddUndoState()
			end
			return true
		end)
	end))
	t_insert(self.controls, common.New("ButtonControl", function() return self.viewPort.x + 4 + 68*1 end, function() return self.viewPort.y + self.viewPort.height + 8 end, 60, 20, "Import", function()
		launch:ShowPrompt(0, 0, 0, "Press Ctrl+V to import passive tree link.", function(key)
			if key == "v" and IsKeyDown("CTRL") then
				local url = Paste()
				if url and #url > 0 then
					self.build.spec:DecodeURL(url)
					self.build.spec:AddUndoState()
				end
				return true
			elseif key == "ESCAPE" then
				return true
			end
		end)
	end))
	t_insert(self.controls, common.New("ButtonControl", function() return self.viewPort.x + 4 + 68*2 end, function() return self.viewPort.y + self.viewPort.height + 8 end, 60, 20, "Export", function()
		launch:ShowPrompt(0, 0, 0, "Press Ctrl+C to copy passive tree link.", function(key)
			if key == "c" and IsKeyDown("CTRL") then
				Copy(self.build.spec:EncodeURL("https://www.pathofexile.com/passive-skill-tree/"))
				return true
			elseif key == "ESCAPE" then
				return true
			end
		end)
	end))
	self.controls.treeSearch = common.New("EditControl", function() return self.viewPort.x + 4 + 68*3 end, function() return self.viewPort.y + self.viewPort.height + 8 end, 400, 20, "", "Search", "[^%c%(%)]", 100, nil, function(buf)
		self.searchStr = buf
	end)
end)

function TreeViewClass:Load(xml, fileName)
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
		self.controls.treeSearch:SetText(self.searchStr)
	end
	if xml.attrib.showHeatMap then
		self.showHeatMap = xml.attrib.showHeatMap == "true"
	end
end

function TreeViewClass:Save(xml)
	xml.attrib = {
		zoomLevel = tostring(self.zoomLevel),
		zoomX = tostring(self.zoomX),
		zoomY = tostring(self.zoomY),
		searchStr = self.searchStr,
		showHeatMap = tostring(self.showHeatMap),
	}
end

function TreeViewClass:DrawTree(build, viewPort, inputEvents)
	local tree = build.tree
	local spec = build.spec

	self.build = build
	self.viewPort = viewPort
	viewPort.height = viewPort.height - 32

	local treeClick
	common.controlsInput(self, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if event.key == "LEFTBUTTON" then
				self.dragX, self.dragY = GetCursorPos()
			elseif event.key == "z" and IsKeyDown("CTRL") then
				spec:Undo()
			elseif event.key == "y" and IsKeyDown("CTRL") then
				spec:Redo()
			elseif event.key == "h" then
				self.showHeatMap = not self.showHeatMap
			end
		elseif event.type == "KeyUp" then
			if event.key == "LEFTBUTTON" then
				if self.dragX and not self.dragging then
					treeClick = "LEFT"
				end
			elseif event.key == "RIGHTBUTTON" then
				treeClick = "RIGHT"
			elseif event.key == "WHEELUP" then
				self:Zoom(IsKeyDown("SHIFT") and 3 or 1, viewPort)
			elseif event.key == "WHEELDOWN" then
				self:Zoom(IsKeyDown("SHIFT") and -3 or -1, viewPort)
			end	
		end
	end

	local cursorX, cursorY = GetCursorPos()

	if not IsKeyDown("LEFTBUTTON") then
		self.dragging = false
		self.dragX, self.dragY = nil, nil
	end
	if self.dragX then
		if not self.dragging then
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
		self.traceMode = true
		self.tracePath = self.tracePath or { }
	else
		self.traceMode = false
		self.tracePath = nil
	end

	local hoverNode
	if cursorX >= viewPort.x and cursorX < viewPort.x + viewPort.width and cursorY >= viewPort.y and cursorY < viewPort.y + viewPort.height then
		local curTreeX, curTreeY = screenToTree(cursorX, cursorY)
		for id, node in pairs(spec.nodes) do
			if node.rsq then
				local vX = curTreeX - node.x
				local vY = curTreeY - node.y
				if vX * vX + vY * vY <= node.rsq then
					if self.traceMode then
						if not node.path then
							break
						elseif not self.tracePath[1] then
							for _, pathNode in ipairs(node.path) do
								t_insert(self.tracePath, 1, pathNode)
							end
						else
							local lastPathNode = self.tracePath[#self.tracePath]
							if node ~= lastPathNode then
								if isValueInArray(self.tracePath, node) then
									break
								end
								if not isValueInArray(node.linked, lastPathNode) then
									break
								end
								t_insert(self.tracePath, node)
							end
						end
					end
					hoverNode = node
					break
				end
			end
		end
	end
	local hoverPath, hoverDep
	if self.traceMode then
		hoverPath = { }
		for _, pathNode in pairs(self.tracePath) do
			hoverPath[pathNode] = true
		end
	elseif hoverNode and hoverNode.path then
		hoverPath = { }
		for _, pathNode in pairs(hoverNode.path) do
			hoverPath[pathNode] = true
		end
		hoverDep = { }
		for _, depNode in pairs(hoverNode.depends) do
			hoverDep[depNode] = true
		end
	end

	if treeClick == "LEFT" then
		if hoverNode then
			if hoverNode.alloc then
				spec:DeallocNode(hoverNode)
				spec:AddUndoState()
			elseif hoverNode.path then
				spec:AllocNode(hoverNode, self.tracePath and hoverNode == self.tracePath[#self.tracePath] and self.tracePath)
				spec:AddUndoState()
			end
		end
	elseif treeClick == "RIGHT" then
		if hoverNode and hoverNode.alloc and hoverNode.type == "socket" then
			build.viewMode = "ITEMS"
			local slot = build.items.sockets[hoverNode.id]
			slot.dropDown.dropped = true
			build.items.selControl = slot
		end
	end

	local bg = tree.assets.Background1
	local bgSize = bg.width * scale * 1.33 * 2.5
	SetDrawColor(1, 1, 1)
	DrawImage(bg.handle, viewPort.x, viewPort.y, viewPort.width, viewPort.height, (self.zoomX + viewPort.width/2) / -bgSize, (self.zoomY + viewPort.height/2) / -bgSize, (viewPort.width/2 - self.zoomX) / bgSize, (viewPort.height/2 - self.zoomY) / bgSize)

	local curAscendName = tree.classes[spec.curClassId].classes[tostring(spec.curAscendClassId)].name

	for _, group in pairs(tree.groups) do
		local scrX, scrY = treeToScreen(group.x, group.y)
		if group.ascendancyName then
			if group.isAscendancyStart then
				if group.ascendancyName ~= curAscendName then
					SetDrawColor(1, 1, 1, 0.25)
				end
				self:DrawAsset(tree.assets["Classes"..group.ascendancyName], scrX, scrY, scale)
				SetDrawColor(1, 1, 1)
			end
		elseif group.oo["3"] then
			self:DrawAsset(tree.assets.PSGroupBackground3, scrX, scrY, scale, true)
		elseif group.oo["2"] then
			self:DrawAsset(tree.assets.PSGroupBackground2, scrX, scrY, scale)
		elseif group.oo["1"] then
			self:DrawAsset(tree.assets.PSGroupBackground1, scrX, scrY, scale)
		end
	end

	for _, conn in pairs(tree.conn) do
		local state = "Normal"
		local node1, node2 = spec.nodes[conn.nodeId1], spec.nodes[conn.nodeId2]
		if node1.alloc and node2.alloc then	
			state = "Active"
		elseif hoverPath then
			if (node1.alloc or node1 == hoverNode or hoverPath[node1]) and (node2.alloc or node2 == hoverNode or hoverPath[node2]) then
				state = "Intermediate"
			end
		end
		local vert = conn.vert[state]
		conn.c[1], conn.c[2] = treeToScreen(vert[1], vert[2])
		conn.c[3], conn.c[4] = treeToScreen(vert[3], vert[4])
		conn.c[5], conn.c[6] = treeToScreen(vert[5], vert[6])
		conn.c[7], conn.c[8] = treeToScreen(vert[7], vert[8])
		if hoverDep and hoverDep[node1] and hoverDep[node2] then
			SetDrawColor(1, 0, 0)
		elseif conn.ascendancyName and conn.ascendancyName ~= curAscendName then
			SetDrawColor(0.75, 0.75, 0.75)
		end
		DrawImageQuad(tree.assets[conn.type..state].handle, unpack(conn.c))
		SetDrawColor(1, 1, 1)
	end

	for id, node in pairs(spec.nodes) do
		local base, overlay
		if node.type == "class" then
			overlay = node.alloc and node.startArt or "PSStartNodeBackgroundInactive"
		elseif node.type == "ascendClass" then
			overlay = "PassiveSkillScreenAscendancyMiddle"
		elseif node.type == "mastery" then
			base = node.sprites.mastery
		else
			local state
			if self.showHeatMap or node.alloc or node == hoverNode or (self.traceMode and node == self.tracePath[#self.tracePath])then
				state = "alloc"
			elseif hoverPath and hoverPath[node] then
				state = "path"
			else
				state = "unalloc"
			end
			if node.type == "socket" then
				base = tree.assets[node.overlay[state .. (node.ascendancyName and "Ascend" or "")]]
				local jewel = node.alloc and build.items.list[build.items.sockets[id].selItem]
				if jewel then
					if jewel.baseName == "Crimson Jewel" then
						overlay = "JewelSocketActiveRed"
					elseif jewel.baseName == "Viridian Jewel" then
						overlay = "JewelSocketActiveGreen"
					elseif jewel.baseName == "Cobalt Jewel" then
						overlay = "JewelSocketActiveBlue"
					end
				end
			else
				base = node.sprites[node.type..(node.alloc and "Active" or "Inactive")] 
				overlay = node.overlay[state .. (node.ascendancyName and "Ascend" or "")]
			end
		end
		local scrX, scrY = treeToScreen(node.x, node.y)
		if node.ascendancyName and node.ascendancyName ~= curAscendName then
			SetDrawColor(0.5, 0.5, 0.5)
		end
		if IsKeyDown("ALT") then
			if node.extra then
				SetDrawColor(1, 0, 0)
			elseif node.unknown then
				SetDrawColor(0, 1, 1)
			else
				SetDrawColor(0, 0, 0)
			end
		end
		if self.showHeatMap then
			if build.calcs.powerBuildFlag then
				build.calcs:BuildPower()
			end
			if not node.alloc and node.type ~= "class" and node.type ~= "ascendClass" then
				local dps = m_max(node.power.dps or 0, 0)
				local def = m_max(node.power.def or 0, 0)
				local dpsCol = (dps / build.calcs.powerMax.dps * 1.5) ^ 0.5
				local defCol = (def / build.calcs.powerMax.def * 1.5) ^ 0.5
				SetDrawColor(dpsCol, (dpsCol + defCol) / 4, defCol)
			else
				SetDrawColor(1, 1, 1)
			end
		end
		if base then
			self:DrawAsset(base, scrX, scrY, scale)
		end
		if overlay then
			if node.type ~= "class" and node.type ~= "ascendClass" then
				if #self.searchStr > 0 then
					local errMsg, match = PCall(string.match, node.dn:lower(), self.searchStr:lower())
					if not match then
						for index, line in ipairs(node.sd) do
							errMsg, match = PCall(string.match, line:lower(), self.searchStr:lower())
							if not match and node.mods[index].list then
								for k in pairs(node.mods[index].list) do
									errMsg, match = PCall(string.match, k, self.searchStr)
									if match then
										break
									end
								end
							end
							if match then
								break
							end
						end
					end
					if match then
						local col = math.sin((GetTime() / 100) % 360) / 2 + 0.5
						SetDrawColor(col, col, col)
					end
				end
				if hoverNode and hoverNode ~= node then
					if hoverDep and hoverDep[node] then
						SetDrawColor(1, 0, 0)
					end
					if hoverNode.type == "socket" then
						local vX, vY = node.x - hoverNode.x, node.y - hoverNode.y
						local dSq = vX * vX + vY * vY
						for _, data in ipairs(data.jewelRadius) do
							if dSq <= data.rad * data.rad then
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
	end

	for nodeId, slot in pairs(build.items.sockets) do
		local node = spec.nodes[nodeId]
		if node == hoverNode then
			local scrX, scrY = treeToScreen(node.x, node.y)
			for _, radData in ipairs(data.jewelRadius) do
				local size = radData.rad * scale
				SetDrawColor(radData.col)
				DrawImage(self.ring, scrX - size, scrY - size, size * 2, size * 2)
			end
		elseif node.alloc then
			local socket, jewel = build.items:GetSocketJewel(nodeId)
			if jewel and jewel.radius then
				local scrX, scrY = treeToScreen(node.x, node.y)
				local radData = data.jewelRadius[jewel.radius]
				local size = radData.rad * scale
				SetDrawColor(radData.col)
				DrawImage(self.ring, scrX - size, scrY - size, size * 2, size * 2)				
			end
		end
	end

	if hoverNode then
		self:AddNodeTooltip(hoverNode, build)
		local scrX, scrY = treeToScreen(hoverNode.x, hoverNode.y)
		local size = m_floor(hoverNode.size * scale)
		self.main:DrawTooltip(m_floor(scrX - size), m_floor(scrY - size), size * 2, size * 2, viewPort)
	end

	SetDrawColor(0.05, 0.05, 0.05)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height + 4, viewPort.width, 28)
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, viewPort.x, viewPort.y + viewPort.height, viewPort.width, 4)
	common.controlsDraw(self, viewPort)
end

function TreeViewClass:DrawAsset(data, x, y, scale, isHalf)
	local width = data.width * scale * 1.33
	local height = data.height * scale * 1.33
	if isHalf then
		DrawImage(data.handle, x - width, y - height * 2, width * 2, height * 2)
		DrawImage(data.handle, x - width, y, width * 2, height * 2, 0, 1, 1, 0)
	else
		DrawImage(data.handle, x - width, y - height, width * 2, height * 2, unpack(data))
	end
end

function TreeViewClass:Zoom(level, viewPort)
	self.zoomLevel = m_max(0, m_min(12, self.zoomLevel + level))
	local oldZoom = self.zoom
	self.zoom = 1.2 ^ self.zoomLevel
	local factor = self.zoom / oldZoom
	local cursorX, cursorY = GetCursorPos()
	local relX = cursorX - viewPort.x - viewPort.width/2
	local relY = cursorY - viewPort.y - viewPort.height/2
	self.zoomX = relX + (self.zoomX - relX) * factor
	self.zoomY = relY + (self.zoomY - relY) * factor
end

function TreeViewClass:AddNodeTooltip(node, build)
	-- Special case for sockets
	if node.type == "socket" and node.alloc then
		local socket, jewel = build.items:GetSocketJewel(node.id)
		if jewel then
			build.items:AddItemTooltip(jewel, build)
		else
			self.main:AddTooltipLine(24, "^7"..node.dn..(IsKeyDown("ALT") and " ["..node.id.."]" or ""))
		end
		self.main:AddTooltipSeperator(14)
		self.main:AddTooltipLine(14, "^x80A080Tip: Right click this socket to go to the items page and choose the jewel for this socket.")
		return
	end
	
	-- Node name
	self.main:AddTooltipLine(24, "^7"..node.dn..(IsKeyDown("ALT") and " ["..node.id.."]" or ""))
	if IsKeyDown("ALT") and node.power and node.power.dps then
		self.main:AddTooltipLine(16, string.format("DPS power: %g   Defence power: %g", node.power.dps, node.power.def))
	end

	-- Node description
	if node.sd[1] then
		self.main:AddTooltipLine(16, "")
		for i, line in ipairs(node.sd) do
			if node.mods[i].list then
				if IsKeyDown("ALT") then
					local modStr
					for k, v in pairs(node.mods[i].list) do
						modStr = (modStr and modStr..", " or "^2") .. string.format("%s = %s", k, tostring(v))
					end
					if node.mods[i].extra then
						modStr = (modStr and modStr.."  " or "") .. "^1" .. node.mods[i].extra
					end
					if modStr then
						line = line .. "  " .. modStr
					end
				end
			end
			self.main:AddTooltipLine(16, "^7"..line)
		end
	end

	-- Reminder text
	if node.reminderText then
		self.main:AddTooltipSeperator(14)
		for _, line in ipairs(node.reminderText) do
			self.main:AddTooltipLine(14, "^xA0A080"..line)
		end
	end

	-- Mod differences
	local calcFunc, calcBase = build.calcs:GetNodeCalculator(build)
	if calcFunc then
		self.main:AddTooltipSeperator(14)
		local count
		local nodeOutput, pathOutput
		if node.alloc then
			count = #node.depends
			nodeOutput = calcFunc({node}, true)
			pathOutput = calcFunc(node.depends, true)
		else
			local path = self.tracePath or node.path or { }
			count = #path
			nodeOutput = calcFunc({node})
			pathOutput = calcFunc(path)
		end
		local none = true
		local header = false
		for _, data in ipairs(build.displayStats) do
			if data.mod then
				local diff = (nodeOutput[data.mod] or 0) - (calcBase[data.mod] or 0)
				if diff > 0.001 or diff < -0.001 then
					none = false
					if not header then
						self.main:AddTooltipLine(14, string.format("^7%s this node will give you:", node.alloc and "Unallocating" or "Allocating"))
						header = true
					end
					self.main:AddTooltipLine(14, string.format("%s%+"..data.fmt.." %s", diff > 0 and "^x00FF44" or "^xFF3300", diff * (data.pc and 100 or 1), data.label))
				end
			end
		end
		if count > 1 then
			header = false
			for _, data in ipairs(build.displayStats) do
				if data.mod then
					local diff = (pathOutput[data.mod] or 0) - (calcBase[data.mod] or 0)
					if diff > 0.001 or diff < -0.001 then
						none = false
						if not header then
							self.main:AddTooltipLine(14, string.format("^7%s this node and all nodes %s will give you:", node.alloc and "Unallocating" or "Allocating", node.alloc and "depending on it" or "leading to it"))
							header = true
						end
						self.main:AddTooltipLine(14, string.format("%s%+"..data.fmt.." %s", diff > 0 and "^x00FF44" or "^xFF3300", diff * (data.pc and 100 or 1), data.label))
					end
				end
			end
		end
		if none then
			self.main:AddTooltipLine(14, string.format("^7No changes from %s this node%s.", node.alloc and "unallocating" or "allocating", count > 1 and " or the nodes leading to it" or ""))
		end
	end

	-- Pathing distance
	if node.path and #node.path > 0 then
		self.main:AddTooltipSeperator(14)
		self.main:AddTooltipLine(14, "^7"..#node.path .. " points to node")
		if #node.path > 1 then
			self.main:AddTooltipLine(14, "^x80A080")
			self.main:AddTooltipLine(14, "Tip: To reach this node by a different path, hold Shift, then trace the path and click this node")
		end
	end
end
