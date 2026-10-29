-- Path of Building
--
-- Module: Radius Jewel Item Actions
-- Builds and executes guarded item actions for Radius Jewel Finder results.
--
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local t_concat = table.concat

local RadiusJewelItemActions = { }
RadiusJewelItemActions.__index = RadiusJewelItemActions

---@alias RadiusJewelActionKind 'equip'|'move'|'replace'|'equipped'

---@class RadiusJewelActionPlan
---@field kind RadiusJewelActionKind
---@field sourceItemId number?
---@field sourceItemLabel string?
---@field sourceItemStateKey string?
---@field sourceSocketId number?
---@field sourceSocketLabel string?
---@field sourceMatchesTarget boolean
---@field targetSocketId number
---@field targetSocketLabel string
---@field targetSocketAllocated boolean
---@field targetIdentity table
---@field targetCanonicalKey string
---@field targetRawText string
---@field targetItemId number
---@field targetItemStateKey string?
---@field matchingItemsStateKey string
---@field replacedTargetId number?
---@field replacedTargetLabel string?

function RadiusJewelItemActions:new(finder)
	return setmetatable({
		finder = finder,
		build = finder.build,
	}, self)
end

local function sortedNumericKeys(tbl)
	local keys = { }
	for key in pairs(tbl or { }) do
		t_insert(keys, key)
	end
	t_sort(keys, function(a, b)
		if type(a) == type(b) then
			return a < b
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end

-- Variant identity deliberately excludes rolls, quality, item level, and unique ID.
-- It retains every field that selects a canonical unique variant, including Foulborn mods.
local function buildItemCanonicalVariantKey(item)
	if not item then
		return nil
	end
	local parts = {
		item.rarity or "",
		item.title or item.name or "",
		item.baseName or "",
		item.jewelRadiusLabel or "",
		tostring(item.selectedVersion or ""),
		tostring(item.variant or ""),
		tostring(item.variantAlt or ""),
		tostring(item.variantAlt2 or ""),
		tostring(item.variantAlt3 or ""),
		tostring(item.variantAlt4 or ""),
		tostring(item.variantAlt5 or ""),
	}
	for _, groupId in ipairs(sortedNumericKeys(item.variantGroupSelections)) do
		t_insert(parts, "group:" .. tostring(groupId) .. "=" .. tostring(item.variantGroupSelections[groupId]))
	end
	local mutatedModIds = { }
	for _, modLine in ipairs(item.explicitModLines or { }) do
		if modLine.mutated then
			t_insert(mutatedModIds, modLine.modGroup or modLine.modId or modLine.line or "mutated")
		end
	end
	t_sort(mutatedModIds)
	for _, modId in ipairs(mutatedModIds) do
		t_insert(parts, "mutated:" .. modId)
	end
	return t_concat(parts, "\31")
end

local function makeTargetItem(targetRawText)
	local item = new("Item"):Item("Rarity: Unique\n" .. targetRawText)
	item:BuildModList()
	return item
end

local function getItemLabel(item)
	if not item then
		return nil
	end
	local itemName = item.title or item.name or item.baseName or "Unknown item"
	local itemType = item.baseName
	if itemType and itemType ~= "" and itemType ~= itemName then
		return itemName .. " (" .. itemType .. ")"
	end
	return itemName
end

local function getItemStateKey(item)
	if not item then
		return nil
	end
	local rawText = item.BuildRaw and item:BuildRaw() or ""
	return (buildItemCanonicalVariantKey(item) or "") .. "\30" .. rawText
end

function RadiusJewelItemActions:getSocketLabel(slot, socketId)
	local label = slot and slot.label
	if label and label ~= "" then
		return label .. " (" .. tostring(socketId) .. ")"
	end
	return "Jewel socket " .. tostring(socketId)
end

-- Returns the first matching item and location plus an aggregate key for all matches.
function RadiusJewelItemActions:findCanonicalVariantMatch(targetCanonicalKey)
	local itemsTab = self.build.itemsTab
	local socketByItemId = { }
	for _, socketId in ipairs(sortedNumericKeys(itemsTab.sockets)) do
		local itemId = itemsTab.sockets[socketId].selItemId
		if itemId and itemId ~= 0 and not socketByItemId[itemId] then
			socketByItemId[itemId] = socketId
		end
	end

	local firstItem, firstSocket, firstSocketId
	local matchingStates = { }
	for _, itemId in ipairs(itemsTab.itemOrderList) do
		local item = itemsTab.items[itemId]
		if buildItemCanonicalVariantKey(item) == targetCanonicalKey then
			local socketId = socketByItemId[itemId]
			t_insert(matchingStates, table.concat({
				tostring(itemId),
				getItemStateKey(item) or "",
				tostring(socketId or ""),
			}, "\29"))
			if not firstItem then
				firstItem = item
				firstSocketId = socketId
				firstSocket = socketId and itemsTab.sockets[socketId] or nil
			end
		end
	end
	return firstItem, firstSocket, firstSocketId, t_concat(matchingStates, "\28")
end

function RadiusJewelItemActions:findExactStoredSource(targetCanonicalKey, targetSocketId)
	local itemsTab = self.build.itemsTab
	local allocNodes = self.build.spec.allocNodes
	local socketedItemIds = { }
	for _, socketId in ipairs(sortedNumericKeys(itemsTab.sockets)) do
		local slot = itemsTab.sockets[socketId]
		local itemId = slot.selItemId
		if itemId and itemId ~= 0 then
			socketedItemIds[itemId] = true
			if socketId ~= targetSocketId and not allocNodes[socketId] then
				local item = itemsTab.items[itemId]
				if buildItemCanonicalVariantKey(item) == targetCanonicalKey then
					return item, slot, socketId
				end
			end
		end
	end
	for _, itemId in ipairs(itemsTab.itemOrderList) do
		if not socketedItemIds[itemId] then
			local item = itemsTab.items[itemId]
			if buildItemCanonicalVariantKey(item) == targetCanonicalKey then
				return item, nil, nil
			end
		end
	end
	return nil, nil, nil
end

---@param target table
---@return RadiusJewelActionPlan?
function RadiusJewelItemActions:buildPlan(target)
	local targetSocket = self.build.itemsTab.sockets[target.socketId]
	local targetIdentity = target.targetIdentity
	local targetRawText = target.targetRawText
	if not targetSocket or not targetIdentity or not targetRawText then
		return nil
	end

	local targetTemplate = makeTargetItem(targetRawText)
	local targetCanonicalKey = buildItemCanonicalVariantKey(targetTemplate)
	local targetItemId = targetSocket.selItemId or 0
	local targetItem = targetItemId ~= 0 and self.build.itemsTab.items[targetItemId] or nil
	local targetMatches = buildItemCanonicalVariantKey(targetItem) == targetCanonicalKey
	local targetSocketLabel = target.socketLabel or self:getSocketLabel(targetSocket, target.socketId)
	local targetSocketAllocated = self.build.spec.allocNodes[target.socketId] ~= nil
	local _, _, _, matchingItemsStateKey = self:findCanonicalVariantMatch(targetCanonicalKey)
	if targetMatches then
		return {
			kind = "equipped",
			sourceItemId = targetItemId,
			sourceItemLabel = getItemLabel(targetItem),
			sourceItemStateKey = getItemStateKey(targetItem),
			sourceSocketId = target.socketId,
			sourceSocketLabel = targetSocketLabel,
			sourceMatchesTarget = true,
			targetSocketId = target.socketId,
			targetSocketLabel = targetSocketLabel,
			targetSocketAllocated = targetSocketAllocated,
			targetIdentity = targetIdentity,
			targetCanonicalKey = targetCanonicalKey,
			targetRawText = targetRawText,
			targetItemId = targetItemId,
			targetItemStateKey = getItemStateKey(targetItem),
			matchingItemsStateKey = matchingItemsStateKey,
		}
	end

	local sourceItem, sourceSocket, sourceSocketId
	local equipped = self.finder:findEquippedJewelSockets({
		name = targetIdentity.family or targetIdentity.uniqueName,
		variantIdentity = targetIdentity,
	})
	if equipped.atLimit then
		t_sort(equipped, function(a, b)
			local aIsTarget = a.socketId == target.socketId
			local bIsTarget = b.socketId == target.socketId
			if aIsTarget ~= bIsTarget then return aIsTarget end
			local aMatches = buildItemCanonicalVariantKey(a.item) == targetCanonicalKey
			local bMatches = buildItemCanonicalVariantKey(b.item) == targetCanonicalKey
			if aMatches ~= bMatches then return aMatches end
			return a.socketId < b.socketId
		end)
		local source = equipped[1]
		if source then
			sourceItem = source.item
			sourceSocket = source.slot
			sourceSocketId = source.socketId
		end
	else
		local storedItem, storedSocket, storedSocketId = self:findExactStoredSource(targetCanonicalKey, target.socketId)
		if storedItem then
			sourceItem = storedItem
			sourceSocket = storedSocket
			sourceSocketId = storedSocketId
		end
	end

	local sourceMatchesTarget = buildItemCanonicalVariantKey(sourceItem) == targetCanonicalKey
	local kind
	if sourceSocket and sourceSocket ~= targetSocket then
		kind = "move"
	elseif targetItem then
		kind = "replace"
	else
		kind = "equip"
	end
	return {
		kind = kind,
		sourceItemId = sourceItem and sourceItem.id or nil,
		sourceItemLabel = getItemLabel(sourceItem),
		sourceItemStateKey = getItemStateKey(sourceItem),
		sourceSocketId = sourceSocketId,
		sourceSocketLabel = sourceSocketId and self:getSocketLabel(sourceSocket, sourceSocketId) or nil,
		sourceMatchesTarget = sourceMatchesTarget,
		targetSocketId = target.socketId,
		targetSocketLabel = targetSocketLabel,
		targetSocketAllocated = targetSocketAllocated,
		targetIdentity = targetIdentity,
		targetCanonicalKey = targetCanonicalKey,
		targetRawText = targetRawText,
		targetItemId = targetItemId,
		targetItemStateKey = getItemStateKey(targetItem),
		matchingItemsStateKey = matchingItemsStateKey,
		replacedTargetId = targetItemId ~= 0 and targetItemId or nil,
		replacedTargetLabel = getItemLabel(targetItem),
	}
end

function RadiusJewelItemActions:isPlanCurrent(plan)
	local itemsTab = self.build.itemsTab
	local targetSocket = plan and itemsTab.sockets[plan.targetSocketId]
	if not targetSocket or targetSocket.selItemId ~= plan.targetItemId then
		return false
	end
	if (self.build.spec.allocNodes[plan.targetSocketId] ~= nil) ~= plan.targetSocketAllocated then
		return false
	end
	local _, _, _, matchingItemsStateKey = self:findCanonicalVariantMatch(plan.targetCanonicalKey)
	if matchingItemsStateKey ~= plan.matchingItemsStateKey then
		return false
	end
	if plan.targetItemId ~= 0 and getItemStateKey(itemsTab.items[plan.targetItemId]) ~= plan.targetItemStateKey then
		return false
	end
	local sourceSocket = plan.sourceSocketId and itemsTab.sockets[plan.sourceSocketId]
	if plan.sourceSocketId and (not sourceSocket or sourceSocket.selItemId ~= plan.sourceItemId) then
		return false
	end
	if plan.sourceItemId and not plan.sourceSocketId then
		for _, socket in pairs(itemsTab.sockets) do
			if socket.selItemId == plan.sourceItemId then
				return false
			end
		end
	end
	return not plan.sourceItemId or getItemStateKey(itemsTab.items[plan.sourceItemId]) == plan.sourceItemStateKey
end

---@param plan RadiusJewelActionPlan
function RadiusJewelItemActions:executePlan(plan)
	local itemsTab = self.build.itemsTab
	if not self:isPlanCurrent(plan) or plan.kind == "equipped" then
		return false
	end

	local sourceItem = plan.sourceItemId and itemsTab.items[plan.sourceItemId]
	local sourceSocket = plan.sourceSocketId and itemsTab.sockets[plan.sourceSocketId]
	local targetSocket = itemsTab.sockets[plan.targetSocketId]
	local targetItem = plan.sourceMatchesTarget and sourceItem or makeTargetItem(plan.targetRawText)
	local changesVariantInPlace = sourceItem and not plan.sourceMatchesTarget and sourceSocket == targetSocket
	if sourceItem and not plan.sourceMatchesTarget and not changesVariantInPlace then
		targetItem.id = sourceItem.id
	end
	if not targetItem.id or targetItem ~= itemsTab.items[targetItem.id] then
		itemsTab:AddItem(targetItem, true)
	end
	if sourceSocket and sourceSocket ~= targetSocket then
		sourceSocket:SetSelItemId(0)
	end
	targetSocket:SetSelItemId(targetItem.id)
	if changesVariantInPlace then
		-- Keep the final item count stable, but use a new ID so normal Undo restoration
		-- changes the socket selection and rebuilds variant-dependent passive graphs.
		itemsTab:DeleteItem(sourceItem, true)
	end
	itemsTab:PopulateSlots()
	itemsTab:AddUndoState()
	self.build.buildFlag = true
	return true
end

---@param plan RadiusJewelActionPlan
function RadiusJewelItemActions:executeAddToBuildPlan(plan)
	local itemsTab = self.build.itemsTab
	if not self:isPlanCurrent(plan) then
		return false
	end
	local existingItem = self:findCanonicalVariantMatch(plan.targetCanonicalKey)
	if existingItem then
		return false
	end

	itemsTab:AddItem(makeTargetItem(plan.targetRawText), true)
	itemsTab:PopulateSlots()
	itemsTab:AddUndoState()
	self.build.buildFlag = true
	return true
end

return {
	new = function(finder)
		return RadiusJewelItemActions:new(finder)
	end,
}
