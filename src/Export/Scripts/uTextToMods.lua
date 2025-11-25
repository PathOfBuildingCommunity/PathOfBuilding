if not table.containsId then
	dofile("Scripts/mods.lua")
end

local itemTypes = {
	"axe",
	-- "bow",
	-- "claw",
	-- "dagger",
	-- "fishing",
	-- "mace",
	-- "sceptre",
	-- "spear",
	-- "staff",
	-- "sword",
	-- "wand",
	-- "helmet",
	-- "body",
	-- "focus",
	-- "gloves",
	-- "boots",
	-- "shield",
	-- "quiver",
	-- "amulet",
	-- "ring",
	-- "belt",
	-- "jewel",
	-- "flask",
	-- "tincture",
}

usedMods = {}

for _, name in pairs(itemTypes) do
	local modTextMap = LoadModule("Uniques/ModTextMap.lua")
	local out = io.open("Uniques/"..name..".lua", "w")
	for line in io.lines("../Data/Uniques/"..name..".lua") do
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if not specName and line ~= "]],[[" then
			local variants = line:match("{[vV]ariant:([%d,.]+)}")
			local fractured = line:match("({fractured})") or ""
			local modText = line:gsub("{.+}", ""):gsub("{.+}", ""):gsub("–", "-") -- Clean EM dash
			local possibleMods = modTextMap[modText]
			local gggMod
			if possibleMods then
				for _, modName in ipairs(possibleMods) do
					if modName:lower():match(name) then -- prefer mods that match the item type
						gggMod = modName
						usedMods[modName] = true
					elseif not usedMods[modName] then -- prefer mods that haven't already been used
						gggMod = modName
						usedMods[modName] = true
					end
				end
				if not gggMod then
					gggMod = possibleMods[1]
					usedMods[gggMod] = true
					ConPrintf("Warning: Multiple possible mods for line '%s' in %s, using '%s'", modText, name, gggMod)
				end
				out:write(fractured)
				if variants then
					out:write("{variant:" .. variants:gsub("%.", ",") .. "}")
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
