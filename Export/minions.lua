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
	[26] = "Shield",
	[32] = "One Handed Mace",
	[36] = "None",
}

local directiveTable = { }

-- #monster <MonsterId>
directiveTable.monster = function(state, args, out)
	local key = MonsterVarieties.Id(args)[1]
	if not key then
		print("Invalid Id: "..args)
		return
	end
	local MonsterVariety = MonsterVarieties[key]
	local MonsterType = MonsterTypes[MonsterVariety.MonsterTypesKey]
	out:write('minions["', args, '"] = {\n')
	out:write('\tname = "', MonsterVariety.Name, '",\n')
	out:write('\tlife = ', (MonsterVariety.LifeMultiplier/100), ',\n')
	if MonsterType.EnergyShieldFromLife ~= 0 then
		out:write('\tenergyShield = ', (0.4 * MonsterType.EnergyShieldFromLife / 100), ',\n')
	end
	local Resist = MonsterResistances[MonsterType.MonsterResistancesKey]
	out:write('\tfireResist = ', Resist.FireMerciless, ',\n')
	out:write('\tcoldResist = ', Resist.ColdMerciless, ',\n')
	out:write('\tlightningResist = ', Resist.LightningMerciless, ',\n')
	out:write('\tchaosResist = ', Resist.ChaosMerciless, ',\n')
	out:write('\tdamage = ', (MonsterVariety.DamageMultiplier/100), ',\n')
	out:write('\tdamageSpread = ', (MonsterType.DamageSpread / 100), ',\n')
	out:write('\tattackTime = ', (MonsterVariety.AttackSpeed/1000), ',\n')
	out:write('\tattackRange = ', MonsterVariety.MaximumAttackDistance, ',\n')
	for _, key in ipairs(MonsterVariety.ModsKeys) do
		local Mod = Mods[key]
		if Mod.Id == "MonsterSpeedAndDamageFixupSmall" then
			out:write('\tdamageFixup = 0.11,\n')
		elseif Mod.Id == "MonsterSpeedAndDamageFixupLarge" then
			out:write('\tdamageFixup = 0.22,\n')
		elseif Mod.Id == "MonsterSpeedAndDamageFixupComplete" then
			out:write('\tdamageFixup = 0.33,\n')
		end
	end
	if MonsterVariety.MainHand_ItemClassesKey and itemClassMap[MonsterVariety.MainHand_ItemClassesKey] then
		out:write('\tweaponType1 = "', itemClassMap[MonsterVariety.MainHand_ItemClassesKey], '",\n')
	end
	if MonsterVariety.OffHand_ItemClassesKey and itemClassMap[MonsterVariety.OffHand_ItemClassesKey] then
		out:write('\tweaponType2 = "', itemClassMap[MonsterVariety.OffHand_ItemClassesKey], '",\n')
	end
	out:write('\tskillList = {\n')
	for _, key in ipairs(MonsterVariety.GrantedEffectsKeys) do
		out:write('\t\t"', GrantedEffects[key].Id, '",\n')
	end
	out:write('\t},\n')
	local modList = { }
	for _, key in ipairs(MonsterVariety.ModsKeys) do
		table.insert(modList, key)
	end
	for _, key in ipairs(MonsterVariety.Special_ModsKeys) do
		table.insert(modList, key)
	end
	out:write('\tmodList = {\n')
	for _, key in ipairs(modList) do
		local Mod = Mods[key]
		if modMap[Mod.Id] then
			for _, mod in ipairs(modMap[Mod.Id]) do
				out:write('\t\t', mod, ', -- ', Mod.Id, '\n')
			end
		else
			out:write('\t\t-- ', Mod.Id, '\n')
		end
	end
	out:write('\t},\n')
	out:write('}\n')
end

for _, name in pairs({"Spectres"}) do
	processTemplateFile("Minions/"..name, directiveTable)
end

os.execute("xcopy Minions\\*.lua ..\\Data\\3_0\\ /Y /Q")

print("Minion data exported.")