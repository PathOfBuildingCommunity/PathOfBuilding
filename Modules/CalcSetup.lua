-- Path of Building
--
-- Module: Calc Setup
-- Initialises the environment for calculations.
--
local calcs = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max

local tempTable1 = { }

-- Initialise modifier database with stats and conditions common to all actors
function calcs.initModDB(env, modDB)
	modDB:NewMod("FireResistMax", "BASE", 75, "Base")
	modDB:NewMod("ColdResistMax", "BASE", 75, "Base")
	modDB:NewMod("LightningResistMax", "BASE", 75, "Base")
	modDB:NewMod("ChaosResistMax", "BASE", 75, "Base")
	modDB:NewMod("BlockChanceMax", "BASE", 75, "Base")
	modDB:NewMod("SpellBlockChanceMax", "BASE", 75, "Base")
	modDB:NewMod("PowerChargesMax", "BASE", 3, "Base")
	modDB:NewMod("FrenzyChargesMax", "BASE", 3, "Base")
	modDB:NewMod("EnduranceChargesMax", "BASE", 3, "Base")
	modDB:NewMod("InspirationChargesMax", "BASE", 5, "Base")
	modDB:NewMod("MaxLifeLeechRate", "BASE", 20, "Base")
	modDB:NewMod("MaxManaLeechRate", "BASE", 20, "Base")
	if env.build.targetVersion ~= "2_6" then
		modDB:NewMod("MaxEnergyShieldLeechRate", "BASE", 10, "Base")
		modDB:NewMod("MaxLifeLeechInstance", "BASE", 10, "Base")
		modDB:NewMod("MaxManaLeechInstance", "BASE", 10, "Base")
		modDB:NewMod("MaxEnergyShieldLeechInstance", "BASE", 10, "Base")
	end
	if env.build.targetVersion == "2_6" then
		modDB:NewMod("TrapThrowingTime", "BASE", 0.5, "Base")
		modDB:NewMod("MineLayingTime", "BASE", 0.5, "Base")
	else
		modDB:NewMod("TrapThrowingTime", "BASE", 0.6, "Base")
		modDB:NewMod("MineLayingTime", "BASE", 0.25, "Base")
	end
	modDB:NewMod("TotemPlacementTime", "BASE", 0.6, "Base")
	modDB:NewMod("ActiveTotemLimit", "BASE", 1, "Base")
	modDB:NewMod("LifeRegenPercent", "BASE", 6, "Base", { type = "Condition", var = "OnConsecratedGround" })
	modDB:NewMod("HitChance", "MORE", -50, "Base", { type = "Condition", var = "Blinded" })
	modDB:NewMod("MovementSpeed", "INC", -30, "Base", { type = "Condition", var = "Maimed" })
	modDB:NewMod("Condition:Burning", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "Condition", var = "Ignited" })
	modDB:NewMod("Condition:Chilled", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "Condition", var = "Frozen" })
	modDB:NewMod("Condition:Poisoned", "FLAG", true, "Base", { type = "IgnoreCond" }, { type = "MultiplierThreshold", var = "PoisonStack", threshold = 1 })
	modDB:NewMod("Chill", "FLAG", true, "Base", { type = "Condition", var = "Chilled" })
	modDB:NewMod("Freeze", "FLAG", true, "Base", { type = "Condition", var = "Frozen" })
	modDB:NewMod("Fortify", "FLAG", true, "Base", { type = "Condition", var = "Fortify" })
	modDB:NewMod("Onslaught", "FLAG", true, "Base", { type = "Condition", var = "Onslaught" })
	modDB:NewMod("UnholyMight", "FLAG", true, "Base", { type = "Condition", var = "UnholyMight" })
	modDB:NewMod("Tailwind", "FLAG", true, "Base", { type = "Condition", var = "Tailwind" })
	modDB:NewMod("Adrenaline", "FLAG", true, "Base", { type = "Condition", var = "Adrenaline" })
	modDB.conditions["Buffed"] = env.mode_buffs
	modDB.conditions["Combat"] = env.mode_combat
	modDB.conditions["Effective"] = env.mode_effective
end

