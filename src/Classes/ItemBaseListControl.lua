-- Path of Building
--
-- Class: Item Base List Control
-- List control for selecting item base types and bases.
--

local t_insert = table.insert

local headerFontSize = 16
local bodyFontSize = 14
local implicitTextOffset = 8
local headerHeight = 20

---@class ItemBaseListControl: ListControl
local ItemBaseListClass = newClass("ItemBaseListControl", "ListControl")

---@param anchor Anchor?
---@param rect Rect
---@param list table
---@param listMode "TYPE"|"BASE"
---@param baseColumnWidth number?
---@param onSelectCallback function?
---@param addValueTooltipCallback function?
function ItemBaseListClass:ItemBaseListControl(anchor, rect, list, listMode, baseColumnWidth, onSelectCallback, addValueTooltipCallback)
	self:ListControl(anchor, rect, 20, "VERTICAL", false, list)
	self.listMode = listMode
	self.onSelectCallback = onSelectCallback
	self.addValueTooltipCallback = addValueTooltipCallback
	self.colLabels = true
	self.colLabelHeight = headerHeight
	self.showRowSeparators = true

	local contentWidth = rect[3] - 20
	if listMode == "TYPE" then
		self.colList = {
			{ label = "Type", width = contentWidth, headerFontSize = headerFontSize, fontSize = bodyFontSize },
		}
	elseif listMode == "BASE" then
		assert(baseColumnWidth, "Base mode requires a base column width")
		self.defaultText = "^x7F7F7F<No Matches>"
		self.forceTooltip = true
		self.tooltipAnchorFullRow = true
		self.colList = {
			{ label = "Base", width = baseColumnWidth, headerFontSize = headerFontSize, fontSize = bodyFontSize },
			{ label = "Implicit", width = contentWidth - baseColumnWidth, textOffset = implicitTextOffset, headerFontSize = headerFontSize, fontSize = bodyFontSize },
		}
	else
		error("Invalid item base list mode: " .. tostring(listMode))
	end
	return self
end

function ItemBaseListClass:GetRowValue(column, index, value)
	if self.listMode == "TYPE" then
		return value
	elseif column == 1 then
		return value.name
	end

	local implicitLines = { }
	if value.base.implicit then
		for line in value.base.implicit:gmatch("[^\n]+") do
			t_insert(implicitLines, line)
		end
	end
	return #implicitLines > 0 and table.concat(implicitLines, " / ") or "None"
end

function ItemBaseListClass:OnSelect(index, value)
	if self.onSelectCallback then
		self.onSelectCallback(index, value)
	end
end

-- Wheel input is handled on hover, including while the search field has focus.
function ItemBaseListClass:OnKeyUp(key)
	if key == "WHEELDOWN" or key == "WHEELUP" then
		return self
	end
	return self.ListControl.OnKeyUp(self, key)
end

function ItemBaseListClass:OnHoverKeyUp(key)
	if key == "WHEELDOWN" or key == "WHEELUP" then
		self.ListControl.OnKeyUp(self, key)
	end
end

function ItemBaseListClass:AddValueTooltip(tooltip, index, value)
	if self.addValueTooltipCallback then
		self.addValueTooltipCallback(tooltip, index, value)
	else
		tooltip:Clear(true)
	end
end

function ItemBaseListClass:SetList(list)
	self.list = list
	self.selIndex = nil
	self.selValue = nil
	self.controls.scrollBarV:SetOffset(0)
end
