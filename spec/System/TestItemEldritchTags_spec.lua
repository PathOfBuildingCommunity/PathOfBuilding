describe("TestItemEldritchTags", function()
	before_each(function()
		newBuild()
	end)

	local function findLine(item, text)
		for _, modLine in ipairs(item.implicitModLines) do
			if modLine.line == text then
				return modLine
			end
		end
	end

	-- Copied from the game (Ctrl+C): implicits carry "(implicit)", not {exarch}/{eater}
	local copiedGloves = [[Item Class: Gloves
Rarity: Rare
Test Grip
Sorcerer Gloves
--------
Energy Shield: 50
--------
Item Level: 84
--------
11% increased Attack Speed (implicit)
Projectiles Pierce an additional Target (implicit)
--------
+30 to maximum Life
--------
Searing Exarch Item
Eater of Worlds Item]]

	it("tags eldritch implicits of a copied item (issue #4940)", function()
		local item = new("Item"):Item(copiedGloves)
		assert.is_true(item.cleansing)
		assert.is_true(item.tangle)
		local exarchLine = findLine(item, "11% increased Attack Speed")
		local eaterLine = findLine(item, "Projectiles Pierce an additional Target")
		assert.is_truthy(exarchLine)
		assert.is_truthy(eaterLine)
		assert.is_true(exarchLine.exarch)
		assert.is_falsy(exarchLine.eater)
		assert.is_true(eaterLine.eater)
		assert.is_falsy(eaterLine.exarch)
	end)

	it("keeps the tags after saving and reloading the item (issue #4940)", function()
		local item = new("Item"):Item(new("Item"):Item(copiedGloves):BuildRaw())
		assert.is_true(findLine(item, "11% increased Attack Speed").exarch)
		assert.is_true(findLine(item, "Projectiles Pierce an additional Target").eater)
	end)

	it("does not tag implicits of an item without eldritch influence", function()
		local item = new("Item"):Item((copiedGloves:gsub("\nSearing Exarch Item\nEater of Worlds Item", "")))
		assert.is_falsy(findLine(item, "11% increased Attack Speed").exarch)
		assert.is_falsy(findLine(item, "Projectiles Pierce an additional Target").eater)
	end)

	it("keeps existing tags", function()
		local item = new("Item"):Item([[Rarity: RARE
Test Grip
Sorcerer Gloves
Searing Exarch Item
Eater of Worlds Item
Implicits: 2
{exarch}11% increased Attack Speed
{eater}Projectiles Pierce an additional Target]])
		assert.is_true(findLine(item, "11% increased Attack Speed").exarch)
		assert.is_falsy(findLine(item, "11% increased Attack Speed").eater)
		assert.is_true(findLine(item, "Projectiles Pierce an additional Target").eater)
	end)

	it("does not tag implicits without the matching influence", function()
		local item = new("Item"):Item((copiedGloves:gsub("\nEater of Worlds Item", "")))
		assert.is_true(findLine(item, "11% increased Attack Speed").exarch)
		assert.is_falsy(findLine(item, "Projectiles Pierce an additional Target").eater)
	end)
end)
