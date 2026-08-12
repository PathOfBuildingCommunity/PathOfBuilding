describe("TestItemsTab", function ()
	describe("CopyAnointsAndEldritchImplicits", function ()
		before_each(function()
			newBuild()
		end)

		local function equip(item)
			build.itemsTab:AddItem(item)
			build.itemsTab:EquipItemInSet(item, build.itemsTab.activeItemSetId)
		end
		it("does not copy an anoint onto a talisman", function()
			local amulet = new("Item"):Item("Rarity: Rare\nAnointed\nOnyx Amulet\n+8 to Strength (enchant)")
			assert.are.equals(1, #amulet.enchantModLines)
			equip(amulet)

			local talisman = new("Item"):Item("Rarity: Rare\nCharm\nBlack Maw Talisman")
			local originalCount = #talisman.enchantModLines

			build.itemsTab:CopyAnointsAndEldritchImplicits(talisman, false, false)

			assert.are.equals(originalCount, #talisman.enchantModLines)
			for _, modLine in ipairs(talisman.enchantModLines) do
				assert.are_not.equals("+8 to Strength", modLine.line)
			end
		end)

		it("does not copy an anoint from a talisman", function()
			local talisman = new("Item"):Item("Rarity: Rare\nCharm\nBlack Maw Talisman\n+8 to Strength (enchant)")
			assert.are.equals(1, #talisman.enchantModLines)
			equip(talisman)

			-- new amulet must not inherit the talisman's enchant as an anoint
			local amulet = new("Item"):Item("Rarity: Rare\nPlain\nOnyx Amulet")
			assert.are.equals(0, #amulet.enchantModLines)

			build.itemsTab:CopyAnointsAndEldritchImplicits(amulet, false, false)

			assert.are.equals(0, #amulet.enchantModLines)
		end)
	end)
end)
