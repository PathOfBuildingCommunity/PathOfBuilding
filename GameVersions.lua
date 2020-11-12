-- Game versions
---Default target version for unknown builds and builds created before 3.0.0.
legacyTargetVersion = "2_6"
---Default target for new builds and target to convert legacy builds to.
liveTargetVersion = "3_0"
-- Skill tree versions
---Display, comparison and export data for all supported skill tree versions.
---@type table<string, {short: string, num: number, export: string}>
treeVersions = {
	["2_6"] = {
		short = "2.6",
		num = 2.06,
		export = "https://www.pathofexile.com/passive-skill-tree/2.6.2/",
	},
	["3_6"] = {
		short = "3.6",
		num = 3.06,
		export = "https://www.pathofexile.com/passive-skill-tree/3.6.0/",
	},
	["3_7"] = {
		short = "3.7",
		num = 3.07,
		export = "https://www.pathofexile.com/passive-skill-tree/3.7.0/",
	},
	["3_8"] = {
		short = "3.8",
		num = 3.08,
		export = "https://www.pathofexile.com/passive-skill-tree/3.8.0/",
	},
	["3_9"] = {
		short = "3.9",
		num = 3.09,
		export = "https://www.pathofexile.com/passive-skill-tree/3.9.0/",
	},
	["3_10"] = {
		short = "3.10",
		num = 3.10,
		export = "https://www.pathofexile.com/passive-skill-tree/3.10.0/",
	},
	["3_11"] = {
		short = "3.11",
		num = 3.11,
		export = "https://www.pathofexile.com/passive-skill-tree/3.11.0/",
	},
	["3_12"] = {
		short = "3.12",
		num = 3.12,
		export = "https://www.pathofexile.com/passive-skill-tree/3.12.0/",
	},
}
---Added for convenient indexing of skill tree versions.
---@type string[]
treeVersionList = {}
for version, _ in pairs(treeVersions) do
	table.insert(treeVersionList, version)
end
--- Always points to the latest skill tree version.
latestTreeVersion = treeVersionList[#treeVersionList]
---Tree version where multiple skill trees per build were introduced to PoBC.
defaultTreeVersion = treeVersionList[2]
