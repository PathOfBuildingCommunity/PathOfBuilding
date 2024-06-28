-- Path of Building
--
-- Class: Resizable Edit Control
-- Resizable edit control.
--
local m_max = math.max
local m_min = math.min

local ResizableEditClass = newClass("ResizableEditControl", "EditControl", function(self, anchor, x, y, minwidth, width, maxwidth, minheight, height, maxheight, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
    self.EditControl(anchor, x, y, width, height, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
    self.minheight = minheight or height
    self.maxheight = maxheight or height
    self.minwidth = minwidth or width
    self.maxwidth = maxwidth or width
    self.controls.draggerHeight = new("DraggerControl", {"BOTTOMRIGHT", self, "BOTTOMRIGHT"}, 7, 7, 14, 14, "//", nil, nil, function (position)
        -- onRightClick 
        if (self.height ~= self.minheight) or (self.width ~= self.minwidth) then
            self:SetWidth(self.minwidth)
            self:SetHeight(self.minheight)
        else
            self:SetWidth(self.maxwidth)
            self:SetHeight(self.maxheight)
        end
    end)
	self.protected = false
end)
function ResizableEditClass:Draw(viewPort, noTooltip)
    self:SetBoundedDrag(self)
    self.EditControl:Draw(viewPort, noTooltip)
end
function ResizableEditClass:SetBoundedDrag()
    if self.controls.draggerHeight.dragging then
        local cursorX, cursorY = GetCursorPos()
        local x, y = self:GetPos()
        self:SetHeight(cursorY - y)
        self:SetWidth(cursorX - x)
    end
end

function ResizableEditClass:SetWidth(width)
    self.width = m_max(m_min(width or 0, self.maxwidth), self.minwidth)
end
function ResizableEditClass:SetHeight(height)
    self.height = m_max(m_min(height or 0, self.maxheight), self.minheight)
end