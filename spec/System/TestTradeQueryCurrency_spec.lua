describe("TradeQuery Currency Conversion", function()
	local mock_tradeQuery

	before_each(function()
		mock_tradeQuery = new("TradeQuery"):TradeQuery({ itemsTab = {} })
	end)

	describe("ConvertCurrencyToDivs", function()
		-- Pass: Calculates price in divs
		-- Fail: Wrong value or nil, indicating broken rounding/baseline logic
		it("handles chaos currency", function()
			mock_tradeQuery.pbCurrencyConversion = { realm = { league = { chaos = 0.1 } } }
			mock_tradeQuery.pbRealm = "realm"
			mock_tradeQuery.pbLeague = "league"
			local result = mock_tradeQuery:ConvertCurrencyToDivs("chaos", 5)
			assert.are.equal(result, 0.5)
		end)

		-- Pass: Returns nil without crash
		-- Fail: Crashes or wrong value, indicating unhandled currencies, corrupting price conversions
		it("returns nil for unmapped", function()
			local result = mock_tradeQuery:ConvertCurrencyToDivs("exotic", 10)
			assert.is_nil(result)
		end)
	end)

	it("applies the Stat Value fallback when currency rates are missing", function()
		mock_tradeQuery.sortModes = { Price = "price", StatValue = "stat" }
		mock_tradeQuery.itemSortSelectionList = { "price" }
		mock_tradeQuery.pbItemSortSelectionIndex = 1
		mock_tradeQuery.resultTbl = { [1] = { { currency = "chaos", amount = 1 } } }
		mock_tradeQuery.sortedResultTbl = {}
		mock_tradeQuery.itemIndexTbl = {}
		mock_tradeQuery.totalPrice = {}
		mock_tradeQuery.controls.pbNotice = {}
		mock_tradeQuery.controls.priceButton1 = {}
		mock_tradeQuery.controls.fullPrice = {}
		mock_tradeQuery.SortFetchResults = function(_, _, mode)
			if mode == "price" then
				return nil, "MissingConversionRates"
			end
			return { { index = 1 } }
		end
		mock_tradeQuery.UpdateDropdownList = function() end

		mock_tradeQuery:UpdateControlsWithItems(1)

		assert.are.equals(1, mock_tradeQuery.sortedResultTbl[1][1].index)
		assert.are.equals(1, mock_tradeQuery.itemIndexTbl[1])
	end)


	describe("PullCXData", function()
		local dkjson = require("dkjson")

		-- base type ids the currency exchange uses
		local DIVINE = "Metadata/Items/Currency/CurrencyModValues"
		local CHAOS  = "Metadata/Items/Currency/CurrencyRerollRare"
		local EXALT  = "Metadata/Items/Currency/CurrencyAddModToRare"
		local ALCH   = "Metadata/Items/Currency/CurrencyUpgradeToRare"
		local STACKED_DECK = "Metadata/Items/DivinationCards/DivinationCardDeck"

		-- static trade data: maps display name -> short trade id
		local static = {
			result = { {
				entries = {
					{ id = "sep", text = "" }, -- separator, must be ignored
					{ id = "divine", text = "Divine Orb" },
					{ id = "chaos", text = "Chaos Orb" },
					{ id = "exalt", text = "Exalted Orb" },
					{ id = "alch", text = "Orb of Alchemy" },
					{ id = "stacked-deck", text = "Stacked Deck" },
				}
			} }
		}

		local origDownloadPage, cxResponse

		before_each(function()
			mock_tradeQuery.pbRealm = "pc"
			mock_tradeQuery.controls.pbNotice = {}
			origDownloadPage = launch.DownloadPage
			cxResponse = nil
			launch.DownloadPage = function(_, url, callback)
				if url == "https://www.pathofexile.com/api/trade/data/static" then
					callback({ body = dkjson.encode(static) })
				elseif cxResponse then
					callback({ body = dkjson.encode(cxResponse) })
				end
			end
		end)

		after_each(function()
			launch.DownloadPage = origDownloadPage
		end)

		it("fetches currency exchange data without authentication", function()
			local requestedUrl
			local requestedParams
			launch.DownloadPage = function(_, url, callback, params)
				if url == "https://www.pathofexile.com/api/trade/data/static" then
					callback({ body = dkjson.encode(static) })
				else
					requestedUrl = url
					requestedParams = params
					callback({ body = dkjson.encode({ markets = {} }) })
				end
			end

			mock_tradeQuery.pbRealm = "xbox"
			mock_tradeQuery:PullCXData()

			assert.is_truthy(requestedUrl:match("^https://web%.poecdn%.com/api/currency%-exchange/xbox/%d+$"))
			assert.is_nil(requestedParams)
		end)

		it("waits until a realm is selected", function()
			local fetched = false
			mock_tradeQuery.pbRealm = ""
			launch.DownloadPage = function()
				fetched = true
			end

			mock_tradeQuery:PullCXData()

			assert.is_false(fetched)
		end)

		it("stores responses under the requested realm", function()
			local callbacks = {}
			launch.DownloadPage = function(_, url, callback)
				if url == "https://www.pathofexile.com/api/trade/data/static" then
					callback({ body = dkjson.encode(static) })
				elseif url:find("/xbox/", 1, true) then
					callbacks.xbox = callback
				else
					callbacks.pc = callback
				end
			end

			mock_tradeQuery.pbRealm = "pc"
			mock_tradeQuery:PullCXData()
			mock_tradeQuery.pbRealm = "xbox"
			mock_tradeQuery:PullCXData()

			for _, response in ipairs({ { "xbox", 5 }, { "pc", 10 } }) do
				callbacks[response[1]]({ body = dkjson.encode({ markets = { {
					league = "Standard",
					market_pair = { EXALT, DIVINE },
					lowest_ratio = { [EXALT] = response[2], [DIVINE] = 1 },
					highest_stock = { [EXALT] = 100, [DIVINE] = 100 },
				} } }) })
			end

			assert.are.equal(0.1, mock_tradeQuery.pbCurrencyConversion.pc.Standard.exalt)
			assert.are.equal(0.2, mock_tradeQuery.pbCurrencyConversion.xbox.Standard.exalt)
		end)

		-- Provide the currency exchange response returned by the download mock.
		local function mockCX(markets)
			cxResponse = { markets = markets }
		end

		it("converts a chained market to divine values", function()
			mockCX({
				-- exalt -> divine directly (1 exalt = 0.1 div)
				{
					league = "Standard",
					market_pair = { EXALT, DIVINE },
					lowest_ratio = { [EXALT] = 10, [DIVINE] = 1 },
					highest_stock = { [EXALT] = 100, [DIVINE] = 100 },
				},
				-- chaos -> divine directly (1 chaos = 0.005 div)
				{
					league = "Standard",
					market_pair = { CHAOS, DIVINE },
					lowest_ratio = { [CHAOS] = 200, [DIVINE] = 1 },
					highest_stock = { [CHAOS] = 500, [DIVINE] = 500 },
				},
				-- alch -> chaos (1 alch = 0.2 chaos), needs a second hop to divine
				{
					league = "Standard",
					market_pair = { ALCH, CHAOS },
					lowest_ratio = { [ALCH] = 5, [CHAOS] = 1 },
					highest_stock = { [ALCH] = 1000, [CHAOS] = 1000 },
				},
				{
					league = "Standard",
					market_pair = { STACKED_DECK, DIVINE },
					lowest_ratio = { [STACKED_DECK] = 50, [DIVINE] = 1 },
					highest_stock = { [STACKED_DECK] = 1000, [DIVINE] = 100 },
				},
			})

			mock_tradeQuery:PullCXData()

			local rates = mock_tradeQuery.pbCurrencyConversion.pc.Standard
			assert.is_not_nil(rates)
			assert.are.equal(1, rates.divine)
			assert.are.equal(0.1, rates.exalt)
			assert.are.equal(0.005, rates.chaos)
			-- 0.2 chaos * 0.005 div/chaos = 0.001 div
			assert.are.equal(0.001, rates.alch)
			assert.are.equal(0.02, rates["stacked-deck"])
		end)

		it("keeps the highest-stock listing for a currency", function()
			mockCX({
				{
					league = "Standard",
					market_pair = { EXALT, DIVINE },
					lowest_ratio = { [EXALT] = 10, [DIVINE] = 1 }, -- 0.1 div
					highest_stock = { [EXALT] = 50, [DIVINE] = 5 },
				},
				{
					league = "Standard",
					market_pair = { EXALT, DIVINE },
					lowest_ratio = { [EXALT] = 5, [DIVINE] = 1 }, -- 0.2 div
					highest_stock = { [EXALT] = 200, [DIVINE] = 40 }, -- more stock, wins
				},
			})

			mock_tradeQuery:PullCXData()

			assert.are.equal(0.2, mock_tradeQuery.pbCurrencyConversion.pc.Standard.exalt)
		end)

		it("skips listings with a zero ratio", function()
			mockCX({
				{
					league = "Standard",
					market_pair = { EXALT, DIVINE },
					lowest_ratio = { [EXALT] = 0, [DIVINE] = 1 },
					highest_stock = { [EXALT] = 100, [DIVINE] = 100 },
				},
			})

			mock_tradeQuery:PullCXData()

			-- league had no usable listings, so it should not appear
			assert.is_nil(mock_tradeQuery.pbCurrencyConversion.pc.Standard)
		end)

		it("shows a notice on an API error response", function()
			cxResponse = { error = { message = "kaput" } }

			mock_tradeQuery:PullCXData()

			assert.are.equal("CX error: kaput", mock_tradeQuery.controls.pbNotice.label)
			assert.is_nil(mock_tradeQuery.pbCurrencyConversion.pc)
		end)

		it("does not refetch within the rate-limit window", function()
			mock_tradeQuery.pbCurrencyConversion.pc = { timestamp = os.time() }
			local fetched = false
			launch.DownloadPage = function() fetched = true end

			mock_tradeQuery:PullCXData()

			assert.is_false(fetched)
		end)
	end)
	describe("GetTotalPriceString", function()
		-- Pass: Sums and formats correctly (e.g., "5 chaos, 10 div", should be most valuable currency first)
		-- Fail: Wrong string (e.g., unsorted/missing sums), indicating aggregation bug, misleading users on totals
		it("aggregates prices", function()
			-- check alphabetical sorting
			mock_tradeQuery.totalPrice = { { currency = "chaos", amount = 5 }, { currency = "div", amount = 10 }, {currency = "exalted", amount = 1} }
			local result = mock_tradeQuery:GetTotalPriceString()
			assert.are.equal(result, "1 exalted, 10 div, 5 chaos")

			-- check if they're sorted according to currency value
			mock_tradeQuery.pbRealm = "realm"
			mock_tradeQuery.pbLeague = "league"
			mock_tradeQuery.pbCurrencyConversion = { realm = { league = { chaos = 0.1, exalted = 0.05, div = 1, mirror = 700 } } }
			local result = mock_tradeQuery:GetTotalPriceString()
			assert.are.equal(result, "10 div, 5 chaos, 1 exalted")

			-- check that missing currency values don't crash
			mock_tradeQuery.pbCurrencyConversion = { realm = { league = { chaos = 0.1, exalted = 0.05, mirror = 700 } } }
			local result = mock_tradeQuery:GetTotalPriceString()
			assert.True(true)
		end)
	end)
end)
