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

tree.skillSprites.keystoneActive[4].coords["Art/2DArt/SkillIcons/passives/CritAilments.png"] = {
	x = 583,
	y = 1019,
	w = 53,
	h = 54,
}
tree.skillSprites.keystoneInactive[4].coords["Art/2DArt/SkillIcons/passives/CritAilments.png"] = {
	x = 583,
	y = 1019,
	w = 53,
	h = 54,
}
tree.skillSprites.notableActive[4].coords["Art/2DArt/SkillIcons/passives/BleedPoison.png"] = {
	x = 532,
	y = 927,
	w = 38,
	h = 38,
}
tree.skillSprites.notableInactive[4].coords["Art/2DArt/SkillIcons/passives/BleedPoison.png"] = {
	x = 532,
	y = 927,
	w = 38,
	h = 38,
}

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
		nodes = { },
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
		group.nodes[n] = node.id
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

local out = io.open("Tree/tree.lua", "w")
out:write('return ')
writeLuaTable(out, tree)
out:close()

os.execute("xcopy Tree\\tree.lua ..\\TreeData\\3_0\\ /Y /Q")

print("Passive skill graph generated.")

--[[out:write('groups = {\n')
for i, group in ipairs(groups) do
	out:write('\t['..i..'] = {\n')
	out:write('\t\tx = ', group.x, ',\n')
	out:write('\t\ty = ', group.y, ',\n')
	out:write('\t\too = { ')
	for i = 0, 4 do
		if group.oo[i] then
			out:write('['..i..'] = true, ')
		end
	end
	out:write('},\n')
	out:write('\t\tn = { ', table.concat(group.nodes, ', '), ' },\n')
	out:write('\t},\n')
end
out:write('}\n')
out:write('nodes = {\n')
for i, node in pairs(nodes) do
	out:write('\t{\n')
	out:write('\t\tid = ', node.id, ',\n')
	local passive = PassiveSkills[PassiveSkills.PassiveSkillGraphId(node.id)[1] ]
	out:write('\t\ticon = "', passive.Icon_DDSFile:gsub("dds$","png"), '",\n')
	out:write('\t\tks = ', tostring(passive.IsKeystone), ',\n')
	out:write('\t\t["not"] = ', tostring(passive.IsNotable), ',\n')
	out:write('\t\tdn = "', passive.Name, '",\n')
	out:write('\t\tm = ', tostring(passive.IsJustIcon), ',\n')
	out:write('\t\tisJewelSocket = ', tostring(passive.IsJewelSocket), ',\n')
	out:write('\t\tisMultipleChoice = ', tostring(passive.IsMultipleChoice), ',\n')
	out:write('\t\tisMultipleChoiceOption = ', tostring(passive.IsMultipleChoiceOption), ',\n')
	out:write('\t\tpassivePointsGranted = ', passive.SkillPointsGranted, ',\n')
	if #passive.FlavourText > 0 then
		out:write('\t\tflavourText = { ', qFmt(passive.FlavourText), ' },\n')
	end
	if passive.AscendancyKey then
		out:write('\t\tascendancyName = "', Ascendancy[passive.AscendancyKey].Name, '",\n')
		out:write('\t\tisAscendancyStart = ', tostring(passive.IsAscendancyStartingNode), ',\n')
	end
	if passive.Reminder_ClientStringsKeys[1] then
		out:write('\t\treminderText = { ')
		for _, csKey in ipairs(passive.Reminder_ClientStringsKeys) do
			out:write(qFmt(ClientStrings[csKey].Text), ', ')
		end
		out:write('},\n')
	end
	out:write('\t\tspc = { ')
	if passive.CharactersKeys[1] then
		out:write(passive.CharactersKeys[1] + 1, ' ')
	end
	out:write('},\n')
	out:write('\t\tsd = { ')
	local sa, da, ia = 0, 0, 0
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
				sa = sa + val
			end
			if stat.Id:match("^base_.*dexterity") then
				da = da + val
			end
			if stat.Id:match("^base_.*intelligence") then
				ia = ia + val
			end
			stats[stat.Id] = { min = val, max = val }
		end
		out:write('"', table.concat(describeStats(stats), '", "'), '", ')
	end
	out:write('},\n')
	out:write('\t\tg = ', node.g, ',\n')
	out:write('\t\to = ', node.o, ',\n')
	out:write('\t\toidx = ', node.oidx, ',\n')
	out:write('\t\tsa = ', sa, ',\n')
	out:write('\t\tda = ', da, ',\n')
	out:write('\t\tia = ', ia, ',\n')
	out:write('\t\tout = { ', table.concat(node.out, ', '), ' },\n')
	out:write('\t},\n')
end
out:write('}\n')
out:close()]]