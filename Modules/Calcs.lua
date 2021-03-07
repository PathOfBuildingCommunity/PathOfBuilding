-- Path of Building
--
-- Module: Calcs
-- Manages the calculation system.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local s_format = string.format

local calcs = { }
calcs.breakdownModule = "Modules/CalcBreakdown"
LoadModule("Modules/CalcSetup", calcs)
LoadModule("Modules/CalcPerform", calcs)
LoadModule("Modules/CalcActiveSkill", calcs)
LoadModule("Modules/CalcDefence", calcs)
LoadModule("Modules/CalcOffence", calcs)

-- Print various tables to the console
local function infoDump(env)
	if env.modDB.parent then
		env.modDB.parent:Print()
	end
	env.modDB:Print()
	if env.minion then
		ConPrintf("=== Minion Mod DB ===")
		env.minion.modDB:Print()
	end
	ConPrintf("=== Enemy Mod DB ===")
	env.enemyDB:Print()
	local mainSkill = env.minion and env.minion.mainSkill or env.player.mainSkill
	ConPrintf("=== Main Skill ===")
	for _, skillEffect in ipairs(mainSkill.effectList) do
		ConPrintf("%s %d/%d", skillEffect.grantedEffect.name, skillEffect.level, skillEffect.quality)
	end
	ConPrintf("=== Main Skill Flags ===")
	ConPrintf("Mod: %s", modLib.formatFlags(mainSkill.skillCfg.flags, ModFlag))
	ConPrintf("Keyword: %s", modLib.formatFlags(mainSkill.skillCfg.keywordFlags, KeywordFlag))
	ConPrintf("=== Main Skill Mods ===")
	mainSkill.skillModList.parent:Print()
	mainSkill.skillModList:Print()
	ConPrintf("=== Main Skill Data ===")
	prettyPrintTable(mainSkill.skillData)
	ConPrintf("== Aux Skills ==")
	for i, aux in ipairs(env.auxSkillList) do
		ConPrintf("Skill #%d:", i)
		for _, skillEffect in ipairs(aux.effectList) do
			ConPrintf("  %s %d/%d", skillEffect.grantedEffect.name, skillEffect.level, skillEffect.quality)
		end
	end
	ConPrintf("== Output Table ==")
	prettyPrintTable(env.player.output)
end

-- Generate a function for calculating the effect of some modification to the environment
local function getCalculator(build, fullInit, modFunc)
	-- Initialise environment
	local env = calcs.initEnv(build, "CALCULATOR")

	-- Save a copy of the initial mod database
	local initModDB = new("ModDB")
	initModDB:AddDB(env.modDB)
	initModDB.conditions = copyTable(env.modDB.conditions)
	initModDB.multipliers = copyTable(env.modDB.multipliers)
	local initEnemyDB = new("ModDB")
	initEnemyDB:AddDB(env.enemyDB)
	initEnemyDB.conditions = copyTable(env.enemyDB.conditions)
	initEnemyDB.multipliers = copyTable(env.enemyDB.multipliers)

	-- Run base calculation pass
	calcs.perform(env)
	local baseOutput = env.player.output

	env.modDB.parent = initModDB
	env.enemyDB.parent = initEnemyDB

	return function(...)
		-- Remove mods added during the last pass
		wipeTable(env.modDB.mods)
		wipeTable(env.modDB.conditions)
		wipeTable(env.modDB.multipliers)
		wipeTable(env.enemyDB.mods)
		wipeTable(env.enemyDB.conditions)
		wipeTable(env.enemyDB.multipliers)

		-- Call function to make modifications to the environment
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
		env.modDB:AddList(calcs.buildModListForNodeList(env, nodeList))
	end)
end

-- Get calculator for other changes (adding/removing nodes, items, gems, etc)
function calcs.getMiscCalculator(build)
	-- Run base calculation pass
	local env = calcs.initEnv(build, "CALCULATOR")
	calcs.perform(env)

	local fullDPS = calcs.calcFullDPS(build, "CALCULATOR")

	env.player.output.SkillDPS = fullDPS.skills
	env.player.output.FullDPS = fullDPS.combinedDPS
	local baseOutput = env.player.output

	return function(override)
		env = calcs.initEnv(build, "CALCULATOR", override)
		calcs.perform(env)

		fullDPS = calcs.calcFullDPS(build, "CALCULATOR", override)

		env.player.output.SkillDPS = fullDPS.skills
		env.player.output.FullDPS = fullDPS.combinedDPS
		return env.player.output
	end, baseOutput	
end

