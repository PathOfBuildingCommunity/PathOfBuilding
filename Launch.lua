#@ SimpleGraphic
-- Path of Building
--
-- Module: Launch
-- Program entry point; loads and runs the Main module within a protected environment
--

SetWindowTitle("PathOfBuilding")
ConExecute("set vid_mode 1")
ConExecute("set vid_resizable 3")

local launch = { }
SetMainObject(launch)

function launch:OnInit()
	if GetScriptPath() ~= GetRuntimePath() then
		-- We are running from an external runtime
		-- Force developer mode to disable update checks
		self.devMode = true
	end
	ConPrintf("Loading main script...")
	local mainFile = io.open("Modules/Main.lua")
	if mainFile then
		mainFile:close()
	else
		ConClear()
		ConPrintf("Please wait while we complete installation...\n")
		local updateMode = LoadModule("Update", "CHECK")
		if not updateMode or updateMode == "none" then
			Exit("Failed to install.")
		else
			self:ApplyUpdate(updateMode)
		end
		return
	end
	local errMsg
	errMsg, self.main = PLoadModule("Modules/Main", self)
	if errMsg then
		self:ShowErrMsg("Error loading main script: %s", errMsg)
	elseif not self.main then
		self:ShowErrMsg("Error loading main script: no object returned")
	elseif self.main.Init then
		errMsg = PCall(self.main.Init, self.main)
		if errMsg then
			self:ShowErrMsg("In 'Init': %s", errMsg)
		end
	end
	if not self.devMode then
		-- Run a background update check if developer mode is off
		self:CheckForUpdate(true)
	end
end

function launch:OnExit()
	if self.main and self.main.Shutdown then
		PCall(self.main.Shutdown, self.main)
	end
end

function launch:OnFrame()
	if self.main then
		if self.main.OnFrame then
			local errMsg = PCall(self.main.OnFrame, self.main)
			if errMsg then
				self:ShowErrMsg("In 'OnFrame': %s", errMsg)
			end
		end
	end
	if self.promptMsg then
		local r, g, b = unpack(self.promptCol)
		self:DrawPopup(r, g, b, "^0%s", self.promptMsg)
	elseif self.updateChecking then
		self:DrawPopup(0, 0.5, 0, "^0%s", self.updateMsg)
	end
	if self.doRestart then
		local screenW, screenH = GetScreenSize()
		SetDrawColor(0, 0, 0, 0.75)
		DrawImage(nil, 0, 0, screenW, screenH)
		SetDrawColor(1, 1, 1)
		DrawString(0, screenH/2, "CENTER", 24, "FIXED", "Restarting...")
		Restart()
	end
end

function launch:OnKeyDown(key, doubleClick)
	if key == "F5" then
		self.doRestart = true
	elseif key == "u" and IsKeyDown("CTRL") then
		if not self.devMode then
			self:CheckForUpdate()
		end
	elseif self.promptMsg then
		local errMsg, ret = PCall(self.promptFunc, key)
		if errMsg then
			self:ShowErrMsg("In prompt func: %s", errMsg)
		elseif ret then
			self.promptMsg = nil
		end
	elseif not self.updateChecking then
		if self.main and self.main.OnKeyDown then
			local errMsg = PCall(self.main.OnKeyDown, self.main, key, doubleClick)
			if errMsg then
				self:ShowErrMsg("In 'OnKeyDown': %s", errMsg)
			end
		end
	end
end

function launch:OnKeyUp(key)
	if not self.promptMsg and not self.updateChecking then
		if self.main and self.main.OnKeyUp then
			local errMsg = PCall(self.main.OnKeyUp, self.main, key)
			if errMsg then
				self:ShowErrMsg("In 'OnKeyUp': %s", errMsg)
			end
		end
	end
end

function launch:OnChar(key)
	if self.promptMsg then
		local errMsg, ret = PCall(self.promptFunc, key)
		if errMsg then
			self:ShowErrMsg("In prompt func: %s", errMsg)
		elseif ret then
			self.promptMsg = nil
		end
	elseif not self.updateChecking then
		if self.main and self.main.OnChar then
			local errMsg = PCall(self.main.OnChar, self.main, key)
			if errMsg then
				self:ShowErrMsg("In 'OnChar': %s", errMsg)
			end
		end
	end
end

function launch:OnSubCall(func, ...)
	if func == "ConPrintf" then
		self.updateMsg = string.format(...)
	end
	if _G[func] then
		return _G[func](...)
	end
end

function launch:OnSubFinished(ret)
	self.updateAvailable = ret	
	if not ret then
		self:ShowPrompt(1, 0, 0, self.updateMsg .. "\n\nEnter/Escape to dismiss")
	elseif self.updateChecking then
		if ret == "none" then
			self:ShowPrompt(0, 0, 0, "No update available.", function(key) return true end)
		else
			self:ShowPrompt(0.2, 0.8, 0.2, "An update has been downloaded.\n\nClick 'Apply Update' at the top right when you are ready.", function(key) return true end)
		end
		self.updateChecking = false
	end
end

function launch:ApplyUpdate(mode)
	if mode == "basic" then
		-- Need to revert to the basic environment to apply the update
		os.execute("start PathOfBuilding Update.lua")
		Exit()
	elseif mode == "normal" then
		-- Update can be applied while normal environment is running
		LoadModule("Update")
		Restart()
		self.doRestart = true -- Will show "Restarting" message if main window is open
	end
end

function launch:CheckForUpdate(inBackground)
	if not IsSubScriptRunning() then
		self.updateChecking = not inBackground
		self.updateMsg = ""
		local update = io.open("Update.lua", "r")
		LaunchSubScript(update:read("*a"), "GetWorkDir,MakeDir", "ConPrintf", "CHECK")
		update:close()
	end
end

function launch:ShowPrompt(r, g, b, str, func)
	if self.promptMsg then
		return
	end
	self.promptMsg = str
	self.promptCol = {r, g, b}
	self.promptFunc = func or function(key)
		if key == "RETURN" or key == "ESCAPE" then
			return true
		end
	end
end

function launch:ShowErrMsg(fmt, ...)
	self:ShowPrompt(1, 0, 0, "^1Error:\n\n^0" .. string.format(fmt, ...) .. "\n\nEnter/Escape to Dismiss, F5 to reload scripts")
end

function launch:DrawPopup(r, g, b, fmt, ...)
	local screenW, screenH = GetScreenSize()
	SetDrawColor(0, 0, 0, 0.5)
	DrawImage(nil, 0, 0, screenW, screenH)
	local txt = string.format(fmt, ...)
	local w = DrawStringWidth(20, "VAR", txt) + 20
	local h = (#txt:gsub("[^\n]","") + 2) * 20
	local ox = (screenW - w) / 2
	local oy = (screenH - h) / 2
	SetDrawColor(1, 1, 1)
	DrawImage(nil, ox, oy, w, h)
	SetDrawColor(r, g, b)
	DrawImage(nil, ox + 2, oy + 2, w - 4, h - 4)
	SetDrawColor(1, 1, 1)
	DrawImage(nil, ox + 4, oy + 4, w - 8, h - 8)
	DrawString(0, oy + 10, "CENTER", 20, "VAR", txt)
end
