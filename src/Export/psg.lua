require "imlua"
require "imlua_process"

local function bits(int, s, e)
	return bit.band(bit.rshift(int, s), 2 ^ (e - s + 1) - 1)
end
local function toFloat(int)
	local s = (-1) ^ bits(int, 31, 31)
	local e = bits(int, 23, 30) - 127
	if e == -127 then
		return 0 * s
	end
	local m = 1
	for i = 0, 22 do
		m = m + bits(int, i, i) * 2 ^ (i - 23)
	end
	return s * m * 2 ^ e
end
local function getInt(f)
	local int = f:read(4)
	return int:byte(1) + int:byte(2) * 256 + int:byte(3) * 65536 + int:byte(4) * 16777216
end
local function getFloat(f)
	return toFloat(getInt(f))
end

local tree = dofile("Tree/tree_in.lua")

tree.nodes = { }
tree.groups = { }
tree.skillSprites = { }

local sheetW = 38 * 19
local function newSheet(name, width, height)
	return {
		name = name,
		width = width,
		height = height,
		totalHeight = height,
		x = 0,
		y = 0,
		sprites = { },
	}
end
local function addToSheet(sheet, icon)
	if sheet.sprites[icon] then
		return
	end
	if sheet.x + sheet.width > sheetW then
		sheet.x = 0
		sheet.y = sheet.y + sheet.height
		sheet.totalHeight = sheet.totalHeight + sheet.height
	end
	sheet.sprites[icon] = {
		icon = icon,
		x = sheet.x,
		y = sheet.y,
	}
	sheet.x = sheet.x + sheet.width
end
local sheets = {
	newSheet("normal", 27, 27),
	newSheet("notable", 38, 38),
	newSheet("keystone", 53, 54),
}
local masterySheet = newSheet("mastery", 99, 99)

printf("Processing skill graph...")

local psg = io.open("Tree/PassiveSkillGraph.psg", "rb")
psg:read(7)
for rn = 1, getInt(psg) do
	getInt(psg)
end
for g = 1, getInt(psg) do
	local group = {
		x = getFloat(psg),
		y = getFloat(psg),
		oo = { },
		n = { },
	}
	table.insert(tree.groups, group)
	for n = 1, getInt(psg) do
		local node = {
			id = getInt(psg),
			g = g,
			o = getInt(psg),
			oidx = getInt(psg),
			out = { },
			sa = 0,
			da = 0,
			ia = 0,
		}
		table.insert(tree.nodes, node)
		group.oo[node.o] = true
		group.n[n] = node.id
		for o = 1, getInt(psg) do
			node.out[o] = getInt(psg)
		end
		local passive = PassiveSkills[PassiveSkills.PassiveSkillGraphId(node.id)[1]]
		node.icon = passive.Icon_DDSFile:gsub("dds$","png")
		node.ks = passive.IsKeystone
		node["not"] = passive.IsNotable
		node.dn = passive.Name
		node.m = passive.IsJustIcon
		node.isJewelSocket = passive.IsJewelSocket
		node.isMultipleChoice = passive.IsMultipleChoice
		node.isMultipleChoiceOption = passive.IsMultipleChoiceOption
		node.passivePointsGranted = passive.SkillPointsGranted
		if #passive.FlavourText > 0 then
			node.flavourText = { passive.FlavourText }
		end
		if passive.AscendancyKey then
			node.ascendancyName = Ascendancy[passive.AscendancyKey].Name
			node.isAscendancyStart = passive.IsAscendancyStartingNode
		end
		if passive.Reminder_ClientStringsKeys[1] then
			node.reminderText = { }
			for _, csKey in ipairs(passive.Reminder_ClientStringsKeys) do
				table.insert(node.reminderText, ClientStrings[csKey].Text)
			end
		end
		node.spc = { }
		if passive.CharactersKeys[1] then
			node.spc[0] = Characters[passive.CharactersKeys[1]].IntegerId
		end
		if node.ks then
			addToSheet(sheets[3], node.icon)
		elseif node["not"] then
			addToSheet(sheets[2], node.icon)
		elseif node.m then
			addToSheet(masterySheet, node.icon)
		elseif not node.isJewelSocket and not node.spc[0] and not node.isAscendancyStart then
			addToSheet(sheets[1], node.icon)
		end
		node.sd = { }
		if passive.StatsKeys[1] > 0 then
			if passive.GrantedBuff_BuffDefinitionsKey then
				loadStatFile("passive_skill_aura_stat_descriptions.txt")
			else
				loadStatFile("passive_skill_stat_descriptions.txt")
			end
			local stats = { }
			for i, statKey in ipairs(passive.StatsKeys) do
				local val = passive["Stat"..i.."Value"]
				local stat = Stats[statKey]
				if stat.Id:match("^base_.*strength") then
					node.sa = node.sa + val
				end
				if stat.Id:match("^base_.*dexterity") then
					node.da = node.da + val
				end
				if stat.Id:match("^base_.*intelligence") then
					node.ia = node.ia + val
				end
				stats[stat.Id] = { min = val, max = val }
			end
			for _, line in ipairs(describeStats(stats)) do
				table.insert(node.sd, line)
			end
		end
	end
