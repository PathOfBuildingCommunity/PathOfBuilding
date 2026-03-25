-- Path of Building
--
-- Class: Radius Jewel Finder
-- Popup that scores passive tree sockets for radius unique jewels.
-- Supports: The Light of Meaning, Might of the Meek, Unnatural Instinct,
--           Inspired Learning, Anatomical Knowledge, Thread of Hope, Lioneye's Fall,
--           Intuitive Leap, Tempered Flesh, Tempered Mind, Tempered Spirit,
--           Transcendent Flesh, Transcendent Mind, Transcendent Spirit,
--           Split Personality, Impossible Escape,
--           Energy From Within, Healthy Mind, Energised Armour,
--           Brute Force Solution, Careful Planning, Efficient Training,
--           Fertile Mind, Fluid Motion, Inertia,
--           Combat Focus (Crimson/Cobalt/Viridian),
--           The Red Dream, The Red Nightmare, The Green Dream, The Green Nightmare,
--           The Blue Dream, The Blue Nightmare.
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

-- Lightweight output snapshot for stat-comparison tooltips.
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
	-- Minion sub-output (same shallow treatment)
	if output.Minion then
		out.Minion = extractTooltipStats(output.Minion)
	end
	return out
end

local function formatSignedValue(value)
	local sign = value >= 0 and "+" or ""
	local col = value > 0 and "^2" or (value < 0 and "^1" or "^8")
	return s_format("%s%s%.1f", col, sign, value)
end

local function formatSignedPercent(value)
	local sign = value >= 0 and "+" or ""
	local col = value > 0 and "^2" or (value < 0 and "^1" or "^8")
	return s_format("%s%s%.1f%%", col, sign, value)
end

local function formatPerPointDisplay(value, points)
	if points == 0 then
		return value > 0 and "^2Free" or (value < 0 and "^1Free" or "^8Free")
	end
	return formatSignedPercent(value)
end

local RadiusJewelResultsListClass = newClass("RadiusJewelResultsListControl", "ListControl", function(self, anchor, rect, build, socketViewer)
	self.ListControl(anchor, rect, 16, "VERTICAL", false)
	self.build = build
	self.socketViewer = socketViewer
	self.colLabels = true
	self.showRowSeparators = true
	self.defaultText = "^8Click Find to search"
	self.mode = "message"
	self.columnsByMode = {
		message = {
			{ width = rect[3] - 22, label = "" },
		},
		computeSocket = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 75, label = "Gain", sortable = true },
			{ width = 60, label = "%", sortable = true },
			{ width = 65, label = "%/Pt", sortable = true },
			{ width = 150, label = "Detail", sortable = true },
		},
		computeSocketAll = {
			{ width = 120, label = "Jewel", sortable = true },
			{ width = 130, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 75, label = "Gain", sortable = true },
			{ width = 60, label = "%", sortable = true },
			{ width = 65, label = "%/Pt", sortable = true },
			{ width = 70, label = "Detail", sortable = true },
		},
		find = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 70, label = "/Pt", sortable = true },
			{ width = 220, label = "Detail", sortable = true },
		},
		findThread = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 70, label = "/Pt", sortable = true },
			{ width = 90, label = "Ring", sortable = true },
			{ width = 130, label = "Detail", sortable = true },
		},
		findAll = {
			{ width = 120, label = "Jewel", sortable = true },
			{ width = 130, label = "Socket", sortable = true },
			{ width = 40, label = "Pts", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 65, label = "/Pt", sortable = true },
			{ width = 145, label = "Detail", sortable = true },
		},
	}
	self.defaultSortByMode = {
		computeSocket = 5,
		computeSocketAll = 6,
		find = 4,
		findThread = 4,
		findAll = 5,
	}
	self.resultTooltip = new("Tooltip")
	self.itemTooltip = new("Tooltip")
end)

local RadiusJewelDetailListClass = newClass("RadiusJewelDetailListControl", "TextListControl", function(self, anchor, rect, columns, list, build, socketViewer)
	self.TextListControl(anchor, rect, columns, list)
	self.build = build
	self.socketViewer = socketViewer
	self.nodeTooltip = new("Tooltip")
end)

function RadiusJewelDetailListClass:GetHoverLine()
	if not self:IsShown() or not self:IsMouseInBounds() then
		return nil
	end
	local cursorX, cursorY = GetCursorPos()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	if cursorX < x + 2 or cursorX > x + width - 20 or cursorY < y + 2 or cursorY > y + height - 2 then
		return nil
	end
	local lineY = y + 2 - self.controls.scrollBar.offset
	for _, lineInfo in ipairs(self.list or { }) do
		if cursorY >= lineY and cursorY < lineY + lineInfo.height then
			return lineInfo
		end
		lineY = lineY + lineInfo.height
	end
	return nil
end

function RadiusJewelDetailListClass:Draw(viewPort)
	self.TextListControl.Draw(self, viewPort)
	local hoverLine = self:GetHoverLine()
	if not hoverLine or not hoverLine.nodeId or main.popups[2] then
		return
	end
	local node = self.build.spec.nodes[hoverLine.nodeId] or self.build.spec.tree.nodes[hoverLine.nodeId]
	if not node then
		return
	end

	local function clampRectPosition(x, y, width, height)
		x = math.max(viewPort.x, math.min(x, viewPort.x + viewPort.width - width))
		y = math.max(viewPort.y, math.min(y, viewPort.y + viewPort.height - height))
		return x, y
	end
	local function rectsOverlap(aX, aY, aW, aH, bX, bY, bW, bH)
		return aX < bX + bW and aX + aW > bX and aY < bY + bH and aY + aH > bY
	end
	local function placeTooltip(ttW, ttH, cursorX, cursorY, blockedRects)
		local candidates = {
			{ x = cursorX + 20, y = cursorY + 20 },
			{ x = cursorX - ttW - 20, y = cursorY + 20 },
			{ x = cursorX + 20, y = cursorY - ttH - 20 },
			{ x = cursorX - ttW - 20, y = cursorY - ttH - 20 },
		}
		for _, candidate in ipairs(candidates) do
			local ttX, ttY = clampRectPosition(candidate.x, candidate.y, ttW, ttH)
			local overlaps = false
			for _, blockedRect in ipairs(blockedRects or { }) do
				if rectsOverlap(ttX, ttY, ttW, ttH, blockedRect.x, blockedRect.y, blockedRect.width, blockedRect.height) then
					overlaps = true
					break
				end
			end
			if not overlaps then
				return ttX, ttY
			end
		end
		return clampRectPosition(cursorX + 20, cursorY + 20, ttW, ttH)
	end

	local cursorX, cursorY = GetCursorPos()
	local viewerRect
	SetDrawLayer(nil, 15)
	local viewerX = cursorX + 20
	local viewerY = cursorY - 150
	if viewerX + 304 > viewPort.x + viewPort.width then viewerX = cursorX - 324 end
	if viewerY < viewPort.y then viewerY = viewPort.y elseif viewerY + 304 > viewPort.y + viewPort.height then viewerY = viewPort.y + viewPort.height - 304 end
	viewerRect = { x = viewerX, y = viewerY, width = 304, height = 304 }

	SetDrawColor(1, 1, 1)
	DrawImage(nil, viewerX, viewerY, 304, 304)
	self.socketViewer.zoom = 5
	local scale = self.build.spec.tree.size / 1500
	self.socketViewer.zoomX = -node.x / scale
	self.socketViewer.zoomY = -node.y / scale
	SetViewport(viewerX + 2, viewerY + 2, 300, 300)
	self.socketViewer:Draw(self.build, { x = 0, y = 0, width = 300, height = 300 }, { })
	SetDrawLayer(nil, 30)
	SetDrawColor(1, 1, 1, 0.2)
	DrawImage(nil, 149, 0, 2, 300)
	DrawImage(nil, 0, 149, 300, 2)
	SetViewport()

	SetDrawLayer(nil, 100)
	self.nodeTooltip:Clear(true)
	local prevShowStatDifferences = self.socketViewer.showStatDifferences
	self.socketViewer.showStatDifferences = true
	self.socketViewer:AddNodeTooltip(self.nodeTooltip, node, self.build)
	self.socketViewer.showStatDifferences = prevShowStatDifferences
	local ttW, ttH = self.nodeTooltip:GetSize()
	local ttX, ttY = placeTooltip(ttW, ttH, cursorX, cursorY, { viewerRect })
	self.nodeTooltip:Draw(ttX, ttY, nil, nil, viewPort)
	SetDrawLayer(nil, 0)
