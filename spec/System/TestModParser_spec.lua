describe("TestModParser", function()
	local function getMasterDistillerCritMultiplier(value, skillTypes, hasDiamondFlask)
		local mods, extra = modLib.parseMod("If Diamond Flask Charges are consumed, +" .. value .. "% to Critical Strike Multiplier")
		assert.is_nil(extra)
		local modDB = new("ModDB"):ModDB()
		modDB:AddList(mods)
		modDB.conditions.HaveDiamondFlask = hasDiamondFlask
		return modDB:Sum("BASE", { skillTypes = skillTypes }, "CritMultiplier")
	end

	it("recognises Crab Totems from The Crustacean's Call without changing Spell Totem damage", function()
		local mods, extra = modLib.parseMod("Skills Supported by Spell Totem are Crab Totems")
		assert.is_not_nil(mods)
		assert.is_nil(extra)

		newBuild()
		build.skillsTab:PasteSocketGroup("Fireball 20/0  1\nSpell Totem 20/0  1")
		runCallback("OnFrame")
		local baseDPS = build.calcsTab.mainOutput.TotalDPS
		build.configTab.input.customMods = "Skills Supported by Spell Totem are Crab Totems"
		build.configTab:BuildModList()
		runCallback("OnFrame")
		assert.are.equal(baseDPS, build.calcsTab.mainOutput.TotalDPS)
	end)

	it("applies the Master Distiller diamond flask bonus only to eligible skills while the flask is present", function()
		assert.are.equal(100, getMasterDistillerCritMultiplier(100, {}, true))
		assert.are.equal(60, getMasterDistillerCritMultiplier(60, {}, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier(100, {}, false))
		assert.are.equal(0, getMasterDistillerCritMultiplier(100, { [SkillType.Triggered] = true }, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier(100, { [SkillType.Channel] = true }, true))
	end)
end)
