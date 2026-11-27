describe("Spectre Library", function()
	local controls, searchText, showAll, showAllCheckbox, corpseOnly

	-- Picks a Spectre that only Show All reveals, with a name that no recommended Spectre matches
	local function findHiddenSpectre(itemisedCorpse)
		local minions = build.data.minions
		local recommendedNames = { }
		for id in pairs(build.data.spectres) do
			if minions[id].extraFlags and minions[id].extraFlags.recommendedSpectre then
				table.insert(recommendedNames, minions[id].name:lower())
			end
		end
		local candidates = { }
		for id in pairs(build.data.spectres) do
			local minion = minions[id]
			local name = minion.name:lower()
			if not (minion.extraFlags and minion.extraFlags.recommendedSpectre)
			and (minion.itemisedCorpse ~= nil) == itemisedCorpse and name:match("^[%a ]+$") then
				local hidden = true
				for _, recommendedName in ipairs(recommendedNames) do
					if recommendedName:find(name, 1, true) then
						hidden = false
						break
					end
				end
				-- Keep the name distinct from skill names so that it only matches in the name search modes
				for _, skill in pairs(build.data.skills) do
					if skill.name and skill.name:lower():find(name, 1, true) then
						hidden = false
						break
					end
				end
				if hidden then
					table.insert(candidates, id)
				end
			end
		end
		table.sort(candidates)
		assert.is_truthy(candidates[1], "Expected a Spectre that is only listed with Show All")
		return candidates[1], minions[candidates[1]].name
	end

	local function setCorpseOnly(state)
		corpseOnly.state = state
		corpseOnly.changeFunc(state)
	end

	before_each(function()
		newBuild()
		build:OpenSpectreLibrary()
		controls = main.popups[1].controls
		searchText = controls.source.controls.searchText
		showAll = controls.source.controls.showAllForSearch
		showAllCheckbox = controls.sortMonsterCheckboxShowAll
		corpseOnly = controls.sortMonsterCheckboxFilterCorpse
	end)

	after_each(function()
		main:ClosePopup()
	end)

	it("offers to enable Show All when a spectre search has no recommended matches", function()
		local id, name = findHiddenSpectre(false)
		searchText:SetText(name, true)
		assert.are.equal(0, #controls.source.list)
		assert.is_truthy(showAll and showAll:IsShown(),
			"An empty recommended search should offer Show All")

		searchText:SetText("", true)
		assert.is_false(showAll:IsShown())
		searchText:SetText(name, true)
		showAll.onClick()

		assert.is_true(showAllCheckbox.state)
		assert.are.equal(name, searchText.buf)
		assert.is_truthy(isValueInArray(controls.source.list, id))
		assert.is_false(showAll:IsShown())
	end)

	it("does not offer Show All when it would not find anything either", function()
		searchText:SetText("no such spectre", true)
		assert.are.equal(0, #controls.source.list)
		assert.is_false(showAll:IsShown())

		-- Hidden by the monster type filter, which Show All does not change
		local id, name = findHiddenSpectre(false)
		local typeCheckbox = controls["sortMonsterCheckbox" .. build.data.minions[id].monsterCategory]
		searchText:SetText(name, true)
		assert.is_true(showAll:IsShown())
		typeCheckbox.state = false
		typeCheckbox.changeFunc(false)
		assert.are.equal(0, #controls.source.list)
		assert.is_false(showAll:IsShown())
		typeCheckbox.state = true
		typeCheckbox.changeFunc(true)
		assert.is_true(showAll:IsShown())

		-- No Spectre has a skill with this name
		controls.source.controls.searchModeDropDown:SetSel(2)
		assert.are.equal(0, #controls.source.list)
		assert.is_false(showAll:IsShown())
	end)

	it("keeps Corpse Only enabled when expanding an empty search", function()
		local plainId, plainName = findHiddenSpectre(false)
		local corpseId, corpseName = findHiddenSpectre(true)
		setCorpseOnly(true)

		-- Show All would still hide a Spectre that has no itemised corpse
		searchText:SetText(plainName, true)
		assert.are.equal(0, #controls.source.list)
		assert.is_false(showAll:IsShown())

		searchText:SetText(corpseName, true)
		assert.are.equal(0, #controls.source.list)
		assert.is_true(showAll:IsShown())
		showAll.onClick()

		assert.is_true(corpseOnly.state)
		assert.is_true(showAllCheckbox.state)
		assert.is_truthy(isValueInArray(controls.source.list, corpseId))
		assert.is_nil(isValueInArray(controls.source.list, plainId))
	end)
end)
