-- Path of Building
--
-- Module: MCP Tools - Trade
-- The Items tab's trader: the weighted search it generates for a slot ("Find
-- best"), and the search it runs on the trade site with every result measured
-- on the build ("Price Item").
--
local T = ...

local t_insert = table.insert
local t_concat = table.concat
local s_format = string.format

local dkjson = require("dkjson")
local tradeHelpers = require("Classes.TradeHelpers")

-- The trader's listing types, in the order of its dropdown (TradeQuery:PriceItem)
-- and of the ids TradeQueryGenerator:FinishQuery sends.
local TRADE_TYPES = { "instant_buyout", "instant_or_in_person", "in_person_online_in_league", "in_person_online", "any" }

-- Currencies of the generator's "Max Price" dropdown (TradeQueryGenerator currencyTable).
local CURRENCIES = { "chaos", "divine", "alch", "alt", "chrome", "exalted", "blessed", "chisel", "gcp", "jewellers", "scour", "regret", "fusing", "chance", "regal", "vaal" }

-- The trader's "Other trades" rows (TradeQuery:PriceItem).
local UNIQUE_ROWS = { "Megalomaniac", "Watcher's Eye", "Pearl of Tsoatha" }

-- Slots whose eldritch implicits the Query Options dialog offers to handle (TradeQueryGenerator eldritchModSlots).
local ELDRITCH_SLOTS = { ["Body Armour"] = true, Helmet = true, Gloves = true, Boots = true, Amulet = true }

-- The trader's "Sort By" choices (TradeQuery sortModes).
local SORT_MODES = { stat_value = "StatValue", stat_value_per_price = "StatValuePrice", price = "Price", weighted_sum = "Weight" }

-- Trade site stat id -> text, from the stat list PoB ships (Data/TradeSiteStats).
local tradeStatText
local function tradeStatLookup()
	if not tradeStatText then
		tradeStatText = { }
		for _, category in ipairs(tradeHelpers.getTradeStats()) do
			for _, entry in ipairs(category.entries or { }) do
				tradeStatText[entry.id] = entry.text
			end
		end
	end
	return tradeStatText
end

-- The weights the trader's "Adjust search weights" dialog offers (TradeQuery:SetStatWeights).
local function statWeights(list)
	local weights = { }
	for _, want in ipairs(list) do
		local found
		for _, stat in ipairs(data.powerStatList) do
			if not stat.ignoreForItems and stat.label ~= "Name" and stat.stat
				and (stat.stat:lower() == want.stat:lower() or stat.label:lower() == want.stat:lower()) then
				found = stat
			end
		end
		if not found then
			local names = { }
			for _, stat in ipairs(data.powerStatList) do
				if not stat.ignoreForItems and stat.stat then
					t_insert(names, stat.stat)
				end
			end
			T.Fail("Unknown weight stat '%s'. Stats: %s", want.stat, t_concat(names, ", "))
		end
		t_insert(weights, { label = found.label, stat = found.stat, transform = found.transform, weightMult = want.weight })
	end
	return weights
end

-- The weights to use: given ones, else the build's saved trader weights, else the trader's defaults.
local function chosenWeights(args, tradeQuery)
	if args.weights then
		return statWeights(args.weights)
	elseif tradeQuery.statSortSelectionList and tradeQuery.statSortSelectionList[1] then
		return tradeQuery.statSortSelectionList
	end
	return statWeights({ { stat = "FullDPS", weight = 1 }, { stat = "TotalEHP", weight = 0.5 } })
end

local function tradeStatFilters(list, what)
	if not list then
		return nil
	end
	local stats = tradeStatLookup()
	local filters = { }
	for _, entry in ipairs(list) do
		if not stats[entry.id] then
			T.Fail("'%s' in %s is not a trade site stat id PoB knows (for example 'explicit.stat_3299347043' or 'pseudo.pseudo_total_life').", entry.id, what)
		end
		t_insert(filters, { tradeId = entry.id, value = entry.min })
	end
	return filters
end

local function statFilterList(description)
	return {
		type = "array", maxItems = 5, description = description,
		items = { type = "object", properties = { id = { type = "string" }, min = { type = "number" } }, required = { "id" }, additionalProperties = false },
	}
