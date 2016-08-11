-- Path of Building
--
-- Module: CalcsControl
-- Control script for calculations
--
local grid = ...

local pairs = pairs
local ipairs = ipairs
local m_abs = math.abs
local m_ceil = math.ceil
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local t_insert = table.insert

local mod_listMerge = modLib.listMerge
local mod_listScaleMerge = modLib.listScaleMerge
local mod_dbMerge = modLib.dbMerge
local mod_dbScaleMerge = modLib.dbScaleMerge
local mod_dbUnmerge = modLib.dbUnmerge
local mod_dbMergeList = modLib.dbMergeList
local mod_dbUnmergeList = modLib.dbUnmergeList

local setViewMode = LoadModule("Modules/CalcsView", grid)

local isElemental = { fire = true, cold = true, lightning = true }

local dmgTypeList = {"physical", "lightning", "cold", "fire", "chaos"}

-- Parse gem list specification
local function parseGemSpec(spec, out)
	for nameSpec, numSpec in spec:gmatch("(%a[%a ]*)%s+([%d/\\]+)") do
		-- Search for gem name using increasingly broad search patterns
		local patternList = {
			"^ "..nameSpec.."$", -- Exact match
			"^"..nameSpec:gsub("%a", " %0%%l+").."$", -- Simple abbreviation ("CtF" -> "Cold to Fire")
			"^"..nameSpec:gsub("%l", "%%l*%0").."%l+$", -- Abbreviated words ("CldFr" -> "Cold to Fire")
			"^"..nameSpec:gsub("%a", ".*%0") -- Global abbreviation ("CtoF" -> "Cold to Fire")
		}
		local gemName, gemData
		for i, pattern in ipairs(patternList) do
			for name, data in pairs(data.gems) do
				if (" "..name):match(pattern) then
					if gemName then
						return "Ambiguous gem name '"..nameSpec.."'\nMatches '"..gemName.."', '"..name.."'"
					end
					gemName = name
					gemData = data
				end
			end
			if gemName then
				break
			end
		end
		if not gemName then
			return "Unrecognised gem name '"..nameSpec.."'"
		end
		if gemData.unsupported then
			return "Gem '"..gemName.."' is unsupported"
		end

		-- Parse level/quality specification
		local level, quality = numSpec:match("(%d+)[/\\](%d+)")
		if level then
			level = tonumber(level)
			quality = tonumber(quality)
		else
			level = tonumber(numSpec)
			quality = 0
		end
		if not level or level < 1 or level > #gemData.levels or quality < 0 then
			return "Invalid level or level/quality specification '"..numSpec.."'"
		end

		-- Add to output list
		t_insert(out, {
			name = gemName,
			nameSpec = nameSpec,
			level = level,
			quality = quality,
			data = gemData
		})
	end	
end

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

-- Merge gem modifiers
local function mergeGemMods(modList, gem)
	for k, v in pairs(gem.data.base) do
		mod_listMerge(modList, k, v)
	end
	for k, v in pairs(gem.data.quality) do
		mod_listMerge(modList, k, m_floor(v * gem.quality))
	end
	for k, v in pairs(gem.data.levels[gem.level]) do
		mod_listMerge(modList, k, v)
	end
end

-- Merge auxillary skill mods
local function mergeAuxMods(modDB, modList, space, effectMod)
	local filter = "^"..space.."_"
	for k, v in pairs(modList) do
		if k:match(filter) then
			k = k:gsub(filter,"")
			if effectMod then
				mod_dbScaleMerge(modDB, nil, k, v, effectMod)
			else
				mod_dbMerge(modDB, nil, k, v)
			end
		end
	end
end

-- Merge modifiers for all items, optionally replacing one item
local function mergeItemMods(env, build, repSlotName, repItem)
	-- Build and merge item mods
	env.itemModList = wipeTable(env.itemModList)
	for slotName, slot in pairs(build.items.slots) do
		local slotNum = tonumber(slotName:match("%d+"))
		local item
		if slotName == repSlotName then
			item = repItem
		else
			item = build.items.list[slot.selItemId]
		end
		if slotName:match("Jewel") and not build.spec.allocNodes[slotNum] then
			item = nil
		end
		if item then
			local armourType = item.base.armour and item.type
			for k, v in pairs(item.modList) do
				if slotName == "Weapon 1" then
					k = k:gsub("weaponX_","weapon1_")
				elseif slotName == "Weapon 2" then
					k = k:gsub("weaponX_","weapon2_")
				end
				if slotNum then
					k = k:gsub("IfSlot:"..slotNum.."_","")
				end
				if armourType and (k == "armourBase" or k == "evasionBase" or k == "energyShieldBase") then
					k = "slot:"..armourType.."_"..k
				end
				mod_listMerge(env.itemModList, k, v)
			end
			if item.type ~= "Jewel" then
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

	-- Find radius jewels
	env.radiusJewelList = wipeTable(env.radiusJewelList)
	for nodeId, node in pairs(build.spec.allocNodes) do
		if node.type == "socket" then
			local socket, jewel = build.items:GetSocketAndJewelForNodeID(nodeId)
			if socket.slotName == repSlotName then
				jewel = repItem
			end
			if jewel and jewel.jewelRadiusIndex and jewel.jewelFunc then
				t_insert(env.radiusJewelList, {
					rSq = data.jewelRadius[jewel.jewelRadiusIndex].rad * data.jewelRadius[jewel.jewelRadiusIndex].rad,
					x = node.x,
					y = node.y,
					func = jewel.jewelFunc,
					data = { }
				})
			end
		end
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
	local nodeModList = { }
	for _, node in pairs(nodeList) do
		-- Build list of mods from this node
		for _, mod in pairs(node.mods) do
			if mod.list and not mod.extra then
				for k, v in pairs(mod.list) do
					mod_listMerge(nodeModList, k, v)
				end
			end
		end

		-- Run radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			local vX, vY = node.x - rad.x, node.y - rad.y
			if vX * vX + vY * vY <= rad.rSq then
				rad.func(nodeModList, modList, rad.data)
			end
		end

		-- Merge with output list
		for k, v in pairs(nodeModList) do
			mod_listMerge(modList, k, v)
			nodeModList[k] = nil
		end
		if node.passivePointsGranted > 0 then
			mod_listMerge(modList, "extraPoints", node.passivePointsGranted)
		end
	end

	if finishJewels then
		-- Finish radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			rad.func(nil, modList, rad.data)
		end
	end

	return modList
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

