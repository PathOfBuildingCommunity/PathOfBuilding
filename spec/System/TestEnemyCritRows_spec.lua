describe("TestEnemyCritRows", function()
	local function findRow(label)
		for _, section in ipairs(LoadModule("Modules/CalcSections")) do
			for _, subSection in ipairs(section[5] or {}) do
				for _, row in ipairs(subSection.data or {}) do
					if row.label == label then
						return row
					end
				end
			end
		end
	end

	local function calc(mods)
		newBuild()
		build.configTab.input.customMods = mods
		build.configTab:BuildModList()
		runCallback("OnFrame")
		build.calcsTab:BuildOutput()
		return build.calcsTab.mainOutput, build.calcsTab.mainEnv.player.breakdown
	end

	it("labels the Watcher's Eye mod as extra crit damage reduction, not crit chance (issue #5417)", function()
		assert.is_nil(findRow("Crit Reduction"))
		local row = findRow("Crit Extra Dmg Red.")
		assert.is_not_nil(row)
		assert.are.equals("ReduceCritExtraDamage", row[1][1].modName)
		assert.is_not_nil(findRow("Enemy Crit Ch."))
	end)

	it("parses reduced critical strike chance against you (Crucible shield mods)", function()
		local output = calc("Hits have 50% reduced Critical Strike Chance against you\nYou take 30% reduced Extra Damage from Critical Strikes")
		assert.are.equals(2.5, output.EnemyCritChance)
		assert.are.equals(30, output.CritExtraDamageReduction)
	end)

	it("explains the enemy crit chance in a breakdown (issue #5417)", function()
		local output, breakdown = calc("Hits have 50% reduced Critical Strike Chance against you")
		assert.are.same({ "5.00% ^8(base, from Configuration)", "x 0.50 ^8(increased/reduced)", "= 2.50%" }, breakdown.EnemyCritChance)
		output, breakdown = calc("Hits against you are always Critical Strikes")
		assert.are.equals(100, output.EnemyCritChance)
		assert.are.same({ "Enemy always Critically Strikes" }, breakdown.EnemyCritChance)
	end)
end)
