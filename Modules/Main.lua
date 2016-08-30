-- Path of Building
--
-- Module: Main
-- Main module of program.
--
local launch = ...

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_floor = math.floor
local m_max = math.max
local m_min = math.min

LoadModule("Modules/Common")
LoadModule("Modules/Data")
LoadModule("Modules/ModTools")
LoadModule("Modules/ItemTools")

LoadModule("Classes/ControlHost")

local main = common.New("ControlHost")

local classList = {
	-- Basic controls
	"Control",
	"LabelControl",
	"SectionControl",
	"ButtonControl",
	"CheckBoxControl",
	"EditControl",
	"DropDownControl",
	"ScrollBarControl",
	"SliderControl",
	-- Misc
	"PopupDialog",
	"UndoHandler",
	-- Mode: Build list
	"BuildListControl",
	-- Mode: Build
	"ImportTab",
	"TreeTab",
	"PassiveTree",
	"PassiveSpec",
	"PassiveTreeView",
	"SkillsTab",
	"SkillListControl",
	"SlotSelectControl",
	"ItemsTab",
	"ItemSlotControl",
	"ItemListControl",
	"ItemDBControl",
	"CalcsTab",
	"Grid",
}
for _, className in pairs(classList) do
	LoadModule("Classes/"..className, launch, main)
end

function main:Init()
	self.modes = { }
	self.modes["LIST"] = LoadModule("Modules/BuildList", launch, self)
	self.modes["BUILD"] = LoadModule("Modules/Build", launch, self)

	if launch.devMode or GetScriptPath() == GetRuntimePath() then
		-- If running in dev mode or standalone mode, put user data in the script path
		self.userPath = GetScriptPath().."/"
	else
		self.userPath = GetUserPath().."/Path of Building/"
		MakeDir(self.userPath)
	end
	self.buildPath = self.userPath.."Builds/"
	MakeDir(self.buildPath)
	
	self.tree = common.New("PassiveTree")

	ConPrintf("Loading item databases...")
	self.uniqueDB = { list = { } }
	for type, typeList in pairs(data.uniques) do
		for _, raw in pairs(typeList) do
			local newItem = itemLib.makeItemFromRaw(raw)
			if newItem then
				self.uniqueDB.list[newItem.name] = newItem
			else
				ConPrintf("Unique DB unrecognised item of type '%s':\n%s", type, raw)
			end
		end
	end
	self.rareDB = { list = { } }
	for _, raw in pairs(data.rares) do
		local newItem = itemLib.makeItemFromRaw(raw)
		if newItem then
			self.rareDB.list[newItem.name] = newItem
		else
			ConPrintf("Rare DB unrecognised item:\n%s", raw)
		end
	end

	self.anchorUpdate = common.New("Control", nil, 2, 0, 0, 0)
	self.anchorUpdate.y = function()
		return self.screenH - 2
	end
	self.controls.applyUpdate = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorUpdate,"BOTTOMLEFT"}, 0, 0, 110, 20, "^x50E050Apply Update", function()
		launch:ApplyUpdate(launch.updateAvailable)
	end)
	self.controls.applyUpdate.shown = function()
		return launch.updateAvailable and launch.updateAvailable ~= "none"
	end
	self.controls.checkUpdate = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorUpdate,"BOTTOMLEFT"}, 0, 0, 110, 18, "Check for Update", function()
		launch:CheckForUpdate()
	end)
	self.controls.checkUpdate.shown = function()
		return not launch.devMode and (not launch.updateAvailable or launch.updateAvailable == "none")
	end
	self.controls.checkUpdate.enabled = function()
		return not IsSubScriptRunning()
	end
	self.controls.devMode = common.New("LabelControl", {"BOTTOMLEFT",self.anchorUpdate,"BOTTOMLEFT"}, 0, 0, 0, 18, "^1Dev Mode")
	self.controls.devMode.shown = function()
		return launch.devMode
	end

	self.inputEvents = { }
	self.popups = { }
	self.tooltipLines = { }

	self.accountSessionIDs = { }

	self:SetMode("LIST")

	self:LoadSettings()
end

function main:Shutdown()
	self:CallMode("Shutdown")

	self:SaveSettings()
end

function main:OnFrame()
	self.screenW, self.screenH = GetScreenSize()

	if self.newMode then
		if self.mode then
			self:CallMode("Shutdown")
		end
		self.mode = self.newMode
		self.modeArgs = self.newModeArgs
		self.newMode = nil
		self:CallMode("Init", unpack(self.modeArgs))
	end

	if self.popups[1] then
		self.popups[1]:ProcessInput(self.inputEvents)
		wipeTable(self.inputEvents)
	else
		self:ProcessControlsInput(self.inputEvents)
	end

	self:CallMode("OnFrame", self.inputEvents)

	self:DrawControls()

	if self.popups[1] then
		SetDrawLayer(10)
		SetDrawColor(0, 0, 0, 0.5)
		DrawImage(nil, 0, 0, self.screenW, self.screenH)
		self.popups[1]:Draw()
		SetDrawLayer(0)
	end

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
	local setXML, errMsg = common.xml.LoadXMLFile(self.userPath.."Settings.xml")
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
			elseif node.elem == "Accounts" then
				self.lastAccountName = node.attrib.lastAccountName
				for _, child in ipairs(node) do
					if child.elem == "Account" then
						self.accountSessionIDs[child.attrib.accountName] = child.attrib.sessionID
					end
				end
			end
		end
	end
