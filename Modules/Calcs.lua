-- Path of Building
--
-- Module: Calcs
-- Manages the calculation system.
--

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local s_format = string.format

local calcs = { }
LoadModule("Modules/CalcSetup", calcs)
LoadModule("Modules/CalcPerform", calcs)
LoadModule("Modules/CalcActiveSkill", calcs)
LoadModule("Modules/CalcDefence", calcs)
LoadModule("Modules/CalcOffence", calcs)

-- Print various tables to the console
local function infoDump(env, output)
	env.modDB:Print()
	if env.minion then
		ConPrintf("=== Minion Mod DB ===")
		env.minion.modDB:Print()
	end
	ConPrintf("=== Enemy Mod DB ===")
	env.enemyDB:Print()
	local mainSkill = env.minion and env.minion.mainSkill or env.player.mainSkill
	ConPrintf("=== Main Skill ===")
	for _, gem in ipairs(mainSkill.gemList) do
		ConPrintf("%s %d/%d", gem.name, gem.level, gem.quality)
	end
	ConPrintf("=== Main Skill Flags ===")
	ConPrintf("Mod: %s", modLib.formatFlags(mainSkill.skillCfg.flags, ModFlag))
	ConPrintf("Keyword: %s", modLib.formatFlags(mainSkill.skillCfg.keywordFlags, KeywordFlag))
	ConPrintf("=== Main Skill Mods ===")
	mainSkill.skillModList:Print()
	ConPrintf("== Aux Skills ==")
	for i, aux in ipairs(env.auxSkillList) do
		ConPrintf("Skill #%d:", i)
		for _, gem in ipairs(aux.gemList) do
			ConPrintf("  %s %d/%d", gem.name, gem.level, gem.quality)
		end
	end
--	ConPrintf("== Conversion Table ==")
--	prettyPrintTable(env.player.conversionTable)
	ConPrintf("== Output Table ==")
	prettyPrintTable(env.player.output)
end

-- Generate a function for calculating the effect of some modification to the environment
local function getCalculator(build, fullInit, modFunc)
	-- Initialise environment
	local env = calcs.initEnv(build, "CALCULATOR")

	-- Save a copy of the initial mod database
	local initModDB = common.New("ModDB")
	initModDB:AddDB(env.modDB)
	initModDB.conditions = copyTable(env.modDB.conditions)
	initModDB.multipliers = copyTable(env.modDB.multipliers)
	local initEnemyDB = common.New("ModDB")
	initEnemyDB:AddDB(env.enemyDB)
	initEnemyDB.conditions = copyTable(env.enemyDB.conditions)
	initEnemyDB.multipliers = copyTable(env.enemyDB.multipliers)

	-- Run base calculation pass
	calcs.perform(env)
	local baseOutput = env.player.output

	return function(...)
		-- Restore initial mod database
		env.modDB.mods = wipeTable(env.modDB.mods)
		env.modDB:AddDB(initModDB)
		env.modDB.conditions = copyTable(initModDB.conditions)
		env.modDB.multipliers = copyTable(initModDB.multipliers)
		env.enemyDB.mods = wipeTable(env.enemyDB.mods)
		env.enemyDB:AddDB(initEnemyDB)
		env.enemyDB.conditions = copyTable(initEnemyDB.conditions)
		env.enemyDB.multipliers = copyTable(initEnemyDB.multipliers)
		
		-- Call function to make modifications to the enviroment
		modFunc(env, ...)
		
		-- Run calculation pass
		calcs.perform(env)

		return env.player.output
	end, baseOutput	
end

-- Get fast calculator for adding tree node modifiers
function calcs.getNodeCalculator(build)
	return getCalculator(build, true, function(env, nodeList)
		-- Build and merge modifiers for these nodes
		env.modDB:AddList(calcs.buildNodeModList(env, nodeList))
		--[[local nodeModList = buildNodeModList(env, nodeList)
		if remove then
			for _, mod in ipairs(nodeModList) do
				if mod.type == "LIST" or mod.type == "FLAG" then
					for i, dbMod in ipairs(env.modDB.mods[mod.name] or { }) do
						if mod == dbMod then
							t_remove(env.modDB.mods[mod.name], i)
							break
						end
					end
				elseif mod.type == "MORE" then
					env.modDB:NewMod(mod.name, mod.type, (1 / (1 + mod.value / 100) - 1) * 100, mod.source, mod.flags, mod.keywordFlags, unpack(mod.tagList))
				else
					env.modDB:NewMod(mod.name, mod.type, -mod.value, mod.source, mod.flags, mod.keywordFlags, unpack(mod.tagList))
				end
			end
		else
			env.modDB:AddList(nodeModList)
		end]]
	end)
end

