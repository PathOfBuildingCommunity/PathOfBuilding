-- Path of Building
--
-- Module: Calc Tools
-- Various functions used by the calculation modules
--

local pairs = pairs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max

calcLib = { }

-- Calculate and combine INC/MORE modifiers for the given modifier names
function calcLib.mod(modDB, cfg, ...)
	return (1 + (modDB:Sum("INC", cfg, ...)) / 100) * modDB:Sum("MORE", cfg, ...)
end

-- Calculate value
function calcLib.val(modDB, name, cfg)
	local baseVal = modDB:Sum("BASE", cfg, name)
	if baseVal ~= 0 then
		return baseVal * calcLib.mod(modDB, cfg, name)
	else
		return 0
	end
end

-- Calculate hit chance
function calcLib.hitChance(evasion, accuracy)
	local rawChance = accuracy / (accuracy + (evasion / 4) ^ 0.8) * 100
	return m_max(m_min(round(rawChance), 95), 5)	
end

-- Calculate physical damage reduction from armour
function calcLib.armourReduction(armour, raw)
	return round(armour / (armour + raw * 10) * 100)
end

-- Validate the level of the given gem
function calcLib.validateGemLevel(gem)
	if not gem.grantedEffect.levels[gem.level] then
		if gem.grantedEffect.defaultLevel then
			gem.level = gem.grantedEffect.defaultLevel
		else
			-- Try limiting to the level range of the gem
			gem.level = m_max(1, gem.level)
			if #gem.grantedEffect.levels > 0 then
				gem.level = m_min(#gem.grantedEffect.levels, gem.level)
			end
			if not gem.grantedEffect.levels[gem.level] then
				-- That failed, so just grab any level
				gem.level = next(gem.grantedEffect.levels)
			end
		end
	end	
end

-- Check if given support gem can support the given skill types
function calcLib.gemCanSupportTypes(gem, skillTypes)
	for _, skillType in pairs(gem.grantedEffect.excludeSkillTypes) do
		if skillTypes[skillType] then
			return false
		end
	end
	if not gem.grantedEffect.requireSkillTypes[1] then
		return true
	end
	for _, skillType in pairs(gem.grantedEffect.requireSkillTypes) do
		if skillTypes[skillType] then
			return true
		end
	end
	return false
end

-- Check if given support gem can support the given active skill
function calcLib.gemCanSupport(gem, activeSkill)
	if gem.grantedEffect.unsupported then
		return false
	end
	if activeSkill.summonSkill then
		return calcLib.gemCanSupport(gem, activeSkill.summonSkill)
	end
	if activeSkill.minionSkillTypes and calcLib.gemCanSupportTypes(gem, activeSkill.minionSkillTypes) then
		return true
	end
	return calcLib.gemCanSupportTypes(gem, activeSkill.skillTypes)
end

-- Check if given gem is of the given type ("all", "strength", "melee", etc)
function calcLib.gemIsType(gem, type)
	local tags = gem.grantedEffect.gemTags
	return tags and (type == "all" or (type == "elemental" and (tags.fire or tags.cold or tags.lightning)) or tags[type])
end

-- From PyPoE's formula.py
function calcLib.gemStatRequirement(level, isSupport, multi)
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