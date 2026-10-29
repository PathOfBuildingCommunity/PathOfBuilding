describe("Cluster jewel notable preview", function()
	local function makeCluster(names, size, count, sockets)
		size = size or "Large"
		local raw = "Rarity: RARE\nPreview\n"..size.." Cluster Jewel\nImplicits: 2\nAdds "..(count or 8).." Passive Skills\n"..(sockets or 2).." Added Passive Skills are Jewel Sockets\n"
		for _, name in ipairs(names) do
			raw = raw.."1 Added Passive Skill is "..name.."\n"
		end
		return new("Item"):Item(raw)
	end

	local function positions(item)
		return itemLib.getClusterJewelNotablePositions(item, data.clusterJewels.notableSortOrder)
	end

	before_each(function()
		newBuild()
	end)

	it("places a single large-cluster notable at the back", function()
		assert.are.same({ { name = "Renewal", index = 6, position = "Back" } }, positions(makeCluster({ "Renewal" })))
	end)

	it("moves the desired pair to the front when a middle-ordered notable is added", function()
		local names = { "Feasting Fiends", "Renewal" }
		local item = makeCluster(names)
		assert.are.same({
			{ name = "Renewal", index = 6, position = "Back" },
			{ name = "Feasting Fiends", index = 10, position = "Front" },
		}, positions(item))
		table.insert(names, "Call to the Slaughter")
		assert.are.same({
			{ name = "Renewal", index = 2, position = "Front" },
			{ name = "Call to the Slaughter", index = 6, position = "Back" },
			{ name = "Feasting Fiends", index = 10, position = "Front" },
		}, positions(makeCluster(names)))
		assert.are.same({ "Feasting Fiends", "Renewal" }, item.jewelData.clusterJewelNotables)
	end)

	it("handles the legacy single socket and socket-count override", function()
		local item = makeCluster({ "Renewal", "Feasting Fiends" }, "Large", 8, 1)
		assert.are.same({ 4, 8 }, itemLib.getClusterJewelNotableIndices(item.clusterJewel, item.jewelData, 2))
		item.jewelData.clusterJewelSocketCountOverride = 2
		assert.are.same({ 6, 10 }, itemLib.getClusterJewelNotableIndices(item.clusterJewel, item.jewelData, 2))
	end)

	it("uses the special four-passive medium-cluster positions", function()
		local item = makeCluster({ "Flow of Life", "Brush with Death" }, "Medium", 4, 1)
		local preview = positions(item)
		assert.are.equal(3, preview[1].index)
		assert.are.equal(9, preview[2].index)
		assert.are.equal("Front", preview[1].position)
		assert.are.equal("Front", preview[2].position)
		item.jewelData.clusterJewelSocketCountOverride = 0
		assert.are.same({ 4, 8 }, itemLib.getClusterJewelNotableIndices(item.clusterJewel, item.jewelData, 2))
	end)

	it("labels a small cluster's terminal notable as End", function()
		local preview = positions(makeCluster({ "Fettle" }, "Small", 3, 0))
		assert.are.equal("End", preview[1].position)
	end)

	it("returns no positions for ordinary items, empty clusters, or keystones", function()
		assert.are.same({ }, positions(nil))
		assert.are.same({ }, positions(new("Item"):Item("Rarity: NORMAL\nIron Ring")))
		assert.are.same({ }, positions(makeCluster({ })))
		local item = makeCluster({ "Renewal" })
		item.jewelData.clusterJewelKeystone = "Hollow Palm Technique"
		assert.are.same({ }, positions(item))
	end)

	it("hides the editor readout for ordinary medium and small clusters", function()
		for _, item in ipairs({
			makeCluster({ "Flow of Life", "Brush with Death" }, "Medium", 4, 1),
			makeCluster({ "Fettle" }, "Small", 3, 0),
		}) do
			build.itemsTab:SetDisplayItem(item)
			item.crafted = true
			local controls = build.itemsTab.controls
			assert.is_falsy(controls.displayItemClusterJewelPositions:IsShown())
			assert.are.equal(0, controls.displayItemSectionClusterJewelPositions:GetProperty("height"))
		end
	end)

	it("shows Megalomaniac positions without requiring crafting controls", function()
		local item = new("Item"):Item([[Rarity: UNIQUE
Megalomaniac
Medium Cluster Jewel
Implicits: 2
Adds 4 Passive Skills
Added Small Passive Skills grant Nothing
1 Added Passive Skill is Feasting Fiends
1 Added Passive Skill is Renewal
1 Added Passive Skill is Call to the Slaughter]])
		build.itemsTab:SetDisplayItem(item)
		local controls = build.itemsTab.controls
		assert.is_falsy(controls.displayItemClusterJewelSkill:IsShown())
		assert.is_true(controls.displayItemClusterJewelPosition3:IsShown())
		assert.are.same({
			{ name = "Renewal", index = 3, position = "Front" },
			{ name = "Call to the Slaughter", index = 6, position = "Back" },
			{ name = "Feasting Fiends", index = 9, position = "Front" },
		}, build.itemsTab.clusterJewelNotablePositions)
		assert.are.equal(78, controls.displayItemSectionClusterJewelPositions:GetProperty("height"))
	end)

	it("updates the editor readout and collapses it when the last notable is removed", function()
		local tab = build.itemsTab
		local item = makeCluster({ "Renewal" })
		-- Exercise the editor controls without turning this parsed fixture into a crafted item.
		tab:SetDisplayItem(item)
		item.crafted = true
		local controls = tab.controls
		assert.is_true(controls.displayItemClusterJewelPosition1:IsShown())
		assert.is_truthy(controls.displayItemClusterJewelPosition1:GetProperty("label"):find("Back: %^7Renewal"))
		assert.are.equal(52, controls.displayItemSectionClusterJewel:GetProperty("height"))
		assert.are.equal(42, controls.displayItemSectionClusterJewelPositions:GetProperty("height"))
		item.jewelData.clusterJewelNotables = { "Feasting Fiends", "Call to the Slaughter", "Renewal" }
		tab:UpdateDisplayItemTooltip()
		assert.is_truthy(controls.displayItemClusterJewelPosition1:GetProperty("label"):find("Front: %^7Renewal"))
		assert.is_true(controls.displayItemClusterJewelPosition3:IsShown())
		local _, lastLabelY = controls.displayItemClusterJewelPosition3:GetPos()
		local _, headerY = controls.displayItemClusterJewelPositions:GetPos()
		local _, addModifierY = controls.displayItemAddCustom:GetPos()
		local _, rangeY = controls.displayItemSectionRange:GetPos()
		assert.is_true(headerY >= addModifierY + 28)
		assert.is_true(rangeY >= lastLabelY + 18)
		item.jewelData.clusterJewelNotables = { }
		tab:UpdateDisplayItemTooltip()
		assert.is_false(controls.displayItemClusterJewelPositions:IsShown())
		assert.are.equal(0, controls.displayItemSectionClusterJewelPositions:GetProperty("height"))
		assert.are.equal(52, controls.displayItemSectionClusterJewel:GetProperty("height"))
		tab:SetDisplayItem(new("Item"):Item("Rarity: NORMAL\nIron Ring"))
		assert.is_falsy(controls.displayItemClusterJewelPosition1:IsShown())
		assert.are.equal(0, controls.displayItemSectionClusterJewel:GetProperty("height"))
	end)
end)
