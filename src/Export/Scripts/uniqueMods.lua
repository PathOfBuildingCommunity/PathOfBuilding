if not table.containsId then
	dofile("Scripts/mods.lua")
end

LoadModule("../Data/Global.lua")

for _, name in pairs(ItemTypes) do
	local uniqueMods = LoadModule("../Data/Uniques/Special/Uniques.lua")
	local out = io.open("../Data/Uniques/Special/"..name..".lua", "w")
	for line in io.lines("../Data/Uniques/"..name..".lua") do
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if not specName and line ~= "]],[[" then
			local variants = line:match("{[vV]ariant:([%d,]+)}")
			local fractured = line:match("({fractured})") or ""
			local foundMod = false
			local modText = line:gsub("{.+}", ""):gsub("{.+}", "")
			for modName, mod in pairs(uniqueMods) do
				if mod[1]:lower() == modText:lower() then
					out:write(fractured)
					if variants then
						out:write("{variant:" .. variants .. "}")
					end
					out:write(modName, "\n")
					foundMod = true
					break
				end
			end
			if not foundMod then
				out:write(line, "\n")
			end
		else
			out:write(line, "\n")
		end
	end
	out:close()
end

print("Unique mods exported.")
