-- Popup and interaction tests for RadiusJewelFinder.

local support = LoadModule("../spec/System/RadiusJewelFinderTestSupport.lua")
local occVortex = support.occVortex
local makeFinder = support.makeFinder
local getLargeRadiusIndex = support.getLargeRadiusIndex
describe("RadiusJewelFinder #radius-jewel", function()

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

		it("uses the standard zone labels for sockets without nearby Keystones", function()
			local socketsById = { }
			for _, socket in ipairs(makeFinder():buildJewelSockets(getLargeRadiusIndex())) do
				socketsById[socket.id] = socket
			end
			for socketId, expectedLabel in pairs({ [26725] = "Marauder", [54127] = "Duelist", [7960] = "Templar/Witch" }) do
				assert.matches("^" .. expectedLabel .. " %(" .. socketId .. "%)", socketsById[socketId].label)
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
				local tooltip = new("Tooltip"):Tooltip()
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
				local tooltip = new("Tooltip"):Tooltip()
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
			local finder = makeFinder()
			local popup = finder:Open()
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
			assert.is_false(popup.controls.findButton:IsShown(), "Find should be hidden for All jewels")
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
			assert.is_false(popup.controls.findButton:IsShown(), "Find should stay hidden for All jewels")
			popup.controls.resultsList:SetMode("computeSocketAll", {
				{
					jewelName = "Selected Jewel",
					socketLabel = "Socket #1",
					socketId = 33631,
					points = 1,
					delta = 10,
					pct = 10,
					pctPerPoint = 10,
					sortValue = 10,
					detailText = "Test detail",
					itemTooltipLines = selectedResultPreview,
					action = "new",
				},
			}, "(no compatible sockets)")
			assert.are.equal("^7Selected Jewel", popup.controls.previewList.list[1][1])
			assert.are.equal(180, popup.controls.previewList.height())
			local allJewelsDetailHover = popup.controls.resultsList:GetHoverInfo(7, popup.controls.resultsList.selValue)
			assert.is_true(allJewelsDetailHover.showItemTooltip,
				"All jewels Compute detail column should show jewel preview tooltip")
			local allJewelsSocketHover = popup.controls.resultsList:GetHoverInfo(2, popup.controls.resultsList.selValue)
			assert.is_true(allJewelsSocketHover.showViewer,
				"All jewels Compute socket column should show socket preview")
			popup.controls.resultsList:SetMode("message", { }, "Click Compute")
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
			assert.is_true(popup.controls.jewelVariantSelect.shown, "expected Foulborn variant selector for Intuitive Leap")
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			assert.is_false(popup.controls.findButton:IsShown(),
				"Find should stay hidden while all Intuitive Leap variants are selected")
			local intuitiveVariantLabels = listLabels(popup.controls.jewelVariantSelect.list)
			local foulbornIntuitiveIdx
			for i, label in ipairs(intuitiveVariantLabels) do
				if label:find("Foulborn:", 1, true) then
					foulbornIntuitiveIdx = i
					break
				end
			end
			assert.is_not_nil(foulbornIntuitiveIdx, "expected Foulborn Intuitive Leap variant")
			popup.controls.jewelVariantSelect.selFunc(foulbornIntuitiveIdx)
			assert.is_true(popup.controls.findButton:IsShown(), "Find should be shown for the selected Intuitive Leap variant")
			local findTooltipTexts = buttonTooltipTexts(popup.controls.findButton)
			assert.is_true(#findTooltipTexts > 0, "expected Find tooltip content")
			assert.is_true(findTooltipTexts[1]:find("matching passives", 1, true) ~= nil,
				"expected Find tooltip to explain passive matching")
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Intuitive Leap")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			assert.are.same({ "Free only", "Safe occupied", "All occupied" }, listLabels(popup.controls.occupiedModeSelect.list))
			assert.are.equal("Fast", popup.controls.computeMethodSelect.list[popup.controls.computeMethodSelect.selIndex])

			-- Dreams & Nightmares: variant tooltips
			local normalDreamsIdx = findIndex(popup.controls.jewelTypeSelect.list, "Dreams & Nightmares")
			assert.is_not_nil(normalDreamsIdx, "expected Dreams & Nightmares in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(normalDreamsIdx)
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			assert.are.equal(1, popup.controls.jewelVariantSelect.selIndex)
			assert.is_false(popup.controls.findButton:IsShown(),
				"Find should be hidden while all variants are selected")
			assert.is_true(popup.controls.jewelVariantLabel.y >= 18,
				"expected header labels to sit below the popup title")
			if popup.controls.variantGroupSelect.shown then
				assert.is_true(popup.controls.variantGroupSelect.x < popup.controls.jewelVariantSelect.x,
					"expected Jewel to filter Variant from left to right")
				local redNightmareGroupIdx = findIndex(popup.controls.variantGroupSelect.list, "Red Nightmare")
				assert.is_not_nil(redNightmareGroupIdx, "expected Red Nightmare in jewel filter")
				popup.controls.variantGroupSelect.selFunc(redNightmareGroupIdx)
				local redNightmareGroupLabels = listLabels(popup.controls.jewelVariantSelect.list)
				assert.are.equal("All variants", redNightmareGroupLabels[1])
				for i = 2, #redNightmareGroupLabels do
					assert.is_true(redNightmareGroupLabels[i]:find("Red Nightmare", 1, true) ~= nil,
						"jewel filter should only show Red Nightmare variants: " .. redNightmareGroupLabels[i])
				end
				popup.controls.variantGroupSelect.selFunc(1)
			end
			local redNightmareIdx = findIndex(popup.controls.jewelVariantSelect.list, "The Red Nightmare")
			assert.is_not_nil(redNightmareIdx, "expected The Red Nightmare in variant list")
			local redNightmareTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, redNightmareIdx)
			assert.is_true(#redNightmareTooltipTexts > 0, "expected Red Nightmare tooltip content")
			for _, text in ipairs(redNightmareTooltipTexts) do
				assert.is_nil(text:find("{variant:", 1, true), "variant tooltip should not expose raw variant tags")
				assert.is_nil(text:find("Selected Variant:", 1, true), "variant tooltip should not expose saved-state metadata")
			end
			popup.controls.jewelVariantSelect.selFunc(redNightmareIdx)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should be shown after selecting a specific variant")
			local foulbornRedNightmareIdx
			for i, label in ipairs(listLabels(popup.controls.jewelVariantSelect.list)) do
				if label:find("The Red Nightmare (Foulborn:", 1, true) then
					foulbornRedNightmareIdx = i
					break
				end
			end
			assert.is_not_nil(foulbornRedNightmareIdx, "expected Foulborn Red Nightmare variant")
			popup.controls.jewelVariantSelect.selFunc(foulbornRedNightmareIdx)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should stay shown for the selected Foulborn variant")
			popup.controls.findButton:Click()
			local hasFoulbornResultLabel = false
			for _, row in ipairs(popup.controls.resultsList.list) do
				if row.variantLabel and row.variantLabel:find("Foulborn:", 1, true) then
					hasFoulbornResultLabel = true
					break
				end
			end
			assert.is_true(hasFoulbornResultLabel, "expected Find results to name the selected Foulborn variant")

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
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			local temperedFleshIdx = findIndex(popup.controls.jewelVariantSelect.list, "Tempered Flesh")
			assert.is_not_nil(temperedFleshIdx, "expected Tempered Flesh in variant list")
			local variantTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, temperedFleshIdx)
			assert.is_true(#variantTooltipTexts > 0, "expected jewel variant tooltip content")
			assert.is_true(variantTooltipTexts[1]:find("Tempered Flesh", 1, true) ~= nil,
				"expected variant tooltip to describe the hovered variant")
			local temperedLabels = listLabels(popup.controls.jewelVariantSelect.list)
			assert.is_true(#temperedLabels > 0, "expected Tempered & Transcendent variants")
			for i, label in ipairs(temperedLabels) do
				if i == 1 then
					assert.are.equal("All variants", label)
				else
					assert.is_truthy(label:find("Tempered") or label:find("Transcendent"),
						"variant should be Tempered or Transcendent: " .. label)
				end
			end

			-- Split Personality: unique variant labels
			local splitIdx = findIndex(popup.controls.jewelTypeSelect.list, "Split Personality")
			assert.is_not_nil(splitIdx, "expected Split Personality in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(splitIdx)
			assert.is_true(popup.controls.computeButton.shown, "expected Compute for Split Personality")
			local splitTypeTooltipTexts = tooltipTexts(popup.controls.jewelTypeSelect, splitIdx)
			for _, text in ipairs(splitTypeTooltipTexts) do
				assert.is_nil(text:find("Radius:", 1, true),
					"Split Personality type tooltip should not show a radius line")
			end
			local splitLabels = listLabels(popup.controls.jewelVariantSelect.list)
			assert.is_true(#splitLabels > 0, "expected Split Personality variants")
			assert.are.equal("All variants", splitLabels[1])
			local splitVariantTooltipTexts = tooltipTexts(popup.controls.jewelVariantSelect, 2)
			for _, text in ipairs(splitVariantTooltipTexts) do
				assert.is_nil(text:find("Radius:", 1, true),
					"Split Personality variant tooltip should not show a radius line")
			end
			local seenLabels = {}
			for i, label in ipairs(splitLabels) do
				assert.is_string(label)
				assert.is_true(#label > 0, "variant label should not be empty")
				if i > 1 then
					assert.is_nil(seenLabels[label], "duplicate Split Personality variant: " .. label)
					seenLabels[label] = true
				end
			end

			-- Impossible Escape: compute method + keystone variants
			local impossibleIdx = findIndex(popup.controls.jewelTypeSelect.list, "Impossible Escape")
			assert.is_not_nil(impossibleIdx, "expected Impossible Escape in jewel type list")
			popup.controls.jewelTypeSelect.selFunc(impossibleIdx)
			assert.is_true(popup.controls.computeMethodSelect.shown, "expected method selector for Impossible Escape")
			assert.are.same({ "Fast", "Simulated" }, listLabels(popup.controls.computeMethodSelect.list))
			assert.is_true(#popup.controls.jewelVariantSelect.list > 0, "expected Impossible Escape keystone variants")
			assert.are.equal("All variants", popup.controls.jewelVariantSelect.list[1])
			assert.are.equal(1, popup.controls.jewelVariantSelect.selIndex)
			assert.is_true(popup.controls.findButton:IsShown(),
				"Find should stay shown for Impossible Escape all-variant searches")
			assert.is_true(#popup.controls.jewelVariantSelect.list > 1, "expected at least one selectable keystone variant")

			local capturedVariants
			finder.computeImpossibleEscapeSocketImpact = function(_, _, _, variants)
				capturedVariants = variants
				return { }, 0
			end
			popup.controls.computeButton:Click()
			while main.onFrameFuncs["RadiusJewelFinderCompute"] do
				runCallback("OnFrame")
			end
			assert.is_table(capturedVariants)
			assert.is_true(#capturedVariants > 1, "All variants should compute every Impossible Escape variant")

			local selectedImpossibleEscapeLabel = listLabels(popup.controls.jewelVariantSelect.list)[2]
			popup.controls.jewelVariantSelect.selFunc(2)
			capturedVariants = nil
			popup.controls.computeButton:Click()
			while main.onFrameFuncs["RadiusJewelFinderCompute"] do
				runCallback("OnFrame")
			end
			assert.is_table(capturedVariants)
			assert.are.equal(1, #capturedVariants, "selected Impossible Escape variant should constrain compute")
			assert.are.equal(selectedImpossibleEscapeLabel, capturedVariants[1].dropdownLabel or capturedVariants[1].name)

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

	describe("replacement item tooltip", function()

		it("attaches the replaced jewel to its detail line", function()
			while main.popups[1] do
				main:ClosePopup()
			end
			local popup = makeFinder():Open()
			local socketId = 36634
			local replacedItem = build.itemsTab.items[build.itemsTab.sockets[socketId].selItemId]
			popup.controls.resultsList:SetMode("computeSocket", {
				{
					socketId = socketId,
					socketLabel = "Test socket",
					points = 0,
					delta = 0,
					pct = 0,
					pctPerPoint = 0,
					sortValue = 0,
					detailText = "",
					action = "replace",
					replacedItemLabel = "Existing jewel",
				},
			}, "")

			local replacementLine
			for _, line in ipairs(popup.controls.resultDetailList.list) do
				if line[1] and line[1]:find("Will replace", 1, true) then
					replacementLine = line
					break
				end
			end

			assert.is_not_nil(replacementLine, "expected a replacement detail line")
			assert.are.equal(replacedItem, replacementLine.item)
		end)

	end)

end)
