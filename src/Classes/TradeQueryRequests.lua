-- Path of Building
--
-- Module: Trade Query Requests
-- Handling trade api requests while respecting rate limits
--

local dkjson = require "dkjson"

---@class TradeQueryRequests
local TradeQueryRequestsClass = newClass("TradeQueryRequests", function(self, rateLimiter)
	self.maxFetchPerSearch = 10
	self.tradeQuery = tradeQuery
	self.rateLimiter = rateLimiter or new("TradeQueryRateLimiter")
	self.requestQueue = {
		["search"] = {},
		["fetch"] = {},
	}
	self.hostName = "https://www.pathofexile.com/"
end)

---Main routine for processing request queue
function TradeQueryRequestsClass:ProcessQueue()
	for key, queue in pairs(self.requestQueue) do
		if #queue > 0 then
			local policy = self.rateLimiter:GetPolicyName(key)
			local now = os.time()
			local timeNext = self.rateLimiter:NextRequestTime(policy, now)
			if now >= timeNext then
				local request = table.remove(queue, 1)
				local requestId = self.rateLimiter:InsertRequest(policy)
				local onComplete = function(response, errMsg)
					self.rateLimiter:FinishRequest(policy, requestId)
					self.rateLimiter:UpdateFromHeader(response.header)
					if response.header:match("HTTP/[%d%.]+ (%d+)") == "429" then
						table.insert(queue, 1, request)
						return
					end
					request.callback(response.body, errMsg, unpack(request.callbackParams or {}))
				end
				-- self:SendRequest(request.url , onComplete, {body = request.body, poesessid = main.POESESSID})
				local header = "Content-Type: application/json"
				if main.POESESSID ~= "" then
					header = header .. "\nCookie: POESESSID=" .. main.POESESSID
				end
				launch:DownloadPage(request.url, onComplete, {
					header = header,
					body = request.body, 
				})
			else
				break
			end
		end
	end
end

---Performs search and fetches results
---@param league string
---@param query string
---@param callback fun(items:table, errMsg:string)
---@param params table @ params = { callbackQueryId = fun(queryId:string) }
function TradeQueryRequestsClass:SearchWithQuery(realm, league, query, callback, params)
	params = params or {}
	--ConPrintf("Query json: %s", query)
	self:PerformSearch(realm, league, query, function(response, errMsg)
		if params.callbackQueryId and response and response.id then
			params.callbackQueryId(response.id)
		end
		if errMsg then
			return callback(nil, errMsg)
		end
		self:FetchResults(response.result, response.id, callback)
	end)
end

