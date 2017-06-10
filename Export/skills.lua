local statMap = { }
do
	local lastStat
	for line in io.lines("Skills/statmap.ini") do
		local statName = line:match("^%[([^]]+)%]$")
		if statName then
			if lastStat and not lastStat.def then
				statMap[statName] = lastStat
			else
				statMap[statName] = { mult = 1 }
				lastStat = statMap[statName]
			end
		else
			local key, value = line:match("^(%a+) = (.+)$")
			if key == "mod" then
				lastStat.def = value
			elseif key == "mult" then
				lastStat.mult = tonumber(value)
			elseif key == "div" then
				lastStat.mult = 1 / tonumber(value)
			end
		end
	end
end

local function addMod(mods, statKey, value)
	local mod = {
		key = statKey, 
		id = Stats[statKey] and Stats[statKey].Id,
		mult = 1,
		val = value,
		levels = { value },
	}
	if mod.id then
		local map = statMap[mod.id]
		if map then
			mod.def = map.def
			mod.mult = map.mult
		end
	else
		mod.def = statKey
	end
	table.insert(mods, mod)
	return mod
end

-- Skill types:
-- 1	Attack
-- 2	Spell
-- 3	Fires projectiles
-- 4	Dual wield skill (Only on Dual Strike)
-- 5	Buff
-- 6	Can use while dual wielding
-- 7	Only uses main hand
-- 8	Combines both weapons? (Only on Cleave)
-- 9	Minion skill
-- 10	Spell with hit damage
-- 11	Area
-- 12	Duration
-- 13	Shield skill
-- 14	Projectile damage
-- 15	Mana cost is reservation
-- 16	Mana cost is percentage
-- 17	Skill can be trap?
-- 18	Spell can be totem?
-- 19	Skill can be mine?
-- 20	Causes status effects (Only on Herald of Ash, allows Elemental Proliferation)
-- 21	Creates minions
-- 22	Attack can be totem?
-- 23	Chaining
-- 24	Melee
-- 25	Single target melee
-- 26	Spell can multicast
-- 27	?? (On auras, searing bond, tempest shield, blade vortex and others)
-- 28	Attack can multistrike
-- 29	Burning
-- 30	Totem
-- 31	?? (On Molten Shell + Glove Thunder, applied by Blasphemy)
-- 32	Curse
-- 33	Fire skill
-- 34	Cold skill
-- 35	Lightning skill
-- 36	Triggerable spell
-- 37	Trap
-- 38	Movement
-- 39	Cast
-- 40	Damage over Time
-- 41	Mine
-- 42	Triggered spell
-- 43	Vaal
-- 44	Aura
-- 45	Lightning spell
-- 46	?? (Not on any skills or supports)
-- 47	Triggered attack
-- 48	Projectile attack
-- 49	Minion spell
-- 50	Chaos skill
-- 51	?? (Not on any skills, excluded by Faster/Slower Projectiles)
-- 52	?? (Only on Contagion, allows Iron Will)
-- 53	?? (Only on Burning Arrow/Vigilant Strike, allows Inc AoE + Conc Effect)
-- 54	Projectile? (Not on any skills, allows all projectile supports)
-- 55	?? (Only on Burning Arrow/VBA, allows Inc/Red Duration + Rapid Decay)
-- 56	Projectile attack? (Not on any skills, allows projectile attack supports)
-- 57	?? Same as 47
-- 58	Channelled
-- 59	?? (Only on Contagion, allows Controlled Destruction)
-- 60	Cold spell
-- 61	Granted triggered skill (Prevents trigger supports, trap, mine, totem)
-- 62	Golem
-- 63	Herald

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

local directiveTable = { }

