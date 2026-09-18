describe("Mercenary equipment validation", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local selectScionLuminary = MercenaryTest.selectScionLuminary
	local MercenaryTools = require("Modules.MercenaryTools")
	local tab, itemSet, mercenaryItemSet

	local function item(fields)
		local value = {
			id = 9001,
			type = "Body Armour",
			rarity = "RARE",
			requirements = { level = 0, str = 0, dex = 0, int = 0 },
			grantedSkills = { },
		}
		for key, fieldValue in pairs(fields or { }) do value[key] = fieldValue end
		return value
	end

	local function selectBuild(buildId, foundAreaLevel)
		tab.profile.buildId = buildId
		tab.profile.foundAreaLevel = foundAreaLevel or 68
		tab:Changed()
		mercenaryItemSet = tab:GetItemSet(true)
	end

	local function showMercenaryEquipment()
		mercenaryItemSet = tab:GetItemSet(true)
		build.itemsTab:SetViewItemSet(mercenaryItemSet.id)
		return mercenaryItemSet
	end

	local function validateEquippedItem(equippedItem, slotName, mercenarySet)
		return MercenaryTools.validateEquippedItem(equippedItem, slotName, {
			profile = tab.profile,
			mercenaryData = tab.data,
			itemSet = mercenarySet or mercenaryItemSet,
			playerItemSet = itemSet,
			items = build.itemsTab.items,
			playerHasFlag = function(flagName) return tab:PlayerFlag(flagName) end,
		})
	end

	local function allocatePassive(name)
		local node = build.spec.tree.ascendancyMap[name]
		if not node then
			for _, candidate in pairs(build.spec.nodes) do
				if candidate.name == name then node = candidate break end
			end
		end
		node = assert(node, name)
		node = build.spec.nodes[node.id] or node
		node.alloc = true
		build.spec.allocNodes[node.id] = node
		build.spec.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
	end

	local function freshBuild()
		newBuild()
		selectScionLuminary()
		tab = build.mercenaryTab
		itemSet = build.itemsTab.activeItemSet
		mercenaryItemSet = nil
		tab:EnsureData()
	end

	local function stubThrowingCalculator()
		local originalGet = build.calcsTab.GetMiscCalculator
		build.calcsTab.mainEnv = build.calcsTab.mainEnv or { }
		build.calcsTab.GetMiscCalculator = function()
			return function() error("calc boom") end, nil, { MERCENARY = { CombinedDPS = 1 } }
		end
		return originalGet
	end

	local function tooltipUnavailableText(tooltip)
		local tooltipText = { }
		for _, line in ipairs(tooltip.lines) do
			if line.text then
				table.insert(tooltipText, line.text)
			end
		end
		return table.concat(tooltipText, "\n")
	end

	before_each(freshBuild)

	it("populates Class and build on first Mercenary tab view without a saved class", function()
		newBuild()
		selectScionLuminary()
		tab = build.mercenaryTab
		assert.is_nil(tab.profile.classId)
		assert.is_nil(tab.profile.buildId)
		assert.are.equal(0, #tab.controls.build.list)

		tab:EnsureData()
		tab:RefreshControls()

		local classGroup = tab.classGroups[tab.controls.class.selIndex]
		assert.is_not_nil(classGroup)
		assert.is_true(#tab.controls.build.list > 0)
		assert.are.equal(#classGroup.buildIds, #tab.controls.build.list)
		assert.are.equal(classGroup.buildIds[1], tab.controls.build.list[1].id)
		assert.is_nil(tab.profile.classId)
		assert.is_nil(tab.profile.buildId)
	end)



	it("persists Mercenary equipment in a generic ItemsTab set and actor assignment", function()
		local mercSet = tab:GetItemSet(true)
		assert.are.equal(mercSet, tab:GetItemSet(true))

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		mercSet = showMercenaryEquipment()
		build.itemsTab.items[9001] = item({ id = 9001, name = "Mercenary Helmet", type = "Helmet", base = { type = "Helmet" } })
		mercSet["Helmet"].selItemId = 9001
		local itemsXml = { }
		build.itemsTab:Save(itemsXml)
		local savedItemId
		local savedOwner
		local savedActor
		for _, node in ipairs(itemsXml) do
			if node.elem == "ItemSet" and tonumber(node.attrib.id) == mercSet.id then
				savedOwner = node.attrib.owner
				for _, slot in ipairs(node) do
					if slot.attrib and slot.attrib.name == "Helmet" then savedItemId = slot.attrib.itemId end
				end
			elseif node.elem == "ActorItemSet" and node.attrib.actor == "MERCENARY" then
				savedActor = tonumber(node.attrib.itemSetId)
			end
		end
		assert.are.equal("9001", savedItemId)
		assert.is_nil(savedOwner)
		assert.are.equal(mercSet.id, savedActor)
		assert.is_nil(itemsXml.attrib.viewItemSet)
		local mercenaryXml = { }
		tab:Save(mercenaryXml)
		assert.is_nil(mercenaryXml.attrib.itemSetId)
		assert.is_nil(mercenaryXml.attrib.auxiliaryItemSetId)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		local itemsTab = build.itemsTab
		local activePlayerSetId = itemsTab.activeItemSetId
		tab:GetItemSet(true)
		local secondSet = itemsTab:NewItemSet()
		secondSet.title = "Alternate Mercenary Equipment"
		table.insert(itemsTab.itemSetOrderList, secondSet.id)
		assert(itemsTab:SetActorItemSet("MERCENARY", secondSet.id))
		assert.are.equal(secondSet.id, itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(secondSet.id, itemsTab.viewItemSetId)
		assert.are.equal(activePlayerSetId, itemsTab.activeItemSetId)

		local saved = { }
		tab:Save(saved)
		assert.is_nil(saved.attrib.itemSetId)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		itemsTab = build.itemsTab
		local validSet = tab:GetItemSet(false)
		assert.is_table(validSet)
		assert.is_false(itemsTab:SetActorItemSet("MERCENARY", 99999, false))
		assert.are.equal(validSet, tab:GetItemSet(false))
		assert.is_true(itemsTab:SetActorItemSet("MERCENARY", nil, false))
		assert.is_table(tab:GetItemSet(false))
		local created = tab:GetItemSet(true)
		assert.is_table(created)
		assert.are_not.equal(99999, created.id)

		freshBuild()
		local playerSet = build.itemsTab:NewItemSet()
		playerSet.title = "Animate Guardian"
		table.insert(build.itemsTab.itemSetOrderList, playerSet.id)
		itemsXml = { }
		build.itemsTab:Save(itemsXml)
		build.itemsTab:Load(itemsXml)
		assert.are.equal("Animate Guardian", build.itemsTab.itemSets[playerSet.id].title)
		assert.is_nil(build.itemsTab.itemSets[playerSet.id].owner)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		itemsTab = build.itemsTab
		mercSet = showMercenaryEquipment()
		local playerHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		local mercHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(playerHelmet, true)
		itemsTab:AddItem(mercHelmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		mercSet["Helmet"].selItemId = mercHelmet.id
		activePlayerSetId = itemsTab.activeItemSetId
		itemsXml, mercenaryXml = { }, { }
		itemsTab:Save(itemsXml)
		tab:Save(mercenaryXml)
		itemsTab:Load(itemsXml)
		tab:Load(mercenaryXml)
		tab:PostLoad()
		assert.are.equal(activePlayerSetId, itemsTab.activeItemSetId)
		assert.are.equal(activePlayerSetId, itemsTab.viewItemSetId)
		assert.are.equal(playerHelmet.id, itemsTab.itemSets[activePlayerSetId].Helmet.selItemId)
		assert.are.equal(mercHelmet.id, tab:GetItemSet(true)["Helmet"].selItemId)

		freshBuild()
		itemsTab = build.itemsTab
		itemsTab:Load({
			attrib = { activeItemSet = "1", useSecondWeaponSet = "false" },
			{
				elem = "ItemSet",
				attrib = { id = "1", owner = "Player", title = "Branch Owner", useSecondWeaponSet = "false" },
			},
		})
		assert.are.equal("Branch Owner", itemsTab.itemSets[1].title)
		assert.is_nil(itemsTab.itemSets[1].owner)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		mercSet = showMercenaryEquipment()
		build.itemsTab.items[9001] = item({ id = 9001, name = "Mercenary Helmet", type = "Helmet", base = { type = "Helmet" } })
		mercSet["Helmet"].selItemId = 9001
		tab:Reset()
		assert.are.equal(mercSet.id, build.itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(mercSet, build.itemsTab.itemSets[mercSet.id])
		assert.are.equal(9001, mercSet["Helmet"].selItemId)
	end)


	it("isolates Items undo from Mercenary profile edits", function()
		selectBuild("MeleeAOEMarauderFireSlam")
		local itemsTab = build.itemsTab
		itemsTab:ResetUndo()
		tab:ResetUndo()
		local hat = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(hat, true)
		itemsTab:AddUndoState()
		tab.profile.title = "New Mercenary name"
		tab.profile.foundAreaLevel = 80
		tab:Changed()
		itemsTab:Undo()
		assert.are.equal("New Mercenary name", tab.profile.title)
		assert.are.equal(80, tab.profile.foundAreaLevel)
		itemsTab:Redo()
		assert.are.equal("New Mercenary name", tab.profile.title)
		assert.is_truthy(itemsTab.items[hat.id])
		local cap = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(cap, true)
		itemsTab:AddUndoState()
		itemsTab:Undo()
		assert.are.equal(80, tab.profile.foundAreaLevel)
		tab:Undo()
		assert.are.equal(68, tab.profile.foundAreaLevel)
		assert.is_nil(itemsTab.items[cap.id])
		assert.is_truthy(itemsTab.items[hat.id])
	end)

	it("validates Mercenary equipment against class, level, and slot rules", function()
		local armourCases = {
			{ "MeleeAOEMarauderFireSlam", {
				{ { str = 100, dex = 100 }, true },
				{ { dex = 100 }, false },
				{ { str = 1, dex = 1, int = 1 }, false },
			} },
			{ "AurasMinionsTemplarStaff", {
				{ { str = 100, int = 100 }, true },
				{ { str = 100, dex = 1 }, false },
			} },
			{ "MiscScionPhysDot", {
				{ { str = 1, dex = 1, int = 1 }, true },
			} },
		}
		for _, group in ipairs(armourCases) do
			selectBuild(group[1])
			for _, case in ipairs(group[2]) do
				assert.are.equal(case[2], validateEquippedItem(item({ requirements = case[1] }), "Body Armour"))
			end
		end

		selectBuild("MeleeAOEMarauderFireSlam", 47)
		assert.is_false(validateEquippedItem(item({ requirements = { level = 68, str = 1 } }), "Body Armour"))
		tab.profile.foundAreaLevel = 48
		assert.is_true(validateEquippedItem(item({ requirements = { level = 68, str = 1 } }), "Body Armour"))

		selectBuild("MeleeAOEMarauderFireSlam")
		assert.is_false(validateEquippedItem(item({ rarity = "UNIQUE" }), "Body Armour"))
		local helmet = item({ type = "Helmet", rarity = "UNIQUE", requirements = { str = 1 } })
		assert.is_false(validateEquippedItem(helmet, "Helmet"))
		allocatePassive("Legendary Helmets")
		assert.is_true(validateEquippedItem(helmet, "Helmet"))

		freshBuild()
		selectBuild("MeleeStrikesMarauderFire")
		local legendaryCases = {
			{ "Helmet", "Helmet", "Legendary Helmets", { str = 1 } },
			{ "Gloves", "Gloves", "Legendary Gloves", { str = 1 } },
			{ "Boots", "Boots", "Legendary Boots", { str = 1 } },
			{ "Amulet", "Amulet", "Legendary Amulets" },
			{ "Ring 1", "Ring", "Legendary Rings" },
			{ "Ring 2", "Ring", "Legendary Rings" },
			{ "Belt", "Belt", "Legendary Belts" },
			{ "Weapon 1", "One Handed Sword", "Legendary Arms" },
			{ "Weapon 2", "One Handed Sword", "Legendary Arms" },
		}
		local allocated = { }
		for index, case in ipairs(legendaryCases) do
			local unique = item({ id = 9100 + index, type = case[2], rarity = "UNIQUE", requirements = case[4] or { } })
			if not allocated[case[3]] then
				assert.is_false(validateEquippedItem(unique, case[1]))
				allocatePassive(case[3])
				allocated[case[3]] = true
			end
			assert.is_true(validateEquippedItem(unique, case[1]))
		end

		freshBuild()
		selectBuild("TrapsMinesShadowLightning")
		assert.is_true(validateEquippedItem(item({ type = "Dagger" }), "Weapon 1"))
		assert.is_false(validateEquippedItem(item({ type = "Shield" }), "Weapon 2"))

		selectBuild("MeleeStrikesMarauderFire")
		assert.is_true(validateEquippedItem(item({ type = "Shield", requirements = { str = 1 } }), "Weapon 2"))
		assert.is_true(validateEquippedItem(item({ type = "One Handed Sword" }), "Weapon 2"))

		selectBuild("AurasMinionsTemplarSmite")
		assert.is_true(validateEquippedItem(item({ type = "Shield" }), "Weapon 2"))
		assert.is_false(validateEquippedItem(item({ type = "Sceptre" }), "Weapon 2"))

		selectBuild("NonEleBowRangerPhys")
		assert.is_true(validateEquippedItem(item({ type = "Bow" }), "Weapon 1"))
		assert.is_true(validateEquippedItem(item({ type = "Quiver" }), "Weapon 2"))

		selectBuild("MeleeStrikesMarauderFire")
		assert.is_true(validateEquippedItem(item({ type = "Shield", requirements = { str = 100 } }), "Weapon 2"))
		assert.is_true(validateEquippedItem(item({ type = "Shield", requirements = { str = 100, dex = 50 } }), "Weapon 2"))
		assert.is_false(validateEquippedItem(item({ type = "Shield", requirements = { dex = 100 } }), "Weapon 2"))
		assert.is_false(validateEquippedItem(item({ type = "Shield", requirements = { int = 15 } }), "Weapon 2"))
		assert.is_false(validateEquippedItem(item({ type = "Shield", requirements = { str = 1, dex = 1, int = 1 } }), "Weapon 2"))

		selectBuild("AurasMinionsTemplarSmite")
		assert.is_true(validateEquippedItem(item({ type = "Shield", requirements = { str = 100, int = 100 } }), "Weapon 2"))
		assert.is_false(validateEquippedItem(item({ type = "Shield", requirements = { dex = 1 } }), "Weapon 2"))
		assert.is_false(validateEquippedItem(item({ type = "Shield", requirements = { str = 100, dex = 1 } }), "Weapon 2"))

		selectBuild("MeleeAOEMarauderFireSlam")
		local shared = item({ type = "Helmet", requirements = { str = 1 } })
		itemSet["Helmet"].selItemId = shared.id
		assert.is_false(validateEquippedItem(shared, "Helmet"))

		local playerCopy = item({ id = 9100, type = "Helmet", requirements = { str = 1 }, uniqueID = "api-item-x", base = { type = "Helmet" } })
		local mercCopy = item({ id = 9101, type = "Helmet", requirements = { str = 1 }, uniqueID = "api-item-x", base = { type = "Helmet" } })
		build.itemsTab.items[playerCopy.id] = playerCopy
		itemSet["Helmet"].selItemId = playerCopy.id
		assert.is_false(validateEquippedItem(mercCopy, "Helmet"))
		build.itemsTab.items[playerCopy.id] = nil
		itemSet["Helmet"].selItemId = shared.id

		local grantedAura = item({ type = "Helmet", id = 9002, requirements = { str = 1 }, grantedSkills = { { skillId = "Anger" } } })
		assert.is_true(validateEquippedItem(grantedAura, "Helmet"))

		local mercSet = showMercenaryEquipment()
		local invalidHelmet = item({ id = 9015, name = "Invalid Mercenary Helmet", type = "Helmet", base = { type = "Helmet" }, requirements = { int = 1 } })
		build.itemsTab.items[invalidHelmet.id] = invalidHelmet
		build.itemsTab.slots["Helmet"]:SetSelItemId(invalidHelmet.id, build.itemsTab:GetVisibleItemSet())
		build.itemsTab:PopulateSlots()
		assert.are.equal(invalidHelmet.id, mercSet["Helmet"].selItemId)
		assert.matches("Helmet: armour attribute alignment", table.concat(tab:GetErrors(), "\n"))

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		showMercenaryEquipment()
		invalidHelmet = item({ id = 9018, name = "Selectable Invalid Helmet", type = "Helmet", base = { type = "Helmet" }, requirements = { int = 1 } })
		build.itemsTab.items[invalidHelmet.id] = invalidHelmet
		build.itemsTab:PopulateSlots()
		local helmetSlot = build.itemsTab.slots["Helmet"]
		local candidateIndex
		for index, itemId in ipairs(helmetSlot.items) do
			if itemId == invalidHelmet.id then candidateIndex = index break end
		end
		assert.is_number(candidateIndex)
		assert.matches(colorCodes[invalidHelmet.rarity], helmetSlot.list[candidateIndex], nil, true)
		helmetSlot:SetSelItemId(invalidHelmet.id, build.itemsTab:GetVisibleItemSet())
		build.itemsTab:PopulateSlots()
		assert.are.equal(invalidHelmet.id, helmetSlot.selItemId)
		assert.matches("Helmet: armour attribute alignment", table.concat(tab:GetErrors(), "\n"))

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		mercSet = showMercenaryEquipment()
		local jewel = item({ id = 9016, name = "Mercenary Abyss Jewel", type = "Jewel", base = { type = "Jewel", subType = "Abyss" }, requirements = { level = 1 } })
		assert.is_false(validateEquippedItem(jewel, "Helmet Abyssal Socket 1"))
		helmet = item({ id = 9017, name = "Mercenary Abyss Helmet", type = "Helmet", base = { type = "Helmet" }, requirements = { str = 1 }, abyssalSocketCount = 1 })
		build.itemsTab.items[helmet.id] = helmet
		mercSet["Helmet"].selItemId = helmet.id
		assert.is_true(validateEquippedItem(jewel, "Helmet Abyssal Socket 1", mercSet))
		assert.is_false(tab:IsSlotSupported("Jewel 12345"))

		local uniqueJewel = item({ id = 9024, name = "Mercenary Unique Abyss Jewel", type = "Jewel", base = { type = "Jewel", subType = "Abyss" }, rarity = "UNIQUE", requirements = { level = 1 } })
		build.itemsTab.items[uniqueJewel.id] = uniqueJewel
		local abyssParents = {
			{ type = "Body Armour", slotName = "Body Armour" },
			{ type = "Helmet", slotName = "Helmet" },
		}
		for index, case in ipairs(abyssParents) do
			local parent = item({ id = 9024 + index, name = "Mercenary Abyss "..case.type, type = case.type, base = { type = case.type }, requirements = { str = 1 }, abyssalSocketCount = 1 })
			build.itemsTab.items[parent.id] = parent
			mercSet[case.slotName].selItemId = parent.id
			assert.is_true(validateEquippedItem(uniqueJewel, case.slotName.." Abyssal Socket 1", mercSet))
		end
	end)

	it("imports Warrant text into the active loadout without replacing gear", function()
		selectBuild("MeleeAOEMarauderFireSlam")
		local mercSet = showMercenaryEquipment()
		local mercenaryHelmet = "Helmet"
		mercSet[mercenaryHelmet].selItemId = 9001
		local warrantText = [[
Item Class: Map Fragments
Rarity: Normal
Mercenary Warrant
--------
Thalia, the Exquisite
--------
Build: Kineticist
Mercenary Level: 83
--------
Elemental Weakness
Greater Curse Effect (Tier: 3)
Faster Casting (Tier: 2)
--------
Right click this item to view Mercenary details.
--------
Note: ~b/o 1 mirror
]]
		tab.controls.importWarrant:Click()
		local popup = main.popups[1]
		assert.are.equal("Import Mercenary Warrant", popup.title)
		popup.controls.edit:SetText(warrantText)
		popup.controls.import:Click()
		assert.are_not.equal(popup, main.popups[1])
		assert.are.equal("Kineticist", tab.data.builds[tab.profile.buildId].name)
		assert.are.equal(83, tab.profile.foundAreaLevel)
		assert.are.equal("Elemental Weakness", tab.data.skills[tab.profile.mainSkillId].name)
		assert.is_true(tab.profile.importedWarrant)
		assert.are.equal(9001, mercSet[mercenaryHelmet].selItemId)
		local xml = { }
		tab:Save(xml)
		assert.are.equal("true", xml[1].attrib.importedWarrant)
		tab:Reset()
		tab:Load(xml)
		assert.is_true(tab.profile.importedWarrant)
		assert.are.equal("Kineticist", tab.data.builds[tab.profile.buildId].name)
	end)


	it("skill and support UI enforces capacity, selection, tooltips, and sort", function()
		assert.matches("simultaneously sustainable", tab.controls.skillFullDPS.tooltipText)
		assert.matches("does not simulate", tab.controls.skillFullDPS.tooltipText)

		local function mercenaryActiveSkill(possibleSupportIds)
			local player = { }
			return {
				activeEffect = { grantedEffect = { modSource = "Skill:Test" } },
				actor = { isMercenary = true, enemy = { player = player } },
				skillTypes = { },
				mercenaryPossibleSupportIds = possibleSupportIds,
			}
		end
		local listedSkill = mercenaryActiveSkill({ "FistOfWarHigh" })
		assert.is_true(calcLib.canGrantedEffectSupportActiveSkill({
			mercenarySupportId = "FistOfWarHigh",
			isTrigger = true,
			excludeSkillTypes = { },
			requireSkillTypes = { },
		}, listedSkill))
		assert.is_false(calcLib.canGrantedEffectSupportActiveSkill({
			mercenarySupportId = "FistOfWarHigh",
		}, mercenaryActiveSkill({ "ArrowNovaHigh" })))
		assert.is_false(calcLib.canGrantedEffectSupportActiveSkill({
			isTrigger = true,
			excludeSkillTypes = { },
			requireSkillTypes = { },
		}, listedSkill))

		tab.profile.skills[1] = { id = "InfernalBlowMercenary", enabled = true, supports = { } }
		tab.controls.skillCount.changeFunc("200")
		assert.are.equal(99, tab.profile.skills[1].count)
		tab.controls.skillCount.changeFunc("0")
		assert.are.equal(1, tab.profile.skills[1].count)

		local skillOptions = require("Modules.SkillOptions")
		assert.are.same(skillOptions.sortGemTypeList, tab.controls.sortGemsByDPSFieldControl.list)
		local xml = { }
		tab.sortGemsByDPS = false
		tab.sortGemsByDPSField = "TotalDPS"
		tab:Save(xml)
		assert.are.equal("false", xml.attrib.sortGemsByDPS)
		assert.are.equal("TotalDPS", xml.attrib.sortGemsByDPSField)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		tab:SetSkill(1, "ConsecratedPathMercenary")
		local expectedSkillColor = data.skillColorMap[build.data.skills.ConsecratedPathMercenary.color]
		local skillRow = tab.controls.skillList:GetRowValue(1, 1, tab.profile.skills[1])
		assert.are.equal(expectedSkillColor, skillRow:sub(1, #expectedSkillColor))
		assert.are.equal(14, tab.controls.skillTip.height)
		assert.is_nil(skillRow:find("(Calcs)", 1, true))
		local skillOption
		for _, option in ipairs(tab.controls.skill.list) do
			if option.id == "ConsecratedPathMercenary" then skillOption = option break end
		end
		assert(skillOption)
		assert.are.equal(expectedSkillColor, skillOption.label:sub(1, #expectedSkillColor))
		local tooltip = new("Tooltip"):Tooltip()
		local function tooltipText()
			local lines = { }
			for _, line in ipairs(tooltip.lines) do if line.text then table.insert(lines, line.text) end end
			return table.concat(lines, "\n")
		end

		tab.controls.skillList:AddValueTooltip(tooltip, 1, tab.profile.skills[1])
		local skillTooltipText = tooltipText()
		assert.matches("Consecrated Path", skillTooltipText)
		assert.matches("Level:", skillTooltipText)
		assert.matches("Slams the ground", skillTooltipText)

		tooltip:Clear(true)
		tab.controls.skill.tooltipFunc(tooltip, "HOVER", 1, { id = "ConsecratedPathMercenary" })
		assert.matches("Consecrated Path", tooltipText())

		tooltip:Clear(true)
		local support = assert(tab.supportControls[1].list[2])
		tab.supportControls[1].tooltipFunc(tooltip, "HOVER", 2, support)
		local supportTooltipText = tooltipText()
		assert.is_true(supportTooltipText:find(tab.data.supports[support.id].name, 1, true) ~= nil)
		assert.is_true(supportTooltipText:find("Mercenary Support, Tier ", 1, true) ~= nil)
		assert.matches("Supported Skills gain", supportTooltipText)

		freshBuild()
		selectBuild("TrapsMinesShadowLightning", 80)
		build.configTab.enemyLevel = 60
		tab:SetSkill(1, "LightningTrapMercenary")
		tooltip = new("Tooltip"):Tooltip()
		tab.controls.skillList:AddValueTooltip(tooltip, 1, tab.profile.skills[1])
		local displayedLevel
		for _, line in ipairs(tooltip.lines) do
			displayedLevel = displayedLevel or line.text and line.text:match("Level: %^7(%d+)")
		end
		local actorLevel = MercenaryTools.effectiveLevel(80, 60)
		assert.are.equal(MercenaryTools.skillLevel(build.data.skills.LightningTrapMercenary, actorLevel), tonumber(displayedLevel))

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		tab:SetSkill(1, "ConsecratedPathMercenary")
		local selected = tab.profile.skills[1]
		local preferredId = tab.supportControls[1].list[2].id
		local originalCalculator = build.calcsTab.GetMiscCalculator
		local ok, err = pcall(function()
			build.calcsTab.GetMiscCalculator = function()
				return function()
					local supportId = selected.supports[1] and selected.supports[1].id
					local dps = supportId == preferredId and 100 or 10
					return { CombinedDPS = dps, FullDPS = dps }
				end
			end
			tab.sortGemsByDPS = true
			tab.sortGemsByDPSField = "CombinedDPS"
			tab:QueueSupportSort(1)
			while tab.supportSortCoroutine do tab:ProcessSupportSort() end
			assert.are.equal(preferredId, tab.supportControls[1].list[1].id)
			assert.is_nil(selected.supports[1])
		end)
		build.calcsTab.GetMiscCalculator = originalCalculator
		assert.is_true(ok, err)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		assert(tab:SetSkill(1, "ConsecratedPathMercenary"))
		local supportId = assert(tab.data.skills.ConsecratedPathMercenary.possibleSupportIds[1])
		assert(tab:SetSupport(5, supportId))
		assert.are.equal(1, #tab.profile.skills[1].supports)
		assert.are.equal(supportId, tab.profile.skills[1].supports[1].id)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		tab:RefreshControls()
		tab.controls.skillList.controls.new.onClick()
		assert.are.equal(1, #tab.profile.skills)
		local skillEntry
		for _, candidate in ipairs(tab.controls.skill.list) do
			if candidate.id and #(tab.data.skills[candidate.id].possibleSupportIds or { }) > 0 then skillEntry = candidate break end
		end
		assert(skillEntry)
		tab.controls.skill.selFunc(2, skillEntry)
		assert.are.equal(skillEntry.id, tab.profile.skills[1].id)
		local supportEntry = assert(tab.supportControls[1].list[2])
		tab.supportControls[1].selFunc(2, supportEntry)
		assert.are.equal(supportEntry.id, tab.profile.skills[1].supports[1].id)
		tab.supportControls[1].selFunc(1, tab.supportControls[1].list[1])
		assert.are.equal(0, #tab.profile.skills[1].supports)

		freshBuild()
		selectBuild("EleBowRangerClones")
		assert(tab:SetSkill(1, "IceShotMercenary"))
		assert.is_true(#tab.supportControls[1].list > 1)
		for index = 1, 5 do
			assert.are.equal(tab.supportControls[index], tab.controls["support"..index])
			assert.is_true(tab.supportControls[index]:IsShown())
		end
		assert.is_nil(tab.controls.skillLink)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		assert(tab:SetSkill(1, "ConsecratedPathMercenary"))
		assert.is_true(tab.supportControls[3].shown)
		assert.is_true(not tab.supportControls[4].shown)
		supportId = tab.data.skills.ConsecratedPathMercenary.possibleSupportIds[1]
		support = tab.data.supports[supportId]
		for index = 1, 4 do tab.profile.skills[1].supports[index] = { id = supportId, tier = support.variant } end
		tab:RefreshControls()
		assert.are.equal(4, #tab.profile.skills[1].supports)
		assert.matches("has more than 3 supports", table.concat(tab:GetErrors(), "\n"))
		local otherId = tab.data.skills.ConsecratedPathMercenary.possibleSupportIds[4]
		assert.is_nil(select(1, tab:SetSupport(4, otherId)))
		assert.are.equal(4, #tab.profile.skills[1].supports)
		assert.are.equal(supportId, tab.profile.skills[1].supports[4].id)

		freshBuild()
		tab:EnsureData()
		tab.profile.classId = "AurasMinionsTemplar"
		tab:RefreshControls()
		for _, entry in ipairs(tab.controls.class.list) do
			assert.not_matches("%[DNT%]", entry.label)
		end
		local labels = { }
		for _, entry in ipairs(tab.controls.build.list) do labels[entry.id] = entry.label end
		assert.are.equal("Warpriest", labels.AurasMinionsTemplarSmite)
		assert.are.equal("Infamous Warpriest", labels.AurasMinionsTemplarSmiteNoble)

		freshBuild()
		tab.profile.classId = "Crit1HShadow"
		tab.profile.buildId = "Crit1HShadowSpectral"
		tab:RefreshControls()
		assert.is_true(not tab.controls.skillList.controls.new.enabled())
		tab.controls.skillList.controls.new.onClick()
		assert.are.equal(0, #tab.profile.skills)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		tab:RefreshControls()
		for _ = 1, 7 do tab.controls.skillList.controls.new.onClick() end
		assert.are.equal(6, #tab.profile.skills)
		assert.is_true(not tab.controls.skillList.controls.new.enabled())

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		assert(tab:SetSkill(1, "InfernalCryMercenary"))
		assert.is_nil(select(1, tab:SetSkill(2, "InfernalCryMercenary")))
		assert.are.equal(1, #tab.profile.skills)
		assert(tab:SetSkill(2, "FissureSlamMercenary"))
		assert.is_nil(select(1, tab:SetSkill(3, "TectonicSlamFireMercenary")))
		assert.are.equal(2, #tab.profile.skills)
		assert.are.equal("FissureSlamMercenary", tab.profile.skills[2].id)

		freshBuild()
		assert.is_nil(tab.controls.skillMain)
		assert.is_nil(tab.controls.skillMainLabel)
		selectBuild("MeleeAOEMarauderFireSlam")
		assert(tab:SetSkill(1, "InfernalCryMercenary"))
		assert.are.equal("InfernalCryMercenary", tab.profile.mainSkillId)
		assert(tab:SetSkill(1, "FissureSlamMercenary"))
		assert.are.equal("FissureSlamMercenary", tab.profile.mainSkillId)
		assert(tab:SetSkill(1, nil))
		assert.is_nil(tab.profile.mainSkillId)

		freshBuild()
		selectBuild("ElementalWitchLightning")
		assert(tab:SetSkill(1, "ArcMercenary"))
		assert(tab:SetSkill(2, "SparkMercenary"))
		tab.selectedSkillIndex = 1
		tab.controls.skillEnabled.changeFunc(false)
		assert.are.equal(false, tab.profile.skills[1].enabled)
		assert.are.equal(true, tab.profile.skills[2].enabled ~= false)
		assert.are.equal("SparkMercenary", tab.profile.mainSkillId)
		tab.selectedSkillIndex = 2
		tab.controls.skillEnabled.changeFunc(false)
		assert.are.equal(false, tab.profile.skills[2].enabled)
		assert.is_nil(tab.profile.mainSkillId)
		tab.controls.skillEnabled.changeFunc(true)
		assert.are.equal("SparkMercenary", tab.profile.mainSkillId)

		freshBuild()
		tab.profile.buildId = "MeleeAOEMarauderFireSlam"
		tab.profile.classId = "MeleeAOEMarauder"
		tab.profile.skills = { { id = "FissureSlamMercenary", enabled = true, supports = { } } }
		tab.profile.mainSkillId = "FissureSlamMercenary"
		local before = #build.itemsTab.itemSetOrderList
		assert(tab:SetSupport(1, "FistOfWarHigh"))
		assert.are.equal(before, #build.itemsTab.itemSetOrderList)
		assert.are.equal("FistOfWarHigh", tab.profile.skills[1].supports[1].id)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		assert(tab:SetSkill(1, "FissureSlamMercenary"))
		local skill = tab.profile.skills[1]
		skill.supports = { { id = "AddedFireHigh", tier = 3 } }
		local original = copyTable(skill.supports, true)
		local originalGet = build.calcsTab.GetMiscCalculator
		build.calcsTab.GetMiscCalculator = function() error("preview boom") end
		support = assert(tab.data.supports.FistOfWarHigh)
		assert.has_error(function()
			tab:AddSupportTooltip(new("Tooltip"):Tooltip(), support, 1, true)
		end)
		build.calcsTab.GetMiscCalculator = originalGet
		assert.same(original, skill.supports)

		local originalId, originalSupports = skill.id, copyTable(skill.supports, true)
		local originalMainSkillId = tab.profile.mainSkillId
		originalGet = stubThrowingCalculator()
		tooltip = new("Tooltip"):Tooltip()
		support = assert(tab.data.supports.FistOfWarHigh)
		ok, err = pcall(tab.AddSupportTooltip, tab, tooltip, support, 1, true)
		build.calcsTab.GetMiscCalculator = originalGet
		assert.is_false(ok)
		assert.matches("calc boom", tostring(err))
		assert.same(original, skill.supports)
		assert.does_not.match("Mercenary comparison unavailable", tooltipUnavailableText(tooltip))

		originalGet = stubThrowingCalculator()
		tooltip = new("Tooltip"):Tooltip()
		ok, err = pcall(tab.AddSkillTooltip, tab, tooltip, { id = "InfernalCryMercenary" }, true)
		build.calcsTab.GetMiscCalculator = originalGet
		assert.is_false(ok)
		assert.matches("calc boom", tostring(err))
		assert.are.equal(originalId, skill.id)
		assert.same(originalSupports, skill.supports)
		assert.are.equal(originalMainSkillId, tab.profile.mainSkillId)
		assert.does_not.match("Mercenary comparison unavailable", tooltipUnavailableText(tooltip))

		tab.sortGemsByDPS = true
		tab:RefreshSupportLists()
		originalGet = build.calcsTab.GetMiscCalculator
		build.calcsTab.GetMiscCalculator = function() error("sort boom") end
		local origDevMode = launch.devMode
		launch.devMode = false
		tab:QueueSupportSort(1)
		assert.has_no.errors(function()
			tab:ProcessSupportSort()
		end)
		assert.are.equal("Error", tab.supportSortStatus)
		assert.is_nil(tab.supportSortCache[1])
		assert.is_nil(tab.supportSortCoroutine)
		tab:QueueSupportSort(1)
		launch.devMode = true
		assert.has_error(function()
			tab:ProcessSupportSort()
		end)
		launch.devMode = origDevMode
		build.calcsTab.GetMiscCalculator = originalGet
		assert.is_nil(tab.supportSortCoroutine)

		freshBuild()
		local profile = build.mercenaryTab.profile
		profile.classId = "EleBowRanger"
		profile.buildId = "EleBowRangerClones"
		profile.foundAreaLevel = 68
		profile.mainSkillId = "MirrorArrowMercenary"
		profile.skills = { {
			id = "MirrorArrowMercenary",
			enabled = true,
			skillMinionSkill = 1,
			skillMinionSkillCalcs = 2,
			supports = { },
		} }

		local saved = { elem = "Mercenary", attrib = { } }
		build.mercenaryTab:Save(saved)
		assert.are.equal("2", saved[1][1].attrib.skillMinionSkillCalcs)

		build.mercenaryTab:Reset()
		build.mercenaryTab:Load(saved)
		local loaded = build.mercenaryTab.profile.skills[1]
		assert.are.equal(1, loaded.skillMinionSkill)
		assert.are.equal(2, loaded.skillMinionSkillCalcs)
	end)

	it("malformed Mercenary state is preserved but blocks calculation", function()
		local function loadSet(attrib)
			tab:Load({
				attrib = { },
				{
					elem = "MercenarySet",
					attrib = attrib,
					{ elem = "Skill", attrib = { id = "TectonicSlamFireMercenary", enabled = "true" } },
				},
			})
		end

		loadSet({
			id = "1",
			buildId = "MeleeAOEMarauderFireSlam",
			mainSkillId = "TectonicSlamFireMercenary",
		})
		assert.is_nil(tab.profile.foundAreaLevel)
		assert.matches("Mercenary level", table.concat(tab:GetErrors(), "\n"))

		loadSet({
			id = "1",
			buildId = "MeleeAOEMarauderFireSlam",
			foundAreaLevel = "not-a-number",
			mainSkillId = "TectonicSlamFireMercenary",
		})
		assert.is_nil(tab.profile.foundAreaLevel)
		assert.matches("Mercenary level", table.concat(tab:GetErrors(), "\n"))

		loadSet({
			id = "1",
			buildId = "MeleeAOEMarauderFireSlam",
			foundAreaLevel = "83",
			mainSkillId = "TectonicSlamFireMercenary",
		})
		assert.are.equal(83, tab.profile.foundAreaLevel)

		freshBuild()
		tab:EnsureData()
		local skillIds = { }
		for _, skillId in ipairs(tab.data.builds.MeleeAOEMarauderFireSlam.skillIds) do
			table.insert(skillIds, skillId)
			if #skillIds == 7 then break end
		end
		local setNode = {
			elem = "MercenarySet",
			attrib = {
				id = "1",
				buildId = "MeleeAOEMarauderFireSlam",
				foundAreaLevel = "68",
				mainSkillId = skillIds[1],
			},
		}
		for _, skillId in ipairs(skillIds) do
			table.insert(setNode, { elem = "Skill", attrib = { id = skillId, enabled = "true" } })
		end
		local mercenaryXml = { attrib = { }, setNode }
		tab:Load(mercenaryXml)
		assert.are.equal(7, #tab.profile.skills)
		for index, skillId in ipairs(skillIds) do
			assert.are.equal(skillId, tab.profile.skills[index].id)
		end

		local mercSet = tab:GetItemSet(true)
		local uniqueBody = new("Item"):Item("Rarity: Unique\nIllegal Unique Body\nPlate Vest")
		build.itemsTab:AddItem(uniqueBody, true)
		mercSet["Body Armour"].selItemId = uniqueBody.id

		local itemsXml, savedMercenary = { }, { }
		build.itemsTab:Save(itemsXml)
		tab:Save(savedMercenary)
		newBuild()
		selectScionLuminary()
		tab = build.mercenaryTab
		build.itemsTab:Load(itemsXml)
		tab:Load(savedMercenary)
		tab:PostLoad()

		assert.are.equal(7, #tab.profile.skills)
		for index, skillId in ipairs(skillIds) do
			assert.are.equal(skillId, tab.profile.skills[index].id)
		end
		assert.are.equal(uniqueBody.id, tab:GetItemSet(true)["Body Armour"].selItemId)
		local errors = table.concat(tab:GetErrors(), "\n")
		assert.matches("cannot have more than 6", errors)
		assert.matches("Body Armour", errors)
		assert.is_true(not tab.controls.skillList.controls.new.enabled())
		tab:AddSkill()
		assert.are.equal(7, #tab.profile.skills)

		build.configTab.input.enemyLevel = 83
		build.configTab:BuildModList()
		build.spec.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		runCallback("OnFrame")
		assert.is_nil(build.calcsTab.mainEnv.mercenary)
		assert.is_nil(build.calcsTab.mainEnv.mercenaryCalculationErrors)
		assert.matches("cannot have more than 6", table.concat(tab:GetErrors(), "\n"))

		local profile = {
			buildId = "AurasMinionsTemplarSpectres",
			foundAreaLevel = 68,
			mainSkillId = "SSMHolySpectresMercenary",
			skills = { {
				id = "SSMHolySpectresMercenary",
				enabled = true,
				supports = { { tier = 3 } },
			} },
		}
		local ok, validateErrors = pcall(MercenaryTools.validateProfile, profile, data.ensureMercenaries())
		assert.is_true(ok)
		assert.matches("Invalid support", table.concat(validateErrors, "\n"))

		newBuild()
		local runtimeProfile = build.mercenaryTab.profile
		runtimeProfile.classId = "AurasMinionsTemplar"
		runtimeProfile.buildId = "AurasMinionsTemplarSpectres"
		runtimeProfile.foundAreaLevel = 68
		runtimeProfile.mainSkillId = "SSMHolySpectresMercenary"
		runtimeProfile.skills = { { enabled = true, supports = { } } }
		build.mercenaryTab:Changed()
		build.configTab:BuildModList()
		local calculated, calculationError = pcall(function() build.calcsTab:BuildOutput() end)
		assert.is_true(calculated, calculationError)
		assert.is_nil(build.calcsTab.mainEnv.mercenary)
		assert.is_nil(build.calcsTab.mainEnv.mercenaryCalculationErrors)
		assert.matches("Invalid skill for selected build", table.concat(build.mercenaryTab:GetErrors(), "\n"))
	end)

	it("comparison actor follows Items vs Edit Equipment context, not who wears the set", function()
		selectBuild("MeleeAOEMarauderFireSlam")
		local itemsTab = build.itemsTab
		local playerSetId = itemsTab.activeItemSetId
		assert(itemsTab:SetActorItemSet("MERCENARY", playerSetId, false))
		tab.controls.editEquipment.onClick()
		assert.are.equal("ITEMS", build.viewMode)
		assert.are.equal(playerSetId, itemsTab.viewItemSetId)
		assert.are.equal("MERCENARY", itemsTab:ComparisonActorForItemSet(playerSetId))
		assert.are.equal("MERCENARY", itemsTab:ItemCalculationOverride("Helmet", item()).comparisonActor)

		assert.are.equal("MERCENARY", itemsTab:ComparisonActorForItemSet(playerSetId))
		assert(itemsTab:SetViewItemSet(playerSetId))
		assert.are.equal("PLAYER", itemsTab:ComparisonActorForItemSet(playerSetId))
		assert.are.equal("PLAYER", itemsTab:ItemCalculationOverride("Helmet", item()).comparisonActor)

		freshBuild()
		selectBuild("MeleeAOEMarauderFireSlam")
		itemsTab = build.itemsTab
		local mercSet = assert(tab:GetItemSet(true))
		assert(itemsTab:SetViewItemSet(mercSet.id))
		assert.are_not.equal(itemsTab.activeItemSetId, mercSet.id)
		assert.are.equal("MERCENARY", itemsTab:ComparisonActorForItemSet(mercSet.id))
		assert.are.equal("MERCENARY", itemsTab:ItemCalculationOverride("Helmet", item()).comparisonActor)

		assert(tab:GetItemSet(true))
		local bossingSet = itemsTab:NewItemSet()
		bossingSet.title = "Bossing"
		table.insert(itemsTab.itemSetOrderList, bossingSet.id)
		assert(itemsTab:SetActorItemSet("MERCENARY", bossingSet.id, false))
		assert(itemsTab:SetViewItemSet(bossingSet.id))
		assert.are_not.equal(itemsTab.activeItemSetId, bossingSet.id)
		assert.are.equal("MERCENARY", itemsTab:ComparisonActorForItemSet(bossingSet.id))
		assert.are.equal("MERCENARY", itemsTab:ItemCalculationOverride("Helmet", item()).comparisonActor)
	end)

	it("migrates legacy Slot XML into the fallback item set", function()
		freshBuild()
		local itemsTab = build.itemsTab
		itemsTab:Load({
			attrib = { useSecondWeaponSet = "false" },
			{
				elem = "Item",
				attrib = { id = "1" },
				"Rarity: Normal\nIron Hat",
			},
			{
				elem = "Slot",
				attrib = { name = "Helmet", itemId = "1" },
			},
		})
		assert.are.equal(1, itemsTab.activeItemSet.Helmet.selItemId)
		assert.are.equal(1, itemsTab.slots.Helmet.selItemId)
	end)

	it("copies a Mercenary loadout without cloning ItemsTab item sets", function()
		selectBuild("MeleeAOEMarauderFireSlam")
		local itemsTab = build.itemsTab
		local mercSet = assert(tab:GetItemSet(true))
		local sourceItemSetId = itemsTab:GetActorItemSetId("MERCENARY")
		local helmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(helmet, true)
		mercSet.Helmet.selItemId = helmet.id
		local setCount = #itemsTab.itemSetOrderList
		tab:ResetUndo()

		local manager = new("MercenarySetListControl"):MercenarySetListControl(nil, { 0, 0, 350, 200 }, tab)
		manager.selValue = tab.activeMercenarySetId
		manager.selIndex = 1
		local popup
		local originalOpenPopup = main.OpenPopup
		local originalClosePopup = main.ClosePopup
		main.OpenPopup = function(_, _, _, _, controls) popup = controls end
		main.ClosePopup = function() end
		local ok, err = pcall(function()
			manager.controls.copy.onClick()
			popup.edit.buf = "Copied Loadout"
			popup.save.onClick()
		end)
		main.OpenPopup = originalOpenPopup
		main.ClosePopup = originalClosePopup
		assert.is_true(ok, err)

		local copied
		for _, setId in ipairs(tab.mercenarySetOrderList) do
			if tab.mercenarySets[setId].title == "Copied Loadout" then copied = tab.mercenarySets[setId] break end
		end
		assert.is_not_nil(copied)
		assert.is_not_nil(copied.itemSetId)
		assert.are_not.equal(sourceItemSetId, copied.itemSetId)
		assert.are.equal(setCount + 1, #itemsTab.itemSetOrderList)
		assert.are.equal(helmet.id, itemsTab.itemSets[copied.itemSetId].Helmet.selItemId)
		assert.are.equal(sourceItemSetId, itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(helmet.id, mercSet.Helmet.selItemId)

		tab:Undo()
		assert.is_nil(tab.mercenarySets[copied.id])
		assert.is_not_nil(itemsTab.itemSets[sourceItemSetId])
		assert.are.equal(sourceItemSetId, itemsTab:GetActorItemSetId("MERCENARY"))
	end)

	it("isolates Mercenary undo from Items sets, assignment, and Config redo", function()
		MercenaryTest.allocatePermanentHire()
		tab = build.mercenaryTab
		tab:EnsureData()
		local itemsTab = build.itemsTab
		tab.profile.buildId = "MeleeAOEMarauderFireSlam"
		tab.profile.classId = tab.data.builds.MeleeAOEMarauderFireSlam.classId
		tab.profile.foundAreaLevel = 68
		tab:Changed()
		assert.is_nil(tab:GetItemSet(false))
		tab:ResetUndo()
		tab.controls.editEquipment.onClick()
		local createdId = itemsTab:GetActorItemSetId("MERCENARY")
		local hat = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(hat, true)
		itemsTab.itemSets[createdId].Helmet.selItemId = hat.id
		itemsTab:AddUndoState()
		tab.profile.foundAreaLevel = 80
		tab:Changed()
		tab:Undo()
		assert.are.equal(68, tab.profile.foundAreaLevel)
		assert.is_not_nil(itemsTab.itemSets[createdId])
		assert.are.equal(hat.id, itemsTab.itemSets[createdId].Helmet.selItemId)
		local bossing = itemsTab:NewItemSet()
		bossing.title = "Bossing"
		table.insert(itemsTab.itemSetOrderList, bossing.id)
		tab.profile.foundAreaLevel = 80
		tab:Changed()
		itemsTab:ResetUndo()
		assert(itemsTab:SetActorItemSet("MERCENARY", bossing.id, false))
		itemsTab:AddUndoState()
		tab:Undo()
		assert.are.equal(68, tab.profile.foundAreaLevel)
		assert.are.equal(bossing.id, itemsTab:GetActorItemSetId("MERCENARY"))
		itemsTab:Undo()
		assert.are.equal(createdId, itemsTab:GetActorItemSetId("MERCENARY"))
		tab:ResetUndo()
		tab.profile.foundAreaLevel = 80
		tab:Changed()
		tab:Undo()
		assert.are.equal(68, tab.profile.foundAreaLevel)
		assert.are.equal(1, #tab.redo)
		local configTab = build.configTab
		configTab:ResetUndo()
		configTab.input.usePowerCharges = true
		configTab:BuildModList()
		configTab:AddUndoState()
		configTab:Undo()
		assert.are.equal(1, #tab.redo)
		tab:Redo()
		assert.are.equal(80, tab.profile.foundAreaLevel)
	end)

	local function hireMarauder(skillId)
		build.characterLevelAutoMode = false
		build.characterLevel = 90
		MercenaryTest.allocatePermanentHire()
		tab = build.mercenaryTab
		tab:EnsureData()
		skillId = skillId or "TectonicSlamFireMercenary"
		local buildId = "MeleeAOEMarauderFireSlam"
		tab.profile.classId = tab.data.builds[buildId].classId
		tab.profile.buildId = buildId
		tab.profile.foundAreaLevel = 68
		tab.profile.mainSkillId = skillId
		tab.profile.skills = { { id = skillId, enabled = true, supports = { } } }
		tab:GetItemSet(true)
		tab:Changed()
		return tab
	end

	it("undo Reset and unhire restore mercenary configuration", function()
		hireMarauder()
		local config = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(config)
		config.actors.mercenary.customModsList[1].text = "+1000 to maximum Life"
		build.configTab:BuildModList()
		local withMod = assert(MercenaryTest.calculateBuild().mercenary).output.Life
		tab:ResetUndo()
		tab:Reset()
		MercenaryTest.calculateBuild()
		tab:Undo()
		assert.are.equal(withMod, assert(MercenaryTest.calculateBuild().mercenary).output.Life)
		newBuild()
		build.characterLevelAutoMode = false
		build.characterLevel = 90
		MercenaryTest.allocatePermanentHire()
		tab = build.mercenaryTab
		config = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(config)
		config.actors.mercenary.customModsList[1].text = "+1000 to maximum Life"
		build.configTab:BuildModList()
		MercenaryTest.calculateBuild()
		tab:ResetUndo()
		hireMarauder()
		assert.is_not_nil(MercenaryTest.calculateBuild().mercenary)
		tab:Undo()
		assert.is_nil(MercenaryTest.calculateBuild().mercenary)
		assert.is_false(build.configTab.modListHasHiredMercenary)
	end)

	it("undo cancels in-flight support sorting", function()
		hireMarauder("FissureSlamMercenary")
		MercenaryTest.calculateBuild()
		tab:ResetUndo()
		tab.profile.foundAreaLevel = 80
		tab:Changed()
		MercenaryTest.calculateBuild()
		tab.sortGemsByDPS = true
		tab.sortGemsByDPSField = "CombinedDPS"
		tab:RefreshSupportLists()
		local originalCalculator = build.calcsTab.GetMiscCalculator
		local sortEnvironment = getfenv(tab.QueueSupportSort)
		local originalTime = sortEnvironment.GetTime
		local ticks = 0
		sortEnvironment.GetTime = function()
			ticks = ticks + 100
			return ticks
		end
		build.calcsTab.GetMiscCalculator = function()
			return function()
				local skill = tab.profile.skills[tab.selectedSkillIndex]
				local supportId = skill and skill.supports[1] and skill.supports[1].id
				return { CombinedDPS = (tab.profile.foundAreaLevel or 0) + (supportId == "AddedFireHigh" and 1000 or 0) }
			end
		end
		local ok, err = pcall(function()
			tab:QueueSupportSort(1)
			tab:ProcessSupportSort()
			assert.is_not_nil(tab.supportSortCoroutine)
			tab:Undo()
			assert.is_nil(tab.supportSortCoroutine)
			assert.is_nil(tab.supportSortCache[1])
			while tab.supportSortCoroutine do tab:ProcessSupportSort() end
			local published = { }
			for _, row in ipairs(tab.supportControls[1].list) do
				if row.dps then published[row.id or "none"] = row.dps end
			end
			tab:InvalidateSupportSort()
			tab:RefreshSupportLists()
			tab:QueueSupportSort(1)
			while tab.supportSortCoroutine do tab:ProcessSupportSort() end
			local expected = { }
			for _, row in ipairs(tab.supportControls[1].list) do
				expected[row.id or "none"] = row.dps
			end
			assert.are.equal(68 + 1000, expected.AddedFireHigh)
			for id, dps in pairs(published) do
				assert.are.equal(expected[id], dps)
			end
		end)
		sortEnvironment.GetTime = originalTime
		build.calcsTab.GetMiscCalculator = originalCalculator
		assert.is_true(ok, err)
	end)

	it("trade set dropdown keeps the current comparison actor", function()
		selectBuild("MeleeAOEMarauderFireSlam")
		local itemsTab = build.itemsTab
		local mercSet = assert(tab:GetItemSet(true))
		assert(itemsTab:SetViewItemSet(mercSet.id, "MERCENARY"))
		local tradeQuery = itemsTab.tradeQuery
		local originalOpenPopup = main.OpenPopup
		local originalUpdateRealms = tradeQuery.UpdateRealms
		local originalPullCXData = tradeQuery.PullCXData
		main.OpenPopup = function() end
		tradeQuery.UpdateRealms = function() end
		tradeQuery.PullCXData = function() end
		local ok, err = pcall(function() tradeQuery:PriceItem() end)
		main.OpenPopup = originalOpenPopup
		tradeQuery.UpdateRealms = originalUpdateRealms
		tradeQuery.PullCXData = originalPullCXData
		assert.is_true(ok, err)
		local mercIndex = isValueInArray(itemsTab.itemSetOrderList, mercSet.id)
		tradeQuery.controls.setSelect.selFunc(mercIndex)
		assert.are.equal("MERCENARY", itemsTab.viewComparisonActor)
		assert.are.equal(mercSet.id, itemsTab.viewItemSetId)
	end)

	it("edits Mercenary supports as a dense list", function()
		local supports = { { id = "FistOfWarHigh" }, { id = "AddedFireHigh" } }
		MercenaryTools.setSkillSupport(supports, 1, nil)
		assert.are.equal(1, #supports)
		assert.are.equal("AddedFireHigh", supports[1].id)
		supports = { }
		MercenaryTools.setSkillSupport(supports, 3, { id = "AddedFireHigh", tier = 3 })
		assert.are.equal(1, #supports)
		assert.are.equal("AddedFireHigh", supports[1].id)
		local skill = { supports = { { id = "FistOfWarHigh" } } }
		local seen
		MercenaryTools.withEditedSupports(skill, 3, { id = "AddedFireHigh" }, function()
			seen = copyTable(skill.supports, true)
		end)
		assert.are.equal(2, #seen)
		assert.are.equal("AddedFireHigh", seen[2].id)
		assert.are.equal(1, #skill.supports)
		assert.are.equal("FistOfWarHigh", skill.supports[1].id)
	end)
end)
