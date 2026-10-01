-- Path of Building
--
-- Class: Tooltip Host
-- Tooltip host
--
---@class TooltipHost
---@field tooltip Tooltip
---@field tooltipText? Prop<string>
---@field tooltipFunc? fun(tooltip: Tooltip, ...: unknown)
---@field Object Control
local TooltipHostClass = newClass("TooltipHost")

---@param tooltipText? Prop<string>
---@return TooltipHost
function TooltipHostClass:TooltipHost(tooltipText)
	self.tooltip = new("Tooltip"):Tooltip()
	self.tooltipText = tooltipText
	return self
end

---@param x number
---@param y number
---@param width number
---@param height number
---@param viewPort Viewport
---@param ... unknown
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
