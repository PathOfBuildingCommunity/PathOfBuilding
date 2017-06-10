-- Path of Building
--
-- Module: Common
-- Libaries, functions and classes used by various modules.
--

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_abs = math.abs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local s_format = string.format

common = { }

-- External libraries
common.curl = require("lcurl.safe")
common.xml = require("xml")
common.base64 = require("base64")

-- Class library
common.classes = { }
local function addSuperParents(class, parent)
	for _, superParent in pairs(parent._parents) do
		class._superParents[superParent] = true
		if superParent._parents then
			addSuperParents(class, superParent)
		end
	end
end
-- NewClass("<className>"[, "<parentClassName>"[, "<parentClassName>" ...]], constructorFunc)
function common.NewClass(className, ...)
	local class = { }
	common.classes[className] = class
	class.__index = class
	class._className = className
	local numVarArg = select("#", ...)
	class._constructor = select(numVarArg, ...)
	if numVarArg > 1 then
		-- Build list of parent classes
		class._parents = { }
		for i = 1, numVarArg - 1 do
			local parentName = select(i, ...)
			if not common.classes[parentName] then
				error("Parent class '"..parentName.."' of class '"..className.."' not defined")
			end
			class._parents[i] = common.classes[parentName]
		end
		-- Build list of all classes directly or indirectly inherited by this class
		class._superParents = { }
		addSuperParents(class, class)
		-- Set up inheritance
		if #class._parents == 1 then
			-- Single inheritance
			setmetatable(class, class._parents[1]) 
		else
			-- Multiple inheritance
			setmetatable(class, {
				__index = function(self, key)
					for _, parent in ipairs(class._parents) do
						local val = parent[key]
						if val ~= nil then
							return val
						end
					end
				end,
			})
		end
	end
	return class
end
function common.New(className, ...)
	local class = common.classes[className]
	if not class then
		error("Class '"..className.."' not defined")
	end
	if not class._constructor then
		error("Class '"..className.."' has no constructor")
	end
	local object = setmetatable({ }, class)
	object.Object = object
	if class._parents then
		-- Add parent and superparent class proxies
		object._parentInit = { }
		for parent in pairs(class._superParents) do
			object[parent._className] = setmetatable({ }, {
				__index = function(self, key)
					local v = rawget(object, key)
					if v ~= nil then
						return v
					else
						return parent[key]
					end
				end,
				__newindex = object,
				__call = function(...)
					if not parent._constructor then
						error("Parent class '"..parent._className.."' of class '"..class._className.."' has no constructor")
					end
					if object._parentInit[parent] then
						error("Parent class '"..parent._className.."' of class '"..class._className.."' has already been initialised")
					end
					parent._constructor(...)
					object._parentInit[parent] = true
				end,
			})
		end
	end
	class._constructor(object, ...)
	if class._parents then
		-- Check that the contructors for all parent and superparent classes have been called
		for parent in pairs(class._superParents) do
			if parent._constructor and not object._parentInit[parent] then
				error("Parent class '"..parent._className.."' of class '"..className.."' must be initialised")
			end
		end
	end
	return object
end

function codePointToUTF8(codePoint)
	if codePoint <= 0x7F then
		return string.char(codePoint)
	elseif codePoint <= 0x07FF then
		return string.char(0xC0 + bit.rshift(codePoint, 6), 0x80 + bit.band(codePoint, 0x3F))
	elseif codePoint <= 0xFFFF then
		return string.char(0xE0 + bit.rshift(codePoint, 12), 0x80 + bit.band(bit.rshift(codePoint, 6), 0x3F), 0x80 + bit.band(codePoint, 0x3f))
	else
		return "?"
	end
end

-- Quick hack to convert JSON to valid lua
function jsonToLua(json)
	return json:gsub("%[","{"):gsub("%]","}"):gsub('"(%d[%d%.]*)":','[%1]='):gsub('"([^"]+)":','["%1"]='):gsub("\\/","/"):gsub("{(%w+)}","{[0]=%1}")
		:gsub("\\u(%x%x%x%x)",function(hex) return codePointToUTF8(tonumber(hex,16)) end)
