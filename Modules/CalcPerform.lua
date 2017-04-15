-- Path of Building
--
-- Module: Calc Perform
-- Manages the offence/defence calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_ceil = math.ceil
local m_floor = math.floor
local s_format = string.format

local tempTable1 = { }

-- Merge an instance of a buff, taking the highest value of each modifier
local function mergeBuff(src, destTable, destKey)
	if not destTable[destKey] then
		destTable[destKey] = { }
	end
	local dest = destTable[destKey]
	for _, mod in ipairs(src) do
		local param = modLib.formatModParams(mod)
		for index, destMod in ipairs(dest) do
			if param == modLib.formatModParams(destMod) then
				if type(destMod.value) == "number" and mod.value > destMod.value then
					dest[index] = mod
				end
				param = nil
				break
			end
		end
		if param then
			t_insert(dest, mod)
		end
	end
end

-- Calculate attributes and life/mana pools, and set conditions
local function doActorAttribsPoolsConditions(env, actor)
	local modDB = actor.modDB
	local output = actor.output
	local breakdown = actor.breakdown
	local condList = modDB.conditions

	-- Calculate attributes
	for _, stat in pairs({"Str","Dex","Int"}) do
		output[stat] = round(calcLib.val(modDB, stat))
		if breakdown then
			breakdown[stat] = breakdown.simple(nil, nil, output[stat], stat)
		end
	end

	-- Add attribute bonuses
	modDB:NewMod("Life", "BASE", m_floor(output.Str / 2), "Strength")
	actor.strDmgBonus = round((output.Str + modDB:Sum("BASE", nil, "DexIntToMeleeBonus")) / 5)
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
		modDB.conditions["FullLife"] = true
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
		if reserved == 0 then
			condList["No"..pool.."Reserved"] = true
		end
		for _, value in ipairs(modDB:Sum("LIST", nil, "GrantReserved"..pool.."AsAura")) do
			local auraMod = copyTable(value.mod)
			auraMod.value = m_floor(auraMod.value * reserved)
			modDB:NewMod("ExtraAura", "LIST", { mod = auraMod })
		end
	end

	-- Set conditions
	if actor.weaponData1.type == "Staff" then
		condList["UsingStaff"] = true
	end
	if actor.weaponData1.type == "Bow" then
		condList["UsingBow"] = true
	end
	if actor.itemList["Weapon 2"] and actor.itemList["Weapon 2"].type == "Shield" then
		condList["UsingShield"] = true
	end
	if actor.weaponData1.type and actor.weaponData2.type then
		condList["DualWielding"] = true
		if actor.weaponData1.type == "Claw" and actor.weaponData2.type == "Claw" then
			condList["DualWieldingClaws"] = true
		end
	end
	if actor.weaponData1.type == "None" then
		condList["Unarmed"] = true
	end
	if (modDB.multipliers["NormalItem"] or 0) > 0 then
		condList["UsingNormalItem"] = true
	end
	if (modDB.multipliers["MagicItem"] or 0) > 0 then
		condList["UsingMagicItem"] = true
	end
	if (modDB.multipliers["RareItem"] or 0) > 0 then
		condList["UsingRareItem"] = true
	end
	if (modDB.multipliers["UniqueItem"] or 0) > 0 then
		condList["UsingUniqueItem"] = true
	end
	if (modDB.multipliers["CorruptedItem"] or 0) > 0 then
		condList["UsingCorruptedItem"] = true
	else
		condList["NotUsingCorruptedItem"] = true
	end
	if env.mode_buffs then
		condList["Buffed"] = true
	end
	if env.mode_combat then
		condList["Combat"] = true
		if not modDB:Sum("FLAG", nil, "NeverCrit") then
			condList["CritInPast8Sec"] = true
		end
		if not actor.mainSkill.skillData.triggered then 
			if actor.mainSkill.skillFlags.attack then
				condList["AttackedRecently"] = true
			elseif actor.mainSkill.skillFlags.spell then
				condList["CastSpellRecently"] = true
			end
		end
		if actor.mainSkill.skillFlags.hit and not actor.mainSkill.skillFlags.trap and not actor.mainSkill.skillFlags.mine and not actor.mainSkill.skillFlags.totem then
			condList["HitRecently"] = true
		end
		if actor.mainSkill.skillFlags.movement then
			condList["UsedMovementSkillRecently"] = true
		end
		if actor.mainSkill.skillFlags.totem then
			condList["HaveTotem"] = true
			condList["SummonedTotemRecently"] = true
		end
		if actor.mainSkill.skillFlags.mine then
			condList["DetonatedMinesRecently"] = true
		end
	end
	if env.mode_effective then
		condList["Effective"] = true
	end
