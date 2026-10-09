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

	describe("account-name overwrite import", function()
		local downloadPage, requests, imports, tab
		local realm = { hostName = "https://example.invalid/", realmCode = "pc" }

		before_each(function()
			tab = build.importTab
			tab.controls.siteAccountName:SetText("First#0001")
			tab.controls.siteCharSelect.list = { { char = { name = "FirstCharacter", league = "Standard" } } }
			tab.controls.siteCharSelect.selIndex = 1
			tab.lastLeague = "Standard"
			requests, imports = { }, { }
			downloadPage = launch.DownloadPage
			launch.DownloadPage = function(_, url, callback)
				table.insert(requests, { url = url, callback = callback })
			end
			tab.ImportItemsAndSkills = function(_, character)
				table.insert(imports, { "items", character.name })
			end
			tab.ImportPassiveTreeAndJewels = function(_, character)
				table.insert(imports, { "tree", character.name })
			end
		end)

		after_each(function()
			launch.DownloadPage = downloadPage
		end)

		it("keeps both requests tied to the original account and character", function()
			tab:DownloadItems(realm, true)
			tab.controls.siteAccountName:SetText("Second#0002")
			tab.controls.siteCharSelect.list = { { char = { name = "SecondCharacter", league = "Standard" } } }
			requests[1].callback({ body = '{"items":[]}' })
			assert.matches("accountName=First%%230001&character=FirstCharacter&realm=pc", requests[2].url)
			assert.same({ }, imports)
			requests[2].callback({ body = '{"items":[]}' })
			assert.same({ { "items", "FirstCharacter" }, { "tree", "FirstCharacter" } }, imports)
		end)

		for _, phase in ipairs({ "items", "tree" }) do
			it("ignores a cancelled " .. phase .. " response after reopening import", function()
				tab:DownloadItems(realm, true)
				if phase == "tree" then
					requests[1].callback({ body = '{"items":[]}' })
				end
				local pending = requests[#requests]
				tab.controls.siteCharClose.onClick()
				tab.charImportMode = "SELECTCHAR"
				tab.charImportStatus = "New character selection"
				pending.callback({ body = '{"items":[]}' })
				assert.same({ }, imports)
				assert.equal("New character selection", tab.charImportStatus)
				assert.equal(pending, requests[#requests])
			end)
		end

		it("ignores an older request without interrupting a newer import", function()
			tab:DownloadItems(realm, true)
			tab:DownloadItems(realm, true)
			requests[1].callback({ body = '{"items":[]}' })
			assert.equal(2, #requests)
			assert.equal("IMPORTING", tab.charImportMode)
			requests[2].callback({ body = '{"items":[]}' })
			requests[3].callback({ body = '{"items":[]}' })
			assert.same({ { "items", "FirstCharacter" }, { "tree", "FirstCharacter" } }, imports)
		end)

		it("leaves the build untouched if the second download fails", function()
			tab:DownloadItems(realm, true)
			requests[1].callback({ body = '{"items":[]}' })
			requests[2].callback(nil, "Download failed")
			assert.same({ }, imports)
			assert.equal("SELECTCHAR", tab.charImportMode)
			assert.matches("Download failed", tab.charImportStatus)
		end)

		it("ignores responses after switching to another build", function()
			tab:DownloadItems(realm, true)
			newBuild()
			requests[1].callback({ body = '{"items":[]}' })
			assert.same({ }, imports)
			assert.equal(1, #requests)
		end)
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
end)
