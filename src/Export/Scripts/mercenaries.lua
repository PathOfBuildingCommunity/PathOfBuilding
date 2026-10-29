local function sortedRows(name, key)
	local rows = { }
	for row in dat(name):Rows() do
		table.insert(rows, row)
	end
	table.sort(rows, function(a, b)
		return tostring(key(a)) < tostring(key(b))
	end)
	return rows
end

local function rowId(row)
	return row and (row.Id.Id or row.Id)
end

local function rowIds(rows)
	local ids = { }
	for _, row in ipairs(rows or { }) do
		table.insert(ids, rowId(row))
	end
	table.sort(ids)
	return ids
end

local function uniqueSorted(values)
	local seen, result = { }, { }
	for _, value in ipairs(values) do
		if value and not seen[value] then
			seen[value] = true
			table.insert(result, value)
		end
	end
	table.sort(result)
	return result
end

local function getOTStats(objectType, stats, visited)
	if not objectType or objectType == "" or objectType == "Metadata/Monsters/Monster" or objectType == "nothing" then
		return
	end
	visited = visited or { }
	if visited[objectType] then
		return
	end
	visited[objectType] = true
	local text = getFile(objectType..".ot")
	if not text then
		error("Missing Mercenary object template: "..objectType..".ot")
	end
	text = convertUTF16to8(text)
	local parent = text:match('extends "([^"]+)"')
	getOTStats(parent, stats, visited)
	local inStats = false
	for line in text:gmatch("[^\r\n]+") do
		if line:match("^Stats") then
			inStats = true
		elseif inStats and line:match("^}") then
			inStats = false
		elseif inStats and line:find("=") and not line:find("//") then
			local id, value = line:gsub("%s+", ""):match("^([^=]+)=(.+)$")
			if id and tonumber(value) then
				table.insert(stats, { id = id, value = tonumber(value), source = objectType })
			end
		end
	end
end

-- The `Monster { }` block of an object template holds engine flags rather than
-- stats, so it needs its own pass.
local function getOTMonsterProperties(objectType, properties, visited)
	if not objectType or objectType == "" or objectType == "Metadata/Monsters/Monster" or objectType == "nothing" then
		return
	end
	visited = visited or { }
	if visited[objectType] then
		return
	end
	visited[objectType] = true
	local text = getFile(objectType..".ot")
	if not text then
		error("Missing Mercenary object template: "..objectType..".ot")
	end
	text = convertUTF16to8(text)
	getOTMonsterProperties(text:match('extends "([^"]+)"'), properties, visited)
	local inMonster = false
	for line in text:gmatch("[^\r\n]+") do
		if line:match("^Monster") then
			inMonster = true
		elseif inMonster and line:match("^}") then
			inMonster = false
		elseif inMonster and line:find("=") and not line:find("//") then
			local id, value = line:gsub("%s+", ""):match("^([^=]+)=(.+)$")
			if id then
				properties[id] = tonumber(value) or value == "true" or value
			end
		end
	end
end

local function appendModStats(mods, stats)
	for _, modRow in ipairs(mods or { }) do
		for index = 1, 6 do
			local stat = modRow["Stat"..index]
			local values = modRow["Stat"..index.."Value"]
			if stat and values and values[1] then
				table.insert(stats, { id = stat.Id, value = values[1], source = modRow.Id })
			end
		end
	end
end

local itemClassMap = {
	["Claw"] = "Claw",
	["Dagger"] = "Dagger",
	["Rune Dagger"] = "Dagger",
	["Wand"] = "Wand",
	["One Hand Sword"] = "One Handed Sword",
	["Thrusting One Hand Sword"] = "Thrusting One Handed Sword",
	["One Hand Axe"] = "One Handed Axe",
	["One Hand Mace"] = "One Handed Mace",
	["Bow"] = "Bow",
	["Quiver"] = "Quiver",
	["Fishing Rod"] = "Fishing Rod",
	["Staff"] = "Staff",
	["Warstaff"] = "Staff",
	["Two Hand Sword"] = "Two Handed Sword",
	["Two Hand Axe"] = "Two Handed Axe",
	["Two Hand Mace"] = "Two Handed Mace",
	["Shield"] = "Shield",
	["Sceptre"] = "Sceptre",
	["Unarmed"] = "None",
}

