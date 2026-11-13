describe("Flask effect", function()
	local function buildFlasks(customMods)
		newBuild()
		build.configTab.input.customMods = customMods or ""
		build.configTab:BuildModList()

		local tooltips = { }
		for index, baseName in ipairs({ "Iron Flask", "Granite Flask" }) do
			local item = new("Item"):Item("Rarity: NORMAL\n" .. baseName)
			build.itemsTab:AddItem(item, true)
			local slot = build.itemsTab.slots["Flask " .. index]
			slot:SetSelItemId(item.id)
			slot.active = true
		end
		build.buildFlag = true
		runCallback("OnFrame")

		for index = 1, 2 do
			local slot = build.itemsTab.slots["Flask " .. index]
			local item = build.itemsTab.items[slot.selItemId]
			local tooltip = new("Tooltip"):Tooltip()
			build.itemsTab:AddItemTooltip(tooltip, item, slot)
			local lines = { }
			for _, line in ipairs(tooltip.lines) do
				table.insert(lines, line.text)
			end
			tooltips[index] = table.concat(lines, "\n"):gsub("%^%x", ""):gsub("%^x%x%x%x%x%x%x", "")
		end
		return build.calcsTab.mainOutput, tooltips
	end

	it("applies Regenerative Runes only to Iron Flasks", function()
		local baseline = buildFlasks()
		local increased, tooltips = buildFlasks("20% increased Effect of Iron Flasks")

		assert.is_true(baseline.Ward > 0)
		assert.is_true(baseline.Armour > 0)
		assert.are.equal(math.floor(baseline.Ward * 1.2), increased.Ward)
		assert.are.equal(baseline.Armour, increased.Armour)
		assert.are.equal(20, tonumber(tooltips[1]:match("Flask effect modifier: ([%+%-]?[%d%.]+)%%")))
		assert.are.equal(0, tonumber(tooltips[2]:match("Flask effect modifier: ([%+%-]?[%d%.]+)%%")) or 0)
	end)

	it("adds Iron Flask effect to generic flask effect", function()
		local generic = buildFlasks("30% increased Effect of Flasks")
		local combined = buildFlasks("10% increased Effect of Flasks\n20% increased Effect of Iron Flasks")
		local genericControl = buildFlasks("10% increased Effect of Flasks")

		assert.are.equal(generic.Ward, combined.Ward)
		assert.are.equal(genericControl.Armour, combined.Armour)
	end)
end)
