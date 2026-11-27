describe("TestUniqueSources", function()
	local function source(name)
		for _, typeList in pairs(data.uniques) do
			for _, itemRaw in pairs(typeList) do
				if itemRaw:match("^%s*" .. name:gsub("%p", "%%%0") .. "\r?\n") then
					return new("Item"):Item(itemRaw).source
				end
			end
		end
	end

	it("has no 3.30-removed Atziri areas as unique sources", function()
		for _, typeList in pairs(data.uniques) do
			for _, itemRaw in pairs(typeList) do
				local name = itemRaw:match("^%s*([^\r\n]+)")
				assert.is_nil(itemRaw:match("The Alluring Abyss"), name)
				assert.is_nil(itemRaw:match("The Apex of Sacrifice"), name)
			end
		end
		assert.are.equals("Drops from unique{Atziri, Queen of the Vaal} in a normal{Temple of Atzoatl}", source("Atziri's Step"))
		assert.are.equals("Drops from unique{Atziri, Queen of the Vaal} in a normal{Temple of Atzoatl} containing the normal{Cradle of Creation}", source("Atziri's Acuity"))
	end)
end)
