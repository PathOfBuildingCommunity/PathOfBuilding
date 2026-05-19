--- this file defines function signatures for the runtime API, and is not meant
--  to be used directly
--- @meta

---@alias Font "FIXED"|"VAR"|"VAR BOLD"|"FONTIN SC"|"FONTIN SC ITALIC"|"FONTIN"|"FONTIN ITALIC"

---@param name string
---@param func? fun()
function SetCallback(name, func) end

---@param name string
---@return table
function GetCallback(name) end

---@param object? table
function SetMainObject(object) end

---@return userdata
function NewImageHandle() end

---@param fileName string
---@return userdata
function NewArtHandle(fileName) end

---@return integer width
---@return integer height
function GetScreenSize() end

---@return number
function GetScreenScale() end

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
function GetDPIScaleOverridePercent() end

---@param imgHandle? userdata
---@param left       number
---@param top        number
---@param width      number
---@param height     number
function DrawImage(imgHandle, left, top, width, height) end

---@param imgHandle? userdata
---@param left       number
---@param top        number
---@param width      number
---@param height     number
---@param tcLeft     number
---@param tcTop      number
---@param tcRight    number
---@param tcBottom   number
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom) end

---@param imgHandle? userdata
---@param left       number
---@param top        number
---@param width      number
---@param height     number
---@param stackIdx integer must be positive
---@param mask? integer must be positive
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom, stackIdx, mask) end

---@param imgHandle? userdata
---@param x1         number
---@param y1         number
---@param x2         number
---@param y2         number
---@param x3         number
---@param y3         number
---@param x4         number
---@param y4         number
function DrawImageQuad(imgHandle, x1, y1, x2, y2, x3, y3, x4, y4) end

---@param imgHandle? userdata
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

---@param imgHandle? userdata
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
function DrawStringWidth(height, font, text) end

---@param height  number
---@param font    Font
---@param text    string
---@param cursorX number
---@param cursorY number
---@return integer
function DrawStringCursorIndex(height, font, text, cursorX, cursorY) end

---@param text string
---@return string
function StripEscapes(text) end

---@return integer asyncCount
function GetAsyncCount() end

---@param flag1  string
---@param ...    string
function RenderInit(flag1, ...) end

---@param spec            string
---@param findDirectories boolean
---@return userdata
function NewFileSearch(spec, findDirectories) end

---@param path string
---@return string?  name
---@return string?  version
---@return integer? status
function GetCloudProvider(path) end

---@param title string
function SetWindowTitle(title) end

---@return number x
---@return number y
function GetCursorPos() end

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
function Deflate(data) end

---@param data string
---@return string? data
---@return string? errMsg
function Inflate(data) end

---@return integer timeMillis
function GetTime() end

---@return string  scriptPath
---@return string? scriptFallback
---@return string? errMsg
function GetScriptPath() end

---@return string  runtimePath
---@return string? fallbackPath
---@return string? errMsg
function GetRuntimePath() end

---@return string? userPath
---@return string? invalidPath
---@return string? errMsg
function GetUserPath() end

---@param path string
---@return true|([nil, string]) true on success, or nil and error message
function MakeDir(path) end

---@param path string
---@param recurse? boolean
function RemoveDir(path, recurse) end

---@param path string
function SetWorkDir(path) end

---@return string
function GetWorkDir() end

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
function LoadModule(name, ...) end

---@param modName string
---@param ... any
---@return unknown retVal use ---@module "name" instead
function PLoadModule(modName, ...) end

---@generic T
---@generic R
---@param func fun(...: T): R
---@param ...  any
---@return any? err
---@return R? retVal
function PCall(func, ...) end

---@param fmt string
---@param ... any
function ConPrintf(fmt, ...) end

---@param tbl table
---@param noRecurse any converted to boolean
function ConPrintTable(tbl, noRecurse) end

---@param cmd string
function ConExecute(cmd) end

function ConClear() end

---@param ... (string|boolean|number|integer)
function print(...) end

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