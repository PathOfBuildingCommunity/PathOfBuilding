describe("TestConfig", function()
	before_each(function()
		newBuild()
		runCallback("OnFrame")
	end)

	describe("ConfigTab", function()
		describe("NewConfigSet", function()
			it("Creates a new config set with specified ID", function()
				local configSetName = "New Config Set"
				local configId = 2
				build.configTab:NewConfigSet(configId, configSetName)

				assert.are.equals(configSetName, build.configTab.configSets[configId].title)
				assert.are.equals(configId, build.configTab.configSets[configId].id)
			end)

			it("Assigns auto-incremented ID when not specified", function()
				local configSetName = "Auto ID Config Set"
				local configSet1 = build.configTab:NewConfigSet()
				local configSet2 = build.configTab:NewConfigSet(nil, configSetName)

				assert.are.equals(2, configSet1.id)
				assert.are.equals(3, configSet2.id)
				assert.are.equals(configSetName, build.configTab.configSets[configSet2.id].title)
			end)

			it("Adds set to order list", function()
				local newTitle = "New Config"

				build.configTab:NewConfigSet(nil, newTitle)

				assert.are.equals(2, #build.configTab.configSetOrderList)
				assert.are.equals(2, build.configTab.configSetOrderList[2])
			end)

			it("Updates the mod flag", function()
				local newTitle = "New Config"
				build.configTab.modFlag = false

				build.configTab:NewConfigSet(nil, newTitle)

				assert.is_true(build.configTab.modFlag)
			end)
		end)

		describe("CopyConfigSet", function()
			it("Copies a config set with a new name", function()
				local newTitle = "Copied Config"
				local newConfigSet = build.configTab:CopyConfigSet(1, newTitle)


				assert.is_not.same(build.configTab.configSets[1], newConfigSet)
				assert.are.equals(newTitle, newConfigSet.title)
				assert.are.same(build.configTab.configSets[1].input, newConfigSet.input)
				assert.are.same(build.configTab.configSets[1].placeholder, newConfigSet.placeholder)
			end)

			it("Copies all input and placeholder values", function()
				local newTitle = "Copied Config"

				build.configTab.configSets[1].input.testValue = 42
				build.configTab.configSets[1].placeholder.testValue = 99

				local newConfigSet = build.configTab:CopyConfigSet(1, newTitle)

				assert.are.equals(42, newConfigSet.input.testValue)
				assert.are.equals(99, newConfigSet.placeholder.testValue)
			end)

			it("Returns copied config set with next ID", function()
				local newTitle = "Copied Config"

				local newConfigSet = build.configTab:CopyConfigSet(1, newTitle)

				assert.are.equals(2, newConfigSet.id)
			end)

			it("Adds copied config set to order list", function()
				local newTitle = "Copied Config"

				build.configTab:CopyConfigSet(1, newTitle)

				assert.are.equals(2, #build.configTab.configSetOrderList)
				assert.are.equals(2, build.configTab.configSetOrderList[2])
			end)

			it("Updates the mod flag", function()
				local newTitle = "Copied Config"
				build.configTab.modFlag = false

				build.configTab:CopyConfigSet(1, newTitle)

				assert.is_true(build.configTab.modFlag)
			end)
		end)

		describe("RenameConfigSet", function()
			it("Renames a config set", function()
				local newTitle = "Renamed Config"
				build.configTab:RenameConfigSet(1, newTitle)

				assert.are.equals(newTitle, build.configTab.configSets[1].title)
			end)

			it("Does not rename non-existent config set", function()
				build.configTab:RenameConfigSet(999, "Non-existent")

				assert.is_nil(build.configTab.configSets[999])
			end)

			it("Updates the mod flag", function()
				local newTitle = "Renamed Config"
				build.configTab.modFlag = false

				build.configTab:RenameConfigSet(1, newTitle)

				assert.is_true(build.configTab.modFlag)
			end)
		end)

		describe("DeleteConfigSet", function()
			it("Deletes a config set and its order entry", function()
				local configSetName = "Config To Delete"
				build.configTab:NewConfigSet(2, configSetName)

				build.configTab:DeleteConfigSet(2, 2)

				assert.is_nil(build.configTab.configSets[2])
				assert.are.equals(1, #build.configTab.configSetOrderList)
			end)

			it("allows deletion of the last config set", function()
				local lastConfig = 1

				assert.are.equals(1, #build.configTab.configSetOrderList)
				build.configTab:DeleteConfigSet(lastConfig, 1)

				assert.are.equals(0, #build.configTab.configSetOrderList)
				assert.is_nil(build.configTab.configSets[lastConfig])
			end)
		end)

		describe("SetActiveConfigSet", function()
			it("Switches to a valid config set", function()
				local configSetName = "New Config"
				build.configTab:NewConfigSet(2, configSetName)

				build.configTab:SetActiveConfigSet(2)

				assert.are.equals(2, build.configTab.activeConfigSetId)
				assert.are.same(build.configTab.configSets[2].input, build.configTab.input)
				assert.are.same(build.configTab.configSets[2].placeholder, build.configTab.placeholder)
			end)

			it("Defaults to first config set if invalid ID provided", function()
				build.configTab:SetActiveConfigSet(999)

				assert.are.equals(1, build.configTab.activeConfigSetId)
			end)

			it("Does not trigger rebuild when init is true", function()
				local configSetName = "New Config"
				build.configTab:NewConfigSet(2, configSetName)

				build.modFlag = false

				build.configTab:SetActiveConfigSet(2, true)

				assert.are.equals(2, build.configTab.activeConfigSetId)
				assert.is_false(build.modFlag)
			end)
		end)
	end)

	describe("ConfigSetService", function()
		local configSetService

		before_each(function()
			configSetService = new("ConfigSetService", build.configTab)
		end)

		describe("NewConfigSet", function()
			it("Creates a new config set via service", function()
				local configSetName = "Service New Config"
				configSetService:NewConfigSet(configSetName)

				assert.are.equals(2, #build.configTab.configSetOrderList)
				assert.are.equals(configSetName, build.configTab.configSets[2].title)
			end)

			it("Sets newly created config as active", function()
				configSetService:NewConfigSet("New From Service")

				assert.are.equals(2, build.configTab.activeConfigSetId)
			end)

			it("Adds an undo state", function()
				local newTitle = "New Config"

				local undoCountBefore = #build.configTab.undo
				configSetService:NewConfigSet(newTitle)

				assert.are.equals(#build.configTab.undo, undoCountBefore + 1)
			end)
		end)

		describe("CopyConfigSet", function()
			it("Copies a config set via service", function()
				local configSetName = "Copied via Service"
				configSetService:CopyConfigSet(1, configSetName)
				local configId = build.configTab.configSetOrderList[2]

				assert.are.equals(configSetName, build.configTab.configSets[configId].title)
			end)

			it("Sets copied config as active via service", function()
				configSetService:NewConfigSet("Config")
				configSetService:CopyConfigSet(1, "Service Copy")
				local configId = build.configTab.configSetOrderList[3]

				assert.are.equals(configId, build.configTab.activeConfigSetId)
			end)

			it("Adds an undo state when copying a config set", function()
				local undoCountBefore = #build.configTab.undo
				configSetService:CopyConfigSet(1, "Copied Config")

				assert.are.equals(#build.configTab.undo, undoCountBefore + 1)
			end)
		end)

		describe("RenameConfigSet", function()
			it("Renames a config set via service", function()
				local configSetName = "Original Name"
				configSetService:NewConfigSet(configSetName)
				local configId = build.configTab.configSetOrderList[2]

				configSetService:RenameConfigSet(configId, "New Name")

				assert.are.equals("New Name", build.configTab.configSets[configId].title)
			end)

			it("Does not rename non-existent config set", function()
				configSetService:RenameConfigSet(10, "Non-existent")

				assert.is_nil(build.configTab.configSets[10])
			end)

			it("Adds an undo state when renaming", function()
				local configSetName = "Config To Rename"
				configSetService:NewConfigSet(configSetName)
				local configId = build.configTab.configSetOrderList[2]

				local undoCountBefore = #build.configTab.undo
				configSetService:RenameConfigSet(configId, "Renamed Config")

				assert.are.equals(#build.configTab.undo, undoCountBefore + 1)
			end)
		end)

		describe("DeleteConfigSet", function()
			it("Deletes a config set via service", function()
				configSetService:NewConfigSet("Service Delete Me")

				configSetService:DeleteConfigSet(2, 2)

				assert.is_nil(build.configTab.configSets[2])
				assert.is_nil(build.configTab.configSetOrderList[2])
			end)


			it("Switches active config set when deleting current", function()
				configSetService:NewConfigSet("Service Delete Me")
				local configToKeep = 1
				local configToDelete = 2

				assert.are.equals(configToDelete, build.configTab.activeConfigSetId)

				configSetService:DeleteConfigSet(configToDelete, 2)

				assert.are.equals(configToKeep, build.configTab.activeConfigSetId)
			end)

			it("Does not delete last config set via service", function()
				configSetService:NewConfigSet("Last One")

				configSetService:DeleteConfigSet(1, 1)

				assert.are.equals(1, #build.configTab.configSetOrderList)
			end)

			it("Adds an undo state when deleting", function()
				local undoCountBefore = #build.configTab.undo
				local undoCountAfterNew = #build.configTab.undo
				configSetService:NewConfigSet("Undo Delete Test")

				configSetService:DeleteConfigSet(2, 2)

				assert.are.equals(#build.configTab.undo, undoCountBefore + 2)
			end)
		end)

		describe("Integration", function()
			it("Completes a config set lifecycle", function()
				local config1Name = "First Config"
				local config2Name = "Second Config"

				configSetService:NewConfigSet(config1Name)
				assert.are.equals("First Config", build.configTab.configSets[2].title)

				configSetService:CopyConfigSet(2, config2Name)
				assert.are.equals("Second Config", build.configTab.configSets[3].title)
			end)
		end)
	end)

	describe("ConfigStateManagement", function()
		local configSetService

		before_each(function()
			configSetService = new("ConfigSetService", build.configTab)
		end)

		describe("Input and placeholder persistence", function()
			it("Preserves input values across config set switches", function()
				local testValue = 123

				configSetService:NewConfigSet("Set 1")
				configSetService:NewConfigSet("Set 2")

				build.configTab.configSets[1].input.testVar = testValue
				build.configTab:SetActiveConfigSet(1)

				assert.are.equals(testValue, build.configTab.configSets[1].input.testVar)

				build.configTab:SetActiveConfigSet(3)
				build.configTab.configSets[3].input.testVar = testValue

				build.configTab:SetActiveConfigSet(1)
				assert.are.equals(testValue, build.configTab.configSets[1].input.testVar)
				assert.are.equals(testValue, build.configTab.configSets[3].input.testVar)
			end)

			it("Preserves placeholder values across config set switches", function()
				local placeholderValue = 456

				configSetService:NewConfigSet("Set 1")
				configSetService:NewConfigSet("Set 2")
				configSetService:NewConfigSet("Set 3")

				build.configTab.configSets[3].placeholder.testVar = placeholderValue

				build.configTab:SetActiveConfigSet(3)
				assert.are.equals(placeholderValue, build.configTab.configSets[3].placeholder.testVar)
			end)
		end)

		describe("Default values", function()
			it("Initializes new config sets with default placeholder states", function()
				assert.is_not_nil(build.configTab.configSets[1])
				assert.is_not_nil(build.configTab.configSets[1].input)
				assert.is_not_nil(build.configTab.configSets[1].placeholder)
			end)

			it("Copies placeholder states when copying config sets", function()
				build.configTab.configSets[1].placeholder.testPlaceholder = "test"

				local newConfigSet = build.configTab:CopyConfigSet(1, "Copy Test")

				assert.are.equals("test", newConfigSet.placeholder.testPlaceholder)
			end)
		end)
	end)
end)
