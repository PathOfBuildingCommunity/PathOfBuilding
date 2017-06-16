-- Path of Building
--
-- Module: Mod DB
-- Stores modifiers in a database, with modifiers separated by stat
--
local launch, main = ...

local pairs = pairs
local t_insert = table.insert
local m_floor = math.floor
local m_min = math.min
local m_modf = math.modf
local band = bit.band
local bor = bit.bor

local mod_createMod = modLib.createMod

-- Magic tables for caching multiplier/condition modifier names
local multiplierName = setmetatable({ }, { __index = function(t, var)
	t[var] = "Multiplier:"..var
	return t[var]
end })
local conditionName = setmetatable({ }, { __index = function(t, var)
	t[var] = "Condition:"..var
	return t[var]
end })

local ModDBClass = common.NewClass("ModDB", function(self)
	self.actor = { output = { } }
	self.multipliers = { }
	self.conditions = { }
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
	for i = 1, #modList do
		local mod = modList[i]
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

function ModDBClass:CopyList(modList)
	for i = 1, #modList do
		self:AddMod(copyTable(modList[i]))
	end
end

function ModDBClass:ScaleAddList(modList, scale)
	if scale == 1 then
		self:AddList(modList)
	else
		for i = 1, #modList do
			local scaledMod = copyTable(modList[i])
			if type(scaledMod.value) == "number" then
				scaledMod.value = (m_floor(scaledMod.value) == scaledMod.value) and m_modf(scaledMod.value * scale) or scaledMod.value * scale
			end
			self:AddMod(scaledMod)
		end
	end
end

function ModDBClass:NewMod(...)
	self:AddMod(mod_createMod(...))
end

function ModDBClass:EvalMod(mod, cfg)
	local value = mod.value
	for _, tag in pairs(mod.tagList) do
		if tag.type == "Multiplier" then
			local mult = (self.multipliers[tag.var] or 0) + self:Sum("BASE", cfg, multiplierName[tag.var])
			if tag.limit or tag.limitVar then
				local limit = tag.limit or ((self.multipliers[tag.limitVar] or 0) + self:Sum("BASE", cfg, multiplierName[tag.limitVar]))
				mult = m_min(mult, limit)
			end
			if type(value) == "table" then
				value = copyTable(value)
				if value.mod then
					value.mod.value = value.mod.value * mult + (tag.base or 0)
				else
					value.value = value.value * mult + (tag.base or 0)
				end
			else
				value = value * mult + (tag.base or 0)
			end
		elseif tag.type == "MultiplierThreshold" then
			local mult = (self.multipliers[tag.var] or 0) + self:Sum("BASE", cfg, multiplierName[tag.var])
			if mult < tag.threshold then
				return
			end
		elseif tag.type == "PerStat" then
			local mult = m_floor((self.actor.output[tag.stat] or (cfg and cfg.skillStats and cfg.skillStats[tag.stat]) or 0) / tag.div + 0.0001)
			if type(value) == "table" then
				value = copyTable(value)
				if value.mod then
					value.mod.value = value.mod.value * mult + (tag.base or 0)
				else
					value.value = value.value * mult + (tag.base or 0)
				end
			else
				value = value * mult + (tag.base or 0)
			end
		elseif tag.type == "StatThreshold" then
			if (self.actor.output[tag.stat] or (cfg and cfg.skillStats and cfg.skillStats[tag.stat]) or 0) < tag.threshold then
				return
			end
		elseif tag.type == "DistanceRamp" then
			if not cfg or not cfg.skillDist then
				return
			end
			if cfg.skillDist <= tag.ramp[1][1] then
				value = value * tag.ramp[1][2]
			elseif cfg.skillDist >= tag.ramp[#tag.ramp][1] then
				value = value * tag.ramp[#tag.ramp][2]
			else
				for i, dat in ipairs(tag.ramp) do
					local next = tag.ramp[i+1]
					if cfg.skillDist <= next[1] then
						value = value * (dat[2] + (next[2] - dat[2]) * (cfg.skillDist - dat[1]) / (next[1] - dat[1]))
						break
					end
				end
			end
		elseif tag.type == "Condition" then
			local match = false
			if tag.varList then
				for _, var in pairs(tag.varList) do
					if self.conditions[var] or (cfg and cfg.skillCond and cfg.skillCond[var]) or self:Sum("FLAG", cfg, conditionName[var]) then
						match = true
						break
					end
				end
			else
				match = self.conditions[tag.var] or (cfg and cfg.skillCond and cfg.skillCond[tag.var]) or self:Sum("FLAG", cfg, conditionName[tag.var])
			end
			if tag.neg then
				match = not match
			end
			if not match then
				return
			end
		elseif tag.type == "EnemyCondition" then
			local match = false
			local enemy = self.actor.enemy
			if enemy then
				if tag.varList then
					for _, var in pairs(tag.varList) do
						if enemy.modDB.conditions[var] or enemy.modDB:Sum("FLAG", nil, conditionName[var]) then
							match = true
							break
						end
					end
				else
					match = enemy.modDB.conditions[tag.var] or enemy.modDB:Sum("FLAG", nil, conditionName[tag.var])
				end
				if tag.neg then
					match = not match
				end
			end
			if not match then
				return
			end
		elseif tag.type == "ParentCondition" then
			local match = false
			local parent = self.actor.parent
			if parent then
				if tag.varList then
					for _, var in pairs(tag.varList) do
						if parent.modDB.conditions[var] or parent.modDB:Sum("FLAG", nil, conditionName[var]) then
							match = true
							break
						end
					end
				else
					match = parent.modDB.conditions[tag.var] or parent.modDB:Sum("FLAG", nil, conditionName[tag.var])
				end
			end
			if tag.neg then
				match = not match
			end
			if not match then
				return
			end
		elseif tag.type == "SocketedIn" then
			if not cfg or tag.slotName ~= cfg.slotName or (tag.keyword and (not cfg or not cfg.skillGem or not calcLib.gemIsType(cfg.skillGem, tag.keyword))) then
				return
			end
		elseif tag.type == "SkillName" then
			local match = false
			local matchName = tag.summonSkill and (cfg and cfg.summonSkillName or "") or (cfg and cfg.skillName)
			if tag.skillNameList then
				for _, name in pairs(tag.skillNameList) do
					if name == matchName then
						match = true
						break
					end
				end
			else
				match = (tag.skillName == matchName)
			end
			if not match then
				return
			end
		elseif tag.type == "SkillId" then
			if not cfg or not cfg.skillGem or cfg.skillGem.grantedEffect.id ~= tag.skillId then
				return
			end
		elseif tag.type == "SkillPart" then
			if not cfg or tag.skillPart ~= cfg.skillPart then
				return
			end
		elseif tag.type == "SkillType" then
			if not cfg or not cfg.skillTypes or not cfg.skillTypes[tag.skillType] then
				return
			end
		elseif tag.type == "SlotName" then
			if not cfg or tag.slotName ~= cfg.slotName then
				return
			end
		end
	end	
	return value
end

function ModDBClass:Sum(modType, cfg, ...)
	local flags, keywordFlags = 0, 0
	local source, tabulate
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
		tabulate = cfg.tabulate
		if tabulate then
			cfg = copyTable(cfg, true)
			cfg.tabulate = false
		end
	end
	local result
	local nullValue = 0
	if tabulate or modType == "LIST" then
		result = { }
		nullValue = nil
	elseif modType == "MORE" then
		result = 1
	elseif modType == "FLAG" then
		result = false
		nullValue = false
	else
		result = 0
	end
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		local modList = self.mods[modName]
		if modList then
			for i = 1, #modList do
				local mod = modList[i]
				if (not modType or mod.type == modType) and (mod.flags == 0 or band(flags, mod.flags) == mod.flags) and (mod.keywordFlags == 0 or band(keywordFlags, mod.keywordFlags) ~= 0) and (not source or mod.source:match("[^:]+") == source) then
					local value
					if mod.tagList[1] then
						value = self:EvalMod(mod, cfg) or nullValue
					else
						value = mod.value
					end
					if tabulate then
						if value and value ~= 0 then
							t_insert(result, { value = value, mod = mod })
						end
					elseif modType == "MORE" then
						result = result * (1 + value / 100)
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
			ConPrintf("\t%s = %s|%s|%s|%s|%s", modLib.formatValue(mod.value), mod.type, modLib.formatFlags(mod.flags, ModFlag), modLib.formatFlags(mod.keywordFlags, KeywordFlag), modLib.formatTags(mod.tagList), mod.source or "?")
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