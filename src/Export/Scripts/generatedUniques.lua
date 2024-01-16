---
--- Programmatically generated uniques live here.
--- Some uniques have to be generated because the amount of variable mods makes it infeasible to implement them manually.
--- As a result, they are forward compatible to some extent as changes to the variable mods are picked up automatically.
---

if not loadStatFile then
	dofile("statdesc.lua")
end
loadStatFile("stat_descriptions.txt")

-- Utility functions
local abbreviateModId = function(string)
	return (string:
	gsub("Increased", "Inc"):
	gsub("Reduced", "Red."):
	gsub("Critical", "Crit"):
	gsub("Physical", "Phys"):
	gsub("Elemental", "Ele"):
	gsub("Multiplier", "Mult"):
	gsub("EnergyShield", "ES"))
end

local parseVeiledModName = function(string)
	return (string:
	gsub("%JunMasterVeiled", ""):
	gsub("%Local", ""):
	gsub("%Display", ""):
	gsub("%Crafted", ""):
	gsub("(%d)h", ""):
	gsub("%_", ""):
	gsub("(%l)(%u)", "%1 %2"):
	gsub("(%d)", " %1 "))
end

local veiledModIsActive = function(mod, baseType, specificType1, specificType2)
	local baseIndex, typeIndex1, typeIndex2
	for index, key in ipairs(mod.SpawnTags) do
		if key.Id == baseType then baseIndex = index end
		if key.Id == specificType1 then typeIndex1 = index end
		if key.Id == specificType2 then typeIndex2 = index end
	end
	return (typeIndex1 and mod.SpawnWeights[typeIndex1] > 0) or (typeIndex2 and mod.SpawnWeights[typeIndex2] > 0) or (not typeIndex1 and not typeIndex2 and baseIndex and mod.SpawnWeights[baseIndex] > 0)
end

local veiledModsPredicate = function (veiledPool, baseType, specificType1, specificType2)
	local activeVeiledPredicate = function(mod) return mod.Domain == 28 and veiledModIsActive(mod, baseType, specificType1, specificType2) end
	if veiledPool == "base" then 
		return function(mod) return activeVeiledPredicate(mod) and (mod.Name == "Chosen" or mod.Name == "of the Order") end 
	elseif veiledPool == "catarina" then
		return function(mod) return activeVeiledPredicate(mod) and (mod.Name == "Catarina's" or mod.Name == "Chosen" or mod.Name == "of the Order") end
	elseif veiledPool == "all" then
		return function(mod) return activeVeiledPredicate(mod) end
	end
end

local veiledModSortFunction = function(a, b)
	if a.GenerationType ~= b.GenerationType then
		return a.GenerationType < b.GenerationType
	else
		return parseVeiledModName(a.Id) < parseVeiledModName(b.Id)
	end
end

local writeTable = function(out, table)
    out:write('[[\n')
    for _, line in ipairs(table) do
        out:write(line)
    end
    out:write(']],\n')
end

local tableFromDat = function(datName, condFunc)
	local out = { }
	if condFunc then
		for row in dat(datName):Rows() do
			if condFunc(row) then
				table.insert(out, row)
			end
		end
	else 
		for row in dat(datName):Rows() do
			table.insert(out, row)
		end
	end
	return out
end

-- Exception tables
local excludedKeystones = {
	"Phase Acrobatics", -- removed from game
	"Mortal Conviction", -- removed from game
}

local excludedItemKeystones = {
	"Chaos Inoculation", -- to prevent infinite loop
	"Necromantic Aegis", -- to prevent infinite loop
}

local typos = {
	["OnHIt"] = "OnHit",
	["LIfe"] = "Life",
	["Enchange"] = "Endurance",
	["Blockedin"] = "BlockedIn",
	["Areaof"] = "AreaOf",
	["Exposureon"] = "ExposureOn",
	["Unaffectedby"] = "UnaffectedBy",
}

local fixTypos = function(str)
	for pattern, replacement in pairs(typos) do
		str = str:gsub(pattern, replacement)
	end
	return str
end
	

-- Generate uniques
-- Paradoxica
local paradoxicaMods = tableFromDat("Mods",
	function(mod) return veiledModsPredicate("base", "weapon", "one_hand_weapon")(mod) and mod.Type.Id ~= "DoubleDamageChance" end)
