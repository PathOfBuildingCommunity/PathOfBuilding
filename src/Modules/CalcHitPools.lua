local m_min = math.min
local m_max = math.max
local isElemental = { Fire = true, Cold = true, Lightning = true }
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}
local t_insert = table.insert
local s_format = string.format

--- Calculates how much damage a given hit pool will absorb
---@param pool table representing the hit pool taking damage
---@param amount number the magnitude of the incoming damage
---@param percentage float percentage of damage the pool will take on behalf of the player. Should be between 0 and 1
---@param type string name of the type of damage to be absorbed. Must be a key in the pool table
---@return number the remaining amount of damage after pool has absorbed what it can
local function genericTakeDamage(pool, amount, percentage, type)
	if pool[type] > 0 then
		local temp = m_min(amount*percentage, pool[type])
		pool[type] = pool[type] - temp
		return amount - temp
	else
		return amount
	end
end

local function maxHitBreakdown(output, breakdown, remainder, poolName, display, color)
	t_insert(
		breakdown,
		s_format(
			"\t%d "..colorCodes[color]..display.." ^7(%d remaining)",
			output[poolName] - remainder,
			remainder
		)
	)
end

local function protectPool(output, pool, mitigation, damageType)
	local mitigationPercent = mitigation / 100
	local poolProtected = pool / mitigationPercent * (1 - mitigationPercent)
	local hitPool = damageType.."TotalHitPool"
	output[hitPool] =
		m_max(output[hitPool]-poolProtected, 0) +
		m_min(output[hitPool], poolProtected) / (1 - mitigationPercent)
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

function Aegis:takeDamage(damageType, damage)
	damage = genericTakeDamage(self, damage, 1, damageType)
	if isElemental[damageType] then
		damage = genericTakeDamage(self, damage, 1, "sharedElemental")
	end
	damage = genericTakeDamage(self, damage, 1, "shared")
	return damage
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
	if output.sharedAegis and output.sharedAegis > 0 then
		maxHitBreakdown(output, breakdown, self.shared, "sharedAegis", "Shared Aegis charge", "GEM")
	end
	local receivedElemental = false
	for takenType in pairs(takenDamages) do
		receivedElemental = receivedElemental or isElemental[takenType]
		if output[takenType.."Aegis"] and output[takenType.."Aegis"] > 0 then
			maxHitBreakdown(output, breakdown, self[takenType], takenType.."Aegis", takenType.." Aegis charge", "GEM")
		end
	end
	if receivedElemental and output.sharedElementalAegis and output.sharedElementalAegis > 0 then
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


function Guard:takeDamage(damageType, damage)
	damage = genericTakeDamage(self, damage, self[damageType.."Rate"], damageType)
	damage = genericTakeDamage(self, damage, self.sharedRate, "shared")
	return damage
end

function Guard.adjustTotalHitPool(output, damageType)
	local GuardAbsorbRate = output["sharedGuardAbsorbRate"] or 0 + output[damageType.."GuardAbsorbRate"] or 0
	if GuardAbsorbRate > 0 then
		local GuardAbsorb = output["sharedGuardAbsorb"] or 0 + output[damageType.."GuardAbsorb"] or 0
		if GuardAbsorbRate >= 100 then
			output[damageType.."TotalHitPool"] = output[damageType.."TotalHitPool"] + GuardAbsorb
		else
			protectPool(output, GuardAbsorb, GuardAbsorbRate, damageType)
		end
	end
end

function Guard:displayMaxHit(output, breakdown, takenDamages)
	if output.sharedGuardAbsorb and output.sharedGuardAbsorb > 0 then
		maxHitBreakdown(output, breakdown, self.shared, "sharedGuardAbsorb", "Shared Guard charge", "SCOURGE")
	end
	for takenType in pairs(takenDamages) do
		if output[takenType.."GuardAbsorb"] and output[takenType.."GuardAbsorb"] > 0 then
			maxHitBreakdown(output, breakdown, self[takenType], takenType.."GuardAbsorb", takenType.." Guard charge", "SCOURGE")
		end
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

function AlliesTakenBeforeYou:takeDamage(damageType, damage)
	for _, allyValues in ipairs(self) do
		if not allyValues.damageType or allyValues.damageType == damageType then
			damage = genericTakeDamage(allyValues, damage, allyValues.percent, "remaining")
		end
	end
	return damage
end

function AlliesTakenBeforeYou.adjustTotalHitPool(output, damageType) 
	for i=1, #namingPairs do
		local allyNames = namingPairs[#namingPairs-i+1] -- hit pools are adjusted in reverse order
		if output[allyNames.poolName] and output[allyNames.poolName] > 0 then
			protectPool(output, output[allyNames.poolName], output[allyNames.percentName], damageType)
		end
	end
end

function AlliesTakenBeforeYou:displayMaxHit(output, breakdown)
	for _, ally in ipairs(self) do
		maxHitBreakdown(output, breakdown, ally.remaining, ally.names.poolName, ally.names.displayName, "GEM")
	end
end