local function getActiveSkillCount(activeSkill)
	if not activeSkill.socketGroup then
		return 1
	else
		local gemList = activeSkill.socketGroup.gemList
		for _, gemData in pairs(gemList) do
			if gemData.gemData and activeSkill.activeEffect.grantedEffect == gemData.gemData.grantedEffect then
				return gemData.count or 1
			end
		end
	end
	return 1
end

function calcs.calcFullDPS(build, mode, override)
	local fullEnv = calcs.initEnv(build, mode, override or {})
	local usedEnv = nil

	local fullDPS = { combinedDPS = 0, skills = { }, poisonDPS = 0, impaleDPS = 0, igniteDPS = 0, bleedDPS = 0, decayDPS = 0, dotDPS = 0 }
	local bleedSource = ""
	local igniteDPS = 0
	local igniteSource = ""
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if activeSkill.socketGroup and activeSkill.socketGroup.includeInFullDPS and not isExcludedFromFullDps(activeSkill) then
			local uuid = cacheSkillUUID(activeSkill)
			if GlobalCache.cachedData[uuid] and not override then
				usedEnv = GlobalCache.cachedData[uuid].Env
				activeSkill = usedEnv.player.mainSkill
			else
				fullEnv.player.mainSkill = activeSkill
				calcs.perform(fullEnv)
				usedEnv = fullEnv
			end
			local activeSkillCount = getActiveSkillCount(activeSkill)
			if activeSkill.minion then
				if usedEnv.minion.output.TotalDPS and usedEnv.minion.output.TotalDPS > 0 then
					if not fullDPS.skills[activeSkill.activeEffect.grantedEffect.name] then
						t_insert(fullDPS.skills, { name = activeSkill.activeEffect.grantedEffect.name, dps = usedEnv.minion.output.TotalDPS, count = activeSkillCount })
					else
						ConPrintf("[Minion] HELP! Numerous same-named effects! '" .. activeSkill.activeEffect.grantedEffect.name .. "'")
					end
					fullDPS.combinedDPS = fullDPS.combinedDPS + usedEnv.minion.output.TotalDPS * activeSkillCount
				end
				if usedEnv.minion.output.BleedDPS and usedEnv.minion.output.BleedDPS > fullDPS.bleedDPS then
					fullDPS.bleedDPS = usedEnv.minion.output.BleedDPS
					bleedSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.minion.output.IgniteDPS and usedEnv.minion.output.IgniteDPS > fullDPS.igniteDPS then
					fullDPS.igniteDPS = usedEnv.minion.output.IgniteDPS
					igniteSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.minion.output.PoisonDPS and usedEnv.minion.output.PoisonDPS > 0 then
					fullDPS.poisonDPS = fullDPS.poisonDPS + usedEnv.minion.output.PoisonDPS
				end
				if usedEnv.minion.output.ImpaleDPS and usedEnv.minion.output.ImpaleDPS > 0 then
					fullDPS.impaleDPS = fullDPS.impaleDPS + usedEnv.minion.output.ImpaleDPS
				end
				if usedEnv.minion.output.DecayDPS and usedEnv.minion.output.DecayDPS > 0 then
					fullDPS.decayDPS = fullDPS.decayDPS + usedEnv.minion.output.DecayDPS
				end
				if usedEnv.minion.output.TotalDot and usedEnv.minion.output.TotalDot > 0 then
					fullDPS.dotDPS = fullDPS.dotDPS + usedEnv.minion.output.TotalDot
				end
			else
				if usedEnv.player.output.TotalDPS and usedEnv.player.output.TotalDPS > 0 then
					if not fullDPS.skills[activeSkill.activeEffect.grantedEffect.name] then
						t_insert(fullDPS.skills, { name = activeSkill.activeEffect.grantedEffect.name, dps = usedEnv.player.output.TotalDPS, count = activeSkillCount, trigger = activeSkill.infoTrigger, skillPart = activeSkill.skillPartName })
					else
						ConPrintf("HELP! Numerous same-named effects! '" .. activeSkill.activeEffect.grantedEffect.name .. "'")
					end
					fullDPS.combinedDPS = fullDPS.combinedDPS + usedEnv.player.output.TotalDPS * activeSkillCount
				end
				if usedEnv.player.output.BleedDPS and usedEnv.player.output.BleedDPS > fullDPS.bleedDPS then
					fullDPS.bleedDPS = usedEnv.player.output.BleedDPS
					bleedSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.IgniteDPS and usedEnv.player.output.IgniteDPS > fullDPS.igniteDPS then
					fullDPS.igniteDPS = usedEnv.player.output.IgniteDPS
					igniteSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.PoisonDPS and usedEnv.player.output.PoisonDPS > 0 then
					fullDPS.poisonDPS = fullDPS.poisonDPS + usedEnv.player.output.PoisonDPS
				end
				if usedEnv.player.output.ImpaleDPS and usedEnv.player.output.ImpaleDPS > 0 then
					fullDPS.impaleDPS = fullDPS.impaleDPS + usedEnv.player.output.ImpaleDPS
				end
				if usedEnv.player.output.DecayDPS and usedEnv.player.output.DecayDPS > 0 then
					fullDPS.decayDPS = fullDPS.decayDPS + usedEnv.player.output.DecayDPS
				end
				if usedEnv.player.output.TotalDot and usedEnv.player.output.TotalDot > 0 then
					fullDPS.dotDPS = fullDPS.dotDPS + usedEnv.player.output.TotalDot
				end
			end
		
			-- Re-Build env calculator for new run
			fullEnv = calcs.initEnv(build, mode)
		end
	end

	-- Re-Add ailment DPS components
	if fullDPS.bleedDPS > 0 then
		t_insert(fullDPS.skills, { name = "Best Bleed DPS", dps = fullDPS.bleedDPS, count = 1, source = bleedSource })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.bleedDPS
	end
	if fullDPS.igniteDPS > 0 then
		t_insert(fullDPS.skills, { name = "Best Ignite DPS", dps = fullDPS.igniteDPS, count = 1, source = igniteSource })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.igniteDPS
	end
	if fullDPS.poisonDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full Poison DPS", dps = fullDPS.poisonDPS, count = 1 })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.poisonDPS
	end
	if fullDPS.impaleDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full Impale DPS", dps = fullDPS.impaleDPS, count = 1 })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.impaleDPS
	end
	if fullDPS.decayDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full Decay DPS", dps = fullDPS.decayDPS, count = 1 })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.decayDPS
	end
	if fullDPS.dotDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full DoT DPS", dps = fullDPS.dotDPS, count = 1 })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.dotDPS
	end

	return fullDPS