local passiveStatFormats = {
	base_strength = { format = "+%s to Strength" },
	base_dexterity = { format = "+%s to Dexterity" },
	base_intelligence = { format = "+%s to Intelligence" },
	["physical_damage_reduction_rating_+%"] = { format = "%s%% increased Armour" },
	["evasion_rating_+%"] = { format = "%s%% increased Evasion Rating" },
	["maximum_energy_shield_+%"] = { format = "%s%% increased maximum Energy Shield" },
	["life_regeneration_rate_per_minute_%"] = { format = "Regenerate %s%% of Life per second", divisor = 60 },
	["energy_shield_recharge_rate_+%"] = { format = "%s%% increased Energy Shield Recharge Rate" },
	["energy_shield_delay_-%"] = { format = "%s%% faster start of Energy Shield Recharge" },
	["base_spell_suppression_chance_%"] = { format = "+%s%% chance to Suppress Spell Damage" },
	["maximum_life_+%"] = { format = "%s%% increased maximum Life" },
	["damage_+%"] = { format = "%s%% increased Damage" },
	["critical_strike_chance_+%"] = { format = "%s%% increased Critical Strike Chance" },
	["base_critical_strike_multiplier_+"] = { format = "+%s%% to Critical Strike Multiplier" },
	["dot_multiplier_+"] = { format = "+%s%% to Damage over Time Multiplier" },
	["attack_speed_+%"] = { format = "%s%% increased Attack Speed" },
	["base_cast_speed_+%"] = { format = "%s%% increased Cast Speed" },
	["trap_throwing_speed_+%"] = { format = "%s%% increased Trap Throwing Speed" },
	["accuracy_rating_+%"] = { format = "%s%% increased Accuracy Rating" },
	resolute_technique = { line = "Resolute Technique" },
	["base_chance_to_freeze_%"] = { format = "%s%% chance to Freeze" },
	["chill_effect_+%"] = { format = "%s%% increased Effect of Chill" },
	["base_chance_to_ignite_%"] = { format = "%s%% chance to Ignite" },
	["ignite_duration_+%"] = { format = "%s%% increased Ignite Duration" },
	["base_chance_to_shock_%"] = { format = "%s%% chance to Shock" },
	["shock_effect_+%"] = { format = "%s%% increased Effect of Shock" },
	["base_chance_to_poison_on_hit_%"] = { format = "%s%% chance to Poison on Hit" },
	["base_poison_duration_+%"] = { format = "%s%% increased Poison Duration" },
	["bleed_on_hit_with_attacks_%"] = { format = "%s%% chance to cause Bleeding" },
	["base_bleed_duration_+%"] = { format = "%s%% increased Bleed Duration" },
	["attacks_impale_on_hit_%_chance"] = { format = "%s%% chance to Impale Enemies on Hit with Attacks" },
	["impale_debuff_effect_+%"] = { format = "%s%% increased Impale Effect" },
	["base_stun_threshold_reduction_+%"] = { format = "%s%% reduced Enemy Stun Threshold" },
	["base_stun_duration_+%"] = { format = "%s%% increased Stun Duration on Enemies" },
	["hits_ignore_enemy_monster_physical_damage_reduction_%_chance"] = { format = "Hits have %s%% chance to ignore Enemy Physical Damage Reduction" },
	["minion_damage_+%"] = { format = "Minions deal %s%% increased Damage" },
	["minion_maximum_life_+%"] = { format = "Minions have %s%% increased maximum Life" },
	["minion_life_regeneration_rate_per_minute_%"] = { format = "Minions Regenerate %s%% of Life per second", divisor = 60 },
	["minion_critical_strike_chance_+%"] = { format = "Minions have %s%% increased Critical Strike Chance" },
	["minion_critical_strike_multiplier_+"] = { format = "Minions have +%s%% to Critical Strike Multiplier" },
	["minion_attack_speed_+%"] = { format = "Minions have %s%% increased Attack Speed" },
	["minion_cast_speed_+%"] = { format = "Minions have %s%% increased Cast Speed" },
	minion_damage_increases_and_reductions_also_affects_you = { line = "Increases and Reductions to Minion Damage also affect you" },
	keystone_minion_instability = { line = "Minion Instability" },
	base_phasing_without_visual = { line = "Phasing" },
	["monster_base_block_%"] = { format = "+%s%% Chance to Block Attack Damage" },
	["base_spell_block_%"] = { format = "+%s%% Chance to Block Spell Damage" },
}

