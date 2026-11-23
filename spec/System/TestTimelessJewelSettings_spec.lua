describe("TestTimelessJewelSettings", function()
	before_each(function()
		newBuild()
	end)

	describe("trade search", function()
		local tradeHelpers = require "Classes.TradeHelpers"
		local originalEncode, originalCopy, originalOpenURL
		local query, copiedUrl, openedUrl

		before_each(function()
			originalEncode, originalCopy, originalOpenURL = tradeHelpers.B64GzipEncode, _G.Copy, _G.OpenURL
			tradeHelpers.B64GzipEncode = function(json)
				query = require("dkjson").decode(json)
				return "encoded"
			end
			_G.Copy = function(url) copiedUrl = url end
			_G.OpenURL = function(url) openedUrl = url end
		end)

		after_each(function()
			tradeHelpers.B64GzipEncode, _G.Copy, _G.OpenURL = originalEncode, originalCopy, originalOpenURL
			main:ClosePopup()
		end)

		it("includes seed and devotion constraints in a console trade link", function()
			build.timelessData.jewelType = { id = 4 }
			build.treeTab.tradeLeaguesList = { pc = { "Standard" }, xbox = { "Hardcore Test" } }
			build.treeTab:FindTimelessJewel()
			local controls = main.popups[1].controls
			build.timelessData.sharedResults = {
				conqueror = { id = 3 }, devotionVariant1 = { id = 2 }, devotionVariant2 = { id = 7 },
			}
			build.timelessData.searchResults = { { seed = 5000 }, { seed = 6000 } }
			controls.realmSelection:SetSel(3)
			controls.tradeTypeSelection:SetSel(2)
			controls.searchTradeButton.onClick()

			assert.are.equal("https://www.pathofexile.com/trade/search/xbox/Hardcore%20Test/encoded", openedUrl)
			assert.are.equal(openedUrl, copiedUrl)
			assert.are.equal("available", query.status.option)
			assert.same({
				type = "count", value = { min = 1 }, filters = {
					{ id = data.timelessJewelTradeIDs[4].keystone[2], value = { min = 5000, max = 5000 } },
					{ id = data.timelessJewelTradeIDs[4].keystone[2], value = { min = 6000, max = 6000 } },
				},
			}, query.stats[1])
			assert.same({ type = "and", filters = {
				{ id = data.timelessJewelTradeIDs[4].devotion[1] },
				{ id = data.timelessJewelTradeIDs[4].devotion[6] },
			} }, query.stats[2])
		end)
	end)

	-- The finder's "Socket Jewel" toggle lives in timelessData, which only reaches the
	-- build XML through the TimelessData element, so cover the save/load round trip.
	it("round trips socketAllocate through the build XML", function()
		build.timelessData.socketAllocate = true
		local xmlText = build:SaveDB("code")
		assert.is_truthy(xmlText:match('socketAllocate="true"'))

		loadBuildFromXML(xmlText)
		assert.is_true(build.timelessData.socketAllocate)
	end)

	it("omits socketAllocate from the build XML while unticked", function()
		build.timelessData.socketAllocate = false
		local xmlText = build:SaveDB("code")
		assert.is_nil(xmlText:match("socketAllocate"))

		loadBuildFromXML(xmlText)
		assert.is_false(build.timelessData.socketAllocate)
	end)

	it("records the item addition when the target socket is unallocated", function()
		local socketId, socketControl = next(build.itemsTab.sockets)
		local result = { label = "10000:", seed = 10000, total = 1 }
		build.spec.allocNodes[socketId] = nil
		build.timelessData.socketAllocate = true
		build.timelessData.sharedResults = {
			type = { id = 2, label = "Lethal Pride" },
			conqueror = { id = 1 },
			socket = { id = socketId, label = "Socket" },
			desiredNodes = { },
		}
		build.timelessData.searchResults = { result }
		local control = new("TimelessJewelListControl"):TimelessJewelListControl(nil, { 0, 0, 300, 100 }, build)
		local initialItemCount = #build.itemsTab.itemOrderList
		build.itemsTab:ResetUndo()
		build.itemsTab.modFlag = false

		control:OnSelClick(1, result, true)

		assert.are.equal(initialItemCount + 1, #build.itemsTab.itemOrderList)
		assert.are.equal(0, socketControl.selItemId)
		assert.is_true(build.itemsTab.modFlag)

		build.itemsTab:Undo()
		assert.are.equal(initialItemCount, #build.itemsTab.itemOrderList)
	end)
end)
