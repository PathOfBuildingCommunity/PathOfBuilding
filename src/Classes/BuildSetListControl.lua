-- Path of Building
--
-- Class: Build Set List
-- Build set list control.
--
local t_remove = table.remove

local BuildSetListClass = newClass("BuildSetListControl", "ListControl", function(self, anchor, rect, buildMode)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, buildMode.treeTab.specList)
	self.buildMode = buildMode
	self.buildSetService = new("BuildSetService", buildMode)
	self.controls.copy = new("ButtonControl", { "BOTTOMLEFT", self, "TOP" }, { 2, -4, 60, 18 }, "Copy", function()
		local loadoutNameToCopy = self.selValue.title or "Default"
		local build = buildMode:GetLoadoutByName(loadoutNameToCopy)
		self:CopyLoadoutClick(build)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl", { "LEFT", self.controls.copy, "RIGHT" }, { 4, 0, 60, 18 }, "Delete",
		function()
			self:OnSelDelete(self.selIndex, self.selValue)
		end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.rename = new("ButtonControl", { "BOTTOMRIGHT", self, "TOP" }, { -2, -4, 60, 18 }, "Rename", function()
		self:RenameLoadout(self.selValue)
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl", { "RIGHT", self.controls.rename, "LEFT" }, { -4, 0, 60, 18 }, "New",
		function()
			self:NewLoadout()
		end)
end)

function BuildSetListClass:RenameLoadout(spec)
	local controls = {}
	local specName = spec.title or "Default"
	controls.label = new("LabelControl", nil, { 0, 20, 0, 16 }, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, { 0, 40, 350, 20 }, specName, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, { -45, 70, 80, 20 }, "Save", function()
		local newTitle = controls.edit.buf
		self.buildSetService:RenameLoadout(specName, newTitle)
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, { 45, 70, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, specName and "Rename Loadout" or "Set Name", controls, "save", "edit", "cancel")
end

function BuildSetListClass:CopyLoadoutClick(build)
	local controls = {}
	local buildName = self.buildMode.treeTab.specList[build.specId].title
	controls.label = new("LabelControl", nil, { 0, 20, 0, 16 }, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, { 0, 40, 350, 20 }, buildName, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, { -45, 70, 80, 20 }, "Save", function()
		self.buildSetService:CopyLoadout(build.specId, build.itemSetId, build.skillSetId, build.configSetId,
			controls.edit.buf)
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, { 45, 70, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, buildName and "Rename" or "Set Name", controls, "save", "edit", "cancel")
end

function BuildSetListClass:NewLoadout()
	local controls = {}
	controls.label = new("LabelControl", nil, { 0, 20, 0, 16 }, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, { 0, 40, 350, 20 }, "New Loadout", nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, { -45, 70, 80, 20 }, "Save", function()
		self.buildSetService:NewLoadout(controls.edit.buf)
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, { 45, 70, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, "Set Name", controls, "save", "edit", "cancel")
end

function BuildSetListClass:GetRowValue(column, index, spec)
	if column == 1 then
		local used = spec:CountAllocNodes()
		return (spec.treeVersion ~= latestTreeVersion and ("[" .. treeVersions[spec.treeVersion].display .. "] ") or "")
			.. (spec.title or "Default")
			..
			" (" ..
			(spec.curAscendClassName ~= "None" and spec.curAscendClassName or spec.curClassName) ..
			", " .. used .. " points)"
			.. (index == self.buildMode.treeTab.activeSpec and "  ^9(Current)" or "")
	end
end

function BuildSetListClass:OnOrderChange()
	self.buildMode.modFlag = true
end

function BuildSetListClass:OnSelClick(index, spec, doubleClick)
	if doubleClick and index ~= self.buildMode.treeTab.activeSpec then
		self.buildMode.controls.buildLoadouts:SetSel(index + 1)
	end
end

function BuildSetListClass:OnSelDelete(index, spec)
	if #self.list > 1 then
		main:OpenConfirmPopup("Delete Loadout", "Are you sure you want to delete '" .. (spec.title or "Default") .. "'?",
			"Delete", function()
				self.buildSetService:DeleteLoadout(index, self.list, spec)
				self.selIndex = nil
				self.selValue = nil
			end)
	end
end

function BuildSetListClass:OnSelKeyDown(index, spec, key)
	if key == "F2" then
		self:RenameLoadout(spec)
	end
end
