-- Path of Building
--
-- Module: Build Display Stats
-- Loads the displayStats and extraSaveStats.
--

local t_insert = table.insert

local StatList = {
	{
		{ stat = "ActiveMinionLimit", label = "Active Minion Limit", fmt = "d", displayStat = true, extraSaveStat = true },
		{ stat = "AverageHit", label = "Average Hit", fmt = ".1f", compPercent = true, displayStat = true },
		{ stat = "PvpAverageHit", label = "PvP Average Hit", fmt = ".1f", compPercent = true, flag = "isPvP", displayStat = true },
		{ stat = "AverageDamage", label = "Average Damage", fmt = ".1f", compPercent = true, flag = "attack", displayStat = true },
		{ stat = "AverageDamage", label = " Average Damage", fmt = ".1f", compPercent = true, minionDisplayStat = true },
		{ stat = "AverageBurstDamage", label = "Average Burst Damage", fmt = ".1f", compPercent = true, condFunc = function(v,o) return o.AverageBurstHits and o.AverageBurstHits > 1 and v > 0 end, displayStat = true },
		{ stat = "PvpAverageDamage", label = "PvP Average Damage", fmt = ".1f", compPercent = true, flag = "attackPvP", displayStat = true },
		{ stat = "Speed", label = "Attack Rate", fmt = ".2f", compPercent = true, flag = "attack", condFunc = function(v,o) return v > 0 and (o.TriggerTime or 0) == 0 end, displayStat = true },
		{ stat = "Speed", label = "Cast Rate", fmt = ".2f", compPercent = true, flag = "spell", condFunc = function(v,o) return v > 0 and (o.TriggerTime or 0) == 0 end, displayStat = true },
		{ stat = "Speed", label = "Attack/Cast Rate", fmt = ".2f", compPercent = true, condFunc = function(v,o) return v > 0 and (o.TriggerTime or 0) == 0 end, minionDisplayStat = true },
		{ stat = "HitSpeed", label = "Hit Rate", fmt = ".2f", minionDisplayStat = true },
		{ stat = "ServerTriggerRate", label = "Trigger Rate", fmt = ".2f", compPercent = true, condFunc = function(v,o) return (o.TriggerTime or 0) ~= 0 end, displayStat = true, minionDisplayStat = true },
		{ stat = "Speed", label = "Effective Trigger Rate", fmt = ".2f", compPercent = true, condFunc = function(v,o) return (o.TriggerTime or 0) ~= 0 and o.ServerTriggerRate ~= o.Speed end, displayStat = true, minionDisplayStat = true },
		{ stat = "WarcryCastTime", label = "Cast Time", fmt = ".2fs", compPercent = true, lowerIsBetter = true, flag = "warcry", displayStat = true },
		{ stat = "HitSpeed", label = " Hit Rate", fmt = ".2f", compPercent = true, condFunc = function(v,o) return not o.TriggerTime end, displayStat = true },
		{ stat = "TrapThrowingTime", label = "Trap Throwing Time", fmt = ".2fs", compPercent = true, lowerIsBetter = true, displayStat = true },
		{ stat = "TrapCooldown", label = "Trap Cooldown", fmt = ".3fs", lowerIsBetter = true, displayStat = true },
		{ stat = "MineLayingTime", label = "Mine Throwing Time", fmt = ".2fs", compPercent = true, lowerIsBetter = true, displayStat = true },
		{ stat = "TotemPlacementTime", label = "Totem Placement Time", fmt = ".2fs", compPercent = true, lowerIsBetter = true, displayStat = true },
		{ stat = "PreEffectiveCritChance", label = "Crit Chance", fmt = ".2f%%", displayStat = true },
		{ stat = "CritChance", label = "Effective Crit Chance", fmt = ".2f%%", condFunc = function(v,o) return v ~= o.PreEffectiveCritChance end, displayStat = true },
		{ stat = "CritMultiplier", label = "Crit Multiplier", fmt = "d%%", pc = true, condFunc = function(v,o) return (o.CritChance or 0) > 0 end, displayStat = true },
		{ stat = "HitChance", label = "Hit Chance", fmt = ".0f%%", flag = "attack", displayStat = true },
		{ stat = "HitChance", label = " Hit Chance", fmt = ".0f%%", condFunc = function(v,o) return o.enemyHasSpellBlock end, displayStat = true },
		{ stat = "TotalDPS", label = "Hit DPS", fmt = ".1f", compPercent = true, flag = "notAverage", displayStat = true },
		{ stat = "PvpTotalDPS", label = "PvP Hit DPS", fmt = ".1f", compPercent = true, flag = "notAveragePvP", displayStat = true },
		{ stat = "TotalDPS", label = " Hit DPS", fmt = ".1f", compPercent = true, flag = "showAverage", condFunc = function(v,o) return (o.TriggerTime or 0) ~= 0 end, displayStat = true },
		{ stat = "TotalDPS", label = "  Hit DPS", fmt = ".1f", compPercent = true, minionDisplayStat = true },
		{ stat = "TotalDot", label = "DoT DPS", fmt = ".1f", compPercent = true, displayStat = true, minionDisplayStat = true },
		{ stat = "WithDotDPS", label = "Total DPS inc. DoT", fmt = ".1f", compPercent = true, flag = "notAverage", condFunc = function(v,o) return v ~= o.TotalDPS and (o.PoisonDPS or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, displayStat = true },
		{ stat = "WithDotDPS", label = " Total DPS inc. DoT", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v ~= o.TotalDPS and (o.PoisonDPS or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, minionDisplayStat = true },
		{ stat = "BleedDPS", label = "Bleed DPS", fmt = ".1f", compPercent = true, warnFunc = function(v) return v >= data.misc.DotDpsCap and "Bleed DPS exceeds in game limit" end, displayStat = true, minionDisplayStat = true },
		{ stat = "BleedDamage", label = "Total Damage per Bleed", fmt = ".1f", compPercent = true, flag = "showAverage", displayStat = true },
		{ stat = "WithBleedDPS", label = "Total DPS inc. Bleed", fmt = ".1f", compPercent = true, flag = "notAverage", condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.IgniteDPS or 0) == 0 end, displayStat = true },
		{ stat = "WithBleedDPS", label = " Total DPS inc. Bleed", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.IgniteDPS or 0) == 0 end, minionDisplayStat = true },
		{ stat = "IgniteDPS", label = "Ignite DPS", fmt = ".1f", compPercent = true, warnFunc = function(v) return v >= data.misc.DotDpsCap and "Ignite DPS exceeds in game limit" end, displayStat = true, minionDisplayStat = true },
		{ stat = "IgniteDamage", label = "Total Damage per Ignite", fmt = ".1f", compPercent = true, flag = "showAverage", displayStat = true },
		{ stat = "BurningGroundDPS", label = "Burning Ground DPS", fmt = ".1f", compPercent = true, warnFunc = function(v,o) return v >= data.misc.DotDpsCap and "Burning Ground DPS exceeds in game limit" end, displayStat = true },
		{ stat = "WithIgniteDPS", label = "Total DPS inc. Ignite", fmt = ".1f", compPercent = true, flag = "notAverage", condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, displayStat = true },
		{ stat = "WithIgniteDPS", label = " Total DPS inc. Ignite", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, minionDisplayStat = true },
		{ stat = "WithIgniteAverageDamage", label = "Average Dmg. inc. Ignite", fmt = ".1f", compPercent = true, displayStat = true },
		{ stat = "PoisonDPS", label = "Poison DPS", fmt = ".1f", compPercent = true, warnFunc = function(v) return v >= data.misc.DotDpsCap and "Poison DPS exceeds in game limit" end, displayStat = true, minionDisplayStat = true },
		{ stat = "CausticGroundDPS", label = "Caustic Ground DPS", fmt = ".1f", compPercent = true, warnFunc = function(v,o) return v >= data.misc.DotDpsCap and "Caustic Ground DPS exceeds in game limit" end, displayStat = true },
		{ stat = "PoisonDamage", label = "Total Damage per Poison", fmt = ".1f", compPercent = true, displayStat = true, minionDisplayStat = true },
		{ stat = "WithPoisonDPS", label = "Total DPS inc. Poison", fmt = ".1f", compPercent = true, flag = "poison", flag = "notAverage", condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, displayStat = true },
		{ stat = "WithPoisonDPS", label = " Total DPS inc. Poison", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.ImpaleDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, minionDisplayStat = true },
		{ stat = "DecayDPS", label = "Decay DPS", fmt = ".1f", compPercent = true, displayStat = true, minionDisplayStat = true },
		{ stat = "TotalDotDPS", label = "Total DoT DPS", fmt = ".1f", compPercent = true, condFunc = function(v,o) return o.showTotalDotDPS or ( v ~= o.TotalDot and v ~= o.TotalPoisonDPS and v ~= o.CausticGroundDPS and v ~= (o.TotalIgniteDPS or o.IgniteDPS) and v ~= o.BurningGroundDPS and v ~= o.BleedDPS ) end, warnFunc = function(v) return v >= data.misc.DotDpsCap and "DoT DPS exceeds in game limit" end, displayStat = true },
		{ stat = "TotalDotDPS", label = " Total DoT DPS", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v ~= o.TotalDot and v ~= o.ImpaleDPS and v ~= o.TotalPoisonDPS and v ~= (o.TotalIgniteDPS or o.IgniteDPS) and v ~= o.BleedDPS end, warnFunc = function(v) return v >= data.misc.DotDpsCap and "DoT DPS exceeds in game limit" end, minionDisplayStat = true },
		{ stat = "ImpaleDPS", label = "Impale Damage", fmt = ".1f", compPercent = true, flag = "impale", flag = "showAverage", displayStat = true },
		{ stat = "WithImpaleDPS", label = "Damage inc. Impale", fmt = ".1f", compPercent = true, flag = "impale", flag = "showAverage", condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end , displayStat = true },
		{ stat = "ImpaleDPS", label = "Impale DPS", fmt = ".1f", compPercent = true, flag = "impale", flag = "notAverage", displayStat = true },
		{ stat = "ImpaleDPS", label = " Impale DPS", fmt = ".1f", compPercent = true, flag = "impale", minionDisplayStat = true },
		{ stat = "WithImpaleDPS", label = "Total DPS inc. Impale", fmt = ".1f", compPercent = true, flag = "impale", flag = "notAverage", condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, displayStat = true },
		{ stat = "WithImpaleDPS", label = " Total DPS inc. Impale", fmt = ".1f", compPercent = true, flag = "impale", condFunc = function(v,o) return v ~= o.TotalDPS and (o.TotalDot or 0) == 0 and (o.IgniteDPS or 0) == 0 and (o.PoisonDPS or 0) == 0 and (o.BleedDPS or 0) == 0 end, minionDisplayStat = true },
		{ stat = "MirageDPS", label = "Total Mirage DPS", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v > 0 end, displayStat = true },
		{ stat = "CullingDPS", label = "Culling DPS", fmt = ".1f", compPercent = true, condFunc = function(v,o) return (o.CullingDPS or 0) > 0 end, displayStat = true, minionDisplayStat = true },
		{ stat = "CombinedDPS", label = "Combined DPS", fmt = ".1f", compPercent = true, flag = "notAverage", condFunc = function(v,o) return v ~= ((o.TotalDPS or 0) + (o.TotalDot or 0)) and v ~= o.WithImpaleDPS and ( o.showTotalDotDPS or ( v ~= o.WithPoisonDPS and v ~= o.WithIgniteDPS and v ~= o.WithBleedDPS ) ) end, displayStat = true },
		{ stat = "CombinedDPS", label = " Combined DPS", fmt = ".1f", compPercent = true, condFunc = function(v,o) return v ~= ((o.TotalDPS or 0) + (o.TotalDot or 0)) and v ~= o.WithImpaleDPS and v ~= o.WithPoisonDPS and v ~= o.WithIgniteDPS and v ~= o.WithBleedDPS end, displayStat = true },
		{ stat = "CombinedAvg", label = "Combined Total Damage", fmt = ".1f", compPercent = true, flag = "showAverage", condFunc = function(v,o) return (v ~= o.AverageDamage and (o.TotalDot or 0) == 0) and (v ~= o.WithPoisonDPS or v ~= o.WithIgniteDPS or v ~= o.WithBleedDPS) end, displayStat = true },
		{ stat = "Cooldown", label = "Skill Cooldown", fmt = ".3fs", lowerIsBetter = true, displayStat = true, minionDisplayStat = true },
		{ stat = "SealCooldown", label = "Seal Gain Frequency", fmt = ".2fs", lowerIsBetter = true, displayStat = true },
		{ stat = "SealMax", label = "Max Number of Seals", fmt = "d", displayStat = true },
		{ stat = "TimeMaxSeals", label = "Time to Gain Max Seals", fmt = ".2fs", lowerIsBetter = true, displayStat = true },
		{ stat = "AreaOfEffectRadius", label = "AoE Radius", fmt = "d", displayStat = true },
		{ stat = "BrandAttachmentRange", label = "Attachment Range", fmt = "d", flag = "brand", displayStat = true },
		{ stat = "BrandTicks", label = "Activations per Brand", fmt = "d", flag = "brand", displayStat = true },
		{ stat = "ManaCost", label = "Mana Cost", fmt = "d", color = colorCodes.MANA, pool = "ManaUnreserved", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ManaHasCost end, displayStat = true },
		{ stat = "ManaPercentCost", label = " Mana Cost", fmt = "d%%", color = colorCodes.MANA, pool = "ManaUnreservedPercent", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ManaPercentHasCost end, displayStat = true },
		{ stat = "ManaPerSecondCost", label = "Mana Cost per second", fmt = ".2f", color = colorCodes.MANA, pool = "ManaUnreserved", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ManaPerSecondHasCost end, displayStat = true },
		{ stat = "ManaPercentPerSecondCost", label = " Mana Cost per second", fmt = ".2f%%", color = colorCodes.MANA, pool = "ManaUnreservedPercent", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ManaPercentPerSecondHasCost end, displayStat = true },
		{ stat = "LifeCost", label = "Life Cost", fmt = "d", color = colorCodes.LIFE, pool = "LifeUnreserved", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.LifeHasCost end, displayStat = true },
		{ stat = "LifePercentCost", label = " Life Cost", fmt = "d%%", color = colorCodes.LIFE, pool = "LifeUnreservedPercent", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.LifePercentHasCost end, displayStat = true },
		{ stat = "LifePerSecondCost", label = "Life Cost per second", fmt = ".2f", color = colorCodes.LIFE, pool = "LifeUnreserved", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.LifePerSecondHasCost end, displayStat = true },
		{ stat = "LifePercentPerSecondCost", label = " Life Cost per second", fmt = ".2f%%", color = colorCodes.LIFE, pool = "LifeUnreservedPercent", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.LifePercentPerSecondHasCost end, displayStat = true },
		{ stat = "ESCost", label = "Energy Shield Cost", fmt = "d", color = colorCodes.ES, pool = "EnergyShield", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ESHasCost end, displayStat = true },
		{ stat = "ESPerSecondCost", label = "ES Cost per second", fmt = ".2f", color = colorCodes.ES, pool = "EnergyShield", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ESPerSecondHasCost end, displayStat = true },
		{ stat = "ESPercentPerSecondCost", label = " ES Cost per second", fmt = ".2f%%", color = colorCodes.ES, compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.ESPercentPerSecondHasCost end, displayStat = true },
		{ stat = "RageCost", label = "Rage Cost", fmt = "d", color = colorCodes.RAGE, pool = "Rage", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.RageHasCost end, displayStat = true },
		{ stat = "RagePerSecondCost", label = "Rage Cost per second", fmt = ".2f", color = colorCodes.RAGE, pool = "Rage", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.RagePerSecondHasCost end, displayStat = true },
		{ stat = "SoulCost", label = "Soul Cost", fmt = "d", color = colorCodes.RAGE, pool = "Soul", compPercent = true, lowerIsBetter = true, condFunc = function(v,o) return o.SoulHasCost end, displayStat = true },
	}, {
		{ stat = "Str", label = "Strength", color = colorCodes.STRENGTH, fmt = "d", displayStat = true },
		{ stat = "ReqStr", label = "Strength Required", color = colorCodes.STRENGTH, fmt = "d", lowerIsBetter = true, condFunc = function(v,o) return v > o.Str end, warnFunc = function(v) return "You do not meet the Strength requirement" end, displayStat = true },
		{ stat = "Dex", label = "Dexterity", color = colorCodes.DEXTERITY, fmt = "d", displayStat = true },
		{ stat = "ReqDex", label = "Dexterity Required", color = colorCodes.DEXTERITY, fmt = "d", lowerIsBetter = true, condFunc = function(v,o) return v > o.Dex end, warnFunc = function(v) return "You do not meet the Dexterity requirement" end, displayStat = true },
		{ stat = "Int", label = "Intelligence", color = colorCodes.INTELLIGENCE, fmt = "d", displayStat = true },
		{ stat = "ReqInt", label = "Intelligence Required", color = colorCodes.INTELLIGENCE, fmt = "d", lowerIsBetter = true, condFunc = function(v,o) return v > o.Int end, warnFunc = function(v) return "You do not meet the Intelligence requirement" end, displayStat = true },
		{ stat = "Omni", label = "Omniscience", color = colorCodes.RARE, fmt = "d", displayStat = true },
		{ stat = "ReqOmni", label = "Omniscience Required", color = colorCodes.RARE, fmt = "d", lowerIsBetter = true, condFunc = function(v,o) return v > (o.Omni or 0) end, warnFunc = function(v) return "You do not meet the Omniscience requirement" end, displayStat = true },
	}, {
		{ stat = "Devotion", label = "Devotion", color = colorCodes.RARE, fmt = "d", displayStat = true, displayStat = true },
	}, {
		{ stat = "TotalEHP", label = "Effective Hit Pool", fmt = ".0f", compPercent = true, displayStat = true },
		{ stat = "PvPTotalTakenHit", label = "PvP Hit Taken", fmt = ".1f", flag = "isPvP", lowerIsBetter = true, displayStat = true },
		{ stat = "PhysicalMaximumHitTaken", label = "Phys Max Hit", fmt = ".0f", color = colorCodes.PHYS, compPercent = true, displayStat = true },
		{ stat = "LightningMaximumHitTaken", label = "Elemental Max Hit", fmt = ".0f", color = colorCodes.LIGHTNING, compPercent = true, condFunc = function(v,o) return o.LightningMaximumHitTaken == o.ColdMaximumHitTaken and o.LightningMaximumHitTaken == o.FireMaximumHitTaken end, displayStat = true },
		{ stat = "FireMaximumHitTaken", label = "Fire Max Hit", fmt = ".0f", color = colorCodes.FIRE, compPercent = true, condFunc = function(v,o) return o.LightningMaximumHitTaken ~= o.ColdMaximumHitTaken or o.LightningMaximumHitTaken ~= o.FireMaximumHitTaken end, displayStat = true },
		{ stat = "ColdMaximumHitTaken", label = "Cold Max Hit", fmt = ".0f", color = colorCodes.COLD, compPercent = true, condFunc = function(v,o) return o.LightningMaximumHitTaken ~= o.ColdMaximumHitTaken or o.LightningMaximumHitTaken ~= o.FireMaximumHitTaken end, displayStat = true },
		{ stat = "LightningMaximumHitTaken", label = "Lightning Max Hit", fmt = ".0f", color = colorCodes.LIGHTNING, compPercent = true, condFunc = function(v,o) return o.LightningMaximumHitTaken ~= o.ColdMaximumHitTaken or o.LightningMaximumHitTaken ~= o.FireMaximumHitTaken end, displayStat = true },
		{ stat = "ChaosMaximumHitTaken", label = "Chaos Max Hit", fmt = ".0f", color = colorCodes.CHAOS, compPercent = true, displayStat = true },
	}, {
		{ stat = "Life", label = "Total Life", fmt = "d", color = colorCodes.LIFE, compPercent = true, displayStat = true },
		{ stat = "Life", label = " Total Life", fmt = ".1f", color = colorCodes.LIFE, compPercent = true, minionDisplayStat = true },
		{ stat = "Spec:LifeInc", label = "%Inc Life from Tree", fmt = "d%%", color = colorCodes.LIFE, condFunc = function(v,o) return v > 0 and o.Life > 1 end, displayStat = true },
		{ stat = "LifeUnreserved", label = "Unreserved Life", fmt = "d", color = colorCodes.LIFE, condFunc = function(v,o) return v < o.Life end, compPercent = true, warnFunc = function(v) return v <= 0 and "Your unreserved Life is below 1" end, displayStat = true },
		{ stat = "LifeRecoverable", label = "Life Recoverable", fmt = "d", color = colorCodes.LIFE, condFunc = function(v,o) return v < o.LifeUnreserved end, displayStat = true },
		{ stat = "LifeUnreservedPercent", label = "Unreserved Life", fmt = "d%%", color = colorCodes.LIFE, condFunc = function(v,o) return v < 100 end, displayStat = true },
		{ stat = "LifeRegenRecovery", label = "Life Regen", fmt = ".1f", color = colorCodes.LIFE, displayStat = true, minionDisplayStat = true },
		{ stat = "LifeLeechGainRate", label = "Life Leech/On Hit Rate", fmt = ".1f", color = colorCodes.LIFE, compPercent = true, displayStat = true, minionDisplayStat = true },
		{ stat = "LifeLeechGainPerHit", label = "Life Leech/Gain per Hit", fmt = ".1f", color = colorCodes.LIFE, compPercent = true, displayStat = true },
	}, {
		{ stat = "Mana", label = "Total Mana", fmt = "d", color = colorCodes.MANA, compPercent = true, displayStat = true },
		{ stat = "Spec:ManaInc", label = "%Inc Mana from Tree", color = colorCodes.MANA, fmt = "d%%", displayStat = true },
		{ stat = "ManaUnreserved", label = "Unreserved Mana", fmt = "d", color = colorCodes.MANA, condFunc = function(v,o) return v < o.Mana end, compPercent = true, warnFunc = function(v) return v < 0 and "Your unreserved Mana is negative" end, displayStat = true },
		{ stat = "ManaUnreservedPercent", label = " Unreserved Mana", fmt = "d%%", color = colorCodes.MANA, condFunc = function(v,o) return v < 100 end, displayStat = true },
		{ stat = "ManaRegenRecovery", label = "Mana Regen", fmt = ".1f", color = colorCodes.MANA, displayStat = true },
		{ stat = "ManaLeechGainRate", label = "Mana Leech/On Hit Rate", fmt = ".1f", color = colorCodes.MANA, compPercent = true, displayStat = true },
		{ stat = "ManaLeechGainPerHit", label = "Mana Leech/Gain per Hit", fmt = ".1f", color = colorCodes.MANA, compPercent = true, displayStat = true },
	}, {
		{ stat = "EnergyShield", label = "Energy Shield", fmt = "d", color = colorCodes.ES, compPercent = true, displayStat = true, minionDisplayStat = true },
		{ stat = "EnergyShieldRecoveryCap", label = "Recoverable ES", color = colorCodes.ES, fmt = "d", condFunc = function(v,o) return o.CappingES end, displayStat = true },
		{ stat = "Spec:EnergyShieldInc", label = "%Inc ES from Tree", color = colorCodes.ES, fmt = "d%%", displayStat = true },
		{ stat = "EnergyShieldRegenRecovery", label = "Energy Shield Regen", color = colorCodes.ES, fmt = ".1f", displayStat = true, minionDisplayStat = true },
		{ stat = "EnergyShieldLeechGainRate", label = "ES Leech/On Hit Rate", color = colorCodes.ES, fmt = ".1f", compPercent = true, displayStat = true, minionDisplayStat = true },
		{ stat = "EnergyShieldLeechGainPerHit", label = "ES Leech/Gain per Hit", color = colorCodes.ES, fmt = ".1f", compPercent = true, displayStat = true },
	}, {
		{ stat = "Ward", label = "Ward", fmt = "d", color = colorCodes.WARD, compPercent = true, displayStat = true },
	}, {
		{ stat = "Rage", label = "Rage", fmt = "d", color = colorCodes.RAGE, compPercent = true, displayStat = true },
		{ stat = "RageRegenRecovery", label = "Rage Regen", fmt = ".1f", color = colorCodes.RAGE, compPercent = true, displayStat = true },
	}, {
		{ stat = "TotalDegen", label = "Total Degen", fmt = ".1f", lowerIsBetter = true, displayStat = true },
		{ stat = "TotalNetRegen", label = "Total Net Regen", fmt = "+.1f", displayStat = true },
		{ stat = "NetLifeRegen", label = "Net Life Regen", fmt = "+.1f", color = colorCodes.LIFE, displayStat = true },
		{ stat = "NetManaRegen", label = "Net Mana Regen", fmt = "+.1f", color = colorCodes.MANA, displayStat = true },
		{ stat = "NetEnergyShieldRegen", label = "Net Energy Shield Regen", fmt = "+.1f", color = colorCodes.ES, displayStat = true },
	}, {
		{ stat = "Evasion", label = "Evasion rating", fmt = "d", color = colorCodes.EVASION, compPercent = true, displayStat = true },
		{ stat = "Spec:EvasionInc", label = "%Inc Evasion from Tree", color = colorCodes.EVASION, fmt = "d%%", displayStat = true },
		{ stat = "MeleeEvadeChance", label = "Evade Chance", fmt = "d%%", color = colorCodes.EVASION, condFunc = function(v,o) return v > 0 and o.MeleeEvadeChance == o.ProjectileEvadeChance end, displayStat = true },
		{ stat = "MeleeEvadeChance", label = "Melee Evade Chance", fmt = "d%%", color = colorCodes.EVASION, condFunc = function(v,o) return v > 0 and o.MeleeEvadeChance ~= o.ProjectileEvadeChance end, displayStat = true },
		{ stat = "ProjectileEvadeChance", label = "Projectile Evade Chance", fmt = "d%%", color = colorCodes.EVASION, condFunc = function(v,o) return v > 0 and o.MeleeEvadeChance ~= o.ProjectileEvadeChance end, displayStat = true },
	}, {
		{ stat = "Armour", label = "Armour", fmt = "d", compPercent = true, displayStat = true },
		{ stat = "Spec:ArmourInc", label = "%Inc Armour from Tree", fmt = "d%%", displayStat = true },
		{ stat = "PhysicalDamageReduction", label = "Phys. Damage Reduction", fmt = "d%%", condFunc = function() return true end, displayStat = true },
	}, {
		{ stat = "BlockChance", label = "Block Chance", fmt = "d%%", overCapStat = "BlockChanceOverCap", displayStat = true },
		{ stat = "SpellBlockChance", label = "Spell Block Chance", fmt = "d%%", overCapStat = "SpellBlockChanceOverCap", displayStat = true },
		{ stat = "AttackDodgeChance", label = "Attack Dodge Chance", fmt = "d%%", overCapStat = "AttackDodgeChanceOverCap", displayStat = true },
		{ stat = "SpellDodgeChance", label = "Spell Dodge Chance", fmt = "d%%", overCapStat = "SpellDodgeChanceOverCap", displayStat = true },
		{ stat = "SpellSuppressionChance", label = "Spell Suppression Chance", fmt = "d%%", overCapStat = "SpellSuppressionChanceOverCap", displayStat = true },
	}, {
		{ stat = "FireResist", label = "Fire Resistance", fmt = "d%%", color = colorCodes.FIRE, condFunc = function() return true end, overCapStat = "FireResistOverCap"},
		{ stat = "FireResistOverCap", label = "Fire Res. Over Max", fmt = "d%%", hideStat = true, displayStat = true },
		{ stat = "ColdResist", label = "Cold Resistance", fmt = "d%%", color = colorCodes.COLD, condFunc = function() return true end, overCapStat = "ColdResistOverCap", displayStat = true },
		{ stat = "ColdResistOverCap", label = "Cold Res. Over Max", fmt = "d%%", hideStat = true, displayStat = true },
		{ stat = "LightningResist", label = "Lightning Resistance", fmt = "d%%", color = colorCodes.LIGHTNING, condFunc = function() return true end, overCapStat = "LightningResistOverCap", displayStat = true },
		{ stat = "LightningResistOverCap", label = "Lightning Res. Over Max", fmt = "d%%", hideStat = true, displayStat = true },
		{ stat = "ChaosResist", label = "Chaos Resistance", fmt = "d%%", color = colorCodes.CHAOS, condFunc = function(v,o) return not o.ChaosInoculation end, overCapStat = "ChaosResistOverCap", displayStat = true },
		{ stat = "ChaosResistOverCap", label = "Chaos Res. Over Max", fmt = "d%%", hideStat = true, displayStat = true },
		{ label = " Chaos Resistance", val = "Immune", labelStat = "ChaosResist", color = colorCodes.CHAOS, condFunc = function(o) return o.ChaosInoculation end, displayStat = true },
	}, {
		{ stat = "EffectiveMovementSpeedMod", label = "Movement Speed Modifier", fmt = "+d%%", mod = true, condFunc = function() return true end, displayStat = true },
		{ stat = "QuantityMultiplier", label = "Quantity Multiplier", fmt = "+d%%" },
		{ stat = "StoredUses", label = "Stored Uses", fmt = "d" },
		{ stat = "Duration", label = "Skill Duration", fmt = ".2f", flag = "duration" },
		{ stat = "DurationSecondary", label = "Secondary Duration", fmt = ".2f", flag = "duration" },
		{ stat = "AuraDuration", label = "Aura Duration", fmt = ".2f" },
		{ stat = "ReserveDuration", label = "Reserve Duration", fmt = ".2f" },
		{ stat = "SoulGainPreventionDuration", label = "Soul Gain Prevent.", fmt = ".2f" },
		{ stat = "SustainableTrauma", label = "Sustainable Trauma", fmt = "d" },
		{ stat = "ProjectileCount", label = "Projectile Count", fmt = "d", flag = "projectile" },
		{ stat = "PierceCountString", label = "Pierce Count", fmt = "d" },
		{ stat = "ForkCountString", label = "Fork Count", fmt = "d" },
		{ stat = "ChainMaxString", label = "Max Chain Count", fmt = "d" },
		{ stat = "ProjectileSpeedMod", label = "Proj. Speed Mod", fmt = ".2f", flag = "projectile" },
		{ stat = "BounceCount", label = "Bounces Count", fmt = "d", flag = "bounce" },
		{ stat = "AuraEffectMod", label = "Aura Effect Mod", fmt = ".2f" },
		{ stat = "CurseEffectMod", label = "Curse Effect Mod", fmt = ".2f" },
	}, {
		{ stat = "FullDPS", label = "Full DPS", fmt = ".1f", color = colorCodes.CURRENCY, compPercent = true, displayStat = true },
		{ stat = "FullDotDPS", label = "Full Dot DPS", fmt = ".1f", color = colorCodes.CURRENCY, compPercent = true, condFunc = function (v) return v >= data.misc.DotDpsCap end, warnFunc = function (v) return "Full Dot DPS exceeds in game limit" end, displayStat = true },
	}, {
		{ stat = "SkillDPS", label = "Skill DPS", condFunc = function() return true end, displayStat = true },
	}, {
		{ stat = "PowerCharges", label = "Power Charges", extraSaveStat = true },
		{ stat = "PowerChargesMax", label = "Power Charges Max", extraSaveStat = true },
		{ stat = "FrenzyCharges", label = "Frenzy Charges", extraSaveStat = true },
		{ stat = "FrenzyChargesMax", label = "Frenzy Charges Max", extraSaveStat = true },
		{ stat = "EnduranceCharges", label = "Endurance Charges", extraSaveStat = true },
		{ stat = "EnduranceChargesMax", label = "Endurance Charges Max", extraSaveStat = true },
		{ stat = "ActiveTotemLimit", label = "Active Totem Limit", extraSaveStat = true },
	}
}

