-- Path of Building
--
-- Module: BuildSetService
-- Build set service for managing loadouts.

-- Utility functions
local m_max = math.max
local t_insert = table.insert


local BuildSetServiceClass = newClass("BuildSetService", function(self, buildMode)
	self.buildMode = buildMode
end)

function BuildSetServiceClass:NewLoadout(name)
	self.buildMode:NewLoadout(name, function()
		self.buildMode:SyncLoadouts()
		self.buildMode.controls.buildLoadouts:SetSel(1)
	end)
end

function BuildSetServiceClass:CopyLoadout(specId, itemSetId, skillSetId, configSetId, newName)
	local newSpec = self.buildMode:CopyLoadout(specId, itemSetId, skillSetId, configSetId, newName)
	self.buildMode:SyncLoadouts()
	self.buildMode.controls.buildLoadouts:SetSel(newSpec.id + 1)
end

function BuildSetServiceClass:RenameLoadout(oldName, newName)
	self.buildMode:RenameLoadout(oldName, newName, function()
		self.buildMode:SyncLoadouts()
	end)
end

function BuildSetServiceClass:DeleteLoadout(index, list, spec)
	local nextLoadoutIndex = index == self.buildMode.treeTab.activeSpec and (index > 1 and index - 1 or index + 1) or
		self.buildMode.treeTab.activeSpec
	local nextLoadout = list[nextLoadoutIndex]
	self.buildMode:DeleteLoadout(spec.title or "Default", nextLoadout.title or "Default")
end

function BuildSetServiceClass:CustomLoadout(specId, itemSetId, skillSetId, configSetId, name)
	local newSpec
	if specId == -1 then
		newSpec = new("PassiveSpec", self.buildMode, latestTreeVersion)
		newSpec.id = #self.buildMode.treeTab.specList + 1
		t_insert(self.buildMode.treeTab.specList, newSpec)
	else
		newSpec = self.buildMode.treeTab:CopyTree(specId, name)
	end
	newSpec.title = name

	local newItemSet
	if itemSetId == -1 then
		newItemSet = self.buildMode.itemsTab:NewItemSet(#self.buildMode.itemsTab.itemSets + 1)
	else
		newItemSet = self.buildMode.itemsTab:CopyItemSet(itemSetId, name)
	end
	t_insert(self.buildMode.itemsTab.itemSetOrderList, newItemSet.id)
	newItemSet.title = name

	local newSkillSet
	if skillSetId == -1 then
		newSkillSet = self.buildMode.skillsTab:NewSkillSet(#self.buildMode.skillsTab.skillSets + 1)
	else
		newSkillSet = self.buildMode.skillsTab:CopySkillSet(skillSetId, name)
	end
	t_insert(self.buildMode.skillsTab.skillSetOrderList, newSkillSet.id)
	newSkillSet.title = name

	local newConfigSet
	if configSetId == -1 then
		newConfigSet = self.buildMode.configTab:NewConfigSet(#self.buildMode.configTab.configSets + 1)
	else
		newConfigSet = self.buildMode.configTab:CopyConfigSet(configSetId, name)
	end
	t_insert(self.buildMode.configTab.configSetOrderList, newConfigSet.id)
	newConfigSet.title = name

	self.buildMode:SyncLoadouts()
	local selectedIndex = newSpec.id and newSpec.id or #self.buildMode.treeTab.specList
	self.buildMode.controls.buildLoadouts:SetSel(selectedIndex + 1)
	self.buildMode.modFlag = true
end
