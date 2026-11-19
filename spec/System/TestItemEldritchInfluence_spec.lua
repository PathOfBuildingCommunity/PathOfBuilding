describe("TestItemEldritchInfluence", function()
	before_each(function()
		newBuild()
	end)

	local function createEldritchHelmet()
		build.itemsTab:CreateDisplayItemFromRaw([[Rarity: RARE
Test Crown
Hubris Circlet
Searing Exarch Item
Eater of Worlds Item
Implicits: 3
{exarch}+10% to Fire Resistance
{eater}+10% to Cold Resistance
+20 to maximum Life
+30 to maximum Mana]])
		return build.itemsTab.displayItem
	end

	local function hasLine(modLines, text)
		for _, modLine in ipairs(modLines) do
			if modLine.line == text then
				return true
			end
		end
		return false
	end

	it("removes Searing Exarch implicits when the Searing Exarch influence is removed (issue #4941)", function()
		local item = createEldritchHelmet()
		assert.is_true(item.cleansing)
		assert.is_true(item.tangle)
		assert.are.equal("Searing Exarch", build.itemsTab.controls.displayItemInfluence:GetSelValue())

		build.itemsTab.controls.displayItemInfluence:SetSel(1)

		item = build.itemsTab.displayItem
		assert.is_falsy(item.cleansing)
		assert.is_true(item.tangle)
		assert.is_false(hasLine(item.implicitModLines, "+10% to Fire Resistance"))
		assert.is_true(hasLine(item.implicitModLines, "+10% to Cold Resistance"))
		assert.is_true(hasLine(item.implicitModLines, "+20 to maximum Life"))
	end)

	it("removes Eater of Worlds implicits when the Eater of Worlds influence is removed (issue #4941)", function()
		createEldritchHelmet()
		assert.are.equal("Eater of Worlds", build.itemsTab.controls.displayItemInfluence2:GetSelValue())

		build.itemsTab.controls.displayItemInfluence2:SetSel(1)

		local item = build.itemsTab.displayItem
		assert.is_true(item.cleansing)
		assert.is_falsy(item.tangle)
		assert.is_true(hasLine(item.implicitModLines, "+10% to Fire Resistance"))
		assert.is_false(hasLine(item.implicitModLines, "+10% to Cold Resistance"))
		assert.is_true(hasLine(item.implicitModLines, "+20 to maximum Life"))
	end)

	it("keeps both eldritch implicits when the item is loaded", function()
		local item = createEldritchHelmet()
		assert.is_true(hasLine(item.implicitModLines, "+10% to Fire Resistance"))
		assert.is_true(hasLine(item.implicitModLines, "+10% to Cold Resistance"))
	end)

	it("switching Eater of Worlds to Shaper drops only the Eater of Worlds implicit", function()
		createEldritchHelmet()

		build.itemsTab.controls.displayItemInfluence2:SetSel(2) -- Shaper instead of Eater

		local item = build.itemsTab.displayItem
		assert.is_true(item.cleansing)
		assert.is_true(item.shaper)
		assert.is_true(hasLine(item.implicitModLines, "+10% to Fire Resistance"))
		assert.is_false(hasLine(item.implicitModLines, "+10% to Cold Resistance"))
	end)
end)
