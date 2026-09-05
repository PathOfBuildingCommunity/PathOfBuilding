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

	it("routes comparison output and overrides by actor", function()
		assert.are.equal("Helmet", tools.baseItemSlotName("Mercenary Helmet"))
		assert.is_nil(tools.baseItemSlotName("Helmet"))
		assert.is_nil(tools.baseItemSlotName(1))

		local playerOutput = { CombinedDPS = 100, FullDPS = 1000, FullDotDPS = 10 }
		local mercenaryOutput = { CombinedDPS = 50, FullDPS = 50, FullDotDPS = 1 }
		assert.is_nil(tools.comparisonBaseOutput(playerOutput, { PLAYER = playerOutput }, "Mercenary Helmet"))
		assert.are.equal(playerOutput, tools.comparisonBaseOutput(playerOutput, { PLAYER = playerOutput }, "Helmet"))
		assert.is_true(not tools.mercenaryOutputAvailable(nil))
		assert.is_true(not tools.mercenaryOutputAvailable({ ActorUnavailableMessage = "missing" }))
		local routed = tools.comparisonBaseOutput(playerOutput, {
			PLAYER = playerOutput,
			MERCENARY = mercenaryOutput,
		}, "Mercenary Helmet")
		assert.are.equal(50, routed.CombinedDPS)
		assert.are.equal(1000, routed.FullDPS)
		assert.are.equal(10, routed.FullDotDPS)
		assert.are.equal(50, mercenaryOutput.FullDPS)
		assert.are_not.equal(mercenaryOutput, routed)
		assert.is_true(tools.mercenaryOutputAvailable(mercenaryOutput))
		assert.are.equal(mercenaryOutput, tools.buildComparisonOutput(mercenaryOutput, nil))
		local unavailable = { ActorUnavailableMessage = "missing" }
		assert.are.equal(unavailable, tools.buildComparisonOutput(unavailable, playerOutput))

		local auxiliary = {
			activeItemSetId = 1,
			build = { mercenaryTab = { itemSetId = 2, auxiliaryItemSetId = 2 } },
		}
		assert.are.equal("MERCENARY", tools.comparisonActorForItemSet(2, auxiliary))
		assert.are.equal("PLAYER", tools.comparisonActorForItemSet(1, {
			activeItemSetId = 1,
			build = { mercenaryTab = { itemSetId = 1 } },
		}))
		assert.are.equal("PLAYER", tools.comparisonActorForItemSet(3, auxiliary))
		assert.are.equal("PLAYER", tools.comparisonActorForItemSet(2, {
			activeItemSetId = 1,
			build = { mercenaryTab = { itemSetId = 2 } },
		}))
		assert.are.equal("MERCENARY", tools.comparisonActorForSlot("Helmet", 2, auxiliary))
		assert.are.equal("MERCENARY", tools.comparisonActorForSlot("Mercenary Helmet", 1, {
			activeItemSetId = 1,
			build = { mercenaryTab = { itemSetId = 2 } },
		}))

		local shared = {
			activeItemSetId = 1,
			viewItemSetId = 1,
			viewComparisonActor = "MERCENARY",
			build = { mercenaryTab = { itemSetId = 1 } },
		}
		assert.are.equal("MERCENARY", tools.comparisonActorForItemSet(1, shared))
		assert.are.equal("MERCENARY", tools.comparisonActorForSlot("Helmet", 1, shared))
		shared.viewComparisonActor = "PLAYER"
		assert.are.equal("PLAYER", tools.comparisonActorForItemSet(1, shared))
		assert.are.equal("PLAYER", tools.comparisonActorForSlot("Helmet", 1, shared))

		assert.is_true(tools.isAuxiliaryMercenaryItemSet(2, {
			activeItemSetId = 1,
			viewItemSetId = 1,
			viewComparisonActor = "MERCENARY",
			build = { mercenaryTab = { itemSetId = 2, auxiliaryItemSetId = 2 } },
		}))
		assert.is_true(not tools.isAuxiliaryMercenaryItemSet(1, {
			activeItemSetId = 1,
			viewItemSetId = 1,
			viewComparisonActor = "MERCENARY",
			build = { mercenaryTab = { itemSetId = 1 } },
		}))
		assert.is_true(not tools.isAuxiliaryMercenaryItemSet(2, {
			activeItemSetId = 1,
			viewItemSetId = 1,
			build = { mercenaryTab = { itemSetId = 2 } },
		}))

		local item = { name = "hat" }
		local override = tools.itemCalculationOverride(2, "Helmet", item, auxiliary)
		assert.are.equal(2, override.itemSetId)
		assert.are.equal("MERCENARY", override.comparisonActor)
		assert.are.equal("Helmet", override.repSlotName)
		assert.are.equal(item, override.repItem)

		local jewelTab = {
			activeItemSetId = 1,
			viewItemSetId = 2,
			build = { mercenaryTab = { itemSetId = 2 } },
		}
		assert.are.equal("PLAYER", tools.comparisonActorForSlot("Jewel 12345", 2, jewelTab))
		local jewelOverride = tools.itemCalculationOverride(2, "Jewel 12345", { name = "jewel" }, jewelTab)
		assert.is_nil(jewelOverride.itemSetId)
		assert.are.equal("PLAYER", jewelOverride.comparisonActor)

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
Vreka, the Killer
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