---Performs search and fetches results, adjusting the query weight and repeating
---the search to fetch more items when the search cap (10k items) is reached
---@param league string
---@param query string
---@param callback fun(items:table, errMsg:string)
---@param params table @ params = { callbackQueryId = fun(queryId:string) }
function TradeQueryRequestsClass:SearchWithQueryWeightAdjusted(realm, league, query, callback, params)
	params = params or {}
	local previousSearchId = nil
	local previousSearchItemIds = nil
	local previousSearchItems = nil
	-- Limit recursion to prevent potential loops
	-- Each repeat is a leap of 10k items, normally we shouldn't need more than 1-2 steps anyways
	local maxRecursion = 5
	local currentRecursion = 0
	local function performSearchCallback(response, errMsg)
		currentRecursion = currentRecursion + 1
		if params.callbackQueryId and response and response.id then
			params.callbackQueryId(response.id)
		end
		if errMsg and ((errMsg == "No Matching Results Found" and currentRecursion >= maxRecursion) or errMsg ~= "No Matching Results Found") then
			return callback(nil, errMsg)
		end
		if (response.total > self.maxFetchPerSearch and response.total < 10000) or currentRecursion >= maxRecursion then
			-- Search not clipped or max recursion reached, fetch results and finalize
			if previousSearchItems and self.maxFetchPerSearch > response.total then
				-- Not enough items in the last search, fill results from previous search
				self:FetchResults(response.result, response.id, function(items, errMsg)
					if errMsg then
						return callback(nil, errMsg)
					end
					local fetchedItemIds = {}
					for _, value in pairs(items) do
						table.insert(fetchedItemIds, value.id)
					end
					for _, value in pairs(previousSearchItems) do
						if #items >= self.maxFetchPerSearch then
							break
						end
						if not isValueInTable(fetchedItemIds, value.id) then
							table.insert(items, value)
							table.insert(fetchedItemIds, value.id)
						end
					end
					local fillCount = self.maxFetchPerSearch - #items
					if fillCount > 0 then
						-- fill with previous search results
						local unfetchedItemIds = {}
						for _, value in pairs(previousSearchItemIds) do
							if #unfetchedItemIds >= fillCount then
								break
							end
							if not isValueInTable(fetchedItemIds, value) then
								table.insert(unfetchedItemIds, value)
							end
						end
						self:FetchResults(unfetchedItemIds, previousSearchId, function(newItems, errMsg)
							if errMsg then
								return callback(nil, errMsg)
							end
							items = tableConcat(items, newItems)
							callback(items, errMsg)
						end)
					else
						callback(items, errMsg)
					end
				end)
			else
				-- Search not clipped and result count satisfy maxFetchPerSearch, proceed normally
				self:FetchResults(response.result, response.id,  callback)
			end
		else
			if response.total < self.maxFetchPerSearch then -- Less than maximum items retrieved lower weight to try and get more.
				local queryJson = dkjson.decode(query)
				queryJson.query.stats[1].value.min = queryJson.query.stats[1].value.min / 2
				query = dkjson.encode(queryJson)
				self:PerformSearch(realm, league, query, performSearchCallback)
			else -- Search clipped, fetch highest weight item, update query weight and repeat search
				previousSearchItemIds = response.result
				previousSearchId = response.id
				local firstResultBatch = {unpack(response.result, 1, math.min(#response.result, 10))}
				self:FetchResults(firstResultBatch, response.id, function(items, errMsg)
					if errMsg then
						return callback(nil, errMsg)
					end
					previousSearchItems = items
					local highestWeight = items[1].weight
					local queryJson = dkjson.decode(query)
					queryJson.query.stats[1].value.min = (tonumber(highestWeight) + queryJson.query.stats[1].value.min) / 2
					query = dkjson.encode(queryJson)
					self:PerformSearch(realm, league, query, performSearchCallback)
				end)
			end
		end
	end
	self:PerformSearch(realm, league, query, performSearchCallback)
end

---Perform search and run callback function on returned item hashes.
---Item info has to be fetched separately 
---@param league string
---@param query string
---@param callback fun(response:table, errMsg:string)
function TradeQueryRequestsClass:PerformSearch(realm, league, query, callback)
	table.insert(self.requestQueue["search"], {
		url = self:buildUrl(self.hostName .. "api/trade/search", realm, league),
		body = query,
		callback = function(response, errMsg)
			if errMsg and not errMsg:find("Response code: 400") then
				return callback(nil, errMsg)
			end
			local response = dkjson.decode(response)
			if not response then
				errMsg = "Failed to Get Trade response"
				return callback(nil, errMsg)
			end
			if not response.result or #response.result == 0 then
				if response.error then
					if not (response.error.code and response.error.message) then
						errMsg = "Encountered unknown error, check console for details."
						ConPrintf("Unknown error: %s", stringify(response.error))
						callback(response, errMsg)
					end
					if response.error.message:find("Logging in will increase this limit") then
						if main.POESESSID ~= "" then
							errMsg = "POESESSID is invalid. Please Re-Log and reset"
						else
							errMsg = "Session is invalid. Please add your POESESSID"
						end
					else
						-- Report unhandled error
						errMsg = "[ " .. response.error.code .. ": " .. response.error.message .. " ]"
					end
				else
					ConPrintf("Found 0 results for " .. self.hostName .. "api/trade/search/" .. league .. "/" .. response.id)
					errMsg = "No Matching Results Found"
				end
				return callback(response, errMsg)
			end
			callback(response, errMsg)
		end,
	})
end

---Fetch item details for itemHashes
---@param itemHashes string[]
---@param queryId string
---@param callback fun(items:table, errMsg:string)
function TradeQueryRequestsClass:FetchResults(itemHashes, queryId, callback)
	local quantity_found = math.min(#itemHashes, self.maxFetchPerSearch)
	local max_block_size = 10
	local items = {}
	for fetch_block_start = 1, quantity_found, max_block_size do
		local fetch_block_end = math.min(fetch_block_start + max_block_size - 1, quantity_found)
		local param_item_hashes = table.concat({unpack(itemHashes, fetch_block_start, fetch_block_end)}, ",")
		local fetch_url = self.hostName .. "api/trade/fetch/"..param_item_hashes.."?query="..queryId
		self:FetchResultBlock(fetch_url, function(itemBlock, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			for _, item in pairs(itemBlock) do
				table.insert(items, item)
			end
			-- finished fetching item blocks
			if #items >= quantity_found then
				callback(items)
			end
		end)
	end
end

---Fetch details for paginated items
---@param url string
---@param callback fun(items: table, errMsg:string)
function TradeQueryRequestsClass:FetchResultBlock(url, callback)
	table.insert(self.requestQueue["fetch"], {
		url = url,
		callback = function(response, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			local response, response_err = dkjson.decode(response)
			if not response or not response.result then
				if response_err then
					errMsg = "JSON Parse Error: " .. (errMsg or "")
				else
					errMsg = "Failed to Get Trade Items: " .. (errMsg or "")
				end
				return callback(nil, errMsg)
			end
			local items = {}
			for _, trade_entry in pairs(response.result) do
				table.insert(items, {
					amount = trade_entry.listing.price.amount,
					currency = trade_entry.listing.price.currency,
					item_string = common.base64.decode(trade_entry.item.extended.text),
					whisper = trade_entry.listing.whisper,
					weight = trade_entry.item.pseudoMods and trade_entry.item.pseudoMods[1]:match("Sum: (.+)") or "0",
					id = trade_entry.id
				})
			end
			return callback(items)
		end
	})
end

---@param callback fun(items:table, errMsg:string)
function TradeQueryRequestsClass:SearchWithURL(url, callback)
	local subpath = url:match(self.hostName .. "trade/search/(.+)$")
	local paths = {}
	for path in subpath:gmatch("[^/]+") do
		table.insert(paths, path)
	end
	if #paths < 2 or #paths > 3 then
		return callback(nil, "Invalid URL")
	end
	local realm, league, queryId
	if #paths == 3 then
		realm = paths[1]
	end
	league = paths[#paths-1]
	queryId = paths[#paths]
	self:FetchSearchQueryHTML(realm, league, queryId, function(query, errMsg)
		if errMsg then
			return callback(nil, errMsg)
		end
		self:SearchWithQuery(realm, league, query, callback)
	end)
end

---Fetch query data needed to perform the search
---@param queryId string
---@param league string
---@param callback fun(query:string, errMsg:string)
function TradeQueryRequestsClass:FetchSearchQuery(realm, league, queryId, callback)
	local url = self:buildUrl(self.hostName .. "api/trade/search", realm, league, queryId)
	table.insert(self.requestQueue["search"], {
		url = url,
		callback = function(response, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			local json_data = dkjson.decode(response)
			if not json_data or json_data.error then
				errMsg = json_data and json_data.error or "Failed to get search query"
			end
			callback(response, errMsg)
		end
	})
end

--- HTML parsing to circumvent extra API call for query fetching
--- queryId -> query fetching via Poe API call costs precious search requests
--- But the search page HTML also contains the query object and this request is not throttled
---@param queryId string
---@param callback fun(query:string, errMsg:string)
---@see TradeQueryRequests#FetchSearchQuery
function TradeQueryRequestsClass:FetchSearchQueryHTML(realm, league, queryId, callback)
	if main.POESESSID == "" then
		return callback(nil, "Please provide your POESESSID")
	end
	local header = "Cookie: POESESSID=" .. main.POESESSID
	launch:DownloadPage(self:buildUrl(self.hostName .. "trade/search", realm, league, queryId),
		function(response, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			-- check if response.header includes "Cache-Control: must-revalidate" which indicates an invalid session
			if response.header:lower():match("cache%-control:.+must%-revalidate") then
				return callback(nil, "Failed to get search query, check POESESSID")
			end
			-- full json state obj from HTML
			local dataStr = response.body:match('require%(%["main"%].+ t%((.+)%);}%);}%);')
			if not dataStr then
				return callback(nil, "JSON object not found on the page.")
			end
			local data, _, err = dkjson.decode(dataStr)
			if err then
				return callback(nil, "Failed to parse JSON object. ".. err)
			end
			local query = { query = data.state }
			if data.state.stats and data.state.stats[1] and data.state.stats[1].type == "weight" then
				query.sort = {}
				query.sort["statgroup.0"] = "desc"
			else
				query.sort = { price = "asc"}
			end
			query.query.status = { option = query.query.status} -- works either way?
			local queryStr = dkjson.encode(query)
			callback(queryStr, errMsg)
		end,
		{header = header})
end

--- Fetches the list of all available leagues using HTML parsing
--- This should get all leagues, including the ones that are not available through API
---
--- example output:
--- result = {
--- 	leagues = [
--- 		{
--- 			"id": "Sanctum",
--- 			"realm": "pc",
--- 			"text": "Sanctum"
--- 		},
---		],
--- 	realms = [
---			{
---			    "id": "sony",
---			    "text": "PS4"
---			},
--- 	]
--- }
---@param callback fun(result:table, errMsg:string)
function TradeQueryRequestsClass:FetchRealmsAndLeaguesHTML(callback)
	if main.POESESSID == "" then
		return callback(nil, "Please provide your POESESSID")
	end
	local header = "Cookie: POESESSID=" .. main.POESESSID
	launch:DownloadPage(
		self.hostName .. "trade",
		function(response, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			-- full json state obj from HTML
			local dataStr = response.body:match('require%(%["main"%].+ t%((.+)%);}%);}%);')
			if not dataStr then
				return callback(nil, "JSON object not found on the page.")
			end
			local data, _, err = dkjson.decode(dataStr)
			if err then
				return callback(nil, "Failed to parse JSON object. ".. err)
			end
			callback({leagues = data.leagues, realms = data.realms}, errMsg)
		end,
		{header = header}
	)
end

--- Fetches the list of all available leagues using poe API
---@param realm string
---@param callback fun(query:table, errMsg:string)
function TradeQueryRequestsClass:FetchLeagues(realm, callback)
	launch:DownloadPage(
		self.hostName .. "api/leagues?compact=1&realm=" .. realm,
		function(response, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			local json_data = dkjson.decode(response.body)
			if not json_data or json_data.error then
				errMsg = json_data and json_data.error or "Failed to get leagues"
			end
			local leagues = {}
				for _, value in pairs(json_data) do
					if (not value.id:find("SSF") and not value.id:find("Solo")) then
						table.insert(leagues, value.id)
					end
				end
			callback(leagues, errMsg)
		end
	)
end

--- Build search and trade URLs with proper encoding
---@param root string
---@param realm string
---@param league string
---@param queryId string
function TradeQueryRequestsClass:buildUrl(root, realm, league, queryId)
	local result = root
	if realm and realm ~='pc' then
		result = result .. "/" .. realm
	end	
	result = result .. "/" .. league:gsub(" ", "+")
	if queryId then
		result = result .. "/" .. queryId
	end
	return result	
end
