local function runtime(path)
	local file = assert(io.open(path, "r"))
	local value = assert(tonumber(file:read("*a")))
	file:close()
	return value
end
local head, base = runtime(arg[1]), runtime(arg[2])
if base > 0 and math.abs(head / base - 1) >= 0.1 then
	print(string.format("%s CPU time: %.1f ms -> %.1f ms (%+.0f%%)", arg[3], base, head, (head / base - 1) * 100))
	os.exit(1)
end
