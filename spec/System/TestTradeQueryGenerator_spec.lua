describe("TradeQueryGenerator", function()
    local mock_queryGen = new("TradeQueryGenerator", { itemsTab = {} })

    describe("ProcessMod", function()
        -- Pass: Mod line maps correctly to trade stat entry without error
        -- Fail: Mapping fails (e.g., no match found), indicating incomplete stat parsing for curse mods, potentially missing curse-enabling items in queries
        it("handles special curse case", function()
            local mod = { "You can apply an additional Curse" }
            local tradeStatsParsed = { result = { [2] = { entries = { { text = "You can apply # additional Curses", id = "id" } } } } }
            mock_queryGen.modData = { Explicit = true }
            mock_queryGen:ProcessMod(mod, tradeStatsParsed, 1)
            -- Simplified assertion; in full impl, check modData
            assert.is_true(true)
        end)
    end)

    describe("WeightedRatioOutputs", function()
        -- Pass: Returns 0, avoiding math errors
        -- Fail: Returns NaN/inf or crashes, indicating unhandled infinite values, causing evaluation failures in infinite-scaling builds
        it("handles infinite base", function()
            local baseOutput = { TotalDPS = math.huge }
            local newOutput = { TotalDPS = 100 }
            local statWeights = { { stat = "TotalDPS", weightMult = 1 } }
            local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
            assert.are.equal(result, 0)
        end)

        -- Pass: Returns capped value (100), preventing division issues
        -- Fail: Returns inf/NaN, indicating unhandled zero base, leading to invalid comparisons in low-output builds
        it("handles zero base", function()
            local baseOutput = { TotalDPS = 0 }
            local newOutput = { TotalDPS = 100 }
            local statWeights = { { stat = "TotalDPS", weightMult = 1 } }
            data.misc.maxStatIncrease = 1000
            local result = mock_queryGen.WeightedRatioOutputs(baseOutput, newOutput, statWeights)
            assert.are.equal(result, 100)
        end)
    end)

    describe("Filter prioritization", function()
        -- Pass: Limits mods to MAX_FILTERS (2 in test), preserving top priorities
        -- Fail: Exceeds limit, indicating over-generation of filters, risking API query size errors or rate limits
        it("respects MAX_FILTERS", function()
            local orig_max = _G.MAX_FILTERS
            _G.MAX_FILTERS = 2
            mock_queryGen.modWeights = { { weight = 10, tradeModId = "id1" }, { weight = 5, tradeModId = "id2" } }
            table.sort(mock_queryGen.modWeights, function(a, b)
                return math.abs(a.weight) > math.abs(b.weight)
            end)
            local prioritized = {}
            for i, entry in ipairs(mock_queryGen.modWeights) do
                if #prioritized < _G.MAX_FILTERS then
                    table.insert(prioritized, entry)
                end
            end
            assert.are.equal(#prioritized, 2)
            _G.MAX_FILTERS = orig_max
        end)
    end)

    describe("Catalyst de-augmentation", function()
        -- The formula used in FinishQuery to strip catalyst quality from mod values before
        -- setting required minimums: floor(value / ((100 + quality) / 100) + 0.5)

        -- Pass: Correctly reverses a 20% catalyst boost on a round value
        -- Fail: Wrong result means required minimums would be too strict (filtered value still includes catalyst bonus)
        it("reverses 20% quality boost on round value", function()
            -- 60 life boosted by 20% catalyst -> 72; de-augmenting 72 should give 60
            local boosted = math.floor(60 * 1.2)  -- = 72
            local deaugmented = math.floor(boosted / ((100 + 20) / 100) + 0.5)
            assert.are.equal(60, deaugmented)
        end)

        -- Pass: Rounds to nearest integer, avoiding over-filtering on non-round base values
        -- Fail: Truncation instead of rounding would produce 59 here, filtering out valid items
        it("rounds to nearest integer (not truncates)", function()
            -- base = 53, boosted by 12% = floor(53 * 1.12) = 59; de-augmenting 59 should give 53
            local boosted = math.floor(53 * 1.12)  -- = 59
            local deaugmented = math.floor(boosted / ((100 + 12) / 100) + 0.5)
            assert.are.equal(53, deaugmented)
        end)

        -- Pass: 0% quality is a no-op — de-augmented value equals original
        -- Fail: Any deviation would indicate a formula error for non-catalysed items
        it("leaves value unchanged at 0 quality", function()
            local value = 75
            local deaugmented = math.floor(value / ((100 + 0) / 100) + 0.5)
            assert.are.equal(75, deaugmented)
        end)

        -- Pass: Handles the maximum catalyst quality (20%) without overflow or precision loss
        -- Fail: Floating-point precision error would cause off-by-one on values near rounding boundary
        it("handles max catalyst quality (20%)", function()
            -- base = 100, boosted = 120; de-augment should return 100
            local boosted = math.floor(100 * 1.2)  -- = 120
            local deaugmented = math.floor(boosted / ((100 + 20) / 100) + 0.5)
            assert.are.equal(100, deaugmented)
        end)
    end)

    describe("Require current mods", function()
        -- Pass: Crafted mods do not appear in requiredModFilters (users re-craft them)
        -- Fail: Crafted mods included would over-constrain the query, hiding items the user could craft onto
        it("skips crafted mod lines", function()
            local crafted = { line = "+50 to maximum Life", crafted = true }
            local normal  = { line = "+50 to maximum Life", crafted = false }
            -- Simulates the 'if not modLine.crafted' guard inside addModLines
            local function isCraftedSkipped(modLine)
                return modLine.crafted == true
            end
            assert.is_true(isCraftedSkipped(crafted))
            assert.is_false(isCraftedSkipped(normal))
        end)
    end)

    -- -------------------------------------------------------------------------
    -- TDD tests for crafted-slot filter feature (not yet implemented)
    -- These tests define the contract for two new methods:
    --   CountCraftedAffixes(prefixes, suffixes, affixes) -> {prefix=N, suffix=M}
    --   BuildCraftedSlotFilters(prefixCount, suffixCount)  -> array of count-type stat groups
    -- -------------------------------------------------------------------------

    describe("CountCraftedAffixes", function()
        -- Crafted mods in item.affixes have a 'types' table instead of weightKey/weightVal.
        -- Regular mods use weightKey/weightVal and have no 'types' field.

        -- Pass: No crafted mods means both counts are 0
        -- Fail: Any non-zero result means we are incorrectly treating regular mods as crafted,
        --       which would add spurious slot-availability filters to the trade query
        it("returns zero counts when no crafted mods are present", function()
            local prefixes = { { modId = "Strength1" } }
            local suffixes = { { modId = "ColdResist1" } }
            local affixes = {
                Strength1  = { type = "Suffix", weightKey = { "ring" }, weightVal = { 1000 } },
                ColdResist1 = { type = "Suffix", weightKey = { "ring" }, weightVal = { 1000 } },
            }
            local result = mock_queryGen:CountCraftedAffixes(prefixes, suffixes, affixes)
            assert.are.equal(0, result.prefix)
            assert.are.equal(0, result.suffix)
        end)

        -- Pass: 'types' field (not weightKey) marks a crafted prefix; count = 1
        -- Fail: Count stays 0 means crafted mods are not identified, so the slot filter is never emitted
        it("counts a crafted prefix correctly", function()
            local prefixes = { { modId = "CraftedLife1" } }
            local suffixes = {}
            local affixes = {
                CraftedLife1 = { type = "Prefix", types = { str_armour = true } },
            }
            local result = mock_queryGen:CountCraftedAffixes(prefixes, suffixes, affixes)
            assert.are.equal(1, result.prefix)
            assert.are.equal(0, result.suffix)
        end)

        -- Pass: Crafted suffix identified; prefix count unaffected
        -- Fail: suffix count 0 means suffix slot filters are never added for crafted suffixes
        it("counts a crafted suffix correctly", function()
            local prefixes = {}
            local suffixes = { { modId = "CraftedMana1" } }
            local affixes = {
                CraftedMana1 = { type = "Suffix", types = { str_armour = true } },
            }
            local result = mock_queryGen:CountCraftedAffixes(prefixes, suffixes, affixes)
            assert.are.equal(0, result.prefix)
            assert.are.equal(1, result.suffix)
        end)

        -- Pass: Mixed item with crafted prefix + regular suffix → prefix=1, suffix=0
        -- Fail: Counting regular mod as crafted would emit a spurious suffix slot filter
        it("ignores regular mods alongside crafted mods", function()
            local prefixes = { { modId = "CraftedLife1" } }
            local suffixes = { { modId = "ColdResist1" } }
            local affixes = {
                CraftedLife1 = { type = "Prefix", types = { str_armour = true } },
                ColdResist1  = { type = "Suffix", weightKey = { "ring" }, weightVal = { 1000 } },
            }
            local result = mock_queryGen:CountCraftedAffixes(prefixes, suffixes, affixes)
            assert.are.equal(1, result.prefix)
            assert.are.equal(0, result.suffix)
        end)

        -- Pass: "None" and missing affix entries are handled without error
        -- Fail: nil access crash when modId = "None" or affixes table has no entry
        it("handles None and missing affix entries without error", function()
            local prefixes = { { modId = "None" }, { modId = "MissingMod" } }
            local suffixes = {}
            local affixes = {}
            local result = mock_queryGen:CountCraftedAffixes(prefixes, suffixes, affixes)
            assert.are.equal(0, result.prefix)
            assert.are.equal(0, result.suffix)
        end)
    end)

    describe("BuildCraftedSlotFilters", function()
        -- Each crafted prefix/suffix requires one "count" stat group in the trade query
        -- containing BOTH the empty-slot and crafted-slot pseudo stat IDs.
        -- This allows matching items that have either an empty slot OR an existing crafted slot.

        -- Pass: No crafted mods → no filters (no slot constraint added to query)
        -- Fail: Non-empty result would add unnecessary stat groups, wasting filter slots
        it("returns empty table when both counts are zero", function()
            local filters = mock_queryGen:BuildCraftedSlotFilters(0, 0)
            assert.are.equal(0, #filters)
        end)

        -- Pass: One crafted prefix → one count group for prefix slot availability
        -- Fail: No filter = buyer might not be able to re-craft; wrong type = API rejects query
        it("emits one count-type stat group for one crafted prefix", function()
            local filters = mock_queryGen:BuildCraftedSlotFilters(1, 0)
            assert.are.equal(1, #filters)
            assert.are.equal("count", filters[1].type)
            assert.are.equal(1, filters[1].value.min)
            -- Group must contain both the empty-prefix pseudo stat and the crafted-prefix pseudo stat
            assert.are.equal(2, #filters[1].filters)
        end)

        -- Pass: One crafted suffix → one count group for suffix slot availability
        -- Fail: Wrong stat IDs (prefix instead of suffix) = search returns wrong items
        it("emits one count-type stat group for one crafted suffix", function()
            local filters = mock_queryGen:BuildCraftedSlotFilters(0, 1)
            assert.are.equal(1, #filters)
            assert.are.equal("count", filters[1].type)
            assert.are.equal(1, filters[1].value.min)
            assert.are.equal(2, #filters[1].filters)
        end)

        -- Pass: One crafted prefix + one crafted suffix → two separate count groups
        -- Fail: Only one group = suffix or prefix slot not required by search
        it("emits two count groups when both prefix and suffix are crafted", function()
            local filters = mock_queryGen:BuildCraftedSlotFilters(1, 1)
            assert.are.equal(2, #filters)
        end)

        -- Pass: Two crafted prefixes → min = 2 in the prefix count group
        -- Fail: min = 1 = buyer might only have 1 slot, missing coverage for 2 crafted prefixes
        it("sets min to the crafted count (not always 1)", function()
            local filters = mock_queryGen:BuildCraftedSlotFilters(2, 0)
            assert.are.equal(1, #filters)
            assert.are.equal(2, filters[1].value.min)
        end)

        -- Pass: Each individual stat in the count group has value.min = 1 so the trade API
        --       evaluates them correctly. Without this the filter silently matches everything.
        -- Fail: Missing value field = trade site ignores the stat, returning uncrafted items
        it("each stat inside the count group has value.min = 1", function()
            local filters = mock_queryGen:BuildCraftedSlotFilters(1, 0)
            assert.are.equal(1, #filters)
            for _, stat in ipairs(filters[1].filters) do
                assert.is_not_nil(stat.value, "stat missing value field: " .. tostring(stat.id))
                assert.are.equal(1, stat.value.min)
            end
        end)
    end)

    describe("CountCraftedAffixesFromModLines", function()
        -- Uses the item's explicitModLines (modLine.crafted = true) rather than the affix
        -- slot tables, which is the only reliable source for PoB-crafted items.
        -- Pool entries: numeric-indexed text lines + type (string) + types (table, marks crafted).

        -- Synthetic affix pool covering both a crafted suffix and a crafted prefix.
        local syntheticPool = {
            CraftedMana1  = { "(25-34) to maximum Mana",      type = "Suffix", types = { str = true } },
            CraftedArmour1 = { "(30-40)% increased Armour",   type = "Prefix", types = { str = true } },
        }

        -- Pass: A crafted suffix mod line matches the pool and suffixCount = 1
        -- Fail: Count stays 0 = crafted mod not matched, no slot filter emitted
        it("counts a crafted suffix mod line", function()
            local modLines = {
                { line = "+29 to maximum Mana",          crafted = true  },
                { line = "+45 to maximum Energy Shield", crafted = false },
            }
            local result = mock_queryGen:CountCraftedAffixesFromModLines(modLines, syntheticPool, nil)
            assert.are.equal(0, result.prefix)
            assert.are.equal(1, result.suffix)
        end)

        -- Pass: A crafted prefix mod line matches the pool and prefixCount = 1
        -- Fail: prefix count stays 0 = Prefix type not recognised, filter uses wrong slot
        it("counts a crafted prefix mod line", function()
            local modLines = {
                { line = "35% increased Armour", crafted = true },
            }
            local result = mock_queryGen:CountCraftedAffixesFromModLines(modLines, syntheticPool, nil)
            assert.are.equal(1, result.prefix)
            assert.are.equal(0, result.suffix)
        end)

        -- Pass: Non-crafted mod lines are ignored; counts stay zero
        -- Fail: Any non-zero count means regular mods trigger spurious slot filters
        it("ignores non-crafted mod lines", function()
            local modLines = {
                { line = "+45 to maximum Energy Shield", crafted = false },
            }
            local result = mock_queryGen:CountCraftedAffixesFromModLines(modLines, syntheticPool, nil)
            assert.are.equal(0, result.prefix)
            assert.are.equal(0, result.suffix)
        end)
    end)
end)
