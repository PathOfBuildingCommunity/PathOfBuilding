local McpProtocol = LoadModule("Modules/McpProtocol")

local PORT = 49290
local TOKEN = "0123456789abcdef0123456789abcdef"

local protocol

local function request(method, params, opts)
	opts = opts or { }
	local message = { jsonrpc = "2.0", id = opts.id == nil and 1 or opts.id, method = method, params = params }
	local headers = {
		host = "127.0.0.1:" .. PORT,
		authorization = "Bearer " .. TOKEN,
		["content-type"] = "application/json",
	}
	local response
	protocol:HandleHttp({
		method = "POST",
		path = "/mcp",
		version = "1.1",
		headers = headers,
		body = McpProtocol.Encode(message),
	}, function(r)
		response = r
	end)
	assert.is_truthy(response, "no response")
	local body = response.body ~= "" and McpProtocol.Decode(response.body) or nil
	return response.status, body, response
end

local function callTool(name, args, allowError)
	local status, body = request("tools/call", { name = name, arguments = args or McpProtocol.Object() })
	assert.are.equals(200, status)
	assert.is_nil(body.error)
	if body.result.isError and not allowError then
		error(name .. " failed: " .. tostring(body.result.content[1].text), 2)
	end
	return body.result.structuredContent, body.result
end

local function toolError(name, args)
	local _, result = callTool(name, args, true)
	assert.is_true(result.isError, "expected an error from " .. name)
	return result.content[1].text
end

local HELMET = "Rarity: RARE\nTest Hat\nIron Hat\nQuality: 0\n+80 to maximum Life\n+40% to Fire Resistance\n"
local GLOVES = "Rarity: RARE\nTest Mitts\nRawhide Gloves\nQuality: 0\n+30 to maximum Life\n"
local FLASK = "Rarity: MAGIC\nSeething Divine Life Flask of Staunching\n"

local function addItem(text)
	build.itemsTab:CreateDisplayItemFromRaw(text, true)
	build.itemsTab:AddDisplayItem()
	runCallback("OnFrame")
end

local function entryFor(list, slotName)
	for _, entry in ipairs(list) do
		if entry.slot == slotName then
			return entry
		end
	end
end

