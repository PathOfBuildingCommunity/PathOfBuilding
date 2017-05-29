#@

dofile("_common.lua")

loadDat("SkillGems")
loadDat("ActiveSkills")
loadDat("GemTags")
loadDat("Stats")
loadDat("Mods")
loadDat("GrantedEffects")
loadDat("GrantedEffectsPerLevel")
loadDat("MonsterVarieties")
loadDat("MonsterTypes")
loadDat("MonsterResistances")
loadDat("ItemClasses")

function actWithType(skillType)
	for _, k in ipairs(ActiveSkills.ActiveSkillTypes(skillType)) do
		if ActiveSkills[k].DisplayedName ~= "" then
			print(ActiveSkills[k].DisplayedName)
		end
	end
end
function supWithType(skillType)
	for _, data in ipairs({"Data0","Data1","Data2"}) do
		print(data..":")
		for _, k in ipairs(GrantedEffects[data](skillType)) do
			print(GrantedEffects[k].Id)
		end
	end
end
function withType(skillType)
	print("Active:")
	actWithType(skillType)
	supWithType(skillType)
end
function skillWithStat(statId)
	local foo = { }
	for _, key in ipairs(GEPL.StatsKeys(Stats.Id(statId)[1])) do
		foo[GEPL[key].GrantedEffectsKey] = true
	end
	for k in pairs(foo) do
		print(GE[k].Id)
	end
end
local function mod(key)
	local m = Mods[key]
	print("Mod #"..key..": "..m.Id)
	for i = 1, 5 do
		local key = m["StatsKey"..i]
		if key then
			print("Stat #"..key..": ["..m["Stat"..i.."Min"].." to "..m["Stat"..i.."Max"].."] "..Stats[key].Id)
		end
	end
end
function spectre(name)
	for i, key in ipairs(MV.Name(name)) do
		local mon = MV[key]
		print("#"..i..": "..mon.Id.." ["..key.."]")
		print("life = "..mon.LifeMultiplier/100)
		if MT[mon.MonsterTypesKey].EnergyShieldFromLife ~= 0 then
			print("energyShield = "..(0.4 * MT[mon.MonsterTypesKey].EnergyShieldFromLife / 100))
		end
		print("fireResist = "..MR[MT[mon.MonsterTypesKey].MonsterResistancesKey].FireMerciless)
		print("coldResist = "..MR[MT[mon.MonsterTypesKey].MonsterResistancesKey].ColdMerciless)
		print("lightningResist = "..MR[MT[mon.MonsterTypesKey].MonsterResistancesKey].LightningMerciless)
		print("chaosResist = "..MR[MT[mon.MonsterTypesKey].MonsterResistancesKey].ChaosMerciless)
		print("damage = "..(mon.DamageMultiplier/100))
		print("damageSpread = "..(MT[mon.MonsterTypesKey].DamageSpread / 100))
		print("attackTime = "..mon.AttackSpeed/1000)
		print("attackRange = "..mon.MaximumAttackDistance)
		if mon.MainHand_ItemClassesKey then
			print("weaponType1 = "..IC[mon.MainHand_ItemClassesKey].Name)
		end
		if mon.OffHand_ItemClassesKey then
			print("weaponType2 = "..IC[mon.OffHand_ItemClassesKey].Name)
		end
		for _, key in ipairs(mon.GrantedEffectsKeys) do
			print("Skill #"..key..": "..GE[key].Id)
		end
		for _, key in ipairs(mon.ModsKeys) do
			mod(key)
		end
		for _, key in ipairs(mon.Special_ModsKeys) do
			mod(key)
		end
	end
end

local str
while true do
	print(">>")
	str = io.read("*l")
	if str == "quit" then
		break
	end
	local func, msg = loadstring(str)
	if func then
		local ret, msg = pcall(func)
		if not ret then
			print(msg)
		end
	else
		print(msg)
	end
end