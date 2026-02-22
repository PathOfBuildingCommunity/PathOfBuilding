describe("Foulborn generation", function()
	it("generates correct number of Foulborn items", function()
		local foulbornCount = 0
		for _, raw in ipairs(data.uniques.generated) do
			if raw:match("^Foulborn ") then
				foulbornCount = foulbornCount + 1
			end
		end
		-- PR #9432 has 440 items total; Skin of the Lords is tree-dependent (separate function)
		-- so we expect ~439 non-tree-dependent items
		assert.is_true(foulbornCount >= 430, "Expected 430+ Foulborn items, got " .. foulbornCount)
		print("  Foulborn items generated: " .. foulbornCount)
	end)

	it("generates correct number of Headhunter items (2^3-1=7)", function()
		local count = 0
		for _, raw in ipairs(data.uniques.generated) do
			if raw:match("^Foulborn Headhunter %d+\n") then
				count = count + 1
			end
		end
		assert.are.equals(7, count, "Headhunter should have 7 Foulborn items (3 slots)")
	end)

	it("generates correct number of Alpha's Howl items (2^2-1=3)", function()
		local count = 0
		for _, raw in ipairs(data.uniques.generated) do
			if raw:match("^Foulborn Alpha's Howl %d+\n") then
				count = count + 1
			end
		end
		assert.are.equals(3, count, "Alpha's Howl should have 3 Foulborn items (2 slots)")
	end)

	it("verifies mod replacement in Headhunter 1", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Headhunter 1\n") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Headhunter 1 not found")
		-- Should have Culling Strike (mutated) as the added mod
		assert.truthy(raw:match("Culling Strike %(mutated%)"), "Missing added mod 'Culling Strike (mutated)'")
		-- Should NOT have the removed mod
		assert.is_falsy(raw:match("increased Damage with Hits against Rare monsters"), "Removed mod should not be present")
		-- Should still have other original mods
		assert.truthy(raw:match("When you Kill a Rare monster"), "Missing original mod that should be preserved")
		assert.truthy(raw:match("Leather Belt"), "Missing base type")
	end)

	it("verifies Headhunter 7 has all three mutations", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Headhunter 7\n") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Headhunter 7 not found")
		assert.truthy(raw:match("Culling Strike %(mutated%)"), "Missing Culling Strike")
		assert.truthy(raw:match("Eat a Soul.-%(mutated%)"), "Missing Eat a Soul")
		assert.truthy(raw:match("Minimap Icons.-%(mutated%)"), "Missing Minimap Icons")
		-- All three original mods should be removed
		assert.is_falsy(raw:match("increased Damage with Hits against Rare monsters"), "Removed mod still present")
		assert.is_falsy(raw:match("When you Kill a Rare monster, you gain its Modifiers"), "Removed mod still present")
	end)

	it("generates valid Foulborn Alpha's Howl 1", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Alpha's Howl 1\n") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Alpha's Howl 1 not found")
		assert.truthy(raw:match("Sinner Tricorne"), "Missing base type")
		assert.truthy(raw:match("Requires Level"), "Missing requires line")
		-- Should have added mod and NOT have removed mod
		assert.truthy(raw:match("Life Reservation Efficiency.-%(mutated%)"), "Missing added mutation mod")
		assert.is_falsy(raw:match("16%% increased Mana Reservation Efficiency"), "Removed mod should not be present")
	end)

	it("parses Foulborn item with foulborn flag", function()
		newBuild()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Alpha's Howl 1\n") then raw = r; break end
		end
		local item = new("Item", raw)
		assert.is_true(item.foulborn, "foulborn flag not set")
		assert.are.equals("Sinner Tricorne", item.baseName)
		assert.are.equals("Foulborn Alpha's Howl 1", item.title)
	end)

	it("generates Foulborn item with existing variants correctly", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn The Formless Flame %d+\n") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn The Formless Flame not found")
		-- Should use current variant base (Royal Burgonet, not Siege Helmet)
		assert.truthy(raw:match("Royal Burgonet"), "Wrong base type - should be Royal Burgonet (current variant)")
		assert.is_falsy(raw:match("Siege Helmet"), "Should not contain old variant base")
	end)

	it("generates Foulborn item with implicits", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Call of the Brotherhood %d+\n") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Call of the Brotherhood not found")
		assert.truthy(raw:match("Implicits: 1"), "Missing implicits declaration")
		assert.truthy(raw:match("Cold and Lightning Resistances"), "Missing implicit mod")
	end)

	it("parses Foulborn ring with implicit", function()
		newBuild()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Call of the Brotherhood %d+\n") then raw = r; break end
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

	it("generates Foulborn Skin of the Lords with alt variant", function()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Skin of the Lords") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Skin of the Lords not found")
		assert.truthy(raw:match("Simple Robe"), "Missing base type")
		assert.truthy(raw:match("Has Alt Variant: true"), "Missing alt variant flag")
		assert.truthy(raw:match("Selected Alt Variant:"), "Missing selected alt variant")
		-- Should have keystone variants + Foulborn mutation variants
		local variantCount = 0
		for _ in raw:gmatch("Variant: ") do
			variantCount = variantCount + 1
		end
		assert.is_true(variantCount > 30, "Expected 30+ variants (keystones + mutations), got " .. variantCount)
		-- Should have base mods
		assert.truthy(raw:match("%+2 to Level of Socketed Gems"), "Missing base mod")
		assert.truthy(raw:match("100%% increased Global Defences"), "Missing base mod")
		-- Should have Foulborn mutation mods
		assert.truthy(raw:match("Elemental and Chaos Resistances"), "Missing Foulborn mutation mod")
		print("  Skin of the Lords variants: " .. variantCount)
	end)

	it("parses Foulborn Skin of the Lords with alt variant", function()
		newBuild()
		local raw
		for _, r in ipairs(data.uniques.generated) do
			if r:match("^Foulborn Skin of the Lords") then raw = r; break end
		end
		assert.is_truthy(raw, "Foulborn Skin of the Lords not found")
		local item = new("Item", raw)
		assert.is_true(item.foulborn, "foulborn flag not set")
		assert.are.equals("Simple Robe", item.baseName)
		assert.is_true(item.hasAltVariant, "Alt variant not parsed")
		assert.is_true(#item.variantList > 30, "Not enough variants parsed")
		print("  Parsed variants: " .. #item.variantList .. ", hasAltVariant: " .. tostring(item.hasAltVariant))
	end)

	it("generates items with (mutated) tag on all added mods", function()
		local issues = {}
		for _, raw in ipairs(data.uniques.generated) do
			if raw:match("^Foulborn ") and not raw:match("^Foulborn Skin of the Lords") then
				local hasMutated = raw:match("%(mutated%)")
				if not hasMutated then
					local name = raw:match("^(.-)\n")
					table.insert(issues, name)
				end
			end
		end
		assert.are.equals(0, #issues, "Items without (mutated) tag: " .. table.concat(issues, ", "))
	end)
end)
