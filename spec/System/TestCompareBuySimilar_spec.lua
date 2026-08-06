describe("Buy similar mod stat matching", function()
	local bs = LoadModule("Classes/CompareBuySimilar")
	local dkjson = require "dkjson"

	describe("addModEntries mod matching", function()
		it("matches impossible escape mods as options", function()
			local fromNothing = new("Item", [[
Impossible Escape
Viridian Jewel
LevelReq: 0
Radius: Small
Limited to: 1
Implicits: 0
Passive skills in radius of Elemental Overload can be Allocated without being connected to your tree
Corrupted]])

			local modSources = {
				{ list = fromNothing.explicitModLines, type = "explicit" }
			}
			local modEntries = bs.addModEntries(fromNothing, modSources)
			assert.equal(1, #modEntries)
			assert.same(
				{
					formattedLines = { colorCodes.MAGIC .. "Passive skills in radius of Elemental Overload can be Allocated without being connected to your tree" },
					type = "explicit",
					isOption = true,
					invert = false,
					tradeIds = { "explicit.stat_2422708892" },
					value = 22088
				},
				modEntries[1])
		end)

		it("matches thread of hope radius as an option", function()
			local thread = new("Item", [[
Rarity: UNIQUE
Thread of Hope
Crimson Jewel
Radius: Variable
Implicits: 0
Only affects Passives in Massive Ring
-15% to all Elemental Resistances
Passive Skills in Radius can be Allocated without being connected to your tree
Passage]])
			local modSources = {
				{ list = thread.explicitModLines, type = "explicit" }
			}
			local modEntries = bs.addModEntries(thread, modSources)
			assert.equal(4, #modEntries)
			assert.equal("explicit.stat_3642528642", modEntries[1].tradeIds[1])
			assert.equal(5, modEntries[1].value)
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
	describe("popup URL controls", function()
		local originalCopy
		local originalOpenURL
		local originalFetchLeagues
		local copiedUrl
		local leaguesByRealm = {
			pc = { "PC League", "PC Event", "Standard" },
			sony = { "PS4 League", "Standard" },
			xbox = { "Xbox League", "Standard" },
		}

		before_each(function()
			newBuild()
			originalCopy = _G.Copy
			originalOpenURL = _G.OpenURL
			copiedUrl = nil
			local requests = build.itemsTab.tradeQuery.tradeQueryRequests
			originalFetchLeagues = requests.FetchLeagues
			requests.FetchLeagues = function(_, realm, callback)
				callback(leaguesByRealm[realm])
			end
		end)

		after_each(function()
			build.itemsTab.tradeQuery.tradeQueryRequests.FetchLeagues = originalFetchLeagues
			_G.Copy = originalCopy
			_G.OpenURL = originalOpenURL
			bs.lastRealmIdx = nil
			bs.lastLeagueByRealm = nil
			bs.lastListedIndex = nil
			main:ClosePopup()
		end)

		local function openPopup(item, slotName)
			item = item or new("Item", "Rarity: Rare\nTest Ring\nRuby Ring\nImplicits: 0\n+50 to maximum Life")
			bs.openPopup(item, slotName or "Ring", build)
			local controls = main.popups[1].controls
			_G.Copy = function(url) copiedUrl = url end
			_G.OpenURL = function() end
			return controls
		end

		local function getQuery(controls)
			controls.search.onClick()
			local queryJson = urlDecode(assert(copiedUrl:match("[?&]q=(.+)$")))
			return dkjson.decode(queryJson)
		end

		local function getUniqueQuery(name, baseName)
			local item = new("Item", "Rarity: UNIQUE\n" .. name .. "\n" .. baseName .. "\nImplicits: 0")
			local query = getQuery(openPopup(item, "Jewel"))
			main:ClosePopup()
			return query
		end

		it("rebuilds the URL when league and listed status change", function()
			local controls = openPopup()
			getQuery(controls)
			local initialUrl = copiedUrl

			controls.leagueDrop:SetSel(isValueInArray(controls.leagueDrop.list, "Standard"))
			getQuery(controls)
			assert.not_equal(initialUrl, copiedUrl)
			assert.is_truthy(copiedUrl:find("/Standard?", 1, true))
			local standardUrl = copiedUrl

			controls.listedDrop:SetSel(4)
			local query = getQuery(controls)
			assert.not_equal(standardUrl, copiedUrl)
			assert.equal("any", query.query.status.option)
		end)

		it("preserves apostrophes in unique names", function()
			local item = new("Item", [[
Rarity: UNIQUE
Ralakesh's Impatience
Riveted Boots
Implicits: 0]])
			local controls = openPopup(item, "Boots")

			assert.equal("Ralakesh's Impatience", getQuery(controls).query.name)
		end)

		it("removes a trailing unique ID without removing name punctuation", function()
			assert.equal("Uul-Netol's Embrace", getUniqueQuery("Uul-Netol's Embrace 1234", "Vaal Axe").query.name)
		end)

		it("trims whitespace after a unique name", function()
			assert.equal("The Hateful Accuser", getUniqueQuery("The Hateful Accuser ", "Ghastly Eye Jewel").query.name)
		end)

		it("persists league choices by name for each realm", function()
			local controls = openPopup()
			assert.equal("PC Event", controls.leagueDrop:GetSelValue())
			controls.leagueDrop:SetSel(2)
			controls.leagueDrop:SetSel(1)
			controls.realmDrop:SetSel(3)
			assert.equal("Xbox League", controls.leagueDrop:GetSelValue())
			controls.leagueDrop:SetSel(2)
			controls.realmDrop:SetSel(1)
			assert.equal("PC Event", controls.leagueDrop:GetSelValue())
			controls.leagueDrop:SetSel(2)
			controls.realmDrop:SetSel(3)
			assert.equal("Standard", controls.leagueDrop:GetSelValue())
			controls.listedDrop:SetSel(4)
			main:ClosePopup()

			controls = openPopup()
			assert.equal(3, bs.lastRealmIdx)
			assert.equal("Standard", controls.leagueDrop:GetSelValue())
			assert.equal("Any", controls.listedDrop:GetSelValue())
		end)

		it("encodes option values in the generated query", function()
			local item = new("Item", [[
Rarity: UNIQUE
Impossible Escape
Viridian Jewel
LevelReq: 0
Radius: Small
Limited to: 1
Implicits: 0
Passive skills in radius of Elemental Overload can be Allocated without being connected to your tree
Corrupted]])
			local controls = openPopup(item, "Jewel")
			controls.mod1Check.state = true
			controls.mod1Check.changeFunc()

			local filter = getQuery(controls).query.stats[1].filters[1]
			assert.equal("explicit.stat_2422708892", filter.id)
			assert.equal(22088, filter.value.option)
		end)

		it("inverts reduced stat bounds in the generated query", function()
			local item = new("Item", [[
Rarity: Rare
Test Ring
Ruby Ring
Implicits: 0
67% reduced maximum Life]])
			local controls = openPopup(item)
			controls.mod1Check.state = true
			controls.mod1Check.changeFunc()

			local value = getQuery(controls).query.stats[1].filters[1].value
			assert.is_nil(value.min)
			assert.equal(-67, value.max)
		end)

		it("uses a count group for ambiguous trade stats", function()
			local item = new("Item", [[
Rarity: Rare
Test Ring
Ruby Ring
Implicits: 0
Adds 5 to 15 Fire Damage]])
			local modEntries = bs.addModEntries(item, { { list = item.explicitModLines, type = "explicit" } })
			local ambiguousIndex
			for index, entry in ipairs(modEntries) do
				if #entry.tradeIds > 1 then
					ambiguousIndex = index
					break
				end
			end
			assert.is_truthy(ambiguousIndex)

			local controls = openPopup(item)
			local check = controls["mod" .. ambiguousIndex .. "Check"]
			check.state = true
			check.changeFunc()

			local countFilter = getQuery(controls).query.stats[2]
			assert.equal("count", countFilter.type)
			assert.equal(1, countFilter.value.min)
			assert.equal(#modEntries[ambiguousIndex].tradeIds, #countFilter.filters)
		end)
	end)
end)
