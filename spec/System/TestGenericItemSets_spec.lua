describe("Generic item sets for player, Animate Guardian, and Mercenary", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local selectScionLuminary = MercenaryTest.selectScionLuminary
	local MercenaryTools = require("Modules.MercenaryTools")

	local function findGuardianGem()
		for _, socketGroup in ipairs(build.skillsTab.socketGroupList) do
			for _, gem in ipairs(socketGroup.gemList) do
				local name = gem.nameSpec or (gem.gemData and gem.gemData.name) or (gem.grantedEffect and gem.grantedEffect.name)
				if name == "Animate Guardian" then
					return gem
				end
			end
		end
	end

	local function findCanonicalGuardianItemSet()
		local itemsTab = build.itemsTab
		for _, itemSetId in ipairs(itemsTab.itemSetOrderList) do
			local itemSet = itemsTab.itemSets[itemSetId]
			if itemSet.title == "Animate Guardian" and itemSet.id ~= itemsTab.activeItemSetId then
				return itemSet
			end
		end
	end

	local function makeImportItem(typeLine, inventoryId, itemId)
		return {
			id = itemId or "guardian-helm-1",
			frameType = 0,
			name = "",
			typeLine = typeLine,
			inventoryId = inventoryId,
			ilvl = 10,
			properties = {},
			sockets = {},
			socketedItems = {},
		}
	end

	before_each(function()
		newBuild()
	end)

	it("Items dropdown views a set without wearing it", function()
		local itemsTab = build.itemsTab
		local secondSet = itemsTab:NewItemSet()
		secondSet.title = "Alternate"
		table.insert(itemsTab.itemSetOrderList, secondSet.id)
		local playerHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		local otherHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(playerHelmet, true)
		itemsTab:AddItem(otherHelmet, true)
		local playerSetId = itemsTab.activeItemSetId
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		secondSet.Helmet.selItemId = otherHelmet.id
		itemsTab:PopulateSlots()

		itemsTab.controls.setSelect.selIndex = 2
		itemsTab.controls.setSelect.selFunc(2, secondSet.title)
		assert.are.equal(playerSetId, itemsTab.activeItemSetId)
		assert.are.equal(secondSet.id, itemsTab.viewItemSetId)
		assert.are.equal(otherHelmet.id, itemsTab.slots.Helmet.selItemId)
		assert.are.equal(playerSetId, build.configTab.configSets[build.configTab.activeConfigSetId].actors.player.itemSetId)

		secondSet.title = "Inspected"
		assert(itemsTab:SetViewItemSet(secondSet.id))
		itemsTab:Draw({ x = 0, y = 0, width = 1920, height = 1080 }, { })
		assert.are.equal(2, itemsTab.controls.setSelect.selIndex)
		assert.are.equal(secondSet.id, itemsTab.viewItemSetId)
		assert.are.equal(playerSetId, itemsTab.activeItemSetId)

		selectScionLuminary()
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		local staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		local shield = new("Item"):Item("Rarity: Normal\nGoathide Buckler")
		itemsTab:AddItem(staff, true)
		itemsTab:AddItem(shield, true)
		mercSet["Weapon 1"].selItemId = staff.id
		mercSet["Weapon 2"].selItemId = shield.id
		assert(itemsTab:SetViewItemSet(mercSet.id))
		itemsTab:PopulateSlots()
		assert.are.equal(staff.id, mercSet["Weapon 1"].selItemId)
		assert.are.equal(shield.id, mercSet["Weapon 2"].selItemId)
		local listed
		for index, itemId in ipairs(itemsTab.slots["Weapon 2"].items) do
			if itemId == shield.id then listed = itemsTab.slots["Weapon 2"].list[index] break end
		end
		assert.is_not_nil(listed)
		assert.matches(colorCodes.NEGATIVE, listed, nil, true)

		newBuild()
		itemsTab = build.itemsTab
		local wand = new("Item"):Item("Rarity: Normal\nDriftwood Wand")
		shield = new("Item"):Item("Rarity: Normal\nGoathide Buckler")
		staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		itemsTab:AddItem(wand, true)
		itemsTab:AddItem(shield, true)
		itemsTab:AddItem(staff, true)
		itemsTab.activeItemSet["Weapon 1"].selItemId = wand.id
		itemsTab.activeItemSet["Weapon 2"].selItemId = shield.id
		itemsTab:PopulateSlots()
		itemsTab.slots["Weapon 1"]:SetSelItemId(staff.id, itemsTab:GetVisibleItemSet())
		itemsTab:PopulateSlots()
		assert.are.equal(0, itemsTab.activeItemSet["Weapon 2"].selItemId)
		assert.are.equal(0, itemsTab.slots["Weapon 2"].selItemId)

		newBuild()
		itemsTab = build.itemsTab
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nHeavy Strike 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1 Swap\nCleave 20/0  1\n")
		build.mainSocketGroup = 1
		local inactiveSet = itemsTab:NewItemSet()
		inactiveSet.title = "Inactive"
		table.insert(itemsTab.itemSetOrderList, inactiveSet.id)
		assert(itemsTab:SetViewItemSet(inactiveSet.id))
		itemsTab.controls.weaponSwap2.onClick()
		assert.is_true(inactiveSet.useSecondWeaponSet)
		assert.is_not_true(itemsTab.activeItemSet.useSecondWeaponSet)
		assert.are.equal(1, build.mainSocketGroup)

		assert(itemsTab:SetViewItemSet(itemsTab.activeItemSetId))
		itemsTab.controls.weaponSwap2.onClick()
		assert.is_true(itemsTab.activeItemSet.useSecondWeaponSet)
		assert.are.equal(2, build.mainSocketGroup)
	end)

	it("lets any actor wear any item set and excludes the auto Mercenary set from player loadouts", function()
		selectScionLuminary()
		local itemsTab = build.itemsTab
		local playerSet = itemsTab.activeItemSet
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local mercSet = build.mercenaryTab:GetItemSet(true)
		assert.are_not.equal(playerSet.id, mercSet.id)
		assert(build.mercenaryTab:SetItemSet(playerSet.id))
		assert.are.equal(playerSet.id, build.mercenaryTab.itemSetId)
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		local gem = assert(findGuardianGem())
		gem.skillMinionItemSet = playerSet.id
		gem.skillMinionItemSetCalcs = playerSet.id

		local helmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(helmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = helmet.id
		local valid, reason = MercenaryTools.validateEquippedItem(helmet, "Helmet", {
			profile = build.mercenaryTab.profile,
			mercenaryData = build.mercenaryTab.data,
			itemSet = itemsTab.activeItemSet,
			playerItemSet = itemsTab.activeItemSet,
			items = itemsTab.items,
			playerHasFlag = function() return true end,
		})
		assert.is_true(valid, reason)

		local function contains(list, wanted)
			for _, itemSetId in ipairs(list) do
				if itemSetId == wanted then return true end
			end
			return false
		end
		local playerSets = itemsTab:GetPlayerItemSetOrderList()
		assert.is_true(contains(playerSets, playerSet.id))
		assert.is_true(not contains(playerSets, mercSet.id))
		assert.is_true(contains(itemsTab:GetMinionItemSetOrderList(), mercSet.id))

		local bossingSet = itemsTab:NewItemSet()
		bossingSet.title = "Bossing"
		table.insert(itemsTab.itemSetOrderList, bossingSet.id)
		assert(build.mercenaryTab:SetItemSet(bossingSet.id))
		playerSets = itemsTab:GetPlayerItemSetOrderList()
		assert.is_true(contains(playerSets, playerSet.id))
		assert.is_true(contains(playerSets, bossingSet.id))
		assert.is_true(not contains(playerSets, mercSet.id))

		local xml = { }
		build.itemsTab:Save(xml)
		for _, node in ipairs(xml) do
			if node.elem == "ItemSet" then
				assert.is_nil(node.attrib.owner)
			end
		end
	end)

	it("imports Animate Guardian gear into the canonical AG set, not worn or custom gem refs", function()
		local itemsTab = build.itemsTab
		local guardianSet = itemsTab:NewItemSet()
		guardianSet.title = "Animate Guardian"
		table.insert(itemsTab.itemSetOrderList, guardianSet.id)
		local oldHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(oldHelmet, true)
		guardianSet.Helmet.selItemId = oldHelmet.id
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		runCallback("OnFrame")
		local gem = assert(findGuardianGem())
		gem.skillMinionItemSet = guardianSet.id
		gem.skillMinionItemSetCalcs = guardianSet.id
		local setCountBefore = #itemsTab.itemSetOrderList
		build.importTab:ImportItemsAndSkills({
			level = 12,
			equipment = { makeImportItem("Driftwood Wand", "Weapon", "player-weapon-1") },
			guardian = { makeImportItem("Leather Cap", "Helm", "fresh-guardian-helm") },
		}, false, true, true)
		assert.are.equal(setCountBefore, #itemsTab.itemSetOrderList)
		assert.are.equal("fresh-guardian-helm", itemsTab.items[guardianSet.Helmet.selItemId].uniqueID)

		newBuild()
		itemsTab = build.itemsTab
		local playerHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(playerHelmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		runCallback("OnFrame")
		gem = assert(findGuardianGem())
		gem.skillMinionItemSet = itemsTab.activeItemSetId
		gem.skillMinionItemSetCalcs = itemsTab.activeItemSetId
		setCountBefore = #itemsTab.itemSetOrderList
		build.importTab:ImportItemsAndSkills({
			level = 12,
			equipment = { makeImportItem("Driftwood Wand", "Weapon", "player-weapon-1") },
			guardian = { makeImportItem("Leather Cap", "Helm", "fresh-guardian-helm") },
		}, false, false, true)
		assert.are.equal(playerHelmet.id, itemsTab.activeItemSet.Helmet.selItemId)
		gem = assert(findGuardianGem())
		assert.are.equal(itemsTab.activeItemSetId, gem.skillMinionItemSet)
		local canonical = assert(findCanonicalGuardianItemSet())
		assert.are.equal("fresh-guardian-helm", itemsTab.items[canonical.Helmet.selItemId].uniqueID)
		assert.is_true(#itemsTab.itemSetOrderList > setCountBefore)

		newBuild()
		itemsTab = build.itemsTab
		local bossSet = itemsTab:NewItemSet()
		bossSet.title = "Boss AG"
		table.insert(itemsTab.itemSetOrderList, bossSet.id)
		local calcsSet = itemsTab:NewItemSet()
		calcsSet.title = "Calcs AG"
		table.insert(itemsTab.itemSetOrderList, calcsSet.id)
		local bossHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		local calcsHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(bossHelmet, true)
		itemsTab:AddItem(calcsHelmet, true)
		bossSet.Helmet.selItemId = bossHelmet.id
		calcsSet.Helmet.selItemId = calcsHelmet.id
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		runCallback("OnFrame")
		gem = assert(findGuardianGem())
		gem.skillMinionItemSet = bossSet.id
		gem.skillMinionItemSetCalcs = calcsSet.id
		build.importTab:ImportItemsAndSkills({
			level = 12,
			equipment = { makeImportItem("Driftwood Wand", "Weapon", "player-weapon-1") },
			guardian = { makeImportItem("Leather Cap", "Helm", "fresh-guardian-helm") },
		}, false, false, true)
		gem = assert(findGuardianGem())
		assert.are.equal(bossSet.id, gem.skillMinionItemSet)
		assert.are.equal(calcsSet.id, gem.skillMinionItemSetCalcs)
		assert.are.equal(bossHelmet.id, bossSet.Helmet.selItemId)
		assert.are.equal(calcsHelmet.id, calcsSet.Helmet.selItemId)
		assert.are.equal("fresh-guardian-helm", itemsTab.items[findCanonicalGuardianItemSet().Helmet.selItemId].uniqueID)
	end)

	it("tooltips and equipped detection follow the visible actor except tree jewels stay player", function()
		selectScionLuminary()
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local itemsTab = build.itemsTab
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		local hoverHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(hoverHelmet, true)
		assert(itemsTab:SetViewItemSet(mercSet.id))
		local calcsTab = build.calcsTab
		local originalGetMiscCalculator = calcsTab.GetMiscCalculator
		local captured
		calcsTab.GetMiscCalculator = function(self)
			local calcFunc, calcBase, actorOutputs = originalGetMiscCalculator(self)
			return function(override, useFullDPS)
				captured = override
				return calcFunc(override, useFullDPS)
			end, calcBase, actorOutputs
		end
		local ok, err = pcall(function()
			itemsTab:AddItemTooltip(new("Tooltip"):Tooltip(), hoverHelmet)
			assert.are.equal(mercSet.id, captured.itemSetId)
			assert.are.equal("MERCENARY", captured.comparisonActor)
			assert.are.equal("Helmet", captured.repSlotName)
		end)
		calcsTab.GetMiscCalculator = originalGetMiscCalculator
		assert(ok, err)

		newBuild()
		itemsTab = build.itemsTab
		local spec = build.spec
		local socketNode
		for _, node in pairs(spec.nodes) do
			if node.type == "Socket" then socketNode = node break end
		end
		socketNode = assert(socketNode)
		socketNode.alloc = true
		spec.allocNodes[socketNode.id] = socketNode
		itemsTab:UpdateSockets()
		local jewel = new("Item"):Item("Rarity: RARE\nPlain Spark\nCrimson Jewel\nImplicits: 0\n+100 to maximum Life\n")
		itemsTab:AddItem(jewel, true)
		itemsTab.sockets[socketNode.id]:SetSelItemId(jewel.id)
		itemsTab:PopulateSlots()
		local equippedSlot, equippedSet = itemsTab:GetEquippedSlotForItem(jewel)
		assert.are.equal(itemsTab.sockets[socketNode.id], equippedSlot)
		assert.is_nil(equippedSet)
		assert.are.equal("Jewel "..socketNode.id, itemsTab:GetComparisonSlotNameForItem(jewel))

		selectScionLuminary()
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		mercSet = assert(build.mercenaryTab:GetItemSet(true))
		assert(itemsTab:SetViewItemSet(mercSet.id))
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")
		local capturedActor, compared
		local originalCompare = build.AddStatComparesToTooltip
		build.AddStatComparesToTooltip = function(self, tooltip, baseOutput, compareOutput, header, nodeCount, actor)
			compared = true
			capturedActor = actor
			return originalCompare(self, tooltip, baseOutput, compareOutput, header, nodeCount, actor)
		end
		ok, err = pcall(function()
			itemsTab:AddItemTooltip(new("Tooltip"):Tooltip(), jewel, itemsTab.sockets[socketNode.id])
		end)
		build.AddStatComparesToTooltip = originalCompare
		assert(ok, err)
		assert.is_true(compared)
		assert.is_nil(capturedActor)

		newBuild()
		itemsTab = build.itemsTab
		local equipped = new("Item"):Item("Rarity: Normal\nIron Hat")
		local other = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(equipped, true)
		itemsTab:AddItem(other, true)
		itemsTab.activeItemSet.Helmet.selItemId = equipped.id
		local mapping = itemsTab:NewItemSet()
		mapping.title = "Mapping"
		table.insert(itemsTab.itemSetOrderList, mapping.id)
		mapping.Helmet.selItemId = other.id
		itemsTab:PopulateSlots()
		local slot, set = itemsTab:GetEquippedSlotForItem(equipped)
		assert.are.equal("Helmet", slot.slotName)
		assert.is_nil(set)
		local otherSlot, otherSet = itemsTab:GetEquippedSlotForItem(other)
		assert.are.equal(mapping, otherSet)
		assert.does_not_match("Used in", itemsTab.controls.itemList:GetRowValue(1, 1, equipped.id))
		assert.matches("Used in 'Mapping'", itemsTab.controls.itemList:GetRowValue(1, 1, other.id))
	end)
end)
