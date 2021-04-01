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

--[[ 3 scenarios exist for legacy mods
	- Mod changed, but kept the same mod Id
		-- Has legacyMod
	- Mod removed, or changed with a new mod Id
		-- Has only a version when it changed
	- Mod changed/removed, but isn't legacy
		-- Has empty table to exclude it from the list
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
Source: Drops from unique{The Elder}
Has Alt Variant: true
Has Alt Variant Two: true
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

for _, mod in ipairs(data.uniqueMods["Watcher's Eye"]) do
	local variantName = abbreviateModId(mod.Id):gsub("^[Purity Of ]*%u%l+", "%1:"):gsub("New", ""):gsub("[%u%d]", " %1"):gsub("_", ""):gsub("E S", "ES")
	if watchersEyeLegacyMods[mod.Id] then
		if watchersEyeLegacyMods[mod.Id].version then
			table.insert(watchersEye, "Variant:" .. variantName .. " (Pre " .. watchersEyeLegacyMods[mod.Id].version .. ")")
		end
		if watchersEyeLegacyMods[mod.Id].legacyMod then
			table.insert(watchersEye, "Variant:" .. variantName)
		end
	else
		table.insert(watchersEye, "Variant:" .. variantName)
	end
end

table.insert(watchersEye,
[[Limited to: 1
(4-6)% increased maximum Energy Shield
(4-6)% increased maximum Life
(4-6)% increased maximum Mana]])

local index = 1
for _, mod in ipairs(data.uniqueMods["Watcher's Eye"]) do
	if watchersEyeLegacyMods[mod.Id] then
		if watchersEyeLegacyMods[mod.Id].legacyMod then
			table.insert(watchersEye, "{variant:" .. index .. "}" .. watchersEyeLegacyMods[mod.Id].legacyMod(mod.mod[1]))
			index = index + 1
		end
		if watchersEyeLegacyMods[mod.Id].version then
			table.insert(watchersEye, "{variant:" .. index .. "}" .. mod.mod[1])
			index = index + 1
		end
	else
		table.insert(watchersEye, "{variant:" .. index .. "}" .. mod.mod[1])
		index = index + 1
	end
end

table.insert(data.uniques.generated, table.concat(watchersEye, "\n"))
