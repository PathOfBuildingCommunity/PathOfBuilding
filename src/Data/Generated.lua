---
--- Programmatically generated uniques live here.
--- Some uniques have to be generated because the amount of variable mods makes it infeasible to implement them manually.
--- As a result, they are forward compatible to some extent as changes to the variable mods are picked up automatically.
---

data.uniques.generated = { }

local megalomaniac = {
	"Megalomaniac",
	"Medium Cluster Jewel",
	"League: Delirium",
	"Source: Drops from the Simulacrum Encounter",
	"Has Alt Variant: true",
	"Has Alt Variant Two: true",
	"Adds 4 Passive Skills",
	"Added Small Passive Skills grant Nothing",
}
local notables = { }
for name in pairs(data.clusterJewels.notableSortOrder) do
	table.insert(notables, name)
end
table.sort(notables)
for index, name in ipairs(notables) do
	table.insert(megalomaniac, "Variant: "..name)
	table.insert(megalomaniac, "{variant:"..index.."}1 Added Passive Skill is "..name)
end
table.insert(data.uniques.generated, table.concat(megalomaniac, "\n"))

local forbiddenShako = {
	"Forbidden Shako",
	"Great Crown",
	"League: Harvest",
	"Source: Drops from unique{Avatar of the Grove}",
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
	table.insert(forbiddenShako, "Variant: "..name)
	table.insert(forbiddenShako, "{variant:"..index.."}Socketed Gems are Supported by Level (15-25) "..name)
	table.insert(replicaForbiddenShako, "Variant: "..name.. " (Low Level)")
	table.insert(replicaForbiddenShako, "{variant:"..(index * 2 - 1).."}Socketed Gems are Supported by Level (1-10) "..name)
	table.insert(replicaForbiddenShako, "Variant: "..name.. " (High Level)")
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
		["Dodge Attacks"] = "1% Chance to Dodge Attack Hits per Endurance Charge",
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
		["Dodge Attacks"] = "1% Chance to Dodge Attack Hits per Frenzy Charge",
		["Accuracy Rating"] = "10% increased Accuracy Rating per Frenzy Charge",
		["Cold as Chaos"] = "Gain 1% of Cold Damage as Extra Chaos Damage per Frenzy Charge",
		["Attack and Cast Speed"] = "1% increased Attack and Cast Speed per Frenzy Charge",
		["Regen. Life"] = "Regenerate 0.3% of Life per second per Frenzy Charge",
		["Inc. Critical Strike Chance"] = "6% increased Critical Strike Chance per Frenzy Charge",
	},
	[1] = {
		["Gain on Hit"] = "10% chance to gain a Frenzy Charge on Hit",
		["+1 Maximum"] = "+1 to Maximum Frenzy Charges",
		["Flask Charge on Crit"] = "Gain a Flask Charge when you deal a Critical Strike while at maximum Frenzy Charges*",
		["Iron Reflexes"] = "You have Iron Reflexes while at maximum Frenzy Charges",
		["Onslaught"] = "Gain Onslaught for 4 seconds on Hit while at maximum Frenzy Charges*",
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
		["Dodge Attacks"] = "1% Chance to Dodge Attack Hits per Power Charge",
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
	"Precursor's Emblem",
	"League: Delve",
	"Variant: Topaz Ring",
	"Variant: Sapphire Ring",
	"Variant: Ruby Ring",
	"Variant: Two-Stone Ring (Cold/Lightning)",
	"Variant: Two-Stone Ring (Fire/Lightning)",
	"Variant: Two-Stone Ring (Fire/Cold)",
	"Variant: Prismatic Ring",
}

for prefix, type in pairs({ ["Endurance - "] = enduranceChargeMods, ["Frenzy - "] = frenzyChargeMods, ["Power - "] = powerChargeMods }) do
	for tier, mods in ipairs(type) do
		for desc, mod in pairs(mods) do
			table.insert(precursorsEmblem, "Variant: " .. prefix .. desc)
		end
	end
end
table.insert(precursorsEmblem, [[Selected Variant: 1
{variant:1}Topaz Ring
{variant:2}Sapphire Ring
{variant:3}Ruby Ring
{variant:4}Two-Stone Ring (Cold/Lightning)
{variant:5}Two-Stone Ring (Fire/Lightning)
{variant:6}Two-Stone Ring (Fire/Cold)
{variant:7}Prismatic Ring
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
			elseif mod:match("%(%-?[%d%.]+%-[%d%.]+%)%%") then
				mod = mod:gsub("(%(%-?[%d%.]+%-)([%d%.]+)%)", function(preceeding, higher) return preceeding .. tonumber(higher) * tier .. ")" end)
			elseif mod:match("%(%d+%-%d+%) to %(%d+%-%d+%)") then
				mod = mod:gsub("(%(%d+%-)(%d+)(%) to %(%d+%-)(%d+)%)", function(preceeding, higher1, middle, higher2) return preceeding .. higher1 * tier .. middle .. higher2 * tier .. ")" end)
			end

			table.insert(precursorsEmblem, "{variant:" .. index .. "}{range:0}" .. mod)
			index = index + 1
		end
	end
end
table.insert(data.uniques.generated, table.concat(precursorsEmblem, "\n"))

local skinOfTheLords = {
	"Skin of the Lords",
	"Simple Robe",
	"League: Breach",
	"Source: Upgraded from unique{Skin of the Loyal} using currency{Blessing of Chayula}",
}
local excludedKeystones = {
	"Chaos Inoculation", -- to prevent infinite loop
	"Corrupted Soul", -- exclusive to specific unique
	"Hollow Palm Technique", -- exclusive to specific unique
	"Immortal Ambition", -- exclusive to specific unique
	"Necromantic Aegis", -- to prevent infinite loop
}
local keystones = {}
for _, name in ipairs(data.keystones) do
	if not isValueInArray(excludedKeystones, name) then
		table.insert(keystones, name)
	end
end
for _, name in ipairs(keystones) do
	table.insert(skinOfTheLords, "Variant: "..name)
end
table.insert(skinOfTheLords, "Implicits: 0")
table.insert(skinOfTheLords, "Sockets cannot be modified")
table.insert(skinOfTheLords, "+1 to Level of Socketed Gems")
table.insert(skinOfTheLords, "100% increased Global Defences")
table.insert(skinOfTheLords, "You can only Socket Corrupted Gems in this item")
for index, name in ipairs(keystones) do
	table.insert(skinOfTheLords, "{variant:"..index.."}"..name)
end
table.insert(skinOfTheLords, "Corrupted")
table.insert(data.uniques.generated, table.concat(skinOfTheLords, "\n"))
