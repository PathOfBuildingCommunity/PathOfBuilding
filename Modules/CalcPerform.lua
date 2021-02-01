-- Path of Building
--
-- Module: Calc Perform
-- Manages the offence/defence calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil
local m_floor = math.floor
local m_modf = math.modf
local s_format = string.format

local tempTable1 = { }

-- Merge an instance of a buff, taking the highest value of each modifier
local function mergeBuff(src, destTable, destKey)
	if not destTable[destKey] then
		destTable[destKey] = new("ModList")
	end
	local dest = destTable[destKey]
	for _, mod in ipairs(src) do
		local match = false
		if mod.type ~= "LIST" then
			for index, destMod in ipairs(dest) do
				if modLib.compareModParams(mod, destMod) then
					if type(destMod.value) == "number" and mod.value > destMod.value then
						dest[index] = mod
					end
					match = true
					break
				end
			end
		end
		if not match then
			t_insert(dest, mod)
		end
	end
end

-- Merge keystone modifiers
local function mergeKeystones(env)
	local modDB = env.modDB

	for _, name in ipairs(modDB:List(nil, "Keystone")) do
		if not env.keystonesAdded[name] and env.spec.tree.keystoneMap[name] then
			env.keystonesAdded[name] = true
			modDB:AddList(env.spec.tree.keystoneMap[name].modList)
		end
	end
end

-- Calculate attributes and life/mana pools, and set conditions
---@param env table
---@param actor table
local function doActorAttribsPoolsConditions(env, actor)
	local modDB = actor.modDB
	local output = actor.output
	local breakdown = actor.breakdown
	local condList = modDB.conditions

	-- Set conditions
	if (actor.itemList["Weapon 2"] and actor.itemList["Weapon 2"].type == "Shield") or (actor == env.player and env.aegisModList) then
		condList["UsingShield"] = true
	end
	if not actor.itemList["Weapon 2"] then
		condList["OffHandIsEmpty"] = true
	end
	if actor.weaponData1.type == "None" then
		condList["Unarmed"] = true
		if not actor.itemList["Weapon 2"] and not actor.itemList["Gloves"] then
			condList["Unencumbered"] = true
		end
	else
		local info = env.data.weaponTypeInfo[actor.weaponData1.type]
		condList["Using"..info.flag] = true
		if actor.weaponData1.countsAsAll1H then
			condList["UsingAxe"] = true
			condList["UsingSword"] = true
			condList["UsingDagger"] = true
			condList["UsingMace"] = true
			condList["UsingClaw"] = true
			-- GGG stated that a single Varunastra satisfied requirement for wielding two different weapons
			condList["WieldingDifferentWeaponTypes"] = true
		end
		if info.melee then
			condList["UsingMeleeWeapon"] = true
		end
		if info.oneHand then
			condList["UsingOneHandedWeapon"] = true
		else
			condList["UsingTwoHandedWeapon"] = true
		end
	end
	if actor.weaponData2.type then
		local info = env.data.weaponTypeInfo[actor.weaponData2.type]
		condList["Using"..info.flag] = true
		if actor.weaponData2.countsAsAll1H then
			condList["UsingAxe"] = true
			condList["UsingSword"] = true
			condList["UsingDagger"] = true
			condList["UsingMace"] = true
			condList["UsingClaw"] = true
			-- GGG stated that a single Varunastra satisfied requirement for wielding two different weapons
			condList["WieldingDifferentWeaponTypes"] = true
		end
		if info.melee then
			condList["UsingMeleeWeapon"] = true
		end
		if info.oneHand then
			condList["UsingOneHandedWeapon"] = true
		else
			condList["UsingTwoHandedWeapon"] = true
		end
	end
	if actor.weaponData1.type and actor.weaponData2.type then
		condList["DualWielding"] = true
		if (actor.weaponData1.type == "Claw" or actor.weaponData1.countsAsAll1H) and (actor.weaponData2.type == "Claw" or actor.weaponData2.countsAsAll1H) then
			condList["DualWieldingClaws"] = true
		end
		if actor.weaponData1.type ~= actor.weaponData2.type then
			local info1 = env.data.weaponTypeInfo[actor.weaponData1.type]
			local info2 = env.data.weaponTypeInfo[actor.weaponData2.type]
			if info1.oneHand and info2.oneHand then
				condList["WieldingDifferentWeaponTypes"] = true
			end
		end
	end
	if env.mode_combat then		
		if not modDB:Flag(nil, "NeverCrit") then
			condList["CritInPast8Sec"] = true
		end
		if not actor.mainSkill.skillData.triggered and not actor.mainSkill.skillFlags.trap and not actor.mainSkill.skillFlags.mine and not actor.mainSkill.skillFlags.totem then 
			if actor.mainSkill.skillFlags.attack then
				condList["AttackedRecently"] = true
			elseif actor.mainSkill.skillFlags.spell then
				condList["CastSpellRecently"] = true
			end
			if actor.mainSkill.skillTypes[SkillType.MovementSkill] then
				condList["UsedMovementSkillRecently"] = true
			end
			if actor.mainSkill.skillFlags.minion then
				condList["UsedMinionSkillRecently"] = true
			end
			if actor.mainSkill.skillTypes[SkillType.Vaal] then
				condList["UsedVaalSkillRecently"] = true
			end
			if actor.mainSkill.skillTypes[SkillType.Channelled] then
				condList["Channelling"] = true
			end
		end
		if actor.mainSkill.skillFlags.hit and not actor.mainSkill.skillFlags.trap and not actor.mainSkill.skillFlags.mine and not actor.mainSkill.skillFlags.totem then
			condList["HitRecently"] = true
		end
		if actor.mainSkill.skillFlags.totem then
			condList["HaveTotem"] = true
			condList["SummonedTotemRecently"] = true
		end
		if actor.mainSkill.skillFlags.mine then
			condList["DetonatedMinesRecently"] = true
		end
		if modDB:Sum("BASE", nil, "ScorchChance") > 0 or modDB:Flag(nil, "CritAlwaysAltAilments") and not modDB:Flag(nil, "NeverCrit") then
			condList["CanInflictScorch"] = true
		end
		if modDB:Sum("BASE", nil, "BrittleChance") > 0 or modDB:Flag(nil, "CritAlwaysAltAilments") and not modDB:Flag(nil, "NeverCrit") then
			condList["CanInflictBrittle"] = true
		end
		if modDB:Sum("BASE", nil, "SapChance") > 0 or modDB:Flag(nil, "CritAlwaysAltAilments") and not modDB:Flag(nil, "NeverCrit") then
			condList["CanInflictSap"] = true
		end
	end
	if env.mode_effective then
		if modDB:Sum("BASE", nil, "FireExposureChance") > 0 then
			condList["CanApplyFireExposure"] = true
		end
		if modDB:Sum("BASE", nil, "ColdExposureChance") > 0 then
			condList["CanApplyColdExposure"] = true
		end
		if modDB:Sum("BASE", nil, "LightningExposureChance") > 0 then
			condList["CanApplyLightningExposure"] = true
		end
	end

	-- Calculate attributes
	local calculateAttributes = function()
		for _, stat in pairs({"Str","Dex","Int"}) do
			output[stat] = m_max(round(calcLib.val(modDB, stat)), 0)
			if breakdown then
				breakdown[stat] = breakdown.simple(nil, nil, output[stat], stat)
			end
		end
		
		output.LowestAttribute = m_min(output.Str, output.Dex, output.Int)
		condList["DexHigherThanInt"] = output.Dex > output.Int
		condList["StrHigherThanDex"] = output.Str > output.Dex
		condList["IntHigherThanStr"] = output.Int > output.Str
		condList["StrHigherThanInt"] = output.Str > output.Int
	end
	
	-- Calculate twice because of circular dependency
	calculateAttributes()
	calculateAttributes()

	-- Calculate total attributes
	output.TotalAttr = output.Str + output.Dex + output.Int

	-- Special case for Devotion
	output.Devotion = modDB:Sum("BASE", nil, "Devotion")

	-- Add attribute bonuses
	if not modDB:Flag(nil, "NoAttributeBonuses") then
		if not modDB:Flag(nil, "NoStrBonusToLife") then
			modDB:NewMod("Life", "BASE", m_floor(output.Str / 2), "Strength")
		end
		local strDmgBonusRatioOverride = modDB:Sum("BASE", nil, "StrDmgBonusRatioOverride")
		if strDmgBonusRatioOverride > 0 then
			actor.strDmgBonus = round((output.Str + modDB:Sum("BASE", nil, "DexIntToMeleeBonus")) * strDmgBonusRatioOverride)
		else
			actor.strDmgBonus = round((output.Str + modDB:Sum("BASE", nil, "DexIntToMeleeBonus")) / 5)
		end
		modDB:NewMod("PhysicalDamage", "INC", actor.strDmgBonus, "Strength", ModFlag.Melee)
		modDB:NewMod("Accuracy", "BASE", output.Dex * 2, "Dexterity")
		if not modDB:Flag(nil, "IronReflexes") then
			modDB:NewMod("Evasion", "INC", round(output.Dex / 5), "Dexterity")
		end
		if not modDB:Flag(nil, "NoIntBonusToMana") then
			modDB:NewMod("Mana", "BASE", round(output.Int / 2), "Intelligence")
		end
		modDB:NewMod("EnergyShield", "INC", round(output.Int / 5), "Intelligence")
	end

	-- Life/mana pools
	if modDB:Flag(nil, "ChaosInoculation") then
		output.Life = 1
		condList["FullLife"] = true
	else
		local base = modDB:Sum("BASE", nil, "Life")
		local inc = modDB:Sum("INC", nil, "Life")
		local more = modDB:More(nil, "Life")
		local conv = modDB:Sum("BASE", nil, "LifeConvertToEnergyShield")
		output.Life = round(base * (1 + inc/100) * more * (1 - conv/100))
		if breakdown then
			if inc ~= 0 or more ~= 1 or conv ~= 0 then
				breakdown.Life = { }
				breakdown.Life[1] = s_format("%g ^8(base)", base)
				if inc ~= 0 then
					t_insert(breakdown.Life, s_format("x %.2f ^8(increased/reduced)", 1 + inc/100))
				end
				if more ~= 1 then
					t_insert(breakdown.Life, s_format("x %.2f ^8(more/less)", more))
				end
				if conv ~= 0 then
					t_insert(breakdown.Life, s_format("x %.2f ^8(converted to Energy Shield)", 1 - conv/100))
				end
				t_insert(breakdown.Life, s_format("= %g", output.Life))
			end
		end
	end
	local manaConv = modDB:Sum("BASE", nil, "ManaConvertToArmour")
	output.Mana = round(calcLib.val(modDB, "Mana") * (1 - manaConv / 100))
	local base = modDB:Sum("BASE", nil, "Mana")
	local inc = modDB:Sum("INC", nil, "Mana")
	local more = modDB:More(nil, "Mana")
	if breakdown then
		if inc ~= 0 or more ~= 1 or manaConv ~= 0 then
			breakdown.Mana = { }
			breakdown.Mana[1] = s_format("%g ^8(base)", base)
			if inc ~= 0 then
				t_insert(breakdown.Mana, s_format("x %.2f ^8(increased/reduced)", 1 + inc/100))
			end
			if more ~= 1 then
				t_insert(breakdown.Mana, s_format("x %.2f ^8(more/less)", more))
			end
			if manaConv ~= 0 then
				t_insert(breakdown.Mana, s_format("x %.2f ^8(converted to Armour)", 1 - manaConv/100))
			end
			t_insert(breakdown.Mana, s_format("= %g", output.Mana))
		end
	end
