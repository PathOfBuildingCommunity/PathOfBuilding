---@meta
---@module "lfs"

---@class LfsAttributes
---@field mode string

---@class LuaFileSystem
---@field dir fun(path: string): fun(): string?
---@field attributes fun(path: string): LfsAttributes?, string?
---@type LuaFileSystem
local lfs = { }

return lfs
