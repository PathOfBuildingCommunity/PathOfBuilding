local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort
local t_concat = table.concat
local m_floor = math.floor
local m_min = math.min
local m_max = math.max

local MercenaryTools = { }

MercenaryTools.equipmentSlots = { "Weapon 1", "Weapon 2", "Helmet", "Body Armour", "Gloves", "Boots", "Amulet", "Ring 1", "Ring 2", "Belt" }

function MercenaryTools.baseItemSlotName(slotName)
	return type(slotName) == "string" and slotName:match("^Mercenary (.+)$") or nil
end

function MercenaryTools.overrideReplacesMercenarySlot(override, slotName, mercenaryItemSetId)
	if not override or not override.repSlotName then
		return false
	end
	local overrideBase = MercenaryTools.baseItemSlotName(override.repSlotName) or override.repSlotName
	if overrideBase ~= slotName then
		return false
	end
	if override.comparisonActor == "PLAYER" then
		return false
	end
	if override.comparisonActor == "MERCENARY" or MercenaryTools.baseItemSlotName(override.repSlotName) then
		return true
	end
	return override.itemSetId ~= nil and override.itemSetId == mercenaryItemSetId
end

-- Effective item in a slot after replacement, removal, and parent sockets.
-- Does not mutate the saved item set.
function MercenaryTools.equippedItem(itemSet, items, slotName, override, mercenaryItemSetId)
	if MercenaryTools.overrideReplacesMercenarySlot(override, slotName, mercenaryItemSetId) then
		return override.repItem
	end
	local parentSlot, abyssalIndex = slotName:match("^(.-) Abyssal Socket (%d+)$")
	if parentSlot then
		local parentItem = MercenaryTools.equippedItem(itemSet, items, parentSlot, override, mercenaryItemSetId)
		if not parentItem or (parentItem.abyssalSocketCount or 0) < tonumber(abyssalIndex) then
			return nil
		end
	end
	local setSlot = itemSet and itemSet[slotName]
	return items and items[setSlot and setSlot.selItemId]
end

local function withRestored(restore, fn)
	local ok, result = pcall(fn)
	restore()
	if not ok then
		error(result)
	end
	return result
end

function MercenaryTools.withMainSkill(profile, skillId, fn)
	local previous = profile.mainSkillId
	profile.mainSkillId = skillId
	return withRestored(function()
		profile.mainSkillId = previous
	end, fn)
end

function MercenaryTools.withReplacedSkill(profile, index, replacement, fn)
	local original = profile.skills[index]
	profile.skills[index] = replacement
	return withRestored(function()
		profile.skills[index] = original
	end, fn)
end

function MercenaryTools.overrideReplacesPlayerItem(override, activeItemSetId)
	if not override then
		return true
	end
	if override.comparisonActor == "MERCENARY" or MercenaryTools.baseItemSlotName(override.repSlotName) then
		return false
	end
	return override.itemSetId == nil or override.itemSetId == activeItemSetId
end

-- Mercenary Life/ES/selected-skill DPS stay on the mercenary output.
-- Full DPS is a build-wide rollup (player skills + mercenary skills), so
-- support auras that only buff the player must use the player's Full DPS
-- or item tooltips and trade weights score them as zero.
function MercenaryTools.buildComparisonOutput(mercenaryOutput, playerOutput)
	if not MercenaryTools.mercenaryOutputAvailable(mercenaryOutput) or not playerOutput then
		return mercenaryOutput
	end
	local output = { }
	for key, value in pairs(mercenaryOutput) do
		output[key] = value
	end
	output.FullDPS = playerOutput.FullDPS
	output.FullDotDPS = playerOutput.FullDotDPS
	return output
end

function MercenaryTools.comparisonBaseOutput(playerOutput, actorOutputs, comparisonActor)
	if comparisonActor == "MERCENARY" then
		return MercenaryTools.buildComparisonOutput(actorOutputs and actorOutputs.MERCENARY, playerOutput)
	end
	return playerOutput
end

function MercenaryTools.mercenaryOutputAvailable(output)
	return output ~= nil and not output.ActorUnavailableMessage
end

-- Hire is a Scion/Luminary mechanic. Every Scion sees the tab so a Mercenary
-- can be configured before Noble Blood is allocated.
function MercenaryTools.tabVisible(build)
	return build and build.spec and build.spec.curClassName == "Scion"
end

function MercenaryTools.isMercenaryCalculationActor(actorId)
	return actorId == "MERCENARY" or actorId == "MERCENARY_MINION"
end

function MercenaryTools.configActorList(build)
	if MercenaryTools.tabVisible(build) then
		return {
			{ id = "player", label = "Player" },
			{ id = "mercenary", label = "Mercenary" },
		}
	end
	return {
		{ id = "player", label = "Player" },
	}
end

