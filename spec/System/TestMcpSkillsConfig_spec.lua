local McpProtocol = LoadModule("Modules/McpProtocol")

local PORT = 49290
local TOKEN = "0123456789abcdef0123456789abcdef"

local protocol

local function request(method, params)
	local message = { jsonrpc = "2.0", id = 1, method = method, params = params }
	local response
	protocol:HandleHttp({
		method = "POST",
		path = "/mcp",
		version = "1.1",
		headers = {
			host = "127.0.0.1:" .. PORT,
			authorization = "Bearer " .. TOKEN,
			["content-type"] = "application/json",
		},
		body = McpProtocol.Encode(message),
	}, function(r)
		response = r
	end)
	assert.is_truthy(response, "no response")
	local body = response.body ~= "" and McpProtocol.Decode(response.body) or nil
	return response.status, body, response
end

local function callTool(name, args, allowError)
	local status, body = request("tools/call", { name = name, arguments = args or McpProtocol.Object() })
	assert.are.equals(200, status)
	assert.is_nil(body.error)
	if body.result.isError and not allowError then
		error(name .. " failed: " .. tostring(body.result.content[1].text), 2)
	end
	return body.result.structuredContent, body.result
end

local function toolError(name, args)
	local _, result = callTool(name, args, true)
	assert.is_true(result.isError, "expected an error from " .. name)
	return result.content[1].text
end

local function findBy(list, key, value)
	for _, entry in ipairs(list) do
		if entry[key] == value then
			return entry
		end
	end
end

