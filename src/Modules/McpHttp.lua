-- Path of Building
--
-- Module: MCP HTTP
-- Minimal HTTP/1.1 message handling for the local MCP server (Modules/McpServer).
-- It only parses requests and composes responses; it never touches a socket,
-- so it runs (and is tested) without LuaSocket.
--
local s_format = string.format
local t_concat = table.concat
local t_insert = table.insert

local M = { }

-- Largest request the server accepts. MCP requests are small JSON-RPC
-- messages; the largest realistic one carries a build XML or code.
M.MAX_HEADER_BYTES = 16 * 1024
M.MAX_BODY_BYTES = 8 * 1024 * 1024

local reasonPhrases = {
	[200] = "OK",
	[202] = "Accepted",
	[400] = "Bad Request",
	[401] = "Unauthorized",
	[403] = "Forbidden",
	[404] = "Not Found",
	[405] = "Method Not Allowed",
	[411] = "Length Required",
	[413] = "Content Too Large",
	[415] = "Unsupported Media Type",
	[431] = "Request Header Fields Too Large",
	[500] = "Internal Server Error",
	[501] = "Not Implemented",
	[503] = "Service Unavailable",
}

-- Decode a chunked body. Returns body, rest (bytes after it), or nil if more
-- data is needed, or false, error message.
local function decodeChunked(data)
	local parts = { }
	local pos = 1
	local size = 0
	while true do
		local lineEnd = data:find("\r\n", pos, true)
		if not lineEnd then
			return nil
		end
		local chunkSize = tonumber(data:sub(pos, lineEnd - 1):match("^%s*(%x+)"), 16)
		if not chunkSize then
			return false, "invalid chunk size"
		end
		pos = lineEnd + 2
		if chunkSize == 0 then
			-- Skip trailers until the empty line that ends the message.
			while true do
				local trailerEnd = data:find("\r\n", pos, true)
				if not trailerEnd then
					return nil
				end
				local isEmpty = trailerEnd == pos
				pos = trailerEnd + 2
				if isEmpty then
					return t_concat(parts), data:sub(pos)
				end
			end
		end
		size = size + chunkSize
		if size > M.MAX_BODY_BYTES then
			return false, "body too large"
		end
		if #data < pos + chunkSize + 1 then
			return nil
		end
		t_insert(parts, data:sub(pos, pos + chunkSize - 1))
		pos = pos + chunkSize
		if data:sub(pos, pos + 1) ~= "\r\n" then
			return false, "invalid chunk terminator"
		end
		pos = pos + 2
	end
end

--- Try to read one request from the start of a buffer.
--- @param buffer string Bytes received so far on a connection.
--- @return table|nil request { method, path, version, headers = { [lowercase name] = value }, body }; nil when more bytes are needed
--- @return string|number rest Bytes after the request, or an HTTP status code when the request is malformed
--- @return string? message Explanation of the error, when rest is a status code
function M.ParseRequest(buffer)
	local headerEnd = buffer:find("\r\n\r\n", 1, true)
	if not headerEnd then
		if #buffer > M.MAX_HEADER_BYTES then
			return nil, 431, "request headers too large"
		end
		return nil, nil
	end
	if headerEnd > M.MAX_HEADER_BYTES then
		return nil, 431, "request headers too large"
	end
	local head = buffer:sub(1, headerEnd - 1)
	local requestLine, headerText = head:match("^([^\r\n]*)\r?\n?(.*)$")
	local method, path, version = requestLine:match("^(%u+) (%S+) HTTP/(%d%.%d)$")
	if not method then
		return nil, 400, "malformed request line"
	end
	local headers = { }
	for line in headerText:gmatch("[^\r\n]+") do
		local name, value = line:match("^([^:%s]+):%s*(.-)%s*$")
		if not name then
			return nil, 400, "malformed header line"
		end
		name = name:lower()
		if headers[name] then
			headers[name] = headers[name] .. ", " .. value
		else
			headers[name] = value
		end
	end
	local rest = buffer:sub(headerEnd + 4)
	local body = ""
	local encoding = headers["transfer-encoding"]
	if encoding then
		if not encoding:lower():match("^%s*chunked%s*$") then
			return nil, 501, "unsupported transfer encoding"
		end
		local decoded, after = decodeChunked(rest)
		if decoded == nil then
			return nil, nil
		elseif decoded == false then
			return nil, after == "body too large" and 413 or 400, after
		end
		body, rest = decoded, after
	elseif headers["content-length"] then
		local length = tonumber(headers["content-length"]:match("^%d+$"))
		if not length then
			return nil, 400, "invalid Content-Length"
		end
		if length > M.MAX_BODY_BYTES then
			return nil, 413, "body too large"
		end
		if #rest < length then
			return nil, nil
		end
		body, rest = rest:sub(1, length), rest:sub(length + 1)
	elseif method == "POST" then
		return nil, 411, "Content-Length required"
	end
	return {
		method = method,
		path = path,
		version = version,
		headers = headers,
		body = body,
	}, rest
end

--- Whether the connection stays open after answering this request.
function M.KeepAlive(request)
	local connection = (request.headers["connection"] or ""):lower()
	if request.version == "1.0" then
		return connection:find("keep%-alive") ~= nil
	end
	return connection:find("close") == nil
end

--- Compose an HTTP response.
--- @param status number
--- @param headers table|nil Extra headers, { name = value }
--- @param body string|nil
--- @param keepAlive boolean
function M.FormatResponse(status, headers, body, keepAlive)
	body = body or ""
	local lines = { s_format("HTTP/1.1 %d %s", status, reasonPhrases[status] or "Unknown") }
	local names = { }
	for name in pairs(headers or { }) do
		t_insert(names, name)
	end
	table.sort(names)
	for _, name in ipairs(names) do
		t_insert(lines, name .. ": " .. headers[name])
	end
	t_insert(lines, "Content-Length: " .. #body)
	t_insert(lines, "Cache-Control: no-store")
	t_insert(lines, "Connection: " .. (keepAlive and "keep-alive" or "close"))
	return t_concat(lines, "\r\n") .. "\r\n\r\n" .. body
end

return M
