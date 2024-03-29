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

---ReplaceModInternal
---  Replaces an existing matching mod with a new mod.
---  If no matching mod exists, then the function returns false
---@param mod table
---@return boolean @Whether any mod was replaced
function ModDBClass:ReplaceModInternal(mod)
	local name = mod.name
	if not self.mods[name] then
		self.mods[name] = { }
	end

	-- Find the index of the existing mod, if it is in the table
	local modList = self.mods[name]
	local modIndex = -1
	for i = 1, #modList do
		local curMod = modList[i]
		if mod.name == curMod.name and mod.type == curMod.type and mod.flags == curMod.flags and mod.keywordFlags == curMod.keywordFlags and mod.source == curMod.source then
			modIndex = i
			break;
		end
	end

	-- Add or replace the mod
	if modIndex > 0 then
		modList[modIndex] = mod
		return true
	end

	if self.parent then
		return self.parent:ReplaceModInternal(mod)
	end
	
	return false
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
	local globalLimits = { }
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == modType and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or ( mod.source and mod.source:match("[^:]+") == source )) then
					if mod[1] then
						local value = context:EvalMod(mod, cfg) or 0
						if mod[1].globalLimit and mod[1].globalLimitKey then
							globalLimits[mod[1].globalLimitKey] = globalLimits[mod[1].globalLimitKey] or 0
							if globalLimits[mod[1].globalLimitKey] + value > mod[1].globalLimit then
								value = mod[1].globalLimit - globalLimits[mod[1].globalLimitKey]
							end
							globalLimits[mod[1].globalLimitKey] = globalLimits[mod[1].globalLimitKey] + value
						end
						result = result + value
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
	local modPrecision = nil
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		local modResult = 1 --The more multipliers for each mod are computed to the nearest percent then applied.
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == "MORE" and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or mod.source:match("[^:]+") == source) then
					if mod[1] then
						modResult = modResult * (1 + (context:EvalMod(mod, cfg) or 0) / 100)
					else
						modResult = modResult * (1 + mod.value / 100)
					end
					if modPrecision then
						modPrecision = m_max(modPrecision, (data.highPrecisionMods[mod.name] and data.highPrecisionMods[mod.name][mod.type]) or modPrecision)
					else
						modPrecision = (data.highPrecisionMods[mod.name] and data.highPrecisionMods[mod.name][mod.type]) or nil
					end
				end
			end
		end
		if modPrecision then
			local power = 10 ^ modPrecision
			result = math.floor(result * modResult * power) / power
		else
			result = result * round(modResult, 2)
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
				if mod.type == "FLAG" and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or mod.source:match("[^:]+") == source) then
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
				if mod.type == "OVERRIDE" and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or mod.source:match("[^:]+") == source) then
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
				if mod.type == "LIST" and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or mod.source:match("[^:]+") == source) then
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
	local globalLimits = { }
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		local modList = self.mods[modName]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if (mod.type == modType or not modType) and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or mod.source:match("[^:]+") == source) then
					local value
					if mod[1] then
						value = context:EvalMod(mod, cfg) or 0
						if mod[1].globalLimit and mod[1].globalLimitKey then
							globalLimits[mod[1].globalLimitKey] = globalLimits[mod[1].globalLimitKey] or 0
							if globalLimits[mod[1].globalLimitKey] + value > mod[1].globalLimit then
								value = mod[1].globalLimit - globalLimits[mod[1].globalLimitKey]
							end
							globalLimits[mod[1].globalLimitKey] = globalLimits[mod[1].globalLimitKey] + value
						end
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

---HasModInternal
---  Checks if a mod exists with the given properties
---@param modType string @The type of the mod, e.g. "BASE"
---@param flags number @The mod flags to match
---@param keywordFlags number @The mod keyword flags to match
---@param source string @The mod source to match
---@return boolean @true if the mod is found, false otherwise.
function ModDBClass:HasModInternal(modType, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modList = self.mods[select(i, ...)]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if mod.type == modType and band(flags, mod.flags) == mod.flags and MatchKeywordFlags(keywordFlags, mod.keywordFlags) and (not source or mod.source:match("[^:]+") == source) then
					return true
				end
			end
		end
	end
	if self.parent then
		local parentResult = self.parent:HasModInternal(modType, flags, keywordFlags, source, ...)
		if parentResult == true then
			return true
		end
	end
	return false
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