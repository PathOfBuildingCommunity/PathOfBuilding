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
local m_max = math.max
local m_ceil = math.ceil
local MercenaryTools = require("Modules.MercenaryTools")
local ConfigScope = require("Modules.ConfigScope")

---@class Calcs
local calcs = require("Modules.CalcBase")
calcs.breakdownModule = "Modules.CalcBreakdown"
require("Modules.CalcSetup")
require("Modules.CalcPerform")
require("Modules.CalcActiveSkill")
require("Modules.CalcDefence")
require("Modules.CalcOffence")
require("Modules.CalcTriggers")
require("Modules.CalcMirages")

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

local function applyFullDPSOutput(env, fullDPS)
	env.player.output.SkillDPS = fullDPS.skills
	env.player.output.FullDPS = fullDPS.combinedDPS
	env.player.output.FullDotDPS = fullDPS.TotalDotDPS
	if env.mercenary then
		env.mercenary.output.SkillDPS = fullDPS.mercenarySkills
		env.mercenary.output.FullDPS = fullDPS.mercenaryDPS
		env.mercenary.output.FullDotDPS = fullDPS.mercenaryDotDPS
	end
end

---@class CalcOverride
---@field spec PassiveSpec?
---@field addNodes table<Node|number, boolean>? A set of passive nodes. Only keyed by node id for anointed nodes.
---@field removeNodes table<Node|number, boolean>? A set of passive nodes. Only keyed by node id for anointed nodes.
---@field repSlotName string? The name of the replaced item slot
---@field repItem Item?
---@field toggleFlask Item? Item object used as a table key.
---@field toggleTincture Item? Item object used as a table key.
---@field conditions string[]?
---@field extraJewelFuncs ModList?
---@field comparisonActor string?
---@field itemSetId integer?

-- Get calculator for other changes (adding/removing nodes, items, gems, etc)
---@param build Build
---@return fun(override?: CalcOverride, useFullDPS?: boolean): Output calcFunc
---@return Output output
---@return table baseOutputs
function calcs.getMiscCalculator(build)
	-- Run base calculation pass
	local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, "CALCULATOR")
	calcs.perform(env)
	local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", {}, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = nil})
	local usedFullDPS = #fullDPS.skills > 0
	if usedFullDPS then
		applyFullDPSOutput(env, fullDPS)
	end
	local function comparisonOutput(calculationEnv, override)
		if override and (override.comparisonActor == "MERCENARY" or MercenaryTools.baseItemSlotName(override.repSlotName)) then
			if calculationEnv.mercenary then
				return MercenaryTools.buildComparisonOutput(calculationEnv.mercenary.output, calculationEnv.player.output)
			end
			local message = "The selected mercenary is unavailable for this build."
			if calculationEnv.mercenaryCalculationErrors and calculationEnv.mercenaryCalculationErrors[1] then
				message = table.concat(calculationEnv.mercenaryCalculationErrors, "\n")
			end
			return { ActorUnavailableMessage = message }
		end
		return calculationEnv.player.output
	end
	local baseOutputs = {
		PLAYER = comparisonOutput(env),
		MERCENARY = comparisonOutput(env, { comparisonActor = "MERCENARY" }),
	}
	return function(override, useFullDPS)
		local env, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, "CALCULATOR", override)
		calcs.perform(env)
		if (useFullDPS ~= false or build.viewMode == "TREE") and usedFullDPS then
			-- prevent upcoming calculation from using Cached Data and thus forcing it to re-calculate new FullDPS roll-up 
			-- without this, FullDPS increase/decrease when for node/item/gem comparison would be all 0 as it would be comparing
			-- A with A (due to cache reuse) instead of A with B
			local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", override, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = nil})
			applyFullDPSOutput(env, fullDPS)
		end
		return comparisonOutput(env, override)
	end, baseOutputs.PLAYER, baseOutputs
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

local function countSkillDamageOnce(activeSkill, modDB)
	local skillName = activeSkill.activeEffect.grantedEffect.name
	return (skillName:match("Absolution") and modDB:Flag(false, "Condition:AbsolutionSkillDamageCountedOnce"))
		or (skillName:match("Dominating Blow") and modDB:Flag(false, "Condition:DominatingBlowSkillDamageCountedOnce"))
		or (skillName:match("Holy Strike") and modDB:Flag(false, "Condition:HolyStrikeSkillDamageCountedOnce"))
end

-- Generic skill DoT for Full DPS. Non-stacking DoTs of the same identity
-- keep the strongest instance; stackable DoTs sum, multiplied by count.
function calcs.genericDotIdentity(grantedEffect)
	local identity = grantedEffect and (grantedEffect.inheritedFrom or grantedEffect.id)
	if not identity then
		error("Full DPS generic DoT is missing an identity")
	end
	return identity
