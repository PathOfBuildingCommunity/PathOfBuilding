describe("ManageLoadouts", function()
	before_each(function()
		newBuild()
	end)

	-- pick a tree version that is not the latest, to exercise the version-prefix handling
	local function nonLatestVersion()
		for _, version in ipairs(treeVersionList) do
			if version ~= latestTreeVersion then
				return version
			end
		end
	end

	local function titleExists(sets, orderList, title)
		for _, id in ipairs(orderList) do
			if (sets[id].title or "Default") == title then
				return true
			end
		end
		return false
	end

	it("strips known tree-version prefixes but leaves other bracketed names alone", function()
		local display = treeVersions[nonLatestVersion()].display
		assert.are.equal("Lvl 1", build:StripTreeVersionPrefix("["..display.."] Lvl 1"))
		-- unknown bracketed text is not a version, so it must be preserved
		assert.are.equal("[Boss] Setup", build:StripTreeVersionPrefix("[Boss] Setup"))
		assert.are.equal("Plain Name", build:StripTreeVersionPrefix("Plain Name"))
	end)

	it("recognises a loadout even when its tree is on a non-latest version", function()
		build:CreateLoadout("Leveling")
		-- move the new tree to an older version; the item/skill/config sets keep the plain name
		build.treeTab.specList[#build.treeTab.specList].treeVersion = nonLatestVersion()

		local loadouts = build:GetLoadouts()
		local found = false
		for _, loadout in ipairs(loadouts) do
			if loadout.name == "Leveling" then
				found = true
			end
		end
		assert.is_true(found)
	end)

	it("deletes every set belonging to a loadout", function()
		local specCount = #build.treeTab.specList
		local itemCount = #build.itemsTab.itemSetOrderList
		local skillCount = #build.skillsTab.skillSetOrderList
		local configCount = #build.configTab.configSetOrderList

		build:CreateLoadout("Boss")
		assert.are.equal(specCount + 1, #build.treeTab.specList)
		assert.are.equal(itemCount + 1, #build.itemsTab.itemSetOrderList)

		local target
		for _, loadout in ipairs(build:GetLoadouts()) do
			if loadout.name == "Boss" then
				target = loadout
			end
		end
		assert.is_not_nil(target)

		build:DeleteLoadout(target)

		assert.are.equal(specCount, #build.treeTab.specList)
		assert.are.equal(itemCount, #build.itemsTab.itemSetOrderList)
		assert.are.equal(skillCount, #build.skillsTab.skillSetOrderList)
		assert.are.equal(configCount, #build.configTab.configSetOrderList)

		assert.is_false(titleExists(build.itemsTab.itemSets, build.itemsTab.itemSetOrderList, "Boss"))
		assert.is_false(titleExists(build.skillsTab.skillSets, build.skillsTab.skillSetOrderList, "Boss"))
		assert.is_false(titleExists(build.configTab.configSets, build.configTab.configSetOrderList, "Boss"))
	end)

	it("reorders every set of a loadout together", function()
		build:CreateLoadout("A")
		build:CreateLoadout("B")

		local loadouts = build:GetLoadouts()
		-- find A and B and build a new order with their positions swapped
		local indexA, indexB
		for i, loadout in ipairs(loadouts) do
			if loadout.name == "A" then indexA = i end
			if loadout.name == "B" then indexB = i end
		end
		assert.is_not_nil(indexA)
		assert.is_not_nil(indexB)

		loadouts[indexA], loadouts[indexB] = loadouts[indexB], loadouts[indexA]
		build:ApplyLoadoutOrder(loadouts)

		-- the trees and the id-based order lists must all reflect the new order
		local specTitles = { }
		for _, spec in ipairs(build.treeTab.specList) do
			table.insert(specTitles, spec.title or "Default")
		end
		local posA, posB
		for i, title in ipairs(specTitles) do
			if title == "A" then posA = i end
			if title == "B" then posB = i end
		end
		assert.is_true(posB < posA)

		local itemTitles = { }
		for _, id in ipairs(build.itemsTab.itemSetOrderList) do
			table.insert(itemTitles, build.itemsTab.itemSets[id].title or "Default")
		end
		local itemPosA, itemPosB
		for i, title in ipairs(itemTitles) do
			if title == "A" then itemPosA = i end
			if title == "B" then itemPosB = i end
		end
		assert.is_true(itemPosB < itemPosA)
	end)
end)
