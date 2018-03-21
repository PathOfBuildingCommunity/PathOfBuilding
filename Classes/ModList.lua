-- Path of Building
--
-- Module: Mod List
-- Stores modifiers in a flat list
--
local launch, main = ...

local ipairs = ipairs
local pairs = pairs
local select = select
local t_insert = table.insert
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local m_modf = math.modf
local band = bit.band
local bor = bit.bor

local mod_createMod = modLib.createMod

local ModListClass = common.NewClass("ModList", "ModStore", function(self)
	self.ModStore()
end)

function ModListClass:AddMod(mod)
	t_insert(self, mod)
end

function ModListClass:MergeMod(mod)
	if mod.type == "BASE" or mod.type == "INC" then
		for i = 1, #self do
			if modLib.compareModParams(self[i], mod) then
				self[i] = copyTable(self[i], true)
				self[i].value = self[i].value + mod.value
				return
			end
		end
	end
	self:AddMod(mod)
end

function ModListClass:AddList(modList)
	for i = 1, #modList do
		t_insert(self, modList[i])
	end
end

function ModListClass:MergeNewMod(...)
	self:MergeMod(mod_createMod(...))
end

function ModListClass:Sum(modType, cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	local result
	local nullValue = 0
	if modType == "MORE" then
		result = 1
	elseif modType == "OVERRIDE" then
		nullValue = nil
	elseif modType == "FLAG" then
		result = false
		nullValue = false
	elseif modType == "LIST" then
		result = { }
		nullValue = nil
	else
		result = 0
	end
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == modType and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				local value
				if mod[1] then
					value = self:EvalMod(mod, cfg) or nullValue
				else
					value = mod.value
				end
				if modType == "MORE" then
					result = result * (1 + value / 100)
				elseif modType == "OVERRIDE" then
					if value then
						return value
					end
				elseif modType == "FLAG" then
					if value then
						return true
					end
				elseif modType == "LIST" then
					if value then
						t_insert(result, value)
					end
				else
					result = result + value
				end
			end
		end
	end
	return result
end

function ModListClass:Print()
	for _, mod in ipairs(self) do
		ConPrintf("%s|%s", modLib.formatMod(mod), mod.source or "?")
	end
end
