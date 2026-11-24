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
end)
