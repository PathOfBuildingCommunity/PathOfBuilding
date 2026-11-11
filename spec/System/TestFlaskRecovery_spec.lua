describe("Flask recovery", function()
	local function buildLifeFlask(customMods, instant)
		newBuild()
		build.configTab.input.conditionUsingFlask = true
		build.configTab.input.customMods = "Life Flask Effects are not removed when Unreserved Life is Filled\n" .. (customMods or "")
		build.configTab:BuildModList()

		local item = new("Item"):Item("Rarity: MAGIC\nTest Life Flask\nDivine Life Flask\n" .. (instant and "Instant Recovery" or ""))
		build.itemsTab:AddItem(item, true)
		local flaskSlot = build.itemsTab.slots["Flask 1"]
		flaskSlot:SetSelItemId(item.id)
		flaskSlot.active = true
		build.itemsTab.showStatDifferences = true
		build.buildFlag = true
		runCallback("OnFrame")

		local tooltip = new("Tooltip"):Tooltip()
		build.itemsTab:AddItemTooltip(tooltip, item, build.itemsTab.slots["Flask 1"])
		local lines = { }
		for _, line in ipairs(tooltip.lines) do
			table.insert(lines, line.text)
		end
		return build.calcsTab.mainOutput, table.concat(lines, "\n")
	end

	it("applies Master Surgeon's recovery rate to active non-instant life flasks", function()
		local baselineOutput = buildLifeFlask()
		local reducedOutput, reducedTooltip = buildLifeFlask("50% less Life Flask Recovery Rate")
		assert.is_true(baselineOutput.LifeRecovery > 0)
		assert.are.equal(baselineOutput.LifeRecovery / 2, reducedOutput.LifeRecovery)
		assert.is_truthy(reducedTooltip:match("over %^77%.00s"))
	end)

	it("does not change instant life flask recovery", function()
		local _, baselineTooltip = buildLifeFlask(nil, true)
		local _, reducedTooltip = buildLifeFlask("50% less Life Flask Recovery Rate", true)

		assert.are.equal(baselineTooltip, reducedTooltip)
	end)
end)
