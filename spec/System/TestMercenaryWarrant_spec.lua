local warrantParser = require("Modules.MercenaryWarrantParser")

local sampleWarrant = [[
Mercenary Warrant
--------
Lotha, the Cynic
--------
Build: Stormhand
Mercenary Level: 69
--------
Conductivity
Greater Curse Effect (Tier: 3)
Greater More Duration (Tier: 3)
--------
Sigil of Power
More Duration (Tier: 2)
--------
Greater Stormcall
Greater Area of Effect (Tier: 3)
Greater Less Duration (Tier: 3)
Greater Elemental Focus (Tier: 3)
--------
Greater Shock Nova
Greater Critical Chance (Tier: 3)
Maximum Shock Effect (Tier: 3)
Second Wind (Tier: 3)
Faster Casting (Tier: 2)
--------
Lightning Warp
Faster Casting (Tier: 2)
Increased Area of Effect (Tier: 2)
--------
Purity of Lightning
]]

describe("TestMercenaryWarrant", function()
	before_each(function()
		newBuild()
		runCallback("OnFrame")
	end)

	it("Detects valid Mercenary Warrant text", function()
		assert.is_true(warrantParser.IsWarrantText(sampleWarrant))
		assert.is_false(warrantParser.IsWarrantText("Rarity: Rare\nSome Item"))
	end)

	it("Parses metadata, skills, and tiered supports from Warrant text", function()
		local parsed, errMsg = warrantParser.Parse(sampleWarrant, build.skillsTab)
		assert.is_nil(errMsg)
		assert.are.equals("Lotha, the Cynic", parsed.name)
		assert.are.equals("Stormhand", parsed.build)
		assert.are.equals(69, parsed.level)
		assert.are.equals("Intelligence", parsed.type)
		assert.are.equals(6, #parsed.skillGroups)

		assert.are.equals("Conductivity", parsed.skillGroups[1].gemList[1].nameSpec)
		assert.are.equals(3, parsed.skillGroups[1].gemList[2].mercTier)
		assert.are.equals(3, parsed.skillGroups[1].gemList[3].mercTier)
		assert.are.equals("Greater Stormcall", parsed.skillGroups[3].gemList[1].nameSpec)
		assert.are.equals("Purity of Lightning", parsed.skillGroups[6].gemList[1].nameSpec)
	end)

	it("Applies Warrant into SkillsTab, ItemsTab metadata, and PartyTab summary", function()
		build.spec.curAscendClassName = "Luminary"
		local ok = warrantParser.ApplyWarrant(build, sampleWarrant)
		assert.is_true(ok)

		assert.are.equals("Lotha, the Cynic", build.itemsTab.activeItemSet.mercenaryName)
		assert.are.equals("Stormhand", build.itemsTab.activeItemSet.mercenaryBuild)
		assert.are.equals(69, build.itemsTab.activeItemSet.mercenaryLevel)
		assert.are.equals("Intelligence", build.itemsTab.activeItemSet.mercenaryType)
		assert.are.equals(6, #build.skillsTab.mercenarySocketGroupList)
		assert.is_nil(build.skillsTab.mercenarySocketGroupList[3].gemList[1].errMsg)

		local summary = build.partyTab:BuildMercenarySummaryText()
		assert.is_truthy(summary:find("Conductivity"))
		assert.is_truthy(summary:find("Tier 3"))
		assert.is_truthy(summary:find("Purity of Lightning"))
	end)

	it("Parses PoE Trade Mercenary Warrant with Item Class/Rarity header and trailing note, adding to PartyTab roster", function()
		local tradeWarrant = [[
Item Class: Map Fragments
Rarity: Normal
Mercenary Warrant
--------
Tanua, the Pit-fighter
--------
Build: Earthshaker
Mercenary Level: 83
--------
Intimidating Cry
Greater Raging Cry (Tier: 3)
Cooldown Recovery (Tier: 2)
--------
Leap Slam
Brutality (Tier: 2)
Increased Area of Effect (Tier: 2)
--------
Earthquake of Amplification
Faster Attacks (Tier: 2)
Increased Area of Effect (Tier: 2)
Brutality (Tier: 2)
Concentrated Effect (Tier: 2)
Pulverise (Tier: 2)
--------
Sunder of Trarthus
Brutality (Tier: 2)
Greater Pulverise (Tier: 3)
Greater Concentrated Effect (Tier: 3)
Greater Area of Effect (Tier: 3)
Greater Faster Attacks (Tier: 3)
--------
Vaal Vitality
Increased Area of Effect (Tier: 2)
Cooldown Recovery (Tier: 2)
--------
Molten Shell
Greater Cooldown Recovery (Tier: 3)
More Duration (Tier: 2)
--------
Right click this item to view Mercenary details.
Open a portal to the Proving Grounds by using this item in a personal Map Device. This previously fought Mercenary will reappear in the area for a rematch. While viewing your Atlas, Right-click this item to pinpoint its location.
--------
Note: ~b/o 1 chaos
]]

		assert.is_true(warrantParser.IsWarrantText(tradeWarrant))
		local ok1 = warrantParser.ApplyWarrant(build, sampleWarrant)
		local ok2 = warrantParser.ApplyWarrant(build, tradeWarrant)
		assert.is_true(ok1)
		assert.is_true(ok2)

		-- Both mercenaries are present in PartyTab roster and selectable
		assert.are.equals(2, #build.partyTab.mercenaries)
		local active = build.partyTab:GetActiveMercenary()
		assert.are.equals("Tanua, the Pit-fighter", active.name)
		assert.are.equals("Earthshaker", active.build)
		assert.are.equals("Strength", active.type)
		assert.are.equals(83, active.level)
		assert.are.equals(6, #active.skills)
		assert.are.equals("Molten Shell", active.skills[6].label)

		local summary = build.partyTab:BuildMercenarySummaryText()
		assert.is_truthy(summary:find("Intimidating Cry"))
		assert.is_truthy(summary:find("Sunder of Trarthus"))
		assert.is_falsy(summary:find("Right click"))
		assert.is_falsy(summary:find("~b/o"))
	end)
end)
