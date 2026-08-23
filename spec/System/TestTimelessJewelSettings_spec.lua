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
end)
