describe("TestCalcSections", function()
	-- Collect every hit "Effective DPS Mod" cell: the breakdown cells whose enemy rows list the hit taken mods
	local function collectEffMultCells(sections)
		local cells = { }
		for _, section in ipairs(sections) do
			for _, subSection in ipairs(section[5] or { }) do
				for _, row in ipairs(subSection.data or { }) do
					if type(row) == "table" then
						for _, cell in ipairs(row) do
							if type(cell) == "table" and cell[1] and type(cell[1].breakdown) == "string" and cell[1].breakdown:match("EffMult$") then
								for _, entry in ipairs(cell) do
									if entry.label == "Enemy modifiers" and type(entry.modName) == "table" and entry.modName[#entry.modName] == "CurseEffectOnSelf" then
										table.insert(cells, cell)
										break
									end
								end
							end
						end
					end
				end
			end
		end
		return cells
	end

	local function findRow(cell, modName)
		for _, entry in ipairs(cell) do
			if entry.enemy and entry.modName == modName then
				return entry
			end
		end
	end

	it("lists damage taken from projectiles, projectile attacks and traps/mines in the effective DPS mod breakdown", function()
		local cells = collectEffMultCells(LoadModule("Modules/CalcSections"))
		-- 5 damage types for the skill, weapon 1 and weapon 2 sections
		assert.are.equals(15, #cells)
		for _, cell in ipairs(cells) do
			local name = cell[1].breakdown
			local projectile = findRow(cell, "ProjectileDamageTaken")
			assert.is_not_nil(projectile, name.." is missing ProjectileDamageTaken")
			assert.are.equals("projectile", projectile.flag)
			local projectileAttack = findRow(cell, "ProjectileAttackDamageTaken")
			assert.is_not_nil(projectileAttack, name.." is missing ProjectileAttackDamageTaken")
			assert.are.same({ "projectile", "attack" }, projectileAttack.flagList)
			local trapMine = findRow(cell, "TrapMineDamageTaken")
			assert.is_not_nil(trapMine, name.." is missing TrapMineDamageTaken")
			assert.are.same({ "trap", "mine" }, trapMine.anyFlagList)
		end
	end)

	it("shows Sniper's Mark in the effective DPS mod breakdown only for projectile skills", function()
		local fireCell
		for _, cell in ipairs(collectEffMultCells(LoadModule("Modules/CalcSections"))) do
			if cell[1].breakdown == "FireEffMult" then
				fireCell = cell
			end
		end
		-- Sources listed in the Fire Effective DPS Mod breakdown, as the Calcs tab builds it
		local function breakdownSources(skill)
			newBuild()
			build.skillsTab:PasteSocketGroup(skill.." 20/0  1\n")
			build.skillsTab:PasteSocketGroup("Sniper's Mark 20/0  1\n")
			runCallback("OnFrame")
			local breakdown = build.calcsTab.controls.breakdown
			breakdown:SetBreakdownData(fireCell)
			local sources = { }
			for _, section in ipairs(breakdown.sectionList) do
				for _, row in ipairs(section.rowList or { }) do
					sources[row.mod.name] = row.sourceName
				end
			end
			return sources
		end

		local fireball = breakdownSources("Fireball")
		assert.are.equals("Sniper's Mark", fireball.ProjectileDamageTaken)
		local arc = breakdownSources("Arc")
		assert.is_nil(arc.ProjectileDamageTaken)
	end)

	it("shows trap and mine damage taken for either a trap or a mine skill", function()
		local calcsTab = { calcsEnv = { player = { mainSkill = { skillFlags = { } } } }, input = { } }
		local check = function(flags)
			calcsTab.calcsEnv.player.mainSkill.skillFlags = flags
			return build.calcsTab.CheckFlag(calcsTab, { anyFlagList = { "trap", "mine" } })
		end
		assert.is_true(check({ trap = true }))
		assert.is_true(check({ mine = true }))
		assert.is_nil(check({ projectile = true }))
	end)
end)
