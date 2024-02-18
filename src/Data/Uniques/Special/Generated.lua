---
--- Programmatically generated uniques live here.
--- Some uniques have to be generated because the amount of variable mods makes it infeasible to implement them manually.
--- As a result, they are forward compatible to some extent as changes to the variable mods are picked up automatically.
---

data.uniques.generated = { }

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
	local baseIndex = isValueInTable(mod.weightKey, baseType)
	local typeIndex1 = isValueInTable(mod.weightKey, specificType1)
	local typeIndex2 = isValueInTable(mod.weightKey, specificType2)
	return (typeIndex1 and mod.weightVal[typeIndex1] > 0) or (typeIndex2 and mod.weightVal[typeIndex2] > 0) or (not typeIndex1 and not typeIndex2 and baseIndex and mod.weightVal[baseIndex] > 0)
end

local getVeiledMods = function (veiledPool, baseType, specificType1, specificType2)
	local veiledMods = { }
	for veiledModIndex, veiledMod in pairs(data.veiledMods) do
		if veiledModIsActive(veiledMod, baseType, specificType1, specificType2) then
			local veiledName = parseVeiledModName(veiledModIndex)

			veiledName = "("..veiledMod.type..") "..veiledName

			local veiled = { veiledName = veiledName, veiledLines = { } }
			for line, value in ipairs(veiledMod) do
				veiled.veiledLines[line] = value
			end

			if veiledPool == "base" and (veiledMod.affix == "Chosen" or veiledMod.affix == "of the Order") then
				table.insert(veiledMods, veiled)
			elseif veiledPool == "catarina" and (veiledMod.affix == "Catarina's" or veiledMod.affix == "Chosen" or veiledMod.affix == "of the Order") then
				table.insert(veiledMods, veiled)
			elseif veiledPool == "all" then
				table.insert(veiledMods, veiled)
			end
		end
	end
	table.sort(veiledMods, function (m1, m2) return m1.veiledName < m2.veiledName end )
	return veiledMods
end

local paradoxicaMods = getVeiledMods("base", "weapon", "one_hand_weapon")
local paradoxica = {
	"Paradoxica",
	"Vaal Rapier",
	"League: Betrayal",
	"Source: Drops from unique{Intervention Leaders} in normal{Safehouses}",
	"Has Alt Variant: true",
	"Selected Variant: 4",
	"Selected Alt Variant: 16"
}

for index, mod in pairs(paradoxicaMods) do
	if (mod.veiledName == "(Suffix) Double Damage Chance") then
		table.remove(paradoxicaMods, index)
	end
end

for index, mod in pairs(paradoxicaMods) do
	table.insert(paradoxica, "Variant: "..mod.veiledName)
end

table.insert(paradoxica, "Requires Level 66, 212 Dex")
table.insert(paradoxica, "Implicits: 1")
table.insert(paradoxica, "+25% to Global Critical Strike Multiplier")

for index, mod in pairs(paradoxicaMods) do
	for _, value in pairs(mod.veiledLines) do
		table.insert(paradoxica, "{variant:"..index.."}"..value.."")
	end
end

table.insert(paradoxica, "Attacks with this Weapon deal Double Damage")
table.insert(data.uniques.generated, table.concat(paradoxica, "\n"))

local caneOfKulemakMods = getVeiledMods("catarina", "weapon", "staff", "two_hand_weapon")
local caneOfKulemakMinUnveiledModifierMagnitudes, caneOfKulemakMaxUnveiledModifierMagnitudes = 60, 90
local caneOfKulemak = {
	"Cane of Kulemak",
	"Serpentine Staff",
	"Source: Drops from unique{Catarina, Master of Undeath}",
	"Has Alt Variant: true",
	"Has Alt Variant Two: true",
	"Selected Variant: 1",
	"Selected Alt Variant: 20"
}

for index, mod in pairs(caneOfKulemakMods) do
	table.insert(caneOfKulemak, "Variant: "..mod.veiledName)
end

table.insert(caneOfKulemak, "Requires Level 68, 85 Str, 85 Int")
table.insert(caneOfKulemak, "Implicits: 1")
table.insert(caneOfKulemak, "+20% Chance to Block Attack Damage while wielding a Staff")
table.insert(caneOfKulemak, "("..caneOfKulemakMinUnveiledModifierMagnitudes.."-"..caneOfKulemakMaxUnveiledModifierMagnitudes..")% increased Unveiled Modifier magnitudes")