-- Start watched section
local function startWatch(env, key, ...)
	if env.buildWatch then 
		env.watchers[key] = { _key = key }
		env.modDB._activeWatchers[env.watchers[key]] = true
		return true
	else
		if not env.watchers or env.spacesChanged or not env.watchers[key] or env.watchers[key]._flag then
			return true
		end
		for i = 1, select('#', ...) do
			if env.watchers[select(i, ...)]._flag then
				return true
			end
		end
	end
end

-- End watched section
local function endWatch(env, key)
	if env.buildWatch and env.watchers[key] then
		env.modDB._activeWatchers[env.watchers[key]] = nil
	end
end

-- Calculate min/max damage of a hit for the given damage type
local function calcHitDamage(env, output, damageType, ...)
	local modDB = env.modDB
	local isAttack = (env.mode == "ATTACK")

	local damageTypeMin = damageType.."Min"
	local damageTypeMax = damageType.."Max"

	-- Calculate base values
	local baseMin, baseMax
	if isAttack then
		baseMin = getMiscVal(modDB, "weapon1", damageTypeMin, 0) + sumMods(modDB, false, damageTypeMin)
		baseMax = getMiscVal(modDB, "weapon1", damageTypeMax, 0) + sumMods(modDB, false, damageTypeMax)
	else
		local damageEffectiveness = getMiscVal(modDB, "skill", "damageEffectiveness", 1)
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
	local damageTypeStrMore = damageTypeStr.."More"
	if startWatch(env, damageTypeStrInc) then
		output[damageTypeStrInc] = sumMods(modDB, false, unpack(inc))
		endWatch(env, damageTypeStrInc)
	end
	if startWatch(env, damageTypeStrMore) then
		output[damageTypeStrMore] = sumMods(modDB, true, unpack(more))
		endWatch(env, damageTypeStrMore)
	end
	local modMult = (1 + output[damageTypeStrInc] / 100) * output[damageTypeStrMore]

	-- Calculate conversions
	if startWatch(env, damageTypeStr.."Conv") then
		local addMin, addMax = 0, 0
		local mult = 1
		for _, otherType in pairs(dmgTypeList) do
			if otherType ~= damageType then
				if damageType ~= "physical" then
					-- Damage added or converted from the other damage type
					local gain = sumMods(modDB, false, otherType.."GainAs"..damageType, otherType.."ConvertTo"..damageType) / 100
					if gain > 0 then
						local min, max = calcHitDamage(env, output, otherType, damageType, ...)
						addMin = addMin + min * gain
						addMax = addMax + max * gain
					end
				end
				if damageType ~= "chaos" and not (...) then
					local convTo = sumMods(modDB, false, damageType.."ConvertTo"..otherType) / 100
					if convTo > 0 then
						-- Some of this damage type is being converted to the other type
						-- Not applied to damage being calculated for conversion
						mult = mult - convTo
					end
				end
			end
		end
		output[damageTypeStr.."ConvAddMin"] = addMin
		output[damageTypeStr.."ConvAddMax"] = addMax
		output[damageTypeStr.."ConvMult"] = mult
		endWatch(env, damageTypeStr.."Conv")
	end

	local finalMult = (...) and 1 or (output[damageTypeStr.."ConvMult"] * sumMods(modDB, true, damageType.."FinalMore"))
	return  (baseMin * modMult + output[damageTypeStr.."ConvAddMin"]) * finalMult,
			(baseMax * modMult + output[damageTypeStr.."ConvAddMax"]) * finalMult
end

