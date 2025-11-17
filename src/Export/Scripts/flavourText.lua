--
-- export flavour text data
--
local function normalizeId(id)
	id = tostring(id)
	-- remove trailing underscores only. We can't match Hash sadly.
	return id:gsub("_+$", "")
end

local function cleanAndSplit(str)
	-- Normalize newlines
	str = str:gsub("\r\n", "\n")

	-- Replace <default> with a newline and ^8
	str = str:gsub("<default>", "\n^8")

	local lines = {}
	for line in str:gmatch("[^\n]+") do
		-- trim
		line = line:match("^%s*(.-)%s*$")

		if line ~= "" then
			-- Remove braces but keep contents
			line = line:gsub("%{(.-)%}", "%1")

			-- Remove any <<...>> sequences (non-greedy)
			line = line:gsub("<<(.-)>>", "")

			-- trim again in case removal left surrounding spaces
			line = line:match("^%s*(.-)%s*$")

			-- Escape quotes
			line = line:gsub('"', '\\"')

			-- Insert a blank line before any ^8 line
			if line:match("^%^8") and (#lines == 0 or lines[#lines] ~= "") then
				table.insert(lines, "")
			end

			-- Only add non-empty lines
			if line ~= "" then
				table.insert(lines, line)
			end
		end
	end

	return lines
end

local uniqueNameLookup = {}
local unmatchedIds = {}
local exportedNames = {}

-- List of forced names (multiple entries for same ID allowed)
local forcedNameList = { -- fated show twice at the moment, but this list is caught first
	{ id = "UniqueOneHandAxe5", name = "Jack, the Axe" },
	{ id = "UniqueBootsDIY", name = "Doryani's Delusion" },
	{ id = "UniqueGlovesStrDex9", name = "Tombfist" },
	{ id = "UniqueAmulet45", name = "Impresence" },
	{ id = "UniqueAmuletVictor1", name = "Talisman of the Victor" },
	{ id = "UniqueStaff8", name = "Agnerod South" },
	{ id = "UniqueStaff8", name = "Agnerod North" },
	{ id = "UniqueStaff8", name = "Agnerod West" },
	{ id = "Ring11", name = "Gifts from Above" },
	{ id = "Ring12", name = "Death Rush" },
	{ id = "Ring13", name = "Shavronne's Revelation" },
	{ id = "Belt5", name = "Auxium" },
	{ id = "Amulet13", name = "Daresso's Salute" },
	{ id = "Amulet14", name = "Voll's Devotion" },
	{ id = "Amulet15", name = "Victario's Acuity" },
	{ id = "UniqueAmulet27", name = "Star of Wraeclast" },
	{ id = "UniqueAmulet29x", name = "Replica Winterheart" },
	{ id = "UniqueJewel82x", name = "Replica Primordial Might" },
	{ id = "UniqueBootsDex10", name = "Abberath's Hooves" },
	{ id = "UniqueRing54", name = "Precursor's Emblem" },
	{ id = "UniqueHelmetStrInt11", name = "Lightpoacher" },
	{ id = "UniqueBootsDexInt6", name = "Bubonic Trail" },
	{ id = "UniqueBodyDexInt9", name = "Shroud of the Lightless" },
	{ id = "UniqueGlovesStrInt6", name = "Volkuur's Guidance" },
	{ id = "UniqueBootsAtlas1", name = "Beacon of Madness" },
	{ id = "UniqueBootsAtlas1", name = "Demigod's Eye" },
	{ id = "UniqueShieldDemigods", name = "Demigod's Beacon" },
	{ id = "UniqueBootsDemigods1", name = "Demigod's Stride" },
	{ id = "UniqueBeltDemigods1", name = "Demigod's Bounty" },
	{ id = "UniqueBodyDemigods", name = "Demigod's Dominance" },
	{ id = "UniqueHelmetDemigods1", name = "Demigod's Immortality" },
	{ id = "UniqueQuiver1", name = "Blackgleam" },
	{ id = "FatedUnique8", name = "The Signal Fire" },
	{ id = "UniqueBootsStr1", name = "Windscream" },
	{ id = "FatedUnique35", name = "Windshriek" },
	{ id = "UniqueBodyDex7", name = "Briskwrap" },
	{ id = "FatedUnique31", name = "Wildwrap" },
	{ id = "UniqueShieldInt2", name = "Matua Tupuna" },
	{ id = "FatedUnique61", name = "Whakatutuki o Matua" },
	{ id = "UniqueBow8", name = "Storm Cloud" },
	{ id = "FatedUnique21", name = "The Tempest" },
	{ id = "UniqueBelt2", name = "The Magnate" },
	{ id = "FatedUnique46", name = "The Tactician" },
	{ id = "FatedUnique47", name = "The Nomad" },
	{ id = "UniqueStaff14", name = "The Stormheart" },
	{ id = "FatedUnique29", name = "The Stormwall" },
	{ id = "UniqueTwoHandAxe3", name = "Limbsplit" },
	{ id = "FatedUnique18", name = "The Cauteriser" },
	{ id = "UniqueTwoHandSword4", name = "Queen's Decree" },
	{ id = "FatedUnique25", name = "Queen's Escape" },
	{ id = "UniqueHelmetDexInt1", name = "Malachai's Simula" },
	{ id = "FatedUnique43", name = "Malachai's Awakening" },
	{ id = "UniqueRing2", name = "Kaom's Sign" },
	{ id = "FatedUnique1", name = "Kaom's Way" },
	{ id = "UniqueQuiver6", name = "Hyrri's Bite" },
	{ id = "FatedUnique49", name = "Hyrri's Demise" },
	{ id = "UniqueGlovesDex1", name = "Hrimsorrow" },
	{ id = "FatedUnique10", name = "Hrimburn" },
	{ id = "UniqueTwoHandMace2", name = "Geofri's Baptism" },
	{ id = "FatedUnique52", name = "Geofri's Devotion" },
	{ id = "UniqueDexHelmet2", name = "Heatshiver" },
	{ id = "FatedUnique36", name = "Frostferno" },
	{ id = "UniqueBootsStrDex3", name = "Dusktoe" },
	{ id = "FatedUnique26", name = "Duskblight" },
	{ id = "UniqueOneHandSword1", name = "Redbeak" },
	{ id = "FatedUnique54", name = "Dreadbeak" },
	{ id = "UniqueBow11", name = "Doomfletch" },
	{ id = "FatedUnique19", name = "Doomfletch's Prism" },
	{ id = "UniqueGlovesInt2", name = "Doedre's Tenure" },
	{ id = "FatedUnique28", name = "Doedre's Malevolence" },
	{ id = "UniqueBow3", name = "Death's Harp" },
	{ id = "FatedUnique5", name = "Death's Opus" },
	{ id = "UniqueTwoHandMace5", name = "Chober Chaber" },
	{ id = "FatedUnique58", name = "Chaber Cairn" },
	{ id = "UniqueOneHandMace4", name = "Cameria's Maul" },
	{ id = "FatedUnique53", name = "Cameria's Avarice" },
	{ id = "UniqueIntHelmet2", name = "Asenath's Mark" },
	{ id = "FatedUnique41", name = "Asenath's Chant" },
	{ id = "UniqueWand8", name = "Reverberation Rod" },
	{ id = "FatedUnique23", name = "Amplification Rod" },
	-- add more as needed
}

-- Build stash layout lookup
for row in dat("UniqueStashLayout"):Rows() do
	local name = row.WordsKey.Text2
	local id = normalizeId(row.ItemVisualIdentity.Id)
	if id:find("Map") or id:find("AlternateArt") or id:find("AtlasUpgrade") or id:find("HeistQuest") then
		goto continue
	end

	uniqueNameLookup[id] = name
	unmatchedIds[id] = name

	::continue::
end

-- Build FlavourText lookup
local flavourTextById = {}
for c in dat("FlavourText"):Rows() do
	local id = normalizeId(c.Id)
	flavourTextById[id] = cleanAndSplit(tostring(c.Text))
end

-- Open output file
local out = io.open("../Data/FlavourText.lua", "w")
out:write('-- This file is automatically generated, do not edit!\n')
out:write('-- Flavour text data (c) Grinding Gear Games\n\n')
out:write('return {\n')

local index = 1

-- Export forced names first
for _, entry in ipairs(forcedNameList) do
	-- We use Text2 because Words.Text has "The Immortan" instead of "The Road Warrior" in PoB2. In PoB, Text seems to have some names with leading spaces.
	local name = entry.name
	local id = entry.id
	local textLines = flavourTextById[id]

	if textLines then
		out:write('\t[', index, '] = {\n')
		out:write('\t\tid = "', id, '",\n')
		out:write('\t\tname = "', name, '",\n')
		out:write('\t\ttext = {\n')
		for _, line in ipairs(textLines) do
			out:write('\t\t\t"', line, '",\n')
		end
		out:write('\t\t},\n')
		out:write('\t},\n')
		index = index + 1

		-- Track exported names
		exportedNames[name] = true
		unmatchedIds[id] = nil
	end
end

-- Export remaining stash layout uniques
for id, name in pairsSortByKey(uniqueNameLookup) do
	local lines = flavourTextById[id]
	if lines then
		out:write('\t[', index, '] = {\n')
		out:write('\t\tid = "', id, '",\n')
		out:write('\t\tname = "', name, '",\n')
		out:write('\t\ttext = {\n')
		for _, line in ipairs(lines) do
			out:write('\t\t\t"', line, '",\n')
		end
		out:write('\t\t},\n')
		out:write('\t},\n')
		index = index + 1

		exportedNames[name] = true
		unmatchedIds[id] = nil
	end
end

out:write('}\n')
out:close()

print("Flavour Texts exported.")

-- Print unmatched: only names never exported
print("Unique items from UniqueStashLayout without flavour text:")
for id, name in pairs(unmatchedIds) do
	if not exportedNames[name] then
		print(string.format("Id: %s, Name: %s", id, name))
	end
end
