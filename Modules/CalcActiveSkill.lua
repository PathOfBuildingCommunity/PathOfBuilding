-- Path of Building
--
-- Module: Calc Active Skill
-- Active skill setup.
--
local calcs = ...

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local bor = bit.bor
local band = bit.band
local bnot = bit.bnot

-- Merge level modifier with give mod list
local function mergeLevelMod(modList, mod, value)
	local newMod = copyTable(mod)
	if type(newMod.value) == "table" then
		if newMod.value.mod then
			newMod.value.mod.value = value
		else
			newMod.value.value = value
		end
	else
		newMod.value = value
	end
	modList:AddMod(newMod)
end

-- Merge gem modifiers with given mod list
local function mergeGemMods(modList, gem)
	modList:AddList(gem.data.baseMods)
	if gem.quality > 0 then
		for i = 1, #gem.data.qualityMods do
			local scaledMod = copyTable(gem.data.qualityMods[i])
			if type(scaledMod.value) == "table" then
				if scaledMod.value.mod then
					scaledMod.value.mod.value = m_floor(scaledMod.value.mod.value * gem.quality)
				else
					scaledMod.value.value = m_floor(scaledMod.value.value * gem.quality)
				end
			else
				scaledMod.value = m_floor(scaledMod.value * gem.quality)
			end
			modList:AddMod(scaledMod)
		end
	end
	gem.level = m_max(gem.level, 1)
	if not gem.data.levels[gem.level] then
		gem.level = m_min(gem.level, #gem.data.levels)
	end
	local levelData = gem.data.levels[gem.level]
	for col, mod in pairs(gem.data.levelMods) do
		if levelData[col] then
			if mod[1] then
				for _, subMod in ipairs(mod) do
					mergeLevelMod(modList, subMod, levelData[col])
				end
			else
				mergeLevelMod(modList, mod, levelData[col])
			end
		end
	end
end

-- Create an active skill using the given active gem and list of support gems
-- It will determine the base flag set, and check which of the support gems can support this skill
function calcs.createActiveSkill(activeGem, supportList, summonSkill)
	local activeSkill = { }
	activeSkill.summonSkill = summonSkill
	activeSkill.supportList = supportList

	activeSkill.activeGem = {
		name = activeGem.name,
		data = activeGem.data,
		level = activeGem.level,
		quality = activeGem.quality,
		fromItem = activeGem.fromItem,
		srcGem = activeGem,
	}
	activeSkill.gemList = { activeSkill.activeGem }

	activeSkill.skillTypes = copyTable(activeGem.data.skillTypes)
	if activeGem.data.minionSkillTypes then
		activeSkill.minionSkillTypes = copyTable(activeGem.data.minionSkillTypes)
	end

	activeSkill.skillData = { }

	-- Initialise skill flag set ('attack', 'projectile', etc)
	local skillFlags = copyTable(activeGem.data.baseFlags)
	activeSkill.skillFlags = skillFlags
	skillFlags.hit = activeSkill.skillTypes[SkillType.Attack] or activeSkill.skillTypes[SkillType.Hit] or activeSkill.skillTypes[SkillType.Projectile]

	for _, gem in ipairs(supportList) do
		if calcLib.gemCanSupport(gem, activeSkill) then
			if gem.data.addFlags then
				-- Support gem adds flags to supported skills (eg. Remote Mine adds 'mine')
				for k in pairs(gem.data.addFlags) do
					skillFlags[k] = true
				end
			end
			for _, skillType in pairs(gem.data.addSkillTypes) do
				activeSkill.skillTypes[skillType] = true
			end
		end
	end

	-- Process support gems
	for _, gem in ipairs(supportList) do
		if calcLib.gemCanSupport(gem, activeSkill) then
			t_insert(activeSkill.gemList, {
				name = gem.name,
				data = gem.data,
				level = gem.level,
				quality = gem.quality,
				fromItem = gem.fromItem,
				srcGem = gem,
			})
			if gem.isSupporting then
				gem.isSupporting[activeGem.name] = true
			end
		end
	end

	return activeSkill
end

-- Get weapon flags and info for given weapon
local function getWeaponFlags(weaponData, weaponTypes)
	local info = data.weaponTypeInfo[weaponData.type]
	if not info then
		return
	end
	if weaponTypes and not weaponTypes[weaponData.type] and 
		(not weaponData.countsAsAll1H or not (weaponTypes["Claw"] or weaponTypes["Dagger"] or weaponTypes["One Handed Axe"] or weaponTypes["One Handed Mace"] or weaponTypes["One Handed Sword"])) then
		return
	end
	local flags = info.flag
	if weaponData.countsAsAll1H then
		flags = bor(ModFlag.Axe, ModFlag.Claw, ModFlag.Dagger, ModFlag.Mace, ModFlag.Sword)
	end
	if weaponData.type ~= "None" then
		flags = bor(flags, ModFlag.Weapon)
		if info.oneHand then
			flags = bor(flags, ModFlag.Weapon1H)
		else
			flags = bor(flags, ModFlag.Weapon2H)
		end
		if info.melee then
			flags = bor(flags, ModFlag.WeaponMelee)
		else
			flags = bor(flags, ModFlag.WeaponRanged)
		end
	end
	return flags, info
end

-- Build list of modifiers for given active skill
function calcs.buildActiveSkillModList(env, actor, activeSkill)
	local skillTypes = activeSkill.skillTypes
	local skillFlags = activeSkill.skillFlags
	local activeGem = activeSkill.activeGem

	-- Set mode flags
	if env.mode_buffs then
		skillFlags.buffs = true
	end
	if env.mode_combat then
		skillFlags.combat = true
	end
	if env.mode_effective then
		skillFlags.effective = true
	end

	-- Handle multipart skills
	local activeGemParts = activeGem.data.parts
	if activeGemParts then
		if env.mode == "CALCS" and activeSkill == env.player.mainSkill then
			activeGem.srcGem.skillPartCalcs = m_min(#activeGemParts, activeGem.srcGem.skillPartCalcs or 1)
			activeSkill.skillPart = activeGem.srcGem.skillPartCalcs
		else
			activeGem.srcGem.skillPart = m_min(#activeGemParts, activeGem.srcGem.skillPart or 1)
			activeSkill.skillPart = activeGem.srcGem.skillPart
		end
		local part = activeGemParts[activeSkill.skillPart]
		for k, v in pairs(part) do
			if v == true then
				skillFlags[k] = true
			elseif v == false then
				skillFlags[k] = nil
			end
		end
		activeSkill.skillPartName = part.name
		skillFlags.multiPart = #activeGemParts > 1
	end

	if skillTypes[SkillType.Shield] and (not actor.itemList["Weapon 2"] or actor.itemList["Weapon 2"].type ~= "Shield") then
		-- Skill requires a shield to be equipped
		skillFlags.disable = true
	end

	if skillFlags.attack then
		-- Set weapon flags
		local weaponTypes = activeGem.data.weaponTypes
		local weapon1Flags, weapon1Info = getWeaponFlags(actor.weaponData1, weaponTypes)
		if not weapon1Flags and activeSkill.summonSkill then
			-- Minion skills seem to ignore weapon types
			weapon1Flags, weapon1Info = data.weaponTypeInfo["None"].flag, data.weaponTypeInfo["None"]
		end
		if weapon1Flags then
			activeSkill.weapon1Flags = weapon1Flags
			skillFlags.weapon1Attack = true
			if weapon1Info.melee and skillFlags.melee then
				skillFlags.projectile = nil
			elseif not weapon1Info.melee and skillFlags.projectile then
				skillFlags.melee = nil
			end
		elseif skillTypes[SkillType.DualWield] or not skillTypes[SkillType.CanDualWield] or skillTypes[SkillType.MainHandOnly] or skillFlags.forceMainHand then
			-- Skill requires a compatible main hand weapon
			skillFlags.disable = true
		end
		if skillTypes[SkillType.DualWield] or skillTypes[SkillType.CanDualWield] then
			if not skillTypes[SkillType.MainHandOnly] and not skillFlags.forceMainHand then
				local weapon2Flags = getWeaponFlags(actor.weaponData2, weaponTypes)
				if weapon2Flags then
					activeSkill.weapon2Flags = weapon2Flags
					skillFlags.weapon2Attack = true
				elseif skillTypes[SkillType.DualWield] or not skillFlags.weapon1Attack then
					-- Skill requires a compatible off hand weapon
					skillFlags.disable = true
				end
			end
		elseif actor.weaponData2.type then
			-- Skill cannot be used while dual wielding
			skillFlags.disable = true
		end
		skillFlags.bothWeaponAttack = skillFlags.weapon1Attack and skillFlags.weapon2Attack
	end
	
	-- Build skill mod flag set
	local skillModFlags = 0
	if skillFlags.hit then
		skillModFlags = bor(skillModFlags, ModFlag.Hit)
	end
	if skillFlags.attack then
		skillModFlags = bor(skillModFlags, ModFlag.Attack)
	else
		skillModFlags = bor(skillModFlags, ModFlag.Cast)
		if skillFlags.spell then
			skillModFlags = bor(skillModFlags, ModFlag.Spell)
		end
	end
	if skillFlags.melee then
		skillModFlags = bor(skillModFlags, ModFlag.Melee)
	elseif skillFlags.projectile then
		skillModFlags = bor(skillModFlags, ModFlag.Projectile)
	end
	if skillFlags.area then
		skillModFlags = bor(skillModFlags, ModFlag.Area)
	end

	-- Build skill keyword flag set
	local skillKeywordFlags = 0
	if skillFlags.aura then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Aura)
	end
	if skillFlags.curse then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Curse)
	end
	if skillFlags.warcry then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Warcry)
	end
	if skillFlags.movement then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Movement)
	end
	if skillFlags.vaal then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Vaal)
	end
	if skillFlags.lightning then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Lightning)
	end
	if skillFlags.cold then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Cold)
	end
	if skillFlags.fire then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Fire)
	end
	if skillFlags.chaos then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Chaos)
	end
	if skillFlags.totem then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Totem)
	elseif skillFlags.trap then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Trap)
	elseif skillFlags.mine then
		skillKeywordFlags = bor(skillKeywordFlags, KeywordFlag.Mine)
	end

	-- Get skill totem ID for totem skills
	-- This is used to calculate totem life
	if skillFlags.totem then
		activeSkill.skillTotemId = activeGem.data.skillTotemId
		if not activeSkill.skillTotemId then
			if activeGem.data.color == 2 then
				activeSkill.skillTotemId = 2
			elseif activeGem.data.color == 3 then
				activeSkill.skillTotemId = 3
			else
				activeSkill.skillTotemId = 1
			end
		end
	end

	-- Build config structure for modifier searches
	activeSkill.skillCfg = {
		flags = bor(skillModFlags, activeSkill.weapon1Flags or activeSkill.weapon2Flags or 0),
		keywordFlags = skillKeywordFlags,
		skillName = activeGem.name:gsub("^Vaal ",""), -- This allows modifiers that target specific skills to also apply to their Vaal counterpart
		summonSkillName = activeSkill.summonSkill and activeSkill.summonSkill.activeGem.name,
		skillGem = activeGem,
		skillPart = activeSkill.skillPart,
		skillTypes = activeSkill.skillTypes,
		skillCond = { },
		skillDist = env.mode_effective and env.configInput.projectileDistance,
		slotName = activeSkill.slotName,
	}
	if skillFlags.weapon1Attack then
		activeSkill.weapon1Cfg = copyTable(activeSkill.skillCfg, true)
		activeSkill.weapon1Cfg.skillCond = setmetatable({ ["MainHandAttack"] = true }, { __index = activeSkill.skillCfg.skillCond })
		activeSkill.weapon1Cfg.flags = bor(skillModFlags, activeSkill.weapon1Flags)
	end
	if skillFlags.weapon2Attack then
		activeSkill.weapon2Cfg = copyTable(activeSkill.skillCfg, true)
		activeSkill.weapon2Cfg.skillCond = setmetatable({ ["OffHandAttack"] = true }, { __index = activeSkill.skillCfg.skillCond })
		activeSkill.weapon2Cfg.flags = bor(skillModFlags, activeSkill.weapon2Flags)
	end

	-- Apply gem property modifiers from the item this skill is socketed into
	for _, value in ipairs(env.modDB:Sum("LIST", activeSkill.skillCfg, "GemProperty")) do
		for _, gem in pairs(activeSkill.gemList) do
			if not gem.fromItem and calcLib.gemIsType(gem, value.keyword) then
				gem[value.key] = (gem[value.key] or 0) + value.value
			end
		end
	end

	-- Initialise skill modifier list
	local skillModList = common.New("ModList")
	activeSkill.skillModList = skillModList

	if skillFlags.disable then
		wipeTable(skillFlags)
		skillFlags.disable = true
		return
	end

	-- Add support gem modifiers to skill mod list
	for _, gem in pairs(activeSkill.gemList) do
		if gem.data.support then
			mergeGemMods(skillModList, gem)
		end
	end

	-- Apply gem/quality modifiers from support gems
	if not activeGem.fromItem then
		for _, value in ipairs(skillModList:Sum("LIST", activeSkill.skillCfg, "GemProperty")) do
			if value.keyword == "active_skill" then
				activeGem[value.key] = activeGem[value.key] + value.value
			end
		end
	end

	-- Add active gem modifiers
	mergeGemMods(skillModList, activeGem)

	-- Add extra modifiers
	for _, value in ipairs(env.modDB:Sum("LIST", activeSkill.skillCfg, "ExtraSkillMod")) do
		skillModList:AddMod(value.mod)
	end

	-- Extract skill data
	for _, value in ipairs(env.modDB:Sum("LIST", activeSkill.skillCfg, "Misc")) do
		if value.type == "SkillData" then
			activeSkill.skillData[value.key] = value.value
		end
	end
	for _, value in ipairs(skillModList:Sum("LIST", activeSkill.skillCfg, "Misc")) do
		if value.type == "SkillData" then
			activeSkill.skillData[value.key] = value.value
		end
	end

	-- Create minion
	if activeGem.data.minionList then
		local minionType
		local minionList = activeGem.data.minionList[1] and activeGem.data.minionList or env.build.spectreList
		if env.mode == "CALCS" and activeSkill == env.player.mainSkill then
			local index = isValueInArray(minionList, activeGem.srcGem.skillMinionCalcs) or 1
			minionType = minionList[index]
			activeGem.srcGem.skillMinionCalcs = minionType
		else
			local index = isValueInArray(minionList, activeGem.srcGem.skillMinion) or 1
			minionType = minionList[index]
			activeGem.srcGem.skillMinion = minionType
		end
		if minionType then
			local minion = { }
			activeSkill.minion = minion
			skillFlags.haveMinion = true
			minion.minionData = data.minions[minionType]
			minion.config = { }
			minion.level = activeSkill.skillData.minionLevel or activeSkill.skillData.levelRequirement
			minion.itemList = { }
			local damage = data.monsterDamageTable[minion.level] * minion.minionData.damage
			if activeSkill.skillData.minionUseBowAndQuiver and env.player.weaponData1.type == "Bow" then
				minion.weaponData1 = env.player.weaponData1
			else
				minion.weaponData1 = { 
					type = minion.minionData.weaponType1 or "None", 
					attackRate = 1 / minion.minionData.attackTime, 
					critChance = 5,
					PhysicalMin = damage * (1 - minion.minionData.damageSpread),
					PhysicalMax = damage * (1 + minion.minionData.damageSpread),
				}
			end
			minion.weaponData2 = { }
		end
	end

	-- Separate global effect modifiers (mods that can affect defensive stats or other skills)
	local i = 1
	while skillModList[i] do
		local destList
		for _, tag in ipairs(skillModList[i].tagList) do
			if tag.type == "GlobalEffect" then
				if tag.effectType == "Buff" then
					destList = "buffModList"
				elseif tag.effectType == "Aura" then
					destList = "auraModList"
				elseif tag.effectType == "Debuff" then
					destList = "debuffModList"
				elseif tag.effectType == "Curse" then
					destList = "curseModList"
				end
				break
			end
		end
		if destList then
			if not activeSkill[destList] then
				activeSkill[destList] = { }
			end
			local sig = modLib.formatModParams(skillModList[i])
			for d = 1, #activeSkill[destList] do
				local destMod = activeSkill[destList][d]
				if sig == modLib.formatModParams(destMod) and (destMod.type == "BASE" or destMod.type == "INC") then
					destMod.value = destMod.value + skillModList[i].value
					sig = nil
					break
				end
			end
			if sig then
				t_insert(activeSkill[destList],  skillModList[i])
			end
			t_remove(skillModList, i)
		else
			i = i + 1
		end
	end

	if activeSkill.buffModList or activeSkill.auraModList or activeSkill.debuffModList or activeSkill.curseModList then
		-- Add to auxillary skill list
		t_insert(env.auxSkillList, activeSkill)
	end
