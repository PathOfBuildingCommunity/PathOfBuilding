-- Path of Building
--
-- Module: Calcs
-- Performs all the offense and defense calculations.
-- Here be dragons!
--
local grid = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local m_abs = math.abs
local m_ceil = math.ceil
local m_floor = math.floor
local m_min = math.min
local m_max = math.max

local mod_listMerge = modLib.listMerge
local mod_listScaleMerge = modLib.listScaleMerge
local mod_dbMerge = modLib.dbMerge
local mod_dbScaleMerge = modLib.dbScaleMerge
local mod_dbUnmerge = modLib.dbUnmerge
local mod_dbMergeList = modLib.dbMergeList
local mod_dbScaleMergeList = modLib.dbScaleMergeList
local mod_dbUnmergeList = modLib.dbUnmergeList

local setViewMode = LoadModule("Modules/CalcsView", grid)

local isElemental = { fire = true, cold = true, lightning = true }

-- List of all damage types, ordered according to the conversion sequence
local dmgTypeList = {"physical", "lightning", "cold", "fire", "chaos"}

-- Combine specified modifiers from all current namespaces
local function sumMods(modDB, mult, ...)
	local activeWatchers = modDB._activeWatchers
	local val = mult and 1 or 0
	for i = 1, select('#', ...) do
		local modName = select(i, ...)
		if modName then
			for space, spaceName in pairs(modDB._spaces) do
				local modVal = space[modName]
				if modVal then
					val = mult and (val * modVal) or (val + modVal)
				end
				if activeWatchers then
					local fullName = (spaceName and spaceName.."_" or "") .. modName
					for watchList in pairs(activeWatchers) do
						watchList[fullName] = mult and 1 or 0
					end
				end
			end
		end
	end
	return val
end

-- Get value of misc modifier
local function getMiscVal(modDB, spaceName, modName, default)
	local space = modDB[spaceName or "global"]
	local val = default
	if space and space[modName] ~= nil then
		val = space[modName]
	end
	if modDB._activeWatchers then
		local fullName = (spaceName and spaceName.."_" or "") .. modName
		for watchList in pairs(modDB._activeWatchers) do
			watchList[fullName] = default
		end
		if not space then
			modDB[spaceName] = { }
		end
	end
	return val
end

-- Calculate value, optionally adding additional base
local function calcVal(modDB, name, base)
	local baseVal = sumMods(modDB, false, name.."Base") + (base or 0)
	return baseVal * (1 + (sumMods(modDB, false, name.."Inc")) / 100) * sumMods(modDB, true, name.."More")
end

-- Calculate hit chance
local function calcHitChance(evasion, accuracy)
	local rawChance = accuracy / (accuracy + (evasion / 4) ^ 0.8) * 100
	return m_max(m_min(m_floor(rawChance + 0.5) / 100, 0.95), 0.05)	
end

-- Merge gem modifiers with given mod list
local function mergeGemMods(modList, gem)
	for k, v in pairs(gem.data.base) do
		mod_listMerge(modList, k, v)
	end
	for k, v in pairs(gem.data.quality) do
		mod_listMerge(modList, k, m_floor(v * gem.effectiveQuality))
	end
	for k, v in pairs(gem.data.levels[gem.effectiveLevel]) do
		mod_listMerge(modList, k, v)
	end
end

-- Generate active namespace table
local function buildSpaceTable(modDB, spaceFlags)
	modDB._spaces = { [modDB.global] = false }
	if spaceFlags then
		for spaceName, val in pairs(spaceFlags) do
			if val then
				modDB[spaceName] = modDB[spaceName] or { }
				if modDB._activeWatchers or next(modDB[spaceName]) then
					modDB._spaces[modDB[spaceName]] = spaceName
				end
			end
		end
	end
end

-- Start watch section
local function startWatch(env, key, ...)
	if env.buildWatch then 
		-- Running in build mode
		-- In this mode, any modifiers read while this section is active will be tracked
		env.watchers[key] = { _key = key }
		env.modDB._activeWatchers[env.watchers[key] ] = true
		return true
	else
		local watchers = env.watchers
		if not watchers or env.spacesChanged then
			-- Watch system is disabled or skill namespaces have changed, so all sections will run by default
			return true
		end
		-- This section will be flagged if any modifiers read during build mode have changed since the build mode pass
		if not watchers[key] or watchers[key]._flag then
			return true
		end
		for i = 1, select('#', ...) do
			-- Check if any dependant sections have been flagged
			if watchers[select(i, ...)]._flag then
				return true
			end
		end
		return false
	end
end

-- End watch section
local function endWatch(env, key)
	if env.buildWatch and env.watchers[key] then
		env.modDB._activeWatchers[env.watchers[key] ] = nil
	end
end


-- Performs some preliminary processing of the given skill
-- It will find the active skill gem, determines the base flag set, and check that the support gems can support this skill
local function validateSkillSupports(skill)
	-- Build gem list
	local gemList = { }
	for _, gem in pairs(skill.gemList) do
		if gem.name then
			t_insert(gemList, gem)
		end
	end

	-- Find active skill
	skill.activeGem = nil
	for _, gem in ipairs(gemList) do
		if not gem.data.support then
			skill.activeGem = gem
			break
		end
	end

	-- Default attack if no active gem provided
	if not skill.activeGem then
		skill.activeGem = {
			name = "Default Attack",
			level = 1,
			quality = 0,
			data = data.gems._default
		}
		gemList = { skill.activeGem }
	end

	-- Build base skill flag set ('attack', 'projectile', etc)
	local baseFlags = { }
	skill.baseFlags = baseFlags
	for k, v in pairs(skill.activeGem.data) do
		if v == true then
			baseFlags[k] = true
		end
	end
	for _, gem in ipairs(gemList) do
		if gem.data.support and gem.data.addFlags then
			-- Support gem adds flags to supported skills (eg. Remote Mine adds 'mine')
			for k in pairs(gem.data.addFlags) do
				baseFlags[k] = true
			end
		end
	end

	-- Process support gems
	skill.validGemList = { }
	for _, gem in ipairs(gemList) do
		if gem.data.support and (
			(gem.data.attack and not baseFlags.attack) or
			(gem.data.spell and not baseFlags.spell) or
			(gem.data.melee and not baseFlags.melee) or
			(gem.data.projectile and not baseFlags.projectile) or
			(gem.data.chaining and not (baseFlags.chaining or baseFlags.projectile) and not (gem.data.projectile and baseFlags.projectile)) or
			(gem.data.duration and not baseFlags.duration) or
			(gem.data.totem and not baseFlags.totem) or
			(gem.data.trap and not baseFlags.trap and not (gem.data.mine and baseFlags.mine)) or
			(gem.data.mine and not baseFlags.mine and not (gem.data.trap and baseFlags.trap)) ) then
			-- This support doesn't apply
			gem.calcsErrMsg = skill.activeGem.name.." cannot be supported by "..gem.name
		elseif not gem.data.support and gem ~= skill.activeGem then
			gem.calcsErrMsg = "You can only specify one active gem per skill, so this one will be ignored"
		else
			gem.calcsErrMsg = nil
			t_insert(skill.validGemList, gem)
		end
	end
end

-- Build list of modifiers for given skill
local function buildSkillModList(env, skill)
	-- Initialise effective gem level and quality
	for _, gem in pairs(skill.validGemList) do
		gem.effectiveLevel = gem.level
		gem.effectiveQuality = gem.quality
	end

	local skillModList = { }
	skill.skillModList = skillModList

	if skill.slot then
		-- Check for local skill modifiers from the item this skill is socketed into
		local slotSpace = env.modDB["SocketedIn:"..skill.slot]
		if slotSpace then
			for k, v in pairs(slotSpace) do
				local factor, type = k:match("gem(%a+)_(%a+)")
				if factor then
					-- Gem level/quality modifier, apply it now
					for _, gem in pairs(skill.validGemList) do
						if type == "all" or (type == "active" and not gem.data.support) or gem.data[type] then
							-- This modifier applies to this type of gem
							if factor == "Level" then
								gem.effectiveLevel = gem.effectiveLevel + v
							elseif factor == "Quality" then
								gem.effectiveQuality = gem.effectiveQuality + v
							end
						end
					end
				else
					-- Merge with the skill modifier list
					mod_listMerge(skillModList, k, v)
				end
			end
		end
	end

	-- Merge skill-specific modifiers
	local skillSpace = env.modDB["Skill:"..skill.activeGem.name]
	if skillSpace then
		for k, v in pairs(skillSpace) do
			mod_listMerge(skillModList, k, v)
		end
	end

	-- Add support gem modifiers to skill mod list
	for _, gem in pairs(skill.validGemList) do
		if gem.data.support then
			mergeGemMods(skillModList, gem)
		end
	end

	-- Apply gem/quality modifiers from support gems
	skill.activeGem.effectiveLevel = skill.activeGem.effectiveLevel + (skillModList.gemLevel_active or 0)
	skill.activeGem.effectiveQuality = skill.activeGem.effectiveQuality + (skillModList.gemQuality_active or 0)

	-- Add active gem modifiers
	mergeGemMods(skillModList, skill.activeGem)

	-- Separate auxillary modifiers (mods that can affect defensive stats or other skills)
	skill.buffModList = { }
	skill.auraModList = { }
	skill.curseModList = { }
	for k, v in pairs(skillModList) do
		local spaceName, modName = modLib.getSpaceName(k)
		if spaceName == "BuffEffect" then
			mod_listMerge(skill.buffModList, modName, v)
		elseif spaceName == "AuraEffect" then
			mod_listMerge(skill.auraModList, modName, v)
		elseif spaceName == "CurseEffect" then
			mod_listMerge(skill.curseModList, modName, v)
		end
	end

	if skill ~= env.mainSkill then
		-- Add to auxillary skill list
		t_insert(env.auxSkills, skill)
	end
end

