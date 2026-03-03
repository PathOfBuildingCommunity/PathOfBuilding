if not table.containsId then
	dofile("Scripts/mods.lua")
end

local itemTypes = {
	"axe",
	"bow",
	"claw",
	"dagger",
	"fishing",
	"mace",
	"staff",
	"sword",
	"wand",
	"helmet",
	"body",
	"gloves",
	"boots",
	"shield",
	"quiver",
	"amulet",
	"ring",
	"belt",
	"jewel",
	"flask",
	"tincture",
}

local usedMods = {}
local itemUsedMods = {}
local modTextMap = LoadModule("Uniques/ModTextMap.lua")

for _, name in pairs(itemTypes) do
	local out = io.open("Uniques/"..name..".lua", "w")
	for line in io.lines("../Data/Uniques/"..name..".lua") do
		if line == "]],[[" then
			itemUsedMods = {} -- Reset mod list for trying to keep variants using the same mod
		end
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if not specName and line ~= "]],[[" then
			local variants = line:match("{[vV]ariant:([%d,.]+)}")
			local fractured = line:match("({fractured})") or ""
			local modText = line:gsub("{.-}", ""):gsub("\xe2\x80\x93", "-") -- Clean tag prefixes and EM dash
			local possibleMods = modTextMap[modText]
			local genericText
			local genericValues = {}
			if not possibleMods then
				-- Replace numbers with placeholder.  Covers 5, -5--10, -5.5-10.5, etc.  Ranges are handled later when printing
				genericText = modText:gsub('(%-*%d*%.*%d+-*%-*%d*%.*%d+)', '#')
				for val in modText:gmatch('(%-*%d*%.*%d+-*%-*%d*%.*%d+)') do
					table.insert(genericValues, val)
				end
				possibleMods = modTextMap[genericText]
			end
			local gggMod
			if possibleMods then
				-- First pass: prefer mods that match the item type
				for _, modName in ipairs(possibleMods) do
					if modName:lower():match(name) then
						gggMod = modName
						usedMods[modName] = true
						itemUsedMods[modName] = true
						break
					end
				end
				-- Second pass: prefer mods that haven't already been used
				if not gggMod then
					for _, modName in ipairs(possibleMods) do
						if (not usedMods[modName]) or itemUsedMods[modName] then
							gggMod = modName
							usedMods[modName] = true
							itemUsedMods[modName] = true
							break
						end
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
				out:write(gggMod)
				if genericText then
					-- Figure out where to put [,]
					for _, val in ipairs(genericValues) do
						local min, max = val:match("(%-*%d*%.*%d+)-*(%-*%d*%.*%d+)")
						out:write("[" .. min .. (max and "," .. max or "") .. "]")
					end
				end
			else
				ConPrintf("Warning: No mod found for line '%s' in %s", modText, name)
				out:write(line, "\n")
			end
		else
			out:write(line, "\n")
		end
	end
	out:close()
end

print("Unique mods exported.")
