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

local watchersEyeLegacyMods = {
	[1] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Clarity: Mana as ES (Pre 3.12.0)",
		["variantText"] = "Gain (12-18)% of Maximum Mana as Extra Maximum Energy Shield while affected by Clarity",
	},
	[2] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Clarity: Mana Recovery Rate (Pre 3.12.0)",
		["variantText"] = "(20-30)% increased Mana Recovery Rate while affected by Clarity",
	},
	[3] = {
		["version"] = "3.8",
		["variantName"] = "Variant: Clarity: Red. Mana Cost (Pre 3.8)",
		["variantText"] = "-(10-5) to Total Mana Cost of Skills while affected by Clarity",
	},
	[4] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Discipline: ES Recovery Rate (Pre 3.12.0)",
		["variantText"] = "(20-30)% increased Energy Shield Recovery Rate while affected by Discipline",
	},
	[5] = {
		["version"] = "3.8.0",
		["variantName"] = "Variant: Malevolence: Inc. DoT Multi (Pre 3.8.0)",
		["variantText"] = "+(36-44)% Damage over Time Multiplier while affected by Malevolence",
	},
	[6] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Malevolence: Life/ES Rec. Rate (Pre 3.12.0)",
		["variantText"] = "(15-20)% increased Recovery rate of Life and Energy Shield while affected by Malevolence",
	},
	[7] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Precision: Inc. Crit Multiplier (Pre 3.12.0)",
		["variantText"] = "+(30-50)% to Critical Strike Multiplier while affected by Precision",
	},
	[8] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Vitality: Dmg Leeched as Life (Pre 3.12.0)",
		["variantText"] = "(1-1.5)% of Damage leeched as Life while affected by Vitality",
	},
	[9] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Vitality: Flat Life Regeneration (Pre 3.12.0)",
		["variantText"] = "(100-140) Life Regenerated per Second while affected by Vitality",
	},
	[10] = {
		["version"] = "3.12.0",
		["variantName"] = "Variant: Vitality: Life Recovery Rate (Pre 3.12.0)",
		["variantText"] = "(20-30)% increased Life Recovery Rate while affected by Vitality",
	},
	[11] = {
		["version"] = "3.8.0",
		["variantName"] = "Variant: Wrath: Lightn. Dmg Leech as Mana (Pre 3.8.0)",
		["variantText"] = "(1-1.5)% of Lightning Damage is Leeched as Mana while affected by Wrath",
	},
}

local watchersEye = { [[
		Watcher's Eye
		Prismatic Jewel
		Source: Drops from unique{The Elder}
		Has Alt Variant: true
		Has Alt Variant Two: true]]
}

for _, mod in ipairs(data.uniqueMods["Watcher's Eye"]) do
	table.insert(watchersEye, "Variant: " .. mod.Id:gsub("^[Purity Of ]*%u%l+", "%1:"):gsub("[%u%d]", " %1"):gsub("_", ""))
end
for _, mod in ipairs(watchersEyeLegacyMods) do
	table.insert(watchersEye, mod.variantName)
end

table.insert(watchersEye,
[[Limited to: 1
(4-6)% increased maximum Energy Shield
(4-6)% increased maximum Life
(4-6)% increased maximum Mana]])

local index = 1
for _, mod in ipairs(data.uniqueMods["Watcher's Eye"]) do
	table.insert(watchersEye, "{variant:" .. index .. "}" .. mod.mod[1])
	index = index + 1
end
for _, mod in ipairs(watchersEyeLegacyMods) do
	table.insert(watchersEye, "{variant:" .. index .. "}" .. mod.variantText)
	index = index + 1
end

table.insert(data.uniques.generated, table.concat(watchersEye, "\n"))
