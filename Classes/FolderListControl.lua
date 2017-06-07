-- Path of Building
--
-- Class: Folder List
-- Folder list control.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert

local FolderListClass = common.NewClass("FolderList", "ListControl", function(self, anchor, x, y, width, height, subPath, onChange)
	self.ListControl(anchor, x, y, width, height, 16, false, { })
	self.subPath = subPath or ""
	self.controls.path = common.New("PathControl", {"BOTTOM",self,"TOP"}, 0, -2, width, 24, main.buildPath, self.subPath, function(subPath)
		self.subPath = subPath
		self:BuildList()
		self.selIndex = nil
		self.selValue = nil
		if onChange then
			onChange(subPath)
		end
	end)
	self:BuildList()
end)

function FolderListClass:BuildList()
	wipeTable(self.list)
	local handle = NewFileSearch(main.buildPath..self.subPath.."*", true)
	while handle do
		local fileName = handle:GetFileName()
		t_insert(self.list, { 
			name = fileName,
			fullFileName = main.buildPath..self.subPath..fileName,
		})
		if not handle:NextFile() then
			break
		end
	end
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