-- Always copies. DropDownControl:SetList wipes the control's previous list, so the
-- source table must never be installed as a dropdown's current list.
function MercenaryTools.filterCalculationActors(actors, build)
	local list = { }
	for _, actor in ipairs(actors) do
		if MercenaryTools.tabVisible(build) or not MercenaryTools.isMercenaryCalculationActor(actor.actorId) then
			t_insert(list, actor)
		end
	end
	return list
end

function MercenaryTools.hasProfile(build)
	return build.mercenaryTab ~= nil and build.mercenaryTab.profile ~= nil and build.mercenaryTab.profile.buildId ~= nil
end

-- Overlay isolation is only valid while a Mercenary actor is in the graph.
-- A configured-but-unhired profile must keep origin's shared enemy HitBy* writes.
function MercenaryTools.playerCanHire(build)
	for _, node in pairs(build and build.spec and build.spec.allocNodes or { }) do
		for _, mod in ipairs(node.modList or { }) do
			if mod.name == "CanHirePermanentMercenary" then
				return true
			end
		end
	end
	return false
end

function MercenaryTools.isHired(build)
	return MercenaryTools.hasProfile(build) and MercenaryTools.playerCanHire(build)
end

function MercenaryTools.firstEnabledSkillId(profile)
	for _, skill in ipairs(profile and profile.skills or { }) do
		if skill.enabled ~= false then
			return skill.id
		end
	end
end

function MercenaryTools.includeInBuildWarnings(build)
	if not MercenaryTools.tabVisible(build) then
		return false
	end
	if build.viewMode == "MERCENARY" then
		return true
	end
	return MercenaryTools.hasProfile(build)
end

function MercenaryTools.applyHiddenState(build)
	if MercenaryTools.tabVisible(build) then
		return
	end
	if build.viewMode == "MERCENARY" then
		build.viewMode = "TREE"
	end
	if build.calcsTab and MercenaryTools.isMercenaryCalculationActor(build.calcsTab.input.actor) then
		build.calcsTab.input.actor = "PLAYER"
	end
	if build.configTab and build.configTab:GetViewActor() == "mercenary" then
		build.configTab.viewActor = "player"
	end
	if build.itemsTab and build.itemsTab.viewComparisonActor == "MERCENARY" then
		build.itemsTab:SetViewItemSet(build.itemsTab.activeItemSetId, "PLAYER")
	end
end

local MAX_WARRANT_BYTES = 256 * 1024
local MAX_SKILLS = 6

local function contains(values, wanted)
	return values ~= nil and isValueInArray(values, wanted) ~= nil
end

function MercenaryTools.classGroups(mercenaryData)
	local groups = { }
	local groupsByClassId = { }
	local groupsByLabel = { }
	for _, classId in ipairs(mercenaryData.classOrder or { }) do
		local class = mercenaryData.classes[classId]
		local name = class.name:gsub("^%[DNT%]%s*", "")
		name = name:gsub("^Merc ", ""):gsub(" Merc ", " "):gsub("%s+%d+$", "")
		local label = name.." ("..class.attributeName..")"
		local group = groupsByLabel[label]
		if not group then
			group = { id = label, label = label, classIds = { }, buildIds = { } }
			groupsByLabel[label] = group
			t_insert(groups, group)
		end
		t_insert(group.classIds, classId)
		groupsByClassId[classId] = group
		for _, buildId in ipairs(class.buildIds or { }) do
			t_insert(group.buildIds, buildId)
		end
	end
	return groups, groupsByClassId
end

-- How many supports a skill accepts, and the largest limit any skill accepts. Both
-- come from the hand-authored `supportCounts` policy attached to the Mercenary data.
-- A missing policy record is nil, not 0: 0 is a valid gameplay capacity.
function MercenaryTools.supportLimit(mercenaryData, skill)
	if not skill then
		return nil
	end
	local count = mercenaryData and mercenaryData.supportCounts and mercenaryData.supportCounts[skill.supportCountId]
	if not count then
		return nil
	end
	return count.maximum
end

function MercenaryTools.missingSupportPolicyError(skill)
	if not skill then
		return nil
	end
	return "Missing support-count policy for "..tostring(skill.supportCountId).." on skill "..tostring(skill.id)
end

