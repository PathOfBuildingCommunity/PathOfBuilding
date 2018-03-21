-- Path of Building
--
-- Module: Mod Store
-- Base class for modifier storage classes
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

local ModStoreClass = common.NewClass("ModStore", function(self)
	self.actor = { output = { } }
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
			end
			self:AddMod(scaledMod)
		end
	end
end

function ModStoreClass:NewMod(...)
	self:AddMod(mod_createMod(...))
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
					base = base + (target.multipliers[var] or 0) + target:Sum("BASE", cfg, multiplierName[var])
				end
			else
				base = (target.multipliers[tag.var] or 0) + target:Sum("BASE", cfg, multiplierName[tag.var])
			end
			local mult = m_floor(base / (tag.div or 1) + 0.0001)
			local limitTotal
			if tag.limit or tag.limitVar then
				local limit = tag.limit or ((self.multipliers[tag.limitVar] or 0) + self:Sum("BASE", cfg, multiplierName[tag.limitVar]))
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
					mult = mult + (target.multipliers[var] or 0) + target:Sum("BASE", cfg, multiplierName[var])
				end
			else
				mult = (target.multipliers[tag.var] or 0) + target:Sum("BASE", cfg, multiplierName[tag.var])
			end
			local threshold = tag.threshold or ((target.multipliers[tag.thresholdVar] or 0) + target:Sum("BASE", cfg, multiplierName[tag.thresholdVar]))
			if (tag.upper and mult > tag.threshold) or (not tag.upper and mult < tag.threshold) then
				return
			end
		elseif tag.type == "PerStat" then
			local base
			if tag.statList then
				base = 0
				for _, stat in ipairs(tag.statList) do
					base = base + (self.actor.output[stat] or (cfg and cfg.skillStats and cfg.skillStats[stat]) or 0)
				end
			else
				base = self.actor.output[tag.stat] or (cfg and cfg.skillStats and cfg.skillStats[tag.stat]) or 0
			end
			local mult = m_floor(base / (tag.div or 1) + 0.0001)
			local limitTotal
			if tag.limit or tag.limitVar then
				local limit = tag.limit or ((self.multipliers[tag.limitVar] or 0) + self:Sum("BASE", cfg, multiplierName[tag.limitVar]))
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
					stat = stat + (self.actor.output[stat] or (cfg and cfg.skillStats and cfg.skillStats[stat]) or 0)
				end
			else
				stat = self.actor.output[tag.stat] or (cfg and cfg.skillStats and cfg.skillStats[tag.stat]) or 0
			end
			local threshold = tag.threshold or (self.actor.output[tag.thresholdStat] or (cfg and cfg.skillStats and cfg.skillStats[tag.thresholdStat]) or 0)
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
		elseif tag.type == "ActorCondition" then
			local match = false
			local actor = self.actor[tag.actor]
			if actor then
				if tag.varList then
					for _, var in pairs(tag.varList) do
						if actor.modDB.conditions[var] or actor.modDB:Sum("FLAG", nil, conditionName[var]) then
							match = true
							break
						end
					end
				else
					match = actor.modDB.conditions[tag.var] or actor.modDB:Sum("FLAG", nil, conditionName[tag.var])
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