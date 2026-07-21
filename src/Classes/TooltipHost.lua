-- Path of Building
--
-- Class: Tooltip Host
-- Tooltip host
--
---@class TooltipHost
local TooltipHostClass = newClass("TooltipHost")

function TooltipHostClass:TooltipHost(tooltipText)
	self.tooltip = new("Tooltip"):Tooltip()
	self.tooltipText = tooltipText
	return self
end

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
