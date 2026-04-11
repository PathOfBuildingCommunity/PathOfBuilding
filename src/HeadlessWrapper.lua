#@
-- This wrapper allows the program to run headless on any OS (in theory)
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
function RenderInit(flag, ...) end
function GetScreenSize()
	return 1920, 1080
end
function GetScreenScale()
	return 1
end
function GetDPIScaleOverridePercent()
	return 1
end
function SetDPIScaleOverridePercent(scale) end
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

-- [PoEW Patch] Basic file search for headless mode
-- Supports exact paths and simple glob patterns (e.g. "*.part*")
do
	local function matchGlob(filename, pattern)
		local luaPat = pattern:gsub("%.", "%%."):gsub("%*", ".*")
		return filename:match("^" .. luaPat .. "$") ~= nil
	end

	local IS_WINDOWS = package.config:sub(1,1) == "\\"

	local function listDir(dir)
		local files = {}
		local cmd
		if IS_WINDOWS then
			cmd = 'dir /b "' .. dir:gsub("/", "\\") .. '" 2>nul'
		else
			cmd = 'ls -1 "' .. dir .. '" 2>/dev/null'
		end
		local handle = io.popen(cmd)
		if handle then
			for line in handle:lines() do
				line = line:gsub("%s+$", "") -- trim trailing \r on Windows
				if line ~= "" then
					files[#files + 1] = line
				end
			end
			handle:close()
		end
		return files
	end

	local fileSearchClass = {}
	fileSearchClass.__index = fileSearchClass

	function fileSearchClass:GetFileName()
		return self.files[self.index]
	end

	function fileSearchClass:GetFileModifiedTime()
		-- Return a fixed timestamp; the .bin cache check will just re-extract
		return 0
	end

	function fileSearchClass:NextFile()
		self.index = self.index + 1
		return self.index <= #self.files
	end

	function NewFileSearch(pattern)
		if not pattern or pattern == "" then return nil end
		local dir = pattern:gsub("[/\\][^/\\]*$", "")
		local filePattern = pattern:gsub(".*[/\\]", "")

		if not filePattern:find("[%*%?]") then
			-- Exact path — just check existence
			local f = io.open(pattern, "r")
			if not f then return nil end
			f:close()
			local obj = setmetatable({ files = { filePattern }, index = 1, dir = dir }, fileSearchClass)
			return obj
		end

		-- Glob pattern — list directory and filter
		local entries = listDir(dir)
		local matched = {}
		for _, name in ipairs(entries) do
			if matchGlob(name, filePattern) then
				matched[#matched + 1] = name
			end
		end
		table.sort(matched)
		if #matched == 0 then return nil end
		return setmetatable({ files = matched, index = 1, dir = dir }, fileSearchClass)
	end
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
-- [PoEW Patch] Inflate/Deflate via LuaJIT FFI + system zlib
do
	local ok, ffi = pcall(require, "ffi")
	if ok and ffi then
		ffi.cdef[[
			unsigned long compressBound(unsigned long sourceLen);
			int compress2(uint8_t *dest, unsigned long *destLen,
			              const uint8_t *source, unsigned long sourceLen, int level);
			int uncompress(uint8_t *dest, unsigned long *destLen,
			               const uint8_t *source, unsigned long sourceLen);
		]]
		local zlib
		-- Try loading zlib from common locations (Windows, Linux, macOS)
		local libs = { "zlib1", "z", "libz.so.1", "libz.1.dylib" }
		for _, name in ipairs(libs) do
			local lok, lib = pcall(ffi.load, name)
			if lok then zlib = lib; break end
		end
		if zlib then
			function Deflate(data)
				if not data or #data == 0 then return "" end
				local srcLen = #data
				local bound = zlib.compressBound(srcLen)
				local buf = ffi.new("uint8_t[?]", bound)
				local destLen = ffi.new("unsigned long[1]", bound)
				local ret = zlib.compress2(buf, destLen, data, srcLen, 9)
				if ret ~= 0 then return "" end
				return ffi.string(buf, destLen[0])
			end
			function Inflate(data)
				if not data or #data == 0 then return "" end
				local srcLen = #data
				-- Try progressively larger buffers (data can expand 10-50x)
				for mult = 10, 100, 10 do
					local destSize = srcLen * mult
					local buf = ffi.new("uint8_t[?]", destSize)
					local destLen = ffi.new("unsigned long[1]", destSize)
					local ret = zlib.uncompress(buf, destLen, data, srcLen)
					if ret == 0 then
						return ffi.string(buf, destLen[0])
					end
					-- ret == -5 means buffer too small, try larger
					if ret ~= -5 then return "" end
				end
				return ""
			end
			print("zlib loaded via FFI — Inflate/Deflate available")
		else
			print("WARNING: zlib not found — timeless jewel data unavailable")
			function Deflate(data) return "" end
			function Inflate(data) return "" end
		end
	else
		function Deflate(data) return "" end
		function Inflate(data) return "" end
	end
end
function GetTime()
	return 0
end
-- [PoEW Patch] Return actual paths for data file resolution
function GetScriptPath()
	return _G.POB_SCRIPT_DIR or "."
end
function GetRuntimePath()
	local base = _G.POB_SCRIPT_DIR or "."
	return base .. "/../runtime"
end
function GetUserPath()
	return _G.POB_SCRIPT_DIR or "."
end
function GetWorkDir()
	return _G.POB_SCRIPT_DIR or ""
end
function MakeDir(path) end
function RemoveDir(path) end
function SetWorkDir(path) end
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
function TakeScreenshot() end

---@return string? provider
---@return string? version
---@return number? status
function GetCloudProvider(fullPath)
	return nil, nil, nil
end



-- [PoEW Patch] Determine script directory for robust path resolution
-- Uses debug.getinfo instead of io.popen('pwd') for cross-platform support
local function _poew_get_script_dir()
  local info = debug and debug.getinfo and debug.getinfo(1, 'S')
  local src = info and info.source or ''
  if type(src) == 'string' and src:sub(1,1) == '@' then
    local path = src:sub(2)
    local dir = (path:gsub('[^/\\]+$', '')):gsub('[/\\]$', '')
    if dir ~= '' then return dir end
  end
  -- Fallback: probe for known files
  local probes = { '.', 'src' }
  for _, d in ipairs(probes) do
    local fh = io.open(d .. '/HeadlessWrapper.lua', 'r')
    if fh then fh:close(); return d end
  end
  return '.'
end
_G.POB_SCRIPT_DIR = _poew_get_script_dir()

local l_require = require
function require(name)
	-- Hack to stop it looking for lcurl, which we don't really need
	if name == "lcurl.safe" then
		return
	end
	-- [PoEW Patch] UTF-8 fallback for headless mode (no native .so on macOS)
	if name == "lua-utf8" then
		local ok, mod = pcall(l_require, name)
		if ok and type(mod) == 'table' then return mod end
		local dir = _G.POB_SCRIPT_DIR or '.'
		local fok, fmod = pcall(dofile, dir .. '/lua-utf8.lua')
		if fok and type(fmod) == 'table' then return fmod end
		return {}
	end
	return l_require(name)
end


-- [PoEW Patch] Add runtime Lua libraries to package.path
local base = _G.POB_SCRIPT_DIR or "."
local runtimeLua = base .. "/../runtime/lua"
local testPath = runtimeLua .. "/xml.lua"
local fh = io.open(testPath, "r")
if fh then
	fh:close()
	package.path = runtimeLua .. "/?.lua;" .. runtimeLua .. "/?/init.lua;" .. package.path
end

dofile("Launch.lua")

-- Prevents loading of ModCache
-- Allows running mod parsing related tests without pushing ModCache
-- The CI env var will be true when run from github workflows but should be false for other tools using the headless wrapper 
mainObject.continuousIntegrationMode = os.getenv("CI")

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

-- [PoEW Patch] CLI flag detection
local function _poew_has_flag(flag)
	if type(arg) ~= 'table' then return false end
	for i = 1, #arg do if arg[i] == flag then return true end end
	return false
end

-- [PoEW Patch] JSON-RPC API server activation (env-gated)
-- Set POB_API_STDIO=1 or pass --stdio to start the API server
if os.getenv('POB_API_STDIO') == '1' or _poew_has_flag('--stdio') then
	local srvPath = (_G.POB_SCRIPT_DIR or '.') .. '/API/Server.lua'
	dofile(srvPath)
	return
end
