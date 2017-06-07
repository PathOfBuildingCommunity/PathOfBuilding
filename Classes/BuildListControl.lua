-- Path of Building
--
-- Class: Build List
-- Build list control.
--
local launch, main = ...

local ipairs = ipairs
local s_format = string.format

local BuildListClass = common.NewClass("BuildList", "ListControl", function(self, anchor, x, y, width, height, listMode)
	self.ListControl(anchor, x, y, width, height, 20, false, listMode.list)
	self.listMode = listMode
	self.showRowSeparators = true
	self.controls.path = common.New("PathControl", {"BOTTOM",self,"TOP"}, 0, -2, width, 24, main.buildPath, listMode.subPath, function(subPath)
		listMode.subPath = subPath
		listMode:BuildList()
		self.selIndex = nil
		self.selValue = nil
	end)
	function self.controls.path:CanReceiveDrag(type, build)
		return type == "Build" and #self.folderList > 1
	end
	function self.controls.path:ReceiveDrag(type, build, source)
		if type == "Build" then
			for index, folder in ipairs(self.folderList) do
				if index < #self.folderList and folder.button:IsMouseOver() then
					if build.folderName then
						main:MoveFolder(build.folderName, main.buildPath..build.subPath, main.buildPath..folder.path)
					else
						os.rename(build.fullFileName, listMode:GetDestName(folder.path, build.fileName))
					end
					listMode:BuildList()
				end
			end
		end
	end
	self.dragTargetList = { self.controls.path, self }
end)

function BuildListClass:SelByFileName(selFileName)
	for index, build in ipairs(self.list) do
		if build.fileName == selFileName then
			self:SelectIndex(index)
			break
		end
	end
end

function BuildListClass:LoadBuild(build)
	if build.folderName then
		self.controls.path:SetSubPath(self.listMode.subPath .. build.folderName  .. "/")
	else
		main:SetMode("BUILD", build.fullFileName, build.buildName)
	end
end

function BuildListClass:NewFolder()
	main:OpenNewFolderPopup(main.buildPath..self.listMode.subPath, function(newFolderName)
		if newFolderName then
			self.listMode:BuildList()
		end
		self.listMode:SelectControl(self)
	end)
end

function BuildListClass:RenameBuild(build, copyOnName)
	local controls = { }
	controls.label = common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter the new name for this "..(build.folderName and "folder:" or "build:"))
	controls.edit = common.New("EditControl", nil, 0, 40, 350, 20, build.folderName or build.buildName, nil, "\\/:%*%?\"<>|%c", 100, function(buf)
		controls.save.enabled = false
		if build.folderName then
			if buf:match("%S") and buf:lower() ~= build.folderName:lower() then
				controls.save.enabled = true
			end
		else
			if buf:match("%S") and buf:lower() ~= build.buildName:lower() then
				local newName = buf..".xml"
				local newFile = io.open(main.buildPath..build.subPath..newName, "r")
				if newFile then
					newFile:close()
				else
					controls.save.enabled = true
				end
			end
		end
	end)
	controls.save = common.New("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
		local newBuildName = controls.edit.buf
		if build.folderName then
			if copyOnName then
				main:CopyFolder(build.fullFileName, main.buildPath..build.subPath..newBuildName)
			else
				local res, msg = os.rename(build.fullFileName, main.buildPath..build.subPath..newBuildName)
				if not res then
					main:OpenMessagePopup("Error", "Couldn't rename '"..build.fullFileName.."' to '"..newBuildName.."': "..msg)
					return
				end
			end
			self.listMode:BuildList()
		else
			local newFileName = newBuildName..".xml"
			if copyOnName then
				local res, msg = copyFile(build.fullFileName, main.buildPath..build.subPath..newFileName)
				if not res then
					main:OpenMessagePopup("Error", "Couldn't copy build: "..msg)
					return
				end
			else
				local res, msg = os.rename(build.fullFileName, main.buildPath..build.subPath..newFileName)
				if not res then
					main:OpenMessagePopup("Error", "Couldn't rename '"..build.fullFileName.."' to '"..newFileName.."': "..msg)
					return
				end
			end
			self.listMode:BuildList()
			self:SelByFileName(newFileName)
		end
		main:ClosePopup()
		self.listMode:SelectControl(self)
	end)
	controls.save.enabled = false
	controls.cancel = common.New("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		main:ClosePopup()
		self.listMode:SelectControl(self)
	end)
	main:OpenPopup(370, 100, (copyOnName and "Copy " or "Rename ")..(build.folderName and "Folder" or "Build"), controls, "save", "edit")	
