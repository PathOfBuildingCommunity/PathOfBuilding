-- Path of Building
--
-- Module: Trade Query Requests
-- Handling trade api requests while respecting rate limits
--

local dkjson = require "dkjson"

---@class TradeQueryRequests
local TradeQueryRequestsClass = newClass("TradeQueryRequests", function(self, tradeQuery, rateLimiter)
	self.maxFetchPerSearch = 10
	self.tradeQuery = tradeQuery
    self.rateLimiter = rateLimiter or new("TradeQueryRateLimiter")
    self.requestQueue = {
		["search"] = {},
		["fetch"] = {},
	}
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
function TradeQueryRequestsClass:SearchWithQuery(league, query, callback, params)
	params = params or {}
	--ConPrintf("Query json: %s", query)
	self:PerformSearch(league, query, function(response, errMsg)
		if params.callbackQueryId and response and response.id then
			params.callbackQueryId(response.id)
		end
		if errMsg then
			return callback(nil, errMsg)
		end
		self:FetchResults(response.result, response.id, callback)
	end)
end

---Perform search and run callback function on returned item hashes.
---Item info has to be fetched separately 
---@param league string
---@param query string
---@param callback fun(response:table, errMsg:string)
function TradeQueryRequestsClass:PerformSearch(league, query, callback)
	table.insert(self.requestQueue["search"], {
		url = "https://www.pathofexile.com/api/trade/search/"..league,
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
					if response.error.code == 2 then
						if main.POESESSID ~= "" then
							errMsg = "POESESSID is invalid. Please Re-Log and reset"
						else
							errMsg = "Complex Query - Please provide your POESESSID"
						end
					elseif response.error.message then
						errMsg = response.error.message
					end
				else
					ConPrintf("Found 0 results for " .. "https://www.pathofexile.com/trade/search/" .. league .. "/" .. response.id)
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
		local fetch_url = "https://www.pathofexile.com/api/trade/fetch/"..param_item_hashes.."?query="..queryId
		self:FetchResultBlock(fetch_url, function(itemBlock, errMsg)
			if errMsg then
				return callback(nil, errMsg)
			end
			for _, item in pairs(itemBlock) do
				table.insert(items, item)
			end
			-- finished fetching item blocks
			if #items == quantity_found then
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
				})
			end
			return callback(items)
		end
	})
end

---@param callback fun(items:table, errMsg:string)
function TradeQueryRequestsClass:SearchWithURL(urlEditControl, callback)
	local _, queryId = urlEditControl.buf:match("https://www.pathofexile.com/trade/search/(.+)/(.+)$")
	self:FetchSearchQueryHTML(queryId, function(query, errMsg)
		if errMsg then
			return callback(nil, errMsg)
		end
		urlEditControl:SetText("https://www.pathofexile.com/trade/search/" .. self.tradeQuery.pbLeagueRealName .. "/" .. queryId)
		self:SearchWithQuery(self.tradeQuery.pbLeagueRealName, query, callback)
	end)
end

---Fetch query data needed to perform the search
---@param queryId string
---@param league string
---@param callback fun(query:string, errMsg:string)
function TradeQueryRequestsClass:FetchSearchQuery(queryId, callback)
	local url = "https://www.pathofexile.com/api/trade/search/" .. self.tradeQuery.pbLeagueRealName .. "/" .. queryId
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
function TradeQueryRequestsClass:FetchSearchQueryHTML(queryId, callback)
	if main.POESESSID == "" then
		return callback(nil, "Please provide your POESESSID")
	end
	local header = "Cookie: POESESSID=" .. main.POESESSID
	-- the league doesn't affect query so we set it to Standard as it doesn't change
	launch:DownloadPage("https://www.pathofexile.com/trade/search/" .. self.tradeQuery.pbLeagueRealName .. "/" .. queryId, 
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
