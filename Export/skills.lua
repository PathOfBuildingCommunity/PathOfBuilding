-- Skill types:
-- 1	Attack
-- 2	Spell
-- 3	Fires projectiles
-- 4	Dual wield skill (Only on Dual Strike)
-- 5	Buff
-- 6	Only uses main hand
-- 7	Combines both weapons? (Only on Cleave)
-- 8	Minion skill
-- 9	Spell with hit damage
-- 10	Area
-- 11	Duration
-- 12	Shield skill
-- 13	Projectile damage
-- 14	Mana cost is reservation
-- 15	Mana cost is percentage
-- 16	Skill can be trap?
-- 17	Spell can be totem?
-- 18	Skill can be mine?
-- 19	Causes status effects (Only on Arctic Armour, allows Elemental Proliferation)
-- 20	Creates minions
-- 21	Attack can be totem?
-- 22	Chaining
-- 23	Melee
-- 24	Single target melee
-- 25	Spell can multicast
-- 26	?? (On auras, searing bond, tempest shield, blade vortex and others)
-- 27	Attack can multistrike
-- 28	Burning
-- 29	Totem
-- 30	?? (On Molten Shell + Glove Thunder, applied by Blasphemy)
-- 31	Curse
-- 32	Fire skill
-- 33	Cold skill
-- 34	Lightning skill
-- 35	Triggerable spell
-- 36	Trap
-- 37	Movement
-- 38	Damage over Time
-- 39	Mine
-- 40	Triggered spell
-- 41	Vaal
-- 42	Aura
-- 43	Lightning spell
-- 44	?? (Not on any skills or supports)
-- 45	Triggered attack
-- 46	Projectile attack
-- 47	Minion spell
-- 48	Chaos skill
-- 49	?? (Not on any skills, excluded by Faster/Slower Projectiles)
-- 50	?? (Only on Contagion, allows Iron Will)
-- 51	?? (Only on Burning Arrow/Vigilant Strike, allows Inc AoE + Conc Effect)
-- 52	Projectile? (Not on any skills, allows all projectile supports)
-- 53	?? (Only on Burning Arrow/VBA, allows Inc/Red Duration + Rapid Decay)
-- 54	Projectile attack? (Not on any skills, allows projectile attack supports)
-- 55	?? Same as 47
-- 56	Channelled
-- 57	?? (Only on Contagion, allows Controlled Destruction)
-- 58	Cold spell
-- 59	Granted triggered skill (Prevents trigger supports, trap, mine, totem)
-- 60	Golem
-- 61	Herald
-- 62	Aura Debuff
-- 63	?? (Excludes Ruthless from Cyclone)
-- 64	?? (Allows Iron Will)
-- 65	Spell can cascade
-- 66	Skill can Volley
-- 67	Skill can Mirage Archer
-- 68	?? (Excludes Volley on Vaal Fireball/Spark)
-- 69	?? (Excludes Volley on Spectral Shield Throw)

local function mapAST(ast)
	if ast >= 36 then
		return ast + 4
	elseif ast >= 6 then
		return ast + 3
	else
		return ast
	end
end

local function addMod(mods, modDef, value)
	local mod = {
		mult = 1,
		val = value,
		levels = { value },
		def = modDef,
	}
	table.insert(mods, mod)
	return mod
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

local gems = { }

local directiveTable = { }