--[[
-- method for generating a copy for settings
main.displayStatList = copyTable(StatList)
for _, statGroup in ipairs(main.displayStatList) do
	for _, stat in ipairs(statGroup) do
		for k, v in pairs(stat) do
			if not (k == "label" or k == "displayStat" or k == "minionDisplayStat" or k == "extraSaveStat") then
				stat[k] = nil
			end
		end
	end
end
--]]

local displayStats = {}
local minionDisplayStats = {}
local extraSaveStats = {}

local statCount = 0
local settingsStatList = main.displayStatList
if settingsStatList then
	-- first add all the missing stats that should be saved to extraSaveStats
	for _, statGroup in ipairs(StatList) do
		for _, stat in ipairs(statGroup) do
			if stat.displayStat or stat.minionDisplayStat or stat.extraSaveStat then
				local found = false
				for _, statGroup2 in ipairs(settingsStatList) do
					for _, stat2 in ipairs(statGroup2) do
						if stat2.label == stat.label then
							found = true
							break
						end
					end
					if found then
						break
					end
				end
				if not found then
					t_insert(extraSaveStats, stat.stat)
				end
			end
		end
	end
	-- then add all the stats from settings
	for _, statGroup in ipairs(settingsStatList) do
		if statCount > 0 then
			t_insert(displayStats, { })
			statCount = 0
		end
		for _, stat in ipairs(statGroup) do
			if stat.displayStat or stat.minionDisplayStat or stat.extraSaveStat then
				local found = false
				for _, statGroup2 in ipairs(StatList) do
					for _, stat2 in ipairs(statGroup2) do
						if stat2.label == stat.label then
							for k, v in pairs(stat) do
								stat2[k] = v
							end
							stat2.extraSaveStat = stat2.extraSaveStat or stat2.displayStat or stat2.minionDisplayStat
							stat2.displayStat = stat.displayStat
							stat2.minionDisplayStat = stat.minionDisplayStat
							stat = stat2
							found = true
							break
						end
					end
					if found then
						break
					end
				end
				if stat.extraSaveStat then
					stat.extraSaveStat = nil
					if not (stat.displayStat or stat.minionDisplayStat) then
						t_insert(extraSaveStats, stat.stat)
					end
				end
				if stat.displayStat then
					stat.displayStat = nil
					t_insert(displayStats, stat)
					statCount = statCount + 1
				end
				if stat.minionDisplayStat then
					stat.minionDisplayStat = nil
					t_insert(minionDisplayStats, stat)
				end
			end
		end
	end
else
	for _, statGroup in ipairs(StatList) do
		if statCount > 0 then
			t_insert(displayStats, { })
			statCount = 0
		end
		for _, stat in ipairs(statGroup) do
			if stat.displayStat then
				stat.displayStat = nil
				t_insert(displayStats, stat)
				statCount = statCount + 1
			end
			if stat.minionDisplayStat then
				stat.minionDisplayStat = nil
				t_insert(minionDisplayStats, stat)
			end
			if stat.extraSaveStat then
				stat.extraSaveStat = nil
				t_insert(extraSaveStats, stat.stat)
			end
		end
	end
end

return displayStats, minionDisplayStats, extraSaveStats