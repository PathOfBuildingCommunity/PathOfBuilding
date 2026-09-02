describe("SearchHost", function()
	it("searches item bases by full name and base effects", function()
		local cases = {
			{ type = "Amulet: Talisman", search = "monkey power charge", name = "Monkey Paw Talisman (Power)" },
			{ type = "Amulet: Talisman", search = "moon rite", name = "Greatwolf Talisman" },
			{ type = "Amulet: Talisman", search = "fire-to-cold", name = "Avian Twins Talisman (Fire-To-Cold)" },
		}

		for _, testCase in ipairs(cases) do
			local control = new("DropDownControl"):DropDownControl(nil, { 0, 0, 100, 20 }, data.itemBaseLists[testCase.type])
			for char in testCase.search:gmatch(".") do
				control:OnSearchChar(char)
			end

			assert.are.equal(1, control:GetMatchCount())
			assert.are.equal(testCase.name, control.list[control:DropIndexToListIndex(1)].name)
		end
	end)

	it("searches flask bases by buff effects", function()
		local control = new("DropDownControl"):DropDownControl(nil, { 0, 0, 100, 20 }, data.itemBaseLists["Flask: Utility"])
		for char in ("res"):gmatch(".") do
			control:OnSearchChar(char)
		end

		local matches = { }
		for index, searchInfo in ipairs(control.searchInfos) do
			if searchInfo.matches then
				matches[control.list[index].name] = true
			end
		end
		assert.is_true(matches["Ruby Flask"])
		assert.is_true(matches["Sapphire Flask"])
		assert.is_true(matches["Topaz Flask"])
	end)

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