end
psg:close()

printf("Building sprite sheets...")

local imgActive = im.ImageCreate(sheetW, sheets[1].totalHeight + sheets[2].totalHeight + sheets[3].totalHeight, im.RGB, im.BYTE)
local imgInactive = imgActive:Duplicate()
local offsetY = 0
for _, sheet in ipairs(sheets) do
	local coords = { }
	for icon, sprite in pairs(sheet.sprites) do
		coords[icon] = {
			w = sheet.width,
			h = sheet.height,
			x = sprite.x,
			y = sprite.y + offsetY,
		}
		local imgYPos = imgActive:Height() - coords[icon].y - sheet.height
		local iconFile = im.FileOpen(icon:gsub("Art/2DArt/SkillIcons/passives","tree/passives"))
		local imageIcon = iconFile:LoadImage(0)
		iconFile:Close()
		local _, imageIconSmall = im.ProcessResizeNew(imageIcon, sheet.width, sheet.height, 3)
		im.ProcessInsert(imgActive, imageIconSmall, imgActive, sprite.x, imgYPos)
		for row = 0, imageIconSmall:Height() - 1 do
			local rRow = imageIconSmall[0][row]
			local gRow = imageIconSmall[1][row]
			local bRow = imageIconSmall[2][row]
			for col = 0, imageIconSmall:Width() - 1 do		
				local r = rRow[col] * 0.58
				local g = gRow[col] * 0.58
				local b = bRow[col] * 0.58
				local a = (math.max(r, g, b) + math.min(r, g, b)) / 2
				rRow[col] = a + (r - a) * 0.43
				gRow[col] = a + (g - a) * 0.43
				bRow[col] = a + (b - a) * 0.43
			end
		end
		im.ProcessInsert(imgInactive, imageIconSmall, imgInactive, sprite.x, imgYPos)
	end
	tree.skillSprites[sheet.name.."Active"] = {
		{ filename = "skills-3.jpg", coords = coords }
	}
	tree.skillSprites[sheet.name.."Inactive"] = {
		{ filename = "skills-disabled-3.jpg", coords = coords }
	}
	offsetY = offsetY + sheet.totalHeight
end
im.FileImageSave("tree/skills-3.jpg", "JPEG", imgActive)
im.FileImageSave("tree/skills-disabled-3.jpg", "JPEG", imgInactive)

local imgMastery = im.ImageCreate(sheetW, masterySheet.totalHeight, im.RGB, im.BYTE)
imgMastery:AddAlpha()
do
	local coords = { }
	for icon, sprite in pairs(masterySheet.sprites) do
		coords[icon] = {
			w = masterySheet.width,
			h = masterySheet.height,
			x = sprite.x,
			y = sprite.y,
		}
		local imgYPos = imgMastery:Height() - coords[icon].y - masterySheet.height
		local iconFile = im.FileOpen(icon:gsub("Art/2DArt/SkillIcons/passives","tree/passives"))
		local imageIcon = iconFile:LoadImage(0)
		iconFile:Close()
		local _, imageIconSmall = im.ProcessResizeNew(imageIcon, masterySheet.width, masterySheet.height, 3)
		im.ProcessInsert(imgMastery, imageIconSmall, imgMastery, sprite.x, imgYPos)
	end
	tree.skillSprites.mastery = {
		{ filename = "groups-3.png", coords = coords }
	}
end
im.FileImageSave("tree/groups-3.png", "PNG", imgMastery)

local out = io.open("Tree/tree.lua", "w")
out:write('return ')
writeLuaTable(out, tree)
out:close()

os.execute("xcopy Tree\\tree.lua ..\\TreeData\\ /Y /Q")
os.execute("xcopy Tree\\*-3* ..\\TreeData\\ /Y /Q")

print("Passive skill graph generated.")
