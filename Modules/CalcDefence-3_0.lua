-- Path of Building
--
-- Module: Calc Defence
-- Performs defence calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_ceil = math.ceil
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local s_format = string.format

local tempTable1 = { }

local isElemental = { Fire = true, Cold = true, Lightning = true }

-- List of all damage types, ordered according to the conversion sequence
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}

local resistTypeList = { "Fire", "Cold", "Lightning", "Chaos" }

-- Calculate hit chance
function calcs.hitChance(evasion, accuracy)
	local rawChance = accuracy / (accuracy + (evasion / 4) ^ 0.8) * 115
	return m_max(m_min(round(rawChance), 100), 5)	
end

-- Calculate physical damage reduction from armour, float
function calcs.armourReductionF(armour, raw)
	return (armour / (armour + raw * 10) * 100)
end

-- Calculate physical damage reduction from armour, int
function calcs.armourReduction(armour, raw)
	return round(calcs.armourReductionF(armour, raw))
end

-- Performs all defensive calculations
function calcs.defence(env, actor)
	local modDB = actor.modDB
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local breakdown = actor.breakdown

	local condList = modDB.conditions

	-- Action Speed
	output.ActionSpeedMod = 1 + (m_max(-data.misc.TemporalChainsEffectCap, modDB:Sum("INC", nil, "TemporalChainsActionSpeed")) + modDB:Sum("INC", nil, "ActionSpeed")) / 100
	if modDB:Flag(nil, "ActionSpeedCannotBeBelowBase") then
		output.ActionSpeedMod = m_max(1, output.ActionSpeedMod)
	end

	-- Resistances
	output.PhysicalResist = m_min(data.misc.PhysicalDamageReductionCap, modDB:Sum("BASE", nil, "PhysicalDamageReduction"))
	output.PhysicalResistWhenHit = m_min(data.misc.PhysicalDamageReductionCap, output.PhysicalResist + modDB:Sum("BASE", nil, "PhysicalDamageReductionWhenHit"))
	for _, elem in ipairs(resistTypeList) do
		local max, total
		if elem == "Chaos" and modDB:Flag(nil, "ChaosInoculation") then
			max = 100
			total = 100
		else
			max = modDB:Override(nil, elem.."ResistMax") or m_min(data.misc.MaxResistCap, modDB:Sum("BASE", nil, elem.."ResistMax", isElemental[elem] and "ElementalResistMax"))
			total = modDB:Override(nil, elem.."Resist")
			if not total then
				local base = modDB:Sum("BASE", nil, elem.."Resist", isElemental[elem] and "ElementalResist")
				total = base * calcLib.mod(modDB, nil, elem.."Resist", isElemental[elem] and "ElementalResist")
			end
		end
		local final = m_min(total, max)
		output[elem.."Resist"] = final
		output[elem.."ResistTotal"] = total
		output[elem.."ResistOverCap"] = m_max(0, total - max)
		output[elem.."ResistOver75"] = m_max(0, final - 75)
		if breakdown then
			breakdown[elem.."Resist"] = {
				"Max: "..max.."%",
				"Total: "..total.."%",
			}
		end
	end

	-- Primary defences: Energy shield, evasion and armour
	do
		local ironReflexes = modDB:Flag(nil, "IronReflexes")
		local energyShield = 0
		local armour = 0
		local evasion = 0
		if breakdown then
			breakdown.EnergyShield = { slots = { } }
			breakdown.Armour = { slots = { } }
			breakdown.Evasion = { slots = { } }
		end
		local energyShieldBase, armourBase, evasionBase
		local gearEnergyShield = 0
		local gearArmour = 0
		local gearEvasion = 0
		local slotCfg = wipeTable(tempTable1)
		for _, slot in pairs({"Helmet","Body Armour","Gloves","Boots","Weapon 2","Weapon 3"}) do
			local armourData = actor.itemList[slot] and actor.itemList[slot].armourData
			if armourData then
				slotCfg.slotName = slot
				energyShieldBase = armourData.EnergyShield or 0
				if energyShieldBase > 0 then
					output["EnergyShieldOn"..slot] = energyShieldBase
					energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, slotCfg, "EnergyShield", "Defences")
					gearEnergyShield = gearEnergyShield + energyShieldBase
					if breakdown then
						breakdown.slot(slot, nil, slotCfg, energyShieldBase, nil, "EnergyShield", "Defences")
					end
				end
				armourBase = armourData.Armour or 0
				if armourBase > 0 then
					output["ArmourOn"..slot] = armourBase
					if slot == "Body Armour" and modDB:Flag(nil, "Unbreakable") then
						armourBase = armourBase * 2
					end
					armour = armour + armourBase * calcLib.mod(modDB, slotCfg, "Armour", "ArmourAndEvasion", "Defences")
					gearArmour = gearArmour + armourBase
					if breakdown then
						breakdown.slot(slot, nil, slotCfg, armourBase, nil, "Armour", "ArmourAndEvasion", "Defences")
					end
				end
				evasionBase = armourData.Evasion or 0
				if evasionBase > 0 then
					output["EvasionOn"..slot] = evasionBase
					if ironReflexes then
						armour = armour + evasionBase * calcLib.mod(modDB, slotCfg, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
						gearArmour = gearArmour + evasionBase
						if breakdown then
							breakdown.slot(slot, nil, slotCfg, evasionBase, nil, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
						end
					else
						evasion = evasion + evasionBase * calcLib.mod(modDB, slotCfg, "Evasion", "ArmourAndEvasion", "Defences")
						gearEvasion = gearEvasion + evasionBase
						if breakdown then
							breakdown.slot(slot, nil, slotCfg, evasionBase, nil, "Evasion", "ArmourAndEvasion", "Defences")
						end
					end
				end
			end
		end
		energyShieldBase = modDB:Sum("BASE", nil, "EnergyShield")
		if energyShieldBase > 0 then
			energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, nil, "EnergyShield", "Defences")
			if breakdown then
				breakdown.slot("Global", nil, nil, energyShieldBase, nil, "EnergyShield", "Defences")
			end
		end
		armourBase = modDB:Sum("BASE", nil, "Armour", "ArmourAndEvasion")
		if armourBase > 0 then
			armour = armour + armourBase * calcLib.mod(modDB, nil, "Armour", "ArmourAndEvasion", "Defences")
			if breakdown then
				breakdown.slot("Global", nil, nil, armourBase, nil, "Armour", "ArmourAndEvasion", "Defences")
			end
		end
		evasionBase = modDB:Sum("BASE", nil, "Evasion", "ArmourAndEvasion")
		if evasionBase > 0 then
			if ironReflexes then
				armour = armour + evasionBase * calcLib.mod(modDB, nil, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
				if breakdown then
					breakdown.slot("Conversion", "Evasion to Armour", nil, evasionBase, nil, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
				end
			else
				evasion = evasion + evasionBase * calcLib.mod(modDB, nil, "Evasion", "ArmourAndEvasion", "Defences")
				if breakdown then
					breakdown.slot("Global", nil, nil, evasionBase, nil, "Evasion", "ArmourAndEvasion", "Defences")
				end
			end
		end
		local convManaToES = modDB:Sum("BASE", nil, "ManaGainAsEnergyShield")
		if convManaToES > 0 then
			energyShieldBase = modDB:Sum("BASE", nil, "Mana") * convManaToES / 100
			energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, nil, "Mana", "EnergyShield", "Defences") 
			if breakdown then
				breakdown.slot("Conversion", "Mana to Energy Shield", nil, energyShieldBase, nil, "EnergyShield", "Defences", "Mana")
			end
		end
		local convLifeToArmour = modDB:Sum("BASE", nil, "LifeGainAsArmour")
		if convLifeToArmour > 0 then
			armourBase = modDB:Sum("BASE", nil, "Life") * convLifeToArmour / 100
			local total
			if modDB:Flag(nil, "ChaosInoculation") then
				total = 1
			else
				total = armourBase * calcLib.mod(modDB, nil, "Life", "Armour", "Defences") 
			end
			armour = armour + total
			if breakdown then
				breakdown.slot("Conversion", "Life to Armour", nil, armourBase, total, "Armour", "Defences", "Life")
			end
		end
		local convLifeToES = modDB:Sum("BASE", nil, "LifeConvertToEnergyShield", "LifeGainAsEnergyShield")
		if convLifeToES > 0 then
			energyShieldBase = modDB:Sum("BASE", nil, "Life") * convLifeToES / 100
			local total
			if modDB:Flag(nil, "ChaosInoculation") then
				total = 1
			else
				total = energyShieldBase * calcLib.mod(modDB, nil, "Life", "EnergyShield", "Defences")
			end
			energyShield = energyShield + total
			if breakdown then
				breakdown.slot("Conversion", "Life to Energy Shield", nil, energyShieldBase, total, "EnergyShield", "Defences", "Life")
			end
		end
		output.EnergyShield = modDB:Override(nil, "EnergyShield") or m_max(round(energyShield), 0)
		output.Armour = m_max(round(armour), 0)
		output.Evasion = m_max(round(evasion), 0)
		output.LowestOfArmourAndEvasion = m_min(output.Armour, output.Evasion)
		output["Gear:EnergyShield"] = gearEnergyShield
		output["Gear:Armour"] = gearArmour
		output["Gear:Evasion"] = gearEvasion
		if modDB:Flag(nil, "CannotEvade") then
			output.EvadeChance = 0
			output.MeleeEvadeChance = 0
			output.ProjectileEvadeChance = 0
		else
			local enemyAccuracy = round(calcLib.val(enemyDB, "Accuracy"))
			output.EvadeChance = 100 - (calcs.hitChance(output.Evasion, enemyAccuracy) - modDB:Sum("BASE", nil, "EvadeChance")) * calcLib.mod(enemyDB, nil, "HitChance")
			if breakdown then
				breakdown.EvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
					s_format("Approximate evade chance: %d%%", output.EvadeChance),
				}
			end
			output.MeleeEvadeChance = m_max(0, m_min(data.misc.EvadeChanceCap, output.EvadeChance * calcLib.mod(modDB, nil, "EvadeChance", "MeleeEvadeChance")))
			output.ProjectileEvadeChance = m_max(0, m_min(data.misc.EvadeChanceCap, output.EvadeChance * calcLib.mod(modDB, nil, "EvadeChance", "ProjectileEvadeChance")))
		end
	end

	-- Recovery modifiers
	output.LifeRecoveryRateMod = calcLib.mod(modDB, nil, "LifeRecoveryRate")
	output.ManaRecoveryRateMod = calcLib.mod(modDB, nil, "ManaRecoveryRate")
	output.EnergyShieldRecoveryRateMod = calcLib.mod(modDB, nil, "EnergyShieldRecoveryRate")

	-- Leech caps
	output.MaxLifeLeechInstance = output.Life * calcLib.val(modDB, "MaxLifeLeechInstance") / 100
	output.MaxLifeLeechRate = output.Life * calcLib.val(modDB, "MaxLifeLeechRate") / 100
	if breakdown then
		breakdown.MaxLifeLeechRate = {
			s_format("%d ^8(maximum life)", output.Life),
			s_format("x %d%% ^8(percentage of life to maximum leech rate)", calcLib.val(modDB, "MaxLifeLeechRate")),
			s_format("= %.1f", output.MaxLifeLeechRate)
		}
	end
	output.MaxEnergyShieldLeechInstance = output.EnergyShield * calcLib.val(modDB, "MaxEnergyShieldLeechInstance") / 100
	output.MaxEnergyShieldLeechRate = output.EnergyShield * calcLib.val(modDB, "MaxEnergyShieldLeechRate") / 100
	if breakdown then
		breakdown.MaxEnergyShieldLeechRate = {
			s_format("%d ^8(maximum energy shield)", output.EnergyShield),
			s_format("x %d%% ^8(percentage of energy shield to maximum leech rate)", calcLib.val(modDB, "MaxEnergyShieldLeechRate")),
			s_format("= %.1f", output.MaxEnergyShieldLeechRate)
		}
	end
	output.MaxManaLeechInstance = output.Mana * calcLib.val(modDB, "MaxManaLeechInstance") / 100
	output.MaxManaLeechRate = output.Mana * calcLib.val(modDB, "MaxManaLeechRate") / 100
	if breakdown then
		breakdown.MaxManaLeechRate = {
			s_format("%d ^8(maximum mana)", output.Mana),
			s_format("x %d%% ^8(percentage of mana to maximum leech rate)", modDB:Sum("BASE", nil, "MaxManaLeechRate")),
			s_format("= %.1f", output.MaxManaLeechRate)
		}
	end

	-- Mana, life, energy shield, and rage regen
	if modDB:Flag(nil, "NoManaRegen") then
		output.ManaRegen = 0
	else
		local base = modDB:Sum("BASE", nil, "ManaRegen") + output.Mana * modDB:Sum("BASE", nil, "ManaRegenPercent") / 100
		output.ManaRegenInc = modDB:Sum("INC", nil, "ManaRegen")
		local more = modDB:More(nil, "ManaRegen")
		if modDB:Flag(nil, "ManaRegenToRageRegen") then
			output.ManaRegenInc = 0
		end
		local regen = base * (1 + output.ManaRegenInc/100) * more
		local regenRate = round(regen * output.ManaRecoveryRateMod, 1)
		local degen = modDB:Sum("BASE", nil, "ManaDegen")
		output.ManaRegen = regenRate - degen
		if breakdown then
			breakdown.ManaRegen = { }
			breakdown.multiChain(breakdown.ManaRegen, {
				label = "Mana Regeneration:",
				base = s_format("%.1f ^8(base)", base),
				{ "%.2f ^8(increased/reduced)", 1 + output.ManaRegenInc/100 },
				{ "%.2f ^8(more/less)", more },
				total = s_format("= %.1f ^8per second", regen),
			})
			breakdown.multiChain(breakdown.ManaRegen, {
				label = "Effective Mana Regeneration:",
				base = s_format("%.1f", regen),
				{ "%.2f ^8(recovery rate modifier)", output.ManaRecoveryRateMod },
				total = s_format("= %.1f ^8per second", regenRate),
			})
			if degen ~= 0 then
				t_insert(breakdown.ManaRegen, s_format("- %d", degen))
				t_insert(breakdown.ManaRegen, s_format("= %.1f ^8per second", output.ManaRegen))
			end
		end
	end
	if modDB:Flag(nil, "NoLifeRegen") then
		output.LifeRegen = 0
	elseif modDB:Flag(nil, "ZealotsOath") then
		output.LifeRegen = 0
		local lifeBase = modDB:Sum("BASE", nil, "LifeRegen")
		if lifeBase > 0 then
			modDB:NewMod("EnergyShieldRegen", "BASE", lifeBase, "Zealot's Oath")
		end
		local lifePercent = modDB:Sum("BASE", nil, "LifeRegenPercent")
		if lifePercent > 0 then
			modDB:NewMod("EnergyShieldRegenPercent", "BASE", lifePercent, "Zealot's Oath")
		end
	else
		local lifeBase = modDB:Sum("BASE", nil, "LifeRegen")
		local lifePercent = modDB:Sum("BASE", nil, "LifeRegenPercent")
		if lifePercent > 0 then
			lifeBase = lifeBase + output.Life * lifePercent / 100
		end
		if lifeBase > 0 then
			output.LifeRegen = lifeBase * output.LifeRecoveryRateMod * (1 + modDB:Sum("MORE", nil, "LifeRegen") / 100)
		else
			output.LifeRegen = 0
		end
	end
	output.LifeRegen = output.LifeRegen - modDB:Sum("BASE", nil, "LifeDegen") + modDB:Sum("BASE", nil, "LifeRecovery") * output.LifeRecoveryRateMod
	output.LifeRegenPercent = round(output.LifeRegen / output.Life * 100, 1)
	if modDB:Flag(nil, "NoEnergyShieldRegen") then
		output.EnergyShieldRegen = 0 - modDB:Sum("BASE", nil, "EnergyShieldDegen")
		output.EnergyShieldRegenPercent = round(output.EnergyShieldRegen / output.EnergyShield * 100, 1)
	else
		local esBase = modDB:Sum("BASE", nil, "EnergyShieldRegen")
		local esPercent = modDB:Sum("BASE", nil, "EnergyShieldRegenPercent")
		if esPercent > 0 then
			esBase = esBase + output.EnergyShield * esPercent / 100
		end
		if esBase > 0 then
			output.EnergyShieldRegen = esBase * output.EnergyShieldRecoveryRateMod * calcLib.mod(modDB, nil, "EnergyShieldRegen") - modDB:Sum("BASE", nil, "EnergyShieldDegen")
			output.EnergyShieldRegenPercent = round(output.EnergyShieldRegen / output.EnergyShield * 100, 1)
		else
			output.EnergyShieldRegen = 0
		end
	end
	if modDB:Sum("BASE", nil, "RageRegen") > 0 then
		modDB:NewMod("Condition:CanGainRage", "FLAG", true, "RageRegen")
		modDB:NewMod("Dummy", "DUMMY", 1, "RageRegen", 0, { type = "Condition", var = "CanGainRage" }) -- Make the Configuration option appear
		local base = modDB:Sum("BASE", nil, "RageRegen")
		if modDB:Flag(nil, "ManaRegenToRageRegen") then
			local mana = modDB:Sum("INC", nil, "ManaRegen")
			modDB:NewMod("RageRegen", "INC", mana, "Mana Regen to Rage Regen")
		end
		local inc = modDB:Sum("INC", nil, "RageRegen")
		local more = modDB:More(nil, "RageRegen")
		output.RageRegen = base * (1 + inc /100) * more
		if breakdown then
			breakdown.RageRegen = { }
			breakdown.multiChain(breakdown.RageRegen, {
				base = s_format("%.1f ^8(base)", base),
				{ "%.2f ^8(increased/reduced)", 1 + inc/100 },
				{ "%.2f ^8(more/less)", more },
				total = s_format("= %.1f ^8per second", output.RageRegen),
			})
		end
	end
	-- Energy Shield Recharge
	if modDB:Flag(nil, "NoEnergyShieldRecharge") then
		output.EnergyShieldRecharge = 0
	else
		local inc = modDB:Sum("INC", nil, "EnergyShieldRecharge")
		local more = modDB:More(nil, "EnergyShieldRecharge")
		if modDB:Flag(nil, "EnergyShieldRechargeAppliesToLife") then
			output.EnergyShieldRechargeAppliesToLife = true
			local recharge = output.Life * data.misc.EnergyShieldRechargeBase * (1 + inc/100) * more
			output.LifeRecharge = round(recharge * output.LifeRecoveryRateMod)
			if breakdown then
				breakdown.LifeRecharge = { }
				breakdown.multiChain(breakdown.LifeRecharge, {
					label = "Recharge rate:",
					base = s_format("%.1f ^8(20%% per second)", output.Life * data.misc.EnergyShieldRechargeBase),
					{ "%.2f ^8(increased/reduced)", 1 + inc/100 },
					{ "%.2f ^8(more/less)", more },
					total = s_format("= %.1f ^8per second", recharge),
				})
				breakdown.multiChain(breakdown.LifeRecharge, {
					label = "Effective Recharge rate:",
					base = s_format("%.1f", recharge),
					{ "%.2f ^8(recovery rate modifier)", output.LifeRecoveryRateMod },
					total = s_format("= %.1f ^8per second", output.LifeRecharge),
				})	
			end
		else
			output.EnergyShieldRechargeAppliesToEnergyShield = true
			local recharge = output.EnergyShield * data.misc.EnergyShieldRechargeBase * (1 + inc/100) * more
			output.EnergyShieldRecharge = round(recharge * output.EnergyShieldRecoveryRateMod)
			if breakdown then
				breakdown.EnergyShieldRecharge = { }
				breakdown.multiChain(breakdown.EnergyShieldRecharge, {
					label = "Recharge rate:",
					base = s_format("%.1f ^8(20%% per second)", output.EnergyShield * data.misc.EnergyShieldRechargeBase),
					{ "%.2f ^8(increased/reduced)", 1 + inc/100 },
					{ "%.2f ^8(more/less)", more },
					total = s_format("= %.1f ^8per second", recharge),
				})
				breakdown.multiChain(breakdown.EnergyShieldRecharge, {
					label = "Effective Recharge rate:",
					base = s_format("%.1f", recharge),
					{ "%.2f ^8(recovery rate modifier)", output.EnergyShieldRecoveryRateMod },
					total = s_format("= %.1f ^8per second", output.EnergyShieldRecharge),
				})
			end
		end
		output.EnergyShieldRechargeDelay = 2 / (1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100)
		if breakdown then
			if output.EnergyShieldRechargeDelay ~= 2 then
				breakdown.EnergyShieldRechargeDelay = {
					"2.00s ^8(base)",
					s_format("/ %.2f ^8(faster start)", 1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100),
					s_format("= %.2fs", output.EnergyShieldRechargeDelay)
				}
			end
		end
	end

	-- Energy Shield bypass
	output.AnyBypass = false
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."EnergyShieldBypass"] = modDB:Sum("BASE", nil, damageType.."EnergyShieldBypass") or 0
		if output[damageType.."EnergyShieldBypass"] ~= 0 then
			output.AnyBypass = true
		end
		if damageType == "Chaos" then
			if not modDB:Flag(nil, "ChaosNotBypassEnergyShield") then
				output[damageType.."EnergyShieldBypass"] = output[damageType.."EnergyShieldBypass"] + 100
			else
				output.AnyBypass = true
			end
		end
		output[damageType.."EnergyShieldBypass"] = m_max(m_min(output[damageType.."EnergyShieldBypass"], 100), 0)
	end

	-- Mind over Matter
	output.AnyMindOverMatter = 0
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."MindOverMatter"] = m_min(modDB:Sum("BASE", nil, "DamageTakenFromManaBeforeLife") + modDB:Sum("BASE", nil, damageType.."DamageTakenFromManaBeforeLife"), 100)
		if output[damageType.."MindOverMatter"] > 0 then
			output.AnyMindOverMatter = output.AnyMindOverMatter + output[damageType.."MindOverMatter"]
			local sourcePool = m_max(output.ManaUnreserved or 0, 0)
			local manatext = "unreserved mana"
			if modDB:Flag(nil, "EnergyShieldProtectsMana") and output[damageType.."EnergyShieldBypass"] < 100 then
				manatext = manatext.." + non-bypassed energy shield"
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local manaProtected = output.EnergyShield / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					sourcePool = m_max(sourcePool - manaProtected, 0) + m_min(sourcePool, manaProtected)  / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					sourcePool = sourcePool + output.EnergyShield
				end
			end
			local lifeProtected = sourcePool / (output[damageType.."MindOverMatter"] / 100) * (1 - output[damageType.."MindOverMatter"] / 100)
			if output[damageType.."MindOverMatter"] >= 100 then
				output[damageType.."EffectiveLife"] = output.LifeUnreserved + sourcePool
			else
				output[damageType.."EffectiveLife"] = m_max(output.LifeUnreserved - lifeProtected, 0) + m_min(output.LifeUnreserved, lifeProtected) / (1 - output[damageType.."MindOverMatter"] / 100)
			end
			if breakdown then
				if output[damageType.."MindOverMatter"] then
					breakdown[damageType.."MindOverMatter"] = {
						s_format("Total life protected:"),
						s_format("%d ^8(%s)", sourcePool, manatext),
						s_format("/ %.2f ^8(portion taken from mana)", output[damageType.."MindOverMatter"] / 100),
						s_format("x %.2f ^8(portion taken from life)", 1 - output[damageType.."MindOverMatter"] / 100),
						s_format("= %d", lifeProtected),
						s_format("Effective life: %d", output[damageType.."EffectiveLife"])
					}
				end
			end
		else
			output[damageType.."EffectiveLife"] = output.LifeUnreserved
		end
	end

	--total pool
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."TotalPool"] = output[damageType.."EffectiveLife"]
		local manatext = "Mana"
		if output[damageType.."EnergyShieldBypass"] < 100 then 
			if modDB:Flag(nil, "EnergyShieldProtectsMana") then
				manatext = manatext.." and non-bypassed Energy Shield"
			else
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local poolProtected = output.EnergyShield / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					output[damageType.."TotalPool"] = m_max(output[damageType.."TotalPool"] - poolProtected, 0) + m_min(output[damageType.."TotalPool"], poolProtected)  / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + output.EnergyShield
				end
			end
		end
		if breakdown then
			breakdown[damageType.."TotalPool"] = {
				s_format("Life: %d", output.LifeUnreserved),
				s_format("%s through MoM: %d", manatext, output[damageType.."EffectiveLife"] - output.LifeUnreserved)
			}
			if (not modDB:Flag(nil, "EnergyShieldProtectsMana")) and output[damageType.."EnergyShieldBypass"] < 100 then
				t_insert(breakdown[damageType.."TotalPool"], s_format("Non-bypassed Energy Shield: %d", output[damageType.."TotalPool"] - output[damageType.."EffectiveLife"]))
			end
			t_insert(breakdown[damageType.."TotalPool"], s_format("TotalPool: %d", output[damageType.."TotalPool"]))
		end
	end

	-- Damage taken multipliers/Degen calculations
	for _, damageType in ipairs(dmgTypeList) do
		local baseTakenInc = modDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken")
		local baseTakenMore = modDB:More(nil, "DamageTaken", damageType.."DamageTaken")
		if isElemental[damageType] then
			baseTakenInc = baseTakenInc + modDB:Sum("INC", nil, "ElementalDamageTaken")
			baseTakenMore = baseTakenMore * modDB:More(nil, "ElementalDamageTaken")
		end
		do
			-- Hit
			local takenInc = baseTakenInc + modDB:Sum("INC", nil, "DamageTakenWhenHit", damageType.."DamageTakenWhenHit")
			local takenMore = baseTakenMore * modDB:More(nil, "DamageTakenWhenHit", damageType.."DamageTakenWhenHit")
			if isElemental[damageType] then
				takenInc = takenInc + modDB:Sum("INC", nil, "ElementalDamageTakenWhenHit")
				takenMore = takenMore * modDB:More(nil, "ElementalDamageTakenWhenHit")
			end
			output[damageType.."TakenHit"] = m_max((1 + takenInc / 100) * takenMore, 0)
			do
				-- Reflect
				takenInc = takenInc + modDB:Sum("INC", nil, damageType.."ReflectedDamageTaken")
				takenMore = takenMore * modDB:More(nil, damageType.."ReflectedDamageTaken")
				if isElemental[damageType] then
					takenInc = takenInc + modDB:Sum("INC", nil, "ElementalReflectedDamageTaken")
					takenMore = takenMore * modDB:More(nil, "ElementalReflectedDamageTaken")
				end
				output[damageType.."TakenReflect"] = m_max((1 + takenInc / 100) * takenMore, 0)
			end
		end
		do
			-- Dot
			local takenInc = baseTakenInc + modDB:Sum("INC", nil, "DamageTakenOverTime", damageType.."DamageTakenOverTime")
			local takenMore = baseTakenMore * modDB:More(nil, "DamageTakenOverTime", damageType.."DamageTakenOverTime")
			if isElemental[damageType] then
				takenInc = takenInc + modDB:Sum("INC", nil, "ElementalDamageTakenOverTime")
				takenMore = takenMore * modDB:More(nil, "ElementalDamageTakenOverTime")
			end
			local resist = output[damageType.."Resist"]
			output[damageType.."TakenDotMult"] = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
			if breakdown then
				breakdown[damageType.."TakenDotMult"] = { }
				breakdown.multiChain(breakdown[damageType.."TakenDotMult"], {
					label = "DoT Multiplier:",
					{ "%.2f ^8(%s)", (1 - output[damageType.."Resist"] / 100), damageType == "Physical" and "physical damage reduction" or "resistance" },
					{ "%.2f ^8(increased/reduced damage taken)", (1 + takenInc / 100) },
					{ "%.2f ^8(more/less damage taken)", takenMore },
					total = s_format("= %.2f", output[damageType.."TakenDotMult"]),
				})
			end
			-- Degens
			local baseVal = modDB:Sum("BASE", nil, damageType.."Degen")
			if baseVal > 0 then
				local total = baseVal * output[damageType.."TakenDotMult"]
				output[damageType.."Degen"] = total
				output.TotalDegen = (output.TotalDegen or 0) + total
				if breakdown then
					breakdown.TotalDegen = breakdown.TotalDegen or { 
						rowList = { },
						colList = {
							{ label = "Type", key = "type" },
							{ label = "Base", key = "base" },
							{ label = "Multiplier", key = "mult" },
							{ label = "Total", key = "total" },
						}
					}
					t_insert(breakdown.TotalDegen.rowList, {
						type = damageType,
						base = s_format("%.1f", baseVal),
						mult = s_format("x %.2f", output[damageType.."TakenDotMult"]),
						total = s_format("%.1f", total),
					})
					breakdown[damageType.."Degen"] = { 
						rowList = { },
						colList = {
							{ label = "Type", key = "type" },
							{ label = "Base", key = "base" },
							{ label = "Multiplier", key = "mult" },
							{ label = "Total", key = "total" },
						}
					}
					t_insert(breakdown[damageType.."Degen"].rowList, {
						type = damageType,
						base = s_format("%.1f", baseVal),
						mult = s_format("x %.2f", output[damageType.."TakenDotMult"]),
						total = s_format("%.1f", total),
					})
				end
			end
		end
	end
	if output.TotalDegen then
		output.NetLifeRegen = output.LifeRegen
		output.NetManaRegen = output.ManaRegen
		output.NetEnergyShieldRegen = output.EnergyShieldRegen
		local totalLifeDegen = 0
		local totalManaDegen = 0
		local totalEnergyShieldDegen = 0
		if breakdown then
			breakdown.NetLifeRegen = { 
					label = "Total Life Degen",
					rowList = { },
					colList = {
						{ label = "Type", key = "type" },
						{ label = "Degen", key = "degen" },
					},
				}
			breakdown.NetManaRegen = { 
					label = "Total Mana Degen",
					rowList = { },
					colList = {
						{ label = "Type", key = "type" },
						{ label = "Degen", key = "degen" },
					},
				}
			breakdown.NetEnergyShieldRegen = { 
					label = "Total Energy Shield Degen",
					rowList = { },
					colList = {
						{ label = "Type", key = "type" },
						{ label = "Degen", key = "degen" },
					},
				}
		end
		for _, damageType in ipairs(dmgTypeList) do
			if output[damageType.."Degen"] then 
				local energyShieldDegen = 0
				local lifeDegen = 0
				local manaDegen = 0
				if output.EnergyShieldRegen > 0 then 
					if modDB:Flag(nil, "EnergyShieldProtectsMana") then
						lifeDegen = output[damageType.."Degen"] * (1 - output[damageType.."MindOverMatter"] / 100)
						energyShieldDegen = output[damageType.."Degen"] * (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."MindOverMatter"] / 100)
					else
						lifeDegen = output[damageType.."Degen"] * (output[damageType.."EnergyShieldBypass"] / 100) * (1 - output[damageType.."MindOverMatter"] / 100)
						energyShieldDegen = output[damageType.."Degen"] * (1 - output[damageType.."EnergyShieldBypass"] / 100)
					end
					manaDegen = output[damageType.."Degen"] * (output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."MindOverMatter"] / 100)
				else
					lifeDegen = output[damageType.."Degen"] * (1 - output[damageType.."MindOverMatter"] / 100)
					manaDegen = output[damageType.."Degen"] * (output[damageType.."MindOverMatter"] / 100)
				end
				totalLifeDegen = totalLifeDegen + lifeDegen
				totalManaDegen = totalManaDegen + manaDegen
				totalEnergyShieldDegen = totalEnergyShieldDegen + energyShieldDegen
				if breakdown then
					t_insert(breakdown.NetLifeRegen.rowList, {
						type = s_format("%s", damageType),
						degen = s_format("%.2f", lifeDegen),
					})
					t_insert(breakdown.NetManaRegen.rowList, {
						type = s_format("%s", damageType),
						degen = s_format("%.2f", manaDegen),
					})
					t_insert(breakdown.NetEnergyShieldRegen.rowList, {
						type = s_format("%s", damageType),
						degen = s_format("%.2f", energyShieldDegen),
					})
				end
			end
		end
		output.NetLifeRegen = output.NetLifeRegen - totalLifeDegen
		output.NetManaRegen = output.NetManaRegen - totalManaDegen
		output.NetEnergyShieldRegen = output.NetEnergyShieldRegen - totalEnergyShieldDegen
		if breakdown then
			t_insert(breakdown.NetLifeRegen, s_format("%.1f ^8(total life regen)", output.LifeRegen))
			t_insert(breakdown.NetLifeRegen, s_format("- %.1f ^8(total life degen)", totalLifeDegen))
			t_insert(breakdown.NetLifeRegen, s_format("= %.1f", output.NetLifeRegen))
			t_insert(breakdown.NetManaRegen, s_format("%.1f ^8(total mana regen)", output.ManaRegen))
			t_insert(breakdown.NetManaRegen, s_format("- %.1f ^8(total mana degen)", totalManaDegen))
			t_insert(breakdown.NetManaRegen, s_format("= %.1f", output.NetManaRegen))
			t_insert(breakdown.NetEnergyShieldRegen, s_format("%.1f ^8(total energy shield regen)", output.EnergyShieldRegen))
			t_insert(breakdown.NetEnergyShieldRegen, s_format("- %.1f ^8(total energy shield degen)", totalEnergyShieldDegen))
			t_insert(breakdown.NetEnergyShieldRegen, s_format("= %.1f", output.NetEnergyShieldRegen))
		end
	end
	output.AnyTakenReflect = 0
	for _, damageType in ipairs(dmgTypeList) do
		if output[damageType.."TakenReflect"] ~= output[damageType.."TakenHit"] then
			output.AnyTakenReflect = true
		end
	end

	-- Incoming hit damage multipliers
	actor.damageShiftTable = wipeTable(actor.damageShiftTable)
	for _, damageType in ipairs(dmgTypeList) do
		-- Build damage shift table
		local shiftTable = { }
		local destTotal = 0
		for _, destType in ipairs(dmgTypeList) do
			if destType ~= damageType then
				shiftTable[destType] = modDB:Sum("BASE", nil, damageType.."DamageTakenAs"..destType, isElemental[damageType] and "ElementalDamageTakenAs"..destType or nil)
				destTotal = destTotal + shiftTable[destType]
			end
		end
		if destTotal > 100 then
			local factor = 100 / destTotal
			for destType, portion in pairs(shiftTable) do
				shiftTable[destType] = portion * factor
			end
			destTotal = 100
		end
		shiftTable[damageType] = 100 - destTotal
		actor.damageShiftTable[damageType] = shiftTable

		-- Calculate incoming damage multiplier
		local mult = 0
		local multReflect = 0
		if breakdown then
			breakdown[damageType.."TakenHitMult"] = { 
				label = "Hit Damage taken as",
				rowList = { },
				colList = {
					{ label = "Type", key = "type" },
					{ label = "Mitigation", key = "resist" },
					{ label = "Taken", key = "taken" },
					{ label = "Final", key = "final" },
				},
			}
			breakdown[damageType.."TakenReflectMult"] = { 
				label = "Hit Damage taken as",
				rowList = { },
				colList = {
					{ label = "Type", key = "type" },
					{ label = "Mitigation", key = "resist" },
					{ label = "Taken", key = "taken" },
					{ label = "Final", key = "final" },
				},
			}
		end
		for _, destType in ipairs(dmgTypeList) do
			local portion = shiftTable[destType]
			if portion > 0 then
				local resist = output[destType.."ResistWhenHit"] or output[destType.."Resist"]
				if damageType == "Physical" and destType == "Physical" then
					-- Factor in armour for Physical taken as Physical
					local damage = env.configInput.enemyPhysicalHit or env.data.monsterDamageTable[env.enemyLevel] * 1.5
					local armourReduct = calcs.armourReduction(output.Armour, damage * portion / 100)
					resist = m_min(data.misc.PhysicalDamageReductionCap, resist + armourReduct)
					output.PhysicalDamageReduction = resist
					if breakdown then
						breakdown.PhysicalDamageReduction = {
							s_format("Enemy Physical Hit Damage: %d ^8(%s the Configuration tab)", damage, env.configInput.enemyPhysicalHit and "overridden from" or "can be overridden in"),
						}
						if portion < 100 then
							t_insert(breakdown.PhysicalDamageReduction, s_format("Portion taken as Physical: %d%%", portion))
						end
						t_insert(breakdown.PhysicalDamageReduction, s_format("Reduction from Armour: %d%%", armourReduct))
					end
				end
				local takenMult = output[destType.."TakenHit"]
				local takenMultReflect = output[destType.."TakenReflect"]
				local final = portion / 100 * (1 - resist / 100) * takenMult
				local finalReflect = portion / 100 * (1 - resist / 100) * takenMultReflect
				mult = mult + final
				multReflect = multReflect + finalReflect
				if breakdown then
					t_insert(breakdown[damageType.."TakenHitMult"].rowList, {
						type = s_format("%d%% as %s", portion, destType),
						resist = s_format("x %.2f", 1 - resist / 100),
						taken = takenMult ~= 1 and s_format("x %.2f", takenMult),
						final = s_format("x %.2f", final),
					})
					if output.AnyTakenReflect then
						t_insert(breakdown[damageType.."TakenReflectMult"].rowList, {
							type = s_format("%d%% as %s", portion, destType),
							resist = s_format("x %.2f", 1 - resist / 100),
							taken = takenMultReflect ~= 1 and s_format("x %.2f", takenMultReflect),
							finalReflect = s_format("x %.2f", finalReflect),
						})
					end
				end
			end
		end
		output[damageType.."TakenHitMult"] = mult
		if output.AnyTakenReflect then
			output[damageType.."TakenReflectMult"] = multReflect
		end
	end

	-- Other defences: block, dodge, stun recovery/avoidance
	do
		output.MovementSpeedMod = modDB:Override(nil, "MovementSpeed") or calcLib.mod(modDB, nil, "MovementSpeed")
		if modDB:Flag(nil, "MovementSpeedCannotBeBelowBase") then
			output.MovementSpeedMod = m_max(output.MovementSpeedMod, 1)
		end
		output.EffectiveMovementSpeedMod = output.MovementSpeedMod * output.ActionSpeedMod
		if breakdown then
			breakdown.EffectiveMovementSpeedMod = { }
			breakdown.multiChain(breakdown.EffectiveMovementSpeedMod, {
				{ "%.2f ^8(movement speed modifier)", output.MovementSpeedMod },
				{ "%.2f ^8(action speed modifier)", output.ActionSpeedMod },
				total = s_format("= %.2f ^8(effective movement speed modifier)", output.EffectiveMovementSpeedMod)
			})
		end
		if modDB:Flag(nil, "Elusive") then
			output.ElusiveEffectMod = calcLib.mod(modDB, nil, "ElusiveEffect", "BuffEffectOnSelf") * 100
		end
		output.BlockChanceMax = modDB:Sum("BASE", nil, "BlockChanceMax")
		local baseBlockChance = 0
		if actor.itemList["Weapon 2"] and actor.itemList["Weapon 2"].armourData then
			baseBlockChance = baseBlockChance + actor.itemList["Weapon 2"].armourData.BlockChance
		end
		if actor.itemList["Weapon 3"] and actor.itemList["Weapon 3"].armourData then
			baseBlockChance = baseBlockChance + actor.itemList["Weapon 3"].armourData.BlockChance
		end
		output.ShieldBlockChance = baseBlockChance
		if modDB:Flag(nil, "MaxBlockIfNotBlockedRecently") then
			output.BlockChance = output.BlockChanceMax
		else
			output.BlockChance = m_min((baseBlockChance + modDB:Sum("BASE", nil, "BlockChance")) * calcLib.mod(modDB, nil, "BlockChance"), output.BlockChanceMax) 
		end
		output.ProjectileBlockChance = m_min(output.BlockChance + modDB:Sum("BASE", nil, "ProjectileBlockChance") * calcLib.mod(modDB, nil, "BlockChance"), output.BlockChanceMax) 
		if modDB:Flag(nil, "SpellBlockChanceMaxIsBlockChanceMax") then
			output.SpellBlockChanceMax = output.BlockChanceMax
		else
			output.SpellBlockChanceMax = modDB:Sum("BASE", nil, "SpellBlockChanceMax")
		end
		if modDB:Flag(nil, "SpellBlockChanceIsBlockChance") then
			output.SpellBlockChance = output.BlockChance
			output.SpellProjectileBlockChance = output.ProjectileBlockChance
		else
			output.SpellBlockChance = m_min(modDB:Sum("BASE", nil, "SpellBlockChance") * calcLib.mod(modDB, nil, "SpellBlockChance"), output.SpellBlockChanceMax) 
			output.SpellProjectileBlockChance = output.SpellBlockChance
		end
		if breakdown then
			breakdown.BlockChance = breakdown.simple(baseBlockChance, nil, output.BlockChance, "BlockChance")
			breakdown.SpellBlockChance = breakdown.simple(0, nil, output.SpellBlockChance, "SpellBlockChance")
		end
		if modDB:Flag(nil, "CannotBlockAttacks") then
			output.BlockChance = 0
			output.ProjectileBlockChance = 0
		end
		if modDB:Flag(nil, "CannotBlockSpells") then
			output.SpellBlockChance = 0
			output.SpellProjectileBlockChance = 0
		end
		output.BlockEffect = modDB:Sum("BASE", nil, "BlockEffect")
		if output.BlockEffect == 0 then
			output.BlockEffect = 100
		else
			output.ShowBlockEffect = true
		end
		output.LifeOnBlock = modDB:Sum("BASE", nil, "LifeOnBlock")
		output.ManaOnBlock = modDB:Sum("BASE", nil, "ManaOnBlock")
		output.EnergyShieldOnBlock = modDB:Sum("BASE", nil, "EnergyShieldOnBlock")
		output.AttackDodgeChance = m_min(modDB:Sum("BASE", nil, "AttackDodgeChance"), data.misc.DodgeChanceCap)
		output.SpellDodgeChance = m_min(modDB:Sum("BASE", nil, "SpellDodgeChance"), data.misc.DodgeChanceCap)
		if env.mode_effective and modDB:Flag(nil, "DodgeChanceIsUnlucky") then
			output.AttackDodgeChance = output.AttackDodgeChance / 100 * output.AttackDodgeChance
			output.SpellDodgeChance = output.SpellDodgeChance / 100 * output.SpellDodgeChance
		end
		-- damage avoidances
		for _, damageType in ipairs(dmgTypeList) do
			output["Avoid"..damageType.."DamageChance"] = m_min(modDB:Sum("BASE", nil, "Avoid"..damageType.."DamageChance"), data.misc.AvoidChanceCap)
		end
		output.AvoidProjectilesChance = m_min(modDB:Sum("BASE", nil, "AvoidProjectilesChance"), data.misc.AvoidChanceCap)
		--other avoidances etc
		local stunChance = 100 - m_min(modDB:Sum("BASE", nil, "AvoidStun"), 100)
		if output.EnergyShield > output.Life * 2 then
			stunChance = stunChance * 0.5
		end
		output.StunAvoidChance = 100 - stunChance
		if output.StunAvoidChance >= 100 then
			output.StunDuration = 0
			output.BlockDuration = 0
		else
			output.StunDuration = 0.35 / (1 + modDB:Sum("INC", nil, "StunRecovery") / 100)
			output.BlockDuration = 0.35 / (1 + modDB:Sum("INC", nil, "StunRecovery", "BlockRecovery") / 100)
			if breakdown then
				breakdown.StunDuration = {
					"0.35s ^8(base)",
					s_format("/ %.2f ^8(increased/reduced recovery)", 1 + modDB:Sum("INC", nil, "StunRecovery") / 100),
					s_format("= %.2fs", output.StunDuration)
				}
				breakdown.BlockDuration = {
					"0.35s ^8(base)",
					s_format("/ %.2f ^8(increased/reduced recovery)", 1 + modDB:Sum("INC", nil, "StunRecovery", "BlockRecovery") / 100),
					s_format("= %.2fs", output.BlockDuration)
				}
			end
		end
		output.InteruptStunAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidInteruptStun"), 100)
		output.ShockAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidShock"), 100)
		output.FreezeAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidFreeze"), 100)
		output.ChillAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidChill"), 100)
		output.IgniteAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidIgnite"), 100)
		output.BleedAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidBleed"), 100)
		output.PoisonAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidPoison"), 100)
		output.CritExtraDamageReduction = m_min(modDB:Sum("BASE", nil, "ReduceCritExtraDamage"), 100)
		output.LightRadiusMod = calcLib.mod(modDB, nil, "LightRadius")
		if breakdown then
			breakdown.LightRadiusMod = breakdown.mod(nil, "LightRadius")
		end
	end

	-- cumulative defences
	--chance to not be hit
	output.MeleeNotHitChance = 100 - (1 - output.MeleeEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * 100
	output.ProjectileNotHitChance = 100 - (1 - output.ProjectileEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * 100
	output.SpellNotHitChance = 100 - (1 - output.SpellDodgeChance / 100) * 100
	output.SpellProjectileNotHitChance = output.SpellNotHitChance
	output.AverageNotHitChance = (output.MeleeNotHitChance + output.ProjectileNotHitChance + output.SpellNotHitChance + output.SpellProjectileNotHitChance) / 4
	if breakdown then
		breakdown.MeleeNotHitChance = { }
		breakdown.multiChain(breakdown.MeleeNotHitChance, {
			{ "%.2f ^8(chance for evasion to fail)", 1 - output.MeleeEvadeChance / 100 },
			{ "%.2f ^8(chance for dodge to fail)", 1 - output.AttackDodgeChance / 100 },
			total = s_format("= %d%% ^8(chance to be hit by a melee attack)", 100 - output.MeleeNotHitChance),
		})
		breakdown.ProjectileNotHitChance = { }
		breakdown.multiChain(breakdown.ProjectileNotHitChance, {
			{ "%.2f ^8(chance for evasion to fail)", 1 - output.ProjectileEvadeChance / 100 },
			{ "%.2f ^8(chance for dodge to fail)", 1 - output.AttackDodgeChance / 100 },
			total = s_format("= %d%% ^8(chance to be hit by a projectile attack)", 100 - output.ProjectileNotHitChance),
		})
		breakdown.SpellNotHitChance = { }
		breakdown.multiChain(breakdown.SpellNotHitChance, {
			{ "%.2f ^8(chance for dodge to fail)", 1 - output.SpellDodgeChance / 100 },
			total = s_format("= %d%% ^8(chance to be hit by a spell)", 100 - output.SpellNotHitChance),
		})
		breakdown.SpellProjectileNotHitChance = { }
		breakdown.multiChain(breakdown.SpellProjectileNotHitChance, {
			{ "%.2f ^8(chance for dodge to fail)", 1 - output.SpellDodgeChance / 100 },
			total = s_format("= %d%% ^8(chance to be hit by a projectile spell)", 100 - output.SpellProjectileNotHitChance),
		})
	end

	--chance to not take damage if hit
	function chanceToNotTakeDamage(outputText, outputName, BlockChance, AvoidChance)
		output[outputName] = 100 - (1 - BlockChance * output.BlockEffect / 100 / 100 ) * (1 - AvoidChance / 100) * 100
		if breakdown then
			breakdown[outputName] = { }
			if output.ShowBlockEffect then
				breakdown.multiChain(breakdown[outputName], {
					{ "%.2f ^8(chance for block to fail)", 1 - BlockChance / 100 },
					{ "%d%% Damage taken from blocks", output.BlockEffect },
					{ "%.2f ^8(chance for avoidance to fail)", 1 - AvoidChance / 100 },
					total = s_format("= %d%% ^8(chance to take damage from a %s)", 100 - output[outputName], outputText),
				})
			else
				breakdown.multiChain(breakdown[outputName], {
					{ "%.2f ^8(chance for block to fail)", 1 - BlockChance / 100 },
					{ "%.2f ^8(chance for avoidance to fail)", 1 - AvoidChance / 100 },
					total = s_format("= %d%% ^8(chance to take damage from a %s)", 100 - output[outputName], outputText),
				})
			end
		end
	end

	for _, damageType in ipairs(dmgTypeList) do
		chanceToNotTakeDamage("Melee Attack", damageType.."MeleeDamageChance", output.BlockChance, output["Avoid"..damageType.."DamageChance"])
		chanceToNotTakeDamage("Projectile Attack", damageType.."ProjectileDamageChance", output.ProjectileBlockChance, m_min(output["Avoid"..damageType.."DamageChance"] + output.AvoidProjectilesChance, data.misc.AvoidChanceCap))
		chanceToNotTakeDamage("Spell", damageType.."SpellDamageChance", output.SpellBlockChance, output["Avoid"..damageType.."DamageChance"])
		chanceToNotTakeDamage("Projectile Spell", damageType.."SpellProjectileDamageChance", output.SpellProjectileBlockChance, m_min(output["Avoid"..damageType.."DamageChance"] + output.AvoidProjectilesChance, data.misc.AvoidChanceCap))
		--average
		output[damageType.."AverageDamageChance"] = (output[damageType.."MeleeDamageChance"] + output[damageType.."ProjectileDamageChance"] + output[damageType.."SpellDamageChance"] + output[damageType.."SpellProjectileDamageChance"] ) / 4
	end

	--effective health pool vs dots
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."DotEHP"] = output[damageType.."TotalPool"] / output[damageType.."TakenDotMult"]
		if breakdown then
			breakdown[damageType.."DotEHP"] = {
				s_format("Total Pool: %d", output[damageType.."TotalPool"]),
				s_format("Dot Damage Taken modifier: %.2f", output[damageType.."TakenDotMult"]),
				s_format("Total Effective Dot Pool: %d", output[damageType.."DotEHP"]),
			}
		end
	end

	--maximum hit taken
	--FIX X TAKEN AS Y (output[damageType.."TotalPool"] should use the damage types that are converted to in output[damageType.."TakenHitMult"])
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."MaximumHitTaken"] = output[damageType.."TotalPool"] / output[damageType.."TakenHitMult"]
		if breakdown then
			breakdown[damageType.."MaximumHitTaken"] = {
				s_format("Total Pool: %d", output[damageType.."TotalPool"]),
				s_format("Damage Taken modifier: %.2f", output[damageType.."TakenHitMult"]),
				s_format("Maximum hit you can take: %d", output[damageType.."MaximumHitTaken"]),
			}
		end
	end

	local DamageTypeConfig = env.configInput.EhpCalcMode or "Average"
	local minimumEHP = 2147483648
	local minimumEHPMode = "NONE"
	if DamageTypeConfig == "Minimum" then
		DamageTypeConfig = {"Melee", "Projectile", "Spell", "SpellProjectile"}
		minimumEHPMode = "Melee"
	else
		DamageTypeConfig = {DamageTypeConfig}
	end
	for _, DamageType in ipairs(DamageTypeConfig) do
		--total EHP
		for _, damageType in ipairs(dmgTypeList) do
			local convertedAvoidance = 0
			for _, damageConvertedType in ipairs(dmgTypeList) do
				convertedAvoidance = convertedAvoidance + output[damageConvertedType..DamageType.."DamageChance"] * actor.damageShiftTable[damageType][damageConvertedType] / 100
			end
			output[damageType.."TotalEHP"] = output[damageType.."MaximumHitTaken"] / (1 - output[DamageType.."NotHitChance"] / 100) / (1 - convertedAvoidance / 100)
			if minimumEHPMode ~= "NONE" then
				if output[damageType.."TotalEHP"] < minimumEHP then
					minimumEHP = output[damageType.."TotalEHP"]
					minimumEHPMode = DamageType
				end
			elseif breakdown then
				breakdown[damageType.."TotalEHP"] = {
				s_format("EHP calculation Mode: %s", DamageType),
				s_format("Maximum Hit taken: %d", output[damageType.."MaximumHitTaken"]),
				s_format("%s chance not to be hit: %d%%", DamageType, output[DamageType.."NotHitChance"]),
				s_format("%s chance to not take damage when hit: %d%%", DamageType, convertedAvoidance),
				s_format("Total Effective Hit Pool: %d", output[damageType.."TotalEHP"]),
				}
			end
		end
	end
	if minimumEHPMode ~= "NONE" then
		for _, damageType in ipairs(dmgTypeList) do
			local convertedAvoidance = 0
			for _, damageConvertedType in ipairs(dmgTypeList) do
				convertedAvoidance = convertedAvoidance + output[damageConvertedType..minimumEHPMode.."DamageChance"] * actor.damageShiftTable[damageType][damageConvertedType] / 100
			end
			output[damageType.."TotalEHP"] = output[damageType.."MaximumHitTaken"] / (1 - output[minimumEHPMode.."NotHitChance"] / 100) / (1 - convertedAvoidance / 100)
			if breakdown then
				breakdown[damageType.."TotalEHP"] = {
				s_format("EHP calculation Mode: Minimum"),
				s_format("Minimum is of type %s", minimumEHPMode),
				s_format("Maximum Hit taken: %d", output[damageType.."MaximumHitTaken"]),
				s_format("%s chance not to be hit: %d%%", minimumEHPMode, output[minimumEHPMode.."NotHitChance"]),
				s_format("%s chance to not take damage when hit: %d%%", minimumEHPMode, convertedAvoidance),
				s_format("Total Effective Hit Pool: %d", output[damageType.."TotalEHP"]),
				}
			end
		end
	end
end
