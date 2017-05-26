local out = io.open("../Data/Misc.lua", "w")

local evasion = ""
local accuracy = ""
local life = ""
local allyLife = ""
local damage = ""
for i = 0, DefaultMonsterStats.maxRow do
	local stats = DefaultMonsterStats[i]
	evasion = evasion .. stats.Evasion .. ", "
	accuracy = accuracy .. stats.Accuracy .. ", "
	life = life .. stats.Life .. ", "
	allyLife = allyLife .. stats.AllyLife .. ", "
	damage = damage .. stats.Damage .. ", "
end
out:write('-- From DefaultMonsterStats.dat\n')
out:write('data.monsterEvasionTable = { '..evasion..'}\n')
out:write('data.monsterAccuracyTable = { '..accuracy..'}\n')
out:write('data.monsterLifeTable = { '..life..'}\n')
out:write('data.monsterAllyLifeTable = { '..allyLife..'}\n')
out:write('data.monsterDamageTable = { '..damage..'}\n')

local totemMult = ""
local keys = { }
for i = 0, SkillTotemVariations.maxRow do
	local var = SkillTotemVariations[i]
	if not keys[var.SkillTotemsKey] then
		keys[var.SkillTotemsKey] = true
		totemMult = totemMult .. "[" .. var.SkillTotemsKey .. "] = " .. MonsterVarieties[var.MonsterVarietiesKey].LifeMultiplier / 100 .. ", "
	end
end
out:write('-- From MonsterVarieties.dat combined with SkillTotemVariations.dat\n')
out:write('data.totemLifeMult = { '..totemMult..'}\n')

out:close()

print("Misc data exported.")
