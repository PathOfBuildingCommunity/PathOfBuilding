-- Path of Building
--
-- Class: Radius Jewel Results List Control
-- Displays and previews ranked Radius Jewel Finder results.
--

local ipairs = ipairs
local t_insert = table.insert
local t_sort = table.sort
local s_format = string.format

local placeTooltip = LoadModule("Classes/RadiusJewelTooltipPlacement").placeTooltip

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

local ACTION_COLORS = {
	equip    = "^2",
	move     = "^x33AAFF",
	replace  = "^xFFAA33",
	equipped = "^8",
}
local function colorSocketLabel(row)
	return (row.action and ACTION_COLORS[row.action] or "") .. row.socketLabel
end

local RESULT_DETAIL_COLUMN_BY_MODE = {
	computeSocket = 6,
	computeSocketAll = 7,
	find = 5,
	findThread = 6,
}
local RESULT_SOCKET_COLUMN_BY_MODE = {
	computeSocket = 1,
	computeSocketAll = 2,
	find = 1,
	findThread = 1,
}
local RESULT_STAT_COLUMNS_BY_MODE = {
	computeSocket = { [3] = true, [4] = true, [5] = true },
	computeSocketAll = { [4] = true, [5] = true, [6] = true },
}
local RESULT_ITEM_COLUMNS_BY_MODE = {
	computeSocket = { [6] = true },
	computeSocketAll = { [7] = true },
	find = { [5] = true },
	findThread = { [6] = true },
}

---@class RadiusJewelResultsListControl: ListControl
local RadiusJewelResultsListClass = newClass("RadiusJewelResultsListControl", "ListControl")

function RadiusJewelResultsListClass:RadiusJewelResultsListControl(anchor, rect, build, socketViewer)
	self:ListControl(anchor, rect, 16, "VERTICAL", false)
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
			{ width = 50, label = "Points", sortable = true },
			{ width = 75, label = "Gain", sortable = true },
			{ width = 60, label = "%", sortable = true },
			{ width = 65, label = "%/Pt", sortable = true },
			{ width = 140, label = "Detail", sortable = true },
		},
		computeSocketAll = {
			{ width = 120, label = "Jewel", sortable = true },
			{ width = 130, label = "Socket", sortable = true },
			{ width = 50, label = "Points", sortable = true },
			{ width = 75, label = "Gain", sortable = true },
			{ width = 60, label = "%", sortable = true },
			{ width = 65, label = "%/Pt", sortable = true },
			{ width = 60, label = "Detail", sortable = true },
		},
		find = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 50, label = "Points", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 70, label = "/Pt", sortable = true },
			{ width = 210, label = "Detail", sortable = true },
		},
		findThread = {
			{ width = 170, label = "Socket", sortable = true },
			{ width = 50, label = "Points", sortable = true },
			{ width = 60, label = "Score", sortable = true },
			{ width = 70, label = "/Pt", sortable = true },
			{ width = 90, label = "Ring", sortable = true },
			{ width = 120, label = "Detail", sortable = true },
		},
	}
	self.defaultSortByMode = {
		computeSocket = 5,
		computeSocketAll = 6,
		find = 4,
		findThread = 4,
	}
	self.resultTooltip = new("Tooltip"):Tooltip()
	self.itemTooltip = new("Tooltip"):Tooltip()
	return self
end

function RadiusJewelResultsListClass:SetMode(mode, list, defaultText)
	self.mode = mode or "message"
	self.list = list or { }
	self.defaultText = defaultText or ""
	self.colList = self.columnsByMode[self.mode] or self.columnsByMode.message
	self.colLabels = self.mode ~= "message" and #self.list > 0
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

function RadiusJewelResultsListClass:GetHoverInfo(hoverColumn, hoverData)
	local detailColumn = hoverColumn and RESULT_DETAIL_COLUMN_BY_MODE[self.mode] == hoverColumn
	local socketColumn = hoverColumn and RESULT_SOCKET_COLUMN_BY_MODE[self.mode] == hoverColumn
	local showViewer = socketColumn or (detailColumn and hoverData and hoverData.detailNodeId)
	local showStatTooltip = hoverData and hoverData.baseOutput and hoverData.compareOutput
		and hoverColumn and RESULT_STAT_COLUMNS_BY_MODE[self.mode] and RESULT_STAT_COLUMNS_BY_MODE[self.mode][hoverColumn]
	local showItemTooltip = hoverData and hoverData.itemTooltipLines
		and hoverColumn and RESULT_ITEM_COLUMNS_BY_MODE[self.mode] and RESULT_ITEM_COLUMNS_BY_MODE[self.mode][hoverColumn]
	local hoverNodeId = hoverData and hoverData.socketId or nil
	if hoverData and hoverData.detailNodeId and detailColumn then
		hoverNodeId = hoverData.detailNodeId
	end
	return {
		detailColumn = detailColumn,
		socketColumn = socketColumn,
		showViewer = showViewer,
		showStatTooltip = showStatTooltip,
		showItemTooltip = showItemTooltip,
		hoverNodeId = hoverNodeId,
	}
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
			t_sort(self.list, function(a, b) return a.sortValue > b.sortValue end)
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
			t_sort(self.list, function(a, b) return a.sortValue > b.sortValue end)
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
			t_sort(self.list, function(a, b) return a.sortValue > b.sortValue end)
		elseif colIndex == 5 then
			if self.mode == "findThread" then
				t_sort(self.list, function(a, b) return a.variantLabel < b.variantLabel end)
			else
				t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
			end
		elseif colIndex == 6 and self.mode == "findThread" then
			t_sort(self.list, function(a, b) return a.detailText < b.detailText end)
		end
	end
