describe("Reflecting Mist", function()
	local mist = require("Modules.ReflectingMist")
	local function item(lines, base)
		return new("Item"):Item("Rarity: Rare\nMist Test\n" .. (base or "Coral Ring") .. "\nImplicits: 0\n" .. (lines or ""))
	end

	it("offers exact current and legacy multiplier steps", function()
		for _, case in ipairs({ { false, 1.3, 0.01, 31 }, { true, 1.5, 0.025, 25 } }) do
			local list = mist.GetMultipliers(case[1])
			assert.are.equals(case[4], #list)
			for i, entry in ipairs(list) do
				assert.near(case[2] + (i - 1) * case[3], entry.multiplier, 0.000001)
			end
		end
	end)

	it("parses both outcomes of added physical damage to spells", function()
		local source = item("Adds 11 to 34 Physical Damage to Spells")
		for _, negative in ipairs({ false, true }) do
			local reflected = mist.ReflectItem(source, 1.6, { negative })
			local loaded = new("Item"):Item(reflected:BuildRaw())
			for _, result in ipairs({ reflected, loaded }) do
				local line = result.explicitModLines[1]
				assert.are.equals(nil, line.extra)
				assert.are.equals(2, #line.modList)
				for i, stat in ipairs({ "PhysicalMin", "PhysicalMax" }) do
					assert.are.equals(stat, line.modList[i].name)
					assert.are.equals(({ 17, 54 })[i] * (negative and -1 or 1), line.modList[i].value)
					assert.are.equals(KeywordFlag.Spell, line.modList[i].keywordFlags)
				end
			end
		end
	end)

	it("restricts reflection to eligible rare jewellery", function()
		assert.is_true(mist.CanReflect(item("+50 to maximum Life")))
		assert.is_true(mist.CanReflect(item("{fractured}+50 to maximum Life", "Simplex Amulet")))
		assert.is_false(mist.CanReflect(item("", "Leather Belt")))
		assert.is_false(mist.CanReflect(item("", "Unset Ring")))
		for _, flag in ipairs({ "corrupted", "mirrored", "synthesised", "veiled", "shaper", "elder", "crusader" }) do
			local source = item()
			source[flag] = true
			assert.is_false(mist.CanReflect(source))
		end
		for _, rarity in ipairs({ "NORMAL", "MAGIC", "UNIQUE", "RELIC" }) do
			local source = item()
			source.rarity = rarity
			assert.is_false(mist.CanReflect(source))
		end
	end)

	it("truncates reflection before applying base and catalyst bonuses", function()
		local source = new("Item"):Item([[
Rarity: Rare
Mist Test
Simplex Amulet
Catalyst: Intrinsic
CatalystQuality: 20
Implicits: 1
100% increased Explicit Modifier magnitudes
{range:1}{tags:attribute}+11 to Strength
+1 to Level of all Skill Gems
]])
		local reflected = mist.ReflectItem(source, 1.6, { true })
		assert.are.equals("-17 to Strength", reflected.explicitModLines[1].line)
		assert.are.equals(-37, reflected.explicitModLines[1].modList[1].value)
		assert.are.equals("+1 to Level of all Skill Gems", reflected.explicitModLines[2].line)
		assert.is_true(reflected.mirrored)
		assert.is_false(reflected.corrupted or false)
		local loaded = new("Item"):Item(reflected:BuildRaw())
		assert.are.equals(-37, loaded.explicitModLines[1].modList[1].value)
		assert.are.equals(source:BuildRaw(), new("Item"):Item(source:BuildRaw()):BuildRaw())
	end)

	local experimentedBases = {
		{ name = "Cogwork Ring", prefixBonus = 0, suffixBonus = 25 },
		{ name = "Geodesic Ring", prefixBonus = 25, suffixBonus = 0 },
		{ name = "Composite Ring", prefixBonus = 0 },
		{ name = "Manifold Ring", prefixBonus = 50, suffixBonus = 0 },
		{ name = "Ratcheting Ring", suffixBonus = 0 },
		{ name = "Helical Ring", prefixBonus = 0, suffixBonus = 50 },
		{ name = "Simplex Amulet", prefixBonus = 100, suffixBonus = 100 },
		{ name = "Focused Amulet", prefixBonus = 100, suffixBonus = 100 },
	}
	local function experimentedItem(baseName, catalyst, prefix, suffix)
		local base = data.itemBases[baseName]
		local _, newlines = base.implicit:gsub("\n", "")
		local raw = "Rarity: Rare\nMist Test\n" .. baseName .. "\n"
		if catalyst then
			raw = raw .. "Catalyst: " .. catalyst .. "\nCatalystQuality: 20\n"
		end
		raw = raw .. "Implicits: " .. (newlines + 1) .. "\n" .. base.implicit .. "\n"
		if prefix then raw = raw .. "{prefix}{tags:life}+(11-11) to maximum Life\n" end
		if suffix then raw = raw .. "{suffix}{tags:attribute}+(11-11) to Strength\n" end
		return new("Item"):Item(raw)
	end

	it("checks reflection eligibility for every experimented base", function()
		local expectedJewellery = { ["Astrolabe Amulet"] = false }
		for _, base in ipairs(experimentedBases) do expectedJewellery[base.name] = true end
		local jewellery = {}
		for name, base in pairs(data.itemBases) do
			if base.tags and base.tags.experimental_base then
				local source = experimentedItem(name)
				local eligible = expectedJewellery[name] == true
				assert.are.equals(eligible, mist.CanReflect(source), name)
				if base.type == "Ring" or base.type == "Amulet" then
					jewellery[name] = eligible
				end
			end
		end
		assert.same(expectedJewellery, jewellery)
	end)

	for _, base in ipairs(experimentedBases) do
		for _, catalyst in ipairs({ "None", "Sinistral", "Dextral" }) do
			it("reflects and reloads " .. base.name .. " with " .. catalyst .. " catalyst at every multiplier", function()
				local source = experimentedItem(base.name, catalyst ~= "None" and catalyst or nil,
					base.prefixBonus ~= nil, base.suffixBonus ~= nil)
				local original = source:BuildRaw()
				assert.is_true(mist.CanReflect(source))
				local prepared = mist.PrepareItem(source)
				for _, legacy in ipairs({ false, true }) do
					for _, entry in ipairs(mist.GetMultipliers(legacy)) do
						for negativeGroup = 1, 2 do
							local negatives = {}
							for i, modLine in ipairs(prepared.explicitModLines) do
								negatives[i] = modLine.prefix and negativeGroup == 1 or modLine.suffix and negativeGroup == 2
							end
							local reflected = mist.ReflectItem(prepared, entry.multiplier, negatives)
							local loaded = new("Item"):Item(reflected:BuildRaw())
							assert.is_true(loaded.mirrored)
							assert.are.equals(entry.multiplier, loaded.reflectionMultiplier)
							assert.are.equals(source.catalyst, loaded.catalyst)
							assert.are.equals(source.catalystQuality, loaded.catalystQuality)
							for i, implicit in ipairs(source.implicitModLines) do
								assert.are.equals(implicit.line, loaded.implicitModLines[i].line)
							end
							for i, modLine in ipairs(reflected.explicitModLines) do
								local bonus = modLine.prefix and base.prefixBonus or base.suffixBonus
								local quality = (modLine.prefix and catalyst == "Sinistral" or modLine.suffix and catalyst == "Dextral") and 20 or 0
								-- Independent integer oracle: truncate the mist first, then add
								-- catalyst and base magnitudes before the final truncation.
								local misted = math.floor(11 * entry.multiplier)
								local expected = math.floor(misted * (100 + bonus + quality) / 100)
								if negatives[i] then expected = -expected end
								assert.are.equals(expected, modLine.modList[1].value)
								assert.are.equals(expected, loaded.explicitModLines[i].modList[1].value)
								assert.is_false(modLine.extra or false)
								assert.is_false(loaded.explicitModLines[i].extra or false)
							end
						end
					end
				end
				assert.are.equals(original, source:BuildRaw())
			end)
		end
	end

	it("inverts ordinary stats and preserves non-scalable numbers", function()
		local cases = {
			{ "+(40-50) to maximum Life", "-80 to maximum Life" },
			{ "20% increased Cast Speed", "32% reduced Cast Speed" },
			{ "10% reduced Mana Cost of Skills", "16% increased Mana Cost of Skills" },
			{ "Non-Channelling Skills have -7 to Total Mana Cost", "Non-Channelling Skills have +11 to Total Mana Cost" },
			{ "Grants Level 20 Aspect of the Spider Skill", "Grants Level 20 Aspect of the Spider Skill" },
			{ "Can have up to 3 Crafted Modifiers", "Can have up to 3 Crafted Modifiers" },
		}
		for _, case in ipairs(cases) do
			assert.are.equals(case[2], mist.ReflectModLine({ line = case[1], range = 1 }, 1.6, true))
		end
	end)

	it("uses exported inverted descriptions for special negatives", function()
		local cases = {
			{ "Adds 10 to 20 Fire Damage to Attacks", "Adds 16 to 32 Fire Damage to Attacks against you" },
			{ "10 to 20 Added Cold Damage per Frenzy Charge", "Adds 16 to 32 Cold Damage to Hits against you per Frenzy Charge" },
			{ "Regenerate 10 Life per second", "Lose 16 Life per second" },
			{ "0.5% of Physical Attack Damage Leeched as Life", "0.8% of Physical Attack Damage Leeched by Enemy as Life" },
			{ "Shock nearby Enemies for 4 Seconds when you Focus", "Shock yourself for 6.4 Seconds when you Focus" },
			{ "10% chance to gain a Frenzy Charge on Kill", "16% chance to lose a Frenzy Charge on Kill" },
			{ "Gain 10% of Physical Damage as Extra Fire Damage", "Hits against you gain 16% of Physical Damage as Extra Fire Damage" },
			{ "You and your Minions prevent +60% of Reflected Damage", "You and your Minions take 96% increased Reflected Damage" },
		}
		for _, case in ipairs(cases) do
			assert.are.equals(case[2], mist.ReflectModLine({ line = case[1] }, 1.6, true))
		end
	end)

	it("preserves every beast Aspect and modifiers without negative versions", function()
		local lines = {
			"Grants Level 20 Aspect of the Avian Skill",
			"Grants Level 20 Aspect of the Cat Skill",
			"Grants Level 30 Aspect of the Crab Skill",
			"Grants Level 30 Aspect of the Spider Skill",
			"Can have up to 3 Crafted Modifiers",
			"Warcries cannot Exert Travel Skills",
			"Light Radius is based on Energy Shield instead of Life",
		}
		for _, legacy in ipairs({ false, true }) do
			for _, entry in ipairs(mist.GetMultipliers(legacy)) do
				for _, line in ipairs(lines) do
					for _, negative in ipairs({ false, true }) do
						assert.are.equals(line, mist.ReflectModLine({ line = line }, entry.multiplier, negative))
					end
				end
			end
		end
		local source = experimentedItem("Simplex Amulet", "Imbued")
		for _, line in ipairs(lines) do
			table.insert(source.explicitModLines, { line = line, modTags = { "caster" } })
		end
		source:BuildAndParseRaw()
		local negatives = {}
		for i = 1, #lines do negatives[i] = true end
		local reflected = mist.ReflectItem(source, 2.1, negatives)
		local loaded = new("Item"):Item(reflected:BuildRaw())
		local groups = mist.GetModGroups(source)
		for i, line in ipairs(lines) do
			assert.are.equals(line, loaded.explicitModLines[i].line)
			assert.is_false(groups[i].canInvert or false)
		end
	end)

	it("preserves explicitly unscalable values and their selected rolls", function()
		for _, line in ipairs({
			"{unscalable}+11 to maximum Life",
			"{unscalable}{range:0.25}+(11-19) to maximum Life",
		}) do
			local source = item(line)
			local expected = itemLib.applyRange(source.explicitModLines[1].line, source.explicitModLines[1].range, 1)
			for _, multiplier in ipairs({ 1.3, 1.6, 1.525, 2.1 }) do
				for _, negative in ipairs({ false, true }) do
					local reflected = mist.ReflectItem(source, multiplier, { negative })
					local loaded = new("Item"):Item(reflected:BuildRaw())
					assert.is_true(loaded.explicitModLines[1].unscalable)
					assert.are.equals(expected, itemLib.applyRange(loaded.explicitModLines[1].line, loaded.explicitModLines[1].range, 1))
					assert.is_false(mist.GetModGroups(source)[1].canInvert or false)
				end
			end
		end
	end)

	it("shows neutral states for Aspects and unscalable modifiers instead of sign buttons", function()
		newBuild()
		build.itemsTab:SetDisplayItem(item("Grants Level 20 Aspect of the Spider Skill\n{unscalable}+11 to maximum Life\n+30% to Fire Resistance"))
		mist.OpenPopup(build.itemsTab)
		local controls = main.popups[1].controls
		assert.are.equals(nil, controls.positive1)
		assert.are.equals(nil, controls.negative1)
		assert.are.equals(nil, controls.positive2)
		assert.are.equals(nil, controls.negative2)
		assert.are.equals("^8Cannot be reflected", controls.state1.label)
		assert.are.equals("^8Cannot be reflected", controls.state2.label)
		assert.is_false(controls.state1:IsEnabled())
		assert.is_false(controls.state2:IsEnabled())
		local viewPort = { x = 0, y = 0, width = 1920, height = 1080 }
		main.popups[1]:Draw(viewPort)
		assert.is_true(controls.negative3:IsEnabled())
		controls.negative3:Click()
		controls.multiplier:SetVal(1)
		assert.is_truthy(controls.mod1.label:find("Grants Level 20 Aspect of the Spider Skill", 1, true))
		assert.is_truthy(controls.mod2.label:find("+11 to maximum Life", 1, true))
		assert.is_truthy(controls.mod3.label:find("-48% to Fire Resistance", 1, true))
		controls.close.onClick()
	end)

	it("distinguishes a scalable modifier without a negative version from an unchanged modifier", function()
		newBuild()
		build.itemsTab:SetDisplayItem(item("Damage Penetrates 10% Elemental Resistances"))
		mist.OpenPopup(build.itemsTab)
		local controls = main.popups[1].controls
		assert.are.equals(nil, controls.positive1)
		assert.are.equals(nil, controls.negative1)
		assert.are.equals("^8No negative version", controls.state1.label)
		main.popups[1]:Draw({ x = 0, y = 0, width = 1920, height = 1080 })
		controls.multiplier:SetVal(1)
		assert.is_truthy(controls.mod1.label:find("Damage Penetrates 16% Elemental Resistances", 1, true))
		controls.close.onClick()
	end)

	it("keeps hybrid modifier signs together", function()
		local source = item("{modGroup:hybrid}+40 to maximum Life\n{modGroup:hybrid}Regenerate 4 Mana per second\n+30% to Fire Resistance")
		local groups = mist.GetModGroups(source)
		assert.are.equals(2, #groups)
		assert.same({ 1, 2 }, groups[1].indices)
		local reflected = mist.ReflectItem(source, 1.5, { true, true })
		assert.are.equals("-60 to maximum Life", reflected.explicitModLines[1].line)
		assert.are.equals("Lose 6 Mana per second", reflected.explicitModLines[2].line)
		assert.are.equals("+45% to Fire Resistance", reflected.explicitModLines[3].line)
	end)

	it("keeps prefix and suffix markers when adding modifiers through the editor", function()
		newBuild()
		for _, sourceId in ipairs({ "MASTER", "ESSENCE", "VEILED", "PREFIX", "SUFFIX", "INCURSION", "DELVE" }) do
			build.itemsTab:SetDisplayItem(experimentedItem("Helical Ring"))
			build.itemsTab:AddCustomModifierToDisplayItem()
			local controls = main.popups[1].controls
			local found = false
			for i, source in ipairs(controls.source.list) do
				if source.sourceId == sourceId then controls.source:SetSel(i); found = true; break end
			end
			assert.is_true(found)
			local mod = controls.modSelect.list[controls.modSelect.selIndex].mod
			assert.is_true(mod.type == "Prefix" or mod.type == "Suffix")
			controls.save.onClick()
			for _, line in ipairs(build.itemsTab.displayItem.explicitModLines) do
				assert.are.equals(mod.type == "Prefix", line.prefix or false)
				assert.are.equals(mod.type == "Suffix", line.suffix or false)
			end
		end
	end)

	it("applies Helical suffix magnitudes to reflected bench minimum charges", function()
		for _, charge in ipairs({ "Endurance", "Frenzy", "Power" }) do
			for _, crafted in ipairs({ false, true }) do
				local source = experimentedItem("Helical Ring")
				table.insert(source.explicitModLines, { line = "+1 to Minimum " .. charge .. " Charges", crafted = true })
				source.crafted = crafted
				source:BuildAndParseRaw()
				local original = source:BuildRaw()
				assert.are.equals(1, source.explicitModLines[1].modList[1].value)
				for _, entry in ipairs(mist.GetMultipliers(true)) do
					local reflected = mist.ReflectItem(mist.PrepareItem(source), entry.multiplier, {})
					local loaded = new("Item"):Item(reflected:BuildRaw())
					for _, result in ipairs({ reflected, loaded }) do
						local mod = result.explicitModLines[1]
						assert.is_true(mod.suffix)
						assert.is_true(mod.crafted)
						assert.are.equals(charge .. "ChargesMin", mod.modList[1].name)
						assert.are.equals(entry.multiplier >= 2 and 3 or 1, mod.modList[1].value)
					end
				end
				assert.are.equals(original, source:BuildRaw())
			end
		end
	end)

	it("previews and saves three crafted minimum charges on a legacy Helical reflection", function()
		newBuild()
		local source = experimentedItem("Helical Ring")
		table.insert(source.explicitModLines, { line = "+1 to Minimum Endurance Charges", crafted = true })
		source:BuildAndParseRaw()
		build.itemsTab:SetDisplayItem(source)
		mist.OpenPopup(build.itemsTab)
		local controls = main.popups[1].controls
		controls.legacy.state = true
		controls.legacy.changeFunc(true)
		controls.multiplier:SetVal(19 / 24)
		assert.is_truthy(controls.mod1.label:find("+1 to Minimum Endurance Charges", 1, true))
		controls.multiplier:SetVal(20 / 24)
		assert.is_truthy(controls.mod1.label:find("+3 to Minimum Endurance Charges", 1, true))
		controls.save.onClick()
		local itemsTab = build.itemsTab
		local saved = itemsTab.items[itemsTab.itemOrderList[#itemsTab.itemOrderList]]
		assert.are.equals(3, saved.explicitModLines[1].modList[1].value)
		assert.are.equals(3, new("Item"):Item(saved:BuildRaw()).explicitModLines[1].modList[1].value)
		assert.are.equals(source, itemsTab.displayItem)
	end)

	it("separates crafted hybrid affixes before choosing signs", function()
		local source = item("Crafted: true\nPrefix: {range:1}IncreasedLife1\nPrefix: {range:1}IncreasedManaEnhancedLevel50ModRegen")
		source:Craft()
		local prepared = mist.PrepareItem(source)
		local groups = mist.GetModGroups(prepared)
		assert.are.equals(2, #groups)
		assert.are.equals(2, #groups[2].indices)
		local negatives = {}
		for _, index in ipairs(groups[2].indices) do negatives[index] = true end
		local reflected = mist.ReflectItem(prepared, 1.5, negatives)
		assert.are.equals("+36 to maximum Life", reflected.explicitModLines[1].line)
		assert.are.equals("-117 to maximum Mana", reflected.explicitModLines[2].line)
		assert.are.equals("Lose 10.5 Mana per second", reflected.explicitModLines[3].line)
	end)

	it("preserves implicits, enchantments and fractured modifiers", function()
		local source = new("Item"):Item([[
Rarity: Rare
Mist Test
Coral Ring
Implicits: 2
{enchant}Allocates Beef
+30 to maximum Life
{fractured}+50 to maximum Life
+]])
		local reflected = mist.ReflectItem(source, 2.1, { true })
		assert.are.equals(source.implicitModLines[1].line, reflected.implicitModLines[1].line)
		assert.are.equals(source.enchantModLines[1].line, reflected.enchantModLines[1].line)
		assert.is_true(reflected.explicitModLines[1].fractured)
		assert.are.equals("-105 to maximum Life", reflected.explicitModLines[1].line)
	end)

	it("keeps long custom modifier previews inside the popup", function()
		newBuild()
		local text = "A long custom modifier " .. string.rep("with several short words ", 8)
			.. string.rep("W", 150)
		build.itemsTab:SetDisplayItem(item(text))
		local originalWidth = DrawStringWidth
		local ok, err = pcall(function()
			-- The headless renderer does not measure fonts. Supply a nonzero glyph
			-- width so this test catches both late word breaks and unbroken words.
			-- Set the real global because Busted isolates assignments within specs.
			_G.DrawStringWidth = function(_, _, value)
				local _, glyphs = StripEscapes(value):gsub("[%z\1-\127\194-\244][\128-\191]*", "")
				return glyphs * 8
			end
			mist.OpenPopup(build.itemsTab)
			local popup = main.popups[1]
			local controls = popup.controls
			local count = 0
			local reconstructed = {}
			for line in controls.mod1.label:gmatch("[^\n]+") do
				assert.is_true(DrawStringWidth(16, "VAR", line) <= 470)
				assert.is_true(controls.mod1.x + DrawStringWidth(16, "VAR", line) < popup.width)
				local plain = StripEscapes(line)
				-- A continuation byte must never start a wrapped line.
				assert.is_false(plain:byte(1) >= 128 and plain:byte(1) < 192)
				table.insert(reconstructed, plain)
				count = count + 1
			end
			assert.is_true(count > 5)
			assert.are.equals(text:gsub("%s", ""), table.concat(reconstructed):gsub("%s", ""))
			assert.is_true(controls.showComparisons.y >= controls.mod1.y + count * 16)
			controls.close.onClick()
		end)
		_G.DrawStringWidth = originalWidth
		assert(ok, err)
	end)

	it("compares reflection changes live against the equipped build without changing it", function()
		newBuild()
		build.controls.characterLevel:SetText("90", true)
		local itemsTab = build.itemsTab
		for _, life in ipairs({ 50, 100 }) do
			itemsTab:SetDisplayItem(item("+" .. life .. " to maximum Life"))
			itemsTab:AddDisplayItem()
		end
		runCallback("OnFrame")
		local ring1, ring2 = itemsTab.slots["Ring 1"].selItemId, itemsTab.slots["Ring 2"].selItemId
		local source = itemsTab.items[ring2]
		itemsTab:SetDisplayItem(source)
		local original = source:BuildRaw()
		local originalLife = build.calcsTab.mainOutput.Life
		mist.OpenPopup(itemsTab)
		local popup = main.popups[1]
		local controls = popup.controls
		local compactHeight = popup.height
		assert.is_false(controls.showComparisons.state)
		assert.is_false(controls.comparison:IsShown())
		assert.are.equals(0, #controls.comparison.tooltip.lines)
		local function hasLifeChange(value)
			for _, line in ipairs(controls.comparison.tooltip.lines) do
				if line.text and StripEscapes(line.text):find(value .. " Total Life", 1, true) then return true end
			end
			return false
		end
		assert.are.equals(nil, controls.compareSlot)
		controls.multiplier:SetVal(0)
		assert.are.equals(0, #controls.comparison.tooltip.lines)
		controls.showComparisons.state = true
		controls.showComparisons.changeFunc(true)
		assert.is_true(controls.comparison:IsShown())
		assert.is_true(popup.height > compactHeight)
		assert.is_true(hasLifeChange("+30"))
		assert.is_true(hasLifeChange("+80"))
		controls.multiplier:SetVal(1)
		assert.is_true(hasLifeChange("+60"))
		assert.is_true(hasLifeChange("+110"))
		controls.negative1:Click()
		assert.is_true(hasLifeChange("-260"))
		assert.is_true(hasLifeChange("-210"))
		local headers = {}
		for _, line in ipairs(controls.comparison.tooltip.lines) do
			if line.text and line.text:find("Equipping this item in Ring", 1, true) then table.insert(headers, StripEscapes(line.text)) end
		end
		assert.are.equals(2, #headers)
		assert.is_truthy(table.concat(headers):find("Ring 1", 1, true))
		assert.is_truthy(table.concat(headers):find("Ring 2", 1, true))
		controls.positive1:Click()
		assert.is_true(hasLifeChange("+110"))
		local normal = new("Tooltip"):Tooltip()
		normal.maxWidth = 330
		itemsTab:AddItemStatDifferences(normal, mist.ReflectItem(source, 1.6, {}), source.base)
		assert.are.equals(#normal.lines, #controls.comparison.tooltip.lines)
		for i, line in ipairs(normal.lines) do
			assert.are.equals(line.text, controls.comparison.tooltip.lines[i].text)
		end
		controls.showComparisons.state = false
		controls.showComparisons.changeFunc(false)
		assert.is_false(controls.comparison:IsShown())
		assert.are.equals(0, #controls.comparison.tooltip.lines)
		assert.are.equals(compactHeight, popup.height)
		controls.close.onClick()
		assert.are.equals(source, itemsTab.displayItem)
		assert.are.equals(original, source:BuildRaw())
		assert.are.equals(ring1, itemsTab.slots["Ring 1"].selItemId)
		assert.are.equals(ring2, itemsTab.slots["Ring 2"].selItemId)
		assert.are.equals(originalLife, build.calcsTab.mainOutput.Life)
		mist.OpenPopup(itemsTab)
		controls = main.popups[1].controls
		assert.is_false(controls.showComparisons.state)
		controls.close.onClick()
	end)

	it("compares unequipped amulets and reports unchanged build stats", function()
		newBuild()
		local itemsTab = build.itemsTab
		local source = item("{unscalable}+50 to maximum Life", "Onyx Amulet")
		itemsTab:SetDisplayItem(source)
		mist.OpenPopup(itemsTab)
		local controls = main.popups[1].controls
		controls.showComparisons.state = true
		controls.showComparisons.changeFunc(true)
		assert.are.equals(nil, controls.compareSlot)
		local found = false
		for _, line in ipairs(controls.comparison.tooltip.lines) do
			if line.text and StripEscapes(line.text):find("+50 Total Life", 1, true) then found = true end
		end
		assert.is_true(found)
		controls.close.onClick()
		itemsTab:AddDisplayItem()
		runCallback("OnFrame")
		itemsTab:SetDisplayItem(source)
		mist.OpenPopup(itemsTab)
		controls = main.popups[1].controls
		controls.showComparisons.state = true
		controls.showComparisons.changeFunc(true)
		assert.are.equals("^7No changes to displayed build stats.", controls.comparison.tooltip.lines[1].text)
		controls.multiplier:SetVal(1)
		assert.are.equals("^7No changes to displayed build stats.", controls.comparison.tooltip.lines[1].text)
		controls.close.onClick()
	end)

	for _, saved in ipairs({ false, true }) do
		it("saves a reflected copy while preserving the " .. (saved and "equipped" or "unsaved") .. " original", function()
			newBuild()
			local itemsTab = build.itemsTab
			local original = item("+50 to maximum Life")
			itemsTab:SetDisplayItem(original)
			if saved then
				itemsTab:AddDisplayItem()
				runCallback("OnFrame")
				itemsTab:SetDisplayItem(original)
			end
			local originalRaw = original:BuildRaw()
			local originalId = original.id
			local equippedId = itemsTab.slots["Ring 1"].selItemId
			local itemCount = #itemsTab.itemOrderList
			mist.OpenPopup(itemsTab)
			local controls = main.popups[1].controls
			assert.is_true(controls.createCopy.state)
			controls.multiplier:SetVal(1)
			controls.negative1:Click()
			controls.save.onClick()
			assert.are.equals(itemCount + 1, #itemsTab.itemOrderList)
			local copy = itemsTab.items[itemsTab.itemOrderList[#itemsTab.itemOrderList]]
			assert.is_true(copy ~= original)
			assert.is_true(copy.id ~= originalId)
			assert.is_true(copy.mirrored)
			assert.are.equals("Reflected " .. original.title, copy.title)
			assert.are.equals("Reflected " .. original.name, copy.name)
			assert.are.equals(copy.name, new("Item"):Item(copy:BuildRaw()).name)
			assert.are.equals(1.6, copy.reflectionMultiplier)
			assert.are.equals("-80 to maximum Life", copy.explicitModLines[1].line)
			assert.are.equals(original, itemsTab.displayItem)
			assert.are.equals(originalRaw, original:BuildRaw())
			assert.are.equals(originalId, original.id)
			assert.are.equals(equippedId, itemsTab.slots["Ring 1"].selItemId)
			assert.are.equals(0, itemsTab.slots["Ring 2"].selItemId)
			if saved then assert.are.equals(original, itemsTab.items[originalId]) end
			-- Cancelling a subsequent copy must not add another item.
			mist.OpenPopup(itemsTab)
			controls = main.popups[1].controls
			controls.createCopy.state = true
			controls.close.onClick()
			assert.are.equals(itemCount + 1, #itemsTab.itemOrderList)
		end)
	end

	it("updates shared magnitude and individual signs in the popup", function()
		newBuild()
		local originalDefault = main.defaultItemAffixQuality
		main.defaultItemAffixQuality = 0.5
		build.itemsTab:SetDisplayItem(item("+50 to maximum Life\n+30% to Fire Resistance"))
		local original = build.itemsTab.displayItem:BuildRaw()
		mist.OpenPopup(build.itemsTab)
		local popup = main.popups[1]
		local controls = popup.controls
		assert.are.equals(0.5, controls.multiplier.val)
		assert.are.equals("^71.45x", controls.multiplierValue.label)
		assert.is_true(controls.positive1.locked)
		assert.is_false(controls.negative1.locked)
		controls.negative1:Click()
		assert.is_false(controls.positive1.locked)
		assert.is_true(controls.negative1.locked)
		assert.are.equals("^xF05050- Negative", controls.negative1.label)
		assert.is_true(controls.positive2.locked)
		controls.multiplier:SetVal(0)
		assert.are.equals("^71.30x", controls.multiplierValue.label)
		assert.is_truthy(controls.mod1.label:find("-65 to maximum Life", 1, true))
		assert.is_truthy(controls.mod2.label:find("+39% to Fire Resistance", 1, true))
		controls.multiplier:SetVal(0.51)
		assert.are.equals("^71.45x", controls.multiplierValue.label)
		assert.are.equals(0.5, controls.multiplier.val)
		controls.positive1:Click()
		assert.is_true(controls.positive1.locked)
		assert.is_false(controls.negative1.locked)
		assert.are.equals(colorCodes.POSITIVE .. "+ Positive", controls.positive1.label)
		assert.is_truthy(controls.mod1.label:find("+72 to maximum Life", 1, true))
		controls.negative1:Click()
		controls.legacy.state = true
		controls.legacy.changeFunc(true)
		assert.are.equals("^71.800x", controls.multiplierValue.label)
		assert.is_truthy(controls.mod1.label:find("-90 to maximum Life", 1, true))
		controls.multiplier:SetVal(1 / 24 + 0.001)
		assert.are.equals("^71.525x", controls.multiplierValue.label)
		assert.are.equals(1 / 24, controls.multiplier.val)
		controls.legacy.state = false
		controls.legacy.changeFunc(false)
		assert.are.equals("^71.45x", controls.multiplierValue.label)
		controls.close.onClick()
		assert.are.equals(original, build.itemsTab.displayItem:BuildRaw())
		main.defaultItemAffixQuality = 0.63
		mist.OpenPopup(build.itemsTab)
		controls = main.popups[1].controls
		assert.are.equals("^71.49x", controls.multiplierValue.label)
		controls.negative2:Click()
		controls.createCopy.state = false
		controls.save.onClick()
		assert.is_true(build.itemsTab.displayItem.mirrored)
		assert.are.equals("Mist Test", build.itemsTab.displayItem.title)
		assert.are.equals("+74 to maximum Life", build.itemsTab.displayItem.explicitModLines[1].line)
		assert.are.equals("-44% to Fire Resistance", build.itemsTab.displayItem.explicitModLines[2].line)
		main.defaultItemAffixQuality = originalDefault
	end)
end)
