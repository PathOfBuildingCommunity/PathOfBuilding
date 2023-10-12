local m_min = math.min
local m_max = math.max
local isElemental = { Fire = true, Cold = true, Lightning = true }
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}
local t_insert = table.insert
local s_format = string.format
local m_huge = math.huge

-- Iterator to only go through some damage of a given damage table
local onlyElemental = function(damageTable)
	local idx = 2
	local function next()
		if idx > 4 then return nil end

		local key = dmgTypeList[idx]
		idx = idx + 1
		
		if not damageTable[key] then return next() end
		return key, damageTable[key]
	end
	return next
end

--- Have a pool that can only absorb a single damage type reduce incoming damage of that type
---@param pool table representing the hit pool taking damage
---@param damageTable table of damage values, keyed by damage type
---@param percentage float percentage of damage the pool will take on behalf of the player. Should be between 0 and 1
---@param type string name of the type of damage to be absorbed. Must be a key in the pool table
---@return nil
local function genericTakeDamage(pool, damageTable, percentage, type)
	if pool[type] > 0 then
		local temp = m_min(damageTable[type]*percentage, pool[type])
		pool[type] = pool[type] - temp
		damageTable[type] = damageTable[type] - temp
	end
end

--- Distributes damage of multiple types and subtracts damage absorbed from the damageTable
---@param pool table representing the hit pool taking damage
---@param damageTable table of damage values, keyed by damage type
---@param percentage number | table percentage of damage the pool will take on behalf of the player. Should be between 0 and 1
---@param resourceName string name of the resource being reduced. Must be a key in the pool table
---@param ... function optional iterator function. Must be able to traverse a damage table
---@return nil
local function genericDistributeSharedDamage(pool, damageTable, percentage, resourceName, ...)
	if pool[resourceName] > 0 then
		local iter = ... or pairs
		local poolTotal = pool[resourceName]
		local damageTotal = 0
		local ratio = {}
		if type(percentage) == "number" then
			setmetatable(ratio, {__index = function(_,_) return percentage end})
		else
			ratio = percentage
		end
		for type, damage in iter(damageTable) do
			damageTotal = damageTotal + damage * ratio[type]
		end
		if damageTotal == 0 then return end
		for type, damage in iter(damageTable) do
			local incomingDamage = damage * ratio[type]
			local damageTaken = m_min(incomingDamage, poolTotal * incomingDamage / damageTotal)
			pool[resourceName] = pool[resourceName] - damageTaken
			damageTable[type] = damage - damageTaken
		end
	end
end

local function maxHitBreakdown(output, breakdown, remainder, poolName, display, color)
	if output[poolName] and output[poolName] > 0 then
		t_insert(
			breakdown,
			s_format(
				"\t%d "..colorCodes[color]..display.." ^7(%d remaining)",
				output[poolName] - remainder,
				remainder
			)
		)
	end
end

local function protectPool(output, poolSize, mitigation, hitPool, shift)
	local bound = shift or 0
	if mitigation >= 100 then
		output[hitPool] = output[hitPool] + poolSize
	else
		local mitigationPercent = mitigation / 100
		local poolProtected = poolSize / mitigationPercent * (1 - mitigationPercent)
		output[hitPool] =
			m_max(output[hitPool]-poolProtected, -bound) +
			m_min(output[hitPool]+bound, poolProtected) / (1 - mitigationPercent)
	end
end

Aegis = {}
function Aegis.init(output, modDB)
	output.AnyAegis = false
	output["sharedAegis"] = modDB:Max(nil, "AegisValue") or 0
	output["sharedElementalAegis"] = modDB:Max(nil, "ElementalAegisValue") or 0
	if output["sharedAegis"] > 0 then
		output.AnyAegis = true
	end
	if output["sharedElementalAegis"] > 0 then
		output.ehpSectionAnySpecificTypes = true
		output.AnyAegis = true
	end
	for _, damageType in ipairs(dmgTypeList) do
		local aegisValue = modDB:Max(nil, damageType.."AegisValue") or 0
		if aegisValue > 0 then
			output.ehpSectionAnySpecificTypes = true
			output.AnyAegis = true
			output[damageType.."Aegis"] = aegisValue
		else
			output[damageType.."Aegis"] = 0
		end
		if isElemental[damageType] then
			output[damageType.."AegisDisplay"] = output[damageType.."Aegis"] + output["sharedElementalAegis"]
		end
	end
