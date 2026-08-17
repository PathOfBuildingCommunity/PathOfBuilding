-- Action planning and execution tests for RadiusJewelFinder.

local support = LoadModule("../spec/System/RadiusJewelFinderTestSupport.lua")
local occVortex = support.occVortex
local RadiusJewelData = support.RadiusJewelData

describe("RadiusJewelFinder actions #radius-jewel", function()
	local originalOpenConfirmPopup

	before_each(function()
		originalOpenConfirmPopup = main.OpenConfirmPopup
		loadBuildFromXML(occVortex.xml, "OccVortex")
	end)

	after_each(function()
		main.OpenConfirmPopup = originalOpenConfirmPopup
		while main.popups[1] do
			main:ClosePopup()
		end
	end)

	local function findControlIndex(list, needle)
		for index, entry in ipairs(list) do
			local label = type(entry) == "table" and entry.label or entry
			if label == needle then
				return index
			end
		end
	end

	local function findThreadVariant(name)
		for _, variant in ipairs(RadiusJewelData.getThreadOfHopeVariants()) do
			if variant.name == name then
				return variant
			end
		end
	end

	local function findJewelType(name)
		for _, jewelType in ipairs(RadiusJewelData.buildJewelTypes()) do
			if jewelType.name == name then
				return jewelType
			end
		end
	end

	local function findVariant(jewelType, name)
		for _, variant in ipairs(jewelType.variants or { }) do
			if variant.name == name then
				return variant
			end
		end
	end

	local function allocatedNodeIds()
		local ids = { }
		for nodeId in pairs(build.spec.allocNodes) do
			ids[nodeId] = true
		end
		return ids
	end

	local function assertUndoRestores(before, undoCount)
		assert.are.equal(undoCount + 1, #build.itemsTab.undo)
		build.itemsTab:Undo()
		support.assertFinderStateUnchanged(before, assert)
	end

	local function tooltipText(control)
		local tooltip = new("Tooltip"):Tooltip()
		control.tooltipFunc(tooltip)
		local texts = { }
		for _, line in ipairs(tooltip.lines) do
			if line.text and line.text ~= "" then
				table.insert(texts, line.text)
			end
		end
		return table.concat(texts, "\n")
	end

	local function listText(control)
		local texts = { }
		for _, line in ipairs(control.list) do
			if line[1] and line[1] ~= "" then
				table.insert(texts, line[1])
			end
		end
		return table.concat(texts, "\n")
	end

	local function addJewelToSocket(rawText, socketId)
		local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
		item:BuildModList()
		build.itemsTab:AddItem(item, true)
		build.itemsTab.sockets[socketId]:SetSelItemId(item.id)
		build.itemsTab:PopulateSlots()
		return item
	end

	local function addJewelToItems(rawText)
		local item = new("Item"):Item("Rarity: Unique\n" .. rawText)
		item:BuildModList()
		build.itemsTab:AddItem(item, true)
		return item
	end

	local function openThreadResult(sourceSocketId, targetSocketId, sourceVariant, targetVariant)
		local sourceSlot = build.itemsTab.sockets[sourceSocketId]
		local targetSlot = build.itemsTab.sockets[targetSocketId]
		assert.is_not_nil(sourceSlot)
		assert.is_not_nil(targetSlot)
		sourceSlot:SetSelItemId(0)
		targetSlot:SetSelItemId(0)
		local sourceItem = addJewelToSocket(sourceVariant.rawText, sourceSocketId)
		build.itemsTab:ResetUndo()

		local finder = support.makeFinder()
		finder.buildJewelSockets = function()
			return { { id = targetSocketId, label = "Target socket", pathDist = 0 } }
		end
		finder.computeThreadOfHopeSocketImpact = function(_, sockets)
			return {
				{
					socket = sockets[1],
					variant = targetVariant,
					delta = 10,
					baseOutput = { },
					compareOutput = { },
				},
			}, 100
		end

		local popup = finder:Open()
		local threadIndex = findControlIndex(popup.controls.jewelTypeSelect.list, "Thread of Hope")
		assert.is_not_nil(threadIndex)
		popup.controls.jewelTypeSelect.selFunc(threadIndex)
		popup.controls.computeButton:Click()
		while main.onFrameFuncs["RadiusJewelFinderCompute"] do
			runCallback("OnFrame")
		end
		assert.are.equal(1, #popup.controls.resultsList.list)
		return popup, popup.controls.resultsList.list[1], sourceItem
	end

	local function openStandardResult(jewelType, targetSocketId)
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		build.itemsTab:PopulateSlots()
		build.itemsTab:ResetUndo()
		local finder = support.makeFinder()
		finder.buildJewelSockets = function()
			return { { id = targetSocketId, label = "Free target", pathDist = 0 } }
		end
		finder.computeSocketImpact = function(_, sockets)
			return {
				{
					socket = sockets[1],
					delta = 10,
					baseOutput = { },
					compareOutput = { },
				},
			}, 100
		end
		local popup = finder:Open()
		popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, jewelType.name))
		popup.controls.computeButton:Click()
		while main.onFrameFuncs["RadiusJewelFinderCompute"] do
			runCallback("OnFrame")
		end
		assert.are.equal(1, #popup.controls.resultsList.list)
		return popup, popup.controls.resultsList.list[1]
	end

	local function openVariantResult(jewelType, variant, sourceSocketId, targetSocketId, replacedRawText)
		local sourceSlot = build.itemsTab.sockets[sourceSocketId]
		local targetSlot = build.itemsTab.sockets[targetSocketId]
		sourceSlot:SetSelItemId(0)
		targetSlot:SetSelItemId(0)
		local sourceItem = addJewelToSocket(variant.rawText, sourceSocketId)
		local replacedItem = replacedRawText and addJewelToSocket(replacedRawText, targetSocketId) or nil
		build.itemsTab:ResetUndo()

		local finder = support.makeFinder()
		finder.buildJewelSockets = function()
			return { { id = targetSocketId, label = "Target socket", pathDist = 0 } }
		end
		finder.computeBestVariantSocketImpact = function(_, sockets)
			return {
				{
					socket = sockets[1],
					variant = variant,
					delta = 10,
					baseOutput = { },
					compareOutput = { },
				},
			}, 100
		end

		local popup = finder:Open()
		popup.controls.jewelTypeSelect.selFunc(findControlIndex(popup.controls.jewelTypeSelect.list, jewelType.name))
		popup.controls.jewelVariantSelect.selFunc(findControlIndex(popup.controls.jewelVariantSelect.list, variant.name))
		popup.controls.computeButton:Click()
		while main.onFrameFuncs["RadiusJewelFinderCompute"] do
			runCallback("OnFrame")
		end
		assert.are.equal(1, #popup.controls.resultsList.list)
		assert.is_not_nil(popup.controls.resultsList.list[1].actionPlan,
			popup.controls.statusLabel.label .. ": " .. tostring(popup.controls.resultsList.list[1].text))
		return popup, popup.controls.resultsList.list[1], sourceItem, replacedItem
	end

	it("equips a new jewel in a free socket without allocating recommended passives", function()
		local jewelType = findJewelType("Might of the Meek")
		local targetSocketId = 33631
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		build.itemsTab:PopulateSlots()
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local beforeAllocatedNodes = allocatedNodeIds()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Free target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.are.equal("equip", plan.kind)
		assert.is_nil(plan.sourceItemId)
		assert.are.equal(jewelType.variantIdentity, plan.targetIdentity)
		assert.are.equal(jewelType.rawText, plan.targetRawText)
		assert.is_true(finder:executeActionPlan(plan))
		local equippedId = build.itemsTab.sockets[targetSocketId].selItemId
		assert.is_true(equippedId ~= 0)
		assert.are.equal("Might of the Meek", build.itemsTab.items[equippedId].title)
		assert.are.same(beforeAllocatedNodes, allocatedNodeIds())
		assertUndoRestores(before, undoCount)
	end)

	it("adds a new jewel to the build without changing sockets or passive allocations", function()
		local jewelType = findJewelType("Might of the Meek")
		local targetSocketId = 33631
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		build.itemsTab:PopulateSlots()
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local beforeAllocatedNodes = allocatedNodeIds()
		local undoCount = #build.itemsTab.undo
		local itemCount = #build.itemsTab.itemOrderList
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Free target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.is_false(plan.targetSocketAllocated)
		assert.is_true(finder:executeAddToBuildPlan(plan))
		assert.are.equal(0, build.itemsTab.sockets[targetSocketId].selItemId)
		assert.are.equal(itemCount + 1, #build.itemsTab.itemOrderList)
		local addedItemId = build.itemsTab.itemOrderList[#build.itemsTab.itemOrderList]
		assert.are.equal("Might of the Meek", build.itemsTab.items[addedItemId].title)
		assert.are.same(beforeAllocatedNodes, allocatedNodeIds())
		assertUndoRestores(before, undoCount)
	end)

	it("does not add a duplicate canonical jewel already present in the build", function()
		local jewelType = findJewelType("Might of the Meek")
		local targetSocketId = 33631
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		local existingItem = addJewelToItems(jewelType.rawText)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Free target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.are.equal(existingItem.id, plan.sourceItemId)
		assert.is_false(finder:executeAddToBuildPlan(plan))
		assert.are.equal(undoCount, #build.itemsTab.undo)
		support.assertFinderStateUnchanged(before, assert)
	end)

	it("adds a limited jewel variant without moving the equipped variant", function()
		local jewelType = findJewelType("Unnatural Instinct")
		local normalVariant = findVariant(jewelType, "Normal")
		local foulbornVariant
		for _, variant in ipairs(jewelType.variants) do
			if variant.isFoulborn then
				foulbornVariant = variant
				break
			end
		end
		assert.is_not_nil(foulbornVariant)
		local sourceSocketId = 36634
		local targetSocketId = 61419
		build.itemsTab.sockets[sourceSocketId]:SetSelItemId(0)
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		local sourceItem = addJewelToSocket(normalVariant.rawText, sourceSocketId)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Variant target",
			targetIdentity = foulbornVariant.variantIdentity,
			targetRawText = foulbornVariant.rawText,
		})

		assert.are.equal(sourceItem.id, plan.sourceItemId)
		assert.is_false(plan.sourceMatchesTarget)
		assert.is_true(finder:executeAddToBuildPlan(plan))
		assert.are.equal(sourceItem.id, build.itemsTab.sockets[sourceSocketId].selItemId)
		assert.are.equal(0, build.itemsTab.sockets[targetSocketId].selItemId)
		local addedItemId = build.itemsTab.itemOrderList[#build.itemsTab.itemOrderList]
		assert.is_true(build.itemsTab.items[addedItemId].foulborn)
		assertUndoRestores(before, undoCount)
	end)

	it("offers both actions and explains that an unallocated socket is hidden from Items", function()
		local popup, row = openStandardResult(findJewelType("Might of the Meek"), 33631)

		assert.are.equal("equip", row.actionPlan.kind)
		assert.is_false(row.actionPlan.targetSocketAllocated)
		assert.are.equal("Add to build", popup.controls.addToBuildButton:GetProperty("label"))
		assert.is_true(popup.controls.addToBuildButton.enabled())
		assert.are.equal("Equip", popup.controls.applyButton:GetProperty("label"))
		assert.is_true(popup.controls.applyButton.enabled())
		local addTooltip = tooltipText(popup.controls.addToBuildButton)
		assert.is_true(addTooltip:find("without equipping", 1, true) ~= nil)
		assert.is_true(addTooltip:find("no sockets or passive allocations change", 1, true) ~= nil)
		assert.is_true(addTooltip:find("Recommended socket:", 1, true) ~= nil)
		local equipTooltip = tooltipText(popup.controls.applyButton)
		assert.is_true(equipTooltip:find("This socket is unallocated", 1, true) ~= nil)
		assert.is_true(equipTooltip:find("hidden from the Items panel", 1, true) ~= nil)
		assert.is_true(equipTooltip:find("not applied automatically", 1, true) ~= nil)
		local details = listText(popup.controls.resultDetailList)
		assert.is_true(details:find("This socket is unallocated", 1, true) ~= nil)
		assert.is_true(details:find("hidden from the Items panel", 1, true) ~= nil)
	end)

	it("adds from the result without equipping and then reports the jewel in the build", function()
		local targetSocketId = 33631
		local popup = openStandardResult(findJewelType("Might of the Meek"), targetSocketId)
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo

		popup.controls.addToBuildButton:Click()

		assert.are.equal(0, build.itemsTab.sockets[targetSocketId].selItemId)
		assert.are.equal("In build", popup.controls.addToBuildButton:GetProperty("label"))
		assert.is_false(popup.controls.addToBuildButton.enabled())
		assert.is_false(popup.controls.applyButton.enabled())
		assert.is_true(tooltipText(popup.controls.addToBuildButton):find("already in this build", 1, true) ~= nil)
		assertUndoRestores(before, undoCount)
	end)

	it("requires confirmation before equipping into a socket hidden from Items", function()
		local targetSocketId = 33631
		local popup = openStandardResult(findJewelType("Might of the Meek"), targetSocketId)
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local confirmation
		main.OpenConfirmPopup = function(_, title, message, confirmLabel, onConfirm)
			confirmation = {
				title = title,
				message = message,
				confirmLabel = confirmLabel,
				onConfirm = onConfirm,
			}
		end

		popup.controls.applyButton:Click()

		assert.is_not_nil(confirmation)
		assert.are.equal("Unallocated Jewel Socket", confirmation.title)
		assert.are.equal("Equip", confirmation.confirmLabel)
		assert.is_true(confirmation.message:find("Socket ", 1, true) == 1)
		assert.is_nil(confirmation.message:find("The target ", 1, true))
		assert.is_true(confirmation.message:find("hidden from the Items panel", 1, true) ~= nil)
		assert.is_true(confirmation.message:find("No passive nodes will be allocated", 1, true) ~= nil)
		assert.are.equal(0, build.itemsTab.sockets[targetSocketId].selItemId)
		assert.are.equal(undoCount, #build.itemsTab.undo)

		confirmation.onConfirm()
		assert.is_true(build.itemsTab.sockets[targetSocketId].selItemId ~= 0)
		assertUndoRestores(before, undoCount)
	end)

	it("treats the exact canonical jewel in the target socket as Equipped", function()
		local jewelType = findJewelType("Might of the Meek")
		local targetSocketId = 33631
		local item = addJewelToSocket(jewelType.rawText, targetSocketId)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Exact target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.are.equal("equipped", plan.kind)
		assert.are.equal(item.id, plan.sourceItemId)
		assert.is_false(finder:executeActionPlan(plan))
		assert.are.equal(undoCount, #build.itemsTab.undo)
		support.assertFinderStateUnchanged(before, assert)
	end)

	it("replaces an occupied target and restores its exact item state with Undo", function()
		local jewelType = findJewelType("Might of the Meek")
		local targetSocketId = 36634
		local replacedItemId = build.itemsTab.sockets[targetSocketId].selItemId
		local replacedItem = build.itemsTab.items[replacedItemId]
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Occupied target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.are.equal("replace", plan.kind)
		assert.are.equal(replacedItem.id, plan.replacedTargetId)
		assert.is_true(finder:executeActionPlan(plan))
		assert.is_true(build.itemsTab.sockets[targetSocketId].selItemId ~= replacedItemId)
		assert.are.equal(replacedItem, build.itemsTab.items[replacedItemId])
		assertUndoRestores(before, undoCount)
	end)

	it("classifies a different Thread ring in the same socket as Replace", function()
		local variants = RadiusJewelData.getThreadOfHopeVariants()
		assert.is_true(#variants >= 2)
		local popup, row, sourceItem = openThreadResult(36634, 36634, variants[1], variants[2])
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo

		assert.are.equal("replace", row.action)
		assert.are.equal("Replace", popup.controls.applyButton:GetProperty("label"))
		popup.controls.applyButton:Click()
		local replacementId = build.itemsTab.sockets[36634].selItemId
		assert.is_true(replacementId ~= sourceItem.id)
		assert.are.equal(variants[2].name .. " Ring", build.itemsTab.items[replacementId].variantList[build.itemsTab.items[replacementId].variant])
		assertUndoRestores(before, undoCount)
	end)

	it("shows Equipped and disables the action for an exact Thread ring", function()
		local variant = RadiusJewelData.getThreadOfHopeVariants()[1]
		local popup, row = openThreadResult(36634, 36634, variant, variant)

		assert.are.equal("equipped", row.action)
		assert.are.equal("Equipped", popup.controls.applyButton:GetProperty("label"))
		assert.is_false(popup.controls.applyButton.enabled())
		assert.is_true(tooltipText(popup.controls.applyButton):find("already equipped", 1, true) ~= nil)
	end)

	it("moves the exact limited jewel without duplicating it and records one undo state", function()
		local jewelType = findJewelType("Unnatural Instinct")
		local targetVariant
		for _, variant in ipairs(jewelType.variants) do
			if variant.name == "Normal" then
				targetVariant = variant
				break
			end
		end
		assert.is_not_nil(targetVariant)
		local sourceSocketId = 36634
		local targetSocketId = 61419
		local popup, row, sourceItem = openVariantResult(jewelType, targetVariant, sourceSocketId, targetSocketId)
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo

		assert.are.equal("move", row.action)
		assert.are.equal("Move", popup.controls.applyButton:GetProperty("label"))
		popup.controls.applyButton:Click()

		assert.are.equal(0, build.itemsTab.sockets[sourceSocketId].selItemId)
		assert.are.equal(sourceItem.id, build.itemsTab.sockets[targetSocketId].selItemId)
		assertUndoRestores(before, undoCount)
	end)

	it("moves a limited jewel while preserving an occupied target for Undo", function()
		local jewelType = findJewelType("Unnatural Instinct")
		local variant = findVariant(jewelType, "Normal")
		local sourceSocketId = 36634
		local targetSocketId = 61419
		local popup, row, sourceItem, replacedItem = openVariantResult(
			jewelType, variant, sourceSocketId, targetSocketId, support.MIGHT_OF_MEEK_RAW_TEXT)
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo

		assert.are.equal("move", row.actionPlan.kind)
		assert.are.equal(sourceItem.id, row.actionPlan.sourceItemId)
		assert.are.equal(replacedItem.id, row.actionPlan.replacedTargetId)
		assert.are.equal("Move", popup.controls.applyButton:GetProperty("label"))
		local actionTooltip = tooltipText(popup.controls.applyButton)
		assert.is_true(actionTooltip:find("Source:", 1, true) ~= nil)
		assert.is_true(actionTooltip:find("Replaces:", 1, true) ~= nil)
		assert.is_true(actionTooltip:find("not applied automatically", 1, true) ~= nil)
		local details = listText(popup.controls.resultDetailList)
		assert.is_true(details:find("Socket: Target socket", 1, true) ~= nil)
		assert.is_true(details:find("Source:", 1, true) ~= nil)
		assert.is_true(details:find("Will replace:", 1, true) ~= nil)
		assert.is_true(details:find("not applied automatically", 1, true) ~= nil)

		popup.controls.applyButton:Click()
		assert.are.equal(0, build.itemsTab.sockets[sourceSocketId].selItemId)
		assert.are.equal(sourceItem.id, build.itemsTab.sockets[targetSocketId].selItemId)
		assert.are.equal(replacedItem, build.itemsTab.items[replacedItem.id])
		assertUndoRestores(before, undoCount)
	end)

	it("moves an exact jewel stored in an unallocated socket", function()
		local jewelType = findJewelType("Might of the Meek")
		local sourceSocketId = 33631
		local targetSocketId = 61419
		assert.is_nil(build.spec.allocNodes[sourceSocketId])
		build.itemsTab.sockets[sourceSocketId]:SetSelItemId(0)
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		local sourceItem = addJewelToSocket(jewelType.rawText, sourceSocketId)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Allocated target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.are.equal("move", plan.kind)
		assert.are.equal(sourceSocketId, plan.sourceSocketId)
		assert.are.equal(sourceItem.id, plan.sourceItemId)
		assert.is_true(plan.sourceMatchesTarget)
		assert.is_true(finder:executeActionPlan(plan))
		assert.are.equal(0, build.itemsTab.sockets[sourceSocketId].selItemId)
		assert.are.equal(sourceItem.id, build.itemsTab.sockets[targetSocketId].selItemId)
		assertUndoRestores(before, undoCount)
	end)

	it("restores an unallocated source socket after consecutive Equip and Move actions", function()
		local jewelType = findJewelType("Unnatural Instinct")
		local variant = findVariant(jewelType, "Normal")
		local sourceSocketId = 33631
		local targetSocketId = 54127
		assert.is_nil(build.spec.allocNodes[sourceSocketId])
		assert.is_nil(build.spec.allocNodes[targetSocketId])
		build.itemsTab.sockets[sourceSocketId]:SetSelItemId(0)
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		build.itemsTab:ResetUndo()
		local finder = support.makeFinder()
		local equipPlan = finder:buildActionPlan({
			socketId = sourceSocketId,
			socketLabel = "Unallocated source",
			targetIdentity = variant.variantIdentity,
			targetRawText = variant.rawText,
		})

		assert.are.equal("equip", equipPlan.kind)
		assert.is_true(finder:executeActionPlan(equipPlan))
		local itemId = build.itemsTab.sockets[sourceSocketId].selItemId
		assert.is_true(itemId ~= 0)
		local movePlan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Unallocated destination",
			targetIdentity = variant.variantIdentity,
			targetRawText = variant.rawText,
		})

		assert.are.equal("move", movePlan.kind)
		assert.is_true(finder:executeActionPlan(movePlan))
		assert.are.equal(0, build.itemsTab.sockets[sourceSocketId].selItemId)
		assert.are.equal(itemId, build.itemsTab.sockets[targetSocketId].selItemId)
		assert.are.equal(3, #build.itemsTab.undo)

		build.itemsTab:Undo()
		assert.are.equal(itemId, build.itemsTab.sockets[sourceSocketId].selItemId)
		assert.are.equal(0, build.itemsTab.sockets[targetSocketId].selItemId)
		assert.are.equal(jewelType.name, build.itemsTab.items[itemId].title)
	end)

	it("skips allocated duplicates when an exact jewel is stored in an unallocated socket", function()
		local jewelType = findJewelType("Might of the Meek")
		local allocatedSourceSocketId = 36634
		local storedSourceSocketId = 54127
		local targetSocketId = 61419
		assert.is_not_nil(build.spec.allocNodes[allocatedSourceSocketId])
		assert.is_nil(build.spec.allocNodes[storedSourceSocketId])
		build.itemsTab.sockets[allocatedSourceSocketId]:SetSelItemId(0)
		build.itemsTab.sockets[storedSourceSocketId]:SetSelItemId(0)
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		addJewelToSocket(jewelType.rawText, allocatedSourceSocketId)
		local storedItem = addJewelToSocket(jewelType.rawText, storedSourceSocketId)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Allocated target",
			targetIdentity = jewelType.variantIdentity,
			targetRawText = jewelType.rawText,
		})

		assert.are.equal("move", plan.kind)
		assert.are.equal(storedSourceSocketId, plan.sourceSocketId)
		assert.are.equal(storedItem.id, plan.sourceItemId)
		assert.is_true(finder:executeActionPlan(plan))
		assert.are.equal(0, build.itemsTab.sockets[storedSourceSocketId].selItemId)
		assert.are.equal(storedItem.id, build.itemsTab.sockets[targetSocketId].selItemId)
		assertUndoRestores(before, undoCount)
	end)

	it("invalidates an Items source that is socketed after planning", function()
		local jewelType = findJewelType("Might of the Meek")
		local targetSocketId = 33631
		local relocatedSocketId = 36634
		build.itemsTab.sockets[relocatedSocketId]:SetSelItemId(0)
		local sourceItem = addJewelToItems(jewelType.rawText)
		local popup, row = openStandardResult(jewelType, targetSocketId)

		assert.are.equal(sourceItem.id, row.actionPlan.sourceItemId)
		assert.is_nil(row.actionPlan.sourceSocketId)
		assert.are.equal("In build", popup.controls.addToBuildButton:GetProperty("label"))
		assert.is_false(popup.controls.addToBuildButton.enabled())
		assert.is_true(popup.controls.applyButton.enabled())
		build.itemsTab.sockets[relocatedSocketId]:SetSelItemId(sourceItem.id)
		build.itemsTab:PopulateSlots()
		local afterRelocation = support.snapshotFinderState()

		assert.is_false(popup.controls.applyButton.enabled())
		popup.controls.resultsList.OnSelClick(popup.controls.resultsList, 1, row, true)
		support.assertFinderStateUnchanged(afterRelocation, assert)
	end)

	it("rebuilds passive dependencies for a limited variant change in the same socket", function()
		local jewelType = findJewelType("Unnatural Instinct")
		local normalVariant = findVariant(jewelType, "Normal")
		local foulbornVariant
		for _, variant in ipairs(jewelType.variants) do
			if variant.isFoulborn then
				foulbornVariant = variant
				break
			end
		end
		assert.is_not_nil(foulbornVariant)
		local targetSocketId = 36634
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		local sourceItem = addJewelToSocket(normalVariant.rawText, targetSocketId)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Variant target",
			targetIdentity = foulbornVariant.variantIdentity,
			targetRawText = foulbornVariant.rawText,
		})
		local originalBuildClusterJewelGraphs = build.spec.BuildClusterJewelGraphs
		local graphBuildCount = 0
		build.spec.BuildClusterJewelGraphs = function(spec, ...)
			graphBuildCount = graphBuildCount + 1
			return originalBuildClusterJewelGraphs(spec, ...)
		end

		assert.are.equal("replace", plan.kind)
		assert.are.equal(sourceItem.id, plan.sourceItemId)
		assert.is_false(plan.sourceMatchesTarget)
		assert.is_true(finder:executeActionPlan(plan))
		assert.are.equal(1, graphBuildCount)
		local replacementItemId = build.itemsTab.sockets[targetSocketId].selItemId
		assert.is_true(replacementItemId ~= sourceItem.id)
		assert.is_nil(build.itemsTab.items[sourceItem.id])
		assert.is_true(build.itemsTab.items[replacementItemId].foulborn)
		assert.are.equal(undoCount + 1, #build.itemsTab.undo)

		build.itemsTab:Undo()
		build.spec.BuildClusterJewelGraphs = originalBuildClusterJewelGraphs
		assert.are.equal(2, graphBuildCount)
		support.assertFinderStateUnchanged(before, assert)
	end)

	it("clears a conflicting limited variant before equipping its replacement", function()
		local jewelType = findJewelType("Unnatural Instinct")
		local normalVariant = findVariant(jewelType, "Normal")
		local foulbornVariant
		for _, variant in ipairs(jewelType.variants) do
			if variant.isFoulborn then
				foulbornVariant = variant
				break
			end
		end
		assert.is_not_nil(foulbornVariant)
		local sourceSocketId = 36634
		local targetSocketId = 61419
		build.itemsTab.sockets[sourceSocketId]:SetSelItemId(0)
		build.itemsTab.sockets[targetSocketId]:SetSelItemId(0)
		local sourceItem = addJewelToSocket(normalVariant.rawText, sourceSocketId)
		build.itemsTab:ResetUndo()
		local before = support.snapshotFinderState()
		local undoCount = #build.itemsTab.undo
		local finder = support.makeFinder()
		local plan = finder:buildActionPlan({
			socketId = targetSocketId,
			socketLabel = "Variant target",
			targetIdentity = foulbornVariant.variantIdentity,
			targetRawText = foulbornVariant.rawText,
		})

		assert.are.equal("move", plan.kind)
		assert.are.equal(sourceItem.id, plan.sourceItemId)
		assert.is_false(plan.sourceMatchesTarget)
		assert.is_true(finder:executeActionPlan(plan))
		assert.are.equal(0, build.itemsTab.sockets[sourceSocketId].selItemId)
		local targetItem = build.itemsTab.items[build.itemsTab.sockets[targetSocketId].selItemId]
		assert.is_true(targetItem.foulborn)
		local equipped = finder:findEquippedJewelSockets(jewelType, foulbornVariant)
		assert.are.equal(1, #equipped)
		assertUndoRestores(before, undoCount)
	end)

end)