-- Initialise environment with skill, input and spec data
local function initEnv(input, build)
	local env = { }

	-- Parse gem specification
	local gemList = { }
	env.gemList = gemList
	local errMsg = parseGemSpec(input.skill_spec or "", gemList)
	if errMsg then
		return nil, errMsg
	end

	-- Find active skill gem
	local activeGem
	for _, gem in ipairs(gemList) do
		if not gem.data.support then
			if activeGem then
				return nil, "Multiple active gems specified:\n"..activeGem.name..", "..gem.name
			end
			activeGem = gem
		end
	end

	-- Default attack if no active gem provided
	if not activeGem then
		activeGem = {
			name = "Default Attack",
			level = 1,
			quality = 0,
			data = data.gems._default
		}
		gemList = { activeGem }
	end
	env.skillName = activeGem.name

	env.setupFunc = activeGem.data.setupFunc

	-- Build base skill flag set ('attack', 'projectile', etc)
	local baseFlags = { }
	env.baseFlags = baseFlags
	for k, v in pairs(activeGem.data) do
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

	-- Build skill modifier list
	local skillModList = { }
	env.skillModList = skillModList
	for _, gem in ipairs(gemList) do
		if gem.data.support and 
		  (gem.data.attack and not baseFlags.attack) or
		  (gem.data.spell and not baseFlags.spell) or
		  (gem.data.melee and not baseFlags.melee) or
		  (gem.data.projectile and not baseFlags.projectile) or
		  (gem.data.duration and not baseFlags.duration) or
		  (gem.data.totem and not baseFlags.totem) or
		  (gem.data.trap and not baseFlags.trap and not (gem.data.mine and baseFlags.mine)) or
		  (gem.data.mine and not baseFlags.mine and not (gem.data.trap and baseFlags.trap)) then
			-- This support doesn't apply
			gem.cantSupport = true
		else
			mergeGemMods(skillModList, gem)
		end
	end

	-- Handle multipart skills
	if activeGem.data.parts then
		input.skill_part = m_max(1, m_min(#activeGem.data.parts, input.skill_part or 1))
		local part = activeGem.data.parts[input.skill_part]
		env.skillPartName = part.name
		for k, v in pairs(part) do
			if v == true then
				baseFlags[k] = true
			elseif v == false then
				baseFlags[k] = nil
			end
		end
		baseFlags.multiPart = #activeGem.data.parts > 1
	else
		env.skillPartName = ""
	end

	-- Set skill mode
	if baseFlags.attack then
		env.mode = "ATTACK"
	else
		env.mode = "SPELL"
	end

	-- Process auras and buff skills
	local auxSkillModList = { }
	env.auxSkillModList = auxSkillModList
	for i = 1, 10 do
		local spec = input["buff_spec"..i]
		if spec and #spec > 0 then
			-- Parse gem specification
			local gemList = { }
			local errMsg = parseGemSpec(spec, gemList)
			if errMsg then
				return nil, "In aux skill "..i..": "..errMsg
			end

			-- Find active skill
			local activeGem
			for _, gem in ipairs(gemList) do
				if not gem.data.support then
					if activeGem then
						return nil, "Multiple active gems specified in aux skill "..i..":\n"..activeGem.name..", "..gem.name
					end
					activeGem = gem
				end
			end

			-- Merge modifiers
			if activeGem then
				mergeGemMods(auxSkillModList, activeGem)
			end
		end
	end

	-- Initialise modifier database with base values
	local modDB = { }
	env.modDB = modDB
	env.classId = build.spec.curClassId
	local classStats = build.tree.characterData[env.classId]
	for _, stat in pairs({"str","dex","int"}) do
		mod_dbMerge(modDB, "", stat.."Base", classStats["base_"..stat])
	end
	local level = input.player_level or 1
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

	-- Add bandit mods
	if input.misc_banditNormal == "Alira" then
		mod_dbMerge(modDB, "", "manaBase", 60)
	elseif input.misc_banditNormal == "Kraityn" then
		mod_dbMerge(modDB, "", "elementalResist", 10)
	elseif input.misc_banditNormal == "Oak" then
		mod_dbMerge(modDB, "", "lifeBase", 40)
	else
		mod_dbMerge(modDB, "", "extraPoints", 1)
	end
	if input.misc_banditCruel == "Alira" then
		mod_dbMerge(modDB, "", "castSpeedInc", 5)
	elseif input.misc_banditCruel == "Kraityn" then
		mod_dbMerge(modDB, "", "attackSpeedInc", 8)
	elseif input.misc_banditCruel == "Oak" then
		mod_dbMerge(modDB, "", "physicalInc", 16)
	else
		mod_dbMerge(modDB, "", "extraPoints", 1)
	end
	if input.misc_banditMerc == "Alira" then
		mod_dbMerge(modDB, "", "powerMax", 1)
	elseif input.misc_banditMerc == "Kraityn" then
		mod_dbMerge(modDB, "", "frenzyMax", 1)
	elseif input.misc_banditMerc == "Oak" then
		mod_dbMerge(modDB, "", "enduranceMax", 1)
	else
		mod_dbMerge(modDB, "", "extraPoints", 1)
	end

	-- Merge skill mods
	mod_dbMergeList(modDB, skillModList)
	if baseFlags.multiPart and modDB["part"..input.skill_part] then
		-- Merge active skill part mods
		mod_dbMergeList(modDB, modDB["part"..input.skill_part])
	end
	if modDB.buff then
		-- Merge buff modifers for this skill
		mod_dbMergeList(modDB, modDB.buff)
	end

	-- Merge buff skill modifiers (auras and curses are added later)
	mergeAuxMods(modDB, auxSkillModList, "BuffEffect")

	-- Add mods from the input table
	mod_dbMergeList(modDB, input)

	return env
end

-- Prepare environment for calculations
local function calcSetup(env, output)
	local modDB = env.modDB

	local weapon1Type = getMiscVal(modDB, "weapon1", "type", "None")
	local weapon2Type = getMiscVal(modDB, "weapon2", "type", "")
	if weapon1Type == env.weapon1Type and weapon2Type == env.weapon2Type then
		env.spacesChanged = false
	else
		env.spacesChanged = true
		env.weapon1Type = weapon1Type
		env.weapon2Type = weapon2Type
		
		-- Initialise skill flag set
		local skillFlags = wipeTable(env.skillFlags)
		for k, v in pairs(env.baseFlags) do
			skillFlags[k] = v
		end
		env.skillFlags = skillFlags

		-- Set weapon flags
		skillFlags.mainIs1H = true
		local weapon1Info = data.weaponTypeInfo[weapon1Type]
		if weapon1Info then
			if not weapon1Info.oneHand then
				skillFlags.mainIs1H = nil
			end
			if skillFlags.attack then
				skillFlags.weapon1Attack = true
				if weapon1Info.melee then
					skillFlags.bow = nil
					skillFlags.projectile = nil
				else
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
			skillSpaceFlags[weapon1Info.space] = true
			if weapon1Type ~= "None" then
				skillSpaceFlags["weapon"] = true
				if skillFlags.mainIs1H then
					skillSpaceFlags["weapon1h"] = true
					if skillFlags.melee then
						skillSpaceFlags["weapon1hMelee"] = true
					else
						skillSpaceFlags["weaponRanged"] = true
					end
				else
					skillSpaceFlags["weapon2h"] = true
					if skillFlags.melee then
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
		elseif skillFlags.mine then
			skillSpaceFlags["mine"] = true
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
		for k, v in pairs(data.unarmedWeap[env.classId]) do
			mod_dbMerge(modDB, "weapon1", k, v)
		end
	end
	
	-- Set modes
	output.mode = env.mode
	if env.skillFlags.showAverage then
		output.mode_average = true
	end
	local buffMode = getMiscVal(modDB, "misc", "buffMode", "")
	if buffMode == "With buffs" then
		env.mode_buffs = true
		env.mode_effective = false
	elseif buffMode == "Effective DPS with buffs" then
		env.mode_buffs = true
		env.mode_effective = true
	else
		env.mode_buffs = false
		env.mode_effective = false
	end
	
	-- Reset namespaces
	buildSpaceTable(modDB)

	-- Merge skill-specific modifiers
	if modDB["Skill:"..env.skillName] then
		mod_dbMergeList(modDB, modDB["Skill:"..env.skillName])
	end

	-- Build condition list
	local condList = { }
	env.condList = condList
	if env.weapon1Type == "Staff" then
		condList["UsingStaff"] = true
	end
	if env.skillFlags.mainIs1H then
		if env.weapon2Type == "Shield" then
			condList["UsingShield"] = true
		end
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
	local condModList = { }
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
		mod_dbMerge(modDB, "", "curseEffectInc", -60)
		mod_dbMerge(modDB, "effective", "elementalResist", 30)
		mod_dbMerge(modDB, "effective", "chaosResist", 15)
	end

	-- Add per-item-type mods
	for _, type in pairs({"Normal","Magic","Rare","Unique","GrandSpectrum"}) do
		if modDB["Per"..type] then
			local count = getMiscVal(modDB, "gear", type.."Count", 0)
			for k, v in pairs(modDB["Per"..type]) do
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

	-- Merge aura modifiers
	mergeAuxMods(modDB, env.auxSkillModList, "AuraEffect", 1 + getMiscVal(modDB, nil, "auraEffectInc", 0) / 100)

	if env.mode_effective then
		-- Merge curse modifiers
		mergeAuxMods(modDB, env.auxSkillModList, "CurseEffect", 1 + getMiscVal(modDB, nil, "curseEffectInc", 0) / 100)
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

-- Calculate primary stats: damage and defences
local function calcPrimary(env, output)
	local modDB = env.modDB

	-- Calculate defences
	if startWatch(env, "lifeES") then
		if getMiscVal(modDB, nil, "chaosInoculation", false) then
			output.total_life = 1
		else
			output.total_life = calcVal(modDB, "life")
		end
		local convManaToES = getMiscVal(modDB, nil, "manaGainAsEnergyShield", 0)
		if convManaToES > 0 then
			output.total_energyShield = sumMods(modDB, false, "manaBase") * (1 + sumMods(modDB, false, "energyShieldInc", "defencesInc", "manaInc") / 100) * sumMods(modDB, true, "energyShieldMore", "defencesMore", "manaMore") * convManaToES / 100
		else
			output.total_energyShield = 0
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
		if getMiscVal(modDB, nil, "vaalPact", false) then
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
		endWatch(env, "lifeES")
	end
	if startWatch(env, "mana") then
		output.total_mana = calcVal(modDB, "mana")
		mod_dbMerge(modDB, "", "manaRegenBase", output.total_mana * 0.0175)
		output.total_manaRegen = sumMods(modDB, false, "manaRegenBase") * (1 + sumMods(modDB, false, "manaRegenInc", "manaRecoveryInc") / 100) * sumMods(modDB, true, "manaRegenMore", "manaRecoveryMore")
		endWatch(env, "mana")
	end
	if startWatch(env, "otherDef") then
		output.total_evasion = 0
		output.total_armour = 0
		output.total_gear_evasionBase = env.itemModList.evasionBase or 0
		output.total_gear_armourBase = env.itemModList.armourBase or 0
		local ironReflexes = getMiscVal(modDB, nil, "ironReflexes", false)
		for _, slot in pairs({"global","slot:Helmet","slot:Body Armour","slot:Gloves","slot:Boots","slot:Shield"}) do
			buildSpaceTable(modDB, { [slot] = true })
			local evasionBase = getMiscVal(modDB, slot, "evasionBase", 0)
			local armourBase = getMiscVal(modDB, slot, "armourBase", 0)
			if ironReflexes then
				if evasionBase > 0 or armourBase > 0 then
					output.total_armour = output.total_armour + (evasionBase + armourBase) * (1 + sumMods(modDB, false, "armourInc", "evasionInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "armourMore", "evasionMore", "defencesMore")
				end
			else
				if evasionBase > 0 then
					output.total_evasion = output.total_evasion + evasionBase * (1 + sumMods(modDB, false, "evasionInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "evasionMore", "defencesMore")
				end
				if armourBase > 0 then
					output.total_armour = output.total_armour + armourBase * (1 + sumMods(modDB, false, "armourInc", "armourAndEvasionInc", "defencesInc") / 100) * sumMods(modDB, true, "armourMore", "defencesMore")
				end
			end
			if slot ~= "global" then
				output.total_gear_evasionBase = output.total_gear_evasionBase + evasionBase
				output.total_gear_armourBase = output.total_gear_armourBase + armourBase
			end
		end
		if getMiscVal(modDB, nil, "cannotEvade", false) then
			output.total_evadeChance = 0
		else
			local attackerLevel = getMiscVal(modDB, "misc", "evadeMonsterLevel", false) and m_min(getMiscVal(modDB, "monster", "level", 1), #data.enemyAccuracyTable) or m_min(getMiscVal(modDB, "player", "level", 1), 80)
			output.total_evadeChance = 1 - calcHitChance(output.total_evasion, data.enemyAccuracyTable[attackerLevel])
		end
		output.total_blockChanceMax = sumMods(modDB, false, "blockChanceMax")
		output.total_blockChance = m_min(sumMods(modDB, false, "blockChance") * (1 + sumMods(modDB, false, "blockChanceInc") / 100) * sumMods(modDB, true, "blockChanceMore"), output.total_blockChanceMax)
		output.total_spellBlockChance = m_min(sumMods(modDB, false, "spellBlockChance") * (1 + sumMods(modDB, false, "spellBlockChanceInc") / 100) * sumMods(modDB, true, "spellBlockChanceMore") + output.total_blockChance * m_min(100, getMiscVal(modDB, nil, "blockChanceConv", 0)) / 100, output.total_blockChanceMax)
		output.total_dodgeAttacks = sumMods(modDB, false, "dodgeAttacks")
		output.total_dodgeSpells = sumMods(modDB, false, "dodgeSpells")
		buildSpaceTable(modDB)
		endWatch(env, "otherDef")
	end
	if startWatch(env, "resist") then
		for _, elem in pairs({"fire", "cold", "lightning"}) do
			output["total_"..elem.."ResistMax"] = sumMods(modDB, false, elem.."ResistMax")
			output["total_"..elem.."Resist"] = m_min(sumMods(modDB, false, elem.."Resist", "elementalResist") - 60, output["total_"..elem.."ResistMax"])
		end
		if getMiscVal(modDB, nil, "chaosInoculation", false) then
			output.total_chaosResistMax = 100
			output.total_chaosResist = 100
		else
			output.total_chaosResistMax = sumMods(modDB, false, "chaosResistMax")
			output.total_chaosResist = sumMods(modDB, false, "chaosResist") - 60
		end
		endWatch(env, "resist")
	end

	-- Enable skill namespaces
	buildSpaceTable(modDB, env.skillSpaceFlags)

	-- Calculate projectile stats
	if env.skillFlags.projectile then
		if startWatch(env, "pierce") then
			output.total_pierce = m_min(100, sumMods(modDB, false, "pierceChance")) / 100
			endWatch(env, "pierce")
		end
		if getMiscVal(modDB, nil, "drillneck", false) then
			mod_dbMerge(modDB, "projectile", "damageInc", output.total_pierce * 100)
		end
		output.total_projectileSpeedMod = (1 + sumMods(modDB, false, "projectileSpeedInc") / 100) * sumMods(modDB, true, "projectileSpeedMore")
	end

	-- Run skill setup function
	if env.setupFunc then
		env.setupFunc(function(mod, val) mod_dbMerge(modDB, nil, mod, val) end, output)
	end

	local isAttack = (env.mode == "ATTACK")

	-- Calculate enemy resistances
	if startWatch(env, "enemyResist") then
		local elemResist = getMiscVal(modDB, "effective", "elementalResist", 0)
		for _, damageType in pairs({"lightning","cold","fire"}) do
			output["enemy_"..damageType.."Resist"] = m_min(elemResist + getMiscVal(modDB, "effective", damageType.."Resist", 0), 75)
		end
		output.enemy_chaosResist = m_min(getMiscVal(modDB, "effective", "chaosResist", 0), 75)
		endWatch(env, "enemyResist")
	end
		
	-- Calculate damage for each damage type
	local combMin, combMax = 0, 0
	for _, damageType in pairs(dmgTypeList) do
		local min, max
		if startWatch(env, damageType, "enemyResist") then
			min, max = calcHitDamage(env, output, damageType)
			if env.mode_effective then
				-- Apply resistances
				local preMult
				local taken = getMiscVal(modDB, "effective", damageType.."TakenInc", 0) + getMiscVal(modDB, "effective", "damageTakenInc", 0)
				if isElemental[damageType] then
					local resist = output["enemy_"..damageType.."Resist"] - sumMods(modDB, false, damageType.."Pen", "elementalPen")
					preMult = (1 - resist / 100)
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
			local targetLevel = getMiscVal(modDB, "misc", "hitMonsterLevel", false) and m_min(getMiscVal(modDB, "monster", "level", 1), #data.enemyEvasionTable) or m_min(getMiscVal(modDB, "player", "level", 1), 79)
			local targetEvasion = data.enemyEvasionTable[targetLevel]
			if env.mode_effective then
				targetEvasion = targetEvasion * getMiscVal(modDB, "effective", "evasionMore", 1)
			end
			output.total_hitChance = calcHitChance(targetEvasion, output.total_accuracy)
		end
		endWatch(env, "dps_hitChance")
	end

	-- Calculate average damage and final DPS
	output.total_avg = (combMin + combMax) / 2 * output.total_critEffect
	output.total_dps = output.total_avg * output.total_speed * output.total_hitChance

	-- Calculate mana cost (may be slightly off due to rounding differences)
	output.total_manaCost = m_max(0, getMiscVal(modDB, "skill", "manaCostBase", 0) * (1 + sumMods(modDB, false, "manaCostInc") / 100) * sumMods(modDB, true, "manaCostMore") - sumMods(modDB, false, "manaCostBase"))

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

	-- Calculate trap stats
	if env.skillFlags.trap then
		output.total_trapCooldown = getMiscVal(modDB, "skill", "trapCooldown", 4) / (1 + getMiscVal(modDB, nil, "trapCooldownRecoveryInc", 0) / 100)
	end

	-- Calculate stun modifiers
	if startWatch(env, "stun") then
		if getMiscVal(modDB, nil, "stunImmunity", false) then
			output.stun_duration = 0
			output.stun_blockDuration = 0
		else
			output.stun_duration = 0.35 / (1 + sumMods(modDB, false, "stunRecoveryInc") / 100)
			output.stun_blockDuration = 0.35 / (1 + sumMods(modDB, false, "stunRecoveryInc", "blockRecoveryInc") / 100)
		end
		local enemyStunThresholdRed = -sumMods(modDB, false, "stunEnemyThresholdInc")
		if enemyStunThresholdRed > 75 then
			output.stun_enemyThresholdMod = 1 - (75 + (enemyStunThresholdRed - 75) * 25 / (enemyStunThresholdRed - 50)) / 100
		else
			output.stun_enemyThresholdMod = 1 - enemyStunThresholdRed / 100
		end
		output.stun_enemyDuration = 0.35 * (1 + sumMods(modDB, false, "stunEnemyDurationInc") / 100)
		endWatch(env, "stun")
	end

	-- Calculate skill DOT components
	output.total_dot = 0
	for _, damageType in pairs(dmgTypeList) do
		if startWatch(env, damageType.."Dot") then
			local baseVal = getMiscVal(modDB, "skill", damageType.."DotBase", 0)
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
		output.total_dot = output.total_dot + (output["total_"..damageType.."Dot"] or 0)
	end

	-- Calculate bleeding chance and damage
	if startWatch(env, "bleed", "physical", "dps_crit") then
		output.bleed_chance = m_min(100, sumMods(modDB, false, "bleedChance")) / 100
		if output.bleed_chance > 0 and output.total_physicalAvg > 0 then
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
	if startWatch(env, "poison", "physical", "chaos", "dps_crit", "enemyResist") then
		output.poison_chance = m_min(100, sumMods(modDB, false, "poisonChance")) / 100
		if output.poison_chance > 0 and (output.total_physicalAvg > 0 or output.total_chaosAvg > 0) then
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
			local baseVal = (output.total_physicalAvg + output.total_chaosAvg) * output.total_critEffect * 0.1
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
	if startWatch(env, "ignite", "fire", "cold", "dps_crit", "enemyResist") then
		output.ignite_chance = m_min(100, sumMods(modDB, false, "igniteChance")) / 100
		local sourceDmg = 0
		if not getMiscVal(modDB, nil, "fireCannotIgnite", false) then
			sourceDmg = sourceDmg + output.total_fireAvg
		end
		if getMiscVal(modDB, nil, "coldCanIgnite", false) then
			sourceDmg = sourceDmg + output.total_coldAvg
		end
		if output.ignite_chance > 0 and sourceDmg > 0 then
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
	if startWatch(env, "shock", "lightning", "fire", "chaos") then
		output.shock_chance = m_min(100, sumMods(modDB, false, "shockChance")) / 100
		local sourceDmg = 0
		if not getMiscVal(modDB, nil, "lightningCannotShock", false) then
			sourceDmg = sourceDmg + output.total_lightningAvg
		end
		if getMiscVal(modDB, nil, "fireCanShock", false) then
			sourceDmg = sourceDmg + output.total_fireAvg
		end
		if getMiscVal(modDB, nil, "chaosCanShock", false) then
			sourceDmg = sourceDmg + output.total_chaosAvg
		end
		if output.shock_chance > 0 and sourceDmg > 0 then
			env.skillFlags.shock = true
			output.shock_durationMod = 1 + getMiscVal(modDB, "shock", "durationInc", 0) / 100
 		end
	end
	if startWatch(env, "freeze", "cold", "lightning") then
		output.freeze_chance = m_min(100, sumMods(modDB, false, "freezeChance")) / 100
		local sourceDmg = 0
		if not getMiscVal(modDB, nil, "coldCannotFreeze", false) then
			sourceDmg = sourceDmg + output.total_coldAvg
		end
		if getMiscVal(modDB, nil, "lightningCanFreeze", false) then
			sourceDmg = sourceDmg + output.total_lightningAvg
		end
		if output.freeze_chance > 0 and sourceDmg > 0 then
			env.skillFlags.freeze = true
			output.freeze_durationMod = 1 + getMiscVal(modDB, "freeze", "durationInc", 0) / 100
		end
	end
end

local control = { }

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

-- Generate a function for calculating the effect of some modification to the environment
local function getCalculator(input, build, fullInit, modFunc)
	-- Initialise environment
	local env, errMsg = initEnv(input, build)
	if errMsg then
		return
	end

	-- Save a copy of the initial mod list
	if fullInit then
		mergeItemMods(env, build)
		env.specModList = buildNodeModList(env, build.spec.allocNodes, true)
		mod_dbMergeList(env.modDB, env.specModList)
	end
	local initModDB = copyTable(env.modDB)
	if not fullInit then
		mergeItemMods(env, build)
		env.specModList = buildNodeModList(env, build.spec.allocNodes, true)
		mod_dbMergeList(env.modDB, env.specModList)
	end

	-- Run base calculation pass while building watch lists
	local base = { }
	local outputMeta = { __index = base }
	env.watchers = { }
	env.buildWatch = true
	env.modDB._activeWatchers = { }
	calcSetup(env, base)
	local baseModDB = copyTable(env.modDB)
	baseModDB._activeWatchers = nil
	calcPrimary(env, base)
	env.buildWatch = false
	env.modDB._activeWatchers = nil

	-- Generate list of watched mods
	env.watchedModList = { }
	for _, watchList in pairs(env.watchers) do
		for k, default in pairs(watchList) do
			-- Add this watcher to the mod's watcher list
			local spaceName, modName = modLib.getSpaceName(k)
			if not env.watchedModList[spaceName] then
				env.watchedModList[spaceName] = { }
			end
			if not baseModDB[spaceName] then
				baseModDB[spaceName] = { }
			end
			if not initModDB[spaceName] then
				initModDB[spaceName] = { }
			end
			if not env.watchedModList[spaceName][modName] then				
				env.watchedModList[spaceName][modName] = { baseModDB[spaceName][modName], { } }
			end
			env.watchedModList[spaceName][modName][2][watchList] = true
			if initModDB[spaceName][modName] == nil and baseModDB[spaceName][modName] ~= nil then
				-- Ensure that the initial mod list has at least a default value for any modifiers present in the base database
				initModDB[spaceName][modName] = default
			end
		end
	end

	local flagged = { }
	return function(...)
		-- Restore initial mod list
		resetModDB(env.modDB, initModDB)

		-- Call function to make modifications to the enviroment
		modFunc(env, ...)
		
		-- Prepare for calculation
		local output = setmetatable({ }, outputMeta)
		calcSetup(env, output)

		-- Check if any watched variables have changed
		local active = false
		for spaceName, watchedMods in pairs(env.watchedModList) do
			for k, v in pairs(env.modDB[spaceName]) do
				local watchedMod = watchedMods[k]
				if watchedMod and v ~= watchedMod[1] then
					for watchList in pairs(watchedMod[2]) do
						watchList._flag = true
						flagged[watchList] = true
					end
					active = true
				end
			end
		end
		if not active then
			return base
		end

		-- Run the calculations
		calcPrimary(env, output)

		-- Reset watcher flags
		for watchList in pairs(flagged) do
			watchList._flag = false
			flagged[watchList] = nil
		end

		return output
	end, base	
end

-- Get calculator for tree node modifiers
function control.getNodeCalculator(input, build)
	return getCalculator(input, build, true, function(env, nodeList, remove)
		-- Build and merge modifiers for these nodes
		local nodeModList = buildNodeModList(env, nodeList)
		if remove then
			mod_dbUnmergeList(env.modDB, nodeModList)
		else
			mod_dbMergeList(env.modDB, nodeModList)
		end
	end)
end

-- Get calculator for item modifiers
function control.getItemCalculator(input, build)
	return getCalculator(input, build, false, function(env, repSlotName, repItem)
		-- Build and merge item mod list
		mergeItemMods(env, build, repSlotName, repItem)

		-- Build and merge spec mod list
		env.specModList = buildNodeModList(env, build.spec.allocNodes, true)
		mod_dbMergeList(env.modDB, env.specModList)
	end)
end

-- Build output for display in the grid
function control.buildOutput(input, output, build)
	-- Initialise environment
	local env, errMsg = initEnv(input, build)
	if errMsg then
		setViewMode({ })
		return errMsg
	end

	-- Calculate primary stats
	mergeItemMods(env, build)
	env.specModList = buildNodeModList(env, build.spec.allocNodes, true)
	mod_dbMergeList(env.modDB, env.specModList)
	calcSetup(env, output)
	calcPrimary(env, output)

	-- Add extra display-only stats
	for k, v in pairs(env.specModList) do
		output["spec_"..k] = v
	end
	for k, v in pairs(env.itemModList) do
		output["gear_"..k] = v
	end
	output.skill_partName = env.skillPartName
	output.total_extraPoints = getMiscVal(env.modDB, nil, "extraPoints", 0)
	for _, damageType in pairs(dmgTypeList) do
		-- Add damage ranges
		if output["total_"..damageType.."Max"] > 0 then
			output["total_"..damageType] = formatRound(output["total_"..damageType.."Min"]) .. " - " .. formatRound(output["total_"..damageType.."Max"])		
		else
			output["total_"..damageType] = 0
		end

		-- Calculate weapon DPS for display
		for _, weapon in pairs({"weapon1","weapon2"}) do
			local weaponDPS = (getMiscVal(env.modDB, weapon, damageType.."Min", 0) + getMiscVal(env.modDB, weapon, damageType.."Max",  0)) / 2 * getMiscVal(env.modDB, weapon, "attackRate", 1)
			output[weapon.."_damageDPS"] = (output[weapon.."damageDPS"] or 0) + weaponDPS
			if isElemental[damageType] then
				output[weapon.."_elementalDPS"] = (output[weapon.."_elementalDPS"] or 0) + weaponDPS
			end
			output[weapon.."_"..damageType.."DPS"] = weaponDPS
		end
	end
	output.total_damage = formatRound(output.total_combMin) .. " - " .. formatRound(output.total_combMax)

	-- Calculate XP modifier
	if input.monster_level and input.monster_level > 0 then
		local playerLevel = input.player_level or 1
		local diff = m_abs(playerLevel - input.monster_level) - 3 - m_floor(playerLevel / 16)
		if diff <= 0 then
			output.monster_xp = 1
		else
			output.monster_xp = m_max(0.01, ((playerLevel + 5) / (playerLevel + 5 + diff ^ 2.5)) ^ 1.5)
		end
	end

	-- Configure view mode
	setViewMode(env.skillFlags)

	ConPrintf("== Modifier Database ==")
	modLib.dbPrint(env.modDB)
	ConPrintf("== Skill Gems ==")
	for _, gem in ipairs(env.gemList) do
		if gem.cantSupport then
			ConPrintf("^1%s %d/%d", gem.name, gem.level, gem.quality)
		else 
			ConPrintf("%s %d/%d", gem.name, gem.level, gem.quality)
		end
	end
	ConPrintf("== Namespaces ==")
	modLib.listPrint(env.skillSpaceFlags)
	ConPrintf("== Skill Mods ==")
	modLib.listPrint(env.skillModList)
	ConPrintf("== Spec Mods ==")
	modLib.listPrint(env.specModList)
	ConPrintf("== Item Mods ==")
	modLib.listPrint(env.itemModList)
	ConPrintf("== Aux Skill Mods ==")
	modLib.listPrint(env.auxSkillModList)
	ConPrintf("== Conditions ==")
	modLib.listPrint(env.condList)
	ConPrintf("== Conditional Modifiers ==")
	modLib.listPrint(env.condModList)
	if env.buffModList then
		ConPrintf("== Buff Mods ==")
		modLib.listPrint(env.buffModList)
	end
end

return control
