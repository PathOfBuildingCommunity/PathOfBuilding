describe("Death Wish minion explosion", function()
	local function recalculate(group)
		if group then
			build.mainSocketGroup = group
			build.calcsTab.input.skill_number = group
		end
		build.buildFlag = true
		runCallback("OnFrame")
	end

	local function minionKey(groupIndex, gemIndex)
		local gem = build.skillsTab.socketGroupList[groupIndex].gemList[gemIndex or 1]
		return "minion:"..build.skillsTab:GetMinionSourceId(gem)..":"..gem.skillId
	end

	local function selectMinion(key)
		build.configTab.input.deathWishMinion = key
		recalculate(2)
	end

	local function explosionDamage()
		return build.calcsTab.mainEnv.player.mainSkill.skillData.FireBonusMin
	end

	before_each(function()
		newBuild()
		build.skillsTab:PasteSocketGroup("Summon Stone Golem 20/0  1\nMinion Life 20/0  1")
		build.itemsTab:CreateDisplayItemFromRaw([[Maw of Mischief
Bone Helmet
Grants Level 20 Death Wish Skill]])
		build.itemsTab:AddDisplayItem()
		recalculate(2)
	end)

	it("defaults to Minion Explosion in the sidebar and Calcs", function()
		assert.are.equal(2, build.calcsTab.mainEnv.player.mainSkill.skillPart)
		assert.are.equal(2, build.calcsTab.calcsEnv.player.mainSkill.skillPart)
	end)

	it("uses the summoning skill's calculated life and ignores corpse life", function()
		recalculate(1)
		local minionLife = build.calcsTab.mainOutput.Minion.Life
		assert.is_true(minionLife > 0)
		build.configTab.input.detonateDeadCorpseLife = 1000000
		build.configTab:BuildModList()
		selectMinion(minionKey(1))
		assert.are.equal(minionLife, build.calcsTab.mainOutput.DeathWishMinionLife)
		assert.are.near(minionLife * 0.19, explosionDamage(), 0.001)
		assert.are.equal(minionLife, build.calcsTab.calcsOutput.DeathWishMinionLife)
	end)

	it("updates when minion gem level, supports and global life scaling change", function()
		selectMinion(minionKey(1))
		local originalLife = build.calcsTab.mainOutput.DeathWishMinionLife
		build.skillsTab.socketGroupList[1].gemList[1].level = 25
		build.configTab.input.customMods = "Minions have 100% increased maximum Life"
		build.configTab:BuildModList()
		recalculate()
		local scaledLife = build.calcsTab.mainOutput.DeathWishMinionLife
		assert.is_true(scaledLife > originalLife)
		recalculate(1)
		assert.are.equal(scaledLife, build.calcsTab.mainOutput.Minion.Life)
		build.skillsTab.socketGroupList[1].gemList[2].enabled = false
		recalculate(2)
		assert.is_true(build.calcsTab.mainOutput.DeathWishMinionLife < scaledLife)
	end)

	it("falls back to enemy corpse life when no minion is selected", function()
		build.configTab.input.detonateDeadCorpseLife = 10000
		build.configTab:BuildModList()
		selectMinion("None")
		assert.is_nil(build.calcsTab.mainOutput.DeathWishMinionLife)
		assert.are.near(1900, explosionDamage(), 0.001)
	end)

	it("falls back when the selected minion is disabled or removed", function()
		build.configTab.input.detonateDeadCorpseLife = 10000
		build.configTab:BuildModList()
		selectMinion(minionKey(1))
		build.skillsTab.socketGroupList[1].enabled = false
		recalculate()
		assert.is_nil(build.calcsTab.mainOutput.DeathWishMinionLife)
		assert.are.near(1900, explosionDamage(), 0.001)
		selectMinion("9:1:SummonStoneGolem")
		assert.is_nil(build.calcsTab.mainOutput.DeathWishMinionLife)
	end)

	it("keeps channelling selectable without explosion damage", function()
		selectMinion(minionKey(1))
		local gem = build.skillsTab.socketGroupList[2].gemList[1]
		gem.skillPart = 1
		gem.skillPartCalcs = 1
		recalculate()
		assert.are.equal(1, build.calcsTab.mainEnv.player.mainSkill.skillPart)
		assert.is_nil(explosionDamage())
	end)

	it("saves and restores the selected minion", function()
		selectMinion(minionKey(1))
		local life = build.calcsTab.mainOutput.DeathWishMinionLife
		local xml = build:SaveDB("code")
		loadBuildFromXML(xml)
		assert.are.equal(minionKey(1), build.configTab.input.deathWishMinion)
		assert.are.equal(life, build.calcsTab.mainOutput.DeathWishMinionLife)
	end)

	it("distinguishes two sources of the same minion", function()
		build.skillsTab:PasteSocketGroup("Summon Stone Golem 1/0  1")
		recalculate(3)
		local lowLevelLife = build.calcsTab.mainOutput.Minion.Life
		selectMinion(minionKey(3))
		assert.are.equal(lowLevelLife, build.calcsTab.mainOutput.DeathWishMinionLife)
		selectMinion(minionKey(1))
		assert.is_true(build.calcsTab.mainOutput.DeathWishMinionLife > lowLevelLife)
	end)

	it("uses the selected spectre's calculated life", function()
		build.spectreList = { "Metadata/Monsters/BloodChieftain/MonkeyChiefBloodEnrage" }
		build.skillsTab:PasteSocketGroup("Raise Spectre 20/0  1\nMinion Life 20/0  1")
		recalculate(3)
		local spectreLife = build.calcsTab.mainOutput.Minion.Life
		selectMinion(minionKey(3))
		assert.are.equal(spectreLife, build.calcsTab.mainOutput.DeathWishMinionLife)
		assert.are.near(spectreLife * 0.19, explosionDamage(), 0.001)
	end)

	it("uses minion life in Full DPS and calculator comparisons", function()
		selectMinion(minionKey(1))
		build.skillsTab.socketGroupList[2].includeInFullDPS = true
		recalculate()
		local selectedDPS = build.calcsTab.mainOutput.FullDPS
		assert.is_true(selectedDPS > 0)
		local calculator = build.calcsTab.calcs.getMiscCalculator(build)
		local result = calculator({ }, false)
		assert.are.equal(build.calcsTab.mainOutput.DeathWishMinionLife, result.DeathWishMinionLife)
		build.configTab.input.detonateDeadCorpseLife = 1000000
		build.configTab:BuildModList()
		recalculate()
		assert.are.equal(selectedDPS, build.calcsTab.mainOutput.FullDPS)
	end)

	it("keeps the selected source when groups are reordered and saved", function()
		build.skillsTab:PasteSocketGroup("Summon Stone Golem 1/0  1")
		selectMinion(minionKey(1))
		local key = build.configTab.input.deathWishMinion
		local life = build.calcsTab.mainOutput.DeathWishMinionLife
		local groups = build.skillsTab.socketGroupList
		table.insert(groups, 3, table.remove(groups, 1))
		build.skillsTab.controls.groupList:OnOrderChange(1, 3)
		recalculate()
		assert.are.equal(key, build.configTab.input.deathWishMinion)
		assert.are.equal(life, build.calcsTab.mainOutput.DeathWishMinionLife)
		loadBuildFromXML(build:SaveDB("code"))
		assert.are.equal(key, build.configTab.input.deathWishMinion)
		assert.are.equal(life, build.calcsTab.mainOutput.DeathWishMinionLife)
	end)

	it("keeps the selected source when gems are reordered and undone", function()
		selectMinion(minionKey(1))
		local key = build.configTab.input.deathWishMinion
		local life = build.calcsTab.mainOutput.DeathWishMinionLife
		local state = build.skillsTab:CreateUndoState()
		local gems = build.skillsTab.socketGroupList[1].gemList
		table.insert(gems, table.remove(gems, 1))
		recalculate()
		assert.are.equal(life, build.calcsTab.mainOutput.DeathWishMinionLife)
		build.skillsTab:RestoreUndoState(state)
		recalculate()
		assert.are.equal(key, build.configTab.input.deathWishMinion)
		assert.are.equal(life, build.calcsTab.mainOutput.DeathWishMinionLife)
	end)

	it("does not select a replacement gem after its source is deleted", function()
		selectMinion(minionKey(1))
		local key = build.configTab.input.deathWishMinion
		table.remove(build.skillsTab.socketGroupList[1].gemList, 1)
		recalculate()
		assert.is_nil(build.calcsTab.mainOutput.DeathWishMinionLife)
		loadBuildFromXML(build:SaveDB("code"))
		build.skillsTab:PasteSocketGroup("Summon Stone Golem 20/0  1")
		recalculate(2)
		assert.are.equal(key, build.configTab.input.deathWishMinion)
		assert.is_nil(build.calcsTab.mainOutput.DeathWishMinionLife)
		assert.is_true(minionKey(3) ~= key)
	end)

	it("migrates selections saved with group positions", function()
		selectMinion("1:1:SummonStoneGolem")
		assert.are.equal(minionKey(1), build.configTab.input.deathWishMinion)
		assert.is_true(build.calcsTab.mainOutput.DeathWishMinionLife > 0)
	end)

	it("populates the selector with enabled minions and a corpse fallback", function()
		local control = build.configTab.varControls.deathWishMinion
		control.refreshList()
		assert.are.equal(2, #control.list)
		assert.are.equal("None", control.list[1].val)
		assert.are.equal(minionKey(1), control.list[2].val)
		control.selFunc(2, control.list[2])
		recalculate()
		assert.is_true(build.calcsTab.mainOutput.DeathWishMinionLife > 0)
	end)
end)
