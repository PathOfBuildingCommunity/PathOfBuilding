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

-- Magic tables for caching multiplier/condition modifier names
local multiplierName = setmetatable({ }, { __index = function(t, var)
	t[var] = "Multiplier:"..var
	return t[var]
end })
local conditionName = setmetatable({ }, { __index = function(t, var)
	t[var] = "Condition:"..var
	return t[var]
end })

local ModListClass = common.NewClass("ModList", function(self)
	self.actor = { output = { } }
	self.multipliers = { }
	self.conditions = { }
end)

function ModListClass:AddMod(mod)
	t_insert(self, mod)
end

function ModListClass:AddList(modList)
	for i = 1, #modList do
		t_insert(self, modList[i])
	end
end

function ModListClass:CopyList(modList)
	for i = 1, #modList do
		self:AddMod(copyTable(modList[i]))
	end
end

function ModListClass:ScaleAddList(modList, scale)
	if scale == 1 then
		self:AddList(modList)
	else
		scale = m_max(scale, 0)
		for i = 1, #modList do
			local scaledMod = copyTable(modList[i])
			if type(scaledMod.value) == "number" then
				scaledMod.value = (m_floor(scaledMod.value) == scaledMod.value) and m_modf(scaledMod.value * scale) or scaledMod.value * scale
			end
			self:AddMod(scaledMod)
		end
	end
end

function ModListClass:NewMod(...)
	self:AddMod(mod_createMod(...))
end

function ModListClass:EvalMod(mod, cfg)
	local value = mod.value
	for _, tag in ipairs(mod) do
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
			local match = cfg and cfg.skillTypes and cfg.skillTypes[tag.skillType]
			if tag.neg then
				match = not match
			end
			if not match then
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
