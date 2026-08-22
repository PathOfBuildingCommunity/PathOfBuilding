describe("TradeQueryRequests", function()
	local dkjson = require "dkjson"
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
	local requests = new("TradeQueryRequests"):TradeQueryRequests(mock_limiter)

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

		-- Pass: Does not crash on 401, and passes error message
		-- Fail: Crash, or returned error is wrong
		it("does not crash on 401", function()
			local json = '"{"error":"invalid_token","error_description":"The access token provided is invalid or has expired"}"'
			local header = [[HTTP/1.1 401 Unauthorized
Date: Fri, 24 Apr 2026 07:30:38 GMT
Content-Type: application/json
Transfer-Encoding: chunked
Connection: keep-alive
Server: cloudflare
WWW-Authenticate: Bearer realm="pathofexile:production", error="invalid_token", error_description="The access token provided is invalid or has expired"
Cache-Control: no-store
Strict-Transport-Security: max-age=63115200; includeSubDomains; preload]]
		local orig_launch = launch
			launch = {
				DownloadPage = function(url, onComplete, opts)
					onComplete({ body = json, header = header }, nil)
				end
			}
			table.insert(requests.requestQueue.search, {
				url = "test",
				callback = function(body, msg)
					assert.are.equal(body, json)
					assert.are.equal(msg, "Response code: 401\nAuthorization is invalid. Please Re-Log and reset")
				end,
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

	describe("FetchResultBlock", function()
		it("preserves item influences in reconstructed item strings", function()
			local response = dkjson.encode({
				result = {
					{
						id = "influenced",
						listing = {
							price = { amount = 1, currency = "chaos", type = "~price" },
							whisper = "hi",
							account = { name = "seller" },
						},
						item = {
							rarity = "Rare",
							name = "Test Subject",
							typeLine = "Astral Plate",
							influences = {
								shaper = true,
								elder = true,
								warlord = true,
								hunter = true,
								crusader = true,
								redeemer = true,
							},
							searing = true,
							tangled = true,
						},
					},
				},
			})
			local fetchedItems
			requests.requestQueue.fetch = { }
			requests:FetchResultBlock("test", function(items)
				fetchedItems = items
			end)

			local request = table.remove(requests.requestQueue.fetch, 1)
			request.callback(response)

			local item = new("Item"):Item(fetchedItems[1].item_string)
			for _, influenceInfo in ipairs(itemLib.influenceInfo.all) do
				assert.is_true(item[influenceInfo.key], influenceInfo.display)
			end
		end)

		local function makeExplicitMod(description, domain, hash, name, tier, min, max, flags)
			return {
				description = description, domain = domain, hash = "stat." .. hash, flags = flags,
				mods = { { name = name, tier = tier, level = 44,
					magnitudes = { { min = tostring(min), max = tostring(max) } } } },
			}
		end

		local function makeStandaloneItem(domain)
			domain = domain or "explicit"
			local hash = domain .. ".fire_resistance"
			return {
				rarity = "Rare", name = "Test Subject", typeLine = "Coral Ring",
				explicitMods = { makeExplicitMod("+17% to Fire Resistance", domain, hash,
					"of the Salamander", "S7", 12, 17, domain == "crafted" and { crafted = true } or nil) },
				extended = { hashes = { [domain] = { { hash, { 0 } } } } },
			}
		end

		local function makeTradeEntry(id, item)
			return {
				id = id,
				listing = {
					price = { amount = 1, currency = "chaos", type = "~price" },
					whisper = "private listing text", account = { name = "private account" },
				},
				item = item,
			}
		end

		local function fetchEntries(entries)
			local response = dkjson.encode({ result = entries })
			local fetchedItems
			local callbackError
			requests.requestQueue.fetch = {}
			requests:FetchResultBlock("test", function(items, errMsg)
				fetchedItems = items
				callbackError = errMsg
			end)
			local request = table.remove(requests.requestQueue.fetch, 1)
			request.callback(response)
			assert.is_nil(callbackError)
			return fetchedItems
		end

		local function fetchSingle(item)
			return fetchEntries({ makeTradeEntry("item-id", item) })[1]
		end

		it("reads weighted sums from current and legacy pseudo mods", function()
			local function itemWithPseudoMods(pseudoMods)
				return { pseudoMods = pseudoMods, rarity = "Rare", name = "Test Subject", typeLine = "Astral Plate" }
			end
			local fetchedItems = fetchEntries({
				makeTradeEntry("current", itemWithPseudoMods({ { description = "Sum: 178", domain = "pseudo", hash = "stat.statgroup.0" } })),
				makeTradeEntry("legacy", itemWithPseudoMods({ "Sum: 42" })),
				makeTradeEntry("empty", itemWithPseudoMods({ })),
			})

			local itemsById = { }
			for _, item in ipairs(fetchedItems) do
				itemsById[item.id] = item
			end
			assert.are.equal("178", itemsById.current.weight)
			assert.are.equal("42", itemsById.legacy.weight)
			assert.are.equal("0", itemsById.empty.weight)
		end)

		it("keeps only a compact descriptor for a standalone explicit resistance", function()
			local result = fetchSingle(makeStandaloneItem())

			assert.are.same({ { lineIndex = 1, element = "Fire", domain = "explicit" } },
				result.resistanceSwapDescriptors)
			assert.is_nil(result.explicitMods)
			assert.is_nil(result.extended)
		end)

		it("accepts metadata when the stat hash is nested on the unique mod", function()
			local item = makeStandaloneItem()
			item.explicitMods[1].mods[1].hash = item.explicitMods[1].hash
			item.explicitMods[1].hash = nil

			local result = fetchSingle(item)
			assert.are.equal("Fire", result.resistanceSwapDescriptors[1].element)
		end)

		it("accepts a resistance whose neighbouring affix has a distinct group", function()
			local item = makeStandaloneItem()
			table.insert(item.explicitMods, makeExplicitMod(
				"11% of Physical Damage from Hits taken as Fire Damage", "explicit", "explicit.phys_taken",
				"The Elder's", "P1", 13, 15))
			item.extended.hashes.explicit = {
				{ "explicit.fire_resistance", { 2 } },
				{ "explicit.phys_taken", { 0 } },
			}

			local result = fetchSingle(item)
			assert.are.equal(1, #result.resistanceSwapDescriptors)
			assert.are.equal(1, result.resistanceSwapDescriptors[1].lineIndex)
			local parsedItem = new("Item"):Item(result.item_string)
			assert.are.equal("+17% to Fire Resistance", parsedItem.explicitModLines[1].line)
			assert.are.equal("11% of Physical Damage from Hits taken as Fire Damage", parsedItem.explicitModLines[2].line)
		end)

		it("keeps explicit and crafted affixes separate when their group indices collide", function()
			local item = makeStandaloneItem("crafted")
			table.insert(item.explicitMods, 1, makeExplicitMod(
				"+25 to maximum Life", "explicit", "explicit.life", "Healthy", "P1", 20, 29))
			item.extended.hashes.explicit = { { "explicit.life", { 0 } } }
			local result = fetchSingle(item)

			assert.are.equal("crafted", result.resistanceSwapDescriptors[1].domain)
			assert.are.equal(2, result.resistanceSwapDescriptors[1].lineIndex)
			assert.is_truthy(result.item_string:find("{crafted}%+17%% to Fire Resistance"))
			local parsedItem = new("Item"):Item(result.item_string)
			assert.are.equal("+17% to Fire Resistance", parsedItem.explicitModLines[2].line)
			assert.is_true(parsedItem.explicitModLines[2].crafted)
		end)

		it("rejects unsafe items and incomplete or ambiguous metadata", function()
			local resistanceSwap = LoadModule("Classes/TradeResistanceSwap")
			local function physicalTakenSibling()
				return makeExplicitMod("3% of Physical Damage from Hits taken as Fire Damage", "explicit",
					"explicit.phys_taken", "of Puhuarte", "S0", 3, 5)
			end
			local cases = {
				{ "shared affix group", function(item)
					item.explicitMods[1].mods[1].name = "of Puhuarte"
					item.explicitMods[1].mods[1].tier = "S0"
					table.insert(item.explicitMods, physicalTakenSibling())
					item.extended.hashes.explicit = {
						{ "explicit.fire_resistance", { 0 } }, { "explicit.phys_taken", { 0 } },
					}
				end },
				{ "sibling hash mapping missing", function(item)
					item.explicitMods[1].mods[1].name = "of Puhuarte"
					item.explicitMods[1].mods[1].tier = "S0"
					local sibling = physicalTakenSibling()
					sibling.hash = nil
					table.insert(item.explicitMods, sibling)
				end },
				{ "sibling group and identity missing", function(item)
					local sibling = physicalTakenSibling()
					sibling.hash = nil
					sibling.mods[1].level = nil
					table.insert(item.explicitMods, sibling)
				end },
				{ "fractured", function(item) item.explicitMods[1].flags = { fractured = true } end },
				{ "corrupted", function(item) item.corrupted = true end },
				{ "duplicated", function(item) item.duplicated = true end },
				{ "mirrored", function(item) item.mirrored = true end },
				{ "unmodifiable", function(item) item.unmodifiable = true end },
				{ "unmodifiable except chaos", function(item) item.unmodifiableExceptChaos = true end },
				{ "extended metadata missing", function(item) item.extended = nil end },
				{ "affix metadata missing", function(item) item.explicitMods[1].mods = {} end },
				{ "affix metadata ambiguous", function(item) table.insert(item.explicitMods[1].mods, item.explicitMods[1].mods[1]) end },
				{ "tier missing", function(item) item.explicitMods[1].mods[1].tier = nil end },
				{ "level missing", function(item) item.explicitMods[1].mods[1].level = nil end },
				{ "magnitude missing", function(item) item.explicitMods[1].mods[1].magnitudes = {} end },
				{ "hash index ambiguous", function(item) item.extended.hashes.explicit[1][2] = { 0, 1 } end },
				{ "hash duplicated", function(item) table.insert(item.extended.hashes.explicit, { "explicit.fire_resistance", { 0 } }) end },
			}
			for _, case in ipairs(cases) do
				local item = makeStandaloneItem()
				case[2](item)
				assert.are.same({ }, resistanceSwap.extractDescriptors(item), case[1])
			end
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
