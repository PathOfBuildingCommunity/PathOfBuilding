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

-- These values are from the 3.6 tree; older trees are missing values for these constants
local legacySkillsPerOrbit = { 1, 6, 12, 12, 40 }
local legacyOrbitRadii = { 0, 82, 162, 335, 493 }

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
	self.classNotables = { }

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

	self.skillsPerOrbit = self.constants.skillsPerOrbit or legacySkillsPerOrbit
	self.orbitRadii = self.constants.orbitRadii or legacyOrbitRadii
	self.orbitAnglesByOrbit = {}
	for orbit, skillsInOrbit in ipairs(self.skillsPerOrbit) do
		self.orbitAnglesByOrbit[orbit] = self:CalcOrbitAngles(skillsInOrbit)
	end

	if versionNum >= 3.19 then
		local treeTextOLD
		local treeFileOLD = io.open("TreeData/".. "3_18" .."/tree.lua", "r")
		if treeFileOLD then
			treeTextOLD = treeFileOLD:read("*a")
			treeFileOLD:close()
		end
		local temp = {}
		for k, v in pairs(assert(loadstring(treeTextOLD))()) do
			temp[k] = v
		end
		self.assets = temp.assets
		self.skillSprites = self.sprites
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
		if versionNum >= 3.19 then
			maxZoom = data[0.3835] or data[1]
		end
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
	self.ascendancyMap = { }
	self.keystoneMap = { }
	self.notableMap = { }
	self.clusterNodeMap = { }
	self.sockets = { }
	self.masteryEffects = { }
	local nodeMap = { }
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
			self.keystoneMap[node.dn:lower()] = node
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
			else
				self.ascendancyMap[node.dn:lower()] = node
				if not self.classNotables[self.ascendNameMap[node.ascendancyName].class.name] then
					self.classNotables[self.ascendNameMap[node.ascendancyName].class.name] = { }
				end
				if self.ascendNameMap[node.ascendancyName].class.name ~= "Scion" then
					t_insert(self.classNotables[self.ascendNameMap[node.ascendancyName].class.name], node.dn)
				end
			end
		else
			node.type = "Normal"
			if node.ascendancyName == "Ascendant" and not node.dn:find("Dexterity") and not node.dn:find("Intelligence") and
				not node.dn:find("Strength") and not node.dn:find("Passive") then
				self.ascendancyMap[node.dn:lower()] = node
				if not self.classNotables[self.ascendNameMap[node.ascendancyName].class.name] then
					self.classNotables[self.ascendNameMap[node.ascendancyName].class.name] = { }
				end
				t_insert(self.classNotables[self.ascendNameMap[node.ascendancyName].class.name], node.dn)
			end
		end

		-- Find the node group
		local group = self.groups[node.g]
		if group then
			node.group = group
			group.ascendancyName = node.ascendancyName
			if node.isAscendancyStart then
				group.isAscendancyStart = true
			end
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
					local connectors = self:BuildConnector(node, other)
					t_insert(self.connectors, connectors[1])
					if connectors[2] then
						t_insert(self.connectors, connectors[2])
					end
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

	for name, keystone in pairs(self.keystoneMap) do
		keystone.nodesInRadius = { }
		for radiusIndex, radiusInfo in ipairs(data.jewelRadius) do
			keystone.nodesInRadius[radiusIndex] = { }
			local outerRadiusSquared = radiusInfo.outer * radiusInfo.outer
			local innerRadiusSquared = radiusInfo.inner * radiusInfo.inner
			if (keystone.x and keystone.y) then
				for _, node in pairs(self.nodes) do
					if node ~= keystone and not node.isBlighted and node.group and not node.isProxy and not node.group.isProxy and not node.isMastery and not node.isSocket then
						local vX, vY = node.x - keystone.x, node.y - keystone.y
						local euclideanDistanceSquared = vX * vX + vY * vY
						if innerRadiusSquared <= euclideanDistanceSquared then
							if euclideanDistanceSquared <= outerRadiusSquared then
								keystone.nodesInRadius[radiusIndex][node.id] = node
							end
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
			if not self.keystoneMap[node.dn] then -- Don't override good tree data with legacy keystones
				self.keystoneMap[node.dn] = node
			end
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

	-- Late load the Generated data so we can take advantage of a tree existing
	buildTreeDependentUniques(self)
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
		node.angle = self.orbitAnglesByOrbit[node.o + 1][node.oidx + 1]
		local orbitRadius = self.orbitRadii[node.o + 1]
		node.x = node.group.x + m_sin(node.angle) * orbitRadius
		node.y = node.group.y - m_cos(node.angle) * orbitRadius
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
		if arcAngle >= m_pi then
			node1, node2 = node2, node1
			arcAngle = m_pi * 2 - arcAngle
		end
		if arcAngle <= m_pi then
			-- Angle is less than 180 degrees, draw an arc
			-- If our arc is greater than 90 degrees, we will need 2 arcs because our orbit assets are at most 90 degree arcs see below
			-- The calling class already handles adding a second connector object in the return table if provided and omits it if nil
			-- Establish a nil secondConnector to populate in the case that we need a second arc (>90 degree orbit)
			local secondConnector
			if arcAngle > (m_pi / 2) then
				-- Angle is greater than 90 degrees.
				-- The default behavior for a given arcAngle is to place the arc at the center point between two nodes and clip the excess
				-- If we need a second arc of any size, we should shift the arcAngle to 25% of the distance between the nodes instead of 50%
				arcAngle = arcAngle / 2
				-- clone the original connector table to ensure same functionality for both of the necessary connectors
				secondConnector = copyTableSafe(connector)
				-- And then ask the BuildArc function to create a connector that is a mirror of the provided arcAngle
				-- Provide the second connector as a parameter to store the mirrored arc
				self:BuildArc(arcAngle, node1, secondConnector, true)
			end
			-- generate the primary arc -- this arcAngle may have been modified if we have determined that a second arc is necessary for this orbit
			self:BuildArc(arcAngle, node1, connector)
			return { connector, secondConnector }
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
	return { connector }
