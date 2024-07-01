-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
local function splitLines(s)
	if s:sub(-1)~="\n" then s=s.."\n" end
	return s:gmatch("(.-)\n")
end

local function buildOutputMap(filecontent)
	local playerOutput = {}
    local minionOutput = {}
	for line in splitLines(filecontent) do
		local key, val = line:match('PlayerStat stat="(.-)" value="(.-)"')
        if key then
		    playerOutput[key] = val
		else
			local key,val = line:match('MinionStat stat="(.-)" value="(.-)"')
			if key then
				minionOutput[key] = val
			end
        end
	end
	return playerOutput, minionOutput
end

local headhnd = io.open(arg[1], "r")
local devhnd = io.open(arg[2], "r")

if headhnd and devhnd then
	local playerHEADOutput, minionHEADOutput = buildOutputMap(headhnd:read("*a"))
	local playerDEVOutput, minionDEVOutput = buildOutputMap(devhnd:read("*a"))
	local mismatch = {}
    local mismatchFound = false
	for key, val in pairs(playerHEADOutput) do
		if not playerDEVOutput[key] or playerDEVOutput[key] ~= val then
			mismatch[key] = {devOutput = playerDEVOutput[key], headOutput = val}
            mismatchFound = true
		end
	end
	for key, val in pairs(playerDEVOutput) do
		if not mismatch[key] and (not playerHEADOutput[key] or playerHEADOutput[key] ~= val) then
			mismatch[key] = {headOutput = playerHEADOutput[key], devOutput = val}
            mismatchFound = true
		end
	end
	for key, val in pairs(mismatch) do
		print(key .. " Mismatch in player outputs: ")
		print("\t" .."head Output: " .. tostring(val["headOutput"]))
		print("\t" .."dev Output: " .. tostring(val["devOutput"]))
	end
	mismatch = {}
	for key, val in pairs(minionHEADOutput) do
		if not minionDEVOutput[key] or minionDEVOutput[key] ~= val then
			mismatch[key] = {devOutput = minionDEVOutput[key], headOutput = val}
            mismatchFound = true
		end
	end
	for key, val in pairs(minionDEVOutput) do
		if not mismatch[key] and (not minionHEADOutput[key] or minionHEADOutput[key] ~= val) then
			mismatch[key] = {headOutput = minionHEADOutput[key], devOutput = val}
            mismatchFound = true
		end
	end
	for key, val in pairs(mismatch) do
		print(key .. " Mismatch in minion outputs: ")
		print("\t" .."head Output: " .. tostring(val["headOutput"]))
		print("\t" .."dev Output: " .. tostring(val["devOutput"]))
	end
    if mismatchFound then
        os.exit(1) -- Make the exit codes of the script match the exit codes of the diff utility
    end
else
    os.exit(2)
end