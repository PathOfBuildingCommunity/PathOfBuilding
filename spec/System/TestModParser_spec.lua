describe("TestModParser", function()
	local function getMasterDistillerCritMultiplier(skillTypes, hasDiamondFlask)
		local mods = modLib.parseMod("If Diamond Flask Charges are consumed, +100% to Critical Strike Multiplier")
		local modDB = new("ModDB"):ModDB()
		modDB:AddList(mods)
		modDB.conditions.HaveDiamondFlask = hasDiamondFlask
		return modDB:Sum("BASE", { skillTypes = skillTypes }, "CritMultiplier")
	end

	it("parses the Master Distiller diamond flask bonus as critical strike multiplier", function()
		local mods, extra = modLib.parseMod("If Diamond Flask Charges are consumed, +100% to Critical Strike Multiplier")

		assert.is_nil(extra)
		assert.are.equal(1, #mods)
		assert.are.equal("CritMultiplier", mods[1].name)
		assert.are.equal("BASE", mods[1].type)
		assert.are.equal(100, mods[1].value)
		assert.are.same({ type = "SkillType", skillType = SkillType.Triggered, neg = true }, mods[1][1])
		assert.are.same({ type = "SkillType", skillType = SkillType.Channel, neg = true }, mods[1][2])
		assert.are.same({ type = "Condition", var = "HaveDiamondFlask" }, mods[1][3])
	end)

	it("applies the Master Distiller diamond flask bonus only to eligible skills while the flask is present", function()
		assert.are.equal(100, getMasterDistillerCritMultiplier({}, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier({}, false))
		assert.are.equal(0, getMasterDistillerCritMultiplier({ [SkillType.Triggered] = true }, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier({ [SkillType.Channel] = true }, true))
	end)

	it("keeps the legacy Master Distiller diamond flask bonus as critical strike chance", function()
		local mods, extra = modLib.parseMod("If Diamond Flask Charges are consumed, 250% increased Critical Strike Chance")

		assert.is_nil(extra)
		assert.are.equal("CritChance", mods[1].name)
		assert.are.equal("INC", mods[1].type)
		assert.are.equal(250, mods[1].value)
	end)
end)
