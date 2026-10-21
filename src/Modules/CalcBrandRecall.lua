-- Path of Building
-- Recalled skill variants and activation rates, excluding natural activations.
local calcs = require("Modules.CalcBase")

local recallCostResources = {
	{ key = "Mana", label = "mana" },
	{ key = "ManaPercent", label = "mana %", percent = true },
	{ key = "Life", label = "life" },
	{ key = "LifePercent", label = "life %", percent = true },
	{ key = "ES", label = "energy shield" },
	{ key = "Rage", label = "rage" },
}

function calcs.buildRecalledSkillParts(env, activeSkill)
	local effect = activeSkill.activeEffect.grantedEffect
	local group = activeSkill.socketGroup
	if not group or not group.brandRecallId or not activeSkill.activeEffect.srcInstance then
		return
	end
	local eligible = activeSkill.skillTypes[SkillType.Brand] and effect.name ~= "Arcanist Brand"
	for _, support in ipairs(activeSkill.effectList) do
		if support.grantedEffect.id == "SupportBrandSupport" then
			eligible = true
		end
	end
	if not eligible then
		return
	end
	local foundRecall = false
	for _, recallGroup in ipairs(env.build.skillsTab.socketGroupList) do
		-- Keep the variant available while a Recall setup is disabled, so disabling
		-- it yields zero recalled damage rather than silently selecting natural DPS.
		if recallGroup.brandRecallSourceId == group.brandRecallId then
			for _, gem in ipairs(recallGroup.gemList) do
				local grantedEffect = gem.grantedEffect or (gem.gemData and gem.gemData.grantedEffect)
				if grantedEffect and grantedEffect.id == "BrandRecall" then
					foundRecall = true
				end
			end
		end
	end
	if not foundRecall then
		return
	end
	local recalledParts = { }
	local baseParts = effect.parts or { { name = "Default" } }
	for index, basePart in ipairs(baseParts) do
		local part = copyTable(basePart)
		part.name = effect.parts and (part.name .. " (Recalled)") or "Recalled"
		part.originalPart = index
		part.recalled = true
		part.recalledBrand = activeSkill.skillTypes[SkillType.Brand]
		table.insert(recalledParts, part)
	end
	return recalledParts
end

