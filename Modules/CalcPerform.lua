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
		destTable[destKey] = common.New("ModList")
	end
	local dest = destTable[destKey]
	for _, mod in ipairs(src) do
		local match = false
		for index, destMod in ipairs(dest) do
			if modLib.compareModParams(mod, destMod) then
				if type(destMod.value) == "number" and mod.value > destMod.value then
					dest[index] = mod
				end
				match = true
				break
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

	for _, name in ipairs(modDB:Sum("LIST", nil, "Keystone")) do
		if not env.keystonesAdded[name] then
			env.keystonesAdded[name] = true
			modDB:AddList(env.build.tree.keystoneMap[name].modList)
		end
	end
end

-- Calculate attributes and life/mana pools, and set conditions
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
	else
		local info = env.data.weaponTypeInfo[actor.weaponData1.type]
		condList["Using"..info.flag] = true
        if actor.weaponData1.countsAsAll1H then
            condList["UsingAxe"] = true
            condList["UsingSword"] = true
            condList["UsingDagger"] = true
            condList["UsingMace"] = true
            condList["UsingClaw"] = true
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
		if actor.weaponData1.type == "Claw" and actor.weaponData2.type == "Claw" then
			condList["DualWieldingClaws"] = true
		end
	end
	if env.mode_combat then		
		if not modDB:Sum("FLAG", nil, "NeverCrit") then
			condList["CritInPast8Sec"] = true
		end
		if not actor.mainSkill.skillData.triggered and not actor.mainSkill.skillFlags.trap and not actor.mainSkill.skillFlags.mine and not actor.mainSkill.skillFlags.totem then 
			if actor.mainSkill.skillFlags.attack then
				condList["AttackedRecently"] = true
			elseif actor.mainSkill.skillFlags.spell then
				condList["CastSpellRecently"] = true
			end
			if actor.mainSkill.skillFlags.movement then
				condList["UsedMovementSkillRecently"] = true
			end
			if actor.mainSkill.skillFlags.minion then
				condList["UsedMinionSkillRecently"] = true
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
	end

	-- Calculate attributes
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

	-- Add attribute bonuses
	modDB:NewMod("Life", "BASE", m_floor(output.Str / 2), "Strength")
	local strDmgBonusRatioOverride = modDB:Sum("BASE", nil, "StrDmgBonusRatioOverride")
	if strDmgBonusRatioOverride > 0 then
		actor.strDmgBonus = round((output.Str + modDB:Sum("BASE", nil, "DexIntToMeleeBonus")) * strDmgBonusRatioOverride)
	else
		actor.strDmgBonus = round((output.Str + modDB:Sum("BASE", nil, "DexIntToMeleeBonus")) / 5)
	end
	modDB:NewMod("PhysicalDamage", "INC", actor.strDmgBonus, "Strength", ModFlag.Melee)
	modDB:NewMod("Accuracy", "BASE", output.Dex * 2, "Dexterity")
	if not modDB:Sum("FLAG", nil, "IronReflexes") then
		modDB:NewMod("Evasion", "INC", round(output.Dex / 5), "Dexterity")
	end
	modDB:NewMod("Mana", "BASE", round(output.Int / 2), "Intelligence")
	modDB:NewMod("EnergyShield", "INC", round(output.Int / 5), "Intelligence")

	-- Life/mana pools
	if modDB:Sum("FLAG", nil, "ChaosInoculation") then
		output.Life = 1
		condList["FullLife"] = true
	else
		local base = modDB:Sum("BASE", nil, "Life")
		local inc = modDB:Sum("INC", nil, "Life")
		local more = modDB:Sum("MORE", nil, "Life")
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
	output.Mana = round(calcLib.val(modDB, "Mana"))
	if breakdown then
		breakdown.Mana = breakdown.simple(nil, nil, output.Mana, "Mana")
	end

	-- Life/mana reservation
	for _, pool in pairs({"Life", "Mana"}) do
		local max = output[pool]
		local reserved
		if max > 0 then
			reserved = (actor["reserved_"..pool.."Base"] or 0) + m_ceil(max * (actor["reserved_"..pool.."Percent"] or 0) / 100)
			output[pool.."Reserved"] = reserved
			output[pool.."ReservedPercent"] = reserved / max * 100
			output[pool.."Unreserved"] = max - reserved
			output[pool.."UnreservedPercent"] = (max - reserved) / max * 100
			if (max - reserved) / max <= 0.35 then
				condList["Low"..pool] = true
			end
		else
			reserved = 0
		end
		for _, value in ipairs(modDB:Sum("LIST", nil, "GrantReserved"..pool.."AsAura")) do
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
	output.PowerChargesMax = modDB:Sum("BASE", nil, "PowerChargesMax")
	output.FrenzyChargesMax = modDB:Sum("BASE", nil, "FrenzyChargesMax")
	output.EnduranceChargesMax = modDB:Sum("BASE", nil, "EnduranceChargesMax")
	output.SiphoningChargesMax = modDB:Sum("BASE", nil, "SiphoningChargesMax")
	output.CrabBarriersMax = modDB:Sum("BASE", nil, "CrabBarriersMax")
	if modDB:Sum("FLAG", nil, "UsePowerCharges") then
		output.PowerCharges = modDB:Sum("OVERRIDE", nil, "PowerCharges") or output.PowerChargesMax
	else
		output.PowerCharges = 0
	end
	if modDB:Sum("FLAG", nil, "UseFrenzyCharges") then
		output.FrenzyCharges = modDB:Sum("OVERRIDE", nil, "FrenzyCharges") or output.FrenzyChargesMax
	else
		output.FrenzyCharges = 0
	end
	if modDB:Sum("FLAG", nil, "UseEnduranceCharges") then
		output.EnduranceCharges = modDB:Sum("OVERRIDE", nil, "EnduranceCharges") or output.EnduranceChargesMax
	else
		output.EnduranceCharges = 0
	end
	if modDB:Sum("FLAG", nil, "UseSiphoningCharges") then
		output.SiphoningCharges = modDB:Sum("OVERRIDE", nil, "SiphoningCharges") or output.SiphoningChargesMax
	else
		output.SiphoningCharges = 0
	end
	output.CrabBarriers = m_min(modDB:Sum("OVERRIDE", nil, "CrabBarriers") or output.CrabBarriersMax, output.CrabBarriersMax)
	modDB.multipliers["PowerCharge"] = output.PowerCharges
	modDB.multipliers["FrenzyCharge"] = output.FrenzyCharges
	modDB.multipliers["EnduranceCharge"] = output.EnduranceCharges
	modDB.multipliers["SiphoningCharge"] = output.SiphoningCharges
	modDB.multipliers["CrabBarrier"] = output.CrabBarriers

	-- Process enemy modifiers 
	for _, value in ipairs(modDB:Sum("LIST", nil, "EnemyModifier")) do
		enemyDB:AddMod(value.mod)
	end

	-- Add misc buffs/debuffs
	if env.mode_combat then
		if modDB:Sum("FLAG", nil, "Fortify") then
			local effect = m_floor(20 * (1 + modDB:Sum("INC", nil, "FortifyEffectOnSelf", "BuffEffectOnSelf") / 100))
			modDB:NewMod("DamageTakenWhenHit", "INC", -effect, "Fortify")
			modDB.multipliers["BuffOnSelf"] = (modDB.multipliers["BuffOnSelf"] or 0) + 1
		end
		if modDB:Sum("FLAG", nil, "Onslaught") then
			local effect = m_floor(20 * (1 + modDB:Sum("INC", nil, "OnslaughtEffect", "BuffEffectOnSelf") / 100))
			modDB:NewMod("Speed", "INC", effect, "Onslaught")
			modDB:NewMod("MovementSpeed", "INC", effect, "Onslaught")
		end
		if modDB:Sum("FLAG", nil, "UnholyMight") then
			local effect = m_floor(30 * (1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100))
			modDB:NewMod("PhysicalDamageGainAsChaos", "BASE", effect, "Unholy Might")
		end
		if modDB:Sum("FLAG", nil, "Tailwind") then
			local effect = m_floor(10 * (1 + modDB:Sum("INC", nil, "TailwindEffectOnSelf", "BuffEffectOnSelf") / 100))
			modDB:NewMod("ActionSpeed", "INC", effect, "Tailwind")
		end
		if modDB:Sum("FLAG", nil, "Adrenaline") then
			local effectMod = 1 + modDB:Sum("INC", nil, "BuffEffectOnSelf") / 100
			modDB:NewMod("Damage", "INC", m_floor(100 * effectMod), "Adrenaline")
			modDB:NewMod("Speed", "INC", m_floor(25 * effectMod), "Adrenaline")
			modDB:NewMod("MovementSpeed", "INC", m_floor(25 * effectMod), "Adrenaline")
			modDB:NewMod("PhysicalDamageReduction", "BASE", m_floor(10 * effectMod), "Adrenaline")
		end
		if modDB:Sum("FLAG", nil, "HerEmbrace") then
			condList["HerEmbrace"] = true
			modDB:NewMod("AvoidStun", "BASE", 100, "Her Embrace")
			modDB:NewMod("PhysicalDamageGainAsFire", "BASE", 123, "Her Embrace", ModFlag.Sword)
			modDB:NewMod("AvoidFreeze", "BASE", 100, "Her Embrace")
			modDB:NewMod("AvoidChill", "BASE", 100, "Her Embrace")
			modDB:NewMod("AvoidIgnite", "BASE", 100, "Her Embrace")
			modDB:NewMod("Speed", "INC", 20, "Her Embrace")
			modDB:NewMod("MovementSpeed", "INC", 20, "Her Embrace")
		end
		if modDB:Sum("FLAG", nil, "Chill") then
			local effect = m_max(m_floor(30 * calcLib.mod(modDB, nil, "SelfChillEffect")), 0)
			modDB:NewMod("ActionSpeed", "INC", effect * (modDB:Sum("FLAG", nil, "SelfChillEffectIsReversed") and 1 or -1), "Chill")
		end
		if modDB:Sum("FLAG", nil, "Freeze") then
			local effect = m_max(m_floor(70 * calcLib.mod(modDB, nil, "SelfChillEffect")), 0)
			modDB:NewMod("ActionSpeed", "INC", -effect, "Freeze")
		end
	end	
