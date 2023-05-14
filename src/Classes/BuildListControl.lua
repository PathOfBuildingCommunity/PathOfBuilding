-- Path of Building
--
-- Class: Build List
-- Build list control.
--
local ipairs = ipairs
local s_format = string.format

local BuildListClass = newClass("BuildListControl", "ListControl", function(self, anchor, x, y, width, height, listMode)
	self.ListControl(anchor, x, y, width, height, 20, "VERTICAL", false, listMode.list)
	self.listMode = listMode
	self.colList = { 
		{ width = function() return self:GetProperty("width") - 172 end }, 
		{ },
	}
	self.showRowSeparators = true
	self.controls.path = new("PathControl", {"BOTTOM",self,"TOP"}, 0, -2, width, 24, main.buildPath, listMode.subPath, function(subPath)
		listMode.subPath = subPath
		listMode:BuildList()
		self.selIndex = nil
		self.selValue = nil
		self.selDragging = false
		self.selDragActive = false
		self.otherDragSource = false
		self.selIndices = { }
	end)
	function self.controls.path:CanReceiveDrag(type, builds)
		return type == "Builds" and #self.folderList > 1
	end
	function self.controls.path:ReceiveDrag(type, builds, source)
		if type == "Builds" then
			for index, folder in ipairs(self.folderList) do
				if index < #self.folderList and folder.button:IsMouseOver() then
					for _, build in pairs(builds) do
						if build.folderName then
							main:MoveFolder(build.folderName, main.buildPath..build.subPath, main.buildPath..folder.path)
						else
							os.rename(build.fullFileName, listMode:GetDestName(folder.path, build.fileName))
						end
					end
					listMode:BuildList()
				end
			end
		end
	end
	self.dragTargetList = { self.controls.path, self }
	self.selIndices = { }
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
	controls.label = new("LabelControl", nil, 0, 20, 0, 16, "^7Enter the new name for this "..(build.folderName and "folder:" or "build:"))
	controls.edit = new("EditControl", nil, 0, 40, 350, 20, build.folderName or build.buildName, nil, "\\/:%*%?\"<>|%c", 100, function(buf)
		controls.save.enabled = false
		if build.folderName then
			if buf:match("%S") then
				controls.save.enabled = true
			end
		else
			if buf:match("%S") then
				if buf:lower() ~= build.buildName:lower() then
					local newName = buf..".xml"
					local newFile = io.open(main.buildPath..build.subPath..newName, "r")
					if newFile then
						newFile:close()
					else
						controls.save.enabled = true
					end
				elseif buf ~= build.buildName then
					controls.save.enabled = true
				end
			end
		end
	end)
	controls.save = new("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
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
	controls.cancel = new("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
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

function BuildListClass:GetRowValue(column, index, build)
	if column == 1 then
		local label
		if build.folderName then
			label = "^8>> ^7" .. build.folderName
		else
			local relativeLabel = ""
			for _, segment in ipairs(string.sub(build.relativePath, 1, -2):split("/")) do
				relativeLabel = relativeLabel .. "^8>> " .. segment .. " "
			end
			relativeLabel = relativeLabel .. (relativeLabel ~= "" and ">> ^7" or "")
			label = relativeLabel .. build.buildName or "?"
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
	local builds = {}
	for idx in pairs(self.selIndices) do
		builds[idx] = self.list[idx]
	end
	return "Builds", builds
end

function BuildListClass:CanReceiveDrag(type, build)
	return type == "Builds"
end

function BuildListClass:ReceiveDrag(type, builds, source)
	if type == "Builds" then
		if self.hoverValue and self.hoverValue.folderName then
			for _, build in pairs(builds) do
				if build.folderName ~= self.hoverValue.folderName then -- don't move a folder into itself... not pretty
					if build.folderName then
						main:MoveFolder(build.folderName, main.buildPath.. build.subPath, main.buildPath..self.hoverValue.subPath..self.hoverValue.folderName.."/")
					else
						os.rename(build.fullFileName, self.listMode:GetDestName(self.listMode.subPath..self.hoverValue.folderName.."/", build.fileName))
					end
				end
			end
			self.listMode:BuildList()
			self.selIndices = {}
		end
	end
end

function BuildListClass:CanDragToValue(index, build, source)
	return build.folderName and source.selValue ~= build
end

function BuildListClass:OnSelClick(index, build, doubleClick)
	if doubleClick then
		self:LoadBuild(self.list[index])
		self.selDragging = false
		self.selDragActive = false
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

function BuildListClass:SetHighlightColor(index, value)
	if not self.selIndices[index] then
		return false
	end
	if self.selIndex ~= index then
		SetDrawColor(.6, .6, .6)	-- Grey out the other selections to hint that they are not the targets of enter to load or f2 to rename.
		return true
	end
	
	SetDrawColor(1, 1, 1)
	return true
end

function BuildListClass:ExtraOnKeyUp(key)
	if self.multiSelectCancelIndex and key == "LEFTBUTTON" then
		self.selIndices = {}
		self:SelectIndex(self.multiSelectCancelIndex)
	end
end

function BuildListClass:OverrideSelectIndex(index)
	if self.selIndices[index] and not IsKeyDown("CTRL") then
		self.multiSelectCancelIndex = index
		return false
	end
	self.multiSelectCancelIndex = nil
	if IsKeyDown("SHIFT") and self.selIndex then
		for i = self.selIndex, index, index < self.selIndex and -1 or 1 do
			self.selIndices[i] = true
		end
		self.selIndex = index
		self.selValue = self.list[index]
	elseif IsKeyDown("CTRL") and self.selIndex then
		if self.selIndices[index] then
			self.selIndices[index] = nil
			if self.selIndex == index then	-- bit of a hack to set selValue to something desirable when current selValue would be unselected, because it is required in quite a few places in ListControl
				local closestFallbackIndexDelta = math.huge
				for idx in pairs(self.selIndices) do
					if math.abs(idx - self.selIndex) < math.abs(closestFallbackIndexDelta) then
						closestFallbackIndexDelta = idx - self.selIndex
					end
				end
				if closestFallbackIndexDelta ~= math.huge then
					self.selIndex = self.selIndex + closestFallbackIndexDelta	-- just hop the selValue to the closest one available
					self.selValue = self.list[self.selIndex]
				else
					self.selIndex = nil
					self.selValue = nil
				end
			end
		else
			self.selIndex = index
			self.selValue = self.list[index]
			self.selIndices[index] = true
		end
	else
		self.selIndex = index
		self.selValue = self.list[index]
		self.selIndices = { [index] = true }
	end
	return false
end
