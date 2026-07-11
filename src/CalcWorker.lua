#@
-- Path of Building
--
-- Module: Calc Worker
-- Background calculation worker, launched via LaunchSubScript by Modules/ParallelRunner.
-- Runs in an isolated Lua VM on its own thread: bootstraps a headless copy of the
-- program (modelled on HeadlessWrapper.lua), reconstructs the build from an XML
-- snapshot, computes the requested batch of candidates, and returns a JSON string.
--
-- Available in this VM: the Lua standard library, require() for bundled binary/lua
-- modules, plus engine functions injected via funcList (GetScriptPath etc.) and
-- main-thread callbacks via subList (ConPrintf, ParallelWorkerProgress).

local jobId, workerIdx, scriptPath, workerMode, buildXML, auxText, specJSON = ...

-- Keep any engine-injected functions before defining stubs
local engineScriptPath = GetScriptPath
local engineRuntimePath = GetRuntimePath
local engineUserPath = GetUserPath
local engineWorkDir = GetWorkDir
local engineConPrintf = ConPrintf
local engineNewFileSearch = NewFileSearch
local engineInflate = Inflate
local engineDeflate = Deflate

-- Millisecond timer; on Windows os.clock() is wall time, which is all we need
-- for timing telemetry and the calc engine's internal pacing checks
local osClock = os.clock
local function nowMs()
	return osClock() * 1000
end

