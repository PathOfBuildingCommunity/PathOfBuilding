-- Path of Building
--
-- Module: Power Calc Tasks
-- Shared per-candidate calculation logic for the parallelizable "iterate over
-- many candidates and rank them" features (node power / compare / anoint
-- notables / item DB sorting). Loaded both by the main thread (single-core code
-- paths and result merging) and by CalcWorker.lua inside worker VMs, so the two
-- paths always run identical calculation code.
--
local ipairs = ipairs
local pairs = pairs
local type = type
local t_insert = table.insert
local m_huge = math.huge
local m_max = math.max

local tasks = { }

local function isFiniteNumber(value)
	-- NaN compares unequal to itself; math.huge can't survive a JSON round trip
	return type(value) == "number" and value == value and value ~= m_huge and value ~= -m_huge
end

-- Baseline stats used to validate that a worker's reconstructed build produces
-- the same numbers as the main thread's live build. Mirrors the stats consumed
-- by CalcsTab:CalculateCombinedOffDefStat plus the active power stat.
local baselineStatList = {
	"LifeUnreserved", "Life", "Armour", "EnergyShield", "EnergyShieldRecoveryCap",
	"Evasion", "LifeRegenRecovery", "EnergyShieldRegenRecovery", "CombinedDPS",
}

function tasks.extractBaseline(output, powerStat, useFullDPS)
	local baseline = { }
	if type(output) ~= "table" then
		return baseline
	end
	for _, stat in ipairs(baselineStatList) do
		if isFiniteNumber(output[stat]) then
			baseline[stat] = output[stat]
		end
	end
	if type(output.Minion) == "table" and isFiniteNumber(output.Minion.CombinedDPS) then
		baseline["Minion.CombinedDPS"] = output.Minion.CombinedDPS
	end
	if useFullDPS and isFiniteNumber(output.FullDPS) then
		baseline["FullDPS"] = output.FullDPS
	end
	if powerStat and powerStat.stat and isFiniteNumber(output[powerStat.stat]) then
		baseline["powerStat."..powerStat.stat] = output[powerStat.stat]
	end
	return baseline
end

-- JSON-safe number encoding: math.huge/-math.huge/NaN can't cross the JSON
-- boundary, so they're carried as sentinel strings
function tasks.encodeNumber(value)
	if type(value) ~= "number" then
		return nil
	end
	if value ~= value then
		return 0
	elseif value == m_huge then
		return "inf"
	elseif value == -m_huge then
		return "-inf"
	end
	return value
end

function tasks.decodeNumber(value)
	if value == "inf" then
		return m_huge
	elseif value == "-inf" then
		return -m_huge
	end
	return tonumber(value)
end

-- Resolve a DB sort drop-list selection (built from data.powerStatList by
-- NotableDBControl/ItemDBControl:BuildSortOrder) from its sortMode key; used to
-- reconstruct the same selection inside a worker VM
function tasks.findSortDetail(sortMode)
	for _, stat in ipairs(data.powerStatList) do
		if (stat.itemField or stat.stat) == sortMode then
			return {
				sortMode = sortMode,
				itemField = stat.itemField,
				stat = stat.stat,
				transform = stat.transform,
			}
		end
	end
end

------------------------------------------------------------------------------
-- Node power (heat map / power report)
------------------------------------------------------------------------------

tasks.nodePower = { }

