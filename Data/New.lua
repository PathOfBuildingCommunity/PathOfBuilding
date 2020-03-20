--
-- Upcoming uniques will live here until their mods/rolls are finalised
--

data.uniques.new = {
-- 3.10
[[
Calamitous Visions
Small Cluster Jewel
Adds Lone Messenger
]],[[
Kitava's Teachings
Small Cluster Jewel
Adds Disciple of Kitava
]],[[
Natural Affinity
Small Cluster Jewel
Adds Nature's Patience
]],[[
One With Nothing
Small Cluster Jewel
Adds Hollow Palm Technique
]],[[
The Front Line
Small Cluster Jewel
Adds Veteran's Awareness
]],[[
The Interrogation
Small Cluster Jewel
Adds Secrets of Suffering
]],[[
The Siege
Small Cluster Jewel
Adds Kineticism
]],[[
Voices
Large Cluster Jewel
Variant: {3_0}Adds 1 Small Passive Skill
Variant: Adds 3 Small Passive Skills
Variant: Adds 5 Small Passive Skills
Variant: Adds 7 Small Passive Skills
Adds 3 Jewel Socket Passive Skills
{variant:1}Adds 1 Small Passive Skill which grants nothing
{variant:2}Adds 3 Small Passive Skills which grant nothing
{variant:3}Adds 5 Small Passive Skills which grant nothing
{variant:4}Adds 7 Small Passive Skills which grant nothing
]],


-- New

-- Reworked

}

-- Automatically generate Megalomaniac because like heck I'm entering all those variants manually lol
local lines = {
	"Megalomaniac",
	"Medium Cluster Jewel",
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