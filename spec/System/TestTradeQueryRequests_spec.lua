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

		it("reads weighted sums from current and legacy pseudo mods", function()
			local function makeTradeEntry(id, pseudoMods)
				return {
					id = id,
					listing = {
						price = { amount = 1, currency = "chaos", type = "~price" },
						whisper = "hi",
						account = { name = "seller" },
					},
					item = {
						pseudoMods = pseudoMods,
						rarity = "Rare",
						name = "Test Subject",
						typeLine = "Astral Plate",
					},
				}
			end
			local response = dkjson.encode({
				result = {
					makeTradeEntry("current", { { description = "Sum: 178", domain = "pseudo", hash = "stat.statgroup.0" } }),
					makeTradeEntry("legacy", { "Sum: 42" }),
					makeTradeEntry("empty", { }),
				},
			})
			local fetchedItems
			local callbackError
			requests.requestQueue.fetch = { }
			requests:FetchResultBlock("test", function(items, errMsg)
				fetchedItems = items
				callbackError = errMsg
			end)

			local request = table.remove(requests.requestQueue.fetch, 1)
			request.callback(response)

			local itemsById = { }
			for _, item in ipairs(fetchedItems) do
				itemsById[item.id] = item
			end
			assert.is_nil(callbackError)
			assert.are.equal("178", itemsById.current.weight)
			assert.are.equal("42", itemsById.legacy.weight)
			assert.are.equal("0", itemsById.empty.weight)
		end)

		it("reconstructs explicit, crafted, and fractured affixes for bench craft replacement", function()
			local function makeTradeApiMod(description, hash, tier, domain)
				return {
					description = description, domain = domain or "explicit", hash = "stat." .. hash,
					mods = { { name = "Test Affix", tier = tier, level = 30 } },
				}
			end
			local response = dkjson.encode({
				result = { {
					id = "affix-metadata",
					listing = { price = { amount = 1, currency = "chaos", type = "~price" },
						whisper = "hi", account = { name = "seller" } },
					item = {
						rarity = "Rare", name = "Test Band", typeLine = "Sapphire Ring",
						explicitMods = {
							makeTradeApiMod("+50 to maximum Life", "explicit.life", "P2"),
							{ description = "+25 to maximum Mana", domain = "fractured", hash = "stat.fractured.mana",
								flags = { fractured = true }, mods = { { name = "Test Affix", tier = "P2", level = 30 } } },
							makeTradeApiMod("20% increased Armour", "explicit.armour", "P2"),
							makeTradeApiMod("+30% to Fire Resistance", "explicit.fire", "S3"),
							makeTradeApiMod("+30% to Cold Resistance", "explicit.cold", "S3"),
							makeTradeApiMod("+20 to Dexterity", "crafted.dexterity", "S3", "crafted"),
							makeTradeApiMod("10% increased Rarity of Items found", "crafted.rarity", "S3", "crafted"),
						},
						extended = { hashes = {
							explicit = {
								{ "explicit.life", { 0 } }, { "explicit.armour", { 0 } },
								{ "explicit.fire", { 1 } }, { "explicit.cold", { 2 } },
							},
							crafted = { { "crafted.dexterity", { 0 } }, { "crafted.rarity", { 0 } } },
							fractured = { { "fractured.mana", { 0 } } },
						} },
					},
				} },
			})
			local fetchedItems
			requests.requestQueue.fetch = { }
			requests:FetchResultBlock("test", function(items) fetchedItems = items end)

			local request = table.remove(requests.requestQueue.fetch, 1)
			request.callback(response)

			local item = new("Item"):Item(fetchedItems[1].item_string)
			local modLines = item.explicitModLines
			assert.are.same({ true, true, true }, { modLines[1].prefix, modLines[2].prefix, modLines[3].prefix })
			assert.are_not.equal(modLines[1].modGroup, modLines[2].modGroup)
			assert.are.equal("trade:fractured:0", modLines[2].modGroup)
			assert.is_true(modLines[2].fractured)
			assert.are.equal(modLines[1].modGroup, modLines[3].modGroup)
			assert.are.same({ true, true, true, true },
				{ modLines[4].suffix, modLines[5].suffix, modLines[6].suffix, modLines[7].suffix })
			assert.are_not.equal(modLines[4].modGroup, modLines[5].modGroup)
			assert.are.same({ true, true }, { modLines[6].crafted, modLines[7].crafted })
			assert.are.equal(modLines[6].modGroup, modLines[7].modGroup)

			local tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = { } })
			local strippedItem = new("Item"):Item(item:BuildRaw())
			for index = #strippedItem.explicitModLines, 1, -1 do
				if strippedItem.explicitModLines[index].crafted then
					table.remove(strippedItem.explicitModLines, index)
				end
			end
			strippedItem = new("Item"):Item(strippedItem:BuildRaw())
			assert.are.same({ Prefix = 1, Suffix = 1 }, tradeQuery:GetBenchCraftAvailability(strippedItem))

			local availability, craftState = tradeQuery:GetBenchCraftAvailability(item)
			assert.is_nil(availability)
			assert.are.same({ count = 1, limit = 1 }, craftState)

			local replacementCraft = { type = "Suffix", group = "Strength",
				modTags = { "attribute" }, types = { Ring = true }, "+(21-25) to Strength" }
			tradeQuery.tradeQueryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = { } })
			tradeQuery.itemsTab.build = { data = { masterMods = { replacementCraft } } }
			tradeQuery.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tradeQuery.slotTables[1] = { slotName = "Ring 1", considerBenchCraft = true }
			tradeQuery.resultTbl[1] = { fetchedItems[1] }
			local evaluation = tradeQuery:GetResultEvaluation(1, 1, function(args)
				local raw = args.repItem:BuildRaw()
				local hasStrengthCraft = raw:find("{crafted}", 1, true) and raw:find("to Strength", 1, true)
				return { Life = hasStrengthCraft and 150 or 100 }
			end, { Life = 100 })[1]

			assert.is_truthy(evaluation.benchCraft:find("to Strength", 1, true))
			assert.is_truthy(evaluation.benchCraftReplaced:find("to Dexterity/10% increased Rarity", 1, true))
			assert.is_nil(evaluation.benchCraftItemString:find("+20 to Dexterity", 1, true))
			assert.is_nil(evaluation.benchCraftItemString:find("10% increased Rarity", 1, true))
			local replacementItem = new("Item"):Item(evaluation.benchCraftItemString)
			local fracturedManaLine
			for _, modLine in ipairs(replacementItem.explicitModLines) do
				if modLine.line == "+25 to maximum Mana" then
					fracturedManaLine = modLine
					break
				end
			end
			assert.is_table(fracturedManaLine)
			assert.is_true(fracturedManaLine.fractured)
		end)

		it("preserves fetched fractured suffix values in a bench craft preview", function()
			local function apiMod(description, hash, tier, domain, flags)
				return { description = description, domain = domain or "explicit", hash = "stat." .. hash,
					flags = flags, mods = { { name = "Test Affix", tier = tier, level = 30 } } }
			end
			local response = dkjson.encode({ result = { {
				id = "helical-preview", listing = { price = { amount = 1, currency = "chaos", type = "~price" }, whisper = "hi", account = { name = "seller" } },
				item = { rarity = "Rare", name = "Preview Subject", typeLine = "Helical Ring", implicitMods = {
					{ description = "-2 Prefix Modifiers allowed" }, { description = "+1 Suffix Modifier allowed" },
					{ description = "Implicit Modifiers Cannot Be Changed" }, { description = "50% increased Suffix Modifier magnitudes" },
				}, explicitMods = {
					apiMod("+50 to maximum Life", "explicit.life", "P2"),
					apiMod("+24% to all Elemental Resistances", "explicit.all-res", "S3"),
					apiMod("+69% to Lightning Resistance", "explicit.lightning-res", "S3"),
					apiMod("+37% to Global Critical Strike Multiplier", "fractured.crit", "S3", "fractured", { fractured = true }),
				}, extended = { hashes = { explicit = { { "explicit.life", { 0 } }, { "explicit.all-res", { 1 } }, { "explicit.lightning-res", { 2 } } }, fractured = { { "fractured.crit", { 0 } } } } } },
			} } })
			requests.requestQueue.fetch = { }
			local fetchedItems
			requests:FetchResultBlock("test", function(items) fetchedItems = items end)
			table.remove(requests.requestQueue.fetch, 1).callback(response)
			local sourceItem = new("Item"):Item(fetchedItems[1].item_string)
			local function findLine(item, text)
				for _, modLine in ipairs(item.explicitModLines) do
					if modLine.line == text then return modLine end
				end
			end
			local function assertDisplayedValue(item, line, stored, displayed)
				local modLine = assert(findLine(item, line))
				assert.are.equal(stored, modLine.line)
				assert.is_truthy(itemLib.formatModLine(modLine):find(displayed, 1, true))
				return modLine
			end
			local sourceCrit = assertDisplayedValue(sourceItem, "+37% to Global Critical Strike Multiplier", "+37% to Global Critical Strike Multiplier", "+37%")
			assert.is_true(sourceCrit.fractured)
			assertDisplayedValue(sourceItem, "+24% to all Elemental Resistances", "+24% to all Elemental Resistances", "+24%")
			assertDisplayedValue(sourceItem, "+69% to Lightning Resistance", "+69% to Lightning Resistance", "+69%")

			local tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = { } })
			local strengthCraft = { type = "Suffix", group = "Strength", modTags = { "attribute" }, types = { Ring = true }, "+(21-25) to Strength" }
			tradeQuery.tradeQueryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator({ itemsTab = { } })
			tradeQuery.itemsTab.build = { data = { masterMods = { strengthCraft } } }
			tradeQuery.statSortSelectionList = { { stat = "Life", weightMult = 1 } }
			tradeQuery.slotTables[1] = { slotName = "Ring 1", considerBenchCraft = true }
			tradeQuery.resultTbl[1] = { fetchedItems[1] }
			local previousAffixQuality = main.defaultItemAffixQuality
			main.defaultItemAffixQuality = 0.5
			local evaluation = tradeQuery:GetResultEvaluation(1, 1, function(args)
				return { Life = args.repItem:BuildRaw():find("to Strength", 1, true) and 150 or 100 }
			end, { Life = 100 })[1]
			main.defaultItemAffixQuality = previousAffixQuality
			assert.is_truthy(evaluation.benchCraftItemString)
			local previewItem = new("Item"):Item(evaluation.benchCraftItemString)
			local previewCrit = assertDisplayedValue(previewItem, "+37% to Global Critical Strike Multiplier", "+37% to Global Critical Strike Multiplier", "+37%")
			assert.is_true(previewCrit.fractured)
			assertDisplayedValue(previewItem, "+24% to all Elemental Resistances", "+24% to all Elemental Resistances", "+24%")
			assertDisplayedValue(previewItem, "+69% to Lightning Resistance", "+69% to Lightning Resistance", "+69%")
			local previewStrength = assert(findLine(previewItem, "+(21-25) to Strength"))
			assert.is_true(previewStrength.crafted)
			assert.is_truthy(itemLib.formatModLine(previewStrength):find("+34 to Strength", 1, true))
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
