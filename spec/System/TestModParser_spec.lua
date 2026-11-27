describe("TestModParser", function()
	it("parses 3.30 explicit distance wording like the old nearby wording", function()
		local cases = {
			{ "Allies within 5 metres cannot have their Action Speed modified to below Base Value", "Nearby Allies' Action Speed cannot be modified to below Base Value" },
			{ "Damage with Hits of Allies within 5 metres is Lucky", "Nearby Allies' Damage with Hits is Lucky" },
			{ "Chaos Resistance of Enemies within 6 metres is 0", "Nearby Enemies' Chaos Resistance is 0" },
			{ "Enemy Monsters within 3 metres have at least 8% of Life Reserved", "Nearby Enemy Monsters have at least 8% of Life Reserved" },
			{ "Your party members within 6 metres maximum Endurance Charges is equal to yours", "Your nearby party members maximum Endurance Charges is equal to yours" },
			{ "Allies Regenerate 400 Life per second for the Poison's duration if within 3 metres", "and nearby Allies Regenerate 400 Life per second" },
			{ "Regenerate 200 Energy Shield per second while a Rare or Unique Enemy is within 6 metres", "Regenerate 200 Energy Shield per second while a Rare or Unique Enemy is Nearby" },
			{ "+38% Critical Strike Multiplier while a Rare or Unique Enemy is within 6 metres", "+38% Critical Strike Multiplier while a Rare or Unique Enemy is Nearby" },
			{ "14% increased Attack Speed while a Rare or Unique Enemy is within 6 metres", "14% increased Attack Speed while a Rare or Unique Enemy is Nearby" },
		}
		for _, pair in ipairs(cases) do
			local mods, extra = modLib.parseMod(pair[1])
			local nearbyMods, nearbyExtra = modLib.parseMod(pair[2])
			assert.is_nil(nearbyExtra, pair[2])
			assert.is_nil(extra, pair[1])
			assert.are.same(nearbyMods, mods, pair[1])
		end
	end)

	local function getMasterDistillerCritMultiplier(value, skillTypes, hasDiamondFlask)
		local mods, extra = modLib.parseMod("If Diamond Flask Charges are consumed, +" .. value .. "% to Critical Strike Multiplier")
		assert.is_nil(extra)
		local modDB = new("ModDB"):ModDB()
		modDB:AddList(mods)
		modDB.conditions.HaveDiamondFlask = hasDiamondFlask
		return modDB:Sum("BASE", { skillTypes = skillTypes }, "CritMultiplier")
	end

	it("applies the Master Distiller diamond flask bonus only to eligible skills while the flask is present", function()
		assert.are.equal(100, getMasterDistillerCritMultiplier(100, {}, true))
		assert.are.equal(60, getMasterDistillerCritMultiplier(60, {}, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier(100, {}, false))
		assert.are.equal(0, getMasterDistillerCritMultiplier(100, { [SkillType.Triggered] = true }, true))
		assert.are.equal(0, getMasterDistillerCritMultiplier(100, { [SkillType.Channel] = true }, true))
	end)
end)
