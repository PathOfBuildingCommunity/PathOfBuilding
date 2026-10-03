-- Path of Building
--
-- Class: Label Control
-- Simple text label.
--
---@class LabelControl: Control
---@field label? Prop<string>
local LabelClass = newClass("LabelControl", "Control")

---@param anchor? Anchor
---@param rect? Rect
---@param label? Prop<string>
---@return LabelControl
function LabelClass:LabelControl(anchor, rect, label)
	self:Control(anchor, rect)
	self.label = label
	self.width = function()
		return DrawStringWidth(self:GetProperty("height"), "VAR", self:GetProperty("label"))
	end
	return self
end

function LabelClass:Draw()
	local x, y = self:GetPos()
	DrawString(x, y, "LEFT", self:GetProperty("height"), "VAR", self:GetProperty("label"))
end