end

function BuildListClass:DeleteBuild(build)
	if build.folderName then
		if NewFileSearch(build.fullFileName.."/*") or NewFileSearch(build.fullFileName.."/*", true) then
			main:OpenMessagePopup("Delete Folder", "The folder is not empty.")
		else
			local res, msg = RemoveDir(build.fullFileName)
			if not res then
				main:OpenMessagePopup("Error", "Couldn't delete '"..build.fullFileName.."': "..msg)
				return
			end
			self.listMode:BuildList()
			self.selIndex = nil
			self.selValue = nil
		end
	else
		main:OpenConfirmPopup("Confirm Delete", "Are you sure you want to delete build:\n"..build.buildName.."\nThis cannot be undone.", "Delete", function()
			os.remove(build.fullFileName)
			self.listMode:BuildList()
			self.selIndex = nil
			self.selValue = nil
		end)
	end
end

function BuildListClass:GetColumnOffset(column)
	if column == 1 then
		return 0
	elseif column == 2 then
		return self:GetProperty("width") - 172
	end
end

function BuildListClass:GetRowValue(column, index, build)
	if column == 1 then
		local label
		if build.folderName then
			label = ">> " .. build.folderName
		else
			label = build.buildName or "?"
		end
		if self.cutBuild and self.cutBuild.buildName == build.buildName and self.cutBuild.folderName == build.folderName then
			return "^xC0B0B0"..label
		else
			return label
		end
	elseif column == 2 then
		if build.buildName then
			return s_format("%sLevel %d %s", 
				build.className and colorCodes[build.className:upper()] or "^7", 
				build.level or 1, 
				(build.ascendClassName ~= "None" and build.ascendClassName) or build.className or "?"
			)
		else
			return ""
		end
	end
end

function BuildListClass:GetDragValue(index, build)
	return "Build", build
end

function BuildListClass:CanReceiveDrag(type, build)
	return type == "Build"
end

function BuildListClass:ReceiveDrag(type, build, source)
	if type == "Build" then
		if self.hoverValue and self.hoverValue.folderName then
			if build.folderName then
				main:MoveFolder(build.folderName, main.buildPath..build.subPath, main.buildPath..self.hoverValue.subPath..self.hoverValue.folderName.."/")
			else
				os.rename(build.fullFileName, self.listMode:GetDestName(self.listMode.subPath..self.hoverValue.folderName.."/", build.fileName))
			end
			self.listMode:BuildList()
		end
	end
end

function BuildListClass:CanDragToValue(index, build, source)
	return build.folderName
end

function BuildListClass:OnSelClick(index, build, doubleClick)
	if doubleClick then
		self:LoadBuild(build)
		self.selDragging = false
	end
end

function BuildListClass:OnSelCopy(index, build)
	self.copyBuild = build
	self.cutBuild = nil
end

function BuildListClass:OnSelCut(index, build)
	self.copyBuild = nil
	self.cutBuild = build
end

function BuildListClass:OnSelDelete(index, build)
	self:DeleteBuild(build)
end

function BuildListClass:OnSelKeyDown(index, build, key)
	if key == "RETURN" then
		self:LoadBuild(build)
	elseif key == "F2" then
		self:RenameBuild(build)
	end	
end
