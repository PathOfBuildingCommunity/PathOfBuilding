describe("TestModParser", function()
	local function getMasterDistillerCritMultiplier(skillTypes, hasDiamondFlask)
		local mods, extra = modLib.parseMod("If Diamond Flask Charges are consumed, +100% to Critical Strike Multiplier")
		assert.is_nil(extra)
		local modDB = new("ModDB"):ModDB()
		modDB:AddList(mods)
		modDB.conditions.HaveDiamondFlask = hasDiamondFlask
		return modDB:Sum("BASE", { skillTypes = skillTypes }, "CritMultiplier")
	end

	it("applies the Master Distiller diamond flask bonus only to eligible skills while the flask is present", function()
		assert.are.equal(100, getMasterDistillerCritMultiplier({}, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier({}, false))
		assert.are.equal(0, getMasterDistillerCritMultiplier({ [SkillType.Triggered] = true }, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier({ [SkillType.Channel] = true }, true))
	end)

	for text, expected in pairs({
		["If Diamond Flask Charges are consumed, 250% increased Critical Strike Chance"] = { "CritChance", "INC", 250 },
		["50% less Flask Life Recovery rate"] = { "FlaskLifeRecoveryRate", "MORE", -50 },
		["50% less Life Recovery from Flasks"] = { "FlaskLifeRecovery", "MORE", -50 },
		["20% increased Effect of Iron Flasks"] = { "IronFlaskEffect", "INC", 20 },
	}) do
		it("parses " .. text, function()
			local mods, extra = modLib.parseMod(text)
			assert.is_nil(extra)
			assert.are.equal(1, #mods)
			assert.are.same(expected, { mods[1].name, mods[1].type, mods[1].value })
		end)
	end
end)