for index, mod in pairs(caneOfKulemakMods) do
	for _, value in pairs(mod.veiledLines) do
		local minValue, maxValue = value:match("%((%d+)%-(%d+)%)")
		if minValue then
			value = value:gsub("%(%d+%-%d+%)", "%("..tostring(math.floor(minValue*(100 + caneOfKulemakMinUnveiledModifierMagnitudes) / 100)).."%-"..tostring(math.floor(maxValue*(100 + caneOfKulemakMaxUnveiledModifierMagnitudes) / 100)).."%)")
		elseif value == "+2 to Level of Socketed Support Gems" then
			value = "+3 to Level of Socketed Support Gems"
		end
		table.insert(caneOfKulemak, "{variant:"..index.."}"..value.."")
	end
end

table.insert(data.uniques.generated, table.concat(caneOfKulemak, "\n"))

local replicaParadoxicaMods = getVeiledMods("all", "weapon", "one_hand_weapon")
local replicaParadoxica = {
	"Replica Paradoxica",
	"Vaal Rapier",
	"League: Heist",
	"Source: Steal from a unique{Curio Display} during a Grand Heist",
	"Has Alt Variant: true",
	"Has Alt Variant Two: true",
	"Has Alt Variant Three: true",
	"Has Alt Variant Four: true",
	"Has Alt Variant Five: true",
	"Selected Variant: 1",
	"Selected Alt Variant: 2",
	"Selected Alt Variant Two: 3",
	"Selected Alt Variant Three: 25",
	"Selected Alt Variant Four: 27",
	"Selected Alt Variant Five: 34"
}

for index, mod in pairs(replicaParadoxicaMods) do
	table.insert(replicaParadoxica, "Variant: "..mod.veiledName)
end

table.insert(replicaParadoxica, "Requires Level 66, 212 Dex")
table.insert(replicaParadoxica, "Implicits: 1")
table.insert(replicaParadoxica, "+25% to Global Critical Strike Multiplier")

for index, mod in pairs(replicaParadoxicaMods) do
	for _, value in pairs(mod.veiledLines) do
		table.insert(replicaParadoxica, "{variant:"..index.."}"..value.."")
	end
end

table.insert(data.uniques.generated, table.concat(replicaParadoxica, "\n"))

local queensHungerMods = getVeiledMods("base", "body_armour", "int_armour")
local queensHunger = {
	"The Queen's Hunger",
	"Vaal Regalia",
	"League: Betrayal",
	"Source: Drops from unique{Catarina, Master of Undeath}",
	"Has Alt Variant: true",
	"Selected Variant: 1",
	"Selected Alt Variant: 24"
}

for index, mod in pairs(queensHungerMods) do
	table.insert(queensHunger, "Variant: "..mod.veiledName)
end

table.insert(queensHunger, "Requires Level 68, 194 Int")
table.insert(queensHunger, "Trigger Level 20 Bone Offering, Flesh Offering or Spirit Offering every 5 seconds")
table.insert(queensHunger, "Offering Skills Triggered this way also affect you")
table.insert(queensHunger, "(5-10)% increased Cast Speed")
table.insert(queensHunger, "(100-130)% increased Energy Shield")
table.insert(queensHunger, "(6-10)% increased maximum Life")

for index, mod in pairs(queensHungerMods) do
	for _, value in pairs(mod.veiledLines) do
		table.insert(queensHunger, "{variant:"..index.."}"..value.."")
	end
end

table.insert(data.uniques.generated, table.concat(queensHunger, "\n"))



local megalomaniac = {
	"Megalomaniac",
	"Medium Cluster Jewel",
	"League: Delirium",
	"Source: Drops from the Simulacrum Encounter",
	"Has Alt Variant: true",
	"Has Alt Variant Two: true",
}
local notables = { }
for name in pairs(data.clusterJewels.notableSortOrder) do
	table.insert(notables, name)
end
table.sort(notables)
for index, name in ipairs(notables) do
	table.insert(megalomaniac, "Variant: "..name)
end
table.insert(megalomaniac, "Adds 4 Passive Skills")
table.insert(megalomaniac, "Added Small Passive Skills grant Nothing")
for index, name in ipairs(notables) do
	table.insert(megalomaniac, "{variant:"..index.."}1 Added Passive Skill is "..name)
