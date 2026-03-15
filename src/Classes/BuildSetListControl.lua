-- Path of Building
--
-- Class: Build Set List
-- Build set list control.
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max
local s_format = string.format

local BuildSetListClass = newClass("BuildSetListControl", "ListControl", function(self, anchor, rect, buildMode, treeTab)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, buildMode.treeTab.specList)
	self.buildMode = buildMode
	self.controls.copy = new("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, {2, -4, 60, 18}, "Copy", function()
		local build = buildMode:GetLoadoutByName(self.selValue.title)
		self:CopyLoadoutClick(build)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, {4, 0, 60, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.rename = new("ButtonControl", {"BOTTOMRIGHT",self,"TOP"}, {-2, -4, 60, 18}, "Rename", function()
		self:RenameLoadout(self.selValue)
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, {-4, 0, 60, 18}, "New", function()
		self:NewLoadout()
	end)
end)

function BuildSetListClass:RenameLoadout(spec, addOnName)
	local controls = { }
	local specName = spec.title or "Default"
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, specName, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "Save", function()
		local newTitle = controls.edit.buf
		self.buildMode:RenameLoadout(specName, newTitle, function()
			self.buildMode:SyncLoadouts()
			self.buildMode.modFlag = true
		end)
		if addOnName then
			self.selIndex = self.buildMode.treeTab.specListIdToOrderId[spec.id]
			self.selValue = spec
		end
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, specName and "Rename Loadout" or "Set Name", controls, "save", "edit", "cancel")
end

function BuildSetListClass:CopyLoadoutClick(build)
    local controls = { }
    local buildName = self.buildMode.treeTab.specList[build.specId].title
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, buildName, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "Save", function()
		local newBuildName = controls.edit.buf
        local newSpec = self.buildMode:CopyLoadout(build.specId, build.itemSetId, build.skillSetId, build.configSetId, newBuildName)
		self.buildMode:SyncLoadouts()
        self.buildMode.modFlag = true
        self.buildMode.controls.buildLoadouts:SetSel(newSpec.id + 1)
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, buildName and "Rename" or "Set Name", controls, "save", "edit", "cancel")
end

function BuildSetListClass:NewLoadout()
    local controls = { }
    controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Enter name for this loadout:")
    controls.edit = new("EditControl", nil, {0, 40, 350, 20}, "New Loadout", nil, nil, 100, function(buf)
        controls.save.enabled = buf:match("%S")
    end)
    controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "Save", function()
        self.buildMode:NewLoadout(controls.edit.buf, function()
            self.buildMode:SyncLoadouts()
            self.buildMode.modFlag = true
            self.buildMode.controls.buildLoadouts:SetSel(1)
            main:ClosePopup()
        end)
    end)
    controls.save.enabled = false
    controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "Cancel", function()
        main:ClosePopup()
    end)
    main:OpenPopup(370, 100, "Set Name", controls, "save", "edit", "cancel")
end

function BuildSetListClass:GetRowValue(column, index, spec)
	if column == 1 then
		local used = spec:CountAllocNodes()
		return (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")
			.. (spec.title or "Default") 
			.. " (" .. (spec.curAscendClassName ~= "None" and spec.curAscendClassName or spec.curClassName) .. ", " .. used .. " points)" 
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
		main:OpenConfirmPopup("Delete Loadout", "Are you sure you want to delete '"..(spec.title or "Default").."'?", "Delete", function()
			t_remove(self.list, index)
            local nextLoadoutIndex = index == self.buildMode.treeTab.activeSpec and m_max(1, index - 1) or index
            local nextLoadout = self.list[nextLoadoutIndex]
			self.buildMode:DeleteLoadout(spec.title or "Default", nextLoadout.title or "Default")
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
