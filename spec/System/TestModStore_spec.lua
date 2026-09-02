describe("ModStore PerStat.subtract", function()
	local function perStatValue(statValue, div, subtract)
		local modDB = new("ModDB"):ModDB()
		modDB.actor = { output = { Str = statValue } }
		modDB:NewMod("Damage", "INC", 1, "Test", { type = "PerStat", stat = "Str", div = div, subtract = subtract })
		return modDB:Sum("INC", nil, "Damage")
	end

	it("divides before subtracting", function()
		-- floor(12 / 5) - 2 = 0. Subtract-then-divide would be floor(10 / 5) = 2.
		assert.are.equal(0, perStatValue(12, 5, 2))
		assert.are.equal(3, perStatValue(20, 5, 1))
	end)

	it("clamps a negative PerStat multiplier to zero", function()
		assert.are.equal(0, perStatValue(3, 5, 1))
		assert.are.equal(0, perStatValue(1, 1, 5))
	end)
end)
