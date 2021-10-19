-- Path of Building
--
-- Class: Passive Tree
-- Passive skill tree class.
-- Responsible for downloading and loading the passive tree data and assets
-- Also pre-calculates and pre-parses most of the data need to use the passive tree, including the node modifiers
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_pi = math.pi
local m_rad = math.rad
local m_sin = math.sin
local m_cos = math.cos
local m_tan = math.tan
local m_sqrt = math.sqrt


local classArt = {
	[0] = "centerscion",
	[1] = "centermarauder",
	[2] = "centerranger",
	[3] = "centerwitch",
	[4] = "centerduelist",
	[5] = "centertemplar",
	[6] = "centershadow"
}

local orbit4Angle = { [0] = 0, 10, 20, 30, 40, 45, 50, 60, 70, 80, 90, 100, 110, 120, 130, 135, 140, 150, 160, 170, 180, 190, 200, 210, 220, 225, 230, 240, 250, 260, 270, 280, 290, 300, 310, 315, 320, 330, 340, 350 }
for i, ang in ipairs(orbit4Angle) do
	orbit4Angle[i] = m_rad(ang)
end
local orbitMult = { [0] = 0, m_pi / 3, m_pi / 6, m_pi / 6, m_pi / 6, m_pi / 36, m_pi / 36 }
local orbitDist = { [0] = 0, 82, 162, 335, 493, 662, 845 }


-- Retrieve the file at the given URL
local function getFile(URL)
	local page = ""
	local easy = common.curl.easy()
	easy:setopt_url(URL)
	easy:setopt_writefunction(function(data)
		page = page..data
		return true
	end)
	easy:perform()
	easy:close()
	return #page > 0 and page
end

