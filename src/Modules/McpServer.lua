-- Path of Building
--
-- Module: MCP Server
-- A local Model Context Protocol server, so MCP clients can read and drive the
-- build open in Path of Building. Off by default; enabled from Options.
--
-- It listens on 127.0.0.1 only, speaks Streamable HTTP (Modules/McpHttp,
-- Modules/McpProtocol) and requires a bearer token that is stored in
-- Settings.xml. Sockets are non-blocking and polled once per frame from
-- main:OnFrame, so every tool runs on the main thread between frames, using
-- the same objects the UI uses (Modules/McpTools).
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local m_min = math.min
local s_format = string.format

local McpHttp = LoadModule("Modules/McpHttp")
local McpProtocol = LoadModule("Modules/McpProtocol")

local DEFAULT_PORT = 49290
local MAX_CONNECTIONS = 8
local RECEIVE_BYTES = 64 * 1024
-- A connection with no request in flight is closed after this long.
local IDLE_CONNECTION_S = 120
-- While nobody uses the window, Poll waits for network activity instead of
-- returning at once, longer the longer the window has been idle (see Poll).
local USER_IDLE_MS = 2000
-- Cursor movement only counts as use this soon after a key or click in the
-- window: the cursor also moves over the window's area while another window
-- covers it (a game, for example), which must not keep frames at full rate.
local CURSOR_ENGAGED_MS = 20000
local LOG_SIZE = 50

local server = {
	enabled = false,
	port = DEFAULT_PORT,
	token = nil,
	connections = { },
	log = { },
	requestCount = 0,
}

-- A random token. Lua has no source of secure random numbers, so this hashes
-- several values that differ between runs and machines.
local function newToken()
	local sha = require("sha2")
	local entropy = {
		tostring(os.time()), tostring(os.clock()), tostring(GetTime()), tostring({ }), tostring(server),
		tostring(collectgarbage("count")), tostring(GetCursorPos()), tostring(main and main.userPath),
	}
	math.randomseed(os.time() + math.floor(os.clock() * 1000000) % 1000000)
	for _ = 1, 16 do
		t_insert(entropy, tostring(math.random()))
	end
	return sha.sha256(table.concat(entropy, "|")):sub(1, 48)
end

function server:EnsureToken()
	if not self.token or not self.token:match("^%x+$") or #self.token < 32 then
		self.token = newToken()
	end
	return self.token
end

function server:Url()
	return s_format("http://127.0.0.1:%d%s", self.port, McpProtocol.ENDPOINT)
end

function server:ClientConfig()
	return table.concat({
		'{',
		'  "mcpServers": {',
		'    "path-of-building": {',
		'      "type": "http",',
		'      "url": "' .. self:Url() .. '",',
		'      "headers": { "Authorization": "Bearer ' .. self:EnsureToken() .. '" }',
		'    }',
		'  }',
		'}',
	}, "\n")
end

function server:AddLog(label, ok, message)
	t_insert(self.log, 1, { time = os.time(), label = label, ok = ok, message = message })
	while #self.log > LOG_SIZE do
		t_remove(self.log)
	end
end

function server:LoadSettings(node)
	self.enabled = node.attrib.enabled == "true"
	self.port = tonumber(node.attrib.port) or DEFAULT_PORT
	self.token = node.attrib.token
end

function server:SaveSettings()
	return { elem = "McpServer", attrib = {
		enabled = tostring(self.enabled),
		port = tostring(self.port),
		token = self.token,
	} }
end

-- The tools, prompts and resources (loaded on first use).
function server:GetTools()
	self.tools = self.tools or LoadModule("Modules/McpTools")
	return self.tools
end

-- A protocol handler for the tools, as the listener uses (also used by tests).
function server:NewProtocol(port)
	local tools = self:GetTools()
	return McpProtocol.New({
		port = port,
		getToken = function() return self.token end,
		serverInfo = { name = "path-of-building", title = "Path of Building", version = tostring(launch.versionNumber) },
		instructions = tools.instructions,
		tools = tools.tools,
		prompts = tools.prompts,
		resources = tools.resources,
		log = function(method, detail, ok, message)
			self.requestCount = self.requestCount + 1
			self:AddLog(detail and (method .. " " .. tostring(detail)) or method, ok, message)
		end,
	})
