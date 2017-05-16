-- Path of Building
--
-- Class: Build List
-- Build list control.
--
local launch, main = ...

local s_format = string.format

local BuildListClass = common.NewClass("BuildList", "ListControl", function(self, anchor, x, y, width, height, listMode)
	self.ListControl(anchor, x, y, width, height, 20, false, listMode.list)
	self.listMode = listMode
	self.showRowSeparators = true
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
	main:SetMode("BUILD", main.buildPath..build.fileName, build.buildName)
end

function BuildListClass:RenameBuild(build, copyOnName)
	local controls = { }
	controls.label = common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter the new name for this build:")
	controls.edit = common.New("EditControl", nil, 0, 40, 350, 20, build.buildName, nil, "\\/:%*%?\"<>|%c", 100, function(buf)
		controls.save.enabled = false
		if buf:match("%S") and buf:lower() ~= build.buildName:lower() then
			local newName = buf..".xml"
			local newFile = io.open(main.buildPath..newName, "r")
			if newFile then
				newFile:close()
			else
				controls.save.enabled = true
			end
		end
	end)
	controls.save = common.New("ButtonControl", nil, -45, 70, 80, 20, "Save", function()
		local newBuildName = controls.edit.buf
		local newFileName = newBuildName..".xml"
		if copyOnName then
			local inFile, msg = io.open(main.buildPath..build.fileName, "r")
			if not inFile then
				main:OpenMessagePopup("Error", "Couldn't open '"..build.fileName.."': "..msg)
				return
			end
			local outFile, msg = io.open(main.buildPath..newFileName, "w")
			if not outFile then
				main:OpenMessagePopup("Error", "Couldn't create '"..newFileName.."': "..msg)
				return
			end
			outFile:write(inFile:read("*a"))
			inFile:close()
			outFile:close()
		else
			local res, msg = os.rename(main.buildPath..build.fileName, main.buildPath..newFileName)
			if not res then
				main:OpenMessagePopup("Error", "Couldn't rename '"..build.fileName.."' to '"..newFileName.."': "..msg)
				return
			end
			build.buildName = newBuildName
			build.fileName = newFileName
		end
		self.listMode:BuildList()
		self:SelByFileName(newFileName)
		main:ClosePopup()
		self.listMode:SelectControl(self)
	end)
	controls.save.enabled = false
	controls.cancel = common.New("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		main:ClosePopup()
		self.listMode:SelectControl(self)
	end)
	main:OpenPopup(370, 100, copyOnName and "Copy Build" or "Rename Build", controls, "save", "edit")	
end

function BuildListClass:DeleteBuild(build)
	main:OpenConfirmPopup("Confirm Delete", "Are you sure you want to delete build:\n"..build.buildName.."\nThis cannot be undone.", "Delete", function()
		os.remove(main.buildPath..build.fileName)
		self.listMode:BuildList()
		self.selIndex = nil
		self.selValue = nil
	end)
end

function BuildListClass:GetColumnOffset(column)
	if column == 1 then
		return 0
	elseif column == 2 then
		return self:GetProperty("width") - 164
	end
end

function BuildListClass:GetRowValue(column, index, build)
	if column == 1 then
		return build.buildName or "?"
	elseif column == 2 then
		return s_format("%sLevel %d %s", 
			build.className and data.colorCodes[build.className:upper()] or "^7", 
			build.level or 1, 
			(build.ascendClassName ~= "None" and build.ascendClassName) or build.className or "?"
		)
	end
end

function BuildListClass:OnSelClick(index, build, doubleClick)
	if doubleClick then
		self:LoadBuild(build)
	end
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
