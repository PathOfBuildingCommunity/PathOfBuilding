-- Tests for RadiusJewelFinder: buildJewelSockets, computeVariantImpact, computeSocketImpact
--
-- Uses OccVortex (3.13 Occultist/Vortex) as reference build.
-- Allocated jewel sockets in that build: 36634, 61419, 41263 (all occupied by jewels).
-- All other sockets are unallocated and empty.

local occVortex = LoadModule("../spec/TestBuilds/3.13/OccVortex.lua")

local MIGHT_OF_MEEK_RAW_TEXT = [[Might of the Meek
Crimson Jewel
Radius: Large
50% increased Effect of non-Keystone Passive Skills in Radius
Notable Passive Skills in Radius grant nothing]]

local UNNATURAL_INSTINCT_RAW_TEXT = [[Unnatural Instinct
Viridian Jewel
Limited to: 1
Radius: Small
Allocated Small Passive Skills in Radius grant nothing
Grants all bonuses of Unallocated Small Passive Skills in Radius]]

local ANATOMICAL_KNOWLEDGE_RAW_TEXT = [[Anatomical Knowledge
Cobalt Jewel
Source: No longer obtainable
Radius: Large
8% increased maximum Life
Adds 1 to Maximum Life per 3 Intelligence Allocated in Radius]]

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function makeFinder()
	return new("RadiusJewelFinder", { build = build })
end

local function getLargeRadiusIndex()
	local map = {}
	for i, r in ipairs(data.jewelRadius) do
		if r.inner == 0 and not map[r.label] then map[r.label] = i end
	end
	return map["Large"]
end

local function isSorted(results, key)
	for i = 2, #results do
		if results[i - 1][key] < results[i][key] then return false end
	end
	return true
end

local function copyShallow(tbl)
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = v
	end
	return out
end

local function snapshotFinderState()
	local socketSelItemIds = {}
	for socketId, slot in pairs(build.itemsTab.sockets) do
		socketSelItemIds[socketId] = slot.selItemId
	end

	local itemOrderList = {}
	for i, itemId in ipairs(build.itemsTab.itemOrderList) do
		itemOrderList[i] = itemId
	end

	local itemCount = 0
	for _ in pairs(build.itemsTab.items) do
		itemCount = itemCount + 1
	end

	return {
		socketSelItemIds = socketSelItemIds,
		itemOrderList = itemOrderList,
		itemCount = itemCount,
		jewels = copyShallow(build.spec.jewels),
	}
end

local function assertFinderStateUnchanged(before)
	local after = snapshotFinderState()
	assert.are.same(before.socketSelItemIds, after.socketSelItemIds)
	assert.are.same(before.itemOrderList, after.itemOrderList)
	assert.are.equal(before.itemCount, after.itemCount)
	assert.are.same(before.jewels, after.jewels)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Tests
-- ─────────────────────────────────────────────────────────────────────────────

