-- Path of Building
--
-- Class: Radius Jewel Finder
-- Popup for comparing radius unique jewels across passive tree sockets.
-- Supported jewel definitions come from RadiusJewelData.buildJewelTypes().
--
local ipairs = ipairs
local pairs = pairs
local t_insert = table.insert
local t_sort = table.sort
local t_concat = table.concat
local s_format = string.format
local m_huge = math.huge
local m_abs = math.abs

local RadiusJewelData = LoadModule("Classes/RadiusJewelData")
local COL_META = RadiusJewelData.COL_META
local FULL_MASSIVE_RADIUS = RadiusJewelData.FULL_MASSIVE_RADIUS

-- Small output snapshot for stat-comparison tooltips.
-- Copies only scalar fields and the small tables needed by
-- AddStatComparesToTooltip / AddRequirementWarningsToTooltip,
-- skipping heavy sub-tables (SkillDPS, env, modDB, etc.)
-- that would otherwise cause multi-GB memory usage.
local function extractTooltipStats(output)
	if not output then return nil end
	local out = {}
	for k, v in pairs(output) do
		local t = type(v)
		if t == "number" or t == "string" or t == "boolean" then
			out[k] = v
		end
	end
	-- Requirement fail lists (small tables with source references)
	for _, key in ipairs({"ReqStrFailList", "ReqDexFailList", "ReqIntFailList", "ReqOmniFailList",
						   "ReqStrItem", "ReqDexItem", "ReqIntItem", "ReqOmniItem"}) do
		if output[key] then
			out[key] = output[key]
		end
	end
	-- Copy minion stats with the same scalar-only treatment.
	if output.Minion then
		out.Minion = extractTooltipStats(output.Minion)
	end
	return out
end

-- These sockets have no nearby Keystone. Keep the labels used by the Timeless Jewel finder.
local SOCKET_ZONE_NAMES = {
	[26725] = "Marauder",
	[54127] = "Duelist",
	[7960] = "Templar/Witch",
}

---@class RadiusJewelFinder
local RadiusJewelFinderClass = newClass("RadiusJewelFinder")

function RadiusJewelFinderClass:RadiusJewelFinder(treeTab)
	self.treeTab = treeTab
	self.build = treeTab.build
	return self
end

local function normalizeImpactStat(impactStat)
	if type(impactStat) == "string" then
		return {
			field = impactStat,
			label = impactStat,
			selection = { stat = impactStat, label = impactStat },
		}
	elseif impactStat and impactStat.stat and not impactStat.selection then
		return {
			field = impactStat.stat,
			label = impactStat.label,
			selection = impactStat,
		}
	end
	return impactStat
end

function RadiusJewelFinderClass:getImpactValue(impactStat, output)
	impactStat = normalizeImpactStat(impactStat)
	local selection = impactStat.selection or impactStat
	if selection.getValue then
		return selection.getValue(output, self.build)
	end
	local statOutput = output
	if statOutput and statOutput.Minion and selection.stat ~= "FullDPS" then
		statOutput = statOutput.Minion
	end
	local value = statOutput and (statOutput[selection.stat] or 0) or 0
	if selection.transform then
		value = selection.transform(value)
	end
	return value
end

function RadiusJewelFinderClass:calculateImpactDelta(impactStat, baselineOutput, compareOutput)
	impactStat = normalizeImpactStat(impactStat)
	local selection = impactStat.selection or impactStat
	return self.build.calcsTab:CalculatePowerStat(selection, compareOutput, baselineOutput)
end

local function calculateImpactPercent(delta, baseline)
	local baselineMagnitude = m_abs(baseline)
	return baselineMagnitude > 0 and (delta / baselineMagnitude * 100) or 0
end

-- Data module imports
local IMPACT_STATS                  = RadiusJewelData.buildImpactStats()
local DISCONNECTED_PASSIVE_COMPUTE_METHODS = RadiusJewelData.DISCONNECTED_PASSIVE_COMPUTE_METHODS
local OCCUPIED_SOCKET_OPTIONS       = RadiusJewelData.OCCUPIED_SOCKET_OPTIONS
local jewelPreviewFn                = RadiusJewelData.jewelPreviewFn
local scoreAllocPassives            = RadiusJewelData.scoreAllocPassives
local buildJewelTypes               = RadiusJewelData.buildJewelTypes
local jewelTypeSortOrder            = RadiusJewelData.jewelTypeSortOrder
local makeVariantDropdownEntry      = RadiusJewelData.makeVariantDropdownEntry
local findDisconnectedPassiveComputeMethod = RadiusJewelData.findDisconnectedPassiveComputeMethod
local getSplitPersonalityVariants   = RadiusJewelData.getSplitPersonalityVariants
local getImpossibleEscapeVariants   = RadiusJewelData.getImpossibleEscapeVariants
local mustGetUniqueRawText          = RadiusJewelData.mustGetUniqueRawText

-- ─────────────────────────────────────────────────────────────────────────────
-- Build jewel socket list
-- ─────────────────────────────────────────────────────────────────────────────

function RadiusJewelFinderClass:buildJewelSockets(largeRadiusIndex)
	local treeData  = self.build.spec.tree
	local allocNodes = self.build.spec.allocNodes
	local sockets = { }
	for socketId, socketData in pairs(self.build.spec.nodes) do
		if socketData.isJewelSocket and socketData.name ~= "Charm Socket" then
			local keystone = SOCKET_ZONE_NAMES[socketId] or "Unknown"
			local minDist = m_huge
			local socketNode = treeData.nodes[socketId]
			if not SOCKET_ZONE_NAMES[socketId] and socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[largeRadiusIndex] then
				for _, n in pairs(socketNode.nodesInRadius[largeRadiusIndex]) do
					if n.isKeystone then
						local dx = n.x - socketData.x
						local dy = n.y - socketData.y
						local d = dx * dx + dy * dy
						if d < minDist then keystone = n.dn or n.name or "Unknown"; minDist = d end
					end
				end
			end
			local prefix = allocNodes[socketId] and "# " or ""
			local pd = socketData.pathDist or 0
			local classStartDist = self:getSocketDistanceToClassStart(socketId)
			local distStr = (not allocNodes[socketId] and pd < 999) and s_format(" [+%d]", pd) or ""
			local label = prefix .. keystone .. " (" .. socketId .. ")" .. distStr
				t_insert(sockets, { label = label, id = socketId, pathDist = pd, classStartDist = classStartDist })
		end
	end
	t_sort(sockets, function(a, b) return a.label < b.label end)
	return sockets
end

-- Occupancy is the socket's current item state plus whether a preview replace is safe.
function RadiusJewelFinderClass:getSocketOccupancyInfo(socketId)
	local slot = self.build.itemsTab.sockets[socketId]
	local isSocketAllocated = self.build.spec.allocNodes[socketId] ~= nil
	if not slot or slot.selItemId == 0 then
		return {
			slot = slot,
			isSocketAllocated = isSocketAllocated,
			isOccupied = false,
			isSafeReplace = true,
		}
	end
	local item = self.build.itemsTab.items[slot.selItemId]
	local itemName = item and (item.title or item.name or item.baseName) or "Unknown item"
	local itemType = item and item.baseName
	local itemLabel = itemName
	if itemType and itemType ~= "" and itemType ~= itemName then
		itemLabel = itemName .. " (" .. itemType .. ")"
	end
	if not isSocketAllocated then
		return {
			slot = slot,
			item = item,
			itemLabel = itemLabel,
			isSocketAllocated = false,
			isOccupied = false,
			isSafeReplace = true,
			storedUnallocatedItemLabel = itemLabel,
		}
	end
	local isPositionSensitive = false
	if item then
		local jewelData = item.jewelData
		local impossibleEscapeKeystones = jewelData and jewelData.impossibleEscapeKeystones
		isPositionSensitive = item.clusterJewel
			or (jewelData and jewelData.conqueredBy)
			or item.jewelRadiusIndex ~= nil
			or (impossibleEscapeKeystones and next(impossibleEscapeKeystones) ~= nil)
			or (item.title and item.title:match("^Split Personality") ~= nil)
	end
	return {
		slot = slot,
		item = item,
		itemLabel = itemLabel,
		isSocketAllocated = true,
		isOccupied = true,
		isSafeReplace = not isPositionSensitive,
		replacedItemLabel = itemLabel,
	}
end

function RadiusJewelFinderClass:socketMatchesOccupiedMode(socketId, occupiedMode)
	local occupancy = self:getSocketOccupancyInfo(socketId)
	if not occupancy.isOccupied then
		return true, occupancy
	end
	if not occupiedMode or occupiedMode.id == "free" then
		return false, occupancy
	elseif occupiedMode.id == "safe" then
		return occupancy.isSafeReplace, occupancy
	end
	return true, occupancy
end

function RadiusJewelFinderClass:getSocketBasePoints(socket, occupancy)
	local socketId = type(socket) == "table" and socket.id or socket
	occupancy = occupancy or self:getSocketOccupancyInfo(socketId)
	-- Socket base points are the passive points needed to reach an empty socket; occupied sockets are already paid for.
	if occupancy and occupancy.isOccupied then
		return 0
	end
	return type(socket) == "table" and (socket.pathDist or 0) or 0
end

-- Find all sockets where a jewel matching this type is currently equipped.
-- Returns a list of { socketId, slot, itemId, item } entries with an .atLimit flag.
-- .atLimit is true when the jewel has a limit and the number of equipped copies >= that limit.
function RadiusJewelFinderClass:findEquippedJewelSockets(jewelType)
	local equipped = { }
	local limit
	local allocNodes = self.build.spec.allocNodes
	for socketId, slot in pairs(self.build.itemsTab.sockets) do
		if allocNodes[socketId] and slot.selItemId and slot.selItemId ~= 0 then
			local item = self.build.itemsTab.items[slot.selItemId]
			local itemName = item and item.title and item.title:gsub("^[Ff]oulborn ", "")
			if itemName == jewelType.name then
				limit = limit or item.limit
				t_insert(equipped, {
					socketId = socketId,
					slot = slot,
					itemId = slot.selItemId,
					item = item,
				})
			end
		end
	end
	equipped.atLimit = limit ~= nil and #equipped >= limit
	return equipped
end

