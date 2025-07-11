-- Path of Building
--
-- Module: Build List
-- Displays the list of builds.
--
local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local buildSortDropList = {
	{ label = "Sort by Name", sortMode = "NAME" },
	{ label = "Sort by Class", sortMode = "CLASS" },
	{ label = "Sort by Last Edited", sortMode = "EDITED"},
	{ label = "Sort by Level", sortMode = "LEVEL"},
}

local listMode = new("ControlHost")

function listMode:Init(selBuildName, subPath)
	if self.initialised then
		self.subPath = subPath or self.subPath
		self.controls.buildList.controls.path:SetSubPath(self.subPath)
		self.controls.buildList:SelByFileName(selBuildName and selBuildName..".xml")
		--if main.showPublicBuilds then
		if false then
			self.controls.ExtBuildList = self:getPublicBuilds()
		else
			self.controls.ExtBuildList = nil
		end
		self:BuildList()
		self:SelectControl(self.controls.buildList)
		return
	end

	self.anchor = new("Control", nil, {0, 4, 0, 0})
	self.anchor.x = function()
		return main.screenW / 2
	end

	self.subPath = subPath or ""
	self.list = { }

	self.controls.new = new("ButtonControl", {"TOP",self.anchor,"TOP"}, {-259, 0, 60, 20}, "New", function()
		main:SetMode("BUILD", false, "Unnamed build")
	end)
	self.controls.newFolder = new("ButtonControl", {"LEFT",self.controls.new,"RIGHT"}, {8, 0, 90, 20}, "New Folder", function()
		self.controls.buildList:NewFolder()
	end)
	self.controls.open = new("ButtonControl", {"LEFT",self.controls.newFolder,"RIGHT"}, {8, 0, 60, 20}, "Open", function()
		self.controls.buildList:LoadBuild(self.controls.buildList.selValue)
	end)
	self.controls.open.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.copy = new("ButtonControl", {"LEFT",self.controls.open,"RIGHT"}, {8, 0, 60, 20}, "Copy", function()
		self.controls.buildList:RenameBuild(self.controls.buildList.selValue, true)
	end)
	self.controls.copy.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.rename = new("ButtonControl", {"LEFT",self.controls.copy,"RIGHT"}, {8, 0, 60, 20}, "Rename", function()
		self.controls.buildList:RenameBuild(self.controls.buildList.selValue)
	end)
	self.controls.rename.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.delete = new("ButtonControl", {"LEFT",self.controls.rename,"RIGHT"}, {8, 0, 60, 20}, "Delete", function()
		self.controls.buildList:DeleteBuild(self.controls.buildList.selValue)
	end)
	self.controls.delete.enabled = function() return self.controls.buildList.selValue ~= nil end
	self.controls.sort = new("DropDownControl", {"LEFT",self.controls.delete,"RIGHT"}, {8, 0, 140, 20}, buildSortDropList, function(index, value)
		main.buildSortMode = value.sortMode
		self:SortList()
	end)
	self.controls.sort:SelByValue(main.buildSortMode, "sortMode")
	self.controls.buildList = new("BuildListControl", {"TOP",self.anchor,"TOP"}, {0, 75, 900, 0}, self)
	self.controls.buildList.height = function()
		return main.screenH - 80
	end
	local buildListWidth = function ()
		--if main.showPublicBuilds then
		if false then
			return math.min((main.screenW / 2), 900)
		else
			return 900
		end
	end
	local buildListOffset = function ()
		--if main.showPublicBuilds then
		if false then
			local offset = math.min(450, main.screenW / 4)
			return offset - 450
		else
			return 0
		end
	end

	self.controls.buildList.width = buildListWidth
	self.controls.buildList.x = buildListOffset

	--if main.showPublicBuilds then
	if false then
		self.controls.ExtBuildList = self:getPublicBuilds()
	end

	self.controls.searchText = new("EditControl", {"TOP",self.anchor,"TOP"}, {0, 25, 640, 20}, self.filterBuildList, "Search", "%c%(%)", 100, function(buf)
		main.filterBuildList = buf
		self:BuildList()
	end, nil, nil, true)
	self.controls.searchText.width = buildListWidth
	self.controls.searchText.x = buildListOffset

	self:BuildList()
	self.controls.buildList:SelByFileName(selBuildName and selBuildName..".xml")
	self:SelectControl(self.controls.buildList)

	self.initialised = true