end

function calcs.genericDotContribution(output, skillFlags, count)
	if not (output.TotalDot and output.TotalDot > 0) then
		return 0
	end
	return output.TotalDot * (skillFlags.DotCanStack and count or 1)
end

function calcs.contributeGenericDot(totals, identity, output, skillFlags, count)
	local contribution = calcs.genericDotContribution(output, skillFlags, count)
	if contribution <= 0 then
		return
	end
	if skillFlags.DotCanStack then
		totals[identity] = (totals[identity] or 0) + contribution
	elseif contribution > (totals[identity] or 0) then
		totals[identity] = contribution
	end
end

-- Minion actors carry their own mainSkill. Full DPS must key generic DoT from
-- that skill, not from the summoning skill that created the actor.
function calcs.contributeSkillGenericDot(totals, skill, output, count)
	if not (output and output.TotalDot and output.TotalDot > 0) then
		return
	end
	if not (skill and skill.activeEffect and skill.activeEffect.grantedEffect) then
		error("Full DPS generic DoT is missing a skill identity")
	end
	calcs.contributeGenericDot(totals, calcs.genericDotIdentity(skill.activeEffect.grantedEffect), output, skill.skillFlags or { }, count)
end

function calcs.sumDotTotals(totals)
	local sum = 0
	for _, value in pairs(totals) do
		sum = sum + value
	end
	return sum
end

