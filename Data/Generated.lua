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
for name in pairs(data["3_0"].clusterJewels.notableSortOrder) do
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
local excludedGems = {
	"Block Chance Reduction",
	"Empower",
	"Enhance",
	"Enlighten",
	"Item Quantity",
}
local gems = { }
for _, gemData in pairs(data["3_0"].gems) do
	local grantedEffect = gemData.grantedEffect
	if grantedEffect.support and not (grantedEffect.plusVersionOf) and not isValueInArray(excludedGems, grantedEffect.name) then
		table.insert(gems, grantedEffect.name)
	end
end
table.sort(gems)
for index, name in ipairs(gems) do
	table.insert(forbiddenShako, "Variant: "..name)
	table.insert(forbiddenShako, "{variant:"..index.."}Socketed Gems are Supported by Level (15-25) "..name)
end
table.insert(forbiddenShako, "+(25-30) to all Attributes")
table.insert(data.uniques.generated, table.concat(forbiddenShako, "\n"))

local skinOfTheLords = {
	"Skin of the Lords",
	"Simple Robe",
	"League: Breach",
	"Source: Upgraded from unique{Skin of the Loyal} using currency{Blessing of Chayula}",
}
for _, name in ipairs(data.keystones) do
	table.insert(skinOfTheLords, "Variant: "..name)
end
table.insert(skinOfTheLords, "Implicits: 0")
table.insert(skinOfTheLords, "Sockets cannot be modified")
table.insert(skinOfTheLords, "+1 to Level of Socketed Gems")
table.insert(skinOfTheLords, "100% increased Global Defences")
table.insert(skinOfTheLords, "You can only Socket Corrupted Gems in this item")
for index, name in ipairs(data.keystones) do
	table.insert(skinOfTheLords, "{variant:"..index.."}"..name)
end
table.insert(skinOfTheLords, "Corrupted")
table.insert(data.uniques.generated, table.concat(skinOfTheLords, "\n"))