end

local function slotLabel(slot)
	return slot.label or slot.slotName
end

-- Active jewel sockets that are not cluster jewel sockets, as the trader lists
-- them for its unique jewel rows, and the one it preselects (the lowest node id).
local function uniqueJewelSockets(build)
	local itemsTab = build.itemsTab
	local list = { }
	for nodeId, socket in pairs(itemsTab.sockets) do
		if not socket.inactive and not build.spec.nodes[nodeId].containJewelSocket then
			t_insert(list, socket)
		end
	end
	table.sort(list, function(a, b) return a.nodeId < b.nodeId end)
	return list
end

-- The trader row for the slot asked for (TradeQuery:PriceItem's slotTables), and
-- the slot the Query Options dialog passes to the generator (RequestQuery).
local function tradeRow(build, args)
	local itemsTab = build.itemsTab
	itemsTab:UpdateSockets()
	local unique
	for _, name in ipairs(UNIQUE_ROWS) do
		if name:lower() == tostring(args.slot):lower() then
			unique = name
		end
	end
	if not unique then
		if args.jewel_socket or args.ring_slot then
			T.Fail("jewel_socket and ring_slot are for the unique rows: %s.", t_concat(UNIQUE_ROWS, ", "))
		end
		local slot = T.FindSlot(build, args.slot)
		if slot.inactive then
			T.Fail("%s is not in use (an unallocated jewel socket or a missing abyssal socket).", slotLabel(slot))
		end
		return { slotName = slot.slotName, nodeId = slot.nodeId }, slot
	end
	local row = { slotName = unique, unique = true, alreadyCorrupted = unique == "Megalomaniac" or nil }
	if unique == "Pearl of Tsoatha" then
		if args.jewel_socket then
			T.Fail("jewel_socket is for Megalomaniac and Watcher's Eye.")
		end
		local rings = { }
		for index = 1, 3 do
			local ring = itemsTab.slots["Ring " .. index]
			if ring and ring.shown() then
				t_insert(rings, ring)
			end
		end
		local ring = args.ring_slot and T.Find(rings, args.ring_slot, function(candidate) return candidate.slotName end, "ring slot") or rings[1]
		row.selectedSlotName = ring.slotName
		return row, ring
	end
	if args.ring_slot then
		T.Fail("ring_slot is for Pearl of Tsoatha.")
	end
	local sockets = uniqueJewelSockets(build)
	if not sockets[1] then
		T.Fail("%s needs an allocated jewel socket that is not a cluster jewel socket, as in the trader.", unique)
	end
	local socket = sockets[1]
	if args.jewel_socket then
		socket = T.Find(sockets, args.jewel_socket, function(candidate)
			return candidate.label
		end, "jewel socket")
	end
	row.selectedJewelNodeId = socket.nodeId
	return row, socket
end

local function checkLeague(league)
	if league ~= nil and (type(league) ~= "string" or not league:match("^[%w '%-%(%)]+$")) then
		T.Fail("league must be a league name, for example 'Standard'.")
	end
	return league
end

-- The search PoB's trader generates for a row: the Query Options dialog's
-- choices with its defaults (TradeQueryGenerator:RequestQuery), then the
-- generator's own work, run to the end here.
local function generateQuery(build, args)
	local itemsTab = build.itemsTab
	local tradeQuery = itemsTab.tradeQuery
	local row, slot = tradeRow(build, args)
	local league = checkLeague(args.league or tradeQuery.pbLeague)
	local weights = chosenWeights(args, tradeQuery)
	local isJewel = slot.slotName:find("Jewel") ~= nil
	local isAbyssal = slot.slotName:find("Abyssal") ~= nil
	local options = {
		statWeights = weights,
		includeCorrupted = not row.alreadyCorrupted and args.include_corrupted ~= false,
		maxPrice = args.max_price,
		maxPriceType = args.max_price and args.max_price_currency or nil,
		maxLevel = args.max_level,
		sockets = args.sockets,
		links = args.links,
		requiredMods = tradeStatFilters(args.required_stats, "required_stats"),
		blockedMods = tradeStatFilters(args.blocked_stats, "blocked_stats"),
	}
	if row.unique then
		options.special = { itemName = row.slotName }
	else
		-- These unique items cannot be mirrored, so the dialog offers it only for other rows.
		options.includeMirrored = args.include_mirrored ~= false
	end
	if not isJewel and not isAbyssal and (league == "Standard" or league == "Hardcore") then
		options.includeScourge = args.include_scourge ~= false
	end
	if slot.slotName == "Amulet" then
		options.includeTalisman = args.include_talisman == true
	end
	if ELDRITCH_SLOTS[slot.slotName] then
		options.includeEldritch = args.eldritch or "Copy Current"
	end
	if isAbyssal then
		options.jewelType = "Abyss"
	elseif isJewel and not row.unique then
		options.jewelType = args.jewel_type or "Base"
	end
	if row.slotName == "Watcher's Eye" then
		options.includeAllWEMods = args.include_all_watchers_eye_mods == true
	end
	local copyEnchantMode
	if slot.slotName == "Amulet" or slot.slotName == "Belt" or slot.slotName == "Weapon 1" or slot.slotName == "Weapon 2" then
		copyEnchantMode = args.enchant_mode or "Keep"
	end
	local tradeTypeIndex = args.trade_type and isValueInArray(TRADE_TYPES, args.trade_type) or tradeQuery.tradeTypeIndex or 1

	-- A generator of our own, so the trader's remembered choices stay as they are.
	local generator = new("TradeQueryGenerator"):TradeQueryGenerator(tradeQuery)
	local query, message
	generator.requesterContext = { }
	generator.requesterCallback = function(_, generated, errMsg)
		query, message = generated, errMsg
	end
	generator.tradeTypeIndex = tradeTypeIndex
	generator:StartQuery(slot, options)
	local co = generator.calcContext.co
	if not co then
		T.Fail("Path of Building's trader has no weighted search for %s.", slotLabel(slot))
	end
	-- The work TradeQueryGenerator:OnFrame spreads over frames, run to the end here.
	while coroutine.status(co) ~= "dead" do
		local ok, err = coroutine.resume(co, generator)
		if not ok then
			T.Fail("Path of Building could not weight the modifiers: %s", tostring(err))
		end
	end
	generator.calcContext.co = nil
	generator:FinishQuery()
	if message then
		T.Fail("%s", message)
	end
	if not query then
		T.Fail("Path of Building generated no trade query.")
	end
	return {
		row = row,
		slot = slot,
		league = league,
		weights = weights,
		query = query,
		includeEldritch = options.includeEldritch,
		copyEnchantMode = copyEnchantMode,
		generator = generator,
	}
end

local function usedWeights(weights)
	local list = { }
	for _, weight in ipairs(weights) do
		t_insert(list, { stat = weight.stat, label = weight.label, weight = T.Round(weight.weightMult) })
	end
	return list
end

-- Options shared by both tools: those of the trader's Query Options dialog.
local QUERY_INPUT = {
	slot = { type = "string", description = "Slot, for example 'Helmet', 'Ring 1', 'Weapon 1', 'Flask 2' or a jewel socket like 'Socket #1', or one of the trader's 'Other trades' rows: 'Megalomaniac', 'Watcher\'s Eye', 'Pearl of Tsoatha'." },
	league = { type = "string", maxLength = 100, description = "Trade league (default: the league chosen in PoB's trader, if any), for example 'Standard'." },
	realm = { type = "string", enum = { "pc", "xbox", "sony" }, description = "Trade realm (default: the trader's, else pc)." },
	trade_type = { type = "string", enum = TRADE_TYPES, description = "Listings to search (default: the trader's choice, else instant_buyout)." },
	weights = {
		type = "array", maxItems = 20, description = "Stats to weight, as the trader's 'Adjust search weights', for example [{stat:'FullDPS', weight:1}, {stat:'Life', weight:0.5}] (default: the build's saved trader weights, else Full DPS 1 and Effective Hit Pool 0.5).",
		items = { type = "object", properties = { stat = { type = "string" }, weight = { type = "number", minimum = 0.01, maximum = 1 } }, required = { "stat", "weight" }, additionalProperties = false },
	},
	include_corrupted = { type = "boolean", description = "Weight corruption implicits (default true; Megalomaniac always false)." },
	include_mirrored = { type = "boolean", description = "Allow mirrored items (default true; not offered for the unique rows)." },
	include_scourge = { type = "boolean", description = "Weight scourge modifiers (default true in Standard and Hardcore, otherwise not offered)." },
	include_talisman = { type = "boolean", description = "Amulet: weight talisman modifiers (default false)." },
	eldritch = { type = "string", enum = { "Copy Current", "Keep regular", "Keep regular+presence", "Remove" }, description = "Helmet, body armour, gloves, boots, amulet: eldritch implicits ('Keep ...' weights them; default Copy Current)." },
	jewel_type = { type = "string", enum = { "Base", "Abyss" }, description = "Jewel sockets: which jewels to search (default Base)." },
	jewel_socket = { type = "string", description = "Megalomaniac and Watcher's Eye: the jewel socket to measure in, by label (default: the trader's choice, the first allocated non-cluster socket)." },
	ring_slot = { type = "string", enum = { "Ring 1", "Ring 2", "Ring 3" }, description = "Pearl of Tsoatha: the ring slot to measure in (default the first shown)." },
	include_all_watchers_eye_mods = { type = "boolean", description = "Watcher's Eye: also include, at weight 0, mods for the build's auras that could not be weighted (default false)." },
	max_price = { type = "integer", minimum = 1, description = "Maximum price." },
	max_price_currency = { type = "string", enum = CURRENCIES, description = "Currency of max_price (default: chaos orb equivalent)." },
	max_level = { type = "integer", minimum = 1, maximum = 100, description = "Maximum level requirement." },
	sockets = { type = "integer", minimum = 1, maximum = 6, description = "Number of empty sockets." },
	links = { type = "integer", minimum = 1, maximum = 6, description = "Number of links." },
	required_stats = statFilterList("Stats the item must have, by trade site stat id (as in weightedStats), with an optional minimum."),
	blocked_stats = statFilterList("Stats the item must not have, by trade site stat id."),
}

------------------------------------------------------------------------------
-- trade_query
------------------------------------------------------------------------------

T.Tool {
	name = "trade_query",
	title = "Weighted trade search",
	description = "Generates the weighted trade search Path of Building's trader ('Trade for these items', 'Find best') builds for "
		.. "an equipment slot, a jewel socket or one of its unique rows (Megalomaniac, Watcher's Eye, Pearl of Tsoatha) of the open "
		.. "build: PoB measures every modifier that can appear on that item type with the build's calculator, weights each by how "
		.. "much it improves the chosen stats, and sets the minimum weighted sum to half the current item's value. Returns the query "
		.. "JSON for the pathofexile.com trade API, the weighted stats in readable form, and a trade site URL when a league is known "
		.. "and compression is available. Nothing is sent to the trade site; it uses only data PoB ships, and takes a few seconds. "
		.. "Options mirror the trader's Query Options dialog. To run the search and get listings with prices, use trade_search.",
	readOnly = true,
	idempotent = true,
	usesDialog = true,
	input = QUERY_INPUT,
	required = { "slot" },
	run = function(args)
		local build = T.Build()
		local tradeQuery = build.itemsTab.tradeQuery
		local generated = generateQuery(build, args)
		local query = generated.query
		local stats = tradeStatLookup()
		local weighted = { }
		for _, filter in ipairs(query.stats[1].filters) do
			t_insert(weighted, { id = filter.id, text = stats[filter.id], weight = T.Round(filter.value.weight) })
		end
		local result = {
			slot = generated.row.unique and generated.row.slotName or generated.slot.slotName,
			measuredIn = generated.row.unique and slotLabel(generated.slot) or nil,
			category = generated.generator.calcContext.itemCategoryQueryStr,
			weights = usedWeights(generated.weights),
			minimumWeightedSum = T.Round(query.stats[1].value.min),
			weightedStats = T.Array(weighted),
			query = query,
		}
		local league = generated.league
		-- As the trader composes the link when it is not logged in.
		local encoded = league and tradeHelpers.B64GzipEncode(dkjson.encode(query))
		if league and encoded and encoded ~= "" then
			local realm = args.realm or (tradeQuery.pbRealm ~= "" and tradeQuery.pbRealm) or "pc"
			result.url = tradeQuery.tradeQueryRequests:buildUrl(tradeQuery.hostName .. "trade/search", realm, league) .. "/" .. encoded
			result.league = league
		elseif not league then
			result.note = "Pass league to get a trade site link."
		else
			result.note = "Path of Building could not compress the query into a trade site link here; use the query with the trade site's search API."
		end
		return result
	end,
}

------------------------------------------------------------------------------
-- trade_search
------------------------------------------------------------------------------

-- Realm and league of a trade site search link (TradeQueryRequests:SearchWithURL).
local function linkRealmAndLeague(tradeQuery, url)
	local subpath = url:match(tradeQuery.hostNamePattern .. "trade/search/(.+)$")
	local paths = { }
	for path in (subpath or ""):gmatch("[^/]+") do
		t_insert(paths, path)
	end
	if #paths < 2 or #paths > 3 then
		T.Fail("url must be a pathofexile.com trade search link, as the trader's 'Price Item' takes.")
	end
	return #paths == 3 and paths[1] or "pc", urlDecode(paths[#paths - 1])
end

local function changeLines(build, before, after)
	local collector = T.LineCollector()
	build:AddStatComparesToTooltip(collector, before, after, "Changes:")
	local lines = { }
	for _, line in ipairs(collector.lines) do
		if line ~= "Changes:" then
			t_insert(lines, line)
		end
	end
	return T.Array(lines)
end

local searchCount = 0

local tradeSearchInput = copyTable(QUERY_INPUT, true)
tradeSearchInput.url = { type = "string", maxLength = 4000, description = "A pathofexile.com trade search link to run instead of generating one (the trader's 'Price Item' with a pasted link); results are measured in slot." }
tradeSearchInput.pages = { type = "integer", minimum = 1, maximum = 10, description = "Result pages to fetch, 10 listings each (the trader's 'Fetch Pages', default 2)." }
tradeSearchInput.sort_by = { type = "string", enum = { "stat_value", "stat_value_per_price", "price", "weighted_sum" }, description = "The trader's 'Sort By': stat_value (default, the weighted improvement PoB measures), stat_value_per_price, price (lowest first) or weighted_sum (the trade site's order)." }
tradeSearchInput.enchant_mode = { type = "string", enum = { "Keep", "Copy Current", "Remove" }, description = "Weapons, amulet, belt: what to do with the listings' enchants or anoints before measuring them (the dialog's Enchant/Anoint Behaviour, default Keep)." }
local limitArgs = T.PageArgs(10, 100)
tradeSearchInput.limit = limitArgs.limit
tradeSearchInput.offset = limitArgs.offset

T.Tool {
	name = "trade_search",
	title = "Search the trade site",
	description = "Runs the search of Path of Building's trader on the pathofexile.com trade site and measures every listing on the open "
		.. "build, as 'Find best' followed by the trader's search does: the weighted search trade_query describes (same options), or a "
		.. "trade search link given in url. It needs Path of Building to be logged in to Path of Exile (Import/Export tab, 'Authorize "
		.. "with Path of Exile'), uses PoB's request queue and rate limits, and only reads listings: nothing is bought, posted or sent "
		.. "to sellers. Returns the listings sorted as the trader's 'Sort By' (default: highest stat value), each with its price (and "
		.. "in divines when PoB has the currency rates), what equipping it would change on the side bar, the item text to use with "
		.. "simulate or items_equip, and the seller's whisper or a link to the listing. Listings are compared with the build's active "
		.. "item set (change it with items_sets). A search takes a few seconds, longer when the trade site rate limits it.",
	readOnly = true,
	openWorld = true,
	usesDialog = true,
	input = tradeSearchInput,
	required = { "slot" },
	run = function(args)
		local build = T.Build()
		local itemsTab = build.itemsTab
		local tradeQuery = itemsTab.tradeQuery
		if not main.api or not main.api.authToken then
			T.Fail("Path of Building is not logged in to Path of Exile, which the trader needs to search. Ask the user to log in from the "
				.. "Import/Export tab ('Authorize with Path of Exile'); meanwhile trade_query gives a trade site link they can open.")
		end
		local row, slot, weights, generated, realm, league
		if args.url then
			if not args.url:match("^https://") and not args.url:match("^www%.") and not args.url:match("^pathofexile") then
				T.Fail("url must be a pathofexile.com trade search link.")
			end
			realm, league = linkRealmAndLeague(tradeQuery, args.url)
			row, slot = tradeRow(build, args)
			weights = chosenWeights(args, tradeQuery)
		else
			generated = generateQuery(build, args)
			row, slot, weights = generated.row, generated.slot, generated.weights
			league = generated.league
			if not league then
				T.Fail("Pass league, for example 'Standard' or the current league.")
			end
			realm = args.realm or (tradeQuery.pbRealm ~= "" and tradeQuery.pbRealm) or "pc"
		end
		local sortMode = tradeQuery.sortModes[SORT_MODES[args.sort_by or "stat_value"]]
		-- The trader fetches currency rates when it opens; the price sorts and divine prices need them.
		tradeQuery:PullCXData(realm)

		-- A queue of our own, so the trader's open searches are not disturbed; the rate limits are shared.
		local requests = new("TradeQueryRequests"):TradeQueryRequests(tradeQuery.tradeQueryRequests.rateLimiter)
		requests.maxFetchPerSearch = 10 * (args.pages or 2)
		local treeTab = build.treeTab
		local timeout = 120
		return T.Defer(function(resolve)
			searchCount = searchCount + 1
			local frameKey = "McpTradeSearch" .. searchCount
			local deadline = os.clock() + timeout
			local searchUrl, sentQuery, longWait
			local function stop()
				main.onFrameFuncs[frameKey] = nil
				requests.requestQueue.search, requests.requestQueue.fetch = { }, { }
			end
			-- PoB waits out rate limits itself; give up on long waits rather than keep the client waiting.
			local function onRateLimit(wait)
				if wait > 30 then
					longWait = wait
				end
			end
			main.onFrameFuncs[frameKey] = function()
				if os.clock() > deadline then
					return stop()
				end
				local ok, err = pcall(requests.ProcessQueue, requests, onRateLimit)
				if not ok then
					stop()
					T.Settle(resolve, T.Fail, "Path of Building's trade requests failed: " .. tostring(err))
				elseif longWait then
					stop()
					T.Settle(resolve, T.Fail, s_format("pathofexile.com is rate limiting trade searches; try again in %d seconds.", longWait))
				end
			end
			local function onResults(items, errMsg, query)
				stop()
				T.Settle(resolve, function()
					if errMsg then
						if errMsg == "No Matching Results Found" then
							T.Fail("The trade site found no listings for this search%s.", args.max_price and " (try a higher max_price)" or "")
						end
						T.Fail("The trade site search failed: %s", tostring(errMsg))
					end
					if T.Build().treeTab ~= treeTab then
						T.Fail("The open build changed while the search ran; nothing was measured.")
					end
					sentQuery = query
					local filterSlot = row.unique and (row.selectedJewelNodeId and itemsTab.sockets[row.selectedJewelNodeId]) or (not row.unique and slot) or nil
					local results
					if generated then
						results = tradeQuery:PrepareGeneratedResults(items or { }, filterSlot and filterSlot.slotName, row.slotName,
							generated.includeEldritch, generated.copyEnchantMode)
					else
						results = tradeQuery:FilterToSafeItems(items or { }, filterSlot and filterSlot.slotName)
					end
					if not results[1] then
						T.Fail("None of the listings found fit %s.", row.unique and row.slotName or slotLabel(slot))
					end
					build:ProcessBuildFlag()
					local calcFunc, baseOutput = build.calcsTab:GetMiscCalculator()
					local notes = { }
					local measured, evaluations, statValues = { }, { }, { }
					for _, result in ipairs(results) do
						local ok, evaluation = pcall(tradeQuery.EvaluateItem, tradeQuery, row, result.item_string, calcFunc, baseOutput, weights)
						if ok then
							t_insert(measured, result)
							t_insert(evaluations, evaluation)
							local sum = 0
							for _, entry in ipairs(evaluation) do
								sum = sum + entry.weight
							end
							t_insert(statValues, sum)
						end
					end
					if #measured < #results then
						t_insert(notes, s_format("%d listing%s could not be measured and %s left out.", #results - #measured,
							#results - #measured == 1 and "" or "s", #results - #measured == 1 and "is" or "are"))
					end
					results = measured
					if not results[1] then
						T.Fail("Path of Building could not measure any of the listings found.")
					end
					local sortedBy = args.sort_by or "stat_value"
					local sorted, sortErr = tradeQuery:SortResults(results, sortMode, function(index) return statValues[index] end, realm, league)
					if sortErr == "MissingConversionRates" then
						t_insert(notes, "Currency rates were not available, so the listings are sorted by stat value, as the trader falls back to.")
						sortedBy = "stat_value"
						sorted = tradeQuery:SortResults(results, tradeQuery.sortModes.StatValue, function(index) return statValues[index] end, realm, league)
					end
					local page, paging = T.Page(sorted, args, 10, 100)
					local listings = { }
					for position, entry in ipairs(page) do
						local result = results[entry.index]
						local item = new("Item"):Item(result.item_string)
						local listing = {
							rank = (args.offset or 0) + position,
							name = T.Clean(item.name),
							rarity = item.rarity,
							price = { amount = result.amount, currency = result.currency, type = result.priceType },
							priceInDivines = T.Round(tradeQuery:ConvertCurrencyToDivs(result.currency, result.amount, realm, league), 3),
							statValue = T.Round(statValues[entry.index], 4),
							tradeWeightedSum = tonumber(result.weight),
							seller = result.trader,
							item = result.item_string,
						}
						local output
						if row.slotName == "Megalomaniac" then
							local combos = { }
							for _, evaluation in ipairs(evaluations[entry.index]) do
								t_insert(combos, { nodes = evaluation.DNs, statValue = T.Round(evaluation.weight, 4) })
							end
							listing.nodeCombinations = combos
							local best = evaluations[entry.index][1]
							local addNodes = { }
							for _, dn in ipairs(best.DNs) do
								addNodes[build.spec.tree.clusterNodeMap[dn]] = true
							end
							output = calcFunc({ addNodes = addNodes })
							listing.changesFor = t_concat(best.DNs, " + ")
						else
							output = calcFunc({ repSlotName = tradeQuery:GetEvaluationSlotName(row), repItem = item })
						end
						listing.changes = changeLines(build, baseOutput, output)
						listing.unmetRequirements = T.Array(T.UnmetRequirements(output))
						if result.whisper and result.priceType ~= "~b/o" then
							listing.whisper = result.whisper
						elseif sentQuery then
							listing.listingUrl = tradeQuery:BuildListingSearchUrl(sentQuery, result, realm, league)
						end
						t_insert(listings, listing)
					end
					return {
						slot = row.unique and row.slotName or slot.slotName,
						measuredIn = row.unique and slotLabel(slot) or nil,
						league = league,
						realm = realm,
						searchUrl = searchUrl,
						weights = usedWeights(weights),
						sortedBy = sortedBy,
						found = #results,
						listings = listings,
						page = paging,
						notes = notes[1] and T.Array(notes) or nil,
					}
				end)
			end
			if args.url then
				searchUrl = args.url
				requests:SearchWithURL(args.url, onResults)
			else
				-- Trade URLs contain only the query; the API also needs the sort order (as the trader sends it).
				local body = dkjson.encode({ query = generated.query, sort = { ["statgroup.0"] = "desc" }, engine = "new" })
				requests:SearchWithQueryWeightAdjusted(realm, league, body, onResults, {
					callbackQueryId = function(queryId)
						searchUrl = requests:buildUrl(tradeQuery.hostName .. "trade/search", realm, league, queryId)
					end,
				})
			end
		end, timeout)
	end,
}
