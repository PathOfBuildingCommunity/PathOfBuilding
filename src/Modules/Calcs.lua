-- Path of Building
--
-- Module: Calcs
-- Manages the calculation system.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert
local s_format = string.format
local m_min = math.min

local calcs = { }
calcs.breakdownModule = "Modules/CalcBreakdown"
LoadModule("Modules/CalcSetup", calcs)
LoadModule("Modules/CalcPerform", calcs)
LoadModule("Modules/CalcActiveSkill", calcs)
LoadModule("Modules/CalcDefence", calcs)
LoadModule("Modules/CalcOffence", calcs)
LoadModule("Modules/CalcTriggers", calcs)
LoadModule("Modules/CalcMirages.lua", calcs)

-- Get the average value of a table -- note this is unused
function math.average(t)
	local sum = 0
	local count = 0
	for k,v in pairs(t) do
		if type(v) == 'number' then
			sum = sum + v
			count = count + 1
		end
	end
	return (sum / count)
end

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
	local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, "CALCULATOR")

	-- Run base calculation pass
	calcs.perform(env)
	local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", {}, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = nil })
	env.player.output.SkillDPS = fullDPS.skills
	env.player.output.FullDPS = fullDPS.combinedDPS
	env.player.output.FullDotDPS = fullDPS.TotalDotDPS
	local baseOutput = env.player.output

	env.modDB.parent = cachedPlayerDB
	env.enemyDB.parent = cachedEnemyDB
	if cachedMinionDB then
		env.minion.modDB.parent = cachedMinionDB
	end

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
		fullDPS = calcs.calcFullDPS(build, "CALCULATOR", {}, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = env})
		env.player.output.SkillDPS = fullDPS.skills
		env.player.output.FullDPS = fullDPS.combinedDPS
		env.player.output.FullDotDPS = fullDPS.TotalDotDPS

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
	local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, "CALCULATOR")
	calcs.perform(env)
	local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", {}, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = env})
	env.player.output.SkillDPS = fullDPS.skills
	env.player.output.FullDPS = fullDPS.combinedDPS
	env.player.output.FullDotDPS = fullDPS.TotalDotDPS

	local baseOutput = env.player.output

	return function(override, accelerate)
		local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, "CALCULATOR", override)
		-- we need to preserve the override somewhere for use by possible trigger-based build-outs with overrides
		env.override = override
		calcs.perform(env)
		if GlobalCache.useFullDPS or build.viewMode == "TREE" then
			-- prevent upcoming calculation from using Cached Data and thus forcing it to re-calculate new FullDPS roll-up 
			-- without this, FullDPS increase/decrease when for node/item/gem comparison would be all 0 as it would be comparing
			-- A with A (due to cache reuse) instead of A with B
			local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", override, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = env, accelerate = accelerate })
			-- reset cache usage
			env.player.output.SkillDPS = fullDPS.skills
			env.player.output.FullDPS = fullDPS.combinedDPS
			env.player.output.FullDotDPS = fullDPS.TotalDotDPS
		end
		return env.player.output
	end, baseOutput	
end

local function getActiveSkillCount(activeSkill)
	if not activeSkill.socketGroup then
		return 1, true
	elseif activeSkill.socketGroup.groupCount then
		return activeSkill.socketGroup.groupCount, true
	else
		local gemList = activeSkill.socketGroup.gemList
		for _, gemData in pairs(gemList) do
			if gemData.gemData then
				if gemData.gemData.vaalGem then
					if activeSkill.activeEffect.grantedEffect == gemData.gemData.grantedEffectList[1] then
						return gemData.count or 1,  gemData.enableGlobal1 == true
					elseif activeSkill.activeEffect.grantedEffect == gemData.gemData.grantedEffectList[2] then
						return gemData.count or 1,  gemData.enableGlobal2 == true
					end
				else
					if (activeSkill.activeEffect.grantedEffect == gemData.gemData.grantedEffect and not gemData.gemData.grantedEffect.support) or (activeSkill.activeEffect.grantedEffect == gemData.gemData.secondaryGrantedEffect) then
						return gemData.count or 1, true
					end
				end
			end
		end
	end
	return 1, true
