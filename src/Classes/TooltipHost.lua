-- Path of Building
--
-- Class: Tooltip Host
-- Tooltip host
--
local TooltipHostClass = newClass("TooltipHost", function(self, tooltipText)
	self.tooltip = new("Tooltip")
	self.tooltipText = tooltipText
end)

function TooltipHostClass:DrawTooltip(x, y, width, height, viewPort, ...)
	if self.tooltipFunc then
		self.tooltipFunc(self.tooltip, ...)
		self.tooltip:Draw(x, y, width, height, viewPort)
	else
		local tooltipText = self.Object:GetProperty("tooltipText")
		if tooltipText then
			self.tooltip:Clear()
			self.tooltip:AddLine(14, tooltipText)
			self.tooltip:Draw(x, y, width, height, viewPort)
		end
	end
end