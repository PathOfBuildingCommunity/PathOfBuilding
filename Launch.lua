#@ SimpleGraphic
-- Path of Building
--
-- Module: Launch
-- Program entry point; loads and runs the Main module within a protected environment
--

SetWindowTitle("PathOfBuilding")
ConExecute("set vid_mode 1")
ConExecute("set vid_resizable 3")

local opFile = io.open("Update/opFile.txt", "r")
if opFile then
	-- Update is pending, apply it
	opFile:close()
	LoadModule("Update")
end

local launch = { }
SetMainObject(launch)

function launch:ApplyUpdate(mode)
	if mode == "basic" then
		-- Need to revert to the basic environment to apply the update
		os.execute("PathOfBuilding Update.lua")
		Exit()
	elseif mode == "normal" then
		-- Update can be applied while normal environment is running
		Restart()
	end
end

function launch:OnInit()
	ConPrintf("Loading main script...")
	local mainFile = io.open("Modules/Main.lua")
	if mainFile then
		mainFile:close()
	else
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
	end
	if self.doReload then
		local screenW, screenH = GetScreenSize()
		SetDrawColor(0, 0, 0, 0.75)
		DrawImage(nil, 0, 0, screenW, screenH)
		SetDrawColor(1, 1, 1)
		DrawString(0, screenH/2, "CENTER", 24, "FIXED", "Reloading...")
		Restart()
	end
end

function launch:OnKeyDown(key, doubleClick)
	if key == "F5" then
		self.doReload = true
	elseif self.promptMsg then
		local errMsg, ret = PCall(self.promptFunc, key)
		if errMsg then
			self:ShowErrMsg("In prompt func: %s", errMsg)
		elseif ret then
			self.promptMsg = nil
		end
	else
		if self.main and self.main.OnKeyDown then
			local errMsg = PCall(self.main.OnKeyDown, self.main, key, doubleClick)
			if errMsg then
				self:ShowErrMsg("In 'OnKeyDown': %s", errMsg)
			end
		end
	end
end

function launch:OnKeyUp(key)
	if not self.promptMsg then
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
	else
		if self.main and self.main.OnChar then
			local errMsg = PCall(self.main.OnChar, self.main, key)
			if errMsg then
				self:ShowErrMsg("In 'OnChar': %s", errMsg)
			end
		end
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
	self:ShowPrompt(1, 0, 0, "^1Error:\n\n^0" .. string.format(fmt, ...) .. "\n\nEnter/Escape to Dismiss, F5 to reload scripts", function(key)
		if key == "RETURN" or key == "ESCAPE" then
			return true
		end
	end)
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
