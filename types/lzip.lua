---@meta
---@module "lzip"

---@class LzipEntry
local entry = { }

---@param format string
---@return string
function entry:Read(format) end

function entry:Close() end

---@class LzipArchive
local archive = { }

---@param name string
---@return LzipEntry?
function archive:OpenFile(name) end

function archive:Close() end

---@class Lzip
---@field open fun(fileName: string): LzipArchive?
---@type Lzip
local lzip = { }

---@param fileName string
---@return LzipArchive?
function lzip.open(fileName) end

return lzip
