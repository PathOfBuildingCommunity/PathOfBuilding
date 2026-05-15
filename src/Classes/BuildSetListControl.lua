-- Path of Building
--
-- Class: Build Set List
-- Build set list control.
--

local t_insert = table.insert

local BuildSetListClass = newClass("BuildSetListControl", "ListControl", function(self, anchor, rect, buildMode)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, buildMode.loadoutsList)
	self.buildMode = buildMode
	self.buildSetService = new("BuildSetService", buildMode)
	self.controls.new = new("ButtonControl", { "BOTTOMLEFT", self, "TOP" }, { -190, -4, 60, 18 }, "New",
		function()
			self:NewLoadout()
		end)
	self.controls.rename = new("ButtonControl", { "LEFT", self.controls.new, "RIGHT" }, { 5, 0, 60, 18 }, "Rename",
		function()
			self:RenameLoadout(self.selValue.title)
		end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.copy = new("ButtonControl", { "LEFT", self.controls.rename, "RIGHT" }, { 5, 0, 60, 18 }, "Copy",
		function()
			self:CopyLoadout(self.selValue.title)
		end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil
	end
	self.controls.delete = new("ButtonControl", { "LEFT", self.controls.copy, "RIGHT" }, { 5, 0, 60, 18 }, "Delete",
		function()
			self:DeleteLoadout(self.selIndex, self.selValue)
		end)
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.custom = new("ButtonControl", { "LEFT", self.controls.delete, "RIGHT" }, { 5, 0, 120, 18 },
		"New/Copy Custom",
		function()
			if self.selValue == nil then
				self:CustomLoadout({
					specId = 0,
					itemSetId = 0,
					skillSetId = 0,
					configSetId = 0,
				})
			else
				local loadoutNameToCopy = self.selValue.title or "Default"
				local build = buildMode:GetLoadoutByName(loadoutNameToCopy)
				self:CustomLoadout(build)
			end
		end)
end)

function BuildSetListClass:RenameLoadout(loadoutName)
	self:BasicLoadoutPopup({
		popupTitle = "Rename Loadout",
		defaultName = loadoutName,
		saveCallback = function(newName)
			self.buildSetService:RenameLoadout(loadoutName or "Default", newName)
		end,
	})
end

function BuildSetListClass:CopyLoadout(loadoutName)
	self:BasicLoadoutPopup({
		popupTitle = "Copy Loadout",
		defaultName = loadoutName,
		saveCallback = function(newName)
			self.buildSetService:CopyLoadout(loadoutName or "Default", newName)
		end,
	})
end

function BuildSetListClass:CustomLoadout(build)
	local function getList(setList, orderList, activeId)
		local newSetList = { "^7New" }
		local activeIndex = 1
		for index, setId in ipairs(orderList) do
			local set = setList[setId]
			t_insert(newSetList, set.title or "Default")
			if setId == activeId then
				activeIndex = index + 1
			end
		end
		return newSetList, activeIndex
	end
	local controls = {}
	local specNameLookup = self.buildSetService:SpecNameLookup()
	local buildName = build.specId > 0 and self.buildMode.treeTab.specList[build.specId].title or "New Loadout"
	controls.label = new("LabelControl", nil, { 0, 20, 0, 16 }, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, { 0, 40, 350, 20 }, buildName, nil, nil, 100, function(buf)
		controls.save.enabled = specNameLookup[buf] == nil and buf:match("%S")
	end)

	local treeList = self.buildMode.treeTab:GetSpecList()
	t_insert(treeList, 1, "^7New")
	controls.treeDropDown = new("DropDownControl", nil, { 0, 90, 350, 20 }, treeList, function(index)

	end)
	controls.treeDropDown:SetSel(build.specId + 1)
	controls.treeLabel = new("LabelControl", { "BOTTOMLEFT", controls.treeDropDown, "TOPLEFT" }, { 4, -4, 0, 16 },
		"^7Copy from Tree:")

	local skillList, activeSkillIndex = getList(self.buildMode.skillsTab.skillSets,
		self.buildMode.skillsTab.skillSetOrderList, build.skillSetId)
	controls.skillDropDown = new("DropDownControl", nil, { 0, 140, 350, 20 }, skillList, function(index)

	end)
	controls.skillDropDown:SetSel(activeSkillIndex)
	controls.skillLabel = new("LabelControl", { "BOTTOMLEFT", controls.skillDropDown, "TOPLEFT" }, { 4, -4, 0, 16 },
		"^7Copy from Skill Set:")

	local itemList, activeItemIndex = getList(self.buildMode.itemsTab.itemSets, self.buildMode.itemsTab.itemSetOrderList,
		build.itemSetId)
	controls.itemDropDown = new("DropDownControl", nil, { 0, 190, 350, 20 }, itemList, function(index)

	end)
	controls.itemDropDown:SetSel(activeItemIndex)
	controls.itemLabel = new("LabelControl", { "BOTTOMLEFT", controls.itemDropDown, "TOPLEFT" }, { 4, -4, 0, 16 },
		"^7Copy from Item Set:")

	local configList, activeConfigIndex = getList(self.buildMode.configTab.configSets,
		self.buildMode.configTab.configSetOrderList, build.configSetId)
	controls.configDropDown = new("DropDownControl", nil, { 0, 240, 350, 20 }, configList, function(index)

	end)
	controls.configDropDown:SetSel(activeConfigIndex)
	controls.configLabel = new("LabelControl", { "BOTTOMLEFT", controls.configDropDown, "TOPLEFT" }, { 4, -4, 0, 16 },
		"^7Copy from Config Set:")

	controls.save = new("ButtonControl", nil, { -45, 270, 80, 20 }, "Save", function()
		local treeIndex = controls.treeDropDown.selIndex
		local itemIndex = controls.itemDropDown.selIndex
		local skillIndex = controls.skillDropDown.selIndex
		local configIndex = controls.configDropDown.selIndex

		local newSpecId = treeIndex == 1 and -1 or (treeIndex > 1 and treeIndex - 1)
		local newItemSetId = itemIndex == 1 and -1 or
			(itemIndex > 1 and self.buildMode.itemsTab.itemSetOrderList[itemIndex - 1] or 0)
		local newSkillSetId = skillIndex == 1 and -1 or
			(skillIndex > 1 and self.buildMode.skillsTab.skillSetOrderList[skillIndex - 1] or 0)
		local newConfigSetId = configIndex == 1 and -1 or
			(configIndex > 1 and self.buildMode.configTab.configSetOrderList[configIndex - 1] or 0)
		self.buildSetService:CustomLoadout(newSpecId, newItemSetId, newSkillSetId, newConfigSetId,
			controls.edit.buf)
		self:ResetList()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, { 45, 270, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 300, "Create Custom Loadout", controls, "save", "edit", "cancel")
end

function BuildSetListClass:NewLoadout()
	self:BasicLoadoutPopup({
		popupTitle = "New Loadout",
		defaultName = "New Loadout",
		saveCallback = function(newName)
			self.buildSetService:NewLoadout(newName)
		end,
	})
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
			.. (index == self.buildMode.activeLoadout and "  ^9(Current)" or "")
	end
end

function BuildSetListClass:OnSelClick(index, spec, doubleClick)
	if doubleClick and index ~= self.buildMode.activeLoadout then
		self.buildMode.controls.buildLoadouts:SetSel(index + 1)
	end
end

function BuildSetListClass:DeleteLoadout(index, spec)
	if #self.list > 1 then
		main:OpenConfirmPopup("Delete Loadout", "Are you sure you want to delete '" .. (spec.title or "Default") .. "'?",
			"Delete", function()
				self.buildSetService:DeleteLoadout(index, self.list, spec)
				self.selIndex = nil
				self.selValue = nil
				self:ResetList()
			end)
	end
end

function BuildSetListClass:OnSelKeyDown(index, spec, key)
	if key == "F2" then
		self:RenameLoadout(spec)
	end
end

function BuildSetListClass:OnOrderChange(oldIndex, newIndex)
	self.buildSetService:ReorderLoadout(oldIndex, newIndex)
	self:ResetList()
end

function BuildSetListClass:ResetList()
	self.list = self.buildMode.loadoutsList
end

function BuildSetListClass:BasicLoadoutPopup(options)
	local controls = {}

	controls.label = new("LabelControl", nil, { 0, 20, 0, 16 },
		"^7Enter name for this loadout:")

	local specNameLookup = self.buildSetService:SpecNameLookup()
	controls.edit = new("EditControl", nil, { 0, 40, 350, 20 },
		options.defaultName or "Default", nil, nil, 100, function(buf)
			print("Buf changed:", buf, specNameLookup[buf])
			controls.save.enabled = specNameLookup[buf] == nil and buf:match("%S")
		end)

	controls.save = new("ButtonControl", nil, { -45, 70, 80, 20 }, "Save", function()
		options.saveCallback(controls.edit.buf)
		self:ResetList()
		main:ClosePopup()
	end)
	controls.save.enabled = false

	controls.cancel = new("ButtonControl", nil, { 45, 70, 80, 20 }, "Cancel", function()
		main:ClosePopup()
	end)

	main:OpenPopup(370, 110, options.popupTitle, controls, "save", "edit", "cancel")
end
