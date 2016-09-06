-- Path of Building
--
-- Class: Skill List
-- Skill list control.
--
local launch, main = ...

local t_insert = table.insert
local t_remove = table.remove
local m_min = math.min
local m_max = math.max
local m_floor = math.floor

local SkillListClass = common.NewClass("SkillList", "Control", "ControlHost", function(self, anchor, x, y, width, height, skillsTab)
	self.Control(anchor, x, y, width, height)
	self.ControlHost()
	self.skillsTab = skillsTab
	self.controls.scrollBar = common.New("ScrollBarControl", {"RIGHT",self,"RIGHT"}, -1, 0, 16, 0, 32)
	self.controls.scrollBar.height = function()
		local width, height = self:GetSize()
		return height - 2
	end
	self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnKeyUp("DELETE")
	end)
	self.controls.delete.enabled = function()
		return self.selSkill ~= nil
	end
	self.controls.paste = common.New("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 60, 18, "Paste", function()
		self.skillsTab:PasteSkill()
	end)
	self.controls.copy = common.New("ButtonControl", {"RIGHT",self.controls.paste,"LEFT"}, -4, 0, 60, 18, "Copy", function()
		self.skillsTab:CopySkill(self.selSkill)
	end)
	self.controls.copy.enabled = function()
		return self.selSkill ~= nil
	end
	self.controls.new = common.New("ButtonControl", {"RIGHT",self.controls.copy,"LEFT"}, -4, 0, 60, 18, "New", function()
		local newSkill = { label = "", active = true, gemList = { } }
		t_insert(self.skillsTab.list, newSkill)
		self.selSkill = newSkill
		self.selIndex = #self.skillsTab.list
		self.skillsTab:SetDisplaySkill(newSkill)
		self.skillsTab:AddUndoState()
		return self.skillsTab.gemSlots[1].nameSpec
	end)
end)

function SkillListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	if self:GetMouseOverControl() then
		return true
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	return cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
end

function SkillListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.skillsTab.list
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#list * 16, height - 4)
	self.selDragIndex = nil
	if self.selSkill and self.selDragging then
		local cursorX, cursorY = GetCursorPos()
		if not self.selDragActive and (cursorX-self.selCX)*(cursorX-self.selCX)+(cursorY-self.selCY)*(cursorY-self.selCY) > 100 then
			self.selDragActive = true
		end
		if self.selDragActive then
			if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
				local index = math.floor((cursorY - y - 2 + scrollBar.offset) / 16 + 0.5) + 1
				if index < self.selIndex or index > self.selIndex + 1 then
					self.selDragIndex = m_min(index, #list + 1)
				end
			end
		end
	end
	DrawString(x, y - 20, "LEFT", 16, "VAR", "^7Skills:")
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
	local ttSkill, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / 16 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 16 + 1), #list)
	for index = minIndex, maxIndex do
		local skill = list[index]
		local skillY = 16 * (index - 1) - scrollBar.offset
		local label = skill.displayLabel
		if not skill.active then
			label = label .. " (Inactive)"
		end
		local nameWidth = DrawStringWidth(16, "VAR", label)
		if not scrollBar.dragging and not self.selDragActive and (not self.skillsTab.selControl or self.hasFocus) then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 17 and relY >= 0 and relY >= skillY and relY < height - 2 and relY < skillY + 16 then
				ttSkill = skill
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = skillY + y + 2
			end
		end
		if skill == ttSkill or skill == self.selSkill then
			if self.hasFocus then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, skillY, width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, skillY + 1, width - 20, 14)		
		end
		if skill.active then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawString(0, skillY, "LEFT", 16, "VAR", label)
	end
	if self.selDragIndex then
		local skillY = 16 * (self.selDragIndex - 1) - scrollBar.offset
		SetDrawColor(1, 1, 1)
		DrawImage(nil, 0, skillY - 1, width - 20, 3)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, 0, skillY, width - 20, 1)
	end
	SetViewport()
	if ttSkill then
		local count = 0
		for _, gem in ipairs(ttSkill.tooltipGemList or { }) do
			if gem.name then
				local color = (gem.data.strength and "STRENGTH") or (gem.data.dexterity and "DEXTERITY") or (gem.data.intelligence and "INTELLIGENCE") or "NORMAL"
				main:AddTooltipLine(20, string.format("%s%s ^7%d%s/%d%s", 
					data.colorCodes[color], 
					gem.name, 
					gem.effectiveLevel or gem.level, 
					(gem.effectiveLevel and gem.effectiveLevel > gem.level) and data.colorCodes.MAGIC.."+"..(gem.effectiveLevel - gem.level).."^7" or "",
					gem.effectiveQuality or gem.quality,
					(gem.effectiveQuality and gem.effectiveQuality > gem.quality) and data.colorCodes.MAGIC.."+"..(gem.effectiveQuality - gem.quality).."^7" or ""
				))
				count = count + 1
			end
		end
		if count > 0 then
			SetDrawLayer(nil, 100)
			main:DrawTooltip(x + 2, ttY, ttWidth, 16, viewPort)
			SetDrawLayer(nil, 0)
		end
	end
