-- Path of Building
--
-- Class: Manage Loadouts List
-- List control for managing whole loadouts (a passive tree + item/skill/config sets sharing a name).
--
local ipairs = ipairs

local ManageLoadoutsListClass = newClass("ManageLoadoutsListControl", "ListControl", function(self, anchor, rect, build)
	self.ListControl(anchor, rect, 16, "VERTICAL", true, { })
	self.build = build
	self:BuildList()

	self.controls.copy = new("ButtonControl", {"BOTTOMLEFT",self,"TOP"}, {2, -4, 60, 18}, "Copy", function()
		self:CopyLoadout(self.selValue)
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
		self.build:OpenNewLoadoutPopup(function()
			self:BuildList()
		end)
	end)
end)

-- Rebuild the list of loadout descriptors, preserving the current selection by tree spec identity.
function ManageLoadoutsListClass:BuildList()
	local prevSpec = self.selValue and self.selValue.spec
	self.list = self.build:GetLoadouts()
	self.selIndex = nil
	self.selValue = nil
	if prevSpec then
		for index, loadout in ipairs(self.list) do
			if loadout.spec == prevSpec then
				self.selIndex = index
				self.selValue = loadout
				break
			end
		end
	end
end

function ManageLoadoutsListClass:GetRowValue(column, index, loadout)
	if column == 1 then
		local spec = loadout.spec
		local used = spec:CountAllocNodes()
		local className = spec.curAscendClassName ~= "None" and spec.curAscendClassName or spec.curClassName
		local isCurrent = self.build.treeTab.specList[self.build.treeTab.activeSpec] == spec
		return (spec.treeVersion ~= latestTreeVersion and ("["..treeVersions[spec.treeVersion].display.."] ") or "")
			.. loadout.name
			.. " (" .. className .. ", " .. used .. " points)"
			.. (isCurrent and "  ^9(Current)" or "")
	end
end

function ManageLoadoutsListClass:OnSelClick(index, loadout, doubleClick)
	if doubleClick then
		self.build:SetActiveLoadout(loadout)
		self:BuildList()
	end
end

function ManageLoadoutsListClass:OnOrderChange()
	self.build:ApplyLoadoutOrder(self.list)
	self:BuildList()
end

function ManageLoadoutsListClass:OnSelDelete(index, loadout)
	if not loadout or #self.list <= 1 then
		return
	end
	main:OpenConfirmPopup("Delete Loadout",
		"Are you sure you want to delete the '"..loadout.name.."' loadout?\n"
		.. "This will delete its passive tree, item set, skill set and config set.\n"
		.. "This will not delete any items used by the set.", "Delete", function()
			self.build:DeleteLoadout(loadout)
			self:BuildList()
		end)
end

function ManageLoadoutsListClass:RenameLoadout(loadout)
	if not loadout then
		return
	end
	local controls = { }
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Enter name for this loadout:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, loadout.name, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "Save", function()
		self.build:RenameLoadout(loadout, controls.edit.buf)
		self:BuildList()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, "Rename Loadout", controls, "save", "edit", "cancel")
end

function ManageLoadoutsListClass:CopyLoadout(loadout)
	if not loadout then
		return
	end
	local controls = { }
	controls.label = new("LabelControl", nil, {0, 20, 0, 16}, "^7Enter name for the copied loadout:")
	controls.edit = new("EditControl", nil, {0, 40, 350, 20}, loadout.name, nil, nil, 100, function(buf)
		controls.save.enabled = buf:match("%S")
	end)
	controls.save = new("ButtonControl", nil, {-45, 70, 80, 20}, "Save", function()
		self.build:CopyLoadout(loadout, controls.edit.buf)
		self:BuildList()
		main:ClosePopup()
	end)
	controls.save.enabled = false
	controls.cancel = new("ButtonControl", nil, {45, 70, 80, 20}, "Cancel", function()
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, "Copy Loadout", controls, "save", "edit", "cancel")
end

function ManageLoadoutsListClass:OnSelKeyDown(index, loadout, key)
	if key == "F2" then
		self:RenameLoadout(loadout)
	end
end
