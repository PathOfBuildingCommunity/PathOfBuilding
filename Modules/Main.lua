-- Path of Building
--
-- Module: Main
-- Main module of program.
--
local launch = ...

local ipairs = ipairs
local m_floor = math.floor
local m_max = math.max
local t_insert = table.insert

local cfg = { }

local main = { }

main.tooltipLines = { }
function main:AddTooltipLine(size, text)
	for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
		t_insert(self.tooltipLines, { size = size, text = line })
	end
end
function main:AddTooltipSeperator(size)
	t_insert(self.tooltipLines, { size = size })
end
function main:DrawTooltip(x, y, w, h, viewPort, col, center)
	local ttW, ttH = 0, 0
	for _, data in ipairs(self.tooltipLines) do
		ttH = ttH + data.size + 2
		if data.text then
			ttW = m_max(ttW, DrawStringWidth(data.size, "VAR", data.text))
		end
	end
	ttW = ttW + 12
	ttH = ttH + 10
	local ttX = x
	local ttY = y
	if w and h then
		ttX = ttX + w + 5
		if ttX + ttW > viewPort.x + viewPort.width then
			ttX = m_max(viewPort.x, x - 5 - ttW)
		end
		if ttY + ttH > viewPort.y + viewPort.height then
			ttY = m_max(viewPort.y, y + h - ttH)
		end
	elseif center then
		ttX = m_floor(x - ttW/2)
	end
	col = col or { 0.5, 0.3, 0 }
	if type(col) == "string" then
		SetDrawColor(col) 
	else
		SetDrawColor(unpack(col))
	end
	DrawImage(nil, ttX, ttY, ttW, 3)
	DrawImage(nil, ttX, ttY, 3, ttH)
	DrawImage(nil, ttX, ttY + ttH - 3, ttW, 3)
	DrawImage(nil, ttX + ttW - 3, ttY, 3, ttH)
	SetDrawColor(0, 0, 0, 0.75)
	DrawImage(nil, ttX + 3, ttY + 3, ttW - 6, ttH - 6)
	SetDrawColor(1, 1, 1)
	local y = ttY + 6
	for i, data in ipairs(self.tooltipLines) do
		if data.text then
			if center then
				DrawString(ttX + ttW/2, y, "CENTER_X", data.size, "VAR", data.text)
			else
				DrawString(ttX + 6, y, "LEFT", data.size, "VAR", data.text)
			end
		else
			if type(col) == "string" then
				SetDrawColor(col) 
			else
				SetDrawColor(unpack(col))
			end
			DrawImage(nil, ttX + 3, y - 1 + data.size / 2, ttW - 6, 2)
		end
		y = y + data.size + 2
		self.tooltipLines[i] = nil
	end
end

LoadModule("Modules/Data")
LoadModule("Modules/ModTools")

main.TreeClass = LoadModule("Modules/Tree", launch, cfg, main)
main.SpecClass = LoadModule("Modules/Spec", launch, cfg, main)
main.TreeViewClass = LoadModule("Modules/TreeView", launch, cfg, main)

main.modes = { }
main.modes["LIST"] = LoadModule("Modules/BuildList", launch, cfg, main)
main.modes["BUILD"] = LoadModule("Modules/Build", launch, cfg, main)

function main:SetMode(newMode, ...)
	self.newMode = newMode
	self.newModeArgs = {...}
end

function main:CallMode(func, ...)
	local modeTbl = self.modes[self.mode]
	if modeTbl[func] then
		modeTbl[func](modeTbl, ...)
	end
end

function main:LoadSettings()
	local setXML, errMsg = common.xml.LoadXMLFile("Settings.xml")
	if not setXML then
		return true
	elseif setXML[1].elem ~= "PathOfBuilding" then
		launch:ShowErrMsg("^1Error parsing 'Settings.xml': 'PathOfBuilding' root element missing")
		return true
	end
	for _, node in ipairs(setXML[1]) do
		if type(node) == "table" then
			if node.elem == "Mode" then
				if not node.attrib.mode or not self.modes[node.attrib.mode] then
					launch:ShowErrMsg("^1Error parsing 'Settings.xml': Invalid mode attribute in 'Mode' element")
					return true
				end
				local args = { }
				for _, child in ipairs(node) do
					if type(child) == "table" then
						if child.elem == "Arg" then
							if child.attrib.number then
								t_insert(args, tonumber(child.attrib.number))
							elseif child.attrib.string then
								t_insert(args, child.attrib.string)
							elseif child.attrib.boolean then
								t_insert(args, child.attrib.boolean == "true")
							end
						end
					end
				end
				self:SetMode(node.attrib.mode, unpack(args))
			end
		end
	end
end
function main:SaveSettings()
	local setXML = { elem = "PathOfBuilding" }
	local mode = { elem = "Mode", attrib = { mode = self.mode } }
	for _, val in ipairs(self.modeArgs) do
		local child = { elem = "Arg", attrib = {} }
		if type(val) == "number" then
			child.attrib.number = tostring(val)
		elseif type(val) == "boolean" then
			child.attrib.boolean = tostring(val)
		else
			child.attrib.string = tostring(val)
		end
		t_insert(mode, child)
	end
	t_insert(setXML, mode)
	local res, errMsg = common.xml.SaveXMLFile(setXML, "Settings.xml")
	if not res then
		launch:ShowErrMsg("Error saving 'Settings.xml': %s", errMsg)
		return true
	end
end

function main:OnFrame()
	cfg.screenW, cfg.screenH = GetScreenSize()

	if self.newMode then
		if self.mode then
			self:CallMode("Shutdown")
		end
		self.mode = self.newMode
		self.modeArgs = self.newModeArgs
		self.newMode = nil
		self:CallMode("Init", unpack(self.modeArgs))
	end		

	self:CallMode("OnFrame", self.inputEvents)

	wipeTable(self.inputEvents)
end

function main:OnKeyDown(key, doubleClick)
	t_insert(self.inputEvents, { type = "KeyDown", key = key, doubleClick = doubleClick })
end

function main:OnKeyUp(key)
	t_insert(self.inputEvents, { type = "KeyUp", key = key })
end

function main:OnChar(key)
	t_insert(self.inputEvents, { type = "Char", key = key })
end

function main:Init()
	self.inputEvents = { }

	self.tree = self.TreeClass.NewTree()

	self:SetMode("LIST")

	self:LoadSettings()
end

function main:Shutdown()
	self:CallMode("Shutdown")

	self:SaveSettings()
end

return main