end
table.insert(data.uniques.generated, table.concat(megalomaniac, "\n"))

local forbiddenShako = {
	"Forbidden Shako",
	"Great Crown",
	"League: Harvest",
	"Source: Drops from unique{Oshabi, Avatar of the Grove}",
	"Requires Level 68, 59 Str, 59 Int",
	"Has Alt Variant: true"
}
local replicaForbiddenShako = {
	"Replica Forbidden Shako",
	"Great Crown",
	"League: Heist",
	"Source: Steal from a unique{Curio Display} during a Grand Heist",
	"Requires Level 68, 59 Str, 59 Int",
	"Has Alt Variant: true"
}
local excludedGems = {
	"Block Chance Reduction",
	"Empower",
	"Enhance",
	"Enlighten",
	"Item Quantity",
}
local gems = { }
for _, gemData in pairs(data.gems) do
	local grantedEffect = gemData.grantedEffect
	if grantedEffect.support and not (grantedEffect.plusVersionOf) and not isValueInArray(excludedGems, grantedEffect.name) then
		table.insert(gems, grantedEffect.name)
	end
end
table.sort(gems)
for index, name in ipairs(gems) do
	table.insert(forbiddenShako, "Variant: "..name.. " (Low Level)")
	table.insert(forbiddenShako, "Variant: "..name.. " (High Level)")
	table.insert(replicaForbiddenShako, "Variant: "..name.. " (Low Level)")
	table.insert(replicaForbiddenShako, "Variant: "..name.. " (High Level)")
end
for index, name in ipairs(gems) do
	table.insert(forbiddenShako, "{variant:"..(index * 2 - 1).."}Socketed Gems are Supported by Level (1-10) "..name)
	table.insert(forbiddenShako, "{variant:"..(index * 2).."}Socketed Gems are Supported by Level (25-35) "..name)
	table.insert(replicaForbiddenShako, "{variant:"..(index * 2 - 1).."}Socketed Gems are Supported by Level (1-10) "..name)
	table.insert(replicaForbiddenShako, "{variant:"..(index * 2).."}Socketed Gems are Supported by Level (25-35) "..name)
end
table.insert(forbiddenShako, "+(25-30) to all Attributes")
table.insert(replicaForbiddenShako, "+(25-30) to all Attributes")
table.insert(data.uniques.generated, table.concat(forbiddenShako, "\n"))
table.insert(data.uniques.generated, table.concat(replicaForbiddenShako, "\n"))

local enduranceChargeMods = {
	[3] = {
		["Up to Max."] = "15% chance that if you would gain Endurance Charges, you instead gain up to your maximum number of Endurance Charges",
		["Duration"] = "(20-40)% increased Endurance Charge Duration",
		["Movement Speed"] = "1% increased Movement Speed per Endurance Charge",
		["Armour"] = "6% increased Armour per Endurance Charge",
		["Add Fire Damage"] = "(7-9) to (13-14) Fire Damage per Endurance Charge",
		["Inc. Damage"] = "5% increased Damage per Endurance Charge",
		["On Kill"] = "10% chance to gain an Endurance Charge on Kill",
	},
	[2] = {
		["Block Attacks"] = "1% Chance to Block Attack Damage per Endurance Charge",
		["Spell Suppression"] = "1% chance to Suppress Spell Damage per Endurance Charge",
		["Chaos Res"] = "+4% to Chaos Resistance per Endurance Charge",
		["Fire as Chaos"] = "Gain 1% of Fire Damage as Extra Chaos Damage per Endurance Charge",
		["Attack and Cast Speed"] = "1% increased Attack and Cast Speed per Endurance Charge",
		["Regen. Life"] = "Regenerate 0.3% of Life per second per Endurance Charge",
		["Inc. Critical Strike Chance"] = "6% increased Critical Strike Chance per Endurance Charge",
	},
	[1] = {
		["Gain every second"] = "Gain an Endurance Charge every second if you've been Hit Recently",
		["+1 Maximum"] = "+1 to Maximum Endurance Charges",
		["Cannot be Stunned"] = "You cannot be Stunned while at maximum Endurance Charges",
		["Vaal Pact"] = "You have Vaal Pact while at maximum Endurance Charges",
		["Intimidate"] = "Intimidate Enemies for 4 seconds on Hit with Attacks while at maximum Endurance Charges",
	},
}

