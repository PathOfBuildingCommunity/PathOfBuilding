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
	return m_max(m_min(m_floor(rawChance + 0.5), 95), 5)	
end

-- Check if given support gem can support the given skill types
function calcLib.gemCanSupportTypes(gem, skillTypes)
	for _, skillType in pairs(gem.data.excludeSkillTypes) do
		if skillTypes[skillType] then
			return false
		end
	end
	if not gem.data.requireSkillTypes[1] then
		return true
	end
	for _, skillType in pairs(gem.data.requireSkillTypes) do
		if skillTypes[skillType] then
			return true
		end
	end
	return false
end

-- Check if given support gem can support the given active skill
function calcLib.gemCanSupport(gem, activeSkill)
	if gem.data.unsupported then
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
	local tags = gem.data.gemTags
	return tags and (type == "all" or (type == "elemental" and (tags.fire or tags.cold or tags.lightning)) or tags[type])
end