function calcs.buildModListForNode(env, node)
	local modList = new("ModList")
	if node.type == "Keystone" then
		modList:AddMod(node.keystoneMod)
	else
		modList:AddList(node.modList)
	end

	-- Run first pass radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		if rad.type == "Other" and rad.nodes[node.id] then
			rad.func(node, modList, rad.data)
		end
	end

	if modList:Flag(nil, "PassiveSkillHasNoEffect") or (env.allocNodes[node.id] and modList:Flag(nil, "AllocatedPassiveSkillHasNoEffect")) then
		wipeTable(modList)
	end

	-- Apply effect scaling
	local scale = calcLib.mod(modList, nil, "PassiveSkillEffect")
	if scale ~= 1 then
		local scaledList = new("ModList")
		scaledList:ScaleAddList(modList, scale)
		modList = scaledList
	end

	-- Run second pass radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		if rad.nodes[node.id] and (rad.type == "Threshold" or (rad.type == "Self" and env.allocNodes[node.id]) or (rad.type == "SelfUnalloc" and not env.allocNodes[node.id])) then
			rad.func(node, modList, rad.data)
		end
	end

	return modList
end

-- Build list of modifiers from the listed tree nodes
function calcs.buildModListForNodeList(env, nodeList, finishJewels)
	-- Initialise radius jewels
	for _, rad in pairs(env.radiusJewelList) do
		wipeTable(rad.data)
		rad.data.modSource = "Tree:"..rad.nodeId
	end

	-- Add node modifers
	local modList = new("ModList")
	for _, node in pairs(nodeList) do
		local nodeModList = calcs.buildModListForNode(env, node)
		modList:AddList(nodeModList)
		if env.mode == "MAIN" then	
			node.finalModList = nodeModList
		end
	end

	if finishJewels then
		-- Process extra radius nodes; these are unallocated nodes near conversion or threshold jewels that need to be processed
		for _, node in pairs(env.extraRadiusNodeList) do
			local nodeModList = calcs.buildModListForNode(env, node)
			if env.mode == "MAIN" then	
				node.finalModList = nodeModList
			end
		end
		
		-- Finalise radius jewels
		for _, rad in pairs(env.radiusJewelList) do
			rad.func(nil, modList, rad.data)
			if env.mode == "MAIN" then
				if not rad.item.jewelRadiusData then
					rad.item.jewelRadiusData = { }
				end
				rad.item.jewelRadiusData[rad.nodeId] = rad.data
			end
		end
	end

	return modList
end

