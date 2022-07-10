if not table.containsId then
	dofile("Scripts/mods.lua")
end

LoadModule("../Data/Global.lua")

for _, name in pairs(ItemTypes) do
	local modTextMap = LoadModule("../Data/Uniques/Special/ModTextMap.lua")
	local out = io.open("../Data/Uniques/Special/"..name..".lua", "w")
	for line in io.lines("../Data/Uniques/"..name..".lua") do
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if not specName and line ~= "]],[[" then
			local variants = line:match("{[vV]ariant:([%d,.]+)}")
			local fractured = line:match("({fractured})") or ""
			local modText = line:gsub("{.+}", ""):gsub("{.+}", ""):gsub("–", "-") -- Clean EM dash
			local possibleMods = modTextMap[modText]
			local gggMod
			if possibleMods then
				gggMod = possibleMods[1]
				for _, modName in ipairs(possibleMods) do
					if modName:lower():match(name) then
						gggMod = modName
					end
				end
				out:write(fractured)
				if variants then
					out:write("{variant:" .. variants:gsub(".", ",") .. "}")
				end
				out:write(gggMod, "\n")
			else
				out:write(line, "\n")
			end
		else
			out:write(line, "\n")
		end
	end
	out:close()
end

print("Unique mods exported.")