end

function RadiusJewelResultsListClass:SetMode(mode, list, defaultText)
	self.mode = mode or "message"
	self.list = list or { }
	self.defaultText = defaultText or ""
	self.colList = self.columnsByMode[self.mode] or self.columnsByMode.message
	local defaultSort = self.defaultSortByMode[self.mode]
	if defaultSort and #self.list > 0 then
		self:ReSort(defaultSort)
	end
	if self.mode ~= "message" and #self.list > 0 then
		self:SelectIndex(1)
	else
		self.selIndex = nil
		self.selValue = nil
		if self.OnSelect then
			self:OnSelect(nil, nil)
		end
	end
end

function RadiusJewelResultsListClass:ReSort(colIndex)
	if self.mode == "computeSocket" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.socketLabel < b.socketLabel end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.points < b.points end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.delta > b.delta end)
		elseif colIndex == 4 then
			t_sort(self.list, function(a, b) return a.pct > b.pct end)
		elseif colIndex == 5 then
			t_sort(self.list, function(a, b) return a.sortPctPerPoint > b.sortPctPerPoint end)
		elseif colIndex == 6 then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	elseif self.mode == "computeSocketAll" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.jewelName < b.jewelName end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.socketLabel < b.socketLabel end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.points < b.points end)
		elseif colIndex == 4 then
			t_sort(self.list, function(a, b) return a.delta > b.delta end)
		elseif colIndex == 5 then
			t_sort(self.list, function(a, b) return a.pct > b.pct end)
		elseif colIndex == 6 then
			t_sort(self.list, function(a, b) return a.sortPctPerPoint > b.sortPctPerPoint end)
		elseif colIndex == 7 then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	elseif self.mode == "find" or self.mode == "findThread" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.socketLabel < b.socketLabel end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.points < b.points end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.score > b.score end)
		elseif colIndex == 4 then
			t_sort(self.list, function(a, b) return a.scorePerPointSort > b.scorePerPointSort end)
		elseif colIndex == 5 then
			if self.mode == "findThread" then
				t_sort(self.list, function(a, b) return a.variantLabel < b.variantLabel end)
			else
				t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
			end
		elseif colIndex == 6 and self.mode == "findThread" then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	elseif self.mode == "findAll" then
		if colIndex == 1 then
			t_sort(self.list, function(a, b) return a.jewelName < b.jewelName end)
		elseif colIndex == 2 then
			t_sort(self.list, function(a, b) return a.socketLabel < b.socketLabel end)
		elseif colIndex == 3 then
			t_sort(self.list, function(a, b) return a.points < b.points end)
		elseif colIndex == 4 then
			t_sort(self.list, function(a, b) return a.score > b.score end)
		elseif colIndex == 5 then
			t_sort(self.list, function(a, b) return a.scorePerPointSort > b.scorePerPointSort end)
		elseif colIndex == 6 then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	end
end

function RadiusJewelResultsListClass:GetRowValue(column, index, row)
	if self.mode == "message" then
		return column == 1 and row.text or ""
	elseif self.mode == "computeSocket" then
		return column == 1 and row.socketLabel
			or column == 2 and tostring(row.points)
			or column == 3 and formatSignedValue(row.delta)
			or column == 4 and formatSignedPercent(row.pct)
			or column == 5 and formatPerPointDisplay(row.pctPerPoint, row.points)
			or column == 6 and row.detailText
			or ""
	elseif self.mode == "computeSocketAll" then
		return column == 1 and row.jewelName
			or column == 2 and row.socketLabel
			or column == 3 and tostring(row.points)
			or column == 4 and formatSignedValue(row.delta)
			or column == 5 and formatSignedPercent(row.pct)
			or column == 6 and formatPerPointDisplay(row.pctPerPoint, row.points)
			or column == 7 and row.detailText
			or ""
	elseif self.mode == "find" then
		return column == 1 and row.socketLabel
			or column == 2 and tostring(row.points)
			or column == 3 and s_format("^7%d", row.score)
			or column == 4 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 5 and row.detailText
			or ""
	elseif self.mode == "findThread" then
		return column == 1 and row.socketLabel
			or column == 2 and tostring(row.points)
			or column == 3 and s_format("^7%d", row.score)
			or column == 4 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 5 and row.variantLabel
			or column == 6 and row.detailText
			or ""
	elseif self.mode == "findAll" then
		return column == 1 and row.jewelName
			or column == 2 and row.socketLabel
			or column == 3 and tostring(row.points)
			or column == 4 and s_format("^7%d", row.score)
			or column == 5 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 6 and row.detailText
			or ""
	end
	return ""
end