function calcs.calcFullDPS(build, mode, override, specEnv)
	local fullDPS = {
		combinedDPS = 0,
		TotalDotDPS = 0,
		skills = { },
		mercenarySkills = { },
		mercenaryDPS = 0,
		mercenaryDotDPS = 0,
		TotalPoisonDPS = 0,
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
	local hasFullDPSSkill = false
	for _, socketGroup in ipairs(build.skillsTab.socketGroupList) do
		if socketGroup.includeInFullDPS then hasFullDPSSkill = true break end
	end
	if not hasFullDPSSkill then
		local mercenarySkills = build.mercenaryTab and build.mercenaryTab.profile and build.mercenaryTab.profile.skills
		for _, selected in ipairs(mercenarySkills or { }) do
			if selected.enabled ~= false and selected.includeInFullDPS then hasFullDPSSkill = true break end
		end
	end
	if not hasFullDPSSkill then return fullDPS end

	local fullEnv, cachedPlayerDB, cachedEnemyDB, cachedMinionDB = calcs.initEnv(build, mode, override, specEnv)
	local usedEnv = nil

	local bleedSource = ""
	local corruptingBloodSource = ""
	local igniteSource = ""
	local burningGroundSource = ""
	local causticGroundSource = ""
	local decaySource = ""
	local genericDots = { }
	local remainingPlayerFullDPS = 0
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if activeSkill.socketGroup and activeSkill.socketGroup.includeInFullDPS then
			local _, enabled = getActiveSkillCount(activeSkill)
			if enabled then
				remainingPlayerFullDPS = remainingPlayerFullDPS + 1
			end
		end
	end
	local mercenaryFullDPSSkills = { }
	for _, activeSkill in ipairs(fullEnv.mercenary and fullEnv.mercenary.activeSkillList or { }) do
		if activeSkill.isMercenaryPrimary and activeSkill.mercenarySkill and activeSkill.mercenarySkill.includeInFullDPS then
			t_insert(mercenaryFullDPSSkills, activeSkill.mercenarySkill)
		end
	end
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		if activeSkill.socketGroup and activeSkill.socketGroup.includeInFullDPS then
			local activeSkillCount, enabled = getActiveSkillCount(activeSkill)
			if enabled then
				fullEnv.player.mainSkill = activeSkill
				calcs.perform(fullEnv, true)
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
						fullDPS.TotalPoisonDPS = fullDPS.TotalPoisonDPS + usedEnv.minion.output.TotalPoisonDPS * activeSkillCount
					end
					if usedEnv.minion.output.ImpaleDPS and usedEnv.minion.output.ImpaleDPS > 0 then
						fullDPS.impaleDPS = fullDPS.impaleDPS + usedEnv.minion.output.ImpaleDPS * activeSkillCount
					end
					if usedEnv.minion.output.DecayDPS and usedEnv.minion.output.DecayDPS > fullDPS.decayDPS then
						fullDPS.decayDPS = usedEnv.minion.output.DecayDPS
						decaySource = activeSkill.activeEffect.grantedEffect.name
					end
					calcs.contributeSkillGenericDot(genericDots, usedEnv.minion.mainSkill, usedEnv.minion.output, activeSkillCount)
					if usedEnv.minion.output.CullMultiplier and usedEnv.minion.output.CullMultiplier > 1 and usedEnv.minion.output.CullMultiplier > fullDPS.cullingMulti then
						fullDPS.cullingMulti = usedEnv.minion.output.CullMultiplier
					end
					-- This is a fix to prevent skills such as Absolution or Dominating Blow from being counted multiple times when increasing minions count
					if countSkillDamageOnce(activeSkill, fullEnv.modDB) then
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
						fullDPS.TotalPoisonDPS = fullDPS.TotalPoisonDPS + activeSkill.mirage.output.TotalPoisonDPS * mirageCount
					end
					if activeSkill.mirage.output.ImpaleDPS and activeSkill.mirage.output.ImpaleDPS > 0 then
						fullDPS.impaleDPS = fullDPS.impaleDPS + activeSkill.mirage.output.ImpaleDPS * mirageCount
					end
					if activeSkill.mirage.output.DecayDPS and activeSkill.mirage.output.DecayDPS > fullDPS.decayDPS then
						fullDPS.decayDPS = activeSkill.mirage.output.DecayDPS
						decaySource = activeSkill.activeEffect.grantedEffect.name .. " (Mirage)"
					end
					calcs.contributeSkillGenericDot(genericDots, activeSkill, activeSkill.mirage.output, mirageCount)
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
					fullDPS.TotalPoisonDPS = fullDPS.TotalPoisonDPS + usedEnv.player.output.TotalPoisonDPS * activeSkillCount
				end
				if usedEnv.player.output.CausticGroundDPS and usedEnv.player.output.CausticGroundDPS > fullDPS.causticGroundDPS then
					fullDPS.causticGroundDPS = usedEnv.player.output.CausticGroundDPS
					causticGroundSource = activeSkill.activeEffect.grantedEffect.name
				end
				if usedEnv.player.output.ImpaleDPS and usedEnv.player.output.ImpaleDPS > 0 then
					fullDPS.impaleDPS = fullDPS.impaleDPS + usedEnv.player.output.ImpaleDPS * activeSkillCount
				end
				if usedEnv.player.output.DecayDPS and usedEnv.player.output.DecayDPS > fullDPS.decayDPS then
					fullDPS.decayDPS = usedEnv.player.output.DecayDPS
					decaySource = activeSkill.activeEffect.grantedEffect.name
				end
				calcs.contributeSkillGenericDot(genericDots, activeSkill, usedEnv.player.output, activeSkillCount)
				if usedEnv.player.output.CullMultiplier and usedEnv.player.output.CullMultiplier > 1 and usedEnv.player.output.CullMultiplier > fullDPS.cullingMulti then
					fullDPS.cullingMulti = usedEnv.player.output.CullMultiplier
				end

				remainingPlayerFullDPS = remainingPlayerFullDPS - 1
				-- Rebuild after the last player skill too when a Mercenary Full DPS
				-- loop follows, so that loop does not inherit the last perform().
				if remainingPlayerFullDPS > 0 or #mercenaryFullDPSSkills > 0 then
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
	end

	local mercenaryGenericDots, mercenaryTotals
	if fullEnv.mercenary then
	mercenaryGenericDots = { }
	mercenaryTotals = {
		direct = 0, poison = 0, impale = 0, decay = 0, dot = 0,
		bleed = 0, corruptingBlood = 0, ignite = 0, burningGround = 0, causticGround = 0, culling = 0,
		bleedSource = "", corruptingBloodSource = "", igniteSource = "", burningGroundSource = "", causticGroundSource = "", decaySource = "",
	}
	local function updateMercenaryMaximum(stat, value, source)
		if value > mercenaryTotals[stat] then
			mercenaryTotals[stat] = value
			mercenaryTotals[stat.."Source"] = source
		end
	end
	for selectedIndex, selected in ipairs(mercenaryFullDPSSkills) do
		local activeSkill
		for _, candidate in ipairs(fullEnv.mercenary and fullEnv.mercenary.activeSkillList or { }) do
			if candidate.mercenarySkill and candidate.mercenarySkill.id == selected.id then activeSkill = candidate break end
		end
		if activeSkill then
			fullEnv.mercenary.mainSkill = activeSkill
			calcs.perform(fullEnv, true)
			usedEnv = fullEnv
			local count = selected.count or 1
			local directCount = count
			if activeSkill.minion and countSkillDamageOnce(activeSkill, fullEnv.mercenary.modDB) then
				directCount = 1
				activeSkill.infoMessage2 = "Skill Damage"
			end
			local actorOutputs = { {
				output = usedEnv.mercenary.output,
				name = activeSkill.activeEffect.grantedEffect.name,
				source = "Mercenary",
				count = directCount,
				skill = activeSkill,
				skillPart = activeSkill.minion and activeSkill.infoMessage2 or activeSkill.skillPartName,
			} }
			if activeSkill.minion and usedEnv.mercenaryMinion then
				t_insert(actorOutputs, 1, {
					output = usedEnv.mercenaryMinion.output,
					name = usedEnv.mercenaryMinion.minionData.name..": "..activeSkill.activeEffect.grantedEffect.name,
					source = "Mercenary Minion",
					count = count,
					skill = usedEnv.mercenaryMinion.mainSkill,
					skillPart = activeSkill.skillPartName,
				})
			end
			if activeSkill.mirage then
				t_insert(actorOutputs, {
					output = activeSkill.mirage.output,
					name = activeSkill.mirage.name.." (Mirage)",
					source = "Mercenary Mirage",
					count = (activeSkill.mirage.count or 1) * directCount,
					skill = activeSkill,
					skillPart = activeSkill.mirage.skillPartName,
				})
			end
			for _, actorData in ipairs(actorOutputs) do
				local actorOutput = actorData.output or { }
				local sourceName = actorData.name
				local actorCount = actorData.count
				if actorOutput.TotalDPS and actorOutput.TotalDPS > 0 then
					local skillDPS = {
						name = sourceName,
						dps = actorOutput.TotalDPS,
						count = actorCount,
						source = actorData.source,
						skillPart = actorData.skillPart,
					}
					t_insert(fullDPS.skills, skillDPS)
					t_insert(fullDPS.mercenarySkills, skillDPS)
					local direct = actorOutput.TotalDPS * actorCount
					fullDPS.combinedDPS = fullDPS.combinedDPS + direct
					mercenaryTotals.direct = mercenaryTotals.direct + direct
				end
				if actorOutput.BleedDPS and actorOutput.BleedDPS > fullDPS.bleedDPS then
					fullDPS.bleedDPS, bleedSource = actorOutput.BleedDPS, sourceName
				end
				updateMercenaryMaximum("bleed", actorOutput.BleedDPS or 0, sourceName)
				if actorOutput.CorruptingBloodDPS and actorOutput.CorruptingBloodDPS > fullDPS.corruptingBloodDPS then
					fullDPS.corruptingBloodDPS, corruptingBloodSource = actorOutput.CorruptingBloodDPS, sourceName
				end
				updateMercenaryMaximum("corruptingBlood", actorOutput.CorruptingBloodDPS or 0, sourceName)
				if actorOutput.IgniteDPS and actorOutput.IgniteDPS > fullDPS.igniteDPS then
					fullDPS.igniteDPS, igniteSource = actorOutput.IgniteDPS, sourceName
				end
				updateMercenaryMaximum("ignite", actorOutput.IgniteDPS or 0, sourceName)
				if actorOutput.BurningGroundDPS and actorOutput.BurningGroundDPS > fullDPS.burningGroundDPS then
					fullDPS.burningGroundDPS, burningGroundSource = actorOutput.BurningGroundDPS, sourceName
				end
				updateMercenaryMaximum("burningGround", actorOutput.BurningGroundDPS or 0, sourceName)
				if actorOutput.CausticGroundDPS and actorOutput.CausticGroundDPS > fullDPS.causticGroundDPS then
					fullDPS.causticGroundDPS, causticGroundSource = actorOutput.CausticGroundDPS, sourceName
				end
				updateMercenaryMaximum("causticGround", actorOutput.CausticGroundDPS or 0, sourceName)
				if actorOutput.PoisonDPS and actorOutput.PoisonDPS > 0 then
					local poison = actorOutput.TotalPoisonDPS * actorCount
					fullDPS.TotalPoisonDPS = fullDPS.TotalPoisonDPS + poison
					mercenaryTotals.poison = mercenaryTotals.poison + poison
				end
				if actorOutput.ImpaleDPS and actorOutput.ImpaleDPS > 0 then
					local impale = actorOutput.ImpaleDPS * actorCount
					fullDPS.impaleDPS = fullDPS.impaleDPS + impale
					mercenaryTotals.impale = mercenaryTotals.impale + impale
				end
				if actorOutput.DecayDPS and actorOutput.DecayDPS > fullDPS.decayDPS then
					fullDPS.decayDPS, decaySource = actorOutput.DecayDPS, sourceName
				end
				updateMercenaryMaximum("decay", actorOutput.DecayDPS or 0, sourceName)
				calcs.contributeSkillGenericDot(genericDots, actorData.skill, actorOutput, actorCount)
				calcs.contributeSkillGenericDot(mercenaryGenericDots, actorData.skill, actorOutput, actorCount)
				if actorOutput.CullMultiplier and actorOutput.CullMultiplier > fullDPS.cullingMulti then
					fullDPS.cullingMulti = actorOutput.CullMultiplier
				end
				mercenaryTotals.culling = m_max(mercenaryTotals.culling, actorOutput.CullMultiplier or 0)
			end

			if selectedIndex < #mercenaryFullDPSSkills then
				local accelerationTbl = { nodeAlloc = true, requirementsItems = true, requirementsGems = true, skills = true, everything = true }
				fullEnv, _, _, _ = calcs.initEnv(build, mode, override, { cachedPlayerDB = cachedPlayerDB, cachedEnemyDB = cachedEnemyDB, cachedMinionDB = cachedMinionDB, env = fullEnv, accelerate = accelerationTbl })
			end
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
	if fullDPS.TotalPoisonDPS > 0 then
		fullDPS.TotalPoisonDPS = m_min(fullDPS.TotalPoisonDPS, data.misc.DotDpsCap)
		t_insert(fullDPS.skills, { name = "Full Poison DPS", dps = fullDPS.TotalPoisonDPS, count = 1 })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.TotalPoisonDPS
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
		t_insert(fullDPS.skills, { name = "Best Decay DPS", dps = fullDPS.decayDPS, count = 1, source = decaySource })
		fullDPS.TotalDotDPS = fullDPS.TotalDotDPS + fullDPS.decayDPS
	end
	fullDPS.dotDPS = calcs.sumDotTotals(genericDots)
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
	if mercenaryTotals then
	mercenaryTotals.dot = calcs.sumDotTotals(mercenaryGenericDots)
	local function addMercenaryDPS(name, dps, source)
		if dps > 0 then
			t_insert(fullDPS.mercenarySkills, { name = name, dps = dps, count = 1, source = source })
		end
	end
	local mercenaryPoison = m_min(mercenaryTotals.poison, data.misc.DotDpsCap)
	addMercenaryDPS("Best Bleed DPS", mercenaryTotals.bleed, mercenaryTotals.bleedSource)
	addMercenaryDPS("Corrupting Blood DPS", mercenaryTotals.corruptingBlood, mercenaryTotals.corruptingBloodSource)
	addMercenaryDPS("Best Ignite DPS", mercenaryTotals.ignite, mercenaryTotals.igniteSource)
	addMercenaryDPS("Best Burning Ground DPS", mercenaryTotals.burningGround, mercenaryTotals.burningGroundSource)
	addMercenaryDPS("Full Poison DPS", mercenaryPoison)
	addMercenaryDPS("Best Caustic Ground DPS", mercenaryTotals.causticGround, mercenaryTotals.causticGroundSource)
	addMercenaryDPS("Full Impale DPS", mercenaryTotals.impale)
	addMercenaryDPS("Best Decay DPS", mercenaryTotals.decay, mercenaryTotals.decaySource)
	addMercenaryDPS("Full DoT DPS", mercenaryTotals.dot)
	fullDPS.mercenaryDotDPS = m_min(mercenaryTotals.bleed + mercenaryTotals.corruptingBlood + mercenaryTotals.ignite
		+ mercenaryTotals.burningGround + mercenaryTotals.causticGround + mercenaryPoison + mercenaryTotals.decay + mercenaryTotals.dot, data.misc.DotDpsCap)
	fullDPS.mercenaryDPS = mercenaryTotals.direct + mercenaryTotals.impale + fullDPS.mercenaryDotDPS
	if mercenaryTotals.culling > 1 then
		local cullingDPS = fullDPS.mercenaryDPS * (mercenaryTotals.culling - 1)
		addMercenaryDPS("Full Culling DPS", cullingDPS)
		fullDPS.mercenaryDPS = fullDPS.mercenaryDPS + cullingDPS
	end
	end

	return fullDPS
end

-- Process active skill
function calcs.buildActiveSkill(env, mode, skill, targetUUID, limitedProcessingFlags)
	local fullEnv, _, _, _ = calcs.initEnv(env.build, mode, env.override)
	fullEnv.buildBreakdown = false

	-- env.limitedSkills contains a map of uuids that should be limited in calculation
	-- this is in order to prevent infinite recursion loops
	fullEnv.limitedSkills = fullEnv.limitedSkills or {}
	for uuid, _ in pairs(env.limitedSkills or {}) do
		fullEnv.limitedSkills[uuid] = true
	end
	for _, uuid in ipairs(limitedProcessingFlags or {}) do
		fullEnv.limitedSkills[uuid] = true
	end

	targetUUID = targetUUID or cacheSkillUUID(skill, env)
	for _, activeSkill in ipairs(fullEnv.player.activeSkillList) do
		local activeSkillUUID = cacheSkillUUID(activeSkill, fullEnv)
		if activeSkillUUID == targetUUID then
			fullEnv.player.mainSkill = activeSkill
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
	applyFullDPSOutput(env, fullDPS)

	if mode == "MAIN" then
		for _, skill in ipairs(env.player.activeSkillList) do
			local uuid = cacheSkillUUID(skill, env)
			if not GlobalCache.cachedData[mode][uuid] then
				calcs.buildActiveSkill(env, mode, skill, uuid)
			end
			if GlobalCache.cachedData[mode][uuid] then
				output.EnergyShieldProtectsMana = env.modDB:Flag(nil, "EnergyShieldProtectsMana")
				for pool, costResource in pairs({["LifeUnreserved"] = "LifeCost", ["ManaUnreserved"] = "ManaCost", ["Rage"] = "RageCost", ["EnergyShield"] = "ESCost"}) do
					local cachedCost = GlobalCache.cachedData[mode][uuid].Env.player.output[costResource]
					if cachedCost then
						local totalPool = (output.EnergyShieldProtectsMana and costResource == "ManaCost" and output["EnergyShield"] or 0) + (output[pool] or 0)
						if totalPool < cachedCost then
							local rawPool = pool:gsub("Unreserved$", "")
							local reservation = GlobalCache.cachedData[mode][uuid].Env.player.mainSkill and GlobalCache.cachedData[mode][uuid].Env.player.mainSkill.skillData[rawPool .. "ReservedPercent"]
							-- Skill has both cost and reservation check if there's available pool for raw cost before reservation
							if not reservation or (reservation and (totalPool + m_ceil((output[rawPool] or 0) * reservation / 100)) < cachedCost) then
								if env.player.mainSkill and env.player.mainSkill.activeEffect.grantedEffect.name == skill.activeEffect.grantedEffect.name then
									output[costResource.."Warning"] = true
								end
								output[costResource.."WarningList"] = output[costResource.."WarningList"] or {}
								t_insert(output[costResource.."WarningList"], skill.activeEffect.grantedEffect.name)
							end
						end
					end
				end
				for pool, costResource in pairs({["LifeUnreservedPercent"] = "LifePercentCost", ["ManaUnreservedPercent"] = "ManaPercentCost"}) do
					local cachedCost = GlobalCache.cachedData[mode][uuid].Env.player.output[costResource]
					if cachedCost then
						if (output[pool] or 0) < cachedCost then
							output[costResource.."PercentCostWarningList"] = output[costResource.."PercentCostWarningList"] or {}
							t_insert(output[costResource.."PercentCostWarningList"], skill.activeEffect.grantedEffect.name)
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
		local function recordActorSkills(actor)
			for _, activeSkill in ipairs(actor and actor.activeSkillList or { }) do
				for _, skillEffect in ipairs(activeSkill.effectList) do
					env.skillsUsed[skillEffect.grantedEffect.name] = true
				end
				if activeSkill.minion then
					for _, minionSkill in ipairs(activeSkill.minion.activeSkillList) do
						env.skillsUsed[minionSkill.activeEffect.grantedEffect.id] = true
					end
				end
			end
		end
		local primaryActorKeys = { "player", "mercenary" }
		for _, actorKey in ipairs(primaryActorKeys) do recordActorSkills(env[actorKey]) end

		env.conditionsUsed = { }
		env.enemyConditionsUsed = { }
		env.minionConditionsUsed = { }
		env.multipliersUsed = { }
		env.enemyMultipliersUsed = { }
		env.perStatsUsed = { }
		env.enemyPerStatsUsed = { }
		env.tagTypesUsed = { }
		env.modsUsed = { }
		env.actorUsage = {
			player = { conditions = { }, multipliers = { }, mods = { }, perStats = { }, minionConditions = { }, enemyConditions = { }, enemyMultipliers = { }, enemyPerStats = { } },
		}
		if env.mercenary then
			env.actorUsage.mercenary = { conditions = { }, multipliers = { }, mods = { }, perStats = { }, minionConditions = { }, enemyConditions = { }, enemyMultipliers = { }, enemyPerStats = { } }
		end
		local function actorUsageFor(actor)
			if actor == env.mercenary then
				return env.actorUsage.mercenary
			end
			if actor == env.player then
				return env.actorUsage.player
			end
		end
		local function ownerUsageForMinion(actor)
			if actor == env.minion or (actor and actor.parent == env.player) then
				return env.actorUsage.player
			end
			if actor == env.mercenaryMinion or (actor and actor.parent == env.mercenary) then
				return env.actorUsage.mercenary
			end
		end
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
			local usage = actorUsageFor(actor)
			if usage then
				addTo(usage.mods, mod.name, mod)
			end
			
			-- Imply enemy conditionals based on damage type
			-- Needed to preemptively show config options for elemental ailments
			for dmgType, conditions in pairs({["[fi][ig][rn][ei]t?e?"] = {"Ignited", "Burning"}, ["[cf][or][le][de]z?e?"] = {"Frozen"}}) do
				if mod.name:lower():match(dmgType) then
					for _, var in ipairs(conditions) do
						addTo(env.enemyConditionsUsed, var, mod)
					end
				end
			end
			if ConfigScope.impliesChilledByYourHits(mod.name) then
				addTo(env.enemyConditionsUsed, "ChilledByYourHits", mod)
				if usage then
					addTo(usage.enemyConditions, "ChilledByYourHits", mod)
				end
			end
			
			for _, tag in ipairs(mod) do
				addTo(env.tagTypesUsed, tag.type, mod)
				if tag.type == "IgnoreCond" then
					break
				elseif tag.type == "Condition" then
					if actor == env.player or actor == env.mercenary then
						addVarTag(env.conditionsUsed, tag, mod)
						if usage then
							addVarTag(usage.conditions, tag, mod)
						end
					else
						addVarTag(env.minionConditionsUsed, tag, mod)
						local ownerUsage = ownerUsageForMinion(actor)
						if ownerUsage then
							addVarTag(ownerUsage.minionConditions, tag, mod)
						end
					end
				elseif tag.type == "ActorCondition" and tag.var then
					if tag.actor == "enemy" then
						addTo(env.enemyConditionsUsed, tag.var, mod)
						if usage then
							addTo(usage.enemyConditions, tag.var, mod)
						end
					else
						addTo(env.conditionsUsed, tag.var, mod)
						if usage then
							addTo(usage.conditions, tag.var, mod)
						end
					end
				elseif tag.type == "Multiplier" or tag.type == "MultiplierThreshold" then
					if not tag.actor then
						if actor == env.player or actor == env.mercenary then
							addVarTag(env.multipliersUsed, tag, mod)
							if usage then
								addVarTag(usage.multipliers, tag, mod)
							end
						end
					elseif tag.actor == "enemy" then
						addVarTag(env.enemyMultipliersUsed, tag, mod)
						if usage then
							addVarTag(usage.enemyMultipliers, tag, mod)
						end
					end
				elseif tag.type == "PerStat" or tag.type == "StatThreshold" then
					if not tag.actor then
						if actor == env.player or actor == env.mercenary then
							addStatTag(env.perStatsUsed, tag, mod)
							if usage then
								addStatTag(usage.perStats, tag, mod)
							end
						end
					elseif tag.actor == "enemy" then
						addStatTag(env.enemyPerStatsUsed, tag, mod)
						if usage then
							addStatTag(usage.enemyPerStats, tag, mod)
						end
					end
				end
			end
			if mod.name == "EnemyModifier" and mod.value and mod.value.mod then
				for _, innerTag in ipairs(mod.value.mod) do
					if innerTag.type == "IgnoreCond" then
						break
					elseif innerTag.type == "Condition" then
						addVarTag(env.enemyConditionsUsed, innerTag, mod.value.mod)
						if usage then
							addVarTag(usage.enemyConditions, innerTag, mod.value.mod)
						end
					elseif innerTag.type == "Multiplier" or innerTag.type == "MultiplierThreshold" then
						if not innerTag.actor then
							addVarTag(env.enemyMultipliersUsed, innerTag, mod.value.mod)
							if usage then
								addVarTag(usage.enemyMultipliers, innerTag, mod.value.mod)
							end
						end
					end
				end
			end
		end
		for _, actorKey in ipairs({ "player", "mercenary", "minion", "mercenaryMinion" }) do
			local actor = env[actorKey]
			if actor then
				for modName, modList in pairs(actor.modDB.mods) do
					for _, mod in ipairs(modList) do
						addModTags(actor, mod)
					end
				end
			end
		end
		for _, actorKey in ipairs(primaryActorKeys) do
			local actor = env[actorKey]
			for _, activeSkill in pairs(actor and actor.activeSkillList or { }) do
				for _, mod in ipairs(activeSkill.baseSkillModList) do
					addModTags(actor, mod)
				end
				for _, mod in ipairs(activeSkill.skillModList) do
					addTo(env.modsUsed, mod.name, mod)
					local usage = actorUsageFor(actor)
					if usage then
						addTo(usage.mods, mod.name, mod)
					end
					for _, tag in ipairs(mod) do
						addTo(env.tagTypesUsed, tag.type, mod)
					end
				end
				if activeSkill.minion then
					for _, minionSkill in pairs(activeSkill.minion.activeSkillList) do
						for _, mod in ipairs(minionSkill.baseSkillModList) do
							addModTags(activeSkill.minion, mod)
						end
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
		if output.BrineCharges > 0 then
			t_insert(combatList, s_format("%d Brine Charges", output.BrineCharges))
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
		if build.calcsTab.mainEnv.multipliersUsed["SpiritInfusion"] then
			t_insert(combatList, s_format("%d Spirit Infusions", output.SpiritInfusions))
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
		if env.modDB:Flag(nil, "AccelerationShrine") then
			t_insert(combatList, "Acceleration Shrine")
		end
		if env.modDB:Flag(nil, "BrutalShrine") then
			t_insert(combatList, "Brutal Shrine")
		end
		if env.modDB:Flag(nil, "DiamondShrine") then
			t_insert(combatList, "Diamond Shrine")
		end
		if env.modDB:Flag(nil, "DivineShrine") then
			t_insert(combatList, "Divine Shrine")
		end
		if env.modDB:Flag(nil, "EchoingShrine") then
			t_insert(combatList, "Echoing Shrine")
		end
		if env.modDB:Flag(nil, "GloomShrine") then
			t_insert(combatList, "Gloom Shrine")
		end
		if env.modDB:Flag(nil, "GreaterFreezingShrine") then
			t_insert(combatList, "Greater Freezing Shrine")
		end
		if env.modDB:Flag(nil, "GreaterShockingShrine") then
			t_insert(combatList, "Greater Shocking Shrine")
		end
		if env.modDB:Flag(nil, "GreaterSkeletalShrine") then
			t_insert(combatList, "Greater Skeletal Shrine")
		end
		if env.modDB:Flag(nil, "ImpenetrableShrine") then
			t_insert(combatList, "Impenetrable Shrine")
		end
		if env.modDB:Flag(nil, "MassiveShrine") then
			t_insert(combatList, "Massive Shrine")
		end
		if env.modDB:Flag(nil, "ReplenishingShrine") then
			t_insert(combatList, "Replenishing Shrine")
		end
		if env.modDB:Flag(nil, "ResistanceShrine") then
			t_insert(combatList, "Resistance Shrine")
		end
		if env.modDB:Flag(nil, "ResonatingShrine") then
			t_insert(combatList, "Resonating Shrine")
		end
		if env.modDB:Flag(nil, "LesserAccelerationShrine") then
			t_insert(combatList, "Lesser Acceleration Shrine")
		end
		if env.modDB:Flag(nil, "LesserBrutalShrine") then
			t_insert(combatList, "Lesser Brutal Shrine")
		end
		if env.modDB:Flag(nil, "LesserImpenetrableShrine") then
			t_insert(combatList, "Lesser Impenetrable Shrine")
		end
		if env.modDB:Flag(nil, "LesserMassiveShrine") then
			t_insert(combatList, "Lesser Massive Shrine")
		end
		if env.modDB:Flag(nil, "LesserReplenishingShrine") then
			t_insert(combatList, "Lesser Replenishing Shrine")
		end
		if env.modDB:Flag(nil, "LesserResistanceShrine") then
			t_insert(combatList, "Lesser Resistance Shrine")
		end
		if env.modDB:Flag(nil, "BloodShrineOfRats") then
			t_insert(combatList, "Blood Shrine of Rats")
		end
		if env.modDB:Flag(nil, "BloodShrineOfLocusts") then
			t_insert(combatList, "Blood Shrine of Locusts")
		end
		if env.modDB:Flag(nil, "BloodShrineOfToads") then
			t_insert(combatList, "Blood Shrine of Toads")
		end
		if env.modDB:Flag(nil, "BloodShrineOfCrows") then
			t_insert(combatList, "Blood Shrine of Crows")
		end
		if env.modDB:Flag(nil, "BloodShrineOfBats") then
			t_insert(combatList, "Blood Shrine of Bats")
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
