local McpProtocol = LoadModule("Modules/McpProtocol")
local McpHttp = LoadModule("Modules/McpHttp")

local PORT = 49290
local TOKEN = "0123456789abcdef0123456789abcdef"
local MODERN = McpProtocol.MODERN_VERSION

local protocol

local function request(method, params, opts)
	opts = opts or { }
	local message = { jsonrpc = "2.0", id = opts.id == nil and 1 or opts.id, method = method, params = params }
	if opts.notification then
		message.id = nil
	end
	local headers = {
		host = opts.host or ("127.0.0.1:" .. PORT),
		authorization = opts.authorization or ("Bearer " .. TOKEN),
		["content-type"] = "application/json",
		origin = opts.origin,
	}
	for name, value in pairs(opts.headers or { }) do
		headers[name] = value
	end
	local response
	protocol:HandleHttp({
		method = opts.httpMethod or "POST",
		path = opts.path or "/mcp",
		version = "1.1",
		headers = headers,
		body = opts.body or McpProtocol.Encode(message),
	}, function(r)
		response = r
	end)
	assert.is_truthy(response, "no response")
	local body = response.body ~= "" and McpProtocol.Decode(response.body) or nil
	return response.status, body, response
end

-- A request in the 2026-07-28 form: _meta in params, metadata in headers.
local function modern(method, params, opts)
	params = params or { }
	params._meta = { ["io.modelcontextprotocol/protocolVersion"] = MODERN, ["io.modelcontextprotocol/clientCapabilities"] = McpProtocol.Object() }
	opts = opts or { }
	opts.headers = opts.headers or { }
	opts.headers["mcp-protocol-version"] = opts.headers["mcp-protocol-version"] or MODERN
	opts.headers["mcp-method"] = opts.headers["mcp-method"] or method
	if method == "tools/call" or method == "prompts/get" then
		opts.headers["mcp-name"] = opts.headers["mcp-name"] or params.name
	end
	return request(method, params, opts)
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