function RadiusJewelResultsListClass:Draw(viewPort, noTooltip)
	self.ListControl.Draw(self, viewPort, true)
	if self.suppressTooltipFunc and self.suppressTooltipFunc() then
		return
	end
	local hoverData = self.hoverValue
	if not hoverData or main.popups[2] then
		return
	end

	local function clampRectPosition(x, y, width, height)
		x = math.max(viewPort.x, math.min(x, viewPort.x + viewPort.width - width))
		y = math.max(viewPort.y, math.min(y, viewPort.y + viewPort.height - height))
		return x, y
	end
	local function rectsOverlap(aX, aY, aW, aH, bX, bY, bW, bH)
		return aX < bX + bW and aX + aW > bX and aY < bY + bH and aY + aH > bY
	end
	local function placeResultTooltip(ttW, ttH, cursorX, cursorY, blockedRects)
		local candidates = {
			{ x = cursorX + 20, y = cursorY + 20 },
			{ x = cursorX - ttW - 20, y = cursorY + 20 },
			{ x = cursorX + 20, y = cursorY - ttH - 20 },
			{ x = cursorX - ttW - 20, y = cursorY - ttH - 20 },
		}
		local primaryBlockedRect = blockedRects and blockedRects[1] or nil
		if primaryBlockedRect then
			t_insert(candidates, 1, { x = primaryBlockedRect.x - ttW - 12, y = cursorY + 20 })
			t_insert(candidates, 2, { x = primaryBlockedRect.x + primaryBlockedRect.width + 12, y = cursorY + 20 })
			t_insert(candidates, 3, { x = primaryBlockedRect.x, y = primaryBlockedRect.y - ttH - 12 })
			t_insert(candidates, 4, { x = primaryBlockedRect.x, y = primaryBlockedRect.y + primaryBlockedRect.height + 12 })
		end
		for _, candidate in ipairs(candidates) do
			local ttX, ttY = clampRectPosition(candidate.x, candidate.y, ttW, ttH)
			local overlapsBlockedRect = false
			for _, blockedRect in ipairs(blockedRects or { }) do
				if rectsOverlap(ttX, ttY, ttW, ttH, blockedRect.x, blockedRect.y, blockedRect.width, blockedRect.height) then
					overlapsBlockedRect = true
					break
				end
			end
			if not overlapsBlockedRect then
				return ttX, ttY
			end
		end
		return clampRectPosition(cursorX + 20, cursorY + 20, ttW, ttH)
	end

	local cursorX, cursorY = GetCursorPos()
	local x, y = self:GetPos()
	local relX = cursorX - (x + 2)
	local hoverColumn
	if hoverData then
		for columnIndex, column in ipairs(self.colList) do
			local colOffset = column._offset or 0
			local colWidth = column._width or 0
			if relX >= colOffset and relX < colOffset + colWidth then
				hoverColumn = columnIndex
				break
			end
		end
	end
	local detailColumnByMode = {
		computeSocket = 6,
		computeSocketAll = 7,
		find = 5,
		findThread = 6,
	}
	local socketColumnByMode = {
		computeSocket = 1,
		computeSocketAll = 2,
		find = 1,
		findThread = 1,
	}
	local statColumnsByMode = {
		computeSocket = { [3] = true, [4] = true, [5] = true },
		computeSocketAll = { [4] = true, [5] = true, [6] = true },
	}
	local itemColumnsByMode = {
		computeSocket = { [6] = true },
		computeSocketAll = { [7] = true },
		find = { [5] = true },
		findThread = { [6] = true },
	}
	local detailColumn = hoverColumn and detailColumnByMode[self.mode] == hoverColumn
	local socketColumn = hoverColumn and socketColumnByMode[self.mode] == hoverColumn
	local showViewer = socketColumn or (detailColumn and hoverData and hoverData.detailNodeId)
	local showStatTooltip = hoverData and hoverData.baseOutput and hoverData.compareOutput
		and hoverColumn and statColumnsByMode[self.mode] and statColumnsByMode[self.mode][hoverColumn]
	local showItemTooltip = hoverData and hoverData.itemTooltipLines
		and hoverColumn and itemColumnsByMode[self.mode] and itemColumnsByMode[self.mode][hoverColumn]
	local hoverNodeId = hoverData and hoverData.socketId or nil
	if hoverData and hoverData.detailNodeId and hoverColumn and detailColumnByMode[self.mode] == hoverColumn then
		hoverNodeId = hoverData.detailNodeId
	end
	local viewerRect
	if showViewer and hoverNodeId then
		local node = self.build.spec.nodes[hoverNodeId] or self.build.spec.tree.nodes[hoverNodeId]
		if node then
			SetDrawLayer(nil, 15)
			local viewerX = cursorX + 20
			local viewerY = cursorY - 150
			if viewerX + 304 > viewPort.x + viewPort.width then viewerX = cursorX - 324 end
			if viewerY < viewPort.y then viewerY = viewPort.y elseif viewerY + 304 > viewPort.y + viewPort.height then viewerY = viewPort.y + viewPort.height - 304 end
			viewerRect = { x = viewerX, y = viewerY, width = 304, height = 304 }

			SetDrawColor(1, 1, 1)
			DrawImage(nil, viewerX, viewerY, 304, 304)
			self.socketViewer.zoom = 5
			local scale = self.build.spec.tree.size / 1500
			self.socketViewer.zoomX = -node.x / scale
			self.socketViewer.zoomY = -node.y / scale
			SetViewport(viewerX + 2, viewerY + 2, 300, 300)
			self.socketViewer:Draw(self.build, { x = 0, y = 0, width = 300, height = 300 }, { })
			SetDrawLayer(nil, 30)
			SetDrawColor(1, 1, 1, 0.2)
			DrawImage(nil, 149, 0, 2, 300)
			DrawImage(nil, 0, 149, 300, 2)
			SetViewport()
			SetDrawLayer(nil, 0)
		end
	end

	local blockedRects = { }
	if viewerRect then
		t_insert(blockedRects, viewerRect)
	end
	if showStatTooltip then
		SetDrawLayer(nil, 100)
		self.resultTooltip:Clear()
		local count = self.build:AddStatComparesToTooltip(self.resultTooltip, hoverData.baseOutput, hoverData.compareOutput,
			hoverData.tooltipHeader or "^7Socketing this jewel will give you:")
		if count == 0 then
			self.resultTooltip:AddLine(14, "^7No stat changes for this proposal.")
		end
		local ttW, ttH = self.resultTooltip:GetSize()
		local ttX, ttY = placeResultTooltip(ttW, ttH, cursorX, cursorY, blockedRects)
		self.resultTooltip:Draw(ttX, ttY, nil, nil, viewPort)
		t_insert(blockedRects, { x = ttX, y = ttY, width = ttW, height = ttH })
		SetDrawLayer(nil, 0)
	end
	if showItemTooltip then
		SetDrawLayer(nil, 100)
		self.itemTooltip:Clear(true)
		for _, line in ipairs(hoverData.itemTooltipLines) do
			self.itemTooltip:AddLine(line.height or 16, line[1], line.font)
		end
		local itemTtW, itemTtH = self.itemTooltip:GetSize()
		local itemTtX, itemTtY = placeResultTooltip(itemTtW, itemTtH, cursorX, cursorY, blockedRects)
		self.itemTooltip:Draw(itemTtX, itemTtY, nil, nil, viewPort)
		SetDrawLayer(nil, 0)
	end
end

local RadiusJewelFinderClass = newClass("RadiusJewelFinder", function(self, treeTab)
	self.treeTab = treeTab
	self.build = treeTab.build
end)

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
	local scopedOutput = output
	if scopedOutput and scopedOutput.Minion and selection.stat ~= "FullDPS" then
		scopedOutput = scopedOutput.Minion
	end
	local value = scopedOutput and (scopedOutput[selection.stat] or 0) or 0
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
	local denom = m_abs(baseline)
	return denom > 0 and (delta / denom * 100) or 0
end

-- Data module aliases
local IMPACT_STATS                  = RadiusJewelData.buildImpactStats()
local CONNECTIONLESS_COMPUTE_METHODS = RadiusJewelData.CONNECTIONLESS_COMPUTE_METHODS
local OCCUPIED_SOCKET_OPTIONS       = RadiusJewelData.OCCUPIED_SOCKET_OPTIONS
local jewelPreviewFn                = RadiusJewelData.jewelPreviewFn
local scoreAllocPassives            = RadiusJewelData.scoreAllocPassives
local buildJewelTypes               = RadiusJewelData.buildJewelTypes
local jewelTypeSortOrder            = RadiusJewelData.jewelTypeSortOrder
local makeVariantDropdownEntry      = RadiusJewelData.makeVariantDropdownEntry
local findConnectionlessComputeMethod = RadiusJewelData.findConnectionlessComputeMethod
local getSplitPersonalityVariants   = RadiusJewelData.getSplitPersonalityVariants
local getImpossibleEscapeVariants   = RadiusJewelData.getImpossibleEscapeVariants
local mustGetUniqueRawText          = RadiusJewelData.mustGetUniqueRawText

-- Exposed for testing; delegates to the data module.
function RadiusJewelFinderClass:buildVariantsFromUniqueItem(uniqueName, baseName)
	return RadiusJewelData.buildVariantsFromUniqueItem(uniqueName, baseName)
end

function RadiusJewelFinderClass:discoverFoulbornVariants(uniqueName, radiusIndexByLabel)
	return RadiusJewelData.discoverFoulbornVariants(uniqueName, radiusIndexByLabel)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Build jewel socket list
-- ─────────────────────────────────────────────────────────────────────────────

function RadiusJewelFinderClass:buildJewelSockets(largeRadiusIndex)
	local treeData  = self.build.spec.tree
	local allocNodes = self.build.spec.allocNodes
	local sockets = { }
	for socketId, socketData in pairs(self.build.spec.nodes) do
		if socketData.isJewelSocket and socketData.name ~= "Charm Socket" then
			local keystone = "Unknown"
			local minDist = m_huge
			local socketNode = treeData.nodes[socketId]
			if socketNode and socketNode.nodesInRadius and socketNode.nodesInRadius[largeRadiusIndex] then
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

