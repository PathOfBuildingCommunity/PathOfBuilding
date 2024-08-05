local headHnd = io.open(arg[1], "r")
local devHnd = io.open(arg[2], "r")
local baseName = arg[3]

if headHnd and devHnd then
	local headRuntime = tonumber(headHnd:read("*a"))
	local devRuntime = tonumber(devHnd:read("*a"))
	local runtimeDifference = math.abs(headRuntime / devRuntime - 1)
	if runtimeDifference >= 0.1 then
		print(string.format("%s Took longer than 10%% to calculate (%d%%)", baseName, math.floor(runtimeDifference*100)))
		print("\thead runtime: " .. headRuntime .. "ms")
		print("\tdev Output: " .. devRuntime .. "ms")
		os.exit(1) -- Make the exit codes of the script match the exit codes of the diff utility
	end
else
	os.exit(2)
end