describe("TestPartyTabMercenary", function()
	before_each(function()
		newBuild()
		runCallback("OnFrame")
	end)

	it("Shows Mercenary section in PartyTab for Luminary or when Mercenary data exists", function()
		assert.is_false(build.partyTab:IsMercenaryShown())
		build.spec.curAscendClassName = "Luminary"
		assert.is_true(build.partyTab:IsMercenaryShown())
	end)

	it("Serializes and restores <Party><Mercenary> across Save, Load, and PostLoad", function()
		build.spec.curAscendClassName = "Luminary"
		build.itemsTab:CreateDisplayItemFromRaw("Crown of Thorns\nVine Circlet")
		build.itemsTab:AddDisplayItem(true)
		local helm = build.itemsTab.items[#build.itemsTab.itemOrderList]
		build.itemsTab.activeItemSet.mercenaryItems["Helmet"] = helm.id
		build.itemsTab.activeItemSet.mercenaryName = "Lotha, the Cynic"
		build.itemsTab.activeItemSet.mercenaryBuild = "Stormhand"
		build.itemsTab.activeItemSet.mercenaryType = "Intelligence"
		build.itemsTab.activeItemSet.mercenaryLevel = 69

		local mercGroup = {
			label = "Purity of Lightning",
			enabled = true,
			isMercenary = true,
			gemList = {
				{ nameSpec = "Purity of Lightning", level = 19, quality = 0, enabled = true, enableGlobal1 = true, enableGlobal2 = true, count = 1 },
			},
		}
		build.skillsTab:ProcessSocketGroup(mercGroup)
		table.insert(build.skillsTab.mercenarySocketGroupList, mercGroup)

		local partyXML = { elem = "Party" }
		build.partyTab:Save(partyXML)

		-- Reset mercenary state and reload from <Party> XML via Load + PostLoad
		build.itemsTab.activeItemSet.mercenaryItems = {}
		build.itemsTab.activeItemSet.mercenaryName = nil
		wipeTable(build.skillsTab.mercenarySocketGroupList)

		build.partyTab:Load(partyXML, "test.xml")
		build.partyTab:PostLoad()

		assert.are.equals("Lotha, the Cynic", build.itemsTab.activeItemSet.mercenaryName)
		assert.are.equals(69, build.itemsTab.activeItemSet.mercenaryLevel)
		assert.are.equals(helm.id, build.itemsTab.activeItemSet.mercenaryItems["Helmet"])
		assert.are.equals(1, #build.skillsTab.mercenarySocketGroupList)
		assert.are.equals("Purity of Lightning", build.skillsTab.mercenarySocketGroupList[1].label)
	end)

	it("Imports mocked league-account mercenary payload into ItemsTab and SkillsTab", function()
		build.spec.curAscendClassName = "Luminary"
		local mockMerc = {
			name = "Lotha, the Cynic",
			build = "Stormhand",
			level = 69,
			items = {
				{
					inventoryId = "Helm",
					frameType = 3,
					name = "Crown of Thorns",
					typeLine = "Vine Circlet",
					ilvl = 69,
				},
			},
			skills = {
				{
					name = "Conductivity",
					level = 19,
					supports = {
						{ name = "Greater Curse Effect", tier = 3 },
					},
				},
			},
		}

		build.importTab:ImportMercenary(mockMerc, true, true)

		assert.are.equals("Lotha, the Cynic", build.itemsTab.activeItemSet.mercenaryName)
		assert.are.equals("Intelligence", build.itemsTab.activeItemSet.mercenaryType)
		assert.is_truthy(build.itemsTab.activeItemSet.mercenaryItems["Helmet"])
		assert.are.equals(1, #build.skillsTab.mercenarySocketGroupList)
		assert.are.equals(2, #build.skillsTab.mercenarySocketGroupList[1].gemList)
		assert.are.equals(3, build.skillsTab.mercenarySocketGroupList[1].gemList[2].mercTier)
	end)

	it("Builds PC and console DownloadLeagueAccount URLs cleanly", function()
		local capturedUrls = {}
		local api = new("PoEAPI"):PoEAPI("tok", "ref", os.time() + 3600)
		api.DownloadWithRateLimit = function(_, _, url, cb)
			table.insert(capturedUrls, url)
			if cb then cb({}, nil) end
		end

		api:DownloadLeagueAccount("pc", "Mercenaries of Trarthus", function() end)
		api:DownloadLeagueAccount("xbox", "Standard", function() end)

		assert.are.equals("/league-account/Mercenaries%20of%20Trarthus", capturedUrls[1])
		assert.are.equals("/league-account/xbox/Standard", capturedUrls[2])
	end)

	it("Shows Mercenary import row only for Luminary characters and imports selected roster entry", function()
		local importTab = build.importTab
		importTab.usingOauth = true
		importTab.isAuthorized = function() return true end

		importTab:BuildCharacterList("pc", "Covens", {
			{ name = "NonLumChar", realm = "pc", league = "Covens", class = "Inquisitor", level = 90 },
			{ name = "Chochi_flaca", realm = "pc", league = "Covens", class = "Luminary", level = 91 },
		}, importTab.controls.charSelect)

		-- Select Inquisitor -> Mercenary row hidden
		importTab.controls.charSelect.selIndex = 2
		if importTab.controls.charSelect:GetSelValue().char.class == "Luminary" then
			importTab.controls.charSelect.selIndex = 1
		end
		assert.is_false(importTab.controls.charImportMercenary:IsShown())

		-- Select Luminary -> Mercenary row shown
		for i, entry in ipairs(importTab.controls.charSelect.list) do
			if entry.char.class == "Luminary" then
				importTab.controls.charSelect.selIndex = i
				break
			end
		end
		assert.is_true(importTab.controls.charImportMercenary:IsShown())

		-- Populate sparse mercenary roster matching live /league-account/Covens shape
		local roster = {
			{
				index = 0,
				name = "Veth, the Vile",
				level = 83,
				build = "ChaosMinionWitchChaosHit",
				skills = { { name = "Despair", supports = { { name = "Increased Area of Effect", tier = 2 } } } },
				items = {},
			},
			{
				index = 2,
				name = "Draveth Azrus",
				level = 66,
				build = "EleBowRangerClones",
				skills = { { name = "Hatred", supports = {} } },
				items = {},
			},
		}
		importTab:PopulateMercenaryList("pc", "Covens", roster)
		assert.are.equals(2, #importTab.controls.mercenarySelect.list)

		-- Import both mercenaries and verify PartyTab roster switching + XML round-trip
		importTab:ImportMercenary(roster[1], true, true)
		importTab:ImportMercenary(roster[2], true, true)

		assert.are.equals(2, #build.partyTab.mercenaries)
		assert.are.equals(2, build.partyTab.activeMercenaryIndex)
		assert.are.equals("Draveth Azrus", build.partyTab:GetActiveMercenary().name)
		assert.is_truthy(build.partyTab:BuildMercenarySummaryText():find("Hatred"))

		-- Switch to first mercenary on PartyTab
		build.partyTab:SetActiveMercenary(1)
		assert.are.equals("Veth, the Vile", build.partyTab:GetActiveMercenary().name)
		assert.are.equals("Veth, the Vile", build.itemsTab.activeItemSet.mercenaryName)
		assert.is_truthy(build.partyTab:BuildMercenarySummaryText():find("Despair"))

		-- Save and reload <Party><Mercenaries active="1">
		local partyXML = { elem = "Party" }
		build.partyTab:Save(partyXML)
		build.partyTab:Load(partyXML, "test.xml")
		build.partyTab:PostLoad()

		assert.are.equals(2, #build.partyTab.mercenaries)
		assert.are.equals(1, build.partyTab.activeMercenaryIndex)
		assert.are.equals("Veth, the Vile", build.partyTab:GetActiveMercenary().name)

		-- Remove active mercenary -> falls back cleanly to remaining entry
		build.partyTab:RemoveActiveMercenary()
		assert.are.equals(1, #build.partyTab.mercenaries)
		assert.are.equals("Draveth Azrus", build.partyTab:GetActiveMercenary().name)
	end)

	it("Populates Any Loadout item selector when a Mercenary item slot is selected on PartyTab", function()
		build.spec.curAscendClassName = "Luminary"
		build.itemsTab:CreateDisplayItemFromRaw("Crown of Thorns\nVine Circlet")
		build.itemsTab:AddDisplayItem(true)
		local helm = build.itemsTab.items[#build.itemsTab.itemOrderList]

		build.itemsTab:CreateDisplayItemFromRaw("New Item\nCobalt Jewel")
		build.itemsTab:AddDisplayItem(true)

		build.partyTab:UpsertMercenary({
			name = "Tanua, the Pit-fighter",
			build = "Earthshaker",
			type = "Strength",
			level = 83,
			skills = {},
			items = {},
		})

		-- All 10 wearable slots appear in mercenaryItemsList
		assert.are.equals(10, #build.partyTab.mercenaryItemRows)

		-- Select the Helmet row -> dropdown lists None + Crown of Thorns (excluding Jewel)
		local helmRowIdx
		for i, row in ipairs(build.partyTab.mercenaryItemRows) do
			if row.slotName == "Helmet" then
				helmRowIdx = i
				break
			end
		end
		build.partyTab.controls.mercenaryItemsList.selIndex = helmRowIdx
		build.partyTab.controls.mercenaryItemsList.selValue = build.partyTab.mercenaryItemRows[helmRowIdx]
		build.partyTab:SyncMercenaryItemPicker("Helmet")

		assert.are.equals(2, #build.partyTab.controls.mercenaryItemSelect.list)
		assert.are.equals(helm.id, build.partyTab.controls.mercenaryItemSelect.list[2].itemId)

		-- Equip Crown of Thorns via the dropdown callback
		build.partyTab.controls.mercenaryItemSelect.selFunc(2, build.partyTab.controls.mercenaryItemSelect.list[2])
		assert.are.equals(helm.id, build.partyTab:GetActiveMercenary().items["Helmet"])
		assert.are.equals(helm.id, build.partyTab.mercenaryItemRows[helmRowIdx].itemId)

		-- Adding a new valid Helmet in ItemsTab automatically refreshes the PartyTab dropdown
		build.itemsTab:CreateDisplayItemFromRaw("Goldrim\nLeather Cap")
		build.itemsTab:AddDisplayItem(true)
		assert.are.equals(3, #build.partyTab.controls.mercenaryItemSelect.list)
	end)

	it("Gates PartyTab code import of mercenaries on All destination and respects Append", function()
		build.spec.curAscendClassName = "Luminary"
		build.partyTab:UpsertMercenary({
			index = 0,
			name = "Veth, the Vile",
			build = "ChaosMinionWitchChaosHit",
			type = "Intelligence",
			level = 83,
			skills = {},
			items = {},
		})

		local partyCodeXML = [[
<PathOfBuilding>
	<Party destination="All">
		<ExportedBuffs name="Curse">--- Curse Limit ---
1</ExportedBuffs>
		<Mercenaries active="1">
			<Mercenary index="2" name="Draveth Azrus" build="EleBowRangerClones" type="Dexterity" level="66" />
		</Mercenaries>
	</Party>
</PathOfBuilding>
]]

		-- 1. Destination = Curse, Append = true -> existing mercenary must NOT be replaced or modified
		build.partyTab.controls.importCodeDestination:SelByValue("Curse")
		build.partyTab.controls.appendNotReplace.state = true
		build.partyTab.importCodeValid = true
		build.partyTab.importCodeFetching = false
		build.partyTab.importCodeXML = partyCodeXML
		build.partyTab.controls.importCodeGo.onClick()

		assert.are.equals(1, #build.partyTab.mercenaries)
		assert.are.equals("Veth, the Vile", build.partyTab:GetActiveMercenary().name)

		-- 2. Destination = All, Append = true -> appends imported mercenary and preserves active selection
		build.partyTab.controls.importCodeDestination:SelByValue("All")
		build.partyTab.controls.appendNotReplace.state = true
		build.partyTab.controls.importCodeGo.onClick()

		assert.are.equals(2, #build.partyTab.mercenaries)
		assert.are.equals(1, build.partyTab.activeMercenaryIndex)
		assert.are.equals("Veth, the Vile", build.partyTab:GetActiveMercenary().name)
		assert.are.equals("Draveth Azrus", build.partyTab.mercenaries[2].name)

		-- 3. Destination = All, Append = false -> replaces existing mercenaries
		build.partyTab.controls.appendNotReplace.state = false
		build.partyTab.controls.importCodeGo.onClick()

		assert.are.equals(1, #build.partyTab.mercenaries)
		assert.are.equals("Draveth Azrus", build.partyTab:GetActiveMercenary().name)
	end)
end)
