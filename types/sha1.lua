---@meta
---@module "sha1"

---@class SHA1
---@field _DESCRIPTION string
---@field _LICENSE string
---@field _URL string
---@field _VERSION string
---@field version string
---@field sha1 fun(text: string): string
---@field binary fun(text: string): string
---@field hmac fun(key: string, text: string): string
---@field hmac_binary fun(key: string, text: string): string
---@operator call(string): string
---@type SHA1
local sha1 = { }

return sha1
