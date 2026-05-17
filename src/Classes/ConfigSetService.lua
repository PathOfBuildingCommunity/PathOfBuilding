-- Path of Building
--
-- Module: ConfigSetService
-- Config set service for managing config sets.
--

local m_max = math.max

local ConfigSetServiceClass = newClass("ConfigSetService", function(self, configTab)
	self.configTab = configTab
end)

function ConfigSetServiceClass:NewConfigSet(name)
	local configSet = self.configTab:NewConfigSet(nil, name)
	self.configTab:SetActiveConfigSet(configSet.id, false, true)
	self.configTab:AddUndoState()
	self.configTab.build:SyncLoadouts()
end

function ConfigSetServiceClass:CopyConfigSet(configSetId, name)
	local configSet = self.configTab:CopyConfigSet(configSetId, name)
	self.configTab:SetActiveConfigSet(configSet.id, false, true)
	self.configTab:AddUndoState()
	self.configTab.build:SyncLoadouts()
end

function ConfigSetServiceClass:RenameConfigSet(configSetId, newName)
	self.configTab:RenameConfigSet(configSetId, newName)
	self.configTab:AddUndoState()
	self.configTab.build:SyncLoadouts()
end

function ConfigSetServiceClass:DeleteConfigSet(configSetId, orderListIndex)
	if #self.configTab.configSetOrderList > 1 then
		self.configTab:DeleteConfigSet(configSetId, orderListIndex)
		if configSetId == self.configTab.activeConfigSetId then
			self.configTab:SetActiveConfigSet(self.configTab.configSetOrderList[m_max(1, orderListIndex - 1)], false, true)
		end
		self.configTab:AddUndoState()
		self.configTab.build:SyncLoadouts()
	end
end
