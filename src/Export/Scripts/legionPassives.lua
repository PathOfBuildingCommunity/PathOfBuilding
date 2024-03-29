if not loadStatFile then
	dofile("statdesc.lua")
end
loadStatFile("passive_skill_stat_descriptions.txt")

-- This table lists errors in the ggpk dat files
local datErrors = {
	["templar_notable_minimum_frenzy_charge"] = {
		["match"] = {
			["Name"] = "Powerful Faith",
		},
		["replace"] = {
			["Id"] = "templar_notable_minimum_power_charge",
		},
	},
	["templar_notable_minimum_power_charge"] = {
		["match"] = {
			["Name"] = "Frenzied Faith",
		},
		["replace"] = {
			["Id"] = "templar_notable_minimum_frenzy_charge",
		},
	},
}

local fixDatErrors = function(row)
	if datErrors[row.Id] then
		for field, value in pairs(datErrors[row.Id].match) do
			if row[field] ~= value then return end
		end
		for field, value in pairs(datErrors[row.Id].replace) do
			row[field] = value
		end
	end
end

local out = io.open("../Data/TimelessJewelData/LegionPassives.lua", "w")

local stats = dat("Stats")
local alternatePassiveSkillDat = dat("AlternatePassiveSkills")
local alternatePassiveAdditionsDat = dat("AlternatePassiveAdditions")

local LEGION_PASSIVE_GROUP = 1e9

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

function parseStats(datFileRow, legionPassive)
	local descOrders = {}
	for idx,statKey in pairs(datFileRow.StatsKeys) do
		local refRow = type(statKey) == "number" and statKey + 1 or statKey._rowIndex
		local statId = stats:ReadCell(refRow, 1)
		local range = datFileRow["Stat"..idx]

		local stat = {}
		stat[statId] = {
			["min"] = range[1],
			["max"] = range[2],
			["index"] = idx
		}
		-- Describing stats here to get the orders
		local statLines, orders = describeStats(stat)
		stat[statId].statOrder = orders[1]
		legionPassive.stats[statId] = stat[statId]
		for i, line in ipairs(statLines) do
			table.insert(legionPassive.sd, line)
			descOrders[line] = orders[i]
		end
	end
	-- Have to re-sort since we described the stats earlier
	table.sort(legionPassive.sd, function(a, b) return descOrders[a] < descOrders[b] end)
	local sortedStats = {}
	for stat in pairs(legionPassive.stats) do
		table.insert(sortedStats, stat)
	end
	-- Finally get what we want, sorted stats by order
	table.sort(sortedStats, function(a, b) return legionPassive.stats[a].statOrder < legionPassive.stats[b].statOrder  end)
	legionPassive.sortedStats = sortedStats
end

---@type table <string, table> @this is the structure used to generate the final data file Data/TimelessJewelData/LegionPassives
local data = { }
data.nodes = { }
data.groups = { }
data.additions = { }
local ksCount = -1

for i=1, alternatePassiveSkillDat.rowCount do
	---@type table<string, boolean|string|number>
	local datFileRow = {}
	for j=1,#alternatePassiveSkillDat.cols-1 do
		local key = alternatePassiveSkillDat.spec[j].name
		datFileRow[key] = alternatePassiveSkillDat:ReadCell(i, j)
	end
	fixDatErrors(datFileRow)
	---@type table<string, boolean|string|number|table>
	local legionPassiveNode = {}
	-- id
	legionPassiveNode.id = datFileRow.Id
	-- icon
	legionPassiveNode.icon = datFileRow.DDSIcon
	-- is keystone
	legionPassiveNode.ks = isValueInTable(datFileRow.PassiveType, 4) and true or false
	if legionPassiveNode.ks then
		ksCount = ksCount + 1
	end
	-- is notable
	legionPassiveNode['not'] = isValueInTable(datFileRow.PassiveType, 3) and true or false
	-- node name
	legionPassiveNode.dn = datFileRow.Name
	-- is mastery wheel
	legionPassiveNode.m = false
	-- self explanatory
	legionPassiveNode.isJewelSocket = false
	legionPassiveNode.isMultipleChoice = false
	legionPassiveNode.isMultipleChoiceOption = false
	legionPassiveNode.passivePointsGranted = 0
	-- class starting node
	legionPassiveNode.spc = {}
	-- display text
	legionPassiveNode.sd = {}
	legionPassiveNode.stats = {}

	parseStats(datFileRow, legionPassiveNode)

	if legionPassiveNode.id == "vaal_keystone_2_v2" then -- Immortal Ambition needs to be manually added
        legionPassiveNode.sd = {
            [1] = "Energy Shield starts at zero",
            [2] = "Cannot Recharge or Regenerate Energy Shield",
            [3] = "Lose 5% of Energy Shield per second",
            [4] = "Life Leech effects are not removed at Full Life",
            [5] = "Life Leech effects Recover Energy Shield instead while on Full Life"
        }
    end

	-- Node group, legion nodes don't use it, so we set it arbitrarily
	legionPassiveNode.g = LEGION_PASSIVE_GROUP
	-- 
	-- group orbit distance
	legionPassiveNode.o = legionPassiveNode.ks and 4 or 3
	legionPassiveNode.oidx = legionPassiveNode.ks and ksCount * 3 or math.floor(math.random() * 1e5)
	-- attributes granted 
	legionPassiveNode.sa = 0
	legionPassiveNode.da = 0
	legionPassiveNode.ia = 0
	-- connected nodes
	legionPassiveNode.out = {}
	legionPassiveNode["in"] = {}

	data.nodes[i] = legionPassiveNode
end

data.groups[LEGION_PASSIVE_GROUP] = {
    ["x"] = -6500,
    ["y"] = -6500,
    ["oo"] = {},
    ["n"] = {}
}

for k,v in pairs(data.nodes) do
	table.insert(data.groups[LEGION_PASSIVE_GROUP].n, k)
end

for i=1, alternatePassiveAdditionsDat.rowCount do
	---@type table<string, boolean|string|number>
	local datFileRow = {};
	for j=1,#alternatePassiveAdditionsDat.cols-1 do
		local key = alternatePassiveAdditionsDat.spec[j].name
		datFileRow[key] = alternatePassiveAdditionsDat:ReadCell(i, j)
	end

	---@type table<string, boolean|string|number|table>
	local legionPassiveAddition = {}

	-- id
	legionPassiveAddition.id = datFileRow.Id
	-- Additions have no name, so we construct one for the UI (also, Lua patterns are too limiting :( )
	legionPassiveAddition.dn = string.gsub(string.gsub(string.gsub(datFileRow.Id, "_", " "), "^%w* ", ""), "^%w* ", "")
	legionPassiveAddition.dn = legionPassiveAddition.dn:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
	-- stat descriptions
	legionPassiveAddition.sd = {}
	legionPassiveAddition.stats = {}

	parseStats(datFileRow, legionPassiveAddition)
	data.additions[i] = legionPassiveAddition
end

str = stringify(data)

out:write("-- This file is automatically generated, do not edit!\n-- Item data (c) Grinding Gear Games\n\n")
out:write("return "..str)
out:close()

print("Legion passives exported.")