-- Hand-authored Mercenary policy lives with the rest of the hand-authored data
-- rather than in the extraction path. Only the policy tables are read here, so the
-- stat map's mod constructors do not need real implementations, but its mod flags
-- are still evaluated as the file loads.
dofile("../Data/Global.lua")
local function stubMod() return { } end
local mercenaryStatData = LoadModule("../Data/MercenaryStatMap.lua")(stubMod, stubMod, stubMod)
local MercenaryExport = LoadModule("MercenaryExport")
local shieldPolicy = mercenaryStatData.shieldPolicy
local supportCounts = mercenaryStatData.supportCounts
for _, row in ipairs(sortedRows("MercenarySupportCounts", function(value) return value.Id end)) do
	if not supportCounts[row.Id] then
		error("Missing support-count policy for: "..tostring(row.Id))
	end
end

-- Every stat a permanent Mercenary gains from its object template is either
-- exported or listed here with the reason it is not, so that a stat GGG adds later
-- fails the export instead of disappearing.
local mercenaryAdditionStatUses = {
	life_per_level = true,
	mana_per_level = true,
	accuracy_rating_per_level = true,
	-- Cancels the Life a monster gains from being Rare. PoB models the Mercenary as
	-- a normalized actor that never receives that bonus, so applying the correction
	-- on its own would remove Life the actor never had.
	["monster_life_+%_final_from_rarity"] = false,
	-- Only governs whether kills by the Mercenary grant experience and drops.
	eligible_to_grant_kill_bonuses = false,
}

local mercenaryAdditionStats = { }
getOTStats("Metadata/Monsters/Mercenaries/MercenaryAdditions", mercenaryAdditionStats)
local mercenaryAdditionStatsById = { }
for _, stat in ipairs(mercenaryAdditionStats) do
	if mercenaryAdditionStatUses[stat.id] == nil then
		error("Unhandled permanent Mercenary base stat: "..stat.id)
	end
	mercenaryAdditionStatsById[stat.id] = stat.value
end
for statId, exported in pairs(mercenaryAdditionStatUses) do
	if exported and not mercenaryAdditionStatsById[statId] then error("Missing permanent Mercenary base stat: "..statId) end
end

local mercenaryAdditionProperties = { }
getOTMonsterProperties("Metadata/Monsters/Mercenaries/MercenaryAdditions", mercenaryAdditionProperties)
if mercenaryAdditionProperties.disable_default_monster_stats ~= true then
	error("Permanent Mercenaries no longer disable the default monster stats")
end

for row in dat("MercenaryBuildExtraStats"):Rows() do
	if not row.Stat or not passiveStatFormats[row.Stat.Id] then
		error("Unsupported Mercenary passive stat: "..tostring(row.Stat and row.Stat.Id or row.Id))
	end
end

local permanentMercenaryDamageMore
for passive in dat("PassiveSkills"):Rows() do
	for index, stat in ipairs(passive.Stats or { }) do
		if stat.Id == "permanenet_mercenary_damage_+%_final_and_minion_damage_+%_final_from_luminary" then
			if permanentMercenaryDamageMore ~= nil then
				error("Permanent Mercenary damage stat is present on more than one passive")
			end
			-- This is the maximum MORE penalty. 3.29.1 tapers it in by Mercenary
			-- level; `MercenaryTools.permanentDamageMore` applies that curve.
			permanentMercenaryDamageMore = passive["Stat"..index]
		end
	end
end
if permanentMercenaryDamageMore == nil then error("Missing permanent Mercenary damage stat") end