end

function PassiveTreeClass:BuildArc(arcAngle, node1, connector, isMirroredArc)
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
	if isMirroredArc then
		-- The center of the mirrored angle should be positioned at 75% of the way between nodes.
		angle = angle + arcAngle
	end
	connector.vert = { }
	for _, state in pairs({ "Normal", "Intermediate", "Active" }) do
		-- The different line states have differently-sized artwork, so the vertex coords must be calculated separately for each one
		local art = self.assets[connector.type .. state]
		local size = art.width * 2 * 1.33
		local oX, oY = size * m_sqrt(2) * m_sin(angle + m_pi / 4), size * m_sqrt(2) * -m_cos(angle + m_pi / 4)
		local cX, cY = node1.group.x + oX, node1.group.y + oY
		local vert = { }
		vert[1], vert[2] = node1.group.x, node1.group.y
		vert[3], vert[4] = cX + (size * m_sin(angle) - oX) * p, cY + (size * -m_cos(angle) - oY) * p
		vert[5], vert[6] = cX, cY
		vert[7], vert[8] = cX + (size * m_cos(angle) - oX) * p, cY + (size * m_sin(angle) - oY) * p
		if (isMirroredArc) then
		-- Flip the quad's non-origin, non-center vertexes when drawing a mirrored arc so that the arc actually mirrored
		-- This is required to prevent the connection of the 2 arcs appear to have a 'seam'
			local temp1, temp2 = vert[3],vert[4]
			vert[3],vert[4] = vert[7],vert[8]
			vert[7],vert[8] = temp1, temp2
		end
		connector.vert[state] = vert
	end
	connector.c[9], connector.c[10] = 1, 1
	connector.c[11], connector.c[12] = 0, p
	connector.c[13], connector.c[14] = 0, 0
	connector.c[15], connector.c[16] = p, 0
end

function PassiveTreeClass:CalcOrbitAngles(nodesInOrbit)
	local orbitAngles = {}

	if nodesInOrbit == 16 then
		-- Every 30 and 45 degrees, per https://github.com/grindinggear/skilltree-export/blob/3.17.0/README.md
		orbitAngles = { 0, 30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330 }
	elseif nodesInOrbit == 40 then
		-- Every 10 and 45 degrees
		orbitAngles = { 0, 10, 20, 30, 40, 45, 50, 60, 70, 80, 90, 100, 110, 120, 130, 135, 140, 150, 160, 170, 180, 190, 200, 210, 220, 225, 230, 240, 250, 260, 270, 280, 290, 300, 310, 315, 320, 330, 340, 350 }
	else
		-- Uniformly spaced
		for i = 0, nodesInOrbit do
			orbitAngles[i + 1] = 360 * i / nodesInOrbit
		end
	end

	for i, degrees in ipairs(orbitAngles) do
		orbitAngles[i] = m_rad(degrees)
	end

	return orbitAngles
end
