describe("Vestigial quivers", function()
	local addImplicit = require("Modules.AddImplicitPopup")
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

	local function vestigialMods(title)
		build.itemsTab.displayItem = new("Item"):Item(main.uniqueDB.byTitle[title:lower()].raw)
		addImplicit.AddImplicitToDisplayItem(build.itemsTab, build.itemsTab.displayItem)
		local controls = main.popups[1].controls
		for i, source in ipairs(controls.source.list) do
			if source.sourceId == "VESTIGIAL" then
				controls.source:SetSel(i)
				local byTitle = { }
				for _, group in ipairs(controls.modGroupSelect.list) do
					byTitle[group.uniqueTitle] = group.id
				end
				return byTitle
			end
		end
	end

	it("maps quiver vestigial mods to their unique", function()
		assert.are.equal("Drillneck", data.vestigialModMappings["DivergentArrowDamageAgainstPiercedTargetsUnique__1"])
		assert.are.equal("Blackgleam", data.vestigialModMappings["DivergentConvertPhysicalToFireUniqueQuiver1_"])
		assert.are.equal("Skirmish", data.vestigialModMappings["DivergentAdditionalAttackTotemsUnique__1"])
	end)

	it("offers other quivers' vestigial mods on a unique quiver", function()
		local byTitle = vestigialMods("Drillneck")
		assert.is_truthy(byTitle)
		assert.are.equal("DivergentConvertPhysicalToFireUniqueQuiver1_", byTitle["Blackgleam"])
		assert.is_truthy(byTitle["Soul Strike"])
		assert.is_nil(byTitle["Drillneck"])
		-- other item classes are not offered
		assert.is_nil(byTitle["Goldrim"])
	end)

	it("adds a vestigial implicit to a unique quiver", function()
		vestigialMods("Drillneck")
		local controls = main.popups[1].controls
		for i, group in ipairs(controls.modGroupSelect.list) do
			if group.uniqueTitle == "Blackgleam" then
				controls.modGroupSelect:SetSel(i)
				break
			end
		end
		controls.save.onClick()
		local item = build.itemsTab.displayItem
		assert.is_true(item.vestigial)
		assert.are.equal(1, #item.implicitModLines)
		assert.is_true(item.implicitModLines[1].vestigial)
		assert.is_truthy(item.implicitModLines[1].line:find("Converted to Fire Damage", 1, true))
	end)
end)
