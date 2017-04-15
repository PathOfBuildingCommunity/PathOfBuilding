-- Path of Building
--
-- Class: Minion List
-- Minion list control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor
local s_format = string.format

local MinionListClass = common.NewClass("MinionList", "Control", "ControlHost", function(self, anchor, x, y, width, height, list, mutable, dest)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.list = list
	self.mutable = mutable
	self.dest = dest
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 16, 0, 32)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	if mutable then
		self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Remove", function()
			self:DeleteSel()
		end)
		self.controls.delete.enabled = function()
			return self.selValue ~= nil
		end
	else
		self.controls.add = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Add", function()
			self:AddSel()
		end)
		self.controls.add.enabled = function()
			return self.selValue ~= nil
		end
	end		
end)

function MinionListClass:SelectIndex(index)
	self.selValue = self.list[index]
	if self.selValue then
		self.selIndex = index
		self.controls.scrollBar:ScrollIntoView((index - 2) * 16, 48)
	end
end

function MinionListClass:AddSel()
	if self.selValue and self.dest and not isValueInArray(self.dest.list, self.selValue) then
		t_insert(self.dest.list, self.selValue)
	end
end

function MinionListClass:DeleteSel()
	if self.selIndex and self.mutable then
		t_remove(self.list, self.selIndex)
		self.selIndex = nil
		self.selValue = nil
	end
end

function MinionListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function MinionListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.list
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#list * 16, height - 4)
	self.selDragIndex = nil
	if (self.selValue and self.selDragging) or self.otherDragActive then
		local cursorX, cursorY = GetCursorPos()
		if not self.selDragActive and not self.otherDragActive and (cursorX-self.selCX)*(cursorX-self.selCX)+(cursorY-self.selCY)*(cursorY-self.selCY) > 100 then
			self.selDragActive = true
		end
		if (self.selDragActive or self.otherDragActive) and self.mutable then
			if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
				local index = math.floor((cursorY - y - 2 + scrollBar.offset) / 16 + 0.5) + 1
				if not self.selIndex or index < self.selIndex or index > self.selIndex + 1 then
					self.selDragIndex = m_min(index, #list + 1)
				end
			end
		end
		if self.dest then
			self.dest.otherDragActive = self.dest:IsMouseOver()
		end
	end
	DrawString(x, y - 20, "LEFT", 16, "VAR", self.mutable and "^7Spectres in Build:" or "^7Available Spectres:")
	if self.hasFocus then
		SetDrawColor(1, 1, 1)
	else
		SetDrawColor(0.5, 0.5, 0.5)
	end
	DrawImage(nil, x, y, width, height)
	SetDrawColor(0, 0, 0)
	DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	self:DrawControls(viewPort)
	SetViewport(x + 2, y + 2, width - 20, height - 4)
	local ttValue, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / 16 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 16 + 1), #list)
	for index = minIndex, maxIndex do
		local value = list[index]
		local minion = data.minions[value]
		local lineY = 16 * (index - 1) - scrollBar.offset
		local label = minion.name
		local nameWidth = DrawStringWidth(16, "VAR", label)
		if not scrollBar.dragging and not self.selDragActive then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 17 and relY >= 0 and relY >= lineY and relY < height - 2 and relY < lineY + 16 then
				ttValue = value
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = lineY + y + 2
			end
		end
		if value == ttValue or value == self.selValue then
			if self.hasFocus then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, lineY, width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, lineY + 1, width - 20, 14)		
		end
		SetDrawColor(1, 1, 1)
		DrawString(0, lineY, "LEFT", 16, "VAR", label)
	end
	if self.selDragIndex then
		local lineY = 16 * (self.selDragIndex - 1) - scrollBar.offset
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, lineY - 1, width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, lineY, width - 20, 1)
	end
	SetViewport()
	if ttValue then
		local minion = data.minions[ttValue]
		main:AddTooltipLine(18, "^7"..minion.name)
		main:AddTooltipLine(14, s_format("^7Life multiplier: x%.2f", minion.life))
		if minion.energyShield then
			main:AddTooltipLine(14, s_format("^7Energy Shield: %d%% of base Life", minion.energyShield * 100))
		end
		main:AddTooltipLine(14, s_format("^7Resistances: %s%d^7/%s%d^7/%s%d^7/%s%d", 
			data.colorCodes.FIRE, minion.fireResist, data.colorCodes.COLD, minion.coldResist, 
			data.colorCodes.LIGHTNING, minion.lightningResist, data.colorCodes.CHAOS, minion.chaosResist))
		main:AddTooltipLine(14, s_format("^7Base damage: x%.2f", minion.damage))
		main:AddTooltipLine(14, s_format("^7Base attack speed: %.2f", 1 / minion.attackTime))
		for _, skillId in ipairs(minion.skillList) do
			if data.skills[skillId] then
				main:AddTooltipLine(14, "^7Skill: "..data.skills[skillId].name)
			end
		end
		SetDrawLayer(nil, 100)
		main:DrawTooltip(x + 2, ttY, ttWidth, 16, viewPort)
		SetDrawLayer(nil, 0)
	end
end

function MinionListClass:OnKeyDown(key, doubleClick)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	local mOverControl = self:GetMouseOverControl()
	if mOverControl and mOverControl.OnKeyDown then
		return mOverControl:OnKeyDown(key)
	end
	if not self:IsMouseOver() and key:match("BUTTON") then
		return
	end
	if key == "LEFTBUTTON" then
		self.selValue = nil
		self.selIndex = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 16) + 1
			local selValue = self.list[index]
			if selValue then
				self.selValue = selValue
				self.selIndex = index
				if doubleClick then
					self:AddSel()
				end
			end
		end
		if self.selValue then
			self.selCX = cursorX
			self.selCY = cursorY
			self.selDragging = true
			self.selDragActive = false
		end
	elseif #self.list > 0 then
		if key == "UP" then
			self:SelectIndex(((self.selIndex or 1) - 2) % #self.list + 1)
		elseif key == "DOWN" then
			self:SelectIndex((self.selIndex or #self.list) % #self.list + 1)
		elseif key == "HOME" then
			self:SelectIndex(1)
		elseif key == "END" then
			self:SelectIndex(#list)
		end
	end
	return self
end

function MinionListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	elseif self.selValue then
		if key == "BACK" or key == "DELETE" then
			self:DeleteSel()
		elseif key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex and self.selDragIndex ~= self.selIndex then
					t_remove(self.list, self.selIndex)
					if self.selDragIndex > self.selIndex then
						self.selDragIndex = self.selDragIndex - 1
					end
					t_insert(self.list, self.selDragIndex, self.selValue)
					self.selValue = nil
				elseif self.dest and self.dest.otherDragActive then
					if self.dest.selDragIndex and not isValueInArray(self.dest.list, self.selValue) then
						t_insert(self.dest.list, self.dest.selDragIndex, self.selValue)
					end
					self.dest.otherDragActive = false
					self.selValue = nil
				end
			end
		end
	end
	return self
end