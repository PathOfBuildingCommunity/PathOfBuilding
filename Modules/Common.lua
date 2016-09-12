-- Path of Building
--
-- Module: Common
-- Libaries, functions and classes used by various modules.
--

local pairs = pairs
local ipairs = ipairs
local m_abs = math.abs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local s_format = string.format

common = { }

-- External libraries
common.curl = require("lcurl")
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

-- Quick hack to convert JSON to valid lua
function jsonToLua(json)
	return json:gsub("%[","{"):gsub("%]","}"):gsub('"(%d[%d%.]*)":','[%1]='):gsub('"([^"]+)":','["%1"]='):gsub("\\/","/"):gsub("{(%w+)}","{[0]=%1}")
end

-- Check if mouse is currently inside area defined by region.x, region.y, region.width, region.height
function isMouseInRegion(region)
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= region.x and cursorX < region.x + region.width and cursorY >= region.y and cursorY < region.y + region.height
end

-- Make a copy of a table and all subtables
function copyTable(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			out[k] = copyTable(v)
		else
			out[k] = v
		end
	end
	return out
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

-- Formats 1234.56 -> "1,234.5" [dec=1]
function formatNumSep(val, dec)
	dec = dec or 0
	val = val or 0
	local neg = val < 0
	val = m_floor(m_abs(val * 10 ^ dec))
	local str = string.reverse(s_format("%.0f", val))
	if #str < (dec + 1) then
		str = str .. string.rep("0", dec + 1 - #str)
	end
	local ret = ""
	local pDec, pThou = dec, 3
	for ci = 1, #str do
		local c = str:sub(ci, ci)
		ret = c .. ret
		if pDec > 0 then
			pDec = pDec - 1
			if pDec == 0 then
				ret = "." .. ret
			end
		else
			pThou = pThou - 1
			if pThou == 0 and ci < #str then
				ret = "," .. ret
				pThou = 3
			end
		end
	end
	return (neg and "-" or "") .. ret
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