-- Initialise environment: 
-- 1. Initialises the player and enemy modifier databases
-- 2. Merges modifiers for all items
-- 3. Builds a list of jewels with radius functions
-- 4. Merges modifiers for all allocated passive nodes
-- 5. Builds a list of active skills and their supports (calcs.createActiveSkill)
-- 6. Builds modifier lists for all active skills (calcs.buildActiveSkillModList)
function calcs.initEnv(build, mode, override)
	override = override or { }

	local env = { }
	env.build = build
	env.data = build.data
	env.configInput = build.configTab.input
	env.calcsInput = build.calcsTab.input
	env.mode = mode
	env.spec = override.spec or build.spec
	env.classId = env.spec.curClassId

	-- Set buff mode
	local buffMode
	if mode == "CALCS" then
		buffMode = env.calcsInput.misc_buffMode
	else
		buffMode = "EFFECTIVE"
	end
	if buffMode == "EFFECTIVE" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = true
	elseif buffMode == "COMBAT" then
		env.mode_buffs = true
		env.mode_combat = true
		env.mode_effective = false
	elseif buffMode == "BUFFED" then
		env.mode_buffs = true
		env.mode_combat = false
		env.mode_effective = false
	else
		env.mode_buffs = false
		env.mode_combat = false
		env.mode_effective = false
	end

	-- Initialise modifier database with base values
	local modDB = new("ModDB")
	env.modDB = modDB
	local classStats = env.spec.tree.characterData[env.classId]
	for _, stat in pairs({"Str","Dex","Int"}) do
		modDB:NewMod(stat, "BASE", classStats["base_"..stat:lower()], "Base")
	end
	modDB.multipliers["Level"] = m_max(1, m_min(100, build.characterLevel))
	calcs.initModDB(env, modDB)
	modDB:NewMod("Life", "BASE", 12, "Base", { type = "Multiplier", var = "Level", base = 38 })
	modDB:NewMod("Mana", "BASE", 6, "Base", { type = "Multiplier", var = "Level", base = 34 })
	modDB:NewMod("ManaRegen", "BASE", 0.0175, "Base", { type = "PerStat", stat = "Mana", div = 1 })
	modDB:NewMod("Evasion", "BASE", 3, "Base", { type = "Multiplier", var = "Level", base = 53 })
	modDB:NewMod("Accuracy", "BASE", 2, "Base", { type = "Multiplier", var = "Level", base = -2 })
	modDB:NewMod("CritMultiplier", "BASE", 50, "Base")
	modDB:NewMod("DotMultiplier", "BASE", 50, "Base", { type = "Condition", var = "CriticalStrike" })
	modDB:NewMod("FireResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
	modDB:NewMod("ColdResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
	modDB:NewMod("LightningResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
	modDB:NewMod("ChaosResist", "BASE", env.configInput.resistancePenalty or -60, "Base")
	if build.targetVersion == "2_6" then
		modDB:NewMod("CritChance", "INC", 50, "Base", { type = "Multiplier", var = "PowerCharge" })
	else
		modDB:NewMod("CritChance", "INC", 40, "Base", { type = "Multiplier", var = "PowerCharge" })
	end
	modDB:NewMod("Speed", "INC", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
	modDB:NewMod("Damage", "MORE", 4, "Base", { type = "Multiplier", var = "FrenzyCharge" })
	modDB:NewMod("PhysicalDamageReduction", "BASE", 4, "Base", { type = "Multiplier", var = "EnduranceCharge" })
	modDB:NewMod("ElementalResist", "BASE", 4, "Base", { type = "Multiplier", var = "EnduranceCharge" })
	modDB:NewMod("Multiplier:RageEffect", "BASE", 1, "Base")
	modDB:NewMod("Damage", "INC", 1, "Base", ModFlag.Attack, { type = "Multiplier", var = "Rage", limit = 50 }, { type = "Multiplier", var = "RageEffect" })
	modDB:NewMod("Speed", "INC", 1, "Base", ModFlag.Attack, { type = "Multiplier", var = "Rage", limit = 25, div = 2 }, { type = "Multiplier", var = "RageEffect" })
	modDB:NewMod("MovementSpeed", "INC", 1, "Base", { type = "Multiplier", var = "Rage", limit = 10, div = 5 }, { type = "Multiplier", var = "RageEffect" })
	if build.targetVersion == "2_6" then
		modDB:NewMod("ActiveTrapLimit", "BASE", 3, "Base")
		modDB:NewMod("ActiveMineLimit", "BASE", 5, "Base")
	else
		modDB:NewMod("ActiveTrapLimit", "BASE", 15, "Base")
		modDB:NewMod("ActiveMineLimit", "BASE", 15, "Base")
	end
	modDB:NewMod("EnemyCurseLimit", "BASE", 1, "Base")
	modDB:NewMod("ProjectileCount", "BASE", 1, "Base")
	modDB:NewMod("Speed", "MORE", 10, "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" })
	modDB:NewMod("PhysicalDamage", "MORE", 20, "Base", ModFlag.Attack, { type = "Condition", var = "DualWielding" })
	modDB:NewMod("BlockChance", "BASE", 15, "Base", { type = "Condition", var = "DualWielding" })
	if build.targetVersion == "2_6" then
		modDB:NewMod("Damage", "MORE", 500, "Base", 0, KeywordFlag.Bleed, { type = "ActorCondition", actor = "enemy", var = "Moving" })
	else
		modDB:NewMod("Damage", "MORE", 200, "Base", 0, KeywordFlag.Bleed, { type = "ActorCondition", actor = "enemy", var = "Moving" }, { type = "Condition", var = "NoExtraBleedDamageToMovingEnemy", neg = true })
	end
	modDB:NewMod("Condition:BloodStance", "FLAG", true, "Base", { type = "Condition", var = "SandStance", neg = true })

	-- Add bandit mods
	if build.targetVersion == "2_6" then
		if build.banditNormal == "Alira" then
			modDB:NewMod("Mana", "BASE", 60, "Bandit")
		elseif build.banditNormal == "Kraityn" then
			modDB:NewMod("ElementalResist", "BASE", 10, "Bandit")
		elseif build.banditNormal == "Oak" then
			modDB:NewMod("Life", "BASE", 40, "Bandit")
		else
			modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
		end
		if build.banditCruel == "Alira" then
			modDB:NewMod("Speed", "INC", 5, "Bandit", ModFlag.Cast)
		elseif build.banditCruel == "Kraityn" then
			modDB:NewMod("Speed", "INC", 8, "Bandit", ModFlag.Attack)
		elseif build.banditCruel == "Oak" then
			modDB:NewMod("PhysicalDamage", "INC", 16, "Bandit")
		else
			modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
		end
		if build.banditMerciless == "Alira" then
			modDB:NewMod("PowerChargesMax", "BASE", 1, "Bandit")
		elseif build.banditMerciless == "Kraityn" then
			modDB:NewMod("FrenzyChargesMax", "BASE", 1, "Bandit")
		elseif build.banditMerciless == "Oak" then
			modDB:NewMod("EnduranceChargesMax", "BASE", 1, "Bandit")
		else
			modDB:NewMod("ExtraPoints", "BASE", 1, "Bandit")
		end
	else
		if build.bandit == "Alira" then
			modDB:NewMod("ManaRegen", "BASE", 5, "Bandit")
			modDB:NewMod("CritMultiplier", "BASE", 20, "Bandit")
			modDB:NewMod("ElementalResist", "BASE", 15, "Bandit")
		elseif build.bandit == "Kraityn" then
			modDB:NewMod("Speed", "INC", 6, "Bandit")
			modDB:NewMod("AttackDodgeChance", "BASE", 3, "Bandit")
			modDB:NewMod("MovementSpeed", "INC", 6, "Bandit")
		elseif build.bandit == "Oak" then
			modDB:NewMod("LifeRegenPercent", "BASE", 1, "Bandit")
			modDB:NewMod("PhysicalDamageReduction", "BASE", 2, "Bandit")
			modDB:NewMod("PhysicalDamage", "INC", 20, "Bandit")
		else
			modDB:NewMod("ExtraPoints", "BASE", 2, "Bandit")
		end
	end

	-- Add Pantheon mods
	if build.targetVersion == "3_0" then
		local parser = modLib.parseMod[build.targetVersion]
		-- Major Gods
		if build.pantheonMajorGod ~= "None" then
			local majorGod = env.data.pantheons[build.pantheonMajorGod]
			pantheon.applySoulMod(modDB, parser, majorGod)
		end
		-- Minor Gods
		if build.pantheonMinorGod ~= "None" then
			local minorGod = env.data.pantheons[build.pantheonMinorGod]
			pantheon.applySoulMod(modDB, parser, minorGod)
		end
	end

	-- Initialise enemy modifier database
	local enemyDB = new("ModDB")
	env.enemyDB = enemyDB
	env.enemyLevel = m_max(1, m_min(100, env.configInput.enemyLevel and env.configInput.enemyLevel or m_min(env.build.characterLevel, 84)))
	calcs.initModDB(env, enemyDB)
	enemyDB:NewMod("Accuracy", "BASE", env.data.monsterAccuracyTable[env.enemyLevel], "Base")
	enemyDB:NewMod("Evasion", "BASE", env.data.monsterEvasionTable[env.enemyLevel], "Base")

	-- Add mods from the config tab
	modDB:AddList(build.configTab.modList)
	enemyDB:AddList(build.configTab.enemyModList)

	-- Create player/enemy actors
	env.player = {
		modDB = modDB,
		level = build.characterLevel,
	}
	modDB.actor = env.player
	env.enemy = {
		modDB = enemyDB,
		level = env.enemyLevel,
	}
	enemyDB.actor = env.enemy
	env.player.enemy = env.enemy
	env.enemy.enemy = env.player

	-- Build list of passive nodes
	local nodes
	if override.addNodes or override.removeNodes then
		nodes = { }
		if override.addNodes then
			for node in pairs(override.addNodes) do
				nodes[node.id] = node
			end
		end
		for _, node in pairs(env.spec.allocNodes) do
			if not override.removeNodes or not override.removeNodes[node] then
				nodes[node.id] = node
			end
		end
	else
		nodes = copyTable(env.spec.allocNodes, true)
	end
	env.allocNodes = nodes

	-- Set up requirements tracking
	env.requirementsTable = { }

	-- Build and merge item modifiers, and create list of radius jewels
	env.radiusJewelList = wipeTable(env.radiusJewelList)
	env.extraRadiusNodeList = wipeTable(env.extraRadiusNodeList)
	env.player.itemList = { }
	env.itemGrantedSkills = { }
	env.flasks = { }
	for _, slot in pairs(build.itemsTab.orderedSlots) do
		local slotName = slot.slotName
		local item
		if slotName == override.repSlotName then
			item = override.repItem
		elseif override.repItem and override.repSlotName:match("^Weapon 1") and slotName:match("^Weapon 2") and 
		  (override.repItem.base.type == "Staff" or override.repItem.base.type == "Two Handed Sword" or override.repItem.base.type == "Two Handed Axe" or override.repItem.base.type == "Two Handed Mace" 
		  or (override.repItem.base.type == "Bow" and item and item.base.type ~= "Quiver")) then
			item = nil
		elseif slot.nodeId and override.spec then
			item = build.itemsTab.items[env.spec.jewels[slot.nodeId]]
		else
			item = build.itemsTab.items[slot.selItemId]
		end
		if item then
			-- Find skills granted by this item
			for _, skill in ipairs(item.grantedSkills) do
				local grantedSkill = copyTable(skill)
				grantedSkill.sourceItem = item
				grantedSkill.slotName = slotName
				t_insert(env.itemGrantedSkills, grantedSkill)
			end
		end
		if slot.weaponSet and slot.weaponSet ~= (build.itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1) then
			item = nil
		end
		if slot.weaponSet == 2 and build.itemsTab.activeItemSet.useSecondWeaponSet then
			slotName = slotName:gsub(" Swap","")
		end
		if slot.nodeId then
			-- Slot is a jewel socket, check if socket is allocated
			if not nodes[slot.nodeId] then
				item = nil
			elseif item and item.jewelRadiusIndex then
				-- Jewel has a radius, add it to the list
				local funcList = item.jewelData.funcList or { { type = "Self", func = function(node, out, data)
					-- Default function just tallies all stats in radius
					if node then
						for _, stat in pairs({"Str","Dex","Int"}) do
							data[stat] = (data[stat] or 0) + out:Sum("BASE", nil, stat)
						end
					end
				end } }
				for _, func in ipairs(funcList) do
					local node = env.spec.nodes[slot.nodeId]
					t_insert(env.radiusJewelList, {
						nodes = node.nodesInRadius[item.jewelRadiusIndex],
						func = func.func,
						type = func.type,
						item = item,
						nodeId = slot.nodeId,
						attributes = node.attributesInRadius[item.jewelRadiusIndex],
						data = { }
					})
					if func.type ~= "Self" then
						-- Add nearby unallocated nodes to the extra node list
						for nodeId, node in pairs(node.nodesInRadius[item.jewelRadiusIndex]) do
							if not nodes[nodeId] then
								env.extraRadiusNodeList[nodeId] = env.spec.nodes[nodeId]
							end
						end
					end
				end
			end
		end
		if item and item.type == "Flask" then
			if slot.active then
				env.flasks[item] = true
			end
			item = nil
		end
		local scale = 1
		if item and item.type == "Jewel" and item.base.subType == "Abyss" and slot.parentSlot then
			-- Check if the item in the parent slot has enough Abyssal Sockets
			local parentItem = env.player.itemList[slot.parentSlot.slotName]
			if not parentItem or parentItem.abyssalSocketCount < slot.slotNum then
				item = nil
			else
				scale = parentItem.socketedJewelEffectModifier
			end
		end
		if item then
			env.player.itemList[slotName] = item
			-- Merge mods for this item
			local srcList = item.modList or item.slotModList[slot.slotNum]
			if item.requirements then	
				t_insert(env.requirementsTable, {
					source = "Item",
					sourceItem = item,
					sourceSlot = slotName,
					Str = item.requirements.strMod,
					Dex = item.requirements.dexMod,
					Int = item.requirements.intMod,
				})
			end
			if item.type == "Jewel" and item.base.subType == "Abyss" then
				-- Update Abyss Jewel conditions/multipliers
				local cond = "Have"..item.baseName:gsub(" ","")
				if not env.modDB.conditions[cond] then
					env.modDB.conditions[cond] = true
					env.modDB.multipliers["AbyssJewelType"] = (env.modDB.multipliers["AbyssJewelType"] or 0) + 1
				end
				if slot.parentSlot then
					env.modDB.conditions[cond.."In"..slot.parentSlot.slotName] = true
				end
				env.modDB.multipliers["AbyssJewel"] = (env.modDB.multipliers["AbyssJewel"] or 0) + 1
			end
			if item.type == "Shield" and nodes[45175] then
				-- Special handling for Necromantic Aegis
				env.aegisModList = new("ModList")
				for _, mod in ipairs(srcList) do
					-- Filter out mods that apply to socketed gems, or which add supports
					local add = true
					for _, tag in ipairs(mod) do
						if tag.type == "SocketedIn" then
							add = false
							break
						end
					end
					if add then
						env.aegisModList:ScaleAddMod(mod, scale)
					else
						env.modDB:ScaleAddMod(mod, scale)
					end
				end
			elseif slotName == "Weapon 1" and item.grantedSkills[1] and item.grantedSkills[1].skillId == "UniqueAnimateWeapon" then
				-- Special handling for The Dancing Dervish
				env.weaponModList1 = new("ModList")
				for _, mod in ipairs(srcList) do
					-- Filter out mods that apply to socketed gems, or which add supports
					local add = true
					for _, tag in ipairs(mod) do
						if tag.type == "SocketedIn" then
							add = false
							break
						end
					end
					if add then
						env.weaponModList1:ScaleAddMod(mod, scale)
					else
						env.modDB:ScaleAddMod(mod, scale)
					end
				end
			else
				env.modDB:ScaleAddList(srcList, scale)
			end
			if item.type ~= "Jewel" and item.type ~= "Flask" then
				-- Update item counts
				local key
				if item.rarity == "UNIQUE" or item.rarity == "RELIC" then
					key = "UniqueItem"
				elseif item.rarity == "RARE" then
					key = "RareItem"
				elseif item.rarity == "MAGIC" then
					key = "MagicItem"
				else
					key = "NormalItem"
				end
				env.modDB.multipliers[key] = (env.modDB.multipliers[key] or 0) + 1
				if item.corrupted then
					env.modDB.multipliers.CorruptedItem = (env.modDB.multipliers.CorruptedItem or 0) + 1
				else
					env.modDB.multipliers.NonCorruptedItem = (env.modDB.multipliers.NonCorruptedItem or 0) + 1
				end
				if item.shaper then
					env.modDB.multipliers.ShaperItem = (env.modDB.multipliers.ShaperItem or 0) + 1
					env.modDB.conditions["ShaperItemIn"..slotName] = true
				else
					env.modDB.multipliers.NonShaperItem = (env.modDB.multipliers.NonShaperItem or 0) + 1
				end
				if item.elder then
					env.modDB.multipliers.ElderItem = (env.modDB.multipliers.ElderItem or 0) + 1
					env.modDB.conditions["ElderItemIn"..slotName] = true
				else
					env.modDB.multipliers.NonElderItem = (env.modDB.multipliers.NonElderItem or 0) + 1
				end
			end
		end
	end

	if override.toggleFlask then
		if env.flasks[override.toggleFlask] then
			env.flasks[override.toggleFlask] = nil
		else
			env.flasks[override.toggleFlask] = true
		end
	end
	
	if env.mode == "MAIN" then
		-- Process extra skills granted by items
		local markList = wipeTable(tempTable1)
		for _, grantedSkill in ipairs(env.itemGrantedSkills) do	
			-- Check if a matching group already exists
			local group
			for index, socketGroup in pairs(build.skillsTab.socketGroupList) do
				if socketGroup.source == grantedSkill.source and socketGroup.slot == grantedSkill.slotName then
					if socketGroup.gemList[1] and socketGroup.gemList[1].skillId == grantedSkill.skillId then
						group = socketGroup
						markList[socketGroup] = true
						break
					end
				end
			end
			if not group then
				-- Create a new group for this skill
				group = { label = "", enabled = true, gemList = { }, source = grantedSkill.source, slot = grantedSkill.slotName }
				t_insert(build.skillsTab.socketGroupList, group)
				markList[group] = true
			end

			-- Update the group
			group.sourceItem = grantedSkill.sourceItem
			local activeGemInstance = group.gemList[1] or {
				skillId = grantedSkill.skillId,
				quality = 0,
				enabled = true,
			}
			activeGemInstance.level = grantedSkill.level
			activeGemInstance.enableGlobal1 = true
			wipeTable(group.gemList)
			t_insert(group.gemList, activeGemInstance)
			if grantedSkill.noSupports then
				group.noSupports = true
			else
				for _, socketGroup in pairs(build.skillsTab.socketGroupList) do
					-- Look for other groups that are socketed in the item
					if socketGroup.slot == grantedSkill.slotName and not socketGroup.source then
						-- Add all support gems to the skill's group
						for _, gemInstance in ipairs(socketGroup.gemList) do
							if gemInstance.gemData and gemInstance.gemData.grantedEffect.support then
								t_insert(group.gemList, gemInstance)
							end
						end
					end
				end
			end
			build.skillsTab:ProcessSocketGroup(group)
		end
		
		-- Remove any socket groups that no longer have a matching item
		local i = 1
		while build.skillsTab.socketGroupList[i] do
			local socketGroup = build.skillsTab.socketGroupList[i]
			if socketGroup.source and not markList[socketGroup] then
				t_remove(build.skillsTab.socketGroupList, i)
				if build.skillsTab.displayGroup == socketGroup then
					build.skillsTab.displayGroup = nil
				end
			else
				i = i + 1
			end
		end
	end

	-- Get the weapon data tables for the equipped weapons
	env.player.weaponData1 = env.player.itemList["Weapon 1"] and env.player.itemList["Weapon 1"].weaponData and env.player.itemList["Weapon 1"].weaponData[1] or copyTable(env.data.unarmedWeaponData[env.classId])
	if env.player.weaponData1.countsAsDualWielding then
		env.player.weaponData2 = env.player.itemList["Weapon 1"].weaponData[2]
	else
		env.player.weaponData2 = env.player.itemList["Weapon 2"] and env.player.itemList["Weapon 2"].weaponData and env.player.itemList["Weapon 2"].weaponData[2] or { }
	end

	-- Add granted passives
	env.grantedPassives = { }
	for _, passive in pairs(env.modDB:List(nil, "GrantedPassive")) do
		local node = env.spec.tree.notableMap[passive]
		if node then
			nodes[node.id] = node
			env.grantedPassives[node.id] = true
		end
	end

	-- Merge modifiers for allocated passives
	env.modDB:AddList(calcs.buildModListForNodeList(env, nodes, true))

	-- Determine main skill group
	if env.mode == "CALCS" then
		env.calcsInput.skill_number = m_min(m_max(#build.skillsTab.socketGroupList, 1), env.calcsInput.skill_number or 1)
		env.mainSocketGroup = env.calcsInput.skill_number
	else
		build.mainSocketGroup = m_min(m_max(#build.skillsTab.socketGroupList, 1), build.mainSocketGroup or 1)
		env.mainSocketGroup = build.mainSocketGroup
	end

	-- Build list of active skills
	env.player.activeSkillList = { }
	local groupCfg = wipeTable(tempTable1)
	for index, socketGroup in pairs(build.skillsTab.socketGroupList) do
		local socketGroupSkillList = { }
		local slot = socketGroup.slot and build.itemsTab.slots[socketGroup.slot]
		socketGroup.slotEnabled = not slot or not slot.weaponSet or slot.weaponSet == (build.itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1)
		if index == env.mainSocketGroup or (socketGroup.enabled and socketGroup.slotEnabled) then
			groupCfg.slotName = socketGroup.slot and socketGroup.slot:gsub(" Swap","")
			local propertyModList = env.modDB:List(groupCfg, "GemProperty")

			-- Build list of supports for this socket group
			local supportList = { }
			if not socketGroup.source then
				-- Add extra supports from the item this group is socketed in
				for _, value in ipairs(env.modDB:List(groupCfg, "ExtraSupport")) do
					local grantedEffect = env.data.skills[value.skillId]
					if grantedEffect then
						t_insert(supportList, { 
							grantedEffect = grantedEffect,
							level = value.level,
							quality = 0,
							enabled = true,
						})
					end
				end
			end
			for _, gemInstance in ipairs(socketGroup.gemList) do
				-- Add support gems from this group
				if env.mode == "MAIN" then
					gemInstance.displayEffect = nil
					gemInstance.supportEffect = nil
				end
				if gemInstance.enabled then
					local function processGrantedEffect(grantedEffect)
						if not grantedEffect or not grantedEffect.support then
							return
						end
						local supportEffect = {
							grantedEffect = grantedEffect,
							level = gemInstance.level,
							quality = gemInstance.quality,
							srcInstance = gemInstance,
							gemData = gemInstance.gemData,
							superseded = false,
							isSupporting = { },
						}
						if env.mode == "MAIN" then
							gemInstance.displayEffect = supportEffect
							gemInstance.supportEffect = supportEffect
						end
						if gemInstance.gemData then
							for _, value in ipairs(propertyModList) do
								if calcLib.gemIsType(supportEffect.gemData, value.keyword) then
									supportEffect[value.key] = (supportEffect[value.key] or 0) + value.value
								end
							end
						end
						local add = true
						for index, otherSupport in ipairs(supportList) do
							-- Check if there's another support with the same name already present
							if grantedEffect == otherSupport.grantedEffect then
								add = false
								if supportEffect.level > otherSupport.level or (supportEffect.level == otherSupport.level and supportEffect.quality > otherSupport.quality) then
									if env.mode == "MAIN" then
										otherSupport.superseded = true
									end
									supportList[index] = supportEffect
								else
									supportEffect.superseded = true
								end
								break
							end
						end
						if add then
							t_insert(supportList, supportEffect)
						end
					end
					if gemInstance.gemData then
						processGrantedEffect(gemInstance.gemData.grantedEffect)
						processGrantedEffect(gemInstance.gemData.secondaryGrantedEffect)
					else
						processGrantedEffect(gemInstance.grantedEffect)
					end
				end	
			end

			-- Create active skills
			for _, gemInstance in ipairs(socketGroup.gemList) do	
				if gemInstance.enabled and (gemInstance.gemData or gemInstance.grantedEffect) then
					local grantedEffectList = gemInstance.gemData and gemInstance.gemData.grantedEffectList or { gemInstance.grantedEffect }
					for index, grantedEffect in ipairs(grantedEffectList) do
						if not grantedEffect.support and not grantedEffect.unsupported and (not grantedEffect.hasGlobalEffect or gemInstance["enableGlobal"..index]) then
							local activeEffect = {
								grantedEffect = grantedEffect,
								level = gemInstance.level,
								quality = gemInstance.quality,
								srcInstance = gemInstance,
								gemData = gemInstance.gemData,
							}
							if gemInstance.gemData then
								for _, value in ipairs(propertyModList) do
									local match = false
									if value.keywordList then
										match = true
										for _, keyword in ipairs(value.keywordList) do
											if not calcLib.gemIsType(activeEffect.gemData, keyword) then
												match = false
												break
											end
										end
									else
										match = calcLib.gemIsType(activeEffect.gemData, value.keyword)
									end
									if match then
										activeEffect[value.key] = (activeEffect[value.key] or 0) + value.value
									end
								end
							end
							if env.mode == "MAIN" then
								gemInstance.displayEffect = activeEffect
							end
							local activeSkill = calcs.createActiveSkill(activeEffect, supportList, env.player, socketGroup)
							if gemInstance.gemData then
								activeSkill.slotName = groupCfg.slotName
							end
							t_insert(socketGroupSkillList, activeSkill)
							t_insert(env.player.activeSkillList, activeSkill)
						end
					end
					if gemInstance.gemData then
						t_insert(env.requirementsTable, {
							source = "Gem",
							sourceGem = gemInstance,
							Str = gemInstance.reqStr,
							Dex = gemInstance.reqDex,
							Int = gemInstance.reqInt,
						})
					end
				end
			end

			if index == env.mainSocketGroup and #socketGroupSkillList > 0 then
				-- Select the main skill from this socket group
				local activeSkillIndex
				if env.mode == "CALCS" then
					socketGroup.mainActiveSkillCalcs = m_min(#socketGroupSkillList, socketGroup.mainActiveSkillCalcs or 1)
					activeSkillIndex = socketGroup.mainActiveSkillCalcs
				else
					activeSkillIndex = m_min(#socketGroupSkillList, socketGroup.mainActiveSkill or 1)
					if env.mode == "MAIN" then
						socketGroup.mainActiveSkill = activeSkillIndex
					end
				end
				env.player.mainSkill = socketGroupSkillList[activeSkillIndex]
			end
		end

		if env.mode == "MAIN" then
			-- Create display label for the socket group if the user didn't specify one
			if socketGroup.label and socketGroup.label:match("%S") then
				socketGroup.displayLabel = socketGroup.label
			else
				socketGroup.displayLabel = nil
				for _, gemInstance in ipairs(socketGroup.gemList) do
					local grantedEffect = gemInstance.gemData and gemInstance.gemData.grantedEffect or gemInstance.grantedEffect
					if grantedEffect and not grantedEffect.support and gemInstance.enabled then
						socketGroup.displayLabel = (socketGroup.displayLabel and socketGroup.displayLabel..", " or "") .. grantedEffect.name
					end
				end
				socketGroup.displayLabel = socketGroup.displayLabel or "<No active skills>"
			end

			-- Save the active skill list for display in the socket group tooltip
			socketGroup.displaySkillList = socketGroupSkillList
		elseif env.mode == "CALCS" then
			socketGroup.displaySkillListCalcs = socketGroupSkillList
		end
	end

	if not env.player.mainSkill then
		-- Add a default main skill if none are specified
		local defaultEffect = {
			grantedEffect = env.data.skills.Melee,
			level = 1,
			quality = 0,
			enabled = true,
		}
		env.player.mainSkill = calcs.createActiveSkill(defaultEffect, { }, env.player)
		t_insert(env.player.activeSkillList, env.player.mainSkill)
	end

	-- Build skill modifier lists
	env.auxSkillList = { }
	for _, activeSkill in pairs(env.player.activeSkillList) do
		calcs.buildActiveSkillModList(env, activeSkill)
	end

	return env
end
