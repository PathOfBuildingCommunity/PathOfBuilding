describe("Generic item sets for player, Animate Guardian, and Mercenary", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local selectScionLuminary = MercenaryTest.selectScionLuminary
	local MercenaryTools = require("Modules.MercenaryTools")
	local calcs = require("Modules.CalcBase")

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

	it("lets any actor wear any generic item set", function()
		selectScionLuminary()
		local itemsTab = build.itemsTab
		local playerSet = itemsTab.activeItemSet
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local mercSet = build.mercenaryTab:GetItemSet(true)
		assert.are_not.equal(playerSet.id, mercSet.id)
		assert(build.itemsTab:SetActorItemSet("MERCENARY", playerSet.id))
		assert.are.equal(playerSet.id, itemsTab:GetActorItemSetId("MERCENARY"))
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
		assert.is_true(contains(itemsTab.itemSetOrderList, playerSet.id))
		assert.is_true(contains(itemsTab.itemSetOrderList, mercSet.id))

		local bossingSet = itemsTab:NewItemSet()
		bossingSet.title = "Bossing"
		table.insert(itemsTab.itemSetOrderList, bossingSet.id)
		assert(build.itemsTab:SetActorItemSet("MERCENARY", bossingSet.id))
		assert.is_true(contains(itemsTab.itemSetOrderList, playerSet.id))
		assert.is_true(contains(itemsTab.itemSetOrderList, bossingSet.id))
		assert.is_true(contains(itemsTab.itemSetOrderList, mercSet.id))

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

	it("character import returns the Items tab to player equipment", function()
		selectScionLuminary()
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local itemsTab = build.itemsTab
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		local mercHat = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(mercHat, true)
		mercSet.Helmet.selItemId = mercHat.id
		assert(itemsTab:SetViewItemSet(mercSet.id, "MERCENARY"))
		assert.are.equal(mercSet.id, itemsTab.viewItemSetId)
		build.importTab:ImportItemsAndSkills({
			level = 12,
			equipment = { makeImportItem("Iron Hat", "Helm", "imported-helm") },
		}, false, false, true)
		assert.are.equal(itemsTab.activeItemSetId, itemsTab.viewItemSetId)
		assert.are.equal("PLAYER", itemsTab.viewComparisonActor)
		assert.are.equal(mercSet.id, itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(mercHat.id, itemsTab:GetActorItemSet("MERCENARY").Helmet.selItemId)
		assert.are.equal("Iron Hat", itemsTab.items[itemsTab.activeItemSet.Helmet.selItemId].name)
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

	it("does not substitute an unrelated viewed item set for Animate Guardian", function()
		local itemsTab = build.itemsTab
		local guardianSet = itemsTab:NewItemSet()
		guardianSet.title = "Guardian"
		table.insert(itemsTab.itemSetOrderList, guardianSet.id)
		local unrelated = itemsTab:NewItemSet()
		unrelated.title = "Unassigned"
		table.insert(itemsTab.itemSetOrderList, unrelated.id)
		local helm = new("Item"):Item("Rarity: Rare\nGuardian helm\nIron Hat\n+100 to maximum Life")
		itemsTab:AddItem(helm, true)
		guardianSet.Helmet.selItemId = helm.id
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		local gem = assert(findGuardianGem())
		gem.skillMinionItemSet = guardianSet.id
		gem.skillMinionItemSetCalcs = guardianSet.id
		build.buildFlag = true
		runCallback("OnFrame")
		local base = calcs.initEnv(build, "CALCULATOR")
		calcs.perform(base)
		itemsTab:SetViewItemSet(unrelated.id)
		local preview = calcs.initEnv(build, "CALCULATOR", itemsTab:ItemCalculationOverride("Helmet", new("Item"):Item("Rarity: Normal\nLeather Cap")))
		calcs.perform(preview)
		assert.are.equal(guardianSet.id, preview.player.mainSkill.minion.itemSet.id)
		assert.are.equal(base.minion.output.Life, preview.minion.output.Life)
	end)

	it("matches actual weapon replacement for Animate Guardian Full DPS", function()
		local items = build.itemsTab
		local set = items:NewItemSet()
		table.insert(items.itemSetOrderList, set.id)
		local sword = new("Item"):Item("Rarity: Normal\nRusted Sword")
		local better = new("Item"):Item("Rarity: Rare\nReview Sword\nRusted Sword\nAdds 100 to 100 Physical Damage")
		items:AddItem(sword, true)
		items:AddItem(better, true)
		set["Weapon 1"].selItemId = sword.id
		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		local group = build.skillsTab.socketGroupList[1]
		group.includeInFullDPS = true
		local gem = assert(findGuardianGem())
		gem.skillMinionItemSet = set.id
		gem.skillMinionItemSetCalcs = set.id
		build.configTab:BuildModList()
		local calc, base = calcs.getMiscCalculator(build)
		items:SetViewItemSet(set.id)
		local preview = calc(items:ItemCalculationOverride("Weapon 1", better))
		set["Weapon 1"].selItemId = better.id
		local actual = calcs.calcFullDPS(build, "CALCULATOR", {}).combinedDPS
		assert.are.near(actual, preview.FullDPS, 1e-8)
		assert.is_true(preview.FullDPS > base.FullDPS)
	end)

	it("edits and undoes actor item-set assignments without a discarded-state argument", function()
		MercenaryTest.allocatePermanentHire()
		local itemsTab = build.itemsTab
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local mercSet = itemsTab:EnsureActorItemSet("MERCENARY")
		local helm = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(helm, true)
		assert(itemsTab:SetViewItemSet(mercSet.id, "MERCENARY"))
		itemsTab.slots.Helmet:SetSelItemId(helm.id)
		itemsTab:AddUndoState()
		assert.are.equal(helm.id, itemsTab:GetActorItemSet("MERCENARY").Helmet.selItemId)
		assert.are.equal(0, itemsTab.activeItemSet.Helmet.selItemId)
		local playerSetId = itemsTab.activeItemSetId
		assert(itemsTab:SetActorItemSet("MERCENARY", playerSetId, false))
		itemsTab:AddUndoState()
		itemsTab:Undo()
		assert.are.equal(mercSet.id, itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(helm.id, itemsTab.itemSets[mercSet.id].Helmet.selItemId)
		local seen
		function itemsTab:RestoreUndoState(state, extra)
			seen = extra
			self.activeItemSetId = state.activeItemSetId
			self.activeItemSet = self.itemSets[self.activeItemSetId]
		end
		itemsTab:ResetUndo()
		itemsTab:AddUndoState()
		itemsTab:Undo()
		assert.is_nil(seen)
	end)

	it("persists actor assignments, blocks deleting referenced sets, and assigns from the manager", function()
		MercenaryTest.allocatePermanentHire()
		local itemsTab = build.itemsTab
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local mercSet = itemsTab:EnsureActorItemSet("MERCENARY")
		local helm = new("Item"):Item("Rarity: Normal\nIron Hat")
		itemsTab:AddItem(helm, true)
		mercSet.Helmet.selItemId = helm.id
		local extra = itemsTab:NewItemSet()
		extra.title = "Merc Gear"
		table.insert(itemsTab.itemSetOrderList, extra.id)
		itemsTab.actorItemSetIds.ZED = extra.id
		local xml = { elem = "Items" }
		itemsTab:Save(xml)
		local actors, found = { }
		for _, node in ipairs(xml) do
			if node.elem == "ActorItemSet" then
				table.insert(actors, node.attrib.actor)
				if node.attrib.actor == "MERCENARY" then found = tonumber(node.attrib.itemSetId) end
			end
		end
		assert.are.same({ "MERCENARY", "ZED" }, actors)
		assert.are.equal(mercSet.id, found)
		local control = new("ItemSetListControl"):ItemSetListControl(nil, {0,0,350,200}, itemsTab)
		assert.is_false(control:CanDeleteItemSet(mercSet.id))
		control.selValue = extra.id
		control.controls.equipActor:SelByValue("MERCENARY", "id")
		control.controls.equip.onClick()
		assert.are.equal(extra.id, itemsTab:GetActorItemSetId("MERCENARY"))
		newBuild()
		build.itemsTab:Load(xml, "items.xml")
		build.mercenaryTab:Load({ elem = "Mercenary", attrib = { } })
		build.mercenaryTab:PostLoad()
		newBuild()
		MercenaryTest.allocatePermanentHire()
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab:Changed()
		local migrated = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, migrated.id)
		build.mercenaryTab:Load({
			elem = "Mercenary",
			attrib = { activeMercenarySet = "1" },
			{ elem = "MercenarySet", attrib = { id = "1", itemSetId = tostring(migrated.id), buildId = "MeleeAOEMarauderFireSlam" } },
		})
		build.mercenaryTab:PostLoad()
		assert.are.equal(migrated.id, build.itemsTab:GetActorItemSetId("MERCENARY"))
	end)

	it("routes comparison to the viewing actor and does not create a set when selecting a build", function()
		MercenaryTest.allocatePermanentHire()
		local itemsTab = build.itemsTab
		build.mercenaryTab.profile.classId = "MeleeAOEMarauder"
		build.mercenaryTab.profile.buildId = "MeleeAOEMarauderFireSlam"
		build.mercenaryTab.profile.mainSkillId = "TectonicSlamFireMercenary"
		build.mercenaryTab.profile.skills = { { id = "TectonicSlamFireMercenary", enabled = true, supports = { } } }
		build.mercenaryTab:Changed()
		assert.is_nil(itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(1, #itemsTab.itemSetOrderList)
		local mercSet = itemsTab:EnsureActorItemSet("MERCENARY")
		assert(itemsTab:SetViewItemSet(mercSet.id, "MERCENARY"))
		assert.is_false(itemsTab.controls.weaponSwap2:IsShown())
		assert.are.equal("MERCENARY", itemsTab:ComparisonActorForItemSet(mercSet.id))
		assert.are.equal("PLAYER", itemsTab:ComparisonActorForItemSet(itemsTab.activeItemSetId))
		assert.are.equal("MERCENARY", itemsTab:ComparisonActorForSlot("Mercenary Helmet", itemsTab.activeItemSetId))
		assert.are.equal("PLAYER", itemsTab:ComparisonActorForSlot("Jewel 12345", mercSet.id))
	end)
end)
