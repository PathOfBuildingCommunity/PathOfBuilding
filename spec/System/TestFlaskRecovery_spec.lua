describe("Flask recovery", function()
	local function containsLifeFlaskRecoveryRateMore(data)
		if type(data) ~= "table" then
			return false
		end
		if data.modName == "FlaskLifeRecoveryRate" and data.modType == "MORE" then
			return true
		end
		for _, field in pairs(data) do
			if containsLifeFlaskRecoveryRateMore(field) then
				return true
			end
		end
		return false
	end

	local function hasLifeFlaskRecoveryRateSection(data)
		if type(data) ~= "table" then
			return false
		end
		if data.label == "More Recovery Rate" then
			return containsLifeFlaskRecoveryRateMore(data)
		end
		for _, field in pairs(data) do
			if hasLifeFlaskRecoveryRateSection(field) then
				return true
			end
		end
		return false
	end

	local function buildLifeFlask(customMods, instant)
		newBuild()
		build.configTab.input.conditionUsingFlask = true
		build.configTab.input.customMods = "Life Flask Effects are not removed when Unreserved Life is Filled\n" .. (customMods or "")
		build.configTab:BuildModList()

		local item = new("Item"):Item((instant and [[Rarity: MAGIC
Test Life Flask
Divine Life Flask
Instant Recovery]] or [[Rarity: MAGIC
Test Life Flask
Divine Life Flask]]))
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
		return item, build.calcsTab.mainOutput, table.concat(lines, "\n")
	end

	it("applies Master Surgeon's recovery rate to active non-instant life flasks", function()
		local item, baselineOutput = buildLifeFlask()
		local _, reducedOutput, reducedTooltip = buildLifeFlask("50% less Life Flask Recovery Rate")
		assert.is_truthy(item.base.flask.life)
		assert.is_true(baselineOutput.LifeRecovery > 0)
		assert.is_true(math.abs(reducedOutput.LifeRecovery - baselineOutput.LifeRecovery / 2) < 0.001)
		assert.is_truthy(reducedTooltip:match("Life recovered"))
		assert.is_truthy(reducedTooltip:match("over %^77%.00s"))
	end)

	it("does not change instant life flask recovery", function()
		local _, _, baselineTooltip = buildLifeFlask(nil, true)
		local _, _, reducedTooltip = buildLifeFlask("50% less Life Flask Recovery Rate", true)

		assert.are.equal(baselineTooltip, reducedTooltip)
	end)

	it("lists life flask recovery rate multipliers in the calculations section", function()
		assert.is_true(hasLifeFlaskRecoveryRateSection(LoadModule("Modules/CalcSections")))
	end)
end)