-- #skill <GrantedEffectId> [<Display name>]
-- Initialises the gem data and emits the skill header
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
	local gem = { }
	state.gem = gem
	if skillGemKey then
		local skillGem = SkillGems[skillGemKey]
		out:write('\tname = "', BaseItemTypes[skillGem.BaseItemTypesKey].Name:gsub(" Support",""), '",\n')
		local tagNames = { }
		out:write('\tgemTags = {\n')
		for i, tagKey in ipairs(skillGem.GemTagsKeys) do
			out:write('\t\t', GemTags[tagKey].Id, ' = true,\n')
			if #GemTags[tagKey].Tag > 0 then
				table.insert(tagNames, GemTags[tagKey].Tag)
			end
		end
		out:write('\t},\n')
		out:write('\tgemTagString = "', table.concat(tagNames, ", "), '",\n')
		out:write('\tgemStr = ', skillGem.Str, ',\n')
		out:write('\tgemDex = ', skillGem.Dex, ',\n')
		out:write('\tgemInt = ', skillGem.Int, ',\n')
	else
		out:write('\tname = "', displayName, '",\n')
		out:write('\thidden = true,\n')
	end
	gem.baseFlags = { }
	gem.mods = { }
	local modMap = { }
	gem.levels = { }
	gem.global = "nil"
	gem.curse = "nil"
	out:write('\tcolor = ', granted.Unknown0, ',\n')
	if granted.IsSupport then
		gem.isSupport = true
		out:write('\tsupport = true,\n')
		out:write('\trequireSkillTypes = { ')
		for _, type in ipairs(granted.Data0) do
			out:write(type, ', ')
		end
		out:write('},\n')
		out:write('\taddSkillTypes = { ')
		for _, type in ipairs(granted.Data1) do
			out:write(type, ', ')
		end
		out:write('},\n')
		out:write('\texcludeSkillTypes = { ')
		for _, type in ipairs(granted.Data2) do
			out:write(type, ', ')
		end
		out:write('},\n')
	else
		local activeSkill = ActiveSkills[granted.ActiveSkillsKey]
		if #activeSkill.Description > 0 then
			out:write('\tdescription = "', activeSkill.Description, '",\n')
		end
		out:write('\tskillTypes = { ')
		for _, type in ipairs(activeSkill.ActiveSkillTypes) do
			out:write('[', type, '] = true, ')
		end
		out:write('},\n')
		if activeSkill.Unknown19[1] then
			out:write('\tminionSkillTypes = { ')
			for _, type in ipairs(activeSkill.Unknown19) do
				out:write('[', type, '] = true, ')
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
		if activeSkill.SkillTotemId ~= 16 then
			out:write('\tskillTotemId = ', activeSkill.SkillTotemId, ',\n')
		end
		local typeFlag = { }
		for _, type in ipairs(activeSkill.ActiveSkillTypes) do
			typeFlag[type] = true
		end
		if typeFlag[32] then
			gem.global = '{ type = "GlobalEffect", effectType = "Curse" }'
			gem.curse = gem.global
		elseif typeFlag[44] then
			gem.global = '{ type = "GlobalEffect", effectType = "Aura" }'
		elseif typeFlag[5] or typeFlag[31] then
			gem.global = '{ type = "GlobalEffect", effectType = "Buff" }'
		end
		addMod(gem.mods, 'skill("castTime", {val})', granted.CastTime / 1000)
	end
	for _, key in ipairs(GrantedEffectsPerLevel.GrantedEffectsKey(grantedKey)) do
		local level = { }
		local levelRow = GrantedEffectsPerLevel[key]
		level.level = levelRow.Level
		table.insert(gem.levels, level)
		local function addLevelMod(statKey, value, forcePerLevel)
			local mod = gem.mods[modMap[statKey]]
			if mod then
				if value ~= mod.val then
					mod.perLevel = true
				end
			else
				modMap[statKey] = #gem.mods + 1
				addMod(gem.mods, statKey)
				mod = gem.mods[modMap[statKey]]
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
			addLevelMod(statKey, levelRow["Stat"..i.."Value"])
		end
		for i, statKey in ipairs(levelRow.StatsKeys2) do
			addLevelMod(statKey)
		end
		if not gem.qualityMods then
			gem.qualityMods = { }
			for i, statKey in ipairs(levelRow.Quality_StatsKeys) do
				addMod(gem.qualityMods, statKey, levelRow.Quality_Values[i] / 1000)
			end
		end
	end
end

-- #global <Buff|Aura|Debuff|Curse>
-- Sets the global effect tag for this skill
directiveTable.global = function(state, args, out)
	local gem = state.gem
	gem.global = '{ type = "GlobalEffect", effectType = "'..args..'" }'
end

-- #flags <flag>[ <flag>[...]]
-- Sets the base flags for this active skill
directiveTable.flags = function(state, args, out)
	local gem = state.gem
	for flag in args:gmatch("%a+") do
		table.insert(gem.baseFlags, flag)
	end