end

function RadiusJewelResultsListClass:GetRowValue(column, index, row)
	if self.mode == "message" then
		return column == 1 and row.text or ""
	elseif self.mode == "computeSocket" then
		return column == 1 and colorSocketLabel(row)
			or column == 2 and tostring(row.points)
			or column == 3 and formatSignedValue(row.delta)
			or column == 4 and formatSignedPercent(row.pct)
			or column == 5 and formatPerPointDisplay(row.pctPerPoint, row.points)
			or column == 6 and row.detailText
			or ""
	elseif self.mode == "computeSocketAll" then
		return column == 1 and row.jewelName
			or column == 2 and colorSocketLabel(row)
			or column == 3 and tostring(row.points)
			or column == 4 and formatSignedValue(row.delta)
			or column == 5 and formatSignedPercent(row.pct)
			or column == 6 and formatPerPointDisplay(row.pctPerPoint, row.points)
			or column == 7 and row.detailText
			or ""
	elseif self.mode == "find" then
		return column == 1 and colorSocketLabel(row)
			or column == 2 and tostring(row.points)
			or column == 3 and s_format("^7%d", row.score)
			or column == 4 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 5 and row.detailText
			or ""
	elseif self.mode == "findThread" then
		return column == 1 and colorSocketLabel(row)
			or column == 2 and tostring(row.points)
			or column == 3 and s_format("^7%d", row.score)
			or column == 4 and (row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint))
			or column == 5 and row.variantLabel
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
	local hoverInfo = self:GetHoverInfo(hoverColumn, hoverData)
	local viewerRect
	if hoverInfo.showViewer and hoverInfo.hoverNodeId then
		local node = self.build.spec.nodes[hoverInfo.hoverNodeId] or self.build.spec.tree.nodes[hoverInfo.hoverNodeId]
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
			self.socketViewer.searchStrResults[hoverInfo.hoverNodeId] = true
			SetViewport(viewerX + 2, viewerY + 2, 300, 300)
			self.socketViewer:Draw(self.build, { x = 0, y = 0, width = 300, height = 300 }, { })
			self.socketViewer.searchStrResults[hoverInfo.hoverNodeId] = nil
			SetDrawLayer(nil, 30)
			SetDrawColor(1, 1, 1, 0.2)
			DrawImage(nil, 149, 0, 2, 300)
			DrawImage(nil, 0, 149, 300, 2)
			SetViewport()
			SetDrawLayer(nil, 0)
		end
	end

	local blockedRectangles = { }
	if viewerRect then
		t_insert(blockedRectangles, viewerRect)
	end
	if hoverInfo.showStatTooltip then
		SetDrawLayer(nil, 100)
		self.resultTooltip:Clear()
		local count = self.build:AddStatComparesToTooltip(self.resultTooltip, hoverData.baseOutput, hoverData.compareOutput,
			hoverData.tooltipHeader or "^7Socketing this jewel will give you:")
		if count == 0 then
			self.resultTooltip:AddLine(14, "^7No stat changes for this result.")
		end
		local ttW, ttH = self.resultTooltip:GetSize()
		local ttX, ttY = placeTooltip(viewPort, ttW, ttH, cursorX, cursorY, blockedRectangles, true)
		self.resultTooltip:Draw(ttX, ttY, nil, nil, viewPort)
		t_insert(blockedRectangles, { x = ttX, y = ttY, width = ttW, height = ttH })
		SetDrawLayer(nil, 0)
	end
	if hoverInfo.showItemTooltip then
		SetDrawLayer(nil, 100)
		self.itemTooltip:Clear(true)
		for _, line in ipairs(hoverData.itemTooltipLines) do
			self.itemTooltip:AddLine(line.height or 16, line[1], line.font)
		end
		local itemTtW, itemTtH = self.itemTooltip:GetSize()
		local itemTtX, itemTtY = placeTooltip(viewPort, itemTtW, itemTtH, cursorX, cursorY, blockedRectangles, true)
		self.itemTooltip:Draw(itemTtX, itemTtY, nil, nil, viewPort)
		SetDrawLayer(nil, 0)
	end
end
