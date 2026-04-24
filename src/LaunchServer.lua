-- Start a server
local url = ...
local socket = require("socket")
local server = assert(socket.bind("*", 49082) or socket.bind("*", 49083) or socket.bind("*", 49084))
local host, port = server:getsockname()
ConPrintf("Server started on %s:%s", host, port)

local redirect_uri = string.format(
	"http://localhost:%d", port
)
ConPrintf("Redirect URI: %s", redirect_uri)
url = url .. string.format("&redirect_uri=%s", redirect_uri)

local commonResponse = [[
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>PoB 2 - Authentication Complete</title>
	<style>
		body {
			font-family: Arial, sans-serif;
			background: #121212;
			color: #fff;
			display: flex;
			justify-content: center;
			align-items: center;
			height: 100vh;
			margin: 0;
		}
		.container {
			display: flex;
			flex-direction: column;
			align-items: center;
		}
		.card {
			background: #1E1E1E;
			padding: 20px;
			border-radius: 10px;
			box-shadow: 0px 4px 10px rgba(255, 255, 255, 0.1);
			width: 90%;
			max-width: 400px;
			text-align: center;
		}
		.card h1 {
			font-size: 24px;
			color: #4CAF50;
			margin-bottom: 10px;
		}
		.card p {
			font-size: 18px;
			margin-bottom: 15px;
		}
		.card code {
			background: #f8d7da;
			color: #721c24;
			padding: 3px 6px;
			border-radius: 4px;
			font-family: monospace;
			display: inline-block;
			margin-bottom: 10px;
		}
		.close-button {
			padding: 10px 20px;
			background: #4CAF50;
			color: white;
			border: none;
			border-radius: 5px;
			cursor: pointer;
			font-size: 16px;
			transition: background 0.3s;
		}
		.close-button:hover {
			background: #45a049;
		}
	</style>
</head>
<body>
	<div class="container">
		<div class="card">
]]

local commonResponseEnd = [[
		</div>
	</div>
</body>
</html>
]]

ConPrintf("Opening URL: %s", url)
OpenURL(url)

--- Handle an incoming socket connection, to complete an OAuth redirect.
--- @param client table @The socket connection to handle, as returned by `server:accept()`.
--- @param attempt number @The number of attempts made to handle an incoming connection. This is used for logging
--- purposes, since spurious issues can be difficult to identify otherwise.
--- @return boolean shouldRetry @Whether we should wait for another connection. If false, we've successfully responded
--- to a HTTP request. Note that, for the purposes of this function, we don't care whether authorization was *granted*,
--- just that the process itself was completed and the user was redirected as intended.
--- @return string? code @The OAuth authorization code. This is exchanged for an access token and refresh token later.
--- @return string? state @The OAuth state string. This is a sentinel value used to ensure that a request hasn't been
--- forged.
function handleConnection(client, attempt)
	local shouldRetry, code, state = true, nil, nil

	local request, err = client:receive("*l")
	if err then
		ConPrintf("Attempt %d to handle incoming connection failed: %s", attempt, err)
	elseif request then
		local response
		local _, _, method, path, version = request:find("^(%S+)%s(%S+)%s(%S+)")
		if method ~= "GET" then
			ConPrintf(
				"Attempt %d to handle incoming connection received an invalid HTTP request: non-GET method %s",
				attempt,
				method
			)

			return true
		end

		local queryParams = {}
		for k, v in path:gmatch("([^&=?]+)=([^&=?]+)") do
			queryParams[k] = v:gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)
		end

		if queryParams["code"] ~= nil then
			response = commonResponse .. [[
			<h1>PoB 2 - Authentication Successful</h1>
			<p>✅ Your authentication is complete! You can now return to the app.</p>
			]] .. commonResponseEnd
			code = queryParams["code"]
			state = queryParams["state"]
		else
			response = commonResponse .. [[
			<h1>PoB 2 - Authentication Failed</h1>
			<p>❌ Authentication failed. Please try again.</p>
			<code>]] .. queryParams["error"] .. ": " .. queryParams["error_description"] .. [[</code>
			]] .. commonResponseEnd
		end

		shouldRetry = false
		if attempt ~= 1 then
			ConPrintf("Attempt %d to handle incoming connection received a valid HTTP request", attempt)
		end

		-- Send HTTP Response
		--ConPrintf("Sending response: %s", response)
		client:send(response)
	end

	return shouldRetry, code, state
end

-- Misbehaving software (think VPNs, anything network-related, even OS services) will occasionally attempt to connect
-- to newly-opened sockets for one reason or another. Previously, PoB only waited for one connection, and gave up
-- immediately if something went wrong.
--
-- This would result in a sequence of events roughly like this:
--   1. PoB opens a socket
--   2. A misbehaving piece of software connects to the socket, sends nothing, then terminates the connection
--   3. PoB tries to read from the socket, receives an error since the connection is terminated, and closes the server
--   4. OAuth authorization succeeds, but by the time the user is redirected back to PoB, the server is already closed
--   5. PoB never receives the OAuth redirect, and doesn't have any of the information necessary to use the API
--
-- To avoid this, we instead allow for any number of incoming connections, and simply stop listening for them once
-- either a) 30 seconds have elapsed or b) we've received a legitimate HTTP request and responded to it.
--
-- Unfortunately, this still isn't perfect: in theory, two applications (such as a browser, and something else) could
-- attempt to establish a connection at the same time. In the future, this could be refactored to perform non-blocking
-- IO, so that it can operate concurrently, but hopefully that isn't necessary.
local attempt = 1
local stopAt = os.time() + 30
local errMsg
local shouldRetry, code, state = true, nil, nil
while (os.time() < stopAt) and shouldRetry do
	-- `settimeout`` applies only to individual operations, but we're more concerned with not spending more than 30
	-- seconds *total* waiting, so we adjust with each iteration as necessary.
	local remainingTime = math.max(0, stopAt - os.time())
	server:settimeout(remainingTime)

	local client = server:accept()
	if not client then
		goto retry
	end

	client:settimeout(5)
	shouldRetry, code, state = handleConnection(client, attempt)
	client:close()

	:: retry ::
	attempt = attempt + 1
end
server:close()
if os.time() >= stopAt then
	errMsg = "Timeout reached without a response received by the local server"
end
return code, errMsg, state, port
