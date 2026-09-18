describe("Mercenary tools", function()
	local tools = require("Modules.MercenaryTools")
	local data = {
		builds = { build = {
			skillIds = { "skill", "other_skill" },
			skillPools = { { skillIds = { "skill", "other_skill" }, countMax = 1 } },
		} },
		skills = {
			skill = { supportCountId = "Low", possibleSupportIds = { "support_t1", "support_t2", "support_t3", "other_support", "support_no_family" } },
			other_skill = { supportCountId = "High", possibleSupportIds = { } },
		},
		supports = {
			support_t1 = { variant = 1, familyId = "family" },
			support_t2 = { variant = 2, familyId = "family" },
			support_t3 = { variant = 3, familyId = "family" },
			other_support = { variant = 1, familyId = "other_family" },
			support_no_family = { variant = 1 },
		},
		supportCounts = { Low = { maximum = 2 }, High = { maximum = 5 } },
	}

	it("maps Mercenary-prefixed slot names to base slots", function()
		assert.are.equal("Helmet", tools.baseItemSlotName("Mercenary Helmet"))
		assert.is_nil(tools.baseItemSlotName("Helmet"))
		assert.is_nil(tools.baseItemSlotName(1))
	end)

	it("routes comparison output by actor", function()
		local playerOutput = { CombinedDPS = 100, FullDPS = 1000, FullDotDPS = 10 }
		local mercenaryOutput = { CombinedDPS = 50, FullDPS = 50, FullDotDPS = 1 }
		assert.are.equal(playerOutput, tools.comparisonBaseOutput(playerOutput, { PLAYER = playerOutput }, "PLAYER"))
		assert.is_nil(tools.comparisonBaseOutput(playerOutput, { PLAYER = playerOutput }, "MERCENARY"))
		assert.is_true(not tools.mercenaryOutputAvailable(nil))
		assert.is_true(not tools.mercenaryOutputAvailable({ ActorUnavailableMessage = "missing" }))
		local routed = tools.comparisonBaseOutput(playerOutput, {
			PLAYER = playerOutput,
			MERCENARY = mercenaryOutput,
		}, "MERCENARY")
		assert.are.equal(50, routed.CombinedDPS)
		assert.are.equal(1000, routed.FullDPS)
		assert.are.equal(10, routed.FullDotDPS)
		assert.are.equal(50, mercenaryOutput.FullDPS)
		assert.are_not.equal(mercenaryOutput, routed)
		assert.is_true(tools.mercenaryOutputAvailable(mercenaryOutput))
		assert.are.equal(mercenaryOutput, tools.buildComparisonOutput(mercenaryOutput, nil))
		local unavailable = { ActorUnavailableMessage = "missing" }
		assert.are.equal(unavailable, tools.buildComparisonOutput(unavailable, playerOutput))
	end)

	it("classifies item overrides by comparison actor", function()
		local playerOverride = { itemSetId = 1, comparisonActor = "PLAYER", repSlotName = "Helmet", repItem = { } }
		assert.is_true(tools.overrideReplacesPlayerItem(playerOverride, 1))
		assert.is_false(tools.overrideReplacesMercenarySlot(playerOverride, "Helmet", 1))
		local mercOverride = { itemSetId = 1, comparisonActor = "MERCENARY", repSlotName = "Helmet", repItem = { } }
		assert.is_false(tools.overrideReplacesPlayerItem(mercOverride, 1))
		assert.is_true(tools.overrideReplacesMercenarySlot(mercOverride, "Helmet", 1))
		local dedicatedMerc = { itemSetId = 2, repSlotName = "Helmet", repItem = { } }
		assert.is_false(tools.overrideReplacesPlayerItem(dedicatedMerc, 1))
		assert.is_true(tools.overrideReplacesMercenarySlot(dedicatedMerc, "Helmet", 2))
	end)

	it("resolves equipped items and reports weapon-configuration errors", function()
		local itemSet = {
			Helmet = { selItemId = 1 },
			["Helmet Abyssal Socket 1"] = { selItemId = 2 },
		}
		local items = {
			[1] = { name = "cap", abyssalSocketCount = 1 },
			[2] = { name = "jewel" },
		}
		assert.are.equal(items[1], tools.equippedItem(itemSet, items, "Helmet"))
		assert.are.equal(items[2], tools.equippedItem(itemSet, items, "Helmet Abyssal Socket 1"))
		local goldrim = { name = "Goldrim", abyssalSocketCount = 0 }
		local replaceHelmet = { comparisonActor = "MERCENARY", repSlotName = "Helmet", repItem = goldrim }
		assert.are.equal(goldrim, tools.equippedItem(itemSet, items, "Helmet", replaceHelmet, 1))
		assert.is_nil(tools.equippedItem(itemSet, items, "Helmet Abyssal Socket 1", replaceHelmet, 1))
		local removeHelmet = { comparisonActor = "MERCENARY", repSlotName = "Helmet", repItem = nil }
		assert.is_nil(tools.equippedItem(itemSet, items, "Helmet", removeHelmet, 1))
		assert.is_nil(tools.equippedItem(itemSet, items, "Helmet Abyssal Socket 1", removeHelmet, 1))

		local dagger = { type = "Dagger", rarity = "NORMAL", base = { type = "Dagger" }, requirements = { } }
		local wand = { id = 3, type = "Wand", rarity = "NORMAL", base = { type = "Wand" }, requirements = { } }
		local weapons = {
			["Weapon 1"] = { selItemId = 1 },
			["Weapon 2"] = { selItemId = 2 },
		}
		local weaponItems = { [1] = dagger, [2] = dagger, [3] = wand }
		local function weaponValid(item, slotName, itemSet, equippedLookup)
			if slotName ~= "Weapon 2" then return true end
			local weapon1 = equippedLookup and equippedLookup("Weapon 1")
			if not weapon1 then
				local sel = itemSet["Weapon 1"] and itemSet["Weapon 1"].selItemId
				weapon1 = weaponItems[sel]
			end
			local weapon1Type = weapon1 and weapon1.base.type or "None"
			if weapon1Type == "Wand" then
				return item.type == "Wand" or item.type == "Shield"
			end
			return true
		end
		local weaponContext = {
			profile = { buildId = "dual", foundAreaLevel = 68 },
			mercenaryData = {
				builds = { dual = {
					classId = "shadow",
					weaponConfiguration = {
						mainHandTypes = { "Dagger", "Wand" },
						offHandRequired = false,
						offHandTypes = { "Dagger", "Wand" },
					},
				} },
				classes = { shadow = { attributeId = "Dex", attributeName = "Dexterity" } },
			},
			itemSet = weapons,
			playerItemSet = { },
			items = weaponItems,
			override = { comparisonActor = "MERCENARY", repSlotName = "Weapon 1", repItem = wand },
			mercenaryItemSetId = 1,
			playerHasFlag = function() return false end,
			isItemValidForSlot = weaponValid,
		}
		assert.are.equal(wand, tools.equippedItem(weapons, weaponItems, "Weapon 1", weaponContext.override, 1))
		assert.are.equal(dagger, tools.equippedItem(weapons, weaponItems, "Weapon 2", weaponContext.override, 1))
		assert.matches("Weapon 2: invalid base slot or weapon configuration", table.concat(tools.equipmentErrors(weaponContext), "\n"))
		weaponContext.override = nil
		assert.are.equal("", table.concat(tools.equipmentErrors(weaponContext), "\n"))
	end)

	it("restores profile skills after withMainSkill and withReplacedSkill", function()
		local profile = { mainSkillId = "A" }
		assert.are.equal("B", tools.withMainSkill(profile, "B", function()
			assert.are.equal("B", profile.mainSkillId)
			return profile.mainSkillId
		end))
		assert.are.equal("A", profile.mainSkillId)
		assert.has_error(function()
			tools.withMainSkill(profile, "B", function() error("boom") end)
		end)
		assert.are.equal("A", profile.mainSkillId)

		local skills = { { id = "A", supports = { "keep" } }, { id = "B" } }
		local replaced = { id = "preview", supports = { } }
		assert.are.equal("preview", tools.withReplacedSkill({ skills = skills }, 1, replaced, function()
			assert.are.equal(replaced, skills[1])
			return skills[1].id
		end))
		assert.are.equal("A", skills[1].id)
		assert.are.same({ "keep" }, skills[1].supports)
		assert.has_error(function()
			tools.withReplacedSkill({ skills = skills }, 1, replaced, function() error("boom") end)
		end)
		assert.are.equal("A", skills[1].id)
	end)

	it("reports missing attribute data and unique-item requirements", function()
		local missingAttribute = {
			profile = { buildId = "dual", foundAreaLevel = 68 },
			mercenaryData = {
				builds = { dual = {
					classId = "shadow",
					weaponConfiguration = { mainHandTypes = { "Dagger" }, offHandTypes = { "Dagger" } },
				} },
				classes = { shadow = { attributeId = "", attributeName = "Dexterity" } },
			},
			itemSet = { Helmet = { selItemId = 1 } },
			playerItemSet = { },
			items = { [1] = { type = "Helmet", rarity = "RARE", requirements = { str = 1 }, base = { type = "Helmet" } } },
			playerHasFlag = function() return false end,
			isItemValidForSlot = function() return true end,
		}
		assert.matches("missing attribute data", table.concat(tools.equipmentErrors(missingAttribute), "\n"))

		local uniqueHelmet = { type = "Helmet", rarity = "UNIQUE", requirements = { dex = 1 }, base = { type = "Helmet" } }
		local uniqueContext = {
			profile = { buildId = "dual", foundAreaLevel = 68 },
			mercenaryData = {
				builds = { dual = {
					classId = "shadow",
					weaponConfiguration = { mainHandTypes = { "Dagger" }, offHandTypes = { "Dagger" } },
				} },
				classes = { shadow = { attributeId = "Dex", attributeName = "Dexterity" } },
			},
			itemSet = { Helmet = { selItemId = 1 } },
			playerItemSet = { },
			items = { [1] = uniqueHelmet },
			isItemValidForSlot = function() return true end,
		}
		uniqueContext.playerHasFlag = function() return nil end
		assert.are.equal("", table.concat(tools.equipmentErrors(uniqueContext), "\n"))
		uniqueContext.playerHasFlag = function() return false end
		assert.matches("Unique Helmets", table.concat(tools.equipmentErrors(uniqueContext), "\n"))
	end)

	it("treats a Mercenary as hired only with a profile and Noble Blood", function()
		local profiled = { mercenaryTab = { profile = { buildId = "AnyBuild" } }, spec = { allocNodes = { } } }
		assert.is_true(tools.hasProfile(profiled))
		assert.is_false(tools.playerCanHire(profiled))
		assert.is_false(tools.isHired(profiled))
		profiled.spec.allocNodes[1] = { modList = { { name = "CanHirePermanentMercenary" } } }
		assert.is_true(tools.playerCanHire(profiled))
		assert.is_true(tools.isHired(profiled))
		assert.is_false(tools.isHired({ mercenaryTab = { profile = { } }, spec = profiled.spec }))
	end)

	it("shows the Mercenary tab only for Scion and keeps unused builds quiet", function()
		assert.is_true(tools.tabVisible({ spec = { curClassName = "Scion" } }))
		assert.is_true(not tools.tabVisible({ spec = { curClassName = "Marauder" } }))
		assert.is_true(not tools.tabVisible({ }))
		assert.is_true(tools.isMercenaryCalculationActor("MERCENARY_MINION"))
		assert.is_true(not tools.isMercenaryCalculationActor("PLAYER"))

		local actors = {
			{ label = "Player", actorId = "PLAYER" },
			{ label = "Mercenary", actorId = "MERCENARY" },
			{ label = "Mercenary Minion", actorId = "MERCENARY_MINION" },
		}
		assert.are.equal(3, #tools.filterCalculationActors(actors, { spec = { curClassName = "Scion" } }))
		local marauderActors = tools.filterCalculationActors(actors, { spec = { curClassName = "Marauder" } })
		assert.are.equal(1, #marauderActors)
		assert.are.equal("PLAYER", marauderActors[1].actorId)
		assert.are_not.equal(actors, marauderActors)
		wipeTable(marauderActors)
		assert.are.equal(3, #actors)

		assert.are.equal(2, #tools.configActorList({ spec = { curClassName = "Scion" } }))
		assert.are.equal(1, #tools.configActorList({ spec = { curClassName = "Witch" } }))

		local unused = { spec = { curClassName = "Scion" }, viewMode = "TREE", mercenaryTab = { profile = { } } }
		assert.is_true(not tools.includeInBuildWarnings(unused))
		unused.viewMode = "MERCENARY"
		assert.is_true(tools.includeInBuildWarnings(unused))
		unused.viewMode = "TREE"
		unused.mercenaryTab.profile.buildId = "AnyBuild"
		assert.is_true(tools.includeInBuildWarnings(unused))
		assert.is_true(not tools.includeInBuildWarnings({ spec = { curClassName = "Marauder" }, viewMode = "MERCENARY", mercenaryTab = unused.mercenaryTab }))

		local marauder = {
			spec = { curClassName = "Marauder" },
			viewMode = "MERCENARY",
			calcsTab = { input = { actor = "MERCENARY" } },
			configTab = { viewActor = "mercenary", GetViewActor = function(self) return self.viewActor end },
			itemsTab = {
				viewComparisonActor = "MERCENARY",
				activeItemSetId = 1,
				SetViewItemSet = function(self, itemSetId, actor)
					self.viewComparisonActor = actor
				end,
			},
		}
		tools.applyHiddenState(marauder)
		assert.are.equal("TREE", marauder.viewMode)
		assert.are.equal("PLAYER", marauder.calcsTab.input.actor)
		assert.are.equal("player", marauder.configTab.viewActor)
		assert.are.equal("PLAYER", marauder.itemsTab.viewComparisonActor)
		local scion = { spec = { curClassName = "Scion" }, viewMode = "MERCENARY" }
		tools.applyHiddenState(scion)
		assert.are.equal("MERCENARY", scion.viewMode)
	end)

	it("groups numbered class variants for the picker", function()
		local groups, byClassId = tools.classGroups({
			classOrder = { "templar2", "witch2", "templar1", "scion" },
			classes = {
				templar2 = { name = "[DNT] Merc Templar 2", attributeName = "Str / Int", buildIds = { "build2" } },
				witch2 = { name = "[DNT] Witch Merc 2", attributeName = "Int", buildIds = { "build3" } },
				templar1 = { name = "[DNT] Merc Templar 1", attributeName = "Str / Int", buildIds = { "build1" } },
				scion = { name = "[DNT] Merc Scion 1", attributeName = "Str / Dex / Int", buildIds = { "scionBuild" } },
			},
		})
		assert.are.equal(3, #groups)
		assert.are.equal("Templar (Str / Int)", groups[1].label)
		assert.same({ "templar2", "templar1" }, groups[1].classIds)
		assert.same({ "build2", "build1" }, groups[1].buildIds)
		assert.are.equal(groups[1], byClassId.templar1)
		assert.are.equal("Scion (Str / Dex / Int)", groups[3].label)
		assert.are.equal(byClassId.scion, groups[3])
	end)

	it("imports a Warrant and rejects invalid input", function()
		_G.data.ensureMercenaries()
		local mercenaryData = LoadModule("Data/Mercenaries")
		mercenaryData.supportCounts = _G.data.mercenaryStatData.supportCounts
		local imported, err = tools.importWarrant([[
Item Class: Map Fragments
Rarity: Normal
Mercenary Warrant
--------
Mercenary
--------
Build: Toxicologist
Mercenary Level: 83
--------
Withering Step
Increased Area of Effect (Tier: 2)
Gilded Wither Stacks (Tier: 3)
--------
Chaotic Burst
Wither on Hit (Tier: 2)
Increased Area of Effect (Tier: 2)
--------
Chaotic Shot
Physical as Extra Chaos (Tier: 2)
Chance to Poison (Tier: 2)
Chaos Penetration (Tier: 2)
Faster Projectiles (Tier: 2)
Greater Multiple Projectiles (Tier: 3)
--------
Scourge Arrow of Menace
Greater Faster Attacks (Tier: 3)
Greater DoT Multiplier (Tier: 3)
Physical as Extra Chaos (Tier: 2)
Chance to Poison (Tier: 2)
--------
Blink Arrow
Faster Attacks (Tier: 2)
Minion Life (Tier: 2)
Greater Minion Damage (Tier: 3)
--------
Trarthan Agility
Cooldown Recovery (Tier: 2)
Greater Area of Effect (Tier: 3)
--------
Right click this item to view Mercenary details.
Can be used in a personal Map Device alongside a Map to have this previously fought Mercenary reappear in the area for a rematch.
]], mercenaryData)
		assert.is_nil(err)
		assert.are.equal("Toxicologist", mercenaryData.builds[imported.buildId].name)
		assert.are.equal(6, #imported.skills)
		assert.are.equal("Withering Step", mercenaryData.skills[imported.mainSkillId].name)
		assert.is_true(imported.importedWarrant)

		local header = "Mercenary Warrant\n--------\nBuild: Toxicologist\nMercenary Level: 83\n--------\n"
		for _, case in ipairs({
			{ text = string.rep("x", 256 * 1024 + 1), pattern = "256 KiB" },
			{ text = header.."Withering Step\nIncreased Area of Effect (Tier: 2)\nIncreased Area of Effect (Tier: 2)\n", pattern = "Duplicate support" },
			{ text = header.."Withering Step\nIncreased Area of Effect (Tier: 9)\n", pattern = "is not valid" },
		}) do
			_, err = tools.importWarrant(case.text, mercenaryData)
			assert.matches(case.pattern, err)
		end

		local fake = {
			builds = {
				a = { id = "a", name = "Dup", classId = "c", skillIds = { "s" } },
				b = { id = "b", name = "Dup", classId = "c", skillIds = { "s" } },
			},
			buildOrder = { "a", "b" },
			skills = { s = { id = "s", name = "Skill", possibleSupportIds = { }, supportCountId = "None" } },
			supports = { },
			supportCounts = { None = { maximum = 0 } },
		}
		_, err = tools.importWarrant("Mercenary Warrant\n--------\nBuild: Dup\nMercenary Level: 10\n--------\nSkill\n", fake)
		assert.matches("Ambiguous Mercenary build", err)
	end)

	it("scales level, passives, and the damage taper", function()
		assert.are.equal(68, tools.effectiveLevel(50, 84))
		assert.are.equal(100, tools.effectiveLevel(100, 85))
		assert.are.equal(100, tools.effectiveLevel(150, 85))
		assert.are.equal(1, tools.effectiveLevel(0, 0))
		assert.are.equal(48, tools.requiredFoundAreaLevel(68))

		local values = { 60, 120, 160 }
		assert.are.equal(60, tools.passiveStatValue(values, 1))
		assert.are.equal(60, tools.passiveStatValue(values, 24))
		assert.are.equal(95, tools.passiveStatValue(values, 50))
		assert.are.equal(120, tools.passiveStatValue(values, 68))
		assert.are.equal(140, tools.passiveStatValue(values, 76))
		assert.are.equal(160, tools.passiveStatValue(values, 84))
		assert.are.equal(60, tools.passiveStatValue(values, 0))
		assert.are.equal(160, tools.passiveStatValue(values, 120))
		assert.are.equal(93, tools.passiveStatValue({ 38, 75, 100 }, 80))

		local maxMore = -30
		for _, case in ipairs({
			{ 1, 0 }, { 44, 0 }, { 45, 0 }, { 46, -1 }, { 82, -29 }, { 83, -30 }, { 100, -30 },
		}) do
			assert.are.equal(case[2], tools.permanentDamageMore(case[1], maxMore))
		end
	end)

	it("validates profiles without repairing them", function()
		local profile = {
			buildId = "build",
			foundAreaLevel = 0,
			mainSkillId = "missing",
			skills = { {
				id = "skill",
				enabled = true,
				supports = { { id = "support_t1", tier = 2 }, { id = "support_t2", tier = 2 } },
			} },
		}
		local errors = table.concat(tools.validateProfile(profile, data), "\n")
		assert.matches("Mercenary level", errors)
		assert.matches("Invalid tier", errors)
		assert.matches("Duplicate support family", errors)
		assert.matches("Selected Calcs skill", errors)
		assert.are.equal("missing", profile.mainSkillId)
		profile.foundAreaLevel = 68.5
		assert.matches("must be an integer", table.concat(tools.validateProfile(profile, data), "\n"))

		local ok, noIdErrors = pcall(tools.validateProfile, {
			buildId = "build",
			foundAreaLevel = 68,
			mainSkillId = "skill",
			skills = { { enabled = true, supports = { } } },
		}, data)
		assert.is_true(ok)
		assert.matches("Invalid skill", table.concat(noIdErrors, "\n"))

		for _, count in ipairs({ 0, 1.5, 100, "2" }) do
			assert.matches("must be an integer from 1 to 99", table.concat(tools.validateProfile({
				buildId = "build",
				foundAreaLevel = 68,
				mainSkillId = "skill",
				skills = { { id = "skill", enabled = true, count = count, supports = { } } },
			}, data), "\n"))
		end

		profile = {
			buildId = "build",
			foundAreaLevel = 68,
			skills = { { id = "skill", enabled = false, supports = { } } },
		}
		assert.matches("Enable at least one", table.concat(tools.validateProfile(profile, data), "\n"))
		profile.skills[1].enabled = true
		assert.matches("Select a Mercenary skill for Calcs", table.concat(tools.validateProfile(profile, data), "\n"))
		profile.mainSkillId = "skill"
		profile.skills[1].enabled = false
		assert.matches("Enable at least one", table.concat(tools.validateProfile(profile, data), "\n"))

		assert.matches("Skill pool 1 allows at most 1", table.concat(tools.validateProfile({
			buildId = "build",
			foundAreaLevel = 68,
			mainSkillId = "skill",
			skills = {
				{ id = "skill", enabled = true, supports = { } },
				{ id = "other_skill", enabled = true, supports = { } },
			},
		}, data), "\n"))

		assert.are.equal(2, tools.supportLimit(data, data.skills.skill))
		data.supportCounts.None = { maximum = 0 }
		assert.are.equal(0, tools.supportLimit(data, { id = "zero", supportCountId = "None" }))
		assert.is_nil(tools.supportLimit(data, { id = "drift", supportCountId = "MissingPolicy" }))
		data.skills.skill.supportCountId = "MissingPolicy"
		assert.matches("Missing support%-count policy for MissingPolicy", table.concat(tools.validateProfile({
			buildId = "build",
			foundAreaLevel = 68,
			mainSkillId = "skill",
			skills = { { id = "skill", enabled = true, supports = { } } },
		}, data), "\n"))
		data.skills.skill.supportCountId = "Low"
		data.supportCounts.None = nil

		profile = {
			buildId = "build",
			foundAreaLevel = 68,
			mainSkillId = "skill",
			skills = { { id = "skill", enabled = true, supports = { } } },
		}
		assert.matches("Duplicate skill", tools.skillCandidateError(profile, data, 2, "skill"))
		assert.matches("allows at most 1", tools.skillCandidateError(profile, data, 2, "other_skill"))
		assert.is_nil(tools.firstLegalSkillId(profile, data))
		assert.matches("Duplicate support family", tools.supportCandidateError({
			skills = { { id = "skill", supports = { { id = "support_t1", tier = 1 } } } },
		}, data, 1, 2, "support_t2"))
		assert.is_nil(tools.supportCandidateError({
			skills = { { id = "skill", supports = { } } },
		}, data, 1, 1, "support_t1"))
	end)
end)

describe("Generated Mercenary data", function()
	local tools = require("Modules.MercenaryTools")
	local mercenaries = data.ensureMercenaries()

	it("has deterministic orders and resolvable references", function()
		local classGroups = select(1, tools.classGroups(mercenaries))
		local classLabels = { }
		for _, group in ipairs(classGroups) do table.insert(classLabels, group.label) end
		assert.same({
			"Templar (Str / Int)",
			"Witch (Int)",
			"Shadow (Dex / Int)",
			"Ranger (Dex)",
			"Marauder (Str)",
			"Duelist (Str / Dex)",
			"Scion (Str / Dex / Int)",
		}, classLabels)
		local function has(values, wanted)
			for _, value in ipairs(values) do if value == wanted then return true end end
			return false
		end
		assert.are.equal(13, #mercenaries.classOrder)
		for index = 2, #mercenaries.classOrder do
			assert.is_true(mercenaries.classOrder[index - 1] < mercenaries.classOrder[index])
		end
		for index = 2, #mercenaries.buildOrder do
			assert.is_true(mercenaries.buildOrder[index - 1] < mercenaries.buildOrder[index])
		end
		for _, classId in ipairs(mercenaries.classOrder) do
			local class = assert(mercenaries.classes[classId])
			assert.is_table(class.monster)
			for _, buildId in ipairs(class.buildIds) do
				assert.are.equal(classId, assert(mercenaries.builds[buildId]).classId)
			end
			for _, skillId in ipairs(class.skillIds) do
				assert.is_table(mercenaries.skills[skillId])
			end
		end
		for skillId, skill in pairs(mercenaries.skills) do
			assert.is_true(data.skills[skillId].mercenary, skillId)
			local resolved = mercenaries.skillsByHash[tostring(skill.hash)]
			assert.is_table(resolved)
			assert.is_true(has(resolved, skillId))
			assert.is_table(mercenaries.supportCounts[skill.supportCountId], skillId..": "..tostring(skill.supportCountId))
			for _, supportId in ipairs(skill.possibleSupportIds) do
				assert.is_table(mercenaries.supports[supportId])
			end
		end
		for supportId, support in pairs(mercenaries.supports) do
			local resolved = mercenaries.supportsByHash[tostring(support.hash)]
			assert.is_table(resolved)
			assert.is_true(has(resolved, supportId))
			for _, stat in ipairs(support.stats) do
				assert.are.equal("string", type(stat.id), supportId)
				assert.are.equal("number", type(stat.value), supportId..": "..stat.id)
			end
		end
		for skillId, skill in pairs(mercenaries.skills) do
			local grantedEffect = data.skills[skillId]
			for _, supportId in ipairs(skill.possibleSupportIds) do
				for _, stat in ipairs(mercenaries.supports[supportId].stats) do
					assert.is_true(grantedEffect.statMap[stat.id] ~= nil or data.mercenarySupportStatMap[stat.id] ~= nil, skillId.." + "..supportId..": "..stat.id)
				end
				local supportEffect = assert(data.mercenarySupportGrantedEffect(supportId, skillId), skillId.." + "..supportId)
				assert.are.equal(supportId, supportEffect.mercenarySupportId)
				assert.is_nil(supportEffect.unsupportedMercenaryStats)
			end
		end
		local seenKnownUncalculated = { }
		for skillId in pairs(mercenaries.skills) do
			local grantedEffect = assert(data.skills[skillId])
			for _, statId in ipairs(grantedEffect.stats or { }) do
				assert.is_true(grantedEffect.statMap[statId] ~= nil or data.knownUncalculatedSkillStats[statId] == true, skillId..": "..statId)
				if not grantedEffect.statMap[statId] then seenKnownUncalculated[statId] = true end
			end
			for _, stat in ipairs(grantedEffect.constantStats or { }) do
				assert.is_true(grantedEffect.statMap[stat[1]] ~= nil or data.knownUncalculatedSkillStats[stat[1]] == true, skillId..": "..stat[1])
				if not grantedEffect.statMap[stat[1]] then seenKnownUncalculated[stat[1]] = true end
			end
		end
		for statId in pairs(data.knownUncalculatedSkillStats) do
			assert.is_true(seenKnownUncalculated[statId] == true, "stale Mercenary stat exemption: "..statId)
		end
		for _, classId in ipairs(mercenaries.classOrder) do
			for _, stat in ipairs(mercenaries.classes[classId].monster.stats or { }) do
				assert.is_true(data.mercenaryStatData.knownMonsterStats[stat.id] == true, classId..": "..stat.id)
			end
		end
		local seenKnownUncalculatedMinion = { }
		local unmappedMinionStats = { }
		for minionId, minion in pairs(mercenaries.minions or { }) do
			for _, stat in ipairs(minion.stats or { }) do
				local mapped = data.mercenarySupportStatMap[stat.id] ~= nil
				local knownMinion = data.knownUncalculatedMinionStats[stat.id] == true
				local knownMonster = data.mercenaryStatData.knownMonsterStats[stat.id] == true
				if not (mapped or knownMinion or knownMonster) then
					table.insert(unmappedMinionStats, minionId..": "..stat.id)
				end
				if knownMinion then seenKnownUncalculatedMinion[stat.id] = true end
			end
		end
		table.sort(unmappedMinionStats)
		assert.same({ }, unmappedMinionStats)
		for statId in pairs(data.knownUncalculatedMinionStats) do
			assert.is_true(seenKnownUncalculatedMinion[statId] == true, "stale Mercenary minion stat exemption: "..statId)
			assert.is_true(data.mercenarySupportStatMap[statId] == nil, "mapped minion stat listed as uncalculated: "..statId)
		end
		local relic = assert(data.minions["Metadata/Monsters/Mercenaries/MercenaryUnholyRelic_"])
		local curseImmune
		for _, mod in ipairs(relic.modList) do
			if mod.name == "CurseImmune" then curseImmune = true break end
		end
		assert.is_true(curseImmune)
		for supportId, templateId in pairs(data.mercenaryStatData.supportTemplates) do
			assert.is_table(mercenaries.supports[supportId], supportId)
			assert.is_table(data.skills[templateId], templateId)
			local grantedEffect = assert(data.mercenarySupportGrantedEffect(supportId), supportId)
			assert.is_true(grantedEffect.support, supportId)
			assert.are.equal(supportId, grantedEffect.mercenarySupportId)
			assert.are.equal("MercenarySupport:"..supportId, grantedEffect.id)
			assert.are.equal("Mercenary Support:"..supportId, grantedEffect.modSource)
		end
		assert.are.equal(5, mercenaries.supportCounts.High.maximum)
		assert.are.equal(0, mercenaries.supportCounts.None.maximum)
		for skillId, skill in pairs(mercenaries.skills) do
			assert.are.equal(skillId, skill.id)
		end
		for _, buildId in ipairs(mercenaries.buildOrder) do
			assert.is_table(assert(mercenaries.builds[buildId]).weaponConfiguration, buildId)
		end
		for policyId in pairs(data.mercenaryStatData.supportCounts) do
			local used = false
			for _, skill in pairs(mercenaries.skills) do
				if skill.supportCountId == policyId then used = true break end
			end
			assert.is_true(used, "unused support-count policy: "..policyId)
		end

		local statData = data.mercenaryStatData
		local problems = { }
		local declarationUsedBy = { }
		for skillId, grantedEffect in pairs(data.skills) do
			if grantedEffect.mercenary then
				local baseEffect = grantedEffect.inheritedFrom and data.skills[grantedEffect.inheritedFrom]
				for _, message in ipairs(tools.preDamageFuncErrors(grantedEffect, baseEffect, statData) or { }) do
					table.insert(problems, message)
				end
				if grantedEffect.inheritedFrom then
					assert.is_table(baseEffect, skillId)
					if grantedEffect.preDamageFunc == baseEffect.preDamageFunc then
						declarationUsedBy[grantedEffect.inheritedFrom] = skillId
					end
				end
			end
		end
		table.sort(problems)
		assert.are.equal("", table.concat(problems, "\n"))
		for skillId, reason in pairs(statData.droppedPreDamageFuncs) do
			local grantedEffect = assert(data.skills[skillId], skillId)
			assert.is_true(grantedEffect.mercenary, skillId)
			assert.is_string(reason)
			assert.is_nil(grantedEffect.preDamageFunc, skillId)
			assert.is_function(assert(data.skills[grantedEffect.inheritedFrom], skillId).preDamageFunc, skillId)
			local missing = assert(tools.missingPreDamageFuncInputs(grantedEffect, grantedEffect.inheritedFrom, statData), skillId)
			assert.is_true(#missing > 0, "no longer needs to drop its preDamageFunc: "..skillId)
			declarationUsedBy[grantedEffect.inheritedFrom] = skillId
		end
		for baseSkillId in pairs(statData.preDamageFuncInputs) do
			assert.is_function(assert(data.skills[baseSkillId], baseSkillId).preDamageFunc, baseSkillId)
			assert.is_string(declarationUsedBy[baseSkillId], "stale preDamageFunc input declaration: "..baseSkillId)
		end

		local gemSkills = { }
		for _, gem in pairs(data.gems) do
			if not gem.support then
				for _, skillId in ipairs({ gem.grantedEffectId, gem.secondaryGrantedEffectId }) do
					if skillId then gemSkills[skillId] = true end
				end
			end
		end
		local gemSkillByName = { }
		for skillId in pairs(gemSkills) do
			local name = data.skills[skillId].name
			if name and (not gemSkillByName[name] or skillId < gemSkillByName[name]) then
				gemSkillByName[name] = skillId
			end
		end
		for skillId, grantedEffect in pairs(data.skills) do
			local base = grantedEffect.mercenary and grantedEffect.inheritedFrom
			if base and not gemSkills[base] then
				assert.is_nil(gemSkillByName[data.skills[base].name], skillId.." inherits from "..base)
			end
		end

		local function stub() return { } end
		local export = require("Export.MercenaryExport")
		local statMap = LoadModule("Data/MercenaryStatMap")(stub, stub, stub)
		assert.is_nil(export.shieldPolicyError(data.mercenaries.builds, statMap.shieldPolicy))
		for buildId, mercBuild in pairs(data.mercenaries.builds) do
			local hasShield = false
			for _, itemType in ipairs(mercBuild.weaponTypes or { }) do
				if itemType == "Shield" then hasShield = true break end
			end
			if hasShield then
				local optional = statMap.shieldPolicy[buildId] == "optional"
				assert.are.equal(not optional, mercBuild.weaponConfiguration.offHandRequired, buildId)
			end
		end
	end)

	it("does not replace canonical item-granted skills with Mercenary variants", function()
		for modLine, expectedSkillId in pairs({
			["Grants Level 1 Icestorm Skill"] = "Icestorm",
			["Grants Level 15 Envy Skill"] = "Envy",
			["Grants Level 20 Aspect of the Spider Skill"] = "AspectOfTheSpider",
		}) do
			local mods = assert(modLib.parseMod(modLine))
			assert.are.equal(expectedSkillId, mods[1].value.skillId, modLine)
		end
	end)
end)