local PassiveTreeClass = newClass("PassiveTree", function(self, treeVersion)
	self.treeVersion = treeVersion
	local versionNum = treeVersions[treeVersion].num

	self.legion = LoadModule("Data/LegionPassives")

	MakeDir("TreeData")

	ConPrintf("Loading passive tree data for version '%s'...", treeVersions[treeVersion].display)
	local treeText
	local treeFile = io.open("TreeData/"..treeVersion.."/tree.lua", "r")
	if treeFile then
		treeText = treeFile:read("*a")
		treeFile:close()
	else
		ConPrintf("Downloading passive tree data...")
		local page
		local pageFile = io.open("TreeData/"..treeVersion.."/data.json", "r")
		if pageFile then
			page = pageFile:read("*a")
			pageFile:close()
		else
			page = getFile("https://www.pathofexile.com/passive-skill-tree")
		end
		local treeData = page:match("var passiveSkillTreeData = (%b{})")
		if treeData then
			treeText = "local tree=" .. jsonToLua(page:match("var passiveSkillTreeData = (%b{})"))
			treeText = treeText .. "return tree"
		else
			treeText = "return " .. jsonToLua(page)
		end
		treeFile = io.open("TreeData/"..treeVersion.."/tree.lua", "w")
		treeFile:write(treeText)
		treeFile:close()
	end
	for k, v in pairs(assert(loadstring(treeText))()) do
		self[k] = v
	end

	local cdnRoot = versionNum >= 3.08 and versionNum <= 3.09 and "https://web.poecdn.com" or ""

	self.size = m_min(self.max_x - self.min_x, self.max_y - self.min_y) * 1.1

	if versionNum >= 3.10 then
		-- Migrate to old format
		for i = 0, 6 do
			self.classes[i] = self.classes[i + 1]
			self.classes[i + 1] = nil
		end
	end

	-- Build maps of class name -> class table
	self.classNameMap = { }
	self.ascendNameMap = { }
	for classId, class in pairs(self.classes) do
		if versionNum >= 3.10 then
			-- Migrate to old format
			class.classes = class.ascendancies
		end
		class.classes[0] = { name = "None" }
		self.classNameMap[class.name] = classId
		for ascendClassId, ascendClass in pairs(class.classes) do
			self.ascendNameMap[ascendClass.name] = {
				classId = classId,
				class = class,
				ascendClassId = ascendClassId,
				ascendClass = ascendClass
			}
		end
	end

	ConPrintf("Loading passive tree assets...")
	for name, data in pairs(self.assets) do
		self:LoadImage(name..".png", cdnRoot..(data[0.3835] or data[1]), data, not name:match("[OL][ri][bn][ie][tC]") and "ASYNC" or nil)--, not name:match("[OL][ri][bn][ie][tC]") and "MIPMAP" or nil)
	end

	-- Load sprite sheets and build sprite map
	self.spriteMap = { }
	local spriteSheets = { }
	for type, data in pairs(self.skillSprites) do
		local maxZoom = data[#data]
		local sheet = spriteSheets[maxZoom.filename]
		if not sheet then
			sheet = { }
			self:LoadImage(versionNum >= 3.16 and maxZoom.filename:gsub("%?%x+$",""):gsub(".*/","") or maxZoom.filename:gsub("%?%x+$",""), versionNum >= 3.16 and maxZoom.filename or "https://web.poecdn.com"..(self.imageRoot or "/image/")..(versionNum >= 3.08 and "passive-skill/" or "build-gen/passive-skill-sprite/")..maxZoom.filename, sheet, "CLAMP")--, "MIPMAP")
			spriteSheets[maxZoom.filename] = sheet
		end
		for name, coords in pairs(maxZoom.coords) do
			if not self.spriteMap[name] then
				self.spriteMap[name] = { }
			end
			self.spriteMap[name][type] = {
				handle = sheet.handle,
				width = coords.w,
				height = coords.h,
				[1] = coords.x / sheet.width,
				[2] = coords.y / sheet.height,
				[3] = (coords.x + coords.w) / sheet.width,
				[4] = (coords.y + coords.h) / sheet.height
			}
		end
	end

	-- Load legion sprite sheets and build sprite map
	local legionSprites = LoadModule("TreeData/legion/tree-legion.lua")
	for type, data in pairs(legionSprites) do
		local maxZoom = data[#data]
		local sheet = spriteSheets[maxZoom.filename]
		if not sheet then
			sheet = { }
			sheet.handle = NewImageHandle()
			sheet.handle:Load("TreeData/legion/"..maxZoom.filename)
			sheet.width, sheet.height = sheet.handle:ImageSize()
			spriteSheets[maxZoom.filename] = sheet
		end
		for name, coords in pairs(maxZoom.coords) do
			if not self.spriteMap[name] then
				self.spriteMap[name] = { }
			end
			self.spriteMap[name][type] = {
				handle = sheet.handle,
				width = coords.w,
				height = coords.h,
				[1] = coords.x / sheet.width,
				[2] = coords.y / sheet.height,
				[3] = (coords.x + coords.w) / sheet.width,
				[4] = (coords.y + coords.h) / sheet.height
			}
		end
	end

	local classArt = {
		[0] = "centerscion",
		[1] = "centermarauder",
		[2] = "centerranger",
		[3] = "centerwitch",
		[4] = "centerduelist",
		[5] = "centertemplar",
		[6] = "centershadow"
	}
	self.nodeOverlay = {
		Normal = {
			artWidth = 40,
			alloc = "PSSkillFrameActive",
			path = "PSSkillFrameHighlighted",
			unalloc = "PSSkillFrame",
			allocAscend = versionNum >= 3.10 and "AscendancyFrameSmallAllocated" or "PassiveSkillScreenAscendancyFrameSmallAllocated",
			pathAscend = versionNum >= 3.10 and "AscendancyFrameSmallCanAllocate" or "PassiveSkillScreenAscendancyFrameSmallCanAllocate",
			unallocAscend = versionNum >= 3.10 and "AscendancyFrameSmallNormal" or "PassiveSkillScreenAscendancyFrameSmallNormal"
		},
		Notable = {
			artWidth = 58,
			alloc = "NotableFrameAllocated",
			path = "NotableFrameCanAllocate",
			unalloc = "NotableFrameUnallocated",
			allocAscend = versionNum >= 3.10 and "AscendancyFrameLargeAllocated" or "PassiveSkillScreenAscendancyFrameLargeAllocated",
			pathAscend = versionNum >= 3.10 and "AscendancyFrameLargeCanAllocate" or "PassiveSkillScreenAscendancyFrameLargeCanAllocate",
			unallocAscend = versionNum >= 3.10 and "AscendancyFrameLargeNormal" or "PassiveSkillScreenAscendancyFrameLargeNormal",
			allocBlighted = "BlightedNotableFrameAllocated",
			pathBlighted = "BlightedNotableFrameCanAllocate",
			unallocBlighted = "BlightedNotableFrameUnallocated",
		},
		Keystone = {
			artWidth = 84,
			alloc = "KeystoneFrameAllocated",
			path = "KeystoneFrameCanAllocate",
			unalloc = "KeystoneFrameUnallocated"
		},
		Socket = {
			artWidth = 58,
			alloc = "JewelFrameAllocated",
			path = "JewelFrameCanAllocate",
			unalloc = "JewelFrameUnallocated",
			allocAlt = "JewelSocketAltActive",
			pathAlt = "JewelSocketAltCanAllocate",
			unallocAlt = "JewelSocketAltNormal",
		},
		Mastery = {
			artWidth = 65,
			alloc = "AscendancyFrameLargeAllocated",
			path = "AscendancyFrameLargeCanAllocate",
			unalloc = "AscendancyFrameLargeNormal"
		},
	}
	for type, data in pairs(self.nodeOverlay) do
		local size = data.artWidth * 1.33
		data.size = size
		data.rsq = size * size
	end

	if versionNum >= 3.10 then
		-- Migrate groups to old format
		for _, group in pairs(self.groups) do
			group.n = group.nodes
			group.oo = { }
			for _, orbit in ipairs(group.orbits) do
				group.oo[orbit] = true
			end
		end

		-- Go away
		self.nodes.root = nil
	end

	ConPrintf("Processing tree...")
	self.keystoneMap = { }
	self.notableMap = { }
	self.clusterNodeMap = { }
	self.sockets = { }
	self.masteryEffects = { }
	local nodeMap = { }
	local orbitMult = { [0] = 0, m_pi / 3, m_pi / 6, m_pi / 6, m_pi / 6, m_pi / 36, m_pi / 36 }
	local orbitMultFull = {
		[0] = 0,
		[1] = 10 * m_pi / 180,
		[2] = 20 * m_pi / 180,
		[3] = 30 * m_pi / 180,
		[4] = 40 * m_pi / 180,
		[5] = 45 * m_pi / 180,
		[6] = 50 * m_pi / 180,
		[7] = 60 * m_pi / 180,
		[8] = 70 * m_pi / 180,
		[9] = 80 * m_pi / 180,
		[10] = 90 * m_pi / 180,
		[11] = 100 * m_pi / 180,
		[12] = 110 * m_pi / 180,
		[13] = 120 * m_pi / 180,
		[14] = 130 * m_pi / 180,
		[15] = 135 * m_pi / 180,
		[16] = 140 * m_pi / 180,
		[17] = 150 * m_pi / 180,
		[18] = 160 * m_pi / 180,
		[19] = 170 * m_pi / 180,
		[20] = 180 * m_pi / 180,
		[21] = 190 * m_pi / 180,
		[22] = 200 * m_pi / 180,
		[23] = 210 * m_pi / 180,
		[24] = 220 * m_pi / 180,
		[25] = 225 * m_pi / 180,
		[26] = 230 * m_pi / 180,
		[27] = 240 * m_pi / 180,
		[28] = 250 * m_pi / 180,
		[29] = 260 * m_pi / 180,
		[30] = 270 * m_pi / 180,
		[31] = 280 * m_pi / 180,
		[32] = 290 * m_pi / 180,
		[33] = 300 * m_pi / 180,
		[34] = 310 * m_pi / 180,
		[35] = 315 * m_pi / 180,
		[36] = 320 * m_pi / 180,
		[37] = 330 * m_pi / 180,
		[38] = 340 * m_pi / 180,
		[39] = 350 * m_pi / 180
	}
	local orbitDist = { [0] = 0, 82, 162, 335, 493, 662, 845 }
	for _, node in pairs(self.nodes) do
		-- Migration...
		if versionNum < 3.10 then
			-- To new format
			node.classStartIndex = node.spc[0] and node.spc[0]
		else
			-- To old format
			node.id = node.skill
			node.g = node.group
			node.o = node.orbit
			node.oidx = node.orbitIndex
			node.dn = node.name
			node.sd = node.stats
			node.passivePointsGranted = node.grantedPassivePoints or 0
		end

		if versionNum <= 3.09 and node.passivePointsGranted > 0 then
			t_insert(node.sd, "Grants "..node.passivePointsGranted.." Passive Skill Point"..(node.passivePointsGranted > 1 and "s" or ""))
		end
		node.conquered = false
		node.alternative = {}
		node.__index = node
		node.linkedId = { }
		nodeMap[node.id] = node	

		-- Determine node type
		if node.classStartIndex then
			node.type = "ClassStart"
			local class = self.classes[node.classStartIndex]
			class.startNodeId = node.id
			node.startArt = classArt[node.classStartIndex]
		elseif node.isAscendancyStart then
			node.type = "AscendClassStart"
			local ascendClass = self.ascendNameMap[node.ascendancyName].ascendClass
			ascendClass.startNodeId = node.id
		elseif node.m or node.isMastery then
			node.type = "Mastery"
			if node.masteryEffects then
				for _, effect in pairs(node.masteryEffects) do
					if not self.masteryEffects[effect.effect] then
						self.masteryEffects[effect.effect] = { id = effect.effect, sd = effect.stats }
						self:ProcessStats(self.masteryEffects[effect.effect])
					end
				end
			end
		elseif node.isJewelSocket then
			node.type = "Socket"
			self.sockets[node.id] = node
		elseif node.ks or node.isKeystone then
			node.type = "Keystone"
			self.keystoneMap[node.dn] = node
		elseif node["not"] or node.isNotable then
			node.type = "Notable"
			if not node.ascendancyName then
				-- Some nodes have duplicate names in the tree data for some reason, even though they're not on the tree
				-- Only add them if they're actually part of a group (i.e. in the tree)
				-- Add everything otherwise, because cluster jewel notables don't have a group
				if not self.notableMap[node.dn:lower()] then
					self.notableMap[node.dn:lower()] = node
				elseif node.g then
					self.notableMap[node.dn:lower()] = node
				end
			end
		else
			node.type = "Normal"
		end

		-- Find the node group
		local group = self.groups[node.g]
		if group then
			node.group = group
			group.ascendancyName = node.ascendancyName
			if node.isAscendancyStart then
				group.isAscendancyStart = true
			end
			if node.o ~= 4 then
				node.angle = node.oidx * orbitMult[node.o]
			else
				node.angle = orbitMultFull[node.oidx]
			end
			local dist = orbitDist[node.o]
			node.x = group.x + m_sin(node.angle) * dist
			node.y = group.y - m_cos(node.angle) * dist
		elseif node.type == "Notable" or node.type == "Keystone" then
			self.clusterNodeMap[node.dn] = node
		end
		
		self:ProcessNode(node)
	end

	-- Pregenerate the polygons for the node connector lines
	self.connectors = { }
	for _, node in pairs(self.nodes) do
		for _, otherId in pairs(node.out or {}) do
			if type(otherId) == "string" then
				otherId = tonumber(otherId)
			end
			local other = nodeMap[otherId]
			t_insert(node.linkedId, otherId)
			if node.type ~= "ClassStart" and other.type ~= "ClassStart"
				and node.type ~= "Mastery" and other.type ~= "Mastery"
			  	and node.ascendancyName == other.ascendancyName
			  	and not node.isProxy and not other.isProxy
			  	and not node.group.isProxy and not node.group.isProxy then
					t_insert(self.connectors, self:BuildConnector(node, other))
			end
		end
		for _, otherId in pairs(node["in"] or {}) do
			if type(otherId) == "string" then
				otherId = tonumber(otherId)
			end
			t_insert(node.linkedId, otherId)
		end
	end
	-- Precalculate the lists of nodes that are within each radius of each socket
	for nodeId, socket in pairs(self.sockets) do
		socket.nodesInRadius = { }
		socket.attributesInRadius = { }
		for radiusIndex, radiusInfo in ipairs(data.jewelRadius) do
			socket.nodesInRadius[radiusIndex] = { }
			socket.attributesInRadius[radiusIndex] = { }
			local outerRadiusSquared = radiusInfo.outer * radiusInfo.outer
			local innerRadiusSquared = radiusInfo.inner * radiusInfo.inner
			for _, node in pairs(self.nodes) do
				if node ~= socket and not node.isBlighted and node.group and not node.isProxy and not node.group.isProxy and not node.isMastery then
					local vX, vY = node.x - socket.x, node.y - socket.y
					local euclideanDistanceSquared = vX * vX + vY * vY
					if innerRadiusSquared <= euclideanDistanceSquared then
						if euclideanDistanceSquared <= outerRadiusSquared then
							socket.nodesInRadius[radiusIndex][node.id] = node
						end
					end
				end
			end
		end
	end

	for classId, class in pairs(self.classes) do
		local startNode = nodeMap[class.startNodeId]
		for _, nodeId in ipairs(startNode.linkedId) do
			local node = nodeMap[nodeId]
			if node.type == "Normal" then
				node.modList:NewMod("Condition:ConnectedTo"..class.name.."Start", "FLAG", true, "Tree:"..nodeId)
			end
		end
	end

	-- Build ModList for legion jewels
	for _, node in pairs(self.legion.nodes) do
		-- Determine node type
		if node.m then
			node.type = "Mastery"
		elseif node.ks then
			node.type = "Keystone"
			self.keystoneMap[node.dn] = node
		elseif node["not"] then
			node.type = "Notable"
		else
			node.type = "Normal"
		end

		-- Assign node artwork assets
		node.sprites = self.spriteMap[node.icon]
		if not node.sprites then
			--error("missing sprite "..node.icon)
			node.sprites = { }
		end

		self:ProcessStats(node)
	end
end)

