-- Path of Building
--
-- Class: HorizontalLine Control
-- Simple horizontal rule
--
local HorizontalLineClass = newClass("HorizontalLineControl", "Control", function(self, anchor, x, y, width, height, colors)
    self.Control(anchor, x, y, width, height)
    self.colors = colors or { 1, 1, 1 }
end)

function HorizontalLineClass:Draw()
    local x, y = self:GetPos()
    SetDrawColor(unpack(self.colors))
    DrawImage(nil, x, y, self.width, self.height)
end
