-- Path of Building
--
-- Class: Mercenary Set List
-- Mercenary loadout list control.
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max

local MercenarySetListClass = newClass("MercenarySetListControl", "ListControl")

function MercenarySetListClass:MercenarySetListControl(anchor, rect, mercenaryTab)
	self:ListControl(anchor, rect, 16, "VERTICAL", true, mercenaryTab.mercenarySetOrderList)
	self.mercenaryTab = mercenaryTab
	self.controls.copy = new("ButtonControl"):ButtonControl({"BOTTOMLEFT", self, "TOP"}, {2, -4, 60, 18}, "Copy", function()
		local set = mercenaryTab.mercenarySets[self.selValue]
		local newSet = copyTable(set)
		newSet.importAssociation = nil
		newSet.id = 1
		while mercenaryTab.mercenarySets[newSet.id] do
			newSet.id = newSet.id + 1
		end
		mercenaryTab.mercenarySets[newSet.id] = newSet
		self:RenameSet(newSet, true)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({"LEFT", self.controls.copy, "RIGHT"}, {4, 0, 60, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.rename = new("ButtonControl"):ButtonControl({"BOTTOMRIGHT", self, "TOP"}, {-2, -4, 60, 18}, "Rename", function()
		self:RenameSet(mercenaryTab.mercenarySets[self.selValue])
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl"):ButtonControl({"RIGHT", self.controls.rename, "LEFT"}, {-4, 0, 60, 18}, "New", function()
		self:RenameSet(mercenaryTab:NewMercenarySet(), true)
	end)
	return self
end

function MercenarySetListClass:RenameSet(set, addOnName)
	local controls = { }
	controls.label = new("LabelControl"):LabelControl(nil, {0, 20, 0, 16}, "^7Enter name for this Mercenary loadout:")
	controls.edit = new("EditControl"):EditControl(nil, {0, 40, 350, 20}, set.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 70, 80, 20}, "Save", function()
		set.title = controls.edit.buf
		self.mercenaryTab.modFlag = true
		if addOnName then
			t_insert(self.list, set.id)
			self.selIndex = #self.list
			self.selValue = set.id
		end
		self.mercenaryTab:RefreshControls()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {45, 70, 80, 20}, "Cancel", function()
		if addOnName then
			self.mercenaryTab.mercenarySets[set.id] = nil
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, set.title and "Rename" or "Set Name", controls, "save", "edit", "cancel")
end

function MercenarySetListClass:GetRowValue(column, _, setId)
	local set = self.mercenaryTab.mercenarySets[setId]
	if column == 1 then
		return (set.title or "Default") .. (setId == self.mercenaryTab.activeMercenarySetId and "  ^9(Current)" or "")
	end
end

function MercenarySetListClass:OnOrderChange()
	self.mercenaryTab.modFlag = true
end

function MercenarySetListClass:OnSelClick(_, setId, doubleClick)
	if doubleClick and setId ~= self.mercenaryTab.activeMercenarySetId then
		self.mercenaryTab:SetActiveMercenarySet(setId)
	end
end

function MercenarySetListClass:OnSelDelete(index, setId)
	local set = self.mercenaryTab.mercenarySets[setId]
	if #self.list > 1 then
		main:OpenConfirmPopup("Delete Mercenary Loadout", "Are you sure you want to delete '"..(set.title or "Default").."'?", "Delete", function()
			t_remove(self.list, index)
			self.mercenaryTab.mercenarySets[setId] = nil
			self.selIndex = nil
			self.selValue = nil
			if setId == self.mercenaryTab.activeMercenarySetId then
				self.mercenaryTab:SetActiveMercenarySet(self.list[m_max(1, index - 1)])
			else
				self.mercenaryTab:RefreshControls()
			end
			self.mercenaryTab.modFlag = true
		end)
	end
end

function MercenarySetListClass:OnSelKeyDown(_, setId, key)
	if key == "F2" then
		self:RenameSet(self.mercenaryTab.mercenarySets[setId])
	end
end
