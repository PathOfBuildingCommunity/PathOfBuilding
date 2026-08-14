-- Path of Building
--
-- Class: Loadout List
-- Loadout list control.
--
local t_insert = table.insert
local t_remove = table.remove
local m_max = math.max

---@class LoadoutListControl: ListControl
local LoadoutListClass = newClass("LoadoutListControl", "ListControl")

function LoadoutListClass:LoadoutListControl(anchor, rect, build)
	self:ListControl(anchor, rect, 16, "VERTICAL", false, build.loadoutList)
	self.build = build
	self.controls.copy = new("ButtonControl"):ButtonControl({"BOTTOMLEFT",self,"TOP"}, {2, -4, 60, 18}, "Copy", function()
		self:CopyLoadout(self.selValue)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({"LEFT",self.controls.copy,"RIGHT"}, {4, 0, 60, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.rename = new("ButtonControl"):ButtonControl({"BOTTOMRIGHT",self,"TOP"}, {-2, -4, 60, 18}, "Rename", function()
		self:RenameLoadout(self.selValue)
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.new = new("ButtonControl"):ButtonControl({"RIGHT",self.controls.rename,"LEFT"}, {-4, 0, 60, 18}, "New", function()
		build:OpenLoadoutNamePopup()
	end)
	return self
end

-- Returns true if another loadout also uses this set
function LoadoutListClass:IsSetShared(field, setId, loadout)
	for _, other in ipairs(self.build.loadoutList) do
		if other ~= loadout and other[field] == setId then
			return true
		end
	end
	return false
end

function LoadoutListClass:NameInUse(name)
	for _, loadout in ipairs(self.build.loadoutList) do
		if loadout.name == name then
			return true
		end
	end
	return false
end

-- Re-selects the loadout owning the given passive tree after the list has been rebuilt
function LoadoutListClass:SelectLoadoutBySpecId(specId)
	self.selIndex = nil
	self.selValue = nil
	for index, loadout in ipairs(self.list) do
		if loadout.specId == specId then
			self.selIndex = index
			self.selValue = loadout
			break
		end
	end
end

-- Copies all four sets of the given loadout into a new loadout
function LoadoutListClass:CopyLoadout(loadout)
	local build = self.build
	local baseName = (loadout.name:gsub("%s*%{[%w,]+%}", ""))
	if baseName == "" then
		baseName = "Default"
	end
	local newName = baseName .. " (copy)"
	local suffix = 1
	while self:NameInUse(newName) do
		suffix = suffix + 1
		newName = baseName .. " (copy " .. suffix .. ")"
	end

	local spec = build.treeTab.specList[loadout.specId]
	local newSpec = new("PassiveSpec"):PassiveSpec(build, spec.treeVersion)
	newSpec.title = newName
	newSpec.jewels = copyTable(spec.jewels)
	newSpec:RestoreUndoState(spec:CreateUndoState())
	newSpec:BuildClusterJewelGraphs()
	t_insert(build.treeTab.specList, newSpec)
	build.treeTab.modFlag = true

	local itemsTab = build.itemsTab
	local newItemSet = copyTable(itemsTab.itemSets[loadout.itemSetId])
	newItemSet.title = newName
	newItemSet.id = 1
	while itemsTab.itemSets[newItemSet.id] do
		newItemSet.id = newItemSet.id + 1
	end
	itemsTab.itemSets[newItemSet.id] = newItemSet
	t_insert(itemsTab.itemSetOrderList, newItemSet.id)
	itemsTab:AddUndoState()

	local skillsTab = build.skillsTab
	local skillSet = skillsTab.skillSets[loadout.skillSetId]
	local newSkillSet = copyTable(skillSet, true)
	newSkillSet.title = newName
	newSkillSet.socketGroupList = { }
	for _, socketGroup in pairs(skillSet.socketGroupList) do
		local newGroup = copyTable(socketGroup, true)
		newGroup.gemList = { }
		for gemIndex, gem in pairs(socketGroup.gemList) do
			newGroup.gemList[gemIndex] = copyTable(gem, true)
		end
		t_insert(newSkillSet.socketGroupList, newGroup)
	end
	newSkillSet.id = 1
	while skillsTab.skillSets[newSkillSet.id] do
		newSkillSet.id = newSkillSet.id + 1
	end
	skillsTab.skillSets[newSkillSet.id] = newSkillSet
	t_insert(skillsTab.skillSetOrderList, newSkillSet.id)
	skillsTab:AddUndoState()

	local configTab = build.configTab
	local newConfigSet = copyTable(configTab.configSets[loadout.configSetId])
	newConfigSet.title = newName
	newConfigSet.id = 1
	while configTab.configSets[newConfigSet.id] do
		newConfigSet.id = newConfigSet.id + 1
	end
	configTab.configSets[newConfigSet.id] = newConfigSet
	t_insert(configTab.configSetOrderList, newConfigSet.id)
	configTab:AddUndoState()

	self:UpdateItemsTabPassiveTreeDropdown()
	build:SyncLoadouts()
	self:SelectLoadoutBySpecId(#build.treeTab.specList)
end

function LoadoutListClass:RenameLoadout(loadout)
	local build = self.build
	local spec = build.treeTab.specList[loadout.specId]
	local controls = { }
	local currentName = ((spec.title or "Default"):gsub("%s*%{[%w,]+%}", ""))
	controls.label = new("LabelControl"):LabelControl(nil, {0, 20, 0, 16}, "^7Enter new name for this loadout:")
	controls.edit = new("EditControl"):EditControl(nil, {0, 40, 350, 20}, currentName, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 70, 80, 20}, "Save", function()
		local newName = controls.edit.buf
		-- Rename each of the associated sets, preserving any {link} identifiers in their titles
		local function newTitle(title)
			local linkIdentifier = title and title:match("%{[%w,]+%}")
			return linkIdentifier and (newName .. " " .. linkIdentifier) or newName
		end
		spec.title = newTitle(spec.title)
		local itemSet = build.itemsTab.itemSets[loadout.itemSetId]
		itemSet.title = newTitle(itemSet.title)
		local skillSet = build.skillsTab.skillSets[loadout.skillSetId]
		skillSet.title = newTitle(skillSet.title)
		local configSet = build.configTab.configSets[loadout.configSetId]
		configSet.title = newTitle(configSet.title)
		build.treeTab.modFlag = true
		build.itemsTab:AddUndoState()
		build.skillsTab:AddUndoState()
		build.configTab:AddUndoState()
		self:UpdateItemsTabPassiveTreeDropdown()
		build:SyncLoadouts()
		self:SelectLoadoutBySpecId(loadout.specId)
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {45, 70, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, "Rename", controls, "save", "edit", "cancel")
end

function LoadoutListClass:IsActiveLoadout(loadout)
	local build = self.build
	return loadout.specId == build.treeTab.activeSpec
		and loadout.itemSetId == build.itemsTab.activeItemSetId
		and loadout.skillSetId == build.skillsTab.activeSkillSetId
		and loadout.configSetId == build.configTab.activeConfigSetId
end

function LoadoutListClass:GetRowValue(column, index, loadout)
	if column == 1 then
		return loadout.name .. (self:IsActiveLoadout(loadout) and "  ^9(Current)" or "")
	end
end

function LoadoutListClass:OnSelClick(index, loadout, doubleClick)
	if doubleClick then
		local build = self.build
		if loadout.specId ~= build.treeTab.activeSpec then
			build.treeTab:SetActiveSpec(loadout.specId)
		end
		if loadout.itemSetId ~= build.itemsTab.activeItemSetId then
			build.itemsTab:SetActiveItemSet(loadout.itemSetId)
		end
		if loadout.skillSetId ~= build.skillsTab.activeSkillSetId then
			build.skillsTab:SetActiveSkillSet(loadout.skillSetId)
		end
		if loadout.configSetId ~= build.configTab.activeConfigSetId then
			build.configTab:SetActiveConfigSet(loadout.configSetId)
		end
		build:SyncLoadouts()
		self:SelectLoadoutBySpecId(loadout.specId)
	end
end

function LoadoutListClass:OnSelDelete(index, loadout)
	local build = self.build
	main:OpenConfirmPopup("Delete Loadout", "Are you sure you want to delete '"..loadout.name.."'?\nThis will delete the passive tree, item set, skill set and config set associated with it.\nSets shared with other loadouts, or the last remaining set of a type, will be kept.", "Delete", function()
		local treeTab, itemsTab, skillsTab, configTab = build.treeTab, build.itemsTab, build.skillsTab, build.configTab
		if #treeTab.specList > 1 and not self:IsSetShared("specId", loadout.specId, loadout) then
			t_remove(treeTab.specList, loadout.specId)
			if loadout.specId == treeTab.activeSpec then
				treeTab:SetActiveSpec(m_max(1, loadout.specId - 1))
			else
				treeTab.activeSpec = isValueInArray(treeTab.specList, build.spec)
			end
			treeTab.modFlag = true
		end
		if #itemsTab.itemSetOrderList > 1 and not self:IsSetShared("itemSetId", loadout.itemSetId, loadout) then
			local setIndex = isValueInArray(itemsTab.itemSetOrderList, loadout.itemSetId)
			t_remove(itemsTab.itemSetOrderList, setIndex)
			itemsTab.itemSets[loadout.itemSetId] = nil
			if loadout.itemSetId == itemsTab.activeItemSetId then
				itemsTab:SetActiveItemSet(itemsTab.itemSetOrderList[m_max(1, setIndex - 1)])
			end
			itemsTab:AddUndoState()
		end
		if #skillsTab.skillSetOrderList > 1 and not self:IsSetShared("skillSetId", loadout.skillSetId, loadout) then
			local setIndex = isValueInArray(skillsTab.skillSetOrderList, loadout.skillSetId)
			t_remove(skillsTab.skillSetOrderList, setIndex)
			skillsTab.skillSets[loadout.skillSetId] = nil
			if loadout.skillSetId == skillsTab.activeSkillSetId then
				skillsTab:SetActiveSkillSet(skillsTab.skillSetOrderList[m_max(1, setIndex - 1)])
			end
			skillsTab:AddUndoState()
		end
		if #configTab.configSetOrderList > 1 and not self:IsSetShared("configSetId", loadout.configSetId, loadout) then
			local setIndex = isValueInArray(configTab.configSetOrderList, loadout.configSetId)
			t_remove(configTab.configSetOrderList, setIndex)
			configTab.configSets[loadout.configSetId] = nil
			if loadout.configSetId == configTab.activeConfigSetId then
				configTab:SetActiveConfigSet(configTab.configSetOrderList[m_max(1, setIndex - 1)])
			end
			configTab:AddUndoState()
		end
		self.selIndex = nil
		self.selValue = nil
		self:UpdateItemsTabPassiveTreeDropdown()
		build:SyncLoadouts()
	end)
end

function LoadoutListClass:OnSelKeyDown(index, loadout, key)
	if key == "F2" then
		self:RenameLoadout(loadout)
	end
end

-- Update the passive tree dropdown control in itemsTab
function LoadoutListClass:UpdateItemsTabPassiveTreeDropdown()
	local build = self.build
	local newSpecList = { }
	for i, spec in ipairs(build.treeTab.specList) do
		newSpecList[i] = spec.title or "Default"
	end
	build.itemsTab.controls.specSelect:SetList(newSpecList)
	build.itemsTab.controls.specSelect.selIndex = build.treeTab.activeSpec
end
