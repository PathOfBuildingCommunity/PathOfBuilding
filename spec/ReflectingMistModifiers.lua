-- Enumerate the exported modifier sources used by the jewellery crafting menus.
local entries, seen = {}, {}
local bases = {}
for name, base in pairs(data.itemBases) do
	if base.type == "Ring" or base.type == "Amulet" then
		table.insert(bases, { name = name, base = base })
	end
end
table.sort(bases, function(a, b) return a.name < b.name end)

local function add(source, id, mod, itemType, influenced)
	local key = source .. ":" .. tostring(id) .. ":" .. itemType
	if not mod or #mod == 0 or seen[key] then return end
	seen[key] = true
	table.insert(entries, {
		source = source, id = tostring(id), mod = mod, itemType = itemType,
		baseName = itemType == "Ring" and "Coral Ring" or "Onyx Amulet",
		influenced = influenced or false,
	})
end

local function spawnable(source, mods, necropolis)
	for id, mod in pairs(mods) do
		if mod.type == "Prefix" or mod.type == "Suffix" then
			for _, itemType in ipairs({ "Ring", "Amulet" }) do
				local normal, influenced = false, false
				for _, base in ipairs(bases) do
					if base.base.type == itemType then
						local item = setmetatable({ base = base.base }, common.classes.Item)
						local weight = necropolis and item:GetNecropolisModSpawnWeight(mod) or item:GetModSpawnWeight(mod)
						normal = normal or weight > 0
						for _, influence in ipairs(itemLib.influenceInfo.all) do item[influence.key] = true end
						influenced = influenced or item:GetModSpawnWeight(mod) > 0
					end
				end
				if normal or influenced then add(source, id, mod, itemType, not normal) end
			end
		end
	end
end

spawnable("Affix", data.itemMods.Item)
spawnable("Veiled", data.veiledMods)
spawnable("Necropolis", data.necropolisMods, true)
for id, mod in ipairs(data.masterMods) do
	for _, itemType in ipairs({ "Ring", "Amulet" }) do
		if mod.types[itemType] then add("Bench", id, mod, itemType) end
	end
end
for id, essence in pairs(data.essences) do
	for _, itemType in ipairs({ "Ring", "Amulet" }) do
		local modId = essence.mods[itemType]
		if modId then add("Essence", id, data.itemMods.Item[modId], itemType) end
	end
end
for _, source in ipairs({
	{ "Incursion", "Data/IncursionDropOnly", data.itemMods.Explicit },
	{ "Delve", "Data/DelveDropOnly", data.itemMods.Delve },
}) do
	for id, drop in pairs(LoadModule(source[2])) do
		for _, itemType in ipairs(drop.categories) do
			if itemType == "Ring" or itemType == "Amulet" then add(source[1], id, source[3][id], itemType) end
		end
	end
end
for id, mod in pairs(data.beastCraft) do
	for _, itemType in ipairs({ "Ring", "Amulet" }) do add("Beastcraft", id, mod, itemType) end
end
table.sort(entries, function(a, b)
	return a.source .. a.id .. a.itemType < b.source .. b.id .. b.itemType
end)

local function makeItem(entry, range)
	local raw = "Rarity: Rare\nMist Modifier Test\n" .. entry.baseName .. "\nImplicits: 0\n"
	local prefix = "{modGroup:test}{range:" .. range .. "}{" .. entry.mod.type:lower() .. "}"
	if entry.source == "Bench" then prefix = prefix .. "{crafted}" end
	if entry.mod.modTags and #entry.mod.modTags > 0 then
		prefix = prefix .. "{tags:" .. table.concat(entry.mod.modTags, ",") .. "}"
	end
	for _, line in ipairs(entry.mod) do raw = raw .. prefix .. line .. "\n" end
	return new("Item"):Item(raw)
end

return { entries = entries, makeItem = makeItem }
