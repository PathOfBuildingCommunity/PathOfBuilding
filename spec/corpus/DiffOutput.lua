-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
local function splitLines(s)
	if s:sub(-1)~="\n" then s=s.."\n" end
	return s:gmatch("(.-)\n")
end

local function buildOutputMap(filecontent)
	local playerOutput = {}
    local minionOutput = {}
	for line in splitLines(filecontent) do
		local stat = line:match('<PlayerStat%s+([^>]+)')
		local key, val = stat and stat:match('stat="(.-)"'), stat and stat:match('value="(.-)"')
        if key then
		    playerOutput[key] = val
		else
			local stat = line:match('<MinionStat%s+([^>]+)')
			local key, val = stat and stat:match('stat="(.-)"'), stat and stat:match('value="(.-)"')
			if key then
				minionOutput[key] = val
			end
        end
	end
	return playerOutput, minionOutput
end

local function readBuild(path)
    local file = assert(io.open(path, "r"))
    local player, minion = buildOutputMap(file:read("*a"))
    file:close()
    return player, minion
end

local function compare(actor, before, after)
    local function record(key)
        assert(not key:find("[%c]"), "Invalid stat name")
        print(table.concat({ arg[3], actor, key, before[key] or "", after[key] or "" }, "\t"))
    end
    for key, value in pairs(before) do
        if after[key] ~= value then record(key) end
    end
    for key in pairs(after) do
        if before[key] == nil then record(key) end
    end
end

local playerAfter, minionAfter = readBuild(arg[1])
local playerBefore, minionBefore = readBuild(arg[2])
compare("Player", playerBefore, playerAfter)
compare("Minion", minionBefore, minionAfter)
