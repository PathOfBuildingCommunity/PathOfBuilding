-- Path of Building
--
-- Sub script: MCP Server
-- A small HTTP server (MCP "Streamable HTTP" transport, JSON responses) that runs in a sub
-- script thread while the MCP switch in the PoB window is on. It does no PoB work itself: every
-- JSON-RPC request is handed to the main thread through MCPHandle(), which runs the tools on the
-- build open in the window and returns the response. Started by Modules/MCPStatus.lua.
--
-- Main-thread functions available here:
--   MCPHandle(remoteAddress, sessionId, httpMethod, body) -> status, body, sessionId   (blocking)
--   MCPEvent(kind, detail)                                                            (fire and forget)
--
local host, port, maxBodySize = ...
maxBodySize = maxBodySize or 8 * 1024 * 1024

local socket = require("socket")
local json = require("dkjson")

local reasons = {
	[200] = "OK", [202] = "Accepted", [204] = "No Content",
	[400] = "Bad Request", [403] = "Forbidden", [404] = "Not Found", [405] = "Method Not Allowed",
	[411] = "Length Required", [413] = "Payload Too Large", [500] = "Internal Server Error",
}

local function respond(client, status, body, extraHeaders)
	body = body or ""
	local lines = {
		string.format("HTTP/1.1 %d %s", status, reasons[status] or "OK"),
		"Connection: close",
		"Cache-Control: no-store",
		"Content-Length: " .. #body,
	}
	if #body > 0 then
		table.insert(lines, "Content-Type: application/json")
	end
	for name, value in pairs(extraHeaders or { }) do
		table.insert(lines, name .. ": " .. value)
	end
	client:send(table.concat(lines, "\r\n") .. "\r\n\r\n" .. body)
end

local function jsonError(id, code, message)
	return json.encode({ jsonrpc = "2.0", id = id, error = { code = code, message = message } })
end

local function readRequest(client)
	local line, err = client:receive("*l")
	if not line then
		return nil, err
	end
	local method, path = line:match("^(%u+)%s+(%S+)%s+HTTP/%d%.%d$")
	if not method then
		return nil, "malformed request line"
	end
	local headers = { }
	while true do
		local header, herr = client:receive("*l")
		if not header then
			return nil, herr
		end
		if header == "" then
			break
		end
		local name, value = header:match("^([^:]+):%s*(.-)%s*$")
		if name then
			headers[name:lower()] = value
		end
	end
	local body = ""
	if (headers["transfer-encoding"] or ""):lower():find("chunked", 1, true) then
		return { method = method, path = path, headers = headers, body = "", chunked = true }
	end
	local length = tonumber(headers["content-length"])
	if length and length > 0 then
		if length > maxBodySize then
			return { method = method, path = path, headers = headers, body = "", tooLarge = true }
		end
		body, err = client:receive(length)
		if not body then
			return nil, err
		end
	end
	return { method = method, path = path, headers = headers, body = body }
end

-- Only pages served from this machine may talk to us (DNS-rebinding protection from the MCP spec)
local function originAllowed(origin)
	if not origin or origin == "" or origin == "null" then
		return true
	end
	return origin:match("^https?://localhost[:/]?") ~= nil or origin:match("^https?://127%.0%.0%.1[:/]?") ~= nil or origin:match("^https?://%[::1%][:/]?") ~= nil
end

-- Build sites whose links load_build accepts; the download has to happen here because the main
-- thread cannot block on the network. Mirrors Modules/BuildSiteTools.lua.
local buildSites = {
	{ "maxroll%.gg/poe/pob/([^%s?#]+)", "https://maxroll.gg/poe/api/pob/%s" },
	{ "pob%.codes/b/([^%s?#]+)", "https://api.pob.codes/%s/raw" },
	{ "pobb%.in/([^%s?#]+)", "https://pobb.in/pob/%s" },
	{ "poe%.ninja/poe1/pob/(%w+)", "https://poe.ninja/poe1/pob/raw/%s" },
	{ "poe%.ninja/pob/(%w+)", "https://poe.ninja/poe1/pob/raw/%s" },
	{ "pastebin%.com/raw/(%w+)", "https://pastebin.com/raw/%s" },
	{ "pastebin%.com/(%w+)", "https://pastebin.com/raw/%s" },
	{ "pastebinp%.com/raw/(%w+)", "https://pastebinp.com/raw/%s" },
	{ "pastebinp%.com/(%w+)", "https://pastebinp.com/raw/%s" },
	{ "rentry%.co/(%w+)", "https://rentry.co/paste/%s/raw" },
	{ "poedb%.tw/pob/([^%s?#/]+)", "https://poedb.tw/pob/%s/raw" },
}

local function rawBuildURL(url)
	for _, site in ipairs(buildSites) do
		local id = url:match(site[1])
		if id then
			return string.format(site[2], id)
		end
	end
	return url
end

