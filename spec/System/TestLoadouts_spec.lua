describe("TestLoadouts", function()
	before_each(function()
		newBuild()
	end)

	teardown(function()
		-- newBuild() takes care of resetting everything in before_each()
	end)

	it("creates a new loadout with all four sets", function()
		build:NewLoadout("My Loadout")
		assert.are.equals("My Loadout", build.treeTab.specList[#build.treeTab.specList].title)
		assert.are.equals("My Loadout", build.itemsTab.itemSets[build.itemsTab.itemSetOrderList[#build.itemsTab.itemSetOrderList]].title)
		assert.are.equals("My Loadout", build.skillsTab.skillSets[build.skillsTab.skillSetOrderList[#build.skillsTab.skillSetOrderList]].title)
		assert.are.equals("My Loadout", build.configTab.configSets[build.configTab.configSetOrderList[#build.configTab.configSetOrderList]].title)
		local found = false
		for _, loadout in ipairs(build.loadoutList) do
			if loadout.name == "My Loadout" then
				found = true
			end
		end
		assert.is_true(found)
	end)

	it("copies a loadout automatically", function()
		build:NewLoadout("My Loadout")
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		local loadout
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "My Loadout" then
				loadout = entry
			end
		end
		assert.is_not_nil(loadout)
		listControl:CopyLoadout(loadout)
		local copyFound = false
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "My Loadout (copy)" then
				copyFound = true
			end
		end
		assert.is_true(copyFound)
		-- Copying again picks a unique name
		listControl:CopyLoadout(loadout)
		local copy2Found = false
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "My Loadout (copy 2)" then
				copy2Found = true
			end
		end
		assert.is_true(copy2Found)
	end)

	it("resolves link identifier loadouts", function()
		build.treeTab.specList[1].title = "Tree {A}"
		local itemSet = build.itemsTab.itemSets[build.itemsTab.itemSetOrderList[1]]
		itemSet.title = "Items {A}"
		-- With only one skill and config set, they are shared by all loadouts
		build:SyncLoadouts()
		local loadout
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "Tree {A}" then
				loadout = entry
			end
		end
		assert.is_not_nil(loadout)
		assert.are.equals(1, loadout.specId)
		assert.are.equals(build.itemsTab.itemSetOrderList[1], loadout.itemSetId)
	end)
end)
