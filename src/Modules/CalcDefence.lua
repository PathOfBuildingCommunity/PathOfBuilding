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
local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}

local resistTypeList = { "Fire", "Cold", "Lightning", "Chaos" }

-- Calculate hit chance
function calcs.hitChance(evasion, accuracy)
	if accuracy < 0 then
		return 5
	end
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

--- Calculates Damage Reduction from Armour
---@param armour number
---@param damage number
---@param doubleChance number @Chance to Defend with Double Armour 
---@return number @Damage Reduction
function calcs.armourReductionDouble(armour, damage, doubleChance)
	return calcs.armourReduction(armour, damage) * (1 - doubleChance) + calcs.armourReduction(armour * 2, damage) * doubleChance
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
		output["Missing"..elem.."Resist"] = m_max(0, max - final)
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
			armourBase = modDB:Sum("BASE", nil, "Evasion") * convEvasionToArmour / 100
			local total = armourBase * calcLib.mod(modDB, nil, "Evasion", "Armour", "ArmourAndEvasion", "Defences")
			armour = armour + total
			if breakdown then
				breakdown.slot("Conversion", "Evasion to Armour", nil, armourBase, total, "Armour", "ArmourAndEvasion", "Defences", "Evasion")
			end
		end
		output.EnergyShield = modDB:Override(nil, "EnergyShield") or m_max(round(energyShield), 0)
		output.Armour = m_max(round(armour), 0)
		output.DoubleArmourChance = m_min(modDB:Sum("BASE", nil, "DoubleArmourChance"), 100)
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

	-- Block
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
	output.AttackDodgeChance = m_min(modDB:Sum("BASE", nil, "AttackDodgeChance"), data.misc.DodgeChanceCap)
	output.SpellDodgeChance = m_min(modDB:Sum("BASE", nil, "SpellDodgeChance"), data.misc.DodgeChanceCap)
	if env.mode_effective and modDB:Flag(nil, "DodgeChanceIsUnlucky") then
		output.AttackDodgeChance = output.AttackDodgeChance / 100 * output.AttackDodgeChance
		output.SpellDodgeChance = output.SpellDodgeChance / 100 * output.SpellDodgeChance
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
			output.LifeRegen = lifeBase * output.LifeRecoveryRateMod * modDB:More(nil, "LifeRegen")
		else
			output.LifeRegen = 0
		end
		-- Don't add life recovery mod for this
		if output.LifeRegen and modDB:Flag(nil, "LifeRegenerationRecoversEnergyShield") then
			modDB:NewMod("EnergyShieldRecovery", "BASE", lifeBase * modDB:More(nil, "LifeRegen"), "Life Regeneration Recovers Energy Shield")
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
	if modDB:Flag(nil, "Elusive") then
		output.ElusiveEffectMod = calcLib.mod(modDB, nil, "ElusiveEffect", "BuffEffectOnSelf") * 100
	end
	
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
					{ label = "Final", key = "final" },
					{ label = "From", key = "from" },
				},
			}
		end
		for _, damageType in ipairs(dmgTypeList) do
			local stringVal = "Default"
			local enemyDamageMult = calcLib.mod(enemyDB, nil, "Damage", damageType.."Damage", isElemental[damageType] and "ElementalDamage" or nil) --missing taunt from allies
			local enemyDamage = 0
			if damageType == "Physical" then
				enemyDamage = env.configInput["enemy"..damageType.."Damage"] or env.data.monsterDamageTable[env.enemyLevel] * 1.5
			else
				enemyDamage = env.configInput["enemy"..damageType.."Damage"] or 0
			end
			if env.configInput["enemy"..damageType.."Damage"] then
				stringVal = "Config"
			end
			output["totalEnemyDamageIn"] = output["totalEnemyDamageIn"] + enemyDamage
			output[damageType.."EnemyDamage"] = enemyDamage * enemyDamageMult
			output["totalEnemyDamage"] = output["totalEnemyDamage"] + output[damageType.."EnemyDamage"]
			if breakdown then
				breakdown[damageType.."EnemyDamage"] = {
				s_format("from %s: %d", stringVal, enemyDamage),
				s_format("* %.2f (modifiers to enemy damage)", enemyDamageMult),
				s_format("= %d", output[damageType.."EnemyDamage"]),
				}
				t_insert(breakdown["totalEnemyDamage"].rowList, {
					type = s_format("%s", damageType),
					value = s_format("%d", enemyDamage),
					mult = s_format("%.2f", enemyDamageMult),
					final = s_format("%d", output[damageType.."EnemyDamage"]),
					from = s_format("%s", stringVal),
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
		end
	end

	-- Incoming hit damage multipliers
	local doubleArmourChance = (output.DoubleArmourChance == 100 or env.configInput.armourCalculationMode == "MAX") and 1 or env.configInput.armourCalculationMode == "MIN" and 0 or output.DoubleArmourChance / 100
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
		local enemyPen = env.configInput["enemy"..damageType.."Pen"] or 0
		local takenFlat = modDB:Sum("BASE", nil, "DamageTaken", damageType.."DamageTaken", "DamageTakenWhenHit", damageType.."DamageTakenWhenHit")
		if damageCategoryConfig == "Melee" or damageCategoryConfig == "Projectile" then
			takenFlat = takenFlat + modDB:Sum("BASE", nil, "DamageTakenFromAttacks", damageType.."DamageTakenFromAttacks")
		elseif damageCategoryConfig == "Average" then
			takenFlat = takenFlat + modDB:Sum("BASE", nil, "DamageTakenFromAttacks", damageType.."DamageTakenFromAttacks") / 2
		end
		if damageType == "Physical" or modDB:Flag(nil, "ArmourAppliesTo"..damageType.."DamageTaken") then
			local damage = output[damageType.."TakenDamage"]
			local armourReduct = 0
			local portionArmour = 100
			if damageType == "Physical" then
				if not modDB:Flag(nil, "ArmourDoesNotApplyToPhysicalDamageTaken") then
					armourReduct = calcs.armourReductionDouble(output.Armour, damage, doubleArmourChance)
					resist = m_min(output.DamageReductionMax, resist - enemyPen + armourReduct)
				end
				resist = m_max(resist, 0)
			else
				portionArmour = 100 - (resist - enemyPen)
				armourReduct = calcs.armourReductionDouble(output.Armour, damage * portionArmour / 100, doubleArmourChance)
				resist = resist + m_min(output.DamageReductionMax, armourReduct) * portionArmour / 100
			end
			output[damageType.."DamageReduction"] = damageType == "Physical" and resist or m_min(output.DamageReductionMax, armourReduct) * portionArmour / 100
			if breakdown then
				breakdown[damageType.."DamageReduction"] = {
					s_format("Enemy Hit Damage: %d ^8(%s the Configuration tab)", damage, env.configInput.enemyHit and "overridden from" or "can be overridden in"),
				}
				if portionArmour < 100 then
					t_insert(breakdown[damageType.."DamageReduction"], s_format("Portion mitigated by Armour: %d%%", portionArmour))
				end
				t_insert(breakdown[damageType.."DamageReduction"], s_format("Reduction from Armour: %d%%", armourReduct))
			end
		end
		local takenMult = output[damageType.."TakenHitMult"]
		output[damageType.."BaseTakenHitMult"] = (1 - resist / 100) * takenMult
		local takenMultReflect = output[damageType.."TakenReflect"]
		local finalReflect = (1 - (resist - enemyPen) / 100) * takenMultReflect
		output[damageType.."TakenHit"] = m_max(output[damageType.."TakenDamage"] * (1 - (resist - enemyPen) / 100) + takenFlat, 0) * takenMult
		output[damageType.."TakenHitMult"] = (output[damageType.."TakenDamage"] > 0) and (output[damageType.."TakenHit"] / output[damageType.."TakenDamage"]) or 0
		output["totalTakenHit"] = output["totalTakenHit"] + output[damageType.."TakenHit"]
		if output.AnyTakenReflect then
			output[damageType.."TakenReflectMult"] = finalReflect
		end
		if breakdown then
			breakdown[damageType.."TakenHitMult"] = {
				s_format("Resistance: %.2f", 1 - resist / 100),
			}
			if enemyPen > 0 then
				t_insert(breakdown[damageType.."TakenHitMult"], s_format("Enemy Pen: %.2f", enemyPen))
			end
			t_insert(breakdown[damageType.."TakenHitMult"], s_format("+ Flat: %.2f", takenFlat))
			t_insert(breakdown[damageType.."TakenHitMult"], s_format("x Taken: %.2f", takenMult))
			t_insert(breakdown[damageType.."TakenHitMult"], s_format("= %.2f", output[damageType.."TakenHitMult"]))
			breakdown[damageType.."TakenHit"] = {
				s_format("Final %s Damage taken:", damageType),
				s_format("%.1f incoming damage", output[damageType.."TakenDamage"]),
				s_format("x %.2f damage mult", output[damageType.."TakenHitMult"]),
				s_format("= %.1f", output[damageType.."TakenHit"]),
			}
			t_insert(breakdown["totalTakenHit"].rowList, {
				type = s_format("%s", damageType),
				incoming = s_format("%.1f incoming damage", output[damageType.."TakenDamage"]),
				mult = s_format("x %.2f damage mult", output[damageType.."TakenHitMult"] ),
				value = s_format("%d", output[damageType.."TakenHit"]),
			})
			if output.AnyTakenReflect then
				breakdown[damageType.."TakenReflectMult"] = {
					s_format("Resistance: %.2f", 1 - resist / 100),
				}
				if enemyPen > 0 then
					t_insert(breakdown[damageType.."TakenReflectMult"], s_format("Enemy Pen: %.2f", enemyPen))
				end
				t_insert(breakdown[damageType.."TakenReflectMult"], s_format("Taken: %.2f", takenMultReflect))
				t_insert(breakdown[damageType.."TakenReflectMult"], s_format("= %.2f", finalReflect))
			end
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

	-- Mind over Matter
	output.AnyMindOverMatter = false
	output["sharedMindOverMatter"] = m_min(modDB:Sum("BASE", nil, "DamageTakenFromManaBeforeLife"), 100)
	if output["sharedMindOverMatter"] > 0 then
		output.AnyMindOverMatter = true
		local sourcePool = m_max(output.ManaUnreserved or 0, 0)
		local manatext = "unreserved mana"
		if modDB:Flag(nil, "EnergyShieldProtectsMana") and output.MinimumBypass < 100 then
			manatext = manatext.." + non-bypassed energy shield"
			if output.MinimumBypass > 0 then
				local manaProtected = output.EnergyShield / (1 - output.MinimumBypass / 100) * (output.MinimumBypass / 100)
				sourcePool = m_max(sourcePool - manaProtected, 0) + m_min(sourcePool, manaProtected) / (output.MinimumBypass / 100)
			else 
				sourcePool = sourcePool + output.EnergyShield
			end
		end
		local poolProtected = sourcePool / (output["sharedMindOverMatter"] / 100) * (1 - output["sharedMindOverMatter"] / 100)
		if output["sharedMindOverMatter"] >= 100 then
			poolProtected = m_huge
			output["sharedManaEffectiveLife"] = output.LifeUnreserved + sourcePool
		else
			output["sharedManaEffectiveLife"] = m_max(output.LifeUnreserved - poolProtected, 0) + m_min(output.LifeUnreserved, poolProtected) / (1 - output["sharedMindOverMatter"] / 100)
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
		output["sharedManaEffectiveLife"] = output.LifeUnreserved
	end
	for _, damageType in ipairs(dmgTypeList) do
		output[damageType.."MindOverMatter"] = m_min(modDB:Sum("BASE", nil, damageType.."DamageTakenFromManaBeforeLife"), 100 - output["sharedMindOverMatter"])
		if output[damageType.."MindOverMatter"] > 0 or (output[damageType.."EnergyShieldBypass"] > output.MinimumBypass and output["sharedMindOverMatter"] > 0) then
			local MindOverMatter = output[damageType.."MindOverMatter"] + output["sharedMindOverMatter"]
			output.AnyMindOverMatter = true
			local sourcePool = m_max(output.ManaUnreserved or 0, 0)
			local manatext = "unreserved mana"
			if modDB:Flag(nil, "EnergyShieldProtectsMana") and output[damageType.."EnergyShieldBypass"] < 100 then
				manatext = manatext.." + non-bypassed energy shield"
				if output[damageType.."EnergyShieldBypass"] > 0 then
					local manaProtected = output.EnergyShield / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					sourcePool = m_max(sourcePool - manaProtected, 0) + m_min(sourcePool, manaProtected) / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					sourcePool = sourcePool + output.EnergyShield
				end
			end
			local poolProtected = sourcePool / (MindOverMatter / 100) * (1 - MindOverMatter / 100)
			if MindOverMatter >= 100 then
				poolProtected = m_huge
				output[damageType.."ManaEffectiveLife"] = output.LifeUnreserved + sourcePool
			else
				output[damageType.."ManaEffectiveLife"] = m_max(output.LifeUnreserved - poolProtected, 0) + m_min(output.LifeUnreserved, poolProtected) / (1 - MindOverMatter / 100)
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
	output["sharedAegis"] = modDB:Sum("BASE", nil, "AegisValue")
	output["sharedElementalAegis"] = modDB:Sum("BASE", nil, "ElementalAegisValue")
	if output["sharedAegis"] > 0 or output["sharedElementalAegis"] > 0 then
		output.AnyAegis = true
	end
	for _, damageType in ipairs(dmgTypeList) do
		local aegisValue = modDB:Sum("BASE", nil, damageType.."AegisValue")
		if aegisValue > 0 then
			output.AnyAegis = true
			output[damageType.."Aegis"] = aegisValue
		else
			output[damageType.."Aegis"] = 0
		end
		if isElemental[damageType] then
			output[damageType.."AegisDisplay"] = output[damageType.."Aegis"] + output["sharedElementalAegis"]
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
					local poolProtected = output.EnergyShield / (1 - output[damageType.."EnergyShieldBypass"] / 100) * (output[damageType.."EnergyShieldBypass"] / 100)
					output[damageType.."TotalPool"] = m_max(output[damageType.."TotalPool"] - poolProtected, 0) + m_min(output[damageType.."TotalPool"], poolProtected) / (output[damageType.."EnergyShieldBypass"] / 100)
				else 
					output[damageType.."TotalPool"] = output[damageType.."TotalPool"] + output.EnergyShield
				end
			end
		end
		if breakdown then
			breakdown[damageType.."TotalPool"] = {
				s_format("Life: %d", output.LifeUnreserved)
			}
			if output[damageType.."ManaEffectiveLife"] ~= output.LifeUnreserved then
				t_insert(breakdown[damageType.."TotalPool"], s_format("%s through MoM: %d", manatext, output[damageType.."ManaEffectiveLife"] - output.LifeUnreserved))
			end
			if (not modDB:Flag(nil, "EnergyShieldProtectsMana")) and output[damageType.."EnergyShieldBypass"] < 100 then
				t_insert(breakdown[damageType.."TotalPool"], s_format("Non-bypassed Energy Shield: %d", output[damageType.."TotalPool"] - output[damageType.."ManaEffectiveLife"]))
			end
			t_insert(breakdown[damageType.."TotalPool"], s_format("TotalPool: %d", output[damageType.."TotalPool"]))
		end
	end
	
	-- helper function that itterativly reduces pools untill life hits 0 to determine the number of hits it would take with given damage to die
	function numberOfHitsToDie(DamageIn)
		local numHits = 0
		
		--check damage in isnt 0
		for _, damageType in ipairs(dmgTypeList) do
			numHits = numHits + DamageIn[damageType]
		end
		if numHits == 0 then
			return m_huge
		else
			numHits = 0
		end
		
		local life = output.LifeUnreserved or 0
		local mana = output.ManaUnreserved or 0
		local energyShield = output.EnergyShield or 0
		local aegis = {}
		aegis["shared"] = output["sharedAegis"] or 0
		aegis["sharedElemental"] = output["sharedElementalAegis"] or 0
		local guard = {}
		guard["shared"] = output.sharedGuardAbsorb or 0
		for _, damageType in ipairs(dmgTypeList) do
			aegis[damageType] = output[damageType.."Aegis"] or 0
			guard[damageType] = output[damageType.."GuardAbsorb"] or 0
			if not DamageIn[damageType.."EnergyShieldBypass"] then
				DamageIn[damageType.."EnergyShieldBypass"] = output[damageType.."EnergyShieldBypass"]
			end
		end
		
		local itterationMultiplier = 1
		local maxHits = 10000 --arbitrary number needs to be moved to data.misc
		maxHits = maxHits / ((DamageIn["c"] or 0) + 1)
		while life > 0 and numHits < maxHits do
			numHits = numHits + itterationMultiplier
			local Damage = {}
			for _, damageType in ipairs(dmgTypeList) do
				Damage[damageType] = DamageIn[damageType] * itterationMultiplier
			end
			for _, damageType in ipairs(dmgTypeList) do
				if Damage[damageType] > 0 then
					--frost sheild goes here in this order when implemented
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
						local tempDamage = m_min(Damage[damageType] * output[damageType.."GuardAbsorbRate"] / 100, guard[damageType])
						guard[damageType] = guard[damageType] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if guard["shared"] > 0 then
						local tempDamage = m_min(Damage[damageType] * output["sharedGuardAbsorbRate"] / 100, guard["shared"])
						guard["shared"] = guard["shared"] - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if energyShield > 0 and (not modDB:Flag(nil, "EnergyShieldProtectsMana")) and DamageIn[damageType.."EnergyShieldBypass"] < 100 then
						local tempDamage = m_min(Damage[damageType] * (1 - DamageIn[damageType.."EnergyShieldBypass"] / 100), energyShield)
						energyShield = energyShield - tempDamage
						Damage[damageType] = Damage[damageType] - tempDamage
					end
					if output.sharedMindOverMatter > 0 then
						local MoMDamage = Damage[damageType] * output.sharedMindOverMatter / 100
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
					life = life - Damage[damageType]
				end
			end
			if DamageIn.GainWhenHit and life > 0 then
				life = m_min(life + DamageIn.LifeWhenHit * itterationMultiplier, output.LifeUnreserved or 0)
				mana = m_min(mana + DamageIn.ManaWhenHit * itterationMultiplier, output.ManaUnreserved or 0)
				energyShield = m_min(energyShield + DamageIn.EnergyShieldWhenHit * itterationMultiplier, output.EnergyShield or 0)
			end
			--this is to speed this up
			itterationMultiplier = 1
			DamageIn["c"] = DamageIn["c"] or 0
			local maxdepth = 4 --move to data.misc
			local speedUp = 5 --move to data.misc
			if life > 0 and DamageIn["c"] < maxdepth then
				Damage = {}
				for _, damageType in ipairs(dmgTypeList) do
					Damage[damageType] = DamageIn[damageType] * speedUp
				end	
				Damage.LifeWhenHit = DamageIn.LifeWhenHit or 0 * speedUp
				Damage.ManaWhenHite = DamageIn.ManaWhenHit or 0 * speedUp
				Damage.EnergyShieldWhenHit = DamageIn.EnergyShieldWhenHit or 0 * speedUp
				Damage["c"] = DamageIn["c"] + 1
				itterationMultiplier = m_max((numberOfHitsToDie(Damage) - 1) * speedUp - 1, 1)
				DamageIn["c"] = maxdepth --only run once
			end
		end
		return numHits
	end
	
	--number of damaging hits needed to be taken to die
	do
		local DamageIn = {}
		for _, damageType in ipairs(dmgTypeList) do
			DamageIn[damageType] = output[damageType.."TakenHit"]
		end
		output["NumberOfDamagingHits"] = numberOfHitsToDie(DamageIn)
	end
	
	--chance to take reduced damage if hit and number of hits needed to be taken to die becouse of it
	do --fix this to not just be average, have config for: average, worst of 2 rolls (unlucky), worst of 4 rolls (Very unlucky)
		local DamageIn = {}
		local BlockChance = 0
		local blockEffect = 1
		local ExtraAvoidChance = 0
		local averageAvoidChance = 0
		local worstOf = env.configInput.EHPUnluckyWorstOf or 1
		--block effect
		if damageCategoryConfig == "Melee" then
			BlockChance = output.BlockChance / 100
		else
			BlockChance = output[damageCategoryConfig.."BlockChance"] / 100
		end
		--unlucky config to lower the value of block, dodge, evade etc for ehp
		if worstOf > 1 then
			BlockChance = BlockChance * BlockChance
			if worstOf == 4 then
				BlockChance = BlockChance * BlockChance
			end
		end
		blockEffect = (1 - BlockChance * output.BlockEffect / 100)
		DamageIn.LifeWhenHit = output.LifeOnBlock * BlockChance
		DamageIn.ManaWhenHit = output.ManaOnBlock * BlockChance
		DamageIn.EnergyShieldWhenHit = output.EnergyShieldOnBlock * BlockChance
		--extra avoid chance
		if damageCategoryConfig == "Projectile" or damageCategoryConfig == "SpellProjectile" then
			ExtraAvoidChance = ExtraAvoidChance + output.AvoidProjectilesChance
		elseif damageCategoryConfig == "Average" then
			ExtraAvoidChance = ExtraAvoidChance + output.AvoidProjectilesChance / 2
		end
		--gain when hit (currently just gain on block)
		if DamageIn.LifeWhenHit ~= 0 or DamageIn.ManaWhenHit ~= 0 or DamageIn.EnergyShieldWhenHit ~= 0 then
			DamageIn.GainWhenHit = true
		end
		for _, damageType in ipairs(dmgTypeList) do
			if modDB:Flag(nil, "BlockedDamageDoesntBypassES") then -- this needs to fail with divine flesh as it cant override it
				DamageIn[damageType.."EnergyShieldBypass"] = output[damageType.."EnergyShieldBypass"] * (1 - BlockChance) 
			end
			local AvoidChance = m_min(output["Avoid"..damageType.."DamageChance"] + ExtraAvoidChance, data.misc.AvoidChanceCap)
			--unlucky config to lower the value of block, dodge, evade etc for ehp
			if worstOf > 1 then
				AvoidChance = AvoidChance / 100 * AvoidChance
				if worstOf == 4 then
					AvoidChance = AvoidChance / 100 * AvoidChance
				end
			end
			averageAvoidChance = averageAvoidChance + AvoidChance
			DamageIn[damageType] = output[damageType.."TakenHit"] * (blockEffect * (1 - AvoidChance / 100))
		end
		output["NumberOfMitigatedDamagingHits"] = numberOfHitsToDie(DamageIn)
		averageAvoidChance = averageAvoidChance / 5
		output["ConfiguredDamageChance"] = 100 * (blockEffect * (1 - averageAvoidChance / 100))
		if breakdown then
			breakdown["ConfiguredDamageChance"] = {
				s_format("%.2f ^8(chance for block to fail)", 1 - BlockChance)
			}	
			if output.ShowBlockEffect then
				t_insert(breakdown["ConfiguredDamageChance"], s_format("x %.2f ^8(block effect)", output.BlockEffect / 100))
			end
			if averageAvoidChance > 0 then
				t_insert(breakdown["ConfiguredDamageChance"], s_format("x %.2f ^8(chance for avoidance to fail)", 1 - averageAvoidChance / 100))
			end
			t_insert(breakdown["ConfiguredDamageChance"], s_format("= %d%% ^8(chance to take damage from a%s hit)", output["ConfiguredDamageChance"], (damageCategoryConfig == "Average" and "n " or " ")..damageCategoryConfig))
		end
	end
	
	--chance to not be hit
	do
		local worstOf = env.configInput.EHPUnluckyWorstOf or 1
		output.MeleeNotHitChance = 100 - (1 - output.MeleeEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * 100
		output.ProjectileNotHitChance = 100 - (1 - output.ProjectileEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * 100
		output.SpellNotHitChance = 100 - (1 - output.SpellDodgeChance / 100) * 100
		output.SpellProjectileNotHitChance = output.SpellNotHitChance
		output.AverageNotHitChance = (output.MeleeNotHitChance + output.ProjectileNotHitChance + output.SpellNotHitChance + output.SpellProjectileNotHitChance) / 4
		output.ConfiguredNotHitChance = output[damageCategoryConfig.."NotHitChance"]
		--unlucky config to lower the value of block, dodge, evade etc for ehp
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
	
	--effective hit pool
	output["TotalEHP"] = output["TotalNumberOfHits"] * output["totalEnemyDamageIn"]
	if breakdown then
		breakdown["TotalEHP"] = {
			s_format("%.2f ^8(total average number of hits you can take)", output["TotalNumberOfHits"]),
			s_format("x %d ^8(total incomming damage)", output["totalEnemyDamageIn"]),
			s_format("= %d ^8(total damage you can take)", output["TotalEHP"]),
		}
	end
	
	--survival time
	do
		local enemySkillTime = env.configInput.enemySpeed or 700 --should be modifed by enemy speed eg temp chains/chill
		enemySkillTime = enemySkillTime / 1000
		output["EHPsurvivalTime"] = output["TotalNumberOfHits"] * enemySkillTime
		if breakdown then
			breakdown["EHPsurvivalTime"] = {
				s_format("%.2f ^8(total average number of hits you can take)", output["TotalNumberOfHits"]),
				s_format("x %.2f ^8enemy attack/cast time", enemySkillTime),
				s_format("= %.2f seconds ^8(total time it would take to die)", output["EHPsurvivalTime"]),
			}
		end
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
	
	-- Degens
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

	--maximum hit taken
	-- this is not done yet, using old max hit taken
	--fix total pools, as they arnt used anymore
	for _, damageType in ipairs(dmgTypeList) do
		--base + aegis
		output[damageType.."TotalHitPool"] = output[damageType.."TotalPool"] + output[damageType.."Aegis"] or 0 + output[damageType.."sharedAegis"] or 0 + isElemental[damageType] and output[damageType.."sharedElementalAegis"] or 0
		--guardskill
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
			 t_insert(breakdown[damageType.."MaximumHitTaken"], s_format("Taken Mult: %.2f",  output[damageType.."TotalHitPool"] / output[damageType.."MaximumHitTaken"]))
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
