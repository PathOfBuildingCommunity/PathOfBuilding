-- Path of Building
--
-- Class: Timeless Jewel Readable List Control
-- Specialized UI element for listing Timeless Jewel search results in a readable format.
--

local ipairs = ipairs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local t_concat = table.concat

local ROW_HEIGHT = 42
local HEADER_TEXT_HEIGHT = 16
local SUMMARY_TEXT_HEIGHT = 12
local ROW_PADDING_X = 8
local SUMMARY_PADDING_X = 18
local TOTAL_TEXT = "Total weight "

local TimelessJewelReadableListControlClass = newClass("TimelessJewelReadableListControl", "TimelessJewelListControl", function(self, anchor, rect, build)
	self.TimelessJewelListControl(anchor, rect, build)
	self.rowHeight = ROW_HEIGHT
	self.defaultText = "^8Run a search to see matching jewels."
end)

local function getResultSocketLabel(data)
	if not data.socketLabel or data.socketLabel == "" then
		return ""
	end
	if tonumber(data.socketLabel) == 54127 then
		return "#Duelist"
	end
	local socketLabel = data.socketLabel:gsub("^#%s*", "#"):gsub(":%s*%d+$", "")
	if socketLabel:match("^#") then
		return socketLabel
	end
	return socketLabel
end

function TimelessJewelReadableListControlClass:GetRowValue(column, index, data)
	local socketLabel = getResultSocketLabel(data)
	return socketLabel ~= "" and ("^8" .. socketLabel .. " - Seed ^7" .. data.seed) or ("^8Seed ^7" .. data.seed)
end

function TimelessJewelReadableListControlClass:GetRowTotalText(data)
	return "Total Weight ", string.format("%.2f", data.total or 0)
end

local function clipText(text, height, font, maxWidth)
	local out = StripEscapes(text or "")
	if DrawStringWidth(height, font, out) <= maxWidth then
		return text
	end
	local clipWidth = DrawStringWidth(height, font, "...")
	local clipIndex = DrawStringCursorIndex(height, font, out, maxWidth - clipWidth, 0)
	return out:sub(1, clipIndex - 1) .. "..."
end

