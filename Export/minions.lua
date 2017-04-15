#@

dofile("_common.lua")

loadDat("MonsterVarieties")
loadDat("MonsterTypes")
loadDat("MonsterResistances")
loadDat("Mods")
loadDat("GrantedEffects")

while true do

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

for _, name in pairs({"Spectres"}) do
	local out = io.open("Minions/"..name..".lua", "w")
	for line in io.lines("Minions/"..name..".txt") do
		local spec, args = line:match("#(%a+) ?(.*)")
		if spec then
			if spec == "monster" then
				local key = MonsterVarieties.Id(args)[1]
				if not key then
					print("Invalid Id: "..args)
				else
					local MonsterVariety = MonsterVarieties[key]
					local MonsterType = MonsterTypes[MonsterVariety.MonsterTypesKey]
					out:write('minions["'..args..'"] = {\n')
					out:write('\tname = "'..MonsterVariety.Name..'",\n')
					out:write('\tlife = '..(MonsterVariety.LifeMultiplier/100)..',\n')
					if MonsterType.Unknown4 ~= 0 then
						out:write('\tenergyShield = '..(0.4 * MonsterType.Unknown4 / 100)..',\n')
					end
					local Resist = MonsterResistances[MonsterType.MonsterResistancesKey]
					out:write('\tfireResist = '..Resist.FireMerciless..',\n')
					out:write('\tcoldResist = '..Resist.ColdMerciless..',\n')
					out:write('\tlightningResist = '..Resist.LightningMerciless..',\n')
					out:write('\tchaosResist = '..Resist.ChaosMerciless..',\n')
					out:write('\tdamage = '..(1 + MonsterVariety.DamageMultiplier/100)..',\n')
					out:write('\tdamageSpread = '..(MonsterType.Unknown5 / 100)..',\n')
					out:write('\tattackTime = '..(MonsterVariety.AttackSpeed/1000)..',\n')
					if MonsterVariety.MainHand_ItemClassesKey and itemClassMap[MonsterVariety.MainHand_ItemClassesKey] then
						out:write('\tweaponType1 = "'..itemClassMap[MonsterVariety.MainHand_ItemClassesKey]..'",\n')
					end
					if MonsterVariety.OffHand_ItemClassesKey and itemClassMap[MonsterVariety.OffHand_ItemClassesKey] then
						out:write('\tweaponType2 = "'..itemClassMap[MonsterVariety.OffHand_ItemClassesKey]..'",\n')
					end
					out:write('\tskillList = {\n')
					for _, key in ipairs(MonsterVariety.GrantedEffectsKeys) do
						out:write('\t\t"'..GrantedEffects[key].Id..'",\n')
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
								out:write('\t\t'..mod..', -- '..Mod.Id..'\n')
							end
						else
							out:write('\t\t-- '..Mod.Id..'\n')
						end
					end
					out:write('\t},\n')
					out:write('}\n')
				end
			end
		else
			out:write(line.."\n")
		end
	end
	out:close()
end

print("Minion data exported.")

os.execute("xcopy Minions\\*.lua ..\\Data\\ /Y")

if io.read("*l") ~= "" then
	break
end
end
os.execute("pause")
