-- Path of Building
--
-- Class: Power Report
-- Power Report control.
--

local t_insert = table.insert
local t_remove = table.remove

local PowerReportListClass = newClass("PowerReportListControl", "ListControl", function(self, anchor, x, y, width, height, report, powerLabel, nodeSelectCallback)

	self.originalList = report

	self.ListControl(anchor, 0, 75, width, height-50, 20, false, false, self:Relist())

	self.colList = {
		{ width = width * 0.15, label = "Type" },
		{ width = width * 0.50, label = "Node Name" },
		{ width = width * 0.18, label = powerLabel },
		{ width = width * 0.12, label = "Distance"}
	}
	self.label = "Click to focus node on tree"
	self.colLabels = true
	self.nodeSelectCallback = nodeSelectCallback
	self.showClusters = false
	self.onlyNotables = false
	self.controls.showClusters = new("CheckBoxControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -1, 18, "Show Clusters:", function(state)
		self.showClusters = state
		self:Relist()
	end, "Show Cluster Jewel Notables")
	self.controls.onlyNotables = new("CheckBoxControl", {"BOTTOMRIGHT", self.controls.showClusters, "TOPRIGHT"}, 0, 0, 18, "Only Notables:", function(state)
		self.onlyNotables = state
		self:Relist()
	end)

end)

function PowerReportListClass:Relist()
	local filteredList = { }
	local iterate = 1
	local insert = true

	while(true) do
		if (not self.showClusters) and (self.originalList[iterate].pathDist == "Cluster") then
			insert = false
		end
		if (self.onlyNotables) and (self.originalList[iterate].type ~= "Notable") then
			insert = false
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
	else
		return ""
	end
end