local frenzyChargeMods = {
	[3] = {
		["Up to Max."] = "15% chance that if you would gain Frenzy Charges, you instead gain up to your maximum number of Frenzy Charges",
		["Duration"] = "(20-40)% increased Frenzy Charge Duration",
		["Movement Speed"] = "1% increased Movement Speed per Frenzy Charge",
		["Evasion"] = "8% increased Evasion Rating per Frenzy Charge",
		["Add Cold Damage"] = "(6-8) to (12-13) Cold Damage per Frenzy Charge",
		["Inc. Damage"] = "5% increased Damage per Frenzy Charge",
		["On Kill"] = "10% chance to gain an Frenzy Charge on Kill",
	},
	[2] = {
		["Block Attacks"] = "1% Chance to Block Attack Damage per Frenzy Charge",
		["Spell Suppression"] = "1% chance to Suppress Spell Damage per Frenzy Charge",
		["Accuracy Rating"] = "10% increased Accuracy Rating per Frenzy Charge",
		["Cold as Chaos"] = "Gain 1% of Cold Damage as Extra Chaos Damage per Frenzy Charge",
		["Attack and Cast Speed"] = "1% increased Attack and Cast Speed per Frenzy Charge",
		["Regen. Life"] = "Regenerate 0.3% of Life per second per Frenzy Charge",
		["Inc. Critical Strike Chance"] = "6% increased Critical Strike Chance per Frenzy Charge",
	},
	[1] = {
		["Gain on Hit"] = "10% chance to gain a Frenzy Charge on Hit",
		["+1 Maximum"] = "+1 to Maximum Frenzy Charges",
		["Flask Charge on Crit"] = "Gain a Flask Charge when you deal a Critical Strike while at maximum Frenzy Charges",
		["Iron Reflexes"] = "You have Iron Reflexes while at maximum Frenzy Charges",
		["Onslaught"] = "Gain Onslaught for 4 seconds on Hit while at maximum Frenzy Charges",
	},
}

local powerChargeMods = {
	[3] = {
		["Up to Max."] = "15% chance that if you would gain Power Charges, you instead gain up to your maximum number of Power Charges",
		["Duration"] = "(20-40)% increased Power Charge Duration",
		["Movement Speed"] = "1% increased Movement Speed per Power Charge",
		["Energy Shield"] = "3% increased Energy Shield per Power Charge",
		["Add Lightning Damage"] = "(1-2) to (18-20) Lightning Damage per Power Charge",
		["Inc. Damage"] = "5% increased Damage per Power Charge",
		["On Kill"] = "10% chance to gain an Power Charge on Kill",
	},
	[2] = {
		["Block Attacks"] = "1% Chance to Block Attack Damage per Power Charge",
		["Spell Suppression"] = "1% chance to Suppress Spell Damage per Power Charge",
		["Phys. Damage Red."] = "1% additional Physical Damage Reduction per Power Charge",
		["Lightning as Chaos"] = "Gain 1% of Lightning Damage as Extra Chaos Damage per Power Charge",
		["Attack and Cast Speed"] = "1% increased Attack and Cast Speed per Power Charge",
		["Regen. Life"] = "Regenerate 0.3% of Life per second per Power Charge",
		["Crit Strike Multi"] = "+3% to Critical Strike Multiplier per Power Charge",
	},
	[1] = {
		["Gain on Crit"] = "20% chance to gain a Power Charge on Critical Strike",
		["+1 Maximum"] = "+1 to Maximum Power Charges",
		["Arcane Surge with Spells"] = "Gain Arcane Surge on Hit with Spells while at maximum Power Charges",
		["Mind over Matter"] = "You have Mind over Matter while at maximum Power Charges",
		["Additional Curse"] = "You can apply an additional Curse while at maximum Power Charges",
	},
}

local precursorsEmblem = {
[[Precursor's Emblem
{variant:1}Topaz Ring
{variant:2}Sapphire Ring
{variant:3}Ruby Ring
{variant:4}Two-Stone Ring (Cold/Lightning)
{variant:5}Two-Stone Ring (Fire/Lightning)
{variant:6}Two-Stone Ring (Fire/Cold)
{variant:7}Prismatic Ring
League: Delve
Source: Vendor Recipe
Variant: Topaz Ring
Variant: Sapphire Ring
Variant: Ruby Ring
Variant: Two-Stone Ring (Cold/Lightning)
Variant: Two-Stone Ring (Fire/Lightning)
Variant: Two-Stone Ring (Fire/Cold)
Variant: Prismatic Ring]]
}

