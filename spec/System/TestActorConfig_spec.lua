describe("Player and mercenary configuration", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local selectScionLuminary = MercenaryTest.selectScionLuminary
	local allocate = MercenaryTest.allocate
	local calculateBuild = MercenaryTest.calculateBuild
	local function configureMercenary()
		allocate("Noble Blood")
		local profile = build.mercenaryTab.profile
		profile.classId = "MeleeAOEMarauder"
		profile.buildId = "MeleeAOEMarauderFireSlam"
		profile.foundAreaLevel = 68
		profile.mainSkillId = "TectonicSlamFireMercenary"
		profile.skills = { { id = "TectonicSlamFireMercenary", enabled = true, supports = { } } }
		build.mercenaryTab:Changed()
		build.mercenaryTab:GetItemSet(true)
	end

	local function envMercenarySkillDist(env)
		return assert(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n")).mainSkill.skillCfg.skillDist
	end

	local function envMercenaryDamageMore(env)
		local skill = assert(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n")).mainSkill
		return skill.skillModList:More(skill.skillCfg, "Damage")
	end

	local function actorConfig()
		local configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		return configSet
	end

	local function calculateWithoutConfigRebuild()
		build.spec.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		runCallback("OnFrame")
		return build.calcsTab.mainEnv
	end

	before_each(function()
		newBuild()
		selectScionLuminary()
		configureMercenary()
	end)

	it("rebuilds actor configuration when a Mercenary is hired", function()
		newBuild()
		selectScionLuminary()
		local configSet = actorConfig()
		configSet.actors.mercenary.input.usePowerCharges = true
		build.configTab:BuildModList()

		configureMercenary()
		local env = calculateWithoutConfigRebuild()
		local mercenary = assert(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_true(mercenary.modDB:Flag(nil, "UsePowerCharges"))
	end)

	it("restores player source configuration when a Mercenary is removed", function()
		local configSet = actorConfig()
		configSet.input.conditionEnemyChilledByYourHits = true
		configSet.customModsList[1].text = "Enemies Chilled by your Hits are Shocked"
		build.configTab:BuildModList()
		local hired = calculateWithoutConfigRebuild()
		assert.is_true(hired.enemyDB:GetCondition("Shocked") or hired.enemyDB:Flag(nil, "Condition:Shocked"))

		build.mercenaryTab.profile.buildId = nil
		build.mercenaryTab.profile.classId = nil
		build.mercenaryTab.profile.mainSkillId = nil
		build.mercenaryTab.profile.skills = { }
		build.mercenaryTab:Changed()
		local unhired = calculateWithoutConfigRebuild()
		assert.is_nil(unhired.mercenary)
		assert.is_true(unhired.enemyDB:GetCondition("Shocked") or unhired.enemyDB:Flag(nil, "Condition:Shocked"))
	end)

	it("scopes shared encounter config vs actor combat and custom mods", function()
		build.configTab.input.PvpScaling = true
		local env = calculateBuild()
		assert.is_true(env.player.modDB:Flag(nil, "HasPvpScaling"))
		assert.is_true(env.mercenary.modDB:Flag(nil, "HasPvpScaling"))

		local configSet = actorConfig()
		configSet.customModsList[1].text = "100000% increased Accuracy Rating"
		env = calculateBuild()
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_true(env.player.modDB:Sum("INC", nil, "Accuracy") >= 100000)
		assert.is_true(env.mercenary.modDB:Sum("INC", nil, "Accuracy") < 100000)

		configSet.customModsList[1].text = ""
		configSet.actors.mercenary.customModsList[1].text = "100000% increased Accuracy Rating"
		env = calculateBuild()
		assert.is_true(env.mercenary.modDB:Sum("INC", nil, "Accuracy") >= 100000)
		assert.is_true(env.player.modDB:Sum("INC", nil, "Accuracy") < 100000)

		configSet.actors.mercenary.customModsList[1].text = ""
		build.configTab.input.usePowerCharges = true
		env = calculateBuild()
		assert.is_true(env.player.modDB:Flag(nil, "UsePowerCharges"))
		assert.is_not_true(env.mercenary.modDB:Flag(nil, "UsePowerCharges"))

		build.configTab.input.usePowerCharges = nil
		configSet.actors.mercenary.input.usePowerCharges = true
		env = calculateBuild()
		assert.is_true(env.mercenary.modDB:Flag(nil, "UsePowerCharges"))
		assert.is_not_true(env.player.modDB:Flag(nil, "UsePowerCharges"))
	end)

	it("Config UI writes and hides against the viewed actor without stealing Items comparison", function()
		local MercenaryTools = require("Modules.MercenaryTools")
		local itemsTab = build.itemsTab
		local configTab = build.configTab
		local configSet = actorConfig()
		configTab:SetViewActor("mercenary")
		configTab:SetConfigValue("usePowerCharges", true)
		assert.is_true(configSet.actors.mercenary.input.usePowerCharges)
		assert.is_not_true(configSet.input.usePowerCharges)
		assert.is_not_true(configTab.input.usePowerCharges)
		configTab:SetViewActor("player")
		configTab:SetConfigValue("usePowerCharges", true)
		assert.is_true(configSet.input.usePowerCharges)

		configTab:SetViewActor("mercenary")
		configTab:SetConfigValue("minionsConditionFullLife", true)
		assert.is_true(configSet.actors.mercenary.input.minionsConditionFullLife)
		assert.is_not_true(configSet.input.minionsConditionFullLife)
		configTab:SetViewActor("player")
		configTab:SetConfigValue("minionsConditionFullLife", true)
		assert.is_true(configSet.input.minionsConditionFullLife)
		assert.is_true(configSet.actors.mercenary.input.minionsConditionFullLife)

		configTab:SetConfigValue("pantheonMajorGod", "TheBrineKing")
		configTab:SetConfigValue("pantheonMinorGod", "Gruthkul")
		configTab:SetConfigValue("bandit", "Alira")
		configTab:SetViewActor("player")
		assert.is_true(configTab.varControls.pantheonMajorGod.shown())
		assert.is_true(configTab.varControls.bandit.shown())
		configTab:SetViewActor("mercenary")
		assert.is_false(configTab.varControls.pantheonMajorGod.shown())
		assert.is_false(configTab.varControls.pantheonMinorGod.shown())
		assert.is_false(configTab.varControls.bandit.shown())
		assert.is_false(configTab.varControls.resistancePenalty.shown())

		local playerSetId = itemsTab.activeItemSetId
		local altPlayer = itemsTab:NewItemSet()
		altPlayer.title = "Config Wear"
		table.insert(itemsTab.itemSetOrderList, altPlayer.id)
		assert(itemsTab:SetViewItemSet(playerSetId, "PLAYER"))
		configTab:SetViewActor("player")
		configTab:UpdateActorItemSetSelect()
		configTab.controls.itemSetSelect.selFunc(nil, { id = altPlayer.id })
		assert.are.equal(altPlayer.id, itemsTab.activeItemSetId)
		assert.are.equal(playerSetId, itemsTab.viewItemSetId)
		assert.are.equal("PLAYER", MercenaryTools.comparisonActorForItemSet(playerSetId, itemsTab))

		itemsTab:SetActiveItemSet(playerSetId)
		local viewItemSetId = itemsTab.viewItemSetId
		configTab:SetViewActor("mercenary")
		configTab:UpdateActorItemSetSelect()
		configTab.controls.itemSetSelect.selFunc(nil, { id = playerSetId })
		assert.are.equal(playerSetId, build.mercenaryTab.itemSetId)
		assert.are.equal(viewItemSetId, itemsTab.viewItemSetId)
		assert.are.equal("PLAYER", MercenaryTools.comparisonActorForItemSet(playerSetId, itemsTab))
	end)

	it("config sets apply per-actor item sets without hijacking Items view", function()
		local itemsTab = build.itemsTab
		local configTab = build.configTab
		local originalPlayerId = itemsTab.activeItemSetId
		local originalMercId = build.mercenaryTab.itemSetId
		local mapping = actorConfig()

		local altPlayer = itemsTab:NewItemSet()
		altPlayer.title = "Bossing"
		table.insert(itemsTab.itemSetOrderList, altPlayer.id)
		local altMerc = itemsTab:NewItemSet()
		altMerc.title = "Merc Bossing"
		table.insert(itemsTab.itemSetOrderList, altMerc.id)
		local bossing = configTab:NewConfigSet()
		table.insert(configTab.configSetOrderList, bossing.id)
		configTab:EnsureActorConfig(bossing)
		bossing.actors.player.itemSetId = altPlayer.id
		bossing.actors.mercenary.itemSetId = altMerc.id

		configTab:SetActiveConfigSet(bossing.id)
		assert.are.equal(altPlayer.id, itemsTab.activeItemSetId)
		assert.are.equal(altMerc.id, build.mercenaryTab.itemSetId)
		assert.are.equal(altPlayer.id, itemsTab.viewItemSetId)
		assert.are.equal(originalPlayerId, mapping.actors.player.itemSetId)
		assert.are.equal(originalMercId, mapping.actors.mercenary.itemSetId)
		configTab:SetActiveConfigSet(mapping.id)
		assert.are.equal(originalPlayerId, itemsTab.activeItemSetId)
		assert.are.equal(originalMercId, build.mercenaryTab.itemSetId)

		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		assert(itemsTab:SetViewItemSet(mercSet.id, "MERCENARY"))
		configTab:ApplyActorItemSets()
		assert.are.equal(originalPlayerId, itemsTab.activeItemSetId)
		assert.are.equal(mercSet.id, itemsTab.viewItemSetId)
		assert.are.equal("MERCENARY", itemsTab.viewComparisonActor)

		assert(build.mercenaryTab:SetItemSet(originalPlayerId, false))
		assert(itemsTab:SetViewItemSet(originalPlayerId, "MERCENARY"))
		configTab:ApplyActorItemSets()
		assert.are.equal("MERCENARY", itemsTab.viewComparisonActor)
		assert.are.equal(originalPlayerId, build.mercenaryTab.itemSetId)

		configTab:AddUndoState()
		altPlayer = itemsTab:NewItemSet()
		table.insert(itemsTab.itemSetOrderList, altPlayer.id)
		configTab.controls.itemSetSelect.selFunc(nil, { id = altPlayer.id })
		assert.are.equal(altPlayer.id, itemsTab.activeItemSetId)
		configTab:Undo()
		assert.are.equal(originalPlayerId, itemsTab.activeItemSetId)
		assert.are.equal(originalPlayerId, configTab.configSets[configTab.activeConfigSetId].actors.player.itemSetId)

		local configSet = actorConfig()
		configSet.actors.player.itemSetId = 9999
		configTab:ApplyActorItemSets()
		assert.is_nil(configSet.actors.player.itemSetId)
		assert.are.equal(originalPlayerId, itemsTab.activeItemSetId)

		assert(build.mercenaryTab:SetItemSet(build.itemsTab.activeItemSetId, false))
		newBuild()
		assert.is_nil(build.mercenaryTab.itemSetId)
	end)

	it("round-trips actor config XML and treats stored itemSetIds as source of truth", function()
		local configTab = build.configTab
		local configSet = actorConfig()
		configSet.customModsList[1].text = "10% increased Damage"
		configSet.actors.mercenary.customModsList[1].text = "20% increased Damage"
		configSet.actors.mercenary.input.usePowerCharges = true
		configTab.input.enemyIsBoss = "Uber"
		local xml = { elem = "Config" }
		configTab:Save(xml)
		local actorIds, mercenaryMods, sharedBoss = { }, nil, nil
		for _, child in ipairs(xml[1]) do
			if child.elem == "Actor" then
				actorIds[child.attrib.id] = child
				if child.attrib.id == "mercenary" then
					for _, grand in ipairs(child) do
						if grand.elem == "CustomModifierBlock" then mercenaryMods = grand[1] end
					end
				end
			elseif child.elem == "Input" and child.attrib.name == "enemyIsBoss" then
				sharedBoss = child.attrib.string
			end
		end
		assert.is_not_nil(actorIds.player)
		assert.is_not_nil(actorIds.mercenary)
		assert.are.equal("20% increased Damage", mercenaryMods)
		assert.are.equal("Uber", sharedBoss)

		newBuild()
		selectScionLuminary()
		configureMercenary()
		build.configTab:Load(xml, "actor-config.xml")
		build.configTab:PostLoad()
		local loaded = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(loaded)
		assert.are.equal("Uber", loaded.input.enemyIsBoss)
		assert.is_true(loaded.actors.mercenary.input.usePowerCharges)
		assert.are.equal("20% increased Damage", loaded.actors.mercenary.customModsList[1].text)

		local itemsTab = build.itemsTab
		local liveMercenaryId = build.mercenaryTab.itemSetId
		build.configTab:Load({
			elem = "Config",
			attrib = { activeConfigSet = "1" },
			{
				elem = "ConfigSet",
				attrib = { id = "1", title = "Mapping" },
				{ elem = "Actor", attrib = { id = "player" } },
				{ elem = "Actor", attrib = { id = "mercenary" } },
			},
		}, "no-merc-itemset.xml")
		build.configTab:PostLoad()
		local mapping = build.configTab.configSets[1]
		build.configTab:EnsureActorConfig(mapping)
		assert.is_nil(mapping.actors.mercenary.itemSetId)
		assert.are.equal(liveMercenaryId, build.mercenaryTab.itemSetId)

		local mappingSet = itemsTab.activeItemSetId
		local bossingSet = itemsTab:NewItemSet()
		bossingSet.title = "Boss Gear"
		table.insert(itemsTab.itemSetOrderList, bossingSet.id)
		build.configTab:Load({
			elem = "Config",
			attrib = { activeConfigSet = "1" },
			{
				elem = "ConfigSet",
				attrib = { id = "1", title = "Mapping" },
				{ elem = "Actor", attrib = { id = "player", itemSetId = tostring(mappingSet) } },
				{ elem = "Actor", attrib = { id = "mercenary" } },
			},
			{
				elem = "ConfigSet",
				attrib = { id = "2", title = "Bossing" },
				{ elem = "Actor", attrib = { id = "player", itemSetId = tostring(bossingSet.id) } },
				{ elem = "Actor", attrib = { id = "mercenary" } },
			},
		}, "actor-ids.xml")
		itemsTab.skipConfigItemSetSync = true
		itemsTab:SetActiveItemSet(mappingSet)
		itemsTab.skipConfigItemSetSync = false
		build.configTab:PostLoad()
		assert.are.equal(mappingSet, build.configTab.configSets[1].actors.player.itemSetId)
		assert.are.equal(bossingSet.id, build.configTab.configSets[2].actors.player.itemSetId)
		build.configTab:SetActiveConfigSet(2)
		assert.are.equal(bossingSet.id, itemsTab.activeItemSetId)
	end)

	it("keeps Mercenary melee distance independent of the player", function()
		local configTab = build.configTab
		local configSet = actorConfig()
		assert.are.equal(15, configSet.actors.mercenary.placeholder.meleeDistance)
		assert.are.equal(40, configSet.actors.mercenary.placeholder.projectileDistance)
		assert.are.equal(15, envMercenarySkillDist(calculateBuild()))

		configSet.input.meleeDistance = 1
		configSet.actors.mercenary.input.meleeDistance = 40
		assert.are.equal(40, envMercenarySkillDist(calculateBuild()))
		configSet.input.meleeDistance = 40
		configSet.actors.mercenary.input.meleeDistance = 1
		assert.are.equal(1, envMercenarySkillDist(calculateBuild()))

		configSet.placeholder.meleeDistance = 15
		configSet.actors.mercenary.placeholder.meleeDistance = 7
		configTab:SetViewActor("player")
		assert.are.equal(15, configTab:GetDefaultState("meleeDistance"))
		configTab:SetViewActor("mercenary")
		assert.are.equal(7, configTab:GetDefaultState("meleeDistance"))
		configTab:SetViewActor("player")
		assert.are.equal(15, configTab:GetDefaultState("meleeDistance"))
		assert.are.equal(7, configSet.actors.mercenary.placeholder.meleeDistance)

		configSet.actors.mercenary.input.meleeDistance = nil
		configSet.actors.mercenary.customModsList[1].text = "Deal up to 15% more Melee Damage to Enemies, based on proximity"
		configSet.input.meleeDistance = 40
		local atDefault = envMercenaryDamageMore(calculateBuild())
		configSet.actors.mercenary.input.meleeDistance = 40
		local atForty = envMercenaryDamageMore(calculateBuild())
		assert.is_true(atDefault > atForty)
		configSet.actors.mercenary.input.meleeDistance = 15
		configSet.input.meleeDistance = 1
		assert.are.near(atDefault, envMercenaryDamageMore(calculateBuild()), 10 ^ -9)

		configSet.actors.mercenary.placeholder.meleeDistance = 15
		configSet.actors.mercenary.input.meleeDistance = 15
		local xml = { elem = "Config" }
		configTab:Save(xml)
		local saved
		for _, child in ipairs(xml[1]) do
			if child.elem == "Actor" and child.attrib.id == "mercenary" then
				for _, grand in ipairs(child) do
					if grand.elem == "Input" and grand.attrib.name == "meleeDistance" then
						saved = tonumber(grand.attrib.number)
					end
				end
			end
		end
		assert.is_nil(saved)
	end)

	it("shows source-owned enemy configuration only for the actor that uses it", function()
		local configTab = build.configTab
		local configSet = actorConfig()
		local control = assert(configTab.varControls.conditionEnemyChilledByYourHits)
		local chilledByHitsMod = "Enemies Chilled by your Hits are Shocked"
		local function assertShownForActor(playerShown, mercenaryShown)
			configTab:SetViewActor("player")
			assert.are.equal(playerShown, control.shown())
			configTab:SetViewActor("mercenary")
			assert.are.equal(mercenaryShown, control.shown())
		end

		configSet.customModsList[1].text = chilledByHitsMod
		local env = calculateBuild()
		assert.is_not_nil(env.actorUsage.player.enemyConditions.ChilledByYourHits)
		assert.is_nil(env.actorUsage.mercenary.enemyConditions.ChilledByYourHits)
		assertShownForActor(true, false)

		configSet.customModsList[1].text = ""
		configSet.actors.mercenary.customModsList[1].text = chilledByHitsMod
		env = calculateBuild()
		assert.is_nil(env.actorUsage.player.enemyConditions.ChilledByYourHits)
		assert.is_not_nil(env.actorUsage.mercenary.enemyConditions.ChilledByYourHits)
		assertShownForActor(false, true)
	end)

	it("keeps by-you ailment conditions source-owned", function()
		local chilledByHitsMod = "Enemies Chilled by your Hits are Shocked"
		local frozenByYouMod = "Enemies permanently take 5% increased Damage for each second they've ever been Frozen by you, up to a maximum of 50%"
		local ignitedByYouMod = "Enemies Ignited by you take 20% increased Damage"
		local curseByYouMod = "Enemies you Curse take 20% increased Damage"
		local function enemyShocked(env)
			return env.enemyDB:GetCondition("Shocked") or env.enemyDB:Flag(nil, "Condition:Shocked")
		end
		local function enemyDamageTaken(env)
			return env.enemyDB:Sum("INC", nil, "DamageTaken")
		end
		local function setActorMod(owner, text)
			local configSet = actorConfig()
			if owner == "PLAYER" then
				configSet.customModsList[1].text = text
			else
				configSet.actors.mercenary.customModsList[1].text = text
			end
		end
		local function setActorInput(owner, key, value)
			local configSet = actorConfig()
			if owner == "PLAYER" then
				configSet.input[key] = value
			else
				configSet.actors.mercenary.input[key] = value
			end
		end

		for _, case in ipairs({
			{ source = "PLAYER", target = "MERCENARY", applies = false },
			{ source = "MERCENARY", target = "MERCENARY", applies = true },
			{ source = "MERCENARY", target = "PLAYER", applies = false },
			{ source = "PLAYER", target = "PLAYER", applies = true },
		}) do
			newBuild()
			selectScionLuminary()
			configureMercenary()
			setActorInput(case.source, "conditionEnemyChilledByYourHits", true)
			setActorMod(case.target, chilledByHitsMod)
			local env = calculateBuild()
			assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
			assert.are.equal(case.applies, not not enemyShocked(env), case.source.." -> "..case.target)
			if case.source == "PLAYER" and case.target == "MERCENARY" then
				assert.is_true(env.enemyDB:GetCondition("Chilled") or env.enemyDB:Flag(nil, "Condition:Chilled"))
			end
		end

		for _, case in ipairs({
			{ source = "PLAYER", target = "MERCENARY", delta = 0 },
			{ source = "MERCENARY", target = "MERCENARY", delta = 50 },
			{ source = "MERCENARY", target = "PLAYER", delta = 0 },
			{ source = "PLAYER", target = "PLAYER", delta = 50 },
		}) do
			newBuild()
			selectScionLuminary()
			configureMercenary()
			local baseline = enemyDamageTaken(calculateBuild())
			setActorInput(case.source, "multiplierFrozenByYouSeconds", 10)
			setActorMod(case.target, frozenByYouMod)
			local env = calculateBuild()
			assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
			assert.are.equal(case.delta, enemyDamageTaken(env) - baseline, case.source.." frozen -> "..case.target)
		end

		for _, case in ipairs({
			{ key = "conditionEnemyIgnited", mod = ignitedByYouMod, owner = "MERCENARY", delta = 0 },
			{ key = "conditionEnemyShocked", mod = "Enemies Shocked by you take 20% increased Damage", owner = "MERCENARY", delta = 0 },
			{ key = "conditionEnemyIgnited", mod = ignitedByYouMod, owner = "PLAYER", delta = 20 },
		}) do
			newBuild()
			selectScionLuminary()
			configureMercenary()
			local configSet = actorConfig()
			configSet.input[case.key] = true
			local baseline = enemyDamageTaken(calculateBuild())
			setActorMod(case.owner, case.mod)
			local env = calculateBuild()
			assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
			assert.are.equal(case.delta, enemyDamageTaken(env) - baseline, case.mod)
		end

		newBuild()
		selectScionLuminary()
		configureMercenary()
		local configSet = actorConfig()
		configSet.customModsList[1].text = curseByYouMod
		local baseline = enemyDamageTaken(calculateBuild())
		assert.is_not_true(configSet.input.conditionEnemyCursed)
		build.skillsTab:PasteSocketGroup("Despair 20/0  1")
		local env = calculateBuild()
		assert.is_true(env.enemy.modDB.conditions.Cursed)
		assert.are.equal(20, enemyDamageTaken(env) - baseline)

		local function configureCurseMerc()
			local profile = build.mercenaryTab.profile
			profile.classId = "ChaosMinionWitch"
			profile.buildId = "ChaosMinionWitchDot"
			profile.mainSkillId = "BaneMercenary"
			profile.skills = {
				{ id = "BaneMercenary", enabled = true, supports = { } },
				{ id = "TemporalChainsMercenary", enabled = true, count = 1, supports = { } },
			}
			build.mercenaryTab:Changed()
			build.mercenaryTab:GetItemSet(true)
		end
		newBuild()
		selectScionLuminary()
		configureMercenary()
		configSet = actorConfig()
		configSet.customModsList[1].text = curseByYouMod
		baseline = enemyDamageTaken(calculateBuild())
		configureCurseMerc()
		env = calculateBuild()
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_true(env.enemy.modDB.conditions.Cursed)
		assert.are.equal(baseline, enemyDamageTaken(env))

		newBuild()
		selectScionLuminary()
		configureMercenary()
		configureCurseMerc()
		configSet = actorConfig()
		baseline = enemyDamageTaken(calculateBuild())
		configSet.actors.mercenary.customModsList[1].text = curseByYouMod
		env = calculateBuild()
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_true(env.enemy.modDB.conditions.Cursed)
		assert.are.equal(20, enemyDamageTaken(env) - baseline)
	end)

	it("drives Elemental Equilibrium hit elements from each actor's own overlay", function()
		local configSet = actorConfig()
		configSet.input.enemyConditionHitByFireDamage = true
		local env = calculateBuild()
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_true(env.player.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_not_true(env.mercenary.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_not_true(env.enemyDB:GetCondition("HitByFireDamage") or env.enemyDB:Flag(nil, "Condition:HitByFireDamage"))

		configSet.input.enemyConditionHitByFireDamage = nil
		configSet.actors.mercenary.input.enemyConditionHitByFireDamage = true
		env = calculateBuild()
		assert.is_true(env.mercenary.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_not_true(env.player.enemySourceDB:GetCondition("HitByFireDamage"))

		newBuild()
		selectScionLuminary()
		configureMercenary()
		allocate("Elemental Equilibrium")
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1")
		env = calculateBuild()
		assert.is_true(env.player.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_not_true(env.player.enemySourceDB:GetCondition("HitByColdDamage"))
		assert.is_not_true(env.mercenary.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_true(env.enemyDB:Flag(nil, "Condition:HasColdExposure") or env.enemy.modDB.conditions.HasColdExposure)
		assert.is_true(env.enemyDB:Flag(nil, "Condition:HasLightningExposure") or env.enemy.modDB.conditions.HasLightningExposure)
		assert.is_not_true(env.enemyDB:Flag(nil, "Condition:HasFireExposure") or env.enemy.modDB.conditions.HasFireExposure)

		newBuild()
		selectScionLuminary()
		configureMercenary()
		allocate("Elemental Equilibrium")
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		configSet = actorConfig()
		configSet.actors.mercenary.customModsList[1].text = "Hits that deal Elemental Damage remove Exposure to those Elements and inflict Exposure to other Elements Exposure inflicted this way applies -25% to Resistances"
		env = calculateBuild()
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_true(env.player.enemySourceDB:GetCondition("HitByLightningDamage"))
		assert.is_not_true(env.player.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_true(env.mercenary.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_not_true(env.mercenary.enemySourceDB:GetCondition("HitByLightningDamage"))
	end)

	it("keeps Mercenary EE hit history on an overlay when config source mods are empty", function()
		local calcs = require("Modules.CalcBase")
		local configSet = actorConfig()
		assert.is_nil(configSet.actors.mercenary.input.enemyConditionHitByFireDamage)
		assert.is_nil(configSet.actors.mercenary.input.enemyConditionHitByColdDamage)
		assert.is_nil(configSet.actors.mercenary.input.enemyConditionHitByLightningDamage)
		configSet.actors.mercenary.customModsList[1].text = "Hits that deal Elemental Damage remove Exposure to those Elements and inflict Exposure to other Elements Exposure inflicted this way applies -25% to Resistances"
		calculateBuild()
		wipeTable(build.configTab.mercenaryEnemyModList)
		assert.is_nil(build.configTab.mercenaryEnemyModList[1])
		local env = calcs.initEnv(build, "MAIN")
		calcs.perform(env)
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_not_nil(env.mercenary.enemySourceDB)
		assert.is_true(env.mercenary.enemySourceDB:GetCondition("HitByFireDamage"))
		assert.is_not_true(env.mercenary.enemySourceDB:GetCondition("HitByColdDamage"))
		assert.is_not_true(env.mercenary.enemySourceDB:GetCondition("HitByLightningDamage"))
		assert.is_not_true(env.enemyDB:GetCondition("HitByFireDamage") or env.enemyDB:Flag(nil, "Condition:HitByFireDamage"))
		assert.is_true(env.enemyDB:Flag(nil, "Condition:HasColdExposure") or env.enemy.modDB.conditions.HasColdExposure)
		assert.is_true(env.enemyDB:Flag(nil, "Condition:HasLightningExposure") or env.enemy.modDB.conditions.HasLightningExposure)
		assert.is_not_true(env.enemyDB:Flag(nil, "Condition:HasFireExposure") or env.enemy.modDB.conditions.HasFireExposure)
	end)

	it("scales each exposure with its inflictor before choosing the strongest", function()
		local configSet = actorConfig()
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		local exposure = "Nearby Enemies have Fire Exposure"
		local bonus = "Exposure you inflict applies an extra -25% to the affected Resistance"
		local function fireResistance()
			return calculateBuild().enemyDB:Sum("BASE", nil, "FireResist")
		end
		local baseline = fireResistance()
		for _, owner in ipairs({ "player", "mercenary" }) do
			local source = owner == "player" and configSet or configSet.actors.mercenary
			local other = owner == "player" and configSet.actors.mercenary or configSet
			source.customModsList[1].text = exposure
			other.customModsList[1].text = bonus
			local env = calculateBuild()
			assert.are.equal(baseline - 10, env.enemyDB:Sum("BASE", nil, "FireResist"))
			assert.is_true(env[owner].modDB:Flag(nil, "Condition:AppliedExposureRecently"))
			assert.is_not_true(env[owner == "player" and "mercenary" or "player"].modDB:Flag(nil, "Condition:AppliedExposureRecently"))
			source.customModsList[1].text = exposure.."\n"..bonus
			other.customModsList[1].text = exposure
			assert.are.equal(baseline - 35, fireResistance())
		end
		configSet.customModsList[1].text = ""
		configSet.actors.mercenary.customModsList[1].text = "100% chance to inflict Cold Exposure on Hit with Cold Damage\n"..bonus
		configSet.input.conditionEnemyColdExposure = true
		local env = calculateBuild()
		assert.are.equal(-35, env.enemyDB:Sum("BASE", nil, "ColdResist") - baseline)
		assert.is_not_true(env.player.modDB:Flag(nil, "Condition:AppliedExposureRecently"))
	end)

	it("keeps minion curses separate from both owners' by-you conditions", function()
		local configSet = actorConfig()
		build.skillsTab:PasteSocketGroup("Summon Skitterbots 20/0  1")
		local profile = build.mercenaryTab.profile
		for _, buildId in ipairs(build.data.mercenaries.buildOrder) do
			local mercBuild = build.data.mercenaries.builds[buildId]
			if isValueInArray(mercBuild.skillIds, "SummonSkitterbotsMercenary") then
				profile.buildId, profile.classId = buildId, mercBuild.classId
				break
			end
		end
		profile.mainSkillId = "SummonSkitterbotsMercenary"
		profile.skills = { { id = profile.mainSkillId, enabled = true, supports = { } } }
		build.mercenaryTab:Changed()
		configSet.customModsList[1].text = "Enemies you Curse take 20% increased Damage"
		configSet.actors.mercenary.customModsList[1].text = "Enemies you Curse take 30% increased Damage"
		build.configTab:BuildModList()
		local calcs = require("Modules.CalcBase")
		for _, owner in ipairs({ "player", "mercenary" }) do
			local env = calcs.initEnv(build, "MAIN")
			env[owner].modDB:NewMod("MinionModifier", "LIST", { mod = modLib.createMod("ExtraCurse", "LIST", { skillId = "Enfeeble", level = 1 }, "Test") }, "Test")
			calcs.perform(env)
			assert.is_true(env.enemyDB:GetCondition("Cursed"))
			assert.is_true(env[owner].mainSkill.minion.enemySourceDB:GetCondition("Cursed"))
			assert.is_not_true(env.player.enemySourceDB:GetCondition("Cursed"))
			assert.is_not_true(env.mercenary.enemySourceDB:GetCondition("Cursed"))
		end
	end)

	it("preserves competing skill exposures through debuff merging", function()
		local configSet = actorConfig()
		local profile = build.mercenaryTab.profile
		for _, buildId in ipairs(build.data.mercenaries.buildOrder) do
			local mercBuild = build.data.mercenaries.builds[buildId]
			if isValueInArray(mercBuild.skillIds, "FrostBombMercenary") then
				profile.buildId, profile.classId = buildId, mercBuild.classId
				break
			end
		end
		profile.mainSkillId = "FrostBombMercenary"
		profile.skills = { { id = profile.mainSkillId, enabled = true, includeInFullDPS = true, supports = { } } }
		build.mercenaryTab:Changed()
		build.skillsTab:PasteSocketGroup("Frost Bomb 20/0  1")
		build.skillsTab.socketGroupList[1].includeInFullDPS = true
		local baseline = calculateBuild().enemyDB:Sum("BASE", nil, "ColdResist")
		for _, config in ipairs({ configSet, configSet.actors.mercenary }) do
			config.customModsList[1].text = "Exposure you inflict applies an extra -25% to the affected Resistance"
			local env = calculateBuild()
			assert.are.equal(baseline - 25, env.enemyDB:Sum("BASE", nil, "ColdResist"))
			local firstDPS = env.player.output.FullDPS
			assert.are.equal(firstDPS, calculateBuild().player.output.FullDPS)
			config.customModsList[1].text = ""
		end
	end)

	it("hover comparisons use the viewed actor's output", function()
		calculateBuild()
		local configTab = build.configTab
		local captured
		local function captureRun()
			configTab.calcFunc = nil
			captured = "unset"
			configTab.RunComparisonCalc = function(self, calcFunc, comparisonActor)
				captured = comparisonActor
				return calcFunc(comparisonActor and { comparisonActor = comparisonActor } or nil)
			end
			local tooltip = new("Tooltip"):Tooltip()
			assert.has_no.errors(function()
				configTab.varControls.usePowerCharges.tooltipFunc(tooltip)
			end)
			configTab.RunComparisonCalc = nil
		end

		configTab:SetViewActor("mercenary")
		captureRun()
		assert.are.equal("MERCENARY", captured)

		configTab:SetViewActor("player")
		captureRun()
		assert.is_nil(captured)
	end)
end)
