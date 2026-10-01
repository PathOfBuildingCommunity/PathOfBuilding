-- Path of Building
--
-- Class: Resizable Edit Control
-- Resizable edit control.
--
local m_max = math.max
local m_min = math.min

---@class ResizableEditControl: EditControl
---@field minWidth number
---@field minHeight number
---@field maxWidth number
---@field maxHeight number
local ResizableEditClass = newClass("ResizableEditControl", "EditControl")

---@param anchor? Anchor
---@param rect Rect
---@param init? string
---@param prompt? string
---@param filter? fun(text: string): string?
---@param limit? integer
---@param changeFunc? fun(text: string)
---@param lineHeight? number
---@param allowZoom? boolean
---@param clearable? boolean
---@return ResizableEditControl
function ResizableEditClass:ResizableEditControl(anchor, rect, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
    self:EditControl(anchor, rect, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
	local x, y, width, height, minWidth, minHeight, maxWidth, maxHeight = unpack(rect)
    self.minHeight = minHeight or height
    self.maxHeight = maxHeight or height
    self.minWidth = minWidth or width
    self.maxWidth = maxWidth or width
    self.controls.draggerHeight = new("DraggerControl"):DraggerControl({"BOTTOMRIGHT", self, "BOTTOMRIGHT"}, {7, 7, 14, 14}, "//", nil, nil, function (position)
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
	return self
end

---@param viewPort Viewport
---@param noTooltip? boolean
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

---@param width? number
function ResizableEditClass:SetWidth(width)
    self.width = m_max(m_min(width or 0, self.maxWidth), self.minWidth)
end

---@param height? number
function ResizableEditClass:SetHeight(height)
    self.height = m_max(m_min(height or 0, self.maxHeight), self.minHeight)
end