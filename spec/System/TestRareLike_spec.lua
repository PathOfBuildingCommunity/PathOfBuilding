describe("Veiled unique affix pools", function()
	local function makeUnique(name)
		for _, typeList in pairs(data.uniques) do
			for _, raw in pairs(typeList) do
				if raw:match("^%s*([^\r\n]+)") == name or raw:find("\n" .. name .. "\n", 1, true) then
					return new("Item"):Item(raw, "UNIQUE")
				end
			end
		end
	end

	-- the mods the crafting UI would offer on this item, selected the same way
	-- ItemsTab:UpdateAffixControl does
	local function offeredMods(item)
		local mods = { }
		for modId, mod in pairs(item.affixes) do
			if item:CanHaveMod(mod) then
				mods[modId] = mod
			end
		end
		return mods
	end

	local function offeredLines(item)
		local lines = { }
		for _, mod in pairs(offeredMods(item)) do
			for _, line in ipairs(mod) do
				table.insert(lines, line)
			end
		end
		return table.concat(lines, "\n")
	end

	it("includes weapon-legal Catarina veiled mods on Cane of Kulemak", function()
		local cane = makeUnique("Cane of Kulemak")
		assert.is_not_nil(cane)
		assert.are.equal(68, cane.requirements.level)
		local lines = offeredLines(cane)
		assert.is_not_nil(lines:find("+2 to Level of Socketed Support Gems", 1, true))
		assert.is_not_nil(lines:find("+(5-8)% to Quality of Socketed Support Gems", 1, true))
		assert.is_not_nil(lines:find("chance to Explode", 1, true))
	end)

	it("excludes weapon-illegal Catarina veiled mods from Cane of Kulemak", function()
		local cane = makeUnique("Cane of Kulemak")
		assert.is_not_nil(cane)
		local lines = offeredLines(cane)
		assert.is_nil(lines:find("maximum number of Spectres", 1, true))
		assert.is_nil(lines:find("Minions are Aggressive", 1, true))
	end)

	it("only offers the base veiled pool on Paradoxica", function()
		local item = makeUnique("Paradoxica")
		assert.is_not_nil(item)
		for modId, mod in pairs(offeredMods(item)) do
			assert.is_true(mod.affix == "Chosen" or mod.affix == "of the Order",
				modId .. " is a master signature mod")
		end
	end)

	it("offers weapon-legal signature veiled mods on Replica Paradoxica", function()
		local item = makeUnique("Replica Paradoxica")
		assert.is_not_nil(item)
		local lines = offeredLines(item)
		assert.is_not_nil(lines:find("+(5-8)% to Quality of Socketed Support Gems", 1, true))
		assert.is_not_nil(lines:find("chance to Explode", 1, true))
		assert.is_nil(lines:find("maximum number of Spectres", 1, true))
		assert.is_nil(lines:find("Minions are Aggressive", 1, true))
	end)

	it("offers Chosen, Catarina's, and of the Order mods on The Queen's Hunger", function()
		local item = makeUnique("The Queen's Hunger")
		assert.is_not_nil(item)
		local mods = offeredMods(item)
		assert.is_not_nil(mods.JunMasterVeiledSpellBlockPercent____)
		assert.is_not_nil(mods.JunMasterVeiledOfferingEffect)
		assert.is_not_nil(mods.JunMasterVeiledStrengthAndDexterity)
	end)

	it("only offers attainable modifiers on That Which Was Taken", function()
		local item = makeUnique("That Which Was Taken")
		assert.is_not_nil(item)
		assert.are.equal(1, item.limit)
		assert.are.equal(48, item.requirements.level)
		assert.is_nil(item.affixes.AnimalCharmMaximumRage1)
		assert.is_not_nil(item.affixes.AnimalCharmMaximumRage2)
	end)
end)
