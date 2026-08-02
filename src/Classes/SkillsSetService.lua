-- Path of Building
--
-- Module: SkillsSetService
-- Skill set service for managing skill sets.
--

local m_max = math.max

local SkillsSetServiceClass = newClass("SkillsSetService", function(self, skillsTab)
	self.skillsTab = skillsTab
end)

function SkillsSetServiceClass:NewSkillSet(name)
	local skillSet = self.skillsTab:NewSkillSet(nil, name)
	self.skillsTab:SetActiveSkillSet(skillSet.id, true)
	self.skillsTab:AddUndoState()
	self.skillsTab.build:SyncLoadouts()
end

function SkillsSetServiceClass:CopySkillSet(skillSetId, name)
	local skillSet = self.skillsTab:CopySkillSet(skillSetId, name)
	self.skillsTab:SetActiveSkillSet(skillSet.id, true)
	self.skillsTab:AddUndoState()
	self.skillsTab.build:SyncLoadouts()
end

function SkillsSetServiceClass:RenameSkillSet(skillSetId, newName)
	self.skillsTab:RenameSkillSet(skillSetId, newName)
	self.skillsTab:AddUndoState()
	self.skillsTab.build:SyncLoadouts()
end

function SkillsSetServiceClass:DeleteSkillSet(skillSetId, orderListIndex)
	if #self.skillsTab.skillSetOrderList > 1 then
		self.skillsTab:DeleteSkillSet(skillSetId, orderListIndex)
		if skillSetId == self.skillsTab.activeSkillSetId then
			self.skillsTab:SetActiveSkillSet(self.skillsTab.skillSetOrderList[m_max(1, orderListIndex - 1)], true)
		end
		self.skillsTab:AddUndoState()
		self.skillsTab.build:SyncLoadouts()
	end
end
