-- Path of Building
--
-- Module: Build List
-- Displays the list of builds.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local buildSortDropList = {
	{ label = "Sort by Name", sortMode = "NAME" },
	{ label = "Sort by Class", sortMode = "CLASS" },
	{ label = "Sort by Last Edited", sortMode = "EDITED"},
}

local listMode = common.New("ControlHost")

function listMode:Init(selBuildName, subPath)
	if self.initialised then
		self.subPath = subPath or self.subPath
		self.controls.buildList.controls.path:SetSubPath(self.subPath)
		self.controls.buildList:SelByFileName(selBuildName and selBuildName..".xml")
		self:BuildList()
		self:SelectControl(self.controls.buildList)
		return
	end

	self.anchor = common.New("Control", nil, 0, 4, 0, 0)
	self.anchor.x = function() 
		return main.screenW / 2 
	end

	self.subPath = subPath or ""
	self.list = { }

	self.controls.new = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, -259, 0, 60, 20, "New", function()
		main:SetMode("BUILD", false, "Unnamed build")
	end)
	self.controls.newFolder = common.New("ButtonControl", {"LEFT",self.controls.new,"RIGHT"}, 8, 0, 90, 20, "New Folder", function()
		self.controls.buildList:NewFolder()
	end)
	self.controls.open = common.New("ButtonControl", {"LEFT",self.controls.newFolder,"RIGHT"}, 8, 0, 60, 20, "Open", function()
		self.controls.buildList:LoadBuild(self.controls.buildList.selValue)
	end)
	self.controls.open.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.copy = common.New("ButtonControl", {"LEFT",self.controls.open,"RIGHT"}, 8, 0, 60, 20, "Copy", function()
		self.controls.buildList:RenameBuild(self.controls.buildList.selValue, true)
	end)
	self.controls.copy.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.rename = common.New("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, 8, 0, 60, 20, "Rename", function()
		self.controls.buildList:RenameBuild(self.controls.buildList.selValue)
	end)
	self.controls.rename.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.delete = common.New("ButtonControl", {"LEFT",self.controls.rename,"RIGHT"}, 8, 0, 60, 20, "Delete", function()
		self.controls.buildList:DeleteBuild(self.controls.buildList.selValue)
	end)
	self.controls.delete.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.sort = common.New("DropDownControl", {"LEFT",self.controls.delete,"RIGHT"}, 8, 0, 140, 20, buildSortDropList, function(index, value)
		main.buildSortMode = value.sortMode
		self:SortList()
	end)
	self.controls.sort:SelByValue(main.buildSortMode, "sortMode")
	self.controls.buildList = common.New("BuildList", {"TOP",self.anchor,"TOP"}, 0, 50, 640, 0, self)
	self.controls.buildList.height = function()
		return main.screenH - 58
	end

	self:BuildList()
	self.controls.buildList:SelByFileName(selBuildName and selBuildName..".xml")
	self:SelectControl(self.controls.buildList)

	self.initialised = true
end

function listMode:Shutdown()
end

function listMode:GetArgs()
	return self.controls.buildList.selValue and self.controls.buildList.selValue.buildName or false, self.subPath
end

function listMode:OnFrame(inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then	
			if event.key == "v" and IsKeyDown("CTRL") then
				if self.controls.buildList.copyBuild then
					local build = self.controls.buildList.copyBuild
					if build.subPath ~= self.subPath then
						if build.folderName then
							main:CopyFolder(build.folderName, main.buildPath..build.subPath, main.buildPath..self.subPath)
						else
							copyFile(build.fullFileName, self:GetDestName(self.subPath, build.fileName))
						end
						self:BuildList()
					else
						self.controls.buildList:RenameBuild(build, true)
					end
					self.controls.buildList.copyBuild = nil
				elseif self.controls.buildList.cutBuild then
					local build = self.controls.buildList.cutBuild
					if build.subPath ~= self.subPath then
						if build.folderName then
							main:MoveFolder(build.folderName, main.buildPath..build.subPath, main.buildPath..self.subPath)
						else
							os.rename(build.fullFileName, self:GetDestName(self.subPath, build.fileName))
						end
						self:BuildList()
					end
					self.controls.buildList.cutBuild = nil
				end
			elseif event.key == "n" and IsKeyDown("CTRL") then
				main:SetMode("BUILD", false, "Unnamed build")
			elseif event.key == "MOUSE4" then
				self.controls.buildList.controls.path:Undo()
			elseif event.key == "MOUSE5" then
				self.controls.buildList.controls.path:Redo()
			end
		end
	end
	self:ProcessControlsInput(inputEvents, main.viewPort)

	main:DrawBackground(main.viewPort)

	self:DrawControls(main.viewPort)
end

function listMode:GetDestName(subPath, fileName)
	local i = 2
	local destName = fileName
	while true do
		local test = io.open(destName, "r")
		if test then
			destName = fileName .. "[" .. i .. "]"
			i = i + 1
		else
			break
		end
	end
	return main.buildPath..subPath..destName
end

function listMode:BuildList()
	wipeTable(self.list)
	local handle = NewFileSearch(main.buildPath..self.subPath.."*.xml")
	while handle do
		local fileName = handle:GetFileName()
		local build = { }
		build.fileName = fileName
		build.subPath = self.subPath
		build.fullFileName = main.buildPath..self.subPath..fileName
		build.modified = handle:GetFileModifiedTime()
		build.buildName = fileName:gsub("%.xml$","")
		local dbXML = common.xml.LoadXMLFile(build.fullFileName)
		if dbXML and dbXML[1].elem == "PathOfBuilding" then
			for _, node in ipairs(dbXML[1]) do
				if type(node) == "table" and node.elem == "Build" then
					build.level = tonumber(node.attrib.level)
					build.className = node.attrib.className
					build.ascendClassName = node.attrib.ascendClassName
				end
			end
		end
		t_insert(self.list, build)
		if not handle:NextFile() then
			break
		end
	end
	handle = NewFileSearch(main.buildPath..self.subPath.."*", true)
	while handle do
		local folderName = handle:GetFileName()
		t_insert(self.list, { 
			folderName = folderName, 
			subPath = self.subPath,
			fullFileName = main.buildPath..self.subPath..folderName,
		})
		if not handle:NextFile() then
			break
		end
	end
	self:SortList()
end

function listMode:SortList()
	local oldSelFileName = self.controls.buildList.selValue and self.controls.buildList.selValue.fileName
	table.sort(self.list, function(a, b) 
		if a.folderName and b.folderName then
			return a.folderName:upper() < b.folderName:upper()
		elseif a.folderName and not b.folderName then
			return true
		elseif not a.folderName and b.folderName then
			return false
		end
		if main.buildSortMode == "EDITED" then
			return a.modified > b.modified
		elseif main.buildSortMode == "CLASS" then
			if a.className and not b.className then
				return false
			elseif not a.className and b.className then
				return true
			elseif a.className ~= b.className then
				return a.className < b.className
			elseif a.ascendClassName ~= b.ascendClassName then
				return a.ascendClassName < b.ascendClassName
			end
		end
		return a.fileName:upper() < b.fileName:upper()
	end)
	if oldSelFileName then
		self.controls.buildList:SelByFileName(oldSelFileName)
	end
end

return listMode