if not table.containsId then
	dofile("Scripts/mods.lua")
end
local catalystTags = {
	["elemental_damage"] = true,
	["caster"] = true,
	["attack"] = true,
	["defences"] = true,
	["resource"] = true,
	["resistance"] = true,
	["attribute"] = true,
	["physical_damage"] = true,
	["chaos_damage"] = true,
	["speed"] = true,
	["critical"] = true,
}
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
	local nextOrder = 100000
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
			nextOrder = 100000
		elseif not specName then
			local prefix = ""
			local variantString = line:match("({variant:[%d,]+})")
			local fractured = line:match("({fractured})") or ""
			local cleanLine = line:gsub("{.-}", "")
			-- Check if this is a mod ID: purely alphanumeric+underscore, optionally followed by [num,num] ranges
			local modName = cleanLine:match("^([%a%d_ ]+)%[") or cleanLine:match("^([%a%d_ ]+)$")
			local legacy = modName and cleanLine:sub(#modName + 1) or ""
			-- Legacy ranges must contain actual brackets, not just stray characters
			if legacy ~= "" and not legacy:match("%[") then
				legacy = ""
				modName = nil
			end
			local mod = modName and uniqueMods[modName]
			if mod or (modName and legacy ~= "") then
				modLines = modLines + 1
				if variantString then
					prefix = prefix ..variantString
				end

				local tags = {}
				if mod then
					if isValueInArray({"amulet", "ring", "belt"}, name) then
						for _, tag in ipairs(mod.modTags) do
							if catalystTags[tag] then
								table.insert(tags, tag)
							end
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
						local min, max = range:match("%[([%d%.%-]+),([%d%.%-]+)%]")
						table.insert(values, { min = tonumber(min), max = tonumber(max) })
					end
					local mod = dat("Mods"):GetRow("Id", modName)
					if mod then
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
					else
						ConPrintf("Warning: Could not find mod data for legacy mod '%s' in %s", modName, name)
					end
				end
				local modText = legacyMod or mod
				if modText then
					local order
					for i, line in ipairs(modText) do
						if i == 1 then
							order = mod and mod.statOrder and mod.statOrder[i] or (nextOrder)
						end
						nextOrder = nextOrder + 1
						if statOrder[order] then
							table.insert(statOrder[order], prefix..line)
						else
							statOrder[order] = { prefix..line }
						end
					end
				end
			else
				if modLines > 0 or implicits then -- treat as post line e.g. mirrored, or unresolved text mod
					-- Unresolved text lines get a sequential order to preserve position among mods
					if statOrder[nextOrder] then
						table.insert(statOrder[nextOrder], line)
					else
						statOrder[nextOrder] = { line }
					end
					nextOrder = nextOrder + 1
				else
					out:write(line, "\n")
				end
			end
		else -- spec line
			if specName == "Implicits" then
				implicits = tonumber(specVal)
			else
				out:write(line, "\n")
			end
		end
		if implicits and implicits == 0 then
			local lines = 0
			for _, l in pairs(statOrder) do
				lines = lines + #l
			end
			out:write("Implicits: "..lines, "\n")
			writeMods(out, statOrder)
			implicits = nil
			statOrder = { }
			modLines = 0
		end
	end
	writeMods(out, statOrder)
	for _, line in ipairs(postModLines) do
		out:write(line, "\n")
	end
	out:close()
end

print("Unique text updated.")
