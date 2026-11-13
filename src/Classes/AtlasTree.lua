local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_sin = math.sin
local m_cos = math.cos
local m_pi = math.pi

local nodeArtWidth = {
	Normal = 40,
	Notable = 58,
	Keystone = 84,
	Wormhole = 58,
	Mastery = 65,
	Root = 100,
}

local assetSpriteTypes = {
	line = true,
	frame = true,
	groupBackground = true,
	startNode = true,
	background = true,
	atlasBackground = true,
	masteryOverlay = true,
}

local AtlasTreeClass = newClass("AtlasTree")

function AtlasTreeClass.ResolveMarkup(text)
	return (text:gsub("%[([^%]]*)%]", function(inner)
		return inner:match("|(.*)$") or inner
	end))
end

local function splitLines(stats)
	local lines = { }
	for _, stat in ipairs(stats or { }) do
		for line in (AtlasTreeClass.ResolveMarkup(stat) .. "\n"):gmatch("([^\n]*)\n") do
			t_insert(lines, line)
		end
	end
	return lines
end

local function pickZoom(zooms)
	if zooms["0.3835"] then
		return zooms["0.3835"]
	end
	local best, bestZoom
	for zoom, data in pairs(zooms) do
		local value = tonumber(zoom) or 0
		if not bestZoom or value > bestZoom then
			best, bestZoom = data, value
		end
	end
	return best
end

