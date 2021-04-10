#@
-- Path of Building
--
-- Module: Update Apply
-- Applies updates.
--
local opFileName = ...

print("Applying update...")
local opFile = io.open(opFileName, "r")
if not opFile then
	print("No operations list present.\n")
	return
end
local lines = { }
for line in opFile:lines() do
	table.insert(lines, line)
end
opFile:close()
os.remove(opFileName)
for _, line in ipairs(lines) do
	local op, args = line:match("(%a+) ?(.*)")
	if op == "move" then
		local src, dst = args:match('"(.*)" "(.*)"')
		dst = dst:gsub("{space}", " ")
		print("Updating '"..dst.."'")
		local srcFile = io.open(src, "rb")
		assert(srcFile, "couldn't open "..src)
		local dstFile
		while not dstFile do
			dstFile = io.open(dst, "w+b")
		end
		if dstFile then
			dstFile:write(srcFile:read("*a"))
			dstFile:close()
		end
		srcFile:close()
		os.remove(src)
	elseif op == "delete" then
		local file = args:match('"(.*)"')
		print("Deleting '"..file.."'")
		os.remove(file)
	elseif op == "start" then
		local target = args:match('"(.*)"')
		SpawnProcess(target)
	end
end
