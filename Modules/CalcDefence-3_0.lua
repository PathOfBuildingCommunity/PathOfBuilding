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

-- Performs all defensive calculations
function calcs.defence(env, actor)
	local modDB = actor.modDB
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local breakdown = actor.breakdown

	local condList = modDB.conditions

	-- Resistances
	output.PhysicalResist = m_min(90, modDB:Sum("BASE", nil, "PhysicalDamageReduction"))
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
			output.MeleeEvadeChance = 0
			output.ProjectileEvadeChance = 0
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
			output.MeleeEvadeChance = m_max(5, m_min(95, output.EvadeChance * calcLib.mod(modDB, nil, "EvadeChance", "MeleeEvadeChance")))
			output.ProjectileEvadeChance = m_max(5, m_min(95, output.EvadeChance * calcLib.mod(modDB, nil, "EvadeChance", "ProjectileEvadeChance")))
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

	-- Mana, life and energy shield regen
	if modDB:Sum("FLAG", nil, "NoManaRegen") then
		output.ManaRegen = 0
	else
		output.ManaRegen = round((modDB:Sum("BASE", nil, "ManaRegen") + output.Mana * modDB:Sum("BASE", nil, "ManaRegenPercent") / 100) * calcLib.mod(modDB, nil, "ManaRegen", "ManaRecovery"), 1)
		if breakdown then
			breakdown.ManaRegen = breakdown.simple(nil, nil, output.ManaRegen, "ManaRegen", "ManaRecovery")
		end
	end
	output.TotalRegen = 0
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
			output.TotalRegen = output.TotalRegen + output.LifeRegen
		else
			output.LifeRegen = 0
		end
	end
	if modDB:Sum("FLAG", nil, "NoEnergyShieldRegen") then
		output.EnergyShieldRegen = 0
	else
		local esBase = modDB:Sum("BASE", nil, "EnergyShieldRegen")
		local esPercent = modDB:Sum("BASE", nil, "EnergyShieldRegenPercent")
		if esPercent > 0 then
			esBase = esBase + output.EnergyShield * esPercent / 100
		end
		if esBase > 0 then
			output.EnergyShieldRegen = esBase * calcLib.mod(modDB, nil, "EnergyShieldRecovery")
			output.EnergyShieldRegenPercent = round(output.EnergyShieldRegen / output.EnergyShield * 100, 1)
			if not modDB:Sum("FLAG", nil, "EnergyShieldProtectsMana") then
				output.TotalRegen = output.TotalRegen + output.EnergyShieldRegen
			end
		else
			output.EnergyShieldRegen = 0
		end
	end

	-- Mind over Matter
	output.MindOverMatter = modDB:Sum("BASE", nil, "DamageTakenFromManaBeforeLife")
	if output.MindOverMatter and breakdown then
		local sourcePool = output.ManaUnreserved or 0
		if modDB:Sum("FLAG", nil, "EnergyShieldProtectsMana") then
			sourcePool = sourcePool + output.EnergyShield
		end
		local lifeProtected = sourcePool / (output.MindOverMatter / 100) * (1 - output.MindOverMatter / 100)
		local effectiveLife = m_max(output.Life - lifeProtected, 0) + m_min(output.Life, lifeProtected) / (1 - output.MindOverMatter / 100)
		breakdown.MindOverMatter = {
			s_format("Total life protected:"),
			s_format("%d ^8(unreserved mana%s)", sourcePool, modDB:Sum("FLAG", nil, "EnergyShieldProtectsMana") and " + total energy shield" or ""),
			s_format("/ %.2f ^8(portion taken from mana)", output.MindOverMatter / 100),
			s_format("x %.2f ^8(portion taken from life)", 1 - output.MindOverMatter / 100),
			s_format("= %d", lifeProtected),
			s_format("Effective life: %d", effectiveLife)
		}
	end

	-- Damage taken multipliers/Degen calculations
	for _, damageType in ipairs(dmgTypeList) do
		local baseTakenInc = modDB:Sum("INC", nil, "DamageTaken", damageType.."DamageTaken")
		local baseTakenMore = modDB:Sum("MORE", nil, "DamageTaken", damageType.."DamageTaken")
		if isElemental[damageType] then
			baseTakenInc = baseTakenInc + modDB:Sum("INC", nil, "ElementalDamageTaken")
			baseTakenMore = baseTakenMore * modDB:Sum("MORE", nil, "ElementalDamageTaken")
		end
		do
			-- Hit
			local takenInc = baseTakenInc + modDB:Sum("INC", nil, "DamageTakenWhenHit")
			local takenMore = baseTakenMore * modDB:Sum("MORE", nil, "DamageTakenWhenHit")
			output[damageType.."TakenHit"] = (1 + takenInc / 100) * takenMore
		end
		do
			-- Dot
			local takenInc = baseTakenInc + modDB:Sum("INC", nil, "DamageTakenOverTime", damageType.."DamageTakenOverTime")
			local takenMore = baseTakenMore * modDB:Sum("MORE", nil, "DamageTakenOverTime", damageType.."DamageTakenOverTime")
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
				end
			end
		end
	end
	if output.TotalDegen then
		output.TotalLifeDegen = output.TotalDegen * (1 - output.MindOverMatter / 100)
		output.TotalManaDegen = output.TotalDegen * output.MindOverMatter / 100
		if output.TotalRegen > 0 or output.MindOverMatter > 0 then
			output.NetLifeRegen = output.TotalRegen - output.TotalLifeDegen
			if breakdown then
				breakdown.NetLifeRegen = {
					s_format("%.1f ^8(total life%s regen)", output.TotalRegen, modDB:Sum("FLAG", nil, "EnergyShieldProtectsMana") and "" or " + energy shield"),	
					s_format("- %.1f ^8(total life degen)", output.TotalLifeDegen),
					s_format("= %.1f", output.NetLifeRegen),
				}
			end
		end
		if output.TotalManaDegen > 0 and output.ManaRegen > 0 then
			output.NetManaRegen = output.ManaRegen - output.TotalManaDegen
			if breakdown then
				breakdown.NetManaRegen = {
					s_format("%.1f ^8(total mana regen)", output.ManaRegen),
					s_format("- %.1f ^8(total mana degen)", output.TotalManaDegen),
					s_format("= %.1f", output.NetManaRegen),
				}
			end
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
		if breakdown then
			breakdown[damageType.."TakenHitMult"] = { 
				label = "Hit Damage taken as",
				rowList = { },
				colList = {
					{ label = "Type", key = "type" },
					{ label = "Migitation", key = "resist" },
					{ label = "Taken", key = "taken" },
					{ label = "Final", key = "final" },
				},
			}
		end
		for _, destType in ipairs(dmgTypeList) do
			local portion = shiftTable[destType]
			if portion > 0 then
				local resist = output[destType.."Resist"]
				if damageType == "Physical" and destType == "Physical" then
					-- Factor in armour for Physical taken as Physical
					local damage = env.configInput.enemyPhysicalHit or env.data.monsterDamageTable[env.enemyLevel] * 1.5
					local armourReduct = calcLib.armourReduction(output.Armour, damage * portion / 100)
					resist = m_min(90, resist + armourReduct)
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
				local final = portion / 100 * (1 - resist / 100) * takenMult
				mult = mult + final
				if breakdown then
					t_insert(breakdown[damageType.."TakenHitMult"].rowList, {
						type = s_format("%d%% as %s", portion, destType),
						resist = s_format("x %.2f", 1 - resist / 100),
						taken = takenMult ~= 1 and s_format("x %.2f", takenMult),
						final = s_format("x %.2f", final),
					})
				end
			end
		end
		output[damageType.."TakenHitMult"] = mult
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
		if env.mode_effective and modDB:Sum("FLAG", nil, "DodgeChanceIsUnlucky") then
			output.AttackDodgeChance = output.AttackDodgeChance / 100 * output.AttackDodgeChance
			output.SpellDodgeChance = output.SpellDodgeChance / 100 * output.SpellDodgeChance
		end
		output.MeleeAvoidChance = 100 - (1 - output.MeleeEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * (1 - output.BlockChance / 100) * 100
		output.ProjectileAvoidChance = 100 - (1 - output.ProjectileEvadeChance / 100) * (1 - output.AttackDodgeChance / 100) * (1 - output.BlockChance / 100) * 100
		output.SpellAvoidChance = 100 - (1 - output.SpellDodgeChance / 100) * (1 - output.SpellBlockChance / 100) * 100
		if breakdown then
			breakdown.MeleeAvoidChance = { }
			breakdown.multiChain(breakdown.MeleeAvoidChance, {
				{ "%.2f ^8(chance for evasion to fail)", 1 - output.MeleeEvadeChance / 100 },
				{ "%.2f ^8(chance for dodge to fail)", 1 - output.AttackDodgeChance / 100 },
				{ "%.2f ^8(chance for block to fail)", 1 - output.BlockChance / 100 },
				total = s_format("= %d%% ^8(chance to be hit by a melee attack)", 100 - output.MeleeAvoidChance),
			})
			breakdown.ProjectileAvoidChance = { }
			breakdown.multiChain(breakdown.ProjectileAvoidChance, {
				{ "%.2f ^8(chance for evasion to fail)", 1 - output.ProjectileEvadeChance / 100 },
				{ "%.2f ^8(chance for dodge to fail)", 1 - output.AttackDodgeChance / 100 },
				{ "%.2f ^8(chance for block to fail)", 1 - output.BlockChance / 100 },
				total = s_format("= %d%% ^8(chance to be hit by a projectile attack)", 100 - output.ProjectileAvoidChance),
			})
			breakdown.SpellAvoidChance = { }
			breakdown.multiChain(breakdown.SpellAvoidChance, {
				{ "%.2f ^8(chance for dodge to fail)", 1 - output.SpellDodgeChance / 100 },
				{ "%.2f ^8(chance for block to fail)", 1 - output.SpellBlockChance / 100 },
				total = s_format("= %d%% ^8(chance to be hit by a spell)", 100 - output.SpellAvoidChance),
			})
		end
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