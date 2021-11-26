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

-- Calculate physical damage reduction from armour, float
function calcs.armourReductionF(armour, raw)
	return (armour / (armour + raw * 5) * 100)
end

-- Calculate physical damage reduction from armour, int
function calcs.armourReduction(armour, raw)
	return round(calcs.armourReductionF(armour, raw))
end

--- Calculates Damage Reduction from Armour
---@param armour number
---@param damage number
---@param moreChance number @Chance to Defend with More Armour
---@param moreValue number multiplier to apply to armour (defaults to 2)
---@return number @Damage Reduction
function calcs.armourReductionDouble(armour, damage, moreChance, moreValue)
	if moreValue and moreValue > 0 then
		return calcs.armourReduction(armour * (1 + moreValue), damage)
	end
	return calcs.armourReduction(armour, damage) * (1 - moreChance) + calcs.armourReduction(armour * 2, damage) * moreChance
end

function calcs.actionSpeedMod(actor)
	local modDB = actor.modDB
	local actionSpeedMod = 1 + (m_max(-data.misc.TemporalChainsEffectCap, modDB:Sum("INC", nil, "TemporalChainsActionSpeed")) + modDB:Sum("INC", nil, "ActionSpeed")) / 100
	if modDB:Flag(nil, "ActionSpeedCannotBeBelowBase") then
		actionSpeedMod = m_max(1, actionSpeedMod)
	end
	return actionSpeedMod
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
	output.PhysicalResist = m_min(output.DamageReductionMax, modDB:Sum("BASE", nil, "PhysicalDamageReduction"))
	output.PhysicalResistWhenHit = m_min(output.DamageReductionMax, output.PhysicalResist + modDB:Sum("BASE", nil, "PhysicalDamageReductionWhenHit"))
	for _, elem in ipairs(resistTypeList) do
		local min, max, total
		min = data.misc.ResistFloor
			max = modDB:Override(nil, elem.."ResistMax") or m_min(data.misc.MaxResistCap, modDB:Sum("BASE", nil, elem.."ResistMax", isElemental[elem] and "ElementalResistMax"))
			total = modDB:Override(nil, elem.."Resist")
			if not total then
				local base = modDB:Sum("BASE", nil, elem.."Resist", isElemental[elem] and "ElementalResist")
				total = base * calcLib.mod(modDB, nil, elem.."Resist", isElemental[elem] and "ElementalResist")
			end
		local final = m_max(m_min(total, max), min)
		output[elem.."Resist"] = final
		output[elem.."ResistTotal"] = total
		output[elem.."ResistOverCap"] = m_max(0, total - max)
		output[elem.."ResistOver75"] = m_max(0, final - 75)
		output["Missing"..elem.."Resist"] = m_max(0, max - final)
		if breakdown then
			breakdown[elem.."Resist"] = {
				"Min: "..min.."%",
				"Max: "..max.."%",
				"Total: "..total.."%",
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
			armourBase = (modDB:Sum("BASE", nil, "Evasion") + gearEvasion) * convEvasionToArmour / 100
			local total = armourBase * calcLib.mod(modDB, nil, "Evasion", "Armour", "ArmourAndEvasion", "Defences")
			armour = armour + total
			if breakdown then
				breakdown.slot("Conversion", "Evasion to Armour", nil, armourBase, total, "Armour", "ArmourAndEvasion", "Defences", "Evasion")
			end
		end
		output.EnergyShield = modDB:Override(nil, "EnergyShield") or m_max(round(energyShield), 0)
		output.Armour = m_max(round(armour), 0)
		output.MoreArmourChance = m_min(modDB:Sum("BASE", nil, "MoreArmourChance"), 100)
		output.ArmourDefense = (modDB:Max(nil, "ArmourDefense") / 100) or 0
		output.RawArmourDefense = output.ArmourDefense > 0 and ((1 + output.ArmourDefense) * 100) or nil
		output.Evasion = m_max(round(evasion), 0)
		output.LowestOfArmourAndEvasion = m_min(output.Armour, output.Evasion)
		output.Ward = m_max(round(ward), 0)
		output["Gear:Ward"] = gearWard
		output["Gear:EnergyShield"] = gearEnergyShield
		output["Gear:Armour"] = gearArmour
		output["Gear:Evasion"] = gearEvasion
		output.CappingES = modDB:Flag(nil, "ArmourESRecoveryCap") and output.Armour < output.EnergyShield or modDB:Flag(nil, "EvasionESRecoveryCap") and output.Evasion < output.EnergyShield

		if output.CappingES then
			output.EnergyShieldRecoveryCap = modDB:Flag(nil, "ArmourESRecoveryCap") and modDB:Flag(nil, "EvasionESRecoveryCap") and m_min(output.Armour, output.Evasion) or modDB:Flag(nil, "ArmourESRecoveryCap") and output.Armour or modDB:Flag(nil, "EvasionESRecoveryCap") and output.Evasion
		end

		if modDB:Flag(nil, "CannotEvade") then
			output.EvadeChance = 0
			output.MeleeEvadeChance = 0
			output.ProjectileEvadeChance = 0
		else
			local enemyAccuracy = round(calcLib.val(enemyDB, "Accuracy"))
			output.EvadeChance = 100 - (calcs.hitChance(output.Evasion, enemyAccuracy) - modDB:Sum("BASE", nil, "EvadeChance")) * calcLib.mod(enemyDB, nil, "HitChance")
			output.MeleeEvadeChance = m_max(0, m_min(data.misc.EvadeChanceCap, output.EvadeChance * calcLib.mod(modDB, nil, "EvadeChance", "MeleeEvadeChance")))
			output.ProjectileEvadeChance = m_max(0, m_min(data.misc.EvadeChanceCap, output.EvadeChance * calcLib.mod(modDB, nil, "EvadeChance", "ProjectileEvadeChance")))
			-- Condition for displayng evade chance only if melee or projectile evade chance have the same values
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
					s_format("Approximate melee evade chance: %d%%", output.MeleeEvadeChance),
				}
				breakdown.ProjectileEvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
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
			output.LifeRegen = lifeBase * output.LifeRecoveryRateMod * modDB:More(nil, "LifeRegen") * (1 + modDB:Sum("INC", nil, "LifeRegen") / 100)
		else
			output.LifeRegen = 0
		end
		-- Don't add life recovery mod for this
		if output.LifeRegen and modDB:Flag(nil, "LifeRegenerationRecoversEnergyShield") and output.EnergyShield > 0 then
			modDB:NewMod("EnergyShieldRecovery", "BASE", lifeBase * modDB:More(nil, "LifeRegen") * (1 + modDB:Sum("INC", nil, "LifeRegen") / 100), "Life Regeneration Recovers Energy Shield")
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
			output.EnergyShieldRegen = 0 - modDB:Sum("BASE", nil, "EnergyShieldDegen")
		end
	end
	output.EnergyShieldRegen = output.EnergyShieldRegen + modDB:Sum("BASE", nil, "EnergyShieldRecovery") * output.EnergyShieldRecoveryRateMod
	output.EnergyShieldRegenPercent = round(output.EnergyShieldRegen / output.EnergyShield * 100, 1)
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

	-- Miscellaneous: move speed, stun recovery, avoidance
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
	
	-- damage avoidances
	for _, damageType in ipairs(dmgTypeList) do
		output["Avoid"..damageType.."DamageChance"] = m_min(modDB:Sum("BASE", nil, "Avoid"..damageType.."DamageChance"), data.misc.AvoidChanceCap)
	end
	output.AvoidProjectilesChance = m_min(modDB:Sum("BASE", nil, "AvoidProjectilesChance"), data.misc.AvoidChanceCap)
	-- other avoidances etc
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
	output.BlindAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidBlind"), 100)
	output.ShockAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidShock"), 100)
	output.FreezeAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidFreeze"), 100)
	output.ChillAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidChill"), 100)
	output.IgniteAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidIgnite"), 100)
	output.BleedAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidBleed"), 100)
	output.PoisonAvoidChance = m_min(modDB:Sum("BASE", nil, "AvoidPoison"), 100)
	output.CritExtraDamageReduction = m_min(modDB:Sum("BASE", nil, "ReduceCritExtraDamage"), 100)
	output.LightRadiusMod = calcLib.mod(modDB, nil, "LightRadius")
	if breakdown then
		breakdown.LightRadiusMod = breakdown.mod(modDB, nil, "LightRadius")
	end

	-- Ailment duration on self	
	output.SelfFreezeDuration = 100 * modDB:More(nil, "SelfFreezeDuration") * (1 + modDB:Sum("INC", nil, "SelfFreezeDuration") / 100) 
	output.SelfBlindDuration = 100 * modDB:More(nil, "SelfBlindDuration") * (1 + modDB:Sum("INC", nil, "SelfBlindDuration") / 100)  
	output.SelfShockDuration = 100 * modDB:More(nil, "SelfShockDuration") * (1 + modDB:Sum("INC", nil, "SelfShockDuration") / 100) 
	output.SelfChillDuration = 100 * modDB:More(nil, "SelfChillDuration") * (1 + modDB:Sum("INC", nil, "SelfChillDuration") / 100) 
	output.SelfIgniteDuration = 100 * modDB:More(nil, "SelfIgniteDuration") * (1 + modDB:Sum("INC", nil, "SelfIgniteDuration") / 100) 
	output.SelfBleedDuration = 100 * modDB:More(nil, "SelfBleedDuration") * (1 + modDB:Sum("INC", nil, "SelfBleedDuration") / 100) 
	output.SelfPoisonDuration = 100 * modDB:More(nil, "SelfPoisonDuration") * (1 + modDB:Sum("INC", nil, "SelfPoisonDuration") / 100)
	output.SelfChillEffect = 100 * modDB:More(nil, "SelfChillEffect") * (1 + modDB:Sum("INC", nil, "SelfChillEffect") / 100)
	output.SelfShockEffect = 100 * modDB:More(nil, "SelfShockEffect") * (1 + modDB:Sum("INC", nil, "SelfShockEffect") / 100)

	-- Energy Shield bypass
	output.AnyBypass = false
	for _, damageType in ipairs(dmgTypeList) do
		if modDB:Flag(nil, "BlockedDamageDoesntBypassES") and modDB:Flag(nil, "UnblockedDamageDoesBypassES") then
			local damageCategoryConfig = env.configInput.EhpCalcMode or "Average"
			if damageCategoryConfig == "Minimum" then
				output[damageType.."EnergyShieldBypass"] = 100 - m_min(output.BlockChance, output.ProjectileBlockChance, output.SpellBlockChance, output.SpellProjectileBlockChance)
			elseif damageCategoryConfig == "Melee" then
				output[damageType.."EnergyShieldBypass"] = 100 - output.BlockChance
			else
				output[damageType.."EnergyShieldBypass"] = 100 - output[damageCategoryConfig.."BlockChance"]
			end
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
	end

	-- Guard
	output.AnyGuard = false
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."GuardAbsorbRate"] = m_min(modDB:Sum("BASE", nil, "GuardAbsorbRate") + modDB:Sum("BASE", nil, damageType.."GuardAbsorbRate"), 100)
		if output[damageType.."GuardAbsorbRate"] > 0 then
			output.AnyGuard = true
			output[damageType.."GuardAbsorb"] = calcLib.val(modDB, "GuardAbsorbLimit") + calcLib.val(modDB, damageType.."GuardAbsorbLimit")
			local lifeProtected = output[damageType.."GuardAbsorb"] / (output[damageType.."GuardAbsorbRate"] / 100) * (1 - output[damageType.."GuardAbsorbRate"] / 100)
			if output[damageType.."GuardAbsorbRate"] >= 100 then
				output[damageType.."GuardEffectiveLife"] = output.LifeUnreserved + output[damageType.."GuardAbsorb"]
			else
				output[damageType.."GuardEffectiveLife"] = m_max(output.LifeUnreserved - lifeProtected, 0) + m_min(output.LifeUnreserved, lifeProtected) / (1 - output[damageType.."GuardAbsorbRate"] / 100)
			end
			if breakdown then
				breakdown[damageType.."GuardAbsorb"] = {
					s_format("Total life protected:"),
					s_format("%d ^8(guard limit)", output[damageType.."GuardAbsorb"]),
					s_format("/ %.2f ^8(portion taken from guard)", output[damageType.."GuardAbsorbRate"] / 100),
					s_format("x %.2f ^8(portion taken from life and energy shield)", 1 - output[damageType.."GuardAbsorbRate"] / 100),
					s_format("= %d", lifeProtected),
					s_format("Guard life protection: %d", output[damageType.."GuardEffectiveLife"] - output.LifeUnreserved)
				}
			end
		else
			output[damageType.."GuardEffectiveLife"] = output.LifeUnreserved
		end
	end

	-- Mind over Matter
	output.AnyMindOverMatter = false
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."MindOverMatter"] = m_min(modDB:Sum("BASE", nil, "DamageTakenFromManaBeforeLife") + modDB:Sum("BASE", nil, damageType.."DamageTakenFromManaBeforeLife"), 100)
		if output[damageType.."MindOverMatter"] > 0 then
			output.AnyMindOverMatter = true
			local sourcePool = m_max(output.ManaUnreserved or 0, 0)
			local manatext = "unreserved mana"
			if modDB:Flag(nil, "EnergyShieldProtectsMana") and output[damageType.."EnergyShieldBypass"] < 100 then
				manatext = manatext.." + non-bypassed energy shield"
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local manaProtected = (output.EnergyShieldRecoveryCap or output.EnergyShield) / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					sourcePool = m_max(sourcePool - manaProtected, 0) + m_min(sourcePool, manaProtected) / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					sourcePool = sourcePool + (output.EnergyShieldRecoveryCap or output.EnergyShield)
				end
			end
			local poolProtected = sourcePool / (output[damageType.."MindOverMatter"] / 100) * (1 - output[damageType.."MindOverMatter"] / 100)
			if output[damageType.."MindOverMatter"] >= 100 then
				output[damageType.."ManaEffectiveLife"] = output[damageType.."GuardEffectiveLife"] + sourcePool
			else
				output[damageType.."ManaEffectiveLife"] = m_max(output[damageType.."GuardEffectiveLife"] - poolProtected, 0) + m_min(output[damageType.."GuardEffectiveLife"], poolProtected) / (1 - output[damageType.."MindOverMatter"] / 100)
			end
			if breakdown then
				if output[damageType.."MindOverMatter"] then
					breakdown[damageType.."MindOverMatter"] = {
						s_format("Total life protected:"),
						s_format("%d ^8(%s)", sourcePool, manatext),
						s_format("/ %.2f ^8(portion taken from mana)", output[damageType.."MindOverMatter"] / 100),
						s_format("x %.2f ^8(portion taken from life)", 1 - output[damageType.."MindOverMatter"] / 100),
						s_format("= %d", poolProtected),
						s_format("Effective life: %d", output[damageType.."ManaEffectiveLife"])
					}
				end
			end
		else
			output[damageType.."ManaEffectiveLife"] = output[damageType.."GuardEffectiveLife"]
		end
	end
	
	--aegis
	output.AnyAegis = false
	for _, damageType in ipairs(dmgTypeList) do
		local aegisValue = modDB:Sum("BASE", nil, damageType.."AegisValue")
		if aegisValue > 0 then
			output.AnyAegis = true
			output[damageType.."Aegis"] = aegisValue
		else
			output[damageType.."Aegis"] = 0
		end
	end

	--total pool
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."TotalPool"] = output[damageType.."ManaEffectiveLife"]
		output[damageType.."GuardEffectivePool"] = 0
		local manatext = "Mana"
		if output[damageType.."EnergyShieldBypass"] < 100 then 
			if modDB:Flag(nil, "EnergyShieldProtectsMana") then
				manatext = manatext.." and non-bypassed Energy Shield"
			else
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local poolProtected = (output.EnergyShieldRecoveryCap or output.EnergyShield) / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					output[damageType.."TotalPool"] = m_max(output[damageType.."TotalPool"] - poolProtected, 0) + m_min(output[damageType.."TotalPool"], poolProtected) / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + (output.EnergyShieldRecoveryCap or output.EnergyShield)
				end
				if output[damageType.."GuardAbsorbRate"] > 0 then
					local guardRemain = output[damageType.."GuardAbsorb"] - (output[damageType.."GuardEffectiveLife"] - output.LifeUnreserved)
					local espool = output[damageType.."TotalPool"] - output[damageType.."ManaEffectiveLife"]
					if guardRemain > 0 then
						local poolProtected = guardRemain / (output[damageType.."GuardAbsorbRate"] / 100) * (1 - output[damageType.."GuardAbsorbRate"] / 100)
						if output[damageType.."GuardAbsorbRate"] >= 100 then
							output[damageType.."GuardEffectivePool"] = guardRemain
						else
							output[damageType.."GuardEffectivePool"] = m_max(espool - poolProtected, 0) + m_min(espool, poolProtected) / (1 - output[damageType.."GuardAbsorbRate"] / 100) - espool
						end
						output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + output[damageType.."GuardEffectivePool"]
					end
				end
			end
		end
		if output[damageType.."Aegis"] > 0 then
			output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + output[damageType.."Aegis"]
		end
		if breakdown then
			breakdown[damageType.."TotalPool"] = {
				s_format("Life: %d", output.LifeUnreserved)
			}
			if output[damageType.."GuardEffectiveLife"] ~= output.LifeUnreserved then
				t_insert(breakdown[damageType.."TotalPool"], s_format("Guard skill: %d", output[damageType.."GuardEffectiveLife"] - output.LifeUnreserved + output[damageType.."GuardEffectivePool"]))
			end
			if output[damageType.."ManaEffectiveLife"] ~= output[damageType.."GuardEffectiveLife"] then
				t_insert(breakdown[damageType.."TotalPool"], s_format("%s through MoM: %d", manatext, output[damageType.."ManaEffectiveLife"] - output[damageType.."GuardEffectiveLife"]))
			end
			if (not modDB:Flag(nil, "EnergyShieldProtectsMana")) and output[damageType.."EnergyShieldBypass"] < 100 then
				t_insert(breakdown[damageType.."TotalPool"], s_format("Non-bypassed Energy Shield: %d", output[damageType.."TotalPool"] - output[damageType.."ManaEffectiveLife"] - output[damageType.."GuardEffectivePool"] - output[damageType.."Aegis"]))
			end
			if output[damageType.."Aegis"] > 0 then
				t_insert(breakdown[damageType.."TotalPool"], s_format("Aegis: %d", output[damageType.."Aegis"]))
			end
			t_insert(breakdown[damageType.."TotalPool"], s_format("TotalPool: %d", output[damageType.."TotalPool"]))
			if output[damageType.."GuardEffectivePool"] > 0 then
				t_insert(breakdown[damageType.."GuardAbsorb"], s_format("Guard energy shield protection: %d", output[damageType.."GuardEffectivePool"]))
			end
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
			local resist = modDB:Flag(nil, "SelfIgnore"..damageType.."Resistance") and 0 or output[damageType.."Resist"]
			if damageType == "Physical" then
				resist = m_max(resist, 0)
			end
			output[damageType.."TakenDotMult"] = (1 - resist / 100) * (1 + takenInc / 100) * takenMore
			if breakdown then
				breakdown[damageType.."TakenDotMult"] = { }
				breakdown.multiChain(breakdown[damageType.."TakenDotMult"], {
					label = "DoT Multiplier:",
					{ "%.2f ^8(%s)", (1 - resist / 100), damageType == "Physical" and "physical damage reduction" or "resistance" },
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
	output.AnyTakenReflect = 0
	for _, damageType in ipairs(dmgTypeList) do
		if output[damageType.."TakenReflect"] ~= output[damageType.."TakenHit"] then
			output.AnyTakenReflect = true
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
		output.TotalNetRegen = output.NetLifeRegen + output.NetManaRegen + output.NetEnergyShieldRegen
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
			breakdown.TotalNetRegen = {
				s_format("Net Life Regen: %.1f", output.NetLifeRegen),
				s_format("+ Net Mana Regen: %.1f", output.NetManaRegen),
				s_format("+ Net Energy Shield Regen: %.1f", output.NetEnergyShieldRegen),
				s_format("= Total Net Regen: %.1f", output.TotalNetRegen)
			}
		end
	end

	-- Incoming hit damage multipliers
	local moreArmourChance = (output.MoreArmourChance == 100 or env.configInput.armourCalculationMode == "MAX") and 1 or env.configInput.armourCalculationMode == "MIN" and 0 or output.MoreArmourChance / 100
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
				local resist = modDB:Flag(nil, "SelfIgnore"..destType.."Resistance") and 0 or output[destType.."ResistWhenHit"] or output[destType.."Resist"]
				if destType == "Physical" or modDB:Flag(nil, "ArmourAppliesTo"..destType.."DamageTaken") then
					local damage = env.configInput.enemyHit or env.data.monsterDamageTable[env.enemyLevel] * 1.5
					local armourReduct = 0
					local portionArmour = 100
					if destType == "Physical" then
						if not modDB:Flag(nil, "ArmourDoesNotApplyToPhysicalDamageTaken") then
							armourReduct = calcs.armourReductionDouble(output.Armour, damage * portion / 100, moreArmourChance, output.ArmourDefense)
							resist = m_min(output.DamageReductionMax, resist + armourReduct)
						end
						resist = m_max(resist, 0)
					else
						portionArmour = 100 - resist
						armourReduct = calcs.armourReductionDouble(output.Armour, damage * portion / 100 * portionArmour / 100, moreArmourChance, output.ArmourDefense)
						resist = resist + m_min(output.DamageReductionMax, armourReduct) * portionArmour / 100
					end
					if damageType == destType then
						output[damageType.."DamageReduction"] = damageType == "Physical" and resist or m_min(output.DamageReductionMax, armourReduct) * portionArmour / 100
						if breakdown then
							breakdown[damageType.."DamageReduction"] = {
								s_format("Enemy Hit Damage: %d ^8(%s the Configuration tab)", damage, env.configInput.enemyHit and "overridden from" or "can be overridden in"),
							}
							if portion < 100 then
								t_insert(breakdown[damageType.."DamageReduction"], s_format("Portion taken as %s: %d%%", damageType, portion))
							end
							if portionArmour < 100 then
								t_insert(breakdown[damageType.."DamageReduction"], s_format("Portion mitigated by Armour: %d%%", portionArmour))
							end
							t_insert(breakdown[damageType.."DamageReduction"], s_format("Reduction from Armour: %d%%", armourReduct))
						end
					end
				end
				local takenMult = output[destType.."TakenHit"]
				local takenMultReflect = output[destType.."TakenReflect"]
				local final = portion / 100 * (1 - resist / 100) * takenMult
				local finalReflect = portion / 100 * (1 - resist / 100) * takenMultReflect
				mult = mult + final
				output[damageType..destType.."BaseTakenHitMult"] = (1 - resist / 100) * takenMult
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
		for _, hitType in ipairs(hitSourceList) do
			local baseTakenInc = modDB:Sum("INC", nil, hitType.."DamageTaken")
			local baseTakenMore = modDB:More(nil, hitType.."DamageTaken")
			do
				-- Hit
				output[hitType.."TakenHitMult"] = m_max((1 + baseTakenInc / 100) * baseTakenMore)
				output[hitType..damageType.."TakenHitMult"] = mult * output[hitType.."TakenHitMult"]
			end
		end
		if output.AnyTakenReflect then
			output[damageType.."TakenReflectMult"] = multReflect
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

	-- Spell Suppression

	function chanceSuppressDamage(outputText, outputName, suppressionChance, suppressionEffect)
		output[outputName] = 100 - (1 - suppressionChance * suppressionEffect / 100 / 100 ) * 100
		if breakdown then
			breakdown[outputName] = { }
			if output.ShowBlockEffect then
				breakdown.multiChain(breakdown[outputName], {
					{ "%.2f ^8(chance for suppression to fail)", 1 - suppressionChance / 100 },
					{ "%d%% Damage taken from suppressed hits", 100 - suppressionEffect },
					total = s_format("= %d%% ^8(Suppressed damage taken from spells)", 100 - output[outputName]),
				})
			else
				breakdown.multiChain(breakdown[outputName], {
					{ "%.2f ^8(chance for suppression to fail)", 1 - suppressionChance / 100 },
					total = s_format("= %d%% ^8(Suppressed damage taken from spells)", 100 - output[outputName]),
				})
			end
		end
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

	chanceSuppressDamage("Spell hit", "SpellSuppressionEffectiveChance", output.SpellSuppressionChance, output.SpellSuppressionEffect)

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
	--FIX ARMOUR MITIGATION FOR THIS, uses input damage to calculate mitigation from armour, instead of maximum hit taken
	local damageCategoryConfig = env.configInput.EhpCalcMode or "Average"
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
				local hitTaken = output[damageConvertedType.."TotalPool"] / (actor.damageShiftTable[damageType][damageConvertedType] / 100) / output[damageType..damageConvertedType.."BaseTakenHitMult"]
				if damageCategoryConfig == "Melee" or damageCategoryConfig == "Projectile" then
					hitTaken = hitTaken * (1 / output.AttackTakenHitMult)
				end
				if damageCategoryConfig == "Spell" or damageCategoryConfig == "Projectile Spell" then
					hitTaken = hitTaken * (1 / output.SpellTakenHitMult)
				end
				if damageCategoryConfig == "Average" then
					hitTaken = hitTaken * (1 / ((output.SpellTakenHitMult + output.AttackTakenHitMult) / 2))
				end
				if hitTaken < output[damageType.."MaximumHitTaken"] then
					output[damageType.."MaximumHitTaken"] = hitTaken
				end
				if breakdown then
					t_insert(breakdown[damageType.."MaximumHitTaken"].rowList, {
						type = s_format("%d%% as %s", actor.damageShiftTable[damageType][damageConvertedType], damageConvertedType),
						pool = s_format("x %d", output[damageConvertedType.."TotalPool"]),
						taken = s_format("/ %.2f", output[damageType..damageConvertedType.."BaseTakenHitMult"]),
						final = s_format("x %.0f", hitTaken),
					})
				end
			end
		end
		if breakdown then
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Total Pool: %d", output[damageType.."TotalPool"]))
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Taken Mult: %.2f",  output[damageType.."TotalPool"] / output[damageType.."MaximumHitTaken"]))
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Maximum hit you can take: %d", output[damageType.."MaximumHitTaken"]))
		end
	end
	
	local damageCategoryConfig = env.configInput.EhpCalcMode or "Average"
	for _, damageType in ipairs(dmgTypeList) do
		local damageCategory = damageCategoryConfig
		local minimumChanceToTakeDamage = -m_huge
		local minimumEHPMode = "NONE"
		if damageCategoryConfig == "Minimum" then
			local damageCategoriesList = {"Melee", "Projectile", "Spell", "SpellProjectile"}
			minimumEHPMode = "Melee"
			for _, damageCategories in ipairs(damageCategoriesList) do
				local convertedAvoidance = 0
				for _, damageConvertedType in ipairs(dmgTypeList) do
					convertedAvoidance = convertedAvoidance + output[damageConvertedType..damageCategories.."DamageChance"] * actor.damageShiftTable[damageType][damageConvertedType] / 100
				end
				local chanceToTakeDamage = (1 - output[damageCategories.."NotHitChance"] / 100) / (1 - convertedAvoidance / 100)
				if chanceToTakeDamage > minimumChanceToTakeDamage then
					minimumChanceToTakeDamage = chanceToTakeDamage
					minimumEHPMode = damageCategories
				end
			end
			damageCategory = minimumEHPMode
		end
		local damage = env.configInput.enemyHit or env.data.monsterDamageTable[env.enemyLevel] * 1.5
		--effective number of hits to deplete pool
		output[damageType.."NumberOfHits"] = m_huge
		local minimumDamageConvertedType = damageType -- this is used for the breakdown
		for _, damageConvertedType in ipairs(dmgTypeList) do
			if actor.damageShiftTable[damageType][damageConvertedType] > 0 then
				local damageTaken = (damage  * actor.damageShiftTable[damageType][damageConvertedType] / 100 * output[damageType..damageConvertedType.."BaseTakenHitMult"])
				if damageCategoryConfig == "Melee" or damageCategoryConfig == "Projectile" then
					damageTaken = damageTaken * output.AttackTakenHitMult
				end
				if damageCategoryConfig == "Spell" or damageCategoryConfig == "SpellProjectile" then
					damageTaken = damageTaken * ((100 - output.SpellSuppressionEffectiveChance) / 100) * output.SpellTakenHitMult
				end
				if damageCategoryConfig == "Average" then
					damageTaken = damageTaken * ((((100 - output.SpellSuppressionEffectiveChance) / 100) * output.SpellTakenHitMult + output.AttackTakenHitMult) / 2)
				end
				local hitsTaken = math.ceil(output[damageConvertedType.."TotalPool"] / damageTaken)
				hitsTaken = hitsTaken / (1 - output[damageCategory.."NotHitChance"] / 100)  / (1 - output[damageConvertedType..damageCategory.."DamageChance"] / 100)
				if hitsTaken < output[damageType.."NumberOfHits"] then
					output[damageType.."NumberOfHits"] = hitsTaken
					minimumDamageConvertedType = damageConvertedType
				end
			end
		end
		if breakdown then
			breakdown[damageType.."NumberOfHits"] = {
				s_format("EHP calculation Mode: %s", damageCategoryConfig),
				s_format("Total Pool: %d", output[damageType.."TotalPool"]),
				s_format("Damage Before mitigation: %d", damage),
				s_format("Damage Taken PerHit: %.2f", damage * output[damageType..minimumDamageConvertedType.."BaseTakenHitMult"]),
				s_format("%s chance not to be hit: %d%%", damageCategory, output[damageCategory.."NotHitChance"]),
				s_format("%s chance to not take damage when hit: %d%%", damageCategory, output[minimumDamageConvertedType..damageCategory.."DamageChance"]),
				s_format("Average Number of hits you can take: %.2f", output[damageType.."NumberOfHits"]),
			}
		end
	--total EHP
		output[damageType.."TotalEHP"] = output[damageType.."NumberOfHits"] * damage
		if breakdown then
			breakdown[damageType.."TotalEHP"] = {
			s_format("EHP calculation Mode: %s", damageCategoryConfig),
			}
			if damageCategoryConfig == "Minimum" then
				t_insert(breakdown[damageType.."TotalEHP"], s_format("Minimum type: %s", damageCategory))
			end
			t_insert(breakdown[damageType.."TotalEHP"], s_format("Average Number of hits you can take: %.2f", output[damageType.."NumberOfHits"]))
			t_insert(breakdown[damageType.."TotalEHP"], s_format("Damage Before mitigation: %d", damage))
			t_insert(breakdown[damageType.."TotalEHP"], s_format("Total Effective Hit Pool: %.0f", output[damageType.."TotalEHP"]))
		end
	end
end
