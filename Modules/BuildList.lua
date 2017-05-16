-- Path of Building
--
-- Module: Build List
-- Displays the list of builds.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs

local listMode = common.New("ControlHost")

function listMode:Init(selBuildName)
	self.anchor = common.New("Control", nil, 0, 4, 0, 0)
	self.anchor.x = function() 
		return main.screenW / 2 
	end

	self.list = { }

	self.controls.new = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, -210, 0, 60, 20, "New", function()
		main:SetMode("BUILD", false, "Unnamed build")
	end)
	self.controls.open = common.New("ButtonControl", {"LEFT",self.controls.new,"RIGHT"}, 8, 0, 60, 20, "Open", function()
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
	self.controls.sort = common.New("DropDownControl", {"LEFT",self.controls.delete,"RIGHT"}, 8, 0, 140, 20, {{val="NAME",label="Sort by Name"},{val="CLASS",label="Sort by Class"},{val="EDITED",label="Sort by Last Edited"}}, function(sel, val)
		main.buildSortMode = val.val
		self:SortList()
	end)
	self.controls.sort:SelByValue(main.buildSortMode)

	self.controls.buildList = common.New("BuildList", {"TOP",self.anchor,"TOP"}, 0, 24, 640, 0, self)
	self.controls.buildList.height = function()
		return main.screenH - 32
	end

	self:BuildList()
	self.controls.buildList:SelByFileName(selBuildName and selBuildName..".xml")
	self:SelectControl(self.controls.buildList)
end

function listMode:Shutdown()
end

function listMode:OnFrame(inputEvents)
	self:ProcessControlsInput(inputEvents, main.viewPort)

	main:DrawBackground(main.viewPort)

	self:DrawControls(main.viewPort)
end

function listMode:BuildList()
	self.list = wipeTable(self.list)
	local handle = NewFileSearch(main.buildPath.."*.xml")
	if not handle then
		return
	end
	while true do
		local fileName = handle:GetFileName()
		local build = { }
		build.fileName = fileName
		build.modified = handle:GetFileModifiedTime()
		build.buildName = fileName:gsub("%.xml$","")
		local dbXML = common.xml.LoadXMLFile(main.buildPath..fileName)
		if dbXML and dbXML[1].elem == "PathOfBuilding" then
			for _, node in ipairs(dbXML[1]) do
				if type(node) == "table" and node.elem == "Build" then
					build.level = tonumber(node.attrib.level)
					build.className = node.attrib.className
					build.ascendClassName = node.attrib.ascendClassName
				end
			end
		end
		table.insert(self.list, build)
		if not handle:NextFile() then
			break
		end
	end
	self:SortList()
end

function listMode:SortList()
	local oldSelFileName = self.controls.buildList.selValue and self.controls.buildList.selValue.fileName
	table.sort(self.list, function(a, b) 
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