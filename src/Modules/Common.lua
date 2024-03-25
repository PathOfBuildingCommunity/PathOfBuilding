-- Path of Building
--
-- Module: Common
-- Libraries, functions and classes used by various modules.
--
local pairs = pairs
local ipairs = ipairs
local type = type
local t_insert = table.insert
local t_remove = table.remove
local m_abs = math.abs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil
local s_format = string.format
local s_char = string.char
local b_rshift = bit.rshift
local b_and = bit.band
local b_xor = bit.bxor

common = { }

-- External libraries
common.curl = require("lcurl.safe")
common.xml = require("xml")
common.base64 = require("base64")
common.sha1 = require("sha1")

-- Try to load a library return nil if failed. https://stackoverflow.com/questions/34965863/lua-require-fallback-error-handling
function prerequire(...)
	local status, lib = pcall(require, ...)
	if(status) then return lib end
	return nil
end

profiler = prerequire("lua-profiler")
profiling = false

if launch.devMode and profiler == nil then
	ConPrintf("Unable to Load Profiler")
end

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
local function getClass(className)
	local class = common.classes[className]
	if not class then
		LoadModule("Classes/"..className)
		class = common.classes[className]
		assert(class, "Class '"..className.."' not defined in class file")
	end
	return class
end
-- newClass("<className>"[, "<parentClassName>"[, "<parentClassName>" ...]], constructorFunc)
function newClass(className, ...)
	local class = { }
	common.classes[className] = class
	class.__index = class
	class.__call = function(obj, mix)
		for k, v in pairs(mix) do
			obj[k] = v
		end
		return obj
	end
	class._className = className
	local numVarArg = select("#", ...)
	class._constructor = select(numVarArg, ...)
	if numVarArg > 1 then
		-- Build list of parent classes
		class._parents = { }
		for i = 1, numVarArg - 1 do
			class._parents[i] = getClass(select(i, ...))
		end
		-- Build list of all classes directly or indirectly inherited by this class
		class._superParents = { }
		addSuperParents(class, class)
		-- Set up inheritance
		setmetatable(class, {
			__index = function(self, key)
				for _, parent in ipairs(class._parents) do
					local val = parent[key]
					if val ~= nil then
						self[key] = val
						return val
					end
				end
			end
		})
	end
	return class
end
function new(className, ...)
	local class = getClass(className)
	local object = setmetatable({ }, class)
	object.Object = object
	if class._parents then
		-- Add parent and superparent class proxies
		object._parentInit = { }
		for parent in pairs(class._superParents) do
			local proxyMeta = {
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
			}
			object[parent._className] = setmetatable(proxyMeta, proxyMeta)
		end
	end
	if class._constructor then
		class._constructor(object, ...)
	end
	if class._parents then
		-- Check that the constructors for all parent and superparent classes have been called
		for parent in pairs(class._superParents) do
			if parent._constructor and not object._parentInit[parent] then
				error("Parent class '"..parent._className.."' of class '"..className.."' must be initialised")
			end
		end
	end
	return object
end

function codePointToUTF8(codePoint)
	if codePoint >= 0xD800 and codePoint <= 0xDFFF then
		return "?"
	elseif codePoint <= 0x7F then
		return s_char(codePoint)
	elseif codePoint <= 0x07FF then
		return s_char(0xC0 + b_rshift(codePoint, 6), 0x80 + b_and(codePoint, 0x3F))
	elseif codePoint <= 0xFFFF then
		return s_char(0xE0 + b_rshift(codePoint, 12), 0x80 + b_and(b_rshift(codePoint, 6), 0x3F), 0x80 + b_and(codePoint, 0x3F))
	elseif codePoint <= 0x10FFFF then
		return s_char(0xF0 + b_rshift(codePoint, 18), 0x80 + b_and(b_rshift(codePoint, 12), 0x3F), 0x80 + b_and(b_rshift(codePoint, 6), 0x3F), 0x80 + b_and(codePoint, 0x3F))
	else
		return "?"
	end