end

function Aegis:new(output)
	local aegis = {
		shared = output.sharedAegis or 0,
		sharedElemental = output.sharedElementalAegis or 0,
		Physical = output["PhysicalAegis"] or 0,
		Lightning = output["LightningAegis"] or 0,
		Cold = output["ColdAegis"] or 0,
		Fire = output["FireAegis"] or 0,
		Chaos = output["ChaosAegis"] or 0
	}
	self.__index = self
	return setmetatable(aegis, self)
end

function Aegis:takeDamage(damageTable)
	genericDistributeSharedDamage(self, damageTable, 1, "shared")
	genericDistributeSharedDamage(self, damageTable, 1, "sharedElemental", onlyElemental)
	for damageType,_ in pairs(damageTable) do
		genericTakeDamage(self, damageTable, 1, damageType)
	end
end

function Aegis.adjustTotalHitPool(output, damageType)
	output[damageType.."TotalHitPool"] =
		output[damageType.."TotalHitPool"] +
		m_max(
			output[damageType.."Aegis"],
			output["sharedAegis"],
			isElemental[damageType] and output[damageType.."AegisDisplay"] or 0
		)
end

function Aegis:displayMaxHit(output, breakdown, takenDamages)
	maxHitBreakdown(output, breakdown, self.shared, "sharedAegis", "Shared Aegis charge", "GEM")
	local receivedElemental = false
	for takenType in pairs(takenDamages) do
		receivedElemental = receivedElemental or isElemental[takenType]
		maxHitBreakdown(output, breakdown, self[takenType], takenType.."Aegis", takenType.." Aegis charge", "GEM")
	end
	if receivedElemental then
		maxHitBreakdown(output, breakdown, self.sharedElemental,  "sharedElementalAegis", "Elemental Aegis charge", "GEM")
	end
end

Guard = {}
function Guard.init(output, modDB, breakdown)
	local function display_breakdown(name)
		local GuardAbsorb = output[name.."GuardAbsorb"]
		local GuardAbsorbRate = output[name.."GuardAbsorbRate"] / 100
		local lifeProtected = GuardAbsorb / GuardAbsorbRate * (1 - GuardAbsorbRate)
		breakdown["sharedGuardAbsorb"] = {
			s_format("Total life protected:"),
			s_format("%d ^8(guard limit)", GuardAbsorb),
			s_format("/ %.2f ^8(portion taken from guard)", GuardAbsorbRate),
			s_format("x %.2f ^8(portion taken from life and energy shield)", 1 - GuardAbsorbRate),
			s_format("= %d", lifeProtected)
		}
	end
	output.AnyGuard = false
	output["sharedGuardAbsorbRate"] = m_min(modDB:Sum("BASE", nil, "GuardAbsorbRate"), 100)
	if output["sharedGuardAbsorbRate"] > 0 then
		output.OnlySharedGuard = true
		output["sharedGuardAbsorb"] = calcLib.val(modDB, "GuardAbsorbLimit")
		if breakdown then display_breakdown("shared") end
	end
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."GuardAbsorbRate"] = m_min(modDB:Sum("BASE", nil, damageType.."GuardAbsorbRate"), 100)
		if output[damageType.."GuardAbsorbRate"] > 0 then
			output.ehpSectionAnySpecificTypes = true
			output.AnyGuard = true
			output.OnlySharedGuard = false
			output[damageType.."GuardAbsorb"] = calcLib.val(modDB, damageType.."GuardAbsorbLimit")
			if breakdown then display_breakdown(damageType) end
		end
	end
end