local function download(url)
	local ok, curl = pcall(require, "lcurl.safe")
	if not ok or type(curl) ~= "table" then
		return nil, "downloading is not available in this runtime"
	end
	local easy = curl.easy()
	easy:setopt_url(url)
	easy:setopt(curl.OPT_FOLLOWLOCATION, 1)
	easy:setopt(curl.OPT_TIMEOUT, 30)
	easy:setopt_useragent("Path of Building MCP")
	local chunks = { }
	easy:setopt_writefunction(function(data)
		table.insert(chunks, data)
		return true
	end)
	local _, err = easy:perform()
	local code = easy:getinfo(curl.INFO_RESPONSE_CODE)
	easy:close()
	if err then
		return nil, err:msg()
	elseif code ~= 200 then
		return nil, "HTTP " .. tostring(code)
	end
	return table.concat(chunks)
end

--- load_build with a URL: fetch it here and hand the main thread the text instead.
--- Returns the (possibly rewritten) body, or a complete JSON-RPC response when the download failed.
local function prefetchBuild(body)
	local request = json.decode(body)
	if type(request) ~= "table" or request.method ~= "tools/call" or type(request.params) ~= "table" or request.params.name ~= "load_build" then
		return body
	end
	local args = request.params.arguments
	if type(args) ~= "table" or type(args.source) ~= "string" then
		return body
	end
	local url = args.source:match("^%s*(https?://%S+)%s*$")
	if not url then
		return body
	end
	MCPEvent("download", url)
	local text, err = download(rawBuildURL(url))
	if not text then
		local message = string.format("Could not download %s: %s", url, err)
		return body, json.encode({
			jsonrpc = "2.0",
			id = request.id,
			result = { content = { { type = "text", text = message } }, isError = true },
		})
	end
	args.source = text:match("^%s*(.-)%s*$")
	args.source_url = url
	return json.encode(request)
end

local function handleClient(client)
	local request, err = readRequest(client)
	if not request then
		if err ~= "closed" then
			MCPEvent("error", "could not read request: " .. tostring(err))
		end
		return
	end
	local method, path, headers = request.method, request.path, request.headers
	path = path:gsub("%?.*$", "")
	if not originAllowed(headers["origin"]) then
		respond(client, 403, jsonError(nil, -32600, "Origin not allowed"))
		return
	end
	if path ~= "/mcp" and path ~= "/mcp/" and path ~= "/" then
		respond(client, 404, jsonError(nil, -32600, "Not found; the MCP endpoint is /mcp"))
		return
	end
	if method == "OPTIONS" then
		respond(client, 204, nil, { ["Allow"] = "POST, DELETE, OPTIONS" })
		return
	elseif method == "GET" then
		-- No server-initiated stream: every response is sent with the request's reply
		respond(client, 405, jsonError(nil, -32600, "This server does not offer a server-to-client stream; send JSON-RPC requests with POST"), { ["Allow"] = "POST, DELETE, OPTIONS" })
		return
	elseif method ~= "POST" and method ~= "DELETE" then
		respond(client, 405, jsonError(nil, -32600, "Method not allowed"), { ["Allow"] = "POST, DELETE, OPTIONS" })
		return
	end
	if request.chunked then
		respond(client, 411, jsonError(nil, -32600, "Chunked requests are not supported; send Content-Length"))
		return
	elseif request.tooLarge then
		respond(client, 413, jsonError(nil, -32600, "Request body too large"))
		return
	end
	local body = request.body
	local prefetchError
	if method == "POST" and #body > 0 then
		body, prefetchError = prefetchBuild(body)
		if prefetchError then
			respond(client, 200, prefetchError)
			return
		end
	end
	local remote = select(1, client:getpeername()) or "?"
	local status, responseBody, sessionId = MCPHandle(remote, headers["mcp-session-id"] or "", method, body)
	if status == nil then
		-- The main thread is shutting the server down
		return "stop"
	end
	local extra = { }
	if sessionId and sessionId ~= "" then
		extra["Mcp-Session-Id"] = sessionId
	end
	respond(client, status, responseBody, extra)
	MCPEvent("request", string.format("%s %s -> %d (%s)", method, path, status, (body:match('"method"%s*:%s*"([^"]+)"') or "-") .. (body:match('"name"%s*:%s*"([^"]+)"') and (" " .. body:match('"name"%s*:%s*"([^"]+)"')) or "")))
end

local server = assert(socket.tcp())
server:setoption("reuseaddr", true)
local bound, bindErr = server:bind(host, port)
if not bound then
	server:close()
	error(string.format("Could not listen on %s:%d: %s", host, port, tostring(bindErr)), 0)
end
local listening, listenErr = server:listen(16)
if not listening then
	server:close()
	error(string.format("Could not listen on %s:%d: %s", host, port, tostring(listenErr)), 0)
end
-- Short accept timeout: AbortSubScript() can only stop this script between Lua statements
server:settimeout(0.1)
MCPEvent("listening", string.format("%s:%d", host, port))

while true do
	local client = server:accept()
	if client then
		client:settimeout(5)
		local ok, result = pcall(handleClient, client)
		client:close()
		if not ok then
			MCPEvent("error", tostring(result))
		elseif result == "stop" then
			break
		end
	end
end
server:close()
return "stopped"
