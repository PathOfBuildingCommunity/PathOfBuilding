local base64 = require("base64")
local sha = require("sha2")
local dkjson = require "dkjson"

local scopesOAuth = {
	"account:profile",
	"account:leagues",
	"account:characters",
	"account:league_accounts",
	"account:trade"
}

local filename = "poe_api_response.json"

local function identifyingHeader()
	return "User-Agent: OAuth pob/" .. tostring(launch.versionNumber) .. " (contact: https://github.com/PathOfBuildingCommunity/PathOfBuilding/issues)"
end

local function validTokenResponse(response)
	return type(response) == "table" and type(response.access_token) == "string"
		and type(response.refresh_token) == "string" and type(response.expires_in) == "number"
end

local function randomBytes(count)
	local ffi = require("ffi")
	if ffi.os == "Windows" then
		ffi.cdef[[long __stdcall BCryptGenRandom(void*, unsigned char*, unsigned long, unsigned long);]]
		local buffer = ffi.new("unsigned char[?]", count)
		if ffi.load("bcrypt").BCryptGenRandom(nil, buffer, count, 2) ~= 0 then
			error("Could not generate OAuth verifier")
		end
		return ffi.string(buffer, count)
	end
	local file = assert(io.open("/dev/urandom", "rb"), "Could not open OS random source")
	local bytes = file:read(count)
	file:close()
	assert(bytes and #bytes == count, "Could not generate OAuth verifier")
	return bytes
end

---@class PoEAPI
local PoEAPIClass = newClass("PoEAPI")

function PoEAPIClass:PoEAPI(authToken, refreshToken, tokenExpiry, grantedScopes)
	self.retries = 0
	self.authToken = authToken
	self.refreshToken = refreshToken
	self.tokenExpiry = tokenExpiry or 0
	self.grantedScopes = grantedScopes
	self.authGeneration = 0
	self.policyAliases = { }
	self.baseUrl = "https://api.pathofexile.com"
	self.rateLimiter = new("TradeQueryRateLimiter"):TradeQueryRateLimiter()
	self.tokenHasBeenValidated = false

	self.ERROR_NO_AUTH = "No auth token"
	return self
end

-- performs a basic check on the validity of the current login by refreshing the
-- token if necessary. if a refresh is attempted and fails, the login details
-- will be reset.
--- @param callback fun(valid: boolean, errMsg: string?)
function PoEAPIClass:ValidateAuth(callback)
	local generation = self.authGeneration
	if self.authToken and self.refreshToken and self.tokenExpiry then
		ConPrintf("Validating auth token")
		if self.tokenExpiry < os.time() then
			ConPrintf("Auth token expired")
			-- here recreate the token with the refresh_token
			local formText = "client_id=pob&grant_type=refresh_token&refresh_token=" .. self.refreshToken
			launch:DownloadPage("https://www.pathofexile.com/oauth/token", function(response, errMsg)
				if generation ~= self.authGeneration then callback(false, "Authorization changed") return end
				ConPrintf("Recreating auth token")
				if errMsg then
					ConPrintf("Failed to recreate auth token: %s", errMsg)
					self:ResetDetails()
					callback(false, errMsg)
					return
				end
				local responseLua = response and response.body and dkjson.decode(response.body)
				if not validTokenResponse(responseLua) then
					self:ResetDetails()
					callback(false, "Malformed response")
				else
					self.authToken = responseLua.access_token
					self.refreshToken = responseLua.refresh_token
					self.tokenExpiry = os.time() + responseLua.expires_in
					self.grantedScopes = responseLua.scope or self.grantedScopes
					self:UpdateMain()
					callback(true)
				end
				
			end, { body = formText, header = identifyingHeader() })
		else
			callback(true)
		end
	else
		callback(false)
	end
end

--- @param secret string
local function base64_encode(secret)
	return base64.encode(secret):gsub("+", "-"):gsub("/", "_"):gsub("=+$", "")
end

--- resets current authorization details
function PoEAPIClass:ResetDetails()
	self.authGeneration = self.authGeneration + 1
	self.authToken = nil
	self.refreshToken = nil
	self.tokenExpiry = nil
	self.grantedScopes = nil
	self:UpdateMain()
end

--- updates main so that API details are saved across restarts
function PoEAPIClass:UpdateMain()
	main.lastToken = self.authToken
	main.lastRefreshToken = self.refreshToken
	main.tokenExpiry = self.tokenExpiry
	main.grantedScopes = self.grantedScopes
	main:SaveSettings()
end

function PoEAPIClass:HasScope(scope)
	for granted in (self.grantedScopes or ""):gmatch("%S+") do
		if granted == scope then
			return true
		end
	end
	return false
end

--- @param callback fun(errCode: string?)
function PoEAPIClass:FetchAuthToken(callback)
	local generation = self.authGeneration
	local ok, secret = pcall(randomBytes, 48)
	if not ok then
		callback("Could not generate secure OAuth verifier")
		return
	end
	local code_verifier = base64_encode(secret:sub(1, 32))
	local code_challenge = base64_encode(sha.hex_to_bin(sha.sha256(code_verifier)))
	local initialState = base64_encode(secret:sub(33))

	local authUrl = string.format(
		"https://www.pathofexile.com/oauth/authorize?client_id=pob&response_type=code&scope=%s&state=%s&code_challenge=%s&code_challenge_method=S256"
		, table.concat(scopesOAuth, "%20")
		, initialState
		, code_challenge
	)

	local server = io.open("LaunchServer.lua", "r")
	local id = LaunchSubScript(server:read("*a"), "", "ConPrintf,OpenURL,Copy", authUrl)
	server:close()
	if id then
		launch.subScripts[id] = {
			type = "DOWNLOAD",
			callback = function(code, errMsg, state, port)
				if generation ~= self.authGeneration then return end
				if not code then
					ConPrintf("Failed to get code from server: %s", errMsg)
					callback(errMsg or self.ERROR_NO_AUTH)
					return
				end

				if initialState ~= state then
					ConPrintf("OAuth state mismatch during authentication")
					callback("OAuth state mismatch")
					return
				end
				local formText = "client_id=pob&grant_type=authorization_code&code=" ..
				code ..
				"&redirect_uri=http://localhost:" ..
				port .. "&scope=" .. table.concat(scopesOAuth, " ") .. "&code_verifier=" .. code_verifier
				launch:DownloadPage("https://www.pathofexile.com/oauth/token", function(response, errMsg)
					if generation ~= self.authGeneration then return end
					if errMsg then
						ConPrintf("Failed to get token from server: " .. errMsg)
						callback(errMsg)
						return
					end
					local responseLua = response and response.body and dkjson.decode(response.body)
					if not validTokenResponse(responseLua) then
						callback("Malformed authorization response")
						return
					end
					self.authToken = responseLua.access_token
					self.refreshToken = responseLua.refresh_token
					self.tokenExpiry = os.time() + responseLua.expires_in
					self.grantedScopes = responseLua.scope or table.concat(scopesOAuth, " ")
					self.authGeneration = self.authGeneration + 1
					self:UpdateMain()
					self.retries = 0
					SetForeground()
					callback()
				end, { body = formText, header = identifyingHeader() })
			end
		}
	else
		callback("Could not start authorization callback server")
	end
end

--- @param endpoint string
--- @param callback fun(response: table?, errorMsg: string)
function PoEAPIClass:DownloadWithRefresh(endpoint, callback)
	local generation = self.authGeneration
	self:ValidateAuth(function(valid, validationErrMsg)
		if generation ~= self.authGeneration then callback(nil, validationErrMsg or "Authorization changed") return end
		if not valid then
			-- Clean info about token and refresh token
			self:ResetDetails()
			callback(nil, validationErrMsg or self.ERROR_NO_AUTH)
			return
		end

		launch:DownloadPage(self.baseUrl .. endpoint, function(response, errMsg)
			if generation ~= self.authGeneration then callback(nil, "Authorization changed") return end
			if errMsg and errMsg:match("401") and self.retries < 1 then
				-- try once again with refresh token
				self.retries = 1
				self.tokenExpiry = 0
				self:DownloadWithRefresh(endpoint, callback)
			else
				self.retries = 0
				if errMsg then
					ConPrintf("Failed to download %s: %s", endpoint, errMsg)
				elseif response and response.body and launch.devMode and not endpoint:match("^/league%-account") and endpoint ~= "/profile" then
					-- create the file and log the name file
					local file = io.open(filename, "w")
					if file then
						file:write(response.body)
						file:close()
					end
					ConPrintf("Download %s:\n%s\n", endpoint, filename)
				end
				callback(response, errMsg)
			end
		end, { header = "Authorization: Bearer " .. self.authToken .. "\r\n" .. identifyingHeader() })
	end)
end

--- @alias DownloadCallback fun(body: table?, err: string?, timeout: integer?)
--- @param policy string
--- @param url string
--- @param callback DownloadCallback
function PoEAPIClass:DownloadWithRateLimit(policy, url, callback)
	local requestedPolicy = policy
	policy = self.policyAliases[policy] or policy
	local now = os.time()
	local timeNext = self.rateLimiter:NextRequestTime(policy, now)
	if now >= timeNext then
		local requestId = self.rateLimiter:InsertRequest(policy)
		local onComplete = function(response, errMsg)
			self.rateLimiter:FinishRequest(policy, requestId)
			local header = response and response.header or ""
			self.rateLimiter:UpdateFromHeader(header, policy)
			local reportedPolicy = self.rateLimiter:ParseHeader(header)["x-rate-limit-policy"] or policy
			self.policyAliases[requestedPolicy] = reportedPolicy
			if header:match("HTTP/[%d%.]+ (%d+)") == "429" or (errMsg and errMsg:match("429")) then
				timeNext = self.rateLimiter:NextRequestTime(reportedPolicy, os.time())
				callback(nil, "Response code: 429", timeNext)
				return
			end
			if errMsg then
				callback(response, errMsg, nil)
				return
			end
			local responseLua = response and response.body and dkjson.decode(response.body)
			if type(responseLua) ~= "table" then
				callback(nil, "Malformed API response")
				return
			end
			callback(responseLua, errMsg, nil)
		end
		self:DownloadWithRefresh(url, onComplete)
	else
		callback(nil, "Response code: 429", timeNext)
	end
end

---Fetches character list from PoE's OAuth api
---@param realm string Realm to fetch the list from
---@param callback DownloadCallback
function PoEAPIClass:DownloadCharacterList(realm, callback)
	self:DownloadWithRateLimit("character-list-request-limit",
		"/character" .. (realm == "pc" and "" or "/" .. realm), callback)
end

---Fetches character from PoE's OAuth api
---@param realm string Realm to fetch the character from
---@param name string Character name to fetch
---@param callback DownloadCallback
function PoEAPIClass:DownloadCharacter(realm, name, callback)
	self:DownloadWithRateLimit("character-request-limit",
		"/character" .. (realm == "pc" and "" or "/" .. realm) .. "/" .. name, callback)
end

---Fetches league-account data from PoE's OAuth api
---@param realm string Realm to fetch the league account from
---@param league string League name
---@param callback DownloadCallback
function PoEAPIClass:DownloadLeagueAccount(realm, league, callback)
	if not self:HasScope("account:league_accounts") then
		callback(nil, "Authorize Mercenary access")
		return
	end
	if realm ~= "pc" and realm ~= "xbox" and realm ~= "sony" then
		callback(nil, "Unsupported realm")
		return
	end
	if type(league) ~= "string" or league == "" then
		callback(nil, "Character has no league")
		return
	end
	self:DownloadWithRateLimit("league-account-request-limit",
		"/league-account" .. (realm == "pc" and "" or "/" .. realm) .. "/" .. urlEncode(league), callback)
end

---Fetches the authorized account profile
---@param callback DownloadCallback
function PoEAPIClass:DownloadProfile(callback)
	self:DownloadWithRateLimit("profile-request-limit", "/profile", callback)
end
