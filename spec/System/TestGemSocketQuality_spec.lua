describe("TestGemSocketQuality", function()
	before_each(function()
		newBuild()
	end)

	-- 3 blue socket body armour
	local function equipBody(sockets, extraLines)
		build.itemsTab:CreateDisplayItemFromRaw(
			"Rarity: RARE\nTest Robe\nSage's Robe\nQuality: 0\nSockets: " .. sockets .. "\nImplicits: 0\n" .. (extraLines or ""))
		build.itemsTab:AddDisplayItem()
	end

	-- get specific socket group linked to a slot
	local function groupForSlot(slotName, index)
		local seen = 0
		for _, group in ipairs(build.skillsTab.socketGroupList) do
			if group.slot == slotName then
				seen = seen + 1
				if seen == (index or 1) then
					return group
				end
			end
		end
	end

	it("grants +10% quality to a gem in a matching colour socket", function()
		equipBody("B-B-B")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local group = groupForSlot("Body Armour")
		assert.is_true(group.gemList[1].matchesSocket)
		assert.are.equals(10, build.calcsTab.mainOutput.GemQuality)
		-- The bonus must reach the calculations, not just the displayed number:
		-- activeEffect.quality is the value fed to buildSkillInstanceStats.
		assert.are.equals(10, build.calcsTab.mainEnv.player.mainSkill.activeEffect.quality)
	end)

	it("adds the socket bonus on top of the gem's own quality", function()
		equipBody("B-B-B")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/5  1\n")
		runCallback("OnFrame")

		assert.are.equals(15, build.calcsTab.mainOutput.GemQuality)
	end)

	it("grants no bonus to a gem in a mismatched colour socket", function()
		equipBody("R-W-R")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local group = groupForSlot("Body Armour")
		assert.is_false(group.gemList[1].matchesSocket)
		assert.is_false(group.gemList[2].matchesSocket)
		assert.are.equals(0, build.calcsTab.mainOutput.GemQuality)
		assert.are.equals(0, build.calcsTab.mainEnv.player.mainSkill.activeEffect.quality)
	end)

	it("applies the socket quality bonus to the skill's quality-scaled stats", function()
		equipBody("B-B-B")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		-- Fireball aoe explosion
		build.calcsTab.input.skillPart = 2
		runCallback("OnFrame")
		assert.are.equals(10, build.calcsTab.mainEnv.player.mainSkill.activeEffect.quality)
		local matchedRadius = build.calcsTab.mainOutput.AreaOfEffectRadius

		newBuild()
		equipBody("R-R-R")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		build.calcsTab.input.skillPart = 2
		runCallback("OnFrame")
		assert.are.equals(0, build.calcsTab.mainEnv.player.mainSkill.activeEffect.quality)
		local unmatchedRadius = build.calcsTab.mainOutput.AreaOfEffectRadius

		assert.is_true(matchedRadius > unmatchedRadius)
	end)

	it("grants no bonus to a white/colourless gem", function()
		equipBody("W-W-W")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nPortal 20/0  1\n")
		runCallback("OnFrame")

		local group = groupForSlot("Body Armour")
		assert.is_false(group.gemList[1].matchesSocket)
	end)

	it("adds quality when an item is equipped and removes it when unequipped", function()
		equipBody("B-B-B")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		runCallback("OnFrame")
		assert.are.equals(10, build.calcsTab.mainOutput.GemQuality)

		-- Unequip the body armour
		build.itemsTab.slots["Body Armour"]:SetSelItemId(0)
		build.buildFlag = true
		runCallback("OnFrame")

		local group = groupForSlot("Body Armour")
		assert.is_false(group.gemList[1].matchesSocket)
		assert.are.equals(0, build.calcsTab.mainOutput.GemQuality)
	end)

	it("always grants the bonus with Dialla's 'always matches' mod", function()
		-- Blue gem in a red socket
		equipBody("R-R-R", "Gems Socketed always have the Quality bonus from Socket Colour\n")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		runCallback("OnFrame")

		local item = build.itemsTab.items[build.itemsTab.slots["Body Armour"].selItemId]
		assert.is_true(item.sockets.colourAlwaysMatches)

		local group = groupForSlot("Body Armour")
		assert.is_true(group.gemList[1].matchesSocket)
		assert.are.equals(10, build.calcsTab.mainOutput.GemQuality)
		assert.are.equals(10, build.calcsTab.mainEnv.player.mainSkill.activeEffect.quality)
	end)

	it("respects socket order across split groups on one item", function()
		-- Sockets are Blue then Red. The first group's gem lines up with the
		-- blue socket, the second group's gem continues at the red socket
		equipBody("B-R")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nAbsolution 20/0  1\n")
		runCallback("OnFrame")

		local blueGroup = groupForSlot("Body Armour", 1)
		local redGroup = groupForSlot("Body Armour", 2)
		-- Fireball (blue) matches socket 1
		assert.is_true(blueGroup.gemList[1].matchesSocket)
		-- Absolution (red) only matches if the offset continues at socket 2
		assert.is_true(redGroup.gemList[1].matchesSocket)
	end)

	it("does not grant the bonus when split order breaks the match", function()
		-- Both sockets blue: the red gem in the second group should not match
		equipBody("R-B")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\n")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nAbsolution 20/0  1\n")
		runCallback("OnFrame")

		assert.is_false(groupForSlot("Body Armour", 1).gemList[1].matchesSocket)
		assert.is_false(groupForSlot("Body Armour", 2).gemList[1].matchesSocket)
	end)

	it("Optimise Sockets recolours an item to match its assigned gems", function()
		equipBody("R-R-R-R")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\nAbsolution 20/0  1\n")
		runCallback("OnFrame")

		build.skillsTab.controls.optimiseSockets.onClick()
		runCallback("OnFrame")

		local item = build.itemsTab.items[build.itemsTab.slots["Body Armour"].selItemId]
		assert.are.equals(2, #item.sockets)
		assert.are.equals("B", item.sockets[1].color)
		assert.are.equals("R", item.sockets[2].color)

		local group = groupForSlot("Body Armour")
		assert.is_true(group.gemList[1].matchesSocket)
		assert.is_true(group.gemList[2].matchesSocket)
	end)

	it("Optimise Sockets does not exceed the item's socket limit", function()
		equipBody("R")
		-- Assign more gems than the base's 6 socket limit
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\n" ..
			("Fireball 20/0  1\n"):rep(8))
		runCallback("OnFrame")

		build.skillsTab.controls.optimiseSockets.onClick()
		runCallback("OnFrame")

		local item = build.itemsTab.items[build.itemsTab.slots["Body Armour"].selItemId]
		assert.is_true(#item.sockets <= item.base.socketLimit)
		assert.are.equals(6, #item.sockets)
	end)
	it("Optimise Sockets preserves abyssal sockets and stays within the limit", function()
		equipBody("A-R-R")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\nAbsolution 20/0  1\n")
		runCallback("OnFrame")

		build.skillsTab.controls.optimiseSockets.onClick()
		runCallback("OnFrame")

		local item = build.itemsTab.items[build.itemsTab.slots["Body Armour"].selItemId]
		local abyssal = 0
		for _, socket in ipairs(item.sockets) do
			if socket.color == "A" then
				abyssal = abyssal + 1
			end
		end
		assert.are.equals(1, abyssal)
		assert.is_true(#item.sockets <= item.base.socketLimit)
	end)

	-- find controlled destruction increased damage mod
	local function supportQualityDamageMod()
		local mainSkill = build.calcsTab.mainEnv.player.mainSkill
		for _, entry in ipairs(mainSkill.skillModList:Tabulate("INC", mainSkill.skillCfg, "Damage")) do
			if entry.mod.source == "Skill:SupportControlledDestruction" then
				return entry.mod
			end
		end
	end

	it("applies the socket bonus to a support gem's effective quality", function()
		equipBody("B-B")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\nControlled Destruction 20/0  1\n")
		runCallback("OnFrame")

		local group = groupForSlot("Body Armour")
		assert.is_true(group.gemList[2].matchesSocket)

		-- check that the actual 5% damage mod exists
		local mod = supportQualityDamageMod()
		assert.is_not_nil(mod)
		assert.are.equals(5, mod.value)

		-- and check that the mod is gone without the socket quality bonus
		newBuild()
		equipBody("R-R")
		build.skillsTab:PasteSocketGroup("Slot: Body Armour\nFireball 20/0  1\nControlled Destruction 20/0  1\n")
		runCallback("OnFrame")

		assert.is_false(groupForSlot("Body Armour").gemList[2].matchesSocket)
		assert.is_nil(supportQualityDamageMod())
	end)
end)