end
function convertUTF16to8(text, offset)
	offset = offset or 1
	local out = { }
	local highSurr
	for i = offset, #text - 1, 2 do
		local codeUnit = text:byte(i) + text:byte(i+1) * 256
		if codeUnit == 0 then
			break
		elseif codeUnit >= 0xD800 and codeUnit <= 0xDBFF then
			highSurr = codeUnit - 0xD800
		elseif codeUnit >= 0xDC00 and codeUnit <= 0xDFFF then
			if highSurr then
				t_insert(out, codePointToUTF8(highSurr * 1024 + codeUnit - 0xDC00 + 0x010000))
				highSurr = nil
			end
		else
			t_insert(out, codePointToUTF8(codeUnit))
		end
	end
	return table.concat(out)
end
function codePointToUTF16(codePoint)
	if codePoint >= 0xD800 and codePoint <= 0xDFFF then
		return "?\z"
	elseif codePoint <= 0xFFFF then
		return s_char(b_and(codePoint, 0xFF), b_rshift(codePoint, 8))
	elseif codePoint <= 0x10FFFF then
		local highSurr = 0xD800 + b_rshift(codePoint - 0x10000, 10)
		local lowSurr = 0xDC00 + b_and(codePoint - 0x10000, 0x2FF)
		return s_char(b_and(highSurr, 0xFF), b_rshift(highSurr, 8), b_and(lowSurr, 0xFF), b_rshift(lowSurr, 8))
	else
		return "?\z"
	end
end
function convertUTF8to16(text, offset)
	offset = offset or 1
	local out = { }
	local codePoint = 0
	local codeUnitRemaining
	for i = offset, #text do
		local codeUnit = text:byte(i)
		if codeUnit == 0 then
			break
		elseif codeUnit <= 0x7F then
			table.insert(out, s_char(codeUnit, 0))
		elseif codeUnit >= 0xC2 and codeUnit <= 0xDF then
			codeUnitRemaining = 1
			codePoint = b_and(codeUnit, 0x1F)
		elseif codeUnit >= 0xE0 and codeUnit <= 0xEF then
			codeUnitRemaining = 2
			codePoint = b_and(codeUnit, 0x0F)
		elseif codeUnit >= 0xF0 and codeUnit <= 0xF4 then
			codeUnitRemaining = 3
			codePoint = b_and(codeUnit, 0x03)
		elseif codeUnit >= 0x80 and codeUnit <= 0xBF then
			if codeUnitRemaining then
				codePoint = bit.lshift(codePoint, 6) + b_and(codeUnit, 0x3F)
				codeUnitRemaining = codeUnitRemaining - 1
				if codeUnitRemaining == 0 then
					t_insert(out, codePointToUTF16(codePoint))
					codeUnitRemaining = nil
				end
			else
				t_insert(out, "?\z")
			end
		else 
			t_insert(out, "?\z")
		end
	end
	return table.concat(out)
end

--- Clean item text by removing or replacing unsupported or redundant characters or sequences
---@param text string
---@return string
function sanitiseText(text)
	if not text then return nil end
	-- Something something unicode support something grumble
	-- Only do these replacements if a char from 128-255 or '<' is found first
	return text:find("[\128-\255<]") and text
		:gsub("%b<>", "")
		:gsub("\226\128\144", "-") -- U+2010 HYPHEN
		:gsub("\226\128\145", "-") -- U+2011 NON-BREAKING HYPHEN
		:gsub("\226\128\146", "-") -- U+2012 FIGURE DASH
		:gsub("\226\128\147", "-") -- U+2013 EN DASH
		:gsub("\226\128\148", "-") -- U+2014 EM DASH
		:gsub("\226\128\149", "-") -- U+2015 HORIZONTAL BAR
		:gsub("\226\136\146", "-") -- U+2212 MINUS SIGN
		:gsub("\195\164", "a") -- U+00E4 LATIN SMALL LETTER A WITH DIAERESIS
		:gsub("\195\182", "o") -- U+00F6 LATIN SMALL LETTER O WITH DIAERESIS
		-- single-byte: Windows-1252 and similar
		:gsub("\150", "-") -- U+2013 EN DASH
		:gsub("\151", "-") -- U+2014 EM DASH
		:gsub("\228", "a") -- U+00E4 LATIN SMALL LETTER A WITH DIAERESIS
		:gsub("\246", "o") -- U+00F6 LATIN SMALL LETTER O WITH DIAERESIS
		-- unsupported
		:gsub("[\128-\255]", "?")
		or text
end