function MercenaryTools.skillCandidateError(profile, mercenaryData, index, skillId)
	if not skillId then
		return nil
	end
	local build = profile and mercenaryData and mercenaryData.builds[profile.buildId]
	if not build then
		return "Select a Mercenary class and build"
	end
	local skill = mercenaryData.skills[skillId]
	if not skill or not contains(build.skillIds, skillId) then
		return "Invalid skill for selected build: "..tostring(skillId)
	end
	local skills = profile.skills or { }
	local replacing = skills[index] ~= nil
	if not replacing and #skills >= MAX_SKILLS then
		return "A Mercenary cannot have more than 6 inherent skills"
	end
	for skillIndex, selected in ipairs(skills) do
		if skillIndex ~= index and selected.id == skillId then
			return "Duplicate skill: "..skillId
		end
	end
	local poolCounts = { }
	for skillIndex, selected in ipairs(skills) do
		local id = skillIndex == index and skillId or selected.id
		for poolIndex, pool in ipairs(build.skillPools or { }) do
			if contains(pool.skillIds, id) then
				poolCounts[poolIndex] = (poolCounts[poolIndex] or 0) + 1
				break
			end
		end
	end
	if not replacing then
		for poolIndex, pool in ipairs(build.skillPools or { }) do
			if contains(pool.skillIds, skillId) then
				poolCounts[poolIndex] = (poolCounts[poolIndex] or 0) + 1
				break
			end
		end
	end
	for poolIndex, pool in ipairs(build.skillPools or { }) do
		if pool.countMax and (poolCounts[poolIndex] or 0) > pool.countMax then
			return "Skill pool "..poolIndex.." allows at most "..pool.countMax.." skills"
		end
	end
end

function MercenaryTools.firstLegalSkillId(profile, mercenaryData)
	local build = profile and mercenaryData and mercenaryData.builds[profile.buildId]
	if not build then
		return nil
	end
	local index = #(profile.skills or { }) + 1
	for _, skillId in ipairs(build.skillIds) do
		if not MercenaryTools.skillCandidateError(profile, mercenaryData, index, skillId) then
			return skillId
		end
	end
end

