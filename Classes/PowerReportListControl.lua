
local PowerReportListClass = newClass("PowerReportListControl", "ListControl", function(self, anchor, x, y, width, height, report, powerLabel, nodeSelectCallback)
	self.ListControl(anchor, x, y, width, height, 20, false, false, report)
	self.colList = {
		{ width = width * 0.20, label = "Type" },
		{ width = width * 0.45, label = "Node Name" },
		{ width = width * 0.15, label = powerLabel },
		{ width = width * 0.15, label = "Distance"}
	}
	self.label = "Click to focus node on tree"
	self.colLabels = true
	self.nodeSelectCallback = nodeSelectCallback
end)

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
			return "Annoint"
		else
			return report.pathDist
		end
	else
		return ""
	end
end