describe("MCP server", function()
	before_each(function()
		main.mcpServer.token = TOKEN
		protocol = main.mcpServer:NewProtocol(PORT)
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

	describe("HTTP parsing", function()
		it("parses a request with a body and keeps the rest", function()
			local req, rest = McpHttp.ParseRequest("POST /mcp HTTP/1.1\r\nHost: x\r\nContent-Length: 2\r\n\r\n{}GET")
			assert.are.equals("POST", req.method)
			assert.are.equals("{}", req.body)
			assert.are.equals("x", req.headers.host)
			assert.are.equals("GET", rest)
		end)
		it("waits for an incomplete body", function()
			local req, rest = McpHttp.ParseRequest("POST /mcp HTTP/1.1\r\nContent-Length: 10\r\n\r\n{}")
			assert.is_nil(req)
			assert.is_nil(rest)
		end)
		it("decodes a chunked body", function()
			local req = McpHttp.ParseRequest("POST /mcp HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n2\r\n{}\r\n0\r\n\r\n")
			assert.are.equals("{}", req.body)
		end)
		it("refuses a POST without a length and oversized bodies", function()
			local _, status = McpHttp.ParseRequest("POST /mcp HTTP/1.1\r\nHost: x\r\n\r\n")
			assert.are.equals(411, status)
			_, status = McpHttp.ParseRequest("POST /mcp HTTP/1.1\r\nContent-Length: 999999999999\r\n\r\n")
			assert.are.equals(413, status)
		end)
	end)

	describe("transport security", function()
		it("refuses other hosts, foreign origins and a missing token", function()
			assert.are.equals(403, (request("tools/list", nil, { host = "evil.example:49290" })))
			assert.are.equals(403, (request("tools/list", nil, { origin = "https://evil.example" })))
			assert.are.equals(401, (request("tools/list", nil, { authorization = "Bearer wrong" })))
			assert.are.equals(200, (request("tools/list", nil, { origin = "http://localhost:" .. PORT })))
		end)
		it("only serves POST on /mcp", function()
			assert.are.equals(405, (request("tools/list", nil, { httpMethod = "GET" })))
			assert.are.equals(404, (request("tools/list", nil, { path = "/other" })))
		end)
		it("refuses batches and invalid JSON", function()
			assert.are.equals(400, (request(nil, nil, { body = "[{}]" })))
			local status, body = request(nil, nil, { body = "{nope" })
			assert.are.equals(400, status)
			assert.are.equals(-32700, body.error.code)
		end)
	end)

	describe("legacy protocol versions", function()
		it("negotiates initialize", function()
			local status, body = request("initialize", { protocolVersion = "2025-06-18", capabilities = { }, clientInfo = { name = "test", version = "1" } })
			assert.are.equals(200, status)
			assert.are.equals("2025-06-18", body.result.protocolVersion)
			assert.are.equals("path-of-building", body.result.serverInfo.name)
			assert.is_truthy(body.result.capabilities.tools)
			assert.is_nil(body.result.resultType)
			_, body = request("initialize", { protocolVersion = "1999-01-01" })
			assert.are.equals(McpProtocol.LEGACY_VERSIONS[1], body.result.protocolVersion)
		end)
		it("accepts notifications without a body", function()
			local status, _, response = request("notifications/initialized", nil, { notification = true })
			assert.are.equals(202, status)
			assert.are.equals("", response.body)
		end)
		it("answers ping and lists tools with annotations", function()
			local _, body = request("ping")
			assert.is_truthy(body.result)
			_, body = request("tools/list")
			local byName = { }
			for _, tool in ipairs(body.result.tools) do
				byName[tool.name] = tool
				assert.are.equals("object", tool.inputSchema.type)
				assert.is_truthy(tool.description:len() > 80, tool.name .. " needs a fuller description")
			end
			assert.is_true(byName.build_stats.annotations.readOnlyHint)
			assert.is_false(byName.build_open.annotations.readOnlyHint)
			assert.is_true(byName.build_open.annotations.destructiveHint)
		end)
		it("reports an unknown tool as a protocol error and bad arguments as a tool error", function()
			local _, body = request("tools/call", { name = "nope" })
			assert.are.equals(-32602, body.error.code)
			local message = toolError("build_stats", { fields = "Life" })
			assert.is_truthy(message:find("arguments.fields must be array", 1, true))
			message = toolError("build_stats", { colour = true })
			assert.is_truthy(message:find("not a known argument", 1, true))
		end)
	end)

	describe("protocol version " .. MODERN, function()
		it("serves server/discover and tools/list with caching hints", function()
			local status, body = modern("server/discover")
			assert.are.equals(200, status)
			assert.are.equals("complete", body.result.resultType)
			assert.is_truthy(body.result.supportedVersions[1] == MODERN)
			assert.are.equals("path-of-building", body.result._meta["io.modelcontextprotocol/serverInfo"].name)
			_, body = modern("tools/list")
			assert.are.equals("complete", body.result.resultType)
			assert.is_truthy(body.result.ttlMs >= 0)
			assert.are.equals("private", body.result.cacheScope)
		end)
		it("checks the request metadata headers", function()
			local status, body = modern("tools/list", nil, { headers = { ["mcp-method"] = "tools/call" } })
			assert.are.equals(400, status)
			assert.are.equals(-32020, body.error.code)
			status, body = modern("tools/call", { name = "app_status" }, { headers = { ["mcp-name"] = "build_stats" } })
			assert.are.equals(400, status)
			assert.are.equals(-32020, body.error.code)
			status, body = modern("tools/call", { name = "app_status" }, { headers = { ["mcp-name"] = "=?base64?YXBwX3N0YXR1cw==?=" } })
			assert.are.equals(200, status)
			assert.is_false(body.result.isError)
		end)
		it("rejects unsupported versions and unknown methods", function()
			local status, body = request("tools/list", { _meta = { ["io.modelcontextprotocol/protocolVersion"] = "2099-01-01", ["io.modelcontextprotocol/clientCapabilities"] = { } } },
				{ headers = { ["mcp-protocol-version"] = "2099-01-01", ["mcp-method"] = "tools/list" } })
			assert.are.equals(400, status)
			assert.are.equals(-32022, body.error.code)
			assert.are.equals(MODERN, body.error.data.supported[1])
			status, body = modern("nothing/here")
			assert.are.equals(404, status)
			assert.are.equals(-32601, body.error.code)
		end)
	end)

	describe("prompts and resources", function()
		it("lists and fills prompts", function()
			local _, body = request("prompts/list")
			assert.is_truthy(#body.result.prompts >= 3)
			_, body = request("prompts/get", { name = "compare_with_guide", arguments = { guide = "https://pobb.in/x" } })
			assert.is_truthy(body.result.messages[1].content.text:find("https://pobb.in/x", 1, true))
			_, body = request("prompts/get", { name = "compare_with_guide", arguments = { } })
			assert.are.equals(-32602, body.error.code)
		end)
		it("reads the open build as XML", function()
			local _, body = request("resources/read", { uri = "pob://build/current.xml" })
			assert.is_truthy(body.result.contents[1].text:find("<PathOfBuilding", 1, true))
		end)
	end)

	describe("build tools", function()
		it("reports the status of the open build", function()
			local status = callTool("app_status")
			assert.are.equals("build", status.screen)
			assert.are.equals("Scion", status.build.class)
		end)

		it("returns the side bar and raw values", function()
			local stats = callTool("build_stats", { fields = { "Life", "NoSuchStat" } })
			assert.are.equals(build.calcsTab.mainOutput.Life, stats.values.Life)
			assert.are.same({ "NoSuchStat" }, stats.missing)
			assert.is_truthy(#stats.sidebar > 0)
		end)

		it("simulates an item exactly as equipping it", function()
			local itemText = "Rarity: RARE\nTest Hat\nIron Hat\nQuality: 0\n+80 to maximum Life\n+40% to Fire Resistance\n"
			local result = callTool("simulate", { slot = "Helmet", item = itemText, fields = { "Life", "FireResist" } })
			assert.is_truthy(#result.changes > 0)
			local predictedLife = result.values.Life.after
			-- The build itself did not change.
			assert.are.equals(result.values.Life.before, build.calcsTab.mainOutput.Life)
			build.itemsTab:CreateDisplayItemFromRaw(itemText, true)
			build.itemsTab:AddDisplayItem()
			runCallback("OnFrame")
			assert.are.equals(build.calcsTab.mainOutput.Life, predictedLife)
		end)

		it("simulates allocating a passive with its path", function()
			local target
			for _, node in pairs(build.spec.nodes) do
				if node.path and #node.path == 2 and node.type == "Normal" and not node.alloc then
					target = node
					break
				end
			end
			assert.is_truthy(target)
			local result = callTool("simulate", { add_nodes = { target.id } })
			assert.is_truthy(result.simulated[1]:find("2 points", 1, true))
			assert.is_nil(build.spec.allocNodes[target.id])
		end)

		it("exports XML that opens as the same build", function()
			-- (Deflate and Inflate are stubs when running headless, so share codes are covered by hand.)
			callTool("build_edit", { level = 87 })
			local export = callTool("build_export", { format = "xml" })
			local opened = callTool("build_open", { code = export.xml, discard_unsaved = true })
			assert.are.equals(87, opened.opened.level)
			assert.is_true(opened.opened.unsaved)
		end)

		it("refuses to replace a build with unsaved changes", function()
			build.controls.characterLevel:SetText("50", true)
			local message = toolError("build_open", { new = true })
			assert.is_truthy(message:find("unsaved changes", 1, true))
			local opened = callTool("build_open", { new = true, class = "Witch", ascendancy = "Necromancer", discard_unsaved = true })
			assert.are.equals("Witch", opened.opened.class)
			assert.are.equals("Necromancer", opened.opened.ascendancy)
		end)

		it("edits the level and notes and marks the build unsaved", function()
			build:ResetModFlags()
			local result = callTool("build_edit", { level = 72, notes = "Hello" })
			assert.are.equals(72, result.level)
			assert.are.equals("manual", result.levelMode)
			assert.are.equals("Hello", build.notesTab.controls.edit.buf)
			assert.is_true(build:HasUnsavedChanges())
		end)
	end)
end)