end

function calcs.calcFullDPS(build, mode, override, specEnv)
	local fullEnv, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, mode, override, specEnv)
	local usedEnv = nil

	local fullDPS = {
		combinedDPS = 0,
		TotalDotDPS = 0,
		skills = { },
		poisonDPS = 0,
		causticGroundDPS = 0,
		impaleDPS = 0,
		igniteDPS = 0,
		burningGroundDPS = 0,
		bleedDPS = 0,
		corruptingBloodDPS = 0,
		decayDPS = 0,
		dotDPS = 0,
		cullingMulti = 0
	}

	local bleedSource = ""
	local corruptingBloodSource = ""
	local igniteSource = ""
	local burningGroundSource = ""
	local causticGroundSource = ""
	
	-- calc defences extra part should only run on the last skill of FullDPS
	local numActiveSkillInFullDPS = 0
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if activeSkill.socketGroup and activeSkill.socketGroup.includeInFullDPS and not GlobalCache.excludeFullDpsList[cacheSkillUUID(activeSkill, fullEnv)] then
			local activeSkillCount, enabled = getActiveSkillCount(activeSkill)
			if enabled then
				numActiveSkillInFullDPS = numActiveSkillInFullDPS + 1
			end
		end
	end
	
	GlobalCache.numActiveSkillInFullDPS = 0
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if activeSkill.socketGroup and activeSkill.socketGroup.includeInFullDPS and not GlobalCache.excludeFullDpsList[cacheSkillUUID(activeSkill, fullEnv)] then
			local activeSkillCount, enabled = getActiveSkillCount(activeSkill)
			if enabled then
				GlobalCache.numActiveSkillInFullDPS = GlobalCache.numActiveSkillInFullDPS + 1
				fullEnv.player.mainSkill = activeSkill
				calcs.perform(fullEnv, (GlobalCache.numActiveSkillInFullDPS ~= numActiveSkillInFullDPS))
				usedEnv = fullEnv
				local minionName = nil
				if activeSkill.minion or usedEnv.minion then
					if usedEnv.minion.output.TotalDPS and usedEnv.minion.output.TotalDPS > 0 then
						minionName = (activeSkill.minion and activeSkill.minion.minionData.name..": ") or (usedEnv.minion and usedEnv.minion.minionData.name..": ") or ""
						t_insert(fullDPS.skills, { name = activeSkill.activeEffect.grantedEffect.name, dps = usedEnv.minion.output.TotalDPS, count = activeSkillCount, trigger = activeSkill.infoTrigger, skillPart = minionName..activeSkill.skillPartName })
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
						fullDPS.poisonDPS = fullDPS.poisonDPS + usedEnv.minion.output.PoisonDPS * (usedEnv.minion.output.TotalPoisonStacks or 1) * activeSkillCount
					end
					if usedEnv.minion.output.ImpaleDPS and usedEnv.minion.output.ImpaleDPS > 0 then
						fullDPS.impaleDPS = fullDPS.impaleDPS + usedEnv.minion.output.ImpaleDPS * activeSkillCount
					end
					if usedEnv.minion.output.DecayDPS and usedEnv.minion.output.DecayDPS > 0 then
						fullDPS.decayDPS = fullDPS.decayDPS + usedEnv.minion.output.DecayDPS
					end
					if usedEnv.minion.output.TotalDot and usedEnv.minion.output.TotalDot > 0 then
						fullDPS.dotDPS = fullDPS.dotDPS + usedEnv.minion.output.TotalDot
					end
					if usedEnv.minion.output.CullMultiplier and usedEnv.minion.output.CullMultiplier > 1 and usedEnv.minion.output.CullMultiplier > fullDPS.cullingMulti then
						fullDPS.cullingMulti = usedEnv.minion.output.CullMultiplier
					end
					-- This is a fix to prevent Absolution spell hit from being counted multiple times when increasing minions count
					if activeSkill.activeEffect.grantedEffect.name == "Absolution" and fullEnv.modDB:Flag(false, "Condition:AbsolutionSkillDamageCountedOnce") then
						activeSkillCount = 1
						activeSkill.infoMessage2 = "Skill Damage"
					end
				end

				if activeSkill.mirage then
					local mirageCount = (activeSkill.mirage.count or 1) * activeSkillCount
					if activeSkill.mirage.output.TotalDPS and activeSkill.mirage.output.TotalDPS > 0 then
						t_insert(fullDPS.skills, { name = activeSkill.mirage.name .. " (Mirage)", dps = activeSkill.mirage.output.TotalDPS, count = mirageCount, trigger = activeSkill.mirage.infoTrigger, skillPart = activeSkill.mirage.skillPartName })
						fullDPS.combinedDPS = fullDPS.combinedDPS + activeSkill.mirage.output.TotalDPS * mirageCount
					end
					if activeSkill.mirage.output.BleedDPS and activeSkill.mirage.output.BleedDPS > fullDPS.bleedDPS then
						fullDPS.bleedDPS = activeSkill.mirage.output.BleedDPS
						bleedSource = activeSkill.activeEffect.grantedEffect.name .. " (Mirage)"
					end
					if activeSkill.mirage.output.IgniteDPS and activeSkill.mirage.output.IgniteDPS > fullDPS.igniteDPS then
						fullDPS.igniteDPS = activeSkill.mirage.output.IgniteDPS
						igniteSource = activeSkill.activeEffect.grantedEffect.name .. " (Mirage)"
					end
					if activeSkill.mirage.output.PoisonDPS and activeSkill.mirage.output.PoisonDPS > 0 then
						fullDPS.poisonDPS = fullDPS.poisonDPS + activeSkill.mirage.output.PoisonDPS * (activeSkill.mirage.output.TotalPoisonStacks or 1) * mirageCount
					end
					if activeSkill.mirage.output.ImpaleDPS and activeSkill.mirage.output.ImpaleDPS > 0 then
						fullDPS.impaleDPS = fullDPS.impaleDPS + activeSkill.mirage.output.ImpaleDPS * mirageCount
					end
					if activeSkill.mirage.output.DecayDPS and activeSkill.mirage.output.DecayDPS > 0 then
						fullDPS.decayDPS = fullDPS.decayDPS + activeSkill.mirage.output.DecayDPS
					end
					if activeSkill.mirage.output.TotalDot and activeSkill.mirage.output.TotalDot > 0 and (activeSkill.skillFlags.DotCanStack or (usedEnv.player.output.TotalDot and usedEnv.player.output.TotalDot == 0)) then
						fullDPS.dotDPS = fullDPS.dotDPS + activeSkill.mirage.output.TotalDot * (activeSkill.skillFlags.DotCanStack and mirageCount or 1)
					end
					if activeSkill.mirage.output.CullMultiplier and activeSkill.mirage.output.CullMultiplier > 1 and activeSkill.mirage.output.CullMultiplier > fullDPS.cullingMulti then
						fullDPS.cullingMulti = activeSkill.mirage.output.CullMultiplier
					end
					if activeSkill.mirage.output.BurningGroundDPS and activeSkill.mirage.output.BurningGroundDPS > fullDPS.burningGroundDPS then
						fullDPS.burningGroundDPS = activeSkill.mirage.output.BurningGroundDPS
						burningGroundSource = activeSkill.activeEffect.grantedEffect.name .. " (Mirage)"
					end
					if activeSkill.mirage.output.CausticGroundDPS and activeSkill.mirage.output.CausticGroundDPS > fullDPS.causticGroundDPS then
						fullDPS.causticGroundDPS = activeSkill.mirage.output.CausticGroundDPS
						causticGroundSource = activeSkill.activeEffect.grantedEffect.name .. " (Mirage)"
					end
				end

				if usedEnv.player.output.TotalDPS and usedEnv.player.output.TotalDPS > 0 then
					t_insert(fullDPS.skills, { name = activeSkill.activeEffect.grantedEffect.name, dps = usedEnv.player.output.TotalDPS, count = activeSkillCount, trigger = activeSkill.infoTrigger, skillPart = minionName and activeSkill.infoMessage2 or activeSkill.skillPartName })
					fullDPS.combinedDPS = fullDPS.combinedDPS + usedEnv.player.output.TotalDPS * activeSkillCount
				end
				if usedEnv.player.output.BleedDPS and usedEnv.player.output.BleedDPS > fullDPS.bleedDPS then
					fullDPS.bleedDPS = usedEnv.player.output.BleedDPS
					bleedSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.CorruptingBloodDPS and usedEnv.player.output.CorruptingBloodDPS > fullDPS.corruptingBloodDPS then
					fullDPS.corruptingBloodDPS = usedEnv.player.output.CorruptingBloodDPS
					corruptingBloodSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.IgniteDPS and usedEnv.player.output.IgniteDPS > fullDPS.igniteDPS then
					fullDPS.igniteDPS = usedEnv.player.output.IgniteDPS
					igniteSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.BurningGroundDPS and usedEnv.player.output.BurningGroundDPS > fullDPS.burningGroundDPS then
					fullDPS.burningGroundDPS = usedEnv.player.output.BurningGroundDPS
					burningGroundSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.PoisonDPS and usedEnv.player.output.PoisonDPS > 0 then
					fullDPS.poisonDPS = fullDPS.poisonDPS + usedEnv.player.output.PoisonDPS * (usedEnv.player.output.TotalPoisonStacks or 1) * activeSkillCount
				end
				if usedEnv.player.output.CausticGroundDPS and usedEnv.player.output.CausticGroundDPS > fullDPS.causticGroundDPS then
					fullDPS.causticGroundDPS = usedEnv.player.output.CausticGroundDPS
					causticGroundSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.ImpaleDPS and usedEnv.player.output.ImpaleDPS > 0 then
					fullDPS.impaleDPS = fullDPS.impaleDPS + usedEnv.player.output.ImpaleDPS * activeSkillCount
				end
				if usedEnv.player.output.DecayDPS and usedEnv.player.output.DecayDPS > 0 then
					fullDPS.decayDPS = fullDPS.decayDPS + usedEnv.player.output.DecayDPS
				end
				if usedEnv.player.output.TotalDot and usedEnv.player.output.TotalDot > 0 then
					fullDPS.dotDPS = fullDPS.dotDPS + usedEnv.player.output.TotalDot * (activeSkill.skillFlags.DotCanStack and activeSkillCount or 1)
				end
				if usedEnv.player.output.CullMultiplier and usedEnv.player.output.CullMultiplier > 1 and usedEnv.player.output.CullMultiplier > fullDPS.cullingMulti then
					fullDPS.cullingMulti = usedEnv.player.output.CullMultiplier
				end

				-- Re-Build env calculator for new run
				local accelerationTbl = {
					nodeAlloc = true,
					requirementsItems = true,
					requirementsGems = true,
					skills = true,
					everything = true,
				}
				fullEnv, _, _, _ = calcs.initEnv(build, mode, override, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = fullEnv, accelerate = accelerationTbl })
			end
		end
	end

	-- Re-Add ailment DPS components
	fullDPS.TotalDotDPS = 0
	if fullDPS.bleedDPS > 0 then
		t_insert(fullDPS.skills, { name = "Best Bleed DPS", dps = fullDPS.bleedDPS, count = 1, source = bleedSource })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.bleedDPS
	end
	if fullDPS.corruptingBloodDPS > 0 then
		t_insert(fullDPS.skills, { name = "Corrupting Blood DPS", dps = fullDPS.corruptingBloodDPS, count = 1, source = corruptingBloodSource })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.corruptingBloodDPS
	end
	if fullDPS.igniteDPS > 0 then
		t_insert(fullDPS.skills, { name = "Best Ignite DPS", dps = fullDPS.igniteDPS, count = 1, source = igniteSource })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.igniteDPS
	end
	if fullDPS.burningGroundDPS > 0 then
		t_insert(fullDPS.skills, { name = "Best Burning Ground DPS", dps = fullDPS.burningGroundDPS, count = 1, source = burningGroundSource })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.burningGroundDPS
	end
	if fullDPS.poisonDPS > 0 then
		fullDPS.poisonDPS = m_min(fullDPS.poisonDPS, data.misc.DotDpsCap)
		t_insert(fullDPS.skills, { name = "Full Poison DPS", dps = fullDPS.poisonDPS, count = 1 })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.poisonDPS
	end
	if fullDPS.causticGroundDPS > 0 then
		t_insert(fullDPS.skills, { name = "Best Caustic Ground DPS", dps = fullDPS.causticGroundDPS, count = 1, source = causticGroundSource })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.causticGroundDPS
	end
	if fullDPS.impaleDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full Impale DPS", dps = fullDPS.impaleDPS, count = 1 })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.impaleDPS
	end
	if fullDPS.decayDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full Decay DPS", dps = fullDPS.decayDPS, count = 1 })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.decayDPS
	end
	if fullDPS.dotDPS > 0 then
		t_insert(fullDPS.skills, { name = "Full DoT DPS", dps = fullDPS.dotDPS, count = 1 })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.dotDPS
	end
	fullDPS.TotalDotDPS = m_min(fullDPS.TotalDotDPS, data.misc.DotDpsCap)
	fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.TotalDotDPS
	if fullDPS.cullingMulti > 0 then
		fullDPS.cullingDPS = fullDPS.combinedDPS * (fullDPS.cullingMulti - 1)
		t_insert(fullDPS.skills, { name = "Full Culling DPS", dps = fullDPS.cullingDPS, count = 1 })
		fullDPS.combinedDPS = fullDPS.combinedDPS + fullDPS.cullingDPS
	end

	return fullDPS
