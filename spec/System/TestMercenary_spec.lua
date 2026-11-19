describe("TestMercenary", function()
	before_each(function()
		newBuild()
	end)

	local function addGroup(mercenary, ...)
		local group = { label = "", enabled = true, mercenary = mercenary, gemList = { } }
		for _, gemId in ipairs({ ... }) do
			local gemData = build.data.gems[gemId]
			table.insert(group.gemList, { gemId = gemId, nameSpec = gemData.name, skillId = gemData.grantedEffectId, level = gemData.naturalMaxLevel, quality = 0, enabled = true, enableGlobal1 = true, count = 1 })
		end
		build.skillsTab:ProcessSocketGroup(group)
		table.insert(build.skillsTab.socketGroupList, group)
		build.buildFlag = true
		runCallback("OnFrame")
	end

	local function addMercenaryGroup(...)
		local gemIds = { }
		for _, skillId in ipairs({ ... }) do
			table.insert(gemIds, "Mercenary/"..skillId)
		end
		addGroup(true, unpack(gemIds))
	end

	-- Mercenaries use the first item set unless one is selected
	local function equipItem(raw)
		local item = new("Item"):Item(raw)
		build.itemsTab:AddItem(item)
		build.itemsTab:EquipItemInSet(item, build.itemsTab.activeItemSetId)
	end

	local function hireMercenary()
		addGroup(false, "Metadata/Items/Gems/SkillGemCallMercenary")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		return build.calcsTab.mainEnv.player.mainSkill.minion
	end

	it("has selectable mercenary gems that don't replace player gems", function()
		local gemData = build.data.gems["Mercenary/SparkMercenary"]
		assert.are.equals("Spark", gemData.name)
		assert.is_true(gemData.tags.mercenary)
		assert.are.equals("Spark", build.data.gems[build.data.gemForBaseName["spark"]].grantedEffect.id)
		-- Implementation is inherited from the player skill
		assert.are.same(build.data.skills.Spark.baseFlags, build.data.skills.SparkMercenary.baseFlags)
	end)

	it("grants Order: To me! from Noble Blood", function()
		local mods = modLib.parseMod("You can hire a Mercenary permanently")
		assert.are.equals("ExtraSkill", mods[1].name)
		assert.are.equals("CallMercenary", mods[1].value.skillId)
	end)

	it("uses mercenary skills and supports on the mercenary instead of the player", function()
		addMercenaryGroup("SparkMercenary", "MercenarySupportMultipleProjectilesHigh")
		local minion = hireMercenary()
		assert.are.equals("Mercenary", minion.minionData.name)
		local mercSkill = minion.activeSkillList[1]
		assert.are.equals("SparkMercenary", mercSkill.activeEffect.grantedEffect.id)
		assert.are.equals(2, #mercSkill.effectList)
		assert.are.equals("MercenarySupportMultipleProjectilesHigh", mercSkill.effectList[2].grantedEffect.id)
		assert.is_true(build.calcsTab.mainOutput.Minion.TotalDPS > 0)
		for _, activeSkill in ipairs(build.calcsTab.mainEnv.player.activeSkillList) do
			assert.is_nil(activeSkill.activeEffect.grantedEffect.mercenary)
		end
	end)

	it("only uses supports listed by the mercenary skill", function()
		addMercenaryGroup("SparkMercenary", "MercenarySupportConflagrationSpecificInvertResistancesHigh", "MercenarySupportMultipleProjectilesHigh")
		local mercSkill = hireMercenary().mainSkill
		assert.are.equals(2, #mercSkill.effectList)
		assert.are.equals("MercenarySupportMultipleProjectilesHigh", mercSkill.effectList[2].grantedEffect.id)
	end)

	it("uses the configured mercenary level for skill levels instead of the gem level", function()
		addMercenaryGroup("SparkMercenary")
		build.skillsTab.socketGroupList[1].gemList[1].level = 1
		build.configTab.input.mercenaryLevel = 70
		build.configTab:BuildModList()
		local minion = hireMercenary()
		assert.are.equals(70, minion.level)
		local expectedLevel = 1
		for level, levelData in ipairs(build.data.skills.SparkMercenary.levels) do
			if levelData.levelRequirement <= minion.level then
				expectedLevel = level
			end
		end
		assert.is_true(expectedLevel > 1)
		assert.are.equals(expectedLevel, minion.activeSkillList[1].activeEffect.level)
	end)

	it("has the permanent mercenary damage penalty tapering in with level", function()
		addMercenaryGroup("SparkMercenary")
		local function penalty(level)
			build.configTab.input.mercenaryLevel = level
			build.configTab:BuildModList()
			for _, value in ipairs(hireMercenary().modDB:Tabulate("MORE", nil, "Damage")) do
				if value.mod.source == "Permanent Mercenary" then
					return value.mod.value
				end
			end
			return 0
		end
		assert.are.equals(84, hireMercenary().level)
		assert.are.equals(-30, penalty(84))
		assert.are.equals(-15, penalty(64))
		assert.are.equals(0, penalty(45))
	end)

	it("gets Luminary mercenary modifiers, but other minions don't", function()
		addMercenaryGroup("SparkMercenary")
		build.configTab.input.customMods = "Your Mercenary and their Minions deal 15% increased Damage"
		build.configTab:BuildModList()
		local minion = hireMercenary()
		assert.are.equals(15, minion.modDB:Sum("INC", nil, "Damage"))
		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.mainEnv.player.mainSkill.minion.modDB:Sum("INC", nil, "Damage"))
	end)

	it("isn't affected by mechanics that only affect minions", function()
		addMercenaryGroup("SparkMercenary")
		addGroup(false, "Metadata/Items/Gems/SkillGemFleshOffering")
		build.configTab.input.customMods = "Your Strength is added to your Minions\nYour Minions gain your chance to Suppress Spell Damage\n+20% chance to Suppress Spell Damage"
		build.configTab:BuildModList()
		local function playerSourced(minion)
			return minion.modDB:Sum("BASE", { source = "Player" }, "Str", "SpellSuppressionChance")
		end
		local minion = hireMercenary()
		local playerModDB = build.calcsTab.mainEnv.player.modDB
		assert.is_nil(minion.modDB.conditions["AffectedByFleshOffering"])
		assert.are.equals(0, playerSourced(minion))
		assert.are.equals(0, playerModDB:Sum("BASE", nil, "Multiplier:SummonedMinion"))
		assert.is_false(playerModDB.conditions["OnlyMinion"])
		assert.is_false(playerModDB:Flag(nil, "Condition:HaveDamageableMinion") or false)

		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		minion = build.calcsTab.mainEnv.player.mainSkill.minion
		assert.is_true(minion.modDB.conditions["AffectedByFleshOffering"])
		assert.is_true(playerSourced(minion) > 0)
	end)

	it("isn't affected by spectre buffs that only affect minions", function()
		local spiderLeader = "Metadata/Monsters/LeagueAzmeri/SpecialCorpses/SpiderLeaderMid"
		build.spectreList = { spiderLeader }
		addMercenaryGroup("SparkMercenary")
		addGroup(false, "Metadata/Items/Gems/SkillGemRaiseSpectre")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].gemList[1].skillMinion = spiderLeader
		hireMercenary()
		assert.is_nil(build.calcsTab.mainEnv.minionBuffs["Judgemental Spirit"])

		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		assert.is_not_nil(build.calcsTab.mainEnv.minionBuffs["Judgemental Spirit"])
	end)

	it("isn't affected by spectre modifiers that only affect minions", function()
		local slashingHorror = "Metadata/Monsters/LeagueAzmeri/SpecialCorpses/DualstrikeDemonMid"
		build.spectreList = { slashingHorror }
		addMercenaryGroup("SparkMercenary")
		addGroup(false, "Metadata/Items/Gems/SkillGemRaiseSpectre")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].gemList[1].skillMinion = slashingHorror
		hireMercenary()
		assert.is_nil(build.calcsTab.mainEnv.minionBuffs["Spectre"])

		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		assert.is_not_nil(build.calcsTab.mainEnv.minionBuffs["Spectre"])
	end)

	it("doesn't give its minion buffs to the player's minions", function()
		addMercenaryGroup("FleshOfferingMercenary")
		hireMercenary()
		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		assert.is_nil(build.calcsTab.mainEnv.minionBuffs["Flesh Offering"])
	end)

	it("doesn't use the player's main hand attack time", function()
		addMercenaryGroup("IceShotMercenary")
		build.configTab.input.customMods = "Non-Spectre Minions' Base Attack Time is equal to the Attack Time of your Main Hand Weapon"
		build.configTab:BuildModList()
		local playerAttackRate = build.calcsTab.mainEnv.player.weaponData1.AttackRate
		assert.are_not.equals(playerAttackRate, hireMercenary().weaponData1.AttackRate)

		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(playerAttackRate, build.calcsTab.mainEnv.player.mainSkill.minion.weaponData1.AttackRate)
	end)

	it("needs compatible weapons for its skills", function()
		addMercenaryGroup("IceShotMercenary")
		addMercenaryGroup("TempestShieldMercenary")
		hireMercenary()
		local function disabledSkills()
			build.buildFlag = true
			runCallback("OnFrame")
			local disabled = { }
			for _, skill in ipairs(build.calcsTab.mainEnv.player.mainSkill.minion.activeSkillList) do
				disabled[skill.activeEffect.grantedEffect.id] = skill.skillFlags.disable or false
			end
			return disabled
		end
		assert.are.same({ IceShotMercenary = true, TempestShieldMercenary = true }, disabledSkills())

		equipItem([[
			Rarity: RARE
			Test Subject
			Splintered Tower Shield
		]])
		assert.are.same({ IceShotMercenary = true, TempestShieldMercenary = false }, disabledSkills())

		equipItem([[
			Rarity: RARE
			Test Subject
			Crude Bow
		]])
		-- The bow is two handed, so it replaces the shield
		assert.are.same({ IceShotMercenary = false, TempestShieldMercenary = true }, disabledSkills())
	end)

	it("uses minion state config options", function()
		addMercenaryGroup("SparkMercenary")
		build.configTab.input.minionsUsePowerCharges = true
		build.configTab.input.minionBuffOnslaught = true
		build.configTab:BuildModList()
		local minion = hireMercenary()
		assert.is_true(minion.modDB:Flag(nil, "UsePowerCharges"))
		assert.is_true(minion.modDB:Flag(nil, "Condition:Onslaught"))
	end)

	it("gets the hidden stats of its mercenary type", function()
		addMercenaryGroup("IceShotMercenary")
		local function hiddenDamage(level, buildId)
			build.configTab.input.mercenaryLevel = level
			build.configTab.input.mercenaryBuild = buildId
			build.configTab:BuildModList()
			for _, value in ipairs(hireMercenary().modDB:Tabulate("INC", nil, "Damage")) do
				if value.mod.source:match("^Mercenary:") then
					return value.mod.source, value.mod.value
				end
			end
		end
		assert.is_nil(hiddenDamage(84, "NONE"))
		assert.are.same({ "Mercenary:Manyshot", 250 }, { hiddenDamage(84, "EleBowRangerClones") })
		assert.are.same({ "Mercenary:Manyshot", 225 }, { hiddenDamage(76, "EleBowRangerClones") })
		assert.are.same({ "Mercenary:Manyshot", 100 }, { hiddenDamage(10, "EleBowRangerClones") })
		assert.are.equals("Mercenary:Flamequiver", (hiddenDamage(84, "EleBowRangerFire")))
	end)

	it("has attack damage scaling with level and resistance penalties from the area level", function()
		addMercenaryGroup("SparkMercenary")
		local function sourceValue(modDB, modType, modName, source)
			for _, value in ipairs(modDB:Tabulate(modType, { flags = ModFlag.Attack }, modName)) do
				if value.mod.source == source then
					return value.mod.value
				end
			end
			return 0
		end
		local function scaling(mercenaryLevel, enemyLevel)
			build.configTab.input.mercenaryLevel = mercenaryLevel
			build.configTab.input.enemyLevel = enemyLevel
			build.configTab:BuildModList()
			local modDB = hireMercenary().modDB
			return sourceValue(modDB, "MORE", "Damage", "Mercenary Level Scaling"), sourceValue(modDB, "BASE", "ChaosResist", "Mercenary Area Level Penalty")
		end
		assert.are.same({ 100, -60 }, { scaling(84, 84) })
		assert.are.same({ 50, -30 }, { scaling(64, 60) })
		assert.are.same({ 0, 0 }, { scaling(40, 40) })
	end)

	it("searches the supports of a mercenary skill while typing", function()
		addMercenaryGroup("HydraForkArrowMercenary")
		build.skillsTab:SetDisplayGroup(build.skillsTab.socketGroupList[1])
		local control = build.skillsTab.gemSlots[2].nameSpec
		control.hasFocus = true
		for char in ("hypothermia"):gmatch(".") do
			control:OnChar(char)
		end
		local names = { }
		for _, gemId in ipairs(control.list) do
			table.insert(names, control.gems[gemId].name)
		end
		table.sort(names)
		assert.are.same({ "Greater Hypothermia", "Hypothermia", "Lesser Hypothermia" }, names)
	end)

	it("maps mercenary support stats using player support stat maps", function()
		equipItem("Rarity: RARE\nTest Subject\nCrude Bow")
		addMercenaryGroup("IceShotMercenary", "MercenarySupportEleDamageWithAttacksMid")
		local mercSkill = hireMercenary().activeSkillList[1]
		local more = 0
		for _, value in ipairs(mercSkill.skillModList:Tabulate("MORE", mercSkill.skillCfg, "ElementalDamage")) do
			if value.mod.source == "Skill:MercenarySupportEleDamageWithAttacksMid" then
				more = value.mod.value
			end
		end
		assert.are.equals(20, more)
	end)

	it("saves and loads mercenary socket groups", function()
		addMercenaryGroup("SparkMercenary", "MercenarySupportMultipleProjectilesHigh")
		loadBuildFromXML(build:SaveDB("code"))
		local group = build.skillsTab.socketGroupList[1]
		assert.is_true(group.mercenary)
		assert.are.equals("Mercenary/SparkMercenary", group.gemList[1].gemData.id)
		assert.are.equals("Mercenary/MercenarySupportMultipleProjectilesHigh", group.gemList[2].gemData.id)
	end)

	it("applies mercenary auras to the player", function()
		addMercenaryGroup("WrathMercenary")
		hireMercenary()
		assert.is_true(build.calcsTab.mainEnv.player.modDB.conditions["AffectedByWrath"])
	end)

	it("applies aura effect from its gear when it isn't the main skill", function()
		addGroup(false, "Metadata/Items/Gems/SkillGemFireball")
		addMercenaryGroup("WrathMercenary")
		hireMercenary()
		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		local amulet = new("Item"):Item("Rarity: RARE\nTest Subject\nJade Amulet\n50% increased effect of Non-Curse Auras from your Skills")
		build.itemsTab:AddItem(amulet)
		itemSet["Amulet"].selItemId = amulet.id
		build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[1].skillMinionItemSet = itemSet.id
		local function wrathLightningMax(mainSocketGroup)
			build.mainSocketGroup = mainSocketGroup
			build.buildFlag = true
			runCallback("OnFrame")
			local total = 0
			for _, mod in ipairs(build.calcsTab.mainEnv.player.modDB.mods["LightningMax"] or { }) do
				if mod.source:match("Wrath") then
					total = total + mod.value
				end
			end
			return total
		end
		local asMainSkill = wrathLightningMax(build.mainSocketGroup)
		assert.is_true(asMainSkill > 0)
		assert.are.equals(asMainSkill, wrathLightningMax(1))
	end)

	it("can be linked without link skills targeting minions", function()
		addMercenaryGroup("SparkMercenary")
		addGroup(false, "Metadata/Items/Gems/SkillGemFlameLink")
		build.configTab.input.linkedToMinion = true
		build.configTab:BuildModList()
		local minion = hireMercenary()
		assert.is_true(minion.modDB.conditions["AffectedByFlameLink"])
		assert.is_true(build.configTab.varControls.linkedToMinion.shown())
	end)

	it("applies light radius to link effect on the mercenary with Golden Glory", function()
		addMercenaryGroup("SparkMercenary")
		addGroup(false, "Metadata/Items/Gems/SkillGemFlameLink")
		build.configTab.input.linkedToMinion = true
		local function linkedFireMax(customMods)
			build.configTab.input.customMods = customMods
			build.configTab:BuildModList()
			return hireMercenary().modDB:Sum("BASE", nil, "FireMax")
		end
		local base = linkedFireMax("")
		assert.is_true(base > 0)
		assert.are.equals(base, linkedFireMax("50% increased Light Radius"))
		assert.is_true(linkedFireMax("50% increased Light Radius\nIncreases and Reductions to Light Radius also apply to Effect of your Link Skill Buffs on your Mercenary at 50% of their value") > base)
	end)

	it("has accuracy instead of always hitting like other minions", function()
		build.configTab.input.enemyEvasion = 100000
		build.configTab:BuildModList()
		equipItem("Rarity: RARE\nTest Subject\nCrude Bow")
		addMercenaryGroup("IceShotMercenary")
		local minion = hireMercenary()
		local baseAccuracy = 0
		for _, value in ipairs(minion.modDB:Tabulate("BASE", nil, "Accuracy")) do
			if value.mod.source == "Base" then
				baseAccuracy = value.mod.value
			end
		end
		assert.are.equals(minion.minionData.accuracyPerLevel * minion.level, baseAccuracy)
		assert.is_true(build.calcsTab.mainOutput.Minion.MainHand.HitChance < 100)

		addGroup(false, "Metadata/Items/Gems/SkillGemSummonRagingSpirit")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(100, build.calcsTab.mainOutput.Minion.MainHand.HitChance)
	end)

	it("is affected by abyss jewels in its items and takes less damage over time", function()
		addMercenaryGroup("SparkMercenary")
		local minion = hireMercenary()
		assert.are.equals(0.2, minion.modDB:More(nil, "DamageTakenOverTime"))
		local baseLife = build.calcsTab.mainOutput.Minion.Life

		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		local gloves = new("Item"):Item([[
			Rarity: RARE
			Test Subject
			Iron Gauntlets
			Has 1 Abyssal Socket
		]])
		local jewel = new("Item"):Item([[
			Rarity: RARE
			Test Subject
			Murderous Eye Jewel
			+30 to maximum Life
		]])
		build.itemsTab:AddItem(gloves)
		build.itemsTab:AddItem(jewel)
		itemSet["Gloves"].selItemId = gloves.id
		itemSet["Gloves Abyssal Socket 1"].selItemId = jewel.id
		build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[1].skillMinionItemSet = itemSet.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 30, build.calcsTab.mainOutput.Minion.Life)

		-- Jewels only apply if the item has an Abyssal Socket for them
		local socketlessGloves = new("Item"):Item([[
			Rarity: RARE
			Test Subject
			Iron Gauntlets
		]])
		build.itemsTab:AddItem(socketlessGloves)
		itemSet["Gloves"].selItemId = socketlessGloves.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife, build.calcsTab.mainOutput.Minion.Life)
	end)

	it("is affected by anoints on its items", function()
		addMercenaryGroup("SparkMercenary")
		hireMercenary()
		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		local belt = new("Item"):Item([[
			Rarity: RARE
			Test Subject
			Leather Belt
			Allocates Disciple of the Slaughter (enchant)
		]])
		build.itemsTab:AddItem(belt)
		itemSet["Belt"].selItemId = belt.id
		build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[1].skillMinionItemSet = itemSet.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(1, build.calcsTab.mainOutput.Minion.FrenzyChargesMin)
	end)

	it("gets character-like base life and gear from its item set", function()
		addMercenaryGroup("SparkMercenary")
		local minion = hireMercenary()
		local baseLife = build.calcsTab.mainOutput.Minion.Life
		assert.are.equals(minion.minionData.lifePerLevel * minion.level, baseLife)

		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		local item = new("Item"):Item([[
			Rarity: RARE
			Test Subject
			Iron Hat
			+50 to maximum Life
		]])
		build.itemsTab:AddItem(item)
		itemSet["Helmet"].selItemId = item.id
		build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[1].skillMinionItemSet = itemSet.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 50, build.calcsTab.mainOutput.Minion.Life)

		-- Uniques need a Luminary passive allowing them in that slot
		local uniqueRing = new("Item"):Item([[
			Rarity: UNIQUE
			Test Subject
			Iron Ring
			+30 to maximum Life
		]])
		build.itemsTab:AddItem(uniqueRing)
		itemSet["Ring 1"].selItemId = uniqueRing.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 50, build.calcsTab.mainOutput.Minion.Life)

		build.configTab.input.customMods = "Your Mercenary can equip Unique Rings"
		build.configTab:BuildModList()
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 80, build.calcsTab.mainOutput.Minion.Life)

		local disabledUnique = new("Item"):Item([[
			Rarity: UNIQUE
			Kalandra's Touch
			Iron Ring
			+40 to maximum Life
		]])
		build.itemsTab:AddItem(disabledUnique)
		itemSet["Ring 2"].selItemId = disabledUnique.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 80, build.calcsTab.mainOutput.Minion.Life)
	end)

	it("only uses abyss jewels from its active weapon set", function()
		addMercenaryGroup("SparkMercenary")
		hireMercenary()
		local baseLife = build.calcsTab.mainOutput.Minion.Life
		local itemSet = build.itemsTab:NewItemSet()
		table.insert(build.itemsTab.itemSetOrderList, itemSet.id)
		local function addItem(slotName, raw)
			local item = new("Item"):Item(raw)
			build.itemsTab:AddItem(item)
			itemSet[slotName].selItemId = item.id
		end
		local shield = "Rarity: RARE\nTest Subject\nPine Buckler\nHas 1 Abyssal Socket"
		addItem("Weapon 2", shield)
		addItem("Weapon 2 Abyssal Socket 1", "Rarity: RARE\nTest Subject\nMurderous Eye Jewel\n+30 to maximum Life")
		addItem("Weapon 2 Swap", shield)
		addItem("Weapon 2 Swap Abyssal Socket 1", "Rarity: RARE\nTest Subject\nMurderous Eye Jewel\n+40 to maximum Life")
		build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[1].skillMinionItemSet = itemSet.id
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 30, build.calcsTab.mainOutput.Minion.Life)

		itemSet.useSecondWeaponSet = true
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(baseLife + 40, build.calcsTab.mainOutput.Minion.Life)
	end)

	it("maps minion stats of its mercenary type like skill stats", function()
		addMercenaryGroup("SparkMercenary")
		build.configTab.input.mercenaryLevel = 84
		build.configTab.input.mercenaryBuild = "AurasMinionsTemplarSmite"
		build.configTab:BuildModList()
		local minion = hireMercenary()
		local minionDamage
		for _, value in ipairs(minion.modDB:List(nil, "MinionModifier")) do
			if value.mod.name == "Damage" and value.mod.type == "INC" then
				minionDamage = value.mod.value
			end
		end
		assert.are.equals(300, minionDamage)
		assert.is_true(build.calcsTab.mainOutput.Minion.TotalDPS > 0)
	end)

	it("removes gems of the other kind when the group's mercenary option is changed", function()
		addGroup(false, "Metadata/Items/Gems/SkillGemFireball", "Mercenary/SparkMercenary")
		local group = build.skillsTab.socketGroupList[1]
		build.skillsTab:SetDisplayGroup(group)
		build.skillsTab.controls.groupMercenary.changeFunc(true)
		assert.are.equals(1, #group.gemList)
		assert.are.equals("Mercenary/SparkMercenary", group.gemList[1].gemData.id)
		build.skillsTab.controls.groupMercenary.changeFunc(false)
		assert.are.equals(0, #group.gemList)
	end)

	it("copies and pastes mercenary socket groups", function()
		-- Herald of Ash has two mercenary versions with the same name
		addMercenaryGroup("HeraldOfAshMercenaryAlt")
		local copied
		local copy = _G.Copy
		_G.Copy = function(text)
			copied = text
		end
		build.skillsTab:CopySocketGroup(build.skillsTab.socketGroupList[1])
		_G.Copy = copy
		build.skillsTab:PasteSocketGroup(copied)
		local group = build.skillsTab.socketGroupList[2]
		assert.is_true(group.mercenary)
		assert.are.equals("Mercenary/HeraldOfAshMercenaryAlt", group.gemList[1].gemData.id)
		assert.are.equals("Herald of Ash", group.gemList[1].nameSpec)
	end)

	it("can't use mercenary groups as the main skill", function()
		addMercenaryGroup("SparkMercenary")
		hireMercenary()
		build.mainSocketGroup = 1
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.equals(2, build.mainSocketGroup)
		assert.are.equals("CallMercenary", build.calcsTab.mainEnv.player.mainSkill.activeEffect.grantedEffect.id)
		local list = build.controls.mainSocketGroup.list
		assert.are.equals(1, #list)
		assert.are.equals(2, list[1].val)
	end)

	it("only lists one skill for a mercenary group", function()
		addMercenaryGroup("HydraForkArrowMercenary")
		build.skillsTab:SetDisplayGroup(build.skillsTab.socketGroupList[1])
		local spark = build.data.gems["Mercenary/SparkMercenary"]
		local hypothermia = build.data.gems["Mercenary/MercenarySupportHypothermiaMid"]
		assert.is_false(build.skillsTab.gemSlots[2].nameSpec:FilterSupport(spark.id, spark))
		assert.is_true(build.skillsTab.gemSlots[2].nameSpec:FilterSupport(hypothermia.id, hypothermia))
		-- The skill itself can be replaced
		assert.is_true(build.skillsTab.gemSlots[1].nameSpec:FilterSupport(spark.id, spark))
	end)
end)
