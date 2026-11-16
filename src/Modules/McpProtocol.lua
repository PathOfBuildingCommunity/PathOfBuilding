-- Path of Building
--
-- Module: MCP Protocol
-- The Model Context Protocol over Streamable HTTP, for the local MCP server
-- (Modules/McpServer). It turns one parsed HTTP request (Modules/McpHttp) into
-- one HTTP response. It does no socket work, so it runs (and is tested)
-- without LuaSocket.
--
-- Two protocol eras are served on the same endpoint, as the specification
-- allows for "dual-era" servers
-- (https://modelcontextprotocol.io/specification/2026-07-28/basic/versioning):
--   * 2026-07-28: stateless. Every request carries its protocol version and the
--     client's capabilities in params._meta and in HTTP headers.
--   * 2025-11-25, 2025-06-18 and 2025-03-26: the client opens with `initialize`.
--     No session id is issued (optional in those versions), so every request
--     is still handled on its own.
-- Responses are always application/json; the server never opens an SSE stream.
--
local dkjson = require("dkjson")
local base64 = require("base64")

local t_insert = table.insert
local t_concat = table.concat
local s_format = string.format

local M = { }

M.MODERN_VERSION = "2026-07-28"
M.LEGACY_VERSIONS = { "2025-11-25", "2025-06-18", "2025-03-26" }
M.ENDPOINT = "/mcp"

-- JSON-RPC error codes
local PARSE_ERROR = -32700
local INVALID_REQUEST = -32600
local METHOD_NOT_FOUND = -32601
local INVALID_PARAMS = -32602
local INTERNAL_ERROR = -32603
local HEADER_MISMATCH = -32020
local UNSUPPORTED_VERSION = -32022

-- How long (ms) a client may reuse list results. They only change when Path of
-- Building is updated.
local LIST_TTL_MS = 5 * 60 * 1000

local META_VERSION = "io.modelcontextprotocol/protocolVersion"
local META_CAPABILITIES = "io.modelcontextprotocol/clientCapabilities"
local META_SERVER_INFO = "io.modelcontextprotocol/serverInfo"

local objectMeta = { __jsontype = "object" }
local arrayMeta = { __jsontype = "array" }

--- Mark a table so it encodes as a JSON object even when empty.
function M.Object(t)
	return setmetatable(t or { }, objectMeta)
end

--- Mark a table so it encodes as a JSON array even when empty.
function M.Array(t)
	return setmetatable(t or { }, arrayMeta)
end

M.null = dkjson.null

function M.Encode(value)
	return dkjson.encode(value)
end

function M.Decode(text)
	-- dkjson marks decoded objects and arrays with __jsontype metatables.
	local value, _, err = dkjson.decode(text, 1, nil)
	return value, err
end

local function isObject(value)
	if type(value) ~= "table" then
		return false
	end
	local meta = getmetatable(value)
	if meta and meta.__jsontype then
		return meta.__jsontype == "object"
	end
	return next(value) == nil or value[1] == nil
end

local function isArray(value)
	if type(value) ~= "table" then
		return false
	end
	local meta = getmetatable(value)
	if meta and meta.__jsontype then
		return meta.__jsontype == "array"
	end
	return next(value) == nil or value[1] ~= nil
end

local function isInteger(value)
	return type(value) == "number" and value == math.floor(value) and value > -math.huge and value < math.huge
end

------------------------------------------------------------------------------
-- Argument validation: the JSON Schema subset the tool schemas use.
------------------------------------------------------------------------------

local function typeMatches(schemaType, value)
	if schemaType == "object" then
		return isObject(value)
	elseif schemaType == "array" then
		return isArray(value)
	elseif schemaType == "string" then
		return type(value) == "string"
	elseif schemaType == "integer" then
		return isInteger(value)
	elseif schemaType == "number" then
		return type(value) == "number"
	elseif schemaType == "boolean" then
		return type(value) == "boolean"
	elseif schemaType == "null" then
		return value == nil
	end
	return true
end

local function describeType(schemaType)
	if type(schemaType) == "table" then
		return t_concat(schemaType, " or ")
	end
	return schemaType
end

local function validate(schema, value, path, errors)
	if type(schema) ~= "table" then
		return
	end
	if schema.anyOf then
		for _, option in ipairs(schema.anyOf) do
			local optionErrors = { }
			validate(option, value, path, optionErrors)
			if not optionErrors[1] then
				return
			end
		end
		t_insert(errors, s_format("%s does not match any allowed form", path))
		return
	end
	if schema.type then
		local ok = false
		if type(schema.type) == "table" then
			for _, schemaType in ipairs(schema.type) do
				ok = ok or typeMatches(schemaType, value)
			end
		else
			ok = typeMatches(schema.type, value)
		end
		if not ok then
			t_insert(errors, s_format("%s must be %s", path, describeType(schema.type)))
			return
		end
	end
	if schema.enum then
		local found = false
		for _, allowed in ipairs(schema.enum) do
			if allowed == value then
				found = true
				break
			end
		end
		if not found then
			local list = { }
			for _, allowed in ipairs(schema.enum) do
				t_insert(list, tostring(allowed))
			end
			t_insert(errors, s_format("%s must be one of: %s", path, t_concat(list, ", ")))
			return
		end
	end
	if type(value) == "number" then
		if schema.minimum and value < schema.minimum then
			t_insert(errors, s_format("%s must be at least %s", path, tostring(schema.minimum)))
		end
		if schema.maximum and value > schema.maximum then
			t_insert(errors, s_format("%s must be at most %s", path, tostring(schema.maximum)))
		end
	elseif type(value) == "string" then
		if schema.minLength and #value < schema.minLength then
			t_insert(errors, s_format("%s must not be empty", path))
		end
		if schema.maxLength and #value > schema.maxLength then
			t_insert(errors, s_format("%s is longer than %d characters", path, schema.maxLength))
		end
	end
	if type(value) == "table" and isArray(value) and schema.items then
		if schema.maxItems and #value > schema.maxItems then
			t_insert(errors, s_format("%s has more than %d entries", path, schema.maxItems))
		end
		for i, item in ipairs(value) do
			validate(schema.items, item, s_format("%s[%d]", path, i - 1), errors)
		end
	end
	if type(value) == "table" and isObject(value) and (schema.properties or schema.required or schema.additionalProperties ~= nil) then
		local properties = schema.properties or { }
		for _, name in ipairs(schema.required or { }) do
			if value[name] == nil then
				t_insert(errors, s_format("%s.%s is required", path, name))
			end
		end
		for name, propertyValue in pairs(value) do
			if properties[name] then
				validate(properties[name], propertyValue, path .. "." .. tostring(name), errors)
			elseif schema.additionalProperties == false then
				local known = { }
				for knownName in pairs(properties) do
					t_insert(known, knownName)
				end
				table.sort(known)
				t_insert(errors, s_format("%s.%s is not a known argument (known: %s)", path, tostring(name), t_concat(known, ", ")))
			elseif type(schema.additionalProperties) == "table" then
				validate(schema.additionalProperties, propertyValue, path .. "." .. tostring(name), errors)
			end
		end
	end
end

--- Check a value against a tool's input schema.
--- @return string|nil error A message listing every problem, or nil when valid
function M.ValidateArguments(schema, value)
	local errors = { }
	validate(schema, value, "arguments", errors)
	if errors[1] then
		return t_concat(errors, "; ")
	end
end

------------------------------------------------------------------------------
-- Server
------------------------------------------------------------------------------

local Server = { }
Server.__index = Server

--- Create a protocol handler.
--- @param options table
---   port number: the port the server listens on (for Host and Origin checks)
---   getToken function: returns the bearer token clients must send
---   serverInfo table: { name, title, version }
---   instructions string: guidance for the client's model
---   tools table: { list = function() -> defs, call = function(def, args, finish) }
---     finish(result) with a JSON-able table, or finish(nil, message) for an error
---   prompts table|nil: { list = function() -> defs, get = function(name, args) -> result | nil, message }
---   resources table|nil: { list = function() -> defs, read = function(uri) -> contents | nil, message }
---   log function|nil: log(method, detail, ok, message) for every handled request
function M.New(options)
	return setmetatable({ options = options }, Server)
end

local function constantTimeEquals(a, b)
	if type(a) ~= "string" or type(b) ~= "string" or #a ~= #b then
		return false
	end
	local diff = 0
	for i = 1, #a do
		diff = bit.bor(diff, bit.bxor(a:byte(i), b:byte(i)))
	end
	return diff == 0
end

-- Header values may be RFC 2047 encoded ("=?base64?...?=") when they carry
-- characters a header cannot (streamable-http, "Mcp-Name").
local function decodeHeaderValue(value)
	if type(value) ~= "string" then
		return value
	end
	local encoded = value:match("^=%?base64%?(.*)%?=$")
	if encoded then
		return base64.decode(encoded)
	end
	return value
end

local function jsonResponse(status, payload, extraHeaders)
	local headers = { ["Content-Type"] = "application/json" }
	for name, value in pairs(extraHeaders or { }) do
		headers[name] = value
	end
	local ok, body = pcall(M.Encode, payload)
	if not ok then
		status = 500
		body = M.Encode({ jsonrpc = "2.0", id = M.null, error = { code = INTERNAL_ERROR, message = "response could not be encoded: " .. tostring(body) } })
	end
	return { status = status, headers = headers, body = body }
end

local function rpcError(id, code, message, data)
	local err = { code = code, message = message }
	if data ~= nil then
		err.data = data
	end
	return { jsonrpc = "2.0", id = id == nil and M.null or id, error = err }
end

local function errorResponse(status, id, code, message, data)
	return jsonResponse(status, rpcError(id, code, message, data))
end

-- Requests from browsers carry an Origin header. Only pages served by this
-- server's own address could be legitimate, and it serves none, but they are
-- accepted so local tooling that sets Origin keeps working. Anything else is
-- refused, which blocks DNS rebinding and cross-site requests.
function Server:OriginAllowed(origin)
	if origin == nil then
		return true
	end
	local host, port = origin:lower():match("^https?://([^/:]+):?(%d*)/?$")
	if not host then
		return false
	end
	if host ~= "127.0.0.1" and host ~= "localhost" then
		return false
	end
	return port == "" or tonumber(port) == self.options.port
end

function Server:HostAllowed(hostHeader)
	if not hostHeader then
		return false
	end
	local host, port = hostHeader:lower():match("^([^:]+):?(%d*)$")
	if host ~= "127.0.0.1" and host ~= "localhost" then
		return false
	end
	return port == "" or tonumber(port) == self.options.port
end

function Server:Authorized(authorization)
	local token = self.options.getToken()
	if not token or token == "" then
		return false
	end
	local given = authorization and authorization:match("^[Bb]earer%s+(%S+)%s*$")
	return constantTimeEquals(given, token)
end

local function isLegacyVersion(version)
	for _, legacy in ipairs(M.LEGACY_VERSIONS) do
		if legacy == version then
			return true
		end
	end
	return false
end

local function supportedVersions()
	local list = { M.MODERN_VERSION }
	for _, legacy in ipairs(M.LEGACY_VERSIONS) do
		t_insert(list, legacy)
	end
	return list
end

function Server:Capabilities()
	local capabilities = { tools = M.Object({ listChanged = false }) }
	if self.options.prompts then
		capabilities.prompts = M.Object({ listChanged = false })
	end
	if self.options.resources then
		capabilities.resources = M.Object({ listChanged = false, subscribe = false })
	end
	return M.Object(capabilities)
end

function Server:ServerInfo()
	local info = self.options.serverInfo
	return M.Object({ name = info.name, title = info.title, version = info.version })
end

-- Tool definitions as sent in tools/list.
local function toolListEntry(def)
	local entry = {
		name = def.name,
		title = def.title,
		description = def.description,
		inputSchema = def.inputSchema,
		annotations = def.annotations,
	}
	if def.outputSchema then
		entry.outputSchema = def.outputSchema
	end
	return entry
end

local function textResult(text, isError)
	return { content = { { type = "text", text = text } }, isError = isError == true }
end

-- A successful tool result: structured content, and the same JSON as text
-- for clients that only read text ("SHOULD also return the serialized JSON").
local function structuredResult(value)
	local ok, text = pcall(M.Encode, value)
	if not ok then
		return textResult("Path of Building produced a result that could not be encoded: " .. tostring(text), true)
	end
	return { content = { { type = "text", text = text } }, structuredContent = value, isError = false }
end

--- Handle one HTTP request; calls respond(response) exactly once, possibly
--- later (tool calls can finish on a later frame).
--- response: { status, headers, body }
function Server:HandleHttp(request, respond)
	local headers = request.headers
	local path = request.path:match("^[^?]*")
	if not self:HostAllowed(headers["host"]) then
		return respond(errorResponse(403, nil, INVALID_REQUEST, "Host header must be 127.0.0.1 or localhost with this server's port"))
	end
	if not self:OriginAllowed(headers["origin"]) then
		return respond(errorResponse(403, nil, INVALID_REQUEST, "Origin not allowed"))
	end
	if path ~= M.ENDPOINT then
		return respond(jsonResponse(404, { error = "not found; the MCP endpoint is " .. M.ENDPOINT }))
	end
	if request.method ~= "POST" then
		-- No server-initiated stream (GET) and no sessions to end (DELETE).
		local response = jsonResponse(405, { error = "only POST is supported" })
		response.headers["Allow"] = "POST"
		return respond(response)
	end
	if not self:Authorized(headers["authorization"]) then
		local response = errorResponse(401, nil, INVALID_REQUEST,
			"missing or wrong bearer token; copy it from Path of Building, Options, MCP server, and send it as 'Authorization: Bearer <token>'")
		response.headers["WWW-Authenticate"] = 'Bearer realm="Path of Building"'
		return respond(response)
	end
	local contentType = (headers["content-type"] or ""):lower()
	if not contentType:match("^application/json") then
		return respond(errorResponse(415, nil, INVALID_REQUEST, "Content-Type must be application/json"))
	end
	local message, decodeErr = M.Decode(request.body)
	if message == nil then
		return respond(errorResponse(400, nil, PARSE_ERROR, "invalid JSON: " .. tostring(decodeErr)))
	end
	if isArray(message) and type(message) == "table" and message[1] ~= nil then
		return respond(errorResponse(400, nil, INVALID_REQUEST, "JSON-RPC batches are not supported; send one message per request"))
	end
	if not isObject(message) or message.jsonrpc ~= "2.0" then
		return respond(errorResponse(400, nil, INVALID_REQUEST, "expected a JSON-RPC 2.0 message"))
	end
	if message.method == nil then
		-- A response to a server request; this server sends none, so there is nothing to match it to.
		return respond({ status = 202, headers = { }, body = "" })
	end
	if type(message.method) ~= "string" then
		return respond(errorResponse(400, message.id, INVALID_REQUEST, "method must be a string"))
	end
	if message.id == nil then
		-- Notifications (notifications/initialized, notifications/cancelled, ...) need no answer.
		return respond({ status = 202, headers = { }, body = "" })
	end
	if type(message.id) ~= "string" and type(message.id) ~= "number" then
		return respond(errorResponse(400, nil, INVALID_REQUEST, "id must be a string or a number"))
	end
	local params = message.params
	if params ~= nil and not isObject(params) then
		return respond(errorResponse(400, message.id, INVALID_REQUEST, "params must be an object"))
	end
	params = params or { }

	local meta = isObject(params._meta) and params._meta or nil
	local modernVersion = meta and meta[META_VERSION]
	local era
	if message.method == "initialize" and not modernVersion then
		era = "legacy"
	elseif modernVersion ~= nil then
		era = "modern"
		local err = self:CheckModernRequest(message, params, meta, headers)
		if err then
			return respond(err)
		end
	else
		era = "legacy"
		local headerVersion = headers["mcp-protocol-version"]
		if headerVersion and headerVersion ~= M.MODERN_VERSION and not isLegacyVersion(headerVersion) then
			return respond(errorResponse(400, message.id, UNSUPPORTED_VERSION, "unsupported protocol version " .. headerVersion,
				{ supported = supportedVersions(), requested = headerVersion }))
		end
		if headerVersion == M.MODERN_VERSION then
			return respond(errorResponse(400, message.id, INVALID_PARAMS,
				"requests for protocol version " .. M.MODERN_VERSION .. " must carry " .. META_VERSION .. " in params._meta"))
		end
	end

	local function finish(result, rpcErr, status)
		if rpcErr then
			local httpStatus = status or 200
			if self.options.log then
				self.options.log(message.method, self:Detail(message.method, params), false, rpcErr.message)
			end
			return respond(jsonResponse(httpStatus, rpcError(message.id, rpcErr.code, rpcErr.message, rpcErr.data)))
		end
		if era == "modern" then
			result.resultType = result.resultType or "complete"
			result._meta = M.Object({ [META_SERVER_INFO] = self:ServerInfo() })
		end
		return respond(jsonResponse(200, { jsonrpc = "2.0", id = message.id, result = result }))
	end

	local ok, err = pcall(self.Dispatch, self, message.method, params, era, finish)
	if not ok then
		finish(nil, { code = INTERNAL_ERROR, message = tostring(err) })
	end
end

-- Validate the request metadata the 2026-07-28 revision requires
-- (basic/index "_meta", transports/streamable-http "Request Metadata Headers").
function Server:CheckModernRequest(message, params, meta, headers)
	local version = meta[META_VERSION]
	if type(version) ~= "string" then
		return errorResponse(400, message.id, INVALID_PARAMS, META_VERSION .. " must be a string")
	end
	if version ~= M.MODERN_VERSION then
		return errorResponse(400, message.id, UNSUPPORTED_VERSION, "unsupported protocol version " .. version,
			{ supported = supportedVersions(), requested = version })
	end
	if not isObject(meta[META_CAPABILITIES]) then
		return errorResponse(400, message.id, INVALID_PARAMS, META_CAPABILITIES .. " is required in params._meta")
	end
	local headerVersion = headers["mcp-protocol-version"]
	if headerVersion ~= version then
		return errorResponse(400, message.id, HEADER_MISMATCH,
			s_format("MCP-Protocol-Version header (%s) does not match params._meta (%s)", tostring(headerVersion), version))
	end
	if decodeHeaderValue(headers["mcp-method"]) ~= message.method then
		return errorResponse(400, message.id, HEADER_MISMATCH,
			s_format("Mcp-Method header (%s) does not match the method (%s)", tostring(headers["mcp-method"]), message.method))
	end
	local nameField = (message.method == "tools/call" or message.method == "prompts/get") and "name"
		or message.method == "resources/read" and "uri"
	if nameField then
		local headerName = decodeHeaderValue(headers["mcp-name"])
		if headerName ~= params[nameField] then
			return errorResponse(400, message.id, HEADER_MISMATCH,
				s_format("Mcp-Name header (%s) does not match params.%s (%s)", tostring(headerName), nameField, tostring(params[nameField])))
		end
	end
end

-- A short description of a request for the activity log.
function Server:Detail(method, params)
	if method == "tools/call" or method == "prompts/get" then
		return params.name
	elseif method == "resources/read" then
		return params.uri
	end
end

local function cacheable(result)
	result.ttlMs = LIST_TTL_MS
	-- Results are only served to clients holding this installation's token.
	result.cacheScope = "private"
	return result
end

function Server:Dispatch(method, params, era, finish)
	local options = self.options
	local modern = era == "modern"
	if method == "initialize" then
		local requested = params.protocolVersion
		local version = isLegacyVersion(requested) and requested or M.LEGACY_VERSIONS[1]
		local result = {
			protocolVersion = version,
			capabilities = self:Capabilities(),
			serverInfo = self:ServerInfo(),
			instructions = options.instructions,
		}
		if options.log then
			options.log(method, requested, true)
		end
		return finish(result)
	elseif method == "server/discover" then
		if not modern then
			return finish(nil, { code = METHOD_NOT_FOUND, message = "server/discover requires protocol version " .. M.MODERN_VERSION })
		end
		local result = cacheable({
			supportedVersions = supportedVersions(),
			capabilities = self:Capabilities(),
			instructions = options.instructions,
		})
		return finish(result)
	elseif method == "ping" and not modern then
		return finish(M.Object())
	elseif method == "tools/list" then
		local tools = { }
		for _, def in ipairs(options.tools.list()) do
			t_insert(tools, toolListEntry(def))
		end
		local result = { tools = M.Array(tools) }
		return finish(modern and cacheable(result) or result)
	elseif method == "tools/call" then
		local name = params.name
		local def
		for _, candidate in ipairs(options.tools.list()) do
			if candidate.name == name then
				def = candidate
				break
			end
		end
		if not def then
			return finish(nil, { code = INVALID_PARAMS, message = "Unknown tool: " .. tostring(name) })
		end
		local args = params.arguments
		if args == nil then
			args = M.Object()
		end
		local function done(result, errMessage)
			if options.log then
				options.log(method, name, errMessage == nil, errMessage)
			end
			if errMessage ~= nil then
				return finish(textResult(tostring(errMessage), true))
			end
			return finish(structuredResult(result))
		end
		local invalid = M.ValidateArguments(def.inputSchema, args)
		if invalid then
			return done(nil, "Invalid arguments: " .. invalid)
		end
		return options.tools.call(def, args, done)
	elseif method == "prompts/list" and options.prompts then
		local prompts = { }
		for _, def in ipairs(options.prompts.list()) do
			t_insert(prompts, { name = def.name, title = def.title, description = def.description, arguments = def.arguments })
		end
		local result = { prompts = M.Array(prompts) }
		return finish(modern and cacheable(result) or result)
	elseif method == "prompts/get" and options.prompts then
		local result, err = options.prompts.get(params.name, params.arguments or { })
		if not result then
			return finish(nil, { code = INVALID_PARAMS, message = err })
		end
		if options.log then
			options.log(method, params.name, true)
		end
		return finish(result)
	elseif method == "resources/list" and options.resources then
		local result = { resources = M.Array(options.resources.list()) }
		return finish(modern and cacheable(result) or result)
	elseif method == "resources/templates/list" and options.resources then
		local result = { resourceTemplates = M.Array() }
		return finish(modern and cacheable(result) or result)
	elseif method == "resources/read" and options.resources then
		local contents, err = options.resources.read(params.uri)
		if not contents then
			return finish(nil, { code = INVALID_PARAMS, message = err or "Resource not found", data = { uri = params.uri } })
		end
		local result = { contents = M.Array(contents) }
		if modern then
			-- The open build changes as the user works.
			result.ttlMs = 0
			result.cacheScope = "private"
		end
		return finish(result)
	end
	return finish(nil, { code = METHOD_NOT_FOUND, message = "Method not found: " .. method }, modern and 404 or 200)
end

return M
