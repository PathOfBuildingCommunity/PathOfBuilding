local gems = { }

function addGem(name, tags, grantedKey)
	local granted = GrantedEffects[grantedKey]
	local activeSkill = granted.ActiveSkillsKey and ActiveSkills[granted.ActiveSkillsKey]
	local gem = { }
	table.insert(gems, gem)
	gem.name = name:gsub(" Support$","")
	gem.tags = tags
	gem.grantedId = granted.Id
end

for i = 0, SkillGems.maxRow do
	local skillGem = SkillGems[i]
	local baseItem = BaseItemTypes[skillGem.BaseItemTypesKey]
	local tags = { }
	for _, tagKey in pairs(skillGem.GemTagsKeys) do
		table.insert(tags, GemTags[tagKey].Id)
	end
	addGem(baseItem.Name, tags, skillGem.GrantedEffectsKey)
end
local uniqueList = { "Icestorm", "Gluttony of Elements", "Illusory Warp" }
for _, name in pairs(uniqueList) do
	addGem(name, { }, GrantedEffects.ActiveSkillsKey(ActiveSkills.DisplayedName(name)[1])[1])
end

table.sort(gems, function(a, b)
	return a.name < b.name
end)
local f = io.open("gems.txt", "w")
for _, gem in ipairs(gems) do
	f:write(gem.name.."|"..gem.grantedId.."|"..table.concat(gem.tags, ",").."\n")
end
f:close()

print("Gem list generated.")
