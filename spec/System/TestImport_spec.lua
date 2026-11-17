describe("TestImport", function()
	local dkjson = require "dkjson"

	local sampleJson, err = io.open("../spec/System/SampleCharacter.json", "r")
	if err then
		ConPrintf("Failed to read sample character response: %s", err)
	end
	local sampleData = dkjson.decode(sampleJson:read("*a")).character
	sampleJson:close()

	before_each(function()
		newBuild()
	end)

	it("imports with correct tree", function()
		build.importTab:ImportPassiveTreeAndJewels(sampleData, true)
		runCallback("OnFrame")

		assert.equals(build.configTab.input.bandit, "None")
		assert.equals(build.configTab.input.pantheonMajorGod, "TheBrineKing")
		assert.equals(build.configTab.input.pantheonMinorGod, "Yugul")
		assert.equals(build.characterLevel, 99)
		-- iron will and CI
		assert.equals(build.spec.allocatedKeystoneCount, 2)
		assert.equals(build.spec.curAscendClassName, "Hierophant")
		assert.equals(build.spec.curClassName, "Templar")
		assert.equals(build.spec.curSecondaryAscendClassName, "Farrul Bloodline")

		-- note: currently only one large cluster and medium is imported on the
		-- tree. build actually has a small cluster on the medium cluster
		local subGraphLen = 0
		for _ in pairs(build.spec.subGraphs) do
			subGraphLen = subGraphLen + 1
		end
		
		assert.equals(subGraphLen, 2)
		assert.equals(build.spec.allocatedMasteryCount, 7)
		assert.equals(build.spec.masterySelections[4492], 5356)

		assert.equals(build.spec.allocatedTattooTypes.NgamahuTattoo, 6)

		assert.equals(build.spec.allocatedNotableCount, 29)
	end)

	it("preserves quest choices only for account-name imports", function()
		build.configTab.varControls.bandit:SetSel(2)
		build.configTab.varControls.pantheonMajorGod:SetSel(4)
		build.configTab.varControls.pantheonMinorGod:SetSel(9)

		local importData = copyTable(sampleData)
		importData.passives.bandit_choice = nil
		importData.passives.pantheon_major = nil
		importData.passives.pantheon_minor = nil
		build.importTab.controls.siteAccountName.buf = "Test#0000"
		build.importTab.controls.siteCharSelect.list = { { char = importData } }
		build.importTab.controls.siteCharSelect.selIndex = 1
		build.importTab.lastLeague = importData.league

		local downloadPage = launch.DownloadPage
		launch.DownloadPage = function(_, _, callback)
			callback({ body = dkjson.encode(importData.passives) })
		end
		build.importTab:DownloadPassiveTree({ hostName = "", realmCode = "pc" })
		launch.DownloadPage = downloadPage
		runCallback("OnFrame")

		assert.equals(build.configTab.input.bandit, "Oak")
		assert.equals(build.configTab.input.pantheonMajorGod, "Solaris")
		assert.equals(build.configTab.input.pantheonMinorGod, "Shakari")

		build.importTab:ImportPassiveTreeAndJewels(importData, true)
		runCallback("OnFrame")

		assert.equals(build.configTab.input.bandit, "None")
		assert.equals(build.configTab.input.pantheonMajorGod, "None")
		assert.equals(build.configTab.input.pantheonMinorGod, "None")
	end)

	it("imports with correct jewels", function()
		build.importTab:ImportPassiveTreeAndJewels(sampleData, true)
		runCallback("OnFrame")

		local jewelCount = 0
		for _ in pairs(build.spec.jewel_data) do
			jewelCount = jewelCount + 1
		end
		assert.equals(jewelCount, 11)
		assert.equals(build.spec.jewel_data[3].radius, 2400)
		assert.equals(build.spec.jewel_data[3].type, "JewelStr")

		local items = build.itemsTab.items
		assert.truthy(items)
		assert.equals(#items, 11)

		function isEquipped(slot, itemName)
			assert.truthy(items[slot])
			assert.equals(items[slot].name, itemName)
			local found = false
			for k, itemId in pairs(build.spec.jewels) do
				if itemId == items[slot].id then
					found = true
				end
			end
			assert.truthy(found)
		end
		isEquipped(3, "Healthy Mind, Cobalt Jewel")
		isEquipped(4, "Fulgent Bliss, Small Cluster Jewel")
	end)

	it("imports modifier flags from the 3.29 item API", function()
		build.importTab:ImportItem({
			id = "test-item-mod-flags",
			frameType = 2,
			name = "Test Grip",
			typeLine = "Rawhide Gloves",
			inventoryId = "Gloves",
			ilvl = 10,
			duplicated = true,
			vestigial = true,
			properties = { },
			implicitMods = {
				{ description = "+20 to maximum Life" },
			},
			explicitMods = {
				{ description = "+10 to maximum Life", flags = { crafted = true } },
				{ description = "+11 to maximum Mana", flags = { fractured = true } },
				{ description = "+12 to Strength", flags = { mutated = true } },
				{ description = "+13 to Dexterity", flags = { vestigial = true } },
			},
		})

		local itemId = build.itemsTab.slots.Gloves.selItemId
		local item = build.itemsTab.items[itemId]
		local explicitMods = { }
		for _, modLine in ipairs(item.explicitModLines) do
			explicitMods[modLine.line] = modLine
		end

		assert.are.equal("+20 to maximum Life", item.implicitModLines[1].line)
		assert.is_true(explicitMods["+10 to maximum Life"].crafted)
		assert.is_true(explicitMods["+11 to maximum Mana"].fractured)
		assert.is_true(explicitMods["+12 to Strength"].mutated)
		assert.is_true(item.mirrored)
		assert.is_true(item.vestigial)
		assert.is_true(explicitMods["+13 to Dexterity"].vestigial)
		assert.is_truthy(item:BuildRaw():find("{vestigial}", 1, true))
	end)

	function importAndReimportWithOldJewel(shouldDelete)
		local oldJewel = new("Item"):Item([[Rarity: RARE
TEST JEWEL
Crimson Jewel
Crafted: true
Prefix: None
Prefix: None
Suffix: None
Suffix: None
Implicits: 0]])

		build.importTab:ImportPassiveTreeAndJewels(sampleData, true)

		for k,v in pairs(build.itemsTab.sockets) do
			if v.label == "Socket #1" then
				v:SetSelItemId(0)
			end
		end
		

		build.itemsTab:AddItem(oldJewel, false)


		-- replace first found jewel
		for _, slot in pairs(build.itemsTab.slots) do
			if slot.selItemId ~= 0 and slot.nodeId then
				slot:SetSelItemId(oldJewel.id)
				break
			end
		end

		build.importTab:ImportPassiveTreeAndJewels(sampleData, shouldDelete)
		runCallback("OnFrame")
		return oldJewel
	end

	it("deletes old jewels", function()
		local oldJewel = importAndReimportWithOldJewel(true)

		for _, v in pairs(build.itemsTab.items) do
			assert.falsy(v.name == oldJewel.name)
		end
	end)

	it("doesn't delete old jewels", function()
		local oldJewel = importAndReimportWithOldJewel(false)
		local found = false
		for _, v in pairs(build.itemsTab.items) do
			if v.name == oldJewel.name then
				found = true
			end
		end
		assert.truthy(found)
	end)

	for _, target in ipairs({ { "NOTES", "notesTab", "edit" }, { "PARTY", "partyTab", "editAuras" } }) do
		it("keeps " .. target[1] .. " changes unsaved after exporting a build", function()
			build:ResetModFlags()
			local tab = build[target[2]]
			tab.controls[target[3]]:SetText("Unsaved text")
			build.viewMode = target[1]
			runCallback("OnFrame")
			assert.is_true(build.unsaved)
			local xml = build:SaveDB("code")
			assert.is_truthy(xml:find("Unsaved text", 1, true))
			runCallback("OnFrame")
			assert.is_true(build.unsaved)
			assert.is_true(tab.modFlag)

			local openFile = io.open
			local written
			io.open = function()
				return { write = function(_, text) written = text; return true end, close = function() return true end }
			end
			build.dbFileName = "test.xml"
			local ok, err = pcall(build.SaveDBFile, build)
			io.open = openFile
			build.dbFileName = nil
			assert.is_true(ok, err)
			assert.is_truthy(written:find("Unsaved text", 1, true))
			runCallback("OnFrame")
			assert.is_false(build.unsaved)
			assert.is_false(tab.modFlag)
		end)
	end

	it("keeps Wickerman items separate through import and save/load", function()
		-- Live OAuth structure and Lesser names; IDs and boundary-case rolls are synthetic.
		local examples = {
			{ "Ravenous Skull", "Ravenous Skull", "Head", "Every 3 seconds, Consume a Corpse within 5 metres to Recover 4% of Life" },
			{ "Lesser Warden's Arm", "Warden's Arm", "Arm", "+43 to maximum Life" },
			{ "Greater Sirus' Head", "Sirus' Head", "Head", "+10 to Strength" },
			{ "Lesser Blackened Lungs", "Blackened Lungs", "Body", "12% increased Warcry Speed", "VisceraBody" },
			{ "Lesser Pocked Leg", "Pocked Leg", "Leg", "20% increased Armour from Equipped Helmet and Gloves", "VisceraLeg" },
			{ "Artificial Appendage", "Artificial Appendage", "Arm", "25% increased Effect of Chill" },
			{ "Artificial Appendage", "Artificial Appendage", "Arm", "18% increased Area of Effect for Attacks" },
			{ "Artificial Appendage", "Artificial Appendage", "Arm", "Minions have 30% increased Critical Strike Chance" },
		}
		local equipped, items = { }, { }
		for i, example in ipairs(examples) do
			local slot = example[2]
			local item = { id = "synthetic-wickerman-" .. i, name = "", typeLine = example[1], baseType = example[1], frameType = 15, ilvl = 83,
				inventoryId = example[5] or (example[2] == "Head" and "VisceraHead" or "VisceraArm"), implicitMods = { { description = example[4] } } }
			table.insert(items, item)
			equipped[slot] = item.id
		end
		local character = { level = 80, equipment = { }, wickerman = items }
		build.importTab:ImportItemsAndSkills(character, true, false)
		build.importTab:ImportItemsAndSkills(character, false, false) -- Replace only matching IDs.
		loadBuildFromXML(build:SaveDB("code"))
		assert.equals(#examples, #build.itemsTab.itemOrderList)
		for i, example in ipairs(examples) do
			local item = build.itemsTab.items[build.itemsTab.itemOrderList[i]]
			assert.equals("synthetic-wickerman-" .. i, item.uniqueID)
			assert.equals(example[2], item.baseName)
			assert.equals("NORMAL", item.rarity)
			assert.equals("Viscera", item.type)
			assert.equals(example[4], item.implicitModLines[1].line)
		end
  end)
	local function characterWithImbuedSupport(name)
		local character = copyTable(sampleData, true)
		for _, item in ipairs(character.equipment) do
			if item.inventoryId == "BodyArmour" then
				local gem = item.socketedItems[1]
				gem.builtInSupport = "Supported by Level 1 " .. name
				return character, gem
			end
		end
		error("Sample character has no body armour")
	end

	local function bodyArmourGroup()
		for index, group in ipairs(build.skillsTab.socketGroupList) do
			if group.slot == "Body Armour" then
				return group, index
			end
		end
		error("Imported character has no body armour skill group")
	end

	for _, example in ipairs({
		{ "Added Fire Damage", "Added Fire Damage", true },
		{ "Added Fire Damage Support", "Added Fire Damage", true },
		{ "Barrage Support", "Barrage Support", true },
		{ "[SupportVolatility|Volatility]", "Volatility", true },
		{ "Unknown Example", "Unknown Example", false },
	}) do
		it("imports and reloads an imbued support: " .. example[1], function()
			local character = characterWithImbuedSupport(example[1])
			build.importTab:ImportItemsAndSkills(character, true, true)
			local function checkGroup()
				local group = bodyArmourGroup()
				assert.equals(example[2], group.imbuedSupport)
				build.skillsTab:SetDisplayGroup(group)
				assert.equals(example[3], build.skillsTab.imbuedSupportBySlot[group.slot] ~= nil)
			end
			checkGroup()
			loadBuildFromXML(build:SaveDB("code"))
			checkGroup()
		end)
	end

	it("repairs saved imbued support markup and applies the support", function()
		local character = characterWithImbuedSupport("[SupportVolatility|Volatility]")
		build.importTab:ImportItemsAndSkills(character, true, true)
		local xml = build:SaveDB("code")
		xml = xml:gsub('imbuedSupport="[^"]+"', 'imbuedSupport="[SupportVolatility|Volatility]"', 1)
		loadBuildFromXML(xml)
		local group, groupIndex = bodyArmourGroup()
		assert.equals("Volatility", group.imbuedSupport)
		build.mainSocketGroup = groupIndex
		build.buildFlag = true
		runCallback("OnFrame")
		local found
		for _, support in ipairs(build.calcsTab.mainEnv.player.mainSkill.supportList) do
			if support.grantedEffect.id == "SupportVolatility" then
				found = support
				break
			end
		end
		assert.is_not_nil(found)
		assert.equals(1, found.level)
	end)

	it("updates imbued support when reimporting an existing skill group", function()
		local character, socketedGem = characterWithImbuedSupport("Added Fire Damage")
		build.importTab:ImportItemsAndSkills(character, true, true)
		local group = bodyArmourGroup()
		build.skillsTab:SetDisplayGroup(group)
		socketedGem.builtInSupport = "Supported by Level 1 [UnknownSupport|Unknown Example]"
		build.importTab:ImportItemsAndSkills(character, false, false)
		assert.equals("Unknown Example", group.imbuedSupport)
		assert.equals("Unknown Example", build.skillsTab.controls.imbuedSupport.buf)
		assert.is_nil(build.skillsTab.imbuedSupportBySlot[group.slot])
		build.skillsTab:SetDisplayGroup(nil)
		socketedGem.builtInSupport = "Supported by Level 1 [SupportVolatility|Volatility]"
		build.importTab:ImportItemsAndSkills(character, false, false)
		assert.equals("Volatility", group.imbuedSupport)
		assert.equals("SupportVolatility", build.skillsTab.imbuedSupportBySlot[group.slot].id)
		build.skillsTab:SetDisplayGroup(group)
		assert.equals("Volatility", build.skillsTab.controls.imbuedSupport.buf)

		group.slot, group.imbuedSupport = nil, nil
		build.skillsTab:SetDisplayGroup(nil)
		build.importTab:ImportItemsAndSkills(character, false, false)
		assert.is_nil(group.slot)
		assert.is_nil(group.imbuedSupport)
	end)

end)
