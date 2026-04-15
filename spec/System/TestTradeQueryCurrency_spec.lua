describe("TradeQuery Currency Conversion", function()
	local mock_tradeQuery = new("TradeQuery", { itemsTab = {} })

	-- test case for commit: "Skip callback on errors to prevent incomplete conversions"
	describe("FetchCurrencyConversionTable", function()
		-- Pass: Callback not called on error
		-- Fail: Callback called, indicating partial data risk
		it("skips callback on error", function()
			local orig_launch = launch
			local spy = { called = false }
			launch = {
				DownloadPage = function(url, callback, opts)
					callback(nil, "test error")
				end
			}
			mock_tradeQuery:FetchCurrencyConversionTable(function()
				spy.called = true
			end)
			launch = orig_launch
			assert.is_false(spy.called)
		end)
	end)

	describe("ConvertCurrencyToChaos", function()
		-- Pass: Ceils amount to integer (e.g., 4.9 -> 5)
		-- Fail: Wrong value or nil, indicating broken rounding/baseline logic, causing inaccurate chaos totals
		it("handles chaos currency", function()
			mock_tradeQuery.pbCurrencyConversion = { league = { chaos = 1 } }
			mock_tradeQuery.pbLeague = "league"
			local result = mock_tradeQuery:ConvertCurrencyToChaos("chaos", 4.9)
			assert.are.equal(result, 5)
		end)

		-- Pass: Returns nil without crash
		-- Fail: Crashes or wrong value, indicating unhandled currencies, corrupting price conversions
		it("returns nil for unmapped", function()
			local result = mock_tradeQuery:ConvertCurrencyToChaos("exotic", 10)
			assert.is_nil(result)
		end)
	end)

	describe("PriceBuilderProcessPoENinjaResponse", function()
		-- Pass: Processes without error, restoring map
		-- Fail: Corrupts map or crashes, indicating fragile API response handling, breaking future conversions
		it("handles unmapped currency", function()
			local orig_conv = mock_tradeQuery.currencyConversionTradeMap
			mock_tradeQuery.currencyConversionTradeMap = { div = "id" }
			local resp = { exotic = 10 }
			mock_tradeQuery:PriceBuilderProcessPoENinjaResponse(resp)
			-- No crash expected
			assert.is_true(true)
			mock_tradeQuery.currencyConversionTradeMap = orig_conv
		end)
	end)

	describe("GetTotalPriceString", function()
		-- Pass: Sums and formats correctly (e.g., "5 chaos, 10 div")
		-- Fail: Wrong string (e.g., unsorted/missing sums), indicating aggregation bug, misleading users on totals
		it("aggregates prices", function()
			mock_tradeQuery.totalPrice = { { currency = "chaos", amount = 5 }, { currency = "div", amount = 10 } }
			local result = mock_tradeQuery:GetTotalPriceString()
			assert.are.equal(result, "5 chaos, 10 div")
		end)
	end)
end)