table.sort(paradoxicaMods, veiledModSortFunction)

local paradoxica = {[[
Paradoxica
Vaal Rapier
League: Betrayal
Source: Drops from unique{Intervention Leaders} in normal{Safehouses}
Has Alt Variant: true
Selected Variant: 4
Selected Alt Variant: 16
]]}
for _, mod in ipairs(paradoxicaMods) do
	local affixType = (mod.GenerationType == 1 and "Prefix") or (mod.GenerationType == 2 and "Suffix")
	local variantName = "("..affixType..") "..parseVeiledModName(mod.Id)
	table.insert(paradoxica, "Variant: "..variantName.."\n")
end
table.insert(paradoxica, [[
Requires Level 66, 212 Dex
Implicits: 1
+25% to Global Critical Strike Multiplier
]])
for index, mod in ipairs(paradoxicaMods) do 
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		table.insert(paradoxica, "{variant:"..index.."}"..stat.."\n")
	end
end
table.insert(paradoxica, "Attacks with this Weapon deal Double Damage\n")

-- Cane of Kulemak
local caneOfKulemakMods = tableFromDat("Mods",
	function(mod) return veiledModsPredicate("catarina", "weapon", "staff", "two_hand_weapon")(mod) end)
table.sort(caneOfKulemakMods, veiledModSortFunction)
local caneOfKulemakMinUnveiledModifierMagnitudes, caneOfKulemakMaxUnveiledModifierMagnitudes = 60, 90

local caneOfKulemak = {[[
Cane of Kulemak
Serpentine Staff
Source: Drops from unique{Catarina, Master of Undeath}
Has Alt Variant: true
Has Alt Variant Two: true
Selected Variant: 1
Selected Alt Variant: 20
]]}
for _, mod in ipairs(caneOfKulemakMods) do
	local affixType = (mod.GenerationType == 1 and "Prefix") or (mod.GenerationType == 2 and "Suffix")
	local variantName = "("..affixType..") "..parseVeiledModName(mod.Id)
	table.insert(caneOfKulemak, "Variant: "..variantName.."\n")
