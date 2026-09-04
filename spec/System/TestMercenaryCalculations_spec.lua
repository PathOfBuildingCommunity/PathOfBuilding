describe("Permanent Mercenary calculations", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local selectScionLuminary = MercenaryTest.selectScionLuminary
	local allocate = MercenaryTest.allocate
	local MercenaryTools = require("Modules.MercenaryTools")
	local calcs = require("Modules.CalcBase")
	local configOptions = LoadModule("Modules/ConfigOptions")
	local configVisibility = LoadModule("Modules/ConfigVisibility")
	local function equipmentSlot(slotName)
		return assert(build.mercenaryTab:GetItemSet(true))[slotName]
	end

	local function configure(classId, buildId, skillId, fields)
		fields = fields or { }
		local profile = build.mercenaryTab.profile
		profile.classId = classId
		profile.buildId = buildId
		profile.foundAreaLevel = fields.foundAreaLevel or 68
		profile.mainSkillId = skillId
		profile.lifeComparison = fields.lifeComparison or "AUTO"
		profile.skills = { {
			id = skillId,
			enabled = true,
			includeInFullDPS = fields.includeInFullDPS == true,
			count = fields.count or 1,
			skillPart = fields.skillPart,
			skillMinionSkill = fields.skillMinionSkill,
			supports = fields.supports or { },
		} }
		build.mercenaryTab:Changed()
		if buildId then
			build.mercenaryTab:GetItemSet(true)
		end
	end

	local function configureSkill(skillId, fields)
		for buildId, mercBuild in pairs(build.data.mercenaries.builds) do
			for _, id in ipairs(mercBuild.skillIds or { }) do
				if id == skillId then
					configure(mercBuild.classId, buildId, skillId, fields)
					return
				end
			end
		end
		error("no Mercenary build exports "..skillId)
	end

	local function calculate(enemyLevel)
		build.configTab.input.enemyLevel = enemyLevel or 83
		build.configTab:BuildModList()
		build.spec.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		runCallback("OnFrame")
		return build.calcsTab.mainEnv
	end

	local function rallyingWeaponFlat(actor, stat)
		local total = 0
		for _, value in ipairs(actor.modDB:Tabulate("BASE", { keywordFlags = KeywordFlag.Attack }, stat)) do
			if value.mod.source == "Rallying Cry" then
				total = total + value.value
			end
		end
		return total
	end

	local function mercMainHandCrit(env)
		local output = env.mercenary.output
		local hand = output.MainHand or output
		return hand.PreEffectiveCritChance or output.PreEffectiveCritChance, hand.CritMultiplier or output.CritMultiplier
	end

	local function namedDps(skills, name)
		for _, row in ipairs(skills or { }) do
			if row.name == name then return row.dps end
		end
		return 0
	end

	local function decayItem(baseName, id)
		local item = new("Item"):Item("Rarity: RARE\nDecay Test\n"..baseName.."\nImplicits: 0\nYour Hits inflict Decay, dealing 700 Chaos Damage per second for 8 seconds\n")
		item.id = id
		build.itemsTab.items[id] = item
		return item
	end

	local function setMercenaryFullDPS(skillIds)
		local profile = build.mercenaryTab.profile
		local skills = { }
		for _, skillId in ipairs(skillIds) do
			table.insert(skills, { id = skillId, enabled = true, includeInFullDPS = true, count = 1, supports = { } })
		end
		profile.skills = skills
		profile.mainSkillId = skillIds[1]
		build.mercenaryTab:Changed()
	end

	local function selectMinionSkill(skillId)
		local group = build.skillsTab.socketGroupList[build.mainSocketGroup]
		local activeSkill = group.displaySkillList[group.mainActiveSkill]
		local found
		for index, minionSkill in ipairs(activeSkill.minion.activeSkillList) do
			if minionSkill.activeEffect.grantedEffect.id == skillId then
				activeSkill.activeEffect.srcInstance.skillMinionSkill = index
				activeSkill.activeEffect.srcInstance.skillMinionSkillCalcs = index
				found = true
				break
			end
		end
		assert.is_true(found, skillId)
	end

	local function resetBuild()
		newBuild()
		selectScionLuminary()
		allocate("Noble Blood")
		build.characterLevel = 90
		build.characterLevelAutoMode = false
	end

	before_each(function()
		newBuild()
		selectScionLuminary()
		allocate("Noble Blood")
		build.characterLevel = 90
		build.characterLevelAutoMode = false
	end)

	it("does not pin recycled Mercenary databases after unhire", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local env = calculate()
		assert.is_not_nil(env.mercenary)
		build.mercenaryTab.profile.buildId = nil
		build.mercenaryTab.profile.classId = nil
		build.mercenaryTab:Changed()
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.is_nil(env.recycledMercenaryModDB)
		assert.is_nil(env.recycledMercenaryItemModDB)
		assert.is_nil(env.recycledMercenaryEnemySourceDB)
		assert.is_nil(env.player.enemySourceDB)
	end)

	it("fails closed on invalid Mercenary loadouts", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		build.mercenaryTab.profile.skills[1].enabled = false
		local env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Enable at least one Mercenary skill", table.concat(env.mercenaryCalculationErrors, "\n"))

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		build.mercenaryTab.profile.buildId = "NotARealBuild"
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Select a Mercenary class and build", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalBlowMercenary")
		local profile = build.mercenaryTab.profile
		profile.skills = { }
		for _, skillId in ipairs(build.data.mercenaries.builds.MeleeAOEMarauderFireSlam.skillIds) do
			table.insert(profile.skills, { id = skillId, enabled = true, supports = { } })
			if #profile.skills == 7 then break end
		end
		profile.mainSkillId = profile.skills[1].id
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("cannot have more than 6", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		profile = build.mercenaryTab.profile
		table.insert(profile.skills, { id = "LightningTrapMercenary", enabled = true, supports = { } })
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Duplicate skill", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		profile.skills = {
			{ id = "LightningTrapMercenary", enabled = false, supports = { } },
			{ id = "ZealotryMercenary", enabled = true, supports = { } },
		}
		profile.mainSkillId = "LightningTrapMercenary"
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.is_true(not env.mercenary)
		assert.matches("disabled", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "FissureSlamMercenary")
		profile = build.mercenaryTab.profile
		table.insert(profile.skills, { id = "TectonicSlamFireMercenary", enabled = true, supports = { } })
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Skill pool", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", {
			supports = {
				{ id = "AddedLightningHigh", tier = 3 },
				{ id = "AddedLightningMid", tier = 2 },
			},
		})
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Duplicate support family", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		build.mercenaryTab.profile.mainSkillId = "ZealotryMercenary"
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Selected Calcs skill is not configured", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local uniqueBody = {
			id = 9040, name = "Illegal Unique Body", type = "Body Armour", base = { type = "Body Armour" },
			rarity = "UNIQUE", requirements = { str = 1 }, grantedSkills = { }, modList = { },
		}
		build.itemsTab.items[uniqueBody.id] = uniqueBody
		equipmentSlot("Body Armour").selItemId = uniqueBody.id
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Body Armour", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local dexHelmet = {
			id = 9043, name = "Dex Helmet", type = "Helmet", base = { type = "Helmet" },
			rarity = "RARE", requirements = { dex = 1 }, grantedSkills = { }, modList = { },
		}
		build.itemsTab.items[dexHelmet.id] = dexHelmet
		equipmentSlot("Helmet").selItemId = dexHelmet.id
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Helmet", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		configure("EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary")
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		bow.id = 9044
		build.itemsTab.items[bow.id] = bow
		equipmentSlot("Weapon 1").selItemId = bow.id
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.matches("Weapon 2", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		resetBuild()
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.is_nil(env.mercenaryCalculationErrors)

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		assert.is_table(build.mercenaryTab:GetItemSet(false))
		build.mercenaryTab.itemSetId = 99999
		env = calculate()
		assert.is_nil(env.mercenary)
		assert.is_nil(env.mercenaryMinion)
		assert.is_not_nil(env.mercenaryCalculationErrors)
		assert.matches("No Mercenary item set is available", table.concat(env.mercenaryCalculationErrors, "\n"))
		assert.is_nil(build.calcsTab.calcsEnv.mercenary)
		local _, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		assert.is_true(not MercenaryTools.mercenaryOutputAvailable(actorOutputs.MERCENARY))
		assert.matches("No Mercenary item set is available", actorOutputs.MERCENARY.ActorUnavailableMessage)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { foundAreaLevel = 101 })
		env = calculate(85)
		assert.is_nil(env.mercenary)
		assert.matches("Found%-area level must be an integer between 1 and 100", table.concat(env.mercenaryCalculationErrors or { }, "\n"))

		resetBuild()
		configure("ChaosMinionWitch", "ChaosMinionWitchInstability", "SSMMercenaryRelic")
		local dagger = new("Item"):Item("Rarity: Normal\nGlass Shank")
		local shield = new("Item"):Item("Rarity: Normal\nTwig Spirit Shield")
		dagger.id, shield.id = 9052, 9053
		build.itemsTab.items[dagger.id], build.itemsTab.items[shield.id] = dagger, shield
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = dagger.id, shield.id
		env = calculate(83)
		assert.is_nil(env.mercenary)
		assert.matches("Unholy Relic has no exported skills", table.concat(env.mercenaryCalculationErrors or { }, "\n"))
	end)

	it("hires only with Noble Blood on Luminary", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "ZealotryMercenary")
		local hired = calculate()
		assert.is_true(hired.player.modDB.conditions.AffectedByZealotry)

		local nobleBlood
		for _, node in pairs(build.spec.allocNodes) do
			if node.name == "Noble Blood" then nobleBlood = node break end
		end
		nobleBlood = assert(nobleBlood, "Noble Blood")
		build.spec.allocNodes[nobleBlood.id] = nil
		nobleBlood.alloc = false
		local unhired = calculate()
		assert.is_nil(unhired.mercenary)
		assert.is_not_true(unhired.player.modDB.conditions.AffectedByZealotry)
		assert.matches("Noble Blood", table.concat(build.mercenaryTab:GetErrors(), "\n"))
		assert.are.equal("TrapsMinesShadowLightning", build.mercenaryTab.profile.buildId)
		assert.matches("Noble Blood", table.concat(build.controls.warnings.lines, "\n"))
		assert.is_true(build.controls.modeMercenary:IsShown())

		for classId, class in pairs(build.spec.tree.classes) do
			if class.name == "Marauder" then build.spec:SelectClass(classId) break end
		end
		assert.is_nil(calculate().mercenary)
		assert.matches("Scion's Luminary", table.concat(build.mercenaryTab:GetErrors(), "\n"))
		assert.are.equal("TrapsMinesShadowLightning", build.mercenaryTab.profile.buildId)
		assert.not_matches("Mercenary:", table.concat(build.controls.warnings.lines, "\n"))
		assert.is_true(not build.controls.modeMercenary:IsShown())
		build.viewMode = "MERCENARY"
		build.calcsTab.input.actor = "MERCENARY"
		build:SyncMercenaryUi()
		assert.are.equal("TREE", build.viewMode)
		assert.are.equal("PLAYER", build.calcsTab.input.actor)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		build.mercenaryTab.itemSetId = 99999
		build.calcsTab.input.actor = "MERCENARY"
		local env = calculate()
		assert.is_nil(env.mercenary)
		assert.is_not_nil(env.mercenaryCalculationErrors)
		assert.is_nil(build.calcsTab:GetDisplayActor(build.calcsTab.calcsEnv))
		assert.is_truthy(build.calcsTab.calcsOutput.ActorUnavailableMessage)
		assert.is_true(build.calcsTab:CheckFlag({ haveOutput = "ActorUnavailableMessage" }))
		assert.is_true(not build.calcsTab:CheckFlag({ flag = "attack" }))
		assert.is_true(not build.calcsTab:CheckFlag({ flag = "minion" }))
		assert.is_true(not build.calcsTab:CheckFlag({ playerFlag = "multiPart" }))
		assert.is_true(not build.calcsTab:CheckFlag({ haveOutput = "Life" }))
		assert.is_true(not build.calcsTab:CheckFlag({ haveOutput = "CombinedDPS" }))
		assert.is_true(env.player.output.Life > 0)
		assert.is_nil(build.calcsTab.calcsOutput.Life)
		assert.is_nil(build.calcsTab.calcsOutput.CombinedDPS)
		for _, section in ipairs(build.calcsTab.sectionList) do
			section:UpdateSize()
			if section.flag == "attack" then
				assert.is_true(not section.enabled, section.id)
			end
		end
		local statusOnly = { output = build.calcsTab.calcsOutput }
		assert.is_nil(statusOnly.mainSkill)
		assert.matches("unavailable", formatCalcStr("{output:ActorUnavailableMessage}", statusOnly))
	end)

	it("does not warn an unused Scion Mercenary loadout until the tab is open", function()
		assert.is_true(build.controls.modeMercenary:IsShown())
		assert.is_nil(calculate().mercenary)
		assert.not_matches("Mercenary:", table.concat(build.controls.warnings.lines, "\n"))
		build.viewMode = "MERCENARY"
		build:RefreshStatList()
		assert.matches("Select a Mercenary class", table.concat(build.controls.warnings.lines, "\n"))
	end)

	it("keeps independent loadouts and persists XML", function()
		build.mercenaryTab:EnsureData()
		build.mercenaryTab:Changed()
		assert.are.equal(7, #build.mercenaryTab.controls.class.list)
		assert.are.equal("Templar (Str / Int)", build.mercenaryTab.controls.class.list[1].label)

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local firstId = build.mercenaryTab.activeMercenarySetId
		local firstEnv = calculate()
		assert.are.equal("LightningTrapMercenary", firstEnv.mercenary.mainSkill.activeEffect.grantedEffect.id)

		local second = build.mercenaryTab:NewMercenarySet()
		table.insert(build.mercenaryTab.mercenarySetOrderList, second.id)
		build.mercenaryTab:SetActiveMercenarySet(second.id)
		build.mercenaryTab.profile.classId = "TrapsMinesShadow"
		build.mercenaryTab.profile.buildId = "TrapsMinesShadowLightning"
		build.mercenaryTab.profile.mainSkillId = "ZealotryMercenary"
		build.mercenaryTab.profile.skills = { { id = "ZealotryMercenary", enabled = true, supports = { } } }
		local secondEnv = calculate()
		assert.are.equal("ZealotryMercenary", secondEnv.mercenary.mainSkill.activeEffect.grantedEffect.id)

		build.mercenaryTab:SetActiveMercenarySet(firstId)
		local firstAgainEnv = calculate()
		assert.are.equal("LightningTrapMercenary", firstAgainEnv.mercenary.mainSkill.activeEffect.grantedEffect.id)

		resetBuild()
		configure("EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary", { includeInFullDPS = true })
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9040, 9041
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id

		local itemsXml, mercenaryXml = { }, { }
		build.itemsTab:Save(itemsXml)
		build.mercenaryTab:Save(mercenaryXml)
		local savedItemSetId = build.mercenaryTab.itemSetId
		build.itemsTab:Load(itemsXml)
		build.mercenaryTab:Load(mercenaryXml)

		local env = calculate()
		assert.are.equal(savedItemSetId, build.mercenaryTab.itemSetId)
		assert.are.equal(bow, env.mercenary.itemList["Weapon 1"])
		assert.is_true(env.mercenary.output.FullDPS > 0)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", {
			includeInFullDPS = true,
			count = 2,
			skillPart = 1,
			skillMinionSkill = 2,
			supports = { { id = "AddedLightningHigh", tier = 3 } },
		})
		assert(build.mercenaryTab:GetItemSet(true))
		local function savedState()
			local saved = { elem = "Mercenary", attrib = { } }
			build.mercenaryTab:Save(saved)
			return saved
		end
		local saved = savedState()
		build.mercenaryTab:Reset()
		build.mercenaryTab:Load(saved)
		assert.are.same(saved, savedState())

		build.calcsTab:Load({ { elem = "Input", attrib = { name = "showMinion", boolean = "true" } } })
		assert.are.equal("PLAYER_MINION", build.calcsTab.input.actor)
	end)

	it("calculates the selected actor and explicitly selected Full DPS", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", {
			includeInFullDPS = true,
			count = 2,
			skillPart = 1,
			supports = { { id = "AddedLightningHigh", tier = 3 } },
		})
		local env = calculate()
		assert.is_table(env.mercenary)
		assert.are.equal("Mercenary", env.mercenary.type)
		assert.are.equal(68, env.mercenary.level)
		assert.are.equal(2160, env.mercenary.output.Life)
		assert.is_true(env.mercenary.output.CombinedDPS > 0)
		assert.are.equal(1, env.mercenary.output.TrapThrowCount)
		assert.are.equal(-90, env.mercenary.modDB:Sum("INC", nil, "DamageTaken"))
		assert.are.near(0.2, env.mercenary.modDB:More({ flags = ModFlag.Dot }, "DamageTaken"), 10 ^ -9)
		-- The permanent-hire Damage penalty belongs to the constructed Mercenary
		-- actor, not to the Noble Blood node that allows hiring one.
		local penalty = MercenaryTools.permanentDamageMore(env.mercenary.level, build.data.mercenaries.permanentMercenaryDamageMore)
		assert.are.near(1 + penalty / 100, env.mercenary.modDB:More(nil, "Damage"), 10 ^ -9)
		assert.are.near(env.mercenary.output.CombinedDPS * 2, env.mercenary.output.FullDPS, 10 ^ -6)
		assert.are.near(env.mercenary.output.FullDPS, build.calcsTab.mainOutput.FullDPS, 10 ^ -6)
		assert.is_table(env.mercenary.output.SkillDPS)
		assert.is_number(env.mercenary.output.FullDotDPS)
		assert.is_true(#env.mercenary.output.SkillDPS > 0)
		assert.is_nil(env.minion)
		local fullDPSWithoutPlayerAura = env.mercenary.output.FullDPS
		build.skillsTab:PasteSocketGroup("Zealotry 20/0  1")
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.AffectedByZealotry)
		assert.is_true(env.mercenary.output.FullDPS > fullDPSWithoutPlayerAura)
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		env = calculate()
		assert.is_true(build.calcsTab.mainOutput.FullDPS > env.mercenary.output.FullDPS)

		build.calcsTab.input.actor = "MERCENARY"
		build.buildFlag = true
		runCallback("OnFrame")
		assert.are.near(env.mercenary.output.CombinedDPS, build.calcsTab.calcsOutput.CombinedDPS, 10 ^ -6)
		build.calcsTab.input.actor = "MERCENARY_MINION"
		build.buildFlag = true
		runCallback("OnFrame")
		assert.matches("unavailable", build.calcsTab.calcsOutput.ActorUnavailableMessage)
	end)

	it("scales found-area level, gem levels, and exclusive extracted skills", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { foundAreaLevel = 40 })
		assert.are.equal(40, calculate(30).mercenary.level)
		assert.are.equal(60, calculate(60).mercenary.level)
		build.mercenaryTab.profile.foundAreaLevel = 68
		assert.are.equal(68, calculate(68).mercenary.level)
		build.mercenaryTab.profile.foundAreaLevel = 80
		assert.are.equal(80, calculate(90).mercenary.level)

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { foundAreaLevel = 100 })
		local env = calculate(85)
		assert.are.equal(100, env.mercenary.level)
		assert.is_number(env.mercenary.averageDamage)
		assert.is_true(env.mercenary.averageDamage > 0)

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { foundAreaLevel = 82 })
		local level82Skill = assert(calculate(90).mercenary.mainSkill)
		assert.are.equal(26, level82Skill.activeEffect.level)
		assert.is_true(level82Skill.skillFlags.trap)
		assert.is_nil(level82Skill.skillFlags.selfCast)
		assert.are.equal(1260, level82Skill.skillData.LightningMin)
		assert.are.equal(3780, level82Skill.skillData.LightningMax)

		build.mercenaryTab.profile.foundAreaLevel = 83
		local level83Skill = assert(calculate(90).mercenary.mainSkill)
		assert.are.equal(26, level83Skill.activeEffect.level)
		assert.are.equal(1329, level83Skill.skillData.LightningMin)
		assert.are.equal(3986, level83Skill.skillData.LightningMax)

		build.mercenaryTab.profile.foundAreaLevel = 84
		assert.are.equal(27, assert(calculate(90).mercenary.mainSkill).activeEffect.level)

		configure("Crit1HShadow", "Crit1HShadowPhysSpell", "DonutCircleMercenary", { foundAreaLevel = 83, skillPart = 1 })
		local outer = calculate(83).mercenary
		assert.is_true(outer.mainSkill.skillFlags.hit)
		assert.is_true(outer.mainSkill.skillFlags.area)
		assert.are.equal(3167, outer.mainSkill.skillData.PhysicalMin)
		assert.are.equal(3500, outer.mainSkill.skillData.PhysicalMax)
		local outerDamageMore = outer.mainSkill.skillModList:More(outer.mainSkill.skillCfg, "Damage")
		build.mercenaryTab.profile.skills[1].skillPart = 2
		local centre = calculate(83).mercenary
		assert.are.equal("Centre", centre.mainSkill.skillPartName)
		assert.are.near(outerDamageMore * 1.5, centre.mainSkill.skillModList:More(centre.mainSkill.skillCfg, "Damage"), 10 ^ -9)

		configure("PhysConvertTemplar", "PhysConvertTemplarFire", "HolyFireMortarMercenary", { foundAreaLevel = 83, skillPart = 1 })
		local first = calculate(83).mercenary
		local firstHitDamageMore = first.mainSkill.skillModList:More(first.mainSkill.skillCfg, "Damage")
		build.mercenaryTab.profile.skills[1].skillPart = 2
		local secondHit = calculate(83).mercenary
		assert.are.equal("Second Hit", secondHit.mainSkill.skillPartName)
		assert.are.near(firstHitDamageMore * 0.4, secondHit.mainSkill.skillModList:More(secondHit.mainSkill.skillCfg, "Damage"), 10 ^ -9)

		configure("MeleeAOEMarauder", "MeleeAOEMarauderNonSlam", "WindSlashMercenary", { foundAreaLevel = 83 })
		local baseline = calculate(83).mercenary
		local baseDamage = baseline.modDB:Sum("INC", nil, "Damage")
		local baseSpeed = baseline.modDB:Sum("INC", nil, "Speed")
		local baseMovementSpeed = baseline.modDB:Sum("INC", nil, "MovementSpeed")
		table.insert(build.mercenaryTab.profile.skills, { id = "EnrageMercenary", enabled = true, count = 1, supports = { } })
		local enraged = calculate(83).mercenary
		assert.is_true(enraged.modDB.conditions.AffectedByEnrage)
		assert.are.equal(baseDamage + 35, enraged.modDB:Sum("INC", nil, "Damage"))
		assert.are.equal(baseSpeed + 40, enraged.modDB:Sum("INC", nil, "Speed"))
		assert.are.equal(baseMovementSpeed + 60, enraged.modDB:Sum("INC", nil, "MovementSpeed"))

		configure("Crit1HShadow", "Crit1HShadowPhysSpell", "TemporalAnomalyMercenary", { foundAreaLevel = 83 })
		assert.are.equal(-25, calculate(83).enemy.modDB:Sum("INC", nil, "ActionSpeed"))

		configure("MeleeAOEMarauder", "MeleeAOEMarauderPhysSlam", "VaalVitalityMercenary", { foundAreaLevel = 83 })
		local vitality = calculate(83)
		assert.are.equal(26, vitality.mercenary.mainSkill.activeEffect.level)
		assert.is_true(vitality.player.modDB.conditions.AffectedByVaalVitality)
		assert.are.near(580 / 60, vitality.player.modDB:Sum("BASE", nil, "LifeRegenPercent"), 10 ^ -9)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarSmite", "SSMHolySpectresMercenary", {
			foundAreaLevel = 83,
			includeInFullDPS = true,
			count = 4,
			skillMinionSkill = 2,
		})
		local mace = new("Item"):Item("Rarity: Normal\nDriftwood Club")
		local shield = new("Item"):Item("Rarity: Normal\nTwig Spirit Shield")
		mace.id, shield.id = 9050, 9051
		build.itemsTab.items[mace.id], build.itemsTab.items[shield.id] = mace, shield
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = mace.id, shield.id
		env = calculate(83)
		local summon = env.mercenary.mainSkill
		local fireball = env.mercenaryMinion.mainSkill
		assert.are.equal(83, env.mercenaryMinion.level)
		assert.are.equal("HolyFireElementalFireball", fireball.activeEffect.grantedEffect.id)
		assert.are.equal(2, fireball.activeEffect.level)
		assert.are.equal(1654, fireball.skillData.FireMin)
		assert.are.equal(2561, fireball.skillData.FireMax)
		assert.are.equal(2, summon.activeEffect.srcInstance.skillMinionSkill)
		assert.is_true(env.mercenaryMinion.output.TotalDPS > 0)
		assert.are.near(env.mercenaryMinion.output.TotalDPS * 4 + env.mercenary.output.FullDotDPS, env.mercenary.output.FullDPS, 10 ^ -6)

		equipmentSlot("Weapon 1").selItemId = 0
		equipmentSlot("Weapon 2").selItemId = 0
		configure("ChaosMinionWitch", "ChaosMinionWitchChaosHit", "SSMMercenarySoulrendOrb", {
			foundAreaLevel = 83,
			skillMinionSkill = 2,
		})
		env = calculate(83)
		assert.are.equal("GSRitualChaosPulse", env.mercenaryMinion.mainSkill.activeEffect.grantedEffect.id)
		assert.is_true(env.mercenaryMinion.modDB:Flag(nil, "Condition:CannotBeDamaged"))
		assert.is_true(env.mercenaryMinion.modDB:Flag(nil, "AlliesAurasCannotAffectSelf"))
	end)

	it("applies permanent bases, taper, charges, and small passives", function()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local env = calculate(83)
		local mercenary = assert(env.mercenary)
		assert.are.equal(build.data.monsterConstants["base_critical_strike_multiplier"] - 100, mercenary.modDB:Sum("BASE", nil, "CritMultiplier"))
		assert.are.equal(build.data.monsterConstants["critical_ailment_dot_multiplier_+"], mercenary.modDB:Sum("BASE", { skillCond = { CriticalStrike = true } }, "DotMultiplier"))
		assert.are.near(298.29000854492, mercenary.averageDamage, 10 ^ -9)
		assert.are.equal(3320, mercenary.output.Life)
		assert.are.near(713.8, mercenary.output.LifeRegen, 10 ^ -9)
		assert.are.equal(150, mercenary.modDB:Sum("INC", nil, "Life"))
		assert.are.equal(100, mercenary.modDB:Sum("INC", nil, "Armour"))
		assert.are.equal(295, mercenary.modDB:Sum("INC", nil, "Damage"))
		assert.are.equal(208, mercenary.modDB:Sum("BASE", nil, "Str"))
		assert.are.equal(21, mercenary.modDB:Sum("BASE", nil, "Dex"))
		assert.are.equal(21, mercenary.modDB:Sum("BASE", nil, "Int"))
		local penalty = MercenaryTools.permanentDamageMore(mercenary.level, build.data.mercenaries.permanentMercenaryDamageMore)
		assert.are.near(1 + penalty / 100, mercenary.modDB:More(nil, "Damage"), 10 ^ -9)

		local function sourceMore(modDB)
			for _, value in ipairs(modDB:Tabulate("MORE", nil, "Damage")) do
				if value.mod.source == "Permanent Mercenary" then
					return value.mod.value
				end
			end
			return 0
		end
		local expected = { [44] = 0, [45] = 0, [46] = -1, [82] = -29, [83] = -30 }
		for _, level in ipairs({ 44, 45, 46, 82, 83 }) do
			configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", {
				foundAreaLevel = level,
			})
			env = calculate(level)
			assert.are.equal(level, env.mercenary.level)
			assert.are.equal(expected[level], sourceMore(env.mercenary.modDB), "skill penalty at "..level)
			assert.is_true(env.mercenary.output.CombinedDPS > 0)
		end
		for _, level in ipairs({ 44, 45, 46, 82, 83 }) do
			configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary", {
				foundAreaLevel = level,
			})
			env = calculate(level)
			assert.is_table(env.mercenaryMinion)
			assert.are.equal(expected[level], sourceMore(env.mercenaryMinion.modDB), "minion penalty at "..level)
			assert.is_true(env.mercenaryMinion.output.TotalDPS > 0)
		end

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		env = calculate()
		local modDB = env.mercenary.modDB
		local cfg = env.mercenary.mainSkill.skillCfg
		local constants = build.data.characterConstants
		local function chargeMod(modType, name, multiplier)
			local charges = modDB.multipliers[multiplier] or 0
			modDB.multipliers[multiplier] = charges + 1
			for _, value in ipairs(modDB:Tabulate(modType, cfg, name)) do
				for _, tag in ipairs(value.mod) do
					if tag.type == "Multiplier" and tag.var == multiplier then
						local oneMoreCharge = modDB:EvalMod(value.mod, cfg)
						modDB.multipliers[multiplier] = charges + 2
						local delta = modDB:EvalMod(value.mod, cfg) - oneMoreCharge
						modDB.multipliers[multiplier] = charges
						return delta
					end
				end
			end
			modDB.multipliers[multiplier] = charges
			error("Missing "..multiplier.." bonus for "..name)
		end

		assert.are.near(constants["critical_strike_chance_+%_per_power_charge"], chargeMod("INC", "CritChance", "PowerCharge"), 10 ^ -9)
		assert.are.near(constants["object_inherent_damage_+%_final_per_frenzy_charge"], chargeMod("MORE", "Damage", "FrenzyCharge"), 10 ^ -9)
		assert.are.near(constants["physical_damage_reduction_%_per_endurance_charge"], chargeMod("BASE", "PhysicalDamageReduction", "EnduranceCharge"), 10 ^ -9)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		local baseline = calculate()
		local mercenaryLife = baseline.mercenary.modDB:Sum("INC", nil, "Life")
		local minionLife = baseline.mercenaryMinion.modDB:Sum("INC", nil, "Life")
		local function hasDamageSmallPassive(modDB)
			for _, value in ipairs(modDB:Tabulate("INC", nil, "Damage")) do
				if value.mod.value == 15 then return true end
			end
			return false
		end
		assert.is_true(hasDamageSmallPassive(baseline.mercenary.modDB))
		assert.is_true(hasDamageSmallPassive(baseline.mercenaryMinion.modDB))

		allocate("Mercenary Life, Light Radius")
		env = calculate()
		assert.are.equal(mercenaryLife + 15, env.mercenary.modDB:Sum("INC", nil, "Life"))
		assert.are.equal(minionLife + 15, env.mercenaryMinion.modDB:Sum("INC", nil, "Life"))
	end)

	it("applies and shows actor-local Configuration", function()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local focusedDamage = {
			name = "Damage", type = "INC", value = 20, source = "Mercenary Config Test", flags = 0, keywordFlags = 0,
			{ type = "Condition", var = "Focused" },
		}
		local helmet = {
			id = 9036, name = "Mercenary Config Test", type = "Helmet", base = { type = "Helmet" }, rarity = "RARE",
			requirements = { str = 1 }, grantedSkills = { }, modList = { focusedDamage },
		}
		build.itemsTab.items[helmet.id] = helmet
		equipmentSlot("Helmet").selItemId = helmet.id

		local env = calculate()
		local baseDamage = env.mercenary.modDB:Sum("INC", nil, "Damage")
		local focusedConditionSource
		for _, mod in ipairs(env.conditionsUsed.Focused or { }) do
			if mod.source == focusedDamage.source then focusedConditionSource = mod.source end
		end
		assert.are.equal(focusedDamage.source, focusedConditionSource)
		assert.is_false(build.configTab.varControls.conditionFocused.shown())
		assert.is_false(build.configTab.varControls.detonateDeadCorpseLife.shown())
		build.configTab:SetViewActor("mercenary")
		assert.is_true(build.configTab.varControls.conditionFocused.shown())
		assert.is_true(build.configTab.varControls.detonateDeadCorpseLife.shown())

		local corpseLifeConfig
		for _, varData in ipairs(configOptions) do
			if varData.var == "detonateDeadCorpseLife" then corpseLifeConfig = varData break end
		end
		assert.is_false(configVisibility.isRelevantForBuild(assert(corpseLifeConfig), build, "player"))
		assert.is_true(configVisibility.isRelevantForBuild(corpseLifeConfig, build, "mercenary"))

		build.configTab:EnsureActorConfig(build.configTab.configSets[build.configTab.activeConfigSetId])
		build.configTab.configSets[build.configTab.activeConfigSetId].actors.mercenary.input.conditionFocused = true
		build.configTab.configSets[build.configTab.activeConfigSetId].actors.mercenary.input.detonateDeadCorpseLife = 12345
		env = calculate()
		assert.is_true(env.mercenary.modDB:GetCondition("Focused"))
		assert.are.equal(baseDamage + focusedDamage.value, env.mercenary.modDB:Sum("INC", nil, "Damage"))
		assert.are.equal(12345, env.mercenary.mainSkill.skillData.corpseLife)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local stationaryDamage = {
			name = "Damage", type = "INC", value = 20, source = "Mercenary Stationary Test", flags = 0, keywordFlags = 0,
			{ type = "ActorCondition", var = "Stationary" },
		}
		helmet = {
			id = 9051, name = "Mercenary Stationary Test", type = "Helmet", base = { type = "Helmet" }, rarity = "RARE",
			requirements = { str = 1 }, grantedSkills = { }, modList = { stationaryDamage },
		}
		build.itemsTab.items[helmet.id] = helmet
		equipmentSlot("Helmet").selItemId = helmet.id
		calculate()
		assert.is_false(build.configTab.varControls.conditionStationary.shown())
		build.configTab:SetViewActor("mercenary")
		assert.is_true(build.configTab.varControls.conditionStationary.shown())

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local leechingDamage = {
			name = "Damage", type = "INC", value = 20, source = "Mercenary Leech Test", flags = 0, keywordFlags = 0,
			{ type = "Condition", var = "Leeching" },
		}
		helmet = {
			id = 9050, name = "Mercenary Leech Test", type = "Helmet", base = { type = "Helmet" }, rarity = "RARE",
			requirements = { str = 1 }, grantedSkills = { }, modList = { leechingDamage },
		}
		build.itemsTab.items[helmet.id] = helmet
		equipmentSlot("Helmet").selItemId = helmet.id

		local configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.input.conditionLeechingLife = true
		calculate()

		local leechingLifeConfig, leechingConfig
		for _, varData in ipairs(configOptions) do
			if varData.var == "conditionLeechingLife" then
				leechingLifeConfig = varData
			elseif varData.var == "conditionLeeching" then
				leechingConfig = varData
			end
		end
		assert.is_false(configVisibility.isRelevantForBuild(assert(leechingLifeConfig), build, "player"))
		assert.is_false(configVisibility.isRelevantForBuild(assert(leechingConfig), build, "player"))
		assert.is_true(configVisibility.isRelevantForBuild(leechingConfig, build, "mercenary"))

		configSet.actors.mercenary.input.conditionLeechingLife = true
		build.configTab:SetViewActor("mercenary")
		assert.is_false(configVisibility.isRelevantForBuild(leechingLifeConfig, build, "player"))
		assert.is_true(configVisibility.isRelevantForBuild(leechingLifeConfig, build, "mercenary"))

		build.configTab:SetViewActor("player")
		assert.is_true(build.configTab.varControls.conditionLeechingLife.shown())
		local label = build.configTab.varControls.conditionLeechingLife.label
		if type(label) == "function" then
			label = label()
		end
		assert.matches("%^xDD0022", assert(label))

		resetBuild()
		configureSkill("VigilantStrikeMercenary")
		local mace = new("Item"):Item("Rarity: Normal\nDriftwood Club")
		mace.id = 9041
		build.itemsTab.items[mace.id] = mace
		equipmentSlot("Weapon 1").selItemId = mace.id
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		local bypassed = assert(calculate().mercenary)
		configSet.actors.mercenary.input.VigilantStrikeBypassCD = false
		local onCooldown = assert(calculate().mercenary)
		assert.is_true(bypassed.output.Speed > onCooldown.output.Speed)
		build.configTab:SetViewActor("mercenary")
		assert.is_true(build.configTab.varControls.VigilantStrikeBypassCD.shown())
		build.configTab:SetViewActor("player")
		assert.is_false(build.configTab.varControls.VigilantStrikeBypassCD.shown())

		resetBuild()
		configureSkill("ToxicRainMercenary")
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9042, 9043
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		local baseline = assert(calculate().mercenary)
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.toxicRainPodOverlap = 5
		local overlapped = assert(calculate().mercenary)
		assert.are.equal(5, overlapped.mainSkill.skillData.podOverlapMultiplier)
		assert.is_true(overlapped.output.CombinedDPS > baseline.output.CombinedDPS)
		build.configTab:SetViewActor("mercenary")
		assert.is_true(build.configTab.varControls.toxicRainPodOverlap.shown())

		resetBuild()
		configureSkill("KineticBlastAltMercenary")
		local wand = new("Item"):Item("Rarity: Normal\nDriftwood Wand")
		local shield = new("Item"):Item("Rarity: Normal\nTwig Spirit Shield")
		wand.id, shield.id = 9060, 9061
		build.itemsTab.items[wand.id], build.itemsTab.items[shield.id] = wand, shield
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = wand.id, shield.id
		local profile = build.mercenaryTab.profile
		table.insert(profile.skills, { id = "FlameWallMercenary", enabled = true, count = 1, supports = { } })
		build.mercenaryTab:Changed()
		baseline = assert(calculate().mercenary)
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.flameWallAddedDamage = true
		local flamed = assert(calculate())
		local fireCfg = { flags = ModFlag.Projectile }
		assert.is_true(flamed.mercenary.modDB:GetCondition("FlameWallAddedDamage"))
		assert.is_true(flamed.mercenary.modDB:Sum("BASE", fireCfg, "FireMin") > baseline.modDB:Sum("BASE", fireCfg, "FireMin"))
		assert.is_true(flamed.mercenary.output.CombinedDPS > baseline.output.CombinedDPS)
		build.configTab:SetViewActor("mercenary")
		assert.is_true(build.configTab.varControls.flameWallAddedDamage.shown())

		resetBuild()
		configure("EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary")
		bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9038, 9039
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id

		baseline = assert(calculate().mercenary.output)
		build.configTab:EnsureActorConfig(build.configTab.configSets[build.configTab.activeConfigSetId])
		build.configTab.configSets[build.configTab.activeConfigSetId].actors.mercenary.input.buffOnslaught = true
		local configured = assert(calculate().mercenary)

		assert.is_true(configured.modDB:GetCondition("Onslaught"))
		assert.is_true(configured.output.Speed > baseline.Speed)
		assert.is_true(configured.output.CombinedDPS > baseline.CombinedDPS)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { foundAreaLevel = 68 })
		local forbiddenFlask = new("Item"):Item("Rarity: Normal\nSmall Life Flask")
		forbiddenFlask.id = 9020
		build.itemsTab.items[forbiddenFlask.id] = forbiddenFlask
		build.itemsTab.activeItemSet["Flask 1"].selItemId = forbiddenFlask.id
		assert.is_table(calculate(83).mercenary)
		assert.not_matches("Flask 1", table.concat(build.mercenaryTab:GetErrors(), "\n"))
		build.itemsTab.activeItemSet["Flask 1"].selItemId = 0

		build.characterLevel = 48
		assert.is_table(calculate(83).mercenary)
		assert.matches("20 below", table.concat(build.mercenaryTab:GetErrors(), "\n"))
		build.characterLevel = 49
		assert.is_table(calculate(83).mercenary)
		build.characterLevel = 90

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1")
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		local fullLifeMod = "Minions have 100% chance to deal double damage while they are on full life"
		configSet.customModsList[1].text = fullLifeMod
		configSet.actors.mercenary.customModsList[1].text = fullLifeMod
		configSet.actors.mercenary.input.minionsConditionFullLife = true
		env = calculate()
		assert.is_table(env.mercenaryMinion)
		assert.is_table(env.minion)
		assert.is_true(env.mercenaryMinion.modDB:Flag(nil, "Condition:FullLife"))
		assert.is_not_true(env.minion.modDB:Flag(nil, "Condition:FullLife"))
		assert.are.equal(100, env.mercenaryMinion.modDB:Sum("BASE", nil, "DoubleDamageChance"))
		assert.are.equal(0, env.minion.modDB:Sum("BASE", nil, "DoubleDamageChance"))

		configSet.actors.mercenary.input.minionsConditionFullLife = nil
		configSet.input.minionsConditionFullLife = true
		env = calculate()
		assert.is_not_true(env.mercenaryMinion.modDB:Flag(nil, "Condition:FullLife"))
		assert.is_true(env.minion.modDB:Flag(nil, "Condition:FullLife"))
		assert.are.equal(0, env.mercenaryMinion.modDB:Sum("BASE", nil, "DoubleDamageChance"))
		assert.are.equal(100, env.minion.modDB:Sum("BASE", nil, "DoubleDamageChance"))

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		fullLifeMod = "Minions have 100% chance to deal double damage while they are on full life"
		configSet.actors.mercenary.customModsList[1].text = fullLifeMod
		env = calculate()
		assert.is_table(env.mercenaryMinion)
		assert.is_nil(env.minion)

		local fullLifeConfig
		for _, varData in ipairs(configOptions) do
			if varData.var == "minionsConditionFullLife" then fullLifeConfig = varData break end
		end
		assert.is_false(configVisibility.isRelevantForBuild(assert(fullLifeConfig), build, "player"))
		assert.is_true(configVisibility.isRelevantForBuild(fullLifeConfig, build, "mercenary"))
		build.configTab:SetViewActor("player")
		assert.is_false(build.configTab.varControls.minionsConditionFullLife.shown())
		build.configTab:SetViewActor("mercenary")
		assert.is_true(build.configTab.varControls.minionsConditionFullLife.shown())

		configSet.actors.mercenary.customModsList[1].text = ""
		configSet.customModsList[1].text = fullLifeMod
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1")
		env = calculate()
		assert.is_table(env.minion)
		assert.is_true(configVisibility.isRelevantForBuild(fullLifeConfig, build, "player"))
		assert.is_false(configVisibility.isRelevantForBuild(fullLifeConfig, build, "mercenary"))
		build.configTab:SetViewActor("player")
		assert.is_true(build.configTab.varControls.minionsConditionFullLife.shown())
		build.configTab:SetViewActor("mercenary")
		assert.is_false(build.configTab.varControls.minionsConditionFullLife.shown())

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.minionsConditionCreatedRecently = true
		env = calculate()
		assert.is_true(env.mercenary.modDB:Flag(nil, "Condition:MinionsCreatedRecently"))
		assert.is_not_true(env.player.modDB:Flag(nil, "Condition:MinionsCreatedRecently"))

		resetBuild()
		configure("EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary")
		bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9060, 9061
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		assert.are.equal(40, configSet.actors.mercenary.placeholder.projectileDistance)
		env = calculate()
		assert.are.equal(40, env.mercenary.mainSkill.skillCfg.skillDist)

		configSet.actors.mercenary.customModsList[1].text = "Projectiles gain Damage as they travel farther, dealing up to 30% more Damage with Hits and Ailments"
		configSet.input.projectileDistance = 70
		local function damageMore()
			local rampEnv = calculate()
			local skill = assert(rampEnv.mercenary, table.concat(rampEnv.mercenaryCalculationErrors or { }, "\n")).mainSkill
			return skill.skillModList:More(skill.skillCfg, "Damage")
		end
		local atDefault = damageMore()
		configSet.actors.mercenary.input.projectileDistance = 70
		local atSeventy = damageMore()
		assert.is_true(atSeventy > atDefault)
		configSet.actors.mercenary.input.projectileDistance = 40
		configSet.input.projectileDistance = 10
		assert.are.near(atDefault, damageMore(), 10 ^ -9)

		resetBuild()
		configureSkill("HolyFlameTotemMercenary")
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.input.TotemsSummoned = 5
		local mercenary = assert(calculate().mercenary, table.concat(build.calcsTab.mainEnv.mercenaryCalculationErrors or { }, "\n"))
		local defaultCount = mercenary.output.ActiveTotemLimit
		assert.is_true(defaultCount >= 1)
		assert.are.equal(defaultCount, mercenary.output.TotemsSummoned)
		configSet.actors.mercenary.input.TotemsSummoned = 3
		mercenary = assert(calculate().mercenary)
		assert.are.equal(3, mercenary.output.TotemsSummoned)
		configSet.input.TotemsSummoned = 1
		mercenary = assert(calculate().mercenary)
		assert.are.equal(3, mercenary.output.TotemsSummoned)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.input.warcryMode = "AVERAGE"
		configSet.actors.mercenary.input.warcryMode = "AVERAGE"
		local average = assert(calculate().mercenary).output.WarcryEffectMod
		assert.is_true(average > 0)
		configSet.actors.mercenary.input.warcryMode = "MAX"
		local maxHit = assert(calculate().mercenary).output.WarcryEffectMod
		assert.is_true(maxHit > average)
		configSet.input.warcryMode = "MAX"
		configSet.actors.mercenary.input.warcryMode = "AVERAGE"
		assert.are.near(average, assert(calculate().mercenary).output.WarcryEffectMod, 10 ^ -9)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.input.physMode = "FIRE"
		configSet.actors.mercenary.input.physMode = "COLD"
		local origBuildModList = build.configTab.BuildModList
		function build.configTab:BuildModList(...)
			origBuildModList(self, ...)
			self.mercenaryModList:NewMod("MinionModifier", "LIST", {
				mod = modLib.createMod("PhysicalDamageGainAsRandom", "BASE", 35)
			}, "Test")
		end
		local function gainAs(physEnv)
			local minion = assert(physEnv.mercenaryMinion, table.concat(physEnv.mercenaryCalculationErrors or { }, "\n"))
			local skill = minion.mainSkill
			return skill.skillModList:Sum("BASE", skill.skillCfg, "PhysicalDamageGainAsFire"),
				skill.skillModList:Sum("BASE", skill.skillCfg, "PhysicalDamageGainAsCold"),
				skill.skillModList:Sum("BASE", skill.skillCfg, "PhysicalDamageGainAsLightning")
		end
		local fire, cold, lightning = gainAs(calculate())
		assert.are.equal(0, fire)
		assert.are.equal(35, cold)
		assert.are.equal(0, lightning)
		configSet.input.physMode = "LIGHTNING"
		fire, cold, lightning = gainAs(calculate())
		assert.are.equal(0, fire)
		assert.are.equal(35, cold)
		assert.are.equal(0, lightning)
		configSet.actors.mercenary.input.physMode = "FIRE"
		fire, cold, lightning = gainAs(calculate())
		assert.are.equal(35, fire)
		assert.are.equal(0, cold)
		assert.are.equal(0, lightning)
	end)

	it("shares enemy Wither once and isolates actor-local keystones, Exposure, Cruelty, and flask recovery", function()
		configureSkill("WitherTotemMercenary")
		local staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9044
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		local profile = build.mercenaryTab.profile
		table.insert(profile.skills, { id = "EssenceDrainAltMercenary", enabled = true, includeInFullDPS = true, count = 1, supports = { } })
		build.mercenaryTab:Changed()
		assert(calculate())
		assert.is_true(build.configTab.varControls.multiplierWitheredStackCount.shown())
		profile.mainSkillId = "EssenceDrainAltMercenary"
		build.mercenaryTab:Changed()
		local baseline = assert(calculate())
		local baselineDot = baseline.mercenary.output.TotalDot or 0
		build.configTab.input.multiplierWitheredStackCount = 15
		local withered = assert(calculate())
		local witherMods = 0
		for _, mod in ipairs(build.configTab.enemyModList) do
			if mod.name == "Multiplier:WitheredStack" then
				witherMods = witherMods + 1
				assert.are.equal(15, mod.value)
			end
		end
		assert.are.equal(1, witherMods)
		assert.is_not_nil(withered.enemy.modDB.mods["Multiplier:WitheredStack"])
		assert.is_true(withered.enemy.modDB:Sum("INC", nil, "ChaosDamageTaken") > 0)
		assert.is_true((withered.mercenary.output.TotalDot or 0) > baselineDot)

		resetBuild()
		configureSkill("WitherTotemMercenary")
		staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9045
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		build.skillsTab:PasteSocketGroup("Wither 20/0  1")
		build.configTab.input.multiplierWitheredStackCount = 15
		local env = assert(calculate())
		local witheredSources = 0
		for _, mod in ipairs(env.enemy.modDB.mods["ChaosDamageTaken"] or { }) do
			if mod.source == "Withered" then
				witheredSources = witheredSources + 1
			end
		end
		assert.are.equal(1, witheredSources)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nCruelty 20/0  1\n")
		env = calculate()
		assert.are.equal(40, env.player.modDB.multipliers.Cruelty)
		assert.is_nil(env.mercenary.modDB.multipliers.Cruelty)

		resetBuild()
		build.skillsTab:PasteSocketGroup("Spark 20/0  1\nAwakened Fire Penetration 20/0  1\n")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		env = calculate()
		assert.is_true(env.player.modDB.conditions.CanApplyFireExposure)
		assert.is_not_true(env.mercenary.modDB.conditions.CanApplyFireExposure)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "MoltenStrikeHolyMercenary", {
			supports = { { id = "HolyMoltenStrikeSpecificLightningExposureHigh", tier = 3 } },
		})
		staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9101
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		build.skillsTab:PasteSocketGroup("Spark 20/0  1")
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.CanApplyLightningExposure)
		assert.is_not_true(env.player.modDB.conditions.CanApplyLightningExposure)

		resetBuild()
		allocate("Precise Technique")
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "TectonicSlamFireMercenary")
		env = calculate()
		assert.is_true(env.keystonesAdded["Precise Technique"])
		assert.is_true(env.player.output.PreciseTechnique)
		assert.is_not_true(env.mercenary.calcEnv.keystonesAdded["Precise Technique"])
		assert.is_not_true(env.mercenary.output.PreciseTechnique)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "TectonicSlamFireMercenary")
		local helmet = new("Item"):Item([[Rarity: Rare
Precise Technique Test Helm
Iron Hat
--------
Precise Technique
]])
		build.itemsTab:AddItem(helmet, true)
		equipmentSlot("Helmet").selItemId = helmet.id
		env = calculate()
		assert.is_nil(env.mercenaryCalculationErrors and env.mercenaryCalculationErrors[1], table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_not_true(env.keystonesAdded["Precise Technique"])
		assert.is_not_true(env.player.output.PreciseTechnique)
		assert.is_true(env.mercenary.calcEnv.keystonesAdded["Precise Technique"])
		assert.is_true(env.mercenary.output.PreciseTechnique)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local lifeFlask = new("Item"):Item("Rarity: Normal\nEternal Life Flask")
		build.itemsTab:AddItem(lifeFlask, true)
		build.itemsTab.slots["Flask 1"].selItemId = lifeFlask.id
		build.itemsTab.activeItemSet["Flask 1"].selItemId = lifeFlask.id
		env = calculate()
		assert.is_true((env.player.output.LifeFlaskRecovery or 0) > 0)
		assert.are.equal(0, env.mercenary.output.LifeFlaskRecovery or 0)
		assert.are.equal(0, env.mercenary.output.LifeFlaskCharges or 0)
		assert.are_not.equal(env.itemModDB, env.mercenary.calcEnv.itemModDB)
	end)

	it("calculates extracted skill DPS, parts, exerts, and on-hit curses", function()
		configure("MiscScion", "MiscScionPhysDot", "BladeVortexAltMercenary", { includeInFullDPS = true })
		local env = calculate()
		local activeSkill = env.mercenary.mainSkill
		assert.are.near(env.mercenary.averageDamage * 366 / 6000, activeSkill.skillData.PhysicalDot, 10 ^ -9)
		assert.are.equal(5, activeSkill.skillData.corruptedBloodStacks)
		assert.is_true(env.mercenary.output.CorruptingBloodDPS > 0)
		assert.are.near(env.mercenary.output.CombinedDPS, env.mercenary.output.FullDPS, 10 ^ -6)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local mercenary = assert(calculate(83).mercenary)
		assert.is_true(mercenary.mainSkill.skillData.explodeCorpse)
		assert.are.equal("Fire", mercenary.mainSkill.skillData.corpseExplosionDamageType)
		assert.are.near(0.08, mercenary.mainSkill.skillData.corpseExplosionLifeMultiplier, 10 ^ -9)
		-- Found-area 68 is inside the 3.29.1 taper, so this hit includes -18% more Damage
		-- rather than the -30% endgame cap.
		assert.are.near(1984.5, mercenary.output.AverageHit, 10 ^ -9)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "TectonicSlamFireMercenary")
		local profile = build.mercenaryTab.profile
		profile.skills = {
			{ id = "TectonicSlamFireMercenary", enabled = true, includeInFullDPS = false, count = 1, supports = { } },
			{ id = "InfernalCryMercenary", enabled = true, includeInFullDPS = false, count = 1, supports = { } },
		}
		profile.mainSkillId = "TectonicSlamFireMercenary"
		build.mercenaryTab:Changed()
		local mace = new("Item"):Item("Rarity: Normal\nDriftwood Maul")
		mace.id = 9060
		build.itemsTab.items[mace.id] = mace
		equipmentSlot("Weapon 1").selItemId = mace.id
		env = calculate()
		assert.is_true(env.mercenary.modDB:Sum("BASE", nil, "NumInfernalExerts") > 0)
		assert.is_true(env.mercenary.modDB:Sum("BASE", nil, "Multiplier:ExertingWarcryCount") > 0)

		resetBuild()
		configure("NonEleBowRanger", "NonEleBowRangerPhys", "BarrageAltMercenary", { skillPart = 2 })
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9018, 9017
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id

		local skill = assert(calculate(83).mercenary.mainSkill)
		assert.are.equal("All Projectiles", skill.skillPartName)
		assert.are.equal(6, skill.skillData.barrageFinalVolleyAdditionalProjectiles)
		assert.are.equal(16, skill.skillData.dpsMultiplier)

		resetBuild()
		configure("MeleeAOEStrikeDuelist", "MeleeAOEStrikeDuelistCyclone", "VaalDoubleStrikeMercenary")
		local sword = new("Item"):Item("Rarity: Normal\nCorroded Blade")
		sword.id = 9019
		build.itemsTab.items[sword.id] = sword
		equipmentSlot("Weapon 1").selItemId = sword.id
		skill = assert(calculate(83).mercenary.mainSkill)
		assert.are.equal(2, skill.skillData.dpsMultiplier)

		resetBuild()
		configure("EleBowRanger", "EleBowRangerClones", "VaalIceShotMercenary", {
			supports = { { id = "MultipleProjectilesHigh", tier = 3 } },
		})
		bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9020, 9021
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		env = calculate(83)
		skill = assert(env.mercenary.mainSkill)
		assert.are.equal(6, skill.skillData.vaalIceShotMirageCount)
		assert.is_true(env.mercenary.output.ProjectileCount > 1)
		assert.are.equal(7, skill.skillData.dpsMultiplier)

		resetBuild()
		configure("MeleeStrikesMarauder", "MeleeStrikesMaraduerPhys", "HeavyStrikeMercenary")
		mace = new("Item"):Item("Rarity: Normal\nDriftwood Club")
		mace.id = 9012
		build.itemsTab.items[mace.id] = mace
		equipmentSlot("Weapon 1").selItemId = mace.id
		env = calculate()
		local foundVulnerability
		for _, activeSkill in ipairs(env.mercenary.activeSkillList) do
			if activeSkill.activeEffect.grantedEffect.id == "Vulnerability" then foundVulnerability = true break end
		end
		assert.is_true(foundVulnerability)
		assert.is_true(env.enemy.modDB.conditions.Cursed)

		resetBuild()
		configure("MeleeAOEStrikeDuelist", "DivingDuelist", "ElementalHitColdOnlyMercenary")
		sword = new("Item"):Item("Rarity: Normal\nRusted Sword")
		sword.id = 9013
		build.itemsTab.items[sword.id] = sword
		equipmentSlot("Weapon 1").selItemId = sword.id
		env = calculate()
		assert.are.equal(3, env.mercenary.mainSkill.skillPart)
		assert.are.equal("Cold Attack", env.mercenary.mainSkill.skillPartName)
		assert.is_true(env.mercenary.output.CombinedDPS > 0)
		build.mercenaryTab.profile.skills[1].skillPart = 4
		build.mercenaryTab:Changed()
		env = calculate()
		assert.are.equal(4, env.mercenary.mainSkill.skillPart)
	end)

	it("applies Mercenary supports, including to minions", function()
		configure("EleBowRanger", "EleBowRangerFire", "BurningArrowMercenary", {
			supports = { { id = "ArrowNovaHigh", tier = 3 } },
		})
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9010, 9011
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		local mercenary = assert(calculate().mercenary)
		assert.is_truthy(mercenary.mainSkill.skillData.projectilesNova)
		assert.is_true(mercenary.output.CombinedDPS > 0)
		assert.are.equal("ArrowNovaHigh", build.mercenaryTab.profile.skills[1].supports[1].id)

		resetBuild()
		configure("EleBowRanger", "EleBowRangerClones", "MirrorArrowMercenary", {
			includeInFullDPS = true,
		})
		bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9016, 9017
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id

		local baseline = assert(calculate())
		local baselineMinionDPS = assert(baseline.mercenaryMinion.output.TotalDPS)
		local baselineFullDPS = assert(baseline.mercenary.output.FullDPS)
		local support = assert(build.data.mercenaries.supports.AddedColdHigh)
		build.mercenaryTab.profile.skills[1].supports = { { id = support.id, tier = support.variant } }
		build.mercenaryTab:Changed()

		local supported = assert(calculate())
		local minionSkill = assert(supported.mercenaryMinion.mainSkill)
		local hasSupport = false
		for _, effect in ipairs(minionSkill.effectList) do
			if effect.grantedEffect.mercenarySupportId == support.id then hasSupport = true break end
		end
		assert.is_true(hasSupport)
		assert.is_true(supported.mercenaryMinion.output.TotalDPS > baselineMinionDPS)
		assert.is_true(supported.mercenary.output.FullDPS > baselineFullDPS)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "FissureSlamMercenary", {
			supports = { { id = "FistOfWarHigh", tier = 3 } },
		})
		mercenary = assert(calculate(83).mercenary)
		assert.is_nil(mercenary.mainSkill.skillTypes[SkillType.Slam])
		local hasFistOfWar = false
		for _, effect in ipairs(mercenary.mainSkill.effectList) do
			if effect.grantedEffect.mercenarySupportId == "FistOfWarHigh" then hasFistOfWar = true break end
		end
		assert.is_true(hasFistOfWar)
		assert.are.equal(0, mercenary.output.FistOfWarUptimeRatio or 0)
	end)

	it("routes auras, warcries, curses, and party import/export", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "ZealotryMercenary")
		local auraEnv = calculate()
		assert.is_true(auraEnv.player.modDB.conditions.AffectedByZealotry)
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1")
		auraEnv = calculate()
		assert.is_true(auraEnv.minion.modDB.conditions.AffectedByZealotry)

		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		build.mercenaryTab.profile.skills[1].enabled = false
		build.mercenaryTab:Changed()
		local playerFullDPSWithoutMercenaryAura = calculate().player.output.FullDPS
		build.mercenaryTab.profile.skills[1].enabled = true
		build.mercenaryTab:Changed()
		auraEnv = calculate()
		assert.is_true(auraEnv.player.modDB.conditions.AffectedByZealotry)
		assert.is_true(auraEnv.player.output.FullDPS > playerFullDPSWithoutMercenaryAura)

		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		local minionEnv = calculate()
		assert.is_table(minionEnv.mercenaryMinion)
		assert.is_table(minionEnv.mercenary.mainSkill.minion)
		assert.are.equal(minionEnv.mercenary, minionEnv.mercenaryMinion.parent)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarSpectres", "AbsolutionMercenary")
		table.insert(build.mercenaryTab.profile.skills, {
			id = "BattlemagesCryMercenary",
			enabled = true,
			count = 1,
			supports = { },
		})
		local env = calculate()
		assert.is_table(env.mercenaryMinion)
		local affectedByBattlemagesCry = false
		for condition in pairs(env.mercenaryMinion.modDB.conditions) do
			if condition:find("Battlemage", 1, true) then affectedByBattlemagesCry = true break end
		end
		assert.is_true(affectedByBattlemagesCry)

		resetBuild()
		configure("MeleeStrikesMarauder", "MeleeStrikesMaraduerPhys", "EnduringCryMercenary")
		env = calculate()
		assert.is_true(env.player.modDB:Flag(nil, "UseEnduranceCharges"))
		assert.are.equal(3, env.player.modDB:Override(nil, "EnduranceCharges"))
		assert.are.near(10, env.player.modDB:Sum("BASE", nil, "LifeRegenPercent"), 10 ^ -9)

		resetBuild()
		local weapon = new("Item"):Item([[Rarity: Rare
Rallying Test Sword
Rusted Sword
--------
Adds 500 to 500 Physical Damage]])
		build.itemsTab:AddItem(weapon, true)
		build.itemsTab.activeItemSet["Weapon 1"].selItemId = weapon.id
		build.skillsTab:PasteSocketGroup("Rallying Cry 20/0  1")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		env = calculate()
		assert.is_true(rallyingWeaponFlat(env.mercenary, "PhysicalMin") > 0)
		assert.is_true(rallyingWeaponFlat(env.mercenary, "PhysicalMax") > 0)

		resetBuild()
		configure("MeleeAOEStrikeDuelist", "MeleeAOEStrikeDuelistCyclone", "RallyingCryMercenary")
		weapon = new("Item"):Item([[Rarity: Rare
Rallying Test Greatsword
Corroded Blade
--------
Adds 500 to 500 Physical Damage]])
		build.itemsTab:AddItem(weapon, true)
		equipmentSlot("Weapon 1").selItemId = weapon.id
		env = calculate()
		assert.is_true(rallyingWeaponFlat(env.player, "PhysicalMin") > 0)
		assert.is_true(rallyingWeaponFlat(env.player, "PhysicalMax") > 0)
		assert.are.equal(0, rallyingWeaponFlat(env.mercenary, "PhysicalMin"))

		resetBuild()
		weapon = new("Item"):Item([[Rarity: Rare
Rallying Test Sword
Rusted Sword
--------
Adds 500 to 500 Physical Damage]])
		build.itemsTab:AddItem(weapon, true)
		build.itemsTab.activeItemSet["Weapon 1"].selItemId = weapon.id
		build.skillsTab:PasteSocketGroup("Rallying Cry 20/0  1")
		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		env = calculate()
		local mercenaryFlat = rallyingWeaponFlat(env.mercenary, "PhysicalMin")
		local minionFlat = rallyingWeaponFlat(env.mercenaryMinion, "PhysicalMin")
		assert.is_true(mercenaryFlat > 0)
		assert.is_true(minionFlat > mercenaryFlat)
		assert.are.near(2, minionFlat / mercenaryFlat, 0.05)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		local average = calculate().player.modDB:Sum("BASE", nil, "PhysicalDamageGainAsFire")
		assert.is_true(average > 0)
		local configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.warcryMode = "MAX"
		local maxHit = calculate().player.modDB:Sum("BASE", nil, "PhysicalDamageGainAsFire")
		assert.is_true(maxHit > average)

		resetBuild()
		build.skillsTab:PasteSocketGroup("Zealotry 20/0  1")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.AffectedByZealotry)
		local spellCfg = { flags = ModFlag.Spell }
		local strongestEffect = env.mercenary.modDB:More(spellCfg, "Damage")

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "ZealotryMercenary")
		env = calculate()
		assert.are.near(strongestEffect, env.mercenary.modDB:More(spellCfg, "Damage"), 10 ^ -9)

		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		env = calculate()
		assert.is_true(env.mercenaryMinion.modDB.conditions.AffectedByZealotry)

		resetBuild()
		configure("ChaosMinionWitch", "ChaosMinionWitchDot", "BaneMercenary")
		table.insert(build.mercenaryTab.profile.skills, {
			id = "TemporalChainsMercenary",
			enabled = true,
			count = 1,
			supports = { },
		})
		env = calculate()
		assert.are.equal(1, env.mercenary.modDB.multipliers.CurseOnEnemy)
		assert.is_true(env.enemy.modDB.conditions.Cursed)

		resetBuild()
		build.skillsTab:PasteSocketGroup("Vulnerability 20/0  1")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		env = calculate()
		assert.is_true(env.enemy.modDB.conditions.Cursed)
		assert.are.equal(1, env.player.modDB.multipliers.CurseOnEnemy)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local baselineDamage = calculate().mercenary.modDB:Sum("INC", nil, "Damage")
		local auraMods = new("ModList"):ModList()
		auraMods:NewMod("Damage", "INC", 20, "Imported Party Aura")
		build.partyTab.actor.Aura = { Aura = { ImportedAura = { effectMult = 100, modList = auraMods } } }
		build.partyTab.actor.modDB:NewMod("PartyMemberMaximumEnduranceChargesEqualToYours", "FLAG", true, "Imported Party Member")
		build.partyTab.actor.output.EnduranceChargesMax = 9
		env = calculate()
		assert.are.equal(baselineDamage + 20, env.mercenary.modDB:Sum("INC", nil, "Damage"))
		assert.is_true(env.mercenary.modDB.conditions.AffectedByImportedAura)
		assert.are.equal(9, env.player.output.EnduranceChargesMax)
		assert.are_not.equals(9, env.mercenary.output.EnduranceChargesMax)

		configure("AurasMinionsTemplar", "AurasMinionsTemplarStaff", "HeraldOfPurityMercenary")
		env = calculate()
		assert.is_true(env.mercenaryMinion.modDB.conditions.AffectedByImportedAura)

		resetBuild()
		build.partyTab.enableExportBuffs = true
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "ZealotryMercenary")
		calculate()
		assert.is_table(build.partyTab.buffExports.Aura.Zealotry)
		assert.is_true(#build.partyTab.buffExports.Aura.Zealotry.modList > 0)

		resetBuild()
		build.partyTab.enableExportBuffs = true
		local function exportedEffect()
			calculate()
			return assert(build.partyTab.buffExports.Aura.Zealotry).effectMult
		end
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab:PasteSocketGroup("Zealotry 20/0  1")
		local playerGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		build.mainSocketGroup = 1
		build.configTab.input.customMods = "Zealotry has 200% increased Aura Effect"
		build.configTab:BuildModList()
		local playerStrong = exportedEffect()
		assert.are.near(3, playerStrong, 10 ^ -9)

		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "ZealotryMercenary")
		playerGroup.enabled = false
		local mercDefault = exportedEffect()
		assert.is_true(playerStrong > mercDefault)

		playerGroup.enabled = true
		assert.are.near(playerStrong, exportedEffect(), 10 ^ -9)

		build.configTab.input.customMods = "Zealotry has 50% reduced Aura Effect"
		build.configTab:BuildModList()
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.customModsList = { { title = "Default", enabled = true, text = "Zealotry has 200% increased Aura Effect" } }
		playerGroup.enabled = false
		local mercStrong = exportedEffect()
		build.mercenaryTab.profile.skills[1].enabled = false
		build.mercenaryTab:Changed()
		playerGroup.enabled = true
		local playerWeak = exportedEffect()
		assert.is_true(mercStrong > playerWeak)

		build.mercenaryTab.profile.skills[1].enabled = true
		build.mercenaryTab:Changed()
		assert.are.near(mercStrong, exportedEffect(), 10 ^ -9)
	end)

	it("applies Bestowed Knighthood taunt and Mercenary aura effect", function()
		local mods = assert(modLib.parseMod("Your Mercenary has 50% increased effect of Non-Curse Auras from Skills"))
		assert.are.equal("AuraEffect", mods[1].value.mod.name)

		allocate("Bestowed Knighthood")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local env = calculate()
		local auraCfg = { skillTypes = { [SkillType.Aura] = true } }
		assert.are.equal(50, env.mercenary.modDB:Sum("INC", auraCfg, "AuraEffect"))
		assert.are.equal(0, env.mercenary.modDB:Sum("INC", nil, "AuraEffectOnSelf"))
		assert.is_true(env.enemy.modDB.conditions.TauntedByMercenary)
		assert.are.near(0.9, env.player.modDB:More(nil, "DamageTaken"), 10 ^ -9)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "ZealotryMercenary")
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		env = calculate()
		local baseAuraMore = env.player.modDB:More({ flags = ModFlag.Spell }, "Damage")
		local baseFullDPS = env.player.output.FullDPS
		assert.is_true(env.player.modDB.conditions.AffectedByZealotry)
		assert.is_true(baseFullDPS > 0)

		allocate("Bestowed Knighthood")
		env = calculate()
		-- Aura stats are floored after effect, so 15% more * 1.5 becomes 22% more.
		assert.are.near(1 + math.floor((baseAuraMore - 1) * 100 * 1.5) / 100, env.player.modDB:More({ flags = ModFlag.Spell }, "Damage"), 10 ^ -9)
		assert.is_true(env.player.output.FullDPS > baseFullDPS)
	end)

	it("weights support-aura weapon mods against player Full DPS", function()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarSpectres", "WrathMercenary")
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		local itemsTab = build.itemsTab
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		local blankWand = new("Item"):Item("Rarity: Normal\nDriftwood Wand")
		local wrathWand = new("Item"):Item([[Rarity: Rare
Eagle Gnarl
Driftwood Wand
--------
Wrath has 40% increased Aura Effect]])
		itemsTab:AddItem(blankWand, true)
		itemsTab:AddItem(wrathWand, true)
		mercSet["Weapon 1"].selItemId = blankWand.id
		local env = calculate()
		assert.is_true(env.player.modDB.conditions.AffectedByWrath)
		local playerFullDPSWithout = env.player.output.FullDPS
		local mercenaryFullDPSWithout = env.mercenary.output.FullDPS or 0
		assert.is_true(playerFullDPSWithout > 0)

		mercSet["Weapon 1"].selItemId = wrathWand.id
		env = calculate()
		assert.is_true(env.player.output.FullDPS > playerFullDPSWithout)
		assert.are.equal(mercenaryFullDPSWithout, env.mercenary.output.FullDPS or 0)

		assert(itemsTab:SetViewItemSet(mercSet.id))
		local calcFunc, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		local blankOutput = calcFunc(itemsTab:ItemCalculationOverride("Weapon 1", blankWand))
		local unequipped = calcFunc(itemsTab:ItemCalculationOverride("Weapon 1", nil))
		assert.are.near(env.player.output.FullDPS, actorOutputs.MERCENARY.FullDPS, 10 ^ -6)
		assert.is_true(blankOutput.FullDPS < actorOutputs.MERCENARY.FullDPS)
		assert.is_true(unequipped.FullDPS < actorOutputs.MERCENARY.FullDPS)

		local tooltip = new("Tooltip"):Tooltip()
		itemsTab:AddItemTooltip(tooltip, wrathWand, itemsTab.slots["Weapon 1"])
		local tooltipLines = { }
		local sawRemoveHeader, sawFullDPS
		for _, line in ipairs(tooltip.lines) do
			local text = line.text or ""
			table.insert(tooltipLines, text)
			if text:find("Removing this item", 1, true) then
				sawRemoveHeader = true
			end
			if sawRemoveHeader and text:find("Full DPS", 1, true) then
				sawFullDPS = true
			end
		end
		assert.is_true(sawRemoveHeader, table.concat(tooltipLines, "\n"))
		assert.is_true(sawFullDPS, table.concat(tooltipLines, "\n"))

		local queryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator(itemsTab.tradeQuery)
		queryGenerator:StartQuery(itemsTab.slots["Weapon 1"], {
			itemSetId = mercSet.id,
			influence1 = 1,
			influence2 = 1,
			includeTalisman = false,
			includeCorrupted = false,
			includeScourge = false,
			includeEldritch = false,
			includeMirrored = false,
			statWeights = { { stat = "FullDPS", weightMult = 1 } },
			requiredMods = { },
		})
		queryGenerator.calcContext.co = nil
		local wrathMod
		for _, mod in pairs(queryGenerator.modData.Explicit) do
			if mod.tradeMod and mod.tradeMod.id == "explicit.stat_2181791238" and mod.Wand then
				wrathMod = mod
				break
			end
		end
		wrathMod = assert(wrathMod, "Wrath aura effect wand trade modifier is missing")
		queryGenerator.modWeights = { }
		queryGenerator.alreadyWeightedMods = { }
		queryGenerator:GenerateModWeights({ WrathAuraEffect = wrathMod })
		assert.are.equal(1, #queryGenerator.modWeights)
		assert.are.equal("explicit.stat_2181791238", queryGenerator.modWeights[1].tradeModId)
		assert.is_true(queryGenerator.modWeights[1].meanStatDiff > 0.01)
		if queryGenerator.calcContext.popup then
			main:ClosePopup()
		end
	end)

	it("shows player Full DPS when removing a Mercenary abyss jewel", function()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarSpectres", "WrathMercenary")
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		local itemsTab = build.itemsTab
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		local helmet = new("Item"):Item([[Rarity: Rare
Socketed Crown
Crusader Helmet
--------
Has 1 Abyssal Socket]])
		local jewel = new("Item"):Item([[Rarity: Rare
Support Eye
Hypnotic Eye Jewel
--------
40% increased Effect of Non-Curse Auras from your Skills]])
		itemsTab:AddItem(helmet, true)
		itemsTab:AddItem(jewel, true)
		mercSet.Helmet.selItemId = helmet.id
		mercSet["Helmet Abyssal Socket 1"].selItemId = jewel.id
		local env = calculate()
		assert.is_true(env.player.modDB.conditions.AffectedByWrath)
		local playerFullDPS = env.player.output.FullDPS
		assert.is_true(playerFullDPS > 0)

		assert(itemsTab:SetViewItemSet(mercSet.id))
		local calcFunc, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		local unequipped = calcFunc(itemsTab:ItemCalculationOverride("Helmet Abyssal Socket 1", nil))
		assert.are.near(playerFullDPS, actorOutputs.MERCENARY.FullDPS, 10 ^ -6)
		assert.is_true(unequipped.FullDPS < actorOutputs.MERCENARY.FullDPS)
		local removedEnv = build.calcsTab.calcs.initEnv(build, "CALCULATOR", itemsTab:ItemCalculationOverride("Helmet Abyssal Socket 1", nil))
		assert.is_nil(removedEnv.mercenary.itemList["Helmet Abyssal Socket 1"])

		local tooltip = new("Tooltip"):Tooltip()
		itemsTab:AddItemTooltip(tooltip, jewel, itemsTab.slots["Helmet Abyssal Socket 1"])
		local tooltipLines = { }
		local sawRemoveHeader, sawFullDPS
		for _, line in ipairs(tooltip.lines) do
			local text = line.text or ""
			table.insert(tooltipLines, text)
			if text:find("Removing this item", 1, true) then
				sawRemoveHeader = true
			end
			if sawRemoveHeader and text:find("Full DPS", 1, true) then
				sawFullDPS = true
			end
		end
		assert.is_true(sawRemoveHeader, table.concat(tooltipLines, "\n"))
		assert.is_true(sawFullDPS, table.concat(tooltipLines, "\n"))
	end)

	it("applies Links and Loyal Bodyguard", function()
		assert.is_nil(build.skillsTab.controls.linkTarget)
		allocate("Oath of Fealty")
		allocate("Golden Glory")
		build.skillsTab:PasteSocketGroup("Flame Link 20/0  1")
		local linkGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { includeInFullDPS = true })
		local env = calculate()
		local baseDPS = env.mercenary.output.CombinedDPS
		local baseFullDPS = env.mercenary.output.FullDPS
		assert.is_true(env.mercenary.modDB.conditions.AffectedByLink)
		-- Neither Link node modifier changes a number PoB calculates, so both are
		-- recognised as unsupported rather than parsed into an unread flag.
		for _, modLine in ipairs({ "Link Skills have infinite Attachment Duration", "If your Linked Mercenary dies, the Link owner does not also die" }) do
			local mods, unsupported = modLib.parseMod(modLine)
			assert.are.equal(0, #mods, modLine)
			assert.are.equal(modLine, unsupported)
		end
		assert.are.near(0.5, env.player.mainSkill.skillModList:More(env.player.mainSkill.skillCfg, "Cost"), 10 ^ -9)

		linkGroup.enabled = false
		env = calculate()
		assert.is_nil(env.mercenary.modDB.conditions.AffectedByLink)

		linkGroup.enabled = true
		build.configTab.input.customMods = "100% increased Light Radius"
		build.configTab:BuildModList()
		env = calculate()
		assert.is_true(env.mercenary.output.CombinedDPS > baseDPS)
		assert.is_true(env.mercenary.output.FullDPS > baseFullDPS)
		assert.is_true(env.mercenary.modDB.conditions.AffectedByLink)

		resetBuild()
		build.skillsTab:PasteSocketGroup("Vampiric Link 20/0  1")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		env = calculate()
		assert.are.equal(env.player, env.mercenary.parent)
		assert.are.equal(env.player.output.MaxLifeLeechRatePercent, env.mercenary.output.MaxLifeLeechRatePercent)

		resetBuild()
		allocate("Loyal Bodyguard")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { lifeComparison = "MERCENARY" })
		env = calculate()
		assert.are.equal(20, env.player.modDB:Sum("BASE", nil, "takenFromMercenaryBeforeYou"))
		assert.are.equal(0, env.mercenary.modDB:Sum("BASE", nil, "LifeRecoup"))

		build.mercenaryTab.profile.lifeComparison = "PLAYER"
		env = calculate()
		assert.are.equal(0, env.player.modDB:Sum("BASE", nil, "takenFromMercenaryBeforeYou"))
		assert.are.equal(40, env.mercenary.modDB:Sum("BASE", nil, "LifeRecoup"))

		build.mercenaryTab.profile.lifeComparison = "AUTO"
		local equalizer = {
			id = 9037, name = "Player Life Equalizer", type = "Helmet", base = { type = "Helmet" }, rarity = "RARE",
			requirements = { }, grantedSkills = { }, sockets = { }, modList = { {
				name = "Life", type = "BASE", value = env.mercenary.output.Life - env.player.output.Life,
				source = "Test", flags = 0, keywordFlags = 0,
			} },
		}
		build.itemsTab.items[equalizer.id] = equalizer
		build.itemsTab.slots.Helmet:SetSelItemId(equalizer.id)
		env = calculate()
		assert.are.equal(env.player.output.Life, env.mercenary.output.Life)
		assert.are.equal(0, env.player.modDB:Sum("BASE", nil, "takenFromMercenaryBeforeYou"))
		assert.are.equal(0, env.mercenary.modDB:Sum("BASE", nil, "LifeRecoup"))
	end)

	it("applies Destructive Link and Ceinture flasks", function()
		local sceptre = new("Item"):Item("Rarity: Normal\nVoid Sceptre")
		build.itemsTab:AddItem(sceptre, true)
		build.itemsTab.slots["Weapon 1"].selItemId = sceptre.id
		build.itemsTab.activeItemSet["Weapon 1"].selItemId = sceptre.id
		local sword = new("Item"):Item("Rarity: Normal\nRusted Sword")
		build.itemsTab:AddItem(sword, true)

		local configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.customModsList[1].text = "400% increased Critical Strike Chance"
		build.configTab:BuildModList()

		build.skillsTab:PasteSocketGroup("Heavy Strike 20/0  1")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		build.skillsTab:PasteSocketGroup("Destructive Link 21/0  1")
		local linkGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		configure("MeleeAOEStrikeDuelist", "MeleeAOEStrikeDuelistRangeStrikes", "FrostBladesMercenary", { includeInFullDPS = true })
		equipmentSlot("Weapon 1").selItemId = sword.id

		linkGroup.enabled = false
		local env = calculate()
		assert.is_not_nil(env.mercenary, table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		local unlinkedCrit, unlinkedMulti = mercMainHandCrit(env)
		assert.is_not_nil(unlinkedCrit)
		assert.is_nil(env.mercenary.modDB.conditions.AffectedByDestructiveLink)

		linkGroup.enabled = true
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.AffectedByLink)
		assert.is_true(env.mercenary.modDB.conditions.AffectedByDestructiveLink)
		local playerSheetCrit = env.player.output.MainHand.PreEffectiveCritChance
		local linkedCrit, linkedMulti = mercMainHandCrit(env)
		assert.is_true(playerSheetCrit > env.player.weaponData1.CritChance)
		assert.are.near(playerSheetCrit, linkedCrit, 0.01)
		assert.is_true(linkedMulti > unlinkedMulti)

		build.skillsTab:PasteSocketGroup("Clarity 20/0  1")
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		env = calculate()
		local auraLinkedCrit, auraLinkedMulti = mercMainHandCrit(env)
		assert.is_true(env.mercenary.modDB.conditions.AffectedByDestructiveLink)
		assert.is_nil(env.player.output.MainHand)
		assert.are.near(playerSheetCrit, auraLinkedCrit, 0.01)
		assert.is_true(auraLinkedCrit > env.player.weaponData1.CritChance)
		assert.is_true(auraLinkedMulti > unlinkedMulti)

		configSet.customModsList[1].text = "400% increased Critical Strike Chance\nNever deal Critical Strikes"
		build.configTab:BuildModList()
		env = calculate()
		local neverCrit, neverCritMulti = mercMainHandCrit(env)
		assert.is_true(env.player.modDB:Flag({ flags = ModFlag.Attack }, "NeverCrit"))
		assert.are.near(playerSheetCrit, neverCrit, 0.01)
		assert.is_true(neverCritMulti > unlinkedMulti)

		resetBuild()
		build.skillsTab:PasteSocketGroup("Flame Link 20/0  1")
		linkGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local recipientBelt = new("Item"):Item("Rarity: Rare\nRecipient Effect\nCloth Belt\nFlasks applied to you have 25% increased Effect")
		recipientBelt.id = 9029
		build.itemsTab.items[recipientBelt.id] = recipientBelt
		equipmentSlot("Belt").selItemId = recipientBelt.id

		local granite = new("Item"):Item("Rarity: Magic\nChemist's Granite Flask of the Opossum\n12% increased Movement Speed during Effect")
		granite.id = 9030
		granite.flaskData.effectInc = 10
		build.itemsTab.items[granite.id] = granite
		build.itemsTab.slots["Flask 1"].selItemId = granite.id
		build.itemsTab.slots["Flask 1"].active = true
		build.itemsTab.activeItemSet["Flask 1"].selItemId = granite.id
		build.itemsTab.activeItemSet["Flask 1"].active = true
		build.configTab.input.customMods = "Flasks applied to you have 30% increased Effect"
		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.customModsList[1].text = "Flasks applied to you have 30% increased Effect"
		configSet.actors.mercenary.customModsList[1].text = "Flasks applied to you have 30% increased Effect"
		build.configTab:BuildModList()
		env = calculate()
		local baseArmour = env.mercenary.modDB:Sum("BASE", nil, "Armour")
		local baseMovementSpeed = env.mercenary.modDB:Sum("INC", nil, "MovementSpeed")
		assert.is_true(env.player.modDB.conditions.UsingGraniteFlask)
		assert.is_nil(env.mercenary.modDB.conditions.UsingGraniteFlask)

		local ceinture = new("Item"):Item("Rarity: Unique\nCeinture of Benevolence\nCloth Belt\nNon-Unique Utility Flasks you Use apply to Linked Targets")
		ceinture.id = 9031
		build.itemsTab.items[ceinture.id] = ceinture
		build.itemsTab.slots.Belt.selItemId = ceinture.id
		build.itemsTab.activeItemSet.Belt.selItemId = ceinture.id
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.UsingFlask)
		assert.is_true(env.mercenary.modDB.conditions.UsingGraniteFlask)
		assert.are.equal(baseArmour + 2475, env.mercenary.modDB:Sum("BASE", nil, "Armour"))
		assert.are.equal(baseMovementSpeed + 19, env.mercenary.modDB:Sum("INC", nil, "MovementSpeed"))

		linkGroup.enabled = false
		env = calculate()
		assert.is_nil(env.mercenary.modDB.conditions.UsingFlask)
		assert.is_nil(env.mercenary.modDB.conditions.UsingGraniteFlask)
		assert.are.equal(baseArmour, env.mercenary.modDB:Sum("BASE", nil, "Armour"))

		linkGroup.enabled = true
		granite.rarity = "UNIQUE"
		granite.title = "Unique Granite Flask"
		env = calculate()
		assert.is_nil(env.mercenary.modDB.conditions.UsingFlask)
		assert.is_nil(env.mercenary.modDB.conditions.UsingGraniteFlask)
		assert.are.equal(baseArmour, env.mercenary.modDB:Sum("BASE", nil, "Armour"))

		local lifeFlask = new("Item"):Item("Rarity: Normal\nEternal Life Flask")
		lifeFlask.id = 9032
		build.itemsTab.items[lifeFlask.id] = lifeFlask
		build.itemsTab.slots["Flask 1"].selItemId = lifeFlask.id
		build.itemsTab.activeItemSet["Flask 1"].selItemId = lifeFlask.id
		env = calculate()
		assert.is_nil(env.mercenary.modDB.conditions.UsingFlask)
		assert.is_nil(env.mercenary.modDB.conditions.UsingEternalLifeFlask)

		resetBuild()
		local function onslaughtMovementSpeed(actor)
			local total = 0
			for _, mod in ipairs(actor.modDB.mods["MovementSpeed"] or { }) do
				if mod.source == "Onslaught" then
					total = total + mod.value
				end
			end
			return total
		end
		local function equipFlask(slotName, item)
			build.itemsTab.items[item.id] = item
			build.itemsTab.slots[slotName].selItemId = item.id
			build.itemsTab.slots[slotName].active = true
			build.itemsTab.activeItemSet[slotName].selItemId = item.id
			build.itemsTab.activeItemSet[slotName].active = true
		end
		local function clearFlask(slotName)
			build.itemsTab.slots[slotName].selItemId = 0
			build.itemsTab.activeItemSet[slotName].selItemId = 0
		end

		build.skillsTab:PasteSocketGroup("Flame Link 20/0  1")
		linkGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		configure("EleBowRanger", "EleBowRangerFire", "ArtilleryBallistaMercenary", {
			supports = { { id = "ArtilleryBallistaSpecificOnslaughtHigh", tier = 3 } },
		})
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9120, 9121
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id

		configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.customModsList[1].text = "Flasks applied to you have 30% increased Effect"
		build.configTab:BuildModList()

		env = calculate()
		assert.is_true(env.mercenary.modDB:Flag(nil, "Onslaught"))
		assert.are.equal(20, onslaughtMovementSpeed(env.mercenary))

		local silver = new("Item"):Item("Rarity: Magic\nChemist's Silver Flask of Curing")
		silver.id = 9122
		silver.flaskData.effectInc = 20
		equipFlask("Flask 1", silver)
		env = calculate()
		assert.is_true(env.player.modDB.conditions.UsingSilverFlask)
		assert.is_nil(env.mercenary.modDB.conditions.UsingSilverFlask)
		assert.is_nil((env.mercenary.appliedFlasks or { })[silver])
		assert.are.equal(24, onslaughtMovementSpeed(env.player))
		assert.are.equal(20, onslaughtMovementSpeed(env.mercenary))

		ceinture = new("Item"):Item("Rarity: Unique\nCeinture of Benevolence\nCloth Belt\nNon-Unique Utility Flasks you Use apply to Linked Targets")
		ceinture.id = 9124
		build.itemsTab.items[ceinture.id] = ceinture
		build.itemsTab.slots.Belt.selItemId = ceinture.id
		build.itemsTab.activeItemSet.Belt.selItemId = ceinture.id
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.UsingSilverFlask)
		assert.is_true(env.mercenary.appliedFlasks[silver])
		assert.are.equal(24, onslaughtMovementSpeed(env.player))
		assert.are.equal(30, onslaughtMovementSpeed(env.mercenary))

		local cinderswallow = new("Item"):Item("Rarity: Unique\nCinderswallow Urn\nSilver Flask")
		cinderswallow.id = 9123
		assert.are.equal("UNIQUE", cinderswallow.rarity)
		assert.are.equal("Silver Flask", cinderswallow.baseName)
		cinderswallow.flaskData.effectInc = 80
		clearFlask("Flask 1")
		equipFlask("Flask 2", cinderswallow)
		env = calculate()
		assert.is_true(env.player.modDB.conditions.UsingSilverFlask)
		assert.is_nil(env.mercenary.modDB.conditions.UsingSilverFlask)
		assert.is_nil((env.mercenary.appliedFlasks or { })[cinderswallow])
		assert.are.equal(36, onslaughtMovementSpeed(env.player))
		assert.are.equal(20, onslaughtMovementSpeed(env.mercenary))

		equipFlask("Flask 1", silver)
		env = calculate()
		assert.is_true(env.mercenary.modDB.conditions.UsingSilverFlask)
		assert.is_true(env.mercenary.appliedFlasks[silver])
		assert.is_nil(env.mercenary.appliedFlasks[cinderswallow])
		assert.are.equal(36, onslaughtMovementSpeed(env.player))
		assert.are.equal(30, onslaughtMovementSpeed(env.mercenary))

		linkGroup.enabled = false
		env = calculate()
		assert.is_nil(env.mercenary.modDB.conditions.UsingSilverFlask)
		assert.is_nil((env.mercenary.appliedFlasks or { })[silver])
		assert.is_nil((env.mercenary.appliedFlasks or { })[cinderswallow])
		assert.are.equal(36, onslaughtMovementSpeed(env.player))
		assert.are.equal(20, onslaughtMovementSpeed(env.mercenary))
	end)

	it("uses separate equipment sets for calculation, comparison, and trade", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local env = calculate()
		local compare, playerBase, actorBases = build.calcsTab.calcs.getMiscCalculator(build)
		assert.are.equal(env.player.output.Life, playerBase.Life)
		assert.are.equal(env.mercenary.output.Life, actorBases.MERCENARY.Life)
		assert.are.equal(env.player.output.Life, compare({ }).Life)
		assert.are.equal(env.mercenary.output.Life, compare({ comparisonActor = "MERCENARY" }).Life)

		compare = build.calcsTab.calcs.getMiscCalculator(build)
		local ok, err = pcall(compare, { itemSetId = 99999 })
		assert.is_true(not ok)
		assert.matches("Unknown item set id", tostring(err))
		assert.is_number(compare({ }).Life)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local itemsTab = build.itemsTab
		local guardianSet = itemsTab:NewItemSet()
		guardianSet.title = "Animate Guardian"
		table.insert(itemsTab.itemSetOrderList, guardianSet.id)
		local mercenarySet = assert(build.mercenaryTab:GetItemSet(true))

		local playerHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		local guardianHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		local mercenaryHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(playerHelmet, true)
		itemsTab:AddItem(guardianHelmet, true)
		itemsTab:AddItem(mercenaryHelmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		guardianSet.Helmet.selItemId = guardianHelmet.id
		mercenarySet["Helmet"].selItemId = mercenaryHelmet.id

		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		local guardianGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		local guardianGem
		for _, gem in ipairs(guardianGroup.gemList) do
			if gem.nameSpec == "Animate Guardian" or gem.gemData and gem.gemData.name == "Animate Guardian" or gem.grantedEffect and gem.grantedEffect.name == "Animate Guardian" then
				guardianGem = gem
				break
			end
		end
		guardianGem = assert(guardianGem)
		guardianGem.skillMinionItemSet = guardianSet.id
		guardianGem.skillMinionItemSetCalcs = guardianSet.id

		env = calculate()
		assert.are.equal(playerHelmet, env.player.itemList.Helmet)
		assert.are.equal(guardianHelmet, env.minion.itemList.Helmet)
		assert.are.equal(mercenaryHelmet, env.mercenary.itemList.Helmet)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		itemsTab = build.itemsTab
		local firstSet = assert(build.mercenaryTab:GetItemSet(true))
		local secondSet = itemsTab:NewItemSet()
		secondSet.title = "Alternate Equipment"
		table.insert(itemsTab.itemSetOrderList, secondSet.id)
		local firstHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		local secondHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(firstHelmet, true)
		itemsTab:AddItem(secondHelmet, true)
		firstSet["Helmet"].selItemId = firstHelmet.id
		secondSet["Helmet"].selItemId = secondHelmet.id

		build.mercenaryTab:SetItemSet(secondSet.id)
		env = calculate()
		assert.are.equal(secondSet.id, build.mercenaryTab.itemSetId)
		assert.are.equal(secondHelmet, env.mercenary.itemList.Helmet)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		itemsTab = build.itemsTab
		mercenarySet = assert(build.mercenaryTab:GetItemSet(true))
		local currentHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		itemsTab:AddItem(currentHelmet, true)
		mercenarySet["Helmet"].selItemId = currentHelmet.id

		local tradeQuery = itemsTab.tradeQuery
		tradeQuery.tradeQueryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator(itemsTab)
		tradeQuery.slotTables[1] = { slotName = "Helmet", itemSetId = mercenarySet.id }
		tradeQuery.resultTbl[1] = { { item_string = [[Rarity: Rare
Mercenary's Test
Leather Cap
--------
+100 to maximum Life]] } }
		tradeQuery.statSortSelectionList = { { stat = "Life", weightMult = 1 } }

		calculate()
		local _, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		local evaluation = tradeQuery:GetResultEvaluation(1, 1)
		assert.is_number(evaluation[1].output.Life)
		assert.is_true(evaluation[1].output.Life > actorOutputs.MERCENARY.Life)
		assert.is_true(evaluation[1].weight > 0)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local mercSet = assert(build.mercenaryTab:GetItemSet(true))
		calculate()
		assert(build.itemsTab:SetViewItemSet(mercSet.id))
		build.calcsTab:BuildOutput()
		local calcFunc, calcBase
		calcFunc, calcBase, actorOutputs = build.calcsTab:GetMiscCalculator()
		assert.are.equal(actorOutputs.PLAYER, calcBase)
		assert.are.equal(calcFunc().Life, calcBase.Life)
		assert.is_truthy(actorOutputs.MERCENARY)
		assert.are.equal(calcFunc({ comparisonActor = "MERCENARY" }).Life, actorOutputs.MERCENARY.Life)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		itemsTab = build.itemsTab
		mercSet = assert(build.mercenaryTab:GetItemSet(true))
		playerHelmet = new("Item"):Item([[Rarity: Rare
Player Helmet
Iron Hat
--------
+1000 to maximum Life]])
		local mercHelmet = new("Item"):Item("Rarity: Normal\nLeather Cap")
		local replacementHelmet = new("Item"):Item([[Rarity: Rare
Replacement Helmet
Leather Cap
--------
+100 to maximum Life]])
		itemsTab:AddItem(playerHelmet, true)
		itemsTab:AddItem(mercHelmet, true)
		itemsTab:AddItem(replacementHelmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		mercSet.Helmet.selItemId = mercHelmet.id
		calculate()
		assert(itemsTab:SetViewItemSet(mercSet.id))
		calcFunc, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		local playerReplacement = calcFunc({
			repSlotName = "Helmet",
			repItem = replacementHelmet,
		})
		local mercReplacement = calcFunc(itemsTab:ItemCalculationOverride("Helmet", replacementHelmet))
		assert.is_true(playerReplacement.Life < actorOutputs.PLAYER.Life)
		assert.is_true(mercReplacement.Life > actorOutputs.MERCENARY.Life)
		assert.are_not.equal(playerReplacement.Life, mercReplacement.Life)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		itemsTab = build.itemsTab
		local playerSetId = itemsTab.activeItemSetId
		assert(build.mercenaryTab:SetItemSet(playerSetId, false))
		playerHelmet = new("Item"):Item([[Rarity: Rare
Player Helmet
Iron Hat
--------
+100 to maximum Life]])
		replacementHelmet = new("Item"):Item([[Rarity: Rare
Replacement Helmet
Iron Hat
--------
+1000 to maximum Life]])
		itemsTab:AddItem(playerHelmet, true)
		itemsTab:AddItem(replacementHelmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		calculate()
		assert(itemsTab:SetViewItemSet(playerSetId, "MERCENARY"))
		_, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		env = build.calcsTab.calcs.initEnv(build, "CALCULATOR", itemsTab:ItemCalculationOverride("Helmet", replacementHelmet))
		build.calcsTab.calcs.perform(env)
		assert.are.equal(actorOutputs.PLAYER.Life, env.player.output.Life)
		assert.is_true(env.mercenary.output.Life > actorOutputs.MERCENARY.Life)

		resetBuild()
		configure("MeleeAOEMarauder", "MeleeAOEMarauderFireSlam", "InfernalCryMercenary")
		itemsTab = build.itemsTab
		playerSetId = itemsTab.activeItemSetId
		assert(build.mercenaryTab:SetItemSet(playerSetId, false))
		playerHelmet = new("Item"):Item([[Rarity: Rare
Player Helmet
Iron Hat
--------
+100 to maximum Life]])
		replacementHelmet = new("Item"):Item([[Rarity: Rare
Replacement Helmet
Iron Hat
--------
+1000 to maximum Life]])
		itemsTab:AddItem(playerHelmet, true)
		itemsTab:AddItem(replacementHelmet, true)
		itemsTab.activeItemSet.Helmet.selItemId = playerHelmet.id
		calculate()
		assert(itemsTab:SetViewItemSet(playerSetId, "PLAYER"))
		_, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		env = build.calcsTab.calcs.initEnv(build, "CALCULATOR", itemsTab:ItemCalculationOverride("Helmet", replacementHelmet))
		build.calcsTab.calcs.perform(env)
		assert.is_true(env.player.output.Life > actorOutputs.PLAYER.Life)
		assert.are.equal(actorOutputs.MERCENARY.Life, env.mercenary.output.Life)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		itemsTab = build.itemsTab
		local configuredGuardianSet = itemsTab:NewItemSet()
		configuredGuardianSet.title = "Configured Guardian"
		table.insert(itemsTab.itemSetOrderList, configuredGuardianSet.id)
		local selectedGuardianSet = itemsTab:NewItemSet()
		selectedGuardianSet.title = "Trader Guardian"
		table.insert(itemsTab.itemSetOrderList, selectedGuardianSet.id)

		local configuredHelmet = new("Item"):Item("Rarity: Normal\nIron Hat")
		local selectedHelmet = new("Item"):Item([[Rarity: Rare
Selected Guardian Helmet
Iron Hat
--------
+10 to maximum Life]])
		replacementHelmet = new("Item"):Item([[Rarity: Rare
Replacement Guardian Helmet
Iron Hat
--------
+100 to maximum Life]])
		itemsTab:AddItem(configuredHelmet, true)
		itemsTab:AddItem(selectedHelmet, true)
		itemsTab:AddItem(replacementHelmet, true)
		configuredGuardianSet.Helmet.selItemId = configuredHelmet.id
		selectedGuardianSet.Helmet.selItemId = selectedHelmet.id

		build.skillsTab:PasteSocketGroup("Animate Guardian 20/0  1")
		guardianGroup = build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList]
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		guardianGem = nil
		for _, gem in ipairs(guardianGroup.gemList) do
			if gem.nameSpec == "Animate Guardian" or gem.gemData and gem.gemData.name == "Animate Guardian" or gem.grantedEffect and gem.grantedEffect.name == "Animate Guardian" then
				guardianGem = gem
				break
			end
		end
		guardianGem = assert(guardianGem)
		guardianGem.skillMinionItemSet = configuredGuardianSet.id
		guardianGem.skillMinionItemSetCalcs = configuredGuardianSet.id

		calculate()
		itemsTab:SetViewItemSet(selectedGuardianSet.id)
		local tradeQueryGenerator = new("TradeQueryGenerator"):TradeQueryGenerator(itemsTab.tradeQuery)
		tradeQueryGenerator:StartQuery(itemsTab.slots.Helmet, {
			itemSetId = selectedGuardianSet.id,
			influence1 = 1,
			influence2 = 1,
			statWeights = { { stat = "Life", weightMult = 1 } },
			requiredMods = { },
		})
		tradeQueryGenerator.calcContext.co = nil
		local baseOutput = tradeQueryGenerator.calcContext.baseOutput
		local replacementOutput = tradeQueryGenerator.calcContext.calcFunc({
			itemSetId = selectedGuardianSet.id,
			comparisonActor = "PLAYER",
			repSlotName = "Helmet",
			repItem = replacementHelmet,
		})

		assert.are.equal(baseOutput.Life, replacementOutput.Life)
		assert.is_true(replacementOutput.Minion.Life > baseOutput.Minion.Life)
	end)

	it("expands anoints, sockets, presence implicits, and strips granted skills", function()
		allocate("Legendary Arms")
		allocate("Legendary Helmets")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		local baseline = calculate().mercenary
		local baselineFireResist = baseline.output.FireResist
		local baselineDamage = baseline.modDB:Sum("INC", nil, "Damage")
		local baselineMoreDamage = baseline.modDB:More(nil, "Damage")
		local presenceDamage = {
			name = "Damage", type = "INC", value = 20, source = "Presence Test", flags = 0, keywordFlags = 0,
			{ type = "ActorCondition", actor = "enemy", var = "RareOrUnique" },
		}
		local item = {
			id = 9003,
			name = "Mercenary Test Helmet",
			type = "Helmet",
			base = { type = "Helmet" },
			rarity = "UNIQUE",
			requirements = { level = 1, dex = 1 },
			grantedSkills = { },
			modList = {
				{ name = "GrantedPassive", type = "LIST", value = "diamond skin", source = "Test", flags = 0, keywordFlags = 0 },
				{ name = "Keystone", type = "LIST", value = "resolute technique", source = "Test", flags = 0, keywordFlags = 0 },
				presenceDamage,
			},
			implicitModLines = { { line = "While a Unique Enemy is in your Presence, 20% increased Damage", modList = { presenceDamage } } },
		}
		build.itemsTab.items[item.id] = item
		equipmentSlot("Helmet").selItemId = item.id
		build.configTab.input.enemyIsBoss = "None"
		local mercenary = calculate().mercenary
		assert.are.equal(baselineFireResist + 15, mercenary.output.FireResist)
		-- Presence implicits are always active on hired Mercenaries, even with no Unique enemy.
		assert.are.equal(baselineDamage + 20, mercenary.modDB:Sum("INC", nil, "Damage"))
		assert.are.equal(round(baselineMoreDamage * 1.08, 2), mercenary.modDB:More(nil, "Damage"))
		assert.is_true(mercenary.modDB:Flag(nil, "CannotBeEvaded"))
		assert.is_true(mercenary.modDB:Flag(nil, "NeverCrit"))
		local _, _, actorBases = build.calcsTab:GetMiscCalculator()
		assert.are.near(mercenary.output.CombinedDPS, actorBases.MERCENARY.CombinedDPS, 10 ^ -6)

		resetBuild()
		allocate("Legendary Helmets")
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		baselineDamage = calculate().mercenary.modDB:Sum("INC", nil, "Damage")
		local againstUnique = {
			name = "Damage", type = "INC", value = 15, source = "Against Unique Test", flags = 0, keywordFlags = 0,
			{ type = "ActorCondition", actor = "enemy", var = "RareOrUnique" },
		}
		item = {
			id = 9005,
			name = "Mercenary Against Unique Helmet",
			type = "Helmet",
			base = { type = "Helmet" },
			rarity = "UNIQUE",
			requirements = { level = 1, dex = 1 },
			grantedSkills = { },
			modList = { againstUnique },
			explicitModLines = { { line = "15% increased Damage against Unique Enemies", modList = { againstUnique } } },
		}
		build.itemsTab.items[item.id] = item
		equipmentSlot("Helmet").selItemId = item.id
		build.configTab.input.enemyIsBoss = "None"
		assert.are.equal(baselineDamage, calculate().mercenary.modDB:Sum("INC", nil, "Damage"))
		build.configTab.input.enemyIsBoss = "Pinnacle"
		assert.are.equal(baselineDamage + 15, calculate().mercenary.modDB:Sum("INC", nil, "Damage"))

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		baseline = calculate().mercenary
		local baselineLife = baseline.output.Life
		local baselineBaseLife = baseline.modDB:Sum("BASE", nil, "Life")
		item = {
			id = 9004,
			name = "Mercenary Socket Test",
			type = "Helmet",
			base = { type = "Helmet" },
			rarity = "RARE",
			requirements = { dex = 1 },
			grantedSkills = { },
			sockets = { { color = "R", group = 1 }, { color = "G", group = 1 } },
			modList = {
				{ name = "Life", type = "BASE", value = 40, source = "Test", flags = 0, keywordFlags = 0,
					{ type = "Multiplier", var = "EmptyRedSocketsInAnySlot" } },
			},
		}
		build.itemsTab.items[item.id] = item
		equipmentSlot("Helmet").selItemId = item.id
		mercenary = calculate().mercenary
		assert.are.equal(1, mercenary.modDB.multipliers.EmptyRedSocketsInAnySlot)
		assert.are.equal(1, mercenary.modDB.multipliers.EmptyGreenSocketsInAnySlot)
		assert.are.equal(baselineBaseLife + 40, mercenary.modDB:Sum("BASE", nil, "Life"))
		assert.is_true(mercenary.output.Life > baselineLife)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		baseline = calculate().mercenary
		local helmet = {
			id = 9005, name = "Mercenary Abyss Helmet", type = "Helmet", base = { type = "Helmet" }, rarity = "RARE",
			requirements = { dex = 1 }, grantedSkills = { }, sockets = { { color = "A", group = 1 } }, abyssalSocketCount = 1, modList = { },
		}
		local jewel = {
			id = 9006, name = "Mercenary Abyss Jewel", type = "Jewel", base = { type = "Jewel", subType = "Abyss" }, rarity = "RARE",
			requirements = { level = 1 }, grantedSkills = { }, modList = {
				{ name = "Life", type = "BASE", value = 40, source = "Test", flags = 0, keywordFlags = 0 },
			},
		}
		build.itemsTab.items[helmet.id], build.itemsTab.items[jewel.id] = helmet, jewel
		equipmentSlot("Helmet").selItemId = helmet.id
		equipmentSlot("Helmet Abyssal Socket 1").selItemId = jewel.id
		mercenary = calculate().mercenary
		assert.are.equal(baseline.modDB:Sum("BASE", nil, "Life") + 40, mercenary.modDB:Sum("BASE", nil, "Life"))
		assert.are.equal(jewel, mercenary.itemList["Helmet Abyssal Socket 1"])

		local itemsTab = build.itemsTab
		assert(itemsTab:SetViewItemSet(assert(build.mercenaryTab:GetItemSet(true)).id))
		local calcFunc, _, actorOutputs = build.calcsTab:GetMiscCalculator()
		local removed = calcFunc(itemsTab:ItemCalculationOverride("Helmet Abyssal Socket 1", nil))
		assert.is_true(removed.Life < actorOutputs.MERCENARY.Life)
		local withJewelEnv = build.calcsTab.calcs.initEnv(build, "CALCULATOR")
		local removedEnv = build.calcsTab.calcs.initEnv(build, "CALCULATOR", itemsTab:ItemCalculationOverride("Helmet Abyssal Socket 1", nil))
		assert.are.equal(jewel, withJewelEnv.mercenary.itemList["Helmet Abyssal Socket 1"])
		assert.is_nil(removedEnv.mercenary.itemList["Helmet Abyssal Socket 1"])
		assert.are.equal(withJewelEnv.mercenary.modDB:Sum("BASE", nil, "Life") - 40, removedEnv.mercenary.modDB:Sum("BASE", nil, "Life"))

		resetBuild()
		configure("ChaosMinionWitch", "ChaosMinionWitchChaosHitNoble", "DarkPactMercenary")
		allocate("Legendary Helmets")
		local baselineMana = calculate().mercenary.modDB:Sum("BASE", nil, "Mana")
		local ebers = new("Item"):Item([[Rarity: Unique
Eber's Unification
Hubris Circlet
Trigger Level 10 Void Gaze when you use a Skill
150% increased Energy Shield
+80 to maximum Mana
50% increased Stun and Block Recovery
Gain 8% of Elemental Damage as Extra Chaos Damage
]])
		assert.are.equal("VoidGaze", ebers.grantedSkills[1].skillId)
		build.itemsTab:AddItem(ebers, true)
		equipmentSlot("Helmet").selItemId = ebers.id
		local env = calculate()
		assert.is_nil(env.mercenaryCalculationErrors and env.mercenaryCalculationErrors[1], table.concat(env.mercenaryCalculationErrors or { }, "\n"))
		assert.is_table(env.mercenary)
		assert.are.equal(ebers, env.mercenary.itemList.Helmet)
		assert.are.equal(baselineMana + 80, env.mercenary.modDB:Sum("BASE", nil, "Mana"))
		assert.are.equal(8, env.mercenary.modDB:Sum("BASE", nil, "ElementalDamageGainAsChaos"))
		assert.are.equal(50, env.mercenary.modDB:Sum("INC", nil, "StunRecovery"))
		assert.are.equal(0, #env.mercenary.modDB:List(nil, "ExtraSkill"))
		for _, skill in ipairs(env.mercenary.activeSkillList) do
			assert.are_not.equal("VoidGaze", skill.activeEffect.grantedEffect.id)
		end
	end)

	it("includes Mercenary Mirage in Full DPS and uses actor-local count-once", function()
		configure("NonEleBowRanger", "NonEleBowRangerChaos", "CausticArrowMercenary", {
			includeInFullDPS = true,
			supports = { { id = "MirageArcherHigh", tier = 3 } },
		})
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9014, 9015
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		local mercenary = assert(calculate().mercenary)
		assert.is_table(mercenary.mainSkill.mirage)
		assert.is_true(mercenary.mainSkill.mirage.output.TotalDPS > 0)
		local mirageBreakdown
		for _, skillDPS in ipairs(mercenary.output.SkillDPS) do
			if skillDPS.source == "Mercenary Mirage" then mirageBreakdown = skillDPS break end
		end
		assert.is_table(mirageBreakdown)
		assert.are.near(mercenary.mainSkill.mirage.output.TotalDPS, mirageBreakdown.dps, 10 ^ -6)
		assert.are.near(mercenary.output.CombinedDPS, mercenary.output.FullDPS, 10 ^ -6)
		assert.is_true(not mercenary.mainSkill.skillCfg.skillCond.usedByMirage)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { includeInFullDPS = true })
		local withoutMirage = assert(calculate().mercenary.output.CombinedDPS)
		build.itemsTab:CreateDisplayItemFromRaw([[Rarity: NORMAL
Crude Bow
Sockets: G-G-G-G-G-G]])
		build.itemsTab:AddDisplayItem()
		build.skillsTab:PasteSocketGroup("Mirage Archer 20/0  1\nRain of Arrows 20/0  1\n")
		local env = calculate()
		assert.is_table(env.mercenary)
		assert.is_true(not env.mercenary.mainSkill.skillCfg.skillCond.usedByMirage)
		assert.are.near(withoutMirage, env.mercenary.output.CombinedDPS, 10 ^ -6)
		local again = calculate()
		assert.is_true(not again.mercenary.mainSkill.skillCfg.skillCond.usedByMirage)
		assert.are.near(withoutMirage, again.mercenary.output.CombinedDPS, 10 ^ -6)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarSpectres", "AbsolutionMercenary", {
			includeInFullDPS = true,
			count = 3,
		})
		local configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.absolutionSkillDamageCountedOnce = true
		build.configTab:BuildModList()
		env = calculate()
		assert.is_true(env.skillsUsed.Absolution)
		assert.are.near(env.mercenary.output.TotalDPS + env.mercenaryMinion.output.TotalDPS * 3, env.mercenary.output.FullDPS, 10 ^ -6)

		resetBuild()
		configure("AurasMinionsTemplar", "AurasMinionsTemplarSpectres", "AbsolutionMercenary", {
			includeInFullDPS = true,
			count = 3,
		})
		build.configTab.input.absolutionSkillDamageCountedOnce = true
		build.configTab:BuildModList()
		env = calculate()
		assert.are.near(env.mercenary.output.TotalDPS * 3 + env.mercenaryMinion.output.TotalDPS * 3, env.mercenary.output.FullDPS, 10 ^ -6)
	end)

	it("counts only the strongest Decay in Full DPS", function()
		local wand = new("Item"):Item("Rarity: RARE\nDecay Test\nGoat's Horn\nImplicits: 0\nYour Hits inflict Decay, dealing 700 Chaos Damage per second for 8 seconds\n")
		build.itemsTab:AddItem(wand, true)
		build.itemsTab.slots["Weapon 1"].selItemId = wand.id
		build.itemsTab.activeItemSet["Weapon 1"].selItemId = wand.id
		build.skillsTab:PasteSocketGroup("Lightning Trap 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		runCallback("OnFrame")
		local trapDecay = calcs.calcFullDPS(build, "CALCULATOR", { }).decayDPS
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].enabled = false
		build.skillsTab:PasteSocketGroup("Lightning Spire Trap 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		runCallback("OnFrame")
		local spireDecay = calcs.calcFullDPS(build, "CALCULATOR", { }).decayDPS
		build.skillsTab.socketGroupList[1].enabled = true
		runCallback("OnFrame")
		local both = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.is_true(trapDecay > 0)
		assert.is_true(spireDecay > 0)
		assert.are.near(math.max(trapDecay, spireDecay), both.decayDPS, 10 ^ -6)
		assert.is_true(both.decayDPS < trapDecay + spireDecay - 1)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { includeInFullDPS = true })
		wand = decayItem("Goat's Horn", 9101)
		equipmentSlot("Weapon 1").selItemId = wand.id
		setMercenaryFullDPS({ "LightningTrapMercenary" })
		trapDecay = calcs.calcFullDPS(build, "CALCULATOR", { }).decayDPS
		setMercenaryFullDPS({ "LightningSpireTrapMercenary" })
		spireDecay = calcs.calcFullDPS(build, "CALCULATOR", { }).decayDPS
		setMercenaryFullDPS({ "LightningTrapMercenary", "LightningSpireTrapMercenary" })
		both = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.is_true(trapDecay > 0)
		assert.is_true(spireDecay > 0)
		assert.are.near(math.max(trapDecay, spireDecay), both.decayDPS, 10 ^ -6)
		assert.are.near(both.decayDPS, namedDps(both.mercenarySkills, "Best Decay DPS"), 10 ^ -6)
		assert.is_true(both.decayDPS < trapDecay + spireDecay - 1)

		resetBuild()
		configure("NonEleBowRanger", "NonEleBowRangerChaos", "CausticArrowMercenary", {
			includeInFullDPS = true,
			supports = { { id = "MirageArcherHigh", tier = 3 } },
		})
		local bow = decayItem("Crude Bow", 9102)
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		quiver.id = 9103
		build.itemsTab.items[quiver.id] = quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		local env = calculate()
		assert.is_table(env.mercenary.mainSkill.mirage)
		local sourceDecay = env.mercenary.output.DecayDPS or 0
		local mirageDecay = env.mercenary.mainSkill.mirage.output.DecayDPS or 0
		assert.is_true(sourceDecay > 0)
		assert.is_true(mirageDecay > 0)
		local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(math.max(sourceDecay, mirageDecay), fullDPS.decayDPS, 10 ^ -6)
		assert.are.near(fullDPS.decayDPS, namedDps(fullDPS.mercenarySkills, "Best Decay DPS"), 10 ^ -6)

		resetBuild()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { includeInFullDPS = true })
		local mercWand = decayItem("Goat's Horn", 9104)
		equipmentSlot("Weapon 1").selItemId = mercWand.id
		local playerWand = new("Item"):Item("Rarity: RARE\nDecay Test\nGoat's Horn\nImplicits: 0\nYour Hits inflict Decay, dealing 700 Chaos Damage per second for 8 seconds\n")
		build.itemsTab:AddItem(playerWand, true)
		build.itemsTab.slots["Weapon 1"].selItemId = playerWand.id
		build.itemsTab.activeItemSet["Weapon 1"].selItemId = playerWand.id
		build.skillsTab:PasteSocketGroup("Lightning Trap 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		env = calculate()
		local playerDecay = env.player.output.DecayDPS or 0
		local mercDecay = env.mercenary.output.DecayDPS or 0
		assert.is_true(playerDecay > 0)
		assert.is_true(mercDecay > 0)
		fullDPS = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(math.max(playerDecay, mercDecay), fullDPS.decayDPS, 10 ^ -6)
		assert.are.near(mercDecay, namedDps(fullDPS.mercenarySkills, "Best Decay DPS"), 10 ^ -6)
	end)

	it("does not grow Mercenary Full DPS merely because extra Full DPS passes ran", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary", { includeInFullDPS = true })
		local configSet = build.configTab.configSets[build.configTab.activeConfigSetId]
		build.configTab:EnsureActorConfig(configSet)
		configSet.actors.mercenary.input.buffOnslaught = true
		setMercenaryFullDPS({ "LightningTrapMercenary" })
		local trapOnly = namedDps(calcs.calcFullDPS(build, "CALCULATOR", { }).mercenarySkills, "Lightning Trap")
		setMercenaryFullDPS({ "LightningSpireTrapMercenary" })
		local spireOnly = namedDps(calcs.calcFullDPS(build, "CALCULATOR", { }).mercenarySkills, "Lightning Spire Trap")
		assert.is_true(trapOnly > 0)
		assert.is_true(spireOnly > 0)
		setMercenaryFullDPS({ "LightningTrapMercenary", "LightningSpireTrapMercenary" })
		local both = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(trapOnly, namedDps(both.mercenarySkills, "Lightning Trap"), 10 ^ -4)
		assert.are.near(spireOnly, namedDps(both.mercenarySkills, "Lightning Spire Trap"), 10 ^ -4)
	end)

	it("does not rebuild after the final player Full DPS skill when the Mercenary is excluded", function()
		configure("TrapsMinesShadow", "TrapsMinesShadowLightning", "LightningTrapMercenary")
		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		calculate()

		local originalInitEnv = calcs.initEnv
		local initEnvCalls = 0
		calcs.initEnv = function(...)
			initEnvCalls = initEnvCalls + 1
			return originalInitEnv(...)
		end
		local ok, fullDPS = pcall(calcs.calcFullDPS, build, "CALCULATOR", { })
		calcs.initEnv = originalInitEnv

		assert.is_true(ok, fullDPS)
		assert.is_true(fullDPS.combinedDPS > 0)
		assert.are.equal(0, #fullDPS.mercenarySkills)
		assert.are.equal(1, initEnvCalls)
	end)

	it("uniques named generic DoTs across actors and still stacks count", function()
		local function grantedSkill(grantedEffect, flags)
			return {
				activeEffect = { grantedEffect = grantedEffect },
				skillFlags = flags or { },
			}
		end
		for _, case in ipairs({
			function()
				local totals = { }
				local identity = calcs.genericDotIdentity({ inheritedFrom = "EssenceDrainAltY", id = "EssenceDrainAltMercenary" })
				calcs.contributeGenericDot(totals, identity, { TotalDot = 100 }, { }, 1)
				calcs.contributeGenericDot(totals, identity, { TotalDot = 80 }, { }, 1)
				assert.are.equal(100, calcs.sumDotTotals(totals))
				calcs.contributeGenericDot(totals, identity, { TotalDot = 180 }, { }, 1)
				assert.are.equal(180, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				calcs.contributeGenericDot(totals, calcs.genericDotIdentity({ id = "EssenceDrainAltY" }), { TotalDot = 80 }, { }, 1)
				calcs.contributeGenericDot(totals, calcs.genericDotIdentity({ inheritedFrom = "EssenceDrainAltY", id = "EssenceDrainAltMercenary" }), { TotalDot = 150 }, { }, 1)
				calcs.contributeGenericDot(totals, calcs.genericDotIdentity({ inheritedFrom = "EssenceDrainAltY", id = "EssenceDrainAltMercenaryEncounter" }), { TotalDot = 100 }, { }, 1)
				assert.are.equal(150, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				calcs.contributeGenericDot(totals, calcs.genericDotIdentity({ inheritedFrom = "EssenceDrainAltY", id = "EssenceDrainAltMercenary" }), { TotalDot = 100 }, { }, 1)
				calcs.contributeGenericDot(totals, calcs.genericDotIdentity({ inheritedFrom = "Bane", id = "BaneMercenary" }), { TotalDot = 40 }, { }, 1)
				assert.are.equal(140, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				local identity = calcs.genericDotIdentity({ inheritedFrom = "ToxicRain", id = "ToxicRainMercenary" })
				calcs.contributeGenericDot(totals, identity, { TotalDot = 50 }, { DotCanStack = true }, 2)
				calcs.contributeGenericDot(totals, identity, { TotalDot = 30 }, { DotCanStack = true }, 1)
				assert.are.equal(130, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				calcs.contributeSkillGenericDot(totals, grantedSkill({ inheritedFrom = "SandstormChaosElementalSummoned", id = "SandstormChaosMercenary" }), { TotalDot = 100 }, 1)
				calcs.contributeSkillGenericDot(totals, grantedSkill({ id = "SandstormChaosElementalSummoned" }), { TotalDot = 80 }, 1)
				assert.are.equal(100, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				calcs.contributeSkillGenericDot(totals, grantedSkill({ id = "SandstormChaosElementalSummoned" }), { TotalDot = 90 }, 1)
				calcs.contributeSkillGenericDot(totals, grantedSkill({ inheritedFrom = "SandstormChaosElementalSummoned", id = "SandstormChaosMercenary" }), { TotalDot = 70 }, 1)
				assert.are.equal(90, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				calcs.contributeSkillGenericDot(totals, grantedSkill({ id = "SandstormChaosElementalSummoned" }), { TotalDot = 80 }, 1)
				calcs.contributeSkillGenericDot(totals, grantedSkill({ id = "InfernalLegion" }), { TotalDot = 40 }, 1)
				assert.are.equal(120, calcs.sumDotTotals(totals))
			end,
			function()
				local totals = { }
				local summon = grantedSkill({ id = "SSMHolySpectresMercenary" })
				local minion = grantedSkill({ id = "ToxicRain" }, { DotCanStack = true })
				calcs.contributeSkillGenericDot(totals, minion, { TotalDot = 50 }, 2)
				assert.are.equal(100, calcs.sumDotTotals(totals))
				calcs.contributeSkillGenericDot(totals, summon, { TotalDot = 50 }, 2)
				assert.are.equal(150, calcs.sumDotTotals(totals))
			end,
		}) do
			case()
		end

		configure("ChaosMinionWitch", "ChaosMinionWitchDot", "EssenceDrainAltMercenary", { includeInFullDPS = true })
		local staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9106
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		build.skillsTab:PasteSocketGroup("Essence Drain of Wickedness 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		local env = calculate()
		local playerDot = env.player.output.TotalDot or 0
		local mercDot = env.mercenary.output.TotalDot or 0
		assert.is_true(playerDot > 0)
		assert.is_true(mercDot > 0)
		local fullDPS = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(math.max(playerDot, mercDot), fullDPS.dotDPS, 10 ^ -6)
		assert.are.near(mercDot, namedDps(fullDPS.mercenarySkills, "Full DoT DPS"), 10 ^ -6)

		resetBuild()
		configure("ChaosMinionWitch", "ChaosMinionWitchDot", "EssenceDrainAltMercenary", { includeInFullDPS = true })
		staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9107
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		setMercenaryFullDPS({ "EssenceDrainAltMercenary" })
		local drain = calcs.calcFullDPS(build, "CALCULATOR", { }).dotDPS
		setMercenaryFullDPS({ "BaneMercenary" })
		local bane = calcs.calcFullDPS(build, "CALCULATOR", { }).dotDPS
		setMercenaryFullDPS({ "EssenceDrainAltMercenary", "BaneMercenary" })
		local both = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.is_true(drain > 0)
		assert.is_true(bane > 0)
		assert.are.near(drain + bane, both.dotDPS, 10 ^ -4)
		assert.are.near(both.dotDPS, namedDps(both.mercenarySkills, "Full DoT DPS"), 10 ^ -6)

		resetBuild()
		configure("NonEleBowRanger", "NonEleBowRangerChaos", "ToxicRainMercenary", { includeInFullDPS = true, count = 2 })
		local bow = new("Item"):Item("Rarity: Normal\nCrude Bow")
		local quiver = new("Item"):Item("Rarity: Normal\nSerrated Arrow Quiver")
		bow.id, quiver.id = 9108, 9109
		build.itemsTab.items[bow.id], build.itemsTab.items[quiver.id] = bow, quiver
		equipmentSlot("Weapon 1").selItemId, equipmentSlot("Weapon 2").selItemId = bow.id, quiver.id
		env = calculate()
		local onePod = env.mercenary.output.TotalDot or 0
		assert.is_true(onePod > 0)
		fullDPS = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(onePod * 2, fullDPS.dotDPS, 10 ^ -4)

		resetBuild()
		configure("ChaosMinionWitch", "ChaosMinionWitchDot", "SandstormChaosMercenary", { includeInFullDPS = true })
		staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9110
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		build.skillsTab:PasteSocketGroup("Summon Chaos Golem 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		runCallback("OnFrame")
		selectMinionSkill("SandstormChaosElementalSummoned")
		env = calculate()
		playerDot = env.minion.output.TotalDot or 0
		mercDot = env.mercenary.output.TotalDot or 0
		assert.is_true(playerDot > 0)
		assert.is_true(mercDot > 0)
		assert.are.not_equal(playerDot, mercDot)
		fullDPS = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(math.max(playerDot, mercDot), fullDPS.dotDPS, 10 ^ -4)
		assert.is_true(fullDPS.dotDPS < playerDot + mercDot - 1)

		resetBuild()
		configure("ChaosMinionWitch", "ChaosMinionWitchDot", "EssenceDrainAltMercenary", { includeInFullDPS = true })
		staff = new("Item"):Item("Rarity: Normal\nGnarled Branch")
		staff.id = 9111
		build.itemsTab.items[staff.id] = staff
		equipmentSlot("Weapon 1").selItemId = staff.id
		build.skillsTab:PasteSocketGroup("Summon Chaos Golem 20/0  1")
		build.skillsTab.socketGroupList[#build.skillsTab.socketGroupList].includeInFullDPS = true
		build.mainSocketGroup = #build.skillsTab.socketGroupList
		runCallback("OnFrame")
		selectMinionSkill("SandstormChaosElementalSummoned")
		env = calculate()
		playerDot = env.minion.output.TotalDot or 0
		mercDot = env.mercenary.output.TotalDot or 0
		assert.is_true(playerDot > 0)
		assert.is_true(mercDot > 0)
		fullDPS = calcs.calcFullDPS(build, "CALCULATOR", { })
		assert.are.near(playerDot + mercDot, fullDPS.dotDPS, 10 ^ -4)
	end)

	it("calculates every selectable exported inherent skill and support without runtime errors", function()
		local function contains(values, wanted)
			for _, value in ipairs(values or { }) do if value == wanted then return true end end
			return false
		end
		local buildForSkill = { }
		for _, buildId in ipairs(build.data.mercenaries.buildOrder) do
			local mercenaryBuild = build.data.mercenaries.builds[buildId]
			if #mercenaryBuild.weaponTypes > 0 then
				for _, skillId in ipairs(mercenaryBuild.skillIds) do
					for _, pool in ipairs(mercenaryBuild.skillPools) do
						if contains(pool.skillIds, skillId) and (not pool.countMax or pool.countMax > 0) then
							buildForSkill[skillId] = buildForSkill[skillId] or buildId
							break
						end
					end
				end
			end
		end

		local baseNameByType = { }
		-- Shields are armour, so the lowest base of type Shield is not always legal.
		-- Cache by type and build so Int Mercenaries do not receive a Dex buckler.
		local function lowestBaseName(itemType, mercenaryBuild)
			local cacheKey = itemType == "Shield" and itemType.."\0"..mercenaryBuild.id or itemType
			if baseNameByType[cacheKey] then return baseNameByType[cacheKey] end
			local bestName, bestLevel
			for name, base in pairs(build.data.itemBases) do
				if base.type == itemType then
					local legal = true
					if itemType == "Shield" then
						legal = MercenaryTools.validateEquippedItem({
							type = "Shield",
							rarity = "NORMAL",
							requirements = {
								level = base.req and base.req.level or 0,
								str = base.req and base.req.str or 0,
								dex = base.req and base.req.dex or 0,
								int = base.req and base.req.int or 0,
							},
						}, "Weapon 2", {
							profile = { buildId = mercenaryBuild.id, foundAreaLevel = 68 },
							mercenaryData = build.data.mercenaries,
							itemSet = { },
							playerItemSet = { },
							items = { },
							playerHasFlag = function() return false end,
						})
					end
					if legal then
						local level = base.req and base.req.level or 0
						if not bestLevel or level < bestLevel or level == bestLevel and name < bestName then
							bestName, bestLevel = name, level
						end
					end
				end
			end
			baseNameByType[cacheKey] = assert(bestName, itemType)
			return bestName
		end

		local nextItemId = 990000
		local function equip(slotName, itemType, mercenaryBuild)
			if not itemType or itemType == "None" then return end
			local item = new("Item"):Item("Rarity: Normal\n"..lowestBaseName(itemType, mercenaryBuild))
			item.id = nextItemId
			nextItemId = nextItemId + 1
			build.itemsTab.items[item.id] = item
			equipmentSlot(slotName).selItemId = item.id
		end

		build.configTab.input.enemyLevel = 83
		build.configTab:BuildModList()
		build.mercenaryTab.profile.buildId = build.data.mercenaries.buildOrder[1]
		build.mercenaryTab:Changed()
		local skillIds = { }
		for skillId in pairs(buildForSkill) do table.insert(skillIds, skillId) end
		table.sort(skillIds)
		local testedSupports = { }
		local testedSupportCount = 0
		local inheritedFlagBySkillType = {
			[SkillType.RemoteMined] = "mine",
			[SkillType.SummonsTotem] = "totem",
			[SkillType.Trapped] = "trap",
		}
		for _, skillId in ipairs(skillIds) do
			equipmentSlot("Weapon 1").selItemId = 0
			equipmentSlot("Weapon 2").selItemId = 0
			local buildId = buildForSkill[skillId]
			local mercenaryBuild = build.data.mercenaries.builds[buildId]
			equip("Weapon 1", mercenaryBuild.weaponConfiguration.mainHandTypes[1], mercenaryBuild)
			if mercenaryBuild.weaponConfiguration.offHandRequired then equip("Weapon 2", mercenaryBuild.weaponConfiguration.offHandTypes[1], mercenaryBuild) end
			build.mercenaryTab.profile = {
				classId = mercenaryBuild.classId,
				buildId = buildId,
				foundAreaLevel = 68,
				mainSkillId = skillId,
				lifeComparison = "AUTO",
				skills = { { id = skillId, enabled = true, includeInFullDPS = true, count = 1, supports = { } } },
			}
			build.spec.modFlag = true
			build.buildFlag = true
			local ok, errorMessage = xpcall(function() build.calcsTab:BuildOutput() end, debug.traceback)
			assert.is_true(ok, skillId..": "..tostring(errorMessage))
			local env = build.calcsTab.mainEnv
			local minionId = build.data.mercenaries.summonedMinions[skillId]
			local noFallbackMinion = minionId and build.data.minions[minionId].noFallbackSkill
			if noFallbackMinion then
				assert.is_nil(env.mercenary, skillId)
				assert.matches("has no exported skills", table.concat(env.mercenaryCalculationErrors or { }, "\n"), skillId)
			else
				assert.is_table(env.mercenary, skillId)
				assert.is_table(env.mercenary.mainSkill, skillId)
				for skillType, flag in pairs(inheritedFlagBySkillType) do
					if env.mercenary.mainSkill.skillTypes[skillType] then assert.is_true(env.mercenary.mainSkill.skillFlags[flag], skillId.." must inherit "..flag) end
				end
				if skillId == "ToxicRainMercenary" then assert.is_true(env.mercenary.mainSkill.skillFlags.projectile) end
				for _, supportId in ipairs(build.data.mercenaries.skills[skillId].possibleSupportIds) do
					if not testedSupports[supportId] then
						local support = build.data.mercenaries.supports[supportId]
						build.mercenaryTab.profile.skills[1].supports = { { id = supportId, tier = support.variant } }
						build.spec.modFlag = true
						build.buildFlag = true
						ok, errorMessage = xpcall(function() build.calcsTab:BuildOutput() end, debug.traceback)
						assert.is_true(ok, supportId.." on "..skillId..": "..tostring(errorMessage))
						assert.is_table(build.calcsTab.mainEnv.mercenary, supportId.." on "..skillId)
						testedSupports[supportId] = true
						testedSupportCount = testedSupportCount + 1
					end
				end
			end
		end
		assert.are.equal(269, #skillIds)
		assert.are.equal(261, testedSupportCount)
	end)
end)
