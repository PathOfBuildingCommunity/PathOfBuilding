-- Path of Building
--
-- Class: Passive Spec List
-- Passive spec list control.
--
local t_insert = table.insert
local t_remove = table.remove
local t_sort = table.sort
local m_max = math.max

local PassiveSpecListClass = newClass("PassiveSpecListControl", "ListControl", function(self, anchor, x, y, width, height, treeTab)
	self.ListControl(anchor, x, y, width, height, 20, "VERTICAL", true, treeTab.specList, true)
	self.treeTab = treeTab
	self.showRowSeparators = true

	-- Copy button is in the middle, the others spread out from there
	self.controls.copy = new("ButtonControl", {"TOPLEFT", self, "TOPLEFT"}, (width -60 ) / 2, -25, 60, 18, "Copy", function()
		local newSpec = new("PassiveSpec", treeTab.build, self.selValue.treeVersion)
		newSpec.title = self.selValue.title
		newSpec.jewels = copyTable(self.selValue.jewels)
		newSpec:RestoreUndoState(self.selValue:CreateUndoState())
		newSpec:BuildClusterJewelGraphs()
		self:RenameSpec(newSpec, "Copy Tree", true)
	end)
	self.controls.copy.enabled = function()
		return self.selValue ~= nil and #self.selections == 1
	end
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, 4, 0, 60, 18, "Delete", function()
		self:OnSelDelete()
	end)
	self.controls.delete.tooltipText = "Use Ctrl-Left Click to multi select trees below"
	self.controls.delete.enabled = function()
		return self.selValue ~= nil and #self.list > 1
	end
	self.controls.convert = new("ButtonControl", {"LEFT",self.controls.delete,"RIGHT"}, 4, 0, 60, 18, "Convert", function()
		if #self.selections > 0 then
			-- sort and loop through the selection list backwards, as the ConvertSpec procedure inserts a new spec after the current
			t_sort(self.selections)
			local last
			for selId = #self.selections, 1, -1 do
				local spec = self.list[self.selections[selId]]
				if spec.treeVersion ~= latestTreeVersion then
					treeTab:ConvertSpec(spec, self.selections[selId])
					last = self.selections[selId]
				end
			end
			-- Set the last spec converted as the current tree
			self.treeTab:SetActiveSpec(last + 1)
			if #self.selections ~= 1 then
				main:OpenMessagePopup("Trees Converted", #self.selections.." trees have been converted to "..treeVersions[latestTreeVersion].display..".\nNote that some or all of the passives may have been de-allocated due to changes in the tree.\n\nYou can switch back to the old tree using the tree selector at the bottom left.")
			end
			wipeTable(self.selections)
		end
	end)
	self.controls.convert.tooltipText = "Use Ctrl-Left Click to multi select trees below"
	self.controls.convert.enabled = function()
		return self.selValue ~= nil and self.selValue.treeVersion ~= latestTreeVersion and #self.selections > 0
	end
	self.controls.rename = new("ButtonControl", {"RIGHT",self.controls.copy,"LEFT"}, -4, 0, 60, 18, "Rename", function()
		self:RenameSpec(self.selValue, "Rename Tree")
	end)
	self.controls.rename.enabled = function()
		return self.selValue ~= nil and #self.selections == 1
	end
	self.controls.new = new("ButtonControl", {"RIGHT",self.controls.rename,"LEFT"}, -4, 0, 60, 18, "New", function()
		local newSpec = new("PassiveSpec", treeTab.build, latestTreeVersion)
		newSpec:SelectClass(treeTab.build.spec.curClassId)
		newSpec:SelectAscendClass(treeTab.build.spec.curAscendClassId)
		self:RenameSpec(newSpec, "New Tree", true)
		wipeTable(self.selections)
	end)
	self:UpdateItemsTabPassiveTreeDropdown()
end)

function PassiveSpecListClass:RenameSpec(spec, title, addOnName)
	local controls = { }
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "^7Enter name for this passive tree:")
	controls.edit = new("EditControl", nil, 0, 40, 350, 20, spec.title, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
		spec.title = controls.edit.buf
		self.treeTab.modFlag = true
		if addOnName then
			t_insert(self.list, spec)
			self.selIndex = #self.list
			self.selValue = spec
		end
		self:UpdateItemsTabPassiveTreeDropdown()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, title, controls, "save", "edit")
end

function PassiveSpecListClass:GetRowValue(column, index, spec)
	if column == 1 then
		local used = spec:CountAllocNodes()
		return (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")
			.. (spec.title or "Default")
			.. " (" .. (spec.curAscendClassName ~= "None" and spec.curAscendClassName or spec.curClassName) .. ", " .. used .. " points)"
			.. (index == self.treeTab.activeSpec and "  ^9(Current)" or "")
	end
end

function PassiveSpecListClass:OnOrderChange()
	self.treeTab.activeSpec = isValueInArray(self.list, self.treeTab.build.spec)
	self.treeTab.modFlag = true
	self:UpdateItemsTabPassiveTreeDropdown()
end

function PassiveSpecListClass:OnSelClick(index, spec, doubleClick)
	if doubleClick and index ~= self.treeTab.activeSpec then
		self.treeTab:SetActiveSpec(index)
	end
end

function PassiveSpecListClass:OnSelDelete()
	-- Delete one or more specs (Trees)
	local text = #self.selections == 1 and "tree?\n" or "trees?\n"

	if #self.list > 1 and #self.selections > 0 then
		--collect tree names, sorted in the order shown on screen
		t_sort(self.selections)
		for selId = 1, #self.selections do
			local index = self.selections[selId]
			local spec = self.list[index]
			text = text..'\n^7'..self:GetRowValue(1, index, spec)
		end
		main:OpenConfirmPopup("Delete Tree", "Are you sure you want to delete the following "..text, "Yes", function()
			local index = 1
			local spec
			-- loop through the selection list backwards, so the deletion of a spec doesn't the position of the next to be deleted
			for selId = #self.selections, 1, -1 do
				index = self.selections[selId]
				local spec = self.list[index]
				t_remove(self.list, index)
			end
			self.selIndex = nil
			self.selValue = nil
			if index == self.treeTab.activeSpec then
				self.treeTab:SetActiveSpec(m_max(1, index - 1))
			else
				self.treeTab.activeSpec = isValueInArray(self.list, self.treeTab.build.spec)
			end
			self.treeTab.modFlag = true
			self:UpdateItemsTabPassiveTreeDropdown()
			wipeTable(self.selections)
		end, "No")
	end
end

function PassiveSpecListClass:OnSelKeyDown(index, spec, key)
	if key == "F2" then
		self:RenameSpec(spec)
	end
end

-- Update the passive tree dropdown control in itemsTab
function PassiveSpecListClass:UpdateItemsTabPassiveTreeDropdown()
	local secondarySpecList = self.treeTab.build.itemsTab.controls.specSelect
	local newSpecList = { }
	for i = 1, #self.list do
		newSpecList[i] = self.list[i].title or "Default"
	end
	secondarySpecList:SetList(newSpecList)
	secondarySpecList.selIndex = self.treeTab.activeSpec
end
