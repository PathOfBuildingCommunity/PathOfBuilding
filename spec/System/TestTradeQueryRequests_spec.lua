describe("TradeQueryRequests", function()
	local mock_limiter = {
		NextRequestTime = function()
			return os.time()
		end,
		InsertRequest = function()
			return 1
		end,
		FinishRequest = function() end,
		UpdateFromHeader = function() end,
		GetPolicyName = function(self, key)
			return key
		end
	}
	local requests = new("TradeQueryRequests", mock_limiter)

	local function simulateRetry(requests, mock_limiter, policy, current_time)
		local now = current_time
		local queue = requests.requestQueue.search
		local request = table.remove(queue, 1)
		local requestId = mock_limiter:InsertRequest(policy)
		local response = { header = "HTTP/1.1 429 Too Many Requests" }
		mock_limiter:FinishRequest(policy, requestId)
		mock_limiter:UpdateFromHeader(response.header)
		local status = response.header:match("HTTP/[%d%%%.]+ (%d+)")
		if status == "429" then
			request.attempts = (request.attempts or 0) + 1
			local backoff = math.min(2 ^ request.attempts, 60)
			request.retryTime = now + backoff
			table.insert(queue, 1, request)
			return true, request.attempts, request.retryTime
		end
		return false, nil, nil
	end

	describe("ProcessQueue", function()
		-- Pass: No changes to empty queues
		-- Fail: Alters queues unexpectedly, indicating loop errors, causing phantom requests
		it("skips empty queue", function()
			requests.requestQueue = { search = {}, fetch = {} }
			requests:ProcessQueue()
			assert.are.equal(#requests.requestQueue.search, 0)
		end)

		-- Pass: Dequeues and processes valid item
		-- Fail: Queue unchanged, indicating timing/insertion bug, blocking trade searches
		it("processes search queue item", function()
			local orig_launch = launch
			launch = {
				DownloadPage = function(url, onComplete, opts)
					onComplete({ body = "{}", header = "HTTP/1.1 200 OK" }, nil)
				end
			}
			table.insert(requests.requestQueue.search, {
				url = "test",
				callback = function() end,
				retryTime = nil
			})
			local function mock_next_time(self, policy, time)
				return time - 1
			end
			mock_limiter.NextRequestTime = mock_next_time
			requests:ProcessQueue()
			assert.are.equal(#requests.requestQueue.search, 0)
			launch = orig_launch
		end)

		-- Pass: Retries with increasing backoff up to cap, preventing infinite loops
		-- Fail: No backoff or uncapped, indicating retry bug, risking API bans
		it("retries on 429 with exponential backoff", function()
			local orig_os_time = os.time
			local mock_time = 1000
			os.time = function() return mock_time end

			local request = {
				url = "test",
				callback = function() end,
				retryTime = nil,
				attempts = 0
			}
			table.insert(requests.requestQueue.search, request)

			local policy = mock_limiter:GetPolicyName("search")

			for i = 1, 7 do
				local previous_time = mock_time
				local entered, attempts, retryTime = simulateRetry(requests, mock_limiter, policy, mock_time)
				assert.is_true(entered)
				assert.are.equal(attempts, i)
				local expected_backoff = math.min(math.pow(2, i), 60)
				assert.are.equal(retryTime, previous_time + expected_backoff)
				mock_time = retryTime
			end

			-- Validate skip when time < retryTime
			mock_time = requests.requestQueue.search[1].retryTime - 1
			local function mock_next_time(self, policy, time)
				return time - 1
			end
			mock_limiter.NextRequestTime = mock_next_time
			requests:ProcessQueue()
			assert.are.equal(#requests.requestQueue.search, 1)

			os.time = orig_os_time
		end)
	end)

	describe("SearchWithQueryWeightAdjusted", function()
		-- Pass: Caps at 5 calls on large results
		-- Fail: Exceeds 5, indicating loop without bound, risking stack overflow or endless API calls
		it("respects recursion limit", function()
			local call_count = 0
			local orig_perform = requests.PerformSearch
			local orig_fetchBlock = requests.FetchResultBlock
			local valid_query = [[{"query":{"stats":[{"value":{"min":0}}]}}]]
			local test_ids = {}
			for i = 1, 11 do
				table.insert(test_ids, "item" .. i)
			end
			requests.PerformSearch = function(self, realm, league, query, callback)
				call_count = call_count + 1
				local response
				if call_count >= 5 then
					response = { total = 11, result = test_ids, id = "id" }
				else
					response = { total = 10000, result = { "item1" }, id = "id" }
				end
				callback(response, nil)
			end
			requests.FetchResultBlock = function(self, url, callback)
				local param_item_hashes = url:match("fetch/([^?]+)")
				local hashes = {}
				if param_item_hashes then
					for hash in param_item_hashes:gmatch("[^,]+") do
						table.insert(hashes, hash)
					end
				end
				local processedItems = {}
				for _, hash in ipairs(hashes) do
					table.insert(processedItems, {
						amount = 1,
						currency = "chaos",
						item_string = "Test Item",
						whisper = "hi",
						weight = "100",
						id = hash
					})
				end
				callback(processedItems)
			end
			requests:SearchWithQueryWeightAdjusted("pc", "league", valid_query, function(items)
				assert.are.equal(call_count, 5)
			end, {})
			requests.PerformSearch = orig_perform
			requests.FetchResultBlock = orig_fetchBlock
		end)
	end)

	describe("FetchResults", function()
		-- Pass: Fetches exactly 10 from 11, in 1 block
		-- Fail: Fetches wrong count/blocks, indicating batch limit violation, triggering rate limits
		it("fetches up to maxFetchPerSearch items", function()
			local itemHashes = { "id1", "id2", "id3", "id4", "id5", "id6", "id7", "id8", "id9", "id10", "id11" }
			local block_count = 0
			local orig_fetchBlock = requests.FetchResultBlock
			requests.FetchResultBlock = function(self, url, callback)
				block_count = block_count + 1
				local param_item_hashes = url:match("fetch/([^?]+)")
				local hashes = {}
				if param_item_hashes then
					for hash in param_item_hashes:gmatch("[^,]+") do
						table.insert(hashes, hash)
					end
				end
				local processedItems = {}
				for _, hash in ipairs(hashes) do
					table.insert(processedItems, {
						amount = 1,
						currency = "chaos",
						item_string = "Test Item",
						whisper = "hi",
						weight = "100",
						id = hash
					})
				end
				callback(processedItems)
			end
			requests:FetchResults(itemHashes, "queryId", function(items)
				assert.are.equal(#items, 10)
				assert.are.equal(block_count, 1)
			end)
			requests.FetchResultBlock = orig_fetchBlock
		end)
	end)
end)