end

-- Calculate life/mana reservation
---@param actor table
local function doActorLifeManaReservation(actor)
	local modDB = actor.modDB
	local output = actor.output
	local condList = modDB.conditions

	for _, pool in pairs({"Life", "Mana"}) do
		local max = output[pool]
		local reserved
		if max > 0 then
			reserved = (actor["reserved_"..pool.."Base"] or 0) + m_ceil(max * (actor["reserved_"..pool.."Percent"] or 0) / 100)
			output[pool.."Reserved"] = m_min(reserved, max)
			output[pool.."ReservedPercent"] = m_min(reserved / max * 100, 100)
			output[pool.."Unreserved"] = max - reserved
			output[pool.."UnreservedPercent"] = (max - reserved) / max * 100
			if (max - reserved) / max <= 0.35 then
				condList["Low"..pool] = true
			end
		else
			reserved = 0
		end
		for _, value in ipairs(modDB:List(nil, "GrantReserved"..pool.."AsAura")) do
			local auraMod = copyTable(value.mod)
			auraMod.value = m_floor(auraMod.value * m_min(reserved, max))
			modDB:NewMod("ExtraAura", "LIST", { mod = auraMod })
		end
	end
end

-- Process charges, enemy modifiers, and other buffs
local function doActorMisc(env, actor)
	local modDB = actor.modDB
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local condList = modDB.conditions

	-- Calculate current and maximum charges
	output.PowerChargesMin = modDB:Sum("BASE", nil, "PowerChargesMin")
	output.PowerChargesMax = modDB:Sum("BASE", nil, "PowerChargesMax")
	output.FrenzyChargesMin = modDB:Sum("BASE", nil, "FrenzyChargesMin")
	output.FrenzyChargesMax = modDB:Flag(nil, "MaximumFrenzyChargesIsMaximumPowerCharges") and output.PowerChargesMax or modDB:Sum("BASE", nil, "FrenzyChargesMax")
	output.EnduranceChargesMin = modDB:Sum("BASE", nil, "EnduranceChargesMin")
	output.EnduranceChargesMax = modDB:Flag(nil, "MaximumEnduranceChargesIsMaximumFrenzyCharges") and output.FrenzyChargesMax or modDB:Sum("BASE", nil, "EnduranceChargesMax")
	output.SiphoningChargesMax = modDB:Sum("BASE", nil, "SiphoningChargesMax")
	output.ChallengerChargesMax = modDB:Sum("BASE", nil, "ChallengerChargesMax")
	output.BlitzChargesMax = modDB:Sum("BASE", nil, "BlitzChargesMax")
	output.InspirationChargesMax = modDB:Sum("BASE", nil, "InspirationChargesMax")
	output.CrabBarriersMax = modDB:Sum("BASE", nil, "CrabBarriersMax")
	output.BrutalChargesMin = modDB:Flag(nil, "MinimumEnduranceChargesEqualsMinimumBrutalCharges") and output.EnduranceChargesMin or 0
	output.BrutalChargesMax = modDB:Flag(nil, "MaximumEnduranceChargesEqualsMaximumBrutalCharges") and output.EnduranceChargesMax or 0
	output.AbsorptionChargesMin = modDB:Flag(nil, "MinimumPowerChargesEqualsMinimumAbsorptionCharges") and output.PowerChargesMin or 0
	output.AbsorptionChargesMax = modDB:Flag(nil, "MaximumPowerChargesEqualsMaximumAbsorptionCharges") and output.PowerChargesMax or 0
	output.AfflictionChargesMin = modDB:Flag(nil, "MinimumFrenzyChargesEqualsMinimumAfflictionCharges") and output.FrenzyChargesMin or 0
	output.AfflictionChargesMax = modDB:Flag(nil, "MaximumFrenzyChargesEqualsMaximumAfflictionCharges") and output.FrenzyChargesMax or 0

	-- Initialize Charges
	output.PowerCharges = 0
	output.FrenzyCharges = 0
	output.EnduranceCharges = 0
	output.SiphoningCharges = 0
	output.ChallengerCharges = 0
	output.BlitzCharges = 0
	output.InspirationCharges = 0
	output.GhostShrouds = 0
	output.BrutalCharges = 0
	output.AbsorptionCharges = 0
	output.AfflictionCharges = 0

	-- Conditionally over-write Charge values
	if modDB:Flag(nil, "UsePowerCharges") then
		output.PowerCharges = modDB:Override(nil, "PowerCharges") or output.PowerChargesMax
		if modDB:Flag(nil, "PowerChargesConvertToAbsorptionCharges") then
			-- we max with possible Power Charge Override from Config since Absorption Charges won't have their own config entry
			-- and are converted from Power Charges
			output.AbsorptionCharges = m_max(output.PowerCharges, m_min(output.AbsorptionChargesMax, output.AbsorptionChargesMin))
			output.PowerCharges = 0
		else
			output.PowerCharges = m_max(output.PowerCharges, m_min(output.PowerChargesMax, output.PowerChargesMin))
		end
	end
	output.RemovablePowerCharges = m_max(output.PowerCharges - output.PowerChargesMin, 0)
	if modDB:Flag(nil, "UseFrenzyCharges") then
		output.FrenzyCharges = modDB:Override(nil, "FrenzyCharges") or output.FrenzyChargesMax
		if modDB:Flag(nil, "FrenzyChargesConvertToAfflictionCharges") then
			-- we max with possible Power Charge Override from Config since Absorption Charges won't have their own config entry
			-- and are converted from Power Charges
			output.AfflictionCharges = m_max(output.FrenzyCharges, m_min(output.AfflictionChargesMax, output.AfflictionChargesMin))
			output.FrenzyCharges = 0
		else
			output.FrenzyCharges = m_max(output.FrenzyCharges, m_min(output.FrenzyChargesMax, output.FrenzyChargesMin))
		end
	end
	output.RemovableFrenzyCharges = m_max(output.FrenzyCharges - output.FrenzyChargesMin, 0)
	if modDB:Flag(nil, "UseEnduranceCharges") then
		output.EnduranceCharges = modDB:Override(nil, "EnduranceCharges") or output.EnduranceChargesMax
		if modDB:Flag(nil, "EnduranceChargesConvertToBrutalCharges") then
			-- we max with possible Endurance Charge Override from Config since Brutal Charges won't have their own config entry
			-- and are converted from Endurance Charges
			output.BrutalCharges = m_max(output.EnduranceCharges, m_min(output.BrutalChargesMax, output.BrutalChargesMin))
			output.EnduranceCharges = 0
		else
			output.EnduranceCharges = m_max(output.EnduranceCharges, m_min(output.EnduranceChargesMax, output.EnduranceChargesMin))
		end
	end
	output.RemovableEnduranceCharges = m_max(output.EnduranceCharges - output.EnduranceChargesMin, 0)
	if modDB:Flag(nil, "UseSiphoningCharges") then
		output.SiphoningCharges = modDB:Override(nil, "SiphoningCharges") or output.SiphoningChargesMax
	end
	if modDB:Flag(nil, "UseChallengerCharges") then
		output.ChallengerCharges = modDB:Override(nil, "ChallengerCharges") or output.ChallengerChargesMax
	end
	if modDB:Flag(nil, "UseBlitzCharges") then
		output.BlitzCharges = modDB:Override(nil, "BlitzCharges") or output.BlitzChargesMax
	end
	if modDB:Flag(nil, "UseInspirationCharges") then
		output.InspirationCharges = modDB:Override(nil, "InspirationCharges") or output.InspirationChargesMax
	end
	if modDB:Flag(nil, "UseGhostShrouds") then
		output.GhostShrouds = modDB:Override(nil, "GhostShrouds") or 3
	end
	if modDB:Flag(nil, "CryWolfMinimumPower") and modDB:Sum("BASE", nil, "WarcryPower") < 10 then
		modDB:NewMod("WarcryPower", "OVERRIDE", 10, "Minimum Warcry Power from CryWolf")
	end

	output.WarcryPower = modDB:Override(nil, "WarcryPower") or modDB:Sum("BASE", nil, "WarcryPower") or 0
	output.CrabBarriers = m_min(modDB:Override(nil, "CrabBarriers") or output.CrabBarriersMax, output.CrabBarriersMax)
	output.TotalCharges = output.PowerCharges + output.FrenzyCharges + output.EnduranceCharges
	modDB.multipliers["WarcryPower"] = output.WarcryPower
	modDB.multipliers["PowerCharge"] = output.PowerCharges
	modDB.multipliers["RemovablePowerCharge"] = output.RemovablePowerCharges
	modDB.multipliers["FrenzyCharge"] = output.FrenzyCharges
	modDB.multipliers["RemovableFrenzyCharge"] = output.RemovableFrenzyCharges
	modDB.multipliers["EnduranceCharge"] = output.EnduranceCharges
	modDB.multipliers["RemovableEnduranceCharge"] = output.RemovableEnduranceCharges
	modDB.multipliers["TotalCharges"] = output.TotalCharges
	modDB.multipliers["SiphoningCharge"] = output.SiphoningCharges
	modDB.multipliers["ChallengerCharge"] = output.ChallengerCharges
	modDB.multipliers["BlitzCharge"] = output.BlitzCharges
	modDB.multipliers["InspirationCharge"] = output.InspirationCharges
	modDB.multipliers["GhostShroud"] = output.GhostShrouds
	modDB.multipliers["CrabBarrier"] = output.CrabBarriers
	modDB.multipliers["BrutalCharge"] = output.BrutalCharges
	modDB.multipliers["AbsorptionCharge"] = output.AbsorptionCharges
	modDB.multipliers["AfflictionCharge"] = output.AfflictionCharges

	-- Process enemy modifiers 
	for _, value in ipairs(modDB:List(nil, "EnemyModifier")) do
		enemyDB:AddMod(value.mod)
	end

	-- Add misc buffs/debuffs
	if env.mode_combat then
		if modDB:Flag(nil, "Fortify") then
			local effectScale = 1 + modDB:Sum("INC", nil, "FortifyEffectOnSelf", "BuffEffectOnSelf") / 100
			local modList = modDB:List(nil, "convertFortifyBuff")
			local changeMod = modList[#modList]
			if changeMod then
				local mod = changeMod.mod
				if not mod.originValue then
					mod.originValue = mod.value
				end
				mod.value = m_floor(mod.originValue * effectScale)
				mod.source = "Fortify"
				modDB:AddMod(mod)
			else
				local effect = m_floor(20 * effectScale)
				modDB:NewMod("DamageTakenWhenHit", "MORE", -effect, "Fortify")
			end
			modDB.multipliers["BuffOnSelf"] = (modDB.multipliers["BuffOnSelf"] or 0) + 1
		end
		if modDB:Flag(nil, "Onslaught") then
			local effect = m_floor(20 * (1 + modDB:Sum("INC", nil, "OnslaughtEffect", "BuffEffectOnSelf") / 100))
			modDB:NewMod("Speed", "INC", effect, "Onslaught")
			modDB:NewMod("MovementSpeed", "INC", effect, "Onslaught")
		end
		if modDB:Flag(nil, "Fanaticism") and actor.mainSkill and actor.mainSkill.skillFlags.selfCast then
			local effect = m_floor(75 * (1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100))
			modDB:NewMod("Speed", "MORE", effect, "Fanaticism", ModFlag.Cast)
			modDB:NewMod("ManaCost", "INC", -effect, "Fanaticism")
			modDB:NewMod("AreaOfEffect", "INC", effect, "Fanaticism")
		end
		if modDB:Flag(nil, "UnholyMight") then
			local effect = m_floor(30 * (1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100))
			modDB:NewMod("PhysicalDamageGainAsChaos", "BASE", effect, "Unholy Might")
		end
		if modDB:Flag(nil, "Tailwind") then
			local effect = m_floor(8 * (1 + modDB:Sum("INC", nil, "TailwindEffectOnSelf", "BuffEffectOnSelf") / 100))
			modDB:NewMod("ActionSpeed", "INC", effect, "Tailwind")
		end
		if modDB:Flag(nil, "Adrenaline") then
			local effectMod = 1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100
			modDB:NewMod("Damage", "INC", m_floor(100 * effectMod), "Adrenaline")
			modDB:NewMod("Speed", "INC", m_floor(25 * effectMod), "Adrenaline")
			modDB:NewMod("MovementSpeed", "INC", m_floor(25 * effectMod), "Adrenaline")
			modDB:NewMod("PhysicalDamageReduction", "BASE", m_floor(10 * effectMod), "Adrenaline")
		end
		if modDB:Flag(nil, "Convergence") then
			local effect = m_floor(30 * (1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100))
			modDB:NewMod("ElementalDamage", "MORE", effect, "Convergence")
		end
		if modDB:Flag(nil, "HerEmbrace") then
			condList["HerEmbrace"] = true
			modDB:NewMod("AvoidStun", "BASE", 100, "Her Embrace")
			modDB:NewMod("PhysicalDamageGainAsFire", "BASE", 123, "Her Embrace", ModFlag.Sword)
			modDB:NewMod("AvoidFreeze", "BASE", 100, "Her Embrace")
			modDB:NewMod("AvoidChill", "BASE", 100, "Her Embrace")
			modDB:NewMod("AvoidIgnite", "BASE", 100, "Her Embrace")
			modDB:NewMod("Speed", "INC", 20, "Her Embrace")
			modDB:NewMod("MovementSpeed", "INC", 20, "Her Embrace")
		end
		if modDB:Flag(nil, "Elusive") then
			local effect = 1 + modDB:Sum("INC", nil, "ElusiveEffect", "BuffEffectOnSelf") / 100
			condList["Elusive"] = true
			modDB:NewMod("AttackDodgeChance", "BASE", m_floor(15 * effect), "Elusive")
			modDB:NewMod("SpellDodgeChance", "BASE", m_floor(15 * effect), "Elusive")
			modDB:NewMod("MovementSpeed", "INC", m_floor(30 * effect), "Elusive")
		end
		if modDB:Flag(nil, "Blind") then
			if not modDB:Flag(nil, "IgnoreBlindHitChance") then
				modDB:NewMod("HitChance", "MORE", -50, "Blind")
			end
		end
		if modDB:Flag(nil, "Chill") then
			local effect = m_max(m_floor(30 * calcLib.mod(modDB, nil, "SelfChillEffect")), 0)
			modDB:NewMod("ActionSpeed", "INC", effect * (modDB:Flag(nil, "SelfChillEffectIsReversed") and 1 or -1), "Chill")
		end
		if modDB:Flag(nil, "Freeze") then
			local effect = m_max(m_floor(70 * calcLib.mod(modDB, nil, "SelfChillEffect")), 0)
			modDB:NewMod("ActionSpeed", "INC", -effect, "Freeze")
		end
		if modDB:Flag(nil, "CanLeechLifeOnFullLife") then
			condList["Leeching"] = true
			condList["LeechingLife"] = true
			env.configInput.conditionLeeching = true
		end
		if modDB:Flag(nil, "CanLeechLifeOnFullEnergyShield") then
			condList["Leeching"] = true
			condList["LeechingEnergyShield"] = true
			env.configInput.conditionLeeching = true
		end
		if modDB:Flag(nil, "Condition:InfusionActive") then
			local effect = 1 + modDB:Sum("INC", nil, "InfusionEffect", "BuffEffectOnSelf") / 100
			if modDB:Flag(nil, "Condition:HavePhysicalInfusion") then
				condList["PhysicalInfusion"] = true
				condList["Infusion"] = true
				modDB:NewMod("PhysicalDamage", "MORE", 10 * effect, "Infusion")
			end
			if modDB:Flag(nil, "Condition:HaveFireInfusion") then
				condList["FireInfusion"] = true
				condList["Infusion"] = true
				modDB:NewMod("FireDamage", "MORE", 10 * effect, "Infusion")
			end
			if modDB:Flag(nil, "Condition:HaveColdInfusion") then
				condList["ColdInfusion"] = true
				condList["Infusion"] = true
				modDB:NewMod("ColdDamage", "MORE", 10 * effect, "Infusion")
			end
			if modDB:Flag(nil, "Condition:HaveLightningInfusion") then
				condList["LightningInfusion"] = true
				condList["Infusion"] = true
				modDB:NewMod("LightningDamage", "MORE", 10 * effect, "Infusion")
			end
			if modDB:Flag(nil, "Condition:HaveChaosInfusion") then
				condList["ChaosInfusion"] = true
				condList["Infusion"] = true
				modDB:NewMod("ChaosDamage", "MORE", 10 * effect, "Infusion")
			end
		end
		if modDB:Flag(nil, "Condition:CanGainRage") or modDB:Sum("BASE", nil, "RageRegen") > 0 then
			output.MaximumRage = modDB:Sum("BASE", skillCfg, "MaximumRage")
			modDB:NewMod("Multiplier:Rage", "BASE", 1, "Base", { type = "Multiplier", var = "RageStack", limit = output.MaximumRage })
		end
		if modDB:Sum("BASE", nil, "CoveredInAshEffect") > 0 then
			local effect = modDB:Sum("BASE", nil, "CoveredInAshEffect")
			enemyDB:NewMod("FireDamageTaken", "INC", m_min(effect, 20), "Covered in Ash")
		end
	end	
end

-- Finalises the environment and performs the stat calculations:
-- 1. Merges keystone modifiers
-- 2. Initialises minion skills
-- 3. Initialises the main skill's minion, if present
-- 4. Merges flask effects
-- 5. Sets conditions and calculates attributes and life/mana pools (doActorAttribsPoolsConditions)
-- 6. Calculates reservations
-- 7. Sets life/mana reservation (doActorLifeManaReservation)
-- 8. Processes buffs and debuffs
-- 9. Processes charges and misc buffs (doActorMisc)
-- 10. Calculates defence and offence stats (calcs.defence, calcs.offence)
function calcs.perform(env)
	local modDB = env.modDB
	local enemyDB = env.enemyDB

	-- Merge keystone modifiers
	env.keystonesAdded = { }
	mergeKeystones(env)

	-- Build minion skills
	for _, activeSkill in ipairs(env.player.activeSkillList) do
		activeSkill.skillModList = new("ModList", activeSkill.baseSkillModList)
		if activeSkill.minion then
			activeSkill.minion.modDB = new("ModDB")
			activeSkill.minion.modDB.actor = activeSkill.minion
			calcs.createMinionSkills(env, activeSkill)
		end
	end

	env.player.output = { }
	env.enemy.output = { }
	local output = env.player.output

	env.minion = env.player.mainSkill.minion
	if env.minion then
		-- Initialise minion modifier database
		output.Minion = { }
		env.minion.output = output.Minion
		env.minion.modDB.multipliers["Level"] = env.minion.level
		calcs.initModDB(env, env.minion.modDB)
		env.minion.modDB:NewMod("Life", "BASE", m_floor(env.minion.lifeTable[env.minion.level] * env.minion.minionData.life), "Base")
		if env.minion.minionData.energyShield then
			env.minion.modDB:NewMod("EnergyShield", "BASE", m_floor(env.data.monsterAllyLifeTable[env.minion.level] * env.minion.minionData.life * env.minion.minionData.energyShield), "Base")
		end
		if env.minion.minionData.armour then
			env.minion.modDB:NewMod("Armour", "BASE", m_floor((10 + env.minion.level * 2) * env.minion.minionData.armour * 1.038 ^ env.minion.level), "Base")
		end
		env.minion.modDB:NewMod("Evasion", "BASE", round((30 + env.minion.level * 5) * 1.03 ^ env.minion.level), "Base")
		env.minion.modDB:NewMod("Accuracy", "BASE", round((17 + env.minion.level / 2) * (env.minion.minionData.accuracy or 1) * 1.03 ^ env.minion.level), "Base")
		env.minion.modDB:NewMod("CritMultiplier", "BASE", 30, "Base")
		env.minion.modDB:NewMod("CritDegenMultiplier", "BASE", 30, "Base")
		env.minion.modDB:NewMod("FireResist", "BASE", env.minion.minionData.fireResist, "Base")
		env.minion.modDB:NewMod("ColdResist", "BASE", env.minion.minionData.coldResist, "Base")
		env.minion.modDB:NewMod("LightningResist", "BASE", env.minion.minionData.lightningResist, "Base")
		env.minion.modDB:NewMod("ChaosResist", "BASE", env.minion.minionData.chaosResist, "Base")
		env.minion.modDB:NewMod("CritChance", "INC", 200, "Base", { type = "Multiplier", var = "PowerCharge" })
		env.minion.modDB:NewMod("Speed", "INC", 15, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		env.minion.modDB:NewMod("Damage", "MORE", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		env.minion.modDB:NewMod("MovementSpeed", "INC", 5, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		env.minion.modDB:NewMod("PhysicalDamageReduction", "BASE", 15, "Base", { type = "Multiplier", var = "EnduranceCharge" })
		env.minion.modDB:NewMod("ElementalResist", "BASE", 15, "Base", { type = "Multiplier", var = "EnduranceCharge" })
		env.minion.modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
		env.minion.modDB:NewMod("Damage", "MORE", -50, "Base", 0, KeywordFlag.Poison)
		env.minion.modDB:NewMod("Damage", "MORE", -50, "Base", 0, KeywordFlag.Ignite)
		env.minion.modDB:NewMod("SkillData", "LIST", { key = "bleedBasePercent", value = 70/6 }, "Base")
		env.minion.modDB:NewMod("Damage", "MORE", 500, "Base", 0, KeywordFlag.Bleed, { type = "ActorCondition", actor = "enemy", var = "Moving" })
		for _, mod in ipairs(env.minion.minionData.modList) do
			env.minion.modDB:AddMod(mod)
		end
		for _, mod in ipairs(env.player.mainSkill.extraSkillModList) do
			env.minion.modDB:AddMod(mod)
		end
		if env.aegisModList then
			env.minion.itemList["Weapon 3"] = env.player.itemList["Weapon 2"]
			env.minion.modDB:AddList(env.aegisModList)
		end
		if env.theIronMass and env.minion.type == "RaisedSkeleton" then
			env.minion.modDB:AddList(env.theIronMass)
			env.minion.modDB:NewMod("TripleDamageChance", "BASE", 100, { type = "ActorCondition", actor = "parent", var = "HitRecentlyWithWeapon" })
		end
		if env.player.mainSkill.skillData.minionUseBowAndQuiver then
			if env.player.weaponData1.type == "Bow" then
				env.minion.modDB:AddList(env.player.itemList["Weapon 1"].slotModList[1])
			end
			if env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 2"].type == "Quiver" then
				env.minion.modDB:AddList(env.player.itemList["Weapon 2"].modList)
			end
		end
		if env.minion.itemSet or env.minion.uses then
			for slotName, slot in pairs(env.build.itemsTab.slots) do
				if env.minion.uses[slotName] then
					local item
					if env.minion.itemSet then
						if slot.weaponSet == 1 and env.minion.itemSet.useSecondWeaponSet then
							slotName = slotName .. " Swap"
						end
						item = env.build.itemsTab.items[env.minion.itemSet[slotName].selItemId]
					else
						item = env.player.itemList[slotName]
					end
					if item then
						env.minion.itemList[slotName] = item
						env.minion.modDB:AddList(item.modList or item.slotModList[slot.slotNum])
					end
				end
			end
		end
		if modDB:Flag(nil, "StrengthAddedToMinions") then
			env.minion.modDB:NewMod("Str", "BASE", round(calcLib.val(modDB, "Str")), "Player")
		end
		if modDB:Flag(nil, "HalfStrengthAddedToMinions") then
			env.minion.modDB:NewMod("Str", "BASE", round(calcLib.val(modDB, "Str") * 0.5), "Player")
		end
	end
	if env.aegisModList then
		env.player.itemList["Weapon 2"] = nil
	end
	if modDB:Flag(nil, "AlchemistsGenius") then
		local effectMod = 1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100
		modDB:NewMod("FlaskEffect", "INC", m_floor(20 * effectMod), "Alchemist's Genius")
		modDB:NewMod("FlaskChargesGained", "INC", m_floor(20 * effectMod), "Alchemist's Genius")
	end

	for _, activeSkill in ipairs(env.player.activeSkillList) do
		if activeSkill.activeEffect.grantedEffect.name == "Herald of Purity" then
			local limit = activeSkill.skillModList:Sum("BASE", nil, "ActiveSentinelOfPurityLimit")
			output.ActiveSentinelOfPurityLimit = m_max(limit, output.ActiveSentinelOfPurityLimit or 0)
		end
		if activeSkill.skillFlags.golem then
			local limit = activeSkill.skillModList:Sum("BASE", nil, "ActiveGolemLimit")
			output.ActiveGolemLimit = m_max(limit, output.ActiveGolemLimit or 0)
		end
		if activeSkill.skillFlags.totem then
			local limit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ActiveTotemLimit", "ActiveBallistaLimit" )
			output.ActiveTotemLimit = m_max(limit, output.ActiveTotemLimit or 0)
			output.TotemsSummoned = modDB:Override(nil, "TotemsSummoned") or output.ActiveTotemLimit
		end
		if activeSkill.skillFlags.brand then
			local attachLimit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "BrandsAttachedLimit")
			if activeSkill.activeEffect.grantedEffect.name == "Arcanist Brand" then
				attachLimit = activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "BrandsAttachedLimit")
			elseif activeSkill.activeEffect.grantedEffect.name == "Wintertide Brand" then
				attachLimit = attachLimit + 1
			end
			local attached = modDB:Sum("BASE", nil, "Multiplier:ConfigBrandsAttachedToEnemy")
			local activeBrands = modDB:Sum("BASE", nil, "Multiplier:ConfigActiveBrands")
			local actual = m_min(attachLimit, attached)
			-- Cap the number of active brands by the limit, which is 3 by default
			modDB.multipliers["ActiveBrand"] = m_min(activeBrands, modDB:Sum("BASE", nil, "ActiveBrandLimit"))
			modDB.multipliers["BrandsAttachedToEnemy"] = m_max(actual, modDB.multipliers["BrandsAttachedToEnemy"] or 0)
			enemyDB.multipliers["BrandsAttached"] = m_max(actual, enemyDB.multipliers["BrandsAttached"] or 0)
		end
		-- The actual hexes as opposed to hex related skills all have the curse flag. Type31 is to remove blasphemy
		-- Note that this doesn't work for triggers yet, insufficient support
		if activeSkill.skillFlags.hex and activeSkill.skillFlags.curse and not activeSkill.skillTypes[SkillType.Type31] then
			local hexDoom = modDB:Sum("BASE", nil, "Multiplier:HexDoomStack")
			local maxDoom = activeSkill.skillModList:Sum("BASE", nil, "MaxDoom") or 30
			local doomEffect = activeSkill.skillModList:More(nil, "DoomEffect")
			-- Update the max doom limit
			output.HexDoomLimit = m_max(maxDoom, output.HexDoomLimit or 0)
			-- Update the Hex Doom to apply
			activeSkill.skillModList:NewMod("CurseEffect", "INC", m_min(hexDoom, maxDoom) * doomEffect, "Doom")
			modDB.multipliers["HexDoom"] =  m_min(m_max(hexDoom, modDB.multipliers["HexDoom"] or 0), output.HexDoomLimit)
		end
		if activeSkill.skillData.supportBonechill then
			if activeSkill.skillTypes[SkillType.ChillingArea] or (activeSkill.skillTypes[SkillType.NonHitChill] and not activeSkill.skillModList:Flag(nil, "CannotChill")) and not (activeSkill.activeEffect.grantedEffect.name == "Summon Skitterbots" and activeSkill.skillModList:Flag(nil, "SkitterbotsCannotChill")) then
				output.BonechillDotEffect = m_floor(10 * (1 + activeSkill.skillModList:Sum("INC", nil, "EnemyChillEffect") / 100))
			end
			output.BonechillEffect = m_max(output.BonechillEffect or 0, modDB:Override(nil, "BonechillEffect") or output.BonechillDotEffect or 0)
		end
		if (activeSkill.activeEffect.grantedEffect.name == "Vaal Lightning Trap"  or activeSkill.activeEffect.grantedEffect.name == "Shock Ground") then
			modDB:NewMod("ShockOverride", "BASE", activeSkill.skillModList:Sum("BASE", nil, "ShockedGroundEffect"), "Shocked Ground", { type = "ActorCondition", actor = "enemy", var = "OnShockedGround" } )
		end
		if activeSkill.activeEffect.grantedEffect.name == "Summon Skitterbots" then
			if not activeSkill.skillModList:Flag(nil, "SkitterbotsCannotShock") then
				local effect = activeSkill.skillModList:Sum("INC", { source = "Skill" }, "EnemyShockEffect")
				modDB:NewMod("ShockOverride", "BASE", 15 * (1 + effect / 100), "Summon Skitterbots")
				enemyDB:NewMod("Condition:Shocked", "FLAG", true, "Summon Skitterbots")
			end
			if not activeSkill.skillModList:Flag(nil, "SkitterbotsCannotChill") then
				enemyDB:NewMod("Condition:Chilled", "FLAG", true, "Summon Skitterbots")
			end
		end
		for _, damageType in ipairs({"Physical", "Lightning", "Cold", "Fire", "Chaos"}) do
			if activeSkill.activeEffect.grantedEffect.name == damageType.." Aegis" then
				modDB:NewMod(damageType.."AegisValue", "BASE", 1000, "Config")
			end
		end
		if activeSkill.activeEffect.grantedEffect.name == "Elemental Aegis" then
			modDB:NewMod("FireAegisValue", "BASE", 1000, "Config")
			modDB:NewMod("ColdAegisValue", "BASE", 1000, "Config")
			modDB:NewMod("LightningAegisValue", "BASE", 1000, "Config")
		end
		if activeSkill.skillModList:Flag(nil, "CanHaveAdditionalCurse") then
			output.GemCurseLimit = activeSkill.skillModList:Sum("BASE", nil, "AdditionalCurse")
		end
		if activeSkill.skillModList:Flag(nil, "Condition:CanWither") and not modDB:Flag(nil, "AlreadyWithered") then
			modDB:NewMod("Condition:CanWither", "FLAG", true, "Config")
			modDB:NewMod("Dummy", "DUMMY", 1, "Config", { type = "Condition", var = "CanWither" })
			local effect = m_floor(6 * (1 + modDB:Sum("INC", nil, "WitherEffect") / 100))
			enemyDB:NewMod("ChaosDamageTaken", "INC", effect, "Withered", { type = "Multiplier", var = "WitheredStack", limit = 15 } )
			if modDB:Flag(nil, "Condition:CanElementalWithered") then
				enemyDB:NewMod("ElementalDamageTaken", "INC", 4, "Withered", ModFlag.Hit, { type = "Multiplier", var = "WitheredStack", limit = 15 } )
			end
			modDB:NewMod("AlreadyWithered", "FLAG", true, "Config") -- Prevents effect from applying multiple times
		end
		if activeSkill.skillFlags.warcry and not modDB:Flag(nil, "AlreadyGlobalWarcryCooldown") then
			local cooldown = calcSkillCooldown(activeSkill.skillModList, activeSkill.skillCfg, activeSkill.skillData)
			local warcryList = { }
			local numWarcries, sumWarcryCooldown = 0
			for _, activeSkill in ipairs(env.player.activeSkillList) do
				if activeSkill.skillTypes[SkillType.Warcry] then
					warcryList[activeSkill.skillCfg.skillName] = true
				end
			end
			for _, warcry in pairs(warcryList) do
				numWarcries = numWarcries + 1
				sumWarcryCooldown = (sumWarcryCooldown or 0) + cooldown
			end
			env.player.modDB:NewMod("GlobalWarcryCooldown", "BASE", sumWarcryCooldown)
			env.player.modDB:NewMod("GlobalWarcryCount", "BASE", numWarcries)
			modDB:NewMod("AlreadyGlobalWarcryCooldown", "FLAG", true, "Config") -- Prevents effect from applying multiple times
		end
		if activeSkill.activeEffect.grantedEffect.name == "Summon Skeletons" then
			local limit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ActiveSkeletonLimit")
			output.ActiveSkeletonLimit = m_max(limit, output.ActiveSkeletonLimit or 0)
		elseif activeSkill.activeEffect.grantedEffect.name == "Raise Zombie" then
			local limit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ActiveZombieLimit")
			output.ActiveZombieLimit = m_max(limit, output.ActiveZombieLimit or 0)
		elseif activeSkill.activeEffect.grantedEffect.name == "Summon Raging Spirit" then
			local limit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ActiveRagingSpiritLimit")
			output.ActiveRagingSpiritLimit = m_max(limit, output.ActiveRagingSpiritLimit or 0)
		elseif activeSkill.activeEffect.grantedEffect.name == "Summoned Phantasm" then
			local limit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ActivePhantasmLimit")
			output.ActivePhantasmLimit = m_max(limit, output.ActivePhantasmLimit or 0)
		elseif activeSkill.activeEffect.grantedEffect.name == "Raise Spectre" then
			local limit = env.player.mainSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "ActiveSpectreLimit")
			output.ActiveSpectreLimit = m_max(limit, output.ActiveSpectreLimit or 0)
		end
		if env.mode_buffs and activeSkill.skillFlags.warcry then
			local extraExertions = activeSkill.skillModList:Sum("BASE", nil, "ExtraExertedAttacks") or 0
			local full_duration = activeSkill.activeEffect.grantedEffectLevel.duration * calcLib.mod(activeSkill.skillModList, activeSkill.skillCfg, "Duration", "PrimaryDuration", "SkillAndDamagingAilmentDuration", activeSkill.skillData.mineDurationAppliesToSkill and "MineDuration" or nil)
			local cooldownOverride = activeSkill.skillModList:Override(activeSkill.skillCfg, "CooldownRecovery")
			local actual_cooldown = cooldownOverride or (activeSkill.skillData.cooldown  + activeSkill.skillModList:Sum("BASE", activeSkill.skillCfg, "CooldownRecovery")) / calcLib.mod(activeSkill.skillModList, activeSkill.skillCfg, "CooldownRecovery")
			local globalCooldown = modDB:Sum("BASE", nil, "GlobalWarcryCooldown")
			local globalCount = modDB:Sum("BASE", nil, "GlobalWarcryCount")
			local uptime = m_min(full_duration / actual_cooldown, 1)
			local buff_inc = 1 + activeSkill.skillModList:Sum("INC", activeSkill.skillCfg, "BuffEffect") / 100
			local warcryPowerBonus = m_floor((modDB:Override(nil, "WarcryPower") or modDB:Sum("BASE", nil, "WarcryPower") or 0) / 5)
			if modDB:Flag(nil, "WarcryShareCooldown") then
				uptime = m_min(full_duration / (actual_cooldown + (globalCooldown - actual_cooldown) / globalCount), 1)
			end
			if activeSkill.activeEffect.grantedEffect.name == "Ancestral Cry" and not modDB:Flag(nil, "AncestralActive") then
				local ancestralArmour = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "AncestralArmourPer5MP")
				local ancestralArmourMax = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "AncestralArmourMax")
				local ancestralStrikeRange = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "AncestralMeleeWeaponRangePer5MP")
				local ancestralStrikeRangeMax = m_floor(6 * buff_inc)
				env.player.modDB:NewMod("NumAncestralExerts", "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "AncestralExertedAttacks") + extraExertions)
				ancestralArmourMax = m_floor(ancestralArmourMax * buff_inc)
				if warcryPowerBonus ~= 0 then
					ancestralArmour = m_floor(ancestralArmour * warcryPowerBonus * buff_inc) / warcryPowerBonus
					ancestralStrikeRange = m_floor(ancestralStrikeRange * warcryPowerBonus * buff_inc) / warcryPowerBonus
				end
				env.player.modDB:NewMod("Armour", "BASE", 257 * uptime, "Ancestral Cry", { type = "Multiplier", var = "WarcryPower", div = 5, limit = ancestralArmourMax, limitTotal = true })
				env.player.modDB:NewMod("MeleeWeaponRange", "BASE", ancestralStrikeRange * uptime, "Ancestral Cry", { type = "Multiplier", var = "WarcryPower", div = 5, limit = ancestralStrikeRangeMax, limitTotal = true })
				modDB:NewMod("AncestralActive", "FLAG", true) -- Prevents effect from applying multiple times
			elseif activeSkill.activeEffect.grantedEffect.name == "Enduring Cry" and not modDB:Flag(nil, "EnduringActive") then
				local heal_over_1_sec = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "EnduringCryLifeRegen")
				local resist_all_per_endurance = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "EnduringCryElementalResist")
				local pdr_per_endurance = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "EnduringCryPhysicalDamageReduction")
				env.player.modDB:NewMod("LifeRegen", "BASE", heal_over_1_sec , "Enduring Cry", { type = "Condition", var = "LifeRegenBurstFull" })
				env.player.modDB:NewMod("LifeRegen", "BASE", heal_over_1_sec / actual_cooldown, "Enduring Cry", { type = "Condition", var = "LifeRegenBurstAvg" })
				env.player.modDB:NewMod("ElementalResist", "BASE", m_floor(resist_all_per_endurance * buff_inc) * uptime, "Enduring Cry", { type = "Multiplier", var = "EnduranceCharge" })
				env.player.modDB:NewMod("PhysicalDamageReduction", "BASE", m_floor(pdr_per_endurance * buff_inc) * uptime, "Enduring Cry", { type = "Multiplier", var = "EnduranceCharge" })
				modDB:NewMod("EnduringActive", "FLAG", true) -- Prevents effect from applying multiple times
			elseif activeSkill.activeEffect.grantedEffect.name == "Infernal Cry" and not modDB:Flag(nil, "InfernalActive") then
				local infernalAshEffect = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "InfernalFireTakenPer5MP")
				env.player.modDB:NewMod("NumInfernalExerts", "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "InfernalExertedAttacks") + extraExertions)
				if env.mode_effective then
					env.player.modDB:NewMod("CoveredInAshEffect", "BASE", infernalAshEffect * uptime, { type = "Multiplier", var = "WarcryPower", div = 5 })
				end
				modDB:NewMod("InfernalActive", "FLAG", true) -- Prevents effect from applying multiple times
			elseif activeSkill.activeEffect.grantedEffect.name == "Intimidating Cry" and not modDB:Flag(nil, "IntimidatingActive") then
				local intimidatingOverwhelmEffect = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "IntimidatingPDRPer5MP")
				if warcryPowerBonus ~= 0 then
					intimidatingOverwhelmEffect = m_floor(intimidatingOverwhelmEffect * warcryPowerBonus * buff_inc) / warcryPowerBonus
				end
				env.player.modDB:NewMod("NumIntimidatingExerts", "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "IntimidatingExertedAttacks") + extraExertions)
				env.player.modDB:NewMod("EnemyPhysicalDamageReduction", "BASE", -intimidatingOverwhelmEffect * uptime, "Intimidating Cry Buff", { type = "Multiplier", var = "WarcryPower", div = 5, limit = 6 })
				modDB:NewMod("IntimidatingActive", "FLAG", true) -- Prevents effect from applying multiple times
			elseif activeSkill.activeEffect.grantedEffect.name == "Rallying Cry" and not modDB:Flag(nil, "RallyingActive") then
				local extraExertions = activeSkill.skillModList:Sum("BASE", nil, "ExtraExertedAttacks") or 0
				env.player.modDB:NewMod("NumRallyingExerts", "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "RallyingExertedAttacks") + extraExertions)
				env.player.modDB:NewMod("RallyingExertMoreDamagePerAlly",  "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "RallyingCryExertDamageBonus"))
				local rallyingWeaponEffect = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "RallyingCryAllyDamageBonusPer5Power")
				-- Rallying cry divergant more effect of buff
				local rallyingBonusMoreMultiplier = 1 + (activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "RallyingCryMinionDamageBonusMultiplier") or 0)
				if warcryPowerBonus ~= 0 then
					rallyingWeaponEffect = m_floor(rallyingWeaponEffect * warcryPowerBonus * buff_inc) / warcryPowerBonus
				end
				-- Special handling for the minion side to add the flat damage bonus
				if env.minion then
					-- Add all damage types
					local dmgTypeList = {"Physical", "Lightning", "Cold", "Fire", "Chaos"}
					for _, damageType in ipairs(dmgTypeList) do
						env.minion.modDB:NewMod(damageType.."Min", "BASE", m_floor((env.player.weaponData1[damageType.."Min"] or 0) * rallyingBonusMoreMultiplier * rallyingWeaponEffect / 100) * uptime, "Rallying Cry", { type = "Multiplier", actor = "parent", var = "WarcryPower", div = 5, limit = 6.6667})
						env.minion.modDB:NewMod(damageType.."Max", "BASE", m_floor((env.player.weaponData1[damageType.."Max"] or 0) * rallyingBonusMoreMultiplier * rallyingWeaponEffect / 100) * uptime, "Rallying Cry", { type = "Multiplier", actor = "parent", var = "WarcryPower", div = 5, limit = 6.6667})
					end
				end
				modDB:NewMod("RallyingActive", "FLAG", true) -- Prevents effect from applying multiple times
			elseif activeSkill.activeEffect.grantedEffect.name == "Seismic Cry" and not modDB:Flag(nil, "SeismicActive") then
				local seismicStunEffect = activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SeismicStunThresholdPer5MP")
				if warcryPowerBonus ~= 0 then
					seismicStunEffect = m_floor(seismicStunEffect * warcryPowerBonus * buff_inc) / warcryPowerBonus
				end
				env.player.modDB:NewMod("NumSeismicExerts", "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SeismicExertedAttacks") + extraExertions)
				env.player.modDB:NewMod("SeismicMoreDmgPerExert",  "BASE", activeSkill.skillModList:Sum("BASE", env.player.mainSkill.skillCfg, "SeismicHitMultiplier"))
				if env.mode_effective then
					env.player.modDB:NewMod("EnemyStunThreshold", "INC", -seismicStunEffect * uptime, "Seismic Cry Buff", { type = "Multiplier", var = "WarcryPower", div = 5, limit = 6 })
				end
				modDB:NewMod("SeismicActive", "FLAG", true) -- Prevents effect from applying multiple times
			end
		end
		if activeSkill.skillData.triggeredByBrand and not activeSkill.skillFlags.minion then
			activeSkill.skillData.triggered = true
			local spellCount, quality = 0
			for _, skill in ipairs(env.player.activeSkillList) do
				if skill.socketGroup == activeSkill.socketGroup and skill.skillData.triggeredByBrand then
					spellCount = spellCount + 1
				end
				if skill.socketGroup == activeSkill.socketGroup and skill.activeEffect.grantedEffect.name == "Arcanist Brand" then
					quality = skill.activeEffect.quality / 2
				end
			end
			for i, value in ipairs(activeSkill.skillModList:Tabulate("INC", env.player.mainSkill.skillCfg, "TriggeredDamage")) do
				activeSkill.skillModList:NewMod("Damage", "INC", value.mod.value, value.mod.source, value.mod.flags, value.mod.keywordFlags, unpack(value.mod))
			end
			for i, value in ipairs(activeSkill.skillModList:Tabulate("MORE", env.player.mainSkill.skillCfg, "TriggeredDamage")) do
				activeSkill.skillModList:NewMod("Damage", "MORE", value.mod.value, value.mod.source, value.mod.flags, value.mod.keywordFlags, unpack(value.mod))
			end
			activeSkill.skillModList:NewMod("ArcanistSpellsLinked", "BASE", spellCount, "Skill")
			activeSkill.skillModList:NewMod("BrandActivationFrequency", "INC", quality, "Skill")
		end
		if activeSkill.skillData.triggeredWhileChannelling and not activeSkill.skillFlags.minion then
			activeSkill.skillData.triggered = true
			local spellCount, trigTime = 0
			for _, skill in ipairs(env.player.activeSkillList) do
				if skill.socketGroup == activeSkill.socketGroup and skill.skillData.triggerTime or 0 > 0 then
					trigTime = skill.skillData.triggerTime
				end
				if skill.socketGroup == activeSkill.socketGroup and skill.skillData.triggeredWhileChannelling then
					spellCount = spellCount + 1
				end
			end
			for i, value in ipairs(activeSkill.skillModList:Tabulate("INC", env.player.mainSkill.skillCfg, "TriggeredDamage")) do
				activeSkill.skillModList:NewMod("Damage", "INC", value.mod.value, value.mod.source, value.mod.flags, value.mod.keywordFlags, unpack(value.mod))
			end
			for i, value in ipairs(activeSkill.skillModList:Tabulate("MORE", env.player.mainSkill.skillCfg, "TriggeredDamage")) do
				activeSkill.skillModList:NewMod("Damage", "MORE", value.mod.value, value.mod.source, value.mod.flags, value.mod.keywordFlags, unpack(value.mod))
			end
			activeSkill.skillModList:NewMod("CastWhileChannellingSpellsLinked", "BASE", spellCount, "Skill")
			activeSkill.skillData.triggerTime = trigTime
		end
	end

	local breakdown
	if env.mode == "CALCS" then
		-- Initialise breakdown module
		breakdown = LoadModule(calcs.breakdownModule, modDB, output, env.player)
		env.player.breakdown = breakdown
		if env.minion then
			env.minion.breakdown = LoadModule(calcs.breakdownModule, env.minion.modDB, env.minion.output, env.minion)
		end
	end

	-- Merge flask modifiers
	if env.mode_combat then
		local effectInc = modDB:Sum("INC", nil, "FlaskEffect")
		local flaskBuffs = { }
		local usingFlask = false
		local usingLifeFlask = false
		local usingManaFlask = false
		for item in pairs(env.flasks) do
			usingFlask = true
			if item.baseName:match("Life Flask") then
				usingLifeFlask = true
			end
			if item.baseName:match("Mana Flask") then
				usingManaFlask = true
			end
			if item.baseName:match("Hybrid Flask") then
				usingLifeFlask = true
				usingManaFlask = true
			end

			-- Avert thine eyes, lest they be forever scarred
			-- I have no idea how to determine which buff is applied by a given flask, 
			-- so utility flasks are grouped by base, unique flasks are grouped by name, and magic flasks by their modifiers
			local effectMod = 1 + (effectInc + item.flaskData.effectInc) / 100
			if item.buffModList[1] then
				local srcList = new("ModList")
				srcList:ScaleAddList(item.buffModList, effectMod)
				mergeBuff(srcList, flaskBuffs, item.baseName)
			end
			if item.modList[1] then
				local srcList = new("ModList")
				srcList:ScaleAddList(item.modList, effectMod)
				local key
				if item.rarity == "UNIQUE" then
					key = item.title
				else
					key = ""
					for _, mod in ipairs(item.modList) do
						key = key .. modLib.formatModParams(mod) .. "&"
					end
				end
				mergeBuff(srcList, flaskBuffs, key)
			end
		end
		if not modDB:Flag(nil, "FlasksDoNotApplyToPlayer") then
			modDB.conditions["UsingFlask"] = usingFlask
			modDB.conditions["UsingLifeFlask"] = usingLifeFlask
			modDB.conditions["UsingManaFlask"] = usingManaFlask
			for _, buffModList in pairs(flaskBuffs) do
				modDB:AddList(buffModList)
			end
		end
		if env.minion and modDB:Flag(env.player.mainSkill.skillCfg, "FlasksApplyToMinion") then
			local minionModDB = env.minion.modDB
			minionModDB.conditions["UsingFlask"] = usingFlask
			minionModDB.conditions["UsingLifeFlask"] = usingLifeFlask
			minionModDB.conditions["UsingManaFlask"] = usingManaFlask
			for _, buffModList in pairs(flaskBuffs) do
				minionModDB:AddList(buffModList)
			end
		end
	end

	-- Merge keystones again to catch any that were added by flasks
	mergeKeystones(env)

	-- Calculate attributes and life/mana pools
	doActorAttribsPoolsConditions(env, env.player)
	if env.minion then
		for _, value in ipairs(env.player.mainSkill.skillModList:List(env.player.mainSkill.skillCfg, "MinionModifier")) do
			if not value.type or env.minion.type == value.type then
				env.minion.modDB:AddMod(value.mod)
			end
		end
		for _, name in ipairs(env.minion.modDB:List(nil, "Keystone")) do
			env.minion.modDB:AddList(env.spec.tree.keystoneMap[name].modList)
		end
		doActorAttribsPoolsConditions(env, env.minion)
	end

	-- Calculate skill life and mana reservations
	env.player.reserved_LifeBase = 0
	env.player.reserved_LifePercent = modDB:Sum("BASE", nil, "ExtraLifeReserved") 
	env.player.reserved_ManaBase = 0
	env.player.reserved_ManaPercent = 0
	if breakdown then
		breakdown.LifeReserved = { reservations = { } }
		breakdown.ManaReserved = { reservations = { } }
	end
	for _, activeSkill in ipairs(env.player.activeSkillList) do
		if activeSkill.skillTypes[SkillType.ManaCostReserved] and not activeSkill.skillFlags.totem then
			local skillModList = activeSkill.skillModList
			local skillCfg = activeSkill.skillCfg
			local suffix = activeSkill.skillTypes[SkillType.ManaCostPercent] and "Percent" or "Base"
			local baseVal = activeSkill.skillData.manaCostOverride or activeSkill.activeEffect.grantedEffectLevel.manaCost or 0
			local mult = skillModList:More(skillCfg, "SupportManaMultiplier")
			local more = skillModList:More(skillCfg, "ManaReserved")
			local inc = skillModList:Sum("INC", skillCfg, "ManaReserved")
			local base = m_floor(baseVal * mult)
			local cost
			if activeSkill.skillData.manaCostForced then
				cost = activeSkill.skillData.manaCostForced
			else
				cost = m_max(base - m_modf(base * -m_floor((100 + inc) * more - 100) / 100), 0)
			end
			if activeSkill.activeMineCount then
				cost = cost * activeSkill.activeMineCount
			end
			local pool
			if skillModList:Flag(skillCfg, "BloodMagic", "SkillBloodMagic") then
				pool = "Life"
			else
				pool = "Mana"
			end
			env.player["reserved_"..pool..suffix] = env.player["reserved_"..pool..suffix] + cost
			if breakdown then
				t_insert(breakdown[pool.."Reserved"].reservations, {
					skillName = activeSkill.activeEffect.grantedEffect.name,
					base = baseVal .. (activeSkill.skillTypes[SkillType.ManaCostPercent] and "%" or ""),
					mult = mult ~= 1 and ("x "..mult),
					more = more ~= 1 and ("x "..more),
					inc = inc ~= 0 and ("x "..(1 + inc/100)),
					total = cost .. (activeSkill.skillTypes[SkillType.ManaCostPercent] and "%" or ""),
				})
			end
		end
	end
	
	-- Set the life/mana reservations
	doActorLifeManaReservation(env.player)
	if env.minion then
		doActorLifeManaReservation(env.minion)
	end

	-- Process attribute requirements
	do
		local reqMult = calcLib.mod(modDB, nil, "GlobalAttributeRequirements")
		for _, attr in ipairs({"Str","Dex","Int"}) do
			if env.mode == "CALCS" then
				breakdown["Req"..attr] = {
					rowList = { },
					colList = {
						{ label = attr, key = "req" },
						{ label = "Source", key = "source" },
						{ label = "Source Name", key = "sourceName" },
					}
				}
			end
			local out = 0
			for _, reqSource in ipairs(env.requirementsTable) do
				if reqSource[attr] and reqSource[attr] > 0 then
					local req = m_floor(reqSource[attr] * reqMult)
					out = m_max(out, req)
					if env.mode == "CALCS" then
						local row = {
							req = req > output[attr] and colorCodes.NEGATIVE..req or req,
							reqNum = req,
							source = reqSource.source,
						}
						if reqSource.source == "Item" then
							local item = reqSource.sourceItem
							row.sourceName = colorCodes[item.rarity]..item.name
							row.sourceNameTooltip = function(tooltip)
								env.build.itemsTab:AddItemTooltip(tooltip, item, reqSource.sourceSlot)
							end
						elseif reqSource.source == "Gem" then
							row.sourceName = s_format("%s%s ^7%d/%d", reqSource.sourceGem.color, reqSource.sourceGem.nameSpec, reqSource.sourceGem.level, reqSource.sourceGem.quality)
						end
						t_insert(breakdown["Req"..attr].rowList, row)
					end
				end
			end
			if modDB:Flag(nil, "IgnoreAttributeRequirements") then
				out = 0
			end
			output["Req"..attr] = out
			if env.mode == "CALCS" then
				output["Req"..attr.."String"] = out > output[attr] and colorCodes.NEGATIVE..out or out
				table.sort(breakdown["Req"..attr].rowList, function(a, b)
					if a.reqNum ~= b.reqNum then
						return a.reqNum > b.reqNum
					elseif a.source ~= b.source then
						return a.source < b.source 
					else
						return a.sourceName < b.sourceName
					end
				end)
			end
		end
	end

	-- Check for extra modifiers to apply to aura skills
	local extraAuraModList = { }
    for _, value in ipairs(modDB:List(nil, "ExtraAuraEffect")) do
        local add = true
        for _, mod in ipairs(extraAuraModList) do
            if modLib.compareModParams(mod, value.mod) then
                mod.value = mod.value + value.mod.value
                add = false
                break
            end
        end
        if add then
            t_insert(extraAuraModList, copyTable(value.mod, true))
        end
    end

	-- Calculate number of active heralds
	if env.mode_buffs then
		local heraldList = { }
		for _, activeSkill in ipairs(env.player.activeSkillList) do
			if activeSkill.skillTypes[SkillType.Herald] then
				heraldList[activeSkill.skillCfg.skillName] = true
			end
		end
		for _, herald in pairs(heraldList) do
			modDB.multipliers["Herald"] = (modDB.multipliers["Herald"] or 0) + 1
			modDB.conditions["AffectedByHerald"] = true
		end
	end
	
	-- Apply effect of Bonechill support
	if env.mode_effective and output.BonechillEffect then 
		enemyDB:NewMod("ColdDamageTaken", "INC", output.BonechillEffect, "Bonechill", { type = "GlobalEffect", effectType = "Debuff", effectName = "Bonechill Cold DoT Taken" }, { type = "Limit", limit = 30 }, { type = "Condition", var = "Chilled" } )
	end

	-- Combine buffs/debuffs 
	output.EnemyCurseLimit = modDB:Sum("BASE", nil, "EnemyCurseLimit") + (output.GemCurseLimit or 0)
	local buffs = { }
	env.buffs = buffs
	local guards = { }
	local minionBuffs = { }
	env.minionBuffs = minionBuffs
	local debuffs = { }
	env.debuffs = debuffs
	local curses = { 
		limit = output.EnemyCurseLimit,
	}
	local minionCurses = { 
		limit = 1,
	}
	local affectedByAura = { }
	for _, activeSkill in ipairs(env.player.activeSkillList) do
		local skillModList = activeSkill.skillModList
		local skillCfg = activeSkill.skillCfg
		for _, buff in ipairs(activeSkill.buffList) do
			if buff.cond and not skillModList:GetCondition(buff.cond, skillCfg) then
				-- Nothing!
			elseif buff.enemyCond and not enemyDB:GetCondition(buff.enemyCond) then
				-- Also nothing :/
			elseif buff.type == "Buff" then
				if env.mode_buffs and (not activeSkill.skillFlags.totem or buff.allowTotemBuff) then
					local skillCfg = buff.activeSkillBuff and skillCfg
					local modStore = buff.activeSkillBuff and skillModList or modDB
				 	if not buff.applyNotPlayer then
						activeSkill.buffSkill = true
						modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
						local srcList = new("ModList")
						local inc = modStore:Sum("INC", skillCfg, "BuffEffect", "BuffEffectOnSelf", "BuffEffectOnPlayer", buff.name:gsub(" ", "").."Effect")
						local more = modStore:More(skillCfg, "BuffEffect", "BuffEffectOnSelf")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						mergeBuff(srcList, buffs, buff.name)
						if activeSkill.skillData.thisIsNotABuff then
							buffs[buff.name].notBuff = true
						end
					end
					if env.minion and (buff.applyMinions or buff.applyAllies) then
						activeSkill.minionBuffSkill = true
						env.minion.modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
						local srcList = new("ModList")
						local inc = modStore:Sum("INC", skillCfg, "BuffEffect", "BuffEffectOnMinion") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf")
						local more = modStore:More(skillCfg, "BuffEffect", "BuffEffectOnMinion") * env.minion.modDB:More(nil, "BuffEffectOnSelf")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						mergeBuff(srcList, minionBuffs, buff.name)
					end
				end
			elseif buff.type == "Guard" then
				if env.mode_buffs and (not activeSkill.skillFlags.totem or buff.allowTotemBuff) then
					local skillCfg = buff.activeSkillBuff and skillCfg
					local modStore = buff.activeSkillBuff and skillModList or modDB
				 	if not buff.applyNotPlayer then
						activeSkill.buffSkill = true
						local srcList = new("ModList")
						local inc = modStore:Sum("INC", skillCfg, "BuffEffect", "BuffEffectOnSelf", "BuffEffectOnPlayer")
						local more = modStore:More(skillCfg, "BuffEffect", "BuffEffectOnSelf")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						mergeBuff(srcList, guards, buff.name)
					end
				end
			elseif buff.type == "Aura" then
				if env.mode_buffs then
					if not activeSkill.skillData.auraCannotAffectSelf then
						activeSkill.buffSkill = true
						affectedByAura[env.player] = true
						modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
						local srcList = new("ModList")
						local inc = skillModList:Sum("INC", skillCfg, "AuraEffect", "BuffEffect", "BuffEffectOnSelf", "AuraEffectOnSelf", "AuraBuffEffect", "SkillAuraEffectOnSelf")

						-- Take the Purposeful Harbinger buffs into account.
						-- These are capped to 40% increased buff effect, no matter the amount allocated
						local incFromPurposefulHarbinger = math.min(
							skillModList:Sum("INC", skillCfg, "PurpHarbAuraBuffEffect"),
							data.misc.PurposefulHarbingerMaxBuffPercent)
						inc = inc + incFromPurposefulHarbinger

						local more = skillModList:More(skillCfg, "AuraEffect", "BuffEffect", "BuffEffectOnSelf", "AuraEffectOnSelf", "AuraBuffEffect", "SkillAuraEffectOnSelf")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						srcList:ScaleAddList(extraAuraModList, (1 + inc / 100) * more)
						mergeBuff(srcList, buffs, buff.name)
					end
					if env.minion and not modDB:Flag(nil, "SelfAurasCannotAffectAllies") then
						activeSkill.minionBuffSkill = true
						affectedByAura[env.minion] = true
						env.minion.modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
						local srcList = new("ModList")
						local inc = skillModList:Sum("INC", skillCfg, "AuraEffect", "BuffEffect") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
						local more = skillModList:More(skillCfg, "AuraEffect", "BuffEffect") * env.minion.modDB:More(nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						srcList:ScaleAddList(extraAuraModList, (1 + inc / 100) * more)
						mergeBuff(srcList, minionBuffs, buff.name)
					end
				end
			elseif buff.type == "Debuff" or buff.type == "AuraDebuff" then
				local stackCount
				if buff.stackVar then
					stackCount = skillModList:Sum("BASE", skillCfg, "Multiplier:"..buff.stackVar)
					if buff.stackLimit then
						stackCount = m_min(stackCount, buff.stackLimit)
					elseif buff.stackLimitVar then
						stackCount = m_min(stackCount, skillModList:Sum("BASE", skillCfg, "Multiplier:"..buff.stackLimitVar))
					end
				else
					stackCount = activeSkill.skillData.stackCount or 1
				end
				if env.mode_effective and stackCount > 0 then
					activeSkill.debuffSkill = true
					modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
					local srcList = new("ModList")
					local mult = 1
					if buff.type == "AuraDebuff" then
						local inc = skillModList:Sum("INC", skillCfg, "AuraEffect", "BuffEffect", "DebuffEffect")
						local more = skillModList:More(skillCfg, "AuraEffect", "BuffEffect", "DebuffEffect")
						mult = (1 + inc / 100) * more
					end
					srcList:ScaleAddList(buff.modList, mult * stackCount)
					if activeSkill.skillData.stackCount or buff.stackVar then
						srcList:NewMod("Multiplier:"..buff.name.."Stack", "BASE", stackCount, buff.name)
					end
					mergeBuff(srcList, debuffs, buff.name)
				end
			elseif buff.type == "Curse" or buff.type == "CurseBuff" then
				if env.mode_effective and (not enemyDB:Flag(nil, "Hexproof") or modDB:Flag(nil, "CursesIgnoreHexproof")) then
					local curse = {
						name = buff.name,
						fromPlayer = true,
						priority = activeSkill.skillTypes[SkillType.Aura] and 3 or 1,
						isMark = activeSkill.skillTypes[SkillType.Mark],
					}
					local inc = skillModList:Sum("INC", skillCfg, "CurseEffect") + enemyDB:Sum("INC", nil, "CurseEffectOnSelf")
					local more = skillModList:More(skillCfg, "CurseEffect")
					-- This is non-ideal, but the only More for enemy is the boss effect
					if not curse.isMark then
						more = more * enemyDB:More(nil, "CurseEffectOnSelf")
					end
					if buff.type == "Curse" then
						curse.modList = new("ModList")
						curse.modList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
					else
						-- Curse applies a buff; scale by curse effect, then buff effect
						local temp = new("ModList")
						temp:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						curse.buffModList = new("ModList")
						local buffInc = modDB:Sum("INC", skillCfg, "BuffEffectOnSelf")
						local buffMore = modDB:More(skillCfg, "BuffEffectOnSelf")
						curse.buffModList:ScaleAddList(temp, (1 + buffInc / 100) * buffMore)
						if env.minion then
							curse.minionBuffModList = new("ModList")
							local buffInc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf")
							local buffMore = env.minion.modDB:More(nil, "BuffEffectOnSelf")
							curse.minionBuffModList:ScaleAddList(temp, (1 + buffInc / 100) * buffMore)
						end
					end
					t_insert(curses, curse)	
				end
			end
		end
		if activeSkill.minion then
			local castingMinion = activeSkill.minion
			for _, activeSkill in ipairs(activeSkill.minion.activeSkillList) do
				local skillModList = activeSkill.skillModList
				local skillCfg = activeSkill.skillCfg
				for _, buff in ipairs(activeSkill.buffList) do
					if buff.type == "Buff" then
						if env.mode_buffs and activeSkill.skillData.enable then
							local skillCfg = buff.activeSkillBuff and skillCfg
							local modStore = buff.activeSkillBuff and skillModList or castingMinion.modDB
							if buff.applyAllies then
								modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
								local srcList = new("ModList")
								local inc = modStore:Sum("INC", skillCfg, "BuffEffect") + modDB:Sum("INC", nil, "BuffEffectOnSelf")
								local more = modStore:More(skillCfg, "BuffEffect") * modDB:More(nil, "BuffEffectOnSelf")
								srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
								mergeBuff(srcList, buffs, buff.name)
							end
							if env.minion and (env.minion == castingMinion or buff.applyAllies) then
				 				env.minion.modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
								local srcList = new("ModList")
								local inc = modStore:Sum("INC", skillCfg, "BuffEffect", "BuffEffectOnSelf")
								local more = modStore:More(skillCfg, "BuffEffect", "BuffEffectOnSelf")
								srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
								mergeBuff(srcList, minionBuffs, buff.name)
							end
						end
					elseif buff.type == "Aura" then
						if env.mode_buffs and activeSkill.skillData.enable then
							if not modDB:Flag(nil, "AlliesAurasCannotAffectSelf") then
								local srcList = new("ModList")
								local inc = skillModList:Sum("INC", skillCfg, "AuraEffect", "BuffEffect") + modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
								local more = skillModList:More(skillCfg, "AuraEffect", "BuffEffect") * modDB:More(nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
								srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
								mergeBuff(srcList, buffs, buff.name)
							end
							if env.minion and (env.minion ~= activeSkill.minion or not activeSkill.skillData.auraCannotAffectSelf) then
								local srcList = new("ModList")
								local inc = skillModList:Sum("INC", skillCfg, "AuraEffect", "BuffEffect") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
								local more = skillModList:More(skillCfg, "AuraEffect", "BuffEffect") * env.minion.modDB:More(nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
								srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
								mergeBuff(srcList, minionBuffs, buff.name)
							end
						end
					elseif buff.type == "Curse" then
						if env.mode_effective and activeSkill.skillData.enable and not enemyDB:Flag(nil, "Hexproof") then
							local curse = {
								name = buff.name,
								priority = 1,
							}
							local inc = skillModList:Sum("INC", skillCfg, "CurseEffect") + enemyDB:Sum("INC", nil, "CurseEffectOnSelf")
							local more = skillModList:More(skillCfg, "CurseEffect") * enemyDB:More(nil, "CurseEffectOnSelf")
							curse.modList = new("ModList")
							curse.modList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
							t_insert(minionCurses, curse)
						end
					elseif buff.type == "Debuff" then
						local stackCount
						if buff.stackVar then
							stackCount = modDB:Sum("BASE", skillCfg, "Multiplier:"..buff.stackVar)
							if buff.stackLimit then
								stackCount = m_min(stackCount, buff.stackLimit)
							elseif buff.stackLimitVar then
								stackCount = m_min(stackCount, modDB:Sum("BASE", skillCfg, "Multiplier:"..buff.stackLimitVar))
							end
						else
							stackCount = activeSkill.skillData.stackCount or 1
						end
						if env.mode_effective and stackCount > 0 then
							activeSkill.debuffSkill = true
							local srcList = new("ModList")
							srcList:ScaleAddList(buff.modList, stackCount)
							if activeSkill.skillData.stackCount then
								srcList:NewMod("Multiplier:"..buff.name.."Stack", "BASE", activeSkill.skillData.stackCount, buff.name)
							end
							mergeBuff(srcList, debuffs, buff.name)
						end
					end
				end
			end
		end
	end

	-- Check for extra curses
	for dest, modDB in pairs({[curses] = modDB, [minionCurses] = env.minion and env.minion.modDB}) do
		for _, value in ipairs(modDB:List(nil, "ExtraCurse")) do
			local gemModList = new("ModList")
			local grantedEffect = env.data.skills[value.skillId]
			if grantedEffect then
				calcs.mergeSkillInstanceMods(env, gemModList, {
					grantedEffect = grantedEffect,
					level = value.level,
					quality = 0,
				})
				local curseModList = { }
				for _, mod in ipairs(gemModList) do
					for _, tag in ipairs(mod) do
						if tag.type == "GlobalEffect" and tag.effectType == "Curse" then
							t_insert(curseModList, mod)
							break
						end
					end
				end
				if value.applyToPlayer then
					-- Sources for curses on the player don't usually respect any kind of limit, so there's little point bothering with slots
					if modDB:Sum("BASE", nil, "AvoidCurse") < 100 then
						modDB.conditions["Cursed"] = true
						modDB.multipliers["CurseOnSelf"] = (modDB.multipliers["CurseOnSelf"] or 0) + 1
						modDB.conditions["AffectedBy"..grantedEffect.name:gsub(" ","")] = true
						local cfg = { skillName = grantedEffect.name }
						local inc = modDB:Sum("INC", cfg, "CurseEffectOnSelf") + gemModList:Sum("INC", nil, "CurseEffectAgainstPlayer")
						local more = modDB:More(cfg, "CurseEffectOnSelf") * gemModList:More(nil, "CurseEffectAgainstPlayer")
						modDB:ScaleAddList(curseModList, (1 + inc / 100) * more)
					end
				elseif not enemyDB:Flag(nil, "Hexproof") or modDB:Flag(nil, "CursesIgnoreHexproof") then
					local curse = {
						name = grantedEffect.name,
						fromPlayer = (dest == curses),
						priority = 2,
					}
					curse.modList = new("ModList")
					curse.modList:ScaleAddList(curseModList, (1 + enemyDB:Sum("INC", nil, "CurseEffectOnSelf") / 100) * enemyDB:More(nil, "CurseEffectOnSelf"))
					t_insert(dest, curse)
				end
			end
		end
	end

	-- Assign curses to slots
	local curseSlots = { }
	env.curseSlots = curseSlots
	-- Currently assume only 1 mark is possible
	local markSlotted = false
	for _, source in ipairs({curses, minionCurses}) do
		for _, curse in ipairs(source) do
			local slot
			for i = 1, source.limit do
				--Prevent multiple marks from being considered
				if curse.isMark then
					if markSlotted then
						slot = nil
						break
					end
				end
				if not curseSlots[i] then
					slot = i
					break
				elseif curseSlots[i].name == curse.name then
					if curseSlots[i].priority < curse.priority then
						slot = i
					else
						slot = nil
					end
					break
				elseif curseSlots[i].priority < curse.priority then
					slot = i
				end
			end
			if slot then
				if curseSlots[slot] and curseSlots[slot].isMark then
					markSlotted = false
				end
				curseSlots[slot] = curse
				if curse.isMark then
					markSlotted = true
				end
			end
		end
	end

	-- Process guard buffs
	local guardSlots = { }
	local nonVaal = false
	for name, modList in pairs(guards) do
		if name == "Vaal Molten Shell" then
			wipeTable(guardSlots)
			nonVaal = false
			t_insert(guardSlots, { name = name, modList = modList })
			break
		elseif name:match("^Vaal") then
			t_insert(guardSlots, { name = name, modList = modList })
		elseif not nonVaal then
			t_insert(guardSlots, { name = name, modList = modList })
			nonVaal = true
		end
	end
	if nonVaal then
		modDB.conditions["AffectedByNonVaalGuardSkill"] = true
	end
	for _, guard in ipairs(guardSlots) do
		modDB.conditions["AffectedByGuardSkill"] = true
		modDB.conditions["AffectedBy"..guard.name:gsub(" ","")] = true
		mergeBuff(guard.modList, buffs, guard.name)
	end

	-- Apply buff/debuff modifiers
	for _, modList in pairs(buffs) do
		modDB:AddList(modList)
		if not modList.notBuff then
			modDB.multipliers["BuffOnSelf"] = (modDB.multipliers["BuffOnSelf"] or 0) + 1
		end
		if env.minion then
			for _, value in ipairs(modList:List(env.player.mainSkill.skillCfg, "MinionModifier")) do
				if not value.type or env.minion.type == value.type then
					env.minion.modDB:AddMod(value.mod)
				end
			end
		end
	end
	if env.minion then
		for _, modList in pairs(minionBuffs) do
			env.minion.modDB:AddList(modList)
		end
	end
	for _, modList in pairs(debuffs) do
		enemyDB:AddList(modList)
	end
	modDB.multipliers["CurseOnEnemy"] = #curseSlots
	local affectedByCurse = { }
	for _, slot in ipairs(curseSlots) do
		enemyDB.conditions["Cursed"] = true
		if slot.isMark then
			enemyDB.conditions["Marked"] = true
		end
		if slot.fromPlayer then
			affectedByCurse[env.enemy] = true
		end
		if slot.modList then
			enemyDB:AddList(slot.modList)
		end
		if slot.buffModList then
			modDB:AddList(slot.buffModList)
		end
		if slot.minionBuffModList then
			env.minion.modDB:AddList(slot.minionBuffModList)
		end
	end
	
	for _, activeSkill in ipairs(env.player.activeSkillList) do -- Do another pass on the SkillList to catch effects of buffs, if needed
		if activeSkill.activeEffect.grantedEffect.name == "Blight" and activeSkill.skillPart == 2 then
			local rate = (1 / 0.3) * calcLib.mod(activeSkill.skillModList, activeSkill.skillCfg, "Speed")
			local duration = calcSkillDuration(activeSkill.skillModList, activeSkill.skillCfg, activeSkill.skillData, env.player, enemyDB)
			local maximum = m_min((m_floor(rate * duration) - 1), 19)
			activeSkill.skillModList:NewMod("Multiplier:BlightMaxStagesAfterFirst", "BASE", maximum, "Base")
			activeSkill.skillModList:NewMod("Multiplier:BlightStageAfterFirst", "BASE", maximum, "Base")
		end
		if activeSkill.activeEffect.grantedEffect.name == "Penance Brand" and activeSkill.skillPart == 2 then
			local rate = 1 / (activeSkill.skillData.repeatFrequency / (1 + env.player.mainSkill.skillModList:Sum("INC", env.player.mainSkill.skillCfg, "Speed", "BrandActivationFrequency") / 100) / activeSkill.skillModList:More(activeSkill.skillCfg, "BrandActivationFrequency"))
			local duration = calcSkillDuration(activeSkill.skillModList, activeSkill.skillCfg, activeSkill.skillData, env.player, enemyDB)
			local ticks = m_min((m_floor(rate * duration) - 1), 19)
			activeSkill.skillModList:NewMod("Multiplier:PenanceBrandMaxStagesAfterFirst", "BASE", ticks, "Base")
			activeSkill.skillModList:NewMod("Multiplier:PenanceBrandStageAfterFirst", "BASE", ticks, "Base")
		end
		if activeSkill.activeEffect.grantedEffect.name == "Scorching Ray" and activeSkill.skillPart == 2 then
			local rate = (1 / 0.5) * calcLib.mod(activeSkill.skillModList, activeSkill.skillCfg, "Speed")
			local duration = calcSkillDuration(activeSkill.skillModList, activeSkill.skillCfg, activeSkill.skillData, env.player, enemyDB)
			local maximum = m_min((m_floor(rate * duration) - 1), 7)
			activeSkill.skillModList:NewMod("Multiplier:ScorchingRayMaxStagesAfterFirst", "BASE", maximum, "Base")
			activeSkill.skillModList:NewMod("Multiplier:ScorchingRayStageAfterFirst", "BASE", maximum, "Base")
			if maximum >= 7 then
				activeSkill.skillModList:NewMod("Condition:ScorchingRayMaxStages", "FLAG", true, "Config")
				enemyDB:NewMod("FireResist", "BASE", -25, "Scorching Ray", { type = "GlobalEffect", effectType = "Debuff" } )
			end
		end
	end
	
	-- Fix the configured impale stacks on the enemy
	-- 		If the config is missing (blank), then use the maximum number of stacks
	--		If the config is larger than the maximum number of stacks, replace it with the correct maximum
	local maxImpaleStacks = modDB:Sum("BASE", nil, "ImpaleStacksMax")
	if not enemyDB:HasMod("BASE", nil, "Multiplier:ImpaleStacks") then
		enemyDB:NewMod("Multiplier:ImpaleStacks", "BASE", maxImpaleStacks, "Config", { type = "Condition", var = "Combat" })
	elseif enemyDB:Sum("BASE", nil, "Multiplier:ImpaleStacks") > maxImpaleStacks then
		enemyDB:ReplaceMod("Multiplier:ImpaleStacks", "BASE", maxImpaleStacks, "Config", { type = "Condition", var = "Combat" })
	end
	
	-- Calculates maximum Shock, then applies the strongest Shock effect to the enemy
	if (enemyDB:Sum("BASE", nil, "ShockVal") > 0 or modDB:Sum(nil, "ShockBase", "ShockOverride")) and not enemyDB:Flag(nil, "Condition:AlreadyShocked") then
		local baseShock = (modDB:Override(nil, "ShockBase") or 0) * (1 + modDB:Sum("INC", nil, "EnemyShockEffect") / 100)
		local overrideShock = 0
		for i, value in ipairs(modDB:Tabulate("BASE", { }, "ShockBase", "ShockOverride")) do
			local mod = value.mod
			local inc = 1 + modDB:Sum("INC", nil, "EnemyShockEffect") / 100
			local effect = mod.value
			if mod.name == "ShockOverride" then
				enemyDB:NewMod("Condition:Shocked", "FLAG", true, mod.source)
			end
			if mod.name == "ShockBase" then
				effect = effect * inc
				modDB:NewMod("ShockOverride", "BASE", effect, mod.source, mod.flags, mod.keywordFlags, unpack(mod))
			end
			overrideShock = m_max(overrideShock or 0, effect or 0)
		end
		output.MaximumShock = modDB:Override(nil, "ShockMax") or 50
		output.CurrentShock = m_floor(m_min(m_max(overrideShock, enemyDB:Sum("BASE", nil, "ShockVal")), output.MaximumShock))
		enemyDB:NewMod("DamageTaken", "INC", m_floor(output.CurrentShock), "Shock", { type = "Condition", var = "Shocked"} )
		enemyDB:NewMod("Condition:AlreadyShocked", "FLAG", true, { type = "Condition", var = "Shocked"} ) -- Prevents Shock from applying doubly for minions
	end

	-- Check for extra auras
	for _, value in ipairs(modDB:List(nil, "ExtraAura")) do
		local modList = { value.mod }
		if not value.onlyAllies then
			local inc = modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			local more = modDB:More(nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			modDB:ScaleAddList(modList, (1 + inc / 100) * more)
			if not value.notBuff then
				modDB.multipliers["BuffOnSelf"] = (modDB.multipliers["BuffOnSelf"] or 0) + 1
			end
		end
		if env.minion and not modDB:Flag(nil, "SelfAurasCannotAffectAllies") then
			local inc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			local more = env.minion.modDB:More(nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			env.minion.modDB:ScaleAddList(modList, (1 + inc / 100) * more)
		end
	end

	-- Check for modifiers to apply to actors affected by player auras or curses
	for _, value in ipairs(modDB:List(nil, "AffectedByAuraMod")) do
		for actor in pairs(affectedByAura) do
			actor.modDB:AddMod(value.mod)
		end
	end
	for _, value in ipairs(modDB:List(nil, "AffectedByCurseMod")) do
		for actor in pairs(affectedByCurse) do
			actor.modDB:AddMod(value.mod)
		end
	end

	-- Merge keystones again to catch any that were added by buffs
	mergeKeystones(env)

	-- Special handling for Dancing Dervish
	if modDB:Flag(nil, "DisableWeapons") then
		env.player.weaponData1 = copyTable(env.data.unarmedWeaponData[env.classId])
		modDB.conditions["Unarmed"] = true
		if not env.player.Gloves or env.player.Gloves == None then
			modDB.conditions["Unencumbered"] = true
		end
	elseif env.weaponModList1 then
		modDB:AddList(env.weaponModList1)
	end

	-- Process misc buffs/modifiers
	doActorMisc(env, env.player)
	if env.minion then
		doActorMisc(env, env.minion)
	end
	doActorMisc(env, env.enemy)

	-- Apply exposures
	for _, element in pairs({"Fire", "Cold", "Lightning"}) do
		local min = math.huge
		for _, mod in ipairs(enemyDB:Tabulate("BASE", nil, element.."Exposure")) do
			if mod.value < min then
				min = mod.value
			end
		end
		if min ~= math.huge then
			-- Modify the magnitude of all exposures
			for _, value in ipairs(modDB:Tabulate("BASE", nil, "ExtraExposure")) do
				local mod = value.mod
				enemyDB:NewMod(element.."Resist", "BASE", mod.value, mod.source)
			end
			enemyDB:NewMod(element.."Resist", "BASE", min, element.." Exposure")
			modDB:NewMod("Condition:AppliedExposureRecently", "FLAG", true, "")
		end
	end

	-- Defence/offence calculations
	calcs.defence(env, env.player)
	calcs.offence(env, env.player, env.player.mainSkill)
	if env.minion then
		calcs.defence(env, env.minion)
		calcs.offence(env, env.minion, env.minion.mainSkill)
	end
end
