-- Path of Building
--
-- Module: Mod Store
-- Base class for modifier storage classes
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

-- Magic tables for caching multiplier/condition modifier names
local multiplierName = setmetatable({ }, { __index = function(t, var)
	t[var] = "Multiplier:"..var
	return t[var]
end })
local conditionName = setmetatable({ }, { __index = function(t, var)
	t[var] = "Condition:"..var
	return t[var]
end })

local ModStoreClass = newClass("ModStore", function(self, parent)
	self.parent = parent or false
	self.actor = parent and parent.actor or { }
	self.multipliers = { }
	self.conditions = { }
end)

function ModStoreClass:ScaleAddMod(mod, scale)
	if scale == 1 then
		self:AddMod(mod)
	else
		scale = m_max(scale, 0)
		local scaledMod = copyTable(mod)
		if type(scaledMod.value) == "number" then
			scaledMod.value = (m_floor(scaledMod.value) == scaledMod.value) and m_modf(scaledMod.value * scale) or scaledMod.value * scale
		elseif type(scaledMod.value) == "table" and scaledMod.value.mod then
			scaledMod.value.mod.value = (m_floor(scaledMod.value.mod.value) == scaledMod.value.mod.value) and m_modf(scaledMod.value.mod.value * scale) or scaledMod.value.mod.value * scale
		end
		self:AddMod(scaledMod)
	end
end

function ModStoreClass:CopyList(modList)
	for i = 1, #modList do
		self:AddMod(copyTable(modList[i]))
	end
end

function ModStoreClass:ScaleAddList(modList, scale)
	if scale == 1 then
		self:AddList(modList)
	else
		scale = m_max(scale, 0)
		for i = 1, #modList do
			local scaledMod = copyTable(modList[i])
			if type(scaledMod.value) == "number" then
				scaledMod.value = (m_floor(scaledMod.value) == scaledMod.value) and m_modf(scaledMod.value * scale) or scaledMod.value * scale
			elseif type(scaledMod.value) == "table" and scaledMod.value.mod then
				scaledMod.value.mod.value = (m_floor(scaledMod.value.mod.value) == scaledMod.value.mod.value) and m_modf(scaledMod.value.mod.value * scale) or scaledMod.value.mod.value * scale
			end
			self:AddMod(scaledMod)
		end
	end
end

function ModStoreClass:NewMod(...)
	self:AddMod(mod_createMod(...))
end

function ModStoreClass:Combine(modType, cfg, ...)
	if modType == "MORE" then
		return self:More(cfg, ...)
	elseif modType == "FLAG" then
		return self:Flag(cfg, ...)
	elseif modType == "OVERRIDE" then
		return self:Override(cfg, ...)
	elseif modType == "LIST" then
		return self:List(cfg, ...)
	else
		return self:Sum(modType, cfg, ...)
	end
end