-- Build list of modifiers from the listed tree nodes
local function buildNodeModList(env, nodeList, finishJewels)
	-- Initialise radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		wipeTable(rad.data)
	end

	-- Add node modifers
	local modList = { }
	for _, node in pairs(nodeList) do
		-- Merge with output list
		for k, v in pairs(node.modList) do
			mod_listMerge(modList, k, v)
		end

		-- Run radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			local vX, vY = node.x - rad.x, node.y - rad.y
			if vX * vX + vY * vY <= rad.rSq then
				rad.func(node.modList, modList, rad.data)
			end
		end
	end

	if finishJewels then
		-- Finalise radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			rad.func(nil, modList, rad.data)
		end
	end

	return modList
end

-- Calculate min/max damage of a hit for the given damage type
local function calcHitDamage(env, output, damageType, ...)
	local modDB = env.modDB
	local isAttack = (env.mode_skillType == "ATTACK")

	local damageTypeMin = damageType.."Min"
	local damageTypeMax = damageType.."Max"

	-- Calculate base values
	local baseMin, baseMax
	if isAttack then
		baseMin = getMiscVal(modDB, "weapon1", damageTypeMin, 0) + sumMods(modDB, false, damageTypeMin)
		baseMax = getMiscVal(modDB, "weapon1", damageTypeMax, 0) + sumMods(modDB, false, damageTypeMax)
	else
		local damageEffectiveness = getMiscVal(modDB, "skill", "damageEffectiveness", 0)
		if damageEffectiveness == 0 then
			damageEffectiveness = 1
		end
		baseMin = getMiscVal(modDB, "skill", damageTypeMin, 0) + sumMods(modDB, false, damageTypeMin) * damageEffectiveness
		baseMax = getMiscVal(modDB, "skill", damageTypeMax, 0) + sumMods(modDB, false, damageTypeMax) * damageEffectiveness
	end

	-- Build lists of applicable modifier names
	local addElemental = isElemental[damageType]
	local inc = { damageType.."Inc", "damageInc" }
	local more = { damageType.."More", "damageMore" }
	local damageTypeStr = "total_"..damageType
	for i = 1, select('#', ...) do
		local dstElem = select(i, ...)
		damageTypeStr = damageTypeStr..dstElem
		-- Add modifiers for damage types to which this damage is being converted
		addElemental = addElemental or isElemental[dstElem]
		t_insert(inc, dstElem.."Inc")
		t_insert(more, dstElem.."More")
	end
	if addElemental then
		-- Damage is elemental or is being converted to elemental damage, add global elemental modifiers
		t_insert(inc, "elementalInc")
		t_insert(more, "elementalMore")
	end

	-- Combine modifiers
	local damageTypeStrInc = damageTypeStr.."Inc"
	if startWatch(env, damageTypeStrInc) then
		output[damageTypeStrInc] = sumMods(modDB, false, unpack(inc))
		endWatch(env, damageTypeStrInc)
	end
	local damageTypeStrMore = damageTypeStr.."More"
	if startWatch(env, damageTypeStrMore) then
		output[damageTypeStrMore] = sumMods(modDB, true, unpack(more))
		endWatch(env, damageTypeStrMore)
	end
	local modMult = (1 + output[damageTypeStrInc] / 100) * output[damageTypeStrMore]

	-- Calculate conversions
	if startWatch(env, damageTypeStr.."Conv", "conversionTable") then
		local addMin, addMax = 0, 0
		local conversionTable = output.conversionTable
		for _, otherType in ipairs(dmgTypeList) do
			if otherType == damageType then
				-- Damage can only be converted from damage types that preceed this one in the conversion sequence, so stop here
				break
			end
			local convMult = conversionTable[otherType][damageType]
			if convMult > 0 then
				-- Damage is being converted/gained from the other damage type
				local min, max = calcHitDamage(env, output, otherType, damageType, ...)
				addMin = addMin + min * convMult
				addMax = addMax + max * convMult
			end
		end
		output[damageTypeStr.."ConvAddMin"] = addMin
		output[damageTypeStr.."ConvAddMax"] = addMax
		endWatch(env, damageTypeStr.."Conv")
	end

	return  (baseMin * modMult + output[damageTypeStr.."ConvAddMin"]),
			(baseMax * modMult + output[damageTypeStr.."ConvAddMax"])
end

--
-- The following functions perform various steps in the calculations process.
-- Depending on what is being done with the output, other code may run inbetween steps, however the steps must always be performed in order:
-- 1. Initialise environment (initEnv)
-- 2. Merge main modifiers (mergeMainMods)
-- 3. Finalise modifier database (finaliseMods)
-- 4. Run calculations (performCalcs)
--
-- Thus a basic calculation pass would look like this:
-- 
-- local env = initEnv(input, build)
-- mergeMainMods(env)
-- finaliseMods(env, output)
-- performCalcs(env, output)
--