-- Worker side: run PowerBuilder for the given subset of nodes/cluster notables
-- and serialize the node.power results
function tasks.nodePower.computeBatch(build, common, batch, auxText, progressFunc)
	local calcsTab = build.calcsTab
	calcsTab.powerStat = common.powerStatIndex and data.powerStatList[common.powerStatIndex] or nil
	calcsTab.nodePowerMaxDepth = common.nodePowerMaxDepth
	local filter = { nodes = { }, cluster = { } }
	for _, nodeId in ipairs(batch.nodeIds or { }) do
		filter.nodes[nodeId] = true
	end
	for _, name in ipairs(batch.clusterNames or { }) do
		filter.cluster[name] = true
	end
	-- Overwrite this spec's path/depends data with the main thread's; a spec
	-- rebuilt from XML resolves equal-length shortest-path ties differently,
	-- which would change pathPower for nodes with multiple viable paths
	for idStr, ids in pairs(batch.paths or { }) do
		local node = build.spec.nodes[tonumber(idStr)]
		if node then
			local path = { }
			for _, pathId in ipairs(ids) do
				local pathNode = build.spec.nodes[pathId]
				if pathNode then
					t_insert(path, pathNode)
				end
			end
			if #path > 0 then
				node.path = path
				node.pathDist = #path
			end
		end
	end
	for idStr, ids in pairs(batch.depends or { }) do
		local node = build.spec.nodes[tonumber(idStr)]
		if node then
			local depends = { }
			for _, depId in ipairs(ids) do
				local depNode = build.spec.nodes[depId]
				if depNode then
					t_insert(depends, depNode)
				end
			end
			node.depends = depends
		end
	end
	calcsTab.workerProgressFunc = progressFunc
	local newPowerMax = calcsTab:PowerBuilder(filter)
	calcsTab.workerProgressFunc = nil

	local encodeNumber = tasks.encodeNumber
	local results = { nodes = { }, cluster = { }, powerMax = { } }
	for key, value in pairs(newPowerMax or { }) do
		results.powerMax[key] = encodeNumber(value)
	end
	for nodeId in pairs(filter.nodes) do
		local node = build.spec.nodes[nodeId]
		if node and node.power then
			local out = {
				singleStat = encodeNumber(node.power.singleStat),
				pathPower = encodeNumber(node.power.pathPower),
				offence = encodeNumber(node.power.offence),
				defence = encodeNumber(node.power.defence),
			}
			if node.power.masteryEffects then
				out.masteryEffects = { }
				for effectId, effect in pairs(node.power.masteryEffects) do
					out.masteryEffects[tostring(effectId)] = {
						singleStat = encodeNumber(effect.singleStat),
						pathPower = encodeNumber(effect.pathPower),
						offence = encodeNumber(effect.offence),
						defence = encodeNumber(effect.defence),
					}
				end
			end
			results.nodes[tostring(nodeId)] = out
		end
	end
	for name in pairs(filter.cluster) do
		local node = build.spec.tree.clusterNodeMap[name]
		if node and node.power then
			results.cluster[name] = { singleStat = encodeNumber(node.power.singleStat) }
		end
	end

	local powerStat = calcsTab.powerStat
	local useFullDPS = powerStat and powerStat.stat == "FullDPS"
	local calcFunc, calcBase = calcsTab:GetMiscCalculator()
	return {
		results = results,
		baseline = tasks.extractBaseline(calcBase, powerStat, useFullDPS),
	}
end

------------------------------------------------------------------------------
-- Anoint notable sorting (NotableDBControl)
------------------------------------------------------------------------------

tasks.notable = { }

-- Measure the impact of anointing one notable onto the display item.
-- Identical to the original NotableDBControl:ListBuilder loop body.
function tasks.notable.measureOne(itemsTab, calcFunc, calcBase, sortDetail, itemType, node)
	if node.modKey == "" then
		return 0
	end
	local output = calcFunc({ repSlotName = itemType, repItem = itemsTab:anointItem(node) })
	local original, modified = output, calcBase
	if modified.Minion then
		original = original.Minion
		modified = modified.Minion
	end
	local originalValue = original[sortDetail.stat] or 0
	local modifiedValue = modified[sortDetail.stat] or 0
	if sortDetail.transform then
		originalValue = sortDetail.transform(originalValue)
		modifiedValue = sortDetail.transform(modifiedValue)
	end
	return originalValue - modifiedValue
end

