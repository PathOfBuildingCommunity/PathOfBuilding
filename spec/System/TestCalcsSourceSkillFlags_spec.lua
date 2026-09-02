describe("Calcs source-skill flag visibility", function()
	local MercenaryTest = dofile("../spec/System/MercenaryTestHelpers.lua")
	local allocatePermanentHire = MercenaryTest.allocatePermanentHire
	local function skillSelectRow(label)
		for _, section in ipairs(build.calcsTab.sectionList) do
			if section.id == "SkillSelect" then
				for _, row in ipairs(section.subSection[1].data) do
					if row.label == label then return row end
				end
			end
		end
	end

	before_each(function()
		newBuild()
	end)

	it("keeps the calculation actor dropdown populated after refresh", function()
		assert.are.equal(4, #calcLib.calculationActorList)
		build.calcsTab:SyncActorList()
		build.calcsTab:SyncActorList()
		local actor = build.calcsTab.skillSelectSection.controls.actor
		assert.is_true(#actor.list >= 2)
		assert.are.equal("PLAYER", actor.list[1].actorId)
		assert.are.equal(4, #calcLib.calculationActorList)
	end)

	it("follows source-skill flags for player, minion, and Mercenary actors", function()
		for _, case in ipairs({
			{ label = "Skill Part", flag = "multiPart" },
			{ label = "Skill Stages", flag = "multiStage" },
			{ label = "Active Mines", flag = "mine" },
		}) do
			local row = assert(skillSelectRow(case.label), case.label)
			assert.are.equal(case.flag, row.playerFlag, case.label)
			assert.is_nil(row.flag, case.label)
		end

		build.skillsTab:PasteSocketGroup("Arc 20/0  1")
		runCallback("OnFrame")
		build.calcsTab.input.actor = "PLAYER"
		assert.is_true(not build.calcsTab:CheckFlag(skillSelectRow("Skill Part")))
		build.calcsTab.calcsEnv.player.mainSkill.skillFlags.multiPart = true
		assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Skill Part")))

		newBuild()
		build.skillsTab:PasteSocketGroup("Summon Raging Spirit 20/0  1")
		runCallback("OnFrame")
		local env = assert(build.calcsTab.calcsEnv)
		local playerFlags = env.player.mainSkill.skillFlags
		local minionFlags = env.minion.mainSkill.skillFlags
		playerFlags.multiPart, playerFlags.multiStage, playerFlags.mine = true, true, true
		minionFlags.multiPart, minionFlags.multiStage, minionFlags.mine = nil, nil, nil
		build.calcsTab.input.actor = "PLAYER_MINION"
		assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Skill Part")))
		assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Skill Stages")))
		assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Active Mines")))

		newBuild()
		allocatePermanentHire()
		local profile = build.mercenaryTab.profile
		profile.classId = "AurasMinionsTemplar"
		profile.buildId = "AurasMinionsTemplarSmite"
		profile.foundAreaLevel = 68
		profile.mainSkillId = "SSMHolySpectresMercenary"
		profile.lifeComparison = "AUTO"
		profile.skills = { { id = "SSMHolySpectresMercenary", enabled = true, includeInFullDPS = false, count = 1, supports = { } } }
		local itemSet = build.mercenaryTab:GetItemSet(true)
		local mace = new("Item"):Item("Rarity: Normal\nDriftwood Club")
		local shield = new("Item"):Item("Rarity: Normal\nTwig Spirit Shield")
		build.itemsTab:AddItem(mace, true)
		build.itemsTab:AddItem(shield, true)
		itemSet["Weapon 1"].selItemId = mace.id
		itemSet["Weapon 2"].selItemId = shield.id
		build.mercenaryTab:Changed()
		build.configTab.input.enemyLevel = 83
		build.configTab:BuildModList()
		build.spec.modFlag = true
		build.buildFlag = true
		runCallback("OnFrame")
		runCallback("OnFrame")
		env = assert(build.calcsTab.calcsEnv)
		assert.is_table(env.mercenary)
		assert.is_table(env.mercenaryMinion)
		playerFlags = env.player.mainSkill.skillFlags
		local mercenaryFlags = env.mercenary.mainSkill.skillFlags
		minionFlags = env.mercenaryMinion.mainSkill.skillFlags
		playerFlags.multiPart, playerFlags.multiStage, playerFlags.mine = nil, nil, nil
		mercenaryFlags.multiPart, mercenaryFlags.multiStage, mercenaryFlags.mine = true, true, true
		minionFlags.multiPart, minionFlags.multiStage, minionFlags.mine = nil, nil, nil
		for _, actor in ipairs({ "MERCENARY", "MERCENARY_MINION" }) do
			build.calcsTab.input.actor = actor
			assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Skill Part")), actor)
			assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Skill Stages")), actor)
			assert.is_true(build.calcsTab:CheckFlag(skillSelectRow("Active Mines")), actor)
		end
		mercenaryFlags.multiPart, mercenaryFlags.multiStage, mercenaryFlags.mine = nil, nil, nil
		build.calcsTab.input.actor = "MERCENARY_MINION"
		assert.is_true(not build.calcsTab:CheckFlag(skillSelectRow("Skill Part")))
	end)
end)
