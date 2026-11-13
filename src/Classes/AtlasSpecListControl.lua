local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max

local AtlasSpecListClass = newClass("AtlasSpecListControl", "ListControl")

function AtlasSpecListClass:AtlasSpecListControl(anchor, rect, atlasTab)
	self:ListControl(anchor, rect, 16, "VERTICAL", true, atlasTab.specList)
	self.atlasTab = atlasTab
	self.controls.copy = new("ButtonControl"):ButtonControl({ "BOTTOMLEFT", self, "TOP" }, { 2, -4, 60, 18 }, "Copy", function()
		local newSpec = new("AtlasSpec"):AtlasSpec(self.selValue.treeVersion, self.selValue.title)
		newSpec:RestoreUndoState(self.selValue:CreateUndoState())
		newSpec:ResetUndo()
		self:RenameSpec(newSpec, "Copy Atlas Tree", true)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({ "LEFT", self.controls.copy, "RIGHT" }, { 4, 0, 60, 18 }, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.rename = new("ButtonControl"):ButtonControl({ "BOTTOMRIGHT", self, "TOP" }, { -2, -4, 60, 18 }, "Rename", function()
		self:RenameSpec(self.selValue, "Rename Atlas Tree")
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl"):ButtonControl({ "RIGHT", self.controls.rename, "LEFT" }, { -4, 0, 60, 18 }, "New", function()
		self:RenameSpec(new("AtlasSpec"):AtlasSpec(latestAtlasTreeVersion, "New Atlas Tree"), "New Atlas Tree", true)
	end)
	return self
end

function AtlasSpecListClass:RenameSpec(spec, title, addOnSave)
	local controls = { }
	controls.label = new("LabelControl"):LabelControl(nil, { 0, 20, 0, 16 }, "^7Enter name for this atlas tree:")
	controls.edit = new("EditControl"):EditControl(nil, { 0, 40, 350, 20 }, spec.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S") ~= nil
	end)
	controls.save = new("ButtonControl"):ButtonControl(nil, { -45, 70, 80, 20 }, "Save", function()
		spec.title = controls.edit.buf
		self.atlasTab.modFlag = true
		if addOnSave then
			t_insert(self.list, spec)
			self.selIndex = #self.list
			self.selValue = spec
		end
		main:ClosePopup()
	end)
	controls.save.enabled = spec.title and spec.title:match("%S") ~= nil
	controls.cancel = new("ButtonControl"):ButtonControl(nil, { 45, 70, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, title, controls, "save", "edit")
end

function AtlasSpecListClass:GetRowValue(column, index, spec)
	if column == 1 then
		return self.atlasTab:GetSpecLabel(spec) .. " (" .. spec:CountAllocNodes() .. " points)" .. (index == self.atlasTab.activeSpec and "  ^9(Current)" or "")
	end
end

function AtlasSpecListClass:OnOrderChange()
	self.atlasTab.activeSpec = isValueInArray(self.list, self.atlasTab.spec)
	self.atlasTab.modFlag = true
end

function AtlasSpecListClass:OnSelClick(index, spec, doubleClick)
	if doubleClick and index ~= self.atlasTab.activeSpec then
		self.atlasTab:SetActiveSpec(index)
	end
end

function AtlasSpecListClass:OnSelDelete(index, spec)
	if #self.list > 1 then
		main:OpenConfirmPopup("Delete Atlas Tree", "Are you sure you want to delete '" .. (spec.title or "Default") .. "'?", "Delete", function()
			t_remove(self.list, index)
			self.selIndex = nil
			self.selValue = nil
			if index == self.atlasTab.activeSpec then
				self.atlasTab:SetActiveSpec(m_max(1, index - 1))
			else
				self.atlasTab.activeSpec = isValueInArray(self.list, self.atlasTab.spec)
			end
			self.atlasTab.modFlag = true
		end)
	end
end

function AtlasSpecListClass:OnSelKeyDown(index, spec, key)
	if key == "F2" then
		self:RenameSpec(spec, "Rename Atlas Tree")
	end
end
