#@ SimpleGraphic
-- Dat View
--
-- Module: Launch
-- Program entry point; loads and runs the Main module within a protected environment
--

SetWindowTitle("Dat View")
ConExecute("set vid_mode 8")
ConExecute("set vid_resizable 3")

launch = { }
SetMainObject(launch)

function launch:OnInit()
	self.devMode = true
	self.subScripts = { }
	self.versionNumber = "?"
	self.versionBranch = "?"
	self.versionPlatform = "?"

	local xml = require("xml")
	local localManXML = xml.LoadXMLFile("manifest.xml") or xml.LoadXMLFile("../manifest.xml")
	if localManXML and localManXML[1].elem == "PoBVersion" then
		for _, node in ipairs(localManXML[1]) do
			if type(node) == "table" then
				if node.elem == "Version" then
					self.versionNumber = node.attrib.number
					self.versionBranch = node.attrib.branch
					self.versionPlatform = node.attrib.platform
				end
			end
		end
	end

	RenderInit()
	ConPrintf("Loading main script...")
	local errMsg
	errMsg, self.main = PLoadModule("Main", self)
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

function launch:CanExit()
	if self.main and self.main.CanExit and not self.promptMsg then
		local errMsg, ret = PCall(self.main.CanExit, self.main)
		if errMsg then
			self:ShowErrMsg("In 'CanExit': %s", errMsg)
			return false
		else
			return ret
		end
	end
	return true
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
	self.devModeAlt = self.devMode and IsKeyDown("ALT")
	SetDrawLayer(1000)
	SetViewport()
	if self.promptMsg then
		local r, g, b = unpack(self.promptCol)
		self:DrawPopup(r, g, b, "^0%s", self.promptMsg)
	end
	if self.doRestart then
		local screenW, screenH = GetScreenSize()
		SetDrawColor(0, 0, 0, 0.75)
		DrawImage(nil, 0, 0, screenW, screenH)
		SetDrawColor(1, 1, 1)
		DrawString(0, screenH/2, "CENTER", 24, "FIXED", self.doRestart)
		Restart()
	end
end

function launch:OnKeyDown(key, doubleClick)
	if key == "F5" and self.devMode then
		self.doRestart = "Restarting..."
	elseif key == "F6" and self.devMode then
		local before = collectgarbage("count")
		collectgarbage("collect")
		ConPrintf("%dkB => %dkB", before, collectgarbage("count"))
	elseif self.promptMsg then
		self:RunPromptFunc(key)
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
		self:RunPromptFunc(key)
	else
		if self.main and self.main.OnChar then
			local errMsg = PCall(self.main.OnChar, self.main, key)
			if errMsg then
				self:ShowErrMsg("In 'OnChar': %s", errMsg)
			end
		end
	end
end

function launch:OnSubCall(func, ...)
	if _G[func] then
		return _G[func](...)
	end
end

function launch:OnSubError(id, errMsg)
	if self.subScripts[id].type == "DOWNLOAD" then
		local errMsg = PCall(self.subScripts[id].callback, nil, errMsg)
		if errMsg then
			self:ShowErrMsg("In download callback: %s", errMsg)
		end
	end
	self.subScripts[id] = nil
end

function launch:OnSubFinished(id, ...)
	if self.subScripts[id].type == "CUSTOM" then
		if self.subScripts[id].callback then
			local errMsg = PCall(self.subScripts[id].callback, ...)
			if errMsg then
				self:ShowErrMsg("In subscript callback: %s", errMsg)
			end
		end
	elseif self.subScripts[id].type == "DOWNLOAD" then
		local errMsg = PCall(self.subScripts[id].callback, ...)
		if errMsg then
			self:ShowErrMsg("In download callback: %s", errMsg)
		end
	end
	self.subScripts[id] = nil
end

function launch:RegisterSubScript(id, callback)
	if id then
		self.subScripts[id] = {
			type = "CUSTOM",
			callback = callback,
		}
	end
end

function launch:ShowPrompt(r, g, b, str, func)
	self.promptMsg = str
	self.promptCol = {r, g, b}
	self.promptFunc = func or function(key)
		if key == "RETURN" or key == "ESCAPE" then
			return true
		elseif key == "F5" then
			self.doRestart = "Restarting..."
			return true
		end
	end
end

function launch:ShowErrMsg(fmt, ...)
	if not self.promptMsg then
		self:ShowPrompt(1, 0, 0, "^1Error:\n\n^0" .. string.format(fmt, ...) .. "\n\nPress Enter/Escape to Dismiss, or F5 to restart the application.")
	end
end

function launch:RunPromptFunc(key)
	local curMsg = self.promptMsg
	local errMsg, ret = PCall(self.promptFunc, key)
	if errMsg then
		self:ShowErrMsg("In prompt func: %s", errMsg)
	elseif ret and self.promptMsg == curMsg then
		self.promptMsg = nil
	end
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

---Download the given page in the background, and calls the provided callback function when done:
---@param url string
---@param callback fun(response:table, errMsg:string) @ response = { header, body }
---@param params table @ params = { header, body }
function launch:DownloadPage(url, callback, params)
	params = params or {}
	local script = [[
		local url, requestHeader, requestBody, connectionProtocol, proxyURL = ...
		local responseHeader = ""
		local responseBody = ""
		ConPrintf("Downloading page at: %s", url)
		local curl = require("lcurl.safe")
		local easy = curl.easy()
		if requestHeader then
			local header = {}
			for s in requestHeader:gmatch("[^\r\n]+") do
				table.insert(header, s)
			end
			easy:setopt(curl.OPT_HTTPHEADER, header)
		end
		easy:setopt_url(url)
		easy:setopt(curl.OPT_USERAGENT, "Path of Building/]]..self.versionNumber..[[")
		easy:setopt(curl.OPT_ACCEPT_ENCODING, "")
		if requestBody then
			easy:setopt(curl.OPT_POST, true)
			easy:setopt(curl.OPT_POSTFIELDS, requestBody)
		end
		if connectionProtocol then
			easy:setopt(curl.OPT_IPRESOLVE, connectionProtocol)
		end
		if proxyURL then
			easy:setopt(curl.OPT_PROXY, proxyURL)
		end
		easy:setopt_headerfunction(function(data)
			responseHeader = responseHeader .. data
			return true
		end)
		easy:setopt_writefunction(function(data)
			responseBody = responseBody .. data
			return true
		end)
		local _, error = easy:perform()
		local code = easy:getinfo(curl.INFO_RESPONSE_CODE)
		easy:close()
		local errMsg
		if error then
			errMsg = error:msg()
		elseif code ~= 200 then
			errMsg = "Response code: "..code
		elseif #responseBody == 0 then
			errMsg = "No data returned"
		end
		ConPrintf("Download complete. Status: %s", errMsg or "OK")
		return responseHeader, responseBody, errMsg
	]]
	local id = LaunchSubScript(script, "", "ConPrintf", url, params.header, params.body, self.connectionProtocol, self.proxyURL)
	if id then
		self.subScripts[id] = {
			type = "DOWNLOAD",
			callback = function(responseHeader, responseBody, errMsg)
				callback({header=responseHeader, body=responseBody}, errMsg)
			end
		}
	end
end