-- Path of Building
--
-- Module: BuildSetService
-- Build set service for managing loadouts.

local BuildSetServiceClass = newClass("BuildSetService", function(self, buildMode)
	self.buildMode = buildMode
end)

function BuildSetServiceClass:NewLoadout(name)
	self.buildMode:NewLoadout(name)
end

function BuildSetServiceClass:CopyLoadout(copyLoadoutName, newName)
	self.buildMode:CopyLoadout(copyLoadoutName, newName)
end

function BuildSetServiceClass:RenameLoadout(oldName, newName)
	self.buildMode:RenameLoadout(oldName, newName)
	self.buildMode:SyncLoadouts()
end

function BuildSetServiceClass:DeleteLoadout(index, list, spec)
	local nextLoadoutIndex = index == self.buildMode.activeLoadout and (index > 1 and index - 1 or index + 1) or
		self.buildMode.activeLoadout or 1
	local nextLoadout = list[nextLoadoutIndex]
	self.buildMode:DeleteLoadout(spec.title or "Default", nextLoadout.title or "Default")
end

function BuildSetServiceClass:CustomLoadout(specId, itemSetId, skillSetId, configSetId, name)
	self.buildMode:CustomLoadout(specId, itemSetId, skillSetId, configSetId, name)
end

function BuildSetServiceClass:ReorderLoadout(oldIndex, newIndex)
	self.buildMode:ReorderLoadout(oldIndex, newIndex)
end

function BuildSetServiceClass:SpecNameLookup()
	local lookup = {}
	for _, specTitle in ipairs(self.buildMode.treeTab:GetSpecList()) do
		lookup[specTitle] = true
	end
	return lookup
end