-- Disconnected-passive jewels allocate passives "without being connected to your tree".
-- Find allocated nodes that depend on Intuitive Leap, Inspired Learning, or Thread of Hope.
-- Returns a list of nodeIds that should be temporarily unallocated.
function RadiusJewelFinderClass:findDisconnectedPassiveDependentNodes(socketId, item)
	local spec = self.build.spec
	local treeData = spec.tree or self.build.tree
	local socketNode = treeData.nodes[socketId]
	if not socketNode then return { } end

	-- Collect all nodes in the jewel's radius
	local radiusNodes = { }
	if item.jewelData and item.jewelData.impossibleEscapeKeystones then
		-- IE: nodes in Small radius around each keystone
		local smallRI
		for i, radius in ipairs(data.jewelRadius) do
			if radius.label == "Small" and radius.inner == 0 then
				smallRI = i
				break
			end
		end
		if smallRI and treeData.keystoneMap then
			for keystoneName, _ in pairs(item.jewelData.impossibleEscapeKeystones) do
				local ksNode = treeData.keystoneMap[keystoneName]
				if ksNode and ksNode.nodesInRadius and ksNode.nodesInRadius[smallRI] then
					for nodeId, node in pairs(ksNode.nodesInRadius[smallRI]) do
						radiusNodes[nodeId] = node
					end
				end
			end
		end
	elseif item.jewelRadiusIndex and socketNode.nodesInRadius then
		-- Inspired Learning / Thread of Hope: nodes in the jewel's radius around the socket
		local nodes = socketNode.nodesInRadius[item.jewelRadiusIndex]
		if nodes then
			for nodeId, node in pairs(nodes) do
				radiusNodes[nodeId] = node
			end
		end
	end

	-- Find allocated nodes in the radius
	local allocInRadius = { }
	for nodeId, _ in pairs(radiusNodes) do
		if spec.allocNodes[nodeId] then
			allocInRadius[nodeId] = true
		end
	end
	if not next(allocInRadius) then return { } end

	-- Search linked allocated nodes away from the radius edge.
	-- Note: spec.nodes has `linked`; treeData.nodes does not.
	local specNodes = spec.nodes
	local connected = { }
	local queue = { }
	for nodeId, _ in pairs(allocInRadius) do
		local node = specNodes[nodeId]
		if node and node.linked then
			for _, other in ipairs(node.linked) do
				if spec.allocNodes[other.id] and not radiusNodes[other.id] then
					connected[nodeId] = true
					t_insert(queue, nodeId)
					break
				end
			end
		end
	end
	-- Continue connectivity within the radius
	local qi = 1
	while qi <= #queue do
		local nodeId = queue[qi]
		qi = qi + 1
		local node = specNodes[nodeId]
		if node and node.linked then
			for _, other in ipairs(node.linked) do
				if allocInRadius[other.id] and not connected[other.id] then
					connected[other.id] = true
					t_insert(queue, other.id)
				end
			end
		end
	end

	-- Nodes in radius that are allocated but NOT connected from outside the radius
	local dependent = { }
	for nodeId, _ in pairs(allocInRadius) do
		if not connected[nodeId] then
			t_insert(dependent, nodeId)
		end
	end
	return dependent
end

function RadiusJewelFinderClass:removeEquippedJewels(equippedList)
	local spec = self.build.spec
	for _, entry in ipairs(equippedList) do
		-- Find disconnected passive dependent nodes before removing the item
		entry.savedAllocNodes = { }
		local dependentNodes = self:findDisconnectedPassiveDependentNodes(entry.socketId, entry.item)
		for _, nodeId in ipairs(dependentNodes) do
			entry.savedAllocNodes[nodeId] = spec.allocNodes[nodeId]
			spec.allocNodes[nodeId] = nil
		end
		-- Remove the jewel from the socket
		entry.savedSelItemId = entry.slot.selItemId
		entry.savedSpecJewel = spec.jewels[entry.socketId]
		entry.slot.selItemId = 0
		spec.jewels[entry.socketId] = 0
	end
	return equippedList
end

function RadiusJewelFinderClass:restoreEquippedJewels(equippedList)
	local spec = self.build.spec
	for _, entry in ipairs(equippedList) do
		if entry.savedSelItemId then
			entry.slot.selItemId = entry.savedSelItemId
			spec.jewels[entry.socketId] = entry.savedSpecJewel
			entry.savedSelItemId = nil
			entry.savedSpecJewel = nil
		end
		if entry.savedAllocNodes then
			for nodeId, node in pairs(entry.savedAllocNodes) do
				spec.allocNodes[nodeId] = node
			end
			entry.savedAllocNodes = nil
		end
	end
end

local function buildNodeLabelList(nodes)
	local labels = { }
	for _, node in ipairs(nodes or { }) do
		if type(node) == "table" then
			t_insert(labels, node.label or node.dn or node.name or tostring(node.id or "?"))
		else
			t_insert(labels, tostring(node))
		end
	end
	return labels
end