for _, type in ipairs({ { prefix = "Endurance - ", mods = enduranceChargeMods }, { prefix = "Frenzy - ", mods = frenzyChargeMods }, { prefix = "Power - ", mods = powerChargeMods } }) do
	for tier, mods in ipairs(type.mods) do
		for desc, mod in pairs(mods) do
			table.insert(precursorsEmblem, "Variant: " .. type.prefix .. desc)
		end
	end
end
table.insert(precursorsEmblem, [[Selected Variant: 1
Has Alt Variant: true
Has Alt Variant Two: true
Has Alt Variant Three: true
LevelReq: 49
Implicits: 7
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
{tags:life}5% increased maximum Life]])

local index = 8
for _, type in ipairs({ enduranceChargeMods, frenzyChargeMods, powerChargeMods }) do
	for tier, mods in ipairs(type) do
		for desc, mod in pairs(mods) do
			if mod:match("[%+%-]?[%d%.]*%d+%%") then
				mod = mod:gsub("([%d%.]*%d+)", function(num) return "(" .. num .. "-" .. tonumber(num) * tier .. ")" end)
			elseif mod:match("%(%-?[%d%.]+%-%-?[%d%.]+%)%%") then
				mod = mod:gsub("(%(%-?[%d%.]+%-)(%-?[%d%.]+)%)", function(preceding, higher) return preceding .. tonumber(higher) * tier .. ")" end)
			elseif mod:match("%(%d+%-%d+%) to %(%d+%-%d+%)") then
				mod = mod:gsub("(%(%d+%-)(%d+)(%) to %(%d+%-)(%d+)%)", function(preceding, higher1, middle, higher2) return preceding .. higher1 * tier .. middle .. higher2 * tier .. ")" end)
			end
			table.insert(precursorsEmblem, "{variant:" .. index .. "}{range:0}" .. mod)
			index = index + 1
		end
	end
end
table.insert(data.uniques.generated, table.concat(precursorsEmblem, "\n"))

local balanceOfTerrorMods = {
	["Vulnerability: Double Damage"] = "(6-10)% chance to deal Double Damage if you've cast Vulnerability in the past 10 seconds",
	["Vulnerability: Unaffected by Bleeding"] = "You are Unaffected by Bleeding if you've cast Vulnerability in the past 10 seconds",
	["Enfeeble: Critical Strike Multiplier"] = "+(30-40)% to Critical Strike Multiplier if you've cast Enfeeble in the past 10 seconds",
	["Enfeeble: Take no Extra Crit Damage"] = "Take no Extra Damage from Critical Strikes if you've cast Enfeeble in the past 10 seconds",
	["Despair: Immune to Curses"] = "Immune to Curses if you've cast Despair in the past 10 seconds",
	["Despair: Inflict Withered"] = "Inflict Withered for 2 seconds on Hit if you've cast Despair in the past 10 seconds",
	["Punishment: Immune to Reflected Damage"] = "Immune to Reflected Damage if you've cast Punishment in the past 10 seconds",
	["Punishment: Intimidate"] = "Intimidate Enemies on Hit if you've cast Punishment in the past 10 seconds",
	["Frostbite: Cold Exposure"] = "Cold Exposure on Hit if you've cast Frostbite in the past 10 seconds",
	["Frostbite: Unaffected by Freeze"] = "You are Unaffected by Freeze if you've cast Frostbite in the past 10 seconds",
	["Flammability: Fire Exposure"] = "Inflict Fire Exposure on Hit if you've cast Flammability in the past 10 seconds",
	["Flammability: Unaffected by Ignite"] = "You are Unaffected by Ignite if you've cast Flammability in the past 10 seconds",
	["Conductivity: Lightning Exposure"] = "Inflict Lightning Exposure on Hit if you've cast Conductivity in the past 10 seconds",
	["Conductivity: Unaffected by Shock"] = "You are Unaffected by Shock if you've cast Conductivity in the past 10 seconds",
	["Elemental Weakness: Immune to Exposure"] = "Immune to Exposure if you've cast Elemental Weakness in the past 10 seconds",
	["Elemental Weakness: Physical Damage as a Random Element"] = "Gain (30-40)% of Physical Damage as a Random Element if you've cast Elemental Weakness in the past 10 seconds",
	["Temporal Chains: Cooldown Recovery Rate"] = "(20-25)% increased Cooldown Recovery Rate if you've cast Temporal Chains in the past 10 seconds",
	["Temporal Chains: Action Speed"] = "Action Speed cannot be Slowed below Base Value if you've cast Temporal Chains in the past 10 seconds",
}