function calcs.recalledSkillRate(env, activeSkill)
	if not activeSkill.skillFlags.recalled then
		return
	end
	local uuid = cacheSkillUUID(activeSkill, env)
	if env.limitedSkills and env.limitedSkills[uuid] then
		return
	end
	local brand = activeSkill
	if activeSkill.skillData.triggeredByBrand then
		for _, skill in ipairs(env.player.activeSkillList) do
			if skill.socketGroup == activeSkill.socketGroup and skill.activeEffect.grantedEffect.name == "Arcanist Brand" then
				brand = skill
				break
			end
		end
	end
	local count = brand.skillModList:Sum("BASE", brand.skillCfg, "ActiveBrandLimit")
	local configured = env.build.configTab.input.ActiveBrands
	if configured ~= nil then
		count = math.min(count, math.max(0, math.floor(configured)))
	end
	local output = env.player.output
	local breakdown = env.player.breakdown
	local brandOutput = output
	if brand ~= activeSkill then
		local brandUUID = cacheSkillUUID(brand, env)
		if not GlobalCache.cachedData[env.mode][brandUUID] or env.mode == "CALCULATOR" then
			calcs.buildActiveSkill(env, env.mode, brand, brandUUID, { uuid, brandUUID })
		end
		local cachedBrand = GlobalCache.cachedData[env.mode][brandUUID]
		brandOutput = cachedBrand and cachedBrand.Env.player.output or { }
	end
	local rotation = 1
	local triggers = 1
	local linkedSpells = { }
	if activeSkill.skillData.triggeredByBrand then
		triggers = env.player.modDB:Flag(nil, "HaveTriggerBots") and 2 or 1
		rotation = 0
		for _, skill in ipairs(env.player.activeSkillList) do
			if skill.socketGroup == activeSkill.socketGroup and skill.skillData.triggeredByBrand and not skill.skillFlags.disable then
				rotation = rotation + 1
				local spellOutput = output
				if skill ~= activeSkill then
					local spellUUID = cacheSkillUUID(skill, env)
					if not GlobalCache.cachedData[env.mode][spellUUID] or env.mode == "CALCULATOR" then
						calcs.buildActiveSkill(env, env.mode, skill, spellUUID, { uuid, spellUUID })
					end
					local cachedSpell = GlobalCache.cachedData[env.mode][spellUUID]
					spellOutput = cachedSpell and cachedSpell.Env.player.output or { }
				end
				table.insert(linkedSpells, spellOutput)
			end
		end
		rotation = math.max(rotation, 1)
	end
	local lines = { "Natural brand activations are excluded." }
	local recallRate = 0
	local recallCosts = { }
	local recallCostBreakdowns = { }
	if not brand.skillModList:Flag(brand.skillCfg, "Condition:CannotRecallBrand") then
		for _, recall in ipairs(env.player.activeSkillList) do
			if recall.skillData.brandRecallCostPercent and recall.socketGroup
				and recall.socketGroup.brandRecallSourceId == activeSkill.socketGroup.brandRecallId
				and recall.socketGroup.enabled and recall.socketGroup.slotEnabled ~= false and not recall.skillFlags.disable then
				local recallUUID = cacheSkillUUID(recall, env)
				if not (env.limitedSkills and env.limitedSkills[recallUUID]) then
					if not GlobalCache.cachedData[env.mode][recallUUID] or env.mode == "CALCULATOR" then
						calcs.buildActiveSkill(env, env.mode, recall, recallUUID, { uuid })
					end
					local cached = GlobalCache.cachedData[env.mode][recallUUID]
					if cached then
						local recallOutput = cached.Env.player.output
						local rate = recallOutput.Speed
						if not rate or rate <= 0 then
							rate = recallOutput.Cooldown and recallOutput.Cooldown > 0 and 1 / recallOutput.Cooldown or 0
						end
						recallRate = recallRate + rate
						local recallName = recall.socketGroup.label ~= "" and recall.socketGroup.label or recall.socketGroup.slot or "Brand Recall"
						table.insert(lines, string.format("+ %.3f ^8(Recall activations/s: %s)", rate, recallName))
						for _, resource in ipairs(recallCostResources) do
							local costName = resource.key.."Cost"
							local cost = recallOutput[costName] or 0
							local brandCost = brandOutput[costName] or 0
							local recalledBrandCost = brandCost * recall.skillData.brandRecallCostPercent / 100
							if not resource.percent then
								recalledBrandCost = math.floor(recalledBrandCost)
							end
							cost = cost + recalledBrandCost * count
							for _, spellOutput in ipairs(linkedSpells) do
								cost = cost + (spellOutput[costName] or 0) * triggers * count / #linkedSpells
							end
							if cost > 0 then
								local perSecond = cost * rate
								recallCosts[resource.key] = (recallCosts[resource.key] or 0) + perSecond
								recallCostBreakdowns[resource.key] = recallCostBreakdowns[resource.key] or { }
								table.insert(recallCostBreakdowns[resource.key], string.format("+ %g%s x %.3f = %.2f%s ^8(%s cost per use x trigger rate)", cost, resource.percent and "%%" or "", rate, perSecond, resource.percent and "%%" or "", recallName))
							end
						end
					end
				end
			end
		end
	end
	local rate = recallRate * count * triggers / rotation
	output.RecalledBrandCount = count
	output.BrandRecallRate = recallRate
	output.RecalledSkillRate = rate
	for _, resource in ipairs(recallCostResources) do
		local value = recallCosts[resource.key] or 0
		output["TotalRecall"..resource.key.."Cost"] = value
		if value > 0 then
			output["TotalRecall"..resource.key.."HasCost"] = true
			if breakdown then
				local costLines = recallCostBreakdowns[resource.key]
				table.insert(costLines, string.format("= %.2f%s ^8(total Recall %s cost per second)", value, resource.percent and "%%" or "", resource.label))
				breakdown["TotalRecall"..resource.key.."Cost"] = costLines
			end
		end
	end
	if breakdown then
		table.insert(lines, string.format("x %d ^8(active brands)", count))
		if activeSkill.skillData.triggeredByBrand then
			table.insert(lines, string.format("x %d ^8(linked spell triggers per activation)", triggers))
			table.insert(lines, string.format("/ %d ^8(linked spell rotation)", rotation))
		end
		table.insert(lines, string.format("= %.3f ^8(recalled activations per second)", rate))
		breakdown.RecalledSkillRate = lines
	end
	return rate
end