end

-- Process charges, misc modifiers, and other buffs
local function doActorMisc(env, actor)
	local modDB = actor.modDB
	local enemyDB = actor.enemy.modDB
	local output = actor.output
	local condList = modDB.conditions

	-- Calculate current and maximum charges
	output.PowerChargesMax = modDB:Sum("BASE", nil, "PowerChargesMax")
	output.FrenzyChargesMax = modDB:Sum("BASE", nil, "FrenzyChargesMax")
	output.EnduranceChargesMax = modDB:Sum("BASE", nil, "EnduranceChargesMax")
	if actor.config.usePowerCharges and env.mode_combat then
		output.PowerCharges = output.PowerChargesMax
	else
		output.PowerCharges = 0
	end
	if actor.config.useFrenzyCharges and env.mode_combat then
		output.FrenzyCharges = output.FrenzyChargesMax
	else
		output.FrenzyCharges = 0
	end
	if actor.config.useEnduranceCharges and env.mode_combat then
		output.EnduranceCharges = output.EnduranceChargesMax
	else
		output.EnduranceCharges = 0
	end
	modDB.multipliers["PowerCharge"] = output.PowerCharges
	modDB.multipliers["FrenzyCharge"] = output.FrenzyCharges
	modDB.multipliers["EnduranceCharge"] = output.EnduranceCharges
	if output.PowerCharges == 0 then
		condList["HaveNoPowerCharges"] = true
	end
	if output.PowerCharges == output.PowerChargesMax then
		condList["AtMaxPowerCharges"] = true
	end
	if output.FrenzyCharges == 0 then
		condList["HaveNoFrenzyCharges"] = true
	end
	if output.FrenzyCharges == output.FrenzyChargesMax then
		condList["AtMaxFrenzyCharges"] = true
	end
	if output.EnduranceCharges == 0 then
		condList["HaveNoEnduranceCharges"] = true
	end
	if output.EnduranceCharges == output.EnduranceChargesMax then
		condList["AtMaxEnduranceCharges"] = true
	end

	-- Process misc modifiers
	for _, value in ipairs(modDB:Sum("LIST", nil, "Misc")) do
		if value.type == "Condition" then
			condList[value.var] = true
		elseif value.type == "EnemyCondition" then
			enemyDB.conditions[value.var] = true
		elseif value.type == "Multiplier" then
			modDB.multipliers[value.var] = (modDB.multipliers[value.var] or 0) + value.value
		end
	end
	-- Process enemy modifiers last in case they depend on conditions that were set by misc modifiers
	for _, value in ipairs(modDB:Sum("LIST", nil, "Misc")) do
		if value.type == "EnemyModifier" then
			enemyDB:AddMod(value.mod)
		end
	end

	-- Process conditions that can depend on other conditions
	if condList["Ignited"] then
		condList["Burning"] = true
	end

	-- Add misc buffs
	if env.mode_combat then
		if condList["Onslaught"] then
			local effect = m_floor(20 * (1 + modDB:Sum("INC", nil, "OnslaughtEffect", "BuffEffect") / 100))
			modDB:NewMod("Speed", "INC", effect, "Onslaught")
			modDB:NewMod("MovementSpeed", "INC", effect, "Onslaught")
		end
		if condList["UnholyMight"] then
			local effect = m_floor(30 * (1 + modDB:Sum("INC", nil, "BuffEffect") / 100))
			modDB:NewMod("PhysicalDamageGainAsChaos", "BASE", effect, "Unholy Might")
		end
	end	
end

