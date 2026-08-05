-- Path of Building
--
-- Class: Label Control
-- Simple text label.
--
local LabelClass = newClass("LabelControl", "Control", function(self, anchor, rect, label)
	self.Control(anchor, rect)
	self.label = label
	self.width = function()
		local curLabel = self:GetProperty("label")
		if self.cachedLabel ~= curLabel then
			self.cachedLabel = curLabel
			self.cachedWidth = DrawStringWidth(self:GetProperty("height"), "VAR", curLabel or "")
		end
		return self.cachedWidth
	end
end)

function LabelClass:Draw()
	local x, y = self:GetPos()
	DrawString(x, y, "LEFT", self:GetProperty("height"), "VAR", self:GetProperty("label"))
end