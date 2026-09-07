#@
---@diagnostic disable: lowercase-global
-- This wrapper allows the program to run headless on any OS (in theory)
-- It can be run using a standard lua interpreter, although LuaJIT is preferable

-- define global SimpleGraphic API functions. some of these have dummy function
-- bodies intended for headless use.
dofile("_SimpleGraphic.def.lua")

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
function GetVirtualScreenSize()
	return 1920, 1080
end

<<<<<<< HEAD
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
-- Callbacks
__callbackTable__ = { }

function runCallback(name, ...)
	if __callbackTable__[name] then
		return __callbackTable__[name](...)
	elseif __mainObject__ and __mainObject__[name] then
		return __mainObject__[name](__mainObject__, ...)
	end
end

dofile("Launch.lua")

-- The CI env var will be true when run from github workflows but should be false for other tools using the headless wrapper 
__mainObject__.continuousIntegrationMode = os.getenv("CI")

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

if __mainObject__.promptMsg then
	-- Something went wrong during startup
	print(__mainObject__.promptMsg)
	io.read("*l")
	return
end

-- The build module; once a build is loaded, you can find all the good stuff in here
build = __mainObject__.main.modes["BUILD"]

-- Here's some helpful helper functions to help you get started
function newBuild()
	__mainObject__.main:SetMode("BUILD", false, "Help, I'm stuck in Path of Building!")
	runCallback("OnFrame")
end
function loadBuildFromXML(xmlText, name)
	__mainObject__.main:SetMode("BUILD", false, name or "", xmlText)
	runCallback("OnFrame")
end
function loadBuildFromJSON(characterJSON)
	__mainObject__.main:SetMode("BUILD", false, "")
	runCallback("OnFrame")
	-- characterJSON could, for example, be the response from the PoE API:
	-- https://www.pathofexile.com/developer/docs/reference#characters-get
	local dkjson = require "dkjson"
	local input = dkjson.decode(characterJSON)
	local charData = build.importTab:ImportItemsAndSkills(input)
	build.importTab:ImportPassiveTreeAndJewels(input)
	-- You now have a build without a correct main skill selected, or any configuration options set
	-- Good luck!
end
