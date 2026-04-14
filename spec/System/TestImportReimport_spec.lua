describe("TestImportReimport", function()
	local dkjson = require "dkjson"
	local DEFAULT_CHARACTER_LEVEL = 12
	local DEFAULT_ITEM_LEVEL = 10
	local TEST_IMPORT_ITEM_ID = "test-import-item-1"
	local DEFAULT_SOCKET_COLOR = "R"

	before_each(function()
		newBuild()
	end)

	local function makeGemProperties(level)
		return {
			{ name = "Level", values = { { tostring(level), 0 } } },
			{ name = "Quality", values = { { "+0%", 0 } } },
		}
	end

	local function makeSocketedGemEntry(socket, support, typeLine, level)
		return {
			socket = socket,
			support = support,
			typeLine = typeLine,
			properties = makeGemProperties(level),
		}
	end

	-- Build a minimal import payload so the tests stay focused on state, not fixture noise.
	local function buildImportPayload(itemTypeLine, inventoryId, socketedItems)
		local maxSocketIndex = 0
		for _, socketedItem in ipairs(socketedItems) do
			maxSocketIndex = math.max(maxSocketIndex, socketedItem.socket + 1)
		end
		local sockets = {}
		for index = 1, maxSocketIndex do
			sockets[index] = { group = 0, sColour = DEFAULT_SOCKET_COLOR }
		end
		return dkjson.encode({
			character = { level = DEFAULT_CHARACTER_LEVEL },
			items = {
				{
					id = TEST_IMPORT_ITEM_ID,
					frameType = 0,
					name = "",
					typeLine = itemTypeLine,
					inventoryId = inventoryId,
					ilvl = DEFAULT_ITEM_LEVEL,
					properties = {},
					sockets = sockets,
					socketedItems = socketedItems,
				}
			},
		})
	end

	local function reimportSingleSocketedGem(itemTypeLine, inventoryId, gemName)
		build.importTab.controls.charImportItemsClearSkills.state = true
		build.importTab.controls.charImportItemsClearItems.state = false
		build.importTab:ImportItemsAndSkills(buildImportPayload(itemTypeLine, inventoryId, {
			makeSocketedGemEntry(0, false, gemName, 20),
		}))
		runCallback("OnFrame")
	end

	local function assertReimportPreservesSkillSubstate(slotName, itemTypeLine, inventoryId, gemName, fieldName, fieldValue)
		build.skillsTab:PasteSocketGroup(string.format([[
Slot: %s
%s 20/0 Default  1
]], slotName, gemName))
		runCallback("OnFrame")

		local socketGroup = build.skillsTab.socketGroupList[1]
		local srcInstance = socketGroup.displaySkillList[1].activeEffect.srcInstance
		srcInstance[fieldName] = fieldValue
		srcInstance[fieldName.."Calcs"] = fieldValue
		build.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")

		reimportSingleSocketedGem(itemTypeLine, inventoryId, gemName)

		socketGroup = build.skillsTab.socketGroupList[1]
		srcInstance = socketGroup.displaySkillList[1].activeEffect.srcInstance
		assert.are.equal(fieldValue, srcInstance[fieldName])
		assert.are.equal(fieldValue, srcInstance[fieldName.."Calcs"])
	end

	it("preserves full DPS state and manually disabled gems when reimporting items and skills", function()
		build.skillsTab:PasteSocketGroup([[
Slot: Helmet
Cleave 1/0 Default  1
Heavy Strike 1/0 Default  1
Added Fire Damage 1/0 Default DISABLED 1
]])
		runCallback("OnFrame")

		local socketGroup = build.skillsTab.socketGroupList[1]
		socketGroup.includeInFullDPS = true
		socketGroup.mainActiveSkill = 2
		runCallback("OnFrame")

		build.importTab.controls.charImportItemsClearSkills.state = true
		build.importTab.controls.charImportItemsClearItems.state = false
		build.importTab:ImportItemsAndSkills(buildImportPayload("Iron Hat", "Helm", {
			makeSocketedGemEntry(0, false, "Cleave", 1),
			makeSocketedGemEntry(1, false, "Heavy Strike", 1),
			makeSocketedGemEntry(2, true, "Added Fire Damage Support", 2),
		}))
		runCallback("OnFrame")

		socketGroup = build.skillsTab.socketGroupList[1]
		assert.are.equal("Helmet", socketGroup.slot)
		assert.is_true(socketGroup.includeInFullDPS)
		assert.are.equal(2, socketGroup.mainActiveSkill)
		assert.are.equal(2, socketGroup.gemList[3].level)
		assert.is_false(socketGroup.gemList[3].enabled)
	end)

	it("preserves skill part selection when reimporting items and skills", function()
		assertReimportPreservesSkillSubstate("Helmet", "Iron Hat", "Helm", "Blight", "skillPart", 2)
	end)

	it("preserves stage count when reimporting items and skills", function()
		assertReimportPreservesSkillSubstate("Weapon 1", "Driftwood Wand", "Weapon", "Scorching Ray", "skillStageCount", 8)
	end)

	it("preserves mine count when reimporting items and skills", function()
		assertReimportPreservesSkillSubstate("Gloves", "Rawhide Gloves", "Gloves", "Pyroclast Mine", "skillMineCount", 12)
	end)
end)
