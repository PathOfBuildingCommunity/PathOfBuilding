describe("Reflecting Mist exported modifier pool", function()
	local mist = require("Modules.ReflectingMist")
	local catalog = dofile("../spec/ReflectingMistModifiers.lua")
	local sources = {}
	for _, entry in ipairs(catalog.entries) do sources[entry.source] = true end
	-- These descriptions are not fully understood by the existing modifier parser.
	-- Keep the exceptions explicit: any additional parsing regression must fail.
	local parserGaps = {
		["#% chance to Defend with #% of Armour"] = true,
		["#% of Chaos Damage Leeched by Enemy as Life"] = true,
		["#% of Cold Damage Leeched by Enemy as Life"] = true,
		["#% of Fire Damage Leeched by Enemy as Life"] = true,
		["#% of Lightning Damage Leeched by Enemy as Life"] = true,
		["#% of Physical Damage Leeched by Enemy as Life"] = true,
		["#% of Physical Attack Damage Leeched by Enemy as Life"] = true,
		["#% of Physical Attack Damage Leeched by Enemy as Mana"] = true,
		["Lose # Life for each Ignited Enemy hit with Attacks"] = true,
		["Shock nearby Enemies for # Seconds when you Focus"] = true,
		["Shock yourself for # Seconds when you Focus"] = true,
		["#% of Damage Leeched by Enemy as Life while Focused"] = true,
	}

	it("includes every jewellery modifier source offered by the crafting menus", function()
		for _, source in ipairs({ "Affix", "Bench", "Essence", "Veiled", "Incursion", "Delve", "Beastcraft" }) do
			assert.is_true(sources[source])
		end
		-- Necropolis is also enumerated, but its current exported mods only target armour.
		assert.is_true(#catalog.entries > 1000)
	end)

	for _, entry in ipairs(catalog.entries) do
		if entry.source == "Bench" or entry.source == "Essence" then
			it("restores missing affix types for " .. entry.source .. ":" .. entry.id .. " on experimented " .. entry.itemType, function()
				local bases = entry.itemType == "Ring"
					and { "Cogwork Ring", "Geodesic Ring", "Composite Ring", "Manifold Ring", "Ratcheting Ring", "Helical Ring" }
					or { "Simplex Amulet", "Focused Amulet" }
				for _, baseName in ipairs(bases) do
					local base = data.itemBases[baseName]
					local _, newlines = base.implicit:gsub("\n", "")
					for _, range in ipairs({ 0, 0.5, 1 }) do
						local tagged = new("Item"):Item("Rarity: Rare\nMist Bench Test\n" .. baseName .. "\nImplicits: " .. (newlines + 1) .. "\n" .. base.implicit)
						tagged.explicitModLines = copyTable(catalog.makeItem(entry, range).explicitModLines)
						for _, modLine in ipairs(tagged.explicitModLines) do modLine.custom = entry.source ~= "Bench" end
						tagged:BuildAndParseRaw()
						local untagged = new("Item"):Item(tagged:BuildRaw():gsub("{prefix}", ""):gsub("{suffix}", ""))
						local original = untagged:BuildRaw()
						for _, multiplier in ipairs({ 1.6, 2, 2.1 }) do
							for _, negative in ipairs({ false, true }) do
								local signs = {}
								for i in ipairs(tagged.explicitModLines) do signs[i] = negative end
								local expected = mist.ReflectItem(tagged, multiplier, signs)
								local actual = mist.ReflectItem(untagged, multiplier, signs)
								assert.same(expected.modList, actual.modList)
								assert.same(actual.modList, new("Item"):Item(actual:BuildRaw()).modList)
							end
						end
						assert.are.equals(original, untagged:BuildRaw())
					end
				end
			end)
		end
		it("preserves " .. entry.source .. ":" .. entry.id .. " on " .. entry.itemType .. " through reflection and reload", function()
			for _, range in ipairs({ 0, 0.5, 1 }) do
				local source = catalog.makeItem(entry, range)
				local original = source:BuildRaw()
				if entry.influenced then
					-- These modifiers require influence, which makes the item ineligible.
					for _, influence in ipairs(itemLib.influenceInfo.all) do source[influence.key] = true end
					assert.is_false(mist.CanReflect(source))
				else
					assert.is_true(mist.CanReflect(source))
					for _, multiplier in ipairs({ 1.3, 1.6, 1.525, 2.1 }) do
						for _, negative in ipairs({ false, true }) do
							local negatives = {}
							for i in ipairs(source.explicitModLines) do negatives[i] = negative end
							local reflected = mist.ReflectItem(source, multiplier, negatives)
							local loaded = new("Item"):Item(reflected:BuildRaw())
							assert.is_true(loaded.mirrored)
							assert.are.equals(multiplier, loaded.reflectionMultiplier)
							assert.are.equals(#source.explicitModLines, #reflected.explicitModLines)
							assert.are.equals(reflected:BuildRaw(), loaded:BuildRaw())
							assert.same(reflected.modList, loaded.modList)
							for i, modLine in ipairs(reflected.explicitModLines) do
								-- Unsupported descriptions must remain visible after reload, too.
								assert.are.equals(modLine.extra, loaded.explicitModLines[i].extra)
								if not source.explicitModLines[i].extra and modLine.extra then
									local template = modLine.line:gsub("[%+%-]?%d+%.?%d*", "#")
									assert.is_true(parserGaps[template] or false, modLine.line)
								end
							end
						end
					end
					assert.are.equals(original, source:BuildRaw())
				end
			end
		end)
	end

	it("uses the game's negative descriptions for resource gain and penetration", function()
		local cases = {
			{ "Gain 10 Life per Enemy Hit with Attacks", "Lose 16 Life per Enemy Hit with Attacks" },
			{ "Gain 10 Mana per Enemy Killed", "Lose 16 Mana per Enemy Killed" },
			{ "Damage Penetrates 10% Fire Resistance", "Your Hits treat Fire Resistance as 16% higher than actual value" },
			{ "Damage Penetrates 10% Elemental Resistances", "Damage Penetrates 16% Elemental Resistances" },
			{ "Lose 10 Mana per second", "Regenerate 16 Mana per second" },
			{ "Adds 6 to 14 Chaos Damage to Attacks", "Adds 9 to 22 Chaos Damage to Attacks against you" },
		}
		for _, case in ipairs(cases) do
			assert.are.equals(case[2], mist.ReflectModLine({ line = case[1] }, 1.6, true))
		end
	end)

	it("preserves every ring and amulet base implicit", function()
		for name, base in pairs(data.itemBases) do
			if (base.type == "Ring" or base.type == "Amulet") and base.implicit then
				local _, newlines = base.implicit:gsub("\n", "")
				local source = new("Item"):Item("Rarity: Rare\nMist Implicit Test\n" .. name
					.. "\nImplicits: " .. (newlines + 1) .. "\n" .. base.implicit
					.. "\n{range:1}+(10-10) to maximum Life")
				if mist.CanReflect(source) then
					for _, multiplier in ipairs({ 1.3, 1.6, 1.525, 2.1 }) do
						local reflected = mist.ReflectItem(source, multiplier, { true })
						assert.are.equals(#source.implicitModLines, #reflected.implicitModLines)
						for i, implicit in ipairs(source.implicitModLines) do
							assert.are.equals(implicit.line, reflected.implicitModLines[i].line)
							assert.same(implicit.modList, reflected.implicitModLines[i].modList)
						end
					end
				end
			end
		end
	end)

	it("rejects jewellery with corrupted or synthesised implicit modifiers", function()
		for _, pool in ipairs({
			{ mods = data.itemMods.Corrupted, marker = "Corrupted" },
			{ mods = data.itemMods.Synthesis, marker = "Synthesised Item" },
		}) do
			for _, baseName in ipairs({ "Coral Ring", "Onyx Amulet" }) do
				local source = new("Item"):Item("Rarity: Rare\nMist Implicit Test\n" .. baseName)
				for _, mod in pairs(pool.mods) do
					if source:GetModSpawnWeight(mod) > 0 then
						local raw = "Rarity: Rare\nMist Implicit Test\n" .. baseName
							.. "\nImplicits: " .. #mod .. "\n" .. table.concat(mod, "\n") .. "\n" .. pool.marker
						assert.is_false(mist.CanReflect(new("Item"):Item(raw)))
					end
				end
			end
		end
	end)
end)
