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

-- Synthetic Kurgal (Baleful Dominion) lookup table, as in TestAbyssTimelessJewel_spec.
local function uint16(value)
	return string.char(value % 256, math.floor(value / 256) % 256)
end

local function abyssModification(components)
	local encoded = { string.char(#components) }
	for _, component in ipairs(components) do
		encoded[#encoded + 1] = string.char(component.type, component.id, #component.rolls)
		for _, roll in ipairs(component.rolls) do
			encoded[#encoded + 1] = uint16(roll < 0 and roll + 65536 or roll)
		end
	end
	return table.concat(encoded)
end

local function kurgalExampleData()
	local affectedNodes = {
		{ id = 4367, modification = abyssModification({ { type = 1, id = 24, rolls = { 6 } } }) },
		{ id = 15117, modification = abyssModification({ { type = 1, id = 19, rolls = { 8 } } }) },
		{ id = 20528, modification = abyssModification({ { type = 2, id = 207, rolls = { -15 } } }) },
		{ id = 21958, modification = abyssModification({ { type = 2, id = 211, rolls = { 12, 18 } } }) },
	}
	local encoded = { "ABYS" .. string.char(1, 9) .. uint16(533) .. uint16(533) .. uint16(1), string.char(1, 60), uint16(61419), string.char(#affectedNodes) }
	for _, affectedNode in ipairs(affectedNodes) do
		encoded[#encoded + 1] = uint16(affectedNode.id)
		encoded[#encoded + 1] = affectedNode.modification
	end
	return table.concat(encoded)
end

-- The closest unallocated node of a type needing at least 'points' points.
local function findNode(nodeType, points, filter)
	local found
	for _, node in pairs(build.spec.nodes) do
		if node.type == nodeType and not node.alloc and not node.ascendancyName and node.path and #node.path >= points
			and (not filter or filter(node))
			and (not found or #node.path < #found.path or (#node.path == #found.path and node.id < found.id)) then
			found = node
		end
	end
	return assert(found, "no " .. nodeType .. " node found")
end

local function idSet(list)
	local set = { }
	for _, entry in ipairs(list) do
		set[entry.id] = true
	end
	return set
end

describe("MCP tree tools", function()
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
		data.timelessJewelLUTs[9] = nil
		build.abortSave = true
		local popup = main.popups[1]
		while main.popups[1] do
			main:ClosePopup()
		end
		assert.is_nil(popup, popup and ("dialog left open: " .. tostring(popup.title)))
	end)

	it("lists the tree tools with full descriptions", function()
		local _, body = request("tools/list")
		local byName = { }
		for _, tool in ipairs(body.result.tools) do
			byName[tool.name] = tool
		end
		for _, name in ipairs({ "tree_get", "tree_search", "tree_edit", "tree_specs", "tree_node_power", "tree_timeless_jewel", "tree_tattoos" }) do
			assert.is_truthy(byName[name], name .. " is missing")
			assert.is_truthy(#byName[name].description > 200, name .. " needs a fuller description")
		end
		assert.is_true(byName.tree_get.annotations.readOnlyHint)
		assert.is_true(byName.tree_specs.annotations.destructiveHint)
		assert.is_true(byName.tree_timeless_jewel.annotations.readOnlyHint)
	end)

	it("reads the tree as PoB counts it", function()
		local target = findNode("Notable", 3)
		build.spec:AllocNode(target)
		build.buildFlag = true
		runCallback("OnFrame")
		build:ResetModFlags()
		local used, ascUsed = build.spec:CountAllocNodes()

		local tree = callTool("tree_get")
		assert.are.equals("Scion", tree.class)
		assert.are.equals(used, tree.points.passives)
		assert.are.equals(ascUsed, tree.points.ascendancy)
		assert.is_truthy(isValueInArray(tree.notables, target.dn))
		assert.are.equals(1, #tree.specs)
		assert.is_true(tree.specs[1].current)
		assert.are.equals(used, tree.specs[1].points)
		assert.is_truthy(tree.pointCounter:find(tostring(used), 1, true))
		assert.is_truthy(tree.pointCounterTooltip[1]:find("Required Level", 1, true))
		assert.is_truthy(tree.url:match("^https://"))
		assert.are.equals(0, tree.tattooCount)

		local nodes = callTool("tree_get", { detail = "nodes" })
		assert.are.equals(used, nodes.page.total)
		for _, node in ipairs(nodes.nodes) do
			assert.is_truthy(build.spec.allocNodes[node.id])
		end
		-- Reading changes nothing.
		assert.is_false(build:HasUnsavedChanges())
	end)

	it("searches with the Tree tab's search", function()
		local target = findNode("Notable", 3)
		local result = callTool("tree_search", { query = '"' .. target.dn .. '"', limit = 200 })
		assert.is_truthy(idSet(result.nodes)[target.id])
		for _, node in ipairs(result.nodes) do
			if node.id == target.id then
				assert.are.equals(#target.path, node.pointsNeeded)
				assert.are.equals("notable", node.type)
				assert.is_false(node.allocated)
			end
		end

		-- The same matches as PoB's own search function, with the filters applied.
		local viewer = build.treeTab.viewer
		local proxy = { searchParams = viewer:ParseSearchString("life") }
		local expected = 0
		for _, node in pairs(build.spec.nodes) do
			if node.type == "Keystone" and not node.ascendancyName and viewer.DoesNodeMatchSearchParams(proxy, node) then
				expected = expected + 1
			end
		end
		result = callTool("tree_search", { query = "life", types = { "keystone" }, allocated = "unallocated" })
		assert.are.equals(expected, result.page.total)

		result = callTool("tree_search", { types = { "mastery" }, limit = 1 })
		assert.is_truthy(result.nodes[1].effects[1].id)
		assert.is_true(result.nodes[1].effects[1].available)
	end)

	it("allocates and removes nodes as clicks do", function()
		local target = findNode("Normal", 3)
		local pathLength = #target.path
		local pathIds = { }
		for _, node in ipairs(target.path) do
			pathIds[node.id] = true
		end
		build:ResetModFlags()
		local result = callTool("tree_edit", { allocate = { target.id, "No Such Passive" }, deallocate = { target.id } })
		local added = idSet(result.added)
		assert.are.same(pathIds, added)
		for id in pairs(pathIds) do
			assert.is_truthy(build.spec.allocNodes[id])
		end
		assert.are.equals(2, #result.failed)
		assert.is_truthy(result.failed[1].reason:find("not allocated", 1, true))
		assert.is_truthy(result.failed[2].reason:find("No passive node is named", 1, true))
		assert.is_true(build:HasUnsavedChanges())
		assert.is_truthy(result.statChanges)

		-- Removing the first node of the path removes the rest with it.
		local first
		for id in pairs(pathIds) do
			local node = build.spec.nodes[id]
			if not first or #node.depends > #first.depends then
				first = node
			end
		end
		result = callTool("tree_edit", { deallocate = { first.id } })
		assert.are.same(pathIds, idSet(result.removed))
		assert.are.equals(pathLength - 1, #result.deallocated[1].alsoRemoved)
		assert.are.equals(0, (build.spec:CountAllocNodes()))
	end)

	it("chooses mastery effects through the mastery dialog", function()
		local mastery, twin
		for _, node in pairs(build.spec.nodes) do
			if node.type == "Mastery" and node.masteryEffects and node.path and (not mastery or #node.path < #mastery.path) then
				mastery = node
			end
		end
		for _, node in pairs(build.spec.nodes) do
			if node ~= mastery and node.type == "Mastery" and node.dn == mastery.dn and node.path then
				twin = node
			end
		end
		local effectId = mastery.masteryEffects[1].effect
		local result = callTool("tree_edit", { masteries = { { node = mastery.id, effect = effectId } } })
		assert.are.equals(effectId, build.spec.masterySelections[mastery.id])
		assert.is_true(mastery.alloc)
		assert.are.equals(1, #result.masteries)
		assert.are.equals(0, #result.failed)
		if twin then
			result = callTool("tree_edit", { masteries = { { node = twin.id, effect = effectId } } })
			assert.is_truthy(result.failed[1].reason:find("already chosen", 1, true))
			assert.is_nil(build.spec.masterySelections[twin.id])
		end
		-- Choosing it again changes nothing.
		result = callTool("tree_edit", { masteries = { { node = mastery.id, effect = effectId } } })
		assert.is_nil(result.masteries)
	end)

	it("changes class and ascendancy", function()
		local result = callTool("tree_edit", { class = "Witch", ascendancy = "Necromancer" })
		assert.are.equals("Witch", build.spec.curClassName)
		assert.are.equals("Necromancer", build.spec.curAscendClassName)
		assert.are.equals("Necromancer", result.ascendancy)
		local message = toolError("tree_edit", { class = "Nobody" })
		assert.is_truthy(message:find("Unknown class", 1, true))
		build:UpdateSecondaryAscendancyDropdown(true)
		local drop = build.controls.secondaryAscendDrop
		if drop.list[2] then
			result = callTool("tree_edit", { secondary_ascendancy = drop.list[2].label })
			assert.are.equals(drop.list[2].ascendClassId, build.spec.curSecondaryAscendClassId)
		else
			message = toolError("tree_edit", { secondary_ascendancy = "Anything" })
			assert.is_truthy(message:find("no secondary ascendancies", 1, true))
		end
	end)

	it("manages the tree list through PoB's list control", function()
		local result = callTool("tree_specs", { action = "new", title = "Second" })
		assert.are.equals(2, #build.treeTab.specList)
		assert.are.equals("Second", build.treeTab.specList[2].title)
		assert.are.equals(2, result.index)
		assert.are.equals(1, build.treeTab.activeSpec)

		callTool("tree_specs", { action = "rename", spec = "Second", title = "Renamed" })
		assert.are.equals("Renamed", build.treeTab.specList[2].title)

		local message = toolError("tree_specs", { action = "copy", spec = 1 })
		assert.is_truthy(message:find("title", 1, true))
		callTool("tree_specs", { action = "copy", spec = 1, title = "Copied" })
		assert.are.equals("Copied", build.treeTab.specList[3].title)

		result = callTool("tree_specs", { action = "select", spec = "Renamed" })
		assert.are.equals(2, build.treeTab.activeSpec)
		assert.are.equals(build.treeTab.specList[2], build.spec)
		assert.is_true(result.specs[2].current)

		result = callTool("tree_specs", { action = "delete", spec = 3 })
		assert.are.equals("Copied", result.deleted)
		assert.are.equals(2, #build.treeTab.specList)
		callTool("tree_specs", { action = "delete", spec = 1 })
		message = toolError("tree_specs", { action = "delete", spec = 1 })
		assert.is_truthy(message:find("only one tree", 1, true))
		assert.are.equals("Renamed", build.spec.title)
	end)

	it("reports node power sorted as asked and restores the Tree tab's stat", function()
		local calcsTab = build.calcsTab
		local statBefore, depthBefore = calcsTab.powerStat, calcsTab.nodePowerMaxDepth
		local result = callTool("tree_node_power", { stat = "Life", max_depth = 5, limit = 200 })
		assert.is_truthy(#result.nodes > 3)
		assert.are.equals("Life", result.stat)
		assert.is_truthy(#result.nodes > 0)
		for i = 2, #result.nodes do
			assert.is_true(result.nodes[i - 1].power >= result.nodes[i].power)
			assert.is_false(result.nodes[i].allocated)
		end
		assert.are.equals(statBefore, calcsTab.powerStat)
		assert.are.equals(depthBefore, calcsTab.nodePowerMaxDepth)
		assert.is_true(calcsTab.powerBuildFlag)

		result = callTool("tree_node_power", { stat = "life", max_depth = 5, sort = "per_point", types = { "normal" }, limit = 200 })
		for i, node in ipairs(result.nodes) do
			assert.are.equals("Normal", node.type)
			if i > 1 then
				assert.is_true(result.nodes[i - 1].perPoint >= node.perPoint)
			end
		end
		local message = toolError("tree_node_power", { stat = "Offence/Defence" })
		assert.is_truthy(message:find("no power report", 1, true))
	end)

	it("finds a timeless jewel seed and leaves the finder's settings alone", function()
		local parseAbyssJewel = select(4, LoadModule("Modules/DataAbyssJewelLookUpTableHelper"))
		data.timelessJewelLUTs[9] = parseAbyssJewel(9, kurgalExampleData())
		build.timelessData.searchList = "something the user typed"
		build:ResetModFlags()
		local saved = copyTable(build.timelessData)
		local savedTradeType = build.treeTab.tradeTypeIndex

		local options = callTool("tree_timeless_jewel", { action = "options", jewel_type = "Baleful Dominion" })
		assert.are.equals(9, options.jewelType.id)
		local modIds = idSet(options.mods)
		assert.is_truthy(modIds["abyss_hypnotic_notable_16"])
		local sockets = idSet(options.sockets)
		assert.is_truthy(sockets[61419])
		assert.is_truthy(sockets.all)

		local result = callTool("tree_timeless_jewel", {
			action = "search",
			jewel_type = 9,
			socket = 61419,
			desired = {
				{ node = "abyss_hypnotic_small_attribute19", weight = 1, weight2 = 0 },
				{ node = "abyss_hypnotic_notable_16", weight = 1, weight2 = 0 },
			},
			trade = { league = "Standard" },
		})
		assert.are.equals(1, result.resultCount)
		assert.are.equals(533, result.results[1].seed)
		assert.are.equals(23, result.results[1].total)
		assert.are.equals(2, #result.results[1].gives)
		assert.is_truthy(result.trade.links[1].url:match("^https://www%.pathofexile%.com/trade/search/Standard"))
		assert.are.same({ 533 }, result.trade.links[1].seeds)

		assert.are.same(saved, build.timelessData)
		assert.are.equals(savedTradeType, build.treeTab.tradeTypeIndex)
		assert.is_false(build:HasUnsavedChanges())

		local message = toolError("tree_timeless_jewel", { action = "search", jewel_type = 9, socket = 61419, desired = { { node = "No such modifier" } } })
		assert.is_truthy(message:find("is not a Baleful Dominion modifier", 1, true))
		assert.are.same(saved, build.timelessData)
	end)

	it("applies and resets a tattoo through PoB's dialog", function()
		local target
		for _, node in pairs(build.spec.nodes) do
			if node.type == "Normal" and node.dn == "Strength" and not node.ascendancyName and (not target or node.id < target.id) then
				target = node
			end
		end
		local treeTab = build.treeTab
		local listing = callTool("tree_tattoos", { action = "list", node = target.id })
		assert.is_truthy(#listing.options > 0)
		assert.are.equals(0, listing.tattooCount)
		assert.is_nil(treeTab.defaultTattoo.Strength)

		local result = callTool("tree_tattoos", { action = "apply", node = target.id, tattoo = listing.options[1].id })
		assert.is_truthy(build.spec.hashOverrides[target.id])
		assert.are.equals(listing.options[1].name, result.applied.name)
		assert.are.equals(1, result.tattooCount)
		assert.is_nil(treeTab.defaultTattoo.Strength)
		assert.is_falsy(treeTab.showLegacyTattoo)
		assert.are.equals(1, callTool("tree_get").tattooCount)

		result = callTool("tree_tattoos", { action = "reset", node = target.id })
		assert.is_nil(build.spec.hashOverrides[target.id])
		assert.are.equals("Strength", build.spec.nodes[target.id].dn)
		assert.are.equals(0, result.tattooCount)

		local message = toolError("tree_tattoos", { action = "reset", node = target.id })
		assert.is_truthy(message:find("has no tattoo", 1, true))
		local notable = findNode("Notable", 3, function(node) return not (node.sd[1] or ""):match("^%+30 to") end)
		message = toolError("tree_tattoos", { action = "list", node = notable.id })
		assert.is_truthy(message:find("cannot be tattooed", 1, true))
	end)
end)
