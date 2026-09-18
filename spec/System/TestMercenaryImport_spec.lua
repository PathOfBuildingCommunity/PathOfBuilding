describe("Mercenary API import", function()
	local Import = require("Modules.MercenaryImport")
	local Tools = require("Modules.MercenaryTools")
	local helpers = dofile("../spec/System/MercenaryTestHelpers.lua")
	local source = { account = "fixture-account", realm = "pc", league = "Test League" }
	local roster, tab

	local function skillEntry(data, skillId, withSupport)
		local skill = assert(data.skills[skillId], skillId)
		local supports = { }
		if withSupport then
			local supportId = skill.possibleSupportIds[1]
			if supportId then
				local support = data.supports[supportId]
				supports[1] = { id = supportId, hash = support.hash, tier = support.variant }
			end
		end
		return { id = skillId, hash = skill.hash, supports = supports }
	end

	local function abyssJewel(uniqueId)
		return {
			abyssJewel = true,
			name = "Morbid Stare",
			typeLine = "Ghastly Eye Jewel",
			frameType = 2,
			id = uniqueId,
			ilvl = 80,
			socket = 0,
			properties = { { name = "Abyss", values = { }, displayMode = 0 } },
			explicitMods = { { description = "+10 to maximum Life" } },
		}
	end

	local function makeHire(data, name, buildId, uniqueSuffix, skillIds)
		local mercBuild = assert(data.builds[buildId], buildId)
		local skills = { }
		for index, skillId in ipairs(skillIds) do
			skills[index] = skillEntry(data, skillId, index == 1)
		end
		return {
			name = name,
			level = 83,
			build = buildId,
			build_hash = mercBuild.hash,
			skills = skills,
			items = {
				{
					id = "helm-"..uniqueSuffix,
					name = "",
					typeLine = "Leather Cap",
					frameType = 0,
					inventoryId = "Helm",
					sockets = { { group = 0, attr = "A", sColour = "A" } },
					explicitMods = { { description = "Has 1 Abyssal Socket" } },
					socketedItems = { abyssJewel("abyss-helm-"..uniqueSuffix) },
				},
				{
					id = "weapon-"..uniqueSuffix,
					name = "",
					typeLine = "Crude Bow",
					frameType = 0,
					inventoryId = "Weapon",
					sockets = { { group = 0, attr = "G", sColour = "G" } },
					socketedItems = { { typeLine = "Fireball", socket = 0, properties = { } } },
				},
				{
					id = "quiver-"..uniqueSuffix,
					name = "",
					typeLine = "Serrated Arrow Quiver",
					frameType = 0,
					inventoryId = "Offhand",
				},
				{
					id = "belt-"..uniqueSuffix,
					name = "",
					typeLine = "Stygian Vise",
					frameType = 0,
					inventoryId = "Belt",
					sockets = { { group = 0, attr = "A", sColour = "A" } },
					implicitMods = { { description = "Has 1 Abyssal Socket" } },
					socketedItems = { abyssJewel("abyss-belt-"..uniqueSuffix) },
				},
			},
		}
	end

	before_each(function()
		newBuild()
		build.characterLevel = 97
		tab = build.mercenaryTab
		tab:EnsureData()
		roster = {
			mercenaries = {
				makeHire(tab.data, "Ruktara, the Bullseye", "EleBowRangerLightning", "1", { "LightningArrowMercenary", "AssassinsMarkMercenary" }),
				makeHire(tab.data, "Vorneka Azrus", "EleBowRangerClones", "2", { "MirrorArrowMercenary", "BlinkArrowMercenary" }),
			},
			active_mercenary_index = 2,
		}
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

	local function mercSetId()
		return build.itemsTab:GetActorItemSetId("MERCENARY")
	end

	it("converts synthetic hires and resolves optional IDs through hashes", function()
		for _, hire in ipairs(roster.mercenaries) do
			local profile = assert(Import.profile(hire, tab.data))
			assert.same({ }, Tools.validateProfile(profile, tab.data))
			assert.equals(83, profile.foundAreaLevel)
			assert.is_nil(profile.importedWarrant)
			assert.is_true(#profile.skills >= 1)
			for _, skill in ipairs(profile.skills) do
				assert.is_true(skill.enabled)
				assert.is_false(skill.includeInFullDPS)
				assert.equals(1, skill.count)
			end
		end
		local hire = roster.mercenaries[1]
		local expected = assert(Import.profile(hire, tab.data))
		for _, skill in ipairs(hire.skills) do
			skill.id = nil
			skill.name = "Wrong display name"
			for _, support in ipairs(skill.supports) do support.id = nil end
		end
		assert.same(expected, assert(Import.profile(hire, tab.data)))
		hire.skills[2].supports = nil
		assert.equals(0, #assert(Import.profile(hire, tab.data)).skills[2].supports)
		hire.skills[2].supports = "nope"
		assert.is_nil(Import.profile(hire, tab.data))
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

	it("imports equipment through ItemsTab without displacing player or Guardian gear", function()
		local itemsTab = build.itemsTab
		build.importTab:ImportItemsAndSkills({ level = 97, equipment = {{ id = "player", name = "", typeLine = "Iron Hat", frameType = 0, inventoryId = "Helm" }} }, false, false, false)
		local guardianSet = build.importTab:GetOrCreateGuardianItemSet()
		build.importTab:ImportItem({ id = "guardian", name = "", typeLine = "Leather Belt", frameType = 0, inventoryId = "Belt" }, nil, false, guardianSet.id)
		local playerBefore = copyTable(itemsTab.activeItemSet)
		local guardianBefore = copyTable(guardianSet)
		local skillsBefore = copyTable(build.skillsTab.socketGroupList)
		local first = import(1)
		local firstSetId = mercSetId()
		assert.is_not_nil(firstSetId)
		assert.are_not.equal(itemsTab.activeItemSetId, firstSetId)
		assert.equals(firstSetId, first.itemSetId)
		local second = import(2)
		local secondSetId = mercSetId()
		assert.are_not.equal(firstSetId, secondSetId)
		local set = itemsTab.itemSets[secondSetId]
		for _, slot in ipairs({"Helmet Abyssal Socket 1", "Belt Abyssal Socket 1"}) do
			assert.is_true(set[slot].selItemId > 0)
			assert.equals("Abyss", itemsTab.items[set[slot].selItemId].base.subType)
		end
		assert.same(playerBefore, itemsTab.activeItemSet)
		assert.same(guardianBefore, itemsTab.itemSets[guardianSet.id])
		assert.same(skillsBefore, build.skillsTab.socketGroupList)
		assert.equals(97, build.characterLevel)
		tab:SetActiveMercenarySet(first.id)
		assert.equals(firstSetId, mercSetId())
		assert.is_nil(build.configTab.configSets[build.configTab.activeConfigSetId].actors.mercenary.itemSetId)
	end)

	it("reimports without duplication and keeps shared or player-worn items", function()
		local first = import(1)
		local second = import(2)
		local firstBefore = copyTable(first)
		second.title = "My renamed hire"
		second.skills[1].includeInFullDPS = true
		second.skills[1].count = 3
		local again = import(2)
		assert.equals(second.id, again.id)
		assert.equals(roster.mercenaries[2].name, again.title)
		assert.equals(1, again.skills[1].count)
		assert.is_false(again.skills[1].includeInFullDPS)
		local afterSecond = itemCount()
		for index, item in ipairs(roster.mercenaries[2].items) do
			if item.inventoryId == "Helm" then table.remove(roster.mercenaries[2].items, index) break end
		end
		import(2)
		local set = build.itemsTab.itemSets[mercSetId()]
		assert.equals(0, set.Helmet.selItemId)
		assert.equals(0, set["Helmet Abyssal Socket 1"].selItemId)
		assert.is_true(itemCount() < afterSecond)
		assert.same(firstBefore, tab.mercenarySets[first.id])

		local helmetId = build.itemsTab.itemSets[first.itemSetId].Helmet.selItemId
		local spare = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, spare.id)
		spare.Helmet.selItemId = helmetId
		import(1)
		assert.equals(helmetId, spare.Helmet.selItemId)
		assert.is_not_nil(build.itemsTab.items[helmetId])

		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		local gem = build.skillsTab.socketGroupList[1].gemList[1]
		gem.skillMinionItemSet = first.itemSetId
		assert.equals(first.itemSetId, import(1).itemSetId)
		assert.equals(first.itemSetId, gem.skillMinionItemSet)

		local before = build:SaveDB("code")
		roster.mercenaries[2].items[1].typeLine = "Unsupported item base"
		assert.is_nil(build.importTab:ImportMercenary(roster.mercenaries[2], source))
		assert.equals(before, build:SaveDB("code"))

		local hire = copyTable(roster.mercenaries[1])
		local helmData
		for _, itemData in ipairs(hire.items) do
			if itemData.inventoryId == "Helm" then helmData = itemData break end
		end
		newBuild()
		tab = build.mercenaryTab
		tab:EnsureData()
		build.importTab:ImportItemsAndSkills({
			level = 97,
			equipment = {{ id = helmData.id, name = "", typeLine = "Iron Hat", frameType = 0, inventoryId = "Helm" }},
		}, false, false, false)
		local imported, message = build.importTab:ImportMercenary(hire, source)
		assert.is_nil(imported)
		assert.matches("still equipped by the player", message)
	end)

	it("maps equipment by inventoryId and applies socket occupancy without player gems", function()
		local hire = roster.mercenaries[1]
		local reversed = { }
		for index = #hire.items, 1, -1 do table.insert(reversed, hire.items[index]) end
		hire.items = reversed
		local profile = import(1)
		assert.equals(0, #build.skillsTab.socketGroupList)
		local weapon = build.itemsTab.items[build.itemsTab.itemSets[mercSetId()]["Weapon 1"].selItemId]
		assert.equals("Crude Bow", weapon.baseName)
		assert.equals("Fireball", weapon.socketedGems[1].nameSpec)
		assert.equals(0, #build.skillsTab.socketGroupList)
		assert.equals(2, #profile.skills)

		newBuild()
		build.characterLevel = 97
		tab = build.mercenaryTab
		tab:EnsureData()
		helpers.allocatePermanentHire()
		helpers.allocate("Legendary Rings")
		tab.profile.classId = "ElementalWitch"
		tab.profile.buildId = "ElementalWitchLightning"
		tab.profile.foundAreaLevel = 83
		tab.profile.mainSkillId = "ArcMercenary"
		tab.profile.skills = { { id = "ArcMercenary", enabled = true, supports = { } } }
		tab:Changed()
		local set = tab:GetItemSet(true)
		local function importRing(socketedItems)
			build.importTab:ImportItem({
				id = "malachai-socket-test", frameType = 3, name = "Malachai's Artifice", typeLine = "Unset Ring",
				sockets = { { group = 0, sColour = "W" } }, socketedItems = socketedItems,
				implicitMods = { "Has 1 Socket" },
				explicitMods = { "-20% to all Elemental Resistances", "+100% to Fire Resistance when Socketed with a Red Gem", "All Sockets are White" },
			}, "Ring 1", false, set.id, { actor = "MERCENARY" })
		end
		importRing({ })
		local env = helpers.calculateBuild()
		assert.is_table(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		local before = env.mercenary.output.FireResistTotal
		importRing({ { typeLine = "Heavy Strike", socket = 0, support = false, properties = { } } })
		env = helpers.calculateBuild()
		assert.equals(before + 100, env.mercenary.output.FireResistTotal)
	end)

	it("forks a new item set only for the player's active destination and unused default loadout", function()
		assert.equals(1, Import.unusedEmptyId(tab.mercenarySets, tab.mercenarySetOrderList))
		local original = import(1)
		assert.equals(1, original.id)
		assert.is_nil(Import.unusedEmptyId(tab.mercenarySets, tab.mercenarySetOrderList))
		local destId = mercSetId()
		assert(build.itemsTab:SetActiveItemSet(destId))
		for _, slot in pairs(build.itemsTab.activeItemSet) do
			if type(slot) == "table" and slot.selItemId then slot.selItemId = 0 end
		end
		local playerSet = copyTable(build.itemsTab.activeItemSet)
		import(1)
		assert.not_equals(destId, mercSetId())
		assert.same(playerSet, build.itemsTab.activeItemSet)
		local duplicate = import(1, 0)
		assert.not_equals(original.id, duplicate.id)
		assert.is_nil(build.importTab:ImportMercenary(roster.mercenaries[1], source))
		assert.equals(original.id, import(1, original.id).id)
		local empty = tab:NewMercenarySet(nil, "Empty")
		table.insert(tab.mercenarySetOrderList, empty.id)
		assert.is_nil(empty.itemSetId)
	end)

	it("persists associations through XML without the account UUID", function()
		roster.mercenaries[1].level = 40
		local uuid = "550e8400-e29b-41d4-a716-446655440000"
		local profile, err = build.importTab:ImportMercenary(roster.mercenaries[1], {
			account = uuid,
			realm = source.realm,
			league = source.league,
		})
		assert.is_table(profile, err)
		assert.equals(40, profile.foundAreaLevel)
		assert.matches("^%x+$", profile.importAssociation)
		assert.equals(64, #profile.importAssociation)
		assert.is_nil(profile.importAssociation:find(uuid, 1, true))
		local xml = { }
		tab:Save(xml)
		tab:Load(xml)
		assert.equals(40, tab.profile.foundAreaLevel)
		assert.equals(profile.importAssociation, tab.profile.importAssociation)
		assert.is_nil(build:SaveDB("code"):find(uuid, 1, true))
	end)

	it("keeps Mercenary and Items undo isolated after import", function()
		local first = import(1)
		local firstSetId = mercSetId()
		local original = copyTable(tab.profile.skills[1].supports)
		import(2)
		tab:Undo()
		assert.equals(first.buildId, tab.profile.buildId)
		assert.equals(firstSetId, mercSetId())
		table.remove(roster.mercenaries[1].skills[1].supports)
		import(1, first.id)
		assert.are.equal(#original - 1, #tab.profile.skills[1].supports)
		build.itemsTab:Undo()
		assert.are.equal(#original - 1, #tab.profile.skills[1].supports)
		tab:Undo()
		assert.same(original, tab.profile.skills[1].supports)
	end)

	it("walks the popup from a valid active index and ignores an empty roster", function()
		for _, index in ipairs({1, 2}) do
			roster.active_mercenary_index = index
			assert.equals(index, Import.activeIndex(roster))
		end
		for _, index in ipairs({0, -1, 3, 1.5, "2", false}) do
			roster.active_mercenary_index = index
			assert.is_nil(Import.activeIndex(roster))
		end
		roster.active_mercenary_index = 2
		build.importTab:OpenMercenaryImportPopup(roster, source)
		local popup = main.popups[1]
		assert.equals(2, popup.controls.hire.selIndex)
		assert.matches("Vorneka", popup.controls.hire:GetSelValue().label)
		assert.matches("%(Active%)", popup.controls.hire:GetSelValue().label)
		popup.controls.import.onClick()
		assert.equals("EleBowRangerClones", tab.profile.buildId)
		main:ClosePopup()
		roster.active_mercenary_index = 0
		build.importTab:OpenMercenaryImportPopup(roster, source)
		assert.equals(1, main.popups[1].controls.hire.selIndex)
		assert.is_nil((main.popups[1].controls.hire:GetSelValue().label):match("%(Active%)"))
		main:ClosePopup()
		build.importTab:OpenMercenaryImportPopup({ mercenaries = { } }, source)
		assert.is_nil(main.popups[1])
	end)

	it("matches reimports by association fingerprint, not roster order or copied loadouts", function()
		local hireA = { name = "Same Name", build_hash = 1, skills = { { hash = 10, supports = { { hash = 1, tier = 1 } } } } }
		local hireB = { name = "Same Name", build_hash = 1, skills = { { hash = 20, supports = { { hash = 1, tier = 1 } } } } }
		assert.not_equals(Import.association(source.account, source.realm, source.league, hireA), Import.association(source.account, source.realm, source.league, hireB))
		local ruktara = import(1)
		local vorneka = import(2)
		roster.mercenaries[1], roster.mercenaries[2] = roster.mercenaries[2], roster.mercenaries[1]
		assert.equals(vorneka.id, build.importTab:ImportMercenary(roster.mercenaries[1], source).id)
		assert.equals(ruktara.id, build.importTab:ImportMercenary(roster.mercenaries[2], source).id)
		roster.mercenaries[1], roster.mercenaries[2] = roster.mercenaries[2], roster.mercenaries[1]
		tab:OpenMercenarySetManagePopup()
		local list = main.popups[1].controls[1]
		list.selValue = ruktara.id
		list.selIndex = 1
		list.controls.copy.onClick()
		main.popups[1].controls.edit.buf = "Copied hire"
		main.popups[1].controls.save.onClick()
		local copyId
		for _, id in ipairs(tab.mercenarySetOrderList) do
			if id ~= ruktara.id and id ~= vorneka.id then copyId = id end
		end
		assert.equals("Copied hire", tab.mercenarySets[copyId].title)
		assert.is_nil(tab.mercenarySets[copyId].importAssociation)
		assert.equals(ruktara.id, import(1).id)
		main:ClosePopup()
	end)
end)
