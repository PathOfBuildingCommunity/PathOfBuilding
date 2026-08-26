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
	-- The button row spans the full width of the list: four equal buttons plus the wider
	-- "New/Copy Custom", separated by 4px gaps
	local buttonWidth, buttonGap = 78, 4
	local customWidth = rect[3] - buttonWidth * 4 - buttonGap * 4
	self.controls.new = new("ButtonControl"):ButtonControl({"BOTTOMLEFT",self,"TOPLEFT"}, {0, -4, buttonWidth, 18}, "New", function()
		build:OpenLoadoutNamePopup()
	end)
	self.controls.rename = new("ButtonControl"):ButtonControl({"LEFT",self.controls.new,"RIGHT"}, {buttonGap, 0, buttonWidth, 18}, "Rename", function()
		self:RenameLoadout(self.selValue)
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.copy = new("ButtonControl"):ButtonControl({"LEFT",self.controls.rename,"RIGHT"}, {buttonGap, 0, buttonWidth, 18}, "Copy", function()
		self:CopyLoadout(self.selValue)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl"):ButtonControl({"LEFT",self.controls.copy,"RIGHT"}, {buttonGap, 0, buttonWidth, 18}, "Delete", function()
		self:OnSelDelete(self.selIndex, self.selValue)
	end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.custom = new("ButtonControl"):ButtonControl({"LEFT",self.controls.delete,"RIGHT"}, {buttonGap, 0, customWidth, 18}, "New/Copy Custom", function()
		self:CreateCustomLoadoutPopup()
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

-- Returns a loadout name not already in use, appending a numeric suffix if needed
function LoadoutListClass:UniqueName(baseName, copySuffix)
	local newName = baseName .. (copySuffix and " (copy)" or "")
	local suffix = 1
	while self:NameInUse(newName) do
		suffix = suffix + 1
		newName = baseName .. (copySuffix and (" (copy " .. suffix .. ")") or (" " .. suffix))
	end
	return newName
end

-- Adds a passive tree, either a copy of the given one or a fresh tree, and returns its index
function LoadoutListClass:AddSpec(specId, name)
	local build = self.build
	local newSpec
	if specId then
		local spec = build.treeTab.specList[specId]
		newSpec = new("PassiveSpec"):PassiveSpec(build, spec.treeVersion)
		newSpec.jewels = copyTable(spec.jewels)
		newSpec:RestoreUndoState(spec:CreateUndoState())
		newSpec:BuildClusterJewelGraphs()
	else
		newSpec = new("PassiveSpec"):PassiveSpec(build, latestTreeVersion)
	end
	newSpec.title = name
	t_insert(build.treeTab.specList, newSpec)
	build.treeTab.modFlag = true
	return #build.treeTab.specList
end

-- Adds an item set, either a copy of the given one or a fresh set, and returns its id
function LoadoutListClass:AddItemSet(itemSetId, name)
	local itemsTab = self.build.itemsTab
	local newSet
	if itemSetId then
		newSet = copyTable(itemsTab.itemSets[itemSetId])
		newSet.id = 1
		while itemsTab.itemSets[newSet.id] do
			newSet.id = newSet.id + 1
		end
		itemsTab.itemSets[newSet.id] = newSet
	else
		newSet = itemsTab:NewItemSet()
	end
	newSet.title = name
	t_insert(itemsTab.itemSetOrderList, newSet.id)
	itemsTab:AddUndoState()
	return newSet.id
end

-- Adds a skill set, either a copy of the given one or a fresh set, and returns its id
function LoadoutListClass:AddSkillSet(skillSetId, name)
	local skillsTab = self.build.skillsTab
	local newSet
	if skillSetId then
		local skillSet = skillsTab.skillSets[skillSetId]
		newSet = copyTable(skillSet, true)
		newSet.socketGroupList = { }
		for _, socketGroup in pairs(skillSet.socketGroupList) do
			local newGroup = copyTable(socketGroup, true)
			newGroup.gemList = { }
			for gemIndex, gem in pairs(socketGroup.gemList) do
				newGroup.gemList[gemIndex] = copyTable(gem, true)
			end
			t_insert(newSet.socketGroupList, newGroup)
		end
		newSet.id = 1
		while skillsTab.skillSets[newSet.id] do
			newSet.id = newSet.id + 1
		end
		skillsTab.skillSets[newSet.id] = newSet
	else
		newSet = skillsTab:NewSkillSet()
	end
	newSet.title = name
	t_insert(skillsTab.skillSetOrderList, newSet.id)
	skillsTab:AddUndoState()
	return newSet.id
end

-- Adds a config set, either a copy of the given one or a fresh set, and returns its id
function LoadoutListClass:AddConfigSet(configSetId, name)
	local configTab = self.build.configTab
	local newSet
	if configSetId then
		newSet = copyTable(configTab.configSets[configSetId])
		newSet.id = 1
		while configTab.configSets[newSet.id] do
			newSet.id = newSet.id + 1
		end
		configTab.configSets[newSet.id] = newSet
	else
		newSet = configTab:NewConfigSet()
	end
	newSet.title = name
	t_insert(configTab.configSetOrderList, newSet.id)
	configTab:AddUndoState()
	return newSet.id
end

-- Creates a loadout from the given sets; a nil set id creates a fresh set of that type
function LoadoutListClass:CreateLoadout(name, specId, itemSetId, skillSetId, configSetId)
	local specIndex = self:AddSpec(specId, name)
	self:AddItemSet(itemSetId, name)
	self:AddSkillSet(skillSetId, name)
	self:AddConfigSet(configSetId, name)
	self.build.modFlag = true
	self:UpdateItemsTabPassiveTreeDropdown()
	self.build:SyncLoadouts()
	self:SelectLoadoutBySpecId(specIndex)
end

-- Copies all four sets of the given loadout into a new loadout
function LoadoutListClass:CopyLoadout(loadout)
	local baseName = (loadout.name:gsub("%s*%{[%w,]+%}", ""))
	if baseName == "" then
		baseName = "Default"
	end
	self:CreateLoadout(self:UniqueName(baseName, true), loadout.specId, loadout.itemSetId, loadout.skillSetId, loadout.configSetId)
end

-- Opens the popup for creating a loadout from a chosen mix of new and existing sets
function LoadoutListClass:CreateCustomLoadoutPopup()
	local build = self.build
	local controls = { }

	-- The first entry creates a fresh set, the rest copy an existing one
	local function buildSetList(orderList, sets)
		local list = { { label = "New" } }
		for _, setId in ipairs(orderList) do
			t_insert(list, { label = sets[setId].title or "Default", id = setId })
		end
		return list
	end
	local treeList = { { label = "New" } }
	for specId, spec in ipairs(build.treeTab.specList) do
		t_insert(treeList, {
			label = (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")..(spec.title or "Default"),
			id = specId,
		})
	end

	controls.label = new("LabelControl"):LabelControl(nil, {0, 20, 0, 16}, "^7Enter name for this loadout:")
	controls.edit = new("EditControl"):EditControl(nil, {0, 40, 350, 20}, self:UniqueName("New Loadout Custom"), nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.treeSelect = new("DropDownControl"):DropDownControl(nil, {0, 90, 350, 20}, treeList)
	controls.treeLabel = new("LabelControl"):LabelControl({"BOTTOMLEFT",controls.treeSelect,"TOPLEFT"}, {0, -4, 0, 16}, "^7Copy from Tree:")
	controls.skillSelect = new("DropDownControl"):DropDownControl(nil, {0, 140, 350, 20}, buildSetList(build.skillsTab.skillSetOrderList, build.skillsTab.skillSets))
	controls.skillLabel = new("LabelControl"):LabelControl({"BOTTOMLEFT",controls.skillSelect,"TOPLEFT"}, {0, -4, 0, 16}, "^7Copy from Skill Set:")
	controls.itemSelect = new("DropDownControl"):DropDownControl(nil, {0, 190, 350, 20}, buildSetList(build.itemsTab.itemSetOrderList, build.itemsTab.itemSets))
	controls.itemLabel = new("LabelControl"):LabelControl({"BOTTOMLEFT",controls.itemSelect,"TOPLEFT"}, {0, -4, 0, 16}, "^7Copy from Item Set:")
	controls.configSelect = new("DropDownControl"):DropDownControl(nil, {0, 240, 350, 20}, buildSetList(build.configTab.configSetOrderList, build.configTab.configSets))
	controls.configLabel = new("LabelControl"):LabelControl({"BOTTOMLEFT",controls.configSelect,"TOPLEFT"}, {0, -4, 0, 16}, "^7Copy from Config Set:")

	-- Every set defaults to "New"; if a loadout is selected in the manager, its sets are
	-- preselected instead so they can be kept or swapped out one at a time
	local selected = self.selValue
	if selected then
		controls.treeSelect:SelByValue(selected.specId, "id")
		controls.skillSelect:SelByValue(selected.skillSetId, "id")
		controls.itemSelect:SelByValue(selected.itemSetId, "id")
		controls.configSelect:SelByValue(selected.configSetId, "id")
	end

	controls.save = new("ButtonControl"):ButtonControl(nil, {-45, 275, 80, 20}, "Save", function()
		self:CreateLoadout(controls.edit.buf,
			controls.treeSelect:GetSelValue().id,
			controls.itemSelect:GetSelValue().id,
			controls.skillSelect:GetSelValue().id,
			controls.configSelect:GetSelValue().id)
		main:ClosePopup()
	end)
	controls.cancel = new("ButtonControl"):ButtonControl(nil, {45, 275, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 305, "Create Custom Loadout", controls, "save", "edit", "cancel")
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

-- Deletes the four sets of the given loadout, keeping any that are shared with another
-- loadout or that are the last remaining set of their type
function LoadoutListClass:DeleteLoadout(loadout)
	local build = self.build
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
end

function LoadoutListClass:OnSelDelete(index, loadout)
	main:OpenConfirmPopup("Delete Loadout", "Are you sure you want to delete '"..loadout.name.."'?\nThis will delete the passive tree, item set, skill set and config set associated with it.\nSets shared with other loadouts, or the last remaining set of a type, will be kept.", "Delete", function()
		self:DeleteLoadout(loadout)
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
