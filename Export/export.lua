#@

dofile("_common.lua")
dofile("_statdesc.lua")

loadDat("Mods")
loadDat("Stats")
loadDat("Tags")
loadDat("ItemClasses")
loadDat("BaseItemTypes")
loadDat("SkillGems")
loadDat("ActiveSkills")
loadDat("GemTags")
loadDat("GrantedEffects")
loadDat("GrantedEffectsPerLevel")
loadDat("BuffDefinitions")
loadDat("ComponentAttributeRequirements")
loadDat("ComponentArmour")
loadDat("ComponentCharges")
loadDat("WeaponTypes")
loadDat("ShieldTypes")
loadDat("Flasks")
loadDat("DefaultMonsterStats")
loadDat("MonsterTypes")
loadDat("MonsterVarieties")
loadDat("MonsterResistances")
loadDat("SkillTotemVariations")
loadDat("Essences")
loadDat("NPCs")
loadDat("NPCMaster")
loadDat("CraftingBenchOptions")
loadDat("PassiveSkills")

while true do
	print("Enter export script name:")
	local script = io.read("*l")
	if script == "" then
		break
	end
	local func, errMsg = loadfile(script..".lua")
	if not func then
		print(errMsg)
	else
		local ret, errMsg = pcall(func)
		if not ret then
			print(errMsg)
		end
	end
	collectgarbage("collect")
end