function Guard:new(output)
	local guard = {
		shared = output.sharedGuardAbsorb or 0,
		Physical = output["PhysicalGuardAbsorb"] or 0,
		Lightning = output["LightningGuardAbsorb"] or 0,
		Cold = output["ColdGuardAbsorb"] or 0,
		Fire = output["FireGuardAbsorb"] or 0,
		Chaos = output["ChaosGuardAbsorb"] or 0,
		sharedRate = output["sharedGuardAbsorbRate"] / 100 or 0,
		PhysicalRate = output["PhysicalGuardAbsorbRate"] / 100 or 0,
		LightningRate = output["LightningGuardAbsorbRate"] / 100 or 0,
		ColdRate = output["ColdGuardAbsorbRate"] / 100 or 0,
		FireRate = output["FireGuardAbsorbRate"] / 100 or 0,
		ChaosRate = output["ChaosGuardAbsorbRate"] / 100 or 0,
	}
	self.__index = self
	return setmetatable(guard, self)
end

function Guard:takeDamage(damageTable)
	genericDistributeSharedDamage(self, damageTable, self.sharedRate, "shared")
	
	for damageType,_ in pairs(damageTable) do
		genericTakeDamage(self, damageTable, self[damageType.."Rate"], damageType)
	end
end

function Guard.adjustTotalHitPool(output, damageType)
	local GuardAbsorbRate = output["sharedGuardAbsorbRate"] or 0 + output[damageType.."GuardAbsorbRate"] or 0
	if GuardAbsorbRate > 0 then
		local GuardAbsorb = output["sharedGuardAbsorb"] or 0 + output[damageType.."GuardAbsorb"] or 0
		protectPool(output, GuardAbsorb, GuardAbsorbRate, damageType.."TotalHitPool")
	end
end

function Guard:displayMaxHit(output, breakdown, takenDamages)
	maxHitBreakdown(output, breakdown, self.shared, "sharedGuardAbsorb", "Shared Guard charge", "SCOURGE")
	for takenType in pairs(takenDamages) do
		maxHitBreakdown(output, breakdown, self[takenType], takenType.."GuardAbsorb", takenType.." Guard charge", "SCOURGE")
	end
end

local namingPairs = { -- Order is important, best known order: https://www.pathofexile.com/forum/view-thread/3123794
	{
		poolName = "AlliedEnergyShield",
		percentName = "SoulLinkMitigation",
		takenFromName = "TakenFromParentESBeforeYou",
		displayName = "Total Allied Energy Shield"
	};
	{
		poolName = "TotalRadianceSentinelLife",
		percentName = "RadianceSentinelAllyDamageMitigation",
		takenFromName = "takenFromRadianceSentinelBeforeYou",
		displayName = "Total Sentinel of Radiance Life"
	};
	{
		poolName = "TotalVaalRejuvenationTotemLife",
		percentName = "VaalRejuvenationTotemAllyDamageMitigation",
		takenFromName = "takenFromVaalRejuvenationTotemsBeforeYou",
		displayName = "Total Vaal Rejuvenation Totem Life"
	};
	{
		poolName = "TotalTotemLife",
		percentName = "TotemAllyDamageMitigation",
		takenFromName = "takenFromTotemsBeforeYou",
		displayName = "Total Totem Life"
	};
	{
		poolName = "TotalSpectreLife",
		percentName = "SpectreAllyDamageMitigation",
		takenFromName = "takenFromSpectresBeforeYou",
		displayName = "Total Spectre Life"
	};
	{
		poolName = "FrostShieldLife",
		percentName = "FrostShieldDamageMitigation",
		takenFromName = "FrostShieldDamageMitigation",
		displayName = "Frost Shield Life"
	};
}

AlliesTakenBeforeYou = {}
function AlliesTakenBeforeYou.init(output, modDB, breakdown, actor)
	for _,ally in ipairs(namingPairs) do
		output[ally.percentName] = modDB:Sum("BASE", nil, ally.takenFromName)
		if output[ally.percentName] ~= 0 then
			output[ally.poolName] = modDB:Sum("BASE", nil, ally.poolName)
		end
	end
	output["FrostShieldLife"] = output["FrostShieldLife"] or 0
	local frostShieldMitigation = output["FrostShieldDamageMitigation"] / 100
	local lifeProtected = output["FrostShieldLife"] / frostShieldMitigation * (1 - frostShieldMitigation)
	if breakdown then
		breakdown["FrostShieldLife"] = {
			s_format("Total life protected:"),
			s_format("%d ^8(frost shield limit)", output["FrostShieldLife"]),
			s_format("/ %.2f ^8(portion taken from frost shield)", frostShieldMitigation),
			s_format("x %.2f ^8(portion taken from life and energy shield)", 1 - frostShieldMitigation),
			s_format("= %d", lifeProtected),
		}
	end
	-- Vaal Rejuv. Totem stacks with regular totem mitigation
	output["VaalRejuvenationTotemAllyDamageMitigation"] =
		output["VaalRejuvenationTotemAllyDamageMitigation"] +
		output["TotemAllyDamageMitigation"]
	
	-- from Allied Energy Shield / Soul Link
	if output["SoulLinkMitigation"] == 0 then
		output["SoulLinkMitigation"] = modDB:Sum("BASE", nil, "TakenFromPartyMemberESBeforeYou")
		if output["SoulLinkMitigation"] ~= 0 then
			output["AlliedEnergyShield"] = actor.partyMembers.output.EnergyShieldRecoveryCap or 0
		end
	end
