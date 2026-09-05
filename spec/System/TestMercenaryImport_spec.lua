describe("Mercenary API import", function()
	local json = require("dkjson")
	local Import = require("Modules.MercenaryImport")
	local Tools = require("Modules.MercenaryTools")
	local helpers = dofile("../spec/System/MercenaryTestHelpers.lua")
	local file = assert(io.open("../spec/System/mercenary-league-account.json"))
	local fixture = assert(json.decode(file:read("*a")))
	file:close()
	local source = { account = "fixture-account", realm = "pc", league = "Test League" }
	local roster, tab
	before_each(function()
		newBuild()
		build.characterLevel = 97
		tab = build.mercenaryTab
		tab:EnsureData()
		roster = copyTable(fixture.league_account)
		roster.active_mercenary_index = fixture.character.active_mercenary_index
	end)
	after_each(function()
		while main.popups[1] do main:ClosePopup() end
	end)

	local function import(index, destination)
		local profile, err = build.importTab:ImportMercenary(roster.mercenaries[index], source, destination)
		assert.is_table(profile, err)
		return profile
	end

	local function itemCount()
		local count = 0
		for _ in pairs(build.itemsTab.items) do count = count + 1 end
		return count
	end

	it("converts both captured rosters with normal validation and exact totals", function()
		local skills, supports, equipment = 0, 0, 0
		for _, hire in ipairs(roster.mercenaries) do
			local profile = assert(Import.profile(hire, tab.data))
			assert.same({ }, Tools.validateProfile(profile, tab.data))
			assert.equals(83, profile.foundAreaLevel)
			assert.is_nil(profile.importedWarrant)
			skills = skills + #profile.skills
			equipment = equipment + #hire.items
			for _, skill in ipairs(profile.skills) do
				supports = supports + #skill.supports
				assert.is_true(skill.enabled)
				assert.is_false(skill.includeInFullDPS)
				assert.equals(1, skill.count)
			end
		end
		assert.same({12, 32, 20}, {skills, supports, equipment})
	end)

	it("resolves optional IDs through hashes without name substitution", function()
		local hire = roster.mercenaries[2]
		local expected = assert(Import.profile(hire, tab.data))
		for _, skill in ipairs(hire.skills) do
			skill.id = nil
			skill.name = "Wrong display name"
			for _, support in ipairs(skill.supports) do support.id = nil end
		end
		assert.same(expected, assert(Import.profile(hire, tab.data)))
	end)

	for _, case in ipairs({ "build hash", "skill hash", "support hash", "skill ID", "support tier", "unknown hash" }) do
		it("rejects "..case.." conflicts without mutating the build", function()
			local hire = roster.mercenaries[1]
			if case == "build hash" then hire.build_hash = -1
			elseif case == "skill hash" then hire.skills[1].hash = -1
			elseif case == "support hash" then hire.skills[1].supports[1].hash = -1
			elseif case == "skill ID" then hire.skills[1].id = "Unsupported"
			elseif case == "support tier" then hire.skills[1].supports[1].tier = 99
			else hire.skills[1].id = nil hire.skills[1].hash = -1 end
			local before = build:SaveDB("code")
			assert.is_nil(build.importTab:ImportMercenary(hire, source))
			assert.equals(before, build:SaveDB("code"))
		end)
	end

	it("imports independent sets and both nested jewels while preserving player and Guardian data", function()
		local itemsTab = build.itemsTab
		build.importTab:ImportItemsAndSkills({ level = 97, equipment = {{ id = "player", name = "", typeLine = "Iron Hat", frameType = 0, inventoryId = "Helm" }} }, false, false, false)
		local guardianSet = build.importTab:GetOrCreateGuardianItemSet()
		build.importTab:ImportItem({ id = "guardian", name = "", typeLine = "Leather Belt", frameType = 0, inventoryId = "Belt" }, nil, false, guardianSet.id)
		local playerBefore = copyTable(itemsTab.activeItemSet)
		local guardianBefore = copyTable(guardianSet)
		local skillsBefore = copyTable(build.skillsTab.socketGroupList)
		local first = import(1)
		local firstSet = copyTable(itemsTab.itemSets[first.itemSetId])
		local second = import(2)
		assert.not_equals(first.itemSetId, second.itemSetId)
		assert.same(firstSet, itemsTab.itemSets[first.itemSetId])
		local set = itemsTab.itemSets[second.itemSetId]
		for _, slot in ipairs({"Helmet Abyssal Socket 1", "Belt Abyssal Socket 1"}) do
			assert.is_true(set[slot].selItemId > 0)
			assert.equals("Abyss", itemsTab.items[set[slot].selItemId].base.subType)
		end
		assert.equals(24, itemCount())
		assert.same(playerBefore, itemsTab.activeItemSet)
		assert.same(guardianBefore, itemsTab.itemSets[guardianSet.id])
		assert.same(skillsBefore, build.skillsTab.socketGroupList)
		assert.equals(97, build.characterLevel)
		tab:SetActiveMercenarySet(first.id)
		assert.equals(first.itemSetId, tab.itemSetId)
		assert.equals(first.itemSetId, build.configTab.configSets[build.configTab.activeConfigSetId].actors.mercenary.itemSetId)
	end)

	it("reimports without duplication and clears removed slots", function()
		local first = import(1)
		local second = import(2)
		local firstBefore = copyTable(first)
		second.title = "My renamed hire"
		second.skills[1].includeInFullDPS = true
		second.skills[1].count = 3
		second.skills[1].skillPart = 2
		second.skills[2].enabled = false
		local again = import(2)
		assert.equals(second.id, again.id)
		assert.equals(22, itemCount())
		assert.equals(roster.mercenaries[2].name, again.title)
		assert.equals(1, again.skills[1].count)
		assert.is_nil(again.skills[1].skillPart)
		assert.is_false(again.skills[1].includeInFullDPS)
		assert.is_true(again.skills[1].enabled)
		assert.is_true(again.skills[2].enabled)
		for index, item in ipairs(roster.mercenaries[2].items) do
			if item.inventoryId == "Helm" then table.remove(roster.mercenaries[2].items, index) break end
		end
		local updated = import(2)
		local set = build.itemsTab.itemSets[updated.itemSetId]
		assert.equals(0, set.Helmet.selItemId)
		assert.equals(0, set["Helmet Abyssal Socket 1"].selItemId)
		assert.equals(20, itemCount())
		assert.same(firstBefore, tab.mercenarySets[first.id])
	end)

	it("stages invalid items atomically, including nested items", function()
		import(1)
		local before = build:SaveDB("code")
		roster.mercenaries[2].items[10].typeLine = "Unsupported item base"
		assert.is_nil(build.importTab:ImportMercenary(roster.mercenaries[2], source))
		assert.equals(before, build:SaveDB("code"))
	end)

	it("maps reordered equipment by inventoryId and omits player gem groups", function()
		local hire = roster.mercenaries[1]
		local reversed = { }
		for index = #hire.items, 1, -1 do table.insert(reversed, hire.items[index]) end
		hire.items = reversed
		hire.items[1].socketedItems = {{ typeLine = "Fireball", socket = 0, properties = { } }}
		local profile = import(1)
		assert.equals(10, itemCount())
		assert.equals(0, #build.skillsTab.socketGroupList)
		local weapon = build.itemsTab.items[build.itemsTab.itemSets[profile.itemSetId]["Weapon 1"].selItemId]
		assert.equals("Assassin Bow", weapon.baseName)
	end)

	it("preserves shared items and isolates explicitly shared equipment on reimport", function()
		local profile = import(1)
		local set = build.itemsTab.itemSets[profile.itemSetId]
		local helmetId = set.Helmet.selItemId
		build.itemsTab.activeItemSet.Helmet.selItemId = helmetId
		local oldItem = build.itemsTab.items[helmetId]
		import(1)
		assert.equals(oldItem, build.itemsTab.items[helmetId])
		assert.not_equals(helmetId, set.Helmet.selItemId)
		local other = tab:NewMercenarySet()
		other.itemSetId = profile.itemSetId
		table.insert(tab.mercenarySetOrderList, other.id)
		local oldSet = copyTable(set)
		local updated = import(1)
		assert.not_equals(other.itemSetId, updated.itemSetId)
		assert.same(oldSet, build.itemsTab.itemSets[other.itemSetId])
	end)

	it("requires ambiguous destinations and supports explicitly creating new loadouts", function()
		local original = import(1)
		local duplicate = import(1, 0)
		assert.not_equals(original.id, duplicate.id)
		assert.is_nil(build.importTab:ImportMercenary(roster.mercenaries[1], source))
		assert.equals(original.id, import(1, original.id).id)
	end)

	it("persists lower Mercenary levels, associations and equipment through XML and undo", function()
		roster.mercenaries[1].level = 40
		local first = import(1)
		local xml = { }
		tab:Save(xml)
		tab:Load(xml)
		assert.equals(40, tab.profile.foundAreaLevel)
		assert.equals(first.itemSetId, tab.itemSetId)
		assert.equals(first.importAssociation, tab.profile.importAssociation)
		import(2)
		build.itemsTab:Undo()
		assert.equals(first.id, tab.profile.id)
		assert.equals(40, tab.profile.foundAreaLevel)
		assert.equals(10, itemCount())
		build.itemsTab:Redo()
		assert.equals(83, tab.profile.foundAreaLevel)
		assert.equals(22, itemCount())
		assert.equals(97, build.characterLevel)
		assert.equals("^7Mercenary level:", tab.controls.levelLabel.label)
	end)

	it("migrates the old shared selection to every loadout and protects inactive sets", function()
		local first, second = import(1), import(2)
		local xml = { }
		tab:Save(xml)
		for _, node in ipairs(xml) do node.attrib.itemSetId = nil end
		tab:Load(xml)
		assert.equals(second.itemSetId, tab.mercenarySets[first.id].itemSetId)
		tab.mercenarySets[first.id].itemSetId = first.itemSetId
		assert.is_true(build.itemsTab:IsItemSetReferenced(first.itemSetId))
	end)

	it("selects only valid one-based active positions", function()
		for _, index in ipairs({1, 2}) do roster.active_mercenary_index = index assert.equals(index, Import.activeIndex(roster)) end
		for _, index in ipairs({0, -1, 3, 1.5, "2", false}) do roster.active_mercenary_index = index assert.is_nil(Import.activeIndex(roster)) end
		roster.active_mercenary_index = nil
		assert.is_nil(Import.activeIndex(roster))
		assert.is_nil(Import.activeIndex({mercenaries = { }, active_mercenary_index = 1}))
	end)

	it("walks the popup and imports the active Manyshot hire", function()
		build.importTab:OpenMercenaryImportPopup(roster, source)
		local popup = main.popups[1]
		assert.equals(2, popup.controls.hire.selIndex)
		assert.matches("Manyshot", popup.controls.hire:GetSelValue().label)
		assert.matches("Vorneka", popup.controls.hire:GetSelValue().label)
		assert.matches("%(Active%)", popup.controls.hire:GetSelValue().label)
		assert.equals(1, popup.controls.destination:GetSelValue().id)
		popup.controls.import.onClick()
		assert.equals("EleBowRangerClones", tab.profile.buildId)
		assert.equals("Vorneka Azrus", tab.profile.title)
		assert.equals(1, tab.profile.id)
		assert.equals(12, itemCount())
		main:ClosePopup()
	end)

	it("defaults the first hire when the active index is invalid", function()
		roster.active_mercenary_index = 1
		build.importTab:OpenMercenaryImportPopup(roster, source)
		local popup = main.popups[1]
		assert.equals(1, popup.controls.hire.selIndex)
		assert.matches("Thunderquiver", popup.controls.hire:GetSelValue().label)
		assert.matches("Ruktara", popup.controls.hire:GetSelValue().label)
		main:ClosePopup()
		roster.active_mercenary_index = 0
		build.importTab:OpenMercenaryImportPopup(roster, source)
		assert.equals(1, main.popups[1].controls.hire.selIndex)
		assert.matches("Ruktara", main.popups[1].controls.hire:GetSelValue().label)
		assert.is_nil((main.popups[1].controls.hire:GetSelValue().label):match("%(Active%)"))
		main:ClosePopup()
	end)

	it("does not open a popup for an empty roster", function()
		build.importTab:OpenMercenaryImportPopup({ mercenaries = { } }, source)
		assert.is_nil(main.popups[1])
	end)

	it("reuses the unused default loadout on first import", function()
		assert.equals(1, Import.unusedEmptyId(tab.mercenarySets, tab.mercenarySetOrderList))
		local profile = import(1)
		assert.equals(1, profile.id)
		assert.equals(1, #tab.mercenarySetOrderList)
		assert.equals("Ruktara, the Bullseye", profile.title)
		assert.is_nil(Import.unusedEmptyId(tab.mercenarySets, tab.mercenarySetOrderList))
	end)

	it("does not reimport into copied loadouts", function()
		local original = import(1)
		tab:OpenMercenarySetManagePopup()
		local list = main.popups[1].controls[1]
		list.selValue = original.id
		list.selIndex = 1
		list.controls.copy.onClick()
		main.popups[1].controls.edit.buf = "Copied hire"
		main.popups[1].controls.save.onClick()
		local copyId
		for _, id in ipairs(tab.mercenarySetOrderList) do
			if id ~= original.id then copyId = id end
		end
		assert.equals("Copied hire", tab.mercenarySets[copyId].title)
		assert.is_nil(tab.mercenarySets[copyId].importAssociation)
		assert.equals(original.id, import(1).id)
		assert.is_nil(tab.mercenarySets[copyId].importAssociation)
		assert.equals("Copied hire", tab.mercenarySets[copyId].title)
		main:ClosePopup()
	end)

	it("matches reimports after roster reordering", function()
		local ruktara = import(1)
		local vorneka = import(2)
		roster.mercenaries[1], roster.mercenaries[2] = roster.mercenaries[2], roster.mercenaries[1]
		assert.equals(vorneka.id, build.importTab:ImportMercenary(roster.mercenaries[1], source).id)
		assert.equals(ruktara.id, build.importTab:ImportMercenary(roster.mercenaries[2], source).id)
	end)

	it("accepts empty support arrays and items without optional fields", function()
		local hire = roster.mercenaries[1]
		assert.equals(0, #hire.skills[2].supports)
		hire.items[1].sockets = nil
		hire.items[1].socketedItems = nil
		hire.items[1].properties = nil
		hire.items[1].requirements = nil
		local profile = import(1)
		assert.equals(6, #profile.skills)
		assert.equals(0, #profile.skills[2].supports)
	end)

	it("restores calculated equipment effects when switching hires", function()
		helpers.allocatePermanentHire()
		helpers.allocate("Legendary Helmets")
		helpers.allocate("Legendary Belts")
		helpers.allocate("Legendary Amulets")
		helpers.allocate("Legendary Rings")
		local first = import(1)
		local firstOutput = helpers.calculateBuild().mercenary.output
		local firstLife = firstOutput.Life
		assert.is_true(firstLife > 0)
		local second = import(2)
		local secondEnv = helpers.calculateBuild()
		assert.is_table(secondEnv.mercenary, table.concat(secondEnv.mercenaryCalculationErrors or { }, "; "))
		local secondOutput = secondEnv.mercenary.output
		assert.is_true(secondOutput.Life > 0)
		assert.not_equals(firstLife, secondOutput.Life)
		tab:SetActiveMercenarySet(first.id)
		assert.equals(firstLife, helpers.calculateBuild().mercenary.output.Life)
		tab:SetActiveMercenarySet(second.id)
		assert.equals(secondOutput.Life, helpers.calculateBuild().mercenary.output.Life)
	end)
end)
