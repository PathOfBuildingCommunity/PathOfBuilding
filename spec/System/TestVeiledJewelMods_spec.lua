describe("Veiled jewel and vestigial quiver mods", function()
	local function parse(line)
		-- Parse the line itself instead of reading the stored ModCache result
		modLib.parseModCache[line] = nil
		local mods, extra = modLib.parseMod(line)
		assert.is_nil(extra)
		assert.is_not_nil(mods)
		return mods
	end

	local function findTag(mod, tagType)
		for _, tag in ipairs(mod) do
			if tag.type == tagType then
				return tag
			end
		end
	end

	it("parses poison chance on critical strikes with bows", function()
		local mods = parse("Critical Strikes with Bows have a 20% chance to Poison the Enemy")
		assert.are.equal(1, #mods)
		assert.are.equal("PoisonChance", mods[1].name)
		assert.are.equal("BASE", mods[1].type)
		assert.are.equal(20, mods[1].value)
		assert.are.equal(ModFlag.Bow, mods[1].flags)
		assert.are.equal("CriticalStrike", findTag(mods[1], "Condition").var)
	end)

	it("parses rage on hit with axes or swords", function()
		local mods = parse("Attacks with Axes or Swords grant 1 Rage on Hit")
		assert.are.equal(1, #mods)
		assert.are.equal("Condition:CanGainRage", mods[1].name)
		assert.are.equal("FLAG", mods[1].type)
		assert.is_true(mods[1].value)
		assert.are.same({ "UsingAxe", "UsingSword" }, findTag(mods[1], "Condition").varList)
	end)

	it("parses unarmed attack speed with melee skills", function()
		for _, value in ipairs({ 7, 10, 12 }) do
			local mods = parse(value .. "% increased Unarmed Attack Speed with Melee Skills")
			assert.are.equal(1, #mods)
			assert.are.equal("Speed", mods[1].name)
			assert.are.equal("INC", mods[1].type)
			assert.are.equal(value, mods[1].value)
			assert.are.equal(bit.bor(ModFlag.Unarmed, ModFlag.Attack, ModFlag.Melee), mods[1].flags)
		end
	end)

	it("parses stun duration against intimidated enemies", function()
		local mods = parse("Enemies Intimidated by you have 13% increased duration of stuns against them")
		assert.are.equal(1, #mods)
		assert.are.equal("EnemyStunDuration", mods[1].name)
		assert.are.equal("INC", mods[1].type)
		assert.are.equal(13, mods[1].value)
		local tag = findTag(mods[1], "ActorCondition")
		assert.are.equal("enemy", tag.actor)
		assert.are.equal("Intimidated", tag.var)
	end)

	it("parses increased damage for linked targets", function()
		local mods = parse("Your Linked targets deal 16% increased Damage")
		assert.are.equal(1, #mods)
		assert.are.equal("ExtraLinkEffect", mods[1].name)
		assert.are.equal("LIST", mods[1].type)
		local linkMod = mods[1].value.mod
		assert.are.equal("Damage", linkMod.name)
		assert.are.equal("INC", linkMod.type)
		assert.are.equal(16, linkMod.value)
		assert.is_true(findTag(linkMod, "GlobalEffect").unscalable)
	end)

	it("parses both wordings of ignored mana burn", function()
		for _, line in ipairs({
			"The first 2 Mana Burn applied to you has no effect",
			"The first 2 Mana Burn applied to you have no effect",
		}) do
			local mods = parse(line)
			assert.are.equal(1, #mods)
			assert.are.equal("EffectiveManaBurnStacks", mods[1].name)
			assert.are.equal("BASE", mods[1].type)
			assert.are.equal(-2, mods[1].value)
			assert.are.equal("player", findTag(mods[1], "ActorCondition").actor)
		end
	end)

	it("parses arrows fork", function()
		local mods = parse("Arrows Fork")
		assert.are.equal(2, #mods)
		assert.are.equal("ForkOnce", mods[1].name)
		assert.are.equal("FLAG", mods[1].type)
		assert.is_true(mods[1].value)
		assert.are.equal(KeywordFlag.Arrow, mods[1].keywordFlags)
		assert.are.equal("ForkCountMax", mods[2].name)
		assert.are.equal("BASE", mods[2].type)
		assert.are.equal(1, mods[2].value)
		assert.are.equal(KeywordFlag.Arrow, mods[2].keywordFlags)
	end)
end)
