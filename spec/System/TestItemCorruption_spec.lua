describe("Item corruption source transitions", function()
	local initialPopupCount

	local function assertImplicitSelectionsCleared(controls)
		for i = 1, 5 do
			assert.are.equal(1, controls["implicit" .. i].selIndex)
		end
	end

	before_each(function()
		newBuild()
		main:SelectControl()
		initialPopupCount = #main.popups
		build.itemsTab.displayItem = new("Item"):Item(main.uniqueDB.byTitle["glimpse of chaos"].raw)
		build.itemsTab:CorruptDisplayItem()
	end)

	after_each(function()
		main:SelectControl()
		while #main.popups > initialPopupCount do
			main:ClosePopup()
		end
	end)

	it("switches from Glimpse of Chaos to Scourge with the fifth implicit selected", function()
		local controls = main.popups[1].controls
		controls.implicit5:SetSel(2)
		assert.are.equal(2, controls.implicit5.selIndex)

		assert.has_no.errors(function()
			controls.source:SetSel(3)
		end)
		assert.are.equal("Scourge", controls.source:GetSelValue())
		assertImplicitSelectionsCleared(controls)
		assert.is_false(controls.implicit5:IsShown())
	end)

	it("clears implicit selections across adjacent source transitions", function()
		local controls = main.popups[1].controls
		local transitions = {
			{ fromSourceIndex = 1, implicitIndex = 5, toSourceIndex = 2 },
			{ fromSourceIndex = 2, implicitIndex = 5, toSourceIndex = 1 },
			{ fromSourceIndex = 2, implicitIndex = 4, toSourceIndex = 3 },
			{ fromSourceIndex = 3, implicitIndex = 4, toSourceIndex = 2 },
		}

		for _, transition in ipairs(transitions) do
			controls.source:SetSel(transition.fromSourceIndex)
			controls["implicit" .. transition.implicitIndex]:SetSel(2)
			assert.are.equal(2, controls["implicit" .. transition.implicitIndex].selIndex)
			controls.source:SetSel(transition.toSourceIndex)
			assert.are.equal(transition.toSourceIndex, controls.source.selIndex)
			assertImplicitSelectionsCleared(controls)
		end
	end)
end)
