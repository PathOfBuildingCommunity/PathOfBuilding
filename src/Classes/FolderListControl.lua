-- Path of Building
--
-- Class: Folder List
-- Folder list control.
--
local ipairs = ipairs
local t_insert = table.insert

local FolderListClass = newClass("FolderListControl", "ListControl", function(self, anchor, rect, subPath, onChange)
	self.ListControl(anchor, rect, 16, "VERTICAL", false, { })
	self.subPath = subPath or ""
	self.onChangeCallback = onChange

	self.controls.path = new("PathControl", {"BOTTOM",self,"TOP"}, {0, -2, self.width, 24}, main.buildPath, self.subPath, function(newSubPath)
		self.subPath = newSubPath
		self:BuildList()
		self.selIndex = nil
		self.selValue = nil
		if self.onChangeCallback then
			self.onChangeCallback(newSubPath)
		end
	end)
	self:BuildList()
end)

function FolderListClass:SortList()
	if not self.list then return end
	local sortMode = main.buildSortMode or "NAME"

	table.sort(self.list, function(a, b)
		if sortMode == "EDITED" then
			local modA = a.modified or 0 
			local modB = b.modified or 0
			if modA ~= modB then
				return modA > modB
			end
			return naturalSortCompare(a.name, b.name)
		else
			return naturalSortCompare(a.name, b.name)
		end
	end)
end

function FolderListClass:BuildList()
	wipeTable(self.list)
	local handle = NewFileSearch(main.buildPath..self.subPath.."*", true)
	while handle do
		local fileName = handle:GetFileName()
		t_insert(self.list, { 
			name = fileName,
			fullFileName = main.buildPath..self.subPath..fileName,
			modified = handle:GetFileModifiedTime()
		})
		if not handle:NextFile() then
			break
		end
	end
	if handle and handle.Close then handle:Close() end

	self:SortList()
	if self.UpdateScrollbar then self:UpdateScrollbar() end
	if self.Redraw then self:Redraw() end
end

function FolderListClass:OpenFolder(folderName)
	self.controls.path:SetSubPath(self.subPath .. folderName  .. "/")
end

function FolderListClass:GetRowValue(column, index, folder)
	if column == 1 then
		return folder.name
	end
end

function FolderListClass:OnSelClick(index, folder, doubleClick)
	if doubleClick then
		self:OpenFolder(folder.name)
	end
end

function FolderListClass:OnSelDelete(index, folder)
	if NewFileSearch(folder.fullFileName.."/*") or NewFileSearch(folder.fullFileName.."/*", true) then
		main:OpenMessagePopup("Delete Folder", "The folder is not empty.")
	else
		local res, msg = RemoveDir(folder.fullFileName)
		if not res then
			main:OpenMessagePopup("Error", "Couldn't delete '"..folder.fullFileName.."': "..msg)
			return
		end
		self:BuildList() 
		self.selIndex = nil
		self.selValue = nil
	end
end