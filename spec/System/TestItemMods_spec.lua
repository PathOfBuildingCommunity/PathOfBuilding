describe("TetsItemMods", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in setup()
	end)

	local function createBaseChangeRing()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Coral Ring
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 1
			+(20-30) to maximum Life
		]])
	end

	it("removes structured affixes that cannot spawn on a changed base", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Boots
			Sorcerer Boots
			Crafted: true
			Prefix: {range:0.25}LocalIncreasedEnergyShield6
			Prefix: {range:0.75}IncreasedLife6
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Quality: 20
			Sockets: B-B-B-B
			LevelReq: 67
			Implicits: 0
			+33 to maximum Energy Shield
			+72 to maximum Life
		]])
		local source = build.itemsTab.displayItem
		local targetBase = { name = "Iron Greaves", base = build.data.itemBases["Iron Greaves"] }
		local candidate, removedAffixes = build.itemsTab:CreateBaseChangeCandidate(source, targetBase)

		assert.is_not_nil(candidate)
		assert.are.equals("Iron Greaves", candidate.baseName)
		assert.are.equals(1, #removedAffixes)
		assert.is_truthy(removedAffixes[1].label:find("maximum Energy Shield", 1, true))
		assert.are.equals("None", candidate.prefixes[1].modId)
		assert.are.equals("IncreasedLife6", candidate.prefixes[2].modId)
		assert.are.equals(0.75, candidate.prefixes[2].range)
		assert.is_nil(candidate.armourData.EnergyShieldBasePercentile)
		assert.are.equals(0, candidate.armourData.EnergyShield)
		assert.is_true(candidate.armourData.Armour > 0)
	end)

	it("refreshes compatibility and applies an unsaved item when changing armour subtype", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			New Item
			Conquest Lamellar
			Crafted: true
			Prefix: {range:0.5}LocalBaseArmourAndEvasionRating5
			Prefix: {range:1}LocalIncreasedArmourAndEvasion4
			Prefix: {range:1}LocalBaseArmourAndLife2
			Suffix: {range:0.5}Dexterity5
			Suffix: {range:0.5}Strength5
			Suffix: {range:0.5}ChanceToSuppressSpellsHigh3
			Quality: 20
			Sockets: G=G=G=G=G=G
			LevelReq: 84
			Implicits: 0
			+116 to Armour
			+116 to Evasion Rating
			67% increased Armour and Evasion
			+48 to Armour
			+28 to maximum Life
			+30 to Dexterity
			+30 to Strength
			+15% chance to Suppress Spell Damage
		]])
		local source = build.itemsTab.displayItem
		build.itemsTab:ChangeDisplayItemBase()
		local popup = main.popups[1]
		local controls = popup.controls
		local initialPopupY = popup:GetProperty("y")
		local initialPopupHeight = popup:GetProperty("height")
		local energyShieldTypeIndex
		for index, typeName in ipairs(controls.type.list) do
			if typeName == "Body Armour: Energy Shield" then
				energyShieldTypeIndex = index
				break
			end
		end

		assert.is_not_nil(energyShieldTypeIndex)
		local typeCount = #controls.type.list
		local selectedType = controls.type.selValue
		controls.search:SetText("Regalia", true)
		assert.are.equals(typeCount, #controls.type.list)
		assert.are.equals(selectedType, controls.type.selValue)
		assert.are.equals(0, #controls.base.list)
		assert.are.equals("^x7F7F7F<No Matches>", controls.base.defaultText)
		assert.is_truthy(controls.status:GetProperty("label"):find("Select a base", 1, true))
		assert.is_false(controls.otherStatus:IsShown())
		assert.is_falsy(controls.save:IsEnabled())
		controls.type:SelectIndex(energyShieldTypeIndex)
		assert.is_true(#controls.base.list > 1)
		for _, baseEntry in ipairs(controls.base.list) do
			assert.is_truthy(baseEntry.name:find("Regalia", 1, true))
		end
		controls.search:SetText("", true)
		assert.are.equals("Body Armour: Energy Shield", controls.type.selValue)
		assert.are.equals("Twilight Regalia", controls.base.selValue.name)
		assert.is_false(controls.implicitStatus:IsShown())
		assert.is_truthy(controls.status:GetProperty("label"):find("Explicits:", 1, true))
		assert.is_truthy(controls.status:GetProperty("label"):find("6 incompatible modifiers will be removed", 1, true))
		assert.is_truthy(controls.removedAffix1:GetProperty("label"):find("(Prefix)", 1, true))
		assert.is_truthy(controls.removedAffix6:GetProperty("label"):find("(Suffix)", 1, true))
		assert.is_truthy(controls.otherStatus:GetProperty("label"):find("Other:", 1, true))
		local baseX = controls.base:GetPos()
		local explicitStatusX = controls.status:GetPos()
		local otherStatusX = controls.otherStatus:GetPos()
		local removedAffixX = controls.removedAffix1:GetPos()
		assert.are.equals(baseX, explicitStatusX)
		assert.are.equals(baseX, otherStatusX)
		assert.are.equals(baseX + 15, removedAffixX)
		assert.are.equals(initialPopupY, popup:GetProperty("y"))
		assert.is_true(popup:GetProperty("height") > initialPopupHeight)

		local originalWrapString = main.WrapString
		finally(function()
			main.WrapString = originalWrapString
		end)
		local wrapCalls = 0
		main.WrapString = function(self, text, height, width)
			wrapCalls = wrapCalls + 1
			local splitIndex = text:find(" ", math.floor(#text / 2))
			return splitIndex and { text:sub(1, splitIndex - 1), text:sub(splitIndex + 1) } or { text }
		end
		controls.base:SelectIndex(controls.base.selIndex)
		local preparedWrapCalls = wrapCalls
		popup:Draw({ x = 0, y = 0, width = 1920, height = 1080 })
		popup:Draw({ x = 0, y = 0, width = 1920, height = 1080 })
		assert.are.equals(preparedWrapCalls, wrapCalls)
		local wrappedLabel = controls.removedAffix1:GetProperty("label")
		local firstAffixY = controls.removedAffix1:GetProperty("y")
		local secondAffixY = controls.removedAffix2:GetProperty("y")
		local expandedPopupHeight = popup:GetProperty("height")
		main.WrapString = originalWrapString

		assert.is_truthy(wrappedLabel:find("\n", 1, true))
		assert.is_true(secondAffixY > firstAffixY + 20)
		assert.is_true(expandedPopupHeight > 310)
		assert.are.equals(initialPopupY, popup:GetProperty("y"))
		assert.is_true(controls.save:IsEnabled())
		controls.save.onClick()

		assert.are.equals("Twilight Regalia", build.itemsTab.displayItem.baseName)
		assert.are.equals("Energy Shield", build.itemsTab.displayItem.base.subType)
		for index = 1, 3 do
			assert.are.equals("None", build.itemsTab.displayItem.prefixes[index].modId)
			assert.are.equals("None", build.itemsTab.displayItem.suffixes[index].modId)
		end
		assert.are.equals("Conquest Lamellar", source.baseName)
	end)

	it("shows type, base, and implicit columns with shared base scrolling", function()
		createBaseChangeRing()
		build.itemsTab:ChangeDisplayItemBase()
		local popup = main.popups[1]
		local controls = popup.controls

		assert.are.equals("Type", controls.type.colList[1].label)
		assert.are.equals("Base", controls.base.colList[1].label)
		assert.are.equals("Implicit", controls.base.colList[2].label)

		local implicitBaseIndex
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.base.implicit then
				implicitBaseIndex = index
				break
			end
		end
		assert.is_not_nil(implicitBaseIndex)
		local baseEntry = controls.base.list[implicitBaseIndex]
		assert.are.equals(baseEntry.name, controls.base:GetRowValue(1, implicitBaseIndex, baseEntry))
		assert.are.equals(baseEntry.base.implicit:gsub("\n", " / "), controls.base:GetRowValue(2, implicitBaseIndex, baseEntry))

		controls.search:SetText("Ruby Ring", true)
		assert.are.equals(1, #controls.base.list)
		assert.are.equals("Ruby Ring", controls.base.selValue.name)
		controls.search:SetText("Fire Resistance", true)
		assert.is_true(#controls.base.list > 0)
		for _, filteredBase in ipairs(controls.base.list) do
			assert.is_truthy((filteredBase.base.implicit or ""):find("Fire Resistance", 1, true))
		end
		controls.search:SetText("", true)

		popup:SelectControl(controls.base)
		local originalIsKeyDown = IsKeyDown
		finally(function()
			_G.IsKeyDown = originalIsKeyDown
		end)
		_G.IsKeyDown = function(key)
			return key == "CTRL"
		end
		popup:ProcessInput({ { type = "KeyDown", key = "f" } }, { x = 0, y = 0, width = 1920, height = 1080 })
		assert.are.equal(controls.search, popup.selControl)
		assert.is_true(controls.search.hasFocus)
		_G.IsKeyDown = originalIsKeyDown

		local selectedType = controls.type.selValue
		for _, filteredBase in ipairs(controls.base.list) do
			local belongsToSelectedType = false
			for _, typeBase in ipairs(build.data.itemBaseLists[selectedType]) do
				if filteredBase == typeBase then
					belongsToSelectedType = true
					break
				end
			end
			assert.is_true(belongsToSelectedType)
		end
		main:ClosePopup()
	end)

	it("keeps the damage search applied across consecutive shield type clicks", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Shield
			Titanium Spirit Shield
			Crafted: true
			Implicits: 0
		]])
		build.itemsTab:ChangeDisplayItemBase()
		local popup = main.popups[1]
		local controls = popup.controls
		local viewPort = { x = 0, y = 0, width = 1920, height = 1080 }
		local originalGetCursorPos = GetCursorPos
		finally(function()
			_G.GetCursorPos = originalGetCursorPos
			main:ClosePopup()
		end)
		assert.are.equals("Shield: Energy Shield", controls.type.selValue)
		controls.search:SetText("damage", true)
		for _, subType in ipairs({ "Evasion", "Evasion/Energy Shield", "Evasion" }) do
			local index = isValueInArray(controls.type.list, "Shield: " .. subType)
			assert.is_not_nil(index)
			local x, y = controls.type:GetPos()
			local rowRegion = controls.type:GetRowRegion()
			_G.GetCursorPos = function()
				return x + rowRegion.x + 10, y + rowRegion.y + (index - 0.5) * controls.type.rowHeight - controls.type.controls.scrollBarV.offset
			end
			popup:ProcessInput({ { type = "KeyDown", key = "LEFTBUTTON" }, { type = "KeyUp", key = "LEFTBUTTON" } }, viewPort)
			assert.are.equals("Shield: " .. subType, controls.type.selValue)
			assert.is_true(#controls.base.list > 0)
			for _, entry in ipairs(controls.base.list) do
				assert.are.equals(subType, entry.base.subType)
				assert.is_truthy(entry.base.implicit:lower():find("damage", 1, true))
			end
		end
		assert.are.equals(controls.type, popup.selControl)
	end)

	it("scrolls the hovered base once regardless of focus and keeps page keys on the focused list", function()
		createBaseChangeRing()
		build.itemsTab:ChangeDisplayItemBase()
		local popup = main.popups[1]
		local list = popup.controls.base
		local scrollBar = list.controls.scrollBarV
		local x, y = list:GetPos()
		local originalGetCursorPos = GetCursorPos
		finally(function()
			_G.GetCursorPos = originalGetCursorPos
			main:ClosePopup()
		end)
		_G.GetCursorPos = function() return x + 30, y + 40 end
		local viewPort = { x = 0, y = 0, width = 1920, height = 1080 }
		list:Draw(viewPort, true)
		for _, focus in ipairs({ "search", "base", "none" }) do
			popup:SelectControl(popup.controls[focus])
			for _, key in ipairs({ "WHEELDOWN", "WHEELUP" }) do
				scrollBar:SetOffset(80)
				popup:ProcessInput({ { type = "KeyUp", key = key } }, viewPort)
				assert.are.equals(key == "WHEELDOWN" and 120 or 40, scrollBar.offset, focus)
			end
		end
		popup:SelectControl(list)
		_G.GetCursorPos = function() return 0, 0 end
		popup:ProcessInput({ { type = "KeyUp", key = "PAGEDOWN" } }, viewPort)
		assert.are.equals(80, scrollBar.offset)
	end)

	it("replaces native implicits while preserving custom modifier text", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Coral Ring
			Unique ID: imported-item-id
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Item Level: 84
			Implicits: 2
			+(20-30) to maximum Life
			{custom}+1 to Maximum Power Charges
			{custom}+10 to Intelligence
		]])
		local source = build.itemsTab.displayItem
		source.id = 42
		local targetBase = { name = "Ruby Ring", base = build.data.itemBases["Ruby Ring"] }
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		assert.is_false(controls.implicitStatus:IsShown())
		main:ClosePopup()
		local candidate, removedAffixes, removedInfluences, removedOtherMods = build.itemsTab:CreateBaseChangeCandidate(source, targetBase)

		assert.is_not_nil(candidate)
		assert.are.equals("Ruby Ring", candidate.baseName)
		assert.are.equals(42, candidate.id)
		assert.are.equals(0, #removedAffixes)
		assert.are.equals(0, #removedInfluences)
		assert.are.equals(0, #removedOtherMods)
		assert.is_nil(candidate.uniqueID)
		assert.are.equals("+(20-30)% to Fire Resistance", candidate.implicitModLines[1].line)
		assert.are.equals(2, #candidate.implicitModLines)
		assert.are.equals("+1 to Maximum Power Charges", candidate.implicitModLines[2].line)
		assert.is_true(candidate.implicitModLines[2].custom)
		assert.are.equals("+10 to Intelligence", candidate.explicitModLines[1].line)
		assert.is_true(candidate.explicitModLines[1].custom)
	end)

	it("replaces native base implicits only when retaining Eldritch implicits", function()
		local exarch = "{exarch}{range:0.25}Bone Offering has (6-7)% increased Effect"
		local eater = "{eater}Regenerate 0.2% of Life per second per Endurance Charge"
		local targetName = "Two-Toned Boots (Armour/Energy Shield)"
		local target = { name = targetName, base = build.data.itemBases[targetName] }
		for _, implicits in ipairs({ { }, { exarch }, { eater }, { exarch, eater } }) do
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest Boots\nSorcerer Boots\nCrafted: true\nSearing Exarch Item\nEater of Worlds Item\nImplicits: " .. #implicits .. "\n" .. table.concat(implicits, "\n"))
			local source = build.itemsTab.displayItem
			local sourceRaw = source:BuildRaw()
			local candidate = build.itemsTab:CreateBaseChangeCandidate(source, target)
			assert.is_not_nil(candidate)
			assert.are.equals(math.max(#implicits, 1), #candidate.implicitModLines)
			if #implicits == 0 then
				assert.are.equals(target.base.implicit, candidate.implicitModLines[1].line)
			else
				for index, implicit in ipairs(source.implicitModLines) do
					local retained = candidate.implicitModLines[index]
					assert.are.equals(implicit.line, retained.line)
					assert.are.equals(implicit.range, retained.range)
					assert.are.equals(implicit.exarch, retained.exarch)
					assert.are.equals(implicit.eater, retained.eater)
				end
				local reloaded = new("Item"):Item(candidate:BuildRaw())
				local roundTrip = build.itemsTab:CreateBaseChangeCandidate(reloaded, { name = source.baseName, base = source.base })
				assert.is_not_nil(roundTrip)
				assert.are.equals(#implicits, #roundTrip.implicitModLines)
				-- A previously crafted item may still contain the old additive combination.
				table.insert(reloaded.implicitModLines, 1, { line = target.base.implicit })
				reloaded:BuildAndParseRaw()
				local corrected = build.itemsTab:CreateBaseChangeCandidate(reloaded, target)
				assert.is_not_nil(corrected)
				assert.are.equals(#implicits, #corrected.implicitModLines)
				assert.are.equals(candidate:BuildRaw(), corrected:BuildRaw())
			end
			assert.are.equals(sourceRaw, source:BuildRaw())
		end
	end)

	it("shows the implicit replacement notice only for a selected base with native implicits", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Boots
			Sorcerer Boots
			Crafted: true
			Searing Exarch Item
			Eater of Worlds Item
			Implicits: 2
			{exarch}Bone Offering has (6-7)% increased Effect
			{eater}Regenerate 0.2% of Life per second per Endurance Charge
		]])
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		finally(function() main:ClosePopup() end)
		assert.is_false(controls.implicitStatus:IsShown())
		controls.type:SelectIndex(isValueInArray(controls.type.list, "Boots: Armour/Energy Shield"))
		for _, name in ipairs({ "Two-Toned Boots (Armour/Energy Shield)", "Soldier Boots", "Two-Toned Boots (Armour/Energy Shield)" }) do
			for index, entry in ipairs(controls.base.list) do
				if entry.name == name then
					controls.base:SelectIndex(index)
					break
				end
			end
			assert.are.equals(name, controls.base.selValue.name)
			assert.are.equals(name ~= "Soldier Boots", controls.implicitStatus:IsShown())
		end
		controls.search:SetText("no matching boots", true)
		assert.is_false(controls.implicitStatus:IsShown())
		controls.search:SetText("Two-Toned", true)
		controls.save.onClick()
		assert.are.equals(2, #build.itemsTab.displayItem.implicitModLines)
		build.itemsTab:ChangeDisplayItemBase()
		assert.is_false(main.popups[1].controls.implicitStatus:IsShown())
	end)

	it("removes every structured affix affected by special base rules", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Coral Ring
			Crafted: true
			Prefix: {range:0.5}IncreasedLife6
			Prefix: None
			Prefix: None
			Suffix: {range:0.5}FireResist6
			Suffix: None
			Suffix: None
			Implicits: 1
			+(20-30) to maximum Life
			+92 to maximum Life
			+39% to Fire Resistance
		]])
		local ratchetingBase = { name = "Ratcheting Ring", base = build.data.itemBases["Ratcheting Ring"] }
		local candidate, removedAffixes, _, removedOtherMods = build.itemsTab:CreateBaseChangeCandidate(build.itemsTab.displayItem, ratchetingBase)

		assert.is_true(removedAffixes.resetPrefixes)
		assert.is_true(removedAffixes.resetSuffixes)
		assert.are.equals(2, #removedAffixes)
		assert.are.equals(0, #removedOtherMods)
		assert.is_truthy(removedAffixes[1].label:find("(Prefix)", 1, true))
		assert.is_truthy(removedAffixes[2].label:find("(Suffix)", 1, true))
		assert.are.equals(0, #candidate.explicitModLines)
		assert.are.equals(0, #candidate.prefixes)
		assert.are.equals(6, #candidate.suffixes)
		build.itemsTab:SetDisplayItem(candidate)
		assert.is_true(build.itemsTab.controls.displayItemChangeBase:IsShown())

		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Ratcheting Ring
			Crafted: true
			Suffix: {range:0.5}Strength5
			Suffix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 3
			-3 Prefix Modifiers allowed
			+3 Suffix Modifiers allowed
			Implicit Modifiers Cannot Be Changed
			+30 to Strength
		]])
		local coralBase = { name = "Coral Ring", base = build.data.itemBases["Coral Ring"] }
		candidate, removedAffixes = build.itemsTab:CreateBaseChangeCandidate(build.itemsTab.displayItem, coralBase)

		assert.is_true(removedAffixes.resetPrefixes)
		assert.is_true(removedAffixes.resetSuffixes)
		assert.are.equals(1, #removedAffixes)
		assert.are.equals(0, #candidate.explicitModLines)
	end)

	it("shows special base slot resets as two status lines", function()
		createBaseChangeRing()
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.name == "Ratcheting Ring" then
				controls.base:SelectIndex(index)
				break
			end
		end

		local status = controls.status:GetProperty("label")
		assert.is_truthy(status:find("The new base changes prefix and suffix rules. All modifiers will be reset.\nThere are no modifiers in the affected slots.", 1, true))
		main:ClosePopup()
	end)

	it("resets carried influences when either base grants influence", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Amulet
			Astrolabe Amulet
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 2
			Implicit Modifiers Cannot Be Changed
			Has Elder, Shaper and all Conqueror Influences
		]])
		local amberBase = { name = "Amber Amulet", base = build.data.itemBases["Amber Amulet"] }
		local candidate, _, removedInfluences = build.itemsTab:CreateBaseChangeCandidate(build.itemsTab.displayItem, amberBase)

		assert.is_true(removedInfluences.reset)
		assert.are.equals(6, #removedInfluences)
		for _, influence in ipairs(itemLib.influenceInfo.default) do
			assert.is_falsy(candidate[influence.key])
		end

		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Amulet
			Amber Amulet
			Searing Exarch Item
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 1
			+(20-30) to Strength
		]])
		local astrolabeBase = { name = "Astrolabe Amulet", base = build.data.itemBases["Astrolabe Amulet"] }
		candidate, _, removedInfluences = build.itemsTab:CreateBaseChangeCandidate(build.itemsTab.displayItem, astrolabeBase)

		assert.is_true(removedInfluences.reset)
		assert.are.equals(1, #removedInfluences)
		assert.are.equals("Searing Exarch", removedInfluences[1])
		assert.is_falsy(candidate.cleansing)
		for _, influence in ipairs(itemLib.influenceInfo.default) do
			assert.is_true(candidate[influence.key])
		end

		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Amulet
			Amber Amulet
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 1
			+(20-30) to Strength
		]])
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.name == "Astrolabe Amulet" then
				controls.base:SelectIndex(index)
				break
			end
		end
		assert.is_false(controls.otherStatus:IsShown())
		assert.is_false(controls.otherStatus2:IsShown())
		assert.is_false(controls.otherStatus3:IsShown())
		main:ClosePopup()
	end)

	it("reports and removes unclassified explicit modifier text", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Coral Ring
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 1
			+(20-30) to maximum Life
			10% increased Damage
			{custom}+10 to Intelligence
		]])
		local rubyBase = { name = "Ruby Ring", base = build.data.itemBases["Ruby Ring"] }
		local candidate, removedAffixes, _, removedOtherMods = build.itemsTab:CreateBaseChangeCandidate(build.itemsTab.displayItem, rubyBase)

		assert.are.equals(0, #removedAffixes)
		assert.are.same({ "10% increased Damage" }, removedOtherMods)
		assert.are.equals(1, #candidate.explicitModLines)

		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.name == "Ruby Ring" then
				controls.base:SelectIndex(index)
				break
			end
		end
		local otherStatus = controls.otherStatus:GetProperty("label")
		local additionalOtherStatus = controls.otherStatus2:GetProperty("label")
		assert.is_truthy(otherStatus:find("1 unclassified explicit modifier will be removed:\n", 1, true))
		assert.is_truthy(otherStatus:find("10% increased Damage", 1, true))
		assert.is_truthy(additionalOtherStatus:find("Modifiers added via 'Add Modifier' persist, but are not checked", 1, true))
		local _, otherStatusY = controls.otherStatus:GetPos()
		local _, additionalOtherStatusY = controls.otherStatus2:GetPos()
		assert.are.equals(otherStatusY + 2 * 20 + 7, additionalOtherStatusY)
		main:ClosePopup()
	end)

	it("hides base changing for unsupported, unique, hidden, and over-capacity items", function()
		for _, baseName in ipairs({ "Small Life Flask", "Cobalt Jewel", "Prismatic Tincture", "Battering Uulgraft", "Cured Quiver" }) do
			build.itemsTab:CreateDisplayItemFromRaw("Rarity: Rare\nTest Item\n" .. baseName .. "\nCrafted: true\nImplicits: 0")
			assert.is_false(build.itemsTab.controls.displayItemChangeBase:IsShown(), baseName)
		end

		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Unique
			Test Ring
			Coral Ring
			Crafted: true
			Implicits: 1
			+(20-30) to maximum Life
		]])
		assert.is_false(build.itemsTab.controls.displayItemChangeBase:IsShown())

		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Coral Ring
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Implicits: 1
			+(20-30) to maximum Life
			{custom}+1 Prefix Modifier allowed
		]])
		assert.is_false(build.itemsTab.controls.displayItemChangeBase:IsShown())
	end)

	it("rebuilds base-granted sockets when changing ring bases", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Rare
			Test Ring
			Unset Ring
			Crafted: true
			Prefix: None
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Suffix: None
			Sockets: B
			Implicits: 1
			Has 1 Socket
		]])
		local coralBase = { name = "Coral Ring", base = build.data.itemBases["Coral Ring"] }
		local unsetBase = { name = "Unset Ring", base = build.data.itemBases["Unset Ring"] }
		local coralRing = build.itemsTab:CreateBaseChangeCandidate(build.itemsTab.displayItem, coralBase)
		local unsetRing = build.itemsTab:CreateBaseChangeCandidate(coralRing, unsetBase)

		assert.are.equals(0, #coralRing.sockets)
		assert.are.equals(1, #unsetRing.sockets)
	end)

	it("does not mutate the display item while the change-base popup is open", function()
		createBaseChangeRing()
		local source = build.itemsTab.displayItem
		local sourceRaw = source:BuildRaw()

		assert.is_true(build.itemsTab.controls.displayItemChangeBase:IsShown())
		assert.are.equal(build.itemsTab.controls.displayItemAddCustom, build.itemsTab.controls.displayItemChangeBase.anchor.other)
		assert.are.equals("TOPRIGHT", build.itemsTab.controls.displayItemChangeBase.anchor.otherPoint)
		build.itemsTab:ChangeDisplayItemBase()
		assert.is_not_nil(main.popups[1])
		main.popups[1].controls.cancel.onClick()

		assert.are.equal(source, build.itemsTab.displayItem)
		assert.are.equals(sourceRaw, build.itemsTab.displayItem:BuildRaw())
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		controls.search:SetText("Ruby Ring", true)
		source.itemLevel = 99
		controls.save.onClick()
		assert.are.equal(source, build.itemsTab.displayItem)
		assert.is_falsy(controls.save:IsEnabled())
		assert.is_truthy(controls.status:GetProperty("label"):find("item changed", 1, true))
		main:ClosePopup()
	end)

	it("builds each hovered base preview only once", function()
		createBaseChangeRing()
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		local rubyRingIndex
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.name == "Ruby Ring" then
				rubyRingIndex = index
				break
			end
		end
		assert.is_not_nil(rubyRingIndex)

		local originalCreateCandidate = build.itemsTab.CreateBaseChangeCandidate
		local candidateBuildCount = 0
		finally(function()
			build.itemsTab.CreateBaseChangeCandidate = originalCreateCandidate
		end)
		build.itemsTab.CreateBaseChangeCandidate = function(self, ...)
			candidateBuildCount = candidateBuildCount + 1
			return originalCreateCandidate(self, ...)
		end
		local tooltip = new("Tooltip"):Tooltip()
		local rubyRing = controls.base.list[rubyRingIndex]
		controls.base:AddValueTooltip(tooltip, rubyRingIndex, rubyRing)
		controls.base:AddValueTooltip(tooltip, rubyRingIndex, rubyRing)

		assert.are.equals(1, candidateBuildCount)
		main:ClosePopup()
	end)

	it("keeps base changes isolated until save and preserves identity through undo and reload", function()
		createBaseChangeRing()
		local storedItem = build.itemsTab.displayItem
		build.itemsTab:AddDisplayItem()
		local itemId = storedItem.id
		local source = new("Item"):Item(storedItem:BuildRaw())
		source.id = itemId
		build.itemsTab:SetDisplayItem(source)
		local sourceRaw = source:BuildRaw()
		build.itemsTab:ChangeDisplayItemBase()
		local controls = main.popups[1].controls
		local rubyRingIndex
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.name == "Ruby Ring" then
				rubyRingIndex = index
				break
			end
		end

		assert.is_not_nil(rubyRingIndex)
		controls.base:SelectIndex(rubyRingIndex)
		assert.is_true(controls.save:IsEnabled())
		controls.save.onClick()

		assert.are.equals("Coral Ring", build.itemsTab.items[itemId].baseName)
		assert.are.equals("Ruby Ring", build.itemsTab.displayItem.baseName)
		assert.is_true(build.itemsTab.controls.displayItemChangeBase:IsShown())
		assert.are.equals("Coral Ring", source.baseName)
		assert.are.equals(sourceRaw, source:BuildRaw())

		build.itemsTab:ChangeDisplayItemBase()
		controls = main.popups[1].controls
		for index, baseEntry in ipairs(controls.base.list) do
			if baseEntry.name == "Sapphire Ring" then
				controls.base:SelectIndex(index)
				break
			end
		end
		controls.save.onClick()
		assert.are.equals("Sapphire Ring", build.itemsTab.displayItem.baseName)
		assert.is_true(build.itemsTab.controls.displayItemChangeBase:IsShown())
		build.itemsTab:AddDisplayItem()
		assert.are.equals("Sapphire Ring", build.itemsTab.items[itemId].baseName)
		assert.are.equals(itemId, build.itemsTab.slots["Ring 1"].selItemId)
		build.itemsTab:Undo()
		assert.are.equals("Coral Ring", build.itemsTab.items[itemId].baseName)
		build.itemsTab:Redo()
		assert.are.equals("Sapphire Ring", build.itemsTab.items[itemId].baseName)
		loadBuildFromXML(build:SaveDB("code"))
		assert.are.equals("Sapphire Ring", build.itemsTab.items[itemId].baseName)
		assert.are.equals(itemId, build.itemsTab.slots["Ring 1"].selItemId)
	end)

	it("shows versioned reusable variant groups", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: Unique
			Grouped Test Item
			Plate Vest
			Version: Pre 3.28.0
			Version: Current
			Variant: Life
			Variant: Energy Shield
			Variant: Mana
			Variant: Armour
			Implicits: 0
			{version:1}{variant:1}{group:1,2}+10 to maximum Life
			{version:2}{variant:2}{group:1,2}+10 to maximum Energy Shield
			{variant:3}{group:1,2}+10 to maximum Mana
			{variant:4}{group:1,2}+10 to Armour
			]])

		local versionControl = build.itemsTab.controls.displayItemVersion
		local group1 = build.itemsTab.controls.displayItemVariant
		local group2 = build.itemsTab.controls.displayItemAltVariant
		assert.is_true(versionControl:IsShown())
		assert.are.equals(2, versionControl.selIndex)
		assert.are.equals("Energy Shield", group1.list[1].label)
		assert.are.equals("Mana", group2.list[1].label)

		group2:SetSel(2)
		group1:SetSel(2)
		assert.are.equals(3, build.itemsTab.displayItem.variantGroupSelections[1])
		versionControl:SetSel(1)
		assert.are.equals(3, build.itemsTab.displayItem.variantGroupSelections[1])
		assert.are.equals("Life", group1.list[1].label)
		assert.are.equals("Mana", group1.list[2].label)
		assert.are.equals("Life", group2.list[1].label)
		assert.are.equals("Armour", group2.list[2].label)
	end)

	it("Dialla's socket mods", function()
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nArc 20/0  1\nArc 20/0  1\n")
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Dialla's Malefaction
		Sage's Robe
		Energy Shield: 95
		EnergyShieldBasePercentile: 0
		Variant: Pre 3.19.0
		Variant: Current
		Selected Variant: 2
		Sage's Robe
		Quality: 20
		Sockets: R-G-B-B-B-B
		LevelReq: 37
		Implicits: 0
		Gems can be Socketed in this Item ignoring Socket Colour
		{variant:1}Gems Socketed in Red Sockets have +1 to Level
		{variant:2}Gems Socketed in Red Sockets have +2 to Level
		{variant:1}Gems Socketed in Green Sockets have +10% to Quality
		{variant:2}Gems Socketed in Green Sockets have +30% to Quality
		{variant:1}Gems Socketed in Blue Sockets gain 25% increased Experience
		{variant:2}Gems Socketed in Blue Sockets gain 100% increased Experience
		Has no Attribute Requirements]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(build.calcsTab.mainEnv.player.activeSkillList[1].activeEffect.level, 22)
		assert.are.equals(build.calcsTab.mainEnv.player.activeSkillList[2].activeEffect.quality, 30)
	end)

	it("Malachai's Artifice socket mods", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Malachai's Artifice
		Unset Ring
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Unset Ring
		Sockets: W
		LevelReq: 5
		Implicits: 1
		Has 1 Socket
		{tags:jewellery_resistance}{variant:1}-25% to all Elemental Resistances
		{tags:jewellery_resistance}{variant:2}-20% to all Elemental Resistances
		{tags:jewellery_resistance}{range:0.5}+(75-100)% to Fire Resistance when Socketed with a Red Gem
		{tags:jewellery_resistance}{range:0.5}+(75-100)% to Cold Resistance when Socketed with a Green Gem
		{tags:jewellery_resistance}{range:0.5}+(75-100)% to Lightning Resistance when Socketed with a Blue Gem
		All Sockets are White
		Socketed Gems have Elemental Equilibrium]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local lightningResBefore = build.calcsTab.mainOutput.LightningResist

		build.skillsTab:PasteSocketGroup("Slot: Ring 1\nWrath 20/0  1\n")
		runCallback("OnFrame")

		assert.are_not.equals(lightningResBefore, build.calcsTab.mainOutput.LightningResist)
	end)

	it("caps socketed gem multipliers in gem order", function()
		build.itemsTab:CreateDisplayItemFromRaw("Test Gloves\nIron Gauntlets\nSockets: R-R-R-R")
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Gloves\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nHeavy Strike 20/0  1\nArc 20/0  1\n")
		runCallback("OnFrame")

		local multipliers = build.calcsTab.mainEnv.itemModDB.multipliers
		assert.are.equals(4, multipliers.SocketedGemsInGloves)
		assert.are.equals(4, multipliers.SocketedRedGemsInGloves)
		assert.are.equals(0, multipliers.SocketedBlueGemsInGloves)
	end)

	it("Doomsower vaal pact and extra phys as fire", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Doomsower
		Lion Sword
		Variant: Pre 2.6.0
		Variant: Pre 3.0.0
		Variant: Pre 3.8.0
		Variant: Pre 3.11.0
		Variant: Current
		Selected Variant: 5
		Lion Sword
		Quality: 20
		Sockets: G-G-G-G-G-G
		LevelReq: 65
		Implicits: 3
		{variant:1}18% increased Global Accuracy Rating
		{variant:2,3,4}+470 to Accuracy Rating
		{variant:5}+50 to Strength and Dexterity
		Socketed Melee Gems have 15% increased Area of Effect
		{variant:1,2,3}Socketed Red Gems get 10% Physical Damage as Extra Fire Damage
		{variant:1,2,3,4}{range:0.5}(50-70)% increased Physical Damage
		{variant:5}{range:0.5}(30-50)% increased Physical Damage
		{variant:1,2}{range:0.5}Adds (50-75) to (85-110) Physical Damage
		{variant:3,4,5}{range:0.5}Adds (65-75) to (100-110) Physical Damage
		{range:0.5}(6-12)% increased Attack Speed
		{variant:5,4}Attack Skills gain 5% of Physical Damage as Extra Fire Damage per Socketed Red Gem
		{variant:5,4}You have Vaal Pact while all Socketed Gems are Red]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0  1\n")
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainEnv.keystonesAdded["Vaal Pact"])
		assert.is_true(build.calcsTab.mainEnv.player.mainSkill.skillModList:Sum("BASE", build.calcsTab.mainEnv.player.mainSkill.skillCfg, "PhysicalDamageGainAsFire") > 0)
	end)

	it("Varunastra works with nightblade", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Varunastra
		Vaal Blade
		League: Perandus
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Vaal Blade
		Quality: 20
		Sockets: G-G-G
		LevelReq: 64
		Implicits: 2
		{variant:1}18% increased Global Accuracy Rating
		{variant:2}+460 to Accuracy Rating
		{range:0.5}(40-60)% increased Physical Damage
		{range:0.5}Adds (30-45) to (80-100) Physical Damage
		{range:0.5}+(2-3) Mana gained for each Enemy hit by Attacks
		Counts as all One Handed Melee Weapon Types]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Smite 20/0  1\nNightblade 20/0  1\n")
		runCallback("OnFrame")
		local nonElusiveCritMult = build.calcsTab.mainOutput.CritMultiplier

		build.configTab.input["buffElusive"] = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(nonElusiveCritMult, build.calcsTab.mainOutput.CritMultiplier)
	end)

	it("Runegraft of the Agile affects average Elusive effect", function()
		build.skillsTab:PasteSocketGroup("Smite 20/0  1\n")
		build.configTab.input.customMods = "Gain Elusive on Critical Strike"
		build.configTab.input.buffElusive = true
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(50, build.calcsTab.mainOutput.ElusiveEffectMod)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(730 / 9, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds
		Elusive on you reduces in effect 50% slower
		Elusive is removed from you at 20% Effect]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(244 / 3, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.customMods = [[Gain Elusive on Critical Strike
		Elusive's Effect on you is increased instead for the first 2 seconds
		100% increased Elusive Effect
		Elusive is removed from you at 100% Effect]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.near(1630 / 9, build.calcsTab.mainOutput.ElusiveEffectMod, 10 ^ -9)

		build.configTab.input.overrideBuffElusive = 220
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(220, build.calcsTab.mainOutput.ElusiveEffectMod)
	end)

	it("Varunastra works with close combat support", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Varunastra
		Vaal Blade
		League: Perandus
		Variant: Pre 2.6.0
		Variant: Current
		Selected Variant: 2
		Vaal Blade
		Quality: 20
		Sockets: G-G-G
		LevelReq: 64
		Implicits: 2
		{variant:1}18% increased Global Accuracy Rating
		{variant:2}+460 to Accuracy Rating
		{range:0.5}(40-60)% increased Physical Damage
		{range:0.5}Adds (30-45) to (80-100) Physical Damage
		{range:0.5}+(2-3) Mana gained for each Enemy hit by Attacks
		Counts as all One Handed Melee Weapon Types]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		build.configTab.input["meleeDistance"] = 99
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.skillsTab:PasteSocketGroup("Cyclone 20/0  1\nClose Combat 20/0  1\n")
		runCallback("OnFrame")

		local farDPS = build.calcsTab.mainOutput.TotalDPS

		build.configTab.input["meleeDistance"] = 1
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(farDPS, build.calcsTab.mainOutput.TotalDPS)
	end)

	it("Kalandra's Touch mod copy", function()
		local initialInt = build.calcsTab.mainOutput.Int

		build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Ring
		Quality: 0
		LevelReq: 35
		Implicits: 0
		+30 to Intelligence]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local genericRingInt = build.calcsTab.mainOutput.Int

		build.itemsTab:CreateDisplayItemFromRaw([[Kalandra's Touch
		Ring
		League: Kalandra
		Implicits: 0
		Reflects your other Ring
		Mirrored]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(genericRingInt - initialInt, build.calcsTab.mainOutput.Int - genericRingInt)
	end)
	
	it("Kalandra's Touch influence copy", function()

		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nSmite 20/0  1\n")
		runCallback("OnFrame")

		local dmg = build.calcsTab.mainOutput.AverageDamage

		build.configTab.input.customMods = "\z
		Gain 5% of Elemental Damage as Extra Chaos Damage per Shaper Item Equipped\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(build.calcsTab.mainOutput.AverageDamage, dmg)

		build.itemsTab:CreateDisplayItemFromRaw([[New Item
		Cerulean Ring
		Shaper Item
		Crafted: true
		Prefix: None
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 0
		LevelReq: 80
		Implicits: 0]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.AverageDamage > dmg)

		local dmgOneRing = build.calcsTab.mainOutput.AverageDamage

		build.itemsTab:CreateDisplayItemFromRaw([[Kalandra's Touch
		Ring
		League: Kalandra
		Implicits: 0
		Reflects your other Ring
		Mirrored]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.is_true(build.calcsTab.mainOutput.AverageDamage > dmgOneRing)
	end)

	it("Both slots mod (evasion and es mastery)", function()

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		LevelReq: 33
		Implicits: 1
		+71 to Evasion Rating
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es changes after adding another ring with mod. Regardless of the evasion mod on the first ring being implicit.
	end)

	it("Both slots explicit mod with mixed mod rings (evasion and es mastery)", function()
	
		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		LevelReq: 33
		Implicits: 1
		+71 to Evasion Rating
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es does not change after adding another ring with mod due to the first ring having an implicit evasion mod.
	end)

	it("Both slots explicit mod (evasion and es mastery)", function()

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with just one ring.

		build.itemsTab:CreateDisplayItemFromRaw([[Chaos Resistance Ring
		Amethyst Ring
		Crafted: true
		Prefix: {range:0.5}IncreasedEvasionRating4
		Prefix: None
		Prefix: None
		Suffix: None
		Suffix: None
		Suffix: None
		LevelReq: 33
		Implicits: 1
		{tags:chaos,resistance}{range:0.5}+(17-23)% to Chaos Resistance
		+71 to Evasion Rating]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseEs, build.calcsTab.mainOutput.EnergyShield)
		-- Es changes after adding two rings with explicit mods.
	end)

	it("Both slots explicit mod no rings (evasion and es mastery)", function()
		build.itemsTab:CreateDisplayItemFromRaw([[Energy Shield Boots
		Sorcerer Boots
		Energy Shield: 114
		EnergyShieldBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}IncreasedLife6
		Prefix: {range:0.5}LocalIncreasedEnergyShieldPercent5
		Prefix: {range:0.5}MovementVelocity5
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: B-B-B-B
		LevelReq: 67
		Implicits: 0
		74% increased Energy Shield
		+65 to maximum Life
		30% increased Movement Speed]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		local baseEs = build.calcsTab.mainOutput.EnergyShield

		build.configTab.input.customMods = "\z
		20% increased Maximum Energy Shield if both Equipped Rings have an Explicit Evasion Modifier\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseEs, build.calcsTab.mainOutput.EnergyShield) -- No change in es with no rings.

	end)

	it("mod if no mod on x slot", function()
		local baseLife = build.calcsTab.mainOutput.Life

		build.configTab.input.customMods = "\z
		15% increased maximum Life if there are no Life Modifiers on Equipped Body Armour\n\z
		"
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are_not.equals(baseLife, build.calcsTab.mainOutput.Life)

		baseLife = build.calcsTab.mainOutput.Life

		build.itemsTab:CreateDisplayItemFromRaw([[Armour Chest
		Astral Plate
		Armour: 1696
		ArmourBasePercentile: 1
		Crafted: true
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRating5
		Prefix: {range:0.5}LocalIncreasedPhysicalDamageReductionRatingPercent5
		Prefix: {range:0.5}IncreasedLife9
		Suffix: None
		Suffix: None
		Suffix: None
		Quality: 20
		Sockets: R-R-R-R-R-R
		LevelReq: 62
		Implicits: 1
		{tags:elemental,resistance}{range:0.5}+(8-12)% to all Elemental Resistances
		+92 to Armour
		74% increased Armour
		+95 to maximum Life]])
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")

		assert.are_not.equals(baseLife, build.calcsTab.mainOutput.Life)
	end)

	it("globalLimit mods", function()
		build.configTab.input.customMods = [[
			-1000% to cold resistance
		]]
		build.configTab:BuildModList()
		build.itemsTab:CreateDisplayItemFromRaw([[Replica Nebulis
			Void Sceptre
			League: Heist
			Quality: 20
			Sockets: B-B-B
			LevelReq: 68
			Implicits: 1
			40% increased Elemental Damage
			{fractured}{range:1}(15-20)% increased Cast Speed
			{range:1}(15-20)% increased Cold Damage per 1% Missing Cold Resistance, up to a maximum of 300%
			{range:1}(15-20)% increased Fire Damage per 1% Missing Fire Resistance, up to a maximum of 300%]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Slot: Weapon 1\nFireball 20/0  1\n")
		runCallback("OnFrame")

		assert.are_not.equals(340, build.calcsTab.mainEnv.modDB:Sum("INC", "FireDamage"))
		assert.are_not.equals(340, build.calcsTab.mainEnv.modDB:Sum("INC", "ColdDamage"))

		newBuild()

		build.configTab.input.customMods = [[
			Gain 25% increased Armour per 5 Power for 8 seconds when you Warcry, up to a maximum of 100%
			Warcries have infinite Power
			warcries grant arcane surge to you and allies, with 10% increased effect per 5 power, up to 100%
		]]
		build.configTab:BuildModList()
		build.itemsTab:CreateDisplayItemFromRaw([[
			New Item
			Plate Vest
			Armour: 32
		]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")

		assert.are_not.equals(40, build.calcsTab.mainEnv.modDB:Sum("INC", { flags = ModFlag.Cast }, "Speed"))
		assert.are_not.equals(64, build.calcsTab.mainOutput.Armour)
		runCallback("OnFrame")
	end)
	
	it("Heralds apply exposure with Heraldry", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\nHerald of Thunder 20/0  1\n")
		runCallback("OnFrame")
		
		assert.are.equals(0.5, build.calcsTab.calcsOutput.LightningEffMult)
				
		build.configTab.input.customMods = [[
		Nearby Enemies have Cold Exposure while you are affected by Herald of Ice
		Nearby Enemies have Fire Exposure while you are affected by Herald of Ash
		Nearby Enemies have Lightning Exposure while you are affected by Herald of Thunder
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0.6, build.calcsTab.calcsOutput.LightningEffMult)
	end)
	
	it("Enemy self curse effect", function()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1\nConductivity 14/0  1\n")
		runCallback("OnFrame")
		
		assert.are.equals(0.8, build.calcsTab.calcsOutput.LightningEffMult)
				
		build.configTab.input.customMods = [[
		Nearby Enemies have 20% increased Effect of Curses on them
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(0.86, build.calcsTab.calcsOutput.LightningEffMult)
	end)
	
	it("Max charges with conditional mod", function() -- see #9442
		build.skillsTab:PasteSocketGroup("Grace 20/20  1\n")
		runCallback("OnFrame")
		
		local baseFrenzyChargesMax = build.calcsTab.calcsOutput.FrenzyChargesMax
		local baseEnduranceChargesMax = build.calcsTab.calcsOutput.EnduranceChargesMax
		
		build.configTab.input.customMods = [[
			+1 to Maximum Frenzy Charges while affected by Grace
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseFrenzyChargesMax + 1, build.calcsTab.calcsOutput.FrenzyChargesMax)
		assert.are.equals(baseEnduranceChargesMax, build.calcsTab.calcsOutput.EnduranceChargesMax)
		
		build.configTab.input.customMods = [[
			Your Maximum Endurance Charges is equal to your Maximum Frenzy Charges
			+1 to Maximum Frenzy Charges while affected by Grace
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(baseFrenzyChargesMax + 1, build.calcsTab.calcsOutput.FrenzyChargesMax)
		assert.are.equals(baseEnduranceChargesMax + 1, build.calcsTab.calcsOutput.EnduranceChargesMax)
	end)

	it("adds life recoup to energy shield recoup", function()
		build.configTab.input.customMods = [[
			20% of Damage taken Recouped as Life
			10% of Physical Damage taken Recouped as Life
			Damage taken Recouped as Life is also Recouped as Energy Shield
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(20, build.calcsTab.calcsOutput.LifeRecoup)
		assert.are.equals(20, build.calcsTab.calcsOutput.EnergyShieldRecoup)
		assert.are.equals(10, build.calcsTab.calcsOutput.PhysicalLifeRecoup)
		assert.are.equals(10, build.calcsTab.calcsOutput.PhysicalEnergyShieldRecoup)
	end)

	it("supports Baleful Dominion recoup modifiers", function()
		build.configTab.input.customMods = [[
			15% of Damage taken Recouped as Life
			10% of Physical Damage taken Recouped as Life
			Life Recoup also recovers Mana
			50% less recovery from Recoup
		]]
		build.configTab:BuildModList()
		runCallback("OnFrame")

		assert.are.equals(7.5, build.calcsTab.calcsOutput.LifeRecoup)
		assert.are.equals(7.5, build.calcsTab.calcsOutput.ManaRecoup)
		assert.are.equals(5, build.calcsTab.calcsOutput.PhysicalLifeRecoup)
		assert.are.equals(5, build.calcsTab.calcsOutput.PhysicalManaRecoup)
		local lifeRecoupBreakdown = build.calcsTab.calcsEnv.player.breakdown.LifeRecoup
		assert.are.equals("7.5% over 4 seconds", lifeRecoupBreakdown[#lifeRecoupBreakdown])
		local physicalLifeRecoupBreakdown = build.calcsTab.calcsEnv.player.breakdown.PhysicalLifeRecoup
		assert.are.equals("= 5.0% over 4 seconds", physicalLifeRecoupBreakdown[#physicalLifeRecoupBreakdown])
	end)

	it("crafts modifiers from supported bases on rare-like uniques", function()
		local item = new("Item"):Item([[
			Item Class: Helmets
			Rarity: Unique
			Subsume the Source
			Faithful Helmet
			--------
			Item Level: 86
			--------
			{ Prefix Modifier "Hale" }
			+23 to maximum Life
			{ Unique Modifier }
			120% increased Explicit Modifier magnitudes
			{ Suffix Modifier "of Adaption" }
			+7 to all Attributes
			{ Unique Modifier }
			Cannot have non-Abyssal sockets
		]])

		assert.are.equals(4, item.affixLimit)
		assert.are.equals(4, item.prefixes.limit)
		assert.are.equals(0, item.suffixes.limit)
		assert.are.equals("AbyssJewelAddedLife1", item.prefixes[1].modId)
		assert.are.equals("AbyssAllAttributesJewel1", item.prefixes[2].modId)
		build.itemsTab.displayItem = item
		build.itemsTab:UpdateAffixControls()
		local lifeModAvailable = false
		for _, entry in ipairs(build.itemsTab.controls.displayItemAffix2.list) do
			for _, modId in ipairs(type(entry) == "table" and entry.modList or { }) do
				lifeModAvailable = lifeModAvailable or modId == "AbyssJewelAddedLife1"
			end
		end
		assert.is_true(lifeModAvailable)

		item:Craft()
		local raw = item:BuildRaw()
		assert.is_truthy(raw:find("increased Explicit Modifier magnitudes", 1, true))
		assert.is_truthy(raw:find("Cannot have non-Abyssal sockets", 1, true))
	end)

	it("uses the item base for rare-like modifier eligibility by default", function()
		local item = new("Item"):Item([[
			Item Class: Bows
			Rarity: Unique
			The Crimson Storm
			Steelwood Bow
			--------
			Item Level: 85
			--------
			{ Suffix Modifier "of the Order" }
			+24(24-28)% to Physical Damage over Time Multiplier
		]])

		assert.are.equals(1, item.affixLimit)
		assert.are.equals(0, item.prefixes.limit)
		assert.are.equals(1, item.suffixes.limit)
		assert.are.equals("JunMasterVeiledPhysicalDamageOverTimeMultiplier", item.suffixes[1].modId)
	end)

	it("keeps modifier metadata on duplicate variant tooltip lines", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Duplicate Variant Test
			Plate Vest
			Variant: First
			Variant: Second
			Selected Variant: 1
			Has Alt Variant: true
			Selected Alt Variant: 1
			Allow Duplicate Variants: true
			Implicits: 0
			{variant:1}+10 to maximum Life
		]])
		local tooltip = new("Tooltip"):Tooltip()
		build.itemsTab:AddItemTooltip(tooltip, item)

		local count = 0
		for _, line in ipairs(tooltip.lines) do
			if line.text and line.text:find("maximum Life", 1, true) then
				assert.are.equals(item.explicitModLines[1], line.modLine)
				count = count + 1
			end
		end
		assert.are.equals(2, count)
	end)

	it("does not sort cluster jewel modifiers when the sorting control is hidden", function()
		local item = new("Item"):Item([[
			Rarity: RARE
			New Item
			Large Cluster Jewel
			Crafted: true
			Prefix: {range:0.5}AfflictionNotableWickedPall_
			Prefix: {range:0.5}AfflictionNotableMiseryEverlasting
			Suffix: {range:0.5}AfflictionNotableUnholyGrace_
			Suffix: None
			Cluster Jewel Skill: affliction_chaos_damage
			Cluster Jewel Node Count: 8
			Quality: 0
			LevelReq: 40
			Implicits: 3
			{crafted}Adds 8 Passive Skills
			{crafted}2 Added Passive Skills are Jewel Sockets
			{crafted}Added Small Passive Skills grant: 12% increased Chaos Damage
			1 Added Passive Skill is Misery Everlasting
			1 Added Passive Skill is Unholy Grace
			1 Added Passive Skill is Wicked Pall
		]])
		local calcCount = 0
		build.itemsTab.displayItem = item
		build.itemsTab.controls.craftingSorting:SetSel(2, true)
		build.calcsTab.GetMiscCalculator = function()
			return function()
				calcCount = calcCount + 1
				return { }
			end
		end

		assert.is_false(build.itemsTab.controls.craftingSortingLabel.shown())
		build.itemsTab:UpdateAffixControls()
		assert.are.equals(0, calcCount)
	end)

	it("shows custom modifier controls when affix crafting is hidden", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Item
			Iron Ring
			Implicits: 1
			Adds 1 to 4 Physical Damage to Attacks
			{crafted}+8 to Strength
		]])

		local controls = build.itemsTab.controls
		assert.is_falsy(build.itemsTab.displayItem.crafted)
		assert.is_falsy(controls.displayItemSectionAffix:IsShown())
		assert.is_true(controls.displayItemSectionCustom:IsShown())
		assert.is_true(controls.displayItemAddCustom:IsShown())
		assert.is_true(controls.displayItemCustomModifierRemove1:IsShown())
	end)

	it("hides custom modifier controls after saving the display item", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			Test Item
			Iron Ring
			Implicits: 1
			Adds 1 to 4 Physical Damage to Attacks
			{crafted}+8 to Strength
		]])

		local controls = build.itemsTab.controls
		assert.is_true(controls.displayItemCustomModifierRemove1:IsShown())
		assert.is_true(controls.displayItemCustomModifier1:IsShown())

		build.itemsTab:AddDisplayItem()

		assert.is_nil(build.itemsTab.displayItem)
		assert.is_falsy(controls.displayItemSectionCustom:IsShown())
		assert.is_falsy(controls.displayItemCustomModifierRemove1:IsShown())
		assert.is_falsy(controls.displayItemCustomModifier1:IsShown())
		assert.is_falsy(controls.displayItemCustomModifierLabel1:IsShown())
	end)

	it("shows affix controls for items crafted in Path of Building", function()
		build.itemsTab:CreateDisplayItemFromRaw([[
			Rarity: RARE
			New Item
			Cobalt Jewel
			Crafted: true
			Prefix: None
			Prefix: None
			Suffix: None
			Suffix: None
			Quality: 0
			LevelReq: 0
			Implicits: 0
		]])

		local controls = build.itemsTab.controls
		assert.is_true(controls.displayItemSectionAffix:IsShown())
		assert.is_true(controls.displayItemAffix1:IsShown())
	end)

	it("sorts crafted modifier replacements without retaining the selected modifier", function()
		local item = new("Item"):Item([[
			Rarity: RARE
			New Item
			Cobalt Jewel
			Crafted: true
			Prefix: {range:1}PercentIncreasedLifeJewel
			Prefix: None
			Suffix: None
			Suffix: None
			Quality: 0
			LevelReq: 0
			Implicits: 0
			7% increased maximum Life
		]])
		local calcCount = 0
		local retainedCount = 0
		build.itemsTab.displayItem = item
		build.itemsTab.controls.craftingSorting:SetSel(2, true)
		build.calcsTab.GetMiscCalculator = function()
			return function(args)
				calcCount = calcCount + 1
				for _, modLine in ipairs(args.repItem.explicitModLines) do
					if modLine.line == "7% increased maximum Life" then
						retainedCount = retainedCount + 1
						break
					end
				end
				return { }
			end
		end

		build.itemsTab:UpdateAffixControl(build.itemsTab.controls.displayItemAffix1, item, "Prefix", "prefixes", 1, { })
		assert.is_true(calcCount > 1)
		assert.are.equals(0, retainedCount)
	end)
	
	it("shows a fallback tooltip when an item's base is no longer supported", function()
		local item = new("Item"):Item([[
			Rarity: Unique
			Legacy Item
			Removed Base
		]])
		local tooltip = new("Tooltip"):Tooltip()

		assert.has_no.errors(function()
			build.itemsTab:AddItemTooltip(tooltip, item)
		end)
		assert.is_truthy(tooltip.lines[#tooltip.lines].text:find("Item base is not supported", 1, true))
	end)

	local function findActiveSkill(name)
		for _, activeSkill in ipairs(build.calcsTab.mainEnv.player.activeSkillList) do
			if activeSkill.activeEffect.grantedEffect.name == name then
				return activeSkill
			end
		end
	end

	local function countSupport(activeSkill, supportId)
		local count = 0
		for _, effect in ipairs(activeSkill.effectList) do
			if effect.grantedEffect.id == supportId then
				count = count + 1
			end
		end
		return count
	end

	local function hasSupport(activeSkill, supportId)
		return countSupport(activeSkill, supportId) > 0
	end

	local function addItem(raw)
		build.itemsTab:CreateDisplayItemFromRaw(raw)
		build.itemsTab:AddDisplayItem()
	end

	-- Pearl of Tsoatha: despite the "Socketed in" wording these support skills granted
	-- by the item in that slot as well, which ExtraSupport normally excludes
	it("ExtraSupport marked appliesToGrantedSkills supports an item granted skill", function()
		addItem("Granting Helmet\nEzomyte Burgonet\nGrants Level 20 Fireball")
		addItem("Supporting Ring\nPrismatic Ring\nSkills Socketed in your Helmet are Supported by level 20 Added Lightning Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_true(hasSupport(fireball, "SupportAddedLightningDamage"))
		assert.is_true(fireball.skillModList:Sum("BASE", fireball.skillCfg, "LightningMin") > 0)
	end)

	it("ExtraSupport marked appliesToGrantedSkills still supports a socketed gem", function()
		addItem("Socketed Helmet\nEzomyte Burgonet\nSockets: B")
		addItem("Supporting Ring\nPrismatic Ring\nSkills Socketed in your Helmet are Supported by level 20 Added Lightning Damage")
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_true(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	it("ExtraSupport marked appliesToGrantedSkills does not cross slots", function()
		addItem("Granting Gloves\nSpiked Gloves\nGrants Level 20 Fireball")
		addItem("Supporting Ring\nPrismatic Ring\nSkills Socketed in your Helmet are Supported by level 20 Added Lightning Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	-- The relaxation is opt-in, so a Forbidden Shako style mod must keep the old behaviour
	it("plain ExtraSupport does not support an item granted skill", function()
		addItem("Shako Like Helmet\nEzomyte Burgonet\nGrants Level 20 Fireball\nSocketed Gems are Supported by Level 20 Added Cold Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedColdDamage"))
	end)

	local anointedTreeSkill = "Anointed Amulet\nAmber Amulet\nAllocates Radiant Crusade"
	local treePearl = "Tree Pearl\nPrismatic Ring\nSkills granted by your Passive Tree are Supported by level 20 Minion Damage"

	it("ExtraSupport marked appliesToGrantedSkills supports a tree granted skill", function()
		addItem(anointedTreeSkill)
		addItem(treePearl)
		runCallback("OnFrame")

		local sentinel = findActiveSkill("Summon Sentinel of Radiance")
		assert.is_not_nil(sentinel)
		assert.is_true(hasSupport(sentinel, "SupportMinionDamage"))
	end)

	-- Regression guard for the duplicate application fix: addExtraSupports has to go
	-- through addBestSupport, otherwise both rings insert their own copy of the support
	it("applies a tree ExtraSupport once when two items grant it", function()
		addItem(anointedTreeSkill)
		addItem(treePearl)
		addItem(treePearl)
		runCallback("OnFrame")

		local sentinel = findActiveSkill("Summon Sentinel of Radiance")
		assert.is_not_nil(sentinel)
		assert.are.equals(1, countSupport(sentinel, "SupportMinionDamage"))
	end)

	it("tree ExtraSupport does not support an item granted skill", function()
		addItem("Granting Helmet\nEzomyte Burgonet\nGrants Level 20 Fireball")
		addItem("Tree Pearl\nPrismatic Ring\nSkills granted by your Passive Tree are Supported by level 20 Added Lightning Damage")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	it("tree ExtraSupport does not support a socketed gem", function()
		addItem("Socketed Helmet\nEzomyte Burgonet\nSockets: B")
		addItem("Tree Pearl\nPrismatic Ring\nSkills granted by your Passive Tree are Supported by level 20 Added Lightning Damage")
		build.skillsTab:PasteSocketGroup("Slot: Helmet\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local fireball = findActiveSkill("Fireball")
		assert.is_not_nil(fireball)
		assert.is_false(hasSupport(fireball, "SupportAddedLightningDamage"))
	end)

	-- Every tree granted skill shares the synthetic "Passive Tree" slot, so each one pools
	-- the support lists of all the others. A second tree skill must not inflate the count.
	it("applies a tree ExtraSupport once when another tree skill shares the slot", function()
		addItem("Anointed Amulet\nAmber Amulet\nAllocates Radiant Crusade\nAllocates Avatar of the Wilds")
		addItem(treePearl)
		runCallback("OnFrame")

		assert.is_not_nil(findActiveSkill("Unbound Avatar"))
		local sentinel = findActiveSkill("Summon Sentinel of Radiance")
		assert.is_not_nil(sentinel)
		assert.are.equals(1, countSupport(sentinel, "SupportMinionDamage"))
	end)
end)
