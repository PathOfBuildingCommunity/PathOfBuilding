describe("Foulborn generation", function()
	it("generates Foulborn items from foulbornMap", function()
		local foulbornCount = 0
		for _, raw in ipairs(data.uniques.generated) do
			if raw:match("^Foulborn ") then
				foulbornCount = foulbornCount + 1
			end
		end
		assert.is_true(foulbornCount > 200, "Expected 200+ Foulborn items, got " .. foulbornCount)
		print("  Foulborn items generated: " .. foulbornCount)
	end)

	it("generates valid Foulborn Alpha's Howl", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Alpha") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Alpha's Howl not found")
		assert.truthy(raw:match("Sinner Tricorne"), "Missing base type")
		assert.truthy(raw:match("Variant:"), "Missing variant declarations")
		assert.truthy(raw:match("{variant:1}"), "Missing variant-tagged mod")
		assert.truthy(raw:match("Requires Level"), "Missing requires line")
	end)

	it("parses Foulborn item with foulborn flag", function()
		newBuild()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Alpha") then raw = r; break end
		end
		local item = new("Item", raw)
		assert.is_true(item.foulborn, "foulborn flag not set")
		assert.are.equals("Sinner Tricorne", item.baseName)
		assert.are.equals("Foulborn Alpha's Howl", item.title)
		assert.is_true(#item.variantList > 0, "No variants parsed")
		print("  Variants: " .. #item.variantList)
	end)

	it("generates Foulborn item with existing variants correctly", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn The Formless Flame") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn The Formless Flame not found")
		-- Should use Current variant base (Royal Burgonet, not Siege Helmet)
		assert.truthy(raw:match("Royal Burgonet"), "Wrong base type - should be Royal Burgonet (Current variant)")
		assert.is_falsy(raw:match("Siege Helmet"), "Should not contain old variant base")
	end)

	it("generates Foulborn item with implicits", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Call of the Brotherhood") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Call of the Brotherhood not found")
		assert.truthy(raw:match("Implicits: 1"), "Missing implicits declaration")
		assert.truthy(raw:match("Cold and Lightning Resistances"), "Missing implicit mod")
	end)

	it("parses Foulborn ring with implicit", function()
		newBuild()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Call of the Brotherhood") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Call of the Brotherhood not found")
		local item = new("Item", raw)
		assert.is_true(item.foulborn)
		assert.are.equals("Two-Stone Ring", item.baseName)
		print("  Ring base: " .. tostring(item.baseName))
	end)

	it("no Foulborn item has empty base type", function()
		for _, raw in ipairs(data.uniques.generated) do
			if raw:match("^Foulborn ") then
				local name = raw:match("^(.-)\n")
				local base = raw:match("^.-\n(.-)\n")
				assert.is_truthy(base and base ~= "", name .. " has empty base type")
			end
		end
	end)
end)
