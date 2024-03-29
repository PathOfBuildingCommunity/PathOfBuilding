-- Path of Building
--
-- Class: Power Report
-- Power Report control.
--

local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort

local PowerReportListClass = newClass("PowerReportListControl", "ListControl", function(self, anchor, x, y, width, height, nodeSelectCallback)
	self.ListControl(anchor, x, y, width, height-50, 16, "VERTICAL", false)

	self.powerColumn = { width = width * 0.16, label = "", sortable = true }
	self.colList = {
		{ width = width * 0.15, label = "Type", sortable = true },
		{ width = width * 0.45, label = "Node Name" },
		self.powerColumn,
		{ width = width * 0.05, label = "Points", sortable = true },
		{ width = width * 0.16, label = "Per Point", sortable = true },
	}
	self.colLabels = true
	self.nodeSelectCallback = nodeSelectCallback
	self.showClusters = false
	self.allocated = false
	self.label = "Building Tree..."
	
	self.controls.filterSelect = new("DropDownControl", { "BOTTOMRIGHT", self, "TOPRIGHT" }, 0, -2, 200, 20,
		{ "Show Unallocated", "Show Unallocated & Clusters", "Show Allocated" },
		function(index, value)
			self.showClusters = index == 2
			self.allocated = index == 3
			self:ReList()
			self:ReSort(3) -- Sort by power
		end)
end)

function PowerReportListClass:SetReport(stat, report)
	self.powerColumn.label = stat and stat.label or ""
	self.originalList = report or {}

	if stat and stat.stat then
		self.label = report and "Click to focus node on tree" or "Building Tree..."
	else
		self.label = "^7\""..self.powerColumn.label.."\" not supported.  Select a specific stat from the dropdown."
	end

	self:ReList()
end

function PowerReportListClass:ReSort(colIndex)
	-- Reverse power sort for allocated because it uses negative numbers
	local compare = self.allocated and 
		function(a, b) return a < b end
		or function(a, b) return a > b end

	if colIndex == 1 then
		t_sort(self.list, function (a,b)
			if a.type == b.type then
				return compare(a.power, b.power)
			end
			return a.type < b.type
		end)
	elseif colIndex == 3 then
		t_sort(self.list, function (a,b)
			return compare(a.power, b.power)
		end)
	elseif colIndex == 4 then
		t_sort(self.list, function (a,b)
			if a.pathDist == "Anoint" or a.pathDist == "Cluster" then
				return false
			end
			if b.pathDist == "Anoint" or b.pathDist == "Cluster" then
				return true
			end
			if a.pathDist == b.pathDist then
				return compare(a.power, b.power)
			end
			return a.pathDist < b.pathDist
		end)
	elseif colIndex == 5 then
		t_sort(self.list, function (a,b)
			if a.pathPower == b.pathPower and type(a.pathDist) == "number" and type(b.pathDist) == "number" then
				return a.pathDist < b.pathDist
			end
			return compare(a.pathPower, b.pathPower)
		end)
	end
end

function PowerReportListClass:ReList()
	self.list = { }
	if not self.originalList then
		return
	end

	for _, item in ipairs(self.originalList) do
		local insert = item.power > 0
		if not self.showClusters and item.pathDist == "Cluster" then
			insert = false
		end
		if self.allocated then
			insert = item.allocated
		end

		if insert then
			t_insert(self.list, item)
		end
	end
end

function PowerReportListClass:OnSelClick(index, report, doubleClick)
	if self.nodeSelectCallback then
		self.nodeSelectCallback(report)
	end
end

function PowerReportListClass:GetRowValue(column, index, report)
	return column == 1 and report.type
		or column == 2 and report.name
		or column == 3 and report.powerStr
		or column == 4 and (report.pathDist == 1000 and "Anoint" or report.pathDist)
		or column == 5 and report.pathPowerStr
		or ""
end
