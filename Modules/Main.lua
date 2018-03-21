-- Path of Building
--
-- Module: Main
-- Main module of program.
--
local launch = ...

local ipairs = ipairs
local t_insert = table.insert
local t_remove = table.remove
local m_ceil = math.ceil
local m_floor = math.floor
local m_max = math.max
local m_min = math.min
local m_sin = math.sin
local m_cos = math.cos
local m_pi = math.pi

defaultTargetVersion = "2_6"
liveTargetVersion = "3_0"
targetVersionList = { "2_6", "3_0" }

LoadModule("Modules/Common")
LoadModule("Modules/Data", launch)
LoadModule("Modules/ModTools", launch)
LoadModule("Modules/ItemTools", launch)
LoadModule("Modules/CalcTools", launch)

LoadModule("Classes/ControlHost")

local main = common.New("ControlHost")

local classList = {
	"UndoHandler",
	"Tooltip",
	"TooltipHost",
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
	"TextListControl",
	"ListControl",
	"PathControl",
	-- Misc
	"PopupDialog",
	"Item",
	-- Mode: Build list
	"BuildListControl",
	"FolderListControl",
	-- Mode: Build
	"ModStore",
	"ModList",
	"ModDB",
	"MinionListControl",
	"ImportTab",
	"NotesTab",
	"ConfigTab",
	"TreeTab",
	"PassiveTree",
	"PassiveSpec",
	"PassiveTreeView",
	"PassiveSpecListControl",
	"SkillsTab",
	"SkillListControl",
	"GemSelectControl",
	"ItemsTab",
	"ItemSetListControl",
	"SharedItemSetListControl",
	"ItemSlotControl",
	"ItemListControl",
	"ItemDBControl",
	"SharedItemListControl",
	"CalcsTab",
	"CalcSectionControl",
	"CalcBreakdownControl",
}
for _, className in pairs(classList) do
	LoadModule("Classes/"..className, launch, main)
end

--[[if launch.devMode then
	for skillName, skill in pairs(data["3_0"].enchantments.Helmet) do
		for _, mod in ipairs(skill.ENDGAME) do
			local modList, extra = modLib.parseMod["3_0"](mod)
			if not modList or extra then
				ConPrintf("%s: '%s' '%s'", skillName, mod, extra or "")
			end
		end
	end
end]]

