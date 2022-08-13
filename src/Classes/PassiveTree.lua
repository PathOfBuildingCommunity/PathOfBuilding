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

	local maxZoomLevel = self.imageZoomLevels[#self.imageZoomLevels]

	ConPrintf("Loading passive tree sprites...")
	-- Load sprite sheets and build sprite map
	self.sprites = self.sprites or self.skillSprites -- renamed in 3.19
	self.spriteMap = { }
	local spriteSheets = { }
	for type, data in pairs(self.sprites) do
		self.spriteMap[type] = {}
		local maxZoom = data[#data]
		if versionNum >= 3.19 then
			maxZoom = data[maxZoomLevel] or data[1]
		end
		local sheet = spriteSheets[maxZoom.filename]
		if not sheet then
			sheet = { }
			self:LoadImage(versionNum >= 3.16 and maxZoom.filename:gsub("%?%x+$",""):gsub(".*/","") or maxZoom.filename:gsub("%?%x+$",""), versionNum >= 3.16 and maxZoom.filename or "https://web.poecdn.com"..(self.imageRoot or "/image/")..(versionNum >= 3.08 and "passive-skill/" or "build-gen/passive-skill-sprite/")..maxZoom.filename, sheet, "CLAMP")--, "MIPMAP")
			spriteSheets[maxZoom.filename] = sheet
		end
		for name, coords in pairs(maxZoom.coords) do
			self.spriteMap[type][name] = {
				debugId = type.."."..name,
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

	if versionNum < 3.19 then
		ConPrintf("Loading pre-3.19 passive tree assets and normalizing to sprite maps...")
		-- Prior to 3.19, many images that are now handles as sprites were instead
		-- loaded as "assets". We normalize old tree assets as if they were full-sheet sprites
		for name, data in pairs(self.assets) do
			self:LoadImage(name..".png", cdnRoot..(data[maxZoomLevel] or data[1]), data, not name:match("[OL][ri][bn][ie][tC]") and "ASYNC" or nil)--, not name:match("[OL][ri][bn][ie][tC]") and "MIPMAP" or nil)

			local type = self:InferAssetSpriteType(name)
			if type ~= nil then	
				if not self.spriteMap[type] then
					self.spriteMap[type] = { }
				end
				self.spriteMap[type][name] = {
					handle = data.handle,
					width = data.width,
					height = data.height,
					[1] = 0,
					[2] = 0,
					[3] = 1,
					[4] = 1,
				}
			end
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
			if not self.spriteMap[type] then
				self.spriteMap[type] = { }
			end
			self.spriteMap[type][name] = {
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
	self:PregenerateOrbitConnectorArcs()
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
					local connectors = self:BuildConnectors(node, other)
					for _, connector in ipairs(connectors) do
						t_insert(self.connectors, connector)
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
		node.sprites = self:MakeNodeSprites(node.type, node.icon)

		self:ProcessStats(node)
	end

	-- Late load the Generated data so we can take advantage of a tree existing
	buildTreeDependentUniques(self)
end)

function string:contains(searchTerm)
	return self:find(searchTerm, 1, true) ~= nil
end

function string:startswith(searchTerm)
    return self:sub(1, #searchTerm) == searchTerm
end

-- Given a pre-3.19 asset name, infers which 3.19+ sprite type it would appear under in more recent trees.
-- Used to normalize pre-3.19 assets into a 3.19-like spriteMap
--
-- nil return implies that we don't care about this sprite type
function PassiveTreeClass:InferAssetSpriteType(name)
	if name:startswith("Background") then
		return "background"
	elseif name:startswith("Classes") then
		return "ascendancyBackground"
	elseif name:startswith("Ascendancy") or name:startswith("Ascendency") then -- Yes, some assets have this typo
		return "ascendancy"
	elseif name:startswith("PSStartNode") or name:startswith("center") then
		return "startNode"
	elseif name:startswith("PSGroupBackground") or name:startswith("GroupBackground") then
		return "groupBackground"
	-- Careful, some "frame" assets start with "JewelSocket" - check for "JewelSocketActive" first
	elseif name:startswith("JewelSocketActive") then
		return "jewel"
	elseif name:contains("Frame") or name:startswith("JewelSocket") then
		return "frame"
	elseif name:startswith("Line") or name:startswith("Orbit") or name:startswith("PSLine") then
		return "line"
	elseif name:contains("JewelCircle") then
		return "jewelRadius"
	elseif name == "PassiveMasteryConnectedButton" then
		return "masteryActiveSelected" -- yes, not "masteryConnected"
	end

	return nil -- We doesn't use other asset types
end

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

function PassiveTreeClass:MakeNodeSprites(type, icon)
	local activeSpriteType = type:lower().."Active"
	local inactiveSpriteType = type:lower().."Inactive"

	return {
		mastery = self.spriteMap.mastery and self.spriteMap.mastery[icon] or nil,
		active = self.spriteMap[activeSpriteType] and self.spriteMap[activeSpriteType][icon] or nil,
		inactive = self.spriteMap[inactiveSpriteType] and self.spriteMap[inactiveSpriteType][icon] or nil
	}
end

-- Common processing code for nodes (used for both real tree nodes and subgraph nodes)
function PassiveTreeClass:ProcessNode(node)
	-- Assign node artwork assets
	if node.type == "Mastery" and node.masteryEffects then
		node.masterySprites = {
			activeIcon = self.spriteMap.masteryActiveSelected[node.activeIcon],
			activeEffectImage = self.spriteMap.masteryActiveEffect[node.activeEffectImage],
			connectedIcon = self.spriteMap.masteryConnected[node.inactiveIcon],
			inactiveIcon = self.spriteMap.masteryInactive[node.inactiveIcon]
		}
		node.sprites = self:MakeNodeSprites(node.type, "Art/2DArt/SkillIcons/passives/MasteryBlank.png")
	else
		node.sprites = self:MakeNodeSprites(node.type, node.icon)
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

function prettyPrintSprite(sprite)
	if sprite.debugId then
		ConPrintf("[sprite %s w=%d h=%d tc=%f,%f,%f,%f]", sprite.debugId, sprite.width, sprite.height, unpack(sprite))
	else
		ConPrintf("[sprite w=%d h=%d tc=%f,%f,%f,%f]", sprite.width, sprite.height, unpack(sprite))
	end
end

function PassiveTreeClass:PregenerateOrbitConnectorArcs()
	-- We render arc connectors by cutting the arc up into segments corresponding to
	-- orbit oidx angles and rendering one quad (representing a segment of the arc) per
	-- oidx that falls within the arc.
	--
	-- This function pregenerates those those quads and their mappings to the associated
	-- sprite for each combination of orbit and connector state.
	self.orbitConnectorArcs = {}
	for orbit, radius in ipairs(self.orbitRadii) do
		if self.skillsPerOrbit[orbit] < 2 then goto continue end

		self.orbitConnectorArcs[orbit] = {}
		for _, state in ipairs({ "Active", "Intermediate", "Normal" }) do
			local spriteName = "Orbit"..(orbit - 1)..state
			local sprite = self.spriteMap.line[spriteName]
			local angles = self.orbitAnglesByOrbit[orbit]

			-- We need to be careful about what parts of the sprite we use because (at least
			-- in 3.19+), the different orbits' sprites overlap one another (the arcs on the
			-- sprite sheet have the same center but different radii).
			local arcThickness = self.spriteMap.line["LineConnector"..state].height
			local treeRelativeArcThickness = arcThickness -- TODO research this
			local tcCenterX, tcCenterY = sprite[3], sprite[4] -- bottom-right of sprite
			-- Be careful - the arc sprites are squares, but their sprite sheets aren't, so
			-- in sprite texture coordinates, tcWidth ~= tcHeight
			local tcWidth = sprite[3] - sprite[1]
			local tcHeight = sprite[4] - sprite[2]
			local tcWidthRelativeArcThickness = (tcWidth / sprite.width) * arcThickness
			local tcHeightRelativeArcThickness = (tcHeight / sprite.height) * arcThickness
			local segments = {}
			for oidx, angle in ipairs(angles) do
				local nextAngle = angles[(oidx % #angles) + 1]
				-- The arc textures only span 90 degrees, so we need to clamp angles used for
				-- texture coordinate calculation to that specific 90 degree quadrant. This has
				-- the effect of rotating the texture to handle other quadrants of the arc, which
				-- isn't quite correct - the arc sprite isn't rotationally tileable, so futher
				-- down there's a correction that mirrors every other quadrant to make it looks
				-- seamless.
				local tcClampedAngle = angle % (m_pi / 2) + m_pi
				-- We do this instead of nextAngle % (m_pi / 2) to avoid issues if the
				-- next angle is at the boundary of the sprite's quadrant. This calculation
				-- assumes that orbit angles will always include values at exactly 90 angles.
				local tcClampedNextAngle = nextAngle + (angle - tcClampedAngle)
				-- assert(tcClampedNextAngle <= m_pi / 2, "tcClampedNextAngle out of bounds")
				local segment = {
					treeQuad = {
						[1] = m_sin(angle) * (radius + treeRelativeArcThickness / 2),
						[2] = m_cos(angle) * (radius + treeRelativeArcThickness / 2),
						[3] = m_sin(angle) * (radius - treeRelativeArcThickness / 2),
						[4] = m_cos(angle) * (radius - treeRelativeArcThickness / 2),
						[5] = m_sin(nextAngle) * (radius + treeRelativeArcThickness / 2),
						[6] = m_cos(nextAngle) * (radius + treeRelativeArcThickness / 2),
						[7] = m_sin(nextAngle) * (radius - treeRelativeArcThickness / 2),
						[8] = m_cos(nextAngle) * (radius - treeRelativeArcThickness / 2)
					},
					tcQuad = {
						[1] = tcCenterX + m_sin(tcClampedAngle) * (tcWidth),
						[2] = tcCenterY + m_cos(tcClampedAngle) * (tcHeight),
						[3] = tcCenterX + m_sin(tcClampedAngle) * (tcWidth - tcWidthRelativeArcThickness),
						[4] = tcCenterY + m_cos(tcClampedAngle) * (tcHeight - tcHeightRelativeArcThickness),
						[5] = tcCenterX + m_sin(tcClampedNextAngle) * (tcWidth),
						[6] = tcCenterY + m_cos(tcClampedNextAngle) * (tcHeight),
						[7] = tcCenterX + m_sin(tcClampedNextAngle) * (tcWidth - tcWidthRelativeArcThickness),
						[8] = tcCenterY + m_cos(tcClampedNextAngle) * (tcHeight - tcHeightRelativeArcThickness)
					}
				}
				-- TODO: mirror 2 of the 4 quadrants
				t_insert(segments, segment)
			end
			self.orbitConnectorArcs[orbit][state] = {
				sprite = sprite,
				segments = segments
			}
		end
		::continue::
	end

	prettyPrintTable(self.orbitConnectorArcs[3].Active.segments)
	local sprite = self.orbitConnectorArcs[3].Active.sprite
	print("width="..sprite.width.." height="..sprite.height.." tc="..sprite[1]..","..sprite[2]..","..sprite[3]..","..sprite[4])
end

-- Generate the quad(s) used to render the line between the two given nodes
function PassiveTreeClass:BuildConnectors(node1, node2)
	local connector = {
		ascendancyName = node1.ascendancyName,
		nodeId1 = node1.id,
		nodeId2 = node2.id,
	}
	if node1.g == node2.g and node1.o == node2.o then
		-- Nodes are in the same orbit of the same group, build an arc connector
		connector.arc = {
			orbit = node1.o + 1,
			centerX = node1.group.x,
			centerY = node1.group.y,
		}

		-- Order the oidx values such that we draw along the shorter arc
		local orbitSize = self.skillsPerOrbit[node1.o + 1]
		local dist1To2 = (node2.oidx - node1.oidx) % orbitSize
		if dist1To2 * 2 <= orbitSize then
			connector.arc.oidx1, connector.arc.oidx2 = node1.oidx, node2.oidx
		else
			connector.arc.oidx1, connector.arc.oidx2 = node2.oidx, node1.oidx
		end
	else
		-- Nodes don't share a group/orbit, build a straight line connector
		connector.type = "LineConnector"
		-- This assumes the sprites for the different LineConnector states all have the same height.
		local art = self.spriteMap.line.LineConnectorNormal
		local vX, vY = node2.x - node1.x, node2.y - node1.y
		local dist = m_sqrt(vX * vX + vY * vY)
		local scale = art.height * 1.33 / dist
		local nX, nY = vX * scale, vY * scale
		connector.lineQuad = {
			[1] = node1.x - nY, [2] = node1.y + nX,
			[3] = node1.x + nY, [4] = node1.y - nX,
			[5] = node2.x + nY, [6] = node2.y - nX,
			[7] = node2.x - nY, [8] = node2.y + nX
		}
	end

	return { connector }
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
