-- Path of Building
--
-- Module: Mod List
-- Stores modifiers in a flat list
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

local ModListClass = newClass("ModList", "ModStore", function(self, parent)
	self.ModStore(parent)
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


function ModListClass:SumInternal(context, modType, cfg, flags, keywordFlags, source, ...)
	local result = 0
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == modType and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				if mod[1] then
					result = result + (context:EvalMod(mod, cfg) or 0)
				else
					result = result + mod.value
				end
			end
		end
	end
	if self.parent then
		result = result + self.parent:SumInternal(context, modType, cfg, flags, keywordFlags, source, ...)
	end
	return result
end

function ModListClass:MoreInternal(context, cfg, flags, keywordFlags, source, ...)
	local result = 1
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "MORE" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				if mod[1] then
					result = result * (1 + (context:EvalMod(mod, cfg) or 0) / 100)
				else
					result = result * (1 + mod.value / 100)
				end
			end
		end
	end
	if self.parent then
		result = result * self.parent:MoreInternal(context, cfg, flags, keywordFlags, source, ...)
	end
	return result
end

function ModListClass:FlagInternal(context, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "FLAG" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
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
	if self.parent then
		return self.parent:FlagInternal(context, cfg, flags, keywordFlags, source, ...)
	end
end

function ModListClass:OverrideInternal(context, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "OVERRIDE" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
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
	if self.parent then
		return self.parent:OverrideInternal(context, cfg, flags, keywordFlags, source, ...)
	end
end

function ModListClass:ListInternal(context, result, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "LIST" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
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
	if self.parent then
		self.parent:ListInternal(context, result, cfg, flags, keywordFlags, source, ...)
	end
end

function ModListClass:TabulateInternal(context, result, modType, cfg, flags, keywordFlags, source, ...)
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and (mod.type == modType or not modType) and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
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
	if self.parent then
		self.parent:TabulateInternal(context, result, modType, cfg, flags, keywordFlags, source, ...)
	end
end

function ModListClass:Print()
	for _, mod in ipairs(self) do
		ConPrintf("%s|%s", modLib.formatMod(mod), mod.source or "?")
	end
end
