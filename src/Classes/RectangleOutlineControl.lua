-- Path of Building
--
-- Class: RectangleOutline Control
-- Simple Outline Only Rectangle control
--
---@class RectangleOutlineControl: Control
---@field stroke number
---@field colors number[]
local RectangleOutlineClass = newClass("RectangleOutlineControl", "Control")

---@param anchor? Anchor
---@param rect? Rect
---@param colors? number[]
---@param stroke? number
---@return RectangleOutlineControl
function RectangleOutlineClass:RectangleOutlineControl(anchor, rect, colors, stroke)
    self:Control(anchor, rect)
    self.stroke = stroke or 1
    self.colors = colors or { 1, 1, 1 }
	return self
end

function RectangleOutlineClass:Draw()
    local x, y = self:GetPos()
    SetDrawColor(unpack(self.colors))
    DrawImage(nil, x, y, self.width + self.stroke, self.stroke)
    DrawImage(nil, x, y + self.height, self.width + self.stroke, self.stroke)
    DrawImage(nil, x, y, self.stroke, self.height + self.stroke)
    DrawImage(nil, x + self.width, y, self.stroke, self.height + self.stroke)
end
