-- Path of Building
--
-- Module: Mod Tools
-- Various functions for dealing with modifier lists and databases.
--

local t_insert = table.insert
local m_floor = math.floor
local m_abs = math.abs

modLib = { }

modLib.parseMod = LoadModule("Modules/ModParser")

-- Break modifier name into namespace and mod name
local spaceLookup = { }
function modLib.getSpaceName(modName)
	if not spaceLookup[modName] then
		local spaceName, mod = modName:match("^([^_]+)_(.+)$")
		if not spaceName then
			spaceName = "global"
			mod = modName
		end
		spaceLookup[modName] = { spaceName, mod }
		return spaceName, mod
	end
	return unpack(spaceLookup[modName])
end

-- Extract condition name from modifier name
local condLookup = { }
function modLib.getCondName(modName)
	if not condLookup[modName] then
		local isNot, condName, mod = modName:match("^(n?o?t?)(%w+)_(.+)$")
		isNot = (isNot == "not")
		condLookup[modName] = { isNot, condName, mod }
		return isNot, condName, mod
	end
	return unpack(condLookup[modName])
end

-- Magic table to check modifier type: 
-- "MORE" = multiplicative (contains 'More' in the modifier name)
-- "INC" = additive (contains 'Inc' in the modifier name)
modLib.getModType = { }
modLib.getModType.__index = function(t, modName)
	local val
	if modName:match("More$") then
		val = "MORE"
	elseif modName:match("Inc$") then
		val = "INC"
	else
		val = "BASE"
	end
	t[modName] = val
	return val
end
setmetatable(modLib.getModType, modLib.getModType)

-- Merge modifier with existing mod list, respecting additivity/multiplicativity
function modLib.listMerge(modList, modName, modVal)
	if modList[modName] then
		if type(modVal) == "boolean" then
			modList[modName] = modList[modName] or modVal
		elseif type(modVal) == "function" then
			local orig = modList[modName]
			modList[modName] = function(...) orig(...) modVal(...) end
		elseif modLib.getModType[modName] == "MORE" then
			modList[modName] = modList[modName] * modVal
		else
			modList[modName] = modList[modName] + modVal
		end
	else
		modList[modName] = modVal
	end
end

-- Scale and merge modifier with existing mod list
function modLib.listScaleMerge(modList, modName, modVal, scale)
	if type(modVal) == "number" then
		local type = modLib.getModType[modName]
		if type == "MORE" then
			modLib.listMerge(modList, modName, 1 + m_floor((modVal - 1) * scale * 100) / 100)
		elseif type == "INC" or m_floor(modVal) == modVal then -- Yes, there's a nasty hack there, move along
			modLib.listMerge(modList, modName, m_floor(modVal * scale))
		else
			modLib.listMerge(modList, modName, modVal * scale)
		end
	else
		modLib.listMerge(modList, modName, modVal)
	end
end


-- Unmerge modifier from existing mod list, respecting additivity/multiplicativity
function modLib.listUnmerge(modList, modName, modVal)
	if type(modVal) == "boolean" then
		if modVal == true then
			modList[modName] = false
		end
	elseif type(modVal) == "string" then
		modList[modName] = nil
	elseif modLib.getModType[modName] == "MORE" then
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
function modLib.dbMerge(modDB, spaceName, modName, modVal)
	if not spaceName then
		spaceName, modName = modLib.getSpaceName(modName)
	elseif spaceName == "" then
		spaceName = "global"
	end
	if not modDB[spaceName] then
		modDB[spaceName] = { }
	end
	modLib.listMerge(modDB[spaceName], modName, modVal)
end

-- Scale and merge modifier with mod database
function modLib.dbScaleMerge(modDB, spaceName, modName, modVal, scale)
	if not spaceName then
		spaceName, modName = modLib.getSpaceName(modName)
	elseif spaceName == "" then
		spaceName = "global"
	end
	if not modDB[spaceName] then
		modDB[spaceName] = { }
	end
	modLib.listScaleMerge(modDB[spaceName], modName, modVal, scale)
end

-- Scale and merge modifier list with mod database
function modLib.dbScaleMergeList(modDB, modList, scale)
	if scale and scale ~= 1 then
		for k, modVal in pairs(modList) do
			local spaceName, modName = modLib.getSpaceName(k)
			if not modDB[spaceName] then
				modDB[spaceName] = { }
			end
			modLib.listScaleMerge(modDB[spaceName], modName, modVal, scale)
		end
	else
		modLib.dbMergeList(modDB, modList)
	end
end

-- Unmerge modifier from mod database
function modLib.dbUnmerge(modDB, spaceName, modName, modVal)
	if not spaceName then
		spaceName, modName = modLib.getSpaceName(modName)
	elseif spaceName == "" then
		spaceName = "global"
	end
	if not modDB[spaceName] then
		modDB[spaceName] = { }
	end
	modLib.listUnmerge(modDB[spaceName], modName, modVal)
end

-- Merge modifier list with mod database
function modLib.dbMergeList(modDB, modList)
	for k, modVal in pairs(modList) do
		local spaceName, modName = modLib.getSpaceName(k)
		if not modDB[spaceName] then
			modDB[spaceName] = { }
		end
		modLib.listMerge(modDB[spaceName], modName, modVal)
	end
end

-- Unmerge modifier list from mod database
function modLib.dbUnmergeList(modDB, modList)
	for k, modVal in pairs(modList) do
		local spaceName, modName = modLib.getSpaceName(k)
		if not modDB[spaceName] then
			modDB[spaceName] = { }
		end
		modLib.listUnmerge(modDB[spaceName], modName, modVal)
	end
end

-- Print modifier list to the console
function modLib.listPrint(modList, tab)
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
function modLib.dbPrint(modDB)
	local spaceNames = { }
	for k in pairs(modDB) do
		t_insert(spaceNames, k)
	end
	table.sort(spaceNames)
	for _, spaceName in pairs(spaceNames) do
		if type(modDB[spaceName]) ~= "table" then
			ConPrintf("%s = %s", spaceName, modDB[spaceName])
		elseif next(modDB[spaceName]) then
			ConPrintf("%s = {", spaceName)
			modLib.listPrint(modDB[spaceName], 1)
			ConPrintf("},")
		else
			ConPrintf("%s = { },", spaceName)
		end
	end
end