end
table.insert(caneOfKulemak, [[
Requires Level 68, 85 Str, 85 Int
Implicits: 1
+20% Chance to Block Attack Damage while wielding a Staff
]])
table.insert(caneOfKulemak, "("..caneOfKulemakMinUnveiledModifierMagnitudes.."-"..caneOfKulemakMaxUnveiledModifierMagnitudes..")% increased Unveiled Modifier magnitudes\n")
for index, mod in ipairs(caneOfKulemakMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		local minValue, maxValue = stat:match("%((%d+)%-(%d+)%)")
		if minValue then
			stat = stat:gsub("%(%d+%-%d+%)", "%("..tostring(math.floor(minValue*(100 + caneOfKulemakMinUnveiledModifierMagnitudes) / 100)).."%-"..tostring(math.floor(maxValue*(100 + caneOfKulemakMaxUnveiledModifierMagnitudes) / 100)).."%)")
		elseif stat == "+2 to Level of Socketed Support Gems" then
			stat = "+3 to Level of Socketed Support Gems"
		end
		table.insert(caneOfKulemak, "{variant:"..index.."}"..stat.."\n")
	end
end

-- Replica Paradoxica
local replicaParadoxicaMods = tableFromDat("Mods",
	function(mod) return veiledModsPredicate("all", "weapon", "one_hand_weapon")(mod) end)
table.sort(replicaParadoxicaMods, veiledModSortFunction)

local replicaParadoxica = {[[
Replica Paradoxica
Vaal Rapier
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
Has Alt Variant: true
Has Alt Variant Two: true
Has Alt Variant Three: true
Has Alt Variant Four: true
Has Alt Variant Five: true
Selected Variant: 1
Selected Alt Variant: 2
Selected Alt Variant Two: 3
Selected Alt Variant Three: 25
Selected Alt Variant Four: 27
Selected Alt Variant Five: 34
]]}
for _, mod in ipairs(replicaParadoxicaMods) do
	local affixType = (mod.GenerationType == 1 and "Prefix") or (mod.GenerationType == 2 and "Suffix")
	local variantName = "("..affixType..") "..parseVeiledModName(mod.Id)
	table.insert(replicaParadoxica, "Variant: "..variantName.."\n")
end
table.insert(replicaParadoxica, [[
Requires Level 66, 212 Dex
Implicits: 1
+25% to Global Critical Strike Multiplier
]])
for index, mod in ipairs(replicaParadoxicaMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		table.insert(replicaParadoxica, "{variant:"..index.."}"..stat.."\n")
	end
end

-- Queen's Hunger
local queensHungerMods = tableFromDat("Mods",
	function(mod) return veiledModsPredicate("base", "body_armour", "int_armour")(mod) end)
table.sort(queensHungerMods, veiledModSortFunction)
	
local queensHunger = {[[
The Queen's Hunger
Vaal Regalia
League: Betrayal
Source: Drops from unique{Catarina, Master of Undeath}
Has Alt Variant: true
Selected Variant: 1
Selected Alt Variant: 24
]]}
for _, mod in ipairs(queensHungerMods) do
	local affixType = (mod.GenerationType == 1 and "Prefix") or (mod.GenerationType == 2 and "Suffix")
	local variantName = "("..affixType..") "..parseVeiledModName(mod.Id)
	table.insert(queensHunger, "Variant: "..variantName.."\n")
end
table.insert(queensHunger, [[
Requires Level 68, 194 Int
Trigger Level 20 Bone Offering, Flesh Offering or Spirit Offering every 5 seconds
Offering Skills Triggered this way also affect you
(5-10)% increased Cast Speed
(100-130)% increased Energy Shield
(6-10)% increased maximum Life
]])
for index, mod in ipairs(queensHungerMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do 
		table.insert(queensHunger, "{variant:"..index.."}"..stat.."\n")
	end
end

-- Replica Dragonfang's Flight
local indexableSkillGems = tableFromDat("IndexableSkillGems")
table.sort(indexableSkillGems, function(a, b) return a.Skill < b.Skill end)

local replicaDragonfangsFlight = {[[
Replica Dragonfang's Flight
Onyx Amulet
Variant: Pre 3.23.0
Variant: Current
]]}
for _, skill in ipairs(indexableSkillGems) do
    table.insert(replicaDragonfangsFlight,'Variant: '..skill.Skill..'\n')
end
table.insert(replicaDragonfangsFlight, [[
Has Alt Variant: true
Selected Variant: 2
Selected Alt Variant: 215
LevelReq: 56
Implicits: 1
{tags: jewellery_attribute}+(10-16) to all Attributes
{variant:1}{tags:jewellery_resistance}+(10-15)% to all Elemental Resistances
{variant:2}{tags:jewellery_resistance}+(5-10)% to all Elemental Resistances
]])
local indexOffset = 2
for index, skill in ipairs(indexableSkillGems) do
    table.insert(replicaDragonfangsFlight, '{variant:'..index + indexOffset..'}+3 to Level of all '..skill.Skill..' Gems\n')
end
table.insert(replicaDragonfangsFlight, [[
{variant:1}(10-15)% increased Reservation Efficiency of Skills
{variant:2}(5-10)% increased Reservation Efficiency of Skills
{variant:1}Items and Gems have (10-15)% reduced Attribute Requirements
{variant:2}Items and Gems have (5-10)% reduced Attribute Requirements
]])

-- That Which Was Taken
local charmMods = tableFromDat("Mods",
	function(mod) return mod.Domain == 35 and not mod.Id:match("1$") end)
local parseCharmModName = function(id) return abbreviateModId(fixTypos(id)):gsub("AnimalCharm", ""):gsub("2$", ""):gsub("[%u]", " %1"):gsub("[%d]+", " %1"):gsub("E S", "ES") end
local getCharmModAscendancy = function(mod)
	if mod.GenerationType == 1 then
		return mod.Name:match("(%a+)'s")
	else
		return mod.Name:match("of the (%a+)")
	end
end
local charmModSortFunction = function(a, b)
	if getCharmModAscendancy(a) ~= getCharmModAscendancy(b) then
		return getCharmModAscendancy(a) < getCharmModAscendancy(b)
	else 
		return parseCharmModName(a.Id) < parseCharmModName(b.Id)
	end
end
table.sort(charmMods, charmModSortFunction)

local thatWhichWasTaken = {[[
Item Class: Jewels
Rarity: Unique
That Which Was Taken
Crimson Jewel
League: Affliction
Source: Drops from unique{King of the Mist}
Has Alt Variant: true
Has Alt Variant Two: true
Has Alt Variant Three: true
Selected Variant: 1
Selected Alt Variant: 25
Selected Alt Variant Two: 66
Selected Alt Variant Three: 125
]]}
for _, mod in ipairs(charmMods) do
	local ascendancy = getCharmModAscendancy(mod)
	local variantName = "("..ascendancy..")"..parseCharmModName(mod.Id)
	table.insert(thatWhichWasTaken, "Variant: "..variantName.."\n")
end
table.insert(thatWhichWasTaken, [[
Limited to: 1
Requirements:
Level: 48
Item Level: 86
]])
for index, mod in ipairs(charmMods) do
    local stats, orders = describeMod(mod)
	for _, stat in ipairs(stats) do
		table.insert(thatWhichWasTaken, "{variant:"..index.."}"..stat.."\n")
	end
end

-- Forbidden Shako and Replica Forbidden Shako
local indexableSupportGems = tableFromDat("IndexableSupportGems")

local forbiddenShako = {[[
Forbidden Shako
Great Crown
League: Harvest
Source: Drops from unique{Oshabi, Avatar of the Grove}
Requires Level 68, 59 Str, 59 Int
Has Alt Variant: true
]]}
local replicaForbiddenShako = {[[
Replica Forbidden Shako
Great Crown
League: Heist
Source: Steal from a unique{Curio Display} during a Grand Heist
Requires Level 68, 59 Str, 59 Int
Has Alt Variant: true
]]}
for _, support in ipairs(indexableSupportGems) do
	table.insert(forbiddenShako, "Variant: "..support.Skill.. " (Low Level)\n")
	table.insert(forbiddenShako, "Variant: "..support.Skill.. " (High Level)\n")
	table.insert(replicaForbiddenShako, "Variant: "..support.Skill.. " (Low Level)\n")
	table.insert(replicaForbiddenShako, "Variant: "..support.Skill.. " (High Level)\n")
end
for index, support in ipairs(indexableSupportGems) do
	table.insert(forbiddenShako, "{variant:"..(index * 2 - 1).."}Socketed Gems are Supported by Level (1-10) "..support.Skill.."\n")
	table.insert(forbiddenShako, "{variant:"..(index * 2).."}Socketed Gems are Supported by Level (25-35) "..support.Skill.."\n")
	table.insert(replicaForbiddenShako, "{variant:"..(index * 2 - 1).."}Socketed Gems are Supported by Level (1-10) "..support.Skill.."\n")
	table.insert(replicaForbiddenShako, "{variant:"..(index * 2).."}Socketed Gems are Supported by Level (25-35) "..support.Skill.."\n")
end
table.insert(forbiddenShako, "+(25-30) to all Attributes\n")
table.insert(replicaForbiddenShako, "+(25-30) to all Attributes\n")

-- Megalomaniac
local notables = tableFromDat("PassiveTreeExpansionSpecialSkills",
	function(skill) return skill.Node.Notable end)

local megalomaniac = {[[
Megalomaniac
Medium Cluster Jewel
League: Delirium
Source: Drops from the Simulacrum Encounter
Has Alt Variant: true
Has Alt Variant Two: true
]]}
for _, notable in ipairs(notables) do
	table.insert(megalomaniac, "Variant: "..notable.Node.Name.."\n")
end
table.insert(megalomaniac, [[
Adds 4 Passive Skills
Added Small Passive Skills grant Nothing
]])
for index, notable in ipairs(notables) do
	table.insert(megalomaniac, "{variant:"..index.."}1 Added Passive Skill is "..notable.Node.Name.."\n")
end


-- Precursors Emblem
local precursorsMods = { }
precursorsMods["Power"] = tableFromDat("Mods", 
	function(mod) return mod.Id:match("^ChargeBonus") and mod.Type.Id:match("PowerCharge") end)
precursorsMods["Endurance"] = tableFromDat("Mods", 
	function(mod) return mod.Id:match("^ChargeBonus") and mod.Type.Id:match("EnduranceCharge") end)
precursorsMods["Frenzy"] = tableFromDat("Mods", 
	function(mod) return mod.Id:match("^ChargeBonus") and mod.Type.Id:match("FrenzyCharge") end)

local precursorsEmblem = {[[
Precursor's Emblem
{variant:1}Topaz Ring
{variant:2}Sapphire Ring
{variant:3}Ruby Ring
{variant:4}Two-Stone Ring (Cold/Lightning)
{variant:5}Two-Stone Ring (Fire/Lightning)
{variant:6}Two-Stone Ring (Fire/Cold)
{variant:7}Prismatic Ring
League: Delve
Source: Vendor Recipe
Has Alt Variant: true
Has Alt Variant Two: true
Has Alt Variant Three: true
LevelReq: 49
Implicits: 7
Selected Variant: 1
Selected Alt Variant: 48
Selected Alt Variant Two: 51
Selected Alt Variant Three: 61
Variant: Topaz Ring
Variant: Sapphire Ring
Variant: Ruby Ring
Variant: Two-Stone Ring (Cold/Lightning)
Variant: Two-Stone Ring (Fire/Lightning)
Variant: Two-Stone Ring (Fire/Cold)
Variant: Prismatic Ring
]]}
for type, mods in pairs(precursorsMods) do
	for _, mod in ipairs(mods) do
		local variantName = abbreviateModId(mod.Id):gsub("ChargeBonus", ""):gsub("[%u]", " %1"):gsub("E S", "ES"):gsub("_", "")
		table.insert(precursorsEmblem, "Variant: "..type.." -"..variantName.."\n")
	end
end
table.insert(precursorsEmblem,[[
{tags:jewellery_resistance}{variant:1}+(20-30)% to Lightning Resistance
{tags:jewellery_resistance}{variant:2}+(20-30)% to Cold Resistance
{tags:jewellery_resistance}{variant:3}+(20-30)% to Fire Resistance
{tags:jewellery_resistance}{variant:4}+(12-16)% to Cold and Lightning Resistances
{tags:jewellery_resistance}{variant:5}+(12-16)% to Fire and Lightning Resistances
{tags:jewellery_resistance}{variant:6}+(12-16)% to Fire and Cold Resistances
{tags:jewellery_resistance}{variant:7}+(8-10)% to all Elemental Resistances
{tags:jewellery_attribute}{variant:1}+20 to Intelligence
{tags:jewellery_attribute}{variant:2}+20 to Dexterity
{tags:jewellery_attribute}{variant:3}+20 to Strength
{tags:jewellery_attribute}{variant:4}+20 to Strength and Intelligence
{tags:jewellery_attribute}{variant:5}+20 to Dexterity and Intelligence
{tags:jewellery_attribute}{variant:6}+20 to Strength and Dexterity
{tags:jewellery_attribute}{variant:7}+20 to all Attributes
{tags:jewellery_defense}5% increased maximum Energy Shield
{tags:life}5% increased maximum Life
]])
local indexCounter = 8
for type, mods in pairs(precursorsMods) do
	for index, mod in ipairs(mods) do
		local stats, orders = describeMod(mod)
		for _, stat in ipairs(stats) do
			table.insert(precursorsEmblem, "{variant:"..indexCounter.."}"..stat.."\n")
		end
		indexCounter = indexCounter + 1
	end
end

-- The Balance of Terror
local balanceOfTerrorMods = tableFromDat("Mods",
	function(mod) return mod.Family[1].Id == "CurseCastBonus" end)

local balanceOfTerror = {[[
The Balance of Terror
Cobalt Jewel
League: Sanctum
Source: Drops from unique{Lycia, Herald of the Scourge} in normal{The Beyond}
Has Alt Variant: true
Has Alt Variant Two: true
Selected Alt Variant Two: 1
Limited to: 1
LevelReq: 56
]]}
-- Blank variant as 3 mod jewels were available in 3.20.1 to 3.21.0
table.insert(balanceOfTerror, "Variant: None\n")
for _, mod in ipairs(balanceOfTerrorMods) do
	local variantName = abbreviateModId(mod.Id):gsub("Unique__1", ""):gsub("[%u]", " %1")
	table.insert(balanceOfTerror, "Variant:"..variantName.."\n")
end
table.insert(balanceOfTerror, "+(10-15)% to all Elemental Resistances\n")
local indexOffset = 1
for index, mod in ipairs(balanceOfTerrorMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		table.insert(balanceOfTerror, "{variant:"..index + indexOffset.."}"..stat.."\n")
	end
end

-- Forbidden Flame/Flesh
local classNotables = tableFromDat("PassiveSkills",
	function(passive) return passive.Ascendancy and (not passive.Name:match("%[UNUSED%]") and passive.Ascendancy.Id ~= "Ascendant" and passive.Notable or passive.MultipleChoiceOption or passive.Id:match("Eldritch")) end)

local forbidden = { }
for _, name in pairs({"Flame", "Flesh"}) do
	forbidden[name] = { }
	table.insert(forbidden[name], "Forbidden " .. name.."\n")
	table.insert(forbidden[name], (name == "Flame" and "Crimson" or "Cobalt") .. " Jewel\n")
	for _, notable in ipairs(classNotables) do
		table.insert(forbidden[name], "Variant: ("..notable.Ascendancy.Class[1].Name..") "..notable.Name.."\n")
	end
	if name == "Flame" then
		table.insert(forbidden[name], "Source: Drops from unique{The Searing Exarch}\n")
	else
		table.insert(forbidden[name], "Source: Drops from unique{The Eater of Worlds}\n")
	end
	table.insert(forbidden[name], "Limited to: 1\n")
	table.insert(forbidden[name], "Item Level: 83\n")
	for index, notable in pairs(classNotables) do
		table.insert(forbidden[name], "{variant:"..index.."}".."Requires Class "..notable.Ascendancy.Class[1].Name.."\n")
		table.insert(forbidden[name], "{variant:"..index.."}".."Allocates "..notable.Name.." if you have the matching modifier on Forbidden "..(name == "Flame" and "Flesh" or "Flame").."\n")
	end
	table.insert(forbidden[name], "Corrupted")
end

-- Impossible Escape
local impossibleEscapeKeystones = tableFromDat("PassiveSkills",
	function(passive) return passive.Keystone and passive.FlavourText ~= "" and not passive.Id:match("_keystone_") and not isValueInArray(excludedItemKeystones, passive.Name) end)

local impossibleEscape = {[[
Impossible Escape
Viridian Jewel
League: Sentinel
Source: Drops from unique{The Maven}
Limited to: 1
Radius: Small
]]}
for _, keystone in ipairs(impossibleEscapeKeystones) do
	table.insert(impossibleEscape, "Variant: "..keystone.Name.."\n")
end
table.insert(impossibleEscape, "Variant: Everything (QoL Test Variant)\n")
local indexQOLVariant = #impossibleEscapeKeystones + 1
for index, keystone in ipairs(impossibleEscapeKeystones) do
	table.insert(impossibleEscape, "{variant:"..index..","..indexQOLVariant.."}Passives in radius of "..keystone.Name.." can be allocated without being connected to your tree\n")
end
table.insert(impossibleEscape, "Corrupted\n")

-- Skin of the Lords
local skinOfTheLordsKeystones = tableFromDat("PassiveSkills",
	function(passive) return passive.Keystone and passive.FlavourText ~= "" and not passive.Id:match("_keystone_") and not isValueInArray(excludedKeystones, passive.Name) and not isValueInArray(excludedItemKeystones, passive.Name) end)

local skinOfTheLords = {[[
Skin of the Lords
Simple Robe
League: Breach
Source: Upgraded from unique{Skin of the Loyal} using currency{Blessing of Chayula}
]]}
for _, keystone in ipairs(skinOfTheLordsKeystones) do
	table.insert(skinOfTheLords, "Variant: "..keystone.Name.."\n")
end
table.insert(skinOfTheLords, [[
Sockets cannot be modified
+2 to Level of Socketed Gems
100% increased Global Defences
You can only Socket Corrupted Gems in this item
]])
for index, keystone in ipairs(skinOfTheLordsKeystones) do
	table.insert(skinOfTheLords, "{variant:"..index.."}"..keystone.Name.."\n")
end

-- Sublime Vision
local sublimeVisionMods = tableFromDat("Mods",
	function(mod) return mod.Family[1].Id == "AuraBonus" and mod.Id:match("^SublimeVision") end)

local sublimeVision = {[[
Sublime Vision
Prismatic Jewel
Shaper Item
Source: Drops from unique{The Elder} (Uber Uber) or unique{The Shaper} (Uber)
Limited to: 1
]]}
for _, mod in ipairs(sublimeVisionMods) do
	local variantName = mod.Id:gsub("SublimeVision", "")
	table.insert(sublimeVision, "Variant: "..variantName.."\n")
end
for index, mod in ipairs(sublimeVisionMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		table.insert(sublimeVision, "{variant:"..index.."}"..stat.."\n")
	end
end

-- Vorana's March
local voranasMarchMods = tableFromDat("Mods",
	function(mod) return mod.Family[1].Id == "ArbalestBonus" end)

local voranasMarch = {[[
Vorana's March
Runic Sabatons
League: Expedition
Source: Drops from unique{Olroth, Origin of the Fall} in normal{Expedition Logbook}
Has Alt Variant: true
Has Alt Variant Two: true
Has Alt Variant Three: true
Selected Variant: 24
Selected Alt Variant: 10
Selected Alt Variant Two: 11
Selected Alt Variant Three: 13
]]}
-- Blank variant to account for changes made in 3.20.1
table.insert(voranasMarch, "Variant: None\n")
for _, mod in ipairs(voranasMarchMods) do
	local variantName = abbreviateModId(fixTypos(mod.Id)):gsub("SummonArbalist", ""):gsub("[%u%d]", " %1"):gsub("_", ""):gsub("Percent To ", ""):gsub("Chance To ", ""):gsub("Targets To ", ""):gsub("[fF]or 4 ?[Ss]econds On Hit", ""):gsub(" Percent", ""):gsub("Number Of ", "")
	table.insert(voranasMarch, "Variant:"..variantName.."\n")
end
table.insert(voranasMarch, [[
Requires Level 69, 46 Str, 46 Dex, 46 Int
Has no Sockets
Triggers Level 20 Summon Arbalists when Equipped
25% increased Movement Speed
]])
local indexOffset = 1
for index, mod in ipairs(voranasMarchMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		table.insert(voranasMarch, "{variant:"..index + indexOffset.."}"..stat.."\n")
	end
end

-- Watcher's Eye
local watchersEyeMods = tableFromDat("Mods",
	function(mod) return mod.Family[1].Id == "AuraBonus" and not mod.Id:match("^SublimeVision") and not mod.Id:match("^Synthesis") end)

--[[ 3 scenarios exist for legacy mods
	- Mod changed, but kept the same mod Id
		-- Has legacyMod
	- Mod removed, or changed with a new mod Id
		-- Has only a version when it changed
	- Mod changed/removed, but isn't legacy
		-- Has empty table to exclude it from the list

	4th scenario: Mod was changed (not legacy), but the mod ID (aka Variant name) no longer reflects the mod
		-- Has 'rename' field to customize the name
]]
local watchersEyeLegacyMods = {
	["ClarityManaAddedAsEnergyShield"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(12-18)")) end,
	},
	["ClarityReducedManaCost"] = {
		["version"] = "3.8.0",
	},
	["ClarityManaRecoveryRate"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(20-30)")) end,
	},
	["DisciplineEnergyShieldRecoveryRate"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(20-30)")) end,
	},
	["MalevolenceDamageOverTimeMultiplier"] = {
		["version"] = "3.8.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(36-44)")) end,
	},
	["MalevolenceLifeAndEnergyShieldRecoveryRate"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(15-20)")) end,
	},
	["PrecisionIncreasedCriticalStrikeMultiplier"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(30-50)")) end,
	},
	["VitalityDamageLifeLeech"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(1-1.5)")) end,
	},
	["VitalityFlatLifeRegen"] = {
		["version"] = "3.12.0",
	},
	["VitalityLifeRecoveryRate"] = {
		["version"] = "3.12.0",
		["legacyMod"] = function(currentMod) return (currentMod:gsub("%(.*%)", "(20-30)")) end,
	},
	["WrathLightningDamageManaLeech"] = {
		["version"] = "3.8.0",
	},
	["GraceChanceToDodge"] = {
		["rename"] = "Grace: Chance to Suppress Spells",
	},
	["HasteChanceToDodgeSpells"] = {
		["rename"] = "Haste: Chance to Suppress Spells",
	},
	["PurityOfFireReducedReflectedFireDamage"] = { },
	["PurityOfIceReducedReflectedColdDamage"] = { },
	["PurityOfLightningReducedReflectedLightningDamage"] = { },
	["MalevolenceSkillEffectDuration"] = { },
	["ZealotryMaximumEnergyShieldPerSecondToMaximumEnergyShieldLeechRate"] = { },
	["MalevolenceColdDamageOverTimeMultiplier"] = { },
	["MalevolenceChaosNonAilmentDamageOverTimeMultiplier"] = { },
}

local watchersEye = {[[
Watcher's Eye
Prismatic Jewel
Source: Drops from unique{The Elder} or unique{The Elder} (Uber)
Has Alt Variant: true
Has Alt Variant Two: true
Selected Variant: 5
Selected Alt Variant: 30
Selected Alt Variant Two: 1
]]}
-- Blank variant to account for changes made in 3.20.1
table.insert(watchersEye, "Variant: None\n")
for _, mod in ipairs(watchersEyeMods) do
	variantName = abbreviateModId(mod.Id):gsub("^[Purity Of ]*%u%l+", "%1:"):gsub("New", ""):gsub("[%u%d]", " %1"):gsub("_", ""):gsub("E S", "ES")
	if watchersEyeLegacyMods[mod.Id] then
		if watchersEyeLegacyMods[mod.Id].version then
			table.insert(watchersEye, "Variant:"..variantName.." (Pre "..watchersEyeLegacyMods[mod.Id].version..")\n")
		end
		if watchersEyeLegacyMods[mod.Id].legacyMod then
			table.insert(watchersEye, "Variant:"..variantName.."\n")
		end
		if watchersEyeLegacyMods[mod.Id].rename then
			table.insert(watchersEye, "Variant: "..watchersEyeLegacyMods[mod.Id].rename.."\n")
		end
	else
		table.insert(watchersEye, "Variant:"..variantName.."\n")
	end
end
table.insert(watchersEye, [[
Limited to: 1
(4-6)% increased maximum Energy Shield
(4-6)% increased maximum Life
(4-6)% increased maximum Mana
]])
local indexWatchersEye = 2
for index, mod in ipairs(watchersEyeMods) do
	local stats, order = describeMod(mod)
	for _, stat in ipairs(stats) do
		if watchersEyeLegacyMods[mod.Id] then
			if watchersEyeLegacyMods[mod.Id].legacyMod then
				table.insert(watchersEye, "{variant:"..indexWatchersEye.."}"..watchersEyeLegacyMods[mod.Id].legacyMod(stat).."\n")
				indexWatchersEye = indexWatchersEye + 1
			end
			if watchersEyeLegacyMods[mod.Id].version or watchersEyeLegacyMods[mod.Id].rename then
				table.insert(watchersEye, "{variant:"..indexWatchersEye.."}"..stat.."\n")
				indexWatchersEye = indexWatchersEye + 1
			end
		else
			table.insert(watchersEye, "{variant:"..indexWatchersEye.."}"..stat.."\n")
			indexWatchersEye = indexWatchersEye + 1
		end
	end
end

-- Write output to file
local out = io.open("../Data/Uniques/Special/Generated.lua", "w")
out:write('-- This file is automatically generated, do not edit!\n')
out:write('-- Item data (c) Grinding Gear Games\n\nreturn {\n')
writeTable(out, paradoxica)
writeTable(out, caneOfKulemak)
writeTable(out, replicaParadoxica)
writeTable(out, queensHunger)
writeTable(out, replicaDragonfangsFlight)
writeTable(out, thatWhichWasTaken)
writeTable(out, forbiddenShako)
writeTable(out, replicaForbiddenShako)
writeTable(out, megalomaniac)
writeTable(out, precursorsEmblem)
writeTable(out, balanceOfTerror)
writeTable(out, forbidden["Flame"])
writeTable(out, forbidden["Flesh"])
writeTable(out, impossibleEscape)
writeTable(out, skinOfTheLords)
writeTable(out, sublimeVision)
writeTable(out, voranasMarch)
writeTable(out, watchersEye)
out:write('}')
out:close()

print("Generated Uniques exported.")