describe("Vaal Caress Onslaught", function()
	local function addGloves(variant)
		build.itemsTab:CreateDisplayItemFromRaw(main.uniqueDB.byTitle["vaal caress"]:BuildRaw())
		build.itemsTab.displayItem.variant = variant
		build.itemsTab.displayItem:BuildModList()
		build.itemsTab:AddDisplayItem()
	end

	local function allocateNotable()
		build.spec:SelectClass(0)
		for id, ascendancy in pairs(build.spec.curClass.classes) do
			if ascendancy.name == "Reliquarian" then
				build.spec:SelectAscendClass(id)
			end
		end
		assert.are.equal("Reliquarian", build.spec.curAscendClassName)
		local vaalCaress
		for _, node in pairs(build.spec.nodes) do
			if node.dn == "Vaal Caress" and node.ascendancyName == "Reliquarian" then
				vaalCaress = node
			end
		end
		assert.is_not_nil(vaalCaress)
		build.spec:AllocNode(vaalCaress)
		assert.is_true(vaalCaress.alloc)
		build.buildFlag = true
	end

	local function configure(input)
		for _, name in ipairs({ "conditionUsedVaalSkillRecently", "buffOnslaught" }) do
			build.configTab.input[name] = input[name]
		end
		build.configTab:BuildModList()
		runCallback("OnFrame")
	end

	for _, case in ipairs({
		{ name = "current gloves", setup = function() addGloves(3) end },
		{ name = "legacy gloves", setup = function() addGloves(2) end },
		{ name = "Reliquarian notable", setup = allocateNotable },
		{ name = "Ruthless Reliquarian notable", setup = function()
			build.spec:Init(latestTreeVersion .. "_ruthless")
			allocateNotable()
		end, movement = false },
	}) do
		it("applies " .. case.name .. " to an ordinary spell after recent Vaal skill use", function()
			newBuild()
			case.setup()
			build.skillsTab:PasteSocketGroup("Fireball 20/0  1\n")
			runCallback("OnFrame")
			assert.are.equal("Fireball", build.calcsTab.mainEnv.player.mainSkill.activeEffect.grantedEffect.name)
			assert.is_falsy(build.calcsTab.mainEnv.player.mainSkill.skillTypes[SkillType.Vaal])
			local inactiveMovement = build.calcsTab.mainOutput.MovementSpeedMod
			local inactiveSpeed = build.calcsTab.mainOutput.Speed
			local mainSkill = build.calcsTab.mainEnv.player.mainSkill
			local inactiveSpeedInc = mainSkill.skillModList:Sum("INC", mainSkill.skillCfg, "Speed")
			local function check(active)
				if case.movement ~= false then
					assert.are.near(inactiveMovement + (active and 0.2 or 0), build.calcsTab.mainOutput.MovementSpeedMod, 1e-9)
				end
				if active then
					assert.are.near(inactiveSpeed * (1 + 20 / (100 + inactiveSpeedInc)), build.calcsTab.mainOutput.Speed, 1e-9)
				else
					assert.are.equal(inactiveSpeed, build.calcsTab.mainOutput.Speed)
				end
			end

			configure({ conditionUsedVaalSkillRecently = true })
			check(true)
			configure({})
			check(false)
			configure({ conditionUsedVaalSkillRecently = true, buffOnslaught = true })
			check(true)
			configure({ buffOnslaught = true })
			check(true)
			configure({})
			check(false)
		end)
	end

	it("automatically grants Onslaught while using a main Vaal skill", function()
		newBuild()
		addGloves(3)
		runCallback("OnFrame")
		local inactiveMovement = build.calcsTab.mainOutput.MovementSpeedMod
		build.skillsTab:PasteSocketGroup("Vaal Arc 20/0  1\n")
		runCallback("OnFrame")
		assert.is_true(build.calcsTab.mainEnv.player.mainSkill.skillTypes[SkillType.Vaal])
		assert.are.near(inactiveMovement + 0.2, build.calcsTab.mainOutput.MovementSpeedMod, 1e-9)
	end)
end)
