
local t_insert = table.insert

mod = { }

mod.parseMod = LoadModule("Modules/ModParser")

-- Break modifier name into namespace and mod name
local spaceLookup = { }
function mod.getSpaceName(modName)
	if not spaceLookup[modName] then
		local space, mod = modName:match("^([^_]+)_(.+)$")
		if not space then
			space = "global"
			mod = modName
		end
		spaceLookup[modName] = { space, mod }
		return space, mod
	end
	return unpack(spaceLookup[modName])
end

-- Extract condition name from modifier name
local condLookup = { }
function mod.getCondName(modName)
	if not condLookup[modName] then
		local isNot, condName, mod = modName:match("^(n?o?t?)(%w+)_(.+)$")
		isNot = (isNot == "not")
		condLookup[modName] = { isNot, condName, mod }
		return isNot, condName, mod
	end
	return unpack(condLookup[modName])
end

-- Magic table to check if a modifier is multiplicative (contains 'More' in the modifier name)
mod.isModMult = { }
mod.isModMult.__index = function(t, modName)
	local val = (modName:match("More") ~= nil)
	t[modName] = val
	return val
end
setmetatable(mod.isModMult, mod.isModMult)

-- Merge modifier with existing mod list, respecting additivity/multiplicativity
function mod.listMerge(modList, modName, modVal)
	if modList[modName] then
		if type(modVal) == "boolean" then
			modList[modName] = modList[modName] or modVal
		elseif type(modVal) == "function" then
			local orig = modList[modName]
			modList[modName] = function(...) orig(...) modVal(...) end
		elseif mod.isModMult[modName] then
			modList[modName] = modList[modName] * modVal
		else
			modList[modName] = modList[modName] + modVal
		end
	else
		modList[modName] = modVal
	end
end

-- Unmerge modifier from existing mod list, respecting additivity/multiplicativity
function mod.listUnmerge(modList, modName, modVal)
	if type(modVal) == "boolean" then
		if modVal == true then
			modList[modName] = false
		end
	elseif type(modVal) == "string" then
		modList[modName] = nil
	elseif mod.isModMult[modName] then
		if modVal == 0 then
			modList[modName] = 1
		else
			modList[modName] = (modList[modName] or 1) / modVal
		end
	else
		modList[modName] = (modList[modName] or 0) - modVal
	end
end

-- Merge modifier with mod database
function mod.dbMerge(modDB, spaceName, modName, modVal)
	if not spaceName then
		spaceName, modName = mod.getSpaceName(modName)
	elseif spaceName == "" then
		spaceName = "global"
	end
	if not modDB[spaceName] then
		modDB[spaceName] = { }
	end
	mod.listMerge(modDB[spaceName], modName, modVal)
end

-- Unmerge modifier from mod database
function mod.dbUnmerge(modDB, spaceName, modName, modVal)
	if not spaceName then
		spaceName, modName = mod.getSpaceName(modName)
	elseif spaceName == "" then
		spaceName = "global"
	end
	if not modDB[spaceName] then
		modDB[spaceName] = { }
	end
	mod.listUnmerge(modDB[spaceName], modName, modVal)
end

-- Merge modifier list with mod database
function mod.dbMergeList(modDB, modList)
	for k, modVal in pairs(modList) do
		local spaceName, modName = mod.getSpaceName(k)
		if not modDB[spaceName] then
			modDB[spaceName] = { }
		end
		mod.listMerge(modDB[spaceName], modName, modVal)
	end
end

-- Unmerge modifier list from mod database
function mod.dbUnmergeList(modDB, modList)
	for k, modVal in pairs(modList) do
		local spaceName, modName = mod.getSpaceName(k)
		if not modDB[spaceName] then
			modDB[spaceName] = { }
		end
		mod.listUnmerge(modDB[spaceName], modName, modVal)
	end
end

-- Print modifier list to the console
function mod.listPrint(modList, tab)
	local names = { }
	for k in pairs(modList) do
		if type(k) == "string" then
			t_insert(names, k)
		end
	end
	table.sort(names)
	for _, name in pairs(names) do
		ConPrintf("%s%s = %s", string.rep("\t", tab or 0), name, modList[name])
	end
end

-- Print modifier database to the console
function mod.dbPrint(modDB)
	local spaceNames = { }
	for k in pairs(modDB) do
		t_insert(spaceNames, k)
	end
	table.sort(spaceNames)
	for _, spaceName in pairs(spaceNames) do
		ConPrintf("%s = {", spaceName)
		mod.listPrint(modDB[spaceName], 1)
		ConPrintf("},")
	end
end