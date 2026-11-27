-- Path of Building
--
-- Class: Tooltip Label Control
-- A label or icon with the same tooltip path as other controls.
--
---@class TooltipLabelControl: LabelControl, TooltipHost
local TooltipLabelClass = newClass("TooltipLabelControl", "LabelControl", "TooltipHost")

---@param anchor? Anchor
---@param rect? Rect
---@param label Prop<string>
function TooltipLabelClass:TooltipLabelControl(anchor, rect, label)
	self:LabelControl(anchor, rect, label)
	if rect[3] > 0 then self.width = rect[3] end
	self:TooltipHost()
	return self
end

function TooltipLabelClass:OnFocusLost()
	self.pressed = nil
end

function TooltipLabelClass:IsMouseOver()
	return self:IsShown() and self:IsMouseInBounds()
end

function TooltipLabelClass:OnKeyDown(key)
	if key == "LEFTBUTTON" and self.canClick and self.canClick() and self:IsMouseOver() then
		self.pressed = true
		return self
	end
end

function TooltipLabelClass:OnKeyUp(key)
	if key == "LEFTBUTTON" and self.pressed then
		self.pressed = nil
		if self:IsMouseOver() and self.canClick() then self.onClick() end
	end
end

function TooltipLabelClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	if self.iconFunc then
		self.iconFunc(x, y, width, height)
	else
		self.LabelControl:Draw()
	end
	if not noTooltip and self:IsMouseOver() then
		SetDrawLayer(nil, 100)
		self:DrawTooltip(x, y, width, height, viewPort)
		SetDrawLayer(nil, 0)
	end
end