local function exportMonster(variety)
	if not variety then
		error("Mercenary class has no allied MonsterVariety")
	end
	local stats = { }
	appendModStats(variety.Mods, stats)
	appendModStats(variety.SpecialMods, stats)
	getOTStats(variety.ObjectType, stats)
	-- Sort by stat id, then by the mod or object template that granted it, so that a
	-- stat granted twice keeps a stable order across re-exports.
	table.sort(stats, function(a, b)
		if a.id ~= b.id then
			return a.id < b.id
		end
		return tostring(a.source) < tostring(b.source)
	end)
	local monster = {
		id = variety.Id,
		name = variety.Name,
		life = variety.LifeMultiplier / 100,
		-- Monsters get 40% of the Energy Shield their type states; `minions.lua` applies
		-- the same conversion when exporting Spectres.
		energyShield = variety.Type.EnergyShield == 0 and 0 or 0.4 * variety.Type.EnergyShield / 100,
		armour = variety.Type.Armour / 100,
		evasion = variety.Type.Evasion / 100,
		fireResist = variety.Type.Resistances.FireMerciless,
		coldResist = variety.Type.Resistances.ColdMerciless,
		lightningResist = variety.Type.Resistances.LightningMerciless,
		chaosResist = variety.Type.Resistances.ChaosMerciless,
		damage = variety.DamageMultiplier / 100,
		damageSpread = variety.Type.DamageSpread / 100,
		attackTime = variety.AttackDuration / 1000,
		attackRange = variety.MaximumAttackRange,
		accuracy = variety.Type.Accuracy / 100,
		baseDamageIgnoresAttackSpeed = variety.Type.BaseDamageIgnoresAttackSpeed or nil,
		lifeScaling = variety.Type.AltLife1 and "AltLife1" or variety.Type.AltLife2 and "AltLife2" or nil,
		weaponType1 = variety.MainHandItemClass and itemClassMap[variety.MainHandItemClass.Id] or nil,
		weaponType2 = variety.OffHandItemClass and itemClassMap[variety.OffHandItemClass.Id] or nil,
		skillIds = rowIds(variety.GrantedEffects),
		stats = stats,
	}
	for _, modRow in ipairs(variety.Mods or { }) do
		local modStats = { }
		for index = 1, 6 do
			local stat = modRow["Stat"..index]
			local values = modRow["Stat"..index.."Value"]
			if stat and values and values[1] then
				table.insert(modStats, { id = stat.Id, value = values[1] })
			end
		end
		local fixup = MercenaryExport.monsterSpeedAndDamageFixup(modRow.Id, modStats)
		if fixup then
			monster.damageFixup = fixup
		end
	end
	return monster
end

local function constantStatValue(grantedEffect, wantedStatId)
	for index, stat in ipairs(grantedEffect.GrantedEffectStatSets.ConstantStats or { }) do
		if stat.Id == wantedStatId then
			return grantedEffect.GrantedEffectStatSets.ConstantStatsValues[index]
		end
	end
end

local mercenaries = {
	baseStats = {
		lifePerLevel = mercenaryAdditionStatsById.life_per_level,
		manaPerLevel = mercenaryAdditionStatsById.mana_per_level,
		accuracyPerLevel = mercenaryAdditionStatsById.accuracy_rating_per_level,
		-- MercenaryAdditions sets `disable_default_monster_stats`, so Life, Mana and
		-- Accuracy come from the per-level grants above rather than the monster level
		-- tables. Armour, Evasion and Energy Shield have no per-level replacement,
		-- which leaves the Mercenary with none of them until it equips items.
		disableDefaultMonsterStats = true,
	},
	permanentMercenaryDamageMore = permanentMercenaryDamageMore,
	classes = { },
	classOrder = { },
	builds = { },
	buildOrder = { },
	skills = { },
	supports = { },
	minions = { },
	summonedMinions = { },
	skillFamilies = { },
	supportFamilies = { },
	skillsByHash = { },
	supportsByHash = { },
}

local supportCount = 0

