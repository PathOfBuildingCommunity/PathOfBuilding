--- this file defines function signatures for the runtime API, and is not meant
--  to be used directly. the function bodies here ARE NOT correct for regular
--  PoB use. they are implemented by SimpleGraphic, and are only correct for
--  headless mode, in which case this file IS executed.
---@meta

---@alias Font "FIXED"|"VAR"|"VAR BOLD"|"FONTIN SC"|"FONTIN SC ITALIC"|"FONTIN"|"FONTIN ITALIC"

---@param name string
---@param func? fun()
function SetCallback(name, func)
	---@diagnostic disable-next-line: undefined-global headless wrapper
	__callbackTable__[name] = func
end

---@param name string
---@return table
function GetCallback(name)
	---@diagnostic disable-next-line: undefined-global headless wrapper
	return __callbackTable__[name]
end

---@param object? table
function SetMainObject(object)
	__mainObject__ = object
end

---@class ImageHandle
local imageHandleClass = {}
imageHandleClass.__index = imageHandleClass

---@return ImageHandle
function NewImageHandle()
	return setmetatable({}, imageHandleClass)
end

---@param fileName string
---@param ... "ASYNC"|"CLAMP"|"MIPMAP"
function imageHandleClass:Load(fileName, ...)
	self.valid = true
end

---@class ArtHandle
local artHandleClass = {}

---@return integer width
---@return integer height
function artHandleClass:Size() end

---@alias ArtFlag "CLAMP"|"MIPMAP"|"NEAREST"

---@param art ArtHandle
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param ... ArtFlag
function imageHandleClass:LoadArtRectangle(art, x1, y1, x2, y2, ...) end

---@param art ArtHandle
---@param xC integer
---@param yC integer
---@param rMin integer
---@param rMax integer
---@param ... ArtFlag
function imageHandleClass:LoadArtArcBand(art, xC, yC, rMin, rMax, ...) end

function imageHandleClass:Unload()
	self.valid = false
end

---@return boolean
function imageHandleClass:IsValid()
	return self.valid
end

---@return boolean
function imageHandleClass:IsLoading()
	return false
end

---@param priority number
function imageHandleClass:SetLoadingPriority(priority) end

---@return integer width
---@return integer height
function imageHandleClass:ImageSize()
	return 1, 1
end

---@param fileName string
---@return userdata
function NewArtHandle(fileName) end

---@class TexHandle
local texHandleClass = {}

---@class TextureInfo
---@field formatStr "<unknown>"|"RGB"|"RGBA"|"BC1"|"BC7"
---@field width integer
---@field height integer
---@field layerCount integer
---@field mipCount integer
local textureInfoClass = {}

---@class Texture
local Texture = {}

---@return TexHandle
function Texture.new() end

-- `gli::format` id, or a matching format string. see `core_tex_manipulation.cpp`
---@alias TextureFormat integer|"RGB"|"RGBA"|"BC1"|"BC7"

---@param format TextureFormat
---@param width integer
---@param height integer
---@param layerCount integer
---@param mipCount integer
---@return boolean success
function texHandleClass:Allocate(format, width, height, layerCount, mipCount) end

---@param fileName string
---@return boolean success
function texHandleClass:Load(fileName) end

---@param fileName string
---@return boolean success
function texHandleClass:Save(fileName) end

---@return TextureInfo
function texHandleClass:Info() end

---@return boolean
function texHandleClass:IsValid() end

---@param textures TexHandle[]
---@return boolean success
function texHandleClass:StackTextures(textures) end

---@return integer width
---@return integer height
function GetScreenSize()
	return 1920, 1080
end

---@return number
function GetScreenScale()
	return 1
end

---@param red    number
---@param green  number
---@param blue   number
---@param alpha? number
function SetClearColor(red, green, blue, alpha) end

---@param layer?    number
---@param subLayer? number
function SetDrawLayer(layer, subLayer) end

---@return integer
function GetDrawLayer() end

---@param x      number
---@param y      number
---@param width  number
---@param height number
---@overload fun()
function SetViewport(x, y, width, height) end

---@param mode ("ALPHA"|"PREALPHA"|"ADDITIVE")
function SetBlendMode(mode) end

---@param r number
---@param g number
---@param b number
---@param a number?
function SetDrawColor(r, g, b, a) end

---@param escapeStr string
function SetDrawColor(escapeStr) end

---@return number r
---@return number g
---@return number b
---@return number a
function GetDrawColor() end

---@param percent integer
function SetDPIScaleOverridePercent(percent) end

---@return integer
function GetDPIScaleOverridePercent()
	return 1
end

---@param imgHandle? ImageHandle
---@param left       number
---@param top        number
---@param width      number
---@param height     number
function DrawImage(imgHandle, left, top, width, height) end

---@param imgHandle? ImageHandle
---@param left       number
---@param top        number
---@param width      number
---@param height     number
---@param tcLeft     number
---@param tcTop      number
---@param tcRight    number
---@param tcBottom   number
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom) end

---@param imgHandle? ImageHandle
---@param left       number
---@param top        number
---@param width      number
---@param height     number
---@param stackIdx integer must be positive
---@param mask? integer must be positive
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom, stackIdx, mask) end

---@param imgHandle? ImageHandle
---@param x1         number
---@param y1         number
---@param x2         number
---@param y2         number
---@param x3         number
---@param y3         number
---@param x4         number
---@param y4         number
function DrawImageQuad(imgHandle, x1, y1, x2, y2, x3, y3, x4, y4) end

---@param imgHandle? ImageHandle
---@param x1         number
---@param y1         number
---@param x2         number
---@param y2         number
---@param x3         number
---@param y3         number
---@param x4         number
---@param s1         number
---@param t1         number
---@param s2         number
---@param t2         number
---@param s3         number
---@param t3         number
---@param s4         number
---@param t4         number
function DrawImageQuad(imgHandle, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4) end

