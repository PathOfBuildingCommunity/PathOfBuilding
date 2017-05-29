local corr = io.open("../Data/ModCorrupted.lua", "w")
corr:write('-- Item data (c) Grinding Gear Games\n\nreturn {\n')
for _, modKey in ipairs(Mods.GenerationType(5)) do
	local mod = Mods[modKey]
	corr:write('\t["', mod.Id, '"] = { "', table.concat(describeMod(mod), '", "'), '", level = ', mod.Level, ', weightKey = { ')
	for _, tagKey in ipairs(mod.SpawnWeight_TagsKeys) do
		corr:write('"', Tags[tagKey].Id, '", ')
	end
	corr:write('}, weightVal = { ', table.concat(mod.SpawnWeight_Values, ', '), ', }, },\n')
end
corr:write('}')
corr:close()

local items = io.open("../Data/ModItem.lua", "w")
items:write('-- Item data (c) Grinding Gear Games\n\nreturn {\n')
for _, modKey in ipairs(Mods.Domain(1)) do
	local mod = Mods[modKey]
	if mod.GenerationType == 1 or mod.GenerationType == 2 then
		items:write('\t["', mod.Id, '"] = { type = "', mod.GenerationType == 1 and "Prefix" or "Suffix", '", affix = "', mod.Name, '", ')
		items:write('"', table.concat(describeMod(mod), '", "'), '", level = ', mod.Level, ', weightKey = { ')
		for _, tagKey in ipairs(mod.SpawnWeight_TagsKeys) do
			items:write('"', Tags[tagKey].Id, '", ')
		end
		items:write('}, weightVal = { ', table.concat(mod.SpawnWeight_Values, ', '), ', }, },\n')
	end
end
items:write('}')
items:close()

print("Mods exported.")