do
	local function toUnsigned(val)
		return val < 0 and val + 0x100000000 or val
	end
	local function murmurMix(val)
		val = toUnsigned(val)
		return bit.tobit(val * 0xE995 + b_and(val * 0x5BD1, 0xFFFF) * 0x10000)
	end
	function murmurHash2(key, seed)
		local len = #key
		local h = b_xor(seed or 0, len)
		local o = 1
		while len >= 4 do
			local k = bytesToInt(key, o)
			k = murmurMix(k)
			k = b_xor(k, b_rshift(k, 24))
			k = murmurMix(k)
			h = murmurMix(h)
			h = b_xor(h, k)
			o = o + 4
			len = len - 4
		end
		if len > 0 then
			h = b_xor(h, bytesToInt(key, o))
			h = murmurMix(h)
		end
		h = b_xor(h, b_rshift(h, 13))
		h = murmurMix(h)
		h = b_xor(h, b_rshift(h, 15))
		return toUnsigned(h)
	end
end

local function bits(int, s, e)
	return b_and(b_rshift(int, s), 2 ^ (e - s + 1) - 1)
end
function bytesToInt(b, o)
	return bit.tobit(bytesToUInt(b, o))
end
function bytesToUInt(b, o)
	o = o or 1
	return (b:byte(o + 0) or 0) + (b:byte(o + 1) or 0) * 256 + (b:byte(o + 2) or 0) * 65536 + (b:byte(o + 3) or 0) * 16777216
end
function bytesToUShort(b, o)
	o = o or 1
	return (b:byte(o + 0) or 0) + (b:byte(o + 1) or 0) * 256
end
function bytesToULong(b, o)
	o = o or 1
	return bytesToUInt(b, o) + bytesToUInt(b, o + 4) * 4294967296
end
function bytesToFloat(b, o)
	local int = bytesToInt(b, o)
	local s = (-1) ^ bits(int, 31, 31)
	local e = bits(int, 23, 30) - 127
	if e == -127 then
		return 0 * s
	end
	local m = 1
	for i = 0, 22 do
		m = m + bits(int, i, i) * 2 ^ (i - 23)
	end
	return s * m * 2 ^ e
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

-- Write a Lua table to file
local function qFmt(s)
	return '"'..s:gsub("\n","\\n"):gsub("\"","\\\"")..'"'
end
function writeLuaTable(out, t, indent)
	out:write('{')
	if indent then
		out:write('\n')
	end
	local keyList = { }
	for k, v in pairs(t) do
		t_insert(keyList, k)
	end
	table.sort(keyList, function(a,b) if type(a) == type(b) then return a < b else return type(a) < type(b) end end)
	for i, k in ipairs(keyList) do
		local v = t[k]
		if indent then
			out:write(string.rep("\t", indent))
		end
		if type(k) == "string" and k:match("^%a[%a%d]*$") and k ~= "hexproof" then
			out:write(k, '=')
		else
			out:write('[')
			if type(k) == "number" then
				out:write(k)
			else
				out:write(qFmt(k))
			end
			out:write(']=')
		end
		if type(v) == "table" then
			writeLuaTable(out, v, indent and indent + 1)
		elseif type(v) == "string" then
			out:write(qFmt(v))
		else
			if v == math.huge then
				out:write("math.huge")
			else
				out:write(tostring(v))
			end
		end
		if i < #keyList then
			out:write(',')
		end
		if indent then
			out:write('\n')
		end
	end
	if indent then
		out:write(string.rep("\t", indent-1))
	end
	out:write('}')
end

-- Make a copy of a table and all subtables
function copyTable(tbl, noRecurse)
	local out = {}
	for k, v in pairs(tbl) do
		if not noRecurse and type(v) == "table" then
			out[k] = copyTable(v)
		else
			out[k] = v
		end
	end
	return out
end
do
	local subTableMap = { }
	function copyTableSafe(tbl, noRecurse, preserveMeta, isSubTable)
		local out = {}
		if not noRecurse then
			subTableMap[tbl] = out
		end
		if preserveMeta then
			setmetatable(out, getmetatable(tbl))
		end
		for k, v in pairs(tbl) do
			if not noRecurse and type(v) == "table" then
				out[k] = subTableMap[v] or copyTableSafe(v, false, preserveMeta, true)
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