end

-- Process active skill
function calcs.buildActiveSkill(env, mode, skill, limitedProcessingFlags)
	local fullEnv, _, _, _ = calcs.initEnv(env.build, mode, env.override)
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if cacheSkillUUID(activeSkill, fullEnv) == cacheSkillUUID(skill, env) then
			fullEnv.player.mainSkill = activeSkill
			fullEnv.player.mainSkill.skillData.limitedProcessing = limitedProcessingFlags and limitedProcessingFlags[cacheSkillUUID(activeSkill, fullEnv)]
			calcs.perform(fullEnv, true)
			return
		end
	end
	ConPrintf("[calcs.buildActiveSkill] Failed to process skill: " .. skill.activeEffect.grantedEffect.name)
end

-- Build output for display in the side bar or calcs tab
function calcs.buildOutput(build, mode)
	-- Build output for selected main skill
	local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, mode)
	calcs.perform(env)

	local output = env.player.output

	-- Build output across all skills added to FullDPS skills
	local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", {}, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = nil })

	-- Add Full DPS data to main `env`
	env.player.output.SkillDPS = fullDPS.skills
	env.player.output.FullDPS = fullDPS.combinedDPS
	env.player.output.FullDotDPS = fullDPS.TotalDotDPS

	if mode == "MAIN" then
		for _, skill in ipairs(env.player.activeSkillList) do
			local uuid = cacheSkillUUID(skill, env)
			if not GlobalCache.cachedData[mode][uuid] then
				calcs.buildActiveSkill(env, mode, skill)
			end
			if GlobalCache.cachedData[mode][uuid] then
				output.EnergyShieldProtectsMana = env.modDB:Flag(nil, "EnergyShieldProtectsMana")
				for pool, costResource in pairs({["LifeUnreserved"] = "LifeCost", ["ManaUnreserved"] = "ManaCost", ["Rage"] = "RageCost", ["EnergyShield"] = "ESCost"}) do
					local cachedCost = GlobalCache.cachedData[mode][uuid].Env.player.output[costResource]
					if cachedCost then
						local totalPool = (output.EnergyShieldProtectsMana and costResource == "ManaCost" and output["EnergyShield"] or 0) + (output[pool] or 0)
						if totalPool < cachedCost then
							output[costResource.."Warning"] = output[costResource.."Warning"] or {}
							t_insert(output[costResource.."Warning"], skill.activeEffect.grantedEffect.name)
						end
					end
				end
				for pool, costResource in pairs({["LifeUnreservedPercent"] = "LifePercentCost", ["ManaUnreservedPercent"] = "ManaPercentCost"}) do
					local cachedCost = GlobalCache.cachedData[mode][uuid].Env.player.output[costResource]
					if cachedCost then
						if (output[pool] or 0) < cachedCost then
							output[costResource.."PercentCostWarning"] = output[costResource.."PercentCostWarning"] or {}
							t_insert(output[costResource.."PercentCostWarning"], skill.activeEffect.grantedEffect.name)
						end
					end
				end
			end
		end
	
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
		env.enemyConditionsUsed = { }
		env.minionConditionsUsed = { }
		env.multipliersUsed = { }
		env.enemyMultipliersUsed = { }
		env.perStatsUsed = { }
		env.enemyPerStatsUsed = { }
		env.tagTypesUsed = { }
		env.modsUsed = { }
		local function addTo(out, var, mod)
			-- Do not count Base mods as mods being actually used as they are only used as descriptors for mods
			if mod.source == "Base" then
				return
			end
			if not out[var] then
				out[var] = { }
			end
			t_insert(out[var], mod)
		end
		local function addVarTag(out, tag, mod)
			if tag.varList then
				for _, var in ipairs(tag.varList) do
					addTo(out, var, mod)
				end
			else
				addTo(out, tag.var, mod)
			end
		end
		local function addStatTag(out, tag, mod)
			if tag.varList then
				for _, var in ipairs(tag.statList) do
					addTo(out, var, mod)
				end
			elseif tag.stat then
				addTo(out, tag.stat, mod)
			end
		end
		local function addModTags(actor, mod)
			addTo(env.modsUsed, mod.name, mod)
			
			-- Imply enemy conditionals based on damage type
			-- Needed to preemptively show config options for elemental ailments
			for dmgType, conditions in pairs({["[fi][ig][rn][ei]t?e?"] = {"Ignited", "Burning"}, ["[cf][or][le][de]z?e?"] = {"Frozen"}}) do
				if mod.name:lower():match(dmgType) then
					for _, var in ipairs(conditions) do
						addTo(env.enemyConditionsUsed, var, mod)
					end
				end
			end
			
			for _, tag in ipairs(mod) do
				addTo(env.tagTypesUsed, tag.type, mod)
				if tag.type == "IgnoreCond" then
					break
				elseif tag.type == "Condition" then
					if actor == env.player then
						addVarTag(env.conditionsUsed, tag, mod)
					else
						addVarTag(env.minionConditionsUsed, tag, mod)
					end
				elseif tag.type == "ActorCondition" and tag.var then
					if tag.actor == "enemy" then
						addTo(env.enemyConditionsUsed, tag.var, mod)
					else
						addTo(env.conditionsUsed, tag.var, mod)
					end
				elseif tag.type == "Multiplier" or tag.type == "MultiplierThreshold" then
					if not tag.actor then
						if actor == env.player then
							addVarTag(env.multipliersUsed, tag, mod)
						end
					elseif tag.actor == "enemy" then
						addVarTag(env.enemyMultipliersUsed, tag, mod)
					end
				elseif tag.type == "PerStat" or tag.type == "StatThreshold" then
					if not tag.actor then
						if actor == env.player then
							addStatTag(env.perStatsUsed, tag, mod)
						end
					elseif tag.actor == "enemy" then
						addStatTag(env.enemyPerStatsUsed, tag, mod)
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
			for _, mod in ipairs(activeSkill.skillModList) do
				addTo(env.modsUsed, mod.name, mod)
				for _, tag in ipairs(mod) do
					addTo(env.tagTypesUsed, tag.type, mod)
				end
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
						addVarTag(env.enemyConditionsUsed, tag, mod)
					elseif tag.type == "ActorCondition" and tag.var then
						if tag.actor == "enemy" or tag.actor == "player" then
							addTo(env.conditionsUsed, tag.var, mod)
						else
							addTo(env.enemyConditionsUsed, tag.var, mod)
						end
					elseif tag.type == "Multiplier" or tag.type == "MultiplierThreshold" then
						if not tag.actor then
							addVarTag(env.enemyMultipliersUsed, tag, mod)
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
	elseif mode == "CALCS" then
		local buffList = { }
		local combatList = { }
		local curseList = { }
		if output.PowerCharges > 0 then
			t_insert(combatList, s_format("%d Power Charges", output.PowerCharges))
		end
		if output.AbsorptionCharges > 0 then
			t_insert(combatList, s_format("%d Absorption Charges", output.AbsorptionCharges))
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
		if build.calcsTab.mainEnv.multipliersUsed["InspirationCharge"] then
			t_insert(combatList, s_format("%d Inspiration Charges", output.InspirationCharges))
		end
		if output.GhostShrouds > 0 then
			t_insert(combatList, s_format("%d Ghost Shrouds", output.GhostShrouds))
		end
		if output.CrabBarriers > 0 then
			t_insert(combatList, s_format("%d Crab Barriers", output.CrabBarriers))
		end
		if build.calcsTab.mainEnv.multipliersUsed["BloodCharge"] then
			t_insert(combatList, s_format("%d Blood Charges", output.BloodCharges))
		end
		if build.calcsTab.mainEnv.multipliersUsed["SpiritCharge"] then
			t_insert(combatList, s_format("%d Spirit Charges", output.SpiritCharges))
		end
		if env.player.mainSkill.baseSkillModList:Flag(nil, "Cruelty") then
			t_insert(combatList, "Cruelty")
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
		if env.modDB:Flag(nil, "ChaoticMight") then
			t_insert(combatList, "Chaotic Might")
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
		if env.modDB:Flag(nil, "LesserMassiveShrine") then
			t_insert(combatList, "Lesser Massive Shrine")
		end
		if env.modDB:Flag(nil, "LesserBrutalShrine") then
			t_insert(combatList, "Lesser Brutal Shrine")
		end
		if env.modDB:Flag(nil, "DiamondShrine") then
			t_insert(combatList, "Diamond Shrine")
		end
		if env.modDB:Flag(nil, "MassiveShrine") then
			t_insert(combatList, "Massive Shrine")
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
			if env.minion.modDB:Flag(nil, "ChaoticMight") then
				t_insert(combatList, "Chaotic Might")
			end
			if env.minion.modDB:Flag(nil, "Tailwind") then
				t_insert(combatList, "Tailwind")
			end
			if env.minion.modDB:Flag(nil, "DiamondShrine") then
				t_insert(combatList, "Diamond Shrine")
			end
			if env.minion.modDB:Flag(nil, "MassiveShrine") then
				t_insert(combatList, "Massive Shrine")
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
