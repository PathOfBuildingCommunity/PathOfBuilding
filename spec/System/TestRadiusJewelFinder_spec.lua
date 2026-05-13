-- Tests for RadiusJewelFinder: buildJewelSockets, computeBestVariantSocketImpact, computeSocketImpact
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

local function buildSplitPersonalityRawText(modLine)
	return table.concat({
		"Split Personality",
		"Crimson Jewel",
		"Variable",
		"This Jewel's Socket has 25% increased effect per Allocated Passive Skill between it and your Class' starting location",
		modLine,
		"Corrupted",
	}, "\n")
end

local function buildImpossibleEscapeRawText(keystoneName)
	return table.concat({
		"Impossible Escape",
		"Viridian Jewel",
		"Limited to: 1",
		"Small",
		"Passive Skills in radius of " .. keystoneName .. " can be allocated without being connected to your tree",
		"Corrupted",
	}, "\n")
end

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

local function getSmallRadiusIndex()
	local map = {}
	for i, r in ipairs(data.jewelRadius) do
		if r.inner == 0 and not map[r.label] then map[r.label] = i end
	end
	return map["Small"]
end

local function makeImpossibleEscapeTestVariant()
	local smallRadiusIndex = getSmallRadiusIndex()
	local allocNodes = build.spec.allocNodes
	for keystoneName, node in pairs(build.spec.tree.keystoneMap or {}) do
		if node and node.nodesInRadius and node.nodesInRadius[smallRadiusIndex] then
			-- Ensure there is at least one unallocated candidate node
			local hasCandidate = false
			for nodeId, n in pairs(node.nodesInRadius[smallRadiusIndex]) do
				if not allocNodes[nodeId] and not n.ascendancyName
						and n.type ~= "Socket" and n.type ~= "ClassStart"
						and n.type ~= "AscendClassStart" and n.type ~= "Mastery" then
					hasCandidate = true
					break
				end
			end
			if hasCandidate then
				return {
					name = keystoneName,
					keystoneName = keystoneName,
					rawText = buildImpossibleEscapeRawText(keystoneName),
				}
			end
		end
	end
end

local function makeThreadVariants()
	local names = { "Small", "Medium", "Large", "Very Large", "Massive" }
	local variants = {}
	local idx = 1
	for radiusIndex, radius in ipairs(data.jewelRadius) do
		if radius.inner > 0 then
			variants[#variants + 1] = {
				name = names[idx] or ("Ring " .. idx),
				radiusIndex = radiusIndex,
			}
			idx = idx + 1
		end
	end
	return variants
end

