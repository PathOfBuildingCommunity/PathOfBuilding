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

local resistTypeList = { "Fire", "Cold", "Lightning", "Chaos" }

-- Performs all defensive calculations
function calcs.defence(env, actor)
	local modDB = actor.modDB
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local breakdown = actor.breakdown

	local condList = modDB.conditions

	-- Resistances
	for _, elem in ipairs(resistTypeList) do
		local max, total
		if elem == "Chaos" and modDB:Sum("FLAG", nil, "ChaosInoculation") then
			max = 100
			total = 100
		else
			max = modDB:Sum("BASE", nil, elem.."ResistMax")
			total = modDB:Sum("BASE", nil, elem.."Resist", isElemental[elem] and "ElementalResist")
		end
		output[elem.."Resist"] = m_min(total, max)
		output[elem.."ResistTotal"] = total
		output[elem.."ResistOverCap"] = m_max(0, total - max)
		if breakdown then
			breakdown[elem.."Resist"] = {
				"Max: "..max.."%",
				"Total: "..total.."%",
				"In hideout: "..(total + 60).."%",
			}
		end
	end
	condList.UncappedLightningResistIsLowest = (output.LightningResistTotal <= output.ColdResistTotal and output.LightningResistTotal <= output.FireResistTotal)
	condList.UncappedColdResistIsLowest = (output.ColdResistTotal <= output.LightningResistTotal and output.ColdResistTotal <= output.FireResistTotal)
	condList.UncappedFireResistIsLowest = (output.FireResistTotal <= output.LightningResistTotal and output.FireResistTotal <= output.ColdResistTotal)
	condList.UncappedLightningResistIsHighest = (output.LightningResistTotal >= output.ColdResistTotal and output.LightningResistTotal >= output.FireResistTotal)
	condList.UncappedColdResistIsHighest = (output.ColdResistTotal >= output.LightningResistTotal and output.ColdResistTotal >= output.FireResistTotal)
	condList.UncappedFireResistIsHighest = (output.FireResistTotal >= output.LightningResistTotal and output.FireResistTotal >= output.ColdResistTotal)

	-- Primary defences: Energy shield, evasion and armour
	do
		local ironReflexes = modDB:Sum("FLAG", nil, "IronReflexes")
		local energyShield = 0
		local armour = 0
		local evasion = 0
		if breakdown then
			breakdown.EnergyShield = { slots = { } }
			breakdown.Armour = { slots = { } }
			breakdown.Evasion = { slots = { } }
		end
		local energyShieldBase = modDB:Sum("BASE", nil, "EnergyShield")
		if energyShieldBase > 0 then
			energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, nil, "EnergyShield", "Defences")
			if breakdown then
				breakdown.slot("Global", nil, nil, energyShieldBase, nil, "EnergyShield", "Defences")
			end
		end
		local armourBase = modDB:Sum("BASE", nil, "Armour", "ArmourAndEvasion")
		if armourBase > 0 then
			armour = armour + armourBase * calcLib.mod(modDB, nil, "Armour", "ArmourAndEvasion", "Defences")
			if breakdown then
				breakdown.slot("Global", nil, nil, armourBase, nil, "Armour", "ArmourAndEvasion", "Defences")
			end
		end
		local evasionBase = modDB:Sum("BASE", nil, "Evasion", "ArmourAndEvasion")
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
		local gearEnergyShield = 0
		local gearArmour = 0
		local gearEvasion = 0
		local slotCfg = wipeTable(tempTable1)
		for _, slot in pairs({"Helmet","Body Armour","Gloves","Boots","Weapon 2"}) do
			local armourData = actor.itemList[slot] and actor.itemList[slot].armourData
			if armourData then
				slotCfg.slotName = slot
				energyShieldBase = armourData.EnergyShield or 0
				if energyShieldBase > 0 then
					energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, slotCfg, "EnergyShield", "Defences")
					gearEnergyShield = gearEnergyShield + energyShieldBase
					if breakdown then
						breakdown.slot(slot, nil, slotCfg, energyShieldBase, nil, "EnergyShield", "Defences")
					end
				end
				armourBase = armourData.Armour or 0
				if armourBase > 0 then
					if slot == "Body Armour" and modDB:Sum("FLAG", nil, "Unbreakable") then
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
		local convManaToES = modDB:Sum("BASE", nil, "ManaGainAsEnergyShield")
		if convManaToES > 0 then
			energyShieldBase = modDB:Sum("BASE", nil, "Mana") * convManaToES / 100
			energyShield = energyShield + energyShieldBase * calcLib.mod(modDB, nil, "Mana", "EnergyShield", "Defences") 
			if breakdown then
				breakdown.slot("Conversion", "Mana to Energy Shield", nil, energyShieldBase, nil, "EnergyShield", "Defences", "Mana")
			end
		end
		local convLifeToES = modDB:Sum("BASE", nil, "LifeConvertToEnergyShield", "LifeGainAsEnergyShield")
		if convLifeToES > 0 then
			energyShieldBase = modDB:Sum("BASE", nil, "Life") * convLifeToES / 100
			local total
			if modDB:Sum("FLAG", nil, "ChaosInoculation") then
				total = 1
			else
				total = energyShieldBase * calcLib.mod(modDB, nil, "Life", "EnergyShield", "Defences")
			end
			energyShield = energyShield + total
			if breakdown then
				breakdown.slot("Conversion", "Life to Energy Shield", nil, energyShieldBase, total, "EnergyShield", "Defences", "Life")
			end
		end
		output.EnergyShield = round(energyShield)
		output.Armour = round(armour)
		output.Evasion = round(evasion)
		output.LowestOfArmourAndEvasion = m_min(output.Armour, output.Evasion)
		output["Gear:EnergyShield"] = gearEnergyShield
		output["Gear:Armour"] = gearArmour
		output["Gear:Evasion"] = gearEvasion
		output.EnergyShieldRecharge = round(output.EnergyShield * 0.2 * calcLib.mod(modDB, nil, "EnergyShieldRecharge", "EnergyShieldRecovery"), 1)
		output.EnergyShieldRechargeDelay = 2 / (1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100)
		if breakdown then
			breakdown.EnergyShieldRecharge = breakdown.simple(output.EnergyShield * 0.2, nil, output.EnergyShieldRecharge, "EnergyShieldRecharge", "EnergyShieldRecovery")
			if output.EnergyShieldRechargeDelay ~= 2 then
				breakdown.EnergyShieldRechargeDelay = {
					"2.00s ^8(base)",
					s_format("/ %.2f ^8(faster start)", 1 + modDB:Sum("INC", nil, "EnergyShieldRechargeFaster") / 100),
					s_format("= %.2fs", output.EnergyShieldRechargeDelay)
				}
			end
		end
		if modDB:Sum("FLAG", nil, "CannotEvade") then
			output.EvadeChance = 0
		else
			local enemyAccuracy = round(calcLib.val(enemyDB, "Accuracy"))
			output.EvadeChance = 100 - calcLib.hitChance(output.Evasion, enemyAccuracy) * calcLib.mod(enemyDB, nil, "HitChance")
			if breakdown then
				breakdown.EvadeChance = {
					s_format("Enemy level: %d ^8(%s the Configuration tab)", env.enemyLevel, env.configInput.enemyLevel and "overridden from" or "can be overridden in"),
					s_format("Average enemy accuracy: %d", enemyAccuracy),
					s_format("Approximate evade chance: %d%%", output.EvadeChance),
				}
			end
		end
	end

	-- Mana, life and energy shield regen
	do
		output.ManaRegen = round((modDB:Sum("BASE", nil, "ManaRegen") + output.Mana * modDB:Sum("BASE", nil, "ManaRegenPercent") / 100) * calcLib.mod(modDB, nil, "ManaRegen", "ManaRecovery"), 1)
		if breakdown then
			breakdown.ManaRegen = breakdown.simple(nil, nil, output.ManaRegen, "ManaRegen", "ManaRecovery")
		end
		if modDB:Sum("FLAG", nil, "NoLifeRegen") then
			output.LifeRegen = 0
		elseif modDB:Sum("FLAG", nil, "ZealotsOath") then
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
				output.LifeRegen = lifeBase * calcLib.mod(modDB, nil, "LifeRecovery")
				output.LifeRegenPercent = round(output.LifeRegen / output.Life * 100, 1)
			else
				output.LifeRegen = 0
			end
		end
		local esBase = modDB:Sum("BASE", nil, "EnergyShieldRegen")
		local esPercent = modDB:Sum("BASE", nil, "EnergyShieldRegenPercent")
		if esPercent > 0 then
			esBase = esBase + output.EnergyShield * esPercent / 100
		end
		if esBase > 0 then
			output.EnergyShieldRegen = esBase * calcLib.mod(modDB, nil, "EnergyShieldRecovery")
			output.EnergyShieldRegenPercent = round(output.EnergyShieldRegen / output.EnergyShield * 100, 1)
		else
			output.EnergyShieldRegen = 0
		end
	end

	-- Leech caps
	if modDB:Sum("FLAG", nil, "GhostReaver") then
		output.MaxEnergyShieldLeechRate = output.EnergyShield * modDB:Sum("BASE", nil, "MaxLifeLeechRate") / 100
		if breakdown then
			breakdown.MaxEnergyShieldLeechRate = {
				s_format("%d ^8(maximum energy shield)", output.EnergyShield),
				s_format("x %d%% ^8(percenage of life to maximum leech rate)", modDB:Sum("BASE", nil, "MaxLifeLeechRate")),
				s_format("= %.1f", output.MaxEnergyShieldLeechRate)
			}
		end
	else
		output.MaxLifeLeechRate = output.Life * modDB:Sum("BASE", nil, "MaxLifeLeechRate") / 100
		if breakdown then
			breakdown.MaxLifeLeechRate = {
				s_format("%d ^8(maximum life)", output.Life),
				s_format("x %d%% ^8(percenage of life to maximum leech rate)", modDB:Sum("BASE", nil, "MaxLifeLeechRate")),
				s_format("= %.1f", output.MaxLifeLeechRate)
			}
		end
	end
	output.MaxManaLeechRate = output.Mana * modDB:Sum("BASE", nil, "MaxManaLeechRate") / 100
	if breakdown then
		breakdown.MaxManaLeechRate = {
			s_format("%d ^8(maximum mana)", output.Mana),
			s_format("x %d%% ^8(percenage of mana to maximum leech rate)", modDB:Sum("BASE", nil, "MaxManaLeechRate")),
			s_format("= %.1f", output.MaxManaLeechRate)
		}
	end

	-- Other defences: block, dodge, stun recovery/avoidance
	do
		output.MovementSpeedMod = calcLib.mod(modDB, nil, "MovementSpeed")
		if modDB:Sum("FLAG", nil, "MovementSpeedCannotBeBelowBase") then
			output.MovementSpeedMod = m_max(output.MovementSpeedMod, 1)
		end
		output.BlockChanceMax = modDB:Sum("BASE", nil, "BlockChanceMax")
		local shieldData = actor.itemList["Weapon 2"] and actor.itemList["Weapon 2"].armourData
		output.BlockChance = m_min(((shieldData and shieldData.BlockChance or 0) + modDB:Sum("BASE", nil, "BlockChance")) * calcLib.mod(modDB, nil, "BlockChance"), output.BlockChanceMax) 
		output.SpellBlockChance = m_min(modDB:Sum("BASE", nil, "SpellBlockChance") * calcLib.mod(modDB, nil, "SpellBlockChance") + output.BlockChance * modDB:Sum("BASE", nil, "BlockChanceConv") / 100, output.BlockChanceMax) 
		if breakdown then
			breakdown.BlockChance = breakdown.simple(shieldData and shieldData.BlockChance, nil, output.BlockChance, "BlockChance")
			breakdown.SpellBlockChance = breakdown.simple(output.BlockChance * modDB:Sum("BASE", nil, "BlockChanceConv") / 100, nil, output.SpellBlockChance, "SpellBlockChance")
		end
		if modDB:Sum("FLAG", nil, "CannotBlockAttacks") then
			output.BlockChance = 0
		end
		output.AttackDodgeChance = m_min(modDB:Sum("BASE", nil, "AttackDodgeChance"), 75)
		output.SpellDodgeChance = m_min(modDB:Sum("BASE", nil, "SpellDodgeChance"), 75)
		local stunChance = 100 - modDB:Sum("BASE", nil, "AvoidStun")
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
	end
end