-- Finalise environment and perform the calculations
function calcs.perform(env)
	local modDB = env.modDB
	local enemyDB = env.enemyDB

	-- Merge keystone modifiers
	do
		local keystoneList = wipeTable(tempTable1)
		for _, name in ipairs(modDB:Sum("LIST", nil, "Keystone")) do
			keystoneList[name] = true
		end
		for name in pairs(keystoneList) do
			modDB:AddList(env.build.tree.keystoneMap[name].modList)
		end
	end

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
		calcs.initModDB(env.minion.modDB)
		env.minion.modDB:NewMod("Life", "BASE", m_floor(data.monsterLifeTable[env.minion.level] * env.minion.minionData.life), "Base")
		if env.minion.minionData.energyShield then
			env.minion.modDB:NewMod("EnergyShield", "BASE", m_floor(data.monsterLifeTable[env.minion.level] * env.minion.minionData.life * env.minion.minionData.energyShield), "Base")
		end
		env.minion.modDB:NewMod("Evasion", "BASE", data.monsterEvasionTable[env.minion.level], "Base")
		env.minion.modDB:NewMod("Accuracy", "BASE", data.monsterAccuracyTable[env.minion.level], "Base")
		env.minion.modDB:NewMod("CritMultiplier", "BASE", 30, "Base")
		env.minion.modDB:NewMod("FireResist", "BASE", env.minion.minionData.fireResist, "Base")
		env.minion.modDB:NewMod("ColdResist", "BASE", env.minion.minionData.coldResist, "Base")
		env.minion.modDB:NewMod("LightningResist", "BASE", env.minion.minionData.lightningResist, "Base")
		env.minion.modDB:NewMod("ChaosResist", "BASE", env.minion.minionData.chaosResist, "Base")
		env.minion.modDB:NewMod("CritChance", "INC", 200, "Base", { type = "Multiplier", var = "PowerCharge" })
		env.minion.modDB:NewMod("Speed", "INC", 15, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		env.minion.modDB:NewMod("Damage", "MORE", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		env.minion.modDB:NewMod("MovementSpeed", "INC", 5, "Base", { type = "Multiplier", var = "FrenzyCharge" })
		env.minion.modDB:NewMod("ElementalResist", "BASE", 15, "Base", { type = "Multiplier", var = "EnduranceCharge" })
		env.minion.modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
		for _, mod in ipairs(env.minion.minionData.modList) do
			env.minion.modDB:AddMod(mod)
		end
		if env.aegisModList then
			env.minion.itemList["Weapon 2"] = env.player.itemList["Weapon 2"]
			env.player.itemList["Weapon 2"] = nil
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
		if modDB:Sum("FLAG", nil, "StrengthAddedToMinions") then
			env.minion.modDB:NewMod("Str", "BASE", round(calcLib.val(modDB, "Str")), "Player")
		end
	end

	local breakdown
	if env.mode == "CALCS" then
		-- Initialise breakdown module
		breakdown = LoadModule("Modules/CalcBreakdown", modDB, output, env.player)
		env.player.breakdown = breakdown
		if env.minion then
			env.minion.breakdown = LoadModule("Modules/CalcBreakdown", env.minion.modDB, env.minion.output, env.minion)
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

	-- Calculate skill life and mana reservations
	env.player.reserved_LifeBase = 0
	env.player.reserved_LifePercent = 0
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
			local baseVal = activeSkill.skillData.manaCostOverride or activeSkill.skillData.manaCost
			local suffix = activeSkill.skillTypes[SkillType.ManaCostPercent] and "Percent" or "Base"
			local mult = skillModList:Sum("MORE", skillCfg, "ManaCost")
			local more = modDB:Sum("MORE", skillCfg, "ManaReserved") * skillModList:Sum("MORE", skillCfg, "ManaReserved")
			local inc = modDB:Sum("INC", skillCfg, "ManaReserved") + skillModList:Sum("INC", skillCfg, "ManaReserved")
			local base = m_floor(baseVal * mult)
			local cost = base - m_floor(base * -m_floor((100 + inc) * more - 100) / 100)
			local pool
			if modDB:Sum("FLAG", skillCfg, "BloodMagic", "SkillBloodMagic") or skillModList:Sum("FLAG", skillCfg, "SkillBloodMagic") then
				pool = "Life"
			else
				pool = "Mana"
			end
			env.player["reserved_"..pool..suffix] = env.player["reserved_"..pool..suffix] + cost
			if breakdown then
				t_insert(breakdown[pool.."Reserved"].reservations, {
					skillName = activeSkill.activeGem.name,
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
			for _, value in ipairs(source:Sum("LIST", env.player.mainSkill.skillCfg, "Misc")) do
				if value.type == "MinionModifier" then
					env.minion.modDB:AddMod(value.mod)
				end
			end
		end
		doActorAttribsPoolsConditions(env, env.minion)
	end

	-- Check for extra modifiers to apply to aura skills
	local extraAuraModList = { }
	for _, value in ipairs(modDB:Sum("LIST", nil, "ExtraAuraEffect")) do
		t_insert(extraAuraModList, value.mod)
	end

	-- Combine buffs/debuffs 
	output.EnemyCurseLimit = modDB:Sum("BASE", nil, "EnemyCurseLimit")
	local buffs = { }
	local minionBuffs = { }
	local debuffs = { }
	local curses = { 
		limit = output.EnemyCurseLimit,
	}
	local minionCurses = { 
		limit = 1,
	}
	local affectedByAuras = { }
	for _, activeSkill in ipairs(env.activeSkillList) do
		local skillModList = activeSkill.skillModList
		local skillCfg = activeSkill.skillCfg
		if env.mode_buffs then
			if activeSkill.buffModList and 
			   not activeSkill.skillFlags.curse and
			   (not activeSkill.skillFlags.totem or activeSkill.skillData.allowTotemBuff) then
				if (not activeSkill.skillData.offering or modDB:Sum("FLAG", nil, "OfferingsAffectPlayer")) then
					activeSkill.buffSkill = true
					local srcList = common.New("ModList")
					local inc = modDB:Sum("INC", skillCfg, "BuffEffect", "BuffEffectOnSelf")
					local more = modDB:Sum("MORE", skillCfg, "BuffEffect", "BuffEffectOnSelf")
					srcList:ScaleAddList(activeSkill.buffModList, (1 + inc / 100) * more)
					mergeBuff(srcList, buffs, activeSkill.activeGem.name)
				end
				if activeSkill.skillData.offering and env.minion then
					activeSkill.minionBuffSkill = true
					local srcList = common.New("ModList")
					local inc = modDB:Sum("INC", skillCfg, "BuffEffect") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf")
					local more = modDB:Sum("MORE", skillCfg, "BuffEffect") * env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf")
					srcList:ScaleAddList(activeSkill.buffModList, (1 + inc / 100) * more)
					mergeBuff(srcList, minionBuffs, activeSkill.activeGem.name)
				end
			end
			if activeSkill.auraModList then
				if not activeSkill.skillData.auraCannotAffectSelf then
					activeSkill.buffSkill = true
					affectedByAuras[env.player] = true
					local srcList = common.New("ModList")
					local inc = modDB:Sum("INC", skillCfg, "AuraEffect", "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
					local more = modDB:Sum("MORE", skillCfg, "AuraEffect", "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
					srcList:ScaleAddList(activeSkill.auraModList, (1 + inc / 100) * more)
					srcList:ScaleAddList(extraAuraModList, (1 + inc / 100) * more)
					mergeBuff(srcList, buffs, activeSkill.activeGem.name)
				end
				if env.minion and not modDB:Sum("FLAG", nil, "YourAurasCannotAffectAllies") then
					activeSkill.minionBuffSkill = true
					affectedByAuras[env.minion] = true
					local srcList = common.New("ModList")
					local inc = modDB:Sum("INC", skillCfg, "AuraEffect") + env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
					local more = modDB:Sum("MORE", skillCfg, "AuraEffect") * env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
					srcList:ScaleAddList(activeSkill.auraModList, (1 + inc / 100) * more)
					srcList:ScaleAddList(extraAuraModList, (1 + inc / 100) * more)
					mergeBuff(srcList, minionBuffs, activeSkill.activeGem.name)
				end
			end
			if activeSkill.minion then
				for _, activeSkill in ipairs(activeSkill.minion.activeSkillList) do
					local skillModList = activeSkill.skillModList
					local skillCfg = activeSkill.skillCfg
					if activeSkill.auraModList and activeSkill.skillData.enable then
						if not modDB:Sum("FLAG", nil, "AlliesAurasCannotAffectSelf") then
							local srcList = common.New("ModList")
							local inc = modDB:Sum("INC", skillCfg, "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
							local more = modDB:Sum("MORE", skillCfg, "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
							srcList:ScaleAddList(activeSkill.auraModList, (1 + inc / 100) * more)
							mergeBuff(srcList, buffs, activeSkill.activeGem.data.id)
						end
						if env.minion and (env.minion ~= activeSkill.minion or not activeSkill.skillData.auraCannotAffectSelf) then
							local srcList = common.New("ModList")
							local inc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") + skillModList:Sum("INC", skillCfg, "AuraEffect")
							local more = env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "AuraEffect")
							srcList:ScaleAddList(activeSkill.auraModList, (1 + inc / 100) * more)
							mergeBuff(srcList, minionBuffs, activeSkill.activeGem.data.id)
						end
					end
				end
			end
		end
		if env.mode_effective then
			if activeSkill.debuffModList then
				activeSkill.debuffSkill = true
				local srcList = common.New("ModList")
				srcList:ScaleAddList(activeSkill.debuffModList, activeSkill.skillData.stackCount or 1)
				mergeBuff(srcList, debuffs, activeSkill.activeGem.name)
			end
			if activeSkill.curseModList or (activeSkill.skillFlags.curse and activeSkill.buffModList) then
				local curse = {
					name = activeSkill.activeGem.name,
					priority = activeSkill.skillTypes[SkillType.Aura] and 3 or 1,
				}
				local inc = modDB:Sum("INC", skillCfg, "CurseEffect") + enemyDB:Sum("INC", nil, "CurseEffectOnSelf") + skillModList:Sum("INC", skillCfg, "CurseEffect")
				local more = modDB:Sum("MORE", skillCfg, "CurseEffect") * enemyDB:Sum("MORE", nil, "CurseEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "CurseEffect")
				if activeSkill.curseModList then
					curse.modList = common.New("ModList")
					curse.modList:ScaleAddList(activeSkill.curseModList, (1 + inc / 100) * more)
				end
				if activeSkill.buffModList then
					-- Curse applies a buff; scale by curse effect, then buff effect
					local temp = common.New("ModList")
					temp:ScaleAddList(activeSkill.buffModList, (1 + inc / 100) * more)
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
			if activeSkill.minion then
				for _, activeSkill in ipairs(activeSkill.minion.activeSkillList) do
					local skillModList = activeSkill.skillModList
					local skillCfg = activeSkill.skillCfg
					if activeSkill.curseModList and activeSkill.skillData.enable then
						local curse = {
							name = activeSkill.activeGem.name,
							priority = 1,
						}
						local inc = enemyDB:Sum("INC", nil, "CurseEffectOnSelf") + skillModList:Sum("INC", skillCfg, "CurseEffect")
						local more = enemyDB:Sum("MORE", nil, "CurseEffectOnSelf") * skillModList:Sum("MORE", skillCfg, "CurseEffect")
						curse.modList = common.New("ModList")
						curse.modList:ScaleAddList(activeSkill.curseModList, (1 + inc / 100) * more)
						t_insert(minionCurses, curse)
					end
				end
			end
		end
	end

	-- Check for extra curses
	for _, value in ipairs(modDB:Sum("LIST", nil, "ExtraCurse")) do
		local curse = {
			name = value.name,
			priority = 2,
			modList = common.New("ModList")
		}
		local gemModList = common.New("ModList")
		mergeGemMods(gemModList, {
			level = value.level,
			quality = 0,
			data = data.gems[value.name],
		})
		local curseModList = { }
		for _, mod in ipairs(gemModList) do
			for _, tag in ipairs(mod.tagList) do
				if tag.type == "GlobalEffect" and tag.effectType == "Curse" then
					t_insert(curseModList, mod)
					break
				end
			end
		end
		curse.modList:ScaleAddList(curseModList, (1 + enemyDB:Sum("INC", nil, "CurseEffectOnSelf") / 100) * enemyDB:Sum("MORE", nil, "CurseEffectOnSelf"))
		t_insert(curses, curse)
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
	for _, slot in ipairs(curseSlots) do
		modDB.conditions["EnemyCursed"] = true
		enemyDB.conditions["Cursed"] = true
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
		end
		if env.minion and not modDB:Sum("FLAG", nil, "SelfAurasCannotAffectAllies") then
			local inc = env.minion.modDB:Sum("INC", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			local more = env.minion.modDB:Sum("MORE", nil, "BuffEffectOnSelf", "AuraEffectOnSelf")
			env.minion.modDB:ScaleAddList(modList, (1 + inc / 100) * more)
		end
	end

	-- Check for modifiers to apply to actors affected by player auras
	for _, value in ipairs(modDB:Sum("LIST", nil, "AffectedByAuraMod")) do
		for actor in pairs(affectedByAuras) do
			actor.modDB:AddMod(value.mod)
		end
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