-- Path of Building
--
-- Module: MCP Status
-- Runs the in-app MCP server and keeps track of the AI clients using it.
--
-- The server itself (MCPServer.lua) is a sub script: a tiny HTTP server on 127.0.0.1 that relays
-- every JSON-RPC request to this module through the MCPHandle() global. Requests are answered
-- here, on the main thread, by Modules/MCPTools.lua acting on the build open in the window.
-- The MCP panel (main:OpenMCPPopup) is the UI for the switch, the port and the client list.
--
local dkjson = require("dkjson")
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local m_floor = math.floor
local m_max = math.max
local os_time = os.time
local s_format = string.format

local MCPStatus = { }

MCPStatus.DEFAULT_PORT = 7390
MCPStatus.HOST = "127.0.0.1"
MCPStatus.ACTIVE_SECONDS = 600 -- sessions silent for longer are shown as idle
MCPStatus.FORGET_SECONDS = 6 * 3600 -- ... and forgotten after this long
MCPStatus.PROTOCOL_VERSIONS = { ["2025-11-25"] = true, ["2025-06-18"] = true, ["2025-03-26"] = true }
MCPStatus.DEFAULT_PROTOCOL_VERSION = "2025-06-18"
MCPStatus.MAX_LOG = 50

function MCPStatus:Init()
	self.tools = self.tools or LoadModule("Modules/MCPTools")
	self.enabled = self.enabled or false
	self.port = tonumber(self.port) or self.DEFAULT_PORT
	self.sessions = self.sessions or { }
	self.connections = self.connections or { }
	self.log = self.log or { }
	self.state = self.state or "stopped" -- stopped | starting | running | error
	self.requestCount = self.requestCount or 0
	if self.enabled and self.state == "stopped" then
		self:Start()
	end
end

-- Server lifecycle ---------------------------------------------------------------

function MCPStatus:Log(line)
	t_insert(self.log, os.date("%H:%M:%S ") .. line)
	while #self.log > self.MAX_LOG do
		table.remove(self.log, 1)
	end
	ConPrintf("MCP: %s", line)
end

function MCPStatus:IsRunning()
	return self.subId ~= nil and (self.state == "running" or self.state == "starting")
end

function MCPStatus:Start()
	if self.subId then
		return true
	end
	local file = io.open("MCPServer.lua", "r")
	if not file then
		self.state = "error"
		self.errMsg = "MCPServer.lua is missing"
		self:Log(self.errMsg)
		return false
	end
	local script = file:read("*a")
	file:close()
	self.port = tonumber(self.port) or self.DEFAULT_PORT
	local id = LaunchSubScript(script, "MCPHandle", "MCPEvent", self.HOST, self.port)
	if not id then
		self.state = "error"
		self.errMsg = "Sub scripts are not available in this runtime"
		self:Log(self.errMsg)
		return false
	end
	self.subId = id
	self.state = "starting"
	self.errMsg = nil
	self.startedAt = os_time()
	launch:RegisterSubScript(id, function(result, errMsg)
		-- The server loop ended: either we stopped it, or it could not start (port in use)
		self.subId = nil
		if self.stopping then
			self.stopping = nil
			self.state = "stopped"
			self:Log("server stopped")
		else
			self.state = "error"
			self.errMsg = errMsg or (result and tostring(result)) or "server exited"
			self:Log("server exited: " .. self.errMsg)
		end
	end)
	-- A failed bind arrives through OnSubError, which goes to the DOWNLOAD/CUSTOM callback with (nil, errMsg)
	self:Log(s_format("starting on %s:%d", self.HOST, self.port))
	return true
end

function MCPStatus:Stop()
	if not self.subId then
		self.state = "stopped"
		return
	end
	self.stopping = true
	AbortSubScript(self.subId)
	-- Aborting discards the sub script's finish callback, so finish up here
	launch.subScripts[self.subId] = nil
	self.subId = nil
	self.stopping = nil
	self.state = "stopped"
	self:Log("server stopped")
end

function MCPStatus:Restart()
	self:Stop()
	if self.enabled then
		self:Start()
	end
end

--- The switch in the panel: starts or stops the server and remembers the choice (saved with the settings).
function MCPStatus:SetEnabled(enabled)
	self.enabled = enabled and true or false
	if self.enabled then
		self:Start()
	else
		self:Stop()
	end
	main:SaveSettings()
end

function MCPStatus:SetPort(port)
	port = tonumber(port)
	if not port or port < 1 or port > 65535 or port ~= m_floor(port) then
		return false
	end
	if port ~= self.port then
		self.port = port
		if self.enabled then
			self:Restart()
		end
		main:SaveSettings()
	end
	return true
end

function MCPStatus:GetURL()
	return s_format("http://%s:%d/mcp", self.HOST, self.port)
end

