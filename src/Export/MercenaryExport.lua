-- Path of Building
--
-- Exporter: MercenaryExport
-- Exporter-only validation helpers for Mercenary data. The running calculator
-- does not load this module.

local MercenaryExport = { }

MercenaryExport.MONSTER_SPEED_DAMAGE_FIXUP_STAT = "monster_base_type_attack_cast_speed_+%_and_damage_-%_final"

function MercenaryExport.monsterSpeedAndDamageFixup(modId, stats)
	if type(modId) ~= "string" or not modId:find("SpeedAndDamageFixup", 1, true) then
		return nil
	end
	for _, stat in ipairs(stats or { }) do
		if stat.id == MercenaryExport.MONSTER_SPEED_DAMAGE_FIXUP_STAT and tonumber(stat.value) then
			return tonumber(stat.value) / 100
		end
	end
	error("Unrecognized monster speed/damage fixup: "..modId)
end

function MercenaryExport.considerRankedCandidate(current, id, rank)
	if not current or rank < current.rank then
		return { id = id, rank = rank, ids = { id } }
	end
	if rank > current.rank then
		return current
	end
	local ids = { }
	for _, existing in ipairs(current.ids) do
		ids[#ids + 1] = existing
	end
	ids[#ids + 1] = id
	return {
		id = id < current.id and id or current.id,
		rank = rank,
		ids = ids,
	}
end

function MercenaryExport.requireUniqueRankedCandidate(current, context)
	if not current then
		return nil
	end
	if #current.ids > 1 then
		local ids = { }
		for _, id in ipairs(current.ids) do
			ids[#ids + 1] = id
		end
		table.sort(ids)
		error("Ambiguous "..context..": "..table.concat(ids, ", "))
	end
	return current
end

function MercenaryExport.uniqueCandidate(candidate)
	return candidate and candidate.ids and #candidate.ids == 1 and candidate or nil
end

-- Unique ActiveSkill/name matches win. Remaining ties require an explicit
-- override. There is no fallback to a previously generated mercenary.lua.
function MercenaryExport.resolveBaseSkill(context)
	local byActiveSkill = context.byActiveSkill
	local byDisplayName = context.byDisplayName
	local base = MercenaryExport.uniqueCandidate(byActiveSkill)
	if MercenaryExport.uniqueCandidate(byDisplayName) and (not base or byDisplayName.rank < base.rank) then
		base = byDisplayName
	end
	if base == byActiveSkill and base ~= nil then
		return { id = base.id, source = "activeSkill" }
	end
	if base then
		return { id = base.id, source = "displayName" }
	end
	local overrideId = context.overrideId
	if overrideId then
		if not context.isExportedSkill or not context.isExportedSkill(overrideId) then
			error("Mercenary base-skill override is not an exported skill: "..context.effectId.." -> "..overrideId)
		end
		return { id = overrideId, source = "override" }
	end
	if byActiveSkill then
		MercenaryExport.requireUniqueRankedCandidate(byActiveSkill, "Mercenary base skill ActiveSkill '"..context.activeSkillId.."'")
	end
	if byDisplayName then
		MercenaryExport.requireUniqueRankedCandidate(byDisplayName, "Mercenary base skill display name '"..context.displayName.."'")
	end
end

function MercenaryExport.shieldPolicyError(builds, shieldPolicy)
	local function hasShield(weaponTypes)
		for _, itemType in ipairs(weaponTypes or { }) do
			if itemType == "Shield" then
				return true
			end
		end
		return false
	end
	for buildId, mercBuild in pairs(builds or { }) do
		if hasShield(mercBuild.weaponTypes) then
			local policy = shieldPolicy and shieldPolicy[buildId]
			if not policy then
				return "missing shield policy for Mercenary build: "..buildId
			end
			if policy ~= "required" and policy ~= "optional" then
				return "unknown shield policy for Mercenary build: "..buildId
			end
		end
	end
	for buildId, policy in pairs(shieldPolicy or { }) do
		if policy ~= "required" and policy ~= "optional" then
			return "unknown shield policy for Mercenary build: "..buildId
		end
		local mercBuild = builds and builds[buildId]
		if not mercBuild then
			return "shield policy references unknown Mercenary build: "..buildId
		end
		if not hasShield(mercBuild.weaponTypes) then
			return "shield policy for "..buildId.." does not include a Shield"
		end
	end
end

return MercenaryExport
