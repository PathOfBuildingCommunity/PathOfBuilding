describe("SearchHost", function()
	it("merges all overlapping ranges when word order is ignored", function()
		local searchHost = new("SearchHost"):SearchHost(function()
			return { "caster" }
		end, nil, true)

		for char in ("caster ast ste"):gmatch(".") do
			searchHost:OnSearchChar(char)
		end

		assert.same({ { from = 1, to = 6 } }, searchHost.searchInfos[1].ranges)
	end)
end)
