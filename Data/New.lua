--
-- Upcoming uniques will live here until their mods/rolls are finalised
--

data.uniques.new = {

-- New

-- Reworked

}

-- Automatically generate Megalomaniac because like heck I'm entering all those variants manually lol
local lines = {
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
	table.insert(lines, "Variant: "..name)
	table.insert(lines, "{variant:"..index.."}1 Added Passive Skill is "..name)
end
table.insert(data.uniques.new, table.concat(lines, '\n'))