for _, row in ipairs(sortedRows("MercenarySupports", function(value) return value.Id end)) do
	local familyId = rowId(row.SupportFamily)
	if row.HASH16 == nil then error("Mercenary support is missing hash data: "..row.Id) end
	local stats = { }
	if #row.Stat ~= #row.StatValues then
		error("Mercenary support stat/value count mismatch: "..row.Id)
	end
	for index, stat in ipairs(row.Stat) do
		table.insert(stats, { id = stat.Id, value = row.StatValues[index] })
	end
	mercenaries.supports[row.Id] = {
		id = row.Id,
		name = row.Name,
		familyId = familyId,
		hash = row.HASH16,
		variant = row.Variant,
		icon = row.GemIcon,
		stats = stats,
	}
	if familyId then mercenaries.supportFamilies[familyId] = { id = familyId } end
	supportCount = supportCount + 1
	local hash = tostring(row.HASH16)
	mercenaries.supportsByHash[hash] = mercenaries.supportsByHash[hash] or { }
	table.insert(mercenaries.supportsByHash[hash], row.Id)
end

local skillCount = 0
for _, row in ipairs(sortedRows("MercenarySkills", function(value) return rowId(value.Id) end)) do
	local id = rowId(row.Id)
	local familyId = rowId(row.SkillFamily)
	local supportCountId = rowId(row.SupportCount)
	if row.HASH16 == nil or not supportCounts[supportCountId] then
		error("Mercenary skill is missing hash or support-count data: "..tostring(id))
	end
	mercenaries.skills[id] = {
		id = id,
		name = row.Name,
		description = row.Description,
		familyId = familyId,
		hash = row.HASH16,
		supportCountId = supportCountId,
		possibleSupportIds = rowIds(row.PossibleSupports),
		secondarySkillId = rowId(row.SecondaryGrantedEffect),
		icon = row.HouseSkillIcon,
	}
	for _, effect in ipairs({ row.Id, row.SecondaryGrantedEffect }) do
		if effect then
			local summonedId = constantStatValue(effect, "alternate_minion")
			if summonedId then
				local summoned = dat("SummonedSpecificMonsters"):GetRow("Id", summonedId)
				local variety = summoned and summoned.MonsterVarietiesKey
				if not variety then error("Mercenary skill references missing summoned monster: "..effect.Id.." -> "..summonedId) end
				mercenaries.summonedMinions[effect.Id] = variety.Id
				mercenaries.minions[variety.Id] = mercenaries.minions[variety.Id] or exportMonster(variety)
			end
		end
	end
	if familyId then mercenaries.skillFamilies[familyId] = { id = familyId } end
	skillCount = skillCount + 1
	local hash = tostring(row.HASH16)
	mercenaries.skillsByHash[hash] = mercenaries.skillsByHash[hash] or { }
	table.insert(mercenaries.skillsByHash[hash], id)
end

for skillId, skill in pairs(mercenaries.skills) do
	for _, supportId in ipairs(skill.possibleSupportIds) do
		if not mercenaries.supports[supportId] then
			error("Mercenary skill references missing support: "..skillId.." -> "..supportId)
		end
	end
	if skill.secondarySkillId and not dat("GrantedEffects"):GetRow("Id", skill.secondarySkillId) then
		error("Mercenary skill references missing secondary effect: "..skillId.." -> "..skill.secondarySkillId)
	end
end

for _, row in ipairs(sortedRows("MercenaryClasses", function(value) return value.Id end)) do
	local class = {
		id = row.Id,
		name = row.MonsterVarietyAllied.Name ~= "" and row.MonsterVarietyAllied.Name or row.MonsterVariety.Name,
		attributeId = rowId(row.Attribute),
		attributeName = row.Attribute.Name,
		attributeTags = rowIds(row.Attribute.Tag),
		icon = row.Icon,
		houseIcon = row.HouseIcon,
		buffIcon = row.BuffIcon,
		monster = exportMonster(row.MonsterVarietyAllied),
		buildIds = { },
		skillIds = { },
	}
	mercenaries.classes[row.Id] = class
	table.insert(mercenaries.classOrder, row.Id)
end

