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
	self.buildMode:NewLoadout(name)
	self.buildMode:SyncLoadouts()
	self.buildMode.controls.buildLoadouts:SetSel(1)
end

function BuildSetServiceClass:CopyLoadout(specId, itemSetId, skillSetId, configSetId, newName)
	local newSpec = self.buildMode:CopyLoadout(specId, itemSetId, skillSetId, configSetId, newName)
	self.buildMode:SyncLoadouts()
	self.buildMode.controls.buildLoadouts:SetSel(newSpec.id + 1)
end

function BuildSetServiceClass:RenameLoadout(oldName, newName)
	self.buildMode:RenameLoadout(oldName, newName)
	self.buildMode:SyncLoadouts()
end

function BuildSetServiceClass:DeleteLoadout(index, list, spec)
	local nextLoadoutIndex = index == self.buildMode.treeTab.activeSpec and (index > 1 and index - 1 or index + 1) or
		self.buildMode.treeTab.activeSpec
	local nextLoadout = list[nextLoadoutIndex]
	self.buildMode:DeleteLoadout(spec.title or "Default", nextLoadout.title or "Default")
end

function BuildSetServiceClass:CustomLoadout(specId, itemSetId, skillSetId, configSetId, name)
	local newSpec = self.buildMode:CustomLoadout(specId, itemSetId, skillSetId, configSetId, name)
	self.buildMode:SyncLoadouts()
	local selectedIndex = newSpec.id and newSpec.id or #self.buildMode.treeTab.specList
	self.buildMode.controls.buildLoadouts:SetSel(selectedIndex + 1)
end

function BuildSetServiceClass:ReorderLoadout(oldIndex, newIndex)
	if oldIndex < newIndex then
		if oldIndex > self.buildMode.treeTab.activeSpec or newIndex < self.buildMode.treeTab.activeSpec then
			return
		end

		if oldIndex == self.buildMode.treeTab.activeSpec then
			self.buildMode:SetActiveLoadout(self.buildMode:GetLoadoutByName(self.buildMode.treeTab.specList[newIndex]
				.title or "Default"))
		elseif newIndex >= self.buildMode.treeTab.activeSpec then
			self.buildMode:SetActiveLoadout(self.buildMode:GetLoadoutByName(self.buildMode.treeTab.specList
				[self.buildMode.treeTab.activeSpec - 1].title or "Default"))
		end
	else
		if oldIndex < self.buildMode.treeTab.activeSpec or newIndex > self.buildMode.treeTab.activeSpec then
			return
		end

		if oldIndex == self.buildMode.treeTab.activeSpec then
			self.buildMode:SetActiveLoadout(self.buildMode:GetLoadoutByName(self.buildMode.treeTab.specList[newIndex]
				.title or "Default"))
		elseif newIndex <= self.buildMode.treeTab.activeSpec then
			self.buildMode:SetActiveLoadout(self.buildMode:GetLoadoutByName(self.buildMode.treeTab.specList
				[self.buildMode.treeTab.activeSpec + 1].title or "Default"))
		end
	end
end
