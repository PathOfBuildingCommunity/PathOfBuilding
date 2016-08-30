-- Path of Building
--
-- Module: Build List
-- Displays the list of builds.
--
local launch, main = ...

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local listMode = common.New("ControlHost")

function listMode:Init(selBuildName)
	self.anchor = common.New("Control", nil, 0, 4, 0, 0)
	self.anchor.x = function() 
		return main.screenW / 2 
	end

	self.controls.new = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, -68*2, 0, 60, 20, "New", function()
		self:New()
	end)
	self.controls.open = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, -68, 0, 60, 20, "Open", function()
		self:LoadSel()
	end)
	self.controls.open.enabled = function() return self.sel ~= nil end
	self.controls.copy = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, 0, 0, 60, 20, "Copy", function()
		self:CopySel()
	end)
	self.controls.copy.enabled = function() return self.sel ~= nil end
	self.controls.rename = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, 68, 0, 60, 20, "Rename", function()
		self:RenameSel()
	end)
	self.controls.rename.enabled = function() return self.sel ~= nil end
	self.controls.delete = common.New("ButtonControl", {"TOP",self.anchor,"TOP"}, 68*2, 0, 60, 20, "Delete", function()
		self:DeleteSel()
	end)
	self.controls.delete.enabled = function() return self.sel ~= nil end

	self.controls.buildList = common.New("BuildList", {"TOP",self.anchor,"TOP"}, 0, 24, 500, 0, self)
	self.controls.buildList.height = function()
		return main.screenH - 32
	end

	self:BuildList()
	self:SelByFileName(selBuildName and selBuildName..".xml")
	self:SelectControl(self.controls.buildList)
end

function listMode:Shutdown()
end

function listMode:OnFrame(inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			if self.edit then
				if event.key == "RETURN" then
					self:EditFinish()
					inputEvents[id] = nil
				elseif event.key == "ESCAPE" then
					self:EditCancel()
					inputEvents[id] = nil
				end
			end
		end
	end
	self:ProcessControlsInput(inputEvents)

	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(main.tree.assets.Background1.handle, 0, 0, main.screenW, main.screenH, 0, 0, main.screenW / 100, main.screenH / 100)

	self:DrawControls()
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
	local oldSelFileName = self.sel and self.list[self.sel].fileName
	table.sort(self.list, function(a, b) return a.fileName:upper() < b.fileName:upper() end)
	if oldSelFileName then
		self:SelByFileName(oldSelFileName)
	end
	self.controls.buildList:ScrollSelIntoView()
end

function listMode:SelByFileName(selFileName)
	self.sel = nil
	for index, build in ipairs(self.list) do
		if build.fileName == selFileName then
			self.sel = index
			self.controls.buildList:ScrollSelIntoView()
			break
		end
	end
end

function listMode:EditInit(finFunc)
	self.edit = self.sel
	self.editFinFunc = finFunc
	self.controls.buildList:ScrollSelIntoView()
	self.controls.buildList.controls.nameEdit:SetText(self.list[self.sel].buildName or "")
end

function listMode:EditFinish()
	local msg = self.editFinFunc(self.controls.buildList.controls.nameEdit.buf)
	if msg then
		main:OpenMessagePopup("Message", msg)
		return
	end
	self.edit = nil
	self:SelectControl(self.controls.buildList)
end

function listMode:EditCancel()
	self.sel = nil
	self.edit = nil
	self:BuildList()
	self:SelectControl(self.controls.buildList)
end

function listMode:New()
	table.insert(self.list, 1, { fileName = "", level = 1 })
	self.sel = 1
	self:EditInit(function(buf)
		if #buf < 1 then
			return "No name entered"
		end
		local fileName = buf .. ".xml"
		local outFile, msg = io.open(main.buildPath..fileName, "r")
		if outFile then
			outFile:close()
			return "'"..fileName.."' already exists"
		end
		outFile, msg = io.open(main.buildPath..fileName, "w")
		if not outFile then
			return "Couldn't create '"..fileName.."': "..msg
		end
		outFile:write('<?xml version="1.0" encoding="UTF-8"?>\n<PathOfBuilding>\n</PathOfBuilding>')
		outFile:close()
		self.list[self.sel].fileName = fileName
		self.list[self.sel].buildName = buf
		self:SortList()
	end)
end

function listMode:LoadSel()
	main:SetMode("BUILD", main.buildPath..self.list[self.sel].fileName, self.list[self.sel].buildName)
end

function listMode:CopySel()
	local srcName = self.list[self.sel].fileName
	table.insert(self.list, self.sel + 1, copyTable(self.list[self.sel]))
	self.sel = self.sel + 1
	self.list[self.sel].fileName = srcName:gsub("%.xml$","") .. " (copy)"
	self:EditInit(function(buf)
		if #buf < 1 then
			return "No name entered"
		end
		local inFile, msg = io.open(main.buildPath..srcName, "r")
		if not inFile then
			return "Couldn't copy '"..srcName.."': "..msg
		end
		local dstName = buf .. ".xml"
		local outFile, msg = io.open(main.buildPath..dstName, "r")
		if outFile then
			outFile:close()
			return "'"..dstName.."' already exists"
		end
		outFile, msg = io.open(main.buildPath..dstName, "w")
		if not outFile then
			return "Couldn't create '"..dstName.."': "..msg
		end
		outFile:write(inFile:read("*a"))
		inFile:close()
		outFile:close()
		self.list[self.sel].fileName = dstName
		self.list[self.sel].buildName = buf
		self:SortList()
	end)
end

function listMode:RenameSel()
	local oldName = self.list[self.sel].fileName
	self:EditInit(function(buf)
		if #buf < 1 then
			return "No name entered"
		end
		local newName = buf .. ".xml"
		if newName == oldName then
			return
		end
		if newName:lower() ~= oldName:lower() then
			local newFile = io.open(main.buildPath..newName, "r")
			if newFile then
				newFile:close()
				return "'"..newName.."' already exists"
			end
		end
		local res, msg = os.rename(main.buildPath..oldName, main.buildPath..newName)
		if not res then
			return "Couldn't rename '"..oldName.."' to '"..newName.."': "..msg
		end
		self.list[self.sel].fileName = newName
		self.list[self.sel].buildName = buf
		self:SortList()
	end)
end

function listMode:DeleteSel()
	main:OpenConfirmPopup("Confirm Delete", "Are you sure you want to delete build:\n"..self.list[self.sel].buildName.."\nThis cannot be undone.", "Delete", function()
		os.remove(main.buildPath..self.list[self.sel].fileName)
		self:BuildList()
		self.sel = nil
	end)
end

return listMode