end

-- Process active skill
function calcs.buildActiveSkill(build, mode, skill)
	local fullEnv = calcs.initEnv(build, mode)
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if cacheSkillUUID(activeSkill) == cacheSkillUUID(skill) then
			fullEnv.player.mainSkill = activeSkill
			calcs.perform(fullEnv)
			--local uuid = cacheSkillUUID(activeSkill)
			--ConPrintf("[Cached] " .. uuid)
			--ConPrintf("\tName: " .. GlobalCache.cachedData[uuid].Name)
			--ConPrintf("\tAPS: " .. tostring(GlobalCache.cachedData[uuid].Speed))
			--ConPrintf("\tHitChance: " .. tostring(GlobalCache.cachedData[uuid].HitChance))
			--ConPrintf("\tCritChance: " .. tostring(GlobalCache.cachedData[uuid].CritChance))
			--ConPrintf("\n")
			return
		end
	end
end

-- Build output for display in the side bar or calcs tab
function calcs.buildOutput(build, mode)
	-- Build output for selected main skill
	local env = calcs.initEnv(build, mode)
	calcs.perform(env)

	local output = env.player.output

	-- Build output across all active skills
	local fullDPS = calcs.calcFullDPS(build, "CACHE")

	-- Add Full DPS data to main `env`
	env.player.output.SkillDPS = fullDPS.skills
	env.player.output.FullDPS = fullDPS.combinedDPS

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
		for _, activeSkill in ipairs(env.player.activeSkillList) do
			for _, skillEffect in ipairs(activeSkill.effectList) do
				env.skillsUsed[skillEffect.grantedEffect.name] = true
			end
			if activeSkill.minion then
				for	_, activeSkill in ipairs(activeSkill.minion.activeSkillList) do
					env.skillsUsed[activeSkill.activeEffect.grantedEffect.id] = true
				end
			end
		end

		env.conditionsUsed = { }
		env.multipliersUsed = { }
		env.minionConditionsUsed = { }
		env.enemyConditionsUsed = { }
		env.enemyMultipliersUsed = { }
		local function addCond(out, var, mod)
			if not out[var] then
				out[var] = { }
			end
			t_insert(out[var], mod)
		end
		local function addCondTag(out, tag, mod)
			if tag.varList then
				for _, var in ipairs(tag.varList) do
					addCond(out, var, mod)
				end
			else
				addCond(out, tag.var, mod)
			end
		end
		local function addMult(out, var, mod)
			if not out[var] then
				out[var] = { }
			end
			t_insert(out[var], mod)
		end
		local function addMultTag(out, tag, mod)
			if tag.varList then
				for _, var in ipairs(tag.varList) do
					addMult(out, var, mod)
				end
			else
				addMult(out, tag.var, mod)
			end
		end
		local function addModTags(actor, mod)
			for _, tag in ipairs(mod) do
				if tag.type == "IgnoreCond" then
					break
				elseif tag.type == "Condition" then
					if actor == env.player then
						addCondTag(env.conditionsUsed, tag, mod)
					else
						addCondTag(env.minionConditionsUsed, tag, mod)
					end
				elseif tag.type == "ActorCondition" and tag.actor == "enemy" then
					addCondTag(env.enemyConditionsUsed, tag, mod)
				elseif tag.type == "Multiplier" or tag.type == "MultiplierThreshold" then
					if not tag.actor then
						if actor == env.player then
							addMultTag(env.multipliersUsed, tag, mod)
						end
					elseif tag.actor == "enemy" then
						addMultTag(env.enemyMultipliersUsed, tag, mod)
					end
				end
			end
		end
		for _, actor in ipairs({env.player, env.minion}) do
			for modName, modList in pairs(actor.modDB.mods) do
				for _, mod in ipairs(modList) do
					addModTags(actor, mod)
				end
			end
		end
		for _, activeSkill in pairs(env.player.activeSkillList) do
			for _, mod in ipairs(activeSkill.baseSkillModList) do
				addModTags(env.player, mod)
			end
			if activeSkill.minion then
				for _, activeSkill in pairs(activeSkill.minion.activeSkillList) do
					for _, mod in ipairs(activeSkill.baseSkillModList) do
						addModTags(env.minion, mod)
					end
				end
			end
		end
		for modName, modList in pairs(env.enemyDB.mods) do
			for _, mod in ipairs(modList) do
				for _, tag in ipairs(mod) do
					if tag.type == "IgnoreCond" then
						break
					elseif tag.type == "Condition" then
						addCondTag(env.enemyConditionsUsed, tag, mod)
					elseif tag.type == "Multiplier" or tag.type == "MultiplierThreshold" then
						if not tag.actor then
							addMultTag(env.enemyMultipliersUsed, tag, mod)
						end
					end
				end
			end
		end
