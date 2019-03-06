
local function mapAST(ast)
	if ast >= 36 then
		return ast + 4
	elseif ast >= 6 then
		return ast + 3
	else
		return ast
	end
end

local weaponClassMap = {
	[6] = "Claw",
	[7] = "Dagger",
	[8] = "Wand",
	[9] = "One Handed Sword",
	[10] = "Thrusting One Handed Sword",
	[11] = "One Handed Axe",
	[12] = "One Handed Mace",
	[13] = "Bow",
	[14] = "Staff",
	[15] = "Two Handed Sword",
	[16] = "Two Handed Axe",
	[17] = "Two Handed Mace",
	[32] = "Sceptre",
	[36] = "None",
}

local skillStatScope = { }
do
	local f = io.open("StatDescriptions/skillpopup_stat_filters.txt", "rb")
	local text = convertUTF16to8(f:read("*a"))
	f:close()
	for skillName, scope in text:gmatch('([%w_]+) "Metadata/StatDescriptions/([%w_]+)%.txt"') do
		skillStatScope[skillName] = scope
	end
end

local gems = { }

local directiveTable = { }

-- #noGem
-- Disables the gem component of the next skill
directiveTable.noGem = function(state, args, out)
	state.noGem = true
end

-- #skill <GrantedEffectId> [<Display name>]
-- Initialises the skill data and emits the skill header
directiveTable.skill = function(state, args, out)
	local grantedId, displayName = args:match("(%w+) (.+)")
	if not grantedId then
		grantedId = args
		displayName = args
	end
	out:write('skills["', grantedId, '"] = {\n')
	local grantedKey = GrantedEffects.Id(grantedId)[1]
	local granted = GrantedEffects[grantedKey]
	if not granted then
		print('Unknown GE: "'..grantedId..'"')
	end
	local skillGemKey = SkillGems.GrantedEffectsKey(grantedKey)[1]
	local skill = { }
	state.skill = skill
	if skillGemKey and not state.noGem then
		gems[skillGemKey] = true
		if granted.IsSupport then
			local skillGem = SkillGems[skillGemKey]
			local baseItemType = BaseItemTypes[skillGem.BaseItemTypesKey]
			out:write('\tname = "', baseItemType.Name:gsub(" Support",""), '",\n')
			if #skillGem.Description > 0 then
				out:write('\tdescription = "', skillGem.Description, '",\n')
			end
		else
			out:write('\tname = "', ActiveSkills[granted.ActiveSkillsKey].DisplayedName, '",\n')
		end
	else
		if displayName == args and not granted.IsSupport then
			displayName = ActiveSkills[granted.ActiveSkillsKey].DisplayedName
		end
		out:write('\tname = "', displayName, '",\n')
		out:write('\thidden = true,\n')
	end
	state.noGem = false
	skill.baseFlags = { }
	local modMap = { }
	skill.mods = { }
	skill.levels = { }
	local statMap = { }
	skill.stats = { }
	skill.statInterpolation = { }
	out:write('\tcolor = ', granted.Unknown0, ',\n')
	if granted.IncrementalEffectiveness ~= 0 then
		out:write('\tbaseEffectiveness = ', granted.BaseEffectiveness, ',\n')
		out:write('\tincrementalEffectiveness = ', granted.IncrementalEffectiveness, ',\n')
	end
	if granted.IsSupport then
		skill.isSupport = true
		out:write('\tsupport = true,\n')
		out:write('\trequireSkillTypes = { ')
		for _, type in ipairs(granted.AllowedActiveSkillTypes) do
			out:write(mapAST(type), ', ')
		end
		out:write('},\n')
		out:write('\taddSkillTypes = { ')
		for _, type in ipairs(granted.AddedActiveSkillTypes) do
			out:write(mapAST(type), ', ')
		end
		out:write('},\n')
		out:write('\texcludeSkillTypes = { ')
		for _, type in ipairs(granted.ExcludedActiveSkillTypes) do
			out:write(mapAST(type), ', ')
		end
		out:write('},\n')
		if granted.SupportsGemsOnly then
			out:write('\tsupportGemsOnly = true,\n')
		end
		out:write('\tstatDescriptionScope = "gem_stat_descriptions",\n')
	else
		local activeSkill = ActiveSkills[granted.ActiveSkillsKey]
		if #activeSkill.Description > 0 then
			out:write('\tdescription = "', activeSkill.Description, '",\n')
		end
		out:write('\tskillTypes = { ')
		for _, type in ipairs(activeSkill.ActiveSkillTypes) do
			out:write('[', mapAST(type), '] = true, ')
		end
		out:write('},\n')
		if activeSkill.MinionActiveSkillTypes[1] then
			out:write('\tminionSkillTypes = { ')
			for _, type in ipairs(activeSkill.MinionActiveSkillTypes) do
				out:write('[', mapAST(type), '] = true, ')
			end
			out:write('},\n')
		end
		local weaponTypes = { }
		for _, classKey in ipairs(activeSkill.WeaponRestriction_ItemClassesKeys) do
			if weaponClassMap[classKey] then
				weaponTypes[weaponClassMap[classKey]] = true
			end
		end
		if next(weaponTypes) then
			out:write('\tweaponTypes = {\n')
			for type in pairs(weaponTypes) do
				out:write('\t\t["', type, '"] = true,\n')
			end
			out:write('\t},\n')
		end
		out:write('\tstatDescriptionScope = "', skillStatScope[activeSkill.Id] or "skill_stat_descriptions", '",\n')
		if activeSkill.SkillTotemId ~= 17 then
			out:write('\tskillTotemId = ', activeSkill.SkillTotemId, ',\n')
		end
		out:write('\tcastTime = ', granted.CastTime / 1000, ',\n')
	end
	for _, key in ipairs(GrantedEffectsPerLevel.GrantedEffectsKey(grantedKey)) do
		local level = { extra = { } }
		local levelRow = GrantedEffectsPerLevel[key]
		level.level = levelRow.Level
		table.insert(skill.levels, level)
		level.extra.levelRequirement = levelRow.LevelRequirement
		if levelRow.ManaCost and levelRow.ManaCost ~= 0 then
			level.extra.manaCost = levelRow.ManaCost
		end
		if levelRow.ManaMultiplier ~= 100 then
			level.extra.manaMultiplier = levelRow.ManaMultiplier - 100
		end
		if levelRow.DamageEffectiveness ~= 0 then
			level.extra.damageEffectiveness = levelRow.DamageEffectiveness / 100 + 1
		end
		if levelRow.CriticalStrikeChance ~= 0 then
			level.extra.critChance = levelRow.CriticalStrikeChance / 100
		end
		if levelRow.DamageMultiplier and levelRow.DamageMultiplier ~= 0 then
			level.extra.baseMultiplier = levelRow.DamageMultiplier / 10000 + 1
		end
		if levelRow.ManaReservationOverride ~= 0 then
			level.extra.manaCostOverride = levelRow.ManaReservationOverride
		end
		if levelRow.Cooldown and levelRow.Cooldown ~= 0 then
			level.extra.cooldown = levelRow.Cooldown / 1000
		end
		for i, statKey in ipairs(levelRow.StatsKeys) do
			local statId = Stats[statKey].Id
			if not statMap[statId] then
				statMap[statId] = #skill.stats + 1
				table.insert(skill.stats, { id = statId })
			end
			skill.statInterpolation[i] = levelRow.StatInterpolationTypesKeys[i]
			if skill.statInterpolation[i] == 3 and levelRow.EffectivenessCostConstantsKeys[i] ~= 2 then
				table.insert(level, levelRow["Stat"..i.."Float"] / EffectivenessCostConstants[levelRow.EffectivenessCostConstantsKeys[i]].Multiplier)
			else
				table.insert(level, levelRow["Stat"..i.."Value"])
			end
		end
		for i, statKey in ipairs(levelRow.StatsKeys2) do
			local statId = Stats[statKey].Id
			if not statMap[statId] then
				statMap[statId] = #skill.stats + 1
				table.insert(skill.stats, { id = statId })
			end
		end
		if not skill.qualityStats then
			skill.qualityStats = { }
			for i, statKey in ipairs(levelRow.Quality_StatsKeys) do
				table.insert(skill.qualityStats, { Stats[statKey].Id, levelRow.Quality_Values[i] / 1000 })
			end
		end
	end
