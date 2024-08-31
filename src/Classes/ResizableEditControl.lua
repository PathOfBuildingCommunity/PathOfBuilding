-- Path of Building
--
-- Class: Resizable Edit Control
-- Resizable edit control.
--
local m_max = math.max
local m_min = math.min

local ResizableEditClass = newClass("ResizableEditControl", "EditControl", function(self, anchor, rect, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
    self.EditControl(anchor, rect, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
	local x, y, width, height, minWidth, minHeight, maxWidth, maxHeight = unpack(rect)
    self.minHeight = minHeight or height
    self.maxHeight = maxHeight or height
    self.minWidth = minWidth or width
    self.maxWidth = maxWidth or width
    self.controls.draggerHeight = new("DraggerControl", {"BOTTOMRIGHT", self, "BOTTOMRIGHT"}, {7, 7, 14, 14}, "//", nil, nil, function (position)
        -- onRightClick 
        if (self.height ~= self.minHeight) or (self.width ~= self.minWidth) then
            self:SetWidth(self.minWidth)
            self:SetHeight(self.minHeight)
        else
            self:SetWidth(self.maxWidth)
            self:SetHeight(self.maxHeight)
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
    self.width = m_max(m_min(width or 0, self.maxWidth), self.minWidth)
end
function ResizableEditClass:SetHeight(height)
    self.height = m_max(m_min(height or 0, self.maxHeight), self.minHeight)
end