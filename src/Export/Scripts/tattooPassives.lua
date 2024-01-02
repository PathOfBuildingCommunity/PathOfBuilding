if not loadStatFile then
	dofile("statdesc.lua")
end
loadStatFile("stat_descriptions.txt")
loadStatFile("passive_skill_stat_descriptions.txt")

local out = io.open("../Data/TattooPassives.lua", "w")

local stats = dat("Stats")
local passiveSkillOverridesDat = dat("passiveskilloverrides")
local passiveSkillTattoosDat = dat("passiveskilltattoos")
local clientStrings = dat("ClientStrings")

local tattoo_PASSIVE_GROUP = 1e9

---@type fun(thing:string|table|number):string
function stringify(thing)
	if type(thing) == 'string' then
		return thing
	elseif type(thing) == 'number' then
		return ""..thing;
	elseif type(thing) == 'table' then
		local s = "{";
		for k,v in pairs(thing) do
			s = s.."\n\t"
			if type(k) == 'number' then
				s = s.."["..k.."] = "
			else
				s = s.."[\""..k.."\"] = "
			end
			if type(v) == 'string' then
				s = s.."\""..stringify(v).."\", "
			else
				if type(v) == "boolean" then
					v = v and "true" or "false"
				end
				val = stringify(v)..", "
				if type(v) == "table" then
					val = string.gsub(val, "\n", "\n\t")
				end
				s = s..val;
			end
		end
		return s.."\n}"
	end
end

function parsePassiveStats(datFileRow, keystonePassive)
	local descOrders = {}
	for idx,statKey in pairs(datFileRow.Stats) do
		local refRow = type(statKey) == "number" and statKey + 1 or statKey._rowIndex
		local statId = stats:ReadCell(refRow, 1)
		local range = datFileRow["Stat"..idx]

		local stat = {}
		stat[statId] = {
			["min"] = range,
			["max"] = range,
			["index"] = idx
		}
		-- Describing stats here to get the orders
		local statLines, orders = describeStats(stat)
		stat[statId].statOrder = orders[1]
		keystonePassive.stats[statId] = stat[statId]
		for i, line in ipairs(statLines) do
			table.insert(keystonePassive.sd, line)
			descOrders[line] = orders[i]
		end
	end
	-- Have to re-sort since we described the stats earlier
	table.sort(keystonePassive.sd, function(a, b) return descOrders[a] < descOrders[b] end)
end

function parseStats(datFileRow, tattooPassive)
	local descOrders = {}
	local stat = {}
	for idx,statKey in pairs(datFileRow.StatsKeys) do
		local refRow = type(statKey) == "number" and statKey + 1 or statKey._rowIndex
		local statId = stats:ReadCell(refRow, 1)
		local range = datFileRow["StatValues"]

		stat[statId] = {
			["min"] = range[idx],
			["max"] = range[idx]
		}
	end
	-- Describing stats here to get the orders
	local statLines, orders = describeStats(stat)
	tattooPassive.stats = stat
	for i, line in ipairs(statLines) do
		table.insert(tattooPassive.sd, line)
		descOrders[line] = orders[i]
	end
	-- Have to re-sort since we described the stats earlier
	table.sort(tattooPassive.sd, function(a, b) return descOrders[a] < descOrders[b] end)
end

---@type table <string, table> @this is the structure used to generate the final data file Data/TattooPassives
local data = { }
data.nodes = { }
data.groups = { }

for i=1, passiveSkillOverridesDat.rowCount do
	---@type table<string, boolean|string|number>
	local datFileRow = {}
	for j=1,#passiveSkillOverridesDat.cols-1 do
		local key = passiveSkillOverridesDat.spec[j].name
		datFileRow[key] = passiveSkillOverridesDat:ReadCell(i, j)
	end

	local tattooDatRow = {}
	for j=1, #passiveSkillTattoosDat.cols-1 do
		local key = passiveSkillTattoosDat.spec[j].name
		tattooDatRow[key] = passiveSkillTattoosDat:ReadCell(i <= passiveSkillTattoosDat.rowCount and i or passiveSkillTattoosDat.rowCount, j)
	end
	---@type table<string, boolean|string|number|table>
	local tattooPassiveNode = {}
	-- id
	tattooPassiveNode.id = datFileRow.Id

	-- display text
	tattooPassiveNode.sd = {}
	tattooPassiveNode.stats = {}
	tattooPassiveNode.isTattoo = true
	-- is keystone
	tattooPassiveNode.ks = false
	-- is notable
	tattooPassiveNode['not'] = tattooDatRow.NodeTarget.Type == "Notable" and true or false
	-- is mastery wheel
	tattooPassiveNode.m = false

	tattooPassiveNode.targetType = tattooDatRow.NodeTarget.Type
	tattooPassiveNode.targetValue = tattooDatRow.NodeTarget.Value

	-- These have 0 if they don't apply, which doesn't make sense for MaximumConnected
	if datFileRow.MinimumConnected > 0 then
		local text = clientStrings:GetRow("Id", "PassiveSkillTattooAdjacentRequirementLower").Text
		tattooPassiveNode.reminderText = { [1] = text:gsub("{}", datFileRow.MinimumConnected) }
	end
	tattooPassiveNode.MinimumConnected = datFileRow.MinimumConnected
	if datFileRow.MaximumConnected > 0 then
		local text = clientStrings:GetRow("Id", "PassiveSkillTattooAdjacentRequirementUpper").Text
		tattooPassiveNode.reminderText = { [1] = text:gsub("{}", datFileRow.MaximumConnected) }
	end
	tattooPassiveNode.MaximumConnected = (datFileRow.MaximumConnected > 0) and datFileRow.MaximumConnected or 100

	local limitText
	if datFileRow.Limit then
		limitText = clientStrings:GetRow("Id", "PassiveSkillTattooLimitReminder").Text:gsub("{0}", datFileRow.Limit.Description)
	end

	tattooPassiveNode.activeEffectImage = datFileRow.Background .. ".png"
	if datFileRow.TattooType.Id == "KeystoneTattoo" then
		-- is keystone
		tattooPassiveNode.ks = true
		datFileRow = datFileRow.PassiveSkill
		parsePassiveStats(datFileRow, tattooPassiveNode)
	else
		parseStats(datFileRow, tattooPassiveNode)
	end

	-- node name
	tattooPassiveNode.dn = datFileRow.Name
	-- icon
	tattooPassiveNode.icon = datFileRow.Icon:gsub("%.dds$", ".png")
	tattooPassiveNode.sd[#tattooPassiveNode.sd + 1] = limitText

	if datFileRow.Id ~= "DisplayRandomKeystone" then
		data.nodes[datFileRow.Name] = tattooPassiveNode
	end
end

data.groups[tattoo_PASSIVE_GROUP] = {
    ["x"] = -6500,
    ["y"] = -6500,
    ["oo"] = {},
    ["n"] = {}
}

for k,v in pairs(data.nodes) do
	table.insert(data.groups[tattoo_PASSIVE_GROUP].n, k)
end

str = stringify(data)

out:write("-- This file is automatically generated, do not edit!\n-- Item data (c) Grinding Gear Games\n\n")
out:write("return "..str)
out:close()

print("tattoo passives exported.")
