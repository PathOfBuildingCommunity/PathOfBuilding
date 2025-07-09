if not table.containsId then
	dofile("Scripts/mods.lua")
end
local catalystTags = {
	["attack"] = true,
	["speed"] = true,
	["life"] = true,
	["mana"] = true,
	["caster"] = true,
	["attribute"] = true,
	["physical"] = true,
	["fire"] = true,
	["cold"] = true,
	["lightning"] = true,
	["chaos"] = true,
	["defences"] = true,
}
local itemTypes = {
	-- "axe",
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
local function writeMods(out, statOrder)
	local orders = { }
	for order, _ in pairs(statOrder) do
		table.insert(orders, order)
	end
	table.sort(orders)
	for _, order in pairs(orders) do
		for _, line in ipairs(statOrder[order]) do
			out:write(line, "\n")
		end
	end
end

local uniqueMods = LoadModule("../Data/ModItemExclusive.lua")
for _, name in ipairs(itemTypes) do
	local out = io.open("../Data/Uniques/"..name..".lua", "w")
	local statOrder = {}
	local postModLines = {}
	local modLines = 0
	local implicits
	for line in io.lines("Uniques/"..name..".lua") do
		if implicits then -- remove 1 downs to 0
			implicits = implicits - 1
		end
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if line:match("]],") then -- start new unique
			writeMods(out, statOrder)
			for _, line in ipairs(postModLines) do
				out:write(line, "\n")
			end
			out:write(line, "\n")
			statOrder = { }
			postModLines = { }
			modLines = 0
		elseif not specName then
			local prefix = ""
			local variantString = line:match("({variant:[%d,]+})")
			local fractured = line:match("({fractured})") or ""
			local modName, legacy = line:gsub("{.+}", ""):match("^([%a%d_]+)([%[%]-,%d]*)")
			local mod = uniqueMods[modName]
			if mod then
				modLines = modLines + 1
				if variantString then
					prefix = prefix ..variantString
				end
				local tags = {}
				if isValueInArray({"amulet", "ring"}, name) then
					for _, tag in ipairs(mod.modTags) do
						if catalystTags[tag] then
							table.insert(tags, tag)
						end
					end
				end
				if tags[1] then
					prefix = prefix.."{tags:"..table.concat(tags, ",").."}"
				end
				prefix = prefix..fractured
				local legacyMod
				if legacy ~= "" then
					local values = { }
					for range in legacy:gmatch("%b[]") do
						local min, max = range:match("%[([%d%-]+),([%d%-]+)%]")
						table.insert(values, { min = tonumber(min), max = tonumber(max) })
					end
					local mod = dat("Mods"):GetRow("Id", modName)
					local stats = { }
					for i = 1, 6 do
						if mod["Stat"..i] then
							stats[mod["Stat"..i].Id] = values[i]
						end
					end
					if mod.Type then
						stats.Type = mod.Type
					end
					legacyMod = describeStats(stats)
				end 
				for i, line in ipairs(legacyMod or mod) do
					local order = mod.statOrder[i]
					if statOrder[order] then
						table.insert(statOrder[order], prefix..line)
					else
						statOrder[order] = { prefix..line }
					end
				end
			else
				if modLines > 0 then -- treat as post line e.g. mirrored
					table.insert(postModLines, line)
				else	
					out:write(line, "\n")
				end
			end
		else
			if specName == "Implicits" then
				implicits = tonumber(specVal)
			end
			out:write(line, "\n")
		end
		if implicits and implicits == 0 then
			writeMods(out, statOrder)
			implicits = nil
			statOrder = { }
			modLines = 0
		end
	end
	out:close()
end

print("Unique text updated.")
