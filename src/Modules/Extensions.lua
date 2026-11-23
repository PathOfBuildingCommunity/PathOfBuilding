-- Path of Building
--
-- Module: Extensions
-- Loads optional, user-installed extension modules from the "Extensions" folder inside the user data folder.
-- Path of Building ships no extensions. If the folder doesn't exist or is empty, nothing is loaded and nothing changes.
--
-- An extension is a Lua file that returns a table. Each of these fields is optional:
--   name                  Display name used in error messages (defaults to the file name)
--   OnFrame(ext)          Called once per frame from main:OnFrame
--   OnBuildFrame(ext, build)  Called once per frame while a build is open, after any pending recalculation
--
-- An extension that errors while loading is skipped. One that errors in a callback is disabled for the rest of the session.
-- In both cases the error is printed to the console and Path of Building carries on.
--
local ipairs = ipairs
local pcall = pcall
local t_insert = table.insert
local t_sort = table.sort

local extensions = {
	list = { },
}

function extensions:Load(folder)
	self.list = { }
	if not folder then
		return
	end
	local fileNames = { }
	local handle = NewFileSearch(folder.."*.lua")
	while handle do
		t_insert(fileNames, handle:GetFileName())
		if not handle:NextFile() then
			break
		end
	end
	t_sort(fileNames)
	for _, fileName in ipairs(fileNames) do
		local func, err = loadfile(folder..fileName)
		local ok, ext
		if func then
			ok, ext = pcall(func)
			if ok and type(ext) ~= "table" then
				ok, ext = false, "it must return a table"
			end
		else
			ok, ext = false, err
		end
		if ok then
			ext.name = ext.name or fileName
			t_insert(self.list, ext)
			ConPrintf("Loaded extension '%s'", ext.name)
		else
			ConPrintf("Skipped extension '%s': %s", fileName, tostring(ext))
		end
	end
end

function extensions:Call(event, ...)
	for _, ext in ipairs(self.list) do
		if not ext.disabled and ext[event] then
			local ok, err = pcall(ext[event], ext, ...)
			if not ok then
				ext.disabled = true
				ConPrintf("Disabled extension '%s' after an error in %s: %s", ext.name, event, tostring(err))
			end
		end
	end
end

return extensions
