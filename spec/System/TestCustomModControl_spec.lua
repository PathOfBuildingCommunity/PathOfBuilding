describe("Custom modifier controls", function()
	local initialPopupCount

	before_each(function()
		newBuild()
		main:SelectControl()
		initialPopupCount = #main.popups
	end)

	after_each(function()
		main:SelectControl()
		while #main.popups > initialPopupCount do
			main:ClosePopup()
		end
	end)

	local function openModBrowser()
		local configTab = build.configTab
		local blockData = configTab.configSets[configTab.activeConfigSetId].customModsList[1]
		configTab:OpenAddModPopup(blockData)
		return main.popups[1], blockData
	end

	it("does not retain the modifier list focus after adding a mod", function()
		local popup, blockData = openModBrowser()
		local listControl = popup.controls.listControl
		local selectedMod = listControl.list[1]

		listControl:OnSelClick(1, selectedMod, false)
		popup.controls.save.onClick()

		assert.is_nil(main.selControl)
		assert.are_not.equal(popup, main.popups[1])
		assert.are.equal(itemLib.applyRange(selectedMod, 0.5), blockData.text)
	end)

	it("collapses numeric tiers of the same modifier", function()
		local popup = openModBrowser()
		local minionDamageEntries = { }
		for _, modText in ipairs(popup.controls.listControl.list) do
			if modText:match("^Minions deal .-%% increased Damage$") then
				table.insert(minionDamageEntries, modText)
			end
		end

		assert.are.same({ "Minions deal (10-11)% increased Damage" }, minionDamageEntries)
	end)

	it("orders modifiers by their number-independent stat text", function()
		local popup = openModBrowser()
		local previousTemplate
		for _, modText in ipairs(popup.controls.listControl.list) do
			local modTemplate = modText
				:gsub("([%+-]?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", "%1#")
				:gsub("%d+%.?%d*", "#")
				:lower()
			assert.is_true(not previousTemplate or previousTemplate < modTemplate,
				tostring(previousTemplate) .. " should be ordered before " .. modTemplate)
			previousTemplate = modTemplate
		end
	end)

	it("clears the modifier search with its clear button", function()
		local popup = openModBrowser()
		local controls = popup.controls
		local unfilteredCount = #controls.listControl.list
		assert.is_false(controls.search.controls.buttonClear:IsShown())
		controls.search:SetText("minion damage", true)

		assert.is_true(#controls.listControl.list < unfilteredCount)
		assert.are.equal("minion damage", controls.search.buf)
		assert.is_true(controls.search.controls.buttonClear:IsShown())

		controls.search.controls.buttonClear.onClick()

		assert.are.equal("", controls.search.buf)
		assert.are.equal(unfilteredCount, #controls.listControl.list)
		assert.is_false(controls.search.controls.buttonClear:IsShown())
	end)

	it("uses the expanded browser dimensions", function()
		local popup = openModBrowser()
		local listWidth, listHeight = popup.controls.listControl:GetSize()
		local searchWidth = popup.controls.search:GetSize()

		assert.are.equal(720, popup.width)
		assert.are.equal(540, popup.height)
		assert.are.equal(700, listWidth)
		assert.are.equal(454, listHeight)
		assert.are.equal(640, searchWidth)
	end)
end)
