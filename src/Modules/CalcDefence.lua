-- Path of Building
--
-- Module: Calc Defence
-- Performs defence calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local m_huge = math.huge
local s_format = string.format

local tempTable1 = { }

local isElemental = { Fire = true, Cold = true, Lightning = true }

-- List of all damage types, ordered according to the conversion sequence
local hitSourceList = {"Attack", "Spell"}
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}

local resistTypeList = { "Fire", "Cold", "Lightning", "Chaos" }

-- Calculate hit chance
function calcs.hitChance(evasion, accuracy)
	if accuracy < 0 then
		return 5
	end
	local rawChance = accuracy / (accuracy + (evasion / 5) ^ 0.9) * 125
	return m_max(m_min(round(rawChance), 100), 5)	
end

-- Calculate damage reduction from armour, float
function calcs.armourReductionF(armour, raw)
	if armour == 0 and raw == 0 then
		return 0
	end
	return (armour / (armour + raw * 5) * 100)
end

-- Calculate damage reduction from armour, int
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
	output.ActionSpeedMod = calcs.actionSpeedMod(actor)

	-- Resistances
	output.DamageReductionMax = modDB:Override(nil, "DamageReductionMax") or data.misc.DamageReductionCap
	output.BasePhysicalDamageReduction = m_min(m_max(0, modDB:Sum("BASE", nil, "PhysicalDamageReduction")), output.DamageReductionMax)
	output.BasePhysicalDamageReductionWhenHit = m_min(m_max(0, output.BasePhysicalDamageReduction + modDB:Sum("BASE", nil, "PhysicalDamageReductionWhenHit")), output.DamageReductionMax)
	modDB:NewMod("ArmourAppliesToPhysicalDamageTaken", "BASE", 100)
	output["PhysicalResist"] = 0

	-- Highest Maximum Elemental Resistance for Melding of the Flesh
	if modDB:Flag(nil, "ElementalResistMaxIsHighestResistMax") then
		local highestResistMax = 0;
		local highestResistMaxType = "";
		for _, elem in ipairs(resistTypeList) do
			local resistMax = modDB:Override(nil, elem.."ResistMax") or m_min(data.misc.MaxResistCap, modDB:Sum("BASE", nil, elem.."ResistMax", isElemental[elem] and "ElementalResistMax"))
			if resistMax > highestResistMax and isElemental[elem] then
				highestResistMax = resistMax;
				highestResistMaxType = elem;
			end
		end
		for _, elem in ipairs(resistTypeList) do
			if isElemental[elem] then
				modDB:NewMod(elem.."ResistMax", "OVERRIDE", highestResistMax, highestResistMaxType.." Melding of the Flesh");
			end
		end
	end
	
	for _, elem in ipairs(resistTypeList) do
		local min, max, total
		min = data.misc.ResistFloor
		max = modDB:Override(nil, elem.."ResistMax") or m_min(data.misc.MaxResistCap, modDB:Sum("BASE", nil, elem.."ResistMax", isElemental[elem] and "ElementalResistMax"))
		totemMax = modDB:Override(nil, "Totem"..elem.."ResistMax") or m_min(data.misc.MaxResistCap, modDB:Sum("BASE", nil, "Totem"..elem.."ResistMax", isElemental[elem] and "TotemElementalResistMax"))
		total = modDB:Override(nil, elem.."Resist")
		totemTotal = modDB:Override(nil, "Totem"..elem.."Resist")
		if not total then
			local base = modDB:Sum("BASE", nil, elem.."Resist", isElemental[elem] and "ElementalResist")
			total = base * calcLib.mod(modDB, nil, elem.."Resist", isElemental[elem] and "ElementalResist")
		end
		if not totemTotal then
			local base = modDB:Sum("BASE", nil, "Totem"..elem.."Resist", isElemental[elem] and "TotemElementalResist")
			totemTotal = base * calcLib.mod(modDB, nil, "Totem"..elem.."Resist", isElemental[elem] and "TotemElementalResist")
		end
		local final = m_max(m_min(total, max), min)
		local totemFinal = m_max(m_min(totemTotal, totemMax), min)
		output["Base"..elem.."DamageReduction"] = 0
		output[elem.."Resist"] = final
		output[elem.."ResistTotal"] = total
		output[elem.."ResistOverCap"] = m_max(0, total - max)
		output[elem.."ResistOver75"] = m_max(0, final - 75)
		output["Missing"..elem.."Resist"] = m_max(0, totemMax - final)
		output["Totem"..elem.."Resist"] = totemFinal
		output["Totem"..elem.."ResistTotal"] = totemTotal
		output["Totem"..elem.."ResistOverCap"] = m_max(0, totemTotal - totemMax)
		output["MissingTotem"..elem.."Resist"] = m_max(0, totemMax - totemFinal)
		if breakdown then
			breakdown[elem.."Resist"] = {
				"Min: "..min.."%",
				"Max: "..max.."%",
				"Total: "..total.."%",
			}
			breakdown["Totem"..elem.."Resist"] = {
				"Min: "..min.."%",
				"Max: "..totemMax.."%",
				"Total: "..totemTotal.."%",
			}
		end
	end

	-- Block
	output.BlockChanceMax = modDB:Sum("BASE", nil, "BlockChanceMax")
	output.BlockChanceOverCap = 0
	output.SpellBlockChanceOverCap = 0
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
		local totalBlockChance = (baseBlockChance + modDB:Sum("BASE", nil, "BlockChance")) * calcLib.mod(modDB, nil, "BlockChance")
		output.BlockChance = m_min(totalBlockChance, output.BlockChanceMax)
		output.BlockChanceOverCap = m_max(0, totalBlockChance - output.BlockChanceMax)
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
		output.SpellBlockChanceOverCap = output.BlockChanceOverCap
	else
		local totalSpellBlockChance = modDB:Sum("BASE", nil, "SpellBlockChance") * calcLib.mod(modDB, nil, "SpellBlockChance")
		output.SpellBlockChance = m_min(totalSpellBlockChance, output.SpellBlockChanceMax)
		output.SpellBlockChanceOverCap = m_max(0, totalSpellBlockChance - output.SpellBlockChanceMax)
		output.SpellProjectileBlockChance = output.SpellBlockChance
	end
	if breakdown then
		breakdown.BlockChance = {
			"Base: "..baseBlockChance.."%",
			"Max: "..output.BlockChanceMax.."%",
			"Total: "..output.BlockChance+output.BlockChanceOverCap.."%",
		}
		breakdown.SpellBlockChance = {
			"Max: "..output.SpellBlockChanceMax.."%",
			"Total: "..output.SpellBlockChance+output.SpellBlockChanceOverCap.."%",
		}
	end
	if modDB:Flag(nil, "CannotBlockAttacks") then
		output.BlockChance = 0
		output.ProjectileBlockChance = 0
	end
	if modDB:Flag(nil, "CannotBlockSpells") then
		output.SpellBlockChance = 0
		output.SpellProjectileBlockChance = 0
	end
	output.AverageBlockChance = (output.BlockChance + output.ProjectileBlockChance + output.SpellBlockChance + output.SpellProjectileBlockChance) / 4
	output.BlockEffect = m_max(100 - modDB:Sum("BASE", nil, "BlockEffect"), 0)
	if output.BlockEffect == 0 then
		output.BlockEffect = 100
	else
		output.ShowBlockEffect = true
		output.DamageTakenOnBlock = 100 - output.BlockEffect
	end

	if modDB:Flag(nil, "ArmourAppliesToEnergyShieldRecharge") then
		-- Armour to ES Recharge conversion from Armour and Energy Shield Mastery
		local multiplier = (modDB:Max(nil, "ImprovedArmourAppliesToEnergyShieldRecharge") or 100) / 100
		for _, value in ipairs(modDB:Tabulate("INC", nil, "Armour", "ArmourAndEvasion", "Defences")) do
			local mod = value.mod
			local modifiers = calcLib.getConvertedModTags(mod, multiplier)
			modDB:NewMod("EnergyShieldRecharge", "INC", m_floor(mod.value * multiplier), mod.source, mod.flags, mod.keywordFlags, unpack(modifiers))
		end
	end

	-- Primary defences: Energy shield, evasion and armour
	do
		local ironReflexes = modDB:Flag(nil, "IronReflexes")
		local ward = 0
		local energyShield = 0
		local armour = 0
		local evasion = 0
		if breakdown then
			breakdown.Ward = { slots = { } }
			breakdown.EnergyShield = { slots = { } }
			breakdown.Armour = { slots = { } }
			breakdown.Evasion = { slots = { } }
		end
		local energyShieldBase, armourBase, evasionBase, wardBase
		local gearWard = 0
		local gearEnergyShield = 0
		local gearArmour = 0
		local gearEvasion = 0
		local slotCfg = wipeTable(tempTable1)
		for _, slot in pairs({"Helmet","Body Armour","Gloves","Boots","Weapon 2","Weapon 3"}) do
			local armourData = actor.itemList[slot] and actor.itemList[slot].armourData
			if armourData then
				slotCfg.slotName = slot
				wardBase = armourData.Ward or 0
				if wardBase > 0 then
					output["WardOn"..slot] = wardBase
					if modDB:Flag(nil, "EnergyShieldToWard") then
						local inc = modDB:Sum("INC", slotCfg, "Ward", "Defences", "EnergyShield")
						local more = modDB:More(slotCfg, "Ward", "Defences")
						ward = ward + wardBase * (1 + inc / 100) * more
						gearWard = gearWard + wardBase
						if breakdown then
							t_insert(breakdown["Ward"].slots, {
								base = wardBase,
								inc = (inc ~= 0) and s_format(" x %.2f", 1 + inc/100),
								more = (more ~= 1) and s_format(" x %.2f", more),
								total = s_format("%.2f", wardBase * (1 + inc / 100) * more),
								source = slot,
								item = actor.itemList[slot],
							})
						end
					else
						ward = ward + wardBase * calcLib.mod(modDB, slotCfg, "Ward", "Defences")
						gearWard = gearWard + wardBase
						if breakdown then
							breakdown.slot(slot, nil, slotCfg, wardBase, nil, "Ward", "Defences")
						end
					end
				end
				energyShieldBase = armourData.EnergyShield or 0
				if energyShieldBase > 0 then
					output["EnergyShieldOn"..slot] = energyShieldBase
					if modDB:Flag(nil, "EnergyShieldToWard") then
						local more = modDB:More(slotCfg, "EnergyShield", "Defences")
						energyShield = energyShield + energyShieldBase * more
						gearEnergyShield = gearEnergyShield + energyShieldBase
						if breakdown then
							t_insert(breakdown["EnergyShield"].slots, {
								base = energyShieldBase,
								more = (more ~= 1) and s_format(" x %.2f", more),
								total = s_format("%.2f", energyShieldBase * more),
								source = slot,
								item = actor.itemList[slot],
							})
						end
					else
						energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, slotCfg, "EnergyShield", "Defences")
						gearEnergyShield = gearEnergyShield + energyShieldBase
						if breakdown then
							breakdown.slot(slot, nil, slotCfg, energyShieldBase, nil, "EnergyShield", "Defences")
						end
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
					gearEvasion = gearEvasion + evasionBase
					if breakdown then
						breakdown.slot(slot, nil, slotCfg, evasionBase, nil, "Evasion", "ArmourAndEvasion", "Defences")
					end
					if ironReflexes then
						armour = armour + evasionBase * calcLib.mod(modDB, slotCfg, "Armour", "Evasion", "ArmourAndEvasion", "Defences")
					else
						evasion = evasion + evasionBase * calcLib.mod(modDB, slotCfg, "Evasion", "ArmourAndEvasion", "Defences")
					end
				end
			end
		end
		wardBase = modDB:Sum("BASE", nil, "Ward")

		if wardBase > 0 then
			if modDB:Flag(nil, "EnergyShieldToWard") then
				local inc = modDB:Sum("INC", slotCfg, "Ward", "Defences", "EnergyShield")
				local more = modDB:More(slotCfg, "Ward", "Defences")
				ward = ward + wardBase * (1 + inc / 100) * more
				if breakdown then
					t_insert(breakdown["Ward"].slots, {
						base = wardBase,
						inc = (inc ~= 0) and s_format(" x %.2f", 1 + inc/100),
						more = (more ~= 1) and s_format(" x %.2f", more),
						total = s_format("%.2f", wardBase * (1 + inc / 100) * more),
						source = "Global",
						item = actor.itemList["Global"],
					})
				end
			else
				ward = ward + wardBase * calcLib.mod(modDB, nil, "Ward", "Defences")
				if breakdown then
					breakdown.slot("Global", nil, nil, wardBase, nil, "Ward", "Defences")
				end
			end
		end
		energyShieldBase = modDB:Sum("BASE", nil, "EnergyShield")
		if energyShieldBase > 0 then
			if modDB:Flag(nil, "EnergyShieldToWard") then
				energyShield = energyShield + energyShieldBase * modDB:More(slotCfg, "EnergyShield", "Defences")
			else
				energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, nil, "EnergyShield", "Defences")
			end
			if breakdown then
				local more = modDB:More(slotCfg, "EnergyShield", "Defences")
				t_insert(breakdown["EnergyShield"].slots, {
					base = energyShieldBase,
					more = (more ~= 1) and s_format(" x %.2f", more),
					total = s_format("%.2f", energyShieldBase * more),
					source = "Global",
					item = actor.itemList["Global"],
				})
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
		local convManaToArmour = modDB:Sum("BASE", nil, "ManaConvertToArmour")
		if convManaToArmour > 0 then
			armourBase = 2 * modDB:Sum("BASE", nil, "Mana") * convManaToArmour / 100
			local total = armourBase * calcLib.mod(modDB, nil, "Mana", "Armour", "ArmourAndEvasion", "Defences")
			armour = armour + total
			if breakdown then
				breakdown.slot("Conversion", "Mana to Armour", nil, armourBase, total, "Armour", "ArmourAndEvasion", "Defences", "Mana")
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
				total = armourBase * calcLib.mod(modDB, nil, "Life", "Armour", "ArmourAndEvasion", "Defences") 
			end
			armour = armour + total
			if breakdown then
				breakdown.slot("Conversion", "Life to Armour", nil, armourBase, total, "Armour", "ArmourAndEvasion", "Defences", "Life")
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
		local convEvasionToArmour = modDB:Sum("BASE", nil, "EvasionGainAsArmour")
		if convEvasionToArmour > 0 then
			armourBase = (modDB:Sum("BASE", nil, "Evasion", "ArmourAndEvasion") + gearEvasion) * convEvasionToArmour / 100
			local total = armourBase * calcLib.mod(modDB, nil, "Evasion", "Armour", "ArmourAndEvasion", "Defences")
			armour = armour + total
			if breakdown then
				breakdown.slot("Conversion", "Evasion to Armour", nil, armourBase, total, "Armour", "ArmourAndEvasion", "Defences", "Evasion")
			end
		end
		output.EnergyShield = modDB:Override(nil, "EnergyShield") or m_max(round(energyShield), 0)
		output.Armour = m_max(round(armour), 0)
		output.ArmourDefense = (modDB:Max(nil, "ArmourDefense") or 0) / 100
		output.RawArmourDefense = output.ArmourDefense > 0 and ((1 + output.ArmourDefense) * 100) or nil
		output.Evasion = m_max(round(evasion), 0)
		output.MeleeEvasion = m_max(round(evasion * calcLib.mod(modDB, nil, "MeleeEvasion")), 0)
		output.ProjectileEvasion = m_max(round(evasion * calcLib.mod(modDB, nil, "ProjectileEvasion")), 0)
		output.LowestOfArmourAndEvasion = m_min(output.Armour, output.Evasion)
		output.Ward = m_max(round(ward), 0)
		output["Gear:Ward"] = gearWard
		output["Gear:EnergyShield"] = gearEnergyShield
		output["Gear:Armour"] = gearArmour
		output["Gear:Evasion"] = gearEvasion
		output.CappingES = modDB:Flag(nil, "ArmourESRecoveryCap") and output.Armour < output.EnergyShield or modDB:Flag(nil, "EvasionESRecoveryCap") and output.Evasion < output.EnergyShield or env.configInput["conditionLowEnergyShield"]

		if output.CappingES then
			output.EnergyShieldRecoveryCap = modDB:Flag(nil, "ArmourESRecoveryCap") and modDB:Flag(nil, "EvasionESRecoveryCap") and m_min(output.Armour, output.Evasion) or modDB:Flag(nil, "ArmourESRecoveryCap") and output.Armour or modDB:Flag(nil, "EvasionESRecoveryCap") and output.Evasion or output.EnergyShield or 0
			output.EnergyShieldRecoveryCap = env.configInput["conditionLowEnergyShield"] and m_min(output.EnergyShield * data.misc.LowPoolThreshold, output.EnergyShieldRecoveryCap) or output.EnergyShieldRecoveryCap
		else
			output.EnergyShieldRecoveryCap = output.EnergyShield or 0
		end

		if modDB:Flag(nil, "CannotEvade") then
			output.EvadeChance = 0
			output.MeleeEvadeChance = 0
			output.ProjectileEvadeChance = 0
		else
			local enemyAccuracy = round(calcLib.val(enemyDB, "Accuracy"))
			local evadeChance = modDB:Sum("BASE", nil, "EvadeChance")
			local hitChance = calcLib.mod(enemyDB, nil, "HitChance")
			output.EvadeChance = 100 - (calcs.hitChance(output.Evasion, enemyAccuracy) - evadeChance) * hitChance
			output.MeleeEvadeChance = m_max(0, m_min(data.misc.EvadeChanceCap, (100 - (calcs.hitChance(output.MeleeEvasion, enemyAccuracy) - evadeChance) * hitChance) * calcLib.mod(modDB, nil, "EvadeChance", "MeleeEvadeChance")))
			output.ProjectileEvadeChance = m_max(0, m_min(data.misc.EvadeChanceCap, (100 - (calcs.hitChance(output.ProjectileEvasion, enemyAccuracy) - evadeChance) * hitChance) * calcLib.mod(modDB, nil, "EvadeChance", "ProjectileEvadeChance")))
			-- Condition for displaying evade chance only if melee or projectile evade chance have the same values
			if output.MeleeEvadeChance ~= output.ProjectileEvadeChance then
				output.splitEvade = true
			else
				output.EvadeChance = output.MeleeEvadeChance
				output.dontSplitEvade = true
			end
			if breakdown then
				breakdown.EvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
					s_format("Approximate evade chance: %d%%", output.EvadeChance),
				}
				breakdown.MeleeEvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
					s_format("Effective Evasion: %d", output.MeleeEvasion),
					s_format("Approximate melee evade chance: %d%%", output.MeleeEvadeChance),
				}
				breakdown.ProjectileEvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
					s_format("Effective Evasion: %d", output.ProjectileEvasion),
					s_format("Approximate projectile evade chance: %d%%", output.ProjectileEvadeChance),
				}
			end
		end
	end

	-- Dodge
	-- Acrobatics Spell Suppression to Spell Dodge Chance conversion.
	if modDB:Flag(nil, "ConvertSpellSuppressionToSpellDodge") then
		local SpellSuppressionChance = modDB:Sum("BASE", nil, "SpellSuppressionChance")
		modDB:NewMod("SpellDodgeChance", "BASE", SpellSuppressionChance / 2, "Acrobatics")
	end
	
	local totalSpellSuppressionChance = modDB:Override(nil, "SpellSuppressionChance") or modDB:Sum("BASE", nil, "SpellSuppressionChance")
	
	output.SpellSuppressionChance = m_min(totalSpellSuppressionChance, data.misc.SuppressionChanceCap)
	output.SpellSuppressionEffect = data.misc.SuppressionEffect + modDB:Sum("BASE", nil, "SpellSuppressionEffect")
	
	if env.mode_effective and modDB:Flag(nil, "SpellSuppressionChanceIsUnlucky") then
		output.SpellSuppressionChance = output.SpellSuppressionChance / 100 * output.SpellSuppressionChance
	elseif env.mode_effective and modDB:Flag(nil, "SpellSuppressionChanceIsLucky") then
		output.SpellSuppressionChance = (1 - (1 - output.SpellSuppressionChance / 100) ^ 2) * 100
	end
	
	output.SpellSuppressionChanceOverCap = m_max(0, totalSpellSuppressionChance - data.misc.SuppressionChanceCap)
	
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
	output.AverageBlockChance = (output.BlockChance + output.ProjectileBlockChance + output.SpellBlockChance + output.SpellProjectileBlockChance) / 4
	output.BlockEffect = m_max(100 - modDB:Sum("BASE", nil, "BlockEffect"), 0)
	if output.BlockEffect == 0 or output.BlockEffect == 100 then
		output.BlockEffect = 100
	else
		output.ShowBlockEffect = true
		output.DamageTakenOnBlock = 100 - output.BlockEffect
	end
	output.LifeOnBlock = modDB:Sum("BASE", nil, "LifeOnBlock")
	output.ManaOnBlock = modDB:Sum("BASE", nil, "ManaOnBlock")
	output.EnergyShieldOnBlock = modDB:Sum("BASE", nil, "EnergyShieldOnBlock")

	-- Dodge
	local baseDodgeChance = 0
	local totalAttackDodgeChance = modDB:Sum("BASE", nil, "AttackDodgeChance")
	local totalSpellDodgeChance = modDB:Sum("BASE", nil, "SpellDodgeChance")
	local attackDodgeChanceMax = data.misc.DodgeChanceCap
	local spellDodgeChanceMax = modDB:Override(nil, "SpellDodgeChanceMax") or modDB:Sum("BASE", nil, "SpellDodgeChanceMax")

	output.AttackDodgeChance = m_min(totalAttackDodgeChance, attackDodgeChanceMax)
	output.SpellDodgeChance = m_min(totalSpellDodgeChance, spellDodgeChanceMax)
	if env.mode_effective and modDB:Flag(nil, "DodgeChanceIsUnlucky") then
		output.AttackDodgeChance = output.AttackDodgeChance / 100 * output.AttackDodgeChance
		output.SpellDodgeChance = output.SpellDodgeChance / 100 * output.SpellDodgeChance
	end
	output.AttackDodgeChanceOverCap = m_max(0, totalAttackDodgeChance - attackDodgeChanceMax)
	output.SpellDodgeChanceOverCap = m_max(0, totalSpellDodgeChance - spellDodgeChanceMax)

	if breakdown then
		breakdown.AttackDodgeChance = {
			"Base: "..baseDodgeChance.."%",
			"Max: "..attackDodgeChanceMax.."%",
			"Total: "..output.AttackDodgeChance+output.AttackDodgeChanceOverCap.."%",
		}
		breakdown.SpellDodgeChance = {
			"Base: "..baseDodgeChance.."%",
			"Max: "..spellDodgeChanceMax.."%",
			"Total: "..output.SpellDodgeChance+output.SpellDodgeChanceOverCap.."%",
		}
	end

	-- Recovery modifiers
	output.LifeRecoveryRateMod = calcLib.mod(modDB, nil, "LifeRecoveryRate")
	output.ManaRecoveryRateMod = calcLib.mod(modDB, nil, "ManaRecoveryRate")
	output.EnergyShieldRecoveryRateMod = calcLib.mod(modDB, nil, "EnergyShieldRecoveryRate")

	-- Leech caps
	output.MaxLifeLeechInstance = output.Life * calcLib.val(modDB, "MaxLifeLeechInstance") / 100
	output.MaxLifeLeechRatePercent = calcLib.val(modDB, "MaxLifeLeechRate")
	output.MaxLifeLeechRate = output.Life * output.MaxLifeLeechRatePercent / 100
	if breakdown then
		breakdown.MaxLifeLeechRate = {
			s_format("%d ^8(maximum life)", output.Life),
			s_format("x %d%% ^8(percentage of life to maximum leech rate)", output.MaxLifeLeechRatePercent),
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
		output.ManaRegenRecovery = - modDB:Sum("BASE", nil, "ManaDegen")
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
		output.ManaRegen = regenRate
		output.ManaRegenRecovery = (modDB:Flag(nil, "UnaffectedByManaRegen") and 0 or output.ManaRegen) - degen
		if breakdown then
			breakdown.ManaRegenRecovery = { }
			breakdown.multiChain(breakdown.ManaRegenRecovery, {
				label = "Mana Regeneration:",
				base = s_format("%.1f ^8(base)", base),
				{ "%.2f ^8(increased/reduced)", 1 + output.ManaRegenInc/100 },
				{ "%.2f ^8(more/less)", more },
				total = s_format("= %.1f ^8per second", regen),
			})
			breakdown.multiChain(breakdown.ManaRegenRecovery, {
				label = "Effective Mana Regeneration:",
				base = s_format("%.1f", regen),
				{ "%.2f ^8(recovery rate modifier)", output.ManaRecoveryRateMod },
				total = s_format("= %.1f ^8per second", regenRate),
			})
			if degen ~= 0 then
				t_insert(breakdown.ManaRegenRecovery, s_format("- %d", degen))
				t_insert(breakdown.ManaRegenRecovery, s_format("= %.1f ^8per second", output.ManaRegenRecovery))
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
			output.LifeRegen = lifeBase * output.LifeRecoveryRateMod * modDB:More(nil, "LifeRegen") * (1 + modDB:Sum("INC", nil, "LifeRegen") / 100)
		else
			output.LifeRegen = 0
		end
		-- Don't add life recovery mod for this
		if output.LifeRegen and modDB:Flag(nil, "LifeRegenerationRecoversEnergyShield") and output.EnergyShield > 0 then
			modDB:NewMod("EnergyShieldRecovery", "BASE",output.LifeRegen / output.LifeRecoveryRateMod, "Life Regeneration Recovers Energy Shield")
		end
	end
	output.LifeRegenRecovery = (modDB:Flag(nil, "UnaffectedByLifeRegen") and 0 or output.LifeRegen) - modDB:Sum("BASE", nil, "LifeDegen") + modDB:Sum("BASE", nil, "LifeRecovery") * output.LifeRecoveryRateMod
	output.LifeRegenPercent = round(output.LifeRegenRecovery / output.Life * 100, 1)
	if modDB:Flag(nil, "NoEnergyShieldRegen") then
		output.EnergyShieldRegenRecovery = 0 - modDB:Sum("BASE", nil, "EnergyShieldDegen")
		output.EnergyShieldRegenPercent = round(output.EnergyShieldRegenRecovery / output.EnergyShield * 100, 1)
	else
		local esBase = modDB:Sum("BASE", nil, "EnergyShieldRegen")
		local esPercent = modDB:Sum("BASE", nil, "EnergyShieldRegenPercent")
		if esPercent > 0 then
			esBase = esBase + output.EnergyShield * esPercent / 100
		end
		if esBase > 0 then
			output.EnergyShieldRegenRecovery = esBase * output.EnergyShieldRecoveryRateMod * calcLib.mod(modDB, nil, "EnergyShieldRegen") - modDB:Sum("BASE", nil, "EnergyShieldDegen")
			output.EnergyShieldRegenPercent = round(output.EnergyShieldRegenRecovery / output.EnergyShield * 100, 1)
		else
			output.EnergyShieldRegenRecovery = 0 - modDB:Sum("BASE", nil, "EnergyShieldDegen")
		end
	end
	output.EnergyShieldRegenRecovery = output.EnergyShieldRegenRecovery + modDB:Sum("BASE", nil, "EnergyShieldRecovery") * output.EnergyShieldRecoveryRateMod
	output.EnergyShieldRegenPercent = round(output.EnergyShieldRegenRecovery / output.EnergyShield * 100, 1)
	if modDB:Sum("BASE", nil, "RageRegen") > 0 then
		modDB:NewMod("Condition:CanGainRage", "FLAG", true, "RageRegen")
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
					base = s_format("%.1f ^8(33%% per second)", output.Life * data.misc.EnergyShieldRechargeBase),
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
					base = s_format("%.1f ^8(33%% per second)", output.EnergyShield * data.misc.EnergyShieldRechargeBase),
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
		output.EnergyShieldRechargeDelay = data.misc.EnergyShieldRechargeDelay / (1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100)
		if breakdown then
			if output.EnergyShieldRechargeDelay ~= data.misc.EnergyShieldRechargeDelay then
				breakdown.EnergyShieldRechargeDelay = {
					s_format("%.2fs ^8(base)", data.misc.EnergyShieldRechargeDelay),
					s_format("/ %.2f ^8(faster start)", 1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100),
					s_format("= %.2fs", output.EnergyShieldRechargeDelay)
				}
			end
		end
	end
	
	-- recoup
	do
		local quickRecoup = modDB:Flag(nil, "3SecondRecoup")
		local recoupTypeList = {"Life", "Mana", "EnergyShield"}
		for _, recoupType in ipairs(recoupTypeList) do
			local baseRecoup = modDB:Sum("BASE", nil, recoupType.."Recoup")
			output[recoupType.."Recoup"] =  baseRecoup * output[recoupType.."RecoveryRateMod"]
			if breakdown then
				if output[recoupType.."RecoveryRateMod"] ~= 1 then
					breakdown[recoupType.."Recoup"] = {
						s_format("%d%% ^8(base)", baseRecoup),
						s_format("* %.2f ^8(recovery rate modifier)", output[recoupType.."RecoveryRateMod"]),
						s_format("= %.1f%% over %d seconds", output[recoupType.."Recoup"], quickRecoup and 3 or 4)
					}
				else
					breakdown[recoupType.."Recoup"] = { s_format("%d%% over %d seconds", output[recoupType.."Recoup"], quickRecoup and 3 or 4) }
				end
			end
		end

		if modDB:Flag(nil, "UsePowerCharges") and modDB:Flag(nil, "PowerChargesConvertToAbsorptionCharges") then
			local ElementalEnergyShieldRecoupPerAbsorptionCharges = modDB:Sum("BASE", nil, "PerAbsorptionElementalEnergyShieldRecoup")
			modDB:NewMod("ElementalEnergyShieldRecoup", "BASE", ElementalEnergyShieldRecoupPerAbsorptionCharges, "Absorption Charges", { type = "Multiplier", var = "AbsorptionCharge" } )
		end
		local ElementalEnergyShieldRecoup = modDB:Sum("BASE", nil, "ElementalEnergyShieldRecoup")
		output.ElementalEnergyShieldRecoup = ElementalEnergyShieldRecoup * output.EnergyShieldRecoveryRateMod
		if breakdown then
			if output.EnergyShieldRecoveryRateMod ~= 1 then
				breakdown.ElementalEnergyShieldRecoup = {
					s_format("%d%% ^8(base)", ElementalEnergyShieldRecoup),
					s_format("* %.2f ^8(recovery rate modifier)", output.EnergyShieldRecoveryRateMod),
					s_format("= %.1f%% over %d seconds", output.ElementalEnergyShieldRecoup, quickRecoup and 3 or 4)
				}
			else
				breakdown.ElementalEnergyShieldRecoup = { s_format("%d%% over %d seconds", output.ElementalEnergyShieldRecoup, quickRecoup and 3 or 4) }
			end
		end
		
		for _, damageType in ipairs(dmgTypeList) do
			local LifeRecoup = modDB:Sum("BASE", nil, damageType.."LifeRecoup")
			output[damageType.."LifeRecoup"] =  LifeRecoup * output.LifeRecoveryRateMod
			if breakdown then
				if output.LifeRecoveryRateMod ~= 1 then
					breakdown[damageType.."LifeRecoup"] = {
						s_format("%d%% ^8(base)", LifeRecoup),
						s_format("* %.2f ^8(recovery rate modifier)", output.LifeRecoveryRateMod),
						s_format("= %.1f%% over %d seconds", output[damageType.."LifeRecoup"], quickRecoup and 3 or 4)
					}
				else
					breakdown[damageType.."LifeRecoup"] = { s_format("%d%% over %d seconds", output[damageType.."LifeRecoup"], quickRecoup and 3 or 4) }
				end
			end
		end
	end

	-- Ward recharge
	output.WardRechargeDelay = data.misc.WardRechargeDelay / (1 + modDB:Sum("INC", nil, "WardRechargeFaster") / 100)
	if breakdown then
		if output.WardRechargeDelay ~= data.misc.WardRechargeDelay then
			breakdown.WardRechargeDelay = {
				s_format("%.2fs ^8(base)", data.misc.WardRechargeDelay),
				s_format("/ %.2f ^8(faster start)", 1 + modDB:Sum("INC", nil, "WardRechargeFaster") / 100),
				s_format("= %.2fs", output.WardRechargeDelay)
			}
		end
	end

	-- Miscellaneous: move speed, avoidance
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

	if enemyDB:Flag(nil, "Blind") then
		output.BlindEffectMod = calcLib.mod(enemyDB, nil, "BlindEffect", "BuffEffectOnSelf") * 100
	end
	
	-- recovery on block, needs to be after primary defences
	output.LifeOnBlock = modDB:Sum("BASE", nil, "LifeOnBlock")
	output.ManaOnBlock = modDB:Sum("BASE", nil, "ManaOnBlock")
	output.EnergyShieldOnBlock = modDB:Sum("BASE", nil, "EnergyShieldOnBlock")
	output.EnergyShieldOnSpellBlock = modDB:Sum("BASE", nil, "EnergyShieldOnSpellBlock")
	
	output.EnergyShieldOnSuppress = modDB:Sum("BASE", nil, "EnergyShieldOnSuppress")
	output.LifeOnSuppress = modDB:Sum("BASE", nil, "LifeOnSuppress")
	
	-- damage avoidances
	for _, damageType in ipairs(dmgTypeList) do
		output["Avoid"..damageType.."DamageChance"] = m_min(modDB:Sum("BASE", nil, "Avoid"..damageType.."DamageChance"), data.misc.AvoidChanceCap)
	end
	output.AvoidProjectilesChance = m_min(modDB:Sum("BASE", nil, "AvoidProjectilesChance"), data.misc.AvoidChanceCap)
	-- other avoidances etc
	output.BlindAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidBlind"), 100)
	for _, ailment in ipairs(data.ailmentTypeList) do
		output[ailment.."AvoidChance"] = m_min(modDB:Sum("BASE", nil, "Avoid"..ailment), 100)
	end
	output.CritExtraDamageReduction = m_min(modDB:Sum("BASE", nil, "ReduceCritExtraDamage"), 100)
	output.LightRadiusMod = calcLib.mod(modDB, nil, "LightRadius")
	if breakdown then
		breakdown.LightRadiusMod = breakdown.mod(modDB, nil, "LightRadius")
	end
	output.CurseEffectOnSelf = modDB:More(nil, "CurseEffectOnSelf") * (100 + modDB:Sum("INC", nil, "CurseEffectOnSelf"))

	-- Ailment duration on self
	output.DebuffExpirationRate = modDB:Sum("BASE", nil, "SelfDebuffExpirationRate")
	output.DebuffExpirationModifier = 10000 / (100 + output.DebuffExpirationRate)
	output.showDebuffExpirationModifier = (output.DebuffExpirationModifier ~= 100)
	output.SelfBlindDuration = modDB:More(nil, "SelfBlindDuration") * (100 + modDB:Sum("INC", nil, "SelfBlindDuration")) * output.DebuffExpirationModifier / 100
	for _, ailment in ipairs(data.ailmentTypeList) do
		output["Self"..ailment.."Duration"] = modDB:More(nil, "Self"..ailment.."Duration") * (100 + modDB:Sum("INC", nil, "Self"..ailment.."Duration")) * 100 / (100 + output.DebuffExpirationRate + modDB:Sum("BASE", nil, "Self"..ailment.."DebuffExpirationRate"))
	end
	output.SelfChillEffect = modDB:More(nil, "SelfChillEffect") * (100 + modDB:Sum("INC", nil, "SelfChillEffect"))
	output.SelfShockEffect = modDB:More(nil, "SelfShockEffect") * (100 + modDB:Sum("INC", nil, "SelfShockEffect"))
	--Enemy damage input and modifications
	do
		output["totalEnemyDamage"] = 0
		output["totalEnemyDamageIn"] = 0
		if breakdown then
			breakdown["totalEnemyDamage"] = { 
				label = "Total damage from the enemy",
				rowList = { },
				colList = {
					{ label = "Type", key = "type" },
					{ label = "Value", key = "value" },
					{ label = "Mult", key = "mult" },
					{ label = "Crit", key = "crit" },
					{ label = "Final", key = "final" },
					{ label = "From", key = "from" },
				},
			}
		end
		local enemyCritChance = env.configInput["enemyCritChance"] or env.configPlaceholder["enemyCritChance"] or 0
		local enemyCritDamage = env.configInput["enemyCritDamage"] or env.configPlaceholder["enemyCritDamage"] or 0
		output["EnemyCritEffect"] = 1 + enemyCritChance / 100 * (enemyCritDamage / 100) * (1 - output.CritExtraDamageReduction / 100)
		for _, damageType in ipairs(dmgTypeList) do
			local enemyDamageMult = calcLib.mod(enemyDB, nil, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil) -- missing taunt from allies
			local enemyDamage = tonumber(env.configInput["enemy"..damageType.."Damage"])
			local enemyPen = tonumber(env.configInput["enemy"..damageType.."Pen"])
			local enemyOverwhelm = tonumber(env.configInput["enemy"..damageType.."Overwhelm"])
			local sourceStr = enemyDamage == nil and "Default" or "Config"

			if enemyDamage == nil then
				enemyDamage = tonumber(env.configPlaceholder["enemy"..damageType.."Damage"]) or 0
			end
			if enemyPen == nil then
				enemyPen = tonumber(env.configPlaceholder["enemy"..damageType.."Pen"]) or 0
			end
			if enemyOverwhelm == nil then
				enemyOverwhelm = tonumber(env.configPlaceholder["enemy"..damageType.."enemyOverwhelm"]) or 0
			end

			output[damageType.."EnemyPen"] = enemyPen
			output[damageType.."EnemyOverwhelm"] = enemyOverwhelm
			output["totalEnemyDamageIn"] = output["totalEnemyDamageIn"] + enemyDamage
			output[damageType.."EnemyDamage"] = enemyDamage * enemyDamageMult * output["EnemyCritEffect"]
			output["totalEnemyDamage"] = output["totalEnemyDamage"] + output[damageType.."EnemyDamage"]
			if breakdown then
				breakdown[damageType.."EnemyDamage"] = {
				s_format("from %s: %d", sourceStr, enemyDamage),
				s_format("* %.2f (modifiers to enemy damage)", enemyDamageMult),
				s_format("* %.3f (enemy crit effect)", output["EnemyCritEffect"]),
				s_format("= %d", output[damageType.."EnemyDamage"]),
				}
				t_insert(breakdown["totalEnemyDamage"].rowList, {
					type = s_format("%s", damageType),
					value = s_format("%d", enemyDamage),
					mult = s_format("%.2f", enemyDamageMult),
					crit = s_format("%.2f", output["EnemyCritEffect"]),
					final = s_format("%d", output[damageType.."EnemyDamage"]),
					from = s_format("%s", sourceStr),
				})
			end
		end
	end
	
	--Damage Taken as
	do
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
			
			--add same type damage
			output[damageType.."TakenDamage"] = output[damageType.."EnemyDamage"] * actor.damageShiftTable[damageType][damageType] / 100
			if breakdown then
				breakdown[damageType.."TakenDamage"] = { 
					label = "Taken",
					rowList = { },
					colList = {
						{ label = "Type", key = "type" },
						{ label = "Value", key = "value" },
					},
				}
				t_insert(breakdown[damageType.."TakenDamage"].rowList, {
					type = s_format("%s", damageType),
					value = s_format("%d", output[damageType.."TakenDamage"]),
				})
			end
		end
		--converted damage types
		for _, damageType in ipairs(dmgTypeList) do
			for _, damageConvertedType in ipairs(dmgTypeList) do
				if damageType ~= damageConvertedType then
					local damage = output[damageType.."EnemyDamage"] * actor.damageShiftTable[damageType][damageConvertedType] / 100
					output[damageConvertedType.."TakenDamage"] = output[damageConvertedType.."TakenDamage"] + damage
					if breakdown and damage > 0 then
						t_insert(breakdown[damageConvertedType.."TakenDamage"].rowList, {
							type = s_format("%s", damageType),
							value = s_format("%d", damage),
						})
					end
				end
			end
		end
		--total
		output["totalTakenDamage"] = 0
		if breakdown then
			breakdown["totalTakenDamage"] = { 
				label = "Total damage taken from the enemy after taken as",
				rowList = { },
				colList = {
					{ label = "Type", key = "type" },
					{ label = "Value", key = "value" },
				},
			}
		end
		for _, damageType in ipairs(dmgTypeList) do
			output["totalTakenDamage"] = output["totalTakenDamage"] + output[damageType.."TakenDamage"]
			if breakdown then
				t_insert(breakdown["totalTakenDamage"].rowList, {
					type = s_format("%s", damageType),
					value = s_format("%d", output[damageType.."TakenDamage"]),
				})
			end
		end
	end

	-- Damage taken multipliers/Degen calculations
	output.AnyTakenReflect = false
	local damageCategoryConfig = env.configInput.enemyDamageType or "Average"
	for _, damageType in ipairs(dmgTypeList) do
		local baseTakenInc = modDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken")
		local baseTakenMore = modDB:More(nil, "DamageTaken", damageType.."DamageTaken")
		if isElemental[damageType] then
			baseTakenInc = baseTakenInc + modDB:Sum("INC", nil, "ElementalDamageTaken")
			baseTakenMore = baseTakenMore * modDB:More(nil, "ElementalDamageTaken")
		end
		do	-- Hit
			local takenInc = baseTakenInc + modDB:Sum("INC", nil, "DamageTakenWhenHit", damageType.."DamageTakenWhenHit")
			local takenMore = baseTakenMore * modDB:More(nil, "DamageTakenWhenHit", damageType.."DamageTakenWhenHit")
			if isElemental[damageType] then
				takenInc = takenInc + modDB:Sum("INC", nil, "ElementalDamageTakenWhenHit")
				takenMore = takenMore * modDB:More(nil, "ElementalDamageTakenWhenHit")
			end
			output[damageType.."TakenHitMult"] = m_max((1 + takenInc / 100) * takenMore, 0)
			
			for _, hitType in ipairs(hitSourceList) do
				local baseTakenIncType = takenInc + modDB:Sum("INC", nil, hitType.."DamageTaken")
				local baseTakenMoreType = takenMore * modDB:More(nil, hitType.."DamageTaken")
				output[hitType.."TakenHitMult"] = m_max((1 + baseTakenIncType / 100) * baseTakenMoreType, 0)
				output[damageType..hitType.."TakenHitMult"] = output[hitType.."TakenHitMult"]
			end
			do
				-- Reflect
				takenInc = takenInc + modDB:Sum("INC", nil, damageType.."ReflectedDamageTaken")
				takenMore = takenMore * modDB:More(nil, damageType.."ReflectedDamageTaken")
				if isElemental[damageType] then
					takenInc = takenInc + modDB:Sum("INC", nil, "ElementalReflectedDamageTaken")
					takenMore = takenMore * modDB:More(nil, "ElementalReflectedDamageTaken")
				end
				output[damageType.."TakenReflect"] = m_max((1 + takenInc / 100) * takenMore, 0)
				if output[damageType.."TakenReflect"] ~= output[damageType.."TakenHitMult"] then
					output.AnyTakenReflect = false --true --this needs a rework as well
				end
			end
		end
		do	-- Dot
			local takenInc = baseTakenInc + modDB:Sum("INC", nil, "DamageTakenOverTime", damageType.."DamageTakenOverTime")
			local takenMore = baseTakenMore * modDB:More(nil, "DamageTakenOverTime", damageType.."DamageTakenOverTime")
			if isElemental[damageType] then
				takenInc = takenInc + modDB:Sum("INC", nil, "ElementalDamageTakenOverTime")
				takenMore = takenMore * modDB:More(nil, "ElementalDamageTakenOverTime")
			end
			local resist = modDB:Flag(nil, "SelfIgnore"..damageType.."Resistance") and 0 or output[damageType.."Resist"]
			local reduction = modDB:Flag(nil, "SelfIgnore".."Base"..damageType.."DamageReduction") and 0 or output["Base"..damageType.."DamageReduction"]
			output[damageType.."TakenDotMult"] = (1 - resist / 100) * (1 - reduction / 100) * (1 + takenInc / 100) * takenMore
			if breakdown then
				breakdown[damageType.."TakenDotMult"] = { }
				breakdown.multiChain(breakdown[damageType.."TakenDotMult"], {
					label = "DoT Multiplier:",
					{ "%.2f ^8(resistance)", (1 - resist / 100) },
					{ "%.2f ^8(%s damage reduction)", (1 - reduction / 100), damageType:lower() },
					{ "%.2f ^8(increased/reduced damage taken)", (1 + takenInc / 100) },
					{ "%.2f ^8(more/less damage taken)", takenMore },
					total = s_format("= %.2f", output[damageType.."TakenDotMult"]),
				})
			end
		end
	end

	-- Incoming hit damage multipliers
	output["totalTakenHit"] = 0
	if breakdown then
		breakdown["totalTakenHit"] = { 
			label = "Total damage taken after mitigation",
			rowList = { },
			colList = {
				{ label = "Type", key = "type" },
				{ label = "Incoming", key = "incoming" },
				{ label = "Mult", key = "mult" },
				{ label = "Value", key = "value" },
			},
		}
	end
	for _, damageType in ipairs(dmgTypeList) do
		-- Calculate incoming damage multiplier
		local resist = modDB:Flag(nil, "SelfIgnore"..damageType.."Resistance") and 0 or output[damageType.."ResistWhenHit"] or output[damageType.."Resist"]
		local reduction = modDB:Flag(nil, "SelfIgnore".."Base"..damageType.."DamageReduction") and 0 or output["Base"..damageType.."DamageReductionWhenHit"] or output["Base"..damageType.."DamageReduction"]
		local enemyPen = modDB:Flag(nil, "SelfIgnore"..damageType.."Resistance") and 0 or output[damageType.."EnemyPen"]
		local enemyOverwhelm = modDB:Flag(nil, "SelfIgnore"..damageType.."DamageReduction") and 0 or output[damageType.."EnemyOverwhelm"]
		local takenFlat = modDB:Sum("BASE", nil, "DamageTaken", damageType.."DamageTaken", "DamageTakenWhenHit", damageType.."DamageTakenWhenHit")
		local damage = output[damageType.."TakenDamage"]
		local armourReduct = 0
		local percentOfArmourApplies = m_min((not modDB:Flag(nil, "ArmourDoesNotApplyTo"..damageType.."DamageTaken") and modDB:Sum("BASE", nil, "ArmourAppliesTo"..damageType.."DamageTaken") or 0), 100)
		local resMult = 1 - (resist - enemyPen) / 100
		local reductMult = 1
		if damageCategoryConfig == "Melee" or damageCategoryConfig == "Projectile" then
			takenFlat = takenFlat + modDB:Sum("BASE", nil, "DamageTakenFromAttacks", damageType.."DamageTakenFromAttacks")
		elseif damageCategoryConfig == "Average" then
			takenFlat = takenFlat + modDB:Sum("BASE", nil, "DamageTakenFromAttacks", damageType.."DamageTakenFromAttacks") / 2
		end
		if percentOfArmourApplies > 0 then
			armourReduct = calcs.armourReduction((output.Armour * percentOfArmourApplies / 100) * (1 + output.ArmourDefense), damage * resMult)
			armourReduct = m_min(output.DamageReductionMax, armourReduct)
		end
		reductMult = 1 - m_max(m_min(output.DamageReductionMax, armourReduct + reduction - enemyOverwhelm), 0) / 100
		output[damageType.."DamageReduction"] = 100 - reductMult * 100
		if breakdown then
			breakdown[damageType.."DamageReduction"] = { }
			if armourReduct ~= 0 then
				if resMult ~= 1 then
					t_insert(breakdown[damageType.."DamageReduction"], s_format("Enemy Hit Damage After Resistance: %d ^8(total incoming damage)", damage * resMult))
				else
					t_insert(breakdown[damageType.."DamageReduction"], s_format("Enemy Hit Damage: %d ^8(total incoming damage)", damage))
				end
				if percentOfArmourApplies ~= 100 then
					t_insert(breakdown[damageType.."DamageReduction"], s_format("%d%% percent of armour applies", percentOfArmourApplies))
				end
				t_insert(breakdown[damageType.."DamageReduction"], s_format("Reduction from Armour: %d%%", armourReduct))
			end
			if reduction ~= 0 then
				t_insert(breakdown[damageType.."DamageReduction"], s_format("Base %s Damage Reduction: %d%%", damageType, reduction))
			end
			if enemyOverwhelm ~= 0 then
				t_insert(breakdown[damageType.."DamageReduction"], s_format("Enemy Overwhelm %s Damage: %d%%", damageType, enemyOverwhelm))
			end
			if (armourReduct ~= 0 and 1 or 0) + (reduction ~= 0 and 1 or 0) + (enemyOverwhelm ~= 0 and 1 or 0) >= 2 then
				t_insert(breakdown[damageType.."DamageReduction"], s_format("Total %s Damage Reduction: %d%%", damageType, 100 - reductMult * 100))
			end
		end
		local baseMult = resMult * reductMult
		local takenMult = output[damageType.."TakenHitMult"]
		local spellSuppressMult = 1
		if damageCategoryConfig == "Melee" or damageCategoryConfig == "Projectile" then
			takenMult = output[damageType.."AttackTakenHitMult"]
		elseif damageCategoryConfig == "Spell" or damageCategoryConfig == "SpellProjectile" then
			takenMult = output[damageType.."SpellTakenHitMult"]
			spellSuppressMult = output.SpellSuppressionChance == 100 and (1 - output.SpellSuppressionEffect / 100) or 1
		elseif damageCategoryConfig == "Average" then
			takenMult = (output[damageType.."SpellTakenHitMult"] + output[damageType.."AttackTakenHitMult"]) / 2
			spellSuppressMult = output.SpellSuppressionChance == 100 and (1 - output.SpellSuppressionEffect / 100 / 2) or 1
		end
		output[damageType.."BaseTakenHitMult"] = baseMult * takenMult * spellSuppressMult
		local takenMultReflect = output[damageType.."TakenReflect"]
		local finalReflect = baseMult * takenMultReflect
		output[damageType.."TakenHit"] = m_max(damage * baseMult + takenFlat, 0) * takenMult * spellSuppressMult
		output[damageType.."TakenHitMult"] = (damage > 0) and (output[damageType.."TakenHit"] / damage) or 0
		output["totalTakenHit"] = output["totalTakenHit"] + output[damageType.."TakenHit"]
		if output.AnyTakenReflect then
			output[damageType.."TakenReflectMult"] = finalReflect
		end
		if breakdown then
			breakdown[damageType.."TakenHitMult"] = { }
			if resist ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("Resistance: %.2f", 1 - resist / 100))
			end
			if enemyPen ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("+ Enemy Pen: %.2f", enemyPen / 100))
			end
			if resist ~= 0 and enemyPen ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("= %.2f", resMult))
			end
			if reduction ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("Base %s Damage Reduction: %.2f", damageType, 1 - reduction / 100))
			end
			if armourReduct ~= 0 then
				if resMult ~= 1 then
					t_insert(breakdown[damageType.."TakenHitMult"], s_format("Enemy Hit Damage After Resistance: %d ^8(total incoming damage)", damage * resMult))
				else
					t_insert(breakdown[damageType.."TakenHitMult"], s_format("Enemy Hit Damage: %d ^8(total incoming damage)", damage))
				end
				if percentOfArmourApplies ~= 100 then
					t_insert(breakdown[damageType.."TakenHitMult"], s_format("%d%% percent of armour applies", percentOfArmourApplies))
				end
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("Reduction from Armour: %.2f", 1 - armourReduct / 100))
			end
			if enemyOverwhelm ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("+ Enemy Overwhelm %s Damage: %.2f", damageType, enemyOverwhelm / 100))
			end
			if reduction ~= 0 or armourReduct ~= 0 or enemyOverwhelm ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("= %.2f", reductMult))
			end
			if resMult ~= 1 and reductMult ~= 1 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("%.2f x %.2f = %.3f", resMult, reductMult, baseMult))
			end
			if takenFlat ~= 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("+ Flat: %d", takenFlat))
			end
			if takenMult ~= 1 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("x Taken: %.3f", takenMult))
			end
			if spellSuppressMult ~= 1 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("x Spell Suppression: %.3f", spellSuppressMult))
			end
			if takenMult ~= 1 or takenFlat ~= 0 or spellSuppressMult ~= 1 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("= %.3f", output[damageType.."TakenHitMult"]))
			end
			breakdown[damageType.."TakenHit"] = {
				s_format("Final %s Damage taken:", damageType),
				s_format("%.1f incoming damage", damage),
				s_format("x %.3f damage mult", output[damageType.."TakenHitMult"]),
				s_format("= %.1f", output[damageType.."TakenHit"]),
			}
			t_insert(breakdown["totalTakenHit"].rowList, {
				type = s_format("%s", damageType),
				incoming = s_format("%.1f incoming damage", damage),
				mult = s_format("x %.3f damage mult", output[damageType.."TakenHitMult"] ),
				value = s_format("%d", output[damageType.."TakenHit"]),
			})
			if output.AnyTakenReflect then
				breakdown[damageType.."TakenReflectMult"] = {
					s_format("Resistance: %.3f", 1 - resist / 100),
				}
				if enemyPen > 0 then
					t_insert(breakdown[damageType.."TakenReflectMult"], s_format("Enemy Pen: %.2f", enemyPen))
				end
				t_insert(breakdown[damageType.."TakenReflectMult"], s_format("Taken: %.3f", takenMultReflect))
				t_insert(breakdown[damageType.."TakenReflectMult"], s_format("= %.3f", finalReflect))
			end
		end
	end
	
	-- stun
	do
		local stunThresholdBase = 0
		local stunThresholdSource = nil
		if modDB:Flag(nil, "StunThresholdBasedOnEnergyShieldInsteadOfLife") then
			local stunThresholdMult = modDB:Sum("BASE", nil, "StunThresholdEnergyShieldPercent")
			stunThresholdBase = output.EnergyShield * stunThresholdMult / 100
			stunThresholdSource = stunThresholdMult.."% of Energy Shield"
		elseif modDB:Flag(nil, "StunThresholdBasedOnManaInsteadOfLife") then
			local stunThresholdMult = modDB:Sum("BASE", nil, "StunThresholdManaPercent")
			stunThresholdBase = output.Mana * stunThresholdMult / 100
			stunThresholdSource = stunThresholdMult.."% of Mana"
		elseif modDB:Flag(nil, "ChaosInoculation") then
			stunThresholdBase = modDB:Sum("BASE", nil, "Life")
			stunThresholdSource = "Life before Chaos Inoculation"
		else
			stunThresholdBase = output.Life
			stunThresholdSource = "Life"
		end
		local StunThresholdMod = (1 + modDB:Sum("INC", nil, "StunThreshold") / 100)
		output.StunThreshold = stunThresholdBase * StunThresholdMod
		if breakdown then
			breakdown.StunThreshold = { s_format("%d ^8(base from %s)", stunThresholdBase, stunThresholdSource) }
			if StunThresholdMod ~= 1 then
				t_insert(breakdown.StunThreshold, s_format("* %.2f ^8(increased threshold)", StunThresholdMod))
				t_insert(breakdown.StunThreshold, s_format("= %d", output.StunThreshold))
			end
		end
		local notAvoidChance = 100 - m_min(modDB:Sum("BASE", nil, "AvoidStun"), 100)
		if output.EnergyShield > output["totalTakenHit"] then
			notAvoidChance = notAvoidChance * 0.5
		end
		output.StunAvoidChance = 100 - notAvoidChance
		if output.StunAvoidChance >= 100 then
			output.StunDuration = 0
			output.BlockDuration = 0
			if breakdown then
				breakdown.StunDuration = {"Cannot be Stunned"}
				breakdown.BlockDuration = {"Cannot be Stunned"}
			end
		else
			local stunDuration = (1 + modDB:Sum("INC", nil, "StunDuration") / 100)
			local baseStunDuration = data.misc.StunBaseDuration
			local stunRecovery = (1 + modDB:Sum("INC", nil, "StunRecovery") / 100)
			local stunAndBlockRecovery = (1 + modDB:Sum("INC", nil, "StunRecovery", "BlockRecovery") / 100)
			output.StunDuration = baseStunDuration * stunDuration / stunRecovery
			output.BlockDuration = baseStunDuration * stunDuration / stunAndBlockRecovery
			if breakdown then
				breakdown.StunDuration = {s_format("%.2fs ^8(base)", baseStunDuration)}
				breakdown.BlockDuration = {s_format("%.2fs ^8(base)", baseStunDuration)}
				if stunDuration ~= 1 then
					t_insert(breakdown.StunDuration, s_format("* %.2f ^8(increased duration)", stunDuration))
					t_insert(breakdown.BlockDuration, s_format("* %.2f ^8(increased duration)", stunDuration))
				end
				if stunRecovery ~= 1 then
					t_insert(breakdown.StunDuration, s_format("/ %.2f ^8(increased/reduced recovery)", stunRecovery))
				end
				if stunAndBlockRecovery ~= 1 then
					t_insert(breakdown.BlockDuration, s_format("/ %.2f ^8(increased/reduced block recovery)", stunAndBlockRecovery))
				end
				if output.StunDuration ~= baseStunDuration then
					t_insert(breakdown.StunDuration, s_format("= %.2fs", output.StunDuration))
				end
				if output.BlockDuration ~= baseStunDuration then
					t_insert(breakdown.BlockDuration, s_format("= %.2fs", output.BlockDuration))
				end
			end
		end
		output.InterruptStunAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidInterruptStun"), 100)
		local effectiveEnemyDamage = output["totalTakenHit"] + output["PhysicalTakenHit"] * 0.25
		if damageCategoryConfig ~= "Average" then
			effectiveEnemyDamage = effectiveEnemyDamage * (1 + data.misc.StunNotMeleeDamageMult * 3) / 4
		elseif damageCategoryConfig ~= "Melee" then
			effectiveEnemyDamage = effectiveEnemyDamage * data.misc.StunNotMeleeDamageMult
		end
		local baseStunChance = m_min(data.misc.StunBaseMult * effectiveEnemyDamage / output.StunThreshold, 100)
		output.SelfStunChance = (baseStunChance > data.misc.MinStunChanceNeeded and baseStunChance or 0) * notAvoidChance / 100
		if breakdown then
			breakdown.SelfStunChance = {
				s_format("%d%% ^8(stun multiplier)", data.misc.StunBaseMult),
				s_format("* %.1f ^8(effective enemy stun damage)", effectiveEnemyDamage),
				s_format("/ %d ^8(stun threshold)", output.StunThreshold)
			}
			if baseStunChance < data.misc.MinStunChanceNeeded then
				t_insert(breakdown.SelfStunChance, s_format("= %.2f%%", baseStunChance))
				t_insert(breakdown.SelfStunChance, s_format("Stun Chance has to be more than %d%% to stun.", data.misc.MinStunChanceNeeded))
			else
				if notAvoidChance ~= 100 then
					t_insert(breakdown.SelfStunChance, s_format("* %.2f ^8(1 - chance to avoid stun)", notAvoidChance / 100))
				end
				t_insert(breakdown.SelfStunChance, s_format("= %.2f%%", output.SelfStunChance))
			end
		end
	end
	
	-- Life Recoverable
	output.LifeRecoverable = output.LifeUnreserved
	if env.configInput["conditionLowLife"] then
		output.LifeRecoverable = m_min(output.Life * data.misc.LowPoolThreshold, output.LifeUnreserved)
		if output.LifeRecoverable < output.LifeUnreserved then
			output.CappingLife = true
		end
	end
	
	-- Prevented life loss (Petrified Blood)
	do
		output["preventedLifeLoss"] = modDB:Sum("BASE", nil, "LifeLossBelowHalfPrevented")
		local portionLife = 1
		if not env.configInput["conditionLowLife"] then
			--portion of life that is lowlife
			portionLife = m_min(output.Life * data.misc.LowPoolThreshold / output.LifeRecoverable, 1)
			output["preventedLifeLoss"] = output["preventedLifeLoss"] * portionLife
		end
		if breakdown then
			breakdown["preventedLifeLoss"] = {
				s_format("Total life protected:"),
			}
			if portionLife ~= 1 then
				t_insert(breakdown["preventedLifeLoss"], s_format("%.2f ^8(initial portion taken from petrified blood)", output["preventedLifeLoss"] / portionLife / 100))
				t_insert(breakdown["preventedLifeLoss"], s_format("* %.2f ^8(portion of life on low life)", portionLife))
				t_insert(breakdown["preventedLifeLoss"], s_format("= %.2f ^8(final portion taken from petrified blood)", output["preventedLifeLoss"] / 100))
				t_insert(breakdown["preventedLifeLoss"], s_format(""))
			else
				t_insert(breakdown["preventedLifeLoss"], s_format("%.2f ^8(portion taken from petrified blood)", output["preventedLifeLoss"] / 100))
			end
			t_insert(breakdown["preventedLifeLoss"], s_format("%.2f ^8(portion taken from life)", 1 - output["preventedLifeLoss"] / 100))
		end
	end

	-- Energy Shield bypass
	output.AnyBypass = false
	output.MinimumBypass = 100
	for _, damageType in ipairs(dmgTypeList) do
		if modDB:Flag(nil, "UnblockedDamageDoesBypassES") then
			output[damageType.."EnergyShieldBypass"] = 100
			output.AnyBypass = true
		else
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
		end
		output[damageType.."EnergyShieldBypass"] = m_max(m_min(output[damageType.."EnergyShieldBypass"], 100), 0)
		output.MinimumBypass = m_min(output.MinimumBypass, output[damageType.."EnergyShieldBypass"])
	end

	output.ehpSectionAnySpecificTypes = false
	-- Mind over Matter
	output.OnlySharedMindOverMatter = false
	output.AnySpecificMindOverMatter = false
	output["sharedMindOverMatter"] = m_min(modDB:Sum("BASE", nil, "DamageTakenFromManaBeforeLife"), 100)
	if output["sharedMindOverMatter"] > 0 then
		output.OnlySharedMindOverMatter = true
		local sourcePool = m_max(output.ManaUnreserved or 0, 0)
		local manatext = "unreserved mana"
		if modDB:Flag(nil, "EnergyShieldProtectsMana") and output.MinimumBypass < 100 then
			manatext = manatext.." + non-bypassed energy shield"
			if output.MinimumBypass > 0 then
				local manaProtected = output.EnergyShieldRecoveryCap / (1 - output.MinimumBypass / 100) * (output.MinimumBypass / 100)
				sourcePool = m_max(sourcePool - manaProtected, 0) + m_min(sourcePool, manaProtected) / (output.MinimumBypass / 100)
			else 
				sourcePool = sourcePool + output.EnergyShieldRecoveryCap
			end
		end
		local poolProtected = sourcePool / (output["sharedMindOverMatter"] / 100) * (1 - output["sharedMindOverMatter"] / 100)
		if output["sharedMindOverMatter"] >= 100 then
			poolProtected = m_huge
			output["sharedManaEffectiveLife"] = output.LifeRecoverable + sourcePool
		else
			output["sharedManaEffectiveLife"] = m_max(output.LifeRecoverable - poolProtected, 0) + m_min(output.LifeRecoverable, poolProtected) / (1 - output["sharedMindOverMatter"] / 100)
		end
		if breakdown then
			if output["sharedMindOverMatter"] then
				breakdown["sharedMindOverMatter"] = {
					s_format("Total life protected:"),
					s_format("%d ^8(%s)", sourcePool, manatext),
					s_format("/ %.2f ^8(portion taken from mana)", output["sharedMindOverMatter"] / 100),
					s_format("x %.2f ^8(portion taken from life)", 1 - output["sharedMindOverMatter"] / 100),
					s_format("= %d", poolProtected),
					s_format("Effective life: %d", output["sharedManaEffectiveLife"])
				}
			end
		end
	else
		output["sharedManaEffectiveLife"] = output.LifeRecoverable
	end
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."MindOverMatter"] = m_min(modDB:Sum("BASE", nil, damageType.."DamageTakenFromManaBeforeLife"), 100 - output["sharedMindOverMatter"])
		if output[damageType.."MindOverMatter"] > 0 or (output[damageType.."EnergyShieldBypass"] > output.MinimumBypass and output["sharedMindOverMatter"] > 0) then
			local MindOverMatter = output[damageType.."MindOverMatter"] + output["sharedMindOverMatter"]
			output.ehpSectionAnySpecificTypes = true
			output.AnySpecificMindOverMatter = true
			output.OnlySharedMindOverMatter = false
			local sourcePool = m_max(output.ManaUnreserved or 0, 0)
			local manatext = "unreserved mana"
			if modDB:Flag(nil, "EnergyShieldProtectsMana") and output[damageType.."EnergyShieldBypass"] < 100 then
				manatext = manatext.." + non-bypassed energy shield"
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local manaProtected = output.EnergyShieldRecoveryCap / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					sourcePool = m_max(sourcePool - manaProtected, 0) + m_min(sourcePool, manaProtected) / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					sourcePool = sourcePool + output.EnergyShieldRecoveryCap
				end
			end
			local poolProtected = sourcePool / (MindOverMatter / 100) * (1 - MindOverMatter / 100)
			if MindOverMatter >= 100 then
				poolProtected = m_huge
				output[damageType.."ManaEffectiveLife"] = output.LifeRecoverable + sourcePool
			else
				output[damageType.."ManaEffectiveLife"] = m_max(output.LifeRecoverable - poolProtected, 0) + m_min(output.LifeRecoverable, poolProtected) / (1 - MindOverMatter / 100)
			end
			if breakdown then
				if output[damageType.."MindOverMatter"] then
					breakdown[damageType.."MindOverMatter"] = {
						s_format("Total life protected:"),
						s_format("%d ^8(%s)", sourcePool, manatext),
						s_format("/ %.2f ^8(portion taken from mana)", MindOverMatter / 100),
						s_format("x %.2f ^8(portion taken from life)", 1 - MindOverMatter / 100),
						s_format("= %d", poolProtected),
						s_format("Effective life: %d", output[damageType.."ManaEffectiveLife"])
					}
				end
			end
		else
			output[damageType.."ManaEffectiveLife"] = output["sharedManaEffectiveLife"]
		end
	end

	-- Guard
	output.AnyGuard = false
	output["sharedGuardAbsorbRate"] = m_min(modDB:Sum("BASE", nil, "GuardAbsorbRate"), 100)
	if output["sharedGuardAbsorbRate"] > 0 then
		output.OnlySharedGuard = true
		output["sharedGuardAbsorb"] = calcLib.val(modDB, "GuardAbsorbLimit")
		local lifeProtected = output["sharedGuardAbsorb"] / (output["sharedGuardAbsorbRate"] / 100) * (1 - output["sharedGuardAbsorbRate"] / 100)
		if breakdown then
			breakdown["sharedGuardAbsorb"] = {
				s_format("Total life protected:"),
				s_format("%d ^8(guard limit)", output["sharedGuardAbsorb"]),
				s_format("/ %.2f ^8(portion taken from guard)", output["sharedGuardAbsorbRate"] / 100),
				s_format("x %.2f ^8(portion taken from life and energy shield)", 1 - output["sharedGuardAbsorbRate"] / 100),
				s_format("= %d", lifeProtected)
			}
		end
	end
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."GuardAbsorbRate"] = m_min(modDB:Sum("BASE", nil, damageType.."GuardAbsorbRate"), 100)
		if output[damageType.."GuardAbsorbRate"] > 0 then
			output.ehpSectionAnySpecificTypes = true
			output.AnyGuard = true
			output.OnlySharedGuard = false
			output[damageType.."GuardAbsorb"] = calcLib.val(modDB, damageType.."GuardAbsorbLimit")
			local lifeProtected = output[damageType.."GuardAbsorb"] / (output[damageType.."GuardAbsorbRate"] / 100) * (1 - output[damageType.."GuardAbsorbRate"] / 100)
			if breakdown then
				breakdown[damageType.."GuardAbsorb"] = {
					s_format("Total life protected:"),
					s_format("%d ^8(guard limit)", output[damageType.."GuardAbsorb"]),
					s_format("/ %.2f ^8(portion taken from guard)", output[damageType.."GuardAbsorbRate"] / 100),
					s_format("x %.2f ^8(portion taken from life and energy shield)", 1 - output[damageType.."GuardAbsorbRate"] / 100),
					s_format("= %d", lifeProtected),
				}
			end
		end
	end
	
	--aegis
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
	
	--frost shield
	do
		output["FrostShieldLife"] = modDB:Sum("BASE", nil, "FrostGlobeHealth")
		output["FrostShieldDamageMitigation"] = modDB:Sum("BASE", nil, "FrostGlobeDamageMitigation")
		
		local lifeProtected = output["FrostShieldLife"] / (output["FrostShieldDamageMitigation"] / 100) * (1 - output["FrostShieldDamageMitigation"] / 100)
		if breakdown then
			breakdown["FrostShieldLife"] = {
				s_format("Total life protected:"),
				s_format("%d ^8(frost shield limit)", output["FrostShieldLife"]),
				s_format("/ %.2f ^8(portion taken from frost shield)", output["FrostShieldDamageMitigation"] / 100),
				s_format("x %.2f ^8(portion taken from life and energy shield)", 1 - output["FrostShieldDamageMitigation"] / 100),
				s_format("= %d", lifeProtected),
			}
		end
	end

	--total pool
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."TotalPool"] = output[damageType.."ManaEffectiveLife"]
		local manatext = "Mana"
		if output[damageType.."EnergyShieldBypass"] < 100 then 
			if modDB:Flag(nil, "EnergyShieldProtectsMana") then
				manatext = manatext.." and non-bypassed Energy Shield"
			else
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local poolProtected = output.EnergyShieldRecoveryCap / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					output[damageType.."TotalPool"] = m_max(output[damageType.."TotalPool"] - poolProtected, 0) + m_min(output[damageType.."TotalPool"], poolProtected) / (output[damageType.."EnergyShieldBypass"] / 100)
				else
					output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + output.EnergyShieldRecoveryCap
				end
			end
		end
		if breakdown then
			breakdown[damageType.."TotalPool"] = {
				s_format("Life: %d", output.LifeRecoverable)
			}
			if output[damageType.."ManaEffectiveLife"] ~= output.LifeRecoverable then
				t_insert(breakdown[damageType.."TotalPool"], s_format("%s through MoM: %d", manatext, output[damageType.."ManaEffectiveLife"] - output.LifeRecoverable))
			end
			if (not modDB:Flag(nil, "EnergyShieldProtectsMana")) and output[damageType.."EnergyShieldBypass"] < 100 then
				t_insert(breakdown[damageType.."TotalPool"], s_format("Non-bypassed Energy Shield: %d", output[damageType.."TotalPool"] - output[damageType.."ManaEffectiveLife"]))
			end
			t_insert(breakdown[damageType.."TotalPool"], s_format("TotalPool: %d", output[damageType.."TotalPool"]))
		end
	end
	
	-- helper function that iteratively reduces pools until life hits 0 to determine the number of hits it would take with given damage to die
	function numberOfHitsToDie(DamageIn)
		local numHits = 0
		DamageIn["cycles"] = DamageIn["cycles"] or 1
		
		-- check damage in isn't 0 and that ward doesn't mitigate all damage
		for _, damageType in ipairs(dmgTypeList) do
			numHits = numHits + DamageIn[damageType]
		end
		if numHits == 0 then
			return m_huge
		elseif modDB:Flag(nil, "WardNotBreak") and output.Ward > 0 and  numHits < output.Ward then
			return m_huge
		else
			numHits = 0
		end
		
		local life = output.LifeRecoverable or 0
		local mana = output.ManaUnreserved or 0
		local energyShield = output.EnergyShieldRecoveryCap
		local ward = output.Ward or 0
		local restoreWard = modDB:Flag(nil, "WardNotBreak") and ward or 0
		-- don't apply non-perma ward for speed up calcs as it wont zero it correctly per hit
		if (not modDB:Flag(nil, "WardNotBreak")) and DamageIn["cycles"] > 1 then
			ward = 0
			restoreWard = 0
		end
		local frostShield = output["FrostShieldLife"] or 0
		local aegis = { }
		aegis["shared"] = output["sharedAegis"] or 0
		aegis["sharedElemental"] = output["sharedElementalAegis"] or 0
		local guard = { }
		guard["shared"] = output.sharedGuardAbsorb or 0
		for _, damageType in ipairs(dmgTypeList) do
			aegis[damageType] = output[damageType.."Aegis"] or 0
			guard[damageType] = output[damageType.."GuardAbsorb"] or 0
			if not DamageIn[damageType.."EnergyShieldBypass"] then
				DamageIn[damageType.."EnergyShieldBypass"] = output[damageType.."EnergyShieldBypass"] or 0
			end

		end
		DamageIn["LifeLossBelowHalfLost"] = DamageIn["LifeLossBelowHalfLost"] or 0
		DamageIn["WardBypass"] = DamageIn["WardBypass"] or modDB:Sum("BASE", nil, "WardBypass") or 0
		
		local iterationMultiplier = 1
		local maxHits = data.misc.ehpCalcMaxHitsToCalc
		maxHits = maxHits / DamageIn["cycles"]
		while life > 0 and numHits < maxHits do
			numHits = numHits + iterationMultiplier
			local Damage = { }
			for _, damageType in ipairs(dmgTypeList) do
				Damage[damageType] = DamageIn[damageType] * iterationMultiplier
			end
			if DamageIn.GainWhenHit and (iterationMultiplier > 1 or DamageIn["cycles"] > 1) then
				local gainMult = iterationMultiplier * DamageIn["cycles"]
				life = m_min(life + DamageIn.LifeWhenHit * (gainMult - 1), gainMult * (output.LifeRecoverable or 0))
				mana = m_min(mana + DamageIn.ManaWhenHit * (gainMult - 1), gainMult * (output.ManaUnreserved or 0))
				energyShield = m_min(energyShield + DamageIn.EnergyShieldWhenHit * (gainMult - 1), gainMult * output.EnergyShieldRecoveryCap)
			end
			for _, damageType in ipairs(dmgTypeList) do
				if Damage[damageType] > 0 then
					if frostShield > 0 then
						local tempDamage = m_min(Damage[damageType] * output["FrostShieldDamageMitigation"] / 100 / iterationMultiplier, frostShield)
						frostShield = frostShield - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if aegis[damageType] > 0 then
						local tempDamage = m_min(Damage[damageType], aegis[damageType])
						aegis[damageType] = aegis[damageType] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if isElemental[damageType] and aegis["sharedElemental"] > 0 then
						local tempDamage = m_min(Damage[damageType], aegis["sharedElemental"])
						aegis["sharedElemental"] = aegis["sharedElemental"] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if aegis["shared"] > 0 then
						local tempDamage = m_min(Damage[damageType], aegis["shared"])
						aegis["shared"] = aegis["shared"] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if guard[damageType] > 0 then
						local tempDamage = m_min(Damage[damageType] * output[damageType.."GuardAbsorbRate"] / 100 / iterationMultiplier, guard[damageType])
						guard[damageType] = guard[damageType] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if guard["shared"] > 0 then
						local tempDamage = m_min(Damage[damageType] * output["sharedGuardAbsorbRate"] / 100 / iterationMultiplier, guard["shared"])
						guard["shared"] = guard["shared"] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if ward > 0 then
						local tempDamage = m_min(Damage[damageType] * (1 - DamageIn["WardBypass"] / 100), ward)
						ward = ward - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if energyShield > 0 and (not modDB:Flag(nil, "EnergyShieldProtectsMana")) and DamageIn[damageType.."EnergyShieldBypass"] < 100 then
						local tempDamage = m_min(Damage[damageType] * (1 - DamageIn[damageType.."EnergyShieldBypass"] / 100), energyShield)
						energyShield = energyShield - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if (output.sharedMindOverMatter + output[damageType.."MindOverMatter"]) > 0 then
						local MoMDamage = Damage[damageType] * m_min(output.sharedMindOverMatter + output[damageType.."MindOverMatter"], 100) / 100
						if modDB:Flag(nil, "EnergyShieldProtectsMana") and energyShield > 0 and DamageIn[damageType.."EnergyShieldBypass"] < 100 then
							local tempDamage = m_min(MoMDamage * (1 - DamageIn[damageType.."EnergyShieldBypass"] / 100), energyShield)
							energyShield = energyShield - tempDamage
							MoMDamage = MoMDamage - tempDamage
							local tempDamage2 = m_min(MoMDamage, mana)
							mana = mana - tempDamage2
							Damage[damageType] = Damage[damageType] - tempDamage - tempDamage2
						elseif mana > 0 then
							local tempDamage = m_min(MoMDamage, mana)
							mana = mana - tempDamage
							Damage[damageType] = Damage[damageType] - tempDamage
						end
					end
					if output.preventedLifeLoss > 0 then
						if DamageIn["LifeLossBelowHalfLost"] > 0 then
							output["LifeLossBelowHalfLost"] = output["LifeLossBelowHalfLost"] + Damage[damageType] * output.preventedLifeLoss / 100
						end
						Damage[damageType] = Damage[damageType] * (1 - output.preventedLifeLoss / 100)
					end
					life = life - Damage[damageType]
				end
			end
			if modDB:Flag(nil, "WardNotBreak") then
				ward = restoreWard
			elseif ward > 0 then
				ward = 0
			end
			if DamageIn.GainWhenHit and life > 0 then
				life = m_min(life + DamageIn.LifeWhenHit, output.LifeRecoverable or 0)
				mana = m_min(mana + DamageIn.ManaWhenHit, output.ManaUnreserved or 0)
				energyShield = m_min(energyShield + DamageIn.EnergyShieldWhenHit, output.EnergyShieldRecoveryCap)
			end
			iterationMultiplier = 1
			-- to speed it up, run recursively but accelerated
			local maxDepth = data.misc.ehpCalcMaxDepth
			local speedUp = data.misc.ehpCalcSpeedUp
			DamageIn["cyclesRan"] = DamageIn["cyclesRan"] or false
			if not DamageIn["cyclesRan"] and life > 0 and DamageIn["cycles"] < maxDepth then
				Damage = { }
				for _, damageType in ipairs(dmgTypeList) do
					Damage[damageType] = DamageIn[damageType] * speedUp
				end	
				Damage["cycles"] = DamageIn["cycles"] * speedUp
				iterationMultiplier = m_max((numberOfHitsToDie(Damage) - 1) * speedUp - 1, 1)
				DamageIn["cyclesRan"] = true 
			end
		end
		if numHits >= maxHits then
			return m_huge
		end
		return numHits
	end
	
	-- number of damaging hits needed to be taken to die
	do
		local DamageIn = { }
		for _, damageType in ipairs(dmgTypeList) do
			DamageIn[damageType] = output[damageType.."TakenHit"]
		end
		output["NumberOfDamagingHits"] = numberOfHitsToDie(DamageIn)
	end

	
	do
		local DamageIn = { }
		local BlockChance = 0
		local blockEffect = 1
		local suppressChance = 0
		local suppressionEffect = 1
		local ExtraAvoidChance = 0
		local averageAvoidChance = 0
		local worstOf = env.configInput.EHPUnluckyWorstOf or 1
		-- block effect
		if damageCategoryConfig == "Melee" then
			BlockChance = output.BlockChance / 100
		else
			BlockChance = output[damageCategoryConfig.."BlockChance"] / 100
		end
		-- unlucky config to lower the value of block, dodge, evade etc for ehp
		if worstOf > 1 then
			BlockChance = BlockChance * BlockChance
			if worstOf == 4 then
				BlockChance = BlockChance * BlockChance
			end
		end
		blockEffect = (1 - BlockChance * output.BlockEffect / 100)
		if not env.configInput.DisableEHPGainOnBlock then
			DamageIn.LifeWhenHit = output.LifeOnBlock * BlockChance
			DamageIn.ManaWhenHit = output.ManaOnBlock * BlockChance
			DamageIn.EnergyShieldWhenHit = output.EnergyShieldOnBlock * BlockChance
			if damageCategoryConfig == "Spell" or damageCategoryConfig == "SpellProjectile" then
				DamageIn.EnergyShieldWhenHit = DamageIn.EnergyShieldWhenHit + output.EnergyShieldOnSpellBlock * BlockChance
			elseif damageCategoryConfig == "Average" then
				DamageIn.EnergyShieldWhenHit = DamageIn.EnergyShieldWhenHit + output.EnergyShieldOnSpellBlock / 2 * BlockChance
			end
		end
		-- suppression
		if damageCategoryConfig == "Spell" or damageCategoryConfig == "SpellProjectile" or damageCategoryConfig == "Average" then
			suppressChance = output.SpellSuppressionChance / 100
		end
		-- We include suppression in damage reduction if it is 100% otherwise we handle it here.
		if suppressChance < 1 then
			-- unlucky config to lower the value of block, dodge, evade etc for ehp
			if worstOf > 1 then
				suppressChance = suppressChance * suppressChance
				if worstOf == 4 then
					suppressChance = suppressChance * suppressChance
				end
			end
			if damageCategoryConfig == "Average" then
				suppressChance = suppressChance / 2
			end
			DamageIn.EnergyShieldWhenHit = (DamageIn.EnergyShieldWhenHit or 0) + output.EnergyShieldOnSuppress * suppressChance
			DamageIn.LifeWhenHit = (DamageIn.LifeWhenHit or 0) + output.LifeOnSuppress * suppressChance
			suppressionEffect = 1 - suppressChance * output.SpellSuppressionEffect / 100
		else
			DamageIn.EnergyShieldWhenHit = (DamageIn.EnergyShieldWhenHit or 0) + output.EnergyShieldOnSuppress * ( damageCategoryConfig == "Average" and 0.5 or 1 )
			DamageIn.LifeWhenHit = (DamageIn.LifeWhenHit or 0) + output.LifeOnSuppress * ( damageCategoryConfig == "Average" and 0.5 or 1 )
		end
		-- extra avoid chance
		if damageCategoryConfig == "Projectile" or damageCategoryConfig == "SpellProjectile" then
			ExtraAvoidChance = ExtraAvoidChance + output.AvoidProjectilesChance
		elseif damageCategoryConfig == "Average" then
			ExtraAvoidChance = ExtraAvoidChance + output.AvoidProjectilesChance / 2
		end
		-- gain when hit (currently just gain on block/suppress)
		if not env.configInput.DisableEHPGainOnBlock then
			if (DamageIn.LifeWhenHit or 0) ~= 0 or (DamageIn.ManaWhenHit or 0) ~= 0 or DamageIn.EnergyShieldWhenHit ~= 0 then
				DamageIn.GainWhenHit = true
			end
		else
			DamageIn.LifeWhenHit = 0
			DamageIn.ManaWhenHit = 0
			DamageIn.EnergyShieldWhenHit = 0
		end
		for _, damageType in ipairs(dmgTypeList) do
			 -- Emperor's Vigilance (this needs to fail with divine flesh as it can't override it, hence the check for high bypass)
			if modDB:Flag(nil, "BlockedDamageDoesntBypassES")and output[damageType.."EnergyShieldBypass"] < 100 and damageType ~= "Chaos"  then
				DamageIn[damageType.."EnergyShieldBypass"] = output[damageType.."EnergyShieldBypass"] * (1 - BlockChance) 
			end
			local AvoidChance = m_min(output["Avoid"..damageType.."DamageChance"] + ExtraAvoidChance, data.misc.AvoidChanceCap)
			-- unlucky config to lower the value of block, dodge, evade etc for ehp
			if worstOf > 1 then
				AvoidChance = AvoidChance / 100 * AvoidChance
				if worstOf == 4 then
					AvoidChance = AvoidChance / 100 * AvoidChance
				end
			end
			averageAvoidChance = averageAvoidChance + AvoidChance
			DamageIn[damageType] = output[damageType.."TakenHit"] * (blockEffect * suppressionEffect * (1 - AvoidChance / 100))
		end
		-- petrified blood degen initialisation
		if output["preventedLifeLoss"] > 0 then
			output["LifeLossBelowHalfLost"] = 0
			DamageIn["LifeLossBelowHalfLost"] = modDB:Sum("BASE", nil, "LifeLossBelowHalfLost") / 100
		end
		output["NumberOfMitigatedDamagingHits"] = numberOfHitsToDie(DamageIn)
		averageAvoidChance = averageAvoidChance / 5
		output["ConfiguredDamageChance"] = 100 * (blockEffect * suppressionEffect * (1 - averageAvoidChance / 100))
		if breakdown then
			breakdown["ConfiguredDamageChance"] = {
				s_format("%.2f ^8(chance for block to fail)", 1 - BlockChance)
			}	
			if output.ShowBlockEffect then
				t_insert(breakdown["ConfiguredDamageChance"], s_format("x %.2f ^8(block effect)", output.BlockEffect / 100))
			end
			if suppressionEffect ~= 1 then
				t_insert(breakdown["ConfiguredDamageChance"], s_format("x %.3f ^8(suppression effect)", suppressionEffect))
			end
			if averageAvoidChance > 0 then
				t_insert(breakdown["ConfiguredDamageChance"], s_format("x %.2f ^8(chance for avoidance to fail)", 1 - averageAvoidChance / 100))
			end
			t_insert(breakdown["ConfiguredDamageChance"], s_format("= %.1f%% ^8(of damage taken from a%s hit)", output["ConfiguredDamageChance"], (damageCategoryConfig == "Average" and "n " or " ")..damageCategoryConfig))
		end
	end
	
	-- chance to not be hit
	do
		local worstOf = env.configInput.EHPUnluckyWorstOf or 1
		output.MeleeNotHitChance = 100 - (1 - output.MeleeEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * 100
		output.ProjectileNotHitChance = 100 - (1 - output.ProjectileEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * 100
		output.SpellNotHitChance = 100 - (1 - output.SpellDodgeChance / 100) * 100
		output.SpellProjectileNotHitChance = output.SpellNotHitChance
		output.AverageNotHitChance = (output.MeleeNotHitChance + output.ProjectileNotHitChance + output.SpellNotHitChance + output.SpellProjectileNotHitChance) / 4
		output.ConfiguredNotHitChance = output[damageCategoryConfig.."NotHitChance"]
		-- unlucky config to lower the value of block, dodge, evade etc for ehp
		if worstOf > 1 then
			output.ConfiguredNotHitChance = output.ConfiguredNotHitChance / 100 * output.ConfiguredNotHitChance
			if worstOf == 4 then
				output.ConfiguredNotHitChance = output.ConfiguredNotHitChance / 100 * output.ConfiguredNotHitChance
			end
		end
		output["TotalNumberOfHits"] = output["NumberOfMitigatedDamagingHits"] / (1 - output["ConfiguredNotHitChance"] / 100)
		if breakdown then
			breakdown.ConfiguredNotHitChance = { }
			if damageCategoryConfig == "Melee" or damageCategoryConfig == "Projectile" then
				t_insert(breakdown["ConfiguredNotHitChance"], s_format("%.2f ^8(chance for evasion to fail)", 1 - output[damageCategoryConfig.."EvadeChance"] / 100))
				t_insert(breakdown["ConfiguredNotHitChance"], s_format("x %.2f ^8(chance for dodge to fail)", 1 - output.AttackDodgeChance / 100))
			elseif damageCategoryConfig == "Spell" or damageCategoryConfig == "SpellProjectile" then
				t_insert(breakdown["ConfiguredNotHitChance"], s_format("%.2f ^8(chance for dodge to fail)", 1 - output.SpellDodgeChance / 100))
			elseif damageCategoryConfig == "Average" then
				t_insert(breakdown["ConfiguredNotHitChance"], s_format("%.2f ^8(chance for evasion to fail, only applies to the attack portion)", 1 - (output.MeleeEvadeChance + output.ProjectileEvadeChance) / 2 / 100))
				t_insert(breakdown["ConfiguredNotHitChance"], s_format("x%.2f ^8(chance for dodge to fail)", 1 - (output.AttackDodgeChance + output.SpellDodgeChance) / 2 / 100))
			end
			if worstOf > 1 then
				t_insert(breakdown["ConfiguredNotHitChance"], s_format("unlucky worst of %d", worstOf))
			end
			t_insert(breakdown["ConfiguredNotHitChance"], s_format("= %d%% ^8(chance to be hit by a%s hit)", 100 - output.ConfiguredNotHitChance, (damageCategoryConfig == "Average" and "n " or " ")..damageCategoryConfig))
			breakdown["TotalNumberOfHits"] = {
				s_format("%.2f ^8(Number of mitigated hits)", output["NumberOfMitigatedDamagingHits"]),
				s_format("/ %.2f ^8(Chance to even be hit)", 1 - output["ConfiguredNotHitChance"] / 100),
				s_format("= %.2f ^8(total average number of hits you can take)", output["TotalNumberOfHits"]),
			}
		end
	end
	
	-- effective hit pool
	output["TotalEHP"] = output["TotalNumberOfHits"] * output["totalEnemyDamageIn"]
	if breakdown then
		breakdown["TotalEHP"] = {
			s_format("%.2f ^8(total average number of hits you can take)", output["TotalNumberOfHits"]),
			s_format("x %d ^8(total incoming damage)", output["totalEnemyDamageIn"]),
			s_format("= %d ^8(total damage you can take)", output["TotalEHP"]),
		}
	end
	
	-- survival time
	do
		output.enemySkillTime = env.configInput.enemySpeed or env.configPlaceholder.enemySpeed or 700
		local enemyActionSpeed = calcs.actionSpeedMod(actor.enemy)
		output.enemySkillTime = output.enemySkillTime / 1000 / enemyActionSpeed
		output["EHPsurvivalTime"] = output["TotalNumberOfHits"] * output.enemySkillTime
		if breakdown then
			breakdown["EHPsurvivalTime"] = {
				s_format("%.2f ^8(total average number of hits you can take)", output["TotalNumberOfHits"]),
				s_format("x %.2f ^8enemy attack/cast time", output.enemySkillTime),
				s_format("= %.2f seconds ^8(total time it would take to die)", output["EHPsurvivalTime"]),
			}
		end
	end
	
	-- petrified blood "degen"
	if output.preventedLifeLoss > 0 then
		local LifeLossBelowHalfLost = modDB:Sum("BASE", nil, "LifeLossBelowHalfLost") / 100
		output["LifeLossBelowHalfLostMax"] = output["LifeLossBelowHalfLost"] * LifeLossBelowHalfLost / 4
		output["LifeLossBelowHalfLostAvg"] = output["LifeLossBelowHalfLost"] * LifeLossBelowHalfLost / (output["EHPsurvivalTime"] + 4)
		if breakdown then
			breakdown["LifeLossBelowHalfLostMax"] = {
				s_format("%d ^8(total damage prevented by petrified blood)", output["LifeLossBelowHalfLost"]),
				s_format("* %.2f ^8(percent of damage taken)", LifeLossBelowHalfLost),
				s_format("/ %.2f ^8(over 4 seconds)", 4),
				s_format("= %.2f per second", output["LifeLossBelowHalfLostMax"]),
			}
			breakdown["LifeLossBelowHalfLostAvg"] = {
				s_format("%d ^8(total damage prevented by petrified blood)", output["LifeLossBelowHalfLost"]),
				s_format("* %.2f ^8(percent of damage taken)", LifeLossBelowHalfLost),
				s_format("/ %.2f ^8(total time of the degen (survival time + 4))", (output["EHPsurvivalTime"] + 4)),
				s_format("= %.2f per second", output["LifeLossBelowHalfLostAvg"]),
			}
		end
	end
	
	-- pvp
	if env.configInput.PvpScaling then
		local PvpTvalue = output.enemySkillTime
		local PvpMultiplier = (env.configInput.enemyMultiplierPvpDamage or 100) / 100
		
		local PvpNonElemental1 = data.misc.PvpNonElemental1
		local PvpNonElemental2 = data.misc.PvpNonElemental2
		local PvpElemental1 = data.misc.PvpElemental1
		local PvpElemental2 = data.misc.PvpElemental2

		local percentageNonElemental = (output["PhysicalTakenHit"] + output["ChaosTakenHit"]) / output["totalTakenHit"]
		local percentageElemental = 1 - percentageNonElemental
		local portionNonElemental = (output["totalTakenHit"] / PvpTvalue / PvpNonElemental2 ) ^ PvpNonElemental1 * PvpTvalue * PvpNonElemental2 * percentageNonElemental
		local portionElemental = (output["totalTakenHit"] / PvpTvalue / PvpElemental2 ) ^ PvpElemental1 * PvpTvalue * PvpElemental2 * percentageElemental
		output.PvPTotalTakenHit = ((portionNonElemental or 0) + (portionElemental or 0)) * PvpMultiplier

		if breakdown then
			breakdown.PvPTotalTakenHit = { 
				s_format("Pvp Formula is (D/(T*M))^E*T*M*P, where D is the damage, T is the time taken," ),
				s_format("M is the multiplier, E is the exponent and P is the percentage of that type (ele or non ele)"),
				s_format("(M=%.1f for ele and %.1f for non-ele)(E=%.2f for ele and %.2f for non-ele)", PvpElemental2, PvpNonElemental2, PvpElemental1, PvpNonElemental1),
				s_format("(%.1f / (%.2f * %.1f)) ^ %.2f * %.2f * %.1f * %.2f = %.1f", output["totalTakenHit"], PvpTvalue, PvpNonElemental2, PvpNonElemental1, PvpTvalue, PvpNonElemental2, percentageNonElemental, portionNonElemental),
				s_format("(%.1f / (%.2f * %.1f)) ^ %.2f * %.2f * %.1f * %.2f = %.1f", output["totalTakenHit"], PvpTvalue, PvpElemental2, PvpElemental1, PvpTvalue, PvpElemental2, percentageElemental, portionElemental),
				s_format("(portionNonElemental + portionElemental) * PvP multiplier"),
				s_format("(%.1f + %.1f) * %.1f", portionNonElemental, portionElemental, PvpMultiplier),
				s_format("= %.1f", output.PvPTotalTakenHit)
			}
		end
	end

	-- effective health pool vs dots
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
	
	-- degens
	for _, damageType in ipairs(dmgTypeList) do
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
	if output.TotalDegen then
		output.NetLifeRegen = output.LifeRegenRecovery
		output.NetManaRegen = output.ManaRegenRecovery
		output.NetEnergyShieldRegen = output.EnergyShieldRegenRecovery
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
				local takenFromMana = output[damageType.."MindOverMatter"] + output["sharedMindOverMatter"]
				if output.EnergyShieldRegenRecovery > 0 then 
					if modDB:Flag(nil, "EnergyShieldProtectsMana") then
						lifeDegen = output[damageType.."Degen"] * (1 - takenFromMana / 100)
						energyShieldDegen = output[damageType.."Degen"] * (1 - output[damageType.."EnergyShieldBypass"] / 100) * (takenFromMana / 100)
					else
						lifeDegen = output[damageType.."Degen"] * (output[damageType.."EnergyShieldBypass"] / 100) * (1 - takenFromMana / 100)
						energyShieldDegen = output[damageType.."Degen"] * (1 - output[damageType.."EnergyShieldBypass"] / 100)
					end
					manaDegen = output[damageType.."Degen"] * (output[damageType.."EnergyShieldBypass"] / 100) * (takenFromMana / 100)
				else
					lifeDegen = output[damageType.."Degen"] * (1 - takenFromMana / 100)
					manaDegen = output[damageType.."Degen"] * (takenFromMana / 100)
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
		output.TotalNetRegen = output.NetLifeRegen + output.NetManaRegen + output.NetEnergyShieldRegen
		if breakdown then
			t_insert(breakdown.NetLifeRegen, s_format("%.1f ^8(total life regen)", output.LifeRegenRecovery))
			t_insert(breakdown.NetLifeRegen, s_format("- %.1f ^8(total life degen)", totalLifeDegen))
			t_insert(breakdown.NetLifeRegen, s_format("= %.1f", output.NetLifeRegen))
			t_insert(breakdown.NetManaRegen, s_format("%.1f ^8(total mana regen)", output.ManaRegenRecovery))
			t_insert(breakdown.NetManaRegen, s_format("- %.1f ^8(total mana degen)", totalManaDegen))
			t_insert(breakdown.NetManaRegen, s_format("= %.1f", output.NetManaRegen))
			t_insert(breakdown.NetEnergyShieldRegen, s_format("%.1f ^8(total energy shield regen)", output.EnergyShieldRegenRecovery))
			t_insert(breakdown.NetEnergyShieldRegen, s_format("- %.1f ^8(total energy shield degen)", totalEnergyShieldDegen))
			t_insert(breakdown.NetEnergyShieldRegen, s_format("= %.1f", output.NetEnergyShieldRegen))
			breakdown.TotalNetRegen = {
				s_format("Net Life Regen: %.1f", output.NetLifeRegen),
				s_format("+ Net Mana Regen: %.1f", output.NetManaRegen),
				s_format("+ Net Energy Shield Regen: %.1f", output.NetEnergyShieldRegen),
				s_format("= Total Net Regen: %.1f", output.TotalNetRegen)
			}
		end
	end
	
	
	-- maximum hit taken
	-- this is not done yet, using old max hit taken
	-- fix total pools, as they aren't used anymore
	for _, damageType in ipairs(dmgTypeList) do
		-- base + petrified blood
		if output["preventedLifeLoss"] > 0 then
			output[damageType.."TotalPool"] =  output[damageType.."TotalPool"] / (1 - output["preventedLifeLoss"] / 100)
		end
		-- ward
		local wardBypass = modDB:Sum("BASE", nil, "WardBypass") or 0
		if wardBypass > 0 then
			local poolProtected = output.Ward / (1 - wardBypass / 100) * (wardBypass / 100)
			local sourcePool = output[damageType.."TotalPool"]
			sourcePool = m_max(sourcePool - poolProtected, 0) + m_min(sourcePool, poolProtected) / (wardBypass / 100)
			output[damageType.."TotalPool"] = sourcePool
		else
			output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + output.Ward or 0
		end
		-- aegis
		output[damageType.."TotalHitPool"] = output[damageType.."TotalPool"] + output[damageType.."Aegis"] or 0 + output[damageType.."sharedAegis"] or 0 + isElemental[damageType] and output[damageType.."sharedElementalAegis"] or 0
		-- guard skill
		local GuardAbsorbRate = output["sharedGuardAbsorbRate"] or 0 + output[damageType.."GuardAbsorbRate"] or 0
		if GuardAbsorbRate > 0 then
			local GuardAbsorb = output["sharedGuardAbsorb"] or 0 + output[damageType.."GuardAbsorb"] or 0
			if GuardAbsorbRate >= 100 then
				output[damageType.."TotalHitPool"] = output[damageType.."TotalHitPool"] + GuardAbsorb
			else
				local poolProtected = GuardAbsorb / (GuardAbsorbRate / 100) * (1 - GuardAbsorbRate / 100)
				output[damageType.."TotalHitPool"] = m_max(output[damageType.."TotalHitPool"] - poolProtected, 0) + m_min(output[damageType.."TotalHitPool"], poolProtected) / (1 - GuardAbsorbRate / 100)
			end
		end
		-- frost shield
		if output["FrostShieldLife"] > 0 then
			local poolProtected = output["FrostShieldLife"] / (output["FrostShieldDamageMitigation"] / 100) * (1 - output["FrostShieldDamageMitigation"] / 100)
			output[damageType.."TotalHitPool"] = m_max(output[damageType.."TotalHitPool"] - poolProtected, 0) + m_min(output[damageType.."TotalHitPool"], poolProtected) / (1 - output["FrostShieldDamageMitigation"] / 100)
		end
	end
	for _, damageType in ipairs(dmgTypeList) do
		if breakdown then
			breakdown[damageType.."MaximumHitTaken"] = { 
				label = "Maximum Hit Taken (uses lowest value)",
				rowList = { },
				colList = {
					{ label = "Type", key = "type" },
					{ label = "TotalPool", key = "pool" },
					{ label = "Taken", key = "taken" },
					{ label = "Final", key = "final" },
				},
			}
		end
		output[damageType.."MaximumHitTaken"] = m_huge
		for _, damageConvertedType in ipairs(dmgTypeList) do
			if actor.damageShiftTable[damageType][damageConvertedType] > 0 then
				local hitTaken = output[damageConvertedType.."TotalHitPool"] / (actor.damageShiftTable[damageType][damageConvertedType] / 100) / output[damageConvertedType.."BaseTakenHitMult"]
				if hitTaken < output[damageType.."MaximumHitTaken"] then
					output[damageType.."MaximumHitTaken"] = hitTaken
				end
				if breakdown then
					t_insert(breakdown[damageType.."MaximumHitTaken"].rowList, {
						type = s_format("%d%% as %s", actor.damageShiftTable[damageType][damageConvertedType], damageConvertedType),
						pool = s_format("x %d", output[damageConvertedType.."TotalHitPool"]),
						taken = s_format("/ %.2f", output[damageConvertedType.."BaseTakenHitMult"]),
						final = s_format("x %.0f", hitTaken),
					})
				end
			end
		end
		if breakdown then
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Total Pool: %d", output[damageType.."TotalHitPool"]))
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Taken Mult: %.3f",  output[damageType.."TotalHitPool"] / output[damageType.."MaximumHitTaken"]))
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Maximum hit you can take: %d", output[damageType.."MaximumHitTaken"]))
		end
	end

	local minimum = m_huge
	local SecondMinimum = m_huge
	for _, damageType in ipairs(dmgTypeList) do
		if output[damageType.."MaximumHitTaken"] < minimum then
			SecondMinimum = minimum
			minimum = output[damageType.."MaximumHitTaken"]
		elseif output[damageType.."MaximumHitTaken"] < SecondMinimum then
			SecondMinimum = output[damageType.."MaximumHitTaken"]
		end
	end
	output.SecondMinimalMaximumHitTaken = SecondMinimum
end
