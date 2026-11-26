describe("TestConfigAuto", function()
	local auto = require("Modules.ConfigAutoScan")
	local rules = require("Modules.ConfigAutoRulesBuild")
	local options = require("Modules.ConfigOptions")

	local function recalc()
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")
	end
	local function gems(text, mainGroup)
		build.skillsTab:PasteSocketGroup(text)
		build.mainSocketGroup = mainGroup or #build.skillsTab.socketGroupList
		runCallback("OnFrame")
	end
	local function mods(text)
		build.configTab.input.customMods = text
		recalc()
	end
	local function equip(text, base)
		build.itemsTab:CreateDisplayItemFromRaw("Rarity: RARE\nAuto Source\n" .. (base or "Gold Ring") .. "\nImplicits: 0\n" .. text)
		build.itemsTab:AddDisplayItem()
		runCallback("OnFrame")
	end
	local function option(var)
		for _, entry in ipairs(options) do if entry.var == var then return entry end end
	end
	local function scan(mapping, seconds)
		local list, report = auto.Detect(build, mapping, seconds)
		local found = { }
		for _, entry in ipairs(list) do found[entry.var] = entry end
		return found, list, report
	end
	-- Select exactly the given proposals from a live scan and apply them like the UI does
	local function applyVars(vars, mapping, seconds, choices)
		local found, list = scan(mapping, seconds)
		for _, entry in ipairs(list) do entry.selected = false end
		for _, var in ipairs(vars) do
			local entry = assert(found[var], "no proposal for " .. var)
			if choices and choices[var] ~= nil then
				assert.is_true(auto.Choose(list, entry, choices[var]), var)
			elseif not entry.selected then
				auto.Toggle(list, entry)
			end
		end
		assert.is_nil(auto.SelectionError(build.configTab, list))
		assert.is_true(auto.Apply(build.configTab, list))
		runCallback("OnFrame")
		for _, var in ipairs(vars) do assert.are.equal(found[var].value, build.configTab.input[var], var) end
		return found
	end
	-- Apply, read the native result, undo, and check inputs and the native result are restored
	local function applyAndUndo(vars, read, mapping, seconds, choices)
		local config = build.configTab
		recalc()
		config:ResetUndo()
		local inputs, before = copyTable(config.input), read()
		applyVars(vars, mapping, seconds, choices)
		local after = read()
		config:Undo()
		runCallback("OnFrame")
		assert.are.same(inputs, config.input)
		assert.are.equal(before, read())
		return before, after
	end
	local function output(name)
		return function() return build.calcsTab.mainOutput[name] or 0 end
	end
	local function condition(actor, name)
		return function() return build.calcsTab.mainEnv[actor].modDB:GetCondition(name) == true end
	end

	before_each(function()
		newBuild()
		gems("Fireball 20/0  1\n")
	end)

	it("scans without writing inputs, placeholders, controls, undo, modFlag or the calculation cache", function()
		equip("10% chance to gain a Frenzy Charge on Hit")
		local config = build.configTab
		config.input.enemyIsBoss = "Pinnacle"
		recalc()
		local set = config.configSets[config.activeConfigSetId]
		local inputs, placeholders = copyTable(set.input), copyTable(set.placeholder)
		local modList, env, undo, modFlag = config.modList, build.calcsTab.mainEnv, #config.undo, config.modFlag
		local control = config.varControls.enemyLevel
		local setPlaceholder, writes = control.SetPlaceholder, 0
		control.SetPlaceholder = function(...) writes = writes + 1 return setPlaceholder(...) end
		local cache = GlobalCache.cachedData.CALCULATOR
		local keys = { }
		for key in pairs(cache) do keys[key] = true end
		-- Only the input changes tier, so any control write during the scan would be visible
		config.input.enemyIsBoss = "Uber"
		auto.Detect(build)
		local _, expected = auto.Detect(build, true)
		-- The automatic check steps the same scan over frames; between steps the real cache is in place
		local scan, steps, done, ok, report = auto.StartDetect(build, true), 0
		repeat
			done, ok, _, report = auto.ResumeDetect(scan, -1)
			steps = steps + 1
			assert.are.equal(cache, GlobalCache.cachedData.CALCULATOR)
		until done
		assert.is_true(ok and steps > 1)
		local function values(entries)
			local result = { }
			for _, entry in ipairs(entries) do result[entry.var] = tostring(entry.value) end
			return result
		end
		assert.are.same(values(expected), values(report))
		control.SetPlaceholder = setPlaceholder
		config.input.enemyIsBoss = "Pinnacle"
		assert.are.equal(0, writes)
		assert.are.same(inputs, set.input)
		assert.are.same(placeholders, set.placeholder)
		assert.are.equal(modList, config.modList)
		assert.are.equal(env, build.calcsTab.mainEnv)
		assert.are.equal(undo, #config.undo)
		assert.are.equal(modFlag, config.modFlag)
		assert.are.equal(cache, GlobalCache.cachedData.CALCULATOR)
		for key in pairs(cache) do assert.is_true(keys[key], "scan leaked into the cache: " .. tostring(key)) end
	end)

	it("applies a charge checkbox only together with its estimate, in one undo step", function()
		equip("10% chance to gain a Frenzy Charge on Hit")
		local config = build.configTab
		local found = scan()
		found.useFrenzyCharges.selected = true
		assert.is_false(auto.Apply(config, { found.useFrenzyCharges }))
		assert.is_nil(config.input.useFrenzyCharges)
		local before, after = applyAndUndo({ "useFrenzyCharges", "overrideFrenzyCharges" }, output("FrenzyCharges"))
		assert.is_true(after > before)
	end)

	it("applies a recent Travel Skill condition and raises native damage", function()
		gems("Flame Dash 20/0  1\n", 1)
		mods("32% increased Damage if you've used a Travel Skill Recently")
		local before, after = applyAndUndo({ "conditionUsedTravelSkillRecently" }, output("TotalDPS"))
		assert.is_true(after > before)
	end)

	it("applies enemy Ignited from a real always-Ignite source", function()
		mods("Hits always Ignite\nAdds 23 to 42 Fire Damage against Ignited Enemies")
		local before, after = applyAndUndo({ "conditionEnemyIgnited" }, condition("enemy", "Ignited"))
		assert.is_false(before)
		assert.is_true(after)
	end)

	it("applies the Spectral Wolf count from a real on-kill trigger while mapping", function()
		equip("Trigger Level 10 Summon Spectral Wolf on Kill")
		local before, after = applyAndUndo({ "configSpectralWolfCount" }, function()
			return build.calcsTab.mainEnv.player.modDB:GetMultiplier("SpectralWolfConfig")
		end, true)
		assert.is_true(after > before)
	end)

	it("applies a Balance of Terror self-only curse so the curse no longer reaches the enemy", function()
		gems("Enfeeble 20/0  1\n", 1)
		equip("+40% to Critical Strike Multiplier if you've cast Enfeeble in the past 10 seconds")
		local before, after = applyAndUndo({ "balanceOfTerrorSelfCastEnfeeble" }, condition("enemy", "Cursed"), false, nil, { balanceOfTerrorSelfCastEnfeeble = true })
		assert.is_true(before)
		assert.is_false(after)
	end)

	it("applies enemy Shocked Ground from a real ground source", function()
		equip("Drops Shocked Ground while moving, lasting 2 seconds")
		local before, after = applyAndUndo({ "conditionEnemyOnShockedGround" }, condition("enemy", "OnShockedGround"))
		assert.is_false(before)
		assert.is_true(after)
	end)

	it("applies imported bandit and pantheon choices to native stats", function()
		build.configTab.input.bandit = "Oak"
		build.configTab.input.pantheonMajorGod = "None"
		recalc()
		rules.Quests.Capture(build, { bandit_choice = "Alira", pantheon_major = "Arakaali" }, "Test Character")
		build.Act = 6
		local function banditResist()
			return build.calcsTab.mainEnv.player.modDB:Sum("BASE", { source = "Bandit" }, "ElementalResist")
		end
		local resistBefore = banditResist()
		applyVars({ "bandit", "pantheonMajorGod" })
		assert.are.equal("Alira", build.configTab.input.bandit)
		assert.are.equal("Arakaali", build.configTab.input.pantheonMajorGod)
		assert.is_true(banditResist() > resistBefore)
		assert.is_true(build.calcsTab.mainEnv.player.modDB:Sum("INC", { source = "Pantheon" }, "DamageTakenOverTime") < 0)
	end)

	it("keeps Cruelty at PoB's native default instead of writing an explicit zero", function()
		gems("Fireball 20/0  1\nCruelty 20/0  1\n", 2)
		local config = build.configTab
		local set = config.configSets[config.activeConfigSetId]
		local draft = auto.BuildSetup(build, set, false)
		assert.is_nil(draft.input.overrideCruelty)
		assert.is_nil(draft.placeholder.overrideCruelty)
		set.input.overrideCruelty = 0
		recalc()
		draft = auto.BuildSetup(build, set, false)
		assert.is_nil(draft.input.overrideCruelty)
		assert.are.equal(0, set.input.overrideCruelty)
	end)

	it("reports Onslaught from a Silver Flask and an enemy Blind PoB applies as derived and refuses to write them", function()
		local item = new("Item"):Item("Rarity: NORMAL\nSilver Flask")
		build.itemsTab:AddItem(item, true)
		local slot = build.itemsTab.slots["Flask 1"]
		slot:SetSelItemId(item.id)
		slot.active = true
		build.configTab.input.overrideBuffBlinded = 20
		mods("Nearby Enemies are Blinded\n10% increased Damage against Blinded Enemies")
		assert.is_true(condition("player", "Onslaught")())
		assert.is_true(condition("enemy", "Blinded")())
		local found, _, report = scan()
		for _, var in ipairs({ "buffOnslaught", "conditionEnemyBlinded" }) do
			assert.is_nil(found[var], var)
			local entry
			for _, row in ipairs(report) do if row.var == var then entry = row end end
			assert.is_true(assert(entry, var).derived, var)
			entry.selected = true
			assert.is_false(auto.Apply(build.configTab, { entry }), var)
			assert.is_nil(build.configTab.input[var], var)
		end
		-- Clearing the stale Blind effect still works without the parent checkbox
		local reset = assert(found.overrideBuffBlinded)
		assert.is_nil(reset.requires)
		reset.selected = true
		assert.is_true(auto.Apply(build.configTab, { reset }))
		assert.is_nil(build.configTab.input.overrideBuffBlinded)
	end)

	it("never writes Low Life as a manual checkbox when reservation already causes it", function()
		gems("Pride 20/0  1\nArrogance 20/0  1\n", 1)
		mods("+30% Chance to Block Spell Damage while on Low Life")
		local config = build.configTab
		assert.is_true(condition("player", "LowLife")())
		assert.is_nil(scan().conditionLowLife)
		local draft = auto.BuildSetup(build, config.configSets[config.activeConfigSetId], false)
		assert.is_nil(draft.input.conditionLowLife)
		assert.is_nil(config.input.conditionLowLife)
	end)

	it("does not use a manual checkbox as evidence for itself", function()
		build.configTab.input.buffOnslaught = true
		build.configTab.input.conditionEnemyShocked = true
		recalc()
		local found = scan()
		assert.is_nil(found.buffOnslaught)
		assert.is_nil(found.conditionEnemyShocked)
		assert.is_true(build.configTab.input.buffOnslaught)
	end)

	it("explains a stance choice once and names the stance skill", function()
		gems("Blood and Sand 20/0  1\n", 1)
		local config = build.configTab
		local set = config.configSets[config.activeConfigSetId]
		set.input.bloodSandStance = "SAND"
		recalc()
		local _, _, report = scan()
		auto.RecordSettingChecks(config, set, report)
		local status, _, message = auto.GetSettingCheck(config, "bloodSandStance", false, true)
		assert.are.equal("review", status)
		assert.is_truthy(message:find("Blood and Sand alternates", 1, true))
		local _, count = message:gsub("Choose the stance", "")
		assert.is_true(count <= 1)
	end)

	it("marks a natively invalid setting failed and names the missing requirement", function()
		local config = build.configTab
		config.configSets[config.activeConfigSetId].input.overrideCruelty = 20
		local status, _, message = auto.GetSettingCheck(config, "overrideCruelty", true, true)
		assert.are.equal("failed", status)
		assert.is_truthy(message:find("Cruelty", 1, true))
		assert.is_truthy(auto.GetInvalidSettingReason(config, option("overrideFrenzyCharges")):find("Frenzy", 1, true))
		gems("Fireball 20/0  1\nCruelty 20/0  1\n", 2)
		assert.is_nil(auto.GetInvalidSettingReason(config, option("overrideCruelty")):find("Cruelty", 1, true))
	end)

	describe("generated setups", function()
		local preferences = require("Modules.ConfigAutoModel").Preferences
		local ui = require("Modules.ConfigAutoUI")
		local saved, clock
		local killMods = "33% chance to gain a Frenzy Charge on Kill\nYou gain Onslaught for 2 seconds on Kill\n18% increased Damage if you've Killed Recently"
		-- One frame to rebuild, then enough quiet time for an active setup to catch up
		local function draw()
			build.buildFlag = true
			runCallback("OnFrame")
			clock = clock + ui.refreshDelay
			runCallback("OnFrame")
		end
		local function ring(text)
			local item = new("Item"):Item("Rarity: RARE\nSetup Test\nGold Ring\nImplicits: 0\n" .. text)
			build.itemsTab:AddItem(item, true)
			build.itemsTab.slots["Ring 1"]:SetSelItemId(item.id)
			draw()
		end
		local function setup(index)
			local config = build.configTab
			config.controls.setupActivity:SetSel(index)
			config.controls.autoConfigure:Click()
			draw()
			return config
		end
		before_each(function()
			saved = { autoSave = main.disableDevAutoSave, preferences = main.autoConfigureSettings,
				getTime = _G.GetTime, buildSetup = auto.BuildSetup, saveXML = common.xml.SaveXMLFile }
			clock = 0
			_G.GetTime = function() return clock end
			main.autoConfigureSettings = preferences.Normalize()
			main.disableDevAutoSave = true
			-- The user's settings file is never written
			common.xml.SaveXMLFile = function() return true end
			while main.popups[1] do main:ClosePopup() end
			newBuild()
			gems("Fireball 20/0  1\nArcane Surge 1/0  1\n")
			draw()
		end)
		after_each(function()
			while main.popups[1] do main:ClosePopup() end
			build.abortSave = true
			main.disableDevAutoSave, main.autoConfigureSettings = saved.autoSave, saved.preferences
			_G.GetTime, auto.BuildSetup, common.xml.SaveXMLFile = saved.getTime, saved.buildSetup, saved.saveXML
		end)

		it("keeps the standard configuration form visible beneath the setup row", function()
			local config = setup(1)
			for _, name in ipairs({ "setSelect", "setManage", "search", "toggleConfigs", "sectionAnchor" }) do
				assert.is_true(config.controls[name]:IsShown(), name)
			end
			assert.is_true(config.varControls.enemyLevel:IsShown())
			assert.is_true(config.customSection:IsShown())
			-- A dropdown value too long for the narrow control is named in full on hover
			local boss, drawWidth = config.varControls.enemyIsBoss, _G.DrawStringWidth
			boss:SelByValue("Pinnacle", "val")
			_G.DrawStringWidth = function(height, font, text) return #text * 7 end
			local tooltip = boss:GetProperty("tooltipText")
			boss:SelByValue("None", "val")
			local short = boss:GetProperty("tooltipText")
			_G.DrawStringWidth = drawWidth
			assert.is_truthy(tooltip:find("Guardian/Pinnacle Boss", 1, true))
			assert.is_truthy(tooltip:find(data.enemyIsBossTooltip:sub(1, 20), 1, true))
			assert.is_falsy(short:find("\n^7No", 1, true))
		end)

		it("applies from the setup button and Undo/Redo switches back to the untouched manual set", function()
			local config = build.configTab
			local manual = config.activeConfigSetId
			local original = copyTable(config.configSets[manual].input)
			local surgeBefore = condition("player", "ArcaneSurge")()
			setup(1)
			local generated = config.activeConfigSetId
			assert.are_not.equal(manual, generated)
			assert.is_true(config.input.buffArcaneSurge)
			assert.is_true(condition("player", "ArcaneSurge")())
			assert.are.same(original, config.configSets[manual].input)
			config:Undo()
			draw()
			assert.are.equal(manual, config.activeConfigSetId)
			assert.are.equal(surgeBefore, condition("player", "ArcaneSurge")())
			config:Redo()
			draw()
			assert.are.equal(generated, config.activeConfigSetId)
			assert.is_true(config.input.buffArcaneSurge)
		end)

		it("switches to the activity's own setup, and clearing maps fights regular monsters", function()
			local manual = build.configTab.configSets[build.configTab.activeConfigSetId]
			local original = copyTable(manual.placeholder)
			assert.are.equal(50, original.enemyFireResist)
			local draft = auto.BuildSetup(build, manual, true, main.autoConfigureSettings)
			assert.is_nil(draft.placeholder.enemyFireResist)
			assert.are.same(original, manual.placeholder)

			local config = setup(2)
			local maps = config.configSets[config.activeConfigSetId]
			assert.are.equal("None", maps.input.enemyIsBoss)
			assert.are.same(draft.placeholder, maps.placeholder)
			-- Native default-on checkboxes keep their default without evidence
			for _, option in ipairs(require("Modules.ConfigOptions")) do
				if option.type == "check" and option.defaultState == true then assert.are_not.equal(false, maps.input[option.var], option.var) end
			end
			local mapsResist = build.calcsTab.mainEnv.enemy.modDB:Sum("BASE", nil, "FireResist")
			config.controls.setupActivity:SetSel(1)
			draw()
			assert.are_not.equal(maps, config.configSets[config.activeConfigSetId])
			assert.is_true(build.calcsTab.mainEnv.enemy.modDB:Sum("BASE", nil, "FireResist") > mapsResist)
			-- From the manual set, the dropdown selects an existing setup
			config:SetActiveConfigSet(maps.autoBaseId)
			config.controls.setupActivity:SetSel(2)
			draw()
			assert.are.equal(maps, config.configSets[config.activeConfigSetId])
		end)

		it("loads a generated set as saved without regenerating it or marking the build modified", function()
			-- Augyre's unset rotation must not start on its first entry (Elemental Overload)
			ring(killMods .. "\nEvery 16 seconds you gain Elemental Overload for 8 seconds")
			local config = setup(2)
			local expected = { }
			for _, var in ipairs({ "conditionKilledRecently", "buffArcaneSurge", "conditionHaveAugyre" }) do
				expected[var] = config.input[var]
			end
			assert.is_true(expected.conditionKilledRecently)
			assert.is_nil(expected.conditionHaveAugyre)
			-- A stale false from an older generator is repaired; a recorded manual uncheck stays
			local generated = config.configSets[config.activeConfigSetId]
			generated.input.FlickerStrikeBypassCD = false
			config.autoSetupCache[generated].baseline.input.FlickerStrikeBypassCD = false
			generated.input.raiseSpectreEnableBuffs = false
			local keystones = build.calcsTab.mainEnv.modDB:List(nil, "Keystone")
			local dps = build.calcsTab.mainOutput.TotalDPS
			local xml = build:SaveDB("code")
			local scans = 0
			auto.BuildSetup = function(...) scans = scans + 1 return saved.buildSetup(...) end
			loadBuildFromXML(xml, "Loaded setup")
			config = build.configTab
			local undo = #config.undo
			draw()
			for var, value in pairs(expected) do assert.are.equal(value, config.input[var], var) end
			assert.is_true(config.input.FlickerStrikeBypassCD)
			assert.is_false(config.input.raiseSpectreEnableBuffs)
			assert.are.same(keystones, build.calcsTab.mainEnv.modDB:List(nil, "Keystone"))
			assert.are.equal(dps, build.calcsTab.mainOutput.TotalDPS)
			assert.are.equal(undo, #config.undo)
			assert.is_falsy(config.modFlag)
			assert.are.equal(0, scans)
		end)

		it("checks a loaded setup against a fresh scan in Details without writing it", function()
			ring(killMods)
			local config = setup(2)
			local generated = config.configSets[config.activeConfigSetId]
			-- A value an older generator did not set, so not a manual override
			generated.input.conditionKilledRecently = nil
			config.autoSetupCache[generated].baseline.input.conditionKilledRecently = nil
			loadBuildFromXML(build:SaveDB("code"), "Outdated setup")
			config = build.configTab
			draw()
			local summary = config.controls.setupSummary
			assert.is_truthy(summary:GetProperty("label"):find("Saved setup", 1, true))
			config.controls.setupDetails:Click()
			local popup = main.popups[1]
			local rows = { }
			for _, row in ipairs(popup.controls.list.list) do rows[row.var] = row end
			assert.are.equal("Outdated", rows.conditionKilledRecently.status)
			-- Hovers name the build source, not only the generic question
			assert.is_truthy(rows.buffArcaneSurge.reason:find("Fireball", 1, true))
			assert.is_truthy(popup.controls.intro:GetProperty("label"):find("fresh scan", 1, true))
			assert.is_nil(config.input.conditionKilledRecently)
			main:ClosePopup()
			assert.is_truthy(summary:GetProperty("label"):find("out of date", 1, true))
		end)

		it("keeps manual edits to a generated set as overrides across regeneration and reload", function()
			ring(killMods)
			local config = setup(2)
			assert.is_true(config.input.conditionKilledRecently)
			local edited = 2
			config.input.useFrenzyCharges, config.input.overrideFrenzyCharges = true, edited
			config.input.conditionKilledRecently = nil
			config.input.raiseSpectreEnableBuffs = false
			config:AddUndoState()
			ring(killMods .. "\n+10 to maximum Life")
			assert.are.equal(edited, config.input.overrideFrenzyCharges)
			assert.is_nil(config.input.conditionKilledRecently)
			assert.is_false(config.input.raiseSpectreEnableBuffs)
			loadBuildFromXML(build:SaveDB("code"), "Override round trip")
			config = build.configTab
			draw()
			config.controls.setupDetails:Click()
			assert.is_false(config.autoSetupCache[config.configSets[config.activeConfigSetId]].outdated)
			main:ClosePopup()

			config.input.raiseSpectreEnableBuffs = true
			config:AddUndoState()
			build:SaveDB("code")
			config:Undo()
			assert.is_false(config.input.raiseSpectreEnableBuffs)
			ring(killMods .. "\n+20 to maximum Life")
			assert.are.equal(edited, config.input.overrideFrenzyCharges)
			assert.is_nil(config.input.conditionKilledRecently)
			assert.is_false(config.input.raiseSpectreEnableBuffs)
		end)

		it("persists imported quest evidence only when the build includes a generated set", function()
			rules.Quests.Capture(build, { bandit_choice = "Alira" }, "Imported Character")
			assert.is_nil(build:SaveDB("code"):find("AutoConfigureQuests", 1, true))

			local config = setup(1)
			local generated = config.configSets[config.activeConfigSetId]
			config:SetActiveConfigSet(generated.autoBaseId)
			local xml = build:SaveDB("code")
			assert.is_truthy(xml:find("AutoConfigureQuests", 1, true))
			loadBuildFromXML(xml, "Imported quest evidence")
			assert.are.equal("Alira", build.autoConfigureQuestEvidence.bandit)
		end)

		it("saves and loads a manual config set, including explicit zeros, unchanged", function()
			local config = build.configTab
			config.input.overrideCruelty = 0
			config.input.enemyIsBoss = "Pinnacle"
			config.input.conditionHitRecently = true
			recalc()
			local inputs, dps = copyTable(config.input), build.calcsTab.mainOutput.TotalDPS
			local xml = build:SaveDB("code")
			assert.is_nil(xml:find('name="multiplierMapModEffect"', 1, true))
			loadBuildFromXML(xml, "Manual round trip")
			draw()
			assert.are.same(inputs, build.configTab.input)
			assert.are.equal(dps, build.calcsTab.mainOutput.TotalDPS)
		end)
	end)
end)