local balanceOfTerror = {
	"The Balance of Terror",
	"Cobalt Jewel",
	"League: Sanctum",
	"Source: Drops from unique{Lycia, Herald of the Scourge} in normal{The Beyond}",
	"Has Alt Variant: true",
	"Has Alt Variant Two: true",
	"Selected Alt Variant Two: 1",
	"Limited to: 1",
	"LevelReq: 56",
}

-- adding a blank variant for 3 mod jewels
table.insert(balanceOfTerror, "Variant: None")

for name, _ in pairs(balanceOfTerrorMods) do
	table.insert(balanceOfTerror, "Variant: "..name)
end

table.insert(balanceOfTerror, "+(10-15)% to all Elemental Resistances")

local index = 2
for _, line in pairs(balanceOfTerrorMods) do
	table.insert(balanceOfTerror, "{variant:"..index.."}"..line)
	index = index + 1
end

table.insert(data.uniques.generated, table.concat(balanceOfTerror, "\n"))

local skinOfTheLords = {
	"Skin of the Lords",
	"Simple Robe",
	"League: Breach",
	"Source: Upgraded from unique{Skin of the Loyal} using currency{Blessing of Chayula}",
}
local excludedItemKeystones = {
	"Corrupted Soul", -- exclusive to specific unique
	"Divine Flesh", -- exclusive to specific unique
	"Hollow Palm Technique", -- exclusive to specific unique
	"Immortal Ambition", -- exclusive to specific unique
	"Secrets of Suffering", -- exclusive to specific items
	"Inner Conviction", -- exclusive to specific items
	"Phase Acrobatics", -- removed from game
	"Mortal Conviction", -- removed from game
}
local excludedPassiveKeystones = {
	"Chaos Inoculation", -- to prevent infinite loop
	"Necromantic Aegis", -- to prevent infinite loop
}
local skinOfTheLordsKeystones = {}
for _, name in ipairs(data.keystones) do
	if not isValueInArray(excludedItemKeystones, name) and not isValueInArray(excludedPassiveKeystones, name) then
		table.insert(skinOfTheLordsKeystones, name)
	end
end
for _, name in ipairs(skinOfTheLordsKeystones) do
	table.insert(skinOfTheLords, "Variant: "..name)
end
table.insert(skinOfTheLords, "Implicits: 0")
table.insert(skinOfTheLords, "Sockets cannot be modified")
table.insert(skinOfTheLords, "+2 to Level of Socketed Gems")
table.insert(skinOfTheLords, "100% increased Global Defences")
table.insert(skinOfTheLords, "You can only Socket Corrupted Gems in this item")
for index, name in ipairs(skinOfTheLordsKeystones) do
	table.insert(skinOfTheLords, "{variant:"..index.."}"..name)
end
table.insert(skinOfTheLords, "Corrupted")
table.insert(data.uniques.generated, table.concat(skinOfTheLords, "\n"))

local impossibleEscapeKeystones = {}
for _, name in ipairs(data.keystones) do
	if not isValueInArray(excludedItemKeystones, name) then
		table.insert(impossibleEscapeKeystones, name)
	end
end
local impossibleEscape = {
	"Impossible Escape",
	"Viridian Jewel",
	"League: Sentinel",
	"Source: Drops from unique{The Maven}",
	"Limited to: 1",
	"Radius: Small"
}
for _, name in ipairs(impossibleEscapeKeystones) do
	table.insert(impossibleEscape, "Variant: "..name)
end
table.insert(impossibleEscape, "Variant: Everything (QoL Test Variant)")
local variantCount = #impossibleEscapeKeystones + 1
for index, name in ipairs(impossibleEscapeKeystones) do
	table.insert(impossibleEscape, "{variant:"..index..","..variantCount.."}Passives in radius of "..name.." can be allocated without being connected to your tree")
