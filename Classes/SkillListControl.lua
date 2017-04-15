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
		return self.selGroup ~= nil and self.selGroup.source == nil
	end
	self.controls.paste = common.New("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 60, 18, "Paste", function()
		self.skillsTab:PasteSocketGroup()
	end)
	self.controls.copy = common.New("ButtonControl", {"RIGHT",self.controls.paste,"LEFT"}, -4, 0, 60, 18, "Copy", function()
		self.skillsTab:CopySocketGroup(self.selGroup)
	end)
	self.controls.copy.enabled = function()
		return self.selGroup ~= nil and self.selGroup.source == nil
	end
	self.controls.new = common.New("ButtonControl", {"RIGHT",self.controls.copy,"LEFT"}, -4, 0, 60, 18, "New", function()
		local newGroup = { label = "", enabled = true, gemList = { } }
		t_insert(self.skillsTab.socketGroupList, newGroup)
		self.selGroup = newGroup
		self.selIndex = #self.skillsTab.socketGroupList
		self.skillsTab:SetDisplayGroup(newGroup)
		self.skillsTab:AddUndoState()
		self.skillsTab.build.buildFlag = true
		return self.skillsTab.gemSlots[1].nameSpec
	end)
end)

function SkillListClass:SelectIndex(index)
	self.selGroup = self.skillsTab.socketGroupList[index]
	if self.selGroup then
		self.selIndex = index
		self.skillsTab:SetDisplayGroup(self.selGroup)
		self.controls.scrollBar:ScrollIntoView((index - 2) * 16, 48)
	end
end

function SkillListClass:IsMouseOver()
	if not self:IsShown() then
		return
	end
	return self:IsMouseInBounds() or self:GetMouseOverControl()
end

function SkillListClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local list = self.skillsTab.socketGroupList
	local scrollBar = self.controls.scrollBar
	scrollBar:SetContentDimension(#list * 16, height - 4)
	self.selDragIndex = nil
	if self.selGroup and self.selDragging then
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
	DrawString(x, y - 20, "LEFT", 16, "VAR", "^7Socket Groups:")
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
	local ttGroup, ttY, ttWidth
	local minIndex = m_floor(scrollBar.offset / 16 + 1)
	local maxIndex = m_min(m_floor((scrollBar.offset + height) / 16 + 1), #list)
	for index = minIndex, maxIndex do
		local socketGroup = list[index]
		local lineY = 16 * (index - 1) - scrollBar.offset
		local label = socketGroup.displayLabel or "?"
		if not socketGroup.enabled then
			label = label .. " (Disabled)"
		end
		local nameWidth = DrawStringWidth(16, "VAR", label)
		if not scrollBar.dragging and not self.selDragActive and (not self.skillsTab.selControl or self.hasFocus) then
			local cursorX, cursorY = GetCursorPos()
			local relX = cursorX - (x + 2)
			local relY = cursorY - (y + 2)
			if relX >= 0 and relX < width - 17 and relY >= 0 and relY >= lineY and relY < height - 2 and relY < lineY + 16 then
				ttGroup = socketGroup
				ttWidth = m_max(nameWidth + 8, relX)
				ttY = lineY + y + 2
			end
		end
		if socketGroup == ttGroup or socketGroup == self.selGroup then
			if self.hasFocus then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, 0, lineY, width - 20, 16)
			SetDrawColor(0.15, 0.15, 0.15)
			DrawImage(nil, 0, lineY + 1, width - 20, 14)		
		end
		if socketGroup.enabled then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
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
	if ttGroup and ttGroup.displaySkillList then
		local count = 0
		local gemShown = { }
		if ttGroup.sourceItem then
			main:AddTooltipLine(18, "^7Source: "..data.colorCodes[ttGroup.sourceItem.rarity]..ttGroup.sourceItem.name)
			main:AddTooltipSeparator(10)
		end
		for index, activeSkill in ipairs(ttGroup.displaySkillList) do
			if index > 1 then
				main:AddTooltipSeparator(10)
			end
			main:AddTooltipLine(16, "^7Active Skill #"..index..":")
			for _, gem in ipairs(activeSkill.gemList) do
				main:AddTooltipLine(20, string.format("%s%s ^7%d%s/%d%s", 
					data.skillColorMap[gem.data.color], 
					gem.name, 
					gem.level, 
					(gem.srcGem and gem.level > gem.srcGem.level) and data.colorCodes.MAGIC.."+"..(gem.level - gem.srcGem.level).."^7" or "",
					gem.quality,
					(gem.srcGem and gem.quality > gem.srcGem.quality) and data.colorCodes.MAGIC.."+"..(gem.quality - gem.srcGem.quality).."^7" or ""
				))
				gemShown[gem.srcGem] = true
				count = count + 1
			end
			if activeSkill.minion then
				main:AddTooltipSeparator(10)
				main:AddTooltipLine(16, "^7Active Skill #"..index.."'s Main Minion Skill:")
				local gem = activeSkill.minion.mainSkill.gemList[1]
				main:AddTooltipLine(20, string.format("%s%s ^7%d%s/%d%s", 
					data.skillColorMap[gem.data.color], 
					gem.name, 
					gem.level, 
					(gem.srcGem and gem.level > gem.srcGem.level) and data.colorCodes.MAGIC.."+"..(gem.level - gem.srcGem.level).."^7" or "",
					gem.quality,
					(gem.srcGem and gem.quality > gem.srcGem.quality) and data.colorCodes.MAGIC.."+"..(gem.quality - gem.srcGem.quality).."^7" or ""
				))
				gemShown[gem.srcGem] = true
				count = count + 1
			end
		end
		local showOtherHeader = true
		for _, gem in ipairs(ttGroup.gemList) do
			if not gemShown[gem] then
				if showOtherHeader then
					showOtherHeader = false
					main:AddTooltipSeparator(10)
					main:AddTooltipLine(16, "^7Inactive Gems:")
				end
				local reason = ""
				if not gem.data then
					reason = "(Unsupported)"
				elseif not gem.enabled then
					reason = "(Disabled)"
				elseif gem.data.support and gem.isSupporting and not next(gem.isSupporting) then
					reason = "(Cannot apply to any of the active skills)"
				end
				main:AddTooltipLine(20, string.format("%s%s ^7%d/%d %s", 
					gem.color, 
					gem.name or gem.nameSpec, 
					gem.level, 
					gem.quality,
					reason
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
		self.selGroup = nil
		self.selIndex = nil
		local x, y = self:GetPos()
		local width, height = self:GetSize()
		local cursorX, cursorY = GetCursorPos()
		if cursorX >= x + 2 and cursorY >= y + 2 and cursorX < x + width - 18 and cursorY < y + height - 2 then
			local index = math.floor((cursorY - y - 2 + self.controls.scrollBar.offset) / 16) + 1
			local selGroup = self.skillsTab.socketGroupList[index]
			if selGroup then
				self.selGroup = selGroup
				self.selIndex = index
				self.skillsTab:SetDisplayGroup(selGroup)
			end
		end
		if self.selGroup then
			self.selCX = cursorX
			self.selCY = cursorY
			self.selDragging = true
			self.selDragActive = false
		end
	elseif key == "c" and IsKeyDown("CTRL") then
		if self.selGroup and not self.selGroup.source then	
			self.skillsTab:CopySocketGroup(self.selGroup)
		end
	elseif #self.skillsTab.socketGroupList > 0 then
		if key == "UP" then
			self:SelectIndex(((self.selIndex or 1) - 2) % #self.skillsTab.socketGroupList + 1)
		elseif key == "DOWN" then
			self:SelectIndex((self.selIndex or #self.skillsTab.socketGroupList) % #self.skillsTab.socketGroupList + 1)
		elseif key == "HOME" then
			self:SelectIndex(1)
		elseif key == "END" then
			self:SelectIndex(#self.skillsTab.socketGroupList)
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
	elseif self.selGroup then
		if key == "BACK" or key == "DELETE" then
			if self.selGroup.source then
				main:OpenMessagePopup("Delete Socket Group", "This socket group cannot be deleted as it is created by an equipped item.")
			elseif not self.selGroup.gemList[1] then
				t_remove(self.skillsTab.socketGroupList, self.selIndex)
				if self.skillsTab.displayGroup == self.selGroup then
					self.skillsTab.displayGroup = nil
				end
				self.skillsTab:AddUndoState()
				self.skillsTab.build.buildFlag = true
				self.selGroup = nil
			else
				main:OpenConfirmPopup("Delete Socket Group", "Are you sure you want to delete '"..self.selGroup.displayLabel.."'?", "Delete", function()
					t_remove(self.skillsTab.socketGroupList, self.selIndex)
					if self.skillsTab.displayGroup == self.selGroup then
						self.skillsTab.displayGroup = nil
					end
					self.skillsTab:AddUndoState()
					self.skillsTab.build.buildFlag = true
					self.selGroup = nil
				end)
			end
		elseif key == "LEFTBUTTON" then
			self.selDragging = false
			if self.selDragActive then
				self.selDragActive = false
				if self.selDragIndex and self.selDragIndex ~= self.selIndex then
					t_remove(self.skillsTab.socketGroupList, self.selIndex)
					if self.selDragIndex > self.selIndex then
						self.selDragIndex = self.selDragIndex - 1
					end
					t_insert(self.skillsTab.socketGroupList, self.selDragIndex, self.selGroup)
					self.skillsTab:AddUndoState()
					self.skillsTab.build.buildFlag = true
					self.selGroup = nil
				end
			end
		end
	end
	return self
end