describe("Tinctures", function()
	before_each(function()
		newBuild()
	end)

	it("applies the numeric additional tincture limit and preserves the singular modifier", function()
		runCallback("OnFrame")
		local baseline = {}
		-- Synthetic resistance markers identify each tincture's contribution independently.
		local tinctures = {
			{ base = "Prismatic Tincture", resist = "Fire", value = 11 },
			{ base = "Rosethorn Tincture", resist = "Cold", value = 13 },
			{ base = "Ironwood Tincture", resist = "Lightning", value = 17 },
			{ base = "Ashbark Tincture", resist = "Chaos", value = 19 },
		}
		for index, tincture in ipairs(tinctures) do
			baseline[tincture.resist] = build.calcsTab.mainOutput[tincture.resist .. "Resist"]
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: NORMAL\n" .. tincture.base .. "\nImplicits: 0\n+" .. tincture.value .. "% to " .. tincture.resist .. " Resistance")
			local item = build.itemsTab.displayItem
			build.itemsTab:AddDisplayItem()
			local slot = build.itemsTab.slots["Flask " .. index]
			slot:SetSelItemId(item.id)
			slot.active = true
		end
		for _, case in ipairs({
			{ text = "", limit = 1 },
			{ text = "You can have an additional Tincture active", limit = 2 },
			{ text = "You can have 2 additional Tinctures active", limit = 3 },
			{ text = "", limit = 1 },
		}) do
			build.configTab.input.customMods = case.text
			build.configTab:BuildModList()
			runCallback("OnFrame")
			assert.are.equal(case.limit, build.calcsTab.mainOutput.TinctureLimit)
			for index, tincture in ipairs(tinctures) do
				local expected = baseline[tincture.resist] + (index <= case.limit and tincture.value or 0)
				assert.are.equal(expected, build.calcsTab.mainOutput[tincture.resist .. "Resist"], tincture.resist)
			end
		end
	end)
end)
