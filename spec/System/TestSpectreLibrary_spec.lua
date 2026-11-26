describe("Spectre Library", function()
	local controls
	local frostbearer = "Metadata/Monsters/LeagueCrucible/Cold/Pyromaniac"

	before_each(function()
		newBuild()
		build:OpenSpectreLibrary()
		controls = main.popups[1].controls
	end)

	after_each(function()
		main:ClosePopup()
	end)

	it("offers to enable Show All when a spectre search has no recommended matches", function()
		local searchText = controls.source.controls.searchText
		local showAll = controls.source.controls.showAllForSearch
		searchText:SetText("forge", true)
		assert.are.equal(0, #controls.source.list)
		assert.is_truthy(showAll and showAll:IsShown(),
			"An empty recommended search should offer Show All")

		searchText:SetText("", true)
		assert.is_false(showAll:IsShown())
		searchText:SetText("forge", true)
		showAll.onClick()

		assert.is_true(controls.sortMonsterCheckboxShowAll.state)
		assert.are.equal("forge", searchText.buf)
		assert.is_truthy(isValueInArray(controls.source.list, frostbearer))
		assert.is_false(showAll:IsShown())

		searchText:SetText("no such spectre", true)
		assert.are.equal(0, #controls.source.list)
		assert.is_false(showAll:IsShown())
	end)

	it("keeps Corpse Only enabled when expanding an empty search", function()
		local corpseOnly = controls.sortMonsterCheckboxFilterCorpse
		corpseOnly.state = true
		corpseOnly.changeFunc(true)
		controls.source.controls.searchText:SetText("forge", true)

		local showAll = controls.source.controls.showAllForSearch
		assert.is_truthy(showAll and showAll:IsShown())
		showAll.onClick()

		assert.is_true(corpseOnly.state)
		assert.are.equal(0, #controls.source.list)
	end)
end)
