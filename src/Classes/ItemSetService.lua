-- Path of Building
--
-- Module: ItemSetService
-- Item set service for managing item sets.
--

local m_max = math.max

local ItemSetServiceClass = newClass("ItemSetService", function(self, itemsTab)
	self.itemsTab = itemsTab
end)

function ItemSetServiceClass:NewItemSet(name)
	local itemSet = self.itemsTab:NewItemSet(nil, name)
	self.itemsTab:SetActiveItemSet(itemSet.id, true)
	self.itemsTab:AddUndoState()
	self.itemsTab.build:SyncLoadouts()
	self.itemsTab.build.buildFlag = true
end

function ItemSetServiceClass:CopyItemSet(itemSetId, name)
	local itemSet = self.itemsTab:CopyItemSet(itemSetId, name)
	self.itemsTab:SetActiveItemSet(itemSet.id, true)
	self.itemsTab:AddUndoState()
	self.itemsTab.build:SyncLoadouts()
	self.itemsTab.build.buildFlag = true
end

function ItemSetServiceClass:RenameItemSet(itemSetId, newName)
	self.itemsTab:RenameItemSet(itemSetId, newName)
	self.itemsTab:AddUndoState()
	self.itemsTab.build:SyncLoadouts()
	self.itemsTab.build.buildFlag = true
end

function ItemSetServiceClass:DeleteItemSet(itemSetId, orderListIndex)
	if #self.itemsTab.itemSetOrderList > 1 then
		self.itemsTab:DeleteItemSet(itemSetId, orderListIndex)
		if itemSetId == self.itemsTab.activeItemSetId then
			self.itemsTab:SetActiveItemSet(self.itemsTab.itemSetOrderList[m_max(1, orderListIndex - 1)], true)
		end
		self.itemsTab:AddUndoState()
		self.itemsTab.build:SyncLoadouts()
		self.itemsTab.build.buildFlag = true
	end
end
