-- Start a server
local socket = require("socket")
local server = assert(socket.bind("*", 49082) or socket.bind("*", 49083) or socket.bind("*", 49084))
server:settimeout(30)
local host, port = server:getsockname()
ConPrintf("Server started on %s:%s", host, port)

local code, state
local client = server:accept()
if client then
	client:settimeout(10)
	local request, err = client:receive("*l")
	
	if not err and request then
		local _, _, method, path, version = request:find("^(%S+)%s(%S+)%s(%S+)")
		if method ~= "GET" then
			return
		end
		local queryParams = {}
		for k, v in path:gmatch("(%w+)=(%w+)") do
			queryParams[k] = v
		end

		client:send("200\r\n")
		code = queryParams["code"]
		state = queryParams["state"]
	end
	client:close()
end
return code, state, port