-- Dense support-list edit used by committed selection and DPS-sort previews.
-- Writing by raw index creates holes that ipairs ignores during calculation.
function MercenaryTools.setSkillSupport(supports, index, support)
	if support then
		supports[m_min(index, #supports + 1)] = support
	elseif supports[index] then
		t_remove(supports, index)
	end
end

function MercenaryTools.withEditedSupports(skill, index, support, fn)
	local original = skill.supports
	skill.supports = copyTable(original or { }, true)
	MercenaryTools.setSkillSupport(skill.supports, index, support)
	return withRestored(function()
		skill.supports = original
	end, fn)
end

function MercenaryTools.supportCandidateError(profile, mercenaryData, skillIndex, supportIndex, supportId)
	if not supportId then
		return nil
	end
	local selected = profile and profile.skills and profile.skills[skillIndex]
	if not selected then
		return "No selected Mercenary skill"
	end
	local skill = mercenaryData.skills[selected.id]
	local maxSupports = MercenaryTools.supportLimit(mercenaryData, skill)
	if maxSupports == nil then
		return MercenaryTools.missingSupportPolicyError(skill) or "Missing support-count policy"
	end
	if supportIndex > maxSupports then
		return "Skill "..tostring(selected.id).." allows at most "..maxSupports.." supports"
	end
	local supports = selected.supports or { }
	if not supports[supportIndex] and #supports >= maxSupports then
		return "Skill "..tostring(selected.id).." has more than "..maxSupports.." supports"
	end
	local support = mercenaryData.supports[supportId]
	if not support or not skill or not contains(skill.possibleSupportIds, supportId) then
		return "Invalid support for skill "..tostring(selected.id)..": "..tostring(supportId)
	end
	for index, selectedSupport in ipairs(supports) do
		if index ~= supportIndex then
			if selectedSupport.id == supportId then
				return "Duplicate support "..supportId.." on skill "..tostring(selected.id)
			end
			local existing = mercenaryData.supports[selectedSupport.id]
			if support.familyId and existing and existing.familyId == support.familyId then
				return "Duplicate support family "..support.familyId.." on skill "..tostring(selected.id)
			end
		end
	end
end

function MercenaryTools.maxSupportLimit(mercenaryData)
	local maximum = 0
	for _, count in pairs(mercenaryData.supportCounts) do
		maximum = m_max(maximum, count.maximum)
	end
	return maximum
end
local supportLimit = MercenaryTools.supportLimit

function MercenaryTools.skillLevel(grantedEffect, actorLevel)
	local bestLevel, bestRequirement = 1, -1
	for level, levelData in pairs(grantedEffect and grantedEffect.levels or { }) do
		local requirement = levelData.levelRequirement or 1
		if type(level) == "number" and requirement <= actorLevel and (requirement > bestRequirement or requirement == bestRequirement and level > bestLevel) then
			bestLevel, bestRequirement = level, requirement
		end
	end
	return bestLevel
end

local function listProducesSkillData(mods, key)
	for _, modOrGroup in ipairs(mods or { }) do
		for _, mod in ipairs(modOrGroup.name and { modOrGroup } or modOrGroup) do
			if mod.name == "SkillData" and type(mod.value) == "table" and mod.value.key == key then
				return true
			end
		end
	end
	return false
end

local function producesSkillData(grantedEffect, key)
	if listProducesSkillData(grantedEffect.baseMods, key) then
		return true
	end
	local function statProduces(statId)
		local map = grantedEffect.statMap[statId]
		return map ~= nil and listProducesSkillData(map, key)
	end
	for _, statId in ipairs(grantedEffect.stats or { }) do
		if statProduces(statId) then return true end
	end
	for _, stat in ipairs(grantedEffect.constantStats or { }) do
		if statProduces(stat[1]) then return true end
	end
	-- Quality stats are deliberately not consulted: a Mercenary skill is not a gem and
	-- always has quality 0, so anything only a quality stat produces stays nil.
	return false
end

-- Which declared inputs of the base skill's `preDamageFunc` this Mercenary skill cannot
-- populate from its own stats, or nil when the base declares no inputs at all.
function MercenaryTools.missingPreDamageFuncInputs(grantedEffect, baseSkillId, mercenaryStatData)
	local declared = mercenaryStatData.preDamageFuncInputs[baseSkillId]
	if not declared then
		return nil
	end
	local missing = { }
	for _, key in ipairs(declared) do
		if not producesSkillData(grantedEffect, key) then t_insert(missing, key) end
	end
	return missing
end

-- Report every declared input of an inherited `preDamageFunc` that the Mercenary
-- skill's own stats cannot populate. Without this the function reads nil, which
-- either errors or reports the missing damage component as zero.
-- A Mercenary skill that overrides `preDamageFunc` itself is not checked, because that
-- function was written against the stats the Mercenary version actually has.
function MercenaryTools.preDamageFuncErrors(grantedEffect, baseEffect, mercenaryStatData)
	if not grantedEffect.preDamageFunc or not grantedEffect.inheritedFrom
	  or grantedEffect.preDamageFunc ~= (baseEffect and baseEffect.preDamageFunc) then
		return nil
	end
	local missing = MercenaryTools.missingPreDamageFuncInputs(grantedEffect, grantedEffect.inheritedFrom, mercenaryStatData)
	if not missing then
		return { "Undeclared preDamageFunc inputs for "..grantedEffect.inheritedFrom.." (inherited by "..grantedEffect.id..")" }
	end
	local errors
	for _, key in ipairs(missing) do
		errors = errors or { }
		t_insert(errors, "Mercenary skill "..grantedEffect.id.." has no stat for "..key..", required by the "..grantedEffect.inheritedFrom.." preDamageFunc")
	end
	return errors
end

-- A Mercenary is as strong as the area it was found in, and levels up with the areas
-- it is taken to, but stops gaining levels past the level of the highest-level
-- non-endgame area (GGG patch notes: "up to a maximum of level 68"). Found-area
-- level itself is not limited by that ceiling: map Mercenaries keep their high
-- found-area level, but monster damage/armour/evasion tables only exist for 1-100.
local MERCENARY_AREA_SCALING_CAP = 68
local MERCENARY_LEVEL_MAX = 100
-- A Mercenary can equip an item requiring up to this fraction more than the level
-- of the area it was found in.
local FOUND_AREA_LEVEL_REQUIREMENT_RATIO = 0.7

function MercenaryTools.effectiveLevel(foundAreaLevel, currentAreaLevel)
	local found = m_max(1, m_min(tonumber(foundAreaLevel) or 1, MERCENARY_LEVEL_MAX))
	local current = m_max(1, m_min(tonumber(currentAreaLevel) or 1, MERCENARY_AREA_SCALING_CAP))
	return m_max(found, current)
end

function MercenaryTools.requiredFoundAreaLevel(requiredLevel)
	return math.ceil((tonumber(requiredLevel) or 0) * FOUND_AREA_LEVEL_REQUIREMENT_RATIO)
end

-- MercenaryBuildExtraStats exports the three values but not their tier boundaries.
-- Keep the validated runtime tier policy here until those boundaries are exposed.
-- Values are truncated because passive mods are integer values.
MercenaryTools.PASSIVE_STAT_LEVELS = { 24, 68, 84 }

-- Noble Blood's PassiveSkills row exports only the maximum MORE penalty.
-- 3.29.1 tapers that penalty in; those breakpoints are not a DAT table.
-- Patch notes: no penalty before level 45, maximum at level 83.
-- Round-to-nearest integer MORE so the cap is reached at 83, not 82.
MercenaryTools.PERMANENT_DAMAGE_MORE_START_LEVEL = 45
MercenaryTools.PERMANENT_DAMAGE_MORE_END_LEVEL = 83

function MercenaryTools.permanentDamageMore(level, maxMore)
	maxMore = tonumber(maxMore)
	if maxMore == nil then
		error("permanent Mercenary damage max is required")
	end
	local startLevel = MercenaryTools.PERMANENT_DAMAGE_MORE_START_LEVEL
	local endLevel = MercenaryTools.PERMANENT_DAMAGE_MORE_END_LEVEL
	local actorLevel = m_max(1, tonumber(level) or 1)
	if actorLevel <= startLevel then
		return 0
	end
	if actorLevel >= endLevel then
		return maxMore
	end
	return m_floor(maxMore * (actorLevel - startLevel) / (endLevel - startLevel) + 0.5)
end

function MercenaryTools.passiveStatValue(values, level)
	local levels = MercenaryTools.PASSIVE_STAT_LEVELS
	local clampedLevel = m_max(levels[1], m_min(tonumber(level) or levels[1], levels[3]))
	local first, second, third = tonumber(values and values[1]) or 0, tonumber(values and values[2]) or 0, tonumber(values and values[3]) or 0
	if clampedLevel <= levels[2] then
		return m_floor(first + (second - first) * (clampedLevel - levels[1]) / (levels[2] - levels[1]))
	end
	return m_floor(second + (third - second) * (clampedLevel - levels[2]) / (levels[3] - levels[2]))
end

local function splitWarrantBlocks(text)
	local blocks, block = { }, { }
	for line in (text.."\n"):gmatch("(.-)\n") do
		line = line:match("^%s*(.-)%s*$")
		if line:match("^%-+$") then
			if #block > 0 then t_insert(blocks, block) end
			block = { }
		elseif line ~= "" then
			t_insert(block, line)
		end
	end
	if #block > 0 then t_insert(blocks, block) end
	return blocks
end

local function namedRecords(records, ids, name)
	local matches = { }
	if ids then
		for _, id in ipairs(ids) do
			local record = records[id]
			if record and record.name == name then t_insert(matches, id) end
		end
	else
		for id, record in pairs(records or { }) do
			if record.name == name then t_insert(matches, id) end
		end
		t_sort(matches)
	end
	return matches
end

function MercenaryTools.importWarrant(text, mercenaryData)
	if type(text) ~= "string" or text:match("^%s*$") then
		return nil, "Paste a Mercenary Warrant item text"
	elseif #text > MAX_WARRANT_BYTES then
		return nil, "Mercenary Warrant text exceeds 256 KiB"
	elseif not mercenaryData or not mercenaryData.builds or not mercenaryData.skills or not mercenaryData.supports then
		return nil, "Mercenary data is unavailable"
	end

	text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
	local blocks = splitWarrantBlocks(text)
	local hasWarrant, buildName, foundAreaLevel = false, nil, nil
	for _, block in ipairs(blocks) do
		for _, line in ipairs(block) do
			hasWarrant = hasWarrant or line == "Mercenary Warrant"
			local value = line:match("^Build:%s*(.-)%s*$")
			if value then
				buildName = value
			end
			value = line:match("^Mercenary Level:%s*(%d+)%s*$")
			if value then
				foundAreaLevel = tonumber(value)
			end
		end
	end
	if not hasWarrant then return nil, "Text is not a Mercenary Warrant" end
	if not buildName then return nil, "Mercenary Warrant is missing its Build line" end
	if not foundAreaLevel then return nil, "Mercenary Warrant is missing its Mercenary Level line" end
	if foundAreaLevel < 1 or foundAreaLevel > 100 then
		return nil, "Mercenary Level must be an integer between 1 and 100"
	end

	local buildIds = namedRecords(mercenaryData.builds, mercenaryData.buildOrder, buildName)
	if #buildIds == 0 then
		return nil, "Unknown Mercenary build: "..buildName
	elseif #buildIds > 1 then
		return nil, "Ambiguous Mercenary build: "..buildName
	end
	local build = mercenaryData.builds[buildIds[1]]
	local importedSkills, startedSkills = { }, false
	local sawBuildLine, sawLevelLine = false, false
	for _, block in ipairs(blocks) do
		local firstLine = block[1]
		if firstLine and firstLine:match("^Right click this item") then break end

		local hasMetadataLine = false
		for _, line in ipairs(block) do
			if line:match("^Build:") then
				sawBuildLine = true
				hasMetadataLine = true
			end
			if line:match("^Mercenary Level:") then
				sawLevelLine = true
				hasMetadataLine = true
			end
		end
		local metadataReady = sawBuildLine and sawLevelLine
		if metadataReady and not hasMetadataLine then
			local skillIds = namedRecords(mercenaryData.skills, build.skillIds, firstLine)
			if #skillIds == 0 then
				return nil, "Unknown Mercenary skill for "..buildName..": "..tostring(firstLine)
			elseif #skillIds > 1 then
				return nil, "Ambiguous Mercenary skill for "..buildName..": "..firstLine
			elseif #importedSkills >= MAX_SKILLS then
				return nil, "A Mercenary Warrant cannot contain more than 6 skills"
			end

			local skillId = skillIds[1]
			local skill = mercenaryData.skills[skillId]
			local importedSkill = {
				id = skillId,
				enabled = true,
				includeInFullDPS = false,
				count = 1,
				supports = { },
			}
			local seenSupports, seenFamilies = { }, { }
			for lineIndex = 2, #block do
				local supportName, tierText = block[lineIndex]:match("^(.+)%s+%(%s*Tier:%s*(%d+)%s*%)$")
				if not supportName then
					return nil, "Invalid support line for "..skill.name..": "..block[lineIndex]
				end
				local tier = tonumber(tierText)
				local supportIds = { }
				for _, supportId in ipairs(skill.possibleSupportIds or { }) do
					local support = mercenaryData.supports[supportId]
					if support and support.name == supportName and support.variant == tier then
						t_insert(supportIds, supportId)
					end
				end
				if #supportIds == 0 then
					return nil, "Support "..supportName.." (Tier: "..tier..") is not valid for "..skill.name
				elseif #supportIds > 1 then
					return nil, "Ambiguous support "..supportName.." (Tier: "..tier..") for "..skill.name
				end
				local supportId = supportIds[1]
				local support = mercenaryData.supports[supportId]
				if seenSupports[supportId] then
					return nil, "Duplicate support "..supportName.." on "..skill.name
				elseif support.familyId and seenFamilies[support.familyId] then
					return nil, "Duplicate support family "..support.familyId.." on "..skill.name
				end
				seenSupports[supportId] = true
				if support.familyId then seenFamilies[support.familyId] = true end
				t_insert(importedSkill.supports, { id = supportId, tier = tier })
			end
			t_insert(importedSkills, importedSkill)
			startedSkills = true
		elseif startedSkills and firstLine then
			return nil, "Unexpected text after Mercenary skills: "..firstLine
		end
	end
	if #importedSkills == 0 then return nil, "Mercenary Warrant contains no recognized skills" end

	local profile = {
		classId = build.classId,
		buildId = build.id,
		foundAreaLevel = foundAreaLevel,
		importedWarrant = true,
		mainSkillId = importedSkills[1].id,
		skills = importedSkills,
	}
	local errors = MercenaryTools.validateProfile(profile, mercenaryData)
	if #errors > 0 then return nil, t_concat(errors, "; ") end
	return profile
end

function MercenaryTools.validateProfile(profile, mercenaryData)
	local errors = { }
	local build = profile and mercenaryData and mercenaryData.builds[profile.buildId]
	if not build then
		t_insert(errors, "Select a Mercenary class and build")
		return errors
	end
	local foundAreaLevel = tonumber(profile.foundAreaLevel)
	if not foundAreaLevel or foundAreaLevel % 1 ~= 0 or foundAreaLevel < 1 or foundAreaLevel > 100 then
		t_insert(errors, "Mercenary level must be an integer between 1 and 100")
	end
	if #(profile.skills or { }) > MAX_SKILLS then
		t_insert(errors, "A Mercenary cannot have more than 6 inherent skills")
	end
	local seenSkills, enabledSkillsById = { }, { }
	local poolCounts = { }
	local enabledSkills = 0
	for _, selected in ipairs(profile.skills or { }) do
		if selected.count ~= nil and (type(selected.count) ~= "number" or selected.count % 1 ~= 0 or selected.count < 1 or selected.count > 99) then
			t_insert(errors, "Full DPS count for "..tostring(selected.id).." must be an integer from 1 to 99")
		end
		if selected.enabled ~= false and selected.id then
			enabledSkills = enabledSkills + 1
			enabledSkillsById[selected.id] = true
		end
		local skill = mercenaryData.skills[selected.id]
		if not skill or not contains(build.skillIds, selected.id) then
			t_insert(errors, "Invalid skill for selected build: "..tostring(selected.id))
		elseif seenSkills[selected.id] then
			t_insert(errors, "Duplicate skill: "..selected.id)
		else
			seenSkills[selected.id] = true
		end
		for poolIndex, pool in ipairs(build.skillPools or { }) do
			if contains(pool.skillIds, selected.id) then
				poolCounts[poolIndex] = (poolCounts[poolIndex] or 0) + 1
				break
			end
		end
		if skill then
			local maxSupports = supportLimit(mercenaryData, skill)
			if maxSupports == nil then
				t_insert(errors, MercenaryTools.missingSupportPolicyError(skill))
			elseif #(selected.supports or { }) > maxSupports then
				t_insert(errors, "Skill "..tostring(selected.id).." has more than "..maxSupports.." supports")
			end
		end
		local seenSupports, seenFamilies = { }, { }
		for _, selectedSupport in ipairs(selected.supports or { }) do
			local supportId = selectedSupport and selectedSupport.id
			local support = mercenaryData.supports[supportId]
			if not support or not skill or not contains(skill.possibleSupportIds, supportId) then
				t_insert(errors, "Invalid support for skill "..tostring(selected.id)..": "..tostring(supportId))
			elseif selectedSupport.tier ~= support.variant then
				t_insert(errors, "Invalid tier for support "..selectedSupport.id)
			elseif seenSupports[supportId] then
				t_insert(errors, "Duplicate support "..selectedSupport.id.." on skill "..tostring(selected.id))
			elseif support.familyId and seenFamilies[support.familyId] then
				t_insert(errors, "Duplicate support family "..support.familyId.." on skill "..tostring(selected.id))
			end
			if supportId then seenSupports[supportId] = true end
			if support and support.familyId then seenFamilies[support.familyId] = true end
		end
	end
	-- Warrant text contains the authoritative complete roster. The exported pool
	-- maximums describe spawn selection, so they do not constrain an imported Warrant.
	if not profile.importedWarrant then
		for poolIndex, pool in ipairs(build.skillPools or { }) do
			if pool.countMax and (poolCounts[poolIndex] or 0) > pool.countMax then
				t_insert(errors, "Skill pool "..poolIndex.." allows at most "..pool.countMax.." skills")
			end
		end
	end
	if #(profile.skills or { }) == 0 then
		t_insert(errors, "Select at least one Mercenary skill")
	elseif enabledSkills == 0 then
		t_insert(errors, "Enable at least one Mercenary skill")
	elseif not profile.mainSkillId then
		t_insert(errors, "Select a Mercenary skill for Calcs")
	elseif not seenSkills[profile.mainSkillId] then
		t_insert(errors, "Selected Calcs skill is not configured")
	elseif not enabledSkillsById[profile.mainSkillId] then
		t_insert(errors, "Selected Calcs skill is disabled")
	end
	return errors
end

local ARMOUR_SLOTS = {
	Helmet = true,
	["Body Armour"] = true,
	Gloves = true,
	Boots = true,
}
-- Unique equipment is only permitted where something has granted the matching
-- "Your Mercenary can equip Unique ..." flag. Body Armour has no such flag.
-- Re-evaluate when GGG adds a Unique Body Armour permission modifier.
local UNIQUE_FLAG_BY_SLOT = {
	["Weapon 1"] = "MercenaryCanEquipUniqueArms",
	["Weapon 2"] = "MercenaryCanEquipUniqueArms",
	Helmet = "MercenaryCanEquipUniqueHelmets",
	Gloves = "MercenaryCanEquipUniqueGloves",
	Boots = "MercenaryCanEquipUniqueBoots",
	Amulet = "MercenaryCanEquipUniqueAmulets",
	["Ring 1"] = "MercenaryCanEquipUniqueRings",
	["Ring 2"] = "MercenaryCanEquipUniqueRings",
	Belt = "MercenaryCanEquipUniqueBelts",
}
local UNIQUE_SLOT_DESCRIPTION = {
	MercenaryCanEquipUniqueArms = "Unique Weapons, Shields and Quivers",
	MercenaryCanEquipUniqueHelmets = "Unique Helmets",
	MercenaryCanEquipUniqueGloves = "Unique Gloves",
	MercenaryCanEquipUniqueBoots = "Unique Boots",
	MercenaryCanEquipUniqueAmulets = "Unique Amulets",
	MercenaryCanEquipUniqueRings = "Unique Rings",
	MercenaryCanEquipUniqueBelts = "Unique Belts",
}

function MercenaryTools.isSlotSupported(slotName)
	local parentSlot = slotName:match("^(.-) Abyssal Socket %d+$")
	return contains(MercenaryTools.equipmentSlots, parentSlot or slotName)
end

-- Same PoB object, or the same PoE API uniqueID when that persistent identity exists.
function MercenaryTools.samePhysicalItem(item, other)
	if not item or not other then
		return false
	end
	if item.id and other.id and item.id == other.id then
		return true
	end
	return item.uniqueID ~= nil and item.uniqueID ~= "" and item.uniqueID == other.uniqueID
end

function MercenaryTools.playerEquipsPhysicalItem(item, playerItemSet, items)
	if not item or not playerItemSet then
		return false
	end
	for _, playerSlot in pairs(playerItemSet) do
		if type(playerSlot) == "table" and playerSlot.selItemId and playerSlot.selItemId ~= 0 then
			if playerSlot.selItemId == item.id then
				return true
			end
			if MercenaryTools.samePhysicalItem(item, items and items[playerSlot.selItemId]) then
				return true
			end
		end
	end
	return false
end

function MercenaryTools.validateEquippedItem(item, slotName, context)
	if not MercenaryTools.isSlotSupported(slotName) then
		return false, "slot is not supported by Mercenaries"
	end
	local parentSlot, abyssalSocketIndex = slotName:match("^(.-) Abyssal Socket (%d+)$")
	if parentSlot then
		local parentItem = MercenaryTools.equippedItem(context.itemSet, context.items, parentSlot, context.override, context.mercenaryItemSetId)
		if not parentItem or (parentItem.abyssalSocketCount or 0) < tonumber(abyssalSocketIndex) then
			return false, "parent item does not have this Abyssal Socket"
		end
	end
	local mercenaryData = context.mercenaryData
	local profile = context.profile
	local mercBuild = mercenaryData.builds[profile.buildId]
	local class = mercBuild and mercenaryData.classes[mercBuild.classId]
	if not mercBuild or not class then
		return false, "select a Mercenary build first"
	end
	local isArmourEquipment = ARMOUR_SLOTS[slotName] or item.type == "Shield"
	if isArmourEquipment then
		if not class.attributeId or class.attributeId == "" then
			return false, "Selected Mercenary class is missing attribute data"
		end
		local itemRequirements = item.requirements or { }
		local attributes = class.attributeId
		local attributeCount, requiredAttributeCount, hasAssociatedRequirement = 0, 0, false
		for _, attribute in ipairs({ "Str", "Dex", "Int" }) do
			if attributes:find(attribute, 1, true) then attributeCount = attributeCount + 1 end
		end
		for _, requirement in ipairs({ { "Str", "str" }, { "Dex", "dex" }, { "Int", "int" } }) do
			local required = (itemRequirements[requirement[2]] or 0) > 0
			local associated = attributes:find(requirement[1], 1, true) ~= nil
			if required then
				requiredAttributeCount = requiredAttributeCount + 1
				hasAssociatedRequirement = hasAssociatedRequirement or associated
			end
			if attributeCount > 1 and required and not associated then
				return false, "armour attribute alignment does not match "..class.attributeName
			end
		end
		if attributeCount == 1 and (not hasAssociatedRequirement or requiredAttributeCount > 2) then
			return false, "armour attribute alignment does not match "..class.attributeName
		end
	end
	local requiredFoundLevel = MercenaryTools.requiredFoundAreaLevel(item.requirements and item.requirements.level)
	if (profile.foundAreaLevel or 0) < requiredFoundLevel then
		return false, "requires Mercenary level "..requiredFoundLevel
	end
	if (item.rarity == "UNIQUE" or item.rarity == "RELIC") and not (item.type == "Jewel" and item.base and item.base.subType == "Abyss") then
		local requiredFlag = UNIQUE_FLAG_BY_SLOT[slotName]
		if not requiredFlag then
			return false, "Unique items are never permitted in this slot"
		elseif context.playerHasFlag(requiredFlag) == false then
			return false, "requires a modifier allowing your Mercenary to equip "..UNIQUE_SLOT_DESCRIPTION[requiredFlag]
		end
	end
	if slotName == "Weapon 1" or slotName == "Weapon 2" then
		local allowedTypes = slotName == "Weapon 1" and mercBuild.weaponConfiguration.mainHandTypes or mercBuild.weaponConfiguration.offHandTypes
		if not contains(allowedTypes, item.type) then
			return false, item.type.." is not valid in this weapon slot for the selected build"
		end
	end
	if context.itemSet ~= context.playerItemSet and MercenaryTools.playerEquipsPhysicalItem(item, context.playerItemSet, context.items) then
		return false, "the same physical item is equipped by the player"
	end
	return true
end

function MercenaryTools.equipmentErrors(context)
	local errors = { }
	local function equippedLookup(slotName)
		return MercenaryTools.equippedItem(context.itemSet, context.items, slotName, context.override, context.mercenaryItemSetId)
	end
	local mercBuild = context.mercenaryData.builds[context.profile.buildId]
	if mercBuild and mercBuild.weaponConfiguration.offHandRequired then
		if not equippedLookup("Weapon 2") then
			t_insert(errors, "Weapon 2: selected build requires a "..t_concat(mercBuild.weaponConfiguration.offHandTypes, " or "))
		end
	end
	local function checkSlot(slotName)
		local item = equippedLookup(slotName)
		if item then
			if not context.isItemValidForSlot(item, slotName, context.itemSet, equippedLookup) then
				t_insert(errors, slotName..": invalid base slot or weapon configuration")
			else
				local valid, reason = MercenaryTools.validateEquippedItem(item, slotName, context)
				if not valid then
					t_insert(errors, slotName..": "..reason)
				end
			end
		end
	end
	for _, slotName in ipairs(MercenaryTools.equipmentSlots) do
		checkSlot(slotName)
		for index = 1, 6 do
			checkSlot(slotName.." Abyssal Socket "..index)
		end
	end
	return errors
end

return MercenaryTools
