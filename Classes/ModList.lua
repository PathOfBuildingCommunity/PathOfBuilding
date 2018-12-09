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


function ModListClass:Sum(modType, cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	local result = 0
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == modType and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				if mod[1] then
					result = result + (self:EvalMod(mod, cfg) or 0)
				else
					result = result + mod.value
				end
			end
		end
	end
	if self.parent then
		self.parent.context = self.context
		result = result + self.parent:Sum(modType, cfg, ...)
		self.parent.context = self.parent
	end
	return result
end

function ModListClass:More(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	local result = 1
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "MORE" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				if mod[1] then
					result = result * (1 + (self:EvalMod(mod, cfg) or 1) / 100)
				else
					result = result * (1 + mod.value / 100)
				end
			end
		end
	end
	if self.parent then
		self.parent.context = self.context
		result = result * self.parent:More(cfg, ...)
		self.parent.context = self.parent
	end
	return result
end

function ModListClass:Flag(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "FLAG" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				if mod[1] then
					if self:EvalMod(mod, cfg) then
						return true
					end
				elseif mod.value then
					return true
				end
			end
		end
	end
	if self.parent then
		self.parent.context = self.context
		local result = self.parent:Flag(cfg, ...)
		self.parent.context = self.parent
		return result
	end
end

function ModListClass:Override(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "OVERRIDE" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				if mod[1] then
					local value = self:EvalMod(mod, cfg)
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
		self.parent.context = self.context
		local result = self.parent:Override(cfg, ...)
		self.parent.context = self.parent
		return result
	end
end

function ModListClass:List(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	local result = { }
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and mod.type == "LIST" and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
				local value
				if mod[1] then
					local value = self:EvalMod(mod, cfg) or nullValue
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
		self.parent.context = self.context
		for _, v in ipairs(self.parent:List(cfg, ...)) do
			t_insert(result, v)
		end
		self.parent.context = self.parent
	end
	return result
end

function ModListClass:Tabulate(modType, cfg, ...)
	local flags = cfg.flags or 0
	local keywordFlags = cfg.keywordFlags or 0
	local source = cfg.source
	local result = { }
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		for i = 1, #self do
			local mod = self[i]
			if mod.name == modName and (mod.type == modType or not modType) and band(flags, mod.flags) == mod.flags and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
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
	if self.parent then
		self.parent.context = self.context
		for _, v in ipairs(self.parent:Tabulate(modType, cfg, ...)) do
			t_insert(result, v)
		end
		self.parent.context = self.parent
	end
	return result
end

function ModListClass:Print()
	for _, mod in ipairs(self) do
		ConPrintf("%s|%s", modLib.formatMod(mod), mod.source or "?")
	end
end
