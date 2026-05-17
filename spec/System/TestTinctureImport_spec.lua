describe("TestTinctureImport", function()
	local function newImportedTincture(baseName, quality, implicitLines, explicitLines)
		local item = new("Item")
		item.baseName = baseName
		item.base = data.itemBases[baseName]
		item.type = "Tincture"
		item.name = baseName
		item.rarity = "MAGIC"
		item.quality = quality
		item.implicitModLines = { }
		item.explicitModLines = { }
		item.enchantModLines = { }
		item.scourgeModLines = { }
		item.classRequirementModLines = { }
		item.crucibleModLines = { }
		for _, line in ipairs(implicitLines or { }) do
			table.insert(item.implicitModLines, { line = line })
		end
		for _, line in ipairs(explicitLines or { }) do
			table.insert(item.explicitModLines, { line = line })
		end
		return item
	end

	it("normalises Rosethorn import lines back to base values", function()
		local item = newImportedTincture("Rosethorn Tincture", 20, {
			"216% increased Critical Strike Chance with Melee Weapons",
		}, {
			"20% increased effect",
			"36% increased Melee Weapon Attack Speed",
		})

		item:NormaliseImportedTinctureModLines()
		item:BuildAndParseRaw()

		assert.are.equal("150% increased Critical Strike Chance with Melee Weapons", item.implicitModLines[1].line)
		assert.are.equal("20% increased effect", item.explicitModLines[1].line)
		assert.are.equal("25% increased Melee Weapon Attack Speed", item.explicitModLines[2].line)
	end)

	it("preserves non-scaled Mana Burn lines while normalising effect-scaled tincture lines", function()
		local item = newImportedTincture("Prismatic Tincture", 20, {
			"162% increased Elemental Damage with Melee Weapons",
		}, {
			"35% increased effect",
			"37% increased Mana Burn rate",
		})

		item:NormaliseImportedTinctureModLines()
		item:BuildAndParseRaw()

		assert.are.equal("100% increased Elemental Damage with Melee Weapons", item.implicitModLines[1].line)
		assert.are.equal("35% increased effect", item.explicitModLines[1].line)
		assert.are.equal("37% increased Mana Burn rate", item.explicitModLines[2].line)
	end)

	it("can recover the base local effect roll when the imported effect line is already quality-scaled", function()
		local item = newImportedTincture("Prismatic Tincture", 20, {
			"162% increased Elemental Damage with Melee Weapons",
		}, {
			"42% increased effect",
			"37% increased Mana Burn rate",
		})

		item:NormaliseImportedTinctureModLines()
		item:BuildAndParseRaw()

		assert.are.equal("100% increased Elemental Damage with Melee Weapons", item.implicitModLines[1].line)
		assert.are.equal("35% increased effect", item.explicitModLines[1].line)
		assert.are.equal("37% increased Mana Burn rate", item.explicitModLines[2].line)
	end)
end)
