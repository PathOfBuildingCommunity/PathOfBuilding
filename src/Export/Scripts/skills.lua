local skillTypes = {
	"Attack",
	"Spell",
	"Projectile",
	"DualWieldOnly",
	"Buff",
	"Minion",
	"Damage",
	"Area",
	"Duration",
	"RequiresShield",
	"ProjectileSpeed",
	"HasReservation",
	"ReservationBecomesCost",
	"Trappable",
	"Totemable",
	"Mineable",
	"ElementalStatus",
	"MinionsCanExplode",
	"Chains",
	"Melee",
	"MeleeSingleTarget",
	"Multicastable",
	"TotemCastsAlone",
	"Multistrikeable",
	"CausesBurning",
	"SummonsTotem",
	"TotemCastsWhenNotDetached",
	"Physical",
	"Fire",
	"Cold",
	"Lightning",
	"Triggerable",
	"Trapped",
	"Movement",
	"DamageOverTime",
	"RemoteMined",
	"Triggered",
	"Vaal",
	"Aura",
	"CanTargetUnusableCorpse",
	"RangedAttack",
	"Chaos",
	"FixedSpeedProjectile",
	"ThresholdJewelArea",
	"ThresholdJewelProjectile",
	"ThresholdJewelDuration",
	"ThresholdJewelRangedAttack",
	"Channel",
	"DegenOnlySpellDamage",
	"InbuiltTrigger",
	"Golem",
	"Herald",
	"AuraAffectsEnemies",
	"NoRuthless",
	"ThresholdJewelSpellDamage",
	"Cascadable",
	"ProjectilesFromUser",
	"MirageArcherCanUse",
	"ProjectileSpiral",
	"SingleMainProjectile",
	"MinionsPersistWhenSkillRemoved",
	"ProjectileNumber",
	"Warcry",
	"Instant",
	"Brand",
	"DestroysCorpse",
	"NonHitChill",
	"ChillingArea",
	"AppliesCurse",
	"CanRapidFire",
	"AuraDuration",
	"AreaSpell",
	"OR",
	"AND",
	"NOT",
	"AppliesMaim",
	"CreatesMinion",
	"Guard",
	"Travel",
	"Blink",
	"CanHaveBlessing",
	"ProjectilesNotFromUser",
	"AttackInPlaceIsDefault",
	"Nova",
	"InstantNoRepeatWhenHeld",
	"InstantShiftAttackForLeftMouse",
	"AuraNotOnCaster",
	"Banner",
	"Rain",
	"Cooldown",
	"ThresholdJewelChaining",
	"Slam",
	"Stance",
	"NonRepeatable",
	"OtherThingUsesSkill",
	"Steel",
	"Hex",
	"Mark",
	"Aegis",
	"Orb",
	"KillNoDamageModifiers",
	"RandomElement",
	"LateConsumeCooldown",
	"Arcane",
	"FixedCastTime",
	"RequiresOffHandNotWeapon",
	"Link",
}

local function mapAST(ast)
	return "SkillType."..(skillTypes[ast._rowIndex] or ("Unknown"..ast._rowIndex))
end

local weaponClassMap = {
	["Claw"] = "Claw",
	["Dagger"] = "Dagger",
	["Wand"] = "Wand",
	["One Hand Sword"] = "One Handed Sword",
	["Thrusting One Hand Sword"] = "Thrusting One Handed Sword",
	["One Hand Axe"] = "One Handed Axe",
	["One Hand Mace"] = "One Handed Mace",
	["Bow"] = "Bow",
	["Fishing Rod"] = "Fishing Rod",
	["Staff"] = "Staff",
	["Two Hand Sword"] = "Two Handed Sword",
	["Two Hand Axe"] = "Two Handed Axe",
	["Two Hand Mace"] = "Two Handed Mace",
	["Sceptre"] = "Sceptre",
	["Unarmed"] = "None",
}

