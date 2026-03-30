-- Path of Building
--
-- Class: Compare Power Report List
-- List control for the compare power report in the Summary tab.
--

local t_insert = table.insert
local t_sort = table.sort

local ComparePowerReportListClass = newClass("ComparePowerReportListControl", "ListControl", function(self, anchor, rect)
	self.ListControl(anchor, rect, 18, "VERTICAL", false)

	local width = rect[3]
	self.impactColumn = { width = width * 0.22, label = "", sortable = true }
	self.colList = {
		{ width = width * 0.10, label = "Category", sortable = true },
		{ width = width * 0.44, label = "Name" },
		self.impactColumn,
		{ width = width * 0.08, label = "Points", sortable = true },
		{ width = width * 0.16, label = "Per Point", sortable = true },
	}
	self.colLabels = true
	self.showRowSeparators = true
	self.statusText = "Select a metric above to generate the power report."
end)

function ComparePowerReportListClass:SetReport(stat, report)
	self.impactColumn.label = stat and stat.label or ""
	self.reportData = report or {}

	if stat and stat.stat then
		if report and #report > 0 then
			self.statusText = nil
		else
			self.statusText = "No differences found."
		end
	else
		self.statusText = "Select a metric above to generate the power report."
	end

	self:ReList()
	self:ReSort(3)
end

function ComparePowerReportListClass:SetProgress(progress)
	if progress < 100 then
		self.statusText = "Calculating... " .. progress .. "%"
		self.list = {}
	end
end

function ComparePowerReportListClass:Draw(viewPort, noTooltip)
	if self.hoverIndex ~= self.lastTooltipIndex then
		self.tooltip.updateParams = nil
	end
	self.lastTooltipIndex = self.hoverIndex
	self.ListControl.Draw(self, viewPort, noTooltip)
	-- Draw status text below column headers when the list is empty
	if #self.list == 0 and self.statusText then
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		-- Column headers are 18px tall, plus 2px border = start at y+20
		SetViewport(x + 2, y + 20, width - 20, height - 22)
		SetDrawColor(1, 1, 1)
		DrawString(4, 4, "LEFT", 14, "VAR", self.statusText)
		SetViewport()
	end
end

function ComparePowerReportListClass:ReSort(colIndex)
	local compare = function(a, b) return a > b end

	if colIndex == 1 then
		t_sort(self.list, function(a, b)
			if a.category == b.category then
				return compare(math.abs(a.impact), math.abs(b.impact))
			end
			return a.category < b.category
		end)
	elseif colIndex == 3 then
		t_sort(self.list, function(a, b)
			return compare(a.impact, b.impact)
		end)
	elseif colIndex == 4 then
		t_sort(self.list, function(a, b)
			local aDist = a.pathDist or 99999
			local bDist = b.pathDist or 99999
			if aDist == bDist then
				return compare(math.abs(a.impact), math.abs(b.impact))
			end
			return aDist < bDist
		end)
	elseif colIndex == 5 then
		t_sort(self.list, function(a, b)
			local aVal = a.perPoint or -99999
			local bVal = b.perPoint or -99999
			return compare(aVal, bVal)
		end)
	end
end

function ComparePowerReportListClass:ReList()
	self.list = {}
	if not self.reportData then
		return
	end
	for _, entry in ipairs(self.reportData) do
		t_insert(self.list, entry)
	end
end

function ComparePowerReportListClass:AddValueTooltip(tooltip, index, entry)
	if main.popups[1] then
		tooltip:Clear()
		return
	end

	local build = self.compareTab and self.compareTab.primaryBuild
	if not build then
		tooltip:Clear()
		return
	end

	if entry.category == "Tree" and entry.nodeId then
		local node = build.spec.nodes[entry.nodeId]
		if node then
			if tooltip:CheckForUpdate(node, IsKeyDown("SHIFT"), launch.devModeAlt, build.outputRevision) then
				local viewer = build.treeTab and build.treeTab.viewer
				if viewer then
					viewer:AddNodeTooltip(tooltip, node, build)
				end
			end
		else
			tooltip:Clear()
		end
	elseif entry.category == "Item" and entry.itemObj then
		if tooltip:CheckForUpdate(entry.itemObj, IsKeyDown("SHIFT"), launch.devModeAlt, build.outputRevision) then
			build.itemsTab:AddItemTooltip(tooltip, entry.itemObj)
		end
	else
		tooltip:Clear()
	end
end

function ComparePowerReportListClass:GetRowValue(column, index, entry)
	if column == 1 then
		return (entry.categoryColor or "^7") .. entry.category
	elseif column == 2 then
		return (entry.nameColor or "^7") .. entry.name
	elseif column == 3 then
		return entry.combinedImpactStr or entry.impactStr or "0"
	elseif column == 4 then
		if entry.pathDist then
			return tostring(entry.pathDist)
		end
		return ""
	elseif column == 5 then
		return entry.perPointStr or ""
	end
	return ""
end
