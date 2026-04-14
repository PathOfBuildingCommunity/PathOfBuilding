describe("TestImportReimport", function()
	before_each(function()
		newBuild()
	end)

	local function reimportSingleSocketedGem(itemTypeLine, inventoryId, gemName)
		build.importTab.controls.charImportItemsClearSkills.state = true
		build.importTab.controls.charImportItemsClearItems.state = false
		build.importTab:ImportItemsAndSkills(string.format([=[
{
	"character": {
		"level": 12
	},
	"items": [
		{
			"id": "item-1",
			"frameType": 0,
			"name": "",
			"typeLine": "%s",
			"inventoryId": "%s",
			"ilvl": 10,
			"properties": [],
			"sockets": [
				{ "group": 0, "sColour": "R" }
			],
			"socketedItems": [
				{
					"socket": 0,
					"support": false,
					"typeLine": "%s",
					"properties": [
						{ "name": "Level", "values": [["20", 0]] },
						{ "name": "Quality", "values": [["+0%%", 0]] }
					]
				}
			]
		}
	]
}
]=], itemTypeLine, inventoryId, gemName))
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
		build.importTab:ImportItemsAndSkills([=[
{
	"character": {
		"level": 12
	},
	"items": [
		{
			"id": "helm-1",
			"frameType": 0,
			"name": "",
			"typeLine": "Iron Hat",
			"inventoryId": "Helm",
			"ilvl": 10,
			"properties": [],
			"sockets": [
				{ "group": 0, "sColour": "R" },
				{ "group": 0, "sColour": "R" },
				{ "group": 0, "sColour": "R" }
			],
			"socketedItems": [
				{
					"socket": 0,
					"support": false,
					"typeLine": "Cleave",
					"properties": [
						{ "name": "Level", "values": [["1", 0]] },
						{ "name": "Quality", "values": [["+0%", 0]] }
					]
				},
				{
					"socket": 1,
					"support": false,
					"typeLine": "Heavy Strike",
					"properties": [
						{ "name": "Level", "values": [["1", 0]] },
						{ "name": "Quality", "values": [["+0%", 0]] }
					]
				},
				{
					"socket": 2,
					"support": true,
					"typeLine": "Added Fire Damage Support",
					"properties": [
						{ "name": "Level", "values": [["2", 0]] },
						{ "name": "Quality", "values": [["+0%", 0]] }
					]
				}
			]
		}
	]
}
]=])
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
