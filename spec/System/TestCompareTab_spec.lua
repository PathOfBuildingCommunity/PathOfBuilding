describe("CompareTab", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local allocatePermanentHire = MercenaryTest.allocatePermanentHire
	it("imports Mercenary builds and preserves their Calcs skill selection", function()
		newBuild()
		allocatePermanentHire()
		build.mercenaryTab.profile = {
			classId = "EleBowRanger",
			buildId = "EleBowRangerClones",
			foundAreaLevel = 68,
			mainSkillId = "MirrorArrowMercenary",
			lifeComparison = "AUTO",
			skills = {
				{ id = "MirrorArrowMercenary", enabled = true, includeInFullDPS = true, supports = { } },
				{ id = "IceShotMercenary", enabled = true, includeInFullDPS = false, supports = { } },
			},
		}
		build.mercenaryTab:Changed()
		local mercenaryItemSet = build.mercenaryTab:GetItemSet(true)
		local item = new("Item"):Item("Rarity: Normal\nCrude Bow")
		item.id = 999903
		build.itemsTab.items[item.id] = item
		mercenaryItemSet["Weapon 1"].selItemId = item.id
		build.calcsTab.input.actor = "MERCENARY"
		build.configTab.input.enemyLevel = 83
		build.configTab:BuildModList()
		build.calcsTab:BuildOutput()

		local compareTab = build.compareTab
		assert.is_true(compareTab:ImportBuild(assert(build:SaveDB("mercenary-compare")), "Mercenary"))
		local entry = assert(compareTab:GetActiveCompare())
		compareTab:UpdateSetSelectors(entry)
		assert.is_true(compareTab.controls.cmpMainSkill:IsShown())
		assert.are.equal(2, #compareTab.controls.cmpMainSkill.list)
		compareTab.controls.cmpMainSkill:SetSel(2)
		assert.are.equal("IceShotMercenary", entry.mercenaryTab.profile.mainSkillId)
		entry.mercenaryTab.profile.mainSkillId = "MirrorArrowMercenary"
		entry.mercenaryTab:Changed()
		compareTab.compareViewMode = "CALCS"
		compareTab:RefreshCalcsSkillControls(entry)
		assert.is_true(entry.calcsTab:IsMercenaryActor())
		assert.is_true(compareTab.controls.cmpCalcsMainSkill:IsShown())
		assert.are.equal(2, #compareTab.controls.cmpCalcsMainSkill.list)
		compareTab.controls.cmpCalcsMainSkill:SetSel(2)
		assert.are.equal("IceShotMercenary", entry.mercenaryTab.profile.mainSkillId)
	end)

	it("hides skill detail controls after removing the final comparison", function()
		newBuild()
		local compareTab = build.compareTab
		compareTab.compareEntries = { { label = "Test" } }
		compareTab.activeCompareIndex = 1
		local controls = {
			compareTab.controls.cmpMainSkill,
			compareTab.controls.cmpSkillPart,
			compareTab.controls.cmpStageCount,
			compareTab.controls.cmpMineCount,
			compareTab.controls.cmpMinion,
			compareTab.controls.cmpMinionSkill,
		}
		for _, control in ipairs(controls) do
			control.shown = true
		end

		compareTab:RemoveBuild(1)

		for _, control in ipairs(controls) do
			assert.is_false(control:IsShown())
		end
	end)
	it("reproduces matching-socket gem quality when comparing a build with itself", function()
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw(
			"Rarity: RARE\nTest Subject\nSage's Robe\nQuality: 0\nSockets: B-B-B\nImplicits: 0\n")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		runCallback("OnFrame")
		assert.are.equals(10, build.calcsTab.mainOutput.GemQuality)

		-- doesn't actually save to a file, just encodes as xml
		local entry = new("CompareEntry"):CompareEntry(build:SaveDB("code"), "Self")

		assert.is_true(entry.skillsTab.socketGroupList[1].gemList[1].matchesSocket)
		assert.are.equals(build.calcsTab.mainOutput.GemQuality, entry.calcsTab.mainOutput.GemQuality)
		assert.are.equals(build.calcsTab.mainOutput.CombinedDPS, entry.calcsTab.mainOutput.CombinedDPS)
	end)

	it("copies an item from the visible Mercenary set into the primary Mercenary set", function()
		newBuild()
		allocatePermanentHire()
		build.mercenaryTab.profile = {
			classId = "EleBowRanger",
			buildId = "EleBowRangerClones",
			foundAreaLevel = 68,
			mainSkillId = "MirrorArrowMercenary",
			lifeComparison = "AUTO",
			skills = { { id = "MirrorArrowMercenary", enabled = true, supports = { } } },
		}
		build.mercenaryTab:Changed()
		local primaryMercenarySet = assert(build.mercenaryTab:GetItemSet(true))
		local item = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		build.itemsTab:AddItem(item, true)
		build.itemsTab:AddItem(quiver, true)
		primaryMercenarySet["Weapon 1"].selItemId = item.id
		primaryMercenarySet["Weapon 2"].selItemId = quiver.id

		build.configTab.input.enemyLevel = 83
		build.configTab:BuildModList()
		build.calcsTab:BuildOutput()
		local compareTab = build.compareTab
		assert.is_true(compareTab:ImportBuild(assert(build:SaveDB("mercenary-copy")), "Mercenary"))
		local entry = assert(compareTab:GetActiveCompare())
		entry.itemsTab:SetViewItemSet(assert(entry.mercenaryTab.itemSetId))
		build.itemsTab:SetViewItemSet(primaryMercenarySet.id)
		build.calcsTab:BuildOutput()
		local _, baseOutput, actorOutputs = build.calcsTab:GetMiscCalculator()
		assert.are.equal(actorOutputs.PLAYER, baseOutput)
		assert.is_truthy(actorOutputs.MERCENARY)

		local playerWeapon = build.itemsTab.activeItemSet["Weapon 1"]
		playerWeapon.selItemId = 0
		compareTab:CopyCompareItemToPrimary("Weapon 1", entry, true)

		local copiedItemId = primaryMercenarySet["Weapon 1"].selItemId
		assert.is_true(copiedItemId > 0)
		assert.are.equal("Crude Bow", build.itemsTab.items[copiedItemId].name)
		assert.are.equal(0, playerWeapon.selItemId)
	end)

	it("views an item set from Compare without equipping the player", function()
		newBuild()
		allocatePermanentHire()
		build.mercenaryTab.profile = {
			classId = "TrapsMinesShadow",
			buildId = "TrapsMinesShadowLightning",
			foundAreaLevel = 68,
			mainSkillId = "LightningTrapMercenary",
			lifeComparison = "AUTO",
			skills = { { id = "LightningTrapMercenary", enabled = true, supports = { } } },
		}
		build.mercenaryTab:Changed()
		local itemsTab = build.itemsTab
		local playerSetId = itemsTab.activeItemSetId
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		assert.are_not.equal(playerSetId, mercSet.id)
		itemsTab:SetViewItemSet(mercSet.id, "MERCENARY")
		local playerIndex, mercIndex
		for index, itemSetId in ipairs(itemsTab.itemSetOrderList) do
			if itemSetId == playerSetId then playerIndex = index end
			if itemSetId == mercSet.id then mercIndex = index end
		end
		build.compareTab.controls.primaryItemSetSelect.selFunc(playerIndex, itemsTab.itemSets[playerSetId].title or "Default")
		assert.are.equal(playerSetId, itemsTab.activeItemSetId)
		assert.are.equal(playerSetId, itemsTab.viewItemSetId)
		assert.are.equal("MERCENARY", itemsTab.viewComparisonActor)
		build.compareTab.controls.primaryItemSetSelect.selFunc(mercIndex, mercSet.title or "Default")
		assert.are.equal(playerSetId, itemsTab.activeItemSetId)
		assert.are.equal(mercSet.id, itemsTab.viewItemSetId)
		assert.are.equal("MERCENARY", itemsTab.viewComparisonActor)

		assert(build.mercenaryTab:SetItemSet(playerSetId))
		itemsTab:SetViewItemSet(playerSetId, "MERCENARY")
		build.compareTab.controls.primaryItemSetSelect.selFunc(playerIndex, itemsTab.itemSets[playerSetId].title or "Default")
		assert.are.equal("MERCENARY", itemsTab.viewComparisonActor)
		assert.are.equal(playerSetId, itemsTab.activeItemSetId)
	end)

	it("Compare Config copies and edits mercenary actor overlays", function()
		newBuild()
		allocatePermanentHire()
		build.mercenaryTab.profile = {
			classId = "EleBowRanger",
			buildId = "EleBowRangerClones",
			foundAreaLevel = 68,
			mainSkillId = "MirrorArrowMercenary",
			lifeComparison = "AUTO",
			skills = { { id = "MirrorArrowMercenary", enabled = true, includeInFullDPS = true, supports = { } } },
		}
		build.mercenaryTab:Changed()
		build.mercenaryTab:GetItemSet(true)
		local configTab = build.configTab
		local configSet = configTab.configSets[configTab.activeConfigSetId]
		configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.usePowerCharges = true
		configTab:BuildModList()
		build.calcsTab:BuildOutput()

		local compareTab = build.compareTab
		assert.is_true(compareTab:ImportBuild(assert(build:SaveDB("mercenary-config")), "Mercenary"))
		local entry = assert(compareTab:GetActiveCompare())
		configSet.actors.mercenary.input.usePowerCharges = false
		compareTab.configViewActor = "mercenary"
		compareTab:RebuildConfigControls(entry)
		local ctrl = assert(compareTab.configControls.usePowerCharges)
		assert.is_false(ctrl.primaryControl.state)
		assert.is_true(ctrl.compareControl.state)

		compareTab:CopyCompareConfig()
		assert.is_true(configSet.actors.mercenary.input.usePowerCharges)
		assert.is_not_true(configTab.input.usePowerCharges)

		configTab:SetViewActor("player")
		compareTab.configViewActor = "mercenary"
		compareTab:RebuildConfigControls(entry)
		ctrl = assert(compareTab.configControls.usePowerCharges)
		local captured
		configTab.RunComparisonCalc = function(self, calcFunc, comparisonActor)
			captured = comparisonActor
			return calcFunc(comparisonActor and { comparisonActor = comparisonActor } or nil)
		end
		local tooltip = new("Tooltip"):Tooltip()
		assert.has_no.errors(function()
			ctrl.primaryControl.tooltipFunc(tooltip)
		end)
		configTab.RunComparisonCalc = nil
		assert.are.equal("player", configTab:GetViewActor())
		assert.are.equal("MERCENARY", captured)
	end)

	it("Compare Config tooltips include specialized tooltipFunc content", function()
		newBuild()
		local compareTab = build.compareTab
		assert.is_true(compareTab:ImportBuild(assert(build:SaveDB("tooltip-func")), "Self"))
		local entry = assert(compareTab:GetActiveCompare())
		compareTab:RebuildConfigControls(entry)

		local function tooltipText(tooltip)
			local parts = { }
			for _, line in ipairs(tooltip.lines) do
				if line.text then
					table.insert(parts, line.text)
				end
			end
			return table.concat(parts, "\n")
		end

		local bossCtrl = assert(compareTab.configControls.presetBossSkills)
		local tooltip = new("Tooltip"):Tooltip()
		assert.has_no.errors(function()
			bossCtrl.primaryControl.tooltipFunc(tooltip, "HOVER", 1, { val = "None" })
		end)
		assert.is_truthy(tooltipText(tooltip):find("Used to fill in defaults for specific boss skills", 1, true))

		local banditCtrl = assert(compareTab.configControls.bandit)
		tooltip = new("Tooltip"):Tooltip()
		assert.has_no.errors(function()
			banditCtrl.primaryControl.tooltipFunc(tooltip, "HOVER", 1, { val = "Oak" })
		end)
		assert.is_truthy(tooltipText(tooltip):find("+40 to Maximum", 1, true))
	end)
end)