---@param imgHandle? ImageHandle
---@param x1         number
---@param y1         number
---@param x2         number
---@param y2         number
---@param x3         number
---@param y3         number
---@param x4         number
---@param y4         number
---@param stackIdx   integer? must be positive
---@param mask       integer? must be positive
function DrawImageQuad(imgHandle, x1, y1, x2, y2, x3, y3, x4, y4, stackIdx, mask) end

---@param left   number
---@param top    number
---@param align? ("LEFT"|"CENTER"|"RIGHT"|"CENTER_X"|"RIGHT_X")
---@param height number
---@param font   Font
---@param text   string
function DrawString(left, top, align, height, font, text) end

---@param height number
---@param font   Font
---@param text   string
---@return integer physicalWidth
function DrawStringWidth(height, font, text)
	return 1
end

---@param height  number
---@param font    Font
---@param text    string
---@param cursorX number
---@param cursorY number
---@return integer
function DrawStringCursorIndex(height, font, text, cursorX, cursorY)
	return 0
end

---@param text string
---@return string
function StripEscapes(text)
	local s, _ = text:gsub("%^%d", ""):gsub("%^x%x%x%x%x%x%x", "")
	return s
end

---@return integer asyncCount
function GetAsyncCount()
	return 0
end

---@param flag1  string
---@param ...    string
function RenderInit(flag1, ...) end

---@class FileSearchHandle
local fileSearchHandleClass = {}

---@return boolean
function fileSearchHandleClass:NextFile() end

---@return string
function fileSearchHandleClass:GetFileName() end

---@return integer
function fileSearchHandleClass:GetFileSize() end

---@return number
function fileSearchHandleClass:GetFileModifiedTime() end

---@param spec             string
---@param findDirectories? boolean
---@return FileSearchHandle
function NewFileSearch(spec, findDirectories) end

---@param path string
---@return string?  name
---@return string?  version
---@return integer? status
function GetCloudProvider(path)
	return nil, nil, nil
end

---@param title string
function SetWindowTitle(title) end

---@return number x
---@return number y
function GetCursorPos()
	return 0, 0
end

---@param x number
---@param y number
function SetCursorPos(x, y) end

---@param doShow boolean
function ShowCursor(doShow) end

---@param keyName string cannot be empty or an unrecognised key name
function IsKeyDown(keyName) end

---@param text string
function Copy(text) end

---@return string? data
function Paste() end

---@param data string
---@return string? compressedData
---@return string? errMsg
function Deflate(data)
	return ""
end

---@param data string
---@return string? data
---@return string? errMsg
function Inflate(data)
	return ""
end

---@return integer timeMillis
function GetTime()
	return 0
end

---@return string  scriptPath
---@return string? scriptFallback
---@return string? errMsg
function GetScriptPath()
	return ""
end

---@return string  runtimePath
---@return string? fallbackPath
---@return string? errMsg
function GetRuntimePath()
	return ""
end

---@return string? userPath
---@return string? invalidPath
---@return string? errMsg
function GetUserPath()
	return ""
end

---@param path string
---@return true|([nil, string]) true on success, or nil and error message
function MakeDir(path) end

---@param path string
---@param recurse? boolean
function RemoveDir(path, recurse) end

---@param path string
function SetWorkDir(path) end

---@return string
function GetWorkDir()
	return ""
end

---@alias SubScriptID userdata

---@param scriptText string
---@param funcList   string
---@param subList    string
---@param ...        nil|boolean|number|string
---@return SubScriptID
function LaunchSubScript(scriptText, funcList, subList, ...) end

---@param ssID SubScriptID
function AbortSubScript(ssID) end

---@param ssID SubScriptID
---@return boolean isRunning
function IsSubScriptRunning(ssID) end

---@param name string
---@param ... any
---@return unknown retVal use ---@module "name" instead
function LoadModule(name, ...)
	if not name:match("%.lua") then
		name = name .. ".lua"
	end
	local func, err = loadfile(name)
	if func then
		return func(...)
	else
		error("LoadModule() error loading '" .. name .. "': " .. err)
	end
end

---@param modName string
---@param ... any
---@return unknown retVal use ---@module "name" instead
function PLoadModule(modName, ...)
	if not modName:match("%.lua") then
		modName = modName .. ".lua"
	end
	local func, err = loadfile(modName)
	if func then
		return PCall(func, ...)
	else
		error("PLoadModule() error loading '" .. modName .. "': " .. err)
	end
end

---@generic T
---@generic R
---@param func fun(...: T): R
---@param ...  any
---@return any? err
---@return R? retVal
function PCall(func, ...)
	local ret = { pcall(func, ...) }
	if ret[1] then
		table.remove(ret, 1)
		---@diagnostic disable-next-line: redundant-return-value headless wrapper
		return nil, unpack(ret)
	else
		return ret[2]
	end
end

--- A function similar to C `printf` which prints to the console (`^~` on US layout) of the program.
---@param fmt string
---@param ... any
function ConPrintf(fmt, ...)
	-- Optional
	print(string.format(fmt, ...))
end

---@param tbl table
---@param noRecurse any converted to boolean
function ConPrintTable(tbl, noRecurse) end

---@param cmd string
function ConExecute(cmd) end

function ConClear() end

---@param cmdName string
---@param args string?
function SpawnProcess(cmdName, args) end

---@param url string
---@return string? error
function OpenURL(url) end

---@param isEnabled boolean
function SetProfiling(isEnabled) end

function TakeScreenshot() end

function Restart() end

---@param msg string?
function Exit(msg) end

function SetForeground() end