describe("MCP skills, config and calcs tools", function()
	before_each(function()
		main.mcpServer.token = TOKEN
		protocol = main.mcpServer:NewProtocol(PORT)
		-- A build an earlier spec changed would be autosaved by Dev Mode when replaced; there is nowhere to save it here.
		build.abortSave = true
		while main.popups[1] do
			main:ClosePopup()
		end
		newBuild()
	end)

	after_each(function()
		-- Dev Mode saves a changed build when the next test replaces it; there is nowhere to save it here.
		build.abortSave = true
		-- No test may leave one of PoB's dialogs open.
		local popup = main.popups[1]
		while main.popups[1] do
			main:ClosePopup()
		end
		assert.is_nil(popup, popup and ("dialog left open: " .. tostring(popup.title)))
	end)

	describe("skills", function()
		it("reports the socket groups and gems as the Skills tab holds them", function()
			build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/3  1\nControlled Destruction 18/0 DISABLED 1\n")
			build.skillsTab:PasteSocketGroup("Label: Second\nArc 20/0  1\n")
			runCallback("OnFrame")
			local skills = callTool("skills_get")
			assert.are.equals(#build.skillsTab.socketGroupList, #skills.groups)
			for index, group in ipairs(build.skillsTab.socketGroupList) do
				local reported = skills.groups[index]
				assert.are.equals(group.displayLabel, reported.label)
				assert.are.equals(#group.gemList, #reported.gems)
				for gemIndex, gem in ipairs(group.gemList) do
					assert.are.equals(gem.gemData.name, reported.gems[gemIndex].name)
					assert.are.equals(gem.level, reported.gems[gemIndex].level)
					assert.are.equals(gem.quality, reported.gems[gemIndex].quality)
					assert.are.equals(gem.enabled, reported.gems[gemIndex].enabled)
				end
			end
			assert.are.equals("Body Armour", skills.groups[1].slot)
			assert.are.equals("support", skills.groups[1].gems[2].type)
			assert.are.equals("active", skills.groups[1].gems[1].type)
			assert.are.equals("Second", skills.groups[2].label)
			assert.are.equals(build.mainSocketGroup, skills.mainSkill.group)
			assert.are.equals("Fireball", skills.mainSkill.activeSkill)
			assert.are.equals(1, #skills.skillSets)
			-- One group with PoB's own details.
			local one = callTool("skills_get", { group = "Second" })
			assert.are.equals(1, #one.groups)
			assert.are.equals(2, one.groups[1].index)
			assert.is_truthy(#one.groups[1].details > 0)
		end)

		it("adds a pasted group and changes gem level and quality as the gem controls do", function()
			local added = callTool("skills_edit", { action = "add_group", text = "Slot: Body Armour\nFireball 1/0 1\n" })
			assert.are.equals(1, #build.skillsTab.socketGroupList)
			assert.are.equals("Fireball", added.group.gems[1].name)
			local hitBefore = build.calcsTab.mainOutput.AverageHit
			assert.is_truthy(hitBefore > 0)
			local edited = callTool("skills_edit", { action = "edit_gem", group = 1, gem = "Fireball", level = 20, quality = 20 })
			local gem = build.skillsTab.socketGroupList[1].gemList[1]
			assert.are.equals(20, gem.level)
			assert.are.equals(20, gem.quality)
			assert.are.equals(20, edited.group.gems[1].level)
			assert.is_truthy(build.calcsTab.mainOutput.AverageHit > hitBefore)
			assert.is_truthy(#edited.statChanges > 0)
			assert.is_true(build:HasUnsavedChanges())
			-- PoB matches gem names as it does for pasted gems.
			local message = toolError("skills_edit", { action = "add_group", text = "Fireball twenty\n" })
			assert.is_truthy(message:find("copy/paste format", 1, true))
		end)

		it("adds, disables and removes gems and groups", function()
			callTool("skills_edit", { action = "add_group", text = "Fireball 20/0 1\n" })
			local result = callTool("skills_edit", { action = "add_gem", group = 1, gem = "Spell Echo Support", quality = 10 })
			local group = build.skillsTab.socketGroupList[1]
			assert.are.equals(2, #group.gemList)
			assert.are.equals("Spell Echo", group.gemList[2].gemData.name)
			assert.are.equals(10, group.gemList[2].quality)
			assert.are.equals(2, result.group.gems[2].index)
			callTool("skills_edit", { action = "edit_gem", group = "Fireball", gem = 2, enabled = false })
			assert.is_false(group.gemList[2].enabled)
			callTool("skills_edit", { action = "remove_gem", group = 1, gem = "Spell Echo" })
			assert.are.equals(1, #group.gemList)
			callTool("skills_edit", { action = "edit_group", group = 1, enabled = false, label = "Main", include_in_full_dps = true })
			assert.is_false(group.enabled)
			assert.is_true(group.includeInFullDPS)
			assert.are.equals("Main", group.label)
			callTool("skills_edit", { action = "edit_group", group = 1, slot = "Helmet" })
			assert.are.equals("Helmet", group.slot)
			assert.is_truthy(toolError("skills_edit", { action = "edit_group", group = 1, slot = "Pocket" }):find("Body Armour", 1, true))
			assert.is_truthy(toolError("skills_edit", { action = "add_gem", group = 1, gem = "No Such Gem At All" }):find("Unrecognised", 1, true))
			callTool("skills_edit", { action = "remove_group", group = "Main" })
			assert.are.equals(0, #build.skillsTab.socketGroupList)
		end)

		it("selects the main skill through the side bar's controls", function()
			build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
			build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
			runCallback("OnFrame")
			assert.are.equals(1, build.mainSocketGroup)
			local result = callTool("skills_edit", { action = "set_main", group = "Arc" })
			assert.are.equals(2, build.mainSocketGroup)
			assert.are.equals("Arc", result.mainSkill.activeSkill)
			assert.are.equals("Arc", build.calcsTab.mainEnv.player.mainSkill.activeEffect.grantedEffect.name)
			assert.is_truthy(toolError("skills_edit", { action = "set_main", skill_part = 2 }):find("no skill part", 1, true))
		end)

		it("manages skill sets with the skill set list and its dialogs", function()
			build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
			runCallback("OnFrame")
			local created = callTool("skills_edit", { action = "copy_set", set = "Default", title = "Copy" })
			assert.are.equals(2, #build.skillsTab.skillSetOrderList)
			assert.are.equals("Copy", build.skillsTab.skillSets[created.skillSet.id].title)
			callTool("skills_edit", { action = "select_set", set = "Copy" })
			assert.are.equals(created.skillSet.id, build.skillsTab.activeSkillSetId)
			assert.are.equals(1, #build.skillsTab.socketGroupList)
			callTool("skills_edit", { action = "new_set", title = "Empty" })
			assert.are.equals(3, #build.skillsTab.skillSetOrderList)
			callTool("skills_edit", { action = "delete_set", set = "Copy" })
			assert.are.equals(2, #build.skillsTab.skillSetOrderList)
			assert.is_nil(build.skillsTab.skillSets[created.skillSet.id])
		end)

		it("sets the spectres as the spectre library does", function()
			local skills = callTool("skills_get", { spectre_search = "a" })
			assert.is_truthy(skills.spectreLibrary.total > 0)
			local spectre = skills.spectreLibrary.results[1]
			local result = callTool("skills_edit", { action = "set_spectres", add_spectres = { spectre.id } })
			assert.are.same({ spectre.id }, build.spectreList)
			assert.are.equals(spectre.id, result.spectres[1].id)
			callTool("skills_edit", { action = "set_spectres", remove_spectres = { spectre.id } })
			assert.are.equals(0, #build.spectreList)
		end)

		it("ranks supports as the gem selector's DPS sort and leaves the build unchanged", function()
			build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
			runCallback("OnFrame")
			build:ResetModFlags()
			local xmlBefore = build:SaveDB("code")
			local dpsBefore = build.calcsTab.mainOutput.CombinedDPS
			local ranked = callTool("skills_rank_supports", { group = 1, search = "fire", limit = 50 })
			assert.are.equals("CombinedDPS", ranked.stat.field)
			assert.is_truthy(#ranked.gems > 1)
			for i = 2, #ranked.gems do
				if ranked.gems[i - 1].canSupport == ranked.gems[i].canSupport then
					assert.is_truthy(ranked.gems[i - 1].value >= ranked.gems[i].value)
				end
			end
			assert.is_truthy(ranked.gems[1].change > 0)
			assert.are.equals(xmlBefore, build:SaveDB("code"))
			assert.are.equals(1, #build.skillsTab.socketGroupList[1].gemList)
			build:ProcessBuildFlag()
			assert.are.equals(dpsBefore, build.calcsTab.mainOutput.CombinedDPS)
			assert.is_false(build:HasUnsavedChanges())
		end)
	end)

	describe("config", function()
		it("lists the options that differ from their defaults, and changes them", function()
			local before = callTool("config_get")
			assert.is_nil(findBy(before.options, "var", "usePowerCharges"))
			local result = callTool("config_set", { options = { usePowerCharges = true, ["Is the enemy a Boss?"] = "Standard Boss", enemyFireResist = 30 } })
			assert.are.equals(3, #result.applied)
			assert.are.equals(0, #result.rejected)
			assert.is_true(build.configTab.input.usePowerCharges)
			assert.are.equals("Boss", build.configTab.input.enemyIsBoss)
			assert.are.equals(30, build.configTab.input.enemyFireResist)
			local after = callTool("config_get")
			assert.is_true(findBy(after.options, "var", "usePowerCharges").value)
			assert.are.equals("Standard Boss", findBy(after.options, "var", "enemyIsBoss").value)
			assert.are.equals(#before.options + 3, #after.options)
			local searched = callTool("config_get", { search = "bandit" })
			local bandit = findBy(searched.options, "var", "bandit")
			assert.are.equals("Kill all", bandit.value)
			assert.is_truthy(#bandit.choices >= 4)
			callTool("config_set", { reset = { "usePowerCharges", "enemyIsBoss" } })
			assert.is_false(build.configTab.input.usePowerCharges)
			assert.are.equals("Pinnacle", build.configTab.input.enemyIsBoss)
		end)

		it("rejects unknown options and invalid values with the valid choices", function()
			local result = callTool("config_set", { options = { enemyIsBoss = "Nope", usePowerCharges = true, noSuchOption = 1, enemyLevel = "high" } })
			assert.are.equals(1, #result.applied)
			assert.are.equals(3, #result.rejected)
			local boss = findBy(result.rejected, "option", "enemyIsBoss")
			assert.is_truthy(boss.choices)
			assert.is_truthy(isValueInArray(boss.choices, "Standard Boss"))
			assert.is_truthy(findBy(result.rejected, "option", "noSuchOption"))
			assert.is_truthy(findBy(result.rejected, "option", "enemyLevel").reason:find("number", 1, true))
			local message = toolError("config_set", { options = { bandit = "Help Nobody" } })
			assert.is_truthy(message:find("Help Oak", 1, true))
		end)

		it("creates, selects and deletes config sets with the config set list", function()
			local created = callTool("config_set", { set_action = "new", title = "Bossing" })
			assert.are.equals(2, #build.configTab.configSetOrderList)
			local id = created.configSetChange.id
			callTool("config_set", { set_action = "select", set = "Bossing", options = { usePowerCharges = true } })
			assert.are.equals(id, build.configTab.activeConfigSetId)
			assert.is_true(build.configTab.configSets[id].input.usePowerCharges)
			assert.is_falsy(build.configTab.configSets[1].input.usePowerCharges)
			callTool("config_set", { set_action = "delete", set = id })
			assert.are.equals(1, #build.configTab.configSetOrderList)
			assert.are.equals(1, build.configTab.activeConfigSetId)
		end)

		it("appends custom modifiers and reports lines PoB does not recognise", function()
			local lifeBefore = build.calcsTab.mainOutput.Life
			local result = callTool("config_set", { custom_mods = "+100 to maximum Life" })
			assert.are.equals(lifeBefore + 100, build.calcsTab.mainOutput.Life)
			assert.is_nil(result.customModifiers.unrecognised)
			result = callTool("config_set", { custom_mods = "This is not a modifier" })
			assert.are.equals("+100 to maximum Life\nThis is not a modifier", build.configTab.configSets[1].customModsList[1].text)
			assert.are.same({ "This is not a modifier" }, result.customModifiers.unrecognised)
			local config = callTool("config_get")
			assert.are.same({ "This is not a modifier" }, config.customModifiers[1].unrecognised)
			callTool("config_set", { custom_mods = "", custom_mods_mode = "replace" })
			assert.are.equals(lifeBefore, build.calcsTab.mainOutput.Life)
		end)
	end)

	describe("calcs", function()
		it("returns PoB's breakdown of a stat and puts the Calcs tab back", function()
			build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
			build.skillsTab:PasteSocketGroup("Arc 20/0  1\n")
			-- PoB only breaks Life down when something increases it.
			build.configTab.configSets[1].customModsList[1].text = "10% increased maximum Life"
			build.configTab:BuildModList()
			build.buildFlag = true
			runCallback("OnFrame")
			local inputBefore = copyTable(build.calcsTab.input)
			local result = callTool("calcs_breakdown", { stat = "Life" })
			local lines = result.breakdown[1].lines
			assert.is_truthy(lines and #lines > 0)
			local base = callTool("calcs_breakdown", { stat = "Total Base", section = "Life" })
			local sourceTable = base.breakdown[1]
			assert.are.equals("table", sourceTable.type)
			assert.is_truthy(isValueInArray(sourceTable.columns, "Source"))
			assert.is_truthy(#sourceTable.rows > 0)
			assert.are.equals("Life", result.cell.section)
			assert.are.equals("Life", result.cell.output)
			local rows = 0
			for _, section in ipairs(result.breakdown) do
				rows = rows + #(section.rows or section.lines or { })
			end
			assert.is_truthy(rows > 0)
			local listed = callTool("calcs_breakdown", { filter = "total", section = "Life" })
			assert.is_truthy(#listed.cells >= 1)
			assert.are.same({ "Life" }, listed.sections)
			for _, cell in ipairs(listed.cells) do
				assert.are.equals("Life", cell.section)
			end
			assert.is_truthy(findBy(listed.cells, "id", result.cell.id))
			-- Another skill and mode, then the tab is as it was.
			local other = callTool("calcs_breakdown", { stat = "AverageHit", group = 2, mode = "UNBUFFED" })
			assert.are.equals("Arc", other.view.skill)
			assert.are.equals("UNBUFFED", other.view.mode)
			assert.are.same(inputBefore, build.calcsTab.input)
			assert.are.equals("Fireball", build.calcsTab.calcsEnv.player.mainSkill.activeEffect.grantedEffect.name)
			assert.are.equals(build.calcsTab.mainOutput.Life, build.calcsTab.calcsOutput.Life)
			assert.is_truthy(toolError("calcs_breakdown", { stat = "No Such Stat Here" }):find("No Calcs tab cell", 1, true))
		end)
	end)
end)
