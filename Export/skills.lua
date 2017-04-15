#@

dofile("_common.lua")

loadDat("SkillGems")
loadDat("BaseItemTypes")
loadDat("ActiveSkills")
loadDat("GemTags")
loadDat("Stats")
loadDat("GrantedEffects")
loadDat("GrantedEffectsPerLevel")

while true do

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

local gem

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

local weaponClassMap = {
	[6] = "Claw",
	[7] = "Dagger",
	[8] = "Wand",
	[9] = "One Handed Sword",
	[10] = "One Handed Sword",
	[11] = "One Handed Axe",
	[12] = "One Handed Mace",
	[13] = "Bow",
	[14] = "Staff",
	[15] = "Two Handed Sword",
	[16] = "Two Handed Axe",
	[17] = "Two Handed Mace",
	[32] = "One Handed Mace",
	[36] = "None",
}

for _, name in pairs({"act_str","act_dex","act_int","other","minion","spectre","sup_str","sup_dex","sup_int"}) do
	local out = io.open("Skills/"..name..".lua", "w")
	for line in io.lines("Skills/"..name..".txt") do
		local spec, args = line:match("#(%a+) ?(.*)")
		if spec then
			if spec == "skill" then
				local grantedId, displayName = args:match("(%w+) (.+)")
				if not grantedId then
					grantedId = args
					displayName = args
				end
				out:write('skills["'..grantedId..'"] = {\n')
				local grantedKey = GrantedEffects.Id(grantedId)[1]
				local granted = GrantedEffects[grantedKey]
				local skillGemKey = SkillGems.GrantedEffectsKey(grantedKey)[1]
				gem = { }
				if skillGemKey then
					out:write('\tname = "'..BaseItemTypes[SkillGems[skillGemKey].BaseItemTypesKey].Name:gsub(" Support","")..'",\n')
					out:write('\tgemTags = {\n')
					for _, tagKey in pairs(SkillGems[skillGemKey].GemTagsKeys) do
						out:write('\t\t'..GemTags[tagKey].Id..' = true,\n')
					end
					out:write('\t},\n')
				else
					out:write('\tname = "'..displayName..'",\n')
					out:write('\thidden = true,\n')
					if name == "other" then
						out:write('\tother = true,\n')
					end
				end
				gem.baseFlags = { }
				gem.mods = { }
				local modMap = { }
				gem.levels = { }
				gem.global = "nil"
				gem.curse = "nil"
				gem.color = granted.Unknown0
				if granted.IsSupport then
					gem.requireSkillTypes = granted.Data0
					gem.addSkillTypes = granted.Data1
					gem.excludeSkillTypes = granted.Data2
					gem.isSupport = true
					out:write('\tsupport = true,\n')
				else
					local activeSkill = ActiveSkills[granted.ActiveSkillsKey]
					gem.skillTypes = activeSkill.ActiveSkillTypes
					if activeSkill.Unknown19[1] then
						gem.minionSkillTypes = activeSkill.Unknown19
					end
					if activeSkill.SkillTotemId ~= 16 then
						gem.skillTotemId = activeSkill.SkillTotemId
					end
					gem.weaponTypes = { }
					for _, classKey in ipairs(activeSkill.WeaponRestriction_ItemClassesKeys) do
						if weaponClassMap[classKey] then
							gem.weaponTypes[weaponClassMap[classKey]] = true
						end
					end
					local typeFlag = { }
					for _, type in ipairs(gem.skillTypes) do
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
					local function addLevelMod(statKey, value)
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
						mod.levels[levelRow.Level] = value
					end
					if not granted.IsSupport then
						addLevelMod('skill("levelRequirement", {val})', levelRow.LevelRequirement)
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
						addLevelMod('skill("critChance", {val})', levelRow.CriticalStrikeChance / 100)
					end
					if levelRow.DamageMultiplier and levelRow.DamageMultiplier ~= 0 then
						addLevelMod('mod("Damage", "MORE", {val}, ModFlag.Attack)', levelRow.DamageMultiplier / 100)
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
			elseif spec == "global" then
				gem.global = '{ type = "GlobalEffect", effectType = "'..args..'" }'
			elseif spec == "flags" then
				for flag in args:gmatch("%a+") do
					table.insert(gem.baseFlags, flag)
				end
			elseif spec == "baseMod" then
				addMod(gem.mods, args)
			elseif spec == "levelMod" then
				local def, vals = args:match("(.*)==(.*)")
				local mod = addMod(gem.mods, def)
				mod.perLevel = true
				local i = 1
				for _, level in ipairs(gem.levels) do
					local s, e, val = vals:find("([%+%-]?[%d%.]+)", i)
					mod.levels[level.level] = tonumber(val)
					i = e + 1
				end
			elseif spec == "setMod" then
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
			elseif spec == "mods" then
				out:write('\tcolor = '..gem.color..',\n')
				if not gem.isSupport then
					out:write('\tbaseFlags = {\n')
					for _, flag in ipairs(gem.baseFlags) do
						out:write('\t\t'..flag..' = true,\n')
					end		
					out:write('\t},\n')
				end
				if gem.skillTypes then
					out:write('\tskillTypes = { ')
					for _, type in ipairs(gem.skillTypes) do
						out:write('['..type..'] = true, ')
					end
					out:write('},\n')
				end
				if gem.minionSkillTypes then
					out:write('\tminionSkillTypes = { ')
					for _, type in ipairs(gem.minionSkillTypes) do
						out:write('['..type..'] = true, ')
					end
					out:write('},\n')
				end
				if gem.weaponTypes and next(gem.weaponTypes) then
					out:write('\tweaponTypes = {\n')
					for type in pairs(gem.weaponTypes) do
						out:write('\t\t["'..type..'"] = true,\n')
					end
					out:write('\t},\n')
				end
				if gem.skillTotemId then
					out:write('\tskillTotemId = '..gem.skillTotemId..',\n')
				end
				for _, field in ipairs({"requireSkillTypes","addSkillTypes","excludeSkillTypes"}) do
					if gem[field] then
						out:write('\t'..field..' = { ')
						for _, type in ipairs(gem[field]) do
							out:write(type..', ')
						end
						out:write('},\n')
					end
				end
				out:write('\tbaseMods = {\n')
				for _, mod in ipairs(gem.mods) do
					if not mod.perLevel then
						out:write('\t\t')
						if mod.def then
							out:write(mod.def:gsub("{val}",(mod.val or 0)*mod.mult):gsub("{global}",gem.global):gsub("{curse}",gem.curse)..', ')
						end
						if mod.id then
							out:write('--"'..mod.id..'" = '..(mod.val or "?"))
						end
						out:write('\n')
					end
				end
				out:write('\t},\n')
				out:write('\tqualityMods = {\n')
				for _, mod in ipairs(gem.qualityMods) do
					out:write('\t\t')
					if mod.def then
						out:write(mod.def:gsub("{val}",mod.levels[1]*mod.mult):gsub("{global}",gem.global):gsub("{curse}",gem.curse)..', ')
					end
					if mod.id then
						out:write('--"'..mod.id..'" = '..mod.levels[1])
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
							out:write('['..lcol..'] = '..mod.def:gsub("{val}","nil"):gsub("{global}",gem.global):gsub("{curse}",gem.curse)..', ')
							if mod.id then
								out:write('--"'..mod.id..'"')
							end
							out:write('\n')
						else
							out:write('--['..lcol..'] = "'..mod.id..'"\n')
						end
						mod.col = lcol
						lcol = lcol + 1
					end
				end
				out:write('\t},\n')
				out:write('\tlevels = {\n')
				for _, level in ipairs(gem.levels) do
					out:write('\t\t['..level.level..'] = { ')
					for _, mod in ipairs(gem.mods) do
						if mod.perLevel then
							if mod.levels[level.level] then
								out:write(tostring(mod.levels[level.level] * mod.mult)..', ')
							else
								out:write('nil, ')
							end
						end
					end
					out:write('},\n')
				end
				out:write('\t},\n')
				out:write('}')
			end
		else
			out:write(line.."\n")
		end
	end
	out:close()
end

print("Gem data exported.")

os.execute("xcopy Skills\\*.lua ..\\Data\\Skills\\ /Y")

if io.read("*l") ~= "" then
	break
end
end
os.execute("pause")
