describe("Mercenary equipment import workflows", function()
	local json = require("dkjson")
	local originalAPI, originalDownload
	local originalRealm, originalLeague, originalCharacter
	local character, roster, requests, leagueResponse, mercenaryAccess

	local function equipment(base, slot, id)
		return { id = string.rep(id, 64), frameType = 0, name = "", typeLine = base,
			inventoryId = slot, ilvl = 70, properties = { }, explicitMods = { } }
	end

	local function respond(callback, body)
		callback({ body = json.encode(body), header = "HTTP/1.1 200 OK\r\n" })
	end

	local function download(_, url, callback)
		local suffix = character.realm == "pc" and "" or "/" .. character.realm
		local path = url:gsub("^https://api%.pathofexile%.com", "")
		table.insert(requests, path)
		if path == "/character" .. suffix then
			local listed = copyTable(character)
			listed.equipment = nil
			respond(callback, { characters = { listed } })
		elseif path == "/character" .. suffix .. "/" .. character.name then
			respond(callback, { character = character })
		elseif path == "/league-account" .. suffix .. "/" .. urlEncode(character.league) then
			if not mercenaryAccess then
				callback(nil, "Response code: 403")
			elseif leagueResponse then
				leagueResponse(callback)
			else
				respond(callback, { league_account = { mercenaries = roster } })
			end
		else
			error("Unexpected API request: " .. url)
		end
	end

	local function fetchMercenaries()
		build.importTab.controls.charImportMercenaryEquipment:Click()
		local popup = assert(main.popups[1], "The Mercenary selection dialog did not open")
		assert.equals("Import Mercenary Equipment", popup.title)
		return popup.controls
	end

	local function existingSet()
		local items = build.itemsTab
		local set = items:NewItemSet()
		set.title = "Mercenary equipment"
		table.insert(items.itemSetOrderList, set.id)
		items:AddUndoState()
		return set
	end

	before_each(function()
		originalAPI, originalDownload = main.api, launch.DownloadPage
		originalRealm, originalLeague, originalCharacter = main.lastRealm, main.lastLeague, main.lastCharacterHash
		main.lastRealm, main.lastLeague, main.lastCharacterHash = "PC", nil, nil
		newBuild()
		while main.popups[1] do main:ClosePopup() end

		local helmet = equipment("Iron Hat", "Helm", "a")
		helmet.sockets = { { group = 0, sColour = "B" } }
		helmet.socketedItems = { { typeLine = "Fireball", socket = 0, support = false,
			properties = { { name = "Level", values = { { "20", 0 } } } } } }
		character = { id = string.rep("b", 64), name = "Player", realm = "pc", class = "Witch",
			league = "Standard", level = 80, active_mercenary_index = 1, equipment = { helmet } }
		roster = {
			{ index = 0, name = "Ruktara, the Bullseye", level = 80, items = { equipment("Leather Cap", "Helm", "c") } },
			{ index = 1, name = "Vorneka Azrus", level = 82, items = { equipment("Cone Helmet", "Helm", "d") } },
		}
		build.importTab:ImportItemsAndSkills(character, true, true, false)
	end)

	after_each(function()
		main.api, launch.DownloadPage = originalAPI, originalDownload
		main.lastRealm, main.lastLeague, main.lastCharacterHash = originalRealm, originalLeague, originalCharacter
		while main.popups[1] do main:ClosePopup() end
		build.abortSave = true
		assert.is_nil(launch.promptMsg)
	end)

	it("replaces the active set without importing socketed gem skills", function()
		local items = build.itemsTab
		local skills = build.skillsTab:CreateUndoState()
		items.activeItemSet.useSecondWeaponSet = true
		local helm = roster[2].items[1]
		helm.sockets = { { group = 0, sColour = "B" } }
		helm.socketedItems = { { typeLine = "Arc", socket = 0, support = false, properties = { } } }
		build.importTab:ImportMercenaryEquipment(roster[2], items.activeItemSetId)
		assert.equals(helm.id, items.items[items.slots.Helmet.selItemId].uniqueID)
		assert.equals(items.slots.Helmet.selItemId, items.activeItemSet.Helmet.selItemId)
		assert.is_false(items.activeItemSet.useSecondWeaponSet)
		assert.same(skills, build.skillsTab:CreateUndoState())
	end)

	it("imports a Stygian Vise and its socketed Abyss jewel into the chosen set", function()
		local set = existingSet()
		local belt = equipment("Stygian Vise", "Belt", "e")
		belt.implicitMods = { "Has 1 Abyssal Socket" }
		belt.sockets = { { group = 0, sColour = "A" } }
		local jewel = equipment("Murderous Eye Jewel", nil, "f")
		jewel.abyssJewel = true
		belt.socketedItems = { jewel }
		table.insert(roster[2].items, belt)
		build.importTab:ImportMercenaryEquipment(roster[2], set.id)
		local items = build.itemsTab
		assert.equals(belt.id, items.items[set.Belt.selItemId].uniqueID)
		assert.equals(jewel.id, items.items[set["Belt Abyssal Socket 1"].selItemId].uniqueID)
		assert.equals(0, items.activeItemSet.Belt.selItemId)
		assert.equals(0, items.activeItemSet["Belt Abyssal Socket 1"].selItemId)
	end)

	describe("API and UI", function()
		before_each(function()
			build.controls.modeImport:Click()
			main.api = new("PoEAPI"):PoEAPI("fixture-token", "fixture-refresh", os.time() + 3600)
			main.api.UpdateMain = function() end
			requests, leagueResponse, mercenaryAccess = { }, nil, true
			launch.DownloadPage = download
			build.importTab.controls.accountRealmFetchButton:Click()
		end)

		it("imports the selected Mercenary into a new set while retaining the player's build", function()
			local items = build.itemsTab
			local playerSet, playerHelmet = items.activeItemSetId, items.slots.Helmet.selItemId
			local skills = build.skillsTab:CreateUndoState()
			local controls = fetchMercenaries()
			assert.equals("Vorneka Azrus (Active)", controls.hire:GetSelValue().label)
			controls.hire:SetSel(1)
			assert.equals("Ruktara, the Bullseye", controls.hire:GetSelValue().label)
			assert.equals(0, controls.destination:GetSelValue().id)
			controls.import:Click()

			local imported = items.itemSets[items.itemSetOrderList[#items.itemSetOrderList]]
			assert.equals("Ruktara, the Bullseye (Mercenary)", imported.title)
			assert.equals(roster[1].items[1].id, items.items[imported.Helmet.selItemId].uniqueID)
			assert.equals(playerSet, items.activeItemSetId)
			assert.equals(playerHelmet, items.slots.Helmet.selItemId)
			assert.equals(80, build.characterLevel)
			assert.same(skills, build.skillsTab:CreateUndoState())
			assert.is_nil(main.popups[1])
			local tab = build.importTab
			local expected = { "PC", "Standard", common.sha1("Player") }
			assert.same(expected, { main.lastRealm, main.lastLeague, main.lastCharacterHash })
			assert.same(expected, { tab.lastRealm, tab.lastLeague, tab.lastCharacterHash })
		end)

		it("reimports changed equipment into the chosen existing set without duplicates", function()
			local items, set = build.itemsTab, existingSet()
			local playerHelmet = items.slots.Helmet.selItemId
			table.insert(roster[2].items, equipment("Iron Greaves", "Boots", "e"))
			local controls = fetchMercenaries()
			controls.destination:SelByValue(set.id, "id")
			controls.import:Click()
			local helmetId, count = set.Helmet.selItemId, #items.itemOrderList
			assert.is_true(set.Boots.selItemId > 0)
			roster[2].items[1].properties = { { name = "Quality", values = { { "+20%", 1 } } } }
			table.remove(roster[2].items, 2)

			controls = fetchMercenaries()
			controls.destination:SelByValue(set.id, "id")
			controls.import:Click()
			assert.equals(helmetId, set.Helmet.selItemId)
			assert.equals(20, items.items[helmetId].quality)
			assert.equals(count, #items.itemOrderList)
			assert.equals(0, set.Boots.selItemId)
			assert.equals(playerHelmet, items.slots.Helmet.selItemId)
			items:Undo()
			assert.equals(0, items.items[helmetId].quality)
			assert.is_true(items.itemSets[set.id].Boots.selItemId > 0)
			items:Undo()
			assert.equals(0, items.itemSets[set.id].Helmet.selItemId)
			assert.equals(0, items.itemSets[set.id].Boots.selItemId)
		end)

		for _, action in ipairs({ "cancel", "logout" }) do
			it("ignores an arriving roster after the user clicks " .. action, function()
				local pending
				leagueResponse = function(callback) pending = callback end
				local tab, before = build.importTab, build.itemsTab:CreateUndoState()
				tab.controls.charImportMercenaryEquipment:Click()
				assert.is_function(pending)
				if action == "cancel" then tab.controls.cancelMercenaryImport:Click()
				else tab.controls.logoutApiButton:Click() end
				respond(pending, { league_account = { mercenaries = roster } })
				assert.is_nil(main.popups[1])
				assert.is_false(tab.oauthLoading)
				assert.same(before, build.itemsTab:CreateUndoState())
			end)
		end

		it("reports a league with no hired Mercenaries without changing equipment", function()
			roster = { }
			local before = build.itemsTab:CreateUndoState()
			build.importTab.controls.charImportMercenaryEquipment:Click()
			assert.matches("No Mercenaries", build.importTab.oauthErrCode)
			assert.is_nil(main.popups[1])
			assert.same(before, build.itemsTab:CreateUndoState())
		end)

		it("disables further import requests while the API rate limit is active", function()
			local before = build.itemsTab:CreateUndoState()
			leagueResponse = function(callback)
				callback({ header = "HTTP/1.1 429 Too Many Requests\r\nX-Rate-Limit-Policy: league-account-request-limit\r\nRetry-After: 30\r\n" }, "Response code: 429")
			end
			local button = build.importTab.controls.charImportMercenaryEquipment
			button:Click()
			assert.is_true(build.importTab.rateLimitEndTime >= os.time() + 29)
			local count = #requests
			assert.is_false(button:IsEnabled())
			button:Click()
			assert.equals(count, #requests)
			assert.same(before, build.itemsTab:CreateUndoState())
		end)

		for _, realm in ipairs({ { "XBOX", "xbox" }, { "SONY", "sony" } }) do
			it("fetches and imports a Mercenary from the " .. realm[1] .. " realm", function()
				character.realm = realm[2]
				character.name = "ConsolePlayer"
				character.league = "Hardcore"
				build.importTab.controls.accountRealm:SelByValue(realm[1], "id")
				build.importTab.controls.accountRealmFetchButton:Click()
				fetchMercenaries().import:Click()
				assert.equals("/league-account/" .. realm[2] .. "/Hardcore", requests[#requests])
				local items = build.itemsTab
				local set = items.itemSets[items.itemSetOrderList[#items.itemSetOrderList]]
				assert.equals(roster[2].items[1].id, items.items[set.Helmet.selItemId].uniqueID)
			end)
		end
	end)
end)
