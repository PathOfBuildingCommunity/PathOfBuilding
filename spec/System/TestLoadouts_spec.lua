describe("TestLoadouts", function()
	-- Returns the loadout with the given name and its index in the loadout list
	local function findLoadout(name)
		for index, loadout in ipairs(build.loadoutList) do
			if loadout.name == name then
				return loadout, index
			end
		end
	end

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

	it("creates a custom loadout from a mix of new and copied sets", function()
		build:NewLoadout("Source")
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		local source
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "Source" then
				source = entry
			end
		end
		assert.is_not_nil(source)

		-- Copy the tree and item set, but start the skill and config sets fresh
		listControl:CreateLoadout("Custom", source.specId, source.itemSetId, nil, nil)
		local custom
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "Custom" then
				custom = entry
			end
		end
		assert.is_not_nil(custom)
		-- Every set is newly created, so none are shared with the source loadout
		assert.are_not.equals(source.specId, custom.specId)
		assert.are_not.equals(source.itemSetId, custom.itemSetId)
		assert.are_not.equals(source.skillSetId, custom.skillSetId)
		assert.are_not.equals(source.configSetId, custom.configSetId)
		assert.are.equals("Custom", build.treeTab.specList[custom.specId].title)
		assert.are.equals("Custom", build.itemsTab.itemSets[custom.itemSetId].title)
		assert.are.equals("Custom", build.skillsTab.skillSets[custom.skillSetId].title)
		assert.are.equals("Custom", build.configTab.configSets[custom.configSetId].title)
	end)

	it("creates an all new custom loadout when nothing is copied", function()
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		listControl:CreateLoadout("All New", nil, nil, nil, nil)
		local found = false
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "All New" then
				found = true
			end
		end
		assert.is_true(found)
	end)

	it("generates unique default names for custom loadouts", function()
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		assert.are.equals("New Loadout Custom", listControl:UniqueName("New Loadout Custom"))
		listControl:CreateLoadout("New Loadout Custom", nil, nil, nil, nil)
		assert.are.equals("New Loadout Custom 2", listControl:UniqueName("New Loadout Custom"))
	end)

	it("copies the untitled default loadout without erroring", function()
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		-- A fresh build has one untitled set of each type, which resolves to a "Default" loadout
		assert.are.equals(1, #build.loadoutList)
		assert.are.equals("Default", build.loadoutList[1].name)
		listControl:CopyLoadout(build.loadoutList[1])
		local copyFound = false
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "Default (copy)" then
				copyFound = true
			end
		end
		assert.is_true(copyFound)
	end)

	it("deletes a newly added loadout without breaking the remaining sets", function()
		build:NewLoadout("Second")
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		assert.are.equals(2, #build.loadoutList)
		local second
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "Second" then
				second = entry
			end
		end
		assert.is_not_nil(second)

		listControl:DeleteLoadout(second)

		assert.are.equals(1, #build.loadoutList)
		assert.are.equals(1, #build.treeTab.specList)
		assert.are.equals(1, #build.itemsTab.itemSetOrderList)
		assert.are.equals(1, #build.skillsTab.skillSetOrderList)
		assert.are.equals(1, #build.configTab.configSetOrderList)
		-- The active sets must still point at sets that exist
		assert.is_not_nil(build.treeTab.specList[build.treeTab.activeSpec])
		assert.is_not_nil(build.itemsTab.itemSets[build.itemsTab.activeItemSetId])
		assert.is_not_nil(build.skillsTab.skillSets[build.skillsTab.activeSkillSetId])
		assert.is_not_nil(build.configTab.configSets[build.configTab.activeConfigSetId])
	end)

	it("keeps sets that are shared with another loadout when deleting", function()
		-- Two trees sharing a single item, skill and config set each
		build.treeTab.specList[1].title = "Shared A"
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		listControl:AddSpec(1, "Shared B")
		build:SyncLoadouts()
		assert.are.equals(2, #build.loadoutList)

		local sharedItemSetId = build.itemsTab.itemSetOrderList[1]
		local toDelete
		for _, entry in ipairs(build.loadoutList) do
			if entry.name == "Shared B" then
				toDelete = entry
			end
		end
		listControl:DeleteLoadout(toDelete)

		-- The tree is gone, but the single item set is still used by "Shared A"
		assert.are.equals(1, #build.treeTab.specList)
		assert.is_not_nil(build.itemsTab.itemSets[sharedItemSetId])
		assert.are.equals(1, #build.loadoutList)
	end)

	it("resets the dropdown selection after opening the manager", function()
		local dropdown = build.controls.buildLoadouts
		local manageIndex
		for i, value in ipairs(dropdown.list) do
			if value == "^7^7Manage Loadouts" then
				manageIndex = i
			end
		end
		assert.is_not_nil(manageIndex)
		dropdown:SetSel(manageIndex)
		-- Selection must fall back to the header, otherwise picking "Manage Loadouts"
		-- a second time would not fire the callback again
		assert.are.equals(1, dropdown.selIndex)
		main:ClosePopup()
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

	it("keeps a linked loadout selected when its tree has several identifiers", function()
		-- One tree shared by two loadouts, each with its own item, skill and config set
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		build.treeTab.specList[1].title = "Linked {A,B}"
		build.itemsTab.itemSets[build.itemsTab.itemSetOrderList[1]].title = "Items {A}"
		build.skillsTab.skillSets[build.skillsTab.skillSetOrderList[1]].title = "Skills {A}"
		build.configTab.configSets[build.configTab.configSetOrderList[1]].title = "Config {A}"
		listControl:AddItemSet(nil, "Items {B}")
		listControl:AddSkillSet(nil, "Skills {B}")
		listControl:AddConfigSet(nil, "Config {B}")
		build:SyncLoadouts()
		local loadoutB, index = findLoadout("Linked {B}")
		assert.is_not_nil(loadoutB)

		listControl:SelectIndex(index)
		listControl:OnSelClick(index, loadoutB, true)

		assert.are.equals("Linked {B}", listControl.selValue.name)
		assert.is_true(listControl:IsActiveLoadout(listControl.selValue))
	end)

	it("keeps the manager's selection on a current row after Sync and New", function()
		build:NewLoadout("First")
		build:OpenLoadoutManagePopup()
		local manager = main.popups[1]
		local listControl = manager.controls[1]
		listControl:SelectIndex(select(2, findLoadout("First")))

		-- Sync rebuilds every row, so the selection has to follow the loadout to its new row
		manager.controls[2]:Click()
		assert.are.equals("First", listControl.selValue.name)
		assert.are.equals(listControl.list[listControl.selIndex], listControl.selValue)
		listControl:DeleteLoadout(listControl.selValue)
		assert.is_nil(findLoadout("First"))

		-- New selects the loadout it creates, like Copy and New/Copy Custom do
		listControl.controls.new:Click()
		local controls = main.popups[1].controls
		controls.edit:SetText("Second", true)
		controls.save:Click()
		assert.are.equals("Second", listControl.selValue.name)
		assert.are.equals(listControl.list[listControl.selIndex], listControl.selValue)
		main:ClosePopup()
	end)

	it("rejects renaming a loadout to a name already in use", function()
		build:NewLoadout("First")
		build:NewLoadout("Second")
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		listControl:RenameLoadout(findLoadout("Second"))
		local controls = main.popups[1].controls
		controls.edit:SetText("First", true)
		assert.is_falsy(controls.save:IsEnabled())
		-- Keeping the current name is allowed, as is a free one
		controls.edit:SetText("Second", true)
		assert.is_truthy(controls.save:IsEnabled())
		controls.edit:SetText("Third", true)
		assert.is_truthy(controls.save:IsEnabled())
		main:ClosePopup()
	end)

	it("allows renaming a linked loadout to the name of an unlinked one", function()
		build:NewLoadout("First")
		build.treeTab.specList[1].title = "Linked {A}"
		build.itemsTab.itemSets[build.itemsTab.itemSetOrderList[1]].title = "Items {A}"
		build.skillsTab.skillSets[build.skillsTab.skillSetOrderList[1]].title = "Skills {A}"
		build.configTab.configSets[build.configTab.configSetOrderList[1]].title = "Config {A}"
		build:SyncLoadouts()
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		local first = findLoadout("First")
		listControl:RenameLoadout(findLoadout("Linked {A}"))
		local controls = main.popups[1].controls
		controls.edit:SetText("First", true)
		assert.is_truthy(controls.save:IsEnabled())
		controls.save:Click()

		-- The sets are tied together by the identifier, so both loadouts keep their own sets
		local renamed = findLoadout("First {A}")
		assert.is_not_nil(renamed)
		assert.are.equals(first.itemSetId, findLoadout("First").itemSetId)
		assert.are_not.equals(first.itemSetId, renamed.itemSetId)
	end)

	it("rejects new loadouts named after an existing passive tree or set", function()
		build:NewLoadout("First")
		-- A tree without matching sets is not a loadout, but one of the same name would still clash with it
		build.treeTab.specList[1].title = "Unmatched"
		build:SyncLoadouts()
		assert.is_nil(findLoadout("Unmatched"))
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)

		listControl:CreateCustomLoadoutPopup()
		local controls = main.popups[1].controls
		controls.edit:SetText("First", true)
		assert.is_falsy(controls.save:IsEnabled())
		controls.edit:SetText("Unmatched", true)
		assert.is_falsy(controls.save:IsEnabled())
		controls.edit:SetText("Third", true)
		assert.is_truthy(controls.save:IsEnabled())
		main:ClosePopup()

		build:OpenLoadoutNamePopup()
		controls = main.popups[1].controls
		controls.edit:SetText("First", true)
		assert.is_falsy(controls.save:IsEnabled())
		controls.edit:SetText("Third", true)
		assert.is_truthy(controls.save:IsEnabled())
		main:ClosePopup()
	end)

	it("defaults a custom loadout to the active sets, or those of the selected loadout", function()
		build:NewLoadout("Other")
		local listControl = new("LoadoutListControl"):LoadoutListControl(nil, {0, 0, 450, 200}, build)
		listControl:CreateCustomLoadoutPopup()
		local controls = main.popups[1].controls
		assert.are.equals(build.treeTab.activeSpec, controls.treeSelect:GetSelValue().id)
		assert.are.equals(build.itemsTab.activeItemSetId, controls.itemSelect:GetSelValue().id)
		assert.are.equals(build.skillsTab.activeSkillSetId, controls.skillSelect:GetSelValue().id)
		assert.are.equals(build.configTab.activeConfigSetId, controls.configSelect:GetSelValue().id)
		main:ClosePopup()

		local other, index = findLoadout("Other")
		listControl:SelectIndex(index)
		listControl:CreateCustomLoadoutPopup()
		controls = main.popups[1].controls
		assert.are.equals(other.specId, controls.treeSelect:GetSelValue().id)
		assert.are.equals(other.itemSetId, controls.itemSelect:GetSelValue().id)
		assert.are.equals(other.skillSetId, controls.skillSelect:GetSelValue().id)
		assert.are.equals(other.configSetId, controls.configSelect:GetSelValue().id)
		main:ClosePopup()
	end)
end)
