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

describe("ModStore source-owned enemy overlay", function()
	local function damageIfChilledByYou(sourceOwned)
		local shared = new("ModDB"):ModDB()
		local overlay = new("ModDB"):ModDB()
		overlay.conditions.ChilledByYou = true
		local actor = {
			enemySourceDB = overlay,
			enemy = { modDB = shared },
		}
		shared.actor = actor
		overlay.actor = actor
		local playerDB = new("ModDB"):ModDB()
		playerDB.actor = actor
		playerDB:NewMod("Damage", "INC", 10, "Test", { type = "ActorCondition", actor = "enemy", var = "ChilledByYou", sourceOwned = sourceOwned })
		return playerDB:Sum("INC", nil, "Damage")
	end

	it("reads the actor overlay only when tag.sourceOwned is true", function()
		assert.are.equal(10, damageIfChilledByYou(true))
		assert.are.equal(0, damageIfChilledByYou(nil))
		assert.are.equal(0, damageIfChilledByYou(false))
	end)
end)