function ModStoreClass:Sum(modType, cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	return self:SumInternal(self, modType, cfg, flags, keywordFlags, source, ...)
end

function ModStoreClass:More(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	return self:MoreInternal(self, cfg, flags, keywordFlags, source, ...)
end

function ModStoreClass:Flag(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	return self:FlagInternal(self, cfg, flags, keywordFlags, source, ...)
end

function ModStoreClass:Override(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	return self:OverrideInternal(self, cfg, flags, keywordFlags, source, ...)
end

function ModStoreClass:List(cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	local result = { }
	self:ListInternal(self, result, cfg, flags, keywordFlags, source, ...)
	return result
end

function ModStoreClass:Tabulate(modType, cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	local result = { }
	self:TabulateInternal(self, result, modType, cfg, flags, keywordFlags, source, ...)
	return result
end

function ModStoreClass:GetCondition(var, cfg, noMod)
	return self.conditions[var] or (self.parent and self.parent:GetCondition(var, cfg, true)) or (not noMod and self:Flag(cfg, conditionName[var]))
end

function ModStoreClass:GetMultiplier(var, cfg, noMod)
	return (self.multipliers[var] or 0) + (self.parent and self.parent:GetMultiplier(var, cfg, true) or 0) + (not noMod and self:Sum("BASE", cfg, multiplierName[var]) or 0)
end

function ModStoreClass:GetStat(stat, cfg)
	return (self.actor.output and self.actor.output[stat]) or (cfg and cfg.skillStats and cfg.skillStats[stat]) or 0
end

function ModStoreClass:EvalMod(mod, cfg)
	local value = mod.value
	for _, tag in ipairs(mod) do
		if tag.type == "Multiplier" then
			local target = self
			if tag.actor then
				if self.actor[tag.actor] then
					target = self.actor[tag.actor].modDB
				else
					return
				end
			end
			local base = 0
			if tag.varList then
				for _, var in pairs(tag.varList) do
					base = base + target:GetMultiplier(var, cfg)
				end
			else
				base = target:GetMultiplier(tag.var, cfg)
			end
			local mult = m_floor(base / (tag.div or 1) + 0.0001)
			local limitTotal
			if tag.limit or tag.limitVar then
				local limit = tag.limit or self:GetMultiplier(tag.limitVar, cfg)
				if tag.limitTotal then
					limitTotal = limit
				else
					mult = m_min(mult, limit)
				end
			end
			if type(value) == "table" then
				value = copyTable(value)
				if value.mod then
					value.mod.value = value.mod.value * mult + (tag.base or 0)
					if limitTotal then
						value.mod.value = m_min(value.mod.value, limitTotal)
					end
				else
					value.value = value.value * mult + (tag.base or 0)
					if limitTotal then
						value.value = m_min(value.value, limitTotal)
					end
				end
			else
				value = value * mult + (tag.base or 0)
				if limitTotal then
					value = m_min(value, limitTotal)
				end
			end
		elseif tag.type == "MultiplierThreshold" then
			local target = self
			if tag.actor then
				if self.actor[tag.actor] then
					target = self.actor[tag.actor].modDB
				else
					return
				end
			end
			local mult = 0
			if tag.varList then
				for _, var in pairs(tag.varList) do
					mult = mult + target:GetMultiplier(var, cfg)
				end
			else
				mult = target:GetMultiplier(tag.var, cfg)
			end
			local threshold = tag.threshold or target:GetMultiplier(tag.thresholdVar, cfg)
			if (tag.upper and mult > threshold) or (not tag.upper and mult < threshold) then
				return
			end
		elseif tag.type == "PerStat" then
			local base
			if tag.statList then
				base = 0
				for _, stat in ipairs(tag.statList) do
					base = base + self:GetStat(stat, cfg)
				end
			else
				base = self:GetStat(tag.stat, cfg)
			end
			local mult = m_floor(base / (tag.div or 1) + 0.0001)
			local limitTotal
			if tag.limit or tag.limitVar then
				local limit = tag.limit or self:GetMultiplier(tag.limitVar, cfg)
				if tag.limitTotal then
					limitTotal = limit
				else
					mult = m_min(mult, limit)
				end 
			end
			if type(value) == "table" then
				value = copyTable(value)
				if value.mod then
					value.mod.value = value.mod.value * mult + (tag.base or 0)
					if limitTotal then
						value.mod.value = m_min(value.mod.value, limitTotal)
					end
				else
					value.value = value.value * mult + (tag.base or 0)
					if limitTotal then
						value.value = m_min(value.value, limitTotal)
					end
				end
			else
				value = value * mult + (tag.base or 0)
				if limitTotal then
					value = m_min(value, limitTotal)
				end
			end
		elseif tag.type == "StatThreshold" then
			local stat
			if tag.statList then
				stat = 0
				for _, stat in ipairs(tag.statList) do
					stat = stat + self:GetStat(stat, cfg)
				end
			else
				stat = self:GetStat(tag.stat, cfg)
			end
			local threshold = tag.threshold or self:GetStat(tag.thresholdStat, cfg)
			if (tag.upper and stat > threshold) or (not tag.upper and stat < threshold) then
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
		-- Syntax: { type = "MeleeProximity", ramp = {MaxBonusPct,MinBonusPct} }
		-- 			Both MaxBonusPct and MinBonusPct are percent in decimal form (1.0 = 100%)
		-- Example: { type = "MeleeProximity", ramp = {1,0} }   ## Duelist-Slayer: Impact
		elseif tag.type == "MeleeProximity" then
			if not cfg or not cfg.skillDist then
				return
			end
			-- Max potency is 0-15 units of distance
			if cfg.skillDist <= 15 then
				value = value * tag.ramp[1]
			-- Reduced potency (linear) until 40 units
			elseif cfg.skillDist >= 16 and cfg.skillDist <= 39 then
				value = value * (tag.ramp[1] - ((tag.ramp[1] / 25) * (cfg.skillDist - 15)))
			elseif cfg.skillDist >= 40 then
				value = 0
			end
		elseif tag.type == "Limit" then
			value = m_min(value, tag.limit or self:GetMultiplier(tag.limitVar, cfg))
		elseif tag.type == "Condition" then
			local match = false
			if tag.varList then
				for _, var in pairs(tag.varList) do
					if self:GetCondition(var, cfg) or (cfg and cfg.skillCond and cfg.skillCond[var]) then
						match = true
						break
					end
				end
			else
				match = self:GetCondition(tag.var, cfg) or (cfg and cfg.skillCond and cfg.skillCond[tag.var])
			end
			if tag.neg then
				match = not match
			end
			if not match then
				return
			end
		elseif tag.type == "ActorCondition" then
			local match = false
			local target = self
			if tag.actor then
				target = self.actor[tag.actor] and self.actor[tag.actor].modDB
			end
			if target then
				if tag.varList then
					for _, var in pairs(tag.varList) do
						if target:GetCondition(var, cfg) then
							match = true
							break
						end
					end
				else
					match = target:GetCondition(tag.var, cfg)
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
			if not cfg or not cfg.skillGrantedEffect or cfg.skillGrantedEffect.id ~= tag.skillId then
				return
			end
		elseif tag.type == "SkillPart" then
			if not cfg then
				return
			end
			local match = false
			if tag.skillPartList then
				for _, part in ipairs(tag.skillPartList) do
					if part == cfg.skillPart then
						match = true
						break
					end
				end
			else
				match = (tag.skillPart == cfg.skillPart)
			end
			if tag.neg then
				match = not match
			end
			if not match then
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