end
table.insert(impossibleEscape, "Corrupted")
table.insert(data.uniques.generated, table.concat(impossibleEscape, "\n"))

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

local watchersEye = {
[[
Watcher's Eye
Prismatic Jewel
Source: Drops from unique{The Elder} or unique{The Elder} (Uber)
Has Alt Variant: true
Has Alt Variant Two: true
Selected Variant: 5
Selected Alt Variant: 30
Selected Alt Variant Two: 1
]]
}

local sublimeVision = {
[[
Sublime Vision
Prismatic Jewel
Shaper Item
Source: Drops from unique{The Elder} (Uber Uber) or unique{The Shaper} (Uber)
Limited to: 1
]]
}

local voranasMarch = {
[[
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
]]
}

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

-- adding a blank variant to account for changes made in 3.20.1
table.insert(voranasMarch, "Variant: None")
table.insert(watchersEye, "Variant: None")

for _, mod in ipairs(data.uniqueMods["Watcher's Eye"]) do
	if not (mod.Id:match("^SublimeVision") or mod.Id:match("^SummonArbalist")) then
		local variantName = abbreviateModId(mod.Id):gsub("^[Purity Of ]*%u%l+", "%1:"):gsub("New", ""):gsub("[%u%d]", " %1"):gsub("_", ""):gsub("E S", "ES")
		if watchersEyeLegacyMods[mod.Id] then
			if watchersEyeLegacyMods[mod.Id].version then
				table.insert(watchersEye, "Variant:" .. variantName .. " (Pre " .. watchersEyeLegacyMods[mod.Id].version .. ")")
			end
			if watchersEyeLegacyMods[mod.Id].legacyMod then
				table.insert(watchersEye, "Variant:" .. variantName)
			end
			if watchersEyeLegacyMods[mod.Id].rename then
				table.insert(watchersEye, "Variant: " .. watchersEyeLegacyMods[mod.Id].rename)
			end
		else
			table.insert(watchersEye, "Variant:" .. variantName)
		end
	elseif not mod.Id:match("^SummonArbalist") then
		local variantName = mod.Id:gsub("SublimeVision", ""):gsub("[%u%d]", " %1")
		table.insert(sublimeVision, "Variant:" .. variantName)
	else
		local variantName = abbreviateModId(mod.Id):gsub("SummonArbalist", ""):gsub("[%u%d]", " %1"):gsub("_", ""):gsub("Percent To ", ""):gsub("Chance To ", ""):gsub("Targets To ", ""):gsub("[fF]or 4 ?[Ss]econds On Hit", ""):gsub(" Percent", ""):gsub("Number Of ", "")
		table.insert(voranasMarch, "Variant:" .. variantName)
	end
end

table.insert(watchersEye,
[[Limited to: 1
(4-6)% increased maximum Energy Shield
(4-6)% increased maximum Life
(4-6)% increased maximum Mana]])

table.insert(voranasMarch,
[[Requires Level 69, 46 Str, 46 Dex, 46 Int
Has no Sockets
Triggers Level 20 Summon Arbalists when Equipped
25% increased Movement Speed]])

local indexWatchersEye = 2
local indexSublimeVision = 1
local indexVoranasMarch = 2
for _, mod in ipairs(data.uniqueMods["Watcher's Eye"]) do
	if not (mod.Id:match("^SublimeVision") or mod.Id:match("^SummonArbalist")) then
		if watchersEyeLegacyMods[mod.Id] then
			if watchersEyeLegacyMods[mod.Id].legacyMod then
				table.insert(watchersEye, "{variant:" .. indexWatchersEye .. "}" .. watchersEyeLegacyMods[mod.Id].legacyMod(mod.mod[1]))
				indexWatchersEye = indexWatchersEye + 1
			end
			if watchersEyeLegacyMods[mod.Id].version or watchersEyeLegacyMods[mod.Id].rename then
				table.insert(watchersEye, "{variant:" .. indexWatchersEye .. "}" .. mod.mod[1])
				indexWatchersEye = indexWatchersEye + 1
			end
		else
			table.insert(watchersEye, "{variant:" .. indexWatchersEye .. "}" .. mod.mod[1])
			indexWatchersEye = indexWatchersEye + 1
		end
	elseif not mod.Id:match("^SummonArbalist") then
		for i, _ in ipairs(mod.mod) do
			table.insert(sublimeVision, "{variant:" .. indexSublimeVision .. "}" .. mod.mod[i])
		end
		indexSublimeVision = indexSublimeVision + 1
	else
		for i, _ in ipairs(mod.mod) do
			table.insert(voranasMarch, "{variant:" .. indexVoranasMarch .. "}" .. mod.mod[i])
		end
		indexVoranasMarch = indexVoranasMarch + 1
	end