end

-- #flags <flag>[ <flag>[...]]
-- Sets the base flags for this active skill
directiveTable.flags = function(state, args, out)
	local skill = state.skill
	for flag in args:gmatch("%a+") do
		table.insert(skill.baseFlags, flag)
	end
end

-- #baseMod <mod definition>
-- Adds a base modifier to the skill
directiveTable.baseMod = function(state, args, out)
	local skill = state.skill
	table.insert(skill.mods, args)
end

-- #mods
-- Emits the skill modifiers
directiveTable.mods = function(state, args, out)
	local skill = state.skill
	if not skill.isSupport then
		out:write('\tbaseFlags = {\n')
		for _, flag in ipairs(skill.baseFlags) do
			out:write('\t\t', flag, ' = true,\n')
		end		
		out:write('\t},\n')
	end
	out:write('\tbaseMods = {\n')
	for _, mod in ipairs(skill.mods) do
		out:write('\t\t', mod, ',\n')
	end
	out:write('\t},\n')
	out:write('\tqualityStats = {\n')
	for _, stat in ipairs(skill.qualityStats) do
		out:write('\t\t{ "', stat[1], '", ', stat[2], ' },\n')
	end
	out:write('\t},\n')
	out:write('\tstats = {\n')
	for _, stat in ipairs(skill.stats) do
		out:write('\t\t"', stat.id, '",\n')
	end
	out:write('\t},\n')
	out:write('\tstatInterpolation = { ')
	for _, type in ipairs(skill.statInterpolation) do
		out:write(type, ', ')
	end
	out:write('},\n')
	out:write('\tlevels = {\n')
	for index, level in ipairs(skill.levels) do
		out:write('\t\t[', level.level, '] = { ')
		for _, statVal in ipairs(level) do
			out:write(tostring(statVal), ', ')
		end
		for k, v in pairs(level.extra) do
			out:write(k, ' = ', tostring(v), ', ')
		end
		out:write('},\n')
	end
	out:write('\t},\n')
	out:write('}')
	state.skill = nil
