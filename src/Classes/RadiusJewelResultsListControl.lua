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

local function compareField(field, descending)
	return function(a, b)
		local aValue = a[field]
		local bValue = b[field]
		if aValue == bValue then return false end
		if aValue == nil then return false end
		if bValue == nil then return true end
		return descending and aValue > bValue or not descending and aValue < bValue
	end
end

local function column(width, label, getValue, sortField, descending, hoverRole)
	return {
		width = width,
		label = label,
		sortable = sortField ~= nil,
		getValue = getValue,
		compare = sortField and compareField(sortField, descending) or nil,
		hoverRole = hoverRole,
	}
end

local function findPerPoint(row)
	return row.points == 0 and (row.score > 0 and "^2Free" or "^8Free") or s_format("^7%.2f", row.scorePerPoint)
end

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
			column(rect[3] - 22, "", function(row) return row.text or "" end),
		},
		computeSocket = {
			column(170, "Socket", colorSocketLabel, "socketLabel", false, "socket"),
			column(50, "Points", function(row) return tostring(row.points) end, "points"),
			column(75, "Gain", function(row) return formatSignedValue(row.delta) end, "delta", true, "stat"),
			column(60, "%", function(row) return formatSignedPercent(row.pct) end, "pct", true, "stat"),
			column(65, "%/Pt", function(row) return formatPerPointDisplay(row.pctPerPoint, row.points) end, "sortValue", true, "stat"),
			column(140, "Detail", function(row) return row.detailText or "" end, "detailText", false, "detail"),
		},
		computeSocketAll = {
			column(120, "Jewel", function(row) return row.jewelName or "" end, "jewelName"),
			column(130, "Socket", colorSocketLabel, "socketLabel", false, "socket"),
			column(50, "Points", function(row) return tostring(row.points) end, "points"),
			column(75, "Gain", function(row) return formatSignedValue(row.delta) end, "delta", true, "stat"),
			column(60, "%", function(row) return formatSignedPercent(row.pct) end, "pct", true, "stat"),
			column(65, "%/Pt", function(row) return formatPerPointDisplay(row.pctPerPoint, row.points) end, "sortValue", true, "stat"),
			column(60, "Detail", function(row) return row.detailText or "" end, "detailText", false, "detail"),
		},
		find = {
			column(170, "Socket", colorSocketLabel, "socketLabel", false, "socket"),
			column(50, "Points", function(row) return tostring(row.points) end, "points"),
			column(60, "Score", function(row) return s_format("^7%d", row.score) end, "score", true),
			column(70, "/Pt", findPerPoint, "sortValue", true),
			column(210, "Detail", function(row) return row.detailText or "" end, "detailText", false, "detail"),
		},
		findThread = {
			column(170, "Socket", colorSocketLabel, "socketLabel", false, "socket"),
			column(50, "Points", function(row) return tostring(row.points) end, "points"),
			column(60, "Score", function(row) return s_format("^7%d", row.score) end, "score", true),
			column(70, "/Pt", findPerPoint, "sortValue", true),
			column(90, "Ring", function(row) return row.variantLabel or "" end, "variantLabel"),
			column(120, "Detail", function(row) return row.detailText or "" end, "detailText", false, "detail"),
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
	local columnInfo = hoverColumn and self.colList[hoverColumn]
	local hoverRole = columnInfo and columnInfo.hoverRole
	local detailColumn = hoverRole == "detail"
	local socketColumn = hoverRole == "socket"
	local showViewer = socketColumn or (detailColumn and hoverData and hoverData.detailNodeId)
	local showStatTooltip = hoverData and hoverData.baseOutput and hoverData.compareOutput
		and hoverRole == "stat"
	local showItemTooltip = hoverData and hoverData.itemTooltipLines
		and detailColumn
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
	local columnInfo = self.colList[colIndex]
	if columnInfo and columnInfo.compare then
		t_sort(self.list, columnInfo.compare)
	end
end

function RadiusJewelResultsListClass:GetRowValue(column, index, row)
	local columnInfo = self.colList[column]
	return columnInfo and columnInfo.getValue and columnInfo.getValue(row) or ""
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
