describe("TestTimelessJewelSettings", function()
	before_each(function()
		newBuild()
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
