-- Path of Building
--
-- Module: Calc Tools
-- Various functions used by the calculation modules
--
local pairs = pairs
local t_insert = table.insert
local t_remove = table.remove
local m_floor = math.floor
local m_min = math.min
local m_max = math.max

calcLib = { }

-- Calculate and combine INC/MORE modifiers for the given modifier names
function calcLib.mod(modStore, cfg, ...)
	return (1 + (modStore:Sum("INC", cfg, ...)) / 100) * modStore:More(cfg, ...)
end

-- Calculate value
function calcLib.val(modStore, name, cfg)
	local baseVal = modStore:Sum("BASE", cfg, name)
	if baseVal ~= 0 then
		return baseVal * calcLib.mod(modStore, cfg, name)
	else
		return 0
	end
end

-- Validate the level of the given gem
function calcLib.validateGemLevel(gemInstance)
	local grantedEffect = gemInstance.grantedEffect or gemInstance.gemData.grantedEffect
	if not grantedEffect.levels[gemInstance.level] then
		if gemInstance.gemData and gemInstance.gemData.defaultLevel then
			gemInstance.level = gemInstance.gemData.defaultLevel
		else
			-- Try limiting to the level range of the skill
			gemInstance.level = m_max(1, gemInstance.level)
			if #grantedEffect.levels > 0 then
				gemInstance.level = m_min(#grantedEffect.levels, gemInstance.level)
			end
			if not grantedEffect.levels[gemInstance.level] then
				-- That failed, so just grab any level
				gemInstance.level = next(grantedEffect.levels)
			end
		end
	end	
end

-- Evaluate a skill type postfix expression
function calcLib.doesTypeExpressionMatch(checkTypes, skillTypes, minionTypes)
	local stack = { }
	for _, skillType in pairs(checkTypes) do
		if skillType == SkillType.OR then
			local other = t_remove(stack)
			stack[#stack] = stack[#stack] or other
		elseif skillType == SkillType.AND then
			local other = t_remove(stack)
			stack[#stack] = stack[#stack] and other
		elseif skillType == SkillType.NOT then
			stack[#stack] = not stack[#stack]
		else
			t_insert(stack, skillTypes[skillType] or (minionTypes and minionTypes[skillType]) or false)
		end
	end
	for _, val in ipairs(stack) do
		if val then
			return true
		end
	end
	return false
end

-- Check if given support skill can support the given active skill
function calcLib.canGrantedEffectSupportActiveSkill(grantedEffect, activeSkill)
	if grantedEffect.unsupported or activeSkill.activeEffect.grantedEffect.cannotBeSupported then
		return false
	end
	if grantedEffect.supportGemsOnly and not activeSkill.activeEffect.gemData then
		return false
	end
	if activeSkill.summonSkill then
		return calcLib.canGrantedEffectSupportActiveSkill(grantedEffect, activeSkill.summonSkill)
	end
	if grantedEffect.excludeSkillTypes[1] and calcLib.doesTypeExpressionMatch(grantedEffect.excludeSkillTypes, activeSkill.skillTypes) then
		return false
	end
	return not grantedEffect.requireSkillTypes[1] or calcLib.doesTypeExpressionMatch(grantedEffect.requireSkillTypes, activeSkill.skillTypes, not grantedEffect.ignoreMinionTypes and activeSkill.minionSkillTypes)
end

-- Check if given gem is of the given type ("all", "strength", "melee", etc)
function calcLib.gemIsType(gem, type)
	return (type == "all" or 
			(type == "elemental" and (gem.tags.fire or gem.tags.cold or gem.tags.lightning)) or 
			(type == "aoe" and gem.tags.area) or
			(type == "trap or mine" and (gem.tags.trap or gem.tags.mine)) or
			(type == gem.name:lower()) or
			gem.tags[type])
end

-- From PyPoE's formula.py
function calcLib.getGemStatRequirement(level, isSupport, multi)
	if multi == 0 then
		return 0
	end
	local a, b
	if isSupport then
        b = 6 * multi / 100
		if multi == 100 then
			a = 1.495
        elseif multi == 60 then
            a = 0.945
        elseif multi == 40 then
            a = 0.6575
		else
			return 0
		end
    else
        b = 8 * multi / 100
        if multi == 100 then
            a = 2.1
            b = 7.75
        elseif multi == 60 then
            a = 1.325
        elseif multi == 40 then
            a = 0.924
		else
			return 0
		end
	end
	local req = round(level * a + b)
    return req < 14 and 0 or req
end

-- Build table of stats for the given skill instance
function calcLib.buildSkillInstanceStats(skillInstance, grantedEffect)
	local stats = { }
	if skillInstance.quality > 0 then
		for _, stat in ipairs(grantedEffect.qualityStats) do
			stats[stat[1]] = (stats[stat[1]] or 0) + m_floor(stat[2] * skillInstance.quality)
		end
	end
	local level = grantedEffect.levels[skillInstance.level]
	local availableEffectiveness
	local actorLevel = skillInstance.actorLevel or level.levelRequirement
	for index, stat in ipairs(grantedEffect.stats) do
		local statValue
		if level.statInterpolation[index] == 3 then
			-- Effectiveness interpolation
			if not availableEffectiveness then
				availableEffectiveness = 
					(3.885209 + 0.360246 * (actorLevel - 1)) * grantedEffect.baseEffectiveness
					* (1 + grantedEffect.incrementalEffectiveness) ^ (actorLevel - 1)
			end
			statValue = round(availableEffectiveness * level[index])
		elseif level.statInterpolation[index] == 2 then
			-- Linear interpolation; I'm actually just guessing how this works
			local nextLevel = m_min(skillInstance.level + 1, #grantedEffect.levels)
			local nextReq = grantedEffect.levels[nextLevel].levelRequirement
			local prevReq = grantedEffect.levels[nextLevel - 1].levelRequirement
			local nextStat = grantedEffect.levels[nextLevel][index]
			local prevStat = grantedEffect.levels[nextLevel - 1][index]
			statValue = round(prevStat + (nextStat - prevStat) * (actorLevel - prevReq) / (nextReq - prevReq))
		else
			-- Static value
			statValue = level[index] or 1
		end
		stats[stat] = (stats[stat] or 0) + statValue
	end
	return stats
end