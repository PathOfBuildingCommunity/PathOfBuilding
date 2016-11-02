-- Path of Building
--
-- Class: Label Control
-- Simple text label.
--
local launch, main = ...

local LabelClass = common.NewClass("LabelControl", "Control", function(self, anchor, x, y, width, height, label)
	self.Control(anchor, x, y, width, height)
	self.label = label
	self.width = function()
		return DrawStringWidth(self:GetProperty("height"), "VAR", self:GetProperty("label"))
	end
end)

function LabelClass:Draw()
	local x, y = self:GetPos()
	DrawString(x, y, "LEFT", self:GetProperty("height"), "VAR", self:GetProperty("label"))
end