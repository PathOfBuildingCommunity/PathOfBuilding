-- Path of Building
--
-- Module: Mod DB
-- Stores modifiers in a database, with modifiers separated by stat
--
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

local ModDBClass = newClass("ModDB", "ModStore", function(self, parent)
	self.ModStore(parent)
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

function ModDBClass:SumInternal(context, modType, cfg, flags, keywordFlags, source, ...)
	local result = 0
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == modType and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					if mod[1] then
						result = result + (context:EvalMod(mod, cfg) or 0)
					else
						result = result + mod.value
					end
				end
			end
		end
	end
	if self.parent then
		result = result + self.parent:SumInternal(context, modType, cfg, flags, keywordFlags, source, ...)
	end
	return result
end

function ModDBClass:MoreInternal(context, cfg, flags, keywordFlags, source, ...)
	local result = 1
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == "MORE" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					if mod[1] then
						result = result * (1 + (context:EvalMod(mod, cfg) or 0) / 100)
					else
						result = result * (1 + mod.value / 100)
					end
				end
			end
		end
	end
	if self.parent then
		result = result * self.parent:MoreInternal(context, cfg, flags, keywordFlags, source, ...)
	end
	return result
end

function ModDBClass:FlagInternal(context, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == "FLAG" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					if mod[1] then
						if context:EvalMod(mod, cfg) then
							return true
						end
					elseif mod.value then
						return true
					end
				end
			end
		end
	end
	if self.parent then
		return self.parent:FlagInternal(context, cfg, flags, keywordFlags, source, ...)
	end
end

function ModDBClass:OverrideInternal(context, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == "OVERRIDE" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					if mod[1] then
						local value = context:EvalMod(mod, cfg)
						if value then
							return value
						end
					elseif mod.value then
						return mod.value
					end
				end
			end
		end
	end
	if self.parent then
		return self.parent:OverrideInternal(context, cfg, flags, keywordFlags, source, ...)
	end
end

function ModDBClass:ListInternal(context, result, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == "LIST" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					local value
					if mod[1] then
						local value = context:EvalMod(mod, cfg) or nullValue
						if value then
							t_insert(result, value)
						end
					elseif mod.value then
						t_insert(result, mod.value)
					end
				end
			end
		end
	end
	if self.parent then
		self.parent:ListInternal(context, result, cfg, flags, keywordFlags, source, ...)
	end
end

function ModDBClass:TabulateInternal(context, result, modType, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		local modList = self.mods[modName]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if (mod.type == modType or not modType) and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					local value
					if mod[1] then
						value = context:EvalMod(mod, cfg)
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
	if self.parent then
		self.parent:TabulateInternal(context, result, modType, cfg, flags, keywordFlags, source, ...)
	end
end

function ModDBClass:Print()
	ConPrintf("=== Modifiers ===")
	local modNames = { }
	for modName in pairs(self.mods) do
		t_insert(modNames, modName)
	end
	table.sort(modNames)
	for _, modName in ipairs(modNames) do
		ConPrintf("'%s':", modName)
		for _, mod in ipairs(self.mods[modName]) do
			ConPrintf("\t%s = %s|%s|%s|%s|%s", modLib.formatValue(mod.value), mod.type, modLib.formatFlags(mod.flags, ModFlag), modLib.formatFlags(mod.keywordFlags, KeywordFlag), modLib.formatTags(mod), mod.source or "?")
		end
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