-- Path of Building
--
-- Class: Passive Tree
-- Passive skill tree class.
--
local launch = ...

local pairs = pairs
local ipairs = ipairs
local m_min = math.min
local m_max = math.max
local m_pi = math.pi
local m_sin = math.sin
local m_cos = math.cos
local m_tan = math.tan
local m_sqrt = math.sqrt
local t_insert = table.insert

local TreeClass = common.NewClass("PassiveTree", function(self)
	MakeDir("TreeData")

	ConPrintf("Loading JSON...")
	local treeText, classText
	local treeFile = io.open("TreeData/tree.json", "r")
	local classFile = io.open("TreeData/classes.json", "r")
	if treeFile and classFile then
		treeText = treeFile:read("*a")
		treeFile:close()
		classText = classFile:read("*a")
		classFile:close()
	else
		if treeFile then
			treeFile:close()
		elseif classFile then
			classFile:close()
		end
		ConPrintf("Downloading JSON...")
		local page = ""
		local easy = common.curl.easy()
		easy:setopt_url("https://www.pathofexile.com/passive-skill-tree/")
		easy:setopt_writefunction(function(data)
			page = page..data 
			return true 
		end)
		easy:perform()
		easy:close()
		treeText = page:match("var passiveSkillTreeData = (%b{})")
		treeFile = io.open("TreeData/tree.json", "w")
		treeFile:write(treeText)
		treeFile:close()
		classText = page:match("ascClasses: (%b{})")
		classFile = io.open("TreeData/classes.json", "w")
		classFile:write(classText)
		classFile:close()
	end
	for k, v in pairs(common.json.decode(treeText)) do
		self[k] = v
	end
	self.classes = { }
	for id, data in pairs(common.json.decode(classText)) do
		self.classes[tonumber(id)] = data
		data.classes["0"] = { name = "None" }
	end

	self.size = m_min(self.max_x - self.min_x, self.max_y - self.min_y) * 1.1

	ConPrintf("Loading assets...")
	for name, data in pairs(self.assets) do
		local imgName = "TreeData/"..name..".png"
		self:CacheImage(imgName, data["0.3835"] or data["1"])
		data.handle = NewImageHandle()
		data.handle:Load(imgName)
		data.width, data.height = data.handle:ImageSize()
	end

	local spriteMap = { }
	local spriteSheets = { }
	for type, data in pairs(self.skillSprites) do
		local maxZoom = data[#data]
		local sheet = spriteSheets[maxZoom.filename]
		if not sheet then
			sheet = { }
			local imgName = "TreeData/"..maxZoom.filename
			self:CacheImage(imgName, self.imageRoot.."build-gen/passive-skill-sprite/"..maxZoom.filename)
			sheet.handle = NewImageHandle()
			sheet.handle:Load(imgName, "CLAMP")
			sheet.width, sheet.height = sheet.handle:ImageSize()
			spriteSheets[maxZoom.filename] = sheet
		end
		for name, coords in pairs(maxZoom.coords) do
			if not spriteMap[name] then
				spriteMap[name] = { }
			end
			spriteMap[name][type] = { 
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

	local nodeOverlay = {
		normal = {
			alloc = "PSSkillFrameActive",
			path = "PSSkillFrameHighlighted",
			unalloc = "PSSkillFrame",
			allocAscend = "PassiveSkillScreenAscendancyFrameSmallAllocated",
			pathAscend = "PassiveSkillScreenAscendancyFrameSmallCanAllocate",
			unallocAscend = "PassiveSkillScreenAscendancyFrameSmallNormal"
		},
		notable = {
			alloc = "NotableFrameAllocated",
			path = "NotableFrameCanAllocate",
			unalloc = "NotableFrameUnallocated",
			allocAscend = "PassiveSkillScreenAscendancyFrameLargeAllocated",
			pathAscend = "PassiveSkillScreenAscendancyFrameLargeCanAllocate",
			unallocAscend = "PassiveSkillScreenAscendancyFrameLargeNormal"
		},
		keystone = { 
			alloc = "KeystoneFrameAllocated",
			path = "KeystoneFrameCanAllocate",
			unalloc = "KeystoneFrameUnallocated"
		},
		socket = {
			alloc = "JewelFrameAllocated",
			path = "JewelFrameCanAllocate",
			unalloc = "JewelFrameUnallocated"
		}
	}
	for type, data in pairs(nodeOverlay) do
		local size = self.assets[data.unalloc].width * 1.33
		data.size = size
		data.rsq = size * size
	end

	ConPrintf("Building nodes...")
	local nodeMap = { }
	local orbitMult = { [0] = 0, m_pi / 3, m_pi / 6, m_pi / 6, m_pi / 20 }
	local orbitDist = { [0] = 0, 82, 162, 335, 493 }
	for _, node in ipairs(self.nodes) do
		nodeMap[node.id] = node
		if node.spc[1] then
			node.type = "class"
		elseif node.isAscendancyStart then
			node.type = "ascendClass"
		elseif node.m then
			node.type = "mastery"
		elseif node.isJewelSocket then
			node.type = "socket"
		elseif node.ks then
			node.type = "keystone"
		elseif node["not"] then
			node.type = "notable"
		else
			node.type = "normal"
		end
		node.sprites = spriteMap[node.icon]
		node.overlay = nodeOverlay[node.type]
		node.linkedId = { }

		local group = self.groups[tostring(node.g)]
		group.ascendancyName = node.ascendancyName
		if node.isAscendancyStart then
			group.isAscendancyStart = true
		end
		node.group = group
		node.angle = node.oidx * orbitMult[node.o]
		local dist = orbitDist[node.o]
		node.x = group.x + m_sin(node.angle) * dist
		node.y = group.y - m_cos(node.angle) * dist

		node.mods = { }
		node.modKey = ""
		local i = 1
		while node.sd[i] do
			local line = node.sd[i]
			local list, extra
			if line:match("\n") then
				list, extra = modLib.parseMod(line:gsub("\n", " "))
				if list and not extra then
					node.sd[i] = line:gsub("\n", " ")
				else
					table.remove(node.sd, i)
					local si = i
					for subLine in line:gmatch("[^\n]+") do
						table.insert(node.sd, si, subLine)
						si = si + 1
					end
					list, extra = modLib.parseMod(node.sd[i])
				end
			else
				list, extra = modLib.parseMod(line)
			end
			if not list then
				node.unknown = true
			elseif extra then
				node.extra = true
			else
				for k, v in pairs(list) do
					node.modKey = node.modKey..k.."="..tostring(v)..","
				end
			end
			node.mods[i] = { list = list, extra = extra }
			i = i + 1
		end
	end

	ConPrintf("Building connections...")
	self.conn = { }
	for _, node in ipairs(self.nodes) do
		for _, otherId in ipairs(node.out) do
			local other = nodeMap[otherId]
			t_insert(node.linkedId, otherId)
			t_insert(other.linkedId, node.id)
			if node.type ~= "class" and other.type ~= "class" and node.ascendancyName == other.ascendancyName then
				t_insert(self.conn, self:BuildConnector(node, other))
			end
		end
	end

	self.classNameMap = { }
	self.ascendNameMap = { ["None"] = { classId = 0, ascendClassId = 0 } }
	for classId, class in pairs(self.classes) do
		self.classNameMap[class.name] = classId
		for ascendClassId, ascendClass in pairs(class.classes) do
			self.ascendNameMap[ascendClass.name] = {
				classId = classId,
				ascendClassId = tonumber(ascendClassId)
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
	for _, node in ipairs(self.nodes) do
		if node.type == "class" then
			local class = self.classes[node.spc[1]]
			class.startNodeId = node.id
			node.startArt = classArt[node.spc[1]]
			for _, otherId in ipairs(node.linkedId) do
				local other = nodeMap[otherId]
				if other.type == "ascendClass" then
					for _, ascendClass in pairs(class.classes) do
						if other.ascendancyName == ascendClass.name then
							ascendClass.startNodeId = otherId
							break
						end
					end
				end
			end
		end
	end
end)

function TreeClass:CacheImage(imgName, url)
	local imgFile = io.open(imgName, "r")
	if imgFile then
		imgFile:close()
	else
		ConPrintf("Downloading '%s'...", imgName)
		imgFile = io.open(imgName, "wb")
		local easy = common.curl.easy()
		easy:setopt_url(url)
		easy:setopt_writefunction(imgFile)
		easy:perform()
		easy:close()
		imgFile:close()
	end
end

function TreeClass:BuildConnector(node1, node2)
	local conn = {
		ascendancyName = node1.ascendancyName,
		nodeId1 = node1.id,
		nodeId2 = node2.id,
		c = { }
	}
	if node1.g == node2.g and node1.o == node2.o then
		conn.type = "Orbit" .. node1.o
		if node1.angle > node2.angle then
			node1, node2 = node2, node1
		end
		local span = node2.angle - node1.angle
		if span > m_pi then
			node1, node2 = node2, node1
			span = m_pi * 2 - span
		end
		local clipAngle = m_pi / 4 - span / 2
		local p = 1 - m_max(m_tan(clipAngle), 0)
		local angle = node1.angle - clipAngle
		local norm, act = { }, { }
		for tbl, state in pairs({[norm] = "Normal", [act] = "Active"}) do
			local art = self.assets[conn.type..state]
			local size = art.width * 2 * 1.33
			local oX, oY = size * m_sqrt(2) * m_sin(angle + m_pi/4), size * m_sqrt(2) * -m_cos(angle + m_pi/4)
			local cX, cY = node1.group.x + oX, node1.group.y + oY
			tbl[1], tbl[2] = node1.group.x, node1.group.y
			tbl[3], tbl[4] = cX + (size * m_sin(angle) - oX) * p, cY + (size * -m_cos(angle) - oY) * p
			tbl[5], tbl[6] = cX, cY
			tbl[7], tbl[8] = cX + (size * m_cos(angle) - oX) * p, cY + (size * m_sin(angle) - oY) * p
		end
		conn.vert = { Normal = norm, Intermediate = norm, Active = act }
		conn.c[9], conn.c[10] = 1, 1
		conn.c[11], conn.c[12] = 0, p
		conn.c[13], conn.c[14] = 0, 0
		conn.c[15], conn.c[16] = p, 0
	else
		conn.type = "LineConnector"
		local art = self.assets.LineConnectorNormal
		local vX, vY = node2.x - node1.x, node2.y - node1.y
		local dist = m_sqrt(vX * vX + vY * vY)
		local scale = art.height * 1.33 / dist
		local nX, nY = vX * scale, vY * scale
		local endS = dist / (art.width * 1.33)
		conn[1], conn[2] = node1.x - nY, node1.y + nX
		conn[3], conn[4] = node1.x + nY, node1.y - nX
		conn[5], conn[6] = node2.x + nY, node2.y - nX
		conn[7], conn[8] = node2.x - nY, node2.y + nX
		conn.vert = { Normal = conn, Intermediate = conn, Active = conn }
		conn.c[9], conn.c[10] = 0, 1
		conn.c[11], conn.c[12] = 0, 0
		conn.c[13], conn.c[14] = endS, 0
		conn.c[15], conn.c[16] = endS, 1
	end
	return conn
end