describe("MCP items tools", function()
	before_each(function()
		main.mcpServer.token = TOKEN
		protocol = main.mcpServer:NewProtocol(PORT)
		-- A build an earlier spec changed would be autosaved by Dev Mode when replaced; there is nowhere to save it here.
		build.abortSave = true
		while main.popups[1] do
			main:ClosePopup()
		end
		newBuild()
	end)

	after_each(function()
		-- Dev Mode saves a changed build when the next test replaces it; there is nowhere to save it here.
		build.abortSave = true
		-- No test may leave one of PoB's dialogs open.
		local popup = main.popups[1]
		while main.popups[1] do
			main:ClosePopup()
		end
		assert.is_nil(popup, popup and ("dialog left open: " .. tostring(popup.title)))
	end)

	describe("items_get", function()
		it("reports the equipped items as the Items tab holds them, and changes nothing", function()
			addItem(HELMET)
			addItem(FLASK)
			build:ResetModFlags()
			local itemsTab = build.itemsTab
			local result = callTool("items_get")
			local helmet = entryFor(result.equipped, "Helmet")
			assert.are.equals(itemsTab.items[itemsTab.slots["Helmet"].selItemId].name, helmet.name)
			assert.are.equals(itemsTab.slots["Helmet"].selItemId, helmet.id)
			assert.is_truthy(table.concat(helmet.mods, "\n"):find("+80 to maximum Life", 1, true))
			local flask = entryFor(result.equipped, "Flask 1")
			assert.are.equals(itemsTab.slots["Flask 1"].active and true or false, flask.active)
			assert.is_truthy(isValueInArray(result.emptySlots, "Gloves"))
			assert.are.equals(1, #result.itemSets)
			assert.is_true(result.itemSets[1].active)
			assert.are.equals(0, result.otherItemsPage.total)

			local detail = callTool("items_get", { detail = true, slot = "Helmet" })
			assert.are.equals(itemsTab.items[itemsTab.slots["Helmet"].selItemId]:BuildRaw(), detail.equipped[1].text)
			assert.is_false(build:HasUnsavedChanges())
		end)
	end)

	describe("items_equip", function()
		it("equips pasted item text exactly as simulate predicted", function()
			local simulated = callTool("simulate", { slot = "Helmet", item = HELMET, fields = { "Life", "FireResist" } })
			local equipped = callTool("items_equip", { action = "equip", slot = "Helmet", item = HELMET })
			assert.are.equals("Helmet", equipped.equippedIn)
			assert.is_true(equipped.added)
			assert.is_truthy(#equipped.statChanges > 0)
			assert.are.equals(simulated.values.Life.after, build.calcsTab.mainOutput.Life)
			assert.are.equals(simulated.values.FireResist.after, build.calcsTab.mainOutput.FireResist)
			assert.is_true(build:HasUnsavedChanges())
			local shown = callTool("items_get", { slot = "Helmet" })
			assert.are.equals("Test Hat, Iron Hat", shown.equipped[1].name)
		end)

		it("replaces, unequips, re-equips and removes items", function()
			callTool("items_equip", { action = "equip", slot = "Gloves", item = GLOVES })
			local itemsTab = build.itemsTab
			local id = itemsTab.slots["Gloves"].selItemId
			local lifeWith = build.calcsTab.mainOutput.Life
			local unequipped = callTool("items_equip", { action = "unequip", slot = "Gloves" })
			assert.are.equals("Test Mitts, Rawhide Gloves", unequipped.unequipped)
			assert.are.equals(0, itemsTab.slots["Gloves"].selItemId)
			assert.is_truthy(itemsTab.items[id])
			assert.is_true(build.calcsTab.mainOutput.Life < lifeWith)
			local others = callTool("items_get")
			assert.are.equals(1, others.otherItemsPage.total)
			assert.are.equals(id, others.otherItems[1].id)

			-- By name, into its usual slot, as Ctrl+click does.
			local again = callTool("items_equip", { action = "equip", item_ref = "Test Mitts" })
			assert.are.equals("Gloves", again.equippedIn)
			assert.are.equals(id, itemsTab.slots["Gloves"].selItemId)
			assert.are.equals(lifeWith, build.calcsTab.mainOutput.Life)

			local message = toolError("items_equip", { action = "equip", slot = "Helmet", item_ref = id })
			assert.is_truthy(message:find("cannot be equipped in Helmet", 1, true))

			local removed = callTool("items_equip", { action = "remove", item_ref = id })
			assert.are.equals("Gloves", removed.wasEquippedIn)
			assert.is_nil(itemsTab.items[id])
			assert.are.equals(0, itemsTab.slots["Gloves"].selItemId)
		end)

		it("switches a flask on and off like its check box", function()
			callTool("items_equip", { action = "equip", slot = "Flask 1", item = FLASK })
			local itemsTab = build.itemsTab
			local flask = itemsTab.items[itemsTab.slots["Flask 1"].selItemId]
			callTool("items_equip", { action = "set_active", slot = "Flask 1", active = false })
			assert.is_falsy(build.calcsTab.mainEnv.flasks[flask])
			local on = callTool("items_equip", { action = "set_active", slot = "Flask 1", active = true })
			assert.is_true(on.active)
			assert.is_true(itemsTab.slots["Flask 1"].controls.activate.state)
			assert.is_truthy(build.calcsTab.mainEnv.flasks[flask])
			callTool("items_equip", { action = "set_active", slot = "Flask 1", active = false })
			assert.is_falsy(build.calcsTab.mainEnv.flasks[flask])
		end)
	end)

	describe("items_sets", function()
		it("creates, renames, selects and deletes item sets", function()
			local itemsTab = build.itemsTab
			callTool("items_equip", { action = "equip", slot = "Helmet", item = HELMET })
			local created = callTool("items_sets", { action = "new", title = "Bossing" })
			assert.are.equals(2, #created.itemSets)
			assert.are.equals("Bossing", created.itemSets[2].title)
			callTool("items_sets", { action = "rename", set = "Bossing", title = "Mapping" })
			assert.are.equals("Mapping", itemsTab.itemSets[itemsTab.itemSetOrderList[2]].title)
			local copied = callTool("items_sets", { action = "copy", set = 1, title = "Copy" })
			assert.are.equals(3, #copied.itemSets)
			assert.are.equals(itemsTab.slots["Helmet"].selItemId, itemsTab.itemSets[itemsTab.itemSetOrderList[3]]["Helmet"].selItemId)

			local selected = callTool("items_sets", { action = "select", set = "Mapping" })
			assert.is_true(selected.itemSets[2].active)
			assert.are.equals(itemsTab.itemSetOrderList[2], itemsTab.activeItemSetId)
			-- The new set is empty.
			assert.are.equals(0, itemsTab.slots["Helmet"].selItemId)

			local deleted = callTool("items_sets", { action = "delete", set = "Mapping" })
			assert.are.equals("Mapping", deleted.deleted)
			assert.are.equals(2, #itemsTab.itemSetOrderList)
			assert.are.equals(itemsTab.itemSetOrderList[1], itemsTab.activeItemSetId)
			assert.is_truthy(itemsTab.slots["Helmet"].selItemId > 0)
			local message = toolError("items_sets", { action = "new" })
			assert.is_truthy(message:find("title is required", 1, true))
		end)
	end)

	describe("items_db_search", function()
		it("finds uniques once the databases are loaded", function()
			local frames = 0
			while (main.uniqueDB.loading or main.rareDB.loading) and frames < 1000 do
				runCallback("OnFrame")
				frames = frames + 1
			end
			assert.is_nil(main.uniqueDB.loading)
			local result = callTool("items_db_search", { search = "Tabula Rasa", include_text = true })
			assert.are.equals("Tabula Rasa, Simple Robe", result.items[1].name)
			assert.is_truthy(result.items[1].text:find("Tabula Rasa", 1, true))
			local item = new("Item"):Item(result.items[1].text)
			assert.are.equals("Simple Robe", item.baseName)

			local helmets = callTool("items_db_search", { slot = "Helmet", limit = 5, list_filters = true })
			assert.are.equals(5, #helmets.items)
			assert.is_truthy(helmets.page.total > 5)
			for _, entry in ipairs(helmets.items) do
				assert.are.equals("Helmet", entry.type)
			end
			assert.is_truthy(isValueInArray(helmets.filters.slot, "Helmet"))

			local rares = callTool("items_db_search", { db = "rare", slot = "Ring", limit = 3 })
			assert.is_truthy(#rares.items > 0)
			local message = toolError("items_db_search", { slot = "Nowhere" })
			assert.is_truthy(message:find("No slot matches", 1, true))
		end)
	end)

	describe("items_craft", function()
		it("crafts with the Items tab's controls and leaves the tab as it was", function()
			local itemsTab = build.itemsTab
			itemsTab:CreateDisplayItemFromRaw(GLOVES, true)
			local shown = itemsTab.displayItem
			-- What the user last picked in "Craft item..." and the affix sorting stay theirs.
			itemsTab.lastCraftRaritySel = 2
			itemsTab.controls.craftingSorting.selIndex = 3

			local bases = callTool("items_craft", { action = "bases", search = "Hubris" })
			assert.are.equals("Hubris Circlet", bases.bases[1].name)

			local created = callTool("items_craft", { action = "create", base = "Hubris Circlet", name = "Crafted Crown" })
			assert.is_truthy(created.item:find("Crafted: true", 1, true))
			assert.are.equals("RARE", created.rarity)

			local options = callTool("items_craft", { action = "affix", item = created.item, affix_type = "prefix" })
			assert.is_truthy(#options.options > 0)
			local lifeLabel
			for _, option in ipairs(options.options) do
				if option.label:find("to maximum Life$") then
					lifeLabel = option.label
				end
			end
			assert.is_truthy(lifeLabel)
			local withLife = callTool("items_craft", { action = "affix", item = created.item, affix_type = "prefix", modifier = lifeLabel, tier = 1, roll = 1 })
			assert.are.equals(1, withLife.affixes[1].tier)
			assert.is_truthy(table.concat(withLife.mods, "\n"):find("to maximum Life", 1, true))

			local bench = callTool("items_craft", { action = "modifier", item = withLife.item, source = "Crafting Bench" })
			assert.is_truthy(#bench.options > 0)
			local custom = callTool("items_craft", { action = "modifier", item = withLife.item, custom = "+10% to Cold Resistance" })
			assert.is_truthy(table.concat(custom.mods, "\n"):find("+10% to Cold Resistance", 1, true))

			local quality = callTool("items_craft", { action = "properties", item = custom.item, quality = 20, influences = { "Shaper" } })
			assert.is_truthy(quality.item:find("Shaper Item", 1, true))
			assert.is_truthy(quality.item:find("Quality: 20", 1, true))

			local corrupted = callTool("items_craft", { action = "corrupt", item = quality.item, implicits = { } })
			assert.is_truthy(corrupted.item:find("Corrupted", 1, true))

			local item = main.mcpServer:GetTools().T.ParseItem(build, corrupted.item, "Helmet")
			assert.are.equals("Crafted Crown, Hubris Circlet", item.name)
			-- Nothing was added to the build and the tab still shows its own item.
			assert.are.equals(shown, itemsTab.displayItem)
			assert.are.equals(2, itemsTab.lastCraftRaritySel)
			assert.are.equals(3, itemsTab.controls.craftingSorting.selIndex)
			assert.are.equals(0, #itemsTab.itemOrderList)
			local message = toolError("items_craft", { action = "affix", item = corrupted.item, modifier = "no such modifier at all" })
			assert.is_truthy(message:find("modifier", 1, true))
			assert.are.equals(shown, itemsTab.displayItem)
			assert.is_nil(main.popups[1])
		end)
	end)

	describe("trade_query", function()
		it("generates a weighted search without contacting the trade site", function()
			callTool("items_equip", { action = "equip", slot = "Helmet", item = HELMET })
			local tradeQuery = build.itemsTab.tradeQuery
			local generatorBefore = tradeQuery.tradeQueryGenerator
			local weightsBefore = tradeQuery.statSortSelectionList and copyTable(tradeQuery.statSortSelectionList)
			local result = callTool("trade_query", { slot = "Helmet", weights = { { stat = "Life", weight = 1 } }, league = "Standard" })
			assert.are.equals("armour.helmet", result.category)
			assert.is_truthy(#result.weightedStats > 0)
			assert.are.equals(result.query.stats[1].filters[1].id, result.weightedStats[1].id)
			assert.are.equals("securable", result.query.status.option)
			assert.are.equals(generatorBefore, tradeQuery.tradeQueryGenerator)
			assert.are.same(weightsBefore, tradeQuery.statSortSelectionList)
			assert.is_nil(main.popups[1])
			local message = toolError("trade_query", { slot = "Helmet", weights = { { stat = "Nonsense", weight = 1 } } })
			assert.is_truthy(message:find("Unknown weight stat", 1, true))
		end)
	end)
end)
