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
local function appendMods(lines, statOrder)
	local orders = { }
	for order, _ in pairs(statOrder) do
		table.insert(orders, order)
	end
	table.sort(orders)
	for _, order in pairs(orders) do
		for _, line in ipairs(statOrder[order]) do
			table.insert(lines, line)
		end
	end
end

local itemBases = { }
for _, name in ipairs(itemTypes) do
	LoadModule("../Data/Bases/"..name..".lua")(itemBases)
end

local uniqueMods = LoadModule("../Data/ModItemExclusive.lua")
for _, name in ipairs(itemTypes) do
	local out = io.open("../Data/Uniques/"..name..".lua", "w")
	local lines = { }
	local requirementIndex
	local statOrder = {}
	local postModLines = {}
	local modLines = 0
	local implicits
	local nextOrder = 100000
	local baseReqLevel = 0
	local uniqueReqLevel = 0
	for line in io.lines("Uniques/"..name..".lua") do
		if implicits then -- remove 1 downs to 0
			implicits = implicits - 1
		end
		local specName, specVal = line:match("^([%a ]+): (.+)$")
		if line:match("^%]%]") then -- end of unique
			-- Attribute requirements come from the base; mods can raise the required level.
			if uniqueReqLevel > 1 and uniqueReqLevel > baseReqLevel then
				table.insert(lines, requirementIndex or #lines + 1, "Requires Level "..uniqueReqLevel)
			end
			appendMods(lines, statOrder)
			for _, line in ipairs(postModLines) do
				table.insert(lines, line)
			end
			table.insert(lines, line)
			out:write(table.concat(lines, "\n"), "\n")
			lines = { }
			requirementIndex = nil
			statOrder = { }
			postModLines = { }
			modLines = 0
			nextOrder = 100000
			baseReqLevel = 0
			uniqueReqLevel = 0
		elseif not specName then
			local prefix = ""
			local versionString = line:match("({version:[%d,]+})")
			local variantString = line:match("({variant:[%d,]+})")
			local groupString = line:match("({group:[%d,]+})")
			local enchant = line:match("({enchant})") or ""
			local fractured = line:match("({fractured})") or ""
			local crafted = line:match("({crafted})") or ""
			local cleanLine = line:gsub("{.-}", "")
			local base = itemBases[sanitiseText(cleanLine)]
			if base then
				baseReqLevel = math.max(baseReqLevel, base.req.level or 0)
			end
			-- Check if this is a mod ID: purely alphanumeric+underscore, optionally followed by [num,num] ranges
			local modName = cleanLine:match("^([%a%d_ ]+)%[") or cleanLine:match("^([%a%d_ ]+)$")
			local legacy = modName and cleanLine:sub(#modName + 1) or ""
			-- Legacy ranges must contain actual brackets, not just stray characters
			if legacy ~= "" and not legacy:match("%[") then
				legacy = ""
				modName = nil
			end
			local mod = modName and uniqueMods[modName]
			local rawMod = modName and dat("Mods"):GetRow("Id", modName)
			local modLevel = rawMod and rawMod.Level or mod and mod.level
			if modLevel then
				uniqueReqLevel = math.max(uniqueReqLevel, math.floor(modLevel * 0.8))
			end
			if modName and not mod and legacy == "" then
				if rawMod then
					local orders
					mod, orders = describeMod(rawMod)
					mod.statOrder = orders
					mod.modTags = { }
					for _, tag in ipairs(rawMod.ImplicitTags) do
						table.insert(mod.modTags, tag.Id)
					end
					uniqueMods[modName] = mod
				end
			end
			if mod or (modName and legacy ~= "") then
				modLines = modLines + 1
				prefix = prefix .. (versionString or "") .. (variantString or "") .. (groupString or "")

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
				prefix = prefix..enchant..fractured..crafted
				local legacyMod
				if legacy ~= "" then
					local values = { }
					for range in legacy:gmatch("%b[]") do
						local min, max = range:match("%[([%d%.%-]+),([%d%.%-]+)%]")
						table.insert(values, { min = tonumber(min), max = tonumber(max) })
					end
					if rawMod then
						local stats = { }
						for i = 1, 6 do
							if rawMod["Stat"..i] then
								stats[rawMod["Stat"..i].Id] = values[i]
							end
						end
						if rawMod.Type then
							stats.Type = rawMod.Type
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
					table.insert(lines, line)
				end
			end
		else -- spec line
			if specName == "Implicits" then
				requirementIndex = #lines + 1
				implicits = tonumber(specVal)
			else
				table.insert(lines, line)
			end
		end
		if implicits and implicits == 0 then
			local count = 0
			for _, l in pairs(statOrder) do
				count = count + #l
			end
			table.insert(lines, "Implicits: "..count)
			appendMods(lines, statOrder)
			implicits = nil
			statOrder = { }
			modLines = 0
		end
	end
	appendMods(lines, statOrder)
	for _, line in ipairs(postModLines) do
		table.insert(lines, line)
	end
	if #lines > 0 then
		out:write(table.concat(lines, "\n"), "\n")
	end
	out:close()
end

print("Unique text updated.")