end

function main:SaveSettings()
	local setXML = { elem = "PathOfBuilding" }
	local mode = { elem = "Mode", attrib = { mode = self.mode } }
	for _, val in ipairs(self.modeArgs) do
		local child = { elem = "Arg", attrib = { } }
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
	local accounts = { elem = "Accounts", attrib = { lastAccountName = self.lastAccountName } }
	for accountName, sessionID in pairs(self.accountSessionIDs) do
		t_insert(accounts, { elem = "Account", attrib = { accountName = accountName, sessionID = sessionID } })
	end
	t_insert(setXML, accounts)
	local res, errMsg = common.xml.SaveXMLFile(setXML, self.userPath.."Settings.xml")
	if not res then
		launch:ShowErrMsg("Error saving 'Settings.xml': %s", errMsg)
		return true
	end
end

function main:DrawBackground(viewPort)
	SetDrawLayer(nil, -100)
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(self.tree.assets.Background1.handle, viewPort.x, viewPort.y, viewPort.width, viewPort.height, 0, 0, viewPort.width / 100, viewPort.height / 100)
	SetDrawLayer(nil, 0)
end

function main:DrawArrow(x, y, size, dir)
	local x1 = x - size / 2
	local x2 = x + size / 2
	local xMid = (x1 + x2) / 2
	local y1 = y - size / 2
	local y2 = y + size / 2
	local yMid = (y1 + y2) / 2
	if dir == "UP" then
		DrawImageQuad(nil, xMid, y1, xMid, y1, x2, y2, x1, y2)
	elseif dir == "RIGHT" then
		DrawImageQuad(nil, x1, y1, x2, yMid, x2, yMid, x1, y2)
	elseif dir == "DOWN" then
		DrawImageQuad(nil, x1, y1, x2, y1, xMid, y2, xMid, y2)
	elseif dir == "LEFT" then
		DrawImageQuad(nil, x1, yMid, x2, y1, x2, y2, x1, yMid)
	end
end

function main:OpenPopup(width, height, title, controls)
	local popup = common.New("PopupDialog", width, height, title, controls)
	t_insert(self.popups, popup)
	return popup
end

function main:ClosePopup()
	t_remove(self.popups, 1)
end

function main:OpenMessagePopup(title, msg)
	local controls = { }
	local numMsgLines = 0
	for line in string.gmatch(msg .. "\n", "([^\n]*)\n") do
		t_insert(controls, common.New("LabelControl", nil, 0, 20 + numMsgLines * 16, 0, 16, line))
		numMsgLines = numMsgLines + 1
	end
	t_insert(controls, common.New("ButtonControl", nil, 0, 40 + numMsgLines * 16, 80, 20, "Ok", function()
		main:ClosePopup()
	end))
	return self:OpenPopup(m_max(DrawStringWidth(16, "VAR", msg) + 30, 190), 70 + numMsgLines * 16, title, controls)
end

function main:OpenConfirmPopup(title, msg, confirmLabel, onConfirm)
	local controls = { }
	local numMsgLines = 0
	for line in string.gmatch(msg .. "\n", "([^\n]*)\n") do
		t_insert(controls, common.New("LabelControl", nil, 0, 20 + numMsgLines * 16, 0, 16, line))
		numMsgLines = numMsgLines + 1
	end
	t_insert(controls, common.New("ButtonControl", nil, -45, 40 + numMsgLines * 16, 80, 20, confirmLabel, function()
		onConfirm()
		main:ClosePopup()
	end))
	t_insert(controls, common.New("ButtonControl", nil, 45, 40 + numMsgLines * 16, 80, 20, "Cancel", function()
		main:ClosePopup()
	end))
	return self:OpenPopup(m_max(DrawStringWidth(16, "VAR", msg) + 30, 190), 70 + numMsgLines * 16, title, controls)
end

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
	for i, data in ipairs(self.tooltipLines) do
		if data.text or (self.tooltipLines[i - 1] and self.tooltipLines[i + 1] and self.tooltipLines[i + 1].text) then
			ttH = ttH + data.size + 2
		end
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
			y = y + data.size + 2
		elseif self.tooltipLines[i + 1] and self.tooltipLines[i - 1] and self.tooltipLines[i - 1].text then
			if type(col) == "string" then
				SetDrawColor(col) 
			else
				SetDrawColor(unpack(col))
			end
			DrawImage(nil, ttX + 3, y - 1 + data.size / 2, ttW - 6, 2)
			y = y + data.size + 2
		end
	end
	self.tooltipLines = wipeTable(self.tooltipLines)
end

return main