function mergeDB(srcDB, modDB)
	if modDB then
		srcDB:AddDB(modDB)
		for k,v in pairs(modDB.conditions) do
			srcDB.conditions[k] = v
		end
		for k,v in pairs(modDB.multipliers) do
			srcDB.multipliers[k] = v
		end
	end
end

function specCopy(env)
	local modDB = new("ModDB")
	modDB:AddDB(env.modDB)
	modDB.conditions = copyTable(env.modDB.conditions)
	modDB.multipliers = copyTable(env.modDB.multipliers)
	local enemyDB = new("ModDB")
	if env.enemyDB then
		enemyDB:AddDB(env.enemyDB)
		enemyDB.conditions = copyTable(env.enemyDB.conditions)
		enemyDB.multipliers = copyTable(env.enemyDB.multipliers)
	end
	local minionDB = nil
	if env.minion then
		minionDB = new("ModDB")
		minionDB:AddDB(env.minion.modDB)
		minionDB.conditions = copyTable(env.minion.modDB.conditions)
		minionDB.multipliers = copyTable(env.minion.modDB.multipliers)
	end
	return modDB, enemyDB, minionDB
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

---Returns the array index of the first element for which the predicate evaluates to true
---@param table table
---@param predicate fun(value:any):any
---@return number
function isValueInArrayPred(table, predicate)
	for i, v in ipairs(table) do
		if predicate(v) then
			return i
		end
	end
end

-- Pretty-prints a table
function prettyPrintTable(tbl, pre, outFile)
	pre = pre or ""
	local outNames = { }
	for name in pairs(tbl) do
		t_insert(outNames, name)
	end
	table.sort(outNames)
	for _, name in ipairs(outNames) do
		if type(tbl[name]) == "table" then
			prettyPrintTable(tbl[name], pre .. name .. ".", outFile)
		else
			if outFile then
				outFile:write(pre .. name .. " = " .. tostring(tbl[name]) .. "\n")
			else
				ConPrintf("%s%s = %s", pre, name, tostring(tbl[name]))
			end
		end
	end
end

