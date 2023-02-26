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
	local unscalable = false
	for _, effects in ipairs(mod) do
		if effects.unscalable then
			unscalable = true
			break
		end
	end
	if scale == 1 or unscalable then
		self:AddMod(mod)
	else
		scale = m_max(scale, 0)
		local scaledMod = copyTable(mod)
		local subMod = scaledMod
		if type(scaledMod.value) == "table" and scaledMod.value.mod then
			subMod = scaledMod.value.mod
		end
		if type(subMod.value) == "number" then
			local precision = ((data.highPrecisionMods[subMod.name] and data.highPrecisionMods[subMod.name][subMod.type])) or ((m_floor(subMod.value) ~= subMod.value) and data.defaultHighPrecision) or nil
			if precision then
				local power = 10 ^ precision
				subMod.value = math.floor(subMod.value * scale * power) / power
			else
				subMod.value = m_modf(round(subMod.value * scale, 2))
			end
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
		for i = 1, #modList do
			self:ScaleAddMod(modList[i], scale)
		end
	end
end

function ModStoreClass:NewMod(...)
	self:AddMod(mod_createMod(...))
end

---ReplaceMod
---  Replaces an existing matching mod with a new mod.
---  A mod is considered the same if the name, type, flags, keywordFlags, and source exactly match.
---  If no matching mod exists, the mod is added instead.
---Notes:
---    See calls to ModStoreClass:NewMod for additional parameter examples.
---    1 (string): name
---    2 (string): type
---    3 (number): value
---    4 (string): source
---    5+ (optional, varies): additional options
---@param ... any @Parameters to be passed along to the modLib.createMod function
function ModStoreClass:ReplaceMod(...)
	local mod = mod_createMod(...)
	if not self:ReplaceModInternal(mod) then
		self:AddMod(mod)
	end
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
	elseif modType == "MAX" then
		return self:Max(cfg, ...)
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

function ModStoreClass:Max(cfg, ...)
	local max
	for _, value in ipairs(self:Tabulate("MAX", cfg, ...)) do
		local val = self:EvalMod(value.mod, cfg)
		if val > (max or 0) then
			max = val
		end	
	end
	return max		
end

---HasMod
---  Checks if a mod exists with the given properties.
---  Useful for determining if the other aggregate functions will find
---  anything to aggregate.
---@param modType string @Mod type to match
---@param cfg table @Optional configuration to use - contains flags, keywordFlags, and source to match
---@param ... string @Mod name(s) to check for.
---@return boolean @true if the mod is found, false otherwise.
function ModStoreClass:HasMod(modType, cfg, ...)
	local flags, keywordFlags = 0, 0
	local source
	if cfg then
		flags = cfg.flags or 0
		keywordFlags = cfg.keywordFlags or 0
		source = cfg.source
	end
	return self:HasModInternal(modType, flags, keywordFlags, source, ...)
end

function ModStoreClass:GetCondition(var, cfg, noMod)
	return self.conditions[var] or (self.parent and self.parent:GetCondition(var, cfg, true)) or (not noMod and self:Flag(cfg, conditionName[var]))
end

function ModStoreClass:GetMultiplier(var, cfg, noMod)
	return (self.multipliers[var] or 0) + (self.parent and self.parent:GetMultiplier(var, cfg, true) or 0) + (not noMod and self:Sum("BASE", cfg, multiplierName[var]) or 0)
end

function ModStoreClass:GetStat(stat, cfg)
	if stat == "ManaReservedPercent" then
		local reservedPercentMana = 0
		for _, activeSkill in ipairs(self.actor.activeSkillList) do
			if (activeSkill.skillTypes[SkillType.Aura] and not activeSkill.skillFlags.disable and activeSkill.buffList and activeSkill.buffList[1] and activeSkill.buffList[1].name == cfg.skillName) then
				local manaBase = activeSkill.skillData["ManaReservedBase"] or 0
				reservedPercentMana = manaBase / self.actor.output["Mana"] * 100
				break
			end
		end
		return m_min(reservedPercentMana, 100) --Don't let people get more than 100% reservation for aura effect.
	end
	-- if ReservationEfficiency is -100, ManaUnreserved is nan which breaks everything if Arcane Cloak is enabled
	if stat == "ManaUnreserved" and self.actor.output[stat] ~= self.actor.output[stat] then
		-- 0% reserved = total mana
		return self.actor.output["Mana"]
	elseif stat == "ManaUnreserved" and not self.actor.output[stat] == nil and self.actor.output[stat] < 0 then
		-- This reverse engineers how much mana is unreserved before efficiency for accurate Arcane Cloak calcs
		local reservedPercentBeforeEfficiency = (math.abs(self.actor.output["ManaUnreservedPercent"]) + 100) * ((100 + self.actor["ManaEfficiency"]) / 100)
		return self.actor.output["Mana"] * (math.ceil(reservedPercentBeforeEfficiency) / 100);
	else
		return (self.actor.output and self.actor.output[stat]) or (cfg and cfg.skillStats and cfg.skillStats[stat]) or 0
	end
end

