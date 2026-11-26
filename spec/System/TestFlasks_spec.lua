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

	local function flaskTooltipDurations()
		local slot = build.itemsTab.slots["Flask 1"]
		local item = build.itemsTab.items[slot.selItemId]
		local tooltip = new("Tooltip"):Tooltip()
		build.itemsTab:AddItemTooltip(tooltip, item, slot)

		local durations = {}
		for _, line in ipairs(tooltip.lines) do
			local resource, duration = (line.text or ""):match("^%^8(%a+) recovered: .-over %^7([%d.]+)s$")
			if resource then
				durations[resource] = tonumber(duration)
			end
		end
		return durations
	end

	local recoveryFlags = "Life Flask Effects are not removed when Unreserved Life is Filled\n"
		.. "Mana Flask Effects are not removed when Unreserved Mana is Filled"
	local recoveryRateMods = "\n30% increased Flask Recovery rate\n34% increased Flask Life Recovery rate"
		.. "\n20% increased Flask Mana Recovery rate\n50% less Flask Life Recovery rate"

	it("applies Master Surgeon's recovery rate to active non-instant life flasks", function()
		local baselineOutput = buildLifeFlask()
		local reducedOutput = buildLifeFlask("50% less Flask Life Recovery rate")
		assert.is_true(baselineOutput.LifeRecovery > 0)
		assert.are.equal(baselineOutput.LifeRecovery / 2, reducedOutput.LifeRecovery)
	end)

	it("adds generic and life-specific flask recovery rate before the Master Surgeon multiplier in the tooltip", function()
		buildFlasks({ "Rarity: NORMAL\nSmall Life Flask" },
			recoveryFlags .. recoveryRateMods .. "\n106% increased Flask Effect Duration")
		assert.are.equal(7.54, flaskTooltipDurations().Life)
	end)

	it("uses the separate additive recovery rates in the tooltip for a hybrid flask", function()
		buildFlasks({ "Rarity: NORMAL\nHallowed Hybrid Flask" }, recoveryFlags .. recoveryRateMods)
		local durations = flaskTooltipDurations()
		assert.are.equal(3.33, durations.Mana)
		assert.are.equal(6.10, durations.Life)
	end)

	it("uses the same additive rates when calculating active hybrid flask recovery", function()
		local flasks = { "Rarity: NORMAL\nHallowed Hybrid Flask" }
		local baseline = buildFlasks(flasks, recoveryFlags)
		local combined = buildFlasks(flasks, recoveryFlags .. recoveryRateMods)
		assert.is_true(baseline.LifeRecovery > 0)
		assert.is_true(baseline.ManaRecovery > 0)
		assert.are.near(baseline.LifeRecovery * 1.64 * 0.5, combined.LifeRecovery, 1e-6)
		assert.are.near(baseline.ManaRecovery * 1.50, combined.ManaRecovery, 1e-6)
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
