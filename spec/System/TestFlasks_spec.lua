describe("Flasks", function()
	local function buildFlasks(rawFlasks, customMods)
		newBuild()
		build.configTab.input.customMods = customMods or ""
		build.configTab:BuildModList()

		local items, tooltips = { }, { }
		for index, raw in ipairs(rawFlasks) do
			local item = new("Item"):Item(raw)
			build.itemsTab:AddItem(item, true)
			local slot = build.itemsTab.slots["Flask " .. index]
			slot:SetSelItemId(item.id)
			slot.active = true
			items[index] = item
		end
		build.itemsTab.showStatDifferences = true
		build.buildFlag = true
		runCallback("OnFrame")

		for index, item in ipairs(items) do
			local tooltip = new("Tooltip"):Tooltip()
			build.itemsTab:AddItemTooltip(tooltip, item, build.itemsTab.slots["Flask " .. index])
			local lines = { }
			for _, line in ipairs(tooltip.lines) do
				table.insert(lines, line.text)
			end
			tooltips[index] = table.concat(lines, "\n"):gsub("%^%x", ""):gsub("%^x%x%x%x%x%x%x", "")
		end
		return build.calcsTab.mainOutput, tooltips, items
	end

	local function buildLifeFlask(customMods, instant)
		local output, tooltips, items = buildFlasks({ "Rarity: MAGIC\nTest Life Flask\nDivine Life Flask\n" .. (instant and "Instant Recovery" or "") },
			"Life Flask Effects are not removed when Unreserved Life is Filled\n" .. (customMods or ""))
		return output, tooltips[1], items[1].flaskData
	end

	local function buildUtilityFlasks(customMods)
		return buildFlasks({ "Rarity: NORMAL\nIron Flask", "Rarity: NORMAL\nGranite Flask" }, customMods)
	end

	it("applies Master Surgeon's recovery rate to active non-instant life flasks", function()
		local baselineOutput = buildLifeFlask()
		local reducedOutput, reducedTooltip, flaskData = buildLifeFlask("50% less Flask Life Recovery rate")
		assert.is_true(baselineOutput.LifeRecovery > 0)
		assert.are.equal(baselineOutput.LifeRecovery / 2, reducedOutput.LifeRecovery)
		local amount, duration = reducedTooltip:match("Life recovered: (%d+) over ([%d%.]+)s")
		assert.are.equal(flaskData.lifeTotal, tonumber(amount))
		assert.are.equal(tonumber(string.format("%.2f", flaskData.duration * 2)), tonumber(duration))
	end)

	it("does not change instant life flask recovery", function()
		local _, baselineTooltip = buildLifeFlask(nil, true)
		local _, reducedTooltip = buildLifeFlask("50% less Flask Life Recovery rate", true)

		assert.are.equal(baselineTooltip, reducedTooltip)
	end)

	it("applies Regenerative Runes only to Iron Flasks", function()
		local baseline = buildUtilityFlasks()
		local increased, tooltips = buildUtilityFlasks("20% increased Effect of Iron Flasks")

		assert.is_true(baseline.Ward > 0)
		assert.is_true(baseline.Armour > 0)
		assert.are.equal(math.floor(baseline.Ward * 1.2), increased.Ward)
		assert.are.equal(baseline.Armour, increased.Armour)
		assert.are.equal(20, tonumber(tooltips[1]:match("Flask effect modifier: ([%+%-]?[%d%.]+)%%")))
		assert.are.equal(0, tonumber(tooltips[2]:match("Flask effect modifier: ([%+%-]?[%d%.]+)%%")) or 0)
	end)

	it("adds Iron Flask effect to generic flask effect", function()
		local generic = buildUtilityFlasks("30% increased Effect of Flasks")
		local combined = buildUtilityFlasks("10% increased Effect of Flasks\n20% increased Effect of Iron Flasks")
		local genericControl = buildUtilityFlasks("10% increased Effect of Flasks")

		assert.are.equal(generic.Ward, combined.Ward)
		assert.are.equal(genericControl.Armour, combined.Armour)
	end)
end)
