describe("Importing a build into a loadout", function()
	local sourceXML
	local sampleData
	local savedInflate, savedDownload

	local function addNamedSets(section, elementName, originalTitle, configure)
		for _, node in ipairs(section) do
			if type(node) == "table" and node.elem == elementName then
				node.attrib.title = originalTitle
				for id, title in ipairs({ "Loadout A", "Loadout B" }) do
					local loadout = copyTable(node)
					loadout.attrib.id = tostring(id + 1)
					loadout.attrib.title = title
					if configure then
						configure(loadout, title)
					end
					table.insert(section, loadout)
				end
				return
			end
		end
	end

	local function makeMultiLoadoutXML()
		local xml = common.xml.ParseXML(sourceXML)
		for _, section in ipairs(xml[1]) do
			if type(section) == "table" and section.elem == "Tree" then
				local original = section[1]
				original.attrib.title = "Unmatched"
				local loadoutA = copyTable(original)
				loadoutA.attrib.title = "Loadout A"
				local loadoutB = copyTable(original)
				loadoutB.attrib.title = "Loadout B"
				table.insert(section, loadoutA)
				table.insert(section, loadoutB)
				section.attrib.activeSpec = "3"
			elseif type(section) == "table" and section.elem == "Items" then
				addNamedSets(section, "ItemSet", "Auxiliary set")
				section.attrib.activeItemSet = "3"
			elseif type(section) == "table" and section.elem == "Skills" then
				addNamedSets(section, "SkillSet", "Unmatched")
				section.attrib.activeSkillSet = "3"
			elseif type(section) == "table" and section.elem == "Config" then
				addNamedSets(section, "ConfigSet", "Default", function(loadout, title)
					table.insert(loadout, { elem = "Input", attrib = { name = "enemyIsBoss", string = title == "Loadout A" and "Boss" or "Uber" } })
				end)
				section.attrib.activeConfigSet = "3"
			end
		end
		return common.xml.ComposeXML(xml[1])
	end

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

	it("rolls back an unexpected error while applying a loadout", function()
		local originalXML = build:SaveDB("code")
		local originalSpec = build.spec
		local originalItems = build.itemsTab.activeItemSet
		local originalSkills = build.skillsTab.skillSets[build.skillsTab.activeSkillSetId]
		local originalConfig = build.configTab.configSets[build.configTab.activeConfigSetId]
		local newSkillSet = build.skillsTab.NewSkillSet
		build.skillsTab.NewSkillSet = function()
			error("forced import failure")
		end

		local success, importError = build.importTab:ImportLoadout(sourceXML, "Rollback")
		build.skillsTab.NewSkillSet = newSkillSet

		assert.is_false(success)
		assert.is_not_nil(importError:match("unexpected error"))
		assert.equals(originalXML, build:SaveDB("code"))
		assert.equals(originalSpec, build.spec)
		assert.equals(originalItems, build.itemsTab.activeItemSet)
		assert.equals(originalSkills, build.skillsTab.skillSets[build.skillsTab.activeSkillSetId])
		assert.equals(originalConfig, build.configTab.configSets[build.configTab.activeConfigSetId])
	end)

	it("finds only complete loadouts in an imported build", function()
		local imported, loadouts, hasNamedLoadouts = build.importTab:PrepareLoadoutImport(makeMultiLoadoutXML())
		assert.is_not_nil(imported)
		assert.is_true(hasNamedLoadouts)
		assert.equals(2, #loadouts)
		assert.equals("Loadout A", loadouts[1].label)
		assert.equals("Loadout B", loadouts[2].label)
		local _, _, hasNamedLoadoutsInSingleBuild = build.importTab:PrepareLoadoutImport(sourceXML)
		assert.is_false(hasNamedLoadoutsInSingleBuild)
	end)

	it("imports only the selected loadouts", function()
		assert.is_true(build.importTab:ImportLoadouts(makeMultiLoadoutXML(), { "Loadout A" }))
		assert.equals(2, #build.treeTab.specList)
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout A"))
		assert.is_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout B"))
		assert.is_nil(isValueInArray(build.treeTab:GetSpecList(), "Unmatched"))
		assert.equals("Loadout A", build.spec.title)
		assert.equals("Boss", build.configTab.input.enemyIsBoss)
	end)

	it("imports all loadouts and resolves name clashes", function()
		build.spec.title = "Loadout A"
		build.itemsTab.activeItemSet.title = "Loadout A"
		build.skillsTab.skillSets[1].title = "Loadout A"
		build.configTab.configSets[1].title = "Loadout A"
		build:SyncLoadouts()
		assert.is_true(build.importTab:ImportLoadouts(makeMultiLoadoutXML(), { "Loadout A", "Loadout B" }))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout A"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout A (2)"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout B"))
		assert.equals("Loadout B", build.controls.buildLoadouts:GetSelValue())
		loadBuildFromXML(build:SaveDB("code"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout A (2)"))
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout B"))
	end)

	it("names auxiliary minion item sets for the loadout that uses them", function()
		local xml = common.xml.ParseXML(makeMultiLoadoutXML())
		local targetGem
		for _, section in ipairs(xml[1]) do
			if type(section) == "table" and section.elem == "Skills" then
				for _, skillSet in ipairs(section) do
					if type(skillSet) == "table" and skillSet.elem == "SkillSet" and (skillSet.attrib.title == "Loadout A" or skillSet.attrib.title == "Loadout B") then
						for _, skill in ipairs(skillSet) do
							if type(skill) == "table" and skill.elem == "Skill" then
								for _, gem in ipairs(skill) do
									if type(gem) == "table" and gem.elem == "Gem" then
										gem.attrib.skillMinionItemSet = nil
										gem.attrib.skillMinionItemSetCalcs = nil
										if skillSet.attrib.title == "Loadout B" and not targetGem then
											targetGem = gem
										end
									end
								end
							end
						end
					end
				end
			end
		end
		assert.is_not_nil(targetGem)
		targetGem.attrib.skillMinionItemSet = "1"
		targetGem.attrib.skillMinionItemSetCalcs = "1"

		assert.is_true(build.importTab:ImportLoadouts(common.xml.ComposeXML(xml[1]), { "Loadout A", "Loadout B" }))
		local titles = { }
		for _, itemSet in pairs(build.itemsTab.itemSets) do
			titles[itemSet.title or "Default"] = true
		end
		assert.is_true(titles["Loadout B - Auxiliary set"])
		assert.is_nil(titles["Loadout A - Auxiliary set"])
	end)

	it("imports a code into an unsaved build through the import controls", function()
		Inflate = function() return sourceXML end
		build.importTab.controls.importCodeIn:SetText("test", true)
		assert.is_true(build.importTab.controls.importCodeMode:IsEnabled())
		build.importTab.controls.importCodeMode:SetSel(4)
		build.importTab.controls.importCodeGo.onClick()
		assert.equals("Import Loadout", main.popups[1].title)
		main.popups[1].controls.name:SetText("From code")
		main.popups[1].controls.import.onClick()
		assert.equals(2, #build.treeTab.specList)
		assert.equals("From code", build.spec.title)
		assert.equals("TREE", build.viewMode)
	end)

	it("retains the selected import destination while downloading a share link", function()
		Inflate = function() return sourceXML end
		build.importTab.controls.importCodeIn:SetText("https://pobb.in/test", true)
		build.importTab.controls.importCodeMode:SetSel(4)
		buildSites.DownloadBuild = function(_, _, callback)
			callback(true, "test")
		end
		build.importTab.controls.importCodeGo.onClick()
		assert.equals("Import Loadout", main.popups[1].title)
		main.popups[1].controls.name:SetText("From link")
		main.popups[1].controls.import.onClick()
		assert.equals(2, #build.treeTab.specList)
		assert.equals("From link", build.spec.title)
	end)

	it("shows loadout choices for builds with multiple loadouts", function()
		Inflate = function() return makeMultiLoadoutXML() end
		build.importTab.controls.importCodeIn:SetText("test", true)
		build.importTab.controls.importCodeMode:SetSel(4)
		build.importTab.controls.importCodeGo.onClick()
		local popup = main.popups[1]
		assert.equals("Import Loadouts", popup.title)
		assert.equals("Loadout A", popup.controls.loadout1.label)
		assert.equals("Loadout B", popup.controls.loadout2.label)
		assert.is_true(popup.controls.loadout1:IsShown())
		assert.is_true(popup.controls.loadout2:IsShown())
		assert.is_true(popup.controls.loadout1.state)
		assert.is_true(popup.controls.loadout2.state)
		assert.is_false(popup.controls.loadout1:IsEnabled())
		assert.is_false(popup.controls.loadout2:IsEnabled())
		popup.controls.mode:SetSel(2)
		assert.is_true(popup.controls.loadout1:IsEnabled())
		assert.is_true(popup.controls.loadout2:IsEnabled())
		popup.controls.loadout2.state = false
		popup.controls.mode:SetSel(1)
		assert.is_true(popup.controls.loadout2.state)
		assert.is_false(popup.controls.loadout2:IsEnabled())
		popup.controls.mode:SetSel(2)
		popup.controls.loadout2.state = false
		assert.is_true(popup.controls.import:IsEnabled())
		popup.controls.import.onClick()
		assert.is_not_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout A"))
		assert.is_nil(isValueInArray(build.controls.buildLoadouts.list, "Loadout B"))
	end)

	it("warns about loadouts that will be renamed", function()
		build.spec.title = "Loadout A"
		build.itemsTab.activeItemSet.title = "Loadout A"
		build.skillsTab.skillSets[1].title = "Loadout A"
		build.configTab.configSets[1].title = "Loadout A"
		build:SyncLoadouts()
		Inflate = function() return makeMultiLoadoutXML() end
		build.importTab.controls.importCodeIn:SetText("test", true)
		build.importTab.controls.importCodeMode:SetSel(4)
		build.importTab.controls.importCodeGo.onClick()
		local popup = main.popups[1]
		assert.is_not_nil(popup.controls.warning)
		assert.equals(colorCodes.WARNING .. "One or more selected loadouts have name conflicts and will be renamed.", popup.controls.warning.label)
		local warningWidth = popup.controls.warning:GetSize()
		local popupWidth = popup:GetSize()
		assert(warningWidth <= popupWidth - 20)
		assert.equals(colorCodes.WARNING .. "Loadout A", popup.controls.loadout1.label)
		assert.equals("Loadout B", popup.controls.loadout2.label)
		popup.controls.mode:SetSel(2)
		popup.controls.loadout1.state = false
		popup.controls.loadout1.changeFunc()
		assert.is_false(popup.controls.warning:IsShown())
		assert.equals("Loadout A", popup.controls.loadout1.label)
		popup.controls.loadout1.state = true
		popup.controls.loadout1.changeFunc()
		assert.is_true(popup.controls.warning:IsShown())
		main:ClosePopup()
	end)

	it("warns when selected incoming loadouts have duplicate names", function()
		local imported = { treeTab = { specList = { { treeVersion = latestTreeVersion }, { treeVersion = latestTreeVersion } } } }
		local loadouts = {
			{ label = "Duplicate", sourceTitle = "Duplicate", treeIndex = 1 },
			{ label = "Duplicate", sourceTitle = "Duplicate", treeIndex = 2 },
		}
		local conflicts, hasConflict = build.importTab:GetLoadoutImportNameConflicts(imported, loadouts)
		assert.is_true(hasConflict)
		assert.is_false(conflicts[1])
		assert.is_true(conflicts[2])
	end)

	it("caps and scrolls the loadout popup", function()
		build.spec.title = "Loadout 1"
		local originalPrepare = build.importTab.PrepareLoadoutImport
		build.importTab.PrepareLoadoutImport = function()
			local loadouts, specs = { }, { }
			for index = 1, 40 do
				table.insert(specs, { treeVersion = latestTreeVersion })
				table.insert(loadouts, { label = "Loadout " .. index, sourceTitle = "Loadout " .. index, treeIndex = index })
			end
			return { treeTab = { specList = specs } }, loadouts, true
		end
		assert.is_true(build.importTab:OpenLoadoutImportPopup("unused"))
		build.importTab.PrepareLoadoutImport = originalPrepare
		local popup = main.popups[1]
		local width, height = popup:GetSize()
		assert(width <= 500)
		assert(height <= 376)
		assert.is_not_nil(popup.controls.warning)
		assert.is_true(popup.controls.scrollBar.enabled)
		assert.is_true(popup.controls.loadout1:IsShown())
		assert.is_false(popup.controls.loadout40:IsShown())
		assert.is_true(popup.controls.loadout40.state)
		assert.is_false(popup.controls.loadout40:IsEnabled())
		popup.controls.scrollBar:SetOffset(popup.controls.scrollBar.offsetMax)
		assert.is_false(popup.controls.loadout1:IsShown())
		assert.is_true(popup.controls.loadout40:IsShown())
		main:ClosePopup()
	end)
end)