-- I'll leave all this here as a monument to how badly I got screwed by BIT being absent in the prepatch
--local gemMap = dofile("Gems.lua")
local wildAssGuessAtNewGemInfo = {
	["SupportPhysicalProjectileAttackDamage"] = {
		"Metadata/Items/Gems/SupportGemPhysicalProjectileAttackDamage", "Vicious Projectiles" 
	},
	["Smite"] = {
		"Metadata/Items/Gems/Smite", "Smite"
	},
	["ConsecratedPath"] = {
		"Metadata/Items/Gems/ConsecratedPath", "Consecrated Path",
	},
	["SummonRelic"] = {
		"Metadata/Items/Gems/SummonRelic", "Summon Holy Relic",
	},
	["HeraldOfPurity"] = {
		"Metadata/Items/Gems/HeraldOfPurity", "Herald of Purity",
	},
	["ScourgeArrow"] = {
		"Metadata/Items/Gems/ScourgeArrow", "Scourge Arrow",
	},
	["RainOfSpores"] = {
		"Metadata/Items/Gems/RainOfSpores", --[["Chocolate Rain"]]"Toxic Rain",
	},
	["HeraldOfAgony"] = {
		"Metadata/Items/Gems/HeraldOfAgony", "Herald of Agony",
	},
	["VaalAncestralWarchief"] = {
		"Metadata/Items/Gems/VaalAncestralWarchief", "Vaal Ancestral Warchief",
	},
	["SupportChaosAttacks"] = {
		"Metadata/Items/Gems/SupportGemChaosAttacks", "Withering Touch",
	},
}
function dammitChris(grantedId)
	if wildAssGuessAtNewGemInfo[grantedId] then
		return unpack(wildAssGuessAtNewGemInfo[grantedId])
	end
	for id, data in pairs(gemMap) do
		if data.grantedEffectId == grantedId then
			return id, data.name
		end
	end
	error("GrantedId '"..grantedId.."' no gem")
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
			--local gemId, gemName = dammitChris(grantedId)
			--out:write('\tname = "', gemName, '",\n')
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
		if activeSkill.SkillTotemId ~= 17 then
			out:write('\tskillTotemId = ', activeSkill.SkillTotemId, ',\n')
		end
		addMod(skill.mods, 'skill("castTime", {val})', granted.CastTime / 1000)
	end
	for _, key in ipairs(GrantedEffectsPerLevel.GrantedEffectsKey(grantedKey)) do
		local level = { }
		local levelRow = GrantedEffectsPerLevel[key]
		level.level = levelRow.Level
		table.insert(skill.levels, level)
		local function addLevelMod(modDef, value, forcePerLevel)
			local mod = skill.mods[modMap[modDef]]
			if mod then
				if value ~= mod.val then
					mod.perLevel = true
				end
			else
				modMap[modDef] = #skill.mods + 1
				addMod(skill.mods, modDef)
				mod = skill.mods[modMap[modDef]]
				mod.val = value
			end
			if forcePerLevel then
				mod.perLevel = true
			end
			mod.levels[levelRow.Level] = value
		end
		if not granted.IsSupport then
			addLevelMod('skill("levelRequirement", {val})', levelRow.LevelRequirement, true)
		else
			addLevelMod("nil", levelRow.LevelRequirement, true)
		end
		if levelRow.ManaCost and levelRow.ManaCost ~= 0 then
			addLevelMod('skill("manaCost", {val})', levelRow.ManaCost)
		end
		if levelRow.ManaMultiplier ~= 100 then
			addLevelMod('mod("ManaCost", "MORE", {val})', levelRow.ManaMultiplier - 100)
		end
		if levelRow.DamageEffectiveness ~= 0 then
			addLevelMod('skill("damageEffectiveness", {val})', levelRow.DamageEffectiveness / 100 + 1)
		end
		if levelRow.CriticalStrikeChance ~= 0 then
			addLevelMod('skill("CritChance", {val})', levelRow.CriticalStrikeChance / 100)
		end
		if levelRow.DamageMultiplier and levelRow.DamageMultiplier ~= 0 then
			addLevelMod('skill("baseMultiplier", {val})', levelRow.DamageMultiplier / 10000 + 1)
		end
		if levelRow.ManaReservationOverride ~= 0 then
			addLevelMod('skill("manaCostOverride", {val})', levelRow.ManaReservationOverride)
		end
		if levelRow.Cooldown and levelRow.Cooldown ~= 0 then
			addLevelMod('skill("cooldown", {val})', levelRow.Cooldown / 1000)
		end
		for i, statKey in ipairs(levelRow.StatsKeys) do
			local statId = Stats[statKey].Id
			if not statMap[statId] then
				statMap[statId] = #skill.stats + 1
				table.insert(skill.stats, { id = statId })
			end
			skill.statInterpolation[i] = levelRow.StatInterpolationTypesKeys[i]
			if skill.statInterpolation[i] == 3 and levelRow.EffectivenessCostConstantsKeys[i] ~= 2 then
				table.insert(skill.stats[statMap[statId]], levelRow["Stat"..i.."Float"] / EffectivenessCostConstants[levelRow.EffectivenessCostConstantsKeys[i]].Multiplier)
			else
				table.insert(skill.stats[statMap[statId]], levelRow["Stat"..i.."Value"])
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
	addMod(skill.mods, args)
end

-- #levelMod <mod definition>==<val>[ <val>[...]]
-- Adds a per-level modifier to the skill
directiveTable.levelMod = function(state, args, out)
	local skill = state.skill
	local def, vals = args:match("(.*)==(.*)")
	local mod = addMod(skill.mods, def)
	mod.perLevel = true
	local i = 1
	for _, level in ipairs(skill.levels) do
		local s, e, val = vals:find("([%+%-]?[%d%.]+)", i)
		mod.levels[level.level] = tonumber(val)
		i = e + 1
	end
end

-- #setLevelVals <index>==<val>[ <val>[...]]
-- Overrides the values of the given level modifier
directiveTable.setLevelVals = function(state, args, out)
	local skill = state.skill
	local index, vals = args:match("(.*)==(.*)")
	index = tonumber(index)
	for _, mod in ipairs(skill.mods) do
		if mod.perLevel then
			index = index - 1
			if index == 0 then
				local i = 1
				for _, level in ipairs(skill.levels) do
					local s, e, val = vals:find("([%+%-]?[%d%.]+)", i)
					mod.levels[level.level] = tonumber(val)
					i = e + 1
				end
				break
			end
		end
	end
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
	out:write('\tstatLevels = {\n')
	for index, level in ipairs(skill.levels) do
		out:write('\t\t[', level.level, '] = { ')
		for _, stat in ipairs(skill.stats) do
			out:write(tostring(stat[index]), ', ')
		end
		out:write('},\n')
	end
	out:write('\t},\n')
	out:write('\tbaseMods = {\n')
	for _, mod in ipairs(skill.mods) do
		if not mod.perLevel then
			out:write('\t\t', mod.def:gsub("{val}",(mod.val or 0)*mod.mult), ',\n')
		end
	end
	out:write('\t},\n')
	out:write('\tlevelMods = {\n')
	local lcol = 1
	for _, mod in ipairs(skill.mods) do
		if mod.perLevel then
			out:write('\t\t[', lcol, '] = ', mod.def:gsub("{val}","nil"), ',\n')
			mod.col = lcol
			lcol = lcol + 1
		end
	end
	out:write('\t},\n')
	out:write('\tlevels = {\n')
	for _, level in ipairs(skill.levels) do
		out:write('\t\t[', level.level, '] = { ')
		for _, mod in ipairs(skill.mods) do
			if mod.perLevel then
				if mod.levels[level.level] then
					out:write(tostring(mod.levels[level.level] * mod.mult), ', ')
				else
					out:write('nil, ')
				end
			end
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

local out = io.open("../Data/3_0/Gems.lua", "w")
out:write('-- This file is automatically generated, do not edit!\n')
out:write('-- Gem data (c) Grinding Gear Games\n\nreturn {\n')
for skillGemKey = 0, SkillGems.maxRow do
	if gems[skillGemKey] then
		local skillGem = SkillGems[skillGemKey] 
		local baseItemType = BaseItemTypes[skillGem.BaseItemTypesKey]
		out:write('\t["', wellShitIGotThoseWrong[baseItemType.Id] or baseItemType.Id, '"] = {\n')
		out:write('\t\tname = "', baseItemType.Name:gsub(" Support",""), '",\n')
		--local gemId, gemName = dammitChris(GrantedEffects[skillGem.GrantedEffectsKey].Id)
		--out:write('\t["', gemId, '"] = {\n')
		--out:write('\t\tname = "', gemName, '",\n')
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