end

function SkillListClass:OnKeyDown(key, doubleClick)
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
		self.selSkill = nil
		self.selIndex = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 16) + 1
			local selSkill = self.skillsTab.list[index]
			if selSkill then
				self.selSkill = selSkill
				self.selIndex = index
				self.skillsTab:SetDisplaySkill(selSkill)
			end
		end
		if self.selSkill then
			self.selCX = cursorX
			self.selCY = cursorY
			self.selDragging = true
			self.selDragActive = false
		end
	elseif key == "c" and IsKeyDown("CTRL") then
		if self.selSkill then	
			self.skillsTab:CopySkill(self.selSkill)
		end
	elseif #self.skillsTab.list > 0 then
		if key == "UP" then
			self.selIndex = ((self.selIndex or 1) - 2) % #self.skillsTab.list + 1
			self.selSkill = self.skillsTab.list[self.selIndex]
			self.skillsTab:SetDisplaySkill(self.selSkill)
		elseif key == "DOWN" then
			self.selIndex = (self.selIndex or #self.skillsTab.list) % #self.skillsTab.list + 1
			self.selSkill = self.skillsTab.list[self.selIndex]
			self.skillsTab:SetDisplaySkill(self.selSkill)
		end
	end
	return self
end

function SkillListClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "WHEELDOWN" then
		self.controls.scrollBar:Scroll(1)
	elseif key == "WHEELUP" then
		self.controls.scrollBar:Scroll(-1)
	elseif self.selSkill then
		if key == "BACK" or key == "DELETE" then
			if not self.selSkill.gemList[1] then
				t_remove(self.skillsTab.list, self.selIndex)
				if self.skillsTab.displaySkill == self.selSkill then
					self.skillsTab.displaySkill = nil
				end
				self.skillsTab:AddUndoState()
				self.selSkill = nil
			else
				main:OpenConfirmPopup("Delete Skill", "Are you sure you want to delete '"..self.selSkill.displayLabel.."'?", "Delete", function()
					t_remove(self.skillsTab.list, self.selIndex)
					if self.skillsTab.displaySkill == self.selSkill then
						self.skillsTab.displaySkill = nil
					end
					self.skillsTab:AddUndoState()
					self.skillsTab.build.buildFlag = true
					self.selSkill = nil
				end)
			end
		elseif key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex and self.selDragIndex ~= self.selIndex then
					t_remove(self.skillsTab.list, self.selIndex)
					if self.selDragIndex > self.selIndex then
						self.selDragIndex = self.selDragIndex - 1
					end
					t_insert(self.skillsTab.list, self.selDragIndex, self.selSkill)
					self.skillsTab:AddUndoState()
					self.selSkill = nil
				end
			end
		end
	end
	return self
end