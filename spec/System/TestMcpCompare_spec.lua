local McpProtocol = LoadModule("Modules/McpProtocol")

local PORT = 49290
local TOKEN = "0123456789abcdef0123456789abcdef"

local protocol

local function request(method, params)
	local message = { jsonrpc = "2.0", id = 1, method = method, params = params }
	local response
	protocol:HandleHttp({
		method = "POST",
		path = "/mcp",
		version = "1.1",
		headers = {
			host = "127.0.0.1:" .. PORT,
			authorization = "Bearer " .. TOKEN,
			["content-type"] = "application/json",
		},
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

-- A node next to the class start that the open build has not allocated.
local function nearbyNode()
	for _, node in pairs(build.spec.nodes) do
		if node.path and #node.path == 1 and node.type == "Normal" and not node.alloc then
			return node
		end
	end
end

local HELMET = "Rarity: RARE\nTest Hat\nIron Hat\nQuality: 0\n+80 to maximum Life\n+40% to Fire Resistance\n"

-- XML of a build different from a new one: level 90, one more passive, a helmet and a skill.
local function otherBuildXML()
	newBuild()
	build.controls.characterLevel:SetText("90", true)
	local node = nearbyNode()
	build.spec:AllocNode(node)
	build.spec:AddUndoState()
	build.itemsTab:CreateDisplayItemFromRaw(HELMET, true)
	build.itemsTab:AddDisplayItem()
	build.skillsTab:PasteSocketGroup("Label: Test group\nFireball 20/0  1\nAdded Fire Damage 20/0  1\n")
	build.buildFlag = true
	runCallback("OnFrame")
	local xml = build:SaveDB("code")
	build.abortSave = true
	return xml, node.id
end

local function readSampleCharacter()
	local dkjson = require "dkjson"
	local file = io.open("../spec/System/SampleCharacter.json", "r")
	local body = dkjson.decode(file:read("*a"))
	file:close()
	return body
end

describe("MCP compare, party and character import tools", function()
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
		build.abortSave = true
		local popup = main.popups[1]
		while main.popups[1] do
			main:ClosePopup()
		end
		assert.is_nil(popup, popup and ("dialog left open: " .. tostring(popup.title)))
	end)

	describe("compare_builds", function()
		it("adds a copy of the open build, lists it and reports no differences", function()
			build:ResetModFlags()
			local added = callTool("compare_builds", { action = "add", current = true })
			assert.are.equals(1, added.added.index)
			assert.are.equals(1, #build.compareTab.compareEntries)
			local list = callTool("compare_builds", { action = "list" })
			assert.are.equals(1, #list.comparisons)
			assert.are.equals("Scion", list.comparisons[1].class)
			assert.is_true(list.comparisons[1].active)
			local report = callTool("compare_builds", { action = "report" })
			assert.are.equals(0, #report.stats.rows)
			assert.are.equals(0, report.tree.compareOnlyCount)
			assert.are.equals(0, report.config.differences)
			-- Comparisons are not part of the build.
			assert.is_false(build:HasUnsavedChanges())
		end)

		it("adds a build from XML and reports what PoB shows as different", function()
			local xml, nodeId = otherBuildXML()
			newBuild()
			callTool("compare_builds", { action = "add", code = xml, name = "Guide" })
			local entry = build.compareTab.compareEntries[1]
			assert.are.equals("Guide", entry.label)
			local report = callTool("compare_builds", { action = "report", item_mods = true, item_stat_changes = true })
			assert.are.equals(90, report.compareLevel)
			local life
			for _, row in ipairs(report.stats.rows) do
				if row.stat == "Life" then
					life = row
				end
			end
			assert.is_truthy(life, "Life should differ")
			assert.is_true(life.compareIsBetter)
			local found = false
			for _, node in ipairs(report.tree.compareOnly) do
				found = found or node.id == nodeId
			end
			assert.is_true(found)
			local helmet
			for _, row in ipairs(report.items.slots) do
				if row.slot == "Helmet" then
					helmet = row
				end
			end
			assert.are.equals("missing", helmet.status)
			assert.is_truthy(helmet.compare.name:find("Test Hat", 1, true))
			assert.is_truthy(#helmet.compareMods > 0)
			assert.is_truthy(#helmet.equipStatChanges > 0)
			assert.are.equals(1, #report.skills.groups)
			assert.is_nil(report.skills.groups[1].primaryGroup)
			-- Only differences: the open build's own passives are all shared.
			local all = callTool("compare_builds", { action = "report", sections = { "stats" }, only_differences = false })
			assert.is_truthy(#all.stats.rows > #report.stats.rows)
		end)

		it("runs the power report without changing the open build", function()
			local xml, nodeId = otherBuildXML()
			newBuild()
			build:ResetModFlags()
			callTool("compare_builds", { action = "add", code = xml })
			local allocated = build.spec:CountAllocNodes()
			local lifeBefore = build.calcsTab.mainOutput.Life
			local report = callTool("compare_builds", { action = "power_report", metric = "Life" })
			assert.are.equals("Life", report.metric.stat)
			local item
			for _, row in ipairs(report.rows) do
				if row.category == "Item" then
					item = row
				end
			end
			assert.is_truthy(item, "the helmet adds life")
			assert.is_truthy(item.impact > 0)
			assert.are.equals(allocated, build.spec:CountAllocNodes())
			assert.are.equals(lifeBefore, build.calcsTab.mainOutput.Life)
			assert.is_false(build:HasUnsavedChanges())
			-- The tab shows the same report.
			assert.are.equals("Life", build.compareTab.comparePowerStat.stat)
			local message = toolError("compare_builds", { action = "power_report", metric = "Nope" })
			assert.is_truthy(message:find("Unknown metric", 1, true))
		end)

		it("composes a buy-similar URL for a compared item without opening anything", function()
			local xml = otherBuildXML()
			newBuild()
			callTool("compare_builds", { action = "add", code = xml })
			local result = callTool("compare_builds", { action = "buy_similar", slot = "Helmet", mods = "all" })
			assert.is_truthy(result.url:find("^https://www%.pathofexile%.com/trade/search/Standard/"))
			assert.is_truthy(#result.mods > 0)
			assert.is_nil(main.popups[1])
		end)

		it("selects and removes comparisons", function()
			callTool("compare_builds", { action = "add", current = true, name = "One" })
			callTool("compare_builds", { action = "add", current = true, name = "Two" })
			assert.are.equals(2, build.compareTab.activeCompareIndex)
			local selected = callTool("compare_builds", { action = "select", index = 1, tree_set = 1 })
			assert.are.equals("One", selected.selected.label)
			assert.are.equals(1, build.compareTab.activeCompareIndex)
			local message = toolError("compare_builds", { action = "select", index = 1, item_set = "Nope" })
			assert.is_truthy(message:find("item set", 1, true))
			local removed = callTool("compare_builds", { action = "remove", index = 1 })
			assert.are.equals("One", removed.removed)
			assert.are.equals(1, removed.remaining)
			callTool("compare_builds", { action = "remove" })
			message = toolError("compare_builds", { action = "report" })
			assert.is_truthy(message:find("No comparison build", 1, true))
		end)
	end)

	describe("compare_copy", function()
		it("copies the tree so the allocations match", function()
			local xml = otherBuildXML()
			newBuild()
			callTool("compare_builds", { action = "add", code = xml })
			local entry = build.compareTab.compareEntries[1]
			local result = callTool("compare_copy", { what = "tree", use = true })
			assert.is_true(result.treeSet.active)
			assert.are.equals(2, #build.treeTab.specList)
			for nodeId in pairs(entry.spec.allocNodes) do
				assert.is_truthy(build.spec.allocNodes[nodeId], "node " .. nodeId .. " not copied")
			end
			for nodeId in pairs(build.spec.allocNodes) do
				assert.is_truthy(entry.spec.allocNodes[nodeId], "node " .. nodeId .. " extra")
			end
			assert.is_true(build:HasUnsavedChanges())
		end)

		it("copies and equips an item and copies socket groups", function()
			local xml = otherBuildXML()
			newBuild()
			callTool("compare_builds", { action = "add", code = xml })
			local lifeBefore = build.calcsTab.mainOutput.Life
			local result = callTool("compare_copy", { what = "item", slot = "Helmet", use = true })
			assert.is_true(result.equipped)
			local slot = build.itemsTab.slots["Helmet"]
			assert.is_truthy(build.itemsTab.items[slot.selItemId].name:find("Test Hat", 1, true))
			assert.is_truthy(build.calcsTab.mainOutput.Life > lifeBefore)
			assert.is_truthy(#result.statChanges > 0)
			result = callTool("compare_copy", { what = "skills", socket_groups = { 1 } })
			assert.are.equals(1, #build.skillsTab.socketGroupList)
			assert.are.equals("Fireball", build.skillsTab.socketGroupList[1].gemList[1].nameSpec)
			assert.are.equals("Test group", build.skillsTab.socketGroupList[1].label)
			local message = toolError("compare_copy", { what = "skills", socket_groups = { 9 } })
			assert.is_truthy(message:find("no socket group 9", 1, true))
		end)
	end)

	describe("party", function()
		it("imports a party member's aura, changing the calculation, and clears it", function()
			-- A support build exporting Clarity.
			callTool("party", { action = "export_support", enabled = true })
			assert.is_true(build.importTab.controls.enablePartyExportBuffs.state)
			build.skillsTab:PasteSocketGroup("Clarity 20/0  1\n")
			build.buildFlag = true
			runCallback("OnFrame")
			local exported = callTool("party", { action = "export_support", enabled = true })
			assert.is_truthy(exported.exports.Aura)
			local xml = build:SaveDB("code")
			assert.is_truthy(xml:find("ExportedBuffs", 1, true))
			build.abortSave = true

			newBuild()
			local regenBefore = build.calcsTab.mainOutput.ManaRegenRecovery
			local destination = build.partyTab.controls.importCodeDestination.selIndex
			-- Build files saved on Windows have CRLF line ends.
			local result = callTool("party", { action = "import", code = xml:gsub("\n", "\r\n") })
			assert.are.equals("Clarity", result.auras[1].name)
			assert.is_truthy(build.partyTab.actor.Aura.Aura.Clarity)
			assert.is_truthy(build.calcsTab.mainOutput.ManaRegenRecovery > regenBefore)
			assert.is_truthy(#result.statChanges > 0)
			assert.are.equals(destination, build.partyTab.controls.importCodeDestination.selIndex)
			assert.is_true(build:HasUnsavedChanges())

			local got = callTool("party", { action = "get", include_text = true })
			assert.is_truthy(got.importedText.auras:find("Clarity", 1, true))
			callTool("party", { action = "disable_effects" })
			assert.are.equals(regenBefore, build.calcsTab.mainOutput.ManaRegenRecovery)
			callTool("party", { action = "rebuild" })
			assert.is_truthy(build.calcsTab.mainOutput.ManaRegenRecovery > regenBefore)
			result = callTool("party", { action = "clear" })
			assert.are.equals(0, #result.auras)
			assert.are.equals("", build.partyTab.controls.editAuras.buf)
			assert.are.equals(regenBefore, build.calcsTab.mainOutput.ManaRegenRecovery)
		end)

		it("refuses a build without a party export", function()
			local message = toolError("party", { action = "import", code = build:SaveDB("code") })
			assert.is_truthy(message:find("Export Support", 1, true))
		end)
	end)

	describe("import_character", function()
		local api, savedToken

		before_each(function()
			api = main.api
			savedToken = api.authToken
		end)

		after_each(function()
			api.authToken = savedToken
			api.DownloadCharacter = nil
			api.DownloadCharacterList = nil
		end)

		it("fails when Path of Building is not logged in, and checks the name", function()
			api.authToken = nil
			local message = toolError("import_character", { action = "import", name = "testCharacter" })
			assert.is_truthy(message:find("Authorize with Path of Exile", 1, true))
			message = toolError("import_character", { action = "list" })
			assert.is_truthy(message:find("Authorize with Path of Exile", 1, true))
			api.authToken = "test"
			message = toolError("import_character", { action = "import", name = "../league/x" })
			assert.is_truthy(message:find("character name", 1, true))
		end)

		it("imports a character into a new build", function()
			local sample = readSampleCharacter()
			api.authToken = "test"
			local asked
			api.DownloadCharacter = function(_, realm, name, callback)
				asked = realm .. "/" .. name
				callback(copyTable(sample))
			end
			build.controls.characterLevel:SetText("50", true)
			assert.is_truthy(toolError("import_character", { action = "import", name = "testCharacter" }):find("unsaved changes", 1, true))
			local result = callTool("import_character", { action = "import", name = "testCharacter", realm = "pc", discard_unsaved = true })
			assert.are.equals("pc/testCharacter", asked)
			assert.are.equals("testCharacter", result.build.name)
			assert.are.equals("Templar", build.spec.curClassName)
			assert.are.equals("Hierophant", build.spec.curAscendClassName)
			assert.are.equals(99, build.characterLevel)
			assert.are.equals(2, build.spec.allocatedKeystoneCount)
			assert.is_truthy(result.equippedItems > 5)
			assert.is_truthy(#build.skillsTab.socketGroupList > 0)
			assert.is_truthy(result.audit.itemsNotImported)
		end)

		it("updates only the tree of the open build", function()
			local sample = readSampleCharacter()
			api.authToken = "test"
			api.DownloadCharacter = function(_, _, _, callback)
				callback(copyTable(sample))
			end
			local result = callTool("import_character", { action = "import", name = "testCharacter", mode = "update", parts = "tree" })
			assert.are.equals("tree and jewels", result.imported)
			assert.are.equals("Templar", build.spec.curClassName)
			-- Only skills granted by the imported jewels, no gem groups.
			for _, group in ipairs(build.skillsTab.socketGroupList) do
				assert.is_truthy(group.source, "unexpected socket group " .. tostring(group.displayLabel))
			end
			assert.is_nil(build.itemsTab.items[build.itemsTab.slots["Helmet"].selItemId])
			assert.is_true(build:HasUnsavedChanges())
		end)

		it("lists characters and explains API errors", function()
			api.authToken = "test"
			api.DownloadCharacterList = function(_, realm, callback)
				callback({ characters = {
					{ name = "Zed", realm = "pc", class = "Witch", league = "Standard", level = 90 },
					{ name = "amy", realm = "pc", class = "Slayer", league = "Mirage", level = 80 },
				} })
			end
			local list = callTool("import_character", { action = "list" })
			assert.are.equals(2, #list.characters)
			assert.are.equals("amy", list.characters[1].name)
			list = callTool("import_character", { action = "list", league = "Standard" })
			assert.are.equals(1, #list.characters)
			assert.are.equals("Zed", list.characters[1].name)
			api.DownloadCharacter = function(_, _, _, callback)
				callback(nil, "Response code: 404")
			end
			local message = toolError("import_character", { action = "import", name = "Nobody", mode = "update" })
			assert.is_truthy(message:find("no character 'Nobody'", 1, true))
			api.DownloadCharacter = function(_, _, _, callback)
				callback(nil, "Response code: 429", os.time() + 30)
			end
			message = toolError("import_character", { action = "import", name = "Nobody", mode = "update" })
			assert.is_truthy(message:find("rate limiting", 1, true))
		end)
	end)
end)
