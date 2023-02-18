-- Path of Building
--
-- Class: Skill List
-- Skill list control.
--
local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local SkillListClass = newClass("SkillListControl", "ListControl", function(self, anchor, x, y, width, height, skillsTab)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", true, skillsTab.socketGroupList)
	self.skillsTab = skillsTab
	self.label = "^7Socket Groups:"
	self.controls.delete = new("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and self.selValue.source == nil
	end
	self.controls.deleteAll = new("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 70, 18, "Delete All", function()
		main:OpenConfirmPopup("Delete All", "Are you sure you want to delete all socket groups in this build?", "Delete", function()
			wipeTable(self.list)
			skillsTab:SetDisplayGroup()
			skillsTab:AddUndoState()
			skillsTab.build.buildFlag = true
			self.selIndex = nil
			self.selValue = nil
		end)
	end)
	self.controls.deleteAll.enabled = function()
		return #self.list > 0 
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.deleteAll,"LEFT"}, -4, 0, 60, 18, "New", function()
		local newGroup = { 
			label = "", 
			enabled = true, 
			gemList = { } 
		}
		t_insert(self.list, newGroup)
		self.selIndex = #self.list
		self.selValue = newGroup
		skillsTab:SetDisplayGroup(newGroup)
		skillsTab:AddUndoState()
		skillsTab.build.buildFlag = true
		return skillsTab.gemSlots[1].nameSpec
	end)
end)

function SkillListClass:GetRowValue(column, index, socketGroup)
	if column == 1 then
		local label = socketGroup.displayLabel or "?"
		if not socketGroup.enabled or not socketGroup.slotEnabled then
			label = "^x7F7F7F" .. label .. " (Disabled)"
		end
		if self.skillsTab.build.mainSocketGroup == index then 
			label = label .. colorCodes.RELIC .. " (Active)"
		end
		if socketGroup.includeInFullDPS then 
			label = label .. colorCodes.CUSTOM .. " (FullDPS)"
		end
		return label
	end
end

function SkillListClass:AddValueTooltip(tooltip, index, socketGroup)
	if not socketGroup.displaySkillList then
		tooltip:Clear()
		return
	end
	if tooltip:CheckForUpdate(socketGroup, self.skillsTab.build.outputRevision) then
		self.skillsTab:AddSocketGroupTooltip(tooltip, socketGroup)
	end
end

function SkillListClass:OnOrderChange(selIndex, selDragIndex)
	local skillsTabIndex = self.skillsTab.build.mainSocketGroup
	if skillsTabIndex == selIndex then
		self.skillsTab.build.mainSocketGroup = selDragIndex
	elseif skillsTabIndex > selIndex and skillsTabIndex <= selDragIndex then
		self.skillsTab.build.mainSocketGroup = skillsTabIndex - 1
	elseif skillsTabIndex < selIndex and skillsTabIndex >= selDragIndex then
		self.skillsTab.build.mainSocketGroup = skillsTabIndex + 1
	end
	local calcsTabIndex = self.skillsTab.build.calcsTab.input.skill_number
	if calcsTabIndex == selIndex then
		self.skillsTab.build.calcsTab.input.skill_number = selDragIndex
	elseif calcsTabIndex > selIndex and calcsTabIndex <= selDragIndex then
		self.skillsTab.build.calcsTab.input.skill_number = calcsTabIndex - 1
	elseif calcsTabIndex < selIndex and calcsTabIndex >= selDragIndex then
		self.skillsTab.build.calcsTab.input.skill_number = calcsTabIndex + 1
	end
	self.skillsTab:AddUndoState()
	self.skillsTab.build.buildFlag = true
end

function SkillListClass:OnSelect(index, socketGroup)
	self.skillsTab:SetDisplayGroup(socketGroup)
end

function SkillListClass:OnSelCopy(index, socketGroup)
	if not socketGroup.source then	
		self.skillsTab:CopySocketGroup(socketGroup)
	end
end

function SkillListClass:OnSelDelete(index, socketGroup)
	local function updateActiveSocketGroupIndex()
		local skillsTabIndex = self.skillsTab.build.mainSocketGroup
		if skillsTabIndex > self.selIndex then
			self.skillsTab.build.mainSocketGroup = skillsTabIndex - 1
		end
		local calcsTabIndex = self.skillsTab.build.calcsTab.input.skill_number
		if calcsTabIndex > self.selIndex then
			self.skillsTab.build.calcsTab.input.skill_number = calcsTabIndex - 1
		end
	end
	if socketGroup.source then
		main:OpenMessagePopup("Delete Socket Group", "This socket group cannot be deleted as it is created by an equipped item.")
	elseif not socketGroup.gemList[1] then
		t_remove(self.list, index)
		if self.skillsTab.displayGroup == socketGroup then
			self.skillsTab.displayGroup = nil
		end
		updateActiveSocketGroupIndex()
		self.skillsTab:AddUndoState()
		self.skillsTab.build.buildFlag = true
		self.selValue = nil
	else
		main:OpenConfirmPopup("Delete Socket Group", "Are you sure you want to delete '"..socketGroup.displayLabel.."'?", "Delete", function()
			t_remove(self.list, index)
			if self.skillsTab.displayGroup == socketGroup then
				self.skillsTab:SetDisplayGroup()
			end
			updateActiveSocketGroupIndex()
			self.skillsTab:AddUndoState()
			self.skillsTab.build.buildFlag = true
			self.selValue = nil
		end)
	end
end

function SkillListClass:OnHoverKeyUp(key)
	local item = self.ListControl:GetHoverValue()
	if item then
		if itemLib.wiki.matchesKey(key) then
			-- Get the first gem in the group
			local gem = item.gemList[1]
			if gem then
				itemLib.wiki.openGem(gem.gemData)
			end
		elseif key == "RIGHTBUTTON" then
			if IsKeyDown("CTRL") then
				item.includeInFullDPS = not item.includeInFullDPS
				if item == self.skillsTab.displayGroup then
					self.skillsTab:SetDisplayGroup(item)
				end
				self.skillsTab:AddUndoState()
				self.skillsTab.build.buildFlag = true
			else
				local index = self.ListControl:GetHoverIndex()
				if index then
					self.skillsTab.build.mainSocketGroup = index
					self.skillsTab:AddUndoState()
					self.skillsTab.build.buildFlag = true
				end
			end
		elseif key == "LEFTBUTTON" and IsKeyDown("CTRL") then
			item.enabled = not item.enabled
			if item == self.skillsTab.displayGroup then
				self.skillsTab:SetDisplayGroup(item)
			end
			self.skillsTab:AddUndoState()
			self.skillsTab.build.buildFlag = true
		end
	end
end
