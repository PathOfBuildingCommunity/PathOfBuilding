describe("Custom modifier controls", function()
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

	local configModBrowser = require("Modules.ConfigModBrowser")

	local function openModBrowser()
		local configTab = build.configTab
		local blockData = configTab.configSets[configTab.activeConfigSetId].customModsList[1]
		configModBrowser.OpenAddModPopup(configTab, blockData)
		return main.popups[1], blockData
	end

	local function getModTemplate(modText)
		return modText
			:gsub("([%+-]?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", "%1#")
			:gsub("%d+%.?%d*", "#")
			:lower()
	end

	it("does not retain the modifier list focus after adding a mod", function()
		local popup, blockData = openModBrowser()
		local listControl = popup.controls.listControl
		local selectedMod = listControl.list[1]

		listControl:OnSelClick(1, selectedMod, false)
		popup.controls.save.onClick()

		assert.is_nil(main.selControl)
		assert.are_not.equal(popup, main.popups[1])
		assert.are.equal(selectedMod.text, blockData.text)
	end)

	it("collapses numeric tiers into a single entry and imports it", function()
		local popup, blockData = openModBrowser()
		local minionDamageEntries = { }
		local minionDamageIndex
		for index, mod in ipairs(popup.controls.listControl.list) do
			if mod.text:match("^Minions deal .-%% increased Damage$") then
				table.insert(minionDamageEntries, mod.text)
				minionDamageIndex = index
			end
		end

		assert.are.same({ "Minions deal 10% increased Damage" }, minionDamageEntries)
		popup.controls.listControl.selIndex = minionDamageIndex
		popup.controls.save.onClick()
		assert.are.equal("Minions deal 10% increased Damage", blockData.text)
	end)

	it("orders modifiers alphabetically while ignoring numeric values", function()
		local popup = openModBrowser()
		local previousSortKey
		for _, mod in ipairs(popup.controls.listControl.list) do
			local sortKey = mod.text
				:gsub("([%+-]?)%((%-?%d+%.?%d*)%-(%-?%d+%.?%d*)%)", "%1#")
				:gsub("%d+%.?%d*", "#")
				:lower()
				:gsub("#", " ")
				:gsub("[^%a]+", " ")
				:match("^%s*(.-)%s*$")
			assert.is_true(not previousSortKey or previousSortKey <= sortKey,
				tostring(previousSortKey) .. " should be ordered before " .. sortKey)
			previousSortKey = sortKey
		end
	end)

	it("clears the modifier search with its clear button", function()
		local popup = openModBrowser()
		local controls = popup.controls
		local unfilteredCount = #controls.listControl.list
		assert.is_false(controls.search.controls.buttonClear:IsShown())
		controls.search:SetText("minion damage", true)

		assert.is_true(#controls.listControl.list < unfilteredCount)
		assert.are.equal("minion damage", controls.search.buf)
		assert.is_true(controls.search.controls.buttonClear:IsShown())

		controls.search.controls.buttonClear.onClick()

		assert.are.equal("", controls.search.buf)
		assert.are.equal(unfilteredCount, #controls.listControl.list)
		assert.is_false(controls.search.controls.buttonClear:IsShown())
	end)

	it("disables adding when no modifiers match the search", function()
		local popup = openModBrowser()
		local controls = popup.controls

		controls.search:SetText("this modifier cannot possibly exist", true)

		assert.are.equal("No matching modifiers found", controls.listControl.list[1].text)
		assert.is_false(controls.save:IsEnabled())
	end)

	it("includes every supported tree modifier", function()
		local popup = openModBrowser()
		local displayedMods = { }
		for _, mod in ipairs(popup.controls.listControl.list) do
			displayedMods[mod.template] = mod
		end

		local tree = build.treeTab.specList[build.treeTab.activeSpec].tree
		for _, node in pairs(tree.nodes) do
			if node.type == "Mastery" and node.masteryEffects then
				for _, masteryEffect in ipairs(node.masteryEffects) do
					for _, statLine in ipairs(masteryEffect.stats) do
						local modList, extra = modLib.parseMod(statLine)
						if modList and not extra then
							local displayed = displayedMods[getModTemplate(statLine)]
							assert.is_not_nil(displayed, "Missing supported mastery modifier: " .. statLine)
							assert.is_true(displayed.sources["Mastery Node"], "Missing mastery source: " .. statLine)
						end
					end
				end
			else
				local i = 1
				while node.stats[i] do
					local combinedLine = node.stats[i]
					while node.mods[i + 1] and node.mods[i + 1].combined do
						combinedLine = combinedLine .. " " .. node.stats[i + 1]
						i = i + 1
					end
					if node.mods[i].list and not node.mods[i].extra then
						assert.is_not_nil(displayedMods[getModTemplate(combinedLine)], "Missing supported tree modifier: " .. combinedLine)
					end
					i = i + 1
				end
			end
		end
	end)

	it("only lists modifier text accepted by the parser", function()
		local popup = openModBrowser()
		for _, mod in ipairs(popup.controls.listControl.list) do
			local modList, extra = modLib.parseMod(mod.text)
			assert.is_not_nil(modList, "Unsupported browser modifier: " .. mod.text)
			assert.is_nil(extra, "Partially supported browser modifier: " .. mod.text)
		end
	end)

	it("uses the expanded browser dimensions", function()
		local popup = openModBrowser()
		local listWidth, listHeight = popup.controls.listControl:GetSize()
		local searchWidth = popup.controls.search:GetSize()

		assert.are.equal(720, popup.width)
		assert.are.equal(566, popup.height)
		assert.are.equal(700, listWidth)
		assert.are.equal(454, listHeight)
		assert.are.equal(640, searchWidth)
	end)

	it("opens with the search field ready for typing", function()
		local popup = openModBrowser()
		local inputEvents = { { type = "Char", key = "m" } }

		assert.are.equal(popup.controls.search, popup.selControl)
		assert.is_true(popup.controls.search.hasFocus)
		assert.is_nil(popup.controls.listControl.hasFocus)

		popup:ProcessInput(inputEvents, { x = 0, y = 0, width = 1920, height = 1080 })

		assert.are.equal("m", popup.controls.search.buf)
	end)

	it("uses the mod group title as the calculation source name", function()
		local configTab = build.configTab
		local blockData = configTab.configSets[configTab.activeConfigSetId].customModsList[1]
		blockData.text = "+100 to maximum Life"
		configTab:BuildModList()

		configTab.customModsBlockControls[1].controls.titleEdit:SetText("Bossing", true)

		local customMods = configTab.modList:Tabulate("BASE", nil, "Life")
		assert.are.equal(1, #customMods)
		assert.are.equal("Custom:Bossing", customMods[1].mod.source)

		build.buildFlag = true
		runCallback("OnFrame")
		local breakdownControl = build.calcsTab.controls.breakdown
		breakdownControl.sectionList = { }
		breakdownControl:AddModSection({ modName = "Life", modType = "BASE" })
		local customRow
		for _, row in ipairs(breakdownControl.sectionList[1].rowList) do
			if row.mod.source == "Custom:Bossing" then
				customRow = row
				break
			end
		end

		assert.is_not_nil(customRow)
		assert.are.equal("Custom", customRow.source)
		assert.are.equal("Bossing", customRow.sourceName)
	end)
end)