function PassiveTreeClass:ProcessStats(node)
	node.modKey = ""
	if not node.sd then
		return
	end

	-- Parse node modifier lines
	node.mods = { }
	local i = 1
	while node.sd[i] do
		if node.sd[i]:match("\n") then
			local line = node.sd[i]
			local il = i
			t_remove(node.sd, i)
			for line in line:gmatch("[^\n]+") do
				t_insert(node.sd, il, line)
				il = il + 1
			end
		end
		local line = node.sd[i]
		local list, extra = modLib.parseMod(line)
		if not list or extra then
			-- Try to combine it with one or more of the lines that follow this one
			local endI = i + 1
			while node.sd[endI] do
				local comb = line
				for ci = i + 1, endI do
					comb = comb .. " " .. node.sd[ci]
				end
				list, extra = modLib.parseMod(comb, true)
				if list and not extra then
					-- Success, add dummy mod lists to the other lines that were combined with this one
					for ci = i + 1, endI do
						node.mods[ci] = { list = { } }
					end
					break
				end
				endI = endI + 1
			end
		end
		if not list then
			-- Parser had no idea how to read this modifier
			node.unknown = true
		elseif extra then
			-- Parser recognised this as a modifier but couldn't understand all of it
			node.extra = true
		else
			for _, mod in ipairs(list) do
				node.modKey = node.modKey.."["..modLib.formatMod(mod).."]"
			end
		end
		node.mods[i] = { list = list, extra = extra }
		i = i + 1
		while node.mods[i] do
			-- Skip any lines with dummy lists added by the line combining code
			i = i + 1
		end
	end

	-- Build unified list of modifiers from all recognised modifier lines
	node.modList = new("ModList")
	for _, mod in pairs(node.mods) do
		if mod.list and not mod.extra then
			for i, mod in ipairs(mod.list) do
				mod = modLib.setSource(mod, "Tree:"..node.id)
				node.modList:AddMod(mod)
			end
		end
	end
	if node.type == "Keystone" then
		node.keystoneMod = modLib.createMod("Keystone", "LIST", node.dn, "Tree"..node.id)
	end