--- Called by the sub script (fire and forget) with progress and errors.
function MCPStatus:OnEvent(kind, detail)
	if kind == "listening" then
		self.state = "running"
		self.errMsg = nil
		self:Log("listening on " .. tostring(detail))
	elseif kind == "error" then
		self:Log("error: " .. tostring(detail))
	elseif kind == "download" then
		self:Log("downloading " .. tostring(detail))
	elseif kind == "request" then
		self:Log(tostring(detail))
	end
end

-- Sessions ---------------------------------------------------------------------------

local function randomId()
	local chars = { }
	for i = 1, 32 do
		chars[i] = s_format("%x", math.random(0, 15))
	end
	return table.concat(chars)
end

function MCPStatus:NewSession(remote, clientInfo, protocolVersion)
	local session = {
		id = randomId(),
		remote = remote,
		client = clientInfo and clientInfo.name or nil,
		version = clientInfo and clientInfo.version or nil,
		title = clientInfo and clientInfo.title or nil,
		protocolVersion = protocolVersion,
		connected = os_time(),
		lastActivity = os_time(),
		requests = 0,
		calls = 0,
	}
	self.sessions[session.id] = session
	self:Log(s_format("client connected: %s %s (%s)", session.client or "unknown", session.version or "", remote))
	self:RebuildConnectionList()
	return session
end

function MCPStatus:TouchSession(session)
	session.lastActivity = os_time()
	session.requests = session.requests + 1
	local now = os_time()
	for id, other in pairs(self.sessions) do
		if now - other.lastActivity > self.FORGET_SECONDS then
			self.sessions[id] = nil
		end
	end
end

function MCPStatus:CloseSession(session)
	session.closed = os_time()
	self:Log(s_format("client disconnected: %s", session.client or session.id))
	self.sessions[session.id] = nil
	self:RebuildConnectionList()
end

--- Rows for the panel, most recently active first (same table instance, so list controls stay bound).
function MCPStatus:RebuildConnectionList()
	wipeTable(self.connections)
	for _, session in pairs(self.sessions) do
		t_insert(self.connections, session)
	end
	t_sort(self.connections, function(a, b)
		if a.lastActivity ~= b.lastActivity then
			return a.lastActivity > b.lastActivity
		end
		return a.id < b.id
	end)
end

function MCPStatus:CountActive()
	local count = 0
	local now = os_time()
	for _, session in pairs(self.sessions) do
		if now - session.lastActivity <= self.ACTIVE_SECONDS then
			count = count + 1
		end
	end
	return count
end

-- JSON-RPC ------------------------------------------------------------------------------

local function rpcError(id, code, message)
	return { jsonrpc = "2.0", id = id, error = { code = code, message = message } }
end

local function rpcResult(id, result)
	return { jsonrpc = "2.0", id = id, result = result }
end

--- Handles one JSON-RPC message; returns the response table (or nil for notifications) and the session.
function MCPStatus:HandleMessage(message, session, remote)
	local object, array = self.tools.object, self.tools.array
	if type(message) ~= "table" or message.jsonrpc ~= "2.0" or type(message.method) ~= "string" then
		if type(message) == "table" and message.method == nil and (message.result ~= nil or message.error ~= nil) then
			return nil, session -- a response to a request we never send
		end
		return rpcError(type(message) == "table" and message.id or nil, -32600, "Invalid JSON-RPC request"), session
	end
	local method, params, id = message.method, message.params or { }, message.id
	local isNotification = id == nil

	if method == "initialize" then
		local wanted = type(params.protocolVersion) == "string" and params.protocolVersion or nil
		local version = (wanted and self.PROTOCOL_VERSIONS[wanted]) and wanted or self.DEFAULT_PROTOCOL_VERSION
		session = self:NewSession(remote, type(params.clientInfo) == "table" and params.clientInfo or nil, version)
		return rpcResult(id, object({
			protocolVersion = version,
			capabilities = object({ tools = object({ listChanged = false }) }),
			serverInfo = object({ name = "pob", title = "Path of Building", version = tostring(launch.versionNumber) }),
			instructions = self.tools.INSTRUCTIONS,
		})), session
	end
	if isNotification then
		return nil, session -- notifications/initialized, notifications/cancelled, ...
	end
	if method == "ping" then
		return rpcResult(id, object()), session
	elseif method == "tools/list" then
		return rpcResult(id, object({ tools = self.tools.List() })), session
	elseif method == "tools/call" then
		local name = params.name
		if type(name) ~= "string" or not self.tools.Has(name) then
			return rpcError(id, -32602, "Unknown tool '" .. tostring(name) .. "'"), session
		end
		if session then
			session.calls = session.calls + 1
			session.lastTool = name
		end
		local ok, result = self.tools.Call(name, params.arguments)
		if session then
			session.lastError = (not ok) and result or nil
		end
		if ok then
			local text = dkjson.encode(result)
			return rpcResult(id, object({
				content = array({ object({ type = "text", text = text }) }),
				structuredContent = result,
				isError = false,
			})), session
		end
		return rpcResult(id, object({
			content = array({ object({ type = "text", text = result }) }),
			isError = true,
		})), session
	end
	return rpcError(id, -32601, "Method not found: " .. method), session