local function isSorted(results, key)
	for i = 2, #results do
		if results[i - 1][key] < results[i][key] then return false end
	end
	return true
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
		jewels = copyTable(build.spec.jewels, true),
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
						"socket " .. s.id .. " should start with '# ', was: " .. s.label)
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

			it("opens the popup with expected jewel types and controls", function()
			local function listLabels(list)
				local labels = {}
				for i, entry in ipairs(list) do
					labels[i] = type(entry) == "table" and entry.label or entry
				end
				return labels
			end

			local function tooltipTexts(control, index)
				local tooltip = new("Tooltip")
				control.tooltipFunc(tooltip, "DROP", index, control.list[index])
				local texts = {}
				for _, line in ipairs(tooltip.lines) do
					if line.text and line.text ~= "" then
						texts[#texts + 1] = line.text
					end
				end
				return texts
			end
			local function buttonTooltipTexts(control, ...)
				local tooltip = new("Tooltip")
				control.tooltipFunc(tooltip, ...)
				local texts = {}
				for _, line in ipairs(tooltip.lines) do
					if line.text and line.text ~= "" then
						texts[#texts + 1] = line.text
					end
				end
				return texts
			end

			local function findIndex(list, needle)
				for i, label in ipairs(listLabels(list)) do
					if label == needle then
						return i
					end
				end
			end
			local function assertAlphabetical(labels, message)
				for i = 2, #labels do
					assert.is_true(labels[i - 1] <= labels[i], message or ("labels not sorted at index " .. i))
				end
			end

			while main.popups[1] do
				main:ClosePopup()
			end

			build.radiusJewelFinderState = nil
			local popup = makeFinder():Open()
			assert.is_not_nil(popup)
			assert.are.equal("Find Radius Jewel", popup.title)
			local popupWidth, popupHeight = popup:GetSize()
			assert.is_true(popupWidth <= 1020, "popup should fit within a 1024px-wide screen")
			local popupX, popupY = popup:GetPos()
			local function assertControlInsidePopup(controlName)
				local control = popup.controls[controlName]
				assert.is_not_nil(control, "expected control: " .. controlName)
				local x, y = control:GetPos()
				local width, height = control:GetSize()
				assert.is_true(x >= popupX, controlName .. " should not extend past the popup left edge")
				assert.is_true(y >= popupY, controlName .. " should not extend past the popup top edge")
				assert.is_true(x + width <= popupX + popupWidth, controlName .. " should not extend past the popup right edge")
				assert.is_true(y + height <= popupY + popupHeight, controlName .. " should not extend past the popup bottom edge")
			end
			for _, controlName in ipairs({
				"computeButton",
				"impactStatSelect",
				"previewList",
				"resultDetailList",
				"findButton",
				"applyButton",
				"closeButton",
			}) do
				assertControlInsidePopup(controlName)
			end
			for _, controlName in ipairs({ "findButton", "applyButton", "closeButton" }) do
				local control = popup.controls[controlName]
				local _, y = control:GetPos()
				local _, height = control:GetSize()
				assert.are.equal(10, popupY + popupHeight - (y + height), controlName .. " should keep the bottom action margin")
			end
			local computeX = popup.controls.computeButton:GetPos()
			local computeWidth = popup.controls.computeButton:GetSize()
			assert.are.equal(20, popupX + popupWidth - (computeX + computeWidth), "computeButton should keep the header right margin")
			local closeX = popup.controls.closeButton:GetPos()
			local closeWidth = popup.controls.closeButton:GetSize()
			assert.are.equal(10, popupX + popupWidth - (closeX + closeWidth), "closeButton should keep the bottom right margin")
			local computeTooltipTexts = buttonTooltipTexts(popup.controls.computeButton)
			assert.is_true(#computeTooltipTexts > 0, "expected Compute tooltip content")
			assert.is_true(computeTooltipTexts[1]:find("selected stat", 1, true) ~= nil,
				"expected Compute tooltip to explain stat ranking")
			local findTooltipTexts = buttonTooltipTexts(popup.controls.findButton)
			assert.is_true(#findTooltipTexts > 0, "expected Find tooltip content")
			assert.is_true(findTooltipTexts[1]:find("passive%-match") ~= nil,
				"expected Find tooltip to explain passive matching")
			local applyTooltipTexts = buttonTooltipTexts(popup.controls.applyButton)
			assert.is_true(#applyTooltipTexts > 0, "expected Apply tooltip content")
			assert.is_true(applyTooltipTexts[1]:find("Select a result", 1, true) ~= nil,
				"expected Apply tooltip to explain missing selection")
			assert.is_nil(popup.controls.closeButton.tooltipFunc, "Close is self-explanatory and should not need a tooltip")
			local maxPointsTooltipTexts = buttonTooltipTexts(popup.controls.maxPointsEdit)
			assert.is_true(#maxPointsTooltipTexts > 0, "expected Max pts tooltip content")
			assert.is_true(maxPointsTooltipTexts[1]:find("total passive points", 1, true) ~= nil,
				"expected Max pts tooltip to explain total point limit")
			local occupiedTooltipTexts = buttonTooltipTexts(popup.controls.occupiedModeSelect, "DROP", 2, popup.controls.occupiedModeSelect.list[2])
			assert.is_true(#occupiedTooltipTexts > 0, "expected Sockets tooltip content")
			assert.is_true(occupiedTooltipTexts[2]:find("socket%-specific") ~= nil,
				"expected Safe occupied tooltip to explain socket-specific behavior")
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected Method selector for All jewels")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			local fastMethodTooltipTexts = buttonTooltipTexts(popup.controls.computeMethodSelect, "DROP", 1, popup.controls.computeMethodSelect.list[1])
			assert.is_true(fastMethodTooltipTexts[1]:find("Intuitive Leap", 1, true) ~= nil,
				"expected All jewels Method tooltip to name affected jewel types")
			assert.is_true(fastMethodTooltipTexts[2]:find("independently", 1, true) ~= nil,
				"expected Fast method tooltip to explain independent scoring")
			local simulatedMethodTooltipTexts = buttonTooltipTexts(popup.controls.computeMethodSelect, "DROP", 2, popup.controls.computeMethodSelect.list[2])
			assert.is_true(simulatedMethodTooltipTexts[2]:find("recalculates", 1, true) ~= nil,
				"expected Simulated method tooltip to explain recalculation")
			popup.controls.computeMethodSelect.selFunc(2)
			assert.are.equal("simulated_greedy", build.radiusJewelFinderState.computeMethodId)
			popup.controls.computeMethodSelect.selFunc(1)
			local allResultsViewTooltipTexts = buttonTooltipTexts(popup.controls.allJewelsViewSelect, "DROP", 1, popup.controls.allJewelsViewSelect.list[1])
			assert.is_true(allResultsViewTooltipTexts[1]:find("every compatible result", 1, true) ~= nil,
				"expected All results view tooltip to explain unfiltered results")
			local bestPerSocketTooltipTexts = buttonTooltipTexts(popup.controls.allJewelsViewSelect, "DROP", 2, popup.controls.allJewelsViewSelect.list[2])
			assert.is_true(bestPerSocketTooltipTexts[1]:find("one best result per socket", 1, true) ~= nil,
				"expected Best per socket tooltip to explain per-socket filtering")
			assert.is_true(bestPerSocketTooltipTexts[2]:find("Jewel limits", 1, true) ~= nil,
				"expected Best per socket tooltip to mention jewel limits")
			assert.is_true(findIndex(popup.controls.impactStatSelect.list, "Full DPS") ~= nil)
			assert.is_true(findIndex(popup.controls.impactStatSelect.list, "Hit DPS") ~= nil)
			assert.is_true(findIndex(popup.controls.impactStatSelect.list, "Block Chance") ~= nil)

			local hasIntuitiveLeap = false
			local hasThreadOfHope = false
			local hasTemperedAndTranscendent = false
			local hasSplitPersonality = false
			local hasImpossibleEscape = false
			local hasDreamsAndNightmares = false
			local jewelTypeLabels = listLabels(popup.controls.jewelTypeSelect.list)
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
				elseif label == "Dreams & Nightmares" then
					hasDreamsAndNightmares = true
				end
			end

			assert.is_true(hasIntuitiveLeap, "expected Intuitive Leap in jewel type list")
			assert.is_true(hasThreadOfHope, "expected Thread of Hope in jewel type list")
			assert.is_true(hasTemperedAndTranscendent, "expected Tempered & Transcendent in jewel type list")
			assert.is_true(hasSplitPersonality, "expected Split Personality in jewel type list")
			assert.is_true(hasImpossibleEscape, "expected Impossible Escape in jewel type list")
			assert.is_true(hasDreamsAndNightmares, "expected Dreams & Nightmares in jewel type list")
			assertAlphabetical(jewelTypeLabels, "expected jewel types to be sorted alphabetically")

			local allJewelsIdx = findIndex(popup.controls.jewelTypeSelect.list, "All jewels")
			assert.is_not_nil(allJewelsIdx, "expected All jewels in jewel type list")
			local allJewelsTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, allJewelsIdx)
			assert.is_true(allJewelsTooltipTexts[2]:find("%/Pt.", 1, true) ~= nil,
				"expected All jewels tooltip to show %/Pt")
			local doubledPercent = allJewelsTooltipTexts[2]:find("%%/Pt.", 1, true)
			assert.is_nil(doubledPercent, "All jewels tooltip should not show escaped %%/Pt")
			popup.controls.jewelTypeSelect.selFunc(allJewelsIdx)
			local selectedResultPreview = {
				{ height = 16, [1] = "^7Selected Jewel" },
				{ height = 16, [1] = "^8Selected result preview line" },
			}
			popup.controls.resultsList:SetMode("findAll", {
				{
					jewelName = "Selected Jewel",
					socketLabel = "Socket #1",
					socketId = 33631,
					points = 1,
					score = 10,
					scorePerPoint = 10,
					scorePerPointSort = 10,
					detailText = "Test detail",
					itemTooltipLines = selectedResultPreview,
					action = "new",
				},
			}, "(no results)")
			assert.are.equal("^7Selected Jewel", popup.controls.previewList.list[1][1])
			assert.are.equal(180, popup.controls.previewList.height())
			popup.controls.resultsList:SetMode("message", { }, "Click Find")
			assert.are.equal("^7Evaluate every jewel type.", popup.controls.previewList.list[1][1])
			assert.are.equal(48, popup.controls.previewList.height())

			-- Intuitive Leap: tooltip, compute method, occupied mode
			local intuitiveIdx = findIndex(popup.controls.jewelTypeSelect.list, "Intuitive Leap")
			assert.is_not_nil(intuitiveIdx, "expected Intuitive Leap in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(intuitiveIdx)
			local typeTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, intuitiveIdx)
			assert.is_true(#typeTooltipTexts > 0, "expected jewel type tooltip content")
			assert.is_true(typeTooltipTexts[1]:find("Intuitive Leap", 1, true) ~= nil,
				"expected type tooltip to describe Intuitive Leap")
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Intuitive Leap")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			assert.are.same({ "Free only", "Safe occupied", "All occupied" }, listLabels(popup.controls.occupiedModeSelect.list))
			assert.are.equal("Fast", popup.controls.computeMethodSelect.list[popup.controls.computeMethodSelect.selIndex])

			-- Dreams & Nightmares: variant tooltips
			local normalDreamsIdx = findIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares")
			assert.is_not_nil(normalDreamsIdx, "expected Dreams & Nightmares in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(normalDreamsIdx)
			local redNightmareIdx = findIndex(popup.controls.jewelVariantSelect.list, "The Red Nightmare")
			assert.is_not_nil(redNightmareIdx, "expected The Red Nightmare in variant list")
			local redNightmareTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, redNightmareIdx)
			assert.is_true(#redNightmareTooltipTexts > 0, "expected Red Nightmare tooltip content")
			for _, text in ipairs(redNightmareTooltipTexts) do
				assert.is_nil(text:find("{variant:", 1, true), "variant tooltip should not expose raw variant tags")
				assert.is_nil(text:find("Selected Variant:", 1, true), "variant tooltip should not expose saved-state metadata")
			end

			-- Tempered & Transcendent: type tooltip generic, variant tooltip specific
			local temperedIdx = findIndex(popup.controls.jewelTypeSelect.list, "Tempered & Transcendent")
			assert.is_not_nil(temperedIdx, "expected Tempered & Transcendent in jewel type list")
			local temperedTypeTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, temperedIdx)
			assert.is_true(#temperedTypeTooltipTexts > 0, "expected generic type tooltip content")
			for _, text in ipairs(temperedTypeTooltipTexts) do
				assert.is_nil(text:find("Tempered Flesh", 1, true),
					"type tooltip should not include a specific variant")
			end
			popup.controls.jewelTypeSelect.selFunc(temperedIdx)
			local variantTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, 1)
			assert.is_true(#variantTooltipTexts > 0, "expected jewel variant tooltip content")
			assert.is_true(variantTooltipTexts[1]:find("Tempered Flesh", 1, true) ~= nil,
				"expected variant tooltip to describe the hovered variant")
			local temperedLabels = listLabels(popup.controls.jewelVariantSelect.list)
			assert.is_true(#temperedLabels > 0, "expected Tempered & Transcendent variants")
			for _, label in ipairs(temperedLabels) do
				assert.is_truthy(label:find("Tempered") or label:find("Transcendent"),
					"variant should be Tempered or Transcendent: " .. label)
			end

			-- Split Personality: unique variant labels
			local splitIdx = findIndex(popup.controls.jewelTypeSelect.list, "Split Personality")
			assert.is_not_nil(splitIdx, "expected Split Personality in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(splitIdx)
			assert.is_true(popup.controls.computeButton.shown, "expected Compute for Split Personality")
			local splitLabels = listLabels(popup.controls.jewelVariantSelect.list)
			assert.is_true(#splitLabels > 0, "expected Split Personality variants")
			local seenLabels = {}
			for _, label in ipairs(splitLabels) do
				assert.is_string(label)
				assert.is_true(#label > 0, "variant label should not be empty")
				assert.is_nil(seenLabels[label], "duplicate Split Personality variant: " .. label)
				seenLabels[label] = true
			end

			-- Impossible Escape: compute method + keystone variants
			local impossibleIdx = findIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape")
			assert.is_not_nil(impossibleIdx, "expected Impossible Escape in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(impossibleIdx)
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Impossible Escape")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			assert.is_true(#popup.controls.jewelVariantSelect.list > 0, "expected Impossible Escape keystone variants")

			-- Thread of Hope: compute method
			local threadIdx = findIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope")
			assert.is_not_nil(threadIdx, "expected Thread of Hope in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(threadIdx)
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Thread of Hope")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))

			while main.popups[1] do
				main:ClosePopup()
			end
			assert.is_nil(main.popups[1])
		end)

	end)

	-- ── buildVariantsFromUniqueItem ──────────────────────────────────────────

	describe("buildVariantsFromUniqueItem", function()

		it("builds Light of Meaning variants with valid name and rawText", function()
			local variants = makeFinder():buildVariantsFromUniqueItem("The Light of Meaning")
			assert.is_true(#variants > 0, "expected at least one Light of Meaning variant")
			for _, v in ipairs(variants) do
				assert.is_string(v.name)
				assert.is_string(v.rawText)
				assert.is_true(#v.name > 0, "variant name should not be empty")
				assert.is_true(#v.rawText > 0, "variant rawText should not be empty")
			end
		end)

		it("builds Split Personality variants with unique names", function()
			local variants = makeFinder():buildVariantsFromUniqueItem("Split Personality")
			assert.is_true(#variants > 0, "expected at least one Split Personality variant")
			local seenNames = {}
			for _, v in ipairs(variants) do
				assert.is_string(v.name)
				assert.is_string(v.rawText)
				assert.is_nil(seenNames[v.name], "duplicate variant name: " .. v.name)
				seenNames[v.name] = true
			end
		end)

		it("variant rawText contains Selected Variant header", function()
			local variants = makeFinder():buildVariantsFromUniqueItem("The Light of Meaning")
			for _, v in ipairs(variants) do
				assert.is_not_nil(v.rawText:match("Selected Variant: %d+"), "rawText should contain Selected Variant: " .. v.name)
			end
		end)

	end)

	-- ── discoverFoulbornVariants ─────────────────────────────────────────────

	describe("discoverFoulbornVariants", function()

		it("returns empty table when no Foulborn data exists", function()
			local radiusIndexByLabel = {}
			for i, r in ipairs(data.jewelRadius) do
				if r.inner == 0 and not radiusIndexByLabel[r.label] then
					radiusIndexByLabel[r.label] = i
				end
			end
			local variants = makeFinder():discoverFoulbornVariants("Might of the Meek", radiusIndexByLabel)
			assert.is_table(variants)
			-- Some data sets include Foulborn items and some do not.
			local hasFoulborn = false
			if data.uniques.generated then
				for _, rawText in ipairs(data.uniques.generated) do
					if type(rawText) == "string" and rawText:match("^Foulborn ") then
						hasFoulborn = true
						break
					end
				end
			end
			if not hasFoulborn then
				assert.are.equal(0, #variants, "expected no Foulborn variants when no Foulborn data exists")
			else
				assert.is_true(#variants > 0, "expected Foulborn variants when Foulborn data exists")
				for _, v in ipairs(variants) do
					assert.is_string(v.name)
					assert.is_string(v.rawText)
					assert.is_true(v.isFoulborn)
					assert.is_number(v.comboIndex)
				end
			end
		end)

	end)

	-- ── computeBestVariantSocketImpact (The Light of Meaning) ────────────────

	describe("computeBestVariantSocketImpact (The Light of Meaning)", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function getLightOfMeaningVariants()
			return makeFinder():buildVariantsFromUniqueItem("The Light of Meaning")
		end

		it("returns one result per socket and uses the best variant", function()
			local sockets = getSockets()
			local variants = getLightOfMeaningVariants()
			local results, baseline = makeFinder():computeBestVariantSocketImpact(sockets, variants, "Life")
			assert.is_true(#results > 0, "expected at least one result")
			assert.is_true(#results <= #sockets, "should return no more than socket count")
			assert.is_number(baseline)
			assert.is_true(baseline > 0)
			for _, r in ipairs(results) do
				assert.is_not_nil(r.socket)
				assert.is_not_nil(r.variant)
				assert.is_string(r.variant.name)
				assert.is_number(r.delta)
			end
		end)

		it("results are sorted by delta descending", function()
			local sockets = getSockets()
			local results, _ = makeFinder():computeBestVariantSocketImpact(sockets, getLightOfMeaningVariants(), "Life")
			assert.is_true(isSorted(results, "delta"),
				"results should be sorted by delta descending")
		end)

		it("Life variant selected on sockets where it is better than others", function()
			local sockets = getSockets()
			local results, _ = makeFinder():computeBestVariantSocketImpact(sockets, getLightOfMeaningVariants(), "Life")
			local hasLife = false
			for _, r in ipairs(results) do
				if r.variant.name == "Life" then hasLife = true; break end
			end
			assert.is_true(hasLife, "expected Life variant to be best for at least one socket")
		end)

		it("restores TotalLife after compute", function()
			local sockets = getSockets()
			local before = build.calcsTab.mainOutput["Life"]
			makeFinder():computeBestVariantSocketImpact(sockets, getLightOfMeaningVariants(), "Life")
			local after = build.calcsTab.mainOutput["Life"]
			assert.are.equal(before, after)
		end)

		it("restores socket and item state after compute", function()
			local sockets = getSockets()
			local before = snapshotFinderState()
			makeFinder():computeBestVariantSocketImpact(sockets, getLightOfMeaningVariants(), "Life")
			assertFinderStateUnchanged(before)
		end)

		it("respects occupiedMode filter", function()
			local sockets = getSockets()
			local results, _ = makeFinder():computeBestVariantSocketImpact(sockets, getLightOfMeaningVariants(), "Life", nil, nil, { id = "all" })
			assert.is_true(#results > 0, "expected results with occupied mode 'all'")
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

		it("returns the current main output as baseline for the selected stat", function()
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

		it("respects max total points for standard compute", function()
			local maxPoints = 2
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life", false, maxPoints)
			for _, r in ipairs(results) do
				assert.is_true((r.socket.pathDist or 0) <= maxPoints,
					"socket " .. r.socket.id .. " used too many points")
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

		it("occupiedMode 'all' includes occupied sockets", function()
			local results, _ = makeFinder():computeSocketImpact(
				getSockets(), MIGHT_OF_MEEK_RAW_TEXT, "Life", false, nil, { id = "all" })
			local occupiedIds = { [36634] = true, [61419] = true, [41263] = true }
			local foundOccupied = false
			for _, r in ipairs(results) do
				if occupiedIds[r.socket.id] then foundOccupied = true; break end
			end
			assert.is_true(foundOccupied,
				"expected at least one occupied socket in results with mode 'all'")
		end)

		it("occupiedMode 'safe' returns at least as many results as 'free'", function()
			local sockets = getSockets()
			local freeResults, _ = makeFinder():computeSocketImpact(
				sockets, MIGHT_OF_MEEK_RAW_TEXT, "Life")
			local safeResults, _ = makeFinder():computeSocketImpact(
				sockets, MIGHT_OF_MEEK_RAW_TEXT, "Life", false, nil, { id = "safe" })
			assert.is_true(#safeResults >= #freeResults,
				"safe mode should include at least all free sockets")
		end)

		it("occupiedMode 'all' returns more results than 'free' (build has occupied sockets)", function()
			local sockets = getSockets()
			local freeResults, _ = makeFinder():computeSocketImpact(
				sockets, MIGHT_OF_MEEK_RAW_TEXT, "Life")
			local allResults, _ = makeFinder():computeSocketImpact(
				sockets, MIGHT_OF_MEEK_RAW_TEXT, "Life", false, nil, { id = "all" })
			assert.is_true(#allResults > #freeResults,
				"all mode should include more sockets than free mode (occupied sockets exist)")
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

	describe("disconnected passive max total points", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		it("respects max total points for Intuitive Leap", function()
			local maxPoints = 4
			local results, _ = makeFinder():computeIntuitiveLeapSocketImpact(
				getSockets(), "Life", false, "simulated_greedy", { }, nil, maxPoints)
			for _, r in ipairs(results) do
				local totalPoints = (r.socket.pathDist or 0) + (r.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. r.socket.id .. " plan used too many points")
			end
		end)

		it("stops at jewel-only when the socket already uses all max points", function()
			local targetSocket
			for _, socket in ipairs(getSockets()) do
				if socket.pathDist and socket.pathDist > 0 then
					targetSocket = socket
					break
				end
			end
			assert.is_not_nil(targetSocket, "expected at least one socket with path points")
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

	describe("computeSplitPersonalitySocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local variants = {
			{ name = "Life", rawText = buildSplitPersonalityRawText("+5 to maximum Life") },
			{ name = "Mana", rawText = buildSplitPersonalityRawText("+5 to maximum Mana") },
		}

		it("returns results and restores socket distance state", function()
			local sockets = getSockets()
			local before = snapshotFinderState()
			local previousDistanceBySocketId = {}
			for _, socket in ipairs(sockets) do
				previousDistanceBySocketId[socket.id] = build.spec.nodes[socket.id] and build.spec.nodes[socket.id].distanceToClassStart
			end

			local results, baseline = makeFinder():computeSplitPersonalitySocketImpact(sockets, "Life", variants)

			assert.is_true(#results > 0, "expected split personality results")
			assert.is_number(baseline)
			for _, result in ipairs(results) do
				assert.is_not_nil(result.variant)
				assert.is_number(result.splitDistance)
				assert.is_string(result.detailText)
			end
			for _, socket in ipairs(sockets) do
				local node = build.spec.nodes[socket.id]
				assert.are.equal(previousDistanceBySocketId[socket.id], node and node.distanceToClassStart)
			end
			assertFinderStateUnchanged(before)
		end)

		it("respects max total points", function()
			local maxPoints = 4
			local results, _ = makeFinder():computeSplitPersonalitySocketImpact(
				getSockets(), "Life", variants, nil, maxPoints)
			for _, result in ipairs(results) do
				local totalPoints = (result.socket.pathDist or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. result.socket.id .. " plan used too many points")
			end
		end)

	end)

	describe("computeImpossibleEscapeSocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		it("returns results for both methods without changing finder state", function()
			local variant = makeImpossibleEscapeTestVariant()
			assert.is_not_nil(variant, "expected at least one keystone-based Impossible Escape variant")
			local sockets = getSockets()
			local before = snapshotFinderState()

			local fastResults, fastBaseline = makeFinder():computeImpossibleEscapeSocketImpact(
				sockets, "Life", { variant }, "fast", { }, nil)
			local simulatedResults, simulatedBaseline = makeFinder():computeImpossibleEscapeSocketImpact(
				sockets, "Life", { variant }, "simulated_greedy", { }, nil)

			assert.is_true(#fastResults > 0, "expected fast Impossible Escape results")
			assert.is_true(#simulatedResults > 0, "expected simulated Impossible Escape results")
			assert.is_number(fastBaseline)
			assert.are.equal(fastBaseline, simulatedBaseline)
			assert.are.equal(variant.name, fastResults[1].variant.name)
			assert.are.equal(variant.name, simulatedResults[1].variant.name)
			assertFinderStateUnchanged(before)
		end)

		it("respects max total points", function()
			local variant = makeImpossibleEscapeTestVariant()
			assert.is_not_nil(variant, "expected at least one keystone-based Impossible Escape variant")
			local maxPoints = 4
			local results, _ = makeFinder():computeImpossibleEscapeSocketImpact(
				getSockets(), "Life", { variant }, "simulated_greedy", { }, nil, maxPoints)
			for _, result in ipairs(results) do
				local totalPoints = (result.socket.pathDist or 0) + (result.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. result.socket.id .. " plan used too many points")
			end
		end)

	end)

	describe("computeThreadOfHopeSocketImpact", function()

		local function getSockets()
			return makeFinder():buildJewelSockets(getLargeRadiusIndex())
		end

		local function getTestVariants()
			local threadVariants = makeThreadVariants()
			return { threadVariants[1], threadVariants[2] or threadVariants[1] }
		end

		local function getTestSockets(threadVariants)
			for _, socket in ipairs(getSockets()) do
				local slot = build.itemsTab.sockets[socket.id]
				local node = build.spec.tree.nodes[socket.id]
				if slot and slot.selItemId == 0 and node and node.nodesInRadius then
					for _, variant in ipairs(threadVariants) do
						local radiusNodes = node.nodesInRadius[variant.radiusIndex]
						if radiusNodes and next(radiusNodes) then
							return { socket }
						end
					end
				end
			end
			return { getSockets()[1] }
		end

		it("returns results for both methods without changing finder state", function()
			local threadVariants = getTestVariants()
			assert.is_true(#threadVariants > 0, "expected Thread of Hope ring variants")
			local sockets = getTestSockets(threadVariants)
			local before = snapshotFinderState()

			local fastResults, fastBaseline = makeFinder():computeThreadOfHopeSocketImpact(
				sockets, "Life", threadVariants, "fast", { }, nil)
			local simulatedResults, simulatedBaseline = makeFinder():computeThreadOfHopeSocketImpact(
				sockets, "Life", threadVariants, "simulated_greedy", { }, nil)

			assert.is_true(#fastResults > 0, "expected fast Thread of Hope results")
			assert.is_true(#simulatedResults > 0, "expected simulated Thread of Hope results")
			assert.is_number(fastBaseline)
			assert.are.equal(fastBaseline, simulatedBaseline)
			assert.is_not_nil(fastResults[1].variant)
			assert.is_not_nil(simulatedResults[1].variant)
			assert.is_number(fastResults[1].variant.radiusIndex)
			assert.is_number(simulatedResults[1].variant.radiusIndex)
			assert.is_string(fastResults[1].detailText)
			assert.is_string(simulatedResults[1].detailText)
			assertFinderStateUnchanged(before)
		end)

		it("respects max total points", function()
			local threadVariants = getTestVariants()
			assert.is_true(#threadVariants > 0, "expected Thread of Hope ring variants")
			local maxPoints = 4
			local results, _ = makeFinder():computeThreadOfHopeSocketImpact(
				getTestSockets(threadVariants), "Life", threadVariants, "simulated_greedy", { }, nil, maxPoints)
			for _, result in ipairs(results) do
				local totalPoints = (result.socket.pathDist or 0) + (result.addedNodeCount or 0)
				assert.is_true(totalPoints <= maxPoints,
					"socket " .. result.socket.id .. " plan used too many points")
			end
		end)

	end)

	-- ── Jewel limit parsing ─────────────────────────────────────────────────

	describe("jewel limit parsing from raw text", function()

		it("parses Limited to: 1 from Impossible Escape raw text", function()
			local rawText = buildImpossibleEscapeRawText("Acrobatics")
			local limitKey = rawText:match("^([^\n]+)")
			local limit = tonumber(rawText:match("Limited to: (%d+)"))
			assert.are.equals("Impossible Escape", limitKey)
			assert.are.equals(1, limit)
		end)

		it("parses Limited to: 1 from Unnatural Instinct raw text", function()
			local limitKey = UNNATURAL_INSTINCT_RAW_TEXT:match("^([^\n]+)")
			local limit = tonumber(UNNATURAL_INSTINCT_RAW_TEXT:match("Limited to: (%d+)"))
			assert.are.equals("Unnatural Instinct", limitKey)
			assert.are.equals(1, limit)
		end)

		it("returns nil limit for jewels without Limited to", function()
			local limit = tonumber(MIGHT_OF_MEEK_RAW_TEXT:match("Limited to: (%d+)"))
			assert.is_nil(limit)
		end)

	end)

	-- ── filterBestPerSocket ────────────────────────────────────────────────

	describe("filterBestPerSocket", function()

		local function makeRow(socketId, score, options)
			options = options or {}
			return {
				socketId = socketId,
				sortPctPerPoint = score,
				isSocketIndependent = options.isSocketIndependent,
				jewelLimitKey = options.jewelLimitKey,
				jewelLimit = options.jewelLimit,
				points = options.points,
				name = options.name or ("row-" .. socketId),
			}
		end

		it("keeps one result per socket, highest score is kept", function()
			local rows = {
				makeRow(1, 10, { name = "A" }),
				makeRow(1, 20, { name = "B" }),
				makeRow(2, 15, { name = "C" }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local ids = {}
			for _, r in ipairs(result) do ids[r.socketId] = r.name end
			assert.are.equal("B", ids[1])
			assert.are.equal("C", ids[2])
		end)

		it("results are sorted by score descending", function()
			local rows = {
				makeRow(1, 5),
				makeRow(2, 30),
				makeRow(3, 15),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(3, #result)
			assert.are.equal(2, result[1].socketId)
			assert.are.equal(3, result[2].socketId)
			assert.are.equal(1, result[3].socketId)
		end)

		it("applies jewelLimit per jewelLimitKey", function()
			local rows = {
				makeRow(1, 30, { jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(2, 20, { jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(3, 10),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local ids = {}
			for _, r in ipairs(result) do ids[r.socketId] = true end
			assert.is_true(ids[1], "best IE should be kept")
			assert.is_true(ids[3], "unlimited jewel should be kept")
			assert.is_nil(ids[2], "second IE should be dropped (limit 1)")
		end)

		it("allows multiple copies up to the limit", function()
			local rows = {
				makeRow(1, 30, { jewelLimitKey = "CF", jewelLimit = 2 }),
				makeRow(2, 20, { jewelLimitKey = "CF", jewelLimit = 2 }),
				makeRow(3, 10, { jewelLimitKey = "CF", jewelLimit = 2 }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			assert.are.equal(1, result[1].socketId)
			assert.are.equal(2, result[2].socketId)
		end)

		it("socket-dependent jewels are assigned before socket-independent", function()
			-- Socket 1: dependent score 10, independent score 20
			-- The dependent should get socket 1, independent goes to socket 2
			local rows = {
				makeRow(1, 10, { name = "dependent" }),
				makeRow(1, 20, { name = "independent", isSocketIndependent = true }),
				makeRow(2, 5,  { name = "independent2", isSocketIndependent = true }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local bySocket = {}
			for _, r in ipairs(result) do bySocket[r.socketId] = r.name end
			-- The independent with score 20 cannot take socket 1 (dependent uses it)
			-- It should go to socket 2 instead
			assert.are.equal("dependent", bySocket[1])
		end)

		it("socket-independent jewels use remaining sockets after dependent allocation", function()
			local rows = {
				makeRow(1, 30, { name = "dependent-1" }),
				makeRow(2, 25, { name = "dependent-2" }),
				makeRow(1, 20, { name = "independent-1", isSocketIndependent = true }),
				makeRow(2, 15, { name = "independent-2", isSocketIndependent = true }),
				makeRow(3, 10, { name = "independent-3", isSocketIndependent = true }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			local bySocket = {}
			for _, r in ipairs(result) do bySocket[r.socketId] = r.name end
			assert.are.equal("dependent-1", bySocket[1])
			assert.are.equal("dependent-2", bySocket[2])
			assert.are.equal("independent-3", bySocket[3])
		end)

		it("socket-independent tie-break uses fewer points", function()
			local rows = {
				makeRow(1, 20, { isSocketIndependent = true, points = 5 }),
				makeRow(2, 20, { isSocketIndependent = true, points = 2 }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			-- Both are kept (different sockets), but fewer points should come first at equal score
			-- Actually both have different sockets so both are included
			-- The tie-break matters when multiple rows can use the same remaining sockets
		end)

		it("socket-independent tie-break: at equal score, fewer points is kept", function()
			-- Two independent jewels can use a single remaining socket
			local rows = {
				makeRow(1, 50, { name = "dependent" }),        -- takes socket 1
				makeRow(1, 20, { name = "ie-high-points", isSocketIndependent = true, points = 8 }),
				makeRow(2, 20, { name = "ie-low-points",  isSocketIndependent = true, points = 2 }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			local bySocket = {}
			for _, r in ipairs(result) do bySocket[r.socketId] = r.name end
			assert.are.equal("dependent", bySocket[1])
			assert.are.equal("ie-low-points", bySocket[2])
		end)

		it("limits are shared between dependent and independent jewels", function()
			-- IE limited to 1: if a dependent row with same limitKey is placed first,
			-- independent rows with that key are blocked
			local rows = {
				makeRow(1, 30, { name = "dependent-ie", jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(2, 20, { name = "independent-ie", isSocketIndependent = true, jewelLimitKey = "IE", jewelLimit = 1 }),
				makeRow(3, 10, { name = "other" }),
			}
			local result = makeFinder():filterBestPerSocket(rows)
			assert.are.equal(2, #result)
			local names = {}
			for _, r in ipairs(result) do names[r.name] = true end
			assert.is_true(names["dependent-ie"])
			assert.is_true(names["other"])
			assert.is_nil(names["independent-ie"], "second IE should be blocked by shared limit")
		end)

		it("returns empty table for empty input", function()
			local result = makeFinder():filterBestPerSocket({})
			assert.are.equal(0, #result)
		end)

		it("does not change the input rows table", function()
			local rows = {
				makeRow(2, 10),
				makeRow(1, 20),
			}
			local originalLen = #rows
			local originalFirst = rows[1]
			makeFinder():filterBestPerSocket(rows)
			assert.are.equal(originalLen, #rows)
			assert.are.equal(originalFirst, rows[1])
		end)

	end)

	-- ── Move-aware compute helpers ─────────────────────────────────────────

	describe("move-aware compute helpers", function()

		local ALLOC_SOCKET_IDS = { 36634, 61419, 41263 }

		local function findUnallocatedSocketId()
			for socketId, socketData in pairs(build.spec.nodes) do
				if socketData.isJewelSocket and socketData.name ~= "Charm Socket"
						and build.itemsTab.sockets[socketId] and not build.spec.allocNodes[socketId] then
					return socketId
				end
			end
			error("expected at least one unallocated jewel socket")
		end

		local function equipFakeJewel(socketId, title, limit, extraItemFields)
			local slot = build.itemsTab.sockets[socketId]
			assert.is_not_nil(slot, "socket " .. socketId .. " should exist")
			local fakeItemId = 999000 + socketId
			local item = { title = title, limit = limit }
			if extraItemFields then
				for k, v in pairs(extraItemFields) do item[k] = v end
			end
			build.itemsTab.items[fakeItemId] = item
			slot.selItemId = fakeItemId
			build.spec.jewels[socketId] = fakeItemId
			return item, fakeItemId
		end

		local function getTestRadiusIndex()
			return getLargeRadiusIndex()
		end

		-- Find a jewel socket whose radius contains at least one unallocated node
		-- with NO allocated linked nodes outside the radius ("isolated").
		-- Note: `linked` is on spec.nodes, not spec.tree.nodes.
		local function findIsolatedRadiusNode(radiusIndex)
			local treeData = build.spec.tree
			for socketId, socketData in pairs(build.spec.nodes) do
				if socketData.isJewelSocket then
					local socketNode = treeData.nodes[socketId]
					if socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[radiusIndex] then
						local radiusNodes = socketNode.nodesInRadius[radiusIndex]
						for nodeId, _ in pairs(radiusNodes) do
							if not build.spec.allocNodes[nodeId] then
								local specNode = build.spec.nodes[nodeId]
								local isolated = true
								if specNode and specNode.linked then
									for _, other in ipairs(specNode.linked) do
										if build.spec.allocNodes[other.id] and not radiusNodes[other.id] then
											isolated = false
											break
										end
									end
								end
								if isolated then
									return socketId, nodeId
								end
							end
						end
					end
				end
			end
		end

		-- Find an unallocated radius node that has at least one linked node
		-- OUTSIDE the radius.  Returns socketId, nodeId, outsideLinkedNodeId.
		-- Note: `linked` is on spec.nodes, not spec.tree.nodes.
		local function findRadiusNodeWithOutsideLinkedNode(radiusIndex)
			local treeData = build.spec.tree
			for socketId, socketData in pairs(build.spec.nodes) do
				if socketData.isJewelSocket then
					local socketNode = treeData.nodes[socketId]
					if socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[radiusIndex] then
						local radiusNodes = socketNode.nodesInRadius[radiusIndex]
						for nodeId, _ in pairs(radiusNodes) do
							if not build.spec.allocNodes[nodeId] then
								local specNode = build.spec.nodes[nodeId]
								if specNode and specNode.linked then
									for _, other in ipairs(specNode.linked) do
										if not radiusNodes[other.id] then
											return socketId, nodeId, other.id
										end
									end
								end
							end
						end
					end
				end
			end
		end

		-- ── findEquippedJewelSockets ────────────────────────────────────

		describe("findEquippedJewelSockets", function()

			it("returns empty when no jewel of that type is equipped", function()
				local result = makeFinder():findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(0, #result)
			end)

			it("ignores jewels stored in unallocated sockets", function()
				local socketId = findUnallocatedSocketId()
				equipFakeJewel(socketId, "Thread of Hope", 1)
				local finder = makeFinder()
				local occupancy = finder:getSocketOccupancyInfo(socketId)
				local allowed = finder:socketMatchesOccupiedMode(socketId, { id = "free" })

				assert.is_false(occupancy.isOccupied)
				assert.are.equal("Thread of Hope", occupancy.storedUnallocatedItemLabel)
				assert.is_true(allowed)
				assert.are.equal(7, finder:getSocketBasePoints({ id = socketId, pathDist = 7 }, occupancy))

				local result = finder:findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(0, #result)
				assert.is_false(result.atLimit)
			end)

			it("returns entry but atLimit=false when equipped jewel has no limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Might of the Meek", nil)
				local result = makeFinder():findEquippedJewelSockets({ name = "Might of the Meek" })
				assert.are.equal(1, #result)
				assert.are.equal(ALLOC_SOCKET_IDS[1], result[1].socketId)
				assert.is_false(result.atLimit)
			end)

			it("returns entries with atLimit=true when limited jewel count reaches limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1)
				local result = makeFinder():findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(1, #result)
				assert.are.equal(ALLOC_SOCKET_IDS[1], result[1].socketId)
				assert.are.equal("Thread of Hope", result[1].item.title)
				assert.is_true(result.atLimit)
			end)

			it("returns entry but atLimit=false when equipped count is below limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Combat Focus", 2)
				local result = makeFinder():findEquippedJewelSockets({ name = "Combat Focus" })
				assert.are.equal(1, #result, "1 equipped < limit 2")
				assert.is_false(result.atLimit)
			end)

			it("returns all entries with atLimit=true when count equals limit", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Combat Focus", 2)
				equipFakeJewel(ALLOC_SOCKET_IDS[2], "Combat Focus", 2)
				local result = makeFinder():findEquippedJewelSockets({ name = "Combat Focus" })
				assert.are.equal(2, #result)
				assert.is_true(result.atLimit)
			end)

			it("does not match jewels with different title", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1)
				local result = makeFinder():findEquippedJewelSockets({ name = "Impossible Escape" })
				assert.are.equal(0, #result)
			end)

		end)

		it("computeSocketImpact treats jewels stored in unallocated sockets as free sockets", function()
			local socketId = findUnallocatedSocketId()
			equipFakeJewel(socketId, "Unnatural Instinct", 1)
			local finder = makeFinder()
			local results = finder:computeSocketImpact({
				{ id = socketId, label = "Test socket", pathDist = 7 },
			}, MIGHT_OF_MEEK_RAW_TEXT, "Life", nil, nil, { id = "free" })

			assert.are.equal(1, #results)
			assert.is_nil(results[1].replacedItemLabel)
			assert.are.equal("Unnatural Instinct", results[1].storedUnallocatedItemLabel)
		end)

		-- ── findDisconnectedPassiveDependentNodes ─────────────────────────────

		describe("findDisconnectedPassiveDependentNodes", function()

			it("returns empty for items without disconnected passive properties", function()
				local result = makeFinder():findDisconnectedPassiveDependentNodes(ALLOC_SOCKET_IDS[1], { title = "Might of the Meek" })
				assert.are.equal(0, #result)
			end)

			it("returns empty for invalid socketId", function()
				local item = { jewelRadiusIndex = getTestRadiusIndex() }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(999999, item)
				assert.are.equal(0, #result)
			end)

			it("returns empty when no nodes are allocated in radius", function()
				local treeData = build.spec.tree
				local smallRI = getTestRadiusIndex()
				local testSocketId
				for socketId, _ in pairs(build.itemsTab.sockets) do
					local node = treeData.nodes[socketId]
					if node and node.nodesInRadius and node.nodesInRadius[smallRI]
							and next(node.nodesInRadius[smallRI]) then
						local hasAllocated = false
						for nodeId, _ in pairs(node.nodesInRadius[smallRI]) do
							if build.spec.allocNodes[nodeId] then
								hasAllocated = true
								break
							end
						end
						if not hasAllocated then
							testSocketId = socketId
							break
						end
					end
				end
				if not testSocketId then pending("no empty radius socket found") end
				local item = { jewelRadiusIndex = smallRI }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(testSocketId, item)
				assert.are.equal(0, #result)
			end)

			it("returns isolated allocated nodes in radius as dependent", function()
				local smallRI = getTestRadiusIndex()
				local testSocketId, testNodeId = findIsolatedRadiusNode(smallRI)
				if not testSocketId then pending("no isolated radius node found") end

				build.spec.allocNodes[testNodeId] = build.spec.tree.nodes[testNodeId]

				local item = { jewelRadiusIndex = smallRI }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(testSocketId, item)

				assert.is_true(#result > 0, "expected at least one dependent node")
				local found = false
				for _, nodeId in ipairs(result) do
					if nodeId == testNodeId then found = true; break end
				end
				assert.is_true(found, "expected node " .. testNodeId .. " in dependent nodes")
			end)

			it("excludes nodes connected from outside the radius", function()
				local treeData = build.spec.tree
				local ri = getTestRadiusIndex()
				local testSocketId, testNodeId, outsideLinkedNodeId = findRadiusNodeWithOutsideLinkedNode(ri)
				if not testSocketId then pending("no radius node with outside linked node found") end

				-- Allocate both the radius node and its outside linked node
				build.spec.allocNodes[testNodeId] = treeData.nodes[testNodeId]
				build.spec.allocNodes[outsideLinkedNodeId] = treeData.nodes[outsideLinkedNodeId]

				local item = { jewelRadiusIndex = ri }
				local result = makeFinder():findDisconnectedPassiveDependentNodes(testSocketId, item)

				local found = false
				for _, nodeId in ipairs(result) do
					if nodeId == testNodeId then found = true; break end
				end
				assert.is_false(found, "node connected from outside radius should not be dependent")
			end)

			it("handles IE keystoneMap path", function()
				local variant = makeImpossibleEscapeTestVariant()
				if not variant then pending("no IE keystone variant found") end

				local item = {
					jewelData = { impossibleEscapeKeystones = { [variant.keystoneName] = true } },
				}
				-- Should return empty since no extra nodes are allocated in the keystone radius
				local result = makeFinder():findDisconnectedPassiveDependentNodes(ALLOC_SOCKET_IDS[1], item)
				assert.is_table(result)
			end)

		end)

		-- ── removeEquippedJewels / restoreEquippedJewels ────────────────

		describe("removeEquippedJewels / restoreEquippedJewels", function()

			it("remove+restore keeps state identical", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1, {
					jewelRadiusIndex = getTestRadiusIndex(),
				})
				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Thread of Hope" })
				assert.are.equal(1, #equippedList)

				local beforeSlotId = build.itemsTab.sockets[ALLOC_SOCKET_IDS[1]].selItemId
				local beforeSpecJewel = build.spec.jewels[ALLOC_SOCKET_IDS[1]]
				local beforeAllocKeys = {}
				for nodeId, _ in pairs(build.spec.allocNodes) do
					beforeAllocKeys[nodeId] = true
				end

				finder:removeEquippedJewels(equippedList)
				finder:restoreEquippedJewels(equippedList)

				assert.are.equal(beforeSlotId, build.itemsTab.sockets[ALLOC_SOCKET_IDS[1]].selItemId)
				assert.are.equal(beforeSpecJewel, build.spec.jewels[ALLOC_SOCKET_IDS[1]])
				for nodeId, _ in pairs(beforeAllocKeys) do
					assert.is_not_nil(build.spec.allocNodes[nodeId],
						"allocNode " .. nodeId .. " should be restored")
				end
			end)

			it("remove clears slot.selItemId and spec.jewels", function()
				equipFakeJewel(ALLOC_SOCKET_IDS[1], "Thread of Hope", 1)
				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Thread of Hope" })

				finder:removeEquippedJewels(equippedList)

				assert.are.equal(0, build.itemsTab.sockets[ALLOC_SOCKET_IDS[1]].selItemId)
				assert.are.equal(0, build.spec.jewels[ALLOC_SOCKET_IDS[1]])

				finder:restoreEquippedJewels(equippedList)
			end)

			it("remove clears dependent disconnected passive nodes from allocNodes", function()
				local smallRI = getTestRadiusIndex()
				local testSocketId, testNodeId = findIsolatedRadiusNode(smallRI)
				if not testSocketId then pending("no isolated radius node found") end

				-- Allocate the isolated node as a disconnected passive jewel would.
				build.spec.allocNodes[testSocketId] = build.spec.tree.nodes[testSocketId]
				build.spec.allocNodes[testNodeId] = build.spec.tree.nodes[testNodeId]

				equipFakeJewel(testSocketId, "Intuitive Leap", 1, {
					jewelRadiusIndex = smallRI,
				})

				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Intuitive Leap" })
				assert.are.equal(1, #equippedList)

				finder:removeEquippedJewels(equippedList)
				assert.is_nil(build.spec.allocNodes[testNodeId],
					"dependent node " .. testNodeId .. " should be removed")

				finder:restoreEquippedJewels(equippedList)
				assert.is_not_nil(build.spec.allocNodes[testNodeId],
					"dependent node " .. testNodeId .. " should be restored")
			end)

			it("remove preserves nodes connected from outside the radius", function()
				local treeData = build.spec.tree
				local ri = getTestRadiusIndex()
				local testSocketId, testNodeId, outsideLinkedNodeId = findRadiusNodeWithOutsideLinkedNode(ri)
				if not testSocketId then pending("no radius node with outside linked node found") end

				build.spec.allocNodes[testSocketId] = treeData.nodes[testSocketId]
				build.spec.allocNodes[testNodeId] = treeData.nodes[testNodeId]
				build.spec.allocNodes[outsideLinkedNodeId] = treeData.nodes[outsideLinkedNodeId]

				equipFakeJewel(testSocketId, "Intuitive Leap", 1, {
					jewelRadiusIndex = ri,
				})

				local finder = makeFinder()
				local equippedList = finder:findEquippedJewelSockets({ name = "Intuitive Leap" })
				assert.are.equal(1, #equippedList)

				finder:removeEquippedJewels(equippedList)
				assert.is_not_nil(build.spec.allocNodes[testNodeId],
					"connected node " .. testNodeId .. " should NOT be removed")

				finder:restoreEquippedJewels(equippedList)
			end)

		end)

	end)

end)
