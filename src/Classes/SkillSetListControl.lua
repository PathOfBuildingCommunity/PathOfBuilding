-- Path of Building
--
-- Class: Skill Set List
-- Skill set list control.
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local s_format = string.format

local SkillSetListClass = newClass("SkillSetListControl", "ListControl", function(self, anchor, x, y, width, height, skillsTab)
	self.ListControl(anchor, x, y, width, height, 16, "VERTICAL", true, skillsTab.skillSetOrderList)
	self.skillsTab = skillsTab
	self.controls.copy = new("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, 2, -4, 60, 18, "Copy", function()
		local skillSet = skillsTab.skillSets[self.selValue]
		local newSkillSet = copyTable(skillSet, true)
		newSkillSet.socketGroupList = { }
		for socketGroupIndex, socketGroup in pairs(skillSet.socketGroupList) do
			local newGroup = copyTable(socketGroup, true)
			newGroup.gemList = { }
			for gemIndex, gem in pairs(socketGroup.gemList) do
				newGroup.gemList[gemIndex] = copyTable(gem, true)
			end
			t_insert(newSkillSet.socketGroupList, newGroup)
		end
		newSkillSet.id = 1
		while skillsTab.skillSets[newSkillSet.id] do
			newSkillSet.id = newSkillSet.id + 1
		end
		skillsTab.skillSets[newSkillSet.id] = newSkillSet
		self:RenameSet(newSkillSet, true)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, 4, 0, 60, 18, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.rename = new("ButtonControl", {"BOTTOMRIGHT",self,"TOP"}, -2, -4, 60, 18, "Rename", function()
		self:RenameSet(skillsTab.skillSets[self.selValue])
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, -4, 0, 60, 18, "New", function()
		self:RenameSet(skillsTab:NewSkillSet(), true)
	end)
end)

function SkillSetListClass:RenameSet(skillSet, addOnName)
	local controls = { }
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "^7Enter name for this skill set:")
	controls.edit = new("EditControl", nil, 0, 40, 350, 20, skillSet.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
		skillSet.title = controls.edit.buf
		self.skillsTab.modFlag = true
		if addOnName then
			t_insert(self.list, skillSet.id)
			self.selIndex = #self.list
			self.selValue = skillSet
		end
		self.skillsTab:AddUndoState()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		if addOnName then
			self.skillsTab.skillSets[skillSet.id] = nil
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, skillSet.title and "Rename" or "Set Name", controls, "save", "edit", "cancel")
end

function SkillSetListClass:GetRowValue(column, index, skillSetId)
	local skillSet = self.skillsTab.skillSets[skillSetId]
	if column == 1 then
		return (skillSet.title or "Default") .. (skillSetId == self.skillsTab.activeSkillSetId and "  ^9(Current)" or "")
	end
end

function SkillSetListClass:OnOrderChange()
	self.skillsTab.modFlag = true
end

function SkillSetListClass:OnSelClick(index, skillSetId, doubleClick)
	if doubleClick and skillSetId ~= self.skillsTab.activeSkillSetId then
		self.skillsTab:SetActiveSkillSet(skillSetId)
		self.skillsTab:AddUndoState()
	end
end

function SkillSetListClass:OnSelDelete(index, skillSetId)
	local skillSet = self.skillsTab.skillSets[skillSetId]
	if #self.list > 1 then
		main:OpenConfirmPopup("Delete Item Set", "Are you sure you want to delete '"..(skillSet.title or "Default").."'?", "Delete", function()
			t_remove(self.list, index)
			self.skillsTab.skillSets[skillSetId] = nil
			self.selIndex = nil
			self.selValue = nil
			if skillSetId == self.skillsTab.activeSkillSetId then
				self.skillsTab:SetActiveSkillSet(self.list[m_max(1, index - 1)])
			end
			self.skillsTab:AddUndoState()
		end)
	end
end

function SkillSetListClass:OnSelKeyDown(index, skillSetId, key)
	if key == "F2" then
		self:RenameSet(skillSetId)
	end
end
