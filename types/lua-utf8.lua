---@meta
---@module "lua-utf8"

local utf8 = { }

---@param text string
---@param pattern string
---@param init? integer
---@return string
function utf8.match(text, pattern, init) end

---@param text string
---@param index? integer
---@param offset? integer
---@return integer?
function utf8.next(text, index, offset) end

---@param text string
---@return string
function utf8.reverse(text) end

---@param text string
---@param pattern string
---@param replacement string|fun(...): string
---@return string
function utf8.gsub(text, pattern, replacement) end

---@param text string
---@param pattern string
---@param init? integer
---@param plain? boolean
---@return integer? start
---@return integer? finish
function utf8.find(text, pattern, init, plain) end

---@param text string
---@param start? integer
---@param finish? integer
---@return string
function utf8.sub(text, start, finish) end

return utf8
