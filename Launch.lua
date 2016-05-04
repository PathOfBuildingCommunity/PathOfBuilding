#@ SimpleGraphic

SetWindowTitle("PathOfBuilding")
ConExecute("vid_mode 1")
ConExecute("vid_resizable 3")

LoadModule("Common")

local launch = { }

function launch:LoadMain()
	ConPrintf("Loading main script...")
	if self.main and self.main.Shutdown then
		PCall(self.main.Shutdown, self.main)
	end
	self.main = nil
	collectgarbage("collect")
	local errMsg
	errMsg, self.main = PLoadModule("main", launch)
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

launch:LoadMain()

SetCallback("OnFrame", function()
	if launch.main then
		if launch.main.OnFrame then
			local errMsg = PCall(launch.main.OnFrame, launch.main)
			if errMsg then
				launch:ShowErrMsg("In 'OnFrame': %s", errMsg)
			end
		end
	end
	if launch.promptMsg then
		local r, g, b = unpack(launch.promptCol)
		common.drawPopup(r, g, b, "^0%s", launch.promptMsg)
	end
	if launch.doReload then
		local screenW, screenH = GetScreenSize()
		SetDrawColor(0, 0, 0, 0.75)
		DrawImage(nil, 0, 0, screenW, screenH)
		SetDrawColor(1, 1, 1)
		DrawString(0, screenH/2, "CENTER", 24, "FIXED", "Reloading...")
		Restart()
	end
end)

SetCallback("OnKeyDown", function(key, doubleClick)
	if key == "F5" then
		launch.doReload = true
	elseif launch.promptMsg then
		local errMsg, ret = PCall(launch.promptFunc, key)
		if errMsg then
			launch:ShowErrMsg("In prompt func: %s", errMsg)
		elseif ret then
			launch.promptMsg = nil
		end
	else
		if launch.main and launch.main.OnKeyDown then
			local errMsg = PCall(launch.main.OnKeyDown, launch.main, key, doubleClick)
			if errMsg then
				launch:ShowErrMsg("In 'OnKeyDown': %s", errMsg)
			end
		end
	end
end)

SetCallback("OnKeyUp", function(key)
	if not launch.promptMsg then
		if launch.main and launch.main.OnKeyUp then
			local errMsg = PCall(launch.main.OnKeyUp, launch.main, key)
			if errMsg then
				launch:ShowErrMsg("In 'OnKeyUp': %s", errMsg)
			end
		end
	end
end)

SetCallback("OnChar", function(key)
	if launch.promptMsg then
		local errMsg, ret = PCall(launch.promptFunc, key)
		if errMsg then
			launch:ShowErrMsg("In prompt func: %s", errMsg)
		elseif ret then
			launch.promptMsg = nil
		end
	else
		if launch.main and launch.main.OnChar then
			local errMsg = PCall(launch.main.OnChar, launch.main, key)
			if errMsg then
				launch:ShowErrMsg("In 'OnChar': %s", errMsg)
			end
		end
	end
end)

SetCallback("OnExit", function()
	if launch.main and launch.main.Shutdown then
		PCall(launch.main.Shutdown, launch.main)
	end
end)