if not table.containsId then
	dofile("Scripts/mods.lua")
end
LoadModule("../Data/Global.lua")
local catalystTags = {
	["attack"] = true,
	["speed"] = true,
	["life"] = true,
	["mana"] = true,
	["resource"] = true,
	["caster"] = true,
	["attribute"] = true,
	["physical"] = true,
	["chaos"] = true,
	["resistance"] = true,
	["defences"] = true,
	["elemental_damage"] = true,
	["critical"] = true,
}
for _, name in pairs(ItemTypes) do
	local uniqueMods = LoadModule("../Data/Uniques/Special/Uniques.lua")
	local out = io.open("../Data/Uniques/"..name..".lua", "w")
	for line in io.lines("../Data/Uniques/Special/"..name..".lua") do
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if not specName and line ~= "]],[[" then
			local variantString = line:match("({variant:[%d,]+})")
			local modName = line:gsub("{.+}", "")
			if uniqueMods[modName] then
				if variantString then
					out:write(variantString)
				end
				local tags = {}
				if isValueInArray({"belt", "amulet", "ring"}, name) then
					for _, tag in ipairs(uniqueMods[modName].modTags) do
						if catalystTags[tag] then
							table.insert(tags, tag)
						end
					end
				end
				if tags[1] then
					out:write("{tags:" .. table.concat(tags, ",") .. "}")
				end
				out:write(uniqueMods[modName][1], "\n")
			else
				out:write(line, "\n")
			end
		else
			out:write(line, "\n")
		end
	end
	out:close()
end

print("Unique text updated.")
