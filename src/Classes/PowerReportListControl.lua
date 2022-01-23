-- Path of Building
--
-- Class: Power Report
-- Power Report control.
--

local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort

local PowerReportListClass = newClass("PowerReportListControl", "ListControl", function(self, anchor, x, y, width, height, report, powerLabel, nodeSelectCallback)

	self.originalList = report

	self.ListControl(anchor, x, y, width, height-50, 16, "VERTICAL", false, self:ReList())

	self.colList = {
		{ width = width * 0.15, label = "Type", sortable = true },
		{ width = width * 0.45, label = "Node Name" },
		{ width = width * 0.16, label = powerLabel, sortable = true },
		{ width = width * 0.05, label = "Points", sortable = true },
		{ width = width * 0.16, label = "Per Point", sortable = true },
	}
	self.label = "Click to focus node on tree"
	self.colLabels = true
	self.nodeSelectCallback = nodeSelectCallback
	self.showClusters = false
	
	self.controls.showClusters = new("CheckBoxControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 18, "Show Clusters:", function(state)
		self.showClusters = state
		self:ReList()
		self:ReSort(3)
	end, "Show Cluster Jewel Notables")
end)

function PowerReportListClass:ReSort(colIndex)
	if colIndex == 1 then
		t_sort(self.list, function (a,b)
			if a.type == b.type then
				return a.power > b.power
			end
			return a.type < b.type
		end)
	elseif colIndex == 3 then
		t_sort(self.list, function (a,b)
			return a.power > b.power
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
				return a.power > b.power
			end
			return a.pathDist < b.pathDist
		end)
	elseif colIndex == 5 then
		t_sort(self.list, function (a,b)
			if a.pathPower == b.pathPower and type(a.pathDist) == "number" and type(b.pathDist) == "number" then
				return a.pathDist < b.pathDist
			end
			return a.pathPower > b.pathPower
		end)
	end
end

function PowerReportListClass:ReList()
	if not next(self.originalList) then
		return { }
	end
	local filteredList = { }
	local iterate = 1
	local insert = true

	while(true) do

		insert = self.originalList[iterate].power > 0
		if (not self.showClusters) and (self.originalList[iterate].pathDist == "Cluster") then
			insert = false
		end
		if self.allocated and self.originalList[iterate].pathDist ~= "Cluster" then
			insert = self.originalList[iterate].allocated and (self.originalList[iterate].pathDist <= (self.pathLength or 100))
		end

		if insert then
			t_insert(filteredList, self.originalList[iterate])
		end

		iterate = iterate + 1
		insert = true

		if iterate > #self.originalList then
			break
		end		
	end

	if (next(filteredList)) then
		self.list = filteredList
		return filteredList
	else 
		self.list = self.originalList
		return self.originalList
	end
end

function PowerReportListClass:OnSelClick(index, report, doubleClick)
	if self.nodeSelectCallback then
		self.nodeSelectCallback(report)
	end
end

function PowerReportListClass:GetRowValue(column, index, report)
	if column == 1 then
		return report.type
	elseif column == 2 then
		return report.name
	elseif column == 3 then
		return report.powerStr
	elseif column == 4 then
		if report.pathDist == 1000 then
			return "Anoint"
		else
			return report.pathDist
		end
	elseif column == 5 then
		return report.pathPowerStr
	else
		return ""
	end
end