end

-- Common processing code for nodes (used for both real tree nodes and subgraph nodes)
function PassiveTreeClass:ProcessNode(node)
	-- Assign node artwork assets
	if node.type == "Mastery" and node.masteryEffects then
		node.masterySprites = { activeIcon = self.spriteMap[node.activeIcon], inactiveIcon = self.spriteMap[node.inactiveIcon], activeEffectImage = self.spriteMap[node.activeEffectImage] }
	else
		node.sprites = self.spriteMap[node.icon]
	end
	if not node.sprites then
		--error("missing sprite "..node.icon)
		node.sprites = self.spriteMap["Art/2DArt/SkillIcons/passives/MasteryBlank.png"]
	end
	node.overlay = self.nodeOverlay[node.type]
	if node.overlay then
		node.rsq = node.overlay.rsq
		node.size = node.overlay.size
	end

	-- Derive the true position of the node
	if node.group then
		node.angle = node.o == 4 and orbit4Angle[node.oidx] or node.oidx * orbitMult[node.o]
		local dist = orbitDist[node.o]
		node.x = node.group.x + m_sin(node.angle) * dist
		node.y = node.group.y - m_cos(node.angle) * dist
	end

	self:ProcessStats(node)
end

-- Checks if a given image is present and downloads it from the given URL if it isn't there
function PassiveTreeClass:LoadImage(imgName, url, data, ...)
	local imgFile = io.open("TreeData/"..imgName, "r")
	if imgFile then
		imgFile:close()
	else
		imgFile = io.open("TreeData/"..self.treeVersion.."/"..imgName, "r")
		if imgFile then
			imgFile:close()
			imgName = self.treeVersion.."/"..imgName
		elseif main.allowTreeDownload then -- Enable downloading with Ctrl+Shift+F5
			ConPrintf("Downloading '%s'...", imgName)
			local data = getFile(url)
			if data and not data:match("<!DOCTYPE html>") then
				imgFile = io.open("TreeData/"..imgName, "wb")
				imgFile:write(data)
				imgFile:close()
			else
				ConPrintf("Failed to download: %s", url)
			end
		end
	end
	data.handle = NewImageHandle()
	data.handle:Load("TreeData/"..imgName, ...)
	data.width, data.height = data.handle:ImageSize()