function ModStoreClass:EvalMod(mod, cfg)
	local value = mod.value
	for _, tag in ipairs(mod) do
		if tag.type == "Multiplier" then
			local target = self
			local limitTarget = self
			-- Allow limiting a self multiplier on a parent multiplier (eg. Agony Crawler on player virulence)
			-- This explicit target is necessary because even though the GetMultiplier method does call self.parent.GetMultiplier, it does so with noMod = true,
			-- disabling the summation (3rd part): (not noMod and self:Sum("BASE", cfg, multiplierName[var]) or 0)
			if tag.limitActor then
				if self.actor[tag.limitActor] then
					limitTarget = self.actor[tag.limitActor].modDB
				else
					return
				end
			end
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
				local limit = tag.limit or limitTarget:GetMultiplier(tag.limitVar, cfg)
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
			local target = self
			-- This functions similar to the above tagTypes in regard to which actor to use, but for PerStat
			-- if the actor is 'parent', we don't want to return if we're already using 'parent', just keep using 'self'
			if tag.actor and self.actor[tag.actor] then
				target = self.actor[tag.actor].modDB
			end
			if tag.statList then
				base = 0
				for _, stat in ipairs(tag.statList) do
					base = base + target:GetStat(stat, cfg)
				end
			else
				base = target:GetStat(tag.stat, cfg)
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
		elseif tag.type == "PercentStat" then
			local base
			if tag.statList then
				base = 0
				for _, stat in ipairs(tag.statList) do
					base = base + self:GetStat(stat, cfg)
				end
			else
				base = self:GetStat(tag.stat, cfg)
			end
			local mult = base * (tag.percent and tag.percent / 100 or 1)
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
			local allOneH = ((self.actor.weaponData1 and self.actor.weaponData1.countsAsAll1H) and self.actor.weaponData1) or ((self.actor.weaponData2 and self.actor.weaponData2.countsAsAll1H) and self.actor.weaponData2)
			if tag.varList then
				for _, var in pairs(tag.varList) do
					if tag.neg and allOneH and allOneH["Added"..var] ~= nil then
						-- Varunastra adds all using weapon conditions and that causes this condition to fail when it shouldn't
						-- if the condition was added by Varunastra then ignore, otherwise return as the tag condition is not satisfied
						if not allOneH["Added"..var] then
							return
						end
					elseif self:GetCondition(var, cfg) or (cfg and cfg.skillCond and cfg.skillCond[var]) then
						match = true
						break
					end
				end
			else
				if tag.neg and allOneH and allOneH["Added"..tag.var] ~= nil then
					if not allOneH["Added"..var] then
						return
					end
				else
					match = self:GetCondition(tag.var, cfg) or (cfg and cfg.skillCond and cfg.skillCond[tag.var])
				end
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
			elseif tag.actor and cfg and tag.var == nil and tag.varList == nil and tag.actor == cfg.actor then
				match = true
			end
			if tag.neg then
				match = not match
			end
			if not match then
				return
			end
		elseif tag.type == "SocketedIn" then
			if not cfg or (not tag.slotName and not tag.keyword and not tag.socketColor) then
				return
			else
				local function isValidSocket(sockets, targetSocket)
					for _, val in ipairs(sockets) do
						if val == targetSocket then
							return true
						end
					end
					return false
				end
				
				local match = {}
				if tag.slotName then
					match["slotName"] = (tag.slotName == cfg.slotName) or false
				end
				if tag.keyword then
					match["keyword"] = (cfg.skillGem and calcLib.gemIsType(cfg.skillGem, tag.keyword)) or false
				elseif tag.socketColor and tag.sockets ~= "all" then -- the all socket tag inherently checks for the correct color
					match["socketColor"] = (tag.socketColor == cfg.socketColor) or false
				end
				if tag.sockets then
					local targetAtrColor = tag.socketColor == "R" and "strengthGems" or tag.socketColor == "G" and "dexterityGems" or tag.socketColor == "B" and "intelligenceGems"
					local count = cfg[targetAtrColor] or 0
					if tag.sockets == "all" then
						local total = (cfg.intelligenceGems or 0) + (cfg.dexterityGems or 0) + (cfg.strengthGems or 0)
						match["sockets"] = (total == count) and (total > 0) or false
					elseif type(tag.sockets) == "table" and cfg.socketNum then
						match["sockets"] = (isValidSocket(tag.sockets, cfg.socketNum)) or false
					elseif type(tag.sockets) == "number" then
						match["sockets"] = (count < tag.sockets) or false
					else
						return
					end
				end
				for _, v in pairs(match) do
					if (not tag.neg and not v) or (tag.neg and v) then
						return
					end
				end
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
			if tag.neg then
				match = not match
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
			local match = false
			if tag.skillTypeList then
				for _, type in pairs(tag.skillTypeList) do
					if cfg and cfg.skillTypes and cfg.skillTypes[type] then
						match = true
						break
					end
				end
			else
				match = cfg and cfg.skillTypes and cfg.skillTypes[tag.skillType]
			end
			if tag.neg then
				match = not match
			end
			if not match then
				return
			end
		elseif tag.type == "SlotName" then
			if not cfg then
				return
			end
			local match = false
			if tag.slotNameList then
				for _, slot in ipairs(tag.slotNameList) do
					if slot == cfg.slotName then
						match = true
						break
					end
				end
			else
				match = (tag.slotName == cfg.slotName)
			end
			if tag.neg then
				match = not match
			end
			if not match then
				return
			end
		elseif tag.type == "ModFlagOr" then
			if not cfg or not cfg.flags then
				return
			end
			if band(cfg.flags, tag.modFlags) == 0 then
				return
			end
		elseif tag.type == "KeywordFlagAnd" then
			if not cfg or not cfg.keywordFlags then
				return
			end
			if band(cfg.keywordFlags, tag.keywordFlags) ~= tag.keywordFlags then
				return
			end
		end
	end	
	return value
end