--		ConPrintf("=== Cond ===")
--		ConPrintTable(env.conditionsUsed)
--		ConPrintf("=== Mult ===")
--		ConPrintTable(env.multipliersUsed)
--		ConPrintf("=== Minion Cond ===")
--		ConPrintTable(env.minionConditionsUsed)
--		ConPrintf("=== Enemy Cond ===")
--		ConPrintTable(env.enemyConditionsUsed)
--		ConPrintf("=== Enemy Mult ===")
--		ConPrintTable(env.enemyMultipliersUsed)
	end
	if mode == "CALCS" then
		local buffList = { }
		local combatList = { }
		local curseList = { }
		if output.PowerCharges > 0 then
			t_insert(combatList, s_format("%d Power Charges", output.PowerCharges))
		end
		if output.AbsorptionCharges > 0 then
			t_insert(combatList, s_format("%d Absoprtion Charges", output.AbsorptionCharges))
		end
		if output.FrenzyCharges > 0 then
			t_insert(combatList, s_format("%d Frenzy Charges", output.FrenzyCharges))
		end
		if output.AfflictionCharges > 0 then
			t_insert(combatList, s_format("%d Affliction Charges", output.AfflictionCharges))
		end
		if output.EnduranceCharges > 0 then
			t_insert(combatList, s_format("%d Endurance Charges", output.EnduranceCharges))
		end
		if output.BrutalCharges > 0 then
			t_insert(combatList, s_format("%d Brutal Charges", output.BrutalCharges))
		end
		if output.SiphoningCharges > 0 then
			t_insert(combatList, s_format("%d Siphoning Charges", output.SiphoningCharges))
		end
		if output.ChallengerCharges > 0 then
			t_insert(combatList, s_format("%d Challenger Charges", output.ChallengerCharges))
		end
		if output.BlitzCharges > 0 then
			t_insert(combatList, s_format("%d Blitz Charges", output.BlitzCharges))
		end
		if output.InspirationCharges > 0 then
			t_insert(combatList, s_format("%d Inspiration Charges", output.InspirationCharges))
		end
		if output.GhostShrouds > 0 then
			t_insert(combatList, s_format("%d Ghost Shrouds", output.GhostShrouds))
		end
		if output.CrabBarriers > 0 then
			t_insert(combatList, s_format("%d Crab Barriers", output.CrabBarriers))
		end
		if env.modDB:Flag(nil, "Fortify") then
			t_insert(combatList, "Fortify")
		end
		if env.modDB:Flag(nil, "Onslaught") then
			t_insert(combatList, "Onslaught")
		end
		if env.modDB:Flag(nil, "UnholyMight") then
			t_insert(combatList, "Unholy Might")
		end
		if env.modDB:Flag(nil, "Tailwind") then
			t_insert(combatList, "Tailwind")
		end
		if env.modDB:Flag(nil, "Adrenaline") then
			t_insert(combatList, "Adrenaline")
		end
		if env.modDB:Flag(nil, "AlchemistsGenius") then
			t_insert(combatList, "Alchemist's Genius")
		end
		if env.modDB:Flag(nil, "HerEmbrace") then
			t_insert(combatList, "Her Embrace")
		end
		for name in pairs(env.buffs) do
			t_insert(buffList, name)
		end
		if env.modDB:Flag(nil, "Elusive") then
			t_insert(combatList, "Elusive")
		end
		table.sort(buffList)
		env.player.breakdown.SkillBuffs = { modList = { } }
		for _, name in ipairs(buffList) do
			for _, mod in ipairs(env.buffs[name]) do
				local value = env.modDB:EvalMod(mod)
				if value and value ~= 0 then
					t_insert(env.player.breakdown.SkillBuffs.modList, {
						mod = mod,
						value = value,
					})
				end
			end
		end
		env.player.breakdown.SkillDebuffs = { modList = { } }
		for name, modList in pairs(env.debuffs) do
			t_insert(curseList, name)
		end
		table.sort(curseList)
		for index, name in ipairs(curseList) do
			for _, mod in ipairs(env.debuffs[name]) do
				local value = env.enemy.modDB:EvalMod(mod)
				if value and value ~= 0 then
					t_insert(env.player.breakdown.SkillDebuffs.modList, {
						mod = mod,
						value = value,
					})
				end
			end
			local stackCount = env.debuffs[name]:Sum("BASE", nil, "Multiplier:"..name.."Stack")
			if stackCount > 0 then
				curseList[index] = name .. " (" .. stackCount .. " stack" .. (stackCount > 1 and "s" or "") .. ")"
			end
		end
		for _, slot in ipairs(env.curseSlots) do
			t_insert(curseList, slot.name)
			if slot.modList then
				for _, mod in ipairs(slot.modList) do
					local value = env.enemy.modDB:EvalMod(mod)
					if value and value ~= 0 then
						t_insert(env.player.breakdown.SkillDebuffs.modList, {
							mod = mod,
							value = value,
						})
					end
				end
			end
		end
		output.BuffList = table.concat(buffList, ", ")
		output.CombatList = table.concat(combatList, ", ")
		output.CurseList = table.concat(curseList, ", ")
		if env.minion then
			local buffList = { }
			local combatList = { }
			if output.Minion.PowerCharges > 0 then
				t_insert(combatList, s_format("%d Power Charges", output.Minion.PowerCharges))
			end
			if output.Minion.FrenzyCharges > 0 then
				t_insert(combatList, s_format("%d Frenzy Charges", output.Minion.FrenzyCharges))
			end
			if output.Minion.EnduranceCharges > 0 then
				t_insert(combatList, s_format("%d Endurance Charges", output.Minion.EnduranceCharges))
			end
			if env.minion.modDB:Flag(nil, "Fortify") then
				t_insert(combatList, "Fortify")
			end
			if env.minion.modDB:Flag(nil, "Onslaught") then
				t_insert(combatList, "Onslaught")
			end
			if env.minion.modDB:Flag(nil, "UnholyMight") then
				t_insert(combatList, "Unholy Might")
			end
			if env.minion.modDB:Flag(nil, "Tailwind") then
				t_insert(combatList, "Tailwind")
			end
			for name in pairs(env.minionBuffs) do
				t_insert(buffList, name)
			end
			table.sort(buffList)
			env.minion.breakdown.SkillBuffs = { modList = { } }
			for _, name in ipairs(buffList) do
				for _, mod in ipairs(env.minionBuffs[name]) do
					local value = env.minion.modDB:EvalMod(mod)
					if value and value ~= 0 then
						t_insert(env.minion.breakdown.SkillBuffs.modList, {
							mod = mod,
							value = value,
						})
					end
				end
			end
			env.minion.breakdown.SkillDebuffs = env.player.breakdown.SkillDebuffs
			output.Minion.BuffList = table.concat(buffList, ", ")
			output.Minion.CombatList = table.concat(combatList, ", ")
			output.Minion.CurseList = output.CurseList
		end

		-- infoDump(env)
	end

	return env
end

return calcs