function RadiusJewelFinderClass:getSocketOccupancyInfo(socketId)
	local slot = self.build.itemsTab.sockets[socketId]
	if not slot or slot.selItemId == 0 then
		return {
			slot = slot,
			isOccupied = false,
			isSafeReplace = true,
		}
	end
	local item = self.build.itemsTab.items[slot.selItemId]
	local itemLabel = item and (item.title or item.name or item.baseName) or "Unknown item"
	local isPositionSensitive = false
	if item then
		isPositionSensitive = item.clusterJewel
			or item.jewelRadiusIndex ~= nil
			or (item.jewelData and item.jewelData.impossibleEscapeKeystones ~= nil)
			or (item.title and item.title:match("^Split Personality") ~= nil)
	end
	return {
		slot = slot,
		item = item,
		itemLabel = itemLabel,
		isOccupied = true,
		isSafeReplace = not isPositionSensitive,
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

function RadiusJewelFinderClass:getSocketAccessCost(socket, occupancy)
	local socketId = type(socket) == "table" and socket.id or socket
	occupancy = occupancy or self:getSocketOccupancyInfo(socketId)
	if occupancy and occupancy.isOccupied then
		return 0
	end
	return type(socket) == "table" and (socket.pathDist or 0) or 0
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
local buildDisplayedConnectionlessPlans = LoadModule("Classes/RadiusJewelCompute")(RadiusJewelFinderClass, {
	extractTooltipStats = extractTooltipStats,
	normalizeImpactStat = normalizeImpactStat,
	calculateImpactPercent = calculateImpactPercent,
	mustGetUniqueRawText = mustGetUniqueRawText,
})

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

	-- Thread of Hope ring variants (annuli: inner > 0)
	local threadVariants = { }
	local threadRawText = mustGetUniqueRawText("Thread of Hope")
	local threadItem = new("Item", "Rarity: Unique\n" .. threadRawText)
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

	-- Mutable state
	local showLegacy             = false
	local activeJewelTypes       = { }   -- filtered view of jewelTypes
	local selectedJewelType      = nil   -- set after first filter build
	local selectedThreadVariant  = threadVariants[1]
	local selectedJewelVariant   = nil  -- set when jewel type has built-in variants
	local selectedComputeMethod  = CONNECTIONLESS_COMPUTE_METHODS[2]
	local selectedMaxPoints      = nil
	local selectedOccupiedMode   = OCCUPIED_SOCKET_OPTIONS[1]
	local dreamFamilyOptions     = {
		{ name = "All", value = "ALL" },
		{ name = "Red Dream", value = "The Red Dream" },
		{ name = "Red Nightmare", value = "The Red Nightmare" },
		{ name = "Green Dream", value = "The Green Dream" },
		{ name = "Green Nightmare", value = "The Green Nightmare" },
		{ name = "Blue Dream", value = "The Blue Dream" },
		{ name = "Blue Nightmare", value = "The Blue Nightmare" },
	}
	local selectedDreamFamily    = dreamFamilyOptions[1]

	local TL       = { "TOPLEFT", nil, "TOPLEFT" }
	local controls = { }

	-- ── Dropdown label lists ──────────────────────────────────────────────────
	-- (jtLabels is built dynamically via rebuildJewelTypeDropdown)
	local jtLabels = { }

	local tvLabels = { }
	for _, tv in ipairs(threadVariants) do t_insert(tvLabels, tv.name .. " Ring") end

	local socketViewer = new("PassiveTreeView")

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
	finderState.connectionlessPlanCache = finderState.connectionlessPlanCache or { }
	local ALL_JEWELS_VIEW_OPTIONS = {
		{ id = "all",           label = "All results" },
		{ id = "bestPerSocket", label = "Best per socket" },
	}
	local allJewelsViewLabels = { }
	for _, v in ipairs(ALL_JEWELS_VIEW_OPTIONS) do t_insert(allJewelsViewLabels, v.label) end
	local selectedAllJewelsView = ALL_JEWELS_VIEW_OPTIONS[1]
	local lastComputeAllRows = nil
	local lastFindAllRows = nil

	local function filterBestPerSocket(rows)
		local bestBySocket = { }
		for _, row in ipairs(rows) do
			local ex = bestBySocket[row.socketId]
			local sortVal = row.sortPctPerPoint or row.scorePerPointSort or 0
			local exSortVal = ex and (ex.sortPctPerPoint or ex.scorePerPointSort or 0) or nil
			if not ex or sortVal > exSortVal then
				bestBySocket[row.socketId] = row
			end
		end
		local filtered = { }
		for _, row in pairs(bestBySocket) do
			t_insert(filtered, row)
		end
		return filtered
	end

	local suppressFinderStateSave = false
	local runFind
	local computeContext
	local cancelComputeTask

	local function saveFinderState()
		if suppressFinderStateSave then
			return
		end
		finderState.showLegacy = showLegacy
		finderState.jewelTypeName = selectedJewelType and selectedJewelType.name or nil
		finderState.jewelVariantName = selectedJewelVariant and (selectedJewelVariant.dropdownLabel or selectedJewelVariant.name) or nil
		finderState.threadVariantName = selectedThreadVariant and selectedThreadVariant.name or nil
		finderState.dreamFamilyValue = selectedDreamFamily and selectedDreamFamily.value or nil
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
			selectedDreamFamily and selectedDreamFamily.value or "",
			selectedImpactStat and selectedImpactStat.field or "",
			computeMethodKey,
			selectedMaxPoints and tostring(selectedMaxPoints) or "",
			selectedOccupiedMode and selectedOccupiedMode.id or "",
		}, "|")
	end

	local function restoreCachedResults()
		local key = getSelectionKey()
		local preferredView = finderState.resultViewByKey[key]
		local cache = preferredView == "compute" and finderState.computeCache[key] or finderState.findCache[key]
		if not cache and preferredView == "compute" then
			cache = finderState.findCache[key]
		elseif not cache and preferredView == "find" then
			cache = finderState.computeCache[key]
		end
		if not cache then
			cache = finderState.findCache[key] or finderState.computeCache[key]
		end
		if not cache then
			return false
		end
		local rows = copyTableSafe(cache.rows, false, true)
		if cache.mode == "computeSocketAll" then
			lastComputeAllRows = rows
			if selectedAllJewelsView.id == "bestPerSocket" then
				rows = filterBestPerSocket(rows)
			end
		elseif cache.mode == "findAll" then
			lastFindAllRows = rows
			if selectedAllJewelsView.id == "bestPerSocket" then
				rows = filterBestPerSocket(rows)
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
	cancelComputeTask = function(statusMessage)
		if not computeContext then
			return
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
	local function selectedJewelSupportsComputeMethods()
		return selectedJewelType and selectedJewelType.computeMethods and #selectedJewelType.computeMethods > 0
	end
	local function hasVariantFamilies()
		if not selectedJewelType or not selectedJewelType.variants then return false end
		for _, v in ipairs(selectedJewelType.variants) do
			if v.family then return true end
		end
		return false
	end

	local function getDisplayedVariants()
		if not selectedJewelType or not selectedJewelType.variants then
			return nil
		end
		if hasVariantFamilies() and selectedDreamFamily and selectedDreamFamily.value ~= "ALL" then
			local variants = { }
			for _, variant in ipairs(selectedJewelType.variants) do
				if variant.family == selectedDreamFamily.value then
					t_insert(variants, variant)
				end
			end
			return variants
		end
	return selectedJewelType.variants
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
		local previewVariant = previewVariantOverride or ((selectedTypeMatches and selectedJewelVariant) or jewelType.variants[1])
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
			or (controls.variantFamilySelect and controls.variantFamilySelect.dropped)
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
		for _, v in ipairs(variants) do
			t_insert(variantNames, makeVariantDropdownEntry(v))
		end
		controls.jewelVariantSelect:SetList(variantNames)
		local varIdx = 1
		if selectedJewelVariant then
			for i, variant in ipairs(variants) do
				if variant == selectedJewelVariant then
					varIdx = i
					break
				end
			end
		else
			varIdx = controls.jewelVariantSelect.selIndex or 1
		end
		if varIdx > #variants then
			varIdx = 1
		end
		controls.jewelVariantSelect.selIndex = varIdx
		selectedJewelVariant = variants[varIdx]
		saveFinderState()
	end

	-- ── Preview list (right panel) ────────────────────────────────────────────
	local previewListData = { }
	local resultDetailListData = { }
	local function updateResultDetails(row)
		wipeTable(resultDetailListData)
		if not row then
			t_insert(resultDetailListData, { height = 16, [1] = COL_META .. "Select a result to inspect its recommended nodes." })
			return
		end
		t_insert(resultDetailListData, { height = 16, [1] = "^7Socket: " .. (row.socketLabel or "(n/a)") })
		if row.variantLabel and row.variantLabel ~= "" then
			t_insert(resultDetailListData, { height = 16, [1] = "^7Variant: " .. row.variantLabel })
		end
		if row.replacedItemLabel then
			t_insert(resultDetailListData, { height = 16, [1] = "^7Replaces: " .. row.replacedItemLabel })
		else
			t_insert(resultDetailListData, { height = 16, [1] = "^7Socket state: Free socket" })
		end
		if row.points ~= nil then
			t_insert(resultDetailListData, { height = 16, [1] = "^7Total points: " .. tostring(row.points) })
		end
		if row.detailText and row.detailText ~= "" then
			t_insert(resultDetailListData, { height = 16, [1] = "^7Summary: " .. row.detailText })
		end
		local nodeEntries = row.resultNodes or row.topNodes
		if nodeEntries and #nodeEntries > 0 then
			t_insert(resultDetailListData, { height = 16, [1] = "" })
			t_insert(resultDetailListData, {
				height = 16,
				[1] = row.resultNodes and s_format("^7Recommended nodes (%d):", #nodeEntries)
					or s_format("^7Nodes in range (%d):", #nodeEntries),
			})
			for _, nodeEntry in ipairs(nodeEntries) do
				t_insert(resultDetailListData, {
					height = 16,
					[1] = "^xC8C8C8- " .. (nodeEntry.label or tostring(nodeEntry)),
					nodeId = nodeEntry.nodeId,
				})
			end
		else
			t_insert(resultDetailListData, { height = 16, [1] = "" })
			t_insert(resultDetailListData, { height = 16, [1] = COL_META .. "(no additional passive nodes)" })
		end
	end
	controls.previewList = new("TextListControl", TL, { 600, 70, 440, 210 },
		{ { x = 0, align = "LEFT" }, { x = 210, align = "LEFT" } }, previewListData)
	controls.previewList.shown = function()
		return not (controls.jewelTypeSelect and controls.jewelTypeSelect.dropped)
	end
	controls.resultDetailLabel = new("LabelControl", TL, { 600, 286, 0, 16 }, "^7Selection:")
	controls.resultDetailList = new("RadiusJewelDetailListControl", TL, { 600, 304, 440, 126 },
		{ { x = 0, align = "LEFT" } }, resultDetailListData, self.build, socketViewer)
	updateResultDetails(nil)

	local function updatePreview()
		wipeTable(previewListData)
		if controls.jewelTypeSelect and controls.jewelTypeSelect.dropped then
			return
		end
		if not selectedJewelType then
			t_insert(previewListData, { height = 16, [1] = COL_META .. "(no preview)" })
			return
		end
		if selectedJewelType.isAllJewels then
			t_insert(previewListData, { height = 16, [1] = "^7Evaluate all jewel types at once." })
			if selectedAllJewelsView.id == "bestPerSocket" then
				t_insert(previewListData, { height = 16, [1] = "^7Shows the single best jewel for each socket." })
			else
				t_insert(previewListData, { height = 16, [1] = "^7Results ranked globally by %/Pt." })
			end
			t_insert(previewListData, { height = 6,  [1] = "" })
			t_insert(previewListData, { height = 16, [1] = COL_META .. "Click Compute to start." })
			return
		end
		local lines = buildPreviewLinesForJewelType(selectedJewelType)
		if type(lines) ~= "table" then
			t_insert(previewListData, { height = 16, [1] = COL_META .. "(no preview)" })
			return
		end
		for _, line in ipairs(lines) do
			t_insert(previewListData, line)
		end
	end

		-- ── Results list (left panel) ─────────────────────────────────────────────
		controls.resultsList = new("RadiusJewelResultsListControl", TL, { 10, 70, 580, 360 }, self.build, socketViewer)
		controls.resultsList.suppressTooltipFunc = isAnyFinderDropdownDropped
		controls.resultsList.OnSelect = function(_, _, row)
			updateResultDetails(row)
		end
		controls.resultsList:SetMode("message", { }, COL_META .. "Click Find to search")

	-- ── Helper: rebuild jewel type dropdown after filter change ──────────────
	local function rebuildJewelTypeDropdown()
		jewelTypes = buildJewelTypes(radiusIndexByLabel)
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
	controls.jewelTypeLabel = new("LabelControl", TL, { 10, 10, 0, 16 }, "^7Type:")

	controls.computeMethodLabel = new("LabelControl", TL, { 600, 10, 0, 16 }, "^7Method:")
	controls.computeMethodSelect = new("DropDownControl", TL, { 600, 26, 160, 20 }, { }, function(idx)
		cancelComputeTask()
		if selectedJewelType and selectedJewelType.computeMethods then
			selectedComputeMethod = selectedJewelType.computeMethods[idx]
		end
		saveFinderState()
	end)
	controls.computeMethodLabel.shown = false
	controls.computeMethodSelect.shown = false

	-- Impact stat selector (shown when jewel has compute)
	controls.impactStatLabel = new("LabelControl", TL, { 820, 10, 0, 16 }, "^7Stat:")
	controls.impactStatSelect = new("DropDownControl", TL, { 820, 26, 140, 20 }, impactStatLabels, function(idx)
		cancelComputeTask()
		selectedImpactStat = IMPACT_STATS[idx]
		saveFinderState()
	end)
	controls.impactStatLabel.shown = true
	controls.impactStatSelect.shown = true

	controls.maxPointsLabel = new("LabelControl", TL, { 120, 444, 0, 16 }, "^7Max pts:")
	controls.maxPointsEdit = new("EditControl", TL, { 182, 442, 56, 20 }, "", nil, "%D", 3, function(buf)
		cancelComputeTask()
		selectedMaxPoints = buf ~= "" and tonumber(buf) or nil
		saveFinderState()
	end)
	controls.maxPointsLabel.shown = true
	controls.maxPointsEdit.shown = true

	controls.occupiedModeLabel = new("LabelControl", TL, { 250, 444, 0, 16 }, "^7Sockets:")
	controls.occupiedModeSelect = new("DropDownControl", TL, { 308, 442, 170, 20 }, occupiedModeLabels, function(idx)
		cancelComputeTask()
		selectedOccupiedMode = OCCUPIED_SOCKET_OPTIONS[idx]
		saveFinderState()
		runFind(false)
	end)
	controls.occupiedModeLabel.shown = true
	controls.occupiedModeSelect.shown = true

	-- All-jewels view mode selector
	controls.allJewelsViewLabel = new("LabelControl", TL, { 278, 10, 0, 16 }, "^7View:")
	controls.allJewelsViewSelect = new("DropDownControl", TL, { 278, 26, 160, 20 }, allJewelsViewLabels, function(idx)
		selectedAllJewelsView = ALL_JEWELS_VIEW_OPTIONS[idx]
		local curMode = controls.resultsList.mode
		if curMode == "findAll" and lastFindAllRows then
			local displayRows = selectedAllJewelsView.id == "bestPerSocket"
				and filterBestPerSocket(lastFindAllRows) or lastFindAllRows
			controls.resultsList:SetMode("findAll", displayRows, COL_META .. "(no results)")
		elseif lastComputeAllRows then
			local displayRows = selectedAllJewelsView.id == "bestPerSocket"
				and filterBestPerSocket(lastComputeAllRows) or lastComputeAllRows
			controls.resultsList:SetMode("computeSocketAll", displayRows, COL_META .. "(no compatible sockets)")
		end
		saveFinderState()
	end)
	controls.allJewelsViewLabel.shown = false
	controls.allJewelsViewSelect.shown = false

		-- Thread ring selector (shown when Thread of Hope selected)
		controls.threadVariantLabel = new("LabelControl", TL, { 278, 10, 0, 16 }, "^7Preview ring:")
	controls.threadVariantSelect = new("DropDownControl", TL, { 278, 26, 200, 20 }, tvLabels, function(idx)
		cancelComputeTask()
		selectedThreadVariant = threadVariants[idx]
		saveFinderState()
		updatePreview()
		runFind(false)
	end)
		controls.threadVariantLabel.shown = false
		controls.threadVariantSelect.shown = false

		controls.variantFamilyLabel = new("LabelControl", TL, { 550, 10, 0, 16 }, "^7Family:")
		controls.variantFamilySelect = new("DropDownControl", TL, { 550, 26, 220, 20 }, {
			"All",
			"Red Dream",
			"Red Nightmare",
			"Green Dream",
			"Green Nightmare",
			"Blue Dream",
			"Blue Nightmare",
		}, function(idx)
			cancelComputeTask()
			selectedDreamFamily = dreamFamilyOptions[idx]
			controls.jewelVariantSelect.selIndex = 1
			selectedJewelVariant = nil
			syncDisplayedVariants()
			saveFinderState()
			updatePreview()
			runFind(false)
		end)
		controls.variantFamilyLabel.shown = false
		controls.variantFamilySelect.shown = false

		-- Jewel variant selector (shown when jewel type has built-in variants)
		controls.jewelVariantLabel = new("LabelControl", TL, { 278, 10, 0, 16 }, "^7Variant:")
		controls.jewelVariantSelect = new("DropDownControl", TL, { 278, 26, 260, 20 }, {}, function(idx)
			cancelComputeTask()
			local variants = getDisplayedVariants()
			if variants then
				selectedJewelVariant = variants[idx]
				saveFinderState()
				updatePreview()
			end
		end)
		controls.jewelVariantSelect.enableDroppedWidth = true
		controls.jewelVariantSelect.maxDroppedWidth = 520
		controls.jewelVariantLabel.shown = false
		controls.jewelVariantSelect.shown = false

		local function syncSelectedJewelTypeControls()
			if selectedJewelType.isAllJewels then
				controls.allJewelsViewLabel.shown  = true
				controls.allJewelsViewSelect.shown = true
				controls.threadVariantLabel.shown  = false
				controls.threadVariantSelect.shown = false
				controls.variantFamilyLabel.shown  = false
				controls.variantFamilySelect.shown = false
				controls.jewelVariantLabel.shown   = false
				controls.jewelVariantSelect.shown  = false
				controls.computeMethodLabel.shown  = false
				controls.computeMethodSelect.shown = false
				controls.impactStatLabel.shown     = true
				controls.impactStatSelect.shown    = true
				if controls.computeButton then
					controls.computeButton.shown = true
				end
				if controls.findButton then
					controls.findButton.shown = true
				end
				selectedJewelVariant = nil
				return
			end
			controls.allJewelsViewLabel.shown  = false
			controls.allJewelsViewSelect.shown = false
			local isThread = selectedJewelType.isThread == true
			local hasVariants = selectedJewelType.variants ~= nil
			local hasVariantFamilyFilter = hasVariantFamilies()
			local hasComputeMethods = selectedJewelSupportsComputeMethods()

			controls.threadVariantLabel.shown  = isThread
			controls.threadVariantSelect.shown = isThread
			controls.variantFamilyLabel.shown  = hasVariantFamilyFilter
			controls.variantFamilySelect.shown = hasVariantFamilyFilter
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
				if not hasVariantFamilyFilter then
					selectedDreamFamily = dreamFamilyOptions[1]
					controls.variantFamilySelect.selIndex = 1
				end
				syncDisplayedVariants()
			else
				selectedJewelVariant = nil
			end
			if hasComputeMethods then
				local methodLabels = { }
				for _, method in ipairs(selectedJewelType.computeMethods) do
					t_insert(methodLabels, method.label)
				end
				local selectedIndex = 1
				for i, method in ipairs(selectedJewelType.computeMethods) do
					if selectedComputeMethod and method.id == selectedComputeMethod.id then
						selectedIndex = i
						break
					end
				end
				selectedComputeMethod = selectedJewelType.computeMethods[selectedIndex]
				controls.computeMethodSelect:SetList(methodLabels)
				controls.computeMethodSelect.selIndex = selectedIndex
			end
	end

	-- Jewel type dropdown (defined after variant controls so :Click() is safe)
	controls.jewelTypeSelect = new("DropDownControl", TL, { 10, 26, 260, 20 }, jtLabels, function(idx)
		cancelComputeTask()
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
			tooltip:AddLine(16, "^7Results ranked globally by %%/Pt.")
			return
		end
		addPreviewLinesToTooltip(tooltip, buildGenericTypeTooltipLinesForJewelType(jewelType))
	end
	controls.jewelVariantSelect.tooltipFunc = function(tooltip, mode, index)
		local variants = getDisplayedVariants()
		local variant = variants and variants[index]
		if not selectedJewelType or not variant then
			return
		end
		addPreviewLinesToTooltip(tooltip, buildPreviewLinesForJewelType(selectedJewelType, variant))
	end
	controls.threadVariantSelect.tooltipFunc = function(tooltip, mode, index)
		local variant = threadVariants[index]
		if not selectedJewelType or not variant then
			return
		end
		addPreviewLinesToTooltip(tooltip, buildPreviewLinesForJewelType(selectedJewelType, variant))
	end
	syncSelectedJewelTypeControls()

	-- Compute button: socket ranking with best variant per socket
	-- Results go into the left panel (resultListData); jewel preview stays intact.
	local function makeComputeProgressTracker()
		local tracker
		local function setFraction(self, fraction, label)
			local clamped = math.max(0, math.min(fraction or 0, 1))
			if clamped < self.fraction then
				clamped = self.fraction
			end
			self.fraction = clamped
			local pct = math.floor(clamped * 100)
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
	local function buildComputeRows(jewelType, socketResults, baseline)
		local rows = { }
		for _, r in ipairs(socketResults) do
			local points = self:getSocketAccessCost(r.socket, { isOccupied = r.replacedItemLabel ~= nil })
			local variantLabel = r.variant and (r.variant.dropdownLabel or r.variant.name) or ""
			local itemTooltipLines = r.variant and buildPreviewLinesForJewelType(jewelType, r.variant) or nil
			local displayedPlans = (jewelType.name == "Intuitive Leap" or jewelType.isThread or jewelType.isImpossibleEscape)
				and buildDisplayedConnectionlessPlans(r, points, baseline)
				or { r }
			for _, plan in ipairs(displayedPlans) do
				local pct = calculateImpactPercent(plan.delta, baseline)
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
				t_insert(rows, {
					socketLabel = r.socket.label,
					socketId = r.socket.id,
					points = totalPoints,
					delta = plan.delta,
					pct = pct,
					pctPerPoint = totalPoints > 0 and (pct / totalPoints) or pct,
					sortPctPerPoint = totalPoints > 0 and (pct / totalPoints) or (pct >= 0 and math.huge or -math.huge),
					detailText = detailText,
					detailNodeId = detailNodeId,
					resultNodes = plan.resultNodes,
					resultNodeLabels = plan.resultNodeLabels,
					replacedItemLabel = r.replacedItemLabel,
					itemTooltipLines = itemTooltipLines,
					baseOutput = plan.baseOutput,
					compareOutput = plan.compareOutput,
					jewelName = jewelType.name,
					applyRawText = r.variant and r.variant.rawText or jewelType.rawText,
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

	controls.computeButton = new("ButtonControl", TL, { 968, 26, 72, 20 }, "Compute", function()
		if computeContext then
			cancelComputeTask("^8Compute cancelled")
			restoreCachedResults()
			return
		end

		controls.computeButton.label = "Cancel"
		setComputeProgress("^7Computing...")
		local progress = makeComputeProgressTracker()
		computeContext = {
			co = coroutine.create(function()
				local ok, err = pcall(function()
			local statLabel = selectedImpactStat.label
			local computeMethod = selectedComputeMethod or findConnectionlessComputeMethod(nil)
			local computeMethodLabel = selectedJewelSupportsComputeMethods() and computeMethod.label or nil

			if selectedJewelType.isAllJewels then
				local allRows = { }
				local globalBaseline

				local computableTypes = { }
				for _, jt in ipairs(activeJewelTypes) do
					if not jt.isAllJewels and jt.hasCompute then
						t_insert(computableTypes, jt)
					end
				end

				for typeIndex, jt in ipairs(computableTypes) do
					local rawChild = progress:child(
						(typeIndex - 1) / #computableTypes,
						1 / #computableTypes)
					local jtName = jt.name
					local typeProgress = {
						tick = function(self, done, total, label)
							rawChild:tick(done, total, label and (jtName .. " | " .. label) or jtName)
						end,
						child = function(self, startFraction, spanFraction)
							local inner = rawChild:child(startFraction, spanFraction)
							return {
								tick = function(_, done, total, label)
									inner:tick(done, total, label and (jtName .. " | " .. label) or jtName)
								end,
								child = function(_, s, sp) return inner:child(s, sp) end,
							}
						end,
					}
					local socketResults, baseline

					if jt.name == "Intuitive Leap" then
						socketResults, baseline =
							self:computeIntuitiveLeapSocketImpact(jewelSockets, selectedImpactStat, nil,
								computeMethod.id, finderState.connectionlessPlanCache, typeProgress, selectedMaxPoints, selectedOccupiedMode)
					elseif jt.isThread then
						socketResults, baseline =
							self:computeThreadOfHopeSocketImpact(jewelSockets, selectedImpactStat, threadVariants,
								computeMethod.id, finderState.connectionlessPlanCache, typeProgress, selectedMaxPoints, selectedOccupiedMode)
					elseif jt.isImpossibleEscape then
						socketResults, baseline =
							self:computeImpossibleEscapeSocketImpact(jewelSockets, selectedImpactStat,
								jt.variants or getImpossibleEscapeVariants(),
								computeMethod.id, finderState.connectionlessPlanCache, typeProgress, selectedMaxPoints, selectedOccupiedMode)
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

					local typeRows = buildComputeRows(jt, socketResults, baseline)

					-- For connectionless types: keep only the best row per socket
					if jt.name == "Intuitive Leap" or jt.isThread or jt.isImpossibleEscape then
						local bestBySocket = { }
						for _, row in ipairs(typeRows) do
							local ex = bestBySocket[row.socketId]
							if not ex or row.sortPctPerPoint > ex.sortPctPerPoint then
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
					and filterBestPerSocket(allRows) or allRows
				controls.resultsList:SetMode("computeSocketAll", displayRows, COL_META .. "(no compatible sockets)")
				controls.statusLabel.label = formatComputeStatus("All jewels", statLabel, globalBaseline, computeMethodLabel)
				saveResultCache("compute", "computeSocketAll", allRows, COL_META .. "(no compatible sockets)", controls.statusLabel.label, true)
			else
					local displayedVariants = getDisplayedVariants()
					local itemLabel = selectedJewelType.name
					local socketResults, baseline
					if selectedJewelType.name == "Intuitive Leap" then
						socketResults, baseline =
							self:computeIntuitiveLeapSocketImpact(jewelSockets, selectedImpactStat, selectedJewelVariant, computeMethod.id, finderState.connectionlessPlanCache, progress, selectedMaxPoints, selectedOccupiedMode)
					elseif selectedJewelType.isThread then
						socketResults, baseline =
							self:computeThreadOfHopeSocketImpact(jewelSockets, selectedImpactStat, threadVariants, computeMethod.id, finderState.connectionlessPlanCache, progress, selectedMaxPoints, selectedOccupiedMode)
					elseif selectedJewelType.isImpossibleEscape then
						socketResults, baseline =
							self:computeImpossibleEscapeSocketImpact(jewelSockets, selectedImpactStat, displayedVariants or getImpossibleEscapeVariants(), computeMethod.id, finderState.connectionlessPlanCache, progress, selectedMaxPoints, selectedOccupiedMode)
					elseif selectedJewelType.isSplitPersonality then
						socketResults, baseline =
							self:computeSplitPersonalitySocketImpact(jewelSockets, selectedImpactStat, displayedVariants or getSplitPersonalityVariants(), progress, selectedMaxPoints, selectedOccupiedMode)
					elseif displayedVariants and #displayedVariants > 0 then
						if hasVariantFamilies() and selectedDreamFamily and selectedDreamFamily.value ~= "ALL" then
							itemLabel = selectedDreamFamily.name
						end
						socketResults, baseline =
							self:computeBestVariantSocketImpact(jewelSockets, displayedVariants, selectedImpactStat, progress, selectedMaxPoints, selectedOccupiedMode)
					else
						local rawText = selectedJewelType.rawText
						socketResults, baseline =
							self:computeSocketImpact(jewelSockets, rawText, selectedImpactStat, progress, selectedMaxPoints, selectedOccupiedMode)
					end
					local rows = buildComputeRows(selectedJewelType, socketResults, baseline)
					controls.resultsList:SetMode("computeSocket", rows, COL_META .. "(no compatible sockets)")
					controls.statusLabel.label = formatComputeStatus(itemLabel, statLabel, baseline, computeMethodLabel)
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
				cancelComputeTask()
				controls.statusLabel.label = "^1Error: " .. tostring(errMsg)
				controls.resultsList:SetMode("message", {
					{ text = "^1" .. tostring(errMsg) },
				}, "^1Error")
				return
			end
			if coroutine.status(computeContext.co) == "dead" then
				cancelComputeTask()
			end
		end
	end)
	controls.computeButton.shown = true

	-- Status label
	controls.statusLabel = new("LabelControl", TL, { 10, 54, 400, 16 }, COL_META .. "Click Find to search")
	controls.showLegacyCheck = new("CheckBoxControl", TL, { 700, 54, 18 }, "Show legacy", function(state)
		cancelComputeTask()
		showLegacy = state
		saveFinderState()
		rebuildJewelTypeDropdown()
		syncSelectedJewelTypeControls()
		updatePreview()
		runFind(false)
	end)

	-- ── Find button ───────────────────────────────────────────────────────────
	runFind = function(makePreferred)
			if selectedJewelType and selectedJewelType.isAllJewels then
				controls.statusLabel.label = "^7Searching all jewels..."
				local ok, err = pcall(function()
					local allocNodes = self.build.spec.allocNodes
					local allRows = { }

					for _, jt in ipairs(activeJewelTypes) do
						if jt.isAllJewels then goto continueType end

						local typeResults = { }

						if jt.isThread then
							-- Thread of Hope: best ring per socket
							for _, socket in ipairs(jewelSockets) do
								local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, selectedOccupiedMode)
								local socketNode = treeData.nodes[socket.id]
								if socketAllowed and socketNode and socketNode.nodesInRadius then
									local best
									for _, tv in ipairs(threadVariants) do
										local nodes = socketNode.nodesInRadius[tv.radiusIndex]
										if nodes then
											local score = jt.score(nodes, allocNodes) or 0
											if not best or score > best.score then
												best = { socket = socket, score = score, variant = tv,
													replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil }
											end
										end
									end
									if best then t_insert(typeResults, best) end
								end
							end
						elseif jt.isImpossibleEscape then
							-- IE: find best keystone variant, score all sockets uniformly
							local smallRI = radiusIndexByLabel["Small"]
							local variants = jt.variants or { }
							local bestIE
							for _, variant in ipairs(variants) do
								local keystoneNode = treeData.keystoneMap[variant.keystoneName]
								local nodes = keystoneNode and keystoneNode.nodesInRadius and smallRI and keystoneNode.nodesInRadius[smallRI]
								if nodes then
									local score = jt.score(nodes, allocNodes) or 0
									if not bestIE or score > bestIE.score then
										bestIE = { score = score, variant = variant }
									end
								end
							end
							if bestIE then
								for _, socket in ipairs(jewelSockets) do
									local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, selectedOccupiedMode)
									if socketAllowed then
										t_insert(typeResults, {
											socket = socket, score = bestIE.score,
											variant = bestIE.variant,
											detailText = bestIE.variant.name,
											replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
										})
									end
								end
							end
						elseif jt.isSplitPersonality then
							-- Split Personality: distance scoring
							for _, socket in ipairs(jewelSockets) do
								local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, selectedOccupiedMode)
								if socketAllowed then
									local score = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
									t_insert(typeResults, {
										socket = socket, score = score,
										detailText = s_format("dist %d", score),
										replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
									})
								end
							end
						elseif jt.variants then
							-- Type with variants: best non-Foulborn variant per socket
							local radiusIndex = jt.radiusIndex
							for _, socket in ipairs(jewelSockets) do
								local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, selectedOccupiedMode)
								local socketNode = treeData.nodes[socket.id]
								if socketAllowed and socketNode and socketNode.nodesInRadius then
									local best
									for _, variant in ipairs(jt.variants) do
										if not variant.isFoulborn then
											local vRadiusIndex = variant.radiusIndex or radiusIndex
											local nodes = vRadiusIndex and socketNode.nodesInRadius[vRadiusIndex]
											if nodes then
												local scoreFn = variant.score or jt.score
												local score = scoreFn(nodes, allocNodes) or 0
												if not best or score > best.score then
													best = { socket = socket, score = score, variant = variant,
														replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil }
												end
											end
										end
									end
									if best then t_insert(typeResults, best) end
								end
							end
						else
							-- Simple type: single radiusIndex + score
							local radiusIndex = jt.radiusIndex
							if radiusIndex then
								for _, socket in ipairs(jewelSockets) do
									local socketAllowed, occupancy = self:socketMatchesOccupiedMode(socket.id, selectedOccupiedMode)
									local socketNode = treeData.nodes[socket.id]
									if socketAllowed and socketNode and socketNode.nodesInRadius then
										local nodes = socketNode.nodesInRadius[radiusIndex]
										if nodes then
											local score = jt.score(nodes, allocNodes) or 0
											t_insert(typeResults, {
												socket = socket, score = score,
												replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
											})
										end
									end
								end
							end
						end

						-- Build rows from typeResults
						for _, r in ipairs(typeResults) do
							local points = self:getSocketAccessCost(r.socket, { isOccupied = r.replacedItemLabel ~= nil })
							local scorePerPoint = points > 0 and (r.score / points) or r.score
							local scorePerPointSort = points > 0 and scorePerPoint or (r.score >= 0 and math.huge or -math.huge)
							local detailText = r.detailText or ""
							if r.variant and detailText == "" then
								if jt.isThread then
									detailText = r.variant.name .. " Ring"
								else
									detailText = r.variant.name
								end
							end
							t_insert(allRows, {
								jewelName = jt.name,
								socketLabel = r.socket.label,
								socketId = r.socket.id,
								points = points,
								score = r.score or 0,
								scorePerPoint = scorePerPoint,
								scorePerPointSort = scorePerPointSort,
								detailText = detailText,
								replacedItemLabel = r.replacedItemLabel,
								applyRawText = (r.variant and r.variant.rawText) or jt.rawText,
							})
						end

						::continueType::
					end

					t_sort(allRows, function(a, b) return a.scorePerPointSort > b.scorePerPointSort end)
					lastFindAllRows = allRows
					local displayRows = selectedAllJewelsView.id == "bestPerSocket"
						and filterBestPerSocket(allRows) or allRows
					controls.resultsList:SetMode("findAll", displayRows, COL_META .. "(no results)")
					controls.statusLabel.label = s_format("^7All jewels | %d results | score/pt", #allRows)
					saveResultCache("find", "findAll", allRows, COL_META .. "(no results)", controls.statusLabel.label, makePreferred)
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
				-- The full Massive radius doesn't exist natively; we handle it below.
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
					local variants = getDisplayedVariants() or selectedJewelType.variants or { }
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
										replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
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
								replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
							})
						elseif isSplitPersonalitySearch then
							local score = socket.classStartDist or self:getSocketDistanceToClassStart(socket.id)
							t_insert(results, {
								socket = socket,
								score = score,
								topNodes = { },
								detailText = s_format("dist to start %d", score),
								replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
							})
						else
							local nodes
							if isMassiveRadiusVariant then
								-- Construction manuelle du cercle complet "Massive" (2400)
								nodes = { }
								for idx, r in ipairs(data.jewelRadius) do
									if r.outer <= 2400 and socketNode.nodesInRadius[idx] then
										for nid, n in pairs(socketNode.nodesInRadius[idx]) do
											nodes[nid] = n
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
									detailText = detailBuilder and detailBuilder(nodes, allocNodes) or nil,
									replacedItemLabel = occupancy and occupancy.isOccupied and occupancy.itemLabel or nil,
								})
							end
						end
					end
				end

					t_sort(results, function(a, b) return (a.score or 0) > (b.score or 0) end)

					local rows = { }
					for _, r in ipairs(results) do
						local topLabels = buildNodeLabelList(r.topNodes)
						local topStr = t_concat(topLabels, ", ")
						if #topStr > 50 then
							topStr = topStr:sub(1, 47) .. "..."
						end

						local scoreLabel = (selectedJewelType.variants and selectedJewelVariant and selectedJewelVariant.scoreLabel)
							or selectedJewelType.scoreLabel
						local points = self:getSocketAccessCost(r.socket, { isOccupied = r.replacedItemLabel ~= nil })
						local scorePerPoint = points > 0 and (r.score / points) or r.score
						local scorePerPointSort = points > 0 and scorePerPoint or (r.score >= 0 and math.huge or -math.huge)
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
						t_insert(rows, {
							socketLabel = r.socket.label,
							socketId = r.socket.id,
							points = points,
							score = r.score or 0,
							scorePerPoint = scorePerPoint,
							scorePerPointSort = scorePerPointSort,
							variantLabel = r.variant and (r.variant.name .. " Ring") or "",
							detailText = detailText,
							detailNodeId = detailNodeId,
							topNodes = copyTableSafe(r.topNodes, false, true),
							replacedItemLabel = r.replacedItemLabel,
							applyRawText = (r.variant and r.variant.rawText)
								or (selectedJewelVariant and selectedJewelVariant.rawText)
								or selectedJewelType.rawText,
						})
					end
					controls.resultsList:SetMode(isThreadBestVariantSearch and "findThread" or "find", rows, COL_META .. "(no results)")
					controls.statusLabel.label = isThreadBestVariantSearch
						and s_format("^7Thread of Hope | %d | score/pt", #results)
						or isImpossibleEscapeBestVariantSearch
						and s_format("^7Impossible Escape | %d | score/pt", #results)
						or isSplitPersonalitySearch
						and s_format("^7Split Personality | %d | score/pt", #results)
						or s_format("^7%d results | score/pt", #results)
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
		controls.findButton = new("ButtonControl", TL, { 10, 444, 100, 20 }, "Find", function()
			cancelComputeTask()
			runFind(true)
		end)

		controls.applyButton = new("ButtonControl", TL, { 490, 444, 80, 20 }, "Apply", function()
			local idx = controls.resultsList.selIndex
			local row = idx and controls.resultsList.list[idx]
			if not row or not row.applyRawText then return end

			local item = new("Item", "Rarity: Unique\n" .. row.applyRawText)
			item:BuildModList()
			self.build.itemsTab:AddItem(item, true)

			local slot = self.build.itemsTab.sockets[row.socketId]
			if slot then
				slot:SetSelItemId(item.id)
			end
			self.build.itemsTab:PopulateSlots()
			self.build.buildFlag = true
		end)

	local function restoreFinderState()
		if not finderState.jewelTypeName then
			updatePreview()
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

		if finderState.dreamFamilyValue then
			for i, option in ipairs(dreamFamilyOptions) do
				if option.value == finderState.dreamFamilyValue then
					selectedDreamFamily = option
					controls.variantFamilySelect.selIndex = i
					break
				end
			end
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
		if finderState.computeMethodId and selectedJewelType and selectedJewelType.computeMethods then
			for i, method in ipairs(selectedJewelType.computeMethods) do
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
					controls.jewelVariantSelect.selIndex = i
					break
				end
			end
		end

		suppressFinderStateSave = false
		saveFinderState()
		updatePreview()
		runFind(false)
	end

	-- Close button
	controls.closeButton = new("ButtonControl", TL, { 950, 444, 100, 20 }, "Close", function()
		cancelComputeTask()
		main:ClosePopup()
	end)

	-- Initialise preview and open popup
	restoreFinderState()
	return main:OpenPopup(1060, 474, "Find Radius Jewel", controls)
end