end

-- Check if mouse is currently inside area defined by region.x, region.y, region.width, region.height
function isMouseInRegion(region)
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= region.x and cursorX < region.x + region.width and cursorY >= region.y and cursorY < region.y + region.height
end

-- Make a copy of a table and all subtables
do
	local subTableMap = { }
	function copyTable(tbl, noRecurse, isSubTable)
		local out = {}
		if not noRecurse then
			subTableMap[tbl] = out
		end
		for k, v in pairs(tbl) do
			if not noRecurse and type(v) == "table" then
				out[k] = subTableMap[v] or copyTable(v, false, true)
			else
				out[k] = v
			end
		end
		if not noRecurse and not isSubTable then
			wipeTable(subTableMap)
		end
		return out
	end
end

-- Wipe all keys from the table and return it, or return a new table if no table provided
function wipeTable(tbl)
	if not tbl then
		return { }
	end
	for k in pairs(tbl) do
		tbl[k] = nil
	end
	return tbl
end

-- Search a table for a value, and return the corresponding key
function isValueInTable(tbl, val)
	for k, v in pairs(tbl) do
		if val == v then
			return k
		end
	end
end

-- Search an array for a value, and return the corresponding array index
function isValueInArray(tbl, val)
	for i, v in ipairs(tbl) do
		if val == v then
			return i
		end
	end
end

-- Pretty-prints a table
function prettyPrintTable(tbl, pre)
	pre = pre or ""
	local outNames = { }
	for name in pairs(tbl) do
		t_insert(outNames, name)
	end
	table.sort(outNames)
	for _, name in ipairs(outNames) do
		if type(tbl[name]) == "table" then
			prettyPrintTable(tbl[name], pre .. name .. ".")
		else
			ConPrintf("%s%s = %s", pre, name, tostring(tbl[name]))
		end
	end
end

-- Rounds a number to the nearest <dec> decimal places
function round(val, dec)
	if dec then
		return m_floor(val * 10 ^ dec + 0.5) / 10 ^ dec
	else
		return m_floor(val + 0.5)
	end
end

-- Formats "1234.56" -> "1,234.5"
function formatNumSep(str)
	return str:gsub("(%d*)(%d%.?)", function(s, e)
		return s:reverse():gsub("(%d%d)(%d)","%1,%2"):reverse()..e
	end)
end
function getFormatNumSep(dec)
	return function(val)
		return formatNumSep(val, dec)
	end
end

-- Formats 1234.56 -> "1234.6" [dec=1]
function formatRound(val, dec)
	dec = dec or 0
	return m_floor(val * 10 ^ dec + 0.5) / 10 ^ dec
end
function getFormatRound(dec)
	return function(val)
		return formatRound(val, dec)
	end
end

-- Formats 12.3456 -> "1234.6%" [dec=1]
function formatPercent(val, dec)
	dec = dec or 0
	return m_floor((val or 0) * 100 * 10 ^ dec + 0.5) / 10 ^ dec .. "%"
end
function getFormatPercent(dec)
	return function(val)
		return formatPercent(val, dec)
	end
end

-- Formats 1234.56 -> "1234.5s" [dec=1]
function formatSec(val, dec)
	dec = dec or 0
	if val == 0 then
		return "0s"
	else
		return s_format("%."..dec.."fs", val)
	end
end
function getFormatSec(dec)
	return function(val)
		return formatSec(val, dec)
	end
end

function copyFile(srcName, dstName)
	local inFile, msg = io.open(srcName, "r")
	if not inFile then
		return nil, "Couldn't open '"..srcName.."': "..msg
	end
	local outFile, msg = io.open(dstName, "w")
	if not outFile then
		return nil, "Couldn't create '"..dstName.."': "..msg
	end
	outFile:write(inFile:read("*a"))
	inFile:close()
	outFile:close()
	return true
end