local function fileExists(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end
	return false
end

function AtlasTreeClass:AtlasTree(key)
	if not atlasTreeVersionMap[key] then
		key = latestAtlasTreeVersion
	end
	self.key = key
	self.display = atlasTreeVersionMap[key].display
	self.treeVersion = "Atlas/" .. key

	ConPrintf("Loading atlas tree data for version '%s'...", self.display)
	local file = assert(io.open("TreeData/Atlas/" .. key .. "/tree.lua", "r"))
	local text = file:read("*a")
	file:close()
	local data = assert(loadstring(text))()

	local passiveTreeClass = common.classes.PassiveTree
	self.skillsPerOrbit = data.constants.skillsPerOrbit
	self.orbitRadii = data.constants.orbitRadii
	self.orbitAnglesByOrbit = { }
	for orbit, skillsInOrbit in ipairs(self.skillsPerOrbit) do
		self.orbitAnglesByOrbit[orbit] = passiveTreeClass.CalcOrbitAngles(self, skillsInOrbit)
	end

	self.min_x, self.min_y, self.max_x, self.max_y = data.min_x, data.min_y, data.max_x, data.max_y
	self.size = m_min(self.max_x - self.min_x, self.max_y - self.min_y) * 1.1
	self.centerX = (self.min_x + self.max_x) / 2
	self.centerY = (self.min_y + self.max_y) / 2
	self.totalPoints = data.points and data.points.totalPoints or 0

	local imageMapFile = io.open("TreeData/Atlas/" .. key .. "/images.lua", "r")
	if imageMapFile then
		self.imageMap = assert(loadstring(imageMapFile:read("*a")))()
		imageMapFile:close()
	else
		self.imageMap = { }
	end

	self:LoadSprites(data)
	self:BuildGroups(data)
	self:BuildNodes(data)
	self:BuildConnectors()
	return self
end

function AtlasTreeClass:ResolveImage(basename)
	local mapped = self.imageMap[basename]
	if mapped and fileExists("TreeData/Atlas/Images/" .. mapped) then
		return "Atlas/Images/" .. mapped
	end
	if fileExists("TreeData/" .. self.treeVersion .. "/" .. basename) then
		return basename
	end
end

function AtlasTreeClass:LoadSheet(sheetData, cache)
	local basename = sheetData.filename:gsub("%?.*$", ""):gsub(".*/", "")
	local sheet = cache[basename]
	if sheet then
		return sheet
	end
	sheet = { }
	cache[basename] = sheet
	local imageName = self:ResolveImage(basename)
	if not imageName then
		return sheet
	end
	common.classes.PassiveTree.LoadImage(self, imageName, sheetData.filename, sheet, "CLAMP")
	sheet.width = sheetData.w or sheet.width
	sheet.height = sheetData.h or sheet.height
	return sheet
end

function AtlasTreeClass:LoadSprites(data)
	self.spriteMap = { }
	self.assets = { }
	local cache = { }
	local function addSheet(spriteType, sheetData)
		local sheet = self:LoadSheet(sheetData, cache)
		if not sheet.handle or not sheet.width or sheet.width == 0 then
			return
		end
		for name, coords in pairs(sheetData.coords) do
			self.spriteMap[name] = self.spriteMap[name] or { }
			local sprite = {
				handle = sheet.handle,
				width = coords.w,
				height = coords.h,
				[1] = coords.x / sheet.width,
				[2] = coords.y / sheet.height,
				[3] = (coords.x + coords.w) / sheet.width,
				[4] = (coords.y + coords.h) / sheet.height,
			}
			self.spriteMap[name][spriteType] = sprite
			if assetSpriteTypes[spriteType] then
				self.assets[name] = sprite
			end
		end
	end
	for spriteType, zooms in pairs(data.sprites or { }) do
		addSheet(spriteType, pickZoom(zooms))
	end
	for spriteType, sheets in pairs(data.skillSprites or { }) do
		addSheet(spriteType, sheets[#sheets])
	end
	for name in pairs(data.assets or { }) do
		local imageName = self:ResolveImage(name .. ".png")
		if imageName then
			local asset = { }
			common.classes.PassiveTree.LoadImage(self, imageName, "", asset, "CLAMP")
			asset[1], asset[2], asset[3], asset[4] = 0, 0, 1, 1
			self.assets[name] = asset
		end
	end
	if self.key ~= latestAtlasTreeVersion then
		local latest = main:LoadAtlasTree(latestAtlasTreeVersion)
		for name, asset in pairs(latest.assets) do
			if not self.assets[name] then
				self.assets[name] = asset
			end
		end
	end
end

function AtlasTreeClass:BuildGroups(data)
	self.groups = { }
	for id, group in pairs(data.groups) do
		local maxOrbit = 0
		for _, orbit in ipairs(group.orbits or { }) do
			maxOrbit = m_max(maxOrbit, orbit)
		end
		self.groups[tonumber(id)] = {
			id = tonumber(id),
			x = group.x,
			y = group.y,
			maxOrbit = maxOrbit,
			isProxy = group.isProxy,
			background = group.background,
		}
	end
end

function AtlasTreeClass:BuildNodes(data)
	self.nodes = { }
	self.masteries = { }
	self.wormholes = { }
	local startIds = { }
	local root = data.nodes.root
	if root then
		for _, id in ipairs(root.out or { }) do
			startIds[tonumber(id)] = true
		end
	end
	for idText, raw in pairs(data.nodes) do
		local id = idText == "root" and 0 or tonumber(idText)
		local node = {
			id = id,
			dn = raw.name or "",
			icon = raw.icon,
			sd = splitLines(raw.stats),
			reminderText = raw.reminderText and splitLines(raw.reminderText),
			flavourText = raw.flavourText and splitLines(raw.flavourText),
			g = raw.group,
			o = raw.orbit,
			oidx = raw.orbitIndex,
			outIds = raw.out or { },
			inIds = raw["in"] or { },
			linked = { },
		}
		if raw.variantEffects then
			node.variants = { }
			for _, variant in ipairs(raw.variantEffects) do
				t_insert(node.variants, { effect = variant.effect, sd = splitLines(variant.stats) })
			end
		end
		if id == 0 or (startIds[id] and node.dn == "" and #node.sd == 0) then
			node.type = "Root"
		elseif raw.isMastery then
			node.type = "Mastery"
			t_insert(self.masteries, node)
		elseif raw.isWormhole then
			node.type = "Wormhole"
			t_insert(self.wormholes, node)
		elseif raw.isKeystone then
			node.type = "Keystone"
		elseif raw.isNotable then
			node.type = "Notable"
		else
			node.type = "Normal"
		end
		local group = id ~= 0 and self.groups[raw.group]
		if group then
			node.group = group
			local angles = self.orbitAnglesByOrbit[node.o + 1]
			node.angle = angles and angles[node.oidx + 1] or 0
			local radius = self.orbitRadii[node.o + 1] or 0
			node.x = group.x + m_sin(node.angle) * radius
			node.y = group.y - m_cos(node.angle) * radius
		end
		node.sprites = node.icon and self.spriteMap[node.icon]
		local size = nodeArtWidth[node.type] * 1.33
		node.size = size
		node.rsq = size * size
		self.nodes[id] = node
	end
	local function link(a, b)
		if a and b and a ~= b and a.type ~= "Mastery" and b.type ~= "Mastery" then
			a.linkedSet = a.linkedSet or { }
			b.linkedSet = b.linkedSet or { }
			if not a.linkedSet[b] then
				a.linkedSet[b] = true
				b.linkedSet[a] = true
				t_insert(a.linked, b)
				t_insert(b.linked, a)
			end
		end
	end
	for _, node in pairs(self.nodes) do
		for _, otherId in ipairs(node.outIds) do
			link(node, self.nodes[tonumber(otherId)])
		end
		for _, otherId in ipairs(node.inIds) do
			link(node, self.nodes[tonumber(otherId)])
		end
	end
	self.rootNode = self.nodes[0]
	self.startNodes = { }
	self.nodesByName = { }
	for _, node in pairs(self.nodes) do
		if node.type == "Root" then
			t_insert(self.startNodes, node)
		elseif node.dn ~= "" and node.x then
			self.nodesByName[node.dn] = self.nodesByName[node.dn] or { }
			t_insert(self.nodesByName[node.dn], node)
		end
		node.linkedSet = nil
	end
end

function AtlasTreeClass:BuildConnectors()
	self.connectors = { }
	for _, node in pairs(self.nodes) do
		for _, other in ipairs(node.linked) do
			if node.id < other.id and node.id ~= 0 and other.id ~= 0 and node.x and other.x
				and not (node.type == "Wormhole" and other.type == "Wormhole") then
				local connector = { node1 = node, node2 = other }
				if node.g == other.g and node.o == other.o and node.o > 0 then
					local a1, a2 = node.angle, other.angle
					local diff = a2 - a1
					if diff > m_pi then
						diff = diff - 2 * m_pi
					elseif diff < -m_pi then
						diff = diff + 2 * m_pi
					end
					connector.arc = {
						x = node.group.x,
						y = node.group.y,
						radius = self.orbitRadii[node.o + 1],
						startAngle = a1,
						sweep = diff,
					}
				end
				t_insert(self.connectors, connector)
			end
		end
	end
end

function AtlasTreeClass:GetNodesWithSameName(node)
	if node.type == "Root" or node.dn == "" then
		return { }
	end
	return self.nodesByName[node.dn] or { }
end

function AtlasTreeClass:GetWormholePartners(node)
	local partners = { }
	if node.type == "Wormhole" then
		for _, other in ipairs(self.wormholes) do
			if other.dn == node.dn then
				t_insert(partners, other)
			end
		end
	end
	return partners
end