end

function AlliesTakenBeforeYou:new(output)
    local alliesTakenBeforeYou = {}
	for _, allyNames in pairs(namingPairs) do
		if output[allyNames.poolName] and output[allyNames.poolName] > 0 then
			t_insert(alliesTakenBeforeYou,{
				remaining = output[allyNames.poolName],
				percent = output[allyNames.percentName] / 100,
				names = allyNames
			})
		end
	end
    self.__index = self
	return setmetatable(alliesTakenBeforeYou, self)
end

function AlliesTakenBeforeYou:takeDamage(damageTable)
	for _, allyValues in ipairs(self) do
		genericDistributeSharedDamage(allyValues, damageTable, allyValues.percent, "remaining")
	end
end

function AlliesTakenBeforeYou.adjustTotalHitPool(output, damageType) 
	for i=1, #namingPairs do
		local allyNames = namingPairs[#namingPairs-i+1] -- hit pools are adjusted in reverse order
		if output[allyNames.poolName] and output[allyNames.poolName] > 0 then
			protectPool(output, output[allyNames.poolName], output[allyNames.percentName], damageType.."TotalHitPool")
		end
	end
end

function AlliesTakenBeforeYou:displayMaxHit(output, breakdown)
	for _, ally in ipairs(self) do
		maxHitBreakdown(output, breakdown, ally.remaining, ally.names.poolName, ally.names.displayName, "GEM")
	end
end

Ward = {}
function Ward:new(output, modDB)
	local ward = {
		remaining = output.Ward or 0,
		percent = 1 - (modDB:Sum("BASE", nil, "WardBypass") or 0) / 100,
		willBreak = not modDB:Flag(nil, "WardNotBreak")
	}
	self.__index = self
	return setmetatable(ward, self)
end

function Ward:takeDamage(damageTable)
	local nonzeroDmg = false
	for _,dmg in pairs(damageTable) do 
		nonzeroDmg = nonzeroDmg or dmg ~= 0
	end
	genericDistributeSharedDamage(self, damageTable, self.percent, "remaining")
	if nonzeroDmg and self.willBreak then 
		self.remaining = 0
	end
end

function Ward.adjustTotalHitPool(output, damageType, modDB)
	local absorbRate = 100 - (modDB:Sum("BASE", nil, "WardBypass") or 0)
	protectPool(output, output.Ward or 0, absorbRate, damageType.."TotalHitPool")
end

function Ward:displayMaxHit(output, breakdown)
	maxHitBreakdown(output, breakdown, self.remaining, "Ward", "Ward", "WARD")
end

EnergyShield = {}
function EnergyShield:new(output)
	local es = {
		remaining = output.EnergyShieldRecoveryCap,
		percent = {
			Physical = 1 - (output["PhysicalEnergyShieldBypass"] or 0) / 100,
			Lightning = 1 - (output["LightningEnergyShieldBypass"] or 0) / 100,
			Cold = 1 - (output["ColdEnergyShieldBypass"] or 0) / 100,
			Fire = 1 - (output["FireEnergyShieldBypass"] or 0) / 100,
			Chaos = 1 - (output["ChaosEnergyShieldBypass"] or 0) / 100
		}
	}
	self.__index = self
	return setmetatable(es, self)
end

function EnergyShield:takeDamage(damageTable)
	genericDistributeSharedDamage(self, damageTable, self.percent, "remaining")
end

MindOverMatter = {}
function MindOverMatter.init(output, modDB, breakdown)
	local function display_breakdown(type, source, text, amount)
		local poolProtected = source / amount * (1 - amount)
		if output[type.."MindOverMatter"] >= 100 then
			poolProtected = m_huge
		end
		if output[type.."MindOverMatter"] then
			breakdown[type.."MindOverMatter"] = {
				s_format("Total life protected:"),
				s_format("%d ^8(%s)", source, text),
				s_format("/ %.2f ^8(portion taken from mana)", amount),
				s_format("x %.2f ^8(portion taken from life)", 1 - amount),
				s_format("= %d", poolProtected),
				s_format("Effective life: %d", output[type.."ManaEffectiveLife"])
			}
		end
	end
	local function protect(type, bypassName)
		local sourcePool = m_max(output.ManaUnreserved or 0, 0)
		local sourceHitPool = sourcePool
		local manatext = "unreserved mana"
		local bypass = output[bypassName]
		local momRate = output[type.."MindOverMatter"]
		if type ~= "shared" then
			momRate = momRate + output["sharedMindOverMatter"]
		end
		if modDB:Flag(nil, "EnergyShieldProtectsMana") and bypass < 100 then
			manatext = manatext.." + non-bypassed energy shield"
			local absorbRate = 100 - bypass
			local dummy = {source = sourcePool; sourceHit = sourceHitPool}
			protectPool(dummy, output.EnergyShieldRecoveryCap, absorbRate, "source", output.LifeRecoverable)
			protectPool(dummy, output.EnergyShieldRecoveryCap, absorbRate, "sourceHit", output.LifeHitPool)
			sourcePool = dummy.source
			sourceHitPool = dummy.sourceHit
		end
		protectPool(output, sourcePool, momRate, type.."ManaEffectiveLife")
		protectPool(output, sourceHitPool, momRate, type.."MoMHitPool")
		if breakdown then
			display_breakdown(type, sourcePool, manatext, momRate / 100)
		end
	end
	output.OnlySharedMindOverMatter = false
	output.AnySpecificMindOverMatter = false
	output["sharedMindOverMatter"] = m_min(modDB:Sum("BASE", nil, "DamageTakenFromManaBeforeLife"), 100)
	output["sharedManaEffectiveLife"] = output.LifeRecoverable
	output["sharedMoMHitPool"] = output.LifeHitPool
	if output["sharedMindOverMatter"] > 0 then
		output.OnlySharedMindOverMatter = true
		protect("shared", "MinimumBypass")
	end
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."MindOverMatter"] = m_min(modDB:Sum("BASE", nil, damageType.."DamageTakenFromManaBeforeLife"), 100 - output["sharedMindOverMatter"])
		output[damageType.."ManaEffectiveLife"] = output.LifeRecoverable
		output[damageType.."MoMHitPool"] = output.LifeHitPool
		if output[damageType.."MindOverMatter"] > 0 or (output[damageType.."EnergyShieldBypass"] > output.MinimumBypass and output["sharedMindOverMatter"] > 0) then
			output.ehpSectionAnySpecificTypes = true
			output.AnySpecificMindOverMatter = true
			output.OnlySharedMindOverMatter = false
			protect(damageType, damageType.."EnergyShieldBypass")
		else
			output[damageType.."ManaEffectiveLife"] = output["sharedManaEffectiveLife"]
			output[damageType.."MoMHitPool"] = output["sharedMoMHitPool"]
		end
	end
end

function MindOverMatter:new(output)
	local shared = output["sharedMindOverMatter"] / 100
	local mana = {
		sharedRate = shared,
		PhysicalRate = shared + output["PhysicalMindOverMatter"] / 100 or 0,
		LightningRate = shared + output["LightningMindOverMatter"] / 100 or 0,
		ColdRate = shared + output["ColdMindOverMatter"] / 100 or 0,
		FireRate = shared + output["FireMindOverMatter"] / 100 or 0,
		ChaosRate = shared + output["ChaosMindOverMatter"] / 100 or 0,
	}
	self.__index = self
	return setmetatable(mana, self)
end