for _, row in ipairs(sortedRows("MercenaryBuilds", function(value) return value.Id end)) do
	local idleSkillId = row.IdleSkill and rowId(row.IdleSkill.Id)
	if idleSkillId ~= "DoLiterallyNothing" then
		error("Unsupported Mercenary idle skill: "..row.Id.." -> "..tostring(idleSkillId))
	end
	local pools = {
		{ skillIds = rowIds(row.Skill1), countMax = row.Skill1CountMax },
		{ skillIds = rowIds(row.Skill2), countMax = row.Skill2CountMax },
		{ skillIds = rowIds(row.Skill3) },
	}
	local allSkills = { }
	for _, pool in ipairs(pools) do
		for _, id in ipairs(pool.skillIds) do
			table.insert(allSkills, id)
		end
	end
	local weaponTypes = { }
	for _, wieldableType in ipairs(row.WeaponTypes) do
		local itemClassId = rowId(wieldableType.ItemClasses)
		local itemType = itemClassMap[itemClassId]
		if not itemType then error("Unsupported Mercenary item class: "..tostring(itemClassId)) end
		table.insert(weaponTypes, itemType)
	end
	weaponTypes = uniqueSorted(weaponTypes)
	local mainHandTypes = { }
	local requiresShield, requiresQuiver = false, false
	for _, itemType in ipairs(weaponTypes) do
		if itemType == "Shield" then
			requiresShield = true
		elseif itemType == "Quiver" then
			requiresQuiver = true
		else
			table.insert(mainHandTypes, itemType)
		end
	end
	local optionalShield = requiresShield and shieldPolicy[row.Id] == "optional"
	local offHandTypes = requiresShield and (optionalShield and uniqueSorted({ "Shield", unpack(mainHandTypes) }) or { "Shield" }) or requiresQuiver and { "Quiver" } or mainHandTypes
	local passiveStats = { }
	for _, statRow in ipairs(row.BuildStats or { }) do
		local statId = statRow.Stat.Id
		local definition = passiveStatFormats[statId]
		table.insert(passiveStats, {
			id = statRow.Id,
			statId = statId,
			categoryId = statRow.Category and statRow.Category.Id or nil,
			categoryName = statRow.Category and statRow.Category.Name or nil,
			values = { statRow.Value1, statRow.Value2, statRow.Value3 },
			format = definition.format,
			line = definition.line,
			divisor = definition.divisor,
		})
	end
	table.sort(passiveStats, function(a, b) return a.id < b.id end)
	local build = {
		id = row.Id,
		classId = row.Class.Id,
		name = row.BuildName,
		infamous = row.Infamous,
		hash = row.HASH16,
		tags = rowIds(row.Tags),
		skillPools = pools,
		skillIds = uniqueSorted(allSkills),
		weaponTypes = weaponTypes,
		weaponConfiguration = {
			mainHandTypes = mainHandTypes,
			offHandTypes = offHandTypes,
			offHandRequired = requiresQuiver or requiresShield and not optionalShield,
		},
		passiveStats = passiveStats,
	}
	if not mercenaries.classes[build.classId] then
		error("Mercenary build references missing class: "..build.id)
	end
	for _, skillId in ipairs(build.skillIds) do
		if not mercenaries.skills[skillId] then
			error("Mercenary build references missing skill: "..build.id.." -> "..skillId)
		end
	end
	mercenaries.builds[build.id] = build
	table.insert(mercenaries.buildOrder, build.id)
	table.insert(mercenaries.classes[build.classId].buildIds, build.id)
	for _, skillId in ipairs(build.skillIds) do
		table.insert(mercenaries.classes[build.classId].skillIds, skillId)
	end
end

for _, class in pairs(mercenaries.classes) do
	class.skillIds = uniqueSorted(class.skillIds)
end
local shieldPolicyError = MercenaryExport.shieldPolicyError(mercenaries.builds, shieldPolicy)
if shieldPolicyError then
	error(shieldPolicyError)
end
for _, ids in pairs(mercenaries.skillsByHash) do
	table.sort(ids)
end
for _, ids in pairs(mercenaries.supportsByHash) do
	table.sort(ids)
end

local out = assert(io.open("../Data/Mercenaries.lua", "w"))
out:write("-- This file is automatically generated, do not edit!\n")
out:write("-- Mercenary data (c) Grinding Gear Games\n\nreturn ")
writeLuaTable(out, mercenaries, 1)
out:write("\n")
out:close()

print(string.format("Mercenary data exported: %d classes, %d builds, %d skills, %d supports.", #mercenaries.classOrder, #mercenaries.buildOrder, skillCount, supportCount))