local skillStatScope = { }
do
	local text = convertUTF16to8(getFile("Metadata/StatDescriptions/skillpopup_stat_filters.txt"))
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
	local granted = dat("GrantedEffects"):GetRow("Id", grantedId)
	if not granted then
		ConPrintf('Unknown GE: "'..grantedId..'"')
		return
	end
	local skillGem = dat("SkillGems"):GetRow("GrantedEffect", granted) or dat("SkillGems"):GetRow("SecondaryGrantedEffect", granted)
	local skill = { }
	state.skill = skill
	if skillGem and not state.noGem then
		gems[skillGem] = true
		if granted.IsSupport then
			out:write('\tname = "', skillGem.BaseItemType.Name:gsub(" Support",""), '",\n')
			if #skillGem.Description > 0 then
				out:write('\tdescription = "', skillGem.Description:gsub('\n','\\n'), '",\n')
			end
		else
			out:write('\tname = "', granted.ActiveSkill.DisplayName, '",\n')
		end
	else
		if displayName == args and not granted.IsSupport then
			displayName = granted.ActiveSkill.DisplayName
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
	out:write('\tcolor = ', granted.Attribute, ',\n')
	if granted.BaseEffectiveness ~= 1 then
		out:write('\tbaseEffectiveness = ', granted.BaseEffectiveness, ',\n')
	end
	if granted.IncrementalEffectiveness ~= 0 then
		out:write('\tincrementalEffectiveness = ', granted.IncrementalEffectiveness, ',\n')
	end
	if granted.IsSupport then
		skill.isSupport = true
		out:write('\tsupport = true,\n')
		out:write('\trequireSkillTypes = { ')
		for _, type in ipairs(granted.SupportTypes) do
			out:write(mapAST(type), ', ')
		end
		out:write('},\n')
		out:write('\taddSkillTypes = { ')
		for _, type in ipairs(granted.AddTypes) do
			out:write(mapAST(type), ', ')
		end
		out:write('},\n')
		out:write('\texcludeSkillTypes = { ')
		for _, type in ipairs(granted.ExcludeTypes) do
			out:write(mapAST(type), ', ')
		end
		out:write('},\n')
		if granted.SupportGemsOnly then
			out:write('\tsupportGemsOnly = true,\n')
		end
		if granted.IgnoreMinionTypes then
			out:write('\tignoreMinionTypes = true,\n')
		end
		if granted.PlusVersionOf then
			out:write('\tplusVersionOf = "', granted.PlusVersionOf.Id, '",\n')
		end
		local weaponTypes = { }
		for _, class in ipairs(granted.WeaponRestrictions) do
			if weaponClassMap[class.Id] then
				weaponTypes[weaponClassMap[class.Id]] = true
			end
		end
		if next(weaponTypes) then
			out:write('\tweaponTypes = {\n')
			for type in pairs(weaponTypes) do
				out:write('\t\t["', type, '"] = true,\n')
			end
			out:write('\t},\n')
		end
		out:write('\tstatDescriptionScope = "gem_stat_descriptions",\n')
	else
		if #granted.ActiveSkill.Description > 0 then
			out:write('\tdescription = "', granted.ActiveSkill.Description:gsub('"','\\"'), '",\n')
		end
		out:write('\tskillTypes = { ')
		for _, type in ipairs(granted.ActiveSkill.SkillTypes) do
			out:write('[', mapAST(type), '] = true, ')
		end
		out:write('},\n')
		if granted.ActiveSkill.MinionSkillTypes[1] then
			out:write('\tminionSkillTypes = { ')
			for _, type in ipairs(granted.ActiveSkill.MinionSkillTypes) do
				out:write('[', mapAST(type), '] = true, ')
			end
			out:write('},\n')
		end
		local weaponTypes = { }
		for _, class in ipairs(granted.ActiveSkill.WeaponRestrictions) do
			if weaponClassMap[class.Id] then
				weaponTypes[weaponClassMap[class.Id]] = true
			end
		end
		if next(weaponTypes) then
			out:write('\tweaponTypes = {\n')
			for type in pairs(weaponTypes) do
				out:write('\t\t["', type, '"] = true,\n')
			end
			out:write('\t},\n')
		end
		out:write('\tstatDescriptionScope = "', skillStatScope[granted.ActiveSkill.Id] or "skill_stat_descriptions", '",\n')
		if granted.ActiveSkill.SkillTotem <= dat("SkillTotems").rowCount then
			out:write('\tskillTotemId = ', granted.ActiveSkill.SkillTotem, ',\n')
		end
		out:write('\tcastTime = ', granted.CastTime / 1000, ',\n')
		if granted.CannotBeSupported then
			out:write('\tcannotBeSupported = true,\n')
		end
	end
	for _, levelRow in ipairs(dat("GrantedEffectsPerLevel"):GetRowList("GrantedEffect", granted)) do
		local level = { extra = { }, statInterpolation = { }, cost = { } }
		level.level = levelRow.Level
		level.extra.levelRequirement = levelRow.PlayerLevel
		for i, cost in ipairs(levelRow.CostTypes) do
			level.cost[cost["Resource"]] = levelRow.CostAmounts[i]
		end
		if levelRow.ManaReservationFlat ~= 0 then
			level.extra.manaReservationFlat = levelRow.ManaReservationFlat
		end
		if levelRow.ManaReservationPercent ~= 0 then
			level.extra.manaReservationPercent = levelRow.ManaReservationPercent / 100
		end
		if levelRow.LifeReservationFlat ~= 0 then
			level.extra.lifeReservationFlat = levelRow.LifeReservationFlat
		end
		if levelRow.LifeReservationPercent ~= 0 then
			level.extra.lifeReservationPercent = levelRow.LifeReservationPercent / 100
		end
		if levelRow.ManaMultiplier ~= 100 then
			level.extra.manaMultiplier = levelRow.ManaMultiplier - 100
		end
		if levelRow.DamageEffectiveness ~= 0 then
			level.extra.damageEffectiveness = levelRow.DamageEffectiveness / 100 + 1
		end
		if levelRow.SpellCritChance ~= 0 then
			level.extra.critChance = levelRow.SpellCritChance / 100
		end
		if levelRow.OffhandCritChance ~= 0 then
			level.extra.critChance = levelRow.OffhandCritChance / 100
		end
		if levelRow.DamageMultiplier and levelRow.DamageMultiplier ~= 0 then
			level.extra.baseMultiplier = levelRow.DamageMultiplier / 10000 + 1
		end
		if levelRow.AttackSpeedMultiplier and levelRow.AttackSpeedMultiplier ~= 0 then
			level.extra.attackSpeedMultiplier = levelRow.AttackSpeedMultiplier
		end
		if levelRow.AttackTime ~= 0 then
			level.extra.attackTime = levelRow.AttackTime
		end
		if levelRow.Cooldown and levelRow.Cooldown ~= 0 then
			level.extra.cooldown = levelRow.Cooldown / 1000
		end
		if levelRow.Duration and levelRow.Duration ~= 0 then
			level.extra.duration = levelRow.Duration / 1000
		end
		for i, stat in ipairs(levelRow.Stats) do
			if not statMap[stat.Id] then
				statMap[stat.Id] = #skill.stats + 1
				table.insert(skill.stats, { id = stat.Id })
			end
			level.statInterpolation[i] = levelRow.InterpolationTypes[i]
			if level.statInterpolation[i] == 3 then
				if levelRow.EffectivenessCost[i].Value ~= 0 then
					table.insert(level, levelRow["StatEff"..i] / levelRow.EffectivenessCost[i].Value)
				else
					level.statInterpolation[i] = 1
					table.insert(level, levelRow["Stat"..i])
				end
			else
				table.insert(level, levelRow["Stat"..i])
			end
		end
		for i, stat in ipairs(levelRow.BooleanStats) do
			if not statMap[stat.Id] then
				statMap[stat.Id] = #skill.stats + 1
				table.insert(skill.stats, { id = stat.Id })
			end
		end
		table.insert(skill.levels, level)
	end
	if not skill.qualityStats then
		skill.qualityStats = { }
		for i, qualityStatsRow in ipairs(dat("GrantedEffectQualityStats"):GetRowList("GrantedEffect", granted)) do
			skill.qualityStats[i] = { }
			for j, stat in ipairs(qualityStatsRow.GrantedStats) do
				table.insert(skill.qualityStats[i], { stat.Id, qualityStatsRow.StatValues[j] / 1000 })
				--ConPrintf("[%d] %s %s", i, granted.ActiveSkill.DisplayName, stat.Id)
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
	for i, alternates in ipairs(skill.qualityStats) do
		if i == 1 then
			out:write('\t\tDefault = {\n')
		else
			local value = i - 1
			out:write('\t\tAlternate' .. value .. ' = {\n')
		end
		for _, stat in ipairs(alternates) do
			out:write('\t\t\t{ "', stat[1], '", ', stat[2], ' },\n')
		end
		out:write('\t\t},\n')
	end
	out:write('\t},\n')
	out:write('\tstats = {\n')
	for _, stat in ipairs(skill.stats) do
		out:write('\t\t"', stat.id, '",\n')
	end
	out:write('\t},\n')
	out:write('\tlevels = {\n')
	for index, level in ipairs(skill.levels) do
		out:write('\t\t[', level.level, '] = { ')
		for _, statVal in ipairs(level) do
			out:write(tostring(statVal), ', ')
		end
		for k, v in pairs(level.extra) do
			out:write(k, ' = ', tostring(v), ', ')
		end
		out:write('statInterpolation = { ')
		for _, type in ipairs(level.statInterpolation) do
			out:write(type, ', ')
		end
		out:write('}, ')
		out:write('cost = { ')
		for k, v in pairs(level.cost) do
			out:write(k, ' = ', tostring(v), ', ')
		end
		out:write('}, ')
		out:write('},\n')
	end
	out:write('\t},\n')
	out:write('}')
	state.skill = nil
end

for _, name in pairs({"act_str","act_dex","act_int","other","glove","minion","spectre","sup_str","sup_dex","sup_int"}) do
	processTemplateFile(name, "Skills/", "../Data/Skills/", directiveTable)
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

local out = io.open("../Data/Gems.lua", "w")
out:write('-- This file is automatically generated, do not edit!\n')
out:write('-- Gem data (c) Grinding Gear Games\n\nreturn {\n')
for skillGem in dat("SkillGems"):Rows() do
	if gems[skillGem] then
		out:write('\t["', wellShitIGotThoseWrong[skillGem.BaseItemType.Id] or skillGem.BaseItemType.Id, '"] = {\n')
		out:write('\t\tname = "', skillGem.BaseItemType.Name:gsub(" Support",""), '",\n')
		out:write('\t\tgrantedEffectId = "', skillGem.GrantedEffect.Id, '",\n')
		if skillGem.SecondaryGrantedEffect then
			out:write('\t\tsecondaryGrantedEffectId = "', skillGem.SecondaryGrantedEffect.Id, '",\n')
		end
		if #skillGem.SecondarySupportName > 0 then
			out:write('\t\tsecondaryEffectName = "', skillGem.SecondarySupportName, '",\n')
		end
		if skillGem.IsVaalGem then
			out:write('\t\tvaalGem = true,\n')
		end
		local tagNames = { }
		out:write('\t\ttags = {\n')
		for _, tag in ipairs(skillGem.Tags) do
			out:write('\t\t\t', tag.Id, ' = true,\n')
			if #tag.Name > 0 then
				table.insert(tagNames, tag.Name)
			end
		end
		out:write('\t\t},\n')
		out:write('\t\ttagString = "', table.concat(tagNames, ", "), '",\n')
		out:write('\t\treqStr = ', skillGem.Str, ',\n')
		out:write('\t\treqDex = ', skillGem.Dex, ',\n')
		out:write('\t\treqInt = ', skillGem.Int, ',\n')
		local defaultLevel = #dat("ItemExperiencePerLevel"):GetRowList("BaseItemType", skillGem.BaseItemType)
		out:write('\t\tdefaultLevel = ', defaultLevel > 0 and defaultLevel or 1, ',\n')
		out:write('\t},\n')
	end
end
out:write('}')
out:close()

print("Skill data exported.")