-- Initialise environment
-- This will initialise the skill list and the modifier database
local function initEnv(build, input, mode)
	local env = { }
	env.build = build

	-- Make a local copy of the skill list
	env.skills = { }
	for _, skill in pairs(build.skillsTab.list) do
		t_insert(env.skills, skill)
	end
	if #env.skills == 0 then
		-- No skills found, so add dummy skill to stop everything exploding
		t_insert(env.skills, { gemList = { } })
	end

	-- Process the skills
	for _, skill in pairs(env.skills) do
		validateSkillSupports(skill)
	end

	-- Select main skill
	if mode == "GRID" then
		input.skill_number = m_min(#env.skills, input.skill_number or 1)
		env.mainSkillIndex = input.skill_number
		env.skillPart = input.skill_part or 1
		env.buffMode = input.misc_buffMode
	else
		build.mainSkillIndex = m_min(#env.skills, build.mainSkillIndex or 1)
		env.mainSkillIndex = build.mainSkillIndex
		env.skillPart = env.skills[env.mainSkillIndex].skillPart or 1
		env.buffMode = "EFFECTIVE"
	end
	env.mainSkill = env.skills[env.mainSkillIndex]
	env.setupFunc = env.mainSkill.activeGem.data.setupFunc

	-- Handle multipart skills
	env.skillParts = { }
	local activeGemParts = env.mainSkill.activeGem.data.parts
	if activeGemParts then
		for i, part in pairs(activeGemParts) do
			env.skillParts[i] = part.name or ""
		end
		env.skillPart = m_min(#activeGemParts, env.skillPart)
		local part = activeGemParts[env.skillPart]
		for k, v in pairs(part) do
			if v == true then
				env.mainSkill.baseFlags[k] = true
			elseif v == false then
				env.mainSkill.baseFlags[k] = nil
			end
		end
		env.mainSkill.baseFlags.multiPart = #activeGemParts > 1
	end

	-- Initialise modifier database with base values
	local modDB = { }
	env.modDB = modDB
	env.classId = build.spec.curClassId
	local classStats = build.tree.characterData[env.classId]
	for _, stat in pairs({"str","dex","int"}) do
		mod_dbMerge(modDB, "", stat.."Base", classStats["base_"..stat])
	end
	local level = build.characterLevel
	mod_dbMerge(modDB, "", "lifeBase", 38 + level * 12)
	mod_dbMerge(modDB, "", "manaBase", 34 + level * 6)
	mod_dbMerge(modDB, "", "evasionBase", 53 + level * 3)
	mod_dbMerge(modDB, "", "accuracyBase", (level - 1) * 2) 
	mod_dbMerge(modDB, "", "fireResistMax", 75)
	mod_dbMerge(modDB, "", "coldResistMax", 75)
	mod_dbMerge(modDB, "", "lightningResistMax", 75)
	mod_dbMerge(modDB, "", "chaosResistMax", 75)
	mod_dbMerge(modDB, "", "blockChanceMax", 75)
	mod_dbMerge(modDB, "", "powerMax", 3)
	mod_dbMerge(modDB, "PerPower", "critChanceInc", 50)
	mod_dbMerge(modDB, "", "frenzyMax", 3)
	mod_dbMerge(modDB, "PerFrenzy", "speedInc", 4)
	mod_dbMerge(modDB, "PerFrenzy", "damageMore", 1.04)
	mod_dbMerge(modDB, "", "enduranceMax", 3)
	mod_dbMerge(modDB, "PerEndurance", "elementalResist", 4)
	mod_dbMerge(modDB, "", "activeTrapLimit", 3)
	mod_dbMerge(modDB, "", "activeMineLimit", 5)
	mod_dbMerge(modDB, "", "projectileCount", 1)
	mod_dbMerge(modDB, "CondMod", "DualWielding_attackSpeedMore", 1.1)
	mod_dbMerge(modDB, "CondMod", "DualWielding_attack_physicalMore", 1.2)
	mod_dbMerge(modDB, "CondMod", "DualWielding_blockChance", 15)

	-- Add bandit mods
	if build.banditNormal == "Alira" then
		mod_dbMerge(modDB, "", "manaBase", 60)
	elseif build.banditNormal == "Kraityn" then
		mod_dbMerge(modDB, "", "elementalResist", 10)
	elseif build.banditNormal == "Oak" then
		mod_dbMerge(modDB, "", "lifeBase", 40)
	else
		mod_dbMerge(modDB, "", "extraPoints", 1)
	end
	if build.banditCruel == "Alira" then
		mod_dbMerge(modDB, "", "castSpeedInc", 5)
	elseif build.banditCruel == "Kraityn" then
		mod_dbMerge(modDB, "", "attackSpeedInc", 8)
	elseif build.banditCruel == "Oak" then
		mod_dbMerge(modDB, "", "physicalInc", 16)
	else
		mod_dbMerge(modDB, "", "extraPoints", 1)
	end
	if build.banditMerciless == "Alira" then
		mod_dbMerge(modDB, "", "powerMax", 1)
	elseif build.banditMerciless == "Kraityn" then
		mod_dbMerge(modDB, "", "frenzyMax", 1)
	elseif build.banditMerciless == "Oak" then
		mod_dbMerge(modDB, "", "enduranceMax", 1)
	else
		mod_dbMerge(modDB, "", "extraPoints", 1)
	end

	-- Add mods from the input table
	mod_dbMergeList(modDB, input)

	return env
end

-- This function:
-- 1. Merges modifiers for all items, optionally replacing one item
-- 2. Builds a list of jewels with radius functions
-- 3. Builds modifier lists for all active skills
-- 4. Merges modifiers for all allocated passive nodes
local function mergeMainMods(env, repSlotName, repItem)
	local build = env.build

	-- Build and merge item modifiers, and create list of radius jewels
	env.itemModList = wipeTable(env.itemModList)
	env.radiusJewelList = wipeTable(env.radiusJewelList)
	for slotName, slot in pairs(build.itemsTab.slots) do
		local item
		if slotName == repSlotName then
			item = repItem
		else
			item = build.itemsTab.list[slot.selItemId]
		end
		if slot.nodeId then
			-- Slot is a jewel socket, check if socket is allocated
			if not build.spec.allocNodes[slot.nodeId] then
				item = nil
			elseif item and item.jewelRadiusIndex and item.jewelFunc then
				-- Jewel has a defined radius function, add it to the list
				local radiusInfo = data.jewelRadius[item.jewelRadiusIndex]
				local node = build.spec.nodes[slot.nodeId]
				t_insert(env.radiusJewelList, {
					rSq = radiusInfo.rad * radiusInfo.rad,
					x = node.x,
					y = node.y,
					func = item.jewelFunc,
					data = { }
				})
			end
		end
		if item then
			-- Merge mods for this item into the global item mod list
			local srcList = item.modList or item.slotModList[slot.slotNum]
			for k, v in pairs(srcList) do
				mod_listMerge(env.itemModList, k, v)
			end
			if item.type ~= "Jewel" then
				-- Update item counts
				if item.rarity == "UNIQUE" then
					mod_listMerge(env.itemModList, "gear_UniqueCount", 1)
				elseif item.rarity == "RARE" then
					mod_listMerge(env.itemModList, "gear_RareCount", 1)
				elseif item.rarity == "MAGIC" then
					mod_listMerge(env.itemModList, "gear_MagicCount", 1)
				else
					mod_listMerge(env.itemModList, "gear_NormalCount", 1)
				end
			end
		end
	end
	mod_dbMergeList(env.modDB, env.itemModList)

	-- Build skill modifier lists
	env.auxSkills = { }
	for _, skill in pairs(env.skills) do
		if skill == env.mainSkill or skill.active then
			buildSkillModList(env, skill)
		end
	end

	-- Build and merge modifiers for allocated passives
	env.specModList = buildNodeModList(env, build.spec.allocNodes, true)
	mod_dbMergeList(env.modDB, env.specModList)
end

-- Prepare environment for calculations
local function finaliseMods(env, output)
	local modDB = env.modDB

	local weapon1Type = getMiscVal(modDB, "weapon1", "type", "None")
	local weapon2Type = getMiscVal(modDB, "weapon2", "type", "")
	if weapon1Type == output.weapon1Type and weapon2Type == output.weapon2Type then
		env.spacesChanged = false
	else
		env.spacesChanged = true
		output.weapon1Type = weapon1Type
		output.weapon2Type = weapon2Type
		
		-- Initialise skill flag set
		env.skillFlags = wipeTable(env.skillFlags)
		local skillFlags = env.skillFlags
		for k, v in pairs(env.mainSkill.baseFlags) do
			skillFlags[k] = v
		end

		-- Set weapon flags
		skillFlags.mainIs1H = true
		local weapon1Info = data.weaponTypeInfo[weapon1Type]
		if weapon1Info then
			if not weapon1Info.oneHand then
				skillFlags.mainIs1H = nil
			end
			if skillFlags.attack then
				skillFlags.weapon1Attack = true
				if weapon1Info.melee and skillFlags.melee then
					skillFlags.bow = nil
					skillFlags.projectile = nil
				elseif not weapon1Info.melee and skillFlags.bow then
					skillFlags.melee = nil
				end
			end
		end
		local weapon2Info = data.weaponTypeInfo[weapon2Type]
		if weapon2Info and skillFlags.mainIs1H then
			if skillFlags.attack then
				skillFlags.weapon2Attack = true
			end
		end

		-- Build list of namespaces to search for mods
		local skillSpaceFlags = wipeTable(env.skillSpaceFlags)
		env.skillSpaceFlags = skillSpaceFlags
		if skillFlags.spell then
			skillSpaceFlags["spell"] = true
		elseif skillFlags.attack then
			skillSpaceFlags["attack"] = true
		end
		if skillFlags.weapon1Attack then
			if getMiscVal(modDB, "weapon1", "varunastra", false) then
				skillSpaceFlags["axe"] = true
				skillSpaceFlags["claw"] = true
				skillSpaceFlags["dagger"] = true
				skillSpaceFlags["mace"] = true
				skillSpaceFlags["sword"] = true
			else
				skillSpaceFlags[weapon1Info.space] = true
			end
			if weapon1Type ~= "None" then
				skillSpaceFlags["weapon"] = true
				if skillFlags.mainIs1H then
					skillSpaceFlags["weapon1h"] = true
					if weapon1Info.melee then
						skillSpaceFlags["weapon1hMelee"] = true
					else
						skillSpaceFlags["weaponRanged"] = true
					end
				else
					skillSpaceFlags["weapon2h"] = true
					if weapon1Info.melee then
						skillSpaceFlags["weapon2hMelee"] = true
					else
						skillSpaceFlags["weaponRanged"] = true
					end
				end
			end
		end
		if skillFlags.melee then
			skillSpaceFlags["melee"] = true
		elseif skillFlags.projectile then
			skillSpaceFlags["projectile"] = true
			if skillFlags.attack then
				skillSpaceFlags["projectileAttack"] = true
			end
		end
		if skillFlags.totem then
			skillSpaceFlags["totem"] = true
		elseif skillFlags.trap then
			skillSpaceFlags["trap"] = true
			skillSpaceFlags["trapHit"] = true
		elseif skillFlags.mine then
			skillSpaceFlags["mine"] = true
			skillSpaceFlags["mineHit"] = true
		end
		if skillFlags.aoe then
			skillSpaceFlags["aoe"] = true
		end
		if skillFlags.debuff then
			skillSpaceFlags["debuff"] = true
		end
		if skillFlags.aura then
			skillSpaceFlags["aura"] = true
		end
		if skillFlags.curse then
			skillSpaceFlags["curse"] = true
		end
		if skillFlags.warcry then
			skillSpaceFlags["warcry"] = true
		end
		if skillFlags.movement then
			skillSpaceFlags["movementSkills"] = true
		end
		if skillFlags.lightning then
			skillSpaceFlags["lightningSkills"] = true
			skillSpaceFlags["elementalSkills"] = true
		end
		if skillFlags.cold then
			skillSpaceFlags["coldSkills"] = true
			skillSpaceFlags["elementalSkills"] = true
		end
		if skillFlags.fire then
			skillSpaceFlags["fireSkills"] = true
			skillSpaceFlags["elementalSkills"] = true
		end
		if skillFlags.chaos then
			skillSpaceFlags["chaosSkills"] = true
		end
	end
	if weapon1Type == "None" then
		-- Merge unarmed weapon modifiers
		for k, v in pairs(data.unarmedWeapon[env.classId]) do
			mod_dbMerge(modDB, "weapon1", k, v)
		end
	end
	
	-- Set modes
	if env.mainSkill.baseFlags.attack then
		env.mode_skillType = "ATTACK"
	else
		env.mode_skillType = "SPELL"
	end
	if env.skillFlags.showAverage then
		env.mode_average = true
	end
	local buffMode = env.buffMode
	if buffMode == "BUFFED" then
		env.mode_buffs = true
		env.mode_effective = false
	elseif buffMode == "EFFECTIVE" then
		env.mode_buffs = true
		env.mode_effective = true
	else
		env.mode_buffs = false
		env.mode_effective = false
	end
	
	-- Reset namespaces
	buildSpaceTable(modDB)
	
	-- Merge skill modifiers and calculate life and mana reservations
	for _, skill in pairs(env.skills) do
		if skill == env.mainSkill or skill.active then
			local skillModList = skill.skillModList
	
			-- Merge skill modifiers
			if skill == env.mainSkill then
				mod_dbMergeList(modDB, skillModList)
			end
			mod_dbMergeList(modDB, skill.buffModList)
			local auraEffect = (1 + (getMiscVal(modDB, nil, "auraEffectInc", 0) + (skillModList.auraEffectInc or 0)) / 100) * getMiscVal(modDB, nil, "auraEffectMore", 1) * (skillModList.auraEffectMore or 1)
			mod_dbScaleMergeList(modDB, skill.auraModList, auraEffect)
			if env.mode_effective then
				local curseEffect = (1 + (getMiscVal(modDB, nil, "curseEffectInc", 0) + (skillModList.curseEffectInc or 0)) / 100) * getMiscVal(modDB, nil, "curseEffectMore", 1) * (skillModList.curseEffectMore or 1)
				mod_dbScaleMergeList(modDB, skill.curseModList, curseEffect)
			end

			-- Calculate reservations
			local baseVal, suffix
			baseVal = skillModList.skill_manaReservedBase
			if baseVal then
				suffix = "Base"
			else
				baseVal = skillModList.skill_manaReservedPercent
				if baseVal then
					suffix = "Percent"
				end
			end
			if baseVal then
				local cost = m_floor(baseVal * (skillModList.manaCostMore or 1))
				cost = m_ceil(cost * sumMods(modDB, true, "manaReservedMore") * (skillModList.manaReservedMore or 1))
				cost = m_ceil(cost * (1 + sumMods(modDB, false, "manaReservedInc") / 100 + (skillModList.manaReservedInc or 0) / 100))
				if getMiscVal(modDB, nil, "bloodMagic", false) or skillModList.skill_bloodMagic then
					mod_dbMerge(modDB, "reserved", "life"..suffix, cost)
				else
					mod_dbMerge(modDB, "reserved", "mana"..suffix, cost)
				end
			end
		end
	end

	-- Merge active skill part mods
	if env.mainSkill.baseFlags.multiPart and modDB["SkillPart"..env.skillPart] then
		mod_dbMergeList(modDB, modDB["SkillPart"..env.skillPart])
	end
	
	-- Merge gear-sourced keystone modifiers
	if modDB.gear then
		for name, node in pairs(env.build.tree.keystoneMap) do
			if getMiscVal(modDB, "gear", "keystone:"..name, false) and not getMiscVal(modDB, nil, "keystone:"..name, false) then
				-- Keystone is granted by gear but not allocated on tree, so add its modifiers
				mod_dbMergeList(modDB, buildNodeModList(env, { node }))
			end
		end
	end

	-- Build condition list
	local condList = wipeTable(env.condList)
	env.condList = condList
	if weapon1Type == "Staff" then
		condList["UsingStaff"] = true
	end
	if env.skillFlags.mainIs1H and weapon2Type == "Shield" then
		condList["UsingShield"] = true
	end
	if data.weaponTypeInfo[weapon1Type] and data.weaponTypeInfo[weapon2Type] then
		condList["DualWielding"] = true
	end
	if weapon1Type == "None" and not data.weaponTypeInfo[weapon2Type] then
		condList["Unarmed"] = true
	end
	if getMiscVal(modDB, "gear", "NormalCount", 0) > 0 then
		condList["UsingNormalItem"] = true
	end
	if getMiscVal(modDB, "gear", "MagicCount", 0) > 0 then
		condList["UsingMagicItem"] = true
	end
	if getMiscVal(modDB, "gear", "RareCount", 0) > 0 then
		condList["UsingRareItem"] = true
	end
	if getMiscVal(modDB, "gear", "UniqueCount", 0) > 0 then
		condList["UsingUniqueItem"] = true
	end
	if output.manaReservedBase == 0 and output.manaReservedPercent == 0 then
		condList["NoManaReserved"] = true
	end
	if modDB.Cond then
		for k, v in pairs(modDB.Cond) do
			condList[k] = v
			if v then
				env.skillFlags[k] = true
			end
		end
	end
	if env.mode_buffs then
		if modDB.CondBuff then
			for k, v in pairs(modDB.CondBuff) do
				condList[k] = v
				if v then
					env.skillFlags[k] = true
				end
			end
		end
		if modDB.CondEff and env.mode_effective then
			for k, v in pairs(modDB.CondEff) do
				condList[k] = v
				if v then
					env.skillFlags[k] = true
				end
			end
			mod_dbMerge(modDB, "CondMod", "EnemyShocked_effective_damageTakenInc", 50)
			condList["EnemyFrozenShockedIgnited"] = condList["EnemyFrozen"] or condList["EnemyShocked"] or condList["EnemyIgnited"]
			condList["EnemyElementalStatus"] = condList["EnemyChilled"] or condList["EnemyFrozen"] or condList["EnemyShocked"] or condList["EnemyIgnited"]
		end
		if not getMiscVal(modDB, nil, "neverCrit", false) then
			condList["CritInPast8Sec"] = true
		end
		if env.skillFlags.attack then
			condList["AttackedRecently"] = true
		elseif env.skillFlags.spell then
			condList["CastSpellRecently"] = true
		end
		if env.skillFlags.movement then
			condList["UsedMovementSkillRecently"] = true
		end
		if env.skillFlags.totem then
			condList["SummonedTotemRecently"] = true
		end
		if env.skillFlags.mine then
			condList["DetonatedMinesRecently"] = true
		end
	end

	-- Build and merge conditional modifier list
	local condModList = wipeTable(env.condModList)
	env.condModList = condModList
	if modDB.CondMod then
		for k, v in pairs(modDB.CondMod) do
			local isNot, condName, modName = modLib.getCondName(k)
			if (isNot and not condList[condName]) or (not isNot and condList[condName]) then
				mod_listMerge(condModList, modName, v)
			end
		end
	end
	mod_dbMergeList(modDB, env.condModList)

	-- Add boss modifiers
	if getMiscVal(modDB, "effective", "enemyIsBoss", false) then
		--mod_dbMerge(modDB, "", "curseEffectInc", -60)
		mod_dbMerge(modDB, "", "curseEffectMore", 0.4) -- FIXME: Need to confirm actual value
		mod_dbMerge(modDB, "effective", "elementalResist", 30)
		mod_dbMerge(modDB, "effective", "chaosResist", 15)
	end

	-- Add per-item-type mods
	for spaceName, countName in pairs({["PerNormal"]="NormalCount",["PerMagic"]="MagicCount",["PerRare"]="RareCount",["PerUnique"]="UniqueCount",["PerGrandSpectrum"]="GrandSpectrumCount"}) do
		local space = modDB[spaceName]
		if space then
			local count = getMiscVal(modDB, "gear", countName, 0)
			for k, v in pairs(space) do
				mod_dbScaleMerge(modDB, "", k, v, count)
			end
		end
	end

	-- Calculate maximum charges
	if getMiscVal(modDB, "buff", "power", false) then
		env.skillFlags.havePower = true
		output.powerMax = getMiscVal(modDB, nil, "powerMax", 0)
	end
	if getMiscVal(modDB, "buff", "frenzy", false) then
		env.skillFlags.haveFrenzy = true
		output.frenzyMax = getMiscVal(modDB, nil, "frenzyMax", 0)
	end
	if getMiscVal(modDB, "buff", "endurance", false) then
		env.skillFlags.haveEndurance = true
		output.enduranceMax = getMiscVal(modDB, nil, "enduranceMax", 0)
	end

	if env.mode_buffs then
		-- Build buff mod list
		local buffModList = wipeTable(env.buffModList)
		env.buffModList = buffModList

		-- Calculate total charge bonuses
		if env.skillFlags.havePower then
			for k, v in pairs(modDB.PerPower) do
				mod_listScaleMerge(buffModList, k, v, output.powerMax)
			end
		end
		if env.skillFlags.haveFrenzy then
			for k, v in pairs(modDB.PerFrenzy) do
				mod_listScaleMerge(buffModList, k, v, output.frenzyMax)
			end
		end
		if env.skillFlags.haveEndurance then
			for k, v in pairs(modDB.PerEndurance) do
				mod_listScaleMerge(buffModList, k, v, output.enduranceMax)
			end
		end
		
		-- Add other buffs
		if env.condList["Onslaught"] then
			local effect = m_floor(20 * (1 + sumMods(modDB, false, "onslaughtEffectInc") / 100))
			mod_listMerge(buffModList, "attackSpeedInc", effect)
			mod_listMerge(buffModList, "castSpeedInc", effect)
			mod_listMerge(buffModList, "movementSpeedInc", effect)
		end
		if getMiscVal(modDB, "buff", "pendulum", false) then
			mod_listMerge(buffModList, "elementalInc", 100)
			mod_listMerge(buffModList, "aoeRadiusInc", 25)
		end

		-- Merge buff bonuses
		mod_dbMergeList(modDB, buffModList)
	end

	-- Calculate attributes
	for _, stat in pairs({"str","dex","int"}) do
		output["total_"..stat] = m_floor(calcVal(modDB, stat))
	end

	-- Add attribute bonuses
	mod_dbMerge(modDB, "", "lifeBase", m_floor(output.total_str / 2))
	local strDmgBonus = m_floor((output.total_str + getMiscVal(modDB, nil, "dexIntToMeleeBonus", 0)) / 5 + 0.5)
	mod_dbMerge(modDB, "melee", "physicalInc", strDmgBonus)
	if getMiscVal(modDB, nil, "ironGrip", false) then
		mod_dbMerge(modDB, "projectileAttack", "physicalInc", strDmgBonus)
	end
	if getMiscVal(modDB, nil, "ironWill", false) then
		mod_dbMerge(modDB, "spell", "damageInc", strDmgBonus)
	end
	mod_dbMerge(modDB, "", "accuracyBase", output.total_dex * 2)
	if not getMiscVal(modDB, nil, "ironReflexes", false) then
		mod_dbMerge(modDB, "", "evasionInc", m_floor(output.total_dex / 5 + 0.5))
	end
	mod_dbMerge(modDB, "", "manaBase", m_ceil(output.total_int / 2))
	mod_dbMerge(modDB, "", "energyShieldInc", m_floor(output.total_int / 5 + 0.5))
end

-- Calculate offence and defence stats
local function performCalcs(env, output)
	local modDB = env.modDB

	-- Calculate life/mana pools
	if startWatch(env, "life") then
		if getMiscVal(modDB, nil, "chaosInoculation", false) then
			output.total_life = 1
		else
			output.total_life = calcVal(modDB, "life")
		end
		endWatch(env, "life")
	end
	if startWatch(env, "mana") then
		output.total_mana = calcVal(modDB, "mana")
		mod_dbMerge(modDB, "", "manaRegenBase", output.total_mana * 0.0175)
		output.total_manaRegen = sumMods(modDB, false, "manaRegenBase") * (1 + sumMods(modDB, false, "manaRegenInc", "manaRecoveryInc") / 100) * sumMods(modDB, true, "manaRegenMore", "manaRecoveryMore")
		endWatch(env, "mana")
	end

	-- Calculate life/mana reservation
	for _, pool in pairs({"life", "mana"}) do
		if startWatch(env, pool.."Reservation", pool) then
			local max = output["total_"..pool]
			local reserved = getMiscVal(modDB, "reserved", pool.."Base", 0) + m_floor(max * getMiscVal(modDB, "reserved", pool.."Percent", 0) / 100 + 0.5)
			output["total_"..pool.."Reserved"] = reserved
			output["total_"..pool.."ReservedPercent"] = reserved / max
			output["total_"..pool.."Unreserved"] = max - reserved
			output["total_"..pool.."UnreservedPercent"] = (max - reserved) / max
			endWatch(env, pool.."Reservation")
		end
	end

	-- Calculate primary defences
	if startWatch(env, "energyShield", "mana") then
		local convManaToES = getMiscVal(modDB, nil, "manaGainAsEnergyShield", 0)
		if convManaToES > 0 then
			output.total_energyShield = sumMods(modDB, false, "manaBase") * (1 + sumMods(modDB, false, "energyShieldInc", "defencesInc", "manaInc") / 100) * sumMods(modDB, true, "energyShieldMore", "defencesMore", "manaMore") * convManaToES / 100
		else
			output.total_energyShield = 0
		end
		local energyShieldFromReservedMana = getMiscVal(modDB, nil, "energyShieldFromReservedMana", 0)
		if energyShieldFromReservedMana > 0 then
			output.total_energyShield = output.total_energyShield + output.total_manaReserved * (1 + sumMods(modDB, false, "energyShieldInc", "defencesInc") / 100) * sumMods(modDB, true, "energyShieldMore", "defencesMore") * energyShieldFromReservedMana / 100
		end
		output.total_gear_energyShieldBase = env.itemModList.energyShieldBase or 0
		for _, slot in pairs({"global","slot:Helmet","slot:Body Armour","slot:Gloves","slot:Boots","slot:Shield"}) do
			buildSpaceTable(modDB, { [slot] = true })
			local energyShieldBase = getMiscVal(modDB, slot, "energyShieldBase", 0)
			if energyShieldBase > 0 then
				output.total_energyShield = output.total_energyShield + energyShieldBase * (1 + sumMods(modDB, false, "energyShieldInc", "defencesInc") / 100) * sumMods(modDB, true, "energyShieldMore", "defencesMore")
			end
			if slot ~= "global" then
				output.total_gear_energyShieldBase = output.total_gear_energyShieldBase + energyShieldBase
			end
		end
		buildSpaceTable(modDB)
		output.total_energyShieldRecharge = output.total_energyShield * 0.2 * (1 + sumMods(modDB, false, "energyShieldRechargeInc", "energyShieldRecoveryInc") / 100) * sumMods(modDB, true, "energyShieldRechargeMore", "energyShieldRecoveryMore")
		output.total_energyShieldRechargeDelay = 2 / (1 + getMiscVal(modDB, nil, "energyShieldRechargeFaster", 0) / 100)
		endWatch(env, "energyShield")
	end
	if startWatch(env, "armourEvasion", "life") then
		output.total_evasion = 0
		local armourFromReservedLife = getMiscVal(modDB, nil, "armourFromReservedLife", 0)
		if armourFromReservedLife > 0 then
			output.total_armour = output.total_lifeReserved * (1 + sumMods(modDB, false, "armourInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "armourMore", "defencesMore") * armourFromReservedLife / 100
		else
			output.total_armour = 0
		end
		output.total_gear_evasionBase = env.itemModList.evasionBase or 0
		output.total_gear_armourBase = env.itemModList.armourBase or 0
		local ironReflexes = getMiscVal(modDB, nil, "ironReflexes", false)
		if getMiscVal(modDB, nil, "unbreakable", false) then
			mod_dbMerge(modDB, "slot:Body Armour", "armourBase", getMiscVal(modDB, "slot:Body Armour", "armourBase", 0))
		end
		for _, slot in pairs({"global","slot:Helmet","slot:Body Armour","slot:Gloves","slot:Boots","slot:Shield"}) do
			buildSpaceTable(modDB, { [slot] = true })
			local evasionBase = getMiscVal(modDB, slot, "evasionBase", 0)
			local bothBase = getMiscVal(modDB, slot, "armourAndEvasionBase", 0)
			local armourBase = getMiscVal(modDB, slot, "armourBase", 0)
			if ironReflexes then
				if evasionBase > 0 or armourBase > 0 then
					output.total_armour = output.total_armour + (evasionBase + armourBase + bothBase) * (1 + sumMods(modDB, false, "armourInc", "evasionInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "armourMore", "evasionMore", "defencesMore")
				end
			else
				if evasionBase > 0 then
					output.total_evasion = output.total_evasion + (evasionBase + bothBase) * (1 + sumMods(modDB, false, "evasionInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "evasionMore", "defencesMore")
				end
				if armourBase > 0 then
					output.total_armour = output.total_armour + (armourBase + bothBase) * (1 + sumMods(modDB, false, "armourInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "armourMore", "defencesMore")
				end
			end
			if slot ~= "global" then
				output.total_gear_evasionBase = output.total_gear_evasionBase + evasionBase + bothBase
				output.total_gear_armourBase = output.total_gear_armourBase + armourBase + bothBase
			end
		end
		if getMiscVal(modDB, nil, "cannotEvade", false) then
			output.total_evadeChance = 0
		else
			local attackerLevel = getMiscVal(modDB, "misc", "evadeMonsterLevel", false) and m_min(getMiscVal(modDB, "monster", "level", 1), #data.enemyAccuracyTable) or m_max(m_min(env.build.characterLevel, 80), 1)
			output.total_evadeChance = 1 - calcHitChance(output.total_evasion, data.enemyAccuracyTable[attackerLevel])
		end
		buildSpaceTable(modDB)
		endWatch(env, "armourEvasion")
	end

	if startWatch(env, "lifeEnergyShieldRegen", "life", "energyShield") then
		if getMiscVal(modDB, nil, "noLifeRegen", false) then
			output.total_lifeRegen = 0
		elseif getMiscVal(modDB, nil, "zealotsOath", false) then
			output.total_lifeRegen = 0
			mod_dbMerge(modDB, "", "energyShieldRegenBase", sumMods(modDB, false, "lifeRegenBase"))
			mod_dbMerge(modDB, "", "energyShieldRegenPercent", sumMods(modDB, false, "lifeRegenPercent"))
		else
			mod_dbMerge(modDB, "", "lifeRegenBase", output.total_life * sumMods(modDB, false, "lifeRegenPercent") / 100)
			output.total_lifeRegen = sumMods(modDB, false, "lifeRegenBase") * (1 + sumMods(modDB, false, "lifeRecoveryInc") / 100) * sumMods(modDB, true, "lifeRecoveryMore")
		end
		mod_dbMerge(modDB, "", "energyShieldRegenBase", output.total_energyShield * sumMods(modDB, false, "energyShieldRegenPercent") / 100)
		output.total_energyShieldRegen = sumMods(modDB, false, "energyShieldRegenBase") * (1 + sumMods(modDB, false, "energyShieldRecoveryInc") / 100) * sumMods(modDB, true, "energyShieldRecoveryMore")
		endWatch(env, "lifeEnergyShieldRegen")
	end

	if startWatch(env, "resist") then
		for _, elem in pairs({"fire", "cold", "lightning"}) do
			output["total_"..elem.."ResistMax"] = sumMods(modDB, false, elem.."ResistMax")
			output["total_"..elem.."ResistTotal"] = sumMods(modDB, false, elem.."Resist", "elementalResist") - 60
		end
		if getMiscVal(modDB, nil, "chaosInoculation", false) then
			output.total_chaosResistMax = 100
			output.total_chaosResistTotal = 100
		else
			output.total_chaosResistMax = sumMods(modDB, false, "chaosResistMax")
			output.total_chaosResistTotal = sumMods(modDB, false, "chaosResist") - 60
		end
		for _, elem in pairs({"fire", "cold", "lightning", "chaos"}) do
			local total = output["total_"..elem.."ResistTotal"]
			local cap = output["total_"..elem.."ResistMax"]
			output["total_"..elem.."Resist"] = m_min(total, cap)
			output["total_"..elem.."ResistOverCap"] = m_max(0, total - cap)
		end
		endWatch(env, "resist")
	end

	if startWatch(env, "otherDef") then
		output.total_blockChanceMax = sumMods(modDB, false, "blockChanceMax")
		output.total_blockChance = m_min(sumMods(modDB, false, "blockChance") / 100 * (1 + sumMods(modDB, false, "blockChanceInc") / 100) * sumMods(modDB, true, "blockChanceMore"), output.total_blockChanceMax) 
		output.total_spellBlockChance = m_min(sumMods(modDB, false, "spellBlockChance") / 100 * (1 + sumMods(modDB, false, "spellBlockChanceInc") / 100) * sumMods(modDB, true, "spellBlockChanceMore") + output.total_blockChance * m_min(100, getMiscVal(modDB, nil, "blockChanceConv", 0)) / 100, output.total_blockChanceMax) 
		if getMiscVal(modDB, nil, "cannotBlockAttacks", false) then
			output.total_blockChance = 0
		end
		output.total_dodgeAttacks = sumMods(modDB, false, "dodgeAttacks") / 100 
		output.total_dodgeSpells = sumMods(modDB, false, "dodgeSpells") / 100 
		local stunChance = 1 - sumMods(modDB, false, "avoidStun", 0) / 100
		if output.total_energyShield > output.total_life * 2 then
			stunChance = stunChance * 0.5
		end
		output.stun_avoidChance = 1 - stunChance
		if output.stun_avoidChance >= 1 then
			output.stun_duration = 0
			output.stun_blockDuration = 0
		else
			output.stun_duration = 0.35 / (1 + sumMods(modDB, false, "stunRecoveryInc") / 100)
			output.stun_blockDuration = 0.35 / (1 + sumMods(modDB, false, "stunRecoveryInc", "blockRecoveryInc") / 100)
		end
		endWatch(env, "otherDef")
	end

	-- Enable skill namespaces
	buildSpaceTable(modDB, env.skillSpaceFlags)

	-- Calculate projectile stats
	if env.skillFlags.projectile then
		if startWatch(env, "projectile") then
			output.total_projectileCount = sumMods(modDB, false, "projectileCount")
			output.total_pierce = m_min(100, sumMods(modDB, false, "pierceChance")) / 100
			output.total_projectileSpeedMod = (1 + sumMods(modDB, false, "projectileSpeedInc") / 100) * sumMods(modDB, true, "projectileSpeedMore")
			endWatch(env, "projectile")
		end
		if getMiscVal(modDB, nil, "drillneck", false) then
			mod_dbMerge(modDB, "projectile", "damageInc", output.total_pierce * 100)
		end
	end

	-- Run skill setup function
	if env.setupFunc then
		env.setupFunc(function(mod, val) mod_dbMerge(modDB, nil, mod, val) end, output)
	end

	local isAttack = (env.mode_skillType == "ATTACK")

	-- Calculate enemy resistances
	if startWatch(env, "enemyResist") then
		local elemResist = getMiscVal(modDB, "effective", "elementalResist", 0)
		for _, damageType in pairs({"lightning","cold","fire"}) do
			output["enemy_"..damageType.."Resist"] = m_min(elemResist + getMiscVal(modDB, "effective", damageType.."Resist", 0), 75)
		end
		output.enemy_chaosResist = m_min(getMiscVal(modDB, "effective", "chaosResist", 0), 75)
		endWatch(env, "enemyResist")
	end

	-- Cache global damage disabling flags
	if startWatch(env, "canDeal") then
		output.canDeal = { }
		for _, damageType in pairs(dmgTypeList) do
			output.canDeal[damageType] = not getMiscVal(modDB, nil, "dealNo"..damageType, false)
		end
		endWatch(env, "canDeal")
	end
	local canDeal = output.canDeal

	-- Calculate damage conversion percentages
	if startWatch(env, "conversionTable") then
		output.conversionTable = { }
		for damageTypeIndex = 1, 4 do
			local damageType = dmgTypeList[damageTypeIndex]
			local globalConv = { }
			local skillConv = { }
			local add = { }
			local globalTotal, skillTotal = 0, 0
			for otherTypeIndex = damageTypeIndex + 1, 5 do
				-- For all possible destination types, check for global and skill conversions
				otherType = dmgTypeList[otherTypeIndex]
				globalConv[otherType] = sumMods(modDB, false, damageType.."ConvertTo"..otherType)
				globalTotal = globalTotal + globalConv[otherType]
				skillConv[otherType] = getMiscVal(modDB, "skill", damageType.."ConvertTo"..otherType, 0)
				skillTotal = skillTotal + skillConv[otherType]
				add[otherType] = sumMods(modDB, false, damageType.."GainAs"..otherType)
			end
			if globalTotal + skillTotal > 100 then
				-- Conversion exceeds 100%, scale down non-skill conversions
				local factor = (100 - skillTotal) / globalTotal
				for type, val in pairs(globalConv) do
					globalConv[type] = globalConv[type] * factor
				end
				globalTotal = globalTotal * factor
			end
			local dmgTable = { }
			for type, val in pairs(globalConv) do
				dmgTable[type] = (globalConv[type] + skillConv[type] + add[type]) / 100
			end
			dmgTable.mult = 1 - (globalTotal + skillTotal) / 100
			output.conversionTable[damageType] = dmgTable
		end
		output.conversionTable["chaos"] = { mult = 1 }
		endWatch(env, "conversionTable")
	end

	-- Calculate damage for each damage type
	local combMin, combMax = 0, 0
	for _, damageType in pairs(dmgTypeList) do
		local min, max
		if startWatch(env, damageType, "enemyResist", "canDeal", "conversionTable") then
			if canDeal[damageType] then
				min, max = calcHitDamage(env, output, damageType)
				local convMult = output.conversionTable[damageType].mult
				min = min * convMult
				max = max * convMult
				if env.mode_effective then
					-- Apply resistances
					local preMult
					local taken = getMiscVal(modDB, "effective", damageType.."TakenInc", 0) + getMiscVal(modDB, "effective", "damageTakenInc", 0)
					if isElemental[damageType] then
						local resist = output["enemy_"..damageType.."Resist"] - sumMods(modDB, false, damageType.."Pen", "elementalPen")
						preMult = 1 - resist / 100
						taken = taken + getMiscVal(modDB, "effective", "elementalTakenInc", 0)
					elseif damageType == "chaos" then
						preMult = 1 - output.enemy_chaosResist / 100
					else
						preMult = 1
						taken = taken - getMiscVal(modDB, "effective", "physicalRed", 0)
					end
					if env.skillSpaceFlags.projectile then
						taken = taken + getMiscVal(modDB, "effective", "projectileTakenInc", 0)
					end
					local mult = preMult * (1 + taken / 100)
					min = min * mult
					max = max * mult
				end
			else
				min, max = 0, 0
			end
			output["total_"..damageType.."Min"] = min
			output["total_"..damageType.."Max"] = max
			output["total_"..damageType.."Avg"] = (min + max) / 2
			endWatch(env, damageType)
		else
			min = output["total_"..damageType.."Min"]
			max = output["total_"..damageType.."Max"]
		end
		combMin = combMin + min
		combMax = combMax + max
	end
	output.total_combMin = combMin
	output.total_combMax = combMax

	-- Calculate crit chance, crit multiplier, and their combined effect
	if startWatch(env, "dps_crit") then
		if getMiscVal(modDB, nil, "neverCrit", false) then
			output.total_critChance = 0
			output.total_critMultiplier = 0
			output.total_critEffect = 1
		else
			local baseCrit
			if isAttack then
				baseCrit = getMiscVal(modDB, "weapon1", "critChanceBase", 0)
			else
				baseCrit = getMiscVal(modDB, "skill", "critChanceBase", 0)
			end
			output.total_critChance = calcVal(modDB, "critChance", baseCrit) / 100
			if env.mode_effective then
				output.total_critChance = output.total_critChance + getMiscVal(modDB, "effective", "additionalCritChance", 0) / 100
			end
			if baseCrit < 100 then
				output.total_critChance = m_min(output.total_critChance, 0.95)
			end
			if baseCrit > 0 then
				output.total_critChance = m_max(output.total_critChance, 0.05)
			end
			if getMiscVal(modDB, nil, "noCritMult", false) then
				output.total_critMultiplier = 1
			else
				output.total_critMultiplier = 1.5 + sumMods(modDB, false, "critMultiplier") / 100
			end
			output.total_critEffect = 1 - output.total_critChance + output.total_critChance * output.total_critMultiplier
		end
		endWatch(env, "dps_crit")
	end

	-- Calculate skill speed
	if startWatch(env, "dps_speed") then
		if isAttack then
			local baseSpeed
			local attackTime = getMiscVal(modDB, "skill", "attackTime", 0)
			if attackTime > 0 then
				-- Skill is overriding weapon attack speed
				baseSpeed = 1 / attackTime * (1 + getMiscVal(modDB, "weapon1", "attackSpeedInc", 0) / 100)
			else
				baseSpeed = getMiscVal(modDB, "weapon1", "attackRate", 0)
			end
			output.total_speed = baseSpeed * (1 + sumMods(modDB, false, "speedInc", "attackSpeedInc") / 100) * sumMods(modDB, true, "speedMore", "attackSpeedMore")
		else
			local baseSpeed = 1 / getMiscVal(modDB, "skill", "castTime", 0)
			output.total_speed = baseSpeed * (1 + sumMods(modDB, false, "speedInc", "castSpeedInc") / 100) * sumMods(modDB, true, "speedMore", "castSpeedMore")
		end
		output.total_time = 1 / output.total_speed
		endWatch(env, "dps_speed")
	end

	-- Calculate hit chance
	if startWatch(env, "dps_hitChance") then
		if not isAttack or getMiscVal(modDB, "skill", "cannotBeEvaded", false) or getMiscVal(modDB, nil, "cannotBeEvaded", false) or getMiscVal(modDB, "weapon1", "cannotBeEvaded", false) then
			output.total_hitChance = 1
		else
			output.total_accuracy = calcVal(modDB, "accuracy")
			local targetLevel = getMiscVal(modDB, "misc", "hitMonsterLevel", false) and m_min(getMiscVal(modDB, "monster", "level", 1), #data.enemyEvasionTable) or m_max(m_min(env.build.characterLevel, 79), 1)
			local targetEvasion = data.enemyEvasionTable[targetLevel]
			if env.mode_effective then
				targetEvasion = targetEvasion * getMiscVal(modDB, "effective", "evasionMore", 1)
			end
			output.total_hitChance = calcHitChance(targetEvasion, output.total_accuracy)
		end
		endWatch(env, "dps_hitChance")
	end

	-- Calculate average damage and final DPS
	output.total_averageHit = (combMin + combMax) / 2 * output.total_critEffect
	output.total_averageDamage = output.total_averageHit * output.total_hitChance
	output.total_dps = output.total_averageDamage * output.total_speed * getMiscVal(modDB, "skill", "dpsMultiplier", 1)

	-- Calculate mana cost (may be slightly off due to rounding differences)
	output.total_manaCost = m_floor(m_max(0, getMiscVal(modDB, "skill", "manaCostBase", 0) * (1 + sumMods(modDB, false, "manaCostInc") / 100) * sumMods(modDB, true, "manaCostMore") - sumMods(modDB, false, "manaCostBase")))

	-- Calculate AoE stats
	if env.skillFlags.aoe then
		output.total_aoeRadiusMod = (1 + sumMods(modDB, false, "aoeRadiusInc") / 100) * sumMods(modDB, true, "aoeRadiusMore")
	end

	-- Calculate skill duration
	if startWatch(env, "duration") then
		local durationBase = getMiscVal(modDB, "skill", "durationBase", 0)
		output.total_durationMod = (1 + sumMods(modDB, false, "durationInc") / 100) * sumMods(modDB, true, "durationMore")
		if durationBase > 0 then
			output.total_duration = durationBase * output.total_durationMod
		end
		endWatch(env, "duration")
	end

	-- Calculate trap and mine stats stats
	if startWatch(env, "trapMine") then
		if env.skillFlags.trap then
			output.total_trapCooldown = getMiscVal(modDB, "skill", "trapCooldown", 4) / (1 + getMiscVal(modDB, nil, "trapCooldownRecoveryInc", 0) / 100)
			output.total_activeTrapLimit = sumMods(modDB, false, "activeTrapLimit")
		end
		if env.skillFlags.mine then
			output.total_activeMineLimit = sumMods(modDB, false, "activeMineLimit")
		end
		endWatch(env, "trapMine")
	end

	-- Calculate enemy stun modifiers
	if startWatch(env, "enemyStun") then
		local enemyStunThresholdRed = -sumMods(modDB, false, "stunEnemyThresholdInc")
		if enemyStunThresholdRed > 75 then
			output.stun_enemyThresholdMod = 1 - (75 + (enemyStunThresholdRed - 75) * 25 / (enemyStunThresholdRed - 50)) / 100
		else
			output.stun_enemyThresholdMod = 1 - enemyStunThresholdRed / 100
		end
		output.stun_enemyDuration = 0.35 * (1 + sumMods(modDB, false, "stunEnemyDurationInc") / 100)
		endWatch(env, "enemyStun")
	end

	-- Calculate skill DOT components
	output.total_damageDot = 0
	for _, damageType in pairs(dmgTypeList) do
		if startWatch(env, damageType.."Dot", "enemyResist", "canDeal") then
			local baseVal 
			if canDeal[damageType] then
				baseVal = getMiscVal(modDB, "skill", damageType.."DotBase", 0)
			else
				baseVal = 0
			end
			if baseVal > 0 then
				env.skillFlags.dot = true
				buildSpaceTable(modDB, {
					dot = true,
					debuff = env.skillSpaceFlags.debuff,
					spell = getMiscVal(modDB, "skill", "dotIsSpell", false),
					projectile = env.skillSpaceFlags.projectile,
					aoe = env.skillSpaceFlags.aoe,
					totem = env.skillSpaceFlags.totem,
					trap = env.skillSpaceFlags.trap,
					mine = env.skillSpaceFlags.mine,
				})
				local effMult = 1
				if env.mode_effective then
					local preMult
					local taken = getMiscVal(modDB, "effective", damageType.."TakenInc", 0) + getMiscVal(modDB, "effective", "damageTakenInc", 0) + getMiscVal(modDB, "effective", "dotTakenInc", 0)
					if damageType == "physical" then
						taken = taken - getMiscVal(modDB, "effective", "physicalRed", 0)
						preMult = 1
					else
						if isElemental[damageType] then
							taken = taken + getMiscVal(modDB, "effective", "elementalTakenInc", 0)
						end
						preMult = 1 - output["enemy_"..damageType.."Resist"] / 100
					end
					effMult = preMult * (1 + taken / 100)
				end
				output["total_"..damageType.."Dot"] = baseVal
					* (1 + sumMods(modDB, false, "damageInc", damageType.."Inc", isElemental[damageType] and "elementalInc" or nil) / 100) 
					* sumMods(modDB, true, "damageMore", damageType.."More", isElemental[damageType] and "elementalMore" or nil) 
					* effMult
			end
			buildSpaceTable(modDB, env.skillSpaceFlags)
			endWatch(env, damageType.."Dot")
		end
		output.total_damageDot = output.total_damageDot + (output["total_"..damageType.."Dot"] or 0)
	end

	-- Calculate bleeding chance and damage
	env.skillFlags.bleed = false
	if startWatch(env, "bleed", "canDeal", "physical", "dps_crit") then
		output.bleed_chance = m_min(100, sumMods(modDB, false, "bleedChance")) / 100
		if canDeal.physical and output.bleed_chance > 0 and output.total_physicalAvg > 0 then
			env.skillFlags.dot = true
			env.skillFlags.bleed = true
			env.skillFlags.duration = true
			buildSpaceTable(modDB, {
				dot = true,
				debuff = true,
				bleed = true,
				projectile = env.skillSpaceFlags.projectile,
				aoe = env.skillSpaceFlags.aoe,
				totem = env.skillSpaceFlags.totem,
				trap = env.skillSpaceFlags.trap,
				mine = env.skillSpaceFlags.mine,
			})
			local baseVal = output.total_physicalAvg * output.total_critEffect * 0.1
			local effMult = 1
			if env.mode_effective then
				local taken = getMiscVal(modDB, "effective", "physicalTakenInc", 0) + getMiscVal(modDB, "effective", "damageTakenInc", 0) + getMiscVal(modDB, "effective", "dotTakenInc", 0) - getMiscVal(modDB, "effective", "physicalRed", 0)
				effMult = 1 + taken / 100
			end
			output.bleed_dps = baseVal * (1 + sumMods(modDB, false, "damageInc", "physicalInc") / 100) * sumMods(modDB, true, "damageMore", "physicalMore") * effMult
			output.bleed_duration = 5 * (1 + sumMods(modDB, false, "durationInc") / 100) * sumMods(modDB, true, "durationMore")
			buildSpaceTable(modDB, env.skillSpaceFlags)
		end	
		endWatch(env, "bleed")
	end

	-- Calculate poison chance and damage
	env.skillFlags.poison = false
	if startWatch(env, "poison", "canDeal", "physical", "chaos", "dps_crit", "enemyResist") then
		output.poison_chance = m_min(100, sumMods(modDB, false, "poisonChance")) / 100
		if canDeal.chaos and output.poison_chance > 0 and (output.total_physicalAvg > 0 or output.total_chaosAvg > 0) then
			env.skillFlags.dot = true
			env.skillFlags.poison = true
			env.skillFlags.duration = true
			buildSpaceTable(modDB, {
				dot = true,
				debuff = true,
				spell = getMiscVal(modDB, "skill", "dotIsSpell", false),
				poison = true,
				projectile = env.skillSpaceFlags.projectile,
				aoe = env.skillSpaceFlags.aoe,
				totem = env.skillSpaceFlags.totem,
				trap = env.skillSpaceFlags.trap,
				mine = env.skillSpaceFlags.mine,
			})
			local baseVal = (output.total_physicalAvg + output.total_chaosAvg) * output.total_critEffect * 0.08
			local effMult = 1
			if env.mode_effective then
				local taken = getMiscVal(modDB, "effective", "chaosTakenInc", 0) + getMiscVal(modDB, "effective", "damageTakenInc", 0) + getMiscVal(modDB, "effective", "dotTakenInc", 0)
				effMult = (1 - output["enemy_chaosResist"] / 100) * (1 + taken / 100)
			end
			output.poison_dps = baseVal * (1 + sumMods(modDB, false, "damageInc", "chaosInc") / 100) * sumMods(modDB, true, "damageMore", "chaosMore") * effMult
			output.poison_duration = 2 * (1 + sumMods(modDB, false, "durationInc") / 100) * sumMods(modDB, true, "durationMore")
			buildSpaceTable(modDB, env.skillSpaceFlags)
		end	
		endWatch(env, "poison")
	end

	-- Calculate ignite chance and damage
	env.skillFlags.ignite = false
	if startWatch(env, "ignite", "canDeal", "fire", "cold", "dps_crit", "enemyResist") then
		output.ignite_chance = m_min(100, sumMods(modDB, false, "igniteChance")) / 100
		local sourceDmg = 0
		if canDeal.fire and not getMiscVal(modDB, nil, "fireCannotIgnite", false) then
			sourceDmg = sourceDmg + output.total_fireAvg
		end
		if canDeal.cold and getMiscVal(modDB, nil, "coldCanIgnite", false) then
			sourceDmg = sourceDmg + output.total_coldAvg
		end
		if canDeal.fire and output.ignite_chance > 0 and sourceDmg > 0 then
			env.skillFlags.dot = true
			env.skillFlags.ignite = true
			buildSpaceTable(modDB, {
				dot = true,
				debuff = true,
				spell = getMiscVal(modDB, "skill", "dotIsSpell", false),
				ignite = true,
				projectile = env.skillSpaceFlags.projectile,
				aoe = env.skillSpaceFlags.aoe,
				totem = env.skillSpaceFlags.totem,
				trap = env.skillSpaceFlags.trap,
				mine = env.skillSpaceFlags.mine,
			})
			local baseVal = sourceDmg * output.total_critEffect * 0.2
			local effMult = 1
			if env.mode_effective then
				local taken = getMiscVal(modDB, "effective", "fireTakenInc", 0) + getMiscVal(modDB, "effective", "elementalTakenInc", 0) + getMiscVal(modDB, "effective", "damageTakenInc", 0) + getMiscVal(modDB, "effective", "dotTakenInc", 0)
				effMult = (1 - output["enemy_fireResist"] / 100) * (1 + taken / 100)
			end
			output.ignite_dps = baseVal * (1 + sumMods(modDB, false, "damageInc", "fireInc", "elementalInc") / 100) * sumMods(modDB, true, "damageMore", "fireMore", "elementalMore") * effMult
			output.ignite_duration = 4 * (1 + getMiscVal(modDB, "ignite", "durationInc", 0) / 100)
			buildSpaceTable(modDB, env.skillSpaceFlags)
		end
		endWatch(env, "ignite")
	end

	-- Calculate shock and freeze chance + duration modifier
	if startWatch(env, "shock", "canDeal", "lightning", "fire", "chaos") then
		output.shock_chance = m_min(100, sumMods(modDB, false, "shockChance")) / 100
		local sourceDmg = 0
		if canDeal.lightning and not getMiscVal(modDB, nil, "lightningCannotShock", false) then
			sourceDmg = sourceDmg + output.total_lightningAvg
		end
		if canDeal.fire and getMiscVal(modDB, nil, "fireCanShock", false) then
			sourceDmg = sourceDmg + output.total_fireAvg
		end
		if canDeal.chaos and getMiscVal(modDB, nil, "chaosCanShock", false) then
			sourceDmg = sourceDmg + output.total_chaosAvg
		end
		if output.shock_chance > 0 and sourceDmg > 0 then
			env.skillFlags.shock = true
			output.shock_durationMod = 1 + getMiscVal(modDB, "shock", "durationInc", 0) / 100
 		end
	end
	if startWatch(env, "freeze", "canDeal", "cold", "lightning") then
		output.freeze_chance = m_min(100, sumMods(modDB, false, "freezeChance")) / 100
		local sourceDmg = 0
		if canDeal.cold and not getMiscVal(modDB, nil, "coldCannotFreeze", false) then
			sourceDmg = sourceDmg + output.total_coldAvg
		end
		if canDeal.lightning and getMiscVal(modDB, nil, "lightningCanFreeze", false) then
			sourceDmg = sourceDmg + output.total_lightningAvg
		end
		if output.freeze_chance > 0 and sourceDmg > 0 then
			env.skillFlags.freeze = true
			output.freeze_durationMod = 1 + getMiscVal(modDB, "freeze", "durationInc", 0) / 100
		end
	end

	-- Calculate combined DPS estimate, including DoTs
	output.total_combinedDPS = output[(env.mode_average and "total_averageDamage") or "total_dps"] + output.total_damageDot
	if env.skillFlags.poison then
		if env.mode_average then
			output.total_combinedDPS = output.total_combinedDPS + output.poison_chance * output.poison_dps * output.poison_duration
		else
			output.total_combinedDPS = output.total_combinedDPS + output.poison_chance * output.poison_dps * output.poison_duration * output.total_speed
		end
	end
	if env.skillFlags.ignite then
		output.total_combinedDPS = output.total_combinedDPS + output.ignite_dps
	end
	if env.skillFlags.bleed then
		output.total_combinedDPS = output.total_combinedDPS + output.bleed_dps
	end
end

local calcs = { }

-- Wipe mod database and repopulate with base mods
local function resetModDB(modDB, base)
	for spaceName, spaceMods in pairs(modDB) do
		local baseSpace = base[spaceName]
		if baseSpace then
			for k in pairs(spaceMods) do
				spaceMods[k] = baseSpace[k]
			end
		else
			wipeTable(spaceMods)
		end
	end
end

-- Print various tables to the console
local function infoDump(env, output)
	ConPrintf("== Modifier Database ==")
	modLib.dbPrint(env.modDB)
	ConPrintf("== Main Skill ==")
	for _, gem in ipairs(env.mainSkill.validGemList) do
		ConPrintf("%s %d/%d", gem.name, gem.effectiveLevel, gem.effectiveQuality)
	end
	ConPrintf("== Main Skill Mods ==")
	modLib.listPrint(env.mainSkill.skillModList)
	ConPrintf("== Main Skill Flags ==")
	modLib.listPrint(env.skillFlags)
	ConPrintf("== Namespaces ==")
	modLib.listPrint(env.skillSpaceFlags)
	ConPrintf("== Aux Skills ==")
	for i, aux in ipairs(env.auxSkills) do
		ConPrintf("Skill #%d:", i)
		for _, gem in ipairs(aux.gemList) do
			ConPrintf("  %s %d/%d", gem.name, gem.effectiveLevel or gem.level, gem.effectiveQuality or gem.quality)
		end
	end
	--[[ConPrintf("== Buff Skill Mods ==")
	modLib.listPrint(env.buffSkillModList)
	ConPrintf("== Aura Skill Mods ==")
	modLib.listPrint(env.auraSkillModList)
	ConPrintf("== Curse Skill Mods ==")
	modLib.listPrint(env.curseSkillModList)]]
	if env.buffModList then
		ConPrintf("== Other Buff Mods ==")
		modLib.listPrint(env.buffModList)
	end
	ConPrintf("== Spec Mods ==")
	modLib.listPrint(env.specModList)
	ConPrintf("== Item Mods ==")
	modLib.listPrint(env.itemModList)
	ConPrintf("== Conditions ==")
	modLib.listPrint(env.condList)
	ConPrintf("== Conditional Modifiers ==")
	modLib.listPrint(env.condModList)
	ConPrintf("== Conversion Table ==")
	modLib.dbPrint(output.conversionTable)
end

-- Generate a function for calculating the effect of some modification to the environment
local function getCalculator(build, input, fullInit, modFunc)
	-- Initialise environment
	local env = initEnv(build, input, "MAIN")

	-- Save a copy of the initial mod database
	if fullInit then
		mergeMainMods(env)
	end
	local initModDB = copyTable(env.modDB)
	if not fullInit then
		mergeMainMods(env)
	end

	-- Finialise modifier database and make a copy for later comparison
	local baseOutput = { }
	local outputMeta = { __index = baseOutput }
	finaliseMods(env, baseOutput)
	local baseModDB = copyTable(env.modDB)

	-- Run base calculation pass while building watch lists
	env.watchers = { }
	env.buildWatch = true
	env.modDB._activeWatchers = { }
	performCalcs(env, baseOutput)
	env.buildWatch = false
	env.modDB._activeWatchers = nil

	-- Generate list of watched mods
	local watchedModList = { }
	for _, watchList in pairs(env.watchers) do
		for k, default in pairs(watchList) do
			-- Add this watcher to the mod's watcher list
			local spaceName, modName = modLib.getSpaceName(k)
			if not watchedModList[spaceName] then
				watchedModList[spaceName] = { }
			end
			if not baseModDB[spaceName] then
				baseModDB[spaceName] = { }
			end
			if not initModDB[spaceName] then
				initModDB[spaceName] = { }
			end
			if not watchedModList[spaceName][modName] then				
				watchedModList[spaceName][modName] = { baseModDB[spaceName][modName], { } }
			end
			watchedModList[spaceName][modName][2][watchList] = true
			if initModDB[spaceName][modName] == nil and baseModDB[spaceName][modName] ~= nil then
				-- Ensure that the initial mod list has at least a default value for any modifiers present in the base database
				initModDB[spaceName][modName] = default
			end
		end
	end

	local flagged = { }
	return function(...)
		-- Restore initial mod database
		resetModDB(env.modDB, initModDB)

		-- Call function to make modifications to the enviroment
		modFunc(env, ...)
		
		-- Prepare for calculation
		local output = setmetatable({ }, outputMeta)
		finaliseMods(env, output)

		--[[local debugThis = type(...) == "table" and #(...) == 1 and (...)[1].id == 17735
		if debugThis then
			ConPrintf("+++++++++++++++++++++++++++++++++++++++")
		end]]

		-- Check if any watched mods have changed
		local active = false
		for spaceName, watchedMods in pairs(watchedModList) do
			for k, v in pairs(env.modDB[spaceName]) do
				local watchedMod = watchedMods[k]
				if watchedMod and v ~= watchedMod[1] then
					-- Modifier value has changed, flag all watchers for this mod
					for watchList in pairs(watchedMod[2]) do
						watchList._flag = true
						flagged[watchList] = true
					end
					--[[if debugThis then
						ConPrintf("%s:%s %s %s", spaceName, k, watchedMod[1], v)
					end]]
					active = true
				end
			end
		end
		if not active then
			return baseOutput
		end

		-- Run the calculations
		performCalcs(env, output)

		--[[if debugThis then
			infoDump(env, output)
		end]]

		-- Reset watcher flags
		for watchList in pairs(flagged) do
			watchList._flag = false
			flagged[watchList] = nil
		end

		return output
	end, baseOutput	
end

-- Get calculator for tree node modifiers
function calcs.getNodeCalculator(build, input)
	return getCalculator(build, input, true, function(env, nodeList, remove)
		-- Build and merge/unmerge modifiers for these nodes
		local nodeModList = buildNodeModList(env, nodeList)
		if remove then
			mod_dbUnmergeList(env.modDB, nodeModList)
		else
			mod_dbMergeList(env.modDB, nodeModList)
		end
	end)
end

-- Get calculator for item modifiers
function calcs.getItemCalculator(build, input)
	return getCalculator(build, input, false, function(env, repSlotName, repItem)
		-- Merge main mods, replacing the item in the given slot with the given item
		mergeMainMods(env, repSlotName, repItem)
	end)
end

-- Build output for display in the grid or side bar
function calcs.buildOutput(build, input, output, mode)
	-- Build output
	local env = initEnv(build, input, mode)
	mergeMainMods(env)
	finaliseMods(env, output)
	performCalcs(env, output)

	output.total_extraPoints = getMiscVal(env.modDB, nil, "extraPoints", 0)

	-- Add extra display-only stats
	for k, v in pairs(env.specModList) do
		output["spec_"..k] = v
	end
	for k, v in pairs(env.itemModList) do
		output["gear_"..k] = v
	end

	if mode == "GRID" then
		for i, aux in pairs(env.auxSkills) do
			output["buff_label"..i] = aux.displayLabel
		end
		for _, damageType in pairs(dmgTypeList) do
			-- Add damage ranges
			if output["total_"..damageType.."Max"] > 0 then
				output["total_"..damageType] = formatRound(output["total_"..damageType.."Min"]) .. " - " .. formatRound(output["total_"..damageType.."Max"])		
			else
				output["total_"..damageType] = 0
			end
		end
		output.total_damage = formatRound(output.total_combMin) .. " - " .. formatRound(output.total_combMax)

		-- Calculate XP modifier
		if input.monster_level and input.monster_level > 0 then
			local playerLevel = build.characterLevel
			local diff = m_abs(playerLevel - input.monster_level) - 3 - m_floor(playerLevel / 16)
			if diff <= 0 then
				output.monster_xp = 1
			else
				output.monster_xp = m_max(0.01, ((playerLevel + 5) / (playerLevel + 5 + diff ^ 2.5)) ^ 1.5)
			end
		end

		-- Configure view mode
		setViewMode(env, build.skillsTab.list)

		infoDump(env, output)
	end
end

return calcs
