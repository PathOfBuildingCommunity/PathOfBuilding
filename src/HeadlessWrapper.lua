#@
---@diagnostic disable: lowercase-global
-- This wrapper allows the program to run headless on any OS (in theory)
-- It can be run using a standard lua interpreter, although LuaJIT is preferable

-- define global SimpleGraphic API functions. some of these have dummy function
-- bodies intended for headless use.
dofile("_SimpleGraphic.def.lua")

function GetVirtualScreenSize()
	return 1920, 1080
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
	local probes = { '.', 'src' }
	for _, d in ipairs(probes) do
		local fh = io.open(d .. '/HeadlessWrapper.lua', 'r')
		if fh then fh:close(); return d end
	end
	return '.'
end
_G.POB_SCRIPT_DIR = _poew_get_script_dir()

-- [PoEW Patch] Return actual paths for data file resolution
-- Overrides _SimpleGraphic stubs that return ""
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

-- [PoEW Patch] File search for headless mode
-- Uses POSIX FFI on Unix to avoid shell injection via io.popen
do
	local ok_ffi, ffi = pcall(require, "ffi")
	local IS_WINDOWS = package.config:sub(1,1) == "\\"

	local function matchGlob(filename, pattern)
		local luaPat = pattern:gsub("%.", "%%."):gsub("%*", ".*")
		return filename:match("^" .. luaPat .. "$") ~= nil
	end

	local listDir, statMtime

	if ok_ffi and ffi and not IS_WINDOWS then
		local dirOK = pcall(function()
			if ffi.os == "OSX" then
				ffi.cdef[[
					typedef struct _pob_dirent {
						uint64_t d_ino; uint64_t d_seekoff;
						uint16_t d_reclen; uint16_t d_namlen; uint8_t d_type;
						char d_name[1024];
					} _pob_dirent;
				]]
			else
				ffi.cdef[[
					typedef struct _pob_dirent {
						unsigned long d_ino; unsigned long d_off;
						unsigned short d_reclen; unsigned char d_type;
						char d_name[256];
					} _pob_dirent;
				]]
			end
			ffi.cdef[[
				typedef struct _pob_DIR _pob_DIR;
				_pob_DIR *opendir(const char *);
				_pob_dirent *readdir(_pob_DIR *);
				int closedir(_pob_DIR *);
			]]
		end)

		if dirOK then
			listDir = function(dir)
				local files = {}
				local dp = ffi.C.opendir(dir)
				if dp == nil then return files end
				while true do
					local entry = ffi.C.readdir(dp)
					if entry == nil then break end
					local name = ffi.string(entry.d_name)
					if name ~= "." and name ~= ".." then
						files[#files + 1] = name
					end
				end
				ffi.C.closedir(dp)
				return files
			end
		end

		local statOK = pcall(function()
			if ffi.os == "OSX" then
				ffi.cdef[[
					typedef struct { long tv_sec; long tv_nsec; } _pob_timespec;
					typedef struct _pob_stat {
						int32_t st_dev; uint16_t st_mode; uint16_t st_nlink;
						uint64_t st_ino; uint32_t st_uid; uint32_t st_gid; int32_t st_rdev;
						_pob_timespec st_atimespec; _pob_timespec st_mtimespec;
						_pob_timespec st_ctimespec; _pob_timespec st_birthtimespec;
						int64_t st_size; int64_t st_blocks; int32_t st_blksize;
						uint32_t st_flags; uint32_t st_gen;
						int32_t st_lspare; int64_t st_qspare[2];
					} _pob_stat;
					int stat(const char *, _pob_stat *);
				]]
			else
				ffi.cdef[[
					typedef struct _pob_stat {
						unsigned long st_dev; unsigned long st_ino; unsigned long st_nlink;
						unsigned int st_mode; unsigned int st_uid; unsigned int st_gid;
						unsigned int __pad0; unsigned long st_rdev;
						long st_size; long st_blksize; long st_blocks;
						unsigned long st_atime_sec; unsigned long st_atime_nsec;
						unsigned long st_mtime_sec; unsigned long st_mtime_nsec;
						unsigned long st_ctime_sec; unsigned long st_ctime_nsec;
						long __unused[3];
					} _pob_stat;
					int stat(const char *, _pob_stat *);
				]]
			end
		end)

		if statOK then
			if ffi.os == "OSX" then
				statMtime = function(path)
					local buf = ffi.new("_pob_stat")
					if ffi.C.stat(path, buf) == 0 then
						return tonumber(buf.st_mtimespec.tv_sec)
					end
					return 0
				end
			else
				statMtime = function(path)
					local buf = ffi.new("_pob_stat")
					if ffi.C.stat(path, buf) == 0 then
						return tonumber(buf.st_mtime_sec)
					end
					return 0
				end
			end
		end
	end

	-- Fallback: shell-quoted io.popen for Windows or when FFI is unavailable
	if not listDir then
		local function shellQuote(s)
			if IS_WINDOWS then
				return '"' .. s:gsub('/', '\\') .. '"'
			end
			return "'" .. s:gsub("'", "'\\''") .. "'"
		end
		listDir = function(dir)
			local files = {}
			local cmd
			if IS_WINDOWS then
				cmd = 'dir /b ' .. shellQuote(dir) .. ' 2>nul'
			else
				cmd = 'ls -1 ' .. shellQuote(dir) .. ' 2>/dev/null'
			end
			local handle = io.popen(cmd)
			if handle then
				for line in handle:lines() do
					line = line:gsub("%s+$", "")
					if line ~= "" then
						files[#files + 1] = line
					end
				end
				handle:close()
			end
			return files
		end
	end

	local fileSearchClass = {}
	fileSearchClass.__index = fileSearchClass

	function fileSearchClass:GetFileName()
		return self.files[self.index]
	end

	function fileSearchClass:GetFileSize()
		local path = self.dir .. "/" .. self.files[self.index]
		local f = io.open(path, "rb")
		if not f then return 0 end
		local size = f:seek("end")
		f:close()
		return size or 0
	end

	function fileSearchClass:GetFileModifiedTime()
		if statMtime then
			return statMtime(self.dir .. "/" .. self.files[self.index])
		end
		return 0
	end

	function fileSearchClass:NextFile()
		self.index = self.index + 1
		return self.index <= #self.files
	end

	function NewFileSearch(pattern, findDirectories)
		if not pattern or pattern == "" then return nil end
		local dir = pattern:gsub("[/\\][^/\\]*$", "")
		local filePattern = pattern:gsub(".*[/\\]", "")

		if not filePattern:find("[%*%?]") then
			local f = io.open(pattern, "r")
			if not f then return nil end
			f:close()
			return setmetatable({ files = { filePattern }, index = 1, dir = dir }, fileSearchClass)
		end

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
				if ret ~= 0 then return nil end
				return ffi.string(buf, destLen[0])
			end
			function Inflate(data)
				if not data or #data == 0 then return "" end
				local srcLen = #data
				for mult = 10, 100, 10 do
					local destSize = srcLen * mult
					local buf = ffi.new("uint8_t[?]", destSize)
					local destLen = ffi.new("unsigned long[1]", destSize)
					local ret = zlib.uncompress(buf, destLen, data, srcLen)
					if ret == 0 then
						return ffi.string(buf, destLen[0])
					end
					if ret ~= -5 then return nil end
				end
				return nil
			end
			print("zlib loaded via FFI — Inflate/Deflate available")
		else
			print("WARNING: zlib not found — timeless jewel data unavailable")
			function Deflate(data) return nil end
			function Inflate(data) return nil end
		end
	else
		function Deflate(data) return nil end
		function Inflate(data) return nil end
	end
end

local l_require = require
function require(name)
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
__mainObject__.continuousIntegrationMode = os.getenv("CI")

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
	local dkjson = require "dkjson"
	local input = dkjson.decode(characterJSON)
	local charData = build.importTab:ImportItemsAndSkills(input)
	build.importTab:ImportPassiveTreeAndJewels(input)
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
