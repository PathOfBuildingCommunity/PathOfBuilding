-- Path of Building
--
-- Module: BuildSetService
-- Build set service for managing loadouts.

-- Utility functions
local m_max = math.max


local BuildSetServiceClass = newClass("BuildSetService", function(self, buildMode)
	self.buildMode = buildMode
end)

function BuildSetServiceClass:NewLoadout(name)
	self.buildMode:NewLoadout(name, function()
		self.buildMode:SyncLoadouts()
		self.buildMode.modFlag = true
		self.buildMode.controls.buildLoadouts:SetSel(1)
	end)
end

function BuildSetServiceClass:CopyLoadout(specId, itemSetId, skillSetId, configSetId, newName)
	local newSpec = self.buildMode:CopyLoadout(specId, itemSetId, skillSetId, configSetId, newName)
	self.buildMode:SyncLoadouts()
	self.buildMode.modFlag = true
	self.buildMode.controls.buildLoadouts:SetSel(newSpec.id + 1)
end

function BuildSetServiceClass:RenameLoadout(oldName, newName)
	self.buildMode:RenameLoadout(oldName, newName, function()
		self.buildMode:SyncLoadouts()
		self.buildMode.modFlag = true
	end)
end

function BuildSetServiceClass:DeleteLoadout(index, list, spec)
	local nextLoadoutIndex = index == self.buildMode.treeTab.activeSpec and (index > 1 and index - 1 or index + 1) or
		self.buildMode.treeTab.activeSpec
	local nextLoadout = list[nextLoadoutIndex]
	self.buildMode:DeleteLoadout(spec.title or "Default", nextLoadout.title or "Default")
end
