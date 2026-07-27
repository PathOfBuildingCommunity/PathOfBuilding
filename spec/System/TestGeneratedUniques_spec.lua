describe("Generated uniques", function()
	local function findGeneratedItem(name)
		for _, itemText in ipairs(data.uniques.generated) do
			if itemText:sub(1, #name + 1) == name .. "\n" then
				return itemText
			end
		end
	end

	it("includes weapon-legal Catarina veiled mods on Cane of Kulemak", function()
		local cane = findGeneratedItem("Cane of Kulemak")
		assert.is_not_nil(cane)
		assert.is_not_nil(cane:find("+2 to Level of Socketed Support Gems", 1, true))
		assert.is_not_nil(cane:find("+(5-8)% to Quality of Socketed Support Gems", 1, true))
		assert.is_not_nil(cane:find("chance to Explode", 1, true))
	end)

	it("excludes weapon-illegal Catarina veiled mods from Cane of Kulemak", function()
		local cane = findGeneratedItem("Cane of Kulemak")
		assert.is_not_nil(cane)
		assert.is_nil(cane:find("maximum number of Spectres", 1, true))
		assert.is_nil(cane:find("Minions are Aggressive", 1, true))
	end)

	it("does not add Catarina signature mods to Paradoxica or Replica Paradoxica", function()
		for _, name in ipairs({ "Paradoxica", "Replica Paradoxica" }) do
			local item = findGeneratedItem(name)
			assert.is_not_nil(item)
			assert.is_nil(item:find("to Quality of Socketed Support Gems", 1, true))
			assert.is_nil(item:find("chance to Explode", 1, true))
		end
	end)
end)