local tempTable1 = { }
local tempTable2 = { }

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
	self.defaultBuildPath = self.userPath.."Builds/"
	self.buildPath = self.defaultBuildPath
	MakeDir(self.buildPath)

	if launch.devMode and IsKeyDown("CTRL") then
		self.rebuildModCache = true
	else
		-- Load mod caches
		for _, targetVersion in ipairs(targetVersionList) do
			LoadModule("Data/"..targetVersion.."/ModCache", modLib.parseModCache[targetVersion])
		end
	end
	
	self.tree = { }
	for _, targetVersion in ipairs(targetVersionList) do
		self.tree[targetVersion] = common.New("PassiveTree", targetVersion)
	end

	ConPrintf("Loading item databases...")
	self.uniqueDB = { }
	self.rareDB = { }
	for _, targetVersion in ipairs(targetVersionList) do
		self.uniqueDB[targetVersion] = { list = { } }
		for type, typeList in pairs(data.uniques) do
			for _, raw in pairs(typeList) do
				local newItem = common.New("Item", targetVersion, "Rarity: Unique\n"..raw)
				if newItem.base then
					newItem:NormaliseQuality()
					self.uniqueDB[targetVersion].list[newItem.name] = newItem
				elseif launch.devMode then
					ConPrintf("Unique DB unrecognised item of type '%s':\n%s", type, raw)
				end
			end
		end
		self.rareDB[targetVersion] = { list = { } }
		for _, raw in pairs(data[targetVersion].rares) do
			local newItem = common.New("Item", targetVersion, "Rarity: Rare\n"..raw)
			if newItem.base then
				newItem:NormaliseQuality()
				if newItem.crafted then
					if newItem.base.implicit and (#newItem.modLines == 0 or newItem.modLines[1].custom) then
						newItem.implicitLines = 0
						for line in newItem.base.implicit:gmatch("[^\n]+") do
							newItem.implicitLines = newItem.implicitLines + 1
							t_insert(newItem.modLines, newItem.implicitLines, { line = line })
						end
					end
					newItem:Craft()
				end
				self.rareDB[targetVersion].list[newItem.name] = newItem
			elseif launch.devMode then
				ConPrintf("Rare DB unrecognised item:\n%s", raw)
			end
		end
	end

	if self.rebuildModCache then
		-- Update mod caches
		for _, targetVersion in ipairs(targetVersionList) do
			local out = io.open("Data/"..targetVersion.."/ModCache.lua", "w")
			out:write('local c=...')
			for line, dat in pairs(modLib.parseModCache[targetVersion]) do
				if not dat[1] or not dat[1][1] or dat[1][1].name ~= "JewelFunc" then
					out:write('c["', line:gsub("\n","\\n"), '"]={')
					if dat[1] then
						writeLuaTable(out, dat[1])
					else
						out:write('nil')
					end
					if dat[2] then
						out:write(',"', dat[2]:gsub("\n","\\n"), '"}')
					else
						out:write(',nil}')
					end
				end
			end
			out:close()
		end
	end

	self.sharedItemList = { }
	self.sharedItemSetList = { }

	self.anchorMain = common.New("Control", nil, 4, 0, 0, 0)
	self.anchorMain.y = function()
		return self.screenH - 4
	end
	self.controls.options = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 0, 0, 70, 20, "Options", function()
		self:OpenOptionsPopup()
	end)
	self.controls.patreon = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 112, 0, 74, 20, "", function()
		OpenURL("https://www.patreon.com/openarl")
	end)
	self.controls.patreon:SetImage("Assets/patreon_logo.png")
	self.controls.patreon.tooltipText = "Help support the development of Path of Building by pledging a monthly donation!"
	self.controls.about = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 228, 0, 70, 20, "About", function()
		self:OpenAboutPopup()
	end)
	self.controls.applyUpdate = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 0, -24, 140, 20, "^x50E050Update Ready", function()
		self:OpenUpdatePopup()
	end)
	self.controls.applyUpdate.shown = function()
		return launch.updateAvailable and launch.updateAvailable ~= "none"
	end
	self.controls.checkUpdate = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 0, -24, 140, 20, "", function()
		launch:CheckForUpdate()
	end)
	self.controls.checkUpdate.shown = function()
		return not launch.devMode and (not launch.updateAvailable or launch.updateAvailable == "none")
	end
	self.controls.checkUpdate.label = function()
		return launch.updateCheckRunning and launch.updateProgress or "Check for Update"
	end
	self.controls.checkUpdate.enabled = function()
		return not launch.updateCheckRunning
	end
	self.controls.versionLabel = common.New("LabelControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 144, -27, 0, 14, "")
	self.controls.versionLabel.label = function()
		return "^8Version: "..launch.versionNumber..(launch.versionBranch == "dev" and " (Dev)" or "")
	end
	self.controls.devMode = common.New("LabelControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 0, -26, 0, 20, "^1Dev Mode")
	self.controls.devMode.shown = function()
		return launch.devMode
	end
	self.controls.dismissToast = common.New("ButtonControl", {"BOTTOMLEFT",self.anchorMain,"BOTTOMLEFT"}, 0, function() return -self.mainBarHeight + self.toastHeight end, 80, 20, "Dismiss", function()
		self.toastMode = "HIDING"
		self.toastStart = GetTime()
	end)
	self.controls.dismissToast.shown = function()
		return self.toastMode == "SHOWN"
	end

	self.mainBarHeight = 58
	self.toastMessages = { }

	if launch.devMode and GetTime() >= 0 and GetTime() < 15000 then
		t_insert(self.toastMessages, [[
^xFF7700Warning: ^7Developer Mode active!
The program is currently running in developer
mode, which is not intended for normal use.
If you are not expecting this, then you may have
set up the program from the source .zip instead
of using one of the installers. If that is the case,
please reinstall using one of the installers from
the "Releases" section of the GitHub page.]])
	end

	self.inputEvents = { }
	self.popups = { }
	self.tooltipLines = { }

	self.accountSessionIDs = { }

	self.buildSortMode = "NAME"
	self.nodePowerTheme = "RED/BLUE"

	self:SetMode("BUILD", false, "Unnamed build")

	self:LoadSettings()
end

function main:CanExit()
	local ret = self:CallMode("CanExit", "EXIT")
	if ret ~= nil then
		return ret
	else
		return true
	end
end

function main:Shutdown()
	self:CallMode("Shutdown")

	self:SaveSettings()
end

function main:OnFrame()
	self.screenW, self.screenH = GetScreenSize()

	while self.newMode do
		if self.mode then
			self:CallMode("Shutdown")
		end
		self.mode = self.newMode
		self.newMode = nil
		self:CallMode("Init", unpack(self.newModeArgs))
	end

	self.viewPort = { x = 0, y = 0, width = self.screenW, height = self.screenH }

	if self.popups[1] then
		self.popups[1]:ProcessInput(self.inputEvents, self.viewPort)
		wipeTable(self.inputEvents)
	else
		self:ProcessControlsInput(self.inputEvents, self.viewPort)
	end

	self:CallMode("OnFrame", self.inputEvents, self.viewPort)

	if launch.updateErrMsg then
		t_insert(self.toastMessages, string.format("Update check failed!\n%s", launch.updateErrMsg))
		launch.updateErrMsg = nil
	end
	if launch.updateAvailable then
		if launch.updateAvailable == "none" then
			t_insert(self.toastMessages, "No update available\nYou are running the latest version.")
			launch.updateAvailable = nil
		elseif not self.updateAvailableShown then
			t_insert(self.toastMessages, "Update Available\nAn update has been downloaded and is ready\nto be applied.")
			self.updateAvailableShown = true
		end
	end

	-- Run toasts
	if self.toastMessages[1] then
		if not self.toastMode then
			self.toastMode = "SHOWING"
			self.toastStart = GetTime()
			self.toastHeight = #self.toastMessages[1]:gsub("[^\n]","") * 16 + 20 + 40
		end
		if self.toastMode == "SHOWING" then
			local now = GetTime()
			if now >= self.toastStart + 250 then
				self.toastMode = "SHOWN"
			else
				self.mainBarHeight = 58 + self.toastHeight * (now - self.toastStart) / 250
			end
		end
		if self.toastMode == "SHOWN" then
			self.mainBarHeight = 58 + self.toastHeight
		elseif self.toastMode == "HIDING" then
			local now = GetTime()
			if now >= self.toastStart + 75 then
				self.toastMode = nil
				self.mainBarHeight = 58
				t_remove(self.toastMessages, 1)
			else
				self.mainBarHeight = 58 + self.toastHeight * (1 - (now - self.toastStart) / 75)
			end
		end
		if self.toastMode then
			SetDrawColor(0.85, 0.85, 0.85)
			DrawImage(nil, 0, self.screenH - self.mainBarHeight, 312, self.mainBarHeight)
			SetDrawColor(0.1, 0.1, 0.1)
			DrawImage(nil, 0, self.screenH - self.mainBarHeight + 4, 308, self.mainBarHeight - 4)
			SetDrawColor(1, 1, 1)
			DrawString(4, self.screenH - self.mainBarHeight + 8, "LEFT", 20, "VAR", self.toastMessages[1]:gsub("\n.*",""))
			DrawString(4, self.screenH - self.mainBarHeight + 28, "LEFT", 16, "VAR", self.toastMessages[1]:gsub("^[^\n]*\n?",""))
		end
	end

	-- Draw main controls
	SetDrawColor(0.85, 0.85, 0.85)
	DrawImage(nil, 0, self.screenH - 58, 312, 58)
	SetDrawColor(0.1, 0.1, 0.1)
	DrawImage(nil, 0, self.screenH - 54, 308, 54)
	self:DrawControls(self.viewPort)

	if self.popups[1] then
		SetDrawLayer(10)
		SetDrawColor(0, 0, 0, 0.5)
		DrawImage(nil, 0, 0, self.screenW, self.screenH)
		self.popups[1]:Draw(self.viewPort)
		SetDrawLayer(0)
	end

	if self.showDragText then
		local cursorX, cursorY = GetCursorPos()
		local strWidth = DrawStringWidth(16, "VAR", self.showDragText)
		SetDrawLayer(20, 0)
		SetDrawColor(0.15, 0.15, 0.15, 0.75)
		DrawImage(nil, cursorX, cursorY - 8, strWidth + 2, 18)
		SetDrawColor(1, 1, 1)
		DrawString(cursorX + 1, cursorY - 7, "LEFT", 16, "VAR", self.showDragText)
		self.showDragText = nil
	end
	
	--[[local par = 300
	for x = 0, 750 do
		for y = 0, 750 do
			local dpsCol = (x / par * 1.5) ^ 0.5
			local defCol = (y / par * 1.5) ^ 0.5
			local mixCol = (m_max(dpsCol - 0.5, 0) + m_max(defCol - 0.5, 0)) / 2
			if main.nodePowerTheme == "RED/BLUE" then
				SetDrawColor(dpsCol, mixCol, defCol)
			elseif main.nodePowerTheme == "RED/GREEN" then
				SetDrawColor(dpsCol, defCol, mixCol)
			elseif main.nodePowerTheme == "GREEN/BLUE" then
				SetDrawColor(mixCol, dpsCol, defCol)
			end
			DrawImage(nil, x + 500, y + 200, 1, 1)
		end
	end
	SetDrawColor(0, 0, 0)
	DrawImage(nil, par + 500, 200, 2, 750)
	DrawImage(nil, 500, par + 200, 759, 2)]]

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
		return modeTbl[func](modeTbl, ...)
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
			elseif node.elem == "SharedItems" then
				for _, child in ipairs(node) do
					if child.elem == "Item" then
						local verItem = { raw = "" }
						for _, subChild in ipairs(child) do
							if type(subChild) == "string" then
								verItem.raw = subChild
							end
						end
						for _, targetVersion in ipairs(targetVersionList) do			
							verItem[targetVersion] = common.New("Item", targetVersion, verItem.raw)
						end
						t_insert(self.sharedItemList, verItem)
					elseif child.elem == "ItemSet" then
						local sharedItemSet = { title = child.attrib.title, slots = { } }
						for _, grandChild in ipairs(child) do
							if grandChild.elem == "Item" then
								local verItem = { raw = "" }
								for _, subChild in ipairs(grandChild) do
									if type(subChild) == "string" then
										verItem.raw = subChild
									end
								end
								for _, targetVersion in ipairs(targetVersionList) do			
									verItem[targetVersion] = common.New("Item", targetVersion, verItem.raw)
								end
								sharedItemSet.slots[grandChild.attrib.slotName] = verItem
							end
						end
						t_insert(self.sharedItemSetList, sharedItemSet)
					end
				end
			elseif node.elem == "Misc" then
				if node.attrib.buildSortMode then
					self.buildSortMode = node.attrib.buildSortMode
				end
				launch.proxyURL = node.attrib.proxyURL
				if node.attrib.buildPath then
					self.buildPath = node.attrib.buildPath
				end
				if node.attrib.nodePowerTheme then
					self.nodePowerTheme = node.attrib.nodePowerTheme
				end
				self.showThousandsSidebar = node.attrib.showThousandsSidebar == "true"
				self.showThousandsCalcs = node.attrib.showThousandsCalcs == "true"
			end
		end
	end
end

function main:SaveSettings()
	local setXML = { elem = "PathOfBuilding" }
	local mode = { elem = "Mode", attrib = { mode = self.mode } }
	for _, val in ipairs({ self:CallMode("GetArgs") }) do
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
	local sharedItemList = { elem = "SharedItems" }
	for _, verItem in ipairs(self.sharedItemList) do
		t_insert(sharedItemList, { elem = "Item", [1] = verItem.raw })
	end
	for _, sharedItemSet in ipairs(self.sharedItemSetList) do
		local set = { elem = "ItemSet", attrib = { title = sharedItemSet.title } }
		for slotName, verItem in pairs(sharedItemSet.slots) do
			t_insert(set, { elem = "Item", attrib = { slotName = slotName }, [1] = verItem.raw })
		end
		t_insert(sharedItemList, set)
	end
	t_insert(setXML, sharedItemList)
	t_insert(setXML, { elem = "Misc", attrib = { 
		buildSortMode = self.buildSortMode, 
		proxyURL = launch.proxyURL, 
		buildPath = (self.buildPath ~= self.defaultBuildPath and self.buildPath or nil),
		nodePowerTheme = self.nodePowerTheme,
		showThousandsSidebar = tostring(self.showThousandsSidebar),
		showThousandsCalcs = tostring(self.showThousandsCalcs),
	} })
	local res, errMsg = common.xml.SaveXMLFile(setXML, self.userPath.."Settings.xml")
	if not res then
		launch:ShowErrMsg("Error saving 'Settings.xml': %s", errMsg)
		return true
	end
end

function main:OpenOptionsPopup()
	local controls = { }
	controls.proxyType = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 150, 20, 80, 18, {
		{ label = "HTTP", scheme = "http" },
		{ label = "SOCKS", scheme = "socks5" },
	})
	controls.proxyLabel = common.New("LabelControl", {"RIGHT",controls.proxyType,"LEFT"}, -4, 0, 0, 16, "^7Proxy server:")
	controls.proxyURL = common.New("EditControl", {"LEFT",controls.proxyType,"RIGHT"}, 4, 0, 206, 18)
	if launch.proxyURL then
		local scheme, url = launch.proxyURL:match("(%w+)://(.+)")
		controls.proxyType:SelByValue(scheme, "scheme")
		controls.proxyURL:SetText(url)
	end
	controls.buildPath = common.New("EditControl", {"TOPLEFT",nil,"TOPLEFT"}, 150, 44, 290, 18)
	controls.buildPathLabel = common.New("LabelControl", {"RIGHT",controls.buildPath,"LEFT"}, -4, 0, 0, 16, "^7Build save path:")
	if self.buildPath ~= self.defaultBuildPath then
		controls.buildPath:SetText(self.buildPath)
	end
	controls.buildPath.tooltipText = "Overrides the default save location for builds.\nThe default location is: '"..self.defaultBuildPath.."'"
	controls.nodePowerTheme = common.New("DropDownControl", {"TOPLEFT",nil,"TOPLEFT"}, 150, 68, 100, 18, {
		{ label = "Red & Blue", theme = "RED/BLUE" },
		{ label = "Red & Green", theme = "RED/GREEN" },
		{ label = "Green & Blue", theme = "GREEN/BLUE" },
	}, function(index, value)
		self.nodePowerTheme = value.theme
	end)
	controls.nodePowerThemeLabel = common.New("LabelControl", {"RIGHT",controls.nodePowerTheme,"LEFT"}, -4, 0, 0, 16, "^7Node Power colours:")
	controls.nodePowerTheme.tooltipText = "Changes the colour scheme used for the node power display on the passive tree."
	controls.nodePowerTheme:SelByValue(self.nodePowerTheme, "theme")
	controls.thousandsLabel = common.New("LabelControl", {"TOPRIGHT",nil,"TOPLEFT"}, 200, 94, 0, 16, "^7Show thousands separators in:")
	controls.thousandsSidebar = common.New("CheckBoxControl", {"TOPLEFT",nil,"TOPLEFT"}, 270, 92, 20, "Sidebar:", function(state)
		self.showThousandsSidebar = state
	end)
	controls.thousandsSidebar.state = self.showThousandsSidebar
	controls.thousandsCalcs = common.New("CheckBoxControl", {"TOPLEFT",nil,"TOPLEFT"}, 370, 92, 20, "Calcs tab:", function(state)
		self.showThousandsCalcs = state
	end)
	controls.thousandsCalcs.state = self.showThousandsCalcs
	local initialNodePowerTheme = self.nodePowerTheme
	local initialThousandsSidebar = self.showThousandsSidebar
	local initialThousandsCalcs = self.showThousandsCalcs
	controls.save = common.New("ButtonControl", nil, -45, 120, 80, 20, "Save", function()
		if controls.proxyURL.buf:match("%w") then
			launch.proxyURL = controls.proxyType.list[controls.proxyType.selIndex].scheme .. "://" .. controls.proxyURL.buf
		else
			launch.proxyURL = nil
		end
		if controls.buildPath.buf:match("%S") then
			self.buildPath = controls.buildPath.buf
			if not self.buildPath:match("[\\/]$") then
				self.buildPath = self.buildPath .. "/"
			end
		else
			self.buildPath = self.defaultBuildPath
		end
		if self.mode == "LIST" then
			self.modes.LIST:BuildList()
		end
		main:ClosePopup()
	end)
	controls.cancel = common.New("ButtonControl", nil, 45, 120, 80, 20, "Cancel", function()
		self.nodePowerTheme = initialNodePowerTheme
		self.showThousandsSidebar = initialThousandsSidebar
		self.showThousandsCalcs = initialThousandsCalcs
		main:ClosePopup()
	end)
	self:OpenPopup(450, 150, "Options", controls, "save", nil, "cancel")
end

function main:OpenUpdatePopup()
	local changeList = { }
	for line in io.lines("changelog.txt") do
		local ver, date = line:match("^VERSION%[(.+)%]%[(.+)%]$")
		if ver then
			if ver == launch.versionNumber then
				break
			end
			if #changeList > 0 then
				t_insert(changeList, { height = 12 })
			end
			t_insert(changeList, { height = 20, "^7Version "..ver.." ("..date..")" })
		else
			t_insert(changeList, { height = 14, "^7"..line })
		end
	end
	local controls = { }
	controls.changeLog = common.New("TextListControl", nil, 0, 20, 780, 192, nil, changeList)
	controls.update = common.New("ButtonControl", nil, -45, 220, 80, 20, "Update", function()
		self:ClosePopup()
		local ret = self:CallMode("CanExit", "UPDATE")
		if ret == nil or ret == true then
			launch:ApplyUpdate(launch.updateAvailable)
		end
	end)
	controls.cancel = common.New("ButtonControl", nil, 45, 220, 80, 20, "Cancel", function()
		self:ClosePopup()
	end)
	controls.patreon = common.New("ButtonControl", {"BOTTOMLEFT",nil,"BOTTOMLEFT"}, 10, -10, 82, 22, "", function()
		OpenURL("https://www.patreon.com/openarl")
	end)
	controls.patreon:SetImage("Assets/patreon_logo.png")
	controls.patreon.tooltipText = "Help support the development of Path of Building by pledging a monthly donation!"
	self:OpenPopup(800, 250, "Update Available", controls)
end

function main:OpenAboutPopup()
	local changeList = { }
	for line in io.lines("changelog.txt") do
		local ver, date = line:match("^VERSION%[(.+)%]%[(.+)%]$")
		if ver then
			if #changeList > 0 then
				t_insert(changeList, { height = 10 })
			end
			t_insert(changeList, { height = 18, "^7Version "..ver.." ("..date..")" })
		else
			t_insert(changeList, { height = 12, "^7"..line })
		end
	end
	local controls = { }
	controls.close = common.New("ButtonControl", {"TOPRIGHT",nil,"TOPRIGHT"}, -10, 10, 50, 20, "Close", function()
		self:ClosePopup()
	end)
	controls.version = common.New("LabelControl", nil, 0, 18, 0, 18, "Path of Building v"..launch.versionNumber.." by Openarl")
	controls.forum = common.New("ButtonControl", nil, 0, 42, 420, 18, "Forum Thread: ^x4040FFhttps://www.pathofexile.com/forum/view-thread/1716360", function(control)
		OpenURL("https://www.pathofexile.com/forum/view-thread/1716360")
	end)
	controls.github = common.New("ButtonControl", nil, 0, 64, 340, 18, "GitHub page: ^x4040FFhttps://github.com/Openarl/PathOfBuilding", function(control)
		OpenURL("https://github.com/Openarl/PathOfBuilding")
	end)
	controls.patreon = common.New("ButtonControl", {"TOPLEFT",nil,"TOPLEFT"}, 10, 10, 82, 22, "", function()
		OpenURL("https://www.patreon.com/openarl")
	end)
	controls.patreon:SetImage("Assets/patreon_logo.png")
	controls.patreon.tooltipText = "Help support the development of Path of Building by pledging a monthly donation!"
	controls.verLabel = common.New("LabelControl", {"TOPLEFT",nil,"TOPLEFT"}, 10, 82, 0, 18, "^7Version history:")
	controls.changelog = common.New("TextListControl", nil, 0, 100, 630, 290, nil, changeList)
	self:OpenPopup(650, 400, "About", controls)
end

function main:DrawBackground(viewPort)
	SetDrawLayer(nil, -100)
	SetDrawColor(0.5, 0.5, 0.5)
	DrawImage(self.tree[defaultTargetVersion].assets.Background1.handle, viewPort.x, viewPort.y, viewPort.width, viewPort.height, 0, 0, viewPort.width / 100, viewPort.height / 100)
	SetDrawLayer(nil, 0)
end

function main:DrawArrow(x, y, width, height, dir)
	local x1 = x - width / 2
	local x2 = x + width / 2
	local xMid = (x1 + x2) / 2
	local y1 = y - height / 2
	local y2 = y + height / 2
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

function main:DrawCheckMark(x, y, size)
	size = size / 0.8
	x = x - size / 2
	y = y - size / 2
	DrawImageQuad(nil, x + size * 0.15, y + size * 0.50, x + size * 0.30, y + size * 0.45, x + size * 0.50, y + size * 0.80, x + size * 0.40, y + size * 0.90)
	DrawImageQuad(nil, x + size * 0.40, y + size * 0.90, x + size * 0.35, y + size * 0.75, x + size * 0.80, y + size * 0.10, x + size * 0.90, y + size * 0.20)
end

do
	local cos45 = m_cos(m_pi / 4)
	local cos35 = m_cos(m_pi * 0.195)
	local sin35 = m_sin(m_pi * 0.195)
	function main:WorldToScreen(x, y, z, width, height)
		-- World -> camera
		local cx = (x - y) * cos45
		local cy = -5.33 - (y + x) * cos45 * cos35 - z * sin35
		local cz = 122 + (y + x) * cos45 * sin35 - z * cos35
		-- Camera -> screen
		local sx = width * 0.5 + cx / cz * 1.27 * height
		local sy = height * 0.5 + cy / cz * 1.27 * height
		return round(sx), round(sy)
	end
end

function main:RenderCircle(x, y, width, height, oX, oY, radius)
	local minX = wipeTable(tempTable1)
	local maxX = wipeTable(tempTable2)
	local minY = height
	local maxY = 0
	for d = 0, 360, 0.15 do
		local r = d / 180 * m_pi
		local px, py = main:WorldToScreen(oX + m_sin(r) * radius, oY + m_cos(r) * radius, 0, width, height)
		if py >= 0 and py < height then
			px = m_min(width, m_max(0, px))
			minY = m_min(minY, py)
			maxY = m_max(maxY, py)
			minX[py] = m_min(minX[py] or px, px)
			maxX[py] = m_max(maxX[py] or px, px)
		end
	end
	for ly = minY, maxY do
		if minX[ly] then
			DrawImage(nil, x + minX[ly], y + ly, maxX[ly] - minX[ly] + 1, 1)
		end
	end
end

function main:RenderRing(x, y, width, height, oX, oY, radius, size)
	local lastX, lastY
	for d = 0, 360, 0.2 do
		local r = d / 180 * m_pi
		local px, py = main:WorldToScreen(oX + m_sin(r) * radius, oY + m_cos(r) * radius, 0, width, height)
		if px >= -size/2 and px < width + size/2 and py >= -size/2 and py < height + size/2 and (px ~= lastX or py ~= lastY) then
			DrawImage(nil, x + px - size/2, y + py, size, size)
			lastX, lastY = px, py
		end
	end
end

function main:StatColor(stat, base, limit)
	if limit and stat > limit then
		return colorCodes.NEGATIVE
	elseif base and stat ~= base then
		return colorCodes.MAGIC
	else
		return "^7"
	end
end

function main:MoveFolder(name, srcPath, dstPath)
	-- Create destination folder
	local res, msg = MakeDir(dstPath..name)
	if not res then
		self:OpenMessagePopup("Error", "Couldn't move '"..name.."' to '"..dstPath.."' : "..msg)
		return
	end

	-- Move subfolders
	local handle = NewFileSearch(srcPath..name.."/*", true)
	while handle do
		self:MoveFolder(handle:GetFileName(), srcPath..name.."/", dstPath..name.."/")
		if not handle:NextFile() then
			break
		end
	end

	-- Move files
	handle = NewFileSearch(srcPath..name.."/*") 
	while handle do
		local fileName = handle:GetFileName()
		local srcName = srcPath..name.."/"..fileName
		local dstName = dstPath..name.."/"..fileName
		local res, msg = os.rename(srcName, dstName)
		if not res then
			self:OpenMessagePopup("Error", "Couldn't move '"..srcName.."' to '"..dstName.."': "..msg)
			return
		end
		if not handle:NextFile() then
			break
		end		
	end

	-- Remove source folder
	local res, msg = RemoveDir(srcPath..name)
	if not res then
		self:OpenMessagePopup("Error", "Couldn't delete '"..dstPath..name.."' : "..msg)
		return
	end
end

function main:CopyFolder(srcName, dstName)
	-- Create destination folder
	local res, msg = MakeDir(dstName)
	if not res then
		self:OpenMessagePopup("Error", "Couldn't copy '"..srcName.."' to '"..dstName.."' : "..msg)
		return
	end

	-- Copy subfolders
	local handle = NewFileSearch(srcName.."/*", true)
	while handle do
		local fileName = handle:GetFileName()
		self:CopyFolder(srcName.."/"..fileName, dstName.."/"..fileName)
		if not handle:NextFile() then
			break
		end
	end

	-- Copy files
	handle = NewFileSearch(srcName.."/*") 
	while handle do
		local fileName = handle:GetFileName()
		local srcName = srcName.."/"..fileName
		local dstName = dstName.."/"..fileName
		local res, msg = copyFile(srcName, dstName)
		if not res then
			self:OpenMessagePopup("Error", "Couldn't copy '"..srcName.."' to '"..dstName.."': "..msg)
			return
		end
		if not handle:NextFile() then
			break
		end		
	end
end

function main:OpenPopup(width, height, title, controls, enterControl, defaultControl, escapeControl)
	local popup = common.New("PopupDialog", width, height, title, controls, enterControl, defaultControl, escapeControl)
	t_insert(self.popups, 1, popup)
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
	controls.close = common.New("ButtonControl", nil, 0, 40 + numMsgLines * 16, 80, 20, "Ok", function()
		main:ClosePopup()
	end)
	return self:OpenPopup(m_max(DrawStringWidth(16, "VAR", msg) + 30, 190), 70 + numMsgLines * 16, title, controls, "close")
end

function main:OpenConfirmPopup(title, msg, confirmLabel, onConfirm)
	local controls = { }
	local numMsgLines = 0
	for line in string.gmatch(msg .. "\n", "([^\n]*)\n") do
		t_insert(controls, common.New("LabelControl", nil, 0, 20 + numMsgLines * 16, 0, 16, line))
		numMsgLines = numMsgLines + 1
	end
	local confirmWidth = m_max(80, DrawStringWidth(16, "VAR", confirmLabel) + 10)
	controls.confirm = common.New("ButtonControl", nil, -5 - m_ceil(confirmWidth/2), 40 + numMsgLines * 16, confirmWidth, 20, confirmLabel, function()
		main:ClosePopup()
		onConfirm()
	end)
	t_insert(controls, common.New("ButtonControl", nil, 5 + m_ceil(confirmWidth/2), 40 + numMsgLines * 16, confirmWidth, 20, "Cancel", function()
		main:ClosePopup()
	end))
	return self:OpenPopup(m_max(DrawStringWidth(16, "VAR", msg) + 30, 190), 70 + numMsgLines * 16, title, controls, "confirm")
end

function main:OpenNewFolderPopup(path, onClose)
	local controls = { }
	controls.label = common.New("LabelControl", nil, 0, 20, 0, 16, "^7Enter folder name:")
	controls.edit = common.New("EditControl", nil, 0, 40, 350, 20, nil, nil, "\\/:%*%?\"<>|%c", 100, function(buf)
		controls.create.enabled = buf:match("%S")
	end)
	controls.create = common.New("ButtonControl", nil, -45, 70, 80, 20, "Create", function()
		local newFolderName = controls.edit.buf
		local res, msg = MakeDir(path..newFolderName)
		if not res then
			main:OpenMessagePopup("Error", "Couldn't create '"..newFolderName.."': "..msg)
			return
		end
		if onClose then
			onClose(newFolderName)
		end
		main:ClosePopup()
	end)
	controls.create.enabled = false
	controls.cancel = common.New("ButtonControl", nil, 45, 70, 80, 20, "Cancel", function()
		if onClose then
			onClose()
		end
		main:ClosePopup()
	end)
	main:OpenPopup(370, 100, "New Folder", controls, "create", "edit", "cancel")	
end

do
	local wrapTable = { }
	function main:WrapString(str, height, width)
		wipeTable(wrapTable)
		local lineStart = 1
		local lastSpace, lastBreak
		while true do
			local s, e = str:find("%s+", lastSpace)
			if not s then
				s = #str + 1
				e = #str + 1
			end
			if DrawStringWidth(height, "VAR", str:sub(lineStart, s - 1)) > width then
				t_insert(wrapTable, str:sub(lineStart, lastBreak))
				lineStart = lastSpace
			end
			if s > #str then
				t_insert(wrapTable, str:sub(lineStart, -1))
				break
			end
			lastBreak = s - 1
			lastSpace = e + 1
		end
		return wrapTable
	end
end

return main