function tableConcat(t1,t2)
	local t3 = {}
	for i=1,#t1 do
		t3[#t3+1] = t1[i]
	end
	for i=1,#t2 do
		t3[#t3+1] = t2[i]
	end
	return t3
end

--- Simple table value equality
---@param t1 table
---@param t2 table
---@return boolean
function tableDeepEquals(t1, t2)
	if t1 == t2 then
		return true
	end
	if not t1 or not t2 or #t1 ~= #t2 then
		return false
	end
	for k, v1 in pairs(t1) do
		local v2 = t2[k]
		local typeV1 = type(v1)
		if not (typeV1 == type(v2) and (typeV1 == "table" and tableDeepEquals(v1, v2) or v1 == v2)) then
			return false
		end
	end
	return true
end

function pairsYield(t)
	local k
	local start = GetTime()
	return function() -- iterator function
		if coroutine.running() and GetTime() - start > 20 then
			coroutine.yield()
			start = GetTime()
		end
		local v
		k, v = next(t, k)
		return k, v
	end
end

-- Based on https://www.lua.org/pil/19.3.html
function pairsSortByKey(t, f)
	local sortedKeys = {}
	for key in pairs(t) do t_insert(sortedKeys, key) end
	table.sort(sortedKeys, f)
	local i = 0
	return function() -- iterator function
		i = i + 1
		if sortedKeys[i] == nil then
			return nil
		else
			return sortedKeys[i], t[sortedKeys[i]]
		end
	end
end

-- Natural sort comparator
function naturalSortCompare(a, b)
	local aIndex, bIndex = 1, 1
	while true do
		local aStr, aNum, aEnd = a:match("(.-)(%d+)()", aIndex)
		local bStr, bNum, bEnd = b:match("(.-)(%d+)()", bIndex)
		if not aStr or not bStr then
			aStr = a:sub(aIndex)
			bStr = b:sub(bIndex)
		end
		local al = aStr:upper()
		local bl = bStr:upper()
		if al ~= bl then
			return al < bl
		end
		if aStr ~= bStr then
			return aStr < bStr
		end
		if not aNum then
			return a < b
		end
		local an = tonumber(aNum)
		local bn = tonumber(bNum)
		if an ~= bn then
			return an < bn
		end
		if aNum ~= bNum then
			return aNum < bNum
		end
		aIndex = aEnd
		bIndex = bEnd
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

--- Rounds down a number to the nearest <dec> decimal places
---@param val number
---@param dec number
---@return number
function floor(val, dec)
	if dec then
		local mult = 10 ^ dec
		return m_floor(val * mult + 0.0001) / mult
	else
		return m_floor(val)
	end
end

---@param n number
---@return number
function triangular(n)
	--- Returns the n-th triangular number
	--- See https://en.wikipedia.org/wiki/Triangular_number
	return n * (n + 1) / 2
end

-- Formats "1234.56" -> "1,234.5"
function formatNumSep(str)
	return string.gsub(str, "(%^?x?%x?%x?%x?%x?%x?%x?-?%d+%.?%d+)", function(m)
		local colour = m:match("(^x%x%x%x%x%x%x)") or m:match("(%^%d)") or ""
		local str = m:gsub("(^x%x%x%x%x%x%x)", ""):gsub("(%^%d)", "")
		if str == "" or (colour == "" and m:match("%^")) then  -- return if we have an invalid color code or a completely stripped number.
			return m
		end
		local x, y, minus, integer, fraction = str:find("(-?)(%d+)(%.?%d*)")
		if main.showThousandsSeparators then
			integer = integer:reverse():gsub("(%d%d%d)", "%1"..main.thousandsSeparator):reverse()
			-- There will be leading separators if the number of digits are divisible by 3
			-- This checks for their presence and removes them
			-- Don't use patterns here because thousandsSeparator can be a pattern control character, and will crash if used
			if main.thousandsSeparator ~= "" then
				local thousandsSeparator = string.find(integer, main.thousandsSeparator, 1, 2)
				if thousandsSeparator and thousandsSeparator == 1 then
					integer = integer:sub(2)
				end
			end
		else
			integer = integer:reverse():gsub("(%d%d%d)", "%1"):reverse()
		end
		return colour..minus..integer..fraction:gsub("%.", main.decimalSeparator)
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

function zip(a, b)
	local zipped = { }
	for i, _ in pairs(a) do
		table.insert(zipped, { a[i], b[i] })
	end
	return zipped
end

-- Generate a UUID for a skill
function cacheSkillUUID(skill, env)
	local strName = skill.activeEffect.grantedEffect.name:gsub("%s+", "") -- strip spaces
	local strSlotName = (skill.socketGroup and skill.socketGroup.slot and skill.socketGroup.slot:upper() or "NO_SLOT"):gsub("%s+", "") -- strip spaces
	local slotIndx = 1
	local groupIdx = 1
	if skill.socketGroup and skill.socketGroup.gemList and skill.activeEffect.srcInstance then
		for idx, gem in ipairs(skill.socketGroup.gemList) do
			-- we compare table addresses rather than names since two of the same gem
			-- can be socketed in the same slot
			if gem == skill.activeEffect.srcInstance then
				slotIndx = idx
				break
			end
		end
	end

	for i, group in ipairs(env.build.skillsTab.socketGroupList) do
		if skill.socketGroup == group then
			groupIdx = i
			break
		end
	end

	return strName.."_"..strSlotName.."_"..tostring(slotIndx) .. "_" .. tostring(groupIdx)
end

-- Global Cache related
function cacheData(uuid, env)
	GlobalCache.cachedData[env.mode][uuid] = {
		Name = env.player.mainSkill.activeEffect.grantedEffect.name,
		Speed = env.player.output.Speed,
		HitSpeed = env.player.output.HitSpeed,
		ManaCost = env.player.output.ManaCost,
		LifeCost = env.player.output.LifeCost,
		ESCost = env.player.output.ESCost,
		RageCost = env.player.output.RageCost,
		HitChance = env.player.output.HitChance,
		AccuracyHitChance = env.player.output.AccuracyHitChance,
		PreEffectiveCritChance = env.player.output.PreEffectiveCritChance,
		CritChance = env.player.output.CritChance,
		TotalDPS = env.player.output.TotalDPS,
		ActiveSkill = env.player.mainSkill,
		Env = env,
	}
end

-- Wipe all the tables associated with Global Cache
function wipeGlobalCache()
	wipeTable(GlobalCache.cachedData.MAIN)
	wipeTable(GlobalCache.cachedData.CALCS)
	wipeTable(GlobalCache.cachedData.CALCULATOR)
	wipeTable(GlobalCache.excludeFullDpsList)
	wipeTable(GlobalCache.deleteGroup)
end

-- Check if a specific named gem is enabled in a socket group belonging to a skill
function supportEnabled(skillName, activeSkill)
	for _, gemInstance in ipairs(activeSkill.socketGroup.gemList) do
		if gemInstance.skillId == skillName then
			return gemInstance.enabled
		end
	end
	return true
end

function stringify(thing)
	if type(thing) == 'string' then
		return thing
	elseif type(thing) == 'number' then
		return ""..thing;
	elseif type(thing) == 'table' then
		local s = "{";
		local keys = { }
		for key in pairs(thing) do table.insert(keys, key) end
		table.sort(keys)
		for _, k in ipairs(keys) do
			local v = thing[k]
			s = s.."\n\t"
			if type(k) == 'number' then
				s = s.."["..k.."] = "
			else
				s = s.."[\""..k.."\"] = "
			end
			if type(v) == 'string' then
				s = s.."\""..stringify(v).."\", "
			else
				if type(v) == "boolean" then
					v = v and "true" or "false"
				end
				val = stringify(v)..", "
				if type(v) == "table" then
					val = string.gsub(val, "\n", "\n\t")
				end
				s = s..val;
			end
		end
		return s.."\n}"
	end
end

-- Class function to split a string on a single character (??) separator.
  -- returns a list of fields, not including the separator.
  -- Will return the first field as blank if the first character of the string is the separator
  -- Separator defaults to colon
function string:split(sep)
	-- Initially from http://lua-users.org/wiki/SplitJoin
	-- function will ignore duplicate separators
	local sep, fields = sep or ":", {}
	local pattern = s_format("([^%s]+)", sep)
	-- inject a blank entry if self begins with a colon
	if string.sub(self, 1, 1) == sep then t_insert(fields, "") end
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

-- Ceil function with optional base parameter
function ceil_b(x, base)
	base = base or 1
	return base * m_ceil(x/base)
end

-- Ceil function with optional base parameter
function floor_b(x, base)
	base = base or 1
	return base * m_floor(x/base)
end

function urlEncode(str)
	local charToHex = function(c)
		return s_format("%%%02X", string.byte(c))
	end
	return str:gsub("([^%w_%-.~])", charToHex)
end

function urlDecode(str)
	local hexToChar = function(x)
		return s_char(tonumber(x, 16))
	end
	return str:gsub("%%(%x%x)", hexToChar)
end

function string:matchOrPattern(pattern)
	local function generateOrPatterns(pattern)
		local subGroups = {}
		local index = 1
		-- find and call generate patterns on all subGroups
		for subGroup in pattern:gmatch("%b()") do
			local open, close = pattern:find(subGroup, (subGroups[index] and subGroups[index].close or 1), true)
			t_insert(subGroups, { open = open, close = close, patterns = generateOrPatterns(subGroup:sub(2,-2)) })
			index = index + 1
		end

		-- generate complete patterns from the subGroup patterns
		local generatedPatterns = { pattern:sub(1, (subGroups[1] and subGroups[1].open or 0) - 1) }
		for i, subGroup in ipairs(subGroups) do
			local regularNextString = pattern:sub(subGroup.close + 1, (subGroups[i+1] and subGroups[i+1].open or 0) - 1)
			local tempPatterns = {}
			for _, subPattern in ipairs(generatedPatterns) do
				for subGroupPattern in pairs(subGroup.patterns) do
					t_insert(tempPatterns, subPattern..subGroupPattern..regularNextString)
				end
			end
			generatedPatterns = tempPatterns
		end

		-- apply | operators
		local orPatterns = { }
		for _, generatedPattern in ipairs(generatedPatterns) do
			for orPattern in generatedPattern:gmatch("[^|]+") do
				orPatterns[orPattern] = true -- store string as key to avoid duplicates.
			end
		end
		return orPatterns
	end

	local orPatterns = generateOrPatterns(pattern)
	for orPattern in pairs(orPatterns) do
		if self:match(orPattern) then
			return true
		end
	end
	return false
end