end

function server:Start()
	self:Stop()
	self.error = nil
	local socket = prerequire("socket")
	if not socket then
		self.error = "LuaSocket is not available"
		ConPrintf("MCP server: %s", self.error)
		return false
	end
	self.socket = socket
	self:EnsureToken()
	local listener = socket.tcp()
	local ok, err = listener:bind("127.0.0.1", self.port)
	if ok then
		ok, err = listener:listen(MAX_CONNECTIONS)
	end
	if not ok then
		listener:close()
		self.error = s_format("cannot listen on 127.0.0.1:%d (%s)", self.port, tostring(err))
		ConPrintf("MCP server: %s", self.error)
		return false
	end
	listener:settimeout(0)
	local protocolOk, protocol = pcall(self.NewProtocol, self, self.port)
	if not protocolOk then
		listener:close()
		self.error = "could not load the MCP tools: " .. tostring(protocol)
		ConPrintf("MCP server: %s", self.error)
		return false
	end
	self.listener = listener
	self.protocol = protocol
	-- SimpleGraphic skips OnFrame for a window that is unfocused, not under the
	-- cursor and has no suspended coroutine (ui_main.cpp, ui_main_c::Frame), so
	-- requests would wait until someone touches the window. A coroutine kept
	-- suspended while the server runs keeps frames coming; Poll throttles them
	-- while nobody uses the window.
	self.keepAlive = coroutine.create(function()
		while self.listener do
			coroutine.yield()
		end
	end)
	coroutine.resume(self.keepAlive)
	ConPrintf("MCP server: listening on %s", self:Url())
	self:AddLog("Listening on " .. self:Url(), true)
	return true
end

function server:Stop()
	for _, connection in ipairs(self.connections) do
		pcall(connection.sock.close, connection.sock)
	end
	wipeTable(self.connections)
	if self.listener then
		self.listener:close()
		self.listener = nil
		ConPrintf("MCP server: stopped")
	end
	if self.keepAlive and coroutine.status(self.keepAlive) == "suspended" then
		-- Let it return now that self.listener is nil.
		coroutine.resume(self.keepAlive)
	end
	self.keepAlive = nil
end

-- Apply the enabled flag and port, starting or stopping the listener.
function server:Apply()
	if self.enabled then
		return self:Start()
	end
	self:Stop()
	self.error = nil
	return true
end

function server:IsRunning()
	return self.listener ~= nil
end

function server:StatusText()
	if self.listener then
		return s_format("^2Listening on %s", self:Url())
	elseif self.error then
		return "^1Error: " .. self.error
	end
	return "^8Off"
end

-- Whether someone used the window recently: an input event (key, click,
-- wheel), or the cursor moving inside the window soon after one.
function server:UserActive(inputEvents)
	local now = GetTime()
	if inputEvents and inputEvents[1] then
		self.lastInput = now
		self.lastInputEvent = now
	end
	local x, y = GetCursorPos()
	if x ~= self.lastCursorX or y ~= self.lastCursorY then
		local inside = x and y and main.screenW and x >= 0 and y >= 0 and x < main.screenW and y < main.screenH
		if inside and now - (self.lastInputEvent or -CURSOR_ENGAGED_MS) < CURSOR_ENGAGED_MS then
			self.lastInput = now
		end
		self.lastCursorX, self.lastCursorY = x, y
	end
	return now - (self.lastInput or 0) < USER_IDLE_MS
end

-- How long Poll may wait for a request: frames of an idle window cost as much
-- as any other, so their rate drops the longer it stays idle. A request still
-- wakes the wait at once; only the first input after a long idle can take up
-- to a second to show.
function server:IdleWait()
	local idleMs = GetTime() - (self.lastInput or 0)
	if idleMs < 10000 then
		return 0.1
	elseif idleMs < 60000 then
		return 0.5
	end
	return 1
