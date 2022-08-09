local LabelTooltipClass = newClass("LabelTooltipControl", "LabelControl", "TooltipHost", function(self, anchor, x, y, width, height, label, tooltipTitle)
    self.LabelControl(anchor, x, y, width, height, label)
    self.TooltipHost()
	self.tooltipTitle = tooltipTitle
end)

function LabelTooltipClass:Draw(viewPort)
	self.LabelControl:Draw(viewPort)
	local x, y = self:GetPos()
	local mOver = self:IsMouseOver()
	if mOver then
		local width, height = self:GetSize()
		SetDrawLayer(nil, 100)
		if self.tooltipTitle then
			self.TooltipHost.tooltip:Clear()
			self.TooltipHost.tooltip:AddLine(16, self.tooltipTitle)
			self.TooltipHost.tooltip:Draw(x, y, width, height, viewPort)
		end
		self:DrawTooltip(x, y+35, width, height, viewPort)
		SetDrawLayer(nil, 0)
	end
end

function LabelTooltipClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds()
end

function LabelTooltipClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELUP" then
		return self.onPrevious and self:onPrevious()
	elseif key == "WHEELDOWN" then
		return self.onNext and self:onNext()
	end
end