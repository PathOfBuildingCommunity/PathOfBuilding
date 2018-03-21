-- Path of Building
--
-- Module: Mod DB
-- Stores modifiers in a database, with modifiers separated by stat
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

local ModDBClass = common.NewClass("ModDB", "ModStore", function(self)
	self.ModStore()
	self.mods = { }
end)

function ModDBClass:AddMod(mod)
	local name = mod.name
	if not self.mods[name] then
		self.mods[name] = { }
	end
	t_insert(self.mods[name], mod)
end

function ModDBClass:AddList(modList)
	local mods = self.mods
	for i, mod in ipairs(modList) do
		local name = mod.name
		if not mods[name] then
			mods[name] = { }
		end
		t_insert(mods[name], mod)
	end
end

function ModDBClass:AddDB(modDB)
	local mods = self.mods
	for modName, modList in pairs(modDB.mods) do
		if not mods[modName] then
			mods[modName] = { }
		end
		local modsName = mods[modName]
		for i = 1, #modList do
			t_insert(modsName, modList[i])
		end
	end
end

function ModDBClass:Sum(modType, cfg, ...)
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
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == modType and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
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
	end
	return result
end

function ModDBClass:Tabulate(modType, cfg, ...)
	local flags = cfg.flags or 0
	local keywordFlags = cfg.keywordFlags or 0
	local source = cfg.source
	local result = { }
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		local modList = self.mods[modName]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if (mod.type == modType or not modType) and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					local value
					if mod[1] then
						value = self:EvalMod(mod, cfg)
					else
						value = mod.value
					end
					if value and (value ~= 0 or mod.type == "OVERRIDE") then
						t_insert(result, { value = value, mod = mod })
					end
				end
			end
		end
	end
	return result
end

function ModDBClass:Print()
	ConPrintf("=== Modifiers ===")
	local modNames = { }
	for modName in pairs(self.mods) do
		t_insert(modNames, modName)
	end
	table.sort(modNames)
	for _, modName in ipairs(modNames) do
		ConPrintf("'%s' = {", modName)
		for _, mod in ipairs(self.mods[modName]) do
			ConPrintf("\t%s = %s|%s|%s|%s|%s", modLib.formatValue(mod.value), mod.type, modLib.formatFlags(mod.flags, ModFlag), modLib.formatFlags(mod.keywordFlags, KeywordFlag), modLib.formatTags(mod), mod.source or "?")
		end
		ConPrintf("},")
	end
	ConPrintf("=== Conditions ===")
	local nameList = { }
	for name, value in pairs(self.conditions) do
		if value then
			t_insert(nameList, name)
		end
	end
	table.sort(nameList)
	for i, name in ipairs(nameList) do
		ConPrintf(name)
	end
	ConPrintf("=== Multipliers ===")
	wipeTable(nameList)
	for name, value in pairs(self.multipliers) do
		if value > 0 then
			t_insert(nameList, name)
		end
	end
	table.sort(nameList)
	for i, name in ipairs(nameList) do
		ConPrintf("%s = %d", name, self.multipliers[name])
	end
end