-- Worker side: auxText is the display item's raw text
function tasks.notable.computeBatch(build, common, batch, auxText, progressFunc)
	local itemsTab = build.itemsTab
	itemsTab.displayItem = new("Item", auxText)
	itemsTab.anointEnchantSlot = common.anointEnchantSlot or 1
	local sortDetail = tasks.findSortDetail(common.sortMode)
	if not sortDetail or not sortDetail.stat then
		error("notable: unknown sort mode "..tostring(common.sortMode))
	end
	local calcFunc, miscCalcBase = build.calcsTab:GetMiscCalculator()
	local itemType = itemsTab.displayItem.base.type
	local calcBase = calcFunc({ repSlotName = itemType, repItem = itemsTab:anointItem(nil) })
	local results = { }
	local nodeIds = batch.nodeIds or { }
	for index, nodeId in ipairs(nodeIds) do
		local node = build.spec.tree.nodes[nodeId]
		if node then
			results[tostring(nodeId)] = tasks.encodeNumber(tasks.notable.measureOne(itemsTab, calcFunc, calcBase, sortDetail, itemType, node))
		end
		if progressFunc and index % 10 == 0 then
			progressFunc(index, #nodeIds)
		end
	end
	return {
		results = results,
		baseline = tasks.extractBaseline(miscCalcBase, sortDetail, false),
	}
end

------------------------------------------------------------------------------
-- Compare tab power report (CompareTab)
------------------------------------------------------------------------------

tasks.compare = { }

-- Worker side: auxText is the comparison build's XML; descriptors identify
-- candidates by stable ids and are computed via the same CompareTab methods
-- the single-core path uses
function tasks.compare.computeBatch(build, common, batch, auxText, progressFunc)
	local compareTab = build.compareTab
	if not compareTab then
		error("compare: build has no compare tab")
	end
	local powerStat = data.powerStatList[common.powerStatIndex]
	if not powerStat then
		error("compare: unknown power stat index "..tostring(common.powerStatIndex))
	end
	local compareEntry = new("CompareEntry", auxText, "CalcWorker comparison")
	local ctx = compareTab:MakeComparePowerContext(compareEntry, powerStat)
	local results = { }
	local descriptors = batch.descriptors or { }
	for index, desc in ipairs(descriptors) do
		local ok, impact, extra = compareTab:ComputeComparePowerCandidate(ctx, desc)
		t_insert(results, {
			i = desc.i,
			ok = ok and true or false,
			impact = ok and impact and tasks.encodeNumber(impact) or nil,
			err = not ok and tostring(impact) or nil,
			extra = extra,
		})
		if progressFunc and index % 5 == 0 then
			progressFunc(index, #descriptors)
		end
	end
	return {
		results = results,
		baseline = tasks.extractBaseline(ctx.calcBase, powerStat, ctx.useFullDPS),
	}
end

------------------------------------------------------------------------------
-- Item DB sorting (ItemDBControl)
------------------------------------------------------------------------------

tasks.itemdb = { }

-- Measure an item's best impact across all slots it fits.
-- Identical to the original ItemDBControl:ListBuilder loop body.
function tasks.itemdb.measureOne(itemsTab, calcFunc, sortDetail, sortMode, useFullDPS, item)
	local measuredPower = 0
	for slotName, slot in pairs(itemsTab.slots) do
		if itemsTab:IsItemValidForSlot(item, slotName) and not slot.inactive and (not slot.weaponSet or slot.weaponSet == (itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1)) then
			local output = calcFunc(item.base.flask and { toggleFlask = item } or item.base.tincture and { toggleTincture = item } or { repSlotName = slotName, repItem = item }, useFullDPS)
			local power = output.Minion and output.Minion[sortMode] or output[sortMode] or 0
			if sortDetail.transform then
				power = sortDetail.transform(power)
			end
			measuredPower = m_max(measuredPower, power)
		end
	end
	return measuredPower
end

-- Worker side: candidates are item names in the shared unique/rare DB
function tasks.itemdb.computeBatch(build, common, batch, auxText, progressFunc)
	local itemsTab = build.itemsTab
	local sortDetail = tasks.findSortDetail(common.sortMode)
	if not sortDetail or not sortDetail.stat then
		error("itemdb: unknown sort mode "..tostring(common.sortMode))
	end
	local useFullDPS = sortDetail.stat == "FullDPS"
	local db = common.dbType == "RARE" and main.rareDB or main.uniqueDB
	local calcFunc, calcBase = build.calcsTab:GetMiscCalculator()
	local results = { }
	local names = batch.names or { }
	for index, name in ipairs(names) do
		local item = db.list[name]
		if item then
			results[name] = tasks.encodeNumber(tasks.itemdb.measureOne(itemsTab, calcFunc, sortDetail, sortDetail.sortMode, useFullDPS, item))
		end
		if progressFunc and index % 10 == 0 then
			progressFunc(index, #names)
		end
	end
	return {
		results = results,
		baseline = tasks.extractBaseline(calcBase, sortDetail, useFullDPS),
	}
end

return tasks