end

-- Finalises the environment and performs the stat calculations:
-- 1. Merges keystone modifiers
-- 2. Initialises minion skills
-- 3. Initialises the main skill's minion, if present
-- 4. Merges flask effects
-- 5. Calculates reservations
-- 6. Sets conditions and calculates attributes and life/mana pools (doActorAttribsPoolsConditions)
-- 7. Processes buffs and debuffs
-- 8. Processes charges and misc buffs (doActorMisc)
-- 9. Calculates defence and offence stats (calcs.defence, calcs.offence)
function calcs.perform(env)
	local modDB = env.modDB
	local enemyDB = env.enemyDB

	-- Merge keystone modifiers
	env.keystonesAdded = { }
	mergeKeystones(env)

	-- Build minion skills
	for _, activeSkill in ipairs(env.activeSkillList) do
		if activeSkill.minion then
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
		env.minion.enemy = env.enemy
		env.minion.modDB = common.New("ModDB")
		env.minion.modDB.actor = env.minion
		env.minion.modDB.multipliers["Level"] = env.minion.level
		calcs.initModDB(env, env.minion.modDB)
		env.minion.modDB:NewMod("Life", "BASE", m_floor(env.data.monsterAllyLifeTable[env.minion.level] * env.minion.minionData.life), "Base")
		if env.minion.minionData.energyShield then
			env.minion.modDB:NewMod("EnergyShield", "BASE", m_floor(env.data.monsterAllyLifeTable[env.minion.level] * env.minion.minionData.life * env.minion.minionData.energyShield), "Base")
		end
		env.minion.modDB:NewMod("Evasion", "BASE", env.data.monsterEvasionTable[env.minion.level], "Base")
		env.minion.modDB:NewMod("Accuracy", "BASE", env.data.monsterAccuracyTable[env.minion.level], "Base")
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
		if env.build.targetVersion ~= "2_6" then
			env.minion.modDB:NewMod("Damage", "MORE", -50, "Base", 0, KeywordFlag.Poison)
			env.minion.modDB:NewMod("Damage", "MORE", -50, "Base", 0, KeywordFlag.Ignite)
			env.minion.modDB:NewMod("SkillData", "LIST", { key = "bleedBasePercent", value = 70/6 }, "Base")
		end
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
		if modDB:Sum("FLAG", nil, "StrengthAddedToMinions") then
			env.minion.modDB:NewMod("Str", "BASE", round(calcLib.val(modDB, "Str")), "Player")
		end
		if modDB:Sum("FLAG", nil, "HalfStrengthAddedToMinions") then
			env.minion.modDB:NewMod("Str", "BASE", round(calcLib.val(modDB, "Str") * 0.5), "Player")
		end
	end
	if env.aegisModList then
		env.player.itemList["Weapon 2"] = nil
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
		for item in pairs(env.flasks) do
			-- Avert thine eyes, lest they be forever scarred
			-- I have no idea how to determine which buff is applied by a given flask, 
			-- so utility flasks are grouped by base, unique flasks are grouped by name, and magic flasks by their modifiers
			local effectMod = 1 + (effectInc + item.flaskData.effectInc) / 100
			if item.buffModList[1] then
				local srcList = common.New("ModList")
				srcList:ScaleAddList(item.buffModList, effectMod)
				mergeBuff(srcList, flaskBuffs, item.baseName)
			end
			if item.modList[1] then
				local srcList = common.New("ModList")
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
		if not modDB:Sum("FLAG", nil, "FlasksDoNotApplyToPlayer") then
			for _, buffModList in pairs(flaskBuffs) do
				modDB.conditions["UsingFlask"] = true
				modDB:AddList(buffModList)
			end
		end
		if env.minion and modDB:Sum("FLAG", env.player.mainSkill.skillCfg, "FlasksApplyToMinion") then
			for _, buffModList in pairs(flaskBuffs) do
				env.minion.modDB.conditions["UsingFlask"] = true
				env.minion.modDB:AddList(buffModList)
			end
		end
	end

	-- Merge keystones again to catch any that were added by flasks
	mergeKeystones(env)

	-- Calculate skill life and mana reservations
	env.player.reserved_LifeBase = 0
	env.player.reserved_LifePercent = modDB:Sum("BASE", nil, "ExtraLifeReserved") 
	env.player.reserved_ManaBase = 0
	env.player.reserved_ManaPercent = 0
	if breakdown then
		breakdown.LifeReserved = { reservations = { } }
		breakdown.ManaReserved = { reservations = { } }
	end
	for _, activeSkill in ipairs(env.activeSkillList) do
		if activeSkill.skillTypes[SkillType.ManaCostReserved] and not activeSkill.skillFlags.totem then
			local skillModList = activeSkill.skillModList
			local skillCfg = activeSkill.skillCfg
			local suffix = activeSkill.skillTypes[SkillType.ManaCostPercent] and "Percent" or "Base"
			local baseVal = activeSkill.skillData.manaCostOverride or activeSkill.skillData.manaCost or 0
			local mult = skillModList:Sum("MORE", skillCfg, "ManaCost")
			local more = modDB:Sum("MORE", skillCfg, "ManaReserved") * skillModList:Sum("MORE", skillCfg, "ManaReserved")
			local inc = modDB:Sum("INC", skillCfg, "ManaReserved") + skillModList:Sum("INC", skillCfg, "ManaReserved")
			local base = m_floor(baseVal * mult)
			local cost
			if activeSkill.skillData.manaCostForced then
				cost = activeSkill.skillData.manaCostForced
			else
				cost = m_max(base - m_modf(base * -m_floor((100 + inc) * more - 100) / 100), 0)
			end
			local pool
			if modDB:Sum("FLAG", skillCfg, "BloodMagic", "SkillBloodMagic") or skillModList:Sum("FLAG", skillCfg, "SkillBloodMagic") then
				pool = "Life"
			else
				pool = "Mana"
			end
			env.player["reserved_"..pool..suffix] = env.player["reserved_"..pool..suffix] + cost
			if breakdown then
				t_insert(breakdown[pool.."Reserved"].reservations, {
					skillName = activeSkill.activeGem.grantedEffect.name,
					base = baseVal .. (activeSkill.skillTypes[SkillType.ManaCostPercent] and "%" or ""),
					mult = mult ~= 1 and ("x "..mult),
					more = more ~= 1 and ("x "..more),
					inc = inc ~= 0 and ("x "..(1 + inc/100)),
					total = cost .. (activeSkill.skillTypes[SkillType.ManaCostPercent] and "%" or ""),
				})
			end
		end
	end
	
	-- Calculate attributes and life/mana pools
	doActorAttribsPoolsConditions(env, env.player)
	if env.minion then
		for _, source in ipairs({modDB, env.player.mainSkill.skillModList}) do
			for _, value in ipairs(source:Sum("LIST", env.player.mainSkill.skillCfg, "MinionModifier")) do
				env.minion.modDB:AddMod(value.mod)
			end
		end
		doActorAttribsPoolsConditions(env, env.minion)
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
							row.sourceName = s_format("%s%s ^7%d/%d", reqSource.sourceGem.color, reqSource.sourceGem.grantedEffect.name, reqSource.sourceGem.level, reqSource.sourceGem.quality)
						end
						t_insert(breakdown["Req"..attr].rowList, row)
					end
				end
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
	for _, value in ipairs(modDB:Sum("LIST", nil, "ExtraAuraEffect")) do
		t_insert(extraAuraModList, value.mod)
	end

	-- Combine buffs/debuffs 
	output.EnemyCurseLimit = modDB:Sum("BASE", nil, "EnemyCurseLimit")
	local buffs = { }
	env.buffs = buffs
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
	for _, activeSkill in ipairs(env.activeSkillList) do
		local skillModList = activeSkill.skillModList
		local skillCfg = activeSkill.skillCfg
		for _, buff in ipairs(activeSkill.buffList) do
			if buff.cond and not modDB:Sum("FLAG", nil, "Condition:"..buff.cond) then
				-- Nothing!
			elseif buff.type == "Buff" then
				if env.mode_buffs and (not activeSkill.skillFlags.totem or buff.allowTotemBuff) then
					local skillCfg = buff.activeSkillBuff and skillCfg
					local incSkill = buff.activeSkillBuff and skillModList:Sum("INC", skillCfg, "BuffEffect") or 0
					local moreSkill = buff.activeSkillBuff and skillModList:Sum("MORE", skillCfg, "BuffEffect") or 1
				 	if not buff.applyNotPlayer then
						activeSkill.buffSkill = true
						modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
						local srcList = common.New("ModList")
						local inc = modDB:Sum("INC", skillCfg, "BuffEffect", "BuffEffectOnSelf") + incSkill + (buff.activeSkillBuff and skillModList:Sum("INC", skillCfg, "BuffEffectOnPlayer") or 0)
						local more = modDB:Sum("MORE", skillCfg, "BuffEffect", "BuffEffectOnSelf") * moreSkill
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						mergeBuff(srcList, buffs, buff.name)
						if activeSkill.skillData.thisIsNotABuff then
							buffs[buff.name].notBuff = true
						end
					end
					if env.minion and (buff.applyMinions or buff.applyAllies) then
						activeSkill.minionBuffSkill = true
						env.minion.modDB.conditions["AffectedBy"..buff.name] = true
						local srcList = common.New("ModList")
						local inc = modDB:Sum("INC", skillCfg, "BuffEffect") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf") + incSkill
						local more = modDB:Sum("MORE", skillCfg, "BuffEffect") * env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf") * moreSkill
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						mergeBuff(srcList, minionBuffs, buff.name)
					end
				end
			elseif buff.type == "Aura" then
				if env.mode_buffs then
					if not activeSkill.skillData.auraCannotAffectSelf then
						activeSkill.buffSkill = true
						affectedByAura[env.player] = true
						modDB.conditions["AffectedBy"..buff.name:gsub(" ","")] = true
						local srcList = common.New("ModList")
						local inc = modDB:Sum("INC", skillCfg, "AuraEffect", "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
						local more = modDB:Sum("MORE", skillCfg, "AuraEffect", "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						srcList:ScaleAddList(extraAuraModList, (1 + inc / 100) * more)
						mergeBuff(srcList, buffs, buff.name)
					end
					if env.minion and not modDB:Sum("FLAG", nil, "YourAurasCannotAffectAllies") then
						activeSkill.minionBuffSkill = true
						affectedByAura[env.minion] = true
						env.minion.modDB.conditions["AffectedBy"..buff.name] = true
						local srcList = common.New("ModList")
						local inc = modDB:Sum("INC", skillCfg, "AuraEffect") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
						local more = modDB:Sum("MORE", skillCfg, "AuraEffect") * env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
						srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						srcList:ScaleAddList(extraAuraModList, (1 + inc / 100) * more)
						mergeBuff(srcList, minionBuffs, buff.name)
					end
				end
			elseif buff.type == "Debuff" then
				local stackCount = activeSkill.skillData.stackCount or 1
				if env.mode_effective and stackCount > 0 then
					activeSkill.debuffSkill = true
					local srcList = common.New("ModList")
					srcList:ScaleAddList(buff.modList, stackCount)
					if activeSkill.skillData.stackCount then
						srcList:NewMod("Multiplier:"..buff.name.."Stack", "BASE", activeSkill.skillData.stackCount, buff.name)
					end
					mergeBuff(srcList, debuffs, buff.name)
				end
			elseif buff.type == "Curse" or buff.type == "CurseBuff" then
				if env.mode_effective and (not enemyDB:Sum("FLAG", nil, "Hexproof") or modDB:Sum("FLAG", nil, "CursesIgnoreHexproof")) then
					local curse = {
						name = buff.name,
						fromPlayer = true,
						priority = activeSkill.skillTypes[SkillType.Aura] and 3 or 1,
					}
					local inc = modDB:Sum("INC", skillCfg, "CurseEffect") + enemyDB:Sum("INC", nil, "CurseEffectOnSelf") + skillModList:Sum("INC", skillCfg, "CurseEffect")
					local more = modDB:Sum("MORE", skillCfg, "CurseEffect") * enemyDB:Sum("MORE", nil, "CurseEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "CurseEffect")
					if buff.type == "Curse" then
						curse.modList = common.New("ModList")
						curse.modList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
					else
						-- Curse applies a buff; scale by curse effect, then buff effect
						local temp = common.New("ModList")
						temp:ScaleAddList(buff.modList, (1 + inc / 100) * more)
						curse.buffModList = common.New("ModList")
						local buffInc = modDB:Sum("INC", skillCfg, "BuffEffectOnSelf")
						local buffMore = modDB:Sum("MORE", skillCfg, "BuffEffectOnSelf")
						curse.buffModList:ScaleAddList(temp, (1 + buffInc / 100) * buffMore)
						if env.minion then
							curse.minionBuffModList = common.New("ModList")
							local buffInc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf")
							local buffMore = env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf")
							curse.minionBuffModList:ScaleAddList(temp, (1 + buffInc / 100) * buffMore)
						end
					end
					t_insert(curses, curse)	
				end
			end
		end
		if activeSkill.minion then
			for _, activeSkill in ipairs(activeSkill.minion.activeSkillList) do
				local skillModList = activeSkill.skillModList
				local skillCfg = activeSkill.skillCfg
				for _, buff in ipairs(activeSkill.buffList) do
					if buff.type == "Aura" then
						if env.mode_buffs and activeSkill.skillData.enable then
							if not modDB:Sum("FLAG", nil, "AlliesAurasCannotAffectSelf") then
								local srcList = common.New("ModList")
								local inc = modDB:Sum("INC", skillCfg, "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
								local more = modDB:Sum("MORE", skillCfg, "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
								srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
								mergeBuff(srcList, buffs, buff.name)
							end
							if env.minion and (env.minion ~= activeSkill.minion or not activeSkill.skillData.auraCannotAffectSelf) then
								local srcList = common.New("ModList")
								local inc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
								local more = env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
								srcList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
								mergeBuff(srcList, minionBuffs, buff.name)
							end
						end
					elseif buff.type == "Curse" then
						if env.mode_effective and activeSkill.skillData.enable and not enemyDB:Sum("FLAG", nil, "Hexproof") then
							local curse = {
								name = buff.name,
								priority = 1,
							}
							local inc = enemyDB:Sum("INC", nil, "CurseEffectOnSelf") + skillModList:Sum("INC", skillCfg, "CurseEffect")
							local more = enemyDB:Sum("MORE", nil, "CurseEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "CurseEffect")
							curse.modList = common.New("ModList")
							curse.modList:ScaleAddList(buff.modList, (1 + inc / 100) * more)
							t_insert(minionCurses, curse)
						end
					end
				end
			end
		end
	end

	-- Check for extra curses
	for dest, modDB in pairs({[curses] = modDB, [minionCurses] = env.minion and env.minion.modDB}) do
		for _, value in ipairs(modDB:Sum("LIST", nil, "ExtraCurse")) do
			local gemModList = common.New("ModList")
			calcs.mergeGemMods(gemModList, {
				level = value.level,
				quality = 0,
				grantedEffect = env.data.gems[value.name],
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
					local cfg = { skillName = value.name }
					local inc = modDB:Sum("INC", cfg, "CurseEffectOnSelf") + gemModList:Sum("INC", nil, "CurseEffectAgainstPlayer")
					local more = modDB:Sum("MORE", cfg, "CurseEffectOnSelf")
					modDB:ScaleAddList(curseModList, (1 + inc / 100) * more)
				end
			elseif not enemyDB:Sum("FLAG", nil, "Hexproof") or modDB:Sum("FLAG", nil, "CursesIgnoreHexproof") then
				local curse = {
					name = value.name,
					fromPlayer = (dest == curses),
					priority = 2,
				}
				curse.modList = common.New("ModList")
				curse.modList:ScaleAddList(curseModList, (1 + enemyDB:Sum("INC", nil, "CurseEffectOnSelf") / 100) * enemyDB:Sum("MORE", nil, "CurseEffectOnSelf"))
				t_insert(dest, curse)
			end
		end
	end

	-- Assign curses to slots
	local curseSlots = { }
	env.curseSlots = curseSlots
	for _, source in ipairs({curses, minionCurses}) do
		for _, curse in ipairs(source) do
			local slot
			for i = 1, source.limit do
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
				curseSlots[slot] = curse
			end
		end
	end

	-- Apply buff/debuff modifiers
	for _, modList in pairs(buffs) do
		modDB:AddList(modList)
		if not modList.notBuff then
			modDB.multipliers["BuffOnSelf"] = (modDB.multipliers["BuffOnSelf"] or 0) + 1
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

	-- Check for extra auras
	for _, value in ipairs(modDB:Sum("LIST", nil, "ExtraAura")) do
		local modList = { value.mod }
		if not value.onlyAllies then
			local inc = modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			local more = modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			modDB:ScaleAddList(modList, (1 + inc / 100) * more)
			if not value.notBuff then
				modDB.multipliers["BuffOnSelf"] = (modDB.multipliers["BuffOnSelf"] or 0) + 1
			end
		end
		if env.minion and not modDB:Sum("FLAG", nil, "SelfAurasCannotAffectAllies") then
			local inc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			local more = env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			env.minion.modDB:ScaleAddList(modList, (1 + inc / 100) * more)
		end
	end

	-- Check for modifiers to apply to actors affected by player auras or curses
	for _, value in ipairs(modDB:Sum("LIST", nil, "AffectedByAuraMod")) do
		for actor in pairs(affectedByAura) do
			actor.modDB:AddMod(value.mod)
		end
	end
	for _, value in ipairs(modDB:Sum("LIST", nil, "AffectedByCurseMod")) do
		for actor in pairs(affectedByCurse) do
			actor.modDB:AddMod(value.mod)
		end
	end

	-- Merge keystones again to catch any that were added by buffs
	mergeKeystones(env)

	-- Special handling for Dancing Dervish
	if modDB:Sum("FLAG", nil, "DisableWeapons") then
		env.player.weaponData1 = copyTable(env.data.unarmedWeaponData[env.classId])
		modDB.conditions["Unarmed"] = true
	elseif env.weaponModList1 then
		modDB:AddList(env.weaponModList1)
	end

	-- Process misc buffs/modifiers
	doActorMisc(env, env.player)
	if env.minion then
		doActorMisc(env, env.minion)
	end
	doActorMisc(env, env.enemy)

	-- Defence/offence calculations
	calcs.defence(env, env.player)
	calcs.offence(env, env.player)
	if env.minion then
		calcs.defence(env, env.minion)
		calcs.offence(env, env.minion)
	end
end