end

-- Long jobs PoB runs as coroutines (item database load, power report, trade
-- generator) want full frame rate.
function server:OtherWorkRunning()
	for co in pairs(coroutine._list()) do
		if co ~= self.keepAlive and coroutine.status(co) == "suspended" then
			return true
		end
	end
	for _, connection in ipairs(self.connections) do
		if connection.busy or connection.out ~= "" or connection.buffer ~= "" then
			return true
		end
	end
	return false
end

local function flush(connection)
	if connection.out == "" then
		return true
	end
	local sent, err, partial = connection.sock:send(connection.out)
	if sent then
		connection.out = ""
		return true
	elseif err == "timeout" then
		connection.out = connection.out:sub((partial or 0) + 1)
		return true
	end
	return false
end

function server:HandleRequest(connection, request)
	connection.busy = true
	local keepAlive = McpHttp.KeepAlive(request)
	local answered = false
	self.protocol:HandleHttp(request, function(response)
		if answered then
			return
		end
		answered = true
		connection.busy = false
		connection.lastActive = os.clock()
		if connection.closed then
			return
		end
		connection.out = connection.out .. McpHttp.FormatResponse(response.status, response.headers, response.body, keepAlive, request.version)
		if not keepAlive then
			connection.closeAfterFlush = true
		end
	end)
end

--- Called once per frame from main:OnFrame.
function server:Poll(inputEvents)
	if not self.listener then
		return
	end
	self.tools.OnFrame()
	local socket = self.socket
	-- With nobody using the window and nothing else to do, wait for a
	-- request here instead of rendering another idle frame at once. select
	-- returns as soon as a connection or request arrives.
	if not self:UserActive(inputEvents) and not self:OtherWorkRunning() then
		local watch = { self.listener }
		for _, connection in ipairs(self.connections) do
			t_insert(watch, connection.sock)
		end
		socket.select(watch, nil, self:IdleWait())
	end
	while true do
		local sock = self.listener:accept()
		if not sock then
			break
		end
		if #self.connections >= MAX_CONNECTIONS then
			sock:close()
		else
			sock:settimeout(0)
			t_insert(self.connections, { sock = sock, buffer = "", out = "", lastActive = os.clock() })
		end
	end
	for i = #self.connections, 1, -1 do
		local connection = self.connections[i]
		local keep = flush(connection)
		if keep and connection.closeAfterFlush and connection.out == "" then
			keep = false
		end
		-- Read what has arrived, unless a request is still being answered:
		-- requests on one connection are answered in order.
		while keep and not connection.busy and not connection.closeAfterFlush do
			local data, err, partial = connection.sock:receive(RECEIVE_BYTES)
			data = data or partial
			if data and data ~= "" then
				connection.buffer = connection.buffer .. data
				connection.lastActive = os.clock()
			end
			if err == "closed" then
				keep = connection.buffer ~= ""
				connection.peerClosed = true
			end
			if not data or data == "" or err then
				break
			end
		end
		if keep and not connection.busy and connection.buffer ~= "" and not connection.closeAfterFlush then
			local request, rest, message = McpHttp.ParseRequest(connection.buffer)
			if request then
				connection.buffer = rest
				self:HandleRequest(connection, request)
				keep = flush(connection)
			elseif rest then
				-- Malformed request: answer and close.
				connection.buffer = ""
				connection.out = connection.out .. McpHttp.FormatResponse(rest, { ["Content-Type"] = "text/plain" }, message, false)
				connection.closeAfterFlush = true
				flush(connection)
			elseif connection.peerClosed then
				keep = false
			end
		end
		if connection.peerClosed and not connection.busy and connection.out == "" and connection.buffer == "" then
			keep = false
		end
		if keep and not connection.busy and os.clock() - connection.lastActive > IDLE_CONNECTION_S then
			keep = false
		end
		if not keep then
			-- A request still being answered is abandoned: its reply is dropped.
			connection.closed = true
			pcall(connection.sock.close, connection.sock)
			t_remove(self.connections, i)
		end
	end