-- JSON codec, needed both for the work spec and to report errors; loaded before
-- anything else so failures later on can still be serialized
local dkjson
do
	local ok, mod = pcall(require, "dkjson")
	if ok and mod then
		dkjson = mod
	else
		local candidates = { }
		if engineRuntimePath then
			candidates[#candidates + 1] = engineRuntimePath().."/lua/dkjson.lua"
		end
		candidates[#candidates + 1] = scriptPath.."/../runtime/lua/dkjson.lua"
		for _, path in ipairs(candidates) do
			local func = loadfile(path)
			if func then
				dkjson = func()
				break
			end
		end
	end
	if not dkjson then
		error("CalcWorker: unable to load dkjson")
	end
end

------------------------------------------------------------------------------
-- Headless environment stubs (hardened copy of HeadlessWrapper.lua)
------------------------------------------------------------------------------

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
function GetVirtualScreenSize()
	return GetScreenSize()
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

-- Search Handles; prefer the engine implementation if this VM has one.
-- The stub returning nil makes data loaders (e.g. timeless jewel LUTs) fall
-- back to reading .bin caches directly — they must NOT get fake handles
NewFileSearch = engineNewFileSearch or function() end

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
-- Prefer the engine implementations if this VM has them. The stubs return nil
-- (NOT "") so callers treat compression as unavailable instead of caching
-- empty data — an empty string here once poisoned the shared timeless jewel
-- .bin cache on disk
Deflate = engineDeflate or function(data)
	return nil
end
Inflate = engineInflate or function(data)
	return nil
end
function GetTime()
	return nowMs()
end
-- Prefer real engine paths where they were injected; fall back to the path the
-- main thread passed as an argument
GetScriptPath = engineScriptPath or function()
	return scriptPath
end
GetRuntimePath = engineRuntimePath or function()
	return scriptPath.."/../runtime"
end
GetUserPath = engineUserPath or function()
	return ""
end
GetWorkDir = engineWorkDir or function()
	return ""
end
function GetCloudProvider(fullPath)
	return nil, nil, nil
end
function MakeDir(path) end
function RemoveDir(path) end
function SetWorkDir(path) end
-- Workers may not spawn further workers
function LaunchSubScript(scriptText, funcList, subList, ...) end
function AbortSubScript(ssID) end
function IsSubScriptRunning(ssID) end
function LoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if not func then
		-- The worker thread's working directory may not be the script path;
		-- retry with an absolute path
		func, err = loadfile(GetScriptPath().."/"..fileName)
	end
	if func then
		return func(...)
	else
		error("LoadModule() error loading '"..fileName.."': "..err)
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
function PLoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if not func then
		func, err = loadfile(GetScriptPath().."/"..fileName)
	end
	if func then
		return PCall(func, ...)
	else
		error("PLoadModule() error loading '"..fileName.."': "..err)
	end
end
-- ConPrintf is normally marshalled to the main thread via subList; keep a
-- local fallback in case it wasn't injected
ConPrintf = ConPrintf or function(fmt, ...)
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

-- Launch.lua indexes these at load time
arg = arg or { }
jit = jit or { opt = { start = function() end } }

local l_require = require
function require(name)
	-- Don't hard-fail if lcurl isn't loadable in this VM; nothing that runs in
	-- a worker actually performs HTTP requests
	if name == "lcurl.safe" then
		local ok, mod = pcall(l_require, name)
		return ok and mod or nil
	end
	return l_require(name)
end

-- Relative paths resolve against the process working directory, which is only
-- guaranteed to be the script path for the main thread. Resolve relative opens
-- against the script path first so file access behaves like the main thread
-- (e.g. "TreeData/<version>/tree.lua" in PassiveTree).
local l_ioOpen = io.open
local function isRelativePath(fileName)
	return type(fileName) == "string" and not fileName:match("^%a:[/\\]") and not fileName:match("^[/\\]")
end
function io.open(fileName, ...)
	if isRelativePath(fileName) then
		local file = l_ioOpen(scriptPath.."/"..fileName, ...)
		if file then
			return file
		end
	end
	return l_ioOpen(fileName, ...)
end

------------------------------------------------------------------------------
-- Worker body
------------------------------------------------------------------------------

local function canOpen(path)
	local file = l_ioOpen(path, "rb")
	if file then
		file:close()
		return true
	end
	return false
end

-- Filled in as early as possible so error payloads can carry environment
-- diagnostics even when bootstrap fails
local envProbe

local function checkForStartupError()
	if mainObject and mainObject.promptMsg then
		error("worker startup failed: "..tostring(mainObject.promptMsg))
	end
end

local function runWorker()
	local timing = { }
	local startTime = nowMs()
	envProbe = {
		scriptPathArg = scriptPath,
		workDir = engineWorkDir and engineWorkDir() or "?",
		treeOpenRelative = canOpen("TreeData/3_28/tree.lua"),
		treeOpenAbsolute = canOpen(scriptPath.."/TreeData/3_28/tree.lua"),
	}

	-- Bootstrap the program
	local launchDoFile, dofileErr = loadfile(scriptPath.."/Launch.lua")
	if not launchDoFile then
		error("unable to load Launch.lua: "..tostring(dofileErr))
	end
	launchDoFile()
	-- The worker must never kick off an update check
	mainObject.CheckForUpdate = function() end
	runCallback("OnInit")
	checkForStartupError()
	timing.initMs = nowMs() - startTime

	local spec = dkjson.decode(specJSON or "") or { }
	local common = spec.common or { }
	local batch = spec.batch or { }

	-- Reconstruct the build from the XML snapshot. Init has queued a mode change
	-- to an empty build; replacing it before the first frame means the worker
	-- never wastes time building that placeholder (or loading its tree version)
	local build
	if buildXML and #buildXML > 0 then
		mainObject.main:SetMode("BUILD", false, "CalcWorker", buildXML)
		runCallback("OnFrame")
		checkForStartupError()
		build = mainObject.main.modes["BUILD"]
		-- Let deferred frame work settle (initial calc pass, item DB loading for
		-- modes that need it); each frame is cheap once the flags have cleared
		local framesLeft = 1000
		while framesLeft > 0 do
			local needMoreFrames = build.buildFlag or build.modFlag
			if workerMode == "itemdb" and mainObject.main.onFrameFuncs["LoadItems"] then
				needMoreFrames = true
			end
			if not needMoreFrames then
				break
			end
			runCallback("OnFrame")
			checkForStartupError()
			framesLeft = framesLeft - 1
		end
	else
		runCallback("OnFrame") -- Need at least one frame for everything to initialise
		checkForStartupError()
	end
	timing.bootstrapMs = nowMs() - startTime

	local result
	if workerMode == "probe" then
		-- Environment probe: report facts about this VM so assumptions about the
		-- worker environment can be verified at runtime instead of guessed at
		local probe = {
			luaVersion = _VERSION,
			jitVersion = (rawget(_G, "jit") and jit.version) or "none",
			hasLoadfile = type(loadfile) == "function",
			hasIo = type(io) == "table",
			packagePath = package and package.path or "?",
			injectedGetScriptPath = engineScriptPath ~= nil,
			injectedGetRuntimePath = engineRuntimePath ~= nil,
			injectedGetUserPath = engineUserPath ~= nil,
			injectedGetWorkDir = engineWorkDir ~= nil,
			injectedConPrintf = engineConPrintf ~= nil,
			injectedNewFileSearch = engineNewFileSearch ~= nil,
			injectedInflate = engineInflate ~= nil,
			buildXMLBytes = buildXML and #buildXML or 0,
			specJSONBytes = specJSON and #specJSON or 0,
			buildLoaded = build ~= nil,
			buildName = build and build.buildName or "none",
		}
		for key, value in pairs(envProbe or { }) do
			probe[key] = value
		end
		result = { probe = probe }
		if build then
			local calcStart = nowMs()
			local tasks = LoadModule("Modules/PowerCalcTasks")
			local calcFunc, calcBase = build.calcsTab:GetMiscCalculator()
			result.baseline = tasks.extractBaseline(calcBase, nil, false)
			-- Time a couple of representative calcFunc calls
			calcFunc({ }, false)
			probe.singleCalcMs = nowMs() - calcStart
			timing.calcMs = nowMs() - calcStart
		end
		if ParallelWorkerProgress then
			ParallelWorkerProgress(jobId, workerIdx, 1, 1)
		end
	else
		if not build then
			error("no build XML provided for mode "..tostring(workerMode))
		end
		local tasks = LoadModule("Modules/PowerCalcTasks")
		local task = tasks[workerMode]
		if not task then
			error("unknown worker mode: "..tostring(workerMode))
		end
		local calcStart = nowMs()
		local progressFunc
		if ParallelWorkerProgress then
			progressFunc = function(done, total)
				ParallelWorkerProgress(jobId, workerIdx, done, total)
			end
		end
		result = task.computeBatch(build, common, batch, auxText, progressFunc)
		timing.calcMs = nowMs() - calcStart
	end

	timing.totalMs = nowMs() - startTime
	result.timing = timing
	return dkjson.encode(result)
end

local ok, resultOrErr = xpcall(runWorker, function(err)
	return tostring(err).."\n"..debug.traceback()
end)
if ok then
	return resultOrErr
end
-- Return the failure as a structured payload so the main thread gets a clean
-- error message (an uncaught error would also work via OnSubError, but with
-- less context); include the environment diagnostics for probe reports
return dkjson.encode({ error = resultOrErr, probe = envProbe })