end

for _, name in pairs({"act_str","act_dex","act_int","other","glove","minion","spectre","sup_str","sup_dex","sup_int"}) do
	processTemplateFile("Skills/"..name, directiveTable)
end

local wellShitIGotThoseWrong = { 
	-- Serves me right for not paying attention (not that I've gotten them all right anyway)
	-- Let's just sweep these under the carpet so we don't break everyone's shiny new builds
	["Metadata/Items/Gems/SkillGemSmite"] = "Metadata/Items/Gems/Smite",
	["Metadata/Items/Gems/SkillGemConsecratedPath"] = "Metadata/Items/Gems/ConsecratedPath",
	["Metadata/Items/Gems/SkillGemVaalAncestralWarchief"] = "Metadata/Items/Gems/VaalAncestralWarchief",
	["Metadata/Items/Gems/SkillGemHeraldOfAgony"] = "Metadata/Items/Gems/HeraldOfAgony",
	["Metadata/Items/Gems/SkillGemHeraldOfPurity"] = "Metadata/Items/Gems/HeraldOfPurity",
	["Metadata/Items/Gems/SkillGemScourgeArrow"] = "Metadata/Items/Gems/ScourgeArrow",
	["Metadata/Items/Gems/SkillGemToxicRain"] = "Metadata/Items/Gems/RainOfSpores",
	["Metadata/Items/Gems/SkillGemSummonRelic"] = "Metadata/Items/Gems/SummonRelic",
}

local out = io.open("../Data/3_0/Gems.lua", "w")
out:write('-- This file is automatically generated, do not edit!\n')
out:write('-- Gem data (c) Grinding Gear Games\n\nreturn {\n')
for skillGemKey = 0, SkillGems.maxRow do
	if gems[skillGemKey] then
		local skillGem = SkillGems[skillGemKey] 
		local baseItemType = BaseItemTypes[skillGem.BaseItemTypesKey]
		out:write('\t["', wellShitIGotThoseWrong[baseItemType.Id] or baseItemType.Id, '"] = {\n')
		out:write('\t\tname = "', baseItemType.Name:gsub(" Support",""), '",\n')
		out:write('\t\tgrantedEffectId = "', GrantedEffects[skillGem.GrantedEffectsKey].Id, '",\n')
		if skillGem.GrantedEffectsKey2 then
			out:write('\t\tsecondaryGrantedEffectId = "', GrantedEffects[skillGem.GrantedEffectsKey2].Id, '",\n')
		end
		local tagNames = { }
		out:write('\t\ttags = {\n')
		for i, tagKey in ipairs(skillGem.GemTagsKeys) do
			out:write('\t\t\t', GemTags[tagKey].Id, ' = true,\n')
			if #GemTags[tagKey].Tag > 0 then
				table.insert(tagNames, GemTags[tagKey].Tag)
			end
		end
		out:write('\t\t},\n')
		out:write('\t\ttagString = "', table.concat(tagNames, ", "), '",\n')
		out:write('\t\treqStr = ', skillGem.Str, ',\n')
		out:write('\t\treqDex = ', skillGem.Dex, ',\n')
		out:write('\t\treqInt = ', skillGem.Int, ',\n')
		out:write('\t},\n')
	end
end
out:write('}')

os.execute("xcopy Skills\\*.lua ..\\Data\\3_0\\Skills\\ /Y /Q")

print("Skill data exported.")