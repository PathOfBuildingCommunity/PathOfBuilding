describe("Build loadouts include Mercenary sets", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")

	local function hire(profile, classId, buildId, skillId)
		profile.classId = classId
		profile.buildId = buildId
		profile.foundAreaLevel = 68
		profile.mainSkillId = skillId
		profile.skills = { { id = skillId, enabled = true, supports = { } } }
	end

	local function addNamedLoadout(title)
		local spec = new("PassiveSpec"):PassiveSpec(build, latestTreeVersion)
		spec.title = title
		table.insert(build.treeTab.specList, spec)
		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		itemSet.title = title
		local skillSet = build.skillsTab:NewSkillSet()
		table.insert(build.skillsTab.skillSetOrderList, skillSet.id)
		skillSet.title = title
		local configSet = build.configTab:NewConfigSet()
		table.insert(build.configTab.configSetOrderList, configSet.id)
		configSet.title = title
		return spec, itemSet, skillSet, configSet
	end

	local function addNamedSets(title)
		local spec, itemSet, skillSet, configSet = addNamedLoadout(title)
		local mercenarySet = build.mercenaryTab:NewMercenarySet(nil, title)
		table.insert(build.mercenaryTab.mercenarySetOrderList, mercenarySet.id)
		return spec, itemSet, skillSet, configSet, mercenarySet
	end

	local function selectLoadout(name)
		build:SyncLoadouts()
		local index = isValueInArray(build.controls.buildLoadouts.list, name)
		assert.is_not_nil(index, "missing loadout "..tostring(name))
		build.controls.buildLoadouts.selIndex = nil
		build.controls.buildLoadouts:SetSel(index)
		assert.are.equal(name, build.controls.buildLoadouts.list[build.controls.buildLoadouts.selIndex])
	end

	local function bindHire(setId)
		build.mercenaryTab:SetActiveMercenarySet(setId, false, true)
		build.mercenaryTab:AddUndoState()
	end

	before_each(function()
		newBuild()
		MercenaryTest.allocatePermanentHire()
		build.treeTab.specList[1].title = "Default"
		build.itemsTab.activeItemSet.title = "Default"
		build.skillsTab.skillSets[build.skillsTab.activeSkillSetId].title = "Default"
		build.configTab.configSets[build.configTab.activeConfigSetId].title = "Default"
		build.mercenaryTab.profile.title = "Default"
		hire(build.mercenaryTab.profile, "MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "TectonicSlamFireMercenary")
		build.mercenaryTab:Changed()
	end)

	it("does not create a Mercenary set when using New Loadout", function()
		local popup
		local originalOpenPopup = main.OpenPopup
		local originalClosePopup = main.ClosePopup
		main.OpenPopup = function(_, _, _, _, controls) popup = controls end
		main.ClosePopup = function() end
		local before = #build.mercenaryTab.mercenarySetOrderList
		local ok, err = pcall(function()
			local index = isValueInArray(build.controls.buildLoadouts.list, "^7^7New Loadout")
			build.controls.buildLoadouts:SetSel(index)
			popup.edit.buf = "Boss"
			popup.save.enabled = true
			popup.save.onClick()
		end)
		main.OpenPopup = originalOpenPopup
		main.ClosePopup = originalClosePopup
		assert.is_true(ok, err)
		assert.are.equal(before, #build.mercenaryTab.mercenarySetOrderList)
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Boss"))
	end)

	it("switches the hired Mercenary and restores that hire's equipment", function()
		local _, playerItems, _, _, bossMerc = addNamedSets("Boss")
		local _, _, _, _, mappingMerc = addNamedSets("Mapping")
		hire(bossMerc, "TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		hire(mappingMerc, "EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary")
		build.mercenaryTab:SetActiveMercenarySet(bossMerc.id)
		local bossItems = build.mercenaryTab:GetItemSet(true)
		local bossHelm = new("Item"):Item("Rarity: Normal\nIron Hat")
		build.itemsTab:AddItem(bossHelm, true)
		bossItems.Helmet.selItemId = bossHelm.id
		build.mercenaryTab:StoreActiveMercenaryItemSet()
		build.mercenaryTab:SetActiveMercenarySet(mappingMerc.id)
		local mappingItems = build.mercenaryTab:GetItemSet(true)
		local mappingHelm = new("Item"):Item("Rarity: Normal\nLeather Cap")
		build.itemsTab:AddItem(mappingHelm, true)
		mappingItems.Helmet.selItemId = mappingHelm.id
		build.mercenaryTab:StoreActiveMercenaryItemSet()
		selectLoadout("Mapping")
		assert.are.equal(mappingMerc.id, build.mercenaryTab.activeMercenarySetId)
		assert.are.equal("EleBowRangerFire", build.mercenaryTab.profile.buildId)
		assert.are.equal(mappingMerc.itemSetId, build.itemsTab:GetActorItemSetId("MERCENARY"))
		assert.are.equal(mappingHelm.id, build.itemsTab:GetActorItemSet("MERCENARY").Helmet.selItemId)
		selectLoadout("Boss")
		assert.are.equal(bossMerc.id, build.mercenaryTab.activeMercenarySetId)
		assert.are.equal(playerItems.id, build.itemsTab.activeItemSetId)
		assert.are.equal(bossHelm.id, build.itemsTab:GetActorItemSet("MERCENARY").Helmet.selItemId)
	end)

	it("does not hide player loadouts or wear Mercenary gear as the player set", function()
		addNamedSets("Boss")
		local extra = build.mercenaryTab:NewMercenarySet(nil, "Kaom")
		table.insert(build.mercenaryTab.mercenarySetOrderList, extra.id)
		build:SyncLoadouts()
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Boss"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Default"))
		local _, playerItems, _, _, bossMerc = addNamedSets("Mapping")
		build.mercenaryTab:SetActiveMercenarySet(bossMerc.id)
		local mercItems = build.mercenaryTab:GetItemSet(true)
		selectLoadout("Mapping")
		assert.are.equal(playerItems.id, build.itemsTab.activeItemSetId)
		assert.are.equal(mercItems.id, build.itemsTab:GetActorItemSetId("MERCENARY"))
	end)

	it("links Mercenary sets through brace identifiers without treating Day1 as {1}", function()
		build.treeTab.specList[1].title = "Tree {1}"
		build.itemsTab.activeItemSet.title = "Items {1}"
		build.skillsTab.skillSets[build.skillsTab.activeSkillSetId].title = "Skills {1}"
		build.configTab.configSets[build.configTab.activeConfigSetId].title = "Config {1}"
		build.mercenaryTab.profile.title = "Mercenary {1}"
		local _, _, _, _, secondMerc = addNamedSets("Unused")
		secondMerc.title = "Mercenary {2}"
		build.treeTab.specList[#build.treeTab.specList].title = "Tree {2}"
		build.itemsTab.itemSets[build.itemsTab.itemSetOrderList[#build.itemsTab.itemSetOrderList]].title = "Items {2}"
		build.skillsTab.skillSets[build.skillsTab.skillSetOrderList[#build.skillsTab.skillSetOrderList]].title = "Skills {2}"
		build.configTab.configSets[build.configTab.configSetOrderList[#build.configTab.configSetOrderList]].title = "Config {2}"
		hire(secondMerc, "EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary")
		selectLoadout("Tree {2}")
		assert.are.equal(secondMerc.id, build.mercenaryTab.activeMercenarySetId)
		local _, itemSet, skillSet, configSet = addNamedLoadout("Boss {1}")
		build.mercenaryTab.profile.title = "Day1"
		local linked = build.mercenaryTab:NewMercenarySet(nil, "Hire {1}")
		table.insert(build.mercenaryTab.mercenarySetOrderList, linked.id)
		build.treeTab:SetActiveSpec(#build.treeTab.specList)
		build.itemsTab:SetActiveItemSet(itemSet.id)
		build.skillsTab:SetActiveSkillSet(skillSet.id)
		build.configTab:SetActiveConfigSet(configSet.id)
		build:SyncLoadouts()
		assert.are_not.equal("Boss {1}", build.controls.buildLoadouts.list[build.controls.buildLoadouts.selIndex])
	end)

	it("binds the selected hire only when requested and falls back to the first set", function()
		local _, _, _, day1Config = addNamedLoadout("Day1")
		local _, _, _, armourConfig = addNamedLoadout("ArmourStackMerc")
		local defaultMercId = build.mercenaryTab.activeMercenarySetId
		local second = build.mercenaryTab:NewMercenarySet(nil, "2nd Merc")
		table.insert(build.mercenaryTab.mercenarySetOrderList, second.id)
		hire(second, "PhysicalDuelist", "PhysicalDuelistShields", "ABTTArmourEleMercenary")
		selectLoadout("Day1")
		bindHire(defaultMercId)
		assert.are.equal(defaultMercId, day1Config.mercenarySetId)
		selectLoadout("ArmourStackMerc")
		build.mercenaryTab:SetActiveMercenarySet(second.id)
		assert.is_nil(armourConfig.mercenarySetId)
		bindHire(second.id)
		assert.are.equal(second.id, armourConfig.mercenarySetId)
		selectLoadout("Day1")
		assert.are.equal(defaultMercId, build.mercenaryTab.activeMercenarySetId)
		selectLoadout("ArmourStackMerc")
		assert.are.equal(second.id, build.mercenaryTab.activeMercenarySetId)
		addNamedLoadout("UnboundLoadout")
		selectLoadout("UnboundLoadout")
		assert.are.equal(build.mercenaryTab.mercenarySetOrderList[1], build.mercenaryTab.activeMercenarySetId)
	end)

	it("persists loadout Mercenary bindings through Config XML and drops stale ids", function()
		addNamedLoadout("ArmourStackMerc")
		local second = build.mercenaryTab:NewMercenarySet(nil, "2nd Merc")
		table.insert(build.mercenaryTab.mercenarySetOrderList, second.id)
		local armourConfig
		for _, configSetId in ipairs(build.configTab.configSetOrderList) do
			if build.configTab.configSets[configSetId].title == "ArmourStackMerc" then
				armourConfig = build.configTab.configSets[configSetId]
			end
		end
		armourConfig.mercenarySetId = second.id
		local xml = { elem = "Config" }
		build.configTab:Save(xml)
		build.configTab:Load(xml, "config.xml")
		local loaded
		for _, configSetId in ipairs(build.configTab.configSetOrderList) do
			if build.configTab.configSets[configSetId].title == "ArmourStackMerc" then
				loaded = build.configTab.configSets[configSetId]
			end
		end
		assert.are.equal(second.id, loaded.mercenarySetId)
		loaded.mercenarySetId = 99
		build.configTab.modFlag = false
		build.mercenaryTab:PostLoad()
		assert.is_nil(loaded.mercenarySetId)
		assert.is_false(build.configTab.modFlag)
	end)

	it("clears bindings on delete and marks Config dirty for undo and stale ids", function()
		local _, _, _, armourConfig = addNamedLoadout("ArmourStackMerc")
		local second = build.mercenaryTab:NewMercenarySet(nil, "2nd Merc")
		table.insert(build.mercenaryTab.mercenarySetOrderList, second.id)
		selectLoadout("ArmourStackMerc")
		bindHire(second.id)
		assert.are.equal(second.id, armourConfig.mercenarySetId)
		local manager = new("MercenarySetListControl"):MercenarySetListControl(nil, { 0, 0, 350, 200 }, build.mercenaryTab)
		local originalOpenConfirmPopup = main.OpenConfirmPopup
		main.OpenConfirmPopup = function(_, _, _, _, onConfirm) onConfirm() end
		local ok, err = pcall(function()
			manager:OnSelDelete(isValueInArray(manager.list, second.id), second.id)
		end)
		main.OpenConfirmPopup = originalOpenConfirmPopup
		assert.is_true(ok, err)
		assert.is_nil(armourConfig.mercenarySetId)
		armourConfig.mercenarySetId = 99
		build.configTab.modFlag = false
		selectLoadout("ArmourStackMerc")
		assert.is_nil(armourConfig.mercenarySetId)
		assert.is_true(build.configTab.modFlag)
		local rebound = build.mercenaryTab:NewMercenarySet(nil, "Rebound")
		table.insert(build.mercenaryTab.mercenarySetOrderList, rebound.id)
		build.mercenaryTab:AddUndoState()
		bindHire(rebound.id)
		build.configTab.modFlag = false
		build.mercenaryTab:Undo()
		assert.are_not.equal(rebound.id, armourConfig.mercenarySetId)
		assert.is_true(build.configTab.modFlag)
	end)

	it("does not treat mercenary-owned item sets as player loadout sets", function()
		addNamedSets("Boss")
		local mercIndex = 1
		for _, itemSetId in ipairs(copyTable(build.itemsTab.itemSetOrderList)) do
			local setId = build.mercenaryTab.mercenarySetOrderList[mercIndex]
			if not setId then
				local extra = build.mercenaryTab:NewMercenarySet()
				table.insert(build.mercenaryTab.mercenarySetOrderList, extra.id)
				setId = extra.id
			end
			build.mercenaryTab.mercenarySets[setId].itemSetId = itemSetId
			mercIndex = mercIndex + 1
		end
		assert.are.equal(0, #build:GetPlayerItemSetOrderList())
	end)

	it("does not clear a Config created after the Mercenary undo snapshot", function()
		local second = build.mercenaryTab:NewMercenarySet(nil, "2nd Merc")
		table.insert(build.mercenaryTab.mercenarySetOrderList, second.id)
		bindHire(second.id)
		local newConfig = build.configTab:NewConfigSet()
		table.insert(build.configTab.configSetOrderList, newConfig.id)
		newConfig.title = "AfterSnapshot"
		newConfig.mercenarySetId = second.id
		build.mercenaryTab:Undo()
		assert.are.equal(second.id, newConfig.mercenarySetId)
	end)
end)
