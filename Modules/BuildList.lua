-- Path of Building
--
-- Module: BuildList
-- Displays the list of builds.
--
local launch, main = ...

local ipairs = ipairs
local t_insert = table.insert

local listMode = { }

function listMode:Init(selBuildName)
	self:BuildList()
	self:SelByFileName(selBuildName and selBuildName..".xml")

	self.controls = { }
	t_insert(self.controls, common.New("ButtonControl", function() return main.screenW/2 - 30 - 68*2 end, 4, 60, 20, "Open", function()
		self:LoadSel()
	end, function()
		return self.sel ~= nil
	end))
	t_insert(self.controls, common.New("ButtonControl", function() return main.screenW/2 - 30 - 68*1 end, 4, 60, 20, "New", function()
		self:New()
	end))
	t_insert(self.controls, common.New("ButtonControl", function() return main.screenW/2 - 30 end, 4, 60, 20, "Copy", function()
		self:CopySel()
	end, function()
		return self.sel ~= nil
	end))
	t_insert(self.controls, common.New("ButtonControl", function() return main.screenW/2 + 38 end, 4, 60, 20, "Rename", function()
		self:RenameSel()
	end, function()
		return self.sel ~= nil
	end))
	t_insert(self.controls, common.New("ButtonControl", function() return main.screenW/2 + 38 + 68*1 end, 4, 60, 20, "Delete", function()
		self:DeleteSel()
	end, function()
		return self.sel ~= nil
	end))
end

function listMode:Shutdown()
	if self.edit then
		self:EditCancel()
	end
end

function listMode:OnFrame(inputEvents)
	for id, event in ipairs(inputEvents) do
		if event.type == "KeyDown" then
			self:OnKeyDown(event.key, event.doubleClick)
		elseif event.type == "KeyUp" then
			self:OnKeyUp(event.key)
		elseif event.type == "Char" then
			self:OnChar(event.key)
		end
	end
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(main.tree.assets.Background1.handle, 0, 0, main.screenW, main.screenH, 0, 0, main.screenW / 100, main.screenH / 100)
	common.controlsDraw(self)
	for index, build in ipairs(self.list) do
		local y = 8 + index * 20
		local x = main.screenW/2 - 250
		if self.sel == index then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawImage(nil, x, y, 500, 20)
		if self.sel == index then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif index % 2 == 0 then
			SetDrawColor(0.05, 0.05, 0.05)
		else
			SetDrawColor(0, 0, 0)
		end
		DrawImage(nil, x + 1, y + 1, 498, 18)
		if self.edit == index then
			self.editField:Draw(x + 2, y + 2, 16)
		else
			DrawString(x + 4, y + 2, "LEFT", 16, "VAR", "^7"..build.fileName:gsub("%.xml$",""))
			SetDrawColor(build.className and data.colorCodes[build.className:upper()] or "^7")
			DrawString(x + 350, y + 2, "LEFT", 16, "VAR", string.format("Level %d %s", build.level or 1, (build.ascendClassName ~= "None" and build.ascendClassName) or build.className or "?"))
		end
	end
end

function listMode:OnKeyDown(key, doubleClick)
	if self.edit then
		if key == "RETURN" then
			self:EditFinish()
		elseif key == "ESCAPE" then
			self:EditCancel()
		else
			self.editField:OnKeyDown(key)
		end
	elseif key == "LEFTBUTTON" then
		self.selControl = nil
		local cx, cy = GetCursorPos()
		for _, control in pairs(self.controls) do
			if control.IsMouseOver and control:IsMouseOver() then
				control:OnKeyDown(key)
				self.selControl = control
				return
			end
		end
		self.sel = nil
		if cx >= main.screenW/2 - 250 and cx < main.screenW/2 + 250 then
			for index, fileName in ipairs(self.list) do
				local y = 8 + index * 20
				if cy >= y and cy < y + 20 then
					self.sel = index
					if doubleClick then
						self:LoadSel()
					end
					return
				end
			end
		end
	elseif key == "RETURN" then
		if self.sel then
			self:LoadSel()
		end
	elseif key == "UP" then
		if not self.sel then
			self.sel = #self.list
		else
			self.sel = (self.sel - 2) % #self.list + 1
		end
	elseif key == "DOWN" then
		if not self.sel then
			self.sel = 1
		else
			self.sel = self.sel % #self.list + 1
		end
	elseif key == "F2" then
		if self.sel then
			self:RenameSel()
		end
	elseif key == "DELETE" then
		if self.sel then
			self:DeleteSel()
		end
	end
end

function listMode:OnKeyUp(key)
	if self.edit then
		self.editField:OnKeyUp(key)
	elseif self.selControl then
		self.selControl:OnKeyUp(key)
		self.selControl = nil
	end
end

function listMode:OnChar(key)
	if self.edit then
		self.editField:OnChar(key)
	end
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
end

function listMode:SelByFileName(selFileName)
	self.sel = nil
	for index, build in ipairs(self.list) do
		if build.fileName == selFileName then
			self.sel = index
			break
		end
	end
end

function listMode:EditInit(finFunc)
	self.edit = self.sel
	self.editFinFunc = finFunc
	self.editField = common.newEditField(self.list[self.sel].fileName:gsub("%.xml$",""), nil, "[%w _+.()]")
	self.editField.x = 2
	self.editField.y = 6 + self.sel * 20
	self.editField.width = main.screenW
	self.editField.height = 16
end

function listMode:EditFinish()
	local msg = self.editFinFunc(self.editField.buf)
	if msg then
		launch:ShowPrompt(1, 0.5, 0, msg.."\n\nEnter/Escape to dismiss")
		return
	end
	self.edit = nil
	self.editField = nil
end

function listMode:EditCancel()
	self.sel = nil
	self.edit = nil
	self.editField = nil
	self:BuildList()	
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
		self:SortList()
	end)
end

function listMode:LoadSel()
	main:SetMode("BUILD", main.buildPath..self.list[self.sel].fileName, (self.list[self.sel].fileName:gsub("%.xml$","")))
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
		self:SortList()
	end)
end

function listMode:DeleteSel()
	launch:ShowPrompt(1, 0, 0, "Are you sure you want to delete\n'"..self.list[self.sel].fileName.."' ? (y/n)", function(key)
		if key == "y" then
			os.remove(main.buildPath..self.list[self.sel].fileName)
			self:BuildList()
			self.sel = nil
		end
		return true
	end)
end

return listMode