describe("RadiusJewelFinder #radiusjewel", function()

	before_each(function()
		loadBuildFromXML(occVortex.xml, "OccVortex")
	end)

	-- ── buildJewelSockets ───────────────────────────────────────────────────

	describe("buildJewelSockets", function()

		it("returns a non-empty list", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			assert.is_true(#sockets > 0, "expected at least one jewel socket")
		end)

		it("each entry has id (number) and label (string)", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			for _, s in ipairs(sockets) do
				assert.is_number(s.id)
				assert.is_string(s.label)
			end
		end)

		it("marks the 3 allocated sockets with # prefix", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			local allocIds = { [36634] = true, [61419] = true, [41263] = true }
			for _, s in ipairs(sockets) do
				if allocIds[s.id] then
					assert.is_true(s.label:sub(1, 2) == "# ",
						"socket " .. s.id .. " should start with '# ', got: " .. s.label)
				end
			end
		end)

		it("unallocated sockets without # prefix", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			local allocIds = { [36634] = true, [61419] = true, [41263] = true }
			for _, s in ipairs(sockets) do
				if not allocIds[s.id] then
					assert.is_false(s.label:sub(1, 2) == "# ",
						"socket " .. s.id .. " should NOT start with '# '")
				end
			end
		end)

		it("list is sorted alphabetically by label", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			for i = 2, #sockets do
				assert.is_true(sockets[i - 1].label <= sockets[i].label,
					"sockets not sorted at index " .. i)
			end
		end)

		it("includes known occupied and empty sockets from the fixture build", function()
			local sockets = makeFinder():buildJewelSockets(getLargeRadiusIndex())
			local seenIds = {}
			for _, socket in ipairs(sockets) do
				seenIds[socket.id] = true
			end

			assert.is_true(seenIds[36634], "expected occupied socket 36634 to be present")
			assert.is_true(seenIds[61419], "expected occupied socket 61419 to be present")
			assert.is_true(seenIds[41263], "expected occupied socket 41263 to be present")
			assert.is_true(seenIds[33631], "expected empty socket 33631 to be present")
		end)

	end)

	describe("popup integration", function()

			it("opens the popup and keeps foulborn jewel types aligned", function()
			local function listLabels(list)
				local labels = {}
				for i, entry in ipairs(list) do
					labels[i] = type(entry) == "table" and entry.label or entry
				end
				return labels
			end

				local function lineTexts(list)
					local lines = {}
					for i, entry in ipairs(list) do
						lines[i] = entry[1]
						if entry[2] then
							lines[#lines + 1] = entry[2]
						end
					end
					return lines
				end

				local function waitForCompute(popup)
					local frameCount = 0
					while popup.controls.computeButton.label == "Cancel" and frameCount < 1000 do
						runCallback("OnFrame")
						frameCount = frameCount + 1
					end
					assert.are_not.equal("Cancel", popup.controls.computeButton.label, "expected async compute to finish")
				end

			local function findIndex(list, needle)
				for i, label in ipairs(listLabels(list)) do
					if label == needle then
						return i
					end
				end
			end

			while main.popups[1] do
				main:ClosePopup()
			end

			local popup = makeFinder():Open()
			assert.is_not_nil(popup)
			assert.are.equal("Find Radius Jewel", popup.title)

			local hasIntuitiveLeap = false
			local hasThreadOfHope = false
			local hasTemperedAndTranscendent = false
			local hasSplitPersonality = false
			local hasImpossibleEscape = false
			local normalLabels = listLabels(popup.controls.jewelTypeSelect.list)
			for _, label in ipairs(popup.controls.jewelTypeSelect.list) do
				if label == "Intuitive Leap" then
					hasIntuitiveLeap = true
				elseif label == "Thread of Hope" then
					hasThreadOfHope = true
				elseif label == "Tempered & Transcendent" then
					hasTemperedAndTranscendent = true
				elseif label == "Split Personality" then
					hasSplitPersonality = true
				elseif label == "Impossible Escape" then
					hasImpossibleEscape = true
				end
			end

			assert.is_true(hasIntuitiveLeap, "expected Intuitive Leap in jewel type list")
			assert.is_true(hasThreadOfHope, "expected Thread of Hope in normal jewel type list")
			assert.is_true(hasTemperedAndTranscendent, "expected Tempered & Transcendent in jewel type list")
			assert.is_true(hasSplitPersonality, "expected Split Personality in jewel type list")
			assert.is_true(hasImpossibleEscape, "expected Impossible Escape in jewel type list")
			assert.are.equal("The Light of Meaning", normalLabels[1])
			assert.are.equal("Might of the Meek", normalLabels[2])
			assert.are.equal("Thread of Hope", normalLabels[#normalLabels])

			popup.controls.foulbornCheck.state = true
			popup.controls.foulbornCheck.changeFunc(true)

				local hasDreamsAndNightmares = false
				local hasFoulbornThreadOfHope = false
				local hasFoulbornLightOfMeaning = false
				local hasFoulbornInspiredLearning = false
				local hasFoulbornCombatFocus = false
				local foulbornLabels = listLabels(popup.controls.jewelTypeSelect.list)
				for _, label in ipairs(popup.controls.jewelTypeSelect.list) do
					if label == "Dreams & Nightmares" then
						hasDreamsAndNightmares = true
					elseif label == "Thread of Hope" then
						hasFoulbornThreadOfHope = true
					elseif label == "The Light of Meaning" then
						hasFoulbornLightOfMeaning = true
					elseif label == "Inspired Learning" then
						hasFoulbornInspiredLearning = true
					elseif label == "Combat Focus" then
						hasFoulbornCombatFocus = true
					end
				end

				assert.is_true(hasDreamsAndNightmares, "expected Dreams & Nightmares in foulborn jewel type list")
				assert.is_true(hasFoulbornThreadOfHope, "expected Thread of Hope in foulborn jewel type list")
				assert.is_true(hasFoulbornLightOfMeaning, "expected The Light of Meaning in foulborn jewel type list")
				assert.is_true(hasFoulbornInspiredLearning, "expected Inspired Learning in foulborn jewel type list")
				assert.is_true(hasFoulbornCombatFocus, "expected Combat Focus in foulborn jewel type list")
				assert.are.equal("The Light of Meaning", foulbornLabels[1])
				assert.are.equal("Might of the Meek", foulbornLabels[2])
				assert.are.equal("Thread of Hope", foulbornLabels[#foulbornLabels])

				local unnaturalIdx = findIndex(popup.controls.jewelTypeSelect.list, "Unnatural Instinct")
				assert.is_not_nil(unnaturalIdx, "expected Unnatural Instinct in foulborn jewel type list")
				popup.controls.jewelTypeSelect.selFunc(unnaturalIdx)
				assert.are.same({
				"Small gain / notable loss",
				"Notable gain / small loss",
					"Notable swap",
				}, listLabels(popup.controls.jewelVariantSelect.list))

					local intuitiveIdx = findIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap")
					assert.is_not_nil(intuitiveIdx, "expected Intuitive Leap in foulborn jewel type list")
					popup.controls.jewelTypeSelect.selFunc(intuitiveIdx)
					assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Intuitive Leap")
					assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
						assert.are.equal("Simulated", popup.controls.computeMethodSelect.list[popup.controls.computeMethodSelect.selIndex])
						popup.controls.computeMethodSelect.selFunc(1)
						assert.is_true(popup.controls.computeButton.shown, "expected Compute for Intuitive Leap")
						popup.controls.computeButton:Click()
						waitForCompute(popup)
					assert.are.equal("computeSocket", popup.controls.resultsList.mode)
					assert.is_true(#popup.controls.resultsList.list > 0, "expected Intuitive Leap compute results")
					local intuitiveDetail = popup.controls.resultsList.list[1].detailText or ""
						assert.is_true(intuitiveDetail ~= "",
						"expected Intuitive Leap compute detail text")
					assert.is_true(popup.controls.statusLabel.label:find("Fast", 1, true) ~= nil,
						"expected compute status to mention Fast")

					local inspiredIdx = findIndex(popup.controls.jewelTypeSelect.list, "Inspired Learning")
					assert.is_not_nil(inspiredIdx, "expected Inspired Learning in foulborn jewel type list")
					popup.controls.jewelTypeSelect.selFunc(inspiredIdx)
					assert.is_true(popup.controls.computeButton.shown, "expected Compute for Inspired Learning")
					assert.are.same({
						"Large radius / no notables",
						"Small radius / 8-12 small passives",
					}, listLabels(popup.controls.jewelVariantSelect.list))

				popup.controls.foulbornCheck.state = false
				popup.controls.foulbornCheck.changeFunc(false)
				local temperedIdx = findIndex(popup.controls.jewelTypeSelect.list, "Tempered & Transcendent")
				assert.is_not_nil(temperedIdx, "expected Tempered & Transcendent in jewel type list")
				popup.controls.jewelTypeSelect.selFunc(temperedIdx)
				assert.are.same({
					"Tempered Flesh",
					"Transcendent Flesh",
					"Tempered Mind",
					"Transcendent Mind",
					"Tempered Spirit",
					"Transcendent Spirit",
				}, listLabels(popup.controls.jewelVariantSelect.list))

				local splitIdx = findIndex(popup.controls.jewelTypeSelect.list, "Split Personality")
				assert.is_not_nil(splitIdx, "expected Split Personality in jewel type list")
				popup.controls.jewelTypeSelect.selFunc(splitIdx)
				assert.is_true(popup.controls.computeButton.shown, "expected Compute for Split Personality")
				assert.are.same({
					"Strength",
					"Dexterity",
					"Intelligence",
					"Life",
					"Mana",
					"Energy Shield",
					"Armour",
					"Evasion Rating",
					"Accuracy Rating",
				}, listLabels(popup.controls.jewelVariantSelect.list))

				local impossibleIdx = findIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape")
				assert.is_not_nil(impossibleIdx, "expected Impossible Escape in jewel type list")
				popup.controls.jewelTypeSelect.selFunc(impossibleIdx)
				assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Impossible Escape")
				assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
				assert.is_true(#popup.controls.jewelVariantSelect.list > 0, "expected Impossible Escape keystone variants")
				popup.controls.findButton:Click()
				assert.are.equal("find", popup.controls.resultsList.mode)
				assert.is_true(popup.controls.statusLabel.label:find("Impossible Escape", 1, true) ~= nil)
				local hasImpossibleEscapeKeystoneLabel = false
				for _, row in ipairs(popup.controls.resultsList.list) do
					if row.detailText and row.detailText:find("|", 1, true) then
						hasImpossibleEscapeKeystoneLabel = true
						break
					end
				end
				assert.is_true(hasImpossibleEscapeKeystoneLabel, "expected Impossible Escape find detail to include the winning keystone")

				popup.controls.foulbornCheck.state = true
				popup.controls.foulbornCheck.changeFunc(true)
				local threadIdx = findIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope")
				assert.is_not_nil(threadIdx, "expected Thread of Hope in foulborn jewel type list")
				popup.controls.jewelTypeSelect.selFunc(threadIdx)
				assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Thread of Hope")
				assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
				popup.controls.findButton:Click()
				assert.are.equal("findThread", popup.controls.resultsList.mode)
				assert.is_true(popup.controls.statusLabel.label:find("Thread of Hope", 1, true) ~= nil)
				local hasWinningRingLabel = false
				for _, row in ipairs(popup.controls.resultsList.list) do
					if row.variantLabel and row.variantLabel:find(" Ring", 1, true) then
						hasWinningRingLabel = true
						break
					end
				end
				assert.is_true(hasWinningRingLabel, "expected winning Thread of Hope ring label in find results")

				local dreamsIdx = findIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares")
				assert.is_not_nil(dreamsIdx, "expected Dreams & Nightmares in foulborn jewel type list")
				popup.controls.jewelTypeSelect.selFunc(dreamsIdx)
			assert.is_true(popup.controls.variantFamilySelect.shown, "expected family filter for foulborn Dreams & Nightmares")
			assert.is_true(findIndex(popup.controls.jewelVariantSelect.list, "Red Dream: Max Life + Extra Chaos") ~= nil)
			assert.is_true(findIndex(popup.controls.jewelVariantSelect.list, "Blue Nightmare: Lightning Conv to Chaos + Crit Multi") ~= nil)

			popup.controls.variantFamilySelect.selFunc(2)
				assert.are.same({
					"Red Dream: Max Life + Extra Chaos",
					"Red Dream: Chaos Res per Endurance + Endurance on Kill",
					"Red Dream: Max Life + Chaos Res",
					"Red Dream: Fire Lucky + Endurance on Kill",
					"Red Dream: Max Life + Fire Lucky",
				}, listLabels(popup.controls.jewelVariantSelect.list))
				assert.is_true(findIndex(lineTexts(popup.controls.previewList.list), "^8Family: Red Dream") ~= nil)

				popup.controls.computeButton:Click()
				waitForCompute(popup)
				assert.are.equal("computeSocket", popup.controls.resultsList.mode)
				assert.is_true(popup.controls.statusLabel.label:find("Red Dream", 1, true) ~= nil)
				local hasWinningVariantLabel = false
				local tooltipResultLine
				for _, row in ipairs(popup.controls.resultsList.list) do
					if row.detailText and row.detailText:find("Red Dream:", 1, true) then
						hasWinningVariantLabel = true
						break
					end
				end
				for _, lineInfo in ipairs(popup.controls.resultsList.list) do
					if lineInfo.socketId and lineInfo.baseOutput and lineInfo.compareOutput then
						tooltipResultLine = lineInfo
						break
					end
				end
				assert.is_true(hasWinningVariantLabel, "expected winning Red Dream variant label in compute results")
				assert.is_not_nil(tooltipResultLine, "expected a compute result row with tooltip compare outputs")
				assert.are.equal("^7Socketing the best variant here will give you:", tooltipResultLine.tooltipHeader)
	
				while main.popups[1] do
					main:ClosePopup()
				end

				local reopened = makeFinder():Open()
				assert.is_not_nil(reopened)
				assert.are.equal("Dreams & Nightmares", reopened.controls.jewelTypeSelect.list[reopened.controls.jewelTypeSelect.selIndex])
				assert.are.equal("computeSocket", reopened.controls.resultsList.mode)
				while main.popups[1] do
					main:ClosePopup()
				end

			assert.is_nil(main.popups[1])
		end)

	end)

	-- ── computeVariantImpact (LOM) ──────────────────────────────────────────

	describe("computeVariantImpact", function()

		-- Use socket 33631 (unallocated, empty in OccVortex)
		local SOCKET_ID = 33631

		it("returns exactly 13 variant results", function()
			local results, baseline = makeFinder():computeVariantImpact(SOCKET_ID, "Life")
			assert.are.equal(13, #results)
			assert.is_number(baseline)
			assert.is_true(baseline > 0)
		end)

		it("each result has required fields", function()
			local results, _ = makeFinder():computeVariantImpact(SOCKET_ID, "Life")
			for _, r in ipairs(results) do
				assert.is_not_nil(r.variant)
				assert.is_string(r.variant.name)
				assert.is_number(r.variantIdx)
				assert.is_number(r.value)
				assert.is_number(r.delta)
				assert.is_true(r.variantIdx >= 1 and r.variantIdx <= 13)
			end
		end)

		it("returns each Light of Meaning variant exactly once", function()
			local results, _ = makeFinder():computeVariantImpact(SOCKET_ID, "Life")
			local seenNames = {}
			for _, r in ipairs(results) do
				assert.is_nil(seenNames[r.variant.name],
					"duplicate variant in results: " .. r.variant.name)
				seenNames[r.variant.name] = true
			end
			assert.are.equal(13, #results)
		end)

		it("results are sorted by delta descending", function()
			local results, _ = makeFinder():computeVariantImpact(SOCKET_ID, "Life")
			assert.is_true(isSorted(results, "delta"),
				"variant results should be sorted by delta descending")
		end)

		it("restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			makeFinder():computeVariantImpact(SOCKET_ID, "Life")
			local after = build.calcsTab.mainOutput["Life"]
			assert.are.equal(before, after)
		end)

		it("restores socket and item state after compute on an empty socket", function()
			local before = snapshotFinderState()
			makeFinder():computeVariantImpact(SOCKET_ID, "Life")
			assertFinderStateUnchanged(before)
		end)

		it("restores occupied socket jewel after compute on allocated socket", function()
			-- Socket 36634 is allocated and occupied by item 17 in OccVortex
			local slot = build.itemsTab.sockets[36634]
			local prevId = slot.selItemId
			makeFinder():computeVariantImpact(36634, "Life")
			assert.are.equal(prevId, slot.selItemId,
				"selItemId should be restored to " .. prevId)
		end)

		it("Life variant gives non-negative delta on allocated socket with passives", function()
			-- Socket 36634 is allocated; its radius should contain allocated passives
			local results, _ = makeFinder():computeVariantImpact(36634, "Life")
			local lifeResult
			for _, r in ipairs(results) do
				if r.variantIdx == 1 then lifeResult = r; break end
			end
			assert.is_not_nil(lifeResult)
			assert.is_true(lifeResult.delta >= 0,
				"Life variant should not decrease life on allocated socket")
		end)

		it("restores socket and item state after compute on an occupied socket", function()
			local before = snapshotFinderState()
			makeFinder():computeVariantImpact(36634, "Life")
			assertFinderStateUnchanged(before)
		end)

	end)

	-- ── computeSocketImpact (MoM / UI / AK) ────────────────────────────────

	describe("computeSocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		it("returns a table (may be empty if all sockets occupied)", function()
			local results, baseline = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			assert.is_table(results)
			assert.is_number(baseline)
		end)

		it("returns the current main output as baseline for the requested stat", function()
			local expectedBaseline = build.calcsTab.mainOutput["Life"]
			local _, baseline = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			assert.are.equal(expectedBaseline, baseline)
		end)

		it("returns at least one result for the fixture build", function()
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			assert.is_true(#results > 0, "expected at least one empty jewel socket result")
		end)

		it("MoM: only tests empty sockets (selItemId == 0)", function()
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			for _, r in ipairs(results) do
				local slot = build.itemsTab.sockets[r.socket.id]
				assert.are.equal(0, slot.selItemId,
					"result socket " .. r.socket.id .. " should be empty after compute")
			end
		end)

		it("MoM: results sorted by delta descending", function()
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			assert.is_true(isSorted(results, "delta"),
				"MoM socket results should be sorted by delta descending")
		end)

		it("MoM: restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			makeFinder():computeSocketImpact(getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			assert.are.equal(before, build.calcsTab.mainOutput["Life"])
		end)

		it("MoM: restores socket and item state after compute", function()
			local before = snapshotFinderState()
			makeFinder():computeSocketImpact(getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			assertFinderStateUnchanged(before)
		end)

		it("UI: restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			makeFinder():computeSocketImpact(getSockets(), UNNATURAL_INSTINCT_RAW_TEXT, "Life")
			assert.are.equal(before, build.calcsTab.mainOutput["Life"])
		end)

		it("AK: restores TotalLife after compute", function()
			local before = build.calcsTab.mainOutput["Life"]
			makeFinder():computeSocketImpact(getSockets(), ANATOMICAL_KNOWLEDGE_RAW_TEXT, "Life")
			assert.are.equal(before, build.calcsTab.mainOutput["Life"])
		end)

		it("respects a max total points budget for standard compute", function()
			local maxPoints = 2
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life", false, nil, maxPoints)
			for _, r in ipairs(results) do
				assert.is_true((r.socket.pathDist or 0) <= maxPoints,
					"socket " .. r.socket.id .. " exceeded max points")
			end
		end)

		it("occupied sockets (36634, 61419, 41263) are skipped", function()
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			local occupiedIds = { [36634] = true, [61419] = true, [41263] = true }
			for _, r in ipairs(results) do
				assert.is_nil(occupiedIds[r.socket.id],
					"occupied socket " .. r.socket.id .. " should not appear in results")
			end
		end)

		it("each result has socket, value and delta fields", function()
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life")
			local seenSocketIds = {}
			for _, r in ipairs(results) do
				assert.is_not_nil(r.socket)
				assert.is_number(r.socket.id)
				assert.is_number(r.value)
				assert.is_number(r.delta)
				assert.is_nil(seenSocketIds[r.socket.id],
					"duplicate socket result for socket " .. r.socket.id)
				seenSocketIds[r.socket.id] = true
			end
		end)

	end)

	describe("connectionless compute budgets", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		it("respects a max total points budget for Intuitive Leap", function()
			local maxPoints = 4
			local results, _ = makeFinder():computeIntuitiveLeapSocketImpact(
				getSockets(), "Life", false, "simulated_greedy", { }, nil, maxPoints)
			for _, r in ipairs(results) do
				local totalPoints = (r.socket.pathDist or 0) + (r.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. r.socket.id .. " plan exceeded max points")
			end
		end)

		it("stops at jewel-only when the socket already uses the whole budget", function()
			local targetSocket
			for _, socket in ipairs(getSockets()) do
				if socket.pathDist and socket.pathDist > 0 then
					targetSocket = socket
					break
				end
			end
			assert.is_not_nil(targetSocket, "expected at least one socket with path cost")
			local maxPoints = targetSocket.pathDist
			local sockets = { targetSocket }
			local fastResults = makeFinder():computeIntuitiveLeapSocketImpact(
				sockets, "Life", false, "fast", { }, nil, maxPoints)
			local simulatedResults = makeFinder():computeIntuitiveLeapSocketImpact(
				sockets, "Life", false, "simulated_greedy", { }, nil, maxPoints)
			assert.are.equal(0, fastResults[1].addedNodeCount or 0)
			assert.are.equal(0, simulatedResults[1].addedNodeCount or 0)
		end)

	end)

end)