local function getReadableNodeSummary(readableNodes)
	local summaryNodes = { }
	for _, nodeData in ipairs(readableNodes or { }) do
		local count = nodeData.targetNodeNames and #nodeData.targetNodeNames or 0
		if count > 0 then
			summaryNodes[#summaryNodes + 1] = {
				displayName = nodeData.displayName,
				count = count,
				totalWeight = nodeData.totalWeight or 0,
			}
		end
	end
	table.sort(summaryNodes, function(a, b)
		if a.count == b.count then
			if a.totalWeight == b.totalWeight then
				return a.displayName < b.displayName
			end
			return a.totalWeight > b.totalWeight
		end
		return a.count > b.count
	end)
	local parts = { }
	local maxShown = m_min(4, #summaryNodes)
	for index = 1, maxShown do
		local nodeData = summaryNodes[index]
		parts[#parts + 1] = nodeData.displayName .. " x" .. nodeData.count
	end
	if #summaryNodes > maxShown then
		parts[#parts + 1] = "+" .. (#summaryNodes - maxShown) .. " more"
	end
	return t_concat(parts, ", ")
end

function TimelessJewelReadableListControlClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local rowHeight = self.rowHeight
	local list = self.list

	local scrollBarV = self.controls.scrollBarV
	local rowRegion = self:GetRowRegion()
	scrollBarV:SetContentDimension(#list * rowHeight, rowRegion.height)
	local scrollOffsetV = scrollBarV.offset

	local cursorX, cursorY = GetCursorPos()
	local ttIndex, ttValue, ttX, ttY, ttWidth

	if self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort, (noTooltip and not self.forceTooltip) and self)

	SetViewport(x + rowRegion.x, y + rowRegion.y, rowRegion.width, rowRegion.height)
	local minIndex = m_floor(scrollOffsetV / rowHeight + 1)
	local maxIndex = m_min(m_floor((scrollOffsetV + rowRegion.height) / rowHeight + 1), #list)
	for index = minIndex, maxIndex do
		local value = list[index]
		local lineY = rowHeight * (index - 1) - scrollOffsetV
		local rowWidth = rowRegion.width
		local relX = cursorX - (x + rowRegion.x)
		local relY = cursorY - (y + rowRegion.y)
		local isHover = relX >= 0 and relX < rowWidth and relY >= lineY and relY < lineY + rowHeight
		local isSelected = value == self.selValue
		local inHighlightRange = self.highlightIndex and self.selIndex and m_min(self.selIndex, self.highlightIndex) <= index and m_max(self.selIndex, self.highlightIndex) >= index
		local isEndpoint = inHighlightRange and (self.selIndex == index or self.highlightIndex == index)

		if isHover then
			ttIndex = index
			ttValue = value
			ttX = x + rowRegion.x + 8
			ttY = y + rowRegion.y + lineY + 4
			ttWidth = rowWidth - 16
		end

		SetDrawColor(0.08, 0.08, 0.08)
		DrawImage(nil, 0, lineY, rowWidth, rowHeight - 1)
		if isSelected then
			SetDrawColor(0.22, 0.22, 0.22)
			DrawImage(nil, 0, lineY, rowWidth, rowHeight - 1)
			SetDrawColor(1, 1, 1)
		elseif isEndpoint then
			SetDrawColor(0.18, 0.14, 0.08)
			DrawImage(nil, 0, lineY, rowWidth, rowHeight - 1)
			SetDrawColor(1, 0.5, 0)
		elseif inHighlightRange then
			SetDrawColor(0.16, 0.16, 0.08)
			DrawImage(nil, 0, lineY, rowWidth, rowHeight - 1)
			SetDrawColor(1, 1, 0)
		elseif isHover then
			SetDrawColor(0.13, 0.13, 0.13)
			DrawImage(nil, 0, lineY, rowWidth, rowHeight - 1)
			SetDrawColor(0.75, 0.75, 0.75)
		else
			SetDrawColor(0.45, 0.45, 0.45)
		end
		DrawImage(nil, 0, lineY + rowHeight - 2, rowWidth, 1)

		local summary = self:GetRowValue(1, index, value)
		local totalLabel, totalValue = self:GetRowTotalText(value)
		local totalText = totalLabel .. totalValue
		local totalWidth = DrawStringWidth(HEADER_TEXT_HEIGHT, "VAR BOLD", totalText)
		local totalX = rowWidth - totalWidth - ROW_PADDING_X
		if value.label and value.label:match("B2B2B2") then
			summary = "^xB2B2B2" .. StripEscapes(summary)
		end
		DrawString(ROW_PADDING_X, lineY + 4, "LEFT", HEADER_TEXT_HEIGHT, "VAR BOLD", clipText(summary, HEADER_TEXT_HEIGHT, "VAR BOLD", totalX - 20))
		DrawString(totalX, lineY + 4, "LEFT", HEADER_TEXT_HEIGHT, "VAR BOLD", "^8" .. totalLabel .. "^7" .. totalValue)

		local readableNodes = value.readableNodes or { }
		local summaryLine = readableNodes[1] and ("^8" .. clipText(getReadableNodeSummary(readableNodes), SUMMARY_TEXT_HEIGHT, "VAR", rowWidth - 24)) or "^8No matched node types"
		DrawString(SUMMARY_PADDING_X, lineY + 23, "LEFT", SUMMARY_TEXT_HEIGHT, "VAR", summaryLine)
	end

	if #self.list == 0 and self.defaultText then
		SetDrawColor(1, 1, 1)
		DrawString(8, 8, "LEFT", 14, "VAR", self.defaultText)
	end
	SetViewport()

	self.hoverIndex = ttIndex
	self.hoverValue = ttValue
	if ttIndex and (not noTooltip or self.forceTooltip) then
		SetDrawLayer(nil, 100)
		self:AddValueTooltip(self.tooltip, ttIndex, ttValue)
		self.tooltip:Draw(ttX, ttY, ttWidth, rowHeight, viewPort)
		SetDrawLayer(nil, 0)
	end
end

function TimelessJewelReadableListControlClass:AddValueTooltip(tooltip, index, data)
	tooltip:Clear()
	if data.label and data.label:match("B2B2B2") == nil then
		tooltip:AddLine(16, "^7Double click to add this jewel to your build.")
	else
		tooltip:AddLine(16, "^7" .. self.sharedList.type.label .. " " .. data.seed .. " was successfully added to your build.")
	end
	if data.socketLabel then
		tooltip:AddLine(16, "^7Socket: " .. getResultSocketLabel(data))
	end
	if data.total > 0 then
		tooltip:AddLine(16, "^7Combined Node Weight: " .. data.total)
	end
	local readableNodes = copyTable(data.readableNodes or { }, true)
	table.sort(readableNodes, function(a, b)
		if (a.totalWeight or 0) == (b.totalWeight or 0) then
			return a.displayName < b.displayName
		end
		return (a.totalWeight or 0) > (b.totalWeight or 0)
	end)
	for _, readableNode in ipairs(readableNodes) do
		tooltip:AddLine(16, "^7" .. readableNode.displayName)
		for _, line in ipairs(readableNode.descriptions or { }) do
			tooltip:AddLine(16, "^8    " .. line)
		end
		if readableNode.totalWeight then
			tooltip:AddLine(16, "^7    Weight: " .. readableNode.totalWeight)
		end
		if readableNode.targetNodeNames and #readableNode.targetNodeNames > 0 then
			tooltip:AddLine(16, "^8    Matched nodes: " .. t_concat(readableNode.targetNodeNames, ", "))
		end
	end
end
