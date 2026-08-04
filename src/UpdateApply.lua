#@
-- Path of Building
--
-- Module: Update Apply
-- Applies updates.
--
local opFileName = ...

local maxOpenAttempts = 1000

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
		local dstFile, openErr
		-- The destination may be transiently locked (e.g. antivirus on Windows); retry, but bounded
		for _ = 1, maxOpenAttempts do
			dstFile, openErr = io.open(dst, "w+b")
			if dstFile then
				break
			end
		end
		if not dstFile then
			srcFile:close()
		end
		assert(dstFile, "couldn't write "..dst..(openErr and (": "..openErr) or ""))
		dstFile:write(srcFile:read("*a"))
		dstFile:close()
		srcFile:close()
		os.remove(src)
	elseif op == "delete" then
		local file = args:match('"(.*)"')
		print("Deleting '"..file.."'")
		os.remove(file)
	elseif op == "chmod" then
		local file = args:match('"(.*)"'):gsub("{space}", " ")
		print("Marking '"..file.."' as executable")
		os.execute('chmod +x "'..file..'"')
	elseif op == "start" then
		local target = args:match('"(.*)"')
		SpawnProcess(target)
	end
end
