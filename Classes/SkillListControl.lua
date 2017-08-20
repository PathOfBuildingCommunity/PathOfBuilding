-- Path of Building
--
-- Class: Skill List
-- Skill list control.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove

local SkillListClass = common.NewClass("SkillList", "ListControl", function(self, anchor, x, y, width, height, skillsTab)
	self.ListControl(anchor, x, y, width, height, 16, true, skillsTab.socketGroupList)
	self.skillsTab = skillsTab
	self.label = "^7Socket Groups:"
	self.controls.delete = common.New("ButtonControl", {"BOTTOMRIGHT",self,"TOPRIGHT"}, 0, -2, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and self.selValue.source == nil
	end
	self.controls.deleteAll = common.New("ButtonControl", {"RIGHT",self.controls.delete,"LEFT"}, -4, 0, 70, 18, "Delete All", function()
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
	self.controls.new = common.New("ButtonControl", {"RIGHT",self.controls.deleteAll,"LEFT"}, -4, 0, 60, 18, "New", function()
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

function SkillListClass:OnOrderChange()
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
	if socketGroup.source then
		main:OpenMessagePopup("Delete Socket Group", "This socket group cannot be deleted as it is created by an equipped item.")
	elseif not socketGroup.gemList[1] then
		t_remove(self.list, index)
		if self.skillsTab.displayGroup == socketGroup then
			self.skillsTab.displayGroup = nil
		end
		self.skillsTab:AddUndoState()
		self.skillsTab.build.buildFlag = true
		self.selValue = nil
	else
		main:OpenConfirmPopup("Delete Socket Group", "Are you sure you want to delete '"..socketGroup.displayLabel.."'?", "Delete", function()
			t_remove(self.list, index)
			if self.skillsTab.displayGroup == socketGroup then
				self.skillsTab:SetDisplayGroup()
			end
			self.skillsTab:AddUndoState()
			self.skillsTab.build.buildFlag = true
			self.selValue = nil
		end)
	end
end