-- Attach compute methods and get the UI helper
local buildDisplayedDisconnectedPassivePlans = LoadModule("Classes/RadiusJewelCompute")(RadiusJewelFinderClass, {
	extractTooltipStats = extractTooltipStats,
	normalizeImpactStat = normalizeImpactStat,
	calculateImpactPercent = calculateImpactPercent,
	mustGetUniqueRawText = mustGetUniqueRawText,
	fullMassiveRadius = FULL_MASSIVE_RADIUS,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- Best-per-socket allocation
-- ─────────────────────────────────────────────────────────────────────────────

--- Filter rows to keep at most one result per socket while applying jewel limits
--- and use socket-dependent jewels before socket-independent ones.
---
--- Each row is expected to carry:
---   socketId            (number)   – jewel socket id
---   sortValue           (number)   – sort key (higher = better)
---   isSocketIndependent (boolean?) – true for jewels like IE
---   jewelLimitKey       (string?)  – key for the "Limited to: X" cap
---   jewelLimit          (number?)  – max copies allowed (nil = unlimited)
---   points              (number?)  – total points (tie-break for independent)
function RadiusJewelFinderClass:filterBestPerSocket(rows)
	local sorted = { }
	for _, row in ipairs(rows) do
		t_insert(sorted, row)
	end
	t_sort(sorted, function(a, b)
		return (a.sortValue or 0) > (b.sortValue or 0)
	end)
	local usedSockets = { }
	local limitCounts = { }
	local filtered = { }
	-- Pass 1: assign socket-dependent jewels first (they need specific sockets)
	for _, row in ipairs(sorted) do
		if not row.isSocketIndependent and not usedSockets[row.socketId] then
			local limitKey = row.jewelLimitKey
			local limit = row.jewelLimit
			if not limit or (limitCounts[limitKey] or 0) < limit then
				usedSockets[row.socketId] = true
				if limitKey and limit then
					limitCounts[limitKey] = (limitCounts[limitKey] or 0) + 1
				end
				t_insert(filtered, row)
			end
		end
	end
	-- Pass 2: assign socket-independent jewels (e.g. IE) to remaining sockets, fewer points first
	local independentSorted = { }
	for _, row in ipairs(sorted) do
		if row.isSocketIndependent then
			t_insert(independentSorted, row)
		end
	end
	t_sort(independentSorted, function(a, b)
		local aScore = a.sortValue or 0
		local bScore = b.sortValue or 0
		if aScore ~= bScore then
			return aScore > bScore
		end
		return (a.points or 0) < (b.points or 0)
	end)
	for _, row in ipairs(independentSorted) do
		if not usedSockets[row.socketId] then
			local limitKey = row.jewelLimitKey
			local limit = row.jewelLimit
			if not limit or (limitCounts[limitKey] or 0) < limit then
				usedSockets[row.socketId] = true
				if limitKey and limit then
					limitCounts[limitKey] = (limitCounts[limitKey] or 0) + 1
				end
				t_insert(filtered, row)
			end
		end
	end
	t_sort(filtered, function(a, b)
		return (a.sortValue or 0) > (b.sortValue or 0)
	end)
	return filtered
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Open popup
-- ─────────────────────────────────────────────────────────────────────────────

function RadiusJewelFinderClass:Open()
	local treeData = self.build.spec.tree

	-- Radius index map
	local radiusIndexByLabel = { }
	for i, r in ipairs(data.jewelRadius) do
		if r.inner == 0 and not radiusIndexByLabel[r.label] then
			radiusIndexByLabel[r.label] = i
		end
	end

	-- Thread of Hope ring variants (inner radius > 0)
	local threadVariants = { }
	local threadRawText = mustGetUniqueRawText("Thread of Hope")
	local threadItem = new("Item"):Item("Rarity: Unique\n" .. threadRawText)
	local tIdx = 1
	for i, r in ipairs(data.jewelRadius) do
		if r.inner > 0 then
			local ringName = threadItem.variantList and threadItem.variantList[tIdx]
			if ringName then
				ringName = ringName:gsub(" Ring$", "")
			else
				ringName = "Ring " .. tIdx
			end
			t_insert(threadVariants, { name = ringName, radiusIndex = i })
			tIdx = tIdx + 1
		end
	end

	local LARGE_IDX    = radiusIndexByLabel["Large"]
	local jewelTypes
	local jewelSockets = self:buildJewelSockets(LARGE_IDX)
	local ALL_VARIANT_GROUPS_VALUE = "ALL"

	-- Mutable state
	local showLegacy             = false
	local activeJewelTypes       = { }   -- filtered view of jewelTypes
	local selectedJewelType      = nil   -- set after first filter build
	local selectedThreadVariant  = threadVariants[1]
	local selectedJewelVariant   = nil  -- set when jewel type has built-in variants
	local selectedComputeMethod  = DISCONNECTED_PASSIVE_COMPUTE_METHODS[1]
	local selectedMaxPoints      = 20
	local selectedOccupiedMode   = OCCUPIED_SOCKET_OPTIONS[1]
	local variantGroupOptions    = { { name = "All", value = ALL_VARIANT_GROUPS_VALUE } }
	local selectedVariantGroup   = variantGroupOptions[1]

	local TL       = { "TOPLEFT", nil, "TOPLEFT" }
	local BL       = { "BOTTOMLEFT", nil, "BOTTOMLEFT" }
	local BR       = { "BOTTOMRIGHT", nil, "BOTTOMRIGHT" }
	local edgePadding = 10
	local buttonHeight = 20
	local leftPanelWidth = 580
	local rightPanelWidth = 410
	local popupWidth = edgePadding * 3 + leftPanelWidth + rightPanelWidth
	local popupHeight = 474
	local rightPanelX = edgePadding * 2 + leftPanelWidth
	local headerLabelY = 18
	local headerInputY = 34
	local statusLabelY = 62
	local contentTopY = 78
	local resultListBottomY = 430
	local variantDefaultX = 278
	local variantDefaultWidth = 260
	local variantGroupX = variantDefaultX
	local variantGroupWidth = 150
	local variantFilteredX = variantGroupX + variantGroupWidth + 8
	local variantFilteredWidth = edgePadding + leftPanelWidth - variantFilteredX
	local bottomButtonY = -edgePadding
	local bottomInputY = -(edgePadding + 2)
	local bottomLabelY = -(edgePadding + 4)
	local controls = { }
	local applySelectedResult  -- set below; used by OnSelClick + applyButton

	-- ── Dropdown label lists ──────────────────────────────────────────────────
	-- (jtLabels is built dynamically via rebuildJewelTypeDropdown)
	local jtLabels = { }

	local tvLabels = { }
	for _, tv in ipairs(threadVariants) do t_insert(tvLabels, tv.name .. " Ring") end

	local socketViewer = new("PassiveTreeView"):PassiveTreeView()

	local impactStatLabels = { }
	for _, s in ipairs(IMPACT_STATS) do t_insert(impactStatLabels, s.label) end
	local occupiedModeLabels = { }
	for _, option in ipairs(OCCUPIED_SOCKET_OPTIONS) do t_insert(occupiedModeLabels, option.label) end
	local selectedImpactStat = IMPACT_STATS[1]
	local finderState = self.build.radiusJewelFinderState or { }
	self.build.radiusJewelFinderState = finderState
	finderState.findCache = finderState.findCache or { }
	finderState.computeCache = finderState.computeCache or { }
	finderState.resultViewByKey = finderState.resultViewByKey or { }
	finderState.disconnectedPassivePlanCache = finderState.disconnectedPassivePlanCache or { }
	local ALL_JEWELS_VIEW_OPTIONS = {
		{ id = "all",           label = "All results" },
		{ id = "bestPerSocket", label = "Best per socket" },
	}
	local ALL_VARIANTS_LABEL = "All variants"
	local allJewelsViewLabels = { }
	for _, v in ipairs(ALL_JEWELS_VIEW_OPTIONS) do t_insert(allJewelsViewLabels, v.label) end
	local selectedAllJewelsView = ALL_JEWELS_VIEW_OPTIONS[1]
	local lastComputeAllRows = nil

	local suppressFinderStateSave = false
	local runFind
	local computeContext
	local cancelCompute
	local searchStartTime

	local function formatElapsed(startTime)
		if not startTime then return "" end
		local ms = GetTime() - startTime
		if ms < 1000 then
			return s_format(" ^8(%d ms)", ms)
		end
		return s_format(" ^8(%.1fs)", ms / 1000)
	end

	local function saveFinderState()
		if suppressFinderStateSave then
			return
		end
		finderState.showLegacy = showLegacy
		finderState.jewelTypeName = selectedJewelType and selectedJewelType.name or nil
		finderState.jewelVariantName = selectedJewelVariant and (selectedJewelVariant.dropdownLabel or selectedJewelVariant.name) or nil
		finderState.threadVariantName = selectedThreadVariant and selectedThreadVariant.name or nil
		finderState.variantGroupValue = selectedVariantGroup and selectedVariantGroup.value or nil
		finderState.dreamFamilyValue = nil
		finderState.impactStatLabel = selectedImpactStat and selectedImpactStat.label or nil
		finderState.computeMethodId = selectedComputeMethod and selectedComputeMethod.id or nil
		finderState.maxPoints = selectedMaxPoints
		finderState.occupiedModeId = selectedOccupiedMode and selectedOccupiedMode.id or nil
		finderState.allJewelsViewId = selectedAllJewelsView and selectedAllJewelsView.id or nil
	end

	local function getSelectionKey()
		local supportsComputeMethods = selectedJewelType and selectedJewelType.computeMethods and #selectedJewelType.computeMethods > 0
		local computeMethodKey = supportsComputeMethods and selectedComputeMethod and selectedComputeMethod.id or ""
		return table.concat({
			tostring(showLegacy and 1 or 0),
			selectedJewelType and selectedJewelType.name or "",
			selectedJewelVariant and (selectedJewelVariant.dropdownLabel or selectedJewelVariant.name) or "",
			selectedThreadVariant and selectedThreadVariant.name or "",
			selectedVariantGroup and selectedVariantGroup.value or "",
			selectedImpactStat and selectedImpactStat.field or "",
			computeMethodKey,
			selectedMaxPoints and tostring(selectedMaxPoints) or "",
			selectedOccupiedMode and selectedOccupiedMode.id or "",
		}, "|")
	end

	local function restoreCachedResults()
		local key = getSelectionKey()
		local preferredView = finderState.resultViewByKey[key]
		local allowFindCache = not (selectedJewelType and selectedJewelType.isAllJewels)
		local findCache = allowFindCache and finderState.findCache[key] or nil
		local computeCache = finderState.computeCache[key]
		local cache = preferredView == "compute" and computeCache or findCache
		if not cache and preferredView == "compute" then
			cache = findCache
		elseif not cache and preferredView == "find" then
			cache = computeCache
		end
		if not cache then
			cache = findCache or computeCache
		end
		if not cache then
			return false
		end
		local rows = copyTableSafe(cache.rows, false, true)
		if cache.mode == "computeSocketAll" then
			lastComputeAllRows = rows
			if selectedAllJewelsView.id == "bestPerSocket" then
				rows = self:filterBestPerSocket(rows)
			end
		end
		controls.resultsList:SetMode(cache.mode, rows, cache.defaultText)
		controls.statusLabel.label = cache.statusLabel or controls.statusLabel.label
		return true
	end
	local function saveResultCache(viewName, mode, rows, defaultText, statusLabel, makePreferred)
		local key = getSelectionKey()
		local targetCache = viewName == "compute" and finderState.computeCache or finderState.findCache
		targetCache[key] = {
			mode = mode,
			rows = copyTableSafe(rows, false, true),
			defaultText = defaultText,
			statusLabel = statusLabel,
		}
		if makePreferred then
			finderState.resultViewByKey[key] = viewName
		end
	end
	local function formatComputeStatus(itemLabel, statLabel, baseline, methodLabel)
		if methodLabel and methodLabel ~= "" then
			return s_format("^7%s | %s %.1f | %s | %%/pt", itemLabel, statLabel, baseline, methodLabel)
		end
		return s_format("^7%s | %s %.1f | %%/pt", itemLabel, statLabel, baseline)
	end
	local function formatReplacementLabel(replacedItemLabel)
		return replacedItemLabel and ("Replace " .. replacedItemLabel) or "Free socket"
	end
	local function setComputeProgress(message)
		controls.statusLabel.label = message
		controls.resultsList:SetMode("message", {
			{ text = message },
		}, message)
	end
	cancelCompute = function(statusMessage)
		if not computeContext then
			return
		end
		if computeContext.removedJewels and #computeContext.removedJewels > 0 then
			self:restoreEquippedJewels(computeContext.removedJewels)
		end
		main.onFrameFuncs["RadiusJewelFinderCompute"] = nil
		computeContext = nil
		if controls.computeButton then
			controls.computeButton.label = "Compute"
		end
		if statusMessage then
			controls.statusLabel.label = statusMessage
		end
	end
	local function getSelectedComputeMethods()
		if selectedJewelType and selectedJewelType.isAllJewels then
			return DISCONNECTED_PASSIVE_COMPUTE_METHODS
		end
		if selectedJewelType and selectedJewelType.computeMethods and #selectedJewelType.computeMethods > 0 then
			return selectedJewelType.computeMethods
		end
	end
	local function selectedJewelSupportsComputeMethods()
		local methods = getSelectedComputeMethods()
		return methods and #methods > 0
	end

	local function makeVariantGroupLabel(group)
		return group:gsub("^The%s+", "")
	end

	local function buildVariantGroupOptions(variants)
		local options = { { name = "All", value = ALL_VARIANT_GROUPS_VALUE } }
		local counts = { }
		for _, variant in ipairs(variants or { }) do
			if variant.variantGroup then
				counts[variant.variantGroup] = (counts[variant.variantGroup] or 0) + 1
			end
		end
		for _, variant in ipairs(variants or { }) do
			local group = variant.variantGroup
			if group and counts[group] and counts[group] > 1 then
				counts[group] = nil
				t_insert(options, { name = makeVariantGroupLabel(group), value = group })
			end
		end
		return options
	end

	local function syncVariantGroupSelect()
		variantGroupOptions = buildVariantGroupOptions(selectedJewelType and selectedJewelType.variants)
		local labels = { }
		local selectedIndex = 1
		for i, option in ipairs(variantGroupOptions) do
			t_insert(labels, option.name)
			if selectedVariantGroup and option.value == selectedVariantGroup.value then
				selectedIndex = i
			end
		end
		selectedVariantGroup = variantGroupOptions[selectedIndex]
		if controls.variantGroupSelect then
			controls.variantGroupSelect:SetList(labels)
			controls.variantGroupSelect.selIndex = selectedIndex
		end
		return #variantGroupOptions > 1
	end

	local function hasVariantGroups()
		return #variantGroupOptions > 1
	end

	local function getDisplayedVariants()
		if not selectedJewelType or not selectedJewelType.variants then
			return nil
		end
		if hasVariantGroups() and selectedVariantGroup and selectedVariantGroup.value ~= ALL_VARIANT_GROUPS_VALUE then
			local variants = { }
			for _, variant in ipairs(selectedJewelType.variants) do
				if variant.variantGroup == selectedVariantGroup.value then
					t_insert(variants, variant)
				end
			end
			return variants
		end
		return selectedJewelType.variants
	end

	local function getSelectedVariants()
		local variants = getDisplayedVariants()
		if not variants then
			return nil
		end
		if selectedJewelVariant then
			return { selectedJewelVariant }
		end
		return variants
	end

	local function buildPreviewLinesForJewelType(jewelType, previewVariantOverride)
		if not jewelType then
			return nil
		end
		local fn = jewelPreviewFn[jewelType.name]
		if not fn then
			return nil
		end
		local selectedTypeMatches = selectedJewelType and selectedJewelType.name == jewelType.name
		if jewelType.isThread then
			local threadVariant = previewVariantOverride or selectedThreadVariant
			return fn(threadVariant and threadVariant.name)
		elseif jewelType.variants then
			local previewVariant = previewVariantOverride
			if not previewVariant then
				previewVariant = selectedTypeMatches and selectedJewelVariant or nil
			end
			if not previewVariant and not selectedTypeMatches then
				previewVariant = jewelType.variants[1]
			end
			return fn(previewVariant)
		end
		return fn()
	end

	local function addPreviewLinesToTooltip(tooltip, lines)
		if type(lines) ~= "table" then
			return
		end
		tooltip:Clear(true)
		for _, line in ipairs(lines) do
			tooltip:AddLine(line.height or 16, line[1], line.font)
		end
	end

	local function buildGenericTypeTooltipLinesForJewelType(jewelType)
	if not jewelType then
		return nil
	end
	if not (jewelType.isThread or jewelType.variants) then
		local lines = buildPreviewLinesForJewelType(jewelType)
		if type(lines) ~= "table" then
			return nil
		end
		return lines
	end
	local fn = jewelPreviewFn[jewelType.name]
	local lines = fn and fn() or nil
	if type(lines) ~= "table" then
		return nil
	end

	local genericLines = { }
	local blankCount = 0
	for _, line in ipairs(lines) do
		t_insert(genericLines, line)
		if line[1] == "" then
			blankCount = blankCount + 1
			if blankCount >= 2 then
				break
			end
		end
	end
	local note
	if jewelType.isThread then
		note = "Multiple ring sizes available"
	else
		note = "Multiple variants available"
	end
	t_insert(genericLines, { height = 16, [1] = COL_META .. note })
	return genericLines
end
	local function isAnyFinderDropdownDropped()
		return (controls.jewelTypeSelect and controls.jewelTypeSelect.dropped)
			or (controls.jewelVariantSelect and controls.jewelVariantSelect.dropped)
			or (controls.threadVariantSelect and controls.threadVariantSelect.dropped)
			or (controls.variantGroupSelect and controls.variantGroupSelect.dropped)
			or (controls.allJewelsViewSelect and controls.allJewelsViewSelect.dropped)
			or (controls.impactStatSelect and controls.impactStatSelect.dropped)
			or (controls.occupiedModeSelect and controls.occupiedModeSelect.dropped)
	end

	local function syncDisplayedVariants()
		local variants = getDisplayedVariants()
		if not variants then
			controls.jewelVariantSelect:SetList({ })
			controls.jewelVariantSelect.selIndex = nil
			selectedJewelVariant = nil
			saveFinderState()
			return
		end
		if #variants == 0 then
			controls.jewelVariantSelect:SetList({ })
			controls.jewelVariantSelect.selIndex = nil
			selectedJewelVariant = nil
			saveFinderState()
			return
		end
		local variantNames = { }
		t_insert(variantNames, ALL_VARIANTS_LABEL)
		for _, v in ipairs(variants) do
			t_insert(variantNames, makeVariantDropdownEntry(v))
		end
		controls.jewelVariantSelect:SetList(variantNames)
		local varIdx = 1
		local matchedVariant
		if selectedJewelVariant then
			for i, variant in ipairs(variants) do
				if variant == selectedJewelVariant then
					varIdx = i + 1
					matchedVariant = variant
					break
				end
			end
		else
			varIdx = 1
		end
		if not matchedVariant then
			selectedJewelVariant = nil
		end
		if varIdx > #variantNames then
			varIdx = 1
			selectedJewelVariant = nil
		end
		controls.jewelVariantSelect.selIndex = varIdx
		saveFinderState()
	end

	-- ── Preview list (right panel) ────────────────────────────────────────────
	local previewListData = { }
	local resultDetailListData = { }
	local previewListY = contentTopY
	local previewListHeight = 180
	local compactPreviewListHeight = 48
	local resultDetailBottomY = resultListBottomY
	local resultDetailGap = 6
	local resultDetailLabelGap = 18
	local function getSelectedAllJewelPreviewLines()
		local mode = controls.resultsList and controls.resultsList.mode
		if mode ~= "computeSocketAll" then
			return nil
		end
		local row = controls.resultsList.selValue
		return row and row.itemTooltipLines or nil
	end
	local function isCompactPreview()
		return selectedJewelType and selectedJewelType.isAllJewels and not getSelectedAllJewelPreviewLines()
	end
	local function getPreviewListHeight()
		return isCompactPreview() and compactPreviewListHeight or previewListHeight
	end
	local function getResultDetailLabelY()
		return previewListY + getPreviewListHeight() + resultDetailGap
	end
	local function getResultDetailListY()
		return getResultDetailLabelY() + resultDetailLabelGap
	end
	local function updateResultDetails(row)
		wipeTable(resultDetailListData)
		if not row then
			t_insert(resultDetailListData, { height = 16, [1] = COL_META .. "Select a result to view details." })
			return
		end
		t_insert(resultDetailListData, { height = 16, [1] = "^7Socket: " .. (row.socketLabel or "(n/a)") })
		if row.variantLabel and row.variantLabel ~= "" then
			t_insert(resultDetailListData, { height = 16, [1] = "^7Variant: " .. row.variantLabel })
		end
		local replacementItem
		if row.replacedItemLabel or row.storedUnallocatedItemLabel then
			local occupancy = self:getSocketOccupancyInfo(row.socketId)
			replacementItem = occupancy and occupancy.item
		end
		if row.action == "keep" then
			t_insert(resultDetailListData, { height = 16, [1] = "^8Already equipped" })
		elseif row.action == "moveReplace" then
			t_insert(resultDetailListData, { height = 16, [1] = "^xBB88FFMove equipped jewel" })
			t_insert(resultDetailListData, { height = 16, [1] = "^xFFAA33Will replace: ^7" .. (row.replacedItemLabel or "?"), item = replacementItem })
		elseif row.action == "move" then
			t_insert(resultDetailListData, { height = 16, [1] = "^x33AAFFMove equipped jewel" })
		elseif row.replacedItemLabel then
			t_insert(resultDetailListData, { height = 16, [1] = "^xFFAA33Use occupied socket" })
			t_insert(resultDetailListData, { height = 16, [1] = "^xFFAA33Will replace: ^7" .. row.replacedItemLabel, item = replacementItem })
		elseif row.storedUnallocatedItemLabel then
			t_insert(resultDetailListData, { height = 16, [1] = "^2Use unallocated socket" })
			t_insert(resultDetailListData, { height = 16, [1] = "^8Stored jewel ignored until this socket is allocated." })
			t_insert(resultDetailListData, { height = 16, [1] = "^xFFAA33Apply will replace the stored jewel: ^7" .. row.storedUnallocatedItemLabel, item = replacementItem })
		else
			t_insert(resultDetailListData, { height = 16, [1] = "^2Use free socket" })
		end
		if row.detailText and row.detailText ~= "" then
			t_insert(resultDetailListData, { height = 16, [1] = "^7" .. row.detailText })
		end
		local nodeEntries = row.resultNodes or row.topNodes
		if nodeEntries and #nodeEntries > 0 then
			t_insert(resultDetailListData, { height = 6, [1] = "" })
			t_insert(resultDetailListData, {
				height = 16,
				[1] = row.resultNodes and s_format("^7Passives to allocate (%d):", #nodeEntries)
					or s_format("^7Passives in range (%d):", #nodeEntries),
			})
			for _, nodeEntry in ipairs(nodeEntries) do
				t_insert(resultDetailListData, {
					height = 16,
					[1] = "^xC8C8C8- " .. (nodeEntry.label or tostring(nodeEntry)),
					nodeId = nodeEntry.nodeId,
				})
			end
		else
			t_insert(resultDetailListData, { height = 6, [1] = "" })
			t_insert(resultDetailListData, { height = 16, [1] = row.resultNodes and (COL_META .. "No passives to allocate") or (COL_META .. "No passives in range") })
		end
	end
	controls.previewList = new("TextListControl"):TextListControl(TL, { rightPanelX, previewListY, rightPanelWidth, previewListHeight },
		{ { x = 0, align = "LEFT" }, { x = 210, align = "LEFT" } }, previewListData)
	controls.previewList.height = getPreviewListHeight
	controls.previewList.shown = function()
		return not (controls.jewelTypeSelect and controls.jewelTypeSelect.dropped)
	end
	controls.resultDetailLabel = new("LabelControl"):LabelControl(TL, { rightPanelX, 256, 0, 16 }, "^7Details:")
	controls.resultDetailLabel.y = getResultDetailLabelY
	controls.resultDetailList = new("RadiusJewelDetailListControl"):RadiusJewelDetailListControl(TL, { rightPanelX, 274, rightPanelWidth, 156 },
		{ { x = 0, align = "LEFT" } }, resultDetailListData, self.build, socketViewer)
	controls.resultDetailList.y = getResultDetailListY
	controls.resultDetailList.height = function()
		return resultDetailBottomY - getResultDetailListY()
	end
	updateResultDetails(nil)

	local function addPreviewLines(lines)
		if type(lines) ~= "table" then
			return false
		end
		for _, line in ipairs(lines) do
			t_insert(previewListData, line)
		end
		return #lines > 0
	end

	local function updatePreview(row)
		wipeTable(previewListData)
		if not selectedJewelType then
			t_insert(previewListData, { height = 16, [1] = COL_META .. "(no preview)" })
			return
		end
		if selectedJewelType.isAllJewels then
			local mode = controls.resultsList and controls.resultsList.mode
			if mode == "computeSocketAll" then
				local previewRow = row or controls.resultsList.selValue
				if previewRow and addPreviewLines(previewRow.itemTooltipLines) then
					return
				end
			end
			t_insert(previewListData, { height = 16, [1] = "^7Evaluate every jewel type." })
			if selectedAllJewelsView.id == "bestPerSocket" then
				t_insert(previewListData, { height = 16, [1] = "^7Best jewel per socket." })
			else
				t_insert(previewListData, { height = 16, [1] = "^7Sorted globally by %/Pt." })
			end
			return
		end
		local lines = buildPreviewLinesForJewelType(selectedJewelType)
		if type(lines) ~= "table" then
			t_insert(previewListData, { height = 16, [1] = COL_META .. "(no preview)" })
			return
		end
		addPreviewLines(lines)
	end

		-- ── Results list (left panel) ─────────────────────────────────────────────
		controls.resultsList = new("RadiusJewelResultsListControl"):RadiusJewelResultsListControl(TL, { edgePadding, contentTopY, leftPanelWidth, resultListBottomY - contentTopY }, self.build, socketViewer)
		controls.resultsList.suppressTooltipFunc = isAnyFinderDropdownDropped
		controls.resultsList.OnSelect = function(_, _, row)
			updateResultDetails(row)
			updatePreview(row)
		end
		controls.resultsList.OnSelClick = function(_, index, value, doubleClick)
			if doubleClick then
				applySelectedResult()
			end
		end
		controls.resultsList:SetMode("message", { }, COL_META .. "Click Find to search")

	-- ── Helper: rebuild jewel type dropdown after filter change ──────────────
	local function rebuildJewelTypeDropdown()
		jewelTypes = buildJewelTypes()
		activeJewelTypes = { }
		jtLabels = { }
		for _, jt in ipairs(jewelTypes) do
			if showLegacy or not jt.isLegacy then
				t_insert(activeJewelTypes, jt)
			end
		end
		t_sort(activeJewelTypes, function(a, b)
			if a.name ~= b.name then
				return a.name < b.name
			end
			if a.isLegacy ~= b.isLegacy then
				return a.isLegacy == false
			end
			return false
		end)
		t_insert(activeJewelTypes, 1, {
			name = "All jewels",
			isAllJewels = true,
			hasCompute = true,
		})
		for _, jt in ipairs(activeJewelTypes) do
			t_insert(jtLabels, jt.name)
		end
		if controls.jewelTypeSelect then
			controls.jewelTypeSelect:SetList(jtLabels)
			-- keep current selection if still visible, else reset to first
			local selIdx = 1
				for i, jt in ipairs(activeJewelTypes) do
					if selectedJewelType and jt.name == selectedJewelType.name then selIdx = i; break end
			end
			controls.jewelTypeSelect.selIndex = selIdx
			selectedJewelType = activeJewelTypes[selIdx]

				local hasVariants = selectedJewelType.variants ~= nil
				controls.jewelVariantLabel.shown = hasVariants
				controls.jewelVariantSelect.shown = hasVariants
				if hasVariants then
					syncDisplayedVariants()
				else
					selectedJewelVariant = nil
				end
			saveFinderState()
		else
			-- initial build before controls exist
			selectedJewelType = activeJewelTypes[1]
		end
	end
	rebuildJewelTypeDropdown()  -- initial build (controls.jewelTypeSelect not yet created)

	-- ── Header controls ───────────────────────────────────────────────────────
	controls.jewelTypeLabel = new("LabelControl"):LabelControl(TL, { edgePadding, headerLabelY, 0, 16 }, "^7Type:")

	controls.computeMethodLabel = new("LabelControl"):LabelControl(TL, { rightPanelX, headerLabelY, 0, 16 }, "^7Method:")
	controls.computeMethodSelect = new("DropDownControl"):DropDownControl(TL, { rightPanelX, headerInputY, 160, buttonHeight }, { }, function(idx)
		cancelCompute()
		local methods = getSelectedComputeMethods()
		if methods then
			selectedComputeMethod = methods[idx]
		end
		saveFinderState()
	end)
	local function addComputeMethodTooltip(tooltip, mode, index)
		local methods = getSelectedComputeMethods()
		local method = (index and methods and methods[index]) or selectedComputeMethod
		tooltip:Clear(true)
		if selectedJewelType and selectedJewelType.isAllJewels then
			tooltip:AddLine(16, "^7Used for Intuitive Leap, Thread of Hope, and Impossible Escape.")
		else
			tooltip:AddLine(16, "^7Controls how passives are selected for this jewel.")
		end
		if method and method.id == "simulated_greedy" then
			tooltip:AddLine(16, "^8Simulated recalculates after each chosen passive.")
		else
			tooltip:AddLine(16, "^8Fast scores candidate passives independently.")
		end
	end
	controls.computeMethodLabel.tooltipFunc = addComputeMethodTooltip
	controls.computeMethodSelect.tooltipFunc = addComputeMethodTooltip
	controls.computeMethodLabel.shown = false
	controls.computeMethodSelect.shown = false

	-- Impact stat selector (shown when jewel has compute)
	controls.impactStatLabel = new("LabelControl"):LabelControl(TL, { rightPanelX + 180, headerLabelY, 0, 16 }, "^7Stat:")
	controls.impactStatSelect = new("DropDownControl"):DropDownControl(TL, { rightPanelX + 180, headerInputY, 140, buttonHeight }, impactStatLabels, function(idx)
		cancelCompute()
		selectedImpactStat = IMPACT_STATS[idx]
		saveFinderState()
	end)
	controls.impactStatLabel.shown = true
	controls.impactStatSelect.shown = true

	controls.maxPointsLabel = new("LabelControl"):LabelControl(BL, { edgePadding + 110, bottomLabelY, 0, 16 }, "^7Max pts:")
	controls.maxPointsEdit = new("EditControl"):EditControl(BL, { edgePadding + 172, bottomInputY, 56, buttonHeight }, tostring(selectedMaxPoints), nil, "%D", 3, function(buf)
		cancelCompute()
		selectedMaxPoints = buf ~= "" and tonumber(buf) or nil
		saveFinderState()
	end)
	local function addMaxPointsTooltip(tooltip)
		tooltip:Clear(true)
		tooltip:AddLine(16, "^7Maximum total passive points for a result.")
		tooltip:AddLine(16, "^8Includes pathing to the socket and passives to allocate.")
	end
	controls.maxPointsLabel.tooltipFunc = addMaxPointsTooltip
	controls.maxPointsEdit.tooltipFunc = addMaxPointsTooltip
	controls.maxPointsLabel.shown = true
	controls.maxPointsEdit.shown = true

	controls.occupiedModeLabel = new("LabelControl"):LabelControl(BL, { edgePadding + 240, bottomLabelY, 0, 16 }, "^7Sockets:")
	controls.occupiedModeSelect = new("DropDownControl"):DropDownControl(BL, { edgePadding + 298, bottomInputY, 170, buttonHeight }, occupiedModeLabels, function(idx)
		cancelCompute()
		selectedOccupiedMode = OCCUPIED_SOCKET_OPTIONS[idx]
		saveFinderState()
		runFind(false)
	end)
	local function addOccupiedModeTooltip(tooltip, mode, index)
		local option = (index and OCCUPIED_SOCKET_OPTIONS[index]) or selectedOccupiedMode
		tooltip:Clear(true)
		if not option or option.id == "free" then
			tooltip:AddLine(16, "^7Only try empty jewel sockets.")
		elseif option.id == "safe" then
			tooltip:AddLine(16, "^7Try empty sockets and safe occupied sockets.")
			tooltip:AddLine(16, "^8Safe means the current jewel has no socket-specific behavior.")
		else
			tooltip:AddLine(16, "^7Try empty and occupied jewel sockets.")
			tooltip:AddLine(16, "^8May suggest replacing socket-specific jewels.")
		end
	end
	controls.occupiedModeLabel.tooltipFunc = addOccupiedModeTooltip
	controls.occupiedModeSelect.tooltipFunc = addOccupiedModeTooltip
	controls.occupiedModeLabel.shown = true
	controls.occupiedModeSelect.shown = true

	-- All-jewels view mode selector
	controls.allJewelsViewLabel = new("LabelControl"):LabelControl(TL, { variantDefaultX, headerLabelY, 0, 16 }, "^7View:")
	controls.allJewelsViewSelect = new("DropDownControl"):DropDownControl(TL, { variantDefaultX, headerInputY, 160, 20 }, allJewelsViewLabels, function(idx)
		selectedAllJewelsView = ALL_JEWELS_VIEW_OPTIONS[idx]
		if lastComputeAllRows then
			local displayRows = selectedAllJewelsView.id == "bestPerSocket"
				and self:filterBestPerSocket(lastComputeAllRows) or lastComputeAllRows
			controls.resultsList:SetMode("computeSocketAll", displayRows, COL_META .. "(no compatible sockets)")
		end
		saveFinderState()
	end)
	local function addAllJewelsViewTooltip(tooltip, mode, index)
		local option = (index and ALL_JEWELS_VIEW_OPTIONS[index]) or selectedAllJewelsView
		tooltip:Clear(true)
		if option and option.id == "bestPerSocket" then
			tooltip:AddLine(16, "^7Keep one best result per socket.")
			tooltip:AddLine(16, "^8Jewel limits still apply.")
		else
			tooltip:AddLine(16, "^7Show every compatible result.")
		end
	end
	controls.allJewelsViewLabel.tooltipFunc = addAllJewelsViewTooltip
	controls.allJewelsViewSelect.tooltipFunc = addAllJewelsViewTooltip
	controls.allJewelsViewLabel.shown = false
	controls.allJewelsViewSelect.shown = false

		-- Thread ring selector (shown when Thread of Hope selected)
		controls.threadVariantLabel = new("LabelControl"):LabelControl(TL, { variantDefaultX, headerLabelY, 0, 16 }, "^7Preview ring:")
		controls.threadVariantSelect = new("DropDownControl"):DropDownControl(TL, { variantDefaultX, headerInputY, 200, 20 }, tvLabels, function(idx)
		cancelCompute()
		selectedThreadVariant = threadVariants[idx]
		saveFinderState()
		updatePreview()
		runFind(false)
	end)
		controls.threadVariantLabel.shown = false
		controls.threadVariantSelect.shown = false

		controls.variantGroupLabel = new("LabelControl"):LabelControl(TL, { variantGroupX, headerLabelY, 0, 16 }, "^7Jewel:")
		controls.variantGroupSelect = new("DropDownControl"):DropDownControl(TL, { variantGroupX, headerInputY, variantGroupWidth, 20 }, { "All" }, function(idx)
			cancelCompute()
			selectedVariantGroup = variantGroupOptions[idx] or variantGroupOptions[1]
			controls.jewelVariantSelect.selIndex = 1
			selectedJewelVariant = nil
			syncDisplayedVariants()
			saveFinderState()
			updatePreview()
			runFind(false)
		end)
		controls.variantGroupLabel.shown = false
		controls.variantGroupSelect.shown = false

		-- Jewel variant selector (shown when jewel type has built-in variants)
		controls.jewelVariantLabel = new("LabelControl"):LabelControl(TL, { variantDefaultX, headerLabelY, 0, 16 }, "^7Variant:")
		controls.jewelVariantSelect = new("DropDownControl"):DropDownControl(TL, { variantDefaultX, headerInputY, variantDefaultWidth, 20 }, {}, function(idx)
			cancelCompute()
			local variants = getDisplayedVariants()
			if variants then
				selectedJewelVariant = idx == 1 and nil or variants[idx - 1]
				saveFinderState()
				updatePreview()
				if controls.findButton then
					controls.findButton.shown = not (selectedJewelType and selectedJewelType.variants
						and not selectedJewelVariant and not selectedJewelType.isImpossibleEscape)
				end
			end
		end)
		controls.jewelVariantSelect.enableDroppedWidth = true
		controls.jewelVariantSelect.maxDroppedWidth = 520
		controls.jewelVariantLabel.shown = false
		controls.jewelVariantSelect.shown = false

		local function syncVariantControlLayout(hasVariantGroupFilter)
			if hasVariantGroupFilter then
				controls.jewelVariantLabel.x = variantFilteredX
				controls.jewelVariantSelect.x = variantFilteredX
				controls.jewelVariantSelect.width = variantFilteredWidth
			else
				controls.jewelVariantLabel.x = variantDefaultX
				controls.jewelVariantSelect.x = variantDefaultX
				controls.jewelVariantSelect.width = variantDefaultWidth
			end
		end

		local function syncComputeMethodSelect(methods)
			methods = methods or getSelectedComputeMethods()
			if not methods or #methods == 0 then
				controls.computeMethodSelect:SetList({ })
				controls.computeMethodSelect.selIndex = nil
				return
			end
			local methodLabels = { }
			for _, method in ipairs(methods) do
				t_insert(methodLabels, method.label)
			end
			local selectedIndex = 1
			for i, method in ipairs(methods) do
				if selectedComputeMethod and method.id == selectedComputeMethod.id then
					selectedIndex = i
					break
				end
			end
			selectedComputeMethod = methods[selectedIndex]
			controls.computeMethodSelect:SetList(methodLabels)
			controls.computeMethodSelect.selIndex = selectedIndex
		end

		local function syncSelectedJewelTypeControls()
			if selectedJewelType.isAllJewels then
				controls.allJewelsViewLabel.shown  = true
				controls.allJewelsViewSelect.shown = true
				controls.threadVariantLabel.shown  = false
				controls.threadVariantSelect.shown = false
				controls.variantGroupLabel.shown   = false
				controls.variantGroupSelect.shown  = false
				controls.jewelVariantLabel.shown   = false
				controls.jewelVariantSelect.shown  = false
				controls.computeMethodLabel.shown  = true
				controls.computeMethodSelect.shown = true
				controls.impactStatLabel.shown     = true
				controls.impactStatSelect.shown    = true
				syncComputeMethodSelect(DISCONNECTED_PASSIVE_COMPUTE_METHODS)
				if controls.computeButton then
					controls.computeButton.shown = true
				end
				if controls.findButton then
					controls.findButton.shown = false
				end
				selectedJewelVariant = nil
				return
			end
			controls.allJewelsViewLabel.shown  = false
			controls.allJewelsViewSelect.shown = false
			local isThread = selectedJewelType.isThread == true
			local hasVariants = selectedJewelType.variants ~= nil
			local hasVariantGroupFilter = syncVariantGroupSelect()
			local hasComputeMethods = selectedJewelSupportsComputeMethods()
			syncVariantControlLayout(hasVariantGroupFilter)

			controls.threadVariantLabel.shown  = isThread
			controls.threadVariantSelect.shown = isThread
			controls.variantGroupLabel.shown   = hasVariantGroupFilter
			controls.variantGroupSelect.shown  = hasVariantGroupFilter
			controls.jewelVariantLabel.shown   = hasVariants
			controls.jewelVariantSelect.shown  = hasVariants
			controls.computeMethodLabel.shown  = hasComputeMethods
			controls.computeMethodSelect.shown = hasComputeMethods
			controls.impactStatLabel.shown     = selectedJewelType.hasCompute
			controls.impactStatSelect.shown    = selectedJewelType.hasCompute
			if controls.findButton then
				controls.findButton.shown = true
			end
			if controls.computeButton then
				controls.computeButton.shown = selectedJewelType.hasCompute
			end

			if hasVariants then
				if not hasVariantGroupFilter then
					selectedVariantGroup = variantGroupOptions[1]
					controls.variantGroupSelect.selIndex = 1
				end
				syncDisplayedVariants()
			else
				selectedJewelVariant = nil
			end
			if controls.findButton and hasVariants and not selectedJewelVariant and not selectedJewelType.isImpossibleEscape then
				controls.findButton.shown = false
			end
			if hasComputeMethods then
				syncComputeMethodSelect(selectedJewelType.computeMethods)
			end
	end

	-- Jewel type dropdown (defined after variant controls so :Click() is safe)
	controls.jewelTypeSelect = new("DropDownControl"):DropDownControl(TL, { 10, headerInputY, 260, 20 }, jtLabels, function(idx)
		cancelCompute()
		selectedJewelType = activeJewelTypes[idx]
		controls.jewelVariantSelect.selIndex = 1
		syncSelectedJewelTypeControls()
		saveFinderState()
		updatePreview()
		runFind(false)
	end)
	controls.jewelTypeSelect.tooltipFunc = function(tooltip, mode, index)
		local jewelType = activeJewelTypes[index]
		if jewelType and jewelType.isAllJewels then
			tooltip:Clear(true)
			tooltip:AddLine(16, "^7Evaluate every jewel type at once.")
			tooltip:AddLine(16, "^7Results sorted globally by %/Pt.")
			return
		end
		addPreviewLinesToTooltip(tooltip, buildGenericTypeTooltipLinesForJewelType(jewelType))
	end
	controls.jewelVariantSelect.tooltipFunc = function(tooltip, mode, index)
		local variants = getDisplayedVariants()
		if not selectedJewelType or not variants then
			return
		end
		if not index then
			addPreviewLinesToTooltip(tooltip, buildPreviewLinesForJewelType(selectedJewelType))
			return
		end
		if index == 1 then
			addPreviewLinesToTooltip(tooltip, buildGenericTypeTooltipLinesForJewelType(selectedJewelType))
			tooltip:AddLine(16, "^8Compute compares every displayed variant.")
			return
		end
		local variant = variants[index - 1]
		if variant then
			addPreviewLinesToTooltip(tooltip, buildPreviewLinesForJewelType(selectedJewelType, variant))
		end
	end
	controls.threadVariantSelect.tooltipFunc = function(tooltip, mode, index)
		local variant = threadVariants[index]
		if not selectedJewelType or not variant then
			return
		end
		addPreviewLinesToTooltip(tooltip, buildPreviewLinesForJewelType(selectedJewelType, variant))
	end
	syncSelectedJewelTypeControls()

	-- Compute button: socket sorting with best variant per socket
	-- Results go into the left panel (resultListData); jewel preview is unchanged.
	local function makeComputeProgressTracker()
		local tracker
		local function setFraction(self, fraction, label)
			local nextFraction = math.max(0, math.min(fraction or 0, 1))
			if nextFraction < self.fraction then
				nextFraction = self.fraction
			end
			self.fraction = nextFraction
			local pct = math.floor(nextFraction * 100)
			local text = label and s_format("^7Computing... %d%% | %s", pct, label) or s_format("^7Computing... %d%%", pct)
			setComputeProgress(text)
			local now = GetTime()
			if now - self.lastYield > 50 then
				self.lastYield = now
				coroutine.yield()
			end
		end
		local function makeChild(root, startFraction, spanFraction)
			return {
				root = root,
				startFraction = startFraction or 0,
				spanFraction = spanFraction or 1,
				tick = function(self, done, total, label)
					local localFraction = total and total > 0 and (done / total) or 0
					self.root:setFraction(self.startFraction + localFraction * self.spanFraction, label)
				end,
				child = function(self, childStartFraction, childSpanFraction)
					return makeChild(
						self.root,
						self.startFraction + (childStartFraction or 0) * self.spanFraction,
						(childSpanFraction or 1) * self.spanFraction
					)
				end,
			}
		end
		tracker = {
			lastYield = GetTime(),
			fraction = 0,
			setFraction = setFraction,
			tick = function(self, done, total, label)
				local fraction = total and total > 0 and (done / total) or 0
				self:setFraction(fraction, label)
			end,
			child = function(self, startFraction, spanFraction)
				return makeChild(self, startFraction, spanFraction)
			end,
		}
		return tracker
	end
	local function buildComputeRows(jewelType, socketResults, baseline, equippedList)
		local equippedSocketIds = { }
		local existingSocketId
		for _, entry in ipairs(equippedList or { }) do
			equippedSocketIds[entry.socketId] = true
			if equippedList.atLimit then
				existingSocketId = existingSocketId or entry.socketId
			end
		end
		-- For limited jewels at capacity, find the keep delta so move rows show the net effect
		local keepDelta = 0
		if existingSocketId then
			for _, r in ipairs(socketResults) do
				if equippedSocketIds[r.socket.id] then
					keepDelta = r.delta or 0
					break
				end
			end
		end
		local rows = { }
		for _, r in ipairs(socketResults) do
			local isEquippedSocket = equippedSocketIds[r.socket.id]
			local points = isEquippedSocket and 0
				or self:getSocketBasePoints(r.socket, { isOccupied = r.replacedItemLabel ~= nil })
			local variantLabel = r.variant and (r.variant.dropdownLabel or r.variant.name) or ""
			local itemTooltipLines = buildPreviewLinesForJewelType(jewelType, r.variant)
			local applyRawText = r.variant and r.variant.rawText or jewelType.rawText
			local jewelLimitKey = applyRawText and applyRawText:match("^([^\n]+)") or jewelType.name
			jewelLimitKey = jewelLimitKey:gsub("^[Ff]oulborn ", "")
			local jewelLimit = jewelType.limit or (applyRawText and tonumber(applyRawText:match("Limited to: (%d+)"))) or nil
			local displayedPlans = (jewelType.name == "Intuitive Leap" or jewelType.isThread or jewelType.isImpossibleEscape)
				and buildDisplayedDisconnectedPassivePlans(r, points, baseline)
				or { r }
			for _, plan in ipairs(displayedPlans) do
				local displayDelta = plan.delta
				if existingSocketId and not isEquippedSocket then
					displayDelta = plan.delta - keepDelta
				end
				local pct = calculateImpactPercent(displayDelta, baseline)
				local totalPoints = points + (plan.addedNodeCount or 0)
				local summaryParts = { }
				if variantLabel ~= "" then
					t_insert(summaryParts, variantLabel)
				end
				if plan.resultNodeLabels and #plan.resultNodeLabels > 0 then
					t_insert(summaryParts, s_format("%d node%s", #plan.resultNodeLabels, #plan.resultNodeLabels == 1 and "" or "s"))
				elseif (not plan.detailText or plan.detailText == "") and variantLabel == "" then
					local rIdx = jewelType.radiusIndex
					local socketNode = plan.socket and treeData.nodes[plan.socket.id]
					local radiusNodes = rIdx and socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[rIdx]
					if radiusNodes then
						local matchCount = 0
						for _, n in pairs(radiusNodes) do
							if not n.ascendancyName and (n.type == "Notable" or n.type == "Keystone") then
								matchCount = matchCount + 1
							end
						end
						if matchCount > 0 then
							t_insert(summaryParts, s_format("%d match%s", matchCount, matchCount == 1 and "" or "es"))
						end
					end
				end
				local detailText = #summaryParts > 0 and t_concat(summaryParts, " | ") or (plan.detailText or "")
				local detailNodeId = nil
				if jewelType.isImpossibleEscape and r.variant and r.variant.keystoneName then
					local keystoneNode = treeData.keystoneMap[r.variant.keystoneName]
					detailNodeId = keystoneNode and keystoneNode.id or nil
				end
				local action
				if isEquippedSocket then
					action = "keep"
				elseif existingSocketId and r.replacedItemLabel then
					action = "moveReplace"
				elseif existingSocketId then
					action = "move"
				elseif r.replacedItemLabel then
					action = "replace"
				else
					action = "new"
				end
				t_insert(rows, {
					socketLabel = r.socket.label,
					socketId = r.socket.id,
					points = totalPoints,
					delta = displayDelta,
					pct = pct,
					pctPerPoint = totalPoints > 0 and (pct / totalPoints) or pct,
					sortValue = totalPoints > 0 and (pct / totalPoints) or pct,
					detailText = detailText,
					detailNodeId = detailNodeId,
					resultNodes = plan.resultNodes,
					resultNodeLabels = plan.resultNodeLabels,
					replacedItemLabel = r.replacedItemLabel,
					storedUnallocatedItemLabel = r.storedUnallocatedItemLabel,
					itemTooltipLines = itemTooltipLines,
					baseOutput = plan.baseOutput,
					compareOutput = plan.compareOutput,
					jewelName = jewelType.name,
					jewelLimitKey = jewelLimitKey,
					jewelLimit = jewelLimit,
					isSocketIndependent = jewelType.isSocketIndependent,
					applyRawText = applyRawText,
					action = action,
					tooltipHeader = jewelType.isThread and "^7Socketing this jewel and allocating the best ring plan here will give you:"
						or jewelType.name == "Intuitive Leap" and "^7Socketing this jewel and allocating the best nodes here will give you:"
						or jewelType.isImpossibleEscape and "^7Socketing this jewel and allocating the best keystone plan here will give you:"
						or variantLabel ~= "" and "^7Socketing the best variant here will give you:"
						or "^7Socketing this jewel will give you:",
				})
			end
		end
		return rows
	end

	controls.computeButton = new("ButtonControl"):ButtonControl(TL, { popupWidth - edgePadding * 2 - 72, headerInputY, 72, buttonHeight }, "Compute", function()
		if computeContext then
			cancelCompute("^8Compute stopped")
			restoreCachedResults()
			return
		end

		controls.computeButton.label = "Cancel"
		searchStartTime = GetTime()
		setComputeProgress("^7Computing...")
		local progress = makeComputeProgressTracker()
		computeContext = {
			co = coroutine.create(function()
				local ok, err = pcall(function()
			local statLabel = selectedImpactStat.label
			local computeMethod = selectedComputeMethod or findDisconnectedPassiveComputeMethod(nil)
			local computeMethodLabel = selectedJewelSupportsComputeMethods() and computeMethod.label or nil

			if selectedJewelType.isAllJewels then
				local allRows = { }
				local globalBaseline

				local computeJewelTypes = { }
				for _, jt in ipairs(activeJewelTypes) do
					if not jt.isAllJewels and jt.hasCompute then
						t_insert(computeJewelTypes, jt)
					end
				end

				for typeIndex, jt in ipairs(computeJewelTypes) do
					local rawChild = progress:child(
						(typeIndex - 1) / #computeJewelTypes,
						1 / #computeJewelTypes)
					local jtName = jt.name
					local function wrapProgress(base)
						return {
							tick = function(self, done, total, label)
								base:tick(done, total, label and (jtName .. " | " .. label) or jtName)
							end,
							child = function(self, startFraction, spanFraction)
								return wrapProgress(base:child(startFraction, spanFraction))
							end,
						}
					end
					local typeProgress = wrapProgress(rawChild)
					local equippedList = self:findEquippedJewelSockets(jt)
					local removedJewels = equippedList.atLimit and self:removeEquippedJewels(equippedList) or { }
					computeContext.removedJewels = removedJewels
					local socketResults, baseline

					if jt.name == "Intuitive Leap" then
						socketResults, baseline =
							self:computeBestIntuitiveLeapSocketImpact(jewelSockets, selectedImpactStat, jt.variants,
								computeMethod.id, finderState.disconnectedPassivePlanCache, typeProgress, selectedMaxPoints, selectedOccupiedMode, true)
					elseif jt.isThread then
						socketResults, baseline =
							self:computeThreadOfHopeSocketImpact(jewelSockets, selectedImpactStat, threadVariants,
								computeMethod.id, finderState.disconnectedPassivePlanCache, typeProgress, selectedMaxPoints, selectedOccupiedMode, true)
					elseif jt.isImpossibleEscape then
						socketResults, baseline =
							self:computeImpossibleEscapeSocketImpact(jewelSockets, selectedImpactStat,
								jt.variants or getImpossibleEscapeVariants(),
								computeMethod.id, finderState.disconnectedPassivePlanCache, typeProgress, selectedMaxPoints, selectedOccupiedMode, true)
					elseif jt.isSplitPersonality then
						socketResults, baseline =
							self:computeSplitPersonalitySocketImpact(jewelSockets, selectedImpactStat,
								jt.variants or getSplitPersonalityVariants(),
								typeProgress, selectedMaxPoints, selectedOccupiedMode)
					elseif jt.variants and #jt.variants > 0 then
						socketResults, baseline =
							self:computeBestVariantSocketImpact(jewelSockets, jt.variants, selectedImpactStat,
								typeProgress, selectedMaxPoints, selectedOccupiedMode)
					else
						socketResults, baseline =
							self:computeSocketImpact(jewelSockets, jt.rawText, selectedImpactStat,
								typeProgress, selectedMaxPoints, selectedOccupiedMode)
					end

					globalBaseline = globalBaseline or baseline
					self:restoreEquippedJewels(removedJewels)
					computeContext.removedJewels = nil

					local typeRows = buildComputeRows(jt, socketResults, baseline, equippedList)

					-- For disconnected-passive types: keep only the best row per socket
					if jt.name == "Intuitive Leap" or jt.isThread or jt.isImpossibleEscape then
						local bestBySocket = { }
						for _, row in ipairs(typeRows) do
							local ex = bestBySocket[row.socketId]
							if not ex or row.sortValue > ex.sortValue then
								bestBySocket[row.socketId] = row
							end
						end
						typeRows = { }
						for _, row in pairs(bestBySocket) do
							t_insert(typeRows, row)
						end
					end

					for _, row in ipairs(typeRows) do
						t_insert(allRows, row)
					end
				end

				globalBaseline = globalBaseline or 0
				lastComputeAllRows = allRows
				local displayRows = selectedAllJewelsView.id == "bestPerSocket"
					and self:filterBestPerSocket(allRows) or allRows
				controls.resultsList:SetMode("computeSocketAll", displayRows, COL_META .. "(no compatible sockets)")
				controls.statusLabel.label = formatComputeStatus("All jewels", statLabel, globalBaseline, computeMethodLabel) .. formatElapsed(searchStartTime)
				saveResultCache("compute", "computeSocketAll", allRows, COL_META .. "(no compatible sockets)", controls.statusLabel.label, true)
			else
					local displayedVariants = getSelectedVariants()
					local itemLabel = selectedJewelType.name
					local equippedList = self:findEquippedJewelSockets(selectedJewelType)
					local removedJewels = equippedList.atLimit and self:removeEquippedJewels(equippedList) or { }
					computeContext.removedJewels = removedJewels
					local socketResults, baseline
					if selectedJewelType.name == "Intuitive Leap" then
						socketResults, baseline =
							self:computeBestIntuitiveLeapSocketImpact(jewelSockets, selectedImpactStat, displayedVariants, computeMethod.id,
								finderState.disconnectedPassivePlanCache, progress, selectedMaxPoints, selectedOccupiedMode)
					elseif selectedJewelType.isThread then
						socketResults, baseline =
							self:computeThreadOfHopeSocketImpact(jewelSockets, selectedImpactStat, threadVariants, computeMethod.id, finderState.disconnectedPassivePlanCache, progress, selectedMaxPoints, selectedOccupiedMode)
					elseif selectedJewelType.isImpossibleEscape then
						socketResults, baseline =
							self:computeImpossibleEscapeSocketImpact(jewelSockets, selectedImpactStat, displayedVariants or getImpossibleEscapeVariants(), computeMethod.id, finderState.disconnectedPassivePlanCache, progress, selectedMaxPoints, selectedOccupiedMode)
					elseif selectedJewelType.isSplitPersonality then
						socketResults, baseline =
							self:computeSplitPersonalitySocketImpact(jewelSockets, selectedImpactStat, displayedVariants or getSplitPersonalityVariants(), progress, selectedMaxPoints, selectedOccupiedMode)
					elseif displayedVariants and #displayedVariants > 0 then
						if hasVariantGroups() and selectedVariantGroup and selectedVariantGroup.value ~= ALL_VARIANT_GROUPS_VALUE then
							itemLabel = selectedVariantGroup.name
						end
						socketResults, baseline =
							self:computeBestVariantSocketImpact(jewelSockets, displayedVariants, selectedImpactStat, progress, selectedMaxPoints, selectedOccupiedMode)
					else
						local rawText = selectedJewelType.rawText
						socketResults, baseline =
							self:computeSocketImpact(jewelSockets, rawText, selectedImpactStat, progress, selectedMaxPoints, selectedOccupiedMode)
					end
					self:restoreEquippedJewels(removedJewels)
					computeContext.removedJewels = nil
					local rows = buildComputeRows(selectedJewelType, socketResults, baseline, equippedList)
					controls.resultsList:SetMode("computeSocket", rows, COL_META .. "(no compatible sockets)")
					controls.statusLabel.label = formatComputeStatus(itemLabel, statLabel, baseline, computeMethodLabel) .. formatElapsed(searchStartTime)
					saveResultCache("compute", "computeSocket", rows, COL_META .. "(no compatible sockets)", controls.statusLabel.label, true)
			end
				end)
				if not ok then
					error(err)
				end
			end),
		}
		main.onFrameFuncs["RadiusJewelFinderCompute"] = function()
			if not computeContext then
				main.onFrameFuncs["RadiusJewelFinderCompute"] = nil
				return
			end
			local res, errMsg = coroutine.resume(computeContext.co)
			if not res then
				cancelCompute()
				controls.statusLabel.label = "^1Error: " .. tostring(errMsg)
				controls.resultsList:SetMode("message", {
					{ text = "^1" .. tostring(errMsg) },
				}, "^1Error")
				return
			end
			if coroutine.status(computeContext.co) == "dead" then
				cancelCompute()
			end
		end
	end)
	controls.computeButton.tooltipFunc = function(tooltip)
		tooltip:Clear(true)
		if computeContext then
			tooltip:AddLine(16, "^7Stop the current compute.")
			tooltip:AddLine(16, "^8Restores the previous results.")
			return
		end
		if selectedJewelType and selectedJewelType.isAllJewels then
			tooltip:AddLine(16, "^7Rank every jewel type by the selected stat.")
		else
			tooltip:AddLine(16, "^7Rank compatible sockets by the selected stat.")
		end
		tooltip:AddLine(16, "^8Uses Stat, Max pts, and Sockets filters.")
	end
	controls.computeButton.shown = true

	-- Status label
	controls.statusLabel = new("LabelControl"):LabelControl(TL, { 10, statusLabelY, 400, 16 }, COL_META .. "Click Find to search")
	local function showAllJewelsComputePrompt()
		controls.statusLabel.label = COL_META .. "Click Compute to rank all jewels"
		controls.resultsList:SetMode("message", { }, COL_META .. "Click Compute to rank all jewels")
	end
	controls.showLegacyCheck = new("CheckBoxControl"):CheckBoxControl(TL, { 700, statusLabelY, 18 }, "Show legacy", function(state)
		cancelCompute()
		showLegacy = state
		saveFinderState()
		rebuildJewelTypeDropdown()
		syncSelectedJewelTypeControls()
		updatePreview()
		runFind(false)
	end)

	-- ── Find button ───────────────────────────────────────────────────────────
	runFind = function(makePreferred)
			searchStartTime = GetTime()
			if selectedJewelType and selectedJewelType.isAllJewels then
				if not restoreCachedResults() then
					showAllJewelsComputePrompt()
				end
				return
			end
			controls.statusLabel.label = "^7Searching..."
			local ok, err = pcall(function()
					local allocNodes  = self.build.spec.allocNodes
					local isThreadBestVariantSearch = selectedJewelType.isThread == true
					local isImpossibleEscapeBestVariantSearch = selectedJewelType.isImpossibleEscape == true
					local isSplitPersonalitySearch = selectedJewelType.isSplitPersonality == true
					local isMassiveRadiusVariant = selectedJewelVariant and selectedJewelVariant.isMassiveRadius
					local radiusIndex
					local smallRadiusIndex = isImpossibleEscapeBestVariantSearch and radiusIndexByLabel["Small"] or nil
					if isThreadBestVariantSearch then
						if selectedThreadVariant then
							radiusIndex = selectedThreadVariant.radiusIndex
						end
					elseif isImpossibleEscapeBestVariantSearch or isSplitPersonalitySearch then
						radiusIndex = nil
				elseif isMassiveRadiusVariant then
				-- data.jewelRadius has no full Massive radius; we handle it below.
			elseif selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.radiusIndex then
				radiusIndex = selectedJewelVariant.radiusIndex
			else
				radiusIndex = selectedJewelType.radiusIndex
				end

				if not isThreadBestVariantSearch and not isImpossibleEscapeBestVariantSearch and not isSplitPersonalitySearch
				and not radiusIndex and not isMassiveRadiusVariant then
					return
				end

				local results = { }
				local impossibleEscapeBestResult
				if isImpossibleEscapeBestVariantSearch then
					local variants = getSelectedVariants() or selectedJewelType.variants or { }
					for _, variant in ipairs(variants) do
						local keystoneNode = treeData.keystoneMap[variant.keystoneName]
						local nodes = keystoneNode and keystoneNode.nodesInRadius and smallRadiusIndex and keystoneNode.nodesInRadius[smallRadiusIndex]
						if nodes then
							local score = selectedJewelType.score(nodes, allocNodes) or 0
							local topNodes = { }
							for _, n in pairs(nodes) do
								if not n.ascendancyName and (n.type == "Notable" or n.type == "Keystone") then
									t_insert(topNodes, {
										label = n.dn or n.name or "Unknown",
										nodeId = n.id,
									})
								end
							end
							t_sort(topNodes, function(a, b) return a.label < b.label end)
							local candidate = {
								score = score,
								topNodes = topNodes,
								variant = variant,
								detailText = variant.name,
							}
							if not impossibleEscapeBestResult
							or candidate.score > impossibleEscapeBestResult.score
							or (candidate.score == impossibleEscapeBestResult.score and candidate.variant.name < impossibleEscapeBestResult.variant.name) then
								impossibleEscapeBestResult = candidate
							end
						end
					end
				end
				for _, socket in ipairs(jewelSockets) do
					local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, selectedOccupiedMode)
					local socketNode = treeData.nodes[socket.id]
					if socketAllowed and socketNode and (socketNode.nodesInRadius or isSplitPersonalitySearch) then
						if isThreadBestVariantSearch then
							local bestThreadResult
							for _, threadVariant in ipairs(threadVariants) do
								local nodes = socketNode.nodesInRadius[threadVariant.radiusIndex]
								if nodes then
									local score = selectedJewelType.score(nodes, allocNodes) or 0
									local topNodes = { }
									for _, n in pairs(nodes) do
										if not n.ascendancyName and (n.type == "Notable" or n.type == "Keystone") then
											t_insert(topNodes, {
												label = n.dn or n.name or "Unknown",
												nodeId = n.id,
											})
										end
									end
									t_sort(topNodes, function(a, b) return a.label < b.label end)
									local candidate = {
										socket = socket,
										score = score,
										topNodes = topNodes,
										variant = threadVariant,
										replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
										storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
									}
									if not bestThreadResult
									or candidate.score > bestThreadResult.score
									or (candidate.score == bestThreadResult.score and candidate.variant.radiusIndex < bestThreadResult.variant.radiusIndex) then
										bestThreadResult = candidate
									end
								end
							end
							if bestThreadResult then
								t_insert(results, bestThreadResult)
							end
						elseif isImpossibleEscapeBestVariantSearch and impossibleEscapeBestResult then
							t_insert(results, {
								socket = socket,
								score = impossibleEscapeBestResult.score,
								topNodes = impossibleEscapeBestResult.topNodes,
								variant = impossibleEscapeBestResult.variant,
								detailText = impossibleEscapeBestResult.detailText,
								replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
								storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
							})
						elseif isSplitPersonalitySearch then
							local score = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
							t_insert(results, {
								socket = socket,
								score = score,
								topNodes = { },
								detailText = s_format("dist to start %d", score),
								replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
								storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
							})
						else
							local nodes
							if isMassiveRadiusVariant then
								-- Merge every parsed ring inside the full Massive boundary.
								nodes = { }
								for idx, r in ipairs(data.jewelRadius) do
									if r.outer <= FULL_MASSIVE_RADIUS and socketNode.nodesInRadius[idx] then
										for nodeId, node in pairs(socketNode.nodesInRadius[idx]) do
											nodes[nodeId] = node
										end
									end
								end
							else
								nodes = socketNode.nodesInRadius[radiusIndex]
							end

							if nodes then
								local scoreFn = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.score)
									or selectedJewelType.score
								local score = scoreFn(nodes, allocNodes)
								local detailBuilder = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.detailBuilder)
									or selectedJewelType.detailBuilder
								local topNodes = { }
								for _, n in pairs(nodes) do
									if not n.ascendancyName and (n.type == "Notable" or n.type == "Keystone") then
										t_insert(topNodes, {
											label = n.dn or n.name or "Unknown",
											nodeId = n.id,
										})
									end
								end
								t_sort(topNodes, function(a, b) return a.label < b.label end)
								t_insert(results, {
									socket = socket,
									score = score or 0,
									topNodes = topNodes,
									variant = selectedJewelVariant,
									detailText = detailBuilder and detailBuilder(nodes, allocNodes) or nil,
									replacedItemLabel = occupancy and occupancy.replacedItemLabel or nil,
									storedUnallocatedItemLabel = occupancy and occupancy.storedUnallocatedItemLabel or nil,
								})
							end
						end
					end
				end

					t_sort(results, function(a, b) return (a.score or 0) > (b.score or 0) end)

					local equippedList = self:findEquippedJewelSockets(selectedJewelType)
					local equippedSocketIds = { }
					local existingSocketId
					for _, entry in ipairs(equippedList) do
						equippedSocketIds[entry.socketId] = true
						if equippedList.atLimit then
							existingSocketId = existingSocketId or entry.socketId
						end
					end
					local rows = { }
					for _, r in ipairs(results) do
						local topLabels = buildNodeLabelList(r.topNodes)
						local topStr = t_concat(topLabels, ", ")
						if #topStr > 50 then
							topStr = topStr:sub(1, 47) .. "..."
						end

						local scoreLabel = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.scoreLabel)
							or selectedJewelType.scoreLabel
						local isEquippedSocket = equippedSocketIds[r.socket.id]
						local points = isEquippedSocket and 0
							or self:getSocketBasePoints(r.socket, { isOccupied = r.replacedItemLabel ~= nil })
						local scorePerPoint = points > 0 and (r.score / points) or r.score
						local sortValue = points > 0 and scorePerPoint or r.score
						local detailText = r.detailText
						if not detailText or detailText == "" then
							detailText = #r.topNodes > 0 and s_format("%d match%s", #r.topNodes, #r.topNodes == 1 and "" or "es") or scoreLabel
						elseif #topStr > 0 and (isThreadBestVariantSearch or isImpossibleEscapeBestVariantSearch) then
							detailText = detailText .. s_format(" | %d match%s", #r.topNodes, #r.topNodes == 1 and "" or "es")
						end
						local detailNodeId = nil
						if isImpossibleEscapeBestVariantSearch and r.variant and r.variant.keystoneName then
							local keystoneNode = treeData.keystoneMap[r.variant.keystoneName]
							detailNodeId = keystoneNode and keystoneNode.id or nil
						end
						local action
						if isEquippedSocket then
							action = "keep"
						elseif existingSocketId and r.replacedItemLabel then
							action = "moveReplace"
						elseif existingSocketId then
							action = "move"
						elseif r.replacedItemLabel then
							action = "replace"
						else
							action = "new"
						end
						t_insert(rows, {
							socketLabel = r.socket.label,
							socketId = r.socket.id,
							points = points,
							score = r.score or 0,
							scorePerPoint = scorePerPoint,
							sortValue = sortValue,
							variantLabel = r.variant and (isThreadBestVariantSearch and (r.variant.name .. " Ring")
								or r.variant.dropdownLabel or r.variant.name) or "",
							detailText = detailText,
							detailNodeId = detailNodeId,
							topNodes = copyTableSafe(r.topNodes, false, true),
							replacedItemLabel = r.replacedItemLabel,
							storedUnallocatedItemLabel = r.storedUnallocatedItemLabel,
							action = action,
							applyRawText = (r.variant and r.variant.rawText)
								or (selectedJewelVariant and selectedJewelVariant.rawText)
								or selectedJewelType.rawText,
						})
					end
					controls.resultsList:SetMode(isThreadBestVariantSearch and "findThread" or "find", rows, COL_META .. "(no results)")
					local elapsed = formatElapsed(searchStartTime)
					controls.statusLabel.label = (isThreadBestVariantSearch
						and s_format("^7Thread of Hope | %d | score/pt", #results)
						or isImpossibleEscapeBestVariantSearch
						and s_format("^7Impossible Escape | %d | score/pt", #results)
						or isSplitPersonalitySearch
						and s_format("^7Split Personality | %d | score/pt", #results)
						or s_format("^7%d results | score/pt", #results)) .. elapsed
					saveResultCache("find", isThreadBestVariantSearch and "findThread" or "find", rows, COL_META .. "(no results)", controls.statusLabel.label, makePreferred)
					if not makePreferred then
						restoreCachedResults()
					end
			end)
			if not ok then
				controls.statusLabel.label = "^1Error: " .. tostring(err)
				controls.resultsList:SetMode("message", {
					{ text = "^1" .. tostring(err) },
				}, "^1Error")
			end
		end
		controls.findButton = new("ButtonControl"):ButtonControl(BL, { edgePadding, bottomButtonY, 100, buttonHeight }, "Find", function()
			cancelCompute()
			runFind(true)
		end)
		controls.findButton.shown = not (selectedJewelType and selectedJewelType.isAllJewels)
		controls.findButton.tooltipFunc = function(tooltip)
			tooltip:Clear(true)
			tooltip:AddLine(16, "^7Find sockets with matching passives for this jewel.")
			tooltip:AddLine(16, "^8Use Compute to rank by the selected stat.")
		end

		applySelectedResult = function()
			local idx = controls.resultsList.selIndex
			local row = idx and controls.resultsList.list[idx]
			if not row or not row.applyRawText then return end

			local item = new("Item"):Item("Rarity: Unique\n" .. row.applyRawText)
			item:BuildModList()
			self.build.itemsTab:AddItem(item, true)

			local slot = self.build.itemsTab.sockets[row.socketId]
			if slot then
				slot:SetSelItemId(item.id)
			end
			self.build.itemsTab:PopulateSlots()
			self.build.buildFlag = true
		end
		controls.applyButton = new("ButtonControl"):ButtonControl(BL, { edgePadding + 480, bottomButtonY, 80, buttonHeight }, "Apply", applySelectedResult)
		controls.applyButton.enabled = function()
			local idx = controls.resultsList.selIndex
			return idx and controls.resultsList.list[idx] and controls.resultsList.list[idx].applyRawText ~= nil
		end
		controls.applyButton.tooltipFunc = function(tooltip)
			local idx = controls.resultsList.selIndex
			local row = idx and controls.resultsList.list[idx]
			if not row or not row.applyRawText then
				tooltip:Clear(true)
				tooltip:AddLine(16, "^7Select a result to apply.")
				return
			end
			tooltip:Clear(true)
			tooltip:AddLine(16, "^7Equip ^x33FF77" .. (row.jewelName or "jewel") .. " ^7in ^x33FF77" .. (row.socketLabel or "socket"))
			tooltip:AddLine(16, "^8Adds the jewel to this build.")
			if row.storedUnallocatedItemLabel then
				tooltip:AddLine(16, "^xFFAA33Replaces the stored jewel ignored by the current tree.")
			end
			tooltip:AddLine(16, "^8Double-click a result to apply it.")
		end

	local function restoreFinderState()
		if not finderState.jewelTypeName then
			updatePreview()
			if selectedJewelType and selectedJewelType.isAllJewels then
				showAllJewelsComputePrompt()
			end
			return
		end
		suppressFinderStateSave = true

		if finderState.showLegacy ~= nil then
			showLegacy = finderState.showLegacy
			controls.showLegacyCheck.state = showLegacy
		end
		rebuildJewelTypeDropdown()

		local jewelTypeIndex
		for i, jt in ipairs(activeJewelTypes) do
			if jt.name == finderState.jewelTypeName then
				jewelTypeIndex = i
				break
			end
		end
		if jewelTypeIndex then
			controls.jewelTypeSelect.selIndex = jewelTypeIndex
			selectedJewelType = activeJewelTypes[jewelTypeIndex]
		end

		if finderState.variantGroupValue or finderState.dreamFamilyValue then
			selectedVariantGroup = { value = finderState.variantGroupValue or finderState.dreamFamilyValue }
		end

		syncSelectedJewelTypeControls()

		if finderState.impactStatLabel then
			for i, stat in ipairs(IMPACT_STATS) do
				if stat.label == finderState.impactStatLabel then
					selectedImpactStat = stat
					controls.impactStatSelect.selIndex = i
					break
				end
			end
		end
		if finderState.maxPoints ~= nil then
			selectedMaxPoints = finderState.maxPoints
			controls.maxPointsEdit.buf = tostring(finderState.maxPoints)
		end
		if finderState.occupiedModeId then
			for i, option in ipairs(OCCUPIED_SOCKET_OPTIONS) do
				if option.id == finderState.occupiedModeId then
					selectedOccupiedMode = option
					controls.occupiedModeSelect.selIndex = i
					break
				end
			end
		end
		if finderState.allJewelsViewId then
			for i, option in ipairs(ALL_JEWELS_VIEW_OPTIONS) do
				if option.id == finderState.allJewelsViewId then
					selectedAllJewelsView = option
					controls.allJewelsViewSelect.selIndex = i
					break
				end
			end
		end
		if finderState.computeMethodId then
			local methods = getSelectedComputeMethods() or { }
			for i, method in ipairs(methods) do
				if method.id == finderState.computeMethodId then
					selectedComputeMethod = method
					controls.computeMethodSelect.selIndex = i
					break
				end
			end
		end
		if selectedJewelType and selectedJewelType.isThread and finderState.threadVariantName then
			for i, variant in ipairs(threadVariants) do
				if variant.name == finderState.threadVariantName then
					selectedThreadVariant = variant
					controls.threadVariantSelect.selIndex = i
					break
				end
			end
		elseif selectedJewelType and selectedJewelType.variants and finderState.jewelVariantName then
			local variants = getDisplayedVariants() or { }
			for i, variant in ipairs(variants) do
				local variantName = variant.dropdownLabel or variant.name
				if variantName == finderState.jewelVariantName then
					selectedJewelVariant = variant
					controls.jewelVariantSelect.selIndex = i + 1
					break
				end
			end
		end

		if controls.findButton and selectedJewelType and selectedJewelType.variants then
			controls.findButton.shown = not (not selectedJewelVariant and not selectedJewelType.isImpossibleEscape)
		end

		suppressFinderStateSave = false
		saveFinderState()
		updatePreview()
		runFind(false)
	end

	-- Close button
	controls.closeButton = new("ButtonControl"):ButtonControl(BR, { -edgePadding, bottomButtonY, 100, buttonHeight }, "Close", function()
		cancelCompute()
		main:ClosePopup()
	end)

	-- Initialise preview and open popup
	restoreFinderState()
	local popup = main:OpenPopup(popupWidth, popupHeight, "Find Radius Jewel", controls, nil, nil, "closeButton")
	local baseProcessInput = popup.ProcessInput
	popup.ProcessInput = function(self, inputEvents, viewPort)
		for _, event in ipairs(inputEvents) do
			if event.type == "KeyDown" and event.key == "RETURN" and IsKeyDown("CTRL") then
				controls.computeButton:Click()
				return
			end
		end
		baseProcessInput(self, inputEvents, viewPort)
	end
	return popup
end