end

--- Entry point for the sub script: one HTTP request in, (status, body, sessionId) out.
function MCPStatus:Handle(remote, sessionId, httpMethod, body)
	self.requestCount = self.requestCount + 1
	local session = sessionId ~= "" and self.sessions[sessionId] or nil
	if sessionId ~= "" and not session then
		return 404, dkjson.encode(rpcError(nil, -32001, "Unknown or expired session; initialize again")), ""
	end
	if httpMethod == "DELETE" then
		if session then
			self:CloseSession(session)
		end
		return 200, "", ""
	end
	if session then
		self:TouchSession(session)
	end
	local message, _, decodeErr = dkjson.decode(body)
	if message == nil then
		return 400, dkjson.encode(rpcError(nil, -32700, "Parse error: " .. tostring(decodeErr))), ""
	end
	local responses
	local isBatch = type(message) == "table" and getmetatable(message) and getmetatable(message).__jsontype == "array" or (type(message) == "table" and message[1] ~= nil and message.jsonrpc == nil)
	if isBatch then
		responses = self.tools.array()
		for _, item in ipairs(message) do
			local response
			response, session = self:HandleMessage(item, session, remote)
			if response then
				t_insert(responses, response)
			end
		end
		if #responses == 0 then
			responses = nil
		end
	else
		responses, session = self:HandleMessage(message, session, remote)
	end
	local newSessionId = (session and sessionId == "" ) and session.id or ""
	if responses == nil then
		return 202, "", newSessionId
	end
	self:RebuildConnectionList()
	return 200, dkjson.encode(responses), newSessionId
end

-- Globals the sub script calls ------------------------------------------------------

--- Blocking call from the server sub script; must never raise (that would surface as a PoB error prompt).
function MCPHandle(remote, sessionId, httpMethod, body)
	local mcp = main and main.mcp
	if not mcp then
		return 500, '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"MCP is not initialised"}}', ""
	end
	local ok, status, responseBody, newSessionId = pcall(mcp.Handle, mcp, tostring(remote or "?"), tostring(sessionId or ""), tostring(httpMethod or "POST"), tostring(body or ""))
	if not ok then
		mcp:Log("internal error: " .. tostring(status))
		return 500, dkjson.encode(rpcError(nil, -32603, "Internal error: " .. tostring(status))), ""
	end
	return status, responseBody, newSessionId or ""
end

function MCPEvent(kind, detail)
	if main and main.mcp then
		main.mcp:OnEvent(kind, detail)
	end
end

-- Display helpers ------------------------------------------------------------------------

function MCPStatus.FormatAge(seconds)
	if not seconds then
		return "-"
	end
	seconds = m_max(m_floor(seconds), 0)
	if seconds < 60 then
		return seconds .. "s ago"
	elseif seconds < 3600 then
		return m_floor(seconds / 60) .. "m ago"
	elseif seconds < 86400 then
		return m_floor(seconds / 3600) .. "h ago"
	end
	return m_floor(seconds / 86400) .. "d ago"
end

function MCPStatus.FormatTime(epoch)
	if not epoch then
		return "-"
	end
	return os.date("%Y-%m-%d %H:%M:%S", m_floor(epoch))
end

--- Label for the button in the main bar.
function MCPStatus:GetButtonLabel()
	if self.state == "error" then
		return "^1MCP: error"
	elseif not self:IsRunning() then
		return "^8MCP: off"
	end
	local active = self:CountActive()
	if active > 0 then
		return s_format("^x50E050MCP: %d", active)
	end
	return "^7MCP: on"
end

--- Status line shown in the panel.
function MCPStatus:GetStatusText()
	if self.state == "error" then
		return "^1" .. (self.errMsg or "The server could not start.")
	elseif self.state == "starting" then
		return "^7Starting on " .. self:GetURL() .. " ..."
	elseif not self:IsRunning() then
		return "^8Off. AI assistants cannot reach this window."
	end
	local active = self:CountActive()
	if active == 0 then
		return "^7Listening on ^x4040FF" .. self:GetURL() .. "^7, waiting for a client."
	end
	return s_format("^7Listening on ^x4040FF%s^7, ^x50E050%d^7 active client%s.", self:GetURL(), active, active == 1 and "" or "s")
end

--- Command that registers this window's server with Claude Code.
function MCPStatus:GetSetupCommand()
	return "claude mcp add --transport http pob " .. self:GetURL()
end

return MCPStatus
