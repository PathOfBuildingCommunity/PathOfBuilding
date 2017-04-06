#@

dofile("_common.lua")

loadDat("SkillGems")
loadDat("ActiveSkills")
loadDat("GemTags")
loadDat("Stats")
loadDat("GrantedEffects")
loadDat("GrantedEffectsPerLevel")

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