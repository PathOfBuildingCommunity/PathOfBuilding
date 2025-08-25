#@
-- This wrapper allows the program to run headless on any OS (in theory)
-- It can be run using a standard lua interpreter, although LuaJIT is preferable

-- Store command line arguments before they get modified by the loading process
local originalArgs = {}
if arg then
	for i = -5, 10 do
		originalArgs[i] = arg[i]
	end
end

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

-- Search Handles
function NewFileSearch() end

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
function Deflate(data)
	local zlib = require("zlib")
	return zlib.deflate()(data, "finish")
end
function Inflate(data)
	local zlib = require("zlib")
	return zlib.inflate()(data, "finish")
end
function GetTime()
	return 0
end
function GetScriptPath()
	return ""
end
function GetRuntimePath()
	return ""
end
function GetUserPath()
	return ""
end
function MakeDir(path) end
function RemoveDir(path) end
function SetWorkDir(path) end
function GetWorkDir()
	return ""
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

local l_require = require
function require(name)
	-- Hack to stop it looking for lcurl, which we don't really need
	if name == "lcurl.safe" then
		return
	end
	-- Provide a basic utf8 stub for headless mode
	if name == "lua-utf8" then
		return {
			len = function(s) return #s end,
			sub = function(s, i, j) return string.sub(s, i, j) end,
			char = function(...) return string.char(...) end,
			byte = function(s, i) return string.byte(s, i) end,
			find = function(s, pattern, init, plain) return string.find(s, pattern, init, plain) end,
			gmatch = function(s, pattern) return string.gmatch(s, pattern) end,
			gsub = function(s, pattern, repl, n) return string.gsub(s, pattern, repl, n) end,
			match = function(s, pattern, init) return string.match(s, pattern, init) end,
			reverse = function(s) return string.reverse(s) end,
			upper = function(s) return string.upper(s) end,
			lower = function(s) return string.lower(s) end,
		}
	end
	return l_require(name)
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

-- Check if JSON files were provided as command line arguments using original args
local itemsJSONPath, passivesJSONPath

-- Check original arguments for JSON files
if originalArgs[1] and originalArgs[2] then
	itemsJSONPath = originalArgs[1]
	passivesJSONPath = originalArgs[2]
	-- print("Found JSON files in arguments - loading items and passives data...")
	
	-- Read the JSON files
	local itemsFile = io.open(itemsJSONPath, "r")
	local passivesFile = io.open(passivesJSONPath, "r")
	
	if itemsFile and passivesFile then
		local itemsJSON = itemsFile:read("*all")
		local passivesJSON = passivesFile:read("*all")
		itemsFile:close()
		passivesFile:close()
		
		-- print("Calling loadBuildFromJSON...")
		local success, error_msg = pcall(function()
			loadBuildFromJSON(itemsJSON, passivesJSON)
		end)
		
		if not success then
			-- print("Warning: loadBuildFromJSON encountered an error:", error_msg)
			-- print("Continuing to check what data was loaded...")
		end
		
		-- print()	
		-- print("Build loading completed (with or without errors). Checking build data...")
		
		-- Print some information from the build object to verify it's working
		-- print("\n=== BUILD OBJECT VERIFICATION ===")
		if build then
			-- print("✓ build global object exists")
			-- print("build type:", type(build))
			
			-- Check if build.spec exists (passive tree)
			if build.spec then
				-- print("✓ build.spec exists (passive tree)")
				if build.spec.nodes then
					local nodeCount = 0
					for _ in pairs(build.spec.nodes) do
						nodeCount = nodeCount + 1
					end
					-- print("  - Number of passive nodes:", nodeCount)
				end
				if build.spec.allocNodes then
					-- print("  - Number of allocated nodes:", #build.spec.allocNodes)
				end
			else
				-- print("✗ build.spec not found")
			end
			
			-- Check if character data exists
			if build.characterLevel then
				-- print("✓ Character level:", build.characterLevel)
			end
			if build.characterName then
				-- print("✓ Character Name: ", build.characterName)
			end
			if build.characterClass then
				-- print("✓ Character class:", build.characterClass)
			end
			
			-- Check if items exist
			if build.itemsTab and build.itemsTab.items then
				local itemCount = 0
				for _ in pairs(build.itemsTab.items) do
					itemCount = itemCount + 1
				end
				-- print("✓ Items loaded in build.itemsTab.items, count:", itemCount)
				
				-- Show a few example items
				local count = 0
				for k, item in pairs(build.itemsTab.items) do
					if count < 3 and item.name then
						-- print("  - Item " .. (count + 1) .. ":", item.name, "(" .. (item.baseName or "unknown base") .. ")")
					end
					count = count + 1
					if count >= 3 then break end
				end
			elseif build.itemsTab and build.itemsTab.list then
				local itemCount = 0
				for _ in pairs(build.itemsTab.list) do
					itemCount = itemCount + 1
				end
				-- print("✓ Items loaded in build.itemsTab.list, count:", itemCount)
			else
				-- print("✗ Items not found or not loaded")
			end
			
			-- Print some build calculation results if available
			if build.calcsTab and build.calcsTab.buildOutput then
				-- print("✓ Build calculations available")
				local output = build.calcsTab.buildOutput
				if output.Life then
					-- print("  - Total Life:", output.Life)
				end
				if output.EnergyShield then
					-- print("  - Total Energy Shield:", output.EnergyShield)
				end
				if output.TotalDPS then
					-- print("  - Total DPS:", output.TotalDPS)
				end
			end

			-- Try to export build code (requires working Deflate function)
			local buildCode = common.base64.encode(Deflate(build:SaveDB("code"))):gsub("+","-"):gsub("/","_")
			print(buildCode)
			-- local f = io.open("/home/alexander/dev/investigations/PathOfBuilding/buildcode.txt", "w")
			-- if f then
			-- 	f:write(buildCode)
			-- 	f:close()
			-- 	-- print("Build code written to buildcode.txt")
			-- else
			-- 	-- print("Failed to open buildcode.txt for writing!")
			-- end
		else
			-- print("✗ build global object does not exist!")
		end
		-- print("=== END BUILD VERIFICATION ===\n")
	else
		-- print("Error: Could not open JSON files")
		if not itemsFile then
			-- print("  - Could not open items file: " .. itemsJSONPath)
		end
		if not passivesFile then
			-- print("  - Could not open passives file: " .. passivesJSONPath)
		end
	end
else
	-- print("No JSON files provided as command line arguments")
	-- print("Usage: luajit HeadlessWrapper.lua <items.json> <passives.json>")
end
