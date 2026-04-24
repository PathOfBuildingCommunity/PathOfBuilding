describe("TradeQuery Currency Conversion", function()
	local mock_tradeQuery

	before_each(function()
		mock_tradeQuery = new("TradeQuery", { itemsTab = {} })
	end)

	describe("ConvertCurrencyToDivs", function()
		-- Pass: Calculates price in divs
		-- Fail: Wrong value or nil, indicating broken rounding/baseline logic
		it("handles chaos currency", function()
			mock_tradeQuery.pbCurrencyConversion = { league = { chaos = 0.1 } }
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

	describe("PriceBuilderProcessPoENinjaResponse", function()
		-- Pass: Processes without error, restoring map while adding a notice
		-- Fail: Corrupts map or crashes, indicating fragile API response handling, breaking future conversions
		it("handles empty response", function()
			local orig_conv = mock_tradeQuery.currencyConversionTradeMap
			mock_tradeQuery.currencyConversionTradeMap = { div = "id" }
			mock_tradeQuery.pbLeague = "league"
			mock_tradeQuery.pbCurrencyConversion = { league = {} }
			mock_tradeQuery.controls.pbNotice = { label = "" }
			local resp = { lines = {  }}
			mock_tradeQuery:PriceBuilderProcessPoENinjaResponse(resp.lines)
			-- No crash expected
			assert.is_true(true)
			assert.is_true(mock_tradeQuery.controls.pbNotice.label == "No currencies received from PoE Ninja")
			mock_tradeQuery.currencyConversionTradeMap = orig_conv
		end)

		-- Pass: Processes without error, restoring map while adding a notice
		-- Fail: Corrupts map or crashes, indicating fragile API response handling, breaking future conversions
		it("handles empty response", function()
			local orig_conv = mock_tradeQuery.currencyConversionTradeMap
			mock_tradeQuery.currencyConversionTradeMap = { div = "id" }
			mock_tradeQuery.pbLeague = "league"
			mock_tradeQuery.pbCurrencyConversion = { league = {} }
			mock_tradeQuery.controls.pbNotice = { label = "" }
			local resp = { lines = { { malformedLine = "lol"} }}
			mock_tradeQuery:PriceBuilderProcessPoENinjaResponse(resp.lines)
			-- No crash expected
			assert.is_true(true)
			assert.is_true(mock_tradeQuery.controls.pbNotice.label == "Currencies not updated: malformed PoE Ninja response")
			mock_tradeQuery.currencyConversionTradeMap = orig_conv
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
			mock_tradeQuery.pbLeague = "league"
			mock_tradeQuery.pbCurrencyConversion = { league = { chaos = 0.1, exalted = 0.05, div = 1, mirror = 700} }
			local result = mock_tradeQuery:GetTotalPriceString()
			assert.are.equal(result, "10 div, 5 chaos, 1 exalted")

			-- check that missing currency values don't crash
			mock_tradeQuery.pbLeague = "league"
			mock_tradeQuery.pbCurrencyConversion = { league = { chaos = 0.1, exalted = 0.05, mirror = 700 } }
			local result = mock_tradeQuery:GetTotalPriceString()
			assert.True(true)
		end)
	end)
end)
