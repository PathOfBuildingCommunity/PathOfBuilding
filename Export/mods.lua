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

print("Mods exported.")