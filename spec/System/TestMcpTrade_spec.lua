local McpProtocol = LoadModule("Modules/McpProtocol")
local dkjson = require("dkjson")

local PORT = 49290
local TOKEN = "0123456789abcdef0123456789abcdef"

local protocol

local function frameFuncKeys()
	local keys = { }
	for key in pairs(main.onFrameFuncs) do
		if key:match("^McpTradeSearch") then
			table.insert(keys, key)
		end
	end
	return keys
end

-- Calls a tool, running its trade search frames until it answers.
local function callTool(name, args, allowError)
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
		body = McpProtocol.Encode({ jsonrpc = "2.0", id = 1, method = "tools/call", params = { name = name, arguments = args or McpProtocol.Object() } }),
	}, function(r)
		response = r
	end)
	for _ = 1, 50 do
		if response then
			break
		end
		for _, key in ipairs(frameFuncKeys()) do
			main.onFrameFuncs[key]()
		end
	end
	assert.is_truthy(response, "no response")
	assert.are.equals(200, response.status)
	local body = McpProtocol.Decode(response.body)
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

local HELMET = "Rarity: RARE\nTest Hat\nIron Hat\nQuality: 0\n+80 to maximum Life\n"

-- A listing as the trade site's fetch API returns it.
local function listing(id, name, typeLine, mods, amount, currency, priceType, whisper)
	return {
		id = id,
		item = { rarity = "Rare", name = name, typeLine = typeLine, ilvl = 80, explicitMods = { { description = mods[1] } }, pseudoMods = { "Sum: 42" } },
		listing = { price = { amount = amount, currency = currency, type = priceType }, whisper = whisper, account = { name = "seller" .. id } },
	}
end

describe("MCP trade tools", function()
	local api, savedToken, savedDownload, requests

	before_each(function()
		main.mcpServer.token = TOKEN
		protocol = main.mcpServer:NewProtocol(PORT)
		build.abortSave = true
		while main.popups[1] do
			main:ClosePopup()
		end
		newBuild()
		api = main.api
		savedToken = api.authToken
		savedDownload = launch.DownloadPage
		requests = { }
		local listings = {
			listing("a", "Fine Hat", "Iron Hat", { "+90 to maximum Life" }, 2, "divine", "~price", "@seller hi"),
			listing("b", "Weak Hat", "Iron Hat", { "+50 to maximum Life" }, 1, "chaos", "~b/o"),
			listing("c", "Wrong Boots", "Rawhide Boots", { "+99 to maximum Life" }, 1, "chaos", "~b/o"),
		}
		-- The trade site: a search, then one fetch; the currency rates are not available.
		launch.DownloadPage = function(_, url, callback, params)
			table.insert(requests, { url = url, params = params })
			if url:find("api/trade/search/", 1, true) then
				callback({ header = "HTTP/1.1 200 OK", body = dkjson.encode({ id = "query1", total = 10, result = { "a", "b", "c" } }) })
			elseif url:find("api/trade/fetch/", 1, true) then
				callback({ header = "HTTP/1.1 200 OK", body = dkjson.encode({ result = listings }) })
			else
				callback(nil, "offline")
			end
		end
	end)

	after_each(function()
		api.authToken = savedToken
		launch.DownloadPage = savedDownload
		build.abortSave = true
		local popup = main.popups[1]
		while main.popups[1] do
			main:ClosePopup()
		end
		assert.is_nil(popup, popup and ("dialog left open: " .. tostring(popup.title)))
	end)

	it("needs Path of Building's Path of Exile login", function()
		api.authToken = nil
		local message = toolError("trade_search", { slot = "Helmet", league = "Standard" })
		assert.is_truthy(message:find("not logged in", 1, true))
		assert.are.equals(0, #requests)
	end)

	it("searches as the trader does and measures every listing on the build", function()
		api.authToken = "test-token"
		callTool("items_equip", { action = "equip", slot = "Helmet", item = HELMET })
		build:ResetModFlags()
		local result = callTool("trade_search", { slot = "Helmet", league = "Standard", pages = 1, weights = { { stat = "Life", weight = 1 } } })

		local search = requests[1]
		for _, request in ipairs(requests) do
			if request.url:find("api/trade/search/", 1, true) then
				search = request
			end
		end
		assert.are.equals("https://www.pathofexile.com/api/trade/search/Standard", search.url)
		local sent = dkjson.decode(search.params.body)
		assert.are.same({ ["statgroup.0"] = "desc" }, sent.sort)
		assert.are.equals("weight", sent.query.stats[1].type)
		assert.is_truthy(search.params.header:find("Bearer test-token", 1, true))

		-- The boots do not fit the slot; the better helmet comes first.
		assert.are.equals(2, result.found)
		assert.are.equals("Fine Hat, Iron Hat", result.listings[1].name)
		assert.are.equals("Weak Hat, Iron Hat", result.listings[2].name)
		assert.is_true(result.listings[1].statValue > result.listings[2].statValue)
		assert.are.same({ amount = 2, currency = "divine", type = "~price" }, result.listings[1].price)
		assert.are.equals("@seller hi", result.listings[1].whisper)
		assert.is_truthy(result.listings[2].listingUrl:find("^https://www%.pathofexile%.com/trade/search/Standard/"))
		assert.is_truthy(table.concat(result.listings[1].changes, "\n"):find("Life", 1, true))
		assert.is_truthy(result.listings[1].item:find("+90 to maximum Life", 1, true))
		assert.are.equals("https://www.pathofexile.com/trade/search/Standard/query1", result.searchUrl)
		assert.are.equals("stat_value", result.sortedBy)

		-- Nothing changed in the build, and the search left nothing running.
		assert.is_false(build.modFlag)
		assert.are.same({ }, frameFuncKeys())

		-- Without currency rates the price sort falls back to stat value, as the trader does.
		result = callTool("trade_search", { slot = "Helmet", league = "Standard", pages = 1, sort_by = "price" })
		assert.are.equals("stat_value", result.sortedBy)
		assert.is_truthy(result.notes[1]:find("Currency rates", 1, true))
	end)

	it("reports a search that finds nothing, and rejects links from elsewhere", function()
		api.authToken = "test-token"
		launch.DownloadPage = function(_, url, callback)
			if url:find("api/trade/search/", 1, true) then
				callback({ header = "HTTP/1.1 200 OK", body = dkjson.encode({ id = "none", total = 0, result = { } }) })
			else
				callback(nil, "offline")
			end
		end
		callTool("items_equip", { action = "equip", slot = "Helmet", item = HELMET })
		local message = toolError("trade_search", { slot = "Helmet", league = "Standard", max_price = 1 })
		assert.is_truthy(message:find("no listings", 1, true))
		assert.are.same({ }, frameFuncKeys())
		message = toolError("trade_search", { slot = "Helmet", url = "https://example.com/trade/search/Standard/abc" })
		assert.is_truthy(message:find("trade search link", 1, true))
	end)

	it("generates searches for the trader's unique rows", function()
		-- The unique jewels need an allocated jewel socket, as in the trader.
		local message = toolError("trade_query", { slot = "Megalomaniac" })
		assert.is_truthy(message:find("jewel socket", 1, true))
		local nearest
		for _, node in pairs(build.spec.nodes) do
			if node.type == "Socket" and not node.containJewelSocket and not node.expansionJewel and node.path
				and (not nearest or #node.path < #nearest.path) then
				nearest = node
			end
		end
		build.spec:AllocNode(nearest)
		build.buildFlag = true
		runCallback("OnFrame")
		build.itemsTab:UpdateSockets()
		local socketLabel = build.itemsTab.sockets[nearest.id].label

		local result = callTool("trade_query", { slot = "Megalomaniac", league = "Standard" })
		assert.are.equals("Megalomaniac", result.slot)
		assert.are.equals(socketLabel, result.measuredIn)
		assert.are.equals("Megalomaniac", result.query.name)
		assert.is_truthy(#result.weightedStats > 0)
		message = toolError("trade_query", { slot = "Megalomaniac", jewel_socket = "No Such Socket" })
		assert.is_truthy(message:find("jewel socket", 1, true))

		-- A Pearl's supports count only for gems in the ring, so PoB has nothing to weight here.
		message = toolError("trade_query", { slot = "Pearl of Tsoatha", ring_slot = "Ring 2" })
		assert.is_truthy(message:find("found no mods", 1, true))
		message = toolError("trade_query", { slot = "Pearl of Tsoatha", ring_slot = "Ring 3" })
		assert.is_truthy(message:find("ring slot", 1, true))
		message = toolError("trade_query", { slot = "Helmet", ring_slot = "Ring 1" })
		assert.is_truthy(message:find("unique rows", 1, true))
	end)
end)