end

table.insert(data.uniques.generated, table.concat(watchersEye, "\n"))
table.insert(data.uniques.generated, table.concat(sublimeVision, "\n"))
table.insert(data.uniques.generated, table.concat(voranasMarch, "\n"))

function buildTreeDependentUniques(tree)
	buildForbidden(tree.classNotables)
end

function buildForbidden(classNotables)
	local forbidden = { }
	for _, name in pairs({"Flame", "Flesh"}) do
		forbidden[name] = { }
		table.insert(forbidden[name], "Forbidden " .. name)
		table.insert(forbidden[name], (name == "Flame" and "Crimson" or "Cobalt") .. " Jewel")
		local index = 1
		for className, notableTable in pairs(classNotables) do
			if className ~= "alternate_ascendancies" then --Remove Affliction Ascendancy's
				for _, notableName in ipairs(notableTable) do
					table.insert(forbidden[name], "Variant: (" .. className .. ") " .. notableName)
					index = index + 1
				end
			end
		end
		if name == "Flame" then
			table.insert(forbidden[name], "Source: Drops from unique{The Searing Exarch}")
		else
			table.insert(forbidden[name], "Source: Drops from unique{The Eater of Worlds}")
		end
		table.insert(forbidden[name], "Limited to: 1")
		table.insert(forbidden[name], "Item Level: 83")
		index = 1
		for className, notableTable in pairs(classNotables) do
			if className ~= "alternate_ascendancies" then --Remove Affliction Ascendancy's
				for _, notableName in ipairs(notableTable) do
					table.insert(forbidden[name], "{variant:" .. index .. "}" .. "Requires Class " .. className)
					table.insert(forbidden[name], "{variant:" .. index .. "}" .. "Allocates ".. notableName .. " if you have the matching modifier on Forbidden " .. (name == "Flame" and "Flesh" or "Flame"))
					index = index + 1
				end
			end
		end
		table.insert(forbidden[name], "Corrupted")
	end
	table.insert(data.uniques.generated, table.concat(forbidden["Flame"], "\n"))
	table.insert(data.uniques.generated, table.concat(forbidden["Flesh"], "\n"))
end

-- That Which Was Taken
local thatWhichWasTaken = {
[[
Item Class: Jewels
Rarity: Unique
That Which Was Taken
Crimson Jewel
League: Affliction
Has Alt Variant: true
Has Alt Variant Two: true
Has Alt Variant Three: true
Selected Variant: 82
Selected Alt Variant: 104
Selected Alt Variant Two: 106
Selected Alt Variant Three: 125
Variant: None
]]
}

local unsortedCharmsMods = LoadModule("Data/ModJewelCharm")
local sortedCharmsMods = { }

for modId, mod in pairs(unsortedCharmsMods) do
	if not modId:match("1$") then
		table.insert(sortedCharmsMods, modId)
	end
end
table.sort(sortedCharmsMods)
for _, modId in ipairs(sortedCharmsMods) do
	local variantName = abbreviateModId(modId):gsub("AnimalCharm", ""):gsub("LIfe", "Life"):gsub("OnHIt", "OnHit"):gsub("2$", ""):gsub("New", ""):gsub("[%u]", " %1"):gsub("[%d]+", " %1"):gsub("_", ""):gsub("E S", "ES")
	table.insert(thatWhichWasTaken, "Variant:"..variantName)
end

table.insert(thatWhichWasTaken,
[[Limited to: 1
Requirements:
Level: 48
Item Level: 86
]]
)

local indexCharmMod = 2
for _, modId in ipairs(sortedCharmsMods) do
	local mod = unsortedCharmsMods[modId]
	for i, _ in ipairs(mod) do
		table.insert(thatWhichWasTaken, "{variant:" .. indexCharmMod .. "}" .. mod[i])
	end
	indexCharmMod = indexCharmMod + 1
end

table.insert(data.uniques.generated, table.concat(thatWhichWasTaken, "\n"))