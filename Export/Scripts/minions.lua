local modMap = { }
do
	local lastMod
	for line in io.lines("Minions/modmap.ini") do
		local statName = line:match("^%[([^]]+)%]$")
		if statName then
			modMap[statName] = { }
			lastMod = modMap[statName]
		elseif line:match("^[^#].+") then
			table.insert(lastMod, line)
		end
	end
end

local itemClassMap = {
	["Claw"] = "Claw",
	["Dagger"] = "Dagger",
	["Wand"] = "Wand",
	["One Hand Sword"] = "One Handed Sword",
	["Thrusting One Hand Sword"] = "One Handed Sword",
	["One Hand Axe"] = "One Handed Axe",
	["One Hand Mace"] = "One Handed Mace",
	["Bow"] = "Bow",
	["Staff"] = "Staff",
	["Two Hand Sword"] = "Two Handed Sword",
	["Two Hand Axe"] = "Two Handed Axe",
	["Two Hand Mace"] = "Two Handed Mace",
	["Shield"] = "Shield",
	["Sceptre"] = "One Handed Mace",
	["Unarmed"] = "None",
}

local directiveTable = { }

-- #monster <MonsterId> [<Name>]
directiveTable.monster = function(state, args, out)	
	local varietyId, name = args:match("(%S+) (%S+)")
	if not varietyId then
		varietyId = args
		name = args
	end
	state.varietyId = varietyId
	state.name = name
	state.limit = nil
	state.extraModList = { }
	state.extraSkillList = { }
end

-- #limit <LimitVarName>
directiveTable.limit = function(state, args, out)
	state.limit = args
end 

-- #mod <ModDecl>
directiveTable.mod = function(state, args, out)
	table.insert(state.extraModList, args)
end 

-- #skill <SkillId>
directiveTable.skill = function(state, args, out)
	table.insert(state.extraSkillList, args)
end 

-- #emit
directiveTable.emit = function(state, args, out)
	local monsterVariety = dat"MonsterVarieties":GetRow("Id", state.varietyId)
	if not monsterVariety then
		print("Invalid Variety: "..state.varietyId)
		return
	end
	out:write('minions["', state.name, '"] = {\n')
	out:write('\tname = "', monsterVariety.Name, '",\n')
	out:write('\tlife = ', (monsterVariety.LifeMultiplier/100), ',\n')
	if monsterVariety.Type.EnergyShield ~= 0 then
		out:write('\tenergyShield = ', (0.4 * monsterVariety.Type.EnergyShield / 100), ',\n')
	end
	if monsterVariety.Type.Armour ~= 0 then
		out:write('\tarmour = ', monsterVariety.Type.Armour / 100, ',\n')
	end
	out:write('\tfireResist = ', monsterVariety.Type.Resistances.FireMerciless, ',\n')
	out:write('\tcoldResist = ', monsterVariety.Type.Resistances.ColdMerciless, ',\n')
	out:write('\tlightningResist = ', monsterVariety.Type.Resistances.LightningMerciless, ',\n')
	out:write('\tchaosResist = ', monsterVariety.Type.Resistances.ChaosMerciless, ',\n')
	out:write('\tdamage = ', (monsterVariety.DamageMultiplier/100), ',\n')
	out:write('\tdamageSpread = ', (monsterVariety.Type.DamageSpread / 100), ',\n')
	out:write('\tattackTime = ', (monsterVariety.AttackDuration/1000), ',\n')
	out:write('\tattackRange = ', monsterVariety.MaximumAttackRange, ',\n')
	out:write('\taccuracy = ', monsterVariety.Type.Accuracy / 100, ',\n')
	for _, mod in ipairs(monsterVariety.Mods) do
		if mod.Id == "MonsterSpeedAndDamageFixupSmall" then
			out:write('\tdamageFixup = 0.11,\n')
		elseif mod.Id == "MonsterSpeedAndDamageFixupLarge" then
			out:write('\tdamageFixup = 0.22,\n')
		elseif mod.Id == "MonsterSpeedAndDamageFixupComplete" then
			out:write('\tdamageFixup = 0.33,\n')
		end
	end
	if monsterVariety.MainHandItemClass and itemClassMap[monsterVariety.MainHandItemClass.Id] then
		out:write('\tweaponType1 = "', itemClassMap[monsterVariety.MainHandItemClass.Id], '",\n')
	end
	if monsterVariety.OffHandItemClass and itemClassMap[monsterVariety.OffHandItemClass.Id] then
		out:write('\tweaponType2 = "', itemClassMap[monsterVariety.OffHandItemClass.Id], '",\n')
	end
	if state.limit then
		out:write('\tlimit = "', state.limit, '",\n')
	end
	out:write('\tskillList = {\n')
	for _, grantedEffect in ipairs(monsterVariety.GrantedEffects) do
		out:write('\t\t"', grantedEffect.Id, '",\n')
	end
	for _, skill in ipairs(state.extraSkillList) do
		out:write('\t\t"', skill, '",\n')
	end
	out:write('\t},\n')
	local modList = { }
	for _, mod in ipairs(monsterVariety.Mods) do
		table.insert(modList, mod)
	end
	for _, mod in ipairs(monsterVariety.SpecialMods) do
		table.insert(modList, mod)
	end
	out:write('\tmodList = {\n')
	for _, mod in ipairs(modList) do
		local modStats = ""
		for i = 1, 6 do
			if mod["Stat"..i] then
				modStats = modStats .. ' [' .. mod["Stat"..i].Id .. ' = ' .. mod["Stat"..i.."Value"][1] .. ']'
			end
		end
		if modMap[mod.Id] then
			for _, mappedMod in ipairs(modMap[mod.Id]) do
				out:write('\t\t', mappedMod, ', -- ', mod.Id, modStats, '\n')
			end
		else
			out:write('\t\t-- ', mod.Id, modStats, '\n')
		end
	end
	for _, mod in ipairs(state.extraModList) do
		out:write('\t\t', mod, ',\n')
	end
	out:write('\t},\n')
	out:write('}\n')
end

-- #spectre <MonsterId> [<Name>]
directiveTable.spectre = function(state, args, out)
	directiveTable.monster(state, args, out)
	directiveTable.emit(state, "", out)
end

for _, name in pairs({"Spectres","Minions"}) do
	processTemplateFile(name, "Minions/", "../Data/3_0/", directiveTable)
end

print("Minion data exported.")