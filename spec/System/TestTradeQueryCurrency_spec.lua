describe("TradeQuery Currency Conversion", function()
	local mock_tradeQuery

	before_each(function()
		mock_tradeQuery = new("TradeQuery", { itemsTab = {} })
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