end

-- Generate the quad used to render the line between the two given nodes
function PassiveTreeClass:BuildConnector(node1, node2)
	local connector = {
		ascendancyName = node1.ascendancyName,
		nodeId1 = node1.id,
		nodeId2 = node2.id,
		c = { } -- This array will contain the quad's data: 1-8 are the vertex coordinates, 9-16 are the texture coordinates
				-- Only the texture coords are filled in at this time; the vertex coords need to be converted from tree-space to screen-space first
				-- This will occur when the tree is being drawn; .vert will map line state (Normal/Intermediate/Active) to the correct tree-space coordinates 
	}
	if node1.g == node2.g and node1.o == node2.o then
		-- Nodes are in the same orbit of the same group
		-- Calculate the starting angle (node1.angle) and arc angle
		if node1.angle > node2.angle then
			node1, node2 = node2, node1
		end
		local arcAngle = node2.angle - node1.angle
		if arcAngle > m_pi then
			node1, node2 = node2, node1
			arcAngle = m_pi * 2 - arcAngle
		end
		if arcAngle < m_pi * 0.9 then
			-- Angle is less than 180 degrees, draw an arc
			connector.type = "Orbit" .. node1.o
			-- This is an arc texture mapped onto a kite-shaped quad
			-- Calculate how much the arc needs to be clipped by
			-- Both ends of the arc will be clipped by this amount, so 90 degree arc angle = no clipping and 30 degree arc angle = 75 degrees of clipping
			-- The clipping is accomplished by effectively moving the bottom left and top right corners of the arc texture towards the top left corner
			-- The arc texture only shows 90 degrees of an arc, but some arcs must go for more than 90 degrees
			-- Fortunately there's nowhere on the tree where we can't just show the middle 90 degrees and rely on the node artwork to cover the gaps :)
			local clipAngle = m_pi / 4 - arcAngle / 2
			local p = 1 - m_max(m_tan(clipAngle), 0)
			local angle = node1.angle - clipAngle
			connector.vert = { }
			for _, state in pairs({"Normal","Intermediate","Active"}) do
				-- The different line states have differently-sized artwork, so the vertex coords must be calculated separately for each one
				local art = self.assets[connector.type..state]
				local size = art.width * 2 * 1.33
				local oX, oY = size * m_sqrt(2) * m_sin(angle + m_pi/4), size * m_sqrt(2) * -m_cos(angle + m_pi/4)
				local cX, cY = node1.group.x + oX, node1.group.y + oY
				local vert = { }
				vert[1], vert[2] = node1.group.x, node1.group.y
				vert[3], vert[4] = cX + (size * m_sin(angle) - oX) * p, cY + (size * -m_cos(angle) - oY) * p
				vert[5], vert[6] = cX, cY
				vert[7], vert[8] = cX + (size * m_cos(angle) - oX) * p, cY + (size * m_sin(angle) - oY) * p
				connector.vert[state] = vert
			end
			connector.c[9], connector.c[10] = 1, 1
			connector.c[11], connector.c[12] = 0, p
			connector.c[13], connector.c[14] = 0, 0
			connector.c[15], connector.c[16] = p, 0
			return connector
		end
	end

	-- Generate a straight line
	connector.type = "LineConnector"
	local art = self.assets.LineConnectorNormal
	local vX, vY = node2.x - node1.x, node2.y - node1.y
	local dist = m_sqrt(vX * vX + vY * vY)
	local scale = art.height * 1.33 / dist
	local nX, nY = vX * scale, vY * scale
	local endS = dist / (art.width * 1.33)
	connector[1], connector[2] = node1.x - nY, node1.y + nX
	connector[3], connector[4] = node1.x + nY, node1.y - nX
	connector[5], connector[6] = node2.x + nY, node2.y - nX
	connector[7], connector[8] = node2.x - nY, node2.y + nX
	connector.c[9], connector.c[10] = 0, 1
	connector.c[11], connector.c[12] = 0, 0
	connector.c[13], connector.c[14] = endS, 0
	connector.c[15], connector.c[16] = endS, 1
	connector.vert = { Normal = connector, Intermediate = connector, Active = connector }
	return connector
end