end

function listMode:getPublicBuilds()
	local buildProviders = {
		{
			name = "PoB Archives",
			impl = new("PoBArchivesProvider", "builds")
		}
	}
	local extBuildList = new("ExtBuildListControl", {"LEFT",self.controls.buildList,"RIGHT"}, {25, 0, main.screenW * 1 / 4 - 50, 0}, buildProviders)
	extBuildList:Init("PoB Archives")
	extBuildList.height = function()
		return main.screenH - 80
	end
	extBuildList.width = function ()
		return math.max((main.screenW / 4 - 50), 400)
	end
	return extBuildList
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
	local filterList = main.filterBuildList or ""
	local handle = nil
	if filterList ~= "" then
		handle = NewFileSearch(main.buildPath..self.subPath.."*"..filterList.."*.xml")
	else
		handle = NewFileSearch(main.buildPath..self.subPath.."*.xml")
	end
	while handle do
		local fileName = handle:GetFileName()
		local build = { }
		build.fileName = fileName
		build.subPath = self.subPath
		build.fullFileName = main.buildPath..self.subPath..fileName
		build.modified = handle:GetFileModifiedTime()
		build.buildName = fileName:gsub("%.xml$","")
		local fileHnd = io.open(build.fullFileName, "r")
		if fileHnd then
			local fileText = fileHnd:read("*a")
			fileHnd:close()
			fileText = fileText:match("(<Build.->)")
			if fileText then
				local xml = common.xml.ParseXML(fileText.."</Build>")
				if xml and xml[1] then
					build.level = tonumber(xml[1].attrib.level)
					build.className = xml[1].attrib.className
					build.ascendClassName = xml[1].attrib.ascendClassName
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
			modified = handle:GetFileModifiedTime()
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
		local a_is_folder = a.folderName ~= nil
		local b_is_folder = b.folderName ~= nil

		if a_is_folder and not b_is_folder then return true end
		if not a_is_folder and b_is_folder then return false end


		if main.buildSortMode == "EDITED" then
			local modA = a.modified or 0 -- Use 0 as fallback if modified time is nil
			local modB = b.modified or 0
			if modA ~= modB then
				return modA > modB -- Newest first maybe allow for inverting of order?
			end
			-- If modified times are the same or both 0 fall back to name sort
			if a_is_folder then
				return naturalSortCompare(a.folderName, b.folderName)
			else
				return naturalSortCompare(a.fileName, b.fileName)
			end
		end

		if a_is_folder then
			return naturalSortCompare(a.folderName, b.folderName)
		else
			if main.buildSortMode == "CLASS" then
				local a_has_class = a.className ~= nil
				local b_has_class = b.className ~= nil
				if not a_has_class and b_has_class then return true
				elseif a_has_class and not b_has_class then return false
				elseif a_has_class and b_has_class and a.className ~= b.className then
					return a.className < b.className
				end

				local a_has_asc = a.ascendClassName ~= nil
				local b_has_asc = b.ascendClassName ~= nil
				if not a_has_asc and b_has_asc then return true
				elseif a_has_asc and not b_has_asc then return false
				elseif a_has_asc and b_has_asc and a.ascendClassName ~= b.ascendClassName then
					return a.ascendClassName < b.ascendClassName
				end
				return naturalSortCompare(a.fileName, b.fileName)
			elseif main.buildSortMode == "LEVEL" then
				if a.level and not b.level then return false
				elseif not a.level and b.level then return true
				elseif a.level and b.level then
					if a.level ~= b.level then return a.level < b.level end
				end
				return naturalSortCompare(a.fileName, b.fileName)
			else
				return naturalSortCompare(a.fileName, b.fileName)
			end
		end
	end)
	if oldSelFileName then
		self.controls.buildList:SelByFileName(oldSelFileName)
	end
end

return listMode
