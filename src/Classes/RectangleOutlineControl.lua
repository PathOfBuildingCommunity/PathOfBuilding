-- Path of Building
--
-- Class: RectangleOutline Control
-- Simple Outline Only Rectangle control
--
local CC = UI.CC

local RectangleOutlineClass = newClass("RectangleOutlineControl", "Control", function(self, anchor, x, y, width, height, colors, stroke)
    self.Control(anchor, x, y, width, height)
    self.stroke = stroke or 1
    self.colors = colors or CC.SECTION_BORDER
end)

function RectangleOutlineClass:Draw()
    local x, y = self:GetPos()
    SetDrawColor(self.colors)
    DrawImage(nil, x, y, self.width + self.stroke, self.stroke)
    DrawImage(nil, x, y + self.height, self.width + self.stroke, self.stroke)
    DrawImage(nil, x, y, self.stroke, self.height + self.stroke)
    DrawImage(nil, x + self.width, y, self.stroke, self.height + self.stroke)
end
