describe("Importing a build into a loadout", function()
	local sourceXML
	local sampleData
	local savedInflate, savedDownload

	setup(function()
		local file = assert(io.open("../spec/System/SampleCharacter.json", "r"))
		sampleData = require("dkjson").decode(file:read("*a")).character
		file:close()
		newBuild()
		build.importTab:ImportItemsAndSkills(sampleData, true, true, false)
		build.importTab:ImportPassiveTreeAndJewels(sampleData, true)
		runCallback("OnFrame")
		build.configTab.input.enemyIsBoss = "Pinnacle"
		sourceXML = build:SaveDB("code")
	end)

	before_each(function()
		newBuild()
		savedInflate = Inflate
		savedDownload = buildSites.DownloadBuild
	end)

	after_each(function()
		Inflate = savedInflate
		buildSites.DownloadBuild = savedDownload
	end)

	it("preserves existing data and remaps equipment and cluster jewels", function()
		build.spec.title = "Original"
		build.itemsTab.activeItemSet.title = "Original"
		build.skillsTab.skillSets[1].title = "Original"
		build.configTab.configSets[1].title = "Original"
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: NORMAL\nIron Hat\n")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
		build.configTab.input.enemyIsBoss = "Boss"
		build.characterLevelAutoMode = false
		build.characterLevel = 84
		build.notesTab.controls.edit:SetText("Keep these notes")
		runCallback("OnFrame")
		local originalSpec = build.spec
		local originalItems = build.itemsTab.activeItemSet
		local originalSkills = build.skillsTab.skillSets[1]
		local originalConfig = build.configTab.configSets[1]
		local originalItem = build.itemsTab.items[build.itemsTab.itemOrderList[1]]
		local originalLevel = build.characterLevel
		local originalName = build.buildName

		assert.is_true(build.importTab:ImportLoadout(sourceXML, "Imported"))
		runCallback("OnFrame")

		assert.equals(originalSpec, build.treeTab.specList[1])
		assert.equals(originalItems, build.itemsTab.itemSets[1])
		assert.equals(originalSkills, build.skillsTab.skillSets[1])
		assert.equals(originalConfig, build.configTab.configSets[1])
		assert.equals(originalItem, build.itemsTab.items[originalItem.id])
		assert.equals(originalLevel, build.characterLevel)
		assert.equals(originalName, build.buildName)
		assert.equals("Keep these notes", build.notesTab.controls.edit.buf)
		assert.equals("Boss", originalConfig.input.enemyIsBoss)
		assert.equals("Fireball", originalSkills.socketGroupList[1].gemList[1].nameSpec)
		assert.equals("Imported", build.spec.title)
		assert.equals("Imported", build.itemsTab.activeItemSet.title)
		assert.equals("Imported", build.skillsTab.skillSets[build.skillsTab.activeSkillSetId].title)
		assert.equals("Imported", build.configTab.configSets[build.configTab.activeConfigSetId].title)
		assert.equals("Imported", build.controls.buildLoadouts:GetSelValue())
		assert.equals("Hierophant", build.spec.curAscendClassName)
		assert.equals("Pinnacle", build.configTab.input.enemyIsBoss)
		assert.is_true(build.modFlag)
		assert.is_not_nil(next(build.spec.subGraphs))
		for _, id in pairs(build.spec.jewels) do
			if id > 0 then
				assert.is_not_nil(build.itemsTab.items[id])
				assert.is_true(id ~= originalItem.id)
			end
		end

		-- Selecting the old loadout must restore its original equipment and skills.
		build.controls.buildLoadouts.selFunc(nil, "Original")
		runCallback("OnFrame")
		assert.equals(originalSpec, build.spec)
		assert.equals(originalItems, build.itemsTab.activeItemSet)
		assert.equals(originalSkills.socketGroupList, build.skillsTab.socketGroupList)
		assert.equals("Boss", build.configTab.input.enemyIsBoss)
	end)

	it("uses unique names and survives saving and reopening", function()
		assert.is_true(build.importTab:ImportLoadout(sourceXML, "Default"))
		assert.equals("Default (2)", build.spec.title)
		assert.is_true(build.importTab:ImportLoadout(sourceXML, "Default"))
		assert.equals("Default (3)", build.spec.title)
		local savedXML = build:SaveDB("code")
		loadBuildFromXML(savedXML)
		assert.equals(3, #build.treeTab.specList)
		assert.equals("Default (3)", build.controls.buildLoadouts:GetSelValue())
		assert.is_not_nil(next(build.spec.subGraphs))
	end)

	it("keeps loadouts that previously shared single sets selectable", function()
		build.spec.title = "Bossing"
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
		build:SyncLoadouts()
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Bossing"))
		assert.is_true(build.importTab:ImportLoadout(sourceXML, "Imported"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Bossing"))
		build.controls.buildLoadouts.selFunc(nil, "Bossing")
		assert.equals("Bossing", build.spec.title)
		assert.equals("Bossing", build.itemsTab.activeItemSet.title)
		assert.equals("Bossing", build.skillsTab.skillSets[build.skillsTab.activeSkillSetId].title)
		assert.equals("Bossing", build.configTab.configSets[build.configTab.activeConfigSetId].title)
		assert.equals("Fireball", build.skillsTab.socketGroupList[1].gemList[1].nameSpec)
	end)

	it("remaps the item sets used by minions", function()
		build.skillsTab:PasteSocketGroup("Animate Weapon 20/0  1\n")
		local minionItems = build.itemsTab:NewItemSet(5)
		minionItems.title = "Minion equipment"
		table.insert(build.itemsTab.itemSetOrderList, minionItems.id)
		local gem = build.skillsTab.socketGroupList[1].gemList[1]
		gem.skillMinionItemSet = minionItems.id
		gem.skillMinionItemSetCalcs = minionItems.id
		local xml = build:SaveDB("code")
		newBuild()
		assert.is_true(build.importTab:ImportLoadout(xml, "Minions"))
		gem = build.skillsTab.socketGroupList[1].gemList[1]
		assert.is_true(gem.skillMinionItemSet ~= 5)
		assert.equals(gem.skillMinionItemSet, gem.skillMinionItemSetCalcs)
		assert.equals("Minions - Minion equipment", build.itemsTab.itemSets[gem.skillMinionItemSet].title)
	end)

	it("imports the selected sets rather than the first sets", function()
		local itemSet = build.itemsTab:NewItemSet(5)
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		itemSet.useSecondWeaponSet = true
		build.itemsTab:SetActiveItemSet(itemSet.id)
		local skillSet = build.skillsTab:NewSkillSet(7)
		table.insert(build.skillsTab.skillSetOrderList, skillSet.id)
		build.skillsTab:SetActiveSkillSet(skillSet.id)
		build.skillsTab:PasteSocketGroup("Ice Nova 20/0  1\n")
		local configSet = build.configTab:NewConfigSet(9)
		table.insert(build.configTab.configSetOrderList, configSet.id)
		configSet.input.enemyIsBoss = "Uber"
		build.configTab:SetActiveConfigSet(configSet.id)
		local xml = build:SaveDB("code")
		newBuild()
		assert.is_true(build.importTab:ImportLoadout(xml, "Selected"))
		assert.is_true(build.itemsTab.activeItemSet.useSecondWeaponSet)
		assert.equals("Ice Nova", build.skillsTab.socketGroupList[1].gemList[1].nameSpec)
		assert.equals("Uber", build.configTab.input.enemyIsBoss)
	end)

	it("preserves loadouts linked with braces", function()
		build.spec.title = "Bossing {boss,map}"
		build:SyncLoadouts()
		assert.is_true(build.importTab:ImportLoadout(sourceXML, "Imported"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Bossing {boss}"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Bossing {map}"))
		build.controls.buildLoadouts.selFunc(nil, "Bossing {boss}")
		assert.equals("Bossing {boss,map}", build.spec.title)
		assert.equals("Bossing {boss,map}", build.itemsTab.activeItemSet.title)
	end)

	it("keeps item-granted skill settings when item IDs change", function()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: RARE\nSkill helm\nIron Hat\nImplicits: 0\nGrants Level 20 Fireball Skill\n")
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		local group = build.skillsTab.socketGroupList[1]
		assert.is_not_nil(group.source)
		group.includeInFullDPS = true
		local xml = build:SaveDB("code")
		newBuild()
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: NORMAL\nIron Hat\n")
		build.itemsTab:AddDisplayItem()
		assert.is_true(build.importTab:ImportLoadout(xml, "Granted skill"))
		runCallback("OnFrame")
		group = build.skillsTab.socketGroupList[1]
		assert.is_true(group.includeInFullDPS)
		assert.equals("Item:" .. build.itemsTab.slots.Helmet.selItemId .. ":", group.source:match("^Item:%d+:"))
	end)

	it("does not change existing imbued supports while loading new skills", function()
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nFireball 20/0  1\n")
		build.skillsTab.socketGroupList[1].imbuedSupport = "Added Cold Damage"
		local xml = build:SaveDB("code")
		newBuild()
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nIce Nova 20/0  1\n")
		local originalGroup = build.skillsTab.socketGroupList[1]
		originalGroup.imbuedSupport = "Increased Critical Strikes"
		assert.is_true(build.importTab:ImportLoadout(xml, "Imbued"))
		assert.equals("Increased Critical Strikes", originalGroup.imbuedSupport)
		assert.equals("Added Cold Damage", build.skillsTab.socketGroupList[1].imbuedSupport)
	end)

	it("creates a selectable loadout for an older tree version", function()
		build.treeTab.specList[1] = new("PassiveSpec"):PassiveSpec(build, "3_28")
		build.treeTab:SetActiveSpec(1)
		local xml = build:SaveDB("code")
		newBuild()
		assert.is_true(build.importTab:ImportLoadout(xml, "Older tree"))
		assert.equals("3_28", build.spec.treeVersion)
		assert.equals("[3.28] Older tree", build.controls.buildLoadouts:GetSelValue())
		loadBuildFromXML(build:SaveDB("code"))
		assert.equals("[3.28] Older tree", build.controls.buildLoadouts:GetSelValue())
		build.controls.buildLoadouts.selFunc(nil, "Default")
		assert.equals(latestTreeVersion, build.spec.treeVersion)
		build.controls.buildLoadouts.selFunc(nil, "[3.28] Older tree")
		assert.equals("3_28", build.spec.treeVersion)
	end)

	it("accepts legacy builds with skills and configuration outside sets", function()
		local xml = common.xml.ParseXML(sourceXML)
		for _, section in ipairs(xml[1]) do
			if type(section) == "table" then
				local setElement = ({ Skills = "SkillSet", Config = "ConfigSet", Items = "ItemSet" })[section.elem]
				if setElement then
					for index = #section, 1, -1 do
						local node = section[index]
						if type(node) == "table" and node.elem == setElement then
							table.remove(section, index)
							for _, child in ipairs(node) do
								table.insert(section, child)
							end
						end
					end
				end
			end
		end
		assert.is_true(build.importTab:ImportLoadout(common.xml.ComposeXML(xml[1]), "Legacy"))
		assert.equals("Legacy", build.controls.buildLoadouts:GetSelValue())
		assert.equals("Pinnacle", build.configTab.input.enemyIsBoss)
		assert.is_true(#build.skillsTab.socketGroupList > 0)
		assert.is_not_nil(next(build.spec.subGraphs))
	end)

	it("leaves the current build intact when the imported XML is invalid", function()
		local original = build:SaveDB("code")
		for _, invalid in ipairs({ "invalid", "<OtherGame/>", "<PathOfBuilding/>", (sourceXML:gsub('treeVersion="[^"]+"', 'treeVersion="unknown"')) }) do
			assert.is_false(build.importTab:ImportLoadout(invalid, "Invalid"))
			assert.equals(original, build:SaveDB("code"))
		end
	end)

	it("imports a code into an unsaved build through the import controls", function()
		Inflate = function() return sourceXML end
		build.importTab.controls.importCodeIn:SetText("test", true)
		assert.is_true(build.importTab.controls.importCodeMode:IsEnabled())
		build.importTab.controls.importCodeMode:SetSel(4)
		build.importTab.controls.importLoadoutName:SetText("From code")
		build.importTab.controls.importCodeGo.onClick()
		assert.equals(2, #build.treeTab.specList)
		assert.equals("From code", build.spec.title)
		assert.equals("TREE", build.viewMode)
	end)

	it("retains the selected import destination while downloading a share link", function()
		Inflate = function() return sourceXML end
		build.importTab.controls.importCodeIn:SetText("https://pobb.in/test", true)
		build.importTab.controls.importCodeMode:SetSel(4)
		build.importTab.controls.importLoadoutName:SetText("From link")
		buildSites.DownloadBuild = function(_, _, callback)
			callback(true, "test")
		end
		build.importTab.controls.importCodeGo.onClick()
		assert.equals(2, #build.treeTab.specList)
		assert.equals("From link", build.spec.title)
	end)
end)
