-- Path of Building
--
-- Module: Mercenary Import
-- Convert LeagueAccount Mercenary snapshots into Mercenary profiles.
-- Skill/support/build IDs are optional; hashes are required and win on conflict.
--
local t_insert = table.insert
local sha = require("sha2")
local MercenaryTools = require("Modules.MercenaryTools")
local MercenaryImport = { }

local function resolve(records, id, hash, kind)
	if type(hash) ~= "number" then
		return nil, "Missing " .. kind .. " hash"
	end
	local record = id and records[id]
	if id then
		if not record then
			return nil, "Unsupported " .. kind .. " ID: " .. tostring(id)
		end
		if record.hash ~= hash then
			return nil, "Conflicting " .. kind .. " ID and hash: " .. tostring(id)
		end
	else
		for _, candidate in pairs(records) do
			if candidate.hash == hash then
				if record then
					return nil, "Ambiguous " .. kind .. " hash: " .. hash
				end
				record = candidate
			end
		end
	end
	if not record then
		return nil, "Unsupported " .. kind .. " hash: " .. hash
	end
	return record
end

function MercenaryImport.profile(hire, mercenaryData)
	if type(hire) ~= "table" or type(hire.name) ~= "string" or hire.name == "" or type(hire.skills) ~= "table" then
		return nil, "Missing Mercenary name or skills"
	end
	local mercBuild, err = resolve(mercenaryData.builds, hire.build, hire.build_hash, "build")
	if not mercBuild then
		return nil, err
	end
	local profile = {
		title = hire.name,
		buildId = mercBuild.id,
		classId = mercBuild.classId,
		foundAreaLevel = hire.level,
		lifeComparison = "AUTO",
		skills = { },
	}
	for _, sourceSkill in ipairs(hire.skills) do
		local skill, err = resolve(mercenaryData.skills, sourceSkill.id, sourceSkill.hash, "skill")
		if not skill then
			return nil, err
		end
		if sourceSkill.supports ~= nil and type(sourceSkill.supports) ~= "table" then
			return nil, "Missing supports for " .. skill.id
		end
		local selected = { id = skill.id, enabled = true, includeInFullDPS = false, count = 1, supports = { } }
		for _, sourceSupport in ipairs(sourceSkill.supports or { }) do
			local support, err = resolve(mercenaryData.supports, sourceSupport.id, sourceSupport.hash, "support")
			if not support then
				return nil, err
			end
			t_insert(selected.supports, { id = support.id, tier = sourceSupport.tier })
		end
		t_insert(profile.skills, selected)
	end
	profile.mainSkillId = MercenaryTools.firstEnabledSkillId(profile)
	local errors = MercenaryTools.validateProfile(profile, mercenaryData)
	if #errors > 0 then
		return nil, table.concat(errors, "; ")
	end
	return profile
end

function MercenaryImport.activeIndex(account)
	local index = account.active_mercenary_index
	if type(index) == "number" and index % 1 == 0 and index > 0 and index <= #(account.mercenaries or { }) then
		return index
	end
end

-- LeagueAccount mercenaries have no unique id. Identity is account/realm/league
-- plus name, build hash, and a canonical skill/support-hash fingerprint.
-- Equipment is excluded because it is mutable in game and in PoB.
-- Names are not assumed unique within a roster; skill hashes disambiguate.
-- The association is stored hashed so shareable XML never carries the account UUID.
local function lengthPrefixed(parts)
	for index, value in ipairs(parts) do
		parts[index] = #value .. ":" .. value
	end
	return table.concat(parts)
end

local function skillFingerprint(hire)
	local fingerprints = { }
	for _, skill in ipairs(hire.skills or { }) do
		local supports = { }
		for _, support in ipairs(skill.supports or { }) do
			t_insert(supports, tostring(support.hash) .. ":" .. tostring(support.tier))
		end
		table.sort(supports)
		t_insert(fingerprints, tostring(skill.hash) .. ":" .. table.concat(supports, ","))
	end
	table.sort(fingerprints)
	return table.concat(fingerprints, ";")
end

function MercenaryImport.association(account, realm, league, hire)
	return sha.sha256(lengthPrefixed({
		account, realm, league, hire.name, tostring(hire.build_hash), skillFingerprint(hire),
	}))
end

function MercenaryImport.matchesAssociation(stored, account, realm, league, hire)
	return type(stored) == "string" and stored == MercenaryImport.association(account, realm, league, hire)
end

function MercenaryImport.unusedEmptyId(sets, order)
	local unused
	for _, id in ipairs(order or { }) do
		local profile = sets[id]
		if profile and not profile.buildId and not profile.importAssociation then
			if unused then
				return
			end
			unused = id
		end
	end
	return unused
end

return MercenaryImport
