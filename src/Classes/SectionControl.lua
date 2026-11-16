-- Path of Building
--
-- Class: Section Control
-- Section box with label
--

---@class SectionControl: Control
local SectionClass = newClass("SectionControl", "Control")

function SectionClass:SectionControl(anchor, rect, label)
	self:Control(anchor, rect)
	self.label = label
	return self
end

function SectionClass:Draw()
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local colors = ui.colors
	SetDrawLayer(nil, -10)
	ui.DrawBox(x, y, width, height, ui.radiusLarge, colors.border, colors.panel)
	SetDrawLayer(nil, 0)
	-- The label straddles the top edge, so it needs to punch a hole in the border it sits on
	local label = self:GetProperty("label")
	local labelWidth = DrawStringWidth(14, "VAR", label)
	ui.SetColor(colors.panel)
	ui.DrawRect(x + 8, y - 8, labelWidth + 10, 18, ui.radiusSmall)
	ui.SetColor(colors.text)
	DrawString(x + 13, y - 6, "LEFT", 14, "VAR", label)
end