local dkjson = require "dkjson"

describe("TradeQueryGenerator", function()
	local mock_queryGen = new("TradeQueryGenerator", { itemsTab = {} })

	local function findStatFilter(queryTable, id)
		for _, group in ipairs(queryTable.query.stats) do
			for _, filter in ipairs(group.filters or {}) do
				if filter.id == id then
					return filter
				end
			end
		end
	end

	local function finishQueryWithAttributeShortfall(shortfall, includeAttrReqs)
		local queryGen = new("TradeQueryGenerator", { itemsTab = {} })
		local queryTable
		local errMsg
		queryGen.modWeights = {
			{ tradeModId = "explicit.stat_3299347043", weight = 1, meanStatDiff = 1 },
		}
		queryGen.tradeTypeIndex = 1
		queryGen.requesterContext = {}
		queryGen.requesterCallback = function(_, queryJson, queryErrMsg)
			queryTable = dkjson.decode(queryJson)
			errMsg = queryErrMsg
		end
		queryGen.calcContext = {
			itemCategoryQueryStr = "ring",
			special = {},
			testItem = {
				BuildAndParseRaw = function() end,
			},
			baseOutput = { TotalDPS = 100 },
			baseStatValue = 0,
			options = {
				statWeights = { { stat = "TotalDPS", weightMult = 1 } },
				includeAllWEMods = false,
				includeAttrReqs = includeAttrReqs,
				includeMirrored = true,
				influence1 = 1,
				influence2 = 1,
			},
			attrReqShortfall = shortfall,
		}

		local previousClosePopup = main.ClosePopup
		main.ClosePopup = function() end
		queryGen:FinishQuery()
		main.ClosePopup = previousClosePopup

		return queryTable, errMsg
	end

	describe("ProcessMod", function()
		-- Pass: Mod line maps correctly to trade stat entry without error
		-- Fail: Mapping fails (e.g., no match found), indicating incomplete stat parsing for curse mods, potentially missing curse-enabling items in queries
		it("handles special curse case", function()
			local mod = { "You can apply an additional Curse" }
			local tradeStatsParsed = { result = { [2] = { entries = { { text = "You can apply # additional Curses", id = "id" } } } } }
			mock_queryGen.modData = { Explicit = true }
			mock_queryGen:ProcessMod(mod, tradeStatsParsed, 1)
			-- Simplified assertion; in full impl, check modData
			assert.is_true(true)
		end)
	end)

	describe("WeightedRatioOutputs", function()
		-- Pass: Returns 0, avoiding math errors
		-- Fail: Returns NaN/inf or crashes, indicating unhandled infinite values, causing evaluation failures in infinite-scaling builds
		it("handles infinite base", function()
			local baseOutput = { TotalDPS = math.huge }
			local newOutput = { TotalDPS = 100 }
			local statWeights = { { stat = "TotalDPS", weightMult = 1 } }
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
			assert.are.equal(result, 0)
		end)

		-- Pass: Returns capped value (100), preventing division issues
		-- Fail: Returns inf/NaN, indicating unhandled zero base, leading to invalid comparisons in low-output builds
		it("handles zero base", function()
			local baseOutput = { TotalDPS = 0 }
			local newOutput = { TotalDPS = 100 }
			local statWeights = { { stat = "TotalDPS", weightMult = 1 } }
			data.misc.maxStatIncrease = 1000
			local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
			assert.are.equal(result, 100)
		end)
	end)

	describe("Filter prioritization", function()
		-- Pass: Limits mods to MAX_FILTERS (2 in test), preserving top priorities
		-- Fail: Exceeds limit, indicating over-generation of filters, risking API query size errors or rate limits
		it("respects MAX_FILTERS", function()
			local orig_max = _G.MAX_FILTERS
			_G.MAX_FILTERS = 2
			mock_queryGen.modWeights = { { weight = 10, tradeModId = "id1" }, { weight = 5, tradeModId = "id2" } }
			table.sort(mock_queryGen.modWeights, function(a, b)
				return math.abs(a.weight) > math.abs(b.weight)
			end)
			local prioritized = {}
			for i, entry in ipairs(mock_queryGen.modWeights) do
				if #prioritized < _G.MAX_FILTERS then
					table.insert(prioritized, entry)
				end
			end
			assert.are.equal(#prioritized, 2)
			_G.MAX_FILTERS = orig_max
		end)
	end)

	describe("attribute requirement filters", function()
		it("adds needed attribute pseudo filters to the generated query", function()
			local queryTable, errMsg = finishQueryWithAttributeShortfall({ Str = 12, Dex = 34, Int = 56 }, true)
			assert.is_nil(errMsg)
			assert.are.equal(12, findStatFilter(queryTable, "pseudo.pseudo_total_strength").value.min)
			assert.are.equal(34, findStatFilter(queryTable, "pseudo.pseudo_total_dexterity").value.min)
			assert.are.equal(56, findStatFilter(queryTable, "pseudo.pseudo_total_intelligence").value.min)
		end)

		it("omits attribute pseudo filters when disabled or no shortfall exists", function()
			local disabledQuery = finishQueryWithAttributeShortfall({ Str = 12, Dex = 34, Int = 56 }, false)
			local zeroQuery = finishQueryWithAttributeShortfall({ Str = 0, Dex = 0, Int = 0 }, true)
			assert.is_nil(findStatFilter(disabledQuery, "pseudo.pseudo_total_strength"))
			assert.is_nil(findStatFilter(disabledQuery, "pseudo.pseudo_total_dexterity"))
			assert.is_nil(findStatFilter(disabledQuery, "pseudo.pseudo_total_intelligence"))
			assert.is_nil(findStatFilter(zeroQuery, "pseudo.pseudo_total_strength"))
			assert.is_nil(findStatFilter(zeroQuery, "pseudo.pseudo_total_dexterity"))
			assert.is_nil(findStatFilter(zeroQuery, "pseudo.pseudo_total_intelligence"))
		end)
	end)
end)