end

-- Initialise the active skill's minion skills
function calcs.createMinionSkills(env, activeSkill)
	local activeGem = activeSkill.activeGem
	local minion = activeSkill.minion
	local minionData = minion.minionData

	minion.activeSkillList = { }
	local skillIdList = { }
	for _, skillId in ipairs(minionData.skillList) do
		if data.skills[skillId] then
			t_insert(skillIdList, skillId)
		end
	end
	if env.modDB:Sum("FLAG", nil, "MinionInstability") then
		t_insert(skillIdList, "MinionInstability")
	end
	for _, skillId in ipairs(skillIdList) do
		local gem = {
			name = data.skills[skillId].name,
			data = data.skills[skillId],
			level = 1,
			quality = 0,
			fromItem = true,
		}
		if #gem.data.levels > 1 then
			for level, levelData in ipairs(gem.data.levels) do
				if levelData[1] > minion.level then
					break
				else
					gem.level = level
				end
			end
		end
		local minionSkill = calcs.createActiveSkill(gem, activeSkill.supportList, activeSkill)
		calcs.buildActiveSkillModList(env, minion, minionSkill)
		minionSkill.skillFlags.minion = true
		minionSkill.skillFlags.minionSkill = true
		minionSkill.skillFlags.haveMinion = true
		minionSkill.skillFlags.spectre = activeSkill.skillFlags.spectre
		if not minionSkill.skillData.damageEffectiveness then
			minionSkill.skillData.damageEffectiveness = 1 + (activeSkill.skillData.minionDamageEffectiveness or 0) / 100
		end
		t_insert(minion.activeSkillList, minionSkill)
	end
	local skillIndex 
	if env.mode == "CALCS" then
		skillIndex = m_min(activeGem.srcGem.skillMinionSkillCalcs or 1, #minion.activeSkillList)
		activeGem.srcGem.skillMinionSkillCalcs = skillIndex
	else
		skillIndex = m_min(activeGem.srcGem.skillMinionSkill or 1, #minion.activeSkillList)
		if env.mode == "MAIN" then
			activeGem.srcGem.skillMinionSkill = skillIndex
		end
	end
	minion.mainSkill = minion.activeSkillList[skillIndex]
end