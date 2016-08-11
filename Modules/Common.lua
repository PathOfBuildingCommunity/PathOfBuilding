-- Path of Building
--
-- Module: Common
-- Libaries, functions and classes used by various modules.
--

local s_format = string.format
local m_abs = math.abs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local pairs = pairs
local ipairs = ipairs

common = { }

-- External libraries
common.curl = require("lcurl")
common.xml = require("xml")
common.base64 = require("base64")
common.newEditField = require("simplegraphic/editfield")

-- Class library
common.classes = { }
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
				error("Parent class '"..className.."' not defined")
			end
			class._parents[i] = common.classes[parentName]
		end
		if #class._parents == 1 then
			-- Single inheritance
			setmetatable(class, class._parents[1]) 
		else
			-- Multiple inheritance
			setmetatable(class, {
				__index = function(self, key)
					for _, parent in ipairs(class._parents) do
						local val = class._parents[key]
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
	if class._parents then
		-- Add parent class proxies
		for _, parent in pairs(class._parents) do
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
						error("Parent class '"..parent._className.."' of class '"..className.."' has no constructor")
					end
					parent._constructor(...)
				end,
			})
		end
	end
	class._constructor(object, ...)
	return object
end

-- UI Controls
LoadModule("Classes/EditControl")
LoadModule("Classes/ButtonControl")
LoadModule("Classes/DropDownControl")
LoadModule("Classes/ScrollBarControl")
LoadModule("Classes/SliderControl")

-- Process input events for a host object with a list of controls
function common.controlsInput(host, inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if host.selControl then
				host.selControl = host.selControl:OnKeyDown(event.key, event.doubleClick)
				inputEvents[id] = nil
			end
			if not host.selControl and event.key:match("BUTTON") then
				host.selControl = nil
				for _, control in pairs(host.controls) do
					if control.IsMouseOver and control:IsMouseOver() and control.OnKeyDown then
						host.selControl = control:OnKeyDown(event.key, event.doubleClick)
						inputEvents[id] = nil
						break
					end
				end
			end
		elseif event.type == "KeyUp" then
			if host.selControl then
				if host.selControl.OnKeyUp then
					host.selControl = host.selControl:OnKeyUp(event.key)
				end
				inputEvents[id] = nil
			else
				for _, control in pairs(host.controls) do
					if control.IsMouseOver and control:IsMouseOver() and control.OnKeyUp then
						control:OnKeyUp(event.key)
						inputEvents[id] = nil
						break
					end
				end
			end
		elseif event.type == "Char" then
			if host.selControl then
				if host.selControl.OnChar then
					host.selControl = host.selControl:OnChar(event.key)
				end
				inputEvents[id] = nil
			end
		end
	end	
end

-- Draw host object's controls
function common.controlsDraw(host, ...)
	for _, control in pairs(host.controls) do
		control:Draw(...)
	end
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

-- Formats 12.3456 -> "1234.5%" [dec=1]
function formatPercent(val, dec)
	dec = dec or 0
	return m_floor((val or 0) * 100 * 10 ^ dec) / 10 ^ dec .. "%"
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