end

------------------------------------------------------------------------------
-- Settings dialog (Options, "Configure...")
------------------------------------------------------------------------------

function server:OpenSettingsPopup()
	local controls = { }
	local enabled = self.enabled
	local port = self.port
	local width = 560

	controls.enabled = new("CheckBoxControl"):CheckBoxControl({ "TOPLEFT", nil, "TOPLEFT" }, { 200, 20, 20 }, "^7Enable MCP server:", function(state)
		enabled = state
	end)
	controls.enabled.state = enabled
	controls.enabled.tooltipText = "Lets MCP clients on this computer read and change the build open in Path of Building.\n"
		.. "Only connections from this computer that send the token below are accepted."

	controls.port = new("EditControl"):EditControl({ "TOPLEFT", nil, "TOPLEFT" }, { 200, 46, 80, 20 }, tostring(port), nil, "%D", 5, function(buf)
		port = tonumber(buf)
	end)
	controls.portLabel = new("LabelControl"):LabelControl({ "RIGHT", controls.port, "LEFT" }, { -4, 0, 0, 16 }, "^7Port:")

	controls.status = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 200, 74, 0, 16 }, function()
		return self:StatusText()
	end)
	controls.statusLabel = new("LabelControl"):LabelControl({ "RIGHT", controls.status, "LEFT" }, { -4, 0, 0, 16 }, "^7Status:")

	controls.token = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 200, 100, 0, 16 }, function()
		local token = self:EnsureToken()
		return "^7" .. token:sub(1, 8) .. "..."
	end)
	controls.tokenLabel = new("LabelControl"):LabelControl({ "RIGHT", controls.token, "LEFT" }, { -4, 0, 0, 16 }, "^7Token:")
	controls.copyToken = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { 290, 98, 90, 20 }, "Copy", function()
		Copy(self:EnsureToken())
	end)
	controls.newToken = new("ButtonControl"):ButtonControl({ "LEFT", controls.copyToken, "RIGHT" }, { 8, 0, 90, 20 }, "New token", function()
		self.token = newToken()
		main:SaveSettings()
	end)
	controls.newToken.tooltipText = "Clients using the old token stop working until their configuration is updated."

	controls.copyConfig = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { 200, 126, 180, 20 }, "Copy client configuration", function()
		Copy(self:ClientConfig())
	end)
	controls.copyConfig.tooltipText = "Copies a JSON configuration with this server's address and token,\n"
		.. "in the 'mcpServers' format most MCP clients read."

	controls.logLabel = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 20, 158, 0, 16 }, function()
		return s_format("^7Recent requests (%d since start):", self.requestCount)
	end)
	local logLines = 10
	for i = 1, logLines do
		controls["log" .. i] = new("LabelControl"):LabelControl({ "TOPLEFT", nil, "TOPLEFT" }, { 28, 160 + i * 18, 0, 14 }, function()
			local entry = self.log[i]
			if not entry then
				return ""
			end
			local text = s_format("^8%s  %s%s", os.date("%H:%M:%S", entry.time), entry.ok and "^7" or "^1", entry.label)
			if entry.message and not entry.ok then
				text = text .. "^8 - " .. entry.message:gsub("\n", " "):sub(1, 60)
			end
			return text
		end)
	end

	local buttonY = 160 + (logLines + 1) * 18 + 12
	controls.save = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { width / 2 - 90, buttonY, 80, 20 }, "Save", function()
		self.enabled = enabled
		self.port = m_min(m_max(port or DEFAULT_PORT, 1024), 65535)
		self:Apply()
		main:SaveSettings()
		main:ClosePopup()
	end)
	controls.close = new("ButtonControl"):ButtonControl({ "TOPLEFT", nil, "TOPLEFT" }, { width / 2 + 10, buttonY, 80, 20 }, "Close", function()
		main:ClosePopup()
	end)
	main:OpenPopup(width, buttonY + 32, "MCP Server", controls, "save", nil, "close")
end

return server
