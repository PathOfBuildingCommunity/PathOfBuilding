describe("Flasks", function()
	local function buildFlasks(rawFlasks, customMods)
		newBuild()
		build.configTab.input.customMods = customMods or ""
		build.configTab:BuildModList()

		for index, raw in ipairs(rawFlasks) do
			local item = new("Item"):Item(raw)
			build.itemsTab:AddItem(item, true)
			local slot = build.itemsTab.slots["Flask " .. index]
			slot:SetSelItemId(item.id)
			slot.active = true
		end
		build.buildFlag = true
		runCallback("OnFrame")
		return build.calcsTab.mainOutput
	end

	local function buildLifeFlask(customMods)
		return buildFlasks({ "Rarity: MAGIC\nTest Life Flask\nDivine Life Flask" },
			"Life Flask Effects are not removed when Unreserved Life is Filled\n" .. (customMods or ""))
	end

	local function buildUtilityFlasks(customMods)
		return buildFlasks({ "Rarity: NORMAL\nIron Flask", "Rarity: NORMAL\nGranite Flask" }, customMods)
	end

	it("applies Master Surgeon's recovery rate to active non-instant life flasks", function()
		local baselineOutput = buildLifeFlask()
		local reducedOutput = buildLifeFlask("50% less Flask Life Recovery rate")
		assert.is_true(baselineOutput.LifeRecovery > 0)
		assert.are.equal(baselineOutput.LifeRecovery / 2, reducedOutput.LifeRecovery)
	end)

	it("applies Regenerative Runes only to Iron Flasks", function()
		local baseline = buildUtilityFlasks()
		local increased = buildUtilityFlasks("20% increased Effect of Iron Flasks")

		assert.is_true(baseline.Ward > 0)
		assert.is_true(baseline.Armour > 0)
		assert.are.equal(math.floor(baseline.Ward * 1.2), increased.Ward)
		assert.are.equal(baseline.Armour, increased.Armour)
	end)

	it("adds Iron Flask effect to generic flask effect", function()
		local generic = buildUtilityFlasks("30% increased Effect of Flasks")
		local combined = buildUtilityFlasks("10% increased Effect of Flasks\n20% increased Effect of Iron Flasks")
		local genericControl = buildUtilityFlasks("10% increased Effect of Flasks")

		assert.are.equal(generic.Ward, combined.Ward)
		assert.are.equal(genericControl.Armour, combined.Armour)
	end)
end)
