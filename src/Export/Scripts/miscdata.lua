local out = io.open("../Data/Misc.lua", "w")

out:write('local data = ...\n')
local evasion = ""
local accuracy = ""
local life = ""
local allyLife = ""
local damage = ""
local armour = ""
for stats in dat("DefaultMonsterStats"):Rows() do
	evasion = evasion .. stats.Evasion .. ", "
	accuracy = accuracy .. stats.Accuracy .. ", "
	life = life .. stats.MonsterLife .. ", "
	allyLife = allyLife .. stats.MinionLife .. ", "
	damage = damage .. stats.Damage .. ", "
	armour = armour .. stats.Armour .. ", "
end
out:write('-- From DefaultMonsterStats.dat\n')
out:write('data.monsterEvasionTable = { '..evasion..'}\n')
out:write('data.monsterAccuracyTable = { '..accuracy..'}\n')
out:write('data.monsterLifeTable = { '..life..'}\n')
out:write('data.monsterAllyLifeTable = { '..allyLife..'}\n')
out:write('data.monsterDamageTable = { '..damage..'}\n')
out:write('data.monsterArmourTable = { '..armour..'}\n')

local totemMult = ""
local keys = { }
for var in dat("SkillTotemVariations"):Rows() do
	if not keys[var.SkillTotem] then
		keys[var.SkillTotem] = true
		totemMult = totemMult .. "[" .. var.SkillTotem .. "] = " .. var.MonsterVariety.LifeMultiplier / 100 .. ", "
	end
end
out:write('-- From MonsterVarieties.dat combined with SkillTotemVariations.dat\n')
out:write('data.totemLifeMult = { '..totemMult..'}\n')

out:close()

print("Misc data exported.")