end

-- #baseMod <mod definition>
-- Adds a base modifier to the skill
directiveTable.baseMod = function(state, args, out)
	local gem = state.gem
	addMod(gem.mods, args)
end

-- #levelMod <mod definition>==<val>[ <val>[...]]
-- Adds a per-level modifier to the skill
directiveTable.levelMod = function(state, args, out)
	local gem = state.gem
	local def, vals = args:match("(.*)==(.*)")
	local mod = addMod(gem.mods, def)
	mod.perLevel = true
	local i = 1
	for _, level in ipairs(gem.levels) do
		local s, e, val = vals:find("([%+%-]?[%d%.]+)", i)
		mod.levels[level.level] = tonumber(val)
		i = e + 1
	end
end

-- #setMod <StatId>==<mod definition[;<mult|div>=<val>]
-- Sets or overrides the mapping of the given stat
directiveTable.setMod = function(state, args, out)
	local gem = state.gem
	local id, def = args:match("(.*)==(.*)")
	for _, mod in ipairs(gem.mods) do
		if mod.id == id then
			local name, mult = def:match("(.*);mult=(.*)")
			if name then
				mod.def = name
				mod.mult = tonumber(mult)
			else
				local name, div = def:match("(.*);div=(.*)")
				if name then
					mod.def = name
					mod.mult = 1 / tonumber(div)
				else
					mod.def = def
				end
			end
		end
	end
end

-- #mods
-- Emits the skill modifiers
directiveTable.mods = function(state, args, out)
	local gem = state.gem
	if not gem.isSupport then
		out:write('\tbaseFlags = {\n')
		for _, flag in ipairs(gem.baseFlags) do
			out:write('\t\t', flag, ' = true,\n')
		end		
		out:write('\t},\n')
	end
	out:write('\tbaseMods = {\n')
	for _, mod in ipairs(gem.mods) do
		if not mod.perLevel then
			out:write('\t\t')
			if mod.def and mod.def ~= "nil" then
				out:write(mod.def:gsub("{val}",(mod.val or 0)*mod.mult):gsub("{global}",gem.global):gsub("{curse}",gem.curse), ', ')
			end
			if mod.id then
				out:write('--"', mod.id, '" = ', (mod.val or "?"))
			end
			out:write('\n')
		end
	end
	out:write('\t},\n')
	out:write('\tqualityMods = {\n')
	for _, mod in ipairs(gem.qualityMods) do
		out:write('\t\t')
		if mod.def then
			out:write(mod.def:gsub("{val}",mod.levels[1]*mod.mult):gsub("{global}",gem.global):gsub("{curse}",gem.curse), ', ')
		end
		if mod.id then
			out:write('--"', mod.id, '" = ', mod.levels[1])
		end
		out:write('\n')
	end
	out:write('\t},\n')
	out:write('\tlevelMods = {\n')
	local lcol = 1
	for _, mod in ipairs(gem.mods) do
		if mod.perLevel then
			out:write('\t\t')
			if mod.def then
				out:write('[', lcol, '] = ', mod.def:gsub("{val}","nil"):gsub("{global}",gem.global):gsub("{curse}",gem.curse), ', ')
				if mod.id then
					out:write('--"', mod.id, '"')
				end
				out:write('\n')
			else
				out:write('--[', lcol, '] = "', mod.id, '"\n')
			end
			mod.col = lcol
			lcol = lcol + 1
		end
	end
	out:write('\t},\n')
	out:write('\tlevels = {\n')
	for _, level in ipairs(gem.levels) do
		out:write('\t\t[', level.level, '] = { ')
		for _, mod in ipairs(gem.mods) do
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
	state.gem = nil
end

for _, name in pairs({"act_str","act_dex","act_int","other","minion","spectre","sup_str","sup_dex","sup_int"}) do
	processTemplateFile("Skills/"..name, directiveTable)
end

os.execute("xcopy Skills\\act_*.lua ..\\Data\\3_0\\Skills\\ /Y /Q")
os.execute("xcopy Skills\\sup_*.lua ..\\Data\\3_0\\Skills\\ /Y /Q")
os.execute("xcopy Skills\\other.lua ..\\Data\\3_0\\Skills\\ /Y /Q")

print("Skill data exported.")