-- Path of Building
--
-- Class: Glag Control
-- Basic flag control.
--
local FlagClass = newClass("FlagControl", "Control", "TooltipHost",
    function(self, anchor, x, y, width, height, label, onClick, onHover, forceTooltip)
    self.Control(anchor, x, y, width, height)
    self.TooltipHost()
    self.label = label
    self.onClick = onClick
    self.onHover = onHover
    self.forceTooltip = forceTooltip
    self.state = 0
end)

function FlagClass:Reset()
    self.state = 0
end

function FlagClass:IsMouseOver()
    if not self:IsShown() then
        return false
    end
    return self:IsMouseInBounds()
end

function FlagClass:Draw(viewPort, noTooltip)
    local x, y = self:GetPos()
    local width, height = self:GetSize()
    local enabled = self:IsEnabled()
    local mOver = self:IsMouseOver()
    local locked = self:GetProperty("locked")
    -- if not enabled then
    --     SetDrawColor(0.33, 0.33, 0.33)
    -- elseif mOver or locked then
    --     SetDrawColor(1, 1, 1)
    -- else
    --     SetDrawColor(0.5, 0.5, 0.5)
    -- end

    SetDrawColor(1,1,1)
    DrawImage(nil, x, y, width, height)
    -- if not enabled then
    --     SetDrawColor(0, 0, 0)
    -- elseif self.clicked and mOver then
    --     SetDrawColor(0.5, 0.5, 0.5)
    -- elseif mOver or locked then
    --     SetDrawColor(0.33, 0.33, 0.33)
    -- else
    --     SetDrawColor(0, 0, 0)
    -- end

    if self.state == 0 then
        SetDrawColor(0.8, 0.8, 0.8)
    elseif self.state == 1 then
       SetDrawColor(0.0, 0.8, 0.0)
    else
        SetDrawColor(0.8, 0.0, 0.0)
    end
    DrawImage(nil, x + 1, y + 1, width - 2, height - 2)

    -- if enabled then
    --     SetDrawColor(1, 1, 1)
    -- else
    --     SetDrawColor(0.33, 0.33, 0.33)
    -- end
    local label = self:GetProperty("label")
    if label then
        label = label
        local overSize = self.overSizeText or 0
        SetDrawColor(0.0, 0.0, 0.0)
        DrawString(x + width / 2, y + 2 - overSize, "CENTER_X", height - 4 + overSize * 2, "VAR", label)
    end
    if mOver then
        if not noTooltip or self.forceTooltip then
            SetDrawLayer(nil, 100)
            self:DrawTooltip(x, y, width, height, viewPort)
            SetDrawLayer(nil, 0)
        end
        if self.onHover ~= nil then
            return self.onHover()
        end
    end
end

function FlagClass:OnKeyDown(key)
    if not self:IsShown() or not self:IsEnabled() then
        return
    end
    if key == "LEFTBUTTON" or key == "RIGHTBUTTON" then
        self.clicked = true
    elseif self.enterFunc then
        self.enterFunc()
    end
    return self
end

function FlagClass:OnKeyUp(key)
    if not self:IsShown() or not self:IsEnabled() then
        return
    end
    if key == "LEFTBUTTON" and self.clicked then
        self.clicked = false
        if self:IsMouseOver() then
            if self.state ~= 1 then
                self.state = 1
            elseif self.state == 1 then
                self.state = 0
            end
            return self.onClick(self.state)
        end
    end
    if key == "RIGHTBUTTON" and self.clicked then
        self.clicked = false
        if self:IsMouseOver() then
            if self.state ~= -1 then
                self.state = -1
            elseif self.state == -1 then
                self.state = 0
            end
            return self.onClick(self.state)
        end
    end
    self.clicked = false
end
