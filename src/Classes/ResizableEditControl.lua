-- Path of Building
--
-- Class: Resizable Edit Control
-- Resizable edit control.
--
local m_max = math.max
local m_min = math.min

---@class ResizableEditControlBase
---@field EditControl fun(...)
---@field Draw fun(...)

---@class ResizableEditControl: EditControl
---@field minWidth number
---@field minHeight number
---@field maxWidth number
---@field maxHeight number
---@field controls ResizableEditControlControls
---@field GetProperty fun(self: ResizableEditControl, name: string): unknown
---@field GetPos fun(self: ResizableEditControl): number, number
---@field GetSize fun(self: ResizableEditControl): number, number
---@field IsShown fun(self: ResizableEditControl): boolean
---@field ResizableEditControl fun(...)
---@field SetBoundedDrag fun(self: ResizableEditControl, control?: ResizableEditControl)
---@field SetWidth fun(self: ResizableEditControl, width?: number)
---@field SetHeight fun(self: ResizableEditControl, height?: number)
---@field EditControl ResizableEditControlBase
---@type ResizableEditControl
local ResizableEditClass = newClass("ResizableEditControl", "EditControl")

---@class ResizableEditControlControls: EditControlControls
---@field draggerHeight ResizableEditDraggerControl

---@class ResizableEditDraggerControl: DraggerControl
---@field dragging? boolean
---@alias ResizableEditRect [number, number, number, number, number?, number?, number?, number?]

---@param anchor? Anchor
---@param rect ResizableEditRect
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
    ---@type Rect
    local baseRect = { rect[1], rect[2], rect[3], rect[4] }
    self.EditControl.EditControl(self, anchor, baseRect, init, prompt, filter, limit, changeFunc, lineHeight, allowZoom, clearable)
    local width = rect[3]
    local height = rect[4]
    local minWidth = rect[5]
    local minHeight = rect[6]
    local maxWidth = rect[7]
    local maxHeight = rect[8]
    self.minHeight = minHeight or height
    self.maxHeight = maxHeight or height
    self.minWidth = minWidth or width
    self.maxWidth = maxWidth or width
    ---@type fun(position: DraggerPosition)
    local onRightClick = function(position)
        -- onRightClick 
        if (self.height ~= self.minHeight) or (self.width ~= self.minWidth) then
            self:SetWidth(self.minWidth)
            self:SetHeight(self.minHeight)
        else
            self:SetWidth(self.maxWidth)
            self:SetHeight(self.maxHeight)
        end
    end
    ---@type Anchor
    local dragAnchor = {"BOTTOMRIGHT", self, "BOTTOMRIGHT"}
    self.controls.draggerHeight = new("DraggerControl"):DraggerControl(dragAnchor, {7, 7, 14, 14}, "//", nil, nil, onRightClick)
	self.protected = false
	return self
end

---@param viewPort Viewport
---@param noTooltip? boolean
function ResizableEditClass:Draw(viewPort, noTooltip)
    self:SetBoundedDrag(self)
    ---@type ResizableEditControlBase
    local editControl = self.EditControl
    editControl.Draw(self, viewPort, noTooltip)
end

---@param control? ResizableEditControl
function ResizableEditClass:SetBoundedDrag(control)
    ---@type ResizableEditDraggerControl
    local dragger = self.controls.draggerHeight
    if dragger.dragging then
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