#@
-- This wrapper allows the program to run headless
-- It can be run using a standard lua interpreter, although LuaJIT is preferable


-- Callbacks
local callbackTable = { }
local mainObject
function runCallback(name, ...)
	if callbackTable[name] then
		return callbackTable[name](...)
	elseif mainObject and mainObject[name] then
		return mainObject[name](mainObject, ...)
	end
end
function SetCallback(name, func)
	callbackTable[name] = func
end
function GetCallback(name)
	return callbackTable[name]
end
function SetMainObject(obj)
	mainObject = obj
end

-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
function splitLines(s)
	if s:sub(-1)~="\n" then s=s.."\n" end
	return s:gmatch("(.-)\n")
end

-- Image Handles
local imageHandleClass = { }
imageHandleClass.__index = imageHandleClass
function NewImageHandle()
	return setmetatable({ }, imageHandleClass)
end
function imageHandleClass:Load(fileName, ...)
	self.valid = true
end
function imageHandleClass:Unload()
	self.valid = false
end
function imageHandleClass:IsValid()
	return self.valid
end
function imageHandleClass:SetLoadingPriority(pri) end
function imageHandleClass:ImageSize()
	return 1, 1
end

-- Rendering
function RenderInit() end
function GetScreenSize()
	return 1920, 1080
end
function SetClearColor(r, g, b, a) end
function SetDrawLayer(layer, subLayer) end
function SetViewport(x, y, width, height) end
function SetDrawColor(r, g, b, a) end
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom) end
function DrawImageQuad(imageHandle, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4) end
function DrawString(left, top, align, height, font, text) end
function DrawStringWidth(height, font, text)
	return 1
end
function DrawStringCursorIndex(height, font, text, cursorX, cursorY)
	return 0
end
function StripEscapes(text)
	return text:gsub("%^%d",""):gsub("%^x%x%x%x%x%x%x","")
end
function GetAsyncCount()
	return 0
end

posix = require("posix")

-- Search Handles
function NewFileSearch(path)
	local paths = posix.glob(path)
	local currentPath = 1
	return paths and {GetFileName = function() 
				return posix.basename(paths[currentPath])
			end,
			GetFileModifiedTime = function() 
				return posix.lstat(paths[currentPath]).st_mtime
			end,
			GetFileSize = function()
				return posix.lstat(paths[currentPath]).st_size
			end,
			NextFile = function()
				currentPath = currentPath + 1
				return paths[currentPath] 
			end}
end

-- General Functions
function SetWindowTitle(title) end
function GetCursorPos()
	return 0, 0
end
function SetCursorPos(x, y) end
function ShowCursor(doShow) end
function IsKeyDown(keyName) end
function Copy(text) end
function Paste() end

require "zlib"
function Deflate(data)
	return zlib.deflate()(data)
end
function Inflate(data)
	return zlib.inflate()(data)
end
function GetTime()
	-- os.clock returns cpu time as float in seconds
	-- SG GetTime https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic/blob/166d251eefa6bf96ee5f6cd022d08410b7023283/engine/system/win/sys_main.cpp#L541
	return os.clock() * 1000
end
function GetScriptPath()
	return os.getenv("PWD") .. "/src"
end
function GetRuntimePath()
	return ""
end
function GetUserPath()
	return os.getenv("HOME")
end
function MakeDir(path) end
function RemoveDir(path) end
function SetWorkDir(path) end
function GetWorkDir()
	return os.getenv("PWD")
end
function LaunchSubScript(scriptText, funcList, subList, ...) end
function AbortSubScript(ssID) end
function IsSubScriptRunning(ssID) end
function LoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return func(...)
	else
		error("LoadModule() error loading '"..fileName.."': "..err)
	end
end
function PLoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return PCall(func, ...)
	else
		error("PLoadModule() error loading '"..fileName.."': "..err)
	end
end
function PCall(func, ...)
	local ret = { pcall(func, ...) }
	if ret[1] then
		table.remove(ret, 1)
		return nil, unpack(ret)
	else
		return ret[2]
	end	
end
function ConPrintf(fmt, ...)
	-- Optional
	print(string.format(fmt, ...))
end
function ConPrintTable(tbl, noRecurse) end
function ConExecute(cmd) end
function ConClear() end
function SpawnProcess(cmdName, args) end
function OpenURL(url) end
function SetProfiling(isEnabled) end
function Restart() end
function Exit() end

dofile("Launch.lua")

-- The CI env var will be true when run from github workflows but should be false for other tools using the headless wrapper 
mainObject.continuousIntegrationMode = os.getenv("CI")

function launch:DownloadPage(url, callback, params)
	params = params or {}
	local responseHeader = ""
	local responseBody = ""
	ConPrintf("Downloading page at: %s", url)
	local curl = require("lcurl.safe")
	local easy = curl.easy()
	if params.header then
		local header = {}
		for s in params.header:gmatch("[^\r\n]+") do
    		table.insert(header, s)
		end
		easy:setopt(curl.OPT_HTTPHEADER, header)
	end
	easy:setopt_url(url)
	easy:setopt(curl.OPT_USERAGENT, "Headless Path of Building" .. (mainObject.continuousIntegrationMode and " CI" or "") .. "/"..launch.versionNumber)
	easy:setopt(curl.OPT_ACCEPT_ENCODING, "")
	if params.body then
		easy:setopt(curl.OPT_POST, true)
		easy:setopt(curl.OPT_POSTFIELDS, params.body)
	end
	if params.connectionProtocol or self.connectionProtocol  then
		easy:setopt(curl.OPT_IPRESOLVE, params.connectionProtocol or self.connectionProtocol)
	end
	if params.proxyURL or self.proxyURL then
		easy:setopt(curl.OPT_PROXY, params.proxyURL or self.proxyURL)
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
	callback({header=responseHeader, body=responseBody}, errMsg)
end

runCallback("OnInit")
runCallback("OnFrame") -- Need at least one frame for everything to initialise

if mainObject.promptMsg then
	-- Something went wrong during startup
	print(mainObject.promptMsg)
	io.read("*l")
	return
end

-- The build module; once a build is loaded, you can find all the good stuff in here
build = mainObject.main.modes["BUILD"]

-- Here's some helpful helper functions to help you get started
function newBuild()
	mainObject.main:SetMode("BUILD", false, "Help, I'm stuck in Path of Building!")
	runCallback("OnFrame")
end
function loadBuildFromXML(xmlText, name)
	mainObject.main:SetMode("BUILD", false, name or "", xmlText)
	runCallback("OnFrame")
end
function loadBuildFromJSON(getItemsJSON, getPassiveSkillsJSON)
	mainObject.main:SetMode("BUILD", false, "")
	runCallback("OnFrame")
	local charData = build.importTab:ImportItemsAndSkills(getItemsJSON)
	build.importTab:ImportPassiveTreeAndJewels(getPassiveSkillsJSON, charData)
	-- You now have a build without a correct main skill selected, or any configuration options set
	-- Good luck!
end
