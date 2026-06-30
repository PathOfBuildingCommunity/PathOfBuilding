describe("Buy similar mod stat matching", function()
	local bs = LoadModule("Classes/CompareBuySimilar")

	describe("addModEntries mod matching", function()
		it("matches from nothing mods as options", function()
			local fromNothing = new("Item", [[
From Nothing
Diamond
LevelReq: 0
Radius: Small
Limited to: 1
Implicits: 0
Passives in radius of Zealot's Oath can be Allocated without being connected to your tree
Corrupted]])

			local modSources = {
				{ list = fromNothing.explicitModLines, type = "explicit" }
			}
			local modEntries = bs.addModEntries(fromNothing, modSources)
			assert.equal(1, #modEntries)
			assert.same(
				{
					formattedLines = { colorCodes.MAGIC.."Passives in radius of Zealot's Oath can be Allocated without being connected to your tree" },
					type =
					"explicit",
					isOption = true,
					invert = false,
					tradeIds = { "explicit.stat_2422708892|52" },
					value = nil
				},
				modEntries[1])
		end)

		it("combines mods that are the same stat", function()
			local lifeDiamond = new("Item", [[
Test Subject
Diamond
Implicits: 0
+100 to Maximum Life
+50 to Maximum Life
+50% to Fire Resistance]])

			local entries = bs.addModEntries(lifeDiamond, { { list = lifeDiamond.explicitModLines, type = "explicit" } })
			assert.equal(2, #entries)
			assert.equal(2, #entries[1].formattedLines)
			assert.equal("+100 to Maximum Life", StripEscapes(entries[1].formattedLines[1]))
			assert.equal("+50 to Maximum Life", StripEscapes(entries[1].formattedLines[2]))
			assert.equal(150, entries[1].value)

			local lifelessDiamond = new("Item", [[
Test Subject
Diamond
Implicits: 0
-100 to Maximum Life
+50 to Maximum Life
+50% to Fire Resistance]])
			local entries = bs.addModEntries(lifelessDiamond,
				{ { list = lifelessDiamond.explicitModLines, type = "explicit" } })
			assert.equal(2, #entries)
			assert.equal(2, #entries[1].formattedLines)
			assert.equal(-50, entries[1].value)
		end)

		it("is not case-sensitive", function ()
			local funnyItem = new("Item", [[
Test Subject
Diamond
Implicits: 1
+50 tO MaxIMum lifE]])

			local entries = bs.addModEntries(funnyItem, {{list = funnyItem.implicitModLines, type = "implicit"}})
			assert.equal(1, #entries)
		end)

		it("does not combine implicit and explicit mods", function()
			local lifelessDiamond = new("Item", [[
Test Subject
Diamond
Implicits: 1
-100 to Maximum Life
+50 to Maximum Life]])
			local entries = bs.addModEntries(lifelessDiamond,
				{ { list = lifelessDiamond.implicitModLines, type = "implicit" }, { list = lifelessDiamond.explicitModLines, type = "explicit" } })
			assert.equal(2, #entries)
			assert.equal(-100, entries[1].value)
			assert.equal(50, entries[2].value)
		end)
	end)
end)
