describe("CompareTab", function()
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
			compareTab.controls.cmpMercenaryItemSet,
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
	it("recalculates the power report when either build changes", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nControlled Destruction 20/0  1\n")
		runCallback("OnFrame")
		local entry = new("CompareEntry"):CompareEntry(build:SaveDB("code"), "Compare")
		-- Config differences rebuild the primary's config mod list, which must not flag a rebuild
		entry.configTab.input.conditionEnemyRareOrUnique = true
		entry.configTab:BuildModList()
		entry:Rebuild()
		local primaryGemList = build.skillsTab.socketGroupList[1].gemList
		local supportGem = table.remove(primaryGemList)
		build.buildFlag = true
		runCallback("OnFrame")

		local compareTab = build.compareTab
		compareTab.compareEntries = { entry }
		compareTab.activeCompareIndex = 1
		for _, powerStat in ipairs(data.powerStatList) do
			if powerStat.stat == "CombinedDPS" then
				compareTab.comparePowerStat = powerStat
			end
		end
		local function runReport()
			runCallback("OnFrame")
			compareTab:RunComparePowerReport(entry)
			while compareTab.comparePowerCoroutine do
				compareTab:RunComparePowerReport(entry)
			end
			local supportResults = 0
			for _, result in ipairs(compareTab.comparePowerResults) do
				if result.category == "Support gem" then
					supportResults = supportResults + 1
				end
			end
			return supportResults
		end

		assert.are.equals(1, runReport())
		-- Finished report must not restart itself
		local results = compareTab.comparePowerResults
		runCallback("OnFrame")
		compareTab:RunComparePowerReport(entry)
		assert.are.equal(results, compareTab.comparePowerResults)

		-- Primary gains the support gem: nothing left to compare
		table.insert(primaryGemList, supportGem)
		build.buildFlag = true
		assert.are.equals(0, runReport())

		-- Compared build loses it too
		table.remove(entry.skillsTab.socketGroupList[1].gemList)
		table.remove(primaryGemList)
		build.buildFlag = true
		entry.buildFlag = true
		entry:Rebuild()
		assert.are.equals(0, runReport())
	end)
	it("keeps mercenary groups apart from player groups with the same gems", function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Spark 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Mercenary: true\nSparkMercenary 20/0  1\n")
		runCallback("OnFrame")
		local entry = new("CompareEntry"):CompareEntry(build:SaveDB("code"), "Self")
		local player, mercenary = entry.skillsTab.socketGroupList[1], entry.skillsTab.socketGroupList[2]
		assert.is_true(mercenary.mercenary)

		local compareTab = build.compareTab
		assert.are_not.equals(compareTab:GetSocketGroupSignature(player), compareTab:GetSocketGroupSignature(mercenary))
		assert.are.equals("Spark", compareTab:GetSocketGroupLabel(player))
		assert.are.equals("Spark (Mercenary)", compareTab:GetSocketGroupLabel(mercenary))
	end)
	-- Compares the build with a copy of itself, using a mercenary group with the given skill as the main skill
	local function compareMercenary(skillId)
		newBuild()
		build.skillsTab:PasteSocketGroup("Mercenary: true\n"..skillId.." 20/0  1\n")
		-- The skill name would be pasted as a "key: value" line
		local gemData = build.data.gems["Metadata/Items/Gems/SkillGemCallMercenary"]
		local group = { label = "", enabled = true, gemList = { { gemId = gemData.id, nameSpec = gemData.name, skillId = gemData.grantedEffectId, level = 20, quality = 0, enabled = true, enableGlobal1 = true, count = 1 } } }
		build.skillsTab:ProcessSocketGroup(group)
		table.insert(build.skillsTab.socketGroupList, group)
		build.mainSocketGroup = 1
		build.calcsTab.input.skill_number = 1
		build.buildFlag = true
		runCallback("OnFrame")
		local entry = new("CompareEntry"):CompareEntry(build:SaveDB("code"), "Self")
		local compareTab = build.compareTab
		compareTab.compareEntries = { entry }
		compareTab.activeCompareIndex = 1
		compareTab.compareViewMode = "CALCS"
		compareTab:RefreshCalcsSkillControls(entry)
		return compareTab, entry
	end
	it("shows the stats of the minion of the mercenary's main skill in the calcs view", function()
		local compareTab, entry = compareMercenary("GigaRaiseZombieMercenary")

		for _, prefix in ipairs({ "primCalcs", "cmpCalcs" }) do
			local actorControl = compareTab.controls[prefix.."ShowMinion"]
			assert.are.equals(3, #actorControl.list)
			assert.are.equals("Mercenary's Raised Zombie", actorControl.list[3].label)
			assert.is_true(compareTab.controls[prefix.."MinionSkill"]:IsShown())
			actorControl.selFunc(3, actorControl.list[3])
		end
		local zombie = entry.calcsTab:GetMercenaryMinion(entry.calcsTab.calcsEnv)
		assert.are.equals(zombie, entry.calcsTab:GetActor(entry.calcsTab.calcsEnv))
	end)
	it("sets the stages of the mercenary's main skill", function()
		local compareTab, entry = compareMercenary("FlameblastMercenary")
		local function stages(env)
			local mainSkill = env.minion.mainSkill
			return mainSkill.skillModList:Sum("BASE", mainSkill.skillCfg, "Multiplier:FlameblastStage")
		end
		compareTab:UpdateSetSelectors(entry)
		for _, name in ipairs({ "primCalcsStageCount", "cmpCalcsStageCount", "cmpStageCount", "primCalcsMercenaryItemSet", "cmpCalcsMercenaryItemSet", "cmpMercenaryItemSet" }) do
			assert.is_true(compareTab.controls[name]:IsShown(), name)
		end
		compareTab.controls.primCalcsStageCount.changeFunc("2")
		compareTab.controls.cmpCalcsStageCount.changeFunc("4")
		compareTab.controls.cmpStageCount.changeFunc("3")
		runCallback("OnFrame")
		entry:Rebuild()
		assert.are.equals(2, stages(build.calcsTab.calcsEnv))
		assert.are.equals(4, stages(entry.calcsTab.calcsEnv))
		assert.are.equals(3, stages(entry.calcsTab.mainEnv))
	end)
end)