-- Get calculator for other changes (adding/removing nodes, items, gems, etc)
function calcs.getMiscCalculator(build)
	-- Run base calculation pass
	local env = calcs.initEnv(build, "CALCULATOR")
	calcs.perform(env)
	local baseOutput = env.player.output

	return function(override)
		env = calcs.initEnv(build, "CALCULATOR", override)
		calcs.perform(env)
		return env.player.output
	end, baseOutput	
end

-- Build output for display in the side bar or calcs tab
function calcs.buildOutput(build, mode)
	-- Build output
	local env = calcs.initEnv(build, mode)
	calcs.perform(env)

	local output = env.player.output

	if mode == "MAIN" then
		output.ExtraPoints = env.modDB:Sum("BASE", nil, "ExtraPoints")

		local specCfg = {
			source = "Tree"
		}
		output["Spec:LifeInc"] = env.modDB:Sum("INC", specCfg, "Life")
		output["Spec:ManaInc"] = env.modDB:Sum("INC", specCfg, "Mana")
		output["Spec:ArmourInc"] = env.modDB:Sum("INC", specCfg, "Armour", "ArmourAndEvasion")
		output["Spec:EvasionInc"] = env.modDB:Sum("INC", specCfg, "Evasion", "ArmourAndEvasion")
		output["Spec:EnergyShieldInc"] = env.modDB:Sum("INC", specCfg, "EnergyShield")

		env.skillsUsed = { }
		for _, activeSkill in ipairs(env.activeSkillList) do
			env.skillsUsed[activeSkill.activeGem.name] = true
		end

		env.conditionsUsed = { }
		env.enemyConditionsUsed = { }
		local function addCond(out, var, mod)
			if not out[var] then
				out[var] = { }
			end
			t_insert(out[var], mod)
		end
		local function addTag(out, tag, mod)
			if tag.varList then
				for _, var in ipairs(tag.varList) do
					addCond(out, var, mod)
				end
			else
				addCond(out, tag.var, mod)
			end
		end
		for _, actor in ipairs({env.player, env.minion}) do
			for modName, modList in pairs(actor.modDB.mods) do
				for _, mod in ipairs(modList) do
					for _, tag in ipairs(mod.tagList) do
						if tag.type == "Condition" and actor == env.player then
							addTag(env.conditionsUsed, tag, mod)
						elseif tag.type == "EnemyCondition" then
							addTag(env.enemyConditionsUsed, tag, mod)
						end
					end
				end
			end
		end
		for modName, modList in pairs(env.enemyDB.mods) do
			for _, mod in ipairs(modList) do
				for _, tag in ipairs(mod.tagList) do
					if tag.type == "Condition" then
						addTag(env.enemyConditionsUsed, tag, mod)
					end
				end
			end
		end
	elseif mode == "CALCS" then
		local buffList = { }
		local combatList = { }
		local curseList = { }
		if output.PowerCharges > 0 then
			t_insert(combatList, s_format("%d Power Charges", output.PowerCharges))
		end
		if output.FrenzyCharges > 0 then
			t_insert(combatList, s_format("%d Frenzy Charges", output.FrenzyCharges))
		end
		if output.EnduranceCharges > 0 then
			t_insert(combatList, s_format("%d Endurance Charges", output.EnduranceCharges))
		end
		if env.modDB.conditions.Onslaught then
			t_insert(combatList, "Onslaught")
		end
		if env.modDB.conditions.UnholyMight then
			t_insert(combatList, "Unholy Might")
		end
		for _, activeSkill in ipairs(env.activeSkillList) do
			if activeSkill.buffSkill then
				if activeSkill.skillFlags.multiPart then
					t_insert(buffList, activeSkill.activeGem.name .. " (" .. activeSkill.skillPartName .. ")")
				else
					t_insert(buffList, activeSkill.activeGem.name)
				end
			end
			if activeSkill.debuffSkill then
				if activeSkill.skillFlags.multiPart then
					t_insert(curseList, activeSkill.activeGem.name .. " (" .. activeSkill.skillPartName .. ")")
				else
					t_insert(curseList, activeSkill.activeGem.name)
				end
			end
		end
		for _, slot in ipairs(env.curseSlots) do
			t_insert(curseList, slot.name)
		end
		output.BuffList = table.concat(buffList, ", ")
		output.CombatList = table.concat(combatList, ", ")
		output.CurseList = table.concat(curseList, ", ")
		if env.minion then
			local buffList = { }
			for _, activeSkill in ipairs(env.activeSkillList) do
				if activeSkill.minionBuffSkill then
					if activeSkill.skillFlags.multiPart then
						t_insert(buffList, activeSkill.activeGem.name .. " (" .. activeSkill.skillPartName .. ")")
					else
						t_insert(buffList, activeSkill.activeGem.name)
					end
				end
			end
			output.Minion.BuffList = table.concat(buffList, ", ")
			output.Minion.CurseList = output.CurseList
		end

